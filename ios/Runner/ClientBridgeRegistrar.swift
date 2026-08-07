import AdSupport
import AppTrackingTransparency
import CFNetwork
import Contacts
import CoreLocation
import Darwin
import Flutter
import Security
import StoreKit
import TDMobRisk
import UIKit

final class ClientBridgeRegistrar: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  static let shared = ClientBridgeRegistrar()

  private let trustDecisionPartnerCode = "boqin_ph"
  private let trustDecisionPartnerKey = "1dc25522f2adc77f5347816c0f7fa31b"
  private lazy var trustDecisionManager = TDMobRiskManager.sharedManager()
  private let deviceSnapshotCollector = DaliDeviceSnapshotCollector()
  private var hasConfiguredTrustDecision = false
  private var eventSink: FlutterEventSink?
  private var pendingNotificationRoutes: [String] = []
  private var locationManager: CLLocationManager?
  private var locationResult: FlutterResult?
  private var locationPermissionManager: CLLocationManager?
  private var locationPermissionResult: FlutterResult?
  private var pushToken = ""

  private override init() {
    super.init()
  }

  func register(with controller: FlutterViewController?) {
    guard let controller else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "dali_cash/client_bridge",
      binaryMessenger: controller.binaryMessenger
    )
    let eventChannel = FlutterEventChannel(
      name: "dali_cash/client_events",
      binaryMessenger: controller.binaryMessenger
    )
    eventChannel.setStreamHandler(self)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getPlatformInfo":
        let info = Bundle.main.infoDictionary
        result([
          "platform": self.deviceModelName(),
          "systemVersion": UIDevice.current.systemVersion,
          "appVersion": info?["CFBundleShortVersionString"] as? String ?? "",
          "buildNumber": info?["CFBundleVersion"] as? String ?? "",
          "deviceId": self.stableVendorIdentifier()
        ])
      case "getProxySettings":
        result(self.currentProxySettings())
      case "requestAppReview":
        self.requestAppReview(result: result)
      case "showTrustDecisionLiveness":
        self.showTrustDecisionLiveness(call.arguments, result: result)
      case "getReportLocation":
        self.getReportLocation(result)
      case "requestLocationPermission":
        self.requestLocationPermission(result)
      case "getReportDeviceSnapshot":
        self.deviceSnapshotCollector.collect(
          idfv: self.stableVendorIdentifier(),
          idfa: self.currentAdvertisingIdentifier(),
          pushToken: self.pushToken,
          isUsingProxy: (self.currentProxySettings()["enabled"] as? Bool) == true,
          modelIdentifier: self.deviceModelName(),
          completion: { snapshot in result(snapshot) }
        )
      case "getPushToken":
        result(self.pushToken)
      case "registerForRemoteNotifications":
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          result(nil)
        }
      case "getTrackingStatus":
        result(self.currentTrackingStatus())
      case "initializeAdjust":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    DispatchQueue.main.async { [weak self] in
      self?.configureTrustDecisionIfNeeded()
    }
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    if !pushToken.isEmpty {
      events(["type": "push_token", "token": pushToken])
    }
    while !pendingNotificationRoutes.isEmpty {
      let route = pendingNotificationRoutes.removeFirst()
      events(["type": "push_route", "url": route])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func updatePushToken(_ token: String) {
    pushToken = token
    guard !token.isEmpty else { return }
    eventSink?(["type": "push_token", "token": token])
  }

  @discardableResult
  func acceptNotificationPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
    guard let route = notificationRoute(from: userInfo) else {
      return false
    }
    guard let eventSink else {
      pendingNotificationRoutes.append(route)
      return true
    }
    eventSink(["type": "push_route", "url": route])
    return true
  }

  private func notificationRoute(from userInfo: [AnyHashable: Any]) -> String? {
    if let route = normalizedNotificationRoute(userInfo["url"]) {
      return route
    }
    if let params = userInfo["params"] as? [AnyHashable: Any] {
      return normalizedNotificationRoute(params["url"])
    }
    guard
      let paramsText = userInfo["params"] as? String,
      let paramsData = paramsText.data(using: .utf8),
      let decoded = try? JSONSerialization.jsonObject(with: paramsData),
      let params = decoded as? [String: Any]
    else {
      return nil
    }
    return normalizedNotificationRoute(params["url"])
  }

  private func normalizedNotificationRoute(_ value: Any?) -> String? {
    guard let value = value as? String else {
      return nil
    }
    let route = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return route.isEmpty ? nil : route
  }

  func publishTrackingStatus() {
    eventSink?([
      "type": "tracking_status_changed",
      "status": currentTrackingStatus()
    ])
  }

  private func requestAppReview(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      if #available(iOS 14.0, *) {
        guard let scene = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .first(where: { $0.activationState == .foregroundActive })
        else {
          result(nil)
          return
        }
        SKStoreReviewController.requestReview(in: scene)
      } else {
        SKStoreReviewController.requestReview()
      }
      result(nil)
    }
  }

  private func getReportLocation(_ result: @escaping FlutterResult) {
    guard locationResult == nil else {
      result(FlutterError(
        code: "location_in_progress",
        message: "A location request is already in progress",
        details: nil
      ))
      return
    }
    guard CLLocationManager.locationServicesEnabled() else {
      result(locationPayload(location: nil, placemark: nil, status: "service_disabled"))
      return
    }

    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    locationManager = manager
    locationResult = result
    let status = manager.authorizationStatus
    if status == .notDetermined {
      finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(status)))
    } else if status == .denied || status == .restricted {
      finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(status)))
    } else {
      manager.requestLocation()
    }
  }

  private func requestLocationPermission(_ result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled() else {
      result("service_disabled")
      return
    }
    let manager = CLLocationManager()
    manager.delegate = self
    if let previousResult = locationPermissionResult {
      locationPermissionResult = nil
      locationPermissionManager = nil
      previousResult("interrupted")
    }
    locationPermissionManager = manager
    locationPermissionResult = result
    let status = manager.authorizationStatus
    guard status == .notDetermined else {
      locationPermissionManager = nil
      locationPermissionResult = nil
      result(locationStatus(status))
      return
    }
    manager.requestWhenInUseAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if manager === locationPermissionManager {
      let status = manager.authorizationStatus
      guard status != .notDetermined else { return }
      let result = locationPermissionResult
      locationPermissionResult = nil
      locationPermissionManager = nil
      result?(locationStatus(status))
      return
    }
    guard locationResult != nil else { return }
    let status = manager.authorizationStatus
    if status == .authorizedAlways || status == .authorizedWhenInUse {
      manager.requestLocation()
    } else if status == .denied || status == .restricted {
      finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(status)))
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last else {
      finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(manager.authorizationStatus)))
      return
    }
    CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
      guard let self else { return }
      self.finishLocation(self.locationPayload(
        location: location,
        placemark: placemarks?.first,
        status: self.locationStatus(manager.authorizationStatus)
      ))
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(manager.authorizationStatus)))
  }

  private func finishLocation(_ payload: [String: Any]) {
    let result = locationResult
    locationResult = nil
    locationManager?.stopUpdatingLocation()
    locationManager = nil
    result?(payload)
  }

  private func locationPayload(
    location: CLLocation?,
    placemark: CLPlacemark?,
    status: String
  ) -> [String: Any] {
    return [
      "province": placemark?.administrativeArea ?? "",
      "locality": placemark?.subAdministrativeArea ?? "",
      "fullAddress": fullAddress(from: placemark),
      "countryCode": placemark?.isoCountryCode ?? "",
      "country": placemark?.country ?? "",
      "street": street(from: placemark),
      "latitude": location.map { String($0.coordinate.latitude) } ?? "",
      "longitude": location.map { String($0.coordinate.longitude) } ?? "",
      "city": placemark?.locality ?? placemark?.subAdministrativeArea ?? "",
      "permissionStatus": status
    ]
  }

  private func street(from placemark: CLPlacemark?) -> String {
    guard let placemark else { return "" }
    return placemark.postalAddress?.street
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  private func fullAddress(from placemark: CLPlacemark?) -> String {
    guard let placemark else { return "" }
    let streetNumber = [placemark.thoroughfare, placemark.subThoroughfare]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: " ")
    let parts = [
      placemark.country,
      placemark.administrativeArea,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.subLocality,
      streetNumber
    ]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    return uniqueAddressParts(parts).joined(separator: " ")
  }

  private func uniqueAddressParts(_ parts: [String]) -> [String] {
    var seen = Set<String>()
    return parts.filter { seen.insert($0).inserted }
  }

  private func locationStatus(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .authorizedAlways: return "authorized_always"
    case .authorizedWhenInUse: return "authorized_when_in_use"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not_determined"
    @unknown default: return "unknown"
    }
  }

  private func currentTrackingStatus() -> String {
    guard #available(iOS 14, *) else { return "not_supported" }
    switch ATTrackingManager.trackingAuthorizationStatus {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "not_determined"
    @unknown default: return "unknown"
    }
  }

  private func currentAdvertisingIdentifier() -> String {
    if #available(iOS 14, *), ATTrackingManager.trackingAuthorizationStatus == .authorized {
      let identifier = ASIdentifierManager.shared().advertisingIdentifier.uuidString
      return identifier == "00000000-0000-0000-0000-000000000000" ? "" : identifier
    }
    return ""
  }

  private func configureTrustDecisionIfNeeded() {
    guard !hasConfiguredTrustDecision else {
      return
    }
    hasConfiguredTrustDecision = true
    var params: [String: Any] = [
      "partner": trustDecisionPartnerCode,
      "appKey": trustDecisionPartnerKey,
      "country": "sg",
      "language": "en"
    ]
#if DEBUG
    params["allowed"] = true
#endif
    trustDecisionManager?.pointee.initWithOptions(params)
  }

  private func showTrustDecisionLiveness(
    _ arguments: Any?,
    result: @escaping FlutterResult
  ) {
    configureTrustDecisionIfNeeded()
    let license = arguments as? String
    guard let viewController = topViewController() else {
      result([
        "success": false,
        "code": -1,
        "message": "find ViewController Error",
        "image": "",
        "sequence_id": "",
        "liveness_id": "",
        "raw": [:]
      ])
      return
    }

    trustDecisionManager?.pointee.showLivenessWithShowStyle(
      viewController,
      license,
      TDLivenessShowStylePresent,
      { successResult in
        result(self.wrapLivenessResult(success: true, payload: successResult))
      },
      { failResult in
        result(self.wrapLivenessResult(success: false, payload: failResult))
      }
    )
  }

  private func wrapLivenessResult(
    success: Bool,
    payload: [AnyHashable: Any]?
  ) -> [String: Any] {
    let raw = (payload as? [String: Any]) ?? [:]
    let code = (raw["code"] as? NSNumber)?.intValue ?? (success ? 0 : -1)
    let message = raw["message"] as? String ?? ""
    let image = raw["image"] as? String ?? ""
    let sequenceId = raw["sequence_id"] as? String ?? ""
    let livenessId = raw["liveness_id"] as? String ?? ""
    return [
      "success": success,
      "code": code,
      "message": message,
      "image": image,
      "sequence_id": sequenceId,
      "liveness_id": livenessId,
      "raw": raw
    ]
  }

  private func topViewController(
    from viewController: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: \.isKeyWindow)?
      .rootViewController
  ) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = viewController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }
    if let presentedViewController = viewController?.presentedViewController {
      return topViewController(from: presentedViewController)
    }
    return viewController
  }

  private func currentProxySettings() -> [String: Any] {
    guard
      let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue()
        as? [String: Any]
    else {
      return ["enabled": false, "host": "", "port": 0]
    }

    let enabled =
      (settings[kCFNetworkProxiesHTTPEnable as String] as? NSNumber)?.boolValue
      ?? false
    let host = settings[kCFNetworkProxiesHTTPProxy as String] as? String ?? ""
    let port =
      (settings[kCFNetworkProxiesHTTPPort as String] as? NSNumber)?.intValue
      ?? 0
    guard enabled, !host.isEmpty, port > 0 else {
      return ["enabled": false, "host": "", "port": 0]
    }
    return ["enabled": true, "host": host, "port": port]
  }

  private func stableVendorIdentifier() -> String {
    let service = "dali_cash.client_bridge"
    let account = "stable_idfv"
    if let stored = keychainValue(service: service, account: account),
       !stored.isEmpty {
      return stored
    }

    let identifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
    if !identifier.isEmpty {
      saveKeychainValue(identifier, service: service, account: account)
    }
    return identifier
  }

  private func deviceModelName() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let identifier = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        String(validatingUTF8: $0) ?? ""
      }
    }
    return identifier.isEmpty ? UIDevice.current.model : identifier
  }

  private func keychainValue(service: String, account: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status == errSecSuccess, let data = result as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  private func saveKeychainValue(_ value: String, service: String, account: String) {
    let data = Data(value.utf8)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      var item = query
      item[kSecValueData as String] = data
      item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
      SecItemAdd(item as CFDictionary, nil)
    }
  }
}

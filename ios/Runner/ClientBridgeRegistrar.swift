import AdSupport
import AppTrackingTransparency
import CFNetwork
import CoreLocation
import Darwin
import Flutter
import Security
import StoreKit
import SystemConfiguration.CaptiveNetwork
import TDMobRisk
import UIKit

final class ClientBridgeRegistrar: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  static let shared = ClientBridgeRegistrar()

  private let trustDecisionPartnerCode = "boqin_ph"
  private let trustDecisionPartnerKey = "1dc25522f2adc77f5347816c0f7fa31b"
  private lazy var trustDecisionManager = TDMobRiskManager.sharedManager()
  private var hasConfiguredTrustDecision = false
  private var eventSink: FlutterEventSink?
  private var locationManager: CLLocationManager?
  private var locationResult: FlutterResult?
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
      case "getReportDeviceSnapshot":
        result(self.currentDeviceSnapshot())
      case "getPushToken":
        result(self.pushToken)
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
      manager.requestWhenInUseAuthorization()
    } else if status == .denied || status == .restricted {
      finishLocation(locationPayload(location: nil, placemark: nil, status: locationStatus(status)))
    } else {
      manager.requestLocation()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
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
    let address = [
      placemark?.subThoroughfare,
      placemark?.thoroughfare,
      placemark?.locality,
      placemark?.administrativeArea,
      placemark?.country
    ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    return [
      "province": placemark?.administrativeArea ?? "",
      "locality": placemark?.subLocality ?? "",
      "fullAddress": address,
      "countryCode": placemark?.isoCountryCode ?? "",
      "country": placemark?.country ?? "",
      "street": placemark?.thoroughfare ?? "",
      "latitude": location.map { String($0.coordinate.latitude) } ?? "",
      "longitude": location.map { String($0.coordinate.longitude) } ?? "",
      "city": placemark?.locality ?? "",
      "permissionStatus": status
    ]
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

  private func currentDeviceSnapshot() -> [String: Any] {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = UIDevice.current.batteryLevel < 0
      ? 0
      : Int(UIDevice.current.batteryLevel * 100)
    let isCharging = UIDevice.current.batteryState == .charging
      || UIDevice.current.batteryState == .full
    let bounds = UIScreen.main.nativeBounds
    let fileAttributes = try? FileManager.default.attributesOfFileSystem(
      forPath: NSHomeDirectory()
    )
    let totalStorage = (fileAttributes?[.systemSize] as? NSNumber)?.stringValue ?? "0"
    let availableStorage = (fileAttributes?[.systemFreeSize] as? NSNumber)?.stringValue ?? "0"
    let wifi = currentWifiInfo()
    let proxy = currentProxySettings()
    let idfv = stableVendorIdentifier()
    let idfa: String
    if #available(iOS 14, *), ATTrackingManager.trackingAuthorizationStatus == .authorized {
      idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    } else {
      idfa = ""
    }
    return [
      "idfv": idfv,
      "idfa": idfa,
      "deviceId": idfv,
      "riskDeviceId": idfv,
      "batteryLevel": batteryLevel,
      "isCharging": isCharging ? 1 : 0,
      "elapsedMillis": Int(ProcessInfo.processInfo.systemUptime * 1000),
      "uptimeMillis": String(Int(ProcessInfo.processInfo.systemUptime * 1000)),
      "isUsingProxy": (proxy["enabled"] as? Bool) == true ? 1 : 0,
      "isUsingVpn": 0,
      "isJailbroken": isJailbroken() ? 1 : 0,
      "isEmulator": isSimulator() ? 1 : 0,
      "language": Locale.current.languageCode ?? "",
      "carrier": "",
      "networkType": "OTHER",
      "timeZoneName": TimeZone.current.identifier,
      "cpuCoreCount": ProcessInfo.processInfo.processorCount,
      "brand": "Apple",
      "deviceName": UIDevice.current.name,
      "model": deviceModelName(),
      "modelName": UIDevice.current.model,
      "systemVersion": UIDevice.current.systemVersion,
      "packageName": Bundle.main.bundleIdentifier ?? "",
      "screenHeight": Int(bounds.height),
      "screenWidth": Int(bounds.width),
      "screenSize": "",
      "innerIp": "",
      "currentWifiName": wifi.name,
      "currentWifiBssid": wifi.bssid,
      "wifiCount": wifi.name.isEmpty ? 0 : 1,
      "availableStorage": availableStorage,
      "totalStorage": totalStorage,
      "totalMemory": String(ProcessInfo.processInfo.physicalMemory),
      "availableMemory": "0",
      "pushToken": pushToken
    ]
  }

  private func currentWifiInfo() -> (name: String, bssid: String) {
    guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
      return ("", "")
    }
    for interface in interfaces {
      if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
        return (
          info[kCNNetworkInfoKeySSID as String] as? String ?? "",
          info[kCNNetworkInfoKeyBSSID as String] as? String ?? ""
        )
      }
    }
    return ("", "")
  }

  private func isSimulator() -> Bool {
#if targetEnvironment(simulator)
    return true
#else
    return false
#endif
  }

  private func isJailbroken() -> Bool {
#if targetEnvironment(simulator)
    return false
#else
    return FileManager.default.fileExists(atPath: "/Applications/Cydia.app")
      || FileManager.default.fileExists(atPath: "/bin/bash")
      || FileManager.default.fileExists(atPath: "/usr/sbin/sshd")
#endif
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

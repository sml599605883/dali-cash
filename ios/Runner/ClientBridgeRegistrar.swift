import CFNetwork
import Darwin
import Flutter
import Security
import TDMobRisk
import UIKit

final class ClientBridgeRegistrar {
  static let shared = ClientBridgeRegistrar()

  private let trustDecisionPartnerCode = "boqin_ph"
  private let trustDecisionPartnerKey = "1dc25522f2adc77f5347816c0f7fa31b"
  private lazy var trustDecisionManager = TDMobRiskManager.sharedManager()
  private var hasConfiguredTrustDecision = false

  private init() {}

  func register(with controller: FlutterViewController?) {
    guard let controller else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "dali_cash/client_bridge",
      binaryMessenger: controller.binaryMessenger
    )
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    DispatchQueue.main.async { [weak self] in
      self?.configureTrustDecisionIfNeeded()
    }
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

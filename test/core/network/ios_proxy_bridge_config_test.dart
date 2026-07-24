import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS registers CFNetwork proxy bridge for app and scene startup', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final registrarFile = File('ios/Runner/ClientBridgeRegistrar.swift');
    final registrar = registrarFile.existsSync()
        ? registrarFile.readAsStringSync()
        : '';
    final sceneDelegate = File(
      'ios/Runner/SceneDelegate.swift',
    ).readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(registrarFile.existsSync(), isTrue);
    expect(registrar, contains('import CFNetwork'));
    expect(registrar, contains('import Security'));
    expect(registrar, contains('dali_cash/client_bridge'));
    expect(registrar, contains('getProxySettings'));
    expect(registrar, contains('getPlatformInfo'));
    expect(registrar, contains('CFNetworkCopySystemProxySettings'));
    expect(registrar, contains('kCFNetworkProxiesHTTPEnable'));
    expect(registrar, contains('kCFNetworkProxiesHTTPProxy'));
    expect(registrar, contains('kCFNetworkProxiesHTTPPort'));
    expect(registrar, contains('stableVendorIdentifier'));
    expect(registrar, contains('UIDevice.current.identifierForVendor'));
    expect(
      registrar,
      contains('kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly'),
    );
    expect(registrar, contains('dali_cash.client_bridge'));
    expect(appDelegate, contains('ClientBridgeRegistrar.shared.register'));
    expect(sceneDelegate, contains('ClientBridgeRegistrar.shared.register'));
    expect(project, contains('ClientBridgeRegistrar.swift in Sources'));
  });

  test('iOS startup has no custom mainland network authorization gate', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final registrarFile = File('ios/Runner/ClientBridgeRegistrar.swift');
    final registrar = registrarFile.existsSync()
        ? registrarFile.readAsStringSync()
        : '';

    expect(registrar, isNot(contains('import CoreTelephony')));
    expect(registrar, isNot(contains('CTCellularData')));
    expect(registrar, isNot(contains('waitForNetworkAuthorization')));
    expect(registrar, isNot(contains('URLSessionConfiguration.ephemeral')));
    expect(appDelegate, isNot(contains('https://www.apple.com')));
  });

  test('iOS initializes pinned TDMobRisk dependencies during startup', () {
    final podfile = File('ios/Podfile').readAsStringSync();
    final registrar = File(
      'ios/Runner/ClientBridgeRegistrar.swift',
    ).readAsStringSync();

    expect(podfile, contains("pod 'TrustDecisionPro', '5.2.5.1'"));
    expect(podfile, contains("pod 'TrustDecisionLiveness', '3.1.2'"));
    expect(registrar, contains('import TDMobRisk'));
    expect(registrar, contains('trustDecisionPartnerCode'));
    expect(registrar, contains('trustDecisionPartnerKey'));
    expect(registrar, contains('hasConfiguredTrustDecision'));
    expect(registrar, contains('DispatchQueue.main.async'));
    expect(registrar, contains('configureTrustDecisionIfNeeded'));
    expect(registrar, contains('"partner": trustDecisionPartnerCode'));
    expect(registrar, contains('"appKey": trustDecisionPartnerKey'));
    expect(registrar, contains('"country": "sg"'));
    expect(registrar, contains('"language": "en"'));
    expect(registrar, contains('params["allowed"] = true'));
    expect(registrar, contains('initWithOptions(params)'));
  });

  test('iOS exposes TrustDecision liveness through the client bridge', () {
    final registrar = File(
      'ios/Runner/ClientBridgeRegistrar.swift',
    ).readAsStringSync();

    expect(registrar, contains('case "showTrustDecisionLiveness"'));
    expect(registrar, contains('showLivenessWithShowStyle'));
    expect(registrar, contains('TDLivenessShowStylePresent'));
    expect(registrar, contains('"success"'));
    expect(registrar, contains('"image"'));
    expect(registrar, contains('"sequence_id"'));
    expect(registrar, contains('"liveness_id"'));
    expect(registrar, contains('"raw"'));
  });
}

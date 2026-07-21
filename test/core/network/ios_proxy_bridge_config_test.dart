import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS registers CFNetwork proxy bridge for app and scene startup', () {
    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final sceneDelegate = File(
      'ios/Runner/SceneDelegate.swift',
    ).readAsStringSync();

    expect(appDelegate, contains('import CFNetwork'));
    expect(appDelegate, contains('import Security'));
    expect(appDelegate, contains('dali_cash/client_bridge'));
    expect(appDelegate, contains('getProxySettings'));
    expect(appDelegate, contains('getPlatformInfo'));
    expect(appDelegate, contains('CFNetworkCopySystemProxySettings'));
    expect(appDelegate, contains('kCFNetworkProxiesHTTPEnable'));
    expect(appDelegate, contains('kCFNetworkProxiesHTTPProxy'));
    expect(appDelegate, contains('kCFNetworkProxiesHTTPPort'));
    expect(appDelegate, contains('stableVendorIdentifier'));
    expect(appDelegate, contains('UIDevice.current.identifierForVendor'));
    expect(
      appDelegate,
      contains('kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly'),
    );
    expect(appDelegate, contains('dali_cash.client_bridge'));
    expect(appDelegate, contains('ProxyBridgeRegistrar.shared.register'));
    expect(sceneDelegate, contains('ProxyBridgeRegistrar.shared.register'));
  });
}

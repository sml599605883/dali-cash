import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ClientBridge.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('parses native platform info', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getPlatformInfo');
          return <String, Object?>{
            'platform': 'iPhone17,1',
            'systemVersion': '18.0',
            'appVersion': '1.2.3',
            'buildNumber': '10',
            'deviceId': 'stable-idfv',
          };
        });

    final info = await ClientBridge(
      platform: ClientPlatform.ios,
    ).getPlatformInfo();

    expect(info.platform, 'iPhone17,1');
    expect(info.systemVersion, '18.0');
    expect(info.appVersion, '1.2.3');
    expect(info.buildNumber, '10');
    expect(info.deviceId, 'stable-idfv');
  });

  test('parses enabled native proxy settings', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getProxySettings');
          return <String, Object?>{
            'enabled': true,
            'host': '192.168.1.8',
            'port': 9090,
          };
        });

    final settings = await ClientBridge(
      platform: ClientPlatform.ios,
    ).getProxySettings();

    expect(settings.canApply, isTrue);
    expect(settings.host, '192.168.1.8');
    expect(settings.port, 9090);
  });

  test('rejects incomplete proxy settings', () {
    final settings = ClientProxySettings.fromMap(<Object?, Object?>{
      'enabled': true,
      'host': '',
      'port': 'invalid',
    });

    expect(settings.canApply, isFalse);
  });

  test('does not invoke iOS bridge on unsupported platforms', () {
    final bridge = ClientBridge(platform: ClientPlatform.android);

    expect(bridge.getProxySettings, throwsA(isA<UnsupportedError>()));
    expect(bridge.getPlatformInfo, throwsA(isA<UnsupportedError>()));
  });
}

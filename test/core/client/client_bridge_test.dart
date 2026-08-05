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

  test('requests app review through the iOS method channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });

    await ClientBridge(platform: ClientPlatform.ios).requestAppReview();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'requestAppReview');
    expect(calls.single.arguments, isNull);
  });

  test('rejects app review outside iOS', () {
    expect(
      () => ClientBridge(platform: ClientPlatform.android).requestAppReview(),
      throwsA(isA<UnsupportedError>()),
    );
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

  test('parses TrustDecision liveness result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'showTrustDecisionLiveness');
          expect(call.arguments, 'td-license');
          return <String, Object?>{
            'success': true,
            'code': 0,
            'message': 'success',
            'image': 'base64-image',
            'sequence_id': 'sequence-42',
            'liveness_id': 'liveness-42',
            'raw': <String, Object?>{'source': 'native'},
          };
        });

    final result = await ClientBridge(
      platform: ClientPlatform.ios,
    ).showTrustDecisionLiveness('td-license');

    expect(result.success, isTrue);
    expect(result.code, 0);
    expect(result.message, 'success');
    expect(result.image, 'base64-image');
    expect(result.sequenceId, 'sequence-42');
    expect(result.livenessId, 'liveness-42');
    expect(result.raw['source'], 'native');
  });

  test('converts TrustDecision platform failures to failed results', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(
            code: 'liveness_failed',
            message: 'Camera unavailable',
          );
        });

    final result = await ClientBridge(
      platform: ClientPlatform.ios,
    ).showTrustDecisionLiveness('td-license');

    expect(result.success, isFalse);
    expect(result.message, 'Camera unavailable');
    expect(result.raw['code'], 'liveness_failed');
  });

  test('reports unavailable TrustDecision bridge', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw MissingPluginException();
        });

    final result = await ClientBridge(
      platform: ClientPlatform.ios,
    ).showTrustDecisionLiveness('td-license');

    expect(result.success, isFalse);
    expect(result.message, 'Liveness verification is unavailable.');
  });

  test('requests location permission through the native bridge', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 'authorized_when_in_use';
        });

    final status = await ClientBridge(
      platform: ClientPlatform.ios,
    ).requestLocationPermission();

    expect(status, 'authorized_when_in_use');
    expect(calls.single.method, 'requestLocationPermission');
  });

  test('does not invoke TrustDecision bridge outside iOS', () async {
    final result = await ClientBridge(
      platform: ClientPlatform.android,
    ).showTrustDecisionLiveness('td-license');

    expect(result.success, isFalse);
    expect(result.message, contains('only available on iOS'));
  });

  test('parses report location and device snapshot', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getReportLocation') {
            return <String, Object?>{
              'latitude': '14.5',
              'longitude': '121.0',
              'city': 'Makati',
            };
          }
          expect(call.method, 'getReportDeviceSnapshot');
          return <String, Object?>{
            'idfv': 'idfv-1',
            'idfa': 'idfa-1',
            'riskDeviceId': 'risk-1',
            'batteryLevel': 80,
          };
        });
    final bridge = ClientBridge(platform: ClientPlatform.ios);

    final location = await bridge.getReportLocation();
    final snapshot = await bridge.getReportDeviceSnapshot();

    expect(location?.city, 'Makati');
    expect(snapshot.idfv, 'idfv-1');
    expect(snapshot.batteryLevel, 80);
  });

  test(
    'gets push token and tracking status and initializes attribution',
    () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            switch (call.method) {
              case 'getPushToken':
                return 'push-token';
              case 'getTrackingStatus':
                return 'authorized';
              case 'initializeAdjust':
                expect(call.arguments, {'token': 'adjust-token'});
                return null;
            }
            return null;
          });
      final bridge = ClientBridge(platform: ClientPlatform.ios);

      expect(await bridge.getPushToken(), 'push-token');
      expect(await bridge.getTrackingStatus(), 'authorized');
      await bridge.initializeAdjust('adjust-token');
      expect(calls, ['getPushToken', 'getTrackingStatus', 'initializeAdjust']);
    },
  );

  test('report bridge failures return safe empty values', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw MissingPluginException();
        });
    final bridge = ClientBridge(platform: ClientPlatform.ios);

    expect(await bridge.getReportLocation(), isNull);
    expect((await bridge.getReportDeviceSnapshot()).idfv, isEmpty);
    expect(await bridge.getPushToken(), isEmpty);
    expect(await bridge.getTrackingStatus(), isEmpty);
  });

  test('does not invoke iOS bridge on unsupported platforms', () {
    final bridge = ClientBridge(platform: ClientPlatform.android);

    expect(bridge.getProxySettings, throwsA(isA<UnsupportedError>()));
    expect(bridge.getPlatformInfo, throwsA(isA<UnsupportedError>()));
  });
}

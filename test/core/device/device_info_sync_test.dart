import 'dart:async';

import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:dali_cash/core/device/device_info_sync.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_endpoints.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ClientBridge.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('fetches and stores Dali normalized device info', () async {
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
    final adapter = _DeviceInfoAdapter();
    final store = SessionStore.memory();
    final bridge = ClientBridge(platform: ClientPlatform.ios);
    final client = ApiClient(
      ApiConfig(
        commonParamsProvider: () async => const <String, dynamic>{},
        timestampProvider: () => 1000,
        randomDigitsProvider: (_) => '123456',
      ),
      dio: Dio()..httpClientAdapter = adapter,
    );

    await DeviceInfoSync(
      apiClient: client,
      clientBridge: bridge,
      store: store,
    ).sync();

    expect(adapter.lastRequest.path, endsWith(ApiEndpoints.getDeviceName));
    expect(adapter.lastRequest.data, {
      'crocidolites': 'iPhone17,1',
      'symbiotes': '123456',
    });
    expect(await store.deviceName(), 'iPhone 17');
    expect(await store.physicalSize(), '6.3');
  });
}

class _DeviceInfoAdapter implements HttpClientAdapter {
  RequestOptions lastRequest = RequestOptions();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{"felicitous":0,"cuckoo":"success","unsphered":{"extravagates":"iPhone 17","beachwear":6.3}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

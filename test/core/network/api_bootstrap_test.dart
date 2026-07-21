import 'dart:async';

import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:dali_cash/core/network/api_bootstrap.dart';
import 'package:dali_cash/core/network/api_config.dart';
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

  test(
    'waits for native proxy lookup and applies it before returning',
    () async {
      final completer = Completer<Map<String, Object?>>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getProxySettings') {
              return completer.future;
            }
            expect(call.method, 'getPlatformInfo');
            return <String, Object?>{'platform': ''};
          });
      var completed = false;

      final bootstrap =
          bootstrapApiClient(
            clientBridge: ClientBridge(platform: ClientPlatform.ios),
            apiConfig: ApiConfig(sessionStore: SessionStore.memory()),
          ).then((client) {
            completed = true;
            return client;
          });

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      completer.complete(<String, Object?>{
        'enabled': true,
        'host': '127.0.0.1',
        'port': 8888,
      });
      final client = await bootstrap;

      expect(completed, isTrue);
      expect(client.proxyHost, '127.0.0.1');
      expect(client.proxyPort, 8888);
    },
  );

  test('explicit proxy override takes precedence over native lookup', () async {
    var proxyLookups = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getProxySettings') {
            proxyLookups++;
            return <String, Object?>{
              'enabled': true,
              'host': '192.168.1.8',
              'port': 9090,
            };
          }
          return <String, Object?>{'platform': ''};
        });

    final client = await bootstrapApiClient(
      clientBridge: ClientBridge(platform: ClientPlatform.ios),
      apiConfig: ApiConfig(sessionStore: SessionStore.memory()),
      proxyHost: '10.0.0.2',
      proxyPort: 8080,
    );

    expect(client.proxyHost, '10.0.0.2');
    expect(client.proxyPort, 8080);
    expect(proxyLookups, 0);
  });

  test('keeps supplied Dio adapter when no proxy is enabled', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getProxySettings') {
            return <String, Object?>{'enabled': false, 'host': '', 'port': 0};
          }
          return <String, Object?>{'platform': ''};
        });
    final dio = Dio();
    final adapter = dio.httpClientAdapter;

    final client = await bootstrapApiClient(
      clientBridge: ClientBridge(platform: ClientPlatform.ios),
      apiConfig: ApiConfig(sessionStore: SessionStore.memory()),
      dio: dio,
    );

    expect(client.proxyHost, isNull);
    expect(client.proxyPort, isNull);
    expect(client.dio.httpClientAdapter, same(adapter));
  });

  test('syncs normalized device info before returning', () async {
    final store = SessionStore.memory();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getProxySettings') {
            return <String, Object?>{'enabled': false, 'host': '', 'port': 0};
          }
          expect(call.method, 'getPlatformInfo');
          return <String, Object?>{
            'platform': 'iPhone17,1',
            'systemVersion': '18.0',
            'appVersion': '1.2.3',
            'buildNumber': '10',
            'deviceId': 'stable-idfv',
          };
        });

    await bootstrapApiClient(
      clientBridge: ClientBridge(platform: ClientPlatform.ios),
      apiConfig: ApiConfig(
        commonParamsProvider: () async => const <String, dynamic>{},
        randomDigitsProvider: (_) => '123456',
      ),
      sessionStore: store,
      dio: Dio()..httpClientAdapter = _BootstrapAdapter(),
    );

    expect(await store.deviceName(), 'iPhone 17');
    expect(await store.physicalSize(), '6.3');
  });
}

class _BootstrapAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

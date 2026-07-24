import 'dart:async';
import 'dart:io';

import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:dali_cash/core/network/api_bootstrap.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_endpoints.dart';
import 'package:dali_cash/core/network/api_exception.dart';
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
      final proxyServer = await _startSuccessfulProxyServer();
      addTearDown(() => proxyServer.close(force: true));
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
            apiConfig: ApiConfig(
              apiBaseUrl: 'http://api.test/manlikely',
              sessionStore: SessionStore.memory(),
            ),
          ).then((client) {
            completed = true;
            return client;
          });

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      completer.complete(<String, Object?>{
        'enabled': true,
        'host': '127.0.0.1',
        'port': proxyServer.port,
      });
      final client = await bootstrap;

      expect(completed, isTrue);
      expect(client.proxyHost, '127.0.0.1');
      expect(client.proxyPort, proxyServer.port);
    },
  );

  test('explicit proxy override takes precedence over native lookup', () async {
    final proxyServer = await _startSuccessfulProxyServer();
    addTearDown(() => proxyServer.close(force: true));
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
      apiConfig: ApiConfig(
        apiBaseUrl: 'http://api.test/manlikely',
        sessionStore: SessionStore.memory(),
      ),
      proxyHost: '127.0.0.1',
      proxyPort: proxyServer.port,
    );

    expect(client.proxyHost, '127.0.0.1');
    expect(client.proxyPort, proxyServer.port);
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
    final adapter = _BootstrapAdapter();
    final dio = Dio()..httpClientAdapter = adapter;

    final client = await bootstrapApiClient(
      clientBridge: ClientBridge(platform: ClientPlatform.ios),
      apiConfig: ApiConfig(
        apiBaseUrl: 'http://api.test/manlikely',
        sessionStore: SessionStore.memory(),
      ),
      dio: dio,
    );

    expect(client.proxyHost, isNull);
    expect(client.proxyPort, isNull);
    expect(client.dio.httpClientAdapter, same(adapter));
  });

  test('stops bootstrap when no API base URL is reachable', () async {
    final adapter = _BootstrapAdapter(statusCode: 503);
    var platformInfoRequests = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getProxySettings') {
            return <String, Object?>{'enabled': false, 'host': '', 'port': 0};
          }
          platformInfoRequests++;
          return <String, Object?>{'platform': 'iPhone17,1'};
        });

    await expectLater(
      bootstrapApiClient(
        clientBridge: ClientBridge(platform: ClientPlatform.ios),
        apiConfig: ApiConfig(
          apiBaseUrl: 'http://api.test/manlikely',
          sessionStore: SessionStore.memory(),
        ),
        dio: Dio()..httpClientAdapter = adapter,
      ),
      throwsA(
        isA<ApiBusinessException>().having(
          (error) => error.message,
          'message',
          'Network connection failed',
        ),
      ),
    );

    expect(adapter.requests, hasLength(1));
    expect(platformInfoRequests, 0);
  });

  test('syncs device info before returning', () async {
    final store = SessionStore.memory();
    final adapter = _BootstrapAdapter();
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
        apiBaseUrl: 'http://api.test/manlikely',
        commonParamsProvider: () async => const <String, dynamic>{},
        randomDigitsProvider: (_) => '123456',
      ),
      sessionStore: store,
      dio: Dio()..httpClientAdapter = adapter,
    );

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.uri.toString(), 'http://api.test/manlikely');
    expect(
      adapter.requests.last.uri.path,
      '/manlikely${ApiEndpoints.getDeviceName}',
    );
    expect(await store.deviceName(), 'iPhone 17');
    expect(await store.physicalSize(), '6.3');
  });
}

Future<HttpServer> _startSuccessfulProxyServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) {
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write('{}')
      ..close();
  });
  return server;
}

class _BootstrapAdapter implements HttpClientAdapter {
  _BootstrapAdapter({this.statusCode = 200});

  final int statusCode;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{"felicitous":0,"cuckoo":"success","unsphered":{"extravagates":"iPhone 17","beachwear":6.3}}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

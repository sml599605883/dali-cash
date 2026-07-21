import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_endpoints.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RecordingAdapter adapter;
  late Dio dio;
  late ApiConfig config;
  late ApiClient client;

  setUp(() {
    adapter = RecordingAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    config = ApiConfig(
      apiBaseUrl: 'http://api.test/manlikely',
      signatureSecret: 'test-secret',
      commonParamsProvider: () async => <String, dynamic>{
        'crawdad': '1.0.0',
        'extravagates': 'iPhone',
        'ouzo': 'device-id',
        'glover': '18.0',
        'vox': 'appstore-ph-dali-cash-ios',
        'crestfallen': 'session-id',
        'sempervivums': 'device-id',
      },
      timestampProvider: () => 1000,
      randomDigitsProvider: (_) => '123456',
    );
    client = ApiClient(config, dio: dio);
  });

  test('GET puts signed and business params in query', () async {
    await client.get('/lutes/unsphered', params: {'uneager': '111111'});

    final request = adapter.lastRequest!;
    expect(request.uri.toString(), startsWith('http://api.test/manlikely/'));
    expect(request.method, 'GET');
    expect(request.queryParameters['uneager'], '111111');
    expect(request.queryParameters['crawdad'], '1.0.0');
    expect(request.queryParameters['hardballs'], '1000');
    expect(request.queryParameters['palefaces'], '123456');
    expect(request.queryParameters['dashy'], isNotEmpty);
  });

  test('homePage sends generated business params with GET', () async {
    await client.homePage();

    final request = adapter.lastRequest!;
    expect(request.method, 'GET');
    expect(request.path, endsWith(ApiEndpoints.homePage));
    expect(request.queryParameters['uneager'], '123456');
    expect(request.queryParameters['hemlock'], '123456');
  });

  test('dialog sends scene with GET', () async {
    await client.dialog(scene: 1);

    final request = adapter.lastRequest!;
    expect(request.method, 'GET');
    expect(request.path, endsWith(ApiEndpoints.dialog));
    expect(request.queryParameters['guarana'], 1);
  });

  test('bannerClickRecord posts documented id and generated value', () async {
    await client.bannerClickRecord(bannerConfigId: 'banner-42');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.bannerClickRecord));
    expect(request.data, {'genially': 'banner-42', 'symbiotes': '123456'});
  });

  test('sendSmsCode posts documented fields and generated value', () async {
    await client.sendSmsCode(phone: '9123456789');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.sendSmsCode));
    expect(request.data, {
      'diachronies': '9123456789',
      'tarletan': 'sms',
      'arillate': '123456',
    });
  });

  test('smsCodeLogin posts documented fields and generated values', () async {
    await client.smsCodeLogin(phone: '9123456789', code: '654321');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.smsCodeLogin));
    expect(request.data, {
      'handiest': '9123456789',
      'humiliations': '654321',
      'queans': '123456',
      'intricate': '123456',
    });
  });

  test('POST keeps signed params in query and data in form body', () async {
    await client.post('/lutes/diachronies', data: {'diachronies': '0917'});

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.queryParameters['crawdad'], '1.0.0');
    expect(request.queryParameters.containsKey('diachronies'), isFalse);
    expect(request.data, {'diachronies': '0917'});
    expect(request.contentType, Headers.formUrlEncodedContentType);
  });

  test('JSON POST keeps data in body and uses json content type', () async {
    await client.postJson('/lutes/typefounder', data: {'unsphered': 'cipher'});

    final request = adapter.lastRequest!;
    expect(request.queryParameters.containsKey('unsphered'), isFalse);
    expect(request.data, {'unsphered': 'cipher'});
    expect(request.contentType, Headers.jsonContentType);
  });

  test('multipart upload uses selected file field and signed query', () async {
    final directory = await Directory.systemTemp.createTemp('dali-upload-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/id.jpg')..writeAsStringSync('image');

    await client.upload(
      '/lutes/pertinencies',
      filePath: file.path,
      fileField: 'inexpensively',
      data: {'bear': 'scene'},
    );

    final request = adapter.lastRequest!;
    final formData = request.data as FormData;
    expect(request.queryParameters['dashy'], isNotEmpty);
    expect(
      formData.fields,
      contains(
        isA<MapEntry<String, String>>()
            .having((entry) => entry.key, 'key', 'bear')
            .having((entry) => entry.value, 'value', 'scene'),
      ),
    );
    expect(formData.files.single.key, 'inexpensively');
    expect(
      request.contentType,
      startsWith(Headers.multipartFormDataContentType),
    );
  });

  test('missing upload file fails before transport', () async {
    expect(
      () => client.upload(
        '/lutes/pertinencies',
        filePath: '/missing/file.jpg',
        fileField: 'inexpensively',
      ),
      throwsA(
        isA<ApiBusinessException>().having(
          (error) => error.message,
          'message',
          'Upload file does not exist',
        ),
      ),
    );
    expect(adapter.lastRequest, isNull);
  });

  test('auth expired invokes handler once and throws', () async {
    var calls = 0;
    adapter.responseBody =
        '{"felicitous":-2,"cuckoo":"Login expired","unsphered":null}';
    client = ApiClient(
      ApiConfig(
        apiBaseUrl: 'http://api.test/manlikely',
        signatureSecret: 'test-secret',
        commonParamsProvider: () async => const <String, dynamic>{},
        timestampProvider: () => 1000,
        randomDigitsProvider: (_) => '123456',
        authExpiredHandler: () async => calls++,
      ),
      dio: dio,
    );

    await expectLater(
      client.get('/lutes/unsphered'),
      throwsA(
        isA<ApiBusinessException>().having((error) => error.code, 'code', -2),
      ),
    );
    expect(calls, 1);
  });

  test('Dio connection failures become stable business errors', () async {
    adapter.error = DioException(
      requestOptions: RequestOptions(path: '/lutes/unsphered'),
      type: DioExceptionType.connectionError,
      message: 'Socket failed',
    );

    await expectLater(
      client.get('/lutes/unsphered'),
      throwsA(
        isA<ApiBusinessException>().having(
          (error) => error.message,
          'message',
          'Network connection failed',
        ),
      ),
    );
  });

  test('setProxy routes requests through configured proxy', () async {
    final targetServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var targetRequests = 0;
    final proxiedRequests = <HttpRequest>[];
    addTearDown(() async {
      await targetServer.close(force: true);
      await proxyServer.close(force: true);
    });

    targetServer.listen((request) {
      targetRequests++;
      request.response
        ..statusCode = 500
        ..close();
    });
    proxyServer.listen((request) {
      proxiedRequests.add(request);
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write('{"felicitous":0,"cuckoo":"success","unsphered":{}}')
        ..close();
    });

    final proxyClient = ApiClient(
      ApiConfig(
        apiBaseUrl: 'http://127.0.0.1:${targetServer.port}',
        signatureSecret: 'test-secret',
        commonParamsProvider: () async => const <String, dynamic>{},
        timestampProvider: () => 1000,
        randomDigitsProvider: (_) => '123456',
      ),
    )..setProxy(host: '127.0.0.1', port: proxyServer.port);

    await proxyClient.get('/lutes/unsphered');

    expect(proxyClient.proxyHost, '127.0.0.1');
    expect(proxyClient.proxyPort, proxyServer.port);
    expect(targetRequests, 0);
    expect(proxiedRequests, hasLength(1));
  });

  test('setProxy replaces a direct client after its first request', () async {
    final targetServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var targetRequests = 0;
    var proxyRequests = 0;
    addTearDown(() async {
      await targetServer.close(force: true);
      await proxyServer.close(force: true);
    });

    targetServer.listen((request) {
      targetRequests++;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write('{"felicitous":0,"cuckoo":"success","unsphered":{}}')
        ..close();
    });
    proxyServer.listen((request) {
      proxyRequests++;
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write('{"felicitous":0,"cuckoo":"success","unsphered":{}}')
        ..close();
    });

    final proxyClient = ApiClient(
      ApiConfig(
        apiBaseUrl: 'http://127.0.0.1:${targetServer.port}',
        signatureSecret: 'test-secret',
        commonParamsProvider: () async => const <String, dynamic>{},
        timestampProvider: () => 1000,
        randomDigitsProvider: (_) => '123456',
      ),
    );

    await proxyClient.get('/lutes/unsphered');
    proxyClient.setProxy(host: '127.0.0.1', port: proxyServer.port);
    await proxyClient.get('/lutes/unsphered');

    expect(targetRequests, 1);
    expect(proxyRequests, 1);
  });
}

class RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  String responseBody = '{"felicitous":0,"cuckoo":"success","unsphered":{}}';
  DioException? error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return ResponseBody.fromString(
      responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

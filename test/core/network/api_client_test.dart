import 'dart:async';
import 'dart:convert';
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

  test('productApply posts documented product and source fields', () async {
    await client.productApply(productId: 'product-42', source: '0');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.productApply));
    expect(request.data, {
      'highlands': 'product-42',
      'coresident': '0',
      'obduratenesses': '123456',
      'guck': '123456',
    });
  });

  test('productDetail posts documented product and generated fields', () async {
    await client.productDetail(productId: 'product-42');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.productDetail));
    expect(request.data, {
      'highlands': 'product-42',
      'coopting': '123456',
      'excursiveness': '123456',
      'revisionist': '123456',
    });
  });

  test(
    'basicPersonInfo gets documented product and generated fields',
    () async {
      await client.basicPersonInfo(productId: 'product-42');

      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(request.path, endsWith(ApiEndpoints.basicPersonInfo));
      expect(request.queryParameters['highlands'], 'product-42');
      expect(request.queryParameters['bear'], '123456');
    },
  );

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

  test('identity upload sends the documented Dali multipart fields', () async {
    final directory = await Directory.systemTemp.createTemp('dali-identity-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/id.jpg')..writeAsStringSync('image');

    await client.uploadImage(
      sociologeses: '11',
      scabble: '2',
      filePath: file.path,
      fileField: 'attach',
      rapscallion: 'PRC ID',
    );

    final formData = adapter.lastRequest!.data as FormData;
    expect(
      formData.fields,
      containsAll(<Matcher>[
        isA<MapEntry<String, String>>()
            .having((entry) => entry.key, 'key', 'sociologeses')
            .having((entry) => entry.value, 'value', '11'),
        isA<MapEntry<String, String>>()
            .having((entry) => entry.key, 'key', 'scabble')
            .having((entry) => entry.value, 'value', '2'),
        isA<MapEntry<String, String>>()
            .having((entry) => entry.key, 'key', 'rapscallion')
            .having((entry) => entry.value, 'value', 'PRC ID'),
      ]),
    );
    expect(formData.files.single.key, 'attach');
  });

  test('saveBasicInfo posts the documented identity fields', () async {
    await client.saveBasicInfo(
      annealers: '31-05-1995',
      imputes: 'ID-9988',
      crocidolites: 'JUAN DELA CRUZ',
      sociologeses: '11',
      rapscallion: 'PRC',
    );

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.saveBasicInfo));
    expect(request.data, {
      'annealers': '31-05-1995',
      'imputes': 'ID-9988',
      'crocidolites': 'JUAN DELA CRUZ',
      'sociologeses': '11',
      'rapscallion': 'PRC',
      'palefaces': '123456',
    });
  });

  test('face token posts the documented Dali fields', () async {
    await client.getFaceIdToken(orderNo: 'ORDER-42', type: '0');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.getFaceIdToken));
    expect(request.data, {
      'titled': 'ORDER-42',
      'sociologeses': '0',
      'motormen': '123456',
      'snakeroots': '123456',
    });
  });

  test('location report posts the documented Dali fields', () async {
    await client.reportLocation(
      province: 'Metro Manila',
      countryCode: 'PH',
      country: 'Philippines',
      street: 'Ayala Ave',
      latitude: '14.5547',
      longitude: '121.0244',
      city: 'Makati',
    );

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.uploadLocation));
    expect(request.data, {
      'prayerfulnesses': 'Metro Manila',
      'wealthiest': 'PH',
      'twiggier': 'Philippines',
      'psychobiology': 'Ayala Ave',
      'serpents': '14.5547',
      'shylocking': '121.0244',
      'mastless': 'Makati',
      'puristic': '123456',
      'suntan': '123456',
    });
  });

  test('Google market report posts identifiers and generated field', () async {
    await client.reportGoogleMarket(idfv: 'idfv-1', idfa: 'idfa-1');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.googleMarket));
    expect(request.data, {
      'pithecoid': 'idfv-1',
      'gnarls': '123456',
      'pyroxenoid': 'idfa-1',
    });
  });

  test('risk report posts the documented Dali fields', () async {
    await client.reportRiskBehavior(
      productId: 'product-1',
      sceneType: '9',
      orderNo: 'order-1',
      riskDeviceId: 'risk-1',
      idfa: 'idfa-1',
      longitude: '121.0244',
      latitude: '14.5547',
      startTime: '100',
      endTime: '101',
    );

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.buriedPoint));
    expect(request.data, {
      'thunderstruck': 'product-1',
      'ruthlessnesses': '9',
      'saggards': 'order-1',
      'snowmobiling': 'risk-1',
      'sunchoke': 'idfa-1',
      'shylocking': '121.0244',
      'serpents': '14.5547',
      'never': '100',
      'doucely': '101',
      'parametrization': '123456',
    });
  });

  test('device report posts only the encrypted payload', () async {
    await client.reportDeviceInfo(encryptedPayload: 'cipher');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.uploadDeviceInfo));
    expect(request.data, {'unsphered': 'cipher'});
  });

  test('Apple push report posts the documented token field', () async {
    await client.reportApplePushToken(token: 'apns-token');

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, endsWith(ApiEndpoints.uploadAppleToken));
    expect(request.data, {'skiagraph': 'apns-token'});
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

  test('bootstrap keeps default URLs when probe status is below 500', () async {
    config
      ..webBaseUrl = 'http://web.test'
      ..remoteConfigUrl = 'http://config.test/bootstrap';
    adapter.enqueueResponse(statusCode: 404);

    final reachable = await client.bootstrapBaseUrls();

    expect(reachable, isTrue);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.uri.toString(), 'http://api.test/manlikely');
    expect(config.apiBaseUrl, 'http://api.test/manlikely');
    expect(config.webBaseUrl, 'http://web.test');
  });

  test('bootstrap switches to plain remote URLs after server failure', () async {
    config
      ..webBaseUrl = 'http://web.test'
      ..remoteConfigUrl = 'http://config.test/bootstrap';
    adapter
      ..enqueueResponse(statusCode: 500)
      ..enqueueResponse(
        body:
            '{"apiBaseUrl":"https://backup-api.test/root","webBaseUrl":"https://backup-web.test"}',
      )
      ..enqueueResponse(statusCode: 204);

    final reachable = await client.bootstrapBaseUrls();

    expect(reachable, isTrue);
    expect(adapter.requests.map((request) => request.uri.toString()), <String>[
      'http://api.test/manlikely',
      'http://config.test/bootstrap',
      'https://backup-api.test/root',
    ]);
    expect(config.apiBaseUrl, 'https://backup-api.test/root');
    expect(config.webBaseUrl, 'https://backup-web.test');
  });

  test('bootstrap decodes base64 remote URLs after server failure', () async {
    config
      ..webBaseUrl = 'http://web.test'
      ..remoteConfigUrl = 'http://config.test/bootstrap';
    final encoded = base64Encode(
      utf8.encode(
        '{"apiBaseUrl":"https://encoded-api.test/root","webBaseUrl":"https://encoded-web.test"}',
      ),
    );
    adapter
      ..enqueueResponse(statusCode: 503)
      ..enqueueResponse(
        body: encoded,
        contentType: Headers.textPlainContentType,
      )
      ..enqueueResponse(statusCode: 404);

    final reachable = await client.bootstrapBaseUrls();

    expect(reachable, isTrue);
    expect(config.apiBaseUrl, 'https://encoded-api.test/root');
    expect(config.webBaseUrl, 'https://encoded-web.test');
  });

  test(
    'bootstrap keeps default URLs when remote config URL is empty',
    () async {
      config.webBaseUrl = 'http://web.test';
      adapter.enqueueResponse(statusCode: 500);

      final reachable = await client.bootstrapBaseUrls();

      expect(reachable, isFalse);
      expect(adapter.requests, hasLength(1));
      expect(config.apiBaseUrl, 'http://api.test/manlikely');
      expect(config.webBaseUrl, 'http://web.test');
    },
  );

  test('bootstrap keeps default URLs when remote config is invalid', () async {
    config
      ..webBaseUrl = 'http://web.test'
      ..remoteConfigUrl = 'http://config.test/bootstrap';
    adapter
      ..enqueueResponse(statusCode: 500)
      ..enqueueResponse(
        body: 'not-json-or-base64',
        contentType: Headers.textPlainContentType,
      );

    final reachable = await client.bootstrapBaseUrls();

    expect(reachable, isFalse);
    expect(config.apiBaseUrl, 'http://api.test/manlikely');
    expect(config.webBaseUrl, 'http://web.test');
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
  final List<RequestOptions> requests = <RequestOptions>[];
  String responseBody = '{"felicitous":0,"cuckoo":"success","unsphered":{}}';
  DioException? error;
  final List<_QueuedAdapterResponse> _queuedResponses =
      <_QueuedAdapterResponse>[];

  void enqueueResponse({
    String body = '',
    int statusCode = 200,
    String contentType = Headers.jsonContentType,
  }) {
    _queuedResponses.add(
      _QueuedAdapterResponse(
        body: body,
        statusCode: statusCode,
        contentType: contentType,
      ),
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    requests.add(options);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    final queued = _queuedResponses.isEmpty
        ? null
        : _queuedResponses.removeAt(0);
    return ResponseBody.fromString(
      queued?.body ?? responseBody,
      queued?.statusCode ?? 200,
      headers: {
        Headers.contentTypeHeader: [
          queued?.contentType ?? Headers.jsonContentType,
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _QueuedAdapterResponse {
  const _QueuedAdapterResponse({
    required this.body,
    required this.statusCode,
    required this.contentType,
  });

  final String body;
  final int statusCode;
  final String contentType;
}

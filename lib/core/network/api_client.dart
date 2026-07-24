import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../json/json.dart';
import 'api_config.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'api_signature.dart';

class ApiClient {
  ApiClient(this.config, {Dio? dio}) : dio = dio ?? Dio() {
    this.dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 20)
      ..contentType = Headers.formUrlEncodedContentType
      ..validateStatus = (_) => true;
  }

  final ApiConfig config;
  final Dio dio;
  bool _handlingAuthExpired = false;
  String? _proxyHost;
  int? _proxyPort;

  String? get proxyHost => _proxyHost;

  int? get proxyPort => _proxyPort;

  void setProxy({
    required String host,
    required int port,
    bool allowBadCertificates = false,
  }) {
    _proxyHost = host;
    _proxyPort = port;
    dio.httpClientAdapter.close(force: true);
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient()..findProxy = (_) => 'PROXY $host:$port;';
        if (allowBadCertificates) {
          client.badCertificateCallback = (_, _, _) => true;
        }
        return client;
      },
    );
  }

  Future<ApiResponse> homePage() {
    return get(
      ApiEndpoints.homePage,
      params: {'uneager': _randomDigits(6), 'hemlock': _randomDigits(6)},
    );
  }

  Future<ApiResponse> dialog({required int scene}) {
    return get(ApiEndpoints.dialog, params: {'guarana': scene});
  }

  Future<ApiResponse> bannerClickRecord({required String bannerConfigId}) {
    return post(
      ApiEndpoints.bannerClickRecord,
      data: {'genially': bannerConfigId, 'symbiotes': _randomDigits(6)},
    );
  }

  Future<ApiResponse> productApply({
    required String productId,
    String source = '0',
  }) {
    return post(
      ApiEndpoints.productApply,
      data: {
        'highlands': productId,
        'coresident': source,
        'obduratenesses': _randomDigits(6),
        'guck': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> productDetail({required String productId}) {
    return post(
      ApiEndpoints.productDetail,
      data: {
        'highlands': productId,
        'coopting': _randomDigits(6),
        'excursiveness': _randomDigits(6),
        'revisionist': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> basicPersonInfo({required String productId}) {
    return get(
      ApiEndpoints.basicPersonInfo,
      params: {'highlands': productId, 'bear': _randomDigits(6)},
    );
  }

  Future<ApiResponse> uploadImage({
    required String sociologeses,
    required String scabble,
    required String filePath,
    required String fileField,
    String? rapscallion,
    String? feoffed,
    String? miscasts,
    String? pileated,
    String? infantilisms,
  }) {
    return upload(
      ApiEndpoints.uploadImage,
      filePath: filePath,
      fileField: fileField,
      data: {
        'sociologeses': sociologeses,
        'scabble': scabble,
        'rapscallion': rapscallion,
        'feoffed': feoffed,
        'miscasts': miscasts,
        'pileated': pileated,
        'infantilisms': infantilisms,
      },
    );
  }

  Future<ApiResponse> saveBasicInfo({
    required String annealers,
    required String imputes,
    required String crocidolites,
    required String sociologeses,
    required String rapscallion,
  }) {
    return post(
      ApiEndpoints.saveBasicInfo,
      data: {
        'annealers': annealers,
        'imputes': imputes,
        'crocidolites': crocidolites,
        'sociologeses': sociologeses,
        'rapscallion': rapscallion,
        'palefaces': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> sendSmsCode({required String phone}) {
    return post(
      ApiEndpoints.sendSmsCode,
      data: {
        'diachronies': phone,
        'tarletan': 'sms',
        'arillate': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> smsCodeLogin({
    required String phone,
    required String code,
  }) {
    return post(
      ApiEndpoints.smsCodeLogin,
      data: {
        'handiest': phone,
        'humiliations': code,
        'queans': _randomDigits(6),
        'intricate': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> getDeviceName({required String deviceIdentifier}) {
    return post(
      ApiEndpoints.getDeviceName,
      data: {'crocidolites': deviceIdentifier, 'symbiotes': _randomDigits(6)},
    );
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic> params = const <String, dynamic>{},
  }) async {
    final query = await ApiSignature(
      config,
    ).buildSignedQuery(path: path, extraQuery: params);
    return _execute(() => dio.get<dynamic>(_url(path), queryParameters: query));
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> query = const <String, dynamic>{},
    Options? options,
  }) async {
    final signedQuery = await ApiSignature(
      config,
    ).buildSignedQuery(path: path, extraQuery: query);
    return _execute(
      () => dio.post<dynamic>(
        _url(path),
        queryParameters: signedQuery,
        data: data,
        options: options,
      ),
    );
  }

  Future<ApiResponse> postJson(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic> query = const <String, dynamic>{},
  }) {
    return post(
      path,
      data: data,
      query: query,
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  Future<ApiResponse> upload(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> query = const <String, dynamic>{},
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ApiBusinessException('Upload file does not exist');
    }

    final signedQuery = await ApiSignature(
      config,
    ).buildSignedQuery(path: path, extraQuery: query);
    final formData = FormData.fromMap({
      ...data,
      fileField: await MultipartFile.fromFile(file.path),
    });
    return _execute(
      () => dio.post<dynamic>(
        _url(path),
        queryParameters: signedQuery,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      ),
    );
  }

  Future<bool> bootstrapBaseUrls() async {
    if (await _isBaseUrlReachable(config.apiBaseUrl)) {
      return true;
    }

    if (config.remoteConfigUrl.isEmpty) {
      return false;
    }

    try {
      final response = await dio.get<dynamic>(config.remoteConfigUrl);
      final remoteConfig = _parseRemoteConfig(response.data);
      final apiBaseUrl = remoteConfig['apiBaseUrl'].stringValue;
      final webBaseUrl = remoteConfig['webBaseUrl'].stringValue;
      if (apiBaseUrl.isNotEmpty) {
        config.apiBaseUrl = apiBaseUrl;
      }
      if (webBaseUrl.isNotEmpty) {
        config.webBaseUrl = webBaseUrl;
      }
      if (apiBaseUrl.isEmpty) {
        return false;
      }
      return _isBaseUrlReachable(apiBaseUrl);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isBaseUrlReachable(String baseUrl) async {
    if (baseUrl.isEmpty) {
      return false;
    }
    try {
      final response = await dio.getUri<dynamic>(Uri.parse(baseUrl));
      final statusCode = response.statusCode;
      return statusCode != null && statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<ApiResponse> _execute(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return _handleResponse(response.data);
    } on DioException catch (error) {
      debugPrint(
        '[DaliNetworkDiag] Dio failure uri=${error.requestOptions.uri} '
        'type=${error.type} error=${error.error}',
      );
      throw ApiBusinessException(ApiErrorMessage.resolve(error));
    }
  }

  Future<ApiResponse> _handleResponse(dynamic raw) async {
    final response = ApiResponse.fromRaw(Json(raw));
    if (response.isAuthExpired) {
      await _handleAuthExpired();
    }
    return response.ensureSuccess();
  }

  Future<void> _handleAuthExpired() async {
    if (_handlingAuthExpired) {
      throw ApiBusinessException('Login expired', code: -2);
    }
    _handlingAuthExpired = true;
    try {
      await config.authExpiredHandler?.call();
    } finally {
      _handlingAuthExpired = false;
    }
    throw ApiBusinessException('Login expired', code: -2);
  }

  String _randomDigits(int length) {
    return config.randomDigitsProvider?.call(length) ??
        ApiSignature.randomDigits(length);
  }

  Json _parseRemoteConfig(dynamic raw) {
    if (raw is Map) {
      return Json(raw);
    }
    final body = raw?.toString().trim() ?? '';
    if (body.isEmpty) {
      return Json(null);
    }

    final parsed = Json.parse(body);
    if (parsed.mapOrNull != null) {
      return parsed;
    }
    try {
      return Json.parseBytes(base64Decode(body));
    } catch (_) {
      return Json(null);
    }
  }

  String _url(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${config.apiBaseUrl}${path.startsWith('/') ? path : '/$path'}';
  }
}

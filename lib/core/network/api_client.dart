import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

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

  Future<ApiResponse> _execute(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      return _handleResponse(response.data);
    } on DioException catch (error) {
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

  String _url(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${config.apiBaseUrl}${path.startsWith('/') ? path : '/$path'}';
  }
}

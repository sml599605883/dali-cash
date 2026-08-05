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

  Future<ApiResponse> reCredit() {
    return get(
      ApiEndpoints.reCredit,
      params: {'marksmanship': _randomDigits(6)},
    );
  }

  Future<ApiResponse> logout() {
    return get(
      ApiEndpoints.logout,
      params: {'rivulose': _randomDigits(6), 'transfection': _randomDigits(6)},
    );
  }

  Future<ApiResponse> userDelete() {
    return get(ApiEndpoints.userDelete, params: {'tautogs': _randomDigits(6)});
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

  Future<ApiResponse> productPush({
    required String orderNo,
    required String amount,
    required String term,
    required String termType,
  }) {
    return post(
      ApiEndpoints.productPush,
      data: {
        'titled': orderNo,
        'injective': amount,
        'resmooth': term,
        'mispatch': termType,
        'gulpers': _randomDigits(6),
        'tap': _randomDigits(6),
        'verste': _randomDigits(6),
        'respective': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> orderList({required String status}) {
    return post(
      ApiEndpoints.orderList,
      data: {'anfractuosity': status, 'redeployments': '1', 'unornate': '50'},
    );
  }

  Future<ApiResponse> retryOriginalAccount({required String orderNo}) {
    return post(ApiEndpoints.userReloan, data: {'saggards': orderNo});
  }

  Future<ApiResponse> userAccountList({required String productId}) {
    return post(
      ApiEndpoints.userCardList,
      data: {
        'highlands': productId,
        'nonanimal': _randomDigits(6),
        'cornuted': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> changeOrderAccount({
    required String orderNo,
    required String bindId,
  }) {
    return post(
      ApiEndpoints.changeOrderAccount,
      data: {
        'titled': orderNo,
        'hoover': bindId,
        'brontosauruses': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> retentionPopup({
    required String type,
    required String productId,
  }) {
    return post(
      ApiEndpoints.retentionDialog,
      data: {
        'omegas': type.trim(),
        'thunderstruck': productId.trim(),
        'jawlines': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> basicPersonInfo({required String productId}) {
    return get(
      ApiEndpoints.basicPersonInfo,
      params: {'highlands': productId, 'bear': _randomDigits(6)},
    );
  }

  Future<ApiResponse> personalInfo({required String productId}) {
    return post(
      ApiEndpoints.personalInfo,
      data: {'highlands': productId, 'suiting': _randomDigits(6)},
    );
  }

  Future<ApiResponse> savePersonalInfo({
    required String productId,
    required Map<String, String> fields,
  }) {
    return post(
      ApiEndpoints.savePersonalInfo,
      data: {
        ...fields,
        'highlands': productId,
        'confit': _randomDigits(6),
        'chromophobe': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> jobInfo({required String productId}) {
    return get(
      ApiEndpoints.jobInfo,
      params: {'highlands': productId, 'suiting': _randomDigits(6)},
    );
  }

  Future<ApiResponse> saveJobInfo({
    required String productId,
    required Map<String, String> fields,
  }) {
    return post(
      ApiEndpoints.saveJobInfo,
      data: {
        ...fields,
        'highlands': productId,
        'salivas': _randomDigits(6),
        'jumped': _randomDigits(6),
        'punitory': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> extInfoV2({required String productId}) {
    return get(
      ApiEndpoints.extInfoV2,
      params: {'highlands': productId, 'populace': _randomDigits(6)},
    );
  }

  Future<ApiResponse> saveExtInfoV2({
    required String productId,
    required List<Map<String, String>> contacts,
  }) {
    return post(
      ApiEndpoints.saveExtInfoV2,
      data: {
        'highlands': productId,
        'unsphered': jsonEncode(contacts),
        'vigorishes': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> addressInit() {
    return get(ApiEndpoints.cityInit);
  }

  Future<ApiResponse> cardInit({required String productId}) {
    return get(
      ApiEndpoints.cardInit,
      params: {
        'highlands': productId,
        'parametrization': _randomDigits(6),
        'uredia': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> bindCard({
    required String productId,
    required String cardType,
    required Map<String, String> fields,
    String livenessType = '',
    String livenessId = '',
    String image = '',
    String businessId = '',
    String license = '',
  }) {
    return post(
      ApiEndpoints.bindCard,
      acceptedCodes: const {20000},
      data: {
        ...fields,
        'highlands': productId,
        'rapscallion': cardType,
        'weave': _randomDigits(6),
        'pileated': livenessType,
        'feoffed': livenessId,
        'attach': image,
        'infantilisms': businessId,
        'miscasts': license,
      },
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

  Future<ApiResponse> getFaceIdToken({
    required String orderNo,
    String type = '0',
  }) {
    return post(
      ApiEndpoints.getFaceIdToken,
      data: {
        'titled': orderNo,
        'sociologeses': type,
        'motormen': _randomDigits(6),
        'snakeroots': _randomDigits(6),
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

  Future<ApiResponse> reportLocation({
    String? province,
    required String countryCode,
    required String country,
    required String street,
    required String latitude,
    required String longitude,
    required String city,
  }) {
    return post(
      ApiEndpoints.uploadLocation,
      data: {
        'prayerfulnesses': province,
        'wealthiest': countryCode,
        'twiggier': country,
        'psychobiology': street,
        'serpents': latitude,
        'shylocking': longitude,
        'mastless': city,
        'puristic': _randomDigits(6),
        'suntan': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> reportGoogleMarket({
    required String idfv,
    required String idfa,
  }) {
    return post(
      ApiEndpoints.googleMarket,
      data: {'pithecoid': idfv, 'gnarls': _randomDigits(6), 'pyroxenoid': idfa},
    );
  }

  Future<ApiResponse> reportRiskBehavior({
    required String productId,
    required String sceneType,
    required String orderNo,
    required String riskDeviceId,
    required String idfa,
    required String longitude,
    required String latitude,
    required String startTime,
    required String endTime,
  }) {
    return post(
      ApiEndpoints.buriedPoint,
      data: {
        'thunderstruck': productId,
        'ruthlessnesses': sceneType,
        'saggards': orderNo,
        'snowmobiling': riskDeviceId,
        'sunchoke': idfa,
        'shylocking': longitude,
        'serpents': latitude,
        'never': startTime,
        'doucely': endTime,
        'parametrization': _randomDigits(6),
      },
    );
  }

  Future<ApiResponse> reportDeviceInfo({required String encryptedPayload}) {
    return post(
      ApiEndpoints.uploadDeviceInfo,
      data: {'unsphered': encryptedPayload},
    );
  }

  Future<ApiResponse> reportApplePushToken({required String token}) {
    return post(ApiEndpoints.uploadAppleToken, data: {'skiagraph': token});
  }

  Future<ApiResponse> reportTrustDecisionResult({
    required String livenessId,
    required String requestId,
    required String resultCode,
    required String result,
  }) {
    return post(
      ApiEndpoints.trustDecisionReport,
      data: {
        'retestifies': livenessId,
        'alloplasm': requestId,
        'trihedral': resultCode,
        'tucking': result,
      },
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
    Set<int> acceptedCodes = const <int>{},
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
      acceptedCodes: acceptedCodes,
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
    Future<Response<dynamic>> Function() request, {
    Set<int> acceptedCodes = const <int>{},
  }) async {
    try {
      final response = await request();
      return _handleResponse(response.data, acceptedCodes: acceptedCodes);
    } on DioException catch (error) {
      debugPrint(
        '[DaliNetworkDiag] Dio failure uri=${error.requestOptions.uri} '
        'type=${error.type} error=${error.error}',
      );
      throw ApiBusinessException(ApiErrorMessage.resolve(error));
    }
  }

  Future<ApiResponse> _handleResponse(
    dynamic raw, {
    Set<int> acceptedCodes = const <int>{},
  }) async {
    final response = ApiResponse.fromRaw(Json(raw));
    if (response.isAuthExpired) {
      await _handleAuthExpired();
    }
    if (acceptedCodes.contains(response.code)) {
      return response;
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

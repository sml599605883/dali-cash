import 'dart:async';
import 'dart:typed_data';

import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:dio/dio.dart';

const noNetworkTransportMessage = 'Unexpected network transport in widget test';

MainBinding testMainBinding() {
  return MainBinding(
    apiClient: NoNetworkApiClient(),
    showError: (_) {},
    showNotice: (_) {},
    showLoading: () async {},
    dismissLoading: () async {},
  );
}

class NoNetworkApiClient extends ApiClient {
  NoNetworkApiClient() : super(ApiConfig(), dio: _failFastDio()) {
    final store = SessionStore.memory();
    config.sessionStore = store;
    unawaited(store.saveSessionId('test-session'));
    unawaited(store.savePhone('9620001300'));
  }

  final Completer<ApiResponse> _homeRequest = Completer<ApiResponse>();
  int logoutCalls = 0;
  int userDeleteCalls = 0;
  Object? logoutError;
  Object? userDeleteError;

  @override
  Future<ApiResponse> homePage() => _homeRequest.future;

  @override
  Future<ApiResponse> logout() async {
    logoutCalls++;
    if (logoutError case final error?) throw error;
    return ApiResponse(code: 0, message: '', states: Json(null));
  }

  @override
  Future<ApiResponse> userDelete() async {
    userDeleteCalls++;
    if (userDeleteError case final error?) throw error;
    return ApiResponse(code: 0, message: '', states: Json(null));
  }

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic> params = const <String, dynamic>{},
  }) {
    return _blockedTransport();
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> query = const <String, dynamic>{},
    Set<int> acceptedCodes = const <int>{},
    Options? options,
  }) {
    return _blockedTransport();
  }

  @override
  Future<ApiResponse> postJson(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic> query = const <String, dynamic>{},
  }) {
    return _blockedTransport();
  }

  @override
  Future<ApiResponse> upload(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, dynamic> data = const <String, dynamic>{},
    Map<String, dynamic> query = const <String, dynamic>{},
  }) {
    return _blockedTransport();
  }
}

Future<ApiResponse> _blockedTransport() {
  return Future<ApiResponse>.error(UnsupportedError(noNetworkTransportMessage));
}

Dio _failFastDio() {
  return Dio()..httpClientAdapter = _FailFastAdapter();
}

class _FailFastAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw UnsupportedError(noNetworkTransportMessage);
  }

  @override
  void close({bool force = false}) {}
}

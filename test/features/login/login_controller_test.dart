import 'dart:async';

import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/login/login_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late SessionStore sessionStore;
  late _FakeLoginApiClient apiClient;
  late List<String> messages;
  late int successCalls;
  late int dismissKeyboardCalls;
  late LoginController controller;

  setUp(() {
    Get.testMode = true;
    sessionStore = SessionStore.memory();
    apiClient = _FakeLoginApiClient();
    messages = <String>[];
    successCalls = 0;
    dismissKeyboardCalls = 0;
  });

  tearDown(Get.reset);

  LoginController createController() {
    controller = LoginController(
      apiClient: apiClient,
      sessionStore: sessionStore,
      showLoading: () async {},
      dismissLoading: () async {},
      showMessage: (message) async => messages.add(message),
      onLoginSuccess: () async => successCalls++,
      dismissKeyboard: () => dismissKeyboardCalls++,
      countdownInterval: const Duration(milliseconds: 10),
    );
    Get.put<LoginController>(controller);
    return controller;
  }

  test('loads remembered phone without replacing active input', () async {
    await sessionStore.savePhone('9123456789');
    final value = createController();
    value.phoneController.text = '9987654321';

    await value.loadRememberedPhone();

    expect(value.phoneController.text, '9987654321');
  });

  test(
    'successful SMS request starts countdown and ignores duplicate',
    () async {
      final requestCompleter = Completer<ApiResponse>();
      apiClient.smsRequest = requestCompleter.future;
      final value = createController();
      value.phoneController.text = '9123456789';

      final first = value.requestSmsCode();
      final duplicate = value.requestSmsCode();
      await Future<void>.delayed(Duration.zero);
      expect(apiClient.smsRequestCalls, 1);

      requestCompleter.complete(_response(message: 'sent'));
      await Future.wait([first, duplicate]);

      expect(value.countdownSeconds, 60);
      expect(value.requestingCode, isFalse);
      expect(messages, ['sent']);
    },
  );

  test('six code digits log in, persist session and notify success', () async {
    apiClient.loginResponse = _response(
      states: {'crestfallen': 'session-token'},
    );
    final value = createController();
    value.phoneController.text = '9123456789';

    value.codeController.text = '654321';
    await Future<void>.delayed(Duration.zero);

    expect(apiClient.loginCalls, 1);
    expect(await sessionStore.sessionId(), 'session-token');
    expect(await sessionStore.phone(), '9123456789');
    expect(successCalls, 1);
    expect(dismissKeyboardCalls, 1);
  });

  test('login failure clears code and reports stable message', () async {
    apiClient.loginError = ApiBusinessException('Invalid SMS code');
    final value = createController();
    value.phoneController.text = '9123456789';

    value.codeController.text = '123456';
    await Future<void>.delayed(Duration.zero);

    expect(value.codeController.text, isEmpty);
    expect(messages, ['Invalid SMS code']);
    expect(successCalls, 0);
  });

  test('agreement starts accepted and can be toggled', () {
    final value = createController();

    expect(value.agreementAccepted, isTrue);
    value.toggleAgreement();
    expect(value.agreementAccepted, isFalse);
  });

  test('six code digits dismiss keyboard and prompt for agreement', () async {
    final value = createController();
    value.phoneController.text = '9123456789';
    value.toggleAgreement();

    value.codeController.text = '654321';
    await Future<void>.delayed(Duration.zero);

    expect(dismissKeyboardCalls, 1);
    expect(messages, ['Please agree to the Privacy Policy']);
    expect(apiClient.loginCalls, 0);
  });
}

ApiResponse _response({
  String message = 'success',
  Map<String, dynamic> states = const <String, dynamic>{},
}) {
  return ApiResponse(code: 0, message: message, states: Json(states));
}

class _FakeLoginApiClient extends ApiClient {
  _FakeLoginApiClient() : super(ApiConfig(), dio: Dio());

  int smsRequestCalls = 0;
  int loginCalls = 0;
  Future<ApiResponse>? smsRequest;
  ApiResponse loginResponse = _response(
    states: const {'crestfallen': 'session-token'},
  );
  Object? loginError;

  @override
  Future<ApiResponse> sendSmsCode({required String phone}) {
    smsRequestCalls++;
    return smsRequest ?? Future.value(_response(message: 'sent'));
  }

  @override
  Future<ApiResponse> smsCodeLogin({
    required String phone,
    required String code,
  }) async {
    loginCalls++;
    final error = loginError;
    if (error != null) {
      throw error;
    }
    return loginResponse;
  }
}

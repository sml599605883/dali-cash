import 'dart:async';

import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/login/login_binding.dart';
import 'package:dali_cash/features/login/login_controller.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ApiClient>(_LoginApiClient());
  });
  tearDown(Get.reset);

  test('login success reports scene 1 without requesting location', () async {
    final events = <String>[];
    final binding = LoginBinding(
      productId: 'product-1',
      startTimeSeconds: 100,
      reportLoginSuccess: () async => events.add('login-reporting'),
      reportRiskScene:
          ({
            required productId,
            required sceneType,
            required startTimeSeconds,
          }) async {
            events.add('$sceneType:$productId:$startTimeSeconds');
          },
      navigateBack: () => events.add('back'),
      showLoading: () async {},
      dismissLoading: () async {},
      showMessage: (_) async {},
    );
    binding.dependencies();
    final controller = Get.find<LoginController>();
    controller.phoneController.text = '9123456789';

    controller.codeController.text = '654321';
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(events, ['login-reporting', '1:product-1:100', 'back']);
  });

  test('login success reports scene 1 when product id is empty', () async {
    final scenes = <String>[];
    final binding = LoginBinding(
      startTimeSeconds: 100,
      reportLoginSuccess: () async {},
      reportRiskScene:
          ({
            required productId,
            required sceneType,
            required startTimeSeconds,
          }) async {
            scenes.add('$sceneType:$productId');
          },
      navigateBack: () {},
      showLoading: () async {},
      dismissLoading: () async {},
      showMessage: (_) async {},
    );
    binding.dependencies();
    final controller = Get.find<LoginController>();
    controller.phoneController.text = '9123456789';
    controller.codeController.text = '654321';
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(scenes, ['1:']);
  });

  test('login success refreshes Home with the new session', () async {
    final apiClient = Get.find<ApiClient>() as _LoginApiClient;
    final homeLoading = Completer<void>();
    var homeLoadingCalls = 0;
    final mainController = Get.put<MainController>(
      MainController(
        apiClient: apiClient,
        showError: (_) {},
        showNotice: (_) {},
        showLoading: () {
          homeLoadingCalls++;
          return homeLoading.future;
        },
        dismissLoading: () async {},
      ),
    );
    LoginBinding(
      reportLoginSuccess: () async {},
      reportRiskScene:
          ({
            required productId,
            required sceneType,
            required startTimeSeconds,
          }) async {},
      navigateBack: () {
        unawaited(mainController.requestHomeDataIfVisible());
      },
      showLoading: () async {},
      dismissLoading: () async {},
      showMessage: (_) async {},
    ).dependencies();
    final controller = Get.find<LoginController>();
    controller.phoneController.text = '9123456789';

    controller.codeController.text = '654321';
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(homeLoadingCalls, 1);
    homeLoading.complete();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(apiClient.homeCalls, 1);
  });
}

class _LoginApiClient extends ApiClient {
  _LoginApiClient() : super(ApiConfig(sessionStore: SessionStore.memory()));

  @override
  Future<ApiResponse> smsCodeLogin({
    required String phone,
    required String code,
  }) async {
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json({'crestfallen': 'session-token'}),
    );
  }

  int homeCalls = 0;

  @override
  Future<ApiResponse> homePage() async {
    homeCalls++;
    return ApiResponse(code: 0, message: 'success', states: Json(null));
  }

  @override
  Future<ApiResponse> dialog({required int scene}) async {
    return ApiResponse(code: 0, message: 'success', states: Json(null));
  }
}

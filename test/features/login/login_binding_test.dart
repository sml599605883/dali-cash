import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/permissions/permission_coordinator.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/login/login_binding.dart';
import 'package:dali_cash/features/login/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ApiClient>(_LoginApiClient());
  });
  tearDown(Get.reset);

  test(
    'login success waits for location decision then reports scene 1',
    () async {
      final events = <String>[];
      final binding = LoginBinding(
        productId: 'product-1',
        startTimeSeconds: 100,
        requestLocation: () async {
          events.add('location');
          return CertificationLocationDecision.denied;
        },
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

      expect(events, [
        'location',
        'login-reporting',
        '1:product-1:100',
        'back',
      ]);
    },
  );
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
}

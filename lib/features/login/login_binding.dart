import 'dart:async';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../core/json/json.dart';
import '../../core/network/api_client.dart';
import '../../core/permissions/permission_coordinator.dart';
import '../../core/report/dali_report_service.dart';
import 'login_controller.dart';

typedef LoginLocationRequester =
    Future<CertificationLocationDecision> Function();
typedef LoginReportAction = Future<void> Function();
typedef LoginRiskReporter =
    Future<void> Function({
      required String productId,
      required String sceneType,
      required int startTimeSeconds,
    });
typedef LoginNavigateBack = void Function();

class LoginBinding extends Bindings {
  LoginBinding({
    this.productId,
    this.startTimeSeconds,
    this.nowSeconds = DaliReportService.nowSeconds,
    LoginLocationRequester? requestLocation,
    LoginReportAction? reportLoginSuccess,
    LoginRiskReporter? reportRiskScene,
    LoginNavigateBack? navigateBack,
    LoginAsyncAction? showLoading,
    LoginAsyncAction? dismissLoading,
    LoginMessagePresenter? showMessage,
  }) : requestLocation =
           requestLocation ??
           PermissionCoordinator.instance.requestCertificationLocation,
       reportLoginSuccess = reportLoginSuccess ?? _reportLoginSuccess,
       reportRiskScene = reportRiskScene ?? _reportRiskScene,
       navigateBack = navigateBack ?? _navigateBack,
       showLoading = showLoading ?? _showLoading,
       dismissLoading = dismissLoading ?? EasyLoading.dismiss,
       showMessage = showMessage ?? _showMessage;

  final String? productId;
  final int? startTimeSeconds;
  final int Function() nowSeconds;
  final LoginLocationRequester requestLocation;
  final LoginReportAction reportLoginSuccess;
  final LoginRiskReporter reportRiskScene;
  final LoginNavigateBack navigateBack;
  final LoginAsyncAction showLoading;
  final LoginAsyncAction dismissLoading;
  final LoginMessagePresenter showMessage;

  @override
  void dependencies() {
    final apiClient = Get.find<ApiClient>();
    final resolvedProductId =
        productId?.trim() ??
        Json(Get.arguments)['highlands'].stringValue.trim();
    final resolvedStartTime = startTimeSeconds ?? nowSeconds();
    Get.lazyPut<LoginController>(
      () => LoginController(
        apiClient: apiClient,
        sessionStore: apiClient.config.sessionStore,
        showLoading: showLoading,
        dismissLoading: dismissLoading,
        showMessage: showMessage,
        onLoginSuccess: () async {
          await requestLocation();
          await reportLoginSuccess();
          if (resolvedProductId.isNotEmpty) {
            unawaited(
              reportRiskScene(
                productId: resolvedProductId,
                sceneType: '1',
                startTimeSeconds: resolvedStartTime,
              ),
            );
          }
          navigateBack();
        },
      ),
    );
  }

  static Future<void> _reportLoginSuccess() async {
    await DaliReportService.current?.loginSucceeded();
  }

  static Future<void> _reportRiskScene({
    required String productId,
    required String sceneType,
    required int startTimeSeconds,
  }) {
    return DaliReportService.current?.reportRisk(
      productId: productId,
      scene: sceneType,
      startedAtSeconds: startTimeSeconds,
    ) ?? Future<void>.value();
  }

  static void _navigateBack() => Get.back<void>();

  static Future<void> _showLoading() => EasyLoading.show(status: 'Loading...');

  static Future<void> _showMessage(String message) {
    if (message.trim().isEmpty) return Future<void>.value();
    return EasyLoading.showToast(message);
  }
}

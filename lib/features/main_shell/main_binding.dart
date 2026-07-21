import 'dart:async';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import 'main_controller.dart';

class MainBinding extends Bindings {
  MainBinding({
    this.apiClient,
    HomeMessagePresenter? showError,
    HomeMessagePresenter? showNotice,
  }) : showError = showError ?? _showError,
       showNotice = showNotice ?? _showNotice;

  final ApiClient? apiClient;
  final HomeMessagePresenter showError;
  final HomeMessagePresenter showNotice;

  @override
  void dependencies() {
    if (!Get.isRegistered<ApiClient>()) {
      Get.put<ApiClient>(apiClient ?? ApiClient(ApiConfig()), permanent: true);
    }
    if (!Get.isRegistered<MainController>()) {
      Get.put<MainController>(
        MainController(
          apiClient: Get.find<ApiClient>(),
          showError: showError,
          showNotice: showNotice,
        ),
      );
    }
  }

  static void _showError(String message) {
    unawaited(EasyLoading.showError(message));
  }

  static void _showNotice(String message) {
    unawaited(EasyLoading.showToast(message));
  }
}

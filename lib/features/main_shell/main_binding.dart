import 'dart:async';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../app/navigation/navigation_helper.dart';
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
    ApiClient client;
    if (Get.isRegistered<ApiClient>()) {
      client = Get.find<ApiClient>();
    } else {
      client = apiClient ?? ApiClient(ApiConfig());
      Get.put<ApiClient>(client, permanent: true);
    }
    if (!Get.isRegistered<MainController>()) {
      Get.put<MainController>(
        MainController(
          apiClient: client,
          showError: showError,
          showNotice: showNotice,
        ),
      );
    }
    final controller = Get.find<MainController>();
    if (!controller.hasApiClient) {
      controller.onNetworkReady(client);
    }
    NavigationHelper.mainTabNavigator = (index) {
      return controller.selectTab(index);
    };
  }

  static void _showError(String message) {
    unawaited(EasyLoading.showError(message));
  }

  static void _showNotice(String message) {
    unawaited(EasyLoading.showToast(message));
  }
}

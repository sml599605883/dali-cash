import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    final apiClient = Get.find<ApiClient>();
    Get.lazyPut<LoginController>(
      () => LoginController(
        apiClient: apiClient,
        sessionStore: apiClient.config.sessionStore,
        showLoading: () => EasyLoading.show(status: 'Loading...'),
        dismissLoading: EasyLoading.dismiss,
        showMessage: (message) {
          if (message.trim().isEmpty) {
            return Future<void>.value();
          }
          return EasyLoading.showToast(message);
        },
        onLoginSuccess: () async => Get.back<void>(),
      ),
    );
  }
}

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/json/json.dart';
import '../../../core/network/api_client.dart';
import 'identity_selection_controller.dart';

class IdentitySelectionBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Json(Get.arguments);
    Get.lazyPut<IdentitySelectionController>(
      () => IdentitySelectionController(
        apiClient: Get.find<ApiClient>(),
        productId: arguments['highlands'].stringValue,
        openUpload: (productId, cardType) {
          Get.toNamed<void>(
            AppRoutes.identityUpload,
            arguments: {'highlands': productId, 'cardType': cardType},
          );
        },
      ),
    );
  }
}

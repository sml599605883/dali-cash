import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/features/certification/identity_selection/identity_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late _FakeApiClient apiClient;
  late List<String> logs;

  setUp(() {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    logs = <String>[];
  });

  tearDown(Get.reset);

  test(
    'loads first lumbagos group as recommended and merges the rest',
    () async {
      apiClient.states = {
        'lumbagos': [
          ['PRC', 'SSS', 'PRC', ''],
          ['TIN', 'VOTERID'],
          ['NATIONALID'],
        ],
      };
      final controller = IdentitySelectionController(
        apiClient: apiClient,
        productId: ' product-42 ',
        logger: logs.add,
      );

      await controller.load();

      expect(apiClient.productIds, ['product-42']);
      expect(controller.state, IdentitySelectionState.ready);
      expect(controller.recommendedTypes, ['PRC', 'SSS']);
      expect(controller.otherTypes, ['TIN', 'VOTERID', 'NATIONALID']);
    },
  );

  test('exposes empty and error states without throwing', () async {
    final controller = IdentitySelectionController(
      apiClient: apiClient,
      productId: 'product-42',
      logger: logs.add,
    );

    await controller.load();
    expect(controller.state, IdentitySelectionState.empty);

    apiClient.error = ApiBusinessException('Identity unavailable');
    await controller.load();
    expect(controller.state, IdentitySelectionState.error);
    expect(controller.errorMessage, 'Identity unavailable');
  });

  test('selection logs normalized product id and card type', () {
    final controller = IdentitySelectionController(
      apiClient: apiClient,
      productId: ' product-42 ',
      logger: logs.add,
    );

    controller.selectType(' PRC ');

    expect(logs, ['identity selected: productId=product-42, type=PRC']);
  });

  test('selection completes risk scene 2 with entry time', () async {
    final reports = <Map<String, Object?>>[];
    final controller = IdentitySelectionController(
      apiClient: apiClient,
      productId: 'product-42',
      logger: logs.add,
      startTimeSeconds: 100,
      reportRiskScene:
          ({
            required productId,
            required sceneType,
            required startTimeSeconds,
          }) async {
            reports.add({
              'productId': productId,
              'sceneType': sceneType,
              'startTimeSeconds': startTimeSeconds,
            });
          },
    );

    controller.selectType('PRC');
    await Future<void>.delayed(Duration.zero);

    expect(reports, [
      {'productId': 'product-42', 'sceneType': '2', 'startTimeSeconds': 100},
    ]);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig());

  final List<String> productIds = <String>[];
  Map<String, dynamic> states = <String, dynamic>{};
  Object? error;

  @override
  Future<ApiResponse> basicPersonInfo({required String productId}) async {
    productIds.add(productId);
    final requestError = error;
    if (requestError != null) {
      throw requestError;
    }
    return ApiResponse(code: 0, message: '', states: Json(states));
  }
}

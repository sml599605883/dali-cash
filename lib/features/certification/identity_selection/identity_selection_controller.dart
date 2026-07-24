import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';

import '../../../core/json/json.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/report/dali_report_service.dart';

enum IdentitySelectionState { loading, ready, empty, error }

typedef IdentitySelectionLogger = void Function(String message);
typedef IdentityUploadNavigator =
    void Function(String productId, String cardType);
typedef IdentitySelectionRiskReporter =
    Future<void> Function({
      required String productId,
      required String sceneType,
      required int startTimeSeconds,
    });

class IdentitySelectionController extends GetxController {
  IdentitySelectionController({
    required this.apiClient,
    required String productId,
    IdentitySelectionLogger? logger,
    this.openUpload,
    int? startTimeSeconds,
    IdentitySelectionRiskReporter? reportRiskScene,
  }) : productId = productId.trim(),
       logger = logger ?? _defaultLogger,
       startTimeSeconds = startTimeSeconds ?? DaliReportService.nowSeconds(),
       reportRiskScene = reportRiskScene ?? _defaultReportRiskScene;

  final ApiClient apiClient;
  final String productId;
  final IdentitySelectionLogger logger;
  final IdentityUploadNavigator? openUpload;
  final int startTimeSeconds;
  final IdentitySelectionRiskReporter reportRiskScene;

  IdentitySelectionState state = IdentitySelectionState.loading;
  List<String> recommendedTypes = const <String>[];
  List<String> otherTypes = const <String>[];
  String errorMessage = '';

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    state = IdentitySelectionState.loading;
    errorMessage = '';
    update();

    if (productId.isEmpty) {
      state = IdentitySelectionState.error;
      errorMessage = 'Product ID is missing';
      update();
      return;
    }

    try {
      final response = await apiClient.basicPersonInfo(productId: productId);
      final groups = response.states['lumbagos'].listValue;
      recommendedTypes = groups.isEmpty
          ? const <String>[]
          : _parseTypes(groups.first);
      otherTypes = _parseTypes(
        Json(groups.skip(1).expand((group) => group.listValue).toList()),
      );
      state = recommendedTypes.isEmpty && otherTypes.isEmpty
          ? IdentitySelectionState.empty
          : IdentitySelectionState.ready;
    } catch (error) {
      recommendedTypes = const <String>[];
      otherTypes = const <String>[];
      state = IdentitySelectionState.error;
      errorMessage = ApiErrorMessage.resolve(error);
    }
    update();
  }

  void selectType(String type) {
    final normalizedType = type.trim();
    if (normalizedType.isEmpty) {
      return;
    }
    logger('identity selected: productId=$productId, type=$normalizedType');
    unawaited(
      reportRiskScene(
        productId: productId,
        sceneType: '2',
        startTimeSeconds: startTimeSeconds,
      ),
    );
    openUpload?.call(productId, normalizedType);
  }

  static List<String> _parseTypes(Json source) {
    final seen = <String>{};
    return source.listValue
        .map((item) => item.stringValue.trim())
        .where((item) => item.isNotEmpty && seen.add(item))
        .toList(growable: false);
  }

  static void _defaultLogger(String message) {
    log(message, name: 'IdentitySelection');
  }

  static Future<void> _defaultReportRiskScene({
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
}

import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/features/certification/identity_selection/identity_selection_controller.dart';
import 'package:dali_cash/features/certification/identity_selection/identity_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('renders recommended and other lumbagos groups vertically', (
    tester,
  ) async {
    final apiClient = _FakeApiClient()
      ..states = {
        'lumbagos': [
          ['PRC ID', 'SSS ID'],
          ["DRIVER'S LICENSE", 'TIN ID'],
        ],
      };
    final logs = <String>[];
    final navigated = <(String productId, String cardType)>[];
    Get.put(
      IdentitySelectionController(
        apiClient: apiClient,
        productId: 'product-42',
        logger: logs.add,
        openUpload: (productId, cardType) {
          navigated.add((productId, cardType));
        },
      ),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: IdentitySelectionPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('ID Verification'), findsOneWidget);
    expect(find.byKey(const Key('recommendedIdentitySection')), findsOneWidget);
    expect(find.byKey(const Key('otherIdentitySection')), findsOneWidget);
    expect(find.bySemanticsLabel('Recommended ID Type'), findsOneWidget);
    expect(find.bySemanticsLabel('Other Options'), findsOneWidget);
    expect(find.text('PRC ID'), findsOneWidget);
    expect(find.text("DRIVER'S LICENSE"), findsOneWidget);

    final recommendedTop = tester.getTopLeft(
      find.byKey(const Key('recommendedIdentitySection')),
    );
    final otherTop = tester.getTopLeft(
      find.byKey(const Key('otherIdentitySection')),
    );
    expect(otherTop.dy, greaterThan(recommendedTop.dy));

    await tester.tap(find.text('PRC ID'));
    await tester.pump();
    expect(logs, ['identity selected: productId=product-42, type=PRC ID']);
    expect(navigated, [('product-42', 'PRC ID')]);
  });

  testWidgets('renders a stable empty state', (tester) async {
    Get.put(
      IdentitySelectionController(
        apiClient: _FakeApiClient(),
        productId: 'product-42',
      ),
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: IdentitySelectionPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No ID types available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig());

  Map<String, dynamic> states = <String, dynamic>{};

  @override
  Future<ApiResponse> basicPersonInfo({required String productId}) async {
    return ApiResponse(code: 0, message: '', states: Json(states));
  }
}

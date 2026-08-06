import 'package:dali_cash/features/main_shell/home_popup.dart';
import 'package:dali_cash/features/main_shell/home_popup_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('upgrade popup displays server version and content', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = HomePopup.show(
      const HomePopupData(
        type: HomePopupType.appUpgrade,
        version: '1.1.4',
        message: 'Install the latest version.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('V1.1.4'), findsOneWidget);
    expect(find.text('Install the latest version.'), findsOneWidget);
    expect(find.byKey(HomePopup.upgradeButtonKey), findsOneWidget);

    Get.back<void>();
    await tester.pumpAndSettle();
    expect(await shown, isTrue);
  });
}

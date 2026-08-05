import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/certification/widgets/certification_retention_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('renders at the 343 by 332 design ratio', (tester) async {
    await _pumpPopup(tester, onExit: () {});
    final size = tester.getSize(
      find.byKey(CertificationRetentionPopup.cardKey),
    );
    expect(size.width, 343);
    expect(size.height, closeTo(332, 0.01));
  });

  testWidgets('matches the Lanhu vertical button layout and styles', (
    tester,
  ) async {
    await _pumpPopup(tester, onExit: () {});

    final cardRect = tester.getRect(
      find.byKey(CertificationRetentionPopup.cardKey),
    );
    final continueFinder = find.byKey(
      CertificationRetentionPopup.continueButtonKey,
    );
    final exitFinder = find.byKey(CertificationRetentionPopup.exitButtonKey);
    final continueRect = tester.getRect(continueFinder);
    final exitRect = tester.getRect(exitFinder);

    expect(continueRect.left - cardRect.left, 12);
    expect(continueRect.top - cardRect.top, 237);
    expect(continueRect.size, const Size(319, 40));
    expect(exitRect.top - cardRect.top, 293);
    expect(exitRect.height, 18);
    expect(exitRect.center.dx, cardRect.center.dx);

    final continueContainer = tester.widget<Container>(
      find.descendant(of: continueFinder, matching: find.byType(Container)),
    );
    final decoration = continueContainer.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors, const [
      AppColors.retentionGradientStart,
      AppColors.retentionGradientMiddle,
      AppColors.retentionGradientEnd,
    ]);
    expect(gradient.stops, const [0, 0.47929414, 1]);
    expect(decoration.borderRadius, BorderRadius.circular(20));

    final continueText = tester.widget<Text>(find.text('Continue'));
    expect(continueText.style?.color, AppColors.surface);
    expect(continueText.style?.fontSize, 15);
    expect(continueText.style?.fontWeight, FontWeight.w700);
    expect(continueText.style?.height, 18 / 15);

    final exitText = tester.widget<Text>(find.text('Exit'));
    expect(exitText.style?.color, AppColors.retentionSecondary);
    expect(exitText.style?.fontSize, 15);
    expect(exitText.style?.fontWeight, FontWeight.w700);
    expect(exitText.style?.height, 18 / 15);
  });

  testWidgets('Continue closes without invoking Exit', (tester) async {
    var exitCount = 0;
    await _pumpPopup(tester, onExit: () => exitCount++);
    await tester.tap(find.byKey(CertificationRetentionPopup.continueButtonKey));
    await tester.pumpAndSettle();
    expect(exitCount, 0);
  });

  testWidgets('Exit invokes its callback once', (tester) async {
    var exitCount = 0;
    await _pumpPopup(tester, onExit: () => exitCount++);
    await tester.tap(find.byKey(CertificationRetentionPopup.exitButtonKey));
    await tester.pumpAndSettle();
    expect(exitCount, 1);
  });
}

Future<void> _pumpPopup(
  WidgetTester tester, {
  required VoidCallback onExit,
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      home: Scaffold(
        body: CertificationRetentionPopup(
          imageUrl: 'https://example.test/retention.png',
          continueText: 'Continue',
          exitText: 'Exit',
          onExit: onExit,
          imageProvider: const AssetImage(
            'assets/certification/identity_back.png',
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

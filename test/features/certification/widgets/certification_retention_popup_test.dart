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

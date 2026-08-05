import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/features/recredit/recredit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('matches the 375x812 waiting-credit layout', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GetMaterialApp(home: RecreditPage()));
    await tester.pump();

    final illustration = find.byKey(const Key('recredit-illustration'));
    expect(illustration, findsOneWidget);
    expect(tester.getSize(illustration), const Size(120, 102));
    expect(tester.getTopLeft(illustration).dy, closeTo(290, 1));
    expect(
      find.text(
        'Calculating your credit limit, just 30 seconds',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text('Please wait patiently'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    final track = find.byKey(const Key('recredit-progress-bar'));
    expect(tester.getSize(track), const Size(287, 12));

    final image = tester.widget<Image>(illustration);
    expect(
      (image.image as AssetImage).assetName,
      AppAssets.recreditIllustration,
    );
  });

  testWidgets('progress advances and caps at 99%', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        home: RecreditPage(
          progressDelayGenerator: () => const Duration(seconds: 1),
          progressIncrementGenerator: (_) => 50,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('50%'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('99%'), findsOneWidget);
  });
}

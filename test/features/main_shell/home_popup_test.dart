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

  testWidgets('upgrade button opens the server URL externally', (tester) async {
    Uri? openedUri;
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = HomePopup.show(
      const HomePopupData(
        type: HomePopupType.appUpgrade,
        targetUrl: ' https://store.example.test/app ',
      ),
      externalOpener: (uri) async {
        openedUri = uri;
        return true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomePopup.upgradeButtonKey));
    await tester.pumpAndSettle();

    expect(await shown, isTrue);
    expect(openedUri, Uri.parse('https://store.example.test/app'));
  });

  testWidgets('upgrade URL falls back in app when external opening fails', (
    tester,
  ) async {
    String? openedInApp;
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = HomePopup.show(
      const HomePopupData(
        type: HomePopupType.appUpgrade,
        targetUrl: 'https://store.example.test/app',
      ),
      externalOpener: (_) async => false,
      inAppOpener: (url) => openedInApp = url,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomePopup.upgradeButtonKey));
    await tester.pumpAndSettle();

    expect(await shown, isTrue);
    expect(openedInApp, 'https://store.example.test/app');
  });

  testWidgets('marketing popup follows screen width and closes below image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final shown = HomePopup.show(
      const HomePopupData(
        type: HomePopupType.marketing,
        imageUrl: 'https://cdn.example.test/popup.png',
      ),
    );
    await tester.pumpAndSettle();

    final contentRect = tester.getRect(
      find.byKey(HomePopup.marketingContentKey),
    );
    final gapRect = tester.getRect(find.byKey(HomePopup.marketingCloseGapKey));
    final closeRect = tester.getRect(find.byKey(HomePopup.marketingCloseKey));
    expect(contentRect.width, 343);
    expect(gapRect.height, 16);
    expect(closeRect.top, gapRect.bottom);
    expect(closeRect.size, const Size(32, 32));

    Get.back<void>();
    await tester.pumpAndSettle();
    expect(await shown, isTrue);
  });
}

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:dali_cash/features/home/widgets/promo_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    ScreenAdapter.initForSize(const Size(375, 812));
  });

  tearDown(ScreenAdapter.resetForTest);

  testWidgets('null banners render the local fallback without a PageView', (
    tester,
  ) async {
    await _pumpBanner(tester);

    expect(find.byKey(const Key('home-promo-banner-asset')), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('one banner stays static and reports the tapped item', (
    tester,
  ) async {
    HomeBannerData? tapped;
    const banner = HomeBannerData(
      id: 'banner-1',
      imageUrl: 'https://example.test/banner-1.png',
      targetUrl: 'https://example.test/target-1',
    );

    await _pumpBanner(
      tester,
      banners: const [banner],
      onTap: (value) => tapped = value,
    );

    expect(find.byKey(const Key('home-promo-banner-network')), findsOneWidget);
    expect(find.byType(PageView), findsNothing);

    await tester.tap(find.byKey(const Key('home-promo-banner-banner-1')));

    expect(tapped, same(banner));
  });

  testWidgets('multiple banners advance every three seconds and map taps', (
    tester,
  ) async {
    HomeBannerData? tapped;
    final banners = _banners(3);
    await _pumpBanner(
      tester,
      banners: banners,
      onTap: (value) => tapped = value,
    );

    final pageView = tester.widget<PageView>(find.byType(PageView));
    final controller = pageView.controller!;
    final initialPage = controller.page!.round();
    expect(initialPage % banners.length, 0);

    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    await tester.pump();
    expect(tapped, same(banners[0]));
    tapped = null;

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(controller.page!.round(), initialPage + 1);
    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    await tester.pump();
    expect(tapped, same(banners[1]));

    controller.jumpToPage(initialPage + 5);
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    await tester.pump();
    expect(tapped, same(banners[2]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing list length resets carousel and disposal cancels it', (
    tester,
  ) async {
    await _pumpBanner(tester, banners: _banners(3));
    final firstController = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;

    await _pumpBanner(tester, banners: _banners(2));
    final secondController = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;

    expect(secondController, isNot(same(firstController)));
    expect(secondController.page!.round() % 2, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpBanner(
  WidgetTester tester, {
  List<HomeBannerData>? banners,
  ValueChanged<HomeBannerData>? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: PromoBanner(banners: banners, onTap: onTap ?? (_) {}),
        ),
      ),
    ),
  );
}

List<HomeBannerData> _banners(int count) {
  return List.generate(
    count,
    (index) => HomeBannerData(
      id: 'banner-$index',
      imageUrl: 'https://example.test/banner-$index.png',
      targetUrl: 'https://example.test/target-$index',
    ),
  );
}

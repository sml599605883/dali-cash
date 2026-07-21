import 'dart:typed_data';

import 'package:dali_cash/app/app.dart';
import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_endpoints.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:dali_cash/features/home/widgets/home_header.dart';
import 'package:dali_cash/features/home/widgets/loan_offer_card.dart';
import 'package:dali_cash/features/home/widgets/promo_banner.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:dali_cash/features/main_shell/main_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../support/test_main_binding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('renders delivered home modules and values', (tester) async {
    final controller = _registerController();
    controller.homeData.value = _deliveredHomeData();

    await _pumpShell(tester);

    expect(find.text('Server Finance'), findsNWidgets(2));
    expect(find.text('88,888.00'), findsNWidgets(2));
    expect(find.text('Server amount caption'), findsNWidgets(2));
    expect(find.text('365 Days'), findsOneWidget);
    expect(find.text('1.25% Day'), findsNWidgets(2));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.byType(LoanOfferCard), findsOneWidget);
    expect(find.byType(PromoBanner), findsOneWidget);
    expect(
      tester.widget<PromoBanner>(find.byType(PromoBanner)).banners,
      hasLength(2),
    );
    expect(
      find.descendant(
        of: find.byType(LoanOfferCard),
        matching: find.text('Server loan progress headline'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-promo-banner-network')), findsOneWidget);
    expect(
      find.byKey(const Key('home-recommendation-card--1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides empty delivered sections but keeps static null fallback', (
    tester,
  ) async {
    final controller = _registerController();

    await _pumpShell(tester);
    expect(find.byKey(const Key('home-loan-offer-card')), findsOneWidget);
    expect(find.text('Confirm your loan， Cash hits fast.'), findsOneWidget);
    expect(find.byKey(const Key('home-promo-banner-asset')), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);

    controller.homeData.value = HomeData(
      loanOffer: null,
      banners: const <HomeBannerData>[],
      recommendations: const <HomeRecommendationData>[],
    );
    await tester.pump();

    expect(find.byKey(const Key('home-loan-offer-card')), findsNothing);
    expect(find.byKey(const Key('home-promo-banner-asset')), findsNothing);
    expect(find.byKey(const Key('home-promo-banner-network')), findsNothing);
    expect(find.text('Recommendation'), findsNothing);
  });

  testWidgets(
    'controller selectedIndex drives shell without same-tab refresh',
    (tester) async {
      final controller = _registerController();
      await _pumpShell(tester);

      await tester.tap(find.byKey(const Key('tab-progress')));
      await tester.pump();
      expect(controller.selectedIndex.value, 1);
      expect(find.byKey(const Key('tab-progress-selected')), findsOneWidget);

      controller.selectedIndex.value = 2;
      await tester.pump();
      expect(find.byKey(const Key('tab-mine-selected')), findsOneWidget);
    },
  );

  testWidgets('root app installs GetMaterialApp runtime', (tester) async {
    await tester.pumpWidget(DaliCashApp(initialBinding: testMainBinding()));

    expect(find.byType(GetMaterialApp), findsOneWidget);
  });

  testWidgets(
    'lifecycle, tabs, and pull refresh request home then popup once',
    (tester) async {
      final adapter = _HomeDialogAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final client = ApiClient(
        ApiConfig(
          apiBaseUrl: 'https://example.test',
          commonParamsProvider: () async => const <String, dynamic>{},
          timestampProvider: () => 1,
          randomDigitsProvider: (length) => '1' * length,
        ),
        dio: dio,
      );
      await tester.pumpWidget(
        DaliCashApp(
          initialBinding: MainBinding(
            apiClient: client,
            showError: (_) {},
            showNotice: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(adapter.events, <String>['home', 'dialog']);

      await tester.tap(find.byKey(const Key('tab-home')));
      await tester.pumpAndSettle();
      expect(adapter.events, <String>['home', 'dialog']);

      await tester.tap(find.byKey(const Key('tab-progress')));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(adapter.events, <String>['home', 'dialog']);

      await tester.tap(find.byKey(const Key('tab-home')));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(adapter.events, <String>[
        'home',
        'dialog',
        'home',
        'dialog',
        'home',
        'dialog',
      ]);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      expect(adapter.events, <String>[
        'home',
        'dialog',
        'home',
        'dialog',
        'home',
        'dialog',
        'home',
        'dialog',
      ]);
    },
  );

  testWidgets('malformed remote images fall back without crashing', (
    tester,
  ) async {
    final controller = _registerController();
    final delivered = _deliveredHomeData();
    controller.homeData.value = HomeData(
      loanOffer: HomeLoanOfferData(
        productId: delivered.loanOffer!.productId,
        productName: delivered.loanOffer!.productName,
        productLogo: 'not a valid URL',
        amount: delivered.loanOffer!.amount,
        amountCaption: delivered.loanOffer!.amountCaption,
        loanTerm: delivered.loanOffer!.loanTerm,
        loanTermCaption: delivered.loanOffer!.loanTermCaption,
        interestRate: delivered.loanOffer!.interestRate,
        interestRateCaption: delivered.loanOffer!.interestRateCaption,
        buttonText: delivered.loanOffer!.buttonText,
        loanProcessText: delivered.loanOffer!.loanProcessText,
      ),
      banners: const <HomeBannerData>[
        HomeBannerData(
          id: 'bad-banner',
          imageUrl: 'not a valid URL',
          targetUrl: '',
        ),
      ],
      recommendations: const <HomeRecommendationData>[
        HomeRecommendationData(
          productId: 'bad-logo',
          productName: 'Broken Logo Finance',
          productLogo: 'not a valid URL',
          amount: '1000',
          amountCaption: 'Available up to',
          interestRate: '1%',
          loanTerm: '7 Days',
          footer: '',
          upscales: 0,
        ),
      ],
    );

    await _pumpShell(tester);
    await tester.pumpAndSettle();

    expect(find.text('Cash'), findsWidgets);
    expect(find.byKey(const Key('home-promo-banner-network')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long delivered recommendation text does not overflow', (
    tester,
  ) async {
    final controller = _registerController();
    controller.homeData.value = HomeData(
      loanOffer: null,
      banners: const <HomeBannerData>[],
      recommendations: const <HomeRecommendationData>[
        HomeRecommendationData(
          productId: 'long-copy',
          productName:
              'An exceptionally long server supplied financial product name',
          productLogo: '',
          amount: '999999999999.99',
          amountCaption: 'An unusually long available amount caption',
          interestRate: '123456789% every single business day',
          loanTerm: '123456789 calendar days',
          footer:
              'A very long server supplied qualification statement that must stay in its card',
          upscales: 0,
        ),
      ],
    );

    await _pumpShell(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long loan values scale down without losing amount digits', (
    tester,
  ) async {
    final controller = _registerController();
    const productName = 'A very long financial product name from the server';
    const amount = '999999999999999999999999.99';
    const caption = 'A very long server supplied available amount caption';
    const button = 'Continue with this exceptionally long application label';
    const headline =
        'Complete authentication to unlock the highest available loan amount';
    controller.homeData.value = HomeData(
      loanOffer: const HomeLoanOfferData(
        productId: 'long-loan',
        productName: productName,
        productLogo: '',
        amount: amount,
        amountCaption: caption,
        loanTerm: '365 days',
        loanTermCaption: 'Loan term',
        interestRate: '1%',
        interestRateCaption: 'Interest rate',
        buttonText: button,
        loanProcessText: headline,
      ),
      banners: const <HomeBannerData>[],
      recommendations: const <HomeRecommendationData>[],
    );

    await _pumpShell(tester, size: const Size(320, 568));

    final formattedAmount = formatHomeAmount(amount);
    expect(find.text(formattedAmount), findsOneWidget);
    for (final value in <String>[
      productName,
      formattedAmount,
      caption,
      button,
      headline,
    ]) {
      final text = find.text(value);
      expect(
        find.ancestor(of: text, matching: find.byType(FittedBox)),
        findsOneWidget,
        reason: value,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('upscales branches use highlight disabled and normal visuals', (
    tester,
  ) async {
    final controller = _registerController();
    controller.homeData.value = HomeData(
      loanOffer: null,
      banners: const <HomeBannerData>[],
      recommendations: <HomeRecommendationData>[
        _recommendation(upscales: 1),
        _recommendation(upscales: 0),
        _recommendation(upscales: -1),
      ],
    );

    await _pumpShell(tester);

    final highlighted = _applyDecoration(tester, 1);
    expect(
      (highlighted.image!.image as AssetImage).assetName,
      AppAssets.recommendationApplyHighlight,
    );
    expect(highlighted.gradient, isNull);

    final disabled = _applyDecoration(tester, -1);
    expect(
      (disabled.image!.image as AssetImage).assetName,
      AppAssets.recommendationApplyDisabled,
    );
    expect(disabled.gradient, isNull);

    final normal = _applyDecoration(tester, 0);
    expect(normal.image, isNull);
    expect(normal.gradient, isA<LinearGradient>());
    expect((normal.gradient! as LinearGradient).colors, <Color>[
      AppColors.recommendationNormalStart,
      AppColors.recommendationNormalEnd,
    ]);
  });

  test(
    'test client returns deterministic responses without transport',
    () async {
      final client = _NoNetworkApiClient();

      final home = await client.homePage().timeout(const Duration(seconds: 1));
      final dialog = await client
          .dialog(scene: 1)
          .timeout(const Duration(seconds: 1));

      expect(home, isA<ApiResponse>());
      expect(home.states['clingiest'].listValue, isEmpty);
      expect(dialog.states['sociologeses'].intValue, 0);
      expect(client.homeCalls, 1);
      expect(client.dialogCalls, 1);
    },
  );
}

BoxDecoration _applyDecoration(WidgetTester tester, int upscales) {
  final box = tester.widget<DecoratedBox>(
    find.byKey(Key('home-recommendation-apply-background-$upscales')),
  );
  return box.decoration as BoxDecoration;
}

HomeRecommendationData _recommendation({required int upscales}) {
  return HomeRecommendationData(
    productId: 'product-$upscales',
    productName: 'Finance $upscales',
    productLogo: '',
    amount: '1000',
    amountCaption: 'Available up to',
    interestRate: '1%',
    loanTerm: '7 days',
    footer: '',
    upscales: upscales,
  );
}

MainController _registerController() {
  final controller = _ViewMainController(
    apiClient: _NoNetworkApiClient(),
    showError: (_) {},
    showNotice: (_) {},
  );
  Get.put<MainController>(controller);
  return controller;
}

Future<void> _pumpShell(
  WidgetTester tester, {
  Size size = const Size(375, 1098),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          ScreenAdapter.init(context);
          return const MainShellPage();
        },
      ),
    ),
  );
}

HomeData _deliveredHomeData() {
  return HomeData(
    loanOffer: const HomeLoanOfferData(
      productId: 'server-loan',
      productName: 'Server Finance',
      productLogo: '',
      amount: '88888.00',
      amountCaption: 'Server amount caption',
      loanTerm: '365 Days',
      loanTermCaption: 'Loan period',
      interestRate: '1.25% Day',
      interestRateCaption: 'Daily rate',
      buttonText: 'Continue',
      loanProcessText: 'Server loan progress headline',
    ),
    banners: const <HomeBannerData>[
      HomeBannerData(
        id: 'banner-1',
        imageUrl: 'https://example.invalid/banner.png',
        targetUrl: '',
      ),
      HomeBannerData(
        id: 'banner-2',
        imageUrl: 'https://example.invalid/banner-2.png',
        targetUrl: 'https://example.invalid/target-2',
      ),
    ],
    recommendations: const <HomeRecommendationData>[
      HomeRecommendationData(
        productId: 'server-recommendation',
        productName: 'Server Finance',
        productLogo: '',
        amount: '88888.00',
        amountCaption: 'Server amount caption',
        interestRate: '1.25% Day',
        loanTerm: '30 Days',
        footer: 'Server footer',
        upscales: -1,
      ),
    ],
  );
}

class _NoNetworkApiClient extends ApiClient {
  _NoNetworkApiClient() : super(ApiConfig());

  int homeCalls = 0;
  int dialogCalls = 0;

  @override
  Future<ApiResponse> homePage() async {
    homeCalls += 1;
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(<String, dynamic>{'clingiest': <dynamic>[]}),
    );
  }

  @override
  Future<ApiResponse> dialog({required int scene}) async {
    dialogCalls += 1;
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(<String, dynamic>{'sociologeses': 0}),
    );
  }
}

class _ViewMainController extends MainController {
  _ViewMainController({
    required super.apiClient,
    required super.showError,
    required super.showNotice,
  });

  @override
  void onReady() {
    // View tests assign homeData directly; lifecycle dispatch is tested separately.
  }
}

class _HomeDialogAdapter implements HttpClientAdapter {
  final List<String> events = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isHome = options.path.endsWith(ApiEndpoints.homePage);
    events.add(isHome ? 'home' : 'dialog');
    final states = isHome ? '{"clingiest":[]}' : '{"sociologeses":0}';
    return ResponseBody.fromString(
      '{"felicitous":0,"cuckoo":"success","unsphered":$states}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

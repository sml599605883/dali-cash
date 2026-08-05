import 'dart:typed_data';

import 'package:dali_cash/app/app.dart';
import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/routes/app_routes.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_endpoints.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:dali_cash/features/home/widgets/home_header.dart';
import 'package:dali_cash/features/home/widgets/loan_offer_card.dart';
import 'package:dali_cash/features/home/widgets/promo_banner.dart';
import 'package:dali_cash/features/login/login_page.dart';
import 'package:dali_cash/features/main_shell/main_binding.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:dali_cash/features/main_shell/main_shell_page.dart';
import 'package:dali_cash/features/progress/progress_item.dart';
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

  testWidgets('renders server progress data from the shared home response', (
    tester,
  ) async {
    final controller = _registerController();
    controller.homeData.value = _deliveredHomeData();
    controller.selectedIndex.value = 1;

    await _pumpShell(tester);

    expect(find.byKey(const Key('progress-card')), findsOneWidget);
    expect(find.text('Server Cash'), findsOneWidget);
    expect(find.text('PHP 2,000.00'), findsOneWidget);
    expect(find.text('Application date'), findsOneWidget);
    expect(find.text('Disbursement Failed'), findsOneWidget);
    expect(find.text('Retry Original Account'), findsOneWidget);
  });

  testWidgets('shows Progress loading and retryable first-load error states', (
    tester,
  ) async {
    final controller = _registerController();
    controller.selectedIndex.value = 1;
    controller.isProgressRefreshing.value = true;

    await _pumpShell(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.isProgressRefreshing.value = false;
    controller.progressError.value = 'Progress unavailable';
    await tester.pump();

    expect(find.text('Progress unavailable'), findsOneWidget);
    expect(find.byKey(const Key('progress-load-retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('progress-load-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Progress unavailable'), findsNothing);
    expect(find.text('No progress yet'), findsOneWidget);
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

  testWidgets('logged-out protected tab returns to Home after login', (
    tester,
  ) async {
    final sessionStore = SessionStore.memory();
    var loginCalls = 0;
    final controller = _registerController(
      sessionStore: sessionStore,
      navigateToLogin: () => loginCalls++,
    );
    await _pumpShell(tester);

    await tester.tap(find.byKey(const Key('tab-progress')));
    await tester.pump();

    expect(loginCalls, 1);
    expect(controller.selectedIndex.value, 0);
    expect(find.byKey(const Key('tab-home-selected')), findsOneWidget);

    await sessionStore.saveSessionId('session-id');
    await tester.pump();
    expect(controller.selectedIndex.value, 0);

    await tester.tap(find.byKey(const Key('tab-progress')));
    await tester.pump();
    expect(controller.selectedIndex.value, 1);
  });

  testWidgets('logged-out hero apply returns Home without auto-resuming', (
    tester,
  ) async {
    final sessionStore = SessionStore.memory();
    var loginCalls = 0;
    final appliedProductIds = <String>[];
    final controller = _registerController(
      sessionStore: sessionStore,
      navigateToLogin: () => loginCalls++,
      onAuthenticatedProductApply: (productId) async {
        appliedProductIds.add(productId);
      },
    );
    controller.homeData.value = _deliveredHomeData();
    await _pumpShell(tester);

    await tester.tap(find.byKey(const Key('home-apply-now')));
    await tester.pump();

    expect(loginCalls, 1);
    expect(controller.selectedIndex.value, 0);
    expect(appliedProductIds, isEmpty);

    await sessionStore.saveSessionId('session-id');
    await tester.pump();
    expect(appliedProductIds, isEmpty);

    await tester.tap(find.byKey(const Key('home-apply-now')));
    await tester.pump();
    expect(appliedProductIds, ['server-loan']);
  });

  testWidgets('logged-out recommendation apply uses the same login gate', (
    tester,
  ) async {
    final sessionStore = SessionStore.memory();
    var loginCalls = 0;
    final appliedProductIds = <String>[];
    final controller = _registerController(
      sessionStore: sessionStore,
      navigateToLogin: () => loginCalls++,
      onAuthenticatedProductApply: (productId) async {
        appliedProductIds.add(productId);
      },
    );
    controller.homeData.value = HomeData(
      loanOffer: null,
      banners: const <HomeBannerData>[],
      recommendations: [_recommendation(upscales: 1)],
    );
    await _pumpShell(tester);

    await tester.tap(find.byKey(const Key('home-recommendation-card-1')));
    await tester.pump();

    expect(loginCalls, 1);
    expect(controller.selectedIndex.value, 0);
    expect(appliedProductIds, isEmpty);

    await sessionStore.saveSessionId('session-id');
    await tester.pump();
    expect(appliedProductIds, isEmpty);

    await tester.tap(find.byKey(const Key('home-recommendation-card-1')));
    await tester.pump();
    expect(appliedProductIds, ['product-1']);
  });

  testWidgets('root app installs GetMaterialApp runtime', (tester) async {
    await tester.pumpWidget(DaliCashApp(initialBinding: testMainBinding()));

    expect(find.byType(GetMaterialApp), findsOneWidget);
  });

  testWidgets('real login route is not duplicated and closes back to Home', (
    tester,
  ) async {
    final apiClient = _NoNetworkApiClient();
    apiClient.config.sessionStore = SessionStore.memory();
    await tester.pumpWidget(
      DaliCashApp(
        initialBinding: MainBinding(
          apiClient: apiClient,
          showError: (_) {},
          showNotice: (_) {},
        ),
      ),
    );
    await tester.pump();

    final controller = Get.find<MainController>();
    await controller.selectTab(2);
    await tester.pumpAndSettle();
    await controller.selectTab(2);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(controller.selectedIndex.value, 0);

    Get.back<void>();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsNothing);
    expect(find.byKey(const Key('tab-home-selected')), findsOneWidget);
    expect(controller.selectedIndex.value, 0);
  });

  testWidgets('Home and Progress use their documented refresh request chains', (
    tester,
  ) async {
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
    client.config.sessionStore = _LoggedInSessionStore();
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
    expect(adapter.events, <String>['home', 'dialog', 'home']);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(adapter.events, <String>['home', 'dialog', 'home', 'home']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(adapter.events, <String>['home', 'dialog', 'home', 'home']);

    await tester.tap(find.byKey(const Key('tab-home')));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(adapter.events, <String>[
      'home',
      'dialog',
      'home',
      'home',
      'home',
      'dialog',
    ]);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(adapter.events, <String>[
      'home',
      'dialog',
      'home',
      'home',
      'home',
      'dialog',
      'home',
      'dialog',
    ]);
  });

  testWidgets('covered Home stays idle and refreshes after route return', (
    tester,
  ) async {
    final adapter = _HomeDialogAdapter();
    final client = ApiClient(
      ApiConfig(
        apiBaseUrl: 'https://example.test',
        commonParamsProvider: () async => const <String, dynamic>{},
        timestampProvider: () => 1,
        randomDigitsProvider: (length) => '1' * length,
      ),
      dio: Dio()..httpClientAdapter = adapter,
    );
    client.config.sessionStore = _LoggedInSessionStore();
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

    final popup = Get.dialog<void>(
      const AlertDialog(content: Text('Permission prompt')),
      transitionDuration: Duration.zero,
    );
    await tester.pumpAndSettle();
    Get.back<void>();
    await tester.pumpAndSettle();
    await popup;
    expect(adapter.events, <String>['home', 'dialog']);

    Get.toNamed<void>(AppRoutes.login);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(adapter.events, <String>['home', 'dialog']);

    Get.back<void>();
    await tester.pumpAndSettle();
    expect(adapter.events, <String>['home', 'dialog', 'home', 'dialog']);
  });

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
    expect(
      (normal.image!.image as AssetImage).assetName,
      AppAssets.recommendationApplyHighlight,
    );
    expect(normal.gradient, isNull);
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

MainController _registerController({
  SessionStore? sessionStore,
  LoginRouteNavigator? navigateToLogin,
  AuthenticatedProductApply? onAuthenticatedProductApply,
}) {
  final apiClient = _NoNetworkApiClient();
  apiClient.config.sessionStore = sessionStore ?? _LoggedInSessionStore();
  final controller = _ViewMainController(
    apiClient: apiClient,
    showError: (_) {},
    showNotice: (_) {},
    navigateToLogin: navigateToLogin,
    onAuthenticatedProductApply: onAuthenticatedProductApply,
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
    progressItems: const <ProgressItem>[
      ProgressItem(
        orderNumber: 'order-1',
        productId: '9',
        productName: 'Server Cash',
        amount: 'PHP 2,000.00',
        amountLabel: 'Loan Amount',
        date: '28-12-2022',
        dateLabel: 'Application date',
        emblemize: ProgressEmblemize.disbursementFailed,
        statusLabel: 'Disbursement Failed',
        actions: <ProgressAction>[
          ProgressAction(
            type: 'retry',
            visible: true,
            label: 'Retry Original Account',
            badge: '',
            route: '',
          ),
        ],
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
    super.navigateToLogin,
    super.onAuthenticatedProductApply,
  });

  @override
  void onReady() {
    // View tests assign homeData directly; lifecycle dispatch is tested separately.
  }
}

class _LoggedInSessionStore extends SessionStore {
  _LoggedInSessionStore() : super.memory();

  @override
  Future<String> sessionId() async => 'session-id';
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

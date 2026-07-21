import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/routes/app_routes.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/login/login_controller.dart';
import 'package:dali_cash/features/login/login_binding.dart';
import 'package:dali_cash/features/login/login_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    ScreenAdapter.resetForTest();
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    Size size = const Size(375, 812),
    VoidCallback? onPrivacyPolicyTap,
    bool useIphoneSafeArea = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (useIphoneSafeArea) {
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPadding);
    }

    final apiClient = _FakeLoginApiClient();
    Get.put<LoginController>(
      LoginController(
        apiClient: apiClient,
        sessionStore: SessionStore.memory(),
        showLoading: () async {},
        dismissLoading: () async {},
        showMessage: (_) async {},
        onLoginSuccess: () async {},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ScreenAdapter.init(context);
            return LoginPage(onPrivacyPolicyTap: onPrivacyPolicyTap);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the Lanhu login page at design size', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Dali Cash'), findsOneWidget);
    expect(find.text('Please enter mobile number'), findsOneWidget);
    expect(find.text('Verify with SMS Code'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
    expect(find.byKey(const Key('login-phone-field')), findsOneWidget);
    expect(find.byKey(const Key('login-code-field')), findsOneWidget);
    expect(find.byKey(const Key('login-agreement-checked')), findsOneWidget);
    expect(
      find.text('I have read and agree to the Privacy Policy'),
      findsOneWidget,
    );

    expect(
      tester.getSize(find.byKey(const Key('login-banner'))),
      const Size(343, 126),
    );
    expect(
      tester.getSize(find.byKey(const Key('login-panel'))),
      const Size(343, 264),
    );
  });

  testWidgets('matches the approved 375x812 login layout', (tester) async {
    await pumpLogin(tester, useIphoneSafeArea: true);
    await tester.runAsync(() async {
      final context = tester.element(find.byType(LoginPage));
      await precacheImage(const AssetImage(AppAssets.loginBackground), context);
      await precacheImage(const AssetImage(AppAssets.loginBanner), context);
    });
    await tester.pump();

    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/login_page.png'),
    );
  });

  testWidgets('agreement and privacy policy have separate actions', (
    tester,
  ) async {
    var policyTaps = 0;
    await pumpLogin(tester, onPrivacyPolicyTap: () => policyTaps++);

    await tester.tap(find.byKey(const Key('login-agreement-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('login-agreement-unchecked')), findsOneWidget);
    expect(policyTaps, 0);

    final agreement = tester.widget<Text>(
      find.text('I have read and agree to the Privacy Policy'),
    );
    final rootSpan = agreement.textSpan! as TextSpan;
    final policySpan = rootSpan.children!.last as TextSpan;
    (policySpan.recognizer! as TapGestureRecognizer).onTap!();
    expect(policyTaps, 1);
  });

  testWidgets('does not overflow on a compact screen', (tester) async {
    await pumpLogin(tester, size: const Size(320, 568));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('opens from the registered login route', (tester) async {
    final apiClient = _FakeLoginApiClient();
    apiClient.config.sessionStore = SessionStore.memory();
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: BindingsBuilder(() => Get.put<ApiClient>(apiClient)),
        home: const Scaffold(body: Text('Home')),
        getPages: [
          GetPage(
            name: AppRoutes.login,
            page: () => const LoginPage(),
            binding: LoginBinding(),
          ),
        ],
      ),
    );

    Get.toNamed<void>(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Dali Cash'), findsOneWidget);
  });
}

class _FakeLoginApiClient extends ApiClient {
  _FakeLoginApiClient() : super(ApiConfig(), dio: Dio());

  @override
  Future<ApiResponse> sendSmsCode({required String phone}) async {
    return ApiResponse(code: 0, message: 'sent', states: Json(null));
  }

  @override
  Future<ApiResponse> smsCodeLogin({
    required String phone,
    required String code,
  }) async {
    return ApiResponse(
      code: 0,
      message: 'success',
      states: Json(const {'crestfallen': 'session'}),
    );
  }
}

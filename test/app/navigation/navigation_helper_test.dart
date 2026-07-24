import 'package:dali_cash/app/navigation/navigation_helper.dart';
import 'package:dali_cash/app/routes/app_routes.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/permissions/permission_coordinator.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late _FakeApiClient apiClient;
  late List<String> feedbackEvents;
  late List<String> navigationLogs;
  late List<int> navigatedTabs;
  late List<String> permissionPrompts;
  late int settingsOpenCount;

  setUp(() async {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    apiClient.config.sessionStore = SessionStore.memory();
    feedbackEvents = <String>[];
    navigationLogs = <String>[];
    navigatedTabs = <int>[];
    permissionPrompts = <String>[];
    settingsOpenCount = 0;
    Get.put<ApiClient>(apiClient);
    NavigationHelper.loadingPresenter = () async {
      feedbackEvents.add('loading');
    };
    NavigationHelper.loadingDismissor = () async {
      feedbackEvents.add('dismiss');
    };
    NavigationHelper.errorPresenter = (message) async {
      feedbackEvents.add('error:$message');
    };
    NavigationHelper.noticePresenter = (message) async {
      feedbackEvents.add('notice:$message');
    };
    NavigationHelper.logger = navigationLogs.add;
    NavigationHelper.mainTabNavigator = (index) async {
      navigatedTabs.add(index);
    };
    NavigationHelper.certificationLocationRequester = () async {
      return CertificationLocationDecision.granted;
    };
    NavigationHelper.permissionPromptPresenter =
        ({
          required title,
          required content,
          required cancelText,
          required confirmText,
        }) async {
          permissionPrompts.add('$title|$content|$cancelText|$confirmText');
          return false;
        };
    NavigationHelper.appSettingsOpener = () async {
      settingsOpenCount++;
      return true;
    };
  });

  tearDown(() {
    NavigationHelper.loadingPresenter =
        NavigationHelper.defaultLoadingPresenter;
    NavigationHelper.loadingDismissor =
        NavigationHelper.defaultLoadingDismissor;
    NavigationHelper.errorPresenter = NavigationHelper.defaultErrorPresenter;
    NavigationHelper.noticePresenter = NavigationHelper.defaultNoticePresenter;
    NavigationHelper.logger = NavigationHelper.defaultLogger;
    NavigationHelper.mainTabNavigator =
        NavigationHelper.defaultMainTabNavigator;
    NavigationHelper.certificationLocationRequester =
        NavigationHelper.defaultCertificationLocationRequester;
    NavigationHelper.permissionPromptPresenter =
        NavigationHelper.defaultPermissionPromptPresenter;
    NavigationHelper.appSettingsOpener =
        NavigationHelper.defaultAppSettingsOpener;
    Get.reset();
  });

  test('navigation entrypoints expose side-effect-only contracts', () {
    final Future<void> Function(String, {Object? arguments}) rawTarget =
        NavigationHelper.navigateRawTarget;
    final Future<void> Function(String, {String source}) productApply =
        NavigationHelper.applyProduct;

    expect(rawTarget, isNotNull);
    expect(productApply, isNotNull);
  });

  testWidgets('dispatches the registered login route without duplicates', (
    tester,
  ) async {
    await _pumpRoutes(tester);

    NavigationHelper.toNamed<void>(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(find.byKey(const Key('loginStub')), findsOneWidget);
    expect(NavigationHelper.toLogin<void>(), isNull);
  });

  testWidgets('ignores route names that are not supported yet', (tester) async {
    await _pumpRoutes(tester);

    final result = NavigationHelper.toNamed<void>('/not-implemented');
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byKey(const Key('homeStub')), findsOneWidget);
  });

  testWidgets('routes the documented Dali login scheme', (tester) async {
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://dali-cash/ios/TortoiseBerkelium',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(navigationLogs, isEmpty);
  });

  test('routes the documented setting scheme to the Mine tab', () async {
    await NavigationHelper.navigateRawTarget(
      'ph://dali-cash/ios/VeinedYachting',
    );

    expect(navigatedTabs, [2]);
    expect(navigationLogs, isEmpty);
  });

  test('loads product detail from the documented Conifer scheme', () async {
    await NavigationHelper.navigateRawTarget(
      'ph://dali-cash/ios/Conifer?highlands=2',
    );

    expect(apiClient.detailedProducts, ['2']);
    expect(navigationLogs, isEmpty);
  });

  test('logs documented routes whose features are not available yet', () async {
    await NavigationHelper.navigateRawTarget('ph://dali-cash/ios/Heed');

    expect(navigationLogs.single, contains('Heed'));
    expect(navigationLogs.single, contains('not available'));
  });

  test('logs HTTP targets until the internal WebView exists', () async {
    await NavigationHelper.navigateRawTarget(
      'https://example.test/errorUrl?productId=42',
    );

    expect(navigationLogs.single, contains('WebView deferred'));
  });

  testWidgets('backs out of the current route', (tester) async {
    await _pumpRoutes(tester);
    NavigationHelper.toLogin<void>();
    await tester.pumpAndSettle();

    NavigationHelper.back<void>();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeStub')), findsOneWidget);
  });

  testWidgets('direct identity navigation does not request location again', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    var locationRequests = 0;
    NavigationHelper.certificationLocationRequester = () async {
      locationRequests++;
      return CertificationLocationDecision.denied;
    };

    await NavigationHelper.toIdentitySelection<void>(productId: 'product-42');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.identitySelection);
    expect(locationRequests, 0);
    expect(permissionPrompts, isEmpty);
    expect(settingsOpenCount, 0);
  });

  testWidgets('location denial stops apply before the API request', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await apiClient.config.sessionStore.saveSessionId('session-id');
    NavigationHelper.certificationLocationRequester = () async {
      return CertificationLocationDecision.denied;
    };

    await NavigationHelper.applyProduct('product-42');
    await tester.pumpAndSettle();

    expect(apiClient.appliedProducts, isEmpty);
    expect(feedbackEvents, isEmpty);
    expect(permissionPrompts, isEmpty);
  });

  testWidgets('permanent location denial offers app settings before apply', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await apiClient.config.sessionStore.saveSessionId('session-id');
    NavigationHelper.certificationLocationRequester = () async {
      return CertificationLocationDecision.settingsRequired;
    };
    NavigationHelper.permissionPromptPresenter =
        ({
          required title,
          required content,
          required cancelText,
          required confirmText,
        }) async {
          permissionPrompts.add('$title|$content|$cancelText|$confirmText');
          return true;
        };

    await NavigationHelper.applyProduct('product-42');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/');
    expect(apiClient.appliedProducts, isEmpty);
    expect(permissionPrompts.single, contains('Location Required'));
    expect(settingsOpenCount, 1);
    expect(feedbackEvents, isEmpty);
  });

  testWidgets('disabled location service stops apply and offers settings', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await apiClient.config.sessionStore.saveSessionId('session-id');
    NavigationHelper.certificationLocationRequester = () async {
      return CertificationLocationDecision.serviceDisabled;
    };

    await NavigationHelper.applyProduct('product-42');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/');
    expect(apiClient.appliedProducts, isEmpty);
    expect(permissionPrompts.single, contains('GPS is Off'));
    expect(settingsOpenCount, 0);
  });

  testWidgets('pops nested routes until the Home root remains', (tester) async {
    await _pumpRoutes(tester);
    Get.toNamed<void>('/middle');
    await tester.pumpAndSettle();
    NavigationHelper.toLogin<void>();
    await tester.pumpAndSettle();

    NavigationHelper.backToRoot();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeStub')), findsOneWidget);
    expect(find.byKey(const Key('middleStub')), findsNothing);
    expect(find.byKey(const Key('loginStub')), findsNothing);
  });

  test('empty product id has no side effects', () async {
    await NavigationHelper.applyProduct('   ');

    expect(apiClient.appliedProducts, isEmpty);
    expect(feedbackEvents, isEmpty);
  });

  testWidgets('logged-out product opens Login without requesting', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    var locationRequests = 0;
    NavigationHelper.certificationLocationRequester = () async {
      locationRequests++;
      return CertificationLocationDecision.granted;
    };

    await NavigationHelper.applyProduct(' product-42 ');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(apiClient.appliedProducts, isEmpty);
    expect(locationRequests, 0);
    expect(feedbackEvents, isEmpty);
  });

  testWidgets('apply target is handled before product detail', (tester) async {
    await _pumpRoutes(tester);
    await apiClient.config.sessionStore.saveSessionId('session-id');
    apiClient.applyResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({
        'tucking': 200,
        'millipede': 'ph://dali-cash/ios/TortoiseBerkelium',
      }),
    );

    await NavigationHelper.applyProduct('product-42');
    await tester.pumpAndSettle();

    expect(apiClient.detailedProducts, isEmpty);
    expect(Get.currentRoute, AppRoutes.login);
  });

  test('apply Conifer target handles its requested product detail', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');
    apiClient.applyResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({
        'tucking': 200,
        'millipede': 'ph://dali-cash/ios/Conifer?highlands=2',
      }),
    );

    await NavigationHelper.applyProduct('product-42');

    expect(apiClient.detailedProducts, ['2']);
    expect(feedbackEvents, ['loading', 'dismiss']);
  });

  test('continues certification by reloading product detail', () async {
    await NavigationHelper.continueProductDetailFlow(' product-42 ');

    expect(apiClient.detailedProducts, ['product-42']);
  });

  testWidgets('successful apply handles normalized product detail internally', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await apiClient.config.sessionStore.saveSessionId('session-id');
    apiClient.detailResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({
        'tucking': 200,
        'shoepac': {'underfeeding': 'product-42', 'saggards': 'ORDER-42'},
        'spirochaete': {
          'entrecote': 'LancerPredacities',
          'enterostomy': 'Identifying information',
        },
        'poolsides': {
          'distention': 'Upload prompt',
          'hoddens': 'Confirmation prompt',
          'variety': 'Face prompt',
        },
      }),
    );

    await NavigationHelper.applyProduct(' product-42 ');

    expect(apiClient.appliedProducts, ['product-42']);
    expect(apiClient.applySources, ['0']);
    expect(apiClient.detailedProducts, ['product-42']);
    expect(Get.currentRoute, AppRoutes.identitySelection);
    expect(Get.arguments, {'highlands': 'product-42'});
    expect(
      apiClient.config.sessionStore.productDetailPrompt(),
      'Upload prompt',
    );
    expect(
      apiClient.config.sessionStore.productDetailIdentityConfirmationPrompt(),
      'Confirmation prompt',
    );
    expect(
      apiClient.config.sessionStore.productDetailFacePrompt(),
      'Face prompt',
    );
    expect(apiClient.config.sessionStore.productDetailOrderNo(), 'ORDER-42');
    expect(navigationLogs, isEmpty);
    expect(feedbackEvents, ['loading', 'dismiss']);
  });

  testWidgets('product detail face step opens face verification', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    apiClient.detailResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({
        'shoepac': {'underfeeding': 'product-face'},
        'spirochaete': {
          'entrecote': 'CilantroCountermemo',
          'enterostomy': 'Face verification',
        },
        'poolsides': {'variety': 'Start live face verification.'},
      }),
    );

    await NavigationHelper.navigateRawTarget(
      'ph://dali-cash/ios/Conifer?highlands=product-face',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.identityFace);
    expect(Get.arguments, {'highlands': 'product-face'});
    expect(
      apiClient.config.sessionStore.productDetailFacePrompt(),
      'Start live face verification.',
    );
    expect(navigationLogs, isEmpty);
  });

  test(
    'recognizes product detail steps whose pages are not available',
    () async {
      const pendingSteps = <String, String>{
        'PermafrostsPalfreys': 'personal',
        'DeviouslyTressours': 'work',
        'TrotlineScootches': 'ext',
        'MolehillSubconscious': 'bank',
      };

      for (final entry in pendingSteps.entries) {
        apiClient.detailResponse = ApiResponse(
          code: 0,
          message: '',
          states: Json({
            'shoepac': {'underfeeding': 'product-42'},
            'spirochaete': {
              'entrecote': entry.key,
              'enterostomy': 'Pending certification',
            },
          }),
        );

        await NavigationHelper.navigateRawTarget(
          'ph://dali-cash/ios/Conifer?highlands=product-42',
        );

        expect(navigationLogs, hasLength(1));
        expect(navigationLogs.single, contains('step=${entry.value}'));
        expect(navigationLogs.single, contains('page not available'));
        navigationLogs.clear();
      }
    },
  );

  test('non-successful admission does not request product detail', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');
    apiClient.applyResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({'tucking': 302, 'detainment': 'Admission denied'}),
    );

    await NavigationHelper.applyProduct('product-42');

    expect(apiClient.detailedProducts, isEmpty);
    expect(feedbackEvents, ['loading', 'dismiss', 'notice:Admission denied']);
  });

  test('product failure dismisses loading and presents stable error', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');
    apiClient.applyError = ApiBusinessException('Apply unavailable');

    await NavigationHelper.applyProduct('product-42');

    expect(apiClient.appliedProducts, ['product-42']);
    expect(feedbackEvents, ['loading', 'dismiss', 'error:Apply unavailable']);
  });

  test('product detail failure uses the shared error handling', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');
    apiClient.detailError = ApiBusinessException('Detail unavailable');

    await NavigationHelper.applyProduct('product-42');

    expect(apiClient.detailedProducts, ['product-42']);
    expect(feedbackEvents, ['loading', 'dismiss', 'error:Detail unavailable']);
  });
}

Future<void> _pumpRoutes(WidgetTester tester) {
  return tester.pumpWidget(
    GetMaterialApp(
      home: const Scaffold(body: Text('Home', key: Key('homeStub'))),
      getPages: [
        GetPage(
          name: AppRoutes.login,
          page: () =>
              const Scaffold(body: Text('Login', key: Key('loginStub'))),
        ),
        GetPage(
          name: '/middle',
          page: () =>
              const Scaffold(body: Text('Middle', key: Key('middleStub'))),
        ),
        GetPage(
          name: AppRoutes.identitySelection,
          page: () => const Scaffold(
            body: Text('Identity', key: Key('identitySelectionStub')),
          ),
        ),
        GetPage(
          name: AppRoutes.identityFace,
          page: () =>
              const Scaffold(body: Text('Face', key: Key('identityFaceStub'))),
        ),
      ],
    ),
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(ApiConfig());

  final List<String> appliedProducts = <String>[];
  final List<String> applySources = <String>[];
  final List<String> detailedProducts = <String>[];
  ApiResponse applyResponse = ApiResponse(
    code: 0,
    message: '',
    states: Json({'tucking': 200}),
  );
  ApiResponse detailResponse = ApiResponse(
    code: 0,
    message: '',
    states: Json({
      'shoepac': {'underfeeding': 'product-42'},
    }),
  );
  Object? applyError;
  Object? detailError;

  @override
  Future<ApiResponse> productApply({
    required String productId,
    String source = '0',
  }) async {
    appliedProducts.add(productId);
    applySources.add(source);
    final error = applyError;
    if (error != null) {
      throw error;
    }
    return applyResponse;
  }

  @override
  Future<ApiResponse> productDetail({required String productId}) async {
    detailedProducts.add(productId);
    final error = detailError;
    if (error != null) {
      throw error;
    }
    return detailResponse;
  }
}

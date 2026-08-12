import 'dart:async';

import 'package:dali_cash/app/navigation/navigation_helper.dart';
import 'package:dali_cash/app/routes/app_routes.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/permissions/permission_coordinator.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/orders/order_list_item.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late _FakeApiClient apiClient;
  late List<String> feedbackEvents;
  late List<String> navigationLogs;
  late List<int> navigatedTabs;
  late List<String> permissionPrompts;
  late List<String> locationReports;
  late List<Map<String, String>> productRedirectReports;
  late List<Uri> externalUris;
  late int settingsOpenCount;

  setUp(() async {
    Get.testMode = true;
    apiClient = _FakeApiClient();
    apiClient.config.sessionStore = SessionStore.memory();
    feedbackEvents = <String>[];
    navigationLogs = <String>[];
    navigatedTabs = <int>[];
    permissionPrompts = <String>[];
    locationReports = <String>[];
    productRedirectReports = <Map<String, String>>[];
    externalUris = <Uri>[];
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
    NavigationHelper.locationReporter = () async {
      locationReports.add('report');
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
    NavigationHelper
        .productRedirectReporter = ({required productId, required orderNo}) {
      productRedirectReports.add({'productId': productId, 'orderNo': orderNo});
    };
    NavigationHelper.externalUriLauncher = (uri) async {
      externalUris.add(uri);
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
    NavigationHelper.locationReporter =
        NavigationHelper.defaultLocationReporter;
    NavigationHelper.permissionPromptPresenter =
        NavigationHelper.defaultPermissionPromptPresenter;
    NavigationHelper.appSettingsOpener =
        NavigationHelper.defaultAppSettingsOpener;
    NavigationHelper.productRedirectReporter =
        NavigationHelper.defaultProductRedirectReporter;
    NavigationHelper.externalUriLauncher =
        NavigationHelper.defaultExternalUriLauncher;
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

  testWidgets('WebView login target returns login to Home', (tester) async {
    await _pumpRoutes(tester);

    NavigationHelper.toWebView<void>(url: 'https://example.test/repayment');
    await tester.pumpAndSettle();

    await NavigationHelper.navigateWebViewRawTarget(
      'ph://dali-cash/ios/TortoiseBerkelium',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(find.byKey(const Key('webViewStub')), findsNothing);

    NavigationHelper.back<void>();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.byKey(const Key('homeStub')), findsOneWidget);
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
    expect(feedbackEvents, ['loading', 'dismiss']);
    expect(navigationLogs.single, contains('status=0'));
  });

  testWidgets('routes each documented order scheme status to the order list', (
    tester,
  ) async {
    await _pumpRoutes(tester);

    for (final status in MineOrderStatus.values) {
      await NavigationHelper.navigateRawTarget(
        'ph://dali-cash/ios/Luminance?anfractuosity=${status.code}',
      );
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.mineOrderList);
      expect(Get.arguments, {'initialStatus': status.code});

      NavigationHelper.back<void>();
      await tester.pumpAndSettle();
    }
    expect(navigationLogs, isEmpty);
  });

  testWidgets('defaults an invalid order scheme status to all', (tester) async {
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'ph://dali-cash/ios/Luminance?anfractuosity=unknown',
    );
    await tester.pumpAndSettle();

    expect(Get.arguments, {'initialStatus': MineOrderStatus.all.code});
  });

  test('runs admission from the documented Mateys scheme product id', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');

    await NavigationHelper.navigateRawTarget(
      'ph://dali-cash/ios/Mateys?highlands=product-42',
    );

    expect(apiClient.appliedProducts, ['product-42']);
    expect(apiClient.applySources, ['0']);
  });

  test(
    'does not run admission when the Mateys scheme has no product id',
    () async {
      await NavigationHelper.navigateRawTarget('ph://dali-cash/ios/Mateys');

      expect(apiClient.appliedProducts, isEmpty);
      expect(navigationLogs, ['admission target is missing highlands: Mateys']);
    },
  );

  testWidgets('routes the documented recredit scheme to its waiting page', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await NavigationHelper.navigateRawTarget('ph://dali-cash/ios/Heed');

    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.recredit);
    expect(find.byKey(const Key('recreditStub')), findsOneWidget);
    expect(navigationLogs, isEmpty);
  });

  testWidgets('routes HTTP targets to the internal WebView', (tester) async {
    await _pumpRoutes(tester);

    await NavigationHelper.navigateRawTarget(
      'https://example.test/errorUrl?productId=42',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://example.test/errorUrl?productId=42',
      'title': null,
    });
    expect(navigationLogs, isEmpty);
  });

  testWidgets('opens configured H5 paths in the internal WebView', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    apiClient.config.webBaseUrl = 'https://h5.example';

    NavigationHelper.toWebPath<void>(path: '/#/SlinkierDesulfured');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://h5.example/#/SlinkierDesulfured',
      'title': null,
    });

    Get.back<void>();
    await tester.pumpAndSettle();
    NavigationHelper.toWebPath<void>(path: '/#/Turbocharger');
    await tester.pumpAndSettle();

    expect(Get.arguments, {
      'url': 'https://h5.example/#/Turbocharger',
      'title': null,
    });
  });

  test('opens external URIs through the injected launcher', () async {
    final opened = await NavigationHelper.openExternalUri(
      Uri.parse('tel:+639171234567'),
    );

    expect(opened, isTrue);
    expect(externalUris, [Uri.parse('tel:+639171234567')]);
  });

  testWidgets('replaces one old WebView and account-change bind route', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    NavigationHelper.toWebView<void>(url: 'https://example.test/old');
    await tester.pumpAndSettle();
    NavigationHelper.toBindCard<void>(productId: 'product-1');
    await tester.pumpAndSettle();

    NavigationHelper.replaceWebView<void>(
      url: 'https://example.test/new',
      removeBindCard: true,
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {'url': 'https://example.test/new', 'title': null});
    NavigationHelper.back<void>();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeStub')), findsOneWidget);
    expect(find.byKey(const Key('bindCardStub')), findsNothing);
  });

  testWidgets('replaces the account-list flow and returns to Home', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    NavigationHelper.toWebView<void>(url: 'https://example.test/old');
    await tester.pumpAndSettle();
    Get.toNamed<void>(AppRoutes.accountList);
    await tester.pumpAndSettle();

    NavigationHelper.replaceAccountChangeFlowWithWebView<void>(
      url: '  https://example.test/new  ',
      title: 'Replacement',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {
      'url': 'https://example.test/new',
      'title': 'Replacement',
    });
    expect(
      find.text('https://example.test/old', skipOffstage: false),
      findsNothing,
    );
    expect(
      find.byKey(const Key('accountListStub'), skipOffstage: false),
      findsNothing,
    );

    NavigationHelper.back<void>();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeStub')), findsOneWidget);
    expect(
      find.byKey(const Key('accountListStub'), skipOffstage: false),
      findsNothing,
    );
    expect(
      find.text('https://example.test/old', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('replaces account-list and bind-card flow and returns to Home', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    NavigationHelper.toWebView<void>(url: 'https://example.test/old');
    await tester.pumpAndSettle();
    Get.toNamed<void>(AppRoutes.accountList);
    await tester.pumpAndSettle();
    NavigationHelper.toBindCard<void>(productId: 'product-1');
    await tester.pumpAndSettle();

    NavigationHelper.replaceAccountChangeFlowWithWebView<void>(
      url: 'https://example.test/new',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(Get.arguments, {'url': 'https://example.test/new', 'title': null});
    expect(
      find.byKey(const Key('accountListStub'), skipOffstage: false),
      findsNothing,
    );
    expect(
      find.byKey(const Key('bindCardStub'), skipOffstage: false),
      findsNothing,
    );
    expect(
      find.text('https://example.test/old', skipOffstage: false),
      findsNothing,
    );

    NavigationHelper.back<void>();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('homeStub')), findsOneWidget);
    expect(
      find.byKey(const Key('accountListStub'), skipOffstage: false),
      findsNothing,
    );
    expect(
      find.byKey(const Key('bindCardStub'), skipOffstage: false),
      findsNothing,
    );
    expect(
      find.text('https://example.test/old', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('invalid account-change replacement leaves the stack unchanged', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    NavigationHelper.toWebView<void>(url: 'https://example.test/old');
    await tester.pumpAndSettle();
    Get.toNamed<void>(AppRoutes.accountList, arguments: {'source': 'test'});
    await tester.pumpAndSettle();

    final result = NavigationHelper.replaceAccountChangeFlowWithWebView<void>(
      url: 'javascript:alert(1)',
    );
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(Get.currentRoute, AppRoutes.accountList);
    expect(Get.arguments, {'source': 'test'});
    expect(find.byKey(const Key('accountListStub')), findsOneWidget);
    expect(navigationLogs.single, contains('invalid WebView replacement URL'));

    NavigationHelper.back<void>();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(find.text('https://example.test/old'), findsOneWidget);
  });

  testWidgets('opens bind-card with Dali account-change arguments', (
    tester,
  ) async {
    await _pumpRoutes(tester);

    NavigationHelper.toBindCard<void>(
      productId: 'product-2',
      orderNo: 'ORDER-2',
      isAccountChange: true,
    );
    await tester.pumpAndSettle();

    expect(Get.arguments, {
      'highlands': 'product-2',
      'saggards': 'ORDER-2',
      'isAccountChange': true,
    });
  });

  testWidgets('opens account list with Dali product and order arguments', (
    tester,
  ) async {
    await _pumpRoutes(tester);

    NavigationHelper.toAccountList<void>(
      productId: ' product-3 ',
      orderNo: ' ORDER-3 ',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.accountList);
    expect(Get.arguments, {'highlands': 'product-3', 'saggards': 'ORDER-3'});
    expect(find.byKey(const Key('accountListStub')), findsOneWidget);
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

  testWidgets('server-selected certification step prunes completed flow', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await NavigationHelper.toIdentitySelection<void>(productId: 'product-42');
    Get.toNamed<void>(AppRoutes.identityUpload);
    await tester.pumpAndSettle();
    Get.toNamed<void>(AppRoutes.identityConfirmation);
    await tester.pumpAndSettle();

    await NavigationHelper.toIdentityFace<void>(productId: 'product-42');
    await tester.pumpAndSettle();
    NavigationHelper.back<void>();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/');
    expect(find.byKey(const Key('homeStub')), findsOneWidget);
    expect(find.byKey(const Key('identitySelectionStub')), findsNothing);
    expect(find.byKey(const Key('identityUploadStub')), findsNothing);
    expect(find.byKey(const Key('identityConfirmationStub')), findsNothing);
  });

  testWidgets('final WebView navigation prunes the completed bind-card page', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await NavigationHelper.toBindCard<void>(productId: 'product-42');
    await tester.pumpAndSettle();

    NavigationHelper.toWebView<void>(url: 'https://example.test/result');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(
      find.byKey(const Key('bindCardStub'), skipOffstage: false),
      findsNothing,
    );

    NavigationHelper.back<void>();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('homeStub')), findsOneWidget);
  });

  testWidgets('confirmation WebView replaces its recommendation WebView', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    NavigationHelper.toWebView<void>(
      url: 'https://example.test/recommendations',
    );
    await tester.pumpAndSettle();

    NavigationHelper.toWebView<void>(
      url: 'https://example.test/Florescences?thunderstruck=product-42',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.webView);
    expect(
      find.text('https://example.test/recommendations', skipOffstage: false),
      findsNothing,
    );

    NavigationHelper.back<void>();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/');
    expect(find.byKey(const Key('homeStub')), findsOneWidget);
    expect(find.byKey(const Key('webViewStub')), findsNothing);
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
    expect(locationReports, isEmpty);
    expect(feedbackEvents, isEmpty);
    expect(permissionPrompts, isEmpty);
  });

  testWidgets('location permission resume does not refresh the Home tab', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await apiClient.config.sessionStore.saveSessionId('session-id');
    final controller = MainController(
      apiClient: apiClient,
      showError: (_) {},
      showNotice: (_) {},
    );
    Get.put<MainController>(controller);
    addTearDown(controller.onClose);
    await tester.pumpAndSettle();
    final initialHomeCalls = apiClient.homeCalls;

    final permission = Completer<CertificationLocationDecision>();
    final requestStarted = Completer<void>();
    NavigationHelper.certificationLocationRequester = () {
      if (!requestStarted.isCompleted) {
        requestStarted.complete();
      }
      return permission.future;
    };
    final apply = NavigationHelper.applyProduct('product-42');
    await requestStarted.future;

    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    permission.complete(CertificationLocationDecision.denied);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await apply;
    await tester.pumpAndSettle();

    expect(apiClient.homeCalls, initialHomeCalls);
    expect(apiClient.appliedProducts, isEmpty);
  });

  test(
    'recredit completion skips location access check before apply',
    () async {
      await apiClient.config.sessionStore.saveSessionId('session-id');
      var locationRequests = 0;
      NavigationHelper.certificationLocationRequester = () async {
        locationRequests += 1;
        return CertificationLocationDecision.denied;
      };

      await NavigationHelper.applyProductAfterRecredit(' product-42 ');

      expect(locationRequests, 0);
      expect(apiClient.appliedProducts, ['product-42']);
      expect(locationReports, ['report']);
    },
  );

  test('granted location starts reporting without blocking apply', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');
    final reportCompleter = Completer<void>();
    NavigationHelper.locationReporter = () {
      locationReports.add('report');
      return reportCompleter.future;
    };

    await NavigationHelper.applyProduct('product-42');

    expect(locationReports, ['report']);
    expect(apiClient.appliedProducts, ['product-42']);
    reportCompleter.complete();
  });

  test('reporting failure does not stop product apply', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');
    NavigationHelper.locationReporter = () async {
      locationReports.add('report');
      throw StateError('report failed');
    };

    await NavigationHelper.applyProduct('product-42');
    await Future<void>.delayed(Duration.zero);

    expect(locationReports, ['report']);
    expect(apiClient.appliedProducts, ['product-42']);
    expect(
      navigationLogs,
      contains(contains('location and device report before apply failed')),
    );
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
    expect(permissionPrompts.single, contains('Allow Location Access'));
    expect(settingsOpenCount, 1);
    expect(feedbackEvents, isEmpty);
  });

  test(
    'permanent location denial can continue when settings prompt is canceled',
    () async {
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
            expect(title, 'Allow Location Access');
            expect(cancelText, 'Cancel');
            expect(confirmText, 'Settings');
            return false;
          };

      await NavigationHelper.applyProduct('product-42');

      expect(apiClient.appliedProducts, ['product-42']);
    },
  );

  testWidgets('disabled location service opens settings and stops apply', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    await apiClient.config.sessionStore.saveSessionId('session-id');
    NavigationHelper.certificationLocationRequester = () async {
      return CertificationLocationDecision.serviceDisabled;
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
    expect(permissionPrompts.single, contains('Turn On Location Services'));
    expect(settingsOpenCount, 1);
  });

  test(
    'disabled location service can continue when settings prompt is canceled',
    () async {
      await apiClient.config.sessionStore.saveSessionId('session-id');
      NavigationHelper.certificationLocationRequester = () async {
        return CertificationLocationDecision.serviceDisabled;
      };
      NavigationHelper.permissionPromptPresenter =
          ({
            required title,
            required content,
            required cancelText,
            required confirmText,
          }) async {
            expect(title, 'Turn On Location Services');
            expect(cancelText, 'Cancel');
            expect(confirmText, 'Settings');
            return false;
          };

      await NavigationHelper.applyProduct('product-42');

      expect(apiClient.appliedProducts, ['product-42']);
    },
  );

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
    expect(feedbackEvents, ['loading', 'dismiss']);
  });

  test('product detail continuation replaces loading with an error', () async {
    apiClient.detailError = ApiBusinessException('Detail unavailable');

    await NavigationHelper.continueProductDetailFlow('product-42');

    expect(apiClient.detailedProducts, ['product-42']);
    expect(feedbackEvents, ['loading', 'error:Detail unavailable']);
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

  testWidgets('product detail personal step opens personal information', (
    tester,
  ) async {
    await _pumpRoutes(tester);
    apiClient.detailResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({
        'shoepac': {'underfeeding': 'product-personal'},
        'spirochaete': {
          'entrecote': 'PermafrostsPalfreys',
          'enterostomy': 'Personal information',
        },
      }),
    );

    await NavigationHelper.navigateRawTarget(
      'ph://dali-cash/ios/Conifer?highlands=product-personal',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.personalInformation);
    expect(Get.arguments, {'highlands': 'product-personal'});
    expect(find.byKey(const Key('personalInformationStub')), findsOneWidget);
    expect(navigationLogs, isEmpty);
  });

  testWidgets(
    'routes the work-information product detail step with product id',
    (tester) async {
      await _pumpRoutes(tester);
      apiClient.detailResponse = ApiResponse(
        code: 0,
        message: '',
        states: Json({
          'shoepac': {'underfeeding': 'product-work'},
          'spirochaete': {
            'entrecote': 'DeviouslyTressours',
            'enterostomy': 'Work information',
          },
        }),
      );

      await NavigationHelper.navigateRawTarget(
        'ph://dali-cash/ios/Conifer?highlands=product-work',
      );
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.workInformation);
      expect(Get.arguments, {'highlands': 'product-work'});
      expect(find.byKey(const Key('workInformationStub')), findsOneWidget);
      expect(navigationLogs, isEmpty);
    },
  );

  testWidgets('bank step opens bind-card certification', (tester) async {
    await _pumpRoutes(tester);
    apiClient.detailResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({
        'shoepac': {'underfeeding': 'product-bind'},
        'spirochaete': {
          'entrecote': 'MolehillSubconscious',
          'enterostomy': 'Account management',
        },
      }),
    );

    await NavigationHelper.navigateRawTarget(
      'ph://dali-cash/ios/Conifer?highlands=product-bind',
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.bindCard);
    expect(Get.arguments, {'highlands': 'product-bind'});
    expect(find.byKey(const Key('bindCardStub')), findsOneWidget);
    expect(navigationLogs, isEmpty);
  });

  final originalProductDetailSteps = <(String, String, String)>[
    ('public', AppRoutes.identitySelection, 'identitySelectionStub'),
    ('face', AppRoutes.identityFace, 'identityFaceStub'),
    ('personal', AppRoutes.personalInformation, 'personalInformationStub'),
    ('work', AppRoutes.workInformation, 'workInformationStub'),
    ('ext', AppRoutes.emergencyContact, 'emergencyContactStub'),
    ('bank', AppRoutes.bindCard, 'bindCardStub'),
  ];
  for (final (step, route, stubKey) in originalProductDetailSteps) {
    testWidgets('product detail original $step step opens its page', (
      tester,
    ) async {
      await _pumpRoutes(tester);
      apiClient.detailResponse = ApiResponse(
        code: 0,
        message: '',
        states: Json({
          'shoepac': {'underfeeding': 'product-$step'},
          'spirochaete': {'entrecote': step},
        }),
      );

      await NavigationHelper.navigateRawTarget(
        'ph://dali-cash/ios/Conifer?highlands=product-$step',
      );
      await tester.pumpAndSettle();

      expect(Get.currentRoute, route);
      expect(Get.arguments, {'highlands': 'product-$step'});
      expect(find.byKey(Key(stubKey)), findsOneWidget);
    });
  }

  test(
    'product detail continuation resolves order target after step completion',
    () async {
      final redirectResponse = Completer<ApiResponse>();
      apiClient.pendingProductPushResponse = redirectResponse;
      apiClient.detailResponse = ApiResponse(
        code: 0,
        message: '',
        states: Json({
          'tucking': 200,
          'shoepac': {
            'underfeeding': 'product-order',
            'saggards': 'ORDER-42',
            'injective': '1100.00',
            'resmooth': '91',
            'mispatch': 1,
          },
          'spirochaete': {'entrecote': ''},
        }),
      );

      final continuation = NavigationHelper.continueProductDetailFlow(
        'product-order',
      );
      await Future<void>.delayed(Duration.zero);

      expect(apiClient.productPushRequests, [
        {
          'orderNo': 'ORDER-42',
          'amount': '1100.00',
          'term': '91',
          'termType': '1',
        },
      ]);
      expect(productRedirectReports, isEmpty);

      redirectResponse.complete(
        ApiResponse(
          code: 0,
          message: '',
          states: Json({'millipede': 'https://example.test/order/ORDER-42'}),
        ),
      );
      await continuation;

      expect(productRedirectReports, [
        {'productId': 'product-order', 'orderNo': 'ORDER-42'},
      ]);
      expect(navigationLogs, isEmpty);
    },
  );

  test('product detail continuation logs a missing order number', () async {
    apiClient.detailResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({
        'tucking': 200,
        'shoepac': {'underfeeding': 'product-no-order'},
      }),
    );

    await NavigationHelper.continueProductDetailFlow('product-no-order');

    expect(apiClient.productPushRequests, isEmpty);
    expect(productRedirectReports, isEmpty);
    expect(navigationLogs.single, contains('missing order number'));
  });

  test('product detail continuation logs an empty order target', () async {
    apiClient.detailResponse = ApiResponse(
      code: 0,
      message: '',
      states: Json({
        'tucking': 200,
        'shoepac': {
          'underfeeding': 'product-empty-target',
          'saggards': 'ORDER-EMPTY',
        },
      }),
    );

    await NavigationHelper.continueProductDetailFlow('product-empty-target');

    expect(apiClient.productPushRequests, hasLength(1));
    expect(productRedirectReports, hasLength(1));
    expect(navigationLogs.single, contains('empty target'));
  });

  test(
    'product detail continuation logs a non-success detail status',
    () async {
      apiClient.detailResponse = ApiResponse(
        code: 0,
        message: '',
        states: Json({
          'tucking': 302,
          'shoepac': {
            'underfeeding': 'product-denied',
            'saggards': 'ORDER-DENIED',
          },
        }),
      );

      await NavigationHelper.continueProductDetailFlow('product-denied');

      expect(apiClient.productPushRequests, isEmpty);
      expect(productRedirectReports, isEmpty);
      expect(navigationLogs.single, contains('status=302'));
    },
  );

  test(
    'unknown product detail step logs without resolving an order target',
    () async {
      apiClient.detailResponse = ApiResponse(
        code: 0,
        message: '',
        states: Json({
          'tucking': 200,
          'shoepac': {
            'underfeeding': 'product-unknown',
            'saggards': 'ORDER-UNKNOWN',
          },
          'spirochaete': {'entrecote': 'FutureCertificationStep'},
        }),
      );

      await NavigationHelper.continueProductDetailFlow('product-unknown');

      expect(apiClient.productPushRequests, isEmpty);
      expect(productRedirectReports, isEmpty);
      expect(navigationLogs.single, contains('FutureCertificationStep'));
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
    expect(feedbackEvents, ['loading', 'notice:Admission denied']);
  });

  test('product failure replaces loading with a stable error', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');
    apiClient.applyError = ApiBusinessException('Apply unavailable');

    await NavigationHelper.applyProduct('product-42');

    expect(apiClient.appliedProducts, ['product-42']);
    expect(feedbackEvents, ['loading', 'error:Apply unavailable']);
  });

  test('product detail failure uses the shared error handling', () async {
    await apiClient.config.sessionStore.saveSessionId('session-id');
    apiClient.detailError = ApiBusinessException('Detail unavailable');

    await NavigationHelper.applyProduct('product-42');

    expect(apiClient.detailedProducts, ['product-42']);
    expect(feedbackEvents, ['loading', 'error:Detail unavailable']);
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
          name: AppRoutes.recredit,
          page: () =>
              const Scaffold(body: Text('Recredit', key: Key('recreditStub'))),
        ),
        GetPage(
          name: AppRoutes.mineOrderList,
          page: () => const Scaffold(
            body: Text('Orders', key: Key('mineOrderListStub')),
          ),
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
          name: AppRoutes.identityUpload,
          page: () => const Scaffold(
            body: Text('Upload', key: Key('identityUploadStub')),
          ),
        ),
        GetPage(
          name: AppRoutes.identityConfirmation,
          page: () => const Scaffold(
            body: Text('Confirmation', key: Key('identityConfirmationStub')),
          ),
        ),
        GetPage(
          name: AppRoutes.identityFace,
          page: () =>
              const Scaffold(body: Text('Face', key: Key('identityFaceStub'))),
        ),
        GetPage(
          name: AppRoutes.personalInformation,
          page: () => const Scaffold(
            body: Text('Personal', key: Key('personalInformationStub')),
          ),
        ),
        GetPage(
          name: AppRoutes.workInformation,
          page: () => const Scaffold(
            body: Text('Work', key: Key('workInformationStub')),
          ),
        ),
        GetPage(
          name: AppRoutes.emergencyContact,
          page: () => const Scaffold(
            body: Text('Emergency', key: Key('emergencyContactStub')),
          ),
        ),
        GetPage(
          name: AppRoutes.bindCard,
          page: () =>
              const Scaffold(body: Text('Bind card', key: Key('bindCardStub'))),
        ),
        GetPage(
          name: AppRoutes.accountList,
          page: () => const Scaffold(
            body: Text('Account list', key: Key('accountListStub')),
          ),
        ),
        GetPage(
          name: AppRoutes.webView,
          page: () => Scaffold(
            body: Text(
              Get.arguments?['url']?.toString() ?? '',
              key: const Key('webViewStub'),
            ),
          ),
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
  int homeCalls = 0;
  final List<Map<String, String>> productPushRequests = <Map<String, String>>[];
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
  Completer<ApiResponse>? pendingProductPushResponse;
  ApiResponse productPushResponse = ApiResponse(
    code: 0,
    message: '',
    states: Json({'millipede': ''}),
  );

  @override
  Future<ApiResponse> homePage() async {
    homeCalls++;
    return ApiResponse(code: 0, message: '', states: Json(null));
  }

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

  @override
  Future<ApiResponse> productPush({
    required String orderNo,
    required String amount,
    required String term,
    required String termType,
  }) async {
    productPushRequests.add({
      'orderNo': orderNo,
      'amount': amount,
      'term': term,
      'termType': termType,
    });
    return pendingProductPushResponse?.future ?? productPushResponse;
  }
}

import 'dart:async';

import 'package:dali_cash/app/navigation/navigation_helper.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/permissions/permission_coordinator.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:dali_cash/features/progress/progress_item.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ScriptedApiClient apiClient;
  late List<String> errors;
  late List<String> notices;
  late List<String> loadingEvents;
  late List<String> bannerTargets;
  late MainController controller;

  setUp(() async {
    Get.testMode = true;
    apiClient = _ScriptedApiClient();
    final sessionStore = SessionStore.memory();
    await sessionStore.saveSessionId('session-id');
    apiClient.config.sessionStore = sessionStore;
    errors = <String>[];
    notices = <String>[];
    loadingEvents = <String>[];
    bannerTargets = <String>[];
    controller = MainController(
      apiClient: apiClient,
      showError: (message) {
        errors.add(message);
        loadingEvents.add('error');
      },
      showNotice: notices.add,
      showLoading: () async => loadingEvents.add('loading'),
      dismissLoading: () async => loadingEvents.add('dismiss'),
      navigateBannerTarget: (target) async => bannerTargets.add(target),
    );
  });

  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test('loads and parses home before requesting scene 1 popup', () async {
    apiClient.homeReplies.add(() async {
      apiClient.events.add('home-complete');
      return _homeResponse(productId: 'loan-42');
    });
    apiClient.dialogReplies.add((scene) async {
      apiClient.events.add('dialog-complete');
      return _dialogResponse(0);
    });

    await controller.requestHomeDataIfVisible();

    expect(controller.homeData.value?.loanOffer?.productId, 'loan-42');
    expect(apiClient.dialogScenes, [1]);
    expect(apiClient.events, [
      'home-start',
      'home-complete',
      'dialog-start',
      'dialog-complete',
    ]);
    expect(loadingEvents, ['loading', 'dismiss']);
  });

  test('GetX update notifications do not trigger a network request', () async {
    controller.update();
    await pumpEventQueue();

    expect(apiClient.homeCalls, 0);
    expect(apiClient.dialogScenes, isEmpty);
  });

  test(
    'explicit refresh runs the request chain independent of selected tab',
    () async {
      controller.selectedIndex.value = 2;
      apiClient.homeReplies.add(
        () async => _homeResponse(productId: 'explicit-refresh'),
      );
      apiClient.dialogReplies.add((_) async => _dialogResponse(0));

      await controller.refreshHome();

      expect(
        controller.homeData.value?.loanOffer?.productId,
        'explicit-refresh',
      );
      expect(apiClient.homeCalls, 1);
      expect(apiClient.dialogScenes, [1]);
      expect(loadingEvents, ['loading', 'dismiss']);
    },
  );

  test('assigns home data before the pending popup completes', () async {
    final dialogCompleter = Completer<ApiResponse>();
    apiClient.homeReplies.add(
      () async => _homeResponse(productId: 'available-before-popup'),
    );
    apiClient.dialogReplies.add((_) => dialogCompleter.future);

    final request = controller.requestHomeDataIfVisible();
    await pumpEventQueue();

    expect(apiClient.dialogScenes, [1]);
    expect(
      controller.homeData.value?.loanOffer?.productId,
      'available-before-popup',
    );
    expect(loadingEvents, ['loading', 'dismiss']);

    dialogCompleter.complete(_dialogResponse(0));
    await request;
  });

  test(
    'waits for Home loading presentation before starting the request',
    () async {
      final loading = Completer<void>();
      final value = MainController(
        apiClient: apiClient,
        showError: errors.add,
        showNotice: notices.add,
        showLoading: () => loading.future,
      );
      addTearDown(value.onClose);
      apiClient.homeReplies.add(() async => _homeResponse());
      apiClient.dialogReplies.add((_) async => _dialogResponse(0));

      final request = value.requestHomeDataIfVisible();
      await Future<void>.delayed(Duration.zero);
      expect(apiClient.homeCalls, 0);

      loading.complete();
      await request;
      expect(apiClient.homeCalls, 1);
    },
  );

  test('popup type 0 and unsupported types remain silent', () async {
    for (final type in [0, 4]) {
      apiClient.homeReplies.add(() async => _homeResponse());
      apiClient.dialogReplies.add((_) async => _dialogResponse(type));
      await controller.requestHomeDataIfVisible();
    }

    expect(notices, isEmpty);
  });

  test('popup types 1, 2, and 3 present the information notice', () async {
    for (final type in [1, 2, 3]) {
      apiClient.homeReplies.add(() async => _homeResponse());
      apiClient.dialogReplies.add((_) async => _dialogResponse(type));
      await controller.requestHomeDataIfVisible();
    }

    expect(notices, [
      'New information available',
      'New information available',
      'New information available',
    ]);
  });

  test(
    'home failure preserves data while popup request runs independently',
    () async {
      final previous = HomeData.fromJson(Json(const <String, dynamic>{}));
      controller.homeData.value = previous;
      apiClient.homeReplies.add(
        () =>
            Future<ApiResponse>.error(ApiBusinessException('Home unavailable')),
      );

      await controller.requestHomeDataIfVisible();

      expect(controller.homeData.value, same(previous));
      expect(errors, ['Home unavailable']);
      expect(apiClient.dialogScenes, [1]);
    },
  );

  test('unknown home failure uses the stable fallback message', () async {
    apiClient.homeReplies.add(
      () => Future<ApiResponse>.error(StateError('transport detail')),
    );

    await controller.requestHomeDataIfVisible();

    expect(errors, ['Request failed']);
    expect(apiClient.dialogScenes, [1]);
  });

  test('timed out Home request allows a retry', () async {
    final pendingHomeRequest = Completer<ApiResponse>();
    final value = MainController(
      apiClient: apiClient,
      showError: errors.add,
      showNotice: notices.add,
      showLoading: () async => loadingEvents.add('loading'),
      dismissLoading: () async => loadingEvents.add('dismiss'),
      homeRequestTimeout: Duration.zero,
    );
    addTearDown(value.onClose);
    apiClient.homeReplies.add(() => pendingHomeRequest.future);
    apiClient.dialogReplies.add((_) async => _dialogResponse(0));

    await value.requestHomeDataIfVisible();

    expect(errors, ['Request timed out']);
    expect(loadingEvents, ['loading']);

    apiClient.homeReplies.add(() async => _homeResponse(productId: 'retry'));
    apiClient.dialogReplies.add((_) async => _dialogResponse(0));
    await value.requestHomeDataIfVisible();

    expect(apiClient.homeCalls, 2);
    expect(value.homeData.value?.loanOffer?.productId, 'retry');
  });

  test(
    'Loading dismissal failure does not prevent the next Home refresh',
    () async {
      final value = MainController(
        apiClient: apiClient,
        showError: errors.add,
        showNotice: notices.add,
        showLoading: () async => loadingEvents.add('loading'),
        dismissLoading: () async => throw StateError('overlay disposed'),
      );
      addTearDown(value.onClose);
      apiClient.homeReplies.addAll([
        () async => _homeResponse(productId: 'first'),
        () async => _homeResponse(productId: 'second'),
      ]);
      apiClient.dialogReplies.addAll([
        (_) async => _dialogResponse(0),
        (_) async => _dialogResponse(0),
      ]);

      await value.requestHomeDataIfVisible();
      await value.requestHomeDataIfVisible();

      expect(apiClient.homeCalls, 2);
      expect(value.homeData.value?.loanOffer?.productId, 'second');
      expect(errors, isEmpty);
    },
  );

  test('popup failure stays silent and retains loaded home data', () async {
    apiClient.homeReplies.add(() async => _homeResponse(productId: 'kept'));
    apiClient.dialogReplies.add(
      (_) => Future<ApiResponse>.error(ApiBusinessException('Popup failed')),
    );

    await controller.requestHomeDataIfVisible();

    expect(controller.homeData.value?.loanOffer?.productId, 'kept');
    expect(errors, isEmpty);
    expect(notices, isEmpty);
  });

  test('overlapping refreshes retain the newest Home response', () async {
    final firstHome = Completer<ApiResponse>();
    apiClient.homeReplies.addAll([
      () => firstHome.future,
      () async => _homeResponse(productId: 'newest'),
    ]);
    apiClient.dialogReplies.addAll([
      (_) async => _dialogResponse(0),
      (_) async => _dialogResponse(0),
    ]);

    final first = controller.requestHomeDataIfVisible();
    await pumpEventQueue();
    final overlap = controller.requestHomeDataIfVisible();
    await overlap;
    expect(apiClient.homeCalls, 2);
    expect(controller.homeData.value?.loanOffer?.productId, 'newest');

    firstHome.complete(_homeResponse(productId: 'older'));
    await first;

    expect(controller.homeData.value?.loanOffer?.productId, 'newest');
    expect(apiClient.dialogScenes, [1, 1]);
  });

  test(
    'login refresh supersedes an in-flight logged-out Home request',
    () async {
      final loggedOutHome = Completer<ApiResponse>();
      final loggedOutPopup = Completer<ApiResponse>();
      apiClient.homeReplies.addAll([
        () => loggedOutHome.future,
        () async => _homeResponse(productId: 'logged-in-home'),
      ]);
      apiClient.dialogReplies.addAll([
        (_) => loggedOutPopup.future,
        (_) async => _dialogResponse(0),
      ]);

      final loggedOutRefresh = controller.requestHomeDataIfVisible();
      await pumpEventQueue();
      final loginRefresh = controller.refreshHomeAfterLogin();
      await loginRefresh;

      expect(apiClient.homeCalls, 2);
      expect(controller.homeData.value?.loanOffer?.productId, 'logged-in-home');
      loggedOutHome.complete(_homeResponse(productId: 'logged-out-home'));
      loggedOutPopup.complete(_dialogResponse(1));
      await loggedOutRefresh;
      await pumpEventQueue();

      expect(controller.homeData.value?.loanOffer?.productId, 'logged-in-home');
      expect(notices, isEmpty);
      expect(loadingEvents, ['loading', 'loading', 'dismiss']);
    },
  );

  test('every switch into Progress refreshes home without popup', () async {
    apiClient.homeReplies.addAll([
      () async => _homeResponse(productId: 'progress-first'),
      () async => _homeResponse(productId: 'home'),
      () async => _homeResponse(productId: 'progress-second'),
    ]);
    apiClient.dialogReplies.add((_) async => _dialogResponse(0));

    await controller.selectTab(1);
    expect(controller.selectedIndex.value, 1);
    expect(apiClient.homeCalls, 1);
    expect(apiClient.dialogScenes, isEmpty);

    await controller.selectTab(0);
    await controller.selectTab(1);

    expect(controller.selectedIndex.value, 1);
    expect(apiClient.homeCalls, 3);
    expect(apiClient.dialogScenes, [1]);
    expect(controller.homeData.value?.loanOffer?.productId, 'progress-second');
  });

  test('selecting the current tab returns without dispatching', () async {
    await controller.selectTab(0);

    expect(apiClient.homeCalls, 0);
  });

  test(
    'returning to Home from a protected tab refreshes visible data',
    () async {
      controller.selectedIndex.value = 2;
      apiClient.homeReplies.add(
        () async => _homeResponse(productId: 'after-exit'),
      );
      apiClient.dialogReplies.add((_) async => _dialogResponse(0));

      controller.returnToHomeTab();
      await pumpEventQueue();

      expect(controller.selectedIndex.value, 0);
      expect(apiClient.homeCalls, 1);
      expect(apiClient.dialogScenes, [1]);
      expect(controller.homeData.value?.loanOffer?.productId, 'after-exit');
    },
  );

  test(
    'Progress failure is retryable and successful retry clears it',
    () async {
      apiClient.homeReplies.addAll([
        () => Future<ApiResponse>.error(
          ApiBusinessException('Progress unavailable'),
        ),
        () async => _homeResponse(productId: 'recovered'),
      ]);

      await controller.refreshProgress();

      expect(controller.progressError.value, 'Progress unavailable');
      expect(errors, ['Progress unavailable']);
      expect(controller.isProgressRefreshing.value, isFalse);
      expect(apiClient.dialogScenes, isEmpty);

      await controller.refreshProgress();

      expect(controller.progressError.value, isNull);
      expect(controller.homeData.value?.loanOffer?.productId, 'recovered');
      expect(apiClient.dialogScenes, isEmpty);
    },
  );

  test(
    'Progress failure preserves the last successful home response',
    () async {
      final previous = HomeData.fromJson(Json(const <String, dynamic>{}));
      controller.homeData.value = previous;
      apiClient.homeReplies.add(
        () => Future<ApiResponse>.error(ApiBusinessException('Refresh failed')),
      );

      await controller.refreshProgress();

      expect(controller.homeData.value, same(previous));
      expect(controller.progressError.value, 'Refresh failed');
    },
  );

  test(
    'Progress card routes its server detail target with order context',
    () async {
      final targets = <String>[];
      final arguments = <Object?>[];
      final value = MainController(
        apiClient: apiClient,
        showError: errors.add,
        showNotice: notices.add,
        navigateProgressTarget: (target, args) async {
          targets.add(target);
          arguments.add(args);
        },
      );
      addTearDown(value.onClose);

      await value.handleProgressTap(
        const ProgressItem(
          productId: 'product-42',
          orderNumber: 'ORDER-42',
          detailRoute: 'ph://dali-cash/ios/Order',
          emblemize: ProgressEmblemize.activeLoan,
        ),
      );

      expect(targets, ['ph://dali-cash/ios/Order']);
      expect(arguments.single, {
        'highlands': 'product-42',
        'saggards': 'ORDER-42',
      });
    },
  );

  test(
    'Progress card falls back to product admission without a target',
    () async {
      final applied = <String>[];
      final value = MainController(
        apiClient: apiClient,
        showError: errors.add,
        showNotice: notices.add,
        onAuthenticatedProductApply: (productId) async =>
            applied.add(productId),
      );
      addTearDown(value.onClose);

      await value.handleProgressTap(
        const ProgressItem(productId: ' product-7 ', emblemize: 1),
      );

      expect(applied, ['product-7']);
    },
  );

  test(
    'Progress retry and change actions use their documented handlers',
    () async {
      final events = <String>[];
      final value = MainController(
        apiClient: apiClient,
        showError: errors.add,
        showNotice: notices.add,
        showLoading: () async => events.add('loading'),
        dismissLoading: () async => events.add('dismiss'),
        resolveProgressRetry: (orderNo) async {
          events.add('retry:$orderNo');
          return 'https://example.test/retry';
        },
        navigateProgressTarget: (target, _) async =>
            events.add('target:$target'),
        openProgressAccountChange:
            ({required productId, required orderNo}) async {
              events.add('change:$productId:$orderNo');
            },
      );
      addTearDown(value.onClose);
      const item = ProgressItem(
        productId: 'product-42',
        orderNumber: 'ORDER-42',
        emblemize: ProgressEmblemize.disbursementFailed,
      );

      await value.handleProgressActionTap(
        item,
        const ProgressAction(
          type: 'retry',
          visible: true,
          label: 'Retry',
          badge: '',
          route: '',
        ),
      );
      await value.handleProgressActionTap(
        item,
        const ProgressAction(
          type: 'change',
          visible: true,
          label: 'Change',
          badge: '',
          route: '',
        ),
      );

      expect(events, [
        'loading',
        'retry:ORDER-42',
        'dismiss',
        'target:https://example.test/retry',
        'loading',
        'change:product-42:ORDER-42',
        'dismiss',
      ]);
    },
  );

  test('unknown Progress action is ignored', () async {
    var called = false;
    final value = MainController(
      apiClient: apiClient,
      showError: errors.add,
      showNotice: notices.add,
      navigateProgressTarget: (_, _) async => called = true,
    );
    addTearDown(value.onClose);

    await value.handleProgressActionTap(
      const ProgressItem(productId: 'product-1', emblemize: 1),
      const ProgressAction(
        type: 'unsupported',
        visible: true,
        label: 'Unsupported',
        badge: '',
        route: 'https://example.test/ignored',
      ),
    );

    expect(called, isFalse);
  });

  test(
    'logged-out protected tab opens login and waits for a second tap',
    () async {
      final sessionStore = SessionStore.memory();
      apiClient.config.sessionStore = sessionStore;
      var loginCalls = 0;
      final value = MainController(
        apiClient: apiClient,
        showError: errors.add,
        showNotice: notices.add,
        navigateToLogin: () => loginCalls++,
      );
      addTearDown(value.onClose);

      await value.selectTab(2);

      expect(loginCalls, 1);
      expect(value.selectedIndex.value, 0);

      await sessionStore.saveSessionId('session-id');
      expect(value.selectedIndex.value, 0);

      await value.selectTab(2);
      expect(value.selectedIndex.value, 2);
      expect(loginCalls, 1);
    },
  );

  test(
    'logged-out product opens login and never auto-resumes after success',
    () async {
      final sessionStore = SessionStore.memory();
      apiClient.config.sessionStore = sessionStore;
      var loginCalls = 0;
      final appliedProductIds = <String>[];
      final value = MainController(
        apiClient: apiClient,
        showError: errors.add,
        showNotice: notices.add,
        navigateToLogin: () => loginCalls++,
        onAuthenticatedProductApply: (productId) async {
          appliedProductIds.add(productId);
        },
      );
      addTearDown(value.onClose);

      await value.applyProduct(' loan-42 ');

      expect(loginCalls, 1);
      expect(appliedProductIds, isEmpty);

      await sessionStore.saveSessionId('session-id');
      expect(appliedProductIds, isEmpty);

      await value.applyProduct(' loan-42 ');
      expect(appliedProductIds, ['loan-42']);
      expect(loginCalls, 1);
    },
  );

  test('overlapping product taps dispatch only one apply', () async {
    final sessionStore = SessionStore.memory();
    await sessionStore.saveSessionId('session-id');
    apiClient.config.sessionStore = sessionStore;
    final applyStarted = Completer<void>();
    final releaseApply = Completer<void>();
    final appliedProductIds = <String>[];
    final value = MainController(
      apiClient: apiClient,
      showError: errors.add,
      showNotice: notices.add,
      onAuthenticatedProductApply: (productId) async {
        appliedProductIds.add(productId);
        applyStarted.complete();
        await releaseApply.future;
      },
    );
    addTearDown(value.onClose);

    final first = value.applyProduct(' loan-42 ');
    await applyStarted.future;
    final second = value.applyProduct(' loan-42 ');
    releaseApply.complete();
    await Future.wait([first, second]);

    expect(appliedProductIds, ['loan-42']);
  });

  test(
    'default authenticated product action delegates to NavigationHelper',
    () async {
      Get.put<ApiClient>(apiClient);
      NavigationHelper.loadingPresenter = () async {};
      NavigationHelper.loadingDismissor = () async {};
      NavigationHelper.errorPresenter = (_) async {};
      NavigationHelper.certificationLocationRequester = () async {
        return CertificationLocationDecision.granted;
      };
      addTearDown(() {
        NavigationHelper.loadingPresenter =
            NavigationHelper.defaultLoadingPresenter;
        NavigationHelper.loadingDismissor =
            NavigationHelper.defaultLoadingDismissor;
        NavigationHelper.errorPresenter =
            NavigationHelper.defaultErrorPresenter;
        NavigationHelper.certificationLocationRequester =
            NavigationHelper.defaultCertificationLocationRequester;
      });

      await controller.applyProduct(' loan-42 ');

      expect(apiClient.appliedProducts, ['loan-42']);
      expect(apiClient.applySources, ['0']);
    },
  );

  test(
    'opening Mine refreshes the phone and requests its popup scene',
    () async {
      final sessionStore = SessionStore.memory();
      await sessionStore.saveSessionId('session-id');
      await sessionStore.savePhone('9123456789');
      apiClient.config.sessionStore = sessionStore;
      apiClient.dialogReplies.add((_) async => _dialogResponse(0));

      await controller.selectTab(2);

      expect(controller.phoneNumber.value, '9123456789');
      expect(apiClient.dialogScenes, [2]);
    },
  );

  test('Mine popup requests are deduplicated while one is pending', () async {
    final dialogCompleter = Completer<ApiResponse>();
    controller.selectedIndex.value = 2;
    apiClient.dialogReplies.add((_) => dialogCompleter.future);

    final first = controller.requestMinePopupIfVisible();
    final second = controller.requestMinePopupIfVisible();
    await pumpEventQueue();

    expect(apiClient.dialogScenes, [2]);

    dialogCompleter.complete(_dialogResponse(0));
    await Future.wait([first, second]);
  });

  test('re-entering Mine requests its popup again', () async {
    apiClient.dialogReplies.addAll([
      (_) async => _dialogResponse(0),
      (_) async => _dialogResponse(0),
    ]);

    await controller.selectTab(2);
    controller.selectedIndex.value = 0;
    await controller.selectTab(2);

    expect(apiClient.dialogScenes, [2, 2]);
  });

  test('Mine popup failure stays silent', () async {
    controller.selectedIndex.value = 2;
    apiClient.dialogReplies.add(
      (_) => Future<ApiResponse>.error(ApiBusinessException('Popup failed')),
    );

    await controller.requestMinePopupIfVisible();

    expect(apiClient.dialogScenes, [2]);
    expect(errors, isEmpty);
    expect(notices, isEmpty);
  });

  test('banner target is required while its id is optional', () async {
    final sessionStore = SessionStore.memory();
    await sessionStore.saveSessionId('session-id');
    apiClient.config.sessionStore = sessionStore;

    await controller.handleBannerTap(_banner(id: '   '));
    await controller.handleBannerTap(_banner(targetUrl: '   '));

    expect(apiClient.bannerClickIds, isEmpty);
    expect(bannerTargets, ['https://example.test/banner']);
  });

  test(
    'logged-out banner tap skips reporting but still opens target',
    () async {
      apiClient.config.sessionStore = SessionStore.memory();

      await controller.handleBannerTap(_banner());

      expect(apiClient.bannerClickIds, isEmpty);
      expect(bannerTargets, ['https://example.test/banner']);
    },
  );

  test('eligible banner tap reports and opens the trimmed target', () async {
    final sessionStore = SessionStore.memory();
    await sessionStore.saveSessionId('session-id');
    apiClient.config.sessionStore = sessionStore;

    await controller.handleBannerTap(
      _banner(id: ' banner-42 ', targetUrl: ' https://example.test/banner-42 '),
    );

    expect(apiClient.bannerClickIds, ['banner-42']);
    expect(bannerTargets, ['https://example.test/banner-42']);
    expect(errors, isEmpty);
    expect(notices, isEmpty);
  });

  test('banner reporting failure stays silent', () async {
    final sessionStore = SessionStore.memory();
    await sessionStore.saveSessionId('session-id');
    apiClient.config.sessionStore = sessionStore;
    apiClient.bannerClickError = ApiBusinessException('Tracking unavailable');

    await controller.handleBannerTap(_banner());

    expect(apiClient.bannerClickIds, ['banner-1']);
    expect(bannerTargets, ['https://example.test/banner']);
    expect(errors, isEmpty);
    expect(notices, isEmpty);
  });

  test('onReady dispatches the visible Home tab', () async {
    apiClient.homeReplies.add(() async => _homeResponse());
    apiClient.dialogReplies.add((_) async => _dialogResponse(0));

    controller.onReady();
    await pumpEventQueue();

    expect(apiClient.homeCalls, 1);
    expect(apiClient.dialogScenes, [1]);
  });

  test(
    'background resume refreshes the visible Home or Progress chain',
    () async {
      apiClient.homeReplies.addAll([
        () async => _homeResponse(),
        () async => _homeResponse(productId: 'progress-resume'),
      ]);
      apiClient.dialogReplies.add((_) async => _dialogResponse(0));

      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(apiClient.homeCalls, 1);

      controller.selectedIndex.value = 1;
      controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(apiClient.homeCalls, 2);
      expect(apiClient.dialogScenes, [1]);
      expect(
        controller.homeData.value?.loanOffer?.productId,
        'progress-resume',
      );
    },
  );

  test('background resume refreshes the visible Mine popup', () async {
    controller.selectedIndex.value = 2;
    apiClient.dialogReplies.add((_) async => _dialogResponse(0));

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(apiClient.homeCalls, 0);
    expect(apiClient.dialogScenes, [2]);
  });

  test('inactive resume refreshes only once per controller lifetime', () async {
    apiClient.homeReplies.add(() async => _homeResponse());
    apiClient.dialogReplies.add((_) async => _dialogResponse(0));

    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(apiClient.homeCalls, 1);

    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(apiClient.homeCalls, 1);
  });

  test('location permission prompt resume does not refresh Home', () async {
    controller.beginLocationPermissionRequest();
    controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    controller.endLocationPermissionRequest();
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(apiClient.homeCalls, 0);
    expect(apiClient.dialogScenes, isEmpty);
  });

  test(
    'resumed without an inactive or background transition is ignored',
    () async {
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(apiClient.homeCalls, 0);
      expect(apiClient.dialogScenes, isEmpty);
    },
  );

  test(
    'WidgetsBinding resume dispatches only while controller is observing',
    () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      controller.onInit();

      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(apiClient.homeCalls, 0);

      apiClient.homeReplies.add(() async => _homeResponse());
      apiClient.dialogReplies.add((_) async => _dialogResponse(0));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(apiClient.homeCalls, 1);

      controller.onClose();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(apiClient.homeCalls, 1);
    },
  );
}

class _ScriptedApiClient extends ApiClient {
  _ScriptedApiClient()
    : super(
        ApiConfig(commonParamsProvider: () async => const <String, dynamic>{}),
      );

  final List<Future<ApiResponse> Function()> homeReplies = [];
  final List<Future<ApiResponse> Function(int)> dialogReplies = [];
  final List<String> events = [];
  final List<int> dialogScenes = [];
  final List<String> bannerClickIds = [];
  final List<String> appliedProducts = [];
  final List<String> applySources = [];
  Object? bannerClickError;
  int homeCalls = 0;

  @override
  Future<ApiResponse> homePage() {
    homeCalls++;
    events.add('home-start');
    return homeReplies.removeAt(0)();
  }

  @override
  Future<ApiResponse> dialog({required int scene}) {
    dialogScenes.add(scene);
    events.add('dialog-start');
    return dialogReplies.removeAt(0)(scene);
  }

  @override
  Future<ApiResponse> bannerClickRecord({
    required String bannerConfigId,
  }) async {
    bannerClickIds.add(bannerConfigId);
    final error = bannerClickError;
    if (error != null) {
      throw error;
    }
    return _dialogResponse(0);
  }

  @override
  Future<ApiResponse> productApply({
    required String productId,
    String source = '0',
  }) async {
    appliedProducts.add(productId);
    applySources.add(source);
    return _dialogResponse(0);
  }
}

HomeBannerData _banner({
  String id = 'banner-1',
  String targetUrl = 'https://example.test/banner',
}) {
  return HomeBannerData(id: id, imageUrl: '', targetUrl: targetUrl);
}

ApiResponse _homeResponse({String productId = 'loan-1'}) {
  return ApiResponse(
    code: 0,
    message: '',
    states: Json({
      'clingiest': [
        {
          'sociologeses': 'QuininaSpeculation',
          'jambes': [
            {'underfeeding': productId},
          ],
        },
      ],
    }),
  );
}

ApiResponse _dialogResponse(int type) {
  return ApiResponse(
    code: 0,
    message: '',
    states: Json({'sociologeses': type}),
  );
}

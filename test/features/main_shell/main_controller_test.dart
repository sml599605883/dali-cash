import 'dart:async';

import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/core/network/api_response.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ScriptedApiClient apiClient;
  late List<String> errors;
  late List<String> notices;
  late MainController controller;

  setUp(() {
    Get.testMode = true;
    apiClient = _ScriptedApiClient();
    errors = <String>[];
    notices = <String>[];
    controller = MainController(
      apiClient: apiClient,
      showError: errors.add,
      showNotice: notices.add,
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
    expect(controller.isRefreshing, isTrue);

    dialogCompleter.complete(_dialogResponse(0));
    await request;
  });

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
    'home business failure preserves data, reports it, and skips popup',
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
      expect(apiClient.dialogScenes, isEmpty);
      expect(controller.isRefreshing, isFalse);
    },
  );

  test('unknown home failure uses the stable fallback message', () async {
    apiClient.homeReplies.add(
      () => Future<ApiResponse>.error(StateError('transport detail')),
    );

    await controller.requestHomeDataIfVisible();

    expect(errors, ['Request failed']);
    expect(apiClient.dialogScenes, isEmpty);
  });

  test('popup failure stays silent and retains loaded home data', () async {
    apiClient.homeReplies.add(() async => _homeResponse(productId: 'kept'));
    apiClient.dialogReplies.add(
      (_) => Future<ApiResponse>.error(ApiBusinessException('Popup failed')),
    );

    await controller.requestHomeDataIfVisible();

    expect(controller.homeData.value?.loanOffer?.productId, 'kept');
    expect(errors, isEmpty);
    expect(notices, isEmpty);
    expect(controller.isRefreshing, isFalse);
  });

  test(
    'overlapping refreshes share the lock and do not duplicate requests',
    () async {
      final homeCompleter = Completer<ApiResponse>();
      apiClient.homeReplies.add(() => homeCompleter.future);
      apiClient.dialogReplies.add((_) async => _dialogResponse(0));

      final first = controller.requestHomeDataIfVisible();
      final overlap = controller.requestHomeDataIfVisible();
      expect(controller.isRefreshing, isTrue);
      expect(apiClient.homeCalls, 1);

      await overlap;
      homeCompleter.complete(_homeResponse());
      await first;

      expect(apiClient.homeCalls, 1);
      expect(apiClient.dialogScenes, [1]);
      expect(controller.isRefreshing, isFalse);
    },
  );

  test(
    'switching to Home dispatches a refresh while other tabs do not',
    () async {
      controller.selectedIndex.value = 2;
      apiClient.homeReplies.add(() async => _homeResponse());
      apiClient.dialogReplies.add((_) async => _dialogResponse(0));

      await controller.selectTab(1);
      expect(apiClient.homeCalls, 0);
      await controller.selectTab(0);

      expect(controller.selectedIndex.value, 0);
      expect(apiClient.homeCalls, 1);
    },
  );

  test('selecting the current tab returns without dispatching', () async {
    await controller.selectTab(0);

    expect(apiClient.homeCalls, 0);
  });

  test('invalid banner fields do not report even when logged in', () async {
    final sessionStore = SessionStore.memory();
    await sessionStore.saveSessionId('session-id');
    apiClient.config.sessionStore = sessionStore;

    await controller.handleBannerTap(_banner(id: '   '));
    await controller.handleBannerTap(_banner(targetUrl: '   '));

    expect(apiClient.bannerClickIds, isEmpty);
  });

  test('logged-out banner tap does not report', () async {
    apiClient.config.sessionStore = SessionStore.memory();

    await controller.handleBannerTap(_banner());

    expect(apiClient.bannerClickIds, isEmpty);
  });

  test('eligible banner tap trims its id and reports once', () async {
    final sessionStore = SessionStore.memory();
    await sessionStore.saveSessionId('session-id');
    apiClient.config.sessionStore = sessionStore;

    await controller.handleBannerTap(_banner(id: ' banner-42 '));

    expect(apiClient.bannerClickIds, ['banner-42']);
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

  test('resume refreshes Home but remains idle on a non-Home tab', () async {
    apiClient.homeReplies.add(() async => _homeResponse());
    apiClient.dialogReplies.add((_) async => _dialogResponse(0));

    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(apiClient.homeCalls, 1);

    controller.selectedIndex.value = 1;
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(apiClient.homeCalls, 1);
  });

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

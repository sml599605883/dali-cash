import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../app/navigation/navigation_helper.dart';
import '../home/home_data.dart';

typedef HomeMessagePresenter = void Function(String message);
typedef LoginRouteNavigator = void Function();
typedef AuthenticatedProductApply = Future<void> Function(String productId);

class MainController extends GetxController with WidgetsBindingObserver {
  MainController({
    ApiClient? apiClient,
    required this.showError,
    required this.showNotice,
    LoginRouteNavigator? navigateToLogin,
    AuthenticatedProductApply? onAuthenticatedProductApply,
  }) : _apiClient = apiClient,
       navigateToLogin = navigateToLogin ?? _defaultNavigateToLogin,
       onAuthenticatedProductApply =
           onAuthenticatedProductApply ?? _defaultAuthenticatedProductApply;

  ApiClient? _apiClient;
  final HomeMessagePresenter showError;
  final HomeMessagePresenter showNotice;
  final LoginRouteNavigator navigateToLogin;
  final AuthenticatedProductApply onAuthenticatedProductApply;

  final selectedIndex = 0.obs;
  final homeData = Rxn<HomeData>();
  final phoneNumber = ''.obs;

  bool _homeRefreshRequesting = false;
  bool _productApplyRequesting = false;
  bool _isReady = false;

  bool get isRefreshing => _homeRefreshRequesting;
  bool get hasApiClient => _apiClient != null;
  ApiClient get apiClient =>
      _apiClient ?? (throw StateError('Network client is not ready'));

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    _isReady = true;
    if (hasApiClient) {
      unawaited(requestHomeDataIfVisible());
    }
  }

  void onNetworkReady(ApiClient client) {
    _apiClient = client;
    if (_isReady) {
      unawaited(requestHomeDataIfVisible());
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(requestHomeDataIfVisible());
    }
  }

  Future<void> selectTab(int index) async {
    if (selectedIndex.value == index) {
      return;
    }
    if (index != 0 && !await _ensureLoggedIn()) {
      return;
    }
    selectedIndex.value = index;
    if (index == 2) {
      await refreshStoredPhone();
    }
    await requestHomeDataIfVisible();
  }

  Future<void> refreshStoredPhone() async {
    final client = _apiClient;
    if (client == null) {
      return;
    }
    phoneNumber.value = await client.config.sessionStore.phone();
  }

  Future<void> applyProduct(String productId) async {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty || _productApplyRequesting) {
      return;
    }
    _productApplyRequesting = true;
    try {
      if (!await _ensureLoggedIn()) {
        return;
      }
      await onAuthenticatedProductApply(normalizedProductId);
    } finally {
      _productApplyRequesting = false;
    }
  }

  Future<void> handleBannerTap(HomeBannerData banner) async {
    final client = _apiClient;
    if (client == null) {
      return;
    }
    final bannerId = banner.id.trim();
    final targetUrl = banner.targetUrl.trim();
    if (bannerId.isEmpty || targetUrl.isEmpty) {
      return;
    }

    final sessionId = await client.config.sessionStore.sessionId();
    if (sessionId.trim().isEmpty) {
      return;
    }

    try {
      await client.bannerClickRecord(bannerConfigId: bannerId);
    } catch (_) {
      // Analytics failures must not interrupt Banner interaction.
    }
  }

  Future<void> requestHomeDataIfVisible() async {
    if (selectedIndex.value != 0) {
      return;
    }
    await refreshHome();
  }

  Future<bool> _ensureLoggedIn() async {
    final client = _apiClient;
    if (client == null) {
      return false;
    }
    final sessionId = await client.config.sessionStore.sessionId();
    if (sessionId.trim().isNotEmpty) {
      return true;
    }
    navigateToLogin();
    return false;
  }

  Future<void> refreshHome() async {
    final client = _apiClient;
    if (_homeRefreshRequesting || client == null) {
      return;
    }
    _homeRefreshRequesting = true;
    try {
      try {
        final response = await client.homePage();
        homeData.value = HomeData.fromJson(response.states);
      } catch (error) {
        showError(
          error is ApiBusinessException ? error.message : 'Request failed',
        );
        return;
      }

      try {
        final response = await client.dialog(scene: 1);
        final type = response.states['sociologeses'].intValue;
        if (type == 1 || type == 2 || type == 3) {
          showNotice('New information available');
        }
      } catch (_) {
        // Popup failures must not invalidate successfully loaded home content.
      }
    } finally {
      _homeRefreshRequesting = false;
    }
  }
}

void _defaultNavigateToLogin() {
  NavigationHelper.toLogin<void>();
}

Future<void> _defaultAuthenticatedProductApply(String productId) async {
  await NavigationHelper.applyProduct(productId);
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/api_response.dart';
import '../../app/navigation/navigation_helper.dart';
import '../../app/routes/app_routes.dart';
import '../home/home_data.dart';
import 'home_popup.dart';
import 'home_popup_data.dart';
import '../progress/progress_item.dart';

typedef HomeMessagePresenter = void Function(String message);
typedef HomeAsyncAction = Future<void> Function();
typedef LoginRouteNavigator = void Function();
typedef AuthenticatedProductApply = Future<void> Function(String productId);
typedef ProgressTargetNavigator =
    Future<void> Function(String target, Object? arguments);
typedef BannerTargetNavigator = Future<void> Function(String target);
typedef ProgressRetryResolver = Future<String> Function(String orderNo);
typedef ProgressAccountResolver =
    Future<void> Function({required String productId, required String orderNo});

class MainController extends GetxController with WidgetsBindingObserver {
  MainController({
    ApiClient? apiClient,
    required this.showError,
    required this.showNotice,
    HomeAsyncAction? showLoading,
    HomeAsyncAction? dismissLoading,
    LoginRouteNavigator? navigateToLogin,
    AuthenticatedProductApply? onAuthenticatedProductApply,
    BannerTargetNavigator? navigateBannerTarget,
    ProgressTargetNavigator? navigateProgressTarget,
    ProgressRetryResolver? resolveProgressRetry,
    ProgressAccountResolver? openProgressAccountChange,
  }) : _apiClient = apiClient,
       navigateToLogin = navigateToLogin ?? _defaultNavigateToLogin,
       showLoading = showLoading ?? _defaultAsyncAction,
       dismissLoading = dismissLoading ?? _defaultAsyncAction,
       onAuthenticatedProductApply =
           onAuthenticatedProductApply ?? _defaultAuthenticatedProductApply,
       navigateBannerTarget =
           navigateBannerTarget ?? NavigationHelper.navigateRawTarget,
       navigateProgressTarget =
           navigateProgressTarget ?? _defaultProgressTargetNavigator,
       resolveProgressRetry = resolveProgressRetry ?? _defaultProgressRetry,
       openProgressAccountChange =
           openProgressAccountChange ?? _defaultProgressAccountChange;

  ApiClient? _apiClient;
  final HomeMessagePresenter showError;
  final HomeMessagePresenter showNotice;
  final HomeAsyncAction showLoading;
  final HomeAsyncAction dismissLoading;
  final LoginRouteNavigator navigateToLogin;
  final AuthenticatedProductApply onAuthenticatedProductApply;
  final BannerTargetNavigator navigateBannerTarget;
  final ProgressTargetNavigator navigateProgressTarget;
  final ProgressRetryResolver resolveProgressRetry;
  final ProgressAccountResolver openProgressAccountChange;

  final selectedIndex = 0.obs;
  final homeData = Rxn<HomeData>();
  final phoneNumber = ''.obs;
  final progressError = RxnString();
  final isProgressRefreshing = false.obs;

  bool _homeRefreshRequesting = false;
  bool _minePopupRequesting = false;
  bool _productApplyRequesting = false;
  bool _progressActionRequesting = false;
  bool _isReady = false;
  bool _wasInactive = false;
  bool _wasInBackground = false;
  bool _inactiveResumeRefreshConsumed = false;

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
      unawaited(_requestVisibleTabData());
    }
  }

  void onNetworkReady(ApiClient client) {
    _apiClient = client;
    if (_isReady) {
      unawaited(_requestVisibleTabData());
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _wasInactive = true;
      return;
    }
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _wasInBackground = true;
      return;
    }
    if (state != AppLifecycleState.resumed) {
      return;
    }

    final resumedFromBackground = _wasInBackground;
    final firstInactiveResume = _wasInactive && !_inactiveResumeRefreshConsumed;
    _wasInactive = false;
    _wasInBackground = false;
    if (!resumedFromBackground && !firstInactiveResume) {
      return;
    }
    if (!resumedFromBackground) {
      _inactiveResumeRefreshConsumed = true;
    }
    unawaited(_requestVisibleTabData());
  }

  Future<void> selectTab(int index) async {
    if (selectedIndex.value == index) {
      return;
    }
    if (index != 0 && !await _ensureLoggedIn()) {
      return;
    }
    selectedIndex.value = index;
    await _requestVisibleTabData();
  }

  void returnToHomeTab() {
    selectedIndex.value = 0;
    unawaited(_requestVisibleTabData());
  }

  void onRouteChanged() {
    unawaited(_requestVisibleTabData());
  }

  Future<void> _requestVisibleTabData() async {
    if (_isHomeVisible) {
      await requestHomeDataIfVisible();
    } else if (_isProgressVisible) {
      await refreshProgress();
    } else if (_isMineVisible) {
      await refreshStoredPhone();
      await requestMinePopupIfVisible();
    }
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

  Future<void> handleProgressTap(ProgressItem item) async {
    if (_progressActionRequesting) {
      return;
    }
    final productId = item.productId.trim();
    final orderNo = item.orderNumber.trim();
    final target = item.detailRoute.trim();
    if (target.isEmpty && productId.isEmpty) {
      return;
    }

    _progressActionRequesting = true;
    try {
      if (target.isNotEmpty) {
        final arguments = <String, dynamic>{
          if (productId.isNotEmpty) 'highlands': productId,
          if (orderNo.isNotEmpty) 'saggards': orderNo,
        };
        await navigateProgressTarget(
          target,
          arguments.isEmpty ? null : arguments,
        );
      } else {
        await applyProduct(productId);
      }
    } finally {
      _progressActionRequesting = false;
    }
  }

  Future<void> handleProgressActionTap(
    ProgressItem item,
    ProgressAction action,
  ) async {
    final type = action.type.trim().toLowerCase();
    if (_progressActionRequesting) {
      return;
    }
    switch (type) {
      case 'detail':
      case 'fallback':
      case 'repay':
        await handleProgressTap(item);
        return;
      case 'retry':
        await _retryProgress(item);
        return;
      case 'change':
        await _changeProgressAccount(item);
        return;
      default:
        return;
    }
  }

  Future<void> _retryProgress(ProgressItem item) async {
    final orderNo = item.orderNumber.trim();
    if (orderNo.isEmpty) {
      return;
    }
    _progressActionRequesting = true;
    var loadingVisible = false;
    try {
      await showLoading();
      loadingVisible = true;
      final target = (await resolveProgressRetry(orderNo)).trim();
      if (target.isEmpty) {
        throw ApiBusinessException('Missing retry result url');
      }
      await dismissLoading();
      loadingVisible = false;
      await navigateProgressTarget(target, null);
    } catch (error) {
      if (loadingVisible) {
        await dismissLoading();
      }
      showError(_resolvedError(error));
    } finally {
      _progressActionRequesting = false;
    }
  }

  Future<void> _changeProgressAccount(ProgressItem item) async {
    final productId = item.productId.trim();
    final orderNo = item.orderNumber.trim();
    if (productId.isEmpty || orderNo.isEmpty) {
      return;
    }
    _progressActionRequesting = true;
    var loadingVisible = false;
    try {
      await showLoading();
      loadingVisible = true;
      await openProgressAccountChange(productId: productId, orderNo: orderNo);
      await dismissLoading();
      loadingVisible = false;
    } catch (error) {
      if (loadingVisible) {
        await dismissLoading();
      }
      showError(_resolvedError(error));
    } finally {
      _progressActionRequesting = false;
    }
  }

  Future<void> handleBannerTap(HomeBannerData banner) async {
    final targetUrl = banner.targetUrl.trim();
    if (targetUrl.isEmpty) {
      return;
    }

    final client = _apiClient;
    final bannerId = banner.id.trim();
    try {
      if (client != null && bannerId.isNotEmpty) {
        final sessionId = await client.config.sessionStore.sessionId();
        if (sessionId.trim().isNotEmpty) {
          await client.bannerClickRecord(bannerConfigId: bannerId);
        }
      }
    } catch (_) {
      // Analytics failures must not interrupt Banner interaction.
    }
    await navigateBannerTarget(targetUrl);
  }

  Future<void> requestHomeDataIfVisible() async {
    if (!_isHomeVisible) {
      return;
    }
    await _requestHomeData(showPopup: true, presentLoading: true);
  }

  bool get _isHomeVisible => selectedIndex.value == 0 && _isMainRoute;

  bool get _isProgressVisible => selectedIndex.value == 1 && _isMainRoute;

  bool get _isMineVisible => selectedIndex.value == 2 && _isMainRoute;

  bool get _isMainRoute {
    final route = Get.currentRoute;
    return route.isEmpty || route == AppRoutes.home;
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
    await _requestHomeData(showPopup: true, presentLoading: true);
  }

  Future<void> refreshProgress() async {
    final client = _apiClient;
    if (_homeRefreshRequesting || client == null) {
      return;
    }
    isProgressRefreshing.value = true;
    try {
      await _requestHomeData(showPopup: false, reportProgressError: true);
    } finally {
      isProgressRefreshing.value = false;
    }
  }

  Future<bool> _requestHomeData({
    required bool showPopup,
    bool presentLoading = false,
    bool reportProgressError = false,
  }) async {
    final client = _apiClient;
    if (_homeRefreshRequesting || client == null) {
      return false;
    }
    _homeRefreshRequesting = true;
    var homeLoadingVisible = false;
    if (presentLoading) {
      unawaited(showLoading());
      homeLoadingVisible = true;
    }
    final homeRequest = client.homePage();
    Future<ApiResponse>? popupRequest;
    if (showPopup) {
      try {
        popupRequest = client.dialog(scene: 1);
      } catch (_) {
        popupRequest = null;
      }
    }
    if (popupRequest != null) {
      unawaited(_handlePopup(popupRequest));
    }
    try {
      try {
        final response = await homeRequest;
        homeData.value = HomeData.fromJson(response.states);
        if (homeLoadingVisible) {
          await dismissLoading();
          homeLoadingVisible = false;
        }
        if (reportProgressError) {
          progressError.value = null;
        }
      } catch (error) {
        homeLoadingVisible = false;
        if (reportProgressError) {
          progressError.value = _resolvedError(error);
        }
        showError(_resolvedError(error));
        return false;
      }

      return true;
    } finally {
      if (homeLoadingVisible) {
        await dismissLoading();
      }
      _homeRefreshRequesting = false;
    }
  }

  Future<void> requestMinePopupIfVisible() async {
    final client = _apiClient;
    if (!_isMineVisible || _minePopupRequesting || client == null) {
      return;
    }
    _minePopupRequesting = true;
    try {
      Future<ApiResponse>? popupRequest;
      try {
        popupRequest = client.dialog(scene: 2);
      } catch (_) {
        popupRequest = null;
      }
      if (popupRequest != null) {
        await _handlePopup(popupRequest);
      }
    } finally {
      _minePopupRequesting = false;
    }
  }

  Future<void> _handlePopup(Future<ApiResponse> request) async {
    try {
      final response = await request;
      final popup = HomePopupData.fromResponse(response.states);
      if (await HomePopup.show(popup)) {
        return;
      }
      if (popup.type == HomePopupType.appUpgrade ||
          popup.type == HomePopupType.membershipUpgrade ||
          popup.type == HomePopupType.marketing) {
        showNotice('New information available');
      }
    } catch (_) {
      // Popup failures must not invalidate the visible page content.
    }
  }

  String _resolvedError(Object error) {
    return error is ApiBusinessException ? error.message : 'Request failed';
  }
}

void _defaultNavigateToLogin() {
  NavigationHelper.toLogin<void>();
}

Future<void> _defaultAuthenticatedProductApply(String productId) async {
  await NavigationHelper.applyProduct(productId);
}

Future<void> _defaultProgressTargetNavigator(String target, Object? arguments) {
  return NavigationHelper.navigateRawTarget(target, arguments: arguments);
}

Future<String> _defaultProgressRetry(String orderNo) async {
  final response = await Get.find<ApiClient>().retryOriginalAccount(
    orderNo: orderNo,
  );
  return response.ensureSuccess().states['misericorde'].stringValue;
}

Future<void> _defaultProgressAccountChange({
  required String productId,
  required String orderNo,
}) async {
  final response = await Get.find<ApiClient>().userAccountList(
    productId: productId,
  );
  if (response.ensureSuccess().states['clingiest'].listValue.isNotEmpty) {
    NavigationHelper.toAccountList<void>(
      productId: productId,
      orderNo: orderNo,
    );
  } else {
    NavigationHelper.toBindCard<void>(
      productId: productId,
      orderNo: orderNo,
      isAccountChange: true,
    );
  }
}

Future<void> _defaultAsyncAction() async {}

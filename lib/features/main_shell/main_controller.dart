import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../home/home_data.dart';

typedef HomeMessagePresenter = void Function(String message);

class MainController extends GetxController with WidgetsBindingObserver {
  MainController({
    required this.apiClient,
    required this.showError,
    required this.showNotice,
  });

  final ApiClient apiClient;
  final HomeMessagePresenter showError;
  final HomeMessagePresenter showNotice;

  final selectedIndex = 0.obs;
  final homeData = Rxn<HomeData>();

  bool _homeRefreshRequesting = false;

  bool get isRefreshing => _homeRefreshRequesting;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(requestHomeDataIfVisible());
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
    selectedIndex.value = index;
    await requestHomeDataIfVisible();
  }

  Future<void> handleBannerTap(HomeBannerData banner) async {
    final bannerId = banner.id.trim();
    final targetUrl = banner.targetUrl.trim();
    if (bannerId.isEmpty || targetUrl.isEmpty) {
      return;
    }

    final sessionId = await apiClient.config.sessionStore.sessionId();
    if (sessionId.trim().isEmpty) {
      return;
    }

    try {
      await apiClient.bannerClickRecord(bannerConfigId: bannerId);
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

  Future<void> refreshHome() async {
    if (_homeRefreshRequesting) {
      return;
    }
    _homeRefreshRequesting = true;
    try {
      try {
        final response = await apiClient.homePage();
        homeData.value = HomeData.fromJson(response.states);
      } catch (error) {
        showError(
          error is ApiBusinessException ? error.message : 'Request failed',
        );
        return;
      }

      try {
        final response = await apiClient.dialog(scene: 1);
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

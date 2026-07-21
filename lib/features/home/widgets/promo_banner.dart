import 'dart:async';

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:flutter/material.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key, this.banners, required this.onTap});

  final List<HomeBannerData>? banners;
  final ValueChanged<HomeBannerData> onTap;

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  static const _rotationInterval = Duration(seconds: 3);
  static const _animationDuration = Duration(milliseconds: 300);
  static const _virtualPageCenter = 10000;

  PageController? _pageController;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _configureCarousel();
  }

  @override
  void didUpdateWidget(covariant PromoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners?.length != widget.banners?.length) {
      _configureCarousel();
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void _configureCarousel() {
    _rotationTimer?.cancel();
    _pageController?.dispose();
    _rotationTimer = null;
    _pageController = null;

    final itemCount = widget.banners?.length ?? 0;
    if (itemCount < 2) {
      return;
    }

    final initialPage = _virtualPageCenter - (_virtualPageCenter % itemCount);
    final controller = PageController(
      initialPage: initialPage,
      keepPage: false,
    );
    _pageController = controller;
    _rotationTimer = Timer.periodic(_rotationInterval, (_) {
      if (!mounted || !controller.hasClients) {
        return;
      }
      final currentPage = controller.page?.round() ?? controller.initialPage;
      unawaited(
        controller.animateToPage(
          currentPage + 1,
          duration: _animationDuration,
          curve: Curves.easeOut,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners == null || banners.isEmpty) {
      return _fallbackBanner(key: const Key('home-promo-banner-asset'));
    }
    if (banners.length == 1) {
      return _staticBanner(banners.single);
    }

    return SizedBox(
      key: const Key('home-promo-banner-network'),
      width: ScreenAdapter.width(343),
      height: ScreenAdapter.height(126),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
        child: PageView.builder(
          key: ValueKey('home-promo-banner-page-view-${banners.length}'),
          controller: _pageController,
          itemBuilder: (context, index) {
            return _bannerItem(banners[index % banners.length]);
          },
        ),
      ),
    );
  }

  Widget _staticBanner(HomeBannerData banner) {
    return ClipRRect(
      key: const Key('home-promo-banner-network'),
      borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
      child: _bannerItem(banner),
    );
  }

  Widget _bannerItem(HomeBannerData banner) {
    final imageUrl = banner.imageUrl.trim();
    return GestureDetector(
      key: Key('home-promo-banner-${banner.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(banner),
      child: imageUrl.isEmpty
          ? _fallbackImage()
          : Image.network(
              imageUrl,
              width: ScreenAdapter.width(343),
              height: ScreenAdapter.height(126),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackImage(),
            ),
    );
  }

  Widget _fallbackBanner({required Key key}) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
      child: _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Image.asset(
      AppAssets.homePromoBanner,
      width: ScreenAdapter.width(343),
      height: ScreenAdapter.height(126),
      fit: BoxFit.cover,
    );
  }
}

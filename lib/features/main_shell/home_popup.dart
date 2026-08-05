import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/navigation/navigation_helper.dart';
import '../../app/resources/app_assets.dart';
import '../../app/theme/app_colors.dart';
import 'home_popup_data.dart';

class HomePopup {
  HomePopup._();

  static bool _showing = false;

  static const upgradeButtonKey = Key('homePopupUpgradeButton');
  static const marketingImageKey = Key('homePopupMarketingImage');
  static const marketingCloseKey = Key('homePopupMarketingClose');

  static Future<bool> show(HomePopupData data) async {
    if (!data.shouldShow || Get.context == null || _showing) return false;
    _showing = true;
    try {
      await Get.dialog<void>(
        data.type == HomePopupType.appUpgrade
            ? _UpgradePopup(data: data)
            : _MarketingPopup(data: data),
        barrierColor: AppColors.dialogBarrier,
        barrierDismissible: true,
        transitionDuration: Duration.zero,
      );
      return true;
    } finally {
      _showing = false;
    }
  }
}

class _UpgradePopup extends StatelessWidget {
  const _UpgradePopup({required this.data});
  final HomePopupData data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 343,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1029 / 600,
                child: Image.asset(
                  AppAssets.homePopupUpgradeBackground,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Column(
                  children: [
                    if (data.displayVersion.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.alert,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          data.displayVersion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (data.message.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        data.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          height: 19 / 16,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: HomePopup.upgradeButtonKey,
                        onPressed: () async {
                          Get.back<void>();
                          final uri = Uri.tryParse(data.targetUrl);
                          if (uri != null && uri.hasScheme) {
                            await NavigationHelper.openExternalUri(uri);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Update Now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketingPopup extends StatelessWidget {
  const _MarketingPopup({required this.data});
  final HomePopupData data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 343, maxHeight: 620),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              GestureDetector(
                key: HomePopup.marketingImageKey,
                onTap: () {
                  Get.back<void>();
                  if (data.targetUrl.isNotEmpty) {
                    NavigationHelper.toWebView<void>(url: data.targetUrl);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data.imageUrl,
                    fit: BoxFit.fitWidth,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    key: HomePopup.marketingCloseKey,
                    onTap: () => Get.back<void>(),
                    child: Image.asset(
                      AppAssets.homePopupMarketingClose,
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

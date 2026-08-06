import 'dart:async';

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/home/recommendation/recommendation_section.dart';
import 'package:dali_cash/features/home/widgets/home_header.dart';
import 'package:dali_cash/features/home/widgets/credit_activation_progress.dart';
import 'package:dali_cash/features/home/widgets/loan_offer_card.dart';
import 'package:dali_cash/features/home/widgets/promo_banner.dart';
import 'package:dali_cash/features/main_shell/main_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends GetView<MainController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: ScreenAdapter.height(253),
            child: Image.asset(
              AppAssets.homeHeaderBackground,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Obx(() {
                  final delivered = controller.homeData.value;
                  final loanOffer = delivered?.loanOffer;
                  final banners = delivered?.banners;
                  final recommendations = delivered?.recommendations;
                  final showLoan = delivered == null || loanOffer != null;
                  final showBanner = delivered == null || banners!.isNotEmpty;
                  final showRecommendations =
                      delivered == null || recommendations!.isNotEmpty;

                  return RefreshIndicator(
                    onRefresh: controller.refreshHome,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            ScreenAdapter.width(16),
                            ScreenAdapter.height(8),
                            ScreenAdapter.width(16),
                            ScreenAdapter.height(24),
                          ),
                          child: Column(
                            children: [
                              const HomeHeader(),
                              if (showLoan) ...[
                                SizedBox(height: ScreenAdapter.height(16)),
                                LoanOfferCard(
                                  offer: loanOffer,
                                  onTap: loanOffer == null
                                      ? null
                                      : () => unawaited(
                                          controller.applyProduct(
                                            loanOffer.productId,
                                          ),
                                        ),
                                ),
                              ],
                              if (delivered?.showCreditActivationProgress ==
                                  true) ...[
                                SizedBox(height: ScreenAdapter.height(16)),
                                const CreditActivationProgress(),
                              ],
                              if (showBanner) ...[
                                SizedBox(height: ScreenAdapter.height(16)),
                                PromoBanner(
                                  banners: banners,
                                  onTap: (banner) => unawaited(
                                    controller.handleBannerTap(banner),
                                  ),
                                ),
                              ],
                              if (showRecommendations) ...[
                                SizedBox(height: ScreenAdapter.height(16)),
                                RecommendationSection(
                                  items:
                                      recommendations ??
                                      defaultHomeRecommendations,
                                  onApply: (item) => unawaited(
                                    controller.applyProduct(item.productId),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

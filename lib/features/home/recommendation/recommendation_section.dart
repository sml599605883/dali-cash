import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:flutter/material.dart';

class RecommendationSection extends StatelessWidget {
  const RecommendationSection({
    super.key,
    this.items = defaultHomeRecommendations,
    this.onApply,
  });

  final List<HomeRecommendationData> items;
  final ValueChanged<HomeRecommendationData>? onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _RecommendationHeader(),
        SizedBox(height: ScreenAdapter.height(12)),
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) SizedBox(height: ScreenAdapter.height(8)),
          _RecommendationCard(item: items[index], onApply: onApply),
        ],
      ],
    );
  }
}

class _RecommendationHeader extends StatelessWidget {
  const _RecommendationHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(20),
      child: Row(
        children: [
          SizedBox(
            width: ScreenAdapter.width(14),
            height: ScreenAdapter.height(14),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.surface,
              size: ScreenAdapter.font(14),
            ),
          ),
          SizedBox(width: ScreenAdapter.width(8)),
          Text(
            'Recommendation',
            style: TextStyle(
              color: AppColors.surface,
              fontSize: ScreenAdapter.font(16),
              fontWeight: FontWeight.w700,
              height: 20 / 16,
            ),
          ),
          const Spacer(),
          Text(
            'More',
            style: TextStyle(
              color: AppColors.surface,
              fontSize: ScreenAdapter.font(14),
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          SizedBox(width: ScreenAdapter.width(4)),
          Image.asset(
            AppAssets.chevronRight,
            color: AppColors.surface,
            width: ScreenAdapter.font(12),
            height: ScreenAdapter.height(12),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onApply});

  final HomeRecommendationData item;
  final ValueChanged<HomeRecommendationData>? onApply;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: item.productId.trim().isEmpty || item.upscales == -1
            ? null
            : _handleTap,
        child: AspectRatio(
          aspectRatio: 343 / 110,
          child: Container(
            key: Key('home-recommendation-card-${item.upscales}'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.recommendationCard,
              borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  left: ScreenAdapter.width(4),
                  top: ScreenAdapter.height(4),
                  right: ScreenAdapter.width(4),
                  bottom: ScreenAdapter.height(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        ScreenAdapter.width(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: ScreenAdapter.width(16),
                  top: ScreenAdapter.height(12),
                  width: ScreenAdapter.width(243),
                  height: ScreenAdapter.height(86),
                  child: IgnorePointer(
                    child: _RecommendationDetails(item: item),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  width: ScreenAdapter.width(107),
                  height: ScreenAdapter.height(110),
                  child: DecoratedBox(
                    key: Key(
                      'home-recommendation-apply-background-${item.upscales}',
                    ),
                    decoration: _applyDecoration(item.upscales),
                    child: Center(
                      child: Text(
                        'Apply\nNow',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: ScreenAdapter.font(18),
                          fontWeight: FontWeight.w700,
                          height: 30 / 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() {
    final callback = onApply;
    if (callback != null) {
      callback(item);
      return;
    }
    debugPrint('[HomePage] Recommendation card tapped: ${item.productName}');
  }

  BoxDecoration _applyDecoration(int upscales) {
    return switch (upscales) {
      1 => const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.recommendationApplyHighlight),
          fit: BoxFit.fill,
        ),
      ),
      -1 => const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.recommendationApplyDisabled),
          fit: BoxFit.fill,
        ),
      ),
      _ => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.recommendationNormalStart,
            AppColors.recommendationNormalEnd,
          ],
        ),
      ),
    };
  }
}

class _RecommendationDetails extends StatelessWidget {
  const _RecommendationDetails({required this.item});

  final HomeRecommendationData item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: ScreenAdapter.height(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: ScreenAdapter.height(2)),
                child: _ProductLogo(imageUrl: item.productLogo),
              ),
              SizedBox(width: ScreenAdapter.width(4)),
              Expanded(
                child: SizedBox(
                  height: ScreenAdapter.height(16),
                  child: Text(
                    item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: ScreenAdapter.font(10),
                      fontWeight: FontWeight.w400,
                      height: 16 / 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ScreenAdapter.height(48),
          child: Row(
            children: [
              SizedBox(
                width: ScreenAdapter.width(91),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: ScreenAdapter.height(30),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatHomeAmount(item.amount),
                          style: TextStyle(
                            color: AppColors.recommendationAmount,
                            fontSize: ScreenAdapter.font(24),
                            fontWeight: FontWeight.w700,
                            height: 29 / 24,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ScreenAdapter.height(4)),
                    SizedBox(
                      height: ScreenAdapter.height(14),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.amountCaption,
                          maxLines: 1,
                          style: TextStyle(
                            color: AppColors.recommendationCaption,
                            fontSize: ScreenAdapter.font(12),
                            fontWeight: FontWeight.w400,
                            height: 14 / 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ScreenAdapter.width(8)),
              SizedBox(
                width: ScreenAdapter.width(144),
                height: ScreenAdapter.height(48),
                child: Container(
                  key: const Key('home-recommendation-terms-panel'),
                  padding: EdgeInsets.fromLTRB(
                    ScreenAdapter.width(8),
                    ScreenAdapter.height(8),
                    ScreenAdapter.width(20),
                    ScreenAdapter.height(8),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RecommendationTerm(
                        label: 'Interest rate',
                        value: item.interestRate,
                      ),
                      SizedBox(height: ScreenAdapter.height(8)),
                      _RecommendationTerm(
                        label: 'Loan terms',
                        value: item.loanTerm,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ScreenAdapter.height(8)),
        SizedBox(
          height: ScreenAdapter.height(10),
          child: Padding(
            padding: EdgeInsets.only(left: ScreenAdapter.width(2)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                item.footer,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.alert,
                  fontSize: ScreenAdapter.font(8),
                  fontWeight: FontWeight.w400,
                  height: 10 / 8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationTerm extends StatelessWidget {
  const _RecommendationTerm({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: ScreenAdapter.font(10),
                fontWeight: FontWeight.w400,
                height: 12 / 10,
              ),
            ),
          ),
          SizedBox(width: ScreenAdapter.width(4)),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: ScreenAdapter.font(10),
                  fontWeight: FontWeight.w400,
                  height: 12 / 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductLogo extends StatelessWidget {
  const _ProductLogo({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(ScreenAdapter.width(2)),
      ),
      child: Text(
        'Cash',
        style: TextStyle(
          color: AppColors.surface,
          fontSize: ScreenAdapter.font(4),
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return SizedBox(
      key: const Key('home-recommendation-product-logo'),
      width: ScreenAdapter.width(12),
      height: ScreenAdapter.height(12),
      child: imageUrl.trim().isEmpty
          ? fallback
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (context, child, progress) {
                return progress == null ? child : fallback;
              },
            ),
    );
  }
}

const defaultHomeRecommendations = <HomeRecommendationData>[
  HomeRecommendationData(
    productId: 'default-home-recommendation',
    productName: 'PG Finance',
    productLogo: '',
    amount: '₱60,000',
    amountCaption: 'Available up to',
    interestRate: '≤ 0.5% Day',
    loanTerm: '≤ 0.5% Day',
    footer: 'Low interest rates / Ages 17 years and over can borrow',
    upscales: 1,
  ),
];

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:flutter/material.dart';

class LoanOfferCard extends StatelessWidget {
  const LoanOfferCard({super.key, this.offer, this.onTap});

  final HomeLoanOfferData? offer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final headline = offer == null
        ? 'Confirm your loan， Cash hits fast.'
        : offer!.loanProcessText;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? () => debugPrint('[HomePage] Loan offer card tapped'),
        child: AspectRatio(
          aspectRatio: 343 / 355,
          child: Container(
            key: const Key('home-loan-offer-card'),
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.homeLoanCardBackground),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: ScreenAdapter.height(24)),
                Padding(
                  padding: EdgeInsets.only(left: ScreenAdapter.width(64)),
                  child: SizedBox(
                    height: ScreenAdapter.height(20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.alert,
                          fontSize: ScreenAdapter.font(14),
                          fontWeight: FontWeight.w400,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenAdapter.height(20)),
                Padding(
                  padding: EdgeInsets.only(left: ScreenAdapter.width(8)),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ProductName(offer: offer),
                  ),
                ),
                SizedBox(height: ScreenAdapter.height(8)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenAdapter.width(16),
                  ),
                  child: SizedBox(
                    height: ScreenAdapter.height(104),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.amountPanel,
                        borderRadius: BorderRadius.circular(
                          ScreenAdapter.width(11),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: ScreenAdapter.height(43),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatHomeAmount(offer?.amount ?? '₱60,000'),
                                maxLines: 1,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: ScreenAdapter.font(36),
                                  fontWeight: FontWeight.w700,
                                  height: 43 / 36,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: ScreenAdapter.height(8)),
                          SizedBox(
                            width: double.infinity,
                            height: ScreenAdapter.height(17),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                offer?.amountCaption ?? 'Available up to',
                                maxLines: 1,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: ScreenAdapter.font(12),
                                  fontWeight: FontWeight.w400,
                                  height: 17 / 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenAdapter.height(16)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenAdapter.width(24),
                  ),
                  child: SizedBox(
                    height: ScreenAdapter.height(48),
                    child: _LoanTerms(offer: offer),
                  ),
                ),
                SizedBox(height: ScreenAdapter.height(16)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenAdapter.width(16),
                  ),
                  child: SizedBox(
                    height: ScreenAdapter.height(48),
                    child: DecoratedBox(
                      key: const Key('home-apply-now'),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.buttonShadow,
                            blurRadius: ScreenAdapter.width(1),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(
                          ScreenAdapter.width(8),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ScreenAdapter.width(8),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              offer?.buttonText ?? 'Apply Now',
                              maxLines: 1,
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: ScreenAdapter.font(20),
                                fontWeight: FontWeight.w600,
                                height: 24 / 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenAdapter.height(16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductName extends StatelessWidget {
  const _ProductName({this.offer});

  final HomeLoanOfferData? offer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ScreenAdapter.width(226),
      height: ScreenAdapter.height(35),
      child: DecoratedBox(
        key: const Key('home-product-gradient'),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.productGradientStart, AppColors.surface],
          ),
          borderRadius: BorderRadius.circular(ScreenAdapter.width(21)),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: ScreenAdapter.width(8)),
          child: Row(
            children: [
              _LoanProductLogo(imageUrl: offer?.productLogo ?? ''),
              SizedBox(width: ScreenAdapter.width(8)),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    offer?.productName ?? 'PG Finance',
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: ScreenAdapter.font(14),
                      fontWeight: FontWeight.w400,
                      height: 16 / 14,
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

class _LoanProductLogo extends StatelessWidget {
  const _LoanProductLogo({required this.imageUrl});

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
          fontSize: ScreenAdapter.font(6),
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return SizedBox(
      width: ScreenAdapter.width(18),
      height: ScreenAdapter.height(18),
      child: imageUrl.trim().isEmpty
          ? fallback
          : ClipRRect(
              borderRadius: BorderRadius.circular(ScreenAdapter.width(2)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) {
                  return progress == null ? child : fallback;
                },
              ),
            ),
    );
  }
}

class _LoanTerms extends StatelessWidget {
  const _LoanTerms({this.offer});

  final HomeLoanOfferData? offer;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: ScreenAdapter.font(14),
      fontWeight: FontWeight.w400,
      height: 16 / 14,
    );
    final valueStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: ScreenAdapter.font(14),
      fontWeight: FontWeight.w400,
      height: 16 / 14,
    );

    final loanTermRows = offer?.loanTermRows ?? const <HomeLoanTermRow>[];
    if (loanTermRows.isNotEmpty) {
      return Column(
        children: [
          for (final row in loanTermRows)
            Expanded(
              child: _LoanTermRow(
                leftText: row.leftText,
                rightText: row.rightText,
                leftStyle: labelStyle,
                rightStyle: valueStyle,
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: _LoanTermRow(
            leftText: offer?.loanTermCaption ?? 'Loan terms',
            rightText: offer?.loanTerm ?? '180 Days',
            leftStyle: labelStyle,
            rightStyle: valueStyle,
          ),
        ),
        SizedBox(height: ScreenAdapter.height(16)),
        Expanded(
          child: _LoanTermRow(
            leftText: offer?.interestRateCaption ?? 'Interest rate',
            rightText: offer?.interestRate ?? '≤ 0.5% Day',
            leftStyle: labelStyle,
            rightStyle: valueStyle,
          ),
        ),
      ],
    );
  }
}

class _LoanTermRow extends StatelessWidget {
  const _LoanTermRow({
    required this.leftText,
    required this.rightText,
    required this.leftStyle,
    required this.rightStyle,
  });

  final String leftText;
  final String rightText;
  final TextStyle leftStyle;
  final TextStyle rightStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(leftText, style: leftStyle),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(rightText, style: rightStyle),
          ),
        ),
      ],
    );
  }
}

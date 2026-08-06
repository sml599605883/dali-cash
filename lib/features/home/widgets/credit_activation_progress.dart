import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CreditActivationProgress extends StatelessWidget {
  const CreditActivationProgress({super.key});

  static const _steps = <String>[
    'Identity',
    'Living',
    'Basic information',
    'Bank Card',
  ];

  static const _amounts = <String>[
    '₱ 30,000',
    '₱ 40,000',
    '₱ 50,000',
    '₱ 60,000',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-credit-activation-progress'),
      width: ScreenAdapter.width(343),
      height: ScreenAdapter.height(140),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment(0.61, 1),
          colors: [
            AppColors.activationProgressGradientStart,
            AppColors.activationProgressGradientEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: ScreenAdapter.height(10),
            left: ScreenAdapter.width(16),
            child: Text(
              'Credit Activation Progress',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: ScreenAdapter.font(16),
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: ScreenAdapter.height(36),
            bottom: 0,
            child: ColoredBox(
              color: AppColors.surface,
              child: Stack(
                children: [
                  Positioned(
                    left: ScreenAdapter.width(24),
                    right: ScreenAdapter.width(24),
                    top: ScreenAdapter.height(12),
                    height: ScreenAdapter.height(47),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var index = 0; index < _steps.length; index++) ...[
                          _ProgressStep(
                            label: _steps[index],
                            isActive: index == 0,
                          ),
                          if (index < _steps.length - 1)
                            Image.asset(
                              index == 0
                                  ? AppAssets.activationProgressArrowActive
                                  : AppAssets.activationProgressArrowInactive,
                              width: ScreenAdapter.width(18),
                              height: ScreenAdapter.height(18),
                            ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: ScreenAdapter.width(24),
                    top: ScreenAdapter.height(69),
                    child: Image.asset(
                      AppAssets.activationProgressTrack,
                      key: const Key('home-credit-activation-track'),
                      width: ScreenAdapter.width(295),
                      height: ScreenAdapter.height(8),
                    ),
                  ),
                  Positioned(
                    left: ScreenAdapter.width(24),
                    right: ScreenAdapter.width(24),
                    top: ScreenAdapter.height(82),
                    height: ScreenAdapter.height(12),
                    child: Row(
                      children: [
                        for (var index = 0; index < _amounts.length; index++)
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: switch (index) {
                                0 => Alignment.centerLeft,
                                3 => Alignment.centerRight,
                                _ => Alignment.center,
                              },
                              child: Text(
                                _amounts[index],
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: ScreenAdapter.font(10),
                                  fontWeight: index == 0
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  height: 12 / 10,
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
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ScreenAdapter.width(46),
      height: ScreenAdapter.height(47),
      padding: EdgeInsets.only(bottom: ScreenAdapter.height(4)),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.activationProgressActive
            : AppColors.activationProgressInactive,
        borderRadius: BorderRadius.circular(ScreenAdapter.width(6)),
      ),
      child: Column(
        children: [
          Image.asset(
            AppAssets.activationProgressCoin,
            width: ScreenAdapter.width(23),
            height: ScreenAdapter.height(23),
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? AppColors.surface : AppColors.textPrimary,
                  fontSize: ScreenAdapter.font(8),
                  height: 10 / 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

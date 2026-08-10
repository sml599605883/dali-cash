import 'dart:math' as math;

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/home/home_data.dart';
import 'package:flutter/material.dart';

class CreditActivationProgress extends StatelessWidget {
  const CreditActivationProgress({super.key, required this.items});

  final List<HomeCreditActivationItem> items;

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
            left: 0,
            right: 0,
            child: Text(
              'Credit Activation Progress',
              textAlign: TextAlign.center,
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
              child: _ProgressContent(items: items),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({required this.items});

  final List<HomeCreditActivationItem> items;

  @override
  Widget build(BuildContext context) {
    final tileWidth = ScreenAdapter.width(46);
    final arrowWidth = ScreenAdapter.width(18);
    final sidePadding = ScreenAdapter.width(24);
    final minimumWidth = ScreenAdapter.width(295);
    final contentWidth = math.max(
      minimumWidth,
      tileWidth * items.length + arrowWidth * math.max(0, items.length - 1),
    );

    return SingleChildScrollView(
      key: const Key('home-credit-activation-scroll'),
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        child: SizedBox(
          width: contentWidth,
          height: ScreenAdapter.height(104),
          child: Column(
            children: [
              SizedBox(height: ScreenAdapter.height(12)),
              SizedBox(
                height: ScreenAdapter.height(47),
                child: _stepRow(contentWidth, tileWidth),
              ),
              SizedBox(height: ScreenAdapter.height(10)),
              SizedBox(
                width: contentWidth,
                height: ScreenAdapter.height(8),
                child: CustomPaint(
                  key: const Key('home-credit-activation-track'),
                  painter: _ProgressTrackPainter(
                    count: items.length,
                    active: items.map((item) => item.isUnlocked).toList(),
                  ),
                ),
              ),
              SizedBox(height: ScreenAdapter.height(5)),
              SizedBox(
                height: ScreenAdapter.height(12),
                child: _amountRow(contentWidth, tileWidth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepRow(double contentWidth, double tileWidth) {
    if (items.length == 1) {
      final item = items.single;
      return Center(
        child: _ProgressStep(
          index: 0,
          label: item.title,
          isActive: item.isUnlocked,
        ),
      );
    }
    final gapWidth =
        (contentWidth - tileWidth * items.length) / (items.length - 1);
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _ProgressStep(
            index: index,
            label: items[index].title,
            isActive: items[index].isUnlocked,
          ),
          if (index < items.length - 1)
            SizedBox(
              width: gapWidth,
              child: Center(
                child: Image.asset(
                  key: Key(
                    'home-credit-activation-arrow-${items[index].isUnlocked ? 'active' : 'inactive'}-$index',
                  ),
                  items[index].isUnlocked
                      ? AppAssets.activationProgressArrowActive
                      : AppAssets.activationProgressArrowInactive,
                  width: ScreenAdapter.width(18),
                  height: ScreenAdapter.height(18),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _amountRow(double contentWidth, double tileWidth) {
    final gapWidth = items.length <= 1
        ? 0.0
        : (contentWidth - tileWidth * items.length) / (items.length - 1);
    return Row(
      mainAxisAlignment: items.length == 1
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          SizedBox(
            width: tileWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                items[index].amount,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: ScreenAdapter.font(10),
                  fontWeight: items[index].isUnlocked
                      ? FontWeight.w700
                      : FontWeight.w400,
                  height: 12 / 10,
                ),
              ),
            ),
          ),
          if (index < items.length - 1) SizedBox(width: gapWidth),
        ],
      ],
    );
  }
}

class _ProgressTrackPainter extends CustomPainter {
  const _ProgressTrackPainter({required this.count, required this.active});

  final int count;
  final List<bool> active;

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;
    final edge = ScreenAdapter.width(4);
    final trackLine = Paint()
      ..color = AppColors.activationProgressTrackInactive
      ..strokeWidth = ScreenAdapter.height(2)
      ..strokeCap = StrokeCap.round;
    final activeLine = Paint()
      ..color = AppColors.activationProgressActive
      ..strokeWidth = ScreenAdapter.height(2)
      ..strokeCap = StrokeCap.round;
    final spacing = count == 1 ? 0 : (size.width - edge * 2) / (count - 1);
    final y = size.height / 2;
    final start = count == 1 ? size.width / 2 : edge;
    final end = count == 1 ? start : size.width - edge;
    canvas.drawLine(Offset(start, y), Offset(end, y), trackLine);
    final unlockedCount = active.where((value) => value).length;
    final progressEnd = count == 1
        ? (unlockedCount == 0 ? start : end)
        : start + (end - start) * unlockedCount / count;
    if (unlockedCount > 0) {
      canvas.drawLine(Offset(start, y), Offset(progressEnd, y), activeLine);
    }
    final activeMarker = Paint()..color = AppColors.activationProgressActive;
    final inactiveMarker = Paint()
      ..color = AppColors.activationProgressTrackMarkerInactive;
    for (var index = 0; index < count; index++) {
      canvas.drawCircle(
        Offset(count == 1 ? start : edge + index * spacing, y),
        ScreenAdapter.width(4),
        active[index] ? activeMarker : inactiveMarker,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressTrackPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.active != active;
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.index,
    required this.label,
    required this.isActive,
  });

  final int index;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key(
        'home-credit-activation-step-${isActive ? 'active' : 'inactive'}-$index',
      ),
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

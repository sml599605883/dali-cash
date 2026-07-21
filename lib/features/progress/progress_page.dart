import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/progress/progress_item.dart';
import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, this.items = ProgressItem.samples});

  final List<ProgressItem> items;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: items.isEmpty ? const _EmptyProgress() : _ProgressList(items),
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ProgressTitle(),
        const Spacer(),
        Image.asset(
          AppAssets.progressEmpty,
          key: const Key('progress-empty-image'),
          width: ScreenAdapter.width(120),
          height: ScreenAdapter.height(102),
          fit: BoxFit.contain,
        ),
        SizedBox(height: ScreenAdapter.height(32)),
        Text(
          'No progress yet',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: ScreenAdapter.font(16),
            fontWeight: FontWeight.w400,
            height: 22 / 16,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _ProgressList extends StatelessWidget {
  const _ProgressList(this.items);

  final List<ProgressItem> items;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _ProgressTitle()),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            ScreenAdapter.width(28),
            ScreenAdapter.height(16),
            ScreenAdapter.width(28),
            ScreenAdapter.height(24),
          ),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1
                    ? 0
                    : ScreenAdapter.height(16),
              ),
              child: _ProgressCard(item: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressTitle extends StatelessWidget {
  const _ProgressTitle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(64),
      child: Center(
        child: Text(
          'progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: ScreenAdapter.font(17),
            fontWeight: FontWeight.w600,
            height: 24 / 17,
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.item});

  final ProgressItem item;

  @override
  Widget build(BuildContext context) {
    final presentation = _ProgressPresentation.from(item.emblemize);
    final hasActions = presentation.actions;
    final cardHeight = hasActions ? 158.0 : 118.0;

    return SizedBox(
      key: const Key('progress-card'),
      width: ScreenAdapter.width(319),
      height: ScreenAdapter.height(cardHeight),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              key: Key(
                presentation.isRed ? 'progress-red-card' : 'progress-blue-card',
              ),
              decoration: BoxDecoration(
                color: presentation.isRed ? AppColors.alert : AppColors.primary,
                borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      ScreenAdapter.width(24),
                      ScreenAdapter.height(44),
                      ScreenAdapter.width(24),
                      0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ValueRow(
                          label: presentation.amountLabel,
                          value: item.amount,
                        ),
                        SizedBox(height: ScreenAdapter.height(8)),
                        _ValueRow(
                          label: presentation.dateLabel,
                          value: item.date,
                        ),
                      ],
                    ),
                  ),
                  if (hasActions)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _ActionRow(presentation: presentation),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: ScreenAdapter.width(-12),
            right: ScreenAdapter.width(-12),
            top: 0,
            height: ScreenAdapter.height(40),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(ScreenAdapter.width(10)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenAdapter.width(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: ScreenAdapter.width(18),
                      height: ScreenAdapter.height(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          ScreenAdapter.width(3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: ScreenAdapter.font(11),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: ScreenAdapter.width(4)),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: ScreenAdapter.font(16),
                          fontWeight: FontWeight.w600,
                          height: 16 / 16,
                        ),
                      ),
                    ),
                    Text(
                      presentation.label,
                      style: TextStyle(
                        color: presentation.isRed || presentation.isFailed
                            ? AppColors.alert
                            : AppColors.primary,
                        fontSize: ScreenAdapter.font(12),
                        fontWeight: FontWeight.w400,
                        height: 17 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: ScreenAdapter.font(14),
              fontWeight: FontWeight.w400,
              height: 16 / 14,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: ScreenAdapter.font(14),
              fontWeight: FontWeight.w700,
              height: 17 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.presentation});

  final _ProgressPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(40),
      child: Row(
        children: [
          if (presentation.isFailed)
            Expanded(
              child: DecoratedBox(
                key: const Key('progress-retry'),
                decoration: BoxDecoration(
                  color: AppColors.progressRetry,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ScreenAdapter.width(8)),
                    bottomLeft: Radius.circular(ScreenAdapter.width(8)),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Try again',
                    style: _actionTextStyle(AppColors.surface),
                  ),
                ),
              ),
            ),
          Expanded(
            child: DecoratedBox(
              key: const Key('progress-change'),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.horizontal(
                  left: presentation.isFailed
                      ? Radius.zero
                      : Radius.circular(ScreenAdapter.width(8)),
                  right: Radius.circular(ScreenAdapter.width(8)),
                ),
              ),
              child: Center(
                child: Text(
                  'Change',
                  style: _actionTextStyle(
                    presentation.isRed ? AppColors.alert : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _actionTextStyle(Color color) => TextStyle(
    color: color,
    fontSize: ScreenAdapter.font(14),
    fontWeight: FontWeight.w500,
    height: 20 / 14,
  );
}

class _ProgressPresentation {
  const _ProgressPresentation({
    required this.label,
    required this.amountLabel,
    required this.dateLabel,
    required this.actions,
    required this.isRed,
    required this.isFailed,
  });

  final String label;
  final String amountLabel;
  final String dateLabel;
  final bool actions;
  final bool isRed;
  final bool isFailed;

  factory _ProgressPresentation.from(String emblemize) {
    switch (emblemize) {
      case ProgressEmblemize.disbursementFailed:
        return const _ProgressPresentation(
          label: 'Disbursement Failed',
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          actions: true,
          isRed: false,
          isFailed: true,
        );
      case ProgressEmblemize.disbursing:
        return const _ProgressPresentation(
          label: 'Disbursing',
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          actions: false,
          isRed: false,
          isFailed: false,
        );
      case ProgressEmblemize.activeLoan:
        return const _ProgressPresentation(
          label: 'Active Loan',
          amountLabel: 'Repayment',
          dateLabel: 'Repayment Date',
          actions: true,
          isRed: true,
          isFailed: false,
        );
      case ProgressEmblemize.overdue:
        return const _ProgressPresentation(
          label: 'Overdue',
          amountLabel: 'Repayment',
          dateLabel: 'Repayment Date',
          actions: true,
          isRed: true,
          isFailed: false,
        );
      case ProgressEmblemize.inReview:
        return const _ProgressPresentation(
          label: 'In Review',
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          actions: false,
          isRed: false,
          isFailed: false,
        );
      default:
        return _ProgressPresentation(
          label: emblemize,
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          actions: false,
          isRed: false,
          isFailed: false,
        );
    }
  }
}

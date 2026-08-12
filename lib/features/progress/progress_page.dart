import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/progress/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../main_shell/main_controller.dart';

class ProgressPage extends GetView<MainController> {
  const ProgressPage({super.key, this.items});

  final List<ProgressItem>? items;

  @override
  Widget build(BuildContext context) {
    if (items != null) {
      return _ProgressRefreshView(items: items!, onRefresh: null);
    }
    return Obx(
      () => _ProgressRefreshView(
        items: controller.homeData.value?.progressItems ?? const [],
        isLoading: controller.isProgressRefreshing.value,
        error: controller.progressError.value,
        onRefresh: controller.refreshProgress,
        onItemTap: controller.handleProgressTap,
        onActionTap: controller.handleProgressActionTap,
      ),
    );
  }
}

class _ProgressRefreshView extends StatelessWidget {
  const _ProgressRefreshView({
    required this.items,
    required this.onRefresh,
    this.isLoading = false,
    this.error,
    this.onItemTap,
    this.onActionTap,
  });

  final List<ProgressItem> items;
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final String? error;
  final ValueChanged<ProgressItem>? onItemTap;
  final void Function(ProgressItem, ProgressAction)? onActionTap;

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _ProgressTitle()),
        if (isLoading && items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null && items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ProgressError(message: error!, onRetry: onRefresh),
          )
        else if (items.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyProgressContent(),
          )
        else
          _ProgressItemsSliver(
            items,
            onItemTap: onItemTap,
            onActionTap: onActionTap,
          ),
      ],
    );

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: onRefresh == null
            ? scrollView
            : RefreshIndicator(onRefresh: onRefresh!, child: scrollView),
      ),
    );
  }
}

class _EmptyProgressContent extends StatelessWidget {
  const _EmptyProgressContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
      ],
    );
  }
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(message, style: TextStyle(color: AppColors.textPrimary)),
        SizedBox(height: ScreenAdapter.height(16)),
        TextButton(
          key: const Key('progress-load-retry'),
          onPressed: onRetry == null ? null : () => onRetry!(),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _ProgressItemsSliver extends StatelessWidget {
  const _ProgressItemsSliver(this.items, {this.onItemTap, this.onActionTap});

  final List<ProgressItem> items;
  final ValueChanged<ProgressItem>? onItemTap;
  final void Function(ProgressItem, ProgressAction)? onActionTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
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
            bottom: index == items.length - 1 ? 0 : ScreenAdapter.height(16),
          ),
          child: _ProgressCard(
            item: items[index],
            onTap: onItemTap == null ? null : () => onItemTap!(items[index]),
            onActionTap: onActionTap == null
                ? null
                : (action) => onActionTap!(items[index], action),
          ),
        ),
      ),
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
  const _ProgressCard({required this.item, this.onTap, this.onActionTap});

  final ProgressItem item;
  final VoidCallback? onTap;
  final ValueChanged<ProgressAction>? onActionTap;

  @override
  Widget build(BuildContext context) {
    final presentation = _ProgressPresentation.from(
      item.emblemize,
      item.statusLabel,
    );
    final hasActions = item.usesServerActions
        ? item.actions.isNotEmpty
        : presentation.actions;
    final cardHeight = hasActions ? 158.0 : 118.0;

    return SizedBox(
      key: const Key('progress-card'),
      width: ScreenAdapter.width(319),
      height: ScreenAdapter.height(cardHeight),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: DecoratedBox(
                key: Key(
                  presentation.isRed
                      ? 'progress-red-card'
                      : 'progress-blue-card',
                ),
                decoration: BoxDecoration(
                  color: presentation.isRed
                      ? AppColors.alert
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(ScreenAdapter.width(12)),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        ScreenAdapter.width(24),
                        ScreenAdapter.height(61),
                        ScreenAdapter.width(24),
                        0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ValueRow(
                            label: item.amountLabel.isEmpty
                                ? presentation.amountLabel
                                : item.amountLabel,
                            value: item.amount,
                          ),
                          SizedBox(height: ScreenAdapter.height(8)),
                          _ValueRow(
                            label: item.dateLabel.isEmpty
                                ? presentation.dateLabel
                                : item.dateLabel,
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
                        child: _ActionRow(
                          presentation: presentation,
                          actions: item.actions,
                          onActionTap: onActionTap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: ScreenAdapter.width(-12),
            right: ScreenAdapter.width(-12),
            top: ScreenAdapter.width(8),
            height: ScreenAdapter.height(40),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
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
                      if (item.productLogo.isNotEmpty) ...[
                        SizedBox(
                          key: const Key('progress-product-logo'),
                          width: ScreenAdapter.width(18),
                          height: ScreenAdapter.height(18),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ScreenAdapter.width(3),
                            ),
                            child: Image.network(
                              item.productLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        SizedBox(width: ScreenAdapter.width(4)),
                      ],
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
  const _ActionRow({
    required this.presentation,
    required this.actions,
    this.onActionTap,
  });

  final _ProgressPresentation presentation;
  final List<ProgressAction> actions;
  final ValueChanged<ProgressAction>? onActionTap;

  @override
  Widget build(BuildContext context) {
    if (actions.isNotEmpty) {
      final hasMultipleActions = actions.length > 1;
      return SizedBox(
        height: ScreenAdapter.height(40),
        child: Row(
          children: List<Widget>.generate(actions.length, (index) {
            final action = actions[index];
            final isFirst = index == 0;
            final isLast = index == actions.length - 1;
            final isHighlightedRetry =
                hasMultipleActions && action.type == 'retry';
            final radius = Radius.circular(ScreenAdapter.width(8));
            return Expanded(
              flex: actions.length == 2 ? (isFirst ? 160 : 159) : 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onActionTap == null ? null : () => onActionTap!(action),
                child: DecoratedBox(
                  key: Key('progress-action-${action.type}'),
                  decoration: BoxDecoration(
                    color: isHighlightedRetry
                        ? AppColors.progressRetry
                        : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: isFirst ? radius : Radius.zero,
                      bottomLeft: isFirst ? radius : Radius.zero,
                      topRight: isLast ? radius : Radius.zero,
                      bottomRight: isLast ? radius : Radius.zero,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      action.label,
                      style: _actionTextStyle(
                        isHighlightedRetry
                            ? AppColors.surface
                            : presentation.isRed
                            ? AppColors.alert
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onActionTap == null
                      ? null
                      : () => onActionTap!(
                          const ProgressAction(
                            type: 'retry',
                            visible: true,
                            label: 'Try again',
                            badge: '',
                            route: '',
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onActionTap == null
                    ? null
                    : () => onActionTap!(
                        const ProgressAction(
                          type: 'change',
                          visible: true,
                          label: 'Change',
                          badge: '',
                          route: '',
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

  factory _ProgressPresentation.from(int emblemize, String serverLabel) {
    final fallback = serverLabel.trim();
    switch (emblemize) {
      case ProgressEmblemize.disbursementFailed:
      case ProgressEmblemize.disbursementFailedAlternative:
        return const _ProgressPresentation(
          label: 'Disbursement Failed',
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          actions: true,
          isRed: false,
          isFailed: true,
        ).withLabel(fallback);
      case ProgressEmblemize.disbursing:
        return const _ProgressPresentation(
          label: 'Disbursing',
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          actions: false,
          isRed: false,
          isFailed: false,
        ).withLabel(fallback);
      case ProgressEmblemize.activeLoan:
        return const _ProgressPresentation(
          label: 'Active Loan',
          amountLabel: 'Repayment',
          dateLabel: 'Repayment Date',
          actions: true,
          isRed: true,
          isFailed: false,
        ).withLabel(fallback);
      case ProgressEmblemize.overdue:
        return const _ProgressPresentation(
          label: 'Overdue',
          amountLabel: 'Repayment',
          dateLabel: 'Repayment Date',
          actions: true,
          isRed: true,
          isFailed: false,
        ).withLabel(fallback);
      case ProgressEmblemize.inReview:
        return const _ProgressPresentation(
          label: 'In Review',
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          actions: false,
          isRed: false,
          isFailed: false,
        ).withLabel(fallback);
      default:
        return _ProgressPresentation(
          label: fallback.isEmpty ? 'In Review' : fallback,
          amountLabel: 'Loan Amount',
          dateLabel: 'Loan Date',
          actions: false,
          isRed: false,
          isFailed: false,
        );
    }
  }

  _ProgressPresentation withLabel(String serverLabel) {
    return serverLabel.isEmpty
        ? this
        : _ProgressPresentation(
            label: serverLabel,
            amountLabel: amountLabel,
            dateLabel: dateLabel,
            actions: actions,
            isRed: isRed,
            isFailed: isFailed,
          );
  }
}

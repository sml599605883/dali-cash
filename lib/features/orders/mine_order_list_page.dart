import 'dart:async';

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/navigation/app_route_observer.dart';
import 'package:dali_cash/app/navigation/navigation_helper.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/core/network/api_client.dart';
import 'package:dali_cash/core/network/api_exception.dart';
import 'package:dali_cash/features/orders/order_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef OrderListLoader = Future<Json> Function(String status);
typedef OrderTargetNavigator = Future<void> Function(String target);
typedef OrderAdmissionNavigator = Future<void> Function(String productId);

class MineOrderListPage extends StatefulWidget {
  const MineOrderListPage({
    super.key,
    this.initialStatus,
    this.loadOrders,
    this.navigateTarget,
    this.startAdmission,
  });

  final MineOrderStatus? initialStatus;
  final OrderListLoader? loadOrders;
  final OrderTargetNavigator? navigateTarget;
  final OrderAdmissionNavigator? startAdmission;

  @override
  State<MineOrderListPage> createState() => _MineOrderListPageState();
}

class _MineOrderListPageState extends State<MineOrderListPage> with RouteAware {
  late MineOrderStatus _selectedStatus;
  List<OrderListItem> _items = const <OrderListItem>[];
  bool _loading = true;
  String? _errorMessage;
  int _loadGeneration = 0;
  final Set<String> _activeActionIds = <String>{};
  PageRoute<dynamic>? _subscribedRoute;

  OrderListLoader get _loadOrders => widget.loadOrders ?? _loadFromApi;

  OrderTargetNavigator get _navigateTarget =>
      widget.navigateTarget ?? NavigationHelper.navigateRawTarget;

  OrderAdmissionNavigator get _startAdmission =>
      widget.startAdmission ?? NavigationHelper.applyProduct;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? _statusFromArguments();
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && !identical(route, _subscribedRoute)) {
      if (_subscribedRoute != null) {
        appRouteObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    unawaited(_load());
  }

  @override
  void dispose() {
    if (_subscribedRoute != null) {
      appRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  MineOrderStatus _statusFromArguments() {
    final arguments = Get.arguments;
    if (arguments is Map) {
      return MineOrderStatus.fromCode(arguments['initialStatus']?.toString());
    }
    return MineOrderStatus.all;
  }

  Future<Json> _loadFromApi(String status) async {
    final response = await Get.find<ApiClient>().orderList(status: status);
    return response.states;
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final states = await _loadOrders(_selectedStatus.code);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _items = parseOrderListItems(states);
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _items = const <OrderListItem>[];
        _loading = false;
        _errorMessage = ApiErrorMessage.resolve(error);
      });
    }
  }

  void _selectStatus(MineOrderStatus status) {
    if (_selectedStatus == status) return;
    setState(() => _selectedStatus = status);
    unawaited(_load());
  }

  Future<void> _handleCardTap(OrderListItem item) async {
    await _handleOrderNavigation(item, target: item.actionTarget);
  }

  Future<void> _handleAction(OrderListItem item) async {
    await _handleOrderNavigation(item, target: item.actionTarget);
  }

  Future<void> _handleOrderNavigation(
    OrderListItem item, {
    required String target,
  }) async {
    final actionId = item.orderId.isNotEmpty
        ? item.orderId
        : '${item.productId}|$target';
    if (!_activeActionIds.add(actionId)) return;
    try {
      if (target.isNotEmpty) {
        await _runNavigation(() => _navigateTarget(target));
        return;
      }
      if (item.productId.isNotEmpty) {
        await _runNavigation(() => _startAdmission(item.productId));
      }
    } finally {
      _activeActionIds.remove(actionId);
    }
  }

  Future<void> _runNavigation(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        await NavigationHelper.errorPresenter(ApiErrorMessage.resolve(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            key: const Key('mineOrderScroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              ScreenAdapter.width(16),
              ScreenAdapter.height(12),
              ScreenAdapter.width(16),
              ScreenAdapter.height(24),
            ),
            children: [
              const _OrderHeader(),
              SizedBox(height: ScreenAdapter.height(20)),
              _OrderTabs(
                selectedStatus: _selectedStatus,
                onSelected: _selectStatus,
              ),
              SizedBox(height: ScreenAdapter.height(16)),
              if (_loading)
                const _OrderLoading()
              else if (_errorMessage != null)
                _OrderStatusState(message: _errorMessage!, onRetry: _load)
              else if (_items.isEmpty)
                  const _OrderStatusState(
                    key: Key('mineOrderEmpty'),
                    message: 'No information available',
                    showEmptyImage: true,
                  )
              else
                for (final item in _items)
                  Padding(
                    padding: EdgeInsets.only(bottom: ScreenAdapter.height(12)),
                    child: _OrderCard(
                      item: item,
                      onCardTap: () => _handleCardTap(item),
                      onActionTap: () => _handleAction(item),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('mineOrderBack'),
                onTap: NavigationHelper.back,
                borderRadius: BorderRadius.circular(ScreenAdapter.width(20)),
                child: SizedBox(
                  width: ScreenAdapter.width(40),
                  height: ScreenAdapter.height(40),
                  child: Center(
                    child: Image.asset(
                      AppAssets.identityBack,
                      width: ScreenAdapter.width(18),
                      height: ScreenAdapter.height(18),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Loan List',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: ScreenAdapter.font(17),
              fontWeight: FontWeight.w600,
              height: 24 / 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTabs extends StatelessWidget {
  const _OrderTabs({required this.selectedStatus, required this.onSelected});

  final MineOrderStatus selectedStatus;
  final ValueChanged<MineOrderStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final status in MineOrderStatus.values)
          Expanded(
            child: InkWell(
              key: ValueKey('orderTab-${status.code}'),
              onTap: () => onSelected(status),
              child: Column(
                children: [
                  Text(
                    status.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: status == selectedStatus
                          ? AppColors.textPrimary
                          : AppColors.orderTabInactive,
                      fontSize: ScreenAdapter.font(14),
                      fontWeight: status == selectedStatus
                          ? FontWeight.w700
                          : FontWeight.w400,
                      height: 17 / 14,
                    ),
                  ),
                  SizedBox(height: ScreenAdapter.height(9)),
                  Container(
                    key: status == selectedStatus
                        ? ValueKey('orderTabSelected-${status.code}')
                        : null,
                    width: ScreenAdapter.width(51),
                    height: ScreenAdapter.height(4),
                    color: status == selectedStatus
                        ? AppColors.primary
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.item,
    required this.onCardTap,
    required this.onActionTap,
  });

  final OrderListItem item;
  final VoidCallback onCardTap;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.usesBlueAction
        ? AppColors.primary
        : item.usesRedAction
        ? AppColors.alert
        : AppColors.textPrimary;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(ScreenAdapter.width(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('orderCard-${item.orderId}'),
        onTap: onCardTap,
        child: Padding(
          padding: EdgeInsets.all(ScreenAdapter.width(12)),
          child: Column(
            children: [
              Row(
                children: [
                  if (item.productLogo.isNotEmpty) ...[
                    SizedBox(
                      width: ScreenAdapter.width(14),
                      height: ScreenAdapter.height(14),
                      child: Image.network(
                        item.productLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    SizedBox(width: ScreenAdapter.width(4)),
                  ],
                  Expanded(
                    child: Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.orderProductText,
                        fontSize: ScreenAdapter.font(14),
                        fontWeight: FontWeight.w500,
                        height: 16 / 14,
                      ),
                    ),
                  ),
                  SizedBox(width: ScreenAdapter.width(8)),
                  Text(
                    item.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: ScreenAdapter.font(12),
                      fontWeight: FontWeight.w400,
                      height: 14 / 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ScreenAdapter.height(12)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ScreenAdapter.width(8),
                  vertical: ScreenAdapter.height(12),
                ),
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(ScreenAdapter.width(4)),
                ),
                child: Column(
                  children: [
                    _OrderInfoRow(
                      label: item.amountLabel,
                      value: item.amountText,
                    ),
                    SizedBox(height: ScreenAdapter.height(12)),
                    _OrderInfoRow(label: item.dateLabel, value: item.dateValue),
                  ],
                ),
              ),
              if (item.showAction) ...[
                SizedBox(height: ScreenAdapter.height(12)),
                SizedBox(
                  width: double.infinity,
                  height: ScreenAdapter.height(36),
                  child: ElevatedButton(
                    key: ValueKey('orderAction-${item.orderId}'),
                    onPressed: onActionTap,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.surface,
                      backgroundColor: item.usesBlueAction
                          ? AppColors.primary
                          : AppColors.alert,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ScreenAdapter.width(8),
                        ),
                      ),
                    ),
                    child: Text(
                      item.actionText,
                      style: TextStyle(
                        fontSize: ScreenAdapter.font(14),
                        fontWeight: FontWeight.w700,
                        height: 17 / 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.orderMutedText,
              fontSize: ScreenAdapter.font(14),
              height: 17 / 14,
            ),
          ),
        ),
        SizedBox(width: ScreenAdapter.width(12)),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: ScreenAdapter.font(14),
              height: 17 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderLoading extends StatelessWidget {
  const _OrderLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: Key('mineOrderLoading'),
      height: 420,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _OrderStatusState extends StatelessWidget {
  const _OrderStatusState({
    super.key,
    required this.message,
    this.onRetry,
    this.showEmptyImage = false,
  });

  final String message;
  final Future<void> Function()? onRetry;
  final bool showEmptyImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ScreenAdapter.height(420),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showEmptyImage) ...[
              Image.asset(
                AppAssets.orderEmpty,
                key: const Key('mineOrderEmptyImage'),
                width: ScreenAdapter.width(120),
                height: ScreenAdapter.height(102),
                fit: BoxFit.contain,
              ),
              SizedBox(height: ScreenAdapter.height(32)),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.orderMutedText,
                fontSize: ScreenAdapter.font(14),
                height: 18 / 14,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: ScreenAdapter.height(12)),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

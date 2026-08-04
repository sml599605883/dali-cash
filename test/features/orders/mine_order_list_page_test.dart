import 'dart:async';

import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/navigation/app_route_observer.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/orders/mine_order_list_page.dart';
import 'package:dali_cash/features/orders/order_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders documented actions and routes each tap correctly', (
    tester,
  ) async {
    final requestedStatuses = <String>[];
    final targets = <String>[];
    final admissionProductIds = <String>[];

    await _pumpPage(
      tester,
      loadOrders: (status) async {
        requestedStatuses.add(status);
        return _orders();
      },
      navigateTarget: (target) async => targets.add(target),
      startAdmission: (productId) async {
        admissionProductIds.add(productId);
      },
    );
    await tester.pumpAndSettle();

    expect(requestedStatuses, ['4']);
    expect(find.text('Loan List'), findsOneWidget);
    expect(find.text('PG Finance'), findsNWidgets(3));
    expect(find.text('PHP 20,000.00'), findsNWidgets(3));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Repay Now'), findsOneWidget);
    expect(find.byKey(const Key('mineOrderConfirm')), findsNothing);

    expect(_buttonColor(tester, '174'), AppColors.primary);
    expect(_buttonColor(tester, '180'), AppColors.alert);
    expect(
      tester.getSize(find.byKey(const ValueKey('orderAction-174'))).height,
      36,
    );
    expect(find.byKey(const ValueKey('orderAction-200')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('orderAction-174')));
    await tester.pump();
    expect(targets, ['/repayment-detail?orderNo=ORDER-174']);
    expect(admissionProductIds, isEmpty);

    await tester.ensureVisible(find.byKey(const ValueKey('orderAction-180')));
    await tester.tap(find.byKey(const ValueKey('orderAction-180')));
    await tester.pump();
    expect(admissionProductIds, ['180']);

    await tester.ensureVisible(find.byKey(const ValueKey('orderCard-200')));
    await tester.tap(find.byKey(const ValueKey('orderCard-200')));
    await tester.pump();
    expect(targets, ['/repayment-detail?orderNo=ORDER-174']);
    expect(admissionProductIds, ['180', '200']);
  });

  testWidgets('changes filters and pull refreshes the active status', (
    tester,
  ) async {
    final requestedStatuses = <String>[];
    await _pumpPage(
      tester,
      loadOrders: (status) async {
        requestedStatuses.add(status);
        return Json({'clingiest': <dynamic>[]});
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('orderTab-7')));
    await tester.pumpAndSettle();
    expect(requestedStatuses, ['4', '7']);

    await tester.drag(
      find.byKey(const Key('mineOrderScroll')),
      const Offset(0, 320),
    );
    await tester.pumpAndSettle();
    expect(requestedStatuses, ['4', '7', '7']);
  });

  testWidgets('shows loading, error retry, and empty states', (tester) async {
    final firstLoad = Completer<Json>();
    var attempts = 0;
    await _pumpPage(
      tester,
      loadOrders: (_) {
        attempts++;
        if (attempts == 1) return firstLoad.future;
        return Future.value(Json({'clingiest': <dynamic>[]}));
      },
    );

    expect(find.byKey(const Key('mineOrderLoading')), findsOneWidget);
    firstLoad.completeError(StateError('load failed'));
    await tester.pumpAndSettle();

    expect(find.textContaining('load failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const Key('mineOrderEmpty')), findsOneWidget);
    final emptyImage = tester.widget<Image>(
      find.byKey(const Key('mineOrderEmptyImage')),
    );
    expect((emptyImage.image as AssetImage).assetName, 'assets/orders/order_empty.png');
  });

  testWidgets('uses the supplied initial filter', (tester) async {
    final requestedStatuses = <String>[];
    await _pumpPage(
      tester,
      initialStatus: MineOrderStatus.late,
      loadOrders: (status) async {
        requestedStatuses.add(status);
        return Json({'clingiest': <dynamic>[]});
      },
    );
    await tester.pumpAndSettle();

    expect(requestedStatuses, ['6']);
    expect(find.byKey(const ValueKey('orderTabSelected-6')), findsOneWidget);
  });

  testWidgets('card starts admission when its target is empty', (tester) async {
    final targets = <String>[];
    final admissions = <String>[];
    await _pumpPage(
      tester,
      loadOrders: (_) async => Json({
        'clingiest': [
          _order(status: 180, productId: 'card-product'),
        ],
      }),
      navigateTarget: (target) async => targets.add(target),
      startAdmission: (productId) async => admissions.add(productId),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('orderCard-180')));
    await tester.pump();

    expect(targets, isEmpty);
    expect(admissions, ['card-product']);
  });

  testWidgets('ignores a duplicate action while the first action is pending', (
    tester,
  ) async {
    final pending = Completer<void>();
    var admissionCalls = 0;
    await _pumpPage(
      tester,
      loadOrders: (_) async => Json({
        'clingiest': [_order(status: 180)],
      }),
      startAdmission: (_) {
        admissionCalls++;
        return pending.future;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('orderAction-180')));
    await tester.tap(find.byKey(const ValueKey('orderAction-180')));
    await tester.pump();
    expect(admissionCalls, 1);

    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('refreshes the active status after a child route returns', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final requestedStatuses = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [appRouteObserver],
        home: Builder(
          builder: (context) {
            ScreenAdapter.init(context);
            return MineOrderListPage(
              loadOrders: (status) async {
                requestedStatuses.add(status);
                return Json({
                  'clingiest': [
                    _order(status: 200, actionTarget: '/order/detail/200'),
                  ],
                });
              },
              navigateTarget: (_) async {
                await navigatorKey.currentState!.push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('Child')),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('orderCard-200')));
    await tester.pumpAndSettle();
    expect(find.text('Child'), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(requestedStatuses, ['4', '4']);
  });

  testWidgets('ignores a stale response from the previous filter', (
    tester,
  ) async {
    final allResponse = Completer<Json>();
    final unpaidResponse = Completer<Json>();
    await _pumpPage(
      tester,
      loadOrders: (status) {
        return status == '4' ? allResponse.future : unpaidResponse.future;
      },
    );

    await tester.tap(find.byKey(const ValueKey('orderTab-7')));
    await tester.pump();
    unpaidResponse.complete(
      Json({
        'clingiest': [_order(status: 200)],
      }),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('orderCard-200')), findsOneWidget);

    allResponse.complete(
      Json({
        'clingiest': [_order(status: 201)],
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('orderCard-200')), findsOneWidget);
    expect(find.byKey(const ValueKey('orderCard-201')), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  MineOrderStatus initialStatus = MineOrderStatus.all,
  required OrderListLoader loadOrders,
  OrderTargetNavigator? navigateTarget,
  OrderAdmissionNavigator? startAdmission,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [appRouteObserver],
      home: Builder(
        builder: (context) {
          ScreenAdapter.init(context);
          return MineOrderListPage(
            initialStatus: initialStatus,
            loadOrders: loadOrders,
            navigateTarget: navigateTarget,
            startAdmission: startAdmission,
          );
        },
      ),
    ),
  );
}

Color? _buttonColor(WidgetTester tester, String orderId) {
  final button = tester.widget<ElevatedButton>(
    find.byKey(ValueKey('orderAction-$orderId')),
  );
  return button.style?.backgroundColor?.resolve(<WidgetState>{});
}

Json _orders() {
  return Json({
    'clingiest': [
      _order(status: 174, actionTarget: '/repayment-detail?orderNo=ORDER-174'),
      _order(status: 180),
      _order(status: 200),
    ],
  });
}

Map<String, dynamic> _order({
  required int status,
  String actionTarget = '',
  String actionText = 'Repay Now',
  String? productId,
}) {
  return {
    'filers': status,
    'saggards': 'ORDER-$status',
    'thunderstruck': productId ?? status,
    'preslaughter': 'PG Finance',
    'fornices': status,
    'proboscis': status == 180 ? 'Overdue' : 'Outstanding',
    'injective': 'PHP 20,000.00',
    'planetological': 'Available up to',
    'weldor': status == 174 ? 'Continue' : actionText,
    'nauseant': actionTarget,
    'prebiological': 'Due Date',
    'en': '29-11-2023',
    'methodical': '/order/detail?orderId=$status',
  };
}

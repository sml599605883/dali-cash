# Mine Order List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Dali Cash personal-center order list, open it from all four Mine shortcuts, and implement the documented status-controlled action behavior.

**Architecture:** Add a Dali-specific immutable order model and dedicated stateful Mine order-list page. Keep protocol fields inside `ApiClient`, route navigation through `NavigationHelper`, and use a shared `RouteObserver` for return refresh; injected page callbacks keep widget tests deterministic.

**Tech Stack:** Flutter, Dart, GetX, Dio, `RouteObserver`, `RefreshIndicator`, `flutter_test`

---

### Task 1: Add The Dali Order-List Request

**Files:**
- Modify: `lib/core/network/api_client.dart`
- Test: `test/core/network/api_client_test.dart`

- [ ] **Step 1: Write the failing request-contract test**

```dart
test('orderList posts the documented Dali paging and status fields', () async {
  await client.orderList(status: '4');

  final request = adapter.lastRequest!;
  expect(request.method, 'POST');
  expect(request.path, endsWith(ApiEndpoints.orderList));
  expect(request.data, {
    'anfractuosity': '4',
    'redeployments': '1',
    'unornate': '50',
  });
});
```

- [ ] **Step 2: Run the test and verify RED**

Run `flutter test --concurrency=1 test/core/network/api_client_test.dart`.

Expected: compile failure because `ApiClient.orderList` does not exist.

- [ ] **Step 3: Implement the request wrapper**

```dart
Future<ApiResponse> orderList({required String status}) {
  return post(
    ApiEndpoints.orderList,
    data: {
      'anfractuosity': status,
      'redeployments': '1',
      'unornate': '50',
    },
  );
}
```

Keep paging fields internal because the page always loads the documented first
50 records.

- [ ] **Step 4: Run the test and verify GREEN**

Run `flutter test --concurrency=1 test/core/network/api_client_test.dart`.
Expected: all API client tests pass.

### Task 2: Parse The Authoritative Dali Fields

**Files:**
- Create: `lib/features/orders/order_list_item.dart`
- Create: `test/features/orders/order_list_item_test.dart`

- [ ] **Step 1: Write failing model tests**

```dart
test('parses the documented Dali order-list item', () {
  final item = OrderListItem.fromJson(Json({
    'filers': 4,
    'saggards': 'ORDER-4',
    'thunderstruck': 31,
    'preslaughter': 'PG Finance',
    'creasing': 'https://cdn.test/logo.png',
    'fornices': 174,
    'proboscis': 'Outstanding',
    'injective': '₱20,000.00',
    'planetological': 'Available up to',
    'weldor': 'Repay Now',
    'nauseant': '/repayment-detail?orderNo=ORDER-4',
    'prebiological': 'Due Date',
    'en': '29-11-2023',
    'reshippers': 0,
    'methodical': '/order/detail?orderId=4',
  }));

  expect(item.productId, '31');
  expect(item.statusCode, 174);
  expect(item.showAction, isTrue);
  expect(item.actionText, 'Repay Now');
  expect(item.actionTarget, '/repayment-detail?orderNo=ORDER-4');
});

test('shows actions only for status 174 and 180', () {
  OrderListItem item(int status) =>
      OrderListItem.fromJson(Json({'fornices': status}));
  expect(item(174).showAction, isTrue);
  expect(item(180).showAction, isTrue);
  expect(item(173).showAction, isFalse);
});

test('parses only map rows from clingiest', () {
  final items = parseOrderListItems(Json({
    'clingiest': [
      {'filers': 1, 'preslaughter': 'Valid'},
      null,
      'invalid',
    ],
  }));
  expect(items, hasLength(1));
  expect(items.single.productName, 'Valid');
});
```

- [ ] **Step 2: Run tests and verify RED**

Run `flutter test --concurrency=1 test/features/orders/order_list_item_test.dart`.

Expected: compile failure because the model does not exist.

- [ ] **Step 3: Implement the immutable model and filter enum**

```dart
enum MineOrderStatus {
  all('4', 'View All'),
  unpaid('7', 'Unpaid'),
  late('6', 'Late'),
  paid('5', 'Paid');

  const MineOrderStatus(this.code, this.label);
  final String code;
  final String label;

  static MineOrderStatus fromCode(String? code) => values.firstWhere(
    (status) => status.code == code?.trim(),
    orElse: () => all,
  );
}
```

Create final semantic fields for every documented item value. Normalize
`thunderstruck` through `stringValue`. Implement only:

```dart
bool get showAction => statusCode == 174 || statusCode == 180;
bool get usesBlueAction => statusCode == 174;
bool get usesRedAction => statusCode == 180;
```

Parse rows with:

```dart
List<OrderListItem> parseOrderListItems(Json states) {
  return states['clingiest'].listValue
      .where((row) => row.mapOrNull != null)
      .map(OrderListItem.fromJson)
      .toList(growable: false);
}
```

- [ ] **Step 4: Run tests and verify GREEN**

Run
`flutter test --concurrency=1 test/features/orders/order_list_item_test.dart`.
Expected: all model tests pass.

### Task 3: Build The Page And Action Behavior

**Files:**
- Create: `lib/features/orders/mine_order_list_page.dart`
- Create: `test/features/orders/mine_order_list_page_test.dart`
- Modify: `lib/app/theme/app_colors.dart`

- [ ] **Step 1: Write failing state and navigation tests**

Use injectable boundaries:

```dart
typedef OrderListLoader = Future<Json> Function(String status);
typedef OrderTargetNavigator = Future<void> Function(String target);
typedef OrderAdmissionNavigator = Future<void> Function(String productId);
```

Assert initial request `4`, title, API content, no fixed Confirm, Loading,
Error/Retry, Empty, filter changes, and pull-to-refresh. Add items for `174`,
`180`, and a non-action status. Assert `174` uses `AppColors.primary`, `180`
uses `AppColors.alert`, and the third item has no action. Verify:

```dart
expect(find.text('Repay Now'), findsOneWidget);
expect(find.byKey(const Key('mineOrderConfirm')), findsNothing);
expect(targets, ['/repayment-detail?orderNo=ORDER-174']);
expect(admissionProductIds, ['180']);
```

Also tap card content and assert it dispatches `methodical` independently.

- [ ] **Step 2: Run tests and verify RED**

Run `flutter test --concurrency=1 test/features/orders/mine_order_list_page_test.dart`.

Expected: compile failure because `MineOrderListPage` does not exist.

- [ ] **Step 3: Implement loading and stale-response protection**

The default loader calls `Get.find<ApiClient>().orderList(status: status)` and
returns `response.states`. Initialize from `Get.arguments['initialStatus']`.
Wrap an always-scrollable list in `RefreshIndicator` and render explicit
Loading, Error/Retry, Empty, and populated states.

Guard filter races with:

```dart
final generation = ++_loadGeneration;
final states = await _loadOrders(_selectedStatus.code);
if (!mounted || generation != _loadGeneration) return;
```

- [ ] **Step 4: Implement the Lanhu card and exact action branch**

Reuse existing `AppColors` tokens. Add semantic tokens only for missing exact
values `(146,149,151,1)`, `(60,60,60,1)`, and `(153,153,153,1)`.

```dart
if (item.showAction)
  SizedBox(
    width: double.infinity,
    height: ScreenAdapter.height(38),
    child: ElevatedButton(
      key: ValueKey('orderAction-${item.orderId}'),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            item.usesBlueAction ? AppColors.primary : AppColors.alert,
      ),
      onPressed: () => _handleAction(item),
      child: Text(item.actionText),
    ),
  );
```

```dart
Future<void> _handleAction(OrderListItem item) async {
  if (item.actionTarget.isNotEmpty) {
    await _navigateTarget(item.actionTarget);
    return;
  }
  if (item.productId.isNotEmpty) {
    await _startAdmission(item.productId);
  }
}
```

Use `Image.network` for `creasing` with a fixed-size empty `errorBuilder`.
Reuse `AppAssets.identityBack`; do not download status-bar, home-indicator, or
sample product-logo slices. Do not render early-settlement UI from `demising`,
`zirconia`, or `developments`. A card whose `methodical` is empty performs no
navigation.

- [ ] **Step 5: Run tests and verify GREEN**

Run
`flutter test --concurrency=1 test/features/orders/mine_order_list_page_test.dart`.
Expected: all page tests pass without overflow.

### Task 4: Register The Route And Wire Mine Shortcuts

**Files:**
- Modify: `lib/app/routes/app_routes.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/navigation/navigation_helper.dart`
- Modify: `lib/features/mine/mine_page.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing route tests**

Update the logging-only Mine test: each order shortcut must open
`MineOrderListPage` with `4`, `7`, `6`, or `5`, then pop before testing the next
shortcut. Preserve logging assertions for unrelated Mine actions.

- [ ] **Step 2: Run tests and verify RED**

Run `flutter test --concurrency=1 test/widget_test.dart`.

Expected: shortcuts still log and the route is absent.

- [ ] **Step 3: Add the route and helper**

Add `AppRoutes.mineOrderList = '/mine/orders'`, register the page, and add:

```dart
static Future<T?>? toMineOrderList<T extends Object?>({
  MineOrderStatus initialStatus = MineOrderStatus.all,
}) {
  return Get.toNamed<T>(
    AppRoutes.mineOrderList,
    arguments: {'initialStatus': initialStatus.code},
  );
}
```

Do not alter the current user-authored certification changes around this new
helper.

- [ ] **Step 4: Wire each existing shortcut**

Replace `_OrderShortcut.logLabel` with `MineOrderStatus status` and use:

```dart
onTap: () => NavigationHelper.toMineOrderList(initialStatus: status),
```

Assign `all`, `unpaid`, `late`, and `paid` while retaining current keys,
labels, assets, dimensions, and Mine layout.

- [ ] **Step 5: Run tests and verify GREEN**

Run `flutter test --concurrency=1 test/widget_test.dart`.
Expected: all Mine tests pass.

### Task 5: Refresh After Child Routes Return

**Files:**
- Create: `lib/app/navigation/app_route_observer.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/features/orders/mine_order_list_page.dart`
- Modify: `test/features/orders/mine_order_list_page_test.dart`

- [ ] **Step 1: Write failing lifecycle tests**

Pump parent and child routes, navigate to the child, pop, and assert:

```dart
expect(requestedStatuses, ['4', '4']);
```

Add a two-completer race test: select a new filter before the first response
completes, complete the new response first, then the old response, and assert
only the new item remains.

- [ ] **Step 2: Run tests and verify RED**

Run
`flutter test --concurrency=1 test/features/orders/mine_order_list_page_test.dart`.
Expected: the route-return test fails because the page does not reload after
pop.

- [ ] **Step 3: Add and register the observer**

```dart
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
```

Register it in `GetMaterialApp.navigatorObservers`. Make page state
`RouteAware`, subscribe once in `didChangeDependencies`, unsubscribe in
`dispose`, and call `_loadOrders()` from `didPopNext()`.

- [ ] **Step 4: Run tests and verify GREEN**

Run
`flutter test --concurrency=1 test/features/orders/mine_order_list_page_test.dart`.
Expected: lifecycle and race tests pass.

### Task 6: Fidelity And Regression Verification

**Files:**
- Verify all files touched by Tasks 1-5.

- [ ] **Step 1: Format only touched Dart files**

Run `dart format` with explicit Task 1-5 paths. Do not format unrelated dirty
files.

- [ ] **Step 2: Run focused tests serially**

```bash
flutter test --concurrency=1 \
  test/core/network/api_client_test.dart \
  test/features/orders/order_list_item_test.dart \
  test/features/orders/mine_order_list_page_test.dart \
  test/widget_test.dart
```

Expected: all focused tests pass.

- [ ] **Step 3: Run static analysis**

Run `flutter analyze` on the touched production and test paths. Expected: no
new diagnostics.

- [ ] **Step 4: Audit Lanhu fidelity**

At 375 logical pixels, verify header, tabs, underline, 343-wide cards,
12-pixel card padding, 8-pixel card radius, 4-pixel inner radius, exact colors,
fixed action height, clipping, and element completeness. Intentional
adaptations are limited to safe-area handling, scrolling dynamic data,
Loading/Error/Empty states, and removal of the uncontracted Confirm footer.

- [ ] **Step 5: Inspect the final diff**

```bash
git diff --check
git diff --stat
git status --short
```

Confirm every new line traces to this feature. Preserve all pre-existing dirty
changes, especially `navigation_helper.dart`; do not stage or commit production
changes unless the user explicitly requests it.

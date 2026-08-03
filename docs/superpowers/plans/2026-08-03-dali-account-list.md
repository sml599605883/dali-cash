# Dali Cash Account List Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the native Dali Cash account-selection page, connect WebView `changeAccount` and account-change bind success to a fresh WebView, and preserve normal bind-card reporting.

**Architecture:** Keep the Dali account contract in a pure parser/model file and keep asynchronous loading, selection, submission, and layout in a dedicated page. Navigation remains centralized in `NavigationHelper`; WebView and bind-card only delegate semantic arguments and outcomes. Rename all supplied Lanhu slices into an `assets/account/` namespace before wiring them through `AppAssets`.

**Tech Stack:** Flutter, Dart, GetX navigation, Dio-backed `ApiClient`, `flutter_test`, existing `ScreenAdapter`, `AppColors`, and `AppAssets`.

---

## File map

- Create `lib/features/account/account_list_data.dart`: tolerant Dali response parsing and semantic account models.
- Create `lib/features/account/account_list_page.dart`: loading, selection, submission, error/empty states, and Lanhu layout.
- Create `test/features/account/account_list_data_test.dart`: field-contract and malformed-payload tests.
- Create `test/features/account/account_list_page_test.dart`: page state, geometry, navigation, and submission tests.
- Rename the seven root-level Chinese assets into `assets/account/` with semantic names.
- Modify `lib/app/resources/app_assets.dart`: semantic account asset constants.
- Reuse `lib/app/theme/app_colors.dart`: existing tokens already match every account-page design color.
- Modify `pubspec.yaml`: include `assets/account/` and remove reliance on the original filenames.
- Modify `lib/app/routes/app_routes.dart` and `lib/app/app.dart`: register the account-list route.
- Modify `lib/app/navigation/navigation_helper.dart`: open the account list and prune the complete account-change stack.
- Modify `test/app/navigation/navigation_helper_test.dart`: route arguments, back behavior, and pruning coverage.
- Modify `lib/features/webview/dali_webview_page.dart`: existing-account branch opens the native account list.
- Modify `test/features/webview/dali_webview_page_test.dart`: verify list-versus-bind routing.
- Modify `lib/features/certification/bind_card/bind_card_page.dart`: skip scene 8 in account-change mode and use complete stack replacement.
- Modify `test/features/certification/bind_card/bind_card_page_test.dart`: normal/account-change reporting and redirect coverage.
- Reuse the already-added `ApiClient.userAccountList` and `ApiClient.changeOrderAccount` methods and their exact-field tests.

### Task 1: Rename and register the account assets

**Files:**
- Rename: `assets/编组 5@3x.png` -> `assets/account/account_bank_label.png`
- Rename: `assets/编组 5@3x(1).png` -> `assets/account/account_wallet_label.png`
- Rename: `assets/编组 5@3x(2).png` -> `assets/account/account_cash_pickup_label.png`
- Rename: `assets/选择@3x.png` -> `assets/account/account_option_selected.png`
- Rename: `assets/选择@3x(1).png` -> `assets/account/account_option_unselected.png`
- Rename: `assets/添加@3x.png` -> `assets/account/account_add_icon.png`
- Rename: `assets/矩形@3x.png` -> `assets/account/account_add_method_border.png`
- Modify: `lib/app/resources/app_assets.dart`
- Modify: `pubspec.yaml`
- Create: `test/app/resources/app_assets_test.dart`

- [ ] **Step 1: Write the failing resource-contract test**

```dart
import 'dart:io';

import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account assets use semantic names and exist', () {
    const assets = <String>[
      AppAssets.accountBankLabel,
      AppAssets.accountWalletLabel,
      AppAssets.accountCashPickupLabel,
      AppAssets.accountOptionSelected,
      AppAssets.accountOptionUnselected,
      AppAssets.accountAddIcon,
      AppAssets.accountAddMethodBorder,
    ];

    expect(assets.every((path) => path.startsWith('assets/account/')), isTrue);
    for (final path in assets) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
```

- [ ] **Step 2: Run the test and verify it fails before the rename**

Run: `flutter test --concurrency=1 test/app/resources/app_assets_test.dart`

Expected: compilation fails because the seven `AppAssets.account...` constants do not exist.

- [ ] **Step 3: Rename the binary assets without changing their pixels**

```bash
mkdir -p assets/account
mv 'assets/编组 5@3x.png' assets/account/account_bank_label.png
mv 'assets/编组 5@3x(1).png' assets/account/account_wallet_label.png
mv 'assets/编组 5@3x(2).png' assets/account/account_cash_pickup_label.png
mv 'assets/选择@3x.png' assets/account/account_option_selected.png
mv 'assets/选择@3x(1).png' assets/account/account_option_unselected.png
mv 'assets/添加@3x.png' assets/account/account_add_icon.png
mv 'assets/矩形@3x.png' assets/account/account_add_method_border.png
```

Verify dimensions remain `216x165`, `276x165`, `396x165`, `72x72`, `72x72`, `48x48`, and `1029x144` respectively with `sips -g pixelWidth -g pixelHeight assets/account/*.png`.

- [ ] **Step 4: Add semantic asset constants and register the directory**

Add to `AppAssets`:

```dart
static const accountBankLabel = 'assets/account/account_bank_label.png';
static const accountWalletLabel = 'assets/account/account_wallet_label.png';
static const accountCashPickupLabel =
    'assets/account/account_cash_pickup_label.png';
static const accountOptionSelected =
    'assets/account/account_option_selected.png';
static const accountOptionUnselected =
    'assets/account/account_option_unselected.png';
static const accountAddIcon = 'assets/account/account_add_icon.png';
static const accountAddMethodBorder =
    'assets/account/account_add_method_border.png';
```

Add the semantic account directory to the existing asset list:

```yaml
    - assets/account/
```

- [ ] **Step 5: Run the resource test**

Run: `flutter test --concurrency=1 test/app/resources/app_assets_test.dart`

Expected: PASS and no root-level Chinese account asset remains.

- [ ] **Step 6: Commit the asset namespace**

```bash
git add assets/account lib/app/resources/app_assets.dart pubspec.yaml test/app/resources/app_assets_test.dart
git commit -m "feat: register semantic account assets"
```

### Task 2: Parse the Dali account-list contract

**Files:**
- Create: `lib/features/account/account_list_data.dart`
- Create: `test/features/account/account_list_data_test.dart`

- [ ] **Step 1: Write field-mapping and malformed-payload tests**

```dart
import 'package:dali_cash/core/json/json.dart';
import 'package:dali_cash/features/account/account_list_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses documented Dali group and row fields', () {
    final sections = parseAccountSections(Json({
      'clingiest': [
        {
          'rapscallion': '2',
          'pater': 'Bank',
          'alodia': 'https://img.test/bank-type.png',
          'jambes': [
            {
              'hoover': 'bind-1',
              'leachate': 'https://img.test/bdo.png',
              'precolonial': 0,
              'filmcards': 'BDO',
              'emptiable': '**** 1234',
              'nonbehavioral': {
                'rattlesnakes': 'Ana',
                'monerans': 'M',
                'sloid': 'Santos',
              },
              'exploitable': 1,
              'sociologeses': 'bank',
            },
          ],
        },
      ],
    }));

    expect(sections, hasLength(1));
    expect(sections.single.title, 'Bank');
    expect(sections.single.typeIconUrl, 'https://img.test/bank-type.png');
    final account = sections.single.accounts.single;
    expect(account.bindId, 'bind-1');
    expect(account.providerName, 'BDO');
    expect(account.accountValue, '**** 1234');
    expect(account.logoUrl, 'https://img.test/bdo.png');
    expect(account.isMain, isTrue);
    expect(account.isUnderMaintenance, isTrue);
    expect(account.firstName, 'Ana');
    expect(account.middleName, 'M');
    expect(account.lastName, 'Santos');
  });

  test('ignores rows without bindId and retains unknown titled groups', () {
    final sections = parseAccountSections(Json({
      'clingiest': [
        {
          'pater': 'Over the counter',
          'jambes': [
            {'hoover': '', 'filmcards': 'Ignored'},
            {'hoover': 'bind-2', 'filmcards': 'Cebuana'},
          ],
        },
        {'pater': '', 'jambes': 'invalid'},
      ],
    }));

    expect(sections.single.title, 'Over the counter');
    expect(sections.single.accounts.single.bindId, 'bind-2');
  });

  test('returns an empty immutable result for malformed data', () {
    expect(parseAccountSections(Json({'clingiest': 'invalid'})), isEmpty);
    expect(parseAccountSections(Json(null)), isEmpty);
  });
}
```

- [ ] **Step 2: Run the parser tests and verify failure**

Run: `flutter test --concurrency=1 test/features/account/account_list_data_test.dart`

Expected: FAIL because `account_list_data.dart` and its types do not exist.

- [ ] **Step 3: Implement focused immutable models and tolerant parsing**

Implement these public boundaries in `account_list_data.dart`:

```dart
class AccountListSection {
  const AccountListSection({
    required this.cardType,
    required this.title,
    required this.typeIconUrl,
    required this.accounts,
  });

  final String cardType;
  final String title;
  final String typeIconUrl;
  final List<AccountListItem> accounts;
}

class AccountListItem {
  const AccountListItem({
    required this.bindId,
    required this.type,
    required this.logoUrl,
    required this.providerName,
    required this.accountValue,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.isMain,
    required this.isUnderMaintenance,
  });

  final String bindId;
  final String type;
  final String logoUrl;
  final String providerName;
  final String accountValue;
  final String firstName;
  final String middleName;
  final String lastName;
  final bool isMain;
  final bool isUnderMaintenance;
}

List<AccountListSection> parseAccountSections(Json states) {
  final result = <AccountListSection>[];
  for (final group in states['clingiest'].listValue) {
    final title = group['pater'].stringValue.trim();
    if (title.isEmpty) continue;
    final accounts = <AccountListItem>[];
    for (final row in group['jambes'].listValue) {
      final bindId = row['hoover'].stringValue.trim();
      if (bindId.isEmpty) continue;
      final option = row['nonbehavioral'];
      accounts.add(AccountListItem(
        bindId: bindId,
        type: row['sociologeses'].stringValue.trim(),
        logoUrl: row['leachate'].stringValue.trim(),
        providerName: row['filmcards'].stringValue.trim(),
        accountValue: row['emptiable'].stringValue.trim(),
        firstName: option['rattlesnakes'].stringValue.trim(),
        middleName: option['monerans'].stringValue.trim(),
        lastName: option['sloid'].stringValue.trim(),
        isMain: row['exploitable'].boolValue,
        isUnderMaintenance: row['precolonial'].intOrNull == 0,
      ));
    }
    if (accounts.isEmpty) continue;
    result.add(AccountListSection(
      cardType: group['rapscallion'].stringValue.trim(),
      title: title,
      typeIconUrl: group['alodia'].stringValue.trim(),
      accounts: List<AccountListItem>.unmodifiable(accounts),
    ));
  }
  return List<AccountListSection>.unmodifiable(result);
}
```

- [ ] **Step 4: Run the parser tests**

Run: `flutter test --concurrency=1 test/features/account/account_list_data_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the parser**

```bash
git add lib/features/account/account_list_data.dart test/features/account/account_list_data_test.dart
git commit -m "feat: parse Dali account options"
```

### Task 3: Build the account-list page states and Lanhu layout

**Files:**
- Create: `lib/features/account/account_list_page.dart`
- Create: `test/features/account/account_list_page_test.dart`

- [ ] **Step 1: Write page tests for loading, default selection, all layouts, maintenance, error, empty, and duplicate submission**

Create an injectable page contract:

```dart
typedef AccountListLoad = Future<Json> Function(String productId);
typedef AccountListSubmit = Future<String> Function({
  required String orderNo,
  required String bindId,
});
typedef AccountListAddMethod = Future<void> Function({
  required String productId,
  required String orderNo,
});
typedef AccountListReplace = Future<void> Function(String url);
```

Tests must assert these stable keys and outcomes:

```dart
expect(find.byKey(const Key('accountListLoading')), findsOneWidget);
expect(find.byKey(const Key('accountListItem-bind-bank')), findsOneWidget);
expect(find.byKey(const Key('accountListItem-bind-wallet')), findsOneWidget);
expect(find.byKey(const Key('accountListItem-bind-cash')), findsOneWidget);
expect(find.text('Receipt Account'), findsNWidgets(2));
expect(find.text('First Name'), findsOneWidget);
expect(find.text('Maintenance'), findsOneWidget);
expect(find.byKey(const Key('accountListConfirm')), findsOneWidget);
expect(tester.getSize(find.byKey(const Key('accountListContent'))).width, 343);
```

Also verify:

```dart
await tester.tap(find.byKey(const Key('accountListItem-bind-bank')));
await tester.tap(find.byKey(const Key('accountListConfirm')));
await tester.tap(find.byKey(const Key('accountListConfirm')));
expect(submissions, ['ORDER-1:bind-bank']);
expect(replacements, ['https://h5.test/changed']);
```

For missing arguments, assert no loader call and the stable messages `Missing product information` or `Missing order information`. For request failure, assert `Retry` invokes the loader again. For empty groups, assert Add other payment methods remains visible and Confirm is disabled.

- [ ] **Step 2: Run the page tests and verify failure**

Run: `flutter test --concurrency=1 test/features/account/account_list_page_test.dart`

Expected: FAIL because `AccountListPage` does not exist.

- [ ] **Step 3: Implement page state with narrow injected boundaries**

The page constructor must expose test seams without introducing a controller layer:

```dart
const AccountListPage({
  super.key,
  this.productId = '',
  this.orderNo = '',
  this.load,
  this.submit,
  this.addMethod,
  this.replace,
  this.showError,
});
```

State rules:

```dart
final main = sections
    .expand((section) => section.accounts)
    .where((account) => account.isMain)
    .firstOrNull;
_selected = main;

if (_submitting || _selected == null) return;
setState(() => _submitting = true);
try {
  final url = await _submit(orderNo: _orderNo, bindId: _selected!.bindId);
  if (url.trim().isEmpty) {
    throw ApiBusinessException('Missing account change result url');
  }
  await _replace(url.trim());
} catch (error) {
  if (mounted) await _showError(ApiErrorMessage.resolve(error));
} finally {
  if (mounted) setState(() => _submitting = false);
}
```

Default production boundaries use the existing API and semantic navigation
helpers:

```dart
Future<Json> _defaultLoad(String productId) async {
  final response = await Get.find<ApiClient>().userAccountList(
    productId: productId,
  );
  return response.ensureSuccess().states;
}

Future<String> _defaultSubmit({
  required String orderNo,
  required String bindId,
}) async {
  final response = await Get.find<ApiClient>().changeOrderAccount(
    orderNo: orderNo,
    bindId: bindId,
  );
  return response.ensureSuccess().states['misericorde'].stringValue.trim();
}

Future<void> _defaultAddMethod({
  required String productId,
  required String orderNo,
}) async {
  final route = NavigationHelper.toBindCard<void>(
    productId: productId,
    orderNo: orderNo,
    isAccountChange: true,
  );
  if (route != null) await route;
}

Future<void> _defaultReplace(String url) async {
  NavigationHelper.replaceAccountChangeFlowWithWebView<void>(url: url);
}
```

Use `Scaffold`, `SafeArea(bottom: false)`, a 45-high header titled `Loan Confirmation`, scrollable content with 16 horizontal padding, a 343-wide content column, and a fixed white footer containing a 48-high Confirm button. Reuse `AppColors.pageBackground`, `surface`, `personalInformationFieldBackground`, `textPrimary`, `recommendationCaption`, `alert`, `primary`, and `personalInformationFooterShadow`; do not add duplicate color constants. Maintenance rows remain tappable. Network logos use `Image.network(..., errorBuilder: ...)`, falling back to the group icon and then a fixed empty box.

Cash Pickup rows show three label/value lines from `firstName`, `middleName`, and `lastName`; Bank and E-wallet show `Receipt Account` plus `accountValue`. The Add other payment methods control uses the renamed border and add icon assets.

- [ ] **Step 4: Run page tests**

Run: `flutter test --concurrency=1 test/features/account/account_list_page_test.dart`

Expected: PASS with no overflow exception at 375x812 and 375x896 test surfaces.

- [ ] **Step 5: Commit the native page**

```bash
git add lib/features/account/account_list_page.dart test/features/account/account_list_page_test.dart
git commit -m "feat: add Dali account selection page"
```

### Task 4: Register account navigation and exact stack replacement

**Files:**
- Modify: `lib/app/routes/app_routes.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/navigation/navigation_helper.dart`
- Modify: `test/app/navigation/navigation_helper_test.dart`

- [ ] **Step 1: Write failing route and pruning tests**

Add `AppRoutes.accountList = '/account-list'` to the test route table and assert:

```dart
NavigationHelper.toAccountList<void>(
  productId: 'product-2',
  orderNo: 'ORDER-2',
);
await tester.pumpAndSettle();
expect(Get.currentRoute, AppRoutes.accountList);
expect(Get.arguments, {
  'highlands': 'product-2',
  'saggards': 'ORDER-2',
});
```

Build `home -> old WebView -> account list -> bind card`, invoke the replacement, then assert the fresh WebView is current and one Back returns to home. Add the direct `home -> old WebView -> account list` variant as well.

- [ ] **Step 2: Run the focused navigation test and verify failure**

Run: `flutter test --concurrency=1 test/app/navigation/navigation_helper_test.dart`

Expected: FAIL because the account-list route/helper and full account-flow pruning do not exist.

- [ ] **Step 3: Add the route and semantic navigation methods**

Add:

```dart
static const accountList = '/account-list';
```

Register `AccountListPage` in `DaliCashApp`. Add:

```dart
static Future<T?>? toAccountList<T extends Object?>({
  required String productId,
  required String orderNo,
}) {
  if (Get.currentRoute == AppRoutes.accountList) return null;
  return Get.toNamed<T>(
    AppRoutes.accountList,
    arguments: {
      'highlands': productId.trim(),
      'saggards': orderNo.trim(),
    },
  );
}
```

Replace the boolean `removeBindCard` API with a semantic method that removes only the active account-change routes and exactly one previous WebView:

```dart
static Future<T?>? replaceAccountChangeFlowWithWebView<T extends Object?>({
  required String url,
  String? title,
}) {
  final uri = _webUri(url);
  if (uri == null) return null;
  var removedWebView = false;
  return Get.offNamedUntil<T>(AppRoutes.webView, (route) {
    final name = route.settings.name;
    if (name == AppRoutes.accountList || name == AppRoutes.bindCard) {
      return false;
    }
    if (!removedWebView && name == AppRoutes.webView) {
      removedWebView = true;
      return false;
    }
    return true;
  }, arguments: {'url': uri.toString(), 'title': title});
}
```

Keep the existing generic `replaceWebView` for retry-order behavior, which removes only one WebView and must not gain account-specific pruning.

- [ ] **Step 4: Run navigation tests**

Run: `flutter test --concurrency=1 test/app/navigation/navigation_helper_test.dart`

Expected: PASS for both direct account confirmation and bind-card account-change paths.

- [ ] **Step 5: Commit navigation**

```bash
git add lib/app/routes/app_routes.dart lib/app/app.dart lib/app/navigation/navigation_helper.dart test/app/navigation/navigation_helper_test.dart
git commit -m "feat: route Dali account change flow"
```

### Task 5: Route WebView changeAccount to the native page

**Files:**
- Modify: `lib/features/webview/dali_webview_page.dart`
- Modify: `test/features/webview/dali_webview_page_test.dart`

- [ ] **Step 1: Replace the source-string assertion with behavioral routing tests**

Add this pure routing decision next to `hasDaliWebViewAccounts`:

```dart
enum DaliAccountDestination { accountList, bindCard }

DaliAccountDestination daliAccountDestination(Json states) =>
    states['clingiest'].listValue.isEmpty
        ? DaliAccountDestination.bindCard
        : DaliAccountDestination.accountList;
```

Test non-empty `clingiest` selects `accountList`, empty or malformed data selects `bindCard`, and remove the expectation for the old `account list page is not available` log.

- [ ] **Step 2: Run WebView tests and verify failure**

Run: `flutter test --concurrency=1 test/features/webview/dali_webview_page_test.dart test/features/webview/dali_webview_action_coordinator_test.dart`

Expected: FAIL because the current non-empty branch only logs.

- [ ] **Step 3: Wire the existing-account branch**

Replace the log-only branch with:

```dart
if (hasDaliWebViewAccounts(states)) {
  NavigationHelper.toAccountList<void>(
    productId: productId,
    orderNo: orderNo,
  );
  return;
}
NavigationHelper.toBindCard<void>(
  productId: productId,
  orderNo: orderNo,
  isAccountChange: true,
);
```

Do not move loading or validation into the page coordinator; the coordinator continues to validate H5 parameters and the capability callback performs the API/navigation decision.

- [ ] **Step 4: Run WebView tests**

Run: `flutter test --concurrency=1 test/features/webview/dali_webview_page_test.dart test/features/webview/dali_webview_action_coordinator_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit WebView routing**

```bash
git add lib/features/webview/dali_webview_page.dart test/features/webview/dali_webview_page_test.dart
git commit -m "feat: open account list from WebView"
```

### Task 6: Align account-change bind success and scene-8 reporting

**Files:**
- Modify: `lib/features/certification/bind_card/bind_card_page.dart`
- Modify: `test/features/certification/bind_card/bind_card_page_test.dart`

- [ ] **Step 1: Add a failing test that account-change success does not report scene 8**

Extend the existing account-change test:

```dart
final reports = <String>[];
final replacements = <String>[];
await _pumpPage(
  tester,
  orderNo: 'ORDER-3',
  isAccountChange: true,
  load: (_) async =>
      _bindCardData(channelValue: '100', accountValue: '09171234567'),
  save: (productId, cardType, fields, liveness) async =>
      ApiResponse(code: 0, message: '', states: Json({'hoover': '5326'})),
  changeAccount: ({required orderNo, required bindId}) async => ApiResponse(
    code: 0,
    message: '',
    states: Json({'misericorde': 'https://h5.example/changed'}),
  ),
  replaceWithWebView: ({required url}) async => replacements.add(url),
  reportRisk: (productId, startedAtSeconds) async {
    reports.add('$productId:$startedAtSeconds');
  },
);
await tester.pumpAndSettle();
await tester.tap(find.byKey(const Key('bindCardUpload')));
await tester.pumpAndSettle();

expect(reports, isEmpty);
expect(replacements, ['https://h5.example/changed']);
```

Keep the existing normal-success assertion `reports == ['product-42:123']` so normal bind certification still reports scene 8.

- [ ] **Step 2: Run the bind-card tests and verify failure**

Run: `flutter test --concurrency=1 test/features/certification/bind_card/bind_card_page_test.dart`

Expected: FAIL because `_completeSuccess` currently reports before checking `_isAccountChange`.

- [ ] **Step 3: Move reporting into the normal-bind branch and use semantic replacement**

Structure `_completeSuccess` as:

```dart
Future<void> _completeSuccess(ApiResponse response) async {
  if (_isAccountChange) {
    final orderNo = _orderNo;
    if (orderNo.isEmpty) {
      await _showError('Missing order information');
      return;
    }
    final bindId = response.states['hoover'].stringValue.trim();
    if (bindId.isEmpty) {
      await _showError('Missing binding information');
      return;
    }
    final changed = await (widget.changeAccount ?? _defaultChangeAccount)(
      orderNo: orderNo,
      bindId: bindId,
    );
    final url = changed.ensureSuccess().states['misericorde'].stringValue.trim();
    if (url.isEmpty) {
      await _showError('Missing account change result url');
      return;
    }
    await (widget.replaceWithWebView ?? _defaultReplaceWithWebView)(url: url);
    return;
  }

  unawaited(
    (widget.reportRisk ?? _defaultReportRisk)(_productId, _startedAtSeconds),
  );
  await (widget.continueFlow ?? NavigationHelper.continueProductDetailFlow)(
    _productId,
  );
}
```

Simplify `BindCardWebViewReplacement` to accept only `required String url`; `_defaultReplaceWithWebView` delegates to `NavigationHelper.replaceAccountChangeFlowWithWebView`.

- [ ] **Step 4: Run bind-card tests**

Run: `flutter test --concurrency=1 test/features/certification/bind_card/bind_card_page_test.dart`

Expected: PASS; account-change reports nothing, normal success reports once, missing order/bind/redirect keeps the current route.

- [ ] **Step 5: Commit bind-card parity**

```bash
git add lib/features/certification/bind_card/bind_card_page.dart test/features/certification/bind_card/bind_card_page_test.dart
git commit -m "fix: align account change bind completion"
```

### Task 7: Run integrated verification and review the final diff

**Files:**
- Verify all files changed in Tasks 1-6.

- [ ] **Step 1: Run focused account and WebView tests serially**

Run:

```bash
flutter test --concurrency=1 \
  test/app/resources/app_assets_test.dart \
  test/features/account/account_list_data_test.dart \
  test/features/account/account_list_page_test.dart \
  test/app/navigation/navigation_helper_test.dart \
  test/features/webview/dali_webview_page_test.dart \
  test/features/webview/dali_webview_action_coordinator_test.dart \
  test/features/certification/bind_card/bind_card_page_test.dart \
  test/core/network/api_client_test.dart
```

Expected: all tests pass.

- [ ] **Step 2: Run static analysis on the touched feature surface**

Run:

```bash
flutter analyze \
  lib/features/account \
  lib/features/webview \
  lib/features/certification/bind_card \
  lib/app/navigation \
  lib/app/routes \
  lib/app/resources \
  lib/app/theme
```

Expected: `No issues found!`

- [ ] **Step 3: Check formatting and whitespace**

Run:

```bash
dart format --output=none --set-exit-if-changed \
  lib/features/account \
  test/features/account \
  lib/features/webview/dali_webview_page.dart \
  lib/features/certification/bind_card/bind_card_page.dart \
  lib/app/navigation/navigation_helper.dart
git diff --check
```

Expected: both commands exit 0.

- [ ] **Step 4: Review scope and asset names**

Run:

```bash
find assets/account -maxdepth 1 -type f | sort
git status --short
git diff --stat
```

Expected: exactly seven semantic account PNG names, no original Chinese account filenames, and no unrelated file deletion or security configuration change.

- [ ] **Step 5: Commit any verification-only corrections**

```bash
git add \
  lib/features/account \
  test/features/account \
  lib/features/webview/dali_webview_page.dart \
  test/features/webview/dali_webview_page_test.dart \
  lib/features/certification/bind_card/bind_card_page.dart \
  test/features/certification/bind_card/bind_card_page_test.dart \
  lib/app/navigation/navigation_helper.dart \
  test/app/navigation/navigation_helper_test.dart \
  lib/app/routes/app_routes.dart \
  lib/app/app.dart \
  lib/app/resources/app_assets.dart \
  test/app/resources/app_assets_test.dart \
  assets/account \
  pubspec.yaml
git commit -m "test: verify Dali account change flow"
```

Skip this commit when verification required no corrective changes.

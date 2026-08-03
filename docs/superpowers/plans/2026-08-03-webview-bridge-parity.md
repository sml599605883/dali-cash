# Dali Cash WebView Bridge Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Dali Cash's iOS in-app WebView, all documented H5 bridge actions, iOS StoreKit rating, retry/account-change flows, and log-only handling for unavailable account-list and confirm-retention UI.

**Architecture:** Keep message parsing and action dispatch independent from `InAppWebViewController`; let the WebView page own controller/lifecycle state and `NavigationHelper` own route stacks. Extend Dali API, native bridge, and bind-card behavior with Dali fields instead of copying Kaibigan route contracts or source structure.

**Tech Stack:** Flutter, Dart, GetX, Dio, `flutter_inappwebview`, `url_launcher`, Swift UIKit/StoreKit, Flutter test.

---

## File Map

- Create `lib/features/webview/dali_webview_contract.dart`, `dali_webview_action_coordinator.dart`, and `dali_webview_page.dart`.
- Create matching tests in `test/features/webview/`.
- Modify dependency, API, route/navigation, native bridge, and bind-card files plus their focused tests.
- Preserve the five existing uncommitted product-detail files and merge additions into `NavigationHelper` and `ApiClient`.

### Task 1: Dependencies And Bridge Contract

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`
- Create: `lib/features/webview/dali_webview_contract.dart`
- Create: `test/features/webview/dali_webview_contract_test.dart`

- [ ] **Step 1: Write the failing contract test**

```dart
expect(DaliWebViewContract.handler, 'ph_dali_cash_ios');
expect(DaliWebViewActions.uploadRisk, 'dali_cash_RbGtlAKg2Hsx7x5');
expect(DaliWebViewActions.openGooglePlay, 'dali_cash_HjU4mCaWf9VcOI6');
expect(DaliWebViewActions.openUrl, 'dali_cash_dudAaHWAtJmjS2T');
expect(DaliWebViewActions.close, 'dali_cash_jWPoDsrg054lhUC');
expect(DaliWebViewActions.home, 'dali_cash_Ax2ivGQo70e2KIR');
expect(DaliWebViewActions.grade, 'dali_cash_L9ePULguB5v2O84');
expect(DaliWebViewActions.retryOrder, 'dali_cash_U5sqmkouwbyYVRT');
expect(DaliWebViewActions.changeAccount, 'dali_cash_dzaSV8NeJkdm0di');
expect(DaliWebViewActions.publicParams, 'dali_cash_YDtfWHIcQnY8cfk');

final request = DaliWebViewRequest.decode({
  'action': DaliWebViewActions.uploadRisk,
  'callbackId': 'cb-1',
  'data': {'thunderstruck': 'product-1', 'saggards': 42},
});
expect(request.callbackId, 'cb-1');
expect(request.data['saggards'], 42);
```

Also test JSON-string envelopes, raw string data, normalized map keys, and malformed JSON returning an empty action without throwing.

- [ ] **Step 2: Run RED**

Run: `flutter test --concurrency=1 test/features/webview/dali_webview_contract_test.dart`

Expected: FAIL because the contract file is absent.

- [ ] **Step 3: Add dependencies and implementation**

Add `flutter_inappwebview: ^6.1.5` and `url_launcher: ^6.3.2`, run `flutter pub get`, then implement immutable request/result models. The result JSON is always `{code, message, data}` and malformed H5 data never escapes as an exception.

- [ ] **Step 4: Run GREEN**

Run: `flutter test --concurrency=1 test/features/webview/dali_webview_contract_test.dart`

Expected: PASS.

### Task 2: Order And Account APIs

**Files:**
- Modify: `lib/core/network/api_client.dart`
- Modify: `test/core/network/api_client_test.dart`

- [ ] **Step 1: Write failing payload tests**

```dart
await client.retryOriginalAccount(orderNo: 'ORDER-1');
expect(adapter.lastRequest!.path, endsWith(ApiEndpoints.userReloan));
expect(adapter.lastRequest!.data, {'saggards': 'ORDER-1'});

await client.userAccountList(productId: 'product-1');
expect(adapter.lastRequest!.data, {
  'highlands': 'product-1',
  'nonanimal': '123456',
  'cornuted': '123456',
});

await client.changeOrderAccount(orderNo: 'ORDER-1', bindId: '5326');
expect(adapter.lastRequest!.data, {
  'titled': 'ORDER-1',
  'hoover': '5326',
  'brontosauruses': '123456',
});
```

- [ ] **Step 2: Run RED**

Run: `flutter test --concurrency=1 test/core/network/api_client_test.dart`

Expected: compile failure because the three methods are absent.

- [ ] **Step 3: Implement minimal wrappers**

Use `ApiEndpoints.userReloan`, `userCardList`, and `changeOrderAccount`, the existing `post` helper, and `_randomDigits(6)`. Keep response parsing in callers.

- [ ] **Step 4: Run GREEN**

Run: `flutter test --concurrency=1 test/core/network/api_client_test.dart`

Expected: PASS.

### Task 3: iOS StoreKit Review

**Files:**
- Modify: `lib/core/client/client_bridge.dart`
- Modify: `ios/Runner/ClientBridgeRegistrar.swift`
- Modify: `test/core/client/client_bridge_test.dart`
- Create: `test/core/client/ios_app_review_bridge_test.dart`

- [ ] **Step 1: Write failing bridge tests**

```dart
await ClientBridge(platform: ClientPlatform.ios).requestAppReview();
expect(calls.single.method, 'requestAppReview');
expect(
  () => ClientBridge(platform: ClientPlatform.android).requestAppReview(),
  throwsA(isA<UnsupportedError>()),
);

expect(registrar, contains('import StoreKit'));
expect(registrar, contains('case "requestAppReview"'));
expect(registrar, contains('activationState == .foregroundActive'));
expect(registrar, contains('SKStoreReviewController.requestReview(in: scene)'));
```

- [ ] **Step 2: Run RED**

Run: `flutter test --concurrency=1 test/core/client/client_bridge_test.dart test/core/client/ios_app_review_bridge_test.dart`

Expected: FAIL because the Flutter method and Swift case are absent.

- [ ] **Step 3: Implement iOS-only review**

Flutter throws `UnsupportedError` off iOS. Swift imports StoreKit, dispatches to main, uses the foreground active `UIWindowScene` on iOS 14+, uses the legacy call below iOS 14, and resolves the Flutter result once.

- [ ] **Step 4: Run GREEN**

Run the same focused command. Expected: PASS.

### Task 4: WebView Navigation Primitives

**Files:**
- Modify: `lib/app/routes/app_routes.dart`
- Modify: `lib/app/navigation/navigation_helper.dart`
- Modify: `test/app/navigation/navigation_helper_test.dart`

- [ ] **Step 1: Write failing route tests**

Use a WebView stub in the test route table:

```dart
await NavigationHelper.navigateRawTarget('https://example.test/details');
await tester.pumpAndSettle();
expect(Get.currentRoute, AppRoutes.webView);
expect(Get.arguments['url'], 'https://example.test/details');

NavigationHelper.replaceWebView<void>(url: 'https://example.test/retry');
await tester.pumpAndSettle();
NavigationHelper.back<void>();
await tester.pumpAndSettle();
expect(find.byKey(const Key('oldWebViewStub')), findsNothing);
```

Test invalid URLs, external-launch injection, and removal of one old WebView plus optional bind-card route.

- [ ] **Step 2: Run RED**

Run: `flutter test --concurrency=1 test/app/navigation/navigation_helper_test.dart`

Expected: FAIL because `AppRoutes.webView`, routing, and replacement are absent.

- [ ] **Step 3: Implement route methods**

Add `toWebView`, `replaceWebView({removeBindCard})`, and injectable `openExternalUri`. Use `Get.offNamedUntil` for replacement and route `DaliDeepLinkKind.webView` to `toWebView` instead of the deferred log. Production external launch uses `LaunchMode.externalApplication`.

- [ ] **Step 4: Run GREEN**

Run the same navigation test. Expected: PASS.

### Task 5: Pure Bridge Action Coordinator

**Files:**
- Create: `lib/features/webview/dali_webview_action_coordinator.dart`
- Create: `test/features/webview/dali_webview_action_coordinator_test.dart`

- [ ] **Step 1: Write failing action tests**

Cover all nine actions, validation, unsupported actions, and thrown callbacks. Retry owns loading and replaces the route:

```dart
final result = await coordinator.dispatch(DaliWebViewRequest.decode({
  'action': DaliWebViewActions.retryOrder,
  'data': {'saggards': 'ORDER-2'},
}));
expect(events, [
  'loading',
  'retry:ORDER-2',
  'replace:https://h5.example/retry',
  'dismiss',
]);
expect(result.code, 0);
```

Google Play logs and succeeds without launch. URL routing distinguishes HTTP(S), `ph`, and external schemes. Public params return the signed map. Close, Home, and grade invoke once.

- [ ] **Step 2: Run RED**

Run: `flutter test --concurrency=1 test/features/webview/dali_webview_action_coordinator_test.dart`

Expected: FAIL because the coordinator is absent.

- [ ] **Step 3: Implement coordinator**

Use narrow injected callbacks for risk, navigation, external launch, signing, retry, change-account, rating, loading, error, and logging. Keep controller types out of this file. Retry calls `replaceWebView`; Google Play logs `Google Play action ignored on iOS: package=<value>`.

- [ ] **Step 4: Run GREEN**

Run the same coordinator test. Expected: PASS.

### Task 6: Bind-Card Account-Change Mode

**Files:**
- Modify: `lib/features/certification/bind_card/bind_card_page.dart`
- Modify: `lib/app/navigation/navigation_helper.dart`
- Modify: `test/features/certification/bind_card/bind_card_page_test.dart`
- Modify: `test/app/navigation/navigation_helper_test.dart`

- [ ] **Step 1: Write failing account-change tests**

Inject a bind response containing `hoover=5326` and a change response containing `misericorde`:

```dart
expect(changeRequests, [
  {'orderNo': 'ORDER-3', 'bindId': '5326'},
]);
expect(replacements, [
  {'url': 'https://h5.example/changed', 'removeBindCard': true},
]);
expect(continuations, isEmpty);
```

Verify normal bind still continues product detail. Missing binding ID, order number, or redirect URL surfaces an error without replacement.

- [ ] **Step 2: Run RED**

Run: `flutter test --concurrency=1 test/features/certification/bind_card/bind_card_page_test.dart test/app/navigation/navigation_helper_test.dart`

Expected: FAIL because account-change mode is absent.

- [ ] **Step 3: Implement account-change success**

Accept `orderNo`, `isAccountChange`, change API, and replacement callbacks. Resolve Dali route arguments `highlands`, `saggards`, and `isAccountChange`. On success:

```dart
if (_isAccountChange) {
  final bindId = response.states['hoover'].stringValue.trim();
  final changed = await changeAccount(orderNo: _orderNo, bindId: bindId);
  final url = changed.ensureSuccess().states['misericorde'].stringValue.trim();
  await replaceWithWebView(url: url, removeBindCard: true);
  return;
}
await normalContinuation(_productId);
```

Keep normal risk and continuation behavior unchanged. Extend `NavigationHelper.toBindCard` without breaking existing callers.

- [ ] **Step 4: Run GREEN**

Run the same bind-card and navigation tests. Expected: PASS.

### Task 7: WebView Page And Capability Wiring

**Files:**
- Create: `lib/features/webview/dali_webview_page.dart`
- Create: `test/features/webview/dali_webview_page_test.dart`
- Modify: `lib/app/app.dart`

- [ ] **Step 1: Write failing helper and wiring tests**

```dart
expect(isInlineDaliWebViewScheme('https'), isTrue);
expect(isInlineDaliWebViewScheme('tel'), isFalse);
expect(shouldCloseDaliWebView(canGoBack: false), isTrue);
expect(
  daliConfirmProductId(
    'https://h5.example/#/Florescences?thunderstruck=product-9',
  ),
  'product-9',
);
expect(
  daliConfirmProductId(
    'https://h5.example/#/SlinkierDesulfured?thunderstruck=product-9',
  ),
  isEmpty,
);
```

Add tests for foreground handler registration/removal, callback JavaScript, main-frame-only errors, stale-controller guards, denied H5 permissions, risk scene `10`, StoreKit injection, exact API response fields, existing-account log, no-account bind-card route, and retry route replacement.

- [ ] **Step 2: Run RED**

Run: `flutter test --concurrency=1 test/features/webview/dali_webview_page_test.dart`

Expected: FAIL because page/helpers are absent.

- [ ] **Step 3: Implement lifecycle and UI**

Build a `WidgetsBindingObserver` page with `PopScope`, AppBar, loading overlay, load-failure retry, and `InAppWebView`. Register `ph_dali_cash_ios` only while resumed. Decode bridge arguments and evaluate `window.ph_dali_cash_ios.handleMessage(...)` only when a callback ID exists. Guard controller identity after awaits, treat only main-frame errors as page failures, deny H5 permissions, and disallow mixed content.

- [ ] **Step 4: Wire Dali capabilities**

- Risk: `DaliReportService` scene `10`.
- URL: HTTP(S) new WebView, `ph` raw route, other scheme external.
- Close/Home: close route or clear to Home tab.
- Grade: `ClientBridge().requestAppReview`.
- Public params: `ApiSignature.buildSignedQuery`.
- Retry: read `misericorde`, then `replaceWebView`.
- Change: read `clingiest`; existing rows log unavailable page, empty rows open account-change bind card.
- Back: `Florescences` reads `thunderstruck`, logs unavailable retention, then performs history/route back.

- [ ] **Step 5: Run GREEN**

Run: `flutter test --concurrency=1 test/features/webview`

Expected: PASS.

### Task 8: Integrated Verification

**Files:**
- Modify only files needed to fix regressions caused by Tasks 1-7.

- [ ] **Step 1: Format changed Dart files**

Run: `dart format lib test`

Expected: completes without errors.

- [ ] **Step 2: Run focused suites serially**

Run: `flutter test --concurrency=1 test/features/webview test/app/navigation/navigation_helper_test.dart test/core/network/api_client_test.dart test/core/client/client_bridge_test.dart test/core/client/ios_app_review_bridge_test.dart test/features/certification/bind_card/bind_card_page_test.dart`

Expected: PASS.

- [ ] **Step 3: Run full tests**

Run: `flutter test --concurrency=1`

Expected: every test passes without GetX registration cascades.

- [ ] **Step 4: Run static validation**

Run: `flutter analyze`

Expected: no issues.

- [ ] **Step 5: Validate the diff**

Run: `git diff --check`

Expected: no output.

Run: `git status --short`

Expected: only intentional product-detail and WebView work is listed.

- [ ] **Step 6: Review behavior against the design**

Confirm all nine actions, exact Dali fields, new-WebView replacement after retry/account change, iOS-only rating, `Florescences` log-and-continue behavior, no account-list page, and no unrelated edits.

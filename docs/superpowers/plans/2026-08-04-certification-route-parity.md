# Certification Route Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Dali certification saves reload the server-controlled next step and replace completed certification routes without introducing a product-detail page.

**Architecture:** Keep `DaliProductNavigationFlow` as the server continuation coordinator. Inject an identity-confirmation continuation callback that defaults to `NavigationHelper.continueProductDetailFlow`, and centralize top-level GetX certification navigation behind one route-pruning helper while leaving the identity upload subflow and account-change bind-card push unchanged.

**Tech Stack:** Flutter, Dart, GetX, flutter_test, existing Dali `NavigationHelper` and `ApiClient`.

---

### Task 1: Continue Identity Submission Through Product Detail

**Files:**
- Modify: `lib/features/certification/identity_confirmation/identity_confirmation_page.dart:21-44,204-239`
- Test: `test/features/certification/identity_confirmation/identity_confirmation_page_test.dart:59-116`

- [ ] **Step 1: Replace the direct-face expectation with a failing continuation test**

Remove the identity-face route fixture and change the submit test to inject and
record the continuation:

```dart
final continuedProducts = <String>[];

home: IdentityConfirmationPage(
  productId: 'product-42',
  cardType: 'PRC',
  apiClient: client,
  recognizedInfo: IdentityRecognitionResult.fromMap({
    'crocidolites': 'OLD NAME',
    'imputes': 'OLD-ID',
    'annealers': '1995/05/31',
  }),
  reportRiskScene: (startTimeSeconds) async {
    riskStarts.add(startTimeSeconds);
  },
  continueProductDetailFlow: (productId) async {
    continuedProducts.add(productId);
  },
),
```

After submission, assert:

```dart
expect(continuedProducts, ['product-42']);
expect(Get.currentRoute, '/');
expect(riskStarts, [100]);
```

Rename the test to
`edits recognized fields and reloads the server-controlled next step`.

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
flutter test test/features/certification/identity_confirmation/identity_confirmation_page_test.dart --plain-name 'edits recognized fields and reloads the server-controlled next step'
```

Expected: compilation fails because `IdentityConfirmationPage` does not yet
accept `continueProductDetailFlow`.

- [ ] **Step 3: Add the minimal continuation dependency**

Import the navigation helper and define the callback beside the existing
identity-confirmation typedefs:

```dart
typedef IdentityConfirmationContinuation =
    Future<void> Function(String productId);
```

Add this optional constructor parameter and field:

```dart
this.continueProductDetailFlow,

final IdentityConfirmationContinuation? continueProductDetailFlow;
```

Replace the hard-coded `Get.toNamed(AppRoutes.identityFace, ...)` block after
save, reporting, dismissal, mounted check, and logging with:

```dart
await (widget.continueProductDetailFlow ??
    NavigationHelper.continueProductDetailFlow)(_productId());
```

Remove the now-unused `AppRoutes` import. Keep the continuation inside the
existing `try` so its errors use the current `ApiErrorMessage` path.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run the command from Step 2.

Expected: PASS; the fake API records the saved identity fields and the injected
continuation records `product-42` without opening face verification directly.

- [ ] **Step 5: Run the complete identity-confirmation test file**

Run:

```bash
flutter test test/features/certification/identity_confirmation/identity_confirmation_page_test.dart --concurrency=1
```

Expected: all identity-confirmation tests pass.

- [ ] **Step 6: Commit the focused change**

```bash
git add lib/features/certification/identity_confirmation/identity_confirmation_page.dart test/features/certification/identity_confirmation/identity_confirmation_page_test.dart
git commit -m "fix: continue identity certification from server state"
```

### Task 2: Replace Completed Certification Routes

**Files:**
- Modify: `lib/app/navigation/navigation_helper.dart:37-52,191-266`
- Test: `test/app/navigation/navigation_helper_test.dart:387-404,915-982`

- [ ] **Step 1: Add a failing route-stack regression**

Extend `_pumpRoutes` with stubs for `AppRoutes.identityUpload` and
`AppRoutes.identityConfirmation`, then add:

```dart
testWidgets('server-selected certification step prunes completed flow', (
  tester,
) async {
  await _pumpRoutes(tester);
  await NavigationHelper.toIdentitySelection<void>(productId: 'product-42');
  Get.toNamed<void>(AppRoutes.identityUpload);
  await tester.pumpAndSettle();
  Get.toNamed<void>(AppRoutes.identityConfirmation);
  await tester.pumpAndSettle();

  await NavigationHelper.toIdentityFace<void>(productId: 'product-42');
  await tester.pumpAndSettle();
  NavigationHelper.back<void>();
  await tester.pumpAndSettle();

  expect(Get.currentRoute, '/');
  expect(find.byKey(const Key('homeStub')), findsOneWidget);
  expect(find.byKey(const Key('identitySelectionStub')), findsNothing);
  expect(find.byKey(const Key('identityUploadStub')), findsNothing);
  expect(find.byKey(const Key('identityConfirmationStub')), findsNothing);
});
```

This construction also proves the two identity-internal pushes remain usable
before the top-level server-selected transition.

- [ ] **Step 2: Run the regression and verify RED**

Run:

```bash
flutter test test/app/navigation/navigation_helper_test.dart --plain-name 'server-selected certification step prunes completed flow'
```

Expected: FAIL because Back returns to identity confirmation instead of Home.

- [ ] **Step 3: Add the shared top-level certification pruning helper**

Add the route set inside `NavigationHelper`:

```dart
static const Set<String> _certificationFlowRouteNames = <String>{
  AppRoutes.identitySelection,
  AppRoutes.identityUpload,
  AppRoutes.identityConfirmation,
  AppRoutes.identityFace,
  AppRoutes.personalInformation,
  AppRoutes.workInformation,
  AppRoutes.emergencyContact,
  AppRoutes.bindCard,
};
```

Add this helper near the concrete route methods:

```dart
static void _openTopLevelCertification(
  String routeName, {
  required Map<String, dynamic> arguments,
}) {
  Get.offNamedUntil<void>(routeName, (route) {
    final name = route.settings.name;
    return name != null &&
        name.isNotEmpty &&
        !_certificationFlowRouteNames.contains(name);
  }, arguments: arguments);
}
```

Update `toIdentitySelection`, `toIdentityFace`, `toPersonalInformation`,
`toWorkInformation`, and `toEmergencyContact` to call this helper with their
existing `highlands` arguments instead of `Get.toNamed`, then keep returning
`Future<T?>.value()` exactly as they do today.

For `toBindCard`, keep the current `Get.toNamed` branch when
`isAccountChange == true`; use `_openTopLevelCertification` for the normal
product-certification branch. Retain each method's current-route guard and
immediate-completion return contract.

- [ ] **Step 4: Run the route-stack regression and verify GREEN**

Run the command from Step 2.

Expected: PASS; Back after the server-selected face route reaches Home.

- [ ] **Step 5: Verify direct dispatch still skips product-detail UI**

Run:

```bash
flutter test test/app/navigation/navigation_helper_test.dart --plain-name 'successful apply handles normalized product detail internally'
```

Expected: PASS with one product-detail request and
`Get.currentRoute == AppRoutes.identitySelection`; no product-detail page is
added or navigated.

- [ ] **Step 6: Run the navigation suite**

Run:

```bash
flutter test test/app/navigation --concurrency=1
```

Expected: all navigation tests pass, including original and obfuscated
server-step mappings and account-change routing.

- [ ] **Step 7: Commit the route change**

```bash
git add lib/app/navigation/navigation_helper.dart test/app/navigation/navigation_helper_test.dart
git commit -m "fix: replace completed certification routes"
```

### Task 3: Regression Verification

**Files:**
- No additional production files.

- [ ] **Step 1: Format only changed Dart files**

```bash
dart format lib/features/certification/identity_confirmation/identity_confirmation_page.dart test/features/certification/identity_confirmation/identity_confirmation_page_test.dart lib/app/navigation/navigation_helper.dart test/app/navigation/navigation_helper_test.dart
```

Expected: formatter exits successfully.

- [ ] **Step 2: Run certification and navigation tests serially**

```bash
flutter test test/features/certification test/app/navigation --concurrency=1
```

Expected: all selected tests pass.

- [ ] **Step 3: Run static analysis**

```bash
flutter analyze
```

Expected: no issues found.

- [ ] **Step 4: Run the full suite serially**

```bash
flutter test --concurrency=1
```

Expected: all tests pass. Report any unrelated pre-existing failure by exact
test name and output instead of changing unrelated code.

- [ ] **Step 5: Verify scope and whitespace**

```bash
git diff --check
git status --short
```

Expected: `git diff --check` is silent. The pre-existing
`lib/features/account/account_list_page.dart` modification remains untouched
and outside the implementation commits.

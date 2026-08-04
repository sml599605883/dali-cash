# Certification Retention Popup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Dali retention popups for certification types `0` through `5`, rendering the server image and implementing only the bottom Continue/Exit interactions.

**Architecture:** Add a Dali API client method and a shared retention guard/popup widget. Native certification pages pass type-specific product IDs and a default `Get.back` callback; the WebView passes type `5` and its existing history-aware back callback. Failed requests or missing `scabble` images fall back to the caller's normal back action.

**Tech Stack:** Flutter, GetX, Dio, Flutter widget tests.

---

### Task 1: Add the Dali retention API method

**Files:**
- Modify: `lib/core/network/api_client.dart`
- Test: `test/core/network/api_client_test.dart`

- [ ] **Step 1: Write the failing request-contract test**

Add a test using the existing fake Dio adapter that calls `ApiClient.retentionPopup(type: ' 2 ', productId: ' product-1 ')` and asserts one POST to `/lutes/weldor` with trimmed `omegas`, `thunderstruck`, and a six-digit `jawlines` field.

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `flutter test test/core/network/api_client_test.dart --plain-name 'retention popup' --concurrency=1`

Expected: FAIL because `retentionPopup` is not defined.

- [ ] **Step 3: Implement the minimal API method**

Add `Future<ApiResponse> retentionPopup({required String type, required String productId})` beside the other certification methods. Post to `ApiEndpoints.retentionDialog` with `omegas`, `thunderstruck`, and `_randomDigits(6)` under `jawlines`.

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `flutter test test/core/network/api_client_test.dart --plain-name 'retention popup' --concurrency=1`

Expected: PASS.

### Task 2: Build the shared popup and retention guard

**Files:**
- Create: `lib/features/certification/widgets/certification_retention_popup.dart`
- Create: `lib/features/certification/widgets/certification_retention_guard.dart`
- Test: `test/features/certification/widgets/certification_retention_popup_test.dart`
- Test: `test/features/certification/widgets/certification_retention_guard_test.dart`

- [ ] **Step 1: Write red widget tests**

Cover these exact behaviors: server image rendered at `343:332`, Continue closes without invoking exit, Exit invokes the supplied exit callback once, failed requests fall back to default back, and missing `scabble` falls back to default back. Use an injected fake API client/presenter so tests do not perform network calls.

- [ ] **Step 2: Run the red tests**

Run: `flutter test test/features/certification/widgets/certification_retention_popup_test.dart test/features/certification/widgets/certification_retention_guard_test.dart --concurrency=1`

Expected: FAIL because the shared widget and guard do not exist.

- [ ] **Step 3: Implement the popup**

Render `states.rheologists.scabble` as the full image with `BoxFit.fill`, constrain the popup to `min(screenWidth - 32, 343)` and `height = width * 332 / 343`, and overlay only the two bottom action targets. Use `toilfully` and `undauntable` for button labels, with `Continue` and `Exit` as empty-value fallbacks. Do not render any title/body copy.

- [ ] **Step 4: Implement the guard**

Expose `backHandler({required String type, required String productId, required VoidCallback onDefaultBack})`. Serialize requests, show the popup only when the response contains a non-empty `scabble`, and call `onDefaultBack` exactly once on invalid input, request failure, or missing image.

- [ ] **Step 5: Run the focused tests**

Run: `flutter test test/features/certification/widgets/certification_retention_popup_test.dart test/features/certification/widgets/certification_retention_guard_test.dart --concurrency=1`

Expected: PASS.

### Task 3: Wire native certification steps `0` through `4`

**Files:**
- Modify: `lib/features/certification/identity_selection/identity_selection_page.dart`
- Modify: `lib/features/certification/identity_face/identity_face_page.dart`
- Modify: `lib/features/certification/certification_information/certification_information_page.dart`
- Modify: `lib/features/certification/emergency_contact/emergency_contact_page.dart`
- Test: `test/features/certification/certification_retention_wiring_test.dart`

- [ ] **Step 1: Add failing wiring assertions**

Assert that the five back callbacks request types `0`, `1`, `2`, `3`, and `4` with the current product ID. Assert that identity upload, identity confirmation, and bind-card back actions do not invoke the guard.

- [ ] **Step 2: Run the red wiring test**

Run: `flutter test test/features/certification/certification_retention_wiring_test.dart --concurrency=1`

Expected: FAIL because the native pages still call direct back callbacks.

- [ ] **Step 3: Wire the shared guard**

Replace only the five main-step back callbacks with `CertificationRetentionGuard.backHandler`. Keep upload, identity confirmation, and bind-card callbacks unchanged. Add `PopScope` only where needed so system back uses the same callback as the toolbar without changing page layout or submit behavior.

- [ ] **Step 4: Run focused native certification tests**

Run: `flutter test test/features/certification --concurrency=1`

Expected: PASS.

### Task 4: Wire WebView confirmation type `5`

**Files:**
- Modify: `lib/features/webview/dali_webview_page.dart`
- Test: `test/features/webview/dali_webview_page_test.dart`

- [ ] **Step 1: Add failing type-5 back tests**

Assert that a confirmation URL with `thunderstruck` requests type `5`, Continue leaves the WebView open, Exit uses WebView history when available, and Exit closes the Flutter route when history is unavailable.

- [ ] **Step 2: Run the red WebView tests**

Run: `flutter test test/features/webview/dali_webview_page_test.dart --concurrency=1`

Expected: FAIL because confirmation back currently only logs unavailable retention.

- [ ] **Step 3: Replace log-only confirmation handling**

When `daliConfirmProductId(currentUrl)` is non-empty, await the shared guard with type `5` and an exit callback that performs the existing `_handleBack` history/route logic. Keep non-confirmation URLs on the existing back path. Remove the normal-path unavailable-retention log; retain a diagnostic log only for request failure/missing image.

- [ ] **Step 4: Run focused WebView tests**

Run: `flutter test test/features/webview/dali_webview_page_test.dart --concurrency=1`

Expected: PASS.

### Task 5: Full verification

**Files:** No additional production files.

- [ ] **Step 1: Run all certification and WebView regressions serially**

Run: `flutter test test/features/certification test/features/webview --concurrency=1`

Expected: PASS.

- [ ] **Step 2: Run static checks**

Run: `flutter analyze`

Expected: No analyzer issues.

- [ ] **Step 3: Check formatting and whitespace**

Run: `dart format --output=none --set-exit-if-changed lib/core/network/api_client.dart lib/features/certification lib/features/webview/dali_webview_page.dart test/core/network/api_client_test.dart test/features/certification test/features/webview/dali_webview_page_test.dart && git diff --check`

Expected: formatting check exits `0` and `git diff --check` prints no errors.

- [ ] **Step 4: Commit the implementation**

Run: `git add lib/core/network/api_client.dart lib/features/certification lib/features/webview/dali_webview_page.dart test/core/network/api_client_test.dart test/features/certification test/features/webview/dali_webview_page_test.dart && git commit -m "feat: add certification retention popups"`

Expected: one implementation commit containing only the retention flow changes.

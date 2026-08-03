# Dali Cash WebView Bridge Parity Design

## Goal

Implement the Dali Cash iOS WebView and H5 bridge with the same observable behavior as the current Kaibigan Loan implementation while retaining Dali-specific action names, payload fields, API contracts, navigation boundaries, and native bridge ownership.

This work does not attempt to evade App Review through cosmetic renaming. App Store guideline 4.3 evaluates the product as a whole. The implementation reduces unnecessary source similarity by assigning responsibilities according to Dali Cash's existing architecture rather than copying Kaibigan Loan's file structure.

## Scope

The implementation covers:

- An in-app WebView page with loading, failure, retry, dynamic title, navigation interception, and history-aware back behavior.
- The `ph_dali_cash_ios` JavaScript handler and all nine documented Dali H5 actions.
- Dali API wrappers required by retry-order and account-change actions.
- iOS StoreKit review requests through the existing Dali native client bridge boundary.
- HTTP/HTTPS raw-target navigation into the new WebView page.
- Focused unit and widget tests for parsing, dispatch, routing, API payloads, lifecycle behavior, and callback delivery.

The implementation excludes:

- Android app-rating behavior.
- An Android Google Play handoff from the iOS bridge.
- A new account-list selection page.
- Kaibigan Loan's project-specific WebView back-retention behavior.

## Architecture

The WebView feature will use Dali-owned responsibility boundaries:

1. A bridge contract defines the Dali handler name, action names, request decoding, and response encoding.
2. A bridge coordinator validates Dali payloads and executes injected business actions without depending on WebView controller types.
3. The WebView page owns controller lifecycle, JavaScript registration, callback evaluation, page loading, navigation interception, and visible states.
4. `NavigationHelper` remains the application routing facade and opens WebViews, Dali schemes, main tabs, and system URLs.
5. `ApiClient` owns Dali request paths and field mappings.
6. The Dali iOS client bridge owns StoreKit interaction.

This keeps message parsing and business behavior testable without a live WebView and prevents the page from becoming a large action switch.

## H5 Contract

The JavaScript handler name is `ph_dali_cash_ios`. Incoming messages may be either JSON strings or JavaScript objects. The parser accepts the bridge envelope's action, callback identifier, and data value without changing Dali field names.

When a callback identifier is present, the page evaluates:

```javascript
window.ph_dali_cash_ios.handleMessage({ callbackId, data })
```

The callback data is the bridge action result. Unsupported actions and invalid parameters produce structured failures rather than throwing through the JavaScript handler.

## Action Behavior

### Risk Upload

`dali_cash_RbGtlAKg2Hsx7x5` reads `thunderstruck` as the product ID and `saggards` as the order number. It reports Dali risk scene `10` with the action start time and returns success after the report completes.

### Google Play

`dali_cash_HjU4mCaWf9VcOI6` receives an Android package name. Dali's requested scope is iOS only, so this action does not construct or launch a Google Play URL. It records a diagnostic log and returns success so H5 is not blocked.

### URL Navigation

`dali_cash_dudAaHWAtJmjS2T` reads the raw URL string:

- HTTP and HTTPS open a new Dali in-app WebView.
- A `ph://` URL enters Dali's existing raw-target navigation parser.
- Other valid schemes are handed to the system as external application URLs.
- Empty or malformed values return a structured failure.

The WebView page also intercepts non-HTTP(S) top-level navigation and applies the same system handoff policy.

### Close And Home

`dali_cash_jWPoDsrg054lhUC` closes the current WebView.

`dali_cash_Ax2ivGQo70e2KIR` removes intermediate routes, returns to the main shell, and selects the Home tab.

### App Rating

`dali_cash_L9ePULguB5v2O84` calls the Dali client bridge. On iOS, the native registrar requests a StoreKit review using the foreground active `UIWindowScene` on iOS 14 and later, with the legacy StoreKit call on older supported iOS versions. No Android implementation is added.

StoreKit decides whether a prompt is displayed; a successful native method invocation cannot guarantee that iOS shows the prompt every time.

### Retry Order

`dali_cash_U5sqmkouwbyYVRT` reads `saggards`, shows the shared loading indicator, and calls `POST /lutes/titled` with:

```text
saggards=<order number>
```

The redirect URL is read from `unsphered.misericorde`. A non-empty result replaces the current WebView URL, or reloads when it matches the current URL. Loading is dismissed in all outcomes. API and missing-URL failures use the shared error presentation and return a structured failure.

### Change Account

`dali_cash_dzaSV8NeJkdm0di` reads `thunderstruck` and `saggards`, then calls `POST /lutes/preslaughter` with the documented product ID and Dali-generated noise fields.

- When `unsphered.clingiest` is empty, the existing Dali bind-card page opens in an explicit account-change mode with product and order context. A successful bind reads the new binding ID from `unsphered.hoover`, calls `/lutes/creasing`, and replaces the account-change route stack with a newly created WebView for the redirect URL. Normal certification-mode bind-card behavior remains unchanged.
- When accounts exist, Dali currently has no account-list selection page. The action records a diagnostic log and returns a canceled/unavailable failure. It must not select an account or call the change endpoint without user input.
- The existing `/lutes/creasing` wrapper is still added for the future account-list flow. It sends `titled` as the order number and `hoover` as the selected binding ID, then reads `unsphered.misericorde` as the redirect URL.

Account-change success does not load the redirect URL into the original WebView controller. The navigation helper removes the bind-card route and one old WebView route, then creates a new WebView route for the redirect URL. This matches Kaibigan Loan's observable route behavior and prevents Back from returning to the obsolete H5 state. A canceled bind-card flow returns to the original WebView unchanged.

### Public Parameters

`dali_cash_YDtfWHIcQnY8cfk` passes its raw URL or path to `ApiSignature.buildSignedQuery(path:)` and returns the resulting Dali common parameters through the H5 callback. Empty paths return a structured failure.

## WebView Lifecycle And UI

The page uses `flutter_inappwebview` and follows current Dali theme constants rather than introducing hard-coded colors.

- The JavaScript handler is registered only while the app is in the foreground and removed when inactive.
- Controller identity is checked after awaited controller calls so disposed or replaced pages cannot use stale controllers.
- Loading starts on navigation and stops on successful load or error.
- Main-frame load failures show an error state with retry; subresource failures do not replace the whole page.
- The title starts from the provided title or a neutral default, then follows non-empty document titles.
- Back first uses WebView history and closes the page only when no history exists.
- Web content permission requests are denied by default because no H5 permission contract was provided.
- Mixed content remains disabled.

## Error Handling

The coordinator catches action failures, resolves a user-facing message, reports it through Dali's shared error presenter, and returns a failure object to H5. Loading-owning actions use `try/finally`. Missing optional platform capabilities are logged when the approved behavior is log-only; missing required parameters fail without invoking APIs or navigation.

No bridge action may crash the Flutter page because of malformed H5 input, a missing callback, an unavailable route, or an absent WebView controller.

## Dependencies

Add stable versions compatible with the current Flutter toolchain:

- `flutter_inappwebview` for embedded WebView behavior and JavaScript handlers.
- `url_launcher` for external application schemes.

No rating package is required because the approved behavior uses Dali's iOS MethodChannel and StoreKit directly.

## Verification

Implementation follows test-driven development. Coverage must include:

- Exact Dali handler/action constants and Dali payload field extraction.
- String/object envelope parsing and malformed input.
- Callback JavaScript shape and callback omission for fire-and-forget actions.
- Risk scene `10`, signed public parameters, URL classification, close, Home, and log-only Google Play behavior.
- Retry loading/error lifecycle and current-controller reload/load behavior.
- Account-list empty/existing/canceled outcomes and log-only missing-page behavior.
- Bind-card normal mode remains unchanged, while account-change mode submits the new binding ID and replaces the old account-change stack with a new WebView.
- Account-change replacement removes the bind-card route and exactly one old WebView; Back must not reveal the obsolete H5 page.
- Exact Dali API paths, request fields, and redirect response fields.
- iOS-only native app-review method wiring and StoreKit foreground-scene behavior.
- WebView loading, retry, title, navigation interception, lifecycle handler registration, and history-aware back behavior.
- Existing navigation and product-detail tests remain green.

Final validation is focused tests first, then `flutter test --concurrency=1`, `flutter analyze`, and `git diff --check`.

## Acceptance Criteria

- All nine Dali H5 actions are recognized and produce the approved observable outcome.
- Dali field names and API contracts match the supplied H5 contract and Dali API documentation.
- App rating invokes StoreKit only through the iOS native bridge.
- Existing-account change logs the missing account-list page instead of fabricating navigation or selection.
- HTTP/HTTPS targets no longer stop at the current deferred WebView log.
- Errors, empty values, lifecycle changes, and canceled page flows do not crash or leave loading visible.
- The design uses Dali-owned module boundaries and does not copy Kaibigan-specific route names, fields, or retention behavior.

# Mine Order List Design

## Goal

Implement the Dali Cash personal-center order list shown in Lanhu design
`05-01 - 订单列表-有订单`. The four Mine shortcuts open this dedicated page
with the corresponding initial filter. Kaibigan Loan supplies observable
interaction behavior only; Dali's API documentation, routes, fields, assets,
and theme tokens remain authoritative.

## Scope

- Add a dedicated Mine order-list route, Dali data model, page, and tests.
- Connect View All, Unpaid, Late, and Paid shortcuts to initial status codes
  `4`, `7`, `6`, and `5` respectively.
- Load, filter, refresh, and render the documented Dali order list.
- Implement independent order-card and action-button navigation.
- Refresh after returning from a child route.
- Omit the design's uncontracted fixed bottom `Confirm` button.
- Do not add early-settlement UI for `demising`, `zirconia`, or
  `developments` in this task.

## Source Contracts

### Design

- Lanhu project: Dali Cash
- Design ID: `3ed02378-b10d-482e-9ad0-6b58d8d5dcbd`
- Design name: `05-01 - 订单列表-有订单`
- Logical canvas: 375 x 812

The page has a centered `Loan List` header, four text tabs, an active blue
underline, vertically scrolling white order cards, and conditional full-width
card actions. The fixed `Confirm` footer in the source design is intentionally
excluded because neither the order-list contract nor the reference behavior
defines an action for it.

### API

```text
POST /lutes/telfered
request:
  anfractuosity = 4 | 7 | 6 | 5
  redeployments = 1
  unornate = 50
response list:
  unsphered.clingiest
```

The API client accepts the semantic status and supplies the fixed first-page
and page-size values internally.

Documented item mapping:

| Semantic value | Dali field |
| --- | --- |
| Order ID | `filers` |
| Order number | `saggards` |
| Product ID | `thunderstruck` |
| Product name | `preslaughter` |
| Product logo | `creasing` |
| Order status code | `fornices` |
| Status text | `proboscis` |
| Formatted amount | `injective` |
| Amount label | `planetological` |
| Action text | `weldor` |
| Action redirect | `nauseant` |
| Date label | `prebiological` |
| Date value | `en` |
| Overdue days | `reshippers` |
| Card redirect | `methodical` |

Formatted monetary values remain strings. The client does not parse them
through floating point or reformat server-provided display text.

## Architecture And State

Create a focused order-list feature containing the semantic model and page.
The parser tolerates malformed entries and missing optional display values
without crashing. It reads the list only from `unsphered.clingiest` after the
shared API response layer has exposed `unsphered` as `states`.

The page owns the selected status, loading flag, parsed items, and retryable
error message. It requests data on initial display, filter changes,
pull-to-refresh, and `RouteAware.didPopNext`. A request token or equivalent
guard prevents stale responses from an earlier filter replacing the newest
selection.

The page provides explicit Loading, Error with Retry, Empty, and populated
states. Both empty and populated content use always-scrollable physics so
pull-to-refresh remains available.

## Navigation

Mine shortcuts open the dedicated route with an `initialStatus` argument:

| Shortcut | Status |
| --- | --- |
| View All | `4` |
| Unpaid | `7` |
| Late | `6` |
| Paid | `5` |

Card and action navigation are independent:

- Tapping the card uses `NavigationHelper.navigateRawTarget(methodical)` when
  `methodical` is non-empty. An empty card target performs no navigation.
- The action button is visible only when `fornices` is `174` or `180`.
- The visible action text is exactly `weldor`; it is not hardcoded to
  `Repay Now` and does not control visibility.
- For status `174`, the action button uses the blue primary treatment.
- For status `180`, the action button uses the red alert treatment.
- Tapping the action first checks `nauseant`. A non-empty value is dispatched
  through `NavigationHelper.navigateRawTarget(nauseant)`.
- When `nauseant` is empty, the action calls the existing Dali admission flow
  through `NavigationHelper.applyProduct(thunderstruck)`.

This matches Kaibigan's redirect-first, admission-fallback behavior while
using Dali's own fields and navigation entry point.

## Visual Implementation

Translate the Lanhu HTML/CSS values into Flutter logical pixels and reuse
`ScreenAdapter` consistently with the existing Dali pages. Visible colors are
exposed through `AppColors`; widgets do not hardcode hexadecimal colors.

Key values include:

- Page background: RGBA `(244, 244, 244, 1)`.
- Primary/action blue: RGBA `(60, 108, 243, 1)`.
- Alert/action red: existing `AppColors.alert`.
- Primary text: RGBA `(51, 51, 51, 1)`.
- Muted text: RGBA `(153, 153, 153, 1)`.
- Horizontal order-card margin: 16 logical pixels.
- Order-card radius: 8 logical pixels.
- Order-card padding: 12 logical pixels.
- Inner information-panel radius: 4 logical pixels.

Product logos come from the API field `creasing`, use `Image.network`, and
fail to an empty visual without crashing. The back affordance reuses an
existing semantic project asset when it matches the design; system status-bar
and home-indicator artwork are not downloaded into the Flutter page.

## Error Handling

- API failures resolve through the existing shared error-message path and show
  Retry.
- Malformed list entries are ignored rather than crashing the page.
- Missing product logo or optional text keeps the card layout stable.
- A visible action with an empty `nauseant` and empty product ID performs no
  request and no navigation.
- Navigation failures continue to use the existing NavigationHelper error
  presentation.
- Stale or overlapping filter responses cannot overwrite the active filter.

## Testing

Focused tests cover:

- endpoint and request fields `anfractuosity`, `redeployments`, and `unornate`;
- parsing every documented Dali order field from `clingiest`;
- malformed and empty response handling;
- shortcut-to-status mapping `4 / 7 / 6 / 5`;
- initial filter selection and filter request changes;
- button hidden for statuses other than `174` and `180`;
- status `174` renders a blue action and status `180` renders a red action;
- button text comes from `weldor`;
- non-empty `nauseant` dispatches directly without admission;
- empty `nauseant` starts admission with `thunderstruck`;
- card taps use `methodical` independently;
- Loading, Error/Retry, Empty, pull-to-refresh, and route-return refresh;
- no fixed bottom `Confirm` action is rendered.

Run focused Flutter tests serially, then formatting, static analysis for the
touched files, `git diff --check`, and the relevant existing widget tests.

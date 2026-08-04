# Certification Route Parity Design

## Goal

Align Dali Cash certification transitions with the observable Kaibigan Loan
behavior while preserving Dali's API contracts and direct, server-driven entry
into certification. Dali must not add or open a standalone product-detail page.

## Confirmed Behavior

- Product application continues to call Dali's product-detail API only to read
  the next certification step.
- Every completed certification stage reloads product detail through
  `NavigationHelper.continueProductDetailFlow(productId)`.
- The server-provided next-step code remains the only authority for selecting
  the next top-level certification page.
- Moving to another top-level certification stage removes completed
  certification pages from the route stack.
- The identity-selection, identity-upload, and identity-confirmation screens
  remain one internal subflow with normal back navigation until identity data
  is submitted successfully.
- Existing Dali field names, endpoints, reporting calls, messages, and step-code
  mappings remain unchanged.

## Selected Approach

Centralize top-level certification route replacement in `NavigationHelper`.
Each top-level route method will use one shared pruning helper, matching the
existing centralized Dali navigation ownership. Identity upload and identity
confirmation remain ordinary pushes because users may need to go back and
change an image or identity type before submission.

After identity confirmation saves successfully, replace its hard-coded face
navigation with `continueProductDetailFlow(productId)`. This matches the other
certification forms and allows the server to skip, reorder, or repeat stages.

Two alternatives are rejected:

- Keeping direct page-to-page transitions would duplicate workflow rules in
  pages and could disagree with the server.
- Popping only the current page would leave earlier completed certification
  pages reachable and would not match the reference route-stack behavior.

## Route Stack Rules

The shared pruning set contains all Dali certification routes:

- identity selection
- identity upload
- identity confirmation
- identity face
- personal information
- work information
- emergency contact
- bind card

When product detail selects a top-level certification stage,
`Get.offNamedUntil` removes routes in that set until it reaches the first
non-certification route, then installs the selected route.

Identity selection opens identity upload with `Get.toNamed`. Identity upload
opens identity confirmation with `Get.toNamed`. These two internal pushes are
not changed. Once identity confirmation is saved and product detail selects the
next stage, the centralized top-level route method prunes the entire identity
subflow.

Account-change bind-card navigation is not part of the product certification
continuation and retains its existing push behavior.

## Data Flow

1. A certification page saves through its existing Dali endpoint.
2. The page keeps its existing report behavior.
3. The page calls `continueProductDetailFlow(productId)`.
4. `POST /lutes/liberals` returns `spirochaete.entrecote`.
5. `NavigationHelper` maps the returned code to an existing Dali page.
6. The selected top-level route replaces the old certification route stack.
7. If no certification step is returned, the existing order continuation
   through `productPush` remains unchanged.

No product-detail UI route is introduced at any point.

## Error Handling

Identity confirmation retains its existing loading, API error presentation,
submission lock, and mounted checks. A product-detail continuation error stays
inside the same `try` block and therefore uses the page's existing resolved
error presentation. The current page remains visible when save or continuation
fails.

Unknown step codes, missing order data, and empty redirect targets retain the
existing log-only handling in `DaliProductNavigationFlow`.

## Testing

- Add a regression proving identity confirmation saves and requests product
  detail instead of directly opening face verification.
- Add route tests proving a server-selected next stage removes prior
  certification routes.
- Add a test proving identity selection, upload, and confirmation retain normal
  back navigation before successful submission.
- Preserve the existing test that initial application reads product detail and
  directly dispatches the next certification step without a product-detail
  page.
- Run focused identity-confirmation and navigation tests serially, then run
  `flutter analyze`, the broader certification/navigation suites, and
  `git diff --check`.

## Non-Goals

- Creating or navigating to a product-detail page.
- Changing product application admission, login, location, reporting, or
  loading order.
- Changing Dali API fields, endpoints, or certification step mappings.
- Changing account-list or account-change behavior.
- Adding placeholder routes or UI.

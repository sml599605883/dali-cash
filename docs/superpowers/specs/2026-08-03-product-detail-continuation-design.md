# Product Detail Continuation Design

## Goal

Complete Dali Cash product-detail continuation using the established Kaibigan
Loan flow shape while preserving Dali-specific API fields, routes, reporting,
and error handling. Existing certification pages should open normally;
unrecognized or unavailable targets should only be logged.

## Scope

- Support both documented original and obfuscated product-detail step codes.
- Keep product-detail prompt and order-number caching before continuation.
- Route every certification step whose page exists in Dali Cash.
- When no certification step is returned and `tucking == 200`, call the
  documented `productPush` endpoint to resolve the order destination.
- Report risk scene 9 only after `productPush` succeeds.
- Navigate a non-empty `productPush` target through the existing raw-target
  dispatcher.
- Log unknown steps, missing order information, and empty redirect targets.
- Do not create placeholder pages or change unrelated UI and certification
  submission behavior.

## API Contract

Product detail remains `POST /lutes/liberals`. Its `unsphered` payload provides:

- `tucking`: internal product-detail status.
- `shoepac`: product and order information.
- `spirochaete.entrecote`: next certification step.
- `poolsides`: certification-page copy.

Order continuation uses `POST /lutes/hotel` with the exact Dali fields:

- `titled`: order number from `shoepac.saggards`.
- `injective`: amount from `shoepac.injective`.
- `resmooth`: term from `shoepac.resmooth`.
- `mispatch`: term type from `shoepac.mispatch`.
- `gulpers`, `tap`, `verste`, and `respective`: generated obfuscation values.

The navigation target is read from `unsphered.millipede`.

## Step Routing

The dispatcher accepts both the original and obfuscated values documented by
Dali:

| Route | Original | Obfuscated |
| --- | --- | --- |
| Identity selection | `public` | `LancerPredacities` |
| Face verification | `face` | `CilantroCountermemo` |
| Personal information | `personal` | `PermafrostsPalfreys` |
| Work information | `work` | `DeviouslyTressours` |
| Emergency contact | `ext` | `TrotlineScootches` |
| Bind card | `bank` | `MolehillSubconscious` |

All six pages currently exist. A non-empty unknown code is logged and stops the
flow so it cannot accidentally enter an order or unrelated fallback branch.

## Continuation Priority

After a successful product-detail response is parsed and cached:

1. If `spirochaete.entrecote` is non-empty, dispatch the certification step.
   Known steps navigate to the existing page. Unknown steps are logged. Either
   result ends this continuation attempt.
2. If no step is present and `tucking == 200`, validate the order number. A
   missing order number is logged and ends the flow.
3. Call `productPush` using the product detail's order values.
4. After `productPush` succeeds, trigger risk scene 9 without awaiting the
   report, so reporting cannot block or invalidate navigation.
5. Navigate a non-empty returned `millipede` through `navigateRawTarget`. Log an
   empty target and remain on the current page.
6. If no step exists and `tucking != 200`, log the status and remain on the
   current page.

## Ownership

`ApiClient` owns the exact `productPush` request contract.
`DaliProductNavigationFlow` owns product-detail parsing, cache sequencing,
productPush, and the decision between certification and order continuation.
`NavigationHelper` remains the GetX compatibility facade for concrete routes,
raw-target navigation, logging, and scene-9 reporting integration.

The product-detail callback will return whether a certification step was
present. This keeps GetX route knowledge out of the flow while allowing the
flow coordinator to avoid order continuation after an unknown non-empty step.

## Loading And Errors

Existing caller boundaries remain unchanged. Initial application continues to
hold its loading state across product detail and productPush. Certification
pages continue to surface continuation failures through their existing submit
error handling. API and parsing failures propagate through the existing
`ApiErrorMessage.resolve` paths.

No new toast is derived from the outer successful `cuckoo` message because the
documented value is a transport-level success message, not a continuation
instruction.

## Testing

- Verify the exact `/lutes/hotel` request path and obfuscated payload fields.
- Verify original and obfuscated certification codes reach the same existing
  routes.
- Verify unknown steps log and do not call `productPush`.
- Verify an empty step with `tucking == 200` calls `productPush` with the parsed
  order values and navigates its `millipede` target.
- Verify scene 9 is not reported before `productPush` completes and is reported
  once after success.
- Verify missing order numbers, empty redirect targets, and non-200 detail
  statuses log without navigation.
- Run focused navigation and API-client tests, then static analysis and the
  relevant broader Flutter test suite with serial execution where needed.

## Non-Goals

- Creating a standalone product-detail page.
- Inventing undocumented fallback fields or routes.
- Changing product application admission, permission prompts, certification
  form behavior, or reporting scenes other than scene 9.

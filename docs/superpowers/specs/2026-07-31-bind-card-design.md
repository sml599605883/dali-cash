# Dali Cash Bind Card Design

## Goal

Implement the certification bind-card page for Dali Cash using the Lanhu design `03-05 - 绑定账户-电子钱包` (`fc61f15a-c637-4a63-a17a-47031ec32a78`). Preserve the observable dynamic-form behavior of Kaibigan Loan while using Dali Cash API contracts, routing, theme tokens, reporting, and assets.

## Scope

- Add the bind-card route and connect product-detail step `MolehillSubconscious` to it.
- Load bind-card configuration from `GET /lutes/underfeeding`.
- Render every account group returned by the API. The current contract returns E-wallet and Bank; future groups such as Cash Pickup require no page-level hardcoding.
- Submit the selected group's values through `POST /lutes/millipede`.
- Continue the existing product-detail flow after normal success.
- Handle response code `20000` with the existing Dali camera-permission and TrustDecision liveness infrastructure, then resubmit with the required liveness fields.
- Reuse and semantically rename the supplied `assets/编组 5@3x.png` progress asset.

Account-change routing and the separate account-list feature are outside this certification-page task.

## Data Contract

The Dali Cash API documentation is authoritative. Kaibigan field names must not cross the project boundary.

### Initialization

`GET /lutes/underfeeding` receives the product id as `highlands`. Existing `ApiClient` request wrapping remains responsible for protocol-level common and obfuscated parameters.

The page parses `unsphered.choired` as dynamic groups:

- `enterostomy`: displayed group label
- `sociologeses`: group/card type
- nested `choired`: dynamic fields

Each field uses:

- `enterostomy`: label
- `felicitous`: logical save key
- `laggings`: placeholder
- `solferino`: `enum` or text input
- `poolsides`: enum options
- `muscats`: optional marker
- `fyke`: initial value
- `degringolade`: suggested/display value when supplied
- `omegas`: numeric-keyboard metadata (`1` selects a numeric keyboard)

Option values under `sociologeses` may be numeric or strings. Normalize them to `String` at the model boundary so selection state and submission are stable.

Top and bottom copy come from `dextrorse` and `brabble`. Empty server copy may fall back to the matching Lanhu text without changing non-empty server text.

### Submission

Map only the selected group's dynamic values to the Dali submission contract:

- `highlands`: product id
- `rapscallion`: selected group/card type
- `global`: channel code
- `rattlesnakes`: first name
- `monerans`: middle name
- `sloid`: last name
- `whops`: account number
- `shallowly`: repeated account number

Liveness retries additionally use `pileated`, `feoffed`, `attach`, `infantilisms`, and `miscasts` according to the Dali response and existing TrustDecision bridge. Required fields must be non-empty, and the repeated account must match before the first request is sent.

## UI Structure

Use existing Dali `ScreenAdapter`, `AppColors`, shared certification widgets, and local assets. Do not introduce raw hex colors in feature widgets.

The page follows the 375 x 812 Lanhu artboard:

1. Gray certification background and safe-area header.
2. Centered `Account management` title with the existing certification back control.
3. Red full-width explanatory banner.
4. Supplied step 4/4 progress artwork, exposed through `AppAssets` under a semantic bind-card name.
5. White 343-wide, 12-radius form panel.
6. Dynamic horizontal account-type tabs. The selected tab uses the Dali primary blue and a 4-pixel indicator; unavailable groups are not fabricated.
7. Dynamic field list with 16-pixel labels, 319-wide light-gray inputs, 4-pixel radius, and exact Lanhu spacing.
8. Fixed white footer with shadow and an 8-radius, 46-high primary `Upload` button.

The form area scrolls when the server returns more fields than the artboard example. Fixed header and footer geometry remains stable. Switching groups preserves each group's controllers and selected options.

## Selection Interaction

Enumeration fields open a shared bind-card option sheet consistent with the existing Dali certification sheet language. Each option can show its server logo, label, availability status, and maintenance copy. The entire row is tappable. At most five rows are visible before the list scrolls.

Cancel leaves the field unchanged. Done commits the normalized option value while displaying the option label.

## State And Errors

- Loading: show an in-page loading state while initialization is pending.
- Error: show the resolved API message and a retry action.
- Empty: show a stable empty state when no valid groups are returned.
- Submission: disable `Upload` while a request or liveness continuation is active.
- Validation: focus or identify the first missing required field; reject mismatched account confirmation locally.
- API errors: use the existing Dali error presenter and preserve non-empty server messages.
- Permission denial: use the existing Cupertino camera settings dialog and do not start TrustDecision without permission.
- Lifecycle: dispose controllers and focus nodes created for dynamic fields.

## Success Flow

On a normal successful bind response:

1. Dismiss loading exactly once.
2. Report the Dali bind-card certification success scene using existing reporting infrastructure where the scene is already defined.
3. Call `NavigationHelper.continueProductDetailFlow(productId)`.

On response code `20000`:

1. Request camera permission.
2. Obtain the face/liveness token through the existing Dali API and bridge contracts.
3. Launch TrustDecision liveness.
4. Report the TrustDecision result through the existing reporter.
5. Resubmit the original form values plus the liveness fields.
6. Reject a second `20000` as an unsuccessful verification instead of looping.

## Testing

Add focused tests for:

- Mixed numeric/string group and option value parsing.
- Filtering malformed groups and fields without crashing.
- Dynamic E-wallet and Bank tabs and future returned groups.
- State preservation across tab switches.
- Enum selection label/value behavior and option-row tap targets.
- Required-field and repeated-account validation.
- Exact Dali request mapping for initialization and submission.
- Loading, retry, empty, and duplicate-submit states.
- Normal success continuing the product-detail flow.
- `20000` camera denial, TrustDecision failure, and successful resubmission.
- Route registration and `MolehillSubconscious` navigation.
- Semantic progress-asset registration.

Verification includes focused Flutter tests, targeted `flutter analyze`, and `git diff --check`. Because the checkout contains concurrent certification changes, run relevant GetX-heavy suites serially when shared global state causes concurrent cascades.

## Fidelity Audit

Before completion, compare the Flutter implementation against the Lanhu HTML/CSS for artboard size, colors, typography, spacing, radii, fixed footer geometry, clipping, and element completeness. Any difference must be either corrected or identified as an intentional Flutter adaptation. Production code must contain no Lanhu CDN URL.

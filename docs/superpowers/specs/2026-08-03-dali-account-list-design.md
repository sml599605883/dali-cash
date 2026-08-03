# Dali Cash Account List Design

## Goal

Implement the Dali Cash account-selection page shown in Lanhu design
`04-01-借款-选择其它借款方式` and connect it to the WebView
`changeAccount` flow. Preserve the observable Kaibigan Loan behavior while
using Dali routes, fields, assets, and component boundaries.

## Scope

- Add an account-list route, parser, page, and focused tests.
- Route WebView `changeAccount` to the account list when existing accounts are
  returned.
- Submit the selected binding through `POST /lutes/creasing`.
- Replace the account-change navigation stack with the returned WebView URL.
- Open the existing bind-card page when the user selects Add other payment
  methods.
- Keep maintenance accounts selectable and submittable.
- Remove scene-8 reporting from account-change bind success while preserving it
  for normal bind success.

The feature does not introduce a new account API, retention popup, or account
editing capability.

## Source Contracts

### Design

- Lanhu project: Dali Cash
- Design ID: `8c99142a-80f0-4bf6-980a-d21f6e386ed9`
- Design name: `04-01-借款-选择其它借款方式`
- Logical canvas: 375 x 896

The page contains:

- A `Loan Confirmation` header.
- Bank, E-wallet, and Cash Pickup section labels.
- Selectable account cards with provider logo, provider name, and selection
  state.
- A bank-maintenance warning that does not disable selection.
- Receipt Account content for bank and wallet accounts.
- First, Middle, and Last Name content for cash-pickup accounts.
- An outlined Add other payment methods action.
- A fixed bottom Confirm action.

### API

Account list:

```text
POST /lutes/preslaughter
request: highlands, nonanimal, cornuted
response list: unsphered.clingiest
```

`ApiClient.userAccountList` accepts the semantic product ID and generates the
`nonanimal` and `cornuted` nonce values internally. Callers do not manufacture
or forward those protocol-only values.

Documented response hierarchy:

```text
clingiest[]
  rapscallion
  pater
  alodia
  jambes[]
    hoover
    leachate
    precolonial
    filmcards
    emptiable
    nonbehavioral
    exploitable
    sociologeses
```

Account change:

```text
POST /lutes/creasing
request: titled=<orderNo>, hoover=<bindId>, brontosauruses=<random>
redirect: unsphered.misericorde
```

`ApiClient.changeOrderAccount` accepts the semantic order number and binding
ID and generates `brontosauruses` internally.

## Architecture

### Account data model

Create a Dali-specific parser rather than reusing or copying Kaibigan models.
The parser owns tolerant conversion of the obfuscated response into semantic
sections and account rows.

Primary mapping:

| Semantic value | Dali field |
| --- | --- |
| Card type | `rapscallion` |
| Card type name / section title | `pater` |
| Card type icon | `alodia` |
| Account rows | `jambes` |
| Binding ID | `hoover` |
| Account/provider logo | `leachate` |
| Account status | `precolonial` |
| Bank/provider name | `filmcards` |
| Account value | `emptiable` |
| Option data, including Cash Pickup names | `nonbehavioral` |
| Main/default selection | `exploitable` |
| Account type | `sociologeses` |

The parser keeps group metadata separate from row data. Bank and wallet rows
render `filmcards` as the provider name and `emptiable` as the receipt account.
Cash Pickup rows derive First, Middle, and Last Name values from
`nonbehavioral`; absent optional name parts render safely. `leachate` is the
row logo, with `alodia` used only as the card-type icon/fallback visual rather
than as account text.

Rows without a binding ID are ignored. Unknown card types remain visible using
the server-provided `pater` title. Missing optional text renders safely instead
of throwing. `precolonial` controls the maintenance presentation but does not
disable selection or confirmation.

### Page ownership

The account-list page owns:

- Loading and parsing account data.
- Default selection from `exploitable`.
- User selection, including maintenance accounts.
- Confirm submission and duplicate-submit locking.
- Empty and retryable error states.
- Opening bind card in account-change mode.
- Replacing the account-change route stack after successful confirmation.

The WebView action coordinator continues to validate H5 data. Its Dali
capability callback decides whether to open the account list or bind card based
on `clingiest`.

### Navigation

Add a dedicated account-list route using Dali arguments:

```text
highlands=<productId>
saggards=<orderNo>
```

Successful account change removes the routes belonging to the active
account-change flow:

- The active account-list route when present.
- The active account-change bind-card route when present.
- Exactly one previous WebView route.

It then creates a new WebView using `misericorde`. Older routes below the
account-change flow remain intact. Confirmation directly from the account list
removes the account list and its previous WebView. Success after Add other
payment methods additionally removes the intervening bind-card route.

Back from the account list returns to the original WebView. Back from bind card
opened through Add other payment methods returns to the account list until the
binding succeeds.

## Visual Implementation

Use the supplied project assets without downloading duplicate Lanhu slices:

- `assets/编组 5@3x.png` — Bank section label.
- `assets/编组 5@3x(1).png` — E-wallet section label.
- `assets/编组 5@3x(2).png` — Cash Pickup section label.
- `assets/选择@3x.png` — selected state.
- `assets/选择@3x(1).png` — unselected state.
- `assets/添加@3x.png` — add icon.
- `assets/矩形@3x.png` — outlined add-payment-method border.

The assets are exposed through semantic `AppAssets` constants. Widgets reuse
matching `AppColors` tokens and add a token only if no exact match exists;
widgets do not hardcode hexadecimal colors.

Important design values:

- Page background: RGBA `(244, 244, 244, 1)`.
- Primary: RGBA `(60, 108, 243, 1)`.
- Primary text: RGBA `(51, 51, 51, 1)`.
- Muted text: RGBA `(153, 153, 153, 1)`.
- Maintenance warning: RGBA `(246, 18, 18, 1)`.
- Account card outer width: 343.
- Account card and inner panel radius: 12.
- Bottom Confirm height: 48 and radius: 8.
- Horizontal page padding: 16.

The content is scrollable above a fixed white footer. Compact screens must not
overflow; the footer remains reachable and account content remains scrollable.

## Error Handling

- Missing product ID or order number shows a stable page error and performs no
  API call.
- Account-list failure shows the shared resolved error with Retry.
- Empty account data shows an empty state with Add other payment methods and a
  disabled Confirm action.
- Missing selected binding ID does not submit.
- Change-account failure preserves the selected row, dismisses Loading, and
  re-enables Confirm.
- Missing `misericorde` is treated as a business error and does not mutate the
  route stack.
- If the page is disposed while submitting, Loading is still dismissed and no
  stale UI update is attempted.

## Risk Reporting

Scene 8 belongs to normal bind-card certification only. Account-change bind
success does not report scene 8, matching the reference behavior.

## Testing

Add focused coverage for:

- Parsing all documented Dali account fields and malformed payloads.
- Group ordering and unknown group retention.
- Default/main selection.
- Maintenance accounts remaining selectable.
- Bank, wallet, and cash-pickup layouts.
- Add-payment-method navigation arguments and back-stack preservation.
- Confirm payload and fresh-WebView replacement.
- Loading, error, retry, empty, and duplicate-submit states.
- Account-change bind success pruning account list, bind card, and one WebView.
- Scene-8 reporting remaining on normal bind only.
- WebView `changeAccount` routing existing accounts to the account list and an
  empty list to bind card.
- Golden or geometry assertions against the 375-wide Lanhu layout.

## Similarity Control

Behavior and API outcomes match the reference app, but Dali uses:

- Its own response parser and semantic model.
- Its own widget composition based on the Dali Lanhu design.
- Its own asset set and theme constants.
- Its own route argument and API field names.
- The existing Dali WebView coordinator boundary.

This avoids copying Kaibigan source structure while preserving required user
behavior.

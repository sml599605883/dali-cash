# Progress API Refresh Design

## Goal

Replace the Progress tab's local sample data with the documented `PROCESS_LIST`
module from `GET /lutes/unsphered`. Refresh it whenever the user switches from
another tab to Progress, when the app resumes while Progress is visible, and
when the user pulls down on the Progress page.

## API Contract And Parsing

The existing home endpoint remains the only network source. `HomeData` parses
the `PROCESS_LIST` section alongside the existing home sections and exposes an
immutable list of `ProgressItem` values. The parser uses the documented fields:

- `titled`: order number;
- `highlands`: product ID;
- `studdies`: product name;
- `tricky`: product logo;
- `alternation`: formatted display amount, falling back to `injective` only
  when the formatted value is absent;
- `betattered`: amount label;
- `totalist`: displayed date;
- `relativize`: date label;
- `interterm`: server status label;
- `emblemize`: numeric card state from `0` through `6`;
- `millipede`: order-detail route;
- `psychographs`: documented action-button metadata.

Malformed sections and items are ignored safely. Monetary values remain
strings for display; the client does not parse them through floating point.

## State And Request Lifecycle

`MainController` continues to own the shared home response and request lock.
Home and Progress use the same `ApiClient.homePage()` implementation, but have
separate refresh entry points:

- Home refresh requests the home endpoint and then the scene-1 popup endpoint.
- Progress refresh requests only the home endpoint.

Every successful home response atomically replaces `HomeData`, so both tabs
observe one data version. Switching from another tab to Progress always calls
the Progress refresh entry point. Tapping the already selected Progress tab
does nothing. App resume refreshes whichever supported tab is visible: Home
uses the Home chain and Progress uses the Progress-only request. A shared lock
prevents overlapping endpoint calls.

Progress keeps explicit loading and error state. The initial request displays a
loader. A first-load failure displays a retry state. If older progress data
exists, a later refresh failure preserves and continues displaying that data
while reporting the existing network error message.

## UI

`ProgressPage` observes `MainController` rather than defaulting to sample data.
Both populated and empty states are vertically scrollable with always-scrollable
physics so pull-to-refresh works in either state. Cards use server-provided
product, amount, date, label, status, and visible action text. Numeric
`emblemize` values select the existing approved color treatment; unsupported
values use the neutral presentation without crashing.

Action navigation is outside this task. Buttons are rendered from documented
visible metadata but do not introduce new order, repayment, account-change, or
retry navigation behavior.

## Testing

Focused tests cover:

- complete and malformed `PROCESS_LIST` parsing;
- numeric status-to-presentation mapping;
- switching into Progress on every visit requests the home endpoint without
  requesting the popup endpoint;
- same-tab selection does not request again;
- app resume while Progress is visible refreshes Progress only;
- pull-to-refresh works for populated and empty states;
- initial loading, first-load error/retry, stale-data preservation, and the
  shared overlap lock;
- the existing Home request and popup lifecycle remains unchanged.

Run focused Flutter tests serially, then run formatting and static analysis on
the touched files.

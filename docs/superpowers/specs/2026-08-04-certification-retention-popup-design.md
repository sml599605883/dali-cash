# Certification Retention Popup Design

## Goal

Add the Dali certification retention flow for native certification steps and the WebView loan-confirmation step, using the server-delivered popup image and Kaibigan Loan interaction behavior.

## Scope

The retention API is requested from these six exit points:

| Type | Owner | Product ID source |
| --- | --- | --- |
| `0` | Identity selection | certification route arguments |
| `1` | Face verification | certification route arguments/cache |
| `2` | Personal information | certification route arguments |
| `3` | Work information | certification route arguments |
| `4` | Emergency contact | certification route arguments |
| `5` | WebView loan-confirmation page | `thunderstruck` from the confirmation URL |

Identity upload, identity confirmation, and bind-card pages retain their existing direct-back behavior and do not request the popup.

## API Contract

Call `POST /lutes/weldor` with:

- `omegas`: popup type (`0` through `5`)
- `thunderstruck`: product ID
- `jawlines`: existing random signing/anti-replay field convention

Read the response from `states.rheologists`:

- `scabble`: complete popup image URL; it contains all title, body, and decorative content
- `toilfully`: Continue button label
- `undauntable`: Exit button label

No popup title, body, or decorative copy is recreated in Flutter. If the request fails, the product ID is missing, or `scabble` is empty, execute the normal back action immediately.

## Popup UI

The popup renders the server image at a fixed `343:332` aspect ratio, constrained to `screenWidth - 32` on narrow screens. Flutter implements only two bottom interaction targets over the image:

- Continue closes the popup and keeps the current page open.
- Exit closes the popup and invokes the caller's normal back callback.

The native popup uses the existing Dali modal/barrier conventions. The WebView uses the same popup widget but supplies a WebView-aware exit callback.

## Navigation Behavior

A shared retention guard owns request, loading dismissal, failure fallback, and duplicate-back protection. Native pages pass their type and default `Get.back` callback. The WebView passes type `5` and its existing `_handleBack` callback.

For WebView Exit, preserve the current order: navigate WebView history when available; otherwise close the Flutter WebView route. Continue must leave the WebView route and document unchanged.

## Verification

Focused tests will cover API request fields, type mapping, missing/failed response fallback, Continue/Exit behavior, duplicate back prevention, popup aspect ratio, and WebView history-vs-route exit behavior. Run the focused certification/WebView tests serially, followed by `flutter analyze`, formatting checks, and `git diff --check`.

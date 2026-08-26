# Public UI Foundation Contract

The UI foundation is a small, cross-platform vocabulary for applications that
use Native Markup. It is not a product shell and it does not own application
state.

## Public Templates

`native eject component ui-foundation` writes the canonical source to
`src/components/ui_foundation.native`. The file contains five headless
templates:

| Template | Responsibility | Caller owns |
| --- | --- | --- |
| `ui-foundation-toolbar` | toolbar row, height and label | title, actions, messages, window-drag policy |
| `ui-foundation-sidebar` | navigation column, minimum width and label | routes, rows, selection, disclosure and pending state |
| `ui-foundation-composer` | composer frame and vertical rhythm | text, IME, submit/stop actions and authority confirmation |
| `ui-foundation-panel` | panel chrome and padding | content, validation, errors and actions |
| `ui-foundation-timeline` | list-role timeline column | entries, collapse state, status and navigation |

Each template has one unnamed `<slot/>`. Slots are expanded in the consumer's
Model/Msg scope, so the foundation never declares product bindings or a second
reducer. Token names and runtime semantics come from Native SDK; responsive
business visibility and custom geometry remain application-owned.

## Ejection And Pinning

The templates are shipped as part of the `ui-foundation` patch and are exposed
through the normal `native eject component` command. Ejection transfers source
ownership to the app; it does not create a runtime dependency on a moving
branch. Consumers must pin the VibeUnion distribution commit and verify the
patch manifest before ejection.

The manifest also records one `compatibility-only` artifact for applications
that must remain on Native SDK 0.9.5. It carries this UI foundation plus the
fail-closed TypeScript Core propagation of explicitly declared built-in bridge
commands required by the same consumer flow. It must be applied after the
exact runtime/compiler foundation from distribution `15fd874`; it is not part
of the active 0.10.1 patch order and does not revive the retired 0.9.5
distribution.

## Boundaries

The public layer excludes product routes, labels, provider/approval semantics,
pending/ACK state, credentials, filesystem policy, CodeSurface, TerminalSurface,
window/session reducers, and WebView UI. Platform accessibility, IME, text
shaping and packaging remain subject to the Native SDK backend support matrix.

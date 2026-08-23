# GPUI UI Library Parity Contract

## Goal

Expose a complete, machine-checkable Native SDK UI-library surface for the
public component modules shipped by the two pinned references:

- Zed `crates/ui` at `6bf539cd52126974eb0dbff667de02a696a737ec`
- `gpui-component` `crates/ui` at
  `334bbed2e8c47d606eb79ab05ddcebd60b823429`

"Parity" in this contract means that every public reference module has one
honest Native SDK counterpart with a real public entry point and deterministic
conformance evidence. A counterpart may be a retained widget, Native markup
element, stateless `canvas.Ui` composite, existing runtime/surface API, or an
algorithm/semantic contract. It is never an unimplemented placeholder.

## Ownership Boundary

The implementation must not embed the GPUI runtime or copy its application
ownership model. In particular it must not add another application context,
entity/global store, window loop, executor, focus manager, input/IME manager,
accessibility owner, or component-local product reducer.

Native SDK keeps the existing split:

- caller model: product state, selection, navigation, open/closed state, and
  pending/result state;
- `canvas.Ui` and Native markup: stateless view construction;
- retained canvas runtime: layout, drawing, focus traversal, interaction, and
  bounded retained presentation state;
- platform runtime: windows, native menus, clipboard, dialogs, input, IME, and
  accessibility integration.

## Scope

- Add one public `canvas.ui_library` registry containing every public module
  from both pinned references, including exact source counts and SHAs.
- Add a reproducible inventory generator and committed receipt that bind each
  module list to its authoritative file path, revision, and source SHA-256.
- Add explicit `canvas.Ui` constructors for every public retained widget that
  previously required the generic `el` escape hatch.
- Add stateless semantic composites for reference-library names that compose
  existing widgets, such as callouts, facepiles, command palettes, searchable
  lists, settings rows, description lists, and dock/sidebar shells.
- Reuse existing high-performance and platform seams for editor, chart,
  virtualization, native-menu, clipboard, focus, and navigation behavior.
- Document product-specific Zed modules as caller composition, not framework
  state or copied product UI.
- Add compile-time and runtime tests proving that every reference record has a
  non-empty, public Native SDK entry and that no record is classified missing.

## Non-goals

- No `gpui` Rust dependency.
- No WebView-based UI.
- No second state machine or global component manager.
- No local copy of Zed product state, docking persistence, editor state, table
  delegate state, notification manager, or command-palette state.
- No claim that Windows/Linux backend accessibility, complex text shaping, or
  real-backend conformance is complete. Those platform-runtime concerns are
  separate from UI-library API parity and must remain explicit.

## Acceptance

1. The generated receipt contains exactly 42 Zed UI modules and 57
   `gpui-component` modules at the pinned revisions and authoritative source
   hashes, with no duplicate module within a source; the registry matches it in
   both directions.
2. Every entry has one of the allowed implementation classes:
   `direct_widget`, `stateless_composite`, `runtime_surface`,
   `algorithm_contract`, `platform_owned`, `caller_owned`, or
   `product_composition`. There is no `missing` class.
3. Every `Ui.*` entry names a real declaration on `canvas.Ui(Msg)`; every
   markup entry resolves through the schema registry; every `canvas.*` entry
   names an exported canvas declaration.
4. The new semantic composites only derive widget trees from caller-owned
   inputs. They do not retain product state or report optimistic success.
   `Ui.hoverCard` exposes hover intent for its trigger and open card while the
   caller owns delay timers and the open/closed state.
5. Focused UI-library tests, `zig build test`, `scripts/gate.sh fast`,
   `scripts/gate.sh full`, and `pnpm --dir docs check` pass.
6. The final diff receives independent boundary and runtime review before it
   is pushed.

## Risk And Orchestration

- Risk: high, because this expands the public UI API and its conformance
  contract.
- Orchestration: one writer and two independent read-only reviewers.
- Base revision: `73e790867e3c86c54ca5c48d0d79dd464a277d90`.
- Rollback: reset consumers to the base revision; the change is additive and
  does not alter persisted widget-kind codes, markup codes, or runtime wire
  formats.

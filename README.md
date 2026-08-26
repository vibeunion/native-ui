# Native SDK

## VibeUnion Foundation Layer

This repository tracks a reusable cross-platform UI foundation on top of
Native SDK 0.10.1. It keeps application state in the caller-owned TypeScript
core and adds no second reducer, product store, browser runtime, or product
backend authority.

The public foundation contains:

- a machine-checked GPUI parity registry for all 42 public Zed UI modules and
  all 57 public `gpui-component` UI modules pinned by
  [`docs/GPUI_UI_LIBRARY_PARITY_CONTRACT.md`](./docs/GPUI_UI_LIBRARY_PARITY_CONTRACT.md);
- the absorbed cross-platform shortcut-capture capability contract, including
  lifecycle, focus ownership, one-shot capture, and the reserved `__capture__`
  command; macOS and Windows system engines implement it today, while Linux
  and Chromium-backed hosts report it unsupported;
- [`patches/native-sdk-0.10.1-runtime-foundation.patch`](./patches/native-sdk-0.10.1-runtime-foundation.patch),
  which adds a thin app-owned host extension, viewport-aware composition,
  bounded native surface input hooks, secure session-input handling, retained
  text-edit after-state, an atomically published host-worker wake seam,
  exactly-once host teardown, automation input pacing, and synchronized public
  TypeScript/bridge names for shortcut capture. Generated TypeScript Core
  launchers also carry only the built-in bridge commands explicitly declared
  by `app.zon`; absent or empty bridge policy remains disabled;
- [`patches/native-sdk-0.10.1-compiler-tooling.patch`](./patches/native-sdk-0.10.1-compiler-tooling.patch),
  which keeps compiler stack usage bounded for large cores, permits supported
  `DataView` decoding, and hardens external-core staging.
- [`patches/native-sdk-0.10.1-ui-foundation.patch`](./patches/native-sdk-0.10.1-ui-foundation.patch),
  which adds headless toolbar, sidebar, composer, panel, and timeline
  templates. They are ejected into an app and bind to the caller's own
  `Model`/`Msg`; they do not carry product routes, labels, pending state, or a
  second reducer.

Start with the [`Foundation Layer Guide`](./docs/FOUNDATION_USAGE.md) for
prerequisites, immutable pinning, ordered patch application, `ts_host.zig`
integration, platform support boundaries, release evidence, upgrade procedure,
and rollback. The normative ownership and acceptance rules remain in the
[`Public Foundation Contract`](./docs/PUBLIC_FOUNDATION_CONTRACT.md).

The patches apply in manifest order to the exact foundation revision recorded
in [`patches/manifest.json`](./patches/manifest.json). Validate provenance,
hashes, clean application, wire stability, and public-boundary scans with:

```bash
scripts/check-foundation-patches.sh
```

Add `--verify` for focused compiler/runtime tests or `--full` for the complete
Zig suite. Product-specific replay fixtures, environment policy, screen
capture prototypes, undeclared platform features, vendored compiler output,
and journal-format migrations are intentionally excluded.

### Consuming The Public UI Foundation

Read the [`Public UI Foundation Contract`](./docs/PUBLIC_UI_FOUNDATION_CONTRACT.md)
and pin the reviewed distribution commit before consuming the templates:

```bash
native eject component ui-foundation /absolute/path/to/your-app
```

The generated `src/components/ui_foundation.native` is application-owned. Use
`<use template="ui-foundation-toolbar">`,
`<use template="ui-foundation-sidebar">`,
`<use template="ui-foundation-composer">`,
`<use template="ui-foundation-panel">`, and
`<use template="ui-foundation-timeline">` as stateless frames around caller
content. The machine-readable inventory is
[`docs/public-ui-foundation-inventory.json`](./docs/public-ui-foundation-inventory.json).

Consumers that must remain on Native SDK 0.9.5 can apply the explicitly
non-active [`0.9.5 UI compatibility artifact`](./patches/compat/native-sdk-0.9.5-ui-foundation.patch)
after the runtime and compiler patches from distribution `15fd874`. Its exact
base, prerequisites, and hash are recorded in the current manifest. This does
not reactivate the retired 0.9.5 runtime/compiler distribution on `main`.

## GPUI-Ecosystem UI Component Library

The foundation adds a public Native SDK counterpart for every module in two
pinned GPUI-ecosystem catalogs: **99 modules total, 42 from Zed `crates/ui`
plus 57 from `gpui-component`, with 0 missing entries**. This is a
machine-checked Native SDK component surface, not a GPUI runtime dependency or
an API-compatibility claim.

| Layer | Representative public entries | What it provides |
| --- | --- | --- |
| Controls | `Ui.button`, `Ui.accordion`, `Ui.alert`, `Ui.avatar`, `Ui.badge`, `Ui.checkbox`, `Ui.combobox`, `Ui.dialog`, `Ui.input`, `Ui.table`, `Ui.tooltip`, `Ui.tree` | Named retained controls with typed messages, semantics, and caller-owned values. |
| Composites | `Ui.callout`, `Ui.commandPalette`, `Ui.descriptionList`, `Ui.dock`, `Ui.form`, `Ui.hoverCard`, `Ui.searchableList`, `Ui.setting`, `Ui.sidebar`, `Ui.stepper` | Stateless builders that lower immediately to ordinary widgets without introducing component-local product state. |
| Surfaces and platform services | `Ui.chart`, `Ui.code`, `Ui.scroll`, `Ui.virtualList`, `Ui.nativeMenu`, clipboard effects | Existing bounded high-performance surfaces and platform-owned services instead of copied GPUI window, focus, input, or global-state machinery. |

Use the catalog through `native_sdk.canvas.Ui(Msg)`. Application state,
selection, open/closed state, validation, and pending/result state stay in the
caller's `Model`:

```zig
const native_sdk = @import("native_sdk");
const Ui = native_sdk.canvas.Ui(Msg);

fn commandView(ui: *Ui, model: Model) Ui.Node {
    const save = ui.button(.{ .on_press = .save }, "Save");
    const search = ui.searchField(.{
        .text = model.query,
        .on_input = Ui.inputMsg(.query_changed),
    });
    const results = ui.list(.{}, commandRows(ui, model));

    return ui.column(.{ .gap = 12 }, .{
        save,
        ui.commandPalette(.{ .on_dismiss = .close_commands }, search, results),
    });
}
```

The registry records each reference module, its concrete Native SDK entry
point, and one honest implementation class: direct widget, stateless
composite, runtime surface, algorithm contract, platform-owned service,
caller-owned state, or product composition. Compile-time and runtime tests
reject duplicate, unresolved, or missing entries.

### Zed crates/ui coverage (42)

- **Direct widgets (11):** avatar, button, dropdown_menu, icon, image, list,
  popover, progress, stack, toggle, tooltip.
- **Stateless composites (22):** banner, callout, chip, count_badge,
  data_table, diff_stat, disclosure, divider, facepile, group, indicator,
  keybinding, keybinding_hint, label, modal, notification, popover_menu,
  redistributable_columns, sticky_items, tab, tab_bar, tree_view_item.
- **Runtime surfaces (2):** indent_guides, scrollbar.
- **Platform-owned services (2):** context_menu, right_click_menu.
- **Caller-owned navigation (1):** navigable.
- **Algorithm contract (1):** gradient_fade.
- **Product compositions (3):** ai, collab, project_empty_state.

### gpui-component coverage (57)

- **Direct widgets (28):** accordion, alert, avatar, badge, breadcrumb,
  button, checkbox, combobox, dialog, input, list, pagination, popover,
  progress, radio, resizable, select, separator, sheet, skeleton, slider,
  spinner, status_bar, switch, table, text, tooltip, tree.
- **Stateless composites (21):** collapsible, color_picker, command,
  description_list, dock, form, group_box, history, hover_card, kbd, label,
  link, menu, notification, rating, searchable_list, setting, sidebar,
  stepper, tab, tag.
- **Runtime surfaces (3):** chart, highlighter, scroll.
- **Platform-owned services (2):** clipboard, native_menu.
- **Caller-owned state and tokens (2):** global_state, theme.
- **Algorithm contract (1):** plot.

Start with the [UI-library parity guide](./docs/src/app/docs/ui-library-parity/page.mdx)
for usage and ownership examples. The
[parity contract](./docs/GPUI_UI_LIBRARY_PARITY_CONTRACT.md),
[public registry](./src/primitives/canvas/ui_library.zig), and generated
[inventory receipt](./src/primitives/canvas/testdata/ui_library_inventory_receipt.json)
are the machine-checkable sources of truth.

UI-library parity is a platform-neutral API and ownership claim, not a claim
that every OS backend has identical accessibility, text, IME, packaging, or
custom-host evidence. See the guide and
[`Platform Support`](https://native-sdk.dev/docs/platform-support) before
making a platform release claim.

**Native SDK is the complete toolkit for building native desktop applications.**

Native SDK exists because expressive UI and native performance should not be competing goals. Developers often choose web-based runtimes because they offer freedom, speed and control over the product experience. But that freedom often comes with a heavy runtime. Native SDK keeps the expressive authoring model and replaces the runtime with native rendering.

Views are declarative markup in `.native` files, logic is plain TypeScript compiled to native code at build time — or Zig, first-class by choice — and Native SDK's own engine draws every pixel into real OS windows. No browser, no WebView, no JS runtime in the binary: Zig is how everything works, TypeScript and Native markup are how apps are authored.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/soundboard-dark.webp">
  <img src=".github/assets/soundboard-light.webp" alt="The Soundboard example app rendered by the Native SDK engine: a music library with album cover art, search, and a playback bar" width="100%">
</picture>

<table>
  <tr>
    <td width="70%">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset=".github/assets/notes-dark.webp">
        <img src=".github/assets/notes-light.webp" alt="The Notes example app rendered by the Native SDK engine: a three-pane notes manager with folders, a note list, and an open note" width="640">
      </picture>
    </td>
    <td width="30%">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset=".github/assets/calculator-dark.webp">
        <img src=".github/assets/calculator-light.webp" alt="The Calculator example app rendered by the Native SDK engine: a finished calculation above a full keypad" width="270">
      </picture>
    </td>
  </tr>
</table>

<sub>Soundboard, Notes, and Calculator from <a href="./examples">examples/</a> — every pixel drawn by the Native SDK engine, captured through its deterministic reference renderer. The images follow your color scheme.</sub>

## Quick start

Install the CLI:

```bash
npm install -g @native-sdk/cli
```

Create and run an app:

```bash
native init my_app
cd my_app
native dev
```

A native window opens with a working counter. The whole app is three files of truth — view, logic, manifest — and no build config. The view is `src/app.native`, a markup file that binds values and dispatches messages (the counter row at its heart):

```html
<row gap="8" main="center" cross="center" grow="1">
  <button variant="secondary" on-press="decrement">-</button>
  <text>{count}</text>
  <button variant="primary" on-press="increment">+</button>
</row>
```

All logic lives in `src/core.ts`: a `Model` interface, a `Msg` union, and one pure `update` function — the only place state changes, plain TypeScript compiled to native code at build time:

```ts
export function update(model: Model, msg: Msg): Model {
  switch (msg.kind) {
    case "increment":
      return { ...model, count: model.count + 1 };
    case "decrement":
      return { ...model, count: model.count - 1 };
    case "reset":
      return { ...model, count: 0 };
  }
}
```

Prefer Zig for the core? `native init my_app --template zig-core` scaffolds the same app with `src/main.zig` — same loop, same runtime, first-class by choice.

Edit `src/app.native` while `native dev` runs and the window updates in place, keeping your state. `native dev --core` runs the TypeScript core under node for instant logic checks, `native check` validates the core and every view in milliseconds without building, and `native build` produces an optimized release binary.

Read the full guide at [native-sdk.dev/quick-start](https://native-sdk.dev/quick-start).

## What you get

**Beautiful by default** — Great software should not start from a blank slate. The built-in component catalog — buttons, tabs, text fields, dialogs, charts, virtual lists, and more — ships with considered typography, spacing, and color, so the app `native init` scaffolds already looks intentional the first time its window opens.

**Customizable by design** — Your app should have its own identity, not ours. Styling is design tokens end to end: color, radius, and typography resolve by name, re-resolve live when the theme changes, and can be replaced wholesale — `examples/soundboard` and `examples/deck` are the same music player separated only by tokens and a chrome pass.

**Native from the start** — Every interface is rendered without a browser or WebView. The engine draws into real OS windows while scroll physics, menus, dialogs, the tray, and text input stay with the operating system, and markup compiles into the executable at build time, so a release build carries no parser or interpreter — the scaffolded counter app builds to a single binary a few megabytes small.

**Predictable state** — State changes should be explicit, inspectable and easy to reason about. Events produce messages, messages update state, and state renders the interface; markup can bind and dispatch but never mutate. The loop is so deterministic that `native automate record` journals a session and `replay` reproduces it headlessly, verified frame by frame against state fingerprints.

**Simple authoring** — Interfaces should be easy to read, easy to write and easy to generate. Views are elements, flex layout, `{bindings}`, and expressions like `selected="{f == filter}"`, and `native check` validates every view against your app's actual `Model` and `Msg` — bindings, iterables, message tags — in milliseconds, with `file:line:column` errors that teach.

**AI is part of the workflow** — Native SDK is designed for a world where humans and AI agents build software together. Every app embeds an automation server, so any agent can read accessibility snapshots, drive widgets, assert on live state, and take deterministic screenshots of the running window; accessibility findings are machine-checked in `native check`; and the CLI ships the agent skills that teach all of it (`native skills list`).

## Examples

The apps pictured above live in [examples/](./examples), most as zero-config projects with a manifest plus `src/` and no build files, run straight from their directory with `native dev`. Many examples predate the current `app.json` default and retain `app.zon`; both formats have the same capabilities. Start with the TypeScript examples when learning the primary authoring path. The `-ts` suffix on `soundboard-ts` and `system-monitor-ts` is historical because those apps are ports kept beside older Zig originals. Chatbot is TypeScript-only and follows the unsuffixed naming used by new apps created with `native init`.

| Example | What it shows |
| --- | --- |
| [`chatbot`](./examples/chatbot) | TypeScript + Native markup end to end: modules, a text editor, streaming fetch effects, and replay-safe configuration. |
| [`soundboard-ts`](./examples/soundboard-ts) | The full music-player showcase in TypeScript + Native markup: audio, search, assets, timers, and context menus. |
| [`system-monitor-ts`](./examples/system-monitor-ts) | A live process monitor in TypeScript + Native markup: subprocess effects, tables, charts, and timers. |
| [`calculator`](./examples/calculator) | A complete small app: markup keypad, keyboard input, chrome shortcuts, theming. |
| [`notes`](./examples/notes) | Persistence through the effects channel: debounced writes, restore on boot, dialogs, search. |
| [`soundboard`](./examples/soundboard) | Album grid with decoded cover art, context menus, timers, and a custom theme. |
| [`deck`](./examples/deck) | The soundboard player rebuilt as a dense hardware chassis: two windows, same widgets, different tokens. |
| [`feed`](./examples/feed) | A 100,000-row list, virtualized with runtime-owned scrolling. |

The unsuffixed showcase apps above predate the TypeScript default and retain their Zig cores as first-class alternative implementations. The full catalog in [examples/README.md](./examples/README.md) also covers guarded OS capabilities, GPU surfaces, WebView composition, web-frontend shells, and the iOS/Android embed hosts.

## Platforms

macOS is the primary development platform and carries the deepest support: Metal presentation, OS scroll physics, native context menus, app menus, tray, and dialogs. Linux runs the full showcase through the deterministic software renderer in real windows, with pointer, keyboard, scroll, native context menus, IME composition, and HiDPI; Windows runs on a Win32 host with native context menus and IME composition and is exercised in CI, including real input injection. Mobile support is experimental: iOS is simulator-proven through the embed library and Android cross-compiles with the full embed ABI, but APIs and tooling on both are still evolving — desktop is the mature surface. WebView surfaces coexist on every desktop platform. The [platform support matrix](https://native-sdk.dev/platform-support) documents exactly what each host supports today.

## Documentation

The full documentation is at [native-sdk.dev](https://native-sdk.dev).

- [Quick Start](https://native-sdk.dev/quick-start) — install to a running, tested app
- [Philosophy](https://native-sdk.dev/philosophy) — the six principles behind the toolkit
- [App Model](https://native-sdk.dev/app-model) — the model/message/update loop, wiring, and hot reload
- [TypeScript Cores](https://native-sdk.dev/typescript) — the app-core subset, effects, subscriptions, and the node dev loop
- [Native UI](https://native-sdk.dev/native-ui) — every element, attribute, and pattern in the markup
- [Components](https://native-sdk.dev/components) — the component catalog
- [State & Data Flow](https://native-sdk.dev/state) — derive-don't-store, bindings, and text editing
- [Testing](https://native-sdk.dev/testing) — full-loop UI tests, headless on any machine
- [Automation](https://native-sdk.dev/automation) — snapshots, widget driving, record/replay, screenshots
- [Capabilities](https://native-sdk.dev/capabilities) — guarded OS services: notifications, clipboard, dialogs, credentials
- [Packaging](https://native-sdk.dev/packaging) — from binary to distributable app
- [Platform Support](https://native-sdk.dev/platform-support) — what each host supports today

## Contributing

Native SDK is pre-1.0: APIs still move, and the toolkit is evolving quickly. Bug reports and focused pull requests are welcome — for larger changes, open an issue first so the design can be discussed. See [CONTRIBUTING.md](./CONTRIBUTING.md) for the development setup and local checks.

## License

[Apache-2.0](./LICENSE)

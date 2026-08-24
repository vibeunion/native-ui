# Foundation Layer Guide

This guide explains how to consume, integrate, verify, upgrade, and roll back
the VibeUnion cross-platform UI foundation. The machine-readable source of
truth is [`patches/manifest.json`](../patches/manifest.json); this document does
not replace its exact revisions or hashes.

## What The Foundation Contains

The repository has two kinds of foundation content:

1. Capabilities already present in the recorded foundation revision:
   - the GPUI parity registry for all 42 pinned Zed UI modules and all 57
     pinned `gpui-component` UI modules;
   - the shortcut-capture contract, with system implementations on macOS and
     Windows and explicit unsupported results on Linux and Chromium-backed
     hosts.
2. Generic Native SDK 0.9.5 changes distributed as ordered patches:
   - `native-sdk-0.9.5-runtime-foundation.patch` adds the optional thin native
     host, viewport-aware composition, bounded surface input, secure recording
     refusal, retained text-edit after-state, worker wakeup, exactly-once host
     teardown, and automation input pacing;
   - `native-sdk-0.9.5-compiler-tooling.patch` adds the Node stack budget,
     supported `DataView` use, and symbol-aware external-core `Bytes` folding.

The patches do not contain application reducers, backend bindings, product
policy, private paths, provider logic, credentials, or a browser runtime.

## Support Boundaries

"Cross-platform foundation" describes shared API and behavior contracts. It
does not mean that every backend has identical implementation maturity or that
the custom-host fixture has run on every operating system.

| Surface | Current claim | Explicit boundary |
| --- | --- | --- |
| UI library | Every module in the two pinned GPUI catalogs has a real Native SDK entry and a machine-checked ownership class. | Catalog parity is not real-host accessibility, text shaping, IME, or packaging parity. |
| Shortcut capture | The lifecycle and command contract is shared; macOS and Windows system engines implement it. | Linux and Chromium-backed hosts report it unsupported. |
| Runtime/tooling patches | The patch set is platform-neutral where the underlying Native SDK seam is platform-neutral. | Platform-specific behavior still follows the Native SDK support matrix. |
| Thin `ts_host.zig` fixture | The formal app build proves the extension API, ownership rejection, lifecycle, and default-host fallback. | The committed fixture currently targets macOS/Metal; Windows and Linux custom-host builds need separate CI evidence before making that narrower claim. |

See [GPUI UI Library Parity](./GPUI_UI_LIBRARY_PARITY_CONTRACT.md) for the
catalog contract and the Native SDK
[Platform Support](https://native-sdk.dev/docs/platform-support) page for
backend-specific capabilities.

## Prerequisites

- Git with worktree support.
- Zig 0.16.0 for build verification.
- Node.js 24 or newer and npm for TypeScript compiler/tooling verification.
- `rg` (ripgrep) for the public-boundary gate.

The default `check` mode needs Git, Node.js, and `rg`. The `--verify` and
`--full` modes also compile and test Native SDK, so they require the relevant
host toolchain. The current release evidence was recorded on macOS.

## Pin And Verify The Distribution

Clone the repository, pin a commit instead of following a moving branch, and
run the provenance gate before using any patch:

```bash
git clone https://github.com/vibeunion/native-ui.git
cd native-ui
git checkout <reviewed-foundation-commit>

scripts/check-foundation-patches.sh
```

The gate verifies that:

- the foundation commit resolves to the exact tree in the manifest;
- every patch SHA-256 matches the manifest;
- patches apply in manifest order and reverse back to the exact base;
- patch additions contain no product/private material or excluded features;
- the patch set does not change the runtime wire version.

Use the stronger modes when preparing an integration or release:

```bash
scripts/check-foundation-patches.sh --verify
scripts/check-foundation-patches.sh --full
```

`--verify` runs focused TypeScript, tooling, runtime-core, UI-shell, default
host, and custom host gates. It also proves that `ts_host.zig` cannot declare a
second reducer and that `hostPoll` cannot compile without `deinit`. `--full`
adds the complete serial Zig suite.

## Apply The Patches

Apply the patches to a clean worktree at the exact base revision from the
manifest. Do not apply them to an npm cache or mutate an already published SDK
tree in place.

```bash
foundation=/absolute/path/to/native-ui
base=$(node -e \
  'const m=require(process.argv[1]); process.stdout.write(m.foundation.base_revision)' \
  "$foundation/patches/manifest.json")
patched="$(dirname "$foundation")/native-ui-patched"

git -C "$foundation" worktree add --detach "$patched" "$base"
cd "$patched"

git apply --check "$foundation/patches/native-sdk-0.9.5-runtime-foundation.patch"
git apply "$foundation/patches/native-sdk-0.9.5-runtime-foundation.patch"
git apply --check "$foundation/patches/native-sdk-0.9.5-compiler-tooling.patch"
git apply "$foundation/patches/native-sdk-0.9.5-compiler-tooling.patch"
```

The order is part of the distribution contract. A base-tree mismatch or patch
failure is a stop condition, not permission to use `--reject`, skip a hunk, or
continue with a mixed SDK.

## Integrate A Thin Native Host

TypeScript Core remains the only application `Model`, `Msg`, `initialModel`,
and `update` authority. Most applications need no native host at all; the
runner supplies an empty default host when `src/ts_host.zig` is absent.

Add `src/ts_host.zig` only for a bounded native extension. The supported public
hooks are:

- `tokens` for model-derived `DesignTokens`;
- `viewViewport`, or `view`, for stateless native composition;
- `surfaceKeyMsg` and `surfaceTextEdit` for bounded native-surface input
  mapping;
- `secureInputWidgetIds` for retained inputs whose committed text must never
  enter a session journal;
- `markupSources` and `fragments` for compiled markup source sets;
- `hostPoll` for adopting worker completions on the loop thread;
- `deinit` for exactly-once native-host shutdown.

The runtime patch materializes a neutral reference at
`examples/ts-host-foundation/src/ts_host.zig`. Its minimal lifecycle shape is:

```zig
const native_sdk = @import("native_sdk");

pub fn viewViewport(
    comptime core: type,
    ui: anytype,
    model: *const core.Model,
    viewport: native_sdk.geometry.SizeF,
) @TypeOf(ui.*).Node {
    _ = model;
    return ui.text(.{}, ui.fmt("{d:.0}x{d:.0}", .{
        viewport.width,
        viewport.height,
    }));
}

pub fn hostPoll(effects: anytype) void {
    // Move completed worker results into effects.feedHostResult here.
    _ = effects;
}

pub fn deinit() void {
    // Stop and join every worker that can call effects.requestWake().
}
```

An asynchronous host follows this sequence:

1. The loop starts bounded external work and records its request key.
2. A worker stores the completion in host-owned transport state.
3. The worker calls `Effects.requestWake()`; it never mutates the model.
4. The platform loop invokes `hostPoll`, which calls `feedHostResult` for the
   matching key, and the ordinary effects drain dispatches the TypeScript
   result message.
5. `deinit` stops and joins every worker. The runtime then revokes the wake
   binding, so later `requestWake()` calls fail with `HostWakeUnavailable`.

Declaring `Model`, `Msg`, reducer functions, command/subscription factories, or
generated core surfaces in `ts_host.zig` is a compile-time error. A host that
declares `hostPoll` without `deinit` is also rejected at compile time and by
the lower-level `UiApp` options contract.

## Secure Input

`secureInputWidgetIds` is a recording boundary, not a secret store. When a
listed retained input receives committed text:

- the live text edit still reaches the retained widget and application flow;
- session recording fails closed before raw input is staged;
- the partial journal remains unsealed and replay refuses it.

Use the platform credential APIs for durable secrets. Do not log, replay, or
copy sensitive text into application state merely because a widget id is
marked secure.

## Current Release Evidence

The public artifacts dated August 24, 2026 have these hashes:

- runtime foundation:
  `0e7a644b43fc508710c4fe660cec4ad0e7606f1d6330a9e6fe2e40483c02b50e`;
- compiler/tooling:
  `1562078cdcc3a819f817e3711eb0ae2d746c63839793ce49e5273e956e286552`.

The final local gates reported:

- TypeScript focused tests: 94 passed;
- Native tooling: 200 passed;
- runtime core: 688 passed, 12 skipped;
- UI shell: 176 passed;
- full Zig suite: 662 of 662 build steps succeeded, 3514 tests passed, 15
  skipped;
- two independent read-only reviews: PASS.

These results prove the recorded artifact on the recorded host. They do not
replace downstream application tests, real backend checks, signing, packaging,
or release CI.

## Upgrade Procedure

Native SDK is pre-1.0. Treat every SDK update as a breaking migration:

1. Record the old foundation commit, base tree, patch hashes, and a rollback
   worktree.
2. Verify the new official SDK revision and its release tree.
3. Start from a clean detached worktree of that revision.
4. Classify each old patch as absorbed, obsolete, or still required. Delete
   absorbed/obsolete patches and minimally rebase only required behavior.
5. Regenerate patch artifacts from the clean tree. Do not keep active patches
   for two SDK versions in one manifest.
6. Update the SDK version, release/base revisions, trees, patch order, hashes,
   wire version, and journal declaration together.
7. Run `check`, `--verify`, and `--full`, then obtain fresh independent review
   for the final hashes.
8. Publish a new immutable commit and verify its remote SHA.

A wire or journal change requires an explicit compatibility/migration contract
and new replay evidence. Do not leave `journal_layout_changed` false when the
journal actually changed.

## Rollback

For an uncommitted consumer worktree, reverse in the opposite order:

```bash
foundation=/absolute/path/to/native-ui
git apply --reverse "$foundation/patches/native-sdk-0.9.5-compiler-tooling.patch"
git apply --reverse "$foundation/patches/native-sdk-0.9.5-runtime-foundation.patch"
```

For an immutable integration, switch the consumer back to its recorded base or
previous reviewed foundation commit. Preserve the old patch artifacts until no
running build or release references them. The current patch set keeps wire
version 8 and does not change the journal layout, so rollback requires no data
migration from this foundation alone.

## Failure Guide

- `foundation base tree mismatch`: the selected base is not the reviewed
  source tree; stop and select the manifest revision.
- `patch hash mismatch`: the artifact changed; restore it or produce a new
  manifest and full review.
- `product, private-path, or credential material found`: remove the leaked
  application-specific content instead of weakening the scanner.
- `hostPoll requires deinit`: implement worker stop/join teardown or remove
  asynchronous host polling.
- `HostWakeUnavailable`: the worker requested a wake before services were
  bound or after teardown; fix the host lifecycle.
- an unsupported platform capability: hide or disable the product entry, or
  add and verify a real platform seam. Do not substitute a no-op or fake
  success.

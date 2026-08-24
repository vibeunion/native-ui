# Public Foundation Contract

## Goal

Publish the reusable cross-platform UI surface and generic Native SDK 0.9.5
patches without carrying application-specific state, runtime policy, backend
bindings, replay fixtures, or private build paths.

## Ownership

- The caller-owned TypeScript core remains the only application `Model`, `Msg`,
  and `update` authority.
- Native markup and `canvas.Ui` own declarative composition only.
- The retained runtime owns bounded layout, drawing, focus, text editing,
  accessibility, input, and automation state.
- An optional `src/ts_host.zig` is a thin native extension. It may expose
  tokens, a view, host completion polling, bounded surface input mapping,
  markup fragments, secure widget ids, and teardown. Compile-time validation
  rejects a second application reducer or generated core surface.
- App-owned host workers may call `Effects.requestWake` only while the host
  lifecycle is active. The runtime publishes the platform wake service
  atomically, invokes host polling on frames and wake events, and revokes the
  binding immediately after exactly-once host teardown has joined workers.
  A host that declares polling without teardown is rejected at compile time
  and by the lower-level UiApp options contract.
- Platform and backend authority remain outside this repository.

## Included

1. The GPUI parity registry at revision `5a079b5`, covering 42 Zed modules and
   57 `gpui-component` modules with no missing entry.
2. The shortcut-capture capability contract at revision `73e7908`, retaining
   the internal `__capture__` sentinel and user shortcut-id validation. The
   macOS and Windows system engines implement it; Linux and Chromium-backed
   hosts remain explicitly unsupported. The runtime patch keeps the public
   `NativeSdkPlatformFeature` type and bridge mapping synchronized for both
   `shortcut_capture` and `shortcutCapture` callers.
3. A runtime patch for thin host composition, viewport-aware views, surface
   input handoff, secure recording refusal, after-state access, exactly-once
   host teardown, and automation input pacing.
4. A separate compiler/tooling patch for Node stack budget, supported
   `DataView` construction, and external-core import staging.

## Excluded

- Application names, reducers, backend bindings, provider logic, approvals,
  projects, workspaces, or private identifiers.
- Synthetic replay modes or application-specific environment variables.
- Screen capture prototypes, global hotkey/configuration feature ids, or any
  capability without a complete cross-platform lifecycle contract.
- Wire-version downgrade, journal epoch change, or window-chrome replay
  migration.
- Patches against vendored `node_modules` output.

## Acceptance

1. Every patch hash matches `patches/manifest.json`.
2. Both patches apply cleanly, in order, to
   `5a079b5f826deed7a4c179c5d645c651f976e234` and reverse cleanly.
3. Patch additions contain no product environment prefixes, private paths,
   credential material, excluded feature ids, or wire-version edits.
4. Focused TypeScript, runtime-core, UI-shell, tooling, validation,
   contract-staging, public package mirror/runtime-type synchronization,
   default-host app, and custom-host app checks pass. The custom-host gate also
   proves reducer ownership rejection. The complete Zig suite is required
   before a release claim.
5. One writer and two independent read-only reviewers approve the final
   artifacts before push.

## Published Evidence

The August 24, 2026 foundation publication records:

- runtime patch SHA-256
  `fda6ab4bdf497829605aaa84f794a05ba3e34b3d07bee86e4e0768f4bd4f3b23`;
- compiler/tooling patch SHA-256
  `1562078cdcc3a819f817e3711eb0ae2d746c63839793ce49e5273e956e286552`;
- focused gates: the public package mirror and runtime TypeScript contract were
  synchronized; TypeScript 94 passed, tooling 200 passed, runtime core 688
  passed and 12 skipped, UI shell 176 passed, plus default/custom host builds
  and the ownership/lifecycle negative compile gates;
- complete Zig gate: 662 of 662 build steps succeeded, 3514 tests passed, and
  15 skipped;
- two independent read-only reviewer verdicts: PASS.

The custom-host fixture in this evidence targets macOS/Metal. The foundation
API remains platform-neutral where the underlying Native SDK contract is
platform-neutral, but a Windows or Linux custom-host release claim requires
corresponding CI or real-host evidence. Operational instructions and rollback
steps live in [`FOUNDATION_USAGE.md`](./FOUNDATION_USAGE.md).

## Risk And Rollback

- Risk: high, because the runtime patch adds public extension seams and secure
  recording behavior.
- Orchestration: one writer plus two independent read-only reviewers.
- Rollback: consumers remove the patches or reset to the recorded base
  revision. No persisted wire or journal version is changed.

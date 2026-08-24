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
   hosts remain explicitly unsupported.
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
   contract-staging, default-host app, and custom-host app checks pass. The
   custom-host gate also proves reducer ownership rejection. The complete Zig
   suite is required before a release claim.
5. One writer and two independent read-only reviewers approve the final
   artifacts before push.

## Risk And Rollback

- Risk: high, because the runtime patch adds public extension seams and secure
  recording behavior.
- Orchestration: one writer plus two independent read-only reviewers.
- Rollback: consumers remove the patches or reset to the recorded base
  revision. No persisted wire or journal version is changed.

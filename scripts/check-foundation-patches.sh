#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/patches/manifest.json"

MODE="${1:-check}"
if [[ "$MODE" != "check" && "$MODE" != "--verify" && "$MODE" != "--full" ]]; then
  echo "usage: scripts/check-foundation-patches.sh [--verify|--full]" >&2
  exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required" >&2
  exit 2
fi
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required" >&2
  exit 2
fi

BASE="$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.foundation.base_revision)' "$MANIFEST")"
BASE_TREE="$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.foundation.base_tree)' "$MANIFEST")"
PATCHES=()
EXPECTED_SHA256=()
while IFS=$'\t' read -r path sha; do
  PATCHES+=("patches/$path")
  EXPECTED_SHA256+=("$sha")
done < <(node -e 'const m=require(process.argv[1]); for (const p of [...m.patches].sort((a,b)=>a.order-b.order)) console.log(`${p.path}\t${p.sha256}`)' "$MANIFEST")
if [[ "${#PATCHES[@]}" -eq 0 ]]; then
  echo "manifest declares no patches" >&2
  exit 1
fi

hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

actual_tree="$(git -C "$ROOT" show -s --format=%T "$BASE")"
if [[ "$actual_tree" != "$BASE_TREE" ]]; then
  echo "foundation base tree mismatch: expected $BASE_TREE, got $actual_tree" >&2
  exit 1
fi

for index in "${!PATCHES[@]}"; do
  patch_path="$ROOT/${PATCHES[$index]}"
  actual_sha="$(hash_file "$patch_path")"
  if [[ "$actual_sha" != "${EXPECTED_SHA256[$index]}" ]]; then
    echo "patch hash mismatch: ${PATCHES[$index]}" >&2
    exit 1
  fi
done

UI_INVENTORY="$ROOT/$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.ui_foundation?.inventory_path || "")' "$MANIFEST")"
UI_TEMPLATE_SOURCE="$ROOT/$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.ui_foundation?.template_source_path || "")' "$MANIFEST")"
UI_PUBLIC_API="$ROOT/$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.ui_foundation?.public_api_path || "")' "$MANIFEST")"
UI_PATCH="$ROOT/patches/$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.patches.find((p) => p.scope === "ui-foundation")?.path || "")' "$MANIFEST")"
UI_INVENTORY_SHA_EXPECTED="$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.ui_foundation?.inventory_sha256 || "")' "$MANIFEST")"
UI_TEMPLATE_SHA_EXPECTED="$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.ui_foundation?.template_source_sha256 || "")' "$MANIFEST")"
UI_PUBLIC_API_SHA_EXPECTED="$(node -e 'const m=require(process.argv[1]); process.stdout.write(m.ui_foundation?.public_api_sha256 || "")' "$MANIFEST")"
UI_TEMPLATE_COUNT="$(node -e 'const m=require(process.argv[1]); process.stdout.write(String(m.ui_foundation?.template_count || 0))' "$MANIFEST")"
COMPAT_UI_PATCH="$ROOT/patches/$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts?.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a?.path || "")' "$MANIFEST")"
COMPAT_UI_SHA_EXPECTED="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts?.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a?.sha256 || "")' "$MANIFEST")"
COMPAT_BASE="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts?.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a?.base_revision || "")' "$MANIFEST")"
COMPAT_BASE_TREE="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts?.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a?.base_tree || "")' "$MANIFEST")"
COMPAT_DISTRIBUTION="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts?.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a?.prerequisite_distribution_commit || "")' "$MANIFEST")"
COMPAT_MANIFEST_SHA_EXPECTED="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts?.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a?.prerequisite_manifest_sha256 || "")' "$MANIFEST")"
[[ -f "$UI_INVENTORY" && -f "$UI_TEMPLATE_SOURCE" && -f "$UI_PUBLIC_API" && -f "$UI_PATCH" ]] || {
  echo "ui-foundation manifest paths are incomplete" >&2
  exit 1
}
[[ -f "$COMPAT_UI_PATCH" ]] || { echo "0.9.5 UI compatibility patch is missing" >&2; exit 1; }
[[ "$(hash_file "$COMPAT_UI_PATCH")" == "$COMPAT_UI_SHA_EXPECTED" ]] || { echo "0.9.5 UI compatibility patch hash mismatch" >&2; exit 1; }
[[ "$(git -C "$ROOT" show -s --format=%T "$COMPAT_BASE")" == "$COMPAT_BASE_TREE" ]] || { echo "0.9.5 UI compatibility base tree mismatch" >&2; exit 1; }
compat_manifest_sha="$(git -C "$ROOT" show "$COMPAT_DISTRIBUTION:patches/manifest.json" | shasum -a 256 | awk '{print $1}')"
[[ "$compat_manifest_sha" == "$COMPAT_MANIFEST_SHA_EXPECTED" ]] || { echo "0.9.5 prerequisite manifest hash mismatch" >&2; exit 1; }
[[ "$(hash_file "$UI_INVENTORY")" == "$UI_INVENTORY_SHA_EXPECTED" ]] || { echo "ui-foundation inventory hash mismatch" >&2; exit 1; }
[[ "$(hash_file "$UI_TEMPLATE_SOURCE")" == "$UI_TEMPLATE_SHA_EXPECTED" ]] || { echo "ui-foundation template source hash mismatch" >&2; exit 1; }
[[ "$(hash_file "$UI_PUBLIC_API")" == "$UI_PUBLIC_API_SHA_EXPECTED" ]] || { echo "ui-foundation public API hash mismatch" >&2; exit 1; }
[[ "$(node -e 'const m=require(process.argv[1]); process.stdout.write(String(m.ui_foundation?.state_owner || ""))' "$MANIFEST")" == "caller" ]] || {
  echo "ui-foundation state ownership must remain caller-owned" >&2
  exit 1
}
actual_ui_template_count="$(node -e 'const m=require(process.argv[1]); process.stdout.write(String(m.templates?.length || 0))' "$UI_INVENTORY")"
[[ "$actual_ui_template_count" == "$UI_TEMPLATE_COUNT" ]] || { echo "ui-foundation template inventory count mismatch" >&2; exit 1; }
node - "$UI_INVENTORY" "$UI_TEMPLATE_SOURCE" "$UI_PUBLIC_API" <<'NODE'
const fs = require("node:fs");
const [inventoryPath, templatePath, apiPath] = process.argv.slice(2);
const inventory = JSON.parse(fs.readFileSync(inventoryPath, "utf8"));
const templateSource = fs.readFileSync(templatePath, "utf8");
const apiSource = fs.readFileSync(apiPath, "utf8");
const names = inventory.templates.map((item) => item.name);
if (new Set(names).size !== names.length) process.exit(1);
for (const name of names) {
  if (!templateSource.includes(`<template name="${name}"`)) process.exit(1);
  if (!apiSource.includes(`.name = "${name}"`)) process.exit(1);
}
NODE

patch_additions() {
  awk '/^\+\+\+ / { next } /^\+/ { print substr($0, 2) }' "${PATCHES[@]/#/$ROOT/}" "$COMPAT_UI_PATCH"
}

PUBLIC_BOUNDARY_PATTERN='VOLT_|CODEX_|agentd|/Users/|/Volumes/|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|api[_-]?key[[:space:]]*[:=]|(^|[^A-Za-z0-9_])(Volt|Codex|provider|approval|workspace|password|secret)([^A-Za-z0-9_]|$)'
if ! printf '%s\n' 'const product = "Volt provider approval workspace password secret";' | rg -q -i "$PUBLIC_BOUNDARY_PATTERN"; then
  echo "public-boundary scanner negative fixture was not rejected" >&2
  exit 1
fi
if patch_additions | rg -n -i "$PUBLIC_BOUNDARY_PATTERN"; then
  echo "product, private-path, or credential material found in public patches" >&2
  exit 1
fi
if patch_additions | rg -n -i 'screen_capture|global_hotkey|configure_shortcuts'; then
  echo "excluded platform feature found in public patches" >&2
  exit 1
fi
if patch_additions | rg -n 'wire_version'; then
  echo "public patches must not change the wire version" >&2
  exit 1
fi
if [[ "$(node -e 'const m=require(process.argv[1]); process.stdout.write(String(m.patches.filter((p) => p.scope === "ui-foundation").length))' "$MANIFEST")" != 1 ]]; then
  echo "manifest must declare exactly one ui-foundation patch" >&2
  exit 1
fi
if [[ "$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts?.filter((x)=>x.id==="native-sdk-0.9.5-ui-foundation") || []; process.stdout.write(String(a.length===1 && a[0].status==="compatibility-only"))' "$MANIFEST")" != true ]]; then
  echo "manifest must declare exactly one compatibility-only 0.9.5 UI artifact" >&2
  exit 1
fi
if awk '/^\+\+\+ / { next } /^\+/ { print substr($0, 2) }' "$UI_PATCH" "$COMPAT_UI_PATCH" | rg -n -i 'VOLT_|CODEX_|agentd|/Users/|/Volumes/|provider|approval|workspace|password|secret|screen_capture|global_hotkey'; then
  echo "ui-foundation patch contains product or private authority" >&2
  exit 1
fi

TMP="$(mktemp -d "/tmp/nui.XXXXXX")"
TREE="$TMP/tree"
COMPAT_TREE="$TMP/compat-tree"
added_worktree=false
added_compat_worktree=false
cleanup() {
  if [[ "$added_worktree" == true ]]; then
    git -C "$ROOT" worktree remove --force "$TREE" >/dev/null 2>&1 || true
  fi
  if [[ "$added_compat_worktree" == true ]]; then
    git -C "$ROOT" worktree remove --force "$COMPAT_TREE" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

git -C "$ROOT" worktree add --detach "$TREE" "$BASE" >/dev/null
added_worktree=true
for patch in "${PATCHES[@]}"; do
  git -C "$TREE" apply --check "$ROOT/$patch"
  git -C "$TREE" apply "$ROOT/$patch"
done
for ((index=${#PATCHES[@]} - 1; index >= 0; index--)); do
  git -C "$TREE" apply --reverse --check "$ROOT/${PATCHES[$index]}"
  git -C "$TREE" apply --reverse "$ROOT/${PATCHES[$index]}"
done
if [[ -n "$(git -C "$TREE" status --short)" ]]; then
  echo "patch reverse check did not restore the exact base" >&2
  git -C "$TREE" status --short >&2
  exit 1
fi
for patch in "${PATCHES[@]}"; do
  git -C "$TREE" apply "$ROOT/$patch"
done

compat_runtime_path="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a.prerequisite_patches[0].path)' "$MANIFEST")"
compat_compiler_path="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a.prerequisite_patches[1].path)' "$MANIFEST")"
compat_runtime_sha="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a.prerequisite_patches[0].sha256)' "$MANIFEST")"
compat_compiler_sha="$(node -e 'const m=require(process.argv[1]); const a=m.compatibility_artifacts.find((x)=>x.id==="native-sdk-0.9.5-ui-foundation"); process.stdout.write(a.prerequisite_patches[1].sha256)' "$MANIFEST")"
git -C "$ROOT" show "$COMPAT_DISTRIBUTION:patches/$compat_runtime_path" > "$TMP/compat-runtime.patch"
git -C "$ROOT" show "$COMPAT_DISTRIBUTION:patches/$compat_compiler_path" > "$TMP/compat-compiler.patch"
[[ "$(hash_file "$TMP/compat-runtime.patch")" == "$compat_runtime_sha" ]] || { echo "0.9.5 prerequisite runtime patch hash mismatch" >&2; exit 1; }
[[ "$(hash_file "$TMP/compat-compiler.patch")" == "$compat_compiler_sha" ]] || { echo "0.9.5 prerequisite compiler patch hash mismatch" >&2; exit 1; }
git -C "$ROOT" worktree add --detach "$COMPAT_TREE" "$COMPAT_BASE" >/dev/null
added_compat_worktree=true
for patch in "$TMP/compat-runtime.patch" "$TMP/compat-compiler.patch" "$COMPAT_UI_PATCH"; do
  git -C "$COMPAT_TREE" apply --check "$patch"
  git -C "$COMPAT_TREE" apply "$patch"
done
for patch in "$COMPAT_UI_PATCH" "$TMP/compat-compiler.patch" "$TMP/compat-runtime.patch"; do
  git -C "$COMPAT_TREE" apply --reverse --check "$patch"
  git -C "$COMPAT_TREE" apply --reverse "$patch"
done
if [[ -n "$(git -C "$COMPAT_TREE" status --short)" ]]; then
  echo "0.9.5 UI compatibility reverse check did not restore the exact base" >&2
  exit 1
fi

if [[ "$MODE" == "--verify" || "$MODE" == "--full" ]]; then
  npm --prefix "$TREE/packages/native-sdk" run scripts:check
  (
    cd "$TREE/packages/core"
    npm ci
    node --test \
      test/checker.test.ts \
      test/compiler_command.test.ts \
      test/external_core_compiler.test.ts \
      test/stage_external_core.test.ts
  )
  (
    cd "$TREE"
    zig build \
      validate \
      test-tooling \
      stage-core-contracts \
      test-desktop-runtime-core \
      test-desktop-ui-shell \
      test-eject-components \
      test-example-gpu-components \
      test-example-ts-host-foundation \
      --summary all
  )

  host_fixture="$TREE/examples/ts-host-foundation/src/ts_host.zig"
  host_fixture_backup="$TMP/ts_host.zig"
  cp "$host_fixture" "$host_fixture_backup"
  printf '\npub const Model = void;\n' >> "$host_fixture"
  set +e
  invalid_host_output="$(cd "$TREE" && zig build test-example-ts-host-foundation --summary all 2>&1)"
  invalid_host_status=$?
  set -e
  cp "$host_fixture_backup" "$host_fixture"
  if [[ "$invalid_host_status" -eq 0 ]]; then
    echo "invalid ts_host reducer declaration unexpectedly compiled" >&2
    exit 1
  fi
  if ! rg -q 'thin native extension and must not declare Model' <<<"$invalid_host_output"; then
    echo "invalid ts_host reducer declaration failed without the ownership diagnostic" >&2
    printf '%s\n' "$invalid_host_output" >&2
    exit 1
  fi

  awk '$0 != "pub fn deinit() void {}"' "$host_fixture_backup" > "$host_fixture"
  set +e
  missing_deinit_output="$(cd "$TREE" && zig build test-example-ts-host-foundation --summary all 2>&1)"
  missing_deinit_status=$?
  set -e
  cp "$host_fixture_backup" "$host_fixture"
  if [[ "$missing_deinit_status" -eq 0 ]]; then
    echo "ts_host hostPoll without deinit unexpectedly compiled" >&2
    exit 1
  fi
  if ! rg -q 'hostPoll requires deinit to stop and join every worker' <<<"$missing_deinit_output"; then
    echo "ts_host hostPoll without deinit failed without the lifecycle diagnostic" >&2
    printf '%s\n' "$missing_deinit_output" >&2
    exit 1
  fi
fi
if [[ "$MODE" == "--full" ]]; then
  (cd "$TREE" && zig build -j1 test --summary all)
fi

echo "foundation patches: PASS ($MODE)"

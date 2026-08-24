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

patch_additions() {
  awk '/^\+\+\+ / { next } /^\+/ { print substr($0, 2) }' "${PATCHES[@]/#/$ROOT/}"
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

TMP="$(mktemp -d "/tmp/nui.XXXXXX")"
TREE="$TMP/tree"
added_worktree=false
cleanup() {
  if [[ "$added_worktree" == true ]]; then
    git -C "$ROOT" worktree remove --force "$TREE" >/dev/null 2>&1 || true
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

if [[ "$MODE" == "--verify" || "$MODE" == "--full" ]]; then
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

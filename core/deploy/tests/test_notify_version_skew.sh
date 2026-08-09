#!/usr/bin/env bash
# test_notify_version_skew.sh — regression test for the SessionStart version-
# skew hook (core/hooks/notify-version-skew.sh).
#
# Guards the path-resolution + wiring fix. The hook must REACH the version
# comparison and emit a one-line notice on genuine skew, and stay SILENT when
# the local .version equals the latest published release tag — in BOTH layouts
# the single hook file runs from:
#   - source clone : <repo>/core/hooks/   with .version at the repo root
#   - deployed     : <ws>/.claude/hooks/  with the .version snapshot at
#                    <ws>/.claude/.version (shipped by setup-workspace.sh /
#                    refreshed by update.sh)
#
# Before the fix, even the skew cases were silent: SCRIPT_DIR/.. pointed at a
# directory with no .version, so the hook early-exited at the
# `[ -r VERSION_FILE ] || exit 0` guard before comparing anything. The
# "skew -> notice" cases are therefore the direct regression guard for the
# path bug; the "equal -> silent" cases prove the comparison still suppresses
# correctly; and the bash -x trace proves the comparison is actually reached.
#
# Hermetic: a private sandbox HOME holds a pre-seeded operator.toml + a FRESH
# release cache (so the hook's 24h TTL short-circuits the network) and a stub
# `gh` on PATH (satisfies the `command -v gh` probe; never invoked because the
# cache is fresh). No network; no operator state touched.
#
# Portable: exercises the hook directly (not setup-workspace.sh, which is
# Darwin-only), so it runs on macOS CI and Linux alike.
#
# Run from repo root:
#   bash core/deploy/tests/test_notify_version_skew.sh
#
# Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
HOOK_SRC="${REPO_ROOT}/core/hooks/notify-version-skew.sh"

PASS=0
FAIL=0
SBX=""

cleanup() {
  if [ -n "${SBX}" ] && [ -d "${SBX}" ]; then
    rm -rf "${SBX}"
  fi
}
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"
    PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"
    [ -n "${detail}" ] && printf '         %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

if [ ! -r "${HOOK_SRC}" ]; then
  printf 'FATAL: hook not found at %s\n' "${HOOK_SRC}" >&2
  exit 2
fi

SBX=$(mktemp -d -t notify-skew.XXXXXX)

# --- Shared sandbox HOME: operator.toml + a gh stub on PATH ------------------
# Reused across cases; only the per-case cache tag + .version vary.
HOME_SBX="${SBX}/home"
mkdir -p "${HOME_SBX}/.config/pmo-platform" \
         "${HOME_SBX}/.cache/pmo-platform" \
         "${HOME_SBX}/bin"

cat > "${HOME_SBX}/.config/pmo-platform/operator.toml" <<'TOML'
[identity]
operator_github = "test-owner"
[paths]
pmo_platform_repo_name = "pmo-platform"
TOML

# Stub gh: present on PATH so `command -v gh` passes. Never executed (every
# case writes a fresh cache, age 0 < 24h TTL), but make it loud-on-call so a
# future TTL/cache regression that reaches the network is surfaced, not masked.
cat > "${HOME_SBX}/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "UNEXPECTED gh CALL: $*" >&2
exit 1
STUB
chmod +x "${HOME_SBX}/bin/gh"

# write_cache <tag> — fresh cache (mtime = now) so the hook skips the fetch.
write_cache() {
  printf '{"tag_name": "%s", "name": "%s", "published_at": "2026-01-01T00:00:00Z"}\n' \
    "$1" "$1" > "${HOME_SBX}/.cache/pmo-platform/latest-release.json"
}

# stage_hook <case_root> <layout> <local_version> — materialize the hook + its
# .version in the requested layout; echo the hook path on stdout.
stage_hook() {
  local case_root="$1" layout="$2" local_version="$3"
  local hook_dir ver_path
  case "${layout}" in
    clone)    hook_dir="${case_root}/core/hooks";    ver_path="${case_root}/.version" ;;
    deployed) hook_dir="${case_root}/.claude/hooks"; ver_path="${case_root}/.claude/.version" ;;
    *) printf 'bad layout: %s\n' "${layout}" >&2; return 1 ;;
  esac
  mkdir -p "${hook_dir}"
  cp "${HOOK_SRC}" "${hook_dir}/notify-version-skew.sh"
  chmod +x "${hook_dir}/notify-version-skew.sh"
  printf '%s\n' "${local_version}" > "${ver_path}"
  printf '%s\n' "${hook_dir}/notify-version-skew.sh"
}

NOTICE_RE='available\. Run \./update\.sh'
CASE_N=0

# run_case <layout> <local_ver> <latest_ver> <expect: notice|silent> <name>
run_case() {
  local layout="$1" local_ver="$2" latest_ver="$3" expect="$4" name="$5"
  CASE_N=$((CASE_N + 1))
  local case_root="${SBX}/case-${CASE_N}"
  mkdir -p "${case_root}"

  local hook_path
  hook_path=$(stage_hook "${case_root}" "${layout}" "${local_ver}") || {
    report "${name}" 0 "stage_hook failed"
    return
  }
  write_cache "${latest_ver}"

  # The notice goes to stderr; capture both streams.
  local out
  out=$(HOME="${HOME_SBX}" PATH="${HOME_SBX}/bin:${PATH}" \
        bash "${hook_path}" 2>&1)

  if grep -qE "${NOTICE_RE}" <<<"${out}"; then
    if [ "${expect}" = "notice" ]; then
      report "${name}" 1
    else
      report "${name}" 0 "expected silence, got: ${out}"
    fi
  else
    if [ "${expect}" = "silent" ]; then
      report "${name}" 1
    else
      report "${name}" 0 "expected notice, got: '${out:-<empty>}'"
    fi
  fi
}

printf '\nVersion-skew hook regression (bash %s)\n' "${BASH_VERSION:-unknown}"

# --- Functional matrix: both layouts x {skew, equal} ------------------------
run_case clone    v1.00 v9.99 notice "source clone: skew -> notice"
run_case clone    v1.00 v1.00 silent "source clone: equal -> silent"
run_case deployed v1.00 v9.99 notice "deployed:     skew -> notice"
run_case deployed v1.00 v1.00 silent "deployed:     equal -> silent"

# --- Reaches-comparison proof (bash -x trace) -------------------------------
# Run a skew case under `bash -x` and assert the trace shows the version
# comparison itself (local `v1.00` tested with `!=` against latest `v9.99`) —
# direct evidence the hook reached the compare rather than early-exiting at an
# earlier guard. This is what a silent "equal" case alone cannot prove. The
# operand-around-`!=` pattern is robust across bash xtrace dialects: bash 3.2
# renders `'[' v1.00 '!=' v9.99 ']'`, newer bash `[ v1.00 != v9.99 ]`.
CASE_N=$((CASE_N + 1))
trace_root="${SBX}/case-${CASE_N}"
mkdir -p "${trace_root}"
trace_hook=$(stage_hook "${trace_root}" clone v1.00)
write_cache "v9.99"
trace=$(HOME="${HOME_SBX}" PATH="${HOME_SBX}/bin:${PATH}" \
        bash -x "${trace_hook}" 2>&1)
if grep -qE 'v1\.00.*!=.*v9\.99' <<<"${trace}"; then
  report "reaches version comparison (bash -x trace shows v1.00 != v9.99)" 1
else
  report "reaches version comparison (bash -x trace)" 0 \
    "comparison of v1.00 != v9.99 not found in trace"
fi

# --- Summary ----------------------------------------------------------------
printf '\n======================================================================\n'
printf 'test_notify_version_skew.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0

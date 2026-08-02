#!/usr/bin/env bash
# setup-ci-layout.sh — materialize a deployed hook runtime layout in a sandbox
# so the hook test harness can run against the co-located, token-resolved
# allowlists the hooks resolve from ${HOOK_DIR}/.. at runtime.
#
# WHY THIS EXISTS
#   The hooks resolve their allowlist + .mode from ${HOOK_DIR}/.. — i.e.
#   ~/Claude/.claude/<name>.txt after install, where install.sh has written
#   token-resolved allowlists. In a source/CI checkout HOOK_DIR=core/hooks →
#   CLAUDE_DIR=core/ → core/<name>.txt is ABSENT (the source allowlists live
#   token-unresolved at core/config/allowlists/). With the allowlist absent the
#   hooks correctly block, so the tests' "allow" assertions fail. The fix is to
#   materialize the deployed posture — hooks + token-resolved allowlists +
#   .mode + the test files, all co-located under a sandbox .claude/hooks/ — and
#   run the harness from there. (Per the Stage 5 spec on issue #718, Option A.)
#
# WHAT IT DOES (idempotent for a given --sandbox)
#   1. Create <sandbox>/.claude/hooks/tests/.
#   2. Copy every core/hooks/*.sh (the hooks) into <sandbox>/.claude/hooks/.
#   3. Copy every core/hooks/tests/*.sh (the tests + runner) into
#      <sandbox>/.claude/hooks/tests/ — EXCEPT this script itself.
#   4. Materialize the token-resolved allowlists at <sandbox>/.claude/ for the
#      "hook"-tier composition-surface files, resolving:
#        [CLAUDE_WORKSPACE_ROOT] -> ${HOME}/Claude   (the boundary the
#                                                     fs-boundary "allow"
#                                                     assertions assume)
#        [OPERATOR_HOMEDIR_PATH] -> ${HOME}
#        [OPERATOR_GITHUB]       -> ${PMO_TEST_GITHUB_HANDLE:-pmo-test-handle}
#   5. Write <sandbox>/.claude/hooks/.mode = enforce (the tests set their own
#      per-case mode against the SANDBOX .mode; the live ~/Claude/.claude/
#      hooks/.mode is NEVER touched — R-8 sandbox invariant).
#
# SANDBOX INVARIANT (R-8)
#   Everything is materialized under the sandbox. This script writes nothing to
#   ~/Claude/.claude/. The fs-boundary test's .mode mutation targets the
#   sandbox copy. Resolving [CLAUDE_WORKSPACE_ROOT] to ${HOME}/Claude only sets
#   the allowlist's prefix-match ROOT (a read-only boundary reference, realpath
#   does not require it to exist); the tests never write under ${HOME}/Claude.
#
# USAGE
#   setup-ci-layout.sh [--repo-root <dir>] [--sandbox <dir>]
#     --repo-root  Source repo root (default: three levels above this script).
#     --sandbox    Sandbox root (default: a fresh mktemp -d).
#   Prints the materialized tests directory on stdout (the only stdout line),
#   so a caller can:   TESTS_DIR="$(bash setup-ci-layout.sh)"
#                      bash "${TESTS_DIR}/test-runner.sh"
#   All diagnostics go to stderr.
#
# Platform: macOS / Linux. bash 3.2-safe (no associative arrays).

set -euo pipefail

log() { printf '%s\n' "$*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
# Default repo root: core/hooks/tests -> core/hooks -> core -> repo root.
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd -P)"
SANDBOX=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --sandbox)   SANDBOX="$2"; shift 2 ;;
    *) log "setup-ci-layout.sh: unknown argument: $1"; exit 64 ;;
  esac
done

if [ -z "${SANDBOX}" ]; then
  SANDBOX="$(mktemp -d -t hook-ci-layout.XXXXXX)"
fi

HOOKS_SRC="${REPO_ROOT}/core/hooks"
TESTS_SRC="${REPO_ROOT}/core/hooks/tests"
ALLOWLIST_SRC="${REPO_ROOT}/core/config/allowlists"
MANIFEST="${REPO_ROOT}/core/deploy/composition-surface-manifest.sh"

for required in "${HOOKS_SRC}" "${TESTS_SRC}" "${ALLOWLIST_SRC}" "${MANIFEST}"; do
  if [ ! -e "${required}" ]; then
    log "setup-ci-layout.sh: required source missing: ${required}"
    exit 1
  fi
done

CLAUDE_DIR="${SANDBOX}/.claude"
HOOKS_DST="${CLAUDE_DIR}/hooks"
TESTS_DST="${HOOKS_DST}/tests"
mkdir -p "${TESTS_DST}"

# Token substitution values.
WS_ROOT="${HOME}/Claude"
HOMEDIR="${HOME}"
GH_HANDLE="${PMO_TEST_GITHUB_HANDLE:-pmo-test-handle}"

# 1) Copy hooks.
log "setup-ci-layout: copying hooks -> ${HOOKS_DST}"
for hook in "${HOOKS_SRC}"/*.sh; do
  [ -f "${hook}" ] || continue
  cp "${hook}" "${HOOKS_DST}/"
done
chmod +x "${HOOKS_DST}"/*.sh

# 1b) Co-locate the shared path-leak primitive next to the hooks, mirroring the
#     deployed posture (setup-workspace.sh co-deploys it to .claude/hooks/).
#     block-gh-path-leak.sh resolves it from ${HOOK_DIR}/path-leak-patterns.sh; the
#     source lives at core/deploy/tools/, outside the hooks dir the loop above copies.
PRIMITIVE_SRC="${REPO_ROOT}/core/deploy/tools/path-leak-patterns.sh"
if [ -f "${PRIMITIVE_SRC}" ]; then
  cp "${PRIMITIVE_SRC}" "${HOOKS_DST}/"
  log "setup-ci-layout: co-located path-leak primitive -> ${HOOKS_DST}/path-leak-patterns.sh"
else
  log "setup-ci-layout: WARNING path-leak primitive missing at ${PRIMITIVE_SRC}"
fi

# 1b') Co-locate the shared operator-instance / needle resolver next to the hooks,
#      mirroring the deployed posture (setup-workspace.sh co-deploys it to .claude/hooks/).
#      block-scope-segregation.sh (#384) resolves it from ${HOOK_DIR}/lib-instance-path.sh
#      for its CD-4 localized-needle scan; the source lives at core/deploy/, outside the
#      hooks dir the loop above copies.
NEEDLELIB_SRC="${REPO_ROOT}/core/deploy/lib-instance-path.sh"
if [ -f "${NEEDLELIB_SRC}" ]; then
  cp "${NEEDLELIB_SRC}" "${HOOKS_DST}/"
  log "setup-ci-layout: co-located needle resolver -> ${HOOKS_DST}/lib-instance-path.sh"
else
  log "setup-ci-layout: WARNING needle resolver missing at ${NEEDLELIB_SRC}"
fi

# 1c) Co-locate the shared jq/dependency resolver at .claude/hooks/lib/, mirroring the
#     deployed posture (setup-workspace.sh co-deploys it there). Every security hook
#     sources it from ${HOOK_DIR}/lib/dep-resolve.sh and fails CLOSED without it
#     (GHSA-9cjm-v22x-4x33); the source lives at core/hooks/lib/, a subdir the *.sh
#     loop above does not copy.
DEPRESOLVE_SRC="${HOOKS_SRC}/lib/dep-resolve.sh"
if [ -f "${DEPRESOLVE_SRC}" ]; then
  mkdir -p "${HOOKS_DST}/lib"
  cp "${DEPRESOLVE_SRC}" "${HOOKS_DST}/lib/"
  log "setup-ci-layout: co-located dep-resolve resolver -> ${HOOKS_DST}/lib/dep-resolve.sh"
else
  log "setup-ci-layout: WARNING dep-resolve resolver missing at ${DEPRESOLVE_SRC}"
fi

# 1d) Co-locate the positional-issue-ref classifier at .claude/hooks/lib/, mirroring the
#     deployed posture (setup-workspace.sh co-deploys it there). block-fragile-refs.sh
#     sources it from ${HOOK_DIR}/lib/positional-issueref.awk and — post
#     GHSA-g9g6-28c9-vrx5 — fails CLOSED in enforce without it; the source lives at
#     core/hooks/lib/, a subdir the *.sh loop above does not copy. Without this the CI
#     deployed-layout would diverge from a correct install and read the positional
#     detector as absent.
POSAWK_SRC="${HOOKS_SRC}/lib/positional-issueref.awk"
if [ -f "${POSAWK_SRC}" ]; then
  mkdir -p "${HOOKS_DST}/lib"
  cp "${POSAWK_SRC}" "${HOOKS_DST}/lib/"
  log "setup-ci-layout: co-located positional classifier -> ${HOOKS_DST}/lib/positional-issueref.awk"
else
  log "setup-ci-layout: WARNING positional classifier missing at ${POSAWK_SRC}"
fi

# 1e') Co-locate the reference-durability detector constants at .claude/hooks/lib/, mirroring
#      the deployed posture (setup-workspace.sh co-deploys it there). block-fragile-refs.sh
#      sources it from ${HOOK_DIR}/lib/fragile-ref-patterns.sh for EVERY pattern it evaluates;
#      the source lives at core/hooks/lib/, a subdir the *.sh loop above does not copy. WITHOUT
#      this the sandbox hook has no detectors and fails CLOSED in enforce — which blocks even
#      the clean-prose ALLOW cases, so block-fragile-refs.test.sh would fail on nearly every
#      assertion. Same CI-fidelity class as the dep-resolve / positional co-locations above.
PATTERNSLIB_SRC="${HOOKS_SRC}/lib/fragile-ref-patterns.sh"
if [ -f "${PATTERNSLIB_SRC}" ]; then
  mkdir -p "${HOOKS_DST}/lib"
  cp "${PATTERNSLIB_SRC}" "${HOOKS_DST}/lib/"
  log "setup-ci-layout: co-located detector constants -> ${HOOKS_DST}/lib/fragile-ref-patterns.sh"
else
  log "setup-ci-layout: WARNING detector constants missing at ${PATTERNSLIB_SRC}"
fi

# 1e) Co-locate the master-activation gate lib at .claude/hooks/lib/, mirroring the deployed
#     posture (setup-workspace.sh co-deploys it there, #310). Every block-*.sh sources it from
#     ${HOOK_DIR}/lib/master-enable.sh to resolve the durable opt-in master-enable state. WITHOUT
#     this the CI sandbox would diverge from a correct install (the hooks would fall back to
#     fail-toward-current-behavior and CI would never exercise the real gate) — the same
#     CI-fidelity class the dep-resolve / positional co-locations above exist to prevent. The
#     test-runner establishes master ON so the rule-tests run against active hooks.
MASTERLIB_SRC="${HOOKS_SRC}/lib/master-enable.sh"
if [ -f "${MASTERLIB_SRC}" ]; then
  mkdir -p "${HOOKS_DST}/lib"
  cp "${MASTERLIB_SRC}" "${HOOKS_DST}/lib/"
  log "setup-ci-layout: co-located master-activation gate -> ${HOOKS_DST}/lib/master-enable.sh"
else
  log "setup-ci-layout: WARNING master-activation gate missing at ${MASTERLIB_SRC}"
fi

# 2) Copy tests + runner (skip this setup script — it is not a test file).
log "setup-ci-layout: copying tests -> ${TESTS_DST}"
for tf in "${TESTS_SRC}"/*.sh; do
  [ -f "${tf}" ] || continue
  case "$(basename "${tf}")" in
    setup-ci-layout.sh) continue ;;
  esac
  cp "${tf}" "${TESTS_DST}/"
done
chmod +x "${TESTS_DST}"/*.sh

# 3) Materialize token-resolved allowlists for the "hook"-tier composition
#    surface, reading the manifest as the source of truth for which files are
#    hook-tier and which carry the "tokens" flag.
#    Manifest entry format: "<src-relpath>|<tier>|<tokens-flag>".
log "setup-ci-layout: materializing hook-tier allowlists -> ${CLAUDE_DIR}"
materialized=0
# shellcheck disable=SC2013  # field-split read of the manifest entry rows
while IFS= read -r row; do
  src="$(printf '%s' "${row}" | awk -F'|' '{print $1}')"
  tier="$(printf '%s' "${row}" | awk -F'|' '{print $2}')"
  flag="$(printf '%s' "${row}" | awk -F'|' '{print $3}')"
  [ "${tier}" = "hook" ] || continue
  src_path="${REPO_ROOT}/${src}"
  base="$(basename "${src}")"
  dst="${CLAUDE_DIR}/${base}"
  if [ ! -f "${src_path}" ]; then
    log "setup-ci-layout: WARNING hook-tier source missing, skipping: ${src_path}"
    continue
  fi
  if [ "${flag}" = "tokens" ]; then
    sed -e "s#\[CLAUDE_WORKSPACE_ROOT\]#${WS_ROOT}#g" \
        -e "s#\[OPERATOR_HOMEDIR_PATH\]#${HOMEDIR}#g" \
        -e "s#\[OPERATOR_GITHUB\]#${GH_HANDLE}#g" \
        "${src_path}" > "${dst}"
  else
    # raw-flag files (webfetch/ssh/mcp-write/shell-injection/...) may still
    # carry [OPERATOR_GITHUB] occurrences the deployed allowlist resolves;
    # resolve that token too so allow-cases match. Path tokens are not present
    # in raw files by contract, but resolving them is harmless (no-op).
    sed -e "s#\[OPERATOR_GITHUB\]#${GH_HANDLE}#g" \
        "${src_path}" > "${dst}"
  fi
  materialized=$((materialized + 1))
done < <(grep -E '^[[:space:]]*"[^"]+\|[^"]+\|[^"]+"' "${MANIFEST}" \
           | sed -E 's/^[[:space:]]*"//; s/".*$//')

if [ "${materialized}" -lt 1 ]; then
  log "setup-ci-layout: ERROR no hook-tier allowlists materialized"
  exit 1
fi
log "setup-ci-layout: materialized ${materialized} hook-tier allowlist(s)"

# 4) Sandbox .mode (enforce). The tests mutate THIS file per-case and restore
#    it; the live ~/Claude/.claude/hooks/.mode is never touched (R-8).
printf 'enforce' > "${HOOKS_DST}/.mode"

log "setup-ci-layout: layout ready"
log "  sandbox       : ${SANDBOX}"
log "  hooks         : ${HOOKS_DST}"
log "  tests         : ${TESTS_DST}"
log "  workspace root: ${WS_ROOT}"
log "  github handle : ${GH_HANDLE}"

# The ONLY stdout line: the tests directory (for the caller to run the runner).
printf '%s\n' "${TESTS_DST}"

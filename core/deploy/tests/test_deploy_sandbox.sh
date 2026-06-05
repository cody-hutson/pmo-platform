#!/usr/bin/env bash
# test_deploy_sandbox.sh — safety proof for the deploy-target-root override
#
# Asserts that deploy.sh honors PMO_PLATFORM_DEPLOY_ROOT so a sandboxed install
# redirects skill deployment under the override instead of writing to the live
# ~/.claude/skills, AND that the operator's real home is never touched.
#
# Hermetic-by-construction: EVERY deploy invocation runs under a redirected HOME
# pointed at a throwaway sandbox. This guarantees the test can never write to the
# operator's real ~/.claude/skills on ANY machine — including one with a pinned
# [paths].cowork_install_path in operator.toml, since the redirected HOME also
# redirects the config-root fallback ($HOME/.config/pmo-platform) that
# detect_install_path reads. The live-~ manifest assertion is then a
# belt-and-suspenders proof that no invocation escaped its sandbox.
#
# The four assertions:
#   A. Redirection — PMO_PLATFORM_DEPLOY_ROOT=<tmp> wins as the deploy root, so
#      ./deploy.sh --deploy <skill> creates <tmp>/.claude/skills/<skill>/SKILL.md
#      even when HOME points elsewhere (the override takes precedence over $HOME).
#   B. Live-~ untouched — a manifest of the REAL $HOME/.claude/skills (sorted file
#      list + per-file hash) is byte-identical before and after every invocation.
#      The test only READS the live tree; it never writes there.
#   C. No-override default derives from $HOME — with PMO_PLATFORM_DEPLOY_ROOT
#      UNSET, the :-$HOME default fires and skills land under $HOME/.claude/skills
#      (proven against a redirected HOME — the exact code path a normal install
#      takes, just sandboxed).
#   D. Exported-but-EMPTY override == default ($HOME) — bash ${var:-default}
#      (colon-dash) treats an empty value the same as unset, so an
#      exported-but-empty PMO_PLATFORM_DEPLOY_ROOT collapses to $HOME (the safe,
#      intended no-sandbox behavior) rather than to an absolute "/.claude/skills".
#      Proven against a redirected HOME; the real ~ stays untouched.
#
# Run from anywhere (resolves repo root from its own location):
#   bash core/deploy/tests/test_deploy_sandbox.sh
#
# deploy.sh resolves skill source dirs relative to CWD ($module/skills/<name>),
# so this test cd's to the repo root before each invocation.
#
# Note: CI wiring for this test is owned by the deploy-test-harness work,
# not by this change — this file only adds the test.
#
# Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DEPLOY="${REPO_ROOT}/core/deploy/deploy.sh"

# Skill used as the deploy probe — a small CORE skill with a SKILL.md.
PROBE_SKILL="pmo-qa-auditor"

PASS=0
FAIL=0
SBX=""          # PMO_PLATFORM_DEPLOY_ROOT sandbox (Test A)
HOME_A=""       # redirected HOME for Test A (override must win over this)
HOME_C=""       # redirected HOME for Test C (default == $HOME)
HOME_D=""       # redirected HOME for Test D (empty override == $HOME)

cleanup() {
  local d
  for d in "${SBX}" "${HOME_A}" "${HOME_C}" "${HOME_D}"; do
    [ -n "${d}" ] && [ -d "${d}" ] && rm -rf "${d}"
  done
  return 0
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

# Portable per-file hash (macOS `md5 -q`, Linux `md5sum`).
hash_file() {
  if command -v md5 >/dev/null 2>&1; then
    md5 -q "$1" 2>/dev/null
  else
    md5sum "$1" 2>/dev/null | awk '{print $1}'
  fi
}

# Manifest of a directory: sorted "relpath  hash" lines. Empty (and exit 0) if the
# directory does not exist — so a machine with no live ~/.claude/skills still gets
# a stable before/after comparison.
manifest_dir() {
  local root="$1"
  [ -d "${root}" ] || return 0
  local f
  while IFS= read -r f; do
    printf '%s  %s\n' "${f#"${root}"/}" "$(hash_file "${f}")"
  done < <(find "${root}" -type f 2>/dev/null | LC_ALL=C sort)
}

# --- Preflight ---
if [ ! -f "${DEPLOY}" ]; then
  printf 'FAIL: deploy.sh not found at %s\n' "${DEPLOY}"
  exit 1
fi
if [ ! -f "${REPO_ROOT}/core/skills/${PROBE_SKILL}/SKILL.md" ]; then
  printf 'FAIL: probe skill source missing: core/skills/%s/SKILL.md\n' "${PROBE_SKILL}"
  exit 1
fi

SBX=$(mktemp -d -t deploy-sbx-root.XXXXXX)
HOME_A=$(mktemp -d -t deploy-sbx-homeA.XXXXXX)
HOME_C=$(mktemp -d -t deploy-sbx-homeC.XXXXXX)
HOME_D=$(mktemp -d -t deploy-sbx-homeD.XXXXXX)

LIVE_SKILLS="${HOME}/.claude/skills"

# Capture the live-~ manifest BEFORE any invocation (the safety baseline).
LIVE_BEFORE=$(manifest_dir "${LIVE_SKILLS}")

# --- Test A: PMO_PLATFORM_DEPLOY_ROOT wins as the deploy root (over $HOME) ---
printf '\nTest A: PMO_PLATFORM_DEPLOY_ROOT redirects deploy (precedence over $HOME)\n'
(
  cd "${REPO_ROOT}" || exit 1
  HOME="${HOME_A}" PMO_PLATFORM_DEPLOY_ROOT="${SBX}" bash "${DEPLOY}" --deploy "${PROBE_SKILL}"
) >/dev/null 2>&1 || true   # deploy may emit Cowork/check noise; assert on artifacts

if [ -f "${SBX}/.claude/skills/${PROBE_SKILL}/SKILL.md" ]; then
  report "skill deployed under PMO_PLATFORM_DEPLOY_ROOT sandbox" 1
else
  report "skill deployed under PMO_PLATFORM_DEPLOY_ROOT sandbox" 0 \
    "expected: ${SBX}/.claude/skills/${PROBE_SKILL}/SKILL.md"
fi
# The override must win: nothing should land under the redirected HOME_A.
if [ ! -e "${HOME_A}/.claude/skills/${PROBE_SKILL}" ]; then
  report "override takes precedence (HOME_A/.claude/skills NOT written)" 1
else
  report "override takes precedence (HOME_A/.claude/skills NOT written)" 0 \
    "unexpected write under ${HOME_A}/.claude/skills/${PROBE_SKILL}"
fi

# --- Test C: no-override default lands under $HOME (redirected) ---
printf '\nTest C: no-override default derives from $HOME (byte-identical contract)\n'
(
  cd "${REPO_ROOT}" || exit 1
  HOME="${HOME_C}" bash "${DEPLOY}" --deploy "${PROBE_SKILL}"
) >/dev/null 2>&1 || true

if [ -f "${HOME_C}/.claude/skills/${PROBE_SKILL}/SKILL.md" ]; then
  report "no-override deploy lands under \$HOME/.claude/skills" 1
else
  report "no-override deploy lands under \$HOME/.claude/skills" 0 \
    "expected: ${HOME_C}/.claude/skills/${PROBE_SKILL}/SKILL.md"
fi

# Override path and default path produce the same artifact (behavior-preserving:
# only the root differs).
sbx_skill="${SBX}/.claude/skills/${PROBE_SKILL}/SKILL.md"
home_skill="${HOME_C}/.claude/skills/${PROBE_SKILL}/SKILL.md"
if [ -f "${sbx_skill}" ] && [ -f "${home_skill}" ] && diff -q "${sbx_skill}" "${home_skill}" >/dev/null 2>&1; then
  report "override and default deploy produce identical SKILL.md (root-only diff)" 1
else
  report "override and default deploy produce identical SKILL.md (root-only diff)" 0
fi

# --- Test D: exported-but-EMPTY override collapses to $HOME (colon-dash) ---
printf '\nTest D: exported-but-empty PMO_PLATFORM_DEPLOY_ROOT == default ($HOME)\n'
(
  cd "${REPO_ROOT}" || exit 1
  HOME="${HOME_D}" PMO_PLATFORM_DEPLOY_ROOT="" bash "${DEPLOY}" --deploy "${PROBE_SKILL}"
) >/dev/null 2>&1 || true

# Empty override must behave exactly like no-override: land under $HOME (HOME_D),
# NOT under an absolute "/.claude/skills".
if [ -f "${HOME_D}/.claude/skills/${PROBE_SKILL}/SKILL.md" ]; then
  report "empty override collapses to \$HOME (lands under HOME_D/.claude/skills)" 1
else
  report "empty override collapses to \$HOME (lands under HOME_D/.claude/skills)" 0 \
    "expected: ${HOME_D}/.claude/skills/${PROBE_SKILL}/SKILL.md"
fi

# --- Test B: live ~/.claude/skills UNCHANGED across all invocations ---
printf '\nTest B: live ~/.claude/skills UNTOUCHED across all sandboxed invocations\n'
LIVE_AFTER=$(manifest_dir "${LIVE_SKILLS}")
if [ "${LIVE_BEFORE}" = "${LIVE_AFTER}" ]; then
  report "live ~/.claude/skills byte-identical before/after (safety proof)" 1
else
  report "live ~/.claude/skills byte-identical before/after (safety proof)" 0 \
    "manifest drift detected under ${LIVE_SKILLS}"
fi

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_deploy_sandbox.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0

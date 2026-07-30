#!/usr/bin/env bash
# test_package_freshness_exit_codes.sh — verdict -> exit-code contract for the
# `deploy.sh --check-package-freshness` probe (Check 7's CI-facing surface).
#
# WHY THIS TEST EXISTS
# The probe used to map a STALE verdict to exit 0 whenever the enforcement
# sentinel held a non-enforce token. Its prose said STALE and its exit status
# said OK, so any caller that read the exit code to answer "is the package
# fresh?" got the opposite of the truth. A verification tool whose success and
# failure are indistinguishable in the signal callers actually read is worse than
# one that only prints the verdict. This test asserts the exit status DIRECTLY,
# in a subprocess, because the exit status is where the defect lived.
#
# THE CONTRACT UNDER TEST (authoring home: the cmd_check_package_freshness
# header table in core/deploy/deploy.sh — this test is the executable mirror):
#
#   verdict   sentinel token   exit
#   -------   --------------   ----
#   FRESH     any              0
#   STALE     != enforce       2     advisory: not fresh, not blocking
#   STALE     enforce          1     blocking
#   <other>   any              1     fail-closed, sentinel-agnostic
#
# THE ASSERTIONS
#   PF-1  fresh sandbox, committed sentinel default    -> exit 0   (clean control)
#   PF-2  one stale package, committed sentinel default -> exit 2  (the regression)
#   PF-3  same stale tree, sentinel token `enforce`    -> exit 1   (blocking arm)
#   PF-4  injected staleness removed                   -> exit 0   (anti-vacuity)
#   PF-5  staleness cleared by the DOCUMENTED REMEDY (a build-skill-packages.sh
#         rebuild) -> exit 0. Conditional: reported as a NAMED SKIP with its
#         reason, and counted in the summary, on a runner whose python3 cannot
#         run the packager. Never silently absent, never counted as a pass.
#
# PF-1 and PF-4 are not optional garnish. Without them PF-2 and PF-3 would pass
# against a probe that returned non-zero unconditionally, which is the vacuity
# this pair exists to defeat. PF-4 removes the staleness by restoring the file
# rather than by rebuilding, so the anti-vacuity control never depends on the
# packager; PF-5 is the packager-dependent remedy proof, kept separate for
# exactly that reason.
#
# WHY IT NORMALIZES THE SANDBOX FIRST
# The contract under test is the verdict->exit MAPPING, not the freshness of the
# committed tree. Tree freshness is already asserted by the always-enforce
# lifecycle Check 7 and by the skill-package-freshness CI gate; asserting it a
# third time here would double-gate it and would turn this suite red during the
# legitimate mid-release window in which a release stales a package before its
# terminal rebuild beat. So the sandbox is normalized to FRESH first (rebuilding
# every package only when the as-archived tree is not already fresh), and the
# staleness this test reasons about is the staleness this test itself injects.
# A sandbox that can be neither confirmed fresh nor rebuilt is a loud
# environmental failure, never a skip.
#
# HERMETICITY
# The fixture is a throwaway `git archive HEAD` export of the tracked tree; every
# probe invocation runs with HOME redirected into a sandbox, so neither the
# operator's ~/.claude nor the real working tree is read for install resolution
# or written at all. The real working tree is NEVER staled. The interpreter's
# user-site base is carried across the redirect via PYTHONUSERBASE so the
# redirect does not, by itself, hide packages an unsandboxed run would import —
# a sandbox that silently disables the content verdict would make PF-2 assert
# something weaker than it claims.
#
# Run from anywhere (resolves the repo root from its own location):
#   bash core/deploy/tests/test_package_freshness_exit_codes.sh
#
# Returns 0 when every executed assertion holds, non-zero otherwise.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# The skill whose package this test stales and rebuilds. It must be rostered,
# packaged, and carry a references/ tree (the surface the original defect was
# reported against). pmo-qa-auditor is the same probe skill test_deploy_sandbox.sh
# uses, so the two tests share one assumption rather than two.
PROBE_SKILL="pmo-qa-auditor"
PROBE_SKILL_DIR="core/skills/${PROBE_SKILL}"

PASS=0
FAIL=0
SKIP=0
SBX=""           # git-archive export of the tracked tree
SBX_HOME=""      # redirected HOME for every probe invocation
ENFORCE_FILE=""  # synthetic sentinel holding the `enforce` token

cleanup() {
  local d
  for d in "${SBX}" "${SBX_HOME}"; do
    [ -n "${d}" ] && [ -d "${d}" ] && rm -rf "${d}"
  done
  [ -n "${ENFORCE_FILE}" ] && [ -f "${ENFORCE_FILE}" ] && rm -f "${ENFORCE_FILE}"
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

report_skip() {
  printf '  SKIP: %s\n' "$1"
  printf '         reason: %s\n' "$2"
  SKIP=$((SKIP + 1))
}

die_loud() {
  printf '\nENVIRONMENTAL FAILURE: %s\n' "$1" >&2
  printf 'This test fails loudly rather than passing: an unrunnable contract test\n' >&2
  printf 'that reports success is the same defect class it exists to catch.\n' >&2
  exit 1
}

# Carry the interpreter's user-site base across the HOME redirect. Without it the
# redirect alone can hide user-installed modules the packager imports, silently
# demoting the probe's content verdict to its mtime fallback.
PY_USER_BASE="$(python3 -c 'import site; print(site.getuserbase())' 2>/dev/null || true)"

# Run the probe inside the sandbox with a redirected HOME. Echoes the exit code.
# $1 (optional) — absolute path to a sentinel file handed to the probe via
#                 SKILL_PACKAGE_FRESHNESS_ENFORCE_FILE. Omitted => the sandbox's
#                 own committed .github/skill-package-freshness.enforce is used.
probe_rc() {
  local sentinel="${1:-}" rc=0
  (
    cd "${SBX}" || exit 127
    export HOME="${SBX_HOME}"
    [ -n "${PY_USER_BASE}" ] && export PYTHONUSERBASE="${PY_USER_BASE}"
    [ -n "${sentinel}" ] && export SKILL_PACKAGE_FRESHNESS_ENFORCE_FILE="${sentinel}"
    bash core/deploy/deploy.sh --check-package-freshness
  ) >/dev/null 2>&1
  rc=$?
  printf '%s' "${rc}"
}

# Rebuild package(s) inside the sandbox. No args => every rostered skill.
# Echoes the builder's exit code; its output is captured to $BUILD_LOG.
BUILD_LOG=""
sandbox_build() {
  local rc=0
  BUILD_LOG="$(
    cd "${SBX}" || exit 127
    export HOME="${SBX_HOME}"
    [ -n "${PY_USER_BASE}" ] && export PYTHONUSERBASE="${PY_USER_BASE}"
    bash core/deploy/tools/build-skill-packages.sh "$@" 2>&1
  )"
  rc=$?
  printf '%s' "${rc}"
}

# --- Preflight: fail loud, never skip ---
printf 'test_package_freshness_exit_codes.sh — verdict -> exit-code contract\n'
printf 'repo root: %s\n' "${REPO_ROOT}"

[ -f "${REPO_ROOT}/core/deploy/deploy.sh" ] \
  || die_loud "deploy.sh not found at ${REPO_ROOT}/core/deploy/deploy.sh"
[ -f "${REPO_ROOT}/core/deploy/tools/build-skill-packages.sh" ] \
  || die_loud "build-skill-packages.sh not found — the remedy assertion cannot run"
[ -d "${REPO_ROOT}/${PROBE_SKILL_DIR}/references" ] \
  || die_loud "probe skill references/ missing: ${PROBE_SKILL_DIR}/references"
[ -f "${REPO_ROOT}/packages/${PROBE_SKILL}.skill" ] \
  || die_loud "probe skill package missing: packages/${PROBE_SKILL}.skill"
command -v python3 >/dev/null 2>&1 \
  || die_loud "python3 absent — the staged-rebuild content verdict cannot run"
command -v unzip >/dev/null 2>&1 \
  || die_loud "unzip absent — the package content hash cannot be computed"
command -v git >/dev/null 2>&1 \
  || die_loud "git absent — the sandbox fixture cannot be exported"

# --- Fixture: throwaway export of the tracked tree ---
SBX=$(mktemp -d -t pkgfresh-sbx.XXXXXX) || die_loud "mktemp failed (sandbox)"
SBX_HOME=$(mktemp -d -t pkgfresh-home.XXXXXX) || die_loud "mktemp failed (home)"

if ! (cd "${REPO_ROOT}" && git archive HEAD) | tar -x -C "${SBX}" 2>/dev/null; then
  die_loud "git archive HEAD | tar -x failed — could not build the sandbox fixture"
fi
[ -f "${SBX}/core/deploy/deploy.sh" ] \
  || die_loud "sandbox fixture incomplete (no core/deploy/deploy.sh)"

# Deterministic stale target: the alphabetically-first markdown file under the
# probe skill's references/. Named by rule rather than by literal filename so a
# rename in the corpus does not silently un-test the assertion.
STALE_REL=$(cd "${SBX}/${PROBE_SKILL_DIR}/references" \
  && ls -1 ./*.md 2>/dev/null | LC_ALL=C sort | head -1)
[ -n "${STALE_REL}" ] \
  || die_loud "no markdown file under ${PROBE_SKILL_DIR}/references to stale"
STALE_TARGET="${SBX}/${PROBE_SKILL_DIR}/references/${STALE_REL#./}"
PRISTINE_COPY="${SBX_HOME}/pristine-stale-target.bak"
cp "${STALE_TARGET}" "${PRISTINE_COPY}" || die_loud "could not snapshot the stale target"

# --- Normalize the sandbox to FRESH (see the header rationale) ---
printf '\nNormalizing the sandbox fixture to FRESH\n'
RC_ARCHIVED=$(probe_rc)
if [ "${RC_ARCHIVED}" = "0" ]; then
  printf '  as-archived tree is already package-fresh (rc=0) — no rebuild needed\n'
else
  printf '  as-archived tree is not fresh (rc=%s) — rebuilding every package in the sandbox\n' "${RC_ARCHIVED}"
  if [ "$(sandbox_build)" != "0" ]; then
    printf '%s\n' "${BUILD_LOG}" | tail -20 >&2
    die_loud "sandbox package rebuild failed — cannot establish the FRESH baseline"
  fi
  RC_ARCHIVED=$(probe_rc)
  [ "${RC_ARCHIVED}" = "0" ] \
    || die_loud "sandbox still not fresh after a full rebuild (rc=${RC_ARCHIVED}) — fixture unusable"
  cp "${STALE_TARGET}" "${PRISTINE_COPY}" || die_loud "could not re-snapshot the stale target"
fi

# --- PF-1: fresh sandbox, committed sentinel default -> exit 0 ---
printf '\nPF-1: FRESH tree, committed sentinel default -> expect exit 0\n'
RC1=$(probe_rc)
if [ "${RC1}" = "0" ]; then
  report "PF-1 FRESH -> exit 0 (clean control)" 1
else
  report "PF-1 FRESH -> exit 0 (clean control)" 0 "expected 0, observed ${RC1}"
fi

# --- Stale exactly one package: append a byte to a references/ file, no rebuild ---
printf '\nStaling %s via %s (no rebuild)\n' "${PROBE_SKILL}" "${STALE_REL#./}"
printf '\n<!-- package-freshness exit-code regression fixture -->\n' >> "${STALE_TARGET}" \
  || die_loud "could not append to the stale target"

# --- PF-2: STALE + non-enforce sentinel -> exit 2 (THE regression assertion) ---
printf '\nPF-2: STALE tree, committed sentinel default (warn) -> expect exit 2\n'
RC2=$(probe_rc)
if [ "${RC2}" = "2" ]; then
  report "PF-2 STALE + warn -> exit 2 (advisory, non-zero, distinguishable)" 1
elif [ "${RC2}" = "0" ]; then
  report "PF-2 STALE + warn -> exit 2 (advisory, non-zero, distinguishable)" 0 \
    "observed 0 — THE REGRESSION: a stale package reports success in the exit status"
else
  report "PF-2 STALE + warn -> exit 2 (advisory, non-zero, distinguishable)" 0 \
    "expected 2, observed ${RC2}"
fi

# --- PF-3: same stale tree + `enforce` sentinel -> exit 1 (blocking) ---
printf '\nPF-3: same STALE tree, sentinel token enforce -> expect exit 1\n'
ENFORCE_FILE=$(mktemp -t pkgfresh-enforce.XXXXXX) || die_loud "mktemp failed (sentinel)"
printf '# synthetic sentinel for PF-3\nenforce\n' > "${ENFORCE_FILE}"
RC3=$(probe_rc "${ENFORCE_FILE}")
if [ "${RC3}" = "1" ]; then
  report "PF-3 STALE + enforce -> exit 1 (blocking)" 1
else
  report "PF-3 STALE + enforce -> exit 1 (blocking)" 0 "expected 1, observed ${RC3}"
fi

# --- PF-4: remove the injected staleness -> exit 0 (anti-vacuity, packager-free) ---
printf '\nPF-4: injected staleness removed (file restored) -> expect exit 0\n'
cp "${PRISTINE_COPY}" "${STALE_TARGET}" || die_loud "could not restore the stale target"
RC4=$(probe_rc)
if [ "${RC4}" = "0" ]; then
  report "PF-4 staleness removed -> exit 0 (probe is not unconditionally non-zero)" 1
else
  report "PF-4 staleness removed -> exit 0 (probe is not unconditionally non-zero)" 0 \
    "expected 0, observed ${RC4}"
fi

# --- PF-5: the DOCUMENTED REMEDY clears the gate (packager-dependent) ---
printf '\nPF-5: staleness cleared by a build-skill-packages.sh rebuild -> expect exit 0\n'
printf '\n<!-- package-freshness exit-code regression fixture (remedy arm) -->\n' >> "${STALE_TARGET}" \
  || die_loud "could not re-append to the stale target"
if [ "$(sandbox_build "${PROBE_SKILL}")" != "0" ]; then
  report_skip "PF-5 rebuild -> exit 0 (documented remedy clears the gate)" \
    "build-skill-packages.sh could not run on this host (last line: $(printf '%s' "${BUILD_LOG}" | tail -1)). \
The packager is a host capability, not a property of the contract under test; PF-1..PF-4 above still ran."
else
  RC5=$(probe_rc)
  if [ "${RC5}" = "0" ]; then
    report "PF-5 rebuild -> exit 0 (documented remedy clears the gate)" 1
  else
    report "PF-5 rebuild -> exit 0 (documented remedy clears the gate)" 0 \
      "expected 0, observed ${RC5}"
  fi
fi

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_package_freshness_exit_codes.sh: %d passed, %d failed, %d skipped (bash %s)\n' \
  "${PASS}" "${FAIL}" "${SKIP}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0

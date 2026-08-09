#!/usr/bin/env bash
# test_detect_install_path_spaces.sh — regression: a [paths].cowork_install_path
# with INTERNAL spaces must resolve correctly.
#
# Background:
#   detect_install_path (rung 1) and Check 8 read [paths].cowork_install_path from
#   operator.toml. The original parse pipeline ended in `tr -d '[:space:]'`, which
#   strips ALL whitespace — including legitimate spaces INSIDE the path. The default
#   macOS Cowork base contains one:
#       ~/Library/Application Support/Claude/local-agent-mode-sessions
#                       ^^^^^^^^^^^^^^^^^^^ space
#   so a pinned default path was mangled to ".../ApplicationSupport/..."; `find`
#   under that nonexistent base matched nothing; INSTALL_PATH was left empty;
#   COWORK_AVAILABLE stayed false; and Cowork-target skill/package deploys silently
#   degraded to "user-local only" even though a valid session existed.
#
#   The fix replaces `tr -d '[:space:]'` with a leading/trailing trim
#   (`sed 's/^[[:space:]]+//; s/[[:space:]]+$//'`) at both reader sites, preserving
#   internal spaces. This test locks that in. The pre-existing fixtures only ever
#   pinned a space-FREE path (test_install_end_to_end.sh: "/tmp/test-cowork"), which
#   is exactly why the regression went uncaught — so this is the missing coverage.
#
# Method (hermetic-by-construction; mirrors test_deploy_sandbox.sh):
#   1. Build a sandbox whose pinned Cowork base CONTAINS A SPACE, in the faithful
#      macOS shape ".../Library/Application Support/Claude/local-agent-mode-sessions".
#   2. Pin it in a sandbox operator.toml; point the reader at it via
#      PMO_PLATFORM_CONFIG_ROOT.
#   3. Seed a real session dir under that exact (space-containing) base, with a
#      Cowork fingerprint skill present, so detect_install_path has something to find.
#   4. Run `deploy.sh --deploy <probe>` from the repo root, with HOME and
#      PMO_PLATFORM_DEPLOY_ROOT redirected so the user-local mirror and the default
#      SEARCH_ROOT can never touch the operator's real ~. The pinned cowork_base
#      drives INSTALL_PATH independently of DEPLOY_ROOT (deploy.sh: rung-1 read →
#      search_base; COWORK_AVAILABLE set from the detect result), so the skill and
#      its package land UNDER the space-containing base.
#
# The four assertions:
#   A. Skill landed at the Cowork target under the space base
#      (<base>/skills-plugin/<u1>/<u2>/skills/<probe>/SKILL.md). This write is
#      COWORK_AVAILABLE-gated, so its presence proves detect_install_path resolved
#      the space-containing base (== COWORK_AVAILABLE became true).
#   B. Package landed under the same session (pkg_dir = dirname(INSTALL_PATH)/packages),
#      also COWORK_AVAILABLE-gated — proves "packages land," not just the SKILL.md.
#   C. No silent degrade — the deploy log carries neither the "user-local only
#      (no Cowork session)" nor the "No Cowork skills-plugin session found" warning
#      (belt-and-suspenders on the COWORK_AVAILABLE=true outcome).
#   D. Safety — the operator's real ~/.claude/skills is byte-identical before/after
#      (a manifest proof that no invocation escaped its sandbox).
#
# With the pre-fix `tr -d '[:space:]'` reader, A/B FAIL (artifacts land nowhere under
# the space base) and the C warnings appear — i.e., this test is RED on the bug and
# GREEN on the fix.
#
# Run from anywhere (resolves repo root from its own location):
#   bash core/deploy/tests/test_detect_install_path_spaces.sh
#
# bash 3.2-safe (`set -uo pipefail`, no bash-4 features). Returns non-zero on any
# failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# Default to the in-tree deploy.sh. Overridable via DEPLOY_SH so a RED/GREEN proof
# (or a bisect) can point the same hermetic setup at an arbitrary deploy.sh — e.g.
# the pre-fix script — without mutating the working tree.
DEPLOY="${DEPLOY_SH:-${REPO_ROOT}/core/deploy/deploy.sh}"

# Probe — a small CORE skill that has BOTH a SKILL.md source and a .skill package,
# so a single --deploy exercises the skill-copy AND the package-copy Cowork paths.
PROBE_SKILL="pmo-qa-auditor"

# Fixed fake session UUIDs (deterministic — no randomness; Date/random are not
# needed and would only make failures non-reproducible).
U1="11111111-1111-1111-1111-111111111111"
U2="22222222-2222-2222-2222-222222222222"

# A Cowork-provided skill name used as the live-session fingerprint (must match one
# of deploy.sh's FINGERPRINT_SKILLS).
FP_SKILL="docx"

PASS=0
FAIL=0
SBX=""

cleanup() {
  [ -n "${SBX}" ] && [ -d "${SBX}" ] && rm -rf "${SBX}"
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

# Manifest of a directory: sorted "relpath  hash" lines. Empty (exit 0) if the dir
# does not exist, so a machine with no live ~/.claude/skills still compares stably.
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
if [ ! -f "${REPO_ROOT}/packages/${PROBE_SKILL}.skill" ]; then
  printf 'FAIL: probe package missing: packages/%s.skill\n' "${PROBE_SKILL}"
  exit 1
fi

SBX=$(mktemp -d -t detect-spaces.XXXXXX)

# The crux: a Cowork base WITH an internal space, in the faithful macOS shape.
COWORK_BASE="${SBX}/Library/Application Support/Claude/local-agent-mode-sessions"
CFG_ROOT="${SBX}/config"
HOME_SBX="${SBX}/home"
DEPLOY_ROOT_SBX="${SBX}/deploy"

# Seeded session: <base>/skills-plugin/<u1>/<u2>/skills/ (the "skills" dir sits at
# find -maxdepth 3, matching detect_install_path's probe), plus a fingerprint skill.
SESSION_SKILLS="${COWORK_BASE}/skills-plugin/${U1}/${U2}/skills"
mkdir -p "${CFG_ROOT}" "${HOME_SBX}" "${DEPLOY_ROOT_SBX}" "${SESSION_SKILLS}/${FP_SKILL}"

# Pin the space-containing base in a sandbox operator.toml. detect_install_path only
# reads [paths].cowork_install_path; a minimal but well-formed file suffices.
cat > "${CFG_ROOT}/operator.toml" <<TOML
[meta]
schema_version = 1
managed_by = "pmo-platform"

[paths]
cowork_install_path = "${COWORK_BASE}"
TOML
chmod 600 "${CFG_ROOT}/operator.toml"

# Safety baseline — the operator's REAL ~/.claude/skills, captured before any run.
LIVE_SKILLS="${HOME}/.claude/skills"
LIVE_BEFORE=$(manifest_dir "${LIVE_SKILLS}")

# --- Invoke deploy against the space-containing, config-pinned base ---
printf '\nRegression: cowork_install_path with internal spaces\n'
printf '  pinned base: %s\n' "${COWORK_BASE}"
deploy_log=$(
  cd "${REPO_ROOT}" || exit 1
  HOME="${HOME_SBX}" \
    PMO_PLATFORM_CONFIG_ROOT="${CFG_ROOT}" \
    PMO_PLATFORM_DEPLOY_ROOT="${DEPLOY_ROOT_SBX}" \
    bash "${DEPLOY}" --deploy "${PROBE_SKILL}" 2>&1
) || true

# --- A. Skill landed at the Cowork target under the space base ---
skill_target="${SESSION_SKILLS}/${PROBE_SKILL}/SKILL.md"
if [ -f "${skill_target}" ]; then
  report "skill deployed to Cowork session under space-containing base" 1
else
  report "skill deployed to Cowork session under space-containing base" 0 \
    "expected: ${skill_target}"
fi

# --- B. Package landed under the same session (dirname(INSTALL_PATH)/packages) ---
pkg_target="${COWORK_BASE}/skills-plugin/${U1}/${U2}/packages/${PROBE_SKILL}.skill"
if [ -f "${pkg_target}" ]; then
  report "package deployed to Cowork session under space-containing base" 1
else
  report "package deployed to Cowork session under space-containing base" 0 \
    "expected: ${pkg_target}"
fi

# --- C. No silent degrade (COWORK_AVAILABLE became true) ---
if grep -q "user-local only (no Cowork session)" <<<"${deploy_log}"; then
  report "no silent degrade to user-local-only" 0 \
    "deploy reported 'user-local only' despite a valid pinned session"
elif grep -q "No Cowork skills-plugin session found" <<<"${deploy_log}"; then
  report "no silent degrade to user-local-only" 0 \
    "detect_install_path failed to find the session under the space-containing base"
else
  report "no silent degrade to user-local-only" 1
fi

# --- D. Safety: real ~/.claude/skills byte-identical before/after ---
LIVE_AFTER=$(manifest_dir "${LIVE_SKILLS}")
if [ "${LIVE_BEFORE}" = "${LIVE_AFTER}" ]; then
  report "live ~/.claude/skills untouched (sandbox safety proof)" 1
else
  report "live ~/.claude/skills untouched (sandbox safety proof)" 0 \
    "manifest drift detected under ${LIVE_SKILLS}"
fi

# On any failure, surface a tail of the deploy log for diagnosis.
if [ "${FAIL}" -ne 0 ]; then
  printf '\n--- deploy log (last 20 lines) ---\n%s\n' \
    "$(printf '%s' "${deploy_log}" | tail -20)"
fi

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_detect_install_path_spaces.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0

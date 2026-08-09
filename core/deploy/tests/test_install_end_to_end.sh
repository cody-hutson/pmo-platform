#!/usr/bin/env bash
# test_install_end_to_end.sh — real install + update verification (not --dry-run)
#
# Runs setup-workspace.sh against a /tmp sandbox with a pre-seeded operator.toml,
# verifies the workspace lands in a correct post-install state, then runs
# update.sh against the same sandbox. Catches issues that --dry-run testing
# (test_sandbox_roots.sh) cannot see — embedded Python heredoc bugs,
# token-substitution failures, hook install regressions, legacy-cache leaks.
#
# Method:
#   1. Pre-seed operator.toml under sandbox config-root with all identity +
#      paths fields populated. setup-workspace.sh reads these via
#      read_operator_toml and skips the prompts that would have asked for them.
#   2. Pipe `yes ""` (via process substitution to avoid SIGPIPE / pipefail
#      interaction) for the 3 uncached prompts (COWORK_INSTALL_PATH_BASE,
#      OPERATOR_PHONE, OPERATOR_PROJECT_NAME). Each has a default or is
#      optional, so empty input is accepted.
#   3. Assert post-install state: state file with verification_passed=true,
#      CLAUDE.md / settings.json substituted, hooks + composition-surface
#      files present, no legacy workspace-config.toml anywhere.
#   4. Run update.sh --dry-run against the sandbox; assert preflight passes and
#      the no-op dry-run exits EX_NOCHANGE (64).
#
# Run from repo root:
#   bash core/deploy/tests/test_install_end_to_end.sh
#
# Platform: Darwin-only. On Linux/WSL the script prints SKIP and exits 0
# (setup-workspace.sh's check_platform exits 78 elsewhere).
#
# Returns non-zero on any failure.

set -uo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'SKIP: test_install_end_to_end.sh — setup-workspace.sh is Darwin-only\n'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
UPDATE="${REPO_ROOT}/update.sh"
# Resolve the instance-tier dir via the single resolver instead of inlining the
# hardcoded leaf (#1830 AC1/AC5). PMO_INSTANCE_PATH is unset in this test, so
# pmo_instance_path_for returns <workspace-root>/<instance-leaf>.
# shellcheck source=../lib-instance-path.sh disable=SC1091
source "${SCRIPT_DIR}/../lib-instance-path.sh"

PASS=0
FAIL=0
SBX=""

cleanup() {
  if [ -n "${SBX}" ] && [ -d "${SBX}" ]; then
    rm -rf "${SBX}"
  fi
}
trap cleanup EXIT

SBX=$(mktemp -d -t install-e2e.XXXXXX)
mkdir -p "${SBX}/config" "${SBX}/ws" "${SBX}/home"

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

# --- Pre-seed operator.toml so setup-workspace.sh prompts skip ---
cat > "${SBX}/config/operator.toml" <<TOML
[meta]
schema_version = 1
managed_by = "pmo-platform"

[identity]
operator_name = "Test Operator"
operator_email = "test@example.com"
operator_git_email = "test@example.com"
operator_github = "test-handle"
operator_phone = ""
operator_role_title = "Test Role"
operator_organization = "Test Org"

[paths]
claude_workspace_root = "${SBX}/ws"
operator_homedir_path = "${SBX}/home"
cowork_install_path = "/tmp/test-cowork"
pmo_platform_repo_name = "pmo-platform"

[platform]
work_board = "github"
comms_platform = ""
TOML
chmod 600 "${SBX}/config/operator.toml"

# --- Stage 1: real install (not --dry-run) ---
# Process substitution `< <(yes "")` keeps `yes` outside the parent pipeline
# so its SIGPIPE on script exit doesn't propagate through pipefail.
printf '\nStage 1: setup-workspace.sh real install\n'
install_log=$("${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/ws" \
  --config-root "${SBX}/config" \
  < <(yes "") 2>&1)
install_exit=$?

if [ "${install_exit}" -eq 0 ]; then
  report "setup-workspace.sh exits 0" 1
else
  tail_log=$(printf '%s' "${install_log}" | tail -5 | tr '\n' '|')
  report "setup-workspace.sh exits 0" 0 "exit ${install_exit}; last lines: ${tail_log}"
fi

# --- Stage 2: post-install state assertions ---
printf '\nStage 2: post-install state assertions\n'

if [ -f "${SBX}/ws/CLAUDE.md" ]; then
  report "CLAUDE.md written" 1
else
  report "CLAUDE.md written" 0
fi

if [ -f "${SBX}/ws/.claude/settings.json" ] && jq . "${SBX}/ws/.claude/settings.json" >/dev/null 2>&1; then
  report "settings.json valid JSON" 1
else
  report "settings.json valid JSON" 0
fi

state_file="${SBX}/ws/.claude/.workspace-setup.state"
if [ -f "${state_file}" ]; then
  verification_passed=$(jq -r '.verification_passed // false' "${state_file}" 2>/dev/null)
  if [ "${verification_passed}" = "true" ]; then
    report "state file verification_passed=true" 1
  else
    report "state file verification_passed=true" 0 "actual: ${verification_passed}"
  fi
else
  report "state file present" 0 "missing: ${state_file}"
fi

hook_count=$(find "${SBX}/ws/.claude/hooks" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
if [ "${hook_count}" -ge 10 ]; then
  report "hooks installed (>=10)" 1
else
  report "hooks installed (>=10)" 0 "found ${hook_count}"
fi

# Dedicated per-hook mode files must actually LAND on a fresh install, not merely
# have a call site. A hook whose own mode file is never installed falls through to
# its in-script default, which is how block-autonomy-ceiling silently ran `enforce`
# while its header declared WARN-MODE-INITIAL. Asserting the installed artifact
# rather than the call site is deliberate: the call site is the mechanism, the
# landed file with its expected content is the outcome, and only the outcome is
# what a hook reads at runtime.
#
# `.verify-session-config-mode` is a KNOWN GAP with the same missing-call-site
# defect and is intentionally absent from this list — it is not on this release's
# path and is tracked separately, together with the durable remedy (an assertion
# over every tracked mode template rather than this per-file enumeration).
for mode_pair in ".autonomy-mode:warn" ".gh-path-leak-mode:warn" ".mode:warn"; do
  mode_file="${mode_pair%%:*}"
  mode_want="${mode_pair##*:}"
  mode_path="${SBX}/ws/.claude/hooks/${mode_file}"
  if [ ! -f "${mode_path}" ]; then
    report "mode file ${mode_file} installed" 0 "absent after install: ${mode_path}"
  else
    mode_got=$(tr -d '[:space:]' < "${mode_path}")
    if [ "${mode_got}" = "${mode_want}" ]; then
      report "mode file ${mode_file} installed (= ${mode_want})" 1
    else
      report "mode file ${mode_file} installed (= ${mode_want})" 0 "content: ${mode_got}"
    fi
  fi
done

allowlist_count=$(find "${SBX}/ws/.claude" "$(pmo_instance_path_for "${SBX}/ws")" -maxdepth 1 -name "*.txt" 2>/dev/null | wc -l | tr -d ' ')
if [ "${allowlist_count}" -ge 14 ]; then
  report "composition-surface files (>=14)" 1
else
  report "composition-surface files (>=14)" 0 "found ${allowlist_count}"
fi

# Token substitution check — narrow regex matching the install-time verification gate.
if grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${SBX}/ws/CLAUDE.md" 2>/dev/null; then
  # sigpipe-idiom: allow — `grep -o` (matches, not lines) plus an intervening `sort -u`, which must consume the WHOLE stream before the truncation is meaningful; `-m3` would cap pre-dedup and change which three tokens are reported.
  unresolved=$(grep -oE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${SBX}/ws/CLAUDE.md" | sort -u | head -3 | tr '\n' ' ')
  report "CLAUDE.md tokens substituted" 0 "unresolved: ${unresolved}"
else
  report "CLAUDE.md tokens substituted" 1
fi

if grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${SBX}/ws/.claude/settings.json" 2>/dev/null; then
  report "settings.json tokens substituted" 0
else
  report "settings.json tokens substituted" 1
fi

# Registration parity at FRESH INSTALL (ADR-121). Present + valid JSON + token-free
# all passed on a deployed workspace that was missing four of its template's hook
# registrations, so none of them speaks to completeness. Identity is the
# (event, matcher, basename(command)) triple — basename because the workspace root is
# baked into every command string. The denominator is the template's own registration
# set, computed here rather than hardcoded.
settings_parity=$(python3 -c '
import json, os, sys

def triples(path):
    with open(path) as f:
        doc = json.load(f)
    return {(e, b.get("matcher", ""), os.path.basename(h.get("command", "")))
            for e, blocks in (doc.get("hooks") or {}).items()
            for b in blocks for h in (b.get("hooks") or [])}

try:
    tpl, live = triples(sys.argv[1]), triples(sys.argv[2])
except Exception as exc:
    print("ERROR|%s" % exc); sys.exit(0)
missing = sorted(tpl - live)
print(("MISSING|%d of %d|%s" % (len(missing), len(tpl), ", ".join("%s[%s]:%s" % m for m in missing)))
      if missing else "OK|%d" % len(tpl))
' "${REPO_ROOT}/core/settings.json.template" "${SBX}/ws/.claude/settings.json" 2>/dev/null)

case "${settings_parity}" in
  OK\|*)
    report "settings.json carries all ${settings_parity#OK|} template hook registrations at fresh install" 1 ;;
  MISSING\|*)
    report "settings.json carries all template hook registrations at fresh install" 0 "${settings_parity#MISSING|}" ;;
  *)
    # Never a silent pass — an uncomputable parity is a FAIL, not an absence of one.
    report "settings.json registration parity is computable at fresh install" 0 "${settings_parity:-no output}" ;;
esac

# The Layer-2 operator overlay is scaffolded empty at install (ADR-121 §Decision 7).
# Empty is the contract, not an accident: any default or commentary would make "has
# the operator customized this?" undecidable.
settings_overlay="${SBX}/ws/.claude/settings.local.json"
if [ -f "${settings_overlay}" ] && [ "$(tr -d ' \n' < "${settings_overlay}")" = "{}" ]; then
  report "settings.local.json overlay scaffolded empty at install" 1
else
  report "settings.local.json overlay scaffolded empty at install" 0 \
    "present=$([ -f "${settings_overlay}" ] && echo yes || echo no); body=$(tr -d ' \n' < "${settings_overlay}" 2>/dev/null)"
fi

# Both ADR-121 baselines recorded at install, and DISTINCT — settings_template_sha is
# the regeneration trigger (source template) and settings_installed_sha the tamper
# anchor (post-substitution body). Equal values would mean one of them is measuring
# the wrong file.
settings_state="${SBX}/ws/.claude/.workspace-setup.state"
state_tpl_sha=$(jq -r '.settings_template_sha // ""' "${settings_state}" 2>/dev/null)
state_inst_sha=$(jq -r '.settings_installed_sha // ""' "${settings_state}" 2>/dev/null)
if [ -n "${state_tpl_sha}" ] && [ -n "${state_inst_sha}" ] && [ "${state_tpl_sha}" != "${state_inst_sha}" ]; then
  report "settings baselines recorded at install and distinct (trigger != anchor)" 1
else
  report "settings baselines recorded at install and distinct (trigger != anchor)" 0 \
    "template_sha='${state_tpl_sha}' installed_sha='${state_inst_sha}'"
fi

# Migration-removal regression: no workspace-config.toml anywhere in the sandbox.
# This guards against any future code path that might re-introduce the legacy cache.
# `find … | grep -q .` over a whole sandbox install tree is the one member of this
# class measured FIRING today: at 20,000 entries grep exits on the first path, find
# takes the broken pipe, and this guard reports NOT-FOUND while the files exist.
# `-print -quit` asks the same question with no pipe to break.
if [ -n "$(find "${SBX}" -name "workspace-config.toml" -print -quit 2>/dev/null)" ]; then
  report "no legacy workspace-config.toml" 0
else
  report "no legacy workspace-config.toml" 1
fi

# Composition-surface marker fences present on a representative file.
egress_allowlist="${SBX}/ws/.claude/egress-allowlist.txt"
if [ -f "${egress_allowlist}" ] \
   && grep -q "BEGIN MANAGED SECTION" "${egress_allowlist}" \
   && grep -q "BEGIN OPERATOR ADDITIONS" "${egress_allowlist}"; then
  report "composition-surface markers present (egress-allowlist.txt)" 1
else
  report "composition-surface markers present (egress-allowlist.txt)" 0
fi

# --- Stage 3: update.sh against the sandboxed install ---
printf '\nStage 3: update.sh --dry-run against sandboxed install\n'
update_output=$("${UPDATE}" \
  --config-root "${SBX}/config" \
  --workspace-root "${SBX}/ws" \
  --dry-run 2>&1)
update_exit=$?

# Exit-code contract: a --dry-run immediately after a clean install finds
# the composition surface already current, so it counts 0 would-be regenerations
# and returns EX_NOCHANGE (64) — the documented "nothing to do" success path, not
# an error. (A non-dry-run or a run with pending regenerations returns EX_OK (0);
# this test exercises only the post-clean-install no-op case, so 64 is expected.)
if [ "${update_exit}" -eq 64 ]; then
  report "update.sh --dry-run exits EX_NOCHANGE (64) — post-install no-op" 1
else
  report "update.sh --dry-run exits EX_NOCHANGE (64) — post-install no-op" 0 "exit ${update_exit}"
fi

if grep -q "Pre-flight passed" <<<"${update_output}"; then
  report "update.sh preflight passes against sandboxed operator.toml" 1
else
  report "update.sh preflight passes against sandboxed operator.toml" 0
fi

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_install_end_to_end.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0

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
# The workspace-root `pmo-platform` child is the CLONE, not an installer artifact.
# docs/INSTALL.md clones the repo to ${WORKSPACE_ROOT}/pmo-platform and only THEN
# runs setup-workspace.sh, so a real workspace root always carries it — which is why
# validate-install.sh check A2 lists it among the five required root dirs. This
# sandbox instead passes the repo in via --source-repo from the real repo root, so
# nothing here would ever create it, and A2 would FAIL unconditionally for a reason
# unrelated to anything under test.
#
# That is not merely a red assertion. An A2 arm phrased "A2 FAILs when X is absent"
# is satisfied by ANY A2 failure, so a permanently-failing A2 makes every such arm
# pass whether or not X matters — an assertion that has never been shown capable of
# failing. Restoring the clone directory is what keeps the Stage 5 arms attributable;
# the Stage 5 baseline arm is the control that proves it worked.
mkdir -p "${SBX}/ws/pmo-platform"

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

# --- operations-root tier: the operations-workspace context anchor ------------
# The operations-root tier is the only tier resolving OUTSIDE both .claude/ and
# the operator-instance base, so a real install is the only place its parent
# pre-create, its resolver arm and its suffix-strip are exercised together.
OPS_ANCHOR="${SBX}/ws/projects/CLAUDE.md"
if [ -f "${OPS_ANCHOR}" ]; then
  report "operations context anchor installed at projects/CLAUDE.md" 1
else
  report "operations context anchor installed at projects/CLAUDE.md" 0 \
    "absent: ${OPS_ANCHOR}"
fi

# Suffix-strip arm: the row's source basename is CLAUDE.md.template, so a tier
# that failed to strip would land the template name instead. Asserting the
# absence of the un-stripped name is what discriminates "stripped" from
# "happened to also write the right file".
if [ ! -e "${SBX}/ws/projects/CLAUDE.md.template" ]; then
  report "operations anchor .template suffix stripped (no projects/CLAUDE.md.template)" 1
else
  report "operations anchor .template suffix stripped (no projects/CLAUDE.md.template)" 0
fi

# Marker dialect: the row declares `markdown`, so the fence is the HTML-comment
# form with a resolved managed_sha — NOT the `#`-prefixed plain form. Reading the
# fence back is what proves the dialect generalized past its single prior user;
# asserting mere existence would not.
if grep -qE '^<!-- === BEGIN MANAGED SECTION' "${OPS_ANCHOR}" 2>/dev/null \
   && grep -qE '^<!-- managed_sha: [0-9a-f]{64} -->' "${OPS_ANCHOR}" 2>/dev/null; then
  report "operations anchor carries the markdown fence with a resolved managed_sha" 1
else
  report "operations anchor carries the markdown fence with a resolved managed_sha" 0 \
    "fence/managed_sha not in markdown form"
fi

# The row is `raw` (token-free). An unresolved token here would fail the install
# validator's A5b check on a real workspace.
if [ -f "${OPS_ANCHOR}" ] && ! grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${OPS_ANCHOR}"; then
  report "operations anchor carries no unresolved operator tokens" 1
else
  report "operations anchor carries no unresolved operator tokens" 0
fi

# AC-3 teeth: the anchor REFERENCES, it never restates. No line of its managed
# body may appear verbatim in the charter template or the operations governance
# file. grep -Fxf, not comm — a numerically-sorted comm silently yields a wrong
# set difference. Blank/fence/heading lines are stripped so the comparison is
# over content lines only.
if [ -f "${OPS_ANCHOR}" ]; then
  ops_body="${SBX}/ops-anchor-body.txt"
  grep -vE '^\s*$|^<!-- |^#' "${OPS_ANCHOR}" > "${ops_body}" 2>/dev/null || true
  ops_body_lines=$(grep -c . "${ops_body}" 2>/dev/null | tr -d ' ')
  ops_restated=$(grep -Fxf "${ops_body}" \
    "${REPO_ROOT}/core/CLAUDE.md.template" \
    "${REPO_ROOT}/core/governance/OPERATIONS.md" 2>/dev/null | grep -c . | tr -d ' ')
  # Anti-vacuity: a zero over an EMPTY body is not a result. The denominator is
  # asserted before the zero is read.
  if [ "${ops_body_lines}" -ge 5 ] && [ "${ops_restated}" = "0" ]; then
    report "operations anchor restates no line of the charter or OPERATIONS.md (${ops_restated} of ${ops_body_lines} content lines)" 1
  else
    report "operations anchor restates no line of the charter or OPERATIONS.md" 0 \
      "restated=${ops_restated} over body_lines=${ops_body_lines} (body_lines < 5 means a BROKEN PROBE — the zero is vacuous)"
  fi
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

# The ambient-intake capability's three member directories must LAND on a fresh
# install. Asserted HERE, in the post-install block, rather than at the tail of
# the file: by the tail a real update.sh has run, and the update path scaffolds
# these directories too, so a tail assertion could pass on the update's work
# while the installer still created nothing. Nothing but setup-workspace.sh has
# run at this point, so a pass here is attributable to the installer alone.
#
# Asserting the landed directory rather than the mkdir call site is deliberate,
# for the same reason the mode-file loop above asserts the landed file: the call
# site is the mechanism, the directory on disk is the outcome, and the outcome is
# the only thing the sweep reads at runtime. A call-site assertion is exactly
# what would have passed while this capability shipped inert.
ambient_base="$(pmo_instance_path_for "${SBX}/ws")"
for ambient_dir in inbox ambient-intake external-sync; do
  if [ -d "${ambient_base}/${ambient_dir}" ]; then
    report "ambient-intake dir ${ambient_dir} installed" 1
  else
    report "ambient-intake dir ${ambient_dir} installed" 0 \
      "absent after install: ${ambient_base}/${ambient_dir}"
  fi
done

# The OPERATIONS TIER SCAFFOLD must land on a fresh install — the directories AND the
# seed orientation cards that make them self-describing. Asserted HERE, in the
# post-install block, for exactly the reason the ambient trio above is: nothing but
# setup-workspace.sh has run at this point, so a pass is attributable to the installer
# alone and not to a later update.sh.
#
# The expected seed set is read from the SHIPPED TEMPLATE TREE, never re-typed here. A
# hardcoded list in the test would be a second enumeration of the same set, free to
# agree with itself while both it and the tree drifted from what the installer walks.
ops_root="$(pmo_operations_path_for "${SBX}/ws")"
ops_tree="${REPO_ROOT}/operations/templates/operations-tiers"

seed_total=$(find "${ops_tree}" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "${seed_total}" -ge 1 ]; then
  report "operations-tier template tree ships seed cards (denominator ${seed_total})" 1
else
  # Reported, not assumed. With an empty tree every assertion below is vacuous, and a
  # vacuous arm must never read as a pass.
  report "operations-tier template tree ships seed cards" 0 \
    "no *.md under ${ops_tree} — every operations-tier assertion below would be vacuous"
fi

seed_missing=""
while IFS= read -r seed_rel; do
  [ -z "${seed_rel}" ] && continue
  [ -f "${ops_root}/${seed_rel}" ] || seed_missing="${seed_missing} ${seed_rel}"
done <<EOF
$(cd "${ops_tree}" && find . -type f -name '*.md' | sed 's|^\./||' | LC_ALL=C sort)
EOF
if [ -z "${seed_missing}" ]; then
  report "operations-tier seed cards installed on fresh install (${seed_total}/${seed_total})" 1
else
  report "operations-tier seed cards installed on fresh install (${seed_total}/${seed_total})" 0 \
    "absent:${seed_missing}"
fi

# AC-4 — "every provisioned folder contains a README; an empty unexplained folder
# fails" — asserted as a PROPERTY over what actually landed rather than against a list
# this test re-types. A hardcoded expectation can agree with itself while it and the
# installer both drift; a property over the landed tree cannot, and it also catches the
# inverse defect a template-driven check would miss: a directory the installer creates
# that no seed card describes.
tier_unexplained=""
tier_count=0
while IFS= read -r landed_dir; do
  [ -z "${landed_dir}" ] && continue
  tier_count=$((tier_count + 1))
  [ -f "${landed_dir}/README.md" ] || tier_unexplained="${tier_unexplained} ${landed_dir#"${ops_root}/"}"
done <<EOF
$(find "${ops_root}" -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort)
EOF
# The 9 is deliberate and is a LOUD coupling, not a stale-count trap: a release that
# adds or drops a tier fails here immediately and updates this numeral alongside the
# tree, rather than silently widening what the installer provisions unobserved.
if [ "${tier_count}" -eq 9 ] && [ -z "${tier_unexplained}" ]; then
  report "9 operations-tier directories present, every one carrying a README (AC-1 + AC-4)" 1
else
  report "9 operations-tier directories present, every one carrying a README (AC-1 + AC-4)" 0 \
    "created=${tier_count} (want 9); unexplained:${tier_unexplained:-none}"
fi

# The automation ceiling must be discoverable in the GENERATED operator.toml.
# Presence in core/config/operator.toml.template does not count and is why this
# assertion exists: write_operator_toml generates from a fixed schema and never
# reads that template, so a default documented only there reached no install.
gen_toml="${SBX}/config/operator.toml"
gen_level=$(grep -E '^automation_level[[:space:]]*=' "${gen_toml}" 2>/dev/null | wc -l | tr -d ' ')
if grep -q '^\[automation\]' "${gen_toml}" 2>/dev/null && [ "${gen_level}" -eq 1 ]; then
  report "generated operator.toml carries the [automation] dial (exactly once)" 1
else
  report "generated operator.toml carries the [automation] dial (exactly once)" 0 \
    "section present=$(grep -c '^\[automation\]' "${gen_toml}" 2>/dev/null || printf '0'); automation_level lines=${gen_level}"
fi

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

# --- Stage 4: install-completeness gate (#4449) ---
# update.sh refuses to refresh the security-hook bundle when a hook-tier composition
# surface is absent. A hook-tier surface is an allowlist — the ESCAPE half of a hook
# control — so shipping the enforcement half without it leaves the workspace strictly
# MORE restrictive than either tool intends, and the run would otherwise report
# success over that state.
#
# Asserted in BOTH directions on purpose. The negative arm proves the gate fires and
# fires EARLY (before the hook refresh, not merely loudly at the end). The positive
# arm proves it stays silent on the healthy workspace Stage 1 built — without it, a
# gate that fired unconditionally would look identical to a gate that works.
printf '\nStage 4: install-completeness gate (update.sh refuses a partial hook-tier install)\n'

gate_surface="${SBX}/ws/.claude/scope-segregation-allowlist.txt"
gate_stash="${SBX}/gate-stash-scope-segregation-allowlist.txt"

if [ ! -f "${gate_surface}" ]; then
  # Reported, not assumed: a fixture that never had the surface would make the
  # negative arm below vacuous, and a vacuous arm must not read as a pass.
  report "Stage 4 precondition: hook-tier surface present after install" 0 "absent: ${gate_surface}"
else
  report "Stage 4 precondition: hook-tier surface present after install" 1

  # NEGATIVE ARM — remove one hook-tier surface, then run a real (non-dry-run) update.
  mv "${gate_surface}" "${gate_stash}"
  gate_out=$("${UPDATE}" \
    --config-root "${SBX}/config" \
    --workspace-root "${SBX}/ws" 2>&1)
  gate_exit=$?

  if [ "${gate_exit}" -eq 75 ]; then
    report "update.sh exits 75 (EX_INCOMPLETE) when a hook-tier surface is absent" 1
  else
    tail_out=$(printf '%s' "${gate_out}" | tail -4 | tr '\n' '|')
    report "update.sh exits 75 (EX_INCOMPLETE) when a hook-tier surface is absent" 0 \
      "exit ${gate_exit}; last: ${tail_out}"
  fi

  # The ordering IS the contract: halting after the refresh would still have landed
  # the asymmetric state, just noisily.
  if grep -q 'REFRESHED:' <<<"${gate_out}"; then
    report "the gate fires BEFORE the hook refresh (no REFRESHED emitted)" 0 "hook refresh ran anyway"
  else
    report "the gate fires BEFORE the hook refresh (no REFRESHED emitted)" 1
  fi

  if grep -q 'scope-segregation-allowlist.txt' <<<"${gate_out}"; then
    report "the gate NAMES the absent surface" 1
  else
    report "the gate NAMES the absent surface" 0 "absent surface not named in output"
  fi

  # POSITIVE ARM — restore the surface; the gate must go quiet and the run complete.
  mv "${gate_stash}" "${gate_surface}"
  ok_out=$("${UPDATE}" \
    --config-root "${SBX}/config" \
    --workspace-root "${SBX}/ws" 2>&1)
  ok_exit=$?
  if [ "${ok_exit}" -eq 0 ] || [ "${ok_exit}" -eq 64 ]; then
    report "healthy workspace: the gate does not fire (exit 0/64)" 1
  else
    tail_out=$(printf '%s' "${ok_out}" | tail -4 | tr '\n' '|')
    report "healthy workspace: the gate does not fire (exit 0/64)" 0 "exit ${ok_exit}; last: ${tail_out}"
  fi
fi

# --- Stage 4b: deployed-hook executability (#4449 AC-1 limb 1 / AC-3 limb 1) ---
# AC #3 requires update.sh to exit non-zero when a deployed control is left
# "non-executable OR list-less". Stage 4 above covers list-less. This covers the
# other limb, and it covers the repair that has to exist underneath it: a gate whose
# named remedy cannot work is a permanently-red gate, not a fix.
#
# Three arms, and the third is what keeps the second honest.
#   REPAIR    — strip +x from a deployed platform hook. The refresh must restore it.
#               This is the path that previously had no repair at all: the checksum
#               comparison is over CONTENT, and a hook stripped of +x is
#               byte-identical to a healthy one, so the refresh returned "unchanged"
#               and left a hook that cannot run.
#   DETECT    — plant a hook the refresh CANNOT repair, so the assertion has
#               something real to catch. install_hooks only ever iterates the source
#               hook set, so a file that is not in it is never touched; that is the
#               genuinely unrepairable case, and it is the one the assertion exists
#               for. update.sh must exit 75 and name the file.
#   RECOVER   — remove it; the run must go back to 0/64. Without this arm a gate that
#               fired unconditionally would be indistinguishable from one that works,
#               and every later stage would inherit a workspace stuck at 75.
printf '\nStage 4b: deployed-hook executability (update.sh refuses a hook that cannot run)\n'

exec_hook="${SBX}/ws/.claude/hooks/block-destructive.sh"
stray_hook="${SBX}/ws/.claude/hooks/zz-unrepairable-probe.sh"

if [ ! -x "${exec_hook}" ]; then
  # Reported, not assumed: if the fixture hook is already non-executable the repair
  # arm proves nothing about a repair.
  report "Stage 4b precondition: deployed hook is executable after install" 0 "not executable: ${exec_hook}"
else
  report "Stage 4b precondition: deployed hook is executable after install" 1

  # REPAIR ARM
  chmod -x "${exec_hook}"
  if [ -x "${exec_hook}" ]; then
    # The strip itself must be shown to have worked, or the arm below is vacuous.
    report "Stage 4b precondition: +x strip took effect" 0 "still executable after chmod -x"
  else
    report "Stage 4b precondition: +x strip took effect" 1

    repair_out=$("${UPDATE}" \
      --config-root "${SBX}/config" \
      --workspace-root "${SBX}/ws" 2>&1)
    repair_exit=$?

    if [ -x "${exec_hook}" ]; then
      report "update.sh restores a stripped +x on a content-identical hook" 1
    else
      report "update.sh restores a stripped +x on a content-identical hook" 0 \
        "still non-executable after update (exit ${repair_exit})"
    fi

    if [ "${repair_exit}" -eq 0 ] || [ "${repair_exit}" -eq 64 ]; then
      report "the repaired run completes (exit 0/64)" 1
    else
      tail_out=$(printf '%s' "${repair_out}" | tail -4 | tr '\n' '|')
      report "the repaired run completes (exit 0/64)" 0 "exit ${repair_exit}; last: ${tail_out}"
    fi

    # Reporting the repair is the point of the release, not a nicety: a run that
    # changed a file mode must not describe itself as having changed nothing.
    if grep -q 'MODE-REPAIRED:' <<<"${repair_out}"; then
      report "the run NAMES the mode repair rather than reporting no change" 1
    else
      report "the run NAMES the mode repair rather than reporting no change" 0 \
        "no MODE-REPAIRED line in output"
    fi
  fi

  # DETECT ARM
  printf '#!/usr/bin/env bash\nexit 0\n' > "${stray_hook}"
  chmod -x "${stray_hook}"
  nonexec_out=$("${UPDATE}" \
    --config-root "${SBX}/config" \
    --workspace-root "${SBX}/ws" 2>&1)
  nonexec_exit=$?

  if [ "${nonexec_exit}" -eq 75 ]; then
    report "update.sh exits 75 (EX_INCOMPLETE) when a deployed hook is not executable" 1
  else
    tail_out=$(printf '%s' "${nonexec_out}" | tail -4 | tr '\n' '|')
    report "update.sh exits 75 (EX_INCOMPLETE) when a deployed hook is not executable" 0 \
      "exit ${nonexec_exit}; last: ${tail_out}"
  fi

  if grep -q 'zz-unrepairable-probe.sh' <<<"${nonexec_out}"; then
    report "the gate NAMES the non-executable hook" 1
  else
    report "the gate NAMES the non-executable hook" 0 "hook not named in output"
  fi

  # The registrations that name these scripts must not have been wired while one of
  # them could not run — the same ordering contract Stage 4 asserts on the other limb.
  if grep -q 'Phase 5d' <<<"${nonexec_out}"; then
    report "the gate fires BEFORE the settings refresh (no Phase 5d emitted)" 0 "settings refresh ran anyway"
  else
    report "the gate fires BEFORE the settings refresh (no Phase 5d emitted)" 1
  fi

  # RECOVER ARM
  rm -f "${stray_hook}"
  recover_out=$("${UPDATE}" \
    --config-root "${SBX}/config" \
    --workspace-root "${SBX}/ws" 2>&1)
  recover_exit=$?
  if [ "${recover_exit}" -eq 0 ] || [ "${recover_exit}" -eq 64 ]; then
    report "healthy workspace: the executability gate does not fire (exit 0/64)" 1
  else
    tail_out=$(printf '%s' "${recover_out}" | tail -4 | tr '\n' '|')
    report "healthy workspace: the executability gate does not fire (exit 0/64)" 0 \
      "exit ${recover_exit}; last: ${tail_out}"
  fi
fi

# --- Stage 5: ambient-intake provisioning, both directions ---
# Stage 2 proved the three directories land on a fresh install. This stage
# proves the two things a landed-artifact assertion cannot: that their ABSENCE
# is detected, and that an already-installed workspace gets them back-filled.
#
# Without the negative arm the Stage 2 assertions could pass vacuously — a check
# that has never been shown capable of failing is not yet evidence, which is the
# defect class this whole release exists to close.
printf '\nStage 5: ambient-intake provisioning (absence detected; existing installs back-filled)\n'

ambient_base="$(pmo_instance_path_for "${SBX}/ws")"
ambient_probe="${ambient_base}/inbox"

# Every A2 read below goes through this one helper, so the baseline, negative and
# positive arms are provably the SAME command against the SAME workspace and differ
# in exactly one variable: whether the drop-zone is on disk.
#
# --dry-run is deliberate and does not weaken any assertion here. A2 is dry-run
# INVARIANT: check_a2_workspace_layout carries no DRY_RUN branch, and emit_pass /
# emit_fail print the "[A2] …" line to stdout before record_step's dry-run
# early-return, so the verdict these arms grep is byte-for-byte what a full run
# emits. What --dry-run does drop is check A8, which shells out to
# `deploy.sh --check --warn` — minutes of work against the real repo, irrelevant to
# every assertion in this stage, and covered by its own suite. It also stops each
# read persisting a .workspace-validation/ tree into the sandbox.
a2_probe() {
  bash "${REPO_ROOT}/docs/scripts/validate-install.sh" \
    --workspace-root "${SBX}/ws" \
    --source-repo "${REPO_ROOT}" \
    --mode install --dry-run 2>&1 || true
}

if [ ! -d "${ambient_probe}" ]; then
  # Reported, not assumed. A fixture that never had the drop-zone would make
  # both arms below vacuous, and a vacuous arm must not read as a pass.
  report "Stage 5 precondition: drop-zone present before the negative arm" 0 "absent: ${ambient_probe}"
else
  report "Stage 5 precondition: drop-zone present before the negative arm" 1

  # BASELINE ARM (anti-vacuity) — the matched-pair control, following the pattern
  # test_validate_install.sh arms 3/4 establish: two arms differing in exactly one
  # variable. The negative arm below asserts A2 FAILs once the drop-zone is removed.
  # That is evidence ONLY if A2 passes while the drop-zone is present; against a
  # permanently-failing A2 the negative arm cannot fail and proves nothing. So run
  # the identical probe first, drop-zone intact, and require the same strong verdict
  # the positive arm requires — which also proves the ambient resolver actually
  # loaded, rather than A2 passing on the five root dirs alone.
  a2_base_out=$(a2_probe)
  if grep -q '^\[A2\] PASS.*ambient-intake dirs present' <<<"${a2_base_out}"; then
    report "Stage 5 baseline: A2 PASSes with the drop-zone present (so the negative arm can fail)" 1
  else
    a2_base_line=$(grep -m1 '^\[A2\]' <<<"${a2_base_out}" || printf '(no A2 line emitted)')
    report "Stage 5 baseline: A2 PASSes with the drop-zone present (so the negative arm can fail)" 0 \
      "observed: ${a2_base_line} — while this is red, every A2 verdict below is unattributable"
  fi

  # NEGATIVE ARM — remove the drop-zone; the install validator's workspace-layout
  # check must FAIL and must NAME what is missing. Before this card it passed.
  rmdir "${ambient_probe}"
  a2_out=$(a2_probe)

  if grep -q '^\[A2\] FAIL' <<<"${a2_out}"; then
    report "validate-install A2 FAILs when the drop-zone is absent" 1
  else
    a2_line=$(grep -m1 '^\[A2\]' <<<"${a2_out}" || printf '(no A2 line emitted)')
    report "validate-install A2 FAILs when the drop-zone is absent" 0 "observed: ${a2_line}"
  fi

  # Naming it is the contract, not merely failing: a layout failure that does not
  # say which directory is missing sends the operator hunting.
  if grep -q 'ambient:.*inbox' <<<"${a2_out}"; then
    report "A2 NAMES the absent ambient directory" 1
  else
    report "A2 NAMES the absent ambient directory" 0 "no 'ambient:' clause naming inbox in A2 output"
  fi

  # BACK-FILL ARM — the update path must restore it on an already-installed
  # workspace. This is the only coverage the update-side scaffold phase has, and
  # it is what makes the capability reach workspaces that predate this release
  # rather than fresh installs only.
  update_backfill_out=$("${UPDATE}" \
    --config-root "${SBX}/config" \
    --workspace-root "${SBX}/ws" 2>&1)
  update_backfill_exit=$?

  if [ -d "${ambient_probe}" ]; then
    report "update.sh back-fills the ambient drop-zone onto an existing install" 1
  else
    tail_out=$(printf '%s' "${update_backfill_out}" | tail -4 | tr '\n' '|')
    report "update.sh back-fills the ambient drop-zone onto an existing install" 0 \
      "still absent after update (exit ${update_backfill_exit}); last: ${tail_out}"
  fi

  # POSITIVE ARM — with the directory restored, the check must go quiet. Together
  # with the baseline arm this brackets the negative arm: PASS, remove, FAIL,
  # restore, PASS. A check that always failed would break the two outer arms, and a
  # check that never failed would break the inner one.
  a2_ok_out=$(a2_probe)
  if grep -q '^\[A2\] PASS.*ambient-intake dirs present' <<<"${a2_ok_out}"; then
    report "A2 PASSes once the drop-zone is restored, and states the ambient denominator" 1
  else
    a2_ok_line=$(grep -m1 '^\[A2\]' <<<"${a2_ok_out}" || printf '(no A2 line emitted)')
    report "A2 PASSes once the drop-zone is restored, and states the ambient denominator" 0 \
      "observed: ${a2_ok_line}"
  fi
fi

# --- Stage 6: operations-tier scaffold on the RE-BOOTSTRAP flow + idempotence ---
# Re-bootstrap is the flow every ALREADY-INSTALLED operator takes, and it is the one a
# fresh-install-only test structurally cannot speak for. create_dir_layout runs on BOTH
# flows, so a seed scaffold wired into fresh_install alone would hand that population
# nine empty directories and no orientation at all — while a fresh-install assertion
# reported a clean pass. This stage is the arm that goes red if the second call site is
# ever dropped.
#
# Four arms, each keeping another honest:
#   DELETE-RESTORE — a removed seed must come back. This is the ONLY arm that can tell a
#                    live second call site from a dead one: every other arm is already
#                    satisfied by the work the FIRST install did, so a stage without it
#                    would pass on a scaffold that never ran again.
#   SENTINEL-EDIT  — an operator-edited seed keeps its edit (create-once, AC-3). The
#                    restore arm above proves the scaffold ran; this proves it did not
#                    run over the operator.
#   SENTINEL-FILE  — operator content placed inside a tier directory survives (AC-3,
#                    "destroys no operator content" — the directory case, not the file
#                    case, which skip-if-exists covers separately).
#   NO-REWRITE     — every untouched seed is byte-identical across the run, so "restored
#                    exactly the one missing file" is distinguishable from "rewrote them
#                    all and happened to produce the same bytes for nine of ten".
printf '\nStage 6: operations-tier scaffold on the re-bootstrap flow + idempotence\n'

reb_edited="${ops_root}/_pmo/people/README.md"
reb_deleted="${ops_root}/Archive/README.md"
reb_sentinel="${ops_root}/_config/operator-sentinel.md"
reb_marker="OPERATOR EDIT SENTINEL — must survive re-bootstrap"

if [ ! -f "${reb_edited}" ] || [ ! -f "${reb_deleted}" ]; then
  report "Stage 6 precondition: the seeds this stage mutates exist after Stage 1" 0 \
    "missing one of: ${reb_edited} ${reb_deleted} — every arm below would be vacuous"
else
  report "Stage 6 precondition: the seeds this stage mutates exist after Stage 1" 1

  printf '%s\n' "${reb_marker}" >> "${reb_edited}"
  printf 'operator content that install must never touch\n' > "${reb_sentinel}"
  rm -f "${reb_deleted}"

  # Seed the automation dial to a NON-DEFAULT enum member before the second run, so the
  # duplicate-key arm below cannot be satisfied by the seed and the generator default
  # coinciding. `off` is declared in operator-toml-schema.json alongside the default
  # `recommend`, so the two are distinguishable by construction. The seed REPLACES in
  # place and never appends — an appending seed would manufacture the very duplicate the
  # arm exists to detect. The pre-run line is captured for the failure detail, which is
  # what keeps "the seed did not apply", "the generator reset the value" and "the key was
  # duplicated" three distinguishable readings of one red arm rather than one ambiguous
  # one. No assertion fires here: a no-op seed surfaces at the arm below as a wrong value,
  # so the value predicate is its own control and a separate precondition arm would only
  # restate it.
  #
  # `tr`, not `head`: tr consumes the whole stream, so the upstream grep cannot take a
  # SIGPIPE from a short-circuiting reader. Stage 1 emits the key exactly once, so the
  # joined form is a single line in practice and a visible multi-line join if it is not —
  # which is itself the diagnostic this capture exists to provide.
  reb_pre_level=$(grep -E '^automation_level[[:space:]]*=' "${SBX}/config/operator.toml" 2>/dev/null | tr '\n' ';')
  sed -i '' -E 's/^automation_level[[:space:]]*=.*/automation_level = "off"/' \
    "${SBX}/config/operator.toml"

  # Fingerprint every surviving seed BEFORE the run so an over-write is measured rather
  # than assumed. Sorted for a stable comparison across filesystems.
  # `-exec … +` rather than a pipe into xargs: with an empty file set xargs would run
  # shasum with no operands, which reads STDIN and hangs the suite. -exec + simply does
  # not run. Sorted after the fact so the comparison is order-stable.
  reb_before=$(cd "${ops_root}" && find . -type f -name '*.md' -exec shasum -a 256 {} + 2>/dev/null | LC_ALL=C sort)

  reb_log=$("${SETUP}" \
    --source-repo "${REPO_ROOT}" \
    --workspace-root "${SBX}/ws" \
    --config-root "${SBX}/config" \
    < <(yes "") 2>&1)
  reb_exit=$?

  # Asserted explicitly so a red arm below is attributable to the scaffold rather than
  # to an unrelated failure earlier in the second run.
  if [ "${reb_exit}" -eq 0 ]; then
    report "second setup-workspace.sh run exits 0 (re-bootstrap flow)" 1
  else
    reb_tail=$(printf '%s' "${reb_log}" | tail -5 | tr '\n' '|')
    report "second setup-workspace.sh run exits 0 (re-bootstrap flow)" 0 \
      "exit ${reb_exit}; last lines: ${reb_tail}"
  fi

  # The run must have taken the re-bootstrap branch, not fresh-install. Without this the
  # DELETE-RESTORE arm could be satisfied by a fresh_install-only call site.
  if grep -q 'RE-BOOTSTRAP flow' <<<"${reb_log}"; then
    report "the second run routed to RE-BOOTSTRAP (not fresh-install)" 1
  else
    report "the second run routed to RE-BOOTSTRAP (not fresh-install)" 0 \
      "no 'RE-BOOTSTRAP flow' line — the arms below would not be testing the re-bootstrap path"
  fi

  # DUPLICATE-KEY ARM
  # The Stage 1 exactly-once assertion covers the FRESH-install path. The duplicate this
  # arm exists for arises only on the SECOND bootstrap, where write_operator_toml emits
  # every delivered key and passthrough() then echoes the prior file for anything outside
  # its already-emitted set. Placed here, directly after the routing assertion, a red arm
  # is already attributable: the two arms above have established that the second run
  # exited 0 AND took the re-bootstrap branch, so a duplicate cannot be misread as "the
  # second run did not happen".
  #
  # Generalised from one key to whole-file (section, key) uniqueness. The hazard is a
  # property of the passthrough-versus-already-emitted relationship, which holds for every
  # managed key identically — automation_level is one instance of a class, and the durable
  # predicate is the class. A single-key count would report one of however many keys a
  # broken guard duplicates. automation_level is still named and counted so the arm stays
  # attributable to the regression that motivated it.
  reb_dup=$(python3 -c '
import re, sys
try:
    body = open(sys.argv[1], encoding="utf-8", errors="replace").read()
except Exception as exc:
    print("ERROR|%s" % exc); sys.exit(0)
sec, n, seen, lvl, stray = "", 0, {}, [], 0
for raw in body.split("\n"):
    line = raw.strip()
    # A comment is decided by the FIRST non-space character only. Trailing # is not
    # stripped: the generator emits no trailing comments, and stripping one would
    # corrupt a quoted value that legitimately contains a hash.
    if not line or line.startswith("#"):
        continue
    m = re.match(r"^\[\[([^\]]+)\]\]$", line)
    if m:
        # Array-of-tables: each occurrence opens a FRESH context, so repeated members
        # are not miscounted as duplicates.
        n += 1; sec = "%s/%d" % (m.group(1), n); continue
    m = re.match(r"^\[([^\]]+)\]$", line)
    if m:
        sec = m.group(1); continue
    if "=" not in line:
        continue
    k, v = [p.strip() for p in line.split("=", 1)]
    if not sec:
        stray += 1
    seen[(sec, k)] = seen.get((sec, k), 0) + 1
    if k == "automation_level":
        lvl.append(v)
dups = sorted("%s.%s x%d" % (s, kk, c) for (s, kk), c in seen.items() if c > 1)
val = lvl[0].strip(chr(34)) if lvl else "<absent>"
if dups or len(lvl) != 1 or val != "off" or stray:
    print("BAD|duplicated: %s; automation_level lines=%d value=%s; pre-section key lines=%d; pairs scanned=%d"
          % (", ".join(dups) or "none", len(lvl), val, stray, len(seen)))
else:
    print("OK|%d" % len(seen))
' "${SBX}/config/operator.toml" 2>/dev/null)

  case "${reb_dup}" in
    OK\|*)
      report "re-bootstrap emits no duplicated key (automation_level exactly once, operator value preserved; ${reb_dup#OK|} pairs)" 1 ;;
    BAD\|*)
      report "re-bootstrap emits no duplicated key (automation_level exactly once, operator value preserved)" 0 \
        "${reb_dup#BAD|}; pre-run line was: ${reb_pre_level:-<none>}" ;;
    *)
      # Never a silent pass — an uncomputable uniqueness verdict is a FAIL, not the
      # absence of one.
      report "re-bootstrap key uniqueness is computable" 0 "${reb_dup:-no output}" ;;
  esac

  # TOML-SHAPE ARM
  # Occurrence-count alone does not localize the defect and a shape scan alone does not
  # name it, so both limbs ship: a duplicated key leaves the shape valid, which is
  # exactly why the arm above is the one that goes red for it.
  #
  # tomllib is the obvious parser and is unavailable here — the operator baseline is
  # Python 3.9 and tomllib is 3.11+, the same constraint check-work-hierarchy.py and
  # check-label-parity.py each record at their own regex parses. Guarding it behind
  # try/except would degrade this arm to a vacuous SKIP on the very host the baseline
  # describes, which is worse than not shipping it. Shape here plus uniqueness above is
  # what makes the pair a real parse rather than a line-shape check: tomllib itself
  # raises on a duplicate key, so a scan that admits one is not equivalent to a parse.
  reb_shape=$(python3 -c '
import re, sys
try:
    body = open(sys.argv[1], encoding="utf-8", errors="replace").read()
except Exception as exc:
    print("ERROR|%s" % exc); sys.exit(0)
bad, n = [], 0
for i, raw in enumerate(body.split("\n")):
    line = raw.strip()
    if not line:
        continue
    n += 1
    if line.startswith("#"):
        continue
    if re.match(r"^\[\[?[^\]]+\]\]?$", line):
        continue
    # Split on the FIRST = only, so an array or a value containing = is not mis-shaped.
    if re.match(r"^[A-Za-z_][A-Za-z0-9_.-]*[ \t]*=", line):
        continue
    bad.append("%d:%s" % (i + 1, line[:48]))
if n == 0:
    print("SHAPE_BAD|no non-blank lines — an empty emit is not a well-formed config")
elif bad:
    print("SHAPE_BAD|%d of %d non-blank lines are neither comment, section header, nor key = value: %s"
          % (len(bad), n, "; ".join(bad[:3])))
else:
    print("SHAPE_OK|%d" % n)
' "${SBX}/config/operator.toml" 2>/dev/null)

  case "${reb_shape}" in
    SHAPE_OK\|*)
      report "re-bootstrap emits an operator.toml whose every line parses (${reb_shape#SHAPE_OK|} non-blank lines)" 1 ;;
    SHAPE_BAD\|*)
      report "re-bootstrap emits an operator.toml whose every line parses" 0 "${reb_shape#SHAPE_BAD|}" ;;
    *)
      # Never a silent pass — an uncomputable shape verdict is a FAIL, not the absence
      # of one.
      report "re-bootstrap TOML shape is computable" 0 "${reb_shape:-no output}" ;;
  esac

  # DELETE-RESTORE ARM
  if [ -f "${reb_deleted}" ]; then
    report "re-bootstrap re-seeds a deleted operations-tier card (second call site is LIVE)" 1
  else
    report "re-bootstrap re-seeds a deleted operations-tier card (second call site is LIVE)" 0 \
      "still absent after re-bootstrap: ${reb_deleted} — scaffold_operations_tiers is not wired into rebootstrap()"
  fi

  # SENTINEL-EDIT ARM
  if grep -qF "${reb_marker}" "${reb_edited}" 2>/dev/null; then
    report "an operator-edited seed keeps its edit across re-bootstrap (create-once, AC-3)" 1
  else
    report "an operator-edited seed keeps its edit across re-bootstrap (create-once, AC-3)" 0 \
      "sentinel line absent from ${reb_edited} — the scaffold clobbered operator content"
  fi

  # SENTINEL-FILE ARM
  if [ -f "${reb_sentinel}" ]; then
    report "operator content inside a tier directory survives re-bootstrap (AC-3)" 1
  else
    report "operator content inside a tier directory survives re-bootstrap (AC-3)" 0 \
      "removed by the run: ${reb_sentinel}"
  fi

  # NO-REWRITE ARM
  reb_after=$(cd "${ops_root}" && find . -type f -name '*.md' -exec shasum -a 256 {} + 2>/dev/null | LC_ALL=C sort)
  reb_before_kept=$(printf '%s\n' "${reb_before}" | grep -vF './Archive/README.md')
  reb_after_kept=$(printf '%s\n' "${reb_after}" | grep -vF './Archive/README.md')
  if [ "${reb_before_kept}" = "${reb_after_kept}" ]; then
    report "every seed the run did not restore is byte-identical across it (no blind rewrite)" 1
  else
    report "every seed the run did not restore is byte-identical across it (no blind rewrite)" 0 \
      "checksum set changed beyond the single restored card"
  fi
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

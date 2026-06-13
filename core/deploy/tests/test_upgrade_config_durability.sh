#!/usr/bin/env bash
# test_upgrade_config_durability.sh — user-config durability across a version upgrade
#
# Closes the one real gap in the install/onboarding/update regression family
# (#706, epic #325 ticket C8): the existing harness proves a CLEAN install + a
# --dry-run no-op update (test_install_end_to_end.sh Stage 3), but NO test
# exercises a NON-dry-run update that actually regenerates a managed section
# while an operator addition is present. This test adds:
#
#   Suite G (real content-delta upgrade) — the core new assertion:
#     fresh sandbox install → inject an operator addition INSIDE the
#     OPERATOR ADDITIONS fence of a deployed composition-surface file →
#     simulate a version delta by editing a managed-section SOURCE TEMPLATE in
#     a sandboxed repo copy (<sbx>/repo-next) so its source SHA differs →
#     run that repo copy's update.sh (non-dry-run) → assert the managed section
#     REGENERATED (target now carries the repo-next delta; exit EX_OK 0, not
#     EX_NOCHANGE 64) AND the operator addition survives BYTE-FOR-BYTE.
#
#   Suite F (synthetic durability, non-dry-run no-op):
#     a non-dry-run update from the UNCHANGED source finds nothing to
#     regenerate (exit EX_NOCHANGE 64) and leaves the operator addition intact.
#
#   AC-b2 (deployed-tree link integrity, partial — see LIMITATION below):
#     the check-doc-links.py primitive is healthy (--self-test green) and the
#     deployed managed composition-surface tree carries no broken intra-sandbox
#     reference that the tool can resolve.
#
# WHY edit cleanup-protect-list.txt as the delta source: it is a `raw` (NON-token)
# composition-surface entry, so a one-line managed-content change forces a real
# regeneration WITHOUT confounding the durability assertion with token-
# substitution differences. update.sh regenerates a managed section only when
# the source-template SHA != the stored managed_sha (update.sh
# regenerate_managed_sections), so editing the source template in a sandboxed
# repo copy is the deterministic way to force a regen without depending on an
# actual future release.
#
# R-8 (HARD sandbox invariant): every install/update invocation runs under a
# redirected config-root + workspace-root into a `mktemp -d` sandbox; the
# operator's live ~/.claude/ is NEVER written. This test carries all three
# guards of the existing harness PER-TEST: (a) mktemp -d sandbox, (b)
# trap-cleanup on EXIT, (c) a sorted-file + per-file-hash manifest of the real
# $HOME/.claude/skills captured BEFORE and AFTER, asserted byte-identical (the
# belt-and-suspenders proof that no invocation escaped its sandbox — mirrors
# test_deploy_sandbox.sh Test B). update.sh's Phase 5 skill-redeploy is
# redirected into the sandbox because --workspace-root is passed explicitly
# (update.sh exports PMO_PLATFORM_DEPLOY_ROOT from --workspace-root, #611 R-A).
#
# LIMITATION (AC-b2, routed to a sibling issue per the Stage 5 spec): the only
# deployed *.md file is the operator-workspace CLAUDE.md, whose cross-refs are
# RELATIVE TO A REAL OPERATOR WORKSPACE LAYOUT (a sibling pmo-platform/ clone),
# not resolvable inside an isolated /tmp sandbox; and check-doc-links.py resolves
# refs against its OWN repo root (WORKSPACE_ROOT = parents[3] of __file__), not
# the sandbox. So a literal "zero broken refs over the deployed CLAUDE.md"
# assertion would fail on environment-relative refs that are correct in a real
# install. The deployed-tree link integrity of the operator CLAUDE.md is covered
# by the repo's own link gates against the real tree; here we assert the
# primitive is healthy and the deployed MANAGED surface (the allowlists, which
# carry no markdown links) is link-clean by construction.
#
# Run from repo root (resolves repo root from its own location):
#   bash core/deploy/tests/test_upgrade_config_durability.sh
#
# Platform: Darwin-only (setup-workspace.sh's check_platform hard-fails
# elsewhere). On Linux/WSL this prints SKIP and exits 0.
#
# Returns non-zero on any failure.

set -uo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'SKIP: test_upgrade_config_durability.sh — setup-workspace.sh is Darwin-only\n'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
DOC_LINKS="${REPO_ROOT}/core/deploy/tools/check-doc-links.py"

# The managed-section SOURCE TEMPLATE whose SHA we perturb to force a regen.
# `raw` tier (no token substitution) → a managed-content edit is a clean
# regeneration trigger with no token noise.
DELTA_SOURCE_REL="core/config/allowlists/cleanup-protect-list.txt"
# Its deployed target basename (hook tier → ~/Claude/.claude/<basename>).
DELTA_TARGET_BASENAME="cleanup-protect-list.txt"
# The composition-surface file we inject the operator addition into. Its
# OPERATOR ADDITIONS fence is asserted present by test_install_end_to_end.sh.
ADDITION_TARGET_BASENAME="egress-allowlist.txt"
# A deliberately invalid sentinel (RFC-2606 .invalid TLD) so it can never be a
# live egress entry; uniquely greppable.
SENTINEL="example.c8-operator-addition-durability-probe.invalid"

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

# Portable per-file hash (macOS `md5 -q`, Linux `md5sum`). Mirrors
# test_deploy_sandbox.sh's hash_file so the safety proof is identical.
hash_file() {
  if command -v md5 >/dev/null 2>&1; then
    md5 -q "$1" 2>/dev/null
  else
    md5sum "$1" 2>/dev/null | awk '{print $1}'
  fi
}

# Manifest of a directory: sorted "relpath  hash" lines. Empty (exit 0) if the
# directory does not exist, so a machine with no live ~/.claude/skills still
# gets a stable before/after comparison.
manifest_dir() {
  local root="$1"
  [ -d "${root}" ] || return 0
  local f
  while IFS= read -r f; do
    printf '%s  %s\n' "${f#"${root}"/}" "$(hash_file "${f}")"
  done < <(find "${root}" -type f 2>/dev/null | LC_ALL=C sort)
}

# --- Preflight ---
if [ ! -f "${SETUP}" ]; then
  printf 'FAIL: setup-workspace.sh not found at %s\n' "${SETUP}"
  exit 1
fi
if [ ! -f "${REPO_ROOT}/${DELTA_SOURCE_REL}" ]; then
  printf 'FAIL: delta source template missing: %s\n' "${DELTA_SOURCE_REL}"
  exit 1
fi

SBX=$(mktemp -d -t upgrade-durability.XXXXXX)
mkdir -p "${SBX}/config" "${SBX}/ws" "${SBX}/home"

# R-8 guard (c): capture the live-~ skills manifest BEFORE any invocation.
LIVE_SKILLS="${HOME}/.claude/skills"
LIVE_BEFORE=$(manifest_dir "${LIVE_SKILLS}")

# --- Pre-seed operator.toml so setup-workspace.sh prompts skip (identical to
#     test_install_end_to_end.sh). ---
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

# --- Stage 1: fresh sandbox install ---
printf '\nStage 1: fresh sandbox install (setup-workspace.sh, real)\n'
install_log=$("${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/ws" \
  --config-root "${SBX}/config" \
  < <(yes "") 2>&1)
install_exit=$?

if [ "${install_exit}" -eq 0 ]; then
  report "fresh install exits 0" 1
else
  tail_log=$(printf '%s' "${install_log}" | tail -5 | tr '\n' '|')
  report "fresh install exits 0" 0 "exit ${install_exit}; last lines: ${tail_log}"
fi

state_file="${SBX}/ws/.claude/.workspace-setup.state"
verification_passed=$(jq -r '.verification_passed // false' "${state_file}" 2>/dev/null)
if [ "${verification_passed}" = "true" ]; then
  report "install verification_passed=true" 1
else
  report "install verification_passed=true" 0 "actual: ${verification_passed}"
fi

ADDITION_TARGET="${SBX}/ws/.claude/${ADDITION_TARGET_BASENAME}"
DELTA_TARGET="${SBX}/ws/.claude/${DELTA_TARGET_BASENAME}"

if [ ! -f "${ADDITION_TARGET}" ]; then
  report "addition target deployed (${ADDITION_TARGET_BASENAME})" 0 "missing: ${ADDITION_TARGET}"
  # Without the target the rest is moot; print summary and bail.
  printf '\ntest_upgrade_config_durability.sh: %d passed, %d failed (bash %s)\n' \
    "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
  exit 1
else
  report "addition target deployed (${ADDITION_TARGET_BASENAME})" 1
fi

if [ ! -f "${DELTA_TARGET}" ]; then
  report "delta target deployed (${DELTA_TARGET_BASENAME})" 0 "missing: ${DELTA_TARGET}"
  printf '\ntest_upgrade_config_durability.sh: %d passed, %d failed (bash %s)\n' \
    "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
  exit 1
else
  report "delta target deployed (${DELTA_TARGET_BASENAME})" 1
fi

# --- Stage 2: inject an operator addition INSIDE the OPERATOR ADDITIONS fence ---
printf '\nStage 2: inject operator addition inside the OPERATOR ADDITIONS fence\n'
if ! grep -q "BEGIN OPERATOR ADDITIONS" "${ADDITION_TARGET}"; then
  report "OPERATOR ADDITIONS fence present in ${ADDITION_TARGET_BASENAME}" 0
  printf '\ntest_upgrade_config_durability.sh: %d passed, %d failed (bash %s)\n' \
    "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
  exit 1
fi
report "OPERATOR ADDITIONS fence present in ${ADDITION_TARGET_BASENAME}" 1

# Insert the sentinel on the line immediately after the BEGIN OPERATOR ADDITIONS
# marker (squarely inside the preserved fence).
awk -v s="${SENTINEL}" '
  /BEGIN OPERATOR ADDITIONS/ { print; print s; next }
  { print }
' "${ADDITION_TARGET}" > "${ADDITION_TARGET}.tmp" && mv "${ADDITION_TARGET}.tmp" "${ADDITION_TARGET}"

# Record the sentinel's full line context (number + content) so durability is a
# byte-for-byte, position-stable assertion — not merely "still present somewhere".
ADDITION_BEFORE=$(grep -nF "${SENTINEL}" "${ADDITION_TARGET}")
if [ -n "${ADDITION_BEFORE}" ]; then
  report "operator addition injected inside fence" 1
else
  report "operator addition injected inside fence" 0
fi

# --- Stage 3: build <sbx>/repo-next with an edited managed-section source ---
printf '\nStage 3: build sandboxed repo-next + perturb a managed-section source SHA\n'
REPONEXT="${SBX}/repo-next"
# Copy the repo into the sandbox. -R preserves the tree; the .git dir is copied
# too but update.sh does not read it (it derives REPO_ROOT from its own path).
cp -R "${REPO_ROOT}" "${REPONEXT}"
DELTA_MARKER="# c8-version-delta-probe: simulated managed-content change (do not ship)"
printf '\n%s\n' "${DELTA_MARKER}" >> "${REPONEXT}/${DELTA_SOURCE_REL}"
if tail -1 "${REPONEXT}/${DELTA_SOURCE_REL}" | grep -qF "c8-version-delta-probe"; then
  report "repo-next managed source perturbed" 1
else
  report "repo-next managed source perturbed" 0
fi

# --- Stage 4 (Suite G): non-dry-run update FROM repo-next → real regen ---
printf '\nStage 4 (Suite G): non-dry-run update from repo-next (real content delta)\n'
# update.sh has no --source-repo flag; it derives its REPO_ROOT from its own
# location (update.sh REPO_ROOT=dirname "$0"). Invoking the repo-next COPY's
# update.sh is therefore how the edited source templates become the regen
# source — equivalent to the spec's "--source-repo <sbx>/repo-next" intent.
upd_out=$(bash "${REPONEXT}/update.sh" \
  --config-root "${SBX}/config" \
  --workspace-root "${SBX}/ws" 2>&1)
upd_exit=$?

# Exit-code contract: a real regeneration returns EX_OK (0); a no-op returns
# EX_NOCHANGE (64). Suite G perturbed the source, so EX_OK is required.
if [ "${upd_exit}" -eq 0 ]; then
  report "real-delta update exits EX_OK (0) — regeneration occurred" 1
else
  tail_out=$(printf '%s' "${upd_out}" | tail -4 | tr '\n' '|')
  report "real-delta update exits EX_OK (0) — regeneration occurred" 0 "exit ${upd_exit}; ${tail_out}"
fi

# Phase 3 reports a non-zero regenerated count.
if printf '%s' "${upd_out}" | grep -qE 'Phase 3 complete: [0-9]+ files surveyed, [1-9][0-9]* regenerated'; then
  report "update reports >=1 managed section regenerated" 1
else
  p3=$(printf '%s' "${upd_out}" | grep -E 'Phase 3 complete' | head -1)
  report "update reports >=1 managed section regenerated" 0 "${p3}"
fi

# The deployed target now reflects the repo-next delta (regen actually landed).
if grep -qF "c8-version-delta-probe" "${DELTA_TARGET}"; then
  report "deployed managed section carries the repo-next delta" 1
else
  report "deployed managed section carries the repo-next delta" 0 \
    "delta marker not found in ${DELTA_TARGET}"
fi

# Suite G durability: the operator addition survives the regeneration
# BYTE-FOR-BYTE (same line number + same content as before the update).
ADDITION_AFTER_G=$(grep -nF "${SENTINEL}" "${ADDITION_TARGET}")
if [ "${ADDITION_BEFORE}" = "${ADDITION_AFTER_G}" ]; then
  report "operator addition preserved byte-for-byte across real-delta upgrade" 1
else
  report "operator addition preserved byte-for-byte across real-delta upgrade" 0 \
    "before=[${ADDITION_BEFORE}] after=[${ADDITION_AFTER_G}]"
fi

# --- Stage 5 (Suite F): non-dry-run NO-OP update (re-run from the SAME source) ---
printf '\nStage 5 (Suite F): non-dry-run no-op update (re-run from repo-next)\n'
# A true no-op runs from the SAME source whose SHA is now stored as managed_sha
# — i.e. repo-next, which Stage 4 just regenerated against. Running from the
# ORIGINAL REPO_ROOT here would NOT be a no-op: its source SHA differs from the
# stored repo-next SHA, so update.sh would (correctly) regenerate again. The
# honest "nothing changed since the last update" case is a second run from
# repo-next → EX_NOCHANGE (64), addition intact.
noop_out=$(bash "${REPONEXT}/update.sh" \
  --config-root "${SBX}/config" \
  --workspace-root "${SBX}/ws" 2>&1)
noop_exit=$?

if [ "${noop_exit}" -eq 64 ]; then
  report "no-op update exits EX_NOCHANGE (64)" 1
else
  tail_out=$(printf '%s' "${noop_out}" | tail -4 | tr '\n' '|')
  report "no-op update exits EX_NOCHANGE (64)" 0 "exit ${noop_exit}; ${tail_out}"
fi

ADDITION_AFTER_F=$(grep -nF "${SENTINEL}" "${ADDITION_TARGET}")
if [ "${ADDITION_BEFORE}" = "${ADDITION_AFTER_F}" ]; then
  report "operator addition preserved byte-for-byte across no-op update" 1
else
  report "operator addition preserved byte-for-byte across no-op update" 0 \
    "before=[${ADDITION_BEFORE}] after=[${ADDITION_AFTER_F}]"
fi

# --- Stage 6 (AC-b2): deployed-tree link integrity (primitive health + managed
#     surface). See LIMITATION in the header for why this is scoped. ---
printf '\nStage 6 (AC-b2): deployed-tree link integrity\n'
if [ -f "${DOC_LINKS}" ]; then
  if python3 "${DOC_LINKS}" --self-test >/dev/null 2>&1; then
    report "check-doc-links.py primitive healthy (--self-test)" 1
  else
    report "check-doc-links.py primitive healthy (--self-test)" 0
  fi
else
  report "check-doc-links.py present" 0 "missing: ${DOC_LINKS}"
fi

# The deployed MANAGED composition surface (the *.txt allowlists) carries no
# markdown link sequence by construction — assert none of the deployed managed
# allowlists contains a markdown inline link. This is the portion of "deployed-
# tree link integrity" that IS resolvable inside an isolated sandbox; the
# operator-workspace CLAUDE.md's environment-relative refs are out of scope here
# (covered by the repo's own link gates — see header LIMITATION + sibling issue).
managed_md_links=$(grep -rlE '\]\([^)]+\)' "${SBX}/ws/.claude"/*.txt 2>/dev/null | wc -l | tr -d ' ')
if [ "${managed_md_links}" = "0" ]; then
  report "deployed managed allowlists carry no markdown links (link-clean by construction)" 1
else
  report "deployed managed allowlists carry no markdown links (link-clean by construction)" 0 \
    "${managed_md_links} allowlist file(s) unexpectedly contain a markdown link"
fi

# --- R-8 guard (c): live ~/.claude/skills UNCHANGED across all invocations ---
printf '\nR-8 safety proof: live ~/.claude/skills UNTOUCHED across all invocations\n'
LIVE_AFTER=$(manifest_dir "${LIVE_SKILLS}")
if [ "${LIVE_BEFORE}" = "${LIVE_AFTER}" ]; then
  report "live ~/.claude/skills byte-identical before/after (R-8 proof)" 1
else
  report "live ~/.claude/skills byte-identical before/after (R-8 proof)" 0 \
    "manifest drift detected under ${LIVE_SKILLS}"
fi

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_upgrade_config_durability.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0

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
#   Suite C (CLAUDE.md workspace-root composition surface, ADR-122):
#     the CUSTOMIZABLE-refresh mechanism. Asserts the workspace-root manifest
#     tier resolves <ws>/CLAUDE.md with the `.template` suffix stripped; the
#     deployed file carries the MARKDOWN marker dialect with a resolved
#     managed_sha and no unresolved [TOKEN]; a template delta regenerates it
#     (EX_OK 0) while an operator addition inside the fence survives
#     byte-for-byte; an unconditional PRE-write backup exists (not tamper-gated);
#     a no-delta re-run returns EX_NOCHANGE 64 (the dialect-aware marker-grep
#     arm — a `#`-pinned grep regenerates forever and never reaches 64); and the
#     workspace-root resolver honors flag > env > $HOME-default, with a
#     specificity arm proving the absent-target signal is reachable.
#     It runs its OWN update invocations and edits no assertion of Suite F/G/T.
#
#   Suite P (non-interactive install + operator.toml preservation, #1531):
#     a FRESH install completes with stdin closed and no pre-existing tokens
#     file, resolving every token from its declared default; a required token
#     with no available default fails non-zero naming the token and writes
#     nothing; and a fully-populated operator.toml survives a fresh + a
#     re-bootstrap round-trip with no table and no key dropped. Its four
#     non-redundant deltas over Suite T, and the four things it deliberately
#     does NOT assert, are stated inline at the suite (Stage 5b) — read that
#     block before adding an assertion to it.
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

[trackers.work]
id = "work"
platform = "jira"
identifier = "PROJ"
scope = "private"

[trackers.personal]
id = "personal"
platform = "github-issues"
identifier = "owner/public-repo"
scope = "public"
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
if grep -qF "c8-version-delta-probe" <<<"$(tail -1 "${REPONEXT}/${DELTA_SOURCE_REL}")"; then
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
if grep -qE 'Phase 3 complete: [0-9]+ files surveyed, [1-9][0-9]* regenerated' <<<"${upd_out}"; then
  report "update reports >=1 managed section regenerated" 1
else
  p3=$(grep -m1 -E 'Phase 3 complete' <<<"${upd_out}")
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

# --- Stage 4b (Suite T / INT-1): [trackers.<id>] subtable durability (#384) ---
# The load-bearing proof that Option B (named subtables) satisfies the #383 round-
# trip and Option A ([[trackers]] array-of-tables) would NOT: two DISTINCT
# [trackers.<id>] subtables seeded pre-install must survive the real-delta upgrade
# round-trip parseable + DISTINCT + field-complete (no collapse into one block, no
# dropped section, no merged keys).
printf '\nStage 4b (Suite T / INT-1): [trackers.<id>] subtable durability round-trip\n'
CFG_TOML="${SBX}/config/operator.toml"

# (a) exactly TWO distinct [trackers.<id>] section headers survived (Option A would
#     collapse both to a single [trackers] block → count 1 or 0).
tr_count=$(grep -cE '^\[trackers\.[^]]+\]' "${CFG_TOML}" 2>/dev/null | tr -d ' ')
if [ "${tr_count}" = "2" ]; then
  report "two distinct [trackers.<id>] subtables survived round-trip (Option B; not collapsed)" 1
else
  report "two distinct [trackers.<id>] subtables survived round-trip (Option B; not collapsed)" 0 \
    "expected 2 distinct [trackers.*] headers, found ${tr_count}"
fi

# (b) both named subtables present by name.
if grep -qE '^\[trackers\.work\]' "${CFG_TOML}" && grep -qE '^\[trackers\.personal\]' "${CFG_TOML}"; then
  report "both [trackers.work] and [trackers.personal] present after round-trip" 1
else
  report "both [trackers.work] and [trackers.personal] present after round-trip" 0 \
    "one or both subtable headers missing in ${CFG_TOML}"
fi

# (c) field-complete + DISTINCT values (parsed section-aware): work→jira/PROJ/private,
#     personal→github-issues/owner/public-repo/public. Distinct field values prove no
#     key-merge across the two blocks.
tr_parsed=$(awk '
  function unq(v){ gsub(/^[ \t]+|[ \t]+$/,"",v); gsub(/^"|"$/,"",v); return v }
  /^\[/ { intr=(/^\[trackers\.[^]]+\]/); if(intr){ sec=$0 } next }
  intr && /^[[:space:]]*platform[[:space:]]*=/   { split($0,a,"="); print sec "|platform="   unq(a[2]) }
  intr && /^[[:space:]]*identifier[[:space:]]*=/ { split($0,a,"="); print sec "|identifier=" unq(a[2]) }
  intr && /^[[:space:]]*scope[[:space:]]*=/      { split($0,a,"="); print sec "|scope="      unq(a[2]) }
' "${CFG_TOML}" 2>/dev/null)

check_field() { # desc  needle
  if grep -qF "$2" <<<"${tr_parsed}"; then
    report "$1" 1
  else
    report "$1" 0 "missing [$2] in parsed trackers: $(printf '%s' "${tr_parsed}" | tr '\n' ';')"
  fi
}
check_field "trackers.work field-complete (jira/PROJ/private)"                 "[trackers.work]|platform=jira"
check_field "trackers.work identifier survived"                               "[trackers.work]|identifier=PROJ"
check_field "trackers.work scope=private survived"                            "[trackers.work]|scope=private"
check_field "trackers.personal field-complete (github-issues/public)"         "[trackers.personal]|platform=github-issues"
check_field "trackers.personal identifier survived"                           "[trackers.personal]|identifier=owner/public-repo"
check_field "trackers.personal scope=public survived (distinct from work)"    "[trackers.personal]|scope=public"

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

# --- Stage 5b (Suite P): non-interactive install + operator.toml preservation ---
# Covers #1531 AC-1 / AC-2 / AC-3. Appended as a NEW named suite; Suites F, G and
# T above are not modified. Runs under the SAME ${SBX} and the SAME trap-cleanup
# EXIT, so the R-8 HARD sandbox invariant (and its live-~/.claude/skills manifest
# proof below) covers every invocation here too — deliberately NOT a second
# `mktemp -d`.
#
# WHY these four deltas and not a re-assertion of Suite T: [trackers.<id>]
# already traverses write_operator_toml's `prior_order` pass-through loop, which
# is the IDENTICAL code path [adapters] / [methodology] / [automation] traverse.
# "An unknown operator-added table survives" is therefore already covered. The
# four genuinely uncovered deltas are:
#   D1 value-TYPE fidelity  — every Suite T fixture value is a quoted string, so a
#                             refactor that re-quotes pass-through values would turn
#                             `false` into `"false"` and still pass Suite T.
#   D2 the passthrough() branch — operator-added keys inside a MANAGED section go
#                             through a DIFFERENT function than the prior_order
#                             loop, and had zero coverage.
#   D3 column-0 line-anchoring — five production consumers read operator.toml with a
#                             COLUMN-0 line-anchored key probe. Three of the five are
#                             still section-blind `grep -E '^key'`; the two autonomy-
#                             ceiling readers were hardened to section-AWARE in this
#                             release and deliberately KEPT the column-0 anchor (strict
#                             parity). COLUMN-0 anchoring — not section-blindness — is
#                             therefore the property all five still share, and the one
#                             P-7 rests on. Suite T's section-aware awk is whitespace-
#                             tolerant and would PASS on an indented re-emit that every
#                             one of those five would MISS — silently dropping the
#                             autonomy ceiling to its fallback. P-7 probes with the
#                             consumers' own shape so this suite fails IFF a consumer
#                             would. (See the fuller note at P-7 itself.)
#   D4 MANAGED-key durability — Suite T asserts only non-managed subtables.
#
# NEGATIVE SCOPE — deliberately NOT asserted. Do not "strengthen" this suite by
# adding any of these: each is shipped, documented, or separately routed behaviour,
# and asserting it would make a correct build red.
#   (a) Comments inside operator-added sections — write_operator_toml's own header
#       documents that inline comments are not retained (accepted residual).
#   (b) [[array-of-tables]] preservation — two [[trackers]] blocks verifiably merge
#       into one. This is WHY named [trackers.<id>] subtables (Option B) were chosen;
#       it is documented on purpose in operator.toml.template.
#   (c) Duplicate-section preservation — a section appearing twice merges. TOML-legal
#       outcome; accepted residual.
#   (d) Multi-line array preservation — `k = [` survives and its continuation lines
#       are dropped, producing invalid TOML. A real defect, but undocumented and
#       routed to its own next-release issue rather than fixed here.
printf '\nStage 5b (Suite P): non-interactive install + operator.toml preservation\n'

mkdir -p "${SBX}/gitcfg" \
         "${SBX}/ni-ws" "${SBX}/ni-config" \
         "${SBX}/nifail-ws" "${SBX}/nifail-config" \
         "${SBX}/pres-ws" "${SBX}/pres-config"

# Git-identity isolation is the lever for both non-interactive arms: a populated
# global config for the success arm, an EMPTY one for the failure arm (so
# [OPERATOR_NAME] genuinely has no default). GIT_CONFIG_GLOBAL requires git >= 2.32.
printf '[user]\n\tname = Test Operator\n\temail = test@example.com\n' > "${SBX}/gitcfg/ok"
: > "${SBX}/gitcfg/empty"

# Probe-validity precondition: prove the isolation lever actually works, with BOTH
# arms observed, before any assertion depends on it. Without this a silently
# ignored GIT_CONFIG_GLOBAL would make P-3 read the operator's REAL identity and
# turn a broken lever into a confusing failure rather than a named one.
gitcfg_ok_arm=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/ok" git config --global user.name 2>/dev/null || true)
gitcfg_empty_arm=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/empty" git config --global user.name 2>/dev/null || true)
if [ "${gitcfg_ok_arm}" = "Test Operator" ] && [ -z "${gitcfg_empty_arm}" ]; then
  report "P-0 GIT_CONFIG_GLOBAL isolation live (sensitivity + specificity arms both observed)" 1
else
  report "P-0 GIT_CONFIG_GLOBAL isolation live (sensitivity + specificity arms both observed)" 0 \
    "ok-arm='${gitcfg_ok_arm}' (expected 'Test Operator'); empty-arm='${gitcfg_empty_arm}' (expected empty); git >= 2.32 required"
fi

# Generalized "SECTION|key=rawvalue" extraction over EVERY table and key — Suite T's
# section-aware awk idiom widened from [trackers.*] to the whole file. Comment and
# blank lines are skipped (the generated header carries a timestamp comment that
# legitimately differs run to run). Output is sorted for comm(1).
extract_kv() {
  awk '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*\[/ { sec=trim($0); next }
    {
      eq=index($0,"=")
      if (eq==0) next
      k=trim(substr($0,1,eq-1))
      v=trim(substr($0,eq+1))
      if (k=="") next
      print sec "|" k "=" v
    }
  ' "$1" | LC_ALL=C sort
}

# --- P-1 (AC-1): fresh non-interactive install, stdin CLOSED, no tokens file ---
if [ ! -f "${SBX}/ni-config/operator.toml" ]; then
  report "P-1 precondition: no pre-existing operator.toml at the non-interactive config root" 1
else
  report "P-1 precondition: no pre-existing operator.toml at the non-interactive config root" 0 \
    "unexpected pre-existing ${SBX}/ni-config/operator.toml"
fi

ni_log=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/ok" "${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/ni-ws" \
  --config-root "${SBX}/ni-config" \
  --non-interactive 0<&- 2>&1)
ni_exit=$?

if [ "${ni_exit}" -eq 0 ]; then
  report "P-1 fresh --non-interactive install exits 0 with stdin closed" 1
else
  ni_tail=$(printf '%s' "${ni_log}" | tail -5 | tr '\n' '|')
  report "P-1 fresh --non-interactive install exits 0 with stdin closed" 0 "exit ${ni_exit}; ${ni_tail}"
fi

NI_TOML="${SBX}/ni-config/operator.toml"
if [ -f "${NI_TOML}" ]; then
  report "P-1 operator.toml written by the unattended run" 1
else
  report "P-1 operator.toml written by the unattended run" 0 "missing: ${NI_TOML}"
fi

ni_verified=$(jq -r '.verification_passed // false' "${SBX}/ni-ws/.claude/.workspace-setup.state" 2>/dev/null)
if [ "${ni_verified}" = "true" ]; then
  report "P-1 unattended install verification_passed=true" 1
else
  report "P-1 unattended install verification_passed=true" 0 "actual: ${ni_verified}"
fi

# --- P-2 (AC-1): fully resolved — no surviving markers AND no empty identity ---
# The two halves catch DIFFERENT failures and neither is redundant: the install's
# own verification gate rejects UNRESOLVED [TOKEN] markers only, and an EMPTY
# substitution leaves no marker behind — so a blank-identity install passes the
# gate. The non-empty half is the load-bearing new assertion.
NI_CLAUDE_MD="${SBX}/ni-ws/CLAUDE.md"
if [ -f "${NI_CLAUDE_MD}" ]; then
  ni_markers=$(grep -cE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${NI_CLAUDE_MD}" 2>/dev/null | tr -d ' ')
  # Sensitivity arm: the SOURCE template must match the same regex, proving the
  # probe can see a marker. A zero from a regex that matches nothing is a broken
  # probe, not a clean result.
  ni_marker_ctl=$(grep -cE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${REPO_ROOT}/core/CLAUDE.md.template" 2>/dev/null | tr -d ' ')
  if [ "${ni_markers}" = "0" ] && [ "${ni_marker_ctl}" != "0" ]; then
    report "P-2 rendered CLAUDE.md carries zero unresolved tokens (control: template matches ${ni_marker_ctl})" 1
  else
    report "P-2 rendered CLAUDE.md carries zero unresolved tokens (control: template matches ${ni_marker_ctl})" 0 \
      "rendered=${ni_markers} (expected 0); control=${ni_marker_ctl} (expected non-zero)"
  fi
else
  report "P-2 rendered CLAUDE.md present" 0 "missing: ${NI_CLAUDE_MD}"
fi

ni_empty_identity=$(grep -cE '^(operator_name|operator_email|operator_role_title|operator_organization) = ""$' "${NI_TOML}" 2>/dev/null | tr -d ' ')
ni_identity_present=$(grep -cE '^(operator_name|operator_email|operator_role_title|operator_organization) = ' "${NI_TOML}" 2>/dev/null | tr -d ' ')
if [ "${ni_empty_identity}" = "0" ] && [ "${ni_identity_present}" = "4" ]; then
  report "P-2 every required identity key resolved NON-empty (4 of 4 present, 0 empty)" 1
else
  report "P-2 every required identity key resolved NON-empty (4 of 4 present, 0 empty)" 0 \
    "empty=${ni_empty_identity} (expected 0); present=${ni_identity_present} (expected 4)"
fi

# P-2c (D4 — MANAGED-key durability on the FRESH path). Every managed [paths] key
# must land NON-EMPTY on an install that had no pre-existing operator.toml.
#
# This arm is NOT a duplicate of P-4 and P-4 structurally cannot replace it. A
# managed key is written from the token whose name write_operator_toml reads; if a
# resolver arm stores under a DIFFERENT token name than the writer reads, the key
# is emitted blank. P-4's populated fixture masks exactly that class of defect,
# because read_operator_toml back-fills the writer's token from the seeded file
# before the writer runs — so the round-trip looks clean while a fresh install is
# silently losing the value. Only the fresh path, with nothing to back-fill from,
# exposes it. That is the live defect this card fixes for
# [paths].cowork_install_path, and this is its regression guard.
ni_empty_paths=$(grep -cE '^(claude_workspace_root|operator_homedir_path|cowork_install_path|pmo_platform_repo_name) = ""$' "${NI_TOML}" 2>/dev/null | tr -d ' ')
ni_paths_present=$(grep -cE '^(claude_workspace_root|operator_homedir_path|cowork_install_path|pmo_platform_repo_name) = ' "${NI_TOML}" 2>/dev/null | tr -d ' ')
if [ "${ni_empty_paths}" = "0" ] && [ "${ni_paths_present}" = "4" ]; then
  report "P-2c every managed [paths] key NON-empty on a FRESH install (4 of 4 present, 0 empty)" 1
else
  report "P-2c every managed [paths] key NON-empty on a FRESH install (4 of 4 present, 0 empty)" 0 \
    "empty=${ni_empty_paths} (expected 0); present=${ni_paths_present} (expected 4) — a managed key was written blank, which means a resolver arm and write_operator_toml disagree on the token name"
fi

# --- P-3 (AC-2): required token with NO default fails loud, before any write ---
nifail_log=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/empty" "${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/nifail-ws" \
  --config-root "${SBX}/nifail-config" \
  --non-interactive 0<&- 2>&1)
nifail_exit=$?

if [ "${nifail_exit}" -ne 0 ]; then
  report "P-3 required token with no default exits NON-ZERO (does not hang, does not substitute)" 1
else
  report "P-3 required token with no default exits NON-ZERO (does not hang, does not substitute)" 0 \
    "exit 0 — an unattended install completed with no identity source"
fi

# The token name must appear on an ERROR line. Grepping the log for the bare
# token would be a BROKEN PROBE: the routine "Active token set:" INFO line lists
# every active token, so it matches whether or not the failure names one.
# Both conditions hold on the SAME line, so they fold into one grep over a
# here-string. An intervening filter stage is not a fix: `writer | grep -F … |
# grep -q` still ends in a reader that closes the pipe on its first match, and
# the surviving producer takes the broken pipe just as `printf` did.
if grep -qE '^ERROR:.*\[OPERATOR_NAME\]' <<<"${nifail_log}"; then
  nifail_named=1
else
  nifail_named=0
fi
# Specificity arm: the SUCCESSFUL P-1 log must NOT satisfy the same predicate.
if grep -qE '^ERROR:.*\[OPERATOR_NAME\]' <<<"${ni_log}"; then
  nifail_ctl=1
else
  nifail_ctl=0
fi
if [ "${nifail_named}" = "1" ] && [ "${nifail_ctl}" = "0" ]; then
  report "P-3 failure names [OPERATOR_NAME] on an ERROR line (specificity: success log does not)" 1
else
  report "P-3 failure names [OPERATOR_NAME] on an ERROR line (specificity: success log does not)" 0 \
    "fail-arm=${nifail_named} (expected 1); success-arm=${nifail_ctl} (expected 0)"
fi

if [ ! -f "${SBX}/nifail-config/operator.toml" ]; then
  report "P-3 fail-before-write: no operator.toml written on the failing run" 1
else
  report "P-3 fail-before-write: no operator.toml written on the failing run" 0 \
    "an operator.toml was written despite the abort"
fi

# --- P-4 / P-5 / P-6 / P-7 (AC-3, D1-D4): preservation over a populated fixture ---
# Every managed key is seeded NON-EMPTY (read_operator_toml skips empty values, so
# an empty seed could not distinguish "preserved" from "never read"). Managed
# claude_workspace_root / operator_homedir_path are seeded to the values the
# installer itself derives, so a difference there would be a real drop rather than
# an expected re-derivation.
PRES_TOML="${SBX}/pres-config/operator.toml"
cat > "${PRES_TOML}" <<TOML
[meta]
schema_version = 1
managed_by = "pmo-platform"

[identity]
operator_name = "Preservation Operator"
operator_email = "pres@example.com"
operator_git_email = "pres-git@example.com"
operator_github = "pres-handle"
operator_phone = "555-0100"
operator_role_title = "Preservation Role"
operator_organization = "Preservation Org"
operator_custom_key = "keep-me"

[paths]
claude_workspace_root = "${SBX}/pres-ws"
operator_homedir_path = "${HOME}"
cowork_install_path = "/tmp/pres-cowork"
pmo_platform_repo_name = "pmo-platform"
operator_instance_evals_results_path = "/tmp/pres-evals"
operator_instance_roadmaps_path = "/tmp/pres-roadmaps"

[platform]
work_board = "github"
comms_platform = "teams"

[adapters]
doc_system = "confluence"
plan_system = "jira"

[methodology]
delivery_approach = "Scrum"

[automation]
automation_level = "bounded_auto"

[session_retro]
enabled = false
min_tool_calls = 12
custom_array = ["a", "b"]

[zz_operator_unknown]
some_string = "kept"
some_int = 7
some_inline_array = ["x", "y"]
TOML
chmod 600 "${PRES_TOML}"

extract_kv "${PRES_TOML}" > "${SBX}/pres-before.kv"
grep -E '^\[' "${PRES_TOML}" | LC_ALL=C sort > "${SBX}/pres-before.tables"

# Run 1 = fresh install; Run 2 = re-bootstrap. Both non-interactive, stdin closed.
# The two runs exercise DIFFERENT flows (fresh_install vs rebootstrap), and both
# route through resolve_all_tokens -> write_operator_toml.
pres_log1=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/ok" "${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/pres-ws" \
  --config-root "${SBX}/pres-config" \
  --non-interactive 0<&- 2>&1)
pres_exit1=$?
pres_log2=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/ok" "${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/pres-ws" \
  --config-root "${SBX}/pres-config" \
  --non-interactive 0<&- 2>&1)
pres_exit2=$?

if [ "${pres_exit1}" -eq 0 ] && [ "${pres_exit2}" -eq 0 ]; then
  report "P-4 fresh + re-bootstrap runs both exit 0 over a populated operator.toml" 1
else
  pres_tail=$(printf '%s' "${pres_log2}" | tail -4 | tr '\n' '|')
  report "P-4 fresh + re-bootstrap runs both exit 0 over a populated operator.toml" 0 \
    "run1 exit ${pres_exit1}; run2 exit ${pres_exit2}; ${pres_tail}"
fi

if grep -q 'RE-BOOTSTRAP flow' <<<"${pres_log2}"; then
  report "P-4 second run took the RE-BOOTSTRAP branch (both write paths exercised)" 1
else
  report "P-4 second run took the RE-BOOTSTRAP branch (both write paths exercised)" 0 \
    "run 2 did not report the re-bootstrap flow"
fi

extract_kv "${PRES_TOML}" > "${SBX}/pres-after.kv"
grep -E '^\[' "${PRES_TOML}" | LC_ALL=C sort > "${SBX}/pres-after.tables"

# P-4: no key dropped. comm -23 = present before, absent after.
pres_dropped=$(comm -23 "${SBX}/pres-before.kv" "${SBX}/pres-after.kv")
pres_before_n=$(wc -l < "${SBX}/pres-before.kv" | tr -d ' ')
if [ -z "${pres_dropped}" ] && [ "${pres_before_n}" -gt 0 ]; then
  report "P-4 zero keys dropped across the round-trip (denominator ${pres_before_n} section/key pairs)" 1
else
  report "P-4 zero keys dropped across the round-trip (denominator ${pres_before_n} section/key pairs)" 0 \
    "dropped: $(printf '%s' "${pres_dropped}" | tr '\n' ';') (denominator ${pres_before_n})"
fi

# P-5: table-set equality.
if diff -q "${SBX}/pres-before.tables" "${SBX}/pres-after.tables" >/dev/null 2>&1; then
  report "P-5 table set identical before/after ($(wc -l < "${SBX}/pres-before.tables" | tr -d ' ') tables)" 1
else
  report "P-5 table set identical before/after" 0 \
    "$(diff "${SBX}/pres-before.tables" "${SBX}/pres-after.tables" | tr '\n' ';')"
fi

# P-6 (D1): value-TYPE fidelity, exact and UNQUOTED. A pass-through refactor that
# re-quoted values would turn `false` into `"false"` and `12` into `"12"` while an
# all-string fixture still passed.
p6_fail=""
for p6_expect in 'enabled = false' 'min_tool_calls = 12' 'custom_array = ["a", "b"]' 'some_int = 7'; do
  p6_n=$(grep -Fxc "${p6_expect}" "${PRES_TOML}" 2>/dev/null | tr -d ' ')
  [ "${p6_n}" = "1" ] || p6_fail="${p6_fail} [${p6_expect} -> ${p6_n}]"
done
if [ -z "${p6_fail}" ]; then
  report "P-6 non-string TOML scalars round-trip UNQUOTED (bool, int, inline array; 4 of 4)" 1
else
  report "P-6 non-string TOML scalars round-trip UNQUOTED (bool, int, inline array; 4 of 4)" 0 \
    "expected exactly 1 exact-line match each; got:${p6_fail}"
fi

# P-7 (D3): probe with the CONSUMERS' own shape — COLUMN-0 LINE-ANCHORED. Five
# production readers resolve operator.toml with a column-0 key anchor. Exactly 1 is the
# contract: 0 means the key moved off column 0 or was dropped (the consumer silently
# falls back), >1 means an ambiguous resolution.
#
# The two autonomy-ceiling readers (block-autonomy-ceiling.sh,
# prime-autonomy-ceiling-cache.sh) were ALSO section-blind when this probe was written
# and are now section-AWARE. That hardening deliberately preserved the column-0 anchor —
# strict parity — precisely so this probe's premise stays true of them; only their
# out-of-section behaviour changed, which this probe does not exercise. The remaining
# three readers are still section-blind, so "column-0" rather than "section-blind" is
# the property this probe actually rests on, and the one to keep true.
#
# SCOPE: the subject is the SEEDED preservation fixture below, not a stock install. On a
# stock install the count is legitimately 0 (write_operator_toml emits no [automation]
# table), which is why this asserts against a fixture that seeds the key at column 0
# rather than against a live operator.toml.
p7_fail=""
for p7_key in automation_level operator_github pmo_platform_repo_name operator_instance_evals_results_path; do
  p7_n=$(grep -c "^${p7_key}" "${PRES_TOML}" 2>/dev/null | tr -d ' ')
  [ "${p7_n}" = "1" ] || p7_fail="${p7_fail} [${p7_key} -> ${p7_n}]"
done
# Specificity arm: a key that does not exist must return 0 under the same probe.
p7_ctl=$(grep -c '^zzz_key_that_does_not_exist' "${PRES_TOML}" 2>/dev/null | tr -d ' ')
if [ -z "${p7_fail}" ] && [ "${p7_ctl}" = "0" ]; then
  report "P-7 consumer-shape probe: 4 of 4 consumer-read keys resolve exactly once at column 0 (specificity arm 0)" 1
else
  report "P-7 consumer-shape probe: 4 of 4 consumer-read keys resolve exactly once at column 0 (specificity arm 0)" 0 \
    "misses:${p7_fail:- none}; specificity arm=${p7_ctl} (expected 0)"
fi

# --- P-8 (probe validity): the assertions above must be PROVABLY able to fail ---
# Mirrors the install-tests precision-probe idiom. Two mutations, one per probe,
# because the two probes catch different things: extract_kv trims leading
# whitespace by design (it is a set comparator), so an INDENTED key is invisible to
# P-4 and visible only to P-7's column-0 shape. That is exactly why D3 needs its
# own probe rather than being folded into the set comparison.
PRES_MUT="${SBX}/pres-mutated.toml"
awk '
  /^\[adapters\]/ { drop=1; next }
  /^\[/           { drop=0 }
  drop            { next }
  { print }
' "${PRES_TOML}" > "${PRES_MUT}"
sed -i.bak 's/^automation_level/  automation_level/' "${PRES_MUT}" && rm -f "${PRES_MUT}.bak"

extract_kv "${PRES_MUT}" > "${SBX}/pres-mutated.kv"
mut_dropped=$(comm -23 "${SBX}/pres-after.kv" "${SBX}/pres-mutated.kv")
if [ -n "${mut_dropped}" ]; then
  report "P-8 negative control (a): the P-4 comparator DOES report a dropped table" 1
else
  report "P-8 negative control (a): the P-4 comparator DOES report a dropped table" 0 \
    "comparator returned empty against a copy with [adapters] deleted — BROKEN PROBE"
fi

mut_anchor=$(grep -c '^automation_level' "${PRES_MUT}" 2>/dev/null | tr -d ' ')
# Mutation-applied precondition (the P-0 idiom, applied to the control itself): an
# ABSENT key also yields 0 at column 0, so `mut_anchor == 0` alone passes vacuously
# on an empty subject — including the exact key-drop P-7 exists to catch. Prove the
# sed bit before drawing the conclusion: the key must now be present INDENTED.
mut_indented=$(grep -c '^[[:space:]][[:space:]]*automation_level' "${PRES_MUT}" 2>/dev/null | tr -d ' ')
if [ "${mut_anchor}" = "0" ] && [ "${mut_indented}" -ge 1 ]; then
  report "P-8 negative control (b): the P-7 column-0 probe DOES report an indented key (mutation applied: ${mut_indented} indented)" 1
else
  report "P-8 negative control (b): the P-7 column-0 probe DOES report an indented key" 0 \
    "expected column-0 count 0 WITH the key present indented; got column-0=${mut_anchor}, indented=${mut_indented} — BROKEN PROBE (indented=0 means the mutation never applied)"
fi

# --- Stage 5c (Suite C): CLAUDE.md workspace-root composition surface (ADR-122) ---
# The CUSTOMIZABLE-refresh mechanism. Mirrors Suite G's <sbx>/repo-next
# SHA-perturbation mechanics verbatim, against a different manifest row: the
# workspace-root tier, the markdown marker dialect, and the operator's top-level
# governance file as the target.
#
# Runs its OWN update invocations rather than folding into Stage 3/4, so Suites
# F, G, and T are untouched (Stage-4 test-file contention constraint).
printf '\nStage 5c (Suite C): CLAUDE.md workspace-root composition surface (ADR-122)\n'

CLAUDE_TARGET="${SBX}/ws/CLAUDE.md"
CLAUDE_SOURCE_REL="core/CLAUDE.md.template"
CLAUDE_SENTINEL="c3831-claude-md-operator-addition-durability-probe"

# C-1: the workspace-root tier resolved to <ws>/CLAUDE.md, with the `.template`
#      suffix STRIPPED. The negative limb is the specificity arm: a tier that
#      failed to strip would have written <ws>/CLAUDE.md.template instead, and a
#      presence-only check could not tell the two apart.
if [ -f "${CLAUDE_TARGET}" ]; then
  report "C-1a workspace-root tier deployed <ws>/CLAUDE.md" 1
else
  report "C-1a workspace-root tier deployed <ws>/CLAUDE.md" 0 "missing: ${CLAUDE_TARGET}"
fi
if [ ! -e "${SBX}/ws/CLAUDE.md.template" ]; then
  report "C-1b .template suffix stripped (no <ws>/CLAUDE.md.template)" 1
else
  report "C-1b .template suffix stripped (no <ws>/CLAUDE.md.template)" 0 \
    "unstripped target present — resolver did not strip .template"
fi

if [ ! -f "${CLAUDE_TARGET}" ]; then
  printf '  (Suite C cannot continue without the deployed target)\n'
else

# C-2: the fence is the MARKDOWN dialect, not the plain one. A plain-dialect
#      fence in a markdown governance file renders as visible `# ===` noise AND
#      is what update.sh's pre-ADR-122 `#`-pinned grep expected — so asserting
#      the markdown form is what makes C-8 below meaningful.
c2_pass=1
c2_detail=""
for needle in \
  "<!-- === BEGIN MANAGED SECTION (regenerated by update.sh; do not edit) === -->" \
  "<!-- === END MANAGED SECTION === -->" \
  "<!-- === BEGIN OPERATOR ADDITIONS (preserved across updates) === -->" \
  "<!-- === END OPERATOR ADDITIONS === -->" ; do
  if ! grep -qF "${needle}" "${CLAUDE_TARGET}"; then
    c2_pass=0
    c2_detail="missing markdown fence line: ${needle}"
  fi
done
if grep -qE '^# === BEGIN MANAGED SECTION' "${CLAUDE_TARGET}"; then
  c2_pass=0
  c2_detail="plain-dialect fence leaked into the markdown target"
fi
report "C-2 deployed CLAUDE.md carries the markdown marker dialect" "${c2_pass}" "${c2_detail}"

# C-2b: markdown marker LINES (not just fences), with field 3 = the hex digest —
#       the field index update.sh's awk depends on for both dialects.
c2b_sha=$(grep -m1 -E '^<!-- managed_sha:' "${CLAUDE_TARGET}" | awk '{print $3}')
if grep -qE '^[0-9a-f]{64}$' <<<"${c2b_sha}"; then
  report "C-2b managed_sha marker is markdown-form with a resolved 64-hex digest" 1
else
  report "C-2b managed_sha marker is markdown-form with a resolved 64-hex digest" 0 \
    "awk field 3 of the managed_sha line = [${c2b_sha}]"
fi

# C-3: no unresolved token survived into the composed governance file. This is
#      the same predicate setup-workspace.sh's own verification gate applies; a
#      failure here is the token-coverage blocker the design named.
c3_unresolved=$(grep -oE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${CLAUDE_TARGET}" 2>/dev/null | sort -u | tr '\n' ' ')
if [ -z "${c3_unresolved}" ]; then
  report "C-3 composed CLAUDE.md carries no unresolved [TOKEN]" 1
else
  report "C-3 composed CLAUDE.md carries no unresolved [TOKEN]" 0 \
    "unresolved: ${c3_unresolved}"
fi
# C-3b sensitivity control: the probe CAN see a token. Without this arm a
#      silently-broken grep would report the same clean zero as a correct file.
c3b_seen=$(printf '[OPERATOR_PROJECT_NAME] x\n' | grep -coE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]')
if [ "${c3b_seen}" = "1" ]; then
  report "C-3b sensitivity control: the unresolved-token probe detects a seeded token" 1
else
  report "C-3b sensitivity control: the unresolved-token probe detects a seeded token" 0 \
    "control returned ${c3b_seen}, expected 1 — BROKEN PROBE, C-3's zero is meaningless"
fi

# C-4: inject an operator addition INSIDE the OPERATOR ADDITIONS fence, perturb
#      the CLAUDE.md source template in repo-next, and run a real update.
awk -v s="${CLAUDE_SENTINEL}" '
  /BEGIN OPERATOR ADDITIONS/ { print; print s; next }
  { print }
' "${CLAUDE_TARGET}" > "${CLAUDE_TARGET}.tmp" && mv "${CLAUDE_TARGET}.tmp" "${CLAUDE_TARGET}"

# Slice the additions region with an INDEPENDENT awk extractor rather than
# compose.py's own `extract` subcommand: verifying the writer's preservation with
# the writer's own reader would be circular — a matched pair of bugs would pass.
#
# The comparison is on the additions-section CONTENT plus the sentinel's offset
# WITHIN the fence, not on its absolute line number. Suite G can assert an
# absolute line number because its delta file and its addition file are
# different; here they are the SAME file, so a template delta legitimately grows
# the managed body and shifts the additions section down. An absolute-line
# assertion would fail on correct behavior.
extract_additions_block() {
  awk '
    /BEGIN OPERATOR ADDITIONS/ { f=1; next }
    /END OPERATOR ADDITIONS/   { f=0 }
    f
  ' "$1"
}
offset_in_fence() {
  # Snapshot the producer before the bounded reader sees it. `grep -m1` closes
  # its input on the first match exactly as `head -1` did, so with a live
  # producer upstream the `| head -N` -> `-mN` rewrite relocates the SIGPIPE
  # hazard rather than removing it. A here-string has no writer to signal.
  local _fence_block
  _fence_block="$(extract_additions_block "$1")"
  grep -m1 -nF "${CLAUDE_SENTINEL}" <<<"$_fence_block" | cut -d: -f1
}

CLAUDE_ADDITIONS_BEFORE=$(extract_additions_block "${CLAUDE_TARGET}")
CLAUDE_OFFSET_BEFORE=$(offset_in_fence "${CLAUDE_TARGET}")
if grep -qF "${CLAUDE_SENTINEL}" <<<"${CLAUDE_ADDITIONS_BEFORE}"; then
  report "C-4a operator addition injected inside CLAUDE.md additions fence" 1
else
  report "C-4a operator addition injected inside CLAUDE.md additions fence" 0
fi

CLAUDE_DELTA_MARKER="<!-- c3831-claude-md-version-delta-probe: simulated template change (do not ship) -->"
printf '\n%s\n' "${CLAUDE_DELTA_MARKER}" >> "${REPONEXT}/${CLAUDE_SOURCE_REL}"

cupd_out=$(bash "${REPONEXT}/update.sh" \
  --config-root "${SBX}/config" \
  --workspace-root "${SBX}/ws" 2>&1)
cupd_exit=$?

if [ "${cupd_exit}" -eq 0 ]; then
  report "C-4b CLAUDE.md template delta → update exits EX_OK (0), not EX_NOCHANGE (64)" 1
else
  report "C-4b CLAUDE.md template delta → update exits EX_OK (0), not EX_NOCHANGE (64)" 0 \
    "exit ${cupd_exit}; $(printf '%s' "${cupd_out}" | tail -4 | tr '\n' '|')"
fi

# C-5: the regeneration actually landed in the operator's file.
if grep -qF "c3831-claude-md-version-delta-probe" "${CLAUDE_TARGET}"; then
  report "C-5 deployed CLAUDE.md carries the repo-next template delta" 1
else
  report "C-5 deployed CLAUDE.md carries the repo-next template delta" 0 \
    "delta marker not found in ${CLAUDE_TARGET}"
fi

# C-6: the operator addition survived BYTE-FOR-BYTE. Two limbs: the whole
#      additions-section content is byte-identical, AND the sentinel sits at the
#      same offset within the fence (so preservation is position-stable, not
#      merely "the string is still somewhere in the file").
CLAUDE_ADDITIONS_AFTER=$(extract_additions_block "${CLAUDE_TARGET}")
CLAUDE_OFFSET_AFTER=$(offset_in_fence "${CLAUDE_TARGET}")
if [ "${CLAUDE_ADDITIONS_BEFORE}" = "${CLAUDE_ADDITIONS_AFTER}" ]; then
  report "C-6a operator additions section byte-identical across CLAUDE.md regeneration" 1
else
  report "C-6a operator additions section byte-identical across CLAUDE.md regeneration" 0 \
    "before=[${CLAUDE_ADDITIONS_BEFORE}] after=[${CLAUDE_ADDITIONS_AFTER}]"
fi
if [ -n "${CLAUDE_OFFSET_BEFORE}" ] && [ "${CLAUDE_OFFSET_BEFORE}" = "${CLAUDE_OFFSET_AFTER}" ]; then
  report "C-6b addition holds its position within the fence (offset ${CLAUDE_OFFSET_BEFORE})" 1
else
  report "C-6b addition holds its position within the fence" 0 \
    "offset before=[${CLAUDE_OFFSET_BEFORE}] after=[${CLAUDE_OFFSET_AFTER}]"
fi
# C-6c: the managed body DID move (the delta grew it), so C-6a is proving
#       preservation across a real rewrite rather than across a no-op. Without
#       this arm, C-6a would also pass if nothing had been regenerated at all.
c6c_line_after=$(grep -m1 -nF "${CLAUDE_SENTINEL}" "${CLAUDE_TARGET}" | cut -d: -f1)
if [ -n "${c6c_line_after}" ] && [ "${c6c_line_after}" -gt "${CLAUDE_OFFSET_AFTER}" ]; then
  report "C-6c sensitivity control: the managed body precedes the fence and was rewritten" 1
else
  report "C-6c sensitivity control: the managed body precedes the fence and was rewritten" 0 \
    "absolute line ${c6c_line_after} vs in-fence offset ${CLAUDE_OFFSET_AFTER}"
fi

# C-7: the unconditional pre-write backup (ADR-122 §Decision 7). No installed
#      CLAUDE.md has ever carried an installed_sha marker, so the tamper-backup
#      path cannot fire on a first rewrite; this asserts the recovery copy the
#      EXPENSIVE-reversibility write depends on exists REGARDLESS.
c7_backup=$(find "${SBX}/ws" -maxdepth 2 -path '*/.backup-pre-update-*/CLAUDE.md' 2>/dev/null | head -1)
if [ -n "${c7_backup}" ] && [ -f "${c7_backup}" ]; then
  report "C-7a pre-write backup of CLAUDE.md exists (unconditional, not tamper-gated)" 1
else
  report "C-7a pre-write backup of CLAUDE.md exists (unconditional, not tamper-gated)" 0 \
    "no .backup-pre-update-*/CLAUDE.md under ${SBX}/ws"
fi
# The backup must be the PRE-regeneration content: it must NOT carry the delta.
if [ -n "${c7_backup}" ] && ! grep -qF "c3831-claude-md-version-delta-probe" "${c7_backup}"; then
  report "C-7b backup captured the PRE-regeneration content (no delta marker)" 1
else
  report "C-7b backup captured the PRE-regeneration content (no delta marker)" 0 \
    "backup already contains the delta — it was taken AFTER the write, not before"
fi

# C-8: THE DIALECT-AWARENESS ARM. Re-run with no further source change. The
#      marker greps in update.sh must PARSE the markdown managed_sha line and
#      find it equal to the source SHA, yielding EX_NOCHANGE (64). A `#`-pinned
#      grep returns empty against this target, so stored != source on EVERY run
#      and the file regenerates forever — EX_NOCHANGE becomes unreachable. This
#      arm is what fails on a dialect-blind parse; C-4b alone does not.
cnoop_out=$(bash "${REPONEXT}/update.sh" \
  --config-root "${SBX}/config" \
  --workspace-root "${SBX}/ws" 2>&1)
cnoop_exit=$?
if [ "${cnoop_exit}" -eq 64 ]; then
  report "C-8a re-run with no delta exits EX_NOCHANGE (64) — markdown managed_sha parsed" 1
else
  report "C-8a re-run with no delta exits EX_NOCHANGE (64) — markdown managed_sha parsed" 0 \
    "exit ${cnoop_exit}; $(grep -m1 -E 'Phase 3 complete' <<<"${cnoop_out}")"
fi
if grep -qE 'Phase 3 complete: [0-9]+ files surveyed, 0 regenerated' <<<"${cnoop_out}"; then
  report "C-8b no-delta re-run regenerates 0 files (no perpetual-regen loop)" 1
else
  report "C-8b no-delta re-run regenerates 0 files (no perpetual-regen loop)" 0 \
    "$(grep -m1 -E 'Phase 3 complete' <<<"${cnoop_out}")"
fi

# C-9: workspace-root resolver precedence — flag > env var > $HOME default.
#      Observable signal: update.sh reports "Target absent (CLAUDE.md)" when the
#      resolved root holds no CLAUDE.md, and a would-regenerate / unchanged line
#      when it does. Run under --dry-run so no arm writes anything.
resolves_claude_md() {
  # Echoes 1 when the run resolved a PRESENT CLAUDE.md, 0 when it reported the
  # target absent. Reads the survey line rather than the exit code, because the
  # exit code aggregates every manifest row.
  local out="$1"
  if grep -qE 'Target absent \(CLAUDE\.md\)' <<<"${out}"; then
    printf '0'
  else
    printf '1'
  fi
}

c9a_out=$(bash "${REPONEXT}/update.sh" --dry-run \
  --config-root "${SBX}/config" --workspace-root "${SBX}/ws" 2>&1)
report "C-9a --workspace-root flag resolves <ws>/CLAUDE.md" \
  "$(resolves_claude_md "${c9a_out}")" "flag arm reported target absent"

c9b_out=$(PMO_PLATFORM_WORKSPACE_ROOT="${SBX}/ws" bash "${REPONEXT}/update.sh" --dry-run \
  --config-root "${SBX}/config" 2>&1)
report "C-9b PMO_PLATFORM_WORKSPACE_ROOT env resolves <ws>/CLAUDE.md (no flag)" \
  "$(resolves_claude_md "${c9b_out}")" "env arm reported target absent"

# HOME-default arm. HOME is redirected INTO the sandbox (R-8), so the real
# ~/.claude is never a candidate; the before/after manifest at the end of this
# file is the proof.
mkdir -p "${SBX}/homedef/Claude"
cp "${CLAUDE_TARGET}" "${SBX}/homedef/Claude/CLAUDE.md"
c9c_out=$(env -u PMO_PLATFORM_WORKSPACE_ROOT HOME="${SBX}/homedef" \
  bash "${REPONEXT}/update.sh" --dry-run --config-root "${SBX}/config" 2>&1)
report "C-9c \$HOME/Claude default resolves <home>/Claude/CLAUDE.md (no flag, no env)" \
  "$(resolves_claude_md "${c9c_out}")" "HOME-default arm reported target absent"

# C-9d SPECIFICITY ARM: point the flag at a root with NO CLAUDE.md. The probe
#      MUST report absent. Without this, C-9a/b/c could all be passing because
#      the "Target absent" string never appears for any reason — a probe whose
#      negative case is unreachable proves nothing about its positive cases.
mkdir -p "${SBX}/emptyroot"
c9d_out=$(bash "${REPONEXT}/update.sh" --dry-run \
  --config-root "${SBX}/config" --workspace-root "${SBX}/emptyroot" 2>&1)
if [ "$(resolves_claude_md "${c9d_out}")" = "0" ]; then
  report "C-9d specificity control: an empty root DOES report 'Target absent (CLAUDE.md)'" 1
else
  report "C-9d specificity control: an empty root DOES report 'Target absent (CLAUDE.md)'" 0 \
    "empty root did not report absent — BROKEN PROBE, C-9a/b/c are meaningless"
fi

fi  # end Suite C target-present guard

# --- Stage 5d (Suite S): settings.json operator-key guard + refresh (ADR-121) ---
# Covers #1355 AC-1 / AC-3 / AC-5 / AC-6 / AC-7. Appended as a NEW named suite;
# Suites F, G, T, P and C above are not modified. Runs under the SAME ${SBX} and the
# SAME trap-cleanup EXIT, so the R-8 HARD sandbox invariant (and its
# live-~/.claude/skills manifest proof below) covers every invocation here too —
# deliberately NOT a second `mktemp -d`.
#
# WHAT THIS SUITE GUARDS, stated as the defect it must fail on: update.sh refreshed
# the hook SCRIPTS and nothing refreshed their REGISTRATIONS, so a workspace could
# hold every current hook on disk with the events that would invoke them unwired.
# The field instance was four registration entries across three scripts, plus the
# whole Stop event block. S-1 and S-3 assert that exact set lands; run either
# against a build without the guard and they go red.
#
# THE DENOMINATOR IS THE TEMPLATE'S OWN REGISTRATION SET, enumerated at runtime —
# never a hardcoded count. Registration identity is the (event, matcher, basename)
# triple over the RESOLVED file: basename because the workspace root is baked into
# every command string, and resolved because the template's _comment key names a
# script in prose that substitute_template strips by design. A filename-shaped scan
# of the RAW template counts 19 scripts where the hooks block holds 17; the TWO
# phantoms (setup-workspace.sh and update.sh — both named only in the _comment prose,
# which substitute_template strips) can never appear in a deployed file. S-0a is the
# arm that pins that distinction so the suite cannot be "fixed" toward the wrong
# population. S-0a derives BOTH figures at runtime and asserts only `raw > hooks-block`,
# so the numbers written here are a worked illustration, never the assertion — the
# _comment gained its second phantom (update.sh) in this same release when the Layer-1
# / Layer-2 sentence was added, which is exactly why the arm is not hardcoded.
#
# NEGATIVE SCOPE — deliberately NOT asserted. Each is correct shipped behaviour and
# asserting it would make a correct build red:
#   (a) The overlay's own contents surviving a refresh beyond create-once + migration
#       merge — Claude Code owns overlay precedence, not the platform.
#   (b) A same-path value difference being migrated. It is platform state and is
#       REPLACED (reported + backed up, never silently dropped); promoting it to the
#       overlay would pin a stale platform value forever.
#   (c) Backup-directory uniqueness within the same UTC second — the shipped
#       convention is second-resolution and two writes in one second share a dir.
printf '\nStage 5d (Suite S): settings.json operator-key guard + refresh (ADR-121)\n'

mkdir -p "${SBX}/set-ws" "${SBX}/set-config"

SET_WS="${SBX}/set-ws"
SET_CONFIG="${SBX}/set-config"
SET_JSON="${SET_WS}/.claude/settings.json"
SET_OVERLAY="${SET_WS}/.claude/settings.local.json"
SET_STATE="${SET_WS}/.claude/.workspace-setup.state"
SET_TEMPLATE="${REPO_ROOT}/core/settings.json.template"
# The field-observed gap: 4 registration entries across 3 distinct scripts, plus the
# entire Stop event block. Held as data so every arm probes the same subject.
SET_MISSING_SCRIPTS="block-scope-segregation.sh verify-session-config.sh session-retro-trigger.sh"

sed -e "s|^claude_workspace_root = .*|claude_workspace_root = \"${SET_WS}\"|" \
    -e "s|^operator_homedir_path = .*|operator_homedir_path = \"${SBX}/home\"|" \
    "${SBX}/config/operator.toml" > "${SET_CONFIG}/operator.toml"
chmod 600 "${SET_CONFIG}/operator.toml"

# Enumerate (event, matcher, basename) triples of a settings JSON document.
# Prints one "event|matcher|basename" per line, sorted. Empty output for a file that
# is absent or unparseable — callers distinguish those cases explicitly.
set_triples() {
  python3 -c '
import json, os, sys
try:
    with open(sys.argv[1]) as f:
        doc = json.load(f)
except Exception:
    sys.exit(0)
out = []
for event, blocks in (doc.get("hooks") or {}).items():
    for b in blocks:
        for h in (b.get("hooks") or []):
            out.append("%s|%s|%s" % (event, b.get("matcher", ""), os.path.basename(h.get("command", ""))))
print("\n".join(sorted(out)))
' "$1" 2>/dev/null
}

# Strip the field-observed registrations from a deployed settings.json, dropping any
# event block left empty (which is how the Stop block disappears).
set_strip_registrations() {
  python3 -c '
import json, os, sys
path, missing = sys.argv[1], set(sys.argv[2].split())
with open(path) as f:
    doc = json.load(f)
hooks = doc.get("hooks") or {}
for event in list(hooks):
    kept_blocks = []
    for b in hooks[event]:
        kept = [h for h in (b.get("hooks") or []) if os.path.basename(h.get("command", "")) not in missing]
        if kept:
            nb = dict(b); nb["hooks"] = kept; kept_blocks.append(nb)
    if kept_blocks:
        hooks[event] = kept_blocks
    else:
        del hooks[event]
with open(path, "w") as f:
    json.dump(doc, f, indent=2); f.write("\n")
' "$1" "$2"
}

# Write the two ADR-121 baselines into the state file. "" for either means "absent",
# which the guard must treat as "classify structurally", never as "unchanged".
set_state_baseline() {
  python3 -c '
import json, sys
path, tpl_sha, inst_sha = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    state = json.load(f)
for key, val in (("settings_template_sha", tpl_sha), ("settings_installed_sha", inst_sha)):
    if val == "":
        state.pop(key, None)
    else:
        state[key] = val
with open(path, "w") as f:
    json.dump(state, f, indent=2); f.write("\n")
' "$1" "$2" "$3"
}

set_sha() { shasum -a 256 "$1" | awk '{print $1}'; }

set_refresh() {
  bash "${SETUP}" --source-repo "${REPO_ROOT}" --workspace-root "${SET_WS}" \
    --config-root "${SET_CONFIG}" --refresh-settings "$@" 0<&- 2>&1
}

# --- S-0a (probe validity): the comparison population is the RESOLVED hooks block,
#     not a filename scan of the raw template. Both arms observed. ---
set_tpl_hook_scripts=$(python3 -c '
import json, os, sys
doc = json.load(open(sys.argv[1]))
print(len({os.path.basename(h.get("command","")) for _e, bs in (doc.get("hooks") or {}).items() for b in bs for h in (b.get("hooks") or [])}))
' "${SET_TEMPLATE}")
set_tpl_raw_scan=$(grep -oE '[A-Za-z0-9_.-]+\.sh' "${SET_TEMPLATE}" | LC_ALL=C sort -u | wc -l | tr -d ' ')
if [ "${set_tpl_raw_scan}" -gt "${set_tpl_hook_scripts}" ]; then
  report "S-0a raw-filename scan over-counts the registration population (${set_tpl_raw_scan} vs ${set_tpl_hook_scripts}) — the suite keys on the resolved hooks block" 1
else
  report "S-0a raw-filename scan over-counts the registration population" 0 \
    "raw scan=${set_tpl_raw_scan}, hooks-block distinct=${set_tpl_hook_scripts}; expected raw > hooks-block (the _comment key names a script in prose). If the template's _comment changed, re-derive — do NOT relax this to >=."
fi

# --- S-0b: fresh install establishes the baseline and scaffolds the overlay ---
set_install_log=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/ok" "${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SET_WS}" \
  --config-root "${SET_CONFIG}" \
  --non-interactive 0<&- 2>&1)
set_install_exit=$?
if [ "${set_install_exit}" -eq 0 ] && [ -f "${SET_JSON}" ]; then
  report "S-0b fresh install for Suite S deployed settings.json" 1
else
  report "S-0b fresh install for Suite S deployed settings.json" 0 \
    "exit ${set_install_exit}; $(printf '%s' "${set_install_log}" | tail -3 | tr '\n' '|')"
fi

if [ -f "${SET_OVERLAY}" ] && [ "$(tr -d ' \n' < "${SET_OVERLAY}")" = "{}" ]; then
  report "S-0b install scaffolds an EMPTY settings.local.json overlay (create-once contract)" 1
else
  report "S-0b install scaffolds an EMPTY settings.local.json overlay (create-once contract)" 0 \
    "present=$([ -f "${SET_OVERLAY}" ] && echo yes || echo no); body=$(tr -d ' \n' < "${SET_OVERLAY}" 2>/dev/null)"
fi

set_state_tpl=$(jq -r '.settings_template_sha // ""' "${SET_STATE}" 2>/dev/null)
set_state_inst=$(jq -r '.settings_installed_sha // ""' "${SET_STATE}" 2>/dev/null)
if [ -n "${set_state_tpl}" ] && [ -n "${set_state_inst}" ] && [ "${set_state_tpl}" != "${set_state_inst}" ]; then
  report "S-0b install records BOTH baselines, and they are distinct (trigger != anchor)" 1
else
  report "S-0b install records BOTH baselines, and they are distinct (trigger != anchor)" 0 \
    "template_sha='${set_state_tpl}' installed_sha='${set_state_inst}'"
fi

# Guard the rest of the suite on a deployed target — without it every arm below is
# vacuous rather than failing.
if [ ! -f "${SET_JSON}" ]; then
  report "S-* preconditions (deployed settings.json present)" 0 "missing: ${SET_JSON}"
else

# --- S-1 (AC-4 + AC-6, the headline arm): a workspace installed at an OLDER
#     template — untouched platform copy, stale trigger — receives every missing
#     registration. This is the field defect, reproduced exactly. ---
set_strip_registrations "${SET_JSON}" "${SET_MISSING_SCRIPTS}"
# The platform DID write this file (from the older template), so the anchor matches
# it and the trigger is stale. That is precisely the pre-ADR-121 install shape.
set_state_baseline "${SET_STATE}" "0000000000000000000000000000000000000000000000000000000000000000" "$(set_sha "${SET_JSON}")"

# Probe-validity precondition: the registrations must be ABSENT now, or the
# post-refresh assertion proves nothing. Sensitivity arm with an observed non-zero.
set_before_count=$(set_triples "${SET_JSON}" | grep -c . || true)
set_tpl_count=$(set_triples "${SET_TEMPLATE}" | grep -c . || true)
set_before_missing=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)
if [ "${set_before_missing}" -gt 0 ] && [ "${set_before_count}" -lt "${set_tpl_count}" ]; then
  report "S-1 precondition: ${set_before_missing} of ${set_tpl_count} template registrations are ABSENT before the refresh (assertion is not vacuous)" 1
else
  report "S-1 precondition: registrations are ABSENT before the refresh" 0 \
    "missing=${set_before_missing} live=${set_before_count} template=${set_tpl_count}"
fi
if grep -q '^Stop|' <<<"$(set_triples "${SET_JSON}")"; then
  report "S-1 precondition: the Stop event block is absent before the refresh" 0 "Stop block unexpectedly present"
else
  report "S-1 precondition: the Stop event block is absent before the refresh" 1
fi

set_s1_log=$(set_refresh); set_s1_exit=$?
if [ "${set_s1_exit}" -eq 0 ]; then
  report "S-1 --refresh-settings exits 0 on an untouched stale copy" 1
else
  report "S-1 --refresh-settings exits 0 on an untouched stale copy" 0 \
    "exit ${set_s1_exit}; $(printf '%s' "${set_s1_log}" | tail -3 | tr '\n' '|')"
fi
if grep -q 'S-1 settings.json is an untouched platform copy' <<<"${set_s1_log}"; then
  report "S-1 guard classified the untouched copy as S-1 (byte-exact anchor arm, no structural diff)" 1
else
  report "S-1 guard classified the untouched copy as S-1" 0 \
    "$(grep -m2 -E 'S-[0-5]' <<<"${set_s1_log}" | tr '\n' '|')"
fi

set_after_missing=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)
if [ "${set_after_missing}" -eq 0 ]; then
  report "S-1 ALL ${set_tpl_count} template registrations reach the previously-deployed install (0 missing, was ${set_before_missing})" 1
else
  report "S-1 ALL template registrations reach the previously-deployed install" 0 \
    "still missing ${set_after_missing}: $(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | tr '\n' ' ')"
fi

# Name the field-observed scripts explicitly, so the arm reads as the defect it
# closes rather than as an anonymous set difference.
set_named_missing=0
for set_script in ${SET_MISSING_SCRIPTS}; do
  if ! grep -q "|${set_script}$" <<<"$(set_triples "${SET_JSON}")"; then
    set_named_missing=$((set_named_missing + 1))
  fi
done
if [ "${set_named_missing}" -eq 0 ]; then
  report "S-1 the three field-observed scripts are registered after the refresh (block-scope-segregation / verify-session-config / session-retro-trigger)" 1
else
  report "S-1 the three field-observed scripts are registered after the refresh" 0 \
    "${set_named_missing} of 3 still unregistered"
fi
if grep -q '^Stop|' <<<"$(set_triples "${SET_JSON}")"; then
  report "S-1 the Stop event block reaches the previously-deployed install" 1
else
  report "S-1 the Stop event block reaches the previously-deployed install" 0 "no Stop registration after refresh"
fi
if grep -qE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${SET_JSON}" 2>/dev/null; then
  report "S-1 refreshed settings.json carries no unresolved token" 0 \
    "$(grep -oE '\[(OPERATOR|CLAUDE|COWORK)_[A-Z_]+\]' "${SET_JSON}" | sort -u | tr '\n' ' ')"
else
  report "S-1 refreshed settings.json carries no unresolved token" 1
fi
if jq -e 'has("_comment")' "${SET_JSON}" >/dev/null 2>&1; then
  report "S-1 refreshed settings.json is a clean JSON document (_comment stripped)" 0 "_comment survived the refresh"
else
  report "S-1 refreshed settings.json is a clean JSON document (_comment stripped)" 1
fi
if [ "$(tr -d ' \n' < "${SET_OVERLAY}")" = "{}" ]; then
  report "S-1 the overlay is NOT written when there is nothing to migrate" 1
else
  report "S-1 the overlay is NOT written when there is nothing to migrate" 0 "overlay body: $(tr -d ' \n' < "${SET_OVERLAY}")"
fi

# --- S-0 (AC-3): an immediate re-run is a true no-op — both baselines match, so
#     nothing is written. This is what keeps update.sh's EX_NOCHANGE reachable. ---
set_s0_before=$(set_sha "${SET_JSON}")
set_s0_log=$(set_refresh); set_s0_exit=$?
set_s0_after=$(set_sha "${SET_JSON}")
if [ "${set_s0_exit}" -eq 0 ] && [ "${set_s0_before}" = "${set_s0_after}" ] \
   && grep -q 'S-0 settings.json already current' <<<"${set_s0_log}"; then
  report "S-0 idempotent re-run writes nothing (both baselines match; byte-identical)" 1
else
  report "S-0 idempotent re-run writes nothing" 0 \
    "exit ${set_s0_exit}; hash_changed=$([ "${set_s0_before}" = "${set_s0_after}" ] && echo no || echo YES); $(grep -m1 -E 'S-[0-5]' <<<"${set_s0_log}")"
fi

# --- S-0 force arm: --force-regen overrides the no-op skip but STILL runs the
#     guard first, so forcing can never bypass operator-key migration. ---
set_sf_log=$(set_refresh --force-regen); set_sf_exit=$?
if [ "${set_sf_exit}" -eq 0 ] && ! grep -q 'S-0 settings.json already current' <<<"${set_sf_log}"; then
  report "S-0 --force-regen overrides the no-op skip (classification still rendered)" 1
else
  report "S-0 --force-regen overrides the no-op skip" 0 \
    "exit ${set_sf_exit}; $(grep -m1 -E 'S-[0-5]' <<<"${set_sf_log}")"
fi

# --- S-2 (AC-3, no false fire): a formatting-only difference is NOT a
#     customization. Re-indent the deployed file and drop the anchor, forcing the
#     structural path; it must find nothing operator-only and touch no overlay. ---
python3 -c '
import json, sys
p = sys.argv[1]
doc = json.load(open(p))
with open(p, "w") as f:
    json.dump(doc, f, indent=6)   # same content, different bytes
    f.write("\n\n")
' "${SET_JSON}"
set_state_baseline "${SET_STATE}" "" ""
set_overlay_before=$(set_sha "${SET_OVERLAY}")
set_s2_log=$(set_refresh); set_s2_exit=$?
set_overlay_after=$(set_sha "${SET_OVERLAY}")
if [ "${set_s2_exit}" -eq 0 ] && grep -q 'S-2 no operator-added content' <<<"${set_s2_log}"; then
  report "S-2 a formatting-only difference does NOT fire the operator-key guard (AC-3)" 1
else
  report "S-2 a formatting-only difference does NOT fire the operator-key guard (AC-3)" 0 \
    "exit ${set_s2_exit}; $(grep -m1 -E 'S-[0-5]' <<<"${set_s2_log}")"
fi
if [ "${set_overlay_before}" = "${set_overlay_after}" ]; then
  report "S-2 the overlay is untouched on a no-customization refresh" 1
else
  report "S-2 the overlay is untouched on a no-customization refresh" 0 "overlay hash changed"
fi
if [ "$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)" -eq 0 ]; then
  report "S-2 the full template registration set is still present after the reformat path" 1
else
  report "S-2 the full template registration set is still present after the reformat path" 0
fi

# --- S-3 (AC-1 + AC-5, the guard-gated arm): operator content AND a stale file in
#     one fixture. The operator key must survive (migrated), AND every template
#     registration must land. Both halves, or the refresh is not guard-gated. ---
set_strip_registrations "${SET_JSON}" "${SET_MISSING_SCRIPTS}"
python3 -c '
import json, sys
p = sys.argv[1]
doc = json.load(open(p))
doc["env"] = {"SUITE_S_OPERATOR_KEY": "operator-value"}                  # unknown top-level key
doc["permissions"]["allow"].append("Bash(suite-s-operator-tool *)")      # permissions list extra
doc["hooks"]["PreToolUse"].append({"matcher": "Task",
    "hooks": [{"type": "command", "command": "/opt/suite-s/operator-hook.sh"}]})
with open(p, "w") as f:
    json.dump(doc, f, indent=2); f.write("\n")
' "${SET_JSON}"
set_state_baseline "${SET_STATE}" "" ""
set_s3_missing_before=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)
set_s3_log=$(set_refresh); set_s3_exit=$?

# The name says MIGRATED, so the assertion must be CONTENT, not the log line that
# announces it. Asserting only `grep 'S-3 MIGRATED'` would stay green under exactly
# the rejected alternative this arm exists to exclude — warn about the operator's
# keys but never move them — because that build still prints the warning. Under
# gate-efficacy Requirement (a) a log line is a proxy signal and is forbidden as the
# sole verdict-bearing assertion (the S-10 -> S-10b remedy, applied here).
# The log grep is RETAINED as a conjunct: it pins the classification that produced
# the migration, so the arm cannot pass off some other write path as an S-3.
set_s3_overlay_keys=$(python3 -c '
import json, sys
try:
    doc = json.load(open(sys.argv[1]))
except Exception:
    print(0); sys.exit(0)
print(len(doc) if isinstance(doc, dict) else 0)
' "${SET_OVERLAY}")
if [ "${set_s3_exit}" -eq 0 ] \
   && [ "${set_s3_overlay_keys}" -gt 0 ] \
   && grep -q 'SUITE_S_OPERATOR_KEY' "${SET_OVERLAY}" \
   && grep -q 'S-3 MIGRATED operator-added settings' <<<"${set_s3_log}"; then
  report "S-3 operator-added content is MIGRATED, not merely warned about (AC-1)" 1
else
  report "S-3 operator-added content is MIGRATED, not merely warned about (AC-1)" 0 \
    "exit ${set_s3_exit}; overlay_keys=${set_s3_overlay_keys} (expected >0); operator key in overlay=$(grep -q 'SUITE_S_OPERATOR_KEY' "${SET_OVERLAY}" && echo yes || echo NO); $(grep -m2 -E 'S-[0-5]' <<<"${set_s3_log}" | tr '\n' '|')"
fi
set_s3_named=0
for set_key in SUITE_S_OPERATOR_KEY 'Bash(suite-s-operator-tool \*)' operator-hook.sh; do
  grep -q "${set_key}" "${SET_OVERLAY}" || set_s3_named=$((set_s3_named + 1))
done
if [ "${set_s3_named}" -eq 0 ]; then
  report "S-3 all three operator shapes reach settings.local.json (top-level key, permissions entry, hook registration)" 1
else
  report "S-3 all three operator shapes reach settings.local.json" 0 \
    "${set_s3_named} of 3 absent from ${SET_OVERLAY}"
fi
if grep -q 'SUITE_S_OPERATOR_KEY' "${SET_JSON}"; then
  report "S-3 the managed file is regenerated clean (operator content no longer in it)" 0 "operator key still present in the managed file"
else
  report "S-3 the managed file is regenerated clean (operator content no longer in it)" 1
fi
set_s3_missing_after=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)
if [ "${set_s3_missing_before}" -gt 0 ] && [ "${set_s3_missing_after}" -eq 0 ]; then
  report "S-3 the template addition ALSO lands in the same run (${set_s3_missing_before} missing -> 0) — refresh and preservation both, which is AC-5" 1
else
  report "S-3 the template addition ALSO lands in the same run" 0 \
    "missing before=${set_s3_missing_before} after=${set_s3_missing_after}"
fi
if ls -d "${SET_WS}"/.backup-pre-update-* >/dev/null 2>&1; then
  report "S-3 a pre-migration backup of the managed file exists" 1
else
  report "S-3 a pre-migration backup of the managed file exists" 0 "no .backup-pre-update-* under ${SET_WS}"
fi

# --- S-4: the one case that must never be resolved silently. The overlay already
#     defines a migrating key with a DIFFERENT value -> abort, write NOTHING. ---
python3 -c '
import json, sys
sp, ov = sys.argv[1], sys.argv[2]
doc = json.load(open(sp)); doc["env"] = {"SUITE_S_OPERATOR_KEY": "managed-file-value"}
with open(sp, "w") as f: json.dump(doc, f, indent=2); f.write("\n")
o = json.load(open(ov)); o.setdefault("env", {})["SUITE_S_OPERATOR_KEY"] = "overlay-DIFFERENT-value"
with open(ov, "w") as f: json.dump(o, f, indent=2); f.write("\n")
' "${SET_JSON}" "${SET_OVERLAY}"
set_state_baseline "${SET_STATE}" "" ""
set_s4_before=$(set_sha "${SET_JSON}")
set_s4_overlay_before=$(set_sha "${SET_OVERLAY}")
set_s4_log=$(set_refresh); set_s4_exit=$?
set_s4_after=$(set_sha "${SET_JSON}")
set_s4_overlay_after=$(set_sha "${SET_OVERLAY}")
if [ "${set_s4_exit}" -eq 0 ] && [ "${set_s4_before}" = "${set_s4_after}" ] \
   && [ "${set_s4_overlay_before}" = "${set_s4_overlay_after}" ]; then
  report "S-4 a migration conflict writes NOTHING — managed file and overlay both byte-identical" 1
else
  report "S-4 a migration conflict writes NOTHING" 0 \
    "exit ${set_s4_exit}; managed_changed=$([ "${set_s4_before}" = "${set_s4_after}" ] && echo no || echo YES); overlay_changed=$([ "${set_s4_overlay_before}" = "${set_s4_overlay_after}" ] && echo no || echo YES)"
fi
if grep -q 'S-4 settings refresh ABORTED' <<<"${set_s4_log}" \
   && grep -q 'SUITE_S_OPERATOR_KEY' <<<"${set_s4_log}" \
   && grep -q 'REGISTRATIONS did NOT land' <<<"${set_s4_log}"; then
  report "S-4 the abort names the conflicting key AND states that registrations did not land" 1
else
  report "S-4 the abort names the conflicting key AND states that registrations did not land" 0 \
    "$(grep -m3 -E 'S-4' <<<"${set_s4_log}" | tr '\n' '|')"
fi

# --- S-5: an unparseable live file means the runtime is loading NO platform
#     settings — strictly worse than any customization loss. Back up, regenerate. ---
printf '{ this is not valid json ' > "${SET_JSON}"
set_state_baseline "${SET_STATE}" "" ""
set_s5_log=$(set_refresh); set_s5_exit=$?
if [ "${set_s5_exit}" -eq 0 ] && grep -q 'S-5 settings.json is not parseable JSON' <<<"${set_s5_log}"; then
  report "S-5 an unparseable settings.json is classified as the tamper case" 1
else
  report "S-5 an unparseable settings.json is classified as the tamper case" 0 \
    "exit ${set_s5_exit}; $(grep -m1 -E 'S-[0-5]' <<<"${set_s5_log}")"
fi
if ls -d "${SET_WS}"/.backup-tampered-* >/dev/null 2>&1; then
  report "S-5 the unparseable bytes are preserved on the tamper backup convention" 1
else
  report "S-5 the unparseable bytes are preserved on the tamper backup convention" 0 "no .backup-tampered-* under ${SET_WS}"
fi
if jq -e . "${SET_JSON}" >/dev/null 2>&1 \
   && [ "$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)" -eq 0 ]; then
  report "S-5 the file is regenerated to valid JSON carrying the full registration set" 1
else
  report "S-5 the file is regenerated to valid JSON carrying the full registration set" 0
fi

# --- S-6: --dry-run classifies and writes nothing. ---
python3 -c '
import json, sys
p = sys.argv[1]; doc = json.load(open(p))
doc["env"] = {"SUITE_S_DRYRUN_KEY": "x"}
with open(p, "w") as f: json.dump(doc, f, indent=2); f.write("\n")
' "${SET_JSON}"
set_state_baseline "${SET_STATE}" "" ""
set_s6_before=$(set_sha "${SET_JSON}")
set_s6_overlay_before=$(set_sha "${SET_OVERLAY}")
set_s6_log=$(set_refresh --dry-run); set_s6_exit=$?
if [ "${set_s6_exit}" -eq 0 ] \
   && [ "${set_s6_before}" = "$(set_sha "${SET_JSON}")" ] \
   && [ "${set_s6_overlay_before}" = "$(set_sha "${SET_OVERLAY}")" ] \
   && grep -q '\[dry-run\] S-3' <<<"${set_s6_log}"; then
  report "S-6 --dry-run reports the classification and writes nothing" 1
else
  report "S-6 --dry-run reports the classification and writes nothing" 0 \
    "exit ${set_s6_exit}; $(grep -m1 -E 'dry-run\] S-' <<<"${set_s6_log}")"
fi

# --- S-7 (AC-7): ADR-121 is Accepted. The design gates the refresh mechanism on
#     the ADR's status FIELD, so the check reads that field rather than inferring
#     acceptance from the file existing. ---
SET_ADR="${REPO_ROOT}/core/ADRs/ADR-121-settings-json-baseline-anchored-refresh.md"
if [ -f "${SET_ADR}" ]; then
  set_adr_status=$(awk '/^---$/{n++; next} n==1 && /^status:/{sub(/^status:[[:space:]]*/, ""); print; exit}' "${SET_ADR}")
  case "${set_adr_status}" in
    Accepted*)
      report "S-7 ADR-121 status field reads Accepted (AC-7)" 1 ;;
    *)
      report "S-7 ADR-121 status field reads Accepted (AC-7)" 0 "status: ${set_adr_status:-<unreadable>}" ;;
  esac
else
  report "S-7 ADR-121 present" 0 "missing: ${SET_ADR}"
fi

# --- S-8 (probe validity): the arms above must be PROVABLY able to fail. Mirrors
#     Suite P's P-8 and Suite C's C-9. A zero whose control also returns zero is a
#     broken probe, so the comparator is exercised on a known-bad subject. ---
set_probe_tmp="${SBX}/set-probe.json"
python3 -c '
import json, sys
doc = json.load(open(sys.argv[1]))
del doc["hooks"]["SessionStart"]
with open(sys.argv[2], "w") as f: json.dump(doc, f, indent=2)
' "${SET_JSON}" "${set_probe_tmp}"
set_probe_missing=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${set_probe_tmp}") | grep -c . || true)
set_control_missing=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)
if [ "${set_probe_missing}" -gt 0 ] && [ "${set_control_missing}" -eq 0 ]; then
  report "S-8 the registration comparator discriminates (mutated subject ${set_probe_missing} missing / control 0) — the S-1/S-3 zeros are real" 1
else
  report "S-8 the registration comparator discriminates" 0 \
    "mutated=${set_probe_missing} (expected >0); control=${set_control_missing} (expected 0). Equal values mean a BROKEN PROBE and every S-* zero above is meaningless."
fi
set_absent_probe=$(set_triples "${SBX}/set-does-not-exist.json" | grep -c . || true)
if [ "${set_absent_probe}" -eq 0 ]; then
  report "S-8 the comparator returns empty for an absent file (specificity arm)" 1
else
  report "S-8 the comparator returns empty for an absent file (specificity arm)" 0 "returned ${set_absent_probe} triples for a nonexistent path"
fi

# --- S-9 (AC-4 + AC-6, end-to-end): the SHIPPED update path — not the flow it
#     delegates to — carries the missing registrations into a previously-deployed
#     install. S-1 proves the guard; this proves update.sh actually invokes it. ---
set_strip_registrations "${SET_JSON}" "${SET_MISSING_SCRIPTS}"
set_state_baseline "${SET_STATE}" "0000000000000000000000000000000000000000000000000000000000000000" "$(set_sha "${SET_JSON}")"
rm -f "${SET_OVERLAY}"           # also exercises Phase 2.5d on an existing workspace
set_s9_missing_before=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)
if [ "${set_s9_missing_before}" -gt 0 ]; then
  report "S-9 precondition: ${set_s9_missing_before} registrations absent before ./update.sh (assertion is not vacuous)" 1
else
  report "S-9 precondition: registrations absent before ./update.sh" 0 "nothing missing — the fixture did not seed"
fi

set_s9_out=$(bash "${REPO_ROOT}/update.sh" \
  --config-root "${SET_CONFIG}" \
  --workspace-root "${SET_WS}" 2>&1)
set_s9_exit=$?

set_s9_missing_after=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | grep -c . || true)
if [ "${set_s9_missing_after}" -eq 0 ]; then
  report "S-9 ./update.sh carries ALL missing registrations into a previously-deployed install (${set_s9_missing_before} -> 0) — AC-4 + AC-6 end-to-end" 1
else
  report "S-9 ./update.sh carries ALL missing registrations into a previously-deployed install" 0 \
    "still missing ${set_s9_missing_after}: $(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${SET_JSON}") | tr '\n' ' '); update exit ${set_s9_exit}"
fi
if grep -q '^Stop|' <<<"$(set_triples "${SET_JSON}")"; then
  report "S-9 the Stop event block reaches the install via ./update.sh" 1
else
  report "S-9 the Stop event block reaches the install via ./update.sh" 0
fi
if grep -q 'Phase 5d: settings.json content changed' <<<"${set_s9_out}"; then
  report "S-9 Phase 5d reports a real byte delta (the EX_NOCHANGE flag is keyed to content, not to 'the phase ran')" 1
else
  report "S-9 Phase 5d reports a real byte delta" 0 \
    "$(grep -m2 -E 'Phase 5d' <<<"${set_s9_out}" | tr '\n' '|')"
fi

# --- S-10 (AC-2, the discoverability half): the update PATH restores the Layer-2
#     overlay to a workspace that already exists. Shipping it only at fresh install
#     would leave every deployed workspace with no signposted home for operator
#     settings.
#
#     SCOPE, stated precisely because a mutation run proved the naive form
#     mislabelled: this arm asserts the OUTCOME (the overlay exists and is empty),
#     which is reachable from TWO scaffolds — update.sh Phase 2.5d and the
#     --refresh-settings flow. Removing Phase 2.5d alone therefore leaves this arm
#     green, so it must NOT be labelled the Phase-2.5d gate. S-10b is that gate, and
#     S-11 independently pins the phase's position. The redundancy is deliberate:
#     Phase 2.5d is what scaffolds the overlay on a workspace where Phase 5d does not
#     run at all (no deployed settings.json), so neither scaffold subsumes the other.
if [ -f "${SET_OVERLAY}" ] && [ "$(tr -d ' \n' < "${SET_OVERLAY}")" = "{}" ]; then
  report "S-10 the update path restores an EMPTY settings.local.json to an EXISTING workspace (outcome arm; two scaffolds reach it)" 1
else
  report "S-10 the update path restores an EMPTY settings.local.json to an EXISTING workspace" 0 \
    "present=$([ -f "${SET_OVERLAY}" ] && echo yes || echo no); body=$(tr -d ' \n' < "${SET_OVERLAY}" 2>/dev/null)"
fi

# --- S-10b: Phase 2.5d specifically RAN. This is the phase-scoped arm S-10 is not:
#     it goes red when the scaffold is dropped from the update sequence, which the
#     outcome arm above cannot detect. ---
if grep -q 'Phase 2.5d: operator settings-overlay scaffold' <<<"${set_s9_out}"; then
  report "S-10b Phase 2.5d ran in the update sequence (phase-scoped arm)" 1
else
  report "S-10b Phase 2.5d ran in the update sequence (phase-scoped arm)" 0 \
    "no 'Phase 2.5d' line in the update output — the scaffold phase is not wired"
fi

# --- S-11: phase ORDER. Scripts (5c) must land before the registrations that name
#     them (5d), and the overlay (2.5d) before the migration that targets it. The
#     assertion is on observed line order in one real run, not on source reading. ---
set_l25d=$(grep -m1 -n 'Phase 2.5d' <<<"${set_s9_out}" | cut -d: -f1)
set_l5c=$(grep -m1 -n 'Phase 5c' <<<"${set_s9_out}" | cut -d: -f1)
set_l5d=$(grep -m1 -n 'Phase 5d' <<<"${set_s9_out}" | cut -d: -f1)
if [ -n "${set_l25d}" ] && [ -n "${set_l5c}" ] && [ -n "${set_l5d}" ] \
   && [ "${set_l25d}" -lt "${set_l5c}" ] && [ "${set_l5c}" -lt "${set_l5d}" ]; then
  report "S-11 phase order holds in a real run: 2.5d (${set_l25d}) < 5c (${set_l5c}) < 5d (${set_l5d})" 1
else
  report "S-11 phase order holds in a real run: 2.5d < 5c < 5d" 0 \
    "2.5d=${set_l25d:-absent} 5c=${set_l5c:-absent} 5d=${set_l5d:-absent}"
fi

# --- S-12 (T-1): a second update with nothing to do must NOT flip the change flag
#     off Phase 5d. Keying that flag to "the phase ran" is precisely what made
#     EX_NOCHANGE unreachable once before. ---
set_s12_before=$(set_sha "${SET_JSON}")
set_s12_out=$(bash "${REPO_ROOT}/update.sh" \
  --config-root "${SET_CONFIG}" \
  --workspace-root "${SET_WS}" 2>&1)
set_s12_after=$(set_sha "${SET_JSON}")
if [ "${set_s12_before}" = "${set_s12_after}" ] \
   && grep -q 'Phase 5d: settings.json byte-identical' <<<"${set_s12_out}"; then
  report "S-12 a no-delta re-run leaves settings.json byte-identical and Phase 5d reports no change (EX_NOCHANGE stays reachable)" 1
else
  report "S-12 a no-delta re-run leaves settings.json byte-identical and Phase 5d reports no change" 0 \
    "hash_changed=$([ "${set_s12_before}" = "${set_s12_after}" ] && echo no || echo YES); $(grep -m1 -E 'Phase 5d' <<<"${set_s12_out}")"
fi

# --- S-13: THE REBOOTSTRAP PATH. A plain setup-workspace.sh re-run — no flags at
#     all — over a healthy workspace routes main() -> detect_state_and_route() ->
#     rebootstrap(), which re-renders the managed settings.json. The Stage-5 design
#     record (sub-task #4790) scopes the guard to "the new --refresh-settings flow
#     AND the existing fresh/rebootstrap flows", and this is the arm for the second
#     half. That scope is a Stage-5 decision, NOT an ADR clause — ADR-121 §Decision 4
#     is "Migration precedes regeneration; warning alone is not sufficient", which
#     governs the guard's ORDER, not the set of flows it covers. This arm conforms to
#     both records.
#
# THE DEFECT THIS MUST FAIL ON, stated concretely: rebootstrap() called
# substitute_templates -> substitute_template directly, overwriting the managed file
# with no classification. Measured on that build, all three operator shapes were
# dropped — not migrated, not backed up, zero WARN lines — while --refresh-settings
# migrated all three from the identical fixture. Suite S had NO rebootstrap arm, so
# nothing caught it. Remove settings_install_or_guarded_rerender's guarded branch and
# this arm goes red.
#
# A DEDICATED WORKSPACE, deliberately. S-1..S-12 drive ${SET_WS} through a long
# sequence of hand-written baselines and stripped registrations; routing a
# no-flag re-run through that state would make the fixture ambiguous. This is a
# clean install whose ONLY perturbation is the operator injection, so a red result
# has exactly one cause. Still under ${SBX}, so the R-8 invariant below covers it.
#
# ASSERTIONS ARE CONTENT, NOT LOG LINES (gate-efficacy Requirement (a)): the verdict
# is "the keys are in the overlay and gone from the managed file", which a
# warn-but-do-not-migrate build fails. The log grep is a conjunct, never the sole
# assertion — the same S-10 -> S-10b remedy applied to S-3 above.
printf '\nS-13: the rebootstrap path (a plain re-run) is guard-gated (ADR-121 D-4)\n'

REB_WS="${SBX}/reb-ws"
REB_CONFIG="${SBX}/reb-config"
REB_JSON="${REB_WS}/.claude/settings.json"
REB_OVERLAY="${REB_WS}/.claude/settings.local.json"
mkdir -p "${REB_WS}" "${REB_CONFIG}"
sed -e "s|^claude_workspace_root = .*|claude_workspace_root = \"${REB_WS}\"|" \
    -e "s|^operator_homedir_path = .*|operator_homedir_path = \"${SBX}/home\"|" \
    "${SBX}/config/operator.toml" > "${REB_CONFIG}/operator.toml"
chmod 600 "${REB_CONFIG}/operator.toml"

reb_install_log=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/ok" "${SETUP}" \
  --source-repo "${REPO_ROOT}" --workspace-root "${REB_WS}" \
  --config-root "${REB_CONFIG}" --non-interactive 0<&- 2>&1)
reb_install_exit=$?

if [ "${reb_install_exit}" -eq 0 ] && [ -f "${REB_JSON}" ]; then
  report "S-13 precondition: fresh install deployed a managed settings.json (the guarded re-render must not break first install)" 1
else
  report "S-13 precondition: fresh install deployed a managed settings.json" 0 \
    "exit ${reb_install_exit}; $(printf '%s' "${reb_install_log}" | tail -3 | tr '\n' '|')"
fi

if [ ! -f "${REB_JSON}" ]; then
  report "S-13 rebootstrap arms (deployed settings.json present)" 0 "missing: ${REB_JSON}"
else

# Inject the same three operator shapes S-3 uses, into the MANAGED file.
python3 -c '
import json, sys
p = sys.argv[1]
doc = json.load(open(p))
doc["env"] = {"REBOOT_OPERATOR_KEY": "operator-value"}
doc["permissions"]["allow"].append("Bash(reboot-operator-tool *)")
doc["hooks"]["PreToolUse"].append({"matcher": "RebootMatcher",
    "hooks": [{"type": "command", "command": "/opt/reboot/operator-hook.sh"}]})
with open(p, "w") as f:
    json.dump(doc, f, indent=2); f.write("\n")
' "${REB_JSON}"

# PRECONDITION (the arm must not be vacuous): all three shapes ARE in the managed
# file, and NONE are in the overlay, before the re-run.
reb_before=0
for reb_key in REBOOT_OPERATOR_KEY 'reboot-operator-tool' 'operator-hook.sh'; do
  grep -q "${reb_key}" "${REB_JSON}" && reb_before=$((reb_before + 1))
done
reb_overlay_before=0
for reb_key in REBOOT_OPERATOR_KEY 'reboot-operator-tool' 'operator-hook.sh'; do
  grep -q "${reb_key}" "${REB_OVERLAY}" 2>/dev/null && reb_overlay_before=$((reb_overlay_before + 1))
done
if [ "${reb_before}" -eq 3 ] && [ "${reb_overlay_before}" -eq 0 ]; then
  report "S-13 precondition: 3 of 3 operator shapes present in the managed file, 0 in the overlay (assertion is not vacuous)" 1
else
  report "S-13 precondition: 3 of 3 operator shapes present in the managed file, 0 in the overlay" 0 \
    "managed=${reb_before} (expected 3); overlay=${reb_overlay_before} (expected 0)"
fi

# Confirm the route really is rebootstrap — otherwise a green result below could
# come from some other flow and the arm would be measuring the wrong subject.
reb_state_ok=$(jq -r '.verification_passed // false' "${REB_WS}/.claude/.workspace-setup.state" 2>/dev/null)

# THE RE-RUN. No flags: exactly what an operator types.
reb_log=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/ok" "${SETUP}" \
  --source-repo "${REPO_ROOT}" --workspace-root "${REB_WS}" \
  --config-root "${REB_CONFIG}" --non-interactive 0<&- 2>&1)
reb_exit=$?

if [ "${reb_state_ok}" = "true" ] && grep -q 'RE-BOOTSTRAP flow' <<<"${reb_log}"; then
  report "S-13 the no-flag re-run really did route to rebootstrap (subject control)" 1
else
  report "S-13 the no-flag re-run really did route to rebootstrap (subject control)" 0 \
    "verification_passed=${reb_state_ok}; flow=$(grep -m1 -E '(FRESH-INSTALL|RE-BOOTSTRAP|REFRESH-[A-Z]+) flow' <<<"${reb_log}")"
fi

# THE HEADLINE ASSERTION — content, not a log line. All three shapes must be in the
# overlay after a plain re-run, exactly as they are after --refresh-settings.
reb_migrated=0
for reb_key in REBOOT_OPERATOR_KEY 'reboot-operator-tool' 'operator-hook.sh'; do
  grep -q "${reb_key}" "${REB_OVERLAY}" 2>/dev/null && reb_migrated=$((reb_migrated + 1))
done
if [ "${reb_exit}" -eq 0 ] && [ "${reb_migrated}" -eq 3 ]; then
  report "S-13 a plain re-run MIGRATES all 3 operator shapes to the overlay (was 0 of 3 — silently dropped — before the guard reached this path)" 1
else
  report "S-13 a plain re-run MIGRATES all 3 operator shapes to the overlay" 0 \
    "exit ${reb_exit}; migrated=${reb_migrated} of 3. 0 of 3 means the rebootstrap re-render is UNGUARDED again — operator keys are being destroyed, not preserved."
fi

# The other half of the contract: the managed file regenerates clean.
if grep -q 'REBOOT_OPERATOR_KEY' "${REB_JSON}"; then
  report "S-13 the managed file is regenerated clean after the re-run" 0 "operator key still present in ${REB_JSON}"
else
  report "S-13 the managed file is regenerated clean after the re-run" 1
fi

# Migration is not destruction: a pre-migration copy must exist.
if ls -d "${REB_WS}"/.backup-pre-update-* >/dev/null 2>&1; then
  report "S-13 a pre-migration backup of the managed file exists (migration is recoverable, not destructive)" 1
else
  report "S-13 a pre-migration backup of the managed file exists" 0 "no .backup-pre-update-* under ${REB_WS}"
fi

# The re-render must still deliver the platform registrations it exists to deliver.
reb_missing=$(comm -23 <(set_triples "${SET_TEMPLATE}") <(set_triples "${REB_JSON}") | grep -c . || true)
if [ "${reb_missing}" -eq 0 ]; then
  report "S-13 the full template registration set is present after the re-run (preservation did not cost the refresh)" 1
else
  report "S-13 the full template registration set is present after the re-run" 0 \
    "${reb_missing} registration(s) missing after rebootstrap"
fi

# S-13 probe validity: the shape-counting comparator used above must be provably
# able to return a non-3. A count whose control cannot move is a broken probe.
reb_control=0
for reb_key in REBOOT_ABSENT_SENTINEL_KEY 'reboot-absent-sentinel-tool' 'reboot-absent-sentinel.sh'; do
  grep -q "${reb_key}" "${REB_OVERLAY}" 2>/dev/null && reb_control=$((reb_control + 1))
done
if [ "${reb_control}" -eq 0 ] && [ "${reb_migrated}" -eq 3 ]; then
  report "S-13 the shape comparator discriminates (3 real shapes found / 0 sentinel shapes found) — the 3 above is a real 3" 1
else
  report "S-13 the shape comparator discriminates" 0 \
    "sentinel=${reb_control} (expected 0); real=${reb_migrated} (expected 3). Equal values mean a BROKEN PROBE and the S-13 counts are meaningless."
fi

# --- S-13d: the no-write arms must NOT re-anchor the baseline. ---
# settings_regenerate re-anchors both baselines on every arm that WROTE. The arms
# that wrote nothing (S-4 CONFLICT, SKIP-*) must leave the baselines as read from
# state. Re-anchoring SETTINGS_INSTALLED_SHA to a file the platform did NOT write is
# a delayed-fuse version of the very defect S-13 closes: the NEXT run would match
# that sha, classify the operator-edited file as an "untouched platform copy" (S-1),
# and regenerate over it with no migration at all. One run later, keys gone.
#
# Added because a mutation proved it uncovered: deleting the arm-scoping left the
# suite 112/0 green. This arm is what makes that mutation red.
#
# The fixture reuses the overlay the S-13 arms just populated: env.REBOOT_OPERATOR_KEY
# now lives there, so re-introducing the SAME key with a DIFFERENT value into the
# managed file is a genuine migration conflict -> CONFLICT -> S-4 -> write nothing.
python3 -c '
import json, sys
p = sys.argv[1]
doc = json.load(open(p))
doc["env"] = {"REBOOT_OPERATOR_KEY": "managed-file-DIFFERENT-value"}
with open(p, "w") as f:
    json.dump(doc, f, indent=2); f.write("\n")
' "${REB_JSON}"

reb_d_live_sha=$(set_sha "${REB_JSON}")
reb_d_state_before=$(jq -r '.settings_installed_sha // ""' "${REB_WS}/.claude/.workspace-setup.state" 2>/dev/null)
reb_d_log=$(GIT_CONFIG_GLOBAL="${SBX}/gitcfg/ok" "${SETUP}" \
  --source-repo "${REPO_ROOT}" --workspace-root "${REB_WS}" \
  --config-root "${REB_CONFIG}" --non-interactive 0<&- 2>&1)
reb_d_live_after=$(set_sha "${REB_JSON}")
reb_d_state_after=$(jq -r '.settings_installed_sha // ""' "${REB_WS}/.claude/.workspace-setup.state" 2>/dev/null)

# Precondition: the run really did hit a no-write arm. Without this the baseline
# assertion below could pass for the wrong reason (a normal write path re-anchoring
# to a file it legitimately wrote).
if grep -q 'S-4 settings refresh ABORTED' <<<"${reb_d_log}" \
   && [ "${reb_d_live_sha}" = "${reb_d_live_after}" ]; then
  report "S-13d precondition: the conflicting re-run hit a NO-WRITE arm (S-4) and left the managed file byte-identical" 1
else
  report "S-13d precondition: the conflicting re-run hit a NO-WRITE arm (S-4)" 0 \
    "managed_changed=$([ "${reb_d_live_sha}" = "${reb_d_live_after}" ] && echo no || echo YES); $(grep -m2 -E 'S-[0-5] ' <<<"${reb_d_log}" | tr '\n' '|')"
fi

# THE ASSERTION: the recorded anchor must NOT have become the sha of the
# operator-edited file the platform declined to overwrite.
if [ -n "${reb_d_state_after}" ] && [ "${reb_d_state_after}" != "${reb_d_live_sha}" ]; then
  report "S-13d a no-write arm does NOT re-anchor settings_installed_sha to the operator-edited file (next run still classifies structurally)" 1
else
  report "S-13d a no-write arm does NOT re-anchor settings_installed_sha to the operator-edited file" 0 \
    "state anchor after='${reb_d_state_after}' equals the operator-edited live sha='${reb_d_live_sha}'. The NEXT run would read this file as an untouched platform copy (S-1) and regenerate over it with NO migration — the silent drop, one run later. (anchor before='${reb_d_state_before}')"
fi

fi  # end S-13 target-present guard

fi  # end Suite S target-present guard

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

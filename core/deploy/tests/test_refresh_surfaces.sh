#!/usr/bin/env bash
# test_refresh_surfaces.sh — regression for the targeted composition-surface refresh
# (./update.sh --surfaces-only), for deploy.sh's scope-honest no-op message, for the
# caller-independence of the composed surface set, and for a sandboxed update's
# containment to the config root it is given.
#
# THE DEFECTS THIS GUARDS
#   core/config/allowlists/script-execution-allowlist.txt is a COMPOSITION SURFACE.
#   The composition-surface manifest is sourced only by setup-workspace.sh and
#   update.sh; deploy.sh never sources it. So `deploy.sh --deploy` exits 0 reporting
#   "Nothing to deploy" while being structurally incapable of refreshing that file —
#   and for a long time that command was the recorded remediation for a stale
#   allowlist. The remediation was never executable.
#
#   A second defect: the refresh substituted the path of whichever checkout ran it
#   for [PMO_PLATFORM_ROOT], so a run from a worktree baked that worktree into a
#   security allowlist, and nothing said so. The fixture arms guard the fix.
#
#   A third: a full update given --config-root delegated its hook refresh without
#   it, so the refresh fell back to the default config root (the live one on an
#   operator's machine) and wrote its hook-bundle snapshots there. Arm 12 guards
#   the fix.
#
# WHAT THE ARMS PROVE, AND WHY EACH ONE EXISTS
#   Arm 0  hermetic PRE-FLIGHT. Isolation is a PRECONDITION, not a postmortem: the
#          suite REFUSES TO START unless HOME and both root overrides resolve inside
#          the sandbox and the two composition-root overrides (PMO_PLATFORM_ROOT,
#          PMO_INSTANCE_PATH) are unset. deploy.sh's write targets reduce to two env
#          vars (PMO_PLATFORM_DEPLOY_ROOT, PMO_PLATFORM_CONFIG_ROOT); ${var:-default}
#          collapses an exported-but-EMPTY var back to $HOME, so emptiness is checked
#          explicitly, not just presence. Baselines of the REAL home (the skills tree,
#          the deployed allowlist and the install record) are captured here and
#          re-compared at Arm 6, which runs LAST.
#   Arm 1  NEGATIVE CONTROL. Regress the sandbox allowlist so the probe token is
#          absent. If the regression does not take, every later "the token is present"
#          assertion is vacuous — so a failed Arm 1 makes the SUITE UNUSABLE and is
#          reported as FAIL. It is never downgraded to a pass.
#   Arm 2a THE DEFECT, BRANCH-INDEPENDENT. `deploy.sh --deploy` leaves the allowlist
#          byte-identical. This holds on EVERY branch deploy.sh can take — full-roster,
#          incremental, or the no-changes branch — because deploy.sh has no
#          composition-surface write path at all. This arm is what proves the CORRECTED
#          path, not ambient state, healed the file.
#   Arm 2b THE SCOPE-HONEST MESSAGE, BRANCH-TARGETED. Only reachable when deploy.sh
#          takes its no-changes branch. When the branch is not reached, this arm
#          SKIPS WITH A REASON — it never emits a pass on a fallback. (A fallback that
#          reports `ok` instead of SKIP is the false-GREEN defect a sibling card in this
#          same milestone is removing; this suite must not ship the bug its sibling
#          deletes.)
#   Arm 3  THE CORRECTED PATH. `./update.sh --surfaces-only` exits 0.
#   Arm 4  THE ASSERTION. The probe token is back, in ALL FOUR invocation forms, and
#          the deployed managed_sha equals the source template's hash.
#   Arm 5  SPECIFICITY / NO COLLATERAL. Proves --surfaces-only is genuinely TARGETED:
#          operator additions preserved verbatim, no skill redeployed, no hook
#          installed, .version unchanged, and .last-update UNCHANGED. The last one is
#          a tested property, not a spec note: .last-update is the final member of the
#          full sequence, so its timestamp is positive evidence that the WHOLE sequence
#          ran. A targeted mode writing it would destroy that discriminator.
#   Arm 7  THE INSTALL RECORD. An unattended install from a nested linked worktree,
#          with stdin held OPEN and silent, completes and records source_repo_path
#          as the fixture primary's physical path (computed by this suite with
#          pwd -P, never by the resolver under test) and source_repo_path_source as
#          the tier that supplied it. The fixture is a fresh git repository built
#          from a COPY of the working tree (never cp -R of the checkout), with a
#          nested and an out-of-tree linked worktree. Without git, every fixture arm
#          SKIPs with a reason; none passes.
#   Arm 8  CALLER-INDEPENDENCE. Refreshes from the main checkout, a nested worktree
#          and an out-of-tree worktree, each run from its own tree, compose one
#          surface set: each run rewrites every manifest-resolved target (managed_at
#          stamp); the sets are identical apart from managed_at; no target names the
#          invoking checkout; every [PMO_PLATFORM_ROOT] row is bound to the main
#          checkout (root probe). 8c, the CONTROL: a branch worktree carrying one
#          branch-only tool block changes the set by exactly that block, bound to
#          the main checkout.
#   Arm 9  PRE-RECORD FALLBACK. With the record's root keys removed, a forced
#          refresh from the nested worktree still binds every row to the main
#          working tree. The record is then restored byte-for-byte.
#   Arm 9b LEGACY RECORD. A record that names another existing clone and carries no
#          source_repo_path_source is advisory: the refresh binds the main working
#          tree, and one WARN names both roots. The record is then restored.
#   Arm 10 THE HEAL. A surface re-rooted to an out-of-tree worktree, its hashes
#          reset the way a pre-fix install leaves them, is healed by a PLAIN refresh
#          that regenerates exactly that surface.
#   Arm 12 THE CONFIG ROOT IS NOT A FALLBACK. A full update given --config-root
#          takes its hook-bundle snapshot there, and leaves the default config root
#          (a byte copy standing in for the live one) byte-identical.
#   Arm 6  LEAKAGE BACKSTOP, LAST. The real home is byte-identical to the Arm-0
#          baseline. It runs after every mutating arm, so their writes fall inside
#          its compare. A backstop, not the control — Arm 0 is the control.
#
# Run from anywhere (resolves repo root from its own location):
#   bash core/deploy/tests/test_refresh_surfaces.sh
#
# Returns non-zero on any failure. bash 3.2-safe.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SETUP="${REPO_ROOT}/docs/scripts/setup-workspace.sh"
UPDATE="${REPO_ROOT}/update.sh"
DEPLOY="${REPO_ROOT}/core/deploy/deploy.sh"

# The probe token: a script whose allowlist entry post-dates many deployed instances,
# which is what made the stale-allowlist defect observable in the first place.
PROBE_TOKEN="produce-learnings-register.sh"
SURFACE_BASENAME="script-execution-allowlist.txt"
SURFACE_SRC_REL="core/config/allowlists/${SURFACE_BASENAME}"
OPERATOR_SENTINEL="# refresh-surfaces-suite operator sentinel — must survive verbatim"

PASS=0
FAIL=0
SKIP=0

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

# skip_with_reason — the ONLY non-pass, non-fail outcome. Every call must state WHY
# the arm could not run. An arm that cannot run is never reported as passing.
skip_with_reason() {
  local name="$1" reason="$2"
  printf '  SKIP: %s\n' "${name}"
  printf '         reason: %s\n' "${reason}"
  SKIP=$((SKIP + 1))
}

sha() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

hash_file() {
  if command -v md5 >/dev/null 2>&1; then md5 -q "$1" 2>/dev/null
  else md5sum "$1" 2>/dev/null | awk '{print $1}'; fi
}

# Manifest of a directory: sorted "relpath  hash" lines. Empty (exit 0) when the
# directory is absent, so a machine with no live tree still gets a stable compare.
manifest_dir() {
  local root="$1"
  [ -d "${root}" ] || return 0
  local f
  while IFS= read -r f; do
    printf '%s  %s\n' "${f#"${root}"/}" "$(hash_file "${f}")"
  done < <(find "${root}" -type f 2>/dev/null | LC_ALL=C sort)
}

# ─────────────────────────────────────────────────────────────────────────────
# Arm 0 — hermetic pre-flight. ABORTS the suite on failure; never warns and continues.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 0: hermetic pre-flight (isolation is a precondition, not a postmortem)\n'

abort_preflight() {
  printf '  ABORT: %s\n' "$1"
  printf '\ntest_refresh_surfaces.sh: PRE-FLIGHT FAILED — suite refused to start.\n'
  exit 1
}

[ -f "${SETUP}" ]  || abort_preflight "setup-workspace.sh not found at ${SETUP}"
[ -f "${UPDATE}" ] || abort_preflight "update.sh not found at ${UPDATE} (it lives at the REPO ROOT)"
[ -f "${DEPLOY}" ] || abort_preflight "deploy.sh not found at ${DEPLOY}"
[ -f "${REPO_ROOT}/${SURFACE_SRC_REL}" ] || abort_preflight "source surface missing: ${SURFACE_SRC_REL}"

REAL_HOME="${HOME}"
REAL_SKILLS="${REAL_HOME}/.claude/skills"
REAL_ALLOWLIST="${REAL_HOME}/Claude/.claude/${SURFACE_BASENAME}"
REAL_INSTALL_RECORD="${REAL_HOME}/Claude/.claude/.workspace-setup.state"

SBX="$(mktemp -d -t refresh-surfaces.XXXXXX)" || abort_preflight "could not create sandbox"
cleanup() { [ -n "${SBX:-}" ] && [ -d "${SBX}" ] && rm -rf "${SBX}"; }
trap cleanup EXIT

mkdir -p "${SBX}/config" "${SBX}/ws" "${SBX}/home"

# The two roots deploy.sh derives every write target from, plus HOME itself.
export HOME="${SBX}/home"
export PMO_PLATFORM_DEPLOY_ROOT="${SBX}/home"
export PMO_PLATFORM_CONFIG_ROOT="${SBX}/config"

# Composition-root overrides no arm may inherit. Unset here, verified below — the same
# set-then-verify shape as the exports above.
#   PMO_PLATFORM_ROOT  tier 2 of the [PMO_PLATFORM_ROOT] resolution ladder. Inherited, it
#                      hands every refresh the same root, so an identity comparison cannot
#                      fail and the install record the fixture arms assert is never read.
#   PMO_INSTANCE_PATH  relocates the instance and hub-state composition targets. Inherited,
#                      the sandbox install and every update write the REAL instance directory.
unset PMO_PLATFORM_ROOT PMO_INSTANCE_PATH

# Non-EMPTY check, not merely set: ${var:-default} collapses an exported-but-empty
# override back to the real $HOME, which is the documented sandbox-escape trap.
[ -n "${PMO_PLATFORM_DEPLOY_ROOT}" ] || abort_preflight "PMO_PLATFORM_DEPLOY_ROOT is empty (collapses to \$HOME)"
[ -n "${PMO_PLATFORM_CONFIG_ROOT}" ] || abort_preflight "PMO_PLATFORM_CONFIG_ROOT is empty (collapses to \$HOME)"
[ -n "${HOME}" ]                     || abort_preflight "HOME is empty"

case "${PMO_PLATFORM_DEPLOY_ROOT}" in "${SBX}"*) ;; *) abort_preflight "deploy root outside sandbox: ${PMO_PLATFORM_DEPLOY_ROOT}" ;; esac
case "${PMO_PLATFORM_CONFIG_ROOT}" in "${SBX}"*) ;; *) abort_preflight "config root outside sandbox: ${PMO_PLATFORM_CONFIG_ROOT}" ;; esac
case "${HOME}"                     in "${SBX}"*) ;; *) abort_preflight "HOME outside sandbox: ${HOME}" ;; esac

[ "${PMO_PLATFORM_DEPLOY_ROOT}" != "${REAL_HOME}" ] || abort_preflight "deploy root equals the real home"
[ "${PMO_PLATFORM_CONFIG_ROOT}" != "${REAL_HOME}" ] || abort_preflight "config root equals the real home"
[ "${HOME}" != "${REAL_HOME}" ]                     || abort_preflight "HOME was not redirected"

[ -z "${PMO_PLATFORM_ROOT+x}" ] || abort_preflight "PMO_PLATFORM_ROOT is still set (readonly?) — tier 2 would bind every refresh"
[ -z "${PMO_INSTANCE_PATH+x}" ] || abort_preflight "PMO_INSTANCE_PATH is still set (readonly?) — instance-tier writes would leave the sandbox"
report "composition-root overrides unset (PMO_PLATFORM_ROOT, PMO_INSTANCE_PATH)" 1

# Baselines of the REAL home, captured BEFORE any invocation (re-compared at Arm 6).
LIVE_SKILLS_BEFORE="$(manifest_dir "${REAL_SKILLS}")"
LIVE_ALLOWLIST_BEFORE=""
[ -f "${REAL_ALLOWLIST}" ] && LIVE_ALLOWLIST_BEFORE="$(sha "${REAL_ALLOWLIST}")"
LIVE_RECORD_BEFORE=""
[ -f "${REAL_INSTALL_RECORD}" ] && LIVE_RECORD_BEFORE="$(sha "${REAL_INSTALL_RECORD}")"

report "sandbox roots resolve inside \$TMP, are non-empty, and differ from the real home" 1
report "real-home baselines captured before any invocation" 1

# ─────────────────────────────────────────────────────────────────────────────
# Sandbox construction — a REAL fresh install, so skills/hooks/.version exist and
# Arm 5's no-collateral assertions have something real to be measured against.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nSandbox: real fresh install under the redirected roots\n'

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
cowork_install_path = "${SBX}/cowork"
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

install_log="$("${SETUP}" \
  --source-repo "${REPO_ROOT}" \
  --workspace-root "${SBX}/ws" \
  --config-root "${SBX}/config" \
  < <(yes "") 2>&1)"
install_exit=$?

TARGET="${SBX}/ws/.claude/${SURFACE_BASENAME}"
if [ "${install_exit}" -ne 0 ] || [ ! -f "${TARGET}" ]; then
  printf '  ABORT: sandbox install did not produce %s (exit %s)\n' "${TARGET}" "${install_exit}"
  printf '%s\n' "${install_log}" | tail -8 | sed 's/^/         /'
  printf '\ntest_refresh_surfaces.sh: SANDBOX CONSTRUCTION FAILED.\n'
  exit 1
fi
report "sandbox install produced the composition surface" 1

# ─────────────────────────────────────────────────────────────────────────────
# Arm 1 — NEGATIVE CONTROL. Regress the surface so the probe token is absent.
# A failed regression makes every later assertion vacuous ⇒ FAIL, never a pass.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 1: negative control — regress the sandbox surface\n'

# Strip every line carrying the probe token from the managed body, and plant an
# operator-additions sentinel that must survive the later regeneration verbatim.
#
# The sentinel is inserted INSIDE the OPERATOR ADDITIONS fence, not appended to the
# end of the file. Only content between the BEGIN/END OPERATOR ADDITIONS markers is
# preserved across a regeneration; a line appended after the closing marker is
# outside the preserved region and is correctly dropped. Planting it outside the
# fence would make Arm 5 assert a guarantee the contract never made.
grep -v "${PROBE_TOKEN}" "${TARGET}" > "${TARGET}.regressed" 2>/dev/null
mv "${TARGET}.regressed" "${TARGET}"

END_OPERATOR_MARKER='# === END OPERATOR ADDITIONS ==='
if grep -qxF "${END_OPERATOR_MARKER}" "${TARGET}"; then
  awk -v sentinel="${OPERATOR_SENTINEL}" -v marker="${END_OPERATOR_MARKER}" \
    '$0 == marker { print sentinel } { print }' "${TARGET}" > "${TARGET}.sentinel"
  mv "${TARGET}.sentinel" "${TARGET}"
else
  report "operator-additions fence present in the installed surface" 0 \
    "no '${END_OPERATOR_MARKER}' marker; Arm 5's preservation assertion cannot be armed"
fi

regressed_hits="$(grep -c "${PROBE_TOKEN}" "${TARGET}" 2>/dev/null || true)"
if [ "${regressed_hits}" = "0" ]; then
  report "regression took — probe token absent from the sandbox surface (0 hits)" 1
else
  report "regression took — probe token absent from the sandbox surface" 0 \
    "still ${regressed_hits} hits; the fixture did not regress, so the suite is UNUSABLE"
  printf '\ntest_refresh_surfaces.sh: %d passed, %d failed, %d skipped — negative control broken.\n' \
    "${PASS}" "${FAIL}" "${SKIP}"
  exit 1
fi

POST_REGRESSION_SHA="$(sha "${TARGET}")"

# Seed the user-local skills mirror so should_full_roster() returns FALSE and
# deploy.sh reverts to incremental tag-diff deployment. Without this the mirror is
# empty, deploy.sh takes its "fresh install detected" full-roster branch, and the
# no-changes branch Arm 2b targets is structurally unreachable. Roster names are
# DERIVED from the repo tree rather than hardcoded, so the seed cannot drift out of
# step with the roster arrays deploy.sh builds.
#
# THE SEED COPIES CONTENT, NOT JUST DIRECTORY NAMES, and that is load-bearing.
# should_full_roster() tests directory PRESENCE, so bare `mkdir`s were enough to
# flip it — but deploy.sh now also selects against GROUND TRUTH (installed-vs-source
# content, per skill_content_drift), and a mirror of hollow directories is a
# genuinely stale instance: every roster skill reads as `missing`, the change set is
# non-empty, and the E-02 branch this arm targets becomes unreachable again. Seeding
# a real mirror keeps the fixture faithful to the state it claims to represent — an
# instance that is already current — which is the only state in which "no changes"
# is the correct answer for Arm 2b to assert on.
MIRROR="${SBX}/home/.claude/skills"
mkdir -p "${MIRROR}"
seeded=0
while IFS= read -r skill_md; do
  skill_dir="$(dirname "${skill_md}")"
  cp -R "${skill_dir}" "${MIRROR}/" 2>/dev/null || mkdir -p "${MIRROR}/$(basename "${skill_dir}")"
  seeded=$((seeded + 1))
done < <(find "${REPO_ROOT}/release/skills" "${REPO_ROOT}/core/skills" "${REPO_ROOT}/operations/skills" \
           -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | LC_ALL=C sort)

if [ "${seeded}" -ge 1 ]; then
  report "user-local mirror seeded with ${seeded} roster skill dirs (should_full_roster now false)" 1
else
  report "user-local mirror seeded with roster skill dirs" 0 \
    "found no */skills/*/SKILL.md under the repo; Arm 2b will skip"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 2a — THE DEFECT, BRANCH-INDEPENDENT.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 2a: deploy.sh --deploy cannot heal the surface (branch-independent)\n'

cd "${REPO_ROOT}" || abort_preflight "cannot cd to repo root"
deploy_log="$(bash "${DEPLOY}" --deploy 2>&1)"
deploy_exit=$?
POST_DEPLOY_SHA="$(sha "${TARGET}")"

if [ "${POST_DEPLOY_SHA}" = "${POST_REGRESSION_SHA}" ]; then
  report "surface byte-identical after --deploy (deploy.sh has no composition-surface write path)" 1
else
  report "surface byte-identical after --deploy" 0 \
    "sha changed ${POST_REGRESSION_SHA} -> ${POST_DEPLOY_SHA}; deploy.sh unexpectedly wrote a composition surface"
fi

post_deploy_hits="$(grep -c "${PROBE_TOKEN}" "${TARGET}" 2>/dev/null || true)"
if [ "${post_deploy_hits}" = "0" ]; then
  report "probe token still absent after --deploy (the remediation is inoperative)" 1
else
  report "probe token still absent after --deploy" 0 "unexpected ${post_deploy_hits} hits"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 2b — THE SCOPE-HONEST MESSAGE, BRANCH-TARGETED. SKIPs with a reason when the
# no-changes branch is not reached. Never emits a pass on a fallback.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 2b: the no-changes message names composition surfaces as out of scope\n'

E02_FIRST_LINE='No skill, package, or harness changes detected. Nothing to deploy.'

if printf '%s' "${deploy_log}" | grep -q 'Fresh install detected\|Full-roster deploy requested'; then
  skip_with_reason "scope-honest no-changes message" \
    "deploy.sh took its full-roster branch (empty user-local mirror), so the no-changes branch was never reached. Arm 2a already proved the defect on this branch."
elif ! printf '%s' "${deploy_log}" | grep -qF "${E02_FIRST_LINE}"; then
  skip_with_reason "scope-honest no-changes message" \
    "deploy.sh detected a non-empty change set, so the no-changes branch was not reached. Not a pass: the message was never emitted."
else
  ok=1; detail=""
  printf '%s' "${deploy_log}" | grep -q 'OUT OF SCOPE for --deploy' || { ok=0; detail="missing the out-of-scope statement"; }
  printf '%s' "${deploy_log}" | grep -q 'update.sh --surfaces-only'  || { ok=0; detail="${detail}; missing the targeted remediation command"; }
  if [ "${deploy_exit}" -ne 0 ]; then ok=0; detail="${detail}; exit was ${deploy_exit}, expected 0"; fi
  report "no-changes message states the out-of-scope boundary and names the working command" "${ok}" "${detail}"

  # The message must NOT match the summary line update.sh greps to set PHASE5_DEPLOYED.
  # A match on the no-op path would flip the flag and make EX_NOCHANGE unreachable.
  if printf '%s' "${deploy_log}" \
       | grep -qE 'Deployed: [0-9]+ skills, [0-9]+ packages, [0-9]+ harness artifacts'; then
    report "no-changes message does not match update.sh's deploy-summary parse" 0 \
      "the no-op path emitted the summary line; EX_NOCHANGE would become unreachable"
  else
    report "no-changes message does not match update.sh's deploy-summary parse" 1
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Pre-Arm-3 baselines for the no-collateral arm.
# ─────────────────────────────────────────────────────────────────────────────
WS_SKILLS_BEFORE="$(manifest_dir "${SBX}/ws/.claude/skills")"
WS_HOOKS_BEFORE="$(manifest_dir "${SBX}/ws/.claude/hooks")"
MIRROR_SKILLS_BEFORE="$(manifest_dir "${SBX}/home/.claude/skills")"
VERSION_BEFORE=""; [ -f "${SBX}/ws/.claude/.version" ] && VERSION_BEFORE="$(sha "${SBX}/ws/.claude/.version")"
LASTUPDATE_BEFORE="__ABSENT__"
[ -f "${SBX}/config/.last-update" ] && LASTUPDATE_BEFORE="$(sha "${SBX}/config/.last-update")"

# ─────────────────────────────────────────────────────────────────────────────
# Arm 3 — THE CORRECTED PATH.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 3: ./update.sh --surfaces-only (the corrected path)\n'

surfaces_log="$(bash "${UPDATE}" --surfaces-only \
  --workspace-root "${SBX}/ws" \
  --config-root "${SBX}/config" 2>&1)"
surfaces_exit=$?

if [ "${surfaces_exit}" -eq 0 ]; then
  report "--surfaces-only exits 0 (EX_OK — at least one surface regenerated)" 1
else
  report "--surfaces-only exits 0" 0 \
    "exit ${surfaces_exit}; last lines: $(printf '%s' "${surfaces_log}" | tail -4 | tr '\n' '|')"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 4 — THE ASSERTION.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 4: the surface is healed — probe token back in all four forms\n'

healed_hits="$(grep -c "${PROBE_TOKEN}" "${TARGET}" 2>/dev/null || true)"
if [ "${healed_hits}" -ge 1 ] 2>/dev/null; then
  report "probe token present after the corrected path (${healed_hits} hits)" 1
else
  report "probe token present after the corrected path" 0 "0 hits — the corrected path did not heal the surface"
fi

# All four invocation forms. The two absolute forms carry a RESOLVED root rather than
# the source template's token, so they are matched by suffix shape, not byte-equality.
form_ok=1; form_detail=""
grep -qE "^/.*/release/tools/${PROBE_TOKEN}$"                      "${TARGET}" || { form_ok=0; form_detail="absolute"; }
grep -qE "^/.*/\.claude/worktrees/\*/release/tools/${PROBE_TOKEN}$" "${TARGET}" || { form_ok=0; form_detail="${form_detail} worktree-glob"; }
grep -qxF "./release/tools/${PROBE_TOKEN}"                          "${TARGET}" || { form_ok=0; form_detail="${form_detail} dot-relative"; }
grep -qxF "release/tools/${PROBE_TOKEN}"                            "${TARGET}" || { form_ok=0; form_detail="${form_detail} bare-relative"; }
report "all four invocation forms present (absolute, worktree-glob, dot-relative, bare-relative)" \
  "${form_ok}" "missing form(s):${form_detail}"

# Tokens actually resolved — an unresolved token left literal is the fail-open shape.
if grep -q '\[PMO_PLATFORM_ROOT\]\|\[CLAUDE_WORKSPACE_ROOT\]' "${TARGET}"; then
  report "no unresolved tokens left literal in the regenerated surface" 0 \
    "an unresolved [TOKEN] survived into the deployed body"
else
  report "no unresolved tokens left literal in the regenerated surface" 1
fi

# The deployed managed_sha must equal the SOURCE TEMPLATE's hash (ADR-014: managed_sha
# is the source-template hash; installed_sha is the post-substitution tamper anchor).
deployed_managed_sha="$(grep -E '^# managed_sha:' "${TARGET}" | head -1 | awk '{print $3}')"
source_sha="$(sha "${REPO_ROOT}/${SURFACE_SRC_REL}")"
if [ -n "${deployed_managed_sha}" ] && [ "${deployed_managed_sha}" = "${source_sha}" ]; then
  report "deployed managed_sha equals the source-template hash" 1
else
  report "deployed managed_sha equals the source-template hash" 0 \
    "deployed='${deployed_managed_sha}' source='${source_sha}'"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 5 — SPECIFICITY / NO COLLATERAL. Proves the mode is genuinely targeted.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 5: no collateral — the mode is targeted, not a full update in disguise\n'

if grep -qxF "${OPERATOR_SENTINEL}" "${TARGET}"; then
  report "operator additions preserved verbatim through regeneration" 1
else
  report "operator additions preserved verbatim through regeneration" 0 "sentinel line was lost"
fi

WS_SKILLS_AFTER="$(manifest_dir "${SBX}/ws/.claude/skills")"
WS_HOOKS_AFTER="$(manifest_dir "${SBX}/ws/.claude/hooks")"
MIRROR_SKILLS_AFTER="$(manifest_dir "${SBX}/home/.claude/skills")"

[ "${WS_SKILLS_BEFORE}" = "${WS_SKILLS_AFTER}" ] \
  && report "no skill redeployed into the workspace tree" 1 \
  || report "no skill redeployed into the workspace tree" 0 "workspace skills tree changed"

[ "${MIRROR_SKILLS_BEFORE}" = "${MIRROR_SKILLS_AFTER}" ] \
  && report "no skill redeployed into the user-local mirror" 1 \
  || report "no skill redeployed into the user-local mirror" 0 "user-local skills mirror changed"

[ "${WS_HOOKS_BEFORE}" = "${WS_HOOKS_AFTER}" ] \
  && report "no hook installed or refreshed" 1 \
  || report "no hook installed or refreshed" 0 "hooks tree changed"

VERSION_AFTER=""; [ -f "${SBX}/ws/.claude/.version" ] && VERSION_AFTER="$(sha "${SBX}/ws/.claude/.version")"
[ "${VERSION_BEFORE}" = "${VERSION_AFTER}" ] \
  && report ".version snapshot NOT restamped" 1 \
  || report ".version snapshot NOT restamped" 0 "snapshot changed ${VERSION_BEFORE} -> ${VERSION_AFTER}"

# .last-update is the LAST member of the full sequence, so its timestamp is positive
# evidence the WHOLE sequence ran. A targeted mode writing it destroys that signal.
LASTUPDATE_AFTER="__ABSENT__"
[ -f "${SBX}/config/.last-update" ] && LASTUPDATE_AFTER="$(sha "${SBX}/config/.last-update")"
if [ "${LASTUPDATE_BEFORE}" = "${LASTUPDATE_AFTER}" ]; then
  report ".last-update NOT written (the full-run discriminator is preserved)" 1
else
  report ".last-update NOT written (the full-run discriminator is preserved)" 0 \
    "changed ${LASTUPDATE_BEFORE} -> ${LASTUPDATE_AFTER}; a targeted refresh must not stamp the full-update marker"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Fixture — shared by Arms 7-11. A fresh git repository built from a COPY of the
# working tree, a nested and an out-of-tree linked worktree, and a second sandbox
# workspace installed from the nested one (Arm 7). Never `cp -R` the checkout: a
# linked worktree's .git entry names the real repository, and a worktree added
# through it would be registered there. Every name a later arm expands is assigned
# here, unconditionally, because this file runs under `set -u`.
# ─────────────────────────────────────────────────────────────────────────────
FIXTURE_READY=0
FIXTURE_SKIP_REASON=""        # non-empty ONLY when git is unavailable
ARM8_READY=0
FX_PRIMARY="${SBX}/fixture/primary"
FX_W1="${FX_PRIMARY}/.claude/worktrees/w1"
FX_SCRATCH="${SBX}/fixture/scratch/wt"
FX_WB="${SBX}/fixture/scratch/wb"
FX_OTHER="${SBX}/fixture/other"
FX_PRIMARY_P=""
FX_SCRATCH_P=""
FX_OTHER_P=""
FX_TPL_REL="${SURFACE_SRC_REL}"
FX_ALLOW=""
ALL_KEYS=""
FWS="${SBX}/fws"
FCFG="${SBX}/fcfg"
STATE="${FWS}/.claude/.workspace-setup.state"
LOGS="${SBX}/logs"
SNAP="${SBX}/snap"
FX_LOG="${LOGS}/7-fixture.log"
mkdir -p "${LOGS}" "${SNAP}" "${FWS}" "${FCFG}"

# The log contract. Every fixture refresh writes ${LOGS}/<name>.out and <name>.err,
# named 8-primary, 8-w1, 8-scratch, 8c-wb, 9-w1, 9b-w1 and 10-w1. Arm 11 reads the
# stderr of six of them (all but 9b-w1); an absent or empty log is a FAIL there.

# fx_git — git for the FIXTURE only: every GIT_* variable stripped (an inherited
# GIT_DIR or GIT_WORK_TREE must never point it at the real repository), no system or
# global config, a fixture identity, no signing.
fx_git() (
  for v in $(compgen -e); do case "${v}" in GIT_*) unset "${v}" ;; esac; done
  export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
  exec git -c user.name='refresh-surfaces fixture' -c user.email=fixture@example.invalid \
    -c commit.gpgsign=false -c init.defaultBranch=main "$@"
)

# fx_build — prints the step that failed; returns 0 with the fixture ready for Arm 7.
fx_build() {
  mkdir -p "${FX_PRIMARY}" "${SBX}/fixture/scratch" || { echo "mkdir"; return 1; }
  fx_git -C "${REPO_ROOT}" ls-files -z --cached --others --exclude-standard \
    >"${LOGS}/7-fixture.files" 2>>"${FX_LOG}" || { echo "ls-files"; return 1; }
  python3 - "${REPO_ROOT}" "${FX_PRIMARY}" "${LOGS}/7-fixture.files" >>"${FX_LOG}" 2>&1 <<'PY' || { echo "copy"; return 1; }
import os, shutil, sys
src, dst, lst = sys.argv[1:4]
copied = 0
for raw in open(lst, "rb").read().split(b"\0"):
    if not raw:
        continue
    rel = os.fsdecode(raw)
    s = os.path.join(src, rel)
    if not os.path.isfile(s):                  # listed, but deleted in the working tree
        continue
    d = os.path.join(dst, rel)
    os.makedirs(os.path.dirname(d), exist_ok=True)
    shutil.copy2(s, d)                         # contents and mode; the .git entry is never listed
    copied += 1
print(f"copied {copied} files")
sys.exit(0 if copied else 1)
PY
  fx_git -C "${FX_PRIMARY}" init -q >>"${FX_LOG}" 2>&1 || { echo "init"; return 1; }
  # A failed init must never let `add` walk up into an enclosing repository.
  [ -d "${FX_PRIMARY}/.git" ] || { echo "init (no .git directory)"; return 1; }
  fx_git -C "${FX_PRIMARY}" add -A >>"${FX_LOG}" 2>&1 || { echo "add"; return 1; }
  fx_git -C "${FX_PRIMARY}" commit -q -m 'fixture: the working tree under test' >>"${FX_LOG}" 2>&1 \
    || { echo "commit"; return 1; }
  mkdir -p "${FX_PRIMARY}/.claude/worktrees" || { echo "mkdir worktrees"; return 1; }
  # No `-q`: older command-line-tools git lacks `worktree add --quiet`.
  fx_git -C "${FX_PRIMARY}" worktree add --detach "${FX_W1}" >>"${FX_LOG}" 2>&1 \
    || { echo "worktree add (nested)"; return 1; }
  fx_git -C "${FX_PRIMARY}" worktree add --detach "${FX_SCRATCH}" >>"${FX_LOG}" 2>&1 \
    || { echo "worktree add (out-of-tree)"; return 1; }
}

fx_unavailable() {   # a fixture-dependent arm reports exactly one outcome when there is no fixture
  if [ -n "${FIXTURE_SKIP_REASON:-}" ]; then skip_with_reason "$1" "${FIXTURE_SKIP_REASON}"
  else report "$1" 0 "the fixture was not built (see Arm 7)"; fi
}

fx_targets() {       # ${SBX}/targets.tsv: "<tier>\t<target>" per manifest row, then "ROWS\t<n>"
  (
    # shellcheck disable=SC1090,SC1091
    source "${FX_PRIMARY}/core/deploy/lib-composition.sh" || exit 1
    lib_compose_source_manifest "${FX_PRIMARY}" || exit 1
    lib_compose_assert_manifest_loaded || exit 1
    for entry in "${COMPOSITION_SURFACE_FILES[@]}"; do
      lib_compose_parse_entry "${entry}"
      target="$(lib_compose_resolve_target "$(basename "${LIB_COMPOSE_ENTRY_SRC}")" \
                "${LIB_COMPOSE_ENTRY_TIER}" "${FWS}")" || exit 1
      printf '%s\t%s\n' "${LIB_COMPOSE_ENTRY_TIER}" "${target}"
    done
    printf 'ROWS\t%s\n' "${#COMPOSITION_SURFACE_FILES[@]}"
  ) > "${SBX}/targets.tsv"
}

# fx_update <log-name> <tree> [update.sh flags...] — a refresh run FROM its own tree,
# the operator's invocation shape, against the fixture workspace and config root.
fx_update() {
  local name="$1" tree="$2"; shift 2
  ( cd "${tree}" && bash ./update.sh "$@" --config-root "${FCFG}" --workspace-root "${FWS}" ) \
    >"${LOGS}/${name}.out" 2>"${LOGS}/${name}.err"
}

# run_open_stdin BUDGET_S CMD [ARGS...] — the same program as run_open_stdin in
# test_upgrade_config_durability.sh; keep the two byte-identical. CMD's stdin is a pipe
# this harness holds OPEN and never writes, so a prompt that ignores --non-interactive
# blocks instead of reading EOF. Returns CMD's exit status, or 124 once BUDGET_S seconds
# pass (the process group terminated, the OPEN-STDIN-HARNESS TIMEOUT sentinel on
# stderr); an OPEN-STDIN-HARNESS START marker on stderr always comes first.
OPEN_STDIN_BUDGET_S="${OPEN_STDIN_BUDGET_S:-300}"
run_open_stdin() {
  python3 - "$@" <<'PY'
import os
import signal
import subprocess
import sys

budget = float(sys.argv[1])
sys.stderr.write("OPEN-STDIN-HARNESS: START budget=%ss\n" % sys.argv[1])
sys.stderr.flush()
proc = subprocess.Popen(sys.argv[2:], stdin=subprocess.PIPE, start_new_session=True)
try:
    rc = proc.wait(timeout=budget)
except subprocess.TimeoutExpired:
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(proc.pid, sig)
        except ProcessLookupError:
            break
        try:
            proc.wait(timeout=15)
            break
        except subprocess.TimeoutExpired:
            continue
    sys.stderr.write("OPEN-STDIN-HARNESS: TIMEOUT after %ss (process group terminated)\n" % sys.argv[1])
    rc = 124
finally:
    proc.stdin.close()
sys.exit(rc)
PY
}

fx_py() {            # one inline program, never written to disk and executed
  python3 - "$@" <<'PY'
import collections, hashlib, json, os, re, sys
STAMP = "1970-01-01T00:00:00Z"
MARKER = re.compile(r"^(# |<!-- )managed_at: (\S+)( -->)?$")   # line 4 of every composed file
TOKEN = "[PMO_PLATFORM_ROOT]"
GLOB = "/.claude/worktrees/*/"                                  # the worktree-glob form's segment
GEN = re.compile(r"^[0-9]{8}T[0-9]{6}Z-[0-9]+$")               # a hook-bundle snapshot generation
C = collections.Counter

def targets(tsv):
    out, rows = [], None
    for line in open(tsv, encoding="utf-8").read().splitlines():
        tier, _, path = line.partition("\t")
        if tier == "ROWS":
            rows = int(path)
        elif tier:
            out.append((f"{tier}-{os.path.basename(path)}", path))
    return out, rows

def lines(path):
    return open(path, encoding="utf-8").read().split("\n")

def marker(ls):
    return MARKER.match(ls[3]) if len(ls) > 3 else None

def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()

def token_rows(template):                     # non-comment template lines carrying the token
    return [l for l in lines(template) if TOKEN in l and not l.lstrip().startswith("#")]

def gens(root):                               # snapshot generations under <config-root>, sorted
    d = os.path.join(root, "hook-bundle-backups")
    return sorted(n for n in (os.listdir(d) if os.path.isdir(d) else []) if GEN.match(n))

cmd, args, problems = sys.argv[1], sys.argv[2:], []

if cmd == "check-targets":                    # <tsv> <sandbox> <required-basename>...
    tset, rows = targets(args[0]); keys = [k for k, _ in tset]
    if rows is None or rows != len(tset):
        problems.append(f"{len(tset)} targets for {rows} manifest rows")
    if len(set(keys)) != len(keys):
        problems.append("tier-basename keys are not unique")
    for k, p in tset:
        if not p.startswith(args[1].rstrip("/") + "/"):
            problems.append(f"{k} resolves outside the sandbox")
        elif not os.path.isfile(p):
            problems.append(f"{k} absent after the fixture install")
    # A required member is matched on the TARGET's basename, never on the tier-qualified
    # key: a member's tier is another decision's to make, and tier names carry hyphens,
    # so the key cannot be split back apart.
    bases = {os.path.basename(p) for _, p in tset}
    problems += [f"required member missing: {r}" for r in args[2:] if r not in bases]
elif cmd == "keys":                           # <tsv> -> every key, sorted
    print(" ".join(sorted(k for k, _ in targets(args[0])[0]))); sys.exit(0)
elif cmd == "token-rows":                     # <template> -> non-comment lines carrying the token
    print(len(token_rows(args[0]))); sys.exit(0)
elif cmd == "stamp":                          # <tsv>
    for k, p in targets(args[0])[0]:
        ls = lines(p); m = marker(ls)
        if not m:
            problems.append(f"{k}: line 4 is not a managed_at marker"); continue
        ls[3] = f"{m.group(1)}managed_at: {STAMP}{m.group(3) or ''}"
        open(p, "w", encoding="utf-8").write("\n".join(ls))
elif cmd == "unstamped":                      # <tsv> -> keys rewritten since the stamp, sorted
    print(" ".join(sorted(k for k, p in targets(args[0])[0]
                          if not (marker(lines(p)) and marker(lines(p)).group(2) == STAMP)))); sys.exit(0)
elif cmd == "snapshot":                       # <tsv> <outdir>: each target minus its managed_at line
    os.makedirs(args[1], exist_ok=True)
    for k, p in targets(args[0])[0]:
        ls = lines(p)
        if not marker(ls):
            problems.append(f"{k}: line 4 is not a managed_at marker"); continue
        norm = ls[:3] + ls[4:]
        for key in ("managed_sha", "installed_sha"):      # kept: installed_sha moves with the root
            if sum(1 for l in norm if re.match(rf"^(# |<!-- ){key}: ", l)) != 1:
                problems.append(f"{k}: {key} not retained exactly once")
        open(os.path.join(args[1], k), "w", encoding="utf-8").write("\n".join(norm))
elif cmd == "caller-hits":                    # <tsv> <checkout> -> lines naming that checkout
    needles = {args[1].rstrip("/") + "/", os.path.realpath(args[1]).rstrip("/") + "/"}
    print(sum(1 for _, p in targets(args[0])[0] for l in lines(p) if any(n in l for n in needles))); sys.exit(0)
elif cmd == "diffset":                        # <dirA> <dirB> -> keys whose contents differ, sorted
    def read(d, n):
        f = os.path.join(d, n)
        return open(f, "rb").read() if os.path.isfile(f) else None
    a, b = args
    print(" ".join(n for n in sorted(set(os.listdir(a)) | set(os.listdir(b)))
                   if read(a, n) is None or read(a, n) != read(b, n))); sys.exit(0)
elif cmd == "allowlist-delta":                # <snapA> <snapB> <templateA> <templateB> <canonical-root>
    sa, sb, ta, tb, canon = args
    def body(t):
        return open(t, encoding="utf-8").read().replace(TOKEN, canon).rstrip().split("\n")
    exp_add, exp_del = C(body(tb)) - C(body(ta)), C(body(ta)) - C(body(tb))
    if exp_del or sum(exp_add.values()) != 5 or \
       sum(v for l, v in exp_add.items() if l.startswith(canon + "/")) != 2:
        problems.append("fixture self-check: the branch block is not a pure 5-line addition with 2 absolute rows")
    add, rem = C(lines(sb)) - C(lines(sa)), C(lines(sa)) - C(lines(sb))
    for d, t, label in ((add, tb, "branch"), (rem, ta, "main-checkout")):
        want = f"# managed_sha: {sha(t)}"
        if d[want] != 1:
            problems.append(f"managed_sha does not carry the {label} template's hash")
        d[want] -= 1
        inst = [l for l, v in d.items() if l.startswith("# installed_sha: ") and v > 0]
        if len(inst) != 1:
            problems.append(f"installed_sha did not change exactly once ({label} side)")
        for l in inst:
            d[l] -= 1
    add, rem = +add, +rem
    if add != exp_add:
        problems.append("added lines are not the branch block bound to the main checkout: "
                        f"{sorted((add - exp_add).elements())[:3]}")
    if rem:
        problems.append(f"unexpected removed lines: {sorted(rem.elements())[:3]}")
elif cmd == "root-probe":                     # <deployed> <template> <root>: every token row of the
    dep, tpl, root = args                     # template, token replaced by <root>, is present, and
    want = [r.replace(TOKEN, root) for r in token_rows(tpl)]   # the worktree-glob rows' roots = {root}
    have = lines(dep)
    missing = sum((C(want) - C(have)).values())
    roots = {m.group(1) for m in (re.match(r"^(/.+?)/\.claude/worktrees/\*/", l) for l in have) if m}
    if not want:
        problems.append("the template carries no token rows, so the probe cannot fail")
    if missing:
        problems.append(f"MISSING={missing} of {len(want)}")
    if roots != {root}:
        problems.append(f"worktree-glob roots {sorted(roots)} != {[root]}")
elif cmd == "reroot-copy":                    # <srcdir> <dstdir> <key> <root> <alt-root>: copy a
    src, dst, key, root, alt = args           # snapshot, re-rooting ONE form-1 token row of <key>
    os.makedirs(dst, exist_ok=True)
    done = False
    for n in sorted(os.listdir(src)):
        ls = lines(os.path.join(src, n))
        if n == key:
            for i, l in enumerate(ls):
                if l.startswith(root + "/") and GLOB not in l:
                    ls[i] = alt + l[len(root):]; done = True; break
        open(os.path.join(dst, n), "w", encoding="utf-8").write("\n".join(ls))
    if not done:
        problems.append(f"no form-1 row rooted at {root} in {key}")
elif cmd == "poison":                         # <deployed> <template> <new-root>: the shape a pre-fix
    dep, tpl, new = args                      # install leaves: every token row on <new-root>, the
    ls, cur = lines(dep), None                # managed_sha zeroed, the installed_sha line dropped
    for r in token_rows(tpl):                 # the root the surface carries NOW, read off one
        if r.startswith(TOKEN + "/") and GLOB not in r:        # form-1 row, whatever wrote it
            tail = r[len(TOKEN):]
            hits = [l for l in ls if l.startswith("/") and l.endswith(tail) and GLOB not in l]
            if len(hits) == 1:
                cur = hits[0][:-len(tail)]; break
    if cur is None:
        problems.append("could not identify the root the surface carries")
    else:
        out = []
        for l in ls:
            if l.startswith(cur + "/"):
                l = new + l[len(cur):]
            elif re.match(r"^(# |<!-- )managed_sha: ", l):
                l = re.sub(r"managed_sha: \S+", "managed_sha: " + "0" * 64, l)
            elif re.match(r"^(# |<!-- )installed_sha: ", l):
                continue
            out.append(l)
        open(dep, "w", encoding="utf-8").write("\n".join(out))
elif cmd == "segment-counts":                 # <file> <root>: a diagnostic, never graded
    ls, needle = lines(args[0]), args[1].rstrip("/") + "/"
    print(f"lines carrying /.claude/worktrees/: {sum(1 for l in ls if '/.claude/worktrees/' in l)}; "
          f"lines naming {needle}: {sum(1 for l in ls if needle in l)}"); sys.exit(0)
elif cmd == "record-field":                   # <state> <key> -> its value, or <absent> / <unreadable>
    try:
        data = json.load(open(args[0], encoding="utf-8"))
    except (OSError, ValueError):
        print("<unreadable>"); sys.exit(0)
    v = data.get(args[1]) if isinstance(data, dict) else None
    print("<absent>" if v is None else v); sys.exit(0)
elif cmd == "record-edit":                    # <state> drop | legacy <root>
    try:
        data = json.load(open(args[0], encoding="utf-8"))
    except (OSError, ValueError) as err:
        print(f"record unreadable ({type(err).__name__})"); sys.exit(0)
    if not isinstance(data, dict):
        print("record is not a JSON object"); sys.exit(0)
    for k in ("source_repo_path", "source_repo_path_source"):
        data.pop(k, None)                     # drop: a pre-record install carries neither key
    if args[1] == "legacy":                   # legacy: a root, and no provenance key
        data["source_repo_path"] = args[2]
    elif args[1] != "drop":
        problems.append(f"unknown record edit {args[1]}")
    open(args[0], "w", encoding="utf-8").write(json.dumps(data, indent=2) + "\n")
elif cmd == "warn-names":                     # <log> <text>...: ONE WARN: line names every text
    if not any(l.startswith("WARN:") and all(t in l for t in args[1:]) for l in lines(args[0])):
        problems.append("no single WARN: line names " + " and ".join(args[1:]))
elif cmd == "gens":                           # <config-root> -> its snapshot generations
    print(" ".join(gens(args[0]))); sys.exit(0)
elif cmd == "new-gens":                       # <config-root> <generations-before> -> the new ones
    before = set(args[1].split())
    print(" ".join(g for g in gens(args[0]) if g not in before)); sys.exit(0)
elif cmd == "manifest-delta":                 # <before> <after>, manifest_dir output -> changed paths
    def load(f):
        m = {}
        for l in open(f, encoding="utf-8").read().splitlines():
            rel, sep, h = l.rpartition("  ")
            if sep:
                m[rel] = h
        return m
    a, b = load(args[0]), load(args[1])
    d = ([f"+{k}" for k in sorted(set(b) - set(a))] + [f"-{k}" for k in sorted(set(a) - set(b))]
         + [f"~{k}" for k in sorted(set(a) & set(b)) if a[k] != b[k]])
    print(" ".join(d[:5]) + (f" (+{len(d) - 5} more)" if len(d) > 5 else "")); sys.exit(0)
else:
    problems.append(f"unknown subcommand {cmd}")
print("OK" if not problems else "; ".join(problems))
PY
}

# ─────────────────────────────────────────────────────────────────────────────
# Arm 7 — THE INSTALL RECORD. The fixture, then an unattended install from its nested
# worktree with stdin held OPEN. The recorded root is compared with the fixture
# primary's physical path, which this suite computes itself: never with the output of
# the resolver under test.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 7: an unattended install from a linked worktree records the canonical root\n'

# Parity: the state file update.sh reads is the one setup-workspace.sh writes.
if grep -qF '.claude/.workspace-setup.state' "${UPDATE}" \
   && grep -qF 'STATE_FILE_NAME=".workspace-setup.state"' "${SETUP}"; then
  report "7: parity — update.sh reads the state file setup-workspace.sh writes" 1
else
  report "7: parity — update.sh reads the state file setup-workspace.sh writes" 0 \
    "update.sh must carry '.claude/.workspace-setup.state' and setup-workspace.sh 'STATE_FILE_NAME=\".workspace-setup.state\"'"
fi

if ! command -v git >/dev/null 2>&1; then
  FIXTURE_SKIP_REASON="git is not available, so the fixture repository and its worktrees cannot be built"
  skip_with_reason "Arm 7: the install record" "${FIXTURE_SKIP_REASON}"
elif ! fx_step="$(fx_build)"; then
  report "Arm 7: fixture built (a git repository from a copy of the working tree, two linked worktrees)" 0 \
    "failed at: ${fx_step}; see ${FX_LOG}"
else
  FX_PRIMARY_P="$(cd "${FX_PRIMARY}" && pwd -P)"
  FX_SCRATCH_P="$(cd "${FX_SCRATCH}" && pwd -P)"
  report "fixture built: a git repository from a copy of the working tree, a nested and an out-of-tree worktree" 1

  # Harness control: an install judged by this harness proves nothing about an open
  # stdin unless a reader under it is really held.
  hc_log="$(run_open_stdin 3 bash -c 'read -r _; exit 0' 2>&1)"
  hc_rc=$?
  if [ "${hc_rc}" -eq 124 ] && grep -qF 'OPEN-STDIN-HARNESS: TIMEOUT' <<<"${hc_log}"; then
    report "7: harness control — a stub that reads stdin is held, then timed out (stdin open and silent)" 1
  else
    report "7: harness control — a stub that reads stdin is held, then timed out (stdin open and silent)" 0 \
      "exit ${hc_rc} (want 124): the harness stdin delivered EOF or data, so the install below proves nothing about an open stdin"
  fi

  cat > "${FCFG}/operator.toml" <<TOML
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
claude_workspace_root = "${FWS}"
operator_homedir_path = "${SBX}/home"
cowork_install_path = "${SBX}/cowork"
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
  chmod 600 "${FCFG}/operator.toml"

  ( cd "${FX_W1}" && run_open_stdin "${OPEN_STDIN_BUDGET_S}" ./docs/scripts/setup-workspace.sh \
      --source-repo "${FX_W1}" --workspace-root "${FWS}" --config-root "${FCFG}" --non-interactive ) \
    >"${LOGS}/7-w1.log" 2>&1
  fx_install_rc=$?
  fx_start="$(grep -c '^OPEN-STDIN-HARNESS: START' "${LOGS}/7-w1.log" || true)"
  fx_timeout="$(grep -cF 'OPEN-STDIN-HARNESS: TIMEOUT' "${LOGS}/7-w1.log" || true)"
  if [ "${fx_install_rc}" -eq 0 ] && [ -f "${STATE}" ]; then FIXTURE_READY=1; fi
  if [ "${FIXTURE_READY}" -eq 1 ] && [ "${fx_start}" = "1" ] && [ "${fx_timeout}" = "0" ]; then
    report "7: the install from the nested worktree completes with stdin OPEN (exit 0, under the harness)" 1
  else
    report "7: the install from the nested worktree completes with stdin OPEN (exit 0, under the harness)" 0 \
      "exit ${fx_install_rc} (124 = still waiting on stdin after ${OPEN_STDIN_BUDGET_S}s); harness start=${fx_start}; timeout sentinel=${fx_timeout}; last lines: $(tail -4 "${LOGS}/7-w1.log" | tr '\n' '|')"
  fi

  if [ -f "${STATE}" ]; then
    rec_path="$(fx_py record-field "${STATE}" source_repo_path)"
    rec_src="$(fx_py record-field "${STATE}" source_repo_path_source)"
    case "${rec_path}" in
      ''|'<absent>'|'<unreadable>')
        report "7: source_repo_path is recorded, and is not empty" 0 "read '${rec_path}'" ;;
      *)
        report "7: source_repo_path is recorded, and is not empty" 1 ;;
    esac
    if [ "${rec_path}" = "${FX_PRIMARY_P}" ]; then
      report "7: source_repo_path is the fixture primary's physical path (pwd -P, computed by this suite)" 1
    else
      report "7: source_repo_path is the fixture primary's physical path (pwd -P, computed by this suite)" 0 \
        "recorded '${rec_path}', want '${FX_PRIMARY_P}'"
    fi
    if [ "${rec_src}" = "declared-source" ]; then
      report "7: source_repo_path_source names the tier that supplied the root (declared-source)" 1
    else
      report "7: source_repo_path_source names the tier that supplied the root (declared-source)" 0 "read '${rec_src}'"
    fi
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 8 — CALLER-INDEPENDENCE. Three refreshes, each run from its own tree, compose
# one surface set, and every [PMO_PLATFORM_ROOT] row names the main checkout.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 8: caller-independence — refreshes from three checkouts compose one surface set\n'
if [ "${FIXTURE_READY}" -ne 1 ]; then
  fx_unavailable "Arm 8: caller-independence"
else
  if fx_targets; then
    v="$(fx_py check-targets "${SBX}/targets.tsv" "${SBX}" \
          script-execution-allowlist.txt skill-editor-exemption-list.txt)"
  else
    v="target resolution failed (lib or manifest did not load)"
  fi
  FX_ALLOW="$(awk -F'\t' '$1 == "hook" && $2 ~ /\/script-execution-allowlist\.txt$/ { print $2 }' "${SBX}/targets.tsv" 2>/dev/null)"
  if [ "${v}" = "OK" ] && [ -n "${FX_ALLOW}" ] && [ -f "${FX_ALLOW}" ]; then
    ARM8_READY=1
    report "target set: every manifest row resolves inside the sandbox and exists (incl. the allowlist and the exemption list)" 1
  else
    report "target set resolves inside the sandbox and exists" 0 "${v}; allowlist target '${FX_ALLOW}'"
  fi
fi

if [ "${ARM8_READY}" -eq 1 ]; then
  awk -v s="${OPERATOR_SENTINEL}" -v m="${END_OPERATOR_MARKER}" '$0 == m { print s } { print }' \
    "${FX_ALLOW}" > "${FX_ALLOW}.sentinel" && mv "${FX_ALLOW}.sentinel" "${FX_ALLOW}"
  n="$(grep -cxF -- "${OPERATOR_SENTINEL}" "${FX_ALLOW}" || true)"
  [ "${n}" = "1" ] || report "8: operator sentinel planted in the fixture allowlist" 0 "found ${n}"
  ALL_KEYS="$(fx_py keys "${SBX}/targets.tsv")"
  for spec in "primary|${FX_PRIMARY}" "w1|${FX_W1}" "scratch|${FX_SCRATCH}"; do
    name="${spec%%|*}"; tree="${spec#*|}"; ok=1; detail=""
    v="$(fx_py stamp "${SBX}/targets.tsv")"; [ "${v}" = "OK" ] || { ok=0; detail="stamp: ${v}"; }
    fx_update "8-${name}" "${tree}" --surfaces-only --force-regen
    rc=$?
    [ "${rc}" -eq 0 ] || { ok=0; detail="${detail}; exit ${rc}"; }
    [ "$(fx_py unstamped "${SBX}/targets.tsv")" = "${ALL_KEYS}" ] \
      || { ok=0; detail="${detail}; not every target was rewritten by this run"; }
    t="$(grep -c '^WARN: tamper detected' "${LOGS}/8-${name}.err" || true)"
    [ "${t}" = "0" ] || { ok=0; detail="${detail}; ${t} tamper WARN(s) (the stamp must be inert)"; }
    n="$(grep -cxF -- "${OPERATOR_SENTINEL}" "${FX_ALLOW}" || true)"
    [ "${n}" = "1" ] || { ok=0; detail="${detail}; operator sentinel count ${n}"; }
    v="$(fx_py snapshot "${SBX}/targets.tsv" "${SNAP}/8-${name}")"; [ "${v}" = "OK" ] || { ok=0; detail="${detail}; ${v}"; }
    report "8-${name}: every target rewritten by this run; operator sentinel kept" "${ok}" "${detail}"
    if [ "${name}" != "primary" ]; then     # the primary IS the canonical root, so it is named by design
      h="$(fx_py caller-hits "${SBX}/targets.tsv" "${tree}")"
      if [ "${h}" = "0" ]; then
        report "8-${name}: no deployed line names the invoking checkout" 1
      else
        report "8-${name}: no deployed line names the invoking checkout" 0 "${h} line(s)"
      fi
    fi
    v="$(fx_py root-probe "${FX_ALLOW}" "${tree}/${FX_TPL_REL}" "${FX_PRIMARY_P}")"
    if [ "${v}" = "OK" ]; then
      report "8-${name}: every [PMO_PLATFORM_ROOT] row is bound to the main checkout (root probe)" 1
    else
      report "8-${name}: every [PMO_PLATFORM_ROOT] row is bound to the main checkout (root probe)" 0 "${v}"
    fi
  done
  for other in w1 scratch; do
    d="$(fx_py diffset "${SNAP}/8-primary" "${SNAP}/8-${other}")"
    if [ -z "${d}" ]; then
      report "8: the ${other} refresh composes the main-checkout refresh's surface set (managed_at aside)" 1
    else
      report "8: the ${other} refresh composes the main-checkout refresh's surface set" 0 "differing: ${d}"
    fi
  done
  # Instrument sensitivity. On a scratch COPY of the main-checkout snapshot, re-root
  # exactly one token row: the comparison must name the allowlist, and the root probe
  # must report exactly one row missing. Nothing deployed is touched.
  rows="$(fx_py token-rows "${FX_PRIMARY}/${FX_TPL_REL}")"
  v="$(fx_py reroot-copy "${SNAP}/8-primary" "${SNAP}/8-sens" hook-script-execution-allowlist.txt \
        "${FX_PRIMARY_P}" "${FX_SCRATCH_P}")"
  d="$(fx_py diffset "${SNAP}/8-primary" "${SNAP}/8-sens")"
  p="$(fx_py root-probe "${SNAP}/8-sens/hook-script-execution-allowlist.txt" \
        "${FX_PRIMARY}/${FX_TPL_REL}" "${FX_PRIMARY_P}")"
  if [ "${v}" = "OK" ] && [ "${d}" = "hook-script-execution-allowlist.txt" ] && [ "${p}" = "MISSING=1 of ${rows}" ]; then
    report "8: instrument sensitivity — one re-rooted row is seen by the comparison and by the root probe" 1
  else
    report "8: instrument sensitivity — one re-rooted row is seen by the comparison and by the root probe" 0 \
      "copy: ${v}; comparison names '${d}' (want the allowlist); probe '${p}' (want MISSING=1 of ${rows})"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 8c — the CONTROL: a branch worktree changes the set by exactly its rows.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 8c: control — a branch worktree changes the set by exactly its branch-only rows\n'
if [ "${ARM8_READY}" -ne 1 ]; then
  if [ "${FIXTURE_READY}" -ne 1 ]; then
    fx_unavailable "Arm 8c: differing-source control"
  else
    report "Arm 8c: differing-source control" 0 "not run: Arm 8's target set did not resolve (see its target-set line)"
  fi
# No `-q` on this worktree add: older command-line-tools git lacks `worktree add --quiet`.
elif ! fx_git -C "${FX_PRIMARY}" worktree add -b fx-branch-rows "${FX_WB}" >"${LOGS}/8c-setup.log" 2>&1; then
  report "Arm 8c: differing-source control" 0 "the branch worktree could not be added; see ${LOGS}/8c-setup.log"
else
  printf '%s\n' \
    '# fixture: branch-only rows (differing-source control)' \
    '[PMO_PLATFORM_ROOT]/release/tools/fixture-branch-only.sh' \
    '[PMO_PLATFORM_ROOT]/.claude/worktrees/*/release/tools/fixture-branch-only.sh' \
    './release/tools/fixture-branch-only.sh' \
    'release/tools/fixture-branch-only.sh' \
    >> "${FX_WB}/${FX_TPL_REL}"
  fx_git -C "${FX_WB}" commit -q -am 'fixture: branch-only rows' >>"${LOGS}/8c-setup.log" 2>&1
  ok=1; detail=""
  v="$(fx_py stamp "${SBX}/targets.tsv")"; [ "${v}" = "OK" ] || { ok=0; detail="stamp: ${v}"; }
  fx_update 8c-wb "${FX_WB}" --surfaces-only
  rc=$?
  [ "${rc}" -eq 0 ] || { ok=0; detail="${detail}; exit ${rc}"; }
  u="$(fx_py unstamped "${SBX}/targets.tsv")"
  [ "${u}" = "hook-script-execution-allowlist.txt" ] || { ok=0; detail="${detail}; rewritten '${u}' (want the allowlist only)"; }
  t="$(grep -c '^WARN: tamper detected' "${LOGS}/8c-wb.err" || true)"
  [ "${t}" = "0" ] || { ok=0; detail="${detail}; ${t} tamper WARN(s)"; }
  h="$(fx_py caller-hits "${SBX}/targets.tsv" "${FX_WB}")"
  [ "${h}" = "0" ] || { ok=0; detail="${detail}; ${h} line(s) name the branch worktree"; }
  n="$(grep -cxF -- "${OPERATOR_SENTINEL}" "${FX_ALLOW}" || true)"
  [ "${n}" = "1" ] || { ok=0; detail="${detail}; operator sentinel count ${n}"; }
  v="$(fx_py snapshot "${SBX}/targets.tsv" "${SNAP}/8c-wb")"; [ "${v}" = "OK" ] || { ok=0; detail="${detail}; ${v}"; }
  d="$(fx_py diffset "${SNAP}/8-primary" "${SNAP}/8c-wb")"
  [ "${d}" = "hook-script-execution-allowlist.txt" ] || { ok=0; detail="${detail}; differing '${d}' (want the allowlist only)"; }
  v="$(fx_py allowlist-delta "${SNAP}/8-primary/hook-script-execution-allowlist.txt" \
        "${SNAP}/8c-wb/hook-script-execution-allowlist.txt" \
        "${FX_PRIMARY}/${FX_TPL_REL}" "${FX_WB}/${FX_TPL_REL}" "${FX_PRIMARY_P}")"
  [ "${v}" = "OK" ] || { ok=0; detail="${detail}; ${v}"; }
  report "8c: the branch refresh adds exactly its branch-only block, bound to the main checkout" "${ok}" "${detail}"
  v="$(fx_py root-probe "${FX_ALLOW}" "${FX_WB}/${FX_TPL_REL}" "${FX_PRIMARY_P}")"
  if [ "${v}" = "OK" ]; then
    report "8c: every token row, the two branch rows included, is bound to the main checkout (root probe)" 1
  else
    report "8c: every token row, the two branch rows included, is bound to the main checkout (root probe)" 0 "${v}"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 9 — PRE-RECORD FALLBACK. The record's root keys removed (a pre-record install
# carries neither), a forced refresh from the nested worktree still binds the main
# working tree; the stamp proves this run rewrote what the probe reads.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 9: pre-record fallback — with no recorded root, a refresh binds the main working tree\n'
if [ "${FIXTURE_READY}" -ne 1 ]; then
  fx_unavailable "Arm 9: pre-record fallback"
elif [ "${ARM8_READY}" -ne 1 ]; then
  report "Arm 9: pre-record fallback" 0 "not run: Arm 8's target set did not resolve (see its target-set line)"
else
  cp "${STATE}" "${SBX}/state.before-arm9"
  ok=1; detail=""
  v="$(fx_py record-edit "${STATE}" drop)"; [ "${v}" = "OK" ] || { ok=0; detail="record edit: ${v}"; }
  v="$(fx_py stamp "${SBX}/targets.tsv")"; [ "${v}" = "OK" ] || { ok=0; detail="${detail}; stamp: ${v}"; }
  fx_update 9-w1 "${FX_W1}" --surfaces-only --force-regen
  rc=$?
  [ "${rc}" -eq 0 ] || { ok=0; detail="${detail}; exit ${rc}"; }
  [ "$(fx_py unstamped "${SBX}/targets.tsv")" = "${ALL_KEYS}" ] \
    || { ok=0; detail="${detail}; not every target was rewritten by this run"; }
  report "9-w1: with no recorded root, every target is rewritten by this run" "${ok}" "${detail}"
  v="$(fx_py root-probe "${FX_ALLOW}" "${FX_W1}/${FX_TPL_REL}" "${FX_PRIMARY_P}")"
  if [ "${v}" = "OK" ]; then
    report "9-w1: every token row is bound to the main working tree (root probe)" 1
  else
    report "9-w1: every token row is bound to the main working tree (root probe)" 0 "${v}"
  fi
  cp "${SBX}/state.before-arm9" "${STATE}"
  if cmp -s "${SBX}/state.before-arm9" "${STATE}"; then
    report "9: install record restored byte-identically for the arms that follow" 1
  else
    report "9: install record restored for the arms that follow" 0 "restore did not take"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 9b — LEGACY RECORD. A record without source_repo_path_source that names another
# existing clone is advisory: the refresh binds the main working tree, and one WARN
# names both roots.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 9b: a legacy record naming another existing clone is advisory, not binding\n'
if [ "${FIXTURE_READY}" -ne 1 ]; then
  fx_unavailable "Arm 9b: legacy record"
elif [ "${ARM8_READY}" -ne 1 ]; then
  report "Arm 9b: legacy record" 0 "not run: Arm 8's target set did not resolve (see its target-set line)"
elif ! fx_git clone -q "${FX_PRIMARY}" "${FX_OTHER}" >"${LOGS}/9b-setup.log" 2>&1; then
  report "Arm 9b: legacy record" 0 "the second clone could not be made; see ${LOGS}/9b-setup.log"
else
  FX_OTHER_P="$(cd "${FX_OTHER}" && pwd -P)"
  cp "${STATE}" "${SBX}/state.before-arm9b"
  ok=1; detail=""
  v="$(fx_py record-edit "${STATE}" legacy "${FX_OTHER_P}")"; [ "${v}" = "OK" ] || { ok=0; detail="record edit: ${v}"; }
  v="$(fx_py stamp "${SBX}/targets.tsv")"; [ "${v}" = "OK" ] || { ok=0; detail="${detail}; stamp: ${v}"; }
  fx_update 9b-w1 "${FX_W1}" --surfaces-only --force-regen
  rc=$?
  [ "${rc}" -eq 0 ] || { ok=0; detail="${detail}; exit ${rc}"; }
  [ "$(fx_py unstamped "${SBX}/targets.tsv")" = "${ALL_KEYS}" ] \
    || { ok=0; detail="${detail}; not every target was rewritten by this run"; }
  report "9b-w1: with a legacy record, every target is rewritten by this run" "${ok}" "${detail}"
  v="$(fx_py root-probe "${FX_ALLOW}" "${FX_W1}/${FX_TPL_REL}" "${FX_PRIMARY_P}")"
  if [ "${v}" = "OK" ]; then
    report "9b-w1: every token row is bound to the main working tree, not the recorded clone (root probe)" 1
  else
    report "9b-w1: every token row is bound to the main working tree, not the recorded clone (root probe)" 0 "${v}"
  fi
  h="$(fx_py caller-hits "${SBX}/targets.tsv" "${FX_OTHER}")"
  if [ "${h}" = "0" ]; then
    report "9b-w1: no deployed line names the recorded clone" 1
  else
    report "9b-w1: no deployed line names the recorded clone" 0 "${h} line(s)"
  fi
  v="$(fx_py warn-names "${LOGS}/9b-w1.err" "${FX_OTHER_P}" "${FX_PRIMARY_P}")"
  if [ "${v}" = "OK" ]; then
    report "9b-w1: one WARN names both roots (the recorded clone and the main working tree)" 1
  else
    report "9b-w1: one WARN names both roots (the recorded clone and the main working tree)" 0 "${v}"
  fi
  cp "${SBX}/state.before-arm9b" "${STATE}"
  if cmp -s "${SBX}/state.before-arm9b" "${STATE}"; then
    report "9b: install record restored byte-identically for the arms that follow" 1
  else
    report "9b: install record restored for the arms that follow" 0 "restore did not take"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 10 — THE HEAL. The allowlist is re-rooted to the out-of-tree worktree with its
# hashes reset the way a pre-fix install leaves them; a PLAIN refresh heals it.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 10: a poisoned install heals on a plain refresh\n'
if [ "${FIXTURE_READY}" -ne 1 ]; then
  fx_unavailable "Arm 10: the heal"
elif [ "${ARM8_READY}" -ne 1 ]; then
  report "Arm 10: the heal" 0 "not run: Arm 8's target set did not resolve (see its target-set line)"
else
  rows="$(fx_py token-rows "${FX_W1}/${FX_TPL_REL}")"
  # The stamp comes first. Every composed file carries its managed_at marker on line 4,
  # below its installed_sha line; the poison drops that line, so a stamp taken after it
  # finds no marker on the poisoned surface's line 4.
  ok=1; detail=""
  v="$(fx_py stamp "${SBX}/targets.tsv")"; [ "${v}" = "OK" ] || { ok=0; detail="stamp: ${v}"; }
  v="$(fx_py poison "${FX_ALLOW}" "${FX_W1}/${FX_TPL_REL}" "${FX_SCRATCH_P}")"
  p="$(fx_py root-probe "${FX_ALLOW}" "${FX_W1}/${FX_TPL_REL}" "${FX_PRIMARY_P}")"
  case "${v}|${p}" in
    "OK|MISSING=${rows} of ${rows}"*)
      report "10: sensitivity — on the poisoned surface the root probe reports every token row missing" 1 ;;
    *)
      report "10: sensitivity — on the poisoned surface the root probe reports every token row missing" 0 \
        "poison: ${v}; probe: ${p}" ;;
  esac
  h="$(fx_py caller-hits "${SBX}/targets.tsv" "${FX_SCRATCH}")"
  if [ "${rows}" -gt 0 ] && [ "${h}" -ge "${rows}" ]; then
    report "10: caller-path probe fires on the poisoned surface (${h} >= ${rows} token rows)" 1
  else
    report "10: caller-path probe fires on the poisoned surface" 0 "hits ${h}, token rows ${rows}"
  fi
  fx_update 10-w1 "${FX_W1}" --surfaces-only --dry-run
  rc=$?
  [ "${rc}" -eq 0 ] || { ok=0; detail="${detail}; exit ${rc}"; }
  u="$(fx_py unstamped "${SBX}/targets.tsv")"
  [ "${u}" = "hook-script-execution-allowlist.txt" ] \
    || { ok=0; detail="${detail}; rewritten '${u}' (want the poisoned allowlist only)"; }
  # The poisoned surface reads as unstamped whether or not this run rewrote it: the
  # poison left no marker on its line 4. The snapshot's check needs one there, which
  # only a composition write restores; with the check above, it is this run's write.
  v="$(fx_py snapshot "${SBX}/targets.tsv" "${SNAP}/10-w1")"; [ "${v}" = "OK" ] || { ok=0; detail="${detail}; ${v}"; }
  report "10-w1: a plain refresh (no --force-regen) regenerates exactly the poisoned surface" "${ok}" "${detail}"
  v="$(fx_py root-probe "${FX_ALLOW}" "${FX_W1}/${FX_TPL_REL}" "${FX_PRIMARY_P}")"
  if [ "${v}" = "OK" ]; then
    report "10-w1: after the heal, every token row is bound to the main checkout (root probe)" 1
  else
    report "10-w1: after the heal, every token row is bound to the main checkout (root probe)" 0 "${v}"
  fi
  h="$(fx_py caller-hits "${SBX}/targets.tsv" "${FX_SCRATCH}")"
  if [ "${h}" = "0" ]; then
    report "10: after the heal, no line names the scratchpad worktree" 1
  else
    report "10: after the heal, no line names the scratchpad worktree" 0 "${h} line(s)"
  fi
  printf '         diagnostic (not graded): %s\n' "$(fx_py segment-counts "${FX_ALLOW}" "${FX_SCRATCH_P}")"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 12 — THE CONFIG ROOT IS NOT A FALLBACK. A full update given --config-root must
# write only there. A child it delegates to without that flag falls back to the
# DEFAULT config root (PMO_PLATFORM_CONFIG_ROOT, else the operator's own). Here the
# default is a byte copy of the given root, so such a write lands where this arm can
# see it, and nothing outside the sandbox is ever at risk. The copy is in sync with
# the declared schema, so a phase that only reads the default root reads the same
# answers it would read from the given one.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 12: a sandboxed full update writes only the config root it was given\n'
PA_CFG="${SBX}/config"
PA_DEFAULT="${SBX}/default-config"
if [ ! -d "${SBX}/ws/.claude/hooks" ] || [ -z "$(ls -A "${SBX}/ws/.claude/hooks" 2>/dev/null)" ]; then
  report "Arm 12: the config root is not a fallback" 0 \
    "precondition: no deployed hooks in the sandbox workspace, so the hook refresh would skip and this arm could not fail"
elif ! cp -Rp "${PA_CFG}" "${PA_DEFAULT}"; then
  report "Arm 12: the config root is not a fallback" 0 "could not copy the given config root to stand in for the default"
else
  pa_before="$(fx_py gens "${PA_CFG}")"
  manifest_dir "${PA_DEFAULT}" > "${SBX}/pa-default.before"
  ( cd "${REPO_ROOT}" && PMO_PLATFORM_CONFIG_ROOT="${PA_DEFAULT}" bash ./update.sh \
      --config-root "${PA_CFG}" --workspace-root "${SBX}/ws" ) >"${LOGS}/12-full.out" 2>"${LOGS}/12-full.err"
  rc=$?
  manifest_dir "${PA_DEFAULT}" > "${SBX}/pa-default.after"
  new="$(fx_py new-gens "${PA_CFG}" "${pa_before}")"
  if [ -n "${new}" ] && [ "${new}" = "${new%% *}" ]; then
    report "12: the hook refresh ran and took its snapshot in the given config root (1 new generation)" 1
  else
    report "12: the hook refresh ran and took its snapshot in the given config root (1 new generation)" 0 \
      "new generations in the given root: '${new}' (want exactly one); update exit ${rc}"
  fi
  d="$(fx_py manifest-delta "${SBX}/pa-default.before" "${SBX}/pa-default.after")"
  if [ -z "${d}" ]; then
    report "12: the default config root is byte-identical after the run" 1
  else
    report "12: the default config root is byte-identical after the run" 0 "changed: ${d}"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Arm 6 — LEAKAGE BACKSTOP. LAST, so every mutating arm above falls inside its compare.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nArm 6: leakage backstop — the real home is untouched\n'

LIVE_SKILLS_AFTER="$(manifest_dir "${REAL_SKILLS}")"
[ "${LIVE_SKILLS_BEFORE}" = "${LIVE_SKILLS_AFTER}" ] \
  && report "real ~/.claude/skills byte-identical to the Arm-0 baseline" 1 \
  || report "real ~/.claude/skills byte-identical to the Arm-0 baseline" 0 "an invocation escaped its sandbox"

LIVE_ALLOWLIST_AFTER=""
[ -f "${REAL_ALLOWLIST}" ] && LIVE_ALLOWLIST_AFTER="$(sha "${REAL_ALLOWLIST}")"
[ "${LIVE_ALLOWLIST_BEFORE}" = "${LIVE_ALLOWLIST_AFTER}" ] \
  && report "real deployed allowlist byte-identical to the Arm-0 baseline" 1 \
  || report "real deployed allowlist byte-identical to the Arm-0 baseline" 0 "an invocation escaped its sandbox"

LIVE_RECORD_AFTER=""
[ -f "${REAL_INSTALL_RECORD}" ] && LIVE_RECORD_AFTER="$(sha "${REAL_INSTALL_RECORD}")"
if [ "${LIVE_RECORD_BEFORE}" = "${LIVE_RECORD_AFTER}" ]; then
  report "real install record byte-identical to the Arm-0 baseline" 1
else
  report "real install record byte-identical to the Arm-0 baseline" 0 "an invocation escaped its sandbox"
fi

# ─────────────────────────────────────────────────────────────────────────────
printf '\ntest_refresh_surfaces.sh: %d passed, %d failed, %d skipped (bash %s)\n' \
  "${PASS}" "${FAIL}" "${SKIP}" "${BASH_VERSION:-unknown}"
[ "${FAIL}" -eq 0 ] || exit 1
exit 0

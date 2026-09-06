#!/usr/bin/env bash
# test_refresh_surfaces.sh — regression for the targeted composition-surface refresh
# (./update.sh --surfaces-only) and for deploy.sh's scope-honest no-op message.
#
# THE DEFECT THIS GUARDS
#   core/config/allowlists/script-execution-allowlist.txt is a COMPOSITION SURFACE.
#   The composition-surface manifest is sourced only by setup-workspace.sh and
#   update.sh; deploy.sh never sources it. So `deploy.sh --deploy` exits 0 reporting
#   "Nothing to deploy" while being structurally incapable of refreshing that file —
#   and for a long time that command was the recorded remediation for a stale
#   allowlist. The remediation was never executable.
#
# WHAT THE ARMS PROVE, AND WHY EACH ONE EXISTS
#   Arm 0  hermetic PRE-FLIGHT. Isolation is a PRECONDITION, not a postmortem: the
#          suite REFUSES TO START unless HOME and both root overrides resolve inside
#          the sandbox. deploy.sh's write targets reduce to two env vars
#          (PMO_PLATFORM_DEPLOY_ROOT, PMO_PLATFORM_CONFIG_ROOT); ${var:-default}
#          collapses an exported-but-EMPTY var back to $HOME, so emptiness is checked
#          explicitly, not just presence. Baseline manifests of the REAL home are
#          captured here and re-compared at Arm 6.
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
#   Arm 6  LEAKAGE BACKSTOP. The real home is byte-identical to the Arm-0 baseline.
#          A backstop, not the control — Arm 0 is the control.
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

SBX="$(mktemp -d -t refresh-surfaces.XXXXXX)" || abort_preflight "could not create sandbox"
cleanup() { [ -n "${SBX:-}" ] && [ -d "${SBX}" ] && rm -rf "${SBX}"; }
trap cleanup EXIT

mkdir -p "${SBX}/config" "${SBX}/ws" "${SBX}/home"

# The two roots deploy.sh derives every write target from, plus HOME itself.
export HOME="${SBX}/home"
export PMO_PLATFORM_DEPLOY_ROOT="${SBX}/home"
export PMO_PLATFORM_CONFIG_ROOT="${SBX}/config"

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

# Baselines of the REAL home, captured BEFORE any invocation (re-compared at Arm 6).
LIVE_SKILLS_BEFORE="$(manifest_dir "${REAL_SKILLS}")"
LIVE_ALLOWLIST_BEFORE=""
[ -f "${REAL_ALLOWLIST}" ] && LIVE_ALLOWLIST_BEFORE="$(sha "${REAL_ALLOWLIST}")"

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
# Arm 6 — LEAKAGE BACKSTOP.
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

# ─────────────────────────────────────────────────────────────────────────────
printf '\ntest_refresh_surfaces.sh: %d passed, %d failed, %d skipped (bash %s)\n' \
  "${PASS}" "${FAIL}" "${SKIP}" "${BASH_VERSION:-unknown}"
[ "${FAIL}" -eq 0 ] || exit 1
exit 0

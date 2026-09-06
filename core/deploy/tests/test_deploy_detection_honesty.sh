#!/usr/bin/env bash
# test_deploy_detection_honesty.sh — `--deploy` selects against ground truth
#
# THE DEFECT THIS GUARDS. `deploy.sh --deploy` reported "Deployed: 0 skills" and
# exit 0 while the installed corpus sat six days behind source. detect_changed_skills
# answers "what changed in the repository since the last tag"; the deploy path used
# that as a PROXY for "what is missing from the installed corpus". The proxy is valid
# only under an unstated, unenforced and structurally unrepresentable precondition —
# that the instance was last deployed at exactly diff_base. One commit past the tag it
# stops firing, and a release's own skill edits leave the window permanently. The
# output of that failure is byte-identical to a correct run, so nothing downstream
# could tell the two apart.
#
# THE FIX THIS ASSERTS. skill_content_drift() asks the ground-truth question — does
# the installed content match source right now — and cmd_deploy unions its answer into
# the candidate set BEFORE the E-02 early exit, then re-asserts zero residual after the
# deploy loop, appending to the existing FAILURES array so the existing terminal die
# produces the non-zero exit.
#
# FOUR ARMS. Each is stated with what it would catch, because an arm whose failure mode
# is not named is an arm nobody can tell is vacuous:
#
#   A — CONTROL (genuine no-op still succeeds). A second deploy over an already-current
#       instance exits 0 and reports no skills changed. Without this arm a "fix" that
#       simply always reports failure, or always re-copies, would pass every other arm.
#       This is the deploy-side half of the EX_NOCHANGE(64) contract that update.sh
#       reads: skills_changed is footprint-derived, so widening the CANDIDATE set must
#       not inflate the REPORTED count. test_upgrade_config_durability.sh Suite F
#       remains the end-to-end EX_NOCHANGE guard; this composes with it, not replaces it.
#
#   B — THE DEFECT (the regression arm). An installed SKILL.md is perturbed so it
#       diverges from source with NO git change — content-equivalent to the tag-window
#       slip and deterministic to stage. The probe skill is CHOSEN AT RUN TIME as a
#       roster skill outside the tag-diff window, and the arm asserts that exclusion
#       itself, so the arm cannot accidentally test a skill the old detector could see.
#       On pre-fix code this reports 0 skills, exits 0, and leaves the copy stale.
#
#   C — UNREPAIRABLE DRIFT EXITS NON-ZERO. As B, plus an unwritable target. The deploy
#       cannot heal it, so the residual assertion must fire, name the skill, and carry
#       the chmod remedy. This is what reserves the non-zero exit for drift that
#       survives the repair rather than for drift as such.
#
#   D — ANTI-VACUITY / SPECIFICITY (the arm that would not otherwise be written). A
#       fully-current instance carries TEMPLATE_SYNC_MAP-injected references/ files that
#       are absent from source by single-source-of-truth design. The drift set must be
#       EMPTY. Its own sensitivity control runs the identical comparison WITHOUT the
#       injected-basename exclusion over the identical population and must flag a
#       NON-ZERO count — measured at 12 of 55 roster skills. Without the exclusion the
#       union re-selects skills no deploy can ever make match (an unterminating repair
#       loop) and the residual assertion can never clear (a permanently red deploy);
#       a build that omits it passes A and B and then fails forever.
#
# HERMETIC BY CONSTRUCTION. Every deploy invocation runs under a redirected HOME
# pointed at a throwaway sandbox AND an explicit PMO_PLATFORM_DEPLOY_ROOT override, so
# the test can never write to the operator's real ~/.claude/skills on any machine —
# including one with a pinned [paths].cowork_install_path, since the redirected HOME
# also redirects the config-root fallback detect_install_path reads. A manifest of the
# live tree is compared before and after as a belt-and-suspenders proof that no
# invocation escaped its sandbox.
#
# Run from anywhere (resolves repo root from its own location):
#   bash core/deploy/tests/test_deploy_detection_honesty.sh
#
# deploy.sh resolves skill source dirs relative to CWD ($module/skills/<name>), so this
# test cd's to the repo root before each invocation.
#
# Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DEPLOY="${REPO_ROOT}/core/deploy/deploy.sh"

PASS=0
FAIL=0
SBX=""      # PMO_PLATFORM_DEPLOY_ROOT sandbox (the deploy target root)
SBH=""      # redirected HOME (config-root + Cowork-session resolution)

cleanup() {
  local d
  for d in "${SBX}" "${SBH}"; do
    if [ -n "${d}" ] && [ -d "${d}" ]; then
      # Arm C deliberately makes a target unwritable; restore write permission so
      # the sandbox can be removed. Failure here is not a test failure.
      chmod -R u+w "${d}" 2>/dev/null || true
      rm -rf "${d}" 2>/dev/null || true
    fi
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
    [ -n "${detail}" ] && printf '        %s\n' "${detail}"
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

# Manifest of a directory: sorted "relpath  hash" lines. Empty (exit 0) when the
# directory does not exist, so a machine with no live ~/.claude/skills still gets a
# stable before/after comparison.
manifest_dir() {
  local root="$1"
  [ -d "${root}" ] || return 0
  local f
  while IFS= read -r f; do
    printf '%s  %s\n' "${f#"${root}"/}" "$(hash_file "${f}")"
  done < <(find "${root}" -type f 2>/dev/null | LC_ALL=C sort)
}

# The EXACT pipeline detect_changed_skills uses (deploy.sh: diff_base resolution +
# the module-aware sed). Reproduced rather than invoked because deploy.sh runs main()
# unconditionally at load and cannot be sourced for one helper. Any divergence between
# this and the real detector would show up as arm B's exclusion assertion failing —
# which is why that assertion is made rather than assumed.
tag_window_skills() {
  local base tag prev
  tag="$(git describe --tags --abbrev=0 2>/dev/null)" || tag=""
  if [ -n "${tag}" ]; then
    if git describe --tags --exact-match HEAD >/dev/null 2>&1; then
      prev="$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null)" || prev=""
      if [ -n "${prev}" ]; then base="${prev}"; else base="HEAD~1"; fi
    else
      base="${tag}"
    fi
  else
    base="HEAD~1"
  fi
  git diff --name-only "${base}"..HEAD -- 'operations/skills/' 'release/skills/' 'core/skills/' 2>/dev/null \
    | sed -n 's|[^/]*/skills/\([^/]*\)/.*|\1|p' | LC_ALL=C sort -u
}

# Resolve a skill name to its module by directory presence (the same three subtrees
# resolve_skill_module iterates).
skill_module() {
  local s="$1" m
  for m in operations release core; do
    if [ -d "${REPO_ROOT}/${m}/skills/${s}" ]; then printf '%s' "${m}"; return 0; fi
  done
  return 1
}

run_deploy() {
  # One sandboxed deploy. $1 = log file; remaining args forwarded to --deploy.
  # Echoes nothing; sets DEPLOY_RC.
  local logf="$1"; shift
  (
    cd "${REPO_ROOT}" || exit 1
    HOME="${SBH}" PMO_PLATFORM_DEPLOY_ROOT="${SBX}" bash "${DEPLOY}" --deploy "$@"
  ) >"${logf}" 2>&1
  DEPLOY_RC=$?
  return 0
}

printf 'deploy.sh --deploy: ground-truth selection + residual assertion (#5564)\n'
printf -- '─────────────────────────────────────────────────────────────────────────\n'

# --- Preflight ---
if [ ! -f "${DEPLOY}" ]; then
  printf 'FAIL: deploy.sh not found at %s\n' "${DEPLOY}"
  exit 1
fi

SBX="$(mktemp -d -t deploy-honesty-root.XXXXXX)"
SBH="$(mktemp -d -t deploy-honesty-home.XXXXXX)"
MIRROR="${SBX}/.claude/skills"

LIVE_SKILLS="${HOME}/.claude/skills"
LIVE_BEFORE="$(manifest_dir "${LIVE_SKILLS}")"

# --- Seed: a full-roster deploy into the empty sandbox -----------------------
# should_full_roster() fires on an empty user-local mirror, so this lands the whole
# roster and leaves the sandbox FULLY CURRENT by construction — which is the
# precondition arms A and D need, and it is established rather than assumed.
run_deploy "${SBX}/seed.log"
SEED_RC="${DEPLOY_RC}"

ROSTER_N=0
if [ -d "${MIRROR}" ]; then
  ROSTER_N="$(find "${MIRROR}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
fi

if [ "${SEED_RC}" -eq 0 ] && [ "${ROSTER_N}" -gt 0 ]; then
  report "seed: full-roster deploy into an empty sandbox exits 0 (${ROSTER_N} skills landed)" 1
else
  report "seed: full-roster deploy into an empty sandbox exits 0" 0 \
    "rc=${SEED_RC}, skills landed=${ROSTER_N}; see ${SBX}/seed.log"
  printf '\nSeed failed — remaining arms cannot be evaluated against a known-current instance.\n'
  printf 'test_deploy_detection_honesty.sh: %d passed, %d failed\n' "${PASS}" "$((FAIL + 1))"
  exit 1
fi

# ── Arm D sensitivity control, measured on the seeded instance ───────────────
# Runs the SAME source-vs-installed references/ comparison the predicate runs, but
# WITHOUT the TEMPLATE_SYNC_MAP exclusion, over the SAME population. It MUST flag a
# non-zero count; a zero here means the near-miss input is absent and arm D below
# would be vacuous rather than passing.
BARE_FLAGGED=0
BARE_NAMES=""
while IFS= read -r sk; do
  [ -n "${sk}" ] || continue
  m="$(skill_module "${sk}")" || continue
  [ -d "${REPO_ROOT}/${m}/skills/${sk}/references" ] || continue
  [ -d "${MIRROR}/${sk}/references" ] || continue
  if ! diff -rq "${REPO_ROOT}/${m}/skills/${sk}/references" "${MIRROR}/${sk}/references" >/dev/null 2>&1; then
    BARE_FLAGGED=$((BARE_FLAGGED + 1))
    BARE_NAMES="${BARE_NAMES}${sk} "
  fi
done < <(find "${MIRROR}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while IFS= read -r d; do basename "${d}"; done | LC_ALL=C sort)

# --- Arm A: control — a genuine no-op still succeeds and reports zero --------
printf '\nArm A — control: genuine no-op deploy still succeeds\n'
run_deploy "${SBX}/run-noop.log"
NOOP_RC="${DEPLOY_RC}"

if [ "${NOOP_RC}" -eq 0 ]; then
  report "no-op deploy exits 0" 1
else
  report "no-op deploy exits 0" 0 "rc=${NOOP_RC}; see ${SBX}/run-noop.log"
fi

# The EX_NOCHANGE-relevant property: the summary's skills field must stay 0 (or the
# E-02 branch must be taken, which emits no summary at all). update.sh defaults
# skills_deployed to 0 when the line is absent, so both states keep PHASE5_DEPLOYED
# at 0 and exit 64 reachable. A summary reporting N>=1 on a no-op is the #384 v3.91
# regression this guards.
if grep -qE 'Deployed: [1-9][0-9]* skills' "${SBX}/run-noop.log" 2>/dev/null; then
  report "no-op reports zero skills changed (footprint-derived count not inflated)" 0 \
    "summary claimed a non-zero skills count on a no-op re-run"
else
  report "no-op reports zero skills changed (footprint-derived count not inflated)" 1
fi

# --- Arm D: anti-vacuity / specificity — injected refs are NOT drift ---------
printf '\nArm D — specificity: TEMPLATE_SYNC_MAP-injected files are not drift\n'

# Non-vacuity first: the near-miss input must actually be present in the target.
INJECTED_N="$(find "${MIRROR}" -type f -name 'template-*.md' 2>/dev/null | wc -l | tr -d ' ')"
if [ "${INJECTED_N}" -gt 0 ]; then
  report "near-miss input present: ${INJECTED_N} injected template file(s) in the target, absent from source" 1
else
  report "near-miss input present: injected template files in the target" 0 \
    "found none — arm D would be vacuous"
fi

if [ "${BARE_FLAGGED}" -gt 0 ]; then
  report "SENSITIVITY: the same comparison WITHOUT the exclusion flags ${BARE_FLAGGED} of ${ROSTER_N} roster skills" 1
else
  report "SENSITIVITY: the same comparison WITHOUT the exclusion flags a non-zero count" 0 \
    "flagged 0 — the arm cannot distinguish an applied exclusion from an absent near-miss"
fi

# The subject: with the exclusion applied (the shipped predicate, exercised through
# --deploy), the fully-current instance yields no ground-truth drift at all.
if grep -q 'Ground-truth scan:' "${SBX}/run-noop.log" 2>/dev/null; then
  report "SUBJECT: fully-current instance yields an EMPTY ground-truth drift set" 0 \
    "the deploy reported stale skills on an instance it had just made current: $(grep 'Ground-truth scan:' "${SBX}/run-noop.log" | head -1)"
else
  report "SUBJECT: fully-current instance yields an EMPTY ground-truth drift set (${BARE_FLAGGED} -> 0 with the exclusion)" 1
fi

# --- Probe selection for arms B and C ---------------------------------------
# A roster skill the tag-diff window CANNOT see. Chosen at run time from live state
# so the arm stays correct as the window moves.
WINDOW="$(cd "${REPO_ROOT}" && tag_window_skills)"
PROBE=""
while IFS= read -r sk; do
  [ -n "${sk}" ] || continue
  case "
${WINDOW}
" in
    *"
${sk}
"*) continue ;;
  esac
  skill_module "${sk}" >/dev/null 2>&1 || continue
  PROBE="${sk}"
  break
done < <(find "${MIRROR}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | while IFS= read -r d; do basename "${d}"; done | LC_ALL=C sort)

if [ -z "${PROBE}" ]; then
  report "probe selection: a roster skill outside the tag-diff window exists" 0 \
    "every roster skill is inside the window; arms B and C cannot be staged"
  printf '\ntest_deploy_detection_honesty.sh: %d passed, %d failed\n' "${PASS}" "${FAIL}"
  exit 1
fi
PROBE_MODULE="$(skill_module "${PROBE}")"
PROBE_SRC="${REPO_ROOT}/${PROBE_MODULE}/skills/${PROBE}/SKILL.md"
PROBE_TGT="${MIRROR}/${PROBE}/SKILL.md"

# --- Arm B: the defect ------------------------------------------------------
printf '\nArm B — the defect: installed copy diverges with no git change\n'

# The arm's OWN control: the probe must be invisible to the tag-diff detector, or the
# arm proves nothing (it would be testing a skill the old code already deployed).
case "
${WINDOW}
" in
  *"
${PROBE}
"*)
    report "CONTROL: probe '${PROBE}' is OUTSIDE the tag-diff window (old detector cannot see it)" 0 \
      "probe is inside the window" ;;
  *)
    report "CONTROL: probe '${PROBE}' is OUTSIDE the tag-diff window (old detector cannot see it)" 1 ;;
esac

printf '\n<!-- staged divergence: test_deploy_detection_honesty.sh arm B -->\n' >> "${PROBE_TGT}"
if diff -q "${PROBE_SRC}" "${PROBE_TGT}" >/dev/null 2>&1; then
  report "setup: installed copy of '${PROBE}' diverges from source" 0 "perturbation did not take"
else
  report "setup: installed copy of '${PROBE}' diverges from source" 1
fi

run_deploy "${SBX}/run-drift.log"
DRIFT_RC="${DEPLOY_RC}"

if grep -q "Ground-truth scan:.*${PROBE}" "${SBX}/run-drift.log" 2>/dev/null; then
  report "ground-truth scan selects '${PROBE}' the tag diff could not see" 1
else
  report "ground-truth scan selects '${PROBE}' the tag diff could not see" 0 \
    "no ground-truth selection line naming the probe; see ${SBX}/run-drift.log"
fi

if diff -q "${PROBE_SRC}" "${PROBE_TGT}" >/dev/null 2>&1; then
  report "installed copy of '${PROBE}' is byte-identical to source afterward" 1
else
  report "installed copy of '${PROBE}' is byte-identical to source afterward" 0 \
    "the deploy left the installed copy stale — the reported defect"
fi

if grep -qE 'Deployed: [1-9][0-9]* skills' "${SBX}/run-drift.log" 2>/dev/null; then
  report "summary reports a non-zero skills count (the repair is visible downstream)" 1
else
  report "summary reports a non-zero skills count (the repair is visible downstream)" 0 \
    "reported zero skills while repairing one — update.sh would keep PHASE5_DEPLOYED at 0"
fi

if [ "${DRIFT_RC}" -eq 0 ]; then
  report "a REPAIRED drift exits 0 (non-zero is reserved for residual)" 1
else
  report "a REPAIRED drift exits 0 (non-zero is reserved for residual)" 0 "rc=${DRIFT_RC}"
fi

# --- Arm C: unrepairable drift exits non-zero -------------------------------
printf '\nArm C — unrepairable drift: residual survives the repair and fails\n'

printf '\n<!-- staged divergence: test_deploy_detection_honesty.sh arm C -->\n' >> "${PROBE_TGT}"
chmod -R a-w "${MIRROR}/${PROBE}" 2>/dev/null || true

if [ -w "${MIRROR}/${PROBE}" ]; then
  report "setup: target for '${PROBE}' is unwritable" 0 "chmod did not take (running as root?)"
else
  report "setup: target for '${PROBE}' is unwritable" 1
fi

run_deploy "${SBX}/run-residual.log"
RESIDUAL_RC="${DEPLOY_RC}"

if [ "${RESIDUAL_RC}" -ne 0 ]; then
  report "unrepairable drift exits NON-ZERO (rc=${RESIDUAL_RC})" 1
else
  report "unrepairable drift exits NON-ZERO" 0 \
    "exited 0 over an instance it could not make current — the reported defect"
fi

if grep -q "residual drift" "${SBX}/run-residual.log" 2>/dev/null && \
   grep -q "${PROBE}" "${SBX}/run-residual.log" 2>/dev/null; then
  report "failure names the skill and the residual cause" 1
else
  report "failure names the skill and the residual cause" 0 \
    "no residual-drift failure naming '${PROBE}'; see ${SBX}/run-residual.log"
fi

if grep -q 'chmod -R u+w' "${SBX}/run-residual.log" 2>/dev/null; then
  report "failure carries the actionable remedy (chmod -R u+w)" 1
else
  report "failure carries the actionable remedy (chmod -R u+w)" 0 \
    "unwritable cause reported without its remedy string"
fi

chmod -R u+w "${MIRROR}/${PROBE}" 2>/dev/null || true

# --- Live-tree safety proof -------------------------------------------------
printf '\nSafety — live ~/.claude/skills untouched across every invocation\n'
LIVE_AFTER="$(manifest_dir "${LIVE_SKILLS}")"
if [ "${LIVE_BEFORE}" = "${LIVE_AFTER}" ]; then
  report "live ~/.claude/skills byte-identical before/after" 1
else
  report "live ~/.claude/skills byte-identical before/after" 0 \
    "manifest drift under ${LIVE_SKILLS} — an invocation escaped its sandbox"
fi

# --- Summary ----------------------------------------------------------------
printf -- '─────────────────────────────────────────────────────────────────────────\n'
printf 'test_deploy_detection_honesty.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0

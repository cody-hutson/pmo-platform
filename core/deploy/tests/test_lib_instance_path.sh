#!/usr/bin/env bash
# test_lib_instance_path.sh — behavioural regression for core/deploy/lib-instance-path.sh.
#
# WHY THIS FILE EXISTS (#5666). The resolver is sourced by deploy.sh, the PII pre-commit
# hook, lib-composition.sh, the composition manifest, check-canonical-structure.sh,
# extract-roster-needles.sh, and the install/update/setup scripts. Before this file it had
# no dedicated test: two of its ten functions were exercised incidentally by
# test_check19_event_log_integrity.sh (pmo_evals_results_path) and
# test_check49_mode_identifier_unification.sh (pmo_instance_path), each as a means to some
# other subject, and test_doctor.sh referenced it only as a file-permission fixture.
#
# The specific risk is that the instance resolver has TWO forms whose disagreement is silent:
#   pmo_instance_path()          builds its own base from CLAUDE_WORKSPACE_ROOT (or $HOME)
#   pmo_instance_path_for(base)  uses whatever base the caller hands it
# A caller that holds an explicit workspace root and reaches for the no-arg form gets the
# ambient base instead of its own, with no error. The arms below pin that divergence
# explicitly rather than leaving it as a property someone re-derives from the source.
#
# Self-contained: sets and unsets its own environment; touches no workspace and no live
# surface. bash 3.2-safe.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LIB="${REPO_ROOT}/core/deploy/lib-instance-path.sh"

PASS=0
FAIL=0
report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '         %s\n' "${detail}"; FAIL=$((FAIL + 1)); fi
}

[ -f "${LIB}" ] || { printf 'FATAL: resolver not found at %s\n' "${LIB}"; exit 2; }
# shellcheck source=/dev/null
. "${LIB}"

# Every arm below sets its own environment explicitly. Start from a known-clear state so a
# variable inherited from the caller cannot make an arm pass for the wrong reason.
unset PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT 2>/dev/null || true

printf '\nCase 1: the no-arg resolver honours CLAUDE_WORKSPACE_ROOT, then falls back to HOME\n'
CLAUDE_WORKSPACE_ROOT="/tmp/ws-alpha"
got="$(pmo_instance_path)"
[ "${got}" = "/tmp/ws-alpha/pmo-instance" ] \
  && report "1a: pmo_instance_path builds from CLAUDE_WORKSPACE_ROOT" 1 \
  || report "1a: pmo_instance_path builds from CLAUDE_WORKSPACE_ROOT" 0 "got ${got}"
unset CLAUDE_WORKSPACE_ROOT
got="$(pmo_instance_path)"
[ "${got}" = "${HOME}/Claude/pmo-instance" ] \
  && report "1b: with no CLAUDE_WORKSPACE_ROOT it falls back to the HOME-based default" 1 \
  || report "1b: with no CLAUDE_WORKSPACE_ROOT it falls back to the HOME-based default" 0 "got ${got}"

printf '\nCase 2: PMO_INSTANCE_PATH is a direct-path override and outranks every base\n'
PMO_INSTANCE_PATH="/tmp/explicit-instance"
CLAUDE_WORKSPACE_ROOT="/tmp/ws-alpha"
got="$(pmo_instance_path)"
[ "${got}" = "/tmp/explicit-instance" ] \
  && report "2a: PMO_INSTANCE_PATH outranks CLAUDE_WORKSPACE_ROOT in the no-arg form" 1 \
  || report "2a: PMO_INSTANCE_PATH outranks CLAUDE_WORKSPACE_ROOT in the no-arg form" 0 "got ${got}"
got="$(pmo_instance_path_for /tmp/ws-beta)"
[ "${got}" = "/tmp/explicit-instance" ] \
  && report "2b: PMO_INSTANCE_PATH outranks an EXPLICIT base in the arg form" 1 \
  || report "2b: PMO_INSTANCE_PATH outranks an EXPLICIT base in the arg form" 0 "got ${got}"
unset PMO_INSTANCE_PATH

printf '\nCase 3: the two forms DIVERGE, which is the whole reason to pick one deliberately\n'
# Same ambient environment, two call shapes, two different answers. A caller holding an
# explicit root that reaches for the no-arg form silently gets the ambient base instead --
# no error, no warning, just the wrong directory.
CLAUDE_WORKSPACE_ROOT="/tmp/ws-ambient"
noarg="$(pmo_instance_path)"
witharg="$(pmo_instance_path_for /tmp/ws-explicit)"
if [ "${noarg}" = "/tmp/ws-ambient/pmo-instance" ] \
   && [ "${witharg}" = "/tmp/ws-explicit/pmo-instance" ] \
   && [ "${noarg}" != "${witharg}" ]; then
  report "3a: under one environment the two forms resolve to DIFFERENT directories" 1
else
  report "3a: under one environment the two forms resolve to DIFFERENT directories" 0 \
    "no-arg=${noarg} arg-form=${witharg}"
fi
# Specificity: the divergence is caused by the base, not by the leaf. Hand the arg form the
# same base the ambient environment supplies and the two must agree exactly -- otherwise the
# arm above would pass for some unrelated reason.
same="$(pmo_instance_path_for /tmp/ws-ambient)"
[ "${same}" = "${noarg}" ] \
  && report "3b-specificity: handed the SAME base, the two forms agree exactly" 1 \
  || report "3b-specificity: handed the SAME base, the two forms agree exactly" 0 \
     "no-arg=${noarg} arg-form=${same}"

printf '\nCase 4: pmo_operations_path_for has NO env tier, and that asymmetry is deliberate\n'
# This is the arm most worth having. The absence of a PMO_OPERATIONS_PATH override reads as
# an oversight next to pmo_instance_path_for, and "fixing" the symmetry would mint a new
# variable that ADR-032 forbids. Pin the current contract so that change has to be a
# deliberate, visible one rather than a tidy-up.
PMO_INSTANCE_PATH="/tmp/explicit-instance"
ops="$(pmo_operations_path_for /tmp/ws-gamma)"
[ "${ops}" = "/tmp/ws-gamma/projects" ] \
  && report "4a: the operations resolver ignores PMO_INSTANCE_PATH entirely" 1 \
  || report "4a: the operations resolver ignores PMO_INSTANCE_PATH entirely" 0 "got ${ops}"
unset PMO_INSTANCE_PATH
CLAUDE_WORKSPACE_ROOT="/tmp/ws-ambient"
ops="$(pmo_operations_path_for /tmp/ws-gamma)"
[ "${ops}" = "/tmp/ws-gamma/projects" ] \
  && report "4b: it also ignores CLAUDE_WORKSPACE_ROOT and uses only its argument" 1 \
  || report "4b: it also ignores CLAUDE_WORKSPACE_ROOT and uses only its argument" 0 "got ${ops}"

printf '\nCase 5: the needle and roster paths hang off the instance path, override included\n'
unset CLAUDE_WORKSPACE_ROOT
PMO_INSTANCE_PATH="/tmp/explicit-instance"
needles="$(pmo_localized_needles)"
roster="$(pmo_people_roster)"
[ "${needles}" = "/tmp/explicit-instance/localized-context-needles.txt" ] \
  && report "5a: the needle file resolves under the instance path" 1 \
  || report "5a: the needle file resolves under the instance path" 0 "got ${needles}"
[ "${roster}" = "/tmp/explicit-instance/people-roster.yaml" ] \
  && report "5b: the roster file resolves under the instance path" 1 \
  || report "5b: the roster file resolves under the instance path" 0 "got ${roster}"
PMO_LOCALIZED_NEEDLES="/tmp/needles-elsewhere.txt"
needles="$(pmo_localized_needles)"
[ "${needles}" = "/tmp/needles-elsewhere.txt" ] \
  && report "5c: PMO_LOCALIZED_NEEDLES overrides the derived location" 1 \
  || report "5c: PMO_LOCALIZED_NEEDLES overrides the derived location" 0 "got ${needles}"
unset PMO_LOCALIZED_NEEDLES PMO_INSTANCE_PATH

printf '\nCase 6: the NEEDLE-BEARING resolvers land OUTSIDE the repository tree\n'
# This is the invariant the operator-instance directory exists to protect, and it is
# narrower than "no operator-instance path is in-repo" on purpose. That broader claim is
# FALSE BY DESIGN: <OPERATOR_INSTANCE_ROADMAPS_PATH> and <OPERATOR_INSTANCE_ANALYSIS_PATH>
# both default to in-repo homes (folder + README tracked, contents git-ignored), so a test
# asserting it would fail on 2 of the codified tokens while the platform behaved
# correctly.  # depersonalization-token: allow — naming two codified tokens in an explanatory comment
#
# What actually must never be reachable by a git operation is the pair of files the PII
# detectors load at runtime: localized-context-needles.txt and people-roster.yaml. The
# .gitignore states the reason directly — hardcoding those values would make the detector
# itself a leak. A git-ignored in-repo home would protect them only while .gitignore stays
# correct and every tool honours it; a sibling directory outside the tree is unreachable by
# any git operation at all.
unset PMO_INSTANCE_PATH PMO_LOCALIZED_NEEDLES PMO_PEOPLE_ROSTER 2>/dev/null || true
CLAUDE_WORKSPACE_ROOT="/tmp/ws-outoftree"
needles="$(pmo_localized_needles)"
roster="$(pmo_people_roster)"
# REPO_ROOT is this checkout. The assertion is a prefix test against it, so it holds for a
# worktree, a sandboxed install, and a clone under any directory name.
case "${needles}" in
  "${REPO_ROOT}"/*) report "6a: the needle file resolves OUTSIDE the repository tree" 0 \
                      "resolved INSIDE the repo: ${needles}" ;;
  *)                report "6a: the needle file resolves OUTSIDE the repository tree" 1 ;;
esac
case "${roster}" in
  "${REPO_ROOT}"/*) report "6b: the people roster resolves OUTSIDE the repository tree" 0 \
                      "resolved INSIDE the repo: ${roster}" ;;
  *)                report "6b: the people roster resolves OUTSIDE the repository tree" 1 ;;
esac
# SENSITIVITY. Both arms above are "does NOT start with the repo root" — a shape that
# passes for free if the prefix test is broken, if REPO_ROOT is empty, or if the resolver
# returns nothing at all. So point the resolver INTO the repo deliberately and require the
# same test to catch it. Without this arm 6a/6b prove nothing.
PMO_INSTANCE_PATH="${REPO_ROOT}/pmo-instance"
inside="$(pmo_localized_needles)"
case "${inside}" in
  "${REPO_ROOT}"/*) report "6c-sensitivity: the same test CATCHES an in-repo resolution" 1 ;;
  *)                report "6c-sensitivity: the same test CATCHES an in-repo resolution" 0 \
                      "the in-repo probe was not detected: ${inside}" ;;
esac
# ...and the resolvers must have returned a real path, not an empty string that would
# satisfy every arm above vacuously.
[ -n "${needles}" ] && [ -n "${roster}" ] && [ "${needles}" != "${roster}" ] \
  && report "6d: both resolvers returned distinct non-empty paths (arms above are not vacuous)" 1 \
  || report "6d: both resolvers returned distinct non-empty paths (arms above are not vacuous)" 0 \
     "needles=${needles} roster=${roster}"
unset PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT 2>/dev/null || true

printf '\n======================================================================\n'
printf 'test_lib_instance_path.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION}"
printf '======================================================================\n'
[ "${FAIL}" -eq 0 ]

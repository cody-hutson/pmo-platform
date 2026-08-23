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

printf '\n======================================================================\n'
printf 'test_lib_instance_path.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION}"
printf '======================================================================\n'
[ "${FAIL}" -eq 0 ]

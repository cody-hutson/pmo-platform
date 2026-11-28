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
#
# FILE-LEVEL SANDBOX (the class-resolver arms, 8020-* and CIAC-*). Before anything is
# sourced, every base a resolver reads is pointed at one fixture root, $FX: HOME, the
# config root, both XDG bases and TMPDIR; every direct override is unset; git's system,
# global and command-line config routes are closed and its identity is pinned. The live
# roots are saved first, for the containment detector only (8020-AC8): it reads the live
# shared surfaces for a per-run nonce and stats the live config root, and it never opens
# the live operator.toml. Cases 1-9 keep passing unchanged, because their expectations
# derive from $HOME or are pure strings.
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

# --- the live roots, saved before any redirect (detector input only) -------------------
LIVE_HOME="${HOME:-}"
LIVE_CFG="${PMO_PLATFORM_CONFIG_ROOT:-${LIVE_HOME}/.config/pmo-platform}"
LIVE_WS="${CLAUDE_WORKSPACE_ROOT:-${LIVE_HOME}/Claude}"
LIVE_DATA="${XDG_DATA_HOME:-${LIVE_HOME}/.local/share}"
LIVE_STATE="${XDG_STATE_HOME:-${LIVE_HOME}/.local/state}"
LIVE_INST="${PMO_INSTANCE_PATH:-${LIVE_WS}/pmo-instance}"
LIVE_EVENT_LOG="${EVALS_RESULTS_PATH:-${LIVE_WS}/pmo-instance/evals/results}/pipeline-event-log.md"
LIVE_HUB_STATE="${HUB_STATE_PATH:-${LIVE_INST}/hub-state}"
LIVE_REGISTERS="${LIVE_INST}/releases/registers"
LIVE_FINOPS="${LIVE_INST}/finops"
# FM-B: the governed arm's own live target — the live designated main checkout's ignored
# local-state/ and analysis/, composed two ways, both read-only (the default repository
# name, because the live operator.toml is never opened; and this checkout's main worktree).
LIVE_MAIN_A="${LIVE_WS}/pmo-platform"
LIVE_MAIN_B="$( (git -C "${REPO_ROOT}" worktree list --porcelain 2>/dev/null || true) | awk 'NR==1 && /^worktree /{sub(/^worktree /,""); p=$0} END{print p}')"
NONCE="libpath-selftest-$$-$(date +%s)"
OUTSIDE_ROOT="$(cd -P "$(mktemp -d)" && pwd -P)" # a second root OUTSIDE the fixture (controls)
FX="$(cd -P "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "${FX}" "${OUTSIDE_ROOT}"' EXIT
MARK="${FX}/.mark"; : > "${MARK}"
TREE_BEFORE="$(git -C "${REPO_ROOT}" status --porcelain=v1 -uall 2>/dev/null || true)"

# --- redirect every base at the fixture root --------------------------------------------
mkdir -p "${FX}/home/.config/pmo-platform" "${FX}/xdg-data" "${FX}/xdg-state" "${FX}/tmp"
export HOME="${FX}/home" XDG_CONFIG_HOME="${FX}/home/.config" PMO_PLATFORM_CONFIG_ROOT="${FX}/home/.config/pmo-platform"
export XDG_DATA_HOME="${FX}/xdg-data" XDG_STATE_HOME="${FX}/xdg-state" TMPDIR="${FX}/tmp"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null PMO_REGRESSION_EMIT=0
export GIT_AUTHOR_NAME=fx GIT_AUTHOR_EMAIL=fx@example.invalid GIT_AUTHOR_DATE='2026-01-01T00:00:00Z'
export GIT_COMMITTER_NAME=fx GIT_COMMITTER_EMAIL=fx@example.invalid GIT_COMMITTER_DATE='2026-01-01T00:00:00Z'
unset WORKSPACE_ROOT PMO_INSTANCE_PATH EVALS_RESULTS_PATH HUB_STATE_PATH PMO_LOCALIZED_NEEDLES PMO_PEOPLE_ROSTER \
  PMO_SRC_ROOT PMO_PROJECT_KEYS STORE FINOPS_STORE_PATH FINOPS_HUB_STATE_DIR FINOPS_PIPELINE_EVENT_LOG \
  GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS \
  GIT_CEILING_DIRECTORIES GIT_DISCOVERY_ACROSS_FILESYSTEM 2>/dev/null || true

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
# both default to in-repo homes (folder + README tracked, contents git-ignored), and the
# working-state telemetry folder (Case 8) defaults to a subfolder of a third, so a test
# asserting it would fail on 3 of the codified tokens while the platform behaved
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

printf '\nCase 7: the skill-editor exemption list has one resolver pair, at the instance tier\n'
# Literal pins, per this file's doctrine: each arm compares a resolved value with the path
# it must be, never with another resolver's answer. 7e is the row invariant — the target
# the manifest row resolves to (the path the installer seeds and update.sh regenerates) is
# the path every reader resolves. The row's tier is read from the manifest, not assumed,
# so re-tiering the row turns 7e red.
EXEMPT_AT_WS="/ws/pmo-instance/skill-editor-exemption-list.txt"
# pin <name> <got> <want> [<detail>] — one arm: a resolved value against its literal.
pin() {
  if [ "$2" = "$3" ]; then report "$1" 1; else report "$1" 0 "${4:-got $2}"; fi
}
pin "7a: the explicit-root form lands under the given workspace root" \
  "$(pmo_skill_editor_exemption_list_for /ws)" "${EXEMPT_AT_WS}"
PMO_INSTANCE_PATH="/tmp/explicit-instance"
pin "7b: PMO_INSTANCE_PATH relocates it, as it relocates every instance file" \
  "$(pmo_skill_editor_exemption_list_for /ws)" "/tmp/explicit-instance/skill-editor-exemption-list.txt"
unset PMO_INSTANCE_PATH
CLAUDE_WORKSPACE_ROOT="/cw"
pin "7c: the no-argument form builds from CLAUDE_WORKSPACE_ROOT" \
  "$(pmo_skill_editor_exemption_list)" "/cw/pmo-instance/skill-editor-exemption-list.txt"
unset CLAUDE_WORKSPACE_ROOT
hook_read="$(pmo_hook_read_instance_files_for /ws)"
hook_read_n=0
while IFS= read -r _l; do
  if [ -n "${_l}" ]; then hook_read_n=$((hook_read_n + 1)); fi
done <<EOF
${hook_read}
EOF
pin "7d: the hook-read instance set is exactly the exemption list, one line" \
  "${hook_read_n}:${hook_read}" "1:${EXEMPT_AT_WS}" "lines=${hook_read_n} value=${hook_read}"
# row_target_for <workspace-root> — the manifest row's resolved target. A function whose
# body is a subshell, called through $( ): bash 3.2 mis-reads a case arm's closing
# parenthesis written directly inside $( ), and this file runs under bash 3.2 in CI.
row_target_for() {
  (
    unset PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT
    # shellcheck source=/dev/null
    . "${REPO_ROOT}/core/deploy/lib-composition.sh" >/dev/null 2>&1 || exit 0
    lib_compose_source_manifest "${REPO_ROOT}" >/dev/null 2>&1 || exit 0
    for entry in "${COMPOSITION_SURFACE_FILES[@]}"; do
      lib_compose_parse_entry "${entry}"
      case "${LIB_COMPOSE_ENTRY_SRC}" in
        */skill-editor-exemption-list.txt)
          lib_compose_resolve_target skill-editor-exemption-list.txt "${LIB_COMPOSE_ENTRY_TIER}" "$1"
          exit 0 ;;
      esac
    done
  )
}
row_target="$(row_target_for /ws)"
pin "7e: the manifest row resolves to the same path the readers resolve (the row invariant)" \
  "${row_target}" "${EXEMPT_AT_WS}" "row resolves to '${row_target}'"

printf '\nCase 8: the working-state telemetry folder resolves to the main checkout, override first\n'
# Literal pins, per this file's doctrine. The resolver's operator.toml tier reads the
# config under $HOME, so every arm runs in a subshell with HOME pointed at a sandbox:
# an empty one for the default, a seeded one for the override. Without the redirect an
# arm would read the live operator config and could pass or fail for a reason that has
# nothing to do with the resolver. 8a is also the arm that fails if the folder is ever
# rooted under the instance container instead of the main checkout.
TEL_SBX="${FX}/case8"; mkdir -p "${TEL_SBX}"   # under the file-level sandbox; its one EXIT trap removes it
mkdir -p "${TEL_SBX}/empty" "${TEL_SBX}/seeded/.config/pmo-platform"
printf '[paths]\noperator_instance_working_state_telemetry_path = "/elsewhere/telemetry"\n' \
  > "${TEL_SBX}/seeded/.config/pmo-platform/operator.toml"
TEL_AT_WS="/ws/pmo-platform/local-state/telemetry"
pin "8a: with no override it resolves under the given root's main checkout" \
  "$( unset PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT; HOME="${TEL_SBX}/empty"
      pmo_telemetry_path_for /ws )" "${TEL_AT_WS}"
pin "8b: the operator.toml override key wins over the default" \
  "$( unset PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT; HOME="${TEL_SBX}/seeded"
      pmo_telemetry_path_for /ws )" "/elsewhere/telemetry"
pin "8c: PMO_INSTANCE_PATH does not relocate it (the folder is not under the instance container)" \
  "$( unset CLAUDE_WORKSPACE_ROOT; HOME="${TEL_SBX}/empty"; PMO_INSTANCE_PATH="/tmp/explicit-instance"
      pmo_telemetry_path_for /ws )" "${TEL_AT_WS}"
pin "8d: an ambient CLAUDE_WORKSPACE_ROOT does not displace the argument" \
  "$( unset PMO_INSTANCE_PATH; HOME="${TEL_SBX}/empty"; CLAUDE_WORKSPACE_ROOT="/cw"
      pmo_telemetry_path_for /ws )" "${TEL_AT_WS}"

printf '\nCase 9: the analysis workspace resolves to the main checkout, override first\n'
# Same sandboxing as Case 8, under Case 8's sandbox so its one EXIT trap removes both (a
# second trap would replace the first). 9c is the control: the override key moves the
# analysis home and nothing else, so the instance base read under the same seeded HOME
# stays where it was.
ANA_SBX="${TEL_SBX}/analysis-case"
mkdir -p "${ANA_SBX}/empty" "${ANA_SBX}/seeded/.config/pmo-platform"
printf '[paths]\noperator_instance_analysis_path = "/elsewhere/analysis"\n' \
  > "${ANA_SBX}/seeded/.config/pmo-platform/operator.toml"
ANA_AT_WS="/ws/pmo-platform/analysis"
pin "9a: with no override it resolves under the given root's main checkout" \
  "$( unset PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT; HOME="${ANA_SBX}/empty"
      pmo_analysis_path_for /ws )" "${ANA_AT_WS}"
pin "9b: the operator.toml override key wins over the default" \
  "$( unset PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT; HOME="${ANA_SBX}/seeded"
      pmo_analysis_path_for /ws )" "/elsewhere/analysis"
pin "9c: control — the same override leaves the instance base unmoved" \
  "$( unset PMO_INSTANCE_PATH CLAUDE_WORKSPACE_ROOT; HOME="${ANA_SBX}/seeded"
      pmo_instance_path_for /ws )" "/ws/pmo-instance"
pin "9d: neither PMO_INSTANCE_PATH nor an ambient CLAUDE_WORKSPACE_ROOT moves it" \
  "$( HOME="${ANA_SBX}/empty"; PMO_INSTANCE_PATH="/tmp/explicit-instance"; CLAUDE_WORKSPACE_ROOT="/cw"
      pmo_analysis_path_for /ws )" "${ANA_AT_WS}"

# =====================================================================================
# The class resolvers (#8020) — every arm below runs inside the file-level sandbox. Each
# row compares a resolved value with a literal, every path is physical, and every value
# a row resolves is appended to the containment ledger (8020-AC8).
# =====================================================================================
W="${FX}/ws"; H="${HOME}"; W1="${W}/widget/.claude/worktrees/w1"
CFG="${PMO_PLATFORM_CONFIG_ROOT}/operator.toml"
: > "${FX}/ledger"
cfg() { printf '%s\n' "$@" > "${CFG}"; }        # the fixture config root's operator.toml (also HOME's)
cfg_clear() { : > "${CFG}"; }
# run_r <cmd...> -> OUT, RC, ERR
run_r() { OUT="$("$@" 2>"${FX}/.err")"; RC=$?; ERR="$(cat "${FX}/.err")"; }
MODE=report; MISS=0
# chk <label> <want-rc> <want-out> <cmd...>
chk() {
  local label="$1" wrc="$2" wout="$3"; shift 3
  run_r "$@"
  if [ "${MODE}" = count ]; then
    if [ "${RC}" != "${wrc}" ] || [ "${OUT}" != "${wout}" ]; then MISS=$((MISS + 1)); fi
    return 0
  fi
  if [ "${RC}" = "${wrc}" ] && [ "${OUT}" = "${wout}" ]; then report "${label}" 1
  else report "${label}" 0 "rc=${RC} (want ${wrc}) out='${OUT}' (want '${wout}') err='${ERR}'"; fi
  # Every resolved PATH goes to the ledger; the on/off verdict of pmo_governed_homes_for is not a path.
  case "${RC}:${OUT}" in 0:on|0:off|0:) ;; 0:*) printf '%s\n' "${OUT}" >> "${FX}/ledger" ;; esac
}
# chk_fail <label> <want-rc> <stderr-substring or ""> <cmd...> — the failure contract:
# the code, stdout empty, exactly one stderr line beginning "lib-instance-path: ".
chk_fail() {
  local label="$1" wrc="$2" sub="$3" ok=1 nl; shift 3
  run_r "$@"
  nl="$(printf '%s' "${ERR}" | awk 'END{print NR}')"
  [ "${RC}" = "${wrc}" ] || ok=0
  [ -z "${OUT}" ] || ok=0
  [ "${nl}" = 1 ] || ok=0
  case "${ERR}" in "lib-instance-path: "*) ;; *) ok=0 ;; esac
  if [ -n "${sub}" ]; then case "${ERR}" in *"${sub}"*) ;; *) ok=0 ;; esac; fi
  report "${label}" "${ok}" "rc=${RC} (want ${wrc}) out='${OUT}' stderr-lines=${nl} err='${ERR}'"
}

# --- fixture builders: both refuse a path outside $FX ----------------------------------
fx_mkdir() {
  case "$1" in "${FX}"/*) mkdir -p "$1" ;; *) printf 'fx_mkdir: refused %s (outside the fixture)\n' "$1" >&2; return 97 ;; esac
}
fx_git() {
  if [ "${1:-}" = "-C" ]; then
    case "${2:-}" in "${FX}"/*) ;; *) printf 'fx_git: refused -C %s (outside the fixture)\n' "${2:-}" >&2; return 97 ;; esac
  fi
  command git -c core.hooksPath=/dev/null -c init.templateDir= -c commit.gpgsign=false "$@"
}
fx_repo() { # fx_repo <dir> <origin-or-empty> <label> — two plumbing commits on main
  local d="$1" o="$2" t c c2
  fx_mkdir "${d}" || return 1
  fx_git -C "${d}" init -q >/dev/null 2>&1 || return 1
  t="$(fx_git -C "${d}" hash-object -t tree -w /dev/null)" || return 1
  c="$(printf 'root %s %s\n' "$3" "${NONCE}" | fx_git -C "${d}" commit-tree "${t}")" || return 1
  c2="$(printf 'second %s\n' "$3" | fx_git -C "${d}" commit-tree "${t}" -p "${c}")" || return 1
  fx_git -C "${d}" update-ref refs/heads/main "${c2}" || return 1
  fx_git -C "${d}" symbolic-ref HEAD refs/heads/main || return 1
  if [ -n "${o}" ]; then fx_git -C "${d}" remote add origin "${o}" || return 1; fi
}
fx_clone() { # fx_clone <src> <dst> <origin-or-empty> [--depth1]
  case "$2" in "${FX}"/*) ;; *) return 97 ;; esac
  if [ "${4:-}" = "--depth1" ]; then fx_git clone -q --depth 1 "file://$1" "$2" >/dev/null 2>&1 || return 1
  else fx_git clone -q --no-local "$1" "$2" >/dev/null 2>&1 || return 1; fi
  if [ -n "$3" ]; then fx_git -C "$2" remote set-url origin "$3" || return 1
  else fx_git -C "$2" remote remove origin || return 1; fi
}
FXOK=1
fx_repo "${W}/widget" "https://example.invalid/acme/widget.git" widget || FXOK=0
fx_git -C "${W}/widget" worktree add -q --detach "${W1}" >/dev/null 2>&1 || FXOK=0
fx_mkdir "${W}/widget/local-state" && fx_mkdir "${W}/widget/analysis" && fx_mkdir "${W}/widget/data" || FXOK=0
fx_repo "${W}/plain" "https://example.invalid/acme/plain.git" plain || FXOK=0
fx_repo "${W}/bare-widget" "https://example.invalid/acme/bare-widget.git" bare-widget || FXOK=0
fx_repo "${FX}/elsewhere/widget-copy" "git@example.invalid:acme/widget.git" widget-copy || FXOK=0
fx_repo "${FX}/other/widget" "https://example.invalid/acme/other.git" widget-other || FXOK=0
fx_clone "${W}/widget" "${FX}/noorigin/widget" "" || FXOK=0
fx_clone "${W}/widget" "${FX}/forks/widget" "https://example.invalid/someone/widget.git" || FXOK=0
fx_clone "${W}/widget" "${FX}/shallow/widget" "https://example.invalid/third/widget.git" --depth1 || FXOK=0
fx_clone "${W}/widget" "${W}/widget-alt" "https://example.invalid/acme/widget.git" || FXOK=0
fx_mkdir "${FX}/gitfile/x" && printf 'gitdir: /nonexistent\n' > "${FX}/gitfile/.git" || FXOK=0
fx_git init -q --bare "${FX}/bare.git" >/dev/null 2>&1 || FXOK=0
ln -s "${W}/widget/data" "${FX}/link" || FXOK=0
fx_mkdir "${FX}/dangle" && ln -s "${FX}/no-such-target" "${FX}/dangle/.git" || FXOK=0
printf 'payload %s\n' "${NONCE}" > "${W}/widget/local-state/nonce-probe.txt" || FXOK=0
report "fixture: every fixture repository and planted path built inside the fixture root" "${FXOK}"

# =====================================================================================
printf '\n8020-AC1 one resolver per served class\n'
n=0
for f in pmo_working_state_path_for pmo_working_state_path pmo_install_state_path_for pmo_leak_risk_path_for pmo_leak_risk_path; do
  if declare -F "${f}" >/dev/null; then n=$((n + 1)); fi
done
pin "8020-AC1 one resolver per served class: the five class-resolver functions are defined" "${n}" "5"
cfg_clear
chk "8020-AC1 one resolver per served class: the run-class argument is accepted" 0 "${H}/Claude/pmo-instance/hub-state" \
  pmo_working_state_path release-runs --run-class working-state
chk "8020-AC1 one resolver per served class: the Operator PMO content resolver answers as before" 0 "${W}/projects" pmo_operations_path_for "${W}"
chk "8020-AC1 one resolver per served class: the ambient inbox resolver answers as before" 0 "${W}/pmo-instance/inbox" pmo_inbox_path_for "${W}"
chk "8020-AC1 one resolver per served class: the ambient intake resolver answers as before" 0 "${W}/pmo-instance/ambient-intake" pmo_ambient_intake_path_for "${W}"
chk "8020-AC1 one resolver per served class: the external-sync resolver answers as before" 0 "${W}/pmo-instance/external-sync" pmo_external_sync_path_for "${W}"

# =====================================================================================
printf '\n8020-AC2 switch unset — every member, every resolver-level rung, against a literal\n'
cfg_clear
ac2_release_runs() {
  cfg_clear
  chk "8020-AC2 switch unset: release-runs _for default" 0 "${W}/pmo-instance/hub-state" pmo_working_state_path_for "${W}" release-runs
  cfg "operator_instance_hub_state_path = \"${FX}/T\""
  chk "8020-AC2 switch unset: release-runs _for toml" 0 "${FX}/T" pmo_working_state_path_for "${W}" release-runs
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: release-runs _for toml beats PMO_INSTANCE_PATH" 0 "${FX}/T" pmo_working_state_path_for "${W}" release-runs
  cfg_clear
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: release-runs _for PMO_INSTANCE_PATH" 0 "${FX}/p/hub-state" pmo_working_state_path_for "${W}" release-runs
  CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "8020-AC2 switch unset: release-runs _for ignores an ambient CLAUDE_WORKSPACE_ROOT" 0 "${W}/pmo-instance/hub-state" pmo_working_state_path_for "${W}" release-runs
  chk "8020-AC2 switch unset: release-runs no-argument default" 0 "${H}/Claude/pmo-instance/hub-state" pmo_working_state_path release-runs
  CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "8020-AC2 switch unset: release-runs no-argument CLAUDE_WORKSPACE_ROOT" 0 "${FX}/c/pmo-instance/hub-state" pmo_working_state_path release-runs
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: release-runs no-argument PMO_INSTANCE_PATH" 0 "${FX}/p/hub-state" pmo_working_state_path release-runs
  cfg "operator_instance_hub_state_path = \"${FX}/T\""
  chk "8020-AC2 switch unset: release-runs no-argument toml" 0 "${FX}/T" pmo_working_state_path release-runs
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: release-runs no-argument toml beats PMO_INSTANCE_PATH" 0 "${FX}/T" pmo_working_state_path release-runs
  cfg "claude_workspace_root = \"${FX}/tr\""
  WORKSPACE_ROOT="${FX}/wr" chk "8020-AC2 switch unset: release-runs no-argument ignores WORKSPACE_ROOT" 0 "${H}/Claude/pmo-instance/hub-state" pmo_working_state_path release-runs
  chk "8020-AC2 switch unset: release-runs no-argument ignores the toml claude_workspace_root" 0 "${H}/Claude/pmo-instance/hub-state" pmo_working_state_path release-runs
  cfg_clear
}
ac2_release_runs
cfg "operator_instance_hub_state_path = \"${FX}/T\""
chk "8020-AC2 switch unset: release-runs-templates _for default, and the toml hub-state key does NOT apply (S-02)" 0 "${W}/pmo-instance/hub-state" \
  pmo_working_state_path_for "${W}" release-runs-templates
cfg_clear
chk "8020-AC2 switch unset: release-runs-templates _for default" 0 "${W}/pmo-instance/hub-state" pmo_working_state_path_for "${W}" release-runs-templates
PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: release-runs-templates _for PMO_INSTANCE_PATH" 0 "${FX}/p/hub-state" pmo_working_state_path_for "${W}" release-runs-templates
CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "8020-AC2 switch unset: release-runs-templates ignores an ambient CLAUDE_WORKSPACE_ROOT" 0 "${W}/pmo-instance/hub-state" pmo_working_state_path_for "${W}" release-runs-templates
chk_fail "8020-AC2 switch unset: release-runs-templates has no no-argument form" 2 "no no-argument form" pmo_working_state_path release-runs-templates

# event-log — the no-argument form, then the same ten rows through the public name.
ev_rows() { # ev_rows <label-prefix> <fn...>
  local p="$1"; shift
  cfg_clear
  chk "${p} default" 0 "${H}/Claude/pmo-instance/evals/results" "$@"
  EVALS_RESULTS_PATH="${FX}/e" chk "${p} EVALS_RESULTS_PATH" 0 "${FX}/e" "$@"
  cfg "operator_instance_evals_results_path = \"${FX}/T\""
  chk "${p} toml" 0 "${FX}/T" "$@"
  EVALS_RESULTS_PATH="${FX}/e" chk "${p} the variable beats toml" 0 "${FX}/e" "$@"
  cfg_clear
  WORKSPACE_ROOT="${FX}/wr" chk "${p} WORKSPACE_ROOT" 0 "${FX}/wr/pmo-instance/evals/results" "$@"
  CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "${p} CLAUDE_WORKSPACE_ROOT" 0 "${FX}/c/pmo-instance/evals/results" "$@"
  WORKSPACE_ROOT="${FX}/wr" CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "${p} WORKSPACE_ROOT beats CLAUDE_WORKSPACE_ROOT" 0 "${FX}/wr/pmo-instance/evals/results" "$@"
  cfg "claude_workspace_root = \"${FX}/tr\""
  chk "${p} toml claude_workspace_root" 0 "${FX}/tr/pmo-instance/evals/results" "$@"
  CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "${p} CLAUDE_WORKSPACE_ROOT beats the toml root" 0 "${FX}/c/pmo-instance/evals/results" "$@"
  cfg_clear
  PMO_INSTANCE_PATH="${FX}/p" chk "${p} ignores PMO_INSTANCE_PATH" 0 "${H}/Claude/pmo-instance/evals/results" "$@"
}
ev_rows "8020-AC2 switch unset: event-log no-argument" pmo_working_state_path event-log
ev_rows "8020-AC2 switch unset: event-log through pmo_evals_results_path" pmo_evals_results_path
chk "8020-AC2 switch unset: event-log _for default" 0 "${W}/pmo-instance/evals/results" pmo_working_state_path_for "${W}" event-log
cfg "operator_instance_evals_results_path = \"${FX}/T\""
chk "8020-AC2 switch unset: event-log _for toml" 0 "${FX}/T" pmo_working_state_path_for "${W}" event-log
cfg_clear
EVALS_RESULTS_PATH="${FX}/e" PMO_INSTANCE_PATH="${FX}/p" WORKSPACE_ROOT="${FX}/wr" CLAUDE_WORKSPACE_ROOT="${FX}/c" \
  chk "8020-AC2 switch unset: event-log _for ignores EVALS_RESULTS_PATH, PMO_INSTANCE_PATH, WORKSPACE_ROOT and CLAUDE_WORKSPACE_ROOT" 0 \
  "${W}/pmo-instance/evals/results" pmo_working_state_path_for "${W}" event-log
# The wrapper runs inside every set -u caller: pin it under /bin/bash (3.2 on macOS) with
# set -euo pipefail and no positional arguments.
BASH32="/bin/bash"; [ -x "${BASH32}" ] || BASH32="bash"
got="$(LIBP="${LIB}" "${BASH32}" -euo pipefail -c '. "$LIBP"; pmo_evals_results_path' 2>&1)"
pin "8020-AC2 switch unset: pmo_evals_results_path under ${BASH32} -euo pipefail with no arguments" "${got}" "${H}/Claude/pmo-instance/evals/results"

# registers, logs, allowlists (working state) and home (leak-risk).
for spec in "registers:/releases/registers:pmo_working_state_path:pmo_working_state_path_for" \
            "logs::pmo_working_state_path:pmo_working_state_path_for" \
            "allowlists::pmo_working_state_path:pmo_working_state_path_for" \
            "home::pmo_leak_risk_path:pmo_leak_risk_path_for"; do
  m="${spec%%:*}"; rest="${spec#*:}"; leaf="${rest%%:*}"; rest="${rest#*:}"; fna="${rest%%:*}"; fnf="${rest#*:}"
  chk "8020-AC2 switch unset: ${m} no-argument default" 0 "${H}/Claude/pmo-instance${leaf}" "${fna}" "${m}"
  CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "8020-AC2 switch unset: ${m} no-argument CLAUDE_WORKSPACE_ROOT" 0 "${FX}/c/pmo-instance${leaf}" "${fna}" "${m}"
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: ${m} no-argument PMO_INSTANCE_PATH" 0 "${FX}/p${leaf}" "${fna}" "${m}"
  chk "8020-AC2 switch unset: ${m} _for default" 0 "${W}/pmo-instance${leaf}" "${fnf}" "${W}" "${m}"
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: ${m} _for PMO_INSTANCE_PATH" 0 "${FX}/p${leaf}" "${fnf}" "${W}" "${m}"
  CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "8020-AC2 switch unset: ${m} _for ignores an ambient CLAUDE_WORKSPACE_ROOT" 0 "${W}/pmo-instance${leaf}" "${fnf}" "${W}" "${m}"
  cfg "claude_workspace_root = \"${FX}/tr\""
  WORKSPACE_ROOT="${FX}/wr" chk "8020-AC2 switch unset: ${m} no-argument ignores WORKSPACE_ROOT and the toml root" 0 "${H}/Claude/pmo-instance${leaf}" "${fna}" "${m}"
  cfg_clear
done
# telemetry and analysis — the unchanged resolvers, through the class resolver.
for spec in "telemetry:operator_instance_working_state_telemetry_path:pmo-platform/local-state/telemetry" \
            "analysis:operator_instance_analysis_path:pmo-platform/analysis"; do
  m="${spec%%:*}"; rest="${spec#*:}"; key="${rest%%:*}"; leaf="${rest#*:}"
  chk "8020-AC2 switch unset: ${m} _for default" 0 "${W}/${leaf}" pmo_working_state_path_for "${W}" "${m}"
  cfg "${key} = \"${FX}/T\""
  chk "8020-AC2 switch unset: ${m} _for toml" 0 "${FX}/T" pmo_working_state_path_for "${W}" "${m}"
  cfg_clear
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: ${m} _for ignores PMO_INSTANCE_PATH" 0 "${W}/${leaf}" pmo_working_state_path_for "${W}" "${m}"
  CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "8020-AC2 switch unset: ${m} _for ignores CLAUDE_WORKSPACE_ROOT" 0 "${W}/${leaf}" pmo_working_state_path_for "${W}" "${m}"
  chk_fail "8020-AC2 switch unset: ${m} has no no-argument form" 2 "no no-argument form" pmo_working_state_path "${m}"
done
# usage-store (install-scoped).
chk "8020-AC2 switch unset: usage-store _for default" 0 "${W}/pmo-instance/finops" pmo_install_state_path_for "${W}" usage-store
cfg "operator_instance_finops_store_path = \"${FX}/T\""
chk "8020-AC2 switch unset: usage-store _for toml" 0 "${FX}/T" pmo_install_state_path_for "${W}" usage-store
cfg_clear
PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: usage-store _for ignores PMO_INSTANCE_PATH" 0 "${W}/pmo-instance/finops" pmo_install_state_path_for "${W}" usage-store
# needles and roster (leak-risk).
for spec in "needles:localized-context-needles.txt:PMO_LOCALIZED_NEEDLES" "roster:people-roster.yaml:PMO_PEOPLE_ROSTER"; do
  m="${spec%%:*}"; rest="${spec#*:}"; leaf="${rest%%:*}"; var="${rest#*:}"
  chk "8020-AC2 switch unset: ${m} no-argument default" 0 "${H}/Claude/pmo-instance/${leaf}" pmo_leak_risk_path "${m}"
  CLAUDE_WORKSPACE_ROOT="${FX}/c" chk "8020-AC2 switch unset: ${m} no-argument CLAUDE_WORKSPACE_ROOT" 0 "${FX}/c/pmo-instance/${leaf}" pmo_leak_risk_path "${m}"
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: ${m} no-argument PMO_INSTANCE_PATH" 0 "${FX}/p/${leaf}" pmo_leak_risk_path "${m}"
  run_r env "${var}=${FX}/direct" "${BASH32}" -c '. "$1"; pmo_leak_risk_path "$2"' _ "${LIB}" "${m}"
  pin "8020-AC2 switch unset: ${m} no-argument direct variable ${var}" "${OUT}" "${FX}/direct"
  chk "8020-AC2 switch unset: ${m} _for default" 0 "${W}/pmo-instance/${leaf}" pmo_leak_risk_path_for "${W}" "${m}"
  PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC2 switch unset: ${m} _for PMO_INSTANCE_PATH" 0 "${FX}/p/${leaf}" pmo_leak_risk_path_for "${W}" "${m}"
  run_r env "${var}=${FX}/direct" "${BASH32}" -c '. "$1"; pmo_leak_risk_path_for "$2" "$3"' _ "${LIB}" "${W}" "${m}"
  pin "8020-AC2 switch unset: ${m} _for direct variable ${var}" "${OUT}" "${FX}/direct"
done
# The switch's off states, and --repo not read while it is off (no git process runs).
for val in "ABSENT" '""' '"  "'; do
  if [ "${val}" = ABSENT ]; then cfg_clear; else cfg "governed_homes = ${val}"; fi
  PMO_SRC_ROOT="${W}/widget" chk "8020-AC2 switch unset: governed_homes ${val} gives the default, --repo and PMO_SRC_ROOT set" 0 \
    "${W}/pmo-instance/hub-state" pmo_working_state_path_for "${W}" release-runs --repo "${W1}"
  chk "8020-AC2 switch unset: governed_homes ${val} — pmo_governed_homes_for prints off" 0 "off" pmo_governed_homes_for "${W}" "${W1}"
done
cfg_clear
git() { printf 'x' >> "${FX}/.gitcalls"; command git "$@"; }
chk "8020-AC2 switch unset: pmo_evals_results_path --repo is not read while the switch is off" 0 "${H}/Claude/pmo-instance/evals/results" \
  pmo_evals_results_path --repo /nonexistent
chk "8020-AC2 switch unset: pmo_working_state_path_for --repo is not read while the switch is off" 0 "${W}/pmo-instance/hub-state" \
  pmo_working_state_path_for "${W}" release-runs --repo /nonexistent
unset -f git
pin "8020-AC2 switch unset: no git process ran for a switch-off resolution" "$(cat "${FX}/.gitcalls" 2>/dev/null)" ""
# SENSITIVITY: a copy of the resolver with the hub-state leaf perturbed must mismatch.
sed 's#/hub-state#/hub-statex#g' "${LIB}" > "${FX}/lib-perturbed.sh"
miss="$( MODE=count; MISS=0; . "${FX}/lib-perturbed.sh"; ac2_release_runs; printf '%s' "${MISS}" )"
if [ "${miss:-0}" -ge 1 ]; then report "8020-AC2 switch unset: SENSITIVITY — the perturbed resolver mismatches ${miss} release-runs row(s)" 1
else report "8020-AC2 switch unset: SENSITIVITY — the perturbed resolver mismatches at least one release-runs row" 0 "0 mismatches: a broken probe"; fi
. "${LIB}"

# =====================================================================================
printf '\n8020-AC3 switch set — fixture repository and fixture XDG roots\n'
cfg 'governed_homes = "widget,bare-widget"'
export PMO_SRC_ROOT="${W}/widget"
for m in release-runs event-log registers logs allowlists telemetry; do
  chk "8020-AC3 switch set: ${m} from the worktree, _for" 0 "${W}/widget/local-state/${m}" pmo_working_state_path_for "${W}" "${m}" --repo "${W1}"
done
chk "8020-AC3 switch set: analysis from the worktree, _for" 0 "${W}/widget/analysis" pmo_working_state_path_for "${W}" analysis --repo "${W1}"
for m in release-runs event-log registers logs allowlists; do
  CLAUDE_WORKSPACE_ROOT="${W}" chk "8020-AC3 switch set: ${m} from the worktree, no-argument" 0 "${W}/widget/local-state/${m}" pmo_working_state_path "${m}" --repo "${W1}"
done
CLAUDE_WORKSPACE_ROOT="${W}" chk "8020-AC3 switch set: pmo_evals_results_path --repo the worktree" 0 "${W}/widget/local-state/event-log" pmo_evals_results_path --repo "${W1}"
chk "8020-AC3 switch set: needles, _for" 0 "${FX}/xdg-data/pmo-platform/pmo-private/localized-context-needles.txt" pmo_leak_risk_path_for "${W}" needles
chk "8020-AC3 switch set: roster, _for" 0 "${FX}/xdg-data/pmo-platform/pmo-private/people-roster.yaml" pmo_leak_risk_path_for "${W}" roster
chk "8020-AC3 switch set: home, _for" 0 "${FX}/xdg-data/pmo-platform/pmo-private" pmo_leak_risk_path_for "${W}" home
CLAUDE_WORKSPACE_ROOT="${W}" chk "8020-AC3 switch set: home, no-argument" 0 "${FX}/xdg-data/pmo-platform/pmo-private" pmo_leak_risk_path home
chk "8020-AC3 switch set: usage-store" 0 "${FX}/xdg-state/pmo-platform/telemetry" pmo_install_state_path_for "${W}" usage-store
# controls
chk "8020-AC3 switch set: control — an unlisted repository keeps today's path (per repository)" 0 "${W}/pmo-instance/hub-state" \
  pmo_working_state_path_for "${W}" release-runs --repo "${W}/plain"
chk "8020-AC3 switch set: control — pmo_inbox_path_for unchanged" 0 "${W}/pmo-instance/inbox" pmo_inbox_path_for "${W}"
chk "8020-AC3 switch set: control — pmo_operations_path_for unchanged" 0 "${W}/projects" pmo_operations_path_for "${W}"
chk "8020-AC3 switch set: control — pmo_instance_path_for unchanged" 0 "${W}/pmo-instance" pmo_instance_path_for "${W}"
CLAUDE_WORKSPACE_ROOT="${W}" chk "8020-AC3 switch set: control — pmo_localized_needles unchanged (not switch-aware this release)" 0 \
  "${W}/pmo-instance/localized-context-needles.txt" pmo_localized_needles
chk_fail "8020-AC3 switch set: a listed repository with no local-state/ fails loud" 3 "is absent" pmo_working_state_path_for "${W}" logs --repo "${W}/bare-widget"
chk_fail "8020-AC3 switch set: U5 near-miss — an unregistered member resolves to no home" 2 "unknown working-state member" \
  pmo_working_state_path_for "${W}" scratch --repo "${W1}"
pin "8020-AC3 switch set: U5 near-miss — nothing exists under local-state/scratch" "$([ -e "${W}/widget/local-state/scratch" ] && echo exists)" ""
for bad in '"../escape"' '"a/b"' '["widget"]'; do
  cfg "governed_homes = ${bad}"
  chk_fail "8020-AC3 switch set: entry grammar — governed_homes = ${bad} is refused" 3 "entry grammar" pmo_working_state_path_for "${W}" logs --repo "${W1}"
done
cfg 'governed_homes = "widget,bare-widget"' "operator_instance_hub_state_path = \"${FX}/T\""
chk "8020-AC3 switch set: the member's own override wins on the governed arm (D-Overrides)" 0 "${FX}/T" pmo_working_state_path_for "${W}" release-runs --repo "${W1}"
cfg 'governed_homes = "widget,bare-widget"'
XDG_DATA_HOME="relative/x" PMO_PLATFORM_CONFIG_ROOT="" chk "8020-AC3 switch set: a relative XDG_DATA_HOME is ignored (config root unset)" 0 \
  "${H}/.local/share/pmo-platform/pmo-private" pmo_leak_risk_path_for "${W}" home
chk "8020-AC3 switch set: --home today returns today's arm" 0 "${W}/pmo-instance/hub-state" pmo_working_state_path_for "${W}" release-runs --repo "${W1}" --home today
fx_mkdir "${W}/plain/local-state"
chk "8020-AC3 switch set: --home governed reaches an unlisted repository's governed arm" 0 "${W}/plain/local-state/logs" \
  pmo_working_state_path_for "${W}" logs --repo "${W}/plain" --home governed
# CD-4 — run-scoped members name their repository once the switch is non-empty.
cfg 'governed_homes = "widget"'
for m in release-runs event-log registers; do
  chk_fail "8020-AC3 switch set: CD-4 — run-scoped ${m} with no --repo exits 2" 2 "needs --repo" pmo_working_state_path_for "${W}" "${m}"
done
CLAUDE_WORKSPACE_ROOT="${W}" chk_fail "8020-AC3 switch set: CD-4 — a bare pmo_evals_results_path exits 2" 2 "needs --repo" pmo_evals_results_path
chk "8020-AC3 switch set: CD-4 control — logs with no --repo resolves the platform context" 0 "${W}/widget/local-state/logs" pmo_working_state_path_for "${W}" logs
chk "8020-AC3 switch set: CD-4 control — release-runs --home today with no --repo" 0 "${W}/pmo-instance/hub-state" pmo_working_state_path_for "${W}" release-runs --home today
# CD-2 — a set family-wide relocation is refused on the governed arm, not dropped.
cfg 'governed_homes = "widget,bare-widget"'
for m in release-runs release-runs-templates registers logs allowlists; do
  PMO_INSTANCE_PATH="${FX}/p" chk_fail "8020-AC3 switch set: CD-2 — PMO_INSTANCE_PATH refused for ${m}" 3 "PMO_INSTANCE_PATH" \
    pmo_working_state_path_for "${W}" "${m}" --repo "${W1}"
done
for m in needles roster home; do
  PMO_INSTANCE_PATH="${FX}/p" chk_fail "8020-AC3 switch set: CD-2 — PMO_INSTANCE_PATH refused for ${m}" 3 "PMO_INSTANCE_PATH" pmo_leak_risk_path_for "${W}" "${m}"
done
PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC3 switch set: CD-2 — event-log ignores PMO_INSTANCE_PATH, so it is not refused" 0 "${W}/widget/local-state/event-log" \
  pmo_working_state_path_for "${W}" event-log --repo "${W1}"
PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC3 switch set: CD-2 — telemetry is not refused" 0 "${W}/widget/local-state/telemetry" pmo_working_state_path_for "${W}" telemetry --repo "${W1}"
PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC3 switch set: CD-2 — analysis is not refused" 0 "${W}/widget/analysis" pmo_working_state_path_for "${W}" analysis --repo "${W1}"
PMO_INSTANCE_PATH="${FX}/p" chk "8020-AC3 switch set: CD-2 — usage-store is not refused" 0 "${FX}/xdg-state/pmo-platform/telemetry" pmo_install_state_path_for "${W}" usage-store
WORKSPACE_ROOT="${FX}/wr" CLAUDE_WORKSPACE_ROOT="${W}" chk_fail "8020-AC3 switch set: CD-2 — WORKSPACE_ROOT refused for the no-argument event-log form" 3 "WORKSPACE_ROOT" \
  pmo_working_state_path event-log --repo "${W1}"
WORKSPACE_ROOT="${FX}/wr" chk "8020-AC3 switch set: CD-2 — the _for event-log form does not honor WORKSPACE_ROOT, so it is not refused" 0 \
  "${W}/widget/local-state/event-log" pmo_working_state_path_for "${W}" event-log --repo "${W1}"
# One direct-override set per member: both forms agree.
EVALS_RESULTS_PATH="${FX}/e" CLAUDE_WORKSPACE_ROOT="${W}" chk "8020-AC3 switch set: one override set — EVALS_RESULTS_PATH, no-argument" 0 "${FX}/e" pmo_working_state_path event-log --repo "${W1}"
EVALS_RESULTS_PATH="${FX}/e" chk "8020-AC3 switch set: one override set — EVALS_RESULTS_PATH, _for" 0 "${FX}/e" pmo_working_state_path_for "${W}" event-log --repo "${W1}"
cfg 'governed_homes = "widget,bare-widget"' "operator_instance_evals_results_path = \"${FX}/t\""
CLAUDE_WORKSPACE_ROOT="${W}" chk "8020-AC3 switch set: one override set — the config-root key, no-argument" 0 "${FX}/t" pmo_working_state_path event-log --repo "${W1}"
chk "8020-AC3 switch set: one override set — the config-root key, _for" 0 "${FX}/t" pmo_working_state_path_for "${W}" event-log --repo "${W1}"
cfg 'governed_homes = "widget,bare-widget"'
chk "8020-AC3 switch set: S-02 governed — release-runs-templates resolves S-01's home" 0 "${W}/widget/local-state/release-runs" \
  pmo_working_state_path_for "${W}" release-runs-templates --repo "${W1}"
chk_fail "8020-AC3 switch set: S-02 — release-runs-templates is not run-scoped" 2 "run-scoped" \
  pmo_working_state_path_for "${W}" release-runs-templates --repo "${W1}" --run-class leak-risk

# =====================================================================================
printf '\n8020-AC4 embargoed run — the leak-risk home whatever the switch says\n'
EMB="${FX}/xdg-data/pmo-platform/pmo-private/embargoed/widget"
for state in absent set; do
  if [ "${state}" = absent ]; then cfg_clear; else cfg 'governed_homes = "widget"'; fi
  for m in release-runs event-log registers; do
    chk "8020-AC4 embargoed run: ${m}, switch ${state}" 0 "${EMB}/${m}" pmo_working_state_path_for "${W}" "${m}" --run-class leak-risk --repo "${W1}"
  done
  chk_fail "8020-AC4 embargoed run: no --repo exits 2, switch ${state}" 2 "needs --repo" pmo_working_state_path_for "${W}" release-runs --run-class leak-risk
done
cfg_clear
chk "8020-AC4 embargoed run: control — --run-class working-state, switch absent, is today" 0 "${W}/pmo-instance/hub-state" \
  pmo_working_state_path_for "${W}" release-runs --run-class working-state --repo "${W1}"
cfg 'governed_homes = "widget"'
chk "8020-AC4 embargoed run: control — --run-class working-state, switch set, is governed" 0 "${W}/widget/local-state/release-runs" \
  pmo_working_state_path_for "${W}" release-runs --run-class working-state --repo "${W1}"
chk_fail "8020-AC4 embargoed run: an empty --run-class exits 2" 2 "unknown run class" pmo_working_state_path_for "${W}" release-runs --run-class "" --repo "${W1}"
chk_fail "8020-AC4 embargoed run: an unknown --run-class exits 2" 2 "unknown run class" pmo_working_state_path_for "${W}" release-runs --run-class embargoed --repo "${W1}"
chk_fail "8020-AC4 embargoed run: leak-risk on a non-run-scoped member exits 2" 2 "run-scoped" pmo_working_state_path_for "${W}" logs --run-class leak-risk --repo "${W1}"
chk "8020-AC4 embargoed run: --home today wins, giving S-01's today path" 0 "${W}/pmo-instance/hub-state" \
  pmo_working_state_path_for "${W}" release-runs --home today --run-class leak-risk
cfg 'governed_homes = "widget"' "operator_instance_hub_state_path = \"${FX}/T\""
chk "8020-AC4 embargoed run: a hub-state override does not capture the embargoed result" 0 "${EMB}/release-runs" \
  pmo_working_state_path_for "${W}" release-runs --run-class leak-risk --repo "${W1}"
cfg 'governed_homes = "widget"'
PMO_INSTANCE_PATH="${FX}/p" chk_fail "8020-AC4 embargoed run: a set PMO_INSTANCE_PATH is refused" 3 "PMO_INSTANCE_PATH" \
  pmo_working_state_path_for "${W}" release-runs --run-class leak-risk --repo "${W1}"
XDG_DATA_HOME="" chk_fail "8020-AC4 embargoed run: a sandboxed config root with no XDG_DATA_HOME is refused" 3 "sandboxed config root without XDG_DATA_HOME" \
  pmo_working_state_path_for "${W}" release-runs --run-class leak-risk --repo "${W1}"

# =====================================================================================
printf '\n8020-AC6 work-tree refusal — a filesystem walk; git is never asked\n'
cfg 'governed_homes = "widget"'
git() { : > "${FX}/.gitmarker"; return 99; }
XDG_DATA_HOME="${W}/widget/data" chk_fail "8020-AC6 work-tree refusal: an untracked folder inside the tree" 3 "inside a git work tree" \
  pmo_leak_risk_path_for "${W}" home --home governed
printf 'data/\n' > "${W}/widget/.gitignore"
XDG_DATA_HOME="${W}/widget/data" chk_fail "8020-AC6 work-tree refusal: a git-ignored folder inside the tree (ignored or not)" 3 "inside a git work tree" \
  pmo_leak_risk_path_for "${W}" home --home governed
XDG_DATA_HOME="${W}/widget/.git/x" chk_fail "8020-AC6 work-tree refusal: inside the .git directory" 3 "inside a git work tree" \
  pmo_leak_risk_path_for "${W}" home --home governed
XDG_STATE_HOME="${W}/widget/data" chk_fail "8020-AC6 work-tree refusal: usage-store under an in-tree XDG_STATE_HOME" 3 "inside a git work tree" \
  pmo_install_state_path_for "${W}" usage-store --home governed
PMO_LOCALIZED_NEEDLES="${W}/widget/needles.txt" chk_fail "8020-AC6 work-tree refusal: a needles override pointing into the tree" 3 "inside a git work tree" \
  pmo_leak_risk_path_for "${W}" needles --home governed
GIT_CEILING_DIRECTORIES="${W}/widget" XDG_DATA_HOME="${W}/widget/data/sub" chk_fail "8020-AC6 work-tree refusal: GIT_CEILING_DIRECTORIES cannot open it (the reproduced fail-open)" 3 \
  "inside a git work tree" pmo_leak_risk_path_for "${W}" home --home governed
XDG_DATA_HOME="${FX}/gitfile/x" chk_fail "8020-AC6 work-tree refusal: a .git FILE at an ancestor" 3 "inside a git work tree" pmo_leak_risk_path_for "${W}" home --home governed
XDG_DATA_HOME="${FX}/bare.git/sub" chk_fail "8020-AC6 work-tree refusal: a git directory by structure (bare)" 3 "inside a git work tree" pmo_leak_risk_path_for "${W}" home --home governed
XDG_DATA_HOME="${FX}/plain/.git/x" chk_fail "8020-AC6 work-tree refusal: a .git path component that does not exist" 3 "inside a git work tree" pmo_leak_risk_path_for "${W}" home --home governed
XDG_DATA_HOME="${FX}/link" chk_fail "8020-AC6 work-tree refusal: a symlink into a tree" 3 "inside a git work tree" pmo_leak_risk_path_for "${W}" home --home governed
XDG_DATA_HOME="${FX}/dangle/d" chk_fail "8020-AC6 work-tree refusal: an ancestor whose .git is a dangling symlink" 3 "inside a git work tree" pmo_leak_risk_path_for "${W}" home --home governed
fx_mkdir "${FX}/outside"
XDG_DATA_HOME="${FX}/outside" chk "8020-AC6 work-tree refusal: control — a path outside every tree resolves" 0 "${FX}/outside/pmo-platform/pmo-private" \
  pmo_leak_risk_path_for "${W}" home --home governed
GIT_DIR="${W}/plain/.git" XDG_DATA_HOME="${FX}/outside" chk "8020-AC6 work-tree refusal: control — an exported GIT_DIR does not change the verdict" 0 \
  "${FX}/outside/pmo-platform/pmo-private" pmo_leak_risk_path_for "${W}" home --home governed
unset -f git
pin "8020-AC6 work-tree refusal: the walk ran no git process (the marker is absent)" "$([ -e "${FX}/.gitmarker" ] && echo present)" ""
XDG_DATA_HOME="${W}/widget/data" chk_fail "8020-AC6 work-tree refusal: the embargoed arm under an in-tree XDG_DATA_HOME" 3 "inside a git work tree" \
  pmo_working_state_path_for "${W}" release-runs --run-class leak-risk --repo "${W1}"
chk_fail "8020-AC6 work-tree refusal: designation's git error (a .git file pointing nowhere) refuses" 3 "" pmo_working_state_path_for "${W}" logs --repo "${FX}/gitfile/x"
cfg_clear
PMO_INSTANCE_PATH="${W}/widget/inst" chk "8020-AC6 work-tree refusal: control — switch off, an in-tree PMO_INSTANCE_PATH is today's path, untouched" 0 \
  "${W}/widget/inst" pmo_leak_risk_path_for "${W}" home

# =====================================================================================
printf '\n8020-AC7 designated main checkout — one rule, a relocated checkout\n'
cfg 'governed_homes = "widget"'
chk "8020-AC7 designated main checkout: a worktree designates its main checkout" 0 "${W}/widget" pmo_main_checkout_for "${W}" "${W1}"
run_r pmo_main_checkout_for "${W}" "${W1}"
pin "8020-AC7 designated main checkout: the rule is not a hard-coded pmo-platform path" "$([ "${OUT}" != "${W}/pmo-platform" ] && echo distinct)" "distinct"
chk "8020-AC7 designated main checkout: a second clone matched by origin (scp form) designates the listed checkout" 0 "${W}/widget" \
  pmo_main_checkout_for "${W}" "${FX}/elsewhere/widget-copy"
chk "8020-AC7 designated main checkout: that clone reads on" 0 "on" pmo_governed_homes_for "${W}" "${FX}/elsewhere/widget-copy"
chk "8020-AC7 designated main checkout: same name, different origin and distinct history is another repository (off)" 0 "${FX}/other/widget" \
  pmo_main_checkout_for "${W}" "${FX}/other/widget"
chk "8020-AC7 designated main checkout: that repository reads off" 0 "off" pmo_governed_homes_for "${W}" "${FX}/other/widget"
chk "8020-AC7 designated main checkout: same name, no origin, shared history designates the listed checkout" 0 "${W}/widget" \
  pmo_main_checkout_for "${W}" "${FX}/noorigin/widget"
chk "8020-AC7 designated main checkout: a fork-workflow clone (origins differ, roots intersect)" 0 "${W}/widget" pmo_main_checkout_for "${W}" "${FX}/forks/widget"
chk_fail "8020-AC7 designated main checkout: a shallow same-name clone cannot confirm identity" 3 "shallow" pmo_main_checkout_for "${W}" "${FX}/shallow/widget"
chk "8020-AC7 designated main checkout: an unlisted repository is its own main worktree" 0 "${W}/plain" pmo_main_checkout_for "${W}" "${W}/plain"
cfg 'governed_homes = "widget-alt,widget"'
chk "8020-AC7 designated main checkout: first-match order (widget-alt listed first)" 0 "${W}/widget-alt" pmo_main_checkout_for "${W}" "${FX}/elsewhere/widget-copy"
cfg 'governed_homes = "widget,widget-alt"'
chk "8020-AC7 designated main checkout: first-match order (widget listed first)" 0 "${W}/widget" pmo_main_checkout_for "${W}" "${FX}/elsewhere/widget-copy"
cfg_clear

# =====================================================================================
printf '\n8020-D split roots — HOME and the config root apart (D-ConfigRoot D)\n'
SH="${FX}/home-h"; SC="${FX}/cfg"
mkdir -p "${SH}/.config/pmo-platform" "${SC}"
hcfg() { printf '%s\n' "$@" > "${SH}/.config/pmo-platform/operator.toml"; }
ccfg() { printf '%s\n' "$@" > "${SC}/operator.toml"; }
ccfg 'governed_homes = "widget"' "operator_instance_hub_state_path = \"${FX}/T_cfg\""; hcfg "operator_instance_hub_state_path = \"${FX}/T_home\""
HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" chk "8020-D split roots: D1 — the governed arm reads the override through the config root" 0 "${FX}/T_cfg" \
  pmo_working_state_path_for "${W}" release-runs --repo "${W1}"
ccfg ""; hcfg 'governed_homes = "widget"' "operator_instance_hub_state_path = \"${FX}/T_home\""
HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" chk "8020-D split roots: D2 — a switch in HOME's toml is not read; today's arm reads HOME" 0 "${FX}/T_home" \
  pmo_working_state_path_for "${W}" release-runs --repo "${W1}"
ccfg 'governed_homes = "widget"'; hcfg ""
for xv in "" "relative/x"; do
  HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" XDG_DATA_HOME="${xv}" chk_fail "8020-D split roots: D3 — needles refused with XDG_DATA_HOME='${xv}'" 3 \
    "sandboxed config root without XDG_DATA_HOME" pmo_leak_risk_path_for "${W}" needles
done
HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" XDG_DATA_HOME="${FX}/xd" chk "8020-D split roots: D3 — with XDG_DATA_HOME set it resolves" 0 \
  "${FX}/xd/pmo-platform/pmo-private/localized-context-needles.txt" pmo_leak_risk_path_for "${W}" needles
HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" XDG_STATE_HOME="" chk_fail "8020-D split roots: D4 — usage-store refused with no XDG_STATE_HOME" 3 \
  "sandboxed config root without XDG_STATE_HOME" pmo_install_state_path_for "${W}" usage-store
HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" XDG_STATE_HOME="${FX}/xs" chk "8020-D split roots: D4 — with XDG_STATE_HOME set it resolves" 0 \
  "${FX}/xs/pmo-platform/telemetry" pmo_install_state_path_for "${W}" usage-store
HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" CLAUDE_WORKSPACE_ROOT="" chk_fail "8020-D split roots: D5 — a no-argument governed call with no workspace root is refused" 3 \
  "no workspace root" pmo_working_state_path logs
ccfg 'governed_homes = "widget"' "claude_workspace_root = \"${W}\""
HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" CLAUDE_WORKSPACE_ROOT="" chk "8020-D split roots: D5 — with the config root's claude_workspace_root it resolves" 0 \
  "${W}/widget/local-state/logs" pmo_working_state_path logs
ccfg 'governed_homes = "widget"'; hcfg "claude_workspace_root = \"${W}\""
HOME="${SH}" PMO_PLATFORM_CONFIG_ROOT="${SC}" CLAUDE_WORKSPACE_ROOT="" chk_fail "8020-D split roots: D6 — the key in HOME's toml only is not read by the governed arm" 3 \
  "no workspace root" pmo_working_state_path logs
unset PMO_SRC_ROOT

# =====================================================================================
printf '\n8020-PR1 deploy.sh refusal — a refused event-log path is never a benign SKIP\n'
DEPLOY="${REPO_ROOT}/core/deploy/deploy.sh"
DE_TEXT="$(sed -n '/^_de_compute_verdict() {/,/^}/p' "${DEPLOY}")"
pin "8020-PR1 deploy.sh refusal: the gate engine extracts with exactly one closing brace" "$(printf '%s\n' "${DE_TEXT}" | grep -c '^}$')" "1"
A1N="$(grep -c '^    local c19_evals_dir=' "${DEPLOY}")"
A2N="$(grep -c '^    elif \[\[ ! -f "\$c19_write_log" \]\]; then$' "${DEPLOY}")"
pin "8020-PR1 deploy.sh refusal: each Check 19 window anchor occurs exactly once" "${A1N}:${A2N}" "1:1"
C19_TEXT="$(awk '/^    local c19_evals_dir=/{on=1} /^    elif \[\[ ! -f "\$c19_write_log" \]\]; then$/{on=0} on{print}' "${DEPLOY}")"
pr1_engine() { # pr1_engine <function text> — the verdict line, run from the repository root
  printf '%s\n' "$1" > "${FX}/de.sh"
  ( cd "${REPO_ROOT}" || exit 1; unset DE_LOG DE_RELEASE_LOG DE_ASSERTED; . "${FX}/de.sh"; _de_compute_verdict lifecycle 2>/dev/null )
}
pr1_c19() { # pr1_c19 <window text> — the Check 19 window's log and flag lines
  { printf 'c19_run() {\n'; printf '%s\n' "$1"; printf '    fi\n}\n'; } > "${FX}/c19.sh"
  ( cd "${REPO_ROOT}" || exit 1
    log() { printf 'LOG:%s\n' "$*"; }
    flag_warn_or_issue() { printf 'FLAG:%s:%s\n' "$1" "$2"; }
    . "${FX}/c19.sh"; c19_run 2>/dev/null )
}
export CLAUDE_WORKSPACE_ROOT="${FX}/pr1"
cfg 'governed_homes = "a/b"'
v="$(pr1_engine "${DE_TEXT}")"
case "${v}" in "UNRESOLVED "*) report "8020-PR1 deploy.sh refusal: PR1-a gate engine, refused → UNRESOLVED" 1 ;; *) report "8020-PR1 deploy.sh refusal: PR1-a gate engine, refused → UNRESOLVED" 0 "got '${v}'" ;; esac
v="$(DECISION_EMISSION_CUTOVER_SLUG=__none__ pr1_engine "${DE_TEXT}")"
pin "8020-PR1 deploy.sh refusal: PR1-c refused but dormant — the dormant sentinel wins" "${v}" "SKIP decision-emission gate dormant (DECISION_EMISSION_CUTOVER_SLUG=__none__)"
c19="$(pr1_c19 "${C19_TEXT}")"
nflag="$(printf '%s\n' "${c19}" | grep -c 'FLAG:pipeline-event-log-integrity:path-resolution failure: core/deploy/lib-instance-path.sh refused')"
nskip="$(printf '%s\n' "${c19}" | grep -c 'SKIP:')"
pin "8020-PR1 deploy.sh refusal: PR1-d Check 19, refused → one flag line, no SKIP" "${nflag}:${nskip}" "1:0"
cfg_clear
v="$(pr1_engine "${DE_TEXT}")"
pin "8020-PR1 deploy.sh refusal: PR1-b gate engine, switch absent → today's SKIP text" "${v}" \
  "SKIP no event log at ${FX}/pr1/pmo-instance/evals/results/pipeline-event-log.md (operator-instance state — fresh install / CI; nothing to assert)"
c19="$(pr1_c19 "${C19_TEXT}")"
nflag="$(printf '%s\n' "${c19}" | grep -c 'FLAG:')"
nskip="$(printf '%s\n' "${c19}" | grep -c "SKIP:  no event log at ${FX}/pr1/pmo-instance/evals/results/pipeline-event-log.md")"
pin "8020-PR1 deploy.sh refusal: PR1-e Check 19, switch absent → no flag, today's SKIP" "${nflag}:${nskip}" "0:1"
cfg 'governed_homes = "a/b"'
v="$(pr1_engine "${DE_TEXT// || de_unresolved=1/}")"
case "${v}" in "UNRESOLVED "*) report "8020-PR1 deploy.sh refusal: PR1-f mutation — without the gate's check, PR1-a must fail" 0 "the mutated engine still printed UNRESOLVED: a broken probe" ;;
  *) report "8020-PR1 deploy.sh refusal: PR1-f mutation — without the gate's check, PR1-a fails" 1 ;; esac
c19="$(pr1_c19 "${C19_TEXT// || c19_unresolved=1/}")"
nflag="$(printf '%s\n' "${c19}" | grep -c 'path-resolution failure: core/deploy/lib-instance-path.sh refused')"
if [ "${nflag}" = 0 ]; then report "8020-PR1 deploy.sh refusal: PR1-f mutation — without Check 19's check, PR1-d fails" 1
else report "8020-PR1 deploy.sh refusal: PR1-f mutation — without Check 19's check, PR1-d must fail" 0 "the mutated window still flagged: a broken probe"; fi
cfg_clear
unset CLAUDE_WORKSPACE_ROOT
PR1G_ALL='pmo_evals_results_path'
PR1G_OK='pmo_evals_results_path[^)]*\)" *\|\| '
pr1g() { grep -v '^[[:space:]]*#' "$1" | grep -cE "$2"; }
pin "8020-PR1 deploy.sh refusal: PR1-g exactly two non-comment lines name the event-log resolver, both checked" \
  "$(pr1g "${DEPLOY}" "${PR1G_ALL}"):$(pr1g "${DEPLOY}" "${PR1G_OK}")" "2:2"
sed -e 's/)" || de_unresolved=1/)"/' -e 's/)" || c19_unresolved=1/)"/' "${DEPLOY}" > "${FX}/deploy-mutated.sh"
pin "8020-PR1 deploy.sh refusal: PR1-g sensitivity — the same predicate on an unchecked copy counts 0" "$(pr1g "${FX}/deploy-mutated.sh" "${PR1G_OK}")" "0"

# =====================================================================================
printf '\nCIAC-3 default-off — the switch ships off, and nothing tells an operator to set it\n'
ADR_FILES="$(ls "${REPO_ROOT}"/core/ADRs/ADR-*-class-homes-switch-and-designation.md 2>/dev/null)"
pin "CIAC-3 default-off: exactly one decision record carries the contract" "$(printf '%s\n' "${ADR_FILES}" | grep -c 'class-homes-switch-and-designation')" "1"
pin "CIAC-3 default-off: the template ships the switch empty" "$(grep -cx 'governed_homes = ""' "${REPO_ROOT}/core/config/operator.toml.template")" "1"
pin "CIAC-3 default-off: the schema declares it opt-in with an empty default" \
  "$(awk '/"key": "governed_homes"/{on=1} on && /"delivery": "opt-in"/{d=1} on && /"default": ""/{e=1} on && /^[[:space:]]*}/{on=0} END{print d+0 ":" e+0}' \
     "${REPO_ROOT}/core/config/operator-toml-schema.json")" "1:1"
CIAC3_SET='governed_homes[[:space:]]*=[[:space:]]*"[^"]'
CIAC3_IMP='(^|[.!?:;][[:space:]]+|^[[:space:]]*#[[:space:]]*|^[[:space:]]*[-*|][[:space:]]*)(Set|Add|List|Flip|Enable)[[:space:]]+[^.]*governed_homes'
CIAC3_N=0; CIAC3_SEEN=0
for f in core/deploy/lib-instance-path.sh core/config/operator.toml.template core/config/operator-toml-schema.json \
         core/standards/instance-data-placement-standard.md docs/platform-config-reference.md core/schemas/platform-config-schema.md \
         core/ADRs/README.md ${ADR_FILES}; do
  case "${f}" in /*) p="${f}" ;; *) p="${REPO_ROOT}/${f}" ;; esac
  if [ -f "${p}" ]; then
    CIAC3_SEEN=$((CIAC3_SEEN + 1))
    CIAC3_N=$((CIAC3_N + $(grep -cE "${CIAC3_SET}" "${p}") + $(grep -cE "${CIAC3_IMP}" "${p}")))
  fi
done
pin "CIAC-3 default-off: the scan read all eight surfaces" "${CIAC3_SEEN}" "8"
pin "CIAC-3 default-off: no non-empty assignment and no imperative to set the switch" "${CIAC3_N}" "0"
printf '# Set governed_homes = "pmo-platform" to cut over.\n' > "${FX}/ciac3-planted.txt"
pin "CIAC-3 default-off: SENSITIVITY — a planted flip instruction is flagged by both patterns" \
  "$(grep -cE "${CIAC3_SET}" "${FX}/ciac3-planted.txt"):$(grep -cE "${CIAC3_IMP}" "${FX}/ciac3-planted.txt")" "1:1"

# =====================================================================================
printf '\n8020-AC8 fixture-root containment, and CIAC-4 sandbox parity\n'
pre=1
for v in "${HOME}" "${PMO_PLATFORM_CONFIG_ROOT}" "${XDG_DATA_HOME}" "${XDG_STATE_HOME}" "${W}" "${TMPDIR}"; do
  case "${v}" in "${FX}"/*) ;; *) pre=0 ;; esac
done
for v in WORKSPACE_ROOT PMO_INSTANCE_PATH EVALS_RESULTS_PATH HUB_STATE_PATH PMO_LOCALIZED_NEEDLES PMO_PEOPLE_ROSTER PMO_SRC_ROOT CLAUDE_WORKSPACE_ROOT; do
  if eval "[ -n \"\${${v}+x}\" ]"; then pre=0; fi
done
report "8020-AC8 fixture-root containment: preflight — every base is under the fixture root and every direct override is unset" "${pre}"
outside="$(grep -v "^${FX}/" "${FX}/ledger" | grep -c '')"
nled="$(grep -c '' "${FX}/ledger")"
pin "8020-AC8 fixture-root containment: every one of the ${nled} resolved values lies under the fixture root" "${outside}" "0" \
  "outside: $(grep -v "^${FX}/" "${FX}/ledger" | tr '\n' ' ')"
run_r env HOME="${OUTSIDE_ROOT}" PMO_PLATFORM_CONFIG_ROOT= XDG_DATA_HOME= "${BASH32}" -c '. "$1"; pmo_leak_risk_path home --home governed' _ "${LIB}"
case "${OUT}" in "${FX}"/*) report "8020-AC8 fixture-root containment: control (a) — a value resolved outside the root is flagged" 0 "not flagged: ${OUT}" ;;
  "") report "8020-AC8 fixture-root containment: control (a) — a value resolved outside the root is flagged" 0 "the control resolved nothing: ${ERR}" ;;
  *) report "8020-AC8 fixture-root containment: control (a) — a value resolved outside the root (${OUT#"${OUT%/*/*/*}"}) is flagged" 1 ;; esac
fx_mkdir "${OUTSIDE_ROOT}/x" 2>/dev/null
pin "8020-AC8 fixture-root containment: control (b) — a fixture write outside the root is refused" "$([ -e "${OUTSIDE_ROOT}/x" ] && echo created)" ""
live_hits=0
if [ -f "${LIVE_EVENT_LOG}" ]; then live_hits=$((live_hits + $(grep -cF "${NONCE}" "${LIVE_EVENT_LOG}"))); fi
for d in "${LIVE_HUB_STATE}" "${LIVE_REGISTERS}" "${LIVE_FINOPS}" "${LIVE_DATA}/pmo-platform" "${LIVE_STATE}/pmo-platform" \
         "${LIVE_MAIN_A}/local-state" "${LIVE_MAIN_A}/analysis" "${LIVE_MAIN_B:-/nonexistent}/local-state" "${LIVE_MAIN_B:-/nonexistent}/analysis"; do
  if [ -d "${d}" ]; then live_hits=$((live_hits + $(grep -rIlF "${NONCE}" "${d}" 2>/dev/null | grep -c ''))); fi
done
if [ -d "${LIVE_HUB_STATE}" ]; then live_hits=$((live_hits + $(find "${LIVE_HUB_STATE}" -name "*${NONCE}*" 2>/dev/null | grep -c ''))); fi
pin "CIAC-4 sandbox parity: no live shared surface carries this run's nonce (content-keyed)" "${live_hits}" "0"
fx_hits="$(grep -rIlF "${NONCE}" "${W}/widget/local-state" 2>/dev/null | grep -c '')"
if [ "${fx_hits}" -ge 1 ]; then report "CIAC-4 sandbox parity: SENSITIVITY — the same scan finds the nonce in the fixture's local-state" 1
else report "CIAC-4 sandbox parity: SENSITIVITY — the same scan finds the nonce in the fixture's local-state" 0 "0 hits: a broken probe"; fi
cfg_newer=""
if [ -d "${LIVE_CFG}" ]; then cfg_newer="$(find "${LIVE_CFG}" -newer "${MARK}" -print 2>/dev/null)"; fi
pin "CIAC-4 sandbox parity: nothing under the live config root changed (modification time; nothing is opened)" "${cfg_newer}" ""
: > "${OUTSIDE_ROOT}/touched"
pin "CIAC-4 sandbox parity: SENSITIVITY — a file touched in a second root is listed by the same find" "$(find "${OUTSIDE_ROOT}" -newer "${MARK}" -name touched -print | grep -c '')" "1"
TREE_AFTER="$(git -C "${REPO_ROOT}" status --porcelain=v1 -uall 2>/dev/null || true)"
pin "CIAC-4 sandbox parity: the repository's working tree reads the same before and after" "${TREE_AFTER}" "${TREE_BEFORE}"

printf '\n======================================================================\n'
printf 'test_lib_instance_path.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION}"
printf '======================================================================\n'
[ "${FAIL}" -eq 0 ]

#!/usr/bin/env bash
# test_doctor.sh — hermetic fault-injection proof for doctor.sh (#302)
#
# doctor.sh is a STRICT READ-ONLY, two-layer operator install self-diagnostic.
# This test builds a throwaway mktemp fixture and points doctor's sandbox-root
# env vars (HOME, PMO_PLATFORM_CONFIG_ROOT / _WORKSPACE_ROOT / _DEPLOY_ROOT) at
# it, so every Layer-1 runtime check reads the fixture — never the operator's
# real ~/.claude. Layer 2 (the #299 registry via qa.sh) inspects the shipping
# source tree read-only, so the healthy baseline requires the repo's qa suite
# to be green (it is a standing regression member).
#
# Assertions:
#   A. Healthy baseline — a fully-populated fixture: every check PASS, exit 0.
#   B. Per-fault -> matching-flag, one fault at a time on a fresh fixture:
#        - python3 broken (PATH shim exits 127) -> python3 FAIL + Layer 2 SKIP
#        - $HOME not writable (chmod 500)        -> home FAIL (others still PASS)
#        - operator.toml removed                 -> toml (presence) FAIL
#        - operator.toml empty/garbage           -> toml-valid FAIL (presence PASS)
#        - operator.toml missing a required key  -> toml-valid FAIL naming the key
#        - one hook stripped of its +x bit       -> hooks FAIL naming the hook
#        - deployed skills dir emptied           -> skills FAIL
#   C. Read-only invariant — `git status --porcelain` is byte-identical before
#      and after a run (healthy AND a fault run).
#   D. Markdown signal — `--format md` renders the table + verdict.
#
# Run from anywhere (resolves repo root from its own location):
#   bash core/deploy/tests/test_doctor.sh
#
# Portable (bash 3.2; Darwin + Linux). Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DOCTOR="${REPO_ROOT}/doctor.sh"

PASS=0
FAIL=0
IS_ROOT=0
[ "$(id -u 2>/dev/null || printf 1)" = "0" ] && IS_ROOT=1
FIXTURES=()          # every mktemp dir created; cleaned (u+w first) on EXIT

OUT=""               # last doctor stdout+stderr capture
RC=0                 # last doctor exit code

cleanup() {
  local d
  for d in "${FIXTURES[@]:-}"; do
    [ -n "${d}" ] && [ -d "${d}" ] && chmod -R u+rwx "${d}" 2>/dev/null
    [ -n "${d}" ] && [ -d "${d}" ] && rm -rf "${d}"
  done
  return 0
}
trap cleanup EXIT

report() {
  local name="$1" ok="$2" detail="${3:-}"
  if [ "${ok}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '        %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

# assert_line HAYSTACK REGEX NAME — pass when REGEX is present.
assert_line() {
  if printf '%s\n' "$1" | grep -qE "$2"; then report "$3" 1; else report "$3" 0 "expected /$2/ in report"; fi
}
# assert_absent HAYSTACK REGEX NAME — pass when REGEX is absent.
assert_absent() {
  if printf '%s\n' "$1" | grep -qE "$2"; then report "$3" 0 "unexpected /$2/ in report"; else report "$3" 1; fi
}
# assert_eq GOT WANT NAME
assert_eq() {
  if [ "$1" = "$2" ]; then report "$3" 1; else report "$3" 0 "got '$1' want '$2'"; fi
}

new_fixture() {
  local d; d="$(mktemp -d -t doctor-fix.XXXXXX)"; FIXTURES+=("${d}"); printf '%s' "${d}"
}

# Lay down a fully-healthy deployed layout under $1.
build_fixture() {
  local sbx="$1"
  mkdir -p "${sbx}/.config/pmo-platform" "${sbx}/Claude/.claude/hooks" "${sbx}/.claude/skills/demo-skill"
  printf '[meta]\nschema_version = 1\nmanaged_by = "pmo-platform"\n\n[identity]\noperator_name = "Test Operator"\n' \
    > "${sbx}/.config/pmo-platform/operator.toml"
  printf '#!/usr/bin/env bash\ntrue\n' > "${sbx}/Claude/.claude/hooks/block-alpha.sh"
  printf '#!/usr/bin/env bash\ntrue\n' > "${sbx}/Claude/.claude/hooks/block-beta.sh"
  chmod +x "${sbx}/Claude/.claude/hooks/block-alpha.sh" "${sbx}/Claude/.claude/hooks/block-beta.sh"
  # #302 regression guard: co-deployed SOURCED libraries live NEXT TO the hooks
  # (setup-workspace.sh install_hooks, #1850) — path-leak-patterns.sh + lib-*.sh.
  # They are sourced BY hooks, never invoked directly, so a healthy install ships
  # them WITHOUT +x (path-leak-patterns.sh is mode -rw-r--r-- in-repo). Seeding
  # them at mode 644 here makes the healthy baseline (assertion A) exercise the
  # exact false-positive doctor.sh must NOT raise: check_hooks_runnable requires
  # +x only on real hook ENTRYPOINTS, not sourced libs. (They carry a shebang, so
  # this also proves the discriminator is name-based, not shebang-based.)
  printf '#!/usr/bin/env bash\n# sourced pattern primitive (block-gh-path-leak dep)\n' \
    > "${sbx}/Claude/.claude/hooks/path-leak-patterns.sh"
  printf '#!/usr/bin/env bash\n# sourced needle resolver (block-scope-segregation dep)\n' \
    > "${sbx}/Claude/.claude/hooks/lib-instance-path.sh"
  chmod 644 "${sbx}/Claude/.claude/hooks/path-leak-patterns.sh" "${sbx}/Claude/.claude/hooks/lib-instance-path.sh"
  printf -- '---\nname: demo-skill\n---\nbody\n' > "${sbx}/.claude/skills/demo-skill/SKILL.md"
}

# _run HOME CONFIG WS DEPLOY PATHPFX FMT -> sets OUT, RC (doctor pointed at fixture roots).
_run() {
  local h="$1" c="$2" w="$3" dp="$4" pp="$5" fmt="$6"
  local pe="${PATH}"
  [ -n "${pp}" ] && pe="${pp}:${PATH}"
  if [ -n "${fmt}" ]; then
    OUT="$(HOME="${h}" PMO_PLATFORM_CONFIG_ROOT="${c}" PMO_PLATFORM_WORKSPACE_ROOT="${w}" \
      PMO_PLATFORM_DEPLOY_ROOT="${dp}" PATH="${pe}" bash "${DOCTOR}" --format "${fmt}" 2>&1)"
  else
    OUT="$(HOME="${h}" PMO_PLATFORM_CONFIG_ROOT="${c}" PMO_PLATFORM_WORKSPACE_ROOT="${w}" \
      PMO_PLATFORM_DEPLOY_ROOT="${dp}" PATH="${pe}" bash "${DOCTOR}" 2>&1)"
  fi
  RC=$?
}

# Standard roots for a fixture whose home IS the sandbox.
_run_std() { _run "$1" "$1/.config/pmo-platform" "$1/Claude" "$1" "" ""; }

git_porcelain() { git -C "${REPO_ROOT}" status --porcelain 2>/dev/null; }

# --- Preflight ---
if [ ! -x "${DOCTOR}" ]; then
  printf 'FAIL: doctor.sh not found or not runnable at %s\n' "${DOCTOR}"
  printf 'test_doctor.sh: 0 passed, 1 failed\n'
  exit 1
fi

# =========================================================================== #
# A. Healthy baseline                                                          #
# =========================================================================== #
printf '\nA. Healthy baseline (fully-populated fixture)\n'
SBX="$(new_fixture)"; build_fixture "${SBX}"
GIT_BEFORE="$(git_porcelain)"
_run_std "${SBX}"
GIT_AFTER="$(git_porcelain)"
assert_eq "${RC}" "0" "healthy run exits 0"
assert_line "${OUT}" '^\[PASS\] bash '        "healthy: bash version PASS (report line present)"
assert_line "${OUT}" '^\[PASS\] python3 '     "healthy: python3 PASS"
assert_line "${OUT}" '^\[PASS\] home '        "healthy: \$HOME writable PASS"
assert_line "${OUT}" '^\[PASS\] toml '        "healthy: operator.toml presence PASS"
assert_line "${OUT}" '^\[PASS\] hooks '       "healthy: deployed hooks +x PASS"
assert_line "${OUT}" '^\[PASS\] skills '      "healthy: deployed skills PASS"
assert_line "${OUT}" '^\[PASS\] toml-valid '  "healthy: operator.toml schema-valid PASS (Layer 2)"
assert_line "${OUT}" '^\[PASS\] qa-registry ' "healthy: #299 QA registry PASS (Layer 2 reuse)"
assert_line "${OUT}" 'VERDICT PASS'           "healthy: overall VERDICT PASS"
# C (part 1): read-only invariant across the healthy run.
assert_eq "${GIT_BEFORE}" "${GIT_AFTER}"      "read-only: git status --porcelain unchanged (healthy run)"

# A2 — #302 regression guard: the healthy fixture now co-deploys NON-executable
# sourced libraries (path-leak-patterns.sh + lib-instance-path.sh at mode 644)
# next to the hooks, exactly as setup-workspace.sh install_hooks does (#1850).
# doctor must treat them as sourced libs (no +x requirement), NOT as hooks: the
# hooks check stays PASS, the overall verdict stays PASS (asserted in A), and the
# report must not name a sourced lib in a chmod remedy. This closes the fixture
# gap that let the false-positive ship (the old healthy fixture used only +x
# block-*.sh, never a co-deployed sourced primitive). Assertions run against the
# section-A run's OUT (that fixture already carries the sourced libs).
printf '\nA2. #302 sourced-lib false-positive guard (non-exec sourced lib beside hooks)\n'
assert_line   "${OUT}" '^\[PASS\] hooks '            "sourced-lib: hooks check PASS with non-exec sourced libs present"
assert_absent "${OUT}" '^\[FAIL\] hooks '            "sourced-lib: hooks check not FAILed by a sourced lib"
assert_absent "${OUT}" 'path-leak-patterns\.sh'      "sourced-lib: report does not flag path-leak-patterns.sh"
assert_absent "${OUT}" 'lib-instance-path\.sh'       "sourced-lib: report does not flag lib-instance-path.sh"

# =========================================================================== #
# B. Per-fault -> matching flag (fresh fixture each time)                      #
# =========================================================================== #

# B1 — python3 broken (PATH shim that exits 127): python3 FAIL + Layer 2 SKIP.
printf '\nB1. python3 broken (PATH shim exits 127)\n'
SBX="$(new_fixture)"; build_fixture "${SBX}"
SHIM="$(new_fixture)"
printf '#!/usr/bin/env bash\nexit 127\n' > "${SHIM}/python3"; chmod +x "${SHIM}/python3"
GIT_BEFORE="$(git_porcelain)"
_run "${SBX}" "${SBX}/.config/pmo-platform" "${SBX}/Claude" "${SBX}" "${SHIM}" ""
GIT_AFTER="$(git_porcelain)"
assert_eq "${RC}" "1" "python3-broken run exits 1"
assert_line "${OUT}" '^\[FAIL\] python3 '     "python3-broken: python3 check FAIL"
assert_line "${OUT}" '^\[SKIP\] toml-valid '  "python3-broken: Layer 2 toml-valid SKIP (degrade)"
assert_line "${OUT}" '^\[SKIP\] qa-registry ' "python3-broken: Layer 2 qa-registry SKIP (degrade, no crash)"
assert_line "${OUT}" '^\[PASS\] bash '        "python3-broken: Layer 1 still runs (bash line present)"
# C (part 2): read-only invariant across a fault run too.
assert_eq "${GIT_BEFORE}" "${GIT_AFTER}"      "read-only: git status --porcelain unchanged (fault run)"

# B2 — $HOME not writable (chmod 500), other roots healthy: only home FAILs.
printf '\nB2. \$HOME not writable (chmod 500)\n'
if [ "${IS_ROOT}" = "1" ]; then
  report "home-not-writable: skipped under root (root bypasses [ -w ])" 1
else
  HEALTHY="$(new_fixture)"; build_fixture "${HEALTHY}"
  RO_HOME="$(new_fixture)"; chmod 500 "${RO_HOME}"
  _run "${RO_HOME}" "${HEALTHY}/.config/pmo-platform" "${HEALTHY}/Claude" "${HEALTHY}" "" ""
  assert_eq "${RC}" "1" "home-not-writable run exits 1"
  assert_line "${OUT}" '^\[FAIL\] home '   "home-not-writable: home check FAIL"
  assert_line "${OUT}" '^\[PASS\] toml '   "home-not-writable: operator.toml still PASS (no cascade)"
  assert_line "${OUT}" '^\[PASS\] hooks '  "home-not-writable: hooks still PASS (no cascade)"
  assert_line "${OUT}" '^\[PASS\] skills ' "home-not-writable: skills still PASS (no cascade)"
fi

# B3 — operator.toml removed: Layer 1 presence FAIL.
printf '\nB3. operator.toml removed\n'
SBX="$(new_fixture)"; build_fixture "${SBX}"
rm -f "${SBX}/.config/pmo-platform/operator.toml"
_run_std "${SBX}"
assert_eq "${RC}" "1" "toml-removed run exits 1"
assert_line "${OUT}" '^\[FAIL\] toml '        "toml-removed: presence check FAIL"

# B4 — operator.toml empty/garbage: presence PASS, Layer 2 validity FAIL (empty parse).
printf '\nB4. operator.toml empty/garbage\n'
SBX="$(new_fixture)"; build_fixture "${SBX}"
printf 'this is not toml at all\n' > "${SBX}/.config/pmo-platform/operator.toml"
_run_std "${SBX}"
assert_line "${OUT}" '^\[PASS\] toml '        "toml-garbage: presence PASS (file exists + readable)"
assert_line "${OUT}" '^\[FAIL\] toml-valid '  "toml-garbage: schema-validity FAIL (empty parse)"

# B5 — operator.toml missing a required key: validity FAIL naming the key.
printf '\nB5. operator.toml missing required [identity].operator_name\n'
SBX="$(new_fixture)"; build_fixture "${SBX}"
printf '[meta]\nschema_version = 1\n' > "${SBX}/.config/pmo-platform/operator.toml"
_run_std "${SBX}"
assert_line "${OUT}" '^\[FAIL\] toml-valid '                 "toml-missing-key: validity FAIL"
assert_line "${OUT}" 'identity\].operator_name'             "toml-missing-key: report names the missing key"

# B6 — one hook stripped of its +x bit: hooks FAIL naming the hook + chmod remedy.
printf '\nB6. one deployed hook missing +x\n'
SBX="$(new_fixture)"; build_fixture "${SBX}"
chmod 644 "${SBX}/Claude/.claude/hooks/block-beta.sh"
_run_std "${SBX}"
assert_eq "${RC}" "1" "hook-no-x run exits 1"
assert_line "${OUT}" '^\[FAIL\] hooks '       "hook-no-x: hooks check FAIL"
assert_line "${OUT}" 'block-beta\.sh'         "hook-no-x: report names the offending hook"
assert_line "${OUT}" 'chmod \+x'              "hook-no-x: report names the chmod +x remedy"

# B7 — deployed skills dir emptied: skills FAIL.
printf '\nB7. deployed skills directory emptied\n'
SBX="$(new_fixture)"; build_fixture "${SBX}"
rm -rf "${SBX}/.claude/skills/demo-skill"
_run_std "${SBX}"
assert_eq "${RC}" "1" "skills-empty run exits 1"
assert_line "${OUT}" '^\[FAIL\] skills '      "skills-empty: skills check FAIL"

# =========================================================================== #
# D. Markdown signal                                                           #
# =========================================================================== #
printf '\nD. Markdown failure-mode signal (--format md)\n'
SBX="$(new_fixture)"; build_fixture "${SBX}"
_run "${SBX}" "${SBX}/.config/pmo-platform" "${SBX}/Claude" "${SBX}" "" "md"
assert_eq "${RC}" "0" "md healthy run exits 0"
assert_line "${OUT}" '^## pmo-platform doctor' "md: report heading present"
assert_line "${OUT}" '^\| Check \| Status '    "md: results table header present"
assert_line "${OUT}" '\*\*Verdict:\*\* PASS'   "md: verdict rendered"

# --- Summary ---
printf '\n======================================================================\n'
printf 'test_doctor.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

if [ "${FAIL}" -ne 0 ]; then
  exit 1
fi
exit 0

#!/usr/bin/env bash
# test_verify_session_config.sh — regression test for the SessionStart model/effort
# posture hook (core/hooks/verify-session-config.sh, #339).
#
# The hook is a NON-BLOCKING workflow-class notifier: it reads the launch payload's
# resolved model + effort and warns (warn-mode) or exits non-zero (enforce-mode) on
# drift from the canonical `platform-config.toml [spoke_runtime]` surface (model)
# and the immutable `max` effort directive. EVERY path exits 0 in warn/off; enforce
# emits a non-zero exit that SessionStart still cannot turn into a hard block.
#
# Hermetic: each case stages the hook + its shared libs + a copy of the config
# template into a private sandbox hooks tree, and drives behavior purely via env
# (PMO_PLATFORM_CONFIG_ROOT for the XDG surface, CLAUDE_EFFORT, CLAUDE_HOOK_BYPASS,
# HOME) + stdin (the payload JSON) + the per-case .verify-session-config-mode file.
# No operator state touched; logs land in the sandbox. No network.
#
# Run from repo root:
#   bash core/deploy/tests/test_verify_session_config.sh
#
# Returns non-zero on any failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
HOOK_SRC="${REPO_ROOT}/core/hooks/verify-session-config.sh"
MASTER_LIB_SRC="${REPO_ROOT}/core/hooks/lib/master-enable.sh"
DEP_LIB_SRC="${REPO_ROOT}/core/hooks/lib/dep-resolve.sh"
TMPL_SRC="${REPO_ROOT}/core/config/platform-config.toml.template"

PASS=0
FAIL=0
SBX=""

cleanup() { [ -n "${KEEP_SBX:-}" ] && { printf 'KEEP_SBX: %s\n' "${SBX}" >&2; return 0; }; [ -n "${SBX}" ] && [ -d "${SBX}" ] && rm -rf "${SBX}"; }
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '         %s\n' "${detail}"; FAIL=$((FAIL + 1))
  fi
}

for f in "${HOOK_SRC}" "${MASTER_LIB_SRC}" "${DEP_LIB_SRC}" "${TMPL_SRC}"; do
  [ -r "${f}" ] || { printf 'FATAL: required source not found: %s\n' "${f}" >&2; exit 2; }
done

SBX=$(mktemp -d -t verify-session-config.XXXXXX)

# stage_case — build a private hooks tree; echo the staged hook path.
#   $1 mode        : warn | enforce | off | ABSENT (no mode file)
#   $2 master      : on | off | nolib  (nolib omits master-enable.sh entirely)
#   $3 xdg_spoke   : "" (template default opus) | "sonnet" (XDG [spoke_runtime] override)
# Each call gets a FRESH, unique, empty case dir via mktemp — stage_case runs in a
# command-substitution subshell, so a shared counter cannot advance; a per-call
# mktemp guarantees isolation (no leftover lib/mode/config from a prior case).
stage_case() {
  local mode="$1" master="$2" xdg_spoke="$3"
  local root; root="$(mktemp -d "${SBX}/case.XXXXXX")"
  local hooks="${root}/hooks" cfg="${root}/config" xdg="${root}/xdg"
  mkdir -p "${hooks}/lib" "${cfg}" "${xdg}" "${root}/home"
  cp "${HOOK_SRC}" "${hooks}/verify-session-config.sh"; chmod +x "${hooks}/verify-session-config.sh"
  cp "${DEP_LIB_SRC}" "${hooks}/lib/dep-resolve.sh"
  [ "${master}" != "nolib" ] && cp "${MASTER_LIB_SRC}" "${hooks}/lib/master-enable.sh"
  # config template floor (hook reads ${HOOK_DIR}/../config/…): default opus.
  cp "${TMPL_SRC}" "${cfg}/platform-config.toml.template"
  # per-case mode file
  case "${mode}" in warn|enforce|off) printf '%s' "${mode}" > "${hooks}/.verify-session-config-mode" ;; esac
  # XDG platform-config.toml: master state + optional [spoke_runtime] override.
  {
    printf '[security_hooks]\n'
    case "${master}" in on) printf 'master_enabled = true\n' ;; *) printf 'master_enabled = false\n' ;; esac
    if [ -n "${xdg_spoke}" ]; then
      printf '\n[spoke_runtime]\ndefault_spoke_model = "%s"\nchip_model = "%s"\n' "${xdg_spoke}" "${xdg_spoke}"
    fi
  } > "${xdg}/platform-config.toml"
  printf '%s' "${hooks}/verify-session-config.sh"
}

# run — invoke a staged hook, capturing stdout + stderr + rc separately.
#   env passed via the caller's inline assignments; payload on stdin.
# Sets: R_OUT R_ERR R_RC and the sandbox root R_ROOT for log inspection.
run() {
  local hook="$1" payload="$2"; shift 2  # remaining args = VAR=VAL env
  R_ROOT="$(dirname "$(dirname "${hook}")")"
  local xdg="${R_ROOT}/xdg"
  R_OUT="${R_ROOT}/stdout"; R_ERR="${R_ROOT}/stderr"
  env -i HOME="${R_ROOT}/home" PATH="/usr/bin:/bin" \
    PMO_PLATFORM_CONFIG_ROOT="${xdg}" "$@" \
    bash "${hook}" >"${R_OUT}" 2>"${R_ERR}" <<EOF
${payload}
EOF
  R_RC=$?
}

OPUS_PAYLOAD='{"source":"startup","model":"claude-opus-4-8","effort":{"level":"max"}}'
HAIKU_PAYLOAD='{"source":"startup","model":"claude-haiku-4-5","effort":{"level":"max"}}'
SONNET_PAYLOAD='{"source":"startup","model":"claude-sonnet-5","effort":{"level":"max"}}'
NOMODEL_PAYLOAD='{"source":"clear","effort":{"level":"max"}}'

printf '\nverify-session-config hook regression (bash %s)\n' "${BASH_VERSION:-unknown}"

# 1. model-match → clean (no notice, exit 0, stdout empty)
h=$(stage_case warn on "")
run "${h}" "${OPUS_PAYLOAD}" CLAUDE_EFFORT=max
if [ "${R_RC}" -eq 0 ] && ! grep -q VERIFY-SESSION-CONFIG "${R_ERR}" && [ ! -s "${R_OUT}" ]; then
  report "model-match (opus) → clean, exit 0, no notice" 1
else
  report "model-match (opus) → clean" 0 "rc=${R_RC} err=$(cat "${R_ERR}") out=$(cat "${R_OUT}")"
fi

# 2. --model haiku → 001 (warn: stderr notice, exit 0)
h=$(stage_case warn on "")
run "${h}" "${HAIKU_PAYLOAD}" CLAUDE_EFFORT=max
if [ "${R_RC}" -eq 0 ] && grep -q "VERIFY-SESSION-CONFIG-001" "${R_ERR}"; then
  report "--model haiku → VERIFY-SESSION-CONFIG-001 (warn, exit 0)" 1
else
  report "--model haiku → 001" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 3. --effort low → 002
h=$(stage_case warn on "")
run "${h}" "${OPUS_PAYLOAD}" CLAUDE_EFFORT=low
if [ "${R_RC}" -eq 0 ] && grep -q "VERIFY-SESSION-CONFIG-002" "${R_ERR}"; then
  report "--effort low → VERIFY-SESSION-CONFIG-002" 1
else
  report "--effort low → 002" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 4. payload .model absent → 003 (degraded, NEVER a silent pass)
h=$(stage_case warn on "")
run "${h}" "${NOMODEL_PAYLOAD}" CLAUDE_EFFORT=max
if [ "${R_RC}" -eq 0 ] && grep -q "VERIFY-SESSION-CONFIG-003" "${R_ERR}"; then
  report "payload .model absent → VERIFY-SESSION-CONFIG-003 (no silent pass)" 1
else
  report ".model absent → 003" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 5. CLAUDE_HOOK_BYPASS=1 → exit 0, no notice, bypass-log appended
h=$(stage_case warn on "")
run "${h}" "${HAIKU_PAYLOAD}" CLAUDE_EFFORT=low CLAUDE_HOOK_BYPASS=1
if [ "${R_RC}" -eq 0 ] && ! grep -q VERIFY-SESSION-CONFIG "${R_ERR}" \
   && grep -q '"action":"bypass"' "$(dirname "${h}")/bypass-log.jsonl" 2>/dev/null; then
  report "CLAUDE_HOOK_BYPASS=1 → exit 0 + bypass-log (mismatch suppressed)" 1
else
  report "CLAUDE_HOOK_BYPASS=1 → bypass" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 6. .mode off → exit 0, no notice (even on mismatch)
h=$(stage_case off on "")
run "${h}" "${HAIKU_PAYLOAD}" CLAUDE_EFFORT=low
if [ "${R_RC}" -eq 0 ] && ! grep -q VERIFY-SESSION-CONFIG "${R_ERR}"; then
  report ".mode off → exit 0, silent (mismatch suppressed)" 1
else
  report ".mode off → silent" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 7. .mode enforce → non-zero exit on mismatch (still non-blocking to the session)
h=$(stage_case enforce on "")
run "${h}" "${HAIKU_PAYLOAD}" CLAUDE_EFFORT=max
if [ "${R_RC}" -ne 0 ] && grep -q "VERIFY-SESSION-CONFIG-001" "${R_ERR}" \
   && grep -q '"mode":"enforce"' "$(dirname "${h}")/block-log.jsonl" 2>/dev/null; then
  report ".mode enforce → 001 + non-zero exit + block-log" 1
else
  report ".mode enforce → non-zero" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 8. master OFF → suppressed (workflow-class), exit 0, no notice
h=$(stage_case warn off "")
run "${h}" "${HAIKU_PAYLOAD}" CLAUDE_EFFORT=low
if [ "${R_RC}" -eq 0 ] && ! grep -q VERIFY-SESSION-CONFIG "${R_ERR}"; then
  report "master OFF → suppressed (workflow-class), silent" 1
else
  report "master OFF → suppressed" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 9. master lib missing → proceed (fail-toward-current-behavior: advisory runs)
h=$(stage_case warn nolib "")
run "${h}" "${HAIKU_PAYLOAD}" CLAUDE_EFFORT=max
if [ "${R_RC}" -eq 0 ] && grep -q "VERIFY-SESSION-CONFIG-001" "${R_ERR}"; then
  report "master lib missing → proceeds (advisory 001, fail-toward-current)" 1
else
  report "master lib missing → proceeds" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 10. CIAC-1: canonical surface drives expected — XDG [spoke_runtime]=sonnet makes
#     an opus launch MISMATCH (proves the hook reads the surface, not a hardcoded opus)
h=$(stage_case warn on "sonnet")
run "${h}" "${OPUS_PAYLOAD}" CLAUDE_EFFORT=max
ciac_flag=0
[ "${R_RC}" -eq 0 ] && grep -q "VERIFY-SESSION-CONFIG-001" "${R_ERR}" && ciac_flag=1
# …and a sonnet launch under the same surface is CLEAN
h=$(stage_case warn on "sonnet")
run "${h}" "${SONNET_PAYLOAD}" CLAUDE_EFFORT=max
[ "${R_RC}" -eq 0 ] && ! grep -q VERIFY-SESSION-CONFIG "${R_ERR}" && ciac_flag=$((ciac_flag + 1))
if [ "${ciac_flag}" -eq 2 ]; then
  report "CIAC-1: [spoke_runtime] override drives expected (opus→001, sonnet→clean)" 1
else
  report "CIAC-1: canonical surface drives expected" 0 "ciac_flag=${ciac_flag}"
fi

# 11. effort resolvable from payload when \$CLAUDE_EFFORT unset (env-primary, payload x-check)
h=$(stage_case warn on "")
run "${h}" "${OPUS_PAYLOAD}"   # NO CLAUDE_EFFORT in env; payload .effort.level=max
if [ "${R_RC}" -eq 0 ] && ! grep -q VERIFY-SESSION-CONFIG "${R_ERR}"; then
  report "effort from payload .effort.level when \$CLAUDE_EFFORT unset → clean" 1
else
  report "effort from payload cross-check" 0 "rc=${R_RC} err=$(cat "${R_ERR}")"
fi

# 12. stdout hygiene — a mismatch must NEVER write to stdout (SessionStart stdout is
#     injected into Claude's context); the notice belongs on stderr only.
h=$(stage_case warn on "")
run "${h}" "${HAIKU_PAYLOAD}" CLAUDE_EFFORT=low
if [ ! -s "${R_OUT}" ] && grep -q VERIFY-SESSION-CONFIG "${R_ERR}"; then
  report "stdout hygiene: notice on stderr only, stdout empty" 1
else
  report "stdout hygiene" 0 "stdout=$(cat "${R_OUT}") err=$(cat "${R_ERR}")"
fi

# 13. combined model+effort drift → BOTH 001 and 002 reported in one launch
h=$(stage_case warn on "")
run "${h}" "${HAIKU_PAYLOAD}" CLAUDE_EFFORT=low
if grep -q "VERIFY-SESSION-CONFIG-001" "${R_ERR}" && grep -q "VERIFY-SESSION-CONFIG-002" "${R_ERR}"; then
  report "combined drift → both 001 and 002 in one launch" 1
else
  report "combined drift → both rules" 0 "err=$(cat "${R_ERR}")"
fi

printf '\n======================================================================\n'
printf 'test_verify_session_config.sh: %d passed, %d failed (bash %s)\n' "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

[ "${FAIL}" -ne 0 ] && exit 1
exit 0

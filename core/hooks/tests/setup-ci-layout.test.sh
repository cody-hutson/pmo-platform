#!/bin/bash
# tests/setup-ci-layout.test.sh — the hook-suite layout helper's own suite.
#
# Grades core/hooks/tests/setup-ci-layout.sh:
#   * its DOCUMENTED AGENT INVOCATION — the lines between the AGENT-INVOCATION markers
#     in its USAGE — against the shipped BLOCK-DESTRUCTIVE-022 matcher, in this run;
#   * its DEFAULT SITE (the checkout it runs from) and the explicit --sandbox form;
#   * the R-8 GUARD, which compares filesystem identity and reads the account home;
#   * the RECORDED FOOTPRINT, the exact-list PURGE, the ownership marker and the
#     ignore coverage of everything the default site writes;
#   * the BUILD DIGEST, through the freshness check LAYOUT-FRESH-01 applies to the
#     very layout this suite is running in.
#
# DECLARED ARM IDS — graded by ID, not by count:
#   LAYOUT-PRECOND
#   LAYOUT-FRESH-01  LAYOUT-FRESH-02  LAYOUT-FRESH-03  LAYOUT-FRESH-04
#   LAYOUT-DOC-00  LAYOUT-DOC-01a  LAYOUT-DOC-01b  LAYOUT-DOC-02a  LAYOUT-DOC-02b
#   LAYOUT-DOC-03a  LAYOUT-DOC-03b
#   LAYOUT-SITE-01
#   LAYOUT-DEFAULT-01  LAYOUT-DEFAULT-02  LAYOUT-DEFAULT-03
#   LAYOUT-GUARD-01  LAYOUT-GUARD-01b  LAYOUT-GUARD-02  LAYOUT-GUARD-03  LAYOUT-GUARD-04
#   LAYOUT-GUARD-05  LAYOUT-GUARD-06  LAYOUT-GUARD-07  LAYOUT-GUARD-08
#   LAYOUT-PURGE-01  LAYOUT-PURGE-02  LAYOUT-PURGE-03  LAYOUT-PURGE-04
#   LAYOUT-FOOTPRINT-01  LAYOUT-IGNORE-01  LAYOUT-OWNER-01
#
# WHERE IT RUNS. Inside a materialized layout — the runner's own site — where it finds
# the helper through the .source-repo-root pointer. Run from the source tree it fails
# LAYOUT-PRECOND closed rather than grading nothing.
#
# WHAT IT NEVER TOUCHES. Every layout it builds lives in its own mktemp directory. It
# never writes to the layout it is running in, the source checkout, the account home
# or the workspace. The one arm that aims the helper at the account home
# (LAYOUT-GUARD-03) passes a repo root with no sources in it, so the helper cannot
# write there even if its guard were broken: a working guard refuses first (exit 65),
# a broken one stops at the missing sources (exit 1).
#
# NO PIPES INTO SHORT-CIRCUITING READERS. The hook is fed from a file, every classifier
# is one awk pass over a file, and lists are joined through files, so the SIGPIPE-idiom
# gate has nothing here to match.
#
# Runs standalone (bash .claude/hooks/tests/setup-ci-layout.test.sh) or under the runner.

# Note: no `set -e` — the arms assert on non-zero exits.
set -u
# The runner's value, so this suite gives the same verdict standalone and under it.
: "${PMO_SCOPE_GUARD_ROOT:=/}"
export PMO_SCOPE_GUARD_ROOT

TESTS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
HOOK="${TESTS_DIR}/../block-destructive.sh"
ALLOWLIST="${TESTS_DIR}/../../script-execution-allowlist.txt"

PASS=0
FAIL=0
pass() { printf 'PASS: %s\n' "$*"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$*"; FAIL=$((FAIL + 1)); }
finish() {
  printf 'Total: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "${PASS}" "${FAIL}"
  if [ "${FAIL}" -gt 0 ]; then exit 1; fi
  exit 0
}

echo "================================"
echo "setup-ci-layout.sh tests (LAYOUT)"
echo "================================"

# ── LAYOUT-PRECOND — a materialized layout, not the source tree ──────────────────
SRC_ROOT=""
if [ -r "${TESTS_DIR}/.source-repo-root" ]; then
  IFS= read -r SRC_ROOT < "${TESTS_DIR}/.source-repo-root" || true
fi
HELPER=""
if [ -n "${SRC_ROOT}" ] && [ -f "${SRC_ROOT}/core/hooks/tests/setup-ci-layout.sh" ]; then
  HELPER="${SRC_ROOT}/core/hooks/tests/setup-ci-layout.sh"
fi
_missing=""
if [ -z "${HELPER}" ]; then _missing="${_missing} source-pointer-or-helper"; fi
if [ ! -f "${HOOK}" ]; then _missing="${_missing} layout-hook"; fi
if [ ! -f "${ALLOWLIST}" ]; then _missing="${_missing} layout-allowlist"; fi
for _tool in jq python3 git awk; do
  if ! command -v "${_tool}" >/dev/null 2>&1; then _missing="${_missing} ${_tool}"; fi
done
if [ -n "${_missing}" ]; then
  fail "LAYOUT-PRECOND not running inside a materialized layout (missing:${_missing}) — run through the documented layout invocation (bash core/hooks/tests/setup-ci-layout.sh, then bash .claude/hooks/tests/test-runner.sh), not the source-tree runner"
  finish
fi
pass "LAYOUT-PRECOND running inside a materialized layout; helper resolved through .source-repo-root"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/setup-ci-layout-test.XXXXXX")"
WORK="$(cd "${WORK}" && pwd -P)"
cleanup() {
  if [ -n "${WORK:-}" ] && [ -d "${WORK}" ]; then
    /bin/chmod -R u+rwX "${WORK}" 2>/dev/null
    /bin/rm -rf "${WORK}"
  fi
}
trap cleanup EXIT

ACCT="$(python3 -c 'import os, pwd; print(pwd.getpwuid(os.getuid()).pw_dir)' 2>/dev/null || true)"
PAYLOAD_CWD="${HOME}/Claude/.claude/worktrees/test"

# ── Helpers ───────────────────────────────────────────────────────────────────────

# run_cmd <out-prefix> <command...> — RC gets the exit code; <prefix>.out / .err the streams.
RC=0
run_cmd() {
  local pfx="$1"
  shift
  RC=0
  "$@" > "${pfx}.out" 2> "${pfx}.err" || RC=$?
}

# A repo root whose core/ subtrees are links to the source.
fixture_linked() {
  local d
  mkdir -p "$1/core"
  for d in hooks config deploy rules; do ln -s "${SRC_ROOT}/core/${d}" "$1/core/${d}"; done
}

# The same, with core/hooks a real copy an arm may edit.
fixture_copied() {
  local d
  mkdir -p "$1/core"
  cp -R "${SRC_ROOT}/core/hooks" "$1/core/hooks"
  for d in config deploy rules; do ln -s "${SRC_ROOT}/core/${d}" "$1/core/${d}"; done
}

# build <out-prefix> <repo-root> <sandbox> — the helper at an explicit sandbox, with no
# declared workspace root in its environment.
build() {
  run_cmd "$1" env -u CLAUDE_WORKSPACE_ROOT bash "${HELPER}" --repo-root "$2" --sandbox "$3"
}

# hook_verdict <command> -> "<exit>:<rule id, or ->" from the SHIPPED hook in this layout.
hook_verdict() {
  local rc=0 rule=""
  jq -n --arg cmd "$1" --arg cwd "${PAYLOAD_CWD}" \
    '{tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}' > "${WORK}/payload.json"
  /bin/bash "${HOOK}" < "${WORK}/payload.json" > /dev/null 2> "${WORK}/hook.err" || rc=$?
  rule="$(awk 'match($0, /BLOCK-[A-Z]+-[0-9]+/) { print substr($0, RSTART, RLENGTH); exit }' "${WORK}/hook.err")"
  printf '%s:%s' "${rc}" "${rule:--}"
}

# doc_lines <helper file> — the documented agent commands, one per line.
doc_lines() {
  awk '
    index($0, "# >>> AGENT-INVOCATION-END") == 1 { inb = 0 }
    inb == 1 { line = $0; sub(/^#[[:space:]]*/, "", line); if (line != "") print line }
    index($0, "# >>> AGENT-INVOCATION-BEGIN") == 1 { inb = 1 }
  ' "$1"
}

# 0 when $1 is `bash <repo-relative path>.sh` with nothing the hook cannot resolve as written.
is_literal_bash() {
  local p
  case "$1" in
    'bash '*) ;;
    *) return 1 ;;
  esac
  p="${1#bash }"
  case "${p}" in
    ''|/*|*' '*|*'$'*|*'`'*|*'"'*|*"'"*|*'\'*) return 1 ;;
  esac
  case "${p}" in
    */*.sh) return 0 ;;
  esac
  return 1
}

# hash_list <base dir> <file of relative paths> -> "<sha256>  <path>" per path, in order.
hash_list() {
  local base="$1" f
  local -a paths=()
  while IFS= read -r f; do paths+=("${f}"); done < "$2"
  if [ "${#paths[@]}" -eq 0 ]; then return 0; fi
  if command -v shasum >/dev/null 2>&1; then
    (cd "${base}" && shasum -a 256 -- "${paths[@]}")
  else
    (cd "${base}" && sha256sum -- "${paths[@]}")
  fi
}

# layout_freshness <a layout's tests dir> -> one line: "FRESH", or "STALE <limb> <path>".
# Limbs, in order: no-digest, no-source-root, mutated (a recorded layout file is missing
# or differs from its recorded hash), source-changed (a recorded source differs from its
# recorded hash), new-source (a hook or test in the source has no record), unrecorded (a
# hook, test or library in the layout has no record).
layout_freshness() {
  local tdir="$1" root src digest f first
  digest="${tdir}/.layout-digest"
  if [ ! -f "${digest}" ]; then printf 'STALE no-digest -'; return 0; fi
  root="$(cd "${tdir}/../../.." 2>/dev/null && pwd -P)"
  src=""
  if [ -r "${tdir}/.source-repo-root" ]; then IFS= read -r src < "${tdir}/.source-repo-root" || true; fi
  if [ -z "${src}" ] || [ ! -d "${src}" ]; then printf 'STALE no-source-root -'; return 0; fi
  awk -F'\t' '$1 != "-" { print $1 }' "${digest}" > "${WORK}/fr.dst"
  awk -F'\t' '$3 != "-" { print $3 }' "${digest}" > "${WORK}/fr.src"
  while IFS= read -r f; do
    if [ ! -f "${root}/${f}" ]; then printf 'STALE mutated %s' "${f}"; return 0; fi
  done < "${WORK}/fr.dst"
  hash_list "${root}" "${WORK}/fr.dst" > "${WORK}/fr.dst.now"
  first="$(awk -F'\t' -v now="${WORK}/fr.dst.now" '
    FILENAME == now { cur[substr($0, 67)] = substr($0, 1, 64); next }
    $1 != "-" && cur[$1] != $2 { print $1; exit }
  ' "${WORK}/fr.dst.now" "${digest}")"
  if [ -n "${first}" ]; then printf 'STALE mutated %s' "${first}"; return 0; fi
  while IFS= read -r f; do
    if [ ! -f "${src}/${f}" ]; then printf 'STALE source-changed %s' "${f}"; return 0; fi
  done < "${WORK}/fr.src"
  hash_list "${src}" "${WORK}/fr.src" > "${WORK}/fr.src.now"
  first="$(awk -F'\t' -v now="${WORK}/fr.src.now" '
    FILENAME == now { cur[substr($0, 67)] = substr($0, 1, 64); next }
    $3 != "-" && cur[$3] != $4 { print $3; exit }
  ' "${WORK}/fr.src.now" "${digest}")"
  if [ -n "${first}" ]; then printf 'STALE source-changed %s' "${first}"; return 0; fi
  : > "${WORK}/fr.cur"
  for f in "${src}"/core/hooks/*.sh "${src}"/core/hooks/tests/*.sh; do
    [ -f "${f}" ] || continue
    case "${f##*/}" in
      setup-ci-layout.sh) continue ;;
    esac
    printf '%s\n' "${f#"${src}"/}" >> "${WORK}/fr.cur"
  done
  first="$(awk -v cur="${WORK}/fr.cur" 'FILENAME != cur { seen[$0] = 1; next } !($0 in seen) { print; exit }' \
    "${WORK}/fr.src" "${WORK}/fr.cur")"
  if [ -n "${first}" ]; then printf 'STALE new-source %s' "${first}"; return 0; fi
  : > "${WORK}/fr.lay"
  for f in "${root}"/.claude/hooks/*.sh "${root}"/.claude/hooks/tests/*.sh "${root}"/.claude/hooks/lib/*; do
    [ -f "${f}" ] || continue
    printf '%s\n' "${f#"${root}"/}" >> "${WORK}/fr.lay"
  done
  first="$(awk -v lay="${WORK}/fr.lay" 'FILENAME != lay { seen[$0] = 1; next } !($0 in seen) { print; exit }' \
    "${WORK}/fr.dst" "${WORK}/fr.lay")"
  if [ -n "${first}" ]; then printf 'STALE unrecorded %s' "${first}"; return 0; fi
  printf 'FRESH'
}

# ── LAYOUT-FRESH-01 — the layout this suite runs in is current ───────────────────
FRESH_RUNNING="$(layout_freshness "${TESTS_DIR}")"
if [ "${FRESH_RUNNING}" = "FRESH" ]; then
  pass "LAYOUT-FRESH-01 the running layout matches its build digest and its source"
else
  fail "LAYOUT-FRESH-01 stale or mutated layout — re-run the helper (bash core/hooks/tests/setup-ci-layout.sh, then the runner): ${FRESH_RUNNING}"
fi

# ── LAYOUT-DOC — the documented agent invocation, graded by the shipped hook ──────
doc_lines "${HELPER}" > "${WORK}/doc.lines"
DOC_N=0
DOC1=""
DOC2=""
while IFS= read -r _l; do
  DOC_N=$((DOC_N + 1))
  case "${DOC_N}" in
    1) DOC1="${_l}" ;;
    2) DOC2="${_l}" ;;
  esac
done < "${WORK}/doc.lines"

if [ "${DOC_N}" -eq 2 ] && is_literal_bash "${DOC1}" && is_literal_bash "${DOC2}"; then
  case "${DOC1}|${DOC2}" in
    *'/setup-ci-layout.sh|'*'/test-runner.sh')
      pass "LAYOUT-DOC-00 the AGENT-INVOCATION block holds exactly two literal commands, the helper then the runner" ;;
    *)
      fail "LAYOUT-DOC-00 the AGENT-INVOCATION block must name the helper first and the runner second: ${DOC1} | ${DOC2}" ;;
  esac
else
  fail "LAYOUT-DOC-00 the AGENT-INVOCATION block must hold exactly two literal 'bash <path>.sh' commands (no variable, quote or absolute path); found ${DOC_N}: ${DOC1} | ${DOC2}"
fi

# Admission AS WRITTEN is decidable only for a literal command: a line that needs the
# shell to expand something first is not the command the hook will be handed, so it
# fails here rather than being graded.
doc_admitted() {   # $1 = arm id  $2 = documented command
  local v
  if ! is_literal_bash "$2"; then
    fail "$1 the documented line is not a literal 'bash <path>.sh' command, so it cannot be admitted as written: ${2:-<none>}"
    return 0
  fi
  v="$(hook_verdict "$2")"
  if [ "${v}" = "0:-" ]; then
    pass "$1 the documented command is admitted as written: $2"
  else
    fail "$1 the documented command is REFUSED by the shipped hook (verdict ${v}): $2"
  fi
}
doc_admitted "LAYOUT-DOC-01a" "${DOC1}"
doc_admitted "LAYOUT-DOC-01b" "${DOC2}"

# The twin — the same directory, an unlisted script — proves each line is adjudicated
# rather than slipping past the matcher unexamined.
doc_twin_refused() {   # $1 = arm id  $2 = documented command
  local p twin v
  if ! is_literal_bash "$2"; then
    fail "$1 cannot build the unlisted twin: the documented line is not a literal bash command: $2"
    return 0
  fi
  p="${2#bash }"
  twin="bash ${p%/*}/zz-unlisted-control.sh"
  v="$(hook_verdict "${twin}")"
  if [ "${v}" = "2:BLOCK-DESTRUCTIVE-022" ]; then
    pass "$1 the unlisted twin of the documented line is refused (${twin})"
  else
    fail "$1 the unlisted twin was not refused as BLOCK-DESTRUCTIVE-022 (verdict ${v}): ${twin}"
  fi
}
doc_twin_refused "LAYOUT-DOC-02a" "${DOC1}"
doc_twin_refused "LAYOUT-DOC-02b" "${DOC2}"

# Red-before controls: the DOC-01 grader, applied to a helper whose runner line is
# replaced by a refused form, must report the refusal. The mutant must be LIVE — it
# must differ from the shipped helper — or the control passes for the wrong reason.
doc_mutant_refused() {   # $1 = arm id  $2 = the refused runner line
  local mut="${WORK}/helper-mutant-$1.sh" v line
  awk -v repl="#   $2" '
    index($0, "# >>> AGENT-INVOCATION-END") == 1 { inb = 0 }
    inb == 1 && index($0, "test-runner.sh") > 0 { print repl; next }
    { print }
    index($0, "# >>> AGENT-INVOCATION-BEGIN") == 1 { inb = 1 }
  ' "${HELPER}" > "${mut}"
  if cmp -s "${HELPER}" "${mut}"; then
    fail "$1 the mutation is INERT — the mutant equals the shipped helper, so the documented runner line already reads: $2"
    return 0
  fi
  doc_lines "${mut}" > "${WORK}/mutant.lines"
  line=""
  while IFS= read -r _l; do
    case "${_l}" in
      *test-runner.sh*) line="${_l}" ;;
    esac
  done < "${WORK}/mutant.lines"
  v="$(hook_verdict "${line}")"
  if [ "${v}" = "2:BLOCK-DESTRUCTIVE-022" ]; then
    pass "$1 a documented runner line in a refused form is caught by the grader: ${line}"
  else
    fail "$1 the grader did not report the refused runner form (verdict ${v}): ${line}"
  fi
}
doc_mutant_refused "LAYOUT-DOC-03a" 'bash "${TESTS_DIR}/test-runner.sh"'
doc_mutant_refused "LAYOUT-DOC-03b" 'bash /tmp/hook-ci-layout.AbC123/.claude/hooks/tests/test-runner.sh'

# ── LAYOUT-SITE-01 — a script beside the runner that no row names is still refused ─
# Named so it matches no *.test.sh row: the site is admitted for the runner, not for
# whatever lands beside it.
_v="$(hook_verdict 'bash .claude/hooks/tests/zz-unlisted-control.sh')"
if [ "${_v}" = "2:BLOCK-DESTRUCTIVE-022" ]; then
  pass "LAYOUT-SITE-01 an unlisted script at the layout's runner site is refused"
else
  fail "LAYOUT-SITE-01 an unlisted script at the layout's runner site was not refused as BLOCK-DESTRUCTIVE-022 (verdict ${_v})"
fi

# ── LAYOUT-DEFAULT — no --sandbox builds at the checkout the helper runs from ──────
FIX="${WORK}/fix"
fixture_linked "${FIX}"
run_cmd "${WORK}/default01" env -u CLAUDE_WORKSPACE_ROOT bash "${HELPER}" --repo-root "${FIX}"
_out=""
if [ -f "${WORK}/default01.out" ]; then IFS= read -r _out < "${WORK}/default01.out" || true; fi
if [ "${RC}" -eq 0 ] && [ "${_out}" = "${FIX}/.claude/hooks/tests" ] && [ -f "${FIX}/.claude/hooks/tests/test-runner.sh" ]; then
  pass "LAYOUT-DEFAULT-01 with no --sandbox the layout lands at the checkout root and the canonical tests dir is printed"
else
  fail "LAYOUT-DEFAULT-01 expected exit 0 and stdout ${FIX}/.claude/hooks/tests with the runner present; got rc=${RC} stdout=${_out:-<empty>}"
fi

if [ -d "${FIX}/.claude/hooks" ] && [ ! -e "${FIX}/.claude/rules" ]; then
  pass "LAYOUT-DEFAULT-02 the default site carries the hooks and no readiness-corpus mirror"
else
  fail "LAYOUT-DEFAULT-02 the default site must carry .claude/hooks and no .claude/rules (hooks present: $([ -d "${FIX}/.claude/hooks" ] && echo yes || echo no); rules present: $([ -e "${FIX}/.claude/rules" ] && echo yes || echo no))"
fi

S3="${WORK}/s3"
mkdir -p "${S3}"
build "${WORK}/default03" "${FIX}" "${S3}"
if [ "${RC}" -eq 0 ] && [ -f "${S3}/.claude/rules/bypass-mode-readiness.md" ]; then
  pass "LAYOUT-DEFAULT-03 an explicit sandbox still carries the readiness-corpus mirror"
else
  fail "LAYOUT-DEFAULT-03 an explicit sandbox must carry .claude/rules/bypass-mode-readiness.md; got rc=${RC}"
fi

# ── LAYOUT-GUARD — R-8, by identity, against the account home ────────────────────
WS="${WORK}/ws"
mkdir -p "${WS}/.claude"
printf '{}\n' > "${WS}/.claude/settings.json"
run_cmd "${WORK}/guard01" env CLAUDE_WORKSPACE_ROOT="${WS}" bash "${HELPER}" --repo-root "${FIX}" --sandbox "${WS}"
if [ "${RC}" -eq 65 ] && [ ! -e "${WS}/.claude/hooks" ]; then
  pass "LAYOUT-GUARD-01 a sandbox that is the declared workspace root is refused before any write"
else
  fail "LAYOUT-GUARD-01 expected exit 65 and no ${WS}/.claude/hooks; got rc=${RC}"
fi

WS2="${WORK}/ws2"
mkdir -p "${WS2}/.claude"
ln -s "${WS2}" "${WORK}/ws2-alias"
run_cmd "${WORK}/guard01b" env CLAUDE_WORKSPACE_ROOT="${WORK}/ws2-alias" bash "${HELPER}" --repo-root "${FIX}" --sandbox "${WS2}"
if [ "${RC}" -eq 65 ] && [ ! -e "${WS2}/.claude/hooks" ]; then
  pass "LAYOUT-GUARD-01b a workspace root declared through an alias is still recognized: the guard compares identity, not path strings"
else
  fail "LAYOUT-GUARD-01b expected exit 65 and no ${WS2}/.claude/hooks when the workspace root is declared through an alias; got rc=${RC}"
fi

FOREIGN="${WORK}/foreign"
mkdir -p "${FOREIGN}/.claude/hooks"
printf 'not written by the helper\n' > "${FOREIGN}/.claude/hooks/foreign.sh"
build "${WORK}/guard02" "${FIX}" "${FOREIGN}"
_foreign_now=""
if [ -f "${FOREIGN}/.claude/hooks/foreign.sh" ]; then IFS= read -r _foreign_now < "${FOREIGN}/.claude/hooks/foreign.sh" || true; fi
_names_trash=0
if grep -q -F 'trash' "${WORK}/guard02.err" 2>/dev/null; then _names_trash=1; fi
if [ "${RC}" -eq 65 ] && [ "${_foreign_now}" = "not written by the helper" ] && [ ! -e "${FOREIGN}/.claude/hooks/tests" ] && [ "${_names_trash}" -eq 1 ]; then
  pass "LAYOUT-GUARD-02 a layout the helper has no record of is refused, left intact, and the refusal names trash-then-rerun"
else
  fail "LAYOUT-GUARD-02 expected exit 65, the foreign file intact, no tests dir and a trash-then-rerun message; got rc=${RC} foreign='${_foreign_now}' names-trash=${_names_trash}"
fi

if [ -z "${ACCT}" ] || [ ! -d "${ACCT}" ]; then
  fail "LAYOUT-GUARD-03 the account home could not be read from the user database, so this arm cannot be set up"
else
  EMPTY_REPO="${WORK}/empty-repo"
  mkdir -p "${EMPTY_REPO}"
  run_cmd "${WORK}/guard03" env -u CLAUDE_WORKSPACE_ROOT bash "${HELPER}" --repo-root "${EMPTY_REPO}" --sandbox "${ACCT}"
  _live=0
  if grep -q -F 'is the live root' "${WORK}/guard03.err" 2>/dev/null; then _live=1; fi
  if [ "${RC}" -eq 65 ] && [ "${_live}" -eq 1 ]; then
    pass "LAYOUT-GUARD-03 a sandbox that is the account home is refused by the identity guard (the account home is read from the user database)"
  else
    fail "LAYOUT-GUARD-03 expected the identity guard to refuse the account home (exit 65, 'is the live root'); got rc=${RC} identity-refusal=${_live}"
  fi
fi

FIX2="${WORK}/fix2"
fixture_linked "${FIX2}"
run_cmd "${WORK}/guard04" env -u CLAUDE_WORKSPACE_ROOT bash "${HELPER}" --repo-root "${FIX2}" --sandbox ""
if [ "${RC}" -eq 64 ] && [ ! -e "${FIX2}/.claude" ]; then
  pass "LAYOUT-GUARD-04 an explicitly empty --sandbox is a usage error, never the default"
else
  fail "LAYOUT-GUARD-04 expected exit 64 and nothing written at the checkout for --sandbox \"\"; got rc=${RC} (checkout .claude present: $([ -e "${FIX2}/.claude" ] && echo yes || echo no))"
fi

S5="${WORK}/s5"
mkdir -p "${S5}"
build "${WORK}/guard05" "${FIX}" "${S5}"
if [ "${RC}" -eq 0 ] && [ -f "${S5}/.claude/hooks/tests/test-runner.sh" ]; then
  pass "LAYOUT-GUARD-05 a fresh sandbox is admitted and carries the runner"
else
  fail "LAYOUT-GUARD-05 expected exit 0 and a runner in a fresh sandbox; got rc=${RC}"
fi

WS3="${WORK}/ws3"
mkdir -p "${WS3}/.claude/hooks/sub" "${WS3}/.claude/worktrees/wt"
run_cmd "${WORK}/guard06" env CLAUDE_WORKSPACE_ROOT="${WS3}" bash "${HELPER}" --repo-root "${FIX}" --sandbox "${WS3}/.claude/hooks/sub"
if [ "${RC}" -eq 65 ] && [ ! -e "${WS3}/.claude/hooks/sub/.claude" ]; then
  pass "LAYOUT-GUARD-06 a sandbox inside a live configuration directory's hooks/ is refused"
else
  fail "LAYOUT-GUARD-06 expected exit 65 and nothing written inside the live hooks/; got rc=${RC}"
fi

run_cmd "${WORK}/guard07" env CLAUDE_WORKSPACE_ROOT="${WS3}" bash "${HELPER}" --repo-root "${FIX}" --sandbox "${WS3}/.claude/worktrees/wt"
if [ "${RC}" -eq 0 ] && [ -f "${WS3}/.claude/worktrees/wt/.claude/hooks/tests/test-runner.sh" ]; then
  pass "LAYOUT-GUARD-07 a linked checkout under a live configuration directory's worktrees/ is admitted"
else
  fail "LAYOUT-GUARD-07 expected exit 0 and a runner for a checkout under the live worktrees/; got rc=${RC}"
fi

FAKE_HOME="${WORK}/fake-home"
mkdir -p "${FAKE_HOME}/.claude"
printf '{}\n' > "${FAKE_HOME}/.claude/settings.json"
run_cmd "${WORK}/guard08" env -u CLAUDE_WORKSPACE_ROOT HOME="${FAKE_HOME}" bash "${HELPER}" --repo-root "${FIX}" --sandbox "${FAKE_HOME}"
if [ "${RC}" -eq 0 ] && [ -f "${FAKE_HOME}/.claude/hooks/tests/test-runner.sh" ]; then
  pass "LAYOUT-GUARD-08 an overridden HOME is not a live root: the guard reads the account home, not \${HOME}"
else
  fail "LAYOUT-GUARD-08 expected exit 0 for a sandbox at an overriding HOME (the guard must read the account home, not \${HOME}); got rc=${RC}"
fi

# ── LAYOUT-PURGE — the rebuild removes exactly what the last build recorded ───────
FIXC="${WORK}/fixc"
fixture_copied "${FIXC}"
printf '#!/bin/bash\necho "Total: 0  PASS: 0  FAIL: 0"\n' > "${FIXC}/core/hooks/tests/zz-stale.test.sh"
printf '#!/bin/bash\nexit 0\n' > "${FIXC}/core/hooks/block-zz-stale.sh"
SP="${WORK}/sp"
mkdir -p "${SP}"
build "${WORK}/purge01a" "${FIXC}" "${SP}"
_planted=0
if [ "${RC}" -eq 0 ] && [ -f "${SP}/.claude/hooks/tests/zz-stale.test.sh" ] && [ -f "${SP}/.claude/hooks/block-zz-stale.sh" ]; then _planted=1; fi
/bin/rm -f "${FIXC}/core/hooks/tests/zz-stale.test.sh" "${FIXC}/core/hooks/block-zz-stale.sh"
build "${WORK}/purge01b" "${FIXC}" "${SP}"
if [ "${_planted}" -eq 1 ] && [ "${RC}" -eq 0 ] && [ ! -e "${SP}/.claude/hooks/tests/zz-stale.test.sh" ] && [ ! -e "${SP}/.claude/hooks/block-zz-stale.sh" ] && [ -f "${SP}/.claude/hooks/tests/test-runner.sh" ]; then
  pass "LAYOUT-PURGE-01 a suite and a hook deleted from the source since the last build are gone after the rebuild"
else
  fail "LAYOUT-PURGE-01 expected the deleted suite and hook to be removed on rebuild; got first-build=${_planted} rc=${RC} (stale suite present: $([ -e "${SP}/.claude/hooks/tests/zz-stale.test.sh" ] && echo yes || echo no))"
fi

printf '#!/bin/bash\n' > "${SP}/.claude/hooks/tests/zz-planted.test.sh"
build "${WORK}/purge02" "${FIXC}" "${SP}"
_fr="$(layout_freshness "${SP}/.claude/hooks/tests")"
if [ "${RC}" -eq 0 ] && [ -f "${SP}/.claude/hooks/tests/zz-planted.test.sh" ] && [ "${_fr}" = "STALE unrecorded .claude/hooks/tests/zz-planted.test.sh" ]; then
  pass "LAYOUT-PURGE-02 a file the helper never recorded survives the purge, and the freshness check flags it"
else
  fail "LAYOUT-PURGE-02 expected the unrecorded file to survive the rebuild and to be flagged; got rc=${RC} present=$([ -f "${SP}/.claude/hooks/tests/zz-planted.test.sh" ] && echo yes || echo no) freshness='${_fr}'"
fi

SQ="${WORK}/sq"
mkdir -p "${SQ}"
build "${WORK}/purge03a" "${FIX}" "${SQ}"
printf 'outside the layout\n' > "${WORK}/outside.txt"
printf 'f\t../outside.txt\t-\n' >> "${SQ}/.claude/hooks/tests/.layout-footprint"
build "${WORK}/purge03b" "${FIX}" "${SQ}"
_outside=""
if [ -f "${WORK}/outside.txt" ]; then IFS= read -r _outside < "${WORK}/outside.txt" || true; fi
if [ "${RC}" -eq 65 ] && [ "${_outside}" = "outside the layout" ]; then
  pass "LAYOUT-PURGE-03 a recorded path that leaves the layout root refuses the purge, and the file outside is untouched"
else
  fail "LAYOUT-PURGE-03 expected exit 65 and the outside file intact; got rc=${RC} outside='${_outside}'"
fi

SR="${WORK}/sr"
mkdir -p "${SR}"
build "${WORK}/purge04a" "${FIX}" "${SR}"
OUTLIB="${WORK}/outside-lib"
mkdir -p "${OUTLIB}"
printf 'outside the layout\n' > "${OUTLIB}/dep-resolve.sh"
if [ -d "${SR}/.claude/hooks/lib" ]; then /bin/mv "${SR}/.claude/hooks/lib" "${WORK}/sr-lib-moved"; fi
ln -s "${OUTLIB}" "${SR}/.claude/hooks/lib"
build "${WORK}/purge04b" "${FIX}" "${SR}"
_outlib=""
if [ -f "${OUTLIB}/dep-resolve.sh" ]; then IFS= read -r _outlib < "${OUTLIB}/dep-resolve.sh" || true; fi
if [ "${RC}" -eq 65 ] && [ "${_outlib}" = "outside the layout" ]; then
  pass "LAYOUT-PURGE-04 a recorded directory replaced by a link that leaves the sandbox refuses the purge, and the file behind the link is untouched"
else
  fail "LAYOUT-PURGE-04 expected exit 65 and the file behind the link intact; got rc=${RC} outside='${_outlib}'"
fi

# ── LAYOUT-FOOTPRINT-01 / LAYOUT-IGNORE-01 — the default site's footprint ─────────
# FIX holds a default-site build (LAYOUT-DEFAULT-01): exactly what a checkout-root run
# writes, which is the population the ignore rules must cover.
_fp="${FIX}/.claude/hooks/tests/.layout-footprint"
: > "${WORK}/fp.recorded"
if [ -f "${_fp}" ]; then
  awk -F'\t' '$1 == "f" { print $2 }' "${_fp}" > "${WORK}/fp.recorded"
  printf '%s\n' .claude/hooks/tests/.layout-owner .claude/hooks/tests/.layout-footprint .claude/hooks/tests/.layout-digest >> "${WORK}/fp.recorded"
fi
LC_ALL=C sort -u "${WORK}/fp.recorded" > "${WORK}/fp.recorded.sorted"
find "${FIX}/.claude" -type f > "${WORK}/fp.found.raw" 2>/dev/null
awk -v p="${FIX}/" 'index($0, p) == 1 { print substr($0, length(p) + 1) }' "${WORK}/fp.found.raw" > "${WORK}/fp.found"
LC_ALL=C sort -u "${WORK}/fp.found" > "${WORK}/fp.found.sorted"
_rec_n=0
while IFS= read -r _l; do _rec_n=$((_rec_n + 1)); done < "${WORK}/fp.recorded.sorted"
if [ "${_rec_n}" -gt 3 ] && cmp -s "${WORK}/fp.recorded.sorted" "${WORK}/fp.found.sorted"; then
  pass "LAYOUT-FOOTPRINT-01 every file the default site wrote is in the footprint, and every recorded file exists (${_rec_n} paths)"
else
  fail "LAYOUT-FOOTPRINT-01 the recorded footprint (${_rec_n} paths) and the files present at the default site differ, or no footprint was recorded"
fi

_ign_ok=0
_ign_detail=""
if [ "${_rec_n}" -gt 3 ]; then
  git -C "${SRC_ROOT}" check-ignore --no-index --stdin < "${WORK}/fp.recorded.sorted" > "${WORK}/fp.ignored" 2> "${WORK}/fp.ignored.err"
  _ign_rc=$?
  _ctl_rc=0
  git -C "${SRC_ROOT}" check-ignore -q --no-index -- core/hooks/tests/setup-ci-layout.test.sh 2>/dev/null || _ctl_rc=$?
  if [ "${_ign_rc}" -gt 1 ] || [ "${_ctl_rc}" -gt 1 ]; then
    _ign_detail="git check-ignore could not read the source checkout ${SRC_ROOT} (rc ${_ign_rc}/${_ctl_rc})"
  elif [ "${_ctl_rc}" -ne 1 ]; then
    _ign_detail="the control — a tracked suite that must NOT read as ignored — read as ignored, so the probe cannot discriminate"
  elif cmp -s "${WORK}/fp.recorded.sorted" "${WORK}/fp.ignored"; then
    _ign_ok=1
  else
    _ign_detail="not every recorded path is git-ignored at the source checkout"
  fi
else
  _ign_detail="no default-site footprint to grade"
fi
if [ "${_ign_ok}" -eq 1 ]; then
  pass "LAYOUT-IGNORE-01 every path a default-site build writes is git-ignored (${_rec_n} paths; a tracked suite reads not-ignored)"
else
  fail "LAYOUT-IGNORE-01 ${_ign_detail}"
fi

# ── LAYOUT-OWNER-01 — ownership is taken before the first copy ───────────────────
FIXD="${WORK}/fixd"
fixture_copied "${FIXD}"
SI="${WORK}/si"
mkdir -p "${SI}"
/bin/chmod 000 "${FIXD}/core/hooks/tests/scope-guard.test.sh"
build "${WORK}/owner01a" "${FIXD}" "${SI}"
_rc_interrupted="${RC}"
/bin/chmod 755 "${FIXD}/core/hooks/tests/scope-guard.test.sh"
_recorded_before_copy=1
if [ -f "${SI}/.claude/hooks/tests/.layout-footprint" ]; then
  awk -F'\t' '$1 == "f" && $2 == ".claude/hooks/tests/scope-guard.test.sh" { found = 1 } END { exit !found }' "${SI}/.claude/hooks/tests/.layout-footprint" || _recorded_before_copy=0
else
  _recorded_before_copy=0
fi
_owned_part=0
if [ "${_rc_interrupted}" -ne 0 ] && [ -f "${SI}/.claude/hooks/tests/.layout-owner" ] && [ ! -e "${SI}/.claude/hooks/tests/.layout-digest" ] && [ "${_recorded_before_copy}" -eq 1 ]; then _owned_part=1; fi
build "${WORK}/owner01b" "${FIXD}" "${SI}"
_fr="$(layout_freshness "${SI}/.claude/hooks/tests")"
if [ "${_owned_part}" -eq 1 ] && [ "${RC}" -eq 0 ] && [ "${_fr}" = "FRESH" ]; then
  pass "LAYOUT-OWNER-01 an interrupted build is owned and recorded up to the failed copy, and the next run replaces it"
else
  fail "LAYOUT-OWNER-01 expected an owned, recorded, digest-less partial layout that the next run replaces; got interrupted-rc=${_rc_interrupted} owned-part=${_owned_part} rebuild-rc=${RC} freshness='${_fr}'"
fi

# ── LAYOUT-FRESH-02..04 — the freshness check discriminates ──────────────────────
SF="${WORK}/sf"
mkdir -p "${SF}"
build "${WORK}/fresh02" "${FIX}" "${SF}"
printf '\n# mutated after the build\n' >> "${SF}/.claude/hooks/block-destructive.sh"
_fr="$(layout_freshness "${SF}/.claude/hooks/tests")"
if [ "${_fr}" = "STALE mutated .claude/hooks/block-destructive.sh" ]; then
  pass "LAYOUT-FRESH-02 a layout file changed after the build reads stale"
else
  fail "LAYOUT-FRESH-02 expected 'STALE mutated .claude/hooks/block-destructive.sh'; got '${_fr}'"
fi

FIXE="${WORK}/fixe"
fixture_copied "${FIXE}"
SE="${WORK}/se"
mkdir -p "${SE}"
build "${WORK}/fresh03" "${FIXE}" "${SE}"
printf '\n# source edited after the build\n' >> "${FIXE}/core/hooks/block-destructive.sh"
_fr="$(layout_freshness "${SE}/.claude/hooks/tests")"
if [ "${_fr}" = "STALE source-changed core/hooks/block-destructive.sh" ]; then
  pass "LAYOUT-FRESH-03 a source edited after the build reads stale"
else
  fail "LAYOUT-FRESH-03 expected 'STALE source-changed core/hooks/block-destructive.sh'; got '${_fr}'"
fi

FIXG="${WORK}/fixg"
fixture_copied "${FIXG}"
SG="${WORK}/sg"
mkdir -p "${SG}"
build "${WORK}/fresh04" "${FIXG}" "${SG}"
printf '#!/bin/bash\n' > "${FIXG}/core/hooks/tests/zz-new.test.sh"
_fr="$(layout_freshness "${SG}/.claude/hooks/tests")"
if [ "${_fr}" = "STALE new-source core/hooks/tests/zz-new.test.sh" ]; then
  pass "LAYOUT-FRESH-04 a suite added to the source after the build reads stale"
else
  fail "LAYOUT-FRESH-04 expected 'STALE new-source core/hooks/tests/zz-new.test.sh'; got '${_fr}'"
fi

finish

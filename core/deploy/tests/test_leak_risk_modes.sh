#!/usr/bin/env bash
# test_leak_risk_modes.sh — one permission policy for leak-risk files: mode 0600 on each
# file and 0700 on each folder, set at install and at a full update, never by
# `update.sh --surfaces-only`, and never on working state.
#
# The population is the placement standard's surface register: every row whose Class cell
# reads `Leak-risk` (core/standards/instance-data-placement-standard.md § Surface register).
# The library that holds it is core/deploy/lib-leak-risk-modes.sh. The validator's finding,
# check A11, has its own arms in core/deploy/tests/test_validate_install.sh (T8024-V*).
#
#   Part L — library units on a scratch workspace root (every platform)
#     L0   the library's row set equals the register's Leak-risk rows; sensitivity S-100,
#          specificity S-98 (Working state)
#     L1   the population equals the expected set exactly, every backup form included
#     L2   each override variable moves its row; S-08 matches the installer's expression
#     L2b  each leaf the library composes equals the one its source names
#     L3   enforce sets the policy and counts each off-policy member once
#     L4   a second enforce changes nothing and prints no change line
#     L5   a dry run changes no mode and counts what L3 changed
#     L6   findings: 0 at the policy; a dot-prefixed S-10 backup at 0644 is one FAIL
#     L6b  an owner-only deviation (0400) is an INFO, never a FAIL
#     L7   a tree copied under umask 077 is normalized to 0700/0600
#     L8   a chmod that returns 0 and changes nothing counts as failed, never as changed
#     L9   an unreadable folder chain is opened and set in one pass
#   Part N — near-miss arms: working state and look-alike paths keep their modes
#     N1   a working-state file under the main checkout's /local-state/ (AC-3)
#     N2   working state in today's container, and the container itself
#     N3   the S-40 glob does not reach an S-41-shaped copy (a glob-width guard)
#     N4   the backup predicate does not reach a name that only contains the stem
#     N5   a symlink is never followed, inside an S-40 copy or in a backup's place
#   Part E — the return-code contract under `set -Eeuo pipefail` (E3 Darwin-only)
#   Part X — the roster-needle extractor creates S-08 at 0600 (with a mutant)
#   Part F — every scaffold copy in install.sh, setup-workspace.sh and update.sh creates
#            at 0600 (each with a mutant that drops the umask wrapper)
#   Part I — a real install on a sandbox copy of this checkout (Darwin)
#   Part U — real updates and dry runs on the same sandbox (Darwin)
#   Part S — `update.sh --surfaces-only` runs no mode pass (Darwin)
#   Part P — opt-in: the pass timed on a tree the size of the largest live S-40 copy,
#            only when T8024_MEASURE_FILES is set to a file count
#
# Fixture names are derived from the library and the accessors at run time; this file
# carries no leak-risk leaf literal. No arm reads a leak-risk file's contents. Every
# fixture is seeded with an explicit chmod under umask 022.
#
# The install and update sandbox follows core/deploy/tests/test_git_hooks_install.sh: a
# COPY of this checkout's tracked and untracked non-ignored files, given its own git init,
# inside the sandbox workspace root. Its fixtures are seeded after the snapshot commit, so
# nothing is ever staged.
#
# Run by core/deploy/tests/run-install-regression.sh. Output: one
# "test_leak_risk_modes: N passed, M failed, K skipped" line; exits non-zero on any FAIL.
set -uo pipefail
umask 022

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
RESOLVER="${REPO_ROOT}/core/deploy/lib-instance-path.sh"
LIB="${REPO_ROOT}/core/deploy/lib-leak-risk-modes.sh"
STANDARD="${REPO_ROOT}/core/standards/instance-data-placement-standard.md"
unset PMO_INSTANCE_PATH PMO_LOCALIZED_NEEDLES PMO_PEOPLE_ROSTER PMO_PROJECT_KEYS \
      PMO_INSTALL_GIT_HOOKS CLAUDE_HOOK_BYPASS CLAUDE_WORKSPACE_ROOT PMO_PLATFORM_WORKSPACE_ROOT
export GIT_CONFIG_NOSYSTEM=1

PASS=0
FAIL=0
SKIP=0
SBX="$(mktemp -d -t leak-risk-modes.XXXXXX)"
SBX="$(cd "${SBX}" && pwd -P)"
export HOME="${SBX}/home"
mkdir -p "${HOME}"
IS_DARWIN=0
[ "$(uname -s)" = "Darwin" ] && IS_DARWIN=1

cleanup() {
  if [ -n "${SBX}" ] && [ -d "${SBX}" ]; then
    if [ "${IS_DARWIN}" -eq 1 ]; then chflags -R nouchg "${SBX}" 2>/dev/null; fi
    chmod -R u+rwx "${SBX}" 2>/dev/null
    /bin/rm -rf "${SBX}"
  fi
  return 0
}
trap cleanup EXIT

report() {
  if [ "$2" = "1" ]; then printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else printf '  FAIL: %s\n' "$1"; [ -n "${3:-}" ] && printf '        %s\n' "$3"; FAIL=$((FAIL + 1)); fi
}
skip() { printf '  SKIP: %s — %s\n' "$1" "$2"; SKIP=$((SKIP + 1)); }

if stat -c '%a' / >/dev/null 2>&1; then
  mode_of() { stat -c '%a' "$1" 2>/dev/null || printf 'absent'; }
else
  mode_of() { stat -f '%Lp' "$1" 2>/dev/null || printf 'absent'; }
fi
# expect_mode NAME PATH WANT
expect_mode() {
  local got; got="$(mode_of "$2")"
  if [ "${got}" = "$3" ]; then report "$1" 1; else report "$1" 0 "$2 reads ${got}, want $3"; fi
}
# seed PATH MODE — a fixture file with fixture content, at an explicit mode.
seed() { mkdir -p "$(dirname "$1")"; printf 'fixture\n' > "$1"; chmod "$2" "$1"; }
# off_count DIR TYPE WANT — entries of TYPE under DIR whose mode is not exactly WANT.
off_count() {
  local n; n="$({ find -P "$1" -type "$2" ! -perm "$3" -print 2>/dev/null || true; } | wc -l)"
  printf '%s\n' "${n//[!0-9]/}"
}
has_line() { if grep -qF -- "$2" <<<"$1"; then return 0; fi; return 1; }
count_lines() { local n; n="$(grep -cE -- "$2" <<<"$1")"; printf '%s\n' "${n:-0}"; }

# The resolver is shipped before this card; the library is this card's.
if [ -r "${RESOLVER}" ]; then
  # shellcheck source=../lib-instance-path.sh disable=SC1091
  . "${RESOLVER}"
fi
LIB_OK=0
if [ -r "${LIB}" ]; then
  # shellcheck source=../lib-leak-risk-modes.sh disable=SC1091
  . "${LIB}" && LIB_OK=1
fi
need_lib() {
  if [ "${LIB_OK}" -ne 1 ]; then report "$1" 0 "library absent: ${LIB}"; return 1; fi
  return 0
}
FILE_ROWS="S-08 S-09 S-10 S-15 S-33 S-48"
primary() { lib_leak_risk_primary_for "$1" "$2" 2>/dev/null; }

# =========================================================================== #
# Part L — library units                                                      #
# =========================================================================== #
printf '\nPart L. Library units\n'

# L0 — register parity, with a planted Leak-risk row (sensitivity) and a planted
# Working-state row (specificity). The register parse takes every row id of any width.
register_leak_rows() {
  python3 - "$1" <<'PY'
import re, sys
rows = []
for line in open(sys.argv[1], encoding="utf-8"):
    m = re.match(r'^\| (S-[0-9]+) \|', line)
    if not m:
        continue
    cells = [c.strip() for c in line.strip().strip('|').split('|')]
    if len(cells) >= 3 and cells[2] == 'Leak-risk':
        rows.append(m.group(1))
print(' '.join(sorted(set(rows), key=lambda r: int(r[2:]))))
PY
}
PARITY_UNHANDLED=""
PARITY_EXTRA=""
parity_against() {
  local expected lib_rows r
  expected=" $(register_leak_rows "$1") "
  lib_rows=" $(lib_leak_risk_rows | awk -F'\t' '{print $1}' | tr '\n' ' ') "
  PARITY_UNHANDLED=""; PARITY_EXTRA=""
  for r in ${expected}; do
    case "${lib_rows}" in *" ${r} "*) ;; *) PARITY_UNHANDLED="${PARITY_UNHANDLED} ${r}" ;; esac
  done
  for r in ${lib_rows}; do
    case "${expected}" in *" ${r} "*) ;; *) PARITY_EXTRA="${PARITY_EXTRA} ${r}" ;; esac
  done
}
if need_lib "T8024-L0: the library's rows equal the register's Leak-risk rows"; then
  parity_against "${STANDARD}"
  report "T8024-L0: the library's rows equal the register's Leak-risk rows" \
    "$([ -z "${PARITY_UNHANDLED}${PARITY_EXTRA}" ] && echo 1 || echo 0)" \
    "unhandled:${PARITY_UNHANDLED:- none}; not a Leak-risk row:${PARITY_EXTRA:- none}"
  bad_deferred="$(lib_leak_risk_rows | awk -F'\t' '$2 == "deferred" && $3 == "" {print $1}')"
  report "T8024-L0: every deferred row carries a reason" "$([ -z "${bad_deferred}" ] && echo 1 || echo 0)" \
    "deferred with no reason: ${bad_deferred}"
  plant="${SBX}/standard-planted.md"
  cp "${STANDARD}" "${plant}"
  printf '| S-100 | planted surface | Leak-risk | x | x | design |\n' >> "${plant}"
  printf '| S-98 | planted surface | Working state | x | x | design |\n' >> "${plant}"
  parity_against "${plant}"
  report "T8024-L0 sensitivity: a planted Leak-risk row S-100 is reported unhandled" \
    "$(case " ${PARITY_UNHANDLED} " in *" S-100 "*) echo 1 ;; *) echo 0 ;; esac)" "unhandled:${PARITY_UNHANDLED:- none}"
  report "T8024-L0 specificity: a planted Working-state row S-98 is not expected" \
    "$(case " ${PARITY_UNHANDLED} " in *" S-98 "*) echo 0 ;; *) echo 1 ;; esac)" "unhandled:${PARITY_UNHANDLED:- none}"
fi

# The L fixture: every resolvable primary; three backup forms for S-08, S-09 and S-10; the
# dot-prefixed form for S-48; two S-40 copies. Near-miss plants (Part N) sit beside them.
WS_L="${SBX}/l-ws"
mkdir -p "${WS_L}"
EXPECTED_L=""
C_L=""
B9="" ; B10="" ; T1="" ; T2=""
build_l_fixture() {
  local row p dir b
  C_L="$(pmo_instance_path_for "${WS_L}")"
  mkdir -p "${C_L}"; chmod 755 "${C_L}"
  EXPECTED_L=""
  for row in ${FILE_ROWS}; do
    p="$(primary "${WS_L}" "${row}")"
    [ -n "${p}" ] || continue
    seed "${p}" 644
    EXPECTED_L="${EXPECTED_L}${row}	file	${p}
"
    dir="${p%/*}"; b="${p##*/}"
    case "${row}" in
      S-08|S-09|S-10)
        seed "${dir}/${b}.bak-x" 644; seed "${dir}/.${b}" 644; seed "${dir}/.${b}.bak-x" 644
        EXPECTED_L="${EXPECTED_L}${row}	file	${dir}/${b}.bak-x
${row}	file	${dir}/.${b}
${row}	file	${dir}/.${b}.bak-x
" ;;
      S-48)
        seed "${dir}/.${b}" 644
        EXPECTED_L="${EXPECTED_L}${row}	file	${dir}/.${b}
" ;;
    esac
    [ "${row}" = "S-09" ] && B9="${b}"
    [ "${row}" = "S-10" ] && B10="${b}"
  done
  T1="${WS_L}/.backup-pre-update-instance-20260101T000000Z"
  T2="${WS_L}/.backup-pre-update-instance-20260102T000000Z"
  mkdir -p "${T1}/sub" "${T2}"
  EXPECTED_L="${EXPECTED_L}S-40	tree	${T1}
S-40	tree	${T2}
"
}
# seed_l_modes — every L member off the policy, in the shapes L3 must repair.
L_OFF_MEMBERS=0
seed_l_modes() {
  local row p dir b
  L_OFF_MEMBERS=0
  for row in ${FILE_ROWS}; do
    p="$(primary "${WS_L}" "${row}")"
    [ -n "${p}" ] || continue
    case "${row}" in S-15) chmod 755 "${p}" ;; S-33) chmod 640 "${p}" ;; *) chmod 644 "${p}" ;; esac
    L_OFF_MEMBERS=$((L_OFF_MEMBERS + 1))
    dir="${p%/*}"; b="${p##*/}"
    case "${row}" in
      S-08|S-09|S-10) chmod 644 "${dir}/${b}.bak-x" "${dir}/.${b}" "${dir}/.${b}.bak-x"; L_OFF_MEMBERS=$((L_OFF_MEMBERS + 3)) ;;
      S-48) chmod 644 "${dir}/.${b}"; L_OFF_MEMBERS=$((L_OFF_MEMBERS + 1)) ;;
    esac
  done
  seed "${T1}/a" 644; seed "${T1}/sub/b" 755; seed "${T1}/sub/c" 400
  chmod 755 "${T1}" "${T1}/sub"
  seed "${T2}/a" 644; chmod 755 "${T2}"
  L_OFF_MEMBERS=$((L_OFF_MEMBERS + 2))
}
# Part N plants, seeded before L3 so every L arm runs with them present.
N1_FILE="${WS_L}/pmo-platform/local-state/release-runs/fixture-run.md"
plant_near_misses() {  # <ws> <container> <tree> <S-09 basename>
  local ws="$1" c="$2" t="$3" b9="$4" stem
  seed "${ws}/pmo-platform/local-state/release-runs/fixture-run.md" 640
  chmod 750 "${ws}/pmo-platform/local-state/release-runs"
  seed "${c}/hub-state/fixture-run.md" 640
  seed "${c}/fixture.mode" 640
  chmod 755 "${c}"
  seed "${ws}/.backup-pre-update-20260101T000000Z/fixture.txt" 640
  chmod 750 "${ws}/.backup-pre-update-20260101T000000Z"
  if [ -n "${b9}" ]; then
    stem="${b9%.*}"
    seed "${c}/x${b9}" 640
    seed "${c}/${stem}-notes.md" 640
    seed "${ws}/outside-target-2.txt" 640
    ln -sf "${ws}/outside-target-2.txt" "${c}/.${b9}.bak-link"
  fi
  seed "${ws}/outside-target.txt" 640
  mkdir -p "${t}"
  ln -sf "${ws}/outside-target.txt" "${t}/link-out"
}
check_near_misses() {  # <label> <ws> <container> <S-09 basename>
  local lbl="$1" ws="$2" c="$3" b9="$4" stem
  expect_mode "T8024-N1 (${lbl}): a working-state file under /local-state/ keeps 640" \
    "${ws}/pmo-platform/local-state/release-runs/fixture-run.md" 640
  expect_mode "T8024-N1 (${lbl}): its folder keeps 750" "${ws}/pmo-platform/local-state/release-runs" 750
  expect_mode "T8024-N2 (${lbl}): working state in today's container keeps 640" "${c}/hub-state/fixture-run.md" 640
  expect_mode "T8024-N2 (${lbl}): a mode-file-shaped file keeps 640" "${c}/fixture.mode" 640
  expect_mode "T8024-N2 (${lbl}): today's container itself keeps 755" "${c}" 755
  expect_mode "T8024-N3 (${lbl}): the S-40 glob does not reach an S-41-shaped copy (folder 750)" \
    "${ws}/.backup-pre-update-20260101T000000Z" 750
  expect_mode "T8024-N3 (${lbl}): nor its file (640)" "${ws}/.backup-pre-update-20260101T000000Z/fixture.txt" 640
  if [ -n "${b9}" ]; then
    stem="${b9%.*}"
    expect_mode "T8024-N4 (${lbl}): a name with a prefix before the stem keeps 640" "${c}/x${b9}" 640
    expect_mode "T8024-N4 (${lbl}): a name that only contains the stem keeps 640" "${c}/${stem}-notes.md" 640
    expect_mode "T8024-N5 (${lbl}): a backup-shaped symlink's target keeps 640" "${ws}/outside-target-2.txt" 640
  else
    report "T8024-N4/N5 (${lbl}): the S-09 basename is resolvable" 0 "library absent: no S-09 basename"
  fi
  expect_mode "T8024-N5 (${lbl}): a symlink inside an S-40 copy is not followed" "${ws}/outside-target.txt" 640
}

if need_lib "T8024-L1: the population equals the expected set"; then
  build_l_fixture
  seed_l_modes
  plant_near_misses "${WS_L}" "${C_L}" "${T1}" "${B9}"
  got="$(lib_leak_risk_population_for "${WS_L}" | sort)"
  want="$(printf '%s' "${EXPECTED_L}" | sort)"
  report "T8024-L1: the population equals the expected set exactly (18 members, every backup form)" \
    "$([ "${got}" = "${want}" ] && echo 1 || echo 0)" \
    "got $(printf '%s\n' "${got}" | grep -c .) lines; diff: $(diff <(printf '%s\n' "${want}") <(printf '%s\n' "${got}") | tr '\n' '|')"
  p15="$(primary "${WS_L}" S-15)"
  mv "${p15}" "${SBX}/s15-aside"
  got2="$(lib_leak_risk_population_for "${WS_L}" | sort)"
  gone="$(diff <(printf '%s\n' "${got}") <(printf '%s\n' "${got2}") | grep -c '^<')"
  report "T8024-L1 sensitivity: removing one primary removes exactly its line" \
    "$([ "${gone}" = "1" ] && ! has_line "${got2}" "${p15}" && echo 1 || echo 0)" "lines removed: ${gone}"
  mv "${SBX}/s15-aside" "${p15}"

  # L2 — the override variables, each in a subshell.
  ov="${SBX}/override"
  mkdir -p "${ov}"
  r="$(PMO_INSTANCE_PATH="${ov}/inst"; export PMO_INSTANCE_PATH; for row in ${FILE_ROWS}; do primary "${WS_L}" "${row}"; done)"
  under=1
  while IFS= read -r p; do case "${p}" in "${ov}/inst/"*) ;; *) under=0 ;; esac; done <<<"${r}"
  report "T8024-L2: PMO_INSTANCE_PATH moves every file row" "${under}" "$(tr '\n' ' ' <<<"${r}")"
  report "T8024-L2: PMO_LOCALIZED_NEEDLES moves S-08" \
    "$([ "$(PMO_LOCALIZED_NEEDLES="${ov}/n.txt"; export PMO_LOCALIZED_NEEDLES; primary "${WS_L}" S-08)" = "${ov}/n.txt" ] && echo 1 || echo 0)"
  report "T8024-L2: PMO_PEOPLE_ROSTER moves S-09" \
    "$([ "$(PMO_PEOPLE_ROSTER="${ov}/r.yaml"; export PMO_PEOPLE_ROSTER; primary "${WS_L}" S-09)" = "${ov}/r.yaml" ] && echo 1 || echo 0)"
  report "T8024-L2: PMO_PROJECT_KEYS moves S-33" \
    "$([ "$(PMO_PROJECT_KEYS="${ov}/k.txt"; export PMO_PROJECT_KEYS; primary "${WS_L}" S-33)" = "${ov}/k.txt" ] && echo 1 || echo 0)"
  installer_s08="$(PMO_INSTANCE_PATH="$(pmo_instance_path_for "${WS_L}")" pmo_localized_needles)"
  report "T8024-L2: S-08 equals the installer's expression, keyed on the passed root" \
    "$([ "$(primary "${WS_L}" S-08)" = "${installer_s08}" ] && echo 1 || echo 0)" \
    "library $(primary "${WS_L}" S-08) vs installer ${installer_s08}"
  under=1
  for row in ${FILE_ROWS}; do
    case "$(primary "${WS_L}" "${row}")" in "${C_L}/"*) ;; *) under=0 ;; esac
  done
  report "T8024-L2 specificity: with no override, every file row sits in today's container" "${under}"

  # L2b — each composed leaf equals the one its source names (the repoint targets).
  leaf() { local p; p="$(primary "${WS_L}" "$1")"; printf '%s\n' "${p##*/}"; }
  tmpl_leaf="$(sed -n 's/.*\$(pmo_instance_path)\/\([A-Za-z0-9._-]*\).*/\1/p' \
    "${REPO_ROOT}/operations/templates/people-graph-clarification-queue-template.md" | sed -n 1p)"
  report "T8024-L2b: S-10's leaf equals the clarification-queue template's" \
    "$([ -n "${tmpl_leaf}" ] && [ "$(leaf S-10)" = "${tmpl_leaf}" ] && echo 1 || echo 0)" \
    "library $(leaf S-10) vs template ${tmpl_leaf:-<none parsed>}"
  reg15_leaf="$(sed -n 's/^| S-15 | The `\([^`]*\)` script.*/\1/p' "${STANDARD}")"
  report "T8024-L2b: S-15's leaf equals the register row's" \
    "$([ -n "${reg15_leaf}" ] && [ "$(leaf S-15)" = "${reg15_leaf}" ] && echo 1 || echo 0)" \
    "library $(leaf S-15) vs register ${reg15_leaf:-<none parsed>}"
  dc3_leaf="$(sed -n 's/.*c23_project_keys="\${PMO_PROJECT_KEYS:-\$(pmo_instance_path)\/\([A-Za-z0-9._-]*\)}".*/\1/p' \
    "${REPO_ROOT}/core/deploy/deploy.sh" | sed -n 1p)"
  report "T8024-L2b: S-33's leaf equals deploy.sh's DC3 pass" \
    "$([ -n "${dc3_leaf}" ] && [ "$(leaf S-33)" = "${dc3_leaf}" ] && echo 1 || echo 0)" \
    "library $(leaf S-33) vs deploy.sh ${dc3_leaf:-<none parsed>}"
  gi_leaf="$(awk -v a="/$(leaf S-15)" 'found && $0 !~ /^#/ && $0 != "" { print; exit } $0 == a { found = 1 }' "${REPO_ROOT}/.gitignore")"
  report "T8024-L2b: S-48's leaf equals the .gitignore scan-list line after the S-15 line" \
    "$([ -n "${gi_leaf}" ] && [ "$(leaf S-48)" = "${gi_leaf}" ] && echo 1 || echo 0)" \
    "library $(leaf S-48) vs .gitignore ${gi_leaf:-<none parsed>}"
  upd_root="$(grep -c -F 'BACKUP_DIR_ROOT="${WORKSPACE_ROOT}/.backup-pre-update"' "${REPO_ROOT}/update.sh")"
  upd_inst="$(grep -c -F '"${BACKUP_DIR_ROOT}-instance-$(date' "${REPO_ROOT}/update.sh")"
  report "T8024-L2b: the S-40 glob is the form update.sh writes" \
    "$([ "${upd_root}" -ge 1 ] && [ "${upd_inst}" -ge 1 ] && echo 1 || echo 0)" \
    "update.sh root lines ${upd_root}, -instance- lines ${upd_inst}"

  # L3 — enforce sets the policy.
  out="$(lib_leak_risk_enforce_for "${WS_L}" 0 2>&1)"
  changed="${LIB_LEAK_RISK_CHANGED:-x}"
  lib_leak_risk_enforce_for "${WS_L}" 0 >/dev/null 2>&1
  report "T8024-L3: enforce counts every seeded off-policy member once (${L_OFF_MEMBERS})" \
    "$([ "${changed}" = "${L_OFF_MEMBERS}" ] && echo 1 || echo 0)" "LIB_LEAK_RISK_CHANGED=${changed}"
  allok=1; bad=""
  while IFS='	' read -r row kind p; do
    [ -n "${row}" ] || continue
    if [ "${kind}" = "file" ]; then
      [ "$(mode_of "${p}")" = "600" ] || { allok=0; bad="${bad} ${row}:$(mode_of "${p}")"; }
    fi
  done <<<"${EXPECTED_L}"
  report "T8024-L3: every file member reads 600, S-15 included" "${allok}" "off:${bad}"
  report "T8024-L3: S-40 copies — every folder 700, every file 600" \
    "$([ "$(off_count "${T1}" d 700)" = 0 ] && [ "$(off_count "${T1}" f 600)" = 0 ] \
        && [ "$(off_count "${T2}" d 700)" = 0 ] && [ "$(off_count "${T2}" f 600)" = 0 ] && echo 1 || echo 0)" \
    "T1 off: $(off_count "${T1}" d 700) folders, $(off_count "${T1}" f 600) files"
  report "T8024-L3: each change is logged with a LEAK-RISK-MODE: line" \
    "$([ "$(count_lines "${out}" '^LEAK-RISK-MODE: ')" = "${L_OFF_MEMBERS}" ] && echo 1 || echo 0)" \
    "$(count_lines "${out}" '^LEAK-RISK-MODE: ') lines"
  report "T8024-L3: one summary line" "$([ "$(count_lines "${out}" '^leak-risk modes: ')" = 1 ] && echo 1 || echo 0)"

  # L4 — idempotent.
  out="$(lib_leak_risk_enforce_for "${WS_L}" 0 2>&1)"
  out4="${out}"
  lib_leak_risk_enforce_for "${WS_L}" 0 >/dev/null 2>&1
  report "T8024-L4: a second enforce changes nothing" "$([ "${LIB_LEAK_RISK_CHANGED:-x}" = 0 ] && echo 1 || echo 0)" \
    "LIB_LEAK_RISK_CHANGED=${LIB_LEAK_RISK_CHANGED:-x}"
  report "T8024-L4: and prints no LEAK-RISK-MODE: line" "$([ "$(count_lines "${out4}" '^LEAK-RISK-MODE: ')" = 0 ] && echo 1 || echo 0)"
  report "T8024-L4: its summary reads 0 changed" "$(has_line "${out4}" 'leak-risk modes: 0 changed' && echo 1 || echo 0)" \
    "$(grep -m1 '^leak-risk modes:' <<<"${out4}")"

  # L5 — dry run.
  seed_l_modes
  before="$(lib_leak_risk_population_for "${WS_L}" | while IFS='	' read -r row kind p; do printf '%s %s\n' "${p}" "$(mode_of "${p}")"; done)"
  lib_leak_risk_enforce_for "${WS_L}" 1 >/dev/null 2>&1
  would="${LIB_LEAK_RISK_CHANGED:-x}"
  after="$(lib_leak_risk_population_for "${WS_L}" | while IFS='	' read -r row kind p; do printf '%s %s\n' "${p}" "$(mode_of "${p}")"; done)"
  report "T8024-L5: a dry run changes no mode" "$([ "${before}" = "${after}" ] && [ "$(off_count "${T1}" d 700)" -gt 0 ] && echo 1 || echo 0)"
  report "T8024-L5: its would-change count equals L3's (${L_OFF_MEMBERS})" "$([ "${would}" = "${L_OFF_MEMBERS}" ] && echo 1 || echo 0)" \
    "would change ${would}"
  lib_leak_risk_enforce_for "${WS_L}" 0 >/dev/null 2>&1

  # L6 — findings.
  lib_leak_risk_findings_for "${WS_L}" >/dev/null 2>&1
  report "T8024-L6: findings at the policy are 0" "$([ "${LIB_LEAK_RISK_FINDINGS:-x}" = 0 ] && echo 1 || echo 0)" \
    "LIB_LEAK_RISK_FINDINGS=${LIB_LEAK_RISK_FINDINGS:-x}"
  d10="$(primary "${WS_L}" S-10)"; d10="${d10%/*}/.${B10}"
  chmod 644 "${d10}"
  fout="$(lib_leak_risk_findings_for "${WS_L}" 2>&1)"
  lib_leak_risk_findings_for "${WS_L}" >/dev/null 2>&1
  report "T8024-L6: one dot-prefixed S-10 backup at 0644 is exactly one finding" \
    "$([ "${LIB_LEAK_RISK_FINDINGS:-x}" = 1 ] && echo 1 || echo 0)" "LIB_LEAK_RISK_FINDINGS=${LIB_LEAK_RISK_FINDINGS:-x}"
  report "T8024-L6: the finding names S-10 and the path" \
    "$(grep -qE "^FAIL	S-10	.*/\\.${B10}	644" <<<"${fout}" && echo 1 || echo 0)" "$(tr '\n' '|' <<<"${fout}")"
  chmod 600 "${d10}"
  # L6b — owner-only deviations are INFO (CD-3).
  p9="$(primary "${WS_L}" S-09)"
  chmod 400 "${p9}"; chmod 400 "${T1}/a"
  fout="$(lib_leak_risk_findings_for "${WS_L}" 2>&1)"
  lib_leak_risk_findings_for "${WS_L}" >/dev/null 2>&1
  report "T8024-L6b: an S-09 primary at 0400 and an S-40 file at 0400 are no FAIL" \
    "$([ "${LIB_LEAK_RISK_FINDINGS:-x}" = 0 ] && echo 1 || echo 0)" "LIB_LEAK_RISK_FINDINGS=${LIB_LEAK_RISK_FINDINGS:-x}"
  report "T8024-L6b: they are two INFO lines, naming S-09 and S-40" \
    "$([ "${LIB_LEAK_RISK_INFOS:-x}" = 2 ] && grep -q '^INFO	S-09	' <<<"${fout}" && grep -q '^INFO	S-40	' <<<"${fout}" && echo 1 || echo 0)" \
    "LIB_LEAK_RISK_INFOS=${LIB_LEAK_RISK_INFOS:-x}; $(tr '\n' '|' <<<"${fout}")"
  chmod 600 "${p9}" "${T1}/a"
fi

# L7 — normalize a tree copied under umask 077.
if need_lib "T8024-L7: a tree copied under umask 077 is normalized"; then
  src="${SBX}/n-src"; dst="${SBX}/n-dst"
  mkdir -p "${src}/d" "${dst}"
  seed "${src}/a" 644; seed "${src}/d/b" 755; seed "${src}/d/c" 400; chmod 755 "${src}/d"
  ( umask 077; cp -R "${src}/." "${dst}/" )
  pre_files="$(off_count "${dst}" f 600)"
  lib_leak_risk_normalize_tree "${dst}"
  n1="${LIB_LEAK_RISK_NORMALIZED:-x}"
  lib_leak_risk_normalize_tree "${dst}"
  n2="${LIB_LEAK_RISK_NORMALIZED:-x}"
  report "T8024-L7 control: umask alone leaves files off the policy" "$([ "${pre_files}" -gt 0 ] && echo 1 || echo 0)" \
    "${pre_files} files off after the copy"
  report "T8024-L7: the copy ends at 0700 folders and 0600 files" \
    "$([ "$(off_count "${dst}" d 700)" = 0 ] && [ "$(off_count "${dst}" f 600)" = 0 ] && echo 1 || echo 0)"
  report "T8024-L7: LIB_LEAK_RISK_NORMALIZED is >0 on the first call and 0 on the second" \
    "$([ "${n1}" != x ] && [ "${n1}" -gt 0 ] && [ "${n2}" = 0 ] && echo 1 || echo 0)" "first ${n1}, second ${n2}"
fi

# L8 — a chmod that returns 0 and changes nothing (FM-1): failed, never changed.
if need_lib "T8024-L8: a no-op chmod counts as failed, never as changed"; then
  ws8="${SBX}/l8-ws"
  mkdir -p "${ws8}"
  p8="$(primary "${ws8}" S-09)"
  seed "${p8}" 644
  seed "${ws8}/.backup-pre-update-instance-20260101T000000Z/a" 644
  fakebin="${SBX}/fakebin"
  mkdir -p "${fakebin}"
  printf '#!/bin/sh\nexit 0\n' > "${fakebin}/chmod"; chmod 755 "${fakebin}/chmod"
  r8="$( PATH="${fakebin}:${PATH}"; lib_leak_risk_enforce_for "${ws8}" 0 >/dev/null 2>"${SBX}/l8.err"
         printf '%s %s' "${LIB_LEAK_RISK_CHANGED:-x}" "${LIB_LEAK_RISK_FAILED:-x}" )"
  report "T8024-L8: CHANGED stays 0 and both members count as FAILED" "$([ "${r8}" = "0 2" ] && echo 1 || echo 0)" \
    "CHANGED FAILED = ${r8}"
  report "T8024-L8: each failure is a WARN-LEAK-RISK-MODE: line on stderr" \
    "$([ "$(grep -c '^WARN-LEAK-RISK-MODE: ' "${SBX}/l8.err")" = 2 ] && echo 1 || echo 0)" "$(tr '\n' '|' < "${SBX}/l8.err")"
  expect_mode "T8024-L8 control: the member really is still off the policy" "${p8}" 644
fi

# L9 — an unreadable folder chain inside an S-40 copy is opened and set in one pass.
if need_lib "T8024-L9: an unreadable folder chain is set in one pass"; then
  ws9="${SBX}/l9-ws"
  t9="${ws9}/.backup-pre-update-instance-20260101T000000Z"
  mkdir -p "${t9}/u/v"
  seed "${t9}/u/f" 644; seed "${t9}/u/v/g" 644
  chmod 300 "${t9}/u/v"; chmod 300 "${t9}/u"
  lib_leak_risk_enforce_for "${ws9}" 0 >/dev/null 2>&1
  r9="${LIB_LEAK_RISK_CHANGED:-x} ${LIB_LEAK_RISK_FAILED:-x}"
  expect_mode "T8024-L9: the unreadable folder reads 700" "${t9}/u" 700
  expect_mode "T8024-L9: the folder inside it reads 700" "${t9}/u/v" 700
  expect_mode "T8024-L9: the file two folders down reads 600" "${t9}/u/v/g" 600
  report "T8024-L9: one change, no failure" "$([ "${r9}" = "1 0" ] && echo 1 || echo 0)" "CHANGED FAILED = ${r9}"
fi

# =========================================================================== #
# Part N — near-miss arms on the L fixture, after L3's passes                 #
# =========================================================================== #
printf '\nPart N. Near-miss arms (library level)\n'
if need_lib "T8024-N1..N5 (library)"; then
  lib_leak_risk_normalize_tree "${T1}"
  check_near_misses "library" "${WS_L}" "${C_L}" "${B9}"
fi

# =========================================================================== #
# Part E — the return-code contract under set -Eeuo pipefail (FM-1)           #
# =========================================================================== #
printf '\nPart E. Return-code contract under set -Eeuo pipefail\n'
contract_run() {  # <lib> <ws> <tree> -> prints REACHED <failed> <findings>
  bash -c 'set -Eeuo pipefail
    if [ -r "$1" ]; then . "$1"; fi
    . "$2"
    lib_leak_risk_rows >/dev/null
    lib_leak_risk_population_for "$3" >/dev/null
    lib_leak_risk_enforce_for "$3" 1 >/dev/null
    lib_leak_risk_enforce_for "$3" 0 >/dev/null
    failed="${LIB_LEAK_RISK_FAILED}"
    lib_leak_risk_findings_for "$3" >/dev/null
    lib_leak_risk_normalize_tree "$4"
    printf "REACHED %s %s\n" "${failed}" "${LIB_LEAK_RISK_FINDINGS}"' _ "${RESOLVER}" "$1" "$2" "$3" 2>&1
}
if need_lib "T8024-E1..E4: the contract"; then
  e1="$(contract_run "${LIB}" "${SBX}/e1-empty" "${SBX}/e1-no-tree")"; rc=$?
  report "T8024-E1: an empty workspace root returns 0 under errexit" \
    "$([ "${rc}" -eq 0 ] && has_line "${e1}" "REACHED 0 0" && echo 1 || echo 0)" "rc ${rc}: $(tr '\n' '|' <<<"${e1}")"
  e2="$(contract_run "${LIB}" "${WS_L}" "${T1}")"; rc=$?
  report "T8024-E2: a population at the policy returns 0 under errexit" \
    "$([ "${rc}" -eq 0 ] && has_line "${e2}" "REACHED 0 0" && echo 1 || echo 0)" "rc ${rc}: $(tr '\n' '|' <<<"${e2}")"
  if [ "${IS_DARWIN}" -eq 1 ]; then
    ws3="${SBX}/e3-ws"
    mkdir -p "${ws3}"
    p3="$(primary "${ws3}" S-09)"
    seed "${p3}.bak-immutable" 644; chflags uchg "${p3}.bak-immutable"
    t3="${ws3}/.backup-pre-update-instance-20260101T000000Z"
    seed "${t3}/locked" 644; chflags uchg "${t3}/locked"
    e3="$(contract_run "${LIB}" "${ws3}" "${t3}")"; rc=$?
    report "T8024-E3: an immutable member and an immutable file in a copy return 0 under errexit" \
      "$([ "${rc}" -eq 0 ] && has_line "${e3}" "REACHED 2 2" && echo 1 || echo 0)" "rc ${rc}: $(tr '\n' '|' <<<"${e3}")"
    report "T8024-E3: the immutable member is named on a warning line" \
      "$(has_line "${e3}" "WARN-LEAK-RISK-MODE: S-09 ${p3}.bak-immutable" && echo 1 || echo 0)"
    chflags nouchg "${p3}.bak-immutable" "${t3}/locked"
  else
    skip "T8024-E3" "chflags is Darwin-only"
  fi
  lonely="${SBX}/lonely-lib"
  mkdir -p "${lonely}"
  cp "${LIB}" "${lonely}/"
  e4="$(bash -c 'set -Eeuo pipefail; . "$1"; lib_leak_risk_enforce_for "$2" 0 >/dev/null; lib_leak_risk_findings_for "$2" >/dev/null; printf "REACHED\n"' \
        _ "${lonely}/${LIB##*/}" "${WS_L}" 2>&1)"; rc=$?
  report "T8024-E4: the library alone, with no resolver beside it, returns 0 under errexit" \
    "$([ "${rc}" -eq 0 ] && has_line "${e4}" "REACHED" && echo 1 || echo 0)" "rc ${rc}: $(tr '\n' '|' <<<"${e4}")"
fi

# =========================================================================== #
# Part X — the roster-needle extractor creates S-08 at 0600 (PR-3)            #
# =========================================================================== #
printf '\nPart X. The roster-needle extractor\n'
EXTRACTOR="${REPO_ROOT}/core/deploy/extract-roster-needles.sh"
TEMPLATE_ROSTER="${REPO_ROOT}/operations/templates/people-roster-template.yaml"
run_extractor() {  # <extractor> <roster> <needles>
  ( umask 022; PMO_PEOPLE_ROSTER="$2" PMO_LOCALIZED_NEEDLES="$3" HOME="${SBX}/x-home" bash "$1" ) >/dev/null 2>&1
}
xw="${SBX}/x"
mkdir -p "${xw}/inst" "${SBX}/x-home"
cp "${TEMPLATE_ROSTER}" "${xw}/inst/roster.yaml"
run_extractor "${EXTRACTOR}" "${xw}/inst/roster.yaml" "${xw}/inst/needles.txt"
expect_mode "T8024-X1: the extractor creates an absent S-08 at 0600" "${xw}/inst/needles.txt" 600
mkdir -p "${xw}/mut"
cp "${EXTRACTOR}" "${RESOLVER}" "${xw}/mut/"
n_mut="$(python3 - "${xw}/mut/${EXTRACTOR##*/}" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
old = '( umask 077; touch "$NEEDLES" )'
print(t.count(old))
open(p, "w", encoding="utf-8").write(t.replace(old, 'touch "$NEEDLES"'))
PY
)"
if [ "${n_mut}" = "1" ]; then
  run_extractor "${xw}/mut/${EXTRACTOR##*/}" "${xw}/inst/roster.yaml" "${xw}/inst/needles-mut.txt"
  expect_mode "T8024-X1 sensitivity: without the umask wrapper the extractor creates at 0644" "${xw}/inst/needles-mut.txt" 644
else
  report "T8024-X1 sensitivity: the mutation anchor is found once" 0 "anchor found ${n_mut} times"
fi

# =========================================================================== #
# Part F — every scaffold copy creates at 0600                                #
# =========================================================================== #
printf '\nPart F. Scaffold creation sites\n'
# extract_fns <file> <fn>... — the named top-level functions, verbatim.
extract_fns() {
  local f="$1" fn; shift
  for fn in "$@"; do
    awk -v h="${fn}() {" 'index($0, h) == 1 { p = 1 } p { print } p && /^}/ { p = 0 }' "${f}"
  done
}
# run_site <label> <script> <ws> — run that script's two scaffold copies into an empty
# sandbox root and read the two files they create.
run_site() {
  local lbl="$1" script="$2" ws="$3" snip="${SBX}/snip-$1.sh" c
  mkdir -p "${ws}"
  case "${lbl}" in
    install)   extract_fns "${script}" scaffold_needles scaffold_roster > "${snip}" ;;
    setup)     extract_fns "${script}" scaffold_localized_needles scaffold_localized_roster > "${snip}" ;;
    update)    extract_fns "${script}" resolve_instance_dir scaffold_needles scaffold_roster > "${snip}" ;;
  esac
  (
    umask 022
    info() { :; }; warn() { :; }; err() { :; }
    REPO_ROOT="${REPO_ROOT}"; SOURCE_REPO="${REPO_ROOT}"; WORKSPACE_ROOT="${ws}"
    DRY_RUN=0; INSTANCE_DIR=""; ROLLBACK_OPS_FILE="${SBX}/rollback-$1.ops"
    # shellcheck source=../lib-instance-path.sh disable=SC1091
    . "${RESOLVER}"
    # shellcheck disable=SC1090
    . "${snip}"
    case "${lbl}" in
      install) scaffold_needles "${ws}"; scaffold_roster "${ws}" ;;
      setup)   scaffold_localized_needles; scaffold_localized_roster ;;
      update)  scaffold_needles; scaffold_roster ;;
    esac
  ) >/dev/null 2>&1
  c="$(pmo_instance_path_for "${ws}")"
  SITE_S08="$(PMO_INSTANCE_PATH="${c}" pmo_localized_needles)"
  SITE_S09="$(pmo_people_roster_for "${ws}")"
}
# mutate_site <script> <copy> — drop the umask wrapper from every scaffold copy.
mutate_site() {
  python3 - "$1" "$2" <<'PY'
import sys
t = open(sys.argv[1], encoding="utf-8").read()
old = '( umask 077; cp '
print(t.count(old))
open(sys.argv[2], "w", encoding="utf-8").write(t.replace(old, '( cp '))
PY
}
fid=1
for site in install setup update; do
  case "${site}" in
    install) script="${REPO_ROOT}/install.sh" ;;
    setup)   script="${REPO_ROOT}/docs/scripts/setup-workspace.sh" ;;
    update)  script="${REPO_ROOT}/update.sh" ;;
  esac
  run_site "${site}" "${script}" "${SBX}/f-${site}"
  expect_mode "T8024-F${fid}: ${site} scaffolds S-08 at 0600" "${SITE_S08}" 600
  expect_mode "T8024-F${fid}: ${site} scaffolds S-09 at 0600" "${SITE_S09}" 600
  n="$(mutate_site "${script}" "${SBX}/mut-${site}.sh")"
  if [ "${n}" = "2" ]; then
    run_site "${site}" "${SBX}/mut-${site}.sh" "${SBX}/fm-${site}"
    expect_mode "T8024-F${fid} sensitivity: without the wrapper ${site} creates S-08 at 0644" "${SITE_S08}" 644
  else
    report "T8024-F${fid} sensitivity: the mutation anchor is found twice in ${site}" 0 "anchor found ${n} times"
  fi
  fid=$((fid + 1))
done

# =========================================================================== #
# Parts I, U and S — a real install and real updates on a sandbox (Darwin)    #
# =========================================================================== #
if [ "${IS_DARWIN}" -ne 1 ]; then
  printf '\nParts I, U, S. Real install and update\n'
  skip "T8024-I*, T8024-U*, T8024-S1" "setup-workspace.sh is Darwin-only"
else
  printf '\nPart I. A real install on a sandbox copy\n'
  WS="${SBX}/ws"
  SRC="${WS}/pmo-platform"
  CFG="${SBX}/config"
  mkdir -p "${SRC}" "${CFG}" "${SBX}/cowork"
  ( cd "${REPO_ROOT}" && git ls-files -z --cached --others --exclude-standard \
      | while IFS= read -r -d '' f; do [ -e "${f}" ] && printf '%s\0' "${f}"; done \
      | tar --null -T - -cf - ) | ( cd "${SRC}" && tar -xf - )
  git -C "${SRC}" init -q
  git -C "${SRC}" config user.name "Leak Risk Test"
  git -C "${SRC}" config user.email "leak-risk-test@example.com"
  git -C "${SRC}" config commit.gpgsign false
  git -C "${SRC}" add -A
  git -C "${SRC}" commit -q -m "sandbox snapshot" || report "sandbox snapshot commit" 0
  cat > "${CFG}/operator.toml" <<TOML
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
claude_workspace_root = "${WS}"
operator_homedir_path = "${HOME}"
cowork_install_path = "${SBX}/cowork"
pmo_platform_repo_name = "pmo-platform"

[platform]
work_board = "github"
comms_platform = ""
TOML
  chmod 600 "${CFG}/operator.toml"

  # Seeds, after the snapshot commit. Off-policy members, each in its own shape.
  C="$(pmo_instance_path_for "${WS}")"
  mkdir -p "${C}"; chmod 755 "${C}"
  SEEDED=""            # "<row> <path> <seeded-mode>" lines
  add_seed() { seed "$2" "$3"; SEEDED="${SEEDED}$1 $2 $3
"; }
  P08="$(PMO_INSTANCE_PATH="${C}" pmo_localized_needles)"
  P09="$(pmo_people_roster_for "${WS}")"
  for pr in "S-08 ${P08}" "S-09 ${P09}"; do
    row="${pr%% *}"; p="${pr#* }"; d="${p%/*}"; b="${p##*/}"
    add_seed "${row}" "${p}" 644
    add_seed "${row}" "${d}/${b}.bak-x" 644
    add_seed "${row}" "${d}/.${b}" 644
    add_seed "${row}" "${d}/.${b}.bak-x" 644
  done
  B9I="${P09##*/}"
  if [ "${LIB_OK}" -eq 1 ]; then
    P10="$(primary "${WS}" S-10)"; P15="$(primary "${WS}" S-15)"
    P33="$(primary "${WS}" S-33)"; P48="$(primary "${WS}" S-48)"
    add_seed S-10 "${P10}" 644
    add_seed S-10 "${P10%/*}/.${P10##*/}.bak-x" 644
    add_seed S-15 "${P15}" 755
    add_seed S-33 "${P33}" 640
    add_seed S-48 "${P48}" 644
    add_seed S-48 "${P48%/*}/.${P48##*/}" 644
  fi
  TI="${WS}/.backup-pre-update-instance-20260101T000000Z"
  mkdir -p "${TI}/sub"
  seed "${TI}/a" 644; seed "${TI}/sub/b" 755; seed "${TI}/sub/c" 400
  chmod 755 "${TI}" "${TI}/sub"
  IMM="${P09%/*}/${B9I}.bak-immutable"
  seed "${IMM}" 644; chflags uchg "${IMM}"
  plant_near_misses "${WS}" "${C}" "${TI}" "${B9I}"

  # I0 — control: every seed reads its seeded mode before the install.
  i0=1
  while IFS=' ' read -r row p m; do
    [ -n "${row}" ] || continue
    [ "$(mode_of "${p}")" = "${m}" ] || i0=0
  done <<<"${SEEDED}"
  report "T8024-I0 control: before the install every seed reads its seeded mode" \
    "$([ "${i0}" -eq 1 ] && [ "$(mode_of "${TI}")" = 755 ] && echo 1 || echo 0)"

  SETUP="${SRC}/docs/scripts/setup-workspace.sh"
  t0=${SECONDS}
  iout="$("${SETUP}" --source-repo "${SRC}" --workspace-root "${WS}" --config-root "${CFG}" < <(yes "") 2>&1)"
  irc=$?
  printf '  (install: %ss)\n' "$((SECONDS - t0))"
  report "T8024-I1: the install exits 0, with one member it cannot chmod" "$([ "${irc}" -eq 0 ] && echo 1 || echo 0)" \
    "exit ${irc}; tail: $(tail -3 <<<"${iout}" | tr '\n' '|')"
  i1=1; bad=""
  while IFS=' ' read -r row p m; do
    [ -n "${row}" ] || continue
    [ "${row}" = "S-15" ] && continue
    [ "$(mode_of "${p}")" = "600" ] || { i1=0; bad="${bad} ${row}:${p##*/}:$(mode_of "${p}")"; }
  done <<<"${SEEDED}"
  report "T8024-I1: every S-08, S-09, S-10, S-33 and S-48 primary and backup reads 600" "${i1}" "off:${bad}"
  if need_lib "T8024-I2: the S-15 script reads 600 after the install"; then
    expect_mode "T8024-I2: the S-15 script reads 600 after the install" "${P15}" 600
  fi
  report "T8024-I3: a pre-seeded S-40 copy — folders 700, files 600" \
    "$([ "$(off_count "${TI}" d 700)" = 0 ] && [ "$(off_count "${TI}" f 600)" = 0 ] && echo 1 || echo 0)" \
    "off: $(off_count "${TI}" d 700) folders, $(off_count "${TI}" f 600) files"
  i5=1; miss=""
  while IFS=' ' read -r row p m; do
    [ -n "${row}" ] || continue
    has_line "${iout}" "LEAK-RISK-MODE: ${row} ${p} ${m} -> 600" || { i5=0; miss="${miss} ${row}:${p##*/}"; }
  done <<<"${SEEDED}"
  has_line "${iout}" "LEAK-RISK-MODE: S-40 ${TI} " || { i5=0; miss="${miss} S-40"; }
  report "T8024-I5: the install log names each repaired member" "${i5}" "missing:${miss}"
  report "T8024-I5: one summary line" "$([ "$(count_lines "${iout}" '^leak-risk modes: ')" = 1 ] && echo 1 || echo 0)" \
    "$(count_lines "${iout}" '^leak-risk modes: ') summary lines"
  report "T8024-I6: the member it cannot chmod is named on a warning line" \
    "$(has_line "${iout}" "WARN-LEAK-RISK-MODE: S-09 ${IMM}" && echo 1 || echo 0)"
  check_near_misses "after install" "${WS}" "${C}" "${B9I}"

  validate() {
    HOME="${HOME}" PMO_USER_SETTINGS_FILE="${SBX}/no-such-user-settings.json" \
      bash "${SRC}/docs/scripts/validate-install.sh" --mode install --dry-run \
        --source-repo "${SRC}" --workspace-root "${WS}" 2>&1
  }
  vout="$(validate)"
  report "T8024-I7: validate-install A11 FAILs naming the member it could not set" \
    "$(grep -qE "^\[A11\] FAIL .*S-09 ${IMM}" <<<"${vout}" && echo 1 || echo 0)" \
    "A11: $(grep -m1 '^\[A11\]' <<<"${vout}")"

  printf '\nPart U. Real updates and dry runs\n'
  UPDATE="${SRC}/update.sh"
  list_copies() { find -P "${WS}" -maxdepth 1 -type d -name '.backup-pre-update-instance-*' -print 2>/dev/null | sort; }
  chmod 644 "${P09}"
  chmod 644 "${P09%/*}/.${B9I}.bak-x"
  if [ "${LIB_OK}" -eq 1 ]; then chmod 755 "${P15}"; fi
  TU="${WS}/.backup-pre-update-instance-20260103T000000Z"
  seed "${TU}/a" 644; chmod 755 "${TU}"
  copies_before="$(list_copies)"
  t0=${SECONDS}
  uout="$("${UPDATE}" --config-root "${CFG}" --workspace-root "${WS}" 2>&1)"
  urc=$?
  printf '  (update 1: %ss)\n' "$((SECONDS - t0))"
  expect_mode "T8024-U1: S-09 loosened to 0644 reads 600 after a real update" "${P09}" 600
  expect_mode "T8024-U1: its dot-prefixed backup reads 600" "${P09%/*}/.${B9I}.bak-x" 600
  if need_lib "T8024-U1: the S-15 script loosened to 0755 reads 600"; then
    expect_mode "T8024-U1: the S-15 script loosened to 0755 reads 600" "${P15}" 600
  fi
  report "T8024-U1: a new S-40-shaped copy at 0755 is set" \
    "$([ "$(off_count "${TU}" d 700)" = 0 ] && [ "$(off_count "${TU}" f 600)" = 0 ] && echo 1 || echo 0)"
  report "T8024-U1: the update exits 0, not EX_NOCHANGE (exit ${urc})" "$([ "${urc}" -eq 0 ] && echo 1 || echo 0)" \
    "tail: $(tail -3 <<<"${uout}" | tr '\n' '|')"
  report "T8024-U1: with a member it cannot chmod, the update still reaches its hook refresh" \
    "$(has_line "${uout}" "Phase 5c: Refresh security-hook bundle" && echo 1 || echo 0)"
  report "T8024-U1: and names that member on a warning line" \
    "$(has_line "${uout}" "WARN-LEAK-RISK-MODE: S-09 ${IMM}" && echo 1 || echo 0)"
  copies_after="$(list_copies)"
  new_copy="$(comm -13 <(printf '%s\n' "${copies_before}") <(printf '%s\n' "${copies_after}"))"
  report "T8024-U2: the update wrote one S-40 copy" "$([ -n "${new_copy}" ] && [ "$(grep -c . <<<"${new_copy}")" = 1 ] && echo 1 || echo 0)" \
    "new copies: $(tr '\n' ' ' <<<"${new_copy}")"
  if [ -n "${new_copy}" ]; then
    report "T8024-U2: its folders read 700 and its files 600" \
      "$([ "$(off_count "${new_copy}" d 700)" = 0 ] && [ "$(off_count "${new_copy}" f 600)" = 0 ] && echo 1 || echo 0)" \
      "off: $(off_count "${new_copy}" d 700) folders, $(off_count "${new_copy}" f 600) files"
    if need_lib "T8024-U2: the library lists the copy the update wrote"; then
      pop_ws="$(lib_leak_risk_population_for "${WS}")"
      report "T8024-U2: the library lists the copy the update wrote" \
        "$(has_line "${pop_ws}" "S-40	tree	${new_copy}" && echo 1 || echo 0)"
    fi
  fi
  check_near_misses "after update" "${WS}" "${C}" "${B9I}"

  chflags nouchg "${IMM}"; chmod 600 "${IMM}"
  copies_before="$(list_copies)"
  t0=${SECONDS}
  u5out="$("${UPDATE}" --config-root "${CFG}" --workspace-root "${WS}" 2>&1)"
  printf '  (update 2: %ss)\n' "$((SECONDS - t0))"
  copies_after="$(list_copies)"
  report "T8024-U5: a second update writes a fresh S-40 copy" \
    "$([ "$(grep -c . <<<"${copies_after}")" -gt "$(grep -c . <<<"${copies_before}")" ] && echo 1 || echo 0)"
  report "T8024-U5: and its summary reads 0 changed (the copy is created at the policy, uncounted)" \
    "$(has_line "${u5out}" "leak-risk modes: 0 changed" && echo 1 || echo 0)" "$(grep -m1 '^leak-risk modes:' <<<"${u5out}")"

  d3out="$("${UPDATE}" --dry-run --config-root "${CFG}" --workspace-root "${WS}" 2>&1)"; d3rc=$?
  report "T8024-U3: a dry run over a population at the policy reports 0 would change" \
    "$(has_line "${d3out}" "leak-risk modes: 0 would change" && echo 1 || echo 0)" "$(grep -m1 '^leak-risk modes:' <<<"${d3out}")"
  chmod 644 "${P09}"
  d4out="$("${UPDATE}" --dry-run --config-root "${CFG}" --workspace-root "${WS}" 2>&1)"; d4rc=$?
  report "T8024-U4: a dry run names S-09 on a would-set line" \
    "$(has_line "${d4out}" "[dry-run] LEAK-RISK-MODE: S-09 ${P09} 644 -> 600" && echo 1 || echo 0)"
  report "T8024-U4: its summary reads 1 would change" "$(has_line "${d4out}" "leak-risk modes: 1 would change" && echo 1 || echo 0)" \
    "$(grep -m1 '^leak-risk modes:' <<<"${d4out}")"
  expect_mode "T8024-U4: and S-09 still reads 644 after the dry run" "${P09}" 644
  if [ "${d3rc}" -eq 64 ]; then
    report "T8024-U4b: the would-change alone turns the dry run's exit from 64 to 0" \
      "$([ "${d4rc}" -eq 0 ] && echo 1 || echo 0)" "baseline ${d3rc}, with S-09 at 0644 ${d4rc}"
  else
    skip "T8024-U4b" "baseline dry-run exit was ${d3rc}, not 64; the EX_NOCHANGE term is not isolable here"
  fi

  printf '\nPart S. --surfaces-only runs no mode pass\n'
  copies_before="$(list_copies)"
  sout="$("${UPDATE}" --surfaces-only --config-root "${CFG}" --workspace-root "${WS}" 2>&1)"
  copies_after="$(list_copies)"
  expect_mode "T8024-S1: --surfaces-only leaves S-09 at 0644" "${P09}" 644
  report "T8024-S1: and prints no leak-risk summary or change line" \
    "$([ "$(count_lines "${sout}" '^leak-risk modes: |^LEAK-RISK-MODE: ')" = 0 ] && echo 1 || echo 0)"
  s_copy="$(comm -13 <(printf '%s\n' "${copies_before}") <(printf '%s\n' "${copies_after}"))"
  report "T8024-S1: its S-40 copy is still created at the policy" \
    "$([ -n "${s_copy}" ] && [ "$(off_count "${s_copy}" d 700)" = 0 ] && [ "$(off_count "${s_copy}" f 600)" = 0 ] && echo 1 || echo 0)" \
    "copy: ${s_copy:-none}"

  chmod 600 "${P09}"
  vout="$(validate)"
  report "T8024-I8: validate-install A11 PASSes once every member is at the policy" \
    "$(grep -qE '^\[A11\] PASS' <<<"${vout}" && echo 1 || echo 0)" "A11: $(grep -m1 '^\[A11\]' <<<"${vout}")"
fi

# =========================================================================== #
# Part P — opt-in: the pass timed on a copy-sized tree (FM-3)                 #
# =========================================================================== #
if [ -n "${T8024_MEASURE_FILES:-}" ]; then
  printf '\nPart P. The pass timed on a tree of %s files\n' "${T8024_MEASURE_FILES}"
  if need_lib "T8024-P1: the pass on a copy-sized tree"; then
    wsp="${SBX}/p-ws"
    tp="${wsp}/.backup-pre-update-instance-20260104T000000Z"
    python3 - "${tp}" "${T8024_MEASURE_FILES}" <<'PY'
import os, sys
root, n = sys.argv[1], int(sys.argv[2])
per = 6   # the live copy holds about 6.4 files per folder
os.makedirs(root, exist_ok=True)
d = root
for i in range(n):
    if i % per == 0:
        d = os.path.join(root, "d%03d" % (i // 1000), "f%06d" % i)
        os.makedirs(d, exist_ok=True)
        os.chmod(d, 0o755)
    p = os.path.join(d, "x%d" % i)
    with open(p, "w") as fh:
        fh.write("x")
    os.chmod(p, 0o644)
PY
    now() { python3 -c 'import time; print("%.1f" % time.time())'; }
    ta="$(now)"; lib_leak_risk_findings_for "${wsp}" >/dev/null 2>&1; tb="$(now)"
    lib_leak_risk_enforce_for "${wsp}" 0 >/dev/null 2>&1; tc="$(now)"
    lib_leak_risk_findings_for "${wsp}" >/dev/null 2>&1; td="$(now)"
    nfiles="$(find -P "${tp}" -type f | wc -l)"; nfold="$(find -P "${tp}" -type d | wc -l)"
    printf '  measured: %s files, %s folders; findings %ss; enforce %ss; findings after %ss\n' \
      "${nfiles//[!0-9]/}" "${nfold//[!0-9]/}" \
      "$(python3 -c "print('%.1f' % (${tb} - ${ta}))")" "$(python3 -c "print('%.1f' % (${tc} - ${tb}))")" \
      "$(python3 -c "print('%.1f' % (${td} - ${tc}))")"
    report "T8024-P1: the copy-sized tree ends at the policy" "$([ "${LIB_LEAK_RISK_FINDINGS:-x}" = 0 ] && echo 1 || echo 0)"
  fi
fi

printf '\ntest_leak_risk_modes: %d passed, %d failed, %d skipped (bash %s)\n' \
  "${PASS}" "${FAIL}" "${SKIP}" "${BASH_VERSION:-unknown}"
[ "${FAIL}" -eq 0 ] || exit 1
exit 0

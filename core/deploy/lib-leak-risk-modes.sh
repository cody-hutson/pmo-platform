#!/usr/bin/env bash
# lib-leak-risk-modes.sh — one permission policy for leak-risk files: the population, the
# setter the installer and a full update run, and the read-only findings the install
# validator reports (check A11).
#
# THE POLICY. Mode 0600 on each leak-risk file and 0700 on each leak-risk folder, backups
# included. Its authority is the Leak-risk row of § Protections in
# core/standards/instance-data-placement-standard.md; this file holds the two numbers that
# row states, and nothing else. The setter is exact. The validator FAILs a member that has
# any group or other permission bit, and reports any other departure from the exact mode
# (a 0400 file, for instance) as information, because it discloses nothing.
#
# THE POPULATION. Every row of that standard's § Surface register whose Class cell reads
# `Leak-risk`, each either resolved here to the path the install path gives it today, or
# declared deferred with its reason (lib_leak_risk_rows). The suite
# core/deploy/tests/test_leak_risk_modes.sh holds the two sets equal (arm T8024-L0), so a
# Leak-risk row added to the register with no entry here fails that suite.
#
#   Row   Member                       Resolved through
#   S-08  PII scan list                pmo_localized_needles, keyed on the passed root
#   S-09  people roster                pmo_people_roster_for
#   S-10  roster clarification queue   pmo_instance_path_for + the queue template's leaf
#   S-15  the scan script              pmo_instance_path_for + the register row's leaf
#   S-33  project-key scan list        PMO_PROJECT_KEYS, else pmo_instance_path_for + deploy.sh's leaf
#   S-48  the scan script's needles    pmo_instance_path_for + the .gitignore scan-list leaf
#   S-40  pre-update container copies  <workspace-root>/.backup-pre-update-instance-*, as update.sh writes them
#   S-19, S-46                         deferred; lib_leak_risk_rows says why
#
# Each file row also covers its backups: a regular file in the primary's folder whose
# name, with at most one leading dot removed, is the primary's name or begins with it
# followed by a dot. An S-40 copy is a tree: every folder in it and every file in it.
# Symbolic links are never followed and never members, so the pass cannot change a file
# outside the population. Today's container itself is never a member: it holds working
# state beside leak-risk files, and the policy belongs to the leak-risk home, which the
# installer milestone provisions.
#
# NO RESOLVER FUNCTION. Every path above is an existing accessor in lib-instance-path.sh
# plus a leaf that the register, a template, deploy.sh or .gitignore already names. This
# file adds no path token, no writer of content and no folder, and it never reads a file's
# contents: it reads modes (stat, find -perm) and sets them (chmod).
#
# REPOINT TARGETS. Six literals here are composed outside the resolver, because the
# one-resolver release owns lib-instance-path.sh. When that release gives the leak-risk
# class its resolver, each is replaced by a call to it:
#   1. S-10's leaf, which today only the clarification-queue template's prose spells;
#   2. S-15's leaf;
#   3. S-33's leaf, which deploy.sh's DC3 pass also spells;
#   4. S-48's leaf, which .gitignore's scan-list lines also spell;
#   5. the backup-name predicate (_lib_leak_risk_is_backup_name);
#   6. the S-40 folder pattern, which mirrors update.sh's backup_instance_dir.
#
# THE RETURN-CODE CONTRACT. Every public function returns 0, whatever it finds and
# whatever a find or a chmod does, so a caller under `set -Eeuo pipefail` is never stopped
# by it. A failure is a counter and a WARN-LEAK-RISK-MODE: line on stderr, never a return
# code. "Changed" is read from the post-state: a member counts as changed only when a
# re-read after the chmod shows fewer entries off the policy than before it, and a member
# still off the policy after the pass counts as failed. A chmod that returns 0 and changes
# nothing therefore counts as a failure, never as a change. A partly repaired S-40 copy
# counts as both.
#
# Public functions:
#   lib_leak_risk_rows                           one line per Leak-risk row: <row> resolved,
#                                                or <row> deferred <reason> (tab-separated)
#   lib_leak_risk_primary_for <ws> <row>         a file row's primary path, present or not
#   lib_leak_risk_population_for <ws>            <row> <file|tree> <path>, members present only
#   lib_leak_risk_enforce_for <ws> <dry-run 0|1> set the policy; prints LEAK-RISK-MODE: lines
#                                                and one summary line; sets LIB_LEAK_RISK_CHANGED,
#                                                _AT_POLICY, _FAILED, _PRESENT
#   lib_leak_risk_normalize_tree <dir>           set the policy on one tree, silently; sets
#                                                LIB_LEAK_RISK_NORMALIZED, _NORMALIZE_FAILED
#   lib_leak_risk_findings_for <ws>              read-only; prints <FAIL|INFO> <row> <path>
#                                                <observed> <wanted>; sets LIB_LEAK_RISK_FINDINGS,
#                                                _INFOS, _PRESENT, _FILES, _FOLDERS,
#                                                _ROWS_PRESENT, _ABSENT_ROWS and _REPORT
#
# Sourceable and idempotent; bash 3.2; never calls exit; no pipeline into a reader that
# stops early. A file name holding a newline is counted once per line it spans by the tree
# counts; the counts are diagnostics, and the verdict reads zero against non-zero.

LIB_LEAK_RISK_FILE_MODE=600
LIB_LEAK_RISK_DIR_MODE=700
LIB_LEAK_RISK_FILE_ROWS="S-08 S-09 S-10 S-15 S-33 S-48"

LIB_LEAK_RISK_CHANGED=0
LIB_LEAK_RISK_AT_POLICY=0
LIB_LEAK_RISK_FAILED=0
LIB_LEAK_RISK_PRESENT=0
LIB_LEAK_RISK_NORMALIZED=0
LIB_LEAK_RISK_NORMALIZE_FAILED=0
LIB_LEAK_RISK_FINDINGS=0
LIB_LEAK_RISK_INFOS=0
LIB_LEAK_RISK_FILES=0
LIB_LEAK_RISK_FOLDERS=0
LIB_LEAK_RISK_ROWS_PRESENT=""
LIB_LEAK_RISK_ABSENT_ROWS=""
LIB_LEAK_RISK_REPORT=""

# The instance resolver, from this file's own folder when the caller has not loaded it.
_lib_leak_risk_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || _lib_leak_risk_dir=""
if ! command -v pmo_instance_path_for >/dev/null 2>&1; then
  if [ -n "${_lib_leak_risk_dir}" ] && [ -r "${_lib_leak_risk_dir}/lib-instance-path.sh" ]; then
    # shellcheck source=lib-instance-path.sh disable=SC1091
    . "${_lib_leak_risk_dir}/lib-instance-path.sh" || true
  fi
fi

# Mode reads: GNU stat takes -c '%a', BSD stat takes -f '%Lp'. Decided once, by asking.
_lib_leak_risk_stat_style="bsd"
case "$(stat -c '%a' / 2>/dev/null || true)" in
  ''|*[!0-7]*) _lib_leak_risk_stat_style="bsd" ;;
  *) _lib_leak_risk_stat_style="gnu" ;;
esac

_lib_leak_risk_mode() {
  local m=""
  if [ "${_lib_leak_risk_stat_style}" = "gnu" ]; then
    m="$(stat -c '%a' "$1" 2>/dev/null || true)"
  else
    m="$(stat -f '%Lp' "$1" 2>/dev/null || true)"
  fi
  case "${m}" in ''|*[!0-7]*) m="unreadable" ;; esac
  printf '%s\n' "${m}"
}

# 0 when the mode string carries a group or other bit, or cannot be read (fail closed).
_lib_leak_risk_has_go_bit() {
  case "$1" in ''|*[!0-7]*) return 0 ;; esac
  [ $(( 8#$1 & 8#077 )) -ne 0 ]
}

# _lib_leak_risk_count <dir> <f|d> <off|go|all> — entries of one type under a tree.
#   off  mode not exactly the policy's    go  any group or other bit    all  every entry
_lib_leak_risk_count() {
  local dir="$1" type="$2" want n=""
  if [ "${type}" = "d" ]; then want="${LIB_LEAK_RISK_DIR_MODE}"; else want="${LIB_LEAK_RISK_FILE_MODE}"; fi
  case "$3" in
    off) n="$({ find -P "${dir}" -type "${type}" ! -perm "${want}" -print 2>/dev/null || true; } | wc -l)" ;;
    go)  n="$({ find -P "${dir}" -type "${type}" \( -perm -040 -o -perm -020 -o -perm -010 \
                 -o -perm -004 -o -perm -002 -o -perm -001 \) -print 2>/dev/null || true; } | wc -l)" ;;
    all) n="$({ find -P "${dir}" -type "${type}" -print 2>/dev/null || true; } | wc -l)" ;;
  esac
  n="${n//[!0-9]/}"
  printf '%s\n' "${n:-0}"
}

# _lib_leak_risk_set_tree <dir> — folders first, so each is readable before its files are
# read: one batched pass, then a pre-order pass that sets each folder still off the policy
# before descending into it, which opens a chain of unreadable folders in one run. Then
# the files, batched.
_lib_leak_risk_set_tree() {
  local dir="$1"
  { find -P "${dir}" -type d ! -perm "${LIB_LEAK_RISK_DIR_MODE}" -exec chmod "${LIB_LEAK_RISK_DIR_MODE}" {} + 2>/dev/null || true; }
  { find -P "${dir}" -type d ! -perm "${LIB_LEAK_RISK_DIR_MODE}" -exec chmod "${LIB_LEAK_RISK_DIR_MODE}" {} \; 2>/dev/null || true; }
  { find -P "${dir}" -type f ! -perm "${LIB_LEAK_RISK_FILE_MODE}" -exec chmod "${LIB_LEAK_RISK_FILE_MODE}" {} + 2>/dev/null || true; }
  return 0
}

# A backup's name, with at most one leading dot removed, is the primary's name or begins
# with it followed by a dot: <name>.bak-x, .<name> and .<name>.bak-x are the forms found.
_lib_leak_risk_is_backup_name() {
  local name="$1" base="$2" n
  if [ "${name}" = "${base}" ]; then return 1; fi
  n="${name#.}"
  if [ "${n}" = "${base}" ]; then return 0; fi
  case "${n}" in "${base}".*) return 0 ;; esac
  return 1
}

lib_leak_risk_rows() {
  printf 'S-08\tresolved\n'
  printf 'S-09\tresolved\n'
  printf 'S-10\tresolved\n'
  printf 'S-15\tresolved\n'
  printf 'S-19\tdeferred\t%s\n' "no install-time path: a run's class is known only once the resolver takes it as an argument (the resolver milestone, then the migration milestone)"
  printf 'S-33\tresolved\n'
  printf 'S-40\tresolved\n'
  printf 'S-46\tdeferred\t%s\n' "no path token: it lives in the leak-risk home, which nothing resolves until the installer milestone provisions it"
  printf 'S-48\tresolved\n'
  return 0
}

lib_leak_risk_primary_for() {
  local ws="${1:-}" row="${2:-}" c=""
  [ -n "${ws}" ] || return 0
  command -v pmo_instance_path_for >/dev/null 2>&1 || return 0
  c="$(pmo_instance_path_for "${ws}" 2>/dev/null || true)"
  [ -n "${c}" ] || return 0
  case "${row}" in
    S-08) printf '%s\n' "$(PMO_INSTANCE_PATH="${c}" pmo_localized_needles 2>/dev/null || true)" ;;
    S-09) printf '%s\n' "$(pmo_people_roster_for "${ws}" 2>/dev/null || true)" ;;
    S-10) printf '%s/%s\n' "${c}" "people-graph-clarification-queue.md" ;;
    S-15) printf '%s/%s\n' "${c}" "scan.sh" ;;
    S-33) printf '%s\n' "${PMO_PROJECT_KEYS:-${c}/project-keys.txt}" ;;
    S-48) printf '%s/%s\n' "${c}" "flip-scan-needles.txt" ;;
  esac
  return 0
}

lib_leak_risk_population_for() {
  local ws="${1:-}" row p dir base entry name
  [ -n "${ws}" ] || return 0
  for row in ${LIB_LEAK_RISK_FILE_ROWS}; do
    p="$(lib_leak_risk_primary_for "${ws}" "${row}")"
    case "${p}" in */*) ;; *) continue ;; esac
    if [ -f "${p}" ] && [ ! -L "${p}" ]; then printf '%s\tfile\t%s\n' "${row}" "${p}"; fi
    dir="${p%/*}"; base="${p##*/}"
    [ -n "${dir}" ] || dir="/"
    [ -d "${dir}" ] || continue
    for entry in "${dir}"/* "${dir}"/.*; do
      if [ ! -f "${entry}" ] || [ -L "${entry}" ]; then continue; fi
      name="${entry##*/}"
      if _lib_leak_risk_is_backup_name "${name}" "${base}"; then
        printf '%s\tfile\t%s\n' "${row}" "${entry}"
      fi
    done
  done
  if [ -d "${ws}" ]; then
    for entry in "${ws}"/.backup-pre-update-instance-*; do
      if [ ! -d "${entry}" ] || [ -L "${entry}" ]; then continue; fi
      printf 'S-40\ttree\t%s\n' "${entry}"
    done
  fi
  return 0
}

# _lib_leak_risk_absent_rows <present-rows> — the resolved rows with no member present.
_lib_leak_risk_absent_rows() {
  local present=" ${1:-} " row kind rest out=""
  while IFS="$(printf '\t')" read -r row kind rest; do
    if [ -z "${row}" ] || [ "${kind}" != "resolved" ]; then continue; fi
    case "${present}" in *" ${row} "*) ;; *) out="${out}${out:+ }${row}" ;; esac
  done <<EOF
$(lib_leak_risk_rows)
EOF
  printf '%s\n' "${out:-none}"
  return 0
}
# _lib_leak_risk_deferred_rows — the rows declared deferred.
_lib_leak_risk_deferred_rows() {
  local row kind rest out=""
  while IFS="$(printf '\t')" read -r row kind rest; do
    if [ "${kind}" = "deferred" ]; then out="${out}${out:+ }${row}"; fi
  done <<EOF
$(lib_leak_risk_rows)
EOF
  printf '%s\n' "${out:-none}"
  return 0
}
# _lib_leak_risk_report_line <line> — print one finding and keep it in LIB_LEAK_RISK_REPORT.
_lib_leak_risk_report_line() {
  printf '%s\n' "$1"
  LIB_LEAK_RISK_REPORT="${LIB_LEAK_RISK_REPORT}$1
"
  return 0
}

lib_leak_risk_enforce_for() {
  local ws="${1:-}" dry="${2:-0}" pop row kind path old new nf nd nf2 nd2 before after rows=""
  local tab; tab="$(printf '\t')"
  LIB_LEAK_RISK_CHANGED=0; LIB_LEAK_RISK_AT_POLICY=0; LIB_LEAK_RISK_FAILED=0; LIB_LEAK_RISK_PRESENT=0
  pop="$(lib_leak_risk_population_for "${ws}")"
  while IFS="${tab}" read -r row kind path; do
    [ -n "${row}" ] || continue
    LIB_LEAK_RISK_PRESENT=$((LIB_LEAK_RISK_PRESENT + 1))
    case " ${rows} " in *" ${row} "*) ;; *) rows="${rows}${rows:+ }${row}" ;; esac
    if [ "${kind}" = "file" ]; then
      old="$(_lib_leak_risk_mode "${path}")"
      if [ "${old}" = "${LIB_LEAK_RISK_FILE_MODE}" ]; then
        LIB_LEAK_RISK_AT_POLICY=$((LIB_LEAK_RISK_AT_POLICY + 1)); continue
      fi
      if [ "${dry}" = "1" ]; then
        printf '[dry-run] LEAK-RISK-MODE: %s %s %s -> %s\n' "${row}" "${path}" "${old}" "${LIB_LEAK_RISK_FILE_MODE}"
        LIB_LEAK_RISK_CHANGED=$((LIB_LEAK_RISK_CHANGED + 1)); continue
      fi
      chmod "${LIB_LEAK_RISK_FILE_MODE}" "${path}" 2>/dev/null || true
      new="$(_lib_leak_risk_mode "${path}")"
      if [ "${new}" = "${LIB_LEAK_RISK_FILE_MODE}" ]; then
        printf 'LEAK-RISK-MODE: %s %s %s -> %s\n' "${row}" "${path}" "${old}" "${new}"
        LIB_LEAK_RISK_CHANGED=$((LIB_LEAK_RISK_CHANGED + 1))
      else
        printf 'WARN-LEAK-RISK-MODE: %s %s reads %s; could not set %s (continuing)\n' \
          "${row}" "${path}" "${new}" "${LIB_LEAK_RISK_FILE_MODE}" >&2
        LIB_LEAK_RISK_FAILED=$((LIB_LEAK_RISK_FAILED + 1))
      fi
    else
      nf="$(_lib_leak_risk_count "${path}" f off)"; nd="$(_lib_leak_risk_count "${path}" d off)"
      before=$((nf + nd))
      if [ "${before}" -eq 0 ]; then
        LIB_LEAK_RISK_AT_POLICY=$((LIB_LEAK_RISK_AT_POLICY + 1)); continue
      fi
      if [ "${dry}" = "1" ]; then
        printf '[dry-run] LEAK-RISK-MODE: %s %s %s files -> %s, %s folders -> %s\n' \
          "${row}" "${path}" "${nf}" "${LIB_LEAK_RISK_FILE_MODE}" "${nd}" "${LIB_LEAK_RISK_DIR_MODE}"
        LIB_LEAK_RISK_CHANGED=$((LIB_LEAK_RISK_CHANGED + 1)); continue
      fi
      _lib_leak_risk_set_tree "${path}"
      nf2="$(_lib_leak_risk_count "${path}" f off)"; nd2="$(_lib_leak_risk_count "${path}" d off)"
      after=$((nf2 + nd2))
      if [ "${after}" -lt "${before}" ]; then
        printf 'LEAK-RISK-MODE: %s %s %s files -> %s, %s folders -> %s\n' "${row}" "${path}" \
          "$(( nf > nf2 ? nf - nf2 : 0 ))" "${LIB_LEAK_RISK_FILE_MODE}" \
          "$(( nd > nd2 ? nd - nd2 : 0 ))" "${LIB_LEAK_RISK_DIR_MODE}"
        LIB_LEAK_RISK_CHANGED=$((LIB_LEAK_RISK_CHANGED + 1))
      fi
      if [ "${after}" -gt 0 ]; then
        printf 'WARN-LEAK-RISK-MODE: %s %s: %s files and %s folders still off the policy (continuing)\n' \
          "${row}" "${path}" "${nf2}" "${nd2}" >&2
        LIB_LEAK_RISK_FAILED=$((LIB_LEAK_RISK_FAILED + 1))
      fi
    fi
  done <<EOF
${pop}
EOF
  printf 'leak-risk modes: %s %s, %s at policy, %s failed (present %s; rows absent: %s; rows deferred: %s)\n' \
    "${LIB_LEAK_RISK_CHANGED}" "$([ "${dry}" = "1" ] && printf 'would change' || printf 'changed')" \
    "${LIB_LEAK_RISK_AT_POLICY}" "${LIB_LEAK_RISK_FAILED}" "${LIB_LEAK_RISK_PRESENT}" \
    "$(_lib_leak_risk_absent_rows "${rows}")" "$(_lib_leak_risk_deferred_rows)"
  return 0
}

lib_leak_risk_normalize_tree() {
  local dir="${1:-}" before after
  LIB_LEAK_RISK_NORMALIZED=0; LIB_LEAK_RISK_NORMALIZE_FAILED=0
  if [ -z "${dir}" ] || [ ! -d "${dir}" ] || [ -L "${dir}" ]; then return 0; fi
  before=$(( $(_lib_leak_risk_count "${dir}" f off) + $(_lib_leak_risk_count "${dir}" d off) ))
  [ "${before}" -gt 0 ] || return 0
  _lib_leak_risk_set_tree "${dir}"
  after=$(( $(_lib_leak_risk_count "${dir}" f off) + $(_lib_leak_risk_count "${dir}" d off) ))
  if [ "${after}" -lt "${before}" ]; then LIB_LEAK_RISK_NORMALIZED=$((before - after)); fi
  LIB_LEAK_RISK_NORMALIZE_FAILED="${after}"
  return 0
}

lib_leak_risk_findings_for() {
  local ws="${1:-}" pop row kind path m gof god off rows=""
  local tab; tab="$(printf '\t')"
  LIB_LEAK_RISK_FINDINGS=0; LIB_LEAK_RISK_INFOS=0; LIB_LEAK_RISK_PRESENT=0
  LIB_LEAK_RISK_FILES=0; LIB_LEAK_RISK_FOLDERS=0; LIB_LEAK_RISK_REPORT=""
  pop="$(lib_leak_risk_population_for "${ws}")"
  while IFS="${tab}" read -r row kind path; do
    [ -n "${row}" ] || continue
    LIB_LEAK_RISK_PRESENT=$((LIB_LEAK_RISK_PRESENT + 1))
    case " ${rows} " in *" ${row} "*) ;; *) rows="${rows}${rows:+ }${row}" ;; esac
    if [ "${kind}" = "file" ]; then
      LIB_LEAK_RISK_FILES=$((LIB_LEAK_RISK_FILES + 1))
      m="$(_lib_leak_risk_mode "${path}")"
      if [ "${m}" = "${LIB_LEAK_RISK_FILE_MODE}" ]; then continue; fi
      if _lib_leak_risk_has_go_bit "${m}"; then
        _lib_leak_risk_report_line "FAIL${tab}${row}${tab}${path}${tab}${m}${tab}${LIB_LEAK_RISK_FILE_MODE}"
        LIB_LEAK_RISK_FINDINGS=$((LIB_LEAK_RISK_FINDINGS + 1))
      else
        _lib_leak_risk_report_line "INFO${tab}${row}${tab}${path}${tab}${m}${tab}${LIB_LEAK_RISK_FILE_MODE}"
        LIB_LEAK_RISK_INFOS=$((LIB_LEAK_RISK_INFOS + 1))
      fi
    else
      LIB_LEAK_RISK_FILES=$((LIB_LEAK_RISK_FILES + $(_lib_leak_risk_count "${path}" f all)))
      LIB_LEAK_RISK_FOLDERS=$((LIB_LEAK_RISK_FOLDERS + $(_lib_leak_risk_count "${path}" d all)))
      gof="$(_lib_leak_risk_count "${path}" f go)"; god="$(_lib_leak_risk_count "${path}" d go)"
      off=$(( $(_lib_leak_risk_count "${path}" f off) + $(_lib_leak_risk_count "${path}" d off) ))
      if [ $((gof + god)) -gt 0 ]; then
        _lib_leak_risk_report_line "FAIL${tab}${row}${tab}${path}${tab}${gof} files and ${god} folders with a group or other bit${tab}${LIB_LEAK_RISK_FILE_MODE}/${LIB_LEAK_RISK_DIR_MODE}"
        LIB_LEAK_RISK_FINDINGS=$((LIB_LEAK_RISK_FINDINGS + 1))
      fi
      if [ $((off - gof - god)) -gt 0 ]; then
        _lib_leak_risk_report_line "INFO${tab}${row}${tab}${path}${tab}$((off - gof - god)) entries owner-only but not exact${tab}${LIB_LEAK_RISK_FILE_MODE}/${LIB_LEAK_RISK_DIR_MODE}"
        LIB_LEAK_RISK_INFOS=$((LIB_LEAK_RISK_INFOS + 1))
      fi
    fi
  done <<EOF
${pop}
EOF
  LIB_LEAK_RISK_ROWS_PRESENT="${rows}"
  LIB_LEAK_RISK_ABSENT_ROWS="$(_lib_leak_risk_absent_rows "${rows}")"
  return 0
}

#!/usr/bin/env bash
# test_deploy_path_literals.sh — standing assertion that every REQUIRED path
# literal in core/deploy/deploy.sh resolves on disk (#4217).
#
# WHY A STANDING ASSERTION AND NOT A MOVE DETECTOR. Every move-triggered control
# the platform owns — the structural blast-radius mode, the rename-cascade
# controls, the doc-link resolvers — keys on something MOVING. The literals this
# test guards did not move: they were WRONG AT BIRTH, entering the file at the
# root commit with their current value and never being added, deleted or renamed
# afterwards. There is nothing for a move detector to key on. The only control
# that catches a born-wrong path is one that RESOLVES the literal and asserts the
# result, and its trigger is every run rather than every move. That is this file.
#
# PROVENANCE. This generalizes an existing point assertion rather than inventing a
# mechanism: test_check19_event_log_integrity.sh T5 is described in its own header
# as a "STANDING LITERAL ASSERTION — the c19_schema literal, extracted from
# deploy.sh itself, points at a file that exists." T5 asserts one literal; this
# file asserts the whole required class, using the same directory, the same
# report()/exit contract, and the same no-deploy-run cost profile.
#
# THE PREDICATE IS THE DELIVERABLE, NOT THE ASSERTION. A naive "every quoted path
# resolves" rule emits findings that are overwhelmingly false — prose spans,
# runtime-constructed paths, globs, commented placeholders, compound records, and
# literals rooted at git-ignored trees — and a gate that emits false findings gets
# muted within a release. A REQUIRED path literal is therefore defined by five
# clauses, four structural plus one marker:
#
#   P1  Repo-relative and rooted at a top-level directory that has at least one
#       TRACKED member, DERIVED LIVE from `git ls-files` and never hardcoded. A
#       tracked root is committed, so it resolves in every checkout. This is what
#       puts the git-ignored Layer-2 trees (projects/) and a deliberately-empty
#       tree (harness/) out of class, and deriving it live means the exclusion
#       cannot rot when a module is added or removed.
#   P2  No shell expansion ($ or backtick) and no glob metacharacter (* ? [). A
#       constructed or globbed path is resolved at runtime against state the
#       source cannot see.
#   P3  Not inside a comment, and carrying no angle-bracket placeholder. The
#       angle-bracket clause is transcribed from the shipped is_internal() skip
#       class in check-doc-links.py: < and > are not valid in committed paths.
#   P4  Field-split on the ||| record separator BEFORE testing. deploy.sh carries
#       multi-field tracker records whose PATH fields resolve; a whole-span test
#       reports those as false findings.
#   P5  Not suppressed by a line-scoped, reason-bearing marker:
#         deploy-path-literal: allow — <reason>
#       Reason MANDATORY. A bare `allow`, and one whose reason is whitespace-only,
#       do NOT suppress. Marked sites are COUNTED AND REPORTED, never silently
#       dropped, so a suppression stays auditable. There is deliberately no
#       file-scoped tier: a whole-file suppressor in an 18k-line file would let
#       one intentional site silence an unconverted sibling. The form transcribes
#       the two shipped per-line reason-bearing markers (`sigpipe-idiom: allow —`
#       and `event-log-key: allow —`), including their separator rule.
#
# A path-shaped literal is one that contains a "/" and no whitespace. A quoted
# span carrying whitespace is prose or a compound command, not a path literal, so
# it never enters the population; that is an EXTRACTION rule, distinct from the
# four structural exclusions above, and the denominator reports them separately.
#
# ONE CLASSIFIER, SHARED. PL_AWK plus pl_scan() are defined ONCE and used by the
# live arm AND every fixture arm, so no arm can pass against a copy that has
# drifted from the body that ships. This is the discipline check-convention.sh
# already applies to its own EL_AWK classifier.
#
# DENOMINATOR REPORTING IS MANDATORY on every run, so "zero findings" is never
# confused with "nothing examined", and PL-7 gives that reporting teeth: a scan
# that extracts zero literals, or derives zero tracked roots, is a SCAN-SURFACE
# ERROR (exit 3), never a clean pass.
#
# Read-only. Fixtures live in a mktemp -d sandbox; the repo is never mutated.
#
# Run from repo root:
#   bash core/deploy/tests/test_deploy_path_literals.sh
#
# RUNTIME: sub-second. It runs no deploy.
#
# EXIT CONTRACT
#   0  every arm passed and the live arm found no unmarked non-resolving literal
#   1  an arm failed (including the live arm finding a non-resolving literal)
#   3  scan-surface error — the live scan extracted zero literals or derived zero
#      tracked roots, so it measured nothing and must not read green

set -uo pipefail
export LC_ALL=C

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      printf 'usage: %s\n' "$(basename "$0")"
      printf '  (no args)  full suite — PL-1..PL-8; sub-second, runs no deploy\n'
      exit 0
      ;;
    *)
      printf 'FATAL: unrecognized argument: %s\n' "$1" >&2
      printf 'usage: %s\n' "$(basename "$0")" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TARGET="${REPO_ROOT}/core/deploy/deploy.sh"

PASS=0
FAIL=0
SBX=""
ARMS_RUN=""

cleanup() { [ -n "${SBX}" ] && [ -d "${SBX}" ] && rm -rf "${SBX}"; }
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '        %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

# ARMS_RUN records which arms actually EXECUTED, so the terminal ARM REACH block
# asserts reachedness instead of inferring it from the PASS tally. An arm that
# silently stopped running takes its own PASS lines away with it and leaves a
# smaller, wholly green count — which is the very "passes without reaching its
# subject" failure this suite exists to make non-recurrable.
mark_arm() { ARMS_RUN="${ARMS_RUN}$1 "; }

# ─────────────────────────────────────────────────────────────────────────────
# PL_AWK — the classifier. Defined ONCE; shared by the live arm and every fixture
# arm. Emits one record per required-candidate plus a trailing denominator record.
#
#   C  <file> <line> <marked> <literal>
#   @@ <files> <literals> <x-root> <x-expansion> <x-glob> <x-placeholder>
#
# Resolution is NOT done here — awk cannot test a file — so pl_scan() below
# performs it against the caller-supplied scan root. Everything upstream of
# resolution (extraction, P1-P4, the P5 marker read) lives in this one body.
#
# POSIX-portable by construction: no gawk extensions, no PCRE. The ||| split uses
# the DOUBLE-BACKSLASH separator form; a single-backslash form yields an empty
# field count under BSD awk, which deploy.sh already records as measured.
#
# NOTE: this string is single-quoted shell. Do not write an apostrophe anywhere in
# it — it terminates the quote and breaks the parse.
# ─────────────────────────────────────────────────────────────────────────────
PL_AWK='
function is_ws(c) { return (c == " " || c == "\t") }
function first_seg(p,   i) { i = index(p, "/"); return (i > 0 ? substr(p, 1, i - 1) : p) }

# emit_field — one ||| field, already split. Applies the extraction rule and P1-P3.
function emit_field(f, marked,   seg) {
  gsub(/^[ \t]+/, "", f); gsub(/[ \t]+$/, "", f)
  if (f == "")            return
  if (index(f, "/") == 0) return          # not path-shaped: no separator
  if (f ~ /[ \t]/)        return          # not path-shaped: prose or a command
  LIT++
  seg = first_seg(f)
  # P1 — the root must carry at least one tracked member. ROOTS arrives already
  # space-padded from a live git ls-files read; a hardcoded list is what the
  # PL-4 arm exists to catch.
  if (index(ROOTS, " " seg " ") == 0) { XROOT++; return }
  # P2 — runtime-constructed or globbed paths are out of class.
  if (f ~ /[$`]/)                     { XEXP++;  return }
  if (f ~ /[*?[]/)                    { XGLOB++; return }
  # P3 (second limb) — angle-bracket placeholder; < and > cannot occur in a
  # committed path. The first limb, the comment boundary, is applied by the
  # scanner below, which stops at an unquoted word-initial hash.
  if (f ~ /[<>]/)                     { XPH++;   return }
  printf "C\t%s\t%d\t%d\t%s\n", FILENAME, FNR, marked, f
}

# P4 — split on the literal ||| BEFORE testing, so a compound record is graded
# field by field rather than as one span.
function split_record(s, marked,   n, parts, i) {
  n = split(s, parts, "\\|\\|\\|")
  for (i = 1; i <= n; i++) emit_field(parts[i], marked)
}

FNR == 1 { FILES++ }
{
  line = $0
  # P5 — read the marker off the RAW line, before the comment boundary is applied,
  # because the marker lives IN the trailing comment. Reason is MANDATORY: the
  # trailing [^ \t] is the whole point.
  #
  # The separator is an ALTERNATION, never a bracket class. Under LC_ALL=C the
  # em-dash is three bytes and a bracket class degrades to a byte set that matches
  # ONE of them, leaving the next byte to satisfy [^ \t] — so a whitespace-only
  # reason would suppress. An alternation branch matches the whole byte sequence
  # and the tooth holds. Measured, not reasoned, in check-convention.sh.
  marked = (line ~ /deploy-path-literal:[ \t]*allow[ \t]*(-|—)[ \t]*[^ \t]/) ? 1 : 0

  n = length(line)
  q = 0; buf = ""
  for (i = 1; i <= n; i++) {
    c = substr(line, i, 1)
    if (q == 0) {
      # P3 (first limb) — a hash that BEGINS A WORD opens a comment; the rest of
      # the line is out of class. Requiring word-initial position is what keeps
      # ${#arr[@]} and $# from truncating a line that carries a real literal.
      if (c == "#" && (i == 1 || is_ws(substr(line, i - 1, 1)))) break
      else if (c == "\"") { q = 1; buf = "" }
      else if (c == "\047") { q = 2; buf = "" }
    } else if (q == 1) {
      if (c == "\\" && i < n) { buf = buf c substr(line, i + 1, 1); i++ }
      else if (c == "\"") { q = 0; split_record(buf, marked) }
      else buf = buf c
    } else {
      if (c == "\047") { q = 0; split_record(buf, marked) }
      else buf = buf c
    }
  }
}
END { printf "@@\t%d\t%d\t%d\t%d\t%d\t%d\n", FILES+0, LIT+0, XROOT+0, XEXP+0, XGLOB+0, XPH+0 }
'

# ─────────────────────────────────────────────────────────────────────────────
# pl_roots — P1's root set, DERIVED LIVE. Every top-level directory carrying at
# least one tracked file, space-padded for an index() membership test. Never a
# hardcoded list: a hardcoded set rots the moment a module is added, reproducing
# the very class this file exists to catch.
# ─────────────────────────────────────────────────────────────────────────────
pl_roots() {
  printf ' %s ' "$(git -C "${REPO_ROOT}" ls-files | awk -F/ 'NF > 1 { print $1 }' | sort -u | tr '\n' ' ')"
}

# ─────────────────────────────────────────────────────────────────────────────
# pl_scan <scan-root> <roots> <file>...
#   stdout: one "FINDING <file>:<line>: <literal>" per unmarked non-resolving
#           required literal, one "MARKED ..." per suppressed one, then the
#           mandatory denominator line.
#   return: 0 clean · 1 findings · 3 scan-surface error
# ─────────────────────────────────────────────────────────────────────────────
pl_scan() {
  local _scanroot="$1"; shift
  local _roots="$1"; shift
  local _raw _t _a _b _c _d _e _f
  local _files=0 _literals=0 _xroot=0 _xexp=0 _xglob=0 _xph=0
  local _required=0 _resolved=0 _suppressed=0 _found=0

  _raw="$(awk -v ROOTS="${_roots}" "${PL_AWK}" "$@")"

  while IFS=$'\t' read -r _t _a _b _c _d _e _f; do
    case "${_t}" in
      C)
        _required=$((_required + 1))
        if [ -e "${_scanroot}/${_d}" ]; then
          _resolved=$((_resolved + 1))
        elif [ "${_c}" = "1" ]; then
          _suppressed=$((_suppressed + 1))
          printf 'MARKED  %s:%s: %s\n' "${_a}" "${_b}" "${_d}"
        else
          _found=$((_found + 1))
          printf 'FINDING %s:%s: %s\n' "${_a}" "${_b}" "${_d}"
        fi
        ;;
      @@)
        _files="${_a}"; _literals="${_b}"; _xroot="${_c}"
        _xexp="${_d}"; _xglob="${_e}"; _xph="${_f}"
        ;;
    esac
  done <<<"${_raw}"

  printf 'DENOM files=%s literals=%s required=%s resolved=%s marked=%s excluded=%s (untracked-root=%s expansion=%s glob=%s placeholder=%s)\n' \
    "${_files}" "${_literals}" "${_required}" "${_resolved}" "${_suppressed}" \
    "$((_xroot + _xexp + _xglob + _xph))" "${_xroot}" "${_xexp}" "${_xglob}" "${_xph}"

  # SCAN-SURFACE ERROR. Zero literals, or a root set that derived empty, means the
  # scan measured nothing. Reporting that as a clean zero is the exact failure
  # shape this file exists to close, one layer up.
  if [ "${_literals}" -eq 0 ] || [ -z "${_roots//[[:space:]]/}" ]; then
    return 3
  fi
  [ "${_found}" -gt 0 ] && return 1
  return 0
}

# --- Preflight ---------------------------------------------------------------
if [ ! -f "${TARGET}" ]; then
  printf 'FAIL: required file missing: %s\n' "${TARGET}"; exit 1
fi

ROOTS="$(pl_roots)"
SBX="$(mktemp -d -t plpaths.XXXXXX)"

printf '\ntest_deploy_path_literals.sh — required path literals in core/deploy/deploy.sh\n'
printf 'tracked roots (derived live): %s\n' "${ROOTS}"

# ─────────────────────────────────────────────────────────────────────────────
# PL-1 — SENSITIVITY. A fixture carrying a non-resolving REQUIRED literal is
# flagged. This is the control arm for every zero the live arm reports: a suite
# whose sensitivity arm returns zero is a broken probe, not a clean result.
# Mutation that must turn this red: delete the resolution test in pl_scan().
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPL-1: SENSITIVITY — a non-resolving required literal is flagged\n'
mark_arm "PL-1"
mkdir -p "${SBX}/f1"
printf 'local x="core/deploy/__no_such_file_pl1__.md"\n' > "${SBX}/f1/subject.sh"
OUT="$(pl_scan "${SBX}/f1" "${ROOTS}" "${SBX}/f1/subject.sh")"; RC=$?
case "${OUT}" in
  *"FINDING"*"core/deploy/__no_such_file_pl1__.md"*)
    if [ "${RC}" -eq 1 ]; then
      report "PL-1 non-resolving required literal is flagged and returns 1" 1
    else
      report "PL-1 non-resolving required literal is flagged and returns 1" 0 "rc=${RC}"
    fi ;;
  *) report "PL-1 non-resolving required literal is flagged and returns 1" 0 "$(printf '%s' "${OUT}" | tr '\n' '|')" ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# PL-2 — SPECIFICITY. A RESOLVING required literal is not flagged.
# Mutation that must turn this red: widen the detector to flag on presence
# (i.e. report every extracted literal rather than only the unresolvable ones).
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPL-2: SPECIFICITY — a resolving required literal is not flagged\n'
mark_arm "PL-2"
mkdir -p "${SBX}/f2/core/deploy"
: > "${SBX}/f2/core/deploy/present.md"
printf 'local x="core/deploy/present.md"\n' > "${SBX}/f2/subject.sh"
OUT="$(pl_scan "${SBX}/f2" "${ROOTS}" "${SBX}/f2/subject.sh")"; RC=$?
case "${OUT}" in
  *"FINDING"*) report "PL-2 a resolving literal is not flagged" 0 "$(printf '%s' "${OUT}" | tr '\n' '|')" ;;
  *)
    case "${OUT}" in
      *"required=1"*"resolved=1"*)
        if [ "${RC}" -eq 0 ]; then
          report "PL-2 a resolving literal is not flagged, counted required=1 resolved=1" 1
        else
          report "PL-2 a resolving literal is not flagged, counted required=1 resolved=1" 0 "rc=${RC}"
        fi ;;
      *) report "PL-2 a resolving literal is not flagged, counted required=1 resolved=1" 0 "$(printf '%s' "${OUT}" | tr '\n' '|')" ;;
    esac ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# PL-3 — SPECIFICITY. A commented literal and an angle-bracket placeholder are
# not flagged — the two limbs of P3. Both targets are absent from the fixture
# root, so a dropped clause surfaces immediately as a finding.
# Mutation that must turn this red: drop either P3 limb — the comment boundary in
# the scanner, or the [<>] test in emit_field().
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPL-3: SPECIFICITY — commented literal + angle-bracket placeholder are out of class\n'
mark_arm "PL-3"
mkdir -p "${SBX}/f3"
{
  printf '# core/deploy/__commented_missing_pl3__.md\n'
  printf 'local y="x"   # core/deploy/__trailing_comment_pl3__.md\n'
  printf 'local z="packages/<name>.skill"\n'
} > "${SBX}/f3/subject.sh"
OUT="$(pl_scan "${SBX}/f3" "${ROOTS}" "${SBX}/f3/subject.sh")"; RC=$?
case "${OUT}" in
  *"FINDING"*) report "PL-3 comment + placeholder are out of class" 0 "$(printf '%s' "${OUT}" | tr '\n' '|')" ;;
  *)
    case "${OUT}" in
      *"required=0"*"placeholder=1"*) report "PL-3 comment + placeholder are out of class (placeholder counted, not dropped)" 1 ;;
      *) report "PL-3 comment + placeholder are out of class (placeholder counted, not dropped)" 0 "$(printf '%s' "${OUT}" | tr '\n' '|')" ;;
    esac ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# PL-4 — SPECIFICITY. A literal rooted at an UNTRACKED top-level directory is not
# flagged, and the root set is DERIVED rather than hardcoded. Both halves are
# needed: a hardcoded list would still pass the fixture half, so the arm
# independently re-derives the set from git and compares.
# Mutation that must turn this red: hardcode the root list in pl_roots() instead
# of deriving it from git ls-files.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPL-4: SPECIFICITY — untracked-root literal is out of class; the root set is derived\n'
mark_arm "PL-4"
mkdir -p "${SBX}/f4"
printf 'local p="projects/Reference/__untracked_root_pl4__.md"\n' > "${SBX}/f4/subject.sh"
OUT="$(pl_scan "${SBX}/f4" "${ROOTS}" "${SBX}/f4/subject.sh")"; RC=$?
case "${OUT}" in
  *"FINDING"*) report "PL-4a untracked-root literal is out of class" 0 "$(printf '%s' "${OUT}" | tr '\n' '|')" ;;
  *)
    case "${OUT}" in
      *"required=0"*"untracked-root=1"*) report "PL-4a untracked-root literal is out of class (counted as excluded)" 1 ;;
      *) report "PL-4a untracked-root literal is out of class (counted as excluded)" 0 "$(printf '%s' "${OUT}" | tr '\n' '|')" ;;
    esac ;;
esac

EXPECT_ROOTS=" $(git -C "${REPO_ROOT}" ls-files | awk -F/ 'NF > 1 { print $1 }' | sort -u | tr '\n' ' ') "
ACTUAL_ROOTS="$(printf '%s' "${ROOTS}" | sed -e 's/^ *//' -e 's/ *$//')"
EXPECT_TRIM="$(printf '%s' "${EXPECT_ROOTS}" | sed -e 's/^ *//' -e 's/ *$//')"
if [ -n "${EXPECT_TRIM}" ] && [ "${ACTUAL_ROOTS}" = "${EXPECT_TRIM}" ]; then
  report "PL-4b the root set is derived live from git ls-files, not hardcoded" 1
else
  report "PL-4b the root set is derived live from git ls-files, not hardcoded" 0 \
    "derived=[${ACTUAL_ROOTS}] independent=[${EXPECT_TRIM}]"
fi

# ─────────────────────────────────────────────────────────────────────────────
# PL-5 — P4 field split. A ||| record whose path fields resolve is NOT flagged;
# one whose path field does not resolve IS. Without the split, the first record
# is graded as one long span, misses the extraction rule on whitespace, and the
# whole record silently leaves the population.
# Mutation that must turn this red: drop the ||| split in split_record().
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPL-5: P4 — ||| records are graded field by field\n'
mark_arm "PL-5"
mkdir -p "${SBX}/f5/core/schemas" "${SBX}/f5/operations/templates"
: > "${SBX}/f5/core/schemas/present-schema.md"
: > "${SBX}/f5/operations/templates/present-template.md"
{
  printf 'local a="operations/templates/present-template.md|||core/schemas/present-schema.md|||Anchor Three"\n'
  printf 'local b="operations/templates/present-template.md|||core/schemas/__absent_pl5__.md|||Anchor Three"\n'
} > "${SBX}/f5/subject.sh"
OUT="$(pl_scan "${SBX}/f5" "${ROOTS}" "${SBX}/f5/subject.sh")"; RC=$?
PL5_OK=1
case "${OUT}" in *"core/schemas/__absent_pl5__.md"*) ;; *) PL5_OK=0 ;; esac
case "${OUT}" in *"FINDING"*"present-template.md"*) PL5_OK=0 ;; esac
case "${OUT}" in *"FINDING"*"present-schema.md"*) PL5_OK=0 ;; esac
case "${OUT}" in *"required=4"*"resolved=3"*) ;; *) PL5_OK=0 ;; esac
[ "${RC}" -eq 1 ] || PL5_OK=0
if [ "${PL5_OK}" -eq 1 ]; then
  report "PL-5 ||| record: resolving fields clean, non-resolving field flagged (required=4 resolved=3)" 1
else
  report "PL-5 ||| record: resolving fields clean, non-resolving field flagged (required=4 resolved=3)" 0 \
    "rc=${RC} out=$(printf '%s' "${OUT}" | tr '\n' '|')"
fi

# ─────────────────────────────────────────────────────────────────────────────
# PL-6 — the MARKER, all four cases. A reasoned allow suppresses AND IS COUNTED;
# a bare allow does not; a whitespace-only reason does not; and BOTH separators
# (ASCII hyphen and em-dash) suppress.
# Mutation that must turn this red: drop the trailing [^ \t] from the suppressor
# (the bare and whitespace-only cases start suppressing), or swap the (-|—)
# alternation for a [-—] bracket class (the whitespace-only case starts
# suppressing under LC_ALL=C while every other case still passes).
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPL-6: MARKER — reason mandatory, both separators, suppression counted\n'
mark_arm "PL-6"
mkdir -p "${SBX}/f6"

pl6_case() { # <fixture-name> <line-content>
  local d="${SBX}/f6/$1"
  mkdir -p "${d}"
  printf '%s\n' "$2" > "${d}/subject.sh"
  pl_scan "${d}" "${ROOTS}" "${d}/subject.sh"
}

O_EM="$(pl6_case em 'local x="core/deploy/__marked_pl6__.md"   # deploy-path-literal: allow — deliberate back-compat fallback rung')"
O_HY="$(pl6_case hy 'local x="core/deploy/__marked_pl6__.md"   # deploy-path-literal: allow - deliberate back-compat fallback rung')"
O_BARE="$(pl6_case bare 'local x="core/deploy/__marked_pl6__.md"   # deploy-path-literal: allow')"
O_BLANK="$(pl6_case blank 'local x="core/deploy/__marked_pl6__.md"   # deploy-path-literal: allow —   ')"

PL6_OK=1
case "${O_EM}" in *"MARKED"*"__marked_pl6__.md"*) ;; *) PL6_OK=0 ;; esac
case "${O_EM}" in *"marked=1"*) ;; *) PL6_OK=0 ;; esac
case "${O_EM}" in *"FINDING"*) PL6_OK=0 ;; esac
case "${O_HY}" in *"MARKED"*"__marked_pl6__.md"*) ;; *) PL6_OK=0 ;; esac
case "${O_HY}" in *"FINDING"*) PL6_OK=0 ;; esac
case "${O_BARE}" in *"FINDING"*"__marked_pl6__.md"*) ;; *) PL6_OK=0 ;; esac
case "${O_BARE}" in *"marked=0"*) ;; *) PL6_OK=0 ;; esac
case "${O_BLANK}" in *"FINDING"*"__marked_pl6__.md"*) ;; *) PL6_OK=0 ;; esac
case "${O_BLANK}" in *"marked=0"*) ;; *) PL6_OK=0 ;; esac
if [ "${PL6_OK}" -eq 1 ]; then
  report "PL-6 em-dash and hyphen reasons suppress and are counted; bare and whitespace-only do not" 1
else
  report "PL-6 em-dash and hyphen reasons suppress and are counted; bare and whitespace-only do not" 0 \
    "em=[$(printf '%s' "${O_EM}" | tr '\n' '|')] hy=[$(printf '%s' "${O_HY}" | tr '\n' '|')] bare=[$(printf '%s' "${O_BARE}" | tr '\n' '|')] blank=[$(printf '%s' "${O_BLANK}" | tr '\n' '|')]"
fi

# ─────────────────────────────────────────────────────────────────────────────
# PL-7 — BROKEN PROBE. A scan that extracts zero literals returns 3, never a
# clean zero. A gate that reports "no findings" over an empty population is
# indistinguishable from one that examined nothing, which is the failure this
# whole file generalizes.
# Mutation that must turn this red: replace the scan-surface guard in pl_scan()
# with a clean-zero return.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPL-7: BROKEN PROBE — zero literals extracted is exit 3, not a clean pass\n'
mark_arm "PL-7"
mkdir -p "${SBX}/f7"
printf 'echo "nothing path shaped here at all"\n' > "${SBX}/f7/subject.sh"
OUT="$(pl_scan "${SBX}/f7" "${ROOTS}" "${SBX}/f7/subject.sh")"; RC=$?
if [ "${RC}" -eq 3 ]; then
  case "${OUT}" in
    *"literals=0"*) report "PL-7 an empty extraction returns 3 and reports literals=0" 1 ;;
    *) report "PL-7 an empty extraction returns 3 and reports literals=0" 0 "$(printf '%s' "${OUT}" | tr '\n' '|')" ;;
  esac
else
  report "PL-7 an empty extraction returns 3 and reports literals=0" 0 "rc=${RC}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# PL-8 — THE LIVE ARM. This is the standing assertion. Every required path
# literal in the real core/deploy/deploy.sh resolves against the real repo root,
# or carries a reason-bearing marker.
#
# A scan-surface error here is fatal to the suite (exit 3), because the live scan
# is the only arm whose subject is the shipping file: a live scan that measured
# nothing must never read green.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nPL-8: LIVE — every required path literal in core/deploy/deploy.sh resolves\n'
mark_arm "PL-8"
LIVE_OUT="$(pl_scan "${REPO_ROOT}" "${ROOTS}" "${TARGET}")"; LIVE_RC=$?
printf '%s\n' "${LIVE_OUT}" | sed 's/^/  /'

if [ "${LIVE_RC}" -eq 3 ]; then
  printf '\n  SCAN-SURFACE ERROR: the live scan extracted zero literals or derived zero tracked\n'
  printf '  roots. It measured nothing, so it is reported as an error rather than a pass.\n'
  printf '======================================================================\n'
  exit 3
fi

if [ "${LIVE_RC}" -eq 0 ]; then
  report "PL-8 every required path literal in deploy.sh resolves (or is marked with a reason)" 1
else
  report "PL-8 every required path literal in deploy.sh resolves (or is marked with a reason)" 0 \
    "see the FINDING lines above; remediate the path, or mark the line deploy-path-literal: allow — <reason>"
fi

# ─────────────────────────────────────────────────────────────────────────────
# ARM REACH — assert on REACHEDNESS, not on the tally. An arm that stopped running
# takes its own PASS lines with it, so the tally shrinks while FAIL stays at zero
# and a contract keyed on FAIL alone never fires.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nARM REACH: every declared arm ran\n'
EXPECT_RUN="PL-1 PL-2 PL-3 PL-4 PL-5 PL-6 PL-7 PL-8"
reach_missing=""
for a in ${EXPECT_RUN}; do
  case " ${ARMS_RUN}" in
    *" ${a} "*) ;;
    *) reach_missing="${reach_missing}${a} " ;;
  esac
done
if [ -z "${reach_missing}" ]; then
  report "every declared arm actually ran (${EXPECT_RUN})" 1
else
  report "every declared arm actually ran" 0 "never reached: ${reach_missing}| ran: ${ARMS_RUN}"
fi

printf '\n======================================================================\n'
printf 'test_deploy_path_literals.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
printf '======================================================================\n'

[ "${FAIL}" -ne 0 ] && exit 1
exit 0

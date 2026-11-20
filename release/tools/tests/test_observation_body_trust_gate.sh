#!/usr/bin/env bash
# test_observation_body_trust_gate.sh — every documented reader of an observation
# issue's BODY resolves the author's trust (A0) before it reads that body, and reads
# bodies only for trusted members.
#
# WHAT IT ASSERTS. Any account can open an issue with the observation form on a public
# repository, so an observation body is untrusted third-party content until its
# author's repository relationship says otherwise. The canonical trust boundary
# (release/governance/release-process.md § Inter-Stage Feedback Protocol, the
# author-association trust boundary) puts that read BEFORE any intake or triage reader
# acts on a body. Each arm names one documented reader and checks it inside that
# reader's own section. A section that cannot be found fails loud, never passes vacuously.
#
# Four arm kinds, because a reader that issues read commands owes more than one that
# only describes a path in prose:
#   cmd   — a section that issues read commands (a, b, c1, d). It must carry a LITERAL
#           `author_association` read, positioned before its first body read. A bare
#           "A0" citation is not enough here: a section can cite A0 and still read every
#           body first.
#   neg   — the same sections (a¬, b¬, c1¬, d¬). FAIL if the section contains any
#           population-wide observation read that pulls `body` — `gh issue list`,
#           `gh api` or `gh search issues` over the observation label whose fields or
#           jq filter include body. Such a read puts untrusted bodies in front of the
#           reader regardless of where the trust read sits.
#   prose — a section that describes a drafting path without issuing commands (c2, e,
#           g). An A0 citation (or a literal `author_association`) must come before the
#           section's body-read anchor.
#   co    — co-occurrence (f, h1, h2, i1, i2). Every line in the section matching an
#           anchor must also match a required pattern: the A0 definition names
#           observations, a force-bundle names UNTRUSTED-BODY, and a "prior operator
#           decision" read is limited to trusted-set comment authors.
#
# WHAT IT DOES NOT ASSERT. It reads governing prose, not agent behaviour: it proves the
# instructions gate the body read on trust, not that an agent following them will. It
# is a structural regression check on the instruction surface, and it is the only
# executable surface this class has.
#
# CONTROL ARMS. Every predicate is run against synthetic text whose verdict is known, so
# a predicate that cannot fail is caught here rather than read as green.
#
# Portable: bash 3.2 (stock macOS), POSIX awk, no associative arrays.
set -u

# OBS_TRUST_GATE_ROOT lets a caller point the suite at a sandbox copy of the corpus.
ROOT="${OBS_TRUST_GATE_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd -P)}"
PASS=0; FAIL=0

# extract_section FILE PARENT_RE START_RE END_RE
# Prints the lines from the first START_RE match (after the first PARENT_RE match, when
# PARENT_RE is non-empty) up to, not including, the next END_RE match.
# Regexes reach awk through ENVIRON, never `-v`: `-v` processes backslash escapes, which
# would turn `\*` into `*` and silently change what a pattern matches.
extract_section() {
  OTG_PARENT="$2" OTG_START="$3" OTG_STOP="$4" LC_ALL=C awk '
    BEGIN { parent = ENVIRON["OTG_PARENT"]; start = ENVIRON["OTG_START"]; stop = ENVIRON["OTG_STOP"]
            st = (parent == "") ? 1 : 0 }
    st == 0 { if ($0 ~ parent) st = 1; next }
    st == 1 { if ($0 ~ start) { st = 2; print; } next }
    st == 2 { if ($0 ~ stop) exit; print }
  ' "$1"
}

# first_pos TEXT ERE -> 1-based character offset of the first match, 0 when none.
first_pos() {
  printf '%s' "$1" | OTG_RE="$2" LC_ALL=C awk 'BEGIN { RS = "\001"; re = ENVIRON["OTG_RE"] } { p = match($0, re); print (p > 0 ? p : 0); exit } END { if (NR == 0) print 0 }'
}

# count_lines TEXT ERE -> number of lines matching ERE.
count_lines() {
  printf '%s\n' "$1" | OTG_RE="$2" LC_ALL=C awk 'BEGIN { re = ENVIRON["OTG_RE"]; n = 0 } $0 ~ re { n++ } END { print n }'
}

# count_lines_missing TEXT ANCHOR_RE REQUIRED_RE -> lines matching ANCHOR_RE but not REQUIRED_RE.
count_lines_missing() {
  printf '%s\n' "$1" | OTG_A="$2" OTG_R="$3" LC_ALL=C awk 'BEGIN { a = ENVIRON["OTG_A"]; r = ENVIRON["OTG_R"]; n = 0 } ($0 ~ a) && ($0 !~ r) { n++ } END { print n }'
}

PROSE_TRUST_RE='author_association|(^|[^A-Za-z0-9])A0([^0-9]|$)'
CMD_TRUST_RE='author_association'
JSON_BODY_RE='(--json[ =][^ ]*body|\.body)'
# One backtick span holding a population-wide gh read over the observation label that
# pulls body (either order of the two words).
POP_BODY_RE='gh (issue list|api|search issues)[^`]*observation[^`]*body|gh (issue list|api|search issues)[^`]*body[^`]*observation'

# order_verdict TEXT TRUST_RE BODY_RE -> "PASS" or "FAIL: <reason>"
order_verdict() {
  local text="$1" tre="$2" bre="$3" tpos bpos
  if [ -z "$text" ]; then echo "FAIL: section not found"; return; fi
  tpos="$(first_pos "$text" "$tre")"
  if [ -n "$bre" ]; then
    bpos="$(first_pos "$text" "$bre")"
    if [ "$bpos" -eq 0 ]; then echo "FAIL: body-read anchor not found in the section"; return; fi
  else
    bpos=0
  fi
  if [ "$tpos" -eq 0 ]; then echo "FAIL: required trust anchor not found in the section"; return; fi
  if [ "$bpos" -gt 0 ] && [ "$tpos" -gt "$bpos" ]; then echo "FAIL: the trust read comes after the body read (trust@${tpos} body@${bpos})"; return; fi
  echo "PASS"
}

# neg_verdict TEXT -> "PASS" or "FAIL: <reason>"
neg_verdict() {
  local text="$1" n
  if [ -z "$text" ]; then echo "FAIL: section not found"; return; fi
  n="$(count_lines "$text" "$POP_BODY_RE")"
  if [ "$n" -gt 0 ]; then echo "FAIL: ${n} population-wide observation read(s) pulling body"; return; fi
  echo "PASS"
}

# co_verdict TEXT ANCHOR_RE REQUIRED_RE -> "PASS" or "FAIL: <reason>"
co_verdict() {
  local text="$1" n m
  if [ -z "$text" ]; then echo "FAIL: section not found"; return; fi
  n="$(count_lines "$text" "$2")"
  if [ "$n" -eq 0 ]; then echo "FAIL: anchor not found in the section"; return; fi
  m="$(count_lines_missing "$text" "$2" "$3")"
  if [ "$m" -gt 0 ]; then echo "FAIL: ${m} of ${n} anchor line(s) lack the required pattern"; return; fi
  echo "PASS"
}

report() { # name verdict
  case "$2" in
    PASS) printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1)) ;;
    *)    printf '  FAIL: %s — %s\n' "$1" "${2#FAIL: }"; FAIL=$((FAIL + 1)) ;;
  esac
}

section() { # file parent_re start_re end_re -> section text, or empty when the file is missing
  [ -f "$ROOT/$1" ] || return 0
  extract_section "$ROOT/$1" "$2" "$3" "$4"
}

arm_cmd() { # id label file parent_re start_re end_re  (emits the cmd arm and its neg arm)
  local text; text="$(section "$3" "$4" "$5" "$6")"
  report "$1  $2 — literal author_association read before the body read" "$(order_verdict "$text" "$CMD_TRUST_RE" "$JSON_BODY_RE")"
  report "$1¬ $2 — no population-wide observation body read" "$(neg_verdict "$text")"
}

arm_prose() { # id label file parent_re start_re end_re body_re
  local text; text="$(section "$3" "$4" "$5" "$6")"
  report "$1  $2" "$(order_verdict "$text" "$PROSE_TRUST_RE" "$7")"
}

arm_co() { # id label file parent_re start_re end_re anchor_re required_re
  local text; text="$(section "$3" "$4" "$5" "$6")"
  report "$1  $2" "$(co_verdict "$text" "$7" "$8")"
}

expect() { # label expected-prefix verdict
  case "$3" in
    "$2"*) printf '  PASS: control — %s (got: %s)\n' "$1" "$3"; PASS=$((PASS + 1)) ;;
    *)     printf '  FAIL: control — %s (expected %s, got: %s)\n' "$1" "$2" "$3"; FAIL=$((FAIL + 1)) ;;
  esac
}

# Control texts live in top-level variables, never inline inside "$(...)": bash 3.2
# mis-parses a double quote inside single quotes inside a double-quoted command
# substitution, which would hand the predicate a mangled control and void it.
T_NO_TRUST='1. Enumerate: gh issue list --label observation --json number,title,body'
T_LATE_TRUST='read --json number,body first; later resolve author_association'
T_EARLY_TRUST='resolve author_association first, then read --json number,body for trusted members'
T_NO_ANCHOR='resolve author_association; nothing else'
T_A01='see A01, then --json body'
T_BARE_A0='(see A0), then `gh issue view <N> --json body`'
T_CMD_OK='`gh api x --jq "{number, author_association}"` then `gh issue view <N> --json body`'
T_POP_LIST='author_association first; then `gh issue list --label observation --state open --json number,title,body`'
T_POP_API='`gh api "repos/o/r/issues?labels=observation&state=open" --jq ".[] | .body"`'
T_POP_SEARCH='`gh search issues --json number,body -- label:observation`'
T_POP_OK='`gh issue view <N> --json body` and `gh issue list --label observation --json number --jq length`'
T_CO_MISS='a force-bundled issue is logged'
T_CO_NONE='nothing relevant here'
T_CO_OK='a force-bundled issue records UNTRUSTED-BODY'

printf '\nControl arms (each predicate can fail)\n'
expect "prose: no trust read"             FAIL "$(order_verdict "$T_NO_TRUST" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "prose: trust read after body"     FAIL "$(order_verdict "$T_LATE_TRUST" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "prose: trust read before body"    PASS "$(order_verdict "$T_EARLY_TRUST" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "section missing"                  FAIL "$(order_verdict "" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "body anchor missing"              FAIL "$(order_verdict "$T_NO_ANCHOR" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "A01 is not an A0 citation"        FAIL "$(order_verdict "$T_A01" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "prose: a bare A0 citation counts" PASS "$(order_verdict "$T_BARE_A0" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "cmd: a bare A0 citation does not" FAIL "$(order_verdict "$T_BARE_A0" "$CMD_TRUST_RE" "$JSON_BODY_RE")"
expect "cmd: literal read before body"    PASS "$(order_verdict "$T_CMD_OK" "$CMD_TRUST_RE" "$JSON_BODY_RE")"
expect "neg: issue list pulling body"     FAIL "$(neg_verdict "$T_POP_LIST")"
expect "neg: gh api jq pulling .body"     FAIL "$(neg_verdict "$T_POP_API")"
expect "neg: body before label"           FAIL "$(neg_verdict "$T_POP_SEARCH")"
expect "neg: per-issue view + count only" PASS "$(neg_verdict "$T_POP_OK")"
expect "co: anchor line lacks required"   FAIL "$(co_verdict "$T_CO_MISS" 'force-bundle' 'UNTRUSTED-BODY')"
expect "co: anchor absent"                FAIL "$(co_verdict "$T_CO_NONE" 'force-bundle' 'UNTRUSTED-BODY')"
expect "co: anchor line carries it"       PASS "$(co_verdict "$T_CO_OK" 'force-bundle' 'UNTRUSTED-BODY')"

STAGE2="release/references/pipeline/stage-02-triage.md"
STAGE3="release/references/pipeline/stage-03-bundle.md"
TRIAGE_EXEC="release/skills/pipeline-triage/references/triage-execution.md"
OPS="core/governance/OPERATIONS.md"
PLANNER="release/skills/release-planner/SKILL.md"
GCS="core/schemas/gate-criteria-spec.md"

printf '\nReaders that issue read commands\n'
arm_cmd a  "stage-02 § Observation counting" "$STAGE2" '^## 5\. Process' \
  '^\*\*Observation counting \(per batch' '^<!-- design-artifact|^#{1,6} '
arm_cmd b  "triage-execution § Observation-counting pass" "$TRIAGE_EXEC" '' \
  '^### Observation-counting pass' '^#{1,3} '
arm_cmd c1 "OPERATIONS § Pattern Review Rule 2 (enumeration)" "$OPS" \
  '^## Pattern Review Cadence Protocol' '^### Rule 2 ' '^#{1,3} '
arm_cmd d  "release-planner § Mode D (enumeration)" "$PLANNER" '' \
  '^### Mode D ' '^#{1,3} '

printf '\nReaders that describe a drafting path\n'
arm_prose c2 "OPERATIONS § Pattern Review Rule 3 (verbatim embed)" "$OPS" \
  '^## Pattern Review Cadence Protocol' '^### Rule 3 ' '^#{1,3} ' '[Ss]ource observation bod'
arm_prose e  "gate-criteria-spec § Template-Conversion Rule" "$GCS" '' \
  '^### Template-Conversion Rule' '^\*\*Retroactive applicability|^#{1,3} ' 'drafts improvement\.yml body'
arm_prose g  "stage-03 Template-Conversion Rule invocation" "$STAGE3" '' \
  '^\*\*Template-Conversion Rule invocation' '^$' 'draft improvement\.yml body'

printf '\nTrust scope and trust carried forward\n'
arm_co f  "stage-02 A0 block names observations in its scope" "$STAGE2" '^## 5\. Process' \
  '^\*\*A0 ' '^$' 'A0 — author-association body-trust resolution' '[Oo]bservation'
arm_co h1 "gate-criteria-spec path (B): a force-bundle records UNTRUSTED-BODY" "$GCS" '' \
  '^### Template-Conversion Rule' '^\*\*Retroactive applicability|^#{1,3} ' 'force-bundled' 'UNTRUSTED-BODY'
arm_co h2 "stage-03 path (B): a force-bundle records UNTRUSTED-BODY" "$STAGE3" '' \
  '^\*\*Template-Conversion Rule invocation' '^$' 'force-bundle' 'UNTRUSTED-BODY'
arm_co i1 "stage-02 step 5: prior decisions from trusted comment authors only" "$STAGE2" '^## 5\. Process' \
  '^\*\*Observation counting \(per batch' '^<!-- design-artifact|^#{1,6} ' 'prior operator decision' 'trusted set'
arm_co i2 "triage-execution: prior decisions from trusted comment authors only" "$TRIAGE_EXEC" '' \
  '^### Observation-counting pass' '^#{1,3} ' 'prior operator decision' 'trusted set'

printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

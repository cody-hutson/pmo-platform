#!/usr/bin/env bash
# test_observation_body_trust_gate.sh — every documented reader of an observation
# issue's BODY resolves the author's trust (A0) before it reads that body.
#
# WHAT IT ASSERTS. Any account can open an issue with the observation form on a public
# repository, so an observation body is untrusted third-party content until its
# author's repository relationship says otherwise. The canonical trust boundary
# (release/governance/release-process.md § Inter-Stage Feedback Protocol, the
# author-association trust boundary) puts that read BEFORE any intake or triage reader
# acts on a body. Each arm below names one documented reader of observation bodies and
# asserts, inside that reader's own section, that:
#   1. the section exists (a moved or renamed section fails loud — never a vacuous pass);
#   2. the section's body-read anchor exists (so the arm is measuring the read it names);
#   3. a trust read — an `author_association` read or an explicit A0 citation — appears
#      in the section; and
#   4. the first trust read comes BEFORE the first body read, by position in the text.
# Arm f asserts the Stage 2 A0 definition itself names observations in its scope.
#
# WHAT IT DOES NOT ASSERT. It reads governing prose, not agent behaviour: it proves the
# instructions put the trust read first, not that an agent following them will. It is a
# structural regression check on the instruction surface, and it is the only executable
# surface this class has.
#
# CONTROL ARMS. The predicate is run against synthetic sections whose verdict is known —
# no trust read, a trust read after the body read, a trust read before it, a missing
# section — so a predicate that cannot fail is caught here rather than read as green.
#
# Portable: bash 3.2 (stock macOS), POSIX awk, no associative arrays.
set -u

# OBS_TRUST_GATE_ROOT lets a caller name the checkout when the script runs from stdin.
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

TRUST_RE='author_association|(^|[^A-Za-z0-9])A0([^0-9]|$)'
JSON_BODY_RE='(--json[ =][^ ]*body|\.body)'

# gate_verdict TEXT TRUST_RE BODY_RE -> prints "PASS" or "FAIL: <reason>"
gate_verdict() {
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

report() { # name verdict
  case "$2" in
    PASS) printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1)) ;;
    *)    printf '  FAIL: %s — %s\n' "$1" "${2#FAIL: }"; FAIL=$((FAIL + 1)) ;;
  esac
}

arm() { # name file parent_re start_re end_re trust_re body_re
  local f="$ROOT/$2" text
  if [ ! -f "$f" ]; then report "$1" "FAIL: file missing: $2"; return; fi
  text="$(extract_section "$f" "$3" "$4" "$5")"
  report "$1" "$(gate_verdict "$text" "$6" "$7")"
}

expect() { # name expected-prefix text trust_re body_re
  local v; v="$(gate_verdict "$3" "$4" "$5")"
  case "$v" in
    "$2"*) printf '  PASS: control — %s (got: %s)\n' "$1" "$v"; PASS=$((PASS + 1)) ;;
    *)     printf '  FAIL: control — %s (expected %s, got: %s)\n' "$1" "$2" "$v"; FAIL=$((FAIL + 1)) ;;
  esac
}

printf '\nControl arms (the predicate can fail)\n'
expect "no trust read"           "FAIL" "1. Enumerate: gh issue list --label observation --json number,title,body" "$TRUST_RE" "$JSON_BODY_RE"
expect "trust read after body"   "FAIL" "read --json number,body first; later resolve author_association" "$TRUST_RE" "$JSON_BODY_RE"
expect "trust read before body"  "PASS" "resolve author_association first, then read --json number,body for trusted members" "$TRUST_RE" "$JSON_BODY_RE"
expect "section missing"         "FAIL" "" "$TRUST_RE" "$JSON_BODY_RE"
expect "body anchor missing"     "FAIL" "resolve author_association; nothing else" "$TRUST_RE" "$JSON_BODY_RE"
expect "A01 is not an A0 citation" "FAIL" "see A01, then --json body" "$TRUST_RE" "$JSON_BODY_RE"

printf '\nObservation-body readers\n'
STAGE2="release/references/pipeline/stage-02-triage.md"
arm "a  stage-02 § Observation counting" "$STAGE2" '^## 5\. Process' \
  '^\*\*Observation counting \(per batch' '^<!-- design-artifact|^#{1,6} ' "$TRUST_RE" "$JSON_BODY_RE"
arm "b  triage-execution § Observation-counting pass" \
  "release/skills/pipeline-triage/references/triage-execution.md" '' \
  '^### Observation-counting pass' '^#{1,3} ' "$TRUST_RE" "$JSON_BODY_RE"
arm "c1 OPERATIONS § Pattern Review Rule 2 (enumeration)" "core/governance/OPERATIONS.md" \
  '^## Pattern Review Cadence Protocol' '^### Rule 2 ' '^#{1,3} ' "$TRUST_RE" "$JSON_BODY_RE"
arm "c2 OPERATIONS § Pattern Review Rule 3 (verbatim embed)" "core/governance/OPERATIONS.md" \
  '^## Pattern Review Cadence Protocol' '^### Rule 3 ' '^#{1,3} ' "$TRUST_RE" '[Ss]ource observation bod'
arm "d  release-planner § Mode D (enumeration)" "release/skills/release-planner/SKILL.md" '' \
  '^### Mode D ' '^#{1,3} ' "$TRUST_RE" "$JSON_BODY_RE"
arm "e  gate-criteria-spec § Template-Conversion Rule" "core/schemas/gate-criteria-spec.md" '' \
  '^### Template-Conversion Rule' '^\*\*Retroactive applicability|^#{1,3} ' "$TRUST_RE" 'drafts improvement\.yml body'
arm "f  stage-02 A0 block names observations in scope" "$STAGE2" '^## 5\. Process' \
  '^\*\*A0 ' '^$' '[Oo]bservation' ''

printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

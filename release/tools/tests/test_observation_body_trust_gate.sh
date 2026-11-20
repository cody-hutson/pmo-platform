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
#           `author_association` read, positioned before its first body read, and the
#           clause introducing that body read must say it reads trusted members only.
#           A bare "A0" citation is not enough here: a section can cite A0 and still read
#           every body first. A body read is a `--json` field list or jq filter naming
#           body, or a `gh issue view` with no `--json` (its default view prints the body).
#   neg   — the same sections (a¬, b¬, c1¬, d¬). FAIL if the section contains any
#           population-wide observation read that pulls `body` — `gh issue list`,
#           `gh api` or `gh search issues` over the observation label whose fields or
#           jq filter include body. Such a read puts untrusted bodies in front of the
#           reader regardless of where the trust read sits.
#           Both kinds match on commands joined across lines first: a backslash
#           continuation anywhere, and a trailing pipe or `&&` / `||` inside a fence.
#   prose — a section that describes a drafting path without issuing commands (c2, e,
#           g). An A0 citation (or a literal `author_association`) must come before the
#           section's body-read anchor.
#   co    — co-occurrence (f, h1, h2, i1, i2). Every line in the section matching an
#           anchor must also match a required pattern: the A0 definition names
#           observations, a force-bundle persists UNTRUSTED-BODY in the issue's triage
#           decision comment (where A0 persists it and the Stage-5 re-trigger reads it),
#           and a "prior operator decision" read is limited to trusted-set comment authors.
#
# NO EARLY-EXIT READERS. Every awk here reads its whole input; nothing pipes into a
# reader that stops early (grep -q, head, an awk that exits, sed q, read). The
# repository's SIGPIPE-idiom gate scans this whole file.
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
  printf '%s' "$1" | OTG_RE="$2" LC_ALL=C awk 'BEGIN { RS = "\001"; re = ENVIRON["OTG_RE"] } { p = match($0, re); print (p > 0 ? p : 0) } END { if (NR == 0) print 0 }'
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
# The clause that introduces a section's first body read must say it is limited.
TRUSTED_ONLY_RE='trusted members only'

# normalize_cmds TEXT -> TEXT with each continued command joined into one logical line:
# a line ending in a backslash anywhere, and inside a fenced block a line ending in a
# pipe or `&&` / `||`. A command written across lines is then one line for matching.
# Every awk below reads its whole input: none exits early inside a pipe.
normalize_cmds() {
  printf '%s\n' "$1" | LC_ALL=C awk '
    /^[[:space:]]*```/ { if (buf != "") { print buf; buf = "" } fence = !fence; print; next }
    {
      line = $0; cont = 0
      if (line ~ /\\$/) { sub(/\\$/, "", line); cont = 1 }
      else if (fence && line ~ /(\||&&)[[:space:]]*$/) { cont = 1 }
      buf = (buf == "") ? line : buf " " line
      if (!cont) { print buf; buf = "" }
    }
    END { if (buf != "") print buf }
  '
}

# first_body_pos TEXT -> 1-based offset of the first body read, 0 when none. A body read
# is a `--json` field list or a jq filter naming body, or a `gh issue view` without
# `--json` — its default view prints the body. A `gh issue view --json` whose fields
# omit body is not a body read.
first_body_pos() {
  printf '%s' "$1" | LC_ALL=C awk 'BEGIN { RS = "\001" }
    {
      s = $0; best = 0
      p = match(s, /--json[ =][^ \n]*body|\.body/); if (p > 0) best = p
      off = 0; rest = s; found = 0
      while (!found && (q = match(rest, /gh issue view[^`\n|;&)]*/)) > 0) {
        span = substr(rest, q, RLENGTH)
        if (span !~ /--json/) { pos = off + q; if (best == 0 || pos < best) best = pos; found = 1 }
        else { off += q + RLENGTH - 1; rest = substr(rest, q + RLENGTH) }
      }
      print best
    }
    END { if (NR == 0) print 0 }'
}

# lead_clause TEXT POS -> the text from the last sentence end (". ") or line start
# before POS, up to POS: the clause that introduces the read found at POS.
lead_clause() {
  printf '%s' "$1" | OTG_P="$2" LC_ALL=C awk 'BEGIN { RS = "\001" }
    {
      pre = substr($0, 1, ENVIRON["OTG_P"] - 1); start = 1; done = 0
      for (i = length(pre); i >= 1 && !done; i--) {
        if (substr(pre, i, 1) == "\n" || substr(pre, i, 2) == ". ") { start = i + 1; done = 1 }
      }
      print substr(pre, start)
    }'
}

# cmd_verdict TEXT -> "PASS" or "FAIL: <reason>", for a section that issues read
# commands: a literal author_association read precedes the first body read, and the
# clause introducing that body read says it reads trusted members only.
cmd_verdict() {
  local text tpos bpos clause
  if [ -z "$1" ]; then echo "FAIL: section not found"; return; fi
  text="$(normalize_cmds "$1")"
  bpos="$(first_body_pos "$text")"
  if [ "$bpos" -eq 0 ]; then echo "FAIL: body-read anchor not found in the section"; return; fi
  tpos="$(first_pos "$text" "$CMD_TRUST_RE")"
  if [ "$tpos" -eq 0 ]; then echo "FAIL: required trust anchor not found in the section"; return; fi
  if [ "$tpos" -gt "$bpos" ]; then echo "FAIL: the trust read comes after the body read (trust@${tpos} body@${bpos})"; return; fi
  clause="$(lead_clause "$text" "$bpos")"
  if [ "$(count_lines "$clause" "$TRUSTED_ONLY_RE")" -eq 0 ]; then echo "FAIL: the body read does not say it reads trusted members only"; return; fi
  echo "PASS"
}

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
  n="$(count_lines "$(normalize_cmds "$text")" "$POP_BODY_RE")"
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
  report "$1  $2 — literal author_association read before a trusted-members-only body read" "$(cmd_verdict "$text")"
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
T_CMD_OK='`gh api x --jq "{number, author_association}"`. Then read bodies for trusted members only: `gh issue view <N> --json body`'
T_UNLIMITED='`gh api x --jq "{number, author_association}"`. **Then the body read, for every observation listed:** `gh issue view <N> --json body`'
T_VIEW_FIRST='Skim each with `gh issue view <N>`. Then `gh api x --jq "{number, author_association}"`. Read bodies for trusted members only: `gh issue view <N> --json body`'
T_VIEW_NOBODY='List with `gh issue view <N> --json number,title`. Then `gh api x --jq "{number, author_association}"`. Read bodies for trusted members only: `gh issue view <N> --json body`'
T_POP_CONT='author_association first.
```bash
gh issue list --label observation --state open \
  --json number,title,body,createdAt
```'
T_POP_CONT_OK='author_association first.
```bash
gh issue list --label observation --state open \
  --json number --jq length
```'
T_POP_LIST='author_association first; then `gh issue list --label observation --state open --json number,title,body`'
T_POP_API='`gh api "repos/o/r/issues?labels=observation&state=open" --jq ".[] | .body"`'
T_POP_SEARCH='`gh search issues --json number,body -- label:observation`'
T_POP_OK='`gh issue view <N> --json body` and `gh issue list --label observation --json number --jq length`'
T_CO_MISS='a force-bundled issue is logged'
T_CO_NONE='nothing relevant here'
T_CO_OK='a force-bundled issue records UNTRUSTED-BODY'
T_FB_LOG_ONLY='a force-bundled issue records UNTRUSTED-BODY in its deviation-log entry'
T_FB_COMMENT='a force-bundled issue has UNTRUSTED-BODY persisted in its triage decision comment'
# A force-bundle must persist UNTRUSTED-BODY where A0 persists it and where the Stage-5
# re-trigger reads it: the issue's triage decision comment, not only the deviation log.
FB_PERSIST_RE='UNTRUSTED-BODY.*triage decision comment|triage decision comment.*UNTRUSTED-BODY'

printf '\nControl arms (each predicate can fail)\n'
expect "prose: no trust read"             FAIL "$(order_verdict "$T_NO_TRUST" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "prose: trust read after body"     FAIL "$(order_verdict "$T_LATE_TRUST" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "prose: trust read before body"    PASS "$(order_verdict "$T_EARLY_TRUST" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "section missing"                  FAIL "$(order_verdict "" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "body anchor missing"              FAIL "$(order_verdict "$T_NO_ANCHOR" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "A01 is not an A0 citation"        FAIL "$(order_verdict "$T_A01" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "prose: a bare A0 citation counts" PASS "$(order_verdict "$T_BARE_A0" "$PROSE_TRUST_RE" "$JSON_BODY_RE")"
expect "cmd: a bare A0 citation does not" FAIL "$(cmd_verdict "$T_BARE_A0")"
expect "cmd: literal read before a trusted-only body read" PASS "$(cmd_verdict "$T_CMD_OK")"
expect "cmd: body read not limited to trusted members" FAIL "$(cmd_verdict "$T_UNLIMITED")"
expect "cmd: a default gh issue view is a body read" FAIL "$(cmd_verdict "$T_VIEW_FIRST")"
expect "cmd: gh issue view --json without body is not" PASS "$(cmd_verdict "$T_VIEW_NOBODY")"
expect "neg: backslash-continued fenced read pulling body" FAIL "$(neg_verdict "$T_POP_CONT")"
expect "neg: backslash-continued count-only read" PASS "$(neg_verdict "$T_POP_CONT_OK")"
expect "neg: issue list pulling body"     FAIL "$(neg_verdict "$T_POP_LIST")"
expect "neg: gh api jq pulling .body"     FAIL "$(neg_verdict "$T_POP_API")"
expect "neg: body before label"           FAIL "$(neg_verdict "$T_POP_SEARCH")"
expect "neg: per-issue view + count only" PASS "$(neg_verdict "$T_POP_OK")"
expect "co: anchor line lacks required"   FAIL "$(co_verdict "$T_CO_MISS" 'force-bundle' 'UNTRUSTED-BODY')"
expect "co: anchor absent"                FAIL "$(co_verdict "$T_CO_NONE" 'force-bundle' 'UNTRUSTED-BODY')"
expect "co: anchor line carries it"       PASS "$(co_verdict "$T_CO_OK" 'force-bundle' 'UNTRUSTED-BODY')"
expect "co: deviation log alone is not where A0 persists" FAIL "$(co_verdict "$T_FB_LOG_ONLY" 'force-bundle' "$FB_PERSIST_RE")"
expect "co: persisted in the triage decision comment" PASS "$(co_verdict "$T_FB_COMMENT" 'force-bundle' "$FB_PERSIST_RE")"

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
arm_co h1 "gate-criteria-spec path (B): a force-bundle persists UNTRUSTED-BODY in the triage decision comment" "$GCS" '' \
  '^### Template-Conversion Rule' '^\*\*Retroactive applicability|^#{1,3} ' 'force-bundled' "$FB_PERSIST_RE"
arm_co h2 "stage-03 path (B): a force-bundle persists UNTRUSTED-BODY in the triage decision comment" "$STAGE3" '' \
  '^\*\*Template-Conversion Rule invocation' '^$' 'force-bundle' "$FB_PERSIST_RE"
arm_co i1 "stage-02 step 5: prior decisions from trusted comment authors only" "$STAGE2" '^## 5\. Process' \
  '^\*\*Observation counting \(per batch' '^<!-- design-artifact|^#{1,6} ' 'prior operator decision' 'trusted set'
arm_co i2 "triage-execution: prior decisions from trusted comment authors only" "$TRIAGE_EXEC" '' \
  '^### Observation-counting pass' '^#{1,3} ' 'prior operator decision' 'trusted set'

printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

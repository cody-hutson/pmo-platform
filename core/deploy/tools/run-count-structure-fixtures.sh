#!/usr/bin/env bash
# run-count-structure-fixtures.sh — the Check 63 labeled expected-match harness.
#
# Asserts that every FLAG case in the fixture file is flagged by the shipped predicate
# and every CLEAN case is examined AND not flagged, and that every SCOPE-OUT case is
# examined ZERO times. The three verdicts exist separately because "not flagged" and
# "not examined" are different results: a specificity arm whose input was never read
# returns zero, which is that arm's PASS condition, and therefore reads as a passing
# control while proving nothing. This harness refuses to conflate them.
#
# Shared by manual verification and by the fixture-regression beat, so both surfaces
# measure the same thing — the core/hooks/run-fragile-ref-fixtures.sh precedent.
#
# Usage:  core/deploy/tools/run-count-structure-fixtures.sh [fixture-file]
# Exit:   0 all cases pass · 1 one or more cases fail · 3 input failure
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FIXTURES="${1:-$ROOT/core/deploy/tests/fixtures/count-structure-fixtures.txt}"
PREDICATE="$ROOT/core/deploy/tools/check-count-structure.py"

[[ -f "$FIXTURES" ]]  || { echo "INPUT-FAILURE: fixture file not found: $FIXTURES" >&2; exit 3; }
[[ -f "$PREDICATE" ]] || { echo "INPUT-FAILURE: predicate not found: $PREDICATE" >&2; exit 3; }

TMPDIR_RUN="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_RUN"' EXIT

pass=0; fail=0; cases=0; skipped=0
expect=""; label=""; body=""; in_case=0
s_label=""; s_bad=0; s_out=""; s_exit=0

emit_case() {
  cases=$((cases + 1))
  local f="$TMPDIR_RUN/case-$cases.md"
  printf '%s' "$body" > "$f"
  local bytes; bytes=$(wc -c < "$f" | tr -d ' ')
  if [[ "$bytes" -eq 0 ]]; then
    echo "  FAIL  [$expect] $label — 0-byte case body; a control that reads nothing proves nothing"
    fail=$((fail + 1)); return
  fi
  local out; out="$(/usr/bin/python3 "$PREDICATE" --root / --path "$f" --no-baseline --output-format tsv 2>&1)"
  local pairs flagged
  pairs=$(echo "$out" | awk -F'\t' '$1=="DENOM"{sub("pairs=","",$4); print $4}')
  flagged=$(echo "$out" | awk -F'\t' '$1=="FAIL"' | wc -l | tr -d ' ')
  local verdict="?"
  case "$expect" in
    FLAG)      [[ "${pairs:-0}" -gt 0 && "$flagged" -gt 0 ]] && verdict=PASS || verdict=FAIL ;;
    CLEAN)     [[ "${pairs:-0}" -gt 0 && "$flagged" -eq 0 ]] && verdict=PASS || verdict=FAIL ;;
    SCOPE-OUT) [[ "${pairs:-0}" -eq 0 ]]                    && verdict=PASS || verdict=FAIL ;;
    *)         verdict=FAIL ;;
  esac
  if [[ "$verdict" == PASS ]]; then
    pass=$((pass + 1))
    echo "  ok    [$expect] $label (${bytes}B, examined=${pairs:-0}, flagged=$flagged)"
  else
    fail=$((fail + 1))
    echo "  FAIL  [$expect] $label (${bytes}B, examined=${pairs:-0}, flagged=$flagged) — expectation not met"
  fi
}

# ── Scope arm ────────────────────────────────────────────────────────────────
# Asserts that baseline reconciliation is SCOPE-RELATIVE, and that a scope which
# resolves to nothing is a withheld verdict rather than a clean zero.
#
# This is a SECOND block with its own emitter rather than a widening of emit_case.
# Every shipped block case drives a single-file `--no-baseline` invocation, and a
# scope question cannot be posed in that form: it needs a synthetic mini-corpus AND
# a synthetic baseline. Adding baseline state to emit_case would change the contract
# for every existing case to serve arms none of them share.
#
# The mini-corpus is a real git repository because the predicate resolves a subtree
# argument against the corpus enumeration. A directory of untracked files would
# resolve to zero paths, and every arm below would report NOT-EVALUATED for the
# WRONG reason -- passing S5 and S6 while making S1 through S4 unexaminable. The
# tracked-file precondition below is what stops that from reading as a green run.

s_body() {  # <name> -> the named body from the fixture file, verbatim
  awk -v n="$1" '
    $0 == "#SCOPE-BODY " n  { inb = 1; next }
    $0 == "#SCOPE-BODY-END" { inb = 0 }
    inb                     { print }
  ' "$FIXTURES"
}

s_field() { # <output> <key> -> that key from the SCOPE record
  echo "$1" | awk -F'\t' -v k="$2" '$1=="SCOPE"{for(i=2;i<=NF;i++){split($i,kv,"="); if(kv[1]==k) print kv[2]}}'
}

s_count() { # <output> <row-type> -> how many rows of that type
  echo "$1" | awk -F'\t' -v t="$2" '$1==t' | wc -l | tr -d ' '
}

s_pairs() { # <output> -> pairs examined, from the denominator
  echo "$1" | awk -F'\t' '$1=="DENOM"{sub("pairs=","",$4); print $4}'
}

s_run() {   # <baseline> <path-arg>; sets s_out and s_exit
  # The exit status is read from the assignment DIRECTLY. Reading it through a pipe
  # reports the pipe's status, not the predicate's, which would turn every wrong
  # number below into a wrong number reported as a clean exit.
  s_out=$(/usr/bin/python3 "$PREDICATE" --root "$SC" --baseline "$1" --path "$2" --output-format tsv 2>&1)
  s_exit=$?
}

s_case() { s_label="$1"; s_bad=0; }

s_eq() {    # <what> <expected> <observed>
  if [[ -z "$3" ]]; then
    echo "        $s_label -- $1 extracted EMPTY; an assertion over an empty string is vacuously true and proves nothing"
    s_bad=$((s_bad + 1)); return
  fi
  if [[ "$3" != "$2" ]]; then
    echo "        $s_label -- $1: expected [$2], observed [$3]"
    s_bad=$((s_bad + 1))
  fi
}

s_done() {
  cases=$((cases + 1))
  if [[ $s_bad -eq 0 ]]; then
    pass=$((pass + 1)); echo "  ok    [SCOPE] $s_label"
  else
    fail=$((fail + 1)); echo "  FAIL  [SCOPE] $s_label ($s_bad assertion(s) not met)"
  fi
}

s_precondition_failed() {
  echo "  FAIL  [SCOPE] scope-arm-precondition -- $1"
  cases=$((cases + 1)); fail=$((fail + 1))
}

run_scope_arm() {
  SC="$TMPDIR_RUN/scope-corpus"
  mkdir -p "$SC/in" "$SC/out" "$SC/empty" "$SC/perm"

  s_body non-reconciling-in  > "$SC/in/a.md"
  s_body non-reconciling-out > "$SC/out/b.md"
  s_body reconciling-in      > "$TMPDIR_RUN/a-mutated.body"
  cp "$SC/in/a.md"  "$TMPDIR_RUN/a-original.body"
  cp "$SC/in/a.md"  "$SC/perm/r.md"
  cp "$SC/out/b.md" "$SC/perm/x.md"

  # Non-vacuity, before anything is asserted: a 0-byte body makes every arm below
  # true of nothing -- the same reason emit_case carries its own 0-byte guard.
  local nb
  for nb in "$SC/in/a.md" "$SC/out/b.md" "$TMPDIR_RUN/a-mutated.body"; do
    if [[ ! -s "$nb" ]]; then
      s_precondition_failed "case body extracted 0 bytes from $FIXTURES ($nb); every arm below would be vacuous"
      return
    fi
  done

  git -C "$SC" init -q >/dev/null 2>&1
  git -C "$SC" -c core.excludesFile=/dev/null add in/a.md out/b.md perm/r.md perm/x.md >/dev/null 2>&1
  local tracked
  tracked=$(git -C "$SC" ls-files '*.md' | wc -l | tr -d ' ')
  if [[ "${tracked:-0}" -ne 4 ]]; then
    s_precondition_failed "expected 4 tracked markdown files in the synthetic corpus, observed ${tracked:-0}; the subtree resolver would have nothing to resolve against"
    return
  fi

  # The synthetic baseline is generated BY the predicate, so its sha1 keys are the
  # real ones rather than hand-copied digests that rot the moment a body is edited.
  local BL1="$TMPDIR_RUN/scope-baseline-1.txt"
  local BL2="$TMPDIR_RUN/scope-baseline-2.txt"
  /usr/bin/python3 "$PREDICATE" --root "$SC" --no-baseline --emit-baseline > "$BL1" 2>/dev/null
  local bl_rows; bl_rows=$(grep -c . "$BL1" || true)
  if [[ "${bl_rows:-0}" -ne 4 ]]; then
    s_precondition_failed "expected 4 generated baseline rows, observed ${bl_rows:-0}; the arms would assert against a baseline that does not describe the corpus"
    return
  fi
  cp "$BL1" "$BL2"
  printf 'in/gone.md\t0000000000000000\tpre-existing:list\n' >> "$BL2"

  # S1 -- the root-cause fix. out/b.md and perm/* are baselined and OUT of scope.
  s_case "S1 a baseline row outside the requested scope is EXCLUDED, not STALE"
  s_run "$BL1" "in/"
  s_eq "exit"              "0"       "$s_exit"
  s_eq "status"            "fetched" "$(s_field "$s_out" status)"
  s_eq "baseline_in_scope" "1"       "$(s_field "$s_out" baseline_in_scope)"
  s_eq "KNOWN rows"        "1"       "$(s_count "$s_out" KNOWN)"
  s_eq "STALE rows"        "0"       "$(s_count "$s_out" STALE)"
  s_done

  # S2 -- the mutation control, on the subject itself.
  s_case "S2 an IN-scope baselined pair that now reconciles is still STALE"
  cp "$TMPDIR_RUN/a-mutated.body" "$SC/in/a.md"
  s_run "$BL1" "in/"
  s_eq "pairs examined" "1" "$(s_pairs "$s_out")"
  s_eq "STALE rows"     "1" "$(s_count "$s_out" STALE)"
  s_eq "KNOWN rows"     "0" "$(s_count "$s_out" KNOWN)"
  s_done
  cp "$TMPDIR_RUN/a-original.body" "$SC/in/a.md"

  # S3 -- the specificity arm. Without it, "STALE=0" could mean the filter simply
  # stopped reporting everything.
  s_case "S3 a correct IN-scope baseline row is NOT reported STALE"
  s_run "$BL1" "in/"
  s_eq "pairs examined" "1" "$(s_pairs "$s_out")"
  s_eq "files read"     "1" "$(s_field "$s_out" read)"
  s_eq "KNOWN rows"     "1" "$(s_count "$s_out" KNOWN)"
  s_eq "STALE rows"     "0" "$(s_count "$s_out" STALE)"
  s_done

  # S4 -- the ratchet must survive the scope filter. A baseline row whose file is
  # GONE is exactly what this check exists to catch, and it appears in no path list.
  s_case "S4 a baselined file absent from the corpus is still STALE"
  s_run "$BL2" "in/"
  s_eq "baseline_in_scope" "2" "$(s_field "$s_out" baseline_in_scope)"
  s_eq "KNOWN rows"        "1" "$(s_count "$s_out" KNOWN)"
  s_eq "STALE rows"        "1" "$(s_count "$s_out" STALE)"
  s_eq "unmeasured"        "0" "$(s_field "$s_out" unmeasured)"
  s_done

  # S5 -- the fail-open arm. Before the fix this invocation reported a clean
  # summary at exit 0 over a scan that read nothing.
  s_case "S5 a scope resolving to zero readable files is terminal, not a clean zero"
  s_run "$BL1" "empty/"
  s_eq "exit"                    "3"             "$s_exit"
  s_eq "status"                  "not-run"       "$(s_field "$s_out" status)"
  s_eq "state"                   "NOT-EVALUATED" "$(s_field "$s_out" state)"
  s_eq "DENOM rows (suppressed)" "0"             "$(s_count "$s_out" DENOM)"
  s_done

  # S6 -- the same terminal state reached by a typo'd path rather than a directory.
  s_case "S6 a path naming nothing is terminal, not a silent clean run"
  s_run "$BL1" "nope.md"
  s_eq "exit"       "3"             "$s_exit"
  s_eq "status"     "not-run"       "$(s_field "$s_out" status)"
  s_eq "state"      "NOT-EVALUATED" "$(s_field "$s_out" state)"
  s_eq "unreadable" "1"             "$(s_field "$s_out" unreadable)"
  s_done

  # S7 -- a PARTIAL read is in-band. The exit code before and after is compared
  # rather than asserted against a literal, so the arm measures that DEGRADED did
  # not MOVE the exit code -- which is the actual PV-7c obligation.
  s_run "$BL1" "perm/"
  local before_exit="$s_exit" before_status
  before_status="$(s_field "$s_out" status)"
  chmod 000 "$SC/perm/x.md" 2>/dev/null || true
  if head -c 1 "$SC/perm/x.md" >/dev/null 2>&1; then
    chmod 644 "$SC/perm/x.md" 2>/dev/null || true
    skipped=$((skipped + 1))
    echo "  SKIP  [SCOPE] S7 partial-read DEGRADED -- this process can read a chmod-000 file (privileged), so the partial-read state cannot be constructed here. Its evidence is missing, which is not the same as met."
  else
    s_case "S7 a PARTIAL read reports DEGRADED in-band and does not move the exit code"
    s_run "$BL1" "perm/"
    s_eq "status before"                  "fetched"       "$before_status"
    s_eq "status after"                   "degraded"      "$(s_field "$s_out" status)"
    s_eq "state"                          "DEGRADED"      "$(s_field "$s_out" state)"
    s_eq "exit unchanged vs readable run" "$before_exit"  "$s_exit"
    s_eq "unreadable"                     "1"             "$(s_field "$s_out" unreadable)"
    s_eq "unmeasured (never STALE)"       "1"             "$(s_field "$s_out" unmeasured)"
    s_eq "STALE rows"                     "0"             "$(s_count "$s_out" STALE)"
    s_eq "findings still emitted (KNOWN)" "1"             "$(s_count "$s_out" KNOWN)"
    s_done
    chmod 644 "$SC/perm/x.md" 2>/dev/null || true
  fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "--- END" ]]; then
    in_case=0; emit_case; body=""; continue
  fi
  if [[ "$line" == "--- "* && $in_case -eq 0 ]]; then
    read -r _dash expect _class label <<< "$line"
    in_case=1; body=""; continue
  fi
  if [[ $in_case -eq 1 ]]; then body+="$line"$'\n'; fi
done < "$FIXTURES"

run_scope_arm

# A skip is counted and reported SEPARATELY rather than folded into the pass tally.
# A skipped arm is an arm whose evidence is missing, and missing evidence that reads
# as a pass is this check's own failure mode in miniature.
echo "fixtures: $pass/$cases passed, $fail failed, $skipped skipped  ($FIXTURES)"

# A harness that asserted nothing must never report success.
if [[ $cases -eq 0 ]]; then
  echo "INPUT-FAILURE: zero cases parsed — refusing to report a passing harness that ran nothing" >&2
  exit 3
fi
[[ $fail -eq 0 ]] && exit 0 || exit 1

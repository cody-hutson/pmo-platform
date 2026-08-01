#!/usr/bin/env bash
# run-count-structure-fixtures.sh — the Check 62 labeled expected-match harness.
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

pass=0; fail=0; cases=0
expect=""; label=""; body=""; in_case=0

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

echo "fixtures: $pass/$cases passed, $fail failed  ($FIXTURES)"

# A harness that asserted nothing must never report success.
if [[ $cases -eq 0 ]]; then
  echo "INPUT-FAILURE: zero cases parsed — refusing to report a passing harness that ran nothing" >&2
  exit 3
fi
[[ $fail -eq 0 ]] && exit 0 || exit 1

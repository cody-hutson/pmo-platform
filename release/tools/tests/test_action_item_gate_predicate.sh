#!/usr/bin/env bash
set -uo pipefail
# test_action_item_gate_predicate.sh — regression fixtures for the Procedure 7a
# Action-Item Resolution Gate predicate (HARD GATE at Stage 13 close).
#
# WHY THIS EXISTS
#   The predicate is prose-embedded: it lives in a ```bash fence inside
#   release/references/how-to/hub-spoke-bridge.md, so no test runner reaches it
#   by default and it can rot silently. A Stage-7 dev-test found the shipped
#   predicate split the ledger on a BARE pipe, which made a `status: open` row
#   carrying a GFM-escaped `\|` in any earlier free-text column read as terminal
#   — a SILENT PASS of the HARD GATE on an unresolved ledger.
#
#   This suite extracts the fenced block VERBATIM from the doc (never a
#   transcription) and exercises it, so the doc IS the unit under test.
#
# GROUPS
#   (G1) 4-VALUE COVERAGE — the gate's decision table has four states
#        (NOT-RECORDED / EMPTY-LEDGER / RESOLVED / UNRESOLVED). Assert each.
#   (G2) ESCAPED-PIPE SAFETY — the regression this suite was written for. A
#        `\|` in any free-text column ahead of `status` must not shift the
#        column read. Includes the single-row silent-pass case, the multi-row
#        undercount case, and a two-escaped-pipes case.
#   (G3) FALSE-POSITIVE CONTROLS — the defect the column-addressed probe was
#        introduced to fix must stay fixed: a NON-status cell whose content is
#        exactly `open` must not report its row unresolved.
#   (G4) NEGATIVE CONTROL (instrument validation) — assert the bare-pipe FS
#        the fix replaced STILL FAILS the G2 fixture. Without this the suite
#        could drift into passing against a predicate that never split
#        correctly in the first place; it proves the fixtures can detect the
#        defect they are looking for.
#
# Offline + deterministic: fixtures are built in a mktemp dir from the real
# 13-field schema in release/releases/hub-state/action-items.md.template.
# No network, no gh, no writes to any operator-instance path.
#
# Run:  bash release/tools/tests/test_action_item_gate_predicate.sh
# Exit: 0 = all assertions pass, 1 = one or more failed.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd -P)"
BRIDGE="$REPO_ROOT/release/references/how-to/hub-spoke-bridge.md"
TEMPLATE="$REPO_ROOT/release/releases/hub-state/action-items.md.template"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0; FAILURES=()
ok()  { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  FAIL — %s\n' "$1"; }

echo "Procedure 7a action-item gate predicate — regression fixtures"
echo "BRIDGE=$BRIDGE"
echo

# ---------------------------------------------------------------------------
# Extract the predicate VERBATIM. Anchored on the block's first line, not on a
# line number — line numbers rot on every edit above the block.
# ---------------------------------------------------------------------------
PRED="$WORK/predicate.sh"
awk '
  /^AI="\$DIR\/action-items\.md"$/ { grab=1 }
  grab && /^```$/                  { grab=0 }
  grab                             { print }
' "$BRIDGE" > "$PRED"

if [ ! -s "$PRED" ]; then
  echo "  FAIL — could not extract the Procedure 7a predicate from $BRIDGE"
  echo "         (anchor line 'AI=\"\$DIR/action-items.md\"' not found —"
  echo "          the block moved or was renamed; re-point this extractor)"
  exit 1
fi
if ! grep -q 'STATE=NOT-RECORDED' "$PRED" || ! grep -q 'STATE=RESOLVED' "$PRED"; then
  echo "  FAIL — extracted block does not look like the gate predicate:"
  sed 's/^/         /' "$PRED"
  exit 1
fi
echo "extracted $(wc -l < "$PRED" | tr -d ' ') lines from the doc's bash fence"
echo

# ---------------------------------------------------------------------------
# Fixture builders — the real 13-field schema, header taken from the template
# so a schema change breaks these fixtures loudly instead of silently.
# ---------------------------------------------------------------------------
HDR="$(grep -m1 '^| id | created_at |' "$TEMPLATE")"
SEP="$(grep -m1 '^|---|' "$TEMPLATE")"
if [ -z "$HDR" ] || [ -z "$SEP" ]; then
  echo "  FAIL — could not read the 13-field header from $TEMPLATE"; exit 1
fi

# row <id> <description> <status> [trigger_detail]
row() {
  printf '| %s | 2026-07-27T00:00:00Z | Stage 5 | #4064 | reminder | hub | %s | event | %s | file:x.md | %s | - | - |\n' \
         "$1" "$2" "${4:-after Stage 5}" "$3"
}

mkfix() { local d="$WORK/$1"; mkdir -p "$d"; { echo "$HDR"; echo "$SEP"; cat; } > "$d/action-items.md"; echo "$d"; }

# probe <DIR> -> "STATE|TOTAL|UNRES", running the extracted doc block
probe() {
  local DIR="$1" STATE TOTAL UNRES
  STATE=""; TOTAL=0; UNRES=0
  # shellcheck disable=SC1090
  ( DIR="$DIR"; . "$PRED"; printf '%s|%s|%s' "$STATE" "${TOTAL:-0}" "${UNRES:-0}" )
}

expect() {  # expect <label> <DIR> <state> <total> <unres>
  local got; got="$(probe "$2")"
  if [ "$got" = "$3|$4|$5" ]; then ok "$1  [$got]"
  else bad "$1  expected [$3|$4|$5], got [$got]"; fi
}

# ---------------------------------------------------------------------------
echo "G1 — 4-value decision-table coverage"
# ---------------------------------------------------------------------------
expect "state 1: ledger absent -> NOT-RECORDED" "$WORK/no-such-dir" NOT-RECORDED 0 0

D=$(mkfix g1-empty </dev/null)
expect "state 2: header present, 0 AI rows -> EMPTY-LEDGER" "$D" EMPTY-LEDGER 0 0

D=$(mkfix g1-template); cp "$TEMPLATE" "$D/action-items.md"
expect "state 2: pristine template copy -> EMPTY-LEDGER" "$D" EMPTY-LEDGER 0 0

D=$(mkfix g1-resolved <<EOF
$(row AI-001 'plain' done)
$(row AI-002 'plain' cancelled)
$(row AI-003 'plain' superseded)
EOF
)
expect "state 3: 3 rows, none open/in-flight -> RESOLVED" "$D" RESOLVED 3 0

D=$(mkfix g1-open <<EOF
$(row AI-001 'plain' done)
$(row AI-002 'plain' open)
EOF
)
expect "state 4: one open row -> UNRESOLVED" "$D" UNRESOLVED 2 1

D=$(mkfix g1-inflight <<EOF
$(row AI-001 'plain' done)
$(row AI-002 'plain' in-flight)
EOF
)
expect "state 4: one in-flight row -> UNRESOLVED" "$D" UNRESOLVED 2 1

# ---------------------------------------------------------------------------
echo
echo "G2 — escaped-pipe safety (the silent-PASS regression)"
# ---------------------------------------------------------------------------
D=$(mkfix g2-escaped-open <<EOF
$(row AI-010 'route A \| route B' open)
EOF
)
expect "single open row, escaped pipe in description" "$D" UNRESOLVED 1 1

D=$(mkfix g2-control-open <<EOF
$(row AI-010 'route A or route B' open)
EOF
)
expect "CONTROL same row without the escaped pipe" "$D" UNRESOLVED 1 1

D=$(mkfix g2-undercount <<EOF
$(row AI-010 'route A \| route B' open)
$(row AI-011 'plain' open)
EOF
)
expect "two open rows, one escaped -> UNRES must be 2" "$D" UNRESOLVED 2 2

D=$(mkfix g2-two-pipes <<EOF
$(row AI-010 'route A \| route B' open 'fires on X \| Y')
EOF
)
expect "TWO escaped pipes ahead of status" "$D" UNRESOLVED 1 1

D=$(mkfix g2-escaped-terminal <<EOF
$(row AI-010 'route A \| route B' done)
$(row AI-011 'plain' done)
EOF
)
expect "escaped pipe on terminal rows -> RESOLVED (no false +)" "$D" RESOLVED 2 0

D=$(mkfix g2-after-status <<EOF
| AI-001 | 2026-07-27T00:00:00Z | Stage 5 | #4064 | reminder | hub | plain | event | after Stage 5 | file:x.md | open | - | closed A \| closed B |
EOF
)
expect "escaped pipe AFTER status (resolution column)" "$D" UNRESOLVED 1 1

# ---------------------------------------------------------------------------
echo
echo "G3 — false-positive controls (the defect column-addressing fixed)"
# ---------------------------------------------------------------------------
D=$(mkfix g3-trigger-open <<EOF
$(row AI-001 'plain' done 'open')
$(row AI-002 'plain' done)
EOF
)
expect "trigger_detail is exactly 'open', status done -> RESOLVED" "$D" RESOLVED 2 0

D=$(mkfix g3-prose <<EOF
$(row AI-001 'left open and in-flight by design' done)
EOF
)
expect "description prose says 'open'/'in-flight' -> RESOLVED" "$D" RESOLVED 1 0

# ---------------------------------------------------------------------------
echo
echo "G4 — negative control (instrument validation)"
# ---------------------------------------------------------------------------
# The predicate MUST split on ' | ', not on a bare '|'. Assert the replaced
# bare-pipe form still MIS-reads the G2 fixture — proving these fixtures can
# actually detect the defect, rather than passing vacuously.
BARE="$(awk -F'|' '
    $2 ~ /^ *AI-[0-9]+ *$/ { t++; gsub(/ /,"",$12);
                             if ($12=="open" || $12=="in-flight") u++ }
    END { print (t+0)"/"(u+0) }' "$WORK/g2-escaped-open/action-items.md")"
if [ "$BARE" = "1/0" ]; then
  ok "bare-pipe FS still mis-reads the escaped row (got $BARE) — fixture is load-bearing"
else
  bad "negative control did not reproduce: bare-pipe FS gave $BARE, expected 1/0"
fi

# And assert the SHIPPED predicate genuinely uses the bracketed delimiter.
if grep -q "awk -F' \[|\] '" "$PRED"; then
  ok "shipped predicate splits on ' [|] ' (space, bracketed pipe, space)"
else
  bad "shipped predicate no longer splits on ' [|] ' — re-verify the FS spelling"
fi
# ' \| ' is NOT a safe spelling: awk escape-processes the -F value, reducing
# \| to a bare | (ERE alternation), which splits the row on every space.
if grep -qE "awk -F' \\\\\| '" "$PRED"; then
  bad "predicate uses -F' \\| ' — awk reduces this to ERE alternation; use ' [|] '"
else
  ok "predicate avoids the unsafe -F' \\| ' spelling"
fi

# ---------------------------------------------------------------------------
echo
echo "========================================================================"
printf 'passed: %d   failed: %d\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf '\nfailures:\n'; for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
  exit 1
fi
echo "ALL ASSERTIONS PASS"
exit 0

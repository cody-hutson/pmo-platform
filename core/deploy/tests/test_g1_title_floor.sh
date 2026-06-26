#!/usr/bin/env bash
# test_g1_title_floor.sh — regression net for the deploy.sh Check 22 G1-01
# title-informativeness floor (#545).
#
# What this proves: the G1-01 floor in deploy.sh Check 22 is a SYNTACTIC floor —
# it rejects (a) a leftover "[...]:" type/category prefix and (b) a bare
# area-slug / single-token / too-short title, and it PASSES any well-formed
# multi-word summary. It is NOT and cannot be an informativeness classifier: a
# vague-but-well-formed title ("Update the gate") passes the floor by design.
# The informativeness BAR lives in intake-style-guide.md §7 + intake-desk
# elicitation (judgment), NOT in this gate. This test asserts the floor's TRUE
# (thin) discrimination — including the adversarial middle the gate deliberately
# lets through — so no future reader mistakes the floor for a semantic gate.
#
# Hermetic-by-construction: the floor predicate is pure string logic (no `gh`,
# no live tracker, no network). This test re-implements the EXACT predicate from
# deploy.sh's Check 22 G1-01 block and pins it against a fixture table, then
# greps deploy.sh to assert the live predicate still matches this test's copy
# (drift guard) — so a silent edit to the gate regex fails this test.
#
# The two crafted fixtures the card requires:
#   F-pass: a clean informative summary  -> 0 findings (PASS)
#   F-fail: a "[Category]:" bracket title -> 1 finding  (FAIL)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"

PASS_COUNT=0
FAIL_COUNT=0

# ── The floor predicate under test — a faithful copy of the deploy.sh Check 22
#    G1-01 block (kept in lock-step via the drift guard below). Returns 0 (title
#    OK, no finding) or 1 (title FAILS the floor). G1_TITLE_MIN_CHARS honored.
g1_title_floor_ok() {
  local _title="$1"
  # F1 — no leading bracket type/category prefix
  if printf '%s' "$_title" | /usr/bin/grep -qE '^[[:space:]]*\[[^]]+\]:[[:space:]]'; then
    return 1
  # F2 — substance floor: bare slug (no internal whitespace) => FAIL
  elif ! printf '%s' "$_title" | /usr/bin/grep -qE '[^[:space:]]+[[:space:]]+[^[:space:]]+'; then
    return 1
  # F3 — too short
  elif [[ "${#_title}" -lt "${G1_TITLE_MIN_CHARS:-12}" ]]; then
    return 1
  fi
  return 0
}

# assert_floor <expected: PASS|FAIL> <title> <note>
assert_floor() {
  local _expected="$1" _title="$2" _note="$3" _got
  if g1_title_floor_ok "$_title"; then _got="PASS"; else _got="FAIL"; fi
  if [[ "$_got" == "$_expected" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   [%s] %-72s  %s\n' "$_got" "${_title:0:72}" "$_note"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL want=%s got=%s  title=%q  (%s)\n' "$_expected" "$_got" "$_title" "$_note"
  fi
}

echo "── Check 22 G1-01 title-floor: required fixtures ─────────────────────────"
# F-pass (clean informative summary) -> 0 findings
assert_floor PASS "Cache the issue-list query in the bundle parser" "F-pass fixture (card deliverable)"
# F-fail (bracket prefix) -> 1 finding
assert_floor FAIL "[Category]: cache the query" "F-fail fixture (card deliverable)"

echo ""
echo "── True-positive PASS cases (informative multi-word summaries) ───────────"
assert_floor PASS "Make work-item titles human-informative — drop the redundant type prefix" "design good example"
assert_floor PASS "Fix deploy.sh CHANGED_PACKAGES unbound variable on empty package set" "specific + multi-word"
assert_floor PASS "Fix the RAID log export" "23ch concise-but-informative (12-floor must PASS, 24-floor over-rejected)"
assert_floor PASS "Fix RAID export" "15ch concise true-positive"

echo ""
echo "── Bracket-prefix FAIL cases (F1) ───────────────────────────────────────"
assert_floor FAIL "[Category]: Make titles human-informative" "[Category]: prefix"
assert_floor FAIL "[Bug]: deploy.sh fails on empty package set" "[Bug]: prefix"
assert_floor FAIL "[Observation]: titles are uninformative" "[Observation]: prefix"
assert_floor FAIL "[Skill Update]: intake-desk elicits to the rubric" "multi-word bracket prefix"

echo ""
echo "── Slug / single-token / too-short FAIL cases (F2/F3) ────────────────────"
assert_floor FAIL "intake-desk" "bare area-slug (one token)"
assert_floor FAIL "repurpose-gate-g1-01-as-informativeness-floor" "long hyphenated slug, no spaces"
assert_floor FAIL "Fix bug" "7ch too short (below 12)"

echo ""
echo "── HONEST-LIMIT cases: the floor is SYNTACTIC, not semantic ──────────────"
echo "   (These vague-but-well-formed titles PASS the floor BY DESIGN. The"
echo "    informativeness bar is the §7 rubric + intake-desk, NOT this gate.)"
assert_floor PASS "Update the gate" "design's OWN canonical BAD title — floor cannot catch it; §7 rubric does"
assert_floor PASS "Various small fixes" "classic uninformative — passes floor (semantic, not syntactic)"
assert_floor PASS "Address PR feedback" "uninformative — passes floor"
assert_floor PASS "Misc cleanup tasks" "uninformative — passes floor"

echo ""
echo "── Drift guard: live deploy.sh predicate matches this test's copy ────────"
# Assert the three load-bearing predicate fragments still exist verbatim in the
# Check 22 G1-01 block, so a silent regex edit can't pass this test stale.
DRIFT_OK=true
for _frag in \
  '\^\[\[:space:\]\]\*\\\[\[\^]\]\+\\\]:\[\[:space:\]\]' \
  'G1_TITLE_MIN_CHARS:-12' \
  'title not an informative summary'
do
  if ! /usr/bin/grep -qE "$_frag" "$DEPLOY_SH"; then
    DRIFT_OK=false
    printf '  FAIL drift: fragment not found in deploy.sh -> %s\n' "$_frag"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done
if [[ "$DRIFT_OK" == "true" ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   live deploy.sh Check 22 G1-01 predicate fragments present"
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf 'Result: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "G1-01 title-floor regression: FAILED"
  exit 1
fi
echo "G1-01 title-floor regression: PASSED"
exit 0

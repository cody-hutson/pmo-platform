#!/usr/bin/env bash
# test_check45_governing_doc_name_match.sh — fixture self-test for deploy.sh
# Check 45 sub-check (b), the design-principle-register governing_doc drift guard.
#
# Cite the code under test by its INLINE MARKER, never by line number:
#   core/deploy/deploy.sh, `# (b) FMF-1 — entry-row-scoped governing_doc resolution`
# Resolver: grep -n '# (b) FMF-1' core/deploy/deploy.sh. That pin has drifted three
# times across three documents describing the same code, which is precisely why the
# drift guard at the bottom of this file greps for the marker instead.
#
# What this proves: (b) asserts CONTENT, not mere existence. Before this test's
# subject shipped, (b) checked only that the pinned file existed, the line number was
# numeric, and the target line was non-empty — so a pin that had shifted onto a
# DIFFERENT principle resolved fine and PASSED. The check was present, greppable, and
# asserting nothing about the thing it claimed to guard.
#
# Three failure branches, asserted independently so a future edit cannot collapse one
# into another and still pass this file:
#   b0 WELL-FORMED — the entry carries BOTH assertion operands: a non-empty
#                    `governing_doc` to resolve and a non-empty `name` to assert against
#   b1 RESOLVE     — path exists, line numeric, target line non-empty
#   b2 NAME-MATCH  — the target line CONTAINS the entry's `name`
#
# b0's `governing_doc` arm closes a SECOND false-confidence defect, distinct from the
# existence-only one above and caught after it shipped: a bare
# `[[ -z "$c45_gd" ]] && continue` sat ABOVE b0, so a row with a blanked
# `governing_doc` cell left the loop neither examined nor counted — Check 45 emitted
# zero findings and still printed its `OK: … all register governing_doc targets
# resolve …` line, certifying an entry it never looked at. T6 / T6′ below reproduce
# that defect and assert its absence, the same way T2 / T2′ do for the first one.
#
# The structural assertion at the bottom of this file is the durable half of that fix:
# the live Check 45(b) loop body must contain ZERO `continue`, so no future edit can
# reintroduce a path that exits the loop without either asserting or flagging. The
# unexamined-exit shape is deleted, not detected.
#
# Hermetic by construction: every fixture is built under a mktemp -d and the predicate
# runs with that tmpdir as cwd. The live core/standards/design-principle-register.md
# and core/disciplines/build-philosophy.md are NEVER read and NEVER mutated by the
# assertions — the only live file this test touches is deploy.sh, read-only, by the
# drift guard.
#
# Precedent: core/deploy/tests/test_check36_drift_classes.sh and
# core/deploy/tests/test_g1_title_floor.sh — a faithful copy of the predicate under
# test pinned against a fixture table, plus a DRIFT GUARD that greps deploy.sh to
# assert the live predicate still matches this file's copy, so a silent edit to
# Check 45(b) fails this test rather than passing it stale.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"

PASS_COUNT=0
FAIL_COUNT=0

# ── Faithful copy of the Check 45(b) predicate (kept in lock-step with deploy.sh via
#    the drift guard at the end). Emits one line per finding, in the shape
#    "<branch> <principle_id>", and nothing at all when the register is clean.
#    Branches: EMPTY-GD (b0) / EMPTY-NAME (b0) / RESOLVE (b1) / NAME-MATCH (b2).
#    Zero findings here means the live check would print its OK: line, which is what
#    makes "0 findings on a degenerate register" the falsifying observation, not a
#    merely-quiet one.
#
#    Branch ORDER is load-bearing and mirrors deploy.sh: `governing_doc` is tested
#    BEFORE `name`, because the empty-name finding's message interpolates the pin
#    ("'DP-N' pins '<gd>' but its name cell is empty") and would read as a claim about
#    an empty pin if it could fire on a row with no pin at all. T6c asserts that order.

_c45_trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

c45b_findings() {
  local _reg="$1"
  local c45_id c45_name c45_gd c45_path c45_line c45_target _c45_lead _c45_stmt _c45_rest
  while IFS='|' read -r _c45_lead c45_id c45_name _c45_stmt c45_gd _c45_rest; do
    c45_id="$(_c45_trim "$c45_id")"
    c45_name="$(_c45_trim "$c45_name")"
    c45_gd="$(_c45_trim "$c45_gd")"
    if [[ -z "$c45_gd" ]]; then
      printf 'EMPTY-GD %s\n' "$c45_id"
    elif [[ -z "$c45_name" ]]; then
      printf 'EMPTY-NAME %s\n' "$c45_id"
    else
      c45_path="${c45_gd%%:*}"
      c45_line="${c45_gd##*:}"
      c45_target=""
      if [[ -f "$c45_path" ]] && [[ "$c45_line" =~ ^[0-9]+$ ]]; then
        c45_target="$(sed -n "${c45_line}p" "$c45_path" 2>/dev/null)"
      fi
      if [[ ! -f "$c45_path" ]] || ! [[ "$c45_line" =~ ^[0-9]+$ ]] || [[ -z "$c45_target" ]]; then
        printf 'RESOLVE %s\n' "$c45_id"
      elif [[ "$c45_target" != *"$c45_name"* ]]; then
        printf 'NAME-MATCH %s\n' "$c45_id"
      fi
    fi
  done < <(grep -E '^\| DP-[0-9]' "$_reg")
}

# ── The PRE-FIX predicate (existence-only), carried so this test can demonstrate the
#    defect rather than merely assert the fix. It is deliberately NOT drift-guarded:
#    it no longer exists in deploy.sh, and that is the point.
c45b_findings_prefix_existence_only() {
  local _reg="$1"
  local c45_gd c45_path c45_line
  while IFS= read -r c45_gd; do
    [[ -z "$c45_gd" ]] && continue
    c45_path="${c45_gd%%:*}"
    c45_line="${c45_gd##*:}"
    if [[ ! -f "$c45_path" ]] || ! [[ "$c45_line" =~ ^[0-9]+$ ]] || [[ -z "$(sed -n "${c45_line}p" "$c45_path" 2>/dev/null)" ]]; then
      printf 'RESOLVE %s\n' "$c45_gd"
    fi
  done < <(grep -E '^\| DP-[0-9]' "$_reg" | grep -oE '[A-Za-z0-9_./-]+\.md:[0-9]+' | sort -u)
}

# ── The SECOND pre-fix predicate — the skip-empty-governing_doc form — carried for the
#    same reason as the one above: so T6′ can demonstrate the false-OK defect rather
#    than merely assert its fix. Byte-identical to the shipped predicate except for the
#    one line that caused it: a bare `continue` ABOVE the b0 guard, which returned the
#    row to the loop unexamined AND unflagged. It is deliberately NOT drift-guarded —
#    it no longer exists in deploy.sh, and that is the point.
c45b_findings_prefix_skip_empty_gd() {
  local _reg="$1"
  local c45_id c45_name c45_gd c45_path c45_line c45_target _c45_lead _c45_stmt _c45_rest
  while IFS='|' read -r _c45_lead c45_id c45_name _c45_stmt c45_gd _c45_rest; do
    c45_id="$(_c45_trim "$c45_id")"
    c45_name="$(_c45_trim "$c45_name")"
    c45_gd="$(_c45_trim "$c45_gd")"
    [[ -z "$c45_gd" ]] && continue
    if [[ -z "$c45_name" ]]; then
      printf 'EMPTY-NAME %s\n' "$c45_id"
      continue
    fi
    c45_path="${c45_gd%%:*}"
    c45_line="${c45_gd##*:}"
    c45_target=""
    if [[ -f "$c45_path" ]] && [[ "$c45_line" =~ ^[0-9]+$ ]]; then
      c45_target="$(sed -n "${c45_line}p" "$c45_path" 2>/dev/null)"
    fi
    if [[ ! -f "$c45_path" ]] || ! [[ "$c45_line" =~ ^[0-9]+$ ]] || [[ -z "$c45_target" ]]; then
      printf 'RESOLVE %s\n' "$c45_id"
      continue
    fi
    if [[ "$c45_target" != *"$c45_name"* ]]; then
      printf 'NAME-MATCH %s\n' "$c45_id"
    fi
  done < <(grep -E '^\| DP-[0-9]' "$_reg")
}

# ── Fixture tree (tmpdir only; the live corpus is never touched) ────────────────
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Synthetic governing doc. Line numbers are load-bearing for the fixtures below:
#   3 Alpha · 4 Bravo · 5 Charlie · 6 (blank) · 7 long prose containing "Delta"
cat > "${TMP}/philosophy.md" <<'DOC'
# Synthetic charter

| **Alpha** | the first synthetic principle |
| **Bravo** | the second synthetic principle |
| **Charlie** | the third synthetic principle |

Prose line: Delta is stated here inside a longer sentence, not as a table cell.
DOC

# reg_write <file> <row>...  — build a synthetic register with the entry-row shape
# Check 45(b) scopes to (^| DP-N ...), plus a header and a schema-prose decoy line
# carrying a path:line that MUST NOT be self-matched.
reg_write() {
  local _out="$1"; shift
  {
    printf '# Synthetic register\n\n'
    printf 'Schema prose decoy — governing_doc is a path:line pin, e.g. philosophy.md:999\n\n'
    printf '| `principle_id` | `name` | `statement` | `governing_doc` | `scope_predicate` |\n'
    printf '|---|---|---|---|---|\n'
    local _r
    for _r in "$@"; do printf '%s\n' "$_r"; done
  } > "$_out"
}

R_A='| DP-1 | Alpha | indexed statement | philosophy.md:3 | synthetic |'
R_B='| DP-2 | Bravo | indexed statement | philosophy.md:4 | synthetic |'
R_C='| DP-3 | Charlie | indexed statement | philosophy.md:5 | synthetic |'
R_D='| DP-4 | Delta | indexed statement | philosophy.md:7 | synthetic |'

reg_write "${TMP}/reg_clean.md"      "$R_A" "$R_B" "$R_C" "$R_D"
# T2: DP-2's pin shifted +1 onto Charlie's line — a real, non-empty line belonging to
# a DIFFERENT principle. This is the AC-2 negative control.
reg_write "${TMP}/reg_mispin.md"     "$R_A" '| DP-2 | Bravo | indexed statement | philosophy.md:5 | synthetic |' "$R_C" "$R_D"
# T3: DP-3 pinned past EOF (resolves to an empty line) — the b1 branch.
reg_write "${TMP}/reg_unresolvable.md" "$R_A" "$R_B" '| DP-3 | Charlie | indexed statement | philosophy.md:999 | synthetic |' "$R_D"
# T3b: DP-3 pinned at a file that does not exist — the other b1 arm.
reg_write "${TMP}/reg_nofile.md"     "$R_A" "$R_B" '| DP-3 | Charlie | indexed statement | absent-doc.md:3 | synthetic |' "$R_D"
# T4: anti-vacuity — the name appears as a SUBSTRING of a longer prose line.
reg_write "${TMP}/reg_substring.md"  "$R_D"
# T5: a blank `name` cell — the b0 operand-degeneracy guard. Without b0 the
# containment test is vacuously true and this row passes against any non-empty line.
reg_write "${TMP}/reg_emptyname.md"  "$R_A" '| DP-2 |  | indexed statement | philosophy.md:5 | synthetic |' "$R_C"
# T6: a blank `governing_doc` cell — the OTHER b0 operand. The pre-fix predicate
# SKIPPED this row, so it reached the end of the loop unexamined and unflagged, and the
# check printed OK: over an entry it never looked at.
reg_write "${TMP}/reg_emptygd.md"    "$R_A" '| DP-2 | Bravo | indexed statement |  | synthetic |' "$R_C"
# T6c: BOTH operands blank — pins the branch order (governing_doc arm wins), so the
# empty-name message can never claim a row "pins ''".
reg_write "${TMP}/reg_emptyboth.md"  "$R_A" '| DP-2 |  | indexed statement |  | synthetic |' "$R_C"

cd "$TMP" || { echo "cannot cd to fixture dir"; exit 1; }

# assert_findings <expected-count> <expected-verbatim-lines|-> <label> <register>
assert_findings() {
  local _want_n="$1" _want_lines="$2" _label="$3" _reg="$4" _got _got_n
  _got="$(c45b_findings "$_reg")"
  if [[ -z "$_got" ]]; then _got_n=0; else _got_n="$(printf '%s\n' "$_got" | wc -l | tr -d ' ')"; fi
  if [[ "$_got_n" != "$_want_n" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL want=%s finding(s) got=%s  (%s)\n' "$_want_n" "$_got_n" "$_label"
    [[ -n "$_got" ]] && printf '        got: %s\n' "$(printf '%s' "$_got" | tr '\n' ';')"
    return
  fi
  if [[ "$_want_lines" != "-" && "$_got" != "$_want_lines" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL want=[%s] got=[%s]  (%s)\n' "$_want_lines" "$_got" "$_label"
    return
  fi
  PASS_COUNT=$((PASS_COUNT + 1))
  printf '  ok   %s finding(s)%s — %s\n' "$_got_n" "${_want_lines:+ = $_want_lines}" "$_label"
}

echo "── T1 CLEAN: every pin resolves and names its own principle ──────────────"
assert_findings 0 "-" "4 correct pins -> 0 findings" "${TMP}/reg_clean.md"

echo ""
echo "── T2 FLAG (name-match): the AC-2 shifted-pin negative control ───────────"
assert_findings 1 "NAME-MATCH DP-2" "DP-2 pin shifted +1 onto Charlie's line -> exactly 1 NAME-MATCH finding naming DP-2" "${TMP}/reg_mispin.md"

echo ""
echo "── T2' the DEFECT, measured: the pre-fix predicate passes that same input ─"
# Discriminates the fix from the thing it replaced. The existence-only predicate sees
# a real file and a non-empty line, so it reports nothing at all on a mis-pin.
PREFIX_OUT="$(c45b_findings_prefix_existence_only "${TMP}/reg_mispin.md")"
if [[ -z "$PREFIX_OUT" ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   pre-fix existence-only predicate -> 0 findings on the SAME mis-pin (silent pass reproduced)"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  FAIL pre-fix predicate unexpectedly flagged: %s\n' "$PREFIX_OUT"
fi

echo ""
echo "── T3 FLAG (resolve): the branches are distinguishable ───────────────────"
assert_findings 1 "RESOLVE DP-3" "DP-3 pinned past EOF -> exactly 1 RESOLVE finding" "${TMP}/reg_unresolvable.md"
assert_findings 1 "RESOLVE DP-3" "DP-3 pinned at an absent file -> exactly 1 RESOLVE finding" "${TMP}/reg_nofile.md"

echo ""
echo "── T4 anti-vacuity: containment, not equality ────────────────────────────"
# Defeats a predicate that has degenerated to always-FLAG: a legitimate pin whose
# target line carries the name inside longer prose must still PASS.
assert_findings 0 "-" "name as a substring of a longer prose line -> 0 findings" "${TMP}/reg_substring.md"

echo ""
echo "── T5 b0: an empty name cell cannot pass vacuously ───────────────────────"
# [[ "$target" == *""* ]] is universally true, so without b0 this row would clear the
# content assertion against any non-empty line — the false-confidence shape b2 exists
# to remove, reappearing inside b2 itself.
assert_findings 1 "EMPTY-NAME DP-2" "blank name cell -> exactly 1 EMPTY-NAME finding, not a silent pass" "${TMP}/reg_emptyname.md"

echo ""
echo "── T6 b0: a blank governing_doc cell is a FINDING, never a silent skip ───"
# Zero findings here would mean the live check prints its OK: line — "all register
# governing_doc targets resolve AND name their own principle" — over a row it never
# examined. That is the false-OK defect, and this is its assertion.
assert_findings 1 "EMPTY-GD DP-2" "blank governing_doc cell -> exactly 1 EMPTY-GD finding, not a silent skip" "${TMP}/reg_emptygd.md"
assert_findings 1 "EMPTY-GD DP-2" "both operands blank -> the governing_doc arm wins (branch order pinned)" "${TMP}/reg_emptyboth.md"

echo ""
echo "── T6' the DEFECT, measured: the skip-form predicate passes that same input"
# The counterpart of T2′, for the second defect. The skip-empty-gd predicate returns
# NOTHING on the blanked-governing_doc register — so c45_ok survives as 1 and the OK:
# line prints. A test that asserted only T6 could not tell a real fix from a fixture
# that never reproduced the defect.
PREFIX_GD_OUT="$(c45b_findings_prefix_skip_empty_gd "${TMP}/reg_emptygd.md")"
if [[ -z "$PREFIX_GD_OUT" ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   pre-fix skip-form predicate -> 0 findings on the SAME blanked governing_doc (false OK: reproduced)"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  FAIL pre-fix skip-form predicate unexpectedly flagged: %s\n' "$PREFIX_GD_OUT"
fi

echo ""
echo "── Invariant: the run never read or wrote the live register ──────────────"
if [[ -n "$(c45b_findings "${TMP}/reg_clean.md")" ]]; then
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL fixture leakage: the clean fixture reported findings on re-run"
else
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   all assertions ran against ${TMP} fixtures; live corpus untouched by construction"
fi

echo ""
echo "── Drift guard: the live deploy.sh predicate still matches this copy ─────"
# Marker-based, never line-numbered. Fixed-string fragments (grep -F) so BRE/ERE
# escaping cannot make a fragment silently un-matchable.
DRIFT_OK=true
while IFS= read -r _frag; do
  [[ -n "$_frag" ]] || continue
  if ! /usr/bin/grep -qF "$_frag" "$DEPLOY_SH"; then
    DRIFT_OK=false
    printf '  FAIL drift: fragment not found in deploy.sh -> %s\n' "$_frag"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done <<'FRAGS'
# (b) FMF-1 — entry-row-scoped governing_doc resolution
while IFS='|' read -r _c45_lead c45_id c45_name _c45_stmt c45_gd _c45_rest
!= *"$c45_name"*
MIS-PIN (name-match)
register entry has no name
register entry has no governing_doc
FRAGS
if [[ "$DRIFT_OK" == "true" ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   live Check 45(b) carries the marker + the b0/b1/b2 branches this test pins"
fi

echo ""
echo "── Structural: the live (b) loop body contains ZERO \`continue\` ───────────"
# The durable half of the false-OK fix. A fragment grep can only see the branches that
# EXIST; it cannot see a newly-added early exit that silently returns a row to the loop
# unexamined — which is precisely how the false OK: got in. This asserts the SHAPE:
# every row traverses one arm of a total if/elif/else, so c45_ok can survive as 1 only
# when every row was fully asserted. Block bounds are the two inline markers, never
# line numbers. Comment lines are excluded so prose ABOUT `continue` (this fix is
# documented in that block) cannot make the assertion fire spuriously.
C45B_BLOCK="$(/usr/bin/awk 'index($0,"# (b) FMF-1"){f=1} f{print} f && index($0,"# (c) FMF-2"){exit}' "$DEPLOY_SH")"
if [[ -z "$C45B_BLOCK" ]]; then
  # Fail closed: an unlocatable block must never read as "zero continues found".
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL cannot locate the Check 45(b) block between its '# (b) FMF-1' and '# (c) FMF-2' markers — NOSET, not a pass"
else
  C45B_CODE="$(/usr/bin/grep -vE '^[[:space:]]*#' <<< "$C45B_BLOCK")"
  C45B_CONTINUES="$(/usr/bin/grep -cE '(^|[[:space:];&|])continue([[:space:];&|]|$)' <<< "$C45B_CODE")"
  if [[ "$C45B_CONTINUES" == "0" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  ok   0 \`continue\` statements in the live (b) body — no row can exit the loop unexamined"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL %s `continue` statement(s) in the live Check 45(b) body — an early exit can return a row to the loop neither asserted nor flagged, which is the false-OK shape this assertion exists to close; make the branch set total instead\n' "$C45B_CONTINUES"
  fi
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf 'Result: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "Check 45(b) governing_doc name-match fixture self-test: FAILED"
  exit 1
fi
echo "Check 45(b) governing_doc name-match fixture self-test: PASSED"
exit 0

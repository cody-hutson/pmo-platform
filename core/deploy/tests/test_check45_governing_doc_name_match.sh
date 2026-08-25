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
# The structural assertions at the bottom of this file are the durable half of that fix.
# They are BLOCK-SCOPED: every one of them runs against the marker-bounded (b) region
# extracted from deploy.sh, never against the whole file. That scoping is the fix for a
# THIRD false-confidence defect, and it is the reason this file's guard is shaped the way
# it is. The drift guard used to match each pinned fragment against all 14k lines of
# deploy.sh, so a pin was satisfied by ANY occurrence anywhere — and the (b) loop's input
# selector `grep -E '^| DP-[0-9]' "$c45_reg"` occurs TWICE, once as (b)'s input and once
# inside sub-check (c). Pinning it whole-file was therefore satisfied by the OTHER
# occurrence: repointing (b)'s input made the live check iterate an empty population and
# print its `OK:` line while every fragment still resolved. Measured, not inferred — the
# whole-file pin was built and the mutation still passed. Scoping the match to the block
# makes each pin an assertion about the code it claims to guard.
#
# The durable assertions, in the order they run:
#   1. EXTRACTION POSTCONDITION — the block's last line carries the `# (c) FMF-2`
#      terminator, and the block's extent is within a stated band. An unlocatable OPENING
#      marker yields an empty block and fails closed; an unlocatable TERMINATOR does NOT
#      (awk simply runs to EOF), so emptiness alone is only half a guard. Without the
#      postcondition, renaming the terminator silently widens the block to the remainder
#      of the file and restores the exact whole-file ambiguity above.
#   2. DRIFT GUARD — every pinned fragment resolves INSIDE that block, and every
#      finding-emitting line in the block is covered by some pin (so a new branch cannot
#      be added unpinned, and no arm can be deleted silently).
#   3. SELECTOR LIVENESS — the live input selector is extracted and RUN, against a
#      sensitivity arm, a specificity arm, and the live register. A pin proves a string
#      exists; only running it proves it still selects the subject.
#   4. TWO-SITE PARITY — (b)'s selector and (c)'s register-side selector are byte-
#      identical, so the duplicated predicate cannot drift apart on one side.
#   5. ZERO `continue` — the live (b) loop body must contain no `continue`, so no future
#      edit can reintroduce a path that exits the loop without either asserting or
#      flagging. The unexamined-exit shape is deleted, not detected.
#   6. PAIRING INVARIANT — every `flag_warn_or_issue` in the block is matched by a
#      `c45_ok=0`, so a branch cannot flag a finding and still let the `OK:` line print.
#
# Falsification is RUN, not asserted. The harness at the bottom mutates each pinned
# fragment in turn against a throwaway copy of deploy.sh and requires the suite to fail
# with THAT pin's named message — exit code alone is not accepted as evidence a specific
# pin bit. Its mutation set is DERIVED from the pin set, so a fragment cannot be added
# without being falsification-tested. It runs by DEFAULT, on every invocation including
# the CI one; only its own child invocations short-circuit it (PMO_C45_FALSIFY_CHILD).
#
# Hermetic where it matters: every fixture is built under a mktemp -d and the predicate
# runs with that tmpdir as cwd. NO live file is ever WRITTEN or MUTATED. Two live files
# are READ, read-only, and both reads are load-bearing: deploy.sh (the subject of every
# structural assertion) and core/standards/design-principle-register.md (the subject
# Check 45(b) actually guards — read solely to assert the live selector still selects a
# non-empty population from it). Its CONTENT is never asserted, only that the selector
# is not dead against it, so a legitimate register edit can never break this test.
#
# Precedent: core/deploy/tests/test_check36_drift_classes.sh and
# core/deploy/tests/test_g1_title_floor.sh — a faithful copy of the predicate under
# test pinned against a fixture table, plus a DRIFT GUARD that greps deploy.sh to
# assert the live predicate still matches this file's copy, so a silent edit to
# Check 45(b) fails this test rather than passing it stale.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DEPLOY_SH is overridable so the falsification harness at the bottom can re-invoke this
# same suite against a MUTATED copy of deploy.sh. Nothing else sets it; the default is
# the live file, so an ordinary run is unchanged.
DEPLOY_SH="${DEPLOY_SH:-${SCRIPT_DIR}/../deploy.sh}"
# Absolute self-path, captured BEFORE the `cd "$TMP"` below, so the harness can re-invoke
# this file from inside the fixture dir.
SELF="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"
# The live subject Check 45(b) guards. Read-only, and read for exactly one purpose: to
# assert the live selector still selects a non-empty population from it.
LIVE_REGISTER="${SCRIPT_DIR}/../../standards/design-principle-register.md"
# Set only by this file's own falsification children, to short-circuit the harness so a
# mutant run cannot re-enter it. A parent run never sets it.
FALSIFY_CHILD="${PMO_C45_FALSIFY_CHILD:-0}"

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
# Check 45(b) scopes to (^| DP-N ...), plus a header and THREE decoy lines that the
# entry-row selector must not match. Called with NO rows it yields the specificity
# fixture: a register whose only DP-bearing lines are decoys.
#
# The decoys are chosen to defeat the two ways the selector can be LOOSENED, and each
# targets a different anchor:
#   - the path:line decoy defeats a selector that matched governing_doc pins anywhere;
#   - the bare-id decoy carries `DP-N` off-row, so dropping the `^| ` prefix entirely
#     (to a bare `DP-[0-9]`) starts matching it;
#   - the row-shape decoy carries a literal `| DP-N` MID-LINE, so dropping only the `^`
#     anchor (to `\| DP-[0-9]`) starts matching it.
# Without the last two, a loosened selector selects 0 on this fixture and the specificity
# arm passes vacuously — the arm would assert nothing. Both are realistic register prose.
reg_write() {
  local _out="$1"; shift
  {
    printf '# Synthetic register\n\n'
    printf 'Schema prose decoy — governing_doc is a path:line pin, e.g. philosophy.md:999\n'
    printf 'Bare-id prose decoy — DP-1 is the first principle; ids are referenced in prose too\n'
    printf 'Row-shape prose decoy — an entry line reads `| DP-1 | Alpha | statement | philosophy.md:3 | synthetic |`\n\n'
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
# The specificity fixture for the selector-liveness arm below: header + separator + the
# three decoys, and ZERO entry rows. The correct selector must select nothing here.
reg_write "${TMP}/reg_decoy.md"

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
echo "── Invariant: the predicate assertions ran against fixtures only ─────────"
# Scope note, because this file's live reads grew and the claim must stay exact: every
# PREDICATE assertion above runs against ${TMP} fixtures. The structural assertions below
# read two live files — deploy.sh and the design-principle register — and both reads are
# strictly read-only. Nothing in this file ever WRITES outside ${TMP}.
if [[ -n "$(c45b_findings "${TMP}/reg_clean.md")" ]]; then
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL fixture leakage: the clean fixture reported findings on re-run"
else
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   all predicate assertions ran against ${TMP} fixtures; no live file is written"
fi

echo ""
echo "── Extraction: locate the live (b) block, and ASSERT its bounds ──────────"
# Every assertion below this line is scoped to this extraction, so the extraction is now
# the trust anchor for the whole guard — and an unasserted trust anchor is exactly the
# defect this file exists to close, one level up. Emptiness is only HALF a guard: awk
# fails to find the OPENING marker by returning nothing, but it fails to find the
# TERMINATOR by running to EOF, which yields a large NON-empty block. So the extraction
# carries its own postconditions.
C45B_OK=false
C45B_BLOCK="$(/usr/bin/awk 'index($0,"# (b) FMF-1"){f=1} f{print} f && index($0,"# (c) FMF-2"){exit}' "$DEPLOY_SH")"
# Stated band, not a byte-exact pin: an ordinary edit to the (b) branch set moves the
# extent by a few lines and must not fail; losing the terminator moves it by thousands.
# The band is wide enough to absorb the former and narrow enough to catch the latter.
C45B_MIN_LINES=20
C45B_MAX_LINES=200
if [[ -z "$C45B_BLOCK" ]]; then
  # Fail closed on a missing OPENING marker: an unlocatable block must never read as
  # "all fragments resolved" or as "zero continues found".
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL cannot locate the Check 45(b) block between its '# (b) FMF-1' and '# (c) FMF-2' markers — NOSET, not a pass"
else
  C45B_LINES="$(/usr/bin/wc -l <<< "$C45B_BLOCK" | tr -d ' ')"
  C45B_LAST="${C45B_BLOCK##*$'\n'}"
  if [[ "$C45B_LAST" != *"# (c) FMF-2"* ]]; then
    # Fail closed on a missing TERMINATOR. The awk exits ON the terminator line, so that
    # line is the block's last by construction — unless the marker was renamed or moved,
    # in which case awk ran to EOF and the block silently widened to the remainder of the
    # file, restoring the whole-file ambiguity every pin below was scoped to remove.
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL the extracted (b) block does not TERMINATE on its '"'"'# (c) FMF-2'"'"' marker — it ran to EOF and is %s lines. The block silently widened; every fragment pin below would be matched against unrelated code. Restore the terminator marker.\n' "$C45B_LINES"
  elif [[ "$C45B_LINES" -lt "$C45B_MIN_LINES" || "$C45B_LINES" -gt "$C45B_MAX_LINES" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL the extracted (b) block is %s lines, outside the stated band %s..%s. A boundary move is reported with its observed extent, never absorbed silently.\n' "$C45B_LINES" "$C45B_MIN_LINES" "$C45B_MAX_LINES"
  else
    C45B_OK=true
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   (b) block extracted: %s lines, terminating on its '"'"'# (c) FMF-2'"'"' marker (band %s..%s)\n' "$C45B_LINES" "$C45B_MIN_LINES" "$C45B_MAX_LINES"
  fi
fi
# Comment-stripped view, shared by the arm-coverage, zero-`continue` and pairing
# assertions below. One extraction, four consumers — never a second awk.
C45B_CODE=""
[[ "$C45B_OK" == "true" ]] && C45B_CODE="$(/usr/bin/grep -vE '^[[:space:]]*#' <<< "$C45B_BLOCK")"

# Emitted by every assertion that consumes the extraction, when the extraction failed.
# A skipped assertion is reported as NOT RUN; the NOSET FAIL above already reddens the
# suite, so this can never read as a pass.
_c45b_unavailable() {
  echo "  skip — the (b) block is NOSET (see the extraction failure above); this assertion did NOT run and is NOT a pass"
}

# ── The pin set. Captured into a variable rather than consumed inline, because the
#    falsification harness at the bottom DERIVES its mutation set from this same value.
#    A parallel hardcoded list is precisely what that harness exists to make impossible:
#    a fragment cannot be added here without being falsification-tested.
C45_FRAGS="$(cat <<'FRAGS'
# (b) FMF-1 — entry-row-scoped governing_doc resolution
while IFS='|' read -r _c45_lead c45_id c45_name _c45_stmt c45_gd _c45_rest
!= *"$c45_name"*
MIS-PIN (name-match)
register entry has no name
register entry has no governing_doc
register governing_doc does not resolve to a real path:line
grep -E '^\| DP-[0-9]' "$c45_reg"
# (c) FMF-2 — consumer-id resolution
FRAGS
)"

echo ""
echo "── Drift guard: every pin resolves INSIDE the (b) block ──────────────────"
# Marker-based, never line-numbered. Fixed-string fragments (grep -F) so BRE/ERE
# escaping cannot make a fragment silently un-matchable.
#
# The match is scoped to the extracted block, NOT to "$DEPLOY_SH". That one change is
# this card's whole subject: matched whole-file, the input-selector pin below is
# satisfied by sub-check (c)'s copy of the same string two lines further down, so
# repointing (b)'s input left every pin resolving and the mutation passed. Scoped to the
# block, (c)'s copy is outside by construction — and the extraction postcondition above
# is what makes "by construction" an assertion rather than a claim.
if [[ "$C45B_OK" != "true" ]]; then
  _c45b_unavailable
else
  DRIFT_OK=true
  _c45_pin_count=0
  while IFS= read -r _frag; do
    [[ -n "$_frag" ]] || continue
    _c45_pin_count=$((_c45_pin_count + 1))
    if ! /usr/bin/grep -qF "$_frag" <<< "$C45B_BLOCK"; then
      DRIFT_OK=false
      printf '  FAIL drift: fragment not found in the live Check 45(b) block -> %s\n' "$_frag"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done <<< "$C45_FRAGS"
  if [[ "$DRIFT_OK" == "true" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   all %s pinned fragment(s) resolve inside the (b) block\n' "$_c45_pin_count"
  fi

  # ── Arm coverage: every finding-emitting line in the block is covered by some pin.
  #    A hand-written message enumerating "the b0/b1/b2 branches this test pins" is the
  #    artifact reviewers read INSTEAD of the pin set, and it goes stale the moment the
  #    two diverge — which is how b1 came to be named by the message and pinned by
  #    nothing. This asserts the claim instead of restating it, so it cannot rot: add an
  #    arm without a pin and this FAILS naming the unpinned line.
  _c45_flag_lines="$(/usr/bin/grep -F 'flag_warn_or_issue' <<< "$C45B_CODE")"
  if [[ -z "$_c45_flag_lines" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  FAIL no flag_warn_or_issue line found in the (b) block — the extraction returned code that emits no findings at all; that is an empty probe, not a clean result"
  else
    _c45_uncovered=0
    while IFS= read -r _fline; do
      [[ -n "$_fline" ]] || continue
      _c45_covered=false
      while IFS= read -r _frag; do
        [[ -n "$_frag" ]] || continue
        if [[ "$_fline" == *"$_frag"* ]]; then _c45_covered=true; break; fi
      done <<< "$C45_FRAGS"
      if [[ "$_c45_covered" != "true" ]]; then
        _c45_uncovered=$((_c45_uncovered + 1))
        FAIL_COUNT=$((FAIL_COUNT + 1))
        printf '  FAIL unpinned finding branch in the live (b) block -> %s\n' "$(_c45_trim "$_fline")"
      fi
    done <<< "$_c45_flag_lines"
    if [[ "$_c45_uncovered" == "0" ]]; then
      _c45_arm_count="$(/usr/bin/grep -cF 'flag_warn_or_issue' <<< "$C45B_CODE")"
      PASS_COUNT=$((PASS_COUNT + 1))
      printf '  ok   all %s finding branch(es) in the live (b) block are pinned — the coverage claim is computed, not restated\n' "$_c45_arm_count"
    fi
  fi
fi

echo ""
echo "── Liveness: the live input selector is EXTRACTED and RUN ────────────────"
# A pin proves a string EXISTS. It cannot prove the string still selects anything — and
# a selector that selects nothing turns the whole check into a silent no-op that still
# prints its OK: line, which is the defect class this milestone exists to close. So the
# live pattern is lifted out of the block and executed against three registers.
#
# The extracted PATTERN is run; the extracted LINE is never `eval`ed. Executing text
# lifted out of another script is a different act with a different risk surface, and
# nothing here needs it.
C45_SEL_PAT=""
if [[ "$C45B_OK" != "true" ]]; then
  _c45b_unavailable
else
  _c45_sel_n="$(/usr/bin/grep -cF 'done < <(grep' <<< "$C45B_BLOCK")"
  if [[ "$_c45_sel_n" != "1" ]]; then
    # Fail closed, never skip: if the shape cannot be parsed, the arms below are vacuous.
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL expected exactly 1 `done < <(grep ...)` input line in the (b) block, found %s — the selector cannot be located, so its liveness arms would assert nothing\n' "$_c45_sel_n"
  else
    _c45_sel_line="$(_c45_trim "$(/usr/bin/grep -F 'done < <(grep' <<< "$C45B_BLOCK")")"
    C45_SEL_PAT="$(/usr/bin/sed -n "s/.*grep -E '\\([^']*\\)'.*/\\1/p" <<< "$_c45_sel_line")"
    _c45_sel_expect="done < <(grep -E '${C45_SEL_PAT}' \"\$c45_reg\")"
    if [[ -z "$C45_SEL_PAT" || "$_c45_sel_line" != "$_c45_sel_expect" ]]; then
      FAIL_COUNT=$((FAIL_COUNT + 1))
      C45_SEL_PAT=""
      printf '  FAIL the (b) input line does not match the expected shape.\n        got:    %s\n        expect: done < <(grep -E '"'"'<pattern>'"'"' "$c45_reg")\n' "$_c45_sel_line"
    else
      PASS_COUNT=$((PASS_COUNT + 1))
      printf '  ok   input selector shape pinned; live pattern extracted -> %s\n' "$C45_SEL_PAT"
    fi
  fi
fi

if [[ -z "$C45_SEL_PAT" ]]; then
  [[ "$C45B_OK" == "true" ]] && echo "  skip — no pattern was extracted (see the shape failure above); the arms did NOT run"
else
  # Sensitivity: the live pattern must still select the entry rows it exists to select.
  # A repoint (^| DP- -> ^| ZZ-) selects 0 here and FAILS.
  _n_sens="$(/usr/bin/grep -cE "$C45_SEL_PAT" "${TMP}/reg_clean.md")"
  if [[ "$_n_sens" == "4" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  ok   sensitivity: live pattern selects 4/4 entry rows on the clean fixture"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL sensitivity: live pattern selected %s of 4 entry rows on the clean fixture — the live (b) loop would iterate a short or EMPTY population while still printing its OK: line\n' "$_n_sens"
  fi

  # Specificity: the live pattern must select NOTHING on a register whose only DP-bearing
  # lines are prose decoys. A loosened pattern matches a decoy and FAILS. Without this
  # arm, "selects something" would be satisfied by a pattern that selects everything.
  _n_spec="$(/usr/bin/grep -cE "$C45_SEL_PAT" "${TMP}/reg_decoy.md")"
  if [[ "$_n_spec" == "0" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  ok   specificity: live pattern selects 0 rows on the decoy register (header + 3 decoys, no entry rows)"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL specificity: live pattern selected %s line(s) on a register with ZERO entry rows — the row anchor has been loosened and the selector now matches schema prose\n' "$_n_spec"
  fi

  # Liveness against the ACTUAL subject. The two arms above run on fixtures this file
  # authored, so they prove the pattern is well-formed against a FROZEN grammar — not
  # that it still selects a non-empty population from the register Check 45(b) really
  # reads. Threshold is >= 1, deliberately not an exact count: this asserts LIVENESS,
  # never content, so a legitimate register edit can never break it. Read-only.
  if [[ ! -f "$LIVE_REGISTER" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL the live register is not readable at %s — the liveness arm cannot run, and an unrun arm is not a pass\n' "$LIVE_REGISTER"
  else
    _n_live="$(/usr/bin/grep -cE "$C45_SEL_PAT" "$LIVE_REGISTER")"
    # Control arm, so the count above is discriminating rather than "grep matched
    # something": a sibling pattern of the same SHAPE against the same file must be 0.
    _n_live_ctl="$(/usr/bin/grep -cE '^\| ZZ-[0-9]' "$LIVE_REGISTER")"
    if [[ "$_n_live" -ge 1 && "$_n_live_ctl" == "0" ]]; then
      PASS_COUNT=$((PASS_COUNT + 1))
      printf '  ok   liveness: live pattern selects %s row(s) from the live register (control pattern selects %s)\n' "$_n_live" "$_n_live_ctl"
    else
      FAIL_COUNT=$((FAIL_COUNT + 1))
      printf '  FAIL liveness: live pattern selected %s row(s) from the live register (control %s, must be 0). Check 45(b) would iterate an EMPTY population and still print its OK: line — the register grammar and the selector have drifted apart\n' "$_n_live" "$_n_live_ctl"
    fi
  fi
fi

echo ""
echo "── Two-site parity: (b) and (c) read the register with the SAME pattern ──"
# The register-row grammar is encoded TWICE in Check 45 — once as (b)'s loop input and
# once as (c)'s defined-id extraction. Asserting byte-identity is stronger than pinning
# each against a hardcoded literal, because it cannot go stale: if the row grammar
# legitimately changes, both sites must change together and this still passes. What it
# forbids is the two drifting apart, which is the state in which one sub-check silently
# stops seeing rows the other still sees.
if [[ -z "$C45_SEL_PAT" ]]; then
  echo "  skip — (b)'s pattern was not extracted (see above); parity did NOT run and is NOT a pass"
else
  _c45_c_n="$(/usr/bin/grep -cF 'c45_defined="$(grep -E ' "$DEPLOY_SH")"
  if [[ "$_c45_c_n" != "1" ]]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL expected exactly 1 `c45_defined="$(grep -E ...` line in deploy.sh, found %s — (c)'"'"'s register-side selector cannot be located, so parity would assert nothing\n' "$_c45_c_n"
  else
    _c45_c_line="$(/usr/bin/grep -F 'c45_defined="$(grep -E ' "$DEPLOY_SH")"
    _c45_c_pat="$(/usr/bin/sed -n "s/.*grep -E '\\([^']*\\)'.*/\\1/p" <<< "$_c45_c_line")"
    if [[ -z "$_c45_c_pat" ]]; then
      FAIL_COUNT=$((FAIL_COUNT + 1))
      echo "  FAIL could not extract (c)'s register-side pattern from its located line — fail closed, not a pass"
    elif [[ "$_c45_c_pat" == "$C45_SEL_PAT" ]]; then
      PASS_COUNT=$((PASS_COUNT + 1))
      printf '  ok   (b) and (c) select register rows with the byte-identical pattern -> %s\n' "$C45_SEL_PAT"
    else
      FAIL_COUNT=$((FAIL_COUNT + 1))
      printf '  FAIL the two register-row selectors have DIVERGED — (b) uses [%s], (c) uses [%s]. One sub-check is now reading rows the other cannot see\n' "$C45_SEL_PAT" "$_c45_c_pat"
    fi
  fi
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
if [[ "$C45B_OK" != "true" ]]; then
  _c45b_unavailable
else
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
echo "── Pairing: every finding branch also clears c45_ok ──────────────────────"
# The zero-`continue` assertion proves every row REACHES an arm. This proves every arm
# that FLAGS also clears c45_ok, so the check cannot emit a finding and print its OK:
# line on the same run. Deleting `c45_ok=0` from one arm makes the counts diverge.
# Whole-ARM deletion is caught by the arm-coverage assertion above, not by this count —
# the two are complementary and neither is sufficient alone.
if [[ "$C45B_OK" != "true" ]]; then
  _c45b_unavailable
else
  _n_flag="$(/usr/bin/grep -cF 'flag_warn_or_issue' <<< "$C45B_CODE")"
  _n_ok0="$(/usr/bin/grep -cF 'c45_ok=0' <<< "$C45B_CODE")"
  if [[ "$_n_flag" -ge 1 && "$_n_flag" == "$_n_ok0" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   %s finding branch(es), %s `c45_ok=0` — paired\n' "$_n_flag" "$_n_ok0"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL pairing broken: %s `flag_warn_or_issue` vs %s `c45_ok=0` in the live (b) body — a branch can now emit a finding while c45_ok survives as 1, so Check 45 prints the finding AND its OK: line together\n' "$_n_flag" "$_n_ok0"
  fi
fi

# ── Falsification harness ───────────────────────────────────────────────────────
# AC-3 requires this guard's falsification to be RUN, not asserted. A one-time run
# recorded in a pull-request body satisfies the word and decays the moment it is
# written — which is how a fragment guard shipped with a hole in it in the first place,
# and re-shipping that shape inside the instrument meant to prove the shape was removed
# would be the same defect one level up. So the harness is permanent, and it RUNS BY
# DEFAULT: `bash <this file>` executes it, which means the CI step that already invokes
# this test bare executes it too, with no workflow edit and no env var for anyone to
# forget to set. Only the harness's OWN child invocations short-circuit it.
#
# Two properties make it self-maintaining rather than a second thing to keep in sync:
#
#   1. The mutation set is DERIVED from the pin set above, so a fragment cannot be added
#      without being falsification-tested. There is no parallel list to fall behind.
#   2. A mutant must fail with the NAMED message of the pin under test — an exit code
#      alone is not accepted. Several mutations redden the suite through more than one
#      assertion, and "something went red" would certify per-pin coverage the harness
#      never demonstrated. Requiring the specific message turns the harness from a
#      smoke test into per-pin attribution, which is what AC-3 is actually asking for.
#
# The expected message for each derived mutant is itself derived, from where the
# fragment sits in the block: corrupting the block's FIRST line destroys the opening
# marker and trips NOSET before the fragment loop is reached; corrupting its LAST line
# destroys the terminator and trips the extent postcondition; anything between is caught
# by the fragment loop itself.
if [[ "$FALSIFY_CHILD" == "1" ]]; then
  echo ""
  echo "── Falsification harness: SHORT-CIRCUITED (child invocation) ─────────────"
elif [[ "$C45B_OK" != "true" ]]; then
  echo ""
  echo "── Falsification harness ─────────────────────────────────────────────────"
  echo "  skip — the (b) block is NOSET, so no mutation could be anchored; did NOT run"
else
  echo ""
  echo "── Falsification harness: every pin is mutated and must bite, by name ────"
  MUT_DIR="${TMP}/falsify"
  mkdir -p "$MUT_DIR"
  FALSIFY_OK=true
  FALSIFY_ROWS=0

  # Replace the FIRST occurrence of a literal needle INSIDE the (b) block. Block-scoped
  # because the input selector occurs twice in deploy.sh and only the in-block occurrence
  # is the one the pins now assert against — mutating (c)'s copy would falsify nothing.
  # Literal via index()/substr(), never a regex, and the needle arrives through ENVIRON
  # rather than -v so awk cannot reinterpret a backslash inside it.
  _c45_mutate() {   # <src> <dst> <needle> <replacement>
    C45M_NEEDLE="$3" C45M_REPL="$4" /usr/bin/awk '
      BEGIN { done=0; act=0; n=ENVIRON["C45M_NEEDLE"]; r=ENVIRON["C45M_REPL"] }
      {
        isopen = index($0, "# (b) FMF-1"); isterm = index($0, "# (c) FMF-2")
        if (isopen) act = 1
        if (act && !done) {
          p = index($0, n)
          if (p > 0) { $0 = substr($0, 1, p-1) r substr($0, p+length(n)); done = 1 }
        }
        print
        if (act && isterm) act = 0
      }
      END { if (!done) exit 3 }
    ' "$1" > "$2"
  }

  # Occurrences of a literal needle inside the (b) block. An anchor count other than 1
  # aborts the row as a setup failure — never a silently skipped or mis-targeted mutation.
  _c45_anchor_count() {   # <src> <needle>
    C45M_NEEDLE="$2" /usr/bin/awk '
      BEGIN { c=0; act=0; n=ENVIRON["C45M_NEEDLE"] }
      {
        isopen = index($0, "# (b) FMF-1"); isterm = index($0, "# (c) FMF-2")
        if (isopen) act = 1
        if (act) { s=$0; p=index(s,n); while (p>0) { c++; s=substr(s,p+length(n)); p=index(s,n) } }
        if (act && isterm) act = 0
      }
      END { print c }
    ' "$1"
  }

  # Run one mutant and grade it. <label> <mutant-file> <expect-red:true|false> <signature>
  _c45_grade() {
    local _label="$1" _mut="$2" _want_red="$3" _sig="$4" _out _rc
    FALSIFY_ROWS=$((FALSIFY_ROWS + 1))
    _out="$(PMO_C45_FALSIFY_CHILD=1 DEPLOY_SH="$_mut" bash "$SELF" 2>&1)"
    _rc=$?
    if [[ "$_want_red" != "true" ]]; then
      # The harness's own specificity arm: an UNMUTATED copy must stay green. Without it,
      # "every mutant went red" is equally consistent with a harness that reddens
      # everything, and the sensitivity rows below would prove nothing.
      if [[ "$_rc" -eq 0 ]]; then
        printf '  ok   %s -> suite GREEN (control: red is earned, not the default)\n' "$_label"
      else
        FALSIFY_OK=false
        FAIL_COUNT=$((FAIL_COUNT + 1))
        printf '  FAIL %s -> the UNMUTATED control copy failed (rc=%s). Every mutant row below is uninterpretable until this passes\n' "$_label" "$_rc"
      fi
      return
    fi
    if [[ "$_rc" -eq 0 ]]; then
      FALSIFY_OK=false
      FAIL_COUNT=$((FAIL_COUNT + 1))
      printf '  FAIL %s -> suite stayed GREEN. That pin does not bite: it can be corrupted without this test noticing\n' "$_label"
    elif [[ "$_out" != *"$_sig"* ]]; then
      FALSIFY_OK=false
      FAIL_COUNT=$((FAIL_COUNT + 1))
      printf '  FAIL %s -> suite went red, but NOT for this pin. Expected the message [%s]; the mutation is being caught by some other assertion, so this pin is uncovered\n' "$_label" "$_sig"
    else
      printf '  ok   %s -> red, with its own message\n' "$_label"
    fi
  }

  _c45_first_line="${C45B_BLOCK%%$'\n'*}"
  _c45_last_line="${C45B_BLOCK##*$'\n'}"

  # ── Derived rows: one per pinned fragment ────────────────────────────────────
  while IFS= read -r _frag; do
    [[ -n "$_frag" ]] || continue
    _anchors="$(_c45_anchor_count "$DEPLOY_SH" "$_frag")"
    if [[ "$_anchors" != "1" ]]; then
      FALSIFY_OK=false
      FAIL_COUNT=$((FAIL_COUNT + 1))
      printf '  FAIL setup: fragment has %s in-block anchor(s), expected exactly 1 -> %s\n' "$_anchors" "$_frag"
      continue
    fi
    if [[ "$_c45_first_line" == *"$_frag"* ]]; then
      _sig="NOSET, not a pass"
    elif [[ "$_c45_last_line" == *"$_frag"* ]]; then
      _sig="does not TERMINATE on its '# (c) FMF-2' marker"
    else
      _sig="fragment not found in the live Check 45(b) block -> ${_frag}"
    fi
    _mut="${MUT_DIR}/frag_${FALSIFY_ROWS}.sh"
    if ! _c45_mutate "$DEPLOY_SH" "$_mut" "$_frag" "ZZ-MUTANT-PIN"; then
      FALSIFY_OK=false
      FAIL_COUNT=$((FAIL_COUNT + 1))
      printf '  FAIL setup: could not apply the mutation for -> %s\n' "$_frag"
      continue
    fi
    _c45_grade "pin [${_frag:0:52}]" "$_mut" true "$_sig"
  done <<< "$C45_FRAGS"

  # ── Control row: the unmutated copy must stay green ──────────────────────────
  cp "$DEPLOY_SH" "${MUT_DIR}/control.sh"
  _c45_grade "control [unmutated deploy.sh copy]" "${MUT_DIR}/control.sh" false ""

  # ── Hand-authored rows for the behavioural arms and the pairing invariant ────
  # These three are not derivable from the pin set: they corrupt the selector's MEANING
  # and the branch/flag pairing rather than a pinned string, which is exactly the class a
  # fragment guard alone cannot see.
  _sel_full="done < <(grep -E '^\| DP-[0-9]' \"\$c45_reg\")"
  _sel_anchors="$(_c45_anchor_count "$DEPLOY_SH" "$_sel_full")"
  if [[ "$_sel_anchors" != "1" ]]; then
    FALSIFY_OK=false
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL setup: the (b) input line has %s in-block anchor(s), expected exactly 1\n' "$_sel_anchors"
  else
    if _c45_mutate "$DEPLOY_SH" "${MUT_DIR}/repoint.sh" "$_sel_full" "done < <(grep -E '^\| ZZ-[0-9]' \"\$c45_reg\")"; then
      _c45_grade "selector REPOINT (^| DP- -> ^| ZZ-)" "${MUT_DIR}/repoint.sh" true "FAIL sensitivity:"
    fi
    if _c45_mutate "$DEPLOY_SH" "${MUT_DIR}/loosen.sh" "$_sel_full" "done < <(grep -E 'DP-[0-9]' \"\$c45_reg\")"; then
      _c45_grade "selector LOOSEN (drop the row anchor)" "${MUT_DIR}/loosen.sh" true "FAIL specificity:"
    fi
  fi

  # Delete `c45_ok=0` from the b2 arm — the defect the pairing invariant closes. Anchored
  # on the unique MIS-PIN message and applied to the line immediately after it, so the
  # other three arms' `c45_ok=0` lines cannot be hit by accident.
  if /usr/bin/awk '
      BEGIN { armed=0; dropped=0 }
      {
        if (armed && !dropped && $0 ~ /^[[:space:]]*c45_ok=0[[:space:]]*$/) { armed=0; dropped=1; next }
        armed = 0
        if (index($0, "MIS-PIN (name-match)")) armed = 1
        print
      }
      END { if (!dropped) exit 3 }
    ' "$DEPLOY_SH" > "${MUT_DIR}/unpair.sh"; then
    _c45_grade "DROP c45_ok=0 from the b2 arm" "${MUT_DIR}/unpair.sh" true "FAIL pairing broken:"
  else
    FALSIFY_OK=false
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  FAIL setup: could not locate a c45_ok=0 line following the b2 MIS-PIN branch"
  fi

  if [[ "$FALSIFY_OK" == "true" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   %s falsification row(s): every pin bit, each with its own named message, and the unmutated control stayed green\n' "$FALSIFY_ROWS"
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

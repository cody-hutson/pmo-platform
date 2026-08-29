#!/usr/bin/env bash
# test_check49_mode_identifier_unification.sh — fixture self-test for deploy.sh
# Check 49, the platform-convention linter's mode-identifier unification.
#
# Cite the code under test by its INLINE MARKER, never by line number:
#   core/deploy/deploy.sh, `# ─── Check 49: platform-convention linter`
# Resolver: grep -n 'Check 49: platform-convention linter' core/deploy/deploy.sh.
# Line pins in this area are actively unsafe — an in-flight draft PR adds 163 lines
# above this range — which is why every assertion below locates the block by marker.
#
# What this proves: Check 49 answered to TWO independent mode knobs. It resolved its
# mode under `check-convention` but emitted its predicate-script-missing finding under
# `convention-linter`, and `flag_warn_or_issue` re-resolves the mode from whatever id
# it is handed. So an operator who created check-convention.mode — the only mode
# filename any shipped guidance has ever named — moved the enforce ladder and left the
# error path sitting on the shared default. Two knobs, neither covering the whole check.
#
# Four arms, asserted independently so a future edit cannot collapse one into another
# and still pass this file:
#   A  ENFORCE-LADDER  — the inline FAIL: ladder escalates under check-convention.mode
#   B  MISSING-SCRIPT  — the emitter arm escalates under the SAME mode file (post-fix)
#   B' THE DEFECT      — a faithful copy of the PRE-FIX call resolves to warn and does
#                        NOT escalate, on the identical fixture
#   C  NEGATIVE CONTROL— with the mode file removed, NEITHER arm escalates
#
# B' is the arm that makes this file mean anything. AC2 demands both arms be exercised
# precisely because a one-arm test reproduces the bug as a PASS: assert only A and the
# suite is green on broken code. B' is the negative image that proves the fixture can
# tell fixed code from broken code, the same role T2'/T6' play in test_check45.
#
# THE ONE CONSTRAINT THAT DECIDES WHETHER THIS FIXTURE IS VALID: the shared
# $DEPLOY_CHECK_MODE must be seeded 'warn', never 'enforce'. Under a shared 'enforce'
# the missing-script arm would escalate PRE-FIX through plain fallback and B' would go
# green on the defect — a broken probe wearing a check mark. The entire discriminating
# power here is the GAP between a per-check 'enforce' and a shared 'warn'.
#
# Hermetic by construction: every fixture is built under a mktemp -d, PMO_INSTANCE_PATH
# is redirected into it, and the predicate copies run with that tmpdir as cwd — so the
# resolver's second tier (.claude/hooks/<id>.mode, resolved RELATIVE to cwd) cannot
# reach an operator's real mode files. The only live file this test touches is
# deploy.sh, read-only, via the drift guard and the CIAC-1 assertion.
#
# Precedent: core/deploy/tests/test_check45_governing_doc_name_match.sh — a faithful
# copy of the predicate under test pinned against a fixture, plus a DRIFT GUARD that
# greps deploy.sh so a silent edit to Check 49 fails this test rather than passing it
# stale. The copies are necessary, not lazy: resolve_check_mode and flag_warn_or_issue
# are both defined INSIDE cmd_check(), not at top level, so they cannot be sourced.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"

PASS_COUNT=0
FAIL_COUNT=0

# pmo_instance_path() IS top-level and sourceable (unlike the two helpers below), so
# the real one is used rather than a copy — one less thing that can drift.
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib-instance-path.sh"

# ── Faithful copies of the two cmd_check() helpers, kept in lock-step with deploy.sh
#    via the drift guard at the end of this file. Copied, not sourced, because both
#    are nested inside cmd_check() and are unreachable from an outside shell.

log() { printf '%s\n' "$*"; }

resolve_check_mode() {
  local _check_id="$1"
  local _default="${2:-$DEPLOY_CHECK_MODE}"
  local _check_mode_file="$(pmo_instance_path)/${_check_id}.mode"
  # Legacy-home rung, mirroring deploy.sh: a mode file is hand-created operator-instance
  # state, so across the instance-home relocation the only copy on an un-migrated
  # instance sits at the previous home. Kept here because this copy exists to exercise
  # the SAME predicate — a copy that resolves through fewer rungs than production is a
  # test asserting behaviour the platform no longer has.
  [[ -f "$_check_mode_file" ]] || _check_mode_file="$(pmo_instance_path_legacy)/${_check_id}.mode"
  [[ -f "$_check_mode_file" ]] || _check_mode_file=".claude/hooks/${_check_id}.mode"
  if [[ -f "$_check_mode_file" ]]; then
    local _cm
    _cm=$(cat "$_check_mode_file" 2>/dev/null | tr -d '[:space:]')
    case "$_cm" in
      enforce|warn|off) printf '%s' "$_cm"; return 0 ;;
    esac
  fi
  printf '%s' "$_default"
}

# DELIBERATE ELISION: the live warn) branch also appends a jsonl row to $WARN_LOG.
# It is omitted here because it has no bearing on which mode an id binds — the only
# property under test. The `case` arms, their order, and the ISSUES increment are
# reproduced exactly; nothing that decides escalation is elided.
flag_warn_or_issue() {
  local check_id="$1"
  local detail="$2"
  local _check_mode
  _check_mode="$(resolve_check_mode "$check_id")"
  case "$_check_mode" in
    enforce)
      log "  FAIL:  $check_id — $detail"
      ISSUES=$((ISSUES + 1))
      ;;
    warn)
      log "  WARN:  $check_id — $detail (warn-mode)"
      ;;
  esac
}

# Faithful copy of Check 49's own inline FAIL: ladder (the enforce path that the
# emitter arm is SUPPOSED to agree with). Takes the already-resolved mode, exactly as
# the live block does via its $c49_mode local.
c49_ladder() {
  local c49_mode="$1"
  local c49_line="$2"
  case "$c49_line" in
    FAIL:*)
      if [[ "$c49_mode" == "enforce" ]]; then
        log "  ${c49_line}"
        ISSUES=$((ISSUES + 1))
      elif [[ "$c49_mode" == "warn" ]]; then
        log "  WARN:  ${c49_line#FAIL: } (warn-mode)"
      fi
      ;;
  esac
}

# ── Hermetic fixture ───────────────────────────────────────────────────────────────
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/instance"
export PMO_INSTANCE_PATH="$TMP/instance"

# cwd moves into the tmpdir so the resolver's SECOND tier (.claude/hooks/<id>.mode) is
# resolved relative to a directory we own. Without this the test would read whatever
# mode files the operator's own checkout happens to carry.
cd "$TMP" || { echo "FAIL: cannot cd to fixture tmpdir"; exit 1; }

# The shared cohort mode. 'warn' is load-bearing — see the header.
DEPLOY_CHECK_MODE="warn"

seed_override()  { printf 'enforce\n' > "$PMO_INSTANCE_PATH/check-convention.mode"; }
clear_override() { rm -f "$PMO_INSTANCE_PATH/check-convention.mode"; }

# The retired identifier must never have a mode file anywhere in this fixture — B'
# depends on it being ABSENT to fall through to the shared default.
rm -f "$PMO_INSTANCE_PATH/convention-linter.mode"

assert_issues() {
  local want="$1" got="$2" label="$3"
  if [[ "$got" == "$want" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  ok   $label (ISSUES delta $got)"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL %s — expected ISSUES delta %s, got %s\n' "$label" "$want" "$got"
  fi
}

echo "── Fixture preconditions ─────────────────────────────────────────────────"
seed_override
if [[ -f "$PMO_INSTANCE_PATH/check-convention.mode" ]] \
   && [[ ! -f "$PMO_INSTANCE_PATH/convention-linter.mode" ]] \
   && [[ "$DEPLOY_CHECK_MODE" == "warn" ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   per-check check-convention.mode=enforce, NO convention-linter.mode, shared mode=warn"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL fixture preconditions not met — every arm below would be meaningless"
fi

# The gap the whole fixture rests on. Asserted explicitly so that if a future edit
# seeds the shared mode to 'enforce', THIS fails loudly instead of B' silently
# going green on broken code.
if [[ "$(resolve_check_mode "check-convention")" == "enforce" ]] \
   && [[ "$(resolve_check_mode "convention-linter")" == "warn" ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   the discriminating gap exists: check-convention→enforce, convention-linter→warn (shared)"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL no discriminating gap — B' cannot distinguish fixed code from broken code"
fi

echo ""
echo "── Arm A: the enforce ladder binds check-convention.mode ─────────────────"
ISSUES=0
c49_ladder "$(resolve_check_mode "check-convention")" "FAIL: synthetic convention finding" >/dev/null
assert_issues 1 "$ISSUES" "inline FAIL: ladder escalates under the per-check override"

echo ""
echo "── Arm B: the predicate-script-missing path binds the SAME mode file ─────"
# This is the arm that does not bind pre-fix. Post-fix the emitter is handed
# check-convention, so it re-resolves the very same file Arm A used.
ISSUES=0
# Output is captured to a FILE, never through $( ), because command substitution runs
# the emitter in a SUBSHELL and the ISSUES increment would be discarded on the way
# back out. Under $( ) this arm reads 0 no matter what the mode resolves to, and B'
# below would then go green on its subshell rather than on the defect — a broken probe
# wearing a check mark. A plain redirect keeps the emitter in the current shell.
flag_warn_or_issue "check-convention" "predicate script missing: core/deploy/tools/check-convention.sh" > "$TMP/b_out.txt"
B_OUT="$(cat "$TMP/b_out.txt")"
assert_issues 1 "$ISSUES" "missing-script emitter escalates under the per-check override"
if [[ "$B_OUT" == *"FAIL:"* ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   emitter output is a FAIL: line, not a WARN:"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  FAIL emitter did not emit FAIL: -> %s\n' "$B_OUT"
fi

echo ""
echo "── Arm B': the DEFECT, measured — pre-fix call on the identical fixture ──"
# A faithful copy of the pre-fix call. If this escalates, the fixture has lost its
# discriminating power and every green above is worthless.
ISSUES=0
# Same file-capture discipline as Arm B, and it matters MORE here: this arm asserts a
# ZERO, so a subshell that silently swallowed the increment would produce the expected
# result for entirely the wrong reason and the fixture would certify broken code.
flag_warn_or_issue "convention-linter" "predicate script missing: core/deploy/tools/check-convention.sh" > "$TMP/bp_out.txt"
BP_OUT="$(cat "$TMP/bp_out.txt")"
assert_issues 0 "$ISSUES" "pre-fix emitter id does NOT escalate (the live bug, reproduced)"
if [[ "$BP_OUT" == *"WARN:"* ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   pre-fix call fell through to the shared warn default — the split, observed"
else
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  FAIL pre-fix call did not fall through to shared warn -> %s\n' "$BP_OUT"
fi

echo ""
echo "── Arm C: negative control — no mode file, neither arm escalates ─────────"
# Proves A and B are reading the mode FILE, not escalating unconditionally.
clear_override
ISSUES=0
c49_ladder "$(resolve_check_mode "check-convention")" "FAIL: synthetic convention finding" >/dev/null
assert_issues 0 "$ISSUES" "ladder does not escalate with the override removed"
ISSUES=0
flag_warn_or_issue "check-convention" "predicate script missing: x" >/dev/null
assert_issues 0 "$ISSUES" "emitter does not escalate with the override removed"
seed_override

echo ""
echo "── Drift guard: the live deploy.sh Check 49 block still matches this copy ─"
# Marker-based, never line-numbered. Fixed-string (grep -F) so no BRE/ERE escaping can
# make a fragment silently un-matchable.
DRIFT_OK=true
while IFS= read -r _frag; do
  [[ -n "$_frag" ]] || continue
  if ! /usr/bin/grep -qF "$_frag" "$DEPLOY_SH"; then
    DRIFT_OK=false
    printf '  FAIL drift: fragment not found in deploy.sh -> %s\n' "$_frag"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done <<'FRAGS'
c49_mode=$(resolve_check_mode "check-convention" "warn")
flag_warn_or_issue "check-convention" "predicate script missing: $c49_script"
log "  FAIL:  Check 49 — check-convention scan-surface error (exit 3)"
FRAGS
if [[ "$DRIFT_OK" == "true" ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   live Check 49 resolves, emits, and logs under check-convention"
fi

# The retired id must be GONE from the live emitter call specifically. A bare
# 'convention-linter' grep would match the AC3 retirement note and the block's own
# descriptive prose, so this pins the CALL FORM, not the bare string.
if /usr/bin/grep -qF 'flag_warn_or_issue "convention-linter"' "$DEPLOY_SH"; then
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL the retired identifier is still passed to flag_warn_or_issue in live deploy.sh"
else
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   no flag_warn_or_issue \"convention-linter\" call survives in deploy.sh"
fi

echo ""
echo "── CIAC-1: the Check 49 block names exactly ONE check id in CODE ─────────"
# The durable half. A fragment grep sees only the sites that exist today; this asserts
# the SHAPE — one block, one identifier — so a future edit that reintroduces a second
# id fails here rather than passing stale. Block bounds are the two inline markers,
# never line numbers.
#
# TWO INDEPENDENT PROTECTIONS, and it matters which is which — measured, not assumed.
# AC3 REQUIRES the block comment to name `convention-linter` (the retirement note), and
# the block's opening prose calls the tool "the convention-linter", so the retired
# string is legitimately present 3 times in comments. A NAIVE bare-string cardinality
# assertion over the raw block sees {check-convention x12, convention-linter x3} and
# fails on the very note the acceptance criteria mandate.
#
# This assertion is protected twice over: (1) the extraction is scoped to the CALL FORM
# `<helper> "<id>"`, which no comment here matches, and (2) comment lines are stripped
# first. Either alone yields cardinality 1 today — verified by running the extraction
# with and without the strip. The call-form scoping is the primary guard; the strip is
# defence in depth for a future edit that broadens the pattern. Do not remove the
# call-form scoping on the assumption that stripping covers it — it does not.
C49_BLOCK="$(/usr/bin/awk 'index($0,"Check 49: platform-convention linter"){f=1} f{print} f && index($0,"Check 50") && index($0,"Platform-doc frontmatter"){exit}' "$DEPLOY_SH")"
if [[ -z "$C49_BLOCK" ]]; then
  # Fail closed: an unlocatable block must never read as "one identifier found".
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "  FAIL cannot locate the Check 49 block between its markers — NOSET, not a pass"
else
  C49_CODE="$(/usr/bin/grep -vE '^[[:space:]]*#' <<< "$C49_BLOCK")"
  C49_IDS="$(/usr/bin/grep -oE '(resolve_check_mode|flag_warn_or_issue) "[a-z0-9-]+"' <<< "$C49_CODE" \
             | /usr/bin/sed -E 's/.*"([a-z0-9-]+)"/\1/' | sort -u)"
  C49_CARD="$(printf '%s\n' "$C49_IDS" | /usr/bin/grep -c .)"
  if [[ "$C49_CARD" == "1" ]] && [[ "$C49_IDS" == "check-convention" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  ok   exactly 1 check id in Check 49 code, and it is check-convention"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL Check 49 code names %s distinct check id(s): %s — one block must answer to one mode knob\n' \
      "$C49_CARD" "$(printf '%s' "$C49_IDS" | tr '\n' ' ')"
  fi

  # AC3: the retired identifier is named in the block's COMMENTS with a no-longer-binds
  # note, so an operator holding the old mode file is not silently ignored.
  C49_COMMENTS="$(/usr/bin/grep -E '^[[:space:]]*#' <<< "$C49_BLOCK")"
  if /usr/bin/grep -qF 'convention-linter.mode' <<< "$C49_COMMENTS" \
     && /usr/bin/grep -qiF 'no longer binds' <<< "$C49_COMMENTS"; then
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  ok   block comment names convention-linter.mode and states it no longer binds"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  FAIL block comment lacks the retired-identifier note required by AC3"
  fi

  # The operator-guidance path must name a directory the resolver actually reads.
  # core/hooks/ is in NEITHER tier: resolve_check_mode reads
  # $(pmo_instance_path)/<id>.mode, then $(pmo_instance_path_legacy)/<id>.mode, then
  # .claude/hooks/<id>.mode. Guidance naming an unreadable directory is the same
  # silent-no-op class this check exists to close.
  if /usr/bin/grep -qF 'core/hooks/' <<< "$C49_COMMENTS"; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "  FAIL block guidance still names core/hooks/, which is in neither resolution tier"
  else
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "  ok   block guidance names only tiers the resolver reads"
  fi
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf 'Result: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "Check 49 mode-identifier unification fixture self-test: FAILED"
  exit 1
fi
echo "Check 49 mode-identifier unification fixture self-test: PASSED"
exit 0

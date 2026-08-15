#!/usr/bin/env bash
# test_check56_m2_advisory.sh — dynamic proof that Check 56's M2 leg is
# STRUCTURALLY incapable of gating, independent of milestone-epic-membership.mode.
#
# Why this harness exists rather than an assertion:
#
#   A static read of the call site cannot demonstrate the ABSENCE of gating. The
#   claim is behavioural — "flipping the dial to enforce does not move ISSUES or
#   the exit code" — so it needs a run.
#
# Why it does NOT stub the emitters, unlike test_g1_form_family.sh:
#
#   That harness stubs flag_g1_enforcement because its assertions are about WHICH
#   findings fire. Here the assertion IS the emitter's escalation behaviour. A
#   stubbed emitter makes "M2 did not increment ISSUES" trivially true and proves
#   nothing — the exact vacuous green this check exists to prevent. So the REAL
#   function bodies are extracted from deploy.sh and executed against a REAL
#   ISSUES counter.
#
# Why Arm D is not optional:
#
#   Arms B and C assert ZEROS. A zero whose control arm also returns zero is a
#   BROKEN PROBE. Arm D drives an M1 finding through the SAME extracted region at
#   the SAME enforce mode and requires ISSUES==1 plus a FAIL: line. Without D,
#   B and C are unusable. Arm E then proves the mode file is actually read, so
#   D's FAIL: cannot be coming from something other than enforce.
#
# Hermetic: no gh, no network. The TSV under test is PRODUCED by the primitive's
# own --fixture path, so it is the real emit shape, not a hand-typed string.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"
SRC_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PRIMITIVE="${SRC_ROOT}/core/deploy/tools/check-milestone-epic-membership.py"

PASS_COUNT=0; FAIL_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT+1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT+1)); printf '  FAIL  %s\n' "$1"; }
note() { printf '        %s\n' "$1"; }
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT

echo "Check 56 M2 advisory-class regression — deploy.sh"
echo "─────────────────────────────────────────────────────────────────────────"

# ── Extraction ──────────────────────────────────────────────────────────────
# Emitters: anchored PER FUNCTION, with NO sentinel markers. This is deliberate.
# A sibling card inserts a new emitter-family member immediately after
# flag_advisory_only's closing brace; a sentinel spanning that neighbourhood
# would collide with it. Per-function anchors make that insertion invisible here.
extract_fn() { /usr/bin/sed -n "/^  $1() {\$/,/^  }\$/p" "$DEPLOY_SH"; }

# Emit region: sentinel-marked, because it is THIS card's own region.
extract_emit() {
  local _b _e
  _b=$(/usr/bin/grep -m1 -n '>>> C56-EMIT-BEGIN' "$DEPLOY_SH" | cut -d: -f1)
  _e=$(/usr/bin/grep -m1 -n '>>> C56-EMIT-END'   "$DEPLOY_SH" | cut -d: -f1)
  [[ -n "$_b" && -n "$_e" && "$_e" -gt "$_b" ]] || return 1
  /usr/bin/sed -n "$((_b+1)),$((_e-1))p" "$DEPLOY_SH"
}

# Input-building block: the awk extractions that build c56_m1 / c56_m2 / the M2
# sub-counters / the detail string from the primitive's TSV. These are INPUTS to
# the emit region, not part of it. They are pulled from deploy.sh at RUN time by
# content anchor rather than pasted in here as a static copy: a copy would drift
# from the shipped extractions silently, and drift in the input builder is
# exactly the class of defect that makes a green arm meaningless. Marker-free by
# design, for the same contention reason as the per-function emitter anchors.
extract_inputs() {
  /usr/bin/sed -n '/^        local c56_declared c56_m1 c56_m2$/,/^        \[\[ "\$c56_m2_res" == "degraded" \]\]/p' "$DEPLOY_SH"
}

# ── Arm A — extraction non-vacuity (PV-3) ───────────────────────────────────
# A silently-empty extraction would make every arm below pass on nothing.
FW="$(extract_fn flag_warn_or_issue)"
FA="$(extract_fn flag_advisory_only)"
RM="$(extract_fn resolve_check_mode)"
EM="$(extract_emit)"
IN="$(extract_inputs)"
_a_ok=1
[[ -n "$FW" && "$FW" == *'ISSUES=$((ISSUES + 1))'* ]] || { _a_ok=0; fail "A flag_warn_or_issue extraction empty or missing its ISSUES increment"; }
[[ -n "$FA" && "$FA" != *'ISSUES=$((ISSUES + 1))'* && "$FA" != *'case '* ]] || { _a_ok=0; fail "A flag_advisory_only extraction empty, or it carries a mode case / ISSUES increment (its structural guarantee is gone)"; }
[[ -n "$RM" && "$RM" == *'.mode'* ]] || { _a_ok=0; fail "A resolve_check_mode extraction empty or missing its .mode read"; }
[[ -n "$EM" && "$EM" == *'flag_advisory_only'* && "$EM" == *'milestone-epic M1'* ]] || { _a_ok=0; fail "A C56-EMIT region empty, or it does not carry BOTH legs (Arm D needs M1 in scope)"; }
[[ -n "$IN" && "$IN" == *'$1=="M1"'* && "$IN" == *'$1=="M2"'* ]] || { _a_ok=0; fail "A input-building block empty or missing its M1/M2 awk extractions (anchor moved)"; }
if [[ "$_a_ok" -eq 1 ]]; then
  pass "A all five regions extracted from deploy.sh and carry their discriminating tokens"
  note "denominators: flag_warn_or_issue $(printf '%s\n' "$FW" | wc -l | tr -d ' ') lines · flag_advisory_only $(printf '%s\n' "$FA" | wc -l | tr -d ' ') lines · resolve_check_mode $(printf '%s\n' "$RM" | wc -l | tr -d ' ') lines · emit region $(printf '%s\n' "$EM" | wc -l | tr -d ' ') lines · input block $(printf '%s\n' "$IN" | wc -l | tr -d ' ') lines"
fi

# ── Runner ──────────────────────────────────────────────────────────────────
# Real emitters, real ISSUES, recording log(). pmo_instance_path is overridden to
# the temp mode dir; the .claude/hooks fallback is neutralised by running with a
# temp cwd so an operator's local mode file cannot leak into the result.
# DEPLOY_CHECK_MODE is set to a value that is NOT a valid mode, so that a run in
# which the mode file was not read emits nothing at all rather than quietly
# resolving to a plausible default — a loud failure, not a silent substitution.
build_runner() {  # $1 = mode-dir, $2 = out path
  { echo '#!/usr/bin/env bash'; echo 'set -uo pipefail'
    echo "pmo_instance_path() { printf '%s' \"$1\"; }"
    echo 'log() { printf "%s\n" "$1"; }'
    echo "WARN_LOG=\"$TMPD/warn.jsonl\""
    echo 'DEPLOY_CHECK_MODE="__no-mode-file-was-read__"'
    printf '%s\n' "$FW"; printf '%s\n' "$FA"; printf '%s\n' "$RM"
    echo 'run() {'; echo '  local ISSUES=0'
    echo '  local c56_out c56_mode'
    echo '  c56_out=$(cat "$1")'
    echo '  c56_mode=$(resolve_check_mode "milestone-epic-membership")'
    echo '  printf "MODE\t%s\n" "$c56_mode"'
    printf '%s\n' "$IN"
    printf '%s\n' "$EM"
    echo '  printf "ISSUES\t%s\n" "$ISSUES"'; echo '}'
    echo 'run "$1"'
  } > "$2"
}

# ── Fixtures — generated by the primitive, not hand-written ─────────────────
# m2_only.json  : a milestone whose ### Scope names a card that is NOT a member
#                 and which declares NO epic, so M1 SKIPs and M2 alone fires
# m1_only.json  : an epic-declaring milestone with a cross-epic child, ### Scope
#                 consistent with membership, so M1 alone fires
cat > "$TMPD/m2_only.json" <<'JSON'
{
  "milestones": [
    {"number": 2, "description": "### Scope\n1. #10 — a card that IS a member\n2. #77 — a card that is NOT a member\n"}
  ],
  "issues": [
    {"number": 10, "body": "", "labels": {"nodes": []}, "milestone": {"number": 2}, "parent": null}
  ]
}
JSON
cat > "$TMPD/m1_only.json" <<'JSON'
{
  "milestones": [
    {"number": 1, "description": "<!-- milestone-epic: #100 -->\n### Scope\n1. #10 — in-epic child\n2. #11 — cross-epic child\n"}
  ],
  "issues": [
    {"number": 10, "body": "", "labels": {"nodes": []}, "milestone": {"number": 1}, "parent": {"number": 100, "labels": {"nodes": []}}},
    {"number": 11, "body": "", "labels": {"nodes": []}, "milestone": {"number": 1}, "parent": {"number": 999, "labels": {"nodes": []}}}
  ]
}
JSON

mk_tsv() { /usr/bin/python3 "$PRIMITIVE" --fixture "$1" --leg all --output-format tsv 2>&1; }
mk_tsv "$TMPD/m2_only.json" > "$TMPD/m2_only.tsv"
mk_tsv "$TMPD/m1_only.json" > "$TMPD/m1_only.tsv"

# Fixture non-vacuity — the primitive must actually have produced the leg the
# arm below is about, or that arm proves nothing.
_fix_ok=1
/usr/bin/grep -qE '^M2	' "$TMPD/m2_only.tsv" || { _fix_ok=0; fail "A2 m2_only fixture produced NO M2 row — arms B/C would assert over an empty subject"; }
/usr/bin/grep -qE '^M1	' "$TMPD/m2_only.tsv" && { _fix_ok=0; fail "A2 m2_only fixture produced an M1 row — arms B/C would not isolate M2"; }
/usr/bin/grep -qE '^M1	' "$TMPD/m1_only.tsv" || { _fix_ok=0; fail "A2 m1_only fixture produced NO M1 row — arms D/E would assert over an empty subject"; }
/usr/bin/grep -qE '^M2	' "$TMPD/m1_only.tsv" && { _fix_ok=0; fail "A2 m1_only fixture produced an M2 row — arm D's FAIL: could not be attributed to M1"; }
[[ "$_fix_ok" -eq 1 ]] && pass "A2 both fixtures produced exactly the leg their arms are about (M2-only / M1-only)"

# ── Arm driver ──────────────────────────────────────────────────────────────
# $1 = fixture tsv, $2 = mode written to the mode file. Runs in a temp cwd so the
# resolver's relative .claude/hooks fallback cannot reach an operator's tree.
run_arm() {  # $1 = tsv, $2 = mode; echoes the run output
  local _md="$TMPD/mode.$2"
  mkdir -p "$_md"
  printf '%s\n' "$2" > "$_md/milestone-epic-membership.mode"
  build_runner "$_md" "$TMPD/runner.sh"
  ( cd "$TMPD" && bash "$TMPD/runner.sh" "$1" 2>&1 )
}
field() { /usr/bin/awk -F'\t' -v k="$1" '$1==k{print $2; exit}' <<<"$2"; }

# ── Arm B — SUBJECT: M2 finding at enforce must not gate ────────────────────
B_OUT="$(run_arm "$TMPD/m2_only.tsv" enforce)"
B_MODE="$(field MODE "$B_OUT")"; B_ISSUES="$(field ISSUES "$B_OUT")"
B_FAIL="$(/usr/bin/grep -c 'FAIL:' <<<"$B_OUT")"
B_ADV="$(/usr/bin/grep -c 'ADVISORY: milestone-description-reconciliation' <<<"$B_OUT")"
if [[ "$B_MODE" == "enforce" && "$B_ISSUES" == "0" && "$B_FAIL" -eq 0 && "$B_ADV" -eq 1 ]]; then
  pass "B M2 finding under mode=enforce: ISSUES=0, no FAIL:, exactly 1 ADVISORY: milestone-description-reconciliation"
else
  fail "B M2 under enforce — mode='$B_MODE' (want enforce) ISSUES='$B_ISSUES' (want 0) FAIL:=$B_FAIL (want 0) ADVISORY=$B_ADV (want 1)"
fi

# ── Arm C — warn/enforce invariance ─────────────────────────────────────────
C_OUT="$(run_arm "$TMPD/m2_only.tsv" warn)"
C_MODE="$(field MODE "$C_OUT")"; C_ISSUES="$(field ISSUES "$C_OUT")"
B_LINE="$(/usr/bin/grep 'ADVISORY: milestone-description-reconciliation' <<<"$B_OUT")"
C_LINE="$(/usr/bin/grep 'ADVISORY: milestone-description-reconciliation' <<<"$C_OUT")"
if [[ "$C_MODE" == "warn" && "$C_ISSUES" == "$B_ISSUES" && -n "$C_LINE" && "$C_LINE" == "$B_LINE" ]]; then
  pass "C same M2 fixture at mode=warn: ISSUES and the emitted M2 line are byte-identical to Arm B"
else
  fail "C warn/enforce invariance — mode='$C_MODE' (want warn) ISSUES='$C_ISSUES' vs B '$B_ISSUES'; M2 line identical=$([[ "$C_LINE" == "$B_LINE" ]] && echo yes || echo no)"
fi

# ── Arm D — SENSITIVITY CONTROL: gating IS observable by this harness ───────
# Without a non-zero here, Arms B and C are a BROKEN PROBE, not a clean result.
D_OUT="$(run_arm "$TMPD/m1_only.tsv" enforce)"
D_MODE="$(field MODE "$D_OUT")"; D_ISSUES="$(field ISSUES "$D_OUT")"
D_FAIL="$(/usr/bin/grep -c 'FAIL:  milestone-epic M1' <<<"$D_OUT")"
if [[ "$D_MODE" == "enforce" && "$D_ISSUES" == "1" && "$D_FAIL" -ge 1 ]]; then
  pass "D SENSITIVITY: M1 finding under mode=enforce DOES gate — ISSUES=$D_ISSUES, 'FAIL:  milestone-epic M1' lines=$D_FAIL"
else
  fail "D SENSITIVITY CONTROL FAILED — mode='$D_MODE' ISSUES='$D_ISSUES' (want 1) FAIL:=$D_FAIL (want >=1). Arms B and C are therefore UNUSABLE, not clean: a zero whose control arm also returns zero is a BROKEN PROBE"
fi

# ── Arm E — SPECIFICITY CONTROL: the mode file is genuinely being read ──────
E_OUT="$(run_arm "$TMPD/m1_only.tsv" warn)"
E_MODE="$(field MODE "$E_OUT")"; E_ISSUES="$(field ISSUES "$E_OUT")"
E_FAIL="$(/usr/bin/grep -c 'FAIL:' <<<"$E_OUT")"
E_WARN="$(/usr/bin/grep -c 'WARN:  milestone-epic-membership' <<<"$E_OUT")"
if [[ "$E_MODE" == "warn" && "$E_ISSUES" == "0" && "$E_FAIL" -eq 0 && "$E_WARN" -ge 1 ]]; then
  pass "E SPECIFICITY: same M1 fixture at mode=warn resolves 'warn', ISSUES=0, no FAIL:, $E_WARN WARN: line(s) — so D's FAIL: came from enforce and nothing else"
else
  fail "E SPECIFICITY CONTROL FAILED — mode='$E_MODE' (want warn) ISSUES='$E_ISSUES' (want 0) FAIL:=$E_FAIL (want 0) WARN:=$E_WARN (want >=1). D's FAIL: cannot be attributed to enforce mode"
fi

# ── Arm F — AC-3 standing regression ────────────────────────────────────────
# Zero flag_warn_or_issue call sites whose nearest preceding contiguous comment
# block (<=30 lines back) asserts unconditional warn-only. The denominator is
# REPORTED rather than pinned to a literal: a pinned count turns this arm into a
# count-drift alarm that reddens on any unrelated leg landing, and the corpus
# deliberately states no such cardinality. What must hold is (a) the denominator
# is non-empty, (b) the subject is 0, and (c) the sensitivity arm — the same
# claim predicate over the flag_advisory_only call sites — returns >=1. If (c)
# returns 0 the probe is BROKEN and the population is NOT reported clean.
F_TSV="$(/usr/bin/python3 - "$DEPLOY_SH" <<'PYEOF'
import re, sys
lines = open(sys.argv[1], encoding='utf-8').read().split('\n')
CLAIM = re.compile(
    r'warn[- ]only\s+(always|regardless)'
    r'|never\s+gates?'
    r'|independent\s+of\s+mode'
    r'|unconditionally\s+advisory'
    r'|advisory\s+(always|regardless)', re.I)
COMMENT = re.compile(r'^[ \t]*#')

def governing(i):
    """Nearest preceding contiguous comment block, bounded to a 30-line lookback."""
    limit = max(0, i - 30)
    j = i - 1
    while j >= limit and not COMMENT.match(lines[j]):
        j -= 1
    if j < limit:
        return None
    end = j
    while j >= 0 and COMMENT.match(lines[j]):
        j -= 1
    return '\n'.join(lines[j + 1:end + 1])

def census(fn):
    pat = re.compile(r'^[ \t]+' + re.escape(fn) + r' ')
    sites = [i for i, l in enumerate(lines) if pat.match(l)]
    withc = [i for i in sites if governing(i)]
    hits = [i + 1 for i in withc if CLAIM.search(governing(i))]
    return len(sites), len(withc), hits

for fn in ('flag_warn_or_issue', 'flag_advisory_only'):
    n, wc, hits = census(fn)
    print('%s\t%d\t%d\t%s' % (fn, n, wc, ','.join(str(h) for h in hits) or '-'))
PYEOF
)"
F_SUBJ_N=$(/usr/bin/awk -F'\t' '$1=="flag_warn_or_issue"{print $2}' <<<"$F_TSV")
F_SUBJ_C=$(/usr/bin/awk -F'\t' '$1=="flag_warn_or_issue"{print $3}' <<<"$F_TSV")
F_SUBJ_H=$(/usr/bin/awk -F'\t' '$1=="flag_warn_or_issue"{print $4}' <<<"$F_TSV")
F_CTRL_N=$(/usr/bin/awk -F'\t' '$1=="flag_advisory_only"{print $2}' <<<"$F_TSV")
F_CTRL_H=$(/usr/bin/awk -F'\t' '$1=="flag_advisory_only"{print $4}' <<<"$F_TSV")
F_CTRL_K=0; [[ "$F_CTRL_H" != "-" ]] && F_CTRL_K=$(/usr/bin/awk -F',' '{print NF}' <<<"$F_CTRL_H")
if [[ "${F_SUBJ_N:-0}" -eq 0 || "${F_SUBJ_C:-0}" -eq 0 ]]; then
  fail "F BROKEN PROBE — the call-site census extracted nothing (sites=${F_SUBJ_N:-0}, with a governing comment=${F_SUBJ_C:-0}). The population is NOT reported clean"
elif [[ "$F_CTRL_K" -lt 1 ]]; then
  fail "F BROKEN PROBE — the claim predicate found 0 hits on its sensitivity arm (flag_advisory_only, ${F_CTRL_N:-0} call sites). A zero whose control arm also returns zero is not a clean result"
elif [[ "$F_SUBJ_H" != "-" ]]; then
  fail "F a flag_warn_or_issue call site still claims unconditional warn-only in its governing comment — deploy.sh line(s): $F_SUBJ_H (denominator $F_SUBJ_N)"
else
  pass "F 0 of $F_SUBJ_N flag_warn_or_issue call sites claim unconditional warn-only ($F_SUBJ_C carry a governing comment); sensitivity arm returns $F_CTRL_K hit(s) over $F_CTRL_N flag_advisory_only call sites"
fi

echo "─────────────────────────────────────────────────────────────────────────"
echo "Result: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
[[ "$FAIL_COUNT" -eq 0 ]] || exit 1

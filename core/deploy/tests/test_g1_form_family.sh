#!/usr/bin/env bash
# test_g1_form_family.sh — regression net for the deploy.sh Check 22 form-family
# scope rule (Template Detection Logic Step 0, gate-criteria-spec.md § Gate 1).
#
# What this proves, and why each arm exists:
#
#   The scope rule partitions the bundled population into FOUR form families —
#   F0 multi-tier / F1 governance-intake / F2 kind-form / F3 unresolved-form —
#   and then decides, per issue, which G1 criteria read it. Two properties carry
#   the whole design, and neither is self-evident from reading the code:
#
#     (1) TOTALITY. Every issue lands in exactly one family, so "the gate is
#         silent on this card" is unreachable. The arms below drive one fixture
#         per family and assert a determinate verdict for each — including the
#         F0 cell, which is EMPTY on the live population and is therefore exactly
#         the kind of branch that rots unobserved.
#
#     (2) DERIVED APPLICABILITY. F2's per-criterion scope comes from the ISSUE
#         BODY's declared field sections, never from a per-family assertion and
#         never from a kind literal. This matters because field presence VARIES
#         WITHIN the family: the story kind form declares a required Acceptance
#         Criteria field whose own description restates the patterns G1-05a
#         enforces, while the epic kind form declares no AC, no Evidence and no
#         Priority. A family-wide "kind forms have no fields" exemption is wrong
#         on the story cell, and wrong silently. Arms B/C pin both directions.
#
#   The kind vocabulary is read FROM THE PACK SSOT at test time, exactly as the
#   check reads it. This test therefore contains no kind literal either: add a
#   kind to a pack and the per-kind arm covers it with no edit here.
#
# Hermetic: no `gh`, no network, no live tracker. The fixture population is
# synthetic JSON; the pack corpus is the repo's own.
#
# Executable-glue by construction: the evaluation region is EXTRACTED FROM
# deploy.sh between the C22-EVAL sentinel markers and executed. A green run
# therefore means the shipped path behaves, not that a copy of it does.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"
SRC_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
KIND_TOOL="${SRC_ROOT}/core/deploy/tools/check-work-hierarchy.py"

PASS_COUNT=0
FAIL_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf '  FAIL  %s\n' "$1"; }

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

echo "G1 form-family scope regression — deploy.sh Check 22 Step 0"
echo "─────────────────────────────────────────────────────────────────────────"

# ── A. Extract the shipped evaluation region ────────────────────────────────
build_runner() {
  # $1 = deploy.sh to extract from, $2 = output runner path
  local _src="$1" _out="$2" _b _e
  _b=$(/usr/bin/grep -m1 -n '>>> C22-EVAL-BEGIN' "$_src" | cut -d: -f1)
  _e=$(/usr/bin/grep -m1 -n '>>> C22-EVAL-END' "$_src" | cut -d: -f1)
  [[ -n "$_b" && -n "$_e" && "$_e" -gt "$_b" ]] || return 1
  {
    echo '#!/usr/bin/env bash'
    echo 'set -uo pipefail'
    echo 'flag_g1_enforcement() { printf "FLAG\t%s\n" "$2"; }'
    echo 'recommend_g1_enforcement() { printf "REC\t%s\n" "$2"; }'
    echo "_audit_src_root=\"\${FIXTURE_SRC_ROOT:-${SRC_ROOT}}\""
    echo 'G1_TITLE_MIN_CHARS=12'
    echo 'run_c22() {'
    echo '  local c22_issues_json c22_issue_count c22_finding_count'
    echo '  c22_issues_json=$(cat "$1")'
    echo '  c22_issue_count=$(printf "%s" "$c22_issues_json" | jq "length")'
    echo '  c22_finding_count=0'
    /usr/bin/sed -n "$((_b + 1)),$((_e - 1))p" "$_src"
    echo '  printf "COUNT\t%s\n" "$c22_finding_count"'
    echo '}'
    echo 'run_c22 "$1"'
  } > "$_out"
  return 0
}

RUNNER="$TMPD/runner.sh"
if build_runner "$DEPLOY_SH" "$RUNNER"; then
  _rl=$(/usr/bin/grep -c '' "$RUNNER")
  if [[ "$_rl" -ge 150 ]]; then
    pass "A evaluation region extracted from deploy.sh between the C22-EVAL sentinels (${_rl} lines)"
  else
    fail "A extraction returned only ${_rl} lines — the sentinels are present but the region is implausibly small"
  fi
else
  fail "A could not extract the C22-EVAL region from deploy.sh (missing or inverted sentinel markers)"
  echo "Result: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
  exit 1
fi

# Non-vacuity: the extracted runner must actually run and emit a COUNT row.
run_fixture() { bash "$RUNNER" "$1" 2>"$TMPD/run.err"; }

# ── The licensed kind vocabulary, read from the SSOT (no literal in this file) ──
KINDS="$(/usr/bin/python3 "$KIND_TOOL" --root "$SRC_ROOT" --emit-kinds 2>"$TMPD/kinds.err")"
KIND_RC=$?
if [[ "$KIND_RC" -eq 0 && -n "$KINDS" ]]; then
  pass "A kind vocabulary resolved from the pack SSOT ($(printf '%s' "$KINDS" | /usr/bin/tr '\n' ' '))"
else
  fail "A kind vocabulary unresolvable (rc=$KIND_RC): $(/usr/bin/head -1 "$TMPD/kinds.err" 2>/dev/null)"
fi

# ── Fixture builder ─────────────────────────────────────────────────────────
# Bodies are written as literal issue-form renders (`### <Field>` headings), the
# shape GitHub Issue Forms actually produces.
json_str() { /usr/bin/python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))'; }

# State lives in FILES, not shell variables: `add_fixture` is invoked inside a
# command substitution so the caller can capture the issue number, and a
# subshell's variable writes are discarded on return. A file-backed accumulator
# is the only form that survives that, and getting it wrong is silent — the
# fixture set comes back EMPTY and every assertion below passes vacuously.
FIXTURE_ROWS_FILE="$TMPD/rows.ndjson"
FIXTURE_SEQ_FILE="$TMPD/seq"
: > "$FIXTURE_ROWS_FILE"
echo 0 > "$FIXTURE_SEQ_FILE"

add_fixture() {
  # $1 title, $2 comma-separated labels, $3 body — echoes the fixture's number.
  local _seq _num _labels="" _l _t _b _old_ifs
  _seq=$(( $(cat "$FIXTURE_SEQ_FILE") + 1 ))
  printf '%s\n' "$_seq" > "$FIXTURE_SEQ_FILE"
  _num=$((900000 + _seq))
  _old_ifs="$IFS"; IFS=','
  for _l in $2; do
    [[ -n "$_l" ]] || continue
    _labels="${_labels}{\"name\":\"${_l}\"},"
  done
  IFS="$_old_ifs"
  _t=$(printf '%s' "$1" | json_str)
  _b=$(printf '%s' "$3" | json_str)
  printf '{"number":%s,"title":%s,"body":%s,"labels":[%s]}\n' \
    "$_num" "$_t" "$_b" "${_labels%,}" >> "$FIXTURE_ROWS_FILE"
  printf '%s' "$_num"
}
write_fixtures() {
  /usr/bin/python3 -c 'import json,sys
rows=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
json.dump(rows, open(sys.argv[2],"w"))' "$FIXTURE_ROWS_FILE" "$1"
}
fixture_count() { /usr/bin/grep -c '' "$FIXTURE_ROWS_FILE" | /usr/bin/tr -d ' '; }

CONFORMING_AC='### Acceptance Criteria

- [ ] Verify that `core/deploy/deploy.sh` contains the form-family branch
'
NONCONFORMING_AC='### Acceptance Criteria

- [ ] It should probably work better than before
'

# One fixture PER LIVE KIND, generated from the SSOT vocabulary. Each is the
# field-less shape (the epic/story kind forms declare no Evidence and no
# Priority) EXCEPT that we additionally emit a story-shaped body carrying AC.
KIND_NUMS=""
while IFS= read -r _k; do
  [[ -n "$_k" ]] || continue
  n=$(add_fixture "Reconcile the ${_k} surface with the declared scope rule" \
        "type:${_k},status: bundled" \
        "### Outcome

A ${_k}-shaped body declaring no Evidence, no Priority and no Acceptance Criteria field.
")
  KIND_NUMS="${KIND_NUMS}${_k}:${n} "
done < <(printf '%s\n' "$KINDS")

# F2 + AC present (the story cell PR-1 named) — must be evaluated for G1-05a.
N_AC_BAD=$(add_fixture "Add the pack-resolved kind set to the applicability rule" \
  "type:story,status: bundled" "### Value

As an operator, I need the scope rule stated.

${NONCONFORMING_AC}")
N_AC_GOOD=$(add_fixture "Add the pack-resolved kind set to the applicability rule" \
  "type:story,status: bundled" "### Value

As an operator, I need the scope rule stated.

${CONFORMING_AC}")

# F2 riding the interim improvement.yml vehicle — the form declares the fields,
# the body carries them, so all three field-keyed criteria must reach it. This is
# the cohort a form-keyed exemption could not evaluate at all (no dedicated form
# exists for these kinds, so "the form it was authored on" has no evaluator).
N_INTERIM=$(add_fixture "Carry the interim vehicle body through the kind-form path" \
  "type:task,status: bundled" "### Priority

P2 - High

### Evidence

[SOURCE] measured at the build anchor.

${CONFORMING_AC}")

# F1 governance-intake CONTROL — must take the unchanged path.
N_F1_CLEAN=$(add_fixture "Reconcile the intake control against the applicability rule" \
  "improvement,status: bundled" "### Priority

P2 - High

### Description

A conforming improvement body.

### Evidence

[SOURCE] measured at the build anchor.

### Proposed Change

Change \`core/deploy/deploy.sh\`.

${CONFORMING_AC}")
# F1 that must FAIL — proves the harness can emit, so a clean control is meaningful.
N_F1_BAD=$(add_fixture "Reconcile the intake control against the applicability rule" \
  "improvement,status: bundled" "### Description

No evidence label, no priority, non-conforming AC.

### Proposed Change

Change \`core/deploy/deploy.sh\`.

${NONCONFORMING_AC}")

# F0 — two intake-tier labels. Population is ZERO live; this is the only place
# the branch is exercised at all.
N_F0=$(add_fixture "Reconcile the multi-tier card against the applicability rule" \
  "improvement,bug,status: bundled" "### Description

Two intake-tier labels.
")

# F3 — a `type:*` label the packs do NOT declare.
N_F3=$(add_fixture "Reconcile the unlicensed-kind card against the applicability rule" \
  "type:zzq-unlicensed,status: bundled" "### Notes

No intake-tier label and no pack-declared kind.
")

# ── G1-05a PRESENCE fixtures (#4232) ────────────────────────────────────────
# The presence arm asks a different question from the shape arm: does the card
# carry an Acceptance Criteria section with at least one criterion at all? The
# shipped check could not answer it — it counted non-conforming checkbox bullets
# and emitted only when that count exceeded zero, so a body with NO AC bullets
# produced zero non-conforming bullets and passed silently. It had never once
# emitted an AC-absence finding, which is why every arm below is paired with a
# control: an arm set that only proves "AC-bearing cards pass" would be green
# against the defect itself.
AC_INTAKE_HEAD='### Priority

P2 - High

### Description

A conforming improvement body.

### Evidence

[SOURCE] measured at the build anchor.

### Proposed Change

Change `core/deploy/deploy.sh`.

'
# AC-1 — H2 pre-template AC. This is the era the card exists to protect: a
# predicate keyed to the H3 template heading scores a false FAIL on every one.
N_AC_H2=$(add_fixture "Reconcile the pre-template body against the presence arm" \
  "improvement,status: bundled" "${AC_INTAKE_HEAD}## Acceptance Criteria

- [ ] Verify that \`core/deploy/deploy.sh\` carries the presence arm
")
# AC-2 — H3 template AC.
N_AC_H3=$(add_fixture "Reconcile the template body against the presence arm" \
  "improvement,status: bundled" "${AC_INTAKE_HEAD}${CONFORMING_AC}")
# AC-3 — template-correct AC whose criteria are an ORDERED LIST. Presence must
# PASS; the shape arm must stay silent, because widening shape to ordered lists
# is a different card's scope and would mass-FAIL conformant cards.
N_AC_ORDERED=$(add_fixture "Reconcile the ordered-list body against the presence arm" \
  "improvement,status: bundled" "${AC_INTAKE_HEAD}### Acceptance Criteria

1. Verify that \`core/deploy/deploy.sh\` carries the presence arm
2. Confirm the empty-section control fails
")
# AC-4 CONTROL — heading present, ZERO criteria beneath it. This is the exact
# empty-set shape the shipped verdict line failed open on.
N_AC_EMPTY=$(add_fixture "Reconcile the empty-section body against the presence arm" \
  "improvement,status: bundled" "${AC_INTAKE_HEAD}### Acceptance Criteria

To be authored during planning.
")
# AC-5 MUTATION CONTROL — AC-2 with the section deleted outright.
N_AC_REMOVED=$(add_fixture "Reconcile the section-removed body against the presence arm" \
  "improvement,status: bundled" "${AC_INTAKE_HEAD}")
# AC-6 — SPECIFICITY. The sub-task scaffold heading is not the card's own AC, so
# a body carrying only that heading must read ABSENT rather than satisfied.
N_AC_XISSUE=$(add_fixture "Reconcile the cross-issue scaffold against the presence arm" \
  "improvement,status: bundled" "${AC_INTAKE_HEAD}### Cross-Issue Acceptance Criteria

- [ ] Verify the sibling card landed
")
# AC-7 — a `sub-task`-labelled AC-less card: DETECTED, never gate-blocking
# (Layer-B(d) detector tier, ADR-120 authority conjunct preserved).
N_AC_SUBTASK=$(add_fixture "Reconcile the sub-task card against the presence arm" \
  "improvement,sub-task,status: bundled" "${AC_INTAKE_HEAD}")
# AC-8 — observation tier declares no AC field, so the criterion must not read it
# at all (the `n/a` applies-to cell, preserved).
N_AC_OBS=$(add_fixture "Reconcile the observation card against the presence arm" \
  "observation,status: bundled" "### What Is Missing

An observation-shaped body declaring no Acceptance Criteria field.

### Evidence

[SOURCE] observed at the build anchor.
")

FIX="$TMPD/fixtures.json"
write_fixtures "$FIX"
FIXTURE_N=$(fixture_count)
OUT="$TMPD/out.txt"
run_fixture "$FIX" > "$OUT"
# NON-VACUITY GUARD. Every zero-valued assertion below is unreadable if the
# fixture set is empty or the runner did not execute, so both are asserted
# before any of them run.
if [[ "$FIXTURE_N" -ge 8 ]] && [[ -s "$OUT" ]] && /usr/bin/grep -q '^COUNT' "$OUT"; then
  pass "A runner executed the extracted region over ${FIXTURE_N} fixtures and emitted a COUNT row"
else
  fail "A non-vacuity: ${FIXTURE_N} fixture(s) built, output $( [[ -s "$OUT" ]] && echo present || echo EMPTY ) — every zero below would be vacuous: $(/usr/bin/head -1 "$TMPD/run.err" 2>/dev/null)"
fi

findings_for() { /usr/bin/grep -F "issue #$1 " "$OUT" || true; }
count_for() { findings_for "$1" | /usr/bin/grep -c '' | /usr/bin/tr -d ' '; }

# ── B. Every live kind yields a determinate verdict ─────────────────────────
_b_ok=true
_b_detail=""
for pair in $KIND_NUMS; do
  _k="${pair%%:*}"; _n="${pair##*:}"
  # The field-less kind body declares no AC / Evidence / Priority, so ONLY the
  # title floor may speak. Its title is a well-formed multi-word summary, so the
  # determinate verdict is CLEAN — and critically, it is NOT the label-count
  # G1-09 FAIL these cards used to receive.
  if /usr/bin/grep -q 'G1-09' <<<"$(findings_for "$_n")"; then
    _b_ok=false; _b_detail="${_b_detail}${_k} still receives a G1-09 verdict; "
  fi
  if [[ "$(count_for "$_n")" -ne 0 ]]; then
    _b_ok=false; _b_detail="${_b_detail}${_k} yielded $(count_for "$_n") finding(s) on a field-less body; "
  fi
done
if [[ "$_b_ok" == "true" ]]; then
  pass "B every live pack kind ($(printf '%s' "$KINDS" | /usr/bin/tr '\n' ' ')) yields a determinate verdict on a field-less body — no label-count G1-09"
else
  fail "B per-kind determinacy: ${_b_detail}"
fi

# ── C. Derived applicability — the direction a family-wide `n/a` gets wrong ──
if /usr/bin/grep -q 'G1-05a' <<<"$(findings_for "$N_AC_BAD")"; then
  pass "C kind-form body DECLARING Acceptance Criteria is evaluated for G1-05a (the story cell)"
else
  fail "C kind-form body declaring AC was NOT evaluated for G1-05a — the family-wide exemption is back"
fi
if [[ "$(count_for "$N_AC_GOOD")" -eq 0 ]]; then
  pass "C SPECIFICITY — a kind-form body whose AC bullets CONFORM yields no finding (the arm above is not a constant)"
else
  fail "C conforming kind-form AC still produced a finding: $(findings_for "$N_AC_GOOD")"
fi
# The contrast case: a field-less kind body must NOT be graded on AC.
_epic_like="${KIND_NUMS%% *}"; _epic_like="${_epic_like##*:}"
if ! /usr/bin/grep -q 'G1-05a' <<<"$(findings_for "$_epic_like")"; then
  pass "C CONTRAST — a kind-form body declaring NO Acceptance Criteria field is not graded on G1-05a"
else
  fail "C a field-less kind body was graded on G1-05a — applicability is not body-derived"
fi
if [[ "$(count_for "$N_INTERIM")" -eq 0 ]]; then
  pass "C interim-vehicle body (kind label, no tier label, full field set) passes all body-keyed criteria"
else
  fail "C interim-vehicle body produced unexpected finding(s): $(findings_for "$N_INTERIM")"
fi

# ── D. F0 — the empty-today cell keeps today's verdict, verbatim ─────────────
if /usr/bin/grep -q 'G1-09 FAIL: 2 intake-tier label(s)' <<<"$(findings_for "$N_F0")" \
   && /usr/bin/grep -q 'apply correct single label' <<<"$(findings_for "$N_F0")"; then
  pass "D multi-tier card keeps the pre-existing G1-09 emit AND its 'apply correct single label' remediation"
else
  fail "D multi-tier card lost its verdict or its remediation: $(findings_for "$N_F0")"
fi

# ── E. F3 — its own finding, never F1's remediation ─────────────────────────
if /usr/bin/grep -q 'UNRESOLVED-FORM' <<<"$(findings_for "$N_F3")"; then
  pass "E unlicensed-kind card receives its own UNRESOLVED-FORM finding"
else
  fail "E unlicensed-kind card did not receive an UNRESOLVED-FORM finding: $(findings_for "$N_F3")"
fi
if ! /usr/bin/grep -q 'apply correct single label' <<<"$(findings_for "$N_F3")"; then
  pass "E SPECIFICITY — the F3 finding does NOT carry F1's 'apply correct single label' remediation"
else
  fail "E the F3 finding carries F1's remediation — it instructs the author to break a correctly-labelled card"
fi

# ── F. Governance-intake control — unchanged path, and the harness can fail ──
if [[ "$(count_for "$N_F1_CLEAN")" -eq 0 ]]; then
  pass "F governance-intake control yields a clean verdict on the unchanged F1 path"
else
  fail "F governance-intake control regressed: $(findings_for "$N_F1_CLEAN")"
fi
_f1_bad=$(count_for "$N_F1_BAD")
if [[ "$_f1_bad" -ge 2 ]]; then
  pass "F CONTROL — a defective governance-intake body still emits (${_f1_bad} findings), so the clean control above is not vacuous"
else
  fail "F CONTROL — a deliberately defective intake body emitted only ${_f1_bad} finding(s); the F1 path may not be running"
fi

# ── G. Degraded kind vocabulary: ONE finding, no per-issue fan-out ───────────
# Bind to the block's named degraded-state contract: the criterion reads
# NOT-EVALUATED, never FAILED, and never once per issue.
DEGRADED_ROOT="$TMPD/degraded"
mkdir -p "$DEGRADED_ROOT/release/tools" "$DEGRADED_ROOT/core/deploy/tools"
cp "${SRC_ROOT}/release/tools/bundle-issues-parser.py" "$DEGRADED_ROOT/release/tools/" 2>/dev/null || true
DEG_OUT="$TMPD/degraded.txt"
FIXTURE_SRC_ROOT="$DEGRADED_ROOT" bash "$RUNNER" "$FIX" > "$DEG_OUT" 2>"$TMPD/deg.err"
_deg_block=$(/usr/bin/grep -c 'Step-0 form-family resolution NOT-EVALUATED' "$DEG_OUT" || true)
_deg_perissue=$(/usr/bin/grep -c "issue #${N_F3} " "$DEG_OUT" || true)
_deg_f1=$(/usr/bin/grep -c "issue #${N_F1_BAD} " "$DEG_OUT" || true)
if [[ "$_deg_block" -eq 1 ]]; then
  pass "G missing kind primitive emits EXACTLY ONE block-level finding (no fan-out)"
else
  fail "G missing kind primitive emitted ${_deg_block} block-level finding(s); expected exactly 1"
fi
if [[ "$_deg_perissue" -eq 0 ]]; then
  pass "G SPECIFICITY — with the vocabulary unavailable, no non-F0/F1 card receives a guessed per-issue verdict"
else
  fail "G a non-F0/F1 card received ${_deg_perissue} per-issue finding(s) under a degraded vocabulary — the family was guessed"
fi
if [[ "$_deg_f1" -ge 2 ]]; then
  pass "G CONTROL — F0/F1 cards are still fully evaluated under a degraded vocabulary (${_deg_f1} findings), so arm G is not measuring a dead runner"
else
  fail "G CONTROL — the degraded run evaluated no F1 card (${_deg_f1} findings); its zeros above are unreadable"
fi

# ── I. G1-05a PRESENCE arm (#4232) — the empty-set hole, closed ─────────────
# Presence and shape are separate arms. `presence_for` isolates the presence
# verdict so an arm below cannot be satisfied by a shape finding that happens to
# mention the same issue.
presence_for() { findings_for "$1" | /usr/bin/grep -F 'G1-05a FAIL (presence)' || true; }
presence_count() { presence_for "$1" | /usr/bin/grep -c '' | /usr/bin/tr -d ' '; }

_i_ok=true; _i_detail=""
for pair in "H2:$N_AC_H2" "H3:$N_AC_H3" "ordered-list:$N_AC_ORDERED"; do
  _lbl="${pair%%:*}"; _n="${pair##*:}"
  if [[ "$(presence_count "$_n")" -ne 0 ]]; then
    _i_ok=false; _i_detail="${_i_detail}${_lbl} body wrongly flagged absent; "
  fi
done
if [[ "$_i_ok" == "true" ]]; then
  pass "I an AC-bearing card passes the presence arm at H2, at H3, and with ordered-list criteria — heading depth and template era do not decide the verdict"
else
  fail "I presence false-positives: ${_i_detail}"
fi

# The ordered-list card must be CLEAN OVERALL, not merely presence-clean: if the
# presence work leaked into the shape arm, this is where it shows up.
if [[ "$(count_for "$N_AC_ORDERED")" -eq 0 ]]; then
  pass "I BOUNDARY — an ordered-list AC card yields NO finding of any kind; the presence arm did not widen the checkbox-scoped shape arm"
else
  fail "I ordered-list AC card produced finding(s) — presence leaked into shape: $(findings_for "$N_AC_ORDERED")"
fi

# CONTROL — heading present, zero criteria. Without this the arms above are
# satisfiable by a predicate that returns "present" unconditionally.
if [[ "$(presence_count "$N_AC_EMPTY")" -eq 1 ]] \
   && /usr/bin/grep -qF 'zero criteria' <<<"$(presence_for "$N_AC_EMPTY")"; then
  pass "I CONTROL — an AC heading with zero criteria FAILS the presence arm exactly once, and the message names emptiness rather than absence"
else
  fail "I empty AC section did not produce exactly one emptiness finding: $(presence_for "$N_AC_EMPTY")"
fi

# MUTATION CONTROL — the card's AC #3: delete the section, verdict flips.
if [[ "$(presence_count "$N_AC_REMOVED")" -eq 1 ]] \
   && /usr/bin/grep -qF 'no Acceptance Criteria section found' <<<"$(presence_for "$N_AC_REMOVED")"; then
  pass "I MUTATION CONTROL — removing the AC section from a passing body flips it to a presence FAIL naming absence (the pre-change verdict on this body was silence)"
else
  fail "I section-removed body did not flip to an absence finding: $(presence_for "$N_AC_REMOVED")"
fi

# SPECIFICITY — the sub-task scaffold heading is not the card's own AC.
if [[ "$(presence_count "$N_AC_XISSUE")" -eq 1 ]]; then
  pass "I SPECIFICITY — a body carrying only '### Cross-Issue Acceptance Criteria' reads ABSENT; the match is prefix-anchored, not a substring search"
else
  fail "I cross-issue scaffold heading was accepted as the card's own AC: $(presence_for "$N_AC_XISSUE")"
fi

# AUTHORITY — a sub-task card is DETECTED but never gate-blocking (ADR-120).
_sub_flag=$(presence_for "$N_AC_SUBTASK" | /usr/bin/grep -c '^FLAG' || true)
_sub_rec=$(presence_for "$N_AC_SUBTASK" | /usr/bin/grep -c '^REC' || true)
if [[ "$_sub_flag" -eq 0 && "$_sub_rec" -eq 1 ]]; then
  pass "I AUTHORITY — an AC-less sub-task card is DETECTED at the recommend tier (${_sub_rec}) and never gate-blocking (${_sub_flag}); the presence arm inherited the router rather than adding an emitter"
else
  fail "I sub-task authority wrong: FLAG=${_sub_flag} REC=${_sub_rec} (expected 0 / 1)"
fi

# APPLICABILITY — observation declares no AC field, so it is not evaluated.
if [[ "$(presence_count "$N_AC_OBS")" -eq 0 ]]; then
  pass "I APPLICABILITY — an observation-tier card is not graded on AC presence; the 'n/a' applies-to cell is preserved"
else
  fail "I observation card was graded on AC presence: $(presence_for "$N_AC_OBS")"
fi

# ── J. Degraded AC primitive: ONE finding, no per-issue fan-out ──────────────
# Bind the same degraded-state contract the priority and kind delegates name: a
# degraded measurement is never rendered as a clean one, and never fanned out.
AC_DEGRADED_ROOT="$TMPD/ac_degraded"
mkdir -p "$AC_DEGRADED_ROOT/release/tools" "$AC_DEGRADED_ROOT/core/deploy/tools"
cp "$KIND_TOOL" "$AC_DEGRADED_ROOT/core/deploy/tools/" 2>/dev/null || true
cp -R "${SRC_ROOT}/core/deploy/packs" "$AC_DEGRADED_ROOT/core/deploy/" 2>/dev/null || true
AC_DEG_OUT="$TMPD/ac_degraded.txt"
FIXTURE_SRC_ROOT="$AC_DEGRADED_ROOT" bash "$RUNNER" "$FIX" > "$AC_DEG_OUT" 2>"$TMPD/ac_deg.err"
_acdeg_block=$(/usr/bin/grep -c 'G1-05a presence NOT EVALUATED' "$AC_DEG_OUT" || true)
_acdeg_perissue=$(/usr/bin/grep -c 'G1-05a FAIL (presence)' "$AC_DEG_OUT" || true)
if [[ "$_acdeg_block" -eq 1 ]]; then
  pass "J missing AC primitive emits EXACTLY ONE population-wide NOT-EVALUATED finding (no fan-out)"
else
  fail "J missing AC primitive emitted ${_acdeg_block} block-level finding(s); expected exactly 1"
fi
if [[ "$_acdeg_perissue" -eq 0 ]]; then
  pass "J SPECIFICITY — with the primitive unavailable the criterion reads NOT-EVALUATED, never FAILED: zero per-issue presence verdicts"
else
  fail "J ${_acdeg_perissue} per-issue presence FAIL(s) under a degraded primitive — one root cause was fanned out into per-card verdicts"
fi
# CONTROL — the degraded run must still be a LIVE run, or its zeros are unreadable.
_acdeg_live=$(/usr/bin/grep -c "issue #${N_F1_BAD} " "$AC_DEG_OUT" || true)
if [[ "$_acdeg_live" -ge 2 ]]; then
  pass "J CONTROL — cards are still evaluated on the other criteria under a degraded AC primitive (${_acdeg_live} findings), so arm J's zeros are not measuring a dead runner"
else
  fail "J CONTROL — the degraded run evaluated nothing (${_acdeg_live} findings); its zeros above are unreadable"
fi
# CONTROL — the SAME probe on the healthy run must be non-zero, or "0 per-issue
# presence findings" above is a property of the fixtures, not of degradation.
_ac_healthy=$(/usr/bin/grep -c 'G1-05a FAIL (presence)' "$OUT" || true)
if [[ "$_ac_healthy" -ge 3 ]]; then
  pass "J CONTROL — the identical probe finds ${_ac_healthy} presence verdict(s) on the healthy run; arm J measures degradation, not an empty fixture set"
else
  fail "J CONTROL — the healthy run produced only ${_ac_healthy} presence verdict(s); arm J cannot distinguish degraded from clean"
fi

# ── H. Anti-drift: the vocabulary stays DELEGATED and stays literal-free ─────
# Restricted to NON-COMMENT lines. A bare substring search over the whole file
# matches this block's own prose, which is how an earlier sibling guard shipped
# unable to detect its own regression.
c22_code_lines() {
  /usr/bin/sed -n '/─── Check 22: G1 enforcement on bundled issues/,/─── Check 23:/p' "$1" \
    | /usr/bin/grep -vE '^[[:space:]]*#'
}
_delegated=$(c22_code_lines "$DEPLOY_SH" | /usr/bin/grep -c -- '--emit-kinds' || true)
if [[ "$_delegated" -ge 1 ]]; then
  pass "H the kind vocabulary is resolved by delegation in LIVE CODE (${_delegated} non-comment reference(s))"
else
  fail "H no non-comment --emit-kinds delegation in the Check-22 block — the vocabulary may have been re-implemented inline"
fi
_literals=$(c22_code_lines "$DEPLOY_SH" \
  | /usr/bin/grep -cE 'type:(epic|story|task|card)\b' || true)
if [[ "$_literals" -eq 0 ]]; then
  pass "H SPECIFICITY — no hardcoded kind literal appears in the block's live code (${_literals})"
else
  fail "H ${_literals} hardcoded kind literal(s) in the Check-22 live code — the scope rule is no longer config-resolved"
fi
# The control that makes H meaningful: the naive whole-file substring form is
# green whether or not the delegation survives, so it could never have caught
# a regression. Demonstrated by running it against a tree with the call removed.
REGRESSED="$TMPD/deploy_regressed.sh"
/usr/bin/sed 's/--emit-kinds 2>&1/--no-such-flag 2>\&1/' "$DEPLOY_SH" > "$REGRESSED"
_naive=$(/usr/bin/grep -c -- '--emit-kinds' "$REGRESSED" || true)
_tight=$(c22_code_lines "$REGRESSED" | /usr/bin/grep -c -- '--emit-kinds' || true)
if [[ "$_naive" -ge 1 && "$_tight" -eq 0 ]]; then
  pass "H CONTROL — on a regressed tree the naive whole-file form stays green (${_naive}) while the non-comment form goes red (${_tight}); the restriction is load-bearing"
else
  fail "H CONTROL — could not demonstrate the naive form's blindness (naive=${_naive}, tight=${_tight}); arm H's claim is unproven"
fi

# ── K. Anti-drift: AC presence stays DELEGATED and stays on the shared router ─
# Two properties that are invisible at runtime but decide what a future edit is
# allowed to do, so they are asserted as facts rather than left to the comments.
_ac_delegated=$(c22_code_lines "$DEPLOY_SH" | /usr/bin/grep -c 'parse_acceptance_criteria' || true)
if [[ "$_ac_delegated" -ge 1 ]]; then
  pass "K AC presence is resolved by delegation in LIVE CODE (${_ac_delegated} non-comment reference(s)) — no heading grammar is authored in deploy.sh"
else
  fail "K no non-comment parse_acceptance_criteria delegation in the Check-22 block — the predicate may have been re-implemented inline"
fi
# The presence emit must go through _c22_emit_structural. That router is what
# carries BOTH the ADR-120 gating-authority conjunct and the check-wide
# G1_ENFORCEMENT_MODE posture; a bespoke emitter here would silently escape the
# warn mode this arm ships under and the detector tier it owes sub-task cards.
# The emit CALL sits exactly one line above its message, so a one-line lookback
# is the correct window: it pairs each message with its own caller rather than
# with a neighbour's, which a wider window would silently do.
_ac_emit_sites=$(c22_code_lines "$DEPLOY_SH" | /usr/bin/grep -c 'G1-05a FAIL (presence)' || true)
_ac_router=$(c22_code_lines "$DEPLOY_SH" \
  | /usr/bin/grep -B1 'G1-05a FAIL (presence)' \
  | /usr/bin/grep -c '_c22_emit_structural' || true)
if [[ "$_ac_emit_sites" -ge 1 && "$_ac_router" -eq "$_ac_emit_sites" ]]; then
  pass "K every presence emit (${_ac_emit_sites}) routes through _c22_emit_structural — it inherits the ADR-120 authority conjunct and the g1-enforcement.mode posture rather than declaring its own"
else
  fail "K ${_ac_emit_sites} presence emit site(s) but ${_ac_router} routed through _c22_emit_structural — a bespoke emitter escapes both the authority router and the mode"
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf 'Result: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "G1 form-family scope regression: FAILED"
  exit 1
fi
echo "G1 form-family scope regression: PASSED"
exit 0

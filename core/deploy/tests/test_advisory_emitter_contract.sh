#!/usr/bin/env bash
# test_advisory_emitter_contract.sh — static conformance assertion for
# flag_advisory_only's calling contract.
#
# WHY THIS HARNESS EXISTS, AND WHY IT IS STATIC.
#
#   flag_advisory_only's contract requires a third argument naming the SCOPE of
#   its non-gating claim — id-non-gating or arm-non-gating. A caller that omits
#   it, or that declares a scope its own check_id's behaviour contradicts, must
#   fail LOUDLY.
#
#   The loudness cannot live inside the emitter. Raising there needs an
#   escalation path in that body, and the ABSENCE of one is the emitter's whole
#   class guarantee — the property its header states, ADR-134 D3 fixes, and
#   test_check56_m2_advisory.sh Arms B and C execute against a real failure
#   counter. Adding a raise to satisfy one acceptance criterion would falsify
#   three artifacts that depend on its absence.
#
#   So the contract is graded HERE instead, outside the body, at CI time. A
#   missing token and a contradicted posture are both build failures, and the
#   emitter stays structurally incapable of gating. That trade is the whole
#   design; it is recorded in the ADR this harness ships with.
#
# WHY IT EXTRACTS RATHER THAN COPIES. Every region under assertion is pulled
# from deploy.sh at RUN time. A pasted copy drifts from the shipped code
# silently, and a green arm over a stale copy is the vacuous pass this harness
# exists to prevent.
#
# WHY NO CALL-SITE COUNT IS PINNED. Denominators are REPORTED, never asserted
# against a literal. A pinned count turns a conformance gate into a count-drift
# alarm that reddens when an unrelated advisory leg lands or retires — the
# failure mode test_check56_m2_advisory.sh Arm F documents on its own subject.
# What must hold is that the denominator is non-empty, the subject is zero, and
# a sensitivity arm over a deliberately mutated copy returns non-zero.
#
# DECLARED COVERAGE BOUNDARY — stated, not implied.
#   * This harness asserts that SHARED CODE cannot ship a per-caller fact: the
#     emitter body carries no authority literal and no hardcoded posture. A
#     caller that writes a wrong authority into its OWN `detail` prose is NOT
#     detected — `detail` is caller-owned free text for every emitter in this
#     family, and grading it is a different instrument.
#   * The posture token is graded as the FINAL argument of the invocation, a
#     bare double-quoted literal from the closed set. A token passed through a
#     variable would read as missing. That is deliberate: the contract is a
#     literal from a closed set, and a variable cannot be graded statically.
#   * Escalation is measured per check_id from the two escalating emitters
#     (flag_warn_or_issue, flag_g1_enforcement), which both key on check_id as
#     their first argument. A bare `ISSUES` increment is NOT attributable to an
#     id and is deliberately out of the measurement; where one exists it sits
#     alongside an id that already measures as escalating.
#
# Hermetic: no gh, no network, no writes outside its own temp directory.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"

PASS_COUNT=0; FAIL_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT+1)); printf '  PASS  %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT+1)); printf '  FAIL  %s\n' "$1"; }
note() { printf '        %s\n' "$1"; }
TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT

echo "Advisory emitter contract — deploy.sh flag_advisory_only"
echo "─────────────────────────────────────────────────────────────────────────"

if [[ ! -r "$DEPLOY_SH" ]]; then
  fail "deploy.sh not readable at $DEPLOY_SH — every arm below would pass on nothing"
  echo "Result: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
  exit 1
fi

# ── The census engine ───────────────────────────────────────────────────────
# Written once and re-used by every arm, INCLUDING the mutated-copy sensitivity
# arms. One engine is the point: a sensitivity arm that ran a different
# predicate from its subject would prove nothing about the subject.
CENSUS_PY="$TMPD/census.py"
cat > "$CENSUS_PY" <<'PYEOF'
import re
import sys

POSTURES = ('id-non-gating', 'arm-non-gating')
ADVISORY = 'flag_advisory_only'
ESCALATING = ('flag_warn_or_issue', 'flag_g1_enforcement')
# A gate identifier as the corpus spells them: G-CL9, G-EX9, G6, ...
GATE_ID = re.compile(r'\bG-[A-Z]{1,4}\d+\b')

lines = open(sys.argv[1], encoding='utf-8').read().split('\n')


def logical(i):
    """Join a call site's physical lines across trailing-backslash continuations.

    Returns (joined_text, index_of_final_physical_line). The posture token is the
    final argument, so a site whose arguments wrap must be read to its last line
    or the token reads as absent on every wrapped caller."""
    j = i
    parts = [lines[j]]
    while lines[j].rstrip().endswith('\\') and j + 1 < len(lines):
        j += 1
        parts.append(lines[j])
    return ' '.join(p.rstrip().rstrip('\\').strip() for p in parts), j


def sites(fn):
    pat = re.compile(r'^[ \t]+' + re.escape(fn) + r'\s')
    return [i for i, l in enumerate(lines) if pat.match(l)]


def first_quoted(text):
    m = re.search(r'"([^"]+)"', text)
    return m.group(1) if m else None


def trailing_token(text):
    m = re.search(r'"([^"]*)"\s*$', text.rstrip())
    return m.group(1) if m else None


# ── the advisory population ────────────────────────────────────────────────
adv = []
for i in sites(ADVISORY):
    text, last = logical(i)
    adv.append({
        'line': i + 1,
        'last': last + 1,
        'id': first_quoted(text),
        'posture': trailing_token(text),
    })

missing = [a for a in adv if a['posture'] not in POSTURES]
families = sorted({a['id'] for a in adv if a['id']})

# ── the escalation surface, keyed by check_id ──────────────────────────────
esc = {}
esc_total = 0
for fn in ESCALATING:
    for i in sites(fn):
        text, _ = logical(i)
        cid = first_quoted(text)
        esc_total += 1
        if cid:
            esc[cid] = esc.get(cid, 0) + 1

# ── declared posture vs measured escalation ────────────────────────────────
contradictions = []
for a in adv:
    if a['posture'] not in POSTURES or not a['id']:
        continue           # a missing token is AE-B's finding, not AE-C's
    n = esc.get(a['id'], 0)
    if a['posture'] == 'id-non-gating' and n > 0:
        contradictions.append('%d:%s:declared-id-non-gating:measured-%d-escalating'
                              % (a['line'], a['id'], n))
    if a['posture'] == 'arm-non-gating' and n == 0:
        contradictions.append('%d:%s:declared-arm-non-gating:measured-0-escalating'
                              % (a['line'], a['id']))

# ── the emitter body ───────────────────────────────────────────────────────
body = []
on = False
for l in lines:
    if l == '  %s() {' % ADVISORY:
        on = True
    if on:
        body.append(l)
    if on and l == '  }':
        break
body_txt = '\n'.join(body)

body_gate = GATE_ID.findall(body_txt)
callsite_gate = []
for a in adv:
    text, _ = logical(a['line'] - 1)
    callsite_gate.extend(GATE_ID.findall(text))

out = [
    ('SITES', len(adv)),
    ('FAMILIES', len(families)),
    ('MISSING', len(missing)),
    ('MISSING_LINES', ','.join(str(a['line']) for a in missing) or '-'),
    ('CONTRADICT', len(contradictions)),
    ('CONTRADICT_DETAIL', ';'.join(contradictions) or '-'),
    ('ESCALATING_SITES', esc_total),
    ('ESCALATING_IDS', len(esc)),
    ('BODY_LINES', len(body)),
    ('BODY_HAS_POSTURE_BRANCH',
     int(all(p in body_txt for p in POSTURES))),
    ('BODY_HAS_ISSUES_INCREMENT', int('ISSUES=$((ISSUES + 1))' in body_txt)),
    ('BODY_HAS_MODE_KEYWORD', int('case ' in body_txt)),
    ('BODY_GATE_ID', len(body_gate)),
    ('BODY_GATE_DETAIL', ','.join(sorted(set(body_gate))) or '-'),
    ('CALLSITE_GATE_ID', len(callsite_gate)),
    ('POSTURE_ID_NON_GATING',
     len([a for a in adv if a['posture'] == 'id-non-gating'])),
    ('POSTURE_ARM_NON_GATING',
     len([a for a in adv if a['posture'] == 'arm-non-gating'])),
]
for k, v in out:
    print('%s\t%s' % (k, v))
PYEOF

field() { /usr/bin/awk -F'\t' -v k="$1" '$1==k{print $2}' <<<"$2"; }

BASE="$(/usr/bin/python3 "$CENSUS_PY" "$DEPLOY_SH")"
if [[ -z "$BASE" ]]; then
  fail "AE-0 census engine produced no output over $DEPLOY_SH — every arm below is unusable"
  echo "Result: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
  exit 1
fi

N_SITES=$(field SITES "$BASE")
N_FAM=$(field FAMILIES "$BASE")
N_MISS=$(field MISSING "$BASE")
L_MISS=$(field MISSING_LINES "$BASE")
N_CONTRA=$(field CONTRADICT "$BASE")
D_CONTRA=$(field CONTRADICT_DETAIL "$BASE")
N_ESC=$(field ESCALATING_SITES "$BASE")
N_ESCID=$(field ESCALATING_IDS "$BASE")
N_BODY=$(field BODY_LINES "$BASE")
B_BRANCH=$(field BODY_HAS_POSTURE_BRANCH "$BASE")
B_ISSUES=$(field BODY_HAS_ISSUES_INCREMENT "$BASE")
B_MODEKW=$(field BODY_HAS_MODE_KEYWORD "$BASE")
N_BGATE=$(field BODY_GATE_ID "$BASE")
D_BGATE=$(field BODY_GATE_DETAIL "$BASE")
N_CGATE=$(field CALLSITE_GATE_ID "$BASE")
N_PID=$(field POSTURE_ID_NON_GATING "$BASE")
N_PARM=$(field POSTURE_ARM_NON_GATING "$BASE")

# ── AE-A — extraction non-vacuity (PV-3) ────────────────────────────────────
# Every arm below reads either the extracted body or the extracted call-site
# population. A silently-empty extraction would make all of them pass on nothing.
if [[ "${N_BODY:-0}" -gt 0 && "${B_BRANCH:-0}" -eq 1 && "${N_SITES:-0}" -gt 0 ]]; then
  pass "AE-A body extracted ($N_BODY lines) and carries both posture branches; call-site population non-empty ($N_SITES sites / $N_FAM check-id families)"
  note "structural facts (reported, asserted by test_check56_m2_advisory.sh Arm A): ISSUES increment in body=$B_ISSUES · mode-keyword in body=$B_MODEKW"
  note "declared posture split: id-non-gating $N_PID · arm-non-gating $N_PARM"
else
  fail "AE-A extraction vacuous — body lines=${N_BODY:-0} (want >0), both posture branches present=${B_BRANCH:-0} (want 1), call sites=${N_SITES:-0} (want >0). Every arm below is UNUSABLE, not clean"
fi

# ── AE-B — SUBJECT: every call site supplies a posture token ────────────────
if [[ "${N_MISS:-1}" -eq 0 ]]; then
  pass "AE-B 0 of $N_SITES flag_advisory_only call sites omit the posture token (denominator reported, not pinned)"
else
  fail "AE-B $N_MISS of $N_SITES call site(s) supply no closed-set posture token as their final argument — deploy.sh line(s): $L_MISS. Add \"id-non-gating\" or \"arm-non-gating\"; the emitter cannot raise on this itself without acquiring an escalation path"
fi

# ── AE-C — SUBJECT: declared posture vs measured escalation surface ─────────
# id-non-gating claims NO emit under that check_id can gate, so the id must
# carry zero escalating emits. arm-non-gating claims siblings CAN, so it must
# carry at least one. Both directions are graded.
if [[ "${N_CONTRA:-1}" -eq 0 ]]; then
  pass "AE-C 0 of $N_SITES declared postures contradict the measured escalation surface of their own check_id"
else
  fail "AE-C $N_CONTRA declared posture(s) contradict measured behaviour: $D_CONTRA"
fi

# ── AE-D — SENSITIVITY: AE-C can see a wrong posture ────────────────────────
# Without a non-zero here, AE-C's zero is a BROKEN PROBE. The mutation is
# applied to a COPY; the tree under test is never written.
MUT_C="$TMPD/deploy_flip.sh"
/usr/bin/python3 - "$DEPLOY_SH" "$MUT_C" <<'PYEOF'
import re
import sys
lines = open(sys.argv[1], encoding='utf-8').read().split('\n')
done = False
for i, l in enumerate(lines):
    if not done and l.rstrip().endswith('"arm-non-gating"'):
        lines[i] = l.rstrip()[:-len('"arm-non-gating"')] + '"id-non-gating"'
        done = True
open(sys.argv[2], 'w', encoding='utf-8').write('\n'.join(lines))
print('MUTATED' if done else 'NOT-MUTATED')
PYEOF
MUT_C_OUT="$(/usr/bin/python3 "$CENSUS_PY" "$MUT_C")"
D_CONTRA_N=$(field CONTRADICT "$MUT_C_OUT")
if [[ "$N_PARM" -eq 0 ]]; then
  fail "AE-D SENSITIVITY CONTROL VACUOUS — the corpus declares 0 arm-non-gating sites, so the mutation had nothing to flip. AE-C's zero is NOT reported clean"
elif [[ "${D_CONTRA_N:-0}" -ge 1 ]]; then
  pass "AE-D SENSITIVITY: flipping one arm-non-gating site to id-non-gating on a mutated copy makes AE-C report $D_CONTRA_N contradiction(s) — so AE-C's zero is a measurement, not a blind spot"
else
  fail "AE-D SENSITIVITY CONTROL FAILED — a deliberately mis-declared posture produced ${D_CONTRA_N:-0} contradictions (want >=1). AE-C is therefore UNUSABLE, not clean: a zero whose control arm also returns zero is a BROKEN PROBE"
fi

# ── AE-E — SENSITIVITY: AE-B can see a dropped argument ─────────────────────
MUT_B="$TMPD/deploy_drop.sh"
/usr/bin/python3 - "$DEPLOY_SH" "$MUT_B" <<'PYEOF'
import re
import sys
lines = open(sys.argv[1], encoding='utf-8').read().split('\n')
done = False
for i, l in enumerate(lines):
    if done:
        break
    for tok in ('"id-non-gating"', '"arm-non-gating"'):
        if l.rstrip().endswith(' ' + tok):
            lines[i] = l.rstrip()[:-(len(tok) + 1)]
            done = True
            break
open(sys.argv[2], 'w', encoding='utf-8').write('\n'.join(lines))
print('MUTATED' if done else 'NOT-MUTATED')
PYEOF
MUT_B_OUT="$(/usr/bin/python3 "$CENSUS_PY" "$MUT_B")"
D_MISS_N=$(field MISSING "$MUT_B_OUT")
if [[ "${D_MISS_N:-0}" -ge 1 ]]; then
  pass "AE-E SENSITIVITY: dropping one site's posture argument on a mutated copy makes AE-B report $D_MISS_N missing token(s) — so AE-B's zero is a measurement"
else
  fail "AE-E SENSITIVITY CONTROL FAILED — a deliberately dropped argument produced ${D_MISS_N:-0} missing tokens (want >=1). AE-B is therefore UNUSABLE, not clean"
fi

# ── AE-F — SPECIFICITY: AE-C's zero is reached over a populated corpus ──────
# AE-C asserts a zero. That zero means nothing unless the escalation census it
# is computed against actually found something to compare against. The count is
# REPORTED; only its non-emptiness is asserted, for the reason in the header.
if [[ "${N_ESC:-0}" -gt 0 && "${N_ESCID:-0}" -gt 0 && "${N_PARM:-0}" -gt 0 ]]; then
  pass "AE-F SPECIFICITY: the escalation census is populated — $N_ESC escalating call site(s) across $N_ESCID check-id(s), and $N_PARM advisory site(s) measure as arm-non-gating — so AE-C's zero is reached over a corpus that discriminates, not an empty one"
else
  fail "AE-F SPECIFICITY CONTROL FAILED — escalating sites=${N_ESC:-0}, escalating ids=${N_ESCID:-0}, arm-non-gating sites=${N_PARM:-0}; each must be >0. AE-C's zero cannot be distinguished from a census that measured nothing"
fi

# ── AE-G — SUBJECT: no gate identifier survives in shared code ──────────────
# The defect this harness's card removed was a gate identifier belonging to ONE
# check, appended by shared code to EVERY caller's line. The property asserted
# is structural: the emitter has no authority parameter and no authority
# literal. Its sensitivity arm is the same pattern over caller-owned call-site
# text, where an authority IS written and IS correct.
if [[ "${N_CGATE:-0}" -lt 1 ]]; then
  fail "AE-G BROKEN PROBE — the gate-identifier pattern found 0 hits on its sensitivity arm (caller-owned call-site text, $N_SITES sites). A zero whose control arm also returns zero is not a clean result"
elif [[ "${N_BGATE:-1}" -eq 0 ]]; then
  pass "AE-G 0 gate identifiers in the emitter body; sensitivity arm returns $N_CGATE hit(s) over caller-owned call-site text — the authority lives with the caller that owns it"
else
  fail "AE-G the emitter body carries $N_BGATE gate identifier(s) ($D_BGATE) — a per-caller fact in shared code cannot be correct for more than one caller. Move it into the caller's own detail string"
fi

echo "─────────────────────────────────────────────────────────────────────────"
echo "test_advisory_emitter_contract: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
[[ "$FAIL_COUNT" -eq 0 ]] || exit 1

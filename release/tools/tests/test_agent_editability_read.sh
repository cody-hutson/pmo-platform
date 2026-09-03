#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# test_agent_editability_read.sh — the Stage-4 Phase A3.5 Agent-Editability
# Read, graded mechanically instead of by inspection.
#
# WHY THIS SUITE EXISTS. The planning dimension it grades shipped as a prose
# procedure with two demonstrations owed and neither delivered:
#
#   (1) a fixture milestone carrying ONE FLOORED and ONE UNFLOORED card, with
#       both classifications correct — the discrimination claim; and
#   (2) a fixture asserting the planning output NEVER recommends setting the
#       hook-bypass environment variable — the safety claim.
#
# Both were derivable from data already in the tree, and both were graded by
# reading rather than by running, which is the state in which a property holds
# now and regresses silently later. This suite converts them to assertions.
#
# THE CLASSIFIER IS DERIVED, NEVER RESTATED. Every arm below reads the Tier-0
# union out of core/hooks/block-autonomy-ceiling.sh at run time and reads the
# path-class → execution-path map out of the planning spec's own table. This
# suite states no governance path of its own; a restated list here would be the
# second source of truth the spec exists to forbid, and the AUTHORITY-MUTATION
# arms below fail loudly if a restatement ever creeps in — they change the
# authority and require the verdicts to move with it.
#
# EVERY ARM HAS AN OBSERVED FAILING STATE. Positive arms are paired with
# mutation arms that assert the negative: a classifier that floors everything,
# a classifier that floors nothing, an authority with an entry removed, an
# authority with an entry added, and a spec whose execution-path column names
# the bypass. Each mutation is verified to DIFFER from its source before it is
# graded, so a silent no-op mutation is caught as a broken control rather than
# counted as a pass.
#
# Hermetic: one mktemp tree, no network, no writes outside it, no reads of any
# operator-instance path. Gates on exit code.
# ---------------------------------------------------------------------------
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT" || { echo "FATAL: cannot resolve repository root"; exit 1; }

PASS=0
FAIL=0

ok()   { printf '  ok   — %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  FAIL — %s\n' "$1"; FAIL=$((FAIL+1)); }
grade() { if [ "$1" = "0" ]; then ok "$2"; else bad "$2"; fi; }
group() { printf '\n(%s) %s\n' "$1" "$2"; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-editability-read.XXXXXX")" || exit 1
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# --- the graded surfaces -----------------------------------------------------
AUTHORITY='core/hooks/block-autonomy-ceiling.sh'
SPEC='release/references/pipeline/stage-04-planning.md'
BRIDGE='release/references/how-to/hub-spoke-bridge.md'
PLANNER_SKILL='release/skills/release-planner/SKILL.md'
PLAN_TEMPLATE='release/skills/release-planner/references/release-plan-template.md'

# The four surfaces the safety claim is asserted over. Kept in one place so an
# arm cannot silently grade three of four.
DELIVERABLES=("$SPEC" "$BRIDGE" "$PLANNER_SKILL" "$PLAN_TEMPLATE")

for f in "$AUTHORITY" "$SPEC" "$BRIDGE" "$PLANNER_SKILL" "$PLAN_TEMPLATE"; do
  [ -f "$f" ] || { echo "FATAL: graded surface missing: $f"; exit 1; }
done

# ---------------------------------------------------------------------------
# The engine. python3 because the load-bearing detectors must not be a shim's
# plausible zero. Reads two authorities and answers three questions:
#   derive   — print the derived Tier-0 basename union, one per line
#   classify — print the path class for one write-set path
#   execmap  — print "<class>\t<execution path>" for each row of the spec table
# Both authorities are passed in as paths, so a mutation arm points it at a
# mutated COPY and nothing else changes.
# ---------------------------------------------------------------------------
cat > "$TMP/engine.py" <<'PYEOF'
import re
import sys


def tier0_union(authority_path):
    """Derive the Tier-0 basename union from the hook, per the spec's step 1.

    Read every `case` block whose body invokes always_block "BLOCK-AUTONOMY-001",
    collect its glob arms, project each into repo-relative form by discarding the
    checkout anchor, and reduce to the basenames a repository path can carry.
    Nothing here is a stated list: remove an arm from the hook and the union
    shrinks; add one and it grows.
    """
    text = open(authority_path, encoding='utf-8').read()
    lines = text.split('\n')
    union = set()
    blocks = 0
    i = 0
    while i < len(lines):
        if re.match(r'^\s*case\s+"\$ABS_TARGET"\s+in\s*$', lines[i]):
            depth_start = i
            j = i + 1
            body = []
            while j < len(lines) and not re.match(r'^\s*esac\s*$', lines[j]):
                body.append(lines[j])
                j += 1
            block = '\n'.join(body)
            if 'always_block "BLOCK-AUTONOMY-001"' in block:
                blocks += 1
                # Arms are the glob alternatives that precede the `)` opening a
                # branch. Collect every quoted or bare fragment on those lines.
                for line in body:
                    if ')' not in line:
                        continue
                    head = line.split(')')[0]
                    if 'always_block' in head or ';;' in head:
                        continue
                    for arm in head.split('|'):
                        arm = arm.strip().strip('\\').strip()
                        if not arm:
                            continue
                        # Reassemble "a"*"b" style concatenations, drop quotes.
                        arm = arm.replace('"', '')
                        if not arm or arm.startswith('#'):
                            continue
                        base = arm.rstrip('/').split('/')[-1]
                        # A trailing-glob arm names a directory subtree, not a
                        # file basename; it contributes no basename to the union.
                        if base in ('', '*') or '$' in base:
                            continue
                        if base.endswith('.md') or base.endswith('.json'):
                            union.add(base)
            i = j
        i += 1
    return blocks, sorted(union)


def classify(authority_path, path):
    """tier-0-floored when the path's basename is in the derived union."""
    _, union = tier0_union(authority_path)
    return 'tier-0-floored' if path.split('/')[-1] in union else 'unconstrained'


def execmap(spec_path):
    """Read the path-class -> execution-path map out of the spec's own table."""
    text = open(spec_path, encoding='utf-8').read()
    rows = {}
    pattern = re.compile(
        r'^\|\s*`(tier-0-floored|sanctioned-session-required|unconstrained)`\s*\|'
        r'([^|]*)\|([^|]*)\|\s*$', re.M)
    for m in pattern.finditer(text):
        rows[m.group(1)] = m.group(3).strip()
    return rows


def main():
    op = sys.argv[1]
    if op == 'derive':
        blocks, union = tier0_union(sys.argv[2])
        print(blocks)
        for b in union:
            print(b)
    elif op == 'classify':
        print(classify(sys.argv[2], sys.argv[3]))
    elif op == 'execmap':
        for k, v in sorted(execmap(sys.argv[2]).items()):
            print(f'{k}\t{v}')
    else:
        sys.exit(2)


main()
PYEOF

PY() { python3 "$TMP/engine.py" "$@"; }

# The bypass token, assembled nowhere and spelled once. Every arm that counts it
# reads THIS literal, so a rename of the variable cannot leave an arm grading a
# string that no longer exists.
BYPASS_TOKEN='CLAUDE_HOOK_BYPASS'

count_token() {
  # $1 = file, $2 = literal needle. python3, not grep: a shim that rejects the
  # pattern returns a plausible zero, and every zero here is load-bearing.
  python3 - "$1" "$2" <<'PYEOF'
import sys
print(open(sys.argv[1], encoding='utf-8').read().count(sys.argv[2]))
PYEOF
}

printf 'test_agent_editability_read.sh — Stage-4 Phase A3.5 fixture\n'
printf 'repo: %s\n' "$REPO_ROOT"

# ===========================================================================
group D "Derivation — the Tier-0 union is read out of the hook, not restated"
# ===========================================================================

DERIVE_OUT="$(PY derive "$AUTHORITY")"
BLOCK_COUNT="$(head -1 <<<"$DERIVE_OUT")"
UNION="$(printf '%s\n' "$DERIVE_OUT" | tail -n +2)"
UNION_N="$(printf '%s\n' "$UNION" | grep -c . || true)"

if [ "${BLOCK_COUNT:-0}" -ge 1 ]; then
  ok "D1 — the authority yields $BLOCK_COUNT case block(s) invoking always_block BLOCK-AUTONOMY-001"
else
  bad "D1 — BROKEN PROBE: no BLOCK-AUTONOMY-001 case block parsed out of $AUTHORITY"
fi

if [ "${UNION_N:-0}" -ge 1 ]; then
  ok "D2 — derived Tier-0 basename union is non-empty ($UNION_N): $(printf '%s' "$UNION" | tr '\n' ' ')"
else
  bad "D2 — BROKEN PROBE: derived union is empty, so every classification below would be vacuous"
fi

# Denominator control: the floored class must be non-empty IN THE REPOSITORY,
# or an all-unconstrained classifier passes the unfloored arm for free.
TRACKED_FLOORED=0
while IFS= read -r base; do
  [ -n "$base" ] || continue
  n="$(git ls-files | awk -F/ -v b="$base" '$NF==b' | grep -c . || true)"
  TRACKED_FLOORED=$((TRACKED_FLOORED + n))
done <<< "$UNION"
if [ "$TRACKED_FLOORED" -ge 1 ]; then
  ok "D3 denominator control — $TRACKED_FLOORED tracked file(s) carry a derived Tier-0 basename; the floored class is non-empty"
else
  bad "D3 denominator control — BROKEN PROBE: no tracked file matches the derived union"
fi

# Specificity: a bogus basename is not admitted.
if grep -qx 'ZZOPERATIONS.md' <<<"$UNION"; then
  bad "D4 specificity — the derived union admits the bogus basename ZZOPERATIONS.md"
else
  ok "D4 specificity — the derived union rejects the bogus basename ZZOPERATIONS.md"
fi

# ===========================================================================
group F "Fixture milestone — one floored card, one unfloored card"
# ===========================================================================
#
# The fixture is two synthetic cards over REAL TRACKED PATHS. A path-level
# fixture is strictly more durable than a card-level one: a card-level arm is
# vacated the moment that card is reclassified, which is exactly how the
# demonstration came to be owed in the first place.

CARD_FLOORED_PATH='core/governance/OPERATIONS.md'
CARD_UNFLOORED_PATH='release/references/pipeline/stage-04-planning.md'

for p in "$CARD_FLOORED_PATH" "$CARD_UNFLOORED_PATH"; do
  if git ls-files --error-unmatch "$p" >/dev/null 2>&1; then
    ok "F0 — fixture write-set path is tracked, so the fixture grades real repository state: $p"
  else
    bad "F0 — BROKEN FIXTURE: $p is not tracked; the fixture would grade a path that cannot occur"
  fi
done

CLS_F="$(PY classify "$AUTHORITY" "$CARD_FLOORED_PATH")"
CLS_U="$(PY classify "$AUTHORITY" "$CARD_UNFLOORED_PATH")"

[ "$CLS_F" = 'tier-0-floored' ]; grade $? "F1 — the floored card classifies tier-0-floored (observed: $CLS_F)"
[ "$CLS_U" = 'unconstrained' ]; grade $? "F2 — the unfloored card classifies unconstrained (observed: $CLS_U)"

# The discrimination claim. F1 and F2 together are the criterion: a classifier
# that floors everything fails F2, one that floors nothing fails F1. Asserted
# rather than left to be inferred from the two arms sitting near each other.
if [ "$CLS_F" != "$CLS_U" ]; then
  ok "F3 discrimination — the two fixture cards receive DIFFERENT classes ($CLS_F vs $CLS_U); the read discriminates rather than labelling everything"
else
  bad "F3 discrimination — both fixture cards received $CLS_F; the classifier is not discriminating"
fi

# ===========================================================================
group F-NEG "Authority mutation — the classifier tracks the authority it reads"
# ===========================================================================
#
# The mutation-test limb: change the AUTHORITY, and the classification must move
# with no edit to the classifier. Both directions, because a one-directional
# arm cannot tell a live read from a hardcoded 'OPERATIONS.md'.

# (a) REMOVE the floored card's basename from the authority -> it must stop
#     being floored.
python3 - "$AUTHORITY" "$TMP/authority-removed.sh" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding='utf-8').read()
out = t.replace('OPERATIONS.md', 'ZZREMOVED.md')
open(dst, 'w', encoding='utf-8').write(out)
PYEOF
if cmp -s "$AUTHORITY" "$TMP/authority-removed.sh"; then
  bad "F-NEG-a control — BROKEN MUTATION: the removed-arm copy is byte-identical to the authority, so the arm below grades nothing"
else
  ok "F-NEG-a control — the removed-arm copy DIFFERS from the authority"
  CLS_FA="$(PY classify "$TMP/authority-removed.sh" "$CARD_FLOORED_PATH")"
  if [ "$CLS_FA" != 'tier-0-floored' ]; then
    ok "F-NEG-a — with the arm removed from the authority the floored card falls to $CLS_FA; the union is READ, not restated"
  else
    bad "F-NEG-a — the card still classifies tier-0-floored against an authority that no longer names it; the set is restated somewhere"
  fi
fi

# (b) ADD the unfloored card's basename to the authority -> it must become
#     floored. This is the criterion's own wording: adding a path to the
#     authority changes the behaviour with no edit to the check.
python3 - "$AUTHORITY" "$TMP/authority-added.sh" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding='utf-8').read()
needle = '        */CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md)'
assert t.count(needle) == 1, f'BROKEN MUTATION ANCHOR: matched {t.count(needle)} times, want 1'
out = t.replace(needle, '        */CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md|*/stage-04-planning.md)')
open(dst, 'w', encoding='utf-8').write(out)
PYEOF
if [ $? -ne 0 ] || cmp -s "$AUTHORITY" "$TMP/authority-added.sh"; then
  bad "F-NEG-b control — BROKEN MUTATION: the added-arm copy is byte-identical to the authority (or the anchor did not resolve)"
else
  ok "F-NEG-b control — the added-arm copy DIFFERS from the authority"
  CLS_UA="$(PY classify "$TMP/authority-added.sh" "$CARD_UNFLOORED_PATH")"
  if [ "$CLS_UA" = 'tier-0-floored' ]; then
    ok "F-NEG-b — adding a path to the AUTHORITY floors the formerly-unfloored card, with no edit to the classifier"
  else
    bad "F-NEG-b — the classifier ignored a path added to the authority (observed: $CLS_UA); the derivation is not live"
  fi
fi

# ===========================================================================
group X "Execution path — a floored card is operator-executed, never a bypass"
# ===========================================================================

EXECMAP="$(PY execmap "$SPEC")"
MAP_ROWS="$(printf '%s\n' "$EXECMAP" | grep -c . || true)"

if [ "${MAP_ROWS:-0}" -eq 3 ]; then
  ok "X0 — the spec's path-class table yields exactly 3 rows"
else
  bad "X0 — BROKEN PROBE: the spec's path-class table yielded $MAP_ROWS row(s), want 3"
fi

FLOORED_EXEC="$(printf '%s\n' "$EXECMAP" | awk -F'\t' '$1=="tier-0-floored"{print $2}')"
case "$FLOORED_EXEC" in
  *operator-executed*) ok "X1 — the floored class maps to an operator-execution path (observed: $FLOORED_EXEC)" ;;
  *) bad "X1 — the floored class does not map to an operator-execution path (observed: $FLOORED_EXEC)" ;;
esac

# The safety claim, on the execution-path column specifically: no class may
# recommend the bypass.
BYPASS_IN_MAP="$(printf '%s\n' "$EXECMAP" | grep -c "$BYPASS_TOKEN" || true)"
# The row-count precondition is part of the assertion, not a separate arm: a
# zero over an EMPTY map is the vacuous pass this release exists to eliminate.
if [ "${MAP_ROWS:-0}" -lt 1 ]; then
  bad "X2 — BROKEN PROBE: the map is empty, so a zero here would be vacuous"
elif [ "${BYPASS_IN_MAP:-0}" -eq 0 ]; then
  ok "X2 — no path class names $BYPASS_TOKEN as its execution path (0 of $MAP_ROWS rows)"
else
  bad "X2 — $BYPASS_IN_MAP path class(es) name $BYPASS_TOKEN as an execution path"
fi

# X-NEG: a spec whose floored row recommends the bypass must FAIL X1 and X2.
python3 - "$SPEC" "$TMP/spec-bypass.md" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding='utf-8').read()
needle = '| `tier-0-floored` | matches the Tier-0 union from step 1 | `operator-executed` |'
assert t.count(needle) == 1, f'BROKEN MUTATION ANCHOR: matched {t.count(needle)} times, want 1'
out = t.replace(
    needle,
    '| `tier-0-floored` | matches the Tier-0 union from step 1 | `CLAUDE_HOOK_BYPASS=1` |')
open(dst, 'w', encoding='utf-8').write(out)
PYEOF
if [ $? -ne 0 ] || cmp -s "$SPEC" "$TMP/spec-bypass.md"; then
  bad "X-NEG control — BROKEN MUTATION: the bypass-recommending copy is byte-identical to the spec (or the anchor did not resolve)"
else
  ok "X-NEG control — the bypass-recommending copy DIFFERS from the spec"
  MUT_MAP="$(PY execmap "$TMP/spec-bypass.md")"
  MUT_FLOORED="$(printf '%s\n' "$MUT_MAP" | awk -F'\t' '$1=="tier-0-floored"{print $2}')"
  MUT_HITS="$(printf '%s\n' "$MUT_MAP" | grep -c "$BYPASS_TOKEN" || true)"
  case "$MUT_FLOORED" in
    *operator-executed*) bad "X-NEG — X1's assertion still passes against a spec that recommends the bypass; X1 cannot fail" ;;
    *) if [ "${MUT_HITS:-0}" -ge 1 ]; then
         ok "X-NEG — against a spec whose floored row recommends the bypass, X1 and X2 both fail ($MUT_HITS hit(s)); the arms can fail"
       else
         bad "X-NEG — the mutated spec was not detected by X2; the arm cannot fail"
       fi ;;
  esac
fi

# ===========================================================================
group B "Safety claim — the delivered surfaces never name the bypass"
# ===========================================================================

TOTAL_D=0
for f in "${DELIVERABLES[@]}"; do
  n="$(count_token "$f" "$BYPASS_TOKEN")"
  TOTAL_D=$((TOTAL_D + n))
  if [ "$n" -eq 0 ]; then
    ok "B — 0 occurrences of $BYPASS_TOKEN in $f"
  else
    bad "B — $n occurrence(s) of $BYPASS_TOKEN in $f"
  fi
done

# Sensitivity: the SAME instrument over the authority, which does carry the
# token, must return non-zero — so the four zeros above are real negatives and
# not the instrument declining to fire.
SENS="$(count_token "$AUTHORITY" "$BYPASS_TOKEN")"
if [ "$SENS" -ge 1 ]; then
  ok "B-SENS — the same instrument returns $SENS on $AUTHORITY; the four zeros are real negatives"
else
  bad "B-SENS — BROKEN PROBE: the instrument returned 0 on a file known to carry the token"
fi

# Specificity: a bogus needle returns 0 everywhere, so a non-zero above is the
# token and not the instrument matching anything.
SPEC_ARM="$(count_token "$AUTHORITY" 'ZZCLAUDE_HOOK_BYPASS')"
if [ "$SPEC_ARM" -eq 0 ]; then
  ok "B-SPEC — a bogus needle returns 0 on the same file the sensitivity arm fires on"
else
  bad "B-SPEC — the bogus needle returned $SPEC_ARM; the instrument matches too much"
fi

# B-NEG: inject the token into a copy of a graded surface and require the
# assertion to fail there.
python3 - "$SPEC" "$TMP/spec-injected.md" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src, encoding='utf-8').read()
out = t + '\n<!-- mutation fixture: CLAUDE_HOOK_BYPASS=1 -->\n'
open(dst, 'w', encoding='utf-8').write(out)
PYEOF
if cmp -s "$SPEC" "$TMP/spec-injected.md"; then
  bad "B-NEG control — BROKEN MUTATION: the injected copy is byte-identical to the spec"
else
  ok "B-NEG control — the injected copy DIFFERS from the spec"
  INJ="$(count_token "$TMP/spec-injected.md" "$BYPASS_TOKEN")"
  if [ "$INJ" -ge 1 ]; then
    ok "B-NEG — the assertion FAILS against a surface carrying the token ($INJ hit(s)); the B arms can fail"
  else
    bad "B-NEG — the injected token was not detected; the B arms cannot fail"
  fi
fi

# ===========================================================================
printf '\n-----------------------------------------------------------------\n'
printf 'AER-1: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0

#!/usr/bin/env bash
# test_advisory_emitter_contract.sh — static conformance assertions for the
# calling contracts of flag_advisory_only (arms AE-*) and flag_warn_or_issue
# (arms WE-*).
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
# THE WARN EMITTER'S GRADUATION TOKEN (arms WE-A to WE-L) — the same rule,
# applied to flag_warn_or_issue. Its third argument is a closed one-member set,
# committed-default: OPTIONAL at the call and REQUIRED WHERE OWED. It is owed on
# every governed findings arm — a call in the else-leg of an inline
# `if [[ "$v" == "enforce" ]]` whose then-leg increments ISSUES, where $v holds
# that check's own resolve_check_mode read — unless the check's flip-decision
# row in core/standards/gate-efficacy-standard.md declines the flip, or the
# census's NOT_OWED ledger names it with a reason. Two arms EXECUTE rather
# than read (WE-G, WE-H): the properties under test are the rendered line and
# the drain row, which a static read cannot show. Every WE sensitivity arm edits
# ONE line of a COPY, chosen by the census rather than by wording, so no arm
# pins a caller's text.
#
# DECLARED COVERAGE BOUNDARY for the WE arms — stated, not implied.
#   * A governed arm is recognised in ONE shape: the inline `== "enforce"` test
#     above. The shape is CLOSED, not assumed. Every dial must be read in the
#     house form v=$(resolve_check_mode "<id>" ["<default>"]), optionally after
#     `local v;`, and every non-comment reference to a dial variable must take
#     one of six shapes: the inline enforce test, `elif [[ "$v" == "warn" ]]`,
#     `if [[ "$v" != "off" ]]`, `[[ "$v" == "off" ]] && return`,
#     `case "$v" in`, or an interpolation in a one-string `log` line. Any other
#     dial read or dial test fails WE-K by line, so a variant spelling cannot
#     leave the owed population without a failure. A `case`-tested dial is read
#     and is not taken as governing an arm; when this was written no such dial
#     routed a warn leg through this emitter.
#   * Not closed, and named: a warn leg nested one block deeper inside the
#     else-leg, an ISSUES increment spelled another way, and an emitted id that
#     differs from its dial's id each take an arm out of the owed population
#     without a failure. None occurs in the tree this shipped on.
#   * The register is read by its own stated row contract: column 1 resolves
#     the check id by the standard's lookaround rule, column 3's leading token
#     is the disposition. It is read ONLY for a declined flip — a row leading
#     RATIFIED ADVISORY, or one leading SPLIT DISPOSITION whose column 3 names
#     a permanent advisory residual, the declined limb ADR-167 names — never for
#     whether a record states the committed default; that limb of the contract
#     is the caller's. A split row's limbs cannot be told apart by arm, so its
#     check owes the token on no governed arm and is not forbidden one. A moved
#     heading or a reshaped table reads as zero rows or zero exempt arms, and
#     WE-A fails on either.
#   * A dial default passed through a variable reads as not-"enforce": the
#     flip is the literal committed default, so the stale-token limb reads the
#     literal.
#   * Caller detail prose is graded on one point only: a check that carries
#     the token names no mode file in its own detail, because one line stating
#     two forms is the defect this contract removed. The rest of detail is
#     caller-owned, as for the advisory emitter.
#   * A token passed through a variable reads as absent; the token is a
#     literal.
#   * A NOT_OWED entry carries its reason AND the evidence that reason rests
#     on, as a pattern that must still match a comment line in that check's
#     own definition block. When the evidence goes, the entry fails WE-K, so
#     the token and the ledger move in the same change.
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

echo "Emitter calling contracts — deploy.sh flag_advisory_only and flag_warn_or_issue"
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


def logical(i, off=0):
    """Join a call site's physical lines across trailing-backslash continuations.

    Returns (joined_text, index_of_final_physical_line). The posture token is the
    final argument, so a site whose arguments wrap must be read to its last line
    or the token reads as absent on every wrapped caller.

    `off` slices the FIRST physical line so the joined text begins after the
    function name. See sites() for why that slice is load-bearing."""
    j = i
    parts = [lines[j][off:]]
    while lines[j].rstrip().endswith('\\') and j + 1 < len(lines):
        j += 1
        parts.append(lines[j])
    return ' '.join(p.rstrip().rstrip('\\').strip() for p in parts), j


def sites(fn):
    """Call sites of `fn`, as (line_index, offset_just_past_the_name).

    ANCHORED AT A COMMAND POSITION, NOT AT THE LINE START. A call is recognised
    at the start of an indented line OR immediately after a shell separator or
    terminator (`;` `;;` `&&` `||` `|` `(` `)` `{` `}`), so a call carrying a
    same-line prefix is seen. The previous anchor required the name to begin the
    line and was therefore SILENTLY blind to every prefixed caller — a `case`
    branch (`*)  flag_advisory_only ...`) and a `[[ ... ]] &&` guarded emit both
    read as absent, and an absent site cannot fail any arm below.

    A whole-line comment is excluded. These emitter names are discussed at
    length in deploy.sh's own prose, and a mention is not a call; without the
    exclusion the widened anchor reports prose as population.

    THE RETURNED OFFSET IS LOAD-BEARING, not a convenience. Argument extraction
    must begin AFTER the function name. A guarded emit such as
    `[[ -n "$c55_h1" ]] && flag_warn_or_issue "work-hierarchy-drift" ...` carries
    the GUARD's own quoted variable earlier on the line; extracting the first
    quoted token from the whole line yields `$c55_h1` instead of the check_id,
    which injects a bogus id into the escalation census that AE-C reads. Widening
    the anchor without also anchoring extraction trades one silent miss for
    several silent fabrications."""
    pat = re.compile(r'(?:^|[;&|(){}])[ \t]*' + re.escape(fn) + r'(?=\s)')
    out = []
    for i, l in enumerate(lines):
        if l.lstrip().startswith('#'):
            continue
        m = pat.search(l)
        if m:
            out.append((i, m.end()))
    return out


def first_quoted(text):
    m = re.search(r'"([^"]+)"', text)
    return m.group(1) if m else None


def trailing_token(text):
    """The final quoted argument of a call.

    A trailing shell terminator is tolerated. Now that sites() sees calls in a
    `case` branch, the final argument is followed by `;;` on those sites; without
    this the posture would read as ABSENT on every case-branch caller and AE-B
    would fail a site that in fact supplies its token — trading the silent miss
    this widening fixed for an equally wrong false positive."""
    m = re.search(r'"([^"]*)"\s*(?:;;?)?\s*$', text.rstrip())
    return m.group(1) if m else None


# ── the advisory population ────────────────────────────────────────────────
adv = []
for i, off in sites(ADVISORY):
    text, last = logical(i, off)
    adv.append({
        'line': i + 1,
        'off': off,
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
    for i, off in sites(fn):
        text, _ = logical(i, off)
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
    text, _ = logical(a['line'] - 1, a['off'])
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

# ══ The warn emitter's graduation token (arms WE-A to WE-L) ════════════════
# Same engine, same sites()/logical()/first_quoted(). argv[2], the gate-efficacy
# standard, is optional so the AE invocations above stay unchanged; every WE
# invocation passes it, and WE-A fails on a run that read no register rows.
WARN = 'flag_warn_or_issue'
TOKENS = ('committed-default',)
# Governed arms that owe NO token: the id, its reason, and the EVIDENCE that
# reason rests on, as a pattern that must still match a comment line in that
# check's own definition block. When the evidence goes the entry fails WE-K, so
# the token and the ledger move in the same change. A check whose own
# flip-decision row declines the flip is exempt by that row and is never listed
# here: the row is the record, and a second list would be a second home.
NOT_OWED = {
    'enum-parity': (
        'its own header names a mode-file flip and it has no flip-decision '
        'row, so no committed-form claim exists to render; it takes the token '
        'when its record states the committed default',
        r'enum-parity\.mode'),
}
# A per-caller fact as shared-code source text: a mode-file name, the shared
# dial's name, a flip verb, or a resolve call carrying a LITERAL check id.
PERCALLER = re.compile(r'\.mode\b|deploy-check|\bflip\b'
                       r'|resolve_check_mode\s+\\?"[a-z0-9]')
MODEFILE = re.compile(r'\.mode\b')
DIAL = re.compile(r'^\s*(?:local\s+\w+;\s*)?(\w+)="?\$\(resolve_check_mode\s+'
                  r'"([a-z0-9-]+)"(?:\s+"([^"]*)")?\)"?\s*$')
# A dial read in ANY spelling: the resolver called with a literal id. A read
# that DIAL does not parse is a shape the census cannot follow, so it is a
# finding rather than an absence.
DIAL_READ = re.compile(r'resolve_check_mode\s+"[a-z0-9-]+"')
IF_ENFORCE = re.compile(r'^\s*(?:el)?if \[\[ "\$(\w+)" == "enforce" \]\]')
BARE3 = re.compile(r'\$3(?![0-9])|\$\{3\}')
# The check-definition header, exactly as the roster extractor reads it
# (core/deploy/tools/check-extraction-contract.py, DEFBLOCK_RE).
DEFBLOCK = re.compile(r'^\s*#\s*(?:─── )?Check (\d+)\s*(?:—|:)')
# The declined limb of a SPLIT DISPOSITION row, by the phrase the in-tree row
# uses for it.
RESIDUAL = re.compile(r'(?i)\bpermanent[- ](?:advisory[- ])?residual\b')
std_lines = (open(sys.argv[2], encoding='utf-8').read().split('\n')
             if len(sys.argv) > 2 else [])


def _dq_end(t, k):
    i, n = k + 1, len(t)
    while i < n:
        c = t[i]
        if c == '\\':
            i += 2
            continue
        if c == '$' and i + 1 < n and t[i + 1] == '(':
            i = _paren_end(t, i + 1) + 1
            continue
        if c == '"':
            return i
        i += 1
    return n - 1


def _paren_end(t, k):
    d, i, n = 0, k, len(t)
    while i < n:
        c = t[i]
        if c == '\\':
            i += 2
            continue
        if c == "'":
            j = t.find("'", i + 1)
            i = n if j < 0 else j + 1
            continue
        if c == '"':
            i = _dq_end(t, i) + 1
            continue
        if c == '(':
            d += 1
        elif c == ')':
            d -= 1
            if d == 0:
                return i
        i += 1
    return n - 1


def words(text):
    """The shell words of one call's argument text: quote-, escape- and
    substitution-aware, ending at an unquoted command terminator."""
    out, cur, has, i, n = [], '', False, 0, len(text)
    while i < n:
        c = text[i]
        if c == '\\' and i + 1 < n:
            cur += text[i:i + 2]; has = True; i += 2; continue
        if c == "'":
            j = text.find("'", i + 1)
            j = n - 1 if j < 0 else j
            cur += text[i:j + 1]; has = True; i = j + 1; continue
        if c == '"':
            j = _dq_end(text, i)
            cur += text[i:j + 1]; has = True; i = j + 1; continue
        if c == '$' and i + 1 < n and text[i + 1] == '(':
            j = _paren_end(text, i + 1)
            cur += text[i:j + 1]; has = True; i = j + 1; continue
        if c in ' \t':
            if has:
                out.append(cur); cur = ''; has = False
            i += 1
            continue
        if c in ';&|)' or (c == '#' and not has):
            break
        cur += c; has = True; i += 1
    if has:
        out.append(cur)
    return out


def strip_comment(l):
    """The code part of one line: an unquoted `#` that starts a word opens a
    trailing comment, and a mention inside it is not a reference."""
    i, n = 0, len(l)
    while i < n:
        c = l[i]
        if c == '\\':
            i += 2
            continue
        if c == "'":
            j = l.find("'", i + 1)
            i = n if j < 0 else j + 1
            continue
        if c == '"':
            i = _dq_end(l, i) + 1
            continue
        if c == '$' and i + 1 < n and l[i + 1] == '(':
            i = _paren_end(l, i + 1) + 1
            continue
        if c == '#' and (i == 0 or l[i - 1] in ' \t'):
            return l[:i]
        i += 1
    return l


def literal_token(word):
    if len(word) >= 2 and word[0] == '"' and word[-1] == '"' \
            and not re.search(r'[$\\`]', word[1:-1]):
        return word[1:-1]
    return None


def ind(l):
    return len(l) - len(l.lstrip(' '))


def governed(i, cid):
    """(dial_line, dial_default, if_line) when the call at index i sits in the
    else-leg of an inline `if [[ "$v" == "enforce" ]]` whose then-leg
    increments ISSUES and whose $v is cid's own resolve_check_mode read."""
    ci = ind(lines[i])
    j = i - 1
    while j >= 0 and (not lines[j].strip() or lines[j].lstrip().startswith('#')
                      or ind(lines[j]) >= ci):
        j -= 1
    if j < 0 or lines[j].strip() != 'else':
        return None
    ei, k = ind(lines[j]), j - 1
    while k >= 0:
        l = lines[k]
        if not l.strip() or l.lstrip().startswith('#') or ind(l) > ei:
            k -= 1
            continue
        if ind(l) < ei:
            return None
        m = IF_ENFORCE.match(l)
        if not m:
            if l.lstrip().startswith(('if ', 'elif ')):
                return None
            k -= 1
            continue
        if 'ISSUES=$((ISSUES + 1))' not in '\n'.join(lines[k:j]):
            return None
        for d in range(k - 1, -1, -1):
            if lines[d].lstrip().startswith('#'):
                continue
            dm = DIAL.match(lines[d])
            if dm and dm.group(1) == m.group(1):
                return (d + 1, dm.group(3), k + 1) if dm.group(2) == cid else None
        return None
    return None


def vocab_ok(code, v):
    """True when one reference to dial variable v takes a shape the census
    reads: the inline enforce test (the ONLY shape that governs an arm), the
    warn elif, the not-off guard, the off early-return, a case dispatch, or an
    interpolation inside a one-string log line."""
    ref = r'"\$(?:%s|\{%s\})"' % (re.escape(v), re.escape(v))
    s = code.strip()
    for p in (r'(?:el)?if \[\[ ' + ref + r' == "enforce" \]\](?:; then)?',
              r'elif \[\[ ' + ref + r' == "warn" \]\](?:; then)?',
              r'if \[\[ ' + ref + r' != "off" \]\](?:; then)?',
              r'\[\[ ' + ref + r' == "off" \]\] && return(?: [0-9]+)?',
              r'case ' + ref + r' in'):
        if re.fullmatch(p, s):
            return True
    return s.startswith('log "') and _dq_end(s, 4) == len(s) - 1


def register_rows():
    """(line, column-1, column-3) for each row of § Flip-decision status."""
    rows, on = [], False
    for n, l in enumerate(std_lines, 1):
        if l.startswith('## Flip-decision status'):
            on = True
            continue
        if on and l.startswith('## '):
            break
        if on and l.startswith('| ') and not l.startswith('| Gate |'):
            cells = l.split(' | ')
            if len(cells) >= 3:
                rows.append((n, cells[0], cells[2]))
    return rows


ROWS = register_rows()


def _row_of(cid):
    """cid's rows, column 1 resolved by the standard's own lookaround rule,
    never a word boundary."""
    pat = re.compile(r'(?<![\w`-])`?' + re.escape(cid) + r'`?(?![\w-])')
    return [(n, c3.lstrip('* '), c3) for n, c1, c3 in ROWS if pat.search(c1)]


def ratified_row(cid):
    """The line of cid's row when its column 3 leads RATIFIED ADVISORY: the
    whole flip is declined, so a graduation token there is false (WE-E)."""
    return next((n for n, lead, _ in _row_of(cid)
                 if lead.startswith('RATIFIED ADVISORY')), 0)


def declined_row(cid):
    """The line of cid's row when its flip is declined: RATIFIED ADVISORY, or a
    SPLIT DISPOSITION whose column 3 names a permanent advisory residual. Read
    for EXEMPTION only — a split row's limbs cannot be told apart by arm, so
    it forbids no token."""
    return next((n for n, lead, c3 in _row_of(cid)
                 if lead.startswith('RATIFIED ADVISORY')
                 or (lead.startswith('SPLIT DISPOSITION') and RESIDUAL.search(c3))), 0)


w_calls = []
for i, off in sites(WARN):
    text, last = logical(i, off)
    w = words(text)
    cid = first_quoted(text)
    w_calls.append({'line': i + 1, 'id': cid, 'arity': len(w), 'text': text,
                    'single': last == i,
                    'tok': literal_token(w[2]) if len(w) == 3 else None,
                    'gov': governed(i, cid)})

w_arity_bad = [c for c in w_calls if c['arity'] not in (2, 3)
               or (c['arity'] == 3 and c['tok'] not in TOKENS)]
w_tok = [c for c in w_calls if c['tok'] in TOKENS]
w_tok_ids = {c['id'] for c in w_tok}
w_contra = []
for c in w_tok:
    if not c['gov']:
        w_contra.append('%d:%s:not-a-governed-findings-arm' % (c['line'], c['id']))
        continue
    if c['gov'][1] == 'enforce':
        w_contra.append('%d:%s:dial-already-defaults-enforce' % (c['line'], c['id']))
    if ratified_row(c['id']):
        w_contra.append('%d:%s:flip-declined-by-its-row' % (c['line'], c['id']))
for c in w_calls:
    if c['id'] in w_tok_ids and MODEFILE.search(c['text']):
        w_contra.append('%d:%s:mode-file-beside-a-committed-claim' % (c['line'], c['id']))
w_gov = [c for c in w_calls if c['gov']]
w_ratified = [c for c in w_gov if ratified_row(c['id'])]
w_exempt = [c for c in w_gov if declined_row(c['id'])]
w_owed = [c for c in w_gov if c['gov'][1] != 'enforce'
          and not declined_row(c['id']) and c['id'] not in NOT_OWED]
w_missing = [c for c in w_owed if c['tok'] not in TOKENS]
w_ledger_stale = sorted({c['id'] for c in w_tok if c['id'] in NOT_OWED})
w_ledger_unused = sorted(k for k in NOT_OWED if not any(c['id'] == k for c in w_gov))

# ── the closed dial vocabulary (WE-K) ──
# Every dial read must parse as DIAL; every non-comment reference to a dial
# variable must pass vocab_ok(). Whole file: a test written inside a helper
# defined above its dial is still a test of that dial.
w_dials, w_dial_bad = {}, []
for n, l in enumerate(lines, 1):
    if l.lstrip().startswith('#') or 'resolve_check_mode' not in l:
        continue
    m = DIAL.match(l)
    if m:
        w_dials[n] = m.group(1)
    elif DIAL_READ.search(strip_comment(l)):
        w_dial_bad.append('%d:dial-read-outside-the-house-form' % n)
w_dial_refs = 0
if w_dials:
    any_ref = re.compile(r'\$\{?(%s)(?![A-Za-z0-9_])'
                         % '|'.join(re.escape(v) for v in sorted(set(w_dials.values()))))
    for n, l in enumerate(lines, 1):
        if n in w_dials or l.lstrip().startswith('#') or not any_ref.search(l):
            continue
        code = strip_comment(l)
        for v in sorted({m.group(1) for m in any_ref.finditer(code)}):
            w_dial_refs += 1
            if not vocab_ok(code, v):
                w_dial_bad.append('%d:%s:unrecognized-dial-test-shape' % (n, v))

# ── the ledger's evidence (WE-K) ──
def_heads = [n for n, l in enumerate(lines, 1) if DEFBLOCK.match(l)]
w_ledger_gone, pick_reason, pick_reason_text = [], 0, ''
for k in sorted(NOT_OWED):
    arm = next((c for c in w_gov if c['id'] == k), None)
    if not arm:
        continue                      # the governs-nothing limb reports it
    lo = max([h for h in def_heads if h <= arm['line']] or [1])
    hi = min([h for h in def_heads if h > arm['line']] or [len(lines) + 1])
    ev = re.compile(NOT_OWED[k][1])
    hit = next(((n, m.group(0)) for n in range(lo, hi)
                if lines[n - 1].lstrip().startswith('#')
                for m in [ev.search(lines[n - 1])] if m), None)
    if hit:
        if not pick_reason:
            pick_reason, pick_reason_text = hit
    else:
        w_ledger_gone.append(k)

w_body, on = [], False
for n, l in enumerate(lines, 1):
    if l == '  %s() {' % WARN:
        on = True
    if on:
        w_body.append((n, l))
    if on and l == '  }':
        break
w_body_txt = '\n'.join(l for _, l in w_body)
w_body_pc = PERCALLER.findall(w_body_txt)


def body_line(needle):
    return next((n for n, l in w_body if needle in l), 0)


def first(pred):
    return next((c for c in w_calls if pred(c)), None)


pick_any = first(lambda c: c['single'] and c['arity'] == 2 and ';' not in c['text'])
pick_tok = w_tok[0] if w_tok else None
pick_ungov = first(lambda c: pick_tok and c['id'] == pick_tok['id']
                   and not c['gov'] and c['tok'] is None)
pick_rat = next((c for c in w_ratified), None)
pick_led = first(lambda c: c['id'] in NOT_OWED and c['gov'])
pick_owed = w_owed[0] if w_owed else None
pick_ac1 = first(lambda c: c['id'] == 'pack-content-completeness' and c['tok'] in TOKENS)
pick_ctrl = first(lambda c: c['id'] == 'pack-content-completeness' and not c['gov'])
pick_ac2 = first(lambda c: c['id'] == 'doc-link-maintenance' and '$c14_findings' in c['text'])


def ln(c):
    return c['line'] if c else 0


out = [
    ('W_SITES', len(w_calls)),
    ('W_REG_ROWS', len(ROWS)),
    ('W_BODY_LINES', len(w_body)),
    ('W_BODY_HAS_ISSUES', int('ISSUES=$((ISSUES + 1))' in w_body_txt)),
    ('W_BODY_HAS_WARN_ARM', int('warn)' in w_body_txt)),
    ('W_BODY_HAS_TOKEN_BRANCH', int(all('"%s"' % t in w_body_txt for t in TOKENS))),
    ('W_BODY_PERCALLER', len(w_body_pc)),
    ('W_BODY_PERCALLER_DETAIL', ','.join(sorted(set(w_body_pc))) or '-'),
    ('W_SITE_PERCALLER', sum(len(PERCALLER.findall(c['text'])) for c in w_calls)),
    ('W_BODY_DEFAULT_READ', int('${3:-}' in w_body_txt)),
    ('W_BODY_BARE3', len(BARE3.findall(w_body_txt))),
    ('W_ARITY2', len([c for c in w_calls if c['arity'] == 2])),
    ('W_ARITY_BAD', len(w_arity_bad)),
    ('W_ARITY_BAD_DETAIL', ';'.join('%d:%s:arity-%d' % (c['line'], c['id'], c['arity'])
                                    for c in w_arity_bad) or '-'),
    ('W_TOKEN_SITES', len(w_tok)),
    ('W_TOKEN_IDS', len(w_tok_ids)),
    ('W_CONTRA', len(w_contra)),
    ('W_CONTRA_DETAIL', ';'.join(w_contra) or '-'),
    ('W_GOVERNED', len(w_gov)),
    ('W_GOVERNED_IDS', len({c['id'] for c in w_gov})),
    ('W_EXEMPT_RATIFIED', len(w_ratified)),
    ('W_EXEMPT_DECLINED', len(w_exempt)),
    ('W_EXEMPT_SPLIT', len(w_exempt) - len(w_ratified)),
    ('W_OWED', len(w_owed)),
    ('W_MISSING', len(w_missing)),
    ('W_MISSING_DETAIL', ';'.join('%d:%s' % (c['line'], c['id']) for c in w_missing) or '-'),
    ('W_DIALS', len(w_dials)),
    ('W_DIAL_REFS', w_dial_refs),
    ('W_DIAL_BAD', len(w_dial_bad)),
    ('W_DIAL_BAD_DETAIL', ';'.join(w_dial_bad) or '-'),
    ('W_LEDGER_SIZE', len(NOT_OWED)),
    ('W_LEDGER_STALE', len(w_ledger_stale)),
    ('W_LEDGER_STALE_DETAIL', ','.join(w_ledger_stale) or '-'),
    ('W_LEDGER_UNUSED', len(w_ledger_unused)),
    ('W_LEDGER_UNUSED_DETAIL', ','.join(w_ledger_unused) or '-'),
    ('W_LEDGER_GONE', len(w_ledger_gone)),
    ('W_LEDGER_GONE_DETAIL', ','.join(w_ledger_gone) or '-'),
    ('W_PICK_WARNLINE', body_line('log "  WARN:  $check_id')),
    ('W_PICK_CLAUSE', body_line('_clause="; ')),
    ('W_PICK_DEFAULT', body_line('local _graduation=')),
    ('W_PICK_ANY', ln(pick_any)),
    ('W_PICK_TOKEN', ln(pick_tok)),
    ('W_PICK_UNGOV', ln(pick_ungov)),
    ('W_PICK_DIAL', pick_tok['gov'][0] if pick_tok and pick_tok['gov'] else 0),
    ('W_PICK_RATIFIED', ln(pick_rat)),
    ('W_PICK_RATIFIED_ROW', ratified_row(pick_rat['id']) if pick_rat else 0),
    ('W_PICK_LEDGER', ln(pick_led)),
    ('W_PICK_LEDGER_IF', pick_led['gov'][2] if pick_led else 0),
    ('W_PICK_REASON', pick_reason),
    ('W_PICK_REASON_TEXT', pick_reason_text or '-'),
    ('W_PICK_OWED_IF', pick_owed['gov'][2] if pick_owed else 0),
    ('W_PICK_OWED_DIAL', pick_owed['gov'][0] if pick_owed else 0),
    ('W_PICK_AC1', ln(pick_ac1)),
    ('W_PICK_CTRL', ln(pick_ctrl)),
    ('W_PICK_AC2', ln(pick_ac2)),
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

# ══ WE arms — flag_warn_or_issue's graduation token ═════════════════════════
# One engine (the census above), given the standard as its second argument.
STD_MD="${SCRIPT_DIR}/../../standards/gate-efficacy-standard.md"
[[ -r "$STD_MD" ]] || STD_MD=/dev/null
we_census() { /usr/bin/python3 "$CENSUS_PY" "$1" "${2:-$STD_MD}"; }
W_BASE="$(we_census "$DEPLOY_SH")"
wf() { field "$1" "$W_BASE"; }

WE_MUT_PY="$TMPD/we_mutate.py"
cat > "$WE_MUT_PY" <<'PYEOF'
import sys
# <src> <copy> <line> append <text> | replace <old> <new> — edits ONE line of a COPY
src, dst, n, op = sys.argv[1], sys.argv[2], int(sys.argv[3] or 0), sys.argv[4]
lines = open(src, encoding='utf-8').read().split('\n')
done = False
if 1 <= n <= len(lines):
    l = lines[n - 1]
    if op == 'append':
        lines[n - 1] = l.rstrip() + sys.argv[5]
        done = True
    elif op == 'replace' and sys.argv[5] in l:
        lines[n - 1] = l.replace(sys.argv[5], sys.argv[6], 1)
        done = True
open(dst, 'w', encoding='utf-8').write('\n'.join(lines))
print('MUTATED' if done else 'NOT-MUTATED')
PYEOF
we_mut() { local _s="$1" _o="$2" _n="$3"; shift 3; /usr/bin/python3 "$WE_MUT_PY" "$_s" "$_o" "${_n:-0}" "$@"; }

# ── WE-A — extraction non-vacuity (PV-3) ─────────────────────────────────────
if [[ "$(wf W_BODY_LINES)" -gt 0 && "$(wf W_BODY_HAS_ISSUES)" == 1 && "$(wf W_BODY_HAS_WARN_ARM)" == 1 \
      && "$(wf W_BODY_HAS_TOKEN_BRANCH)" == 1 && "$(wf W_SITES)" -gt 0 && "$(wf W_GOVERNED)" -gt 0 \
      && "$(wf W_REG_ROWS)" -gt 0 && "$(wf W_EXEMPT_RATIFIED)" -gt 0 && "$(wf W_DIALS)" -gt 0 ]]; then
  pass "WE-A warn body extracted ($(wf W_BODY_LINES) lines) with its increment, warn arm and token branch; $(wf W_SITES) call sites, $(wf W_GOVERNED) governed findings arms over $(wf W_GOVERNED_IDS) ids, $(wf W_DIALS) dials; $(wf W_REG_ROWS) flip-decision rows read, $(wf W_EXEMPT_RATIFIED) arm(s) exempt by a RATIFIED ADVISORY row"
else
  fail "WE-A extraction vacuous — body lines=$(wf W_BODY_LINES), increment=$(wf W_BODY_HAS_ISSUES), warn arm=$(wf W_BODY_HAS_WARN_ARM), token branch=$(wf W_BODY_HAS_TOKEN_BRANCH), sites=$(wf W_SITES), governed=$(wf W_GOVERNED), dials=$(wf W_DIALS), register rows=$(wf W_REG_ROWS), arms exempt by a row=$(wf W_EXEMPT_RATIFIED). Zero rows means the standard moved or its table was reshaped. Every WE arm below is UNUSABLE, not clean"
fi

# ── WE-B — SUBJECT (AC-4): the warn body states no per-caller fact ───────────
if [[ "$(wf W_BODY_PERCALLER)" == 0 ]]; then
  pass "WE-B 0 per-caller facts in the warn emitter body — no mode-file name, no shared-dial name, no flip verb, no literal check id"
else
  fail "WE-B the warn emitter body carries $(wf W_BODY_PERCALLER) per-caller fact(s): $(wf W_BODY_PERCALLER_DETAIL). A fact that varies by caller cannot be correct in shared code; the caller declares it as its token"
fi

# ── WE-C — SENSITIVITY for WE-B ──────────────────────────────────────────────
_wc1="$(we_mut "$DEPLOY_SH" "$TMPD/we_c1.sh" "$(wf W_PICK_WARNLINE)" replace '(warn-mode$_clause)' "(warn-mode; flip .claude/hooks/deploy-check.mode to 'enforce' after shakedown)")"
_wc1n="$(field W_BODY_PERCALLER "$(we_census "$TMPD/we_c1.sh")")"
_wc2="$(we_mut "$DEPLOY_SH" "$TMPD/we_c2.sh" "$(wf W_PICK_CLAUSE)" replace '\"$check_id\"' '\"we-literal-id\"')"
_wc2n="$(field W_BODY_PERCALLER "$(we_census "$TMPD/we_c2.sh")")"
if [[ "$_wc1" == MUTATED && "${_wc1n:-0}" -ge 1 && "$_wc2" == MUTATED && "${_wc2n:-0}" -ge 1 ]]; then
  pass "WE-C SENSITIVITY: the historical suffix restored on a copy reads $_wc1n, a literal id in the rendered clause reads $_wc2n — so WE-B's zero is a measurement"
  note "reported, not asserted: the same pattern reads $(wf W_SITE_PERCALLER) hit(s) over caller-owned call-site text"
else
  fail "WE-C SENSITIVITY CONTROL FAILED — suffix copy $_wc1 -> ${_wc1n:-0}, literal-id copy $_wc2 -> ${_wc2n:-0} (each must be MUTATED and >=1). WE-B is UNUSABLE, not clean"
fi

# ── WE-D — SUBJECT and SENSITIVITY: an omitted token cannot trip nounset ─────
_wd="$(we_mut "$DEPLOY_SH" "$TMPD/we_d.sh" "$(wf W_PICK_DEFAULT)" replace '${3:-}' '$3')"
_wdn="$(field W_BODY_BARE3 "$(we_census "$TMPD/we_d.sh")")"
if [[ "$(wf W_BODY_DEFAULT_READ)" == 1 && "$(wf W_BODY_BARE3)" == 0 && "$_wd" == MUTATED && "${_wdn:-0}" -ge 1 ]]; then
  pass "WE-D the warn body reads its third argument as \${3:-} with no bare \$3; a copy with a bare \$3 reads $_wdn"
else
  fail "WE-D nounset safety — defaulted read=$(wf W_BODY_DEFAULT_READ) (want 1), bare \$3=$(wf W_BODY_BARE3) (want 0), sensitivity copy $_wd -> ${_wdn:-0} (want >=1). A bare \$3 aborts the whole check run on every two-argument caller"
fi

# ── WE-E — SUBJECT: every graduation token is true for its caller ────────────
if [[ "$(wf W_TOKEN_SITES)" -lt 1 ]]; then
  fail "WE-E VACUOUS — no call site carries a graduation token, so there is no claim to grade; a check whose record states the committed default carries one (WE-K)"
elif [[ "$(wf W_CONTRA)" == 0 ]]; then
  pass "WE-E 0 of $(wf W_TOKEN_SITES) graduation tokens ($(wf W_TOKEN_IDS) check ids) false for their caller — each on an arm its own dial governs; no such dial already enforce; no row declines the flip; no such check names a mode file in its own detail"
else
  fail "WE-E $(wf W_CONTRA) graduation token(s) false for their caller: $(wf W_CONTRA_DETAIL). A flip commit drops the token; an arm the dial does not govern carries none"
fi

# ── WE-F — SENSITIVITY for WE-E: each limb fires on its own mutation ─────────
we_tag() {  # $1 = copy  $2 = pick field  $3 = expected limb tag  $4.. = op ; prints ok, or what failed
  local _c="$1" _p="$2" _t="$3" _st _d; shift 3
  _st="$(we_mut "$DEPLOY_SH" "$TMPD/$_c.sh" "$(wf "$_p")" "$@")"
  _d="$(field W_CONTRA_DETAIL "$(we_census "$TMPD/$_c.sh")")"
  if [[ "$_st" == MUTATED && "$_d" == *"$_t"* ]]; then printf 'ok'; else printf '%s(%s)' "$_t" "$_st"; fi
}
_wf1="$(we_tag we_f1 W_PICK_UNGOV not-a-governed-findings-arm append ' "committed-default"')"
_wf2="$(we_tag we_f2 W_PICK_DIAL dial-already-defaults-enforce replace '")' '" "enforce")')"
_wf3="$(we_tag we_f3 W_PICK_RATIFIED flip-declined-by-its-row append ' "committed-default"')"
_wf4="$(we_tag we_f4 W_PICK_TOKEN mode-file-beside-a-committed-claim replace '" "committed-default"' ' (or flip we.mode)" "committed-default"')"
if [[ "$_wf1$_wf2$_wf3$_wf4" == okokokok ]]; then
  pass "WE-F SENSITIVITY: each of WE-E's four limbs reports its own tag on a copy mutated for it — ungoverned arm, dial already enforce, flip declined by its row, mode file beside the claim"
else
  fail "WE-F SENSITIVITY CONTROL FAILED — limbs: $_wf1 $_wf2 $_wf3 $_wf4. A limb whose mutation goes unseen is UNUSABLE; a copy that could not be mutated is a failure, never a pass"
fi

# ── Runner for WE-G / WE-H: real bodies, a recording log, nounset armed ──────
extract_fn()  { /usr/bin/sed -n "/^  $1() {\$/,/^  }\$/p" "$DEPLOY_SH"; }
extract_fn0() { /usr/bin/sed -n "/^$1() {\$/,/^}\$/p" "$DEPLOY_SH"; }
W_FW="$(extract_fn flag_warn_or_issue)"
W_RM="$(extract_fn resolve_check_mode)"
W_JE="$(extract_fn0 json_escape_detail)"
we_vars() {  # define every variable a live call line references, so a fixture gap cannot trip nounset
  local _rest="$1" _re='\$\{?([A-Za-z_][A-Za-z0-9_]*)'
  while [[ "$_rest" =~ $_re ]]; do
    printf '%s="WE-FIXTURE"\n' "${BASH_REMATCH[1]}"
    _rest="${_rest#*"${BASH_REMATCH[0]}"}"
  done
}
we_run() {  # $1 = shared mode (warn|enforce)   $2 = one shell line to execute
  local _d; _d="$(mktemp -d "$TMPD/we.XXXXXX")"; mkdir -p "$_d/inst" "$_d/cwd"
  { echo '#!/usr/bin/env bash'; echo 'set -uo pipefail'
    echo "pmo_instance_path() { printf '%s' \"$_d/inst\"; }"
    echo "pmo_instance_path_legacy() { printf '%s' \"$_d/inst\"; }"
    echo 'log() { printf "%s\n" "$1"; }'
    echo "WARN_LOG=\"$_d/warn.jsonl\""; echo "DEPLOY_CHECK_MODE=\"$1\""
    echo 'JSON_ESCAPED=""'; echo 'ISSUES=0'
    printf '%s\n' "$W_JE" "$W_RM" "$W_FW"
    we_vars "$2"
    printf '%s\n' "$2"
    echo 'printf "ISSUES\t%s\n" "$ISSUES"'
    echo "[[ -f \"$_d/warn.jsonl\" ]] && /usr/bin/sed 's/^/ROW /' \"$_d/warn.jsonl\" || true"
  } > "$_d/run.sh"
  ( cd "$_d/cwd" && bash "$_d/run.sh" 2>&1 )
}
we_emit() { /usr/bin/awk '/^  (WARN|FAIL):/{print; exit}' <<<"$1"; }
we_count() {  # occurrences of $2 in $1
  local _s="$1" _n=0
  while [[ "$_s" == *"$2"* ]]; do _s="${_s#*"$2"}"; _n=$((_n + 1)); done
  printf '%s' "$_n"
}

# ── WE-G — EXECUTED: rendering, record and verdict ───────────────────────────
G1="$(we_run warn 'flag_warn_or_issue "we-probe" "detail text"')"
G2="$(we_run warn 'flag_warn_or_issue "we-probe" "detail text" "committed-default"')"
G3="$(we_run warn 'flag_warn_or_issue "we-probe" "detail text" "we-not-a-member"')"
G4="$(we_run enforce 'flag_warn_or_issue "we-probe" "detail text" "committed-default"')"
_g1="$(we_emit "$G1")"; _g2="$(we_emit "$G2")"; _g3="$(we_emit "$G3")"; _g4="$(we_emit "$G4")"
_g2rows="$(/usr/bin/grep '^ROW ' <<<"$G2")"
_wg=1; _wgwhy=""
[[ "$_g1" == "  WARN:  we-probe — detail text (warn-mode)" && "$(field ISSUES "$G1")" == 0 \
   && "$(/usr/bin/grep -c '^ROW .*"detail":"detail text"' <<<"$G1")" == 1 ]] || { _wg=0; _wgwhy="$_wgwhy two-argument: $_g1;"; }
[[ "$_g2" == "  WARN:  we-probe — detail text (warn-mode; "*")" \
   && "$(we_count "$_g2" 'resolve_check_mode "we-probe" "enforce"')" == 1 \
   && "$(we_count "$_g2" '(warn-mode')" == 1 && "$(we_count "$_g2" '.mode')" == 0 \
   && "$(field ISSUES "$G2")" == 0 && -n "$_g2rows" && "$_g2rows" != *resolve_check_mode* ]] || { _wg=0; _wgwhy="$_wgwhy token: $_g2;"; }
[[ "$_g3" == "$_g1" && "$(field ISSUES "$G3")" == 0 ]] || { _wg=0; _wgwhy="$_wgwhy unknown token: $_g3;"; }
[[ "$_g4" == "  FAIL:  we-probe — detail text" && "$(field ISSUES "$G4")" == 1 \
   && "$(/usr/bin/grep -c '^ROW ' <<<"$G4")" == 0 ]] || { _wg=0; _wgwhy="$_wgwhy enforce: $_g4;"; }
if [[ "$_wg" -eq 1 ]]; then
  pass "WE-G executed: two arguments end (warn-mode); the token renders the committed form for its own id, once, and stays out of the row; an unknown token is silent; enforce prints the bare FAIL line and increments ISSUES once"
else
  fail "WE-G executed rendering —$_wgwhy"
fi

# ── WE-H — EXECUTED: the acceptance subjects, from the live call sites ───────
_hp1="$(wf W_PICK_AC1)"; _hpc="$(wf W_PICK_CTRL)"; _hp2="$(wf W_PICK_AC2)"
_wh=1; _whwhy=""
if [[ "${_hp1:-0}" -lt 1 || "${_hpc:-0}" -lt 1 || "${_hp2:-0}" -lt 1 ]]; then
  _wh=0; _whwhy=" a live call site could not be selected (AC-1=${_hp1:-0} control=${_hpc:-0} AC-2=${_hp2:-0});"
else
  _hl1="$(/usr/bin/sed -n "${_hp1}p" "$DEPLOY_SH")"
  _hlc="$(/usr/bin/sed -n "${_hpc}p" "$DEPLOY_SH")"
  _hl2="$(/usr/bin/sed -n "${_hp2}p" "$DEPLOY_SH")"
  for _hl in "$_hl1" "$_hlc" "$_hl2"; do
    [[ "$_hl" == *'\' ]] && { _wh=0; _whwhy="$_whwhy a selected call continues onto a second line;"; }
  done
fi
if [[ "$_wh" -eq 1 ]]; then
  _h1="$(we_emit "$(we_run warn "$_hl1")")"
  _hc="$(we_emit "$(we_run warn "$_hlc")")"
  _h2="$(we_emit "$(we_run warn "$_hl2")")"
  [[ "$(we_count "$_h1" 'resolve_check_mode "pack-content-completeness" "enforce"')" == 1 \
     && "$(we_count "$_h1" '(warn-mode')" == 1 && "$(we_count "$_h1" '.mode')" == 0 ]] || { _wh=0; _whwhy="$_whwhy AC-1: $_h1;"; }
  [[ "$_hc" == *"(warn-mode)" && "$_hc" != *resolve_check_mode* ]] || { _wh=0; _whwhy="$_whwhy control: $_hc;"; }
  [[ "$_h2" == *"(warn-mode)" && "$_h2" != *".mode"* && "$_h2" != *resolve_check_mode* ]] || { _wh=0; _whwhy="$_whwhy AC-2: $_h2;"; }
fi
if [[ "$_wh" -eq 1 ]]; then
  pass "WE-H executed from the live call sites: the committed-default check's findings line carries one instruction, the committed form (AC-1); that check's infrastructure arm carries none (control); the doc-link findings line carries none (AC-2)"
else
  fail "WE-H acceptance subjects —$_whwhy"
fi

# ── WE-I — SUBJECT: every call keeps to the closed set ───────────────────────
if [[ "$(wf W_SITES)" -gt 0 && "$(wf W_ARITY_BAD)" == 0 ]]; then
  pass "WE-I 0 of $(wf W_SITES) flag_warn_or_issue call sites outside the calling contract ($(wf W_ARITY2) at arity 2, $(wf W_TOKEN_SITES) carrying a token from the closed set)"
else
  fail "WE-I $(wf W_ARITY_BAD) call site(s) outside the contract — arity 2, or 3 ending in the bare literal \"committed-default\": $(wf W_ARITY_BAD_DETAIL)"
fi

# ── WE-J — SENSITIVITY for WE-I ──────────────────────────────────────────────
_wj1="$(we_mut "$DEPLOY_SH" "$TMPD/we_j1.sh" "$(wf W_PICK_ANY)" append ' "we-not-a-member"')"
_wj1n="$(field W_ARITY_BAD "$(we_census "$TMPD/we_j1.sh")")"
_wj2="$(we_mut "$DEPLOY_SH" "$TMPD/we_j2.sh" "$(wf W_PICK_ANY)" append ' "committed-default" "we-extra"')"
_wj2n="$(field W_ARITY_BAD "$(we_census "$TMPD/we_j2.sh")")"
if [[ "$_wj1" == MUTATED && "${_wj1n:-0}" -gt "$(wf W_ARITY_BAD)" && "$_wj2" == MUTATED && "${_wj2n:-0}" -gt "$(wf W_ARITY_BAD)" ]]; then
  pass "WE-J SENSITIVITY: a non-member third argument and a fourth argument each raise WE-I's count on a copy ($_wj1n, $_wj2n)"
else
  fail "WE-J SENSITIVITY CONTROL FAILED — non-member copy $_wj1 -> ${_wj1n:-0}, fourth-argument copy $_wj2 -> ${_wj2n:-0}. WE-I is UNUSABLE, not clean"
fi

# ── WE-K — SUBJECT (presence): every owed token is present ───────────────────
if [[ "$(wf W_OWED)" -lt 1 ]]; then
  fail "WE-K VACUOUS — no governed findings arm owes a token, so presence is graded over nothing"
elif [[ "$(wf W_MISSING)" == 0 && "$(wf W_LEDGER_STALE)" == 0 && "$(wf W_LEDGER_UNUSED)" == 0 \
        && "$(wf W_LEDGER_GONE)" == 0 && "$(wf W_DIAL_BAD)" == 0 ]]; then
  pass "WE-K 0 of $(wf W_OWED) owed graduation tokens missing, over $(wf W_GOVERNED) governed findings arms ($(wf W_EXEMPT_DECLINED) exempt by a row that declines the flip, $(wf W_EXEMPT_SPLIT) of them through a split row's residual limb; a ledger of $(wf W_LEDGER_SIZE), all current, each reason's evidence present); $(wf W_DIAL_REFS) references to $(wf W_DIALS) dials, every one in a shape the census reads"
else
  fail "WE-K owed token(s) missing at: $(wf W_MISSING_DETAIL); stale ledger entries — carries the token: $(wf W_LEDGER_STALE_DETAIL), governs nothing: $(wf W_LEDGER_UNUSED_DETAIL), reason no longer holds: $(wf W_LEDGER_GONE_DETAIL); unrecognized dial-test shape — extend the census or use the house form: $(wf W_DIAL_BAD_DETAIL). Add \"committed-default\" where the check's record states the committed default, or record why it owes none"
fi

# ── WE-L — SENSITIVITY for WE-K ──────────────────────────────────────────────
_wlr="$(wf W_MISSING)"; _wlb="$(wf W_DIAL_BAD)"; _wl=1; _wlwhy=""
_wl1="$(we_mut "$DEPLOY_SH" "$TMPD/we_l1.sh" "$(wf W_PICK_TOKEN)" replace ' "committed-default"' '')"
_wl1n="$(field W_MISSING "$(we_census "$TMPD/we_l1.sh")")"
[[ "$_wl1" == MUTATED && "${_wl1n:-0}" -gt "${_wlr:-0}" ]] || { _wl=0; _wlwhy="$_wlwhy dropped token ($_wl1 -> ${_wl1n:-0});"; }
_wl4="$(we_mut "$STD_MD" "$TMPD/we_l4.md" "$(wf W_PICK_RATIFIED_ROW)" replace 'RATIFIED ADVISORY' 'DEFERRED')"
_wl4n="$(field W_MISSING "$(we_census "$DEPLOY_SH" "$TMPD/we_l4.md")")"
[[ "$_wl4" == MUTATED && "${_wl4n:-0}" -gt "${_wlr:-0}" ]] || { _wl=0; _wlwhy="$_wlwhy register exemption ($_wl4 -> ${_wl4n:-0});"; }
# A split row exempts by its residual limb, never by its leading token alone.
_wl5="$(we_mut "$STD_MD" "$TMPD/we_l5.md" "$(wf W_PICK_RATIFIED_ROW)" replace 'RATIFIED ADVISORY' 'SPLIT DISPOSITION')"
_wl5n="$(field W_MISSING "$(we_census "$DEPLOY_SH" "$TMPD/we_l5.md")")"
[[ "$_wl5" == MUTATED && "${_wl5n:-0}" -gt "${_wlr:-0}" ]] || { _wl=0; _wlwhy="$_wlwhy split row naming no declined limb ($_wl5 -> ${_wl5n:-0});"; }
_wl6="$(we_mut "$STD_MD" "$TMPD/we_l6.md" "$(wf W_PICK_RATIFIED_ROW)" replace 'RATIFIED ADVISORY' 'SPLIT DISPOSITION — (ii) a PERMANENT advisory residual;')"
_wl6n="$(field W_MISSING "$(we_census "$DEPLOY_SH" "$TMPD/we_l6.md")")"
[[ "$_wl6" == MUTATED && "${_wl6n:-x}" == "${_wlr:-0}" ]] || { _wl=0; _wlwhy="$_wlwhy split row naming a permanent residual ($_wl6 -> ${_wl6n:-x}, want ${_wlr:-0});"; }
_wl8="$(we_mut "$DEPLOY_SH" "$TMPD/we_l8.sh" "$(wf W_PICK_OWED_IF)" replace '== "enforce"' '= "enforce"')"
_wl8n="$(field W_DIAL_BAD "$(we_census "$TMPD/we_l8.sh")")"
[[ "$_wl8" == MUTATED && "${_wl8n:-0}" -gt "${_wlb:-0}" ]] || { _wl=0; _wlwhy="$_wlwhy governed test rewritten to = ($_wl8 -> ${_wl8n:-0});"; }
_wl9="$(we_mut "$DEPLOY_SH" "$TMPD/we_l9.sh" "$(wf W_PICK_OWED_DIAL)" append ' || true')"
_wl9n="$(field W_DIAL_BAD "$(we_census "$TMPD/we_l9.sh")")"
[[ "$_wl9" == MUTATED && "${_wl9n:-0}" -gt "${_wlb:-0}" ]] || { _wl=0; _wlwhy="$_wlwhy dial read outside the house form ($_wl9 -> ${_wl9n:-0});"; }
if [[ "$(wf W_LEDGER_SIZE)" -gt 0 ]]; then
  _wl2="$(we_mut "$DEPLOY_SH" "$TMPD/we_l2.sh" "$(wf W_PICK_LEDGER)" append ' "committed-default"')"
  _wl2n="$(field W_LEDGER_STALE "$(we_census "$TMPD/we_l2.sh")")"
  [[ "$_wl2" == MUTATED && "${_wl2n:-0}" -ge 1 ]] || { _wl=0; _wlwhy="$_wlwhy ledger id carries token ($_wl2 -> ${_wl2n:-0});"; }
  _wl3="$(we_mut "$DEPLOY_SH" "$TMPD/we_l3.sh" "$(wf W_PICK_LEDGER_IF)" replace '== "enforce"' '== "we-enforce"')"
  _wl3n="$(field W_LEDGER_UNUSED "$(we_census "$TMPD/we_l3.sh")")"
  [[ "$_wl3" == MUTATED && "${_wl3n:-0}" -ge 1 ]] || { _wl=0; _wlwhy="$_wlwhy ledger id governs nothing ($_wl3 -> ${_wl3n:-0});"; }
  _wl7="$(we_mut "$DEPLOY_SH" "$TMPD/we_l7.sh" "$(wf W_PICK_REASON)" replace "$(wf W_PICK_REASON_TEXT)" 'we-reason-removed')"
  _wl7n="$(field W_LEDGER_GONE "$(we_census "$TMPD/we_l7.sh")")"
  [[ "$_wl7" == MUTATED && "${_wl7n:-0}" -ge 1 ]] || { _wl=0; _wlwhy="$_wlwhy ledger reason's evidence removed ($_wl7 -> ${_wl7n:-0});"; }
  _wlled="all three ledger legs applied"
else
  _wlled="the ledger is empty, so its three legs are not applicable"
fi
if [[ "$_wl" -eq 1 ]]; then
  pass "WE-L SENSITIVITY: a dropped owed token, and a flip-decision row re-dispositioned on a copy of the standard, each raise WE-K's missing count; a split row raises it unless its column 3 names a permanent residual; a governed test rewritten to = and a dial read outside the house form each raise its shape count; $_wlled"
else
  fail "WE-L SENSITIVITY CONTROL FAILED —$_wlwhy WE-K is UNUSABLE, not clean"
fi

echo "─────────────────────────────────────────────────────────────────────────"
echo "test_advisory_emitter_contract: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
[[ "$FAIL_COUNT" -eq 0 ]] || exit 1

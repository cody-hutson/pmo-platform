#!/usr/bin/env bash
# test_warn_log_json_escape.sh — proves deploy.sh's warn-log `detail` serialization
# emits a valid JSON line for a value carrying a control character, and proves the
# pre-fix serialization did not.
#
# Cite the code under test by its INLINE MARKER, never by line number:
#   core/deploy/deploy.sh, `json_escape_detail()`
# Resolver: grep -n 'json_escape_detail()' core/deploy/deploy.sh
#
# WHY THIS EXISTS. 659 rows of the live deploy-check warn-log family are not valid
# JSON, because a raw TAB reaches the `detail` field unescaped: the pre-fix writer
# folded a backslash and a double-quote and nothing else, while RFC 8259 §7 requires
# every U+0000–U+001F in a JSON string to be escaped. Any drain that parses the log
# as one object per line silently drops those rows from BOTH the numerator and the
# denominator of every count computed over the file.
#
# THE CONTROL ARM IS THE POINT, NOT DECORATION. A test that only drives the fixed
# writer and observes a parseable row proves the harness works, not that the fix
# works — the same PASS would appear if the input never carried a control character
# at all. Arm B therefore reproduces the pre-fix two-substitution pair verbatim, on
# the SAME input, through the SAME emit format, and requires the row to FAIL to
# parse. A zero-failure control arm means the fixture stopped carrying a control
# character and the whole file is reporting on nothing; Arm B fails loudly in that
# case rather than letting Arm A pass for the wrong reason.
#
# THE HELPER IS SOURCED, NOT REIMPLEMENTED. Arm A extracts the shipped
# json_escape_detail() definition out of deploy.sh and evaluates it, so the function
# under test is the one that ships. Reimplementing it here would test a copy, and a
# copy is exactly the defect class this card removes.
#
# HERMETIC by construction: every row is written under mktemp -d. The live warn-log
# family and the live durable corpus are READ and never written. No `gh`, no network.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DEPLOY_SH="${SRC_ROOT}/core/deploy/deploy.sh"

PASS_COUNT=0
FAIL_COUNT=0
report() { # report <name> <ok:1|0> [detail]
  if [[ "$2" == "1" ]]; then
    echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: $1${3:+ — $3}"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}
note() { printf '        %s\n' "$1"; }

if [[ ! -f "$DEPLOY_SH" ]]; then
  echo "  FAIL: code under test missing: $DEPLOY_SH"
  echo "passed=0 failed=1"
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "  FAIL: python3 is required to parse the emitted rows back"
  echo "passed=0 failed=1"
  exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/warnlog-json-escape-XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# ── Extract the shipped helper ───────────────────────────────────────────────
# From the `JSON_ESCAPED=""` initialiser down to the first line that is a bare `}`
# at column 0 after the function header. Anchored on the function's own name, so a
# relocation of the block inside deploy.sh does not break the extraction.
HELPER_SRC="${TMP}/helper.sh"
awk '
  /^JSON_ESCAPED=""$/            { grab = 1 }
  grab                           { print }
  grab && /^}$/ && seen_header   { exit }
  /^json_escape_detail\(\) \{$/  { seen_header = 1 }
' "$DEPLOY_SH" > "$HELPER_SRC"

helper_lines="$(awk 'END { print NR }' "$HELPER_SRC")"
extract_ok=1; extract_missing=""
[[ "$helper_lines" -ge 10 ]] || { extract_ok=0; extract_missing="extracted only ${helper_lines} line(s)"; }
grep -qF 'json_escape_detail() {' "$HELPER_SRC" \
  || { extract_ok=0; extract_missing="${extract_missing:+$extract_missing; }no function header in the extract"; }
grep -qF 'JSON_ESCAPED="$_s"' "$HELPER_SRC" \
  || { extract_ok=0; extract_missing="${extract_missing:+$extract_missing; }no terminal assignment in the extract"; }
report "A0 the shipped json_escape_detail() definition was extracted from deploy.sh (${helper_lines} lines)" \
  "$extract_ok" "$extract_missing"
if [[ "$extract_ok" != "1" ]]; then
  echo
  echo "passed=$PASS_COUNT failed=$FAIL_COUNT"
  exit 1
fi

# shellcheck source=/dev/null
. "$HELPER_SRC"

# ── The fixture set ──────────────────────────────────────────────────────────
# Row 3 is the real shape: 656 of the 659 live malformed rows carry the prefix
# `input failure (exit N): ERROR<TAB>…`, emitted by the check-*.py primitives'
# TSV diagnostic contract, which deploy.sh does not own.
TAB="$(printf '\t')"
BEL="$(printf '\007')"
US="$(printf '\037')"

FIXTURES=(
  "plain text with no control character"
  "tab${TAB}here"
  "input failure (exit 3): ERROR${TAB}Check 56 could not resolve the milestone"
  "quote\"and\\slash"
  "bell${BEL}here"
  "unit${US}separator"
)

# ── Emit: Arm A through the shipped helper, Arm B through the pre-fix pair ───
# Both arms use the SAME printf format string the shipped emitters use, so the only
# variable between them is the serialization step.
A_OUT="${TMP}/arm-a.jsonl"
B_OUT="${TMP}/arm-b.jsonl"
: > "$A_OUT"
: > "$B_OUT"

for _fx in "${FIXTURES[@]}"; do
  json_escape_detail "$_fx"
  printf '{"ts":"2026-01-01T00:00:00Z","check":"test-subject","detail":"%s"}\n' \
    "$JSON_ESCAPED" >> "$A_OUT" 2>/dev/null || true

  # Arm B — the pre-fix serialization, reproduced verbatim: backslash, then
  # double-quote, and nothing else.
  _pre="${_fx//\\/\\\\}"
  _pre="${_pre//\"/\\\"}"
  printf '{"ts":"2026-01-01T00:00:00Z","check":"test-control","detail":"%s"}\n' \
    "$_pre" >> "$B_OUT" 2>/dev/null || true
done

# The fixture set is written to disk so the parser reads the same bytes the shell
# produced, rather than a re-encoding of them.
FX_OUT="${TMP}/fixtures.txt"
: > "$FX_OUT"
for _fx in "${FIXTURES[@]}"; do printf '%s\n' "$_fx" >> "$FX_OUT"; done

# ── The parser ───────────────────────────────────────────────────────────────
# Emits three integers per arm: rows, parse-failures, roundtrip-mismatches.
# A roundtrip mismatch is only counted for a row that parsed; an unparseable row
# is already counted as a failure and would double-count.
PARSE_PY="${TMP}/parse.py"
cat > "$PARSE_PY" <<'PYEOF'
import json, sys

rows_path, fx_path = sys.argv[1], sys.argv[2]
originals = [l[:-1] if l.endswith("\n") else l for l in open(fx_path, "r", encoding="utf-8")]
rows = [l for l in open(rows_path, "r", encoding="utf-8") if l.strip()]

bad, mismatch = 0, 0
for i, line in enumerate(rows):
    try:
        obj = json.loads(line)
    except ValueError:
        bad += 1
        continue
    want = originals[i] if i < len(originals) else None
    if obj.get("detail") != want:
        mismatch += 1
print("%d %d %d" % (len(rows), bad, mismatch))
PYEOF

read -r a_rows a_bad a_mismatch < <(python3 "$PARSE_PY" "$A_OUT" "$FX_OUT")
read -r b_rows b_bad b_mismatch < <(python3 "$PARSE_PY" "$B_OUT" "$FX_OUT")

want_rows="${#FIXTURES[@]}"

# ── A1 — DENOMINATOR: the population is non-empty and complete ───────────────
# Asserted before any zero is read, so a zero below can never be a zero over an
# empty file.
a1_ok=1; a1_missing=""
[[ "$a_rows" -eq "$want_rows" ]] || { a1_ok=0; a1_missing="arm A wrote ${a_rows} row(s), want ${want_rows}"; }
[[ "$b_rows" -eq "$want_rows" ]] || { a1_ok=0; a1_missing="${a1_missing:+$a1_missing; }arm B wrote ${b_rows} row(s), want ${want_rows}"; }
report "A1 both arms emitted the full fixture set (denominator = ${want_rows} rows)" "$a1_ok" "$a1_missing"

# ── A2 — SUBJECT: every row through the shipped helper is valid JSON ────────
[[ "$a_bad" -eq 0 ]] \
  && report "A2 every row serialized by json_escape_detail() parses as valid JSON (${a_bad} failures of ${a_rows})" 1 \
  || report "A2 every row serialized by json_escape_detail() parses as valid JSON" 0 \
       "${a_bad} of ${a_rows} rows failed to parse"

# ── A3 — SUBJECT: every parsed row round-trips to its input exactly ─────────
# This is what makes A2 more than a syntax check: an escaper that dropped the
# control character entirely would also produce parseable rows.
[[ "$a_mismatch" -eq 0 ]] \
  && report "A3 every parsed row's decoded detail equals its input byte-for-byte (${a_mismatch} mismatches)" 1 \
  || report "A3 every parsed row's decoded detail equals its input byte-for-byte" 0 \
       "${a_mismatch} of ${a_rows} rows did not round-trip"

# ── A4 — CONTROL (sensitivity): the pre-fix serialization FAILS ─────────────
# The arm that makes A2's zero mean something. A zero here is a BROKEN PROBE, not
# a clean result: it means the fixtures no longer carry a control character and A2
# is passing over an input that could not have exhibited the defect.
if [[ "$b_bad" -ge 1 ]]; then
  report "A4 the pre-fix two-substitution serialization produces unparseable rows on the same input (${b_bad} of ${b_rows})" 1
  note "the control arm fires, so A2's zero is a measurement rather than an unresolvable-pattern zero"
else
  report "A4 the pre-fix two-substitution serialization produces unparseable rows on the same input" 0 \
    "control arm returned 0 failures over ${b_rows} rows — BROKEN PROBE: the fixture set no longer carries a control character, so A2/A3 are passing over an input that cannot exhibit the defect"
fi

# ── A5 — CONTROL (specificity): the plain fixture parses under BOTH arms ────
# Bounds A4: the pre-fix writer is not broken for everything, only for control
# characters. Without this, A4 would also pass if arm B were emitting garbage.
PLAIN_A="${TMP}/plain-a.jsonl"
PLAIN_B="${TMP}/plain-b.jsonl"
PLAIN_FX="${TMP}/plain-fx.txt"
printf '%s\n' "${FIXTURES[0]}" > "$PLAIN_FX"
json_escape_detail "${FIXTURES[0]}"
printf '{"ts":"2026-01-01T00:00:00Z","check":"test-subject","detail":"%s"}\n' "$JSON_ESCAPED" > "$PLAIN_A"
_pp="${FIXTURES[0]//\\/\\\\}"; _pp="${_pp//\"/\\\"}"
printf '{"ts":"2026-01-01T00:00:00Z","check":"test-control","detail":"%s"}\n' "$_pp" > "$PLAIN_B"
read -r pa_rows pa_bad pa_mismatch < <(python3 "$PARSE_PY" "$PLAIN_A" "$PLAIN_FX")
read -r pb_rows pb_bad pb_mismatch < <(python3 "$PARSE_PY" "$PLAIN_B" "$PLAIN_FX")
a5_ok=1; a5_missing=""
[[ "$pa_rows" -eq 1 && "$pb_rows" -eq 1 ]] || { a5_ok=0; a5_missing="near-miss input produced ${pa_rows}/${pb_rows} rows, want 1/1"; }
[[ "$pa_bad" -eq 0 && "$pa_mismatch" -eq 0 ]] || { a5_ok=0; a5_missing="${a5_missing:+$a5_missing; }subject arm failed on the control-character-free input"; }
[[ "$pb_bad" -eq 0 && "$pb_mismatch" -eq 0 ]] || { a5_ok=0; a5_missing="${a5_missing:+$a5_missing; }pre-fix arm failed on the control-character-free input, so A4 is not control-character-specific"; }
report "A5 a control-character-free input parses and round-trips under BOTH arms (A4 is specific to the defect, not a broken arm B)" "$a5_ok" "$a5_missing"

# ── A6 — SUBJECT: full C0 coverage, not TAB-only ────────────────────────────
# The invariant is the writer being correct for input it does not own: 28
# check-*.py primitives emit TSV diagnostics through this path, and escaping only
# the character observed today leaves the identical defect latent for the next one.
c0_bad=0; c0_total=0; c0_failed=""
for _code in 1 2 7 11 14 27 31; do
  _ch="$(printf "\\$(printf '%03o' "$_code")")"
  _val="pre${_ch}post"
  c0_total=$((c0_total + 1))
  json_escape_detail "$_val"
  printf '{"ts":"2026-01-01T00:00:00Z","check":"c0","detail":"%s"}\n' "$JSON_ESCAPED" > "${TMP}/c0.jsonl"
  printf '%s\n' "$_val" > "${TMP}/c0-fx.txt"
  read -r _cr _cb _cm < <(python3 "$PARSE_PY" "${TMP}/c0.jsonl" "${TMP}/c0-fx.txt")
  if [[ "$_cr" -ne 1 || "$_cb" -ne 0 || "$_cm" -ne 0 ]]; then
    c0_bad=$((c0_bad + 1))
    c0_failed="${c0_failed:+$c0_failed, }U+$(printf '%04X' "$_code")"
  fi
done
[[ "$c0_bad" -eq 0 ]] \
  && report "A6 every sampled C0 code point round-trips, not only TAB (${c0_total} of ${c0_total})" 1 \
  || report "A6 every sampled C0 code point round-trips, not only TAB" 0 \
       "${c0_bad} of ${c0_total} failed: ${c0_failed}"

# ── A7 — COMPLETENESS: one definition, nine call sites, zero surviving pairs ─
# The name- and keyword-agnostic completeness matcher. It keys on neither the
# `local` keyword nor any variable name, because the surface carries a
# differently-named variable (`_frf_esc`) and a `local`-less assignment
# (`_c56_m4_esc`) — the two sites a `local _detail_escaped=` instrument cannot see.
COMPLETENESS_PY="${TMP}/completeness.py"
cat > "$COMPLETENESS_PY" <<'PYEOF'
import re, sys

lines = open(sys.argv[1], "r", encoding="utf-8").read().split("\n")
idiom = re.compile(r"\{[A-Za-z_][A-Za-z0-9_]*//\\\\/")
hits = [i + 1 for i, l in enumerate(lines) if idiom.search(l)]

defs = [i + 1 for i, l in enumerate(lines) if l.startswith("json_escape_detail() {")]
calls = sum(len(re.findall(r'json_escape_detail "', l)) for l in lines)

# Bound the definition's own body so the one idiom occurrence it legitimately
# contains is not counted as a surviving duplicate at a call site.
outside = len(hits)
if defs:
    start = defs[0]
    end = len(lines)
    for i in range(start, len(lines)):
        if lines[i] == "}":
            end = i + 1
            break
    outside = len([h for h in hits if not (start <= h <= end)])

print("%d %d %d %d" % (len(hits), len(defs), calls, outside))
PYEOF

read -r n_idiom n_defs n_calls n_outside < <(python3 "$COMPLETENESS_PY" "$DEPLOY_SH")
a7_ok=1; a7_missing=""
[[ "$n_defs" -eq 1 ]]    || { a7_ok=0; a7_missing="definitions=${n_defs}, want 1"; }
[[ "$n_calls" -eq 9 ]]   || { a7_ok=0; a7_missing="${a7_missing:+$a7_missing; }call sites=${n_calls}, want 9"; }
[[ "$n_outside" -eq 0 ]] || { a7_ok=0; a7_missing="${a7_missing:+$a7_missing; }surviving inline escape pairs outside the definition=${n_outside}, want 0"; }
report "A7 exactly one definition, nine call sites, zero surviving inline escape pairs outside it (reads ${n_idiom} ${n_defs} ${n_calls} ${n_outside})" \
  "$a7_ok" "$a7_missing"
note "the first term is 1 by construction: the surviving definition necessarily contains the idiom it replaced. The fourth term excludes the definition's own body and is the one that asserts completeness."

# ── A8 — CONTROL (null-arm): the same matcher over the pre-fix source ────────
# Reconstructs the pre-fix shape by reversing the conversion on a COPY, then runs
# the identical instrument. Without this arm A7's `1 1 9 0` is a reading with no
# demonstration that the instrument can register anything else.
PREFIX_COPY="${TMP}/deploy-prefix.sh"
python3 - "$DEPLOY_SH" "$PREFIX_COPY" <<'PYEOF'
import re, sys
src = open(sys.argv[1], "r", encoding="utf-8").read()
# Reverse the conversion: turn each two-line helper call back into the two-line
# inline pair it replaced. Indentation and the preserved local name are captured
# so the reconstruction matches the shape the file actually carried.
pat = re.compile(
    r'^(?P<ind>[ \t]*)json_escape_detail "\$(?P<src>[A-Za-z_][A-Za-z0-9_]*)"\n'
    r'(?P=ind)(?P<decl>local )?(?P<var>[A-Za-z_][A-Za-z0-9_]*)="\$JSON_ESCAPED"$',
    re.M,
)
def back(m):
    ind, s, decl, var = m.group("ind"), m.group("src"), m.group("decl") or "", m.group("var")
    return (ind + decl + var + '="${' + s + '//\\\\/\\\\\\\\}"\n'
            + ind + var + '="${' + var + '//\\"/\\\\\\"}"')
out, n = pat.subn(back, src)
# Remove the definition too, so the null arm is the pre-fix file rather than a
# hybrid carrying both shapes.
out = re.sub(r'^JSON_ESCAPED=""\njson_escape_detail\(\) \{\n(?:.*\n)*?\}\n', "", out, count=1, flags=re.M)
open(sys.argv[2], "w", encoding="utf-8").write(out)
sys.stderr.write("reverted %d call site(s)\n" % n)
PYEOF

read -r p_idiom p_defs p_calls p_outside < <(python3 "$COMPLETENESS_PY" "$PREFIX_COPY")
a8_ok=1; a8_missing=""
[[ "$p_idiom" -eq 9 ]]  || { a8_ok=0; a8_missing="pre-fix idiom count=${p_idiom}, want 9"; }
[[ "$p_defs" -eq 0 ]]   || { a8_ok=0; a8_missing="${a8_missing:+$a8_missing; }pre-fix definitions=${p_defs}, want 0"; }
[[ "$p_calls" -eq 0 ]]  || { a8_ok=0; a8_missing="${a8_missing:+$a8_missing; }pre-fix call sites=${p_calls}, want 0"; }
report "A8 the same matcher over the reconstructed pre-fix source reads the 9 / 0 / 0 baseline null-arm (reads ${p_idiom} ${p_defs} ${p_calls})" \
  "$a8_ok" "$a8_missing"

# ── A9 — CONTROL (blindness): the retired instrument reads 7, not 9 ─────────
# Pins WHY the matcher above is name- and keyword-agnostic. If this ever reads 9,
# the two odd sites have been renamed into the common shape and A7's fourth term
# is no longer guarding anything a simpler instrument would miss.
old_reads="$(python3 -c "import re,sys; print(len(re.findall(r'local _detail_escaped=', open(sys.argv[1], encoding='utf-8').read())))" "$PREFIX_COPY")"
if [[ "$old_reads" -eq 7 ]]; then
  report "A9 the retired \`local _detail_escaped=\` instrument reads 7 of the 9 pre-fix sites (blind to _frf_esc and _c56_m4_esc)" 1
  note "under that instrument a post-fix reading of 1 would have graded PASS with two sites unconverted"
else
  report "A9 the retired \`local _detail_escaped=\` instrument reads 7 of the 9 pre-fix sites" 0 \
    "reads ${old_reads} — the blindness this file pins has changed shape; re-derive before trusting A7"
fi

# ── A10 — drift guard: deploy.sh still carries the markers this file pins ───
a10_ok=1; a10_missing=""
for lit in 'json_escape_detail() {' 'JSON_ESCAPED="$_s"' '*[[:cntrl:]]*'; do
  grep -qF -- "$lit" "$DEPLOY_SH" || { a10_ok=0; a10_missing="${a10_missing:+$a10_missing; }'$lit' absent from deploy.sh"; }
done
report "A10 deploy.sh still carries the helper header, the terminal assignment and the cntrl short-circuit this file pins" "$a10_ok" "$a10_missing"

# ── Arm-count floor — the expectation lives HERE, not in a handoff ──────────
# This suite runs 11 arms: A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 A10. The Stage-6
# handoff quoted `passed=10 failed=0` as the expected line, which is fail-UNSAFE
# in the one direction that matters: a run that lost an arm to an early `exit`,
# a mis-set fixture or a silently-skipped branch reports a LOWER pass count with
# zero failures, and reads as success against a number that was already too low.
# Asserting the total here makes a missing arm a failure rather than a quieter
# pass, and keeps the expected value in the file that owns it, where a reader
# can re-derive it from the arms themselves.
EXPECTED_ARMS=11
_ran=$((PASS_COUNT + FAIL_COUNT))
if [[ "$_ran" -ne "$EXPECTED_ARMS" ]]; then
  echo "  FAIL: arm-count floor — $_ran of $EXPECTED_ARMS arms reported (A0..A10). A run that reports fewer arms than the suite defines has skipped one; its passes do not cover the missing arm's subject"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo
echo "passed=$PASS_COUNT failed=$FAIL_COUNT arms=$_ran/$EXPECTED_ARMS"
[[ "$FAIL_COUNT" -eq 0 ]] || exit 1

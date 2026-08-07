#!/usr/bin/env bash
# test_g1_06_priority_carrier.sh — regression net for the deploy.sh Check 22
# G1-06 priority-carrier criterion.
#
# What this proves, and why it is shaped the way it is.
#
# G1-06 used to bind one carrier — the bold-inline `**Priority:** P2` form —
# and was therefore blind to every body the intake form renders, which uses a
# `### Priority` heading instead. The fix does not author a better carrier
# regex. Per ADR-111 ("The P-level digit is the canonical priority satisfier.
# The carrier is not part of the contract... A consumer that needs an issue's
# priority reuses the shared detector"), Check 22 DELEGATES to
# release/tools/bundle-issues-parser.py parse_priority_body and holds no
# grammar of its own.
#
# THE SUBJECT OF THIS TEST IS THE DELEGATION, NOT THE LIBRARY. A suite that
# imports parse_priority_body and pins sixteen fixtures certifies a detector
# nobody in this change is modifying, and certifies nothing about the glue that
# is the entire deliverable. An earlier draft of this net did exactly that, and
# a falsification run proved all of its arms stayed GREEN on a state where the
# delegation had been deleted and only its explanatory comment retained. That
# is an assertion that cannot fail, which is the same defect class the original
# bug belonged to.
#
# So the arms are ordered by what they can actually catch:
#
#   A. Fixture table (16 cases) — the carrier grammar the delegation inherits,
#      including the no-carrier control that makes the positive cases mean
#      something. Catches: a regression in the shared detector.
#   B. Executable-glue arm — EXTRACTS the delegate program from the live
#      deploy.sh between its two sentinel markers and RUNS it against fixture
#      JSON, asserting the resulting number-to-level map. Catches: a broken
#      extraction, a changed map format, a lost delegation, a wrong key.
#   C. Failure-posture arms — runs the same extracted program against a missing
#      primitive and asserts the failure is DISTINGUISHABLE from a clean result
#      (non-zero exit AND a non-empty diagnostic on the captured stream).
#      Catches: a silently-swallowed stderr, a degraded state rendered clean.
#   D. Lookup arm — a faithful copy of the per-issue map lookup, driven by the
#      map arm B produced. Catches: a broken needle, a lost delimiter.
#   E. Drift guard — four arms, the first of which is restricted to NON-COMMENT
#      lines precisely because the change's own comments name the delegated
#      function, so a bare substring grep stays green on a deleted delegation.
#   F. Self-falsification — constructs the regressed state (delegation deleted,
#      comment retained) and PROVES arm E discriminates: GREEN on the live
#      file, RED on the regressed one. If a future edit makes the guard
#      undiscriminating, THIS arm fails and says so.
#
# Hermetic by construction: no `gh`, no network, no live tracker. It reads the
# in-repo parser (stdlib-only, __main__-guarded, import-safe) and the in-repo
# deploy.sh, and writes only into a temp directory it removes.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DEPLOY_SH="${REPO_ROOT}/core/deploy/deploy.sh"
PARSER="${REPO_ROOT}/release/tools/bundle-issues-parser.py"
PY=/usr/bin/python3

PASS_COUNT=0
FAIL_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf '  ok   %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf '  FAIL %s\n' "$1"; }

TMPDIR_T="$(mktemp -d)"
cleanup() { [[ -n "${TMPDIR_T:-}" && -d "$TMPDIR_T" ]] && rm -rf "$TMPDIR_T"; }
trap cleanup EXIT

echo "── Preconditions ─────────────────────────────────────────────────────────"
for _f in "$DEPLOY_SH" "$PARSER"; do
  if [[ -f "$_f" ]]; then pass "present: ${_f#"$REPO_ROOT"/}"; else fail "missing: $_f"; fi
done
if [[ -x "$PY" ]]; then pass "interpreter executable: $PY"; else fail "interpreter not executable: $PY"; fi
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "G1-06 priority-carrier regression: FAILED (preconditions)"; exit 1
fi

# ── A. Fixture table — one case per live carrier, plus the controls ──────────
echo ""
echo "── A. Carrier fixture table (16 cases; F4 is the non-vacuity control) ────"
"$PY" - "$PARSER" <<'PY' > "$TMPDIR_T/fixtures.out" 2>&1
import importlib.util, pathlib, sys
spec = importlib.util.spec_from_file_location("bip", pathlib.Path(sys.argv[1]))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)

CASES = [
    ("F1",  "### Priority\n\nP2 - High\n",                                    "P2", "form-rendered heading + value on the next line"),
    ("F2",  "**Priority:** P2\n",                                             "P2", "agent-authored bold inline"),
    ("F2b", "**Priority**: P2 - High\n",                                      "P2", "bold label, colon outside the bold"),
    ("F3",  "### Severity\n\nP2 - Material\n",                                "P2", "bug-template Severity adapter"),
    ("F4",  "### Outcome\n\nSomething entirely else.\n",                      None, "CONTROL — no priority field at all"),
    ("P1",  "## Priority\n\nP3 - Medium\n",                                   "P3", "H2 heading (any heading level)"),
    ("P2",  "### Severity P1 - Blocker\n",                                    "P1", "label and value on one line"),
    ("P3",  "Priority: P4 - Low\n",                                           "P4", "plain inline, no bold"),
    ("N1",  "...markers. Priority P3 (immediate behavioral rule)\n",          None, "mid-prose mention — line anchor rejects it"),
    ("N2",  "Parent epic **#1106**. Priority P2-High.\n",                     None, "mid-prose mention after other text"),
    ("N3",  "Priority `P2 - High` is [RECOMMENDED] for this class\n",         None, "backticked value in prose, not a field"),
    ("N4",  "**Severity:** Moderate — needs triage\n",                        None, "word-only value: no digit, so unset"),
    ("N5",  "### Priority\n\nLow — latent until the gate flips\n",            None, "word-only value under a heading"),
    ("N6",  "| Field | Form |\n| Priority | `**Priority:** P1` |\n",          None, "table cell quoting the carrier syntax"),
    ("N7",  "### Priority\n\n_No response_\n",                                None, "form default when the dropdown is left unset"),
    ("N8",  "### Priority\n\nP5 - Someday\n",                                 None, "out of the P1-P4 enum"),
]
bad = 0
for cid, body, want, note in CASES:
    got = mod.parse_priority_body(body)
    if got == want:
        print("ok   [%-3s] %-6s %s" % (cid, got if got else "unset", note))
    else:
        bad += 1
        print("FAIL [%-3s] want=%s got=%s  %s" % (cid, want, got, note))
print("FIXTURE_FAILURES=%d" % bad)
PY
/usr/bin/grep -v '^FIXTURE_FAILURES=' "$TMPDIR_T/fixtures.out" | /usr/bin/sed 's/^/  /'
_fx=$(/usr/bin/grep '^FIXTURE_FAILURES=' "$TMPDIR_T/fixtures.out" | /usr/bin/sed 's/^FIXTURE_FAILURES=//')
if [[ "${_fx:-1}" == "0" ]]; then
  pass "all 16 carrier fixtures resolve as specified (incl. the F4 no-carrier control)"
else
  fail "${_fx:-?} carrier fixture(s) mismatched — see above"
fi

# ── Extract the delegate program from the LIVE deploy.sh ─────────────────────
# This is what makes arms B and C test the check rather than the library.
extract_delegate_program() {
  "$PY" - "$DEPLOY_SH" <<'PY'
import sys
src = open(sys.argv[1], encoding="utf-8").read().splitlines()
b = [i for i, l in enumerate(src) if "G1-06-DELEGATE-BEGIN" in l]
e = [i for i, l in enumerate(src) if "G1-06-DELEGATE-END" in l]
if not b or not e or e[0] <= b[0]:
    sys.stderr.write("delegate sentinels not found or out of order\n")
    sys.exit(3)
seg = src[b[0]:e[0]]
starts = [i for i, l in enumerate(seg) if l.rstrip().endswith("python3 -c '")]
if not starts:
    sys.stderr.write("no python3 -c heredoc opener inside the delegate region\n")
    sys.exit(4)
s = starts[0]
stops = [i for i, l in enumerate(seg) if i > s and l.lstrip().startswith("'")]
if not stops:
    sys.stderr.write("no closing quote for the python3 -c program\n")
    sys.exit(5)
sys.stdout.write("\n".join(seg[s + 1:stops[0]]))
PY
}

echo ""
echo "── B. Executable-glue arm: run the LIVE delegate program on fixtures ─────"
DELEGATE_PROG="$(extract_delegate_program 2>"$TMPDIR_T/extract.err")"
_extract_rc=$?
if [[ "$_extract_rc" -ne 0 || -z "$DELEGATE_PROG" ]]; then
  fail "could not extract the delegate program from deploy.sh (rc=$_extract_rc): $(/usr/bin/head -1 "$TMPDIR_T/extract.err" 2>/dev/null)"
else
  pass "delegate program extracted from deploy.sh ($(printf '%s\n' "$DELEGATE_PROG" | /usr/bin/grep -c '') lines, between the sentinel markers)"

  cat > "$TMPDIR_T/issues.json" <<'JSON'
[
  {"number": 9001, "body": "### Proposed Change\n\nsomething\n\n### Priority\n\nP2 - High\n"},
  {"number": 9002, "body": "### Reproduction Steps\n\nrun it\n\n**Severity:** P1 - Blocker\n"},
  {"number": 9003, "body": "### Proposed Change\n\nno priority field anywhere in this body\n"},
  {"number": 9004, "body": "### Proposed Change\n\nx\n\n### Priority\n\n_No response_\n"}
]
JSON
  GLUE_MAP="$("$PY" -c "$DELEGATE_PROG" "$PARSER" < "$TMPDIR_T/issues.json" 2>&1)"
  _glue_rc=$?
  EXPECT_MAP='|9001:P2|9002:P1|9003:-|9004:-|'
  if [[ "$_glue_rc" -eq 0 && "$GLUE_MAP" == "$EXPECT_MAP" ]]; then
    pass "live delegate program emits the expected map: $GLUE_MAP"
  else
    fail "live delegate program map mismatch (rc=$_glue_rc)
         want: $EXPECT_MAP
         got:  $GLUE_MAP"
  fi
  # Non-vacuity of arm B itself: the map must contain BOTH a resolved level and
  # an unresolved sentinel, so it cannot pass by resolving everything or nothing.
  if [[ "$GLUE_MAP" == *":P"* && "$GLUE_MAP" == *":-|"* ]]; then
    pass "arm B is non-vacuous — the map carries both a resolved level and an unresolved sentinel"
  else
    fail "arm B is vacuous — the map is uniformly resolved or uniformly unresolved: $GLUE_MAP"
  fi

  echo ""
  echo "── C. Failure posture: a broken primitive must NOT look like a clean run ─"
  BAD_OUT="$("$PY" -c "$DELEGATE_PROG" "$TMPDIR_T/no-such-parser.py" < "$TMPDIR_T/issues.json" 2>&1)"
  _bad_rc=$?
  if [[ "$_bad_rc" -ne 0 ]]; then
    pass "missing primitive exits non-zero (rc=$_bad_rc) — the caller can branch on it"
  else
    fail "missing primitive exited 0 — the failure is indistinguishable from success"
  fi
  if [[ -n "$BAD_OUT" ]]; then
    pass "missing primitive emits a diagnostic on the captured stream ($(printf '%s\n' "$BAD_OUT" | /usr/bin/grep -v '^[[:space:]]*$' | /usr/bin/tail -1 | /usr/bin/cut -c1-72))"
  else
    fail "missing primitive emitted NOTHING — stderr is being discarded, so three different failures report as one"
  fi
  if [[ "$BAD_OUT" != "$GLUE_MAP" ]]; then
    pass "degraded output is distinguishable from the clean map (the two differ)"
  else
    fail "degraded output equals the clean map — a broken measurement reads as a clean result"
  fi
fi

# ── D. Per-issue lookup — faithful copy of the deploy.sh map lookup ──────────
echo ""
echo "── D. Per-issue map lookup (faithful copy; drift-guarded in arm E) ───────"
g1_06_lookup() {
  local _map="$1" _num="$2" _needle _out
  _needle="|${_num}:"
  _out="${_map##*"$_needle"}"
  _out="${_out%%|*}"
  printf '%s' "$_out"
}
assert_lookup() {
  local _want="$1" _num="$2" _note="$3" _got
  _got="$(g1_06_lookup "${GLUE_MAP:-$EXPECT_MAP}" "$_num")"
  if [[ "$_got" == "$_want" ]]; then
    pass "lookup #${_num} -> '${_got}'  ${_note}"
  else
    fail "lookup #${_num} want='${_want}' got='${_got}'  ${_note}"
  fi
}
assert_lookup "P2" 9001 "resolved level"
assert_lookup "P1" 9002 "resolved level, different value (so the lookup is not returning a constant)"
assert_lookup "-"  9003 "unresolved sentinel"
assert_lookup ""   9999 "CONTROL — number absent from the map yields empty, not a stale neighbour"
assert_lookup "P2" 9001 "re-read is stable"

# ── E. Drift guard ───────────────────────────────────────────────────────────
echo ""
echo "── E. Drift guard (arm E1 is restricted to NON-COMMENT lines) ────────────"

# E1 — the delegation is LIVE CODE, not a comment that mentions it. The bare
#      substring form of this arm is green on a deleted delegation, because the
#      surrounding comment names the function; arm F proves this form is not.
E1_PATTERN='^[[:space:]]*[^#[:space:]].*parse_priority_body'
_e1_hits=$(/usr/bin/grep -cE "$E1_PATTERN" "$DEPLOY_SH" || true)
if [[ "${_e1_hits:-0}" -ge 1 ]]; then
  pass "E1 Check 22 still DELEGATES — ${_e1_hits} non-comment reference(s) to parse_priority_body"
else
  fail "E1 no non-comment reference to parse_priority_body — the delegation was removed (a comment mentioning it does not count)"
fi

# E2 — no local carrier regex has re-grown. This is the arm that stops the
#      original bug recurring: the check must never bind a carrier itself.
E2_PATTERN='\*\*(Priority|Severity):\*\*[[:space:]]*P\[1-4\]'
if /usr/bin/grep -qE "$E2_PATTERN" "$DEPLOY_SH"; then
  fail "E2 a local carrier regex has re-grown in deploy.sh — change the shared detector instead"
else
  pass "E2 no local carrier regex in deploy.sh"
fi

# E3 — the authority still exists at its cited home.
if /usr/bin/grep -q 'PRIORITY_FIELD_RE' "$PARSER"; then
  pass "E3 the shared detector is still at its cited home"
else
  fail "E3 PRIORITY_FIELD_RE not found in the parser — the cited authority moved or was renamed"
fi

# E4 — the degraded-state contract still gates the per-issue branch, so one
#      unavailable primitive cannot fan out into one finding per issue.
if /usr/bin/grep -qE '^[[:space:]]*if \[\[ "\$c22_prio_ok" == "true" &&' "$DEPLOY_SH"; then
  pass "E4 the per-issue G1-06 branch is still gated on the primitive-availability flag"
else
  fail "E4 the per-issue G1-06 branch is no longer gated on c22_prio_ok — a missing primitive would FAIL every issue instead of marking the criterion not-evaluated"
fi

# E5 — the per-issue lookup arm D copies is still the live one.
for _frag in '_prio_needle="|\$\{_num\}:"' '_prio="\$\{c22_prio_map##\*"\$_prio_needle"\}"' '_prio="\$\{_prio%%\|\*\}"'; do
  if /usr/bin/grep -qE "$_frag" "$DEPLOY_SH"; then
    pass "E5 live lookup fragment present: $_frag"
  else
    fail "E5 lookup fragment missing from deploy.sh (arm D's copy is stale): $_frag"
  fi
done

# ── F. Self-falsification: prove arm E1 can actually go red ──────────────────
echo ""
echo "── F. Self-falsification — E1 must be RED on a regressed deploy.sh ───────"
# Construct the exact regressed state the adversarial review demonstrated:
# every NON-COMMENT line naming the delegated function is removed, and every
# comment that names it is retained. A guard that stays green here is a guard
# that cannot detect the regression it exists to prevent.
"$PY" - "$DEPLOY_SH" "$TMPDIR_T/deploy_regressed.sh" <<'PY'
import re, sys
src = open(sys.argv[1], encoding="utf-8").read().splitlines(True)
keep = []
removed = 0
for line in src:
    stripped = line.lstrip()
    is_comment = stripped.startswith("#")
    if "parse_priority_body" in line and not is_comment:
        removed += 1
        continue
    keep.append(line)
open(sys.argv[2], "w", encoding="utf-8").writelines(keep)
sys.stderr.write("removed=%d\n" % removed)
PY
_regressed_removed=$(/usr/bin/grep -c 'parse_priority_body' "$TMPDIR_T/deploy_regressed.sh" || true)
_regressed_noncomment=$(/usr/bin/grep -cE "$E1_PATTERN" "$TMPDIR_T/deploy_regressed.sh" || true)

if [[ "${_regressed_removed:-0}" -ge 1 ]]; then
  pass "F regressed fixture retains ${_regressed_removed} COMMENT mention(s) of the delegated function — the falsification state is faithful"
else
  fail "F regressed fixture retains no mention at all — this is not the state the guard must discriminate (a bare substring grep would trivially catch it)"
fi

# The assertion is DIRECTIONAL, so it must not pass vacuously: "red on the
# regressed copy" proves nothing unless the live file is green. Both halves are
# required, or a tree whose delegation is already gone would report a
# discriminating guard while E1 is failing two arms above.
if [[ "${_e1_hits:-0}" -ge 1 && "${_regressed_noncomment:-0}" -eq 0 ]]; then
  pass "F E1 is GREEN on the live file (${_e1_hits}) and RED on the regressed fixture (0) — the guard DISCRIMINATES"
elif [[ "${_e1_hits:-0}" -lt 1 ]]; then
  fail "F cannot demonstrate discrimination — the LIVE file already has 0 non-comment references, so the green half of the assertion is unavailable (see E1)"
else
  fail "F E1 is GREEN on the regressed fixture (${_regressed_noncomment} non-comment references) — the guard cannot detect its own regression"
fi

# The control that makes arm F meaningful: the naive substring form the earlier
# draft used must be shown to be GREEN on BOTH states, i.e. undiscriminating.
_naive_live=$(/usr/bin/grep -c 'parse_priority_body' "$DEPLOY_SH" || true)
if [[ "${_naive_live:-0}" -ge 1 && "${_regressed_removed:-0}" -ge 1 ]]; then
  pass "F CONTROL — the naive substring form is green on BOTH states (live ${_naive_live}, regressed ${_regressed_removed}); the tightening is load-bearing, not cosmetic"
else
  fail "F CONTROL — could not demonstrate the naive form's blindness; arm F's claim is unproven"
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf 'Result: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "G1-06 priority-carrier regression: FAILED"
  exit 1
fi
echo "G1-06 priority-carrier regression: PASSED"
exit 0

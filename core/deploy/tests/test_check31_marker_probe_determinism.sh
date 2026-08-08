#!/usr/bin/env bash
# test_check31_marker_probe_determinism.sh — regression test for deploy.sh Check 31's
# two per-file override-marker probes (reference-durability saturation).
#
# Cite the code under test by its INLINE MARKER, never by line number:
#   core/deploy/deploy.sh, `# PLUMBING (#3833 — same defect class as #4224`
# Resolver: grep -n 'PLUMBING (#3833' core/deploy/deploy.sh
#
# WHAT THIS PROVES, and why a value assertion could not.
# Check 31 read each file's override marker by piping the stripped body into a quiet
# grep, under deploy.sh's `set -euo pipefail`. A quiet grep exits on its FIRST match;
# the writer is still writing, hits EPIPE, and pipefail promotes ITS non-zero status
# to the pipeline's — so a SUCCESSFUL match reported failure and the marker was
# silently ignored. The reported Class-L count therefore varied run to run on a
# byte-identical corpus.
#
# THE FAILING STATUS IS NOT ALWAYS 141 — read the disposition, not the folklore.
# Which non-zero code appears is a property of the writer's SIGPIPE disposition,
# not of the defect:
#   * default disposition — the writer DIES on the signal and bash reports 128+13
#     = 141. This is what a developer shell shows.
#   * SIGPIPE inherited as SIG_IGN — the writer never receives the signal. It sees
#     EPIPE, prints `printf: write error: Broken pipe`, and returns 1. This is what
#     a GitHub-hosted runner hands the step, so on CI the signature is rc=1 —
#     INDISTINGUISHABLE from `grep` legitimately finding nothing.
# Both dispositions reproduce the same defect: a haystack that DOES contain the
# literal is reported CLEAN. Anything downstream that hunts for "141" as THE
# signature will miss the CI case entirely; hunt for a non-zero status on a
# pipeline whose reader short-circuits.
#
# A single-run count assertion CANNOT fail on this defect: any one run produces some
# self-consistent number. The defect is run-to-run INEQUALITY, so this file asserts
# equality across N runs (T1) and completeness against an independent census (T2).
#
# T3 is the load-bearing control. Without it, T1/T2 would pass on a fixture too small
# to exercise EPIPE at all — a green test asserting nothing, which is the exact
# false-confidence class this release exists to close. T3 runs the PRE-FIX form on the
# same fixture and requires it to FAIL, so the fixture is proven to reproduce the
# defect before the fixed form is credited with surviving it. T4 is its symmetric
# partner: a below-capacity file must be read correctly by BOTH forms, so T3 is
# pinned to the capacity mechanism rather than to "the old form never works".
#
# Hermetic by construction: every fixture is built under mktemp -d. The live durable
# corpus is NEVER read and NEVER mutated. The only live file touched is deploy.sh,
# read-only, by the T5/T6 drift guards.
#
# Precedent: core/deploy/tests/test_check45_governing_doc_name_match.sh — a faithful
# copy of the predicate under test pinned against fixtures, plus a drift guard that
# greps deploy.sh by marker so a silent edit fails this test rather than passing it
# stale.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"

PASS_COUNT=0
FAIL_COUNT=0
report() { # report <name> <ok:1|0> [detail]
  if [[ "$2" == "1" ]]; then
    echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "  FAIL: $1${3:+ — $3}"; FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

LINK_RE='<!--[[:space:]]*reference-durability:[[:space:]]*allow-link[[:space:]]*-->'
VER_RE='<!--[[:space:]]*reference-durability:[[:space:]]*allow-version-ref[[:space:]]*-->'

# ── Fixture corpus ───────────────────────────────────────────────────────────
# Pipe capacity is 64 KiB on the macOS/Linux runners. A marker-carrying body ABOVE
# that bound guarantees the writer is still writing when a quiet grep exits on a
# first-line match, so the pre-fix form drops the marker deterministically rather
# than racily — which is what makes T3 a stable control instead of a flaky one.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

_pad() { # _pad <file> <approx-bytes> — filler that matches NEITHER marker
  local f="$1" want="$2" line="filler line for capacity padding, no marker here at all"
  local n=$(( want / ${#line} + 1 ))
  for ((i = 0; i < n; i++)); do printf '%s %d\n' "$line" "$i"; done >> "$f"
}

# BIG-BOTH: marker on line 1, body far above capacity, carries both markers.
big_both="$TMP/big-both.md"
{ echo '<!-- reference-durability: allow-link -->'
  echo '<!-- reference-durability: allow-version-ref -->'; } > "$big_both"
_pad "$big_both" 200000

# BIG-LINK: above capacity, allow-link only.
big_link="$TMP/big-link.md"
echo '<!-- reference-durability: allow-link -->' > "$big_link"
_pad "$big_link" 150000

# SMALL-LINK: well below capacity, allow-link only. The T4 control.
small_link="$TMP/small-link.md"
echo '<!-- reference-durability: allow-link -->' > "$small_link"
_pad "$small_link" 500

# NONE: above capacity, no marker at all. Guards against a probe that says yes to
# everything — a tally that counted every file would pass T1/T2 without this.
none_big="$TMP/none-big.md"
: > "$none_big"; _pad "$none_big" 120000

FIXTURES=("$big_both" "$big_link" "$small_link" "$none_big")
# Independent census, computed WITHOUT any pipe: the ground truth for T2.
CENSUS_LINK=3   # big_both, big_link, small_link
CENSUS_VER=1    # big_both

# ── The two probe forms ──────────────────────────────────────────────────────
# NEW = the shipped form (herestring; no writer left to signal).
probe_new() {
  local link=0 ver=0 f body
  for f in "${FIXTURES[@]}"; do
    body="$(cat "$f")"
    local al=0 av=0
    grep -qE "$LINK_RE" <<< "$body" && al=1
    grep -qE "$VER_RE"  <<< "$body" && av=1
    link=$((link + al)); ver=$((ver + av))
  done
  printf 'link=%d ver=%d' "$link" "$ver"
}

# OLD = the PRE-FIX form, reproduced verbatim ON PURPOSE as the T3 negative control.
# This is the only intentional occurrence of the pipe form on the core/deploy/ surface;
# it is a defect reproduction, not a defect. Do not "fix" it — deleting it silently
# disarms the control that proves this whole file discriminates.
probe_old() {
  local link=0 ver=0 f body
  for f in "${FIXTURES[@]}"; do
    body="$(cat "$f")"
    local al=0 av=0
    # stderr is suppressed because the failing write is EXPECTED here: the writer
    # takes SIGPIPE and bash reports `echo: write error: Broken pipe`. That message
    # is the defect's own signature (it is what #4224 surfaced on its runner), not a
    # fault in this test — suppressed so a CI reader does not read the control
    # working as the harness breaking.
    # sigpipe-idiom: allow — DELIBERATE pre-fix reproduction (the T3 control arm). See the header note above: converting these two lines disarms the control that proves this whole file discriminates.
    echo "$body" 2>/dev/null | grep -qE "$LINK_RE" && al=1
    # sigpipe-idiom: allow — same T3 control arm, version-ref probe.
    echo "$body" 2>/dev/null | grep -qE "$VER_RE" && av=1
    link=$((link + al)); ver=$((ver + av))
  done
  printf 'link=%d ver=%d' "$link" "$ver"
}

echo "test_check31_marker_probe_determinism.sh"
echo

# ── T1 — run-to-run equality (the assertion the defect can actually fail) ────
RUNS=5
first="$(probe_new)"
t1_ok=1; t1_detail=""
for ((r = 2; r <= RUNS; r++)); do
  this="$(probe_new)"
  [[ "$this" == "$first" ]] || { t1_ok=0; t1_detail="run$r '$this' != run1 '$first'"; }
done
report "T1 shipped probe is stable across $RUNS runs on a fixed corpus" "$t1_ok" "$t1_detail"

# ── T2 — completeness against the independent census ────────────────────────
expect="link=${CENSUS_LINK} ver=${CENSUS_VER}"
[[ "$first" == "$expect" ]] \
  && report "T2 shipped probe detects every marker-carrying file ($expect)" 1 \
  || report "T2 shipped probe detects every marker-carrying file" 0 "got '$first', want '$expect'"

# ── T3 — NEGATIVE CONTROL: the pre-fix form must FAIL on this same fixture ──
old="$(probe_old)"
if [[ "$old" == "$expect" ]]; then
  report "T3 pre-fix form drops above-capacity markers (fixture exercises the defect)" 0 \
    "pre-fix form returned the CORRECT '$old' — the fixture no longer reproduces the defect, so T1/T2 prove nothing"
else
  report "T3 pre-fix form drops above-capacity markers (fixture exercises the defect)" 1
  echo "        pre-fix='$old'  shipped='$first'  census='$expect'"
fi

# ── T4 — capacity control: below-capacity file read correctly by BOTH forms ─
sub_new=0; sub_old=0
body="$(cat "$small_link")"
grep -qE "$LINK_RE" <<< "$body" && sub_new=1
# sigpipe-idiom: allow — DELIBERATE pre-fix form (the T4 capacity control); it must be the OLD shape to pin T3 to capacity rather than to form.
echo "$body" | grep -qE "$LINK_RE" && sub_old=1
[[ "$sub_new" == "1" && "$sub_old" == "1" ]] \
  && report "T4 below-capacity marker is read by BOTH forms (T3 is capacity-bound, not form-bound)" 1 \
  || report "T4 below-capacity marker is read by BOTH forms" 0 "new=$sub_new old=$sub_old"

# ── T5 — drift guard: the live probes use the herestring form ───────────────
live_new=$(grep -cE "grep -qE '<!--\[\[:space:\]\]\*reference-durability:.*<<< \"\\\$_stripped\"" "$DEPLOY_SH" 2>/dev/null || true)
[[ "$live_new" == "2" ]] \
  && report "T5 both live Check 31 override probes read a herestring" 1 \
  || report "T5 both live Check 31 override probes read a herestring" 0 "found $live_new herestring probes, want 2"

# ── T6 — the negative assertion that BOUNDS the defect in deploy.sh ─────────
# Card AC-2 / CIAC-3: zero pipe-form quiet-grep probes may remain in deploy.sh.
live_old=$(grep -cE 'echo[[:space:]]+"\$[A-Za-z_]+"[[:space:]]*\|[[:space:]]*grep[[:space:]]+-q' "$DEPLOY_SH" 2>/dev/null || true)
[[ "$live_old" == "0" ]] \
  && report "T6 deploy.sh carries zero pipe-form quiet-grep probes" 1 \
  || report "T6 deploy.sh carries zero pipe-form quiet-grep probes" 0 "found $live_old"

# ── T7 — anti-vacuity: the marker regexes this file pins still match deploy.sh ──
# If Check 31's regexes were reworded, T5's grep could return 0 and T1-T4 would keep
# passing against a pattern the live check no longer uses. Bind them.
for re_name in 'allow-link' 'allow-version-ref'; do
  if grep -qF "reference-durability:[[:space:]]*${re_name}[[:space:]]*-->" "$DEPLOY_SH"; then
    report "T7 live Check 31 still probes for '${re_name}'" 1
  else
    report "T7 live Check 31 still probes for '${re_name}'" 0 "marker regex not found in deploy.sh — this test is pinned to a stale pattern"
  fi
done

# ── T8/T9/T10 — the #3832 sweep's own regression arm ────────────────────────
# WHY THIS LIVES HERE rather than in a new suite: this file already builds the
# >64 KiB multi-line early-match fixture, already carries a pre-fix control arm,
# and is already wired into install-tests.yml. A second suite would need its own
# workflow step on a file two other in-flight changes are editing.
#
# WHAT IT ADDS. T1-T4 prove the fixture reproduces the defect for Check 31's own
# marker probes. T8/T9 prove the SAME fixture still reproduces it for the guard
# SHAPE the #3832 sweep converted across the install-regression surface, and that
# the converted shape survives it. The distinction matters: a conversion that
# merely compiles is not a conversion that fixes anything.
#
# WHY A FAITHFUL COPY rather than sourcing a converted guard: the highest-
# consequence converted guard is `depersonalization_line_verdict` in
# release/tools/lib/deciders-carveout.sh, and core/ takes no code-import on
# release/. This mirrors the probe_new/probe_old precedent above — copy the
# predicate, then pin the copy with a drift guard (T10) so it cannot go stale.
#
# THE FAILURE MODE BEING PINNED is not a crash. Under `pipefail` the writer fails on
# the broken pipe and the pipeline reports ITS status (141 under the default SIGPIPE
# disposition, 1 under an inherited SIG_IGN — see the disposition note in the file
# header); the predicate is written `if ! <pipeline>`, so that non-zero inverts to
# "no match" and a haystack that DOES contain the literal is reported CLEAN. A gate
# that silently passes what it exists to catch.

# CONVERTED form — the shape the sweep landed.
_ac7_converted() { # <content> <pattern-file> -> CLEAN | BLOCKED
  ( set -uo pipefail
    if [ ! -s "$2" ] || [ -z "$1" ] || ! grep -qE -f "$2" <<<"$1"; then
      printf 'CLEAN\n'
    else
      printf 'BLOCKED\n'
    fi )
}

# PRE-CONVERSION form — reproduced ON PURPOSE, exactly as probe_old is. Deleting
# it disarms the control that proves the converted form is doing anything.
_ac7_prefix() { # <content> <pattern-file> -> CLEAN | BLOCKED
  ( set -uo pipefail
    # sigpipe-idiom: allow — DELIBERATE pre-conversion reproduction. This line IS the T9 control; converting it deletes the proof that T8 asserts anything.
    if [ ! -s "$2" ] || ! printf '%s' "$1" | grep -qE -f "$2" 2>/dev/null; then
      printf 'CLEAN\n'
    else
      printf 'BLOCKED\n'
    fi )
}

ac7_pat="$TMP/ac7-patterns"
printf '%s\n' 'SENTINEL-LITERAL-3832' > "$ac7_pat"
ac7_file="$TMP/ac7-body.txt"
echo 'SENTINEL-LITERAL-3832 appears on line one — the EARLY match' > "$ac7_file"
_pad "$ac7_file" 200000          # far above the 64 KiB pipe bound, multi-line
AC7_CONTENT="$(cat "$ac7_file")"
ac7_bytes=${#AC7_CONTENT}
ac7_lines=$(printf '%s\n' "$AC7_CONTENT" | wc -l | tr -d ' ')

# The SMALL companion haystack — same needle, same shape, below the pipe bound.
# It is T9's discrimination control; see the note above the T9 assertion.
AC7_SMALL="$(printf '%s\n%s\n' 'SENTINEL-LITERAL-3832 appears on line one — the EARLY match' 'one short filler line')"

# SIGPIPE disposition — probed, and the probe's LIMIT stated rather than hidden.
# `trap -p PIPE` reports a signal that was ignored on entry to the shell and
# prints nothing otherwise. That reading is ADVISORY and known to be incomplete:
# on the GitHub-hosted macOS runner it prints nothing (reading "not ignored")
# while the writer nonetheless returns 1 rather than dying on the signal. So the
# probe cannot establish which regime you are in; the observed exit code is the
# fact, and this label is a hint. Nothing is asserted on it — the T9 predicate
# below accepts both codes precisely because this cannot be determined portably.
if [ -n "$(trap -p PIPE 2>/dev/null)" ]; then
  ac7_disp="shell reports SIGPIPE inherited-ignored"
else
  ac7_disp="shell reports no inherited ignore (advisory only — the macOS runner reads this way and still returns 1)"
fi

# Raw pipeline status under pipefail, asserted directly rather than inferred.
set +e
( set -uo pipefail; grep -qE -f "$ac7_pat" <<<"$AC7_CONTENT" ); ac7_rc_new=$?
# sigpipe-idiom: allow — DELIBERATE pre-conversion reproduction; this is the arm that must fail non-zero.
( set -uo pipefail; printf '%s' "$AC7_CONTENT" | grep -qE -f "$ac7_pat" 2>/dev/null ); ac7_rc_old=$?
# sigpipe-idiom: allow — DELIBERATE pre-conversion reproduction; T9's small-haystack positive control.
( set -uo pipefail; printf '%s' "$AC7_SMALL" | grep -qE -f "$ac7_pat" 2>/dev/null ); ac7_rc_old_small=$?
set -e

ac7_new="$(_ac7_converted "$AC7_CONTENT" "$ac7_pat")"
ac7_old="$(_ac7_prefix    "$AC7_CONTENT" "$ac7_pat")"
ac7_old_small="$(_ac7_prefix "$AC7_SMALL" "$ac7_pat")"

# T8 — the converted guard survives the fixture and returns the CORRECT verdict.
if [[ "$ac7_new" == "BLOCKED" && "$ac7_rc_new" -eq 0 ]]; then
  report "T8 converted guard reads a ${ac7_bytes}-byte / ${ac7_lines}-line early-match haystack under pipefail (rc=0, BLOCKED)" 1
else
  report "T8 converted guard reads a large early-match haystack under pipefail" 0 \
    "verdict='$ac7_new' (want BLOCKED), rc=$ac7_rc_new (want 0)"
fi

# T9 — NEGATIVE CONTROL. The pre-conversion form must MISREAD this same fixture.
# If this ever passes, the fixture stopped reproducing the defect and T8 proves nothing.
#
# WHY THE rc CLAUSE IS A SET AND NOT `141`. The exit code is a property of the
# writer's SIGPIPE disposition, not of the defect: 141 when the signal is fatal,
# 1 when it was inherited as SIG_IGN (which is what a GitHub-hosted runner hands
# the step). Pinning 141 made this arm assert the environment rather than the
# behaviour, and it turned `Shell harness (macOS)` red at 287dd846 on a fixture
# that was reproducing the defect perfectly. `verdict == CLEAN` is the load-bearing
# half and holds under both. The rc clause stays NON-ZERO so a fixture that has
# stopped firing (rc=0, BLOCKED) still fails this arm.
#
# WHY THE SMALL-HAYSTACK CONTROL IS PART OF THE SAME ASSERTION. Under SIG_IGN the
# failing status is 1 — the very code `grep` returns when it legitimately finds
# nothing. rc alone can therefore no longer tell "the defect fired" from "the needle
# never matched", and an arm that cannot tell those apart asserts nothing. The
# control runs the SAME pre-conversion form against the SAME needle on a haystack
# below the pipe bound and requires rc=0 / BLOCKED. Passing it proves the needle
# matches this content, so CLEAN on the large haystack is the defect and not a
# non-match. Under the default disposition 141 carried that discrimination for
# free; under SIG_IGN this control is what restores it.
if [[ "$ac7_old" == "CLEAN" && "$ac7_rc_old" -ne 0 ]] \
   && { [[ "$ac7_rc_old" -eq 141 ]] || [[ "$ac7_rc_old" -eq 1 ]]; } \
   && [[ "$ac7_old_small" == "BLOCKED" && "$ac7_rc_old_small" -eq 0 ]]; then
  report "T9 pre-conversion form breaks its pipe on the same fixture and misreports CLEAN (rc=$ac7_rc_old; small-haystack control BLOCKED at rc=0)" 1
  echo "        rc=$ac7_rc_old — 141 where the writer DIES on SIGPIPE, 1 where it sees EPIPE and returns instead; both are this defect. Probe (advisory): $ac7_disp"
  echo "        pre-conversion='$ac7_old' rc=$ac7_rc_old   converted='$ac7_new' rc=$ac7_rc_new   control(small)='$ac7_old_small' rc=$ac7_rc_old_small"
else
  report "T9 pre-conversion form breaks its pipe on the same fixture and misreports CLEAN" 0 \
    "verdict='$ac7_old' (want CLEAN), rc=$ac7_rc_old (want 141 or 1, non-zero; disposition: $ac7_disp), small-haystack control='$ac7_old_small' rc=$ac7_rc_old_small (want BLOCKED / 0) — either the fixture no longer reproduces the defect or the needle no longer matches, and T8 asserts nothing"
fi

# T10 — drift guard for the COPY. T8/T9 grade a reproduction of the converted
# shape; this asserts the shape is still what the tree actually ships, so the
# copy cannot quietly diverge from the code it stands in for.
ac7_live=$(grep -cE 'grep[[:space:]]+-q[A-Za-z]*([[:space:]]+-[A-Za-z]+)*[[:space:]]+.*<<<' "$DEPLOY_SH" 2>/dev/null || true)
[[ "$ac7_live" -ge 1 ]] \
  && report "T10 deploy.sh ships at least one converted here-string quiet-grep guard ($ac7_live found)" 1 \
  || report "T10 deploy.sh ships at least one converted here-string quiet-grep guard" 0 \
       "found 0 — either the sweep regressed or this drift guard is pinned to a stale shape"

echo
echo "passed=$PASS_COUNT failed=$FAIL_COUNT"
[[ "$FAIL_COUNT" -eq 0 ]] || exit 1

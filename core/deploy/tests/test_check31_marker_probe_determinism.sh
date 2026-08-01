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
# the writer is still writing, takes SIGPIPE, and pipefail promotes its 141 to the
# pipeline's status — so a SUCCESSFUL match reported failure and the marker was
# silently ignored. The reported Class-L count therefore varied run to run on a
# byte-identical corpus.
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
    echo "$body" 2>/dev/null | grep -qE "$LINK_RE" && al=1
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

echo
echo "passed=$PASS_COUNT failed=$FAIL_COUNT"
[[ "$FAIL_COUNT" -eq 0 ]] || exit 1

#!/usr/bin/env bash
# test_corpus_home_tolerance.sh — corpus-home adapter tolerance conformance suite
#
# ─── Why this exists ─────────────────────────────────────────────────────────
#
# The constraint under test is CH-1..CH-4 of
#   release/references/standards/corpus-home-adapter-constraints.md
# chiefly CH-1: when corpus-path resolution becomes instance-aware and the
# instance-corpus root is ABSENT, `automated-closeout.sh --check-paths` must
# record N/A and exit 0 — never HARD-FAIL. It is a REQUIRED step of the
# closeout-smoke CI job, so a HARD-FAIL-on-absence resolver reddens every PR
# raised from a fresh clone or a CI runner.
#
# ─── The vacuity trap this suite exists to avoid ─────────────────────────────
#
# The obvious test is "set PMO_INSTANCE_PATH to a nonexistent directory and
# assert --check-paths exits 0". That test passes TODAY — not because the
# tolerance property holds, but because NOTHING IN THE SCRIPT READS THE
# INSTANCE PATH AT ALL. It would pass today, pass after a correct seam ships,
# and pass after a VIOLATING seam ships. It is indistinguishable from `return 0`.
#
# This suite instead models the post-adapter world directly: the corpus is moved
# OUT of $REPO_ROOT and into an instance root. Against today's repo-homed
# resolver that genuinely FAILS — which is what makes the assertion real.
#
# ─── Fixture matrix (exit codes measured, not assumed) ───────────────────────
#
#   Fixture | in-tree corpus        | instance root         | asserts | today
#   --------|-----------------------|-----------------------|---------|-------
#      A    | ABSENT                | PRESENT, corpus inside| CH-2    |   1
#      B    | ABSENT                | ABSENT                | CH-1/4  |   1
#      C    | present, LOG omitted  | (pinned absent)       | CH-3    |   1
#      D    | present, all four     | (pinned absent)       | CH-3    |   0
#
# ─── The teeth are a DIVERGENCE rule, not a pass rule ────────────────────────
#
#   R1  d != 0                              -> FAIL  in-tree baseline regressed
#   R2  c == 0                              -> FAIL  probe blind to a broken path
#   R3  a == 0 && b != 0                    -> FAIL  SEAM LANDED, TOLERANCE VIOLATED (CH-1)
#   R4  a == 0 && b == 0 && B has no N/A    -> FAIL  tolerance is silent            (CH-4)
#   R5  a != 0 && b == 0                    -> FAIL  degenerate resolver            (CH-2)
#   R6  a claimed CH-id is missing from the standard -> FAIL  doc<->test binding broken
#       a != 0 && b != 0                    -> PENDING-SEAM     exit 0 + notice
#       a == 0 && b == 0 && B has N/A       -> PASS-SEAM-LANDED exit 0 + retire-notice
#
# R1/R2/R5/R6 gate from day one. R3/R4 ARM THEMSELVES: the instant --check-paths
# becomes instance-aware with a HARD-FAIL-on-absence resolver, fixture A starts
# passing while B still fails and the PR introducing it goes red. No cutoff date,
# no flag to flip, no human who must remember the standard exists.
#
# TODAY a=1 and b=1, so the verdict is PENDING-SEAM and the suite exits 0. It
# CANNOT redden a PR before the seam lands.
#
# ─── Hermeticity contract ────────────────────────────────────────────────────
#
# mktemp fixtures only. No network, no `gh`, no git remote, and no write outside
# the temp tree — the real checkout is never mutated. HOME and CLAUDE_WORKSPACE_ROOT
# are PINNED to an empty temp dir for every fixture so an ambient operator instance
# on the runner cannot leak into a fixture and silently defeat it.
#
# ─── Instrument validation ───────────────────────────────────────────────────
#
# CLOSEOUT_SH_UNDER_TEST overrides the script under test. Without it the
# PENDING-SEAM branch would be unfalsifiable — nobody could distinguish this
# suite from a stub. The negative control is:
#
#   patch a throwaway copy of automated-closeout.sh with an instance-aware
#   resolver that HARD-FAILs on absence, then
#     CLOSEOUT_SH_UNDER_TEST=<copy> bash release/tools/tests/test_corpus_home_tolerance.sh
#   MUST exit 1 citing R3 / CH-1.
#
# Usage: bash release/tools/tests/test_corpus_home_tolerance.sh [--help]

set -uo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# This file lives at release/tools/tests/, so the repo root is THREE levels up
# (tests -> tools -> release -> root). One level too few or too many silently
# anchors outside the repo and every path below resolves to nothing — the
# mis-anchor defect class. P8 below asserts the anchor rather than trusting it.
REPO_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"
CLOSEOUT="${CLOSEOUT_SH_UNDER_TEST:-$REPO_ROOT/release/tools/automated-closeout.sh}"
STANDARD="$REPO_ROOT/release/references/standards/corpus-home-adapter-constraints.md"

# The CH ids this suite claims to assert. R6 binds them to the standard.
CLAIMED_IDS="CH-1 CH-2 CH-3 CH-4"

if [[ "${1:-}" == "--help" ]]; then
  sed -n '3,60p' "${BASH_SOURCE[0]}"
  exit 0
fi

FAILURES=0
fail() { echo "  FAIL  $*" >&2; FAILURES=$((FAILURES + 1)); }
pass() { echo "  PASS  $*"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# An empty directory used as a pinned HOME / CLAUDE_WORKSPACE_ROOT for every
# fixture, so no ambient operator instance is reachable from inside a fixture.
PINNED_HOME="$TMP/pinned-home"
mkdir -p "$PINNED_HOME"

echo "corpus-home tolerance conformance"
echo "  repo root:      $REPO_ROOT"
echo "  script under test: $CLOSEOUT"
echo

# ─── Fixture construction ────────────────────────────────────────────────────

# build_repo <root> <corpus-mode>
#   corpus-mode: none    -> no release/releases/ at all (fixtures A/B)
#                partial -> notes/ + INDEX + DIGEST, RELEASE_LOG DELIBERATELY absent (C)
#                full    -> all four corpus paths present (D)
build_repo() {
  local root="$1" mode="$2"
  mkdir -p "$root/release/tools"
  cp "$CLOSEOUT" "$root/release/tools/automated-closeout.sh"
  case "$mode" in
    none) : ;;
    partial)
      mkdir -p "$root/release/releases/notes"
      : > "$root/release/releases/RELEASE_INDEX.md"
      : > "$root/release/releases/RELEASE_DIGEST.md"
      # RELEASE_LOG.md intentionally absent — this is fixture C's deliberate break.
      ;;
    full)
      mkdir -p "$root/release/releases/notes"
      : > "$root/release/releases/RELEASE_LOG.md"
      : > "$root/release/releases/RELEASE_INDEX.md"
      : > "$root/release/releases/RELEASE_DIGEST.md"
      ;;
  esac
}

# build_instance_corpus <instance-root>
#   Seeds the four corpus artifacts under BOTH candidate instance layouts:
#     <instance>/releases/...          the live platform convention
#                                      (produce-learnings-register.sh composes
#                                       $(pmo_instance_path)/releases/registers/)
#     <instance>/release/releases/...  the repo-mirroring layout
#   Seeding only one would make fixture A UNSATISFIABLE for an adapter that chose
#   the other — the gate would look armed while being structurally unable to arm.
build_instance_corpus() {
  local inst="$1" sub
  for sub in "releases" "release/releases"; do
    mkdir -p "$inst/$sub/notes"
    : > "$inst/$sub/RELEASE_LOG.md"
    : > "$inst/$sub/RELEASE_INDEX.md"
    : > "$inst/$sub/RELEASE_DIGEST.md"
  done
}

AB_REPO="$TMP/ab"          # shared by A and B: no in-tree corpus
INSTANCE="$TMP/instance"   # fixture A's instance root (exists)
ABSENT_INSTANCE="$TMP/no-such-instance"   # fixture B's instance root (never created)
C_REPO="$TMP/c"
D_REPO="$TMP/d"

build_repo "$AB_REPO" none
build_repo "$C_REPO" partial
build_repo "$D_REPO" full
build_instance_corpus "$INSTANCE"

# ─── Fixture preconditions ───────────────────────────────────────────────────
#
# A fixture can silently fail to be in the state you believe it is, and then
# every assertion downstream passes against nothing. Each precondition asserts
# the fixture BEFORE any verdict rule consumes it.

echo "Fixture preconditions"

# P8 first: a mis-anchored REPO_ROOT makes every other check meaningless.
if [[ -f "$CLOSEOUT" ]]; then
  pass "P8 REPO_ROOT anchor resolves the script under test"
else
  fail "P8 REPO_ROOT mis-anchored: script under test not found at $CLOSEOUT"
fi

if [[ ! -e "$AB_REPO/release/releases" ]]; then
  pass "P1 fixtures A/B have NO in-tree corpus (the post-adapter world)"
else
  fail "P1 fixtures A/B unexpectedly carry an in-tree corpus — A/B would measure the wrong thing"
fi

_p2_missing=""
for _sub in "releases" "release/releases"; do
  for _f in RELEASE_LOG.md RELEASE_INDEX.md RELEASE_DIGEST.md; do
    [[ -f "$INSTANCE/$_sub/$_f" ]] || _p2_missing="$_p2_missing $_sub/$_f"
  done
  [[ -d "$INSTANCE/$_sub/notes" ]] || _p2_missing="$_p2_missing $_sub/notes"
done
if [[ -z "$_p2_missing" ]]; then
  pass "P2 fixture A instance corpus seeded in BOTH candidate layouts (8 artifacts)"
else
  fail "P2 fixture A instance corpus incomplete —$_p2_missing"
fi

if [[ ! -e "$ABSENT_INSTANCE" ]]; then
  pass "P3 fixture B instance root genuinely does not exist"
else
  fail "P3 fixture B instance root exists — B is not testing absence"
fi

if [[ ! -e "$C_REPO/release/releases/RELEASE_LOG.md" ]] \
   && [[ -f "$C_REPO/release/releases/RELEASE_INDEX.md" ]] \
   && [[ -f "$C_REPO/release/releases/RELEASE_DIGEST.md" ]] \
   && [[ -d "$C_REPO/release/releases/notes" ]]; then
  pass "P4 fixture C carries exactly 3 of 4 corpus paths (RELEASE_LOG deliberately absent)"
else
  fail "P4 fixture C is not in the 3-of-4 broken state it must be in"
fi

if [[ -f "$D_REPO/release/releases/RELEASE_LOG.md" ]] \
   && [[ -f "$D_REPO/release/releases/RELEASE_INDEX.md" ]] \
   && [[ -f "$D_REPO/release/releases/RELEASE_DIGEST.md" ]] \
   && [[ -d "$D_REPO/release/releases/notes" ]]; then
  pass "P5 fixture D carries all four corpus paths (the in-tree baseline)"
else
  fail "P5 fixture D is missing a corpus path — the baseline would fail for the wrong reason"
fi

_p6_bad=""
for _r in "$AB_REPO" "$C_REPO" "$D_REPO"; do
  cmp -s "$CLOSEOUT" "$_r/release/tools/automated-closeout.sh" || _p6_bad="$_p6_bad $_r"
done
if [[ -z "$_p6_bad" ]]; then
  pass "P6 every fixture runs a byte-identical copy of the script under test"
else
  fail "P6 fixture script copy differs from the script under test —$_p6_bad"
fi

if [[ -f "$STANDARD" ]]; then
  pass "P7 the constraint standard is present at its canonical path"
else
  fail "P7 constraint standard not found at $STANDARD"
fi

echo

# ─── Fixture execution ───────────────────────────────────────────────────────
#
# run_fixture <label> <repo-root> <instance-path-or-empty> <capture-file>
# HOME and CLAUDE_WORKSPACE_ROOT are pinned to an empty dir so that every tier of
# pmo_instance_path()'s resolution cascade lands on absence unless this call
# explicitly provides an instance root. Without the pin, a future instance-aware
# resolver running on the operator's own machine would find the REAL instance and
# fixture B would stop testing absence — passing for the wrong reason.
run_fixture() {
  local label="$1" repo="$2" inst="$3" cap="$4" rc=0
  if [[ -n "$inst" ]]; then
    ( cd "$repo" \
      && HOME="$PINNED_HOME" CLAUDE_WORKSPACE_ROOT="$PINNED_HOME" PMO_INSTANCE_PATH="$inst" \
         bash release/tools/automated-closeout.sh --check-paths ) > "$cap" 2>&1
    rc=$?
  else
    ( cd "$repo" \
      && env -u PMO_INSTANCE_PATH HOME="$PINNED_HOME" CLAUDE_WORKSPACE_ROOT="$PINNED_HOME" \
         bash release/tools/automated-closeout.sh --check-paths ) > "$cap" 2>&1
    rc=$?
  fi
  echo "$rc"
}

CAP_A="$TMP/cap.a"; CAP_B="$TMP/cap.b"; CAP_C="$TMP/cap.c"; CAP_D="$TMP/cap.d"

a="$(run_fixture A "$AB_REPO" "$INSTANCE"        "$CAP_A")"
b="$(run_fixture B "$AB_REPO" "$ABSENT_INSTANCE" "$CAP_B")"
c="$(run_fixture C "$C_REPO"  ""                 "$CAP_C")"
d="$(run_fixture D "$D_REPO"  ""                 "$CAP_D")"

# CH-4's needle, assembled at runtime. A literal in this file would be an
# occurrence of the pattern in this file — harmless here because the grep target
# is a subprocess capture, but assembling it keeps the needle robust if this file
# is ever scanned for its own literals.
NA_NEEDLE='[N]'"/A"

B_HAS_NA=0
grep -qE "$NA_NEEDLE" "$CAP_B" && B_HAS_NA=1

echo "Fixture results"
echo "  FIXTURE A [CH-2]     exit=$a  (instance-homed corpus, instance PRESENT)"
echo "  FIXTURE B [CH-1/4]   exit=$b  (instance-homed corpus, instance ABSENT; N/A token: $B_HAS_NA)"
echo "  FIXTURE C [CH-3]     exit=$c  (repo-homed, RELEASE_LOG omitted)"
echo "  FIXTURE D [CH-3]     exit=$d  (repo-homed, all four present)"
echo

# ─── Verdict rules ───────────────────────────────────────────────────────────

echo "Verdict rules"

# R1 — the in-tree baseline. Gates today.
if [[ "$d" -eq 0 ]]; then
  pass "R1 in-tree baseline resolves (fixture D exit 0)"
else
  fail "R1 in-tree baseline REGRESSED — fixture D exit $d; --check-paths no longer resolves a complete in-tree corpus"
fi

# R2 — probe liveness. Gates today.
if [[ "$c" -ne 0 ]]; then
  pass "R2 probe is live (fixture C: a broken corpus path still fails)"
else
  fail "R2 probe is BLIND — fixture C exit 0 with RELEASE_LOG.md absent; --check-paths no longer detects a broken corpus path"
fi

# R6 — doc<->test binding. Gates today.
if [[ ! -f "$STANDARD" ]]; then
  fail "R6 doc<->test binding BROKEN — the constraint standard is absent: $STANDARD"
else
  # Non-vacuity floor FIRST. R6 is a loop over CLAIMED_IDS; an empty or truncated
  # list makes the loop body unreachable and turns R6 into a universal acceptor
  # that reports PASS having grepped for nothing. Assert the population before
  # trusting the result.
  _r6_count=0
  for _id in $CLAIMED_IDS; do _r6_count=$((_r6_count + 1)); done
  if [[ "$_r6_count" -lt 4 ]]; then
    fail "R6 claimed-id list is DEGENERATE — $_r6_count id(s), expected at least 4 (CH-1..CH-4). R6 would grade a PASS having asserted nothing."
  else
    _r6_missing=""
    for _id in $CLAIMED_IDS; do
      grep -q "\*\*${_id}\*\*" "$STANDARD" || _r6_missing="$_r6_missing $_id"
    done
    if [[ -z "$_r6_missing" ]]; then
      pass "R6 all $_r6_count claimed constraint ids ($CLAIMED_IDS) are present in the standard"
    else
      fail "R6 doc<->test binding BROKEN — constraint id(s) missing from the standard:$_r6_missing"
    fi
  fi
fi

# R3 / R4 / R5 — the self-arming tolerance rules.
if [[ "$a" -eq 0 && "$b" -ne 0 ]]; then
  fail "R3 SEAM LANDED, TOLERANCE VIOLATED (CH-1) — corpus-path resolution is now instance-aware (fixture A passes) but HARD-FAILS when the instance-corpus root is absent (fixture B exit $b). Per release/references/standards/corpus-home-adapter-constraints.md CH-1, instance-absence MUST record N/A and exit 0. As written, --check-paths reddens the required closeout-smoke gate on every PR from a fresh clone or CI runner."
elif [[ "$a" -ne 0 && "$b" -eq 0 ]]; then
  fail "R5 DEGENERATE RESOLVER (CH-2) — fixture B passes (absence tolerated) but fixture A fails (a PRESENT instance corpus does not resolve). A resolver that tolerates absence without resolving presence satisfies the letter of CH-1 while resolving nothing."
elif [[ "$a" -eq 0 && "$b" -eq 0 ]]; then
  if [[ "$B_HAS_NA" -eq 1 ]]; then
    pass "R3/R5 tolerance property holds — presence resolves, absence is tolerated"
    pass "R4 tolerance is explicit (CH-4) — fixture B emits a distinguishable N/A record"
  else
    fail "R4 TOLERANCE IS SILENT (CH-4) — fixture B exits 0 with an absent instance-corpus root but emits no distinguishable N/A record. An unresolved path that reads as OK defeats CH-3: a genuine resolution defect would be indistinguishable from a tolerated absence."
  fi
else
  pass "R3/R4/R5 dormant — no instance-aware resolution present (fixtures A and B both fail)"
fi

echo

# ─── Terminal verdict ────────────────────────────────────────────────────────

if [[ "$FAILURES" -gt 0 ]]; then
  echo "verdict: FAIL — $FAILURES failing check(s)" >&2
  echo "  See release/references/standards/corpus-home-adapter-constraints.md (CH-1..CH-4)." >&2
  exit 1
fi

if [[ "$a" -ne 0 && "$b" -ne 0 ]]; then
  echo "verdict: PENDING-SEAM"
  echo "  Corpus-path resolution is not instance-aware yet, so the CH-1/CH-4 tolerance"
  echo "  rules (R3/R4) are dormant. R1/R2/R5/R6 gated and passed. This suite cannot"
  echo "  redden a PR until the corpus-home seam lands — and it reddens the PR that"
  echo "  lands it non-conformantly, with no cutoff to set and no arming step to run."
  exit 0
fi

echo "verdict: PASS-SEAM-LANDED"
echo "  The corpus-home seam has landed CONFORMANTLY: a present instance corpus"
echo "  resolves, an absent one is tolerated with an explicit N/A record."
echo "  ACTION — retire the PENDING-SEAM branch of this suite. Replace it with a"
echo "  hard 'a != 0 || b != 0 -> FAIL' so the tolerance property gates"
echo "  unconditionally and cannot silently regress to the pre-seam state."
echo "  (See corpus-home-adapter-constraints.md §5 'Retirement condition'.)"
exit 0

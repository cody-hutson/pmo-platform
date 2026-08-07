#!/usr/bin/env bash
set -uo pipefail
# test_spoke_run_directory.sh — NC-NS-1, the negative control for spoke
# output-path namespacing (hub-spoke-bridge.md § Run-Directory Discipline).
#
# WHY THIS EXISTS
#   A spawned Stage-6 Engineering spoke once picked up a PRIOR spoke's leftover
#   stage-comment file from a shared temp parent and nearly posted it to the
#   wrong sub-task. The failure was a READ, not a write: the spoke read a path
#   it had never written. The prompt contract mandated a local temp file and
#   said nothing about where it goes, so the collision surface was a MANDATED
#   write with an unspecified target.
#
# WHAT THIS SUITE GRADES — and what it deliberately does NOT
#   An earlier draft of this control asserted that N parallel `mktemp -d` calls
#   return N distinct directories. That grades a POSIX guarantee, not this
#   design: it would still pass with the entire contract clause deleted from
#   the corpus. Every arm here is chosen so that removing the clause FAILS it.
#
#   Group A grades the CLAUSE and proves its own deletion-sensitivity by
#   re-running each assertion against a mutated copy of the doc with the
#   section excised — the mutated copy MUST fail every arm that the live copy
#   passes. That inversion is the instrument-validation arm; without it, Group A
#   would only be asserting that a file is non-empty.
#
#   Group B grades the BEHAVIOUR the clause prescribes, in both the serial
#   (re-run) and the concurrent case, and carries the arm the original design
#   was missing: a deliberately NON-CONFORMING reader that globs the shared
#   parent DOES find the prior run's leftover. That arm is what makes the
#   conforming arm's zero a real negative — it proves the leftover is reachable
#   when the read clause is violated, so conformance is what prevents the
#   collision, not the absence of a file to collide with.
#
# GROUPS
#   (A1-A6) CLAUSE ARMS — the run-directory section exists in the Spoke
#           Template, binds the WRITE side, binds the READ side, requires the
#           resolved path be echoed, the read-only GitHub-write bound no longer
#           reads as covering the filesystem, and the temp-file mandate names
#           the run directory.
#   (A-NEG) DELETION SENSITIVITY — the same six assertions against a copy with
#           the section removed must ALL fail. An arm that still passes there
#           is not grading the clause.
#   (B1-B5) BEHAVIOURAL ARMS — serial re-run isolation, the non-conforming
#           reader (sensitivity), concurrent distinctness with disjoint
#           contents, conforming-read specificity on a known-absent target, and
#           a read-mechanism sensitivity arm proving the zeros are real.
#
# Offline + deterministic: all fixtures under one mktemp dir. No network, no
# gh, no writes to any operator-instance path, no writes into the repo.
#
# Run:  bash release/tools/tests/test_spoke_run_directory.sh
# Exit: 0 = all assertions pass, 1 = one or more failed.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$HERE/../../.." && pwd -P)"
BRIDGE="$REPO_ROOT/release/references/how-to/hub-spoke-bridge.md"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0; FAILURES=()
ok()  { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  FAIL — %s\n' "$1"; }

echo "NC-NS-1 — spoke run-directory discipline"
echo

if [ ! -f "$BRIDGE" ]; then
  echo "  FAIL — cannot locate hub-spoke-bridge.md at $BRIDGE"
  exit 1
fi

# ---------------------------------------------------------------------------
# Extract the run-directory section from a given copy of the bridge doc.
# Prints the section body; prints nothing when the section is absent.
# ---------------------------------------------------------------------------
extract_section() {
  awk '
    /^## Run-Directory Discipline \(all spokes\)$/ { inside = 1; next }
    inside && /^## / { inside = 0 }
    inside { print }
  ' "$1"
}

# Six clause assertions, evaluated against an arbitrary copy of the doc.
# Emits one line per arm: "<arm-id> PASS" or "<arm-id> FAIL".
clause_arms() {
  local doc="$1" section
  section="$(extract_section "$doc")"

  # A1 — the section exists at all, inside the Spoke Template.
  if [ -n "$section" ]; then echo "A1 PASS"; else echo "A1 FAIL"; fi

  # A2 — it binds the WRITE side to the run directory.
  if printf '%s' "$section" | grep -qF 'inside `$SPOKE_OUT` and nowhere else'
  then echo "A2 PASS"; else echo "A2 FAIL"; fi

  # A3 — it binds the READ side. #3211 was a READ; a write-only clause lets
  #      the AC pass with the observed defect fully reachable.
  if printf '%s' "$section" | grep -qF 'Read** scratch input only from `$SPOKE_OUT`'
  then echo "A3 PASS"; else echo "A3 FAIL"; fi

  # A4 — it requires the resolved path be echoed into the durable artifact,
  #      which is the only compensating control the unenforceable read side has.
  if printf '%s' "$section" | grep -qF 'Echo the resolved `$SPOKE_OUT`'
  then echo "A4 PASS"; else echo "A4 FAIL"; fi

  # A5 — the read-only spoke's GitHub-write bound is scoped to GitHub, so it no
  #      longer reads as a claim about the filesystem surface as well.
  if grep -qF 'On the GitHub surface** you may WRITE in exactly one place' "$doc"
  then echo "A5 PASS"; else echo "A5 FAIL"; fi

  # A6 — the temp-file posting mandate, which is what CREATES the local write,
  #      names the path discipline that bounds it.
  if grep -qF 'That temp file goes in the spoke'\''s run directory' "$doc"
  then echo "A6 PASS"; else echo "A6 FAIL"; fi
}

# ---------------------------------------------------------------------------
echo "(A) Clause arms — the live corpus"
# ---------------------------------------------------------------------------
LIVE_RESULTS="$(clause_arms "$BRIDGE")"
for arm in A1 A2 A3 A4 A5 A6; do
  if printf '%s\n' "$LIVE_RESULTS" | grep -qx "$arm PASS"; then
    ok "$arm — clause assertion holds in hub-spoke-bridge.md"
  else
    bad "$arm — clause assertion does NOT hold in hub-spoke-bridge.md"
  fi
done
echo

# ---------------------------------------------------------------------------
echo "(A-NEG) Deletion sensitivity — the same arms against an excised copy"
# ---------------------------------------------------------------------------
# Build a mutated copy with the run-directory section (and the two pointer
# edits that depend on it) removed. Every arm above must FAIL here. An arm that
# survives the deletion is grading something other than the contract clause.
MUTATED="$WORK/bridge-clause-deleted.md"
awk '
  /^## Run-Directory Discipline \(all spokes\)$/ { skipping = 1; next }
  skipping && /^## / { skipping = 0 }
  skipping { next }
  { print }
' "$BRIDGE" \
  | sed -e 's/\*\*On the GitHub surface\*\* you may WRITE in exactly one place/You may WRITE in exactly one place/' \
        -e 's/\*\*That temp file goes in the spoke'\''s run directory\*\*.*$//' \
  > "$MUTATED"

if [ ! -s "$MUTATED" ]; then
  bad "A-NEG — mutated fixture is empty; the excision step is broken"
else
  MUT_RESULTS="$(clause_arms "$MUTATED")"
  SURVIVORS=0
  for arm in A1 A2 A3 A4 A5 A6; do
    if printf '%s\n' "$MUT_RESULTS" | grep -qx "$arm PASS"; then
      SURVIVORS=$((SURVIVORS+1))
      printf '         survivor: %s still passes with the clause deleted\n' "$arm"
    fi
  done
  if [ "$SURVIVORS" -eq 0 ]; then
    ok "A-NEG — all 6 clause arms fail when the section is excised (deletion-sensitive)"
  else
    bad "A-NEG — $SURVIVORS of 6 clause arms survive deletion; they do not grade the clause"
  fi
  # Instrument validation for the excision itself: the mutated copy must still
  # be a substantial document, or "everything failed" would be trivially true.
  MUT_LINES="$(wc -l < "$MUTATED" | tr -d ' ')"
  LIVE_LINES="$(wc -l < "$BRIDGE" | tr -d ' ')"
  if [ "$MUT_LINES" -gt $(( LIVE_LINES * 9 / 10 )) ]; then
    ok "A-NEG control — excised copy retains $MUT_LINES of $LIVE_LINES lines (targeted, not wholesale)"
  else
    bad "A-NEG control — excised copy dropped to $MUT_LINES of $LIVE_LINES lines; the mutation is too broad to attribute"
  fi
fi
echo

# ---------------------------------------------------------------------------
echo "(B) Behavioural arms — resolution, isolation, and the non-conforming read"
# ---------------------------------------------------------------------------
SCRATCH_BASE="$WORK/scratch"
mkdir -p "$SCRATCH_BASE"

# The resolution the clause prescribes, verbatim in shape.
resolve_spoke_out() {  # $1 = stage, $2 = sub-task number
  mktemp -d "${SCRATCH_BASE}/spoke-$1-$2-XXXXXX"
}

STAGE=6
SUBTASK=4804
SENTINEL_NAME="stage-comment.md"

# --- B1: serial re-run of the SAME stage + SAME sub-task ---
RUN1="$(resolve_spoke_out "$STAGE" "$SUBTASK")"
printf 'run-1 output body — must never reach run 2\n' > "$RUN1/$SENTINEL_NAME"
RUN2="$(resolve_spoke_out "$STAGE" "$SUBTASK")"

if [ "$RUN1" != "$RUN2" ]; then
  ok "B1 — a re-run of stage $STAGE / sub-task $SUBTASK resolves a DIFFERENT run directory"
else
  bad "B1 — the re-run resolved run 1's directory ($RUN1); the leftover is in scope"
fi

RUN2_COUNT="$(find "$RUN2" -type f | wc -l | tr -d ' ')"
if [ "$RUN2_COUNT" -eq 0 ]; then
  ok "B1b — run 2's directory is empty (0 files) at resolution"
else
  bad "B1b — run 2's directory already holds $RUN2_COUNT file(s)"
fi

# --- B2: SENSITIVITY. A non-conforming reader — one that globs the shared
#         parent instead of reading only $SPOKE_OUT — DOES reach run 1's file.
#         This is the #3211 shape reproduced on purpose. It must be NON-ZERO,
#         or B1/B4's zeros are a broken probe rather than a real negative.
NONCONFORMING_HITS="$(find "$SCRATCH_BASE" -path "*/spoke-${STAGE}-${SUBTASK}-*" \
                        -name "$SENTINEL_NAME" -type f | wc -l | tr -d ' ')"
if [ "$NONCONFORMING_HITS" -ge 1 ]; then
  ok "B2 sensitivity — a shared-parent glob DOES find $NONCONFORMING_HITS leftover(s); the hazard is reachable when the read clause is violated"
else
  bad "B2 sensitivity — the glob found 0 leftovers; the probe cannot observe the defect it exists to detect (BROKEN PROBE)"
fi

# --- B4: SPECIFICITY on a KNOWN-ABSENT target. The conforming read scope is
#         run 2's $SPOKE_OUT only. The sentinel is known to EXIST (B2 proved
#         it) and known to be ABSENT from this directory. Zero here is the arm's
#         pass condition precisely because the population is non-empty elsewhere.
CONFORMING_HITS="$(find "$RUN2" -name "$SENTINEL_NAME" -type f | wc -l | tr -d ' ')"
if [ "$CONFORMING_HITS" -eq 0 ]; then
  ok "B4 specificity — a read scoped to run 2's \$SPOKE_OUT finds 0 of the $NONCONFORMING_HITS existing leftover(s)"
else
  bad "B4 specificity — the conforming read reached $CONFORMING_HITS leftover(s)"
fi

# --- B5: SENSITIVITY for the read mechanism itself. Without this, B4's zero is
#         consistent with a reader that can never find anything.
printf 'own artifact\n' > "$RUN2/own-evidence.txt"
OWN_HITS="$(find "$RUN2" -name 'own-evidence.txt' -type f | wc -l | tr -d ' ')"
if [ "$OWN_HITS" -eq 1 ]; then
  ok "B5 sensitivity — the same reader DOES find run 2's own artifact (1); B4's zero is a real negative"
else
  bad "B5 sensitivity — the reader found $OWN_HITS of its own artifact; the instrument is broken"
fi

# --- B3: concurrent resolution for the same stage + sub-task ---
CONC_LIST="$WORK/concurrent-dirs.txt"
: > "$CONC_LIST"
N=6
i=0
while [ "$i" -lt "$N" ]; do
  ( d="$(resolve_spoke_out "$STAGE" "$SUBTASK")"; printf '%s\n' "$d" >> "$CONC_LIST" ) &
  i=$((i+1))
done
wait

CONC_TOTAL="$(wc -l < "$CONC_LIST" | tr -d ' ')"
CONC_DISTINCT="$(sort -u "$CONC_LIST" | wc -l | tr -d ' ')"
if [ "$CONC_TOTAL" -eq "$N" ] && [ "$CONC_DISTINCT" -eq "$N" ]; then
  ok "B3 — $N concurrent resolutions produced $CONC_DISTINCT distinct directories"
else
  bad "B3 — $CONC_TOTAL resolutions produced $CONC_DISTINCT distinct directories (expected $N/$N)"
fi

# Pairwise-disjoint contents: each concurrent run writes a same-named file;
# no run may observe another's. Denominator = the N directories just resolved.
while IFS= read -r d; do
  printf '%s\n' "$d" > "$d/$SENTINEL_NAME"
done < "$CONC_LIST"

CROSS=0
while IFS= read -r d; do
  body="$(cat "$d/$SENTINEL_NAME")"
  [ "$body" = "$d" ] || CROSS=$((CROSS+1))
done < "$CONC_LIST"
if [ "$CROSS" -eq 0 ]; then
  ok "B3b — 0 of $CONC_TOTAL concurrent runs read a sibling's same-named artifact"
else
  bad "B3b — $CROSS of $CONC_TOTAL concurrent runs read a sibling's artifact"
fi

echo
echo "-----------------------------------------------------------------"
printf 'NC-NS-1: %d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf '\nFailures:\n'
  for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
  exit 1
fi
exit 0

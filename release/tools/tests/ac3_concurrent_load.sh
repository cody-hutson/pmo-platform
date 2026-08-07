#!/usr/bin/env bash
set -uo pipefail
# ac3_concurrent_load.sh — AC-3 harness for #3818. Stage-7 executes this; it is NOT a
# committed CI gate and nothing in .github/ invokes it.
#
# WHAT IT GRADES, AND WHY IT IS NOT "10/10 GREEN"
# ----------------------------------------------
# #3818's defect is a suite that reports success while the assertion it exists to make
# did not run. So "the suite exited 0" is not the assertion — a run that SKIPPED the
# strong arm also exits 0 without STRICT. This harness grades the strong arm being
# OBSERVED TO HAVE RUN, per round, and carries two falsification arms proving it can
# tell the two apart.
#
# SIX conditions, all required:
#   1. load liveness asserted (a load arm that never spawned voids every result below)
#   2. exit-0            = 80/80
#   3. STRONG ARM OBSERVED = 8/8 on all 10 rounds   <-- the AC-3 assertion
#   4. runs with a SKIP  = 0/80
#   5. falsification A: golden removed WITH STRICT     -> RED, strong-arm marker absent
#   6. falsification B: golden removed WITHOUT STRICT   -> GREEN, strong-arm marker absent
#
# Condition 6 is the one that tests the actual defect: it proves the harness can
# distinguish a green run that SKIPPED from a green run that RAN. A red-path-only
# falsification arm does not test that.
#
# PROBE-LOCATION CONSTRAINT (found by making the mistake): the probe copies must live
# INSIDE the repo. blast-radius.sh / domain-blast-radius.sh resolve their scan root with
# `git rev-parse --show-toplevel` when invoked without --root, which the suite's dispatch
# group does. A probe copy outside the repo makes those tools exit 2, so the falsification
# arm goes red for the WRONG reason and passes vacuously. Hence the marker assertions
# below are on CONTENT, not on the exit code alone.
#
# Run: bash release/tools/tests/ac3_concurrent_load.sh

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
SUITE="$REPO/release/tools/tests/test_domain_blast_radius.sh"
ROUNDS=10; PAR=8                       # 10 rounds x 8 concurrent = 80 suite executions
NCPU="$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)"
STRONG_MARKER='F1: current output == committed pre-refactor golden'
SKIP_MARKER='  SKIP — '

out="$(mktemp -d)"
probes=()
cleanup() { local p; for p in "${probes[@]:-}"; do [ -n "$p" ] && rm -rf "$p"; done; }
trap cleanup EXIT

# Answers in a GLOBAL, deliberately — NOT by echoing into a command substitution.
# `p="$(mkprobe)"` would run the function in a SUBSHELL, so the `probes+=(...)` that
# registers the directory for cleanup would mutate the subshell's copy and vanish. The
# parent array would stay empty, the EXIT trap would delete nothing, and every run would
# leak two untracked directories into the repo. Calling convention: invoke bare, then
# read $MKPROBE_DIR.
MKPROBE_DIR=""
mkprobe() {
  MKPROBE_DIR="$(mktemp -d "$REPO/.ac3-probe-XXXXXX")"
  cp -R "$REPO/release/tools" "$MKPROBE_DIR/tools"
  probes+=("$MKPROBE_DIR")
}

echo "=== AC-3 concurrent-load harness (#3818) ==="
echo "repo: $REPO"
echo "plan: $ROUNDS rounds x $PAR concurrent = $((ROUNDS*PAR)) suite executions, under load"
echo

# ---- 1. Load generators: CPU saturation + git contention on the same object store.
#
# The git arm is RATE-LIMITED. To be clear about what this does and does not fix: it is
# NOT the fix for the hang — that was a bare `wait` blocking on these never-exiting
# generators, corrected at the execution loop below. The sleep is resource hygiene. An
# unbounded `while :; do git show …; done` forks as fast as the kernel allows, and four of
# them spend the machine's fork capacity on background noise rather than on the subject.
#
# Note also what this arm is now FOR. It was justified when F1's failure mode WAS git
# contention; after this card the suite makes zero history reads, so contending on git no
# longer targets the defect. It is retained as background I/O noise and as a "does the fix
# survive the original stressor" check — not as the load that matters. The CPU arm is.
pids=()
for _ in $(seq 1 $((NCPU * 2))); do ( while :; do :; done ) & pids+=("$!"); done
for _ in 1 2 3 4; do
  ( while :; do git -C "$REPO" show HEAD:release/tools/blast-radius.sh >/dev/null 2>&1; sleep 0.05; done ) &
  pids+=("$!")
done

# ---- 2. LIVENESS ASSERTION. A load arm that never spawned means the runs below were
# not loaded and prove nothing — the same defect class as a test that silently does not test.
live=0; for p in "${pids[@]}"; do kill -0 "$p" 2>/dev/null && live=$((live+1)); done
if [ "$live" -ne "${#pids[@]}" ]; then
  echo "HARNESS VOID: $live/${#pids[@]} load generators live — this is NOT a loaded run."
  kill "${pids[@]}" 2>/dev/null; exit 2
fi
echo "load: $live generators live on ${NCPU} cores"
# Detach the generators from job control AFTER the liveness assertion has used them.
# Killing 32 tracked background jobs makes the shell print a "Terminated" block for each,
# which buries the graded output under ~100 lines of noise — and this output is what the
# Stage-7 report quotes. Disowning suppresses the notice; the PIDs stay valid to kill.
disown "${pids[@]}" 2>/dev/null || true
echo

# ---- 3. Execute.
#
# `wait` MUST name this round's PIDs. A bare `wait` waits for ALL background jobs of this
# shell — which includes the 32 load generators, and those never exit. Round 1 completes,
# the bare `wait` then blocks forever on the generators, and the harness hangs with round 1
# done and no output. That is a hang, not slowness: measured, round 1's eight executions
# finish in about six seconds and a single suite run costs ~1.6s even under this load.
#
# A per-round watchdog bounds the round so a genuine stall is REPORTED rather than silent.
# It cannot be written with `kill -0` on the children: a finished-but-unreaped child is a
# zombie, `kill -0` still succeeds on it, and the poll would never observe zero — turning
# every healthy round into a false stall. So the bound is a killer subprocess, and the
# stall verdict is read from the round's completion artifacts.
ROUND_TIMEOUT="${AC3_ROUND_TIMEOUT:-300}"
for r in $(seq 1 $ROUNDS); do
  rpids=()
  for c in $(seq 1 $PAR); do
    ( BLAST_RADIUS_TESTS_STRICT=1 bash "$SUITE" > "$out/r${r}c${c}.log" 2>&1; echo $? > "$out/r${r}c${c}.rc" ) &
    rpids+=("$!")
  done
  start=$SECONDS
  ( sleep "$ROUND_TIMEOUT"; kill "${rpids[@]}" 2>/dev/null ) & wd=$!
  wait "${rpids[@]}" 2>/dev/null
  kill "$wd" 2>/dev/null; wait "$wd" 2>/dev/null
  done_n=0
  for c in $(seq 1 $PAR); do [ -f "$out/r${r}c${c}.rc" ] && done_n=$((done_n+1)); done
  if [ "$done_n" -ne "$PAR" ]; then
    echo "HARNESS STALLED: round $r produced $done_n/$PAR results within ${ROUND_TIMEOUT}s."
    echo "  A stalled round is neither a pass nor a fail — the run is VOID, and grading it"
    echo "  would report a partial denominator as a full one. Raise AC3_ROUND_TIMEOUT or"
    echo "  reduce the load-generator count, then re-run."
    kill "${pids[@]}" 2>/dev/null; exit 2
  fi
  printf 'round %s/%s complete (%ss)\n' "$r" "$ROUNDS" "$((SECONDS-start))"
done
kill "${pids[@]}" 2>/dev/null

# ---- 4. Grade PER ROUND. An 80-denominator aggregate can hide a round that skipped.
total=0; green=0; strong=0; skipped=0; allrounds_ok=1
for r in $(seq 1 $ROUNDS); do
  rs=0; rn=0
  for c in $(seq 1 $PAR); do
    rn=$((rn+1)); total=$((total+1))
    [ "$(cat "$out/r${r}c${c}.rc")" = "0" ]           && green=$((green+1))
    if grep -qF "$STRONG_MARKER" "$out/r${r}c${c}.log"; then rs=$((rs+1)); strong=$((strong+1)); fi
    grep -qF "$SKIP_MARKER" "$out/r${r}c${c}.log"     && skipped=$((skipped+1))
  done
  printf 'ROUND %-2s STRONG ARM OBSERVED: %s/%s\n' "$r" "$rs" "$rn"
  [ "$rs" -eq "$rn" ] || allrounds_ok=0
done
printf 'D-12 OBSERVATION: strong arm observed on %s of %s rounds (all executions)\n' \
  "$( [ "$allrounds_ok" = 1 ] && echo "$ROUNDS" || echo "<$ROUNDS" )" "$ROUNDS"
echo
echo "exit-0:            $green/$total"
echo "STRONG ARM RAN:    $strong/$total     <-- this is the AC-3 assertion"
echo "runs with a SKIP:  $skipped/$total    <-- must be 0"
echo

# ---- 5a. FALSIFICATION A — golden removed WITH STRICT must go RED with the strong arm absent.
mkprobe; pA="$MKPROBE_DIR"
rm -f "$pA/tools/tests/fixtures/blast-radius-f1/normalized-golden.json"
BLAST_RADIUS_TESTS_STRICT=1 bash "$pA/tools/tests/test_domain_blast_radius.sh" > "$pA/f.log" 2>&1; rcA=$?
if [ "$rcA" -eq 0 ]; then
  echo "HARNESS BLIND: golden removed under STRICT still exited 0."; exit 2
fi
if grep -qF "$STRONG_MARKER" "$pA/f.log"; then
  echo "HARNESS BLIND: strong-arm marker present with the golden REMOVED."; exit 2
fi
if ! grep -qF "$SKIP_MARKER" "$pA/f.log"; then
  echo "HARNESS BLIND: golden removed produced neither a SKIP nor the strong arm — the"
  echo "               red is red for some OTHER reason, so this arm proves nothing."; exit 2
fi
echo "falsification A OK — golden removed + STRICT => exit $rcA, SKIP emitted, strong-arm marker absent"

# ---- 5b. FALSIFICATION B — the arm the defect actually describes. Without STRICT the
# suite exits 0 with the strong arm absent. If the harness cannot tell THAT from a real
# green run, it cannot detect #3818's failure mode at all.
mkprobe; pB="$MKPROBE_DIR"
rm -f "$pB/tools/tests/fixtures/blast-radius-f1/normalized-golden.json"
bash "$pB/tools/tests/test_domain_blast_radius.sh" > "$pB/f.log" 2>&1; rcB=$?   # NO STRICT
if [ "$rcB" -ne 0 ]; then
  echo "HARNESS VOID: non-STRICT skip exited $rcB, not 0 — cannot test the green-skip case."
  echo "              (If the failures are in the dispatch group, the probe copy is"
  echo "               resolving outside the repo — see the probe-location note above.)"
  sed -n '/FAILURES:/,$p' "$pB/f.log" | head -6
  exit 2
fi
if grep -qF "$STRONG_MARKER" "$pB/f.log"; then
  echo "HARNESS BLIND: suite exited 0 with the golden REMOVED and still claims the strong arm ran."; exit 2
fi
echo "D-12 falsification B OK — exit 0 WITHOUT the strong-arm marker is observably distinguishable"

# ---- 5c. CONTROL on the falsification arms: the UNMODIFIED suite must emit the marker.
# A marker that never matches would make both arms above pass vacuously.
ctl="$(mktemp)"
bash "$SUITE" > "$ctl" 2>&1
if ! grep -qF "$STRONG_MARKER" "$ctl"; then
  echo "HARNESS VOID: the strong-arm marker does not match even an unmodified run —"
  echo "              every 'marker absent' result above is meaningless."; exit 2
fi
echo "control OK — the unmodified suite DOES emit the strong-arm marker (matcher is live)"
echo

# ---- 6. Verdict: all six conditions.
if [ "$green" -eq "$total" ] && [ "$strong" -eq "$total" ] && [ "$skipped" -eq 0 ] && [ "$allrounds_ok" = 1 ]; then
  echo "AC-3 PASS"; exit 0
else
  echo "AC-3 FAIL"; exit 1
fi

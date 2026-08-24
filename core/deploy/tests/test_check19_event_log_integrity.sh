#!/usr/bin/env bash
# test_check19_event_log_integrity.sh — deploy.sh Check 19 trichotomy + assertions (#4051).
#
# Check 19 asserts the append-only integrity invariant on the pipeline event log:
#   19a presence, split by OWNERSHIP CLASS into three distinct outcomes
#   19b row-count parity  (log data rows == write-log data lines)
#   19c header preserved  (the log's header row survives)
#
# Before #4051 all three of Check 19's path literals mis-resolved. c19_log is arm 1
# of a flat if/elif chain, so it short-circuited every run and 19b/19c had NEVER
# executed on any release — while the check emitted a warning that read as benign.
# These tests exist to make that failure mode non-recurrable.
#
# T1  positive control        — a valid fixture produces OK with real counts
# T2  19b catches parity drift          (issue AC #3)
# T3  19c catches a mangled header      (issue AC #4)
# T4  REGRESSION GUARD for #4051        — none of the three presence-failure
#     messages appears on a valid fixture, i.e. all three literals resolve
# T5  STANDING LITERAL ASSERTION        — the c19_schema literal, extracted from
#     deploy.sh itself, points at a file that exists. Fails the moment the schema
#     doc moves again. This is a 2-line unit test with no deploy run.
# T6  SKIP path              — an absent operator-instance log is a SKIP with NO
#     flag, not a drift claim (a fresh install and CI must not fail)
# T7  FAIL-LOUD path         — an unresolvable TRACKED schema is flagged as a
#     path-resolution failure, AND fires even while the instance log is also
#     absent, proving the schema arm is no longer nested behind the Class A arm
#
# T4, T5 and T7 are the tests that would have caught the original defect. T2/T3
# alone would have passed vacuously in exactly the way the check did — they never
# execute unless the paths resolve first. An assertion nested behind an
# unvalidated guard is not a test of the guard.
#
# SAFETY. The operator's live event log is NEVER written:
#   - EVALS_RESULTS_PATH redirects the event log + write-log into a mktemp -d
#     sandbox (possible only because #4051 routed Check 19 through the shared
#     pmo_evals_results_path() resolver).
#   - PMO_INSTANCE_PATH redirects the deploy warn-log JSONL into the same sandbox.
#   - GUARD 1 (pre-flight) refuses to run unless the resolver lands in the sandbox.
#   - GUARD 2 (post-flight) asserts THIS SUITE did not write the live log: no
#     fixture sentinel leaked into it, it was never truncated, its header is
#     untouched. Deliberately not a hash-equality check — concurrent spokes append
#     to that log legitimately, and a guard that fails at random gets ignored.
#   - T7 builds a symlink-farm repo root that omits ONLY the schema file, so the
#     real repo is never mutated to exercise the unresolvable-schema arm.
#
# Run from repo root:
#   bash core/deploy/tests/test_check19_event_log_integrity.sh           # full suite
#   bash core/deploy/tests/test_check19_event_log_integrity.sh --fast    # deploy-free arm
#
# RUNTIME: ~42 min for the FULL suite (measured 2026-08-23 at 8dc00db1). It drives
# 5 full `deploy.sh --check` invocations; one full run measured 505 s at that same
# anchor, roughly double the 4m38s this block previously recorded — so treat the
# figure as dated, not fixed, and re-measure before relying on it. Budget
# accordingly; the full suite is not a fast pre-commit test.
#
# IT DOES NOT HANG. It terminates, slowly, and emits nothing until each deploy run
# completes because check19_region() block-buffers a whole run through a sed range
# filter. A reader who kills it at "about 25 minutes, no output" has stopped it at
# roughly its own completion time and will read a slow suite as a hung one.
#
# WHAT CI REACHES: `--fast` only. The five deploy-driven arms (T1/T4, T2, T3, T6,
# T7) are DELIBERATELY UNREACHED in CI — at ~42 min they are not a per-pull-request
# budget on a workflow that has no paths: filter and therefore fires on every pull
# request in the repo. They stay operator-invocable and remain the default: a bare
# invocation still runs all seven arms. What CI does reach is T5 — the standing
# literal assertion that is the actual recurrence guard for the original defect —
# plus both sandbox guards, at sub-second cost and with no deploy run at all. The
# disposition is recorded HERE, at the tool, because runtime affinity is a property
# of the suite, not a coverage decision belonging in an exclusions roster.
#
# That cost was never the reason the standing guard sat outside CI, and it does not
# cover it: T5 runs no deploy at all (a grep plus a file test), and
# the sibling `append-pipeline-event.sh --self-test` measures under a second. The
# reason is SCOPE — #3702 owns CI self-test enforcement and requires the tool set be
# DISCOVERED, not hardcoded, so a step hardcoded here is one that issue would delete.
# That trade is now ACCEPTED rather than deferred: the deploy-free arm is wired as a
# discrete step alongside this workflow's existing hardcoded siblings, on the ground
# that an unrun guard protects nothing today and a discovery model can absorb one
# more enumerated step when it lands. What remains deferred is the COST question —
# the five deploy-driven arms — not the scope one.
# Per the Stage-5 design (R8), a standalone --check-event-log-integrity dispatch
# arm was deliberately DEFERRED — it would collide with the dispatch region
# another slice edits in this same release — so the region-scoped full run is the
# accepted trade-off. Exit codes of the deploy run are deliberately NOT asserted:
# the sandbox trips unrelated checks; only the Check-19 region is graded.

set -uo pipefail

# --- Mode selector ------------------------------------------------------------
# Bare invocation is UNCHANGED: the full suite, all seven arms. `--fast` selects
# the arm that drives no `deploy.sh --check` at all — Preflight, GUARD 1, T5 and
# GUARD 2 — which is what CI runs. The suite parsed no arguments before this, so
# the selector is purely additive; anything other than --fast/-h is a hard error
# rather than a silently-ignored word, because a typo'd selector that fell through
# to the full suite would put ~42 min on a pull request without saying so.
FAST=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --fast) FAST=1 ;;
    -h|--help)
      printf 'usage: %s [--fast]\n' "$(basename "$0")"
      printf '  (no args)  FULL suite — all seven arms, ~42 min (5 x deploy.sh --check)\n'
      printf '  --fast     deploy-free arm — GUARD 1, T5, GUARD 2; sub-second\n'
      exit 0
      ;;
    *)
      printf 'FATAL: unrecognized argument: %s\n' "$1" >&2
      printf 'usage: %s [--fast]\n' "$(basename "$0")" >&2
      exit 2
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
DEPLOY="${REPO_ROOT}/core/deploy/deploy.sh"
RESOLVER="${REPO_ROOT}/core/deploy/lib-instance-path.sh"
SCHEMA_REL="release/references/standards/pipeline-event-log-schema.md"

PASS=0
FAIL=0
SBX=""

cleanup() { [ -n "${SBX}" ] && [ -d "${SBX}" ] && rm -rf "${SBX}"; }
trap cleanup EXIT

report() {
  local name="$1" passed="$2" detail="${3:-}"
  if [ "${passed}" = "1" ]; then
    printf '  PASS: %s\n' "${name}"; PASS=$((PASS + 1))
  else
    printf '  FAIL: %s\n' "${name}"; [ -n "${detail}" ] && printf '        %s\n' "${detail}"
    FAIL=$((FAIL + 1))
  fi
}

# --- Arm bookkeeping ----------------------------------------------------------
# ARMS_RUN records which arms actually EXECUTED, so the terminal ARM REACH block
# can assert reachedness instead of inferring it from the PASS tally. It has to be
# recorded rather than inferred, because a selector that skips MORE than it should
# takes that arm's PASS lines away with it and leaves a smaller, wholly green count
# and a zero exit — which is precisely the "passes without ever reaching its
# subject" failure this suite exists to make non-recurrable, reproduced inside the
# suite's own mode selector.
ARMS_RUN=""
SKIPPED=0

mark_arm() { ARMS_RUN="${ARMS_RUN}$1 "; }

# slow_arm — the gate on each of the five arms that drive `deploy.sh --check`.
#   returns 0 -> run this arm (and record it as reached)
#   returns 1 -> skip it (--fast), announcing the skip in the log so an unreached
#                arm is visible in CI output rather than merely absent from it
slow_arm() {
  if [ "${FAST}" -eq 1 ]; then
    printf '\n%s: SKIPPED (--fast) — this arm drives deploy.sh --check\n' "$1"
    SKIPPED=$((SKIPPED + 1))
    return 1
  fi
  mark_arm "$1"
  return 0
}

sha_file() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

# Run deploy.sh --check and echo ONLY the Check 19 region. Output lines carry a
# "[HH:MM:SS] " timestamp prefix, so the range patterns are deliberately unanchored.
check19_region() {
  local root="${1:-${REPO_ROOT}}"
  # Invoked repo-relative (not via ${DEPLOY}) so the run is byte-for-byte the way
  # an operator invokes it, and so the T7 farm root exercises its OWN tree.
  ( cd "${root}" && bash core/deploy/deploy.sh --check 2>&1 ) \
    | sed -n '/Check 19: Pipeline-event-log integrity/,/Check 20:/p' | sed '$d'
}

# --- Preflight ---
for f in "${DEPLOY}" "${RESOLVER}" "${REPO_ROOT}/${SCHEMA_REL}"; do
  if [ ! -f "${f}" ]; then printf 'FAIL: required file missing: %s\n' "${f}"; exit 1; fi
done

SBX=$(mktemp -d -t check19.XXXXXX)
export PMO_INSTANCE_PATH="${SBX}/instance"
export EVALS_RESULTS_PATH="${SBX}/instance/evals/results"
mkdir -p "${EVALS_RESULTS_PATH}"

LOG="${EVALS_RESULTS_PATH}/pipeline-event-log.md"
WLOG="${EVALS_RESULTS_PATH}/pipeline-event-log-write.log"

# --- GUARD 1 (pre-flight): the resolver MUST land inside the sandbox ---
printf '\nGUARD 1: resolver lands in the sandbox\n'
mark_arm "GUARD1"
# shellcheck source=/dev/null
source "${RESOLVER}"
RESOLVED="$(pmo_evals_results_path)"
case "${RESOLVED}" in
  "${SBX}"/*) report "pmo_evals_results_path() resolves inside the sandbox" 1 ;;
  *)
    report "pmo_evals_results_path() resolves inside the sandbox" 0 "resolved=${RESOLVED}"
    printf '\nABORTING: resolver escaped the sandbox; refusing to run against the live log.\n'
    exit 1
    ;;
esac

# --- GUARD 2 (pre-flight half): baseline the LIVE log ---
#
# Deliberately NOT a sha256-equality assertion. The live event log is an
# append-only surface that CONCURRENT release spokes legitimately write while this
# suite runs, so hash equality fails at random on an active instance — and a guard
# that cries wolf gets ignored, which is the exact "warning that never clears"
# pathology #4051 is about. What matters is "THIS TEST did not write the live
# log", so the guard asserts that directly:
#   (a) no fixture row from this suite reached the live log, detected by a
#       sentinel that cannot occur in a real emission;
#   (b) the log was never truncated or rewritten (row count never DECREASES);
#   (c) the header row is untouched.
# A hash change satisfying all three is reported as a benign concurrent append,
# with the row delta, rather than as a failure.
#
# Subshell + unset: a `VAR= func` prefix would PERSIST past a function call in
# bash and would silently clear the sandbox redirect for the rest of the suite.
LIVE_DIR="$( unset EVALS_RESULTS_PATH PMO_INSTANCE_PATH; pmo_evals_results_path )"
LIVE_LOG="${LIVE_DIR}/pipeline-event-log.md"
LIVE_SHA_BEFORE=""; LIVE_ROWS_BEFORE=0; LIVE_HEADER_BEFORE=""
if [ -f "${LIVE_LOG}" ]; then
  LIVE_SHA_BEFORE="$(sha_file "${LIVE_LOG}")"
  LIVE_ROWS_BEFORE="$(grep -cE '^\| [0-9]{4}-' "${LIVE_LOG}" 2>/dev/null || echo 0)"
  LIVE_HEADER_BEFORE="$(grep -m1 '^| ts_iso |' "${LIVE_LOG}" 2>/dev/null || true)"
fi

# Stamped into every fixture payload. The `check19-selftest-` prefix cannot occur
# in a real emission, so grepping the live log for it detects fixture leakage
# exactly — with no false positive from a genuine spoke:#4051 event.
SENTINEL="check19-selftest-$$-$(date +%s)"

# --- Fixture builders ---
# The header row is copied VERBATIM out of the schema, never hand-typed, so a
# schema header change cannot silently desynchronize this fixture.
HEADER="$(grep -m1 '^| ts_iso |' "${REPO_ROOT}/${SCHEMA_REL}")"
if [ -z "${HEADER}" ]; then
  printf 'FAIL: could not extract the header row from %s\n' "${SCHEMA_REL}"; exit 1
fi

# One fixture data row. All-%s and args in format order, so the sentinel can never
# land on a numeric conversion. $1 = sequence digit, also used as the payload tag.
fixture_row() {
  printf '| 2026-07-27T00:00:0%sZ | v0.0 | stage-06 | decision | fixture | spoke:#4051 | fixture-subject | CHEAP | resolved | %s fixture:t%s |\n' \
    "$1" "${SENTINEL}" "$1"
}

seed_valid() {   # 3 data rows / 3 write-log lines / header intact
  {
    printf '# Pipeline Event Log\n\n'
    printf '%s\n' "${HEADER}"
    printf '|---|---|---|---|---|---|---|---|---|---|\n'
    fixture_row 1
    fixture_row 2
    fixture_row 3
  } > "${LOG}"
  {
    printf '# write-log fixture\n'
    printf '2026-07-27T00:00:01Z\tdeadbeef01\tspoke:#4051\tfixture:t1\n'
    printf '2026-07-27T00:00:02Z\tdeadbeef02\tspoke:#4051\tfixture:t2\n'
    printf '2026-07-27T00:00:03Z\tdeadbeef03\tspoke:#4051\tfixture:t3\n'
  } > "${WLOG}"
}

# ─────────────────────────────────────────────────────────────────────────────
# T1 + T4 — positive control AND the #4051 regression guard, from one run.
# ─────────────────────────────────────────────────────────────────────────────
if slow_arm "T1/T4"; then
  printf '\nT1/T4: positive control + #4051 regression guard (valid 3/3 fixture)\n'
  seed_valid
  R="$(check19_region)"

  if grep -q 'OK:.*log rows=3, write-log lines=3, header preserved' <<<"${R}"; then
    report "T1 19b+19c EXECUTE and report OK with real counts (rows=3, lines=3)" 1
  else
    report "T1 19b+19c EXECUTE and report OK with real counts (rows=3, lines=3)" 0 \
      "$(printf '%s' "${R}" | tr '\n' '|')"
  fi

  if grep -q 'pipeline-event-log-integrity' <<<"${R}"; then
    report "T1 no integrity finding on a valid fixture" 0 "$(printf '%s' "${R}" | tr '\n' '|')"
  else
    report "T1 no integrity finding on a valid fixture" 1
  fi

  # T4 — the three presence-failure messages must be ABSENT, proving all three
  # literals resolve. Any one of them reappearing means a literal regressed.
  t4_ok=1; t4_detail=""
  for msg in 'log file missing' 'write-log missing' 'schema doc missing'; do
    if grep -q "${msg}" <<<"${R}"; then t4_ok=0; t4_detail="${t4_detail}${msg}; "; fi
  done
  if [ "${t4_ok}" = "1" ]; then
    report "T4 all three path literals resolve (no presence-failure message)" 1
  else
    report "T4 all three path literals resolve (no presence-failure message)" 0 "found: ${t4_detail}"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# T2 — 19b catches a seeded parity break (issue AC #3)
# ─────────────────────────────────────────────────────────────────────────────
if slow_arm "T2"; then
  printf '\nT2: 19b catches a seeded parity break (AC #3)\n'
  seed_valid
  # Append a 4th data row to the LOG with no corresponding write-log line -> 4 / 3.
  printf '| 2026-07-27T00:00:04Z | v0.0 | stage-06 | decision | fixture | spoke:#4051 | hand-edit | CHEAP | resolved | %s fixture:bypass |\n' "${SENTINEL}" >> "${LOG}"
  R="$(check19_region)"

  if grep -q 'row-count parity drift' <<<"${R}"; then
    report "T2 19b flags row-count parity drift" 1
  else
    report "T2 19b flags row-count parity drift" 0 "$(printf '%s' "${R}" | tr '\n' '|')"
  fi
  if grep -q 'rows=4' <<<"${R}" && grep -q 'lines=3' <<<"${R}"; then
    report "T2 the finding names the real counts (rows=4, lines=3)" 1
  else
    report "T2 the finding names the real counts (rows=4, lines=3)" 0 "$(printf '%s' "${R}" | tr '\n' '|')"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# T3 — 19c catches a mangled header (issue AC #4)
# ─────────────────────────────────────────────────────────────────────────────
if slow_arm "T3"; then
  printf '\nT3: 19c catches a mangled header row (AC #4)\n'
  seed_valid
  # Rewrite the FIRST column header token: '| ts_iso |' -> '| timestamp |'.
  MANGLED="${HEADER/| ts_iso |/| timestamp |}"
  {
    printf '# Pipeline Event Log\n\n'
    printf '%s\n' "${MANGLED}"
    printf '|---|---|---|---|---|---|---|---|---|---|\n'
    fixture_row 1
    fixture_row 2
    fixture_row 3
  } > "${LOG}"
  R="$(check19_region)"

  if grep -q 'header row missing or malformed' <<<"${R}"; then
    report "T3 19c flags the mangled header row" 1
  else
    report "T3 19c flags the mangled header row" 0 "$(printf '%s' "${R}" | tr '\n' '|')"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# T5 — standing literal assertion (no deploy run; drift-proofing).
# ALWAYS RUNS, in both modes: this is the arm `--fast` exists to preserve. It is
# the standing recurrence guard for the original defect and it costs one grep plus
# one file test, so no cost argument ever justifies skipping it.
# ─────────────────────────────────────────────────────────────────────────────
printf '\nT5: standing assertion that the c19_schema literal resolves\n'
mark_arm "T5"
C19_SCHEMA_LITERAL="$(grep -m1 'local c19_schema=' "${DEPLOY}" | sed -e 's/.*local c19_schema="//' -e 's/".*//')"
if [ -n "${C19_SCHEMA_LITERAL}" ] && [ -f "${REPO_ROOT}/${C19_SCHEMA_LITERAL}" ]; then
  report "T5 c19_schema literal in deploy.sh points at an existing file" 1
else
  report "T5 c19_schema literal in deploy.sh points at an existing file" 0 \
    "literal='${C19_SCHEMA_LITERAL}' (resolved against ${REPO_ROOT})"
fi

# ─────────────────────────────────────────────────────────────────────────────
# T6 — SKIP path: an absent operator-instance log is NOT a drift claim
# ─────────────────────────────────────────────────────────────────────────────
if slow_arm "T6"; then
  printf '\nT6: absent instance log -> SKIP, no flag (fresh install / CI must not fail)\n'
  rm -f "${LOG}" "${WLOG}"
  R="$(check19_region)"

  if grep -q 'SKIP:.*no event log at' <<<"${R}"; then
    report "T6 absent event log emits SKIP naming the resolved path" 1
  else
    report "T6 absent event log emits SKIP naming the resolved path" 0 "$(printf '%s' "${R}" | tr '\n' '|')"
  fi
  if grep -q 'pipeline-event-log-integrity' <<<"${R}"; then
    report "T6 SKIP raises NO integrity finding" 0 "$(printf '%s' "${R}" | tr '\n' '|')"
  else
    report "T6 SKIP raises NO integrity finding" 1
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# T7 — FAIL-LOUD path: an unresolvable TRACKED schema is a broken control.
# Built as a symlink-farm repo root that omits ONLY the schema file, so the real
# repo is never mutated. The instance log is left absent on purpose: the schema
# finding MUST still fire, proving it is no longer nested behind the Class A arm
# (the pre-#4051 chain would have short-circuited and never evaluated it).
# ─────────────────────────────────────────────────────────────────────────────
if slow_arm "T7"; then
  printf '\nT7: unresolvable tracked schema -> fail-loud path-resolution failure\n'
  FARM="${SBX}/farm"
  mkdir -p "${FARM}"
  for e in "${REPO_ROOT}"/* "${REPO_ROOT}"/.[!.]*; do
    [ -e "${e}" ] || continue
    ln -s "${e}" "${FARM}/$(basename "${e}")"
  done
  shallow_farm() {  # $1 real dir, $2 sandbox dir, $3 basename to omit ("" = omit nothing)
    rm -f "$2"; mkdir -p "$2"
    local e
    for e in "$1"/* "$1"/.[!.]*; do
      [ -e "${e}" ] || continue
      [ "$(basename "${e}")" = "$3" ] && continue
      ln -s "${e}" "$2/$(basename "${e}")"
    done
  }
  shallow_farm "${REPO_ROOT}/release"                      "${FARM}/release"                      ""
  shallow_farm "${REPO_ROOT}/release/references"           "${FARM}/release/references"           ""
  shallow_farm "${REPO_ROOT}/release/references/standards" "${FARM}/release/references/standards" "pipeline-event-log-schema.md"

  if [ -f "${FARM}/${SCHEMA_REL}" ]; then
    report "T7 fixture: schema absent from the farm root" 0 "still present"
  else
    report "T7 fixture: schema absent from the farm root" 1
  fi
  if [ -f "${REPO_ROOT}/${SCHEMA_REL}" ]; then
    report "T7 fixture: the REAL repo schema was never touched" 1
  else
    report "T7 fixture: the REAL repo schema was never touched" 0 "real schema missing!"
  fi

  R="$(check19_region "${FARM}")"
  if grep -q 'path-resolution failure' <<<"${R}"; then
    report "T7 unresolvable schema flags a PATH-RESOLUTION FAILURE" 1
  else
    report "T7 unresolvable schema flags a PATH-RESOLUTION FAILURE" 0 "$(printf '%s' "${R}" | tr '\n' '|')"
  fi
  if grep -q 'BROKEN CONTROL' <<<"${R}"; then
    report "T7 the finding names itself a broken control, not a missing artifact" 1
  else
    report "T7 the finding names itself a broken control, not a missing artifact" 0 "$(printf '%s' "${R}" | tr '\n' '|')"
  fi
  # The decisive non-nesting assertion: the schema finding AND the Class A SKIP
  # both appear in the same run. Under the pre-#4051 flat if/elif chain, arm 1
  # (absent log) fired and the schema arm was never evaluated.
  if grep -q 'path-resolution failure' <<<"${R}" \
     && grep -q 'SKIP:' <<<"${R}"; then
    report "T7 schema arm fires INDEPENDENTLY of the absent instance log (not nested)" 1
  else
    report "T7 schema arm fires INDEPENDENTLY of the absent instance log (not nested)" 0 \
      "$(printf '%s' "${R}" | tr '\n' '|')"
  fi
fi

# --- GUARD 2 (post-flight): this suite did not write the live log ---
printf '\nGUARD 2: the operator live event log was not written by this suite\n'
mark_arm "GUARD2"
if [ -n "${LIVE_SHA_BEFORE}" ]; then
  LIVE_SHA_AFTER="$(sha_file "${LIVE_LOG}")"
  LIVE_ROWS_AFTER="$(grep -cE '^\| [0-9]{4}-' "${LIVE_LOG}" 2>/dev/null || echo 0)"
  LIVE_HEADER_AFTER="$(grep -m1 '^| ts_iso |' "${LIVE_LOG}" 2>/dev/null || true)"

  # (a) THE decisive assertion: no fixture row from this suite reached the live log.
  if grep -q "check19-selftest-" "${LIVE_LOG}" 2>/dev/null; then
    report "no fixture row leaked into the live event log" 0 \
      "sentinel found in ${LIVE_LOG} — the sandbox redirect FAILED"
  else
    report "no fixture row leaked into the live event log" 1
  fi

  # (b) never truncated or rewritten.
  if [ "${LIVE_ROWS_AFTER}" -ge "${LIVE_ROWS_BEFORE}" ]; then
    report "live event log never truncated (rows ${LIVE_ROWS_BEFORE} -> ${LIVE_ROWS_AFTER})" 1
  else
    report "live event log never truncated" 0 \
      "row count DROPPED ${LIVE_ROWS_BEFORE} -> ${LIVE_ROWS_AFTER}"
  fi

  # (c) header untouched.
  if [ "${LIVE_HEADER_BEFORE}" = "${LIVE_HEADER_AFTER}" ]; then
    report "live event log header row untouched" 1
  else
    report "live event log header row untouched" 0 "header changed"
  fi

  # Informational only: a hash change with (a)-(c) intact is a concurrent spoke
  # appending its own events while this suite ran. That is normal on an active
  # instance and is NOT a failure — asserting hash equality here would make the
  # guard flaky and therefore ignorable.
  if [ "${LIVE_SHA_BEFORE}" != "${LIVE_SHA_AFTER}" ]; then
    printf '  NOTE: live log hash changed (+%d row(s)) — concurrent emission by another\n' \
      "$((LIVE_ROWS_AFTER - LIVE_ROWS_BEFORE))"
    printf '        spoke, not this suite; the leakage/truncation/header guards above hold.\n'
  fi
else
  report "live event log absent on this host — nothing to protect (vacuous PASS)" 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# ARM REACH — the selected mode reached the arms it declares.
#
# Without this the mode selector would be an UNFALSIFIABLE limb. A guard that
# skips MORE than it should takes that arm's PASS lines away with it, so the suite
# still prints an all-green tally and still exits 0; there is no count to compare
# against, because the count is itself a function of what ran. Follow the exit
# contract at the foot of this file to see it: a skipped arm makes no report()
# call, so PASS falls while FAIL stays at zero, and a contract that keys on FAIL
# alone therefore never fires. So the assertion is on REACHEDNESS, which a
# shrinking tally cannot fake. Under --fast it asserts the converse too, so a
# selector that quietly stopped skipping is caught as a failure rather than merely
# as a slow run.
#
# (Deliberately paraphrased rather than quoting that contract line: it must occur
# EXACTLY ONCE in this file. The CI falsification probe locates it by literal
# match to inject a failing assertion, and treats a non-unique match as a broken
# probe — so a second verbatim copy in a comment would disable the probe.)
# ─────────────────────────────────────────────────────────────────────────────
printf '\nARM REACH: the selected mode reached the arms it declares\n'
if [ "${FAST}" -eq 1 ]; then
  EXPECT_RUN="GUARD1 T5 GUARD2"
  EXPECT_SKIP="T1/T4 T2 T3 T6 T7"
else
  EXPECT_RUN="GUARD1 T1/T4 T2 T3 T5 T6 T7 GUARD2"
  EXPECT_SKIP=""
fi

reach_missing=""
for a in ${EXPECT_RUN}; do
  case " ${ARMS_RUN}" in
    *" ${a} "*) ;;
    *) reach_missing="${reach_missing}${a} " ;;
  esac
done
if [ -z "${reach_missing}" ]; then
  report "every arm this mode declares actually ran (${EXPECT_RUN})" 1
else
  report "every arm this mode declares actually ran" 0 \
    "never reached: ${reach_missing}| ran: ${ARMS_RUN}"
fi

# Rendered under --fast only. In full mode the skip set is empty, and an assertion
# quantified over an empty set is a vacuous PASS, not evidence.
if [ -n "${EXPECT_SKIP}" ]; then
  reach_extra=""
  for a in ${EXPECT_SKIP}; do
    case " ${ARMS_RUN}" in
      *" ${a} "*) reach_extra="${reach_extra}${a} " ;;
      *) ;;
    esac
  done
  if [ -z "${reach_extra}" ]; then
    report "no deploy-driven arm ran under --fast (${EXPECT_SKIP})" 1
  else
    report "no deploy-driven arm ran under --fast" 0 "unexpectedly ran: ${reach_extra}"
  fi
fi

printf '\n======================================================================\n'
printf 'test_check19_event_log_integrity.sh: %d passed, %d failed (bash %s)\n' \
  "${PASS}" "${FAIL}" "${BASH_VERSION:-unknown}"
if [ "${FAST}" -eq 1 ]; then
  printf '  --fast: %d deploy-driven arm(s) deliberately unreached: %s\n' \
    "${SKIPPED}" "${EXPECT_SKIP}"
fi
printf '======================================================================\n'

[ "${FAIL}" -ne 0 ] && exit 1
exit 0

#!/usr/bin/env bash
# test-status-label-invariant.sh — SUBJECT-EXECUTING efficacy test for deploy.sh
# Check 16 (status-label invariants I1/I2/I3/I4) under the #2682 widened scope.
# <!-- repo-integrity: allow-issue-ref -->  the #90NN tokens below are SYNTHETIC fixture issue numbers served by the in-test gh stub, not real repo issues.
#
# WHAT THIS TEST ASSERTS, AND WHY IT IS BUILT THIS WAY
# ---------------------------------------------------
# This suite EXECUTES `core/deploy/deploy.sh --check` and asserts against the real
# Check 16 emissions that run produces. It does NOT re-implement Check 16's jq
# filters. That distinction is the whole point of the test:
#
#   A mirror test — one that embeds its own copy of the predicate and asserts the
#   copy — passes unchanged when the subject it claims to cover is deleted. This
#   suite previously did exactly that: it carried four inline jq filters, executed
#   deploy.sh zero times, and reported "4 passed" with deploy.sh stubbed to a
#   no-op. CI green then read as coverage the suite did not provide.
#
# The falsifiability contract this suite holds itself to:
#   * Stub deploy.sh to a no-op  -> this suite FAILS (nothing to assert against).
#   * Break a Check 16 filter    -> this suite FAILS (emitted set stops matching).
#   * Leave deploy.sh intact     -> this suite PASSES.
# Arm B asserts the first of those IN-TEST, by running a no-op stub through the
# same harness and requiring the extraction to come back empty. The suite
# therefore demonstrates its own falsifiability rather than claiming it in a
# comment.
#
# WHY BOTH SEEDS ARE DELIBERATELY OFF-DEFAULT
# -------------------------------------------
# An assertion whose seed equals the value the subject already produces by default
# cannot fail, because the expected value arrives whether or not the subject ran.
# Both seeds here are chosen to differ from the shipped default:
#
#   * MODE seed = `enforce`. The shipped default is `warn` (absent a dedicated
#     status-label-invariant.mode file, resolve_check_mode falls back to the
#     shared mode, which defaults to warn). Asserting the `FAIL:` severity
#     therefore proves the dedicated mode file was read and honored; a subject
#     ignoring it would emit `WARN:` and this suite would fail.
#   * POPULATION seed = five violations across all four invariants. The live
#     orphaned-bundle population is 0, so a fixture asserting "0 violations"
#     would be satisfied by a subject that never ran at all.
#
# WHY THE ASSERTIONS ARE EXACT SETS RATHER THAN COUNTS
# ----------------------------------------------------
# Each invariant is asserted against the exact set of issue numbers it must flag.
# Exactness carries the specificity arm inside the sensitivity run: the fixture
# deliberately contains issues that must NOT be flagged — 9003 (type:epic) and
# 9004 (sub-task) are exempt from I2, and 9007 is in contract on all four. A
# filter that over-fires produces a superset and fails the comparison, so no
# separate clean-population run is needed to prove discrimination.
#
# HERMETIC BY CONSTRUCTION
# ------------------------
# No network and no repo mutation. Every input the subject reads is redirected
# into a tmpdir through env seams deploy.sh already honors:
#   PMO_AUDIT_REPO     — the repo Check 16 fetches (never contacted; gh is stubbed)
#   PMO_INSTANCE_PATH  — where resolve_check_mode() reads the mode file, and where
#                        the warn-log is written
#   PATH               — fronted with a canned `gh` serving the fixture
# The tmpdir is removed on exit; the live instance directory is never touched.
#
# COST NOTE (read before adding arms)
# -----------------------------------
# Check 16 has no standalone entry point — it is inline in cmd_check(), so the
# only way to execute the real filters is a full `deploy.sh --check`, which runs
# every check and takes minutes. Each additional arm that needs a different
# fixture or mode costs another full run. This suite therefore spends exactly ONE
# real subject run and derives its specificity from exact-set assertions within
# that run; the no-op arm is free because a no-op exits immediately.
#
# Runnable standalone: `bash core/deploy/tools/tests/test-status-label-invariant.sh`
# Exit 0 = all assertions pass; exit 1 = a mismatch (Check 16 would mis-fire).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# core/deploy/tools/tests -> repo root is four levels up.
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
DEPLOY_SH="${REPO_ROOT}/core/deploy/deploy.sh"

# jq fails CLOSED, matching core/deploy/tests/test_validate_install.sh's preflight.
# Every assertion below reads Check 16's emissions through jq, so without it this
# suite runs zero assertions — and the header two lines above declares "Exit 0 =
# all assertions pass". A skip that exits 0 makes that sentence also mean "no
# assertion ran", which is the vacuity this suite exists to rule out. CI's
# "Ensure jq" step guarantees the dependency before invoking the runner.
if ! command -v jq >/dev/null 2>&1; then
  echo "FAIL: jq is required — every assertion here reads Check 16's emissions through it"
  echo ""
  echo "status-label-invariant subject-execution suite: 0 passed, 1 failed"
  exit 1
fi
[[ -f "$DEPLOY_SH" ]] || { echo "FAIL: subject not found at ${DEPLOY_SH}"; exit 1; }

pass=0; fail=0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "${TMP}/bin" "${TMP}/instance"

# ── The gh stub ───────────────────────────────────────────────────────────────
# Serves $PMO_TEST_FIXTURE to the exact fetch shape Check 16 issues
# (`gh issue list --repo <r> --state open --limit 5000 --json number,labels,milestone`)
# and an empty array to every other gh call, so unrelated checks in the same
# --check run degrade quietly instead of reaching the network.
cat > "${TMP}/bin/gh" <<'GHSTUB'
#!/usr/bin/env bash
if [[ "${1:-}" == "issue" && "${2:-}" == "list" ]]; then
  case "$*" in
    *"--json number,labels,milestone"*)
      cat "$PMO_TEST_FIXTURE"
      exit 0 ;;
  esac
fi
echo "[]"
exit 0
GHSTUB
chmod +x "${TMP}/bin/gh"

# ── Fixture ───────────────────────────────────────────────────────────────────
# One issue per state the widened Check 16 must classify:
#   9001 bundled + no milestone            -> I4
#   9002 bug, zero status labels           -> I2
#   9003 type:epic, zero status labels     -> EXEMPT from I2 (load-bearing)
#   9004 sub-task, zero status labels      -> EXEMPT from I2 (load-bearing)
#   9005 proposed + bundled, no milestone  -> I1 (mutex) and I4
#   9006 proposed + milestone set          -> I3
#   9007 approved + milestone set          -> in contract on all four
cat > "${TMP}/fixture-violating.json" <<'JSON'
[
  { "number": 9001, "labels": [{"name":"improvement"},{"name":"status: bundled"}], "milestone": null },
  { "number": 9002, "labels": [{"name":"bug"}], "milestone": null },
  { "number": 9003, "labels": [{"name":"type:epic"}], "milestone": null },
  { "number": 9004, "labels": [{"name":"sub-task"}], "milestone": null },
  { "number": 9005, "labels": [{"name":"improvement"},{"name":"status: proposed"},{"name":"status: bundled"}], "milestone": null },
  { "number": 9006, "labels": [{"name":"improvement"},{"name":"status: proposed"}], "milestone": {"number": 42} },
  { "number": 9007, "labels": [{"name":"improvement"},{"name":"status: approved"}], "milestone": {"number": 42} }
]
JSON

# ── Subject execution ─────────────────────────────────────────────────────────
# run_subject <subject-path> <fixture-path> <mode> -> stdout+stderr of the run.
#
# Two mode files are written, and the pair is load-bearing:
#
#   deploy-check.mode           = off      (the shared cohort kill-switch)
#   status-label-invariant.mode = $_mode   (Check 16's dedicated dial)
#
# Check 16 is MODE DECOUPLED: resolve_check_mode() reads the check-specific file
# FIRST and only falls back to the shared mode when no dedicated file exists. So
# the dedicated `enforce` outranks the shared `off`, and Check 16 runs at the
# seeded mode while the mode-gated remainder of the cohort skips. This is the
# only lever available for bounding the run: Check 16 has no standalone entry
# point, so executing the real filters means running cmd_check(), and cmd_check()
# has no check-subset selector. Without the kill-switch a single run takes many
# minutes; with it, only the ungated checks plus Check 16 execute.
#
# If a future change removes Check 16's dedicated mode file support, the shared
# `off` would suppress Check 16 too — and this suite would fail loudly at the
# banner assertion rather than passing vacuously. That failure direction is
# deliberate.
run_subject() {
  local _subject="$1" _fixture="$2" _mode="$3"
  printf 'off\n' > "${TMP}/instance/deploy-check.mode"
  printf '%s\n' "$_mode" > "${TMP}/instance/status-label-invariant.mode"
  ( cd "$REPO_ROOT" && \
    PATH="${TMP}/bin:${PATH}" \
    PMO_TEST_FIXTURE="$_fixture" \
    PMO_INSTANCE_PATH="${TMP}/instance" \
    PMO_AUDIT_REPO="fixture/status-label-invariant" \
    bash "$_subject" --check --warn 2>&1 )
}

# emitted_for <invariant-id> <run-output> -> sorted CSV of flagged issue numbers.
# Parses the REAL emission shape produced by flag_status_label(), which reaches
# stdout through log() as:
#   "[HH:MM:SS+ZZZZ]   FAIL:  status-label-I4-contradiction-B — issue #9001 is ..."
emitted_for() {
  local _inv="$1" _out="$2"
  printf '%s\n' "$_out" \
    | sed -n "s/.*status-label-${_inv}-[a-zA-Z-]* — issue #\([0-9][0-9]*\).*/\1/p" \
    | sort -u | paste -sd, -
}

assert_set() {
  # assert_set <label> <actual-csv> <expected-space-list>
  local label="$1" actual="$2" expected
  expected=$(printf '%s' "$3" | tr ' ' '\n' | sed '/^$/d' | sort -u | paste -sd, -)
  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $label → [$actual]"
    pass=$((pass+1))
  else
    echo "  FAIL  $label → got [$actual] want [$expected]"
    fail=$((fail+1))
  fi
}

assert_contains() {
  local label="$1" haystack="$2" needle="$3"
  # Here-string, not `printf | grep -q`. `grep -q` stops reading at the first
  # match while the writer is still writing; under the `set -o pipefail` at the
  # head of this file the writer's broken-pipe status is promoted to the
  # pipeline's, so a SUCCESSFUL match reports failure once the residual after the
  # matched line exceeds the ~64 KiB pipe buffer. A here-string has no pipe and
  # no second process, so the reader's own status is the only status. Semantics
  # are identical to `printf '%s\n'`: `<<<` appends the same single newline, on
  # the empty-haystack arm too.
  if grep -qF -- "$needle" <<<"$haystack"; then
    echo "  PASS  $label"
    pass=$((pass+1))
  else
    echo "  FAIL  $label → expected output to contain: $needle"
    fail=$((fail+1))
  fi
}

# ── Arm A — the real subject, executed ────────────────────────────────────────
echo "── Arm A: deploy.sh Check 16 executed against a seeded violating population ──"
_t0=$(date +%s)
OUT_VIOLATING="$(run_subject "$DEPLOY_SH" "${TMP}/fixture-violating.json" enforce)"
echo "  [timing] Arm A subject run: $(( $(date +%s) - _t0 ))s"

# The banner is the proof the subject reached Check 16 at all. Its absence is the
# no-op-subject signature and is reported as such rather than as a set mismatch.
if grep -q 'Check 16:' <<<"$OUT_VIOLATING"; then
  echo "  PASS  subject reached Check 16 (banner emitted)"
  pass=$((pass+1))
else
  echo "  FAIL  subject never reached Check 16 — no banner in output."
  echo "        This is the no-op-subject signature: there is nothing to assert against."
  fail=$((fail+1))
fi

assert_set "I1 mutex (>1 status)"                         "$(emitted_for I1 "$OUT_VIOLATING")" "9005"
assert_set "I2 presence (0 status; epic+sub-task exempt)" "$(emitted_for I2 "$OUT_VIOLATING")" "9002"
assert_set "I3 proposed+milestone"                        "$(emitted_for I3 "$OUT_VIOLATING")" "9006"
assert_set "I4 bundled+no-milestone (orphaned bundle)"    "$(emitted_for I4 "$OUT_VIOLATING")" "9001 9005"

# The mode seed is off-default (`enforce` vs shipped `warn`). Asserting the FAIL:
# severity proves the dedicated mode file was actually read by the subject.
assert_contains "mode seed honored — emissions carry FAIL: severity, not WARN:" \
  "$OUT_VIOLATING" "FAIL:  status-label-I4-contradiction-B"

# ── Arm B — falsifiability, demonstrated rather than asserted ─────────────────
# A no-op stub through the IDENTICAL harness. If the extraction still returned the
# expected violators, the assertions above would be reading something other than
# the subject's output — i.e. the suite would be unfalsifiable. This arm is the
# in-test proof that Arm A's PASS is caused by deploy.sh actually running. It is
# free: a no-op subject exits immediately.
echo ""
echo "── Arm B: no-op subject through the same harness must yield nothing ─────────"
cat > "${TMP}/deploy-noop.sh" <<'NOOP'
#!/usr/bin/env bash
exit 0
NOOP
chmod +x "${TMP}/deploy-noop.sh"
OUT_NOOP="$(run_subject "${TMP}/deploy-noop.sh" "${TMP}/fixture-violating.json" enforce)"

assert_set "no-op subject emits no I1" "$(emitted_for I1 "$OUT_NOOP")" ""
assert_set "no-op subject emits no I2" "$(emitted_for I2 "$OUT_NOOP")" ""
assert_set "no-op subject emits no I3" "$(emitted_for I3 "$OUT_NOOP")" ""
assert_set "no-op subject emits no I4" "$(emitted_for I4 "$OUT_NOOP")" ""
if grep -q 'Check 16:' <<<"$OUT_NOOP"; then
  echo "  FAIL  no-op subject produced a Check 16 banner — the harness is not reading the subject"
  fail=$((fail+1))
else
  echo "  PASS  no-op subject produced no Check 16 banner → Arm A's PASS is subject-caused"
  pass=$((pass+1))
fi

echo ""
echo "status-label-invariant subject-execution suite: $pass passed, $fail failed"
[[ $fail -eq 0 ]] || exit 1

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
#   * Stub deploy.sh to a no-op        -> FAILS (nothing to assert against).
#   * Break a Check 16 filter          -> FAILS (emitted set stops matching).
#   * Re-drift the --report copy       -> FAILS (the parity comparison goes red).
#   * Leave deploy.sh intact           -> PASSES.
# Arms B and D assert the first and third of those IN-TEST rather than claiming
# them in a comment: B runs a no-op subject through the same harness and requires
# the extraction to come back empty; D runs a deliberately MUTATED subject —
# carrying the pre-#6165 inline report block verbatim — and requires the parity
# comparison to report DIVERGE. An Arm C that could not be made red by Arm D would
# be an unfalsified parity check, which is the same defect one layer up.
#
# ARM INVENTORY
# -------------
#   Arm 0  gh stub honours --label            prerequisite for C and D
#   Arm A  real subject, `--check`            the four invariant sets, per issue
#   Arm B  no-op subject, `--check`           A's PASS is subject-caused
#   Arm C  real subject, `--report`           check-surface vs report-surface parity
#   Arm D  mutated subject, `--report`        C is able to go red
#
# WHY A REPORT SURFACE IS TESTED AT ALL
# -------------------------------------
# deploy.sh has two Check 16 surfaces: cmd_check() (mode-gated, per-issue emit) and
# cmd_report() (unvarnished PASS/FAIL, consumed as Stage 13 evidence). They used to
# carry two independent encodings of the population and had silently drifted apart
# three ways. cmd_report GATES — it exits 1 on FAIL > 0 — so the drift was a
# false-green on a gating surface. #6165 replaced both copies with one shared
# population body; Arms C and D are what keep it one.
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
# Check 16's EMIT is inline in cmd_check(), so exercising the check end to end —
# emit shape, mode resolution, exit code — still costs a full `deploy.sh --check`,
# which runs every check and takes minutes. That is why this suite spends exactly
# ONE real subject run and derives its specificity from exact-set assertions
# within that run; the no-op arm is free because a no-op exits immediately.
#
# The FILTERS are no longer trapped in there. #6165 hoisted the shared body to top
# level as three directly-callable entry points — `_c16_population` (the fetch),
# `_c16_violators <invariant-id> <issues-json>` (the four filters plus the
# exemption predicate) and `_c16_exempt_pair <issue> <invariant-id>` — so a new arm
# that only needs to assert filter behaviour on a fixture can source deploy.sh and
# call `_c16_violators` directly, at no full-run cost. Reach for that first, and
# spend a full run only on an arm whose subject is genuinely the emit surface.
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
#
# SCOPE-AWARE BY CONSTRUCTION, AND THIS IS A PREREQUISITE RATHER THAN POLISH.
# The stub previously matched on the --json shape alone and never inspected
# --label, so it served the WHOLE fixture to both fetch shapes Check 16 has:
# cmd_check()'s unscoped fetch and cmd_report()'s (pre-fix) `--label improvement`
# fetch. Measured: the two call shapes returned byte-identical arrays. Any parity
# assertion between the check surface and the report surface built on a stub like
# that reads GREEN on the scope defect, because the narrowing it exists to detect
# is invisible to the stub — the unfalsifiable-assertion failure this suite's own
# header warns about, one layer up. Arm 0 below asserts the discrimination, so the
# prerequisite cannot silently regress.
cat > "${TMP}/bin/gh" <<'GHSTUB'
#!/usr/bin/env bash
if [[ "${1:-}" == "issue" && "${2:-}" == "list" ]]; then
  case "$*" in
    *"--json number,labels,milestone"*)
      # Honour `--label <name>` the way the real gh does: narrow the served
      # population to issues carrying that label. An unscoped call still gets the
      # whole fixture.
      _label=""
      _prev=""
      for _a in "$@"; do
        if [[ "$_prev" == "--label" ]]; then _label="$_a"; fi
        _prev="$_a"
      done
      if [[ -n "$_label" ]]; then
        jq --arg l "$_label" '[.[] | select((.labels | map(.name) | index($l)))]' "$PMO_TEST_FIXTURE"
      else
        cat "$PMO_TEST_FIXTURE"
      fi
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

# ── Arm 0 — stub discrimination (prerequisite for every parity arm below) ─────
# The parity arms compare the check surface's population against the report
# surface's. That comparison is only meaningful if the harness can REPRESENT a
# scope difference at all. A stub that ignores --label serves the same array to
# both call shapes, so a report path still carrying the pre-#2682
# `--label improvement` narrowing would look identical to a fixed one and the
# parity arm would pass on the primary defect. This arm asserts the stub
# discriminates, with both counts pinned: 7 members unscoped, 4 under
# `--label improvement` (9001/9005/9006/9007 carry it; 9002/9003/9004 do not).
echo "── Arm 0: gh stub honours --label (prerequisite for the parity arms) ────────"
_stub_unscoped=$(PMO_TEST_FIXTURE="${TMP}/fixture-violating.json" "${TMP}/bin/gh" \
  issue list --repo r --state open --limit 5000 --json number,labels,milestone | jq 'length')
_stub_scoped=$(PMO_TEST_FIXTURE="${TMP}/fixture-violating.json" "${TMP}/bin/gh" \
  issue list --repo r --state open --label improvement --limit 5000 --json number,labels,milestone | jq 'length')
if [[ "$_stub_unscoped" == "7" && "$_stub_scoped" == "4" ]]; then
  echo "  PASS  stub discriminates on --label → unscoped=7, improvement=4"
  pass=$((pass+1))
else
  echo "  FAIL  stub is scope-blind → got unscoped=[$_stub_unscoped] scoped=[$_stub_scoped], want 7 / 4"
  echo "        Every parity arm below is untestable until this passes: a scope-blind"
  echo "        stub cannot represent the very difference those arms exist to detect."
  fail=$((fail+1))
fi
echo ""

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

# ── Report-surface harness ────────────────────────────────────────────────────
# run_report_subject <subject-path> <fixture-path> -> stdout+stderr of `--report`.
# Same env seams as run_subject. No mode file matters here: cmd_report is
# unconditional by design — it is the "what would happen in enforce-mode" view.
# cmd_report exits 1 whenever it counts a failure, which a violating fixture
# guarantees; the status is deliberately not checked, only the output is read.
run_report_subject() {
  local _subject="$1" _fixture="$2"
  ( cd "$REPO_ROOT" && \
    PATH="${TMP}/bin:${PATH}" \
    PMO_TEST_FIXTURE="$_fixture" \
    PMO_INSTANCE_PATH="${TMP}/instance" \
    PMO_AUDIT_REPO="fixture/status-label-invariant" \
    bash "$_subject" --report 2>&1 )
}

# report_count_for <invariant-label> <report-output> -> the count, or MISSING.
# Parses the REAL emission shape produced by cmd_report's PASS/FAIL loop:
#   "[PASS] I1 mutex — 0 violations"   /   "[FAIL] I2 presence — 1 violation(s)"
# MISSING (rather than an empty string) so an absent row fails an assertion
# instead of quietly comparing equal to another empty string.
report_count_for() {
  local _label="$1" _out="$2" _v
  _v="$(sed -n "s/^\[[A-Z][A-Z]*\] ${_label} — \([0-9][0-9]*\) violation.*/\1/p" <<<"$_out")"
  if [[ -z "$_v" ]]; then printf 'MISSING\n'; else printf '%s\n' "$_v"; fi
}

# check_card <invariant-id> <check-output> -> cardinality of the emitted set.
# Derived from Arm A's ACTUAL emissions, never hardcoded — that is what makes the
# comparison below a parity assertion between two subject runs rather than two
# independent hardcoded expectations that could both be wrong together.
check_card() {
  local _csv
  _csv="$(emitted_for "$1" "$2")"
  if [[ -z "$_csv" ]]; then printf '0\n'; else awk -F, '{print NF}' <<<"$_csv"; fi
}

# struct_report_block <subject-path> -> "<fetches> <status-filters> <shared-calls>"
# inside cmd_report's Check 16 region. A surface with its own population has a
# non-zero fetch or filter count; a surface delegating to the shared body has
# zeroes and four _c16_violators calls.
struct_report_block() {
  python3 - "$1" <<'STRUCT'
import re, sys
s = open(sys.argv[1]).read()
i = s.index("# --- Status-Label Invariant (Check 16) ---")
j = s.index("# --- Aging Signal", i)
b = s[i:j]
print(len(re.findall(r"gh issue list", b)),
      len(re.findall(r"status: ", b)),
      len(re.findall(r"_c16_violators", b)))
STRUCT
}

# mutate_report_block <src> <dst> — reinstate the pre-#6165 inline report block
# VERBATIM, giving cmd_report its own drifted population again: `--label
# improvement` scope, no I2 type exemptions, no exemption-list consultation.
# python's .index raises if either anchor is gone, so a subject whose banners
# moved fails loudly here instead of silently producing an unmutated copy that
# would make Arm D pass for the wrong reason.
mutate_report_block() {
  local _src="$1" _dst="$2"
  cat > "${TMP}/prefix-block.txt" <<'PREFIXBLOCK'
  # --- Status-Label Invariant (Check 16) ---
  echo "--- Status-Label Invariant (Check 16) ---"
  local c14r_json
  c14r_json=$(gh issue list --repo "$AUDIT_REPO" --state open \
    --label improvement --limit 5000 --json number,labels,milestone 2>/dev/null || echo "[]")
  local c14r_i1 c14r_i2 c14r_i3 c14r_i4
  c14r_i1=$(printf '%s' "$c14r_json" | jq '[.[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) > 1)] | length')
  c14r_i2=$(printf '%s' "$c14r_json" | jq '[.[] | select((.labels | map(.name) | map(select(startswith("status: "))) | length) == 0)] | length')
  c14r_i3=$(printf '%s' "$c14r_json" | jq '[.[] | select(.milestone != null) | select((.labels | map(.name) | map(select(. == "status: proposed"))) | length > 0)] | length')
  c14r_i4=$(printf '%s' "$c14r_json" | jq '[.[] | select(.milestone == null) | select((.labels | map(.name) | map(select(. == "status: bundled"))) | length > 0)] | length')
  for entry in "I1 mutex:$c14r_i1" "I2 presence:$c14r_i2" "I3 contradiction-A:$c14r_i3" "I4 contradiction-B:$c14r_i4"; do
    local _name="${entry%%:*}"
    local _count="${entry##*:}"
    if [[ "$_count" -eq 0 ]]; then
      echo "[PASS] $_name — 0 violations"
      PASS=$((PASS + 1))
    else
      echo "[FAIL] $_name — $_count violation(s)"
      FAIL=$((FAIL + 1))
    fi
  done
  echo ""

PREFIXBLOCK
  python3 - "$_src" "$_dst" "${TMP}/prefix-block.txt" <<'MUT'
import sys
src, dst, blk = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(src).read()
i = s.index("  # --- Status-Label Invariant (Check 16) ---")
j = s.index("  # --- Aging Signal", i)
open(dst, "w").write(s[:i] + open(blk).read() + s[j:])
MUT
}

# ── Arm C — check surface vs report surface, one population ───────────────────
# deploy.sh's two Check 16 surfaces must evaluate the same population. Arm A
# already holds the check surface's four sets; this arm runs `--report` through
# the IDENTICAL stub and fixture and requires its four counts to equal those sets'
# cardinalities. Both sides come from real subject runs.
echo ""
echo "── Arm C: --report surface evaluates the same population as --check ─────────"
_t0=$(date +%s)
OUT_REPORT="$(run_report_subject "$DEPLOY_SH" "${TMP}/fixture-violating.json")"
echo "  [timing] Arm C report run: $(( $(date +%s) - _t0 ))s"

if grep -q 'Status-Label Invariant (Check 16)' <<<"$OUT_REPORT"; then
  echo "  PASS  report surface reached Check 16 (banner emitted)"
  pass=$((pass+1))
else
  echo "  FAIL  report surface never reached Check 16 — no banner in output."
  echo "        Under set -euo pipefail this is also the signature of an unreachable"
  echo "        shared body: cmd_report is dispatched directly by main(), so a"
  echo "        population helper nested inside cmd_check() is never registered here."
  fail=$((fail+1))
fi

for _pair in "I1:I1 mutex" "I2:I2 presence" "I3:I3 contradiction-A" "I4:I4 contradiction-B"; do
  _inv="${_pair%%:*}"
  _label="${_pair#*:}"
  _want="$(check_card "$_inv" "$OUT_VIOLATING")"
  _got="$(report_count_for "$_label" "$OUT_REPORT")"
  if [[ "$_got" == "$_want" ]]; then
    echo "  PASS  $_label parity → check set size $_want == report count $_got"
    pass=$((pass+1))
  else
    echo "  FAIL  $_label parity → check set size [$_want] but report count [$_got]"
    fail=$((fail+1))
  fi
done

# Per-defect assertions (issue AC-4). Each of the three divergences is named by its
# own assertion with its own counterfactual, never covered by the blanket parity
# rows above. All three land on I2, which is the invariant the shipped fixture was
# built to discriminate on.
#
#   (a) SCOPE. 9002 is a `bug` carrying no `improvement` label, so it is reachable
#       only from an UNSCOPED fetch. Under the pre-#2682 `--label improvement`
#       scope the report path cannot see it and I2 reads 0.
#   (b) TYPE EXEMPTION. 9003 (type:epic) and 9004 (sub-task) also carry zero status
#       labels. Without I2's two exemptions the report path counts them too and I2
#       reads 3 — which is the partial-fix hazard in miniature: closing (a) without
#       (b) is strictly WORSE than the bug, because it converts a silent under-count
#       into loud false FAILs.
#   (c) EXEMPTION LIST. Asserted structurally rather than behaviourally, and the
#       reason is recorded honestly: the exemption file resolves relative to the
#       repo root, and cmd_report's validate_workspace pins CWD there, so seeding
#       one would mean writing into the checkout — which this suite forbids by
#       construction. What IS assertable, and is sufficient, is that the report
#       surface has no population of its own and obtains its counts from the shared
#       body, which is the sole caller of the exemption predicate. Arm D is the
#       null control for exactly this claim.
_i2_report="$(report_count_for "I2 presence" "$OUT_REPORT")"
if [[ "$_i2_report" == "1" ]]; then
  echo "  PASS  AC-4(a) scope → report flags #9002 (a non-improvement bug); I2=1, not 0"
  pass=$((pass+1))
  echo "  PASS  AC-4(b) type exemption → report does NOT flag #9003/#9004; I2=1, not 3"
  pass=$((pass+1))
else
  echo "  FAIL  AC-4(a)/(b) → I2 report count [$_i2_report]; want 1"
  echo "        0 means the scope gap is back (9002 unreachable under --label improvement)."
  echo "        3 means the I2 type exemptions are missing (9003/9004 falsely counted)."
  fail=$((fail+2))
fi

read -r _f _s _v <<<"$(struct_report_block "$DEPLOY_SH")"
if [[ "$_f" == "0" && "$_s" == "0" && "$_v" == "4" ]]; then
  echo "  PASS  AC-4(c) + AC-2 structural → report block has 0 fetches, 0 filters, 4 shared-body calls"
  pass=$((pass+1))
else
  echo "  FAIL  AC-4(c) + AC-2 structural → got fetches=[$_f] filters=[$_s] shared-calls=[$_v], want 0 0 4"
  echo "        A non-zero fetch or filter count means the report surface has grown"
  echo "        its own population again — the #6165 defect, re-committed."
  fail=$((fail+1))
fi

if grep -q '_c16_exempt_pair' <<<"$(sed -n '/^_c16_violators() {/,/^}/p' "$DEPLOY_SH")"; then
  echo "  PASS  AC-4(c) → the shared body consults the operator exemption predicate"
  pass=$((pass+1))
else
  echo "  FAIL  AC-4(c) → _c16_violators does not call _c16_exempt_pair; the report"
  echo "        surface would once again never consult the exemption list"
  fail=$((fail+1))
fi

# ── Arm D — the parity assertion, shown able to fail ──────────────────────────
# A parity check nobody has seen go red is an unfalsified parity check. This arm
# reinstates the pre-#6165 inline report block on a COPY of the subject and
# requires Arm C's comparison to go DIVERGE against it. The copy lives beside
# copies of deploy.sh's sibling libs because deploy.sh sources them by
# BASH_SOURCE-relative path.
echo ""
echo "── Arm D: mutated subject (pre-#6165 inline report block) must go RED ───────"
mkdir -p "${TMP}/deploydir"
cp "${REPO_ROOT}"/core/deploy/*.sh "${TMP}/deploydir/"
if mutate_report_block "$DEPLOY_SH" "${TMP}/deploydir/deploy.sh"; then
  echo "  PASS  mutation applied (both region anchors resolved on the subject)"
  pass=$((pass+1))
else
  echo "  FAIL  mutation could not be applied — a region anchor moved. Arm D cannot"
  echo "        certify Arm C until the anchors are repaired; treat Arm C as"
  echo "        unfalsified rather than passing."
  fail=$((fail+1))
fi

read -r _mf _ms _mv <<<"$(struct_report_block "${TMP}/deploydir/deploy.sh")"
if [[ "$_mf" == "1" && "$_ms" == "4" && "$_mv" == "0" ]]; then
  echo "  PASS  mutant carries its own population again → fetches=1 filters=4 shared-calls=0"
  pass=$((pass+1))
else
  echo "  FAIL  mutant structure [$_mf $_ms $_mv], want 1 4 0 — the structural"
  echo "        instrument's null arm did not fire, so its zeroes on the real"
  echo "        subject are not a measurement"
  fail=$((fail+1))
fi

_t0=$(date +%s)
OUT_REPORT_MUT="$(run_report_subject "${TMP}/deploydir/deploy.sh" "${TMP}/fixture-violating.json")"
echo "  [timing] Arm D report run: $(( $(date +%s) - _t0 ))s"

_mut_verdict="AGREE"
for _pair in "I1:I1 mutex" "I2:I2 presence" "I3:I3 contradiction-A" "I4:I4 contradiction-B"; do
  _inv="${_pair%%:*}"
  _label="${_pair#*:}"
  _want="$(check_card "$_inv" "$OUT_VIOLATING")"
  _got="$(report_count_for "$_label" "$OUT_REPORT_MUT")"
  [[ "$_got" == "$_want" ]] || _mut_verdict="DIVERGE"
done

if [[ "$_mut_verdict" == "DIVERGE" ]]; then
  echo "  PASS  parity comparison goes RED against the mutant → Arm C is falsifiable"
  pass=$((pass+1))
else
  echo "  FAIL  parity comparison still AGREES against a subject carrying the known"
  echo "        pre-#6165 drift. Arm C cannot detect the defect it exists to detect;"
  echo "        report the parity assertion UNUSABLE, not the subject clean."
  fail=$((fail+1))
fi

# The specificity half: the mutant must diverge on I2 SPECIFICALLY, the invariant
# carrying all three defects. A mutant that diverged everywhere would suggest the
# harness broke rather than that the drift was detected.
_mut_i2="$(report_count_for "I2 presence" "$OUT_REPORT_MUT")"
_mut_i4="$(report_count_for "I4 contradiction-B" "$OUT_REPORT_MUT")"
if [[ "$_mut_i2" == "0" && "$_mut_i4" == "2" ]]; then
  echo "  PASS  mutant diverges on I2 only (I2=0 vs 1; I4 still 2) → drift detected, harness intact"
  pass=$((pass+1))
else
  echo "  FAIL  mutant I2=[$_mut_i2] I4=[$_mut_i4], want 0 and 2 — the divergence is not"
  echo "        the known pre-#6165 drift, so Arm D is not certifying what it claims"
  fail=$((fail+1))
fi

echo ""
echo "status-label-invariant subject-execution suite: $pass passed, $fail failed"
[[ $fail -eq 0 ]] || exit 1

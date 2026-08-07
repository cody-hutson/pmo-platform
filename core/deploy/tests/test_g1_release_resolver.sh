#!/usr/bin/env bash
# test_g1_release_resolver.sh — hermetic regression net for Check 22's
# release-identity resolver (`_c22_resolve_release` in core/deploy/deploy.sh).
#
# WHAT THIS EXISTS TO HOLD IN PLACE, and why reading the code is not enough.
#
#   1. THE MILESTONE READ IS PAGINATED. `gh api` does not auto-paginate and
#      GitHub's default page is 30 rows. The open-milestone population sits
#      within one row of that boundary, so an unpaginated validator classifies a
#      legitimate in-flight release as absent and emits a gating finding whose
#      stated reason is FALSE — and it starts doing so with no code change at
#      all, the moment one more milestone is opened. That failure is invisible
#      to any test that runs against a population smaller than a page, which is
#      exactly why the fixture below is 201 rows.
#
#   2. A DETECTED CANDIDATE NEVER BLOCKS. The resolver splits its token space by
#      PROVENANCE: an operator-asserted candidate that will not validate is
#      fail-closed, a branch-detected one degrades to advisory. Without that
#      split, three ordinary release-workflow states become gating findings.
#
#   3. `NONE` IS A DETERMINATE ANSWER, NOT A DEGRADED ONE. No release in flight
#      must resolve to NONE, never to a fail-closed verdict.
#
# METHOD. The resolver is EXTRACTED VERBATIM from the live deploy.sh between the
# C22-RESOLVER sentinels and executed, so what is measured is what ships rather
# than a re-implementation of it. `gh` is stubbed by a fake on PATH that honours
# the real API's pagination semantics — one page of `per_page` rows unless
# `--paginate` is passed — so the truncation defect is REPRODUCIBLE here rather
# than argued about. Every zero-valued assertion carries a control arm that must
# return non-zero, and the pagination arms are graded against a deliberately
# REGRESSED copy of the shipped resolver: a probe that cannot go red on the
# defect it names is not evidence.
#
# Hermetic: no network, no live tracker, no `gh`. Consumes no workflow input.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DEPLOY_SH="$SRC_ROOT/core/deploy/deploy.sh"

PASS_COUNT=0
FAIL_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "  PASS  $1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "  FAIL  $1"; }

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

echo "G1 release-identity resolver regression — deploy.sh Check 22 step 22-0"
echo "─────────────────────────────────────────────────────────────────────────"

# ── A. Extract the shipped resolver ─────────────────────────────────────────
build_runner() {
  # $1 = deploy.sh to extract from, $2 = output runner path
  local _src="$1" _out="$2" _b _e
  _b=$(/usr/bin/grep -n '>>> C22-RESOLVER-BEGIN' "$_src" | head -1 | cut -d: -f1)
  _e=$(/usr/bin/grep -n '>>> C22-RESOLVER-END' "$_src" | head -1 | cut -d: -f1)
  [[ -n "$_b" && -n "$_e" && "$_e" -gt "$_b" ]] || return 1
  {
    echo '#!/usr/bin/env bash'
    echo 'set -uo pipefail'
    /usr/bin/sed -n "$((_b + 1)),$((_e - 1))p" "$_src"
    echo '_c22_resolve_release'
  } > "$_out"
  return 0
}

RUNNER="$TMPD/resolver.sh"
if build_runner "$DEPLOY_SH" "$RUNNER"; then
  _rl=$(/usr/bin/grep -c '' "$RUNNER")
  if [[ "$_rl" -ge 40 ]]; then
    pass "A resolver extracted from deploy.sh between the C22-RESOLVER sentinels (${_rl} lines)"
  else
    fail "A extraction returned only ${_rl} lines — sentinels present but the region is implausibly small"
  fi
else
  fail "A could not extract the C22-RESOLVER region (missing or inverted sentinel markers)"
  echo "Result: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
  exit 1
fi

# The REGRESSED twin — the pre-fix form, with both pagination tokens removed.
# This is the state the shipped code must be distinguishable FROM. A probe that
# is green on both is a broken probe, not a pass.
REGRESSED="$TMPD/resolver_regressed.sh"
/usr/bin/sed -e 's/&per_page=100//' -e 's/ --paginate//' "$RUNNER" > "$REGRESSED"

# ── The `gh` stub — honours real pagination semantics ───────────────────────
# STUB_TOTAL rows exist. Without `--paginate`, exactly ONE page is returned,
# sized by `per_page` in the URL (default 30) — which is precisely what the real
# API does and precisely what the un-paginated form got wrong.
STUB_DIR="$TMPD/bin"
mkdir -p "$STUB_DIR"
STUB_LOG="$TMPD/gh-argv.log"
cat > "$STUB_DIR/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_ARGV_LOG"
url=""; paginate=0; jqprog=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    api) shift ;;
    --paginate) paginate=1; shift ;;
    --jq) jqprog="${2:-}"; shift 2 ;;
    *) [[ -z "$url" ]] && url="$1"; shift ;;
  esac
done
if [[ "${STUB_MODE:-ok}" == "fail" ]]; then
  echo "HTTP 401: Bad credentials (https://api.github.com/)" >&2
  exit 1
fi
total="${STUB_TOTAL:-201}"
[[ "${STUB_MODE:-ok}" == "empty" ]] && total=0
per=30
[[ "$url" == *per_page=100* ]] && per=100
if [[ "$paginate" -eq 1 ]]; then n="$total"; else n="$per"; fi
[[ "$n" -gt "$total" ]] && n="$total"
/usr/bin/python3 -c '
import json, sys
n = int(sys.argv[1])
rows = []
for i in range(n):
    rows.append({"state": "closed" if i == 199 else "open", "title": "ms-%03d" % i})
sys.stdout.write(json.dumps(rows))
' "$n" | jq -r "${jqprog:-.}"
STUB
chmod +x "$STUB_DIR/gh"

# ── A git fixture repo, so the branch rung is exercised for real ────────────
REPO="$TMPD/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q >/dev/null 2>&1
git -C "$REPO" -c user.name=t -c user.email=t@example.invalid \
  commit -q --allow-empty -m "fixture" >/dev/null 2>&1
# The branch arms below repoint HEAD at UNBORN refs (no commit needed to read a
# ref name), so the detach arm must target this SHA explicitly — detaching from
# an unborn branch is a no-op that leaves HEAD attached, and the arm would then
# pass or fail for the wrong reason.
REPO_SHA="$(git -C "$REPO" rev-parse HEAD 2>/dev/null)"
NON_GIT="$TMPD/notarepo"
mkdir -p "$NON_GIT"

# Drive the resolver. $1 = runner, $2 = candidate ("" = unset), $3 = src root.
run_resolver() {
  local _runner="$1" _cand="${2:-}" _root="${3:-$NON_GIT}"
  env PATH="$STUB_DIR:$PATH" \
      STUB_ARGV_LOG="$STUB_LOG" \
      STUB_MODE="${STUB_MODE:-ok}" \
      STUB_TOTAL="${STUB_TOTAL:-201}" \
      AUDIT_REPO="acme/widget" \
      _audit_src_root="$_root" \
      PMO_G1_ENFORCE_MILESTONE="$_cand" \
      bash "$_runner" 2>"$TMPD/run.err"
}
tok() { printf '%s' "$1" | awk '{print $1}'; }
reason() { printf '%s' "$1" | awk '{print $3}'; }
src() { printf '%s' "$1" | awk '{print $2}'; }

# NON-VACUITY. Every assertion below is unreadable if the runner never ran.
: > "$STUB_LOG"
V_SANITY="$(run_resolver "$RUNNER" "ms-010" "$NON_GIT")"
if [[ -n "$V_SANITY" ]] && [[ -s "$STUB_LOG" ]]; then
  pass "A runner executed and the gh stub was invoked (verdict: $(tok "$V_SANITY"))"
else
  fail "A non-vacuity: verdict '${V_SANITY}', stub log $( [[ -s "$STUB_LOG" ]] && echo present || echo EMPTY ) — every arm below would be vacuous: $(/usr/bin/head -1 "$TMPD/run.err" 2>/dev/null)"
  echo "Result: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
  exit 1
fi

# ── B. AC-G1 — BOTH pagination tokens are present, structurally and at runtime ─
resolver_code() { /usr/bin/grep -vE '^[[:space:]]*#' "$1"; }
_b_per=$(resolver_code "$RUNNER" | /usr/bin/grep -c 'per_page=100' || true)
_b_pag=$(resolver_code "$RUNNER" | /usr/bin/grep -c -- '--paginate' || true)
if [[ "$_b_per" -ge 1 && "$_b_pag" -ge 1 ]]; then
  pass "B AC-G1 the shipped milestone read carries per_page=100 (${_b_per}) AND --paginate (${_b_pag}) in LIVE CODE, not only in prose"
else
  fail "B AC-G1 shipped milestone read is missing a pagination token (per_page=100: ${_b_per}, --paginate: ${_b_pag})"
fi
_bc_per=$(resolver_code "$REGRESSED" | /usr/bin/grep -c 'per_page=100' || true)
_bc_pag=$(resolver_code "$REGRESSED" | /usr/bin/grep -c -- '--paginate' || true)
if [[ "$_bc_per" -eq 0 && "$_bc_pag" -eq 0 ]]; then
  pass "B CONTROL — the same probe reports 0/0 on the superseded un-paginated form, so it detects the absence it claims to detect"
else
  fail "B CONTROL — the probe still found tokens on the regressed form (per_page=100: ${_bc_per}, --paginate: ${_bc_pag}); it cannot discriminate"
fi
# Runtime arm — grep proves the text, the stub's own argv log proves the CALL.
if /usr/bin/grep -q 'per_page=100' "$STUB_LOG" && /usr/bin/grep -q -- '--paginate' "$STUB_LOG"; then
  pass "B AC-G1 RUNTIME — the argv gh actually received carries both tokens (read back from the stub, not from the source)"
else
  fail "B AC-G1 RUNTIME — the invocation gh received lacks a pagination token: $(/usr/bin/head -1 "$STUB_LOG")"
fi

# ── C. AC-G2 — truncated is distinguishable from absent ─────────────────────
# ms-150 exists and is open, but lives beyond the first page. This is the whole
# defect: under an un-paginated read it is indistinguishable from nonexistent.
V_PAGE2_LIVE="$(run_resolver "$RUNNER" "ms-150" "$NON_GIT")"
V_PAGE2_REG="$(run_resolver "$REGRESSED" "ms-150" "$NON_GIT")"
if [[ "$(tok "$V_PAGE2_LIVE")" == "RESOLVED" ]]; then
  pass "C AC-G2 a milestone beyond page 1 of a 201-row set resolves RESOLVED (${V_PAGE2_LIVE})"
else
  fail "C AC-G2 a legitimate milestone beyond page 1 did NOT resolve: ${V_PAGE2_LIVE}"
fi
if [[ "$(tok "$V_PAGE2_REG")" == "INVALID" ]]; then
  pass "C AC-G2 CONTROL — the same milestone on the un-paginated form returns INVALID, so the defect is real and this arm can go red"
else
  fail "C AC-G2 CONTROL — the regressed form did NOT misclassify the page-2 milestone (${V_PAGE2_REG}); the arm above proves nothing"
fi
# Non-vacuity of the regressed twin: it must still work on page 1, or arm C is
# measuring a runner that is simply broken rather than one that is truncating.
V_PAGE1_REG="$(run_resolver "$REGRESSED" "ms-010" "$NON_GIT")"
if [[ "$(tok "$V_PAGE1_REG")" == "RESOLVED" ]]; then
  pass "C CONTROL — the regressed form still resolves a page-1 milestone, so its page-2 failure is TRUNCATION and not a dead runner"
else
  fail "C CONTROL — the regressed form failed on a page-1 milestone too (${V_PAGE1_REG}); it is broken, so arm C is unreadable"
fi
# SPECIFICITY — a genuinely absent milestone must still be INVALID.
V_ABSENT="$(run_resolver "$RUNNER" "zzqqxx-not-a-milestone" "$NON_GIT")"
if [[ "$(tok "$V_ABSENT")" == "INVALID" && "$(reason "$V_ABSENT")" == "absent-from-milestone-set" ]]; then
  pass "C SPECIFICITY — a genuinely absent asserted milestone still returns INVALID/absent-from-milestone-set, so arm C is not a constant-RESOLVED function"
else
  fail "C SPECIFICITY — an absent milestone did not return INVALID/absent: ${V_ABSENT}"
fi

# ── D. closed and absent are DISTINCT reason tokens ─────────────────────────
V_CLOSED="$(run_resolver "$RUNNER" "ms-199" "$NON_GIT")"
if [[ "$(tok "$V_CLOSED")" == "INVALID" && "$(reason "$V_CLOSED")" == "closed-milestone" ]]; then
  pass "D a CLOSED milestone returns its own reason token (closed-milestone), not the absent one"
else
  fail "D a closed milestone did not produce a distinct reason token: ${V_CLOSED}"
fi
if [[ "$(reason "$V_CLOSED")" != "$(reason "$V_ABSENT")" ]]; then
  pass "D CONTROL — closed ($(reason "$V_CLOSED")) and absent ($(reason "$V_ABSENT")) are different strings; state=all is doing real work"
else
  fail "D CONTROL — closed and absent collapsed to the same token; the two states are indistinguishable again"
fi

# ── E. NONE is a determinate answer, and it never reaches the validator ─────
: > "$STUB_LOG"
V_NONE="$(run_resolver "$RUNNER" "" "$NON_GIT")"
if [[ "$(tok "$V_NONE")" == "NONE" ]]; then
  pass "E no assertion and no release branch resolves NONE (${V_NONE})"
else
  fail "E no-release-in-flight did not resolve NONE: ${V_NONE}"
fi
if [[ ! -s "$STUB_LOG" ]]; then
  pass "E SPECIFICITY — NONE short-circuits before the validator; gh was not called at all"
else
  fail "E NONE still called the validator: $(/usr/bin/head -1 "$STUB_LOG")"
fi

# ── F. The branch rung — form-total, and an unknown form never says INVALID ──
git -C "$REPO" symbolic-ref HEAD refs/heads/release/ms-010
V_FORM_A="$(run_resolver "$RUNNER" "" "$REPO")"
if [[ "$(tok "$V_FORM_A")" == "RESOLVED" && "$(src "$V_FORM_A")" == "branch" ]]; then
  pass "F form A (release/<slug>) resolves from the branch (${V_FORM_A})"
else
  fail "F form A did not resolve from the branch: ${V_FORM_A}"
fi
git -C "$REPO" symbolic-ref HEAD refs/heads/release/v9.9-ms-010
V_FORM_B="$(run_resolver "$RUNNER" "" "$REPO")"
if [[ "$(tok "$V_FORM_B")" == "RESOLVED" ]]; then
  pass "F form B (release/vX.Y-<slug>) resolves via the version-stripped candidate (${V_FORM_B})"
else
  fail "F form B did not resolve — the rung is not form-total: ${V_FORM_B}"
fi
git -C "$REPO" symbolic-ref HEAD refs/heads/release/zzqqxx-unknown-form
V_FORM_X="$(run_resolver "$RUNNER" "" "$REPO")"
if [[ "$(tok "$V_FORM_X")" == "UNRESOLVED" && "$(reason "$V_FORM_X")" == "form-unrecognized" ]]; then
  pass "F an unrecognized branch form returns UNRESOLVED/form-unrecognized — never INVALID, so branch-naming variance cannot become a gating finding"
else
  fail "F an unrecognized branch form did not degrade correctly: ${V_FORM_X}"
fi
if [[ "$(tok "$V_FORM_X")" != "$(tok "$V_ABSENT")" ]]; then
  pass "F CONTROL — the detected miss ($(tok "$V_FORM_X")) and the asserted miss ($(tok "$V_ABSENT")) return different tokens; provenance is load-bearing"
else
  fail "F CONTROL — detected and asserted misses collapsed to the same token; the provenance split is not implemented"
fi
git -C "$REPO" checkout -q --detach "$REPO_SHA" >/dev/null 2>&1
if git -C "$REPO" symbolic-ref -q HEAD >/dev/null 2>&1; then
  fail "F FIXTURE — the repo is still on an attached HEAD, so the detached arm below would be measuring the wrong state"
else
  pass "F FIXTURE — the repo is genuinely on a detached HEAD, so the arm below measures the state it names"
fi
V_DETACHED="$(run_resolver "$RUNNER" "" "$REPO")"
if [[ "$(tok "$V_DETACHED")" == "NONE" ]]; then
  pass "F detached HEAD — the state hub-spoke-bridge.md prescribes at session end — resolves NONE, never a blocker (${V_DETACHED})"
else
  fail "F detached HEAD did not resolve NONE: ${V_DETACHED}"
fi

# ── G. A degraded validator is UNRESOLVED, never INVALID ────────────────────
V_UNREACH="$(STUB_MODE=fail run_resolver "$RUNNER" "ms-010" "$NON_GIT")"
if [[ "$(tok "$V_UNREACH")" == "UNRESOLVED" && "$(reason "$V_UNREACH")" == "validator-unreachable" ]]; then
  pass "G an unreachable validator returns UNRESOLVED/validator-unreachable — a broken probe is never rendered as an absent milestone"
else
  fail "G an unreachable validator did not degrade correctly: ${V_UNREACH}"
fi
if printf '%s' "$V_UNREACH" | /usr/bin/grep -q 'Bad credentials'; then
  pass "G CONTROL — the validator's own diagnostic survives into the verdict (stderr captured, not discarded)"
else
  fail "G CONTROL — the diagnostic was swallowed; three different failures would read identically: ${V_UNREACH}"
fi
V_EMPTY="$(STUB_MODE=empty run_resolver "$RUNNER" "ms-010" "$NON_GIT")"
if [[ "$(tok "$V_EMPTY")" == "UNRESOLVED" && "$(reason "$V_EMPTY")" == "validator-empty-set" ]]; then
  pass "G a zero-row milestone read returns UNRESOLVED/validator-empty-set — an empty population is a broken probe, not evidence of absence"
else
  fail "G a zero-row read was not distinguished from absence: ${V_EMPTY}"
fi

# ── H. The denominator travels with the verdict ─────────────────────────────
_h_count=$(printf '%s' "$V_ABSENT" | awk '{print $4}')
if [[ "$_h_count" == "201" ]]; then
  pass "H the verdict carries the denominator it was measured against (${_h_count} milestones read), so a truncated read is legible at review time"
else
  fail "H the verdict's milestone count is '${_h_count}', expected 201 — the denominator is not travelling with the verdict"
fi
_h_reg=$(printf '%s' "$V_PAGE2_REG" | awk '{print $4}')
if [[ "$_h_reg" != "$_h_count" ]]; then
  pass "H CONTROL — the regressed form reports a different denominator (${_h_reg} vs ${_h_count}); the field is measured, not hardcoded"
else
  fail "H CONTROL — both forms report the same denominator (${_h_reg}); the count is not derived from the actual read"
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo "Result: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
if [[ "$FAIL_COUNT" -eq 0 ]]; then
  echo "G1 release-identity resolver regression: PASSED"
  exit 0
fi
echo "G1 release-identity resolver regression: FAILED"
exit 1

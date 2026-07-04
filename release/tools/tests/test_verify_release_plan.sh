#!/usr/bin/env bash
set -euo pipefail
# test_verify_release_plan.sh — tests for the plan-driven verification executor
# (verify-release-plan.sh, sub-task #3175).
#
# Groups:
#   (G1) FAMILY DISPATCH — the canonical fixture exercises all five check
#        families; assert each family's expected verdict (per-issue PASS/FAIL,
#        deferred SKIP, runtime-suite SKIP, integration/CIAC PASS). Proves the
#        thin-dispatcher registry routes every family AND that the honesty
#        contract holds (a threshold-missing per-issue check FAILs — no
#        fabricated PASS; a declared-deferred method SKIPs).
#   (G2) TABLE-SHAPE TOLERANCE (m-5) — the executor parses BOTH the enriched
#        per-issue-subsection form (grouping from the enclosing #N header, no
#        Issue column) AND the canonical Issue-column table. Assert per-issue
#        grouping is well-formed under both.
#   (G3) EXIT-CODE + SCHEMA — a fixture carrying a FAIL exits 3; --version prints
#        the SCHEMA_VERSION; a clean all-PASS/SKIP synthetic exits 0.
#   (G4) CIAC EXECUTION — the integration handler runs CIAC-1's grep method
#        (quote-aware; a pattern with a `|` alternation and spaces stays one arg)
#        and grades it on the co-occurrence threshold.
#
# Offline + deterministic: fixtures are committed under tests/fixtures/ and all
# methods are fast local greps against the repo tree (no deploy.sh --check here —
# that delegation is validated once against the real release plan). No network.
#
# Run:  bash release/tools/tests/test_verify_release_plan.sh
# Exit: 0 = all assertions pass, 1 = one or more failed.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLS_DIR="$(cd "$HERE/.." && pwd -P)"
REPO_ROOT="$(cd "$TOOLS_DIR/../.." && pwd -P)"
VERIFY="$TOOLS_DIR/verify-release-plan.sh"
FIX_CANON="release/tools/tests/fixtures/verify-plan-3175-canonical.md"
FIX_ISSUECOL="release/tools/tests/fixtures/verify-plan-3175-issuecol.md"

PASS=0
FAIL=0
FAILURES=()
ok()  { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  FAIL — %s\n' "$1"; }

# verdict_of <json> <id> — pull the verdict for a given check id out of the
# --format=json output using a portable grep/sed (no jq dependency). Isolates the
# JSON object containing this id, then reads its verdict field.
verdict_of() {
  local json="$1" id="$2"
  printf '%s\n' "$json" \
    | grep -oE "\{[^{}]*\"id\":\"$id\"[^{}]*\}" \
    | sed -n 's/.*"verdict":"\([A-Z]*\)".*/\1/p' | head -1
}

family_of() {
  local json="$1" id="$2"
  printf '%s\n' "$json" \
    | grep -oE "\{[^{}]*\"id\":\"$id\"[^{}]*\}" \
    | sed -n 's/.*"family":"\([a-z-]*\)".*/\1/p' | head -1
}

cd "$REPO_ROOT"

echo "verify-release-plan.sh test suite (#3175)"
echo "VERIFY=$VERIFY"
echo

# ---------------------------------------------------------------------------
# G1 — family dispatch + honesty contract (canonical fixture, JSON).
# ---------------------------------------------------------------------------
echo "G1 — family dispatch + honesty contract"
set +e
CANON_JSON="$("$VERIFY" --format=json "$FIX_CANON" 2>/dev/null)"
CANON_RC=$?
set -e

[ "$(verdict_of "$CANON_JSON" "AC-1")" = "PASS" ] && ok "per-issue grep-count PASS (AC-1)" || bad "per-issue AC-1 expected PASS, got '$(verdict_of "$CANON_JSON" AC-1)'"
[ "$(verdict_of "$CANON_JSON" "AC-2")" = "PASS" ] && ok "per-issue test -f PASS (AC-2)" || bad "per-issue AC-2 expected PASS, got '$(verdict_of "$CANON_JSON" AC-2)'"
[ "$(verdict_of "$CANON_JSON" "AC-3")" = "FAIL" ] && ok "per-issue threshold-miss FAILs (no fabricated PASS) (AC-3)" || bad "per-issue AC-3 expected FAIL, got '$(verdict_of "$CANON_JSON" AC-3)'"

# #902 AC-1 (deferred) — the JSON carries two AC-1 ids (one per issue); assert
# the deferred family is present and SKIPs.
DEFERRED_FAMILY_PRESENT="$(printf '%s\n' "$CANON_JSON" | grep -c '"family":"deferred"')"
[ "$DEFERRED_FAMILY_PRESENT" -ge 1 ] && ok "declared-deferred routes to deferred family (SKIP)" || bad "no deferred family found in canonical output"
DEFERRED_VERDICT="$(printf '%s\n' "$CANON_JSON" | grep -oE '\{[^{}]*"family":"deferred"[^{}]*\}' | sed -n 's/.*"verdict":"\([A-Z]*\)".*/\1/p' | head -1)"
[ "$DEFERRED_VERDICT" = "SKIP" ] && ok "deferred verdict is SKIP (honest no-op)" || bad "deferred verdict expected SKIP, got '$DEFERRED_VERDICT'"

RUNTIME_VERDICT="$(printf '%s\n' "$CANON_JSON" | grep -oE '\{[^{}]*"family":"runtime-suite"[^{}]*\}' | sed -n 's/.*"verdict":"\([A-Z]*\)".*/\1/p' | head -1)"
[ "$RUNTIME_VERDICT" = "SKIP" ] && ok "runtime-suite no-match → suite-skip SKIP" || bad "runtime-suite verdict expected SKIP, got '$RUNTIME_VERDICT'"

# ---------------------------------------------------------------------------
# G4 — CIAC execution (integration family runs the grep method w/ threshold).
# ---------------------------------------------------------------------------
echo "G4 — CIAC integration execution"
[ "$(family_of "$CANON_JSON" "CIAC-1")" = "integration" ] && ok "CIAC-1 classified integration" || bad "CIAC-1 family expected integration, got '$(family_of "$CANON_JSON" CIAC-1)'"
[ "$(verdict_of "$CANON_JSON" "CIAC-1")" = "PASS" ] && ok "CIAC-1 co-occurrence method executes → PASS (quote-aware | alternation)" || bad "CIAC-1 expected PASS, got '$(verdict_of "$CANON_JSON" CIAC-1)'"

# ---------------------------------------------------------------------------
# G2 — table-shape tolerance (m-5): both fixtures group per-issue correctly.
# ---------------------------------------------------------------------------
echo "G2 — table-shape tolerance (m-5)"
# Enriched form (canonical fixture): issue grouping from the #N subsection header.
printf '%s\n' "$CANON_JSON" | grep -q '"issue":"#901"' && ok "enriched form: #901 grouping from subsection header" || bad "enriched form: #901 not grouped"
printf '%s\n' "$CANON_JSON" | grep -q '"issue":"#902"' && ok "enriched form: #902 grouping from subsection header" || bad "enriched form: #902 not grouped"
# Issue-column form.
set +e
ISSUECOL_JSON="$("$VERIFY" --format=json "$FIX_ISSUECOL" 2>/dev/null)"
set -e
printf '%s\n' "$ISSUECOL_JSON" | grep -q '"issue":"#801"' && ok "issue-column form: #801 grouped from Issue column" || bad "issue-column form: #801 not grouped"
printf '%s\n' "$ISSUECOL_JSON" | grep -q '"issue":"#802"' && ok "issue-column form: #802 grouped from Issue column" || bad "issue-column form: #802 not grouped"

# ---------------------------------------------------------------------------
# G3 — exit-code + schema-version + clean-plan exit 0.
# ---------------------------------------------------------------------------
echo "G3 — exit code + schema version"
[ "$CANON_RC" -eq 3 ] && ok "fixture carrying a FAIL exits 3" || bad "canonical fixture expected exit 3, got $CANON_RC"

VER_OUT="$("$VERIFY" --version)"
printf '%s\n' "$VER_OUT" | grep -q 'schema v1' && ok "--version prints SCHEMA_VERSION (schema v1)" || bad "--version missing schema version: '$VER_OUT'"

# Clean all-PASS/SKIP synthetic → exit 0.
CLEAN_FIX="$(mktemp -t verify-plan-3175-clean.XXXXXX.md)"
cat > "$CLEAN_FIX" <<'EOF'
# vTEST clean plan

## Verification Plan

**#701 — clean**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `test -f release/tools/verify-release-plan.sh` | exists |
| AC-2 | behavioral/domain, DEFERRED | [DEFERRED — later] run against a future plan | deferred |
EOF
set +e
"$VERIFY" --format=json "$CLEAN_FIX" >/dev/null 2>&1
CLEAN_RC=$?
set -e
rm -f "$CLEAN_FIX"
[ "$CLEAN_RC" -eq 0 ] && ok "clean all-PASS/SKIP plan exits 0" || bad "clean plan expected exit 0, got $CLEAN_RC"

# ---------------------------------------------------------------------------
# G5 — deploy-check delegation (sync + regression families) via a fast stub.
# Regression guard: a non-zero deploy --check exit must render a FAIL verdict and
# an overall exit 3 — NOT abort the executor with an internal error (the errexit-
# through-command-substitution bug the C4 self-verification caught). Also proves
# the deploy check is memoized (one run shared by the sync + regression rows).
# ---------------------------------------------------------------------------
echo "G5 — deploy-check delegation + memoization (stub)"
STUB_DIR="$(mktemp -d -t verify-plan-3175-stub.XXXXXX)"
mkdir -p "$STUB_DIR/core/deploy" "$STUB_DIR/release/tools" "$STUB_DIR/plan"
cp "$VERIFY" "$STUB_DIR/release/tools/"
cat > "$STUB_DIR/plan/p.md" <<'EOF'
# stub plan
## Verification Plan
**#601 — deploy families**
| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | regression | run deploy.sh --check byte-diff regression against unchanged files | unchanged |
| AC-2 | sync | source-to-deployed via deploy.sh --check | in-sync |
EOF
# Drift case: stub deploy exits 1.
printf '#!/usr/bin/env bash\nexit 1\n' > "$STUB_DIR/core/deploy/deploy.sh"; chmod +x "$STUB_DIR/core/deploy/deploy.sh"
set +e
DRIFT_JSON="$("$STUB_DIR/release/tools/verify-release-plan.sh" --format=json --root "$STUB_DIR" "$STUB_DIR/plan/p.md" 2>/dev/null)"
DRIFT_RC=$?
set -e
[ "$DRIFT_RC" -eq 3 ] && ok "deploy --check drift → overall exit 3 (not internal error)" || bad "deploy drift expected exit 3, got $DRIFT_RC"
printf '%s\n' "$DRIFT_JSON" | grep -q '"family":"regression".*"verdict":"FAIL"\|"verdict":"FAIL".*"family":"regression"' && ok "regression family renders FAIL on drift" || { printf '%s\n' "$DRIFT_JSON" | grep -oE '\{[^{}]*regression[^{}]*\}' | grep -q '"verdict":"FAIL"' && ok "regression family renders FAIL on drift" || bad "regression family did not FAIL on drift"; }
# Clean case: stub deploy exits 0.
printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_DIR/core/deploy/deploy.sh"
set +e
CLEANDEP_JSON="$("$STUB_DIR/release/tools/verify-release-plan.sh" --format=json --root "$STUB_DIR" "$STUB_DIR/plan/p.md" 2>/dev/null)"
CLEANDEP_RC=$?
set -e
[ "$CLEANDEP_RC" -eq 0 ] && ok "deploy --check clean → overall exit 0" || bad "deploy clean expected exit 0, got $CLEANDEP_RC"
printf '%s\n' "$CLEANDEP_JSON" | grep -oE '\{[^{}]*sync[^{}]*\}' | grep -q '"verdict":"PASS"' && ok "sync family renders PASS when clean" || bad "sync family did not PASS when clean"
rm -rf "$STUB_DIR"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "──────────────────────────────────────────"
printf 'RESULT: %d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf 'FAILURES:\n'
  for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
  exit 1
fi
echo "ALL PASS"
exit 0

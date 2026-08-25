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
#   (G6) FCM DELIVERY — declared File-Change-Matrix ADDs vs the merged diff.
#        Eleven fixture arms covering the verdict lattice, ONE non-synthetic
#        historical replay against the release that motivated the family, and
#        EIGHT mutation arms. Group id is G6 because G5 is already taken by the
#        deploy-check delegation group below.
#
#        THE MUTATION ARMS ARE THE POINT. A fixture arm proves the code returns
#        the expected verdict; it does not prove the verdict is OBSERVED by
#        anything. Every mutation below deletes one observing step and asserts
#        that at least one arm changes its answer. An arm that survives every
#        mutation of the thing it claims to check is not a control — it is a
#        control-shaped assertion, and this release exists because ten of those
#        were found in one milestone.
#   (G7) PROVENANCE SURVIVAL — the `domain_practice` label across the Commit-0
#        transcription boundary. The P1–P12 ladder, plus five mutation arms.
#
#        P5a IS THE LOAD-BEARING CASE and the reason the family has an absolute
#        limb at all. On the v4.37 shape BOTH surfaces are empty, so the delta
#        limb PASSes — honestly, because nothing was lost — and a delta-only
#        mechanism therefore reports CLEAN on the one release that failed. P5a
#        asserts the delta PASS and the presence FAIL and the exit 3 together.
#        A check that cannot fail on the case that motivated it is not a check.
#
#        Every grammar arm is paired: P6 (five real non-conformant values, all
#        FAIL) is meaningless without P7 (Forms A/B/X, all PASS), because a
#        predicate that rejects everything satisfies P6 alone. Same for P9 and
#        its truncated-token control.
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
# Each stage reads a here-string rather than a pipe. `head -1` closes its input
# on the first line, and under `pipefail` every producer still upstream inherits
# the broken pipe — an intervening `sed` does not make that safe, it just puts
# one more process in the blast radius. A here-string has no writer to signal,
# so `head` is retained unchanged and only the writers are removed. All callers
# take these through command substitution, which strips the trailing newline, so
# the empty case is byte-identical to the previous form.
verdict_of() {
  local json="$1" id="$2" obj verdicts
  obj="$(grep -oE "\{[^{}]*\"id\":\"$id\"[^{}]*\}" <<<"$json" || true)"
  verdicts="$(sed -n 's/.*"verdict":"\([A-Z]*\)".*/\1/p' <<<"$obj")"
  head -1 <<<"$verdicts"
}

family_of() {
  local json="$1" id="$2" obj families
  obj="$(grep -oE "\{[^{}]*\"id\":\"$id\"[^{}]*\}" <<<"$json" || true)"
  families="$(sed -n 's/.*"family":"\([a-z-]*\)".*/\1/p' <<<"$obj")"
  head -1 <<<"$families"
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
# sigpipe-idiom: allow — `grep -o` (matches, not lines) with an intervening `sed -n`; `-m1` would cap grep's LINE count, not the extracted verdict list. Writer already converted to a here-string.
DEFERRED_VERDICT="$(grep -oE '\{[^{}]*"family":"deferred"[^{}]*\}' <<<"$CANON_JSON" | sed -n 's/.*"verdict":"\([A-Z]*\)".*/\1/p' | head -1)"
[ "$DEFERRED_VERDICT" = "SKIP" ] && ok "deferred verdict is SKIP (honest no-op)" || bad "deferred verdict expected SKIP, got '$DEFERRED_VERDICT'"

# sigpipe-idiom: allow — same `grep -o` + intervening `sed -n` shape as the deferred probe above.
RUNTIME_VERDICT="$(grep -oE '\{[^{}]*"family":"runtime-suite"[^{}]*\}' <<<"$CANON_JSON" | sed -n 's/.*"verdict":"\([A-Z]*\)".*/\1/p' | head -1)"
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
grep -q '"issue":"#901"' <<<"$CANON_JSON" && ok "enriched form: #901 grouping from subsection header" || bad "enriched form: #901 not grouped"
grep -q '"issue":"#902"' <<<"$CANON_JSON" && ok "enriched form: #902 grouping from subsection header" || bad "enriched form: #902 not grouped"
# Issue-column form.
set +e
ISSUECOL_JSON="$("$VERIFY" --format=json "$FIX_ISSUECOL" 2>/dev/null)"
set -e
grep -q '"issue":"#801"' <<<"$ISSUECOL_JSON" && ok "issue-column form: #801 grouped from Issue column" || bad "issue-column form: #801 not grouped"
grep -q '"issue":"#802"' <<<"$ISSUECOL_JSON" && ok "issue-column form: #802 grouped from Issue column" || bad "issue-column form: #802 not grouped"

# ---------------------------------------------------------------------------
# G3 — exit-code + schema-version + clean-plan exit 0.
# ---------------------------------------------------------------------------
echo "G3 — exit code + schema version"
[ "$CANON_RC" -eq 3 ] && ok "fixture carrying a FAIL exits 3" || bad "canonical fixture expected exit 3, got $CANON_RC"

# SCHEMA_VERSION 1 -> 2 with the fcm-delivery family. This assertion is pinned to the
# literal, so the bump cannot land silently — which is the whole point of the constant.
VER_OUT="$("$VERIFY" --version)"
grep -q 'schema v2' <<<"$VER_OUT" && ok "--version prints SCHEMA_VERSION (schema v2)" || bad "--version missing schema version: '$VER_OUT'"

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
DRIFT_REGRESSION_OBJ="$(grep -oE '\{[^{}]*regression[^{}]*\}' <<<"$DRIFT_JSON" || true)"
grep -q '"family":"regression".*"verdict":"FAIL"\|"verdict":"FAIL".*"family":"regression"' <<<"$DRIFT_JSON" && ok "regression family renders FAIL on drift" || { grep -q '"verdict":"FAIL"' <<<"$DRIFT_REGRESSION_OBJ" && ok "regression family renders FAIL on drift" || bad "regression family did not FAIL on drift"; }
# Clean case: stub deploy exits 0.
printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_DIR/core/deploy/deploy.sh"
set +e
CLEANDEP_JSON="$("$STUB_DIR/release/tools/verify-release-plan.sh" --format=json --root "$STUB_DIR" "$STUB_DIR/plan/p.md" 2>/dev/null)"
CLEANDEP_RC=$?
set -e
[ "$CLEANDEP_RC" -eq 0 ] && ok "deploy --check clean → overall exit 0" || bad "deploy clean expected exit 0, got $CLEANDEP_RC"
CLEANDEP_SYNC_OBJ="$(grep -oE '\{[^{}]*sync[^{}]*\}' <<<"$CLEANDEP_JSON" || true)"
grep -q '"verdict":"PASS"' <<<"$CLEANDEP_SYNC_OBJ" && ok "sync family renders PASS when clean" || bad "sync family did not PASS when clean"
rm -rf "$STUB_DIR"

# ---------------------------------------------------------------------------
# CIAC method parsing: span selection, comparators, and the SKIP/ERROR split
#
# WHY. This roll-up read 0 PASS / 3 SKIP / 1 ERROR on a release whose criteria
# were all substantively sound, and the causes were three parser defects rather
# than three unverifiable criteria:
#   (i)   extract_command took the LAST backtick span, so a method that mentions
#         a flag or a symbol in backticks yielded that as its "verb";
#   (ii)  a non-allowlisted verb rendered ERROR (malformed input) rather than an
#         honest SKIP (the executor declining to run a tool);
#   (iii) no comparator but ">=", so "expect zero" — the shape most verification
#         criteria actually take — was inexpressible and fell through to prose.
# Each arm below carries a control that must move the other way.
# ---------------------------------------------------------------------------
eval "$(sed -n '/^RUNNABLE_VERBS=/,/^}/p'      "$VERIFY")"
eval "$(sed -n '/^is_runnable_verb()/,/^}/p'   "$VERIFY")"
eval "$(sed -n '/^looks_like_command()/,/^}/p' "$VERIFY")"
eval "$(sed -n '/^extract_command()/,/^}/p'    "$VERIFY")"
eval "$(sed -n '/^extract_threshold()/,/^}/p'  "$VERIFY")"
eval "$(sed -n '/^compare_threshold()/,/^}/p'  "$VERIFY")"

M_FLAGFIRST='run `--self-test` (expect exit 0); then `grep -c -E "X" some/file.md` — expect exactly 3'
[ "$(extract_command "$M_FLAGFIRST" | awk '{print $1}')" = "grep" ] \
  && ok "extract_command skips a flag-shaped span and takes the first RUNNABLE one" \
  || bad "extract_command still takes the first span regardless of whether it is a command"
# CONTROL — a method whose ONLY span is a tool invocation must still surface that
# verb, not silently report "no runnable command"; otherwise the SKIP below would
# be indistinguishable from an unparseable method.
[ "$(extract_command 'run `python3 release/tools/x.py --self-test`' | awk '{print $1}')" = "python3" ] \
  && ok "extract_command CONTROL — a lone non-allowlisted command is still surfaced by verb" \
  || bad "extract_command control — a lone tool invocation was not surfaced"
is_runnable_verb grep && ! is_runnable_verb python3 \
  && ok "verb allowlist stays closed (grep in, python3 out)" \
  || bad "verb allowlist is not behaving as a closed set"
if looks_like_command "grep" && ! looks_like_command "--self-test" && ! looks_like_command "§Top"; then
  ok "looks_like_command rejects flags and prose, accepts a bare verb"
else
  bad "looks_like_command misclassifies a flag or a prose token"
fi

t_thr() { [ "$(extract_threshold "$1" | tr '\t' ' ')" = "$2" ]; }
if t_thr 'expect 0' '== 0' && t_thr 'expect exactly 3, one per writer' '== 3' \
   && t_thr '≥ 5 hits' '>= 5' && t_thr 'at least 2' '>= 2' \
   && t_thr 'at most 3' '<= 3' && t_thr 'expect zero findings' '== 0'; then
  ok "extract_threshold parses all four comparator shapes (== / >= / <=, incl. zero)"
else
  bad "extract_threshold does not parse the comparator set (BSD sed will not honour \\| in a BRE — use -E)"
fi
# CONTROL — a method with no threshold must yield nothing, or every rc-graded row
# would silently acquire a bogus count comparison.
[ -z "$(extract_threshold 'confirm the recorded no-overlap decision')" ] \
  && ok "extract_threshold CONTROL — a threshold-free method yields no comparator" \
  || bad "extract_threshold invented a comparator for a threshold-free method"
if [ "$(compare_threshold 0 '==' 0)" = PASS ] && [ "$(compare_threshold 1 '==' 0)" = FAIL ] \
   && [ "$(compare_threshold 3 '>=' 2)" = PASS ] && [ "$(compare_threshold 1 '>=' 2)" = FAIL ] \
   && [ "$(compare_threshold 1 '<=' 3)" = PASS ] && [ "$(compare_threshold 4 '<=' 3)" = FAIL ]; then
  ok "compare_threshold discriminates in BOTH directions on all three comparators"
else
  bad "compare_threshold does not discriminate on one or more comparators"
fi

# ---------------------------------------------------------------------------
# G6 — FCM DELIVERY (declared File Change Matrix ADDs vs the merged diff).
# ---------------------------------------------------------------------------
echo "G6 — fcm-delivery: declared ADDs vs the merged diff"

FIXD="release/tools/tests/fixtures"
DIFF_ABSENT="$REPO_ROOT/$FIXD/fcm-diff-absent.tsv"
DIFF_PRESENT="$REPO_ROOT/$FIXD/fcm-diff-present.tsv"

# fcm_run <tool> <fixture-basename> <diff-set> — sets FCM_JSON and FCM_RC in the
# CURRENT shell. It deliberately does NOT print the JSON for the caller to capture
# with `$(...)`: that runs the function in a subshell, where FCM_RC is assigned and
# then discarded, and every exit-code assertion silently grades a stale 0. Two arms
# were passing that way before this was caught.
FCM_JSON=""
FCM_RC=0
fcm_run() {
  local tool="$1" fx="$2" diff="$3"
  set +e
  FCM_JSON="$("$tool" --format=json --fcm-diff-file "$diff" "$REPO_ROOT/$FIXD/$fx" 2>/dev/null)"
  FCM_RC=$?
  set -e
}
observed_of() {
  local json="$1" id="$2" obj
  obj="$(grep -oE "\{[^{}]*\"id\":\"$id\"[^{}]*\}" <<<"$json" || true)"
  # sigpipe-idiom: allow — here-string writer, no upstream producer to signal.
  sed -n 's/.*"observed":"\([^"]*\)".*/\1/p' <<<"$obj" | head -1
}

# --- A1 / A2: the AC4 pair. Same declaration; the ONLY difference is delivery. ---
fcm_run "$VERIFY" fcm-declared-absent.md "$DIFF_ABSENT"; J_ABSENT="$FCM_JSON"; RC_ABSENT="$FCM_RC"
fcm_run "$VERIFY" fcm-conformant.md "$DIFF_PRESENT"; J_PRESENT="$FCM_JSON"

case "$(observed_of "$J_ABSENT" FCM-1)" in
  declared-add-not-delivered*) ok "A1 MUST-FLAG — a declared, undelivered ADD is caught" ;;
  *) bad "A1 expected declared-add-not-delivered, got '$(observed_of "$J_ABSENT" FCM-1)'" ;;
esac
[ "$(verdict_of "$J_ABSENT" FCM-1)" = FAIL ] && ok "A1 verdict is FAIL" || bad "A1 verdict expected FAIL, got '$(verdict_of "$J_ABSENT" FCM-1)'"
[ "$RC_ABSENT" -eq 3 ] && ok "A1 exits 3 (the FAIL reaches the exit predicate)" || bad "A1 expected exit 3, got $RC_ABSENT"
case "$(observed_of "$J_PRESENT" FCM-1)" in
  declared-add-delivered*) ok "A2 CONFORMANT CONTROL — the delivered ADD passes (probe is not stuck-on)" ;;
  *) bad "A2 expected declared-add-delivered, got '$(observed_of "$J_PRESENT" FCM-1)'" ;;
esac

# --- A3: AC2 — the Deviation-Log row is what converts FAIL to PASS. ---
fcm_run "$VERIFY" fcm-deviation-recorded.md "$DIFF_ABSENT"; J_DEV="$FCM_JSON"
case "$(observed_of "$J_DEV" FCM-1)" in
  deviation-recorded*) ok "A3 AC2 — an undelivered declared ADD PASSes only with a NOT DELIVERED row" ;;
  *) bad "A3 expected deviation-recorded, got '$(observed_of "$J_DEV" FCM-1)'" ;;
esac

# --- A4: AC3 — conditional rows are discriminated from unconditional ones. ---
fcm_run "$VERIFY" fcm-conditional.md "$DIFF_ABSENT"; J_COND="$FCM_JSON"; RC_COND="$FCM_RC"
case "$(observed_of "$J_COND" FCM-1)" in
  conditional-unrecorded*) ok "A4 AC3 — an unfired CONDITIONAL ADD is a named SKIP, not a FAIL" ;;
  *) bad "A4 expected conditional-unrecorded, got '$(observed_of "$J_COND" FCM-1)'" ;;
esac
[ "$RC_COND" -eq 0 ] && ok "A4 conditional SKIP does not red-line the run" || bad "A4 expected exit 0, got $RC_COND"
grep -q 'conditional=1' <<<"$(observed_of "$J_COND" FCM-COVERAGE)" \
  && ok "A4 the conditional count is VISIBLE in the coverage record (the exemption is priced)" \
  || bad "A4 coverage record does not carry conditional=1: '$(observed_of "$J_COND" FCM-COVERAGE)'"

# --- A5: fail-closed. An absent matrix is ERROR, never 'no ADDs, no violations'. ---
fcm_run "$VERIFY" fcm-no-matrix.md "$DIFF_ABSENT"; J_NOMX="$FCM_JSON"; RC_NOMX="$FCM_RC"
case "$(observed_of "$J_NOMX" FCM-COVERAGE)" in
  fcm-section-absent*) ok "A5 FAIL-CLOSED — an absent matrix is ERROR, not a silent zero" ;;
  *) bad "A5 expected fcm-section-absent, got '$(observed_of "$J_NOMX" FCM-COVERAGE)'" ;;
esac
[ "$RC_NOMX" -eq 3 ] && ok "A5 the fail-closed ERROR reaches the exit predicate" || bad "A5 expected exit 3, got $RC_NOMX"

# --- A6: marker-less rows are 'unknown', never 'edit' — and they are COUNTED. ---
fcm_run "$VERIFY" fcm-bare-paths.md "$DIFF_ABSENT"; J_BARE="$FCM_JSON"
case "$(observed_of "$J_BARE" FCM-COVERAGE)" in
  *fcm-rows-uninterpreted:3*) ok "A6 bare rows are reported as uninterpreted, with their count" ;;
  *) bad "A6 expected fcm-rows-uninterpreted:3, got '$(observed_of "$J_BARE" FCM-COVERAGE)'" ;;
esac
[ "$(verdict_of "$J_BARE" FCM-COVERAGE)" = SKIP ] \
  && ok "A6 partial row coverage is NON-PASS (silence must not read as zero)" \
  || bad "A6 expected coverage SKIP, got '$(verdict_of "$J_BARE" FCM-COVERAGE)'"

# --- A7: READ / non-scope rows are excluded from the obligation set. ---
fcm_run "$VERIFY" fcm-readonly-rows.md "$DIFF_PRESENT"; J_RO="$FCM_JSON"
case "$(observed_of "$J_RO" FCM-COVERAGE)" in
  *excluded=4*obligations=1*|*obligations=1*excluded=4*)
    ok "A7 READ + NOT EDITED/NOT TOUCHED rows are excluded, not asserted" ;;
  *) bad "A7 expected excluded=4 obligations=1, got '$(observed_of "$J_RO" FCM-COVERAGE)'" ;;
esac

# --- A8: the glob arm (FMF-3) + placeholder normalization. ---
fcm_run "$VERIFY" fcm-glob.md "$DIFF_PRESENT"; J_GLOB="$FCM_JSON"; RC_GLOB="$FCM_RC"
case "$(observed_of "$J_GLOB" FCM-1)" in
  declared-add-delivered*) ok "A8 GLOB ARM — an authored glob ADD resolves (18+ such tokens are authored)" ;;
  *) bad "A8 expected declared-add-delivered for the glob row, got '$(observed_of "$J_GLOB" FCM-1)'" ;;
esac
case "$(observed_of "$J_GLOB" FCM-2)" in
  declared-add-delivered*) ok "A8 PLACEHOLDER ARM — ADR-NNN-<slug>.md normalizes and resolves" ;;
  *) bad "A8 expected declared-add-delivered for the placeholder row, got '$(observed_of "$J_GLOB" FCM-2)'" ;;
esac
[ "$RC_GLOB" -eq 0 ] && ok "A8 a correctly-authored glob matrix does not red-line" || bad "A8 expected exit 0, got $RC_GLOB"

# --- A9: extraction fidelity — the row after an in-fence '#' comment is SEEN. ---
fcm_run "$VERIFY" fcm-truncating.md "$DIFF_PRESENT"; J_TRUNC="$FCM_JSON"
case "$(observed_of "$J_TRUNC" FCM-1)" in
  declared-add-delivered*) ok "A9 EXTRACTION FIDELITY — an ADD after an in-fence '#' comment is graded" ;;
  *) bad "A9 expected declared-add-delivered, got '$(observed_of "$J_TRUNC" FCM-1)'" ;;
esac

# --- A10: fixture-mode is REFUSED against a real release plan (no off-switch). ---
# This is v4.03's plan, at the ADR-092 claim-time home (a plan's identity is its
# VERSION, so it is filed under plans/v4/ by version). It previously carried the
# legacy milestone-slug name closeout-output-set-integrity_RELEASE_PLAN.md. Both the
# A11 replay below and its own prose speak of "the v4.03 merge", so the versioned
# name is also the one that agrees with what these arms actually assert.
REALPLAN="release/releases/plans/v4/v4.03_RELEASE_PLAN.md"
# PRECONDITION, and it is load-bearing rather than decorative. Every REALPLAN
# consumer below (A10, A11, M6) decides its verdict by reading the tool's OUTPUT, and
# a target the tool cannot open yields empty output plus EXIT_BAD_TARGET(2). A10 and
# A11 read that as a WRONG ANSWER, but M6 reads it as a clean PASS — M6's success
# condition is the ABSENCE of the refusal string, and nothing absent is more absent
# than a run that never happened. So a relocated or renamed plan silently converts one
# arm into a false green while reddening two others, and the red arms point at the
# family rather than at the missing file. Assert the target once, loudly, so this
# suite can never grade "the tool refused" and "the tool never ran" as the same
# observation.
if [ ! -f "$REPO_ROOT/$REALPLAN" ]; then
  bad "A10/A11/M6 PRECONDITION — REALPLAN target absent: $REALPLAN (relocated or renamed? the arms below cannot grade)"
fi
set +e
J_FIXLIVE="$("$VERIFY" --format=json --fcm-diff-file "$DIFF_PRESENT" "$REPO_ROOT/$REALPLAN" 2>/dev/null)"
RC_FIXLIVE=$?
set -e
case "$(observed_of "$J_FIXLIVE" FCM-COVERAGE)" in
  fcm-fixture-mode-on-live-plan*) ok "A10 the determinism seam is REFUSED on a real release plan" ;;
  *) bad "A10 expected fcm-fixture-mode-on-live-plan, got '$(observed_of "$J_FIXLIVE" FCM-COVERAGE)'" ;;
esac
[ "$RC_FIXLIVE" -eq 3 ] && ok "A10 the refusal is a hard ERROR, not an advisory stamp" || bad "A10 expected exit 3, got $RC_FIXLIVE"

# --- A11: NON-SYNTHETIC historical replay against the release that motivated this. ---
# v4.03 declared 5 ADDs; merge 2adf533e delivered 24 files with 5 A-status paths, none
# of them the declared ADR. The fifth declared ADD is a PLACEHOLDER path
# (release/ADRs/<self-arming-conditional-gate-posture>.md), so a literal `test -f`
# would have failed it even had the ADR shipped — the placeholder arm is what makes
# the verdict correct rather than accidentally right. Guarded for a shallow clone:
# an unreachable commit degrades to a stated skip, never a false pass.
if git -C "$REPO_ROOT" cat-file -e 2adf533e^{commit} 2>/dev/null; then
  set +e
  J_V403="$("$VERIFY" --format=json --merge-base '2adf533e^1' --head 2adf533e "$REPO_ROOT/$REALPLAN" 2>/dev/null)"
  RC_V403=$?
  set -e
  V403_MISS="$(grep -c '"observed":"declared-add-not-delivered' <<<"$J_V403" || true)"
  V403_HIT="$(grep -c '"observed":"declared-add-delivered' <<<"$J_V403" || true)"
  # Print the replay's own denominator. A control that reports only "ok" has not
  # shown what it examined, and this is the one arm whose evidence is worth reading.
  printf '       replay: %s\n       replay: delivered=%s undelivered=%s exit=%s\n' \
    "$(observed_of "$J_V403" FCM-COVERAGE)" "$V403_HIT" "$V403_MISS" "$RC_V403"
  grep -oE '"observed":"declared-add-not-delivered[^"]*"' <<<"$J_V403" | sed 's/^/       replay: /' || true
  [ "$V403_MISS" -ge 1 ] \
    && ok "A11 HISTORICAL REPLAY — the v4.03 merge FAILs on its undelivered declared ADD" \
    || bad "A11 v4.03 replay did not flag the undelivered ADD (miss=$V403_MISS hit=$V403_HIT)"
  [ "$V403_HIT" -ge 1 ] \
    && ok "A11 CONTROL — the v4.03 ADDs that DID ship still PASS (not a stuck-on probe)" \
    || bad "A11 v4.03 replay flagged everything — no delivered ADD passed (hit=$V403_HIT)"
  [ "$RC_V403" -eq 3 ] && ok "A11 the replay exits 3" || bad "A11 expected exit 3, got $RC_V403"
else
  ok "A11 SKIP — historical-commit-unreachable (shallow clone); degraded honestly, not passed"
fi

# ---------------------------------------------------------------------------
# G6-M — MUTATION ARMS. Each removes ONE observing step and asserts an arm moves.
# ---------------------------------------------------------------------------
echo "G6-M — mutation arms (each deletes one observing step)"
MUTD="$(mktemp -d -t verify-plan-fcm-mut.XXXXXX)"

# mutate <name> <sed-expr> — writes a mutated tool copy, prints its path.
mutate() {
  local name="$1"; shift
  local dst="$MUTD/$name.sh"
  cp "$VERIFY" "$dst"
  local e
  for e in "$@"; do sed -i.bak -E "$e" "$dst"; done
  rm -f "$dst.bak"
  chmod +x "$dst"
  printf '%s' "$dst"
}
# mutant_differs <label> <mutant> <fixture> <diff> <id> <live-observed-prefix>
mutant_differs() {
  local label="$1" mut="$2" fx="$3" diff="$4" id="$5" live="$6" got
  fcm_run "$mut" "$fx" "$diff"
  got="$(observed_of "$FCM_JSON" "$id")"
  case "$got" in
    "$live"*) bad "$label — SURVIVED the mutation (still '$got'): the arm observes nothing" ;;
    *)        ok  "$label — mutation detected (observed moved to '${got:-<no record at all>}')" ;;
  esac
}

# M1 flips the VERDICT and leaves the observed text alone — which is exactly how a
# neutered control still looks healthy in an evidence table. The arm therefore reads
# the verdict, not the prose. (Comparing observed here would have passed under the
# mutation; that was caught on the first run of this group.)
M1="$(mutate m1-must-flag 's/"\$VERDICT_FAIL" "declared-add-not-delivered/"$VERDICT_PASS" "declared-add-not-delivered/')"
fcm_run "$M1" fcm-declared-absent.md "$DIFF_ABSENT"
[ "$(verdict_of "$FCM_JSON" FCM-1)" != FAIL ] \
  && ok "M1 must-flag emission neutered — mutation detected (verdict moved to '$(verdict_of "$FCM_JSON" FCM-1)')" \
  || bad "M1 SURVIVED — the undelivered ADD still FAILs with the FAIL emission removed"
[ "$FCM_RC" -eq 0 ] \
  && ok "M1 CONTROL — the neutered build also stops exiting 3 (the verdict really is load-bearing)" \
  || bad "M1 control — the neutered build still exits $FCM_RC"

M2="$(mutate m2-fence-blind \
      '/infence = 1 - infence; print \}; next \}/d' \
      's/\(insec == 0 \|\| infence == 0\) \&\& \/\^#\+ \/ \{/\/^#+ \/ {/')"
mutant_differs "M2 fence-aware extraction reverted to the shared fence-blind seam" \
      "$M2" fcm-truncating.md "$DIFF_PRESENT" FCM-1 "declared-add-delivered"

M3="$(mutate m3-no-trunc-guard 's/exit \(n % 2 == 0\)/exit 1/')"
M23="$(mutate m23-blind-and-unguarded \
      '/infence = 1 - infence; print \}; next \}/d' \
      's/\(insec == 0 \|\| infence == 0\) \&\& \/\^#\+ \/ \{/\/^#+ \/ {/' \
      's/exit \(n % 2 == 0\)/exit 1/')"
# The pair is the real demonstration: with BOTH removed the obligation is not merely
# mis-graded, it becomes invisible and the matrix reads as having nothing to assert.
fcm_run "$M23" fcm-truncating.md "$DIFF_PRESENT"; J_M23="$FCM_JSON"
case "$(observed_of "$J_M23" FCM-COVERAGE)" in
  *fcm-no-unconditional-adds*|*obligations=0*)
    ok "M2+M3 VACUITY DEMO — without both guards the declared ADD vanishes and the matrix reads clean" ;;
  *) bad "M2+M3 expected a vacuous obligations=0 reading, got '$(observed_of "$J_M23" FCM-COVERAGE)'" ;;
esac
[ "$(observed_of "$J_M23" FCM-1)" = "" ] \
  && ok "M2+M3 the obligation record is ABSENT under the unguarded mutant (this is the defect class)" \
  || bad "M2+M3 an obligation record survived: '$(observed_of "$J_M23" FCM-1)'"

M4="$(mutate m4-unwired 's/fcm_records="\$\(handle_fcm_delivery "\$PLAN_ABS" \|\| true\)"/fcm_records=""/')"
fcm_run "$M4" fcm-declared-absent.md "$DIFF_ABSENT"; J_M4="$FCM_JSON"
[ -z "$(observed_of "$J_M4" FCM-COVERAGE)" ] && [ -z "$(observed_of "$J_M4" FCM-1)" ] \
  && ok "M4 WIRING — with the main() record source removed the family emits NOTHING (FMF-2 class)" \
  || bad "M4 the unwired mutant still emitted FCM records — the mutation did not take"
grep -q 'FCM-COVERAGE' <<<"$J_ABSENT" \
  && ok "M4 CONTROL — the wired build DOES emit the coverage record (absence is detectable)" \
  || bad "M4 control — the wired build emitted no coverage record either; M4 proves nothing"

M5="$(mutate m5-default-edit 's/iv = "unknown"; form = "fence-bare"/iv = "edit"; form = "fence-bare"/')"
mutant_differs "M5 marker-less default flipped from unknown to edit" \
      "$M5" fcm-bare-paths.md "$DIFF_ABSENT" FCM-COVERAGE "declared=3 interpreted=0"

M6="$(mutate m6-seam-open 's/if \[ -n "\$ARG_FCM_DIFF_FILE" \] \&\& \[ "\$in_corpus" -eq 1 \]; then/if false; then/')"
set +e
J_M6="$("$M6" --format=json --fcm-diff-file "$DIFF_PRESENT" "$REPO_ROOT/$REALPLAN" 2>/dev/null)"
set -e
case "$(observed_of "$J_M6" FCM-COVERAGE)" in
  fcm-fixture-mode-on-live-plan*) bad "M6 SURVIVED — the seam refusal fired without its guard" ;;
  # An EMPTY record is not evidence the refusal was removed — it is evidence nothing
  # was graded. Without this arm M6's success condition is satisfied by any failure
  # that produces no output at all, which is the same "silence must not read as zero"
  # defect A6 pins for coverage. This arm is what makes M6 discriminate.
  "") bad "M6 NOT GRADEABLE — the mutant emitted no coverage record at all; absence of the refusal is not evidence its guard was removed" ;;
  *) ok "M6 fixture-seam refusal removed — a real plan becomes gradeable against an authored diff" ;;
esac

M7="$(mutate m7-no-glob-arm "s/printf 'glob'/printf 'literal'/")"
mutant_differs "M7 glob arm removed (falls to the literal arm)" \
      "$M7" fcm-glob.md "$DIFF_PRESENT" FCM-1 "declared-add-delivered"

M8="$(mutate m8-no-devlog 's/devlog="\$\(parse_deviation_log "\$plan" \|\| true\)"/devlog=""/')"
mutant_differs "M8 Deviation-Log read removed" \
      "$M8" fcm-deviation-recorded.md "$DIFF_ABSENT" FCM-1 "deviation-recorded"

rm -rf "$MUTD"

# ---------------------------------------------------------------------------
# G7 — PROVENANCE SURVIVAL (the domain_practice label across Commit-0).
#
# WHY THE FIXTURES ARE STAGED INTO A TEMP TREE. This family's applicability gate
# is a PATH test: a target outside */release/releases/plans/* is a named SKIP.
# A fixture sitting at release/tools/tests/fixtures/ therefore takes the SKIP arm
# and NOTHING below it can ever be graded. The options were to weaken the gate
# with a test-only override, or to commit fixtures into the live plan corpus, or
# to stage a committed fixture into a temp tree whose PATH satisfies the gate.
# The third is the only one that neither installs an off-switch on the control
# nor pollutes the corpus the control governs, so that is what prov_stage does.
#
# WHY EACH PLAN FIXTURE DECLARES A READ ROW AND NO ADDS. These fixtures are real
# release-plan targets as far as the tool is concerned, so fcm-delivery grades
# them too. Without a parseable matrix every run would carry an fcm ERROR, every
# exit code would be 3 for a reason having nothing to do with provenance, and the
# exit-code arms below would assert nothing.
# ---------------------------------------------------------------------------
echo "G7 — provenance-survival: the label across the Commit-0 transcription"

PROVD="$(mktemp -d -t verify-plan-prov.XXXXXX)"
PROV_PLANS="$PROVD/release/releases/plans"
mkdir -p "$PROV_PLANS"

PROV_N=0
# prov_stage <fixture> [<replacement-source-value>] — copy a committed fixture
# into the gate-satisfying temp tree, optionally rewriting ONLY the source: value.
# Every other field and the rest of the file stay byte-identical, so a value arm
# differs from its base in exactly the field under test.
prov_stage() {
  local fx="$1" newsrc="${2:-}" dst
  PROV_N=$((PROV_N+1))
  dst="$PROV_PLANS/staged-$PROV_N-$fx"
  cp "$REPO_ROOT/$FIXD/$fx" "$dst"
  if [ -n "$newsrc" ]; then
    sed -i.bak -E "s|(domain_practice: \{ source: )[^,]*|\1$newsrc|" "$dst"
    rm -f "$dst.bak"
  fi
  printf '%s' "$dst"
}

# prov_run <tool> <plan-path> [<comment-path>] — sets PROV_JSON and PROV_RC in the
# CURRENT shell, for the same reason fcm_run does: capturing through $(...) runs
# the function in a subshell where PROV_RC is assigned and then discarded, and
# every exit-code assertion silently grades a stale 0.
PROV_JSON=""
PROV_RC=0
prov_run() {
  local tool="$1" plan="$2" comment="${3:-}"
  set +e
  if [ -n "$comment" ]; then
    PROV_JSON="$("$tool" --format=json --stage4-comment "$comment" "$plan" 2>/dev/null)"
  else
    PROV_JSON="$("$tool" --format=json "$plan" 2>/dev/null)"
  fi
  PROV_RC=$?
  set -e
}

C_LABEL="$REPO_ROOT/$FIXD/prov-comment-with-label.txt"
C_THIN="$REPO_ROOT/$FIXD/prov-comment-thin.txt"

# --- P1: conformant plan, no comment supplied. ---
P_CONF="$(prov_stage prov-conformant.md)"
prov_run "$VERIFY" "$P_CONF"; J_P1="$PROV_JSON"; RC_P1="$PROV_RC"
[ "$(verdict_of "$J_P1" PROV-PRESENCE)" = PASS ] && ok "P1 conformant plan → PRESENCE PASS" || bad "P1 PRESENCE expected PASS, got '$(verdict_of "$J_P1" PROV-PRESENCE)'"
[ "$(verdict_of "$J_P1" PROV-GRAMMAR)" = PASS ] && ok "P1 conformant plan → GRAMMAR PASS" || bad "P1 GRAMMAR expected PASS, got '$(verdict_of "$J_P1" PROV-GRAMMAR)' obs='$(observed_of "$J_P1" PROV-GRAMMAR)'"
[ "$(verdict_of "$J_P1" PROV-DELTA)" = SKIP ] && ok "P1 no comment supplied → DELTA SKIP" || bad "P1 DELTA expected SKIP, got '$(verdict_of "$J_P1" PROV-DELTA)'"
[ "$RC_P1" -eq 0 ] && ok "P1 a fully conformant plan does not red-line the run" || bad "P1 expected exit 0, got $RC_P1 (cov='$(observed_of "$J_P1" FCM-COVERAGE)')"

# --- P2: the v4.37 shape. THE NEGATIVE ARM. ---
P_ABS="$(prov_stage prov-label-absent.md)"
prov_run "$VERIFY" "$P_ABS"; J_P2="$PROV_JSON"; RC_P2="$PROV_RC"
[ "$(verdict_of "$J_P2" PROV-PRESENCE)" = FAIL ] && ok "P2 MUST-FLAG — a plan carrying no label FAILs presence" || bad "P2 PRESENCE expected FAIL, got '$(verdict_of "$J_P2" PROV-PRESENCE)'"
case "$(observed_of "$J_P2" PROV-PRESENCE)" in
  prov-label-absent*) ok "P2 the finding names itself (prov-label-absent)" ;;
  *) bad "P2 expected prov-label-absent, got '$(observed_of "$J_P2" PROV-PRESENCE)'" ;;
esac
[ "$RC_P2" -eq 3 ] && ok "P2 the presence FAIL reaches the exit predicate" || bad "P2 expected exit 3, got $RC_P2"
[ "$(verdict_of "$J_P2" PROV-GRAMMAR)" = SKIP ] && ok "P2 GRAMMAR SKIPs honestly when there is no label to grade" || bad "P2 GRAMMAR expected SKIP, got '$(verdict_of "$J_P2" PROV-GRAMMAR)'"

# --- P3: both surfaces carry the label → no loss. ---
prov_run "$VERIFY" "$P_CONF" "$C_LABEL"; J_P3="$PROV_JSON"
[ "$(verdict_of "$J_P3" PROV-DELTA)" = PASS ] && ok "P3 comment + plan both carry the label → DELTA PASS" || bad "P3 DELTA expected PASS, got '$(verdict_of "$J_P3" PROV-DELTA)' obs='$(observed_of "$J_P3" PROV-DELTA)'"

# --- P4: emitted at Stage 4, dropped at Commit 0. THE CARD'S OWN SYMPTOM. ---
prov_run "$VERIFY" "$P_ABS" "$C_LABEL"; J_P4="$PROV_JSON"
[ "$(verdict_of "$J_P4" PROV-DELTA)" = FAIL ] && ok "P4 MUST-FLAG — label in the comment, absent from the plan → DELTA FAIL" || bad "P4 DELTA expected FAIL, got '$(verdict_of "$J_P4" PROV-DELTA)'"
case "$(observed_of "$J_P4" PROV-DELTA)" in
  *domain_practice-label*) ok "P4 the lost element is NAMED, not merely counted" ;;
  *) bad "P4 expected the lost element named, got '$(observed_of "$J_P4" PROV-DELTA)'" ;;
esac
# The partial-loss control: file-change-matrix is present on BOTH surfaces and must
# NOT be reported lost, or the arm is a stuck-on probe reporting everything.
case "$(observed_of "$J_P4" PROV-DELTA)" in
  *file-change-matrix*) bad "P4 CONTROL — a surviving element was reported lost; the delta set is stuck-on" ;;
  *) ok "P4 CONTROL — the element present on BOTH surfaces is not reported lost" ;;
esac

# --- P5a: THE LOAD-BEARING CASE. Both surfaces empty. ---
# The delta limb PASSes here, honestly and correctly — nothing was lost, because
# nothing was ever there. A delta-only mechanism reports this release CLEAN. The
# run must still FAIL, and it must fail on PRESENCE.
prov_run "$VERIFY" "$P_ABS" "$C_THIN"; J_P5A="$PROV_JSON"; RC_P5A="$PROV_RC"
[ "$(verdict_of "$J_P5A" PROV-DELTA)" = PASS ] \
  && ok "P5a the delta limb PASSes on the v4.37 shape (this is the vacuity, demonstrated)" \
  || bad "P5a DELTA expected PASS, got '$(verdict_of "$J_P5A" PROV-DELTA)'"
[ "$(verdict_of "$J_P5A" PROV-PRESENCE)" = FAIL ] \
  && ok "P5a LOAD-BEARING — the run still FAILs, on the absolute limb" \
  || bad "P5a PRESENCE expected FAIL, got '$(verdict_of "$J_P5A" PROV-PRESENCE)'"
[ "$RC_P5A" -eq 3 ] \
  && ok "P5a AC2 SATISFIED — a release where NEITHER surface carries the field exits 3" \
  || bad "P5a expected exit 3, got $RC_P5A"

# --- P5b: withholding the evidence must not manufacture a pass. ---
prov_run "$VERIFY" "$P_ABS"; J_P5B="$PROV_JSON"
[ "$(verdict_of "$J_P5B" PROV-DELTA)" = SKIP ] && ok "P5b absent evidence → SKIP, never PASS" || bad "P5b DELTA expected SKIP, got '$(verdict_of "$J_P5B" PROV-DELTA)'"
case "$(observed_of "$J_P5B" PROV-DELTA)" in
  prov-no-stage4-comment-supplied*) ok "P5b the SKIP is NAMED (it says why it could not assert)" ;;
  *) bad "P5b expected prov-no-stage4-comment-supplied, got '$(observed_of "$J_P5B" PROV-DELTA)'" ;;
esac
[ "$(verdict_of "$J_P5B" PROV-PRESENCE)" = FAIL ] && ok "P5b presence still FAILs without any comment at all" || bad "P5b PRESENCE expected FAIL, got '$(verdict_of "$J_P5B" PROV-PRESENCE)'"

# --- P6: the five observed non-conformant source values. NEGATIVE ARM. ---
# Every one of these was authored into a real release plan. None is a fourth form:
# each has a codified home it should have routed to, which is why the grammar
# ROUTES rather than EXTENDS. All five must FAIL, and on the source limb.
P6_VALUES="N/A — in-repo precedent governs; no external practice consulted
N/A — governance/skill-corpus release; conventions already encoded
N/A — pipeline-internal
release-hub Mode O Stage-13 fold-in
UNSOURCED-DOMAIN ... domain: governance"
P6_FAILS=0
P6_TOTAL=0
while IFS= read -r v; do
  [ -z "$v" ] && continue
  P6_TOTAL=$((P6_TOTAL+1))
  P6_PLAN="$(prov_stage prov-conformant.md "$v")"
  prov_run "$VERIFY" "$P6_PLAN"
  if [ "$(verdict_of "$PROV_JSON" PROV-GRAMMAR)" = FAIL ]; then
    P6_FAILS=$((P6_FAILS+1))
  else
    bad "P6 non-conformant source accepted: '$v' → '$(verdict_of "$PROV_JSON" PROV-GRAMMAR)'"
  fi
done <<< "$P6_VALUES"
[ "$P6_FAILS" -eq "$P6_TOTAL" ] && [ "$P6_TOTAL" -eq 5 ] \
  && ok "P6 all $P6_FAILS/$P6_TOTAL observed non-conformant source values FAIL the grammar" \
  || bad "P6 only $P6_FAILS of $P6_TOTAL non-conformant values failed (expected 5/5)"

# --- P7: Forms A / B / X all PASS. THE SENSITIVITY ARM. ---
# Without this, P6 is satisfied by a predicate that rejects everything.
prov_run "$VERIFY" "$(prov_stage prov-form-a.md)"; J_FA="$PROV_JSON"
[ "$(verdict_of "$J_FA" PROV-GRAMMAR)" = PASS ] && ok "P7-A SENSITIVITY — Form A (repo-relative path + anchor) is accepted" || bad "P7-A expected PASS, got '$(verdict_of "$J_FA" PROV-GRAMMAR)' obs='$(observed_of "$J_FA" PROV-GRAMMAR)'"
prov_run "$VERIFY" "$(prov_stage prov-form-b.md)"; J_FB="$PROV_JSON"
[ "$(verdict_of "$J_FB" PROV-GRAMMAR)" = PASS ] && ok "P7-B SENSITIVITY — Form B with a rationale sibling is accepted" || bad "P7-B expected PASS, got '$(verdict_of "$J_FB" PROV-GRAMMAR)' obs='$(observed_of "$J_FB" PROV-GRAMMAR)'"
[ "$(verdict_of "$J_P1" PROV-GRAMMAR)" = PASS ] && ok "P7-X SENSITIVITY — Form X (the exemption token) is accepted" || bad "P7-X expected PASS via P1"
prov_run "$VERIFY" "$(prov_stage prov-conformant.md 'https://example.invalid/practice-guide')"; J_FURL="$PROV_JSON"
[ "$(verdict_of "$J_FURL" PROV-GRAMMAR)" = PASS ] && ok "P7-A SENSITIVITY — the URL spelling of Form A is accepted" || bad "P7-A URL expected PASS, got '$(verdict_of "$J_FURL" PROV-GRAMMAR)'"

# --- P8: Form B with no rationale sibling. ---
prov_run "$VERIFY" "$(prov_stage prov-form-b-no-rationale.md)"; J_FBN="$PROV_JSON"
[ "$(verdict_of "$J_FBN" PROV-GRAMMAR)" = FAIL ] && ok "P8 Form B with no rationale FAILs" || bad "P8 expected FAIL, got '$(verdict_of "$J_FBN" PROV-GRAMMAR)'"
case "$(observed_of "$J_FBN" PROV-GRAMMAR)" in
  *limb=rationale*) ok "P8 the failing LIMB is named (limb=rationale), not just the verdict" ;;
  *) bad "P8 expected limb=rationale, got '$(observed_of "$J_FBN" PROV-GRAMMAR)'" ;;
esac

# --- P9: dash variants normalize. A typographic slip is not a semantic finding. ---
P9_OK=0
P9_TOTAL=0
for d in "N/A - pipeline-internal release" "N/A -- pipeline-internal release" "N/A – pipeline-internal release"; do
  P9_TOTAL=$((P9_TOTAL+1))
  prov_run "$VERIFY" "$(prov_stage prov-conformant.md "$d")"
  if [ "$(verdict_of "$PROV_JSON" PROV-GRAMMAR)" = PASS ]; then P9_OK=$((P9_OK+1)); else bad "P9 dash variant rejected: '$d'"; fi
done
[ "$P9_OK" -eq "$P9_TOTAL" ] && ok "P9 all $P9_OK/$P9_TOTAL dash variants normalize to Form X" || bad "P9 only $P9_OK of $P9_TOTAL normalized"

# --- P9 CONTROL: normalization must not swallow a genuinely different value. ---
prov_run "$VERIFY" "$(prov_stage prov-conformant.md 'N/A — pipeline-internal')"; J_P9C="$PROV_JSON"
[ "$(verdict_of "$J_P9C" PROV-GRAMMAR)" = FAIL ] \
  && ok "P9 CONTROL — the truncated token is still rejected (normalization folds the DASH, not the value)" \
  || bad "P9 CONTROL — normalization accepted a truncated token; it is folding too much"

# --- The date limb, both arms. ---
prov_run "$VERIFY" "$(prov_stage prov-conformant.md)"; J_DOK="$PROV_JSON"
[ "$(verdict_of "$J_DOK" PROV-GRAMMAR)" = PASS ] && ok "date limb CONTROL — a well-formed date passes" || bad "date limb control expected PASS"
P_BADDATE="$(prov_stage prov-conformant.md)"
sed -i.bak 's/date: 2026-08-24/date: August 2026/' "$P_BADDATE"; rm -f "$P_BADDATE.bak"
prov_run "$VERIFY" "$P_BADDATE"; J_BD="$PROV_JSON"
[ "$(verdict_of "$J_BD" PROV-GRAMMAR)" = FAIL ] && ok "date limb — a malformed date FAILs" || bad "date limb expected FAIL, got '$(verdict_of "$J_BD" PROV-GRAMMAR)'"
case "$(observed_of "$J_BD" PROV-GRAMMAR)" in
  *limb=date*) ok "date limb — the failing limb is named" ;;
  *) bad "expected limb=date, got '$(observed_of "$J_BD" PROV-GRAMMAR)'" ;;
esac

# --- The in-label domain limb: a wrapped body satisfies presence and fails here. ---
P_NODOM="$(prov_stage prov-conformant.md)"
sed -i.bak 's/, domain: governance }/ }/' "$P_NODOM"; rm -f "$P_NODOM.bak"
prov_run "$VERIFY" "$P_NODOM"; J_ND="$PROV_JSON"
[ "$(verdict_of "$J_ND" PROV-PRESENCE)" = PASS ] && ok "domain limb — the label still satisfies PRESENCE" || bad "domain limb: presence expected PASS"
[ "$(verdict_of "$J_ND" PROV-GRAMMAR)" = FAIL ] && ok "domain limb — the missing mandatory class field FAILs GRAMMAR" || bad "domain limb expected FAIL, got '$(verdict_of "$J_ND" PROV-GRAMMAR)'"
case "$(observed_of "$J_ND" PROV-GRAMMAR)" in
  *limb=domain*) ok "domain limb — the failing limb is named" ;;
  *) bad "expected limb=domain, got '$(observed_of "$J_ND" PROV-GRAMMAR)'" ;;
esac

# --- Multi-label (the v1.16 shape): surfaced with line numbers, not resolved. ---
prov_run "$VERIFY" "$(prov_stage prov-quoted-in-prose.md)"; J_MULTI="$PROV_JSON"
case "$(observed_of "$J_MULTI" PROV-COVERAGE)" in
  *prov-multiple-labels:2*) ok "multi-label — both matches are reported with their line numbers" ;;
  *) bad "expected prov-multiple-labels:2, got '$(observed_of "$J_MULTI" PROV-COVERAGE)'" ;;
esac
case "$(observed_of "$J_P1" PROV-COVERAGE)" in
  *prov-multiple-labels*) bad "multi-label CONTROL — the single-label plan also reported multiple labels" ;;
  *) ok "multi-label CONTROL — a single-label plan does NOT carry the note (not stuck-on)" ;;
esac

# --- P10: outside the plan corpus → a NAMED skip, and nothing else graded. ---
prov_run "$VERIFY" "$REPO_ROOT/$FIXD/prov-conformant.md"; J_OUT="$PROV_JSON"
case "$(observed_of "$J_OUT" PROV-COVERAGE)" in
  prov-not-a-release-plan*) ok "P10 a target outside the plan corpus is a NAMED skip" ;;
  *) bad "P10 expected prov-not-a-release-plan, got '$(observed_of "$J_OUT" PROV-COVERAGE)'" ;;
esac
[ -z "$(verdict_of "$J_OUT" PROV-PRESENCE)" ] \
  && ok "P10 REGRESSION BOUND — no other provenance record is emitted off-corpus" \
  || bad "P10 a graded record leaked outside the corpus: '$(verdict_of "$J_OUT" PROV-PRESENCE)'"

# --- P11: an unreadable comment is ERROR, never PASS. ---
prov_run "$VERIFY" "$P_CONF" "$PROVD/does-not-exist.txt"; J_P11="$PROV_JSON"
[ "$(verdict_of "$J_P11" PROV-DELTA)" = ERROR ] \
  && ok "P11 SPECIFICITY — --stage4-comment naming a non-existent path is ERROR, never PASS" \
  || bad "P11 DELTA expected ERROR, got '$(verdict_of "$J_P11" PROV-DELTA)'"

# --- Coverage record carries its denominators. ---
case "$(observed_of "$J_P1" PROV-COVERAGE)" in
  *labels_found=*plan_lines=*delta_source=*) ok "COVERAGE reports its denominators (labels_found / plan_lines / delta_source)" ;;
  *) bad "COVERAGE denominators missing: '$(observed_of "$J_P1" PROV-COVERAGE)'" ;;
esac
case "$(observed_of "$J_P1" PROV-COVERAGE)" in
  *survival-rows-1-5-only*) ok "COVERAGE states the delta-limb SCOPE, so it is visible rather than inferred" ;;
  *) bad "COVERAGE does not state the delta set scope: '$(observed_of "$J_P1" PROV-COVERAGE)'" ;;
esac

# --- P12: NON-SYNTHETIC historical replay. The releases that motivated the card. ---
V431="release/releases/plans/v4/v4.31_RELEASE_PLAN.md"
V437="release/releases/plans/v4/v4.37_RELEASE_PLAN.md"
# PRECONDITION, load-bearing for the same reason A10/A11's is: a missing target
# yields empty output, and an empty verdict would grade as "not FAIL" on the v4.31
# arm — a false green produced by a file that was never read.
if [ ! -f "$REPO_ROOT/$V431" ] || [ ! -f "$REPO_ROOT/$V437" ]; then
  bad "P12 PRECONDITION — a replay target is absent (v4.31/v4.37 relocated or renamed?); the arms below cannot grade"
else
  prov_run "$VERIFY" "$REPO_ROOT/$V431"; J_431="$PROV_JSON"
  prov_run "$VERIFY" "$REPO_ROOT/$V437"; J_437="$PROV_JSON"
  printf '       replay: v4.31 %s\n       replay: v4.37 %s\n' \
    "$(observed_of "$J_431" PROV-COVERAGE)" "$(observed_of "$J_437" PROV-COVERAGE)"
  [ "$(verdict_of "$J_437" PROV-PRESENCE)" = FAIL ] \
    && ok "P12 HISTORICAL REPLAY — v4.37 (merged with no label) FAILs presence" \
    || bad "P12 v4.37 did not fail presence (got '$(verdict_of "$J_437" PROV-PRESENCE)') — the live recurrence is not caught"
  [ "$(verdict_of "$J_431" PROV-PRESENCE)" = PASS ] \
    && ok "P12 CONTROL — v4.31 (which DID carry the label) still passes (not a stuck-on probe)" \
    || bad "P12 v4.31 failed presence too — the replay flags everything and proves nothing"
fi

# ---------------------------------------------------------------------------
# G7-M — MUTATION ARMS for provenance-survival. Same contract as G6-M: each
# deletes ONE observing step and asserts an arm changes its answer.
# ---------------------------------------------------------------------------
echo "G7-M — provenance mutation arms (each deletes one observing step)"
PMUTD="$(mktemp -d -t verify-plan-prov-mut.XXXXXX)"
pmutate() {
  local name="$1"; shift
  local dst="$PMUTD/$name.sh"
  cp "$VERIFY" "$dst"
  local e
  for e in "$@"; do sed -i.bak -E "$e" "$dst"; done
  rm -f "$dst.bak"
  chmod +x "$dst"
  printf '%s' "$dst"
}

# M9 — the must-flag emission. Reads the VERDICT, not the prose: flipping the
# verdict while leaving the observed text intact is exactly how a neutered control
# still looks healthy in an evidence table.
M9="$(pmutate m9-presence-neutered 's/"at least one conformant single-line label" "\$VERDICT_FAIL"/"at least one conformant single-line label" "$VERDICT_PASS"/')"
prov_run "$M9" "$P_ABS"
[ "$(verdict_of "$PROV_JSON" PROV-PRESENCE)" != FAIL ] \
  && ok "M9 presence FAIL emission neutered — mutation detected (verdict moved to '$(verdict_of "$PROV_JSON" PROV-PRESENCE)')" \
  || bad "M9 SURVIVED — the label-absent plan still FAILs with the FAIL emission removed"
[ "$PROV_RC" -eq 0 ] \
  && ok "M9 CONTROL — the neutered build also stops exiting 3 (the verdict really is load-bearing)" \
  || bad "M9 control — the neutered build still exits $PROV_RC"

# M10 — WIRING. With the main() record source removed the family emits NOTHING.
M10="$(pmutate m10-unwired 's/prov_records="\$\(handle_provenance_survival "\$PLAN_ABS" \|\| true\)"/prov_records=""/')"
prov_run "$M10" "$P_ABS"; J_M10="$PROV_JSON"
[ -z "$(observed_of "$J_M10" PROV-COVERAGE)" ] && [ -z "$(verdict_of "$J_M10" PROV-PRESENCE)" ] \
  && ok "M10 WIRING — the unwired mutant emits no provenance records at all" \
  || bad "M10 the unwired mutant still emitted provenance records — the mutation did not take"
grep -q 'PROV-COVERAGE' <<<"$J_P2" \
  && ok "M10 CONTROL — the wired build DOES emit the coverage record (absence is detectable)" \
  || bad "M10 control — the wired build emitted no coverage record either; M10 proves nothing"

# M11 — the DIRECTION OF THE DEFAULT. This is the arm that proves withholding the
# Stage-4 comment cannot buy a pass. It is the substitute for the fixture-refusal
# guard fcm-delivery has, and it is the whole reason that refusal was not copied.
M11="$(pmutate m11-absent-comment-passes 's/"no survival element lost at transcription" "\$VERDICT_SKIP"/"no survival element lost at transcription" "$VERDICT_PASS"/')"
prov_run "$M11" "$P_ABS"
[ "$(verdict_of "$PROV_JSON" PROV-DELTA)" != SKIP ] \
  && ok "M11 absent-evidence SKIP flipped to PASS — mutation detected (withholding would buy a pass)" \
  || bad "M11 SURVIVED — the absent-comment arm still SKIPs with the SKIP emission removed"

# M12 — the grammar must-flag emission.
M12="$(pmutate m12-grammar-neutered 's/source" "\$VERDICT_FAIL"/source" "$VERDICT_PASS"/')"
prov_run "$M12" "$(prov_stage prov-form-b-no-rationale.md)"
[ "$(verdict_of "$PROV_JSON" PROV-GRAMMAR)" != FAIL ] \
  && ok "M12 grammar FAIL emission neutered — mutation detected" \
  || bad "M12 SURVIVED — a non-conformant label still FAILs with the FAIL emission removed"

# M13 — the delta SET. Removing the label detector from the element sweep must move
# P4, or the delta limb is not really computing a set difference.
M13="$(pmutate m13-no-label-element '/domain_practice-label/d')"
prov_run "$M13" "$P_ABS" "$C_LABEL"
case "$(observed_of "$PROV_JSON" PROV-DELTA)" in
  *domain_practice-label*) bad "M13 SURVIVED — the lost element is still reported with its detector deleted" ;;
  *) ok "M13 delta element detector removed — mutation detected (observed moved to '$(observed_of "$PROV_JSON" PROV-DELTA)')" ;;
esac

rm -rf "$PMUTD"
rm -rf "$PROVD"

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

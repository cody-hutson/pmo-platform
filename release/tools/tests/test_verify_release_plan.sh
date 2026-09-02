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
#  (G10) #6383 — the header-trap regression arm the landed positional fix
#        shipped without; the runtime-suite verdict floor (PASS unreachable,
#        prose route retired, executable rows no longer stolen); the roll-up
#        denominator; and FCM intent read as a DECLARATION rather than
#        inferred from annotation prose or a filename segment. Six mutation
#        arms, one per property limb.
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
#   (G9) MARKDOWN PIPE ESCAPE — field parity across both split sites, plus the
#        boundary question of WHERE the escape may be resolved. A `\|` inside a
#        table cell is markdown (the cell is split on pipes, so an author who
#        needs a literal one has no alternative) and is healed; a `\|` inside a
#        scaffold BULLET is matcher syntax (a bullet is never split) and is
#        passed through byte-intact. A row that still misses its header's field
#        count after healing carries an unescaped bare pipe and is a named ERROR
#        rather than a verdict read at shifted column indices. Carries a control
#        twin, a bullet-passthrough guard, and a non-synthetic corpus replay.
#   (G8) MATCHER COUNT-MODE FIDELITY — count mode versus match mode read from the
#        command's own flags, a strict-integer guard, and an UNCONDITIONAL
#        exit-status guard. The last of these closes a false PASS: a matcher
#        exiting 2 produced empty output, a fabricated count of 0, and an
#        "expect zero" criterion rendering PASS — inside the tool that grades the
#        release's own verification plan.
#   (G9-M / G8-M) Mutation arms for both groups. Each proves its mutation TOOK
#        (the mutant bytes differ), proves the mutant RAN (it emitted records),
#        and then names the specific answer the assertion must move to. A
#        negation alone is not enough: "no longer PASS" is satisfied by a mutant
#        that never ran, which is a green arm testing nothing.
#
#   NOTE — DUPLICATE GROUP ID, RESOLVED. Two branches allocated "G7" (and "G7-M")
#        independently from the same base, so the merge briefly documented and ran
#        TWO distinct G7 groups. The merge left both standing because renumbering
#        exceeds a merge's remit; it was resolved immediately afterwards, at
#        operator direction, on the same precedence rule the ADR number space
#        uses — the incumbent keeps the id and the newcomer yields. The
#        provenance-survival group had already merged to the mainline, so THIS
#        branch's markdown-pipe-escape group moved: G7* -> G9* (G7-1..G7-10,
#        G7-R, G7-M1..G7-M3 and the `G7M2_PARITY` shell identifier all shifted
#        with it). G8 is this branch's too but was uncontended, so it did not
#        move — which is why the group headings above read G9, G8, G9-M/G8-M
#        rather than in numeric order. The ids are cosmetic echo labels that feed
#        no pass/fail tally, and a repo-wide sweep at the time of the move found
#        ZERO references to the compound ids outside this file.
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

# The expectation is DERIVED from the tool's own SCHEMA_VERSION — never pinned to a
# literal. A hardcoded `schema v2` is a PRESENCE predicate against a CURRENCY fact: it
# holds for exactly one release and then asserts the wrong thing forever. That is the
# defect family this release exists to close, and this line is how it red-lined its own
# CI at the 2 -> 3 bump — the constant moved in one file and its assertion did not move
# in the other. Deriving binds the pair mechanically instead of by memory.
#
# THE NON-EMPTY ARM BELOW IS LOAD-BEARING, so do not "simplify" it away. If the
# extractor ever stops matching — the constant reformatted, renamed, or moved — then
# EXPECT_SCHEMA goes empty, `schema v` matches ANY version, and the assertion passes
# vacuously in a way no reader can distinguish from a real pass. Deriving trades a
# STALE assertion for a SILENT one unless the derivation is itself asserted.
EXPECT_SCHEMA="$(sed -n 's/^readonly SCHEMA_VERSION="\([0-9][0-9]*\)".*/\1/p' "$VERIFY")"
if [ -n "$EXPECT_SCHEMA" ]; then
  ok "schema expectation DERIVED from the tool's own constant (SCHEMA_VERSION=$EXPECT_SCHEMA)"
else
  bad "could not derive SCHEMA_VERSION from $VERIFY — without this arm the check below would pass vacuously"
  EXPECT_SCHEMA='<UNDERIVABLE>'   # cannot match: fail LOUDLY below rather than vacuously
fi
VER_OUT="$("$VERIFY" --version)"
grep -q "schema v${EXPECT_SCHEMA}" <<<"$VER_OUT" && ok "--version prints SCHEMA_VERSION (schema v${EXPECT_SCHEMA})" || bad "--version missing schema version: '$VER_OUT' (expected 'schema v${EXPECT_SCHEMA}')"

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
  # sigpipe-idiom: allow — `sed`, not the here-string, is the signallable producer: the here-string feeds `sed`, and `sed` writes into the pipe `head -1` closes. Safe on SIZE, not on shape — the extracted field list is a few short lines, far under the pipe buffer, so `sed` writes it all and exits before `head` closes the read end.
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

# --- A12: the first-segment enum admits `operations`, a top-level module. ---
# The enum omitted it, and the omission was SILENT: 286 declaration rows across 47
# plans of the 189-plan corpus returned no path and left the population before
# classification. This arm is the sensitivity half — it fires only if the segment
# is recognised. M14 below is what proves the arm observes the enum rather than
# passing for some unrelated reason.
DIFF_OPS="$REPO_ROOT/$FIXD/fcm-diff-operations.tsv"
fcm_run "$VERIFY" fcm-operations-module.md "$DIFF_OPS"; J_OPS="$FCM_JSON"
case "$(observed_of "$J_OPS" FCM-1)" in
  declared-add-delivered:operations/*)
    ok "A12 FIRST-SEGMENT ENUM — an operations/ ADD is recognised and graded" ;;
  *) bad "A12 expected declared-add-delivered:operations/…, got '$(observed_of "$J_OPS" FCM-1)'" ;;
esac

# --- A13: a row the recogniser CANNOT read is disclosed, never discarded. ---
# The durable half of the same defect. `ops-runbook.md` carries no directory
# segment, so no enum entry recognises it; it must surface in `uninterpreted`
# instead of leaving the denominator. Paired with its specificity control below,
# because a count that the all-recognised fixture also produces is a broken
# harness rather than a finding.
case "$(observed_of "$J_OPS" FCM-COVERAGE)" in
  *uninterpreted:1*|*uninterpreted=1*)
    ok "A13 UNRECOGNISED-PATH DISCLOSURE — an unreadable row is COUNTED, not dropped" ;;
  *) bad "A13 expected uninterpreted=1, got '$(observed_of "$J_OPS" FCM-COVERAGE)'" ;;
esac
[ "$(verdict_of "$J_OPS" FCM-COVERAGE)" = SKIP ] \
  && ok "A13 an unreadable row makes coverage NON-PASS (silence must not read as full coverage)" \
  || bad "A13 expected coverage SKIP, got '$(verdict_of "$J_OPS" FCM-COVERAGE)'"
case "$(observed_of "$J_PRESENT" FCM-COVERAGE)" in
  *uninterpreted=0*)
    ok "A13 SPECIFICITY CONTROL — a fully-recognised matrix reports uninterpreted=0 (count is not stuck-on)" ;;
  *) bad "A13 control — fcm-conformant.md should report uninterpreted=0, got '$(observed_of "$J_PRESENT" FCM-COVERAGE)'" ;;
esac

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

# M14 NARROWS THE ENUM BACK. This is the regression arm the family shipped
# without: `operations` was missing for the whole life of the check and no test
# noticed, because the rows it lost were not merely mis-graded — they were gone,
# and a shorter denominator grades clean. Removing the word must now MOVE A12.
M14="$(mutate m14-enum-narrowed 's/\(core\|operations\|release\|docs/(core|release|docs/')"
mutant_differs "M14 first-segment enum narrowed (operations removed again)" \
      "$M14" fcm-operations-module.md "$DIFF_OPS" FCM-1 "declared-add-delivered:operations/"
# THE TWO ARMS THAT KILL THIS MUTANT are the FCM-1 arm above (the observed value
# stops reading `declared-add-delivered:operations/`) and the coverage-COUNT arm
# immediately below (uninterpreted moves 1 -> 3). Between them M14 is not a
# spelling test. Narrowing the enum is a stand-in for the NEXT top-level module
# nobody adds; under the shipped tool that omission was invisible — the rows left
# the denominator and coverage read PASS. It must now be DISCLOSED instead: all
# three fixture rows become unreadable, and the COUNT is what has to say so.
fcm_run "$M14" fcm-operations-module.md "$DIFF_OPS"; J_M14="$FCM_JSON"
case "$(observed_of "$J_M14" FCM-COVERAGE)" in
  *declared=3*uninterpreted=3*)
    ok "M14 NEXT-OMISSION VISIBILITY (discriminating arm) — an unknown module is COUNTED (declared=3 uninterpreted=3, up from 1 live), not silently dropped" ;;
  *) bad "M14 expected declared=3 uninterpreted=3 under the narrowed enum, got '$(observed_of "$J_M14" FCM-COVERAGE)'" ;;
esac
# NON-DISCRIMINATING INVARIANT — kept deliberately, and labelled so no reader
# mistakes it for the arm doing the work. This comment previously read "THE ARM
# THAT MATTERS", and that was false: fcm-operations-module.md's third row
# (`ops-runbook.md`) carries no directory segment, so coverage is pinned non-PASS
# by the FIXTURE regardless of the enum — A13 above asserts exactly that SKIP on
# the UNMUTATED tool, which is the same measurement this arm makes. It therefore
# holds identically with and without the mutation and cannot fail here, so it
# proves nothing about the enum. Retained as a standing invariant (coverage must
# never reach a clean PASS while a module is unreadable) rather than deleted,
# because the invariant is still worth asserting — it is simply not the kill.
# Demoted at Stage 6; the kill belongs to the two arms above.
[ "$(verdict_of "$J_M14" FCM-COVERAGE)" != PASS ] \
  && ok "M14 INVARIANT (not discriminating — see note) — the narrowed enum still cannot reach a clean PASS" \
  || bad "M14 coverage reached a clean PASS with an entire module unreadable"

# M15 RESTORES THE DROP. The enum arm above only proves one word is present; this
# proves the drop-to-nowhere behaviour itself is observed. With the discard back,
# the unreadable row leaves the population and the coverage record reports a
# CONFIDENT count over a denominator that lost it — no ERROR, no FAIL, just a
# smaller true-looking number. That is the defect class, so the arm reads the
# coverage record rather than any single row.
M15="$(mutate m15-drop-unrecognized \
      's/key = s; gsub\(\/\\t\/, " ", key\)/next/' \
      's/printf "%s\\t%s\\t%s\\t%s\\t%s\\n", key, "unknown", "uncond", "fence-unrecognized-path", s/next/')"
fcm_run "$M15" fcm-operations-module.md "$DIFF_OPS"; J_M15="$FCM_JSON"
case "$(observed_of "$J_M15" FCM-COVERAGE)" in
  *uninterpreted=0*)
    ok "M15 SILENT-DROP DEMO — with the discard restored the unreadable row VANISHES and coverage reads clean" ;;
  *) bad "M15 SURVIVED — the unreadable row is still counted: '$(observed_of "$J_M15" FCM-COVERAGE)'" ;;
esac
# CONTROL. An empty record satisfies the case above for the wrong reason: nothing
# absent is more absent than a run that never happened. Assert the mutant still
# GRADED the fixture, so M15 discriminates the drop from a broken mutation.
case "$(observed_of "$J_M15" FCM-1)" in
  declared-add-delivered:operations/*)
    ok "M15 CONTROL — the mutant still grades the recognised rows (the mutation removed the drop, not the run)" ;;
  *) bad "M15 NOT GRADEABLE — mutant emitted no operations/ row: '$(observed_of "$J_M15" FCM-1)'" ;;
esac

rm -rf "$MUTD"

# ===========================================================================
# G9 — MARKDOWN PIPE ESCAPE: field parity, and where the escape may be resolved
# G8 — MATCHER COUNT-MODE FIDELITY: a count that cannot be read is not a zero
#
# Both groups exist because a parser produced a CONFIDENT WRONG NUMBER, which is
# the failure mode this suite is least able to notice without a paired control:
# a false FAIL looks like a finding and a false PASS looks like success.
# ===========================================================================
FIX_ESC="release/tools/tests/fixtures/verify-plan-escaped-pipe.md"
FIX_ESCCTL="release/tools/tests/fixtures/verify-plan-escaped-pipe-control.md"
FIX_COUNT="release/tools/tests/fixtures/verify-plan-count-modes.md"

# vrp_run <tool> <fixture-path> — sets VRP_JSON + VRP_RC in the CURRENT shell.
# Deliberately not `$(...)`-capturable, for the same reason fcm_run is not: a
# subshell would assign VRP_RC and discard it, and every exit-code assertion
# below would silently grade a stale 0.
VRP_JSON=""
VRP_RC=0
vrp_run() {
  local tool="$1" fx="$2"
  set +e
  VRP_JSON="$("$tool" --format=json --root "$REPO_ROOT" "$REPO_ROOT/$fx" 2>/dev/null)"
  VRP_RC=$?
  set -e
}
# count_verdict <json> <VERDICT> — how many records carry that verdict.
count_verdict() { grep -c "\"verdict\":\"$2\"" <<<"$1" || true; }

echo
echo "G9 — markdown pipe escape: field parity + resolution boundary"

# --- G9-1..G9-3: the three SPLIT sites heal and their rows execute. ---
vrp_run "$VERIFY" "$FIX_ESC"; J_ESC="$VRP_JSON"; RC_ESC="$VRP_RC"
[ "$(verdict_of "$J_ESC" AC-1)" = PASS ] \
  && ok "G9-1 Verification-Plan table: an escaped-pipe row heals to its header's field count and executes" \
  || bad "G9-1 expected PASS for the escaped VP row, got '$(verdict_of "$J_ESC" AC-1)'"
[ "$(verdict_of "$J_ESC" AC-2)" = PASS ] \
  && ok "G9-2 ROW-LEVEL CONTROL — the unescaped row in the same table is unaffected" \
  || bad "G9-2 expected PASS for the unescaped sibling row, got '$(verdict_of "$J_ESC" AC-2)'"
[ "$(verdict_of "$J_ESC" CIAC-2)" = PASS ] \
  && ok "G9-3 CIAC table form: the same heal applies at the second split site" \
  || bad "G9-3 expected PASS for the escaped CIAC table row, got '$(verdict_of "$J_ESC" CIAC-2)'"

# --- G9-4/5/6: the parity guard is an ERROR, is attributable, and is observed. ---
[ "$(verdict_of "$J_ESC" ROW)" = ERROR ] \
  && ok "G9-4 PARITY GUARD — an UNESCAPED bare pipe is ERROR, not a verdict read at shifted indices" \
  || bad "G9-4 expected ERROR for the malformed row, got '$(verdict_of "$J_ESC" ROW)'"
case "$(observed_of "$J_ESC" ROW)" in
  *table-row-field-parity*fields=7*header=6*)
    ok "G9-5 the parity ERROR is ATTRIBUTABLE — it names both field counts" ;;
  *) bad "G9-5 parity ERROR does not carry its field counts: '$(observed_of "$J_ESC" ROW)'" ;;
esac
[ "$RC_ESC" -eq 3 ] \
  && ok "G9-6 the parity ERROR reaches the exit predicate (exit 3)" \
  || bad "G9-6 expected exit 3 on the malformed row, got $RC_ESC"

# --- G9-7..G9-9: the CONTROL TWIN. Without this the group proves only that the
#     parser became permissive, not that it became correct. ---
vrp_run "$VERIFY" "$FIX_ESCCTL"; J_CTL="$VRP_JSON"; RC_CTL="$VRP_RC"
[ "$(count_verdict "$J_CTL" ERROR)" -eq 0 ] \
  && ok "G9-7 CONTROL TWIN — the escape-free twin raises ZERO errors (the guard is inert without its trigger)" \
  || bad "G9-7 control twin raised $(count_verdict "$J_CTL" ERROR) ERROR record(s); the guard fires on clean input"
[ "$(count_verdict "$J_CTL" FAIL)" -eq 0 ] \
  && ok "G9-8 CONTROL TWIN — and zero failures" \
  || bad "G9-8 control twin raised $(count_verdict "$J_CTL" FAIL) FAIL record(s)"
[ "$RC_CTL" -eq 0 ] && ok "G9-9 CONTROL TWIN exits 0" || bad "G9-9 control twin expected exit 0, got $RC_CTL"

# --- G9-10: THE RESOLUTION BOUNDARY. The escape is resolved by the SPLITTER, at
#     the point a split created it — never on a string that was never split.
#     A scaffold bullet is line-based, so a `\|` inside one is matcher syntax,
#     not markdown, and under a BRE matcher it is the alternation operator.
#     Resolving it there was implemented and then falsified against the corpus:
#     of the 5 CIAC bullet methods carrying `\|`, 4 are BRE alternations and the
#     5th deliberately matches a literal pipe — all 5 broke. This arm is what
#     catches the substitution being re-introduced.
[ "$(verdict_of "$J_ESC" CIAC-1)" = PASS ] \
  && ok "G9-10 BULLET PASSTHROUGH — a BRE alternation in a bullet reaches the matcher byte-intact" \
  || bad "G9-10 the bullet's escaped pipe was rewritten before it reached the matcher, got '$(verdict_of "$J_ESC" CIAC-1)'"

# --- G9-R: NON-SYNTHETIC replay against a live corpus plan. ---
REALESC="release/releases/plans/v4/v4.07_RELEASE_PLAN.md"
if [ ! -f "$REPO_ROOT/$REALESC" ]; then
  bad "G9-R PRECONDITION — replay target absent: $REALESC (relocated or renamed? the arm below cannot grade)"
else
  # DENOMINATOR FIRST. An escaped-pipe replay over a plan carrying no escaped
  # pipe is vacuous, and a vacuous arm that reports "ok" is worse than no arm.
  ESC_LINES="$(grep -cF '\|' "$REPO_ROOT/$REALESC" || true)"
  printf '       replay: %s carries %s escaped-pipe line(s)\n' "$REALESC" "$ESC_LINES"
  if [ "$ESC_LINES" -lt 1 ]; then
    bad "G9-R VACUOUS — the replay target carries no escaped pipe; this arm asserts nothing"
  else
    vrp_run "$VERIFY" "$REALESC"; J_REAL="$VRP_JSON"
    REAL_RECORDS="$(grep -c '"verdict":"' <<<"$J_REAL" || true)"
    REAL_PARITY="$(grep -c 'table-row-field-parity' <<<"$J_REAL" || true)"
    printf '       replay: records=%s parity-errors=%s\n' "$REAL_RECORDS" "$REAL_PARITY"
    [ "$REAL_RECORDS" -ge 1 ] \
      && ok "G9-R the replay actually graded the plan (records=$REAL_RECORDS, not a silent no-parse)" \
      || bad "G9-R the replay produced no records at all; nothing was graded"
    [ "$REAL_PARITY" -eq 0 ] \
      && ok "G9-R NON-SYNTHETIC — every escaped row on a live plan heals to header parity (0 parity errors)" \
      || bad "G9-R $REAL_PARITY row(s) on a live plan still fail field parity after healing"
  fi
fi

echo
echo "G8 — matcher count-mode fidelity + absence-vs-zero"

vrp_run "$VERIFY" "$FIX_COUNT"; J_CNT="$VRP_JSON"; RC_CNT="$VRP_RC"
# G8-1/G8-2 are the CONTROLS: these two shapes returned the right answer before
# the fix and must still return it, so a green match-mode arm is evidence of a
# repair rather than of a counter that now reports whatever is needed.
[ "$(verdict_of "$J_CNT" AC-1)" = PASS ] \
  && ok "G8-1 CONTROL — count mode, single file (grep -c) still reads a genuine count" \
  || bad "G8-1 expected PASS, got '$(verdict_of "$J_CNT" AC-1)'"
[ "$(verdict_of "$J_CNT" AC-2)" = PASS ] \
  && ok "G8-2 CONTROL — count mode, multi-file (path:n per line) still sums correctly" \
  || bad "G8-2 expected PASS, got '$(verdict_of "$J_CNT" AC-2)'"
[ "$(verdict_of "$J_CNT" AC-3)" = PASS ] \
  && ok "G8-3 match mode (grep -n): real hits are counted, not coerced to 0 by trailing text" \
  || bad "G8-3 expected PASS for the grep -n row, got '$(verdict_of "$J_CNT" AC-3)'"
[ "$(verdict_of "$J_CNT" AC-4)" = PASS ] \
  && ok "G8-4 match mode (plain grep): matching LINES are the hit count" \
  || bad "G8-4 expected PASS for the plain-grep row, got '$(verdict_of "$J_CNT" AC-4)'"

# G8-5/G8-6 — THE FALSE PASS. A matcher exiting 2 produced empty output, a
# fabricated count of 0, and an "expect zero" criterion rendering PASS: a silent
# false pass inside the tool that grades the release's own verification plan.
[ "$(verdict_of "$J_CNT" AC-5)" = ERROR ] \
  && ok "G8-5 FALSE PASS CLOSED — an unreadable target is ERROR, and an expect-zero criterion no longer PASSes on it" \
  || bad "G8-5 expected ERROR for the unreadable-target row, got '$(verdict_of "$J_CNT" AC-5)' (a false PASS is back)"
case "$(observed_of "$J_CNT" AC-5)" in
  *matcher-exit-2*) ok "G8-6 the error NAMES the exit status that produced it" ;;
  *) bad "G8-6 the error does not name the matcher exit status: '$(observed_of "$J_CNT" AC-5)'" ;;
esac
[ "$RC_CNT" -eq 3 ] && ok "G8-7 the count ERROR reaches the exit predicate (exit 3)" || bad "G8-7 expected exit 3, got $RC_CNT"

# --- Unit arms on the shared reader, extracted from the shipped file. ---
eval "$(sed -n '/^tokenize_cmd()/,/^}/p'      "$VERIFY")"
eval "$(sed -n '/^count_mode_cmd()/,/^}/p'    "$VERIFY")"
eval "$(sed -n '/^count_from_output()/,/^}/p' "$VERIFY")"

if count_mode_cmd "grep -c x f" && count_mode_cmd "grep -cE x f" \
   && count_mode_cmd "grep -rc x f" && count_mode_cmd "grep --count x f"; then
  ok "G8-8 count mode is detected from every flag shape (-c, -cE, -rc, --count)"
else
  bad "G8-8 count mode missed one of the flag shapes (-c / -cE / -rc / --count)"
fi
# CONTROL — without this, a detector that simply returns true always would pass.
if ! count_mode_cmd "grep -n x f" && ! count_mode_cmd "grep -i x f" && ! count_mode_cmd "grep x f"; then
  ok "G8-9 CONTROL — match-mode invocations are NOT read as count mode (the detector discriminates)"
else
  bad "G8-9 the count-mode detector fires on a match-mode invocation; it is stuck on"
fi
[ "$(count_from_output 'grep -c x f' '' 2   | cut -f1)" = ERROR ] \
  && ok "G8-10 exit >= 2 is an ERROR regardless of output (the matcher could not run)" \
  || bad "G8-10 an exit-2 matcher did not produce ERROR"
[ "$(count_from_output 'grep -c x f' '0' 1  | cut -f2)" = "0" ] \
  && ok "G8-11 CONTROL — exit 1 is a LEGITIMATE zero, not an error (absence and failure stay distinct)" \
  || bad "G8-11 exit 1 was not treated as a legitimate zero"
[ "$(count_from_output 'grep -c x a b' 'a:3
b:4' 0 | cut -f2)" = "7" ] \
  && ok "G8-12 count mode sums the last colon field across files (3 + 4 = 7)" \
  || bad "G8-12 count mode did not sum multi-file counts"
[ "$(count_from_output 'grep -n x f' '12:some trailing prose
19:more prose' 0 | cut -f2)" = "2" ] \
  && ok "G8-13 match mode counts LINES — the shape that used to sum prose to 0" \
  || bad "G8-13 match mode did not count lines"
[ "$(count_from_output 'grep -c x f' 'not-a-number' 0 | cut -f1)" = ERROR ] \
  && ok "G8-14 a non-integer count field is an ERROR, never a silent 0" \
  || bad "G8-14 a non-integer count field was coerced instead of raising ERROR"

# ===========================================================================
# G9-M / G8-M — MUTATION ARMS.
#
# Each arm reverts ONE fix and asserts the paired assertion CHANGES ITS ANSWER.
# Every arm first proves the mutation TOOK: a sed that matches nothing yields a
# byte-identical copy, the arm reads green, and it has tested nothing. That is
# not hypothetical — it is the failure this release caught four separate times,
# including a mutation arm that was green while never mutating anything.
# ===========================================================================
echo
echo "G9-M / G8-M — mutation arms (each reverts one fix; each proves it took)"
MUTD2="$(mktemp -d -t verify-plan-esc-mut.XXXXXX)"

# mutate_proved <name> <sed-expr>... — mutate the tool, ASSERT THE BYTES MOVED,
# and publish the mutant path in the global MUT_PATH.
#
# It sets a GLOBAL rather than printing the path, and that is not a style choice.
# Printing it would force every caller to use `$(...)`, which (a) runs the
# function in a subshell where the ok/bad counters are incremented and then
# discarded, and (b) captures the ok/bad TEXT into the path string, so the
# "mutant" the caller then executes is not a file at all. Every arm downstream
# would grade an empty result — and three of the arms below assert "the verdict
# is no longer PASS", which an empty result satisfies. That is a vacuous green:
# the arm passes precisely because the mutation never ran. This was caught by the
# two arms whose assertion names a SPECIFIC expected value instead of a negation,
# which is why every arm below now does both: it requires the mutant to have
# produced output, and then names what the answer must become.
MUT_PATH=""
mutate_proved() {
  local name="$1"; shift
  local dst="$MUTD2/$name.sh" e
  cp "$VERIFY" "$dst"
  for e in "$@"; do sed -i.bak -E "$e" "$dst"; done
  rm -f "$dst.bak"
  chmod +x "$dst"
  MUT_PATH="$dst"
  if cmp -s "$VERIFY" "$dst"; then
    bad "$name — MUTATION DID NOT TAKE (mutant is byte-identical); the paired arm would pass vacuously"
  else
    ok "$name — mutation applied (mutant bytes differ from the shipped tool)"
  fi
}

# mutant_ran <label> — assert the mutant actually produced a graded record set.
# Absence of a verdict is not evidence that a verdict changed.
mutant_ran() {
  if [ -n "$(grep -c '"verdict":"' <<<"$VRP_JSON" || true)" ] && grep -q '"verdict":"' <<<"$VRP_JSON"; then
    return 0
  fi
  bad "$1 NOT GRADEABLE — the mutant emitted no records at all; nothing was measured"
  return 1
}

# G9-M1 — revert the heal: the re-join never fires, so the splitter is a plain
# split on `|` again and the escaped row mis-parses.
PARITY_LIVE="$(grep -c 'table-row-field-parity' <<<"$J_ESC" || true)"
mutate_proved g9-m1-no-heal 's/bs % 2 == 1 && i < m/0 == 1/'
vrp_run "$MUT_PATH" "$FIX_ESC"
if mutant_ran "G9-M1"; then
  PARITY_MUT="$(grep -c 'table-row-field-parity' <<<"$VRP_JSON" || true)"
  printf '       g9-m1: parity errors with the heal = %s ; without it = %s\n' "$PARITY_LIVE" "$PARITY_MUT"
  [ "$PARITY_MUT" -gt "$PARITY_LIVE" ] \
    && ok "G9-M1 heal reverted — correctly-escaped rows now break field parity ($PARITY_LIVE -> $PARITY_MUT)" \
    || bad "G9-M1 SURVIVED — removing the re-join changed no parity count ($PARITY_LIVE -> $PARITY_MUT); G9-1 observes nothing"
fi

# G9-M2 — revert the parity guard: the malformed row is parsed at shifted
# indices again instead of being named.
mutate_proved g9-m2-no-parity-guard 's/hdr_n > 0 && n != hdr_n/0 == 1/g'
vrp_run "$MUT_PATH" "$FIX_ESC"
if mutant_ran "G9-M2"; then
  G9M2_PARITY="$(grep -c 'table-row-field-parity' <<<"$VRP_JSON" || true)"
  printf '       g9-m2: parity errors with the guard = %s ; without it = %s\n' "$PARITY_LIVE" "$G9M2_PARITY"
  [ "$G9M2_PARITY" -eq 0 ] && [ "$PARITY_LIVE" -ge 1 ] \
    && ok "G9-M2 parity guard reverted — the malformed row stops being named and is parsed at shifted indices again" \
    || bad "G9-M2 SURVIVED — parity errors went $PARITY_LIVE -> $G9M2_PARITY with the guard removed; G9-4 observes nothing"
fi

# G9-M3 — revert the per-table-block column reset. A markdown table ends at the
# first non-table line, so its column map must end with it. Without the reset the
# map is STICKY and a later PROSE table in the same section is parsed as check
# rows at the earlier table's column index — cells read against a header that is
# not theirs, which is the same defect as the escaped split one level up.
STICKY_FIX="$(mktemp -t verify-plan-sticky.XXXXXX.md)"
cat > "$STICKY_FIX" <<'EOF'
# vTEST sticky-column-map plan

## Verification Plan

**#931 — a real check table**

| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | file-path+state | `test -f release/tools/verify-release-plan.sh` | exists |

A prose evidence table follows, in the same section. It declares no Verification
method column, so it must not be graded as if it did.

| Field | Value |
|---|---|
| Denominator | 224 issues read at a pinned anchor |
| Partition | F1 123 / F2 39 / F3 62 |
EOF
set +e
STICKY_LIVE="$("$VERIFY" --format=json --root "$REPO_ROOT" "$STICKY_FIX" 2>/dev/null)"
set -e
STICKY_LIVE_N="$(grep -c '"verdict":"' <<<"$STICKY_LIVE" || true)"
mutate_proved g9-m3-sticky-columns 's/\{ reset_cols\(\); next \}/{ next }/'
set +e
STICKY_MUT="$("$MUT_PATH" --format=json --root "$REPO_ROOT" "$STICKY_FIX" 2>/dev/null)"
set -e
STICKY_MUT_N="$(grep -c '"verdict":"' <<<"$STICKY_MUT" || true)"
rm -f "$STICKY_FIX"
printf '       sticky: records with the reset = %s ; without it = %s\n' "$STICKY_LIVE_N" "$STICKY_MUT_N"
[ "$STICKY_MUT_N" -gt "$STICKY_LIVE_N" ] \
  && ok "G9-M3 per-table-block reset reverted — the prose table is graded as checks again ($STICKY_LIVE_N -> $STICKY_MUT_N records)" \
  || bad "G9-M3 SURVIVED — removing the reset changed no record count ($STICKY_LIVE_N -> $STICKY_MUT_N); the reset observes nothing"

# G8-M1 — revert count-mode discrimination: every matcher is read as match mode,
# so `grep -c`'s single integer line counts as one hit.
mutate_proved g8-m1-no-count-mode 's/if count_mode_cmd "\$cmd"; then/if false; then/'
vrp_run "$MUT_PATH" "$FIX_COUNT"
if mutant_ran "G8-M1"; then
  G8M1_GOT="$(verdict_of "$VRP_JSON" AC-1)"
  [ "$G8M1_GOT" = FAIL ] \
    && ok "G8-M1 count-mode detection reverted — grep -c's single integer line is miscounted as one hit, so a real count FAILs" \
    || bad "G8-M1 SURVIVED — with its detector removed the count still reads correctly (got '$G8M1_GOT'); G8-1 observes nothing"
fi

# G8-M2 — THE DECISIVE ARM. Revert the unconditional exit-status guard and the
# false PASS must come back. If this arm cannot re-open the false pass, the guard
# was never what was closing it.
mutate_proved g8-m2-no-exit-guard 's/if \[ "\$rc" -ge 2 \]; then/if false; then/'
vrp_run "$MUT_PATH" "$FIX_COUNT"
if mutant_ran "G8-M2"; then
  G8M2_GOT="$(verdict_of "$VRP_JSON" AC-5)"
  [ "$G8M2_GOT" = PASS ] \
    && ok "G8-M2 exit-status guard reverted — THE FALSE PASS RETURNS (expect-zero PASSes on a matcher that exited 2)" \
    || bad "G8-M2 SURVIVED — removing the exit guard did not restore the false PASS, so G8-5 is not what closes it (got '$G8M2_GOT')"
  [ "$VRP_RC" -eq 0 ] \
    && ok "G8-M2 CONTROL — and the neutered build exits 0, so the false PASS reaches the roll-up too" \
    || bad "G8-M2 control — the neutered build still exits $VRP_RC"
fi

rm -rf "$MUTD2"

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
# G10 — #6383: the header-trap regression arm, the runtime-suite verdict floor,
#       the roll-up denominator, and declared-not-inferred FCM intent.
#
# Four properties, each with a seeded failure that MUST flip it:
#   (H)  a data row carrying schema vocabulary is indexed as DATA — the arm the
#        already-landed positional header fix shipped WITHOUT.
#   (R)  handle_runtime_suite cannot return PASS, and the retired keyword route
#        can no longer steal an executable row from the family that runs it.
#   (D)  the verdict roll-up carries the denominator its counts were taken over.
#   (V)  FCM intent is the FIRST verb token of the path-stripped declaration;
#        annotation prose and filename segments decide nothing.
# ---------------------------------------------------------------------------
echo
echo "G10 — #6383: header trap · runtime floor · roll-up denominator · declared intent"

FIX_TRAP="release/tools/tests/fixtures/verify-plan-header-trap.md"
FIX_TRAPCTL="release/tools/tests/fixtures/verify-plan-header-trap-control.md"
FIX_HIJACK="release/tools/tests/fixtures/verify-plan-runtime-hijack.md"
FIX_NOTABLE="release/tools/tests/fixtures/verify-plan-no-table.md"

# rows_of <json> — the roll-up denominator. acs_of <json> — emitted AC-N records.
# sigpipe-idiom: allow — `sed`, not the here-string, is the signallable producer: the here-string feeds `sed`, and `sed` writes into the pipe `head -1` closes. Safe on SIZE, not on shape — the extracted field list is a few short lines, far under the pipe buffer, so `sed` writes it all and exits before `head` closes the read end.
rows_of() { sed -n 's/.*"per_issue_rows": \([0-9]*\).*/\1/p' <<<"$1" | head -1; }
acs_of()  { grep -c '"id":"AC-' <<<"$1" || true; }

MUTD3="$(mktemp -d -t verify-plan-6383-mut.XXXXXX)"
m6383() {
  local name="$1"; shift
  local dst="$MUTD3/$name.sh" e
  cp "$VERIFY" "$dst"
  for e in "$@"; do sed -i.bak -E "$e" "$dst"; done
  rm -f "$dst.bak"
  chmod +x "$dst"
  MUT_PATH="$dst"
  if cmp -s "$VERIFY" "$dst"; then
    bad "$name — MUTATION DID NOT TAKE (mutant is byte-identical); the paired arm would pass vacuously"
  else
    ok "$name — mutation applied (mutant bytes differ from the shipped tool)"
  fi
}

# --- H: the header trap. THE ARM 94dcadb7 SHIPPED WITHOUT. -------------------
vrp_run "$VERIFY" "$FIX_TRAP";    J_TRAP="$VRP_JSON"
vrp_run "$VERIFY" "$FIX_TRAPCTL"; J_TRAPC="$VRP_JSON"
R_TRAP="$(rows_of "$J_TRAP")"; R_TRAPC="$(rows_of "$J_TRAPC")"
A_TRAP="$(acs_of "$J_TRAP")";  A_TRAPC="$(acs_of "$J_TRAPC")"

# H-0 is the arm that stops H-1 from being 0 == 0. Two files that both parsed to
# nothing would "agree" perfectly, which is the vacuity this group exists to
# refuse. Assert the population is non-empty BEFORE asserting the pair matches.
[ "${R_TRAP:-0}" -eq 4 ] \
  && ok "H-0 SENSITIVITY — the trap fixture indexes all 4 of its data rows (the pair below is not 0 == 0)" \
  || bad "H-0 expected 4 indexed rows in the trap fixture, got '${R_TRAP:-<none>}'"
[ "$R_TRAP" = "$R_TRAPC" ] \
  && ok "H-1 a data cell carrying predicate / expected / verification method is indexed as DATA (trap $R_TRAP == control $R_TRAPC)" \
  || bad "H-1 trap indexed $R_TRAP rows, control indexed $R_TRAPC — a trap row was consumed as a header"
[ "$A_TRAP" = "$A_TRAPC" ] && [ "${A_TRAP:-0}" -eq 4 ] \
  && ok "H-2 every indexed trap row also EMITS a record ($A_TRAP == $A_TRAPC) — nothing vanished after indexing" \
  || bad "H-2 emitted AC records differ: trap $A_TRAP vs control $A_TRAPC (expected 4 each)"

# H-M — SEEDED FAILURE. Revert the positional anchor so every row is header
# eligible again. Only the TRAP fixture loses rows, so the PAIR separates; that
# separation is what proves H-1 observes the fix rather than the fixture.
m6383 g10-m1-header-not-positional 's/if \(block_row == 1\) \{/if (block_row >= 1) {/'
vrp_run "$MUT_PATH" "$FIX_TRAP";    JM_TRAP="$VRP_JSON"
vrp_run "$MUT_PATH" "$FIX_TRAPCTL"; JM_TRAPC="$VRP_JSON"
MR_TRAP="$(rows_of "$JM_TRAP")"; MR_TRAPC="$(rows_of "$JM_TRAPC")"
[ "$MR_TRAP" != "$MR_TRAPC" ] \
  && ok "H-M mutation detected — with the positional anchor reverted the pair separates (trap $MR_TRAP vs control $MR_TRAPC)" \
  || bad "H-M SURVIVED — trap and control still agree at $MR_TRAP with the anchor reverted; H-1 observes nothing"
[ "${MR_TRAPC:-0}" -eq 4 ] \
  && ok "H-M CONTROL — the mutation costs the control fixture nothing (still 4); the loss is attributable to the trap vocabulary" \
  || bad "H-M control — the control fixture also moved to '${MR_TRAPC:-<none>}'; the mutation is not isolating the trap"

# --- R: the runtime-suite verdict floor + the retired keyword route ----------
vrp_run "$VERIFY" "$FIX_HIJACK"; J_HJ="$VRP_JSON"; RC_HJ="$VRP_RC"

# R-0 STRUCTURAL. "Cannot return PASS without an executed check" is checkable at
# the source: the function performs no execution, so PASS must not be reachable
# from its body at all. The sensitivity arm runs the SAME extractor over
# handle_per_issue, which does return PASS — without it, a broken extractor
# would report a clean zero.
RS_BODY="$(awk '/^handle_runtime_suite\(\) \{/,/^\}/' "$VERIFY")"
PI_BODY="$(awk '/^handle_per_issue\(\) \{/,/^\}/' "$VERIFY")"
RS_HITS="$(grep -c 'VERDICT_PASS' <<<"$RS_BODY" || true)"
PI_HITS="$(grep -c 'VERDICT_PASS' <<<"$PI_BODY" || true)"
[ "${PI_HITS:-0}" -gt 0 ] \
  && ok "R-0 SENSITIVITY — the body extractor finds VERDICT_PASS in handle_per_issue ($PI_HITS); a zero below is a real absence" \
  || bad "R-0 the extractor found no VERDICT_PASS in handle_per_issue either — it is broken, and R-0 would pass vacuously"
[ "${RS_HITS:-0}" -eq 0 ] \
  && ok "R-0 handle_runtime_suite cannot return PASS — VERDICT_PASS does not appear in its body" \
  || bad "R-0 VERDICT_PASS appears $RS_HITS time(s) in handle_runtime_suite; the family can fabricate a pass again"

# R-1 THE HIJACK. AC-1 and AC-2 carry the SAME grep command; AC-2 merely says
# "Exercise the register" first. Before the fix AC-1 executed and AC-2 did not.
[ "$(family_of "$J_HJ" AC-1)" = "per-issue" ] && [ "$(family_of "$J_HJ" AC-2)" = "per-issue" ] \
  && ok "R-1 an executable row is not stolen by prose — bare and Exercise-prefixed both classify per-issue" \
  || bad "R-1 families differ: AC-1 '$(family_of "$J_HJ" AC-1)' vs AC-2 '$(family_of "$J_HJ" AC-2)'"
[ "$(verdict_of "$J_HJ" AC-1)" = "PASS" ] && [ "$(verdict_of "$J_HJ" AC-2)" = "PASS" ] \
  && ok "R-1b both rows EXECUTE and agree (PASS / PASS) — the earned verdict and the once-fabricated one now coincide honestly" \
  || bad "R-1b verdicts differ: AC-1 '$(verdict_of "$J_HJ" AC-1)' vs AC-2 '$(verdict_of "$J_HJ" AC-2)'"

# R-2 THE CARD AC. A method carrying `exercise`, no fail-word and no executable
# probe must not report PASS. It reaches `unclassified`, which is an ERROR: this
# executor genuinely cannot tell what the row is asking for, and saying so is
# the honest answer. Never a fabricated green.
[ "$(verdict_of "$J_HJ" AC-3)" != "PASS" ] \
  && ok "R-2 an 'exercise' method with no fail-word and no probe is NOT PASS (got '$(verdict_of "$J_HJ" AC-3)')" \
  || bad "R-2 an 'exercise' method still reports PASS — the fabricated-verdict path is open"

# R-3 THE SURVIVING ROUTE. A declared test-run subtype still reaches the family,
# floored at SKIP; a declared failure still FAILs. Without R-3 the retirement
# would have silently orphaned the handler, which is the same vacuity one level
# over: a floor on a family nothing can reach holds nothing down.
[ "$(family_of "$J_HJ" AC-4)" = "runtime-suite" ] && [ "$(verdict_of "$J_HJ" AC-4)" = "SKIP" ] \
  && ok "R-3 a declared suite-skip still reaches the family and is floored at SKIP" \
  || bad "R-3 AC-4 expected runtime-suite/SKIP, got '$(family_of "$J_HJ" AC-4)'/'$(verdict_of "$J_HJ" AC-4)'"
[ "$(family_of "$J_HJ" AC-5)" = "runtime-suite" ] && [ "$(verdict_of "$J_HJ" AC-5)" = "FAIL" ] \
  && ok "R-3b a declared suite-fail still FAILs — the floor does not swallow a recorded failure" \
  || bad "R-3b AC-5 expected runtime-suite/FAIL, got '$(family_of "$J_HJ" AC-5)'/'$(verdict_of "$J_HJ" AC-5)'"
[ "$RC_HJ" -eq 3 ] \
  && ok "R-3c the FAIL and the ERROR reach the exit predicate (exit 3)" \
  || bad "R-3c expected exit 3 from the hijack fixture, got $RC_HJ"

# R-M1 — SEEDED FAILURE on the floor. Raise it and R-2 must flip.
m6383 g10-m2-floor-raised 's|"\$VERDICT_SKIP" "test-run/\$subtype \(not executed|"$VERDICT_PASS" "test-run/$subtype (not executed|'
vrp_run "$MUT_PATH" "$FIX_HIJACK"; JM_HJ="$VRP_JSON"
[ "$(verdict_of "$JM_HJ" AC-4)" = "PASS" ] \
  && ok "R-M1 mutation detected — with the floor raised the declared suite-skip fabricates a PASS again" \
  || bad "R-M1 SURVIVED — AC-4 is '$(verdict_of "$JM_HJ" AC-4)' with the floor raised; R-3 observes nothing"

# R-M2 — SEEDED FAILURE on the retired route. Re-insert the prose keyword arm
# ABOVE the executable arm, which is exactly the shape that stole the row, and
# R-1 must flip. Position is the defect, so the mutation restores the position.
m6383 g10-m3-keyword-route-restored 's#^    \*grep\*#    *runtime*suite*|*test-run*|*dispatch*the*runtime*|*suite-*|*exercise*) echo "runtime-suite"; return ;;\
    *grep*#'
vrp_run "$MUT_PATH" "$FIX_HIJACK"; JM_HJ2="$VRP_JSON"
[ "$(family_of "$JM_HJ2" AC-1)" = "per-issue" ] && [ "$(family_of "$JM_HJ2" AC-2)" = "runtime-suite" ] \
  && ok "R-M2 mutation detected — with the keyword route restored above the executable arm, AC-2 is stolen again while AC-1 is not" \
  || bad "R-M2 SURVIVED — AC-1 '$(family_of "$JM_HJ2" AC-1)' / AC-2 '$(family_of "$JM_HJ2" AC-2)'; R-1 observes nothing"

# --- D: the roll-up denominator ---------------------------------------------
vrp_run "$VERIFY" "$FIX_NOTABLE"; J_NT="$VRP_JSON"; RC_NT="$VRP_RC"
R_NT="$(rows_of "$J_NT")"

# THE CARD AC: run against a plan WITH a per-issue table and one WITHOUT, and
# observe DIFFERENT denominators. Both report 0 ERROR, which is precisely why
# the error count alone was never interpretable.
[ "${R_NT:-x}" = "0" ] && [ "${R_TRAP:-0}" -gt 0 ] && [ "$R_NT" != "$R_TRAP" ] \
  && ok "D-1 a plan with a per-issue table and one without report DIFFERENT denominators ($R_TRAP vs $R_NT)" \
  || bad "D-1 denominators did not separate: with-table '$R_TRAP', without-table '${R_NT:-<none>}'"
# sigpipe-idiom: allow — `sed`, not the here-string, is the signallable producer: the here-string feeds `sed`, and `sed` writes into the pipe `head -1` closes. Safe on SIZE, not on shape — the extracted field list is a few short lines, far under the pipe buffer, so `sed` writes it all and exits before `head` closes the read end.
E_NT="$(sed -n 's/.*"error": \([0-9]*\).*/\1/p' <<<"$J_NT" | head -1)"
# sigpipe-idiom: allow — `sed`, not the here-string, is the signallable producer: the here-string feeds `sed`, and `sed` writes into the pipe `head -1` closes. Safe on SIZE, not on shape — the extracted field list is a few short lines, far under the pipe buffer, so `sed` writes it all and exits before `head` closes the read end.
E_TRAP="$(sed -n 's/.*"error": \([0-9]*\).*/\1/p' <<<"$J_TRAP" | head -1)"
[ "$E_NT" = "0" ] && [ "$E_TRAP" = "0" ] \
  && ok "D-1b BOTH report 0 ERROR — which is exactly why 0 ERROR alone was uninterpretable, and why the denominator is the fix" \
  || bad "D-1b expected 0 ERROR from both; got no-table '$E_NT', trap '$E_TRAP'"

# D-2 the markdown render must SAY it found nothing, not merely report a zero.
set +e
MD_NT="$("$VERIFY" --no-color --format=md --root "$REPO_ROOT" "$REPO_ROOT/$FIX_NOTABLE" 2>/dev/null)"
set -e
grep -q 'no per-issue verification table found' <<<"$MD_NT" \
  && ok "D-2 the md roll-up STATES the empty denominator rather than rendering a clean-looking zero" \
  || bad "D-2 the md roll-up does not name the empty denominator: '$(tail -1 <<<"$MD_NT")'"
grep -qE 'over 4 per-issue row\(s\)' <<<"$("$VERIFY" --no-color --format=md --root "$REPO_ROOT" "$REPO_ROOT/$FIX_TRAP" 2>/dev/null)" \
  && ok "D-2b CONTROL — a plan that DOES carry a table renders its row count instead of the empty-denominator statement" \
  || bad "D-2b the with-table md roll-up does not carry its row count"

# D-M — SEEDED FAILURE. Zero the denominator at its source. D-1 must flip.
# ANCHORED ON THE ASSIGNMENT, NOT ITS BODY. The previous form pinned the exact
# pipeline text and silently stopped matching the moment #6234 changed the
# counter — the mutant went byte-identical and the paired arm would have passed
# vacuously. It was caught only because the harness asserts the mutant differs.
m6383 g10-m4-denominator-zeroed 's/^  PER_ISSUE_ROWS=.*$/  PER_ISSUE_ROWS=0/'
vrp_run "$MUT_PATH" "$FIX_TRAP"; JM_TRAP2="$VRP_JSON"
[ "$(rows_of "$JM_TRAP2")" = "0" ] \
  && ok "D-M mutation detected — with the counter zeroed the with-table plan reports the empty-denominator statement too" \
  || bad "D-M SURVIVED — the mutant still reports '$(rows_of "$JM_TRAP2")' rows; D-1 observes nothing"

# --- V: FCM intent is DECLARED, not inferred --------------------------------
fcm_run "$VERIFY" fcm-verbof-trap.md "$DIFF_PRESENT";    J_VTRAP="$FCM_JSON"
fcm_run "$VERIFY" fcm-verbof-control.md "$DIFF_PRESENT"; J_VCTL="$FCM_JSON"

# V-1 THE PAIR. The only variable across these two fixtures is annotation prose.
# Before the fix it moved the assertion onto a DIFFERENT FILE: row 1 (a declared
# EDIT whose note says "add") became an ADD obligation and FAILed, while row 2
# (a declared ADD whose note says "renamed") was classified rename, counted
# excluded, and its obligation vanished with no record at all. Both directions,
# one fixture.
[ "$(observed_of "$J_VTRAP" FCM-1)" = "$(observed_of "$J_VCTL" FCM-1)" ] \
  && ok "V-1 annotation prose cannot move the assertion — trap and control grade the SAME file identically ('$(observed_of "$J_VTRAP" FCM-1)')" \
  || bad "V-1 records diverge: trap '$(observed_of "$J_VTRAP" FCM-1)' vs control '$(observed_of "$J_VCTL" FCM-1)'"
[ "$(verdict_of "$J_VTRAP" FCM-1)" = "PASS" ] && [ "$(verdict_of "$J_VCTL" FCM-1)" = "PASS" ] \
  && ok "V-1b both PASS — the declared EDIT raises no false obligation and the declared ADD is delivered" \
  || bad "V-1b verdicts differ: trap '$(verdict_of "$J_VTRAP" FCM-1)' vs control '$(verdict_of "$J_VCTL" FCM-1)'"

# V-2 THE VACUITY HALF. A declared ADD carrying a rename annotation must be
# COUNTED, never dropped into `excluded`. excluded=0 is the whole assertion:
# an ADD in `excluded` is a declared obligation the gate can never fail on.
case "$(observed_of "$J_VTRAP" FCM-COVERAGE)" in
  *"obligations=1 excluded=0"*) ok "V-2 a declared ADD annotated 'renamed from …' is an OBLIGATION, not an exclusion (obligations=1 excluded=0)" ;;
  *) bad "V-2 coverage expected 'obligations=1 excluded=0', got '$(observed_of "$J_VTRAP" FCM-COVERAGE)'" ;;
esac

# V-3 THE DISCLOSURE. The residual — a row whose winning verb is not its first
# token — is reported rather than errored. The control arm is what makes the
# counter meaningful: it must read 0 on the same two paths and intents.
case "$(observed_of "$J_VTRAP" FCM-COVERAGE)" in
  *prose_led=1*) ok "V-3 the prose-led row is DISCLOSED in the coverage record (prose_led=1), not converted to an ERROR" ;;
  *) bad "V-3 expected prose_led=1 in the trap coverage record, got '$(observed_of "$J_VTRAP" FCM-COVERAGE)'" ;;
esac
case "$(observed_of "$J_VCTL" FCM-COVERAGE)" in
  *prose_led=0*) ok "V-3b CONTROL — the annotation-free twin reads prose_led=0, so the counter tracks prose and not the paths" ;;
  *) bad "V-3b expected prose_led=0 in the control coverage record, got '$(observed_of "$J_VCTL" FCM-COVERAGE)'" ;;
esac

# V-4 SCOPE. A path segment is not a declaration: a bare path whose own slug
# carries the word `edit` is intent-UNDECLARED, and undeclared is counted and
# reported — never silently promoted to an intent the author never wrote.
fcm_run "$VERIFY" fcm-verbof-pathword.md "$DIFF_ABSENT"; J_VPW="$FCM_JSON"
case "$(observed_of "$J_VPW" FCM-COVERAGE)" in
  *"declared=2 interpreted=1"*uninterpreted:1*) ok "V-4 a filename containing 'edit' does not declare an EDIT (declared=2 interpreted=1)" ;;
  *) bad "V-4 coverage expected declared=2 interpreted=1 with uninterpreted:1, got '$(observed_of "$J_VPW" FCM-COVERAGE)'" ;;
esac

# V-M1 — SEEDED FAILURE on POSITION. Restore the enum cascade so ADD is tested
# before EDIT again. V-1 must flip: the assertion moves back onto the wrong file.
m6383 g10-m5-enum-cascade-restored 's/      return firstverb\(u\)/      if (index(u,"ADD")) return "add"; return firstverb(u)/'
fcm_run "$MUT_PATH" fcm-verbof-trap.md "$DIFF_PRESENT"; JM_VTRAP="$FCM_JSON"
[ "$(observed_of "$JM_VTRAP" FCM-1)" != "$(observed_of "$J_VCTL" FCM-1)" ] \
  && ok "V-M1 mutation detected — with ADD tested ahead of position the trap grades a different file ('$(observed_of "$JM_VTRAP" FCM-1)')" \
  || bad "V-M1 SURVIVED — the trap still grades '$(observed_of "$JM_VTRAP" FCM-1)' with the cascade restored; V-1 observes nothing"

# V-M2 — SEEDED FAILURE on SCOPE. Stop stripping the declared path and V-4 must
# flip: the filename segment starts declaring an intent again.
m6383 g10-m6-path-not-stripped 's/      u  = toupper\(stripfirst\(s, p\)\)/      u  = toupper(s)/'
fcm_run "$MUT_PATH" fcm-verbof-pathword.md "$DIFF_ABSENT"; JM_VPW="$FCM_JSON"
case "$(observed_of "$JM_VPW" FCM-COVERAGE)" in
  *"declared=2 interpreted=2"*) ok "V-M2 mutation detected — unstripped, the filename segment declares an intent (interpreted 1 -> 2)" ;;
  *) bad "V-M2 SURVIVED — coverage is still '$(observed_of "$JM_VPW" FCM-COVERAGE)' with the path strip removed; V-4 observes nothing" ;;
esac

rm -rf "$MUTD3"

# ===========================================================================
# G11 — #6234: the record format, the header dialects, and the residual ERROR
#
# WHY THIS GROUP EXISTS, AND WHY THE OLD SUITE COULD NOT HAVE CAUGHT IT.
# All five pre-existing verify-plan fixtures carry a literal `AC` column — 10 of
# 10 indexed blocks — so the entire fixture corpus was drawn from the population
# that is IMMUNE to the empty-field collapse. Worse, the suite's only row-
# addressing primitives (verdict_of / family_of) key on `"id":"AC-N"`, which is
# the exact field the collapse destroys: under it every row reads `id` as the
# literal `PENDING`, so the helpers cannot address a collapsed row even in
# principle. 146 green assertions were structurally blind to this class.
#
# Every fixture below is drawn from the AFFECTED population, and every arm is
# paired with either a control that must NOT move or a seeded failure that must
# flip it.
# ===========================================================================
echo
echo "G11 — #6234: record format, header dialects, and the unindexable residual"

FIX_NOAC="release/tools/tests/fixtures/verify-plan-no-ac.md"
FIX_NOACCTL="release/tools/tests/fixtures/verify-plan-no-ac-control.md"
FIX_NOACNOEXP="release/tools/tests/fixtures/verify-plan-no-ac-no-expected.md"
FIX_MCLASS="release/tools/tests/fixtures/verify-plan-method-class.md"
FIX_CMDCOL="release/tools/tests/fixtures/verify-plan-command-col.md"
FIX_LONGFORM="release/tools/tests/fixtures/verify-plan-longform-method.md"
FIX_UNIDX="release/tools/tests/fixtures/verify-plan-unindexable.md"
FIX_NONVERIF="release/tools/tests/fixtures/verify-plan-nonverif-table.md"
FIX_EMPTYM="release/tools/tests/fixtures/verify-plan-empty-method-cell.md"
FIX_CIACPAR="release/tools/tests/fixtures/verify-plan-ciac-parity.md"

# field_by_issue <json> <issue> <field> — address a record by its ISSUE rather
# than by its id. Required here and not a convenience: a plan with no AC column
# has no AC identifier to key on, and inventing one would be the placeholder fix
# the acceptance criterion explicitly disqualifies.
field_by_issue() {
  local json="$1" iss="$2" fld="$3" obj
  obj="$(grep -oE "\{[^{}]*\"issue\":\"$iss\"[^{}]*\}" <<<"$json" || true)"
  # sigpipe-idiom: allow — `sed`, not the here-string, is the signallable producer: the here-string feeds `sed`, and `sed` writes into the pipe `head -1` closes. Safe on SIZE, not on shape — the extracted field list is a few short lines, far under the pipe buffer, so `sed` writes it all and exits before `head` closes the read end.
  sed -n "s/.*\"$fld\":\"\([^\"]*\)\".*/\1/p" <<<"$obj" | head -1
}
pending_ids() { grep -c '"id":"PENDING"' <<<"$1" || true; }
# field_by_id <json> <id> <field> — the id-keyed twin. Used for the block-level
# diagnostic, whose ISSUE label is the literal `(plan)`: those parentheses are
# ERE metacharacters, so keying on the issue silently matches nothing and the
# arm reads an empty string. Caught by the arm failing rather than passing.
field_by_id() {
  local json="$1" the_id="$2" fld="$3" obj
  obj="$(grep -oE "\{[^{}]*\"id\":\"$the_id\"[^{}]*\}" <<<"$json" || true)"
  # sigpipe-idiom: allow — `sed`, not the here-string, is the signallable producer: the here-string feeds `sed`, and `sed` writes into the pipe `head -1` closes. Safe on SIZE, not on shape — the extracted field list is a few short lines, far under the pipe buffer, so `sed` writes it all and exits before `head` closes the read end.
  sed -n "s/.*\"$fld\":\"\([^\"]*\)\".*/\1/p" <<<"$obj" | head -1
}

# --- G11-A: THE CARD AC — per-row cell attribution, byte-compared -----------
vrp_run "$VERIFY" "$FIX_NOAC";    J_NOAC="$VRP_JSON"
vrp_run "$VERIFY" "$FIX_NOACCTL"; J_NOACC="$VRP_JSON"

M_NOAC="$(field_by_issue "$J_NOAC" '#811' method)"
E_NOAC="$(field_by_issue "$J_NOAC" '#811' expected)"
M_CTL="$(field_by_issue "$J_NOACC" '#811' method)"
E_CTL="$(field_by_issue "$J_NOACC" '#811' expected)"

# THE byte comparison that surfaced the defect: the emitted Method must equal the
# row's Verification-method cell and must DIFFER from its Expected-result cell.
[ "$M_NOAC" = '`test -f release/tools/verify-release-plan.sh`' ] && [ "$M_NOAC" != "$E_NOAC" ] \
  && ok "G11-A1 no-AC plan: the emitted Method is the METHOD cell and differs from the Expected cell ('$M_NOAC')" \
  || bad "G11-A1 cell attribution wrong on a no-AC plan: method='$M_NOAC' expected='$E_NOAC'"

# THE CONTROL. The AC column is the ONLY variable between the pair, and the two
# Method cells are byte-identical in the fixtures, so the emitted methods must be
# byte-identical too. This is what separates "the parser read the right column"
# from "the parser happened to produce a plausible string".
[ "$M_NOAC" = "$M_CTL" ] && [ "$E_NOAC" = "$E_CTL" ] \
  && ok "G11-A2 CONTROL — trap and control emit BYTE-IDENTICAL method and expected; the AC column changes nothing but the id" \
  || bad "G11-A2 the pair separated: trap method='$M_NOAC' vs control method='$M_CTL'"

[ "$(field_by_issue "$J_NOAC" '#811' id)" = "" ] && [ "$(field_by_issue "$J_NOACC" '#811' id)" = "AC-1" ] \
  && ok "G11-A3 the id field reports what the plan DECLARED — empty when there is no AC column, AC-1 when there is" \
  || bad "G11-A3 id fields wrong: trap '$(field_by_issue "$J_NOAC" '#811' id)', control '$(field_by_issue "$J_NOACC" '#811' id)'"

[ "$(pending_ids "$J_NOAC")" = "0" ] \
  && ok "G11-A4 zero records carry the collapse signature 'id:PENDING' — the marker stays in the position it was written to" \
  || bad "G11-A4 $(pending_ids "$J_NOAC") record(s) leaked the PENDING marker into the id field"

# --- G11-B: TWO empty interior fields (no AC and no Expected) ---------------
vrp_run "$VERIFY" "$FIX_NOACNOEXP"; J_NN="$VRP_JSON"
[ "$(field_by_issue "$J_NN" '#813' method)" = '`test -f release/tools/verify-release-plan.sh`' ] \
  && [ "$(pending_ids "$J_NN")" = "0" ] \
  && ok "G11-B1 a record with TWO empty interior fields still reads its method at the method position" \
  || bad "G11-B1 double-empty record mis-read: method='$(field_by_issue "$J_NN" '#813' method)'"

# --- G11-C: the CIAC parity record survives the read ------------------------
vrp_run "$VERIFY" "$FIX_CIACPAR"; J_CP="$VRP_JSON"
[ "$(family_of "$J_CP" CIAC-2)" = "parity-error" ] && [ "$(verdict_of "$J_CP" CIAC-2)" = "ERROR" ] \
  && ok "G11-C1 the CIAC parity record — whose field 2 is a literal empty string — keeps its family marker and ERRORs" \
  || bad "G11-C1 CIAC-2 family='$(family_of "$J_CP" CIAC-2)' verdict='$(verdict_of "$J_CP" CIAC-2)'; expected parity-error/ERROR"
[ "$(family_of "$J_CP" CIAC-1)" = "integration" ] && [ "$(verdict_of "$J_CP" CIAC-1)" = "PASS" ] \
  && ok "G11-C2 CONTROL — the conformant CIAC row in the same fixture still dispatches as integration and PASSes" \
  || bad "G11-C2 the conformant control row moved: family='$(family_of "$J_CP" CIAC-1)'"

# --- G11-D: the widened header dialects index -------------------------------
vrp_run "$VERIFY" "$FIX_MCLASS";   J_MC="$VRP_JSON"
vrp_run "$VERIFY" "$FIX_CMDCOL";   J_CC="$VRP_JSON"
vrp_run "$VERIFY" "$FIX_LONGFORM"; J_LF="$VRP_JSON"
[ "$(rows_of "$J_MC")" = "2" ] && [ "$(rows_of "$J_CC")" = "2" ] \
  && ok "G11-D1 the two unrecognised dialects index: 'Method class' 2 rows, 'Command' 2 rows (both were 0 before)" \
  || bad "G11-D1 dialects did not index: method-class '$(rows_of "$J_MC")', command '$(rows_of "$J_CC")'"
[ "$(rows_of "$J_LF")" = "2" ] \
  && ok "G11-D2 the long-form header 'Verification method (FMF-1-scoped)' still indexes — containment is preserved" \
  || bad "G11-D2 the long-form header stopped indexing: '$(rows_of "$J_LF")' rows"

# --- G11-E: the residual ERRORs, and does NOT false-positive ----------------
vrp_run "$VERIFY" "$FIX_UNIDX";    J_UI="$VRP_JSON"; RC_UI="$VRP_RC"
vrp_run "$VERIFY" "$FIX_NONVERIF"; J_NV="$VRP_JSON"; RC_NV="$VRP_RC"
U_N="$(grep -c '"family":"table-unindexable"' <<<"$J_UI" || true)"
[ "$U_N" = "1" ] && [ "$(field_by_id "$J_UI" TABLE expected)" = "rows=2" ] && [ "$RC_UI" = "3" ] \
  && ok "G11-E1 an unindexable table ERRORs ONCE per block carrying rows=2, and the run exits 3" \
  || bad "G11-E1 expected 1 block record/rows=2/exit 3; got n=$U_N rows='$(field_by_id "$J_UI" TABLE expected)' rc=$RC_UI"
case "$(field_by_id "$J_UI" TABLE method)" in
  *"| Issue | AC | Expected result |"*) ok "G11-E2 the ERROR carries the offending header VERBATIM, so the author can see which column is missing" ;;
  *) bad "G11-E2 the ERROR does not carry the header: '$(field_by_id "$J_UI" TABLE method)'" ;;
esac
# THE FALSE-POSITIVE CONTROL, and the reason the discriminator is not the looser
# rule. This table shares only the word `Issue` with the schema. ERROR means exit
# 3, so a rule that fires here turns a correct, shipped, unchangeable plan red.
[ "$(grep -c '"family":"table-unindexable"' <<<"$J_NV" || true)" = "0" ] && [ "$RC_NV" = "0" ] \
  && ok "G11-E3 CONTROL — a table naming only 'Issue' is NOT a verification claim: 0 records, exit 0" \
  || bad "G11-E3 FALSE POSITIVE — the non-verification table produced a record or a non-zero exit (rc=$RC_NV)"
# --- G11-F: an empty Method cell inside an indexed table --------------------
vrp_run "$VERIFY" "$FIX_EMPTYM"; J_EM="$VRP_JSON"; RC_EM="$VRP_RC"
[ "$(family_of "$J_EM" AC-2)" = "method-cell-empty" ] && [ "$(verdict_of "$J_EM" AC-2)" = "ERROR" ] && [ "$RC_EM" = "3" ] \
  && ok "G11-F1 a row declaring a check with no method to run it is a NAMED ERROR, not a silent drop" \
  || bad "G11-F1 AC-2 family='$(family_of "$J_EM" AC-2)' verdict='$(verdict_of "$J_EM" AC-2)' rc=$RC_EM"
[ "$(verdict_of "$J_EM" AC-1)" = "PASS" ] \
  && ok "G11-F2 CONTROL — the populated row in the SAME table grades normally, so the ERROR is attributable to the empty cell" \
  || bad "G11-F2 the in-fixture control row moved: '$(verdict_of "$J_EM" AC-1)'"

# ===========================================================================
# G11-M — SEEDED FAILURES. Each mutation must FLIP the arm it is paired with.
# Without these the group is a set of control-shaped assertions, which is the
# defect class this milestone exists to eliminate.
# ===========================================================================
MUTD4="$(mktemp -d -t verify-plan-6234-mut.XXXXXX)"
m6234() {
  local name="$1"; shift
  local dst="$MUTD4/$name.sh" e
  cp "$VERIFY" "$dst"
  for e in "$@"; do sed -i.bak -E "$e" "$dst"; done
  rm -f "$dst.bak"
  chmod +x "$dst"
  MUT_PATH="$dst"
  if cmp -s "$VERIFY" "$dst"; then
    bad "$name — MUTATION DID NOT TAKE (mutant is byte-identical); the paired arm would pass vacuously"
  else
    ok "$name — mutation applied (mutant bytes differ from the shipped tool)"
  fi
}

# M1 — REVERT THE DELIMITER TO A TAB. The replacement builds the tab through
# `printf %b` rather than a shell quote, so this expression carries no invisible
# literal tab that an editor could silently convert to spaces.
m6234 g11-m1-delimiter-reverted-to-tab 's/^readonly REC_FS=.*$/readonly REC_FS="$(printf %b \\\\011)"/'
vrp_run "$MUT_PATH" "$FIX_NOAC"; JM_NOAC="$VRP_JSON"
MM="$(field_by_issue "$JM_NOAC" '#811' method)"
[ "$(pending_ids "$JM_NOAC")" -gt 0 ] && [ "$MM" != "$M_NOAC" ] \
  && ok "G11-M1 mutation detected — under a whitespace delimiter the record shifts: ids read PENDING and the Method becomes '$MM'" \
  || bad "G11-M1 SURVIVED — pending=$(pending_ids "$JM_NOAC") method='$MM'; G11-A observes nothing"
vrp_run "$MUT_PATH" "$FIX_NOACCTL"; JM_NOACC="$VRP_JSON"
[ "$(field_by_issue "$JM_NOACC" '#811' method)" = "$M_CTL" ] \
  && ok "G11-M1b the SAME mutant leaves the AC-bearing control UNMOVED — which is why a fixture corpus drawn only from that population saw nothing" \
  || bad "G11-M1b the mutant moved the control too, so G11-M1 is not attributable to the empty field"

# M2 — REVERT THE WIDENING. The two dialects must stop indexing.
m6234 g11-m2-widening-reverted 's@else if \(c ~ /verification method/ \|\| c ~ /method class/ \|\|@else if (c ~ /verification method/ ||@; s@ *c == "method" \|\| c == "command"\) *\{ h_method = i;   h_hits\+\+ \}@                   c == "method")                              { h_method = i;   h_hits++ }@'
vrp_run "$MUT_PATH" "$FIX_MCLASS"; JM_MC="$VRP_JSON"
vrp_run "$MUT_PATH" "$FIX_CMDCOL"; JM_CC="$VRP_JSON"
[ "$(rows_of "$JM_MC")" = "0" ] && [ "$(rows_of "$JM_CC")" = "0" ] \
  && ok "G11-M2 mutation detected — with the widening reverted both dialects index 0 rows; G11-D1 flips" \
  || bad "G11-M2 SURVIVED — method-class '$(rows_of "$JM_MC")', command '$(rows_of "$JM_CC")'"
# AND the residual now fires on them, which is the whole point of pairing the
# widening with the ERROR: the rows do not vanish, they are named.
[ "$(grep -c '"family":"table-unindexable"' <<<"$JM_MC" || true)" -ge 1 ] \
  && ok "G11-M2b the reverted rows are NAMED, not lost — the residual ERROR fires on the same table" \
  || bad "G11-M2b the reverted rows vanished silently, which is the defect this card exists to close"

# M3 — THE EQUALITY REGRESSION, MADE EXECUTABLE. This is the amendment that was
# carried on a single measurement; here it is a test. Tightening containment to
# full-cell equality must de-index the long-form header.
m6234 g11-m3-method-match-tightened-to-equality 's@c ~ /verification method/ \|\| c ~ /method class/ \|\|@c == "verification method" || c == "method class" ||@'
vrp_run "$MUT_PATH" "$FIX_LONGFORM"; JM_LF="$VRP_JSON"
[ "$(rows_of "$JM_LF")" = "0" ] \
  && ok "G11-M3 mutation detected — full-cell equality silently de-indexes a header that works today; containment is load-bearing, not stylistic" \
  || bad "G11-M3 SURVIVED — the long-form header still indexes '$(rows_of "$JM_LF")' rows under equality"

# M4 — REMOVE THE RESIDUAL ERROR. The unindexable table must go silent again.
m6234 g11-m4-residual-error-removed 's@if \(h_method == 0 && \(h_ac > 0 \|\| h_expected > 0 \|\| h_pred > 0\)\) \{@if (0) {@'
vrp_run "$MUT_PATH" "$FIX_UNIDX"; JM_UI="$VRP_JSON"; RCM_UI="$VRP_RC"
[ "$(grep -c '"family":"table-unindexable"' <<<"$JM_UI" || true)" = "0" ] && [ "$RCM_UI" = "0" ] \
  && ok "G11-M4 mutation detected — without the residual arm the table suppresses its rows silently and the run exits 0" \
  || bad "G11-M4 SURVIVED — records still emitted (rc=$RCM_UI); G11-E1 observes nothing"

# M5 — WIDEN THE DISCRIMINATOR TO THE LOOSER RULE. The false-positive control
# must go red. This is the arm that would have caught the briefed predicate.
m6234 g11-m5-discriminator-loosened 's@if \(h_method == 0 && \(h_ac > 0 \|\| h_expected > 0 \|\| h_pred > 0\)\) \{@if (h_method == 0 \&\& h_hits >= 1) {@'
vrp_run "$MUT_PATH" "$FIX_NONVERIF"; JM_NV="$VRP_JSON"; RCM_NV="$VRP_RC"
[ "$(grep -c '"family":"table-unindexable"' <<<"$JM_NV" || true)" -ge 1 ] && [ "$RCM_NV" = "3" ] \
  && ok "G11-M5 mutation detected — the looser predicate ERRORs on a table making no verification claim and exits 3; G11-E3 flips" \
  || bad "G11-M5 SURVIVED — the looser predicate did not fire (rc=$RCM_NV), so G11-E3 proves nothing"

# M6 — REMOVE THE method-cell-empty ARM. The row must vanish silently.
m6234 g11-m6-empty-method-silent 's@^      if \(method == ""\) \{$@      if (method == "") { next } if (0) {@'
vrp_run "$MUT_PATH" "$FIX_EMPTYM"; JM_EM="$VRP_JSON"; RCM_EM="$VRP_RC"
[ "$(family_of "$JM_EM" AC-2)" = "" ] && [ "$RCM_EM" = "0" ] \
  && ok "G11-M6 mutation detected — without the arm the empty-method row vanishes with no record and the run exits 0" \
  || bad "G11-M6 SURVIVED — AC-2 family '$(family_of "$JM_EM" AC-2)' rc=$RCM_EM"

# M7 — DROP THE -F FROM THE CIAC DE-DUPE. The cascade the delimiter change
# creates: `!seen[$1]++` keyed on awk default whitespace no longer isolates the
# id, so the de-dupe silently stops de-duplicating.
m6234 g11-m7-dedupe-fs-dropped 's@awk -F"\$REC_FS" .!seen\[\$1\]\+\+.@awk "!seen[\$1]++"@'
vrp_run "$MUT_PATH" "$FIX_CIACPAR"; JM_CP="$VRP_JSON"
[ "$(grep -c '"id":"CIAC-' <<<"$JM_CP" || true)" != "$(grep -c '"id":"CIAC-' <<<"$J_CP" || true)" ] \
  && ok "G11-M7 mutation detected — without -F the de-dupe key runs past the id and the CIAC record count changes" \
  || bad "G11-M7 SURVIVED — CIAC record count unchanged ($(grep -c '"id":"CIAC-' <<<"$JM_CP" || true)); the -F cascade is untested"

rm -rf "$MUTD4"

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

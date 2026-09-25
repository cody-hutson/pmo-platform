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
#   (G5) DEPLOY-CHECK DELEGATION — the sync and regression families delegate to
#        deploy.sh --check, here a fast stub: a non-zero exit renders FAIL and an
#        overall exit 3 rather than an internal error, and the check runs once per
#        invocation however many sync and regression rows share it.
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
#  (G11) RECORD FORMAT + HEADER DIALECTS — the 0x1F parser-to-dispatcher
#        delimiter (an empty AC or Expected field no longer shifts the record
#        one position left), the widened method-column dialects, and the named
#        ERRORs for an unindexable table and an empty Method cell. Seven
#        mutation arms (G11-M).
#  (G12) FD-0 (V7531-AC1 / V7531-AC2) — a method cell cannot read the record
#        stream the executor iterates: a stdin reader is a named refusal, every
#        indexed row emits, a stdin-reading child cannot drain the loop, and a
#        loop that reads short is a named ERROR with a DEGRADED roll-up and an
#        internal exit. A reachability arm measures, on the bash running this
#        suite, that an exec'd child in the loop form sees no copy of the stream.
#        Five mutation arms, one non-synthetic replay graded per criterion.
#  (G13) NON-RETROACTIVITY (V6236-AC4) — a row this executor declines by design
#        stays outside the exit-failing set. A plan whose every row declines (a
#        refused tool, an identifier in the command position, no runnable
#        command, a declared deferral in either spelling) exits 0, and no declined
#        row reads FAIL or ERROR — asserted per row, never as "= SKIP", so a later
#        verdict that stays non-failing keeps it green. One fixture row per
#        historical SKIP shape, a non-synthetic replay graded per row, and two
#        seeded failures, each proved to apply at exactly the sites it names.
#  (G14) PREDICATE CLASS IS A READER ANNOTATION (V6180-AC5) — the executor grades
#        a row from its method cell alone. No surface of it claims a class hint,
#        the per-issue parser resolves no class value (the CIAC Predicate field
#        and the header word stay), and every row grades identically with and
#        without a Predicate class column: a row is routed away from the executor
#        only by the declared-deferred form in its method cell. One seeded failure
#        re-introduces a class read, proved to apply at exactly one site, and must
#        move a row.
#  (G15) A RUNNABLE PROBE IS EXECUTED, NEVER ROUTED BY PROSE (V6893-AC2/AC3/AC4,
#        V6837-AC2, V7531-AC3) — a row whose designated command is a probe this
#        executor runs is graded by that probe ahead of every keyword arm, whatever
#        its prose says; a phrase inside a span led by an allowlisted verb is that
#        command's pattern, never a declaration; a quoted operator character is
#        literal. Rows with no runnable probe keep the keyword fallback,
#        could-not-read stays ERROR beside a declared SKIP, and --help describes the
#        dispatch and claims no class hint. Five seeded failures, each proved to
#        apply at exactly its sites. G10's R-M2 is split in two for the same change.
#  (G16) A METHOD NAMING SEVERAL COMMANDS IS GRADED ON ITS DESIGNATED COMMAND
#        (V6837-AC4, V7531-CIAC6) — the designated command (the first allowlisted
#        verb that carries an argument) runs against the comparator stated after
#        it, and every other command the method names is reported as "did not run
#        (<reason>)"; a row with a command that did not run never reads PASS, and
#        takes the can't-run slot the executor binds, whose value the arms derive
#        rather than pin. A bare verb is prose, the shared comparator vocabulary
#        reads markdown emphasis around N and nothing wider, and an operand-less
#        further command never runs, so no later row is lost. G12-5 reads the
#        stdin-verb fixture's bare cat under the same bare-verb rule. Five seeded
#        failures and seams, each proved to apply at exactly its sites.
#  (G17) A METHOD THIS EXECUTOR CANNOT RUN IS UNRUNNABLE, AND A SCOPE ASSERTION RUNS
#        NATIVELY (V6848-AC1..AC4) — UNRUNNABLE is a fifth verdict, never PASS and
#        outside the exit predicate; a tool is named only from an invocation-shaped
#        span, so a mention never reads UNRUNNABLE; a runnable probe beside a tool
#        reads the can't-run slot and names both; a `git diff` scope assertion is
#        graded natively against the release diff a test seam supplies, and every
#        vacuous or mis-bound input reads UNRUNNABLE. RUNNABLE_VERBS is unchanged,
#        armed red. One non-synthetic replay over a real commit's diff, and eight
#        seeded failures, each proved to apply at exactly its sites.
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
# extract_command reads spans through method_spans, which asks span_invokes_tool;
# extract_threshold reads the comparator vocabulary from the CMP_*_ALT constants.
# Load all three first, or the arms below grade functions that cannot run.
eval "$(sed -n '/^readonly CMP_[A-Z]*_ALT=/p'  "$VERIFY" | sed 's/^readonly //')"
eval "$(sed -n '/^span_invokes_tool()/,/^}/p'  "$VERIFY")"
eval "$(sed -n '/^method_spans()/,/^}/p'       "$VERIFY")"
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

# R-M2 — SEEDED FAILURES on the retired route, in two layers, because a runnable
# probe is now resolved ahead of every keyword arm (classify_family step 1).
# R-M2a re-inserts the prose keyword arm ALONE, above the executable arm, which is
# exactly the shape that stole the row: AC-2 must STAY per-issue, because the probe
# step resolves it first — the new layer holds. R-M2b re-inserts the arm AND
# removes the probe step: AC-2 must be stolen again while AC-1 is not — the
# original detection, so R-1 still observes the keyword arm's position. Position
# is the defect, so each mutation restores the position.
G10_PROSE_ROUTE='s#^    \*grep\*#    *runtime*suite*|*test-run*|*dispatch*the*runtime*|*suite-*|*exercise*) echo "runtime-suite"; return ;;\
    *grep*#'
m6383 g10-m3a-keyword-route-only "$G10_PROSE_ROUTE"
vrp_run "$MUT_PATH" "$FIX_HIJACK"; JM_HJ2A="$VRP_JSON"
if mutant_ran "R-M2a"; then
  [ "$(family_of "$JM_HJ2A" AC-2)" = "per-issue" ] \
    && ok "R-M2a with only the prose keyword route restored, AC-2 stays per-issue — the probe step resolves it first" \
    || bad "R-M2a AC-2 reads '$(family_of "$JM_HJ2A" AC-2)' with only the prose route restored — a keyword still steals a runnable probe"
fi
m6383 g10-m3-keyword-route-restored "$G10_PROSE_ROUTE" 's/^  if \[ -n "\$probe" \]; then echo "per-issue"; return; fi$/  :/'
vrp_run "$MUT_PATH" "$FIX_HIJACK"; JM_HJ2="$VRP_JSON"
[ "$(family_of "$JM_HJ2" AC-1)" = "per-issue" ] && [ "$(family_of "$JM_HJ2" AC-2)" = "runtime-suite" ] \
  && ok "R-M2b mutation detected — with the keyword route restored above the executable arm and the probe step removed, AC-2 is stolen again while AC-1 is not" \
  || bad "R-M2b SURVIVED — AC-1 '$(family_of "$JM_HJ2" AC-1)' / AC-2 '$(family_of "$JM_HJ2" AC-2)'; R-1 observes nothing"

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

# ===========================================================================
# G12 — FD-0 (V7531-AC1 / V7531-AC2): a method cell cannot read the record
#       stream the executor iterates.
#
# Both dispatch loops in main() iterate a here-string on fd 0. A method with no
# file operand read the loop's OWN remaining records: every row after it
# vanished with no record while the roll-up still reported the parser's full
# denominator, and the cell itself was graded on the records it swallowed. A
# stdin-reading child outside the verb route did the same and left a clean exit.
# Every arm below carries its criterion label, and every guard is paired with a
# seeded failure that must flip it.
# ===========================================================================
echo
echo "G12 — FD-0: a method cell cannot read the record stream (V7531-AC1 / V7531-AC2)"

FIX_DRAIN="release/tools/tests/fixtures/verify-plan-stdin-drain.md"
FIX_VERBS="release/tools/tests/fixtures/verify-plan-stdin-verbs.md"

# ciacs_of <json> — emitted CIAC-N records. CIAC-STREAM is deliberately NOT one:
# the tripwire's own record must never be counted as a recovered row.
# strunc_of <json> — completeness records the FD-0 tripwire emitted.
ciacs_of()  { grep -c '"id":"CIAC-[0-9]' <<<"$1" || true; }
strunc_of() { grep -c '"family":"stream-truncated"' <<<"$1" || true; }

# g12_refused <json> <id> <reason> — the row is an ERROR, its observed value
# names the reason, and it reads as a REFUSAL (the command never ran) rather than
# through the matcher-outcome text a command that ran and failed carries.
g12_refused() {
  local obs; obs="$(observed_of "$1" "$2")"
  [ "$(verdict_of "$1" "$2")" = ERROR ] || return 1
  case "$obs" in
    "$3 (not run — "*) : ;;
    # A method naming several commands lists them, and its designated command's
    # refusal is named in that list with the same remedy (the executor's METHOD
    # LIMBS): still a refusal, never a count.
    "limbs run 1 of "*"ERROR $3 (not run — "*) : ;;
    *) return 1 ;;
  esac
  case "$obs" in *"the matcher produced no readable result"*) return 1 ;; esac
  return 0
}

# The detector, extracted from the shipped file (tokenize_cmd was loaded in G8).
eval "$(sed -n '/^stdin_input_refusal()/,/^}/p' "$VERIFY")"
eval "$(sed -n '/^reads_stdin_cmd()/,/^}/p'     "$VERIFY")"
G12_DET=0
if type reads_stdin_cmd >/dev/null 2>&1 && type stdin_input_refusal >/dev/null 2>&1; then G12_DET=1; fi

# --- G12-0: SENSITIVITY — the detector exists, and the fixture still plants. ---
if [ "$G12_DET" -eq 1 ] && [ "$(reads_stdin_cmd 'grep -c -F "AC-"' || true)" = "stdin-reader:grep" ]; then
  ok "G12-0 V7531-AC1 SENSITIVITY — the detector is defined and names an operand-less grep (stdin-reader:grep)"
else
  bad "G12-0 V7531-AC1 reads_stdin_cmd is undefined or does not name an operand-less grep; every arm that depends on it grades nothing"
fi
G12_PLANTED="$(grep -c -F 'grep -c -F "AC-"' "$REPO_ROOT/$FIX_DRAIN" || true)"
[ "${G12_PLANTED:-0}" -ge 1 ] \
  && ok "G12-0b V7531-AC2 the drain fixture still carries its planted operand-less grep (without it every arm below is vacuous)" \
  || bad "G12-0b V7531-AC2 the drain fixture no longer carries its planted cell; the arms below would grade nothing"

# --- G12-1..G12-3: the drain fixture (V7531-AC2). ---
vrp_run "$VERIFY" "$FIX_DRAIN"; J_DRAIN="$VRP_JSON"; RC_DRAIN="$VRP_RC"
[ "$(rows_of "$J_DRAIN")" = "6" ] && [ "$(acs_of "$J_DRAIN")" = "6" ] && [ "$(ciacs_of "$J_DRAIN")" = "3" ] \
  && ok "G12-1 V7531-AC2 every indexed row emits past the planted cells — 6 of 6 per-issue records and 3 of 3 CIACs" \
  || bad "G12-1 V7531-AC2 indexed=$(rows_of "$J_DRAIN") emitted AC=$(acs_of "$J_DRAIN") CIAC=$(ciacs_of "$J_DRAIN") (expected 6/6/3): a planted cell drained its loop"
if g12_refused "$J_DRAIN" AC-3 "stdin-reader:grep" && g12_refused "$J_DRAIN" CIAC-2 "stdin-reader:grep" \
   && case "$(observed_of "$J_DRAIN" AC-3)" in *"a file named only in the prose is not read"*) true ;; *) false ;; esac; then
  ok "G12-2 V7531-AC2 each planted cell is a NAMED ERROR rendered as a refusal with its remedy — never a count over the records it swallowed, nor over the null device"
else
  bad "G12-2 V7531-AC2 AC-3 '$(verdict_of "$J_DRAIN" AC-3)' / '$(observed_of "$J_DRAIN" AC-3)' — CIAC-2 '$(verdict_of "$J_DRAIN" CIAC-2)' / '$(observed_of "$J_DRAIN" CIAC-2)'"
fi
G12_CTL=0
for g12id in AC-1 AC-2 AC-4 AC-5 AC-6 CIAC-1 CIAC-3; do
  if [ "$(verdict_of "$J_DRAIN" "$g12id")" = PASS ]; then G12_CTL=$((G12_CTL + 1)); fi
done
[ "$G12_CTL" -eq 7 ] && [ "$(strunc_of "$J_DRAIN")" = "0" ] && [ "$RC_DRAIN" -eq 3 ] \
  && ok "G12-3 V7531-AC2 CONTROLS — all 7 control rows PASS, no completeness record fires, and the named ERROR reaches exit 3" \
  || bad "G12-3 V7531-AC2 controls PASS=$G12_CTL of 7, stream-truncated=$(strunc_of "$J_DRAIN"), rc=$RC_DRAIN (expected 7/0/3)"

# --- G12-4..G12-6: every stdin-capable verb, and each refusal class (V7531-AC1). ---
vrp_run "$VERIFY" "$FIX_VERBS"; J_VERBS="$VRP_JSON"; RC_VERBS="$VRP_RC"
[ "$(acs_of "$J_VERBS")" = "15" ] && [ "$(ciacs_of "$J_VERBS")" = "7" ] \
  && ok "G12-4 V7531-AC1 every row after each planted reader emits, in both loops — 15 of 15 per-issue records and 7 of 7 CIACs" \
  || bad "G12-4 V7531-AC1 emitted AC=$(acs_of "$J_VERBS") CIAC=$(ciacs_of "$J_VERBS") (expected 15 and 7)"
G12_REF=0
for g12pair in "AC-2 stdin-reader:grep" "AC-4 stdin-reader:head" "AC-6 stdin-reader:wc" \
               "AC-10 stdin-reader:grep" "AC-12 device-operand:/dev/stdin" "AC-14 unmodelled-option:--not-an-option" \
               "CIAC-2 stdin-reader:grep" "CIAC-4 stdin-reader:head" "CIAC-6 stdin-reader:cat"; do
  g12id="${g12pair%% *}"; g12why="${g12pair#* }"
  if g12_refused "$J_VERBS" "$g12id" "$g12why"; then G12_REF=$((G12_REF + 1))
  else printf '       %s: %s / %s (wanted %s)\n' "$g12id" "$(verdict_of "$J_VERBS" "$g12id")" "$(observed_of "$J_VERBS" "$g12id")" "$g12why"; fi
done
[ "$G12_REF" -eq 9 ] \
  && ok "G12-5 V7531-AC1 all 9 planted readers are NAMED refusals — grep, head, wc, cat, the stdin operand, a device path and an unmodelled option, in both loops" \
  || bad "G12-5 V7531-AC1 only $G12_REF of 9 planted readers were refused with their reason"
# AC-8 plants `cat` with no argument at all. A bare verb names a tool in prose and is
# never the command (the executor's METHOD LIMBS rule), so the row names no command:
# a named SKIP, and nothing reads stdin. The detector's own zero-argument case stays
# pinned in G12-13, and cat's refusal in a dispatch loop in CIAC-6 above.
[ "$(verdict_of "$J_VERBS" AC-8)" = SKIP ] && [ "$(observed_of "$J_VERBS" AC-8)" = "no-executable-command-in-method" ] \
  && ok "G12-5b V7531-AC1 a bare cat is prose, not a stdin reader: AC-8 names no command (SKIP no-executable-command-in-method)" \
  || bad "G12-5b V7531-AC1 AC-8 '$(verdict_of "$J_VERBS" AC-8)' / '$(observed_of "$J_VERBS" AC-8)' (expected SKIP no-executable-command-in-method)"
G12_CTL=0
for g12id in AC-1 AC-3 AC-5 AC-7 AC-9 AC-11 AC-13 AC-15 CIAC-1 CIAC-3 CIAC-5 CIAC-7; do
  if [ "$(verdict_of "$J_VERBS" "$g12id")" = PASS ]; then G12_CTL=$((G12_CTL + 1)); fi
done
[ "$G12_CTL" -eq 12 ] && [ "$(strunc_of "$J_VERBS")" = "0" ] && [ "$RC_VERBS" -eq 3 ] \
  && ok "G12-6 V7531-AC1 CONTROLS — all 12 control rows PASS, no completeness record fires, exit 3" \
  || bad "G12-6 V7531-AC1 controls PASS=$G12_CTL of 12, stream-truncated=$(strunc_of "$J_VERBS"), rc=$RC_VERBS (expected 12/0/3)"

# --- G12-7: CONTROL — a command that RAN and failed keeps the matcher text. ---
# The refusal's own rendering must not leak onto a matcher that genuinely ran.
case "$(observed_of "$J_CNT" AC-5)" in
  "count-unreadable:matcher-exit-2 (the matcher produced no readable result; this is NOT a zero)")
    ok "G12-7 V7531-AC2 CONTROL — a matcher that ran and exited 2 keeps the matcher-outcome text; only a command that never ran reads as a refusal" ;;
  *) bad "G12-7 V7531-AC2 the matcher-outcome text changed for a command that ran: '$(observed_of "$J_CNT" AC-5)'" ;;
esac

# --- G12-8..G12-10: the CHILD route (V7531-AC1). ---
# A deploy --check child that READS ITS STDIN, ahead of three rows. Before the
# fix it drained the loop and the run still exited 0: a silent green.
G12_STUB="$(mktemp -d -t verify-plan-7531-stub.XXXXXX)"
mkdir -p "$G12_STUB/core/deploy" "$G12_STUB/release/tools" "$G12_STUB/plan"
cp "$VERIFY" "$G12_STUB/release/tools/"
G12_RAN="$G12_STUB/deploy-child-ran"
printf '#!/usr/bin/env bash\ncat >/dev/null\n: > "%s"\nexit 0\n' "$G12_RAN" > "$G12_STUB/core/deploy/deploy.sh"
chmod +x "$G12_STUB/core/deploy/deploy.sh"
# The sync row names its invocation IN BACKTICKS. That keeps its declared route
# to the deploy-check oracle under the keyword-precedence carve-out, so the row
# still spawns the child; written in prose, a later routing change would leave
# this arm, and the mutation paired with it, vacuous.
cat > "$G12_STUB/plan/p.md" <<'EOF'
# stub plan — a stdin-reading deploy child ahead of three rows
## Verification Plan
**#602 — the child route**
| AC | Predicate class | Verification method | Expected result |
|---|---|---|---|
| AC-1 | sync | source-to-deployed via `deploy.sh --check` | in-sync |
| AC-2 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-3 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
| AC-4 | file-path+state | `test -f release/tools/verify-release-plan.sh` | control |
EOF
# g12_child <tool> [<format>] — run a tool on the child-route plan inside the stub
# root; sets VRP_JSON / VRP_RC in the CURRENT shell, for the reason vrp_run does.
g12_child() {
  rm -f "$G12_RAN"
  set +e
  VRP_JSON="$("$1" --no-color --format="${2:-json}" --root "$G12_STUB" "$G12_STUB/plan/p.md" 2>/dev/null)"
  VRP_RC=$?
  set -e
}
g12_child "$G12_STUB/release/tools/verify-release-plan.sh"; J_CHILD="$VRP_JSON"; RC_CHILD="$VRP_RC"
[ -f "$G12_RAN" ] && [ "$(family_of "$J_CHILD" AC-1)" = "sync" ] \
  && ok "G12-8 V7531-AC1 CHILD-ROUTE SENSITIVITY — the backticked sync row reached the deploy-check oracle and its stdin-reading child RAN" \
  || bad "G12-8 V7531-AC1 the deploy child never ran (AC-1 family '$(family_of "$J_CHILD" AC-1)'); G12-9 would be vacuous"
[ "$(acs_of "$J_CHILD")" = "4" ] && [ "$(strunc_of "$J_CHILD")" = "0" ] && [ "$RC_CHILD" -eq 0 ] \
  && ok "G12-9 V7531-AC1 a stdin-reading child OUTSIDE the verb route cannot drain the loop — 4 of 4 rows, clean exit 0" \
  || bad "G12-9 V7531-AC1 child route emitted AC=$(acs_of "$J_CHILD") stream-truncated=$(strunc_of "$J_CHILD") rc=$RC_CHILD (expected 4/0/0)"
grep -q -F '"stream_state": "fetched"' <<<"$J_CHILD" \
  && ok "G12-10 V7531-AC1 a complete stream says so — the JSON roll-up reports stream_state fetched" \
  || bad "G12-10 V7531-AC1 the JSON roll-up does not report stream_state fetched on a complete stream"

# --- G12-11/G12-12: REACHABILITY, measured on the bash running this suite (V7531-AC1). ---
# The FD-0 rule relies on bash keeping its saved copy of fd 0 close-on-exec while
# the loop body is redirected. That is a property of the bash, not of this file,
# so it is MEASURED here — on CI, on the runner's bash — rather than assumed per
# version. An exec'd child lists its own descriptors inside the executor's loop
# form and outside it; a descriptor the loop adds is a copy the child could read.
G12_LOOPS="$(grep -c -F '} </dev/null; done <<< "$per_issue_records"' "$VERIFY" || true)"
G12_LOOPS="$G12_LOOPS/$(grep -c -F '} </dev/null; done <<< "$ciac_records"' "$VERIFY" || true)"
[ "$G12_LOOPS" = "1/1" ] \
  && ok "G12-11 V7531-AC1 both dispatch loops carry the FD-0 form the arm below measures" \
  || bad "G12-11 V7531-AC1 the dispatch loops do not carry the FD-0 form (per-issue/CIAC = $G12_LOOPS, expected 1/1)"
g12_fds() { ls /dev/fd 2>/dev/null | tr '\n' ' '; }
g12_extra() {   # <baseline set> <observed set> -> descriptors observed but not in the baseline
  local base=" $1 " fd out=""
  for fd in $2; do case "$base" in *" $fd "*) : ;; *) out="$out $fd" ;; esac; done
  printf '%s' "$out"
}
G12_MK="R$$K"   # built at run time, so this file's own text can never match it
G12_RECS="$(printf '%s-1\n%s-2\n%s-3\n%s-4' "$G12_MK" "$G12_MK" "$G12_MK" "$G12_MK")"
G12_BASE="$(g12_fds)"
# SUBJECT — the executor's loop form.
G12_N=0; G12_SEEN=""
while IFS= read -r _g12rec; do {
  G12_N=$((G12_N + 1))
  if [ -z "$G12_SEEN" ]; then G12_SEEN="$(g12_fds)"; fi
} </dev/null; done <<< "$G12_RECS"
G12_XTRA="$(g12_extra "$G12_BASE" "$G12_SEEN")"
# SENSITIVITY — the same loop with one explicitly INHERITED copy of the stream.
G12_SXTRA=""; G12_SREACH=0
while IFS= read -r _g12rec; do {
  if [ -z "$G12_SXTRA" ]; then
    G12_SXTRA="$(g12_extra "$G12_BASE" "$(g12_fds)")"
    for g12fd in $G12_SXTRA; do
      g12hits="$(cat "/dev/fd/$g12fd" 2>/dev/null | grep -c "$G12_MK" || true)"
      G12_SREACH=$((G12_SREACH + ${g12hits:-0}))
    done
  fi
} 9<&0 </dev/null; done <<< "$G12_RECS"
if [ -z "$G12_XTRA" ] && [ "$G12_N" -eq 4 ]; then
  ok "G12-12 V7531-AC1 REACHABILITY (bash $BASH_VERSION) — an exec'd child inside the FD-0 loop form sees only its baseline descriptors [$G12_BASE], and the loop read 4 of 4"
else
  bad "G12-12 V7531-AC1 REACHABILITY (bash $BASH_VERSION) — the child sees extra descriptor(s) [$G12_XTRA] and the loop read $G12_N of 4: this bash leaves an inheritable copy of the stream"
fi
if [ -n "$G12_SXTRA" ] && [ "$G12_SREACH" -ge 1 ]; then
  ok "G12-12b V7531-AC1 REACHABILITY SENSITIVITY — the same probe sees an inherited copy [$G12_SXTRA] and reads $G12_SREACH record(s) through it, so an empty result above is a real absence"
else
  bad "G12-12b V7531-AC1 the probe did not detect a deliberately inherited copy (extra [$G12_SXTRA], reach $G12_SREACH); G12-12 is a broken probe"
fi

# --- G12-13..G12-15: the detector, unit by unit (V7531-AC1 / V7531-AC2). ---
# THE MODEL IS CLOSED, so both directions are asserted: every must-flag command is
# refused with its reason, and no must-pass command is refused. A detector that
# refused everything would satisfy the first table alone.
G12_MUST_FLAG="$(cat <<'EOF'
stdin-reader:grep %% grep -c -F "AC-"
stdin-reader:grep %% grep -m 1 x
stdin-reader:grep %% grep -c -m1 x
stdin-reader:grep %% grep -ec
stdin-reader:grep %% grep -c -e x
stdin-reader:grep %% grep -c -f patterns.txt
stdin-reader:grep %% grep -c -f - release/tools/verify-release-plan.sh
stdin-reader:grep %% grep -c x -
stdin-reader:grep %% grep -c -- x
stdin-reader:grep %% grep -c --regexp x
stdin-reader:grep %% grep -c --regexp=x
stdin-reader:grep %% grep -c --max-count 1 x
stdin-reader:grep %% grep -c --file=- release/tools/verify-release-plan.sh
stdin-reader:grep %% grep -c --exclude-from=- x release
stdin-reader:grep %% grep -c -A 2 x
stdin-reader:grep %% grep -c --include=*.md x
stdin-reader:grep %% grep -c --label L x
stdin-reader:head %% head -n 1
stdin-reader:head %% head -5
stdin-reader:head %% head
stdin-reader:wc %% wc -l
stdin-reader:wc %% wc
stdin-reader:cat %% cat
stdin-reader:cat %% cat -u
stdin-reader:cat %% cat -
device-operand:/dev/stdin %% grep -c x /dev/stdin
device-operand:/dev/fd/0 %% grep -c x /dev/fd/0
device-operand:/dev/fd/3 %% cat /dev/fd/3
device-operand://dev/stdin %% cat //dev/stdin
device-operand:/dev//stdin %% cat /dev//stdin
device-operand:/proc/self/fd/0 %% wc -l /proc/self/fd/0
device-operand:/dev/zero %% head -n 1 /dev/zero
device-operand:/dev/stdin %% grep -c -f /dev/stdin release/tools/verify-release-plan.sh
device-operand:/dev/fd/0 %% grep -c --file=/dev/fd/0 release/tools/verify-release-plan.sh
device-operand:/dev/stdin %% grep -c --exclude-from /dev/stdin x release
unmodelled-option:--not-an-option %% grep -c --not-an-option x release/tools/verify-release-plan.sh
unmodelled-option:-K %% grep -c -K x release/tools/verify-release-plan.sh
unmodelled-option:-K %% grep -cK x release/tools/verify-release-plan.sh
unmodelled-option:--context %% grep -c --context 1 x release/tools/verify-release-plan.sh
unmodelled-option:-q %% head -q release/tools/verify-release-plan.sh
unmodelled-option:-A %% cat -A release/tools/verify-release-plan.sh
unmodelled-option:--lines %% wc --lines release/tools/verify-release-plan.sh
unmodelled-option:--bytes %% head --bytes 5 release/tools/verify-release-plan.sh
EOF
)"
G12_MUST_PASS="$(cat <<'EOF'
grep -c -F "AC-" release/tools/verify-release-plan.sh
grep -m 1 x release/tools/verify-release-plan.sh
grep -c -e x release/tools/verify-release-plan.sh
grep -c -e x -e y release/tools/verify-release-plan.sh
grep -c -f patterns.txt release/tools/verify-release-plan.sh
grep -r -c x
grep -rc x
grep -R -c x
grep -c -d recurse x
grep -c -drecurse x
grep -c --directories=recurse x
grep -c --directories recurse x
grep -c --recursive x
grep
grep -c
grep -c -e
grep -c -- -x release/tools/verify-release-plan.sh
grep -c --include=*.md -r x release
grep -c --exclude-dir=ADRs -r x release
grep --count x release/tools/verify-release-plan.sh
grep -c --context=1 x release/tools/verify-release-plan.sh
grep -c --color x release/tools/verify-release-plan.sh
grep -c --color=never x release/tools/verify-release-plan.sh
grep -c -5 x release/tools/verify-release-plan.sh
grep -c -A 2 x release/tools/verify-release-plan.sh
grep -c -B2 x release/tools/verify-release-plan.sh
grep -c -i -w -v x release/tools/verify-release-plan.sh
grep -c x release/tools/verify-release-plan.sh release/tools/claim-version.sh
grep -c x dev/stdin
grep -c x release/dev-notes.md
grep -n "Author-association trust boundary" release/governance/release-process.md
grep -rn "no review comments arrive" --include="*.md" --exclude-dir=ADRs --exclude-dir=releases core/ release/
head -n 1 release/tools/verify-release-plan.sh
head -n1 release/tools/verify-release-plan.sh
head -5 release/tools/verify-release-plan.sh
head -c 10 release/tools/verify-release-plan.sh
wc -l release/tools/verify-release-plan.sh
wc -L release/tools/verify-release-plan.sh
cat release/tools/verify-release-plan.sh
cat -n release/tools/verify-release-plan.sh
test -f /dev/null
test -f release/tools/verify-release-plan.sh
ls /dev/fd
ls release/ADRs/ADR-076-*
EOF
)"
if [ "$G12_DET" -eq 1 ]; then
  G12_FN=0; G12_FMISS=0
  while IFS= read -r g12line; do
    [ -n "$g12line" ] || continue
    g12why="${g12line%% %% *}"; g12cmd="${g12line#* %% }"
    G12_FN=$((G12_FN + 1))
    if g12got="$(reads_stdin_cmd "$g12cmd")" && [ "$g12got" = "$g12why" ]; then :; else
      G12_FMISS=$((G12_FMISS + 1)); printf '       must-flag MISS: [%s] got [%s] want [%s]\n' "$g12cmd" "${g12got:-}" "$g12why"
    fi
  done <<< "$G12_MUST_FLAG"
  [ "$G12_FMISS" -eq 0 ] && [ "$G12_FN" -eq 43 ] \
    && ok "G12-13 V7531-AC1 UNIT — all $G12_FN must-flag commands are refused, each with its reason (stdin-reader / device-operand / unmodelled-option)" \
    || bad "G12-13 V7531-AC1 UNIT — $G12_FMISS of $G12_FN must-flag commands were missed or misnamed (expected 0 of 43)"
  G12_PN=0; G12_PFP=0
  while IFS= read -r g12cmd; do
    [ -n "$g12cmd" ] || continue
    G12_PN=$((G12_PN + 1))
    if g12got="$(reads_stdin_cmd "$g12cmd")"; then
      G12_PFP=$((G12_PFP + 1)); printf '       must-pass FALSE REFUSAL: [%s] -> [%s]\n' "$g12cmd" "$g12got"
    fi
  done <<< "$G12_MUST_PASS"
  [ "$G12_PFP" -eq 0 ] && [ "$G12_PN" -eq 44 ] \
    && ok "G12-14 V7531-AC1 UNIT SPECIFICITY — none of the $G12_PN must-pass commands is refused (a detector that refused everything fails here)" \
    || bad "G12-14 V7531-AC1 UNIT — $G12_PFP of $G12_PN must-pass commands were refused (expected 0 of 44)"
  [ "$(count_from_output 'grep -c -F "AC-"' '' 4 | cut -f2)" = "stdin-reader:grep" ] \
    && ok "G12-15 V7531-AC2 the single exit-status reader names status 4 as the refusal it is (stdin-reader:grep), never as matcher-exit-4" \
    || bad "G12-15 V7531-AC2 count_from_output reads status 4 as '$(count_from_output 'grep -c -F "AC-"' '' 4 | cut -f2)'"
else
  bad "G12-13 V7531-AC1 UNIT — reads_stdin_cmd is undefined; the must-flag table cannot run"
  bad "G12-14 V7531-AC1 UNIT SPECIFICITY — reads_stdin_cmd is undefined; the must-pass table cannot run"
  bad "G12-15 V7531-AC2 count_from_output's status-4 reading cannot be graded without the detector"
fi

# --- G12-R: NON-SYNTHETIC replay (V7531-AC2), graded PER CRITERION. ---
# v3.65.1 is a live plan whose AC-3, AC-5 and AC-9 each name a grep with no file;
# the first of them used to take every later row with it. The arm names those
# three criteria instead of counting refusals, so a later change to how a row's
# other limbs are graded cannot move it.
REAL7531="release/releases/plans/v3.65.1_RELEASE_PLAN.md"
if [ ! -f "$REPO_ROOT/$REAL7531" ]; then
  bad "G12-R PRECONDITION — replay target absent: $REAL7531 (relocated or renamed? the arms below cannot grade)"
else
  # DENOMINATOR FIRST: a replay of a plan that no longer carries the shape is vacuous.
  G12R_SHAPE="$(grep -c -F '`grep -n "unrequested"`' "$REPO_ROOT/$REAL7531" || true)"
  if [ "${G12R_SHAPE:-0}" -lt 1 ]; then
    bad "G12-R VACUOUS — the replay target no longer carries its operand-less grep; this arm asserts nothing"
  else
    vrp_run "$VERIFY" "$REAL7531"; J_R7531="$VRP_JSON"
    printf '       replay: %s indexed=%s emitted=%s stream-truncated=%s\n' \
      "$REAL7531" "$(rows_of "$J_R7531")" "$(acs_of "$J_R7531")" "$(strunc_of "$J_R7531")"
    [ "$(rows_of "$J_R7531")" = "11" ] && [ "$(acs_of "$J_R7531")" = "11" ] && [ "$(strunc_of "$J_R7531")" = "0" ] \
      && ok "G12-R V7531-AC2 NON-SYNTHETIC — every indexed row of a live plan emits (11 of 11), with no completeness record" \
      || bad "G12-R V7531-AC2 v3.65.1 indexed=$(rows_of "$J_R7531") emitted=$(acs_of "$J_R7531") stream-truncated=$(strunc_of "$J_R7531") (expected 11/11/0)"
    for g12id in AC-3 AC-5 AC-9; do
      if g12_refused "$J_R7531" "$g12id" "stdin-reader:grep"; then
        ok "G12-R V7531-AC2 v3.65.1 $g12id — its operand-less grep is a NAMED refusal (stdin-reader:grep)"
      else
        bad "G12-R V7531-AC2 v3.65.1 $g12id '$(verdict_of "$J_R7531" "$g12id")' / '$(observed_of "$J_R7531" "$g12id")' (expected ERROR stdin-reader:grep)"
      fi
    done
  fi
fi

# ===========================================================================
# G12-M — SEEDED FAILURES. Each reverts one FD-0 guard and names the answer its
# paired arm must move to; each first proves the mutation took.
# ===========================================================================
MUTD5="$(mktemp -d -t verify-plan-7531-mut.XXXXXX)"
m7531() {
  local name="$1"; shift
  local dst="$MUTD5/$name.sh" e
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
G12_UNREDIRECT_PI='s/\} <\/dev\/null; done <<< "\$per_issue_records"/}; done <<< "$per_issue_records"/'
G12_UNREDIRECT_CI='s/\} <\/dev\/null; done <<< "\$ciac_records"/}; done <<< "$ciac_records"/'
G12_UNREFUSE='s/if reads_stdin_cmd "\$cmd" >\/dev\/null; then return 4; fi/if false; then return 4; fi/'

# M1 — the per-issue body redirect removed: the child route drains again, and the
# TRIPWIRE must name it — a STREAM ERROR, a DEGRADED roll-up, exit 1 (not 3).
m7531 g12-m1-per-issue-body-unredirected "$G12_UNREDIRECT_PI"
g12_child "$MUT_PATH"; JM1="$VRP_JSON"; RCM1="$VRP_RC"
case "$(observed_of "$JM1" STREAM)" in *"read 1 of 4 parsed per-issue records"*) G12M1_OBS=1 ;; *) G12M1_OBS=0 ;; esac
[ "$(acs_of "$JM1")" = "1" ] && [ "$(field_by_id "$JM1" STREAM verdict)" = "ERROR" ] && [ "$G12M1_OBS" -eq 1 ] && [ "$RCM1" -eq 1 ] \
  && ok "G12-M1 V7531-AC1 mutation detected — without the body redirect the child drains the loop (1 of 4) and the tripwire names it: a STREAM ERROR reading 'read 1 of 4', exit 1 (internal) rather than a silent green" \
  || bad "G12-M1 V7531-AC1 emitted AC=$(acs_of "$JM1") STREAM '$(field_by_id "$JM1" STREAM verdict)' / '$(observed_of "$JM1" STREAM)' rc=$RCM1 (expected 1 / ERROR 'read 1 of 4' / 1)"
grep -q -F '"stream_state": "truncated"' <<<"$JM1" \
  && ok "G12-M1b V7531-AC1 the drained run's JSON roll-up reports stream_state truncated" \
  || bad "G12-M1b V7531-AC1 the drained run's JSON roll-up does not report stream_state truncated"
g12_child "$MUT_PATH" md; MDM1="$VRP_JSON"
grep -q -F '**DEGRADED:** read 1 of 4 parsed per-issue records' <<<"$MDM1" \
  && ok "G12-M1c V7531-AC1 the md roll-up carries the DEGRADED marker and 'read 1 of 4' — a partial measurement is annotated, never presented as a clean count" \
  || bad "G12-M1c V7531-AC1 the md roll-up does not carry the DEGRADED marker: '$(grep -F 'Verdict roll-up' <<<"$MDM1" || true)'"

# M2 — the refusal removed, the redirects kept: isolation alone holds (6 of 6),
# but the planted cell PASSes on the null device. That grade-on-nothing false PASS
# is what the refusal exists to close.
m7531 g12-m2-refusal-removed "$G12_UNREFUSE"
vrp_run "$MUT_PATH" "$FIX_DRAIN"; JM2="$VRP_JSON"
if mutant_ran "G12-M2"; then
  [ "$(acs_of "$JM2")" = "6" ] && [ "$(verdict_of "$JM2" AC-3)" = "PASS" ] && [ "$(observed_of "$JM2" AC-3)" = "count=0 (== 0)" ] \
    && ok "G12-M2 V7531-AC2 mutation detected — without the refusal every row still emits (6 of 6) but the planted cell PASSes 'count=0 (== 0)' on the null device" \
    || bad "G12-M2 V7531-AC2 emitted AC=$(acs_of "$JM2"), AC-3 '$(verdict_of "$JM2" AC-3)' / '$(observed_of "$JM2" AC-3)' (expected 6 and PASS 'count=0 (== 0)')"
fi

# M3 — the refusal AND both body redirects removed: the pre-fix shape. The
# tripwire is then the only guard left, and it must fire on BOTH loops.
m7531 g12-m3-refusal-and-both-redirects-removed "$G12_UNREFUSE" "$G12_UNREDIRECT_PI" "$G12_UNREDIRECT_CI"
vrp_run "$MUT_PATH" "$FIX_DRAIN"; JM3="$VRP_JSON"; RCM3="$VRP_RC"
if mutant_ran "G12-M3"; then
  [ "$(acs_of "$JM3")" = "3" ] && [ "$(ciacs_of "$JM3")" = "2" ] && [ "$(strunc_of "$JM3")" = "2" ] && [ "$RCM3" -eq 1 ] \
    && ok "G12-M3 V7531-AC2 mutation detected — in the pre-fix shape both loops lose rows again (3 of 6, 2 of 3), and the tripwire names both losses and exits 1" \
    || bad "G12-M3 V7531-AC2 emitted AC=$(acs_of "$JM3") CIAC=$(ciacs_of "$JM3") stream-truncated=$(strunc_of "$JM3") rc=$RCM3 (expected 3/2/2/1)"
fi

# M4 — the refusal's own rendering removed: the planted cell falls back to the
# matcher-outcome text, which asserts that a matcher ran. G12-2 must flip.
m7531 g12-m4-refusal-rendered-as-matcher-outcome 's/^    stdin-reader:\*\)$/    stdin-reader-unrendered:*)/'
vrp_run "$MUT_PATH" "$FIX_DRAIN"; JM4="$VRP_JSON"
if mutant_ran "G12-M4"; then
  case "$(observed_of "$JM4" AC-3)" in
    "count-unreadable:stdin-reader:grep (the matcher produced no readable result"*)
      ok "G12-M4 V7531-AC2 mutation detected — without its own rendering the refusal reads as a matcher that ran and failed, and G12-2 flips" ;;
    *) bad "G12-M4 V7531-AC2 AC-3 observed '$(observed_of "$JM4" AC-3)' under the mutant; G12-2 observes nothing" ;;
  esac
fi

# M5 — the device rule removed: a method naming /dev/stdin runs, reads the null
# device and PASSes — the same false PASS, reached through a path rather than an
# absent operand.
m7531 g12-m5-device-rule-removed 's@case "\$p" in /dev\|/dev/\*\|/proc\|/proc/\*\)@case "$p" in /no-such-device-root/*)@'
vrp_run "$MUT_PATH" "$FIX_VERBS"; JM5="$VRP_JSON"
if mutant_ran "G12-M5"; then
  [ "$(verdict_of "$JM5" AC-12)" = "PASS" ] && [ "$(observed_of "$JM5" AC-12)" = "count=0 (== 0)" ] \
    && ok "G12-M5 V7531-AC1 mutation detected — without the device rule a method reading /dev/stdin PASSes 'count=0 (== 0)' on the null device" \
    || bad "G12-M5 V7531-AC1 AC-12 '$(verdict_of "$JM5" AC-12)' / '$(observed_of "$JM5" AC-12)' under the mutant (expected PASS 'count=0 (== 0)')"
fi

rm -rf "$MUTD5" "$G12_STUB"

# ===========================================================================
# G13 — NON-RETROACTIVITY (V6236-AC4): a row this executor declines by design
#       never joins the exit-failing set.
#
# Declining is not failing. A refused tool, an identifier in the command
# position, a method with no runnable command and a declared deferral each say
# that this executor is not the runner for the row, and every historical plan
# that declined that way exits 0. A later change that renames or re-classes a
# decline (a "cannot run here" verdict, say) must keep it outside main()'s
# exit-failing set, or it turns those plans' exit 0 into 3: a fix that turns
# every prior release's QC3.5 red is worse than the gap it closes. The fixture
# carries one row per historical SKIP shape; the replay grades a live plan whose
# five CIACs all decline. Both read PER ROW that no decline is FAIL or ERROR —
# never "= SKIP", so a later verdict that stays non-failing keeps them green.
# Each seeded failure is proved to apply at exactly the sites it names, then
# must move its arm to a named answer.
# ===========================================================================
echo
echo "G13 — non-retroactivity: a declined row never fails the plan (V6236-AC4)"

FIX_HIST="release/tools/tests/fixtures/verify-plan-historical-skips.md"
G13_AC="AC-1 AC-2 AC-3 AC-4 AC-5"
G13_CIAC="CIAC-1 CIAC-2 CIAC-3 CIAC-4 CIAC-5"

# g13_records <json> — every emitted record (each carries exactly one verdict field).
# covs_of <json>     — the always-on families' coverage records.
g13_records() { grep -c '"verdict":"' <<<"$1" || true; }
covs_of()     { grep -c '"id":"[A-Z]*-COVERAGE"' <<<"$1" || true; }

# g13_verdict / g13_observed <json> <id> — one field of one record, read from the
# record's own LINE. verdict_of and observed_of isolate a record with `[^{}]*`, so
# a record whose text carries a brace is invisible to them and reads as absent:
# v4.43's CIAC-3 method quotes a set in braces. The JSON presenter writes one record
# per line and escapes every quote inside a field, so the record's line and each
# unescaped `"<field>":"` delimiter are unambiguous. A duplicated id yields its
# first record.
g13_verdict() {
  local line v
  line="$(grep -F "\"id\":\"$2\"" <<<"$1" || true)"
  v="$(sed -n 's/.*"verdict":"\([A-Z]*\)".*/\1/p' <<<"$line")"
  printf '%s' "${v%%$'\n'*}"
}
g13_observed() {
  local line v
  line="$(grep -F "\"id\":\"$2\"" <<<"$1" || true)"
  v="$(sed -n 's/.*"observed":"\([^"]*\)".*/\1/p' <<<"$line")"
  printf '%s' "${v%%$'\n'*}"
}

# g13_failing <json> <id>... — prints " id=verdict" for each named row that is
# ABSENT or reads FAIL or ERROR, and nothing when every one is present and
# non-failing. An absent row counts: a row that vanished did not stay clean.
g13_failing() {
  local json="$1" id v out=""
  shift
  for id in "$@"; do
    v="$(g13_verdict "$json" "$id")"
    case "$v" in ''|FAIL|ERROR) out="$out $id=${v:-absent}" ;; esac
  done
  printf '%s' "$out"
}

# --- G13-0: DENOMINATOR FIRST — the fixture still declares every declined row. ---
G13_ROWS="$(grep -c -F '| AC-' "$REPO_ROOT/$FIX_HIST" || true)"
G13_ENTRIES="$(grep -c -F '**CIAC-' "$REPO_ROOT/$FIX_HIST" || true)"
[ "${G13_ROWS:-0}" -eq 5 ] && [ "${G13_ENTRIES:-0}" -eq 5 ] \
  && ok "G13-0 V6236-AC4 the fixture still declares its 5 declined per-issue rows and 5 declined CIACs (without them every arm below is vacuous)" \
  || bad "G13-0 V6236-AC4 the fixture declares ${G13_ROWS:-0} per-issue rows and ${G13_ENTRIES:-0} CIACs (expected 5 and 5); the arms below would grade nothing"

# --- G13-1..G13-3: the fixture on the shipped tool (V6236-AC4). ---
vrp_run "$VERIFY" "$FIX_HIST"; J_HIST="$VRP_JSON"; RC_HIST="$VRP_RC"
printf '       g13 historical-skips: records=%s (AC %s, CIAC %s, coverage %s) PASS=%s FAIL=%s ERROR=%s SKIP=%s rc=%s\n' \
  "$(g13_records "$J_HIST")" "$(acs_of "$J_HIST")" "$(ciacs_of "$J_HIST")" "$(covs_of "$J_HIST")" \
  "$(count_verdict "$J_HIST" PASS)" "$(count_verdict "$J_HIST" FAIL)" "$(count_verdict "$J_HIST" ERROR)" \
  "$(count_verdict "$J_HIST" SKIP)" "$RC_HIST"
[ "$(g13_records "$J_HIST")" = "12" ] && [ "$(acs_of "$J_HIST")" = "5" ] && [ "$(ciacs_of "$J_HIST")" = "5" ] && [ "$(covs_of "$J_HIST")" = "2" ] \
  && ok "G13-1 V6236-AC4 the fixture yields 12 records — 5 per-issue, 5 CIAC and the 2 always-on coverage records" \
  || bad "G13-1 V6236-AC4 records=$(g13_records "$J_HIST") (AC $(acs_of "$J_HIST"), CIAC $(ciacs_of "$J_HIST"), coverage $(covs_of "$J_HIST")); expected 12 (5, 5, 2)"
G13_BAD="$(g13_failing "$J_HIST" $G13_AC $G13_CIAC)"
[ -z "$G13_BAD" ] && [ "$(count_verdict "$J_HIST" FAIL)" = "0" ] && [ "$(count_verdict "$J_HIST" ERROR)" = "0" ] \
  && ok "G13-2 V6236-AC4 no declined row reads FAIL or ERROR — AC-1..AC-5 and CIAC-1..CIAC-5 each present and non-failing, and the record set carries 0 FAIL and 0 ERROR" \
  || bad "G13-2 V6236-AC4 rows absent or failing:${G13_BAD:- none}; FAIL=$(count_verdict "$J_HIST" FAIL) ERROR=$(count_verdict "$J_HIST" ERROR) (expected 0 and 0)"
[ "$RC_HIST" -eq 0 ] \
  && ok "G13-3 V6236-AC4 a plan whose every row declines by design exits 0 — a decline stays outside the exit-failing set" \
  || bad "G13-3 V6236-AC4 a plan whose every row declines exits $RC_HIST (expected 0): a decline reached the exit-failing set"

# --- G13-R: NON-SYNTHETIC replay (V6236-AC4), graded PER ROW, never by exit code. ---
# v4.43's five CIACs are the ones #6236 was filed from: three name a tool the
# executor refuses and two carry no runnable command. The arm reads each row and
# not the exit, because the plan's always-on families read the environment (the
# delivery family cannot resolve a diff outside a repository), so the plan's exit
# says nothing about its declines.
REAL6236="release/releases/plans/v4/v4.43_RELEASE_PLAN.md"
if [ ! -f "$REPO_ROOT/$REAL6236" ]; then
  bad "G13-R V6236-AC4 PRECONDITION — replay target absent: $REAL6236 (relocated or renamed? the arm cannot grade)"
else
  # DENOMINATOR FIRST: a replay of a plan that no longer declares its CIACs is vacuous.
  G13R_ENTRIES="$(grep -c -F '**CIAC-' "$REPO_ROOT/$REAL6236" || true)"
  if [ "${G13R_ENTRIES:-0}" -lt 5 ]; then
    bad "G13-R V6236-AC4 VACUOUS — the replay target declares ${G13R_ENTRIES:-0} bold CIAC entries (expected 5); this arm asserts nothing"
  else
    vrp_run "$VERIFY" "$REAL6236"; J_R6236="$VRP_JSON"
    printf '       g13 replay: %s CIAC-1..CIAC-5 = %s %s %s %s %s (rc %s, not graded)\n' "$REAL6236" \
      "$(g13_verdict "$J_R6236" CIAC-1)" "$(g13_verdict "$J_R6236" CIAC-2)" "$(g13_verdict "$J_R6236" CIAC-3)" \
      "$(g13_verdict "$J_R6236" CIAC-4)" "$(g13_verdict "$J_R6236" CIAC-5)" "$VRP_RC"
    for g13id in $G13_CIAC; do
      if [ -z "$(g13_failing "$J_R6236" "$g13id")" ]; then
        ok "G13-R V6236-AC4 NON-SYNTHETIC — v4.43 $g13id emits and declines without failing ($(g13_verdict "$J_R6236" "$g13id"))"
      else
        bad "G13-R V6236-AC4 v4.43 $g13id '$(g13_verdict "$J_R6236" "$g13id")' / '$(g13_observed "$J_R6236" "$g13id")' (expected present and neither FAIL nor ERROR)"
      fi
    done
  fi
fi

# ===========================================================================
# G13-M — SEEDED FAILURES. Each is proved to apply at EXACTLY the sites it names:
# a sed that matches nothing leaves a byte-identical copy and a vacuous green, and
# one that matches more than intended changes something else as well. Each must
# then move its arm to a named answer.
# ===========================================================================
MUTD6="$(mktemp -d -t verify-plan-6236-mut.XXXXXX)"
# m6236 <label> <stem> <sites> <sed-expr> — publish the mutant in MUT_PATH, as the
# earlier groups' helpers do, and count the lines it changed. A substitution never
# adds or removes a line, so a line-by-line comparison counts its sites.
m6236() {
  local label="$1" stem="$2" want="$3" e="$4" dst n
  dst="$MUTD6/$stem.sh"
  cp "$VERIFY" "$dst"
  sed -i.bak -E "$e" "$dst"
  rm -f "$dst.bak"
  chmod +x "$dst"
  MUT_PATH="$dst"
  n="$(awk 'NR == FNR { a[FNR] = $0; next } a[FNR] != $0 { n++ } END { print n + 0 }' "$VERIFY" "$dst")"
  if [ "$n" -eq "$want" ]; then
    ok "$label — mutation applied at exactly $want site(s): the mutant differs from the shipped tool in $n line(s)"
  else
    bad "$label — mutation applied at $n site(s), expected exactly $want; the paired arm would grade the wrong change"
  fi
}

# M1 — a decline joins the failing set. main()'s exit predicate names only FAIL
# and ERROR; adding SKIP is the change V6236-AC4 exists to stop, and the fixture,
# every row of which declines, must then exit 3 on the same non-failing records.
m6236 "G13-M1 V6236-AC4" g13-m1-decline-joins-failing-set 1 \
  's/\$6=="FAIL"\|\|\$6=="ERROR"\{found=1\}/$6=="FAIL"\|\|$6=="ERROR"\|\|$6=="SKIP"{found=1}/'
vrp_run "$MUT_PATH" "$FIX_HIST"; JM6236_1="$VRP_JSON"; RCM6236_1="$VRP_RC"
if mutant_ran "G13-M1 V6236-AC4"; then
  [ "$RCM6236_1" -eq 3 ] && [ "$(g13_records "$JM6236_1")" = "12" ] && [ -z "$(g13_failing "$JM6236_1" $G13_AC $G13_CIAC)" ] \
    && ok "G13-M1 V6236-AC4 mutation detected — with a decline in the exit-failing set the same 12 non-failing records exit 3, so G13-3 flips" \
    || bad "G13-M1 V6236-AC4 rc=$RCM6236_1 records=$(g13_records "$JM6236_1") failing rows:$(g13_failing "$JM6236_1" $G13_AC $G13_CIAC) (expected 3, 12 and none)"
fi

# M2 — the verb check disabled in both handlers. The refused-tool rows then reach
# eval_free_run, which runs nothing for a verb outside its set (`*) return 3`), so
# each reads ERROR as a matcher that could not run and the plan exits 3: a decline
# turned into a failure by a change to how the row is graded, not to the exit rule.
m6236 "G13-M2 V6236-AC4" g13-m2-verb-check-disabled 2 \
  's/  if ! is_runnable_verb "\$verb"; then/  if false; then/'
vrp_run "$MUT_PATH" "$FIX_HIST"; JM6236_2="$VRP_JSON"; RCM6236_2="$VRP_RC"
if mutant_ran "G13-M2 V6236-AC4"; then
  G13M2_HIT=0
  for g13id in AC-1 AC-2 CIAC-1 CIAC-2; do
    case "$(g13_verdict "$JM6236_2" "$g13id")/$(g13_observed "$JM6236_2" "$g13id")" in
      "ERROR/count-unreadable:matcher-exit-3 (the matcher produced no readable result"*) G13M2_HIT=$((G13M2_HIT + 1)) ;;
      *) printf '       g13 %s: %s / %s\n' "$g13id" "$(g13_verdict "$JM6236_2" "$g13id")" "$(g13_observed "$JM6236_2" "$g13id")" ;;
    esac
  done
  G13M2_REST="$(g13_failing "$JM6236_2" AC-3 AC-4 AC-5 CIAC-3 CIAC-4 CIAC-5)"
  [ "$G13M2_HIT" -eq 4 ] && [ -z "$G13M2_REST" ] && [ "$(count_verdict "$JM6236_2" ERROR)" = "4" ] && [ "$RCM6236_2" -eq 3 ] \
    && ok "G13-M2 V6236-AC4 mutation detected — with the verb check disabled the four refused-tool rows (AC-1, AC-2, CIAC-1, CIAC-2) read ERROR count-unreadable:matcher-exit-3, no other row moves, and the plan exits 3, so G13-2 and G13-3 flip" \
    || bad "G13-M2 V6236-AC4 $G13M2_HIT of 4 refused-tool rows read ERROR matcher-exit-3, other rows failing:${G13M2_REST:- none}, ERROR=$(count_verdict "$JM6236_2" ERROR), rc=$RCM6236_2 (expected 4, none, 4 and 3)"
fi

rm -rf "$MUTD6"

# ===========================================================================
# G14 — PREDICATE CLASS IS A READER ANNOTATION (V6180-AC5): a row is graded from
#       its Verification method cell alone.
#
# {{ADR:a-rows-grading-route-is-declared-in-its-method-cell}} removed the
# classifier's dormant class-hint path rather than wiring it: its only caller had
# passed an empty class since the executor's first commit, so the column plans
# author never shaped a verdict. A row is routed away from the executor only by a
# declaration IN its method cell, in the one declared-deferred form (bracket or
# phrase spelling). (a) is RED on the pre-removal tool. (b) is GREEN on both
# tools, because the hint was unreachable before too — so (c) re-introduces a class
# read and must move a row: a green arm alone is not evidence.
# ===========================================================================
echo
echo "G14 — #6180: the Predicate class column is a reader annotation (V6180-AC5)"

FIX_CINERT="release/tools/tests/fixtures/verify-plan-class-inert.md"
FIX_CINERTCTL="release/tools/tests/fixtures/verify-plan-class-inert-control.md"
G14_ROWS="AC-1 AC-2 AC-3 AC-4"

# --- G14-0: DENOMINATOR FIRST — both twins still declare their four rows. ---
G14_N="$(grep -c -F '| AC-' "$REPO_ROOT/$FIX_CINERT" || true)"
G14_NC="$(grep -c -F '| AC-' "$REPO_ROOT/$FIX_CINERTCTL" || true)"
[ "${G14_N:-0}" -eq 4 ] && [ "${G14_NC:-0}" -eq 4 ] \
  && ok "G14-0 V6180-AC5b both twins still declare their 4 rows (without them every arm below is vacuous)" \
  || bad "G14-0 V6180-AC5b the twins declare ${G14_N:-0} and ${G14_NC:-0} rows (expected 4 and 4); the arms below would grade nothing"

# --- G14-1..G14-4: (a) the shipped tool carries no class-hint path. ---
PVP_BODY="$(sed -n '/^parse_verification_plan()/,/^}/p' "$VERIFY")"
PCI_BODY="$(sed -n '/^parse_ciac()/,/^}/p' "$VERIFY")"
[ "$(grep -c '' <<<"$PVP_BODY")" -ge 150 ] || bad "G14 V6180-AC5a the per-issue parser body did not extract; the zero below would be vacuous"
G14_HINT="$(grep -c -F 'predicate-class hint' "$VERIFY" || true)"
[ "$G14_HINT" = "0" ] \
  && ok "G14-1 V6180-AC5a no surface of the executor claims a predicate-class hint" \
  || bad "G14-1 V6180-AC5a the executor still claims a predicate-class hint on $G14_HINT line(s)"
G14_PVP="$(grep -c -F 'col_pred' <<<"$PVP_BODY" || true)"
[ "$G14_PVP" = "0" ] \
  && ok "G14-2 V6180-AC5a the per-issue parser resolves no class value" \
  || bad "G14-2 V6180-AC5a the per-issue parser still resolves a class value ($G14_PVP col_pred line(s))"
[ "$(grep -c -F 'col_pred' <<<"$PCI_BODY" || true)" -ge 1 ] \
  && ok "G14-3 V6180-AC5a CONTROL — the CIAC parser still reads its own Predicate field (a different field, kept)" \
  || bad "G14-3 V6180-AC5a the CIAC Predicate field was removed too — over-deletion"
[ "$(grep -c -F 'if (h_method == 0 && (h_ac > 0 || h_expected > 0 || h_pred > 0)) {' "$VERIFY" || true)" = "1" ] \
  && ok "G14-4 V6180-AC5a ADR-168's discriminator is intact — the header word still counts toward the unindexable latch" \
  || bad "G14-4 V6180-AC5a ADR-168's discriminator line changed"

# --- G14-5..G14-9: (b) every row grades identically with and without the column. ---
vrp_run "$VERIFY" "$FIX_CINERT";    J_CI="$VRP_JSON"
vrp_run "$VERIFY" "$FIX_CINERTCTL"; J_CIC="$VRP_JSON"
G14_DIFF=""
for g14a in $G14_ROWS; do
  g14f="$(family_of "$J_CI" "$g14a")/$(verdict_of "$J_CI" "$g14a")"
  g14c="$(family_of "$J_CIC" "$g14a")/$(verdict_of "$J_CIC" "$g14a")"
  case "$g14f" in /*|*/) G14_DIFF="$G14_DIFF $g14a=absent"; continue ;; esac
  [ "$g14f" = "$g14c" ] || G14_DIFF="$G14_DIFF $g14a=$g14f/vs/$g14c"
done
[ -z "$G14_DIFF" ] && [ "$(rows_of "$J_CI")" = "4" ] && [ "$(rows_of "$J_CIC")" = "4" ] \
  && ok "G14-5 V6180-AC5b every row is present and grades identically with and without the class column (4 of 4 indexed in each twin)" \
  || bad "G14-5 V6180-AC5b rows absent or moved by the class column:${G14_DIFF:- none}; indexed $(rows_of "$J_CI") and $(rows_of "$J_CIC") (expected 4 and 4)"
[ "$(family_of "$J_CI" AC-1)/$(verdict_of "$J_CI" AC-1)" = "deferred/SKIP" ] \
  && ok "G14-6 V6180-AC5b AC-1 the declared-deferred form in the method cell, bracket spelling → deferred/SKIP" \
  || bad "G14-6 V6180-AC5b AC-1 got $(family_of "$J_CI" AC-1)/$(verdict_of "$J_CI" AC-1) (expected deferred/SKIP)"
[ "$(family_of "$J_CI" AC-2)/$(verdict_of "$J_CI" AC-2)" = "deferred/SKIP" ] \
  && ok "G14-7 V6180-AC5b AC-2 the declared-deferred form in the method cell, phrase spelling → deferred/SKIP" \
  || bad "G14-7 V6180-AC5b AC-2 got $(family_of "$J_CI" AC-2)/$(verdict_of "$J_CI" AC-2) (expected deferred/SKIP)"
G14_V3="$(verdict_of "$J_CI" AC-3)"
[ -n "$G14_V3" ] && [ "$G14_V3" != "PASS" ] \
  && ok "G14-8 V6180-AC5b AC-3 a class cell alone earns nothing — present and not PASS ($(family_of "$J_CI" AC-3)/$G14_V3)" \
  || bad "G14-8 V6180-AC5b AC-3 read '${G14_V3:-absent}' (expected present and not PASS)"
[ "$(family_of "$J_CI" AC-4)/$(verdict_of "$J_CI" AC-4)" = "per-issue/PASS" ] \
  && ok "G14-9 V6180-AC5b AC-4 a class never displaces a runnable probe → per-issue/PASS" \
  || bad "G14-9 V6180-AC5b AC-4 got $(family_of "$J_CI" AC-4)/$(verdict_of "$J_CI" AC-4) (expected per-issue/PASS)"

# --- G14-M: (c) SEEDED FAILURE — a class read re-introduced ahead of the keyword arms. ---
# The mutant prefixes a runtime-suite subtype token to the method of every row whose
# class cell reads runtime or behavioral, so the column routes again. It is proved to
# apply at EXACTLY one site (a substitution never adds or removes a line, so a
# line-by-line comparison counts its sites), and it must then move AC-3 between the
# twins. AC-3's control family is checked as present and different rather than
# pinned, so a later residual that re-routes a command-less row keeps the arm green.
MUTD6180="$(mktemp -d -t verify-plan-6180-mut.XXXXXX)"
MUT6180="$MUTD6180/class-read.sh"
sed -E 's@^      rec\(issue, ac, "PENDING", method, expected\)$@      rec(issue, ac, "PENDING", ((h_pred > 0 \&\& h_pred <= n \&\& tolower(F[h_pred]) ~ /runtime|behavioral/) ? "suite-skip; " : "") method, expected)@' "$VERIFY" > "$MUT6180"
chmod +x "$MUT6180"
G14_SITES="$(awk 'NR == FNR { a[FNR] = $0; next } a[FNR] != $0 { n++ } END { print n + 0 }' "$VERIFY" "$MUT6180")"
if [ "$G14_SITES" -ne 1 ]; then
  bad "G14-M V6180-AC5c mutation applied at $G14_SITES site(s), expected exactly 1; (b) would be graded against the wrong change, or none"
else
  ok "G14-M V6180-AC5c mutation applied at exactly 1 site: a class-cell read re-introduced ahead of the keyword arms"
  vrp_run "$MUT6180" "$FIX_CINERTCTL"; JM_CIC="$VRP_JSON"
  vrp_run "$MUT6180" "$FIX_CINERT";    JM_CI="$VRP_JSON"
  if mutant_ran "G14-M V6180-AC5c"; then
    G14_MF3="$(family_of "$JM_CI" AC-3)"; G14_MC3="$(family_of "$JM_CIC" AC-3)"
    [ "$G14_MF3" = "runtime-suite" ] && [ -n "$G14_MC3" ] && [ "$G14_MC3" != "$G14_MF3" ] \
      && ok "G14-M V6180-AC5c mutation detected — with a class read restored, AC-3 grades $G14_MF3 with the column and $G14_MC3 without it, so G14-5 flips" \
      || bad "G14-M V6180-AC5c SURVIVED — AC-3 reads '${G14_MF3:-absent}' with the column and '${G14_MC3:-absent}' without it; the class read moved nothing, so V6180-AC5b proves nothing"
  fi
fi
rm -rf "$MUTD6180"

# ===========================================================================
# G15 — A RUNNABLE PROBE IS EXECUTED, NEVER ROUTED BY PROSE (V6893-AC2/AC3/AC4,
#       V6837-AC2, V7531-AC3).
#
# classify_family hands a row whose designated command — extract_command's pick,
# a backticked span — is a probe this executor runs (an allowlisted verb, at least
# one argument, no shell operator outside quotes; span_shell_operator is the one
# quote-aware test) to the per-issue handler AHEAD of every keyword arm, and every
# declared-deferral reader reads the cell with each span led by an allowlisted verb
# blanked. So a prose word cannot hand a failing probe to the deploy oracle, a
# subtype token cannot divert a head probe, a phrase inside a probe is its pattern,
# and a quoted operator character is literal. Rows with no runnable probe keep the
# keyword fallback, could-not-read stays ERROR beside a declared SKIP, and --help
# describes the dispatch it performs.
#
# The plan is written into a temp stub root whose deploy check exits 0, so a row
# the oracle grades reads PASS there and a probe that FAILs is visibly not the
# oracle's verdict. Its tables keep the design's AC-1..AC-15 numbering; AC-16..AC-18
# are the quoted-pattern and deploy-span rows. Every record read here carries no
# brace, so the shared family_of / verdict_of / observed_of readers see each one,
# and every negated assertion first requires its record to be present. Each seeded
# failure is proved to apply at exactly the sites it names, and only a mutation
# that took is graded.
# ===========================================================================
echo
echo "G15 — #6893: a runnable probe is executed, never routed by prose (V6893-AC2/AC3/AC4, V6837-AC2, V7531-AC3)"
G15STUB="$(mktemp -d -t verify-plan-6893-stub.XXXXXX)"; MUTD6893="$(mktemp -d -t verify-plan-6893-mut.XXXXXX)"
mkdir -p "$G15STUB/core/deploy" "$G15STUB/release/tools" "$G15STUB/plan"
cp "$VERIFY" "$G15STUB/release/tools/"
printf '#!/usr/bin/env bash\nexit 0\n' > "$G15STUB/core/deploy/deploy.sh"; chmod +x "$G15STUB/core/deploy/deploy.sh"
cat > "$G15STUB/plan/p.md" <<'EOF'
# vTEST Release Plan — a runnable probe is executed, never routed by prose (G15)

## Verification Plan

**#960 — a runnable probe is never displaced by prose**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `grep -c -F 'zz-absent-probe-token' release/tools/verify-release-plan.sh` at least 1; the design around it stands unchanged | FAIL: the probe runs and finds nothing |
| AC-2 | `grep -c -F 'RUNNABLE_VERBS=' release/tools/verify-release-plan.sh` at least 1, then a byte-diff via deploy.sh --check | PASS: the probe runs |
| AC-3 | `head -n 1 release/tools/verify-release-plan.sh` at least 1; the declared outcome of the suite run is suite-skip | PASS: the probe runs |
| AC-4 | `grep -c -F 'deferred to #' plan/p.md` at least 1 | PASS: a phrase inside the probe is its pattern |
| AC-5 | `grep -c -F 'RUNNABLE_VERBS=' release/tools/verify-release-plan.sh` at least 1; recorded for the cross-issue integration read | PASS, family per-issue |
| AC-6 | [DEFERRED — graded by the Stage 8 reader] `grep -c -F 'zz-absent-probe-token' release/tools/verify-release-plan.sh` at least 1 | SKIP: a declaration outside the probe still wins |
| AC-7 | `grep` the deploy log for drift; the hook arms stay unchanged | not per-issue: a bare verb is not a probe |
| AC-8 | `ls release/tools \| wc -l` at least 1; the tree stays unchanged | not per-issue: a pipeline is not a probe this executor runs |

**#961 — rows with no runnable probe keep the keyword fallback**

| AC | Verification method | Expected result |
|---|---|---|
| AC-9 | source-to-deployed sync via `deploy.sh --check` | sync |
| AC-10 | the other arms stay byte-identical: unchanged | regression |
| AC-11 | cross-issue integration read of the recorded decision | integration, documented-decision SKIP |
| AC-12 | the declared outcome of this suite run is suite-skip | runtime-suite SKIP |

**#962 — could not evaluate, beside not this runner's job**

| AC | Verification method | Expected result |
|---|---|---|
| AC-13 | declared, verification deferred to the Stage 8 named read of the decision record | SKIP: declared in the method cell |
| AC-14 | `grep -c -F 'x' release/tools/tests/fixtures/verify-plan-no-such-fixture.md` expect 0 | ERROR: the probe input could not be read |
| AC-15 |  | ERROR: an empty method cell |

**#963 — a quoted pattern is literal, and a probe outranks the deploy-check span**

| AC | Verification method | Expected result |
|---|---|---|
| AC-16 | `grep -c -F '<!-- zz-marker-a' plan/p.md` expect 0; the hook arms stay unchanged | FAIL: a quoted operator character is literal, so the probe runs |
| AC-17 | `grep -c -F '<!-- zz-marker-b deferred to #' plan/p.md` at least 1 | PASS: a phrase inside a quoted-marker probe is its pattern |
| AC-18 | `bash core/deploy/deploy.sh --check` exits 0, and `grep -c -F 'RUNNABLE_VERBS=' release/tools/verify-release-plan.sh` at least 1 | PASS: the probe grades the row; the deploy check does not run |
EOF
# g15_run <tool> — sets VRP_JSON + VRP_RC in the CURRENT shell (vrp_run's contract).
g15_run() { set +e; VRP_JSON="$("$1" --format=json --root "$G15STUB" "$G15STUB/plan/p.md" 2>/dev/null)"; VRP_RC=$?; set -e; }
# fv15 <json> <id> — "family/verdict"; reads "/" for an absent record, which no arm expects.
fv15() { printf '%s/%s' "$(family_of "$1" "$2")" "$(verdict_of "$1" "$2")"; }
# g15_present_not <json> <id> <family> — TRUE only when the record is PRESENT and its
# family is not <family>: an absent record never passes a negated assertion.
g15_present_not() { local f; f="$(family_of "$1" "$2")"; [ -n "$f" ] && [ "$f" != "$3" ]; }
# m15 <label> <stem> <sites> <sed-expr> — publish the mutant in MUT_PATH, count the
# lines it changed (a substitution never adds or removes a line), and set MUT_TOOK
# only when it applied at exactly <sites> lines. An arm whose mutation did not take
# is not graded: its answer would be the shipped tool's, a vacuous detection.
MUT_TOOK=0
m15() {
  local label="$1" stem="$2" want="$3" e="$4" dst n
  dst="$MUTD6893/$stem.sh"
  cp "$VERIFY" "$dst"
  sed -i.bak -E "$e" "$dst"
  rm -f "$dst.bak"
  chmod +x "$dst"
  MUT_PATH="$dst"
  n="$(awk 'NR == FNR { a[FNR] = $0; next } a[FNR] != $0 { n++ } END { print n + 0 }' "$VERIFY" "$dst")"
  if [ "$n" -eq "$want" ]; then
    MUT_TOOK=1; ok "$label — mutation applied at exactly $want site(s): the mutant differs from the shipped tool in $n line(s)"
  else
    MUT_TOOK=0; bad "$label — mutation applied at $n site(s), expected exactly $want; its arm is not graded"
  fi
}

g15_run "$VERIFY"; J15="$VRP_JSON"; RC15="$VRP_RC"
# --- G15-0: DENOMINATOR FIRST — every stub-plan row emits. ---
[ "$(grep -c '"id":"AC-' <<<"$J15" || true)" -eq 18 ] \
  && ok "G15-0 SENSITIVITY — all 18 stub-plan rows emit (the arms below grade real records)" \
  || bad "G15-0 expected 18 AC records, got $(grep -c '"id":"AC-' <<<"$J15" || true)"

# --- V6893-AC2: no prose displaces a runnable probe; a declaration outside it still wins. ---
[ "$(fv15 "$J15" AC-1)" = "per-issue/FAIL" ] && [ "$(observed_of "$J15" AC-1)" = "count=0 (wanted >= 1)" ] \
  && ok "V6893-AC2 a — 'unchanged' no longer sends a failing probe to the deploy oracle: it runs and FAILs" \
  || bad "V6893-AC2 a — AC-1 got $(fv15 "$J15" AC-1) '$(observed_of "$J15" AC-1)'"
[ "$(fv15 "$J15" AC-2)" = "per-issue/PASS" ] \
  && ok "V6893-AC2 b — byte-diff and deploy.sh --check prose do not displace the probe" \
  || bad "V6893-AC2 b — AC-2 got $(fv15 "$J15" AC-2)"
[ "$(fv15 "$J15" AC-3)" = "per-issue/PASS" ] \
  && ok "V6893-AC2 c — a subtype token does not displace a head probe" \
  || bad "V6893-AC2 c — AC-3 got $(fv15 "$J15" AC-3)"
[ "$(fv15 "$J15" AC-4)" = "per-issue/PASS" ] \
  && ok "V6893-AC2 d — a deferral phrase inside the probe is its pattern" \
  || bad "V6893-AC2 d — AC-4 got $(fv15 "$J15" AC-4)"
[ "$(fv15 "$J15" AC-5)" = "per-issue/PASS" ] \
  && ok "V6893-AC2 e — an 'integration' word no longer relabels a probe" \
  || bad "V6893-AC2 e — AC-5 got $(fv15 "$J15" AC-5)"
[ "$(fv15 "$J15" AC-6)" = "deferred/SKIP" ] \
  && ok "V6893-AC2 f CONTROL — a declaration outside the probe still wins" \
  || bad "V6893-AC2 f — AC-6 got $(fv15 "$J15" AC-6)"
g15_present_not "$J15" AC-7 per-issue && g15_present_not "$J15" AC-8 per-issue \
  && ok "V6893-AC2 g BOUNDARY — a bare verb and a pipeline are not probes (AC-7 $(fv15 "$J15" AC-7), AC-8 $(fv15 "$J15" AC-8))" \
  || bad "V6893-AC2 g — AC-7 $(fv15 "$J15" AC-7) / AC-8 $(fv15 "$J15" AC-8): absent, or claimed as probes"
[ "$(fv15 "$J15" AC-16)" = "per-issue/FAIL" ] && [ "$(observed_of "$J15" AC-16)" = "count=1 (wanted == 0)" ] \
  && ok "V6893-AC2 h — a quoted marker is a pattern, not an operator: the failing probe beside 'unchanged' runs and FAILs" \
  || bad "V6893-AC2 h — AC-16 got $(fv15 "$J15" AC-16) '$(observed_of "$J15" AC-16)'"
[ "$(fv15 "$J15" AC-17)" = "per-issue/PASS" ] \
  && ok "V6893-AC2 i — a deferral phrase inside a quoted-marker probe is its pattern, not a declaration" \
  || bad "V6893-AC2 i — AC-17 got $(fv15 "$J15" AC-17)"
case "$(observed_of "$J15" AC-18)" in count=*) G15_P18=1 ;; *) G15_P18=0 ;; esac
[ "$(fv15 "$J15" AC-18)" = "per-issue/PASS" ] && [ "$G15_P18" = 1 ] \
  && ok "V6893-AC2 j — a probe beside the deploy.sh --check span grades the row; the deploy check does not ($(observed_of "$J15" AC-18))" \
  || bad "V6893-AC2 j — AC-18 got $(fv15 "$J15" AC-18) '$(observed_of "$J15" AC-18)'"

# --- V6893-AC3: rows with no runnable probe keep the keyword fallback (each control carries a routing keyword). ---
if [ "$(fv15 "$J15" AC-9)" = "sync/PASS" ] && [ "$(fv15 "$J15" AC-10)" = "regression/PASS" ] \
   && [ "$(fv15 "$J15" AC-11)" = "integration/SKIP" ] && [ "$(fv15 "$J15" AC-12)" = "runtime-suite/SKIP" ]; then
  ok "V6893-AC3 — command-less rows keep sync / regression / integration / runtime-suite"
else
  bad "V6893-AC3 — the keyword fallback moved for a row with no runnable probe: $(fv15 "$J15" AC-9) $(fv15 "$J15" AC-10) $(fv15 "$J15" AC-11) $(fv15 "$J15" AC-12)"
fi

# --- V6837-AC2: could not evaluate stays ERROR, beside a declared SKIP. ---
[ "$(fv15 "$J15" AC-13)" = "deferred/SKIP" ] \
  && ok "V6837-AC2 a — a prose row declared in its method cell is a named SKIP" \
  || bad "V6837-AC2 a — AC-13 got $(fv15 "$J15" AC-13)"
case "$(observed_of "$J15" AC-14)" in
  *count-unreadable:matcher-exit-2*)
    [ "$(verdict_of "$J15" AC-14)" = ERROR ] \
      && ok "V6837-AC2 b — a probe whose input cannot be read is still ERROR" \
      || bad "V6837-AC2 b — AC-14 names the unreadable input but reads $(verdict_of "$J15" AC-14)" ;;
  *) bad "V6837-AC2 b — AC-14 observed '$(observed_of "$J15" AC-14)'" ;;
esac
[ "$(fv15 "$J15" AC-15)" = "method-cell-empty/ERROR" ] && [ "$RC15" -eq 3 ] \
  && ok "V6837-AC2 c — an empty method cell is ERROR; rc 3" \
  || bad "V6837-AC2 c — AC-15 $(fv15 "$J15" AC-15), rc $RC15"

# --- V7531-AC3: --help describes the dispatch the classifier performs. ---
H15="$("$VERIFY" --help 2>&1 || true)"
[ "$(grep -c -F 'CHECK FAMILIES' <<<"$H15" || true)" -eq 1 ] \
  && ok "V7531-AC3 SENSITIVITY — the help carries its CHECK FAMILIES line" \
  || bad "V7531-AC3 — no CHECK FAMILIES line in --help"
[ "$(grep -c -i -E 'predicate[- ]class|class hint|class column' <<<"$H15" || true)" -eq 0 ] \
  && ok "V7531-AC3 — --help makes no predicate-class claim" \
  || bad "V7531-AC3 — --help claims predicate-class dispatch"
[ "$(grep -c -F 'method cell' <<<"$H15" || true)" -ge 1 ] && [ "$(grep -c -F 'runnable probe' <<<"$H15" || true)" -ge 1 ] \
  && ok "V7531-AC3 — --help names the dispatch the classifier performs (the method cell; a runnable probe)" \
  || bad "V7531-AC3 — --help does not describe the dispatch (method cell / runnable probe)"

# --- V6893-AC4: SEEDED FAILURES. Each reverts one limb and names the answer it must move. ---
m15 "V6893-AC4 M1" g15-m1-no-probe-step 1 's/^  if \[ -n "\$probe" \]; then echo "per-issue"; return; fi$/  :/'
if [ "$MUT_TOOK" = 1 ]; then
  g15_run "$MUT_PATH"; JM15_1="$VRP_JSON"
  if mutant_ran "V6893-AC4 M1"; then
    [ "$(fv15 "$JM15_1" AC-1)" = "regression/PASS" ] && [ "$(fv15 "$JM15_1" AC-3)" = "runtime-suite/SKIP" ] \
      && ok "V6893-AC4 M1 detected — without the probe step the failing probe is graded PASS by the deploy oracle again" \
      || bad "V6893-AC4 M1 SURVIVED — AC-1 $(fv15 "$JM15_1" AC-1), AC-3 $(fv15 "$JM15_1" AC-3)"
    G15_SAME=1
    for g15a in AC-9 AC-10 AC-11 AC-12; do [ "$(fv15 "$JM15_1" "$g15a")" = "$(fv15 "$J15" "$g15a")" ] || G15_SAME=0; done
    [ "$G15_SAME" = 1 ] \
      && ok "V6893-AC4 M1 CONTROL — the step touches only rows with a runnable probe" \
      || bad "V6893-AC4 M1 CONTROL — a command-less row moved"
  fi
fi
m15 "V6893-AC4 M2" g15-m2-step0-raw 1 's/^  prose="\$\(method_outside_verb_spans .*$/  prose="$method"/'
if [ "$MUT_TOOK" = 1 ]; then
  g15_run "$MUT_PATH"; JM15_2="$VRP_JSON"
  if mutant_ran "V6893-AC4 M2"; then
    [ "$(fv15 "$JM15_2" AC-4)" = "deferred/SKIP" ] && [ "$(fv15 "$JM15_2" AC-17)" = "deferred/SKIP" ] \
      && ok "V6893-AC4 M2 detected — step 0 on the raw cell lets an in-probe phrase displace the probe again" \
      || bad "V6893-AC4 M2 SURVIVED — AC-4 $(fv15 "$JM15_2" AC-4), AC-17 $(fv15 "$JM15_2" AC-17)"
  fi
fi
m15 "V6893-AC4 M3" g15-m3-guard-raw 2 's/case "\$\(method_outside_verb_spans "\$method"\)" in/case "$method" in/'
if [ "$MUT_TOOK" = 1 ]; then
  g15_run "$MUT_PATH"; JM15_3="$VRP_JSON"
  if mutant_ran "V6893-AC4 M3"; then
    [ "$(fv15 "$JM15_3" AC-4)" = "per-issue/SKIP" ] && [ "$(observed_of "$JM15_3" AC-4)" = "declared-deferred" ] \
      && ok "V6893-AC4 M3 detected — a raw-cell handler guard skips the routed probe again" \
      || bad "V6893-AC4 M3 SURVIVED — AC-4 $(fv15 "$JM15_3" AC-4) '$(observed_of "$JM15_3" AC-4)'"
  fi
fi
m15 "V7531-AC3 M4" g15-m4-help-claim 1 's/CHECK FAMILIES \(dispatched from the Verification method cell alone[^)]*\)/CHECK FAMILIES (dispatched by predicate-class hint, else method keyword)/'
if [ "$MUT_TOOK" = 1 ]; then
  HM15_4="$("$MUT_PATH" --help 2>&1 || true)"
  if [ "$(grep -c -F 'CHECK FAMILIES' <<<"$HM15_4" || true)" -eq 1 ]; then
    [ "$(grep -c -i -E 'predicate[- ]class|class hint|class column' <<<"$HM15_4" || true)" -eq 1 ] \
      && ok "V7531-AC3 M4 detected — the old wording restored reads 1" \
      || bad "V7531-AC3 M4 SURVIVED — the restored claim reads $(grep -c -i -E 'predicate[- ]class|class hint|class column' <<<"$HM15_4" || true)"
  else
    bad "V7531-AC3 M4 NOT GRADEABLE — the mutant printed no CHECK FAMILIES line"
  fi
fi
m15 "V6893-AC2 M5" g15-m5-quote-blind 1 's/ q="\$ch" ;;$/ : ;;/'
if [ "$MUT_TOOK" = 1 ]; then
  g15_run "$MUT_PATH"; JM15_5="$VRP_JSON"
  if mutant_ran "V6893-AC2 M5"; then
    [ "$(fv15 "$JM15_5" AC-16)" = "regression/PASS" ] \
      && ok "V6893-AC2 M5 detected — a quote-blind operator scan reads the quoted marker as an operator and hands the failing probe to the deploy oracle" \
      || bad "V6893-AC2 M5 SURVIVED — AC-16 $(fv15 "$JM15_5" AC-16)"
  fi
fi
rm -rf "$G15STUB" "$MUTD6893"

# ===========================================================================
# G16 — A METHOD NAMING SEVERAL COMMANDS IS GRADED ON ITS DESIGNATED COMMAND
#       (V6837-AC4, V7531-CIAC6).
#
# The per-issue and integration handlers run the designated command — the first
# allowlisted verb that carries an argument — against the comparator stated after
# it, and name every other command the method carries as "did not run (<reason>)".
# A row with a command that did not run never reads PASS: it takes the can't-run
# slot the executor binds as VERDICT_PARTIAL_SLOT, and every arm here DERIVES the
# slot's value from that one line rather than pinning it, so a re-binding of the
# slot keeps the arms meaningful. A bare verb is prose. The shared comparator
# vocabulary reads markdown emphasis around N and nothing wider. An operand-less
# further command is never run, so no row after it is lost.
#
# The fixture's counts come from its own data section. Every arm first requires
# the record it grades to be present, and every record read here carries no brace,
# so the shared readers see each one. Each seeded failure is proved to apply at
# exactly the sites it names, and only a mutation that took is graded.
# ===========================================================================
echo
echo "G16 — #6837: a method naming several commands is graded on its designated command (V6837-AC4, V7531-CIAC6)"
MUTD6837="$(mktemp -d -t verify-plan-6837-mut.XXXXXX)"
FIX_LIMB="release/tools/tests/fixtures/verify-plan-multi-limb.md"
eval "$(sed -n '/^comparator_phrases()/,/^}/p' "$VERIFY")"
eval "$(sed -n '/^limb_comparator()/,/^}/p'    "$VERIFY")"
# The slot's value, derived from its one binding line: the name after $VERDICT_.
PARTIAL_SLOT="$(sed -n 's/^readonly VERDICT_PARTIAL_SLOT="\$VERDICT_\([A-Z]*\)".*/\1/p' "$VERIFY")"
# fv16 <json> <id> — "family/verdict"; reads "/" for an absent record, which no arm expects.
fv16() { printf '%s/%s' "$(family_of "$1" "$2")" "$(verdict_of "$1" "$2")"; }
# g16_slot <json> <id> — TRUE only when the slot is derived and the record reads it.
g16_slot() { [ -n "$PARTIAL_SLOT" ] && [ "$(verdict_of "$1" "$2")" = "$PARTIAL_SLOT" ]; }
# g16_has <json> <id> <text> — TRUE only when the record's observed text carries <text>.
g16_has() { case "$(observed_of "$1" "$2")" in *"$3"*) return 0 ;; *) return 1 ;; esac; }
# g16_partial <json> <id> — the slot, with the observed text leading "partial-execution:".
g16_partial() { g16_slot "$1" "$2" && case "$(observed_of "$1" "$2")" in "partial-execution: limbs run 1 of "*) return 0 ;; *) return 1 ;; esac; }
# m16 <label> <stem> <sites> <sed-expr>... — publish the mutant in MUT_PATH, count the
# lines it changed (a substitution never adds or removes a line), and set MUT_TOOK
# only when it applied at exactly <sites> lines. An arm whose mutation did not take
# is not graded: its answer would be the shipped tool's, a vacuous detection.
m16() {
  local label="$1" stem="$2" want="$3" dst n e
  shift 3
  dst="$MUTD6837/$stem.sh"
  cp "$VERIFY" "$dst"
  for e in "$@"; do sed -i.bak -E "$e" "$dst"; done
  rm -f "$dst.bak"
  chmod +x "$dst"
  MUT_PATH="$dst"
  n="$(awk 'NR == FNR { a[FNR] = $0; next } a[FNR] != $0 { n++ } END { print n + 0 }' "$VERIFY" "$dst")"
  if [ "$n" -eq "$want" ]; then
    MUT_TOOK=1; ok "$label — mutation applied at exactly $want site(s): the mutant differs from the shipped tool in $n line(s)"
  else
    MUT_TOOK=0; bad "$label — mutation applied at $n site(s), expected exactly $want; its arm is not graded"
  fi
}

vrp_run "$VERIFY" "$FIX_LIMB"; J16="$VRP_JSON"; RC16="$VRP_RC"
# --- G16-0: DENOMINATOR FIRST — the fixture still plants, and every row emits. ---
G16_PAIRED="$(grep -c -F 'paired arm' "$REPO_ROOT/$FIX_LIMB" || true)"
[ "${G16_PAIRED:-0}" -ge 3 ] && [ "$(acs_of "$J16")" = "14" ] && [ "$(ciacs_of "$J16")" = "5" ] \
  && ok "G16-0 SENSITIVITY — the fixture plants its multi-command rows ($G16_PAIRED 'paired arm' lines) and all 14 rows and 5 CIACs emit" \
  || bad "G16-0 fixture 'paired arm' lines=$G16_PAIRED, emitted AC=$(acs_of "$J16") CIAC=$(ciacs_of "$J16") (expected >= 3, 14 and 5)"

# --- V6837-AC4: the designated command is graded on its own comparator; the rest are named, never passed. ---
if [ -n "$PARTIAL_SLOT" ] && [ "$PARTIAL_SLOT" != PASS ] \
   && [ "$(grep -c -E "^readonly VERDICT_${PARTIAL_SLOT}=" "$VERIFY" || true)" = "1" ]; then
  ok "V6837-AC4 — the can't-run slot is bound once, to a verdict the file declares that is not PASS ($PARTIAL_SLOT)"
else
  bad "V6837-AC4 — VERDICT_PARTIAL_SLOT is unbound, bound to PASS, or bound to an undeclared verdict ('$PARTIAL_SLOT')"
fi
g16_partial "$J16" AC-1 && g16_has "$J16" AC-1 "limb 1 grep PASS count=2 (== 2); limb 2 grep did not run (only the designated command runs)" \
  && ok "V6837-AC4 a — two commands, the designated one holds: the slot, naming the command that ran and the one that did not" \
  || bad "V6837-AC4 a — AC-1 $(fv16 "$J16" AC-1) '$(observed_of "$J16" AC-1)'"
G16_V2="$(verdict_of "$J16" AC-2)"; G16_C2="$(verdict_of "$J16" CIAC-2)"
[ -n "$G16_V2" ] && [ "$G16_V2" != PASS ] && [ -n "$G16_C2" ] && [ "$G16_C2" != PASS ] \
   && g16_has "$J16" AC-2 "limb 2 grep did not run" && g16_has "$J16" CIAC-2 "limb 2 grep did not run" \
  && ok "V6837-AC4 b — a false value in a NON-FIRST command: the row does not read PASS, in either loop, and names that command as not run" \
  || bad "V6837-AC4 b — AC-2 '$G16_V2' / CIAC-2 '$G16_C2' '$(observed_of "$J16" AC-2)'"
[ "$(fv16 "$J16" AC-3)" = "per-issue/FAIL" ] \
  && ok "V6837-AC4 c CONTROL — the same false value in the FIRST command already FAILs" \
  || bad "V6837-AC4 c — AC-3 $(fv16 "$J16" AC-3)"
g16_has "$J16" AC-3 "limbs run 1 of 2: limb 1 grep FAIL count=2 (wanted == 3); limb 2 grep did not run" \
  && ok "V6837-AC4 d — a comparator binds to the command it follows: AC-3's designated command is graded against its own 'expect 3', not the next command's" \
  || bad "V6837-AC4 d — AC-3 '$(observed_of "$J16" AC-3)'"
g16_partial "$J16" AC-4 && g16_has "$J16" AC-4 "limb 2 grep did not run (only the designated command runs)" \
  && ok "V6837-AC4 e — a second command with no comparator the vocabulary reads is named as not run, never passed" \
  || bad "V6837-AC4 e — AC-4 $(fv16 "$J16" AC-4) '$(observed_of "$J16" AC-4)'"
g16_partial "$J16" AC-7 && g16_has "$J16" AC-7 "limb 1 grep PASS count=0 (== 0)" \
   && [ "$(fv16 "$J16" AC-8)" = "per-issue/FAIL" ] && g16_has "$J16" AC-8 "limb 1 grep FAIL count=2 (wanted == 0)" \
  && ok "V6837-AC4 f — a null is graded on its own 'expect 0': AC-7's holds (the control did not run), and AC-8's violated null FAILs where the whole-cell reading passed it" \
  || bad "V6837-AC4 f — AC-7 $(fv16 "$J16" AC-7) '$(observed_of "$J16" AC-7)'; AC-8 $(fv16 "$J16" AC-8) '$(observed_of "$J16" AC-8)'"
[ "$(fv16 "$J16" AC-10)" = "per-issue/PASS" ] && [ "$(observed_of "$J16" AC-10)" = "count=2 (== 2)" ] \
   && [ "$(observed_of "$J16" AC-9)" = "command-succeeded" ] && [ "$(observed_of "$J16" CIAC-5)" = "integration-method-succeeded" ] \
  && ok "V6837-AC4 g CONTROL — a method naming one command is graded exactly as before (AC-9, AC-10, CIAC-5)" \
  || bad "V6837-AC4 g — AC-10 $(fv16 "$J16" AC-10) '$(observed_of "$J16" AC-10)'; AC-9 '$(observed_of "$J16" AC-9)'; CIAC-5 '$(observed_of "$J16" CIAC-5)'"
g16_partial "$J16" CIAC-1 && g16_has "$J16" CIAC-1 "limb 2 grep did not run (only the designated command runs)" \
  && ok "V6837-AC4 h — the cross-issue handler takes the same path: CIAC-1 reads the slot and names its unrun command" \
  || bad "V6837-AC4 h — CIAC-1 $(fv16 "$J16" CIAC-1) '$(observed_of "$J16" CIAC-1)'"
[ "$(fv16 "$J16" AC-13)" = "per-issue/PASS" ] && [ "$(observed_of "$J16" AC-13)" = "count=1 (== 1)" ] \
  && ok "V6837-AC4 i — a bare verb is prose: AC-13's leading bare grep is skipped and its probe is the designated command" \
  || bad "V6837-AC4 i — AC-13 $(fv16 "$J16" AC-13) '$(observed_of "$J16" AC-13)'"
[ "$(fv16 "$J16" AC-14)" = "per-issue/PASS" ] && [ "$(observed_of "$J16" AC-14)" = "count=1 (== 1)" ] \
  && ok "V6837-AC4 j CONTROL — a tool span is prose while the tool predicate names no tool: AC-14 grades as one command" \
  || bad "V6837-AC4 j — AC-14 $(fv16 "$J16" AC-14) '$(observed_of "$J16" AC-14)'"

# --- The shared comparator vocabulary: emphasis around N is read, and nothing wider. ---
[ "$(fv16 "$J16" AC-11)" = "per-issue/PASS" ] && [ "$(observed_of "$J16" AC-11)" = "count=0 (== 0)" ] \
  && ok "V6837-AC4 k — a comparator whose N carries markdown emphasis is read: 'expect **0**' grades count=0 (== 0)" \
  || bad "V6837-AC4 k — AC-11 $(fv16 "$J16" AC-11) '$(observed_of "$J16" AC-11)'"
[ "$(fv16 "$J16" AC-12)" = "per-issue/FAIL" ] && [ "$(observed_of "$J16" AC-12)" = "command-exit-1" ] \
  && ok "V6837-AC4 l CONTROL — 'returns 0' is not a comparator: the row is graded on the exit status, which reads a zero count as FAIL" \
  || bad "V6837-AC4 l — AC-12 $(fv16 "$J16" AC-12) '$(observed_of "$J16" AC-12)'"

# --- V7531-CIAC6: an operand-less further command never runs, so no later row is lost. ---
g16_partial "$J16" AC-5 && g16_partial "$J16" CIAC-3 \
   && g16_has "$J16" AC-5 "limb 2 grep did not run (names no input)" && g16_has "$J16" CIAC-3 "limb 2 grep did not run (names no input)" \
  && ok "V7531-CIAC6 a — a further command naming no input is named 'did not run (names no input)', never passed, in both loops" \
  || bad "V7531-CIAC6 a — AC-5 $(fv16 "$J16" AC-5) '$(observed_of "$J16" AC-5)'; CIAC-3 $(fv16 "$J16" CIAC-3)"
g16_partial "$J16" AC-6 && g16_partial "$J16" CIAC-4 \
   && g16_has "$J16" AC-6 "limb 2 grep did not run (names no input)" && g16_has "$J16" CIAC-4 "limb 2 grep did not run (names no input)" \
  && ok "V7531-CIAC6 b — one with a comparator of its own is not run either: it names no input, so nothing reads stdin" \
  || bad "V7531-CIAC6 b — AC-6 $(fv16 "$J16" AC-6) '$(observed_of "$J16" AC-6)'; CIAC-4 $(fv16 "$J16" CIAC-4)"
G16_LATE=0
for g16id in AC-7 AC-8 AC-9 AC-10 AC-11 AC-12 AC-13 AC-14 CIAC-5; do
  [ -n "$(verdict_of "$J16" "$g16id")" ] && G16_LATE=$((G16_LATE + 1))
done
[ "$G16_LATE" -eq 9 ] && [ "$(verdict_of "$J16" AC-9)" = PASS ] && [ "$(verdict_of "$J16" CIAC-5)" = PASS ] \
   && [ "$(strunc_of "$J16")" = "0" ] && grep -q -F '"stream_state": "fetched"' <<<"$J16" && [ "$RC16" -eq 3 ] \
  && ok "V7531-CIAC6 c — every limb that runs goes through the stdin-isolated dispatch, so no row after the planted cells is lost: 9 of 9 emit, the controls after them PASS, and the stream reads fetched; exit 3" \
  || bad "V7531-CIAC6 c — later rows present=$G16_LATE of 9, AC-9 '$(verdict_of "$J16" AC-9)', CIAC-5 '$(verdict_of "$J16" CIAC-5)', stream-truncated=$(strunc_of "$J16"), rc=$RC16"

# --- V6837-AC4: the one splitter, the one vocabulary, and the bare-verb rule, unit by unit. ---
EC16_OK=1
t_ec16() { [ "$(extract_command "$1")" = "$2" ] || { EC16_OK=0; printf '       extract_command mismatch: [%s] -> [%s], wanted [%s]\n' "$1" "$(extract_command "$1")" "$2"; }; }
t_ec16 'run `--self-test` (expect exit 0); then `grep -c -E "X" some/file.md` — expect exactly 3' 'grep -c -E "X" some/file.md'
t_ec16 '`grep -c x f` then `grep -c y f`' 'grep -c x f'
t_ec16 '``grep -c x f``' ''
t_ec16 'prose only, no spans' ''
t_ec16 'grep -c bare f' 'grep -c bare f'
t_ec16 '`python3 tools/x.py` and `awk 1 f`' 'python3 tools/x.py'
t_ec16 '`PARSE-07` then `release/x.sh`' 'PARSE-07'
t_ec16 '`grep`' ''
t_ec16 '`grep` the register, then `grep -c x f` expect 1' 'grep -c x f'
t_ec16 'trailing `' ''
t_ec16 '`  grep -c spaced f`' '  grep -c spaced f'
[ "$EC16_OK" = 1 ] \
  && ok "V6837-AC4 m — extract_command reads spans through the one splitter and skips a bare verb (11 pinned cases)" \
  || bad "V6837-AC4 m — extract_command departs from a pinned case (above)"
if type comparator_phrases >/dev/null 2>&1 && type limb_comparator >/dev/null 2>&1; then
  G16_CP="$(comparator_phrases 'at least 2, ≤ 3, expect zero, exactly 4' | tr '\t\n' ' |')"
  G16_EM="$(comparator_phrases 'expect **0**; at least __3__; ≥ *5*' | tr '\t\n' ' |')"
  G16_NW="$(comparator_phrases 'returns 0 and = 2 and → 4 and expects 1' | tr '\t\n' ' |')"
  [ "$G16_CP" = ">= 2|<= 3|== 0|== 4|" ] && [ "$G16_EM" = "== 0|>= 3|>= 5|" ] && [ -z "$G16_NW" ] \
    && ok "V6837-AC4 n — comparator_phrases reads every phrase in order, emphasis around N included, and no wider form" \
    || bad "V6837-AC4 n — comparator_phrases read [$G16_CP] [$G16_EM] [$G16_NW]"
  [ "$(limb_comparator 'at least 3; again at least 3' | tr '\t' ' ')" = ">= 3" ] && [ "$(limb_comparator 'expect 0 (at most 3 others)')" = "ambiguous" ] \
    && ok "V6837-AC4 o — limb_comparator counts a repeat once and reads two that disagree as ambiguous" \
    || bad "V6837-AC4 o — limb_comparator read '$(limb_comparator 'at least 3; again at least 3')' / '$(limb_comparator 'expect 0 (at most 3 others)')'"
else
  bad "V6837-AC4 n — comparator_phrases or limb_comparator is not defined in the executor"
  bad "V6837-AC4 o — limb_comparator is not defined in the executor"
fi
G16_ET="$(sed -n '/^extract_threshold()/,/^}/p' "$VERIFY")"; G16_PH="$(sed -n '/^comparator_phrases()/,/^}/p' "$VERIFY")"
G16_ETN="$(grep -o -E 'CMP_(GE|LE|EQ|EMPH)_ALT' <<<"$G16_ET" | sort -u | grep -c . || true)"
G16_PHN="$(grep -o -E 'CMP_(GE|LE|EQ|EMPH)_ALT' <<<"$G16_PH" | sort -u | grep -c . || true)"
[ "$G16_ETN" = "4" ] && [ "$G16_PHN" = "4" ] \
   && [ "$(grep -c -F 'at least' <<<"$G16_ET" || true)" = "0" ] && [ "$(grep -c -F 'at least' <<<"$G16_PH" || true)" = "0" ] \
  && ok "V6837-AC4 p — one vocabulary: extract_threshold and comparator_phrases each read all four CMP_*_ALT constants and carry no comparator literal of their own" \
  || bad "V6837-AC4 p — constants read: extract_threshold $G16_ETN of 4, comparator_phrases $G16_PHN of 4 (or a body still carries its own 'at least')"
H16="$("$VERIFY" --help 2>&1 || true)"
[ "$(grep -c -F 'MULTI-COMMAND METHODS' <<<"$H16" || true)" = "1" ] && [ "$(grep -c -F 'did not run' <<<"$H16" || true)" -ge 1 ] \
   && [ "$(grep -c -F 'designated command' <<<"$H16" || true)" -ge 1 ] \
  && ok "V6837-AC4 q — --help states how a multi-command method is graded (the designated command; the rest did not run)" \
  || bad "V6837-AC4 q — --help carries no MULTI-COMMAND METHODS section naming the designated command and 'did not run'"

# --- SEEDED FAILURES. Each reverts one limb and names the answer it must move to. ---
m16 "V6837-AC4 M1" g16-m1-unhooked 2 's/^  if limbs_are_multi "\$limbs"; then grade_limbs "\$limbs"; return; fi$/  :/'
if [ "$MUT_TOOK" = 1 ]; then
  vrp_run "$MUT_PATH" "$FIX_LIMB"; JM16_1="$VRP_JSON"
  if mutant_ran "V6837-AC4 M1"; then
    [ "$(verdict_of "$JM16_1" AC-2)" = PASS ] && [ "$(verdict_of "$JM16_1" AC-8)" = PASS ] && [ "$(verdict_of "$JM16_1" CIAC-2)" = PASS ] \
      && ok "V6837-AC4 M1 detected — without the multi-command path the false second command PASSes again, and so does the violated null" \
      || bad "V6837-AC4 M1 SURVIVED — AC-2 $(fv16 "$JM16_1" AC-2), AC-8 $(fv16 "$JM16_1" AC-8), CIAC-2 $(fv16 "$JM16_1" CIAC-2)"
  fi
fi
m16 "V6837-AC4 M2" g16-m2-whole-cell 1 's/cmp="\$\(limb_comparator "\$\{L_prose\[\$i\]\}"\)"/cmp="$(limb_comparator "$method")"/'
if [ "$MUT_TOOK" = 1 ]; then
  vrp_run "$MUT_PATH" "$FIX_LIMB"; JM16_2="$VRP_JSON"
  if mutant_ran "V6837-AC4 M2"; then
    [ "$(verdict_of "$JM16_2" AC-8)" = ERROR ] && g16_has "$JM16_2" AC-8 "comparator-ambiguous" \
      && ok "V6837-AC4 M2 detected — read from the whole cell, the designated command meets two comparators and AC-8 cannot be graded on its own null" \
      || bad "V6837-AC4 M2 SURVIVED — AC-8 $(fv16 "$JM16_2" AC-8) '$(observed_of "$JM16_2" AC-8)'"
  fi
fi
m16 "V7531-CIAC6 M3" g16-m3-further-runs-unisolated 3 \
  's/^      stdin\)$/      stdin) eval_free_run "$span" >\/dev\/null 2>\&1 || true/' \
  's/if reads_stdin_cmd "\$cmd" >\/dev\/null; then return 4; fi/if false; then return 4; fi/' \
  's/\} <\/dev\/null; done <<< "\$per_issue_records"/}; done <<< "$per_issue_records"/'
if [ "$MUT_TOOK" = 1 ]; then
  vrp_run "$MUT_PATH" "$FIX_LIMB"; JM16_3="$VRP_JSON"; RCM16_3="$VRP_RC"
  if mutant_ran "V7531-CIAC6 M3"; then
    [ "$(acs_of "$JM16_3")" -lt 14 ] && [ "$(strunc_of "$JM16_3")" -ge 1 ] && [ "$(ciacs_of "$JM16_3")" = "5" ] && [ "$RCM16_3" -eq 1 ] \
      && ok "V7531-CIAC6 M3 detected — a further command run outside the stdin-isolated dispatch drains the per-issue loop ($(acs_of "$JM16_3") of 14 rows; the CIAC loop, still isolated, keeps 5 of 5) and the tripwire exits 1" \
      || bad "V7531-CIAC6 M3 SURVIVED — AC=$(acs_of "$JM16_3") CIAC=$(ciacs_of "$JM16_3") stream-truncated=$(strunc_of "$JM16_3") rc=$RCM16_3"
  fi
fi
m16 "V6837-AC4 M4" g16-m4-bare-verb-is-a-command 1 's/ bare-verb\) continue ;; esac$/ bare-verb) printf "%s" "$span"; return ;; esac/'
if [ "$MUT_TOOK" = 1 ]; then
  vrp_run "$MUT_PATH" "$FIX_LIMB"; JM16_4="$VRP_JSON"
  if mutant_ran "V6837-AC4 M4"; then
    G16_M4="$(verdict_of "$JM16_4" AC-13)"
    [ -n "$G16_M4" ] && [ "$G16_M4" != PASS ] \
      && ok "V6837-AC4 M4 detected — with a bare verb taken as the command, AC-13 runs 'grep' with no argument and no longer PASSes ($G16_M4)" \
      || bad "V6837-AC4 M4 SURVIVED — AC-13 $(fv16 "$JM16_4" AC-13) '$(observed_of "$JM16_4" AC-13)'"
  fi
fi
m16 "V6837-AC4 M5" g16-m5-tool-catalog-seam 1 's/^span_invokes_tool\(\) \{$/span_invokes_tool() { case "$1" in "python3 "*) printf python3 ;; esac/'
if [ "$MUT_TOOK" = 1 ]; then
  vrp_run "$MUT_PATH" "$FIX_LIMB"; JM16_5="$VRP_JSON"
  if mutant_ran "V6837-AC4 M5"; then
    g16_partial "$JM16_5" AC-14 && g16_has "$JM16_5" AC-14 "limb 1 python3 did not run (outside the verb set); limb 2 grep PASS count=1 (== 1)" \
      && ok "V6837-AC4 M5 — once the tool predicate names a tool, the tool span is a command that did not run (outside the verb set) and the row reads the slot: the one seam a catalog replaces" \
      || bad "V6837-AC4 M5 — AC-14 under a named tool $(fv16 "$JM16_5" AC-14) '$(observed_of "$JM16_5" AC-14)'"
  fi
fi
rm -rf "$MUTD6837"

# ===========================================================================
# G17 — A METHOD THIS EXECUTOR CANNOT RUN IS REPORTED UNRUNNABLE, AND A SCOPE
#       ASSERTION RUNS NATIVELY (V6848-AC1, V6848-AC2, V6848-AC3, V6848-AC4).
#
# UNRUNNABLE is the fifth verdict, can't-run-here: the row was read, and a command
# it names cannot run in this executor. It is never PASS and it stays outside
# main()'s exit predicate, so a plan whose rows only decline still exits 0. A tool
# is named only from an invocation-shaped span (span_invokes_tool), so a label, a
# file name or a word the method merely mentions is never named, and a mention-only
# row never reads UNRUNNABLE. A method naming a runnable probe and a tool reads the
# can't-run slot and names both. A `git diff` scope assertion runs natively: its
# pathspecs are data, matched in-process against the release diff a test seam
# supplies, and every vacuous or mis-bound input reads UNRUNNABLE rather than PASS.
# RUNNABLE_VERBS is unchanged, proved armed-red-then-revert.
#
# The unrunnable fixture's awk rows carry a brace, which hides a record from the
# shared readers, so every record here is read from its own line (g17_family with
# G13's g13_verdict and g13_observed). Every arm first requires the record it grades
# to be present. Each seeded failure is proved to apply at exactly the sites it
# names, and only a mutation that took is graded.
# ===========================================================================
echo
echo "G17 — #6848: a method this executor cannot run is UNRUNNABLE, and a scope assertion runs natively (V6848-AC1/AC2/AC3/AC4)"
MUTD6848="$(mktemp -d -t verify-plan-6848-mut.XXXXXX)"
SEAMD6848="$(mktemp -d -t verify-plan-6848-seam.XXXXXX)"
FIX_SCOPE="release/tools/tests/fixtures/verify-plan-scope.md"
FIX_UNRUN="release/tools/tests/fixtures/verify-plan-unrunnable.md"
printf 'M\trelease/tools/verify-release-plan.sh\nM\trelease/tools/tests/test_verify_release_plan.sh\nM\trelease/references/pipeline/stage-04-planning.md\n' > "$SEAMD6848/mixed.tsv"
printf 'M\trelease/tools/verify-release-plan.sh\nM\trelease/tools/tests/test_verify_release_plan.sh\n' > "$SEAMD6848/clean.tsv"
: > "$SEAMD6848/empty.tsv"
# g17_seam <tool> <fixture> <seam> — vrp_run's contract (VRP_JSON + VRP_RC in the
# CURRENT shell), with the delivered set read from a test seam instead of git.
g17_seam() {
  set +e
  VRP_JSON="$("$1" --format=json --root "$REPO_ROOT" --fcm-diff-file "$3" "$REPO_ROOT/$2" 2>/dev/null)"
  VRP_RC=$?
  set -e
}
# g17_family <json> <id> — the family of one record, read from the record's own line.
g17_family() {
  local line v
  line="$(grep -F "\"id\":\"$2\"" <<<"$1" || true)"
  v="$(sed -n 's/.*"family":"\([a-z-]*\)".*/\1/p' <<<"$line")"
  printf '%s' "${v%%$'\n'*}"
}
# fv17 <json> <id> — "family/verdict"; reads "/" for an absent record, which no arm expects.
fv17() { printf '%s/%s' "$(g17_family "$1" "$2")" "$(g13_verdict "$1" "$2")"; }
# g17_has <json> <id> <text> — TRUE only when the record's observed text carries <text>.
g17_has() { case "$(g13_observed "$1" "$2")" in *"$3"*) return 0 ;; *) return 1 ;; esac; }
# g17_names <json> <id> <word>... — TRUE when the record's observed text carries any <word>.
g17_names() { local j="$1" i="$2" w; shift 2; for w in "$@"; do g17_has "$j" "$i" "$w" && return 0; done; return 1; }
# m17 <label> <stem> <sites> <sed-expr>... — publish the mutant in MUT_PATH, count the
# lines it changed (a substitution never adds or removes a line), and set MUT_TOOK
# only when it applied at exactly <sites> lines.
m17() {
  local label="$1" stem="$2" want="$3" dst n e
  shift 3
  dst="$MUTD6848/$stem.sh"
  cp "$VERIFY" "$dst"
  for e in "$@"; do sed -i.bak -E "$e" "$dst"; done
  rm -f "$dst.bak"
  chmod +x "$dst"
  MUT_PATH="$dst"
  n="$(awk 'NR == FNR { a[FNR] = $0; next } a[FNR] != $0 { n++ } END { print n + 0 }' "$VERIFY" "$dst")"
  if [ "$n" -eq "$want" ]; then
    MUT_TOOK=1; ok "$label — mutation applied at exactly $want site(s): the mutant differs from the shipped tool in $n line(s)"
  else
    MUT_TOOK=0; bad "$label — mutation applied at $n site(s), expected exactly $want; its arm is not graded"
  fi
}

g17_seam "$VERIFY" "$FIX_SCOPE" "$SEAMD6848/mixed.tsv"; J17M="$VRP_JSON"; RC17M="$VRP_RC"
vrp_run "$VERIFY" "$FIX_UNRUN"; J17U="$VRP_JSON"; RC17U="$VRP_RC"
E17U="$("$VERIFY" --format=json --root "$REPO_ROOT" "$REPO_ROOT/$FIX_UNRUN" 2>&1 >/dev/null || true)"

# --- G17-0: DENOMINATOR FIRST — both fixtures still declare their rows, and every one emits. ---
G17_SROWS="$(grep -c -F '| AC-' "$REPO_ROOT/$FIX_SCOPE" || true)"
G17_UROWS="$(grep -c -F '| AC-' "$REPO_ROOT/$FIX_UNRUN" || true)"
G17_UCIAC="$(grep -c -F '**CIAC-' "$REPO_ROOT/$FIX_UNRUN" || true)"
[ "${G17_SROWS:-0}" -eq 13 ] && [ "${G17_UROWS:-0}" -eq 10 ] && [ "${G17_UCIAC:-0}" -eq 4 ] \
   && [ "$(acs_of "$J17M")" = "13" ] && [ "$(acs_of "$J17U")" = "10" ] && [ "$(ciacs_of "$J17U")" = "4" ] \
  && ok "G17-0 SENSITIVITY — the scope fixture declares and emits 13 rows, and the unrunnable fixture 10 rows and 4 CIACs (the arms below grade real records)" \
  || bad "G17-0 declared scope=${G17_SROWS:-0} unrunnable=${G17_UROWS:-0}+${G17_UCIAC:-0}, emitted $(acs_of "$J17M") and $(acs_of "$J17U")+$(ciacs_of "$J17U") (expected 13 and 10+4)"

# --- V6848-AC1: a scope assertion dispatches to its own family and executes; a failing one FAILs. ---
G17_A=1
for g17a in AC-1 AC-2 AC-5; do
  { [ "$(fv17 "$J17M" "$g17a")" = scope/PASS ] && [ "$(g13_observed "$J17M" "$g17a")" = "scope count=0 (== 0) over 3 changed path(s) in the release diff" ]; } || G17_A=0
done
[ "$G17_A" = 1 ] \
  && ok "V6848-AC1 a — a scope assertion dispatches to the scope family and executes: AC-1, AC-2 (an exclusion) and AC-5 (a glob) read count=0 (== 0) over the 3 changed paths" \
  || bad "V6848-AC1 a — AC-1 $(fv17 "$J17M" AC-1) '$(g13_observed "$J17M" AC-1)'; AC-2 $(fv17 "$J17M" AC-2); AC-5 $(fv17 "$J17M" AC-5)"
[ "$(fv17 "$J17M" AC-3)" = scope/PASS ] && g17_has "$J17M" AC-3 "scope count=2 (== 2) over 3 changed path(s)" \
  && ok "V6848-AC1 b CONTROL — the same instrument reaches the changed paths: AC-3 reads count=2 (== 2)" \
  || bad "V6848-AC1 b — AC-3 $(fv17 "$J17M" AC-3) '$(g13_observed "$J17M" AC-3)'"
[ "$(fv17 "$J17M" AC-4)" = scope/FAIL ] && g17_has "$J17M" AC-4 "scope count=1 (wanted == 0)" \
   && g17_has "$J17M" AC-4 "release/references/pipeline/stage-04-planning.md" && [ "$RC17M" -eq 3 ] \
  && ok "V6848-AC1 c CONTROL — a violated scope assertion FAILs, naming the path that broke it, and the plan exits 3: the family is not inert" \
  || bad "V6848-AC1 c — AC-4 $(fv17 "$J17M" AC-4) '$(g13_observed "$J17M" AC-4)', rc $RC17M"
G17_D=1
for g17a in AC-6 AC-7 AC-8; do
  { [ "$(g13_verdict "$J17M" "$g17a")" = UNRUNNABLE ] && g17_has "$J17M" "$g17a" "tool-invocation-outside-executor-allowlist:git "; } || G17_D=0
done
[ "$G17_D" = 1 ] \
  && ok "V6848-AC1 d — a pipeline, a pinned range and a comparator-less git diff are outside the grammar: each reads UNRUNNABLE naming git, never PASS" \
  || bad "V6848-AC1 d — AC-6 $(fv17 "$J17M" AC-6), AC-7 $(fv17 "$J17M" AC-7), AC-8 $(fv17 "$J17M" AC-8)"
g17_seam "$VERIFY" "$FIX_SCOPE" "$SEAMD6848/empty.tsv"; J17E="$VRP_JSON"
G17_E=1
for g17a in AC-1 AC-2 AC-3 AC-4 AC-5; do
  { [ "$(fv17 "$J17E" "$g17a")" = scope/UNRUNNABLE ] && g17_has "$J17E" "$g17a" "scope-diff-empty"; } || G17_E=0
done
[ "$G17_E" = 1 ] && [ "$(grep -c '"family":"scope".*"verdict":"PASS"' <<<"$J17E" || true)" = "0" ] \
  && ok "V6848-AC1 e — an empty release diff is vacuous, never a pass: AC-1..AC-5 read UNRUNNABLE scope-diff-empty, and no scope row PASSes" \
  || bad "V6848-AC1 e — AC-1 $(fv17 "$J17E" AC-1) '$(g13_observed "$J17E" AC-1)'; scope PASS records: $(grep -c '"family":"scope".*"verdict":"PASS"' <<<"$J17E" || true)"
mkdir -p "$SEAMD6848/live/release/releases/plans"
cp "$REPO_ROOT/$FIX_SCOPE" "$SEAMD6848/live/release/releases/plans/p.md"
set +e
J17L="$("$VERIFY" --format=json --root "$REPO_ROOT" --fcm-diff-file "$SEAMD6848/mixed.tsv" "$SEAMD6848/live/release/releases/plans/p.md" 2>/dev/null)"
set -e
[ "$(fv17 "$J17L" AC-1)" = scope/ERROR ] && g17_has "$J17L" AC-1 "scope-fixture-mode-on-live-plan" \
  && ok "V6848-AC1 f — the test seam is refused against a plan under release/releases/plans/: a real release is never graded on an authored diff (ERROR)" \
  || bad "V6848-AC1 f — AC-1 on a live-plan path with the seam: $(fv17 "$J17L" AC-1) '$(g13_observed "$J17L" AC-1)'"

# --- V6848-AC1 g: NON-SYNTHETIC — a real commit's diff, through the same fixed git call. ---
# 6fea3536 changed 4 paths: the executor, the suite and two new fixtures. The arm reads
# the delivered set git reports for that one commit, so it grades the family's git path
# rather than the seam. An unreachable commit (a shallow clone, or a tree that is not a
# repository) degrades to a stated skip plus the honest reading, never a false pass.
cat > "$SEAMD6848/real.md" <<'EOF'
# vTEST Release Plan — a scope assertion over a real commit's diff (G17)

## Verification Plan

**#983 — the scope family on a real diff**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | `git diff --name-only origin/main...HEAD -- release/tools/verify-release-plan.sh` expect 1 | PASS: the commit changed the executor |
| AC-2 | `git diff --name-only origin/main...HEAD -- release/tools/tests/` expect 0 | FAIL: the commit changed 3 paths under tests/ |
EOF
set +e
J17G="$("$VERIFY" --format=json --root "$REPO_ROOT" --merge-base '6fea3536^' --head 6fea3536 "$SEAMD6848/real.md" 2>/dev/null)"
set -e
if git -C "$REPO_ROOT" cat-file -e '6fea3536^{commit}' 2>/dev/null; then
  [ "$(fv17 "$J17G" AC-1)" = scope/PASS ] && g17_has "$J17G" AC-1 "scope count=1 (== 1) over 4 changed path(s)" \
     && [ "$(fv17 "$J17G" AC-2)" = scope/FAIL ] && g17_has "$J17G" AC-2 "scope count=3 (wanted == 0) over 4 changed path(s)" \
    && ok "V6848-AC1 g NON-SYNTHETIC — over a real commit's diff the family reads count=1 (== 1) and FAILs count=3 (wanted == 0), through the fixed git call" \
    || bad "V6848-AC1 g — AC-1 $(fv17 "$J17G" AC-1) '$(g13_observed "$J17G" AC-1)'; AC-2 $(fv17 "$J17G" AC-2) '$(g13_observed "$J17G" AC-2)'"
else
  [ "$(fv17 "$J17G" AC-1)" = scope/UNRUNNABLE ] && g17_has "$J17G" AC-1 "scope-diff-unresolvable" \
     && [ "$(fv17 "$J17G" AC-2)" = scope/UNRUNNABLE ] \
    && ok "V6848-AC1 g SKIP — historical-commit-unreachable (a shallow clone, or not a repository): both rows read UNRUNNABLE scope-diff-unresolvable, degraded honestly, not passed" \
    || bad "V6848-AC1 g — the commit is unreachable, yet AC-1 $(fv17 "$J17G" AC-1) '$(g13_observed "$J17G" AC-1)'; AC-2 $(fv17 "$J17G" AC-2)"
fi

# --- V6848-AC1 h: the three guards, each on its own row (D23); the third is scoped to == and <=. ---
[ "$(fv17 "$J17M" AC-9)" = scope/UNRUNNABLE ] && g17_has "$J17M" AC-9 "scope-comparator-ambiguous" \
  && ok "V6848-AC1 h1 — two comparators that disagree grade the assertion on neither: UNRUNNABLE scope-comparator-ambiguous" \
  || bad "V6848-AC1 h1 — AC-9 $(fv17 "$J17M" AC-9) '$(g13_observed "$J17M" AC-9)'"
[ "$(fv17 "$J17M" AC-10)" = scope/UNRUNNABLE ] && g17_has "$J17M" AC-10 "scope-pathspec-placeholder:<skill-dir>" \
  && ok "V6848-AC1 h2 — a placeholder pathspec names no path: UNRUNNABLE scope-pathspec-placeholder" \
  || bad "V6848-AC1 h2 — AC-10 $(fv17 "$J17M" AC-10) '$(g13_observed "$J17M" AC-10)'"
[ "$(fv17 "$J17M" AC-11)" = scope/UNRUNNABLE ] && g17_has "$J17M" AC-11 "scope-pathspec-selects-nothing:core/skils/" \
  && ok "V6848-AC1 h3 — an expect-0 pathspec that selects no existing and no delivered path is vacuous: UNRUNNABLE scope-pathspec-selects-nothing" \
  || bad "V6848-AC1 h3 — AC-11 $(fv17 "$J17M" AC-11) '$(g13_observed "$J17M" AC-11)'"
[ "$(fv17 "$J17M" AC-12)" = scope/PASS ] && g17_has "$J17M" AC-12 "scope count=0 (>= 0)" \
  && ok "V6848-AC1 h4 CONTROL — the selects-nothing guard reads only an == or <= assertion: the same pathspec under at least 0 is graded" \
  || bad "V6848-AC1 h4 — AC-12 $(fv17 "$J17M" AC-12) '$(g13_observed "$J17M" AC-12)'"
# --- V6848-AC1 i: the partition's partial rule reaches the scope family too (D37). ---
[ -n "$PARTIAL_SLOT" ] && [ "$(g13_verdict "$J17M" AC-13)" = "$PARTIAL_SLOT" ] && [ "$PARTIAL_SLOT" != PASS ] \
   && g17_has "$J17M" AC-13 "limb 1 git PASS scope count=0 (== 0)" && g17_has "$J17M" AC-13 "limb 2 python3 did not run (outside the verb set)" \
  && ok "V6848-AC1 i — a scope assertion beside a command that did not run reads the can't-run slot ($PARTIAL_SLOT), naming the command that ran and the one that did not" \
  || bad "V6848-AC1 i — AC-13 $(fv17 "$J17M" AC-13) '$(g13_observed "$J17M" AC-13)'"

# --- V6848-AC2: a method this executor cannot run is UNRUNNABLE, naming a tool it invokes. ---
[ "$(fv17 "$J17U" AC-1)" = unrunnable/UNRUNNABLE ] && g17_has "$J17U" AC-1 "tool-invocation-outside-executor-allowlist:awk " \
  && ok "V6848-AC2 a — an awk method with no family keyword reaches the residual step and reads UNRUNNABLE naming awk, never PASS" \
  || bad "V6848-AC2 a — AC-1 $(fv17 "$J17U" AC-1) '$(g13_observed "$J17U" AC-1)'"
{ [ "$(fv17 "$J17U" AC-2)" = per-issue/UNRUNNABLE ] && g17_has "$J17U" AC-2 "allowlist:awk " \
  && [ "$(g13_verdict "$J17U" AC-3)" = UNRUNNABLE ] && g17_has "$J17U" AC-3 "allowlist:python3 " \
  && [ "$(fv17 "$J17U" CIAC-1)" = integration/UNRUNNABLE ] && g17_has "$J17U" CIAC-1 "allowlist:python3 " \
  && [ "$(fv17 "$J17U" AC-5)" = per-issue/UNRUNNABLE ] && g17_has "$J17U" AC-5 "allowlist:bash "; } \
  && ok "V6848-AC2 b — every route declines at the one decline point: awk with a keyword, an interpreter, the cross-issue handler, and the tool after an identifier (bash, not G-CL)" \
  || bad "V6848-AC2 b — AC-2 $(fv17 "$J17U" AC-2); AC-3 $(fv17 "$J17U" AC-3) '$(g13_observed "$J17U" AC-3)'; CIAC-1 $(fv17 "$J17U" CIAC-1); AC-5 $(fv17 "$J17U" AC-5) '$(g13_observed "$J17U" AC-5)'"
[ "$(fv17 "$J17U" AC-4)" = per-issue/SKIP ] && [ "$(g13_observed "$J17U" AC-4)" = "no-executable-command-in-method" ] \
   && ! g17_names "$J17U" AC-4 PARSE-07 PARSE-12a PARSE-14a PMO_SCOPE_GUARD_ROOT G-CL _pmo status \
  && ok "V6848-AC2 c — identifiers are never named as a tool: a method made only of labels is a method with no command" \
  || bad "V6848-AC2 c — AC-4 $(fv17 "$J17U" AC-4) '$(g13_observed "$J17U" AC-4)'"
[ "$(fv17 "$J17U" CIAC-2)" = integration/SKIP ] && [ "$(g13_observed "$J17U" CIAC-2)" = "documented-decision-method (no runnable command)" ] \
  && ok "V6848-AC2 d — prose around an identifier is never run as a bare command: CIAC-2 is a documented decision, not executed" \
  || bad "V6848-AC2 d — CIAC-2 $(fv17 "$J17U" CIAC-2) '$(g13_observed "$J17U" CIAC-2)'"
[ "$(fv17 "$J17U" AC-6)" = per-issue/PASS ] && [ "$(fv17 "$J17U" CIAC-3)" = integration/PASS ] \
  && ok "V6848-AC2 e CONTROL — a runnable probe still executes in both loops (AC-6, CIAC-3)" \
  || bad "V6848-AC2 e — AC-6 $(fv17 "$J17U" AC-6), CIAC-3 $(fv17 "$J17U" CIAC-3)"
# f — THE COMMAND-SHAPE TEST, unit by unit: a tool is named only from an invocation-shaped span.
G17_F=1
t_sit17() { [ "$(span_invokes_tool "$1" "${3:-}" 2>/dev/null || true)" = "$2" ] || { G17_F=0; printf '       span_invokes_tool mismatch: [%s] -> [%s], wanted [%s]\n' "$1" "$(span_invokes_tool "$1" "${3:-}" 2>/dev/null || true)" "$2"; }; }
for g17s in PARSE-07 PARSE-12a PARSE-14a PMO_SCOPE_GUARD_ROOT G-CL _pmo status PORTFOLIO.md 539c4440 resolve_check_mode main warn '../x.sh' case source set 'core/hooks/block-destructive.sh' 'grep -c x f'; do
  t_sit17 "$g17s" ''
done
t_sit17 "awk 'END{print NR}' core/CLAUDE.md.template" awk
t_sit17 'python3' python3
t_sit17 'python3 release/tools/check-adr-numbers.py' python3
t_sit17 'release/tools/automated-closeout.sh --self-test' automated-closeout.sh
t_sit17 './qa.sh --quick' qa.sh
t_sit17 'set -u' set
t_sit17 'case' '' whole
t_sit17 'release/tools/x.sh' x.sh whole
[ "$G17_F" = 1 ] \
  && ok "V6848-AC2 f — the command-shape test: 19 identifiers and mentions name nothing (labels, a file name, a hash, a keyword or builtin with no argument, a script path mentioned in prose, an allowlisted command); 7 invocation-shaped spans name their tool" \
  || bad "V6848-AC2 f — span_invokes_tool departs from a pinned case (above)"
# g — the roll-up counts UNRUNNABLE in both presenters, and the five counters sum to the records.
G17_MD="$("$VERIFY" --format=md --root "$REPO_ROOT" "$REPO_ROOT/$FIX_UNRUN" 2>/dev/null || true)"
G17_RP="$(sed -n 's/.*"rollup": {"pass": \([0-9]*\), "fail": \([0-9]*\), "skip": \([0-9]*\), "unrunnable": \([0-9]*\), "error": \([0-9]*\).*/\1 \2 \3 \4 \5/p' <<<"$J17U")"
G17_U="$(count_verdict "$J17U" UNRUNNABLE)"
G17_SUM="$(awk '{ print $1 + $2 + $3 + $4 + $5 }' <<<"${G17_RP:-x}")"
[ "$G17_U" = "8" ] && [ "$(awk '{ print $4 }' <<<"${G17_RP:-x}")" = "8" ] && [ "$G17_SUM" = "$(g13_records "$J17U")" ] \
   && [ "$(grep -c -F '/ 8 UNRUNNABLE /' <<<"$G17_MD" || true)" = "1" ] \
  && ok "V6848-AC2 g — UNRUNNABLE has its own counter: 8 records, 'unrunnable': 8 in JSON, '8 UNRUNNABLE' in the markdown roll-up, and the five counters sum to the $G17_SUM records emitted" \
  || bad "V6848-AC2 g — UNRUNNABLE records=$G17_U, JSON rollup [${G17_RP:-absent}] (sum $G17_SUM of $(g13_records "$J17U") records), md line: $(grep -F 'Verdict roll-up' <<<"$G17_MD" || true)"
[ "$RC17U" -eq 0 ] && grep -q -F 'UNRUNNABLE' <<<"$E17U" \
  && ok "V6848-AC2 h — UNRUNNABLE does not fail the run (exit 0) and is noted on stderr, so a clean exit is not read as every check having run" \
  || bad "V6848-AC2 h — rc $RC17U; stderr '${E17U:-<empty>}'"
{ [ -n "$(g13_verdict "$J17U" AC-7)" ] && [ "$(g13_verdict "$J17U" AC-7)" != UNRUNNABLE ] && ! g17_names "$J17U" AC-7 case source \
  && [ -n "$(g13_verdict "$J17U" AC-8)" ] && [ "$(g13_verdict "$J17U" AC-8)" != UNRUNNABLE ] && ! g17_names "$J17U" AC-8 block-destructive; } \
  && ok "V6848-AC2 i SPECIFICITY — a mention-only span never grades UNRUNNABLE: a keyword or field name with no argument, and a script path mentioned in prose, are not commands" \
  || bad "V6848-AC2 i — AC-7 $(fv17 "$J17U" AC-7) '$(g13_observed "$J17U" AC-7)'; AC-8 $(fv17 "$J17U" AC-8) '$(g13_observed "$J17U" AC-8)'"
# j — the RESIDUAL step keys on the same test: a mention-only row with no keyword is not
# UNRUNNABLE; a tool row with no keyword is (its control).
cat > "$SEAMD6848/resid.md" <<'EOF'
# vTEST Release Plan — the residual step keys on the command-shape test (G17)

## Verification Plan

**#984 — rows no keyword arm claims**

| AC | Verification method | Expected result |
|---|---|---|
| AC-1 | the hand-maintained `case` arms and the `core/hooks/block-destructive.sh` control stay in place | mentions only: not a command |
| AC-2 | `awk 'END{print NR}' core/CLAUDE.md.template` expect 4 | control: a tool the residual step names |
EOF
set +e
J17R="$("$VERIFY" --format=json --root "$REPO_ROOT" "$SEAMD6848/resid.md" 2>/dev/null)"
set -e
{ [ -n "$(g13_verdict "$J17R" AC-1)" ] && [ "$(g13_verdict "$J17R" AC-1)" != UNRUNNABLE ] && [ "$(g17_family "$J17R" AC-1)" != unrunnable ] \
  && [ "$(fv17 "$J17R" AC-2)" = unrunnable/UNRUNNABLE ]; } \
  && ok "V6848-AC2 j SPECIFICITY — the residual step keys on the command-shape test: a mention-only row no keyword claims is not UNRUNNABLE ($(fv17 "$J17R" AC-1)), and a tool row is (AC-2)" \
  || bad "V6848-AC2 j — AC-1 $(fv17 "$J17R" AC-1) '$(g13_observed "$J17R" AC-1)'; AC-2 $(fv17 "$J17R" AC-2)"
# k — INT-4: a runnable probe beside a tool, in either order and in either loop, reads the
# can't-run slot and names both commands; it is never PASS.
{ [ -n "$PARTIAL_SLOT" ] && [ "$PARTIAL_SLOT" != PASS ] \
  && [ "$(g13_verdict "$J17U" AC-9)" = "$PARTIAL_SLOT" ] && g17_has "$J17U" AC-9 "limb 1 grep PASS count=" && g17_has "$J17U" AC-9 "limb 2 awk did not run (outside the verb set)" \
  && [ "$(g13_verdict "$J17U" AC-10)" = "$PARTIAL_SLOT" ] && g17_has "$J17U" AC-10 "limb 1 awk did not run (outside the verb set); limb 2 grep PASS count=" \
  && [ "$(g13_verdict "$J17U" CIAC-4)" = "$PARTIAL_SLOT" ] && g17_has "$J17U" CIAC-4 "limb 2 awk did not run (outside the verb set)"; } \
  && ok "V6848-AC2 k — INT-4: a grep and an awk in one method read the can't-run slot ($PARTIAL_SLOT) in both orders and both loops, naming both commands; never PASS" \
  || bad "V6848-AC2 k — AC-9 $(fv17 "$J17U" AC-9) '$(g13_observed "$J17U" AC-9)'; AC-10 $(fv17 "$J17U" AC-10); CIAC-4 $(fv17 "$J17U" CIAC-4)"

# --- V6848-AC3: RUNNABLE_VERBS is unchanged — the plan row's literal, proved armed-red-then-revert. ---
G17_LIT="RUNNABLE_VERBS='grep test ls head wc cat'"
G17_L0="$(grep -c -F "$G17_LIT" "$VERIFY" || true)"
m17 "V6848-AC3 armed red" g17-ac3-verb-set-widened 1 "s/^RUNNABLE_VERBS='grep test ls head wc cat'\$/RUNNABLE_VERBS='grep test ls head wc cat awk git'/"
G17_L1="$(grep -c -F "$G17_LIT" "$MUT_PATH" || true)"
[ "$G17_L0" = "1" ] && [ "$MUT_TOOK" = 1 ] && [ "$G17_L1" = "0" ] \
  && ok "V6848-AC3 — RUNNABLE_VERBS is unchanged: the plan row's literal counts 1 in the shipped tool and 0 in a copy whose verb set is widened (armed red; the shipped tool is untouched)" \
  || bad "V6848-AC3 — the literal counts $G17_L0 in the shipped tool and ${G17_L1:-?} in the widened copy (expected 1 and 0)"

# --- V6848-AC4: a plan whose rows assert scope reaches a clean exit. ---
g17_seam "$VERIFY" "$FIX_SCOPE" "$SEAMD6848/clean.tsv"; J17C="$VRP_JSON"; RC17C="$VRP_RC"
G17_C=1
for g17a in AC-1 AC-2 AC-3 AC-4 AC-5; do [ "$(fv17 "$J17C" "$g17a")" = scope/PASS ] || G17_C=0; done
[ "$G17_C" = 1 ] && [ "$RC17C" -eq 0 ] && [ "$RC17M" -eq 3 ] \
  && ok "V6848-AC4 — on a release diff that honours every scope row the plan exits 0 (AC-1..AC-5 PASS); control: the mixed diff exits 3" \
  || bad "V6848-AC4 — clean rc $RC17C (AC-4 $(fv17 "$J17C" AC-4)); mixed rc $RC17M (expected 0 and 3)"

# --- SEEDED FAILURES. Each removes one observing step and names the answer it must move to. ---
m17 "V6848-AC2 M1" g17-m1-no-residual-step 1 's/^  if \[ -n "\$lead" \] && ! is_runnable_verb "\$lead"; then echo "unrunnable"; return; fi$/  :/'
if [ "$MUT_TOOK" = 1 ]; then
  vrp_run "$MUT_PATH" "$FIX_UNRUN"; JM17_1="$VRP_JSON"
  if mutant_ran "V6848-AC2 M1"; then
    [ "$(fv17 "$JM17_1" AC-1)" = unclassified/ERROR ] \
      && ok "V6848-AC2 M1 detected — without the residual step an awk method with no keyword is unclassifiable again (ERROR)" \
      || bad "V6848-AC2 M1 SURVIVED — AC-1 $(fv17 "$JM17_1" AC-1)"
  fi
fi
m17 "V6848-AC2 M2" g17-m2-decline-skips 1 's/"\$VERDICT_UNRUNNABLE" "tool-invocation-outside-executor-allowlist:\$tool/"$VERDICT_SKIP" "tool-invocation-outside-executor-allowlist:$tool/'
if [ "$MUT_TOOK" = 1 ]; then
  vrp_run "$MUT_PATH" "$FIX_UNRUN"; JM17_2="$VRP_JSON"
  if mutant_ran "V6848-AC2 M2"; then
    [ "$(g13_verdict "$JM17_2" AC-1)" = SKIP ] && [ "$(g13_verdict "$JM17_2" CIAC-1)" = SKIP ] \
      && ok "V6848-AC2 M2 detected — a decline that reads SKIP is indistinguishable from a declared deferral again (AC-1, CIAC-1)" \
      || bad "V6848-AC2 M2 SURVIVED — AC-1 $(fv17 "$JM17_2" AC-1), CIAC-1 $(fv17 "$JM17_2" CIAC-1)"
  fi
fi
m17 "V6848-AC2 M3" g17-m3-no-identifier-guard 1 's/^  if \[ "\$identifier" -eq 1 \]; then return; fi$/  :/'
if [ "$MUT_TOOK" = 1 ]; then
  vrp_run "$MUT_PATH" "$FIX_UNRUN"; JM17_3="$VRP_JSON"
  if mutant_ran "V6848-AC2 M3"; then
    [ "$(fv17 "$JM17_3" CIAC-2)" = integration/ERROR ] && g17_has "$JM17_3" CIAC-2 "matcher-exit-3" \
      && ok "V6848-AC2 M3 detected — without the identifier guard the prose that opens with 'grep' runs as a bare command and reads ERROR" \
      || bad "V6848-AC2 M3 SURVIVED — CIAC-2 $(fv17 "$JM17_3" CIAC-2) '$(g13_observed "$JM17_3" CIAC-2)'"
  fi
fi
m17 "V6848-AC1 M5" g17-m5-no-exclusion 1 's/^      -\*\) if scope_pattern_matches "\$path" "\$\{s#-\}"; then return 1; fi ;;$/      -*) : ;;/'
if [ "$MUT_TOOK" = 1 ]; then
  g17_seam "$MUT_PATH" "$FIX_SCOPE" "$SEAMD6848/mixed.tsv"; JM17_5="$VRP_JSON"
  if mutant_ran "V6848-AC1 M5"; then
    [ "$(fv17 "$JM17_5" AC-2)" = scope/FAIL ] && g17_has "$JM17_5" AC-2 "scope count=3 (wanted == 0)" \
      && ok "V6848-AC1 M5 detected — with the exclusion a no-op, AC-2 counts every path and FAILs: the exclusion is observed" \
      || bad "V6848-AC1 M5 SURVIVED — AC-2 $(fv17 "$JM17_5" AC-2) '$(g13_observed "$JM17_5" AC-2)'"
  fi
fi
m17 "V6848-AC1 M6" g17-m6-empty-diff-passes 1 's/"\$VERDICT_UNRUNNABLE" "scope-diff-empty/"$VERDICT_PASS" "scope-diff-empty/'
if [ "$MUT_TOOK" = 1 ]; then
  g17_seam "$MUT_PATH" "$FIX_SCOPE" "$SEAMD6848/empty.tsv"; JM17_6="$VRP_JSON"
  if mutant_ran "V6848-AC1 M6"; then
    [ "$(fv17 "$JM17_6" AC-1)" = scope/PASS ] \
      && ok "V6848-AC1 M6 detected — an empty diff that reads PASS is caught: arm e sees a scope PASS on nothing" \
      || bad "V6848-AC1 M6 SURVIVED — AC-1 $(fv17 "$JM17_6" AC-1)"
  fi
fi
m17 "V6848-AC1 M7" g17-m7-whole-cell-comparator 1 's/^  cmpr="\$\(limb_comparator "\$method"\)"$/  cmpr="$(extract_threshold "$method")"/'
if [ "$MUT_TOOK" = 1 ]; then
  g17_seam "$MUT_PATH" "$FIX_SCOPE" "$SEAMD6848/mixed.tsv"; JM17_7="$VRP_JSON"
  if mutant_ran "V6848-AC1 M7"; then
    [ "$(fv17 "$JM17_7" AC-9)" = scope/PASS ] && g17_has "$JM17_7" AC-9 "scope count=1 (>= 1)" \
      && ok "V6848-AC1 M7 detected — read through the whole-cell priority reader, a comparator written for something else grades the violated null PASS: the ambiguity guard is what stops it" \
      || bad "V6848-AC1 M7 SURVIVED — AC-9 $(fv17 "$JM17_7" AC-9) '$(g13_observed "$JM17_7" AC-9)'"
  fi
fi
m17 "V6848-AC1 M8" g17-m8-placeholder-as-path 2 \
  's/out="\$\{out\}\?\$\{p\}"/out="${out}+${p}"/' \
  's/if ! scope_pathspec_selects "\$\{s#\+\}" "\$paths"; then/if false; then/'
if [ "$MUT_TOOK" = 1 ]; then
  g17_seam "$MUT_PATH" "$FIX_SCOPE" "$SEAMD6848/mixed.tsv"; JM17_8="$VRP_JSON"
  if mutant_ran "V6848-AC1 M8"; then
    [ "$(fv17 "$JM17_8" AC-10)" = scope/PASS ] && g17_has "$JM17_8" AC-10 "scope count=0 (== 0)" \
      && ok "V6848-AC1 M8 detected — a placeholder read as a literal path matches nothing and its expect 0 PASSes: the placeholder refusal is observed" \
      || bad "V6848-AC1 M8 SURVIVED — AC-10 $(fv17 "$JM17_8" AC-10) '$(g13_observed "$JM17_8" AC-10)'"
  fi
fi
m17 "V6848-AC1 M9" g17-m9-no-selects-nothing-guard 1 's/if ! scope_pathspec_selects "\$\{s#\+\}" "\$paths"; then/if false; then/'
if [ "$MUT_TOOK" = 1 ]; then
  g17_seam "$MUT_PATH" "$FIX_SCOPE" "$SEAMD6848/mixed.tsv"; JM17_9="$VRP_JSON"
  if mutant_ran "V6848-AC1 M9"; then
    [ "$(fv17 "$JM17_9" AC-11)" = scope/PASS ] && g17_has "$JM17_9" AC-11 "scope count=0 (== 0)" \
      && ok "V6848-AC1 M9 detected — without the selects-nothing guard a typo'd pathspec makes 'nothing changed there' PASS" \
      || bad "V6848-AC1 M9 SURVIVED — AC-11 $(fv17 "$JM17_9" AC-11) '$(g13_observed "$JM17_9" AC-11)'"
  fi
fi
rm -rf "$MUTD6848" "$SEAMD6848"

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

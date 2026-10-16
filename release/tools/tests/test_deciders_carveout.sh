#!/usr/bin/env bash
# test_deciders_carveout.sh — two-gate agreement suite for the ADR `deciders:` carve-out.
#
# WHAT IT ASSERTS. The depersonalization gate and the ADR durability lint both scan an
# ADR `deciders:` line. Under the ratified name-only reading they must return the SAME
# verdict on their shared subject — the operator's GitHub handle — and they must both
# still PASS a line carrying only the literal name. That second arm is what stops the
# reconciliation from being "resolved" the lazy way, by making both gates strict.
#
# WHY IT EXISTS AS A COMMITTED SUITE. The depersonalization gate's decision used to be
# inline in .github/workflows/repo-integrity.yml, reachable only by a remote CI
# trigger. A probe like that can only be exercised locally by re-implementing it, and a
# re-implementation passes while the real gate diverges. So the decision was extracted
# into release/tools/lib/deciders-carveout.sh, which the workflow and this suite BOTH
# source: the extraction is part of the work, not an exemption from it
# (review-discipline-principles.md § 8, PV-2d). This suite asserts that binding
# structurally, so the workflow cannot quietly grow a private copy again.
#
# AGREEMENT SCOPE, stated precisely because the claim is falsifiable otherwise. The two
# gates are NOT co-extensive scanners: the durability lint's subject is the operator
# handle; the depersonalization gate also scans the name, the email and the collaborator
# dimensions. Their differing verdicts on those other dimensions are correct, not
# disagreement. Agreement is asserted on the shared subject only. Both gates resolve the
# handle from the SAME source, the repository owner, on every run — whoever triggered
# it — so the agreement holds on a run a bot started as well as on a human's. (The
# depersonalization gate used to resolve it from the run's actor and skip its operator
# dimension when the actor was a bot; decision record
# {{ADR:depersonalization-gate-scans-bot-runs}} retired that.) This suite drives a
# synthetic handle directly, and the run-level arms below assert the resolution itself.
#
# EVERY LITERAL HERE IS SYNTHETIC. Nothing is resolved from a secret or from the run's
# actor. See fixtures/deciders-carveout/README.md.
#
# Hermetic: mktemp only, no network, no gh, no git remote, and no write to the checkout.
# Bash 3.2 compatible (the CI runner for this suite's job is macOS) — no associative
# arrays, no mapfile, no ${var,,}.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
FIXDIR="$HERE/fixtures/deciders-carveout"
LIB="$ROOT/release/tools/lib/deciders-carveout.sh"
LINT="$ROOT/release/tools/check-adr-durability.py"
WORKFLOW="$ROOT/.github/workflows/repo-integrity.yml"

# --- Synthetic literals (never real identifiers) -----------------------------------
FIXTURE_HANDLE="octo-fixture"          # same synthetic handle check-adr-durability.py uses
FIXTURE_NAME="Ada Lovelace"
FIXTURE_EMAIL="ada@fixture.invalid"    # RFC 2606 reserved TLD — can never route
FIXTURE_COLLAB="Grace Hopper"
OVERRIDE_RE='<!--[[:space:]]*repo-integrity:[[:space:]]*allow-depersonalization[[:space:]]*-->'

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; }
check() { if [ "$2" = "$3" ]; then ok "$1 (= $3)"; else bad "$1 — expected [$3], observed [$2]"; fi; }

[ -f "$LIB" ]   || { echo "FATAL: shared library not found at $LIB"; exit 1; }
[ -f "$LINT" ]  || { echo "FATAL: durability lint not found at $LINT"; exit 1; }
[ -d "$FIXDIR" ]|| { echo "FATAL: fixture directory not found at $FIXDIR"; exit 1; }

# Source the SAME library the workflow sources. If this file ever stops defining the
# functions the gate calls, the suite dies here rather than passing vacuously.
#
# `declare -F`, NOT the `type "$fn" | head -1 | grep -q 'function'` this replaces.
# That idiom is a writer piped into short-circuiting readers, in PREDICATE position:
# `head -1` and `grep -q` each stop at their first line, so the writer can still be
# writing when the pipe closes — and under the `set -uo pipefail` at the top of this
# file the writer's broken-pipe status becomes the PIPELINE's status. A SUCCESSFUL
# match therefore reports failure, `!` inverts it, and the guard announces a missing
# function that is demonstrably defined. Measured: forcing the writer past the pipe
# buffer gives PIPESTATUS=[141 0 0] — grep matched, the pipeline still reported 141.
# Where SIGPIPE is inherited as SIG_IGN, which is what a hosted-runner step gets, the
# writer returns 1 instead of 141, which is why this class is diagnosed by a non-zero
# status on a short-circuiting pipeline and never by hunting for 141.
#
# `declare -F` has no pipe, so there is no upstream status to promote over it. It is
# also STRICTER than the grep it replaces: true only for a function, false for a
# builtin, an alias, or a PATH file whose name merely contains the word "function".
# Do not "simplify" this back into a pipeline.
# shellcheck source=/dev/null
. "$LIB"
for fn in esc_lines identity_preflight handle_preflight resolve_operator_literals literal_set_verdict \
          adr_deciders_carveout_suppresses depersonalization_line_verdict; do
  if ! declare -F "$fn" >/dev/null; then
    echo "FATAL: $LIB did not define $fn"; exit 1
  fi
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- Pattern sets, built through the gate's OWN esc_lines --------------------------
# PATTERN_FILE mirrors the gate's operator+collaborator literal set; NOT_CARVED holds
# the literals the carve-out does not cover, which under the ratified reading is the
# handle. Building both through the library's helper is what makes this suite's inputs
# identical in escaping to the gate's.
PATTERN_FILE="$TMP/patterns"
NOT_CARVED="$TMP/not_carved"
EMPTY_NOT_CARVED="$TMP/not_carved_empty"
: > "$PATTERN_FILE"; : > "$NOT_CARVED"; : > "$EMPTY_NOT_CARVED"
esc_lines "$(printf '%s\n%s\n%s\n' "$FIXTURE_HANDLE" "$FIXTURE_NAME" "$FIXTURE_EMAIL")" >> "$PATTERN_FILE"
esc_lines "$FIXTURE_COLLAB" >> "$PATTERN_FILE"
esc_lines "$FIXTURE_HANDLE" >> "$NOT_CARVED"

echo "=== ADR deciders carve-out — two-gate agreement suite ==="
echo
echo "Pattern set built via the library's esc_lines:"
echo "  PATTERN_FILE   : $(wc -l < "$PATTERN_FILE" | tr -d ' ') pattern(s)  [operator + collaborator dimensions]"
echo "  NOT_CARVED     : $(wc -l < "$NOT_CARVED" | tr -d ' ') pattern(s)  [the un-carved literal: the handle]"
echo "  EMPTY_NOT_CARVED: 0 patterns  [drives the shipped-behaviour negative control]"
echo

# --- Fixture table: ID | file | subject-line regex | expected verdict | expected R3 --
# The expected-match set lives HERE, not in the fixtures, so a fixture cannot declare
# its own expected verdict. R3 column: FIRES / silent / n-a (no ADR read for this row).
FIXTURES='
FX-1|fx1-handle-on-deciders.md|^deciders:|BLOCKED|FIRES
FX-2|fx2-name-on-deciders.md|^deciders:|SUPPRESSED-CARVEOUT|silent
FX-3|fx3-handle-in-body.md|^Authored by|BLOCKED|FIRES
FX-5|fx5-collaborator-on-deciders.md|^deciders:|SUPPRESSED-CARVEOUT|silent
FX-6|fx6-email-on-deciders.md|^deciders:|SUPPRESSED-CARVEOUT|silent
FX-7|fx7-name-and-handle-on-deciders.md|^deciders:|BLOCKED|FIRES
FX-8|fx8-clean-deciders.md|^deciders:|CLEAN|silent
'

# r3_rows <fixture-file> — copy the fixture into a throwaway ADR directory (so the lint
# reads it as a corpus member) and count its R3 findings. The fixtures deliberately do
# NOT carry an ADR-NNN filename in the tree, so the live corpus walk and the ADR
# numbering gate can never pick them up.
r3_rows() {
  _rr_tmp="$(mktemp -d)"
  mkdir -p "$_rr_tmp/release/ADRs"
  cp "$FIXDIR/$1" "$_rr_tmp/release/ADRs/ADR-901-deciders-carveout-fixture.md"
  _rr_out="$(python3 "$LINT" --root "$_rr_tmp" --handle "$FIXTURE_HANDLE" 2>/dev/null || true)"
  printf '%s\n' "$_rr_out" | grep -c '^R3' | tr -d ' '
  rm -rf "$_rr_tmp"
}

DENOM=0
echo "--- Per-fixture verdicts (both gates) ---"
printf '%-6s %-34s %-22s %-8s\n' "ID" "fixture" "depersonalization" "R3"
while IFS='|' read -r id file subject want_verdict want_r3; do
  [ -z "${id:-}" ] && continue
  DENOM=$((DENOM+1))
  [ -f "$FIXDIR/$file" ] || { bad "$id — fixture file missing: $file"; continue; }

  line="$(grep -m1 -E "$subject" "$FIXDIR/$file" || true)"
  if [ -z "$line" ]; then
    bad "$id — subject line matching /$subject/ not found in $file (extraction empty)"
    continue
  fi

  got_verdict="$(depersonalization_line_verdict \
    "release/ADRs/ADR-901-deciders-carveout-fixture.md" "$line" \
    "$PATTERN_FILE" "$NOT_CARVED" "$OVERRIDE_RE")"

  if [ "$want_r3" = "n-a" ]; then got_r3="n-a"
  else
    n="$(r3_rows "$file")"
    if [ "$n" -gt 0 ]; then got_r3="FIRES"; else got_r3="silent"; fi
  fi

  printf '%-6s %-34s %-22s %-8s\n' "$id" "$file" "$got_verdict" "$got_r3"
  check "$id depersonalization verdict" "$got_verdict" "$want_verdict"
  check "$id durability R3"             "$got_r3"      "$want_r3"
done <<EOF
$FIXTURES
EOF

echo
echo "--- Acceptance criteria ---"
# AC-2': the two gates AGREE (both block) on a deciders: line carrying the handle.
v1="$(depersonalization_line_verdict "release/ADRs/x.md" "$(grep -m1 '^deciders:' "$FIXDIR/fx1-handle-on-deciders.md")" "$PATTERN_FILE" "$NOT_CARVED" "$OVERRIDE_RE")"
r1="$(r3_rows fx1-handle-on-deciders.md)"
if [ "$v1" = "BLOCKED" ] && [ "$r1" -gt 0 ]; then
  ok "AC-2' both gates BLOCK the handle on a deciders: line (deperson=$v1, R3 rows=$r1)"
else
  bad "AC-2' gates disagree on the handle (deperson=$v1, R3 rows=$r1)"
fi
# AC-3': the two gates AGREE (both pass) on a deciders: line carrying only the name.
v2="$(depersonalization_line_verdict "release/ADRs/x.md" "$(grep -m1 '^deciders:' "$FIXDIR/fx2-name-on-deciders.md")" "$PATTERN_FILE" "$NOT_CARVED" "$OVERRIDE_RE")"
r2="$(r3_rows fx2-name-on-deciders.md)"
if [ "$v2" = "SUPPRESSED-CARVEOUT" ] && [ "$r2" -eq 0 ]; then
  ok "AC-3' both gates PASS the literal name on a deciders: line (deperson=$v2, R3 rows=$r2)"
else
  bad "AC-3' the fix made a gate strict on the carved-out name (deperson=$v2, R3 rows=$r2)"
fi

echo
echo "--- Control arms (a suite whose controls do not move is not measuring) ---"

# NEGATIVE CONTROL — the decisive one. With an EMPTY un-carved set the predicate must
# reproduce the SHIPPED pre-fix behaviour: the handle on a deciders: line is suppressed.
# If this arm ever returns BLOCKED, the suite can no longer tell the fixed gate from the
# broken one, and every PASS above becomes uninterpretable.
shipped="$(depersonalization_line_verdict "release/ADRs/x.md" "$(grep -m1 '^deciders:' "$FIXDIR/fx1-handle-on-deciders.md")" "$PATTERN_FILE" "$EMPTY_NOT_CARVED" "$OVERRIDE_RE")"
check "negative control — empty un-carved set reproduces the pre-fix defect" "$shipped" "SUPPRESSED-CARVEOUT"

# SENSITIVITY — the harness detects: a handle outside the carve-out is blocked.
sens="$(depersonalization_line_verdict "release/ADRs/x.md" "Authored by $FIXTURE_HANDLE." "$PATTERN_FILE" "$NOT_CARVED" "$OVERRIDE_RE")"
check "sensitivity — handle on a body line is BLOCKED" "$sens" "BLOCKED"

# SPECIFICITY — no false positive: a line with no identity literal never matches.
spec="$(depersonalization_line_verdict "release/ADRs/x.md" 'deciders: "operator + Stage 5 spoke"' "$PATTERN_FILE" "$NOT_CARVED" "$OVERRIDE_RE")"
check "specificity — role-only deciders line is CLEAN" "$spec" "CLEAN"

# NON-ADR control — the carve-out is file-class scoped and must not leak.
nonadr="$(depersonalization_line_verdict "core/standards/x.md" "deciders: \"$FIXTURE_NAME\"" "$PATTERN_FILE" "$NOT_CARVED" "$OVERRIDE_RE")"
check "non-ADR file — carve-out does not apply" "$nonadr" "BLOCKED"

# OVERRIDE precedence — the line-scoped marker is decided before the carve-out.
ovr="$(depersonalization_line_verdict "release/ADRs/x.md" "deciders: \"$FIXTURE_HANDLE\" <!-- repo-integrity: allow-depersonalization -->" "$PATTERN_FILE" "$NOT_CARVED" "$OVERRIDE_RE")"
check "override marker still takes precedence" "$ovr" "SUPPRESSED-OVERRIDE"

# EMPTY-HAYSTACK ARM — pins the here-string conversion's one non-mechanical hazard.
# The verdict function reads its haystack from `<<<"$content"` rather than a
# `printf '%s' "$content" | grep` pipe. The two are NOT equivalent when content is
# empty: printf emits ZERO lines, `<<<` emits ONE empty line. A pattern set able to
# match an empty line therefore flips `no match` to `match` on the swap, turning a
# CLEAN verdict into BLOCKED — in a branch-protection required gate, on any blank
# added line a PR happens to contain. Nothing pinned this before the conversion.
empty_v="$(depersonalization_line_verdict "release/ADRs/x.md" "" "$PATTERN_FILE" "$NOT_CARVED" "$OVERRIDE_RE")"
check "empty added line is CLEAN (here-string empty-haystack guard holds)" "$empty_v" "CLEAN"

# …and the same arm against a pattern file that DOES match an empty line, which is
# the condition the guard exists for. Built through the library's own esc_lines is
# impossible here by construction (it drops blank lines — that is its job), so the
# hostile pattern file is written directly. Without the `[ -z ]` guard this arm
# returns BLOCKED; with it, CLEAN. This is the arm that would have caught a
# mechanical `printf | grep` -> `<<<` substitution on this file.
EMPTY_MATCHING="$TMP/patterns_empty_matching"
printf '^.*$\n' > "$EMPTY_MATCHING"
empty_hostile="$(depersonalization_line_verdict "release/ADRs/x.md" "" "$EMPTY_MATCHING" "$NOT_CARVED" "$OVERRIDE_RE")"
check "empty line stays CLEAN even against an empty-matching pattern set" "$empty_hostile" "CLEAN"

# NON-VACUITY CONTROL for the arm above — the hostile pattern file must actually be
# hostile. A NON-empty line run against the same empty-matching set must NOT be
# CLEAN; if it were, the arm above would pass for the wrong reason and prove nothing.
hostile_ctl="$(depersonalization_line_verdict "core/standards/x.md" "any content at all" "$EMPTY_MATCHING" "$NOT_CARVED" "$OVERRIDE_RE")"
check "control — the empty-matching pattern set does match a non-empty line" "$hostile_ctl" "BLOCKED"

# esc_lines behaviour preservation — the helper was MOVED, not rewritten, so a literal
# carrying regex metacharacters must still be escaped rather than interpreted.
meta="$(esc_lines 'a.b*c' | tr -d '\n')"
check "esc_lines escapes regex metacharacters" "$meta" '\ba\.b\*c\b'
blank="$(esc_lines "$(printf '\n   \n')" | wc -l | tr -d ' ')"
check "esc_lines drops blank/whitespace-only lines" "$blank" "0"

echo
echo "--- Run-level decisions: the literal set a run scans (fixture arms a-f) ---"
# The run-level functions take NO actor parameter: who triggered the run cannot
# change what it scans, which is the decision record
# {{ADR:depersonalization-gate-scans-bot-runs}} in executable form. Each arm calls them
# with the arguments the workflow passes on that kind of run — the repository owner as
# the handle, never the actor — and the structural bindings further down assert that
# the workflow really passes those arguments. Effect here, call shape there.
FIXTURE_BOT="dependabot[bot]"
FIXTURE_IDENTITY="$(printf '%s\n%s' "$FIXTURE_NAME" "$FIXTURE_EMAIL")"
flat() { printf '%s' "$1" | tr '\n' '|'; }
EMPTY_PATTERNS="$TMP/patterns_run_empty"
: > "$EMPTY_PATTERNS"

# (a) SENSITIVITY, AC 3 — a run Dependabot started, on canonical, with the mirrored
# identity present. The workflow passes REPO_OWNER, so the set is the owner plus the
# identity lines. (That the bot's own login cannot enter the set is not asserted
# here: the function has no actor parameter, so such an arm could not fail. The
# call-shape bindings below assert the workflow passes the owner, not the actor.)
REPO_OWNER_A="$FIXTURE_HANDLE"
set_a="$(resolve_operator_literals 1 0 "$REPO_OWNER_A" "$FIXTURE_IDENTITY")"
check "(a) bot's run, canonical, identity set — literal set is owner + identity lines" \
  "$(flat "$set_a")" "$FIXTURE_HANDLE|$FIXTURE_NAME|$FIXTURE_EMAIL"
# …and the set is not decorative: a pattern file built from it BLOCKS the handle and
# the email on a body line, which is the measured verdict AC 3 asks for.
PATTERNS_A="$TMP/patterns_run_a"
esc_lines "$set_a" > "$PATTERNS_A"
check "(a) effect — the owner handle on a body line is BLOCKED on a bot's run" \
  "$(depersonalization_line_verdict "core/standards/x.md" "by $FIXTURE_HANDLE" "$PATTERNS_A" "" "$OVERRIDE_RE")" "BLOCKED"
check "(a) effect — the operator email on a body line is BLOCKED on a bot's run" \
  "$(depersonalization_line_verdict "core/standards/x.md" "mail $FIXTURE_EMAIL" "$PATTERNS_A" "" "$OVERRIDE_RE")" "BLOCKED"
check "(a) literal_set_verdict on that set is SCAN" "$(literal_set_verdict 1 "$PATTERNS_A")" "SCAN"

# (b) CONTROL, AC 4 — a human's run on canonical with the identity genuinely unset
# still fails loud.
check "(b) human's run, canonical, identity unset — preflight FAILs" "$(identity_preflight 1 "")" "FAIL"

# (c) MISSING-MIRROR arm — a run Dependabot started reads the Dependabot store; with
# the mirror absent the identity is unset there, and the preflight FAILs exactly as
# (b) does. The call is the same call: nothing in it can tell the two runs apart.
check "(c) bot's run, canonical, identity unset (mirror missing) — preflight FAILs" "$(identity_preflight 1 "")" "FAIL"
# Non-vacuity for (b)/(c): the preflight can say OK, so FAIL above is a decision.
check "(b/c control) canonical with the identity set — preflight is OK" "$(identity_preflight 1 "$FIXTURE_IDENTITY")" "OK"
# A whitespace-only identity is UNSET: esc_lines would drop it, so it would scan no
# name or email behind an OK — the hand-set Dependabot mirror is where it can slip in.
check "(b) canonical with a whitespace-only identity — preflight FAILs" \
  "$(identity_preflight 1 "$(printf ' \n\t ')")" "FAIL"

# (b') HANDLE PREFLIGHT — on canonical the handle must be the owner segment of the
# repository. Reachable only by an edit that re-binds the handle (to the actor, say)
# or an empty expression; either would leave the handle silently unscanned.
check "(b') canonical, owner = the repository's owner — OK" \
  "$(handle_preflight 1 "$FIXTURE_HANDLE" "$FIXTURE_HANDLE/pmo-platform")" "OK"
check "(b') canonical, handle re-bound to the bot's login — FAIL" \
  "$(handle_preflight 1 "$FIXTURE_BOT" "$FIXTURE_HANDLE/pmo-platform")" "FAIL"
check "(b') canonical, empty handle — FAIL" \
  "$(handle_preflight 1 "" "$FIXTURE_HANDLE/pmo-platform")" "FAIL"
check "(b') a fork — OK whatever its owner" \
  "$(handle_preflight 0 "fork-owner" "$FIXTURE_HANDLE/pmo-platform")" "OK"

# (d) FORK OPT-OUT — a fork that opted the operator dimension out, identity unset:
# the preflight passes, the set is empty, and the empty set passes with a notice.
check "(d) fork opted out, identity unset — preflight OK" "$(identity_preflight 0 "")" "OK"
set_d="$(resolve_operator_literals 0 1 "$FIXTURE_HANDLE" "")"
check "(d) fork opted out — literal set is empty" "$(flat "$set_d")" ""
check "(d) fork opted out — the empty set PASSes with a notice" "$(literal_set_verdict 0 "$EMPTY_PATTERNS")" "PASS-EMPTY"
# Pre-change behaviour preserved on the other fork path: not opted out, identity
# unset, so only the owner handle resolves.
set_d2="$(resolve_operator_literals 0 0 "$FIXTURE_HANDLE" "")"
check "(d control) fork NOT opted out, identity unset — the owner handle alone" "$(flat "$set_d2")" "$FIXTURE_HANDLE"

# (e) NO REGRESSION — actor = owner, canonical, identity set: the ordinary human run.
# The new set must equal, byte for byte, the inline construction it replaced, once
# each is captured by $(...).
set_e="$(resolve_operator_literals 1 0 "$FIXTURE_HANDLE" "$FIXTURE_IDENTITY")"
pre_e="$(printf '%s\n%s\n' "$FIXTURE_HANDLE" "$FIXTURE_IDENTITY")"
if [ "$set_e" = "$pre_e" ]; then
  ok "(e) actor = owner — literal set byte-identical to the pre-change construction"
else
  bad "(e) actor = owner — literal set differs from the pre-change construction: [$(flat "$set_e")] vs [$(flat "$pre_e")]"
fi
if [ "$(esc_lines "$set_e")" = "$(esc_lines "$pre_e")" ]; then
  ok "(e) …and so is the escaped pattern set built from it"
else
  bad "(e) the escaped pattern set differs from the pre-change one"
fi

# (f) THE EMPTY-SET GUARD — on canonical an empty literal set FAILs. That is the set
# the retired exemption produced on a bot's run with no collaborator list, which the
# gate used to pass with "nothing to match". Controls for the other two verdicts are
# (a) (SCAN) and (d) (PASS-EMPTY on a fork).
check "(f) canonical with an empty literal set — FAIL-EMPTY" "$(literal_set_verdict 1 "$EMPTY_PATTERNS")" "FAIL-EMPTY"

echo
echo "--- Structural binding: the workflow uses this library, not a private copy ---"
# ALL THREE binding patterns below are ANCHORED at `^[[:space:]]*` and reject a
# leading `#`. The unanchored forms they replace asked "does this string APPEAR in
# the workflow?", which a COMMENTED-OUT line answers yes — so the suite read 28/28
# green over a gate whose construction line never executed. Presence of a string is
# not execution of a statement, and these assertions are read as evidence of the
# latter. What the anchor does NOT close, stated rather than implied: a live line
# wrapped in `if false; then ... fi`, or one inside an unreached branch, still
# matches. Closing that needs the construction moved into the shared library so the
# suite can exercise it as EFFECT rather than assert it as text — a design change,
# named here rather than smuggled in. The anchor closes the shape that actually
# shipped; the residual is the honest remainder.
if grep -qE '^[[:space:]]*(\.|source)[[:space:]]+"[^"]*release/tools/lib/deciders-carveout\.sh"' "$WORKFLOW"; then
  ok "repo-integrity.yml sources the shared library (executable source statement, not a mention)"
else
  bad "repo-integrity.yml no longer sources release/tools/lib/deciders-carveout.sh on an executable line"
fi
if grep -qE '^[[:space:]]*[^#[:space:]][^#]*depersonalization_line_verdict' "$WORKFLOW"; then
  ok "repo-integrity.yml calls depersonalization_line_verdict (executable line, token not in a comment)"
else
  bad "repo-integrity.yml no longer calls depersonalization_line_verdict on an executable line"
fi
# CONSTRUCTION, not just the call. Sourcing the library and calling the verdict
# function are necessary and NOT sufficient: the whole delta between this fix
# working and this fix being decorative is one line in the workflow that puts the
# handle literal into the un-carved set. Delete it and `depersonalization_line_verdict`
# still runs, still sources, still returns — and returns SUPPRESSED-CARVEOUT on a
# handle-bearing `deciders:` line, which is the PRE-FIX DEFECT. The failure is silent
# by design: the library's documented empty-set fallback reproduces the shipped
# whole-line behaviour, which is the right call for a genuinely dark dimension and is
# exactly why a construction regression is indistinguishable from a legitimately dark
# run. The suite built its own NOT_CARVED above, so every arm before this one grades
# the PREDICATE given a correctly-constructed set. This grades the construction.
if grep -qE '^[[:space:]]*esc_lines[[:space:]]+"\$HANDLE_LITERAL"[[:space:]]*>>[[:space:]]*"\$NOT_CARVED_FILE"' "$WORKFLOW"; then
  ok "repo-integrity.yml POPULATES the un-carved set (esc_lines \$HANDLE_LITERAL >> \$NOT_CARVED_FILE, on an executable line)"
else
  bad "repo-integrity.yml no longer writes \$HANDLE_LITERAL into \$NOT_CARVED_FILE — the un-carved set is empty, so the gate silently reverts to whole-line suppression on deciders: lines"
fi
# Non-vacuity control for the three greps above: a token that must NOT be present. If
# this arm ever passes, the grep-based binding assertions are matching nothing real.
# Carries the SAME anchor as the assertion it controls — a control that exercises a
# pattern nobody ships is not a control of anything.
if grep -qE '^[[:space:]]*[^#[:space:]][^#]*depersonalization_line_verdict_THAT_DOES_NOT_EXIST' "$WORKFLOW"; then
  bad "binding-assertion control matched a nonexistent token — the greps prove nothing"
else
  ok "binding-assertion control — a nonexistent token is absent (greps are discriminating)"
fi
# ... and a construction-shaped control, because the arm above is a NEW pattern and a
# typo in it would pass silently as a nonexistent-token miss. A redirect into a file
# the workflow does not have must NOT match.
if grep -qE '^[[:space:]]*esc_lines[[:space:]]+"\$HANDLE_LITERAL"[[:space:]]*>>[[:space:]]*"\$NO_SUCH_CARVED_FILE"' "$WORKFLOW"; then
  bad "construction-assertion control matched a nonexistent redirect — the construction grep proves nothing"
else
  ok "construction-assertion control — a nonexistent redirect target is absent (the construction grep is shaped, not loose)"
fi

# RUN-LEVEL CALL SHAPE. The arms (a)-(f) grade the functions given the arguments the
# workflow is supposed to pass; these grade that it passes them, and that the branch
# each verdict selects still ends the run the way the verdict says. Same anchoring as
# the bindings above: an executable line, not a mention.
if grep -qE '^[[:space:]]*REPO_OWNER:[[:space:]]*[$][{][{][[:space:]]*github[.]repository_owner[[:space:]]*[}][}]' "$WORKFLOW"; then
  ok "repo-integrity.yml binds REPO_OWNER from github.repository_owner"
else
  bad "repo-integrity.yml no longer binds REPO_OWNER from github.repository_owner"
fi
# …exactly once, so a step-level REPO_OWNER cannot shadow the job binding unseen.
check "REPO_OWNER is bound exactly once in repo-integrity.yml" \
  "$(grep -cE '^[[:space:]]*REPO_OWNER:' "$WORKFLOW" || true)" "1"
if grep -qE '^[[:space:]]*case "[$][(]identity_preflight "[$]IS_CANONICAL" "[$][{]OPERATOR_IDENTITY:-[}]"[)]" in' "$WORKFLOW"; then
  ok "repo-integrity.yml decides the preflight through identity_preflight (no actor argument)"
else
  bad "repo-integrity.yml no longer routes the preflight through case \"\$(identity_preflight \"\$IS_CANONICAL\" \"\${OPERATOR_IDENTITY:-}\")\" on an executable line"
fi
if grep -qE '^[[:space:]]*case "[$][(]handle_preflight "[$]IS_CANONICAL" "[$][{]REPO_OWNER:-[}]" "[$][{]GITHUB_REPOSITORY:-[}]"[)]" in' "$WORKFLOW"; then
  ok "repo-integrity.yml checks the handle through handle_preflight"
else
  bad "repo-integrity.yml no longer routes the handle check through handle_preflight"
fi
if grep -qE '^[[:space:]]*OP_LITERALS="[$][(]resolve_operator_literals "[$]IS_CANONICAL" "[$]FORK_OPTED_OUT" "[$][{]REPO_OWNER:-[}]" "[$][{]OPERATOR_IDENTITY:-[}]"[)]"' "$WORKFLOW"; then
  ok "repo-integrity.yml resolves OP_LITERALS through resolve_operator_literals with the owner as the handle"
else
  bad "repo-integrity.yml no longer resolves OP_LITERALS through resolve_operator_literals with \${REPO_OWNER:-}"
fi
# …and that is the ONLY executable assignment to OP_LITERALS, so a later line cannot
# quietly empty or replace the set the library resolved (the retired exemption's shape).
check "OP_LITERALS is assigned exactly once on an executable line" \
  "$(grep -cE '^[^#]*OP_LITERALS=' "$WORKFLOW" || true)" "1"
if grep -qE '^[[:space:]]*HANDLE_LITERAL="[$][{]REPO_OWNER:-[}]"' "$WORKFLOW"; then
  ok "repo-integrity.yml sets HANDLE_LITERAL to the owner"
else
  bad "repo-integrity.yml no longer sets HANDLE_LITERAL=\"\${REPO_OWNER:-}\" on an executable line"
fi
if grep -qE '^[[:space:]]*case "[$][(]literal_set_verdict "[$]IS_CANONICAL" "[$]PATTERN_FILE"[)]" in' "$WORKFLOW"; then
  ok "repo-integrity.yml decides the empty-set branch through literal_set_verdict"
else
  bad "repo-integrity.yml no longer routes the empty-set branch through literal_set_verdict"
fi

# NEGATIVE: no executable line takes a literal from the actor. The actor may feed the
# summary notice only. "Executable" here means no `#` ahead of the assignment, so the
# pattern matches an assignment at the start of a line, which is where the retired
# lines sat, and it reads the WHOLE line, so an actor passed as an argument inside a
# command substitution is caught too. Control: the same pattern MUST find all three
# retired or regressed shapes in a synthetic copy, and must NOT find a commented one.
ACTOR_LITERAL_RE='^[^#]*(OP_LITERALS|HANDLE_LITERAL)=.*[$][{]?ACTOR([^A-Za-z0-9_]|$)'
actor_hits="$(grep -cE "$ACTOR_LITERAL_RE" "$WORKFLOW" || true)"
check "no executable line in repo-integrity.yml builds a literal from the actor" "$actor_hits" "0"
RETIRED_FIXTURE="$TMP/retired_actor_shape"
{
  printf '                OP_LITERALS="$ACTOR"\n'
  printf '                HANDLE_LITERAL="$ACTOR"\n'
  printf '          OP_LITERALS="$(resolve_operator_literals "$IS_CANONICAL" "$FORK_OPTED_OUT" "${ACTOR:-}" "${OPERATOR_IDENTITY:-}")"\n'
  printf '                # HANDLE_LITERAL="$ACTOR"\n'
} > "$RETIRED_FIXTURE"
check "…control — the pattern finds the three actor shapes and skips the commented one" \
  "$(grep -cE "$ACTOR_LITERAL_RE" "$RETIRED_FIXTURE" || true)" "3"

# EACH FAILING VERDICT STILL FAILS THE RUN. A binding that proves the verdict is read
# proves nothing if the arm it selects was edited to `exit 0`. arm_exits_1 reads the
# workflow from the first line matching <case-start>, finds the first arm line matching
# <arm>, and reports whether that arm reaches `exit 1` by its `;;`. It reads a file
# argument — no pipe, so no short-circuiting reader.
arm_exits_1() {
  awk -v start="$2" -v arm="$3" '
    !inside && $0 ~ start { inside = 1; next }
    inside && !inarm && $0 ~ arm { inarm = 1 }
    inarm {
      if ($0 ~ /exit 1/) { found = 1 }
      if ($0 ~ /;;/) { print (found ? "yes" : "no"); done = 1; exit }
    }
    END { if (!done) { print "absent" } }
  ' "$1"
}
for spec in \
  'identity_preflight|^[[:space:]]*FAIL[)]' \
  'identity_preflight|^[[:space:]]*[*][)]' \
  'handle_preflight|^[[:space:]]*FAIL[)]' \
  'handle_preflight|^[[:space:]]*[*][)]' \
  'literal_set_verdict|^[[:space:]]*FAIL-EMPTY[)]' \
  'literal_set_verdict|^[[:space:]]*[*][)]'; do
  fn_name="${spec%%|*}"; arm_re="${spec#*|}"
  check "the $fn_name arm /$arm_re/ ends in exit 1" \
    "$(arm_exits_1 "$WORKFLOW" "^[[:space:]]*case \"[\$][(]$fn_name " "$arm_re")" "yes"
done
# Control: the reader must say "no" for an arm edited to exit 0, and "yes" for the
# same arm intact, or the six PASSes above are not measuring.
ARM_FIXTURE_BAD="$TMP/arm_exit0"
ARM_FIXTURE_OK="$TMP/arm_exit1"
printf '          case "$(literal_set_verdict "$IS_CANONICAL" "$PATTERN_FILE")" in\n            FAIL-EMPTY)\n              echo "::error::x"\n              exit 0 ;;\n          esac\n' > "$ARM_FIXTURE_BAD"
printf '          case "$(literal_set_verdict "$IS_CANONICAL" "$PATTERN_FILE")" in\n            FAIL-EMPTY)\n              echo "::error::x"\n              exit 1 ;;\n          esac\n' > "$ARM_FIXTURE_OK"
check "…control — an arm edited to exit 0 reads no" \
  "$(arm_exits_1 "$ARM_FIXTURE_BAD" '^[[:space:]]*case "[$][(]literal_set_verdict ' '^[[:space:]]*FAIL-EMPTY[)]')" "no"
check "…control — the same arm intact reads yes" \
  "$(arm_exits_1 "$ARM_FIXTURE_OK" '^[[:space:]]*case "[$][(]literal_set_verdict ' '^[[:space:]]*FAIL-EMPTY[)]')" "yes"

# THE ANCHOR'S OWN REGRESSION ARM. Everything above measures the three patterns
# against the LIVE workflow, where anchored and unanchored forms agree — so nothing
# above would notice an anchor being dropped. This arm measures them against a
# synthetic file holding the exact shape that shipped green over a broken gate:
# each binding line, commented out. The anchored forms must find NOTHING; the
# unanchored forms must find all three, which is simultaneously the proof that the
# fixture is non-empty and the reproduction of the defect being closed.
ANCHOR_FIXTURE="$(mktemp)"
{
  printf '          # . "${GITHUB_WORKSPACE:-.}/release/tools/lib/deciders-carveout.sh"\n'
  printf '              # case "$(depersonalization_line_verdict \\\n'
  printf '          # esc_lines "$HANDLE_LITERAL" >> "$NOT_CARVED_FILE"\n'
} > "$ANCHOR_FIXTURE"
anchored_hits="$( { grep -cE '^[[:space:]]*(\.|source)[[:space:]]+"[^"]*release/tools/lib/deciders-carveout\.sh"' "$ANCHOR_FIXTURE" || true
                    grep -cE '^[[:space:]]*[^#[:space:]][^#]*depersonalization_line_verdict' "$ANCHOR_FIXTURE" || true
                    grep -cE '^[[:space:]]*esc_lines[[:space:]]+"\$HANDLE_LITERAL"[[:space:]]*>>[[:space:]]*"\$NOT_CARVED_FILE"' "$ANCHOR_FIXTURE" || true
                  } | paste -sd+ - | bc)"
unanchored_hits="$( { grep -c 'release/tools/lib/deciders-carveout\.sh' "$ANCHOR_FIXTURE" || true
                      grep -c 'depersonalization_line_verdict' "$ANCHOR_FIXTURE" || true
                      grep -cE 'esc_lines[[:space:]]+"\$HANDLE_LITERAL"[[:space:]]*>>[[:space:]]*"\$NOT_CARVED_FILE"' "$ANCHOR_FIXTURE" || true
                    } | paste -sd+ - | bc)"
rm -f "$ANCHOR_FIXTURE"
check "anchor rejects a commented-out binding line (all 3 patterns)" "$anchored_hits" "0"
check "…and the fixture is non-empty — the UNANCHORED forms still match it (the shipped defect)" "$unanchored_hits" "3"

echo
echo "=== Result ==="
echo "  fixtures exercised (denominator) : $DENOM"
echo "  assertions passed                : $PASS"
echo "  assertions failed                : $FAIL"
echo "  control arms                     : negative=$shipped  sensitivity=$sens  specificity=$spec"
echo "  scope                            : agreement asserted on the SHARED subject (the operator handle) only"
echo "  recorded residual                : FX-5 / FX-6 pin the email + collaborator dimensions as still whole-line suppressed"
if [ "$FAIL" -ne 0 ]; then
  echo "deciders-carveout suite: $PASS passed, $FAIL FAILED"
  exit 1
fi
echo "deciders-carveout suite: $PASS/$((PASS+FAIL)) passed over $DENOM fixtures"
exit 0

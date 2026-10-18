#!/usr/bin/env bash
# test_deciders_carveout.sh — two-gate agreement suite for the ADR `deciders:` carve-out.
#
# WHAT IT ASSERTS. The depersonalization gate and the ADR durability lint both scan an
# ADR `deciders:` line. Under the ratified name-only reading they must return the SAME
# verdict on their shared subject — the operator's GitHub handle — and they must both
# still PASS a line carrying only the literal name. That second arm is what stops the
# reconciliation from being "resolved" the lazy way, by making both gates strict.
#
# It also asserts that the depersonalization gate FAILS CLOSED on the three reads it
# makes before any per-line verdict: the changed-file listing, each file's added lines,
# and the literal scan. A read that could not run is UNEVALUABLE and turns the run red.
# It is never read as "nothing found". See the fail-closed section near the end.
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
# ADR-220 retired that.) This suite drives a
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
# ADR-220 in executable form. Each arm calls them
# with the arguments the workflow passes on that kind of run — the repository owner as
# the handle, never the actor — and the structural bindings further down assert that
# the workflow really passes those arguments. Effect here, call shape there.
FIXTURE_BOT="dependabot[bot]"
FIXTURE_IDENTITY="$(printf '%s\n%s' "$FIXTURE_NAME" "$FIXTURE_EMAIL")"
flat() { printf '%s' "$1" | tr '\n' '|'; }
EMPTY_PATTERNS="$TMP/patterns_run_empty"
: > "$EMPTY_PATTERNS"

# (a) SENSITIVITY — a run on canonical with the identity present, whoever started it
# (a maintainer's push on a Dependabot branch included); the actor never enters. The workflow passes REPO_OWNER, so the set is the owner plus the
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

# (c) A run Dependabot started has no copy of the identity (it receives only
# Dependabot secrets), so on a C6 change the preflight FAILs exactly as (b) does —
# closed, not passed unscanned. The call is the same call: nothing in it can tell the
# two runs apart.
check "(c) bot's run on a C6 change, canonical, identity unset — preflight FAILs" "$(identity_preflight 1 "")" "FAIL"
# Non-vacuity for (b)/(c): the preflight can say OK, so FAIL above is a decision.
check "(b/c control) canonical with the identity set — preflight is OK" "$(identity_preflight 1 "$FIXTURE_IDENTITY")" "OK"
# A whitespace-only identity is UNSET: esc_lines would drop it, so it would scan no
# name or email behind an OK.
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
# The loop variable is arm_spec, not spec: `spec` holds the specificity control's
# verdict, which the summary line prints.
for arm_spec in \
  'identity_preflight|^[[:space:]]*FAIL[)]' \
  'identity_preflight|^[[:space:]]*[*][)]' \
  'handle_preflight|^[[:space:]]*FAIL[)]' \
  'handle_preflight|^[[:space:]]*[*][)]' \
  'literal_set_verdict|^[[:space:]]*FAIL-EMPTY[)]' \
  'literal_set_verdict|^[[:space:]]*[*][)]' \
  'changed_files_verdict|^[[:space:]]*UNEVALUABLE[)]' \
  'changed_files_verdict|^[[:space:]]*[*][)]' \
  'added_lines_verdict|^[[:space:]]*UNEVALUABLE[)]' \
  'added_lines_verdict|^[[:space:]]*BINARY[)]' \
  'added_lines_verdict|^[[:space:]]*[*][)]' \
  'literal_scan_verdict|^[[:space:]]*UNEVALUABLE[)]' \
  'literal_scan_verdict|^[[:space:]]*[*][)]'; do
  fn_name="${arm_spec%%|*}"; arm_re="${arm_spec#*|}"
  check "the $fn_name arm /$arm_re/ ends in exit 1" \
    "$(arm_exits_1 "$WORKFLOW" "^[[:space:]]*case \"[\$][(]$fn_name " "$arm_re")" "yes"
done
# REACHING `exit 1` IS NOT ENOUGH: an arm that leaves first — a `continue`, `break`,
# `return` or `exit 0` ahead of its `exit 1` — still contains the line the check
# above looks for. arm_leaves_early prints the arm's lines up to its `;;` and reports
# whether any of them leaves. The BINARY arm's one legitimate `continue`, the
# compiled-package exception pinned below, is set aside by exact text.
PKG_EXCEPTION='if [ "${f#packages/}" != "$f" ] && [ "${f%.skill}" != "$f" ]; then continue; fi'
arm_leaves_early() {   # <file> <case-start> <arm>
  awk -v start="$2" -v arm="$3" -v keep="$PKG_EXCEPTION" '
    !inside && $0 ~ start { inside = 1; next }
    inside && !inarm && $0 ~ arm { inarm = 1 }
    inarm {
      l = $0; sub(/^[[:space:]]+/, "", l)
      if (l != keep && l !~ /^#/ && l ~ /(^|[^[:alnum:]_])(continue|break|return|exit 0)([^[:alnum:]_]|$)/) { leaves = 1 }
      if ($0 ~ /;;/) { print (leaves ? "yes" : "no"); done = 1; exit }
    }
    END { if (!done) { print "absent" } }
  ' "$1"
}
for arm_spec in \
  'identity_preflight|^[[:space:]]*FAIL[)]' \
  'handle_preflight|^[[:space:]]*FAIL[)]' \
  'literal_set_verdict|^[[:space:]]*FAIL-EMPTY[)]' \
  'changed_files_verdict|^[[:space:]]*UNEVALUABLE[)]' \
  'added_lines_verdict|^[[:space:]]*UNEVALUABLE[)]' \
  'added_lines_verdict|^[[:space:]]*BINARY[)]' \
  'literal_scan_verdict|^[[:space:]]*UNEVALUABLE[)]'; do
  fn_name="${arm_spec%%|*}"; arm_re="${arm_spec#*|}"
  check "the $fn_name arm /$arm_re/ does not leave before its exit 1" \
    "$(arm_leaves_early "$WORKFLOW" "^[[:space:]]*case \"[\$][(]$fn_name " "$arm_re")" "no"
done
ARM_FIXTURE_BREAK="$TMP/arm_break"
printf '            case "$(added_lines_verdict . "$B" "$H" "$f" "$A")" in\n              UNEVALUABLE)\n                echo "::error::x"\n                break\n                exit 1 ;;\n            esac\n' > "$ARM_FIXTURE_BREAK"
check "…control — an arm with a break ahead of its exit 1 reads yes" \
  "$(arm_leaves_early "$ARM_FIXTURE_BREAK" '^[[:space:]]*case "[$][(]added_lines_verdict ' '^[[:space:]]*UNEVALUABLE[)]')" "yes"
check "…control — the pinned package exception does not read as leaving" \
  "$(printf '            case "$(added_lines_verdict . "$B" "$H" "$f" "$A")" in\n              BINARY)\n                %s\n                exit 1 ;;\n            esac\n' "$PKG_EXCEPTION" > "$TMP/arm_pkg"; arm_leaves_early "$TMP/arm_pkg" '^[[:space:]]*case "[$][(]added_lines_verdict ' '^[[:space:]]*BINARY[)]')" "no"

# Control: the reader must say "no" for an arm edited to exit 0, and "yes" for the
# same arm intact, or the thirteen PASSes above are not measuring.
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
echo "--- Fail-closed evaluation: could-not-evaluate is never read as found-nothing ---"
# The gate reads the change three times before any per-line verdict — the changed-file
# listing, each file's added lines, the literal scan — and each read used to swallow
# every non-zero exit. A git that could not list the changed files therefore read as
# "no changed files", and a grep exit 2 as "no match": a red-worthy run passed. The
# three reads now live in the shared library as changed_files_verdict,
# added_lines_verdict and literal_scan_verdict, which report the could-not-evaluate
# state as its own verdict, UNEVALUABLE.
#
# Every arm below is a pair. The SENSITIVITY arm forces the could-not-evaluate state
# and expects UNEVALUABLE. The CONTROL arm takes the nearest legitimate "nothing found"
# (an empty but successful diff, a grep exit 1) and expects the pass verdict, so
# a function that answered UNEVALUABLE to everything fails here too. Where an arm's
# forcing input could be wrong for an unrelated reason, a non-vacuity check proves
# it forces what it claims to.
#
# Still hermetic: the fixture repository is a local `git init` under $TMP, with no
# remote. Its identity is synthetic and supplied per command, and signing and hooks
# are switched off per command, so the suite neither needs a configured git identity
# on the runner nor reaches for the operator's signing key or hooks.
for fn in changed_files_verdict added_lines_verdict literal_scan_verdict; do
  if ! declare -F "$fn" >/dev/null; then
    echo "FATAL: $LIB did not define $fn"; exit 1
  fi
done

FC_REPO="$TMP/fail-closed-repo"
FC_OUT="$TMP/fail-closed-out"
FC_ABSENT="0000000000000000000000000000000000000001"   # well-formed, never an object
fc_git() {
  git -C "$FC_REPO" -c user.name="$FIXTURE_NAME" -c user.email="$FIXTURE_EMAIL" \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"
}
mkdir -p "$FC_REPO/core" "$FC_REPO/release"
if ! git -C "$FC_REPO" init -q >/dev/null 2>&1; then
  echo "FATAL: could not initialise the fail-closed fixture repository"; exit 1
fi
printf 'line one\n' > "$FC_REPO/core/a.md"
if ! { fc_git add core/a.md && fc_git commit -q -m base; }; then
  echo "FATAL: could not commit the fixture base"; exit 1
fi
FC_BASE="$(fc_git rev-parse HEAD)"
printf 'line one\nAuthored by %s.\n' "$FIXTURE_HANDLE" > "$FC_REPO/core/a.md"
printf 'nothing to see\n' > "$FC_REPO/release/b.md"
if ! { fc_git add core/a.md release/b.md && fc_git commit -q -m head; }; then
  echo "FATAL: could not commit the fixture head"; exit 1
fi
FC_HEAD="$(fc_git rev-parse HEAD)"

# --- changed_files_verdict ----------------------------------------------------------
printf 'stale\n' > "$FC_OUT"
v="$(changed_files_verdict "$FC_REPO" "$FC_ABSENT" "$FC_HEAD" "$FC_OUT" 2>/dev/null)"
check "CF sensitivity — a base commit git does not have is UNEVALUABLE, not an empty listing" "$v" "UNEVALUABLE"
check "CF sensitivity — the out-file is truncated on UNEVALUABLE" "$(wc -l < "$FC_OUT" | tr -d ' ')" "0"

v="$(changed_files_verdict "$FC_REPO" "" "$FC_HEAD" "$FC_OUT" 2>/dev/null)"
check "CF sensitivity — an empty base revision is UNEVALUABLE" "$v" "UNEVALUABLE"
# Non-vacuity for the arm above: git itself ACCEPTS an empty base (it defaults the
# missing side to HEAD), so without the function's own guard this would list files
# from the wrong range and read LISTED.
fc_git diff --name-only ..."$FC_HEAD" >/dev/null 2>&1
check "CF control — git exits 0 on an empty base, so the guard is what rejects it" "$?" "0"

v="$(changed_files_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" "$FC_OUT")"
check "CF control — a real range is LISTED" "$v" "LISTED"
check "CF control — the listing names both changed files" "$(paste -s -d , "$FC_OUT")" "core/a.md,release/b.md"

printf 'stale\n' > "$FC_OUT"
v="$(changed_files_verdict "$FC_REPO" "$FC_HEAD" "$FC_HEAD" "$FC_OUT")"
check "CF control — an empty but successful diff is LISTED, not UNEVALUABLE" "$v" "LISTED"
check "CF control — …and lists no files" "$(wc -l < "$FC_OUT" | tr -d ' ')" "0"

# A listed path must be the file's real name. Two commits on top of FC_HEAD: one adds a
# file whose name carries a byte above 0x7F, one adds a file whose name carries a `"`.
# Under the default core.quotePath git C-quotes both; the gate's scope test then read
# the quoted string as out of scope and never scanned the file.
FC_U_NAME="$(printf 'core/caf\303\251.md')"
FC_Q_NAME='core/a"b.md'
printf 'Authored by %s.\n' "$FIXTURE_HANDLE" > "$FC_REPO/$FC_U_NAME"
if ! { fc_git add -- "$FC_U_NAME" && fc_git commit -q -m unicode; }; then
  echo "FATAL: could not commit the non-ASCII-name fixture"; exit 1
fi
FC_U="$(fc_git rev-parse HEAD)"
printf 'Authored by %s.\n' "$FIXTURE_HANDLE" > "$FC_REPO/$FC_Q_NAME"
if ! { fc_git add -- "$FC_Q_NAME" && fc_git commit -q -m quote; }; then
  echo "FATAL: could not commit the quote-name fixture"; exit 1
fi
FC_Q="$(fc_git rev-parse HEAD)"
# Non-vacuity: with quoting on, git really does quote both names, so these fixtures
# force the shape that used to read as out of scope.
check "CF control — git quotes the non-ASCII name under core.quotePath=true" \
  "$(fc_git -c core.quotePath=true diff --name-only "$FC_HEAD"..."$FC_U" | cut -c1)" '"'
check "CF control — git quotes the name carrying a quote under core.quotePath=false too" \
  "$(fc_git -c core.quotePath=false diff --name-only "$FC_U"..."$FC_Q" | cut -c1)" '"'

v="$(changed_files_verdict "$FC_REPO" "$FC_HEAD" "$FC_U" "$FC_OUT")"
check "CF control — a non-ASCII path is LISTED" "$v" "LISTED"
check "CF control — …under its real name, not git's quoted form" "$(cat "$FC_OUT")" "$FC_U_NAME"

printf 'stale\n' > "$FC_OUT"
v="$(changed_files_verdict "$FC_REPO" "$FC_U" "$FC_Q" "$FC_OUT")"
check "CF sensitivity — a path git must quote is UNEVALUABLE, not an out-of-scope name" "$v" "UNEVALUABLE"
check "CF sensitivity — …and the out-file is truncated" "$(wc -l < "$FC_OUT" | tr -d ' ')" "0"

# --- added_lines_verdict ------------------------------------------------------------
printf 'stale\n' > "$FC_OUT"
v="$(added_lines_verdict "$FC_REPO" "$FC_ABSENT" "$FC_HEAD" core/a.md "$FC_OUT" 2>/dev/null)"
check "AL sensitivity — a diff against a missing base is UNEVALUABLE, not 'nothing added'" "$v" "UNEVALUABLE"
check "AL sensitivity — the out-file is truncated on UNEVALUABLE" "$(wc -l < "$FC_OUT" | tr -d ' ')" "0"

v="$(added_lines_verdict "$FC_REPO" "$FC_BASE" "" core/a.md "$FC_OUT" 2>/dev/null)"
check "AL sensitivity — an empty head revision is UNEVALUABLE" "$v" "UNEVALUABLE"

v="$(added_lines_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" core/a.md "$FC_OUT")"
check "AL control — a real range is LISTED" "$v" "LISTED"
check "AL control — the added line carries its head line number" "$(cat "$FC_OUT")" "2:Authored by $FIXTURE_HANDLE."
FC_ADDED="$TMP/fail-closed-added"
cp "$FC_OUT" "$FC_ADDED"

printf 'stale\n' > "$FC_OUT"
v="$(added_lines_verdict "$FC_REPO" "$FC_HEAD" "$FC_HEAD" core/a.md "$FC_OUT")"
check "AL control — an empty but successful diff is LISTED, not UNEVALUABLE" "$v" "LISTED"
check "AL control — …and yields no added lines" "$(wc -l < "$FC_OUT" | tr -d ' ')" "0"

# A file git renders as binary prints "Binary files … differ" and no lines, so the
# extraction finds nothing although the read evaluated nothing. Two ways a TEXT file
# gets there: a `.gitattributes` line marking it `-diff`, which the pull request can
# add itself, and a NUL byte in its content. Both carry the handle.
printf 'core/hidden.md -diff\n' > "$FC_REPO/.gitattributes"
printf 'Authored by %s.\n' "$FIXTURE_HANDLE" > "$FC_REPO/core/hidden.md"
if ! { fc_git add .gitattributes core/hidden.md && fc_git commit -q -m hidden; }; then
  echo "FATAL: could not commit the -diff fixture"; exit 1
fi
FC_B1="$(fc_git rev-parse HEAD)"
printf 'Authored by %s.\000\n' "$FIXTURE_HANDLE" > "$FC_REPO/core/nul.md"
if ! { fc_git add core/nul.md && fc_git commit -q -m nul; }; then
  echo "FATAL: could not commit the NUL-byte fixture"; exit 1
fi
FC_B2="$(fc_git rev-parse HEAD)"
# Non-vacuity: git really renders both as binary, and the hidden file really carries
# the handle as text.
check "AL control — git renders the -diff file as binary" \
  "$(fc_git diff --unified=0 "$FC_Q"..."$FC_B1" -- core/hidden.md | grep -c '^Binary files ')" "1"
check "AL control — …and its text carries the handle" \
  "$(fc_git diff --text --unified=0 "$FC_Q"..."$FC_B1" -- core/hidden.md | grep -c "^+Authored by $FIXTURE_HANDLE")" "1"
check "AL control — git renders the NUL-byte file as binary" \
  "$(fc_git diff --unified=0 "$FC_B1"..."$FC_B2" -- core/nul.md | grep -c '^Binary files ')" "1"

printf 'stale\n' > "$FC_OUT"
v="$(added_lines_verdict "$FC_REPO" "$FC_Q" "$FC_B1" core/hidden.md "$FC_OUT")"
check "AL sensitivity — a text file marked -diff is BINARY, not 'nothing added'" "$v" "BINARY"
check "AL sensitivity — …and the out-file is truncated" "$(wc -l < "$FC_OUT" | tr -d ' ')" "0"
v="$(added_lines_verdict "$FC_REPO" "$FC_B1" "$FC_B2" core/nul.md "$FC_OUT")"
check "AL sensitivity — a file carrying a NUL byte is BINARY, not 'nothing added'" "$v" "BINARY"
v="$(added_lines_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" core/a.md "$FC_OUT")"
check "AL control — a text file beside them is still LISTED" "$v" "LISTED"

# Three more commits, used by the run-block replay at the end of this suite: a clean
# C6 change, a compiled package (binary by construction), and an out-of-scope change
# that carries the handle.
printf 'nothing to see\n' > "$FC_REPO/core/clean.md"
if ! { fc_git add core/clean.md && fc_git commit -q -m clean; }; then
  echo "FATAL: could not commit the clean fixture"; exit 1
fi
FC_C="$(fc_git rev-parse HEAD)"
mkdir -p "$FC_REPO/packages"
printf 'PK\003\004\000\001by %s\n\000' "$FIXTURE_HANDLE" > "$FC_REPO/packages/x.skill"
if ! { fc_git add packages/x.skill && fc_git commit -q -m package; }; then
  echo "FATAL: could not commit the package fixture"; exit 1
fi
FC_S="$(fc_git rev-parse HEAD)"
mkdir -p "$FC_REPO/docs"
printf 'Authored by %s.\n' "$FIXTURE_HANDLE" > "$FC_REPO/docs/note.md"
if ! { fc_git add docs/note.md && fc_git commit -q -m out-of-scope; }; then
  echo "FATAL: could not commit the out-of-scope fixture"; exit 1
fi
FC_O="$(fc_git rev-parse HEAD)"

# --- literal_scan_verdict -----------------------------------------------------------
FC_HITS="$TMP/fail-closed-hits"
FC_MALFORMED="$TMP/fail-closed-malformed-patterns"
FC_EMPTY_PATTERNS="$TMP/fail-closed-empty-patterns"
FC_CLEAN_ADDED="$TMP/fail-closed-clean-added"
FC_EMPTY_ADDED="$TMP/fail-closed-empty-added"
printf '(\n' > "$FC_MALFORMED"           # unbalanced group: grep -E exits 2 on BSD and GNU
: > "$FC_EMPTY_PATTERNS"
printf '1:nothing to see\n' > "$FC_CLEAN_ADDED"
: > "$FC_EMPTY_ADDED"

printf 'stale\n' > "$FC_HITS"
v="$(literal_scan_verdict "$FC_ADDED" "$FC_MALFORMED" "$FC_HITS" 2>/dev/null)"
check "LS sensitivity — a grep exit 2 (malformed pattern) is UNEVALUABLE, not 'no match'" "$v" "UNEVALUABLE"
check "LS sensitivity — the out-file is truncated on UNEVALUABLE" "$(wc -l < "$FC_HITS" | tr -d ' ')" "0"
# Non-vacuity for the arm above: this grep really does exit 2 on this pattern file.
# Without this, an implementation that rejected the pattern file for some other
# reason would pass the arm without the exit-2 branch ever being exercised.
grep -E -f "$FC_MALFORMED" "$FC_ADDED" >/dev/null 2>&1
check "LS control — this grep exits 2 on the malformed pattern file" "$?" "2"

v="$(literal_scan_verdict "$FC_ADDED" "$TMP/no-such-pattern-file" "$FC_HITS" 2>/dev/null)"
check "LS sensitivity — a missing pattern file is UNEVALUABLE" "$v" "UNEVALUABLE"
v="$(literal_scan_verdict "$FC_ADDED" "$FC_EMPTY_PATTERNS" "$FC_HITS")"
check "LS sensitivity — an empty pattern file is UNEVALUABLE" "$v" "UNEVALUABLE"
v="$(literal_scan_verdict "$TMP/no-such-added-file" "$PATTERN_FILE" "$FC_HITS")"
check "LS sensitivity — a missing added-lines file is UNEVALUABLE" "$v" "UNEVALUABLE"

v="$(literal_scan_verdict "$FC_ADDED" "$PATTERN_FILE" "$FC_HITS")"
check "LS control — an added line carrying a literal is HITS" "$v" "HITS"
check "LS control — the hit keeps its LINENO:CONTENT shape" "$(cat "$FC_HITS")" "2:Authored by $FIXTURE_HANDLE."

printf 'stale\n' > "$FC_HITS"
v="$(literal_scan_verdict "$FC_CLEAN_ADDED" "$PATTERN_FILE" "$FC_HITS")"
check "LS control — a grep exit 1 (no match) is NONE, not UNEVALUABLE" "$v" "NONE"
check "LS control — …and reports no hits" "$(wc -l < "$FC_HITS" | tr -d ' ')" "0"
v="$(literal_scan_verdict "$FC_EMPTY_ADDED" "$PATTERN_FILE" "$FC_HITS")"
check "LS control — an empty added-lines file (nothing added) is NONE" "$v" "NONE"

# A grep that says "matched" but prints no line is not a result the gate can act on:
# GNU grep, reading a line whose bytes are invalid in the locale as binary data, can
# do exactly that without -a. A grep function shadows the command inside a subshell
# to force that exit-0-and-silent shape; its twin returning 1 is the control that
# the shadow is the grep the function calls. (Whether such a line MATCHES at all is
# grep- and locale-dependent — BSD grep in a UTF-8 locale does not match it — and is
# a recorded follow-up, not asserted here.)
# The scan reads its input as text whatever bytes it carries (-a). On a hit line that
# also carries a NUL, the out-file holds the line itself, LINENO first; a grep
# without -a writes a "Binary file … matches" notice there instead, in either locale.
FC_NUL_ADDED="$TMP/fc-nul-added"
printf '2:Authored by %s.\000tail\n' "$FIXTURE_HANDLE" > "$FC_NUL_ADDED"
v="$(literal_scan_verdict "$FC_NUL_ADDED" "$PATTERN_FILE" "$FC_HITS")"
check "LS sensitivity — a hit line carrying a NUL is HITS" "$v" "HITS"
check "LS sensitivity — …and the out-file holds the line, not a binary notice" "$(cut -c1-2 "$FC_HITS")" "2:"
v="$( grep() { return 0; }; literal_scan_verdict "$FC_CLEAN_ADDED" "$PATTERN_FILE" "$FC_HITS" )"
check "LS sensitivity — a match that printed no line is UNEVALUABLE, not HITS" "$v" "UNEVALUABLE"
v="$( grep() { return 1; }; literal_scan_verdict "$FC_CLEAN_ADDED" "$PATTERN_FILE" "$FC_HITS" )"
check "LS control — the shadowing grep is the one called (exit 1 reads NONE)" "$v" "NONE"

# --- Shell-option independence ------------------------------------------------------
# The library promises the same verdict whatever the caller's shell options. This
# suite and the gate both run with pipefail on and (inside a command substitution)
# errexit off, so every arm above sees one option state, and the two classic ways a
# status gets lost both pass there. A pipeline into the extraction (`git diff | awk`)
# is rescued by pipefail; a bare `cmd; rc=$?` is harmless without errexit. Each pair
# below re-runs a sensitivity or control arm with pipefail OFF, which exposes the
# first, and with errexit ON, which aborts on the second and leaves an empty verdict.
fc_opts() {   # <label> <expected-verdict> <function> <args...>
  _fo_label="$1"; _fo_want="$2"; shift 2
  check "$_fo_label — without pipefail" "$( set +o pipefail; "$@" 2>/dev/null )" "$_fo_want"
  check "$_fo_label — under errexit"    "$( set -e; "$@" 2>/dev/null )" "$_fo_want"
}
fc_opts "CF sensitivity (missing base)" UNEVALUABLE changed_files_verdict "$FC_REPO" "$FC_ABSENT" "$FC_HEAD" "$FC_OUT"
fc_opts "CF control (empty diff)"       LISTED      changed_files_verdict "$FC_REPO" "$FC_HEAD" "$FC_HEAD" "$FC_OUT"
fc_opts "AL sensitivity (missing base)" UNEVALUABLE added_lines_verdict "$FC_REPO" "$FC_ABSENT" "$FC_HEAD" core/a.md "$FC_OUT"
fc_opts "AL control (real range)"       LISTED      added_lines_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" core/a.md "$FC_OUT"
fc_opts "LS sensitivity (grep exit 2)"  UNEVALUABLE literal_scan_verdict "$FC_ADDED" "$FC_MALFORMED" "$FC_HITS"
fc_opts "LS control (grep exit 1)"      NONE        literal_scan_verdict "$FC_CLEAN_ADDED" "$PATTERN_FILE" "$FC_HITS"

# --- Structural binding: the gate calls the three, and swallows nothing -------------
# Call-shaped, not mention-shaped: each pattern requires `$(<fn> `, so the gate's own
# "<fn> returned an unrecognised verdict" error line cannot satisfy it on its own.
for fn in changed_files_verdict added_lines_verdict literal_scan_verdict; do
  if grep -qE "^[[:space:]]*[^#[:space:]][^#]*\\\$\\(${fn}[[:space:]]" "$WORKFLOW"; then
    ok "repo-integrity.yml calls $fn (executable call, not a mention)"
  else
    bad "repo-integrity.yml no longer calls $fn on an executable line"
  fi
done
if grep -qE '^[[:space:]]*[^#[:space:]][^#]*\$\(literal_scan_verdict_THAT_DOES_NOT_EXIST[[:space:]]' "$WORKFLOW"; then
  bad "call-assertion control matched a nonexistent function — the call greps prove nothing"
else
  ok "call-assertion control — a nonexistent function call is absent (the call greps are discriminating)"
fi

# The whole depersonalization job, not just the three sites: no executable line in it
# may swallow a non-zero exit with the `|| true` idiom. The job is extracted from its
# key to the next top-level job key.
GATE1_BLOCK="$TMP/gate1-block"
awk '/^  depersonalization:$/ { on = 1; print; next }
     on && /^  [A-Za-z0-9_-]+:$/ { on = 0 }
     on' "$WORKFLOW" > "$GATE1_BLOCK"
SWALLOW_RE='^[[:space:]]*[^#[:space:]].*[|][|][[:space:]]*true([^[:alnum:]_]|$)'
check "Gate-1 extraction is the depersonalization job" "$(grep -c 'name: Depersonalization gate' "$GATE1_BLOCK")" "1"
check "Gate-1 extraction reaches the scan (spans the run block)" "$(grep -cE '\$\(literal_scan_verdict[[:space:]]' "$GATE1_BLOCK")" "1"
check "Gate-1 has no executable line that swallows a non-zero exit" "$(grep -cE "$SWALLOW_RE" "$GATE1_BLOCK")" "0"
# Sensitivity for the assertion above: the three shapes this change removed, verbatim,
# must each be caught, and a comment that merely mentions the idiom must not be.
SWALLOW_FIXTURE="$TMP/swallow-fixture"
cat > "$SWALLOW_FIXTURE" <<'EOF'
          mapfile -t ALL_CHANGED < <(git diff --name-only "$BASE_SHA"..."$HEAD_SHA" 2>/dev/null || true)
              ' || true)"
            HITS="$(printf '%s\n' "$ADDED_LINES" | grep -E -f "$PATTERN_FILE" || true)"
          # a comment that mentions || true is not a swallow
EOF
check "swallow detector catches the three removed shapes and skips the comment" "$(grep -cE "$SWALLOW_RE" "$SWALLOW_FIXTURE")" "3"

# --- Exact call shapes, the scan's hit arm, and the two read-backs ------------------
# A call that is present but aimed at the wrong range or file is a silent pass as
# surely as a missing one: `changed_files_verdict . "$HEAD_SHA" "$HEAD_SHA" …` lists
# nothing and passes, and a loop that reads /dev/null scans nothing. Each line below
# must appear in Gate 1 exactly once, compared whole after its indentation, so no
# argument can drift without failing here.
line_count() {   # <file> <exact line, leading whitespace ignored>
  awk -v want="$2" '{ sub(/^[[:space:]]+/, ""); if ($0 == want) n++ } END { print n + 0 }' "$1"
}
for want in \
  'case "$(changed_files_verdict . "$BASE_SHA" "$HEAD_SHA" "$CHANGED_LIST_FILE")" in' \
  'done < "$CHANGED_LIST_FILE"' \
  'case "$(added_lines_verdict . "$BASE_SHA" "$HEAD_SHA" "$f" "$ADDED_FILE")" in' \
  'case "$(literal_scan_verdict "$ADDED_FILE" "$PATTERN_FILE" "$HITS_FILE")" in' \
  'HITS) : ;;' \
  'done < "$HITS_FILE"'; do
  check "Gate 1 carries exactly once: $want" "$(line_count "$GATE1_BLOCK" "$want")" "1"
done
# Control: the comparison must miss a drifted argument and a skipped hit arm.
DRIFT_FIXTURE="$TMP/drift-fixture"
printf '          case "$(changed_files_verdict . "$HEAD_SHA" "$HEAD_SHA" "$CHANGED_LIST_FILE")" in\n              HITS) continue ;;\n' > "$DRIFT_FIXTURE"
check "…control — a drifted range and a skipped hit arm are not counted" \
  "$(line_count "$DRIFT_FIXTURE" 'case "$(changed_files_verdict . "$BASE_SHA" "$HEAD_SHA" "$CHANGED_LIST_FILE")" in')$(line_count "$DRIFT_FIXTURE" 'HITS) : ;;')" "00"

# The definition guard must name every library function the gate calls. A function
# missing from the guard but still called reads as an empty verdict if the library
# ever stops defining it; the call sites' `*)` arms catch that today, and this keeps
# the guard true to its own claim. The guard is the `for fn in … ; do` list that
# follows the library's `.` line.
guard_names() {   # <file> — the names in the first `for fn in … ; do` list, one space apart
  awk '/^[[:space:]]*for fn in / { on = 1 }
       on { line = $0; sub(/^[[:space:]]*for fn in /, "", line); sub(/;[[:space:]]*do.*$/, "", line)
            gsub(/\\/, " ", line); out = out " " line; if ($0 ~ /;[[:space:]]*do/) exit }
       END { gsub(/[[:space:]]+/, " ", out); sub(/^ /, "", out); sub(/ $/, "", out); print out }' "$1"
}
guard_missing() {   # <block-file> — library functions the block calls that its guard omits
  _gm_guard=" $(guard_names "$1") "
  _gm_missing=""
  for _gm_fn in $(sed -nE 's/^([a-z_][a-z0-9_]*)\(\)[[:space:]]*\{.*/\1/p' "$LIB"); do
    if grep -qE "^[[:space:]]*[^#[:space:]][^#]*\\\$\(${_gm_fn}[[:space:]]" "$1"; then
      case "$_gm_guard" in *" $_gm_fn "*) : ;; *) _gm_missing="$_gm_missing $_gm_fn" ;; esac
    fi
  done
  printf '%s\n' "${_gm_missing# }"
}
check "Gate 1's definition guard names every library function the gate calls" "$(guard_missing "$GATE1_BLOCK")" ""
GUARD_FIXTURE="$TMP/guard-fixture"
printf '          for fn in esc_lines identity_preflight \\\n                    changed_files_verdict; do\n          case "$(literal_scan_verdict "$A" "$B" "$C")" in\n' > "$GUARD_FIXTURE"
check "…control — the guard reader parses a continued list" "$(guard_names "$GUARD_FIXTURE")" "esc_lines identity_preflight changed_files_verdict"
check "…control — a called function missing from the guard is reported" "$(guard_missing "$GUARD_FIXTURE")" "literal_scan_verdict"

# --- The pass arms, the binary exception, the scope list and the exit-0 count -------
# An arm label merged into a pass arm (`LISTED|UNEVALUABLE) : ;;`) leaves the failing
# arm in place and unreachable, so the exit-arm reader above still reads "yes". Each
# pass arm must therefore appear exactly as written, as many times as the gate has it.
check "Gate 1 carries the LISTED pass arm exactly twice" "$(line_count "$GATE1_BLOCK" 'LISTED) : ;;')" "2"
check "Gate 1 carries the NONE skip arm exactly once" "$(line_count "$GATE1_BLOCK" 'NONE) continue ;;')" "1"
check "Gate 1 carries the packages/*.skill binary exception exactly once" \
  "$(line_count "$GATE1_BLOCK" 'if [ "${f#packages/}" != "$f" ] && [ "${f%.skill}" != "$f" ]; then continue; fi')" "1"
check "Gate 1 carries the C6 scope list exactly once" \
  "$(line_count "$GATE1_BLOCK" 'core/*|release/*|operations/*|packages/*) CHANGED+=("$f") ;;')" "1"
check "Gate 1 exempts only release/releases/ ahead of the scope list" \
  "$(grep -cE '^[[:space:]]*release/releases/[*][)] : ;;' "$GATE1_BLOCK")" "1"
# The scope `case` must hold exactly these three arms, in this order: an extra arm —
# another exemption ahead of the scope list — leaves a C6 subtree unscanned while
# every line pinned above still matches. The reader takes the first `case "$f" in`
# and prints each arm label up to its `)`.
scope_arms() {   # <file>
  awk 'index($0, "case \"$f\" in") && !on { on = 1; next }
       on && /^[[:space:]]*esac/ { exit }
       on && /^[[:space:]]*[^#[:space:]][^)]*[)]/ { l = $0; sub(/^[[:space:]]+/, "", l); sub(/[)].*$/, "", l); printf "%s ", l }' "$1"
}
check "Gate 1's scope case holds exactly the exemption, the C6 list and the default" \
  "$(scope_arms "$GATE1_BLOCK")" "release/releases/* core/*|release/*|operations/*|packages/* * "
SCOPE_FIXTURE="$TMP/scope-fixture"
printf '            case "$f" in\n              release/releases/*) : ;;\n              core/private/*) : ;;\n              core/*|release/*|operations/*|packages/*) CHANGED+=("$f") ;;\n              *) : ;;\n            esac\n' > "$SCOPE_FIXTURE"
check "…control — an extra exemption arm is seen" \
  "$(scope_arms "$SCOPE_FIXTURE")" "release/releases/* core/private/* core/*|release/*|operations/*|packages/* * "
# Every executable `exit 0` in the job, counted: the out-of-scope pass, the opted-out
# fork's empty set, and the clean verdict. An early `exit 0` inserted anywhere — the
# retired bot exemption returning as control flow, say — changes the count.
EXIT0_RE='^[^#]*(^|[^[:alnum:]_])exit 0([^0-9]|$)'
check "Gate 1 has exactly three executable exit 0 lines" "$(grep -cE "$EXIT0_RE" "$GATE1_BLOCK")" "3"
EXIT0_FIXTURE="$TMP/exit0-fixture"
printf '          [ "$BOT" -eq 1 ] && exit 0\n            exit 0\n          # exit 0 in a comment\n          exit 10\n' > "$EXIT0_FIXTURE"
check "…control — the exit 0 count reads code, not comments or exit 10" "$(grep -cE "$EXIT0_RE" "$EXIT0_FIXTURE")" "2"

# --- The secrets: step-scoped, canonical names only, and scope before identity ----
# The identity is bound to the scan step only, never at job level, where the checkout
# action would run with it. It is read from the Actions store under its canonical
# name; there is deliberately no Dependabot-store copy, so no other name may appear.
GATE1_JOB_ENV="$TMP/gate1-job-env"
awk '/^  depersonalization:$/ { on = 1; next } on && /^    steps:$/ { exit } on' "$WORKFLOW" > "$GATE1_JOB_ENV"
SECRET_REF_RE='secrets[.][A-Za-z_]|secrets\['
check "Gate 1's job-level env binds no secret" "$(grep -cE "$SECRET_REF_RE" "$GATE1_JOB_ENV")" "0"
check "Gate 1 references secrets on exactly two lines, the scan step's two bindings" \
  "$(grep -cE "$SECRET_REF_RE" "$GATE1_BLOCK")" "2"
SECRET_FIXTURE="$TMP/secret-fixture"
printf '        env:\n          X: ${{ secrets.OPERATOR_IDENTITY_DEPENDABOT }}\n          Y: ${{ secrets['"'"'OPERATOR_IDENTITY'"'"'] }}\n          echo "set it in repo secrets."\n' > "$SECRET_FIXTURE"
check "…control — both reference syntaxes count, prose does not" "$(grep -cE "$SECRET_REF_RE" "$SECRET_FIXTURE")" "2"
check "…control — the job-level extraction holds the job's env" "$(grep -c 'REPO_OWNER: ' "$GATE1_JOB_ENV")" "1"
check "Gate 1 reads the identity from its canonical name, once" \
  "$(line_count "$GATE1_BLOCK" 'OPERATOR_IDENTITY: ${{ secrets.OPERATOR_IDENTITY }}')" "1"
check "Gate 1 reads the collaborator list from its canonical name, once" \
  "$(grep -cF 'COLLABORATOR_NAMES: ${{ secrets.COLLABORATOR_NAMES }}' "$GATE1_BLOCK")" "1"
check "Gate 1 names no Dependabot-store copy of either secret" "$(grep -c '_DEPENDABOT' "$GATE1_BLOCK")" "0"
# Scope first: the C6 listing and its no-C6-change pass come before the identity
# check, so a run that changes no C6 file passes without reading the identity.
first_line() {   # <file> <fixed text> — the line number of its first occurrence, or 0
  awk -v want="$2" 'index($0, want) { print NR; found = 1; exit } END { if (!found) print 0 }' "$1"
}
L_SCOPE="$(first_line "$GATE1_BLOCK" 'case "$(changed_files_verdict ')"
L_PASS="$(first_line "$GATE1_BLOCK" 'no changed files under the C6 domains')"
L_IDENT="$(first_line "$GATE1_BLOCK" 'case "$(identity_preflight ')"
check "Gate 1 lists the C6 changes before it checks the identity" \
  "$([ "$L_SCOPE" -gt 0 ] && [ "$L_IDENT" -gt "$L_SCOPE" ] && echo yes || echo no)" "yes"
check "Gate 1 passes a run with no C6 change before it checks the identity" \
  "$([ "$L_PASS" -gt 0 ] && [ "$L_IDENT" -gt "$L_PASS" ] && echo yes || echo no)" "yes"
# The range the gate reads and the literal assignments it builds, pinned. The
# replay below injects BASE_SHA and HEAD_SHA itself, so only a pin sees the step's
# own binding drift (a base bound to the head lists nothing and passes); and a
# second, emptying assignment to a literal after it is built undoes the carve-out's
# handle block while every other line still matches.
check "Gate 1 binds BASE_SHA to the pull request's base, once" \
  "$(line_count "$GATE1_BLOCK" 'BASE_SHA: ${{ github.event.pull_request.base.sha }}')" "1"
check "Gate 1 binds HEAD_SHA to the pull request's head, once" \
  "$(line_count "$GATE1_BLOCK" 'HEAD_SHA: ${{ github.event.pull_request.head.sha }}')" "1"
check "Gate 1 assigns HANDLE_LITERAL on exactly two executable lines" \
  "$(grep -cE '^[[:space:]]*HANDLE_LITERAL=' "$GATE1_BLOCK")" "2"
check "Gate 1 assigns COLLAB_LITERALS on exactly two executable lines" \
  "$(grep -cE '^[[:space:]]*COLLAB_LITERALS=' "$GATE1_BLOCK")" "2"
check "Gate 1 skips only a path with nothing to read (nothing there, or a real directory), never a symlink, once" \
  "$(line_count "$GATE1_BLOCK" 'if { [ ! -e "$f" ] || [ -d "$f" ]; } && [ ! -L "$f" ]; then continue; fi')" "1"

# --- Gate 1's run block, executed ---------------------------------------------------
# Everything above reads the workflow as text. An edit inside an arm — a `continue`
# or `break` ahead of its `exit 1` — keeps every pinned line and changes what the job
# does. So the scan step's own run block is extracted and executed against the
# fixture repository, with synthetic literals, and graded by its exit status: the
# job's verdict, not its wording. The library is supplied through GITHUB_WORKSPACE,
# exactly as the step sources it; the environment is cleared except for what the
# step's env: block and the runner provide.
RUN_BLOCK="$TMP/gate1-run.sh"
awk '
  index($0, "- name: Scan C6-domain changed files for operator and collaborator personal data") { step = 1; next }
  step && !body && /^[[:space:]]+run: [|][[:space:]]*$/ { body = 1; next }
  body { if ($0 != "" && $0 !~ /^          /) exit; sub(/^          /, ""); print }
' "$WORKFLOW" > "$RUN_BLOCK"
check "run-block extraction holds the scan step's script" \
  "$(grep -cF 'case "$(changed_files_verdict . "$BASE_SHA" "$HEAD_SHA" "$CHANGED_LIST_FILE")" in' "$RUN_BLOCK")" "1"
RB_WS="$TMP/gate1-workspace"
mkdir -p "$RB_WS/release/tools/lib"
cp "$LIB" "$RB_WS/release/tools/lib/deciders-carveout.sh"
RB_REPO="$FIXTURE_HANDLE/fixture-repository"
RB_IDENTITY="$(printf '%s\n%s' "$FIXTURE_NAME" "$FIXTURE_EMAIL")"
gate_run() {   # <run-block> <base> <head> <actor> <sender-type> <identity> [<collaborators>] — prints the exit status
  ( cd "$FC_REPO" && env -i PATH="$PATH" HOME="$TMP" LC_ALL=C \
      GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
      GITHUB_WORKSPACE="$RB_WS" GITHUB_REPOSITORY="$RB_REPO" CANONICAL_REPO="$RB_REPO" \
      GITHUB_STEP_SUMMARY="$TMP/gate1-summary.md" \
      REPO_OWNER="$FIXTURE_HANDLE" ACTOR="$4" SENDER_TYPE="$5" \
      OPERATOR_IDENTITY="$6" COLLABORATOR_NAMES="${7:-}" FORK_OPTOUT="" \
      BASE_SHA="$2" HEAD_SHA="$3" bash "$1" >/dev/null 2>&1 )
  printf '%s\n' "$?"
}
BOT="dependabot[bot]"
check "run block — a clean C6 change passes"                     "$(gate_run "$RUN_BLOCK" "$FC_B2" "$FC_C" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"
check "run block — the handle added under core/ fails"           "$(gate_run "$RUN_BLOCK" "$FC_BASE" "$FC_HEAD" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
check "run block — a bot's run is scanned and fails on the handle" "$(gate_run "$RUN_BLOCK" "$FC_BASE" "$FC_HEAD" "$BOT" Bot "$RB_IDENTITY")" "1"
check "run block — a bot's clean run passes after a scan"         "$(gate_run "$RUN_BLOCK" "$FC_B2" "$FC_C" "$BOT" Bot "$RB_IDENTITY")" "0"
check "run block — a bot's run with no identity, on a C6 change, fails closed" "$(gate_run "$RUN_BLOCK" "$FC_B2" "$FC_C" "$BOT" Bot "")" "1"
check "run block — a human's run with no identity, on a C6 change, fails closed" "$(gate_run "$RUN_BLOCK" "$FC_B2" "$FC_C" "$FIXTURE_HANDLE" User "")" "1"
check "run block — a bot's run with no identity and no C6 change passes, by scope" "$(gate_run "$RUN_BLOCK" "$FC_S" "$FC_O" "$BOT" Bot "")" "0"
check "run block — a human's run with no identity and no C6 change passes, by scope" "$(gate_run "$RUN_BLOCK" "$FC_S" "$FC_O" "$FIXTURE_HANDLE" User "")" "0"
check "run block — a base commit git does not have fails closed" "$(gate_run "$RUN_BLOCK" "$FC_ABSENT" "$FC_HEAD" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
check "run block — a name git must quote fails closed"           "$(gate_run "$RUN_BLOCK" "$FC_U" "$FC_Q" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
check "run block — a non-ASCII name is scanned and fails on the handle" "$(gate_run "$RUN_BLOCK" "$FC_HEAD" "$FC_U" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
check "run block — a text file marked -diff fails closed"        "$(gate_run "$RUN_BLOCK" "$FC_Q" "$FC_B1" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
check "run block — a compiled package passes as binary"          "$(gate_run "$RUN_BLOCK" "$FC_C" "$FC_S" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"
check "run block — the handle outside the C6 domains passes by scope" "$(gate_run "$RUN_BLOCK" "$FC_S" "$FC_O" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"
# Five more commits for the cases the text pins cannot grade by effect.
#   D1 — an ADR whose `deciders:` line carries the handle: blocked (the carve-out is
#        name-only, ADR-116).  D2 — the same line carrying only the name: passes.
#   G  — a collaborator's name under core/: blocked when the list is set.
#   L  — a dangling symlink whose target text carries the handle: read, and blocked.
#   X  — only a deletion: nothing to scan, passes.
mkdir -p "$FC_REPO/core/ADRs"
printf -- '---\ntitle: fixture\ndeciders: "%s"\n---\n' "$FIXTURE_HANDLE" > "$FC_REPO/core/ADRs/ADR-999-fixture.md"
if ! { fc_git add core/ADRs/ADR-999-fixture.md && fc_git commit -q -m adr-handle; }; then
  echo "FATAL: could not commit the deciders-handle fixture"; exit 1
fi
FC_D1="$(fc_git rev-parse HEAD)"
printf -- '---\ntitle: fixture\ndeciders: "%s"\n---\n' "$FIXTURE_NAME" > "$FC_REPO/core/ADRs/ADR-998-fixture.md"
if ! { fc_git add core/ADRs/ADR-998-fixture.md && fc_git commit -q -m adr-name; }; then
  echo "FATAL: could not commit the deciders-name fixture"; exit 1
fi
FC_D2="$(fc_git rev-parse HEAD)"
FC_COLLAB="Grace Hopper"
printf 'Reviewed by %s.\n' "$FC_COLLAB" > "$FC_REPO/core/collab.md"
if ! { fc_git add core/collab.md && fc_git commit -q -m collab; }; then
  echo "FATAL: could not commit the collaborator fixture"; exit 1
fi
FC_G="$(fc_git rev-parse HEAD)"
ln -s "../$FIXTURE_HANDLE-elsewhere" "$FC_REPO/core/link.md"
if ! { fc_git add core/link.md && fc_git commit -q -m link; }; then
  echo "FATAL: could not commit the symlink fixture"; exit 1
fi
FC_L="$(fc_git rev-parse HEAD)"
check "…control — the symlink fixture is a link whose target does not exist" \
  "$([ -L "$FC_REPO/core/link.md" ] && [ ! -e "$FC_REPO/core/link.md" ] && echo dangling || echo other)" "dangling"
if ! fc_git rm -q core/clean.md || ! fc_git commit -q -m delete; then
  echo "FATAL: could not commit the deletion fixture"; exit 1
fi
FC_X="$(fc_git rev-parse HEAD)"
check "run block — the handle on an ADR deciders: line fails (the carve-out is name-only)" \
  "$(gate_run "$RUN_BLOCK" "$FC_O" "$FC_D1" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
check "run block — the name alone on an ADR deciders: line passes (the carve-out)" \
  "$(gate_run "$RUN_BLOCK" "$FC_D1" "$FC_D2" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"
check "run block — a collaborator's name fails when the list is set" \
  "$(gate_run "$RUN_BLOCK" "$FC_D2" "$FC_G" "$FIXTURE_HANDLE" User "$RB_IDENTITY" "$FC_COLLAB")" "1"
check "…control — the same change passes with no collaborator list" \
  "$(gate_run "$RUN_BLOCK" "$FC_D2" "$FC_G" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"
check "run block — a dangling symlink is read, and its target text fails on the handle" \
  "$(gate_run "$RUN_BLOCK" "$FC_G" "$FC_L" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
check "run block — a deletion alone passes, with nothing to scan" \
  "$(gate_run "$RUN_BLOCK" "$FC_L" "$FC_X" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"

# Two shapes a skip test can get wrong, from Stage 7 pass 3:
#   LD — a symlink to a DIRECTORY whose target text carries the handle: read and
#        blocked (a bare `-d` test would skip it).
#   PD — a file under packages/ replaced by a directory holding a compiled package:
#        the old path is a directory now and is skipped; the package inside passes.
mkdir -p "$FC_REPO/core/$FIXTURE_HANDLE-dir"
printf 'nothing to see\n' > "$FC_REPO/core/$FIXTURE_HANDLE-dir/x.md"
if ! { fc_git add "core/$FIXTURE_HANDLE-dir/x.md" && fc_git commit -q -m dir; }; then
  echo "FATAL: could not commit the directory fixture"; exit 1
fi
FC_DA="$(fc_git rev-parse HEAD)"
ln -s "$FIXTURE_HANDLE-dir" "$FC_REPO/core/dirlink"
if ! { fc_git add core/dirlink && fc_git commit -q -m dirlink; }; then
  echo "FATAL: could not commit the directory-symlink fixture"; exit 1
fi
FC_LD="$(fc_git rev-parse HEAD)"
check "…control — the directory-symlink fixture is a link to an existing directory" \
  "$([ -L "$FC_REPO/core/dirlink" ] && [ -d "$FC_REPO/core/dirlink" ] && echo dirlink || echo other)" "dirlink"
mkdir -p "$FC_REPO/packages"
printf 'plain text\n' > "$FC_REPO/packages/foo"
if ! { fc_git add packages/foo && fc_git commit -q -m pkgfile; }; then
  echo "FATAL: could not commit the package-path file fixture"; exit 1
fi
FC_PF="$(fc_git rev-parse HEAD)"
if ! fc_git rm -q packages/foo; then
  echo "FATAL: could not remove the package-path file"; exit 1
fi
mkdir -p "$FC_REPO/packages/foo"
printf 'PK\003\004\000\001\000' > "$FC_REPO/packages/foo/x.skill"
if ! { fc_git add packages/foo/x.skill && fc_git commit -q -m pkgdir; }; then
  echo "FATAL: could not commit the file-to-directory fixture"; exit 1
fi
FC_PD="$(fc_git rev-parse HEAD)"
check "run block — a symlink to a directory is read, and its target text fails on the handle" \
  "$(gate_run "$RUN_BLOCK" "$FC_DA" "$FC_LD" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
check "run block — a file replaced by a directory holding a package passes" \
  "$(gate_run "$RUN_BLOCK" "$FC_PF" "$FC_PD" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"

# git looks for a NUL only in a file's first 8000 bytes. A text file whose NUL sits
# past that window is diffed as text, and the NUL then cannot survive the gate's
# line handling, so the literal beside it could be lost. The read reports it BINARY,
# and the run block fails closed on it.
awk 'BEGIN { for (i = 0; i < 9000; i++) printf "a"; printf "\n" }' > "$FC_REPO/core/latenul.md"
printf 'x\000 Authored by %s.\n' "$FIXTURE_HANDLE" >> "$FC_REPO/core/latenul.md"
if ! { fc_git add core/latenul.md && fc_git commit -q -m late-nul; }; then
  echo "FATAL: could not commit the late-NUL fixture"; exit 1
fi
FC_N="$(fc_git rev-parse HEAD)"
check "…control — git diffs the late-NUL file as text, not binary" \
  "$(fc_git diff --unified=0 "$FC_PD"..."$FC_N" -- core/latenul.md | grep -c '^Binary files ')" "0"
check "AL sensitivity — a NUL past git's binary window is BINARY, not text" \
  "$(added_lines_verdict "$FC_REPO" "$FC_PD" "$FC_N" core/latenul.md "$TMP/latenul-added")" "BINARY"
check "run block — a NUL past git's binary window fails closed" \
  "$(gate_run "$RUN_BLOCK" "$FC_PD" "$FC_N" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
# Only ADDED lines are read for a NUL. Appending a clean line after the NUL line
# (whose text can surface in the hunk header) and then removing the NUL line are
# both readable changes, and both pass.
printf 'clean tail\n' >> "$FC_REPO/core/latenul.md"
if ! { fc_git add core/latenul.md && fc_git commit -q -m nul-append; }; then
  echo "FATAL: could not commit the append-after-NUL fixture"; exit 1
fi
FC_E="$(fc_git rev-parse HEAD)"
awk 'BEGIN { for (i = 0; i < 9000; i++) printf "a"; printf "\nclean tail\n" }' > "$FC_REPO/core/latenul.md"
if ! { fc_git add core/latenul.md && fc_git commit -q -m nul-remove; }; then
  echo "FATAL: could not commit the remove-NUL fixture"; exit 1
fi
FC_R="$(fc_git rev-parse HEAD)"
check "AL control — a clean line added after a NUL line is LISTED" \
  "$(added_lines_verdict "$FC_REPO" "$FC_N" "$FC_E" core/latenul.md "$TMP/nul-append")" "LISTED"
check "AL control — removing the NUL line is LISTED" \
  "$(added_lines_verdict "$FC_REPO" "$FC_E" "$FC_R" core/latenul.md "$TMP/nul-remove")" "LISTED"
check "run block — removing a line that carries a NUL passes" \
  "$(gate_run "$RUN_BLOCK" "$FC_E" "$FC_R" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"

# An added line whose own content starts with "++" shows in the diff as "+++…", the
# same prefix as the file header. Only the header — before the first hunk — is
# skipped; inside a hunk the line is extracted under its own line number.
printf 'intro\n++ Authored by %s.\nline three\n' "$FIXTURE_HANDLE" > "$FC_REPO/core/plusplus.md"
if ! { fc_git add core/plusplus.md && fc_git commit -q -m plusplus; }; then
  echo "FATAL: could not commit the plus-plus fixture"; exit 1
fi
FC_PP="$(fc_git rev-parse HEAD)"
check "AL sensitivity — an added line starting with ++ is extracted, under its own line number" \
  "$(added_lines_verdict "$FC_REPO" "$FC_R" "$FC_PP" core/plusplus.md "$TMP/pp-added" >/dev/null; sed -n '2p' "$TMP/pp-added")" "2:++ Authored by $FIXTURE_HANDLE."
check "AL control — …and every added line is extracted" "$(wc -l < "$TMP/pp-added" | tr -d ' ')" "3"
check "run block — the handle on an added line starting with ++ fails" \
  "$(gate_run "$RUN_BLOCK" "$FC_R" "$FC_PP" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"

# A per-path diff with two sections: a directory replaced by a file of the same
# name. The second section's "+++ /dev/null" header is a header again, not an added
# line, so only the new file's own lines are extracted.
mkdir -p "$FC_REPO/core/dd"
printf 'nothing to see\n' > "$FC_REPO/core/dd/inner.md"
if ! { fc_git add core/dd/inner.md && fc_git commit -q -m dd-dir; }; then
  echo "FATAL: could not commit the directory fixture"; exit 1
fi
FC_DD1="$(fc_git rev-parse HEAD)"
if ! fc_git rm -q -r core/dd; then
  echo "FATAL: could not remove the fixture directory"; exit 1
fi
printf 'a file now\n' > "$FC_REPO/core/dd"
if ! { fc_git add core/dd && fc_git commit -q -m dd-file; }; then
  echo "FATAL: could not commit the directory-to-file fixture"; exit 1
fi
FC_DD2="$(fc_git rev-parse HEAD)"
check "…control — that path's diff holds two sections" \
  "$(fc_git diff --unified=0 "$FC_DD1"..."$FC_DD2" -- core/dd | grep -c '^diff --git ')" "2"
check "AL control — a second section's header is not extracted as an added line" \
  "$(added_lines_verdict "$FC_REPO" "$FC_DD1" "$FC_DD2" core/dd "$TMP/dd-added" >/dev/null; cat "$TMP/dd-added")" "1:a file now"

# The NUL check's own failure branches, each forced by shadowing one command with a
# shell function inside a subshell, over a range that otherwise reads LISTED. The
# mktemp shadow counts its calls in a file (each $(mktemp) runs in a subshell) and
# fails only the Nth; `command mktemp` reaches the real one.
al_shadow_mktemp() {   # <zero-based call to fail>
  ( MKC="$TMP/mktemp-count"; printf '0\n' > "$MKC"; FAILAT="$1"
    mktemp() { _c="$(cat "$MKC")"; printf '%s\n' "$((_c + 1))" > "$MKC"
               [ "$_c" -eq "$FAILAT" ] && return 1; command mktemp "$@"; }
    added_lines_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" core/a.md "$TMP/al-shadow" )
}
check "AL sensitivity — the NUL check's first scratch file failing is UNEVALUABLE"  "$(al_shadow_mktemp 1)" "UNEVALUABLE"
check "AL sensitivity — the NUL check's second scratch file failing is UNEVALUABLE" "$(al_shadow_mktemp 2)" "UNEVALUABLE"
check "…control — with no failure the shadowed run is LISTED" "$(al_shadow_mktemp 99)" "LISTED"
check "AL sensitivity — the added-line filter failing is UNEVALUABLE" \
  "$( grep() { return 2; }; added_lines_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" core/a.md "$TMP/al-shadow" )" "UNEVALUABLE"
check "AL sensitivity — the NUL strip failing is UNEVALUABLE" \
  "$( tr() { return 1; }; added_lines_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" core/a.md "$TMP/al-shadow" )" "UNEVALUABLE"
check "AL sensitivity — a comparison that cannot run is UNEVALUABLE" \
  "$( cmp() { return 2; }; added_lines_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" core/a.md "$TMP/al-shadow" )" "UNEVALUABLE"
check "…control — a comparison shadowed to differ reads BINARY" \
  "$( cmp() { return 1; }; added_lines_verdict "$FC_REPO" "$FC_BASE" "$FC_HEAD" core/a.md "$TMP/al-shadow" )" "BINARY"

# A per-file diff that fails while the listing succeeds: the listing compares trees,
# the per-file diff reads blobs, so a commit whose new blob is then removed from the
# fixture's object store lists fine and cannot be diffed. This is the last use of
# the fixture repository.
printf 'line\n' > "$FC_REPO/core/broken.md"
if ! { fc_git add core/broken.md && fc_git commit -q -m broken; }; then
  echo "FATAL: could not commit the broken-blob fixture"; exit 1
fi
FC_K="$(fc_git rev-parse HEAD)"
FC_K_BLOB="$(fc_git rev-parse "$FC_K:core/broken.md")"
FC_K_OBJ="$FC_REPO/.git/objects/$(printf '%s' "$FC_K_BLOB" | cut -c1-2)/$(printf '%s' "$FC_K_BLOB" | cut -c3-)"
check "…control — the broken-blob fixture's object is loose" "$([ -f "$FC_K_OBJ" ] && echo loose || echo missing)" "loose"
rm -f "$FC_K_OBJ"
check "…control — the blob is gone from the object store" \
  "$(fc_git cat-file -e "$FC_K_BLOB" 2>/dev/null && echo present || echo gone)" "gone"
check "…control — the listing still succeeds over that commit" \
  "$(changed_files_verdict "$FC_REPO" "$FC_DD2" "$FC_K" "$TMP/broken-list")" "LISTED"
check "…control — the per-file diff over it is UNEVALUABLE" \
  "$(added_lines_verdict "$FC_REPO" "$FC_DD2" "$FC_K" core/broken.md "$TMP/broken-added" 2>/dev/null)" "UNEVALUABLE"
check "run block — a per-file diff that fails fails closed" \
  "$(gate_run "$RUN_BLOCK" "$FC_DD2" "$FC_K" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "1"
# Control: the replay reads the block it is given. A copy whose first line after
# `set -euo pipefail` exits 0 must pass the case the real block fails, and a copy
# whose quoted-name arm continues instead of failing must pass the quoted case.
RB_EXIT0="$TMP/gate1-run-exit0.sh"
awk '{ print } /^set -euo pipefail$/ && !d { print "exit 0"; d = 1 }' "$RUN_BLOCK" > "$RB_EXIT0"
check "…control — a block that exits 0 at once passes the handle case" \
  "$(gate_run "$RB_EXIT0" "$FC_BASE" "$FC_HEAD" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"
RB_CONT="$TMP/gate1-run-continue.sh"
awk '{ print } /^  UNEVALUABLE[)]$/ && !d { print "    exit 0"; d = 1 }' "$RUN_BLOCK" > "$RB_CONT"
check "…control — the edited copy differs from the block" "$(cmp -s "$RUN_BLOCK" "$RB_CONT" && echo same || echo differs)" "differs"
check "…control — a listing arm edited to exit 0 passes the quoted case" \
  "$(gate_run "$RB_CONT" "$FC_U" "$FC_Q" "$FIXTURE_HANDLE" User "$RB_IDENTITY")" "0"

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

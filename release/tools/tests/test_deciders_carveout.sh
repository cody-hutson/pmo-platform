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
# It is never read as "nothing found". See the fail-closed section near the end. The
# section after it does the same for the six other repo-integrity jobs that source the
# library's fail-closed reads, and checks each job's wiring to them.
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
# disagreement. Agreement is asserted on the shared subject only. The two gates also
# resolve the handle from different sources by deliberate design (the lint from the
# repository owner, the gate from the run's actor), so on a bot-authored PR the gate's
# operator dimension is skipped and the two correctly differ; this suite drives a
# synthetic handle directly and so is unaffected.
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
for fn in esc_lines adr_deciders_carveout_suppresses depersonalization_line_verdict; do
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

echo
echo "--- Fail-closed evaluation: the other repo-integrity jobs ---"
# Six more jobs in the same workflow read the change the same way, and they swallowed
# the same failures: dead-file-ref, draft-file, governance-file-map, projects-casing,
# adr-durability and sigpipe-idiom. They now source this library too. They use
# changed_files_verdict (with pathspecs) and added_lines_verdict from above, plus
# added_files_verdict, file_status_verdict and ere_line_verdict, and report a
# could-not-evaluate run through report_unevaluable. The arms below follow the same
# pairing as the section above: a SENSITIVITY arm that forces could-not-evaluate,
# and a CONTROL arm on the nearest legitimate "nothing found".
for fn in added_files_verdict file_status_verdict ere_line_verdict report_unevaluable; do
  if ! declare -F "$fn" >/dev/null; then
    echo "FATAL: $LIB did not define $fn"; exit 1
  fi
done

# A second fixture repository, because these reads need shapes the first one lacks:
# a non-markdown change (so a pathspec has something to exclude), an ADR path, an
# ADDED file and an unchanged one. Same hermetic setup as fc_git above.
OJ_REPO="$TMP/other-jobs-repo"
OJ_OUT="$TMP/other-jobs-out"
oj_git() {
  git -C "$OJ_REPO" -c user.name="$FIXTURE_NAME" -c user.email="$FIXTURE_EMAIL" \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"
}
mkdir -p "$OJ_REPO/core/ADRs" "$OJ_REPO/tools" "$OJ_REPO/docs/drafts"
if ! git -C "$OJ_REPO" init -q >/dev/null 2>&1; then
  echo "FATAL: could not initialise the other-jobs fixture repository"; exit 1
fi
printf 'line one\n' > "$OJ_REPO/core/a.md"
printf 'kept as is\n' > "$OJ_REPO/core/keep.md"
printf 'adr one\n' > "$OJ_REPO/core/ADRs/ADR-001-fixture.md"
printf 'echo one\n' > "$OJ_REPO/tools/run.sh"
if ! { oj_git add core tools && oj_git commit -q -m base; }; then
  echo "FATAL: could not commit the other-jobs fixture base"; exit 1
fi
OJ_BASE="$(oj_git rev-parse HEAD)"
printf 'line one\nline two\n' > "$OJ_REPO/core/a.md"
printf 'adr one\nadr two\n' > "$OJ_REPO/core/ADRs/ADR-001-fixture.md"
printf 'echo one\necho two\n' > "$OJ_REPO/tools/run.sh"
printf 'a draft\n' > "$OJ_REPO/docs/drafts/new.md"
if ! { oj_git add core tools docs && oj_git commit -q -m head; }; then
  echo "FATAL: could not commit the other-jobs fixture head"; exit 1
fi
OJ_HEAD="$(oj_git rev-parse HEAD)"

# --- changed_files_verdict with pathspecs -------------------------------------------
printf 'stale\n' > "$OJ_OUT"
v="$(changed_files_verdict "$OJ_REPO" "$FC_ABSENT" "$OJ_HEAD" "$OJ_OUT" '*.md' 2>/dev/null)"
check "CF+pathspec sensitivity — a missing base is UNEVALUABLE with a pathspec too" "$v" "UNEVALUABLE"
check "CF+pathspec sensitivity — the out-file is truncated" "$(wc -l < "$OJ_OUT" | tr -d ' ')" "0"
v="$(changed_files_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" "$OJ_OUT")"
check "CF control — no pathspec lists every changed path" "$(paste -s -d , "$OJ_OUT")" "core/ADRs/ADR-001-fixture.md,core/a.md,docs/drafts/new.md,tools/run.sh"
v="$(changed_files_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" "$OJ_OUT" '*.md')"
check "CF+pathspec control — '*.md' is LISTED" "$v" "LISTED"
check "CF+pathspec control — '*.md' drops the shell file and keeps nested markdown" "$(paste -s -d , "$OJ_OUT")" "core/ADRs/ADR-001-fixture.md,core/a.md,docs/drafts/new.md"
v="$(changed_files_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" "$OJ_OUT" 'core/ADRs/ADR-*.md' 'release/ADRs/ADR-*.md')"
check "CF+pathspec control — two ADR pathspecs list only the ADR" "$v:$(paste -s -d , "$OJ_OUT")" "LISTED:core/ADRs/ADR-001-fixture.md"
printf 'stale\n' > "$OJ_OUT"
v="$(changed_files_verdict "$OJ_REPO" "$OJ_HEAD" "$OJ_HEAD" "$OJ_OUT" '*.md')"
check "CF+pathspec control — an empty but successful diff is LISTED and empty" "$v:$(wc -l < "$OJ_OUT" | tr -d ' ')" "LISTED:0"

# --- added_files_verdict --------------------------------------------------------------
printf 'stale\n' > "$OJ_OUT"
v="$(added_files_verdict "$OJ_REPO" "$FC_ABSENT" "$OJ_HEAD" "$OJ_OUT" 2>/dev/null)"
check "AF sensitivity — a base commit git does not have is UNEVALUABLE, not 'nothing added'" "$v" "UNEVALUABLE"
check "AF sensitivity — the out-file is truncated" "$(wc -l < "$OJ_OUT" | tr -d ' ')" "0"
v="$(added_files_verdict "$OJ_REPO" "" "$OJ_HEAD" "$OJ_OUT")"
check "AF sensitivity — an empty base revision is UNEVALUABLE" "$v" "UNEVALUABLE"
v="$(added_files_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" "$OJ_OUT")"
check "AF control — a real range is LISTED" "$v" "LISTED"
check "AF control — only the ADDED file is listed, not the modified ones" "$(paste -s -d , "$OJ_OUT")" "docs/drafts/new.md"
printf 'stale\n' > "$OJ_OUT"
v="$(added_files_verdict "$OJ_REPO" "$OJ_HEAD" "$OJ_HEAD" "$OJ_OUT")"
check "AF control — an empty but successful diff is LISTED and empty" "$v:$(wc -l < "$OJ_OUT" | tr -d ' ')" "LISTED:0"

# --- file_status_verdict --------------------------------------------------------------
TAB="$(printf '\t')"
printf 'stale\n' > "$OJ_OUT"
v="$(file_status_verdict "$OJ_REPO" "$FC_ABSENT" "$OJ_HEAD" tools/run.sh "$OJ_OUT" 2>/dev/null)"
check "FS sensitivity — a base commit git does not have is UNEVALUABLE, not 'unchanged'" "$v" "UNEVALUABLE"
check "FS sensitivity — the out-file is truncated" "$(wc -l < "$OJ_OUT" | tr -d ' ')" "0"
v="$(file_status_verdict "$OJ_REPO" "$OJ_BASE" "" tools/run.sh "$OJ_OUT")"
check "FS sensitivity — an empty head revision is UNEVALUABLE" "$v" "UNEVALUABLE"
v="$(file_status_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" tools/run.sh "$OJ_OUT")"
check "FS control — a modified file is LISTED with status M" "$v:$(cat "$OJ_OUT")" "LISTED:M${TAB}tools/run.sh"
v="$(file_status_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" docs/drafts/new.md "$OJ_OUT")"
check "FS control — an added file is LISTED with status A" "$v:$(cat "$OJ_OUT")" "LISTED:A${TAB}docs/drafts/new.md"
printf 'stale\n' > "$OJ_OUT"
v="$(file_status_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" core/keep.md "$OJ_OUT")"
check "FS control — an unchanged file is LISTED and empty, not UNEVALUABLE" "$v:$(wc -l < "$OJ_OUT" | tr -d ' ')" "LISTED:0"

# --- ere_line_verdict -----------------------------------------------------------------
v="$(ere_line_verdict '(' 'any line' 2>/dev/null)"
check "EL sensitivity — a grep exit 2 (malformed ERE) is UNEVALUABLE, not NOMATCH" "$v" "UNEVALUABLE"
# Non-vacuity for the arm above: this ERE really does make grep exit 2 here.
grep -qE '(' <<<'any line' 2>/dev/null
check "EL control — this grep exits 2 on the malformed ERE" "$?" "2"
v="$(ere_line_verdict '' 'any line')"
check "EL sensitivity — an empty ERE (it matches every line) is UNEVALUABLE, not MATCH" "$v" "UNEVALUABLE"
v="$(ere_line_verdict '(^|[^A-Za-z0-9._/])Projects/' 'see Projects/x for it')"
check "EL control — a matching line is MATCH" "$v" "MATCH"
v="$(ere_line_verdict '(^|[^A-Za-z0-9._/])Projects/' 'see projects/x for it')"
check "EL control — a non-matching line (grep exit 1) is NOMATCH" "$v" "NOMATCH"
v="$(ere_line_verdict 'Projects/' '')"
check "EL control — an empty line is NOMATCH for an ERE that cannot match empty" "$v" "NOMATCH"

fc_opts "AF sensitivity (missing base)" UNEVALUABLE added_files_verdict "$OJ_REPO" "$FC_ABSENT" "$OJ_HEAD" "$OJ_OUT"
fc_opts "AF control (real range)"       LISTED      added_files_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" "$OJ_OUT"
fc_opts "FS sensitivity (missing base)" UNEVALUABLE file_status_verdict "$OJ_REPO" "$FC_ABSENT" "$OJ_HEAD" tools/run.sh "$OJ_OUT"
fc_opts "FS control (unchanged file)"   LISTED      file_status_verdict "$OJ_REPO" "$OJ_BASE" "$OJ_HEAD" core/keep.md "$OJ_OUT"
fc_opts "EL sensitivity (grep exit 2)"  UNEVALUABLE ere_line_verdict '(' 'any line'
fc_opts "EL control (grep exit 1)"      NOMATCH     ere_line_verdict 'Projects/' 'no capital here'

# --- report_unevaluable ---------------------------------------------------------------
OJ_SUMMARY="$TMP/other-jobs-summary"
: > "$OJ_SUMMARY"
OJ_REPORT="$(report_unevaluable "Fixture gate" "$OJ_SUMMARY" "git could not list the changed files")"
OJ_RC=$?
check "report_unevaluable returns 0 (the caller owns the exit)" "$OJ_RC" "0"
case "$OJ_REPORT" in
  *"::error::Fixture gate could not evaluate: git could not list the changed files"*) ok "report_unevaluable emits the ::error:: annotation naming the gate and the read" ;;
  *) bad "report_unevaluable did not emit the expected ::error:: annotation" ;;
esac
check "report_unevaluable appends its heading to the summary file" "$(grep -c '^## :x: Fixture gate could not evaluate$' "$OJ_SUMMARY")" "1"

# --- Structural binding: each job reads through the library and swallows nothing ----
# Per job: it sources the library on an executable line; it dispatches the expected
# number of verdicts; every UNEVALUABLE arm and every catch-all arm reports and exits
# 1; and no executable line swallows a git or grep failure. The sigpipe-idiom job
# keeps two `|| true` reads on purpose (its shebang read and its marker walk's line
# read: a failed read there skips an exemption, not a finding), and only those two.
# Each job is extracted from its key to the next top-level job key, as Gate 1 is.
SOURCE_RE='^[[:space:]]*(\.|source)[[:space:]]+"[^"]*release/tools/lib/deciders-carveout\.sh"'
DISPATCH_RE='^[[:space:]]*case "\$\((changed_files|added_files|added_lines|file_status|ere_line)_verdict[[:space:]]'
UNEV_ARM_RE='^[[:space:]]*UNEVALUABLE\)'
UNEV_OK_RE='^[[:space:]]*UNEVALUABLE\) report_unevaluable "\$GATE" .*; exit 1 ;;$'
STAR_OK_RE='^[[:space:]]*\*\) report_unevaluable "\$GATE" .*; exit 1 ;;$'
ALLOWED_SWALLOWS="$TMP/allowed-swallows"
printf '%s\n' 'IFS= read -r SHEBANG < "$f" 2>/dev/null || true' 'PREV="$(sed -n "${K}p" "$f" 2>/dev/null || true)"' > "$ALLOWED_SWALLOWS"
# job-key | job name | case dispatches | ere_line dispatches | allowed swallows
OTHER_JOBS='
dead-file-ref|Dead-file-reference gate|1|0|0
draft-file|Draft-file gate|2|1|0
governance-file-map|Governance-file-map cross-check gate|1|0|0
projects-casing|Projects/ casing canonicalization gate|3|1|0
adr-durability|ADR durability gate|1|0|0
sigpipe-idiom|SIGPIPE-idiom gate|4|1|2
'
while IFS='|' read -r oj_key oj_name oj_cases oj_ere oj_allowed; do
  [ -z "$oj_key" ] && continue
  OJ_BLOCK="$TMP/job-$oj_key"
  awk -v key="  ${oj_key}:" '$0 == key { on = 1; print; next }
       on && /^  [A-Za-z0-9_-]+:$/ { on = 0 }
       on' "$WORKFLOW" > "$OJ_BLOCK"
  check "[$oj_key] extraction is the job (its name line, once)" "$(grep -cF "name: $oj_name" "$OJ_BLOCK")" "1"
  check "[$oj_key] sources the shared library on an executable line" "$(grep -cE "$SOURCE_RE" "$OJ_BLOCK")" "1"
  check "[$oj_key] dispatches $oj_cases verdict(s) through a case" "$(grep -cE "$DISPATCH_RE" "$OJ_BLOCK")" "$oj_cases"
  oj_unev_arms="$(grep -cE "$UNEV_ARM_RE" "$OJ_BLOCK")"
  check "[$oj_key] has an UNEVALUABLE arm for every read verdict" "$oj_unev_arms" "$((oj_cases - oj_ere))"
  check "[$oj_key] every UNEVALUABLE arm reports and exits 1" "$(grep -cE "$UNEV_OK_RE" "$OJ_BLOCK")" "$oj_unev_arms"
  check "[$oj_key] every verdict's catch-all arm reports and exits 1" "$(grep -cE "$STAR_OK_RE" "$OJ_BLOCK")" "$oj_cases"
  grep -E "$SWALLOW_RE" "$OJ_BLOCK" > "$TMP/swallows-$oj_key"
  check "[$oj_key] no executable line swallows a non-zero exit, except the allowed reads" "$(grep -cvF -f "$ALLOWED_SWALLOWS" "$TMP/swallows-$oj_key")" "0"
  check "[$oj_key] allowed swallow reads present" "$(grep -cF -f "$ALLOWED_SWALLOWS" "$TMP/swallows-$oj_key")" "$oj_allowed"
done <<EOF
$OTHER_JOBS
EOF

# The per-line detection tests must go through rx, never straight to grep, in the
# three jobs that have them. Each shape below is the one this change removed.
OJ_DRAFT="$TMP/job-draft-file"; OJ_CASING="$TMP/job-projects-casing"; OJ_SIGPIPE="$TMP/job-sigpipe-idiom"
check "[draft-file] no path-shape test reads grep directly" "$(grep -cE '^[[:space:]]*([^#[:space:]].*)?grep -qE "\$(DRAFT_SEG|GOVERNED|TOPLEVEL)"' "$OJ_DRAFT")" "0"
check "[projects-casing] no casing test reads grep directly" "$(grep -cE '^[[:space:]]*([^#[:space:]].*)?grep -qE "\$(CASING_RE|SCHEMA_EXEMPT)"' "$OJ_CASING")" "0"
check "[sigpipe-idiom] no idiom test reads grep directly" "$(grep -cE '^[[:space:]]*([^#[:space:]].*)?grep -qE "\$IDIOM_' "$OJ_SIGPIPE")" "0"
check "[sigpipe-idiom] the T1 program detector goes through rx" "$(grep -cF "|| rx '(^|[^[:alnum:]_./-])(eval|" "$OJ_SIGPIPE")" "1"
check "[sigpipe-idiom] the continuation-join read has its status read" "$(grep -cF 'if ! PREVJ="$(sed -n "$((LN - 1))p" "$f")"; then' "$OJ_SIGPIPE")" "1"
# Sensitivity for the direct-grep assertions: a direct grep on each class of
# detection constant is caught, and the same names in a comment are not. The
# fixture uses the here-string form of each removed test rather than the piped
# form, because the piped form is the very shape the sigpipe-idiom job flags in a
# shell file like this one.
OJ_GREP_FIXTURE="$TMP/direct-grep-fixture"
cat > "$OJ_GREP_FIXTURE" <<'EOF'
            if grep -qE "$DRAFT_SEG" <<<"$f"; then
              grep -qE "$CASING_RE" <<<"$line" || continue
            if grep -qE "$IDIOM_Q" <<<"$_s"; then return 0; fi
          # a comment naming grep -qE "$IDIOM_Q" and grep -qE "$CASING_RE" is not a call
EOF
check "direct-grep detectors catch a direct grep in each job and skip the comment" \
  "$(grep -cE '^[[:space:]]*([^#[:space:]].*)?grep -qE "\$(DRAFT_SEG|GOVERNED|TOPLEVEL|CASING_RE|SCHEMA_EXEMPT|IDIOM_)' "$OJ_GREP_FIXTURE")" "3"

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

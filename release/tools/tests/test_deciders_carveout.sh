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
# shellcheck source=/dev/null
. "$LIB"
for fn in esc_lines adr_deciders_carveout_suppresses depersonalization_line_verdict; do
  if ! type "$fn" 2>/dev/null | head -1 | grep -q 'function'; then
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

# esc_lines behaviour preservation — the helper was MOVED, not rewritten, so a literal
# carrying regex metacharacters must still be escaped rather than interpreted.
meta="$(esc_lines 'a.b*c' | tr -d '\n')"
check "esc_lines escapes regex metacharacters" "$meta" '\ba\.b\*c\b'
blank="$(esc_lines "$(printf '\n   \n')" | wc -l | tr -d ' ')"
check "esc_lines drops blank/whitespace-only lines" "$blank" "0"

echo
echo "--- Structural binding: the workflow uses this library, not a private copy ---"
if grep -q 'release/tools/lib/deciders-carveout\.sh' "$WORKFLOW"; then
  ok "repo-integrity.yml sources the shared library"
else
  bad "repo-integrity.yml no longer sources release/tools/lib/deciders-carveout.sh"
fi
if grep -q 'depersonalization_line_verdict' "$WORKFLOW"; then
  ok "repo-integrity.yml calls depersonalization_line_verdict"
else
  bad "repo-integrity.yml no longer calls depersonalization_line_verdict"
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
if grep -qE 'esc_lines[[:space:]]+"\$HANDLE_LITERAL"[[:space:]]*>>[[:space:]]*"\$NOT_CARVED_FILE"' "$WORKFLOW"; then
  ok "repo-integrity.yml POPULATES the un-carved set (esc_lines \$HANDLE_LITERAL >> \$NOT_CARVED_FILE)"
else
  bad "repo-integrity.yml no longer writes \$HANDLE_LITERAL into \$NOT_CARVED_FILE — the un-carved set is empty, so the gate silently reverts to whole-line suppression on deciders: lines"
fi
# Non-vacuity control for the three greps above: a token that must NOT be present. If
# this arm ever passes, the grep-based binding assertions are matching nothing real.
if grep -q 'depersonalization_line_verdict_THAT_DOES_NOT_EXIST' "$WORKFLOW"; then
  bad "binding-assertion control matched a nonexistent token — the greps prove nothing"
else
  ok "binding-assertion control — a nonexistent token is absent (greps are discriminating)"
fi
# ... and a construction-shaped control, because the arm above is a NEW pattern and a
# typo in it would pass silently as a nonexistent-token miss. A redirect into a file
# the workflow does not have must NOT match.
if grep -qE 'esc_lines[[:space:]]+"\$HANDLE_LITERAL"[[:space:]]*>>[[:space:]]*"\$NO_SUCH_CARVED_FILE"' "$WORKFLOW"; then
  bad "construction-assertion control matched a nonexistent redirect — the construction grep proves nothing"
else
  ok "construction-assertion control — a nonexistent redirect target is absent (the construction grep is shaped, not loose)"
fi

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

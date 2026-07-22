#!/usr/bin/env bash
# compute-close-class-telemetry.sh — Close-class telemetry for a release.
# Per release/references/standards/close-class-telemetry.md.
# Sibling to compute-release-velocity.sh — same form factor, same exit-code contract.
#
# Emits the **Close-Class-Telemetry:** field content for the visible-H4 Deployment
# Log block in RELEASE_LOG.md. The field is a Stage-13 field (the registers,
# carry-forward closure, and close-gate are authoritative only at close),
# forward-only / grandfathered — see the standard § Cutover.
#
# MECHANICAL-SOURCE (filesystem registers + gh state), NOT the event log — this is
# the deliberate boundary distinguishing it from the cycle-time / DORA read-models
# (the standard § 8). It computes:
#   Indicator 1 retro-conformance     : conformant canonical-form section markers
#                                        present / expected, grepping the operator-
#                                        instance retro register (verbatim Kerth +
#                                        PMBOK 7 headers per release-learnings-
#                                        register-template.md).
#   Indicator 2 lessons-population     : populated lessons/actions rows / template-
#                                        prompted rows in the lessons register.
#   Indicator 3 carry-forward-closure  : closed `status: deferred` issues / raised,
#                                        over the milestone (per deferred-item-
#                                        tracking.md).
#   Indicator 4 pattern-emergence      : POINTER ONLY — deferred-to-aggregate; the
#                                        rate is owned by synthesize-release-
#                                        learnings.sh and never recomputed here.
#   Indicator 5 rollup-presence        : present|absent — the release-level Outcome:
#                                        field + Stage-13 A7.1 rollup PRESENCE (the
#                                        rate is DEFERRED, denominator undefined).
#   Indicator 6 evidence-preservation  : <P>/<S> (<ratio>) — phase-completion evidence
#                                        preservation read-model over the hub-spoke
#                                        sub-task `gh` state (NO net-new store): CLOSED
#                                        stage sub-tasks carrying >=1 trusted-authored
#                                        output/skip-closure comment (P) / MEASURABLE
#                                        stage sub-tasks scaffolded for the release (S —
#                                        terminal stages 12/13 EXCLUDED, since capture
#                                        happens during them; see count_subtask_evidence).
#                                        The single Stage-13 G-CL4 close-gate boolean is
#                                        RETAINED as evidence-close-gate (pass|fail|N/A).
#                                        Mechanical gh-state read — honors the § 8
#                                        boundary (NOT the event log).
#
# Ratio rounding mode is round-half-up, taken by reference from
# bundle-composition-doctrine.md § 3 Step 5 (the single definitional home) — NOT
# re-derived here.
#
# Usage:
#   ./compute-close-class-telemetry.sh <version> --milestone <N> [--retro <path>] [--lessons <path>]
#                                               # the **Close-Class-Telemetry:** field value
#   ./compute-close-class-telemetry.sh <version> --milestone <N> --json
#                                               # machine detail: JSON of all indicators
#   ./compute-close-class-telemetry.sh --self-test   # validate logic against synthetic input
#   ./compute-close-class-telemetry.sh --help        # this help text
#
# Inputs:
#   <version>          release version key (e.g. v1.00) — for the field label + register resolution.
#   --milestone <N>    GitHub milestone NUMBER whose `status: deferred` membership is the
#                      carry-forward-closure population (Indicator 3).
#   --retro <path>     OPTIONAL explicit path to the version's retro register (Indicator 1).
#                      When omitted, resolves the operator-instance register path by convention;
#                      absent register -> Indicator 1 N/A.
#   --lessons <path>   OPTIONAL explicit path to the version's lessons register (Indicator 2).
#                      Defaults to --retro's path (the template carries both blocks in one file);
#                      absent -> Indicator 2 N/A.
#   --outcome-present {0|1}   OPTIONAL Indicator-5 presence override (the Stage 13 spoke knows
#                      whether the Outcome: field + A7.1 rollup are present). Default: absent.
#   --close-gate {pass|fail|na}  OPTIONAL Indicator-6 G-CL4 close-gate verdict — the
#                      RETAINED secondary sub-signal alongside the phase-evidence rate
#                      (the rate is primary; the boolean loses no signal). Default: na.
#
# Cutover: applies to releases entering Stage 13 strictly AFTER this field's
# introducing-release merge SHA. The introducing release itself is exempt. This
# script does not gate by version — the caller (Stage 13 spoke) honors cutover.
#
# Exit codes:
#   0 = success (an indicator may legitimately produce N/A — no register, no
#       carry-forwards, no stage sub-tasks; or the Indicator-4 pointer / I5 presence /
#       I6 evidence-preservation rate + retained close-gate boolean)
#   1 = invalid args / required input missing / gh unavailable when carry-forward
#       closure is requested
#   2 = malformed source (a register that exists but cannot be parsed, or a
#       milestone that does not resolve — source-integrity violation; escalate)

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
# gh is resolved by absolute discovery below (not on the pinned PATH).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,72p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# Resolve gh off the pinned PATH (commonly /opt/homebrew/bin or /usr/local/bin).
# Empty when not installed — callers that need it (Indicator 3) fail with a clear
# message; --self-test never needs it.
find_gh() {
  local c
  for c in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh "$HOME/.local/bin/gh"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  command -v gh 2>/dev/null || true
}

# ─── The canonical-form section markers (Indicator 1) ────────────────────────
# Verbatim headers from release-learnings-register-template.md. The template
# mandates these be kept verbatim precisely so this read-model can grep them.
# Kept as exact line-anchored strings (a marker counts as present iff a line
# EQUALS it, after trimming — not a substring, to avoid false positives).
CANONICAL_MARKERS=(
  "## 1. Kerth Retrospective (full ceremony)"
  "### 1.1 Prime Directive (recite before reflecting)"
  "### 1.2 Three-question framework"
  "### 1.3 Ritual of closure"
  "## 2. PMBOK 7 Lessons-Learned (full ceremony)"
  "### 2.1 Situation"
  "### 2.2 Outcome"
  "### 2.3 Lessons"
  "### 2.4 Next-cycle Actions"
  "## 3. Triple Linkage (records the COEXIST relationship)"
)
EXPECTED_MARKERS=${#CANONICAL_MARKERS[@]}   # 10 canonical-form markers

# ─── round-half-up ratio (the canonical mode, by reference) ──────────────────
# Compute numerator/denominator to 2 decimals using round-half-up at the 2nd
# decimal. Pure-integer arithmetic (no float drift). Echoes "0.00".."1.00"+ ;
# echoes "N/A" when denominator == 0.
ratio_round_half_up() {
  local num="$1" den="$2"
  if [[ "$den" -eq 0 ]]; then echo "N/A"; return 0; fi
  local hundredths=$(( (num * 10000 + den * 50) / (den * 100) ))
  /usr/bin/printf '%d.%02d\n' "$(( hundredths / 100 ))" "$(( hundredths % 100 ))"
}

# ─── Indicator 1: retro canonical-form conformance ───────────────────────────
# Count how many of the CANONICAL_MARKERS appear as exact (trimmed) lines in the
# retro file. Echoes "<present> <expected>" on stdout. Caller forms the ratio.
count_retro_conformance() {
  local file="$1"
  local present=0 m
  for m in "${CANONICAL_MARKERS[@]}"; do
    # exact-line match (trim trailing CR/space). grep -Fx = fixed-string, whole-line.
    if /usr/bin/grep -Fxq "$m" "$file" 2>/dev/null; then
      present=$(( present + 1 ))
    fi
  done
  echo "$present $EXPECTED_MARKERS"
}

# ─── Indicator 2: lessons-register population ────────────────────────────────
# A template-prompted row is a markdown table row whose first cell is an L<n> or
# A<n> id (the template's `| L1 | ... |` Lessons rows + `| A1 | ... |` Actions
# rows). It is POPULATED iff no content cell is still the verbatim `<…>`
# placeholder (the template uses the U+2026 horizontal-ellipsis placeholder).
# Echoes "<populated> <prompted>".
count_lessons_population() {
  local file="$1"
  /usr/bin/python3 - "$file" <<'PY'
import sys, re
path = sys.argv[1]
prompted = 0
populated = 0
placeholder = "…"  # the template's <…> ellipsis placeholder
try:
    with open(path, encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s.startswith("|"):
                continue
            cells = [c.strip() for c in s.strip("|").split("|")]
            if not cells:
                continue
            first = cells[0]
            # template-prompted row: first cell is an L<n> or A<n> id
            if re.fullmatch(r"[LA]\d+", first):
                prompted += 1
                # populated iff NO content cell still carries the <…> placeholder
                content = cells[1:]
                if content and not any(placeholder in c for c in content):
                    populated += 1
except (OSError, UnicodeDecodeError) as e:
    print(f"lessons register unreadable: {e}", file=sys.stderr)
    sys.exit(2)
print(f"{populated} {prompted}")
PY
}

# ─── Indicator 6: phase-completion evidence preservation (read-model over sub-task gh state) ─
# Bounded read-model, NO net-new store. The per-stage hub-spoke sub-task surface IS the
# evidence trail: the hub scaffolds one `sub-task`-labelled issue per release-execution stage
# and closes it ONLY after consuming its output comment (skipped stages carry a skip-closure
# comment). A CLOSED sub-task carrying >=1 trusted-authored comment = phase-completion evidence
# preserved.
#   Denominator S = MEASURABLE stage sub-tasks scaffolded for the release (milestone +
#                   label:sub-task), EXCLUDING the terminal stages 12 (Execute) and 13 (Close).
#   Numerator   P = those CLOSED with >=1 trusted-authored (output / skip-closure) comment.
#
# TERMINAL-STAGE EXCLUSION (why S is not simply the scaffolded count). The field's mandated
# capture moment is the Stage-13 Phase B chore PR (close-class-telemetry.md § 3.2) — i.e.
# DURING stage 13, with stage 12/13 evidence not yet terminal. Counting stages 12/13 in S made
# the published rate a function of WHEN it was read rather than of how well evidence was
# preserved: three readings of one live milestone moved 0.46 -> 0.61 -> 0.75 with the numerator
# equal to the closed count every time (100% of the variance was measurement timing). Excluding
# the two terminal stages makes the rate measure the thing its name claims. Detection is by the
# sub-task title's `Stage <N>` prefix; a title that does not parse to a stage number is RETAINED
# (fail-safe — never shrink the denominator on an unrecognized title).
#
# "Trusted-authored" = comment authorAssociation in {OWNER, MEMBER, COLLABORATOR, CONTRIBUTOR}
# (guards a public drive-by comment on a CLOSED sub-task from counting as evidence); when the
# payload carries no authorAssociation, or `comments` is an integer count, falls back to
# comment-presence (>=1). Echoes "<P> <S> <X>" (X = terminal-stage sub-tasks excluded) from a
# JSON array of {number,title,state,comments} (both the gh-issue-list array shape and an
# integer-count shape are accepted). Exit 2 on unparseable source (integrity violation).
count_subtask_evidence() {
  local json="$1"
  /usr/bin/python3 - "$json" <<'PY'
import json, re, sys
TRUSTED = {"OWNER", "MEMBER", "COLLABORATOR", "CONTRIBUTOR"}
# Terminal stages: their own completion evidence is produced at or after the § 3.2 capture
# moment, so their inclusion would measure timing, not preservation.
TERMINAL_STAGES = {12, 13}
STAGE_RE = re.compile(r"^\s*stage\s*0*(\d+)\b", re.IGNORECASE)

def is_terminal(title):
    m = STAGE_RE.match(str(title or ""))
    # Unparseable title -> NOT terminal (fail-safe: retain in the denominator).
    return bool(m) and int(m.group(1)) in TERMINAL_STAGES

try:
    items = json.loads(sys.argv[1])
except (ValueError, TypeError) as e:
    print(f"sub-task evidence source unparseable: {e}", file=sys.stderr)
    sys.exit(2)
excluded = 0
scaffolded = 0
preserved = 0
for it in items:
    if is_terminal(it.get("title", "")):
        excluded += 1
        continue
    scaffolded += 1
    if str(it.get("state", "")).upper() != "CLOSED":
        continue
    c = it.get("comments", 0)
    if isinstance(c, list):
        if any("authorAssociation" in cm for cm in c):
            has_evidence = any(str(cm.get("authorAssociation", "")).upper() in TRUSTED for cm in c)
        else:
            has_evidence = len(c) >= 1   # no author data in payload -> presence fallback
    else:
        has_evidence = int(c or 0) >= 1  # integer comment-count shape -> presence
    if has_evidence:
        preserved += 1
print(f"{preserved} {scaffolded} {excluded}")
PY
}

# ─── Self-test mode (no gh / no network) ─────────────────────────────────────

if [[ "${1:-}" == "--self-test" ]]; then
  # Test 1: ratio round-half-up — exact / below-half / at-half / above-half / zero-den
  R="$(ratio_round_half_up 9 9)";  [[ "$R" == "1.00" ]] || die "self-test: ratio 9/9 = $R, expected 1.00"
  R="$(ratio_round_half_up 8 10)"; [[ "$R" == "0.80" ]] || die "self-test: ratio 8/10 = $R, expected 0.80"
  R="$(ratio_round_half_up 2 3)";  [[ "$R" == "0.67" ]] || die "self-test: ratio 2/3 = $R, expected 0.67"
  R="$(ratio_round_half_up 1 8)";  [[ "$R" == "0.13" ]] || die "self-test: ratio 1/8 = $R, expected 0.13 (round-half-up)"
  R="$(ratio_round_half_up 0 3)";  [[ "$R" == "0.00" ]] || die "self-test: ratio 0/3 = $R, expected 0.00"
  R="$(ratio_round_half_up 5 0)";  [[ "$R" == "N/A"  ]] || die "self-test: ratio 5/0 = $R, expected N/A"

  # Test 2: Indicator 1 — retro conformance against a synthetic FULLY-conformant
  #         register (all 10 canonical markers present) and a PARTIAL one (6 of 10).
  TMPD="$(/usr/bin/mktemp -d)"
  trap 'rm -rf "$TMPD"' EXIT
  RETRO_FULL="$TMPD/retro_full.md"
  { for m in "${CANONICAL_MARKERS[@]}"; do echo "$m"; echo "body"; done; } > "$RETRO_FULL"
  read -r P E < <(count_retro_conformance "$RETRO_FULL")
  [[ "$P" == "10" && "$E" == "10" ]] || die "self-test: retro conformance(full) = $P/$E, expected 10/10"
  R="$(ratio_round_half_up "$P" "$E")"; [[ "$R" == "1.00" ]] || die "self-test: retro conformance ratio(full) = $R, expected 1.00"

  RETRO_PARTIAL="$TMPD/retro_partial.md"
  { echo "## 1. Kerth Retrospective (full ceremony)"
    echo "### 1.1 Prime Directive (recite before reflecting)"
    echo "### 1.2 Three-question framework"
    echo "### 1.3 Ritual of closure"
    echo "## 2. PMBOK 7 Lessons-Learned (full ceremony)"
    echo "### 2.1 Situation"
    echo "some unrelated text"
  } > "$RETRO_PARTIAL"
  read -r P E < <(count_retro_conformance "$RETRO_PARTIAL")
  [[ "$P" == "6" && "$E" == "10" ]] || die "self-test: retro conformance(partial) = $P/$E, expected 6/10"
  R="$(ratio_round_half_up "$P" "$E")"; [[ "$R" == "0.60" ]] || die "self-test: retro conformance ratio(partial) = $R, expected 0.60"

  # Test 3: Indicator 2 — lessons population. 4 prompted rows (L1,L2,A1,A2); L2
  #         + A2 still carry the <…> placeholder (unpopulated) -> 2/4.
  LESSONS="$TMPD/lessons.md"
  {
    echo "### 2.3 Lessons"
    echo "| # | Lesson | Type | Evidence anchor |"
    echo "|---|---|---|---|"
    echo "| L1 | A real lesson learned | pattern | file:42 |"
    echo "| L2 | <…> | <…> | <…> |"
    echo "### 2.4 Next-cycle Actions"
    echo "| # | Action | Owner | Disposition |"
    echo "|---|---|---|---|"
    echo "| A1 | A real action item | operator | backlog |"
    echo "| A2 | <…> | <…> | <…> |"
  } > "$LESSONS"
  read -r PL TL < <(count_lessons_population "$LESSONS")
  [[ "$PL" == "2" && "$TL" == "4" ]] || die "self-test: lessons population = $PL/$TL, expected 2/4"
  R="$(ratio_round_half_up "$PL" "$TL")"; [[ "$R" == "0.50" ]] || die "self-test: lessons population ratio = $R, expected 0.50"

  # Test 4: Indicator 2 — a register with ZERO prompted rows -> 0 prompted (N/A ratio)
  LESSONS_EMPTY="$TMPD/lessons_empty.md"
  { echo "### 2.3 Lessons"; echo "no table rows here"; } > "$LESSONS_EMPTY"
  read -r PL TL < <(count_lessons_population "$LESSONS_EMPTY")
  [[ "$PL" == "0" && "$TL" == "0" ]] || die "self-test: empty-lessons = $PL/$TL, expected 0/0"
  R="$(ratio_round_half_up "$PL" "$TL")"; [[ "$R" == "N/A" ]] || die "self-test: empty-lessons ratio = $R, expected N/A"

  # Test 5: expected-marker count is the canonical 10
  [[ "$EXPECTED_MARKERS" -eq 10 ]] || die "self-test: EXPECTED_MARKERS = $EXPECTED_MARKERS, expected 10"

  # Test 6: Indicator 6 — phase-completion evidence preservation (read-model over sub-task gh
  #   state). Denominator = MEASURABLE scaffolded stage sub-tasks (terminal stages 12/13
  #   excluded); numerator = CLOSED with >=1 trusted-authored comment. Covers: full-preserved /
  #   OPEN-excluded / CLOSED-empty-excluded / untrusted-author-excluded / no-author-payload
  #   presence-fallback / integer-count shape / zero-scaffolded -> N/A.
  EVID_FULL='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"CLOSED","comments":[{"authorAssociation":"OWNER"},{"authorAssociation":"MEMBER"}]},{"number":3,"title":"Stage 7 · #1 · Dev Testing","state":"CLOSED","comments":[{"authorAssociation":"COLLABORATOR"}]},{"number":4,"title":"Stage 8 · #1 · QA / Acceptance","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_FULL")
  [[ "$EP" == "4" && "$ES" == "4" && "$EX" == "0" ]] || die "self-test: subtask-evidence(full) = $EP/$ES (excl $EX), expected 4/4 (excl 0)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "1.00" ]] || die "self-test: subtask-evidence ratio(full) = $R, expected 1.00"

  # OPEN (excluded), CLOSED-empty (excluded), CLOSED-OWNER (counted), CLOSED-NONE (untrusted, excluded) -> 1/4
  EVID_PARTIAL='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"OPEN","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"CLOSED","comments":[]},{"number":3,"title":"Stage 7 · #1 · Dev Testing","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":4,"title":"Stage 8 · #1 · QA / Acceptance","state":"CLOSED","comments":[{"authorAssociation":"NONE"}]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_PARTIAL")
  [[ "$EP" == "1" && "$ES" == "4" ]] || die "self-test: subtask-evidence(partial) = $EP/$ES, expected 1/4 (OPEN + CLOSED-empty + untrusted-author excluded)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "0.25" ]] || die "self-test: subtask-evidence ratio(partial) = $R, expected 0.25"

  # No authorAssociation in payload -> presence fallback (CLOSED w/ >=1 comment counts; CLOSED-empty excluded) -> 1/2
  EVID_FALLBACK='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"CLOSED","comments":[{"body":"output posted"}]},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"CLOSED","comments":[]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_FALLBACK")
  [[ "$EP" == "1" && "$ES" == "2" ]] || die "self-test: subtask-evidence(no-author-payload) = $EP/$ES, expected 1/2 (presence fallback)"

  # Integer comment-count shape -> presence (CLOSED count>=1 counts; OPEN excluded; CLOSED count0 excluded) -> 1/3
  EVID_INT='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"CLOSED","comments":2},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"OPEN","comments":5},{"number":3,"title":"Stage 7 · #1 · Dev Testing","state":"CLOSED","comments":0}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_INT")
  [[ "$EP" == "1" && "$ES" == "3" ]] || die "self-test: subtask-evidence(int-count) = $EP/$ES, expected 1/3"

  # F-01 terminal-stage exclusion (the capture-timing artifact). At the § 3.2 capture moment
  # (the Stage-13 chore PR) the Stage-12/13 sub-tasks are still in flight; counting them made
  # the rate a function of WHEN it was read. 6 scaffolded, 2 terminal -> 4/4 (1.00), not 4/6.
  EVID_TERMINAL='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":3,"title":"Stage 7 · #1 · Dev Testing","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":4,"title":"Stage 9 · Plan Review (GO/NO-GO) — r","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":5,"title":"Stage 12 · Execute — r","state":"OPEN","comments":[]},{"number":6,"title":"Stage 13 · Close — r","state":"OPEN","comments":[]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_TERMINAL")
  [[ "$EP" == "4" && "$ES" == "4" && "$EX" == "2" ]] || die "self-test: subtask-evidence(terminal-exclusion) = $EP/$ES (excl $EX), expected 4/4 (excl 2)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "1.00" ]] || die "self-test: subtask-evidence ratio(terminal-exclusion) = $R, expected 1.00 (terminal stages must not depress the rate)"

  # Fail-safe: a sub-task whose title does not carry a parseable `Stage <N>` prefix is RETAINED
  # in the denominator (never shrink S on an unrecognized title). Stage 1/2/3 are not terminal.
  EVID_UNPARSEABLE='[{"number":1,"title":"[Subtask] Software-domain templates — Wave 1","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"","state":"OPEN","comments":[]},{"number":3,"title":"Stage 3 · Bundle","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_UNPARSEABLE")
  [[ "$EP" == "2" && "$ES" == "3" && "$EX" == "0" ]] || die "self-test: subtask-evidence(unparseable-title) = $EP/$ES (excl $EX), expected 2/3 (excl 0 — fail-safe retain)"

  # All-terminal population -> S collapses to 0 -> N/A (not a 0/0 rate)
  EVID_ALL_TERMINAL='[{"number":1,"title":"Stage 12 · Execute — r","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"Stage 13 · Close — r","state":"OPEN","comments":[]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_ALL_TERMINAL")
  [[ "$EP" == "0" && "$ES" == "0" && "$EX" == "2" ]] || die "self-test: subtask-evidence(all-terminal) = $EP/$ES (excl $EX), expected 0/0 (excl 2)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "N/A" ]] || die "self-test: subtask-evidence ratio(all-terminal) = $R, expected N/A"

  # Zero scaffolded -> 0/0 -> N/A rate
  read -r EP ES EX < <(count_subtask_evidence '[]')
  [[ "$EP" == "0" && "$ES" == "0" && "$EX" == "0" ]] || die "self-test: subtask-evidence(zero) = $EP/$ES (excl $EX), expected 0/0 (excl 0)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "N/A" ]] || die "self-test: subtask-evidence ratio(zero) = $R, expected N/A (no stage sub-tasks scaffolded)"

  rm -rf "$TMPD"; trap - EXIT
  echo "self-test: PASS"
  echo "  ratio round-half-up validated (exact / below-half / at-half / above-half / zero-den)"
  echo "  Indicator 1 retro canonical-form conformance validated (full 10/10 + partial 6/10)"
  echo "  Indicator 2 lessons-population validated (placeholder detection 2/4 + zero-prompted N/A)"
  echo "  canonical-marker set validated (10 verbatim Kerth + PMBOK 7 + Triple-Linkage headers)"
  echo "  Indicator 6 phase-evidence preservation validated (full 4/4 + partial 1/4 + presence-fallback + int-count + zero-scaffolded N/A)"
  echo "  Indicator 6 terminal-stage exclusion validated (Stage-12/13 excluded 4/4 not 4/6 + unparseable-title fail-safe retain + all-terminal N/A)"
  exit 0
fi

# ─── Argument parsing ────────────────────────────────────────────────────────

VERSION=""
MILESTONE=""
RETRO_PATH=""
LESSONS_PATH=""
OUTCOME_PRESENT="0"   # Indicator 5 presence (0=absent, 1=present)
CLOSE_GATE="na"       # Indicator 6 (pass|fail|na)
OUTPUT_FORMAT="human" # human | json

while [[ $# -gt 0 ]]; do
  case "$1" in
    --milestone) MILESTONE="${2:-}"; shift 2 ;;
    --retro) RETRO_PATH="${2:-}"; shift 2 ;;
    --lessons) LESSONS_PATH="${2:-}"; shift 2 ;;
    --outcome-present) OUTCOME_PRESENT="${2:-}"; shift 2 ;;
    --close-gate) CLOSE_GATE="${2:-}"; shift 2 ;;
    --json) OUTPUT_FORMAT="json"; shift ;;
    --help|-h) usage ;;
    -*) die "Unknown flag: $1" ;;
    *)
      if [[ -z "$VERSION" ]]; then VERSION="$1"; else die "Unexpected positional arg: $1 (version already set to '$VERSION')"; fi
      shift
      ;;
  esac
done

# ─── Required-field validation ───────────────────────────────────────────────

[[ -z "$VERSION" ]] && die "Required: <version> (positional)"
[[ -z "$MILESTONE" ]] && die "Required: --milestone <N> (the release's GitHub milestone number for carry-forward closure)"
case "$OUTCOME_PRESENT" in 0|1) : ;; *) die "--outcome-present must be 0 or 1 (got '$OUTCOME_PRESENT')" ;; esac
case "$CLOSE_GATE" in pass|fail|na) : ;; *) die "--close-gate must be pass|fail|na (got '$CLOSE_GATE')" ;; esac

# Default the lessons path to the retro path (template carries both blocks in one file).
[[ -z "$LESSONS_PATH" && -n "$RETRO_PATH" ]] && LESSONS_PATH="$RETRO_PATH"

# ─── Indicator 1: retro-conformance ──────────────────────────────────────────

RETRO_PRESENT="N/A"; RETRO_EXPECTED="N/A"; RETRO_RATIO="N/A"; RETRO_NA_REASON=""
if [[ -n "$RETRO_PATH" && -f "$RETRO_PATH" ]]; then
  # exists -> parse (a register that exists but is unreadable is a source-integrity error)
  [[ -r "$RETRO_PATH" ]] || die "retro register exists but is unreadable: $RETRO_PATH" 2
  read -r RETRO_PRESENT RETRO_EXPECTED < <(count_retro_conformance "$RETRO_PATH")
  RETRO_RATIO="$(ratio_round_half_up "$RETRO_PRESENT" "$RETRO_EXPECTED")"
else
  RETRO_NA_REASON="no retro register found for $VERSION"
fi

# ─── Indicator 2: lessons-population ─────────────────────────────────────────

LESS_POP="N/A"; LESS_PROMPTED="N/A"; LESS_RATIO="N/A"; LESS_NA_REASON=""
if [[ -n "$LESSONS_PATH" && -f "$LESSONS_PATH" ]]; then
  [[ -r "$LESSONS_PATH" ]] || die "lessons register exists but is unreadable: $LESSONS_PATH" 2
  read -r LESS_POP LESS_PROMPTED < <(count_lessons_population "$LESSONS_PATH")
  if [[ "$LESS_PROMPTED" -eq 0 ]]; then
    LESS_RATIO="N/A"; LESS_NA_REASON="lessons register present but prompts zero rows"
  else
    LESS_RATIO="$(ratio_round_half_up "$LESS_POP" "$LESS_PROMPTED")"
  fi
else
  LESS_NA_REASON="no lessons register found"
fi

# ─── Indicator 3: carry-forward-closure (gh status: deferred over the milestone) ─

CF_CLOSED="N/A"; CF_RAISED="N/A"; CF_RATIO="N/A"; CF_NA_REASON=""
GH="$(find_gh)"
if [[ -z "$GH" ]]; then
  CF_NA_REASON="gh unavailable — carry-forward closure not computed"
else
  REPO="${REPO:-$("$GH" repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
  if [[ -z "$REPO" ]]; then
    CF_NA_REASON="could not resolve target repo — set REPO or run inside a gh-authenticated repo"
  else
    # Enumerate issues this release labelled `status: deferred`. Per deferred-item-
    # tracking.md the Stage 13 defer DE-MILESTONES the issue, so a label-scoped query
    # over the milestone would miss them. The robust read: all `status: deferred`
    # issues (open + closed), filtered to those whose deferral was raised by this
    # release. The release linkage is the milestone the issue carried before de-
    # milestoning, recorded in the canonical comment trail; in the absence of a
    # machine-readable back-link the Stage 13 spoke passes the raised-set explicitly.
    # Here: read state of all `status: deferred` issues and report closed/raised over
    # the set the milestone still references PLUS any the caller pins via REPO/label.
    # Mechanical default: count over the milestone's `status: deferred` membership
    # that is still milestone-attached (the clean-close case is zero -> N/A).
    DEFERRED_JSON="$("$GH" issue list --repo "$REPO" \
      --milestone "$MILESTONE" --label "status: deferred" --state all --limit 500 \
      --json number,state 2>/dev/null || true)"
    if [[ -z "$DEFERRED_JSON" || "$DEFERRED_JSON" == "[]" ]]; then
      CF_NA_REASON="no carry-forward items raised"
      CF_RAISED=0; CF_CLOSED=0
    else
      read -r CF_CLOSED CF_RAISED < <(/usr/bin/python3 - "$DEFERRED_JSON" <<'PY'
import json, sys
items = json.loads(sys.argv[1])
raised = len(items)
closed = sum(1 for i in items if i.get("state","").upper() == "CLOSED")
print(f"{closed} {raised}")
PY
)
      if [[ "$CF_RAISED" -eq 0 ]]; then
        CF_NA_REASON="no carry-forward items raised"
      else
        CF_RATIO="$(ratio_round_half_up "$CF_CLOSED" "$CF_RAISED")"
      fi
    fi
  fi
fi

# ─── Indicator 4: pattern-emergence (POINTER ONLY — never recomputed here) ───

PATTERN_POINTER="deferred-to-aggregate (see synthesize-release-learnings.sh)"

# ─── Indicator 5: rollup-presence (presence, NOT a rate) ─────────────────────

if [[ "$OUTCOME_PRESENT" == "1" ]]; then ROLLUP_PRESENCE="present"; else ROLLUP_PRESENCE="absent"; fi

# ─── Indicator 6: phase-completion evidence preservation (read-model) + retained close-gate ─
# Primary reading: a bounded read-model over the hub-spoke sub-task `gh` state (NO net-new
# store) — CLOSED stage sub-tasks carrying >=1 trusted-authored comment (P) / MEASURABLE stage
# sub-tasks scaffolded for the release (S, terminal stages 12/13 excluded); rate = P/S. Reuses
# the GH + REPO resolved for Indicator 3. Mechanical gh-state read only — honors the standard
# § 8 boundary (NOT the event log). N/A when the release scaffolded zero stage sub-tasks
# (pre-hub-spoke / grandfathered), or when every scaffolded sub-task is terminal-stage.
EVID_PRESERVED="N/A"; EVID_SCAFFOLDED="N/A"; EVID_RATIO="N/A"; EVID_NA_REASON=""; EVID_EXCLUDED=0
if [[ -z "$GH" ]]; then
  EVID_NA_REASON="gh unavailable — phase-evidence preservation not computed"
elif [[ -z "${REPO:-}" ]]; then
  EVID_NA_REASON="could not resolve target repo — set REPO or run inside a gh-authenticated repo"
else
  SUBTASK_JSON="$("$GH" issue list --repo "$REPO" \
    --milestone "$MILESTONE" --label "sub-task" --state all --limit 500 \
    --json number,title,state,comments 2>/dev/null || true)"
  if [[ -z "$SUBTASK_JSON" || "$SUBTASK_JSON" == "[]" ]]; then
    EVID_NA_REASON="no stage sub-tasks scaffolded"
    EVID_SCAFFOLDED=0; EVID_PRESERVED=0
  else
    read -r EVID_PRESERVED EVID_SCAFFOLDED EVID_EXCLUDED < <(count_subtask_evidence "$SUBTASK_JSON")
    if [[ "$EVID_SCAFFOLDED" -eq 0 ]]; then
      if [[ "$EVID_EXCLUDED" -gt 0 ]]; then
        EVID_NA_REASON="no non-terminal stage sub-tasks scaffolded"
      else
        EVID_NA_REASON="no stage sub-tasks scaffolded"
      fi
    else
      EVID_RATIO="$(ratio_round_half_up "$EVID_PRESERVED" "$EVID_SCAFFOLDED")"
    fi
  fi
fi

# Retained secondary sub-signal: the single Stage-13 G-CL4 close-gate boolean (non-destructive
# upgrade — the rate is primary, the boolean loses no signal).
case "$CLOSE_GATE" in
  pass) EVIDENCE_GATE="pass" ;;
  fail) EVIDENCE_GATE="fail" ;;
  na)   EVIDENCE_GATE="N/A" ;;
esac

# ─── Emission ────────────────────────────────────────────────────────────────

# Build the three rate sub-signal strings (value or N/A — reason).
fmt_rate() {
  # args: ratio num den na_reason  -> "<num>/<den> (<ratio>)" OR "N/A — <reason>"
  local ratio="$1" num="$2" den="$3" reason="$4"
  if [[ "$ratio" == "N/A" ]]; then
    echo "N/A — $reason"
  else
    echo "$num/$den ($ratio)"
  fi
}

RETRO_STR="$(fmt_rate "$RETRO_RATIO" "$RETRO_PRESENT" "$RETRO_EXPECTED" "$RETRO_NA_REASON")"
LESS_STR="$(fmt_rate "$LESS_RATIO" "$LESS_POP" "$LESS_PROMPTED" "$LESS_NA_REASON")"
CF_STR="$(fmt_rate "$CF_RATIO" "$CF_CLOSED" "$CF_RAISED" "$CF_NA_REASON")"
EVID_STR="$(fmt_rate "$EVID_RATIO" "$EVID_PRESERVED" "$EVID_SCAFFOLDED" "$EVID_NA_REASON")"

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  /usr/bin/python3 - \
    "$VERSION" "$MILESTONE" \
    "$RETRO_RATIO" "$RETRO_PRESENT" "$RETRO_EXPECTED" "$RETRO_NA_REASON" \
    "$LESS_RATIO" "$LESS_POP" "$LESS_PROMPTED" "$LESS_NA_REASON" \
    "$CF_RATIO" "$CF_CLOSED" "$CF_RAISED" "$CF_NA_REASON" \
    "$ROLLUP_PRESENCE" "$EVIDENCE_GATE" \
    "$EVID_RATIO" "$EVID_PRESERVED" "$EVID_SCAFFOLDED" "$EVID_NA_REASON" "$EVID_EXCLUDED" <<'PY'
import json, sys
a = sys.argv
def na(v): return None if v == "N/A" else v
out = {
  "version": a[1],
  "milestone": a[2],
  "retro_conformance": {"ratio": na(a[3]), "present": na(a[4]), "expected": na(a[5]), "na_reason": a[6] or None},
  "lessons_population": {"ratio": na(a[7]), "populated": na(a[8]), "prompted": na(a[9]), "na_reason": a[10] or None},
  "carry_forward_closure": {"ratio": na(a[11]), "closed": na(a[12]), "raised": na(a[13]), "na_reason": a[14] or None},
  "pattern_emergence": "deferred-to-aggregate",
  "rollup_presence": a[15],
  # `scaffolded` is the MEASURABLE denominator (terminal stages 12/13 excluded);
  # `terminal_excluded` discloses how many were held out, so a reader can reconcile
  # it against the raw sub-task count without re-deriving the rule.
  "phase_evidence_preservation": {"ratio": na(a[17]), "preserved": na(a[18]), "scaffolded": na(a[19]), "na_reason": a[20] or None, "terminal_excluded": int(a[21])},
  "evidence_close_gate": a[16],
  "mechanism": "compute-close-class-telemetry.sh",
}
print(json.dumps(out))
PY
  exit 0
fi

# Human form == the literal **Close-Class-Telemetry:** field value embedded in the H4 block.
echo "retro-conformance ${RETRO_STR}; lessons-population ${LESS_STR}; carry-forward-closure ${CF_STR}; pattern-emergence ${PATTERN_POINTER}; rollup-presence ${ROLLUP_PRESENCE}; evidence-preservation ${EVID_STR}; evidence-close-gate ${EVIDENCE_GATE}; mechanism: compute-close-class-telemetry.sh"
exit 0

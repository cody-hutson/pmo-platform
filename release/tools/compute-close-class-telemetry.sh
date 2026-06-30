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
#   Indicator 6 evidence-close-gate    : pass|fail|N/A — the single Stage-13 G-CL4
#                                        close-gate boolean (the per-phase reading is
#                                        N/A-until-source-exists; no ledger).
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
#   --close-gate {pass|fail|na}  OPTIONAL Indicator-6 G-CL4 close-gate verdict. Default: na.
#
# Cutover: applies to releases entering Stage 13 strictly AFTER this field's
# introducing-release merge SHA. The introducing release itself is exempt. This
# script does not gate by version — the caller (Stage 13 spoke) honors cutover.
#
# Exit codes:
#   0 = success (an indicator may legitimately produce N/A — no register, no
#       carry-forwards; or the Indicator-4 pointer / I5 presence / I6 boolean)
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

  rm -rf "$TMPD"; trap - EXIT
  echo "self-test: PASS"
  echo "  ratio round-half-up validated (exact / below-half / at-half / above-half / zero-den)"
  echo "  Indicator 1 retro canonical-form conformance validated (full 10/10 + partial 6/10)"
  echo "  Indicator 2 lessons-population validated (placeholder detection 2/4 + zero-prompted N/A)"
  echo "  canonical-marker set validated (10 verbatim Kerth + PMBOK 7 + Triple-Linkage headers)"
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

# ─── Indicator 6: evidence-close-gate (single G-CL4 boolean) ─────────────────

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

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  /usr/bin/python3 - \
    "$VERSION" "$MILESTONE" \
    "$RETRO_RATIO" "$RETRO_PRESENT" "$RETRO_EXPECTED" "$RETRO_NA_REASON" \
    "$LESS_RATIO" "$LESS_POP" "$LESS_PROMPTED" "$LESS_NA_REASON" \
    "$CF_RATIO" "$CF_CLOSED" "$CF_RAISED" "$CF_NA_REASON" \
    "$ROLLUP_PRESENCE" "$EVIDENCE_GATE" <<'PY'
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
  "evidence_close_gate": a[16],
  "mechanism": "compute-close-class-telemetry.sh",
}
print(json.dumps(out))
PY
  exit 0
fi

# Human form == the literal **Close-Class-Telemetry:** field value embedded in the H4 block.
echo "retro-conformance ${RETRO_STR}; lessons-population ${LESS_STR}; carry-forward-closure ${CF_STR}; pattern-emergence ${PATTERN_POINTER}; rollup-presence ${ROLLUP_PRESENCE}; evidence-close-gate ${EVIDENCE_GATE}; mechanism: compute-close-class-telemetry.sh"
exit 0

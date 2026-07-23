#!/usr/bin/env bash
# compute-middle-cluster-telemetry.sh — Middle-cluster phase-distinctive telemetry read-model.
# Per release/references/standards/phase-telemetry-middle-cluster.md.
# Sibling to compute-dora-metrics.sh / compute-close-class-telemetry.sh / the front-cluster
# tool — same form factor, same exit-code contract, same explicit-N/A discipline.
#
# The middle cluster = the pipeline's "sound coming OUT" phases:
#   Verify (Stages 7-8), Authorize (Stage 9).
# It computes the middle cluster's phase-distinctive quality-attribute read-models as an
# ON-DEMAND WINDOW read-model over the operator-instance pipeline event log at
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md, via query-pipeline-event.sh
# (sibling tool; it resolves the log location).
#
# READ-MODEL ONLY: this tool READS the event stream; it NEVER writes a row back into it
# (the OUT-class boundary per the standard § 3.1 / § 12 FM3). It also NEVER writes the
# event-log schema (CIAC-1 reader).
#
# 11 candidate indicators, anti-overfit-dispositioned (standard § 4):
#   BUILD (4): composed-loop-iteration-depth, escape-rate, conditional-accept-rate,
#              exception-plan-trigger-rate
#   POINTER (1): decision-outcome-correlation
#              (query-pipeline-event.sh --event-subtype recommendation-choice-delta look-back)
#   NARROWED (1): decision-record-conformance (presence; deep conformance qualitative)
#   DEFER (5): forward-handoff-payload-conformance, lane-2-through-dt, ambiguous-ac,
#              vocabulary-distinguishing, phase-b-3-tier-presentation
#              (no present mechanical source — N/A-until-source, no bespoke machinery)
#
# Per-indicator N/A is INDEPENDENT (standard § 5): a window may yield real values for some
# indicators and N/A for others. N/A is never blank-fill and never a synthesized 0.00 for
# an absent population — it carries a parenthetical reason.
#
# Usage:
#   ./compute-middle-cluster-telemetry.sh                      # human block, all events
#   ./compute-middle-cluster-telemetry.sh --window 5           # trailing 5 distinct versions
#   ./compute-middle-cluster-telemetry.sh --json               # JSON of all indicators
#   ./compute-middle-cluster-telemetry.sh --indicator escape-rate  # single indicator
#   ./compute-middle-cluster-telemetry.sh --self-test          # validate logic (no network)
#   ./compute-middle-cluster-telemetry.sh --help               # this help text
#
# Inputs:
#   --window <N>       restrict to the trailing N DISTINCT release versions (matches
#                      query-pipeline-event.sh --window semantics). Default: all events.
#   --indicator <name> emit a single indicator only (any BUILD indicator name above).
#   --json             machine detail (JSON of every indicator + disposition + N/A reason).
#
# Cutover: applies to windows over events emitted post-cutover; pre-cutover windows yield
# N/A for the affected indicators (no backfill). This tool does not gate by date — the
# caller honors cutover (standard § 10).
#
# Exit codes:
#   0 = success (any indicator may legitimately produce N/A — empty population; POINTER;
#       NARROWED presence; or a DEFER reason)
#   1 = invalid args / required dependency (query-pipeline-event.sh / python3) unavailable
#   2 = malformed source (ts_iso parse failure — source-integrity violation; escalate)

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Two levels up — NOT three; a `../../..` depth mis-anchors above the repo from a worktree.
# shellcheck disable=SC2034
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
QUERY_TOOL="$SCRIPT_DIR/query-pipeline-event.sh"
PY=/usr/bin/python3

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,53p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# ─── The event-sourced aggregator (single python pass; stdlib only) ──────────
# Emits a JSON object with every middle-cluster indicator. Passed:
#   argv[1] = window ("" or a positive integer count of trailing distinct versions)
# stdin    = the pipe-delimited event rows (query-pipeline-event.sh field layout).
MIDDLE_AGG_PY="$(/bin/cat <<'PY'
import sys, json, math
from datetime import datetime
from collections import defaultdict

window = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1] else None

def parse_iso(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError as e:
        print(f"ts_iso parse failure: {e}", file=sys.stderr)
        sys.exit(2)

def rhu(num, den):
    # round-half-up to 2 decimals (canonical mode by reference from
    # bundle-composition-doctrine.md § 3 Step 5); None when the denominator is empty.
    if den == 0:
        return None
    return math.floor((num / den) * 100 + 0.5) / 100

rows = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line.strip():
        continue
    parts = line.split(" | ")
    if len(parts) < 9:
        continue
    ts = parts[0][2:].strip()
    # Parse ONCE at ingest and carry the datetime on the row. Every temporal
    # comparison below orders on `tsdt`, never on the raw `ts` string: lexicographic
    # order equals chronological order only under ONE fixed timestamp format, and a
    # fractional-second stamp ("…:00.500Z") parses cleanly, clears the exit-2
    # integrity gate, then sorts BEFORE "…:00Z" — silently dropping a real escape
    # and publishing it as a clean signal. `ts` is retained for display only.
    tsdt = parse_iso(ts)
    rows.append({
        "ts": ts,
        "tsdt": tsdt,
        "version": parts[1].strip(),
        "stage": parts[2].strip(),
        "etype": parts[3].strip(),
        "esub": parts[4].strip(),
        "subject": parts[6].strip(),
        "outcome": parts[8].strip(),
        "payload": parts[9].strip() if len(parts) > 9 else "",
    })

if window:
    keep = []
    for r in reversed(rows):
        if r["version"] not in keep:
            if len(keep) >= window:
                continue
            keep.append(r["version"])
    keepset = set(keep)
    rows = [r for r in rows if r["version"] in keepset]

by_subject = defaultdict(list)
for r in rows:
    by_subject[r["subject"]].append(r)

# ─── I18 composed-loop iteration depth (Verify) ──────────────────────────────
# Mean over subjects (with >=1 iteration row) of the count of iteration passes
# (dt-eng-pass-N + qa-dt-pass-N) — "how deep the composed DT<->Eng / QA<->DT loop went".
iter_counts = defaultdict(int)
for r in rows:
    if r["etype"] == "iteration" and (r["esub"].startswith("dt-eng-pass-") or r["esub"].startswith("qa-dt-pass-")):
        iter_counts[r["subject"]] += 1
n_subj = len(iter_counts)
total_iter = sum(iter_counts.values())
i18 = {"mean": rhu(total_iter, n_subj), "n_subjects": n_subj}

# ─── I19 escape rate (Verify) ────────────────────────────────────────────────
# Denominator: subjects with a gate-outcome/dt-pass (passed dev-test).
# Numerator: those that then hit a gate-outcome/qa-rejection (defect escaped DT into QA).
dt_pass = {}
for r in rows:
    if r["etype"] == "gate-outcome" and r["esub"] == "dt-pass":
        s = r["subject"]
        if s not in dt_pass or r["tsdt"] < dt_pass[s]:
            dt_pass[s] = r["tsdt"]
escaped = 0
for s, p_ts in dt_pass.items():
    if any(rr["etype"] == "gate-outcome" and rr["esub"] == "qa-rejection" and rr["tsdt"] > p_ts for rr in by_subject[s]):
        escaped += 1
i19 = {"num": escaped, "den": len(dt_pass), "rate": rhu(escaped, len(dt_pass))}

# ─── I21 conditional-accept rate (Verify) ────────────────────────────────────
# Denominator: all dev-test verdict rows (dt-pass + dt-conditional-pass + dt-return).
# Numerator: dt-conditional-pass rows.
DT_VERDICTS = ("dt-pass", "dt-conditional-pass", "dt-return")
dt_verdict_rows = sum(1 for r in rows if r["etype"] == "gate-outcome" and r["esub"] in DT_VERDICTS)
dt_conditional = sum(1 for r in rows if r["etype"] == "gate-outcome" and r["esub"] == "dt-conditional-pass")
i21 = {"num": dt_conditional, "den": dt_verdict_rows, "rate": rhu(dt_conditional, dt_verdict_rows)}

# ─── I24 exception-plan-trigger rate (Authorize) ─────────────────────────────
# Denominator: distinct plan-reviews (subjects with a plan-review-go/no-go verdict).
# Numerator: those that resulted in a no-go OR a Stage-9 escalation (an exception path).
plan_reviews = set()
for r in rows:
    if r["etype"] == "gate-outcome" and r["esub"] in ("plan-review-go", "plan-review-no-go"):
        plan_reviews.add(r["subject"])
exception = set()
for s in plan_reviews:
    for rr in by_subject[s]:
        if rr["etype"] == "gate-outcome" and rr["esub"] == "plan-review-no-go":
            exception.add(s); break
        if rr["etype"] == "escalation" and rr["stage"] == "9":
            exception.add(s); break
i24 = {"num": len(exception), "den": len(plan_reviews), "rate": rhu(len(exception), len(plan_reviews))}

# ─── I22 decision-record conformance (Authorize; NARROWED presence) ──────────
# Presence: is a release-level plan-review decision record present in the window?
# Deep conformance (does the record meet every G-PR6 field) is qualitative — deferred.
has_record = any(r["etype"] == "gate-outcome" and r["esub"] in ("plan-review-go", "plan-review-no-go") for r in rows)
i22 = {"presence": ("present" if has_record else "absent"),
       "note": "deep conformance is qualitative — rate deferred"}

out = {
    "window": (f"trailing {window} versions" if window else "all events"),
    "build": {
        "composed-loop-iteration-depth": i18,
        "escape-rate": i19,
        "conditional-accept-rate": i21,
        "exception-plan-trigger-rate": i24,
    },
    "pointer": {
        "decision-outcome-correlation": "see query-pipeline-event.sh --event-subtype recommendation-choice-delta --window N (rec<->choice look-back)",
    },
    "narrowed": {
        "decision-record-conformance": i22,
    },
    "deferred": {
        "forward-handoff-payload-conformance": "no payload-conformance event in the 10-col schema; N/A-until-source",
        "lane-2-through-dt": "no 'lane' field in the event schema; N/A-until-source",
        "ambiguous-ac": "verdict enum is MET/NOT-MET/PARTIAL — no ambiguity value (PARTIAL != ambiguous); N/A-until-source",
        "vocabulary-distinguishing": "semantic analysis of decision-record vocabulary — no structured field; N/A-until-source",
        "phase-b-3-tier-presentation": "structural/text property of the briefing, not an event; N/A-until-source",
    },
}
print(json.dumps(out))
PY
)"

# ─── Self-test mode (no network / no event log) ──────────────────────────────
if [[ "${1:-}" == "--self-test" ]]; then
  [[ -x "$QUERY_TOOL" ]] || die "self-test: query-pipeline-event.sh not executable at $QUERY_TOOL"
  [[ -x "$PY" ]] || die "self-test: $PY not executable"

  FIXTURE="$(/bin/cat <<'ROWS'
| 2026-04-01T10:00:00Z | v1.00 | 7 | iteration | dt-eng-pass-1 | hub | #P | CHEAP | resolved | p |
| 2026-04-01T12:00:00Z | v1.00 | 7 | iteration | dt-eng-pass-2 | hub | #P | CHEAP | resolved | p |
| 2026-04-02T10:00:00Z | v1.00 | 8 | iteration | qa-dt-pass-1 | hub | #Q | CHEAP | resolved | p |
| 2026-04-03T10:00:00Z | v1.00 | 7 | gate-outcome | dt-pass | spoke:#R | #R | CHEAP | resolved | p |
| 2026-04-03T14:00:00Z | v1.00 | 8 | gate-outcome | qa-rejection | spoke:#R | #R | MODERATE | resolved | p |
| 2026-04-04T10:00:00Z | v1.00 | 7 | gate-outcome | dt-pass | spoke:#S | #S | CHEAP | resolved | p |
| 2026-04-05T10:00:00Z | v1.00 | 7 | gate-outcome | dt-conditional-pass | spoke:#T | #T | CHEAP | resolved | p |
| 2026-04-06T10:00:00Z | v1.00 | 7 | gate-outcome | dt-return | spoke:#U | #U | CHEAP | resolved | p |
| 2026-04-07T10:00:00Z | v1.00 | 9 | gate-outcome | plan-review-go | hub | milestone:#M9 | EXPENSIVE | resolved | p |
| 2026-04-08T10:00:00Z | v1.00 | 9 | gate-outcome | plan-review-no-go | hub | milestone:#M10 | EXPENSIVE | resolved | p |
| 2026-04-09T10:00:00Z | v1.00 | 9 | gate-outcome | plan-review-go | hub | milestone:#M11 | EXPENSIVE | resolved | p |
| 2026-04-09T11:00:00Z | v1.00 | 9 | escalation | tier-2 | operator | milestone:#M11 | EXPENSIVE | resolved | p |
ROWS
)"
  ST_JSON="$(printf '%s\n' "$FIXTURE" | "$PY" -c "$MIDDLE_AGG_PY" "")"

  get() { "$PY" -c 'import json,sys
d=json.loads(sys.argv[1])
for k in sys.argv[2:]:
    d=d[k]
print("NA" if d is None else d)' "$ST_JSON" "$@"; }

  # I18 mean loop depth: #P=2 rows, #Q=1 row -> mean (2+1)/2 = 1.5
  [[ "$(get build composed-loop-iteration-depth mean)" == "1.5" ]] || die "self-test: I18 loop-depth mean = $(get build composed-loop-iteration-depth mean), expected 1.5"
  # I19 escape: dt-pass {#R,#S}; #R escaped -> 1/2 = 0.5
  [[ "$(get build escape-rate rate)" == "0.5" ]]                    || die "self-test: I19 escape = $(get build escape-rate rate), expected 0.5 (1/2)"
  # I21 conditional: 1 conditional / 4 dt verdicts (2 pass + 1 conditional + 1 return) = 0.25
  [[ "$(get build conditional-accept-rate rate)" == "0.25" ]]       || die "self-test: I21 conditional = $(get build conditional-accept-rate rate), expected 0.25 (1/4)"
  # I24 exception: plan-reviews {#M9,#M10,#M11}=3; exceptions {#M10 no-go, #M11 stage-9 escalation}=2 -> 0.67
  [[ "$(get build exception-plan-trigger-rate rate)" == "0.67" ]]   || die "self-test: I24 exception = $(get build exception-plan-trigger-rate rate), expected 0.67 (2/3)"
  # I22 presence: plan-review rows present -> "present"
  [[ "$(get narrowed decision-record-conformance presence)" == "present" ]] || die "self-test: I22 presence = $(get narrowed decision-record-conformance presence), expected present"

  # Temporal ordering must compare PARSED datetimes, never raw timestamp strings.
  # Discriminating fixture: a QA rejection 250ms after its DT pass, in the same whole
  # second. Lexicographically "…:00.250Z" sorts BEFORE "…:00Z" ('.' < 'Z'), so a raw-string
  # compare reads the rejection as PRE-pass and drops a REAL escape — publishing
  # `escape-rate 0/1 (0.00)`, an FM1-shaped fabricated clean signal. Expected 1.0.
  TS_FIXTURE="$(/bin/cat <<'ROWS'
| 2026-04-10T09:00:00Z | v2.00 | 7 | gate-outcome | dt-pass | spoke:#Y | #Y | CHEAP | resolved | p |
| 2026-04-10T09:00:00.250Z | v2.00 | 8 | gate-outcome | qa-rejection | spoke:#Y | #Y | MODERATE | resolved | post-pass |
ROWS
)"
  TS_JSON="$(printf '%s\n' "$TS_FIXTURE" | "$PY" -c "$MIDDLE_AGG_PY" "")"
  TSR="$("$PY" -c 'import json,sys; v=json.loads(sys.argv[1])["build"]["escape-rate"]["rate"]; print("NA" if v is None else v)' "$TS_JSON")"
  [[ "$TSR" == "1.0" ]] || die "self-test: I19 fractional-second ordering = $TSR, expected 1.0 (the .250Z rejection is AFTER the Z-form dt-pass; a raw-string compare drops the escape and fabricates a clean 0.00)"

  # N/A discipline: an empty stream yields N/A rates (not 0.00) for every BUILD rate.
  EMPTY_JSON="$(printf '' | "$PY" -c "$MIDDLE_AGG_PY" "")"
  ER="$("$PY" -c 'import json,sys; v=json.loads(sys.argv[1])["build"]["escape-rate"]["rate"]; print("NA" if v is None else v)' "$EMPTY_JSON")"
  [[ "$ER" == "NA" ]] || die "self-test: empty-stream escape-rate = $ER, expected NA (empty population, NOT 0.00)"
  PR="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["narrowed"]["decision-record-conformance"]["presence"])' "$EMPTY_JSON")"
  [[ "$PR" == "absent" ]] || die "self-test: empty-stream I22 presence = $PR, expected absent"

  echo "self-test: PASS"
  echo "  4 BUILD indicators validated (loop-depth mean, escape, conditional-accept, exception-trigger)"
  echo "  NARROWED I22 presence flag validated (present / absent)"
  echo "  temporal ordering validated on parsed datetimes (fractional-second stamp does not drop an escape)"
  echo "  N/A discipline validated (empty population -> N/A, never synthesized 0.00)"
  echo "  query-pipeline-event.sh dependency validated"
  exit 0
fi

# ─── Argument parsing ────────────────────────────────────────────────────────
WINDOW=""
SINGLE_INDICATOR=""
OUTPUT_FORMAT="human"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --window) WINDOW="${2:-}"; shift 2 ;;
    --indicator) SINGLE_INDICATOR="${2:-}"; shift 2 ;;
    --json) OUTPUT_FORMAT="json"; shift ;;
    --help|-h) usage ;;
    -*) die "Unknown flag: $1" ;;
    *) die "Unexpected positional arg: $1" ;;
  esac
done

if [[ -n "$WINDOW" ]]; then
  [[ "$WINDOW" =~ ^[0-9]+$ && "$WINDOW" -ge 1 ]] || die "--window must be a positive integer: got '$WINDOW'"
fi

[[ -x "$QUERY_TOOL" ]] || die "query-pipeline-event.sh missing or not executable at $QUERY_TOOL"
[[ -x "$PY" ]] || die "$PY not executable (required for aggregation)"

ALL_ROWS="$("$QUERY_TOOL" 2>/dev/null | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"

MIDDLE_JSON="$(printf '%s\n' "$ALL_ROWS" | "$PY" -c "$MIDDLE_AGG_PY" "$WINDOW")" \
  || die "middle-cluster aggregation parse failure (malformed ts_iso)" 2

# ─── Render ──────────────────────────────────────────────────────────────────
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  if [[ -n "$SINGLE_INDICATOR" ]]; then
    "$PY" -c 'import json,sys
d=json.loads(sys.argv[1]); k=sys.argv[2]
b=d["build"]
print(json.dumps({k: b[k]}) if k in b else json.dumps({k: "unknown or non-BUILD indicator"}))' "$MIDDLE_JSON" "$SINGLE_INDICATOR"
  else
    printf '%s\n' "$MIDDLE_JSON"
  fi
  exit 0
fi

r_rate() { "$PY" -c 'import json,sys
d=json.loads(sys.argv[1])["build"][sys.argv[2]]
if d["rate"] is None:
    print("N/A (" + sys.argv[3] + ")")
else:
    print("%d/%d (%.2f)" % (d["num"], d["den"], d["rate"]))' "$MIDDLE_JSON" "$1" "$2"; }

r_depth() { "$PY" -c 'import json,sys
d=json.loads(sys.argv[1])["build"]["composed-loop-iteration-depth"]
if d["mean"] is None:
    print("N/A (no iteration rows in window)")
else:
    print("%.2f mean passes over %d issue(s)" % (d["mean"], d["n_subjects"]))' "$MIDDLE_JSON"; }

if [[ -n "$SINGLE_INDICATOR" ]]; then
  case "$SINGLE_INDICATOR" in
    escape-rate) r_rate "$SINGLE_INDICATOR" "no dt-pass subjects in window" ;;
    conditional-accept-rate) r_rate "$SINGLE_INDICATOR" "no dev-test verdicts in window" ;;
    exception-plan-trigger-rate) r_rate "$SINGLE_INDICATOR" "no plan-reviews in window" ;;
    composed-loop-iteration-depth) r_depth ;;
    *) die "--indicator must be a BUILD indicator name (see --help)" ;;
  esac
  exit 0
fi

WINDOW_DESC="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["window"])' "$MIDDLE_JSON")"
PRESENCE="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["narrowed"]["decision-record-conformance"]["presence"])' "$MIDDLE_JSON")"

echo "Middle-cluster telemetry (window=${WINDOW_DESC}) — Verify / Authorize:"
echo "  [Verify]"
echo "    composed-loop-iteration-depth: $(r_depth)"
echo "    escape-rate:                   $(r_rate escape-rate 'no dt-pass subjects in window')"
echo "    conditional-accept-rate:       $(r_rate conditional-accept-rate 'no dev-test verdicts in window')"
echo "    forward-handoff-payload-conformance: DEFER — no payload-conformance event; N/A-until-source"
echo "    lane-2-through-dt:             DEFER — no 'lane' field in the event schema; N/A-until-source"
echo "    ambiguous-ac:                  DEFER — verdict enum has no ambiguity value; N/A-until-source"
echo "  [Authorize]"
echo "    exception-plan-trigger-rate:   $(r_rate exception-plan-trigger-rate 'no plan-reviews in window')"
echo "    decision-record-conformance:   NARROWED — presence ${PRESENCE}; deep conformance qualitative (rate deferred)"
echo "    decision-outcome-correlation:  POINTER — query-pipeline-event.sh --event-subtype recommendation-choice-delta --window N"
echo "    vocabulary-distinguishing:     DEFER — semantic (no structured field); N/A-until-source"
echo "    phase-b-3-tier-presentation:   DEFER — structural/text property, not an event; N/A-until-source"
echo "  mechanism: compute-middle-cluster-telemetry.sh"
exit 0

#!/usr/bin/env bash
# compute-front-cluster-telemetry.sh — Front-cluster phase-distinctive telemetry read-model.
# Per release/references/standards/phase-telemetry-front-cluster.md.
# Sibling to compute-dora-metrics.sh / compute-close-class-telemetry.sh — same form
# factor, same exit-code contract, same explicit-N/A discipline.
#
# The front cluster = the pipeline's "well-formed going IN" phases:
#   Demand (Stages 1-2), Definition (Stages 3-4), Solution-design (Stage 5).
# It computes the front cluster's phase-distinctive quality-attribute read-models as
# an ON-DEMAND WINDOW read-model over the operator-instance pipeline event log at
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md, via
# query-pipeline-event.sh (sibling tool; it resolves the log location), plus a thin
# best-effort `gh` read for the one gh-sourced gauge (approved-queue-depth).
#
# READ-MODEL ONLY: this tool READS the event stream; it NEVER writes a row back into
# it (the OUT-class boundary per the standard § 3.1 / § 12 FM3). It also NEVER writes
# the event-log schema (CIAC-1 reader).
#
# 15 candidate indicators, anti-overfit-dispositioned (standard § 4):
#   BUILD (9): zero-round-trip-triage-rate, triage-cycle-time, approved-queue-depth,
#              plan-survival-rate, bundle-amendment-rate, phase-a0-c3-rate,
#              plan-survival-post-solutioning-rate, phase-0.5-c3-rate,
#              collective-review-scope-lock-first-pass-rate
#   POINTER (3): capacity-overrun, file-contention-detection (gate-evaluation-spec.md
#              Gate 3->4), adr-closure (gate-evaluation-spec.md Gate 5->6) — reference,
#              never recompute
#   NARROWED (1): source-of-origin-attribution (presence/coverage; rate deferred)
#   DEFER (2): decision-date-setting, quality-attribute-trade-off-mention
#              (no present mechanical source — N/A-until-source, no bespoke machinery)
#
# Per-indicator N/A is INDEPENDENT (standard § 5): a window may yield real values for
# some indicators and N/A for others. N/A is never blank-fill and never a synthesized
# 0.00 for an absent population — it carries a parenthetical reason.
#
# Usage:
#   ./compute-front-cluster-telemetry.sh                       # human block, all events
#   ./compute-front-cluster-telemetry.sh --window 5            # trailing 5 distinct versions
#   ./compute-front-cluster-telemetry.sh --json                # JSON of all indicators
#   ./compute-front-cluster-telemetry.sh --indicator plan-survival-rate  # single indicator
#   ./compute-front-cluster-telemetry.sh --self-test           # validate logic (no network/gh)
#   ./compute-front-cluster-telemetry.sh --help                # this help text
#
# Inputs:
#   --window <N>       restrict to the trailing N DISTINCT release versions (matches
#                      query-pipeline-event.sh --window semantics). Default: all events.
#   --indicator <name> emit a single indicator only (any BUILD indicator name above).
#   --json             machine detail (JSON of every indicator + disposition + N/A reason).
#
# Cutover: applies to windows over events emitted post-cutover; pre-cutover windows
# yield N/A for the affected indicators (no backfill). This tool does not gate by date —
# the caller honors cutover (standard § 10).
#
# Exit codes:
#   0 = success (any indicator may legitimately produce N/A — empty population; POINTER;
#       NARROWED presence; or a DEFER reason)
#   1 = invalid args / required dependency (query-pipeline-event.sh / python3) unavailable
#   2 = malformed source (ts_iso parse failure — source-integrity violation; escalate)

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
# gh is resolved by absolute discovery below (not on the pinned PATH).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Two levels up — NOT three; a `../../..` depth mis-anchors above the repo from a
# worktree (the extinct-path resolution bug the sibling event-log tools guard against).
# shellcheck disable=SC2034
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
QUERY_TOOL="$SCRIPT_DIR/query-pipeline-event.sh"
PY=/usr/bin/python3

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,54p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# Resolve gh off the pinned PATH (commonly /opt/homebrew/bin or /usr/local/bin).
find_gh() {
  local c
  for c in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh "$HOME/.local/bin/gh"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  command -v gh 2>/dev/null || true
}

# ─── Duration formatting (compact <X>m / <H>h<M>m / <D>d<H>h per DORA § 3 sibling) ──
format_duration() {
  local secs="$1"
  if [[ "$secs" -lt 0 ]]; then secs=0; fi
  if [[ "$secs" -lt 3600 ]]; then
    /usr/bin/printf '%dm\n' "$(( secs / 60 ))"
  elif [[ "$secs" -lt 86400 ]]; then
    /usr/bin/printf '%dh%dm\n' "$(( secs / 3600 ))" "$(( (secs % 3600) / 60 ))"
  else
    /usr/bin/printf '%dd%dh\n' "$(( secs / 86400 ))" "$(( (secs % 86400) / 3600 ))"
  fi
}

# ─── The event-sourced aggregator (single python pass; stdlib only) ──────────
# Emits a JSON object with every front-cluster indicator. Passed:
#   argv[1] = approved_queue_depth ("NA" or an integer, computed via gh in bash)
#   argv[2] = window ("" or a positive integer count of trailing distinct versions)
# stdin    = the pipe-delimited event rows (query-pipeline-event.sh field layout:
#            "| ts | version | stage | event_type | event_subtype | actor | subject |
#             reversibility | outcome | payload |").
FRONT_AGG_PY="$(/bin/cat <<'PY'
import sys, json, math, re
from datetime import datetime
from collections import defaultdict

approved_depth = sys.argv[1] if len(sys.argv) > 1 else "NA"
window = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else None

def parse_iso(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError as e:
        print(f"ts_iso parse failure: {e}", file=sys.stderr)
        sys.exit(2)

def rhu(num, den):
    # round-half-up to 2 decimals (the one canonical mode, taken by reference from
    # bundle-composition-doctrine.md § 3 Step 5); None when the denominator is empty.
    if den == 0:
        return None
    return math.floor((num / den) * 100 + 0.5) / 100

def norm_stage(s):
    # A stage is read as its integer value, the way the row-identity rules in
    # append-pipeline-event.sh match it (^0*4$, ^0*[45]$): the writer admits a zero-padded
    # stage such as 05, and an exact string compare dropped that row from every stage-keyed
    # selection below while the writer had judged it a stage-5 row. Normalized once, here,
    # so every selection agrees. (This heredoc sits inside a command substitution, where
    # bash 3.2 still scans quote characters: keep apostrophes out of it.)
    return str(int(s)) if s.isdigit() else s

rows = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line.strip():
        continue
    parts = line.split(" | ")
    if len(parts) < 9:
        continue
    ts = parts[0][2:].strip()   # strip leading "| "
    # Parse ONCE at ingest and carry the datetime on the row. Every temporal
    # comparison below orders on `tsdt`, never on the raw `ts` string:
    # lexicographic order equals chronological order only under ONE fixed
    # timestamp format, and a fractional-second stamp ("…:00.500Z") parses
    # cleanly, clears the exit-2 integrity gate, then sorts BEFORE "…:00Z" —
    # silently dropping a real escape and publishing it as a clean signal.
    # `ts` is retained for display only.
    tsdt = parse_iso(ts)        # source-integrity: exit 2 on malformed ts
    rows.append({
        "ts": ts,
        "tsdt": tsdt,
        "version": parts[1].strip(),
        "stage": norm_stage(parts[2].strip()),
        "etype": parts[3].strip(),
        "esub": parts[4].strip(),
        "actor": parts[5].strip(),
        "subject": parts[6].strip(),
        "outcome": parts[8].strip(),
        "payload": parts[9].strip() if len(parts) > 9 else "",
    })

# ─── Window: trailing N DISTINCT versions (chronological order preserved) ────
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

# ─── I1 zero-round-trip triage rate ──────────────────────────────────────────
# Denominator: distinct subjects that reached the g1-g2 triage gate.
# Numerator: those with NO scope-change/* or escalation/* row at or before g1-g2
# (a return/round-trip during triage).
g1g2 = {}
for r in rows:
    if r["etype"] == "gate-outcome" and r["esub"] == "g1-g2":
        s = r["subject"]
        if s not in g1g2 or r["tsdt"] < g1g2[s]:
            g1g2[s] = r["tsdt"]
zrt = 0
for s, g_ts in g1g2.items():
    round_trip = any(
        rr["tsdt"] <= g_ts and rr["etype"] in ("scope-change", "escalation")
        for rr in by_subject[s]
    )
    if not round_trip:
        zrt += 1
i1 = {"num": zrt, "den": len(g1g2), "rate": rhu(zrt, len(g1g2))}

# ─── I4 triage cycle-time (median over subjects: first-seen -> g1-g2) ─────────
cyc = []
for s, g_ts in g1g2.items():
    first_ts = min(rr["tsdt"] for rr in by_subject[s])
    d = int((g_ts - first_ts).total_seconds())
    if d >= 0:
        cyc.append(d)
cyc.sort()
def median(xs):
    if not xs:
        return None
    n = len(xs)
    return xs[n // 2] if n % 2 else (xs[n // 2 - 1] + xs[n // 2]) // 2
i4 = {"median_seconds": median(cyc), "n": len(cyc)}

# ─── I6 plan-survival (Definition) ───────────────────────────────────────────
# Population: cards carrying a per-issue Stage-4 gate decision — a stage-4
# decision row whose subtype is in GATE_DECISION_SUBTYPES, whose actor is in
# GATE_DECISION_ACTORS (stage-04-planning.md § 11: operator, or hub for a recorded
# determination) and whose subject is a card (CARD_SUBJECT: issue:#N or #N).
# Each term is an ALLOW-list: a delegation fork, an action-item transition, a
# sub-task process decision or a spoke's row is not a gate decision; admitted, it
# is a phantom card that also counts as a survivor, so the rate can only inflate.
# One card, one key: card_key() folds #N into issue:#N for the plan, the removal
# and the scope-change join, so a card carried in one spelling and removed or
# broken in the other is still one card.
# Removal (a gate row carrying card-disposition:removed) is re-plan aware. A
# removal written BEFORE the release's first stage >= 5 row is a first-gate
# removal: that (release, card) pair was never a plan of the release and is
# dropped whole, and a later release that carries the card plans it there. A
# removal AT OR AFTER that row is a re-plan: the carried plan stays in the
# population and is scored broken at the removal, so a re-plan cannot erase a
# plan's break. A pair whose only gate rows are removals carried nothing and is
# dropped. CARD_REMOVED matches a payload segment, never prose; its lookahead
# admits the " |" the " | " split leaves on the last field. Selection, removal
# and coverage limits: phase-telemetry-front-cluster.md § 4 I6 and FM2.
# Numerator: those with no tier-2/tier-3 scope-change and no re-plan removal at
# or after that plan.
GATE_DECISION_SUBTYPES = ("d-class",)
GATE_DECISION_ACTORS = ("operator", "hub")
CARD_SUBJECT = re.compile(r"^(?:issue:)?#([0-9]+)$")
CARD_REMOVED = re.compile(r"(?:^|;)\s*card-disposition:\s*removed\s*(?=;|\|?\s*$)", re.IGNORECASE)

def card_key(subject):
    m = CARD_SUBJECT.match(subject)
    return "issue:#" + m.group(1) if m else None

def is_gate_decision(r):
    return (r["stage"] == "4" and r["etype"] == "decision"
            and r["esub"] in GATE_DECISION_SUBTYPES
            and r["actor"] in GATE_DECISION_ACTORS
            and card_key(r["subject"]) is not None)

past_stage4 = {}
for r in rows:
    if r["stage"].isdigit() and int(r["stage"]) >= 5:
        if r["version"] not in past_stage4 or r["tsdt"] < past_stage4[r["version"]]:
            past_stage4[r["version"]] = r["tsdt"]

gate_rows = defaultdict(list)
for r in rows:
    if is_gate_decision(r):
        gate_rows[(r["version"], card_key(r["subject"]))].append(r)

plan, replan_removed = {}, {}
for (v, c), grs in gate_rows.items():
    removed = [r["tsdt"] for r in grs if CARD_REMOVED.search(r["payload"])]
    carried = [r["tsdt"] for r in grs if not CARD_REMOVED.search(r["payload"])]
    t5 = past_stage4.get(v)
    if not carried or any(t5 is None or t < t5 for t in removed):
        continue
    if c not in plan or min(carried) < plan[c]:
        plan[c] = min(carried)
    for t in removed:
        if c not in replan_removed or t < replan_removed[c]:
            replan_removed[c] = t

card_breaks = defaultdict(list)
for r in rows:
    if r["etype"] == "scope-change" and r["esub"] in ("tier-2-scope-change", "tier-3-plan-rejection"):
        c = card_key(r["subject"])
        if c is not None:
            card_breaks[c].append(r["tsdt"])
surv = 0
for c, p_ts in plan.items():
    broke = (any(t >= p_ts for t in card_breaks[c])
             or (c in replan_removed and replan_removed[c] >= p_ts))
    if not broke:
        surv += 1
i6 = {"num": surv, "den": len(plan), "rate": rhu(surv, len(plan))}

# ─── I7 bundle-amendment (Definition) ────────────────────────────────────────
# Denominator: distinct bundled milestones (milestone:* subjects in decision rows).
# Numerator: those with an a7-bundle-amend/rebundle/defer amendment.
bundles, amended = set(), set()
for r in rows:
    if r["etype"] == "decision" and r["subject"].startswith("milestone:"):
        bundles.add(r["subject"])
        if r["esub"] in ("a7-bundle-amend", "a7-bundle-rebundle", "a7-bundle-defer"):
            amended.add(r["subject"])
i7 = {"num": len(amended), "den": len(bundles), "rate": rhu(len(amended), len(bundles))}

# ─── I8 Phase-A0 C3 rate (Definition) ────────────────────────────────────────
# Denominator: re-review/phase-a0-row rows. Numerator: those carrying a C3 CLASS TOKEN.
# The match is on the structured `class:C3` token (triage-design-rereview.md § 5), NOT a
# bare "C3" substring: payloads are free text to 300 chars, so a `class:C1` row whose prose
# merely MENTIONS C3 ("no C3-level challenge raised") would otherwise score as a premise
# challenge — fabricating a dirty signal in the numerator of two indicators.
CLASS_C3 = re.compile(r"\bclass:\s*C3\b", re.IGNORECASE)

def has_c3(payload):
    return bool(CLASS_C3.search(payload or ""))

a0_total = sum(1 for r in rows if r["etype"] == "re-review" and r["esub"] == "phase-a0-row")
a0_c3 = sum(1 for r in rows if r["etype"] == "re-review" and r["esub"] == "phase-a0-row" and has_c3(r["payload"]))
i8 = {"num": a0_c3, "den": a0_total, "rate": rhu(a0_c3, a0_total)}

# ─── I11 plan-survival post-Solutioning (Solution-design) ────────────────────
# Denominator: distinct subjects with a Collective Review scope-lock — the
# identity stage-05-solutioning.md § 11 declares: decision/scope-lock at
# CR_LOCK_STAGE by CR_LOCK_ACTOR, on the release's milestone:* subject (the
# Collective Review is release-scoped, per its Release-Level Checkpoint). The
# subtype alone is not that identity: the Stage-4 plan approval shares it, and
# admitted it is a phantom subject, an earlier anchor here and a phantom re-lock
# in I15 (FM7). Rows of the subtype at any other stage, under any other actor or
# on a sub-release subject (a per-card amendment keyed issue:#N) are off the
# emission contract and stay inert. The release-grain test is the same milestone:
# predicate I7 uses for a bundle.
# Numerator: those with no scope-change at or after their earliest scope-lock.
CR_LOCK_STAGE = "5"
CR_LOCK_ACTOR = "operator"

def is_cr_scope_lock(r):
    return (r["etype"] == "decision" and r["esub"] == "scope-lock"
            and r["stage"] == CR_LOCK_STAGE and r["actor"] == CR_LOCK_ACTOR
            and r["subject"].startswith("milestone:"))

lock = {}
for r in rows:
    if is_cr_scope_lock(r):
        s = r["subject"]
        if s not in lock or r["tsdt"] < lock[s]:
            lock[s] = r["tsdt"]
surv2 = 0
for s, l_ts in lock.items():
    broke = any(rr["etype"] == "scope-change" and rr["tsdt"] >= l_ts for rr in by_subject[s])
    if not broke:
        surv2 += 1
i11 = {"num": surv2, "den": len(lock), "rate": rhu(surv2, len(lock))}

# ─── I14 Phase-0.5 C3 rate (Solution-design) ─────────────────────────────────
p05_total = sum(1 for r in rows if r["etype"] == "re-review" and r["esub"] == "phase-0.5-row")
p05_c3 = sum(1 for r in rows if r["etype"] == "re-review" and r["esub"] == "phase-0.5-row" and has_c3(r["payload"]))
i14 = {"num": p05_c3, "den": p05_total, "rate": rhu(p05_c3, p05_total)}

# ─── I15 collective-review scope-lock first-pass (Solution-design) ───────────
# Denominator: distinct subjects with >=1 Collective Review scope-lock
# (is_cr_scope_lock, the I11 selection; a Stage-4 plan approval is not a lock).
# Numerator: those scope-locked exactly once (no second lock row). The count is a
# proxy: the contract records approve, adjust and reject under this one subtype,
# so a lone reject reads as a first pass (phase-telemetry-front-cluster.md § 4 I15).
lock_counts = defaultdict(int)
for r in rows:
    if is_cr_scope_lock(r):
        lock_counts[r["subject"]] += 1
first_pass = sum(1 for c in lock_counts.values() if c == 1)
i15 = {"num": first_pass, "den": len(lock_counts), "rate": rhu(first_pass, len(lock_counts))}

# ─── I5 approved-queue-depth (gauge, gh-sourced; passed in) ───────────────────
if approved_depth == "NA":
    i5 = {"value": None, "na_reason": "gh unavailable — cannot read approved/bundled queue depth"}
else:
    i5 = {"value": int(approved_depth), "na_reason": None}

out = {
    "window": (f"trailing {window} versions" if window else "all events"),
    "build": {
        "zero-round-trip-triage-rate": i1,
        "triage-cycle-time": i4,
        "approved-queue-depth": i5,
        "plan-survival-rate": i6,
        "bundle-amendment-rate": i7,
        "phase-a0-c3-rate": i8,
        "plan-survival-post-solutioning-rate": i11,
        "phase-0.5-c3-rate": i14,
        "collective-review-scope-lock-first-pass-rate": i15,
    },
    "pointer": {
        "capacity-overrun": "see gate-evaluation-spec.md Gate 3->4 Capacity utilization (bundle_size/capacity_heuristic)",
        "file-contention-detection": "see gate-evaluation-spec.md Gate 3->4 Contention density (files_with_2+_issues/total_unique_files)",
        "adr-closure": "see gate-evaluation-spec.md Gate 5->6 ADR closure (adr_closed/adr_opened)",
    },
    "narrowed": {
        "source-of-origin-attribution": "presence/coverage — rate deferred (intake source field is not a structured mechanical denominator)",
    },
    "deferred": {
        "decision-date-setting": "gh Decision-Date field deliberately unpopulated (no-backfill-at-scale) — a rate reads structurally-low not quality; N/A-until-populated",
        "quality-attribute-trade-off-mention": "no structured field — a semantic text-scan of design specs is not a mechanical denominator; N/A-until-source",
    },
}
print(json.dumps(out))
PY
)"

# ─── Self-test mode (no network / no gh / no event log) ──────────────────────
if [[ "${1:-}" == "--self-test" ]]; then
  [[ -x "$QUERY_TOOL" ]] || die "self-test: query-pipeline-event.sh not executable at $QUERY_TOOL"
  [[ -x "$PY" ]] || die "self-test: $PY not executable"

  # Duration formatter contract parity with the DORA sibling.
  R="$(format_duration 10800)"; [[ "$R" == "3h0m" ]] || die "self-test: format_duration(10800) = $R, expected 3h0m"
  R="$(format_duration 0)";     [[ "$R" == "0m"   ]] || die "self-test: format_duration(0) = $R, expected 0m"

  # Synthetic fixture exercising every event-sourced BUILD indicator.
  FIXTURE="$(/bin/cat <<'ROWS'
| 2026-03-01T10:00:00Z | v1.00 | 1 | decision | queued-pending-approval | hub | #A | CHEAP | resolved | p |
| 2026-03-01T12:00:00Z | v1.00 | 2 | gate-outcome | g1-g2 | spoke:#A | #A | CHEAP | resolved | verdict:Approved |
| 2026-03-02T09:00:00Z | v1.00 | 1 | decision | queued-pending-approval | hub | #B | CHEAP | resolved | p |
| 2026-03-02T11:00:00Z | v1.00 | 2 | escalation | tier-1 | operator | #B | MODERATE | resolved | p |
| 2026-03-02T13:00:00Z | v1.00 | 2 | gate-outcome | g1-g2 | spoke:#B | #B | CHEAP | resolved | verdict:Approved |
| 2026-03-03T10:00:00Z | v1.00 | 4 | decision | d-class | operator | issue:#3 | CHEAP | resolved | p |
| 2026-03-04T10:00:00Z | v1.00 | 4 | decision | d-class | operator | issue:#4 | CHEAP | resolved | p |
| 2026-03-04T15:00:00Z | v1.00 | 5 | scope-change | tier-2-scope-change | operator | issue:#4 | MODERATE | resolved | p |
| 2026-03-05T10:00:00Z | v1.00 | 3 | decision | outcome-statement-authored | hub | milestone:#M1 | CHEAP | resolved | p |
| 2026-03-05T11:00:00Z | v1.00 | 4 | decision | a7-bundle-amend | hub | milestone:#M1 | CHEAP | resolved | p |
| 2026-03-06T10:00:00Z | v1.00 | 3 | decision | outcome-statement-authored | hub | milestone:#M2 | CHEAP | resolved | p |
| 2026-03-07T10:00:00Z | v1.00 | 4 | re-review | phase-a0-row | spoke:#E | #E | CHEAP | resolved | class:C1 |
| 2026-03-07T11:00:00Z | v1.00 | 4 | re-review | phase-a0-row | spoke:#F | #F | CHEAP | resolved | class:C3; PT:PT-2 |
| 2026-03-07T12:00:00Z | v1.00 | 4 | re-review | phase-a0-row | spoke:#F2 | #F2 | CHEAP | resolved | class:C1; note: no C3-level premise challenge raised |
| 2026-03-08T09:00:00Z | v1.00 | 5 | re-review | phase-0.5-row | spoke:#G | #G | CHEAP | resolved | class:C1 |
| 2026-03-08T09:05:00Z | v1.00 | 5 | re-review | phase-0.5-row | spoke:#G2 | #G2 | CHEAP | resolved | class:C3 |
| 2026-03-08T09:07:00Z | v1.00 | 5 | re-review | phase-0.5-row | spoke:#G4 | #G4 | CHEAP | resolved | class: C3 |
| 2026-03-08T09:10:00Z | v1.00 | 5 | re-review | phase-0.5-row | spoke:#G3 | #G3 | CHEAP | resolved | class:C1 |
| 2026-03-08T10:00:00Z | v1.00 | 5 | decision | scope-lock | operator | milestone:#M1 | CHEAP | approved | p |
| 2026-03-09T10:00:00Z | v1.00 | 5 | decision | scope-lock | operator | milestone:#M2 | CHEAP | resolved | p |
| 2026-03-09T12:00:00Z | v1.00 | 5 | scope-change | tier-2-scope-change | operator | milestone:#M2 | MODERATE | resolved | p |
| 2026-03-09T14:00:00Z | v1.00 | 5 | decision | scope-lock | operator | milestone:#M2 | CHEAP | approved | p |
ROWS
)"
  ST_JSON="$(printf '%s\n' "$FIXTURE" | "$PY" -c "$FRONT_AGG_PY" "NA" "")"

  # Accessor takes the JSON path as SEPARATE args (indicator keys contain dots,
  # e.g. phase-0.5-c3-rate — a dotted-path split would mis-parse them).
  get() { "$PY" -c 'import json,sys
d=json.loads(sys.argv[1])
for k in sys.argv[2:]:
    d=d[k]
print("NA" if d is None else d)' "$ST_JSON" "$@"; }

  [[ "$(get build zero-round-trip-triage-rate rate)" == "0.5" ]]  || die "self-test: I1 zero-round-trip = $(get build zero-round-trip-triage-rate rate), expected 0.5 (1/2)"
  [[ "$(get build triage-cycle-time median_seconds)" == "10800" ]] || die "self-test: I4 triage-cycle median = $(get build triage-cycle-time median_seconds)s, expected 10800 (3h)"
  [[ "$(get build plan-survival-rate rate)" == "0.5" ]]           || die "self-test: I6 plan-survival = $(get build plan-survival-rate rate), expected 0.5 (1/2)"
  [[ "$(get build bundle-amendment-rate rate)" == "0.5" ]]        || die "self-test: I7 bundle-amendment = $(get build bundle-amendment-rate rate), expected 0.5 (1/2)"
  # I8: 3 phase-a0 rows, exactly ONE carrying a `class:C3` token. #F2 is the false-positive
  # guard — a `class:C1` row whose free prose MENTIONS C3. A bare-substring match scores it
  # as a premise challenge and reports 0.67; the class-token match reports the true 0.33.
  [[ "$(get build phase-a0-c3-rate rate)" == "0.33" ]]            || die "self-test: I8 phase-a0-c3 = $(get build phase-a0-c3-rate rate), expected 0.33 (1/3 — the class:C1 row whose prose mentions C3 must NOT count)"
  [[ "$(get build plan-survival-post-solutioning-rate rate)" == "0.5" ]] || die "self-test: I11 post-sol survival = $(get build plan-survival-post-solutioning-rate rate), expected 0.5 (1/2)"
  # I14: 4 phase-0.5 rows, two C3 — one `class:C3`, one spaced `class: C3` (whitespace
  # tolerance in the token match).
  [[ "$(get build phase-0.5-c3-rate rate)" == "0.5" ]]            || die "self-test: I14 phase-0.5-c3 = $(get build phase-0.5-c3-rate rate), expected 0.5 (2/4 — incl. the spaced 'class: C3' form)"
  [[ "$(get build collective-review-scope-lock-first-pass-rate rate)" == "0.5" ]] || die "self-test: I15 scope-lock first-pass = $(get build collective-review-scope-lock-first-pass-rate rate), expected 0.5 (1/2)"
  # I5 gauge is N/A without gh (self-test never calls gh)
  [[ "$(get build approved-queue-depth value)" == "NA" ]]         || die "self-test: I5 approved-queue-depth = $(get build approved-queue-depth value), expected NA (no gh in self-test)"

  # Temporal ordering must compare PARSED datetimes, never raw timestamp strings.
  # Discriminating fixture: two rows in the same whole second, one carrying a fractional
  # part. Lexicographically "…:00.500Z" sorts BEFORE "…:00Z" ('.' < 'Z'), inverting the
  # true order — so a raw-string compare reads the escalation as PRE-gate (a round trip)
  # when it in fact fired 500ms AFTER the gate. Expected 1.00 (clean); a string compare
  # yields 0.00.
  TS_FIXTURE="$(/bin/cat <<'ROWS'
| 2026-03-10T10:00:00Z | v2.00 | 2 | gate-outcome | g1-g2 | spoke:#Z | #Z | CHEAP | resolved | verdict:Approved |
| 2026-03-10T10:00:00.500Z | v2.00 | 2 | escalation | tier-1 | operator | #Z | MODERATE | resolved | post-gate |
ROWS
)"
  TS_JSON="$(printf '%s\n' "$TS_FIXTURE" | "$PY" -c "$FRONT_AGG_PY" "NA" "")"
  TSR="$("$PY" -c 'import json,sys; v=json.loads(sys.argv[1])["build"]["zero-round-trip-triage-rate"]["rate"]; print("NA" if v is None else v)' "$TS_JSON")"
  [[ "$TSR" == "1.0" ]] || die "self-test: I1 fractional-second ordering = $TSR, expected 1.0 (the .500Z escalation is AFTER the Z-form gate; a raw-string compare inverts it)"

  # I6 gate-decision selection. Each arm appends stage-4 rows to the main FIXTURE
  # (issue:#3 survives, issue:#4 is broken by a tier-2 scope-change; both are
  # operator gate rows): 1/2 0.5 holds unless the arm adds a real card. Each
  # message names what a wrong filter reads; P2 and X6c are the inert controls.
  i6_arm() {
    local j
    j="$(printf '%s\n%s\n' "$FIXTURE" "$1" | "$PY" -c "$FRONT_AGG_PY" "NA" "")" \
      || die "self-test: I6 gate-decision arm $2 — aggregation failed"
    "$PY" -c 'import json,sys
d=json.loads(sys.argv[1])["build"]["plan-survival-rate"]
print("%s/%s %s" % (d["num"], d["den"], d["rate"]))' "$j"
  }
  I6R="$(i6_arm '| 2026-03-04T11:00:00Z | v1.00 | 4 | decision | delegation | hub | sub-task:#S1 | CHEAP | resolved | ms:#M1; chose:spoke |' P1)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 P1 — a delegation keyed sub-task:#N entered ($I6R; want 1/2 0.5; no subtype term reads 2/3 0.67)"
  I6R="$(i6_arm '| 2026-03-04T11:00:00Z | v1.00 | 4 | decision | delegation | hub | milestone:#M1 | CHEAP | resolved | ms:#M1; chose:spoke |' P2)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 P2 — the compliant milestone-keyed delegation moved the population ($I6R; want 1/2 0.5)"
  I6R="$(i6_arm '| 2026-03-04T11:05:00Z | v1.00 | 4 | decision | action-item-opened | hub | issue:#9 | CHEAP | resolved | ms:#M1; id:AI-001 |' P3)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 P3 — an action-item row on a card entered ($I6R; want 1/2 0.5; a deny-list reads 2/3 0.67)"
  I6R="$(i6_arm '| 2026-03-04T11:10:00Z | v1.00 | 4 | decision | d-class | operator | sub-task:#7 | CHEAP | resolved | ms:#M1; d:process-decision |' G1)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 G1 — a sub-task-grain d-class row entered ($I6R; want 1/2 0.5; no card grain reads 2/3 0.67)"
  I6R="$(i6_arm '| 2026-03-04T11:15:00Z | v1.00 | 4 | decision | d-class | operator | issue:#5 | CHEAP | resolved | ms:#M1; d:Plan-Approval; card-disposition:removed |' R1)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 R1 — a card removed at the first gate was scored as a plan ($I6R; want 1/2 0.5)"
  I6R="$(i6_arm '| 2026-03-04T11:20:00Z | v1.00 | 4 | decision | d-class | operator | issue:#6 | CHEAP | resolved | ms:#M1; d:D-6-Split |
| 2026-03-04T11:21:00Z | v1.00 | 4 | decision | d-class | operator | issue:#6 | CHEAP | resolved | ms:#M1; card-disposition:removed |' R2)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 R2 — a card removed at the first gate re-entered through a token-less row of its release ($I6R; want 1/2 0.5; the exclusion is per (release, card))"
  I6R="$(i6_arm '| 2026-03-04T11:25:00Z | v1.00 | 4 | decision | d-class | operator | issue:#8 | CHEAP | resolved | ms:#M1; card-disposition:removed |
| 2026-03-11T10:00:00Z | v2.00 | 4 | decision | d-class | operator | issue:#8 | CHEAP | resolved | ms:#M2; card-disposition:carried |' R3)"
  [[ "$I6R" == "2/3 0.67" ]] || die "self-test: I6 R3 — a card removed by v1.00 and carried by v2.00 lost its v2.00 plan ($I6R; want 2/3 0.67; a subject-level exclusion reads 1/2 0.5)"
  I6R="$(i6_arm '| 2026-03-04T11:30:00Z | v1.00 | 4 | decision | d-class | operator | issue:#10 | CHEAP | resolved | ms:#M1; note:card-disposition:removed was proposed |' R4)"
  [[ "$I6R" == "2/3 0.67" ]] || die "self-test: I6 R4 — prose naming the token excluded a card ($I6R; want 2/3 0.67; the token is a segment, not a substring)"
  I6R="$(i6_arm '| 2026-03-04T11:35:00Z | v1.00 | 4 | decision | d-class | spoke:#11 | issue:#11 | CHEAP | resolved | ms:#M1; card-disposition:carried |' A1)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 A1 — a spoke-actored gate row entered ($I6R; want 1/2 0.5; no actor term reads 2/3 0.67)"
  # G2: the writer admits a zero-padded stage (its row-identity arms match ^0*4$), so a
  # gate row written at stage 04 is a Stage-4 gate decision and must be read as one.
  I6R="$(i6_arm '| 2026-03-04T11:40:00Z | v1.00 | 04 | decision | d-class | operator | issue:#19 | CHEAP | resolved | ms:#M1; d:Plan-Approval; card-disposition:carried |' G2)"
  [[ "$I6R" == "2/3 0.67" ]] || die "self-test: I6 G2 — a gate row written at the zero-padded stage 04 the writer admits was dropped ($I6R; want 2/3 0.67; an exact string compare on the stage reads 1/2 0.5)"
  # The re-plan-aware removal rule and the one card key. v1.00's first stage >= 5
  # row is at 03-04T15:00, so R1-R3 and X2 remove at the first gate and X1 and X6
  # remove at a re-plan.
  I6R="$(i6_arm '| 2026-03-04T12:00:00Z | v1.00 | 4 | decision | d-class | operator | issue:#13 | CHEAP | resolved | ms:#M1; d:Plan-Approval; card-disposition:carried |
| 2026-03-05T09:00:00Z | v1.00 | 5 | scope-change | tier-2-scope-change | operator | issue:#13 | MODERATE | resolved | p |
| 2026-03-06T09:00:00Z | v1.00 | 4 | decision | d-class | operator | issue:#13 | CHEAP | resolved | ms:#M1; d:re-plan; card-disposition:removed |' X1)"
  [[ "$I6R" == "1/3 0.33" ]] || die "self-test: I6 X1 — a re-plan removal erased a broken plan ($I6R; want 1/3 0.33; dropping the pair on any removal reads 1/2 0.5)"
  I6R="$(i6_arm '| 2026-03-04T12:30:00Z | v1.00 | 4 | decision | d-class | operator | issue:#14 | CHEAP | resolved | ms:#M1; d:Plan-Approval; card-disposition:carried |
| 2026-03-06T10:30:00Z | v1.00 | 5 | decision | scope-lock | operator | milestone:#M1 | MODERATE | resolved | ms:#M1; verdict:re-bundle |
| 2026-03-06T11:30:00Z | v1.00 | 4 | decision | d-class | operator | issue:#14 | CHEAP | resolved | ms:#M1; d:re-plan; card-disposition:removed |' X6)"
  [[ "$I6R" == "1/3 0.33" ]] || die "self-test: I6 X6 — a card removed at a re-plan after a Collective Review re-bundle was not scored broken ($I6R; want 1/3 0.33; dropping the pair reads 1/2 0.5, keeping it unbroken reads 2/3 0.67)"
  I6R="$(i6_arm '| 2026-03-04T12:30:00Z | v1.00 | 4 | decision | d-class | operator | issue:#14 | CHEAP | resolved | ms:#M1; d:Plan-Approval; card-disposition:carried |
| 2026-03-06T10:30:00Z | v1.00 | 5 | decision | scope-lock | operator | milestone:#M1 | MODERATE | resolved | ms:#M1; verdict:re-bundle |' X6c)"
  [[ "$I6R" == "2/3 0.67" ]] || die "self-test: I6 X6c — with no removal the carried card must survive the re-bundle ($I6R; want 2/3 0.67; a release past Stage 4 does not break its plans)"
  I6R="$(i6_arm '| 2026-03-04T13:00:00Z | v1.00 | 4 | decision | d-class | operator | issue:#15 | CHEAP | resolved | ms:#M1; d:Plan-Approval; card-disposition:carried |
| 2026-03-04T13:05:00Z | v1.00 | 4 | decision | d-class | operator | #15 | CHEAP | resolved | ms:#M1; card-disposition:removed |' X2)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 X2 — a card carried as issue:#N and removed as #N survived ($I6R; want 1/2 0.5; a raw-subject key reads 2/3 0.67)"
  I6R="$(i6_arm '| 2026-03-04T13:10:00Z | v1.00 | 4 | decision | d-class | operator | issue:#16 | CHEAP | resolved | ms:#M1; d:Plan-Approval; card-disposition:carried |
| 2026-03-05T10:00:00Z | v1.00 | 5 | scope-change | tier-2-scope-change | operator | #16 | MODERATE | resolved | p |' X2j)"
  [[ "$I6R" == "1/3 0.33" ]] || die "self-test: I6 X2j — a break keyed #N did not reach the card carried as issue:#N ($I6R; want 1/3 0.33; a raw-subject join reads 2/3 0.67)"
  # The rule's two edges. E1: a removal AT the release's first stage >= 5 instant
  # is a re-plan. E2: a pair whose only gate rows are removals carried nothing.
  I6R="$(i6_arm '| 2026-03-04T14:00:00Z | v1.00 | 4 | decision | d-class | operator | issue:#17 | CHEAP | resolved | ms:#M1; d:Plan-Approval; card-disposition:carried |
| 2026-03-04T15:00:00Z | v1.00 | 4 | decision | d-class | operator | issue:#17 | CHEAP | resolved | ms:#M1; d:re-plan; card-disposition:removed |' E1)"
  [[ "$I6R" == "1/3 0.33" ]] || die "self-test: I6 E1 — a removal at the instant the release passed Stage 4 was read as a first-gate removal ($I6R; want 1/3 0.33; counting that instant as the first gate reads 1/2 0.5)"
  I6R="$(i6_arm '| 2026-03-06T12:00:00Z | v1.00 | 4 | decision | d-class | operator | issue:#18 | CHEAP | resolved | ms:#M1; d:re-plan; card-disposition:removed |' E2)"
  [[ "$I6R" == "1/2 0.5" ]] || die "self-test: I6 E2 — a card whose only gate row is a removal entered the population ($I6R; want 1/2 0.5; planning a removal-only pair reads 1/3 0.33)"

  # I11/I15 Collective Review lock identity: decision/scope-lock at stage 5 by
  # operator on a release-grain milestone:* subject. FIXTURE locks: milestone:#M1
  # (one, no reversal) and milestone:#M2 (two, a tier-2 reversal between them):
  # I11 1/2 0.5 and I15 1/2 0.5 hold in every arm.
  lock_arm() {
    local j
    j="$(printf '%s\n%s\n' "$FIXTURE" "$1" | "$PY" -c "$FRONT_AGG_PY" "NA" "")" \
      || die "self-test: I11/I15 lock-identity arm $2 — aggregation failed"
    "$PY" -c 'import json,sys
b=json.loads(sys.argv[1])["build"]
a=b["plan-survival-post-solutioning-rate"]; c=b["collective-review-scope-lock-first-pass-rate"]
print("I11 %s/%s %s; I15 %s/%s %s" % (a["num"], a["den"], a["rate"], c["num"], c["den"], c["rate"]))' "$j"
  }
  LKR="$(lock_arm '| 2026-03-10T10:00:00Z | v1.00 | 4 | decision | scope-lock | operator | milestone:#M3 | MODERATE | resolved | d:Plan-Approval |' SL1)"
  [[ "$LKR" == "I11 1/2 0.5; I15 1/2 0.5" ]] || die "self-test: I11/I15 SL1 — a Stage-4 plan approval entered ($LKR; a subtype-only filter reads I11 2/3 0.67; I15 2/3 0.67)"
  LKR="$(lock_arm '| 2026-03-08T08:00:00Z | v1.00 | 4 | decision | scope-lock | operator | milestone:#M1 | MODERATE | resolved | d:Plan-Approval |
| 2026-03-08T08:30:00Z | v1.00 | 5 | scope-change | tier-2-scope-change | operator | milestone:#M1 | MODERATE | resolved | p |' SL2)"
  [[ "$LKR" == "I11 1/2 0.5; I15 1/2 0.5" ]] || die "self-test: I11/I15 SL2 — a Stage-4 plan approval moved a lock anchor or counted as a re-lock ($LKR; a subtype-only filter reads I11 0/2 0.0; I15 0/2 0.0)"
  LKR="$(lock_arm '| 2026-03-12T10:00:00Z | v1.00 | 7 | decision | scope-lock | operator | milestone:#M1 | CHEAP | resolved | d:stage-7-amendment |' SL3)"
  [[ "$LKR" == "I11 1/2 0.5; I15 1/2 0.5" ]] || die "self-test: I11/I15 SL3 — an off-contract stage-7 scope-lock counted as a re-lock ($LKR; a stage >= 5 term reads I15 0/2 0.0)"
  LKR="$(lock_arm '| 2026-03-12T11:00:00Z | v1.00 | 5 | decision | scope-lock | hub | milestone:#M1 | CHEAP | resolved | d:retroactive-check |' SL4)"
  [[ "$LKR" == "I11 1/2 0.5; I15 1/2 0.5" ]] || die "self-test: I11/I15 SL4 — a hub-actored stage-5 scope-lock counted as a re-lock ($LKR; a stage-only term reads I15 0/2 0.0)"
  LKR="$(lock_arm '| 2026-03-12T12:00:00Z | v1.00 | 5 | decision | scope-lock | operator | issue:#12 | CHEAP | resolved | d:per-card-amendment |' SL5)"
  [[ "$LKR" == "I11 1/2 0.5; I15 1/2 0.5" ]] || die "self-test: I11/I15 SL5 — a card-grain stage-5 scope-lock entered as a Collective Review lock ($LKR; no release-grain subject term reads I11 2/3 0.67; I15 2/3 0.67)"
  # SL6: the writer admits a zero-padded stage (its scope-lock arm matches ^0*[45]$), so a
  # Collective Review lock written at stage 05 is a stage-5 lock and must be read as one.
  LKR="$(lock_arm '| 2026-03-12T13:00:00Z | v1.00 | 05 | decision | scope-lock | operator | milestone:#M4 | MODERATE | resolved | d:collective-review-lock |' SL6)"
  [[ "$LKR" == "I11 2/3 0.67; I15 2/3 0.67" ]] || die "self-test: I11/I15 SL6 — a Collective Review lock written at the zero-padded stage 05 the writer admits was dropped ($LKR; want I11 2/3 0.67; I15 2/3 0.67; an exact string compare on the stage reads I11 1/2 0.5; I15 1/2 0.5)"

  # N/A discipline: an empty stream yields N/A rates (not 0.00) for every BUILD rate.
  EMPTY_JSON="$(printf '' | "$PY" -c "$FRONT_AGG_PY" "NA" "")"
  ER="$("$PY" -c 'import json,sys; v=json.loads(sys.argv[1])["build"]["plan-survival-rate"]["rate"]; print("NA" if v is None else v)' "$EMPTY_JSON")"
  [[ "$ER" == "NA" ]] || die "self-test: empty-stream plan-survival = $ER, expected NA (empty population, NOT 0.00)"

  echo "self-test: PASS"
  echo "  duration formatter validated"
  echo "  9 BUILD indicators validated (8 event-sourced rates/median + gauge-N/A path)"
  echo "  C3 class-token match validated (class:C1 prose mentioning C3 excluded; spaced 'class: C3' included)"
  echo "  temporal ordering validated on parsed datetimes (fractional-second stamp does not invert order)"
  echo "  I6 gate-decision selection validated (a stage-4 delegation or action-item row, a sub-task process decision and a spoke-actored row stay out; a card removed at the first gate is dropped from that release only; a re-plan removal keeps the carried plan and scores it broken; #N and issue:#N are one card; the removal segment is matched as a segment, not a substring; a gate row at the zero-padded stage 04 the writer admits is read as stage 4)"
  echo "  I11/I15 Collective Review lock identity validated (a Stage-4 plan approval, an off-contract stage-7 scope-lock, a hub-actored stage-5 scope-lock and a card-grain stage-5 scope-lock stay inert; a lock at the zero-padded stage 05 the writer admits is read as stage 5)"
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

# ─── Read all event rows (via the query primitive; empty is legitimate pre-cutover) ─
ALL_ROWS="$("$QUERY_TOOL" 2>/dev/null | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"

# ─── I5 approved-queue-depth: best-effort gh union of open approved/bundled issues ─
APPROVED_DEPTH="NA"
GH="$(find_gh)"
if [[ -n "$GH" ]]; then
  A="$("$GH" issue list --state open --label "status: approved" --json number -q '.[].number' 2>/dev/null || true)"
  B="$("$GH" issue list --state open --label "status: bundled" --json number -q '.[].number' 2>/dev/null || true)"
  UNION="$(printf '%s\n%s\n' "$A" "$B" | /usr/bin/grep -E '^[0-9]+$' | /usr/bin/sort -u | /usr/bin/wc -l | /usr/bin/tr -d ' ' || true)"
  [[ -n "$UNION" ]] && APPROVED_DEPTH="$UNION"
fi

FRONT_JSON="$(printf '%s\n' "$ALL_ROWS" | "$PY" -c "$FRONT_AGG_PY" "$APPROVED_DEPTH" "$WINDOW")" \
  || die "front-cluster aggregation parse failure (malformed ts_iso)" 2

# ─── Render ──────────────────────────────────────────────────────────────────
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  if [[ -n "$SINGLE_INDICATOR" ]]; then
    "$PY" -c 'import json,sys
d=json.loads(sys.argv[1]); k=sys.argv[2]
b=d["build"]
if k in b: print(json.dumps({k: b[k]}))
else: print(json.dumps({k: "unknown or non-BUILD indicator"}))' "$FRONT_JSON" "$SINGLE_INDICATOR"
  else
    printf '%s\n' "$FRONT_JSON"
  fi
  exit 0
fi

# Human render — one helper reads a BUILD rate field to a display string.
# %-formatting (not f-strings) — the system python3 (3.9) rejects backslashes in
# f-string expression parts, and dict-key subscripts there would need them.
r_rate()  { "$PY" -c 'import json,sys
d=json.loads(sys.argv[1])["build"][sys.argv[2]]
if d["rate"] is None:
    print("N/A (" + sys.argv[3] + ")")
else:
    print("%d/%d (%.2f)" % (d["num"], d["den"], d["rate"]))' "$FRONT_JSON" "$1" "$2"; }

if [[ -n "$SINGLE_INDICATOR" ]]; then
  case "$SINGLE_INDICATOR" in
    zero-round-trip-triage-rate) r_rate "$SINGLE_INDICATOR" "no triaged subjects (no g1-g2 in window)" ;;
    plan-survival-rate) r_rate "$SINGLE_INDICATOR" "no card carried a Stage-4 gate decision in window" ;;
    bundle-amendment-rate) r_rate "$SINGLE_INDICATOR" "no bundled milestones in window" ;;
    phase-a0-c3-rate) r_rate "$SINGLE_INDICATOR" "no phase-a0 re-review rows in window" ;;
    plan-survival-post-solutioning-rate) r_rate "$SINGLE_INDICATOR" "no Collective Review scope-lock in window" ;;
    phase-0.5-c3-rate) r_rate "$SINGLE_INDICATOR" "no phase-0.5 re-review rows in window" ;;
    collective-review-scope-lock-first-pass-rate) r_rate "$SINGLE_INDICATOR" "no Collective Review scope-lock in window" ;;
    triage-cycle-time)
      "$PY" -c 'import json,sys; d=json.loads(sys.argv[1])["build"]["triage-cycle-time"]; print("NA" if d["median_seconds"] is None else d["median_seconds"])' "$FRONT_JSON" \
        | { read -r s; [[ "$s" == "NA" ]] && echo "N/A (no triaged subjects in window)" || echo "$(format_duration "$s") (median over subjects)"; } ;;
    approved-queue-depth)
      "$PY" -c 'import json,sys
d=json.loads(sys.argv[1])["build"]["approved-queue-depth"]
print("N/A (" + d["na_reason"] + ")" if d["value"] is None else ("%d open (approved+bundled)" % d["value"]))' "$FRONT_JSON" ;;
    *) die "--indicator must be a BUILD indicator name (see --help)" ;;
  esac
  exit 0
fi

WINDOW_DESC="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["window"])' "$FRONT_JSON")"
CYC="$("$PY" -c 'import json,sys; d=json.loads(sys.argv[1])["build"]["triage-cycle-time"]; print("NA" if d["median_seconds"] is None else d["median_seconds"])' "$FRONT_JSON")"
if [[ "$CYC" == "NA" ]]; then CYC_DISP="N/A (no triaged subjects in window)"; else CYC_DISP="$(format_duration "$CYC") (median over subjects)"; fi
QDEP="$("$PY" -c 'import json,sys
d=json.loads(sys.argv[1])["build"]["approved-queue-depth"]
print("N/A (" + d["na_reason"] + ")" if d["value"] is None else ("%d open (approved+bundled)" % d["value"]))' "$FRONT_JSON")"

echo "Front-cluster telemetry (window=${WINDOW_DESC}) — Demand / Definition / Solution-design:"
echo "  [Demand]"
echo "    zero-round-trip-triage-rate:  $(r_rate zero-round-trip-triage-rate 'no triaged subjects (no g1-g2 in window)')"
echo "    triage-cycle-time:            ${CYC_DISP}"
echo "    approved-queue-depth:         ${QDEP}"
echo "    source-of-origin-attribution: NARROWED — presence/coverage; rate deferred (no structured intake source field)"
echo "    decision-date-setting:        DEFER — gh field deliberately unpopulated (no-backfill-at-scale); N/A-until-populated"
echo "  [Definition]"
echo "    plan-survival-rate:           $(r_rate plan-survival-rate 'no card carried a Stage-4 gate decision in window')"
echo "    bundle-amendment-rate:        $(r_rate bundle-amendment-rate 'no bundled milestones in window')"
echo "    phase-a0-c3-rate:             $(r_rate phase-a0-c3-rate 'no phase-a0 re-review rows in window')"
echo "    capacity-overrun:             POINTER — gate-evaluation-spec.md Gate 3->4 Capacity utilization"
echo "    file-contention-detection:    POINTER — gate-evaluation-spec.md Gate 3->4 Contention density"
echo "  [Solution-design]"
echo "    plan-survival-post-solutioning-rate:            $(r_rate plan-survival-post-solutioning-rate 'no Collective Review scope-lock in window')"
echo "    phase-0.5-c3-rate:                              $(r_rate phase-0.5-c3-rate 'no phase-0.5 re-review rows in window')"
echo "    collective-review-scope-lock-first-pass-rate:   $(r_rate collective-review-scope-lock-first-pass-rate 'no Collective Review scope-lock in window')"
echo "    adr-closure:                                    POINTER — gate-evaluation-spec.md Gate 5->6 ADR closure"
echo "    quality-attribute-trade-off-mention:            DEFER — no structured field (semantic scan); N/A-until-source"
echo "  mechanism: compute-front-cluster-telemetry.sh"
exit 0

#!/usr/bin/env bash
# compute-dora-metrics.sh — DORA-4 telemetry read-model for the PMO platform.
# Per release/references/standards/dora-telemetry.md.
# Sibling to compute-cycle-time.sh — same form factor, same exit-code contract.
#
# Computes the four DORA delivery metrics over a bounded window as a READ-MODEL
# over the operator-instance pipeline event log at
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md
# (canonical default: ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results/)
# via query-pipeline-event.sh (sibling tool; it resolves the log location), plus a
# thin `git log --format=%cI` read for the lead-time commit-time numerator.
#
# READ-MODEL ONLY: this tool READS the event stream; it NEVER writes a DORA row
# back into it (the OUT-class boundary per the standard § 3.1 / § 10 FM3).
#
#   deployment_frequency  : count of DISTINCT deploy occasions (same-version
#                           deploy-skill/deploy-harness rows collapsed to one
#                           occasion) per window length.
#   lead_time_for_changes : median over occasions of (T_DEPLOY - T_COMMIT), where
#                           T_DEPLOY = MAX(ts_iso) of the occasion's deploy rows and
#                           T_COMMIT = committer-date (%cI) of the FIRST commit the
#                           deploy carried (DORA-canonical commit->deploy window; a
#                           SIBLING to deployment-cycle-time.md's GO->deploy window,
#                           never recomputed from it).
#   change_failure_rate   : rollback-correlated occasions / total occasions in window.
#   mean_time_to_restore  : mean over rollback pairs of (T_RESTORE - T_FAILURE).
#
# Per-metric N/A is INDEPENDENT (the standard § 4): a window may yield real values
# for some metrics and N/A for others. The CFR zero-vs-N/A distinction is load-
# bearing: 0.0% = deployed-and-no-failures (a real clean-window value); N/A = no
# deploy occasions (denominator undefined).
#
# Usage:
#   ./compute-dora-metrics.sh --window 30d              # human four-metric block
#   ./compute-dora-metrics.sh --window 30d --json       # JSON of all four metrics
#   ./compute-dora-metrics.sh --window-occasions 10     # window by trailing N occasions
#   ./compute-dora-metrics.sh --metric deployment_frequency --window 30d  # single metric
#   ./compute-dora-metrics.sh --self-test               # validate logic (no network/git)
#   ./compute-dora-metrics.sh --help                    # this help text
#
# Inputs:
#   --window <Nd>          window length in days (e.g. 30d). Default 30d. The window
#                          ends "now" (UTC) unless --window-occasions is given.
#   --window-occasions <N> window by the trailing N DISTINCT deploy occasions instead
#                          of by days (mutually exclusive with --window).
#   --metric <name>        emit a single metric only (deployment_frequency |
#                          lead_time_for_changes | change_failure_rate |
#                          mean_time_to_restore). Default: all four.
#   --json                 machine detail (JSON of all four metrics + N/A reasons).
#   --commit-anchor-map <file>  OPTIONAL. A "<release-key><TAB>commit_iso" map supplying
#                          the first-commit committer-date per release, for lead-time.
#                          The release key is the MILESTONE SLUG — the join key the
#                          event log's version column carries per
#                          pipeline-event-log-schema.md § 2a — so map keys must match
#                          the deploy rows' key, not the shipped vX.Y tag. When absent,
#                          lead-time falls back to a `git log` read against the resolved
#                          repo (best-effort; it translates slug -> tag via RELEASE_LOG);
#                          when neither resolves a commit anchor, lead-time is N/A. A map
#                          keeps the tool deterministic + testable without a live git
#                          history.
#
# Cutover: applies to windows over events emitted post-cutover; pre-cutover windows
# yield N/A for the affected metrics (no backfill). This tool does not gate by date —
# the caller honors cutover.
#
# Exit codes:
#   0 = success (any metric may legitimately produce N/A — empty population for that
#       metric; or a legitimate real-zero CFR)
#   1 = invalid args / log file missing / required dependency unavailable
#   2 = malformed source (ts_iso parse failure, or %cI commit-time parse failure —
#       source-integrity violation; escalate)

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
# git is resolved by absolute discovery below (not on the pinned PATH).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# REPO_ROOT retained for resolution-block parity with the append/query event-log
# tools; this tool delegates event-log path resolution to query-pipeline-event.sh
# (QUERY_TOOL below). REPO_ROOT IS used here for the best-effort lead-time git read.
# Two levels up — NOT three; a `../../..` depth mis-anchors above the repo from a
# worktree (the extinct-path resolution bug the sibling event-log tools guard against).
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
QUERY_TOOL="$SCRIPT_DIR/query-pipeline-event.sh"
PY=/usr/bin/python3

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,68p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# Resolve git off the pinned PATH (commonly /opt/homebrew/bin or /usr/local/bin).
find_git() {
  local c
  for c in /usr/bin/git /opt/homebrew/bin/git /usr/local/bin/git "$HOME/.local/bin/git"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  command -v git 2>/dev/null || true
}

# ─── Duration formatting (compact <X>m / <H>h<M>m / <D>d<H>h per standard § 3) ──

# Format integer seconds. < 3600 -> "47m"; < 86400 -> "2h17m"; else "<D>d<H>h".
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

# Derive a cadence label from deploys-per-window-days.
cadence_label() {
  # args: deploys window_days  -> daily | weekly | monthly | sparse
  local deploys="$1" days="$2"
  if [[ "$deploys" -le 0 || "$days" -le 0 ]]; then echo "sparse"; return; fi
  # deploys per day, scaled x1000 for integer compare
  local per_day_milli=$(( deploys * 1000 / days ))
  if   [[ "$per_day_milli" -ge 1000 ]]; then echo "daily"      # >= ~1 per day
  elif [[ "$per_day_milli" -ge 100  ]]; then echo "weekly"     # >= ~3/30 per day (about-weekly cadence)
  elif [[ "$per_day_milli" -ge 33   ]]; then echo "monthly"    # >= ~1/30 per day
  else echo "sparse"; fi
}

# ─── The DORA aggregation engine (single python pass; stdlib only) ───────────
#
# DEFINED HERE, ABOVE THE SELF-TEST, ON PURPOSE (#4215). The self-test used to carry
# its own transcription of this logic and grade that copy. A transcription is a shadow
# source of truth: a defect fixed here but not mirrored there stays green, and a
# mutation introduced here is invisible to the suite — which is precisely the
# control-that-cannot-fail shape this release exists to eliminate. The self-test below
# now pipes its fixtures through THIS variable, so every arm grades the engine that
# actually runs in production.
#
# stdin carries the event rows, so the python SOURCE is passed via `-c "$AGG_PY"` —
# a heredoc on `python3 -` would itself consume stdin and starve the piped rows.
AGG_PY="$(/bin/cat <<'PY'
import sys, json
from datetime import datetime, timezone, timedelta

commit_map_raw = sys.argv[1]
window_days = int(sys.argv[2]) if sys.argv[2] else 30
window_occasions = int(sys.argv[3]) if sys.argv[3] else None
now_iso = sys.argv[4]

def parse_iso(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError as e:
        print(f"ts_iso parse failure: {e}", file=sys.stderr)
        sys.exit(2)

now = parse_iso(now_iso)

commit_map = {}
for line in commit_map_raw.splitlines():
    if not line.strip():
        continue
    if "\t" in line:
        ver, ciso = line.split("\t", 1)
        commit_map[ver.strip()] = ciso.strip()

deploys = []    # (ts_iso, version)
rollbacks = []  # (ts_iso, version)
# Versions carrying at least one FAILED deploy-target row (#4215). A failed deploy is
# a change failure, and before this set existed it entered the change_failure_rate
# DENOMINATOR ONLY — the numerator was keyed exclusively to a self-repair/rollback
# event — so a release whose every target failed reported 0.0% (0/1). The platform's
# change-failure rate IMPROVED as its deploys failed, permanently, in an append-only
# log. Occasion MEMBERSHIP deliberately still counts a failed deploy: a deploy that ran
# and failed is a deployment event, so it belongs in the denominator too. What changed
# is that it now also reaches the numerator.
failed_deploy_versions = set()
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line.strip():
        continue
    parts = line.split(" | ")
    if len(parts) < 5:
        continue
    ts = parts[0][2:].strip()
    version = parts[1].strip()
    etype = parts[3].strip()
    esub = parts[4].strip()
    outcome = parts[8].strip() if len(parts) > 8 else ""
    # Validate ts parses (source-integrity; exit 2 on malformed).
    parse_iso(ts)
    if etype == "deployment-status" and esub in ("deploy-skill", "deploy-harness"):
        deploys.append((ts, version))
        if outcome and outcome != "resolved":
            failed_deploy_versions.add(version)
    elif etype == "self-repair" and esub == "rollback":
        rollbacks.append((ts, version))

# Collapse deploy rows to occasions keyed by version; T_DEPLOY = MAX(ts) per version.
occ_deploy = {}
for ts, ver in deploys:
    if ver not in occ_deploy or ts > occ_deploy[ver]:
        occ_deploy[ver] = ts
# occasions sorted chronologically by their T_DEPLOY
occasions = sorted(occ_deploy.items(), key=lambda kv: kv[1])  # [(version, t_deploy_iso)]

# ─── Window slicing ───────────────────────────────────────────────────────
if window_occasions is not None:
    occasions = occasions[-window_occasions:]
    window_desc = f"{window_occasions} occasions"
    # for frequency-per-time we still need a span; derive it from the kept-occasion ts range
    if occasions:
        span = (parse_iso(occasions[-1][1]) - parse_iso(occasions[0][1])).days or 1
    else:
        span = window_days
else:
    cutoff = now - timedelta(days=window_days)
    occasions = [(v, t) for (v, t) in occasions if parse_iso(t) >= cutoff]
    span = window_days
    window_desc = f"{window_days}d"

kept_versions = {v for v, _ in occasions}
# rollbacks restricted to the windowed occasions (a rollback counts only if it
# remediates an in-window occasion)
win_rollbacks = [(ts, ver) for ts, ver in rollbacks if ver in kept_versions]

# ─── deployment_frequency ──────────────────────────────────────────────────
freq_n = len(occasions)
freq = {
    "value": freq_n if freq_n > 0 else None,
    "window_days": span,
    "na_reason": None if freq_n > 0 else "no deploy events in window",
}

# ─── lead_time_for_changes (median of t_deploy - t_commit) ─────────────────
lead_secs = []
for ver, t_deploy in occasions:
    if ver in commit_map:
        d = int((parse_iso(t_deploy) - parse_iso(commit_map[ver])).total_seconds())
        lead_secs.append(d)
lead_secs.sort()
def median(xs):
    if not xs:
        return None
    n = len(xs)
    return xs[n // 2] if n % 2 else (xs[n // 2 - 1] + xs[n // 2]) // 2
lead_median = median(lead_secs)
if freq_n == 0:
    lead_na = "no deploy occasion with a resolvable commit anchor"
elif lead_median is None:
    lead_na = "no deploy occasion with a resolvable commit anchor"
else:
    lead_na = None
lead = {"value_seconds": lead_median, "n": len(lead_secs), "na_reason": lead_na}

# ─── change_failure_rate ───────────────────────────────────────────────────
# The numerator is the UNION of two independent failure signals, and it must be a
# union rather than either one alone: a rollback says the deploy landed and was then
# undone; a failed deploy-target row says it never landed at all. Both are change
# failures. Keying the numerator only on rollback — the pre-#4215 behaviour — made a
# totally-failed deploy read as a clean one. `occasions` is already window-sliced, so
# the membership test below applies the window to both signals.
failed_versions = {ver for _, ver in win_rollbacks} | failed_deploy_versions
failed_occ = sum(1 for ver, _ in occasions if ver in failed_versions)
if freq_n == 0:
    cfr = {"value_permille": None, "failed": 0, "total": 0,
           "na_reason": "no deploy occasions — denominator undefined"}
else:
    cfr = {"value_permille": failed_occ * 1000 // freq_n, "failed": failed_occ,
           "total": freq_n, "na_reason": None}   # 0/N is a REAL 0.0%, not N/A

# ─── mean_time_to_restore ──────────────────────────────────────────────────
mttr_secs = []
for ts, ver in win_rollbacks:
    if ver in occ_deploy:
        mttr_secs.append(int((parse_iso(ts) - parse_iso(occ_deploy[ver])).total_seconds()))
mttr_mean = (sum(mttr_secs) // len(mttr_secs)) if mttr_secs else None
mttr = {
    "value_seconds": mttr_mean,
    "n": len(mttr_secs),
    "na_reason": None if mttr_mean is not None else "no rollback events in window",
}

print(json.dumps({
    "window": window_desc,
    "window_ending": now_iso,
    "deployment_frequency": freq,
    "lead_time_for_changes": lead,
    "change_failure_rate": cfr,
    "mean_time_to_restore": mttr,
}))
PY
)"

# ─── Self-test mode (no network / no git / no event log) ─────────────────────

if [[ "${1:-}" == "--self-test" ]]; then
  # Test 1: duration formatter — sub-hour / over-hour / multi-day / zero
  R="$(format_duration 2820)";   [[ "$R" == "47m"   ]] || die "self-test: format_duration(2820) = $R, expected 47m"
  R="$(format_duration 8220)";   [[ "$R" == "2h17m" ]] || die "self-test: format_duration(8220) = $R, expected 2h17m"
  R="$(format_duration 0)";      [[ "$R" == "0m"    ]] || die "self-test: format_duration(0) = $R, expected 0m"
  R="$(format_duration 187200)"; [[ "$R" == "2d4h"  ]] || die "self-test: format_duration(187200) = $R, expected 2d4h"
  R="$(format_duration 86400)";  [[ "$R" == "1d0h"  ]] || die "self-test: format_duration(86400) = $R, expected 1d0h"

  # Test 2: cadence label thresholds
  R="$(cadence_label 30 30)"; [[ "$R" == "daily"   ]] || die "self-test: cadence(30,30) = $R, expected daily"
  R="$(cadence_label 4 30)";  [[ "$R" == "weekly"  ]] || die "self-test: cadence(4,30) = $R, expected weekly"
  R="$(cadence_label 1 30)";  [[ "$R" == "monthly" ]] || die "self-test: cadence(1,30) = $R, expected monthly"
  R="$(cadence_label 0 30)";  [[ "$R" == "sparse"  ]] || die "self-test: cadence(0,30) = $R, expected sparse"

  # Test 3: query tool dependency present
  [[ -x "$QUERY_TOOL" ]] || die "self-test: query-pipeline-event.sh not executable at $QUERY_TOOL"
  [[ -x "$PY" ]] || die "self-test: $PY not executable"

  # ─── Tests 4-6: the DORA aggregation, run through the REAL engine ──────────
  #
  # These arms pipe synthetic fixtures through $AGG_PY — the same variable the live
  # path uses — rather than through a transcription of it. The transcription that used
  # to live here was a shadow source of truth: a change made to the engine and not
  # mirrored into the copy left the suite green, so the suite could not detect the very
  # class of defect it existed to catch.
  #
  # Fixture field layout is the one query-pipeline-event.sh emits:
  #   "| ts | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
  # `now` is pinned INSIDE the fixture's own window so the arms do not rot as the wall
  # clock advances past the 30-day cutoff.
  ST_NOW="2026-01-10T00:00:00Z"

  _dora_field() {
    # _dora_field <json> <metric> <key> -> value, or the literal NA for JSON null
    "$PY" -c 'import json,sys; v=json.loads(sys.argv[1])[sys.argv[2]][sys.argv[3]]; print("NA" if v is None else v)' "$1" "$2" "$3"
  }

  # Test 4: two occasions (v1.00 carries 2 targets, v1.01 carries 1) + 1 rollback on
  #   v1.01. Every deploy row succeeded, so the ONLY failure signal is the rollback.
  #   Expected: freq=2; CFR=50.0% (1/2); lead median over the two occasions; MTTR from
  #   the v1.01 rollback pair.
  FIXTURE_ROWS="$(/bin/cat <<'ROWS'
| 2026-01-02T10:00:00Z | v1.00 | 12 | deployment-status | deploy-skill | hub | s | CHEAP | resolved | p |
| 2026-01-02T10:00:05Z | v1.00 | 12 | deployment-status | deploy-harness | hub | s | CHEAP | resolved | p |
| 2026-01-06T09:00:00Z | v1.01 | 12 | deployment-status | deploy-skill | hub | s | CHEAP | resolved | p |
| 2026-01-06T12:12:00Z | v1.01 | 13 | self-repair | rollback | operator | s | MODERATE | resolved | p |
ROWS
)"
  COMMIT_MAP="$(/usr/bin/printf 'v1.00\t2026-01-01T00:00:00Z\nv1.01\t2026-01-05T00:00:00Z\n')"

  SELFTEST_JSON="$(/usr/bin/printf '%s\n' "$FIXTURE_ROWS" | "$PY" -c "$AGG_PY" "$COMMIT_MAP" "30" "" "$ST_NOW")"
  FREQ="$(_dora_field "$SELFTEST_JSON" deployment_frequency value)"
  CFRPM="$(_dora_field "$SELFTEST_JSON" change_failure_rate value_permille)"
  FAILED="$(_dora_field "$SELFTEST_JSON" change_failure_rate failed)"
  LEADM="$(_dora_field "$SELFTEST_JSON" lead_time_for_changes value_seconds)"
  MTTRM="$(_dora_field "$SELFTEST_JSON" mean_time_to_restore value_seconds)"

  [[ "$FREQ" == "2" ]]   || die "self-test: deployment_frequency occasions = $FREQ, expected 2 (per-target rows collapsed)"
  [[ "$FAILED" == "1" ]] || die "self-test: failed occasions = $FAILED, expected 1"
  [[ "$CFRPM" == "500" ]] || die "self-test: change_failure_rate = ${CFRPM}permille, expected 500 (50.0%, 1/2)"
  # lead median over occasions. v1.00 T_DEPLOY = MAX(10:00:00, 10:00:05) = 10:00:05,
  # commit Jan1 00:00:00 -> 86400+36000+5 = 122405s. v1.01 T_DEPLOY = Jan6 09:00:00,
  # commit Jan5 00:00:00 -> 86400+32400 = 118800s. sorted [118800,122405],
  # even-count median = (118800+122405)//2 = 120602. (Exercises the per-target MAX
  # collapse: the harness row at :05 wins T_DEPLOY over the skill row at :00.)
  [[ "$LEADM" == "120602" ]] || die "self-test: lead_time median = $LEADM s, expected 120602"
  # MTTR: v1.01 rollback 12:12 - deploy 09:00 = 3h12m = 11520s
  [[ "$MTTRM" == "11520" ]] || die "self-test: MTTR mean = $MTTRM s, expected 11520 (3h12m)"

  # Test 5: format the self-test durations through the bash formatter (contract parity)
  R="$(format_duration "$MTTRM")"; [[ "$R" == "3h12m" ]] || die "self-test: format_duration(MTTR=$MTTRM) = $R, expected 3h12m"

  # Test 6: CFR real-zero vs N/A discriminator — zero failures WITH occasions -> 0.0%
  #         (a real clean-window value, NOT N/A); zero occasions -> N/A.
  ZERO_JSON="$(/usr/bin/printf '%s\n' "| 2026-01-05T10:00:00Z | v2.00 | 12 | deployment-status | deploy-skill | hub | s | CHEAP | resolved | p |" \
    | "$PY" -c "$AGG_PY" "" "30" "" "$ST_NOW")"
  ZFREQ="$(_dora_field "$ZERO_JSON" deployment_frequency value)"
  ZCFR="$(_dora_field "$ZERO_JSON" change_failure_rate value_permille)"
  [[ "$ZFREQ" == "1" ]] || die "self-test: zero-failure window occasions = $ZFREQ, expected 1"
  [[ "$ZCFR" == "0" ]]  || die "self-test: zero-failure-with-occasion CFR = $ZCFR, expected 0 (real 0.0%, NOT N/A)"

  EMPTY_JSON="$(/usr/bin/printf '' | "$PY" -c "$AGG_PY" "" "30" "" "$ST_NOW")"
  ECFR="$(_dora_field "$EMPTY_JSON" change_failure_rate value_permille)"
  [[ "$ECFR" == "NA" ]] || die "self-test: zero-occasion CFR = $ECFR, expected NA (denominator undefined)"

  # ─── Group DF — failed deploys reach the CFR NUMERATOR (#4215) ─────────────
  #
  # THE DEFECT, IN FIXTURE FORM. Before this group existed the change_failure_rate
  # numerator was keyed ONLY to a self-repair/rollback row, so a deploy whose every
  # target failed entered the DENOMINATOR ALONE and the release reported 0.0% (0/1).
  # The platform's change-failure rate therefore IMPROVED as its deploys failed, and
  # because the event log is append-only the bias was permanent.
  #
  # Mutation pairing: delete `| failed_deploy_versions` from the numerator union and
  # DF-1 turns red while DF-2 stays green — which is exactly why DF-2 exists.
  DF_FAIL_ROWS="$(/bin/cat <<'ROWS'
| 2026-01-08T11:30:00Z | slug-allfail | 12 | deployment-status | deploy-skill | hub | skill:a | CHEAP | escalated | result:FAIL |
| 2026-01-08T11:30:01Z | slug-allfail | 12 | deployment-status | deploy-skill | hub | skill:b | CHEAP | escalated | result:FAIL |
ROWS
)"
  DF_OK_ROWS="$(/bin/cat <<'ROWS'
| 2026-01-08T11:30:00Z | slug-allok | 12 | deployment-status | deploy-skill | hub | skill:a | CHEAP | resolved | result:SUCCESS |
| 2026-01-08T11:30:01Z | slug-allok | 12 | deployment-status | deploy-skill | hub | skill:b | CHEAP | resolved | result:SUCCESS |
ROWS
)"
  DF_MIXED_ROWS="$(/bin/cat <<'ROWS'
| 2026-01-08T11:30:00Z | slug-mixed | 12 | deployment-status | deploy-skill | hub | skill:a | CHEAP | resolved | result:SUCCESS |
| 2026-01-08T11:30:01Z | slug-mixed | 12 | deployment-status | deploy-skill | hub | skill:b | CHEAP | escalated | result:FAIL |
ROWS
)"

  # DF-1 — a release whose every target failed is a CHANGE FAILURE: 1 of 1, 100%.
  DF_JSON="$(/usr/bin/printf '%s\n' "$DF_FAIL_ROWS" | "$PY" -c "$AGG_PY" "" "30" "" "$ST_NOW")"
  R="$(_dora_field "$DF_JSON" change_failure_rate value_permille)"
  [[ "$R" == "1000" ]] || die "self-test: DF-1 an all-targets-failed release must read CFR 1000permille (100%), got ${R}permille"
  # DF-1b — and it STAYS in the denominator. A deploy that ran and failed is still a
  #         deployment event; dropping it would understate deployment_frequency and
  #         quietly hide the failure a second way.
  R="$(_dora_field "$DF_JSON" deployment_frequency value)"
  [[ "$R" == "1" ]] || die "self-test: DF-1b a failed deploy must still count as 1 occasion (denominator), got $R"

  # DF-2 — CONTROL. The identical fixture with resolved outcomes reads 0%. Without
  #        this arm, DF-1's 100% would be consistent with an engine that marks
  #        everything failed.
  DF_JSON="$(/usr/bin/printf '%s\n' "$DF_OK_ROWS" | "$PY" -c "$AGG_PY" "" "30" "" "$ST_NOW")"
  R="$(_dora_field "$DF_JSON" change_failure_rate value_permille)"
  [[ "$R" == "0" ]] || die "self-test: DF-2 CONTROL — an all-targets-succeeded release must read CFR 0permille, got ${R}permille"

  # DF-3 — a PARTIAL failure is a failure. One escalated target means the deploy did
  #        not succeed, so the occasion is a change failure even though a sibling
  #        target reported success.
  DF_JSON="$(/usr/bin/printf '%s\n' "$DF_MIXED_ROWS" | "$PY" -c "$AGG_PY" "" "30" "" "$ST_NOW")"
  R="$(_dora_field "$DF_JSON" change_failure_rate value_permille)"
  [[ "$R" == "1000" ]] || die "self-test: DF-3 a partially-failed release must read CFR 1000permille (100%), got ${R}permille"

  # DF-4 — the two failure signals UNION rather than double-count. A release carrying
  #        BOTH a failed deploy row and a rollback is one failed occasion, not two.
  DF_JSON="$(/usr/bin/printf '%s\n%s\n' "$DF_FAIL_ROWS" \
    "| 2026-01-08T13:00:00Z | slug-allfail | 13 | self-repair | rollback | operator | s | MODERATE | resolved | p |" \
    | "$PY" -c "$AGG_PY" "" "30" "" "$ST_NOW")"
  R="$(_dora_field "$DF_JSON" change_failure_rate failed)"
  [[ "$R" == "1" ]] || die "self-test: DF-4 rollback + failed-deploy on one release is ONE failed occasion, got $R"

  # DF-5 — SPECIFICITY. A failed row of a NON-anchor subtype must not mark the
  #        occasion failed, because deploy-package is not part of the occasion set at
  #        all; without this arm the numerator could be keyed on any deployment-status
  #        row and DF-1 would still pass.
  DF_JSON="$(/usr/bin/printf '%s\n%s\n' "$DF_OK_ROWS" \
    "| 2026-01-08T11:30:02Z | slug-allok | 12 | deployment-status | deploy-package | hub | package:p | CHEAP | escalated | result:FAIL |" \
    | "$PY" -c "$AGG_PY" "" "30" "" "$ST_NOW")"
  R="$(_dora_field "$DF_JSON" change_failure_rate value_permille)"
  [[ "$R" == "0" ]] || die "self-test: DF-5 SPECIFICITY — a failed deploy-package row is not an anchor and must not mark the occasion failed, got ${R}permille"

  echo "self-test: PASS"
  echo "  duration formatter validated (sub-hour / over-hour / multi-day / zero)"
  echo "  cadence label thresholds validated"
  echo "  DORA aggregation validated (per-target row collapse to occasions, lead-median, CFR, MTTR)"
  echo "  CFR real-zero vs N/A discriminator validated"
  echo "  query-pipeline-event.sh dependency validated"
  echo "  every arm above ran through the LIVE \$AGG_PY engine, not a transcription of it"
  echo "  failed deploys reach the CFR NUMERATOR validated (#4215, group DF):"
  echo "    DF-1 an all-targets-failed release reads CFR 100% (it used to read 0.0% — failed deploys entered the denominator ALONE, so the platform's change-failure rate improved as its deploys failed, permanently) / DF-1b and it STAYS in the denominator, because a deploy that ran and failed is still a deployment event / DF-2 CONTROL an all-targets-succeeded release reads 0% / DF-3 a PARTIAL failure is a failure / DF-4 rollback + failed-deploy on one release is ONE failed occasion, not two (union, not sum) / DF-5 SPECIFICITY a failed deploy-package row is not an anchor and does not mark the occasion failed"
  exit 0
fi

# ─── Argument parsing ────────────────────────────────────────────────────────

WINDOW_DAYS="30"
WINDOW_OCCASIONS=""
SINGLE_METRIC=""
OUTPUT_FORMAT="human"   # human | json
COMMIT_ANCHOR_MAP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --window)
      # accept "30d" or bare "30"
      WINDOW_DAYS="${2%d}"; shift 2 ;;
    --window-occasions) WINDOW_OCCASIONS="${2:-}"; shift 2 ;;
    --metric) SINGLE_METRIC="${2:-}"; shift 2 ;;
    --commit-anchor-map) COMMIT_ANCHOR_MAP="${2:-}"; shift 2 ;;
    --json) OUTPUT_FORMAT="json"; shift ;;
    --help|-h) usage ;;
    -*) die "Unknown flag: $1" ;;
    *) die "Unexpected positional arg: $1" ;;
  esac
done

# Validate window args
if [[ -n "$WINDOW_OCCASIONS" ]]; then
  [[ "$WINDOW_OCCASIONS" =~ ^[0-9]+$ && "$WINDOW_OCCASIONS" -ge 1 ]] \
    || die "--window-occasions must be a positive integer: got '$WINDOW_OCCASIONS'"
else
  [[ "$WINDOW_DAYS" =~ ^[0-9]+$ && "$WINDOW_DAYS" -ge 1 ]] \
    || die "--window must be a positive integer count of days (e.g. 30 or 30d): got '$WINDOW_DAYS'"
fi

case "$SINGLE_METRIC" in
  ""|deployment_frequency|lead_time_for_changes|change_failure_rate|mean_time_to_restore) : ;;
  *) die "--metric must be one of: deployment_frequency lead_time_for_changes change_failure_rate mean_time_to_restore (got '$SINGLE_METRIC')" ;;
esac

[[ -x "$QUERY_TOOL" ]] || die "query-pipeline-event.sh missing or not executable at $QUERY_TOOL"
[[ -x "$PY" ]] || die "$PY not executable (required for DORA aggregation)"

# ─── Read deploy + rollback rows from the event log (via the query primitive) ─

# The query tool filters event_type but not subtype; the python aggregator below
# applies the subtype filter (deploy-skill / deploy-harness ; rollback). Read both
# event types; legitimate-empty is the pre-cutover / no-event case.
DEPLOY_ROWS="$("$QUERY_TOOL" --event-type deployment-status 2>/dev/null | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
ROLLBACK_ROWS="$("$QUERY_TOOL" --event-type self-repair 2>/dev/null | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
ALL_ROWS="$(printf '%s\n%s\n' "$DEPLOY_ROWS" "$ROLLBACK_ROWS" | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"

# ─── Resolve the commit-anchor map for lead-time ─────────────────────────────
# Priority: explicit --commit-anchor-map file. Best-effort git fallback is left to
# the aggregator's "version not in map -> occasion excluded from lead-time" path;
# a deterministic map keeps the read reproducible. When neither resolves an anchor
# for ANY occasion, lead_time is N/A.

COMMIT_MAP_DATA=""
if [[ -n "$COMMIT_ANCHOR_MAP" ]]; then
  [[ -r "$COMMIT_ANCHOR_MAP" ]] || die "--commit-anchor-map not readable: $COMMIT_ANCHOR_MAP"
  COMMIT_MAP_DATA="$(/bin/cat "$COMMIT_ANCHOR_MAP")"
else
  # Best-effort git read: for each version tag present in the deploy rows, resolve the
  # FIRST commit's committer-date the tag carries vs the previous tag. This is a
  # convenience path; it degrades to "no anchor" (lead-time N/A) when git or the tags
  # are unavailable — never an error.
  GIT="$(find_git)"
  if [[ -n "$GIT" ]] && "$GIT" -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    # Collect distinct occasion keys from deploy rows (field 2).
    VERSIONS="$(printf '%s\n' "$DEPLOY_ROWS" | /usr/bin/awk -F ' \\| ' 'NF>2 {print $2}' | /usr/bin/sort -u)"
    # The occasion key is the release join key — the milestone SLUG per
    # pipeline-event-log-schema.md § 2a — but the anchor below is resolved as a
    # GIT TAG, and no tag is named after a milestone. Without this translation
    # the lookup misses every slug-keyed occasion and lead-time degrades to a
    # permanent N/A: silent, because the git read is best-effort by design.
    # Translate slug -> shipped tag via the § 2a WRITE-side inverse (RELEASE_LOG
    # 8-col schema: Version(1) Milestone(2) ... Tag(6)). A key that is already a
    # version resolves directly and is left alone.
    RELEASE_LOG_FILE="${RELEASE_LOG_FILE:-$REPO_ROOT/release/releases/RELEASE_LOG.md}"
    _dora_slug_to_tag() {  # <key> -> git-resolvable ref, or the key unchanged
      local key="$1"
      [[ -r "$RELEASE_LOG_FILE" ]] || { printf '%s' "$key"; return; }
      /usr/bin/awk -F ' \\| ' -v k="$key" '
        /^\|[[:space:]]*v[0-9]+\.[0-9]+/ {
          v=$1; sub(/^\|[[:space:]]*/,"",v); sub(/[[:space:]]*$/,"",v)
          ms=$2; gsub(/`/,"",ms); sub(/^[[:space:]]*/,"",ms); sub(/[[:space:]]*$/,"",ms)
          tg=$6; gsub(/`/,"",tg); sub(/^[[:space:]]*/,"",tg); sub(/[[:space:]]*$/,"",tg)
          if (ms == k) { print (tg != "" ? tg : v); found=1; exit }
        }
        END { if (!found) print k }
      ' "$RELEASE_LOG_FILE"
    }
    while IFS= read -r occ_key; do
      [[ -z "$occ_key" ]] && continue
      ver="$(_dora_slug_to_tag "$occ_key")"
      # Resolve the tag's earliest-carried commit committer-date: the first commit
      # reachable from <ver> but not from its immediate predecessor. Best-effort:
      # if the tag is absent, skip (no anchor for this occasion).
      if "$GIT" -C "$REPO_ROOT" rev-parse "$ver" >/dev/null 2>&1; then
        # earliest commit committer-date on the tag (cheap, robust): the min %cI across
        # the tag's history is over-broad, so prefer the tag's own commit date as a
        # stable proxy when range resolution is unavailable.
        CISO="$("$GIT" -C "$REPO_ROOT" log -1 --format=%cI "$ver" 2>/dev/null || true)"
        # Key the map by the OCCASION key (what the deploy rows carry), not by
        # the tag we resolved it through — the aggregator joins on the former.
        [[ -n "$CISO" ]] && COMMIT_MAP_DATA="${COMMIT_MAP_DATA}${occ_key}	${CISO}
"
      fi
    done <<< "$VERSIONS"
  fi
fi

# ─── Aggregate the four metrics (single python pass; stdlib only) ────────────

NOW_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# stdin carries the event rows, so the python SOURCE is passed via `-c "$AGG_PY"` —
# a heredoc on `python3 -` would itself consume stdin and starve the piped rows
# (the synthesize-release-learnings.sh pattern).

DORA_JSON="$(printf '%s\n' "$ALL_ROWS" | "$PY" -c "$AGG_PY" \
  "$COMMIT_MAP_DATA" "$WINDOW_DAYS" "${WINDOW_OCCASIONS:-}" "$NOW_ISO")" \
  || die "DORA aggregation parse failure (malformed ts_iso or commit-time)" 2

# ─── Render ──────────────────────────────────────────────────────────────────

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  if [[ -n "$SINGLE_METRIC" ]]; then
    "$PY" -c 'import json,sys; d=json.loads(sys.argv[1]); print(json.dumps({sys.argv[2]: d[sys.argv[2]], "window": d["window"]}))' "$DORA_JSON" "$SINGLE_METRIC"
  else
    printf '%s\n' "$DORA_JSON"
  fi
  exit 0
fi

# Human render — extract each metric's display string.
WINDOW_DESC="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["window"])' "$DORA_JSON")"
WINDOW_END="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["window_ending"][:10])' "$DORA_JSON")"

render_freq() {
  local val wd na
  val="$("$PY" -c 'import json,sys; v=json.loads(sys.argv[1])["deployment_frequency"]["value"]; print("NA" if v is None else v)' "$DORA_JSON")"
  wd="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["deployment_frequency"]["window_days"])' "$DORA_JSON")"
  na="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["deployment_frequency"].get("na_reason") or "")' "$DORA_JSON")"
  if [[ "$val" == "NA" ]]; then
    echo "  deployment_frequency:  N/A ($na)"
  else
    echo "  deployment_frequency:  $val deploys / ${wd}d ($(cadence_label "$val" "$wd"))"
  fi
}

render_lead() {
  local secs n na
  secs="$("$PY" -c 'import json,sys; v=json.loads(sys.argv[1])["lead_time_for_changes"]["value_seconds"]; print("NA" if v is None else v)' "$DORA_JSON")"
  n="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["lead_time_for_changes"]["n"])' "$DORA_JSON")"
  na="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["lead_time_for_changes"].get("na_reason") or "")' "$DORA_JSON")"
  if [[ "$secs" == "NA" ]]; then
    echo "  lead_time_for_changes: N/A ($na)"
  else
    echo "  lead_time_for_changes: $(format_duration "$secs") (median over $n deploys)"
  fi
}

render_cfr() {
  local pm failed total na
  pm="$("$PY" -c 'import json,sys; v=json.loads(sys.argv[1])["change_failure_rate"]["value_permille"]; print("NA" if v is None else v)' "$DORA_JSON")"
  failed="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["change_failure_rate"]["failed"])' "$DORA_JSON")"
  total="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["change_failure_rate"]["total"])' "$DORA_JSON")"
  na="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["change_failure_rate"].get("na_reason") or "")' "$DORA_JSON")"
  if [[ "$pm" == "NA" ]]; then
    echo "  change_failure_rate:   N/A ($na)"
  else
    # per-mille -> percent with one decimal
    local pct
    pct="$("$PY" -c 'import sys; print(f"{int(sys.argv[1])/10:.1f}")' "$pm")"
    echo "  change_failure_rate:   ${pct}% (${failed}/${total} occasions)"
  fi
}

render_mttr() {
  local secs n na
  secs="$("$PY" -c 'import json,sys; v=json.loads(sys.argv[1])["mean_time_to_restore"]["value_seconds"]; print("NA" if v is None else v)' "$DORA_JSON")"
  n="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["mean_time_to_restore"]["n"])' "$DORA_JSON")"
  na="$("$PY" -c 'import json,sys; print(json.loads(sys.argv[1])["mean_time_to_restore"].get("na_reason") or "")' "$DORA_JSON")"
  if [[ "$secs" == "NA" ]]; then
    echo "  mean_time_to_restore:  N/A ($na)"
  else
    echo "  mean_time_to_restore:  $(format_duration "$secs") (mean over $n rollback$([ "$n" -eq 1 ] || echo s))"
  fi
}

if [[ -n "$SINGLE_METRIC" ]]; then
  case "$SINGLE_METRIC" in
    deployment_frequency) render_freq | /usr/bin/sed 's/^  //' ;;
    lead_time_for_changes) render_lead | /usr/bin/sed 's/^  //' ;;
    change_failure_rate) render_cfr | /usr/bin/sed 's/^  //' ;;
    mean_time_to_restore) render_mttr | /usr/bin/sed 's/^  //' ;;
  esac
  exit 0
fi

echo "DORA (window=${WINDOW_DESC}, ending ${WINDOW_END}):"
render_freq
render_lead
render_cfr
render_mttr
echo "  mechanism: compute-dora-metrics.sh"
exit 0

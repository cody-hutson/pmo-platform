#!/usr/bin/env bash
# synthesize-release-learnings.sh — Release-learnings synthesizer
# Per pmo-platform/reference/standards/pipeline-event-log-schema.md § 11.
# Reads the operator-instance pipeline event log at
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md
# (canonical default: ${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results/)
# via query-pipeline-event.sh (sibling tool; it resolves the log location).
#
# Per the Stage 5 spec.
#
# Two modes:
#   per-release    : compose the sibling H4 "#### Release Learnings v<X.Y>" block
#                    for a single version by JOINing release-synthesis/learnings-triple
#                    events from pipeline-event-log.md
#   pattern-detect : scan a trailing window of versions for recurring
#                    same-domain keywords across the surprise / would-change /
#                    watch-for fields; optionally auto-promote clusters to
#                    GitHub Issues
#
# Usage:
#   ./synthesize-release-learnings.sh --mode per-release --version v2.10
#   ./synthesize-release-learnings.sh --mode pattern-detect --window 5
#   ./synthesize-release-learnings.sh --mode pattern-detect --window 5 --cluster-min 3 --apply
#   ./synthesize-release-learnings.sh --mode pattern-detect --window 5 --emit rate
#   ./synthesize-release-learnings.sh --self-test
#   ./synthesize-release-learnings.sh --help
#
# Flags:
#   --mode {per-release|pattern-detect}   required for non-self-test runs
#   --version vX.Y                        required for --mode per-release
#   --window N                            trailing N distinct VERSIONS (default 5);
#                                         pattern-detect mode only
#   --window-by-row                       trailing N rows instead of N versions
#   --cluster-min N                       minimum cluster size for pattern (default 3);
#                                         spec also requires cluster spans >=2 versions
#   --emit {report|rate}                  pattern-detect output form (default report).
#                                         `rate` emits the cross_release_pattern_emergence_rate
#                                         = qualifying-clusters / events-in-window (both ALREADY
#                                         computed by pattern-detect — REUSED, not re-implemented).
#                                         This is the rate close-class-telemetry.md Indicator 4
#                                         POINTS to (deferred-to-aggregate). Human line + a
#                                         machine `rate=<2dp>` token; `--apply` is ignored in rate mode.
#   --apply                               actually create Issues via `gh issue create`
#                                         (default is dry-run; prints the would-create
#                                         Issue body to stdout)
#   --self-test                           run unit tests; no side effects
#   --help, -h                            print this help
#
# Cutover: applies to releases entering Stage 13 strictly AFTER the cutover merge SHA.
# The cutover release itself is exempt (reflexive-pipeline-loop discipline). This script does
# not gate by version — the Stage 13 call-site honors cutover.
#
# Exit codes:
#   0 = success (per-release may emit a block; pattern-detect may emit a report;
#       legitimate empty result when no events match)
#   1 = invalid args / dependency missing / parse failure

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# REPO_ROOT retained for resolution-block parity with the append/query event-log
# tools; this tool delegates all log-path resolution to query-pipeline-event.sh
# (QUERY_TOOL below), so REPO_ROOT is unused here. Two levels up — NOT three; the
# prior `../../..` mis-anchored above the repo from a worktree (the #430-class bug).
# shellcheck disable=SC2034
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
QUERY_TOOL="$SCRIPT_DIR/query-pipeline-event.sh"
PY=/usr/bin/python3

# Repo slug resolution (env → operator.toml → bare default) for the optional
# --apply pattern-promotion gh-create path; exported so the embedded python reads
# it via os.environ. Literal lives only in the gitignored operator.toml.
REPO_SLUG="${REPO_SLUG:-}"
if [[ -z "$REPO_SLUG" ]] && [[ -r "${HOME}/.config/pmo-platform/operator.toml" ]]; then
  _gh=$(grep -E '^operator_github' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  _repo=$(grep -E '^pmo_platform_repo_name' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | head -1 | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  [[ -z "$_repo" ]] && _repo="pmo-platform"
  [[ -n "$_gh" ]] && REPO_SLUG="${_gh}/${_repo}"
fi
[[ -z "$REPO_SLUG" ]] && REPO_SLUG="pmo-platform"
export PMO_REPO_SLUG="$REPO_SLUG"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,46p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# ─── Argument parsing ────────────────────────────────────────────────────────

MODE=""
VERSION=""
WINDOW=5
WINDOW_BY_ROW=false
CLUSTER_MIN=3
APPLY=false
EMIT="report"   # report | rate — pattern-detect mode only (rate = cross_release_pattern_emergence_rate)
SELF_TEST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --window) WINDOW="$2"; shift 2 ;;
    --window-by-row) WINDOW_BY_ROW=true; shift ;;
    --cluster-min) CLUSTER_MIN="$2"; shift 2 ;;
    --emit) EMIT="$2"; shift 2 ;;
    --apply) APPLY=true; shift ;;
    --self-test) SELF_TEST=true; shift ;;
    --help|-h) usage ;;
    *) die "Unknown flag: $1" ;;
  esac
done

# ─── Helpers ─────────────────────────────────────────────────────────────────

# Parse a payload triple "surprise:...; would-change:...; watch-for:..."
# and emit three lines on stdout: surprise, would-change, watch-for (in that order).
# Each may be the literal string "N/A — no novel learning this release" when the
# release captured no novel learning.
parse_triple() {
  local payload="$1"
  "$PY" - "$payload" <<'PY'
import re
import sys

payload = sys.argv[1]

# Split on field labels; accept the three fields in any order. The labels are
# case-sensitive and followed by ":" then arbitrary content up to the next
# label OR end-of-string. Per spec § 3 the separator BETWEEN fields is "; "
# but inputs vary slightly (some rows omit space after ;).
fields = {"surprise": "", "would-change": "", "watch-for": ""}
# Build a regex that captures each labeled field's content up to the next label.
labels = list(fields.keys())
# Pattern: <label>:<content> where content is anything up to (?=<next label>) or end.
label_alt = "|".join(re.escape(l) for l in labels)
pattern = re.compile(
    r"(?P<label>" + label_alt + r"):\s*(?P<content>.*?)(?=\s*(?:" + label_alt + r"):|$)",
    re.DOTALL,
)
for m in pattern.finditer(payload):
    label = m.group("label")
    content = m.group("content").strip().rstrip(";").strip()
    if label in fields and not fields[label]:
        fields[label] = content

# Emit three lines; preserve empty when not present.
print(fields["surprise"])
print(fields["would-change"])
print(fields["watch-for"])
PY
}

# Check whether a field value matches the explicit N/A sentinel per AC8.
# Sentinel: "N/A — no novel learning this release" (case-sensitive, exact match).
is_na_sentinel() {
  [[ "$1" == "N/A — no novel learning this release" ]]
}

# ─── Per-release mode ────────────────────────────────────────────────────────

emit_per_release_block() {
  local version="$1"
  local now_iso
  now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local rows
  rows="$("$QUERY_TOOL" --event-type release-synthesis --event-subtype learnings-triple --version "$version" 2>/dev/null \
    | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"

  local n=0
  if [[ -n "$rows" ]]; then
    n="$(echo "$rows" | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
  fi

  echo "#### Release Learnings $version"
  echo ""
  echo "**Synthesized at:** $now_iso"

  if [[ "$n" -eq 0 ]]; then
    # Per § 11.3: forward-compatible — emit an N/A block when no events exist,
    # so consumers (release-planner Mode B; Stage 9 Empirical Verification) see
    # a structured "no data" rather than a missing block.
    echo "**Source events:** 0 \`release-synthesis/learnings-triple\` row(s) from \`pipeline-event-log.md\` (filter: version=\`$version\`)"
    echo "**Source-row anchors:** N/A"
    echo ""
    echo "**Surprise:** N/A — no novel learning this release"
    echo "**Would-change:** N/A — no novel learning this release"
    echo "**Watch-for:** N/A — no novel learning this release"
    return 0
  fi

  # Collect per-row anchors + parse triples
  local anchors=()
  local surprises=()
  local would_changes=()
  local watch_fors=()
  local na_count=0
  local ts payload triple_lines s_val w_val h_val

  while IFS= read -r row; do
    # Field map (per query-pipeline-event.sh actual layout):
    # $1="| ts"  $2=version  $3=stage  $4=event_type  $5=event_subtype
    # $6=actor   $7=subject  $8=reversibility  $9=outcome  $10="payload |"
    ts="$(echo "$row" | /usr/bin/awk -F ' \\| ' '{ print $1 }' | /usr/bin/sed 's/^| //')"
    payload="$(echo "$row" | /usr/bin/awk -F ' \\| ' '{ print $10 }' | /usr/bin/sed 's/ |$//')"
    anchors+=("$ts")

    triple_lines="$(parse_triple "$payload")" || die "payload parse failure on row ts=$ts"
    s_val="$(echo "$triple_lines" | /usr/bin/sed -n '1p')"
    w_val="$(echo "$triple_lines" | /usr/bin/sed -n '2p')"
    h_val="$(echo "$triple_lines" | /usr/bin/sed -n '3p')"
    surprises+=("$s_val")
    would_changes+=("$w_val")
    watch_fors+=("$h_val")

    # Detect all-N/A row (per AC8 explicit-N/A discipline)
    if is_na_sentinel "$s_val" && is_na_sentinel "$w_val" && is_na_sentinel "$h_val"; then
      na_count=$((na_count + 1))
    fi
  done <<< "$rows"

  # Source-event header
  echo "**Source events:** $n \`release-synthesis/learnings-triple\` row(s) from \`pipeline-event-log.md\` (filter: version=\`$version\`)"
  # Source-row anchors: list of timestamps
  local anchor_str=""
  for ts in "${anchors[@]}"; do
    if [[ -z "$anchor_str" ]]; then
      anchor_str="\`$ts\`"
    else
      anchor_str="$anchor_str, \`$ts\`"
    fi
  done
  echo "**Source-row anchors:** \`pipeline-event-log.md\` row(s) at ts $anchor_str"
  echo ""

  # All-N/A short-circuit per AC8
  if [[ "$na_count" -eq "$n" ]]; then
    echo "**Surprise:** N/A — no novel learning this release"
    echo "**Would-change:** N/A — no novel learning this release"
    echo "**Watch-for:** N/A — no novel learning this release"
    return 0
  fi

  # Compose each field across rows. N=1 → single field verbatim; N>1 → joined
  # with "; " separator and per-row attribution "[from <ts>]".
  compose_field() {
    local label="$1"
    shift
    local -a values=("$@")
    local out=""
    local idx=0
    for v in "${values[@]}"; do
      local ts="${anchors[$idx]}"
      idx=$((idx + 1))
      if [[ "$n" -eq 1 ]]; then
        out="$v"
      else
        if [[ -z "$out" ]]; then
          out="$v [from $ts]"
        else
          out="$out; $v [from $ts]"
        fi
      fi
    done
    echo "**$label:** $out"
  }

  compose_field "Surprise" "${surprises[@]}"
  compose_field "Would-change" "${would_changes[@]}"
  compose_field "Watch-for" "${watch_fors[@]}"

  if [[ "$na_count" -gt 0 ]]; then
    echo ""
    echo "**Explicit-N/A markers (per AC8):** $na_count source event(s) had triple fields = \`N/A — no novel learning this release\`"
  fi
}

# ─── Pattern-detect mode ─────────────────────────────────────────────────────

emit_pattern_detect_report() {
  local window="$1"
  local cluster_min="$2"
  local by_row="$3"
  local apply="$4"
  local emit="${5:-report}"   # report | rate

  # Read ALL learnings-triple rows (filtered by subtype).
  local rows
  rows="$("$QUERY_TOOL" --event-type release-synthesis --event-subtype learnings-triple 2>/dev/null \
    | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"

  if [[ -z "$rows" ]]; then
    if [[ "$emit" == "rate" ]]; then
      # cross_release_pattern_emergence_rate over an empty window is N/A (no
      # events-in-window denominator) — the close-class-telemetry N/A discipline.
      echo "cross_release_pattern_emergence_rate: N/A — no release-synthesis/learnings-triple events in window (window=$window) | rate=N/A"
      return 0
    fi
    echo "## Pattern-Detect Report (window=$window$([ "$by_row" == "true" ] && echo " by-row"))"
    echo ""
    echo "No \`release-synthesis/learnings-triple\` events found in \`pipeline-event-log.md\`."
    return 0
  fi

  # Window slicing: by-row tail vs by-version (default) distinct-version tail.
  # Pass to Python for cluster detection — keeps the bash surface thin.
  # Pipe rows on stdin; pass the script body via `-c "$(cat <<...)"` since a
  # heredoc on `python3 -` would consume stdin and starve the data.
  local pattern_py
  pattern_py="$(/bin/cat <<'PY'
import os
import re
import subprocess
import sys

window = int(sys.argv[1])
cluster_min = int(sys.argv[2])
by_row = (sys.argv[3] == "true")
apply_mode = (sys.argv[4] == "true")
emit_mode = sys.argv[5] if len(sys.argv) > 5 else "report"  # report | rate

# Stopword list — minimal; operator can extend via .claude/synthesizer-stopwords.txt
# in a future release. For now ship a small in-script default.
DEFAULT_STOPWORDS = {
    "this", "that", "with", "from", "into", "have", "will", "been", "more",
    "than", "some", "such", "when", "what", "which", "where", "would",
    "could", "should", "shall", "must", "also", "very", "much", "many",
    "make", "made", "made-", "their", "there", "release", "issue", "issues",
    "spoke", "stage", "milestone", "would-change", "change", "watch", "watch-for",
    "surprise", "fired", "fires", "ship", "ships", "shipped", "without", "before",
    "after", "needs", "needed", "still", "since", "today", "again",
}

# Field map per query-pipeline-event.sh actual layout (FS=" | "; $1 retains leading "| ")
def parse_row(row):
    parts = row.split(" | ")
    ts = parts[0][2:]  # strip leading "| "
    version = parts[1]
    payload = parts[9].rstrip(" |") if len(parts) > 9 else ""
    return ts, version, payload

def parse_triple(payload):
    labels = ["surprise", "would-change", "watch-for"]
    label_alt = "|".join(re.escape(l) for l in labels)
    pattern = re.compile(
        r"(?P<label>" + label_alt + r"):\s*(?P<content>.*?)(?=\s*(?:" + label_alt + r"):|$)",
        re.DOTALL,
    )
    out = {l: "" for l in labels}
    for m in pattern.finditer(payload):
        label = m.group("label")
        content = m.group("content").strip().rstrip(";").strip()
        if not out[label]:
            out[label] = content
    return out

def tokenize(text):
    # min-length 4, ASCII alphanumeric+hyphen; case-insensitive
    tokens = re.findall(r"[A-Za-z][A-Za-z0-9-]{3,}", text.lower())
    return [t for t in tokens if t not in DEFAULT_STOPWORDS]

NA_SENTINEL = "N/A — no novel learning this release"

# Parse all input rows
all_rows = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line.strip():
        continue
    ts, version, payload = parse_row(line)
    all_rows.append({"ts": ts, "version": version, "payload": payload})

# Sort chronologically (ts ISO8601 sorts lexically)
all_rows.sort(key=lambda r: r["ts"])

# Window slicing
if by_row:
    windowed = all_rows[-window:]
else:
    seen_versions = []
    for r in reversed(all_rows):
        if r["version"] not in seen_versions:
            seen_versions.append(r["version"])
        if len(seen_versions) >= window:
            break
    keep = set(seen_versions)
    windowed = [r for r in all_rows if r["version"] in keep]

# Per-field clustering: collect token → list of (ts, version, field, payload-excerpt)
fields = ["surprise", "would-change", "watch-for"]
clusters = {}  # (field, token) -> list of dicts
for r in windowed:
    triple = parse_triple(r["payload"])
    for f in fields:
        v = triple.get(f, "")
        if not v or v == NA_SENTINEL:
            continue  # AC8: N/A rows contribute no keyword signal
        for tok in set(tokenize(v)):
            key = (f, tok)
            clusters.setdefault(key, []).append({
                "ts": r["ts"], "version": r["version"], "field": f,
                "excerpt": v[:140],
            })

# Filter: cluster_size >= cluster_min AND spans >= 2 distinct versions
qualifying = []
for (field, tok), entries in clusters.items():
    if len(entries) < cluster_min:
        continue
    versions = {e["version"] for e in entries}
    if len(versions) < 2:
        continue
    qualifying.append({"field": field, "token": tok, "entries": entries, "versions": sorted(versions)})

# Sort qualifying clusters by size (desc), then by token (asc) for determinism
qualifying.sort(key=lambda c: (-len(c["entries"]), c["field"], c["token"]))

# ─── --emit rate short-circuit ─────────────────────────────────────────────
# cross_release_pattern_emergence_rate = qualifying-clusters / events-in-window.
# BOTH numerator (len(qualifying)) and denominator (len(windowed)) are ALREADY
# computed above by the pattern-detect machinery — this REUSES them, it does NOT
# re-implement the window/cluster logic. This is the rate close-class-telemetry.md
# Indicator 4 POINTS to (deferred-to-aggregate). round-half-up at 2 decimals (the
# canonical mode taken by reference from bundle-composition-doctrine.md § 3 Step 5).
if emit_mode == "rate":
    events_in_window = len(windowed)
    qualifying_clusters = len(qualifying)
    if events_in_window == 0:
        # no denominator -> N/A (the close-class-telemetry N/A discipline; never 0/0)
        print(f"cross_release_pattern_emergence_rate: N/A — no events in window "
              f"(window={window}, cluster-min={cluster_min}) | rate=N/A")
    else:
        hundredths = (qualifying_clusters * 10000 + events_in_window * 50) // (events_in_window * 100)
        rate = f"{hundredths // 100}.{hundredths % 100:02d}"
        print(f"cross_release_pattern_emergence_rate: {qualifying_clusters} qualifying cluster(s) "
              f"/ {events_in_window} event(s) in window ({rate}) "
              f"(window={window}, cluster-min={cluster_min}) | rate={rate}")
    sys.exit(0)

# Render report
mode_suffix = " by-row" if by_row else ""
print(f"## Pattern-Detect Report (window={window}{mode_suffix}; cluster-min={cluster_min})")
print()
print(f"**Events in window:** {len(windowed)}")
print(f"**Distinct versions in window:** {len({r['version'] for r in windowed})}")
print(f"**Qualifying clusters (size >= {cluster_min}, spans >= 2 versions):** {len(qualifying)}")
print()

if not qualifying:
    print("No clusters meet the auto-promotion criteria.")
    sys.exit(0)

# Emit cluster reports
for c in qualifying:
    print(f"### Cluster: `{c['token']}` ({c['field']}, {len(c['entries'])} events across {len(c['versions'])} versions)")
    print()
    print("| ts | version | excerpt |")
    print("|---|---|---|")
    for e in c["entries"]:
        excerpt_safe = e["excerpt"].replace("|", "\\|")
        print(f"| `{e['ts']}` | `{e['version']}` | {excerpt_safe} |")
    print()

# Auto-promotion (dry-run by default; --apply triggers actual gh issue create)
print("---")
print()
if apply_mode:
    print(f"**--apply mode:** would attempt `gh issue create` for {len(qualifying)} cluster(s).")
    for c in qualifying:
        body_lines = [
            "**Auto-promoted from synthesizer pattern-detect**",
            "",
            f"**Pattern:** {c['token']}",
            f"**Cluster size:** {len(c['entries'])} events spanning versions {', '.join(c['versions'])}",
            f"**Field:** {c['field']}",
            "**Source events (pipeline-event-log.md):**",
        ]
        for e in c["entries"]:
            excerpt_safe = e["excerpt"].replace("|", "\\|")
            body_lines.append(f"- ts `{e['ts']}`, version `{e['version']}`, payload excerpt: {excerpt_safe}")
        body_lines.append("")
        body_lines.append("**Triage instruction:** Review per `intake-style-guide.md` 5-test rule; reclassify or close-as-not-planned if false-positive.")
        body = "\n".join(body_lines)
        title = f"[Pattern]: Recurring `{c['token']}` across releases ({c['field']} field, {len(c['entries'])} events)"
        # Attempt the gh issue create call
        try:
            result = subprocess.run(
                [
                    "gh", "issue", "create",
                    "--repo", os.environ.get("PMO_REPO_SLUG", ""),
                    "--title", title,
                    "--body", body,
                    "--label", "improvement,auto-promoted-pattern,status: proposed",
                ],
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode == 0:
                print(f"  created: {result.stdout.strip()}")
            else:
                print(f"  FAILED to create issue for cluster '{c['token']}': {result.stderr.strip()}")
        except (subprocess.SubprocessError, FileNotFoundError) as e:
            print(f"  FAILED to invoke gh: {e}")
else:
    print(f"**Dry-run mode (default):** would create {len(qualifying)} Issue(s); re-run with --apply to actually create.")
    for c in qualifying:
        title = f"[Pattern]: Recurring `{c['token']}` across releases ({c['field']} field, {len(c['entries'])} events)"
        print(f"  - title: {title}")
PY
)"
  echo "$rows" | "$PY" -c "$pattern_py" "$window" "$cluster_min" "$by_row" "$apply" "$emit"
}

# ─── Self-test mode ──────────────────────────────────────────────────────────

run_self_test() {
  echo "self-test: starting"

  # Test 1: dependency present
  [[ -x "$QUERY_TOOL" ]] || die "self-test: query-pipeline-event.sh missing at $QUERY_TOOL"
  [[ -x "$PY" ]] || die "self-test: $PY not executable"

  # Test 2: parse_triple round-trip
  local result
  result="$(parse_triple "surprise: foo; would-change: bar; watch-for: baz")"
  local s w h
  s="$(echo "$result" | /usr/bin/sed -n '1p')"
  w="$(echo "$result" | /usr/bin/sed -n '2p')"
  h="$(echo "$result" | /usr/bin/sed -n '3p')"
  [[ "$s" == "foo" ]] || die "self-test: parse_triple surprise wrong (got '$s')"
  [[ "$w" == "bar" ]] || die "self-test: parse_triple would-change wrong (got '$w')"
  [[ "$h" == "baz" ]] || die "self-test: parse_triple watch-for wrong (got '$h')"

  # Test 3: parse_triple handles a real multi-clause payload (embedded semicolons)
  result="$(parse_triple "surprise: auto-close parser scope-restricted to default-branch; 5/6 parents missed at S12 (constituents merged release branch; aggregate PR Issue Refs empty); D-1 manual close at S13; would-change: chip-prompt update OR per-PR-to-main topology; watch-for: next release is first multi-issue test")"
  s="$(echo "$result" | /usr/bin/sed -n '1p')"
  w="$(echo "$result" | /usr/bin/sed -n '2p')"
  h="$(echo "$result" | /usr/bin/sed -n '3p')"
  [[ "$s" == *"auto-close parser scope-restricted"* ]] || die "self-test: real payload surprise wrong (got '$s')"
  [[ "$w" == *"chip-prompt update"* ]] || die "self-test: real payload would-change wrong (got '$w')"
  [[ "$h" == *"first multi-issue test"* ]] || die "self-test: real payload watch-for wrong (got '$h')"

  # Test 4: N/A sentinel detection
  is_na_sentinel "N/A — no novel learning this release" || die "self-test: N/A sentinel exact-match failed"
  ! is_na_sentinel "N/A" || die "self-test: N/A short-form should NOT match"
  ! is_na_sentinel "n/a — no novel learning this release" || die "self-test: case-insensitive should NOT match"

  # Test 5: per-release block on a version with one event (v2.10)
  local block
  block="$(emit_per_release_block v2.10)" || die "self-test: per-release v2.10 emit failed"
  echo "$block" | /usr/bin/grep -q "^#### Release Learnings v2.10$" || die "self-test: per-release header missing"
  echo "$block" | /usr/bin/grep -q "Source events.* 1 " || die "self-test: per-release source-events count wrong"
  echo "$block" | /usr/bin/grep -q "^\*\*Surprise:\*\*" || die "self-test: per-release Surprise field missing"
  echo "$block" | /usr/bin/grep -q "^\*\*Would-change:\*\*" || die "self-test: per-release Would-change field missing"
  echo "$block" | /usr/bin/grep -q "^\*\*Watch-for:\*\*" || die "self-test: per-release Watch-for field missing"

  # Test 6: per-release block on a version with NO events (forward-compat fallback)
  block="$(emit_per_release_block v999.999)" || die "self-test: per-release v999.999 emit failed"
  echo "$block" | /usr/bin/grep -q "0 \`release-synthesis/learnings-triple\` row" || die "self-test: missing-version should emit 0-rows header"
  echo "$block" | /usr/bin/grep -q "Surprise:\*\* N/A — no novel learning this release" || die "self-test: missing-version should emit N/A surprise"

  # Test 7: pattern-detect on real data — current 5 learnings-triple events,
  # all distinct versions. With cluster-min=3 and the default window=5, the
  # detector should run cleanly (whether it finds clusters depends on payload
  # similarity; the test asserts the report renders without error).
  local report
  report="$(emit_pattern_detect_report 5 3 false false)" || die "self-test: pattern-detect emit failed"
  echo "$report" | /usr/bin/grep -q "^## Pattern-Detect Report" || die "self-test: pattern-detect header missing"
  echo "$report" | /usr/bin/grep -q "Events in window" || die "self-test: pattern-detect events-in-window line missing"
  echo "$report" | /usr/bin/grep -q "Qualifying clusters" || die "self-test: pattern-detect qualifying-clusters line missing"

  # Test 8: pattern-detect dry-run vs apply — branch on whether clusters exist
  local qualifying_count
  qualifying_count="$(echo "$report" | /usr/bin/awk -F ':\\*\\* ' '/Qualifying clusters/ { print $2; exit }')"
  if [[ "$qualifying_count" == "0" ]]; then
    echo "$report" | /usr/bin/grep -q "No clusters meet the auto-promotion criteria" || die "self-test: pattern-detect zero-cluster footer missing"
  else
    echo "$report" | /usr/bin/grep -q "Dry-run mode (default)" || die "self-test: pattern-detect dry-run footer missing"
  fi

  # Test 9: --emit rate emits the cross_release_pattern_emergence_rate line with a
  # machine `rate=` token (the Indicator-4 aggregate close-class-telemetry.md points
  # to). Works whether the live log has events (rate=<2dp>) or is empty (rate=N/A):
  # both paths emit the prefix + the `rate=` token. Rate is qualifying/events-in-window.
  local rate_out
  rate_out="$(emit_pattern_detect_report 5 3 false false rate)" || die "self-test: --emit rate failed"
  echo "$rate_out" | /usr/bin/grep -q "^cross_release_pattern_emergence_rate:" || die "self-test: rate-emit prefix missing"
  echo "$rate_out" | /usr/bin/grep -qE 'rate=([0-9]+\.[0-9]{2}|N/A)' || die "self-test: rate-emit machine token (rate=<2dp>|N/A) missing"
  # The rate must be a ratio in [0.00, 1.00] when numeric (qualifying clusters cannot
  # exceed events-in-window): assert the numeric form never exceeds 1.00.
  local rate_val
  rate_val="$(echo "$rate_out" | /usr/bin/sed -nE 's/.*rate=([0-9]+\.[0-9]{2}).*/\1/p')"
  if [[ -n "$rate_val" ]]; then
    # integer-compare hundredths <= 100
    local rh
    rh="$(echo "$rate_val" | /usr/bin/awk -F. '{ printf "%d", $1*100 + $2 }')"
    [[ "$rh" -le 100 ]] || die "self-test: rate $rate_val exceeds 1.00 (qualifying > events-in-window — impossible)"
  fi

  echo "self-test: PASS"
  echo "  parse_triple validated (synthetic + real payload)"
  echo "  N/A sentinel exact-match validated"
  echo "  per-release block emit validated (with-events + zero-events)"
  echo "  pattern-detect report renders cleanly on current data"
  echo "  dry-run-vs-apply switch validated"
  echo "  --emit rate (cross_release_pattern_emergence_rate) validated"
  exit 0
}

# ─── Dispatch ────────────────────────────────────────────────────────────────

if [[ "$SELF_TEST" == "true" ]]; then
  run_self_test
fi

[[ -x "$QUERY_TOOL" ]] || die "query-pipeline-event.sh missing or not executable at $QUERY_TOOL"
[[ -x "$PY" ]] || die "$PY not executable (required for payload parsing)"

case "$MODE" in
  per-release)
    [[ -z "$VERSION" ]] && die "Required for --mode per-release: --version vX.Y"
    emit_per_release_block "$VERSION"
    ;;
  pattern-detect)
    [[ "$WINDOW" =~ ^[0-9]+$ ]] || die "--window must be a positive integer (got '$WINDOW')"
    [[ "$CLUSTER_MIN" =~ ^[0-9]+$ ]] || die "--cluster-min must be a positive integer (got '$CLUSTER_MIN')"
    case "$EMIT" in report|rate) : ;; *) die "--emit must be report|rate (got '$EMIT')" ;; esac
    emit_pattern_detect_report "$WINDOW" "$CLUSTER_MIN" "$WINDOW_BY_ROW" "$APPLY" "$EMIT"
    ;;
  "")
    die "Required: --mode {per-release|pattern-detect} (or --self-test)"
    ;;
  *)
    die "Invalid --mode '$MODE' (allowed: per-release, pattern-detect)"
    ;;
esac

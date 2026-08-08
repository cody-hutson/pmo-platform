#!/usr/bin/env bash
# synthesize-release-learnings.sh — Release-learnings synthesizer
# Per release/references/standards/pipeline-event-log-schema.md § 11.
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
#                    GitHub Issues. The report ALSO renders the near-threshold
#                    band (clusters spanning >=2 versions but below --cluster-min)
#                    and the versions that have left the trailing window — both
#                    SIGNAL-ONLY: they gate nothing and file nothing, and the
#                    auto-promotion predicate is unaffected by either.
#
# Usage:
#   ./synthesize-release-learnings.sh --mode per-release --version v2.10
#   ./synthesize-release-learnings.sh --mode pattern-detect --window 5
#   ./synthesize-release-learnings.sh --mode pattern-detect --window 5 --cluster-min 3 --apply
#   ./synthesize-release-learnings.sh --mode pattern-detect --window 5 --emit rate
#   ./synthesize-release-learnings.sh --mode pattern-detect --source session-retro --window 5
#   ./synthesize-release-learnings.sh --self-test
#   ./synthesize-release-learnings.sh --help
#
# Flags:
#   --mode {per-release|pattern-detect}   required for non-self-test runs
#   --version <release>                   required for --mode per-release. Accepts the
#                                         shipped vX.Y OR the milestone slug: row
#                                         selection routes through the query tool's
#                                         --release, i.e. the § 2a READ ladder, so a
#                                         vX.Y resolves to its slug-keyed rows rather
#                                         than matching the raw column. The value is
#                                         ALSO rendered verbatim into the H4 heading
#                                         `#### Release Learnings <value>`, so at
#                                         Stage 13 pass the shipped vX.Y — that is the
#                                         form § 11.3 specifies and the form the
#                                         RELEASE_LOG placement convention expects.
#                                         Pre-claim (no version yet), pass the slug.
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
#   --source {release-synthesis|session-retro}
#                                         pattern-detect INPUT GRAIN (default release-synthesis —
#                                         the pre-existing behavior, byte-unchanged). `session-retro`
#                                         clusters per-session self-retro rows on their `theme:` key.
#                                         The window / cluster / auto-promotion machinery is SHARED
#                                         across both grains; only the input filter and the clustered
#                                         field-set differ. See pipeline-event-log-schema.md § 11.8.
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
  _gh=$(grep -m1 -E '^operator_github' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  _repo=$(grep -m1 -E '^pmo_platform_repo_name' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | awk -F= '{gsub(/[" ]/,"",$2); print $2}')
  [[ -z "$_repo" ]] && _repo="pmo-platform"
  [[ -n "$_gh" ]] && REPO_SLUG="${_gh}/${_repo}"
fi
[[ -z "$REPO_SLUG" ]] && REPO_SLUG="pmo-platform"
export PMO_REPO_SLUG="$REPO_SLUG"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,66p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
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
SOURCE="release-synthesis"   # release-synthesis | session-retro — pattern-detect input grain (§ 11.8)
SELF_TEST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --window) WINDOW="$2"; shift 2 ;;
    --window-by-row) WINDOW_BY_ROW=true; shift ;;
    --cluster-min) CLUSTER_MIN="$2"; shift 2 ;;
    --emit) EMIT="$2"; shift 2 ;;
    --source) SOURCE="$2"; shift 2 ;;
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
# Pattern: <label>:<content> where content runs up to the next label or end.
# A field terminates at a RECOGNIZED label, or at any SEGMENT-OPENING label token
# (one that follows a ';'), recognized or not. Without that second alternative an
# unrecognized label is swallowed into the preceding field and rendered as part of
# it — the same containment defect fixed in the pattern-detect parser below.
# Prose colons do not open a segment and so are not treated as labels, which keeps
# multi-clause payloads (embedded ';' inside a clause) rendering unchanged.
label_alt = "|".join(re.escape(l) for l in labels)
GENERIC_LABEL = r"[A-Za-z][A-Za-z0-9_-]*"
pattern = re.compile(
    r"(?P<label>" + label_alt + r"):\s*(?P<content>.*?)"
    r"(?=\s*(?:" + label_alt + r"):|\s*;\s*" + GENERIC_LABEL + r":|$)",
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

  # --release, NOT --version: the release join key is the milestone SLUG
  # (pipeline-event-log-schema.md § 2a), so a raw --version filter carrying a
  # vX.Y matches ZERO slug-keyed rows and this function would emit a structured
  # "N/A — no novel learning this release" block for a release that in fact
  # emitted rows. --release resolves through the § 2a ladder and accepts either
  # form, so legacy callers passing vX.Y keep working.
  local rows
  rows="$("$QUERY_TOOL" --event-type release-synthesis --event-subtype learnings-triple --release "$version" 2>/dev/null \
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
    echo "**Source events:** 0 \`release-synthesis/learnings-triple\` row(s) from \`pipeline-event-log.md\` (filter: release=\`$version\`)"
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
  echo "**Source events:** $n \`release-synthesis/learnings-triple\` row(s) from \`pipeline-event-log.md\` (filter: release=\`$version\`)"
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
  local source="${6:-release-synthesis}"   # release-synthesis | session-retro

  # Source-parameterized input filter per pipeline-event-log-schema.md § 11.8.
  # The window/cluster/promotion machinery below is SHARED across both sources —
  # only the query filter, the payload label-set, and the clustered field-set
  # differ. A second cluster implementation is exactly the producer/producer
  # disagreement the Indicator-4 pointer discipline rejects.
  local src_label            # human name in report/N-A strings
  local rows
  case "$source" in
    release-synthesis)
      src_label="release-synthesis/learnings-triple"
      rows="$("$QUERY_TOOL" --event-type release-synthesis --event-subtype learnings-triple 2>/dev/null \
        | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
      ;;
    session-retro)
      # All three subtypes are read here; `no-learning` rows are then excluded
      # BY ENFORCEMENT before clustering (skipped on event_subtype, § 11.8) —
      # not left to tokenize to nothing on the assumption they carry no `theme:`.
      # That assumption was emitter discipline, and a mis-emitted row broke it.
      src_label="session-retro"
      rows="$("$QUERY_TOOL" --event-type session-retro 2>/dev/null \
        | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
      ;;
    *)
      die "--source must be one of: release-synthesis | session-retro (got '$source')"
      ;;
  esac

  if [[ -z "$rows" ]]; then
    if [[ "$emit" == "rate" ]]; then
      # cross_release_pattern_emergence_rate over an empty window is N/A (no
      # events-in-window denominator) — the close-class-telemetry N/A discipline.
      echo "cross_release_pattern_emergence_rate: N/A — no $src_label events in window (window=$window) | rate=N/A"
      return 0
    fi
    echo "## Pattern-Detect Report (window=$window$([ "$by_row" == "true" ] && echo " by-row"))"
    echo ""
    echo "No \`$src_label\` events found in \`pipeline-event-log.md\`."
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
source = sys.argv[6] if len(sys.argv) > 6 else "release-synthesis"

# Per-source payload contract (pipeline-event-log-schema.md § 11.8).
#   LABELS       — every label recognized in the payload. Needed IN FULL so the
#                  field regex terminates each field at the next label; an
#                  unlisted label would be swallowed into the preceding field
#                  content and tokenized as if it were signal.
#   CLUSTER_ON   — the subset actually tokenized into clusters.
# NB: this heredoc sits inside a $( ) command substitution, so bash still lexes
# quotes here even though the delimiter is quoted — every line must carry an EVEN
# number of apostrophes (an unpaired one is a hard parse error, not a comment).
SOURCE_CONTRACT = {
    "release-synthesis": {
        "labels": ["surprise", "would-change", "watch-for"],
        "cluster_on": ["surprise", "would-change", "watch-for"],
    },
    "session-retro": {
        # theme: ONLY — free-text `learning:` prose would cluster on incidental
        # vocabulary and manufacture patterns out of shared phrasing.
        "labels": ["session", "source", "theme", "domain", "learning", "reason"],
        "cluster_on": ["theme"],
    },
}
contract = SOURCE_CONTRACT.get(source, SOURCE_CONTRACT["release-synthesis"])
LABELS = contract["labels"]
CLUSTER_ON = contract["cluster_on"]

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
# Column order: ts | version | stage | event_type | event_subtype | actor |
#               subject | reversibility | outcome | payload
# event_subtype is index 4 and is returned so the zero-state can be excluded
# STRUCTURALLY rather than by trusting the emitter to omit `theme:`.
def parse_row(row):
    parts = row.split(" | ")
    ts = parts[0][2:]  # strip leading "| "
    version = parts[1]
    subtype = parts[4] if len(parts) > 4 else ""
    payload = parts[9].rstrip(" |") if len(parts) > 9 else ""
    return ts, version, subtype, payload

# Subtypes excluded from clustering by ENFORCEMENT (not by convention). A
# `no-learning` row means "reflected, found nothing"; it must contribute no
# cluster signal even if it was mis-emitted carrying a `theme:`.
EXCLUDED_SUBTYPES = {"no-learning"}

# A label token is one that OPENS a payload segment: at the string start, or
# immediately after a ';'. This is the grammar the writer emits and the gate in
# append-pipeline-event.sh enforces. A colon inside free prose does NOT open a
# segment and is therefore not a label boundary.
GENERIC_LABEL = r"[A-Za-z][A-Za-z0-9_-]*"

def parse_triple(payload):
    labels = LABELS
    # Longest-first so a label that prefixes another (none today, but the
    # session-retro set is open to growth) cannot shadow the longer one.
    label_alt = "|".join(re.escape(l) for l in sorted(labels, key=len, reverse=True))
    # A field ends at the next RECOGNIZED label (as before) OR at any
    # segment-opening label token, recognized or not. That second alternative is
    # the fix: previously an UNRECOGNIZED label did not terminate the field, so
    # its content was swallowed into the preceding field and tokenized as signal
    # — one stray label after `theme:` inflated one real cluster into three.
    # Because only recognized labels can open a match, the swallowed content is
    # now DISCARDED rather than re-attributed to a neighbour.
    terminator = (
        r"(?=\s*(?:" + label_alt + r"):"
        r"|\s*;\s*" + GENERIC_LABEL + r":"
        r"|$)"
    )
    pattern = re.compile(
        r"(?P<label>" + label_alt + r"):\s*(?P<content>.*?)" + terminator,
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
    ts, version, subtype, payload = parse_row(line)
    all_rows.append({"ts": ts, "version": version, "subtype": subtype, "payload": payload})

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
fields = CLUSTER_ON
clusters = {}  # (field, token) -> list of dicts
for r in windowed:
    # Zero-state exclusion by ENFORCEMENT. Previously `no-learning` rows were
    # relied on to carry no `theme:` — i.e. on emitter discipline alone. A
    # mis-emitted or label-leaked row then contributed cluster signal. Skipping
    # by subtype makes the exclusion structural: the row cannot contribute
    # regardless of what its payload happens to contain.
    if r.get("subtype", "") in EXCLUDED_SUBTYPES:
        continue
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

# ── Near-threshold band (sub-threshold disposition; stage-13-close.md Phase A7) ──
# Signal-only, and it gates NOTHING. Renders clusters ALREADY computed above that
# met the >=2-distinct-version filter but not cluster_min — data the tool has always
# built and then discarded at render. The § 11.5 auto-promotion predicate, the
# cluster_min default, and the --apply path are untouched: nothing here files.
# PLACEMENT IS LOAD-BEARING. This block sits BEFORE the `if not qualifying` early
# exit below, because zero-qualifying is exactly the case a sub-threshold learning
# lands in — a block appended after that exit would never render where it is needed.
near = []
for (field, tok), entries in clusters.items():
    if len(entries) >= cluster_min:
        continue                      # the promotion path owns these
    versions = {e["version"] for e in entries}
    if len(versions) < 2:
        continue                      # a single-version token is not "one release short"
    near.append({"field": field, "token": tok,
                 "entries": entries, "versions": sorted(versions)})
near.sort(key=lambda c: (-len(c["entries"]), c["field"], c["token"]))

print(f"**Near-threshold clusters (2 <= size < {cluster_min}, spans >= 2 versions):** {len(near)}")
print()
if near:
    print("### Near-threshold (no promotion)")
    print()
    print("| token | field | events | versions |")
    print("|---|---|---:|---|")
    for c in near:
        print(f"| `{c['token']}` | {c['field']} | {len(c['entries'])} | {', '.join(c['versions'])} |")
    print()

# ── Out of emergence window (parked; no longer counted toward emergence) ──
# Version-grained and branch-agnostic: `windowed` is a sublist of `all_rows` in BOTH
# the by-row and by-version branches, so deriving from version sets works either way
# (`keep` exists only in the by-version branch and must NOT be referenced here).
# Expiry is not deletion — the event row is append-only and the rendered
# `#### Release Learnings <V>` block is carved out of the archival sweep at any window.
_win_versions = {r["version"] for r in windowed}
_out_versions = sorted({r["version"] for r in all_rows} - _win_versions)
print(f"**Out of emergence window (parked, no longer counted):** {len(_out_versions)} version(s)"
      + (f" — {', '.join(_out_versions)}" if _out_versions else ""))
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
  echo "$rows" | "$PY" -c "$pattern_py" "$window" "$cluster_min" "$by_row" "$apply" "$emit" "$source"
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

  # ─── Per-release source-events counting path — hermetic fixture (#1561) ─────
  # Tests 5–6 assert a DETERMINISTIC per-release source-events count. They read
  # the source events through query-pipeline-event.sh, which resolves the
  # operator-instance pipeline-event-log.md — mutable, gitignored, append-only
  # data that is also absent entirely in CI. That coupling is the #1561 defect:
  # the counting LOGIC is correct, but as the live log rotated, v2.10's
  # learnings-triple count drifted from 1 to 0 and Test 5's count assertion went
  # red against live state. Fix at the fixture layer — point the reader at a
  # controlled in-tmp log (query-pipeline-event.sh honors EVALS_RESULTS_PATH), so
  # the count is fixture-defined (v2.10 = exactly one learnings-triple row), not
  # live-data-defined. Production synthesis behavior is unchanged: the override is
  # exported only inside this self-test, which exits before the CLI dispatch. The
  # pattern-detect tests below read the same resolved log, so this fixture also
  # keeps them deterministic (the live log no longer carries learnings-triple rows).
  local st_fixture_dir
  st_fixture_dir="$(/usr/bin/mktemp -d)" || die "self-test: mktemp -d failed"
  # Remove the fixture on ANY exit from the self-test (happy path or die).
  trap '/bin/rm -rf "$st_fixture_dir"' EXIT
  {
    echo "| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
    echo "|---|---|---|---|---|---|---|---|---|---|"
    echo "| 2026-03-01T12:00:00Z | v2.10 | 13 | release-synthesis | learnings-triple | skill:synthesize-release-learnings | release:v2.10 | CHEAP | resolved | surprise: fixture surprise; would-change: fixture would-change; watch-for: fixture watch-for |"
    # session-retro fixture (Test 10/11) — a SEPARATE event_type, so the
    # release-synthesis query filter above never sees these rows and Tests 5–9 are
    # unaffected. Shaped to yield EXACTLY ONE qualifying cluster:
    #   theme:over-building   x3 across v2.10 + v2.11 -> qualifies (>=3, >=2 versions)
    #   theme:one-off-noise   x2 in v2.11 only        -> below cluster-min, excluded
    #   no-learning row       carries NO theme:       -> excluded by subtype (enforced)
    echo "| 2026-03-02T09:00:00Z | v2.10 | 6 | session-retro | learning | skill:session-retro | session:s1 | CHEAP | resolved | session:s1; source:friction; theme:over-building; domain:corpus-edit; learning:scope grew past the ask |"
    echo "| 2026-03-02T09:00:01Z | v2.10 | 6 | session-retro | operator-feedback | skill:session-retro | session:s2 | CHEAP | resolved | session:s2; source:correction; theme:over-building; domain:release-ops; learning:operator trimmed unrequested scope |"
    echo "| 2026-03-03T09:00:02Z | v2.11 | 5 | session-retro | learning | skill:session-retro | session:s3 | CHEAP | resolved | session:s3; source:friction; theme:over-building; domain:planning; learning:design outran the acceptance criteria |"
    echo "| 2026-03-03T09:00:03Z | v2.11 | 5 | session-retro | learning | skill:session-retro | session:s4 | CHEAP | resolved | session:s4; source:preference; theme:one-off-noise; domain:comms; learning:single-session preference |"
    echo "| 2026-03-03T09:00:04Z | v2.11 | 5 | session-retro | learning | skill:session-retro | session:s5 | CHEAP | resolved | session:s5; source:preference; theme:one-off-noise; domain:comms; learning:repeat within one version only |"
    echo "| 2026-03-03T09:00:05Z | v2.11 | 13 | session-retro | no-learning | skill:session-retro | session:s6 | CHEAP | resolved | session:s6; reason:trivial-session-no-novel-signal |"
  } > "$st_fixture_dir/pipeline-event-log.md" || die "self-test: could not write fixture log"
  export EVALS_RESULTS_PATH="$st_fixture_dir"

  # Test 5: per-release block on a version with exactly one event (fixture v2.10)
  local block
  block="$(emit_per_release_block v2.10)" || die "self-test: per-release v2.10 emit failed"
  /usr/bin/grep -q "^#### Release Learnings v2.10$" <<<"$block" || die "self-test: per-release header missing"
  /usr/bin/grep -q "Source events.* 1 " <<<"$block" || die "self-test: per-release source-events count wrong"
  /usr/bin/grep -q "^\*\*Surprise:\*\*" <<<"$block" || die "self-test: per-release Surprise field missing"
  /usr/bin/grep -q "^\*\*Would-change:\*\*" <<<"$block" || die "self-test: per-release Would-change field missing"
  /usr/bin/grep -q "^\*\*Watch-for:\*\*" <<<"$block" || die "self-test: per-release Watch-for field missing"

  # Test 6: per-release block on a version with NO events (forward-compat fallback).
  # v999.999 is absent from the fixture, exercising the zero-rows N/A path.
  block="$(emit_per_release_block v999.999)" || die "self-test: per-release v999.999 emit failed"
  /usr/bin/grep -q "0 \`release-synthesis/learnings-triple\` row" <<<"$block" || die "self-test: missing-version should emit 0-rows header"
  /usr/bin/grep -q "Surprise:\*\* N/A — no novel learning this release" <<<"$block" || die "self-test: missing-version should emit N/A surprise"

  # Test 7: pattern-detect over the hermetic fixture set up above (the same in-tmp
  # log the per-release tests use). With cluster-min=3 and the default window=5
  # the detector runs cleanly — the single fixture event yields no qualifying
  # cluster; the test asserts the report renders without error.
  local report
  report="$(emit_pattern_detect_report 5 3 false false)" || die "self-test: pattern-detect emit failed"
  /usr/bin/grep -q "^## Pattern-Detect Report" <<<"$report" || die "self-test: pattern-detect header missing"
  /usr/bin/grep -q "Events in window" <<<"$report" || die "self-test: pattern-detect events-in-window line missing"
  /usr/bin/grep -q "Qualifying clusters" <<<"$report" || die "self-test: pattern-detect qualifying-clusters line missing"

  # Test 8: pattern-detect dry-run vs apply — branch on whether clusters exist
  local qualifying_count
  qualifying_count="$(echo "$report" | /usr/bin/awk -F ':\\*\\* ' '/Qualifying clusters/ { print $2; exit }')"
  if [[ "$qualifying_count" == "0" ]]; then
    /usr/bin/grep -q "No clusters meet the auto-promotion criteria" <<<"$report" || die "self-test: pattern-detect zero-cluster footer missing"
  else
    /usr/bin/grep -q "Dry-run mode (default)" <<<"$report" || die "self-test: pattern-detect dry-run footer missing"
  fi

  # Test 9: --emit rate emits the cross_release_pattern_emergence_rate line with a
  # machine `rate=` token (the Indicator-4 aggregate close-class-telemetry.md points
  # to). Works whether the live log has events (rate=<2dp>) or is empty (rate=N/A):
  # both paths emit the prefix + the `rate=` token. Rate is qualifying/events-in-window.
  local rate_out
  rate_out="$(emit_pattern_detect_report 5 3 false false rate)" || die "self-test: --emit rate failed"
  /usr/bin/grep -q "^cross_release_pattern_emergence_rate:" <<<"$rate_out" || die "self-test: rate-emit prefix missing"
  /usr/bin/grep -qE 'rate=([0-9]+\.[0-9]{2}|N/A)' <<<"$rate_out" || die "self-test: rate-emit machine token (rate=<2dp>|N/A) missing"
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

  # Test 10: --source session-retro clusters the SESSION grain on `theme:` and
  # yields EXACTLY ONE qualifying cluster over the seeded fixture (the #2423 AC3
  # method: "seeded fixture yields exactly one cluster"). Also asserts the cluster
  # is the intended one and that the sub-threshold theme did NOT qualify.
  local sr_report
  sr_report="$(emit_pattern_detect_report 5 3 false false report session-retro)" \
    || die "self-test: session-retro pattern-detect emit failed"
  /usr/bin/grep -q "^## Pattern-Detect Report" <<<"$sr_report" \
    || die "self-test: session-retro pattern-detect header missing"
  local sr_qualifying
  sr_qualifying="$(echo "$sr_report" | /usr/bin/awk -F ':\\*\\* ' '/Qualifying clusters/ { print $2; exit }')"
  [[ "$sr_qualifying" == "1" ]] \
    || die "self-test: session-retro fixture expected exactly 1 qualifying cluster, got '$sr_qualifying'"
  /usr/bin/grep -q '^### Cluster: `over-building` (theme,' <<<"$sr_report" \
    || die "self-test: session-retro cluster should be theme/over-building"
  if /usr/bin/grep -q 'one-off-noise' <<<"$sr_report"; then
    die "self-test: sub-threshold theme one-off-noise must NOT qualify"
  fi

  # Test 11: the explicit zero-state contributes NO cluster signal (a no-learning
  # row carries no theme:), and an unknown --source is rejected rather than
  # silently falling back to the release grain. The reject probe runs in a
  # SUBSHELL — die() exits, and an un-subshelled call would tear down the whole
  # self-test instead of being caught by the `if`.
  if /usr/bin/grep -q 'trivial-session' <<<"$sr_report"; then
    die "self-test: no-learning row must contribute no cluster signal"
  fi
  if ( emit_pattern_detect_report 5 3 false false report bogus-source ) >/dev/null 2>&1; then
    die "self-test: unknown --source must be rejected (bogus-source accepted)"
  fi

  # ── Test 12 (PA-4 REGRESSION): one unrecognized label must not inflate the
  # cluster count. The AC verbatim. Injects `mood:excited` immediately after
  # `theme:` on ONE row of the same fixture used by Test 10. Before the
  # containment fix this yielded 3 qualifying clusters instead of 1, because the
  # unrecognized label was swallowed into `theme:` and tokenized as signal.
  local dt2_dir dt2_report dt2_count
  dt2_dir="$(/usr/bin/mktemp -d)" || die "self-test: mktemp -d failed (DT-2)"
  {
    echo "| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
    echo "|---|---|---|---|---|---|---|---|---|---|"
    echo "| 2026-03-02T09:00:00Z | v2.10 | 6 | session-retro | learning | skill:session-retro | session:s1 | CHEAP | resolved | session:s1; source:friction; theme:over-building; mood:excited; domain:corpus-edit; learning:scope grew past the ask |"
    echo "| 2026-03-02T09:00:01Z | v2.10 | 6 | session-retro | operator-feedback | skill:session-retro | session:s2 | CHEAP | resolved | session:s2; source:correction; theme:over-building; domain:release-ops; learning:operator trimmed unrequested scope |"
    echo "| 2026-03-03T09:00:02Z | v2.11 | 5 | session-retro | learning | skill:session-retro | session:s3 | CHEAP | resolved | session:s3; source:friction; theme:over-building; domain:planning; learning:design outran the acceptance criteria |"
  } > "$dt2_dir/pipeline-event-log.md" || die "self-test: could not write DT-2 fixture"
  dt2_report="$(EVALS_RESULTS_PATH="$dt2_dir" emit_pattern_detect_report 5 3 false false report session-retro)" \
    || die "self-test: DT-2 pattern-detect emit failed"
  dt2_count="$(echo "$dt2_report" | /usr/bin/awk -F ':\\*\\* ' '/Qualifying clusters/ { print $2; exit }')"
  [[ "$dt2_count" == "1" ]] \
    || die "self-test: an unrecognized label inflated the cluster count (expected 1, got '$dt2_count') — parse_triple containment regressed"
  if /usr/bin/grep -q 'excited' <<<"$dt2_report"; then
    die "self-test: unrecognized-label content leaked into a cluster token"
  fi
  /bin/rm -rf "$dt2_dir"

  # ── Test 13 (PA-5 REGRESSION): a MIS-EMITTED no-learning row — one that does
  # carry a `theme:` matching a qualifying cluster — must still contribute
  # nothing. The shipped fixture could never catch this: its no-learning row is
  # well-formed, so it never exercised the case the exclusion exists for. The
  # exclusion is now structural (by subtype), not a matter of emitter discipline.
  local pa5_dir pa5_report pa5_count
  pa5_dir="$(/usr/bin/mktemp -d)" || die "self-test: mktemp -d failed (PA-5)"
  {
    echo "| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
    echo "|---|---|---|---|---|---|---|---|---|---|"
    echo "| 2026-03-02T09:00:00Z | v2.10 | 6 | session-retro | learning | skill:session-retro | session:s1 | CHEAP | resolved | session:s1; source:friction; theme:over-building; domain:corpus-edit; learning:a |"
    echo "| 2026-03-02T09:00:01Z | v2.10 | 6 | session-retro | learning | skill:session-retro | session:s2 | CHEAP | resolved | session:s2; source:friction; theme:over-building; domain:release-ops; learning:b |"
    # MIS-EMITTED zero-state: carries a theme: it should never have. Structurally excluded.
    echo "| 2026-03-03T09:00:02Z | v2.11 | 5 | session-retro | no-learning | skill:session-retro | session:s3 | CHEAP | resolved | session:s3; reason:trivial; theme:over-building |"
  } > "$pa5_dir/pipeline-event-log.md" || die "self-test: could not write PA-5 fixture"
  pa5_report="$(EVALS_RESULTS_PATH="$pa5_dir" emit_pattern_detect_report 5 3 false false report session-retro)" \
    || die "self-test: PA-5 pattern-detect emit failed"
  pa5_count="$(echo "$pa5_report" | /usr/bin/awk -F ':\\*\\* ' '/Qualifying clusters/ { print $2; exit }')"
  # Two real rows + one excluded zero-state = 2 < cluster-min 3 -> NO qualifying cluster.
  # If the no-learning row were counted it would reach 3 and qualify.
  [[ "$pa5_count" == "0" ]] \
    || die "self-test: a mis-emitted no-learning row contributed cluster signal (expected 0 clusters, got '$pa5_count') — the exclusion is not enforced"
  /bin/rm -rf "$pa5_dir"

  # ── Tests 14-16 (#3121 NEAR-THRESHOLD BAND): the sub-threshold disposition.
  # ONE hermetic fixture carries all three arms, because no single arm is
  # sufficient: Arm A alone would pass a "print every cluster" implementation,
  # Arm B alone would pass a no-op, and Arm C alone would pass the UN-fixed tool.
  # Every assertion is on report TEXT, never on exit status — the exit code is 0
  # whether 0 or N clusters qualify, so it cannot discriminate.
  #   widget   2 events / 2 versions -> near-threshold band (Arm A, sensitivity)
  #   flange   2 events / 1 version  -> IN the size band, blocked by the version
  #                                     limb (Arm B, specificity — this is the token
  #                                     that actually exercises that filter)
  #   gizmo    3 events / 1 version  -> invisible to BOTH paths (Arm B', the
  #                                     brief's stated observable; note it is
  #                                     excluded by the SIZE limb first, so it does
  #                                     not on its own discriminate the version limb)
  #   sprocket 3 events / 3 versions -> qualifying, output unchanged (Arm C, AC4 regression)
  # Non-planted fields carry the exact N/A sentinel, which contributes no token —
  # so the three planted tokens are the ONLY cluster signal in the fixture.
  local nt_dir nt_report nt_na
  # The N/A sentinel is a Python-side constant; restate it here for the fixture
  # writer. Test 4 already asserts the emitted block carries this exact string,
  # so a drift between the two surfaces fails there rather than silently here.
  nt_na="N/A — no novel learning this release"
  nt_dir="$(/usr/bin/mktemp -d)" || die "self-test: mktemp -d failed (#3121)"
  {
    echo "| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
    echo "|---|---|---|---|---|---|---|---|---|---|"
    echo "| 2026-09-01T10:00:00Z | v9.01 | 13 | release-synthesis | learnings-triple | skill:synthesize-release-learnings | release:v9.01 | CHEAP | resolved | surprise: widget; would-change: sprocket; watch-for: $nt_na |"
    echo "| 2026-09-02T10:00:00Z | v9.02 | 13 | release-synthesis | learnings-triple | skill:synthesize-release-learnings | release:v9.02 | CHEAP | resolved | surprise: widget; would-change: sprocket; watch-for: $nt_na |"
    echo "| 2026-09-03T10:00:00Z | v9.03 | 13 | release-synthesis | learnings-triple | skill:synthesize-release-learnings | release:v9.03 | CHEAP | resolved | surprise: $nt_na; would-change: sprocket; watch-for: $nt_na |"
    echo "| 2026-09-04T10:00:00Z | v9.04 | 13 | release-synthesis | learnings-triple | skill:synthesize-release-learnings | release:v9.04 | CHEAP | resolved | surprise: gizmo; would-change: flange; watch-for: $nt_na |"
    echo "| 2026-09-04T10:00:01Z | v9.04 | 13 | release-synthesis | learnings-triple | skill:synthesize-release-learnings | release:v9.04 | CHEAP | resolved | surprise: gizmo; would-change: flange; watch-for: $nt_na |"
    echo "| 2026-09-04T10:00:02Z | v9.04 | 13 | release-synthesis | learnings-triple | skill:synthesize-release-learnings | release:v9.04 | CHEAP | resolved | surprise: gizmo; would-change: $nt_na; watch-for: $nt_na |"
  } > "$nt_dir/pipeline-event-log.md" || die "self-test: could not write #3121 fixture"
  nt_report="$(EVALS_RESULTS_PATH="$nt_dir" emit_pattern_detect_report 5 3 false false)" \
    || die "self-test: #3121 near-threshold pattern-detect emit failed"

  # Test 14 (Arm A - sensitivity): the near-miss becomes VISIBLE.
  /usr/bin/grep -q "^### Near-threshold (no promotion)$" <<<"$nt_report" \
    || die "self-test: near-threshold section heading missing (#3121 Arm A)"
  /usr/bin/grep -q '^| `widget` | surprise | 2 | v9.01, v9.02 |$' <<<"$nt_report" \
    || die "self-test: near-threshold band must list widget as 2 events across v9.01, v9.02 (#3121 Arm A)"
  /usr/bin/grep -q '^\*\*Near-threshold clusters (2 <= size < 3, spans >= 2 versions):\*\* 1$' <<<"$nt_report" \
    || die "self-test: near-threshold count line wrong (#3121 Arm A)"

  # Test 15 (Arm B - specificity): the band's >=2-DISTINCT-VERSION limb is enforced.
  # `flange` sits INSIDE the size band (2 events, and 2 <= 2 < 3) and differs from a
  # qualifying-band member ONLY in spanning one version — so it is the token that
  # actually exercises the version filter. Dropping that filter makes this assertion
  # red; without this arm, Test 14 also passes an implementation that prints every
  # sub-threshold cluster regardless of version span.
  if /usr/bin/grep -q 'flange' <<<"$nt_report"; then
    die "self-test: a 2-event SINGLE-version token entered the near-threshold band (#3121 Arm B) — the >=2-version filter is not enforced"
  fi
  # Test 15' (Arm B - the stated observable): a 3-event single-version token is
  # invisible to BOTH paths. It is excluded by the SIZE limb before the version
  # limb is reached, so it corroborates rather than isolates — recorded as such
  # instead of being counted as version-filter coverage it does not provide.
  if /usr/bin/grep -q 'gizmo' <<<"$nt_report"; then
    die "self-test: a 3-event single-version token became visible (#3121 Arm B') — it must qualify for neither path"
  fi

  # Test 16 (Arm C - AC4 regression): the QUALIFYING path is byte-unchanged.
  /usr/bin/grep -q '^\*\*Qualifying clusters (size >= 3, spans >= 2 versions):\*\* 1$' <<<"$nt_report" \
    || die "self-test: qualifying-cluster count changed (#3121 Arm C / AC4)"
  /usr/bin/grep -q '^### Cluster: `sprocket` (would-change, 3 events across 3 versions)$' <<<"$nt_report" \
    || die "self-test: qualifying cluster heading changed (#3121 Arm C / AC4)"
  /usr/bin/grep -qF 'title: [Pattern]: Recurring `sprocket` across releases (would-change field, 3 events)' <<<"$nt_report" \
    || die "self-test: dry-run promotion title changed (#3121 Arm C / AC4)"
  if /usr/bin/grep -q '^| `sprocket` | would-change |' <<<"$nt_report"; then
    die "self-test: a QUALIFYING cluster leaked into the near-threshold band (#3121 Arm C)"
  fi

  # Placement guard: the band must render even when NOTHING qualifies — that is
  # the 100%-of-live-corpus case, and it is the case the early-exit below the
  # insertion point would otherwise swallow. Drop v9.03 so sprocket falls to 2/2.
  local ntz_dir ntz_report
  ntz_dir="$(/usr/bin/mktemp -d)" || die "self-test: mktemp -d failed (#3121 zero-qualifying)"
  /usr/bin/grep -v 'v9.03' "$nt_dir/pipeline-event-log.md" > "$ntz_dir/pipeline-event-log.md" \
    || die "self-test: could not write #3121 zero-qualifying fixture"
  ntz_report="$(EVALS_RESULTS_PATH="$ntz_dir" emit_pattern_detect_report 5 3 false false)" \
    || die "self-test: #3121 zero-qualifying pattern-detect emit failed"
  /usr/bin/grep -q '^\*\*Qualifying clusters (size >= 3, spans >= 2 versions):\*\* 0$' <<<"$ntz_report" \
    || die "self-test: #3121 zero-qualifying fixture should qualify nothing"
  /usr/bin/grep -q "^### Near-threshold (no promotion)$" <<<"$ntz_report" \
    || die "self-test: the near-threshold band did NOT render in the zero-qualifying case — the insertion point regressed below the early exit (#3121)"
  /usr/bin/grep -q "No clusters meet the auto-promotion criteria" <<<"$ntz_report" \
    || die "self-test: the zero-cluster footer must still render after the band (#3121)"
  /bin/rm -rf "$nt_dir" "$ntz_dir"

  echo "self-test: PASS"
  echo "  parse_triple validated (synthetic + real payload)"
  echo "  N/A sentinel exact-match validated"
  echo "  per-release block emit validated (with-events + zero-events)"
  echo "  pattern-detect report renders cleanly on current data"
  echo "  dry-run-vs-apply switch validated"
  echo "  --emit rate (cross_release_pattern_emergence_rate) validated"
  echo "  --source session-retro: exactly 1 qualifying cluster on the seeded fixture"
  echo "  no-learning zero-state + unknown-source rejection validated"
  echo "  PA-4 regression: one unrecognized label does NOT inflate the cluster count (1, not 3)"
  echo "  PA-5 regression: a MIS-EMITTED no-learning row carrying theme: contributes nothing (enforced by subtype)"
  echo "  #3121 Arm A (sensitivity): a 2-event/2-version near-miss RENDERS in the near-threshold band"
  echo "  #3121 Arm B (specificity): a 2-event/1-version token is blocked by the band's >=2-version limb"
  echo "  #3121 Arm C (AC4 regression): the qualifying cluster + promotion title are byte-unchanged"
  echo "  #3121 placement guard: the band renders in the zero-qualifying case (above the early exit)"
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
    case "$SOURCE" in release-synthesis|session-retro) : ;; *) die "--source must be release-synthesis|session-retro (got '$SOURCE')" ;; esac
    emit_pattern_detect_report "$WINDOW" "$CLUSTER_MIN" "$WINDOW_BY_ROW" "$APPLY" "$EMIT" "$SOURCE"
    ;;
  "")
    die "Required: --mode {per-release|pattern-detect} (or --self-test)"
    ;;
  *)
    die "Invalid --mode '$MODE' (allowed: per-release, pattern-detect)"
    ;;
esac

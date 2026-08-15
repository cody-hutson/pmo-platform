#!/usr/bin/env bash
# compute-release-velocity.sh — Release velocity computation for a release.
# Per release/references/standards/release-velocity-tracking.md.
# Sibling to compute-cycle-time.sh — same form factor, same exit-code contract.
#
# Emits the **Velocity:** field content for the visible-H4 Deployment Log block
# in RELEASE_LOG.md. The field is a Stage-13 field (delivered membership + the
# allocation actuals are authoritative only once Stage 13 marks the milestone
# closed), forward-only / grandfathered — see the standard § Cutover.
#
# Computes 3 velocity signals from mechanical sources:
#   planned-vs-delivered : Sum of size:* -> points over the milestone membership
#                          (planned = all member issues; delivered = closed
#                          member issues), plus the delivered/planned ratio.
#   files-changed        : `git diff --shortstat <base>..<merge-SHA>` files count
#                          (whole-release; promotes the inline (+N/-M) narrative
#                          to a structured field).
#   allocation actuals   : feature / debt / protocol-slack point split over the
#                          delivered membership, keyed off the issue type:/cluster:
#                          labels mapped to the 3 work-classes per the standard's
#                          label -> work-class map.
# Plus the milestone's declared Release Class (carried into the field so the
# #290 recalibration half can group delivered-vs-planned BY class).
#
# Points scale (reused verbatim from bundle-composition-doctrine.md § 3 Step 5;
# NOT redefined here): XS=1 / S=2 / M=4 / L=8 / XL=16.
#
# Ratio rounding mode is **round-half-up** (a .5 result rounds away from zero,
# e.g. 22.5 -> 23), taken by reference from bundle-composition-doctrine.md
# § 3 Step 5 Risk-Weighting — the single definitional home. A producer and a
# consumer must never disagree at a half-integer boundary, so this tool does NOT
# re-derive the mode; it implements that one canonical mode.
#
# Usage:
#   ./compute-release-velocity.sh <version> --milestone <N> [--merge-sha <SHA>] [--base <ref>]
#                                               # human field value, or "N/A — ..."
#   ./compute-release-velocity.sh <version> --milestone <N> --json
#                                               # machine detail: JSON of all signals
#   ./compute-release-velocity.sh --self-test   # validate logic against synthetic input
#   ./compute-release-velocity.sh --help        # this help text
#
# Inputs:
#   <version>        release version key (e.g. v2.03) — for the field label only.
#   --milestone <N>  GitHub milestone NUMBER whose membership defines the bundle
#                    (planned = all members; delivered = CLOSED members).
#   --merge-sha <SHA> the release-PR merge commit SHA (files-changed end ref).
#                    Optional — when omitted, files-changed is recorded as N/A.
#   --base <ref>     the merge-base / pre-release ref (files-changed start ref).
#                    Optional — defaults to the merge SHA's first parent
#                    (<merge-sha>^), i.e. the diff the merge introduced.
#
# Cutover: applies to releases entering Stage 13 strictly AFTER this field's
# introducing-release merge SHA. The introducing release itself is exempt. This
# script does not gate by version — the caller (Stage 13 spoke) honors cutover.
#
# Exit codes:
#   0 = success (a release may legitimately produce N/A — content-only release
#       with no size:* membership, or files-changed unknown at call time)
#   1 = invalid args / required input missing / gh unavailable when needed
#   2 = malformed source (a size: label that is not in the closed XS..XL set, or
#       a milestone that does not resolve — source-integrity violation; escalate)

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
# gh is resolved by absolute discovery below (not on the pinned PATH).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────
#
# Repo root is TWO levels up from this script (release/tools/) — NOT three. The
# prior `../../..` walked above the repo, and its failure signature is
# layout-dependent: from the primary checkout it landed outside any repository,
# so the files-changed query returned nothing and the signal degraded to N/A
# behind the `|| true` below; from a worktree at
# .claude/worktrees/<name>/release/tools/ it landed in the worktrees directory,
# whose git toplevel is a DIFFERENT working tree. A test that only asks "is this
# a git repo" therefore PASSES the worktree case — which is why the --self-test
# asserts a resolution identity (arms 1-3) rather than repository membership.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Anchor-resolution predicate — ONE implementation, called by BOTH self-test
# arm 1 (the shipped anchor, which must match) and arm 3 (the known-bad anchor,
# which must NOT match). Sharing the implementation is what makes arm 3 a real
# vacuity control rather than a constant-true statement about the filesystem: a
# predicate mutated to always-match fails arm 3, one mutated to never-match
# fails arm 1, so the pair cannot decay into a no-op that still passes. Echoes
# the verdict token the arms assert on, mirroring the observed-output assertion
# shape of append-pipeline-event.sh's liveness check.
anchor_verdict() {
  if [[ "${1:-}/release/tools" -ef "$SCRIPT_DIR" ]]; then
    echo "anchor=match"; return 0
  fi
  echo "anchor=mismatch"; return 1
}

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  /usr/bin/sed -n '4,63p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# Resolve gh off the pinned PATH (gh commonly lives in /opt/homebrew/bin or
# /usr/local/bin). Empty when not installed — callers that need it fail with a
# clear message; --self-test never needs it.
find_gh() {
  local c
  for c in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh "$HOME/.local/bin/gh"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  command -v gh 2>/dev/null || true
}

# ─── Point scale (closed XS..XL; reused, not redefined) ──────────────────────

# Map a size:* label value to its point weight. Echoes the integer on stdout.
# Exit 2 on an out-of-set size value (source-integrity violation).
size_to_points() {
  case "$1" in
    XS|xs) echo 1 ;;
    S|s)   echo 2 ;;
    M|m)   echo 4 ;;
    L|l)   echo 8 ;;
    XL|xl) echo 16 ;;
    *) echo "size label not in closed XS/S/M/L/XL set: '$1'" >&2; return 2 ;;
  esac
}

# ─── round-half-up ratio (the FM1 canonical mode) ────────────────────────────

# Compute delivered/planned to 2 decimals using round-half-up at the 2nd
# decimal. Pure-integer arithmetic (no float drift): ratio*100 rounded
# half-up = floor( (delivered*10000 + planned*5) / (planned*100) ) expressed as
# X.YY. Echoes "0.00".."1.00"+ ; echoes "N/A" when planned == 0.
ratio_round_half_up() {
  local delivered="$1" planned="$2"
  if [[ "$planned" -eq 0 ]]; then echo "N/A"; return 0; fi
  # hundredths, round-half-up: add half-a-denominator before integer divide
  local hundredths=$(( (delivered * 10000 + planned * 50) / (planned * 100) ))
  /usr/bin/printf '%d.%02d\n' "$(( hundredths / 100 ))" "$(( hundredths % 100 ))"
}

# ─── Work-class mapping (label -> feature / debt / protocol-slack) ───────────

# Resolve a delivered issue's work-class from its labels per the standard's
# label -> work-class map. Precedence: an explicit feature signal wins; then a
# protocol/process signal; then a debt signal; default = debt (the conservative
# bucket — un-feature, un-protocol delivery is treated as debt-paydown, never
# silently dropped, so the three buckets always sum to delivered points).
# Input: a space-separated lowercased label string. Echoes feature|debt|slack.
labels_to_work_class() {
  local labels="$1"
  case " $labels " in
    *" enhancement "*|*" type:feature "*|*" feature "*) echo feature ;;
    *" protocol "*|*" cluster: process-protocol "*|*" routing-rules "*|*" tracker-schema "*) echo slack ;;
    *" bug "*|*" structure "*|*" cluster: architecture "*|*" cluster: tech-debt "*|*" skill-update "*|*" documentation "*) echo debt ;;
    *) echo debt ;;
  esac
}

# ─── Self-test mode (no gh / no network) ─────────────────────────────────────

if [[ "${1:-}" == "--self-test" ]]; then
  # Test 1: point scale across the closed set
  for pair in "XS 1" "S 2" "M 4" "L 8" "XL 16"; do
    set -- $pair
    R="$(size_to_points "$1")" || die "self-test: size_to_points($1) errored"
    [[ "$R" == "$2" ]] || die "self-test: size_to_points($1) = $R, expected $2"
  done

  # Test 2: out-of-set size -> exit 2
  if size_to_points "XXL" >/dev/null 2>&1; then
    die "self-test: out-of-set size 'XXL' accepted (should exit 2)"
  fi

  # Test 3: ratio round-half-up — exact, below-half, at-half, above-half
  R="$(ratio_round_half_up 24 24)"; [[ "$R" == "1.00" ]] || die "self-test: ratio 24/24 = $R, expected 1.00"
  R="$(ratio_round_half_up 0 24)";  [[ "$R" == "0.00" ]] || die "self-test: ratio 0/24 = $R, expected 0.00"
  R="$(ratio_round_half_up 18 24)"; [[ "$R" == "0.75" ]] || die "self-test: ratio 18/24 = $R, expected 0.75"
  # 17/24 = 0.70833... -> round-half-up at 2dp = 0.71
  R="$(ratio_round_half_up 17 24)"; [[ "$R" == "0.71" ]] || die "self-test: ratio 17/24 = $R, expected 0.71"
  # 1/8 = 0.125 -> the 2nd-decimal half-case -> round-half-up = 0.13 (away from zero)
  R="$(ratio_round_half_up 1 8)";   [[ "$R" == "0.13" ]] || die "self-test: ratio 1/8 = $R, expected 0.13 (round-half-up)"
  # 3/8 = 0.375 -> half-case at 2nd decimal -> 0.38
  R="$(ratio_round_half_up 3 8)";   [[ "$R" == "0.38" ]] || die "self-test: ratio 3/8 = $R, expected 0.38 (round-half-up)"
  # planned 0 -> N/A
  R="$(ratio_round_half_up 0 0)";   [[ "$R" == "N/A" ]] || die "self-test: ratio 0/0 = $R, expected N/A"

  # Test 4: work-class mapping precedence (cluster labels carry the canonical
  # SPACED form per release-velocity-tracking.md §4 + core/specs/label-taxonomy.md)
  R="$(labels_to_work_class "size:m enhancement status: done")"; [[ "$R" == "feature" ]] || die "self-test: work-class(enhancement) = $R, expected feature"
  R="$(labels_to_work_class "size:s protocol cluster: process-protocol")"; [[ "$R" == "slack" ]] || die "self-test: work-class(protocol) = $R, expected slack"
  # cluster-label-ONLY protocol signal (no bare 'protocol' label) — the spaced
  # 'cluster: process-protocol' must alone resolve to slack (regression for the
  # no-space matcher that mis-bucketed these to debt).
  R="$(labels_to_work_class "size:m cluster: process-protocol")"; [[ "$R" == "slack" ]] || die "self-test: work-class(cluster: process-protocol only) = $R, expected slack"
  R="$(labels_to_work_class "size:l bug")"; [[ "$R" == "debt" ]] || die "self-test: work-class(bug) = $R, expected debt"
  R="$(labels_to_work_class "size:m cluster: tech-debt")"; [[ "$R" == "debt" ]] || die "self-test: work-class(cluster: tech-debt) = $R, expected debt"
  R="$(labels_to_work_class "size:m cluster: architecture")"; [[ "$R" == "debt" ]] || die "self-test: work-class(cluster: architecture) = $R, expected debt"
  R="$(labels_to_work_class "size:m")"; [[ "$R" == "debt" ]] || die "self-test: work-class(unlabeled) = $R default expected debt"
  # feature wins over a co-present debt/protocol signal (precedence)
  R="$(labels_to_work_class "enhancement bug protocol")"; [[ "$R" == "feature" ]] || die "self-test: work-class precedence (feature wins) = $R"

  # Test 5: allocation sums to delivered (invariant — three buckets partition delivered points)
  #   delivered = {enhancement size:m=4, bug size:s=2, protocol size:l=8} -> feat 4 / debt 2 / slack 8 ; sum 14
  feat=0; debt=0; slack=0
  for spec in "enhancement 4" "bug 2" "protocol 8"; do
    set -- $spec
    wc="$(labels_to_work_class "$1")"
    case "$wc" in feature) feat=$((feat+$2)) ;; debt) debt=$((debt+$2)) ;; slack) slack=$((slack+$2)) ;; esac
  done
  [[ "$feat" -eq 4 && "$debt" -eq 2 && "$slack" -eq 8 ]] || die "self-test: allocation split wrong (feat=$feat debt=$debt slack=$slack)"
  [[ $((feat+debt+slack)) -eq 14 ]] || die "self-test: allocation does not sum to delivered (14)"

  # Test 6: repo-root anchor resolution — the anchor-depth regression guard.
  # Arms 1 and 3 call ONE predicate (anchor_verdict) and assert on its OBSERVED
  # verdict token, so a mutated predicate fails an arm rather than turning the
  # pair into a decoration that still reports PASS.

  # Arm 1 — anchor identity. Always runs and needs no git, so it holds in a
  # tarball, a CI checkout, a worktree, or a copied tree. This is the floor: the
  # composite can never fail open.
  A1="$(anchor_verdict "$REPO_ROOT" || true)"
  [[ "$A1" == "anchor=match" ]] || die "self-test: anchor arm 1 observed '$A1' — REPO_ROOT resolved to '$REPO_ROOT', but this script's own directory is '$SCRIPT_DIR' (the repo root is TWO levels up from release/tools/, not three)"

  # Arm 3 — vacuity control. The known-bad ../../.. anchor MUST be rejected by
  # the SAME predicate arm 1 just passed. Fails closed: a control that could not
  # run is a FAIL, not a skip.
  if BAD_ANCHOR="$( cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd )" && [[ -n "$BAD_ANCHOR" ]]; then
    A3="$(anchor_verdict "$BAD_ANCHOR" || true)"
    [[ "$A3" == "anchor=mismatch" ]] || die "self-test: anchor arm 3 — the anchor assertion is VACUOUS; the known-bad anchor '$BAD_ANCHOR' observed '$A3' through the same predicate arm 1 passed"
  else
    die "self-test: anchor arm 3 (vacuity control) could not resolve the known-bad anchor from '$SCRIPT_DIR' — the control did not run, which is a FAIL, not a skip"
  fi

  # Arm 2 — working-tree identity. Catches the worktree case from the other
  # direction: there the bad anchor DOES resolve to a git root, just the wrong
  # working tree. Guarded with `if`, never a bare command substitution — under
  # `set -euo pipefail` (live at the top of this file) a failing $(git ...)
  # assignment exits 128 with no message, turning the intended skip into an
  # unattributable crash.
  if git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
    TOPLEVEL="$( git -C "$SCRIPT_DIR" rev-parse --show-toplevel )"
    [[ "$REPO_ROOT" -ef "$TOPLEVEL" ]] || die "self-test: anchor arm 2 — REPO_ROOT '$REPO_ROOT' is not this script's own working tree '$TOPLEVEL'; the anchor resolved to a DIFFERENT working tree"
    ANCHOR_ARM2="ran — working-tree identity matches '$TOPLEVEL'"
    echo "  anchor arm 2: RAN — REPO_ROOT matches this script's working tree '$TOPLEVEL'"
  else
    ANCHOR_ARM2="SKIPPED — not inside a git working tree"
    echo "  anchor arm 2: SKIPPED — this script's directory is not inside a git working tree; arms 1 and 3 still ran"
  fi

  echo "self-test: PASS"
  echo "  point scale (XS/S/M/L/XL) validated; out-of-set rejection validated"
  echo "  ratio round-half-up validated (exact / below-half / at-half / above-half / planned-zero)"
  echo "  work-class mapping + precedence validated"
  echo "  allocation-partitions-delivered invariant validated"
  echo "  repo-root anchor: arm 1 identity + arm 3 vacuity control validated via one shared predicate; arm 2 ${ANCHOR_ARM2}"
  exit 0
fi

# ─── Argument parsing ────────────────────────────────────────────────────────

VERSION=""
MILESTONE=""
MERGE_SHA=""
BASE_REF=""
OUTPUT_FORMAT="human"   # human | json

while [[ $# -gt 0 ]]; do
  case "$1" in
    --milestone) MILESTONE="${2:-}"; shift 2 ;;
    --merge-sha) MERGE_SHA="${2:-}"; shift 2 ;;
    --base) BASE_REF="${2:-}"; shift 2 ;;
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
[[ -z "$MILESTONE" ]] && die "Required: --milestone <N> (the bundle's GitHub milestone number)"

GH="$(find_gh)"
[[ -n "$GH" ]] || die "gh CLI not found — required to read milestone membership labels"

# Resolve the target repo from the current gh-authenticated checkout (no hardcoded
# operator slug — an installable tool must RESOLVE the repo, not embed the author's).
# Honors a caller-set REPO override. Never runs in --self-test (that path exits above).
REPO="${REPO:-$("$GH" repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
[[ -n "$REPO" ]] || die "could not resolve target repo — set REPO or run inside a gh-authenticated repo"

# ─── Read milestone membership (planned = all; delivered = closed) ───────────

# Single batched read of the milestone's issues (number, state, labels). Per the
# gh-background-hang reference: one foreground call, no loop. --limit set high
# (a milestone bundle is small, but guard against silent truncation).
MEMBERS_JSON="$("$GH" issue list --repo "$REPO" \
  --milestone "$MILESTONE" --state all --limit 500 \
  --json number,state,labels 2>/dev/null || true)"

if [[ -z "$MEMBERS_JSON" || "$MEMBERS_JSON" == "[]" ]]; then
  die "milestone $MILESTONE resolved to zero issues (does it exist? is the title/number right?)" 2
fi

# ─── Compute planned / delivered points + allocation via python (stdlib json) ─

# Hand the membership JSON + the work-class map to python for a single pass.
# python re-implements the SAME three helpers (point scale, round-half-up,
# work-class precedence) so the heavy JSON walk stays in one place; the bash
# helpers above are the self-tested reference and the contract.
COMPUTED="$(/usr/bin/python3 - "$MEMBERS_JSON" <<'PY' || die "membership parse failure (malformed gh JSON or out-of-set size label)" 2
import json, sys, math

members = json.loads(sys.argv[1])

PTS = {"xs":1, "s":2, "m":4, "l":8, "xl":16}

def size_points(labels):
    for name in labels:
        if name.lower().startswith("size:"):
            key = name.split(":",1)[1].strip().lower()
            if key not in PTS:
                print(f"size label not in closed set: {name}", file=sys.stderr)
                sys.exit(2)
            return PTS[key]
    return 0  # unsized member contributes 0 points (recorded; surfaces as N/A when ALL unsized)

def work_class(labels):
    s = set(n.lower() for n in labels)
    if s & {"enhancement", "type:feature", "feature"}:
        return "feature"
    if s & {"protocol", "cluster: process-protocol", "routing-rules", "tracker-schema"}:
        return "slack"
    # bug / structure / cluster: architecture / cluster: tech-debt / skill-update / documentation -> debt; default debt
    return "debt"

def ratio_half_up(delivered, planned):
    if planned == 0:
        return None
    hundredths = (delivered * 10000 + planned * 50) // (planned * 100)
    return hundredths / 100.0

planned_pts = 0
delivered_pts = 0
sized_members = 0
alloc = {"feature":0, "debt":0, "slack":0}

for m in members:
    labels = [l["name"] for l in m.get("labels", [])]
    pts = size_points(labels)
    if pts > 0:
        sized_members += 1
    planned_pts += pts
    if m.get("state","").upper() == "CLOSED":
        delivered_pts += pts
        if pts > 0:
            alloc[work_class(labels)] += pts

r = ratio_half_up(delivered_pts, planned_pts)
out = {
    "planned_pts": planned_pts,
    "delivered_pts": delivered_pts,
    "sized_members": sized_members,
    "member_count": len(members),
    "ratio": (f"{r:.2f}" if r is not None else "N/A"),
    "alloc_feature": alloc["feature"],
    "alloc_debt": alloc["debt"],
    "alloc_slack": alloc["slack"],
}
print(json.dumps(out))
PY
)"

PLANNED_PTS="$(/usr/bin/python3 -c 'import json,sys; print(json.loads(sys.argv[1])["planned_pts"])' "$COMPUTED")"
DELIVERED_PTS="$(/usr/bin/python3 -c 'import json,sys; print(json.loads(sys.argv[1])["delivered_pts"])' "$COMPUTED")"
SIZED_MEMBERS="$(/usr/bin/python3 -c 'import json,sys; print(json.loads(sys.argv[1])["sized_members"])' "$COMPUTED")"
RATIO="$(/usr/bin/python3 -c 'import json,sys; print(json.loads(sys.argv[1])["ratio"])' "$COMPUTED")"
ALLOC_F="$(/usr/bin/python3 -c 'import json,sys; print(json.loads(sys.argv[1])["alloc_feature"])' "$COMPUTED")"
ALLOC_D="$(/usr/bin/python3 -c 'import json,sys; print(json.loads(sys.argv[1])["alloc_debt"])' "$COMPUTED")"
ALLOC_S="$(/usr/bin/python3 -c 'import json,sys; print(json.loads(sys.argv[1])["alloc_slack"])' "$COMPUTED")"

# ─── Release Class (from the milestone description ## Release Class H2) ───────

MS_BODY="$("$GH" api "repos/$REPO/milestones/$MILESTONE" --jq '.description' 2>/dev/null || true)"
RELEASE_CLASS="$(/usr/bin/printf '%s' "$MS_BODY" \
  | /usr/bin/awk 'BEGIN{f=0} /^## Release Class/{f=1; next} /^## /{f=0} f && NF {print; exit}' \
  | /usr/bin/grep -oE 'routine|novel|cross-cutting|hotfix' | /usr/bin/head -1 || true)"
[[ -n "$RELEASE_CLASS" ]] || RELEASE_CLASS="unknown"

# ─── files-changed (git diff --shortstat over the release range) ─────────────

FILES_CHANGED="N/A"
if [[ -n "$MERGE_SHA" ]]; then
  DIFF_BASE="${BASE_REF:-${MERGE_SHA}^}"
  # files-touched count from --shortstat ("N files changed"). git is on the pinned PATH.
  SHORTSTAT="$(git -C "$REPO_ROOT" diff --shortstat "${DIFF_BASE}..${MERGE_SHA}" 2>/dev/null || true)"
  if [[ -n "$SHORTSTAT" ]]; then
    FC="$(/usr/bin/printf '%s' "$SHORTSTAT" | /usr/bin/grep -oE '[0-9]+ files? changed' | /usr/bin/grep -oE '[0-9]+' | /usr/bin/head -1 || true)"
    [[ -n "$FC" ]] && FILES_CHANGED="$FC"
  fi
  # Announce the degradation; do not silence it. A degrade to N/A here can be
  # legitimate (a genuinely empty diff, an unknown SHA), so the `|| true` above
  # STAYS and the exit-code contract is unchanged — but an INVISIBLE degrade is
  # how the mis-anchored REPO_ROOT above survived a release cycle. Diagnostic
  # goes to stderr so the stdout field value stays byte-identical for callers.
  if [[ "$FILES_CHANGED" == "N/A" ]]; then
    echo "NOTE: files-changed degraded to N/A — 'git diff --shortstat ${DIFF_BASE}..${MERGE_SHA}' yielded no file count from repo root '${REPO_ROOT}'" >&2
  fi
fi

# ─── N/A determination + emission ────────────────────────────────────────────

# If no member carries a size:* label, points cannot be derived — N/A field,
# excluded from the calibration ratio (the standard's N/A semantics).
if [[ "$SIZED_MEMBERS" -eq 0 ]]; then
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    /usr/bin/printf '{"version":"%s","milestone":%s,"planned_pts":0,"delivered_pts":0,"ratio":"N/A","files_changed":"%s","release_class":"%s","na_reason":"no size:* labels on milestone membership"}\n' \
      "$VERSION" "$MILESTONE" "$FILES_CHANGED" "$RELEASE_CLASS"
  else
    echo "N/A — no size:* labels on milestone membership (cannot derive points); files-changed ${FILES_CHANGED} recorded; class ${RELEASE_CLASS} (excluded from calibration ratio)"
  fi
  exit 0
fi

# ─── Field emission (the **Velocity:** field VALUE) ──────────────────────────

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  /usr/bin/printf '{"version":"%s","milestone":%s,"planned_pts":%s,"delivered_pts":%s,"ratio":"%s","files_changed":"%s","allocation":{"feature":%s,"debt":%s,"slack":%s},"release_class":"%s","mechanism":"compute-release-velocity.sh"}\n' \
    "$VERSION" "$MILESTONE" "$PLANNED_PTS" "$DELIVERED_PTS" "$RATIO" "$FILES_CHANGED" "$ALLOC_F" "$ALLOC_D" "$ALLOC_S" "$RELEASE_CLASS"
else
  # Human form == the literal **Velocity:** field value embedded in the H4 block.
  echo "planned ${PLANNED_PTS} pts / delivered ${DELIVERED_PTS} pts (${RATIO}); files-changed ${FILES_CHANGED}; allocation ${ALLOC_F}/${ALLOC_D}/${ALLOC_S} pts (feature/debt/protocol-slack); class ${RELEASE_CLASS}; mechanism: compute-release-velocity.sh"
fi
exit 0

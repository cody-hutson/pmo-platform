#!/usr/bin/env bash
# compute-release-velocity.sh — Release velocity computation for a release.
# Per release/references/standards/release-velocity-tracking.md.
# Sibling to compute-cycle-time.sh — same form factor, same exit-code contract.
#
# Emits the **Velocity:** field content for the visible-H4 Deployment Log block
# in RELEASE_LOG.md. The field is a Stage-13 field, forward-only / grandfathered
# — see the standard § Cutover.
#
# THE DELIVERY PREDICATE IS CLOSE-STATE-INDEPENDENT, AND THAT IS THE POINT.
# An earlier form derived `delivered` from issue state (`state == CLOSED`). That
# read is bimodal on a property nothing in the close controls: when the release
# PR's close keywords resolve at Stage 12 the members are already CLOSED and the
# number is right; when they do not, the script's own remedy runs twenty phases
# downstream of this measurement and the field books `delivered 0 pts` on a
# release that shipped everything. Seven rows in the hot ledger recorded that.
# The predicate below reads LABELS and TIMELINE EVENTS instead — evidence that
# does not change between a --no-merge run, a dry run, and an --apply run.
#
# Computes 3 velocity signals from mechanical sources:
#   planned-vs-delivered : Sum of size:* -> points, plus the delivered/planned
#                          ratio, where
#                            delivered = milestone members NOT carrying a
#                                        terminal not-delivered status: label;
#                            planned   = delivered + the members that DID carry
#                                        one, INCLUDING those Phase A2 removed
#                                        from the milestone on the way out
#                                        (recovered from `demilestoned` timeline
#                                        events — see § Phase-A2 recovery below).
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
# ─── Phase-A2 recovery (why `planned` needs it) ──────────────────────────────
#
# stage-13-close.md Phase A2 disposes of a bundled-but-not-closed member by
# applying `status: deferred` AND THEN REMOVING THE MILESTONE. Membership here is
# read via `gh issue list --milestone`, so a Phase-A2-dispositioned member is in
# neither the delivered set NOR the planned set — `planned` silently shrinks to
# equal `delivered` on every governed close, and the ratio pins to 1.00 forever.
# A constant feeds the § 6 capacity-weight recalibration, which cannot move a
# weight. That is a quieter defect than the zero it replaces.
#
# So `planned` is recovered rather than read: over the terminal-status
# population (issues carrying a terminal not-delivered status: label — a bounded
# repo-wide set, ~40 issues, further filtered to the SIZED ones since an unsized
# issue contributes zero points either way), each candidate's `demilestoned`
# events are read and any that names THIS milestone puts the candidate's points
# back into `planned`. Timeline events are immutable, so the recovery is
# order-independent for the same reason the label predicate is.
#
# KNOWN BOUNDS, stated rather than papered over. The join is keyed on the
# milestone TITLE — the `demilestoned` event payload carries no stable milestone
# id — and it is TEMPORALLY UNBOUNDED: any demilestone naming that title counts,
# whenever it happened. The recovery is best-effort in BOTH directions.
#
#   UNDER-reports when a member demilestoned at Phase A2 is later RE-BUNDLED
#   into a different milestone (it loses its terminal status label, leaves the
#   scanned population, and is not recovered), or when the event's title no
#   longer resolves to a live milestone (a rename, or a title the live set never
#   carried) — the fixed-string join can then never fire, and a zero-recovery
#   outcome is indistinguishable from "nothing to recover": the NOTE below fires
#   only when something WAS recovered.
#
#   OVER-reports when a member was milestoned mid-release for provenance and
#   demilestoned long AFTER the release closed. Nothing here distinguishes that
#   from a disposition at this release's Phase A2, so its points are returned to
#   a bundle it was never committed to.
#
# `planned` is therefore NOT a guaranteed bound in either direction. Closing both
# gaps needs the Stage-3 membership snapshot the platform does not yet take.
# REACHABILITY: measured at a release's own Stage 13 the demilestone and the
# close are the same step, so the divergence is not reachable in practice; it
# bites on RECOMPUTATION of a historical row, where the elapsed window admits
# later demilestones.
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
#                    (delivered = members without a terminal not-delivered
#                    status: label; planned = delivered + the marked members,
#                    including the Phase-A2-demilestoned ones recovered above).
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
#       a milestone that does not resolve — source-integrity violation; escalate),
#       OR an implausible measurement: a non-zero planned against delivered 0
#       over a non-empty sized membership. That reading was shipped seven times
#       as a permanent ledger row before anything caught it, so the tool refuses
#       to emit it. A release that genuinely delivered nothing takes the § 7
#       manual-fill fallback, which is a deliberate operator act rather than a
#       silent default.

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
  # Range ends at the last header comment line (the exit-code block), immediately
  # before `set -euo pipefail`. Derived, not hardcoded — the prior literal 4,63p
  # silently truncated --help the moment the header grew.
  local _last; _last="$(/usr/bin/grep -n '^set -euo pipefail' "${BASH_SOURCE[0]}" | /usr/bin/head -1 | /usr/bin/cut -d: -f1)"
  /usr/bin/sed -n "4,$(( _last - 2 ))p" "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
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

# ─── Delivery predicate (terminal not-delivered status markers) ──────────────

# The terminal not-delivered members of the status:* lifecycle, canonical SPACED
# form, comma-separated. ONE definition: `labels_to_delivered` below is the
# self-tested bash reference, and the python pass reads this SAME string through
# argv, so the two cannot drift into two different exclusion SETS.
#
# What the shared constant does NOT buy — stated because asserting it did was an
# overclaim: it does not make the two MATCHERS identical. They differ on CASE
# NORMALIZATION. The bash reference matches the canonical form as written
# (case-sensitive `case` globs); the python pass lowercases each label name
# before the set intersection (see `delivered_member`), so it additionally
# catches a mis-cased variant the reference rejects. Python is strictly the more
# tolerant of the two. The divergence is unreachable on canonical GitHub labels,
# which are lowercase, and the case arm at self-test 5.5(b) now pins the
# reference's half of it rather than leaving it to be discovered.
#
# OPEN-SET CAVEAT, stated because a negative predicate over an open set has no
# failure signal of its own: core/specs/label-taxonomy.md § Status Labels calls
# its status:* enumeration ILLUSTRATIVE and says "the live set is the packs'
# union". This constant is therefore a snapshot of the terminal members the
# shipped packs contribute, NOT a closed universe. A deployment whose pack adds
# another terminal status (say `status: cancelled`) must add it here, or those
# members are silently counted as delivered. The self-test asserts the shape of
# every entry, which is the only check available with no network.
_STATUS_NOT_DELIVERED="status: deferred,status: rejected"

# Resolve whether a member counts as DELIVERED from its labels. Echoes
# delivered|not-delivered.
#
# Match on the FULL canonical spaced label between space boundaries — never a
# prefix and never a bare substring. labels_to_work_class above carries a
# regression comment for exactly this: a no-space matcher mis-bucketed the
# spaced cluster labels. `status: deferred` has the same shape and the same trap.
# Input: a space-separated lowercased label string.
labels_to_delivered() {
  local labels=" $1 " _entry
  local IFS=','
  for _entry in $_STATUS_NOT_DELIVERED; do
    case "$labels" in *" $_entry "*) echo not-delivered; return 0 ;; esac
  done
  echo delivered
}

# ─── Phase-A2 candidate selection ────────────────────────────────────────────
#
# Narrow the terminal-status population to the candidates worth an API call:
# SIZED, and not already a member of this milestone. Emits `<number> <points>`
# per line, then a literal OK sentinel — an empty capture is otherwise
# indistinguishable between "no candidates" (correct) and "the pass crashed"
# (silently under-reports planned).
#
# It is a FUNCTION, and it is defined up here rather than inline in the recovery
# block, for one reason: inline it sat below the --self-test exit, so no arm
# could reach it, and the recovery shipped with zero coverage over its only
# pure-computation step. It takes JSON on argv and touches neither gh nor the
# network, so Test 7 runs the real thing rather than a simulation of it.
#
# Input: $1 = milestone-membership JSON; $2.. = one candidate-list JSON blob per
# exclusion marker. Output on stdout; exit status is python's.
_rv_select_candidates() {
  /usr/bin/python3 - "$@" <<'PY' 2>/dev/null
import json, sys
PTS = {"xs":1, "s":2, "m":4, "l":8, "xl":16}
members = {i.get("number") for i in json.loads(sys.argv[1])}
seen = {}
for b in sys.argv[2:]:
    for it in json.loads(b):
        n = it.get("number")
        if n is None or n in members or n in seen:
            continue
        pts = 0
        for l in it.get("labels", []):
            nm = (l.get("name") or "").lower()
            if nm.startswith("size:"):
                pts = PTS.get(nm.split(":",1)[1].strip(), 0)
                break
        if pts > 0:
            seen[n] = pts
for n in sorted(seen):
    print(n, seen[n])
print("OK")
PY
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

  # Test 5.5: the DELIVERY PREDICATE (#4927) — close-state independence.
  #
  # These arms are the reference contract for the python accumulator below. They
  # run offline against synthetic members, so they assert the RULE; the runtime
  # asserts nothing about the rule at all.

  # (a) the predicate itself, both directions. The pair must DISAGREE — a
  # predicate mutated to always-deliver passes the first arm and fails the
  # second, one mutated to never-deliver does the reverse, so neither can decay
  # into a constant that still reports PASS.
  R="$(labels_to_delivered "size:m status: bundled")";  [[ "$R" == "delivered" ]]     || die "self-test 5.5(a): an unmarked member must be delivered, got '$R'"
  R="$(labels_to_delivered "size:m status: deferred")"; [[ "$R" == "not-delivered" ]] || die "self-test 5.5(a): 'status: deferred' must be not-delivered, got '$R'"
  R="$(labels_to_delivered "size:m status: rejected")"; [[ "$R" == "not-delivered" ]] || die "self-test 5.5(a): 'status: rejected' must be not-delivered, got '$R'"
  R="$(labels_to_delivered "size:m")";                  [[ "$R" == "delivered" ]]     || die "self-test 5.5(a): a bare sized member must default to delivered (never silently drop points), got '$R'"

  # (b) MATCH FIDELITY. The canonical form is SPACED and LOWERCASE. One arm per
  # way a near-miss arrives: a no-space variant, a non-lowercased variant, and
  # the bare word inside an unrelated label must all MISS; a label whose suffix
  # is the marker must miss on the left space boundary; and the marker at the
  # START of the string must HIT. The regression labels_to_work_class already
  # records is the same shape.
  #
  # The case arm is the one this comment used to claim while no assertion
  # covered it. It asserts the REFERENCE's half of a real divergence: the python
  # production pass lowercases first and would read this same fixture as
  # not-delivered (see the note at _STATUS_NOT_DELIVERED). Unreachable on
  # canonical GitHub labels; pinned so a harmonization either way is deliberate.
  R="$(labels_to_delivered "size:m status:deferred")";           [[ "$R" == "delivered" ]] || die "self-test 5.5(b): the unspaced 'status:deferred' is not the canonical label and must NOT match, got '$R'"
  R="$(labels_to_delivered "size:m STATUS: DEFERRED")";          [[ "$R" == "delivered" ]] || die "self-test 5.5(b): the non-lowercased 'STATUS: DEFERRED' is not the canonical label and must NOT match the case-sensitive bash reference, got '$R'"
  R="$(labels_to_delivered "size:m cluster: deferred-intake")";  [[ "$R" == "delivered" ]] || die "self-test 5.5(b): 'deferred' as a SUBSTRING of an unrelated label must NOT match, got '$R'"
  R="$(labels_to_delivered "size:m xstatus: deferred")";         [[ "$R" == "delivered" ]] || die "self-test 5.5(b): a label whose suffix is the marker must NOT match (left space boundary), got '$R'"
  R="$(labels_to_delivered "status: deferred size:m")";          [[ "$R" == "not-delivered" ]] || die "self-test 5.5(b): the marker must match at the START of the label string, got '$R'"

  # (c) the exclusion CONSTANT's shape. The set is open (see the caveat at the
  # constant), so the only offline assertion available is that every entry is a
  # canonically-spaced status: label and that the set is non-empty. An empty or
  # malformed constant would make the predicate silently deliver everything.
  _vd_n=0
  while IFS= read -r _vd_e; do
    if [[ -n "$_vd_e" ]]; then
      case "$_vd_e" in
        "status: "?*) _vd_n=$((_vd_n+1)) ;;
        *) die "self-test 5.5(c): _STATUS_NOT_DELIVERED entry '$_vd_e' is not a canonically-spaced 'status: <value>' label" ;;
      esac
    fi
  done <<< "$(/usr/bin/printf '%s' "$_STATUS_NOT_DELIVERED" | /usr/bin/tr ',' '\n')"
  [[ "$_vd_n" -ge 2 ]] || die "self-test 5.5(c): _STATUS_NOT_DELIVERED resolved to $_vd_n entries; the two terminal statuses the platform ships are the floor"

  # (d) CLOSE-STATE INDEPENDENCE, with the pre-fix predicate as the sensitivity
  # arm. Same fixture, both rules. The fixture is the defect's own shape: three
  # sized members that all shipped, none closed yet, because the release PR's
  # close keywords did not resolve.
  #
  # Without the pre-fix arm this whole group is unfalsifiable — a green run
  # would not distinguish "the fix works" from "the fixture never exercised the
  # defect". The pre-fix arm MUST read 0 here, or Test 5.5 is decoration.
  _vd_new=0; _vd_old=0
  for _vd_spec in "OPEN|status: bundled|4" "OPEN|status: bundled|2" "OPEN|status: bundled|8"; do
    _vd_state="${_vd_spec%%|*}"; _vd_rest="${_vd_spec#*|}"
    _vd_labels="${_vd_rest%%|*}"; _vd_pts="${_vd_rest##*|}"
    if [[ "$(labels_to_delivered "$_vd_labels")" == "delivered" ]]; then _vd_new=$((_vd_new + _vd_pts)); fi
    if [[ "$_vd_state" == "CLOSED" ]]; then _vd_old=$((_vd_old + _vd_pts)); fi
  done
  [[ "$_vd_new" -eq 14 ]] || die "self-test 5.5(d): the label predicate must deliver all 14 pts on an all-shipped/none-closed fixture, got $_vd_new"
  [[ "$_vd_old" -eq 0 ]]  || die "self-test 5.5(d) SENSITIVITY: the pre-fix close-state predicate must report 0 on this fixture — it read $_vd_old, so the fixture does not exercise the defect and this group asserts nothing"

  # ...and the same two rules must AGREE on a fixture where the close keywords
  # did resolve. A fix that is order-independent by breaking the healthy path is
  # not a fix.
  _vd_new=0; _vd_old=0
  for _vd_spec in "CLOSED|status: bundled|4" "CLOSED|status: bundled|2" "CLOSED|status: bundled|8"; do
    _vd_state="${_vd_spec%%|*}"; _vd_rest="${_vd_spec#*|}"
    _vd_labels="${_vd_rest%%|*}"; _vd_pts="${_vd_rest##*|}"
    if [[ "$(labels_to_delivered "$_vd_labels")" == "delivered" ]]; then _vd_new=$((_vd_new + _vd_pts)); fi
    if [[ "$_vd_state" == "CLOSED" ]]; then _vd_old=$((_vd_old + _vd_pts)); fi
  done
  [[ "$_vd_new" -eq "$_vd_old" && "$_vd_new" -eq 14 ]] || die "self-test 5.5(d): on the healthy (auto-closed) path both predicates must read 14; got new=$_vd_new old=$_vd_old"

  # (e) NON-DEGENERACY. `delivered` must be able to differ from `planned`, or
  # the ratio is a constant and the § 6 recalibration reads a value that can
  # never move. planned = every member's points INCLUDING the marked ones and
  # the Phase-A2-recovered ones; delivered excludes the marked.
  _vd_planned=0; _vd_delivered=0
  for _vd_spec in "status: bundled|4" "status: bundled|8" "status: deferred|4"; do
    _vd_labels="${_vd_spec%%|*}"; _vd_pts="${_vd_spec##*|}"
    _vd_planned=$((_vd_planned + _vd_pts))
    if [[ "$(labels_to_delivered "$_vd_labels")" == "delivered" ]]; then _vd_delivered=$((_vd_delivered + _vd_pts)); fi
  done
  # plus one member Phase A2 demilestoned on its way out — recovered into planned only
  _vd_planned=$((_vd_planned + 4))
  [[ "$_vd_planned" -eq 20 && "$_vd_delivered" -eq 12 ]] || die "self-test 5.5(e): planned/delivered must be 20/12 on the mixed fixture, got $_vd_planned/$_vd_delivered"
  [[ "$_vd_delivered" -ne "$_vd_planned" ]] || die "self-test 5.5(e): delivered equals planned on a fixture carrying a deferred AND a recovered member — the ratio is degenerate and cannot inform recalibration"
  R="$(ratio_round_half_up "$_vd_delivered" "$_vd_planned")"; [[ "$R" == "0.60" ]] || die "self-test 5.5(e): ratio 12/20 = $R, expected 0.60"

  # (f) ALLOCATION PARTITIONS DELIVERED, under the NEW predicate. Test 5 asserts
  # the invariant with no exclusions; this arm asserts it survives one. A member
  # excluded from delivered must be excluded from the allocation too, or the
  # three buckets stop summing to delivered.
  feat=0; debt=0; slack=0; _vd_delivered=0
  for _vd_spec in "enhancement status: bundled|4" "bug status: bundled|2" "protocol status: deferred|8"; do
    _vd_labels="${_vd_spec%%|*}"; _vd_pts="${_vd_spec##*|}"
    if [[ "$(labels_to_delivered "$_vd_labels")" == "delivered" ]]; then
      _vd_delivered=$((_vd_delivered + _vd_pts))
      case "$(labels_to_work_class "$_vd_labels")" in
        feature) feat=$((feat+_vd_pts)) ;; debt) debt=$((debt+_vd_pts)) ;; slack) slack=$((slack+_vd_pts)) ;;
      esac
    fi
  done
  [[ $((feat+debt+slack)) -eq "$_vd_delivered" ]] || die "self-test 5.5(f): allocation ($feat/$debt/$slack) does not partition delivered ($_vd_delivered) once a member is excluded"
  [[ "$slack" -eq 0 ]] || die "self-test 5.5(f): the deferred protocol member's 8 pts leaked into the allocation split (slack=$slack)"

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

  # Test 7: PHASE-A2 CANDIDATE SELECTION. The recovery's only pure-computation
  # step had no arm at all: Test 5.5(e) "simulates" a recovered member by adding
  # a literal 4 to a counter, which asserts arithmetic, not the pass. These arms
  # run `_rv_select_candidates` itself on synthetic JSON — no gh, no network.
  #
  # Every filter is paired with a control that CHANGES the result, so no arm can
  # pass because the fixture failed to exercise it. The join itself (the
  # `demilestoned` title match) is NOT covered here — it needs the events API.
  #
  # Fixture: #101 is already on the milestone, #103 is unsized, #102 appears in
  # both blobs, and #105 carries a lowercased size label. Expect 102/104/105
  # only, sorted, sentinel last.
  _cs_members='[{"number":101}]'
  _cs_b1='[{"number":101,"labels":[{"name":"size:M"}]},{"number":102,"labels":[{"name":"size:L"}]},{"number":103,"labels":[{"name":"bug"}]},{"number":104,"labels":[{"name":"size:XS"}]}]'
  _cs_b2='[{"number":102,"labels":[{"name":"size:L"}]},{"number":105,"labels":[{"name":"size:xl"}]}]'

  _cs_out=""; _cs_rc=0
  _cs_out="$(_rv_select_candidates "$_cs_members" "$_cs_b1" "$_cs_b2")" || _cs_rc=$?
  [[ "$_cs_rc" -eq 0 ]] || die "self-test 7: the candidate-selection pass exited $_cs_rc on well-formed input"
  _cs_want="$(/usr/bin/printf '102 8\n104 1\n105 16\nOK')"
  [[ "$_cs_out" == "$_cs_want" ]] || die "self-test 7: candidate selection returned '$_cs_out'; expected sized-only, deduped across blobs, sorted, sentinel last: '$_cs_want'"

  # (a) the NOT-ALREADY-A-MEMBER filter, with its firing control. Same blobs,
  # empty membership: #101 must NOW appear at 4 pts. Without this arm the
  # exclusion above could pass because #101 was never selectable at all —
  # double-counting a current member into `planned` is the failure it guards.
  _cs_out2=""; _cs_rc=0
  _cs_out2="$(_rv_select_candidates '[]' "$_cs_b1" "$_cs_b2")" || _cs_rc=$?
  [[ "$_cs_rc" -eq 0 ]] || die "self-test 7(a): the pass exited $_cs_rc on the empty-membership control"
  /usr/bin/grep -qx '101 4' <<< "$_cs_out2" || die "self-test 7(a) CONTROL: with an empty membership #101 must be selected at 4 pts — otherwise the member filter is not what excluded it above; got '$_cs_out2'"
  if /usr/bin/grep -qx '101 4' <<< "$_cs_out"; then
    die "self-test 7(a): #101 is already on the milestone and must NOT be re-counted into planned; got '$_cs_out'"
  fi

  # (b) the SIZED filter, both directions. An unsized candidate contributes zero
  # points either way, so it must never cost an events call.
  if /usr/bin/grep -q '^103 ' <<< "$_cs_out2"; then
    die "self-test 7(b): the unsized #103 must be dropped from the candidate set; got '$_cs_out2'"
  fi
  /usr/bin/grep -qx '104 1' <<< "$_cs_out" || die "self-test 7(b) CONTROL: the sized #104 must survive the same filter that dropped #103; got '$_cs_out'"

  # (c) the OK SENTINEL, with a vacuity control. The caller reads a missing
  # sentinel as "the pass crashed" and degrades the recovery; that check is
  # worthless if the sentinel cannot go missing. Malformed input must not
  # produce exit 0 WITH a sentinel.
  /usr/bin/grep -qx 'OK' <<< "$_cs_out" || die "self-test 7(c): the OK sentinel is absent from a successful pass"
  _cs_bad=""; _cs_rc=0
  _cs_bad="$(_rv_select_candidates '[{"number":1}]' 'not json at all')" || _cs_rc=$?
  if [[ "$_cs_rc" -eq 0 ]] && /usr/bin/grep -qx 'OK' <<< "$_cs_bad"; then
    die "self-test 7(c) CONTROL: malformed candidate JSON produced exit 0 WITH the sentinel — the caller's crash check is vacuous"
  fi

  echo "self-test: PASS"
  echo "  point scale (XS/S/M/L/XL) validated; out-of-set rejection validated"
  echo "  ratio round-half-up validated (exact / below-half / at-half / above-half / planned-zero)"
  echo "  work-class mapping + precedence validated"
  echo "  allocation-partitions-delivered invariant validated"
  echo "  delivery predicate (5.5) validated: both directions disagree / spaced-and-cased label match fidelity (5 arms, case included) / exclusion-constant shape / close-state independence WITH the pre-fix predicate as a firing sensitivity arm / non-degenerate planned-vs-delivered / allocation partitions delivered across an exclusion"
  echo "  Phase-A2 candidate selection (7) validated on the real pass, offline: sized filter / not-already-a-member filter / cross-blob dedup / sort order / OK sentinel — each with a firing control, and a vacuity control on the sentinel"
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

# ─── Resolve the milestone ONCE (title + description) ────────────────────────

# The title is the join key the Phase-A2 recovery matches `demilestoned` events
# against; the description carries the Release Class. One call, two consumers —
# the description read used to sit further down as its own call.
MS_JSON="$("$GH" api "repos/$REPO/milestones/$MILESTONE" 2>/dev/null || true)"
MS_TITLE=""
MS_BODY=""
if [[ -n "$MS_JSON" ]]; then
  MS_TITLE="$(/usr/bin/python3 -c 'import json,sys
try: print(json.loads(sys.argv[1]).get("title") or "")
except Exception: print("")' "$MS_JSON" 2>/dev/null || true)"
  MS_BODY="$(/usr/bin/python3 -c 'import json,sys
try: print(json.loads(sys.argv[1]).get("description") or "")
except Exception: print("")' "$MS_JSON" 2>/dev/null || true)"
fi

# ─── Read milestone membership ───────────────────────────────────────────────

# Single batched read of the milestone's issues (number, state, labels). Per the
# gh-background-hang reference: one foreground call, no loop. --limit set high
# (a milestone bundle is small, but guard against silent truncation).
MEMBERS_JSON="$("$GH" issue list --repo "$REPO" \
  --milestone "$MILESTONE" --state all --limit 500 \
  --json number,state,labels 2>/dev/null || true)"

[[ -n "$MEMBERS_JSON" ]] || MEMBERS_JSON="[]"

# A milestone with no CURRENT issues is now two distinguishable conditions, and
# they need different diagnoses. Before the Phase-A2 recovery below existed,
# both collapsed into "does it exist?" — which sent the operator to check a
# milestone number that was perfectly correct on a release where every member
# had simply been deferred out at Phase A2.
if [[ "$MEMBERS_JSON" == "[]" && -z "$MS_TITLE" ]]; then
  die "milestone $MILESTONE resolved to zero issues (does it exist? is the title/number right?)" 2
fi

# ─── Phase-A2 recovery: return the demilestoned members to `planned` ─────────
#
# See the § Phase-A2 recovery note in the header for WHY. Mechanically: build the
# terminal-status candidate population, drop the unsized ones (zero points either
# way) and the ones still on this milestone (already counted), then ask each
# remaining candidate's issue-events whether it was ever demilestoned FROM this
# milestone. Bounded by the terminal-status population, not by repo size.

RECOVERED_PTS=""      # comma-separated point values, one per recovered member
RECOVERED_NUMS=""     # space-separated issue numbers, for the stderr diagnostic
RECOVERY_DEGRADED=""  # non-empty => the recovery could not complete; announced below

# Split the exclusion constant into an array WITHOUT word-splitting: every marker
# contains a space, so the default IFS would shred `status: deferred` into two.
_rv_markers=()
while IFS= read -r _rv_m; do
  if [[ -n "$_rv_m" ]]; then _rv_markers+=("$_rv_m"); fi
done <<< "$(/usr/bin/printf '%s' "$_STATUS_NOT_DELIVERED" | /usr/bin/tr ',' '\n')"

if [[ -z "$MS_TITLE" ]]; then
  RECOVERY_DEGRADED="milestone $MILESTONE did not resolve to a title"
elif [[ "${#_rv_markers[@]}" -eq 0 ]]; then
  RECOVERY_DEGRADED="the terminal-status exclusion set is empty"
else
  # One `gh issue list` per marker: the CLI ANDs multiple --label flags, so a
  # single call cannot express the union. Blobs are collected into an ARRAY and
  # handed to python as separate argv entries — no delimiter to pick, and none
  # to collide with JSON content.
  _rv_blobs=()
  for _rv_m in "${_rv_markers[@]}"; do
    _rv_one="$("$GH" issue list --repo "$REPO" --label "$_rv_m" --state all --limit 500 \
                 --json number,labels,milestone 2>/dev/null || true)"
    if [[ -z "$_rv_one" ]]; then
      RECOVERY_DEGRADED="could not list issues carrying '$_rv_m'"
      break
    fi
    _rv_blobs+=("$_rv_one")
  done
  if [[ -z "$RECOVERY_DEGRADED" && "${#_rv_blobs[@]}" -eq 0 ]]; then
    RECOVERY_DEGRADED="no candidate list was retrieved"
  fi
fi

if [[ -z "$RECOVERY_DEGRADED" ]]; then
  # The selection pass itself is `_rv_select_candidates`, defined above the
  # self-test block so Test 7 can reach it — see the note there. The exit-0-with-
  # empty-stdout failure mode the files-changed degrade below documents is what
  # the OK sentinel exists to distinguish from an honest empty result.
  # The `|| _rv_src=$?` MUST sit outside the command substitution. Inside it, the
  # assignment lands in the subshell and is discarded — the status is lost and
  # the failure reads as success with empty output.
  _rv_short=""; _rv_src=0
  _rv_short="$(_rv_select_candidates "$MEMBERS_JSON" "${_rv_blobs[@]}")" || _rv_src=$?
  if [[ "$_rv_src" -ne 0 ]] || ! /usr/bin/grep -qx 'OK' <<< "$_rv_short"; then
    RECOVERY_DEGRADED="the candidate-selection pass did not complete (exit $_rv_src)"
    _rv_short=""
  fi
  while read -r _rv_num _rv_pts; do
    if [[ "$_rv_num" == "OK" ]]; then continue; fi
    if [[ -n "$_rv_num" ]]; then
      # Issue EVENTS, not the full timeline: same `demilestoned` records with
      # the milestone title, materially smaller payload.
      _rv_hit="$("$GH" api "repos/$REPO/issues/$_rv_num/events" --paginate \
                   --jq '.[] | select(.event=="demilestoned") | .milestone.title' 2>/dev/null || true)"
      if [[ -n "$_rv_hit" ]] && /usr/bin/grep -qxF -- "$MS_TITLE" <<< "$_rv_hit"; then
        RECOVERED_PTS="${RECOVERED_PTS}${RECOVERED_PTS:+,}${_rv_pts}"
        RECOVERED_NUMS="${RECOVERED_NUMS}${RECOVERED_NUMS:+ }#${_rv_num}"
      fi
    fi
  done <<< "$_rv_short"
fi

# Announce a degraded recovery; never silence it. An incomplete recovery
# UNDER-reports planned, which reads as a healthier ratio than the truth — the
# precise direction of error a permanent ledger row must not absorb quietly.
# stderr only, so the stdout field value stays byte-identical for callers.
if [[ -n "$RECOVERY_DEGRADED" ]]; then
  echo "NOTE: Phase-A2 planned-recovery degraded (${RECOVERY_DEGRADED}) — 'planned' counts only the CURRENT milestone membership and may under-report any member deferred out at Phase A2." >&2
elif [[ -n "$RECOVERED_NUMS" ]]; then
  echo "NOTE: Phase-A2 planned-recovery returned ${RECOVERED_NUMS} to 'planned' (demilestoned from '${MS_TITLE}' while carrying a terminal not-delivered status label)." >&2
fi

# ─── Compute planned / delivered points + allocation via python (stdlib json) ─

# Hand the membership JSON + the work-class map to python for a single pass.
# python re-implements the SAME three helpers (point scale, round-half-up,
# work-class precedence) so the heavy JSON walk stays in one place; the bash
# helpers above are the self-tested reference and the contract.
COMPUTED="$(/usr/bin/python3 - "$MEMBERS_JSON" "$_STATUS_NOT_DELIVERED" "$RECOVERED_PTS" <<'PY' || die "membership parse failure (malformed gh JSON or out-of-set size label)" 2
import json, sys, math

members = json.loads(sys.argv[1])

# The SAME exclusion constant the bash reference `labels_to_delivered` reads —
# passed in rather than re-declared, so the two consumers cannot drift.
NOT_DELIVERED = {s.strip().lower() for s in sys.argv[2].split(",") if s.strip()}

# Points for the members Phase A2 removed from this milestone on the way out.
RECOVERED = [int(p) for p in sys.argv[3].split(",") if p.strip()]

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

def delivered_member(labels):
    # Mirror of labels_to_delivered: a member counts as delivered unless it
    # carries a terminal not-delivered status: label. Full-label equality on the
    # lowercased name — never a prefix, never a substring.
    return not ({(n or "").strip().lower() for n in labels} & NOT_DELIVERED)

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
    # The delivery predicate reads LABELS, not `state`. A member whose close
    # keyword did not resolve at Stage 12 is still delivered; a member Phase A2
    # marked terminal is not, whether or not it happens to be closed.
    if delivered_member(labels):
        delivered_pts += pts
        # Allocation accumulates inside the SAME branch as delivered_pts. The
        # three buckets partition delivered points by contract (§ 4), so an
        # excluded member must be excluded from both or the invariant breaks.
        if pts > 0:
            alloc[work_class(labels)] += pts

# Recovered members are planned-not-delivered by construction: Phase A2 marked
# them terminal and removed the milestone. They add to planned only, and they
# count toward sized_members so an all-deferred release still reaches the
# plausibility guard instead of degrading to the unsized N/A path.
for pts in RECOVERED:
    if pts > 0:
        sized_members += 1
    planned_pts += pts

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
#
# MS_BODY was resolved above, in the same call that resolved MS_TITLE.

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

# ─── Plausibility guard (must follow the N/A early-return above) ─────────────
#
# ORDERING IS LOAD-BEARING. This runs AFTER the SIZED_MEMBERS == 0 return, so a
# legitimately unsized content-only release takes the N/A path and never reaches
# the guard. Moving it earlier would fail every governance-only release.
#
# The condition is reachable: a release whose sized members were all deferred at
# Phase A2 recovers them into planned (above) while delivering none of them.
# Before the recovery existed the same release resolved to an EMPTY milestone
# and died upstream with a milestone-does-not-exist diagnosis, which is why this
# guard had no reachable input and would have shipped as unfalsifiable coverage.
if [[ "$PLANNED_PTS" -gt 0 && "$DELIVERED_PTS" -eq 0 ]]; then
  die "implausible **Velocity:** measurement for milestone $MILESTONE — planned ${PLANNED_PTS} pts against delivered 0 pts over ${SIZED_MEMBERS} sized member(s). Every sized member reads terminal-not-delivered. Refusing to write a zero-delivered figure into the permanent RELEASE_LOG record: that exact reading shipped seven times before anything caught it. If the release genuinely delivered nothing, record the field by hand per release-velocity-tracking.md § 7 manual-fill fallback; otherwise the membership or the status labels are wrong." 2
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

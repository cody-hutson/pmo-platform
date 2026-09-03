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

# Operator-instance path resolver — the same one deploy.sh Check 51 uses to reach
# the operator-local (K4) packs, sourced rather than re-derived so the two cannot
# construct different pack source lists (see resolve_declared_kinds below). Five
# other release/tools/*.sh scripts source it exactly this way.
#
# Guarded and NON-FATAL, unlike automated-closeout.sh's exit-2 preflight: this
# tool must still emit a measurement from the corpus packs alone when the
# resolver is unavailable. The absence is ANNOUNCED (resolve_declared_kinds sets
# a degrade reason), never silently absorbed — a silently-dropped K4 leg would
# under-report the feature bucket, which reads as a healthier mix than the truth.
_RV_INSTANCE_LIB="$REPO_ROOT/core/deploy/lib-instance-path.sh"
if [[ -r "$_RV_INSTANCE_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_RV_INSTANCE_LIB" "" || true
fi

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
  # The trailing `head -1` folds into `grep -m1`: grep reads the FILE directly, so no
  # upstream writer is left for an early-closing consumer to signal, and `cut` drains.
  local _last; _last="$(/usr/bin/grep -m1 -n '^set -euo pipefail' "${BASH_SOURCE[0]}" | /usr/bin/cut -d: -f1)"
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

# Resolve a delivered issue's work-class per release-velocity-tracking.md § 4.
#
# THREE TIERS, and the ORDER is the load-bearing part:
#
#   T1  declared category / cluster signal   feature -> slack -> debt
#   T2  declared work-item kind              -> feature   (RESIDUAL, fires only
#                                                          when T1 is silent)
#   T3  stated conservative default          -> debt
#
# WHY T2 IS RESIDUAL AND NOT A FOURTH ARM OF T1. The intuitive change — add the
# kind tokens beside `enhancement` in the feature arm — inverts every bug on any
# deployment that declares a `bug` kind: `bug` + `type:bug` would resolve
# FEATURE, because the feature arm wins precedence. A `type:<kind_id>` whose
# name is co-extensive with a live category row is the SAME assertion at two
# altitudes (core/specs/label-taxonomy.md § Work-Item-Kind Labels, and Rule 1's
# structural exception), so the category altitude must resolve first or the
# projection contradicts its own parent. Precedence does that work directly: no
# runtime read of the category facet is needed, because wherever a kind name
# collides with a category row that row is present on the issue and resolves at
# T1. See ADR-173.
#
# T1's token set is the SELECTED PACKS' declared rows, not folklore. Three
# phantom tokens were retired from this map — named by it, present in no live
# label set and in no pack `[[labels]]` row. They are NOT re-listed here: a dead
# token spelled in a comment is still a grep hit for every consumer looking for
# live arms, and the map's SSOT is the standard, not this script. § 4 of
# release-velocity-tracking.md records which three and why; § 13 FM6 names the
# failure mode; ADR-173 carries the decision. A dead arm reads as coverage while
# covering nothing, so self-test 4(m) asserts every SURVIVING T1 token against
# the corpus pack set — the class cannot silently return.
#
# Input:  $1 = space-separated lowercased label string
#         $2 = space-separated declared `type:<kind_id>` set (may be empty; an
#              empty set degrades this cleanly to T1+T3, which is exactly the
#              pre-#4223 behaviour minus the phantom tokens)
# Echoes: feature|debt|slack
labels_to_work_class() {
  local labels="$1" declared_kinds="${2:-}" _k
  # T1 — declared category / cluster signal. Order unchanged from § 4.
  case " $labels " in
    *" enhancement "*) echo feature; return 0 ;;
    *" protocol "*|*" cluster: process-protocol "*|*" routing-rules "*|*" tracker-schema "*) echo slack; return 0 ;;
    *" bug "*|*" structure "*|*" cluster: architecture "*|*" skill-update "*|*" documentation "*) echo debt; return 0 ;;
  esac
  # T2 — declared work-item kind, as a RESIDUAL feature signal. A `type:<kind_id>`
  # for a kind the selected pack set declares is planned capability work. The set
  # is resolved ONCE by resolve_declared_kinds() below and handed in; this
  # function never parses a pack itself.
  for _k in $declared_kinds; do
    case " $labels " in *" $_k "*) echo feature; return 0 ;; esac
  done
  # T3 — conservative default, reached BY RULE rather than by falling off the end
  # of an enumeration. Authority: release-velocity-tracking.md § 4 ("Default =
  # debt — an un-feature, un-protocol delivered issue is treated as debt-paydown,
  # never silently dropped, so the three buckets always partition the delivered
  # points") and § 13 FM3 (dropping an unmapped issue's points breaks the
  # partition invariant). Defaulting to debt is the conservative direction: it
  # never inflates the feature third.
  echo debt
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

# ─── Declared work-item kinds (T2's input) ───────────────────────────────────
#
# Resolve the `type:<kind_id>` set the SELECTED pack set declares, and echo it
# space-separated. This is `labels_to_work_class`'s T2 input, resolved once.
#
# CONSUMES, NEVER FORKS. The resolution rule lives in ONE place —
# `check-label-parity.py --list-declared-kinds` (#5291) — and this function calls
# it. It deliberately does NOT parse the pack `.toml` itself: a second copy of a
# resolution rule is the drift surface the extend-seam decision exists to
# prevent, and the parity gate and this instrument would then disagree about what
# a "declared kind" is without either being wrong on its own terms. The mode is
# contractually OFFLINE (it returns before the repo-slug derivation and before any
# live read) and exits 0 writing nothing on an empty result — both properties are
# asserted by that tool's own fixture suite, which matters because this script's
# --self-test runs in a CI step declared "offline, stdlib-only".
#
# SOURCE LIST — mirrors deploy.sh Check 51 exactly (corpus glob, then the
# operator-local K4 packs under $(pmo_instance_path)/packs, each guarded the same
# way). Kinds are K4 operator-local by grammar (work-item-type-schema.md
# §1.1.1 — never authored into this corpus), so a corpus-only source list would
# make a deployment's own declared kinds invisible HERE exactly as it did to the
# parity gate before #5291. No new path token and no new config key: an
# unregistered token orphans silently.
#
# It is a FUNCTION defined ABOVE the --self-test gate for the reason recorded at
# _rv_select_candidates: below the gate no arm can reach it, and an unreachable
# pure-computation step ships with zero coverage.
#
# RESULTS ARE GLOBALS, NOT STDOUT, and that is load-bearing rather than stylistic.
# An echoing function has to be called as `$(resolve_declared_kinds)`, which runs
# it in a SUBSHELL — so the degrade reason it sets would be discarded at the
# closing paren and every degrade would announce as an honest empty set. That is
# the same trap the Phase-A2 recovery documents below for `|| _rv_src=$?`, and it
# is the precise failure this tier must not have: a silently-dropped kind tier
# UNDER-reports the feature bucket, which reads as a healthier mix than the truth.
# Setting both outputs as globals keeps them in one process and makes the
# degrade-vs-empty distinction survivable. Self-test 4(d) pins it with a firing
# control.
#
# Input:  $@ = OPTIONAL explicit source paths, which REPLACE the default list
#              (the self-test hands it a fixture pack this way).
# Output: _RV_DECLARED_KINDS = the `type:*` tokens, space-separated; empty on a
#         degrade AND on a legitimately kinds-free pack set.
#         _RV_KIND_DEGRADED  = empty when the resolution completed (including an
#         honest empty result); the reason otherwise.
# Exit:   0 always — an unavailable optional tier degrades the measurement, it
#         never refuses it.
_RV_DECLARED_KINDS=""
_RV_KIND_DEGRADED=""
resolve_declared_kinds() {
  local _rk_srcs=() _rk_pack _rk_instance _rk_out _rk_rc=0 _rk_partial=""
  _RV_DECLARED_KINDS=""
  _RV_KIND_DEGRADED=""
  if [[ $# -gt 0 ]]; then
    _rk_srcs=("$@")
  else
    for _rk_pack in "$REPO_ROOT"/core/packs/*/pack.toml; do
      [[ -f "$_rk_pack" ]] && _rk_srcs+=("$_rk_pack")
    done
    # ...and the OPERATOR-LOCAL (K4) packs, guarded exactly like the corpus loop
    # so a deployment with no instance packs directory is a no-op.
    if declare -F pmo_instance_path >/dev/null 2>&1; then
      _rk_instance="$(pmo_instance_path)/packs"
      if [[ -d "$_rk_instance" ]]; then
        for _rk_pack in "$_rk_instance"/*/pack.toml; do
          [[ -f "$_rk_pack" ]] && _rk_srcs+=("$_rk_pack")
        done
      fi
    else
      _rk_partial="the operator-instance resolver is unavailable, so the K4 pack leg was not searched"
    fi
  fi

  local _rk_script="$REPO_ROOT/core/deploy/tools/check-label-parity.py"
  if [[ ! -f "$_rk_script" ]]; then
    _RV_KIND_DEGRADED="the kind resolver is absent at $_rk_script"
    return 0
  fi
  if [[ "${#_rk_srcs[@]}" -eq 0 ]]; then
    _RV_KIND_DEGRADED="no pack source resolved from the selected pack set"
    return 0
  fi

  local _rk_args=()
  for _rk_pack in "${_rk_srcs[@]}"; do _rk_args+=(--source "$_rk_pack"); done
  # `|| _rk_rc=$?` MUST sit outside the command substitution — inside it the
  # assignment lands in the subshell and the status is lost (the same trap
  # documented at the Phase-A2 recovery below).
  _rk_out="$(/usr/bin/python3 "$_rk_script" "${_rk_args[@]}" --list-declared-kinds 2>/dev/null)" || _rk_rc=$?
  if [[ "$_rk_rc" -ne 0 ]]; then
    _RV_KIND_DEGRADED="the kind resolver exited $_rk_rc"
    return 0
  fi
  # An EMPTY result is a legitimate answer (a pack set declaring no kinds), not a
  # degrade — the exit code carries the distinction, which is why the mode's
  # exit-0-on-empty property is contractual rather than incidental.
  _RV_KIND_DEGRADED="$_rk_partial"
  _RV_DECLARED_KINDS="$(/usr/bin/tr '\n' ' ' <<< "$_rk_out" | /usr/bin/sed 's/ *$//')"
  return 0
}

# ─── AC-9 cross-implementation agreement harness ─────────────────────────────
#
# Grade the python EMITTER (`work_class`, in the production pass below) against
# the bash REFERENCE (`labels_to_work_class`) over a shared fixture set. Self-test
# 4(x) is the only caller; see the rationale block there.
#
# It is a FUNCTION, and not an inline heredoc at the call site, for a mechanical
# reason worth recording: a `<<'PY'` heredoc nested inside a `$( )` command
# substitution is NOT opaque to bash's substitution scanner — the scanner
# tokenizes the body looking for the matching paren, so a python apostrophe
# ("bash=%s" style output, a docstring, a contraction in a comment) makes bash
# parse the python as shell and the whole file fails to load with an
# unattributable error 130 lines later. `_rv_select_candidates` above is the same
# shape for the same reason. A function body is parsed once at definition time,
# outside any substitution, so the heredoc is genuinely quoted.
#
# Input:  $1 = this script's path (the emitter is read from its OWN shipped
#              source, never a transcription)
#         $2 = the space-separated declared-kind set
#         $3 = path to the bash reference verdicts, one `<labels>\t<class>` row
# Exit:   0 agree + control fired · 1 divergence · 2 control did not fire ·
#         3 harness/extraction failure
_rv_work_class_agreement() {
  /usr/bin/python3 - "$@" <<'PYX'
import importlib.util, os, re, sys, tempfile

src_path, declared, ref_path = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(src_path, encoding="utf-8").read()

# Extract the EMITTER source: `def work_class(` up to the next top-level `def `.
# Fail loud if it cannot be located — a silently-empty extraction would make
# every comparison below vacuous.
m = re.search(r"^def work_class\(labels\):\n(?:.*\n)*?(?=^def )", text, re.M)
if not m:
    print("EXTRACT-FAIL: could not locate the emitter definition in the shipped source")
    sys.exit(3)
emitter_src = m.group(0)
if "DECLARED_KINDS" not in emitter_src:
    print("EXTRACT-FAIL: the extracted emitter does not reference DECLARED_KINDS -- wrong function or a stale extraction")
    sys.exit(3)

PREAMBLE = "DECLARED_KINDS = %r\n" % ({k.strip().lower() for k in declared.split() if k.strip()},)
tmpdir = tempfile.mkdtemp(prefix="rv-selftest-emitter-")

def load(tag, source_text):
    # Load the copy as a real module rather than injecting a namespace: the
    # emitter then runs under exactly the import semantics it ships with.
    path = os.path.join(tmpdir, "emitter_%s.py" % tag)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(PREAMBLE + source_text)
    spec = importlib.util.spec_from_file_location("emitter_" + tag, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.work_class

rows = [l.split("\t") for l in open(ref_path, encoding="utf-8").read().splitlines() if l.strip()]
if not rows:
    print("HARNESS-FAIL: the reference verdict file is empty -- there is nothing to compare")
    sys.exit(3)

def diverge(fn):
    out = []
    for lab, ref in rows:
        # `|` back to the LIST of label names the emitter takes in production
        # (m.get("labels") -> [l["name"], ...]). A space-split would shred every
        # canonically-spaced label and grade a fixture production never sees.
        got = fn([p for p in lab.split("|") if p])
        if got != ref:
            out.append((lab, ref, got))
    return out

# SUBJECT -- the shipped emitter must agree with the bash reference everywhere.
diffs = diverge(load("subject", emitter_src))

# MUTATION CONTROL -- corrupt the emitter T3 default and REQUIRE a divergence.
mutated = emitter_src.replace('    return "debt"\n', '    return "slack"\n')
if mutated == emitter_src:
    print("CONTROL-FAIL: the planted mutation did not change the emitter source, so the control cannot fire")
    sys.exit(3)
mdiffs = diverge(load("mutated", mutated))

print("FIXTURES=%d DIVERGENCES=%d MUTATION-DIVERGENCES=%d" % (len(rows), len(diffs), len(mdiffs)))
for lab, ref, got in diffs:
    print("  DIVERGE  [%s]  bash=%s  python=%s" % (lab, ref, got))
if diffs:
    sys.exit(1)
if not mdiffs:
    print("CONTROL-FAIL: the mutated emitter still agreed with the bash reference on every fixture -- this comparison cannot detect a divergence and asserts nothing")
    sys.exit(2)
PYX
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
  # `cluster: tech-debt` keeps its VALUE (debt) but no longer reaches it through a
  # debt arm — the token is phantom (in no live label set, in no pack row) and was
  # removed with the other two. It now resolves at T3. Both halves are pinned: a
  # future reader must not "restore" the arm on the strength of the value.
  R="$(labels_to_work_class "size:m cluster: tech-debt")"; [[ "$R" == "debt" ]] || die "self-test: work-class(cluster: tech-debt) = $R, expected debt (now via the T3 default — the token is phantom and its arm was retired)"
  R="$(labels_to_work_class "size:m cluster: architecture")"; [[ "$R" == "debt" ]] || die "self-test: work-class(cluster: architecture) = $R, expected debt"
  R="$(labels_to_work_class "size:m")"; [[ "$R" == "debt" ]] || die "self-test: work-class(unlabeled) = $R default expected debt"
  # feature wins over a co-present debt/protocol signal (precedence)
  R="$(labels_to_work_class "enhancement bug protocol")"; [[ "$R" == "feature" ]] || die "self-test: work-class precedence (feature wins) = $R"

  # Test 4(k): the T2 KIND TIER (#4223). An `improvement`-labelled story could not
  # register as feature allocation at all before this — `improvement` matches no
  # arm, `type:story` matched no arm, and both fell to the default. The subject
  # arm and its control must DISAGREE, or the arm passes on a fixture that never
  # exercised the tier.
  _wc_kinds="type:card type:epic type:story type:task"
  R="$(labels_to_work_class "size:m improvement type:story status: done" "$_wc_kinds")"; [[ "$R" == "feature" ]] || die "self-test 4(k): a story carrying 'improvement' must resolve to feature via the kind tier, got '$R'"
  R="$(labels_to_work_class "size:m status: done" "$_wc_kinds")"; [[ "$R" == "debt" ]] || die "self-test 4(k) CONTROL: the same call WITHOUT 'improvement'/'type:story' must still default to debt, got '$R' — the kind tier is over-broad"
  # ...and the kind signal stands ALONE: `improvement` is template provenance, not
  # a content class (improvement.yml's required Category dropdown offers 7 options
  # and 'Improvement' is not among them), so it must contribute nothing by itself.
  R="$(labels_to_work_class "size:m type:story" "$_wc_kinds")"; [[ "$R" == "feature" ]] || die "self-test 4(k): 'type:story' must resolve to feature independently of 'improvement', got '$R'"
  R="$(labels_to_work_class "size:m improvement" "$_wc_kinds")"; [[ "$R" == "debt" ]] || die "self-test 4(k): 'improvement' ALONE must resolve nothing — it is template provenance, not a work-class signal — got '$R'"

  # Test 4(t): TIER ORDER — the regression guard for the rejected design.
  # If the kind tier is ever flattened into the T1 feature arm, `bug` + `type:bug`
  # resolves FEATURE on any deployment declaring a `bug` kind, inverting every bug
  # in the ledger. This arm is the one that fails when that happens. (ADR-173.)
  R="$(labels_to_work_class "size:l bug type:bug" "type:bug type:story")"; [[ "$R" == "debt" ]] || die "self-test 4(t) TIER ORDER: 'bug type:bug' must resolve debt via T1 — got '$R'. The kind tier has been flattened into the feature arm and every bug on a kind-declaring deployment now reads as feature."
  R="$(labels_to_work_class "size:m protocol type:task" "$_wc_kinds")"; [[ "$R" == "slack" ]] || die "self-test 4(t) TIER ORDER: 'protocol type:task' must resolve slack via T1 — got '$R'"
  # ...with the SENSITIVITY arm proving the fixture reaches the kind tier at all:
  # drop the T1 token and the same kind label must now resolve feature.
  R="$(labels_to_work_class "size:l type:bug" "type:bug type:story")"; [[ "$R" == "feature" ]] || die "self-test 4(t) SENSITIVITY: with the 'bug' category token removed, 'type:bug' must reach T2 and resolve feature — got '$R', so the tier-order arms above are asserting nothing"

  # Test 4(e): an EMPTY declared-kind set degrades cleanly to T1+T3. This is the
  # E5 degrade path's resolution behaviour, and it must not crash or mis-resolve.
  R="$(labels_to_work_class "size:m type:story" "")"; [[ "$R" == "debt" ]] || die "self-test 4(e): with an empty declared-kind set the resolver must degrade to T1+T3, got '$R'"
  R="$(labels_to_work_class "size:m enhancement" "")"; [[ "$R" == "feature" ]] || die "self-test 4(e): T1 must be unaffected by an empty declared-kind set, got '$R'"

  # Test 4(m): MEMBERSHIP. Every surviving T1 token must exist as a declared
  # `name = "<token>"` row in the corpus pack set. This is the arm that makes the
  # phantom class a pre-merge FAILURE instead of a silent drift — § 13 FM6. It is
  # an existence check on the category axis, not a second kind resolver: it greps
  # the pack files for a literal row, it does not re-derive the resolution rule.
  _wc_t1_tokens=("enhancement" "protocol" "cluster: process-protocol" "routing-rules" "tracker-schema" "bug" "structure" "cluster: architecture" "skill-update" "documentation")
  _wc_packs=("$REPO_ROOT"/core/packs/*/pack.toml)
  [[ -f "${_wc_packs[0]}" ]] || die "self-test 4(m): no corpus pack.toml resolved under $REPO_ROOT/core/packs — the membership arm cannot run, which is a FAIL, not a skip"
  for _wc_tok in "${_wc_t1_tokens[@]}"; do
    /usr/bin/grep -qF -- "name = \"$_wc_tok\"" "${_wc_packs[@]}" \
      || die "self-test 4(m): the T1 token '$_wc_tok' is declared by NO corpus pack [[labels]] row — it is a phantom arm that reads as coverage while covering nothing (release-velocity-tracking.md § 13 FM6)"
  done
  # CONTROL — the arm must be able to fail. A token known NOT to be a declared row
  # (one of the three this card retired) must be rejected by the same predicate.
  if /usr/bin/grep -qF -- 'name = "cluster: tech-debt"' "${_wc_packs[@]}"; then
    die "self-test 4(m) CONTROL: the retired phantom 'cluster: tech-debt' resolved as a declared pack row — the membership predicate cannot distinguish live tokens from dead ones and asserts nothing"
  fi

  # Test 4(p): resolve_declared_kinds() END-TO-END, offline, against the real
  # #5291 helper — this is the seam that makes the map derived rather than
  # hand-maintained, so it is exercised for real rather than simulated.
  #
  # The AC-5 PAIR IS BOTH ARMS, and it must DISCRIMINATE. A subject-only
  # assertion ("the fixture kind resolves") is the degenerate probe shape: it
  # passes identically whether or not the fixture was ever read. So the same
  # label is resolved twice — once with the fixture pack in the source list and
  # once without — and the two must DISAGREE. Neither file is edited between the
  # two runs, which is the actual AC-5 claim.
  resolve_declared_kinds; _rk_corpus="$_RV_DECLARED_KINDS"
  [[ -n "$_rk_corpus" ]] || die "self-test 4(p): resolve_declared_kinds() returned nothing over the corpus pack set — the kind tier has no input and every arm above that uses a literal set is asserting against a fiction"
  for _rk_want in type:card type:epic type:story type:task; do
    case " $_rk_corpus " in *" $_rk_want "*) ;; *) die "self-test 4(p): the corpus-declared kind '$_rk_want' is absent from the resolved set '$_rk_corpus'" ;; esac
  done

  _rk_fx="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rv-selftest-pack-XXXXXX")" \
    || die "self-test 4(p): could not create the fixture-pack directory — the AC-5 control did not run, which is a FAIL, not a skip"
  /usr/bin/printf '[[kinds]]\nkind_id = "initiative"\ndisplay_name = "Initiative"\n' > "$_rk_fx/pack.toml"

  # Subject arm — fixture pack SELECTED. A newly-declared pack kind must resolve
  # with NEITHER this script nor the standard edited.
  resolve_declared_kinds "${_wc_packs[@]}" "$_rk_fx/pack.toml"; _rk_with="$_RV_DECLARED_KINDS"
  # Control arm — same call, fixture pack NOT selected.
  resolve_declared_kinds "${_wc_packs[@]}"; _rk_without="$_RV_DECLARED_KINDS"
  R="$(labels_to_work_class "size:m type:initiative" "$_rk_with")"
  [[ "$R" == "feature" ]] || die "self-test 4(p) AC-5 subject: a kind declared only by the fixture pack must resolve to feature with no edit to this file, got '$R' (resolved set: '$_rk_with')"
  R="$(labels_to_work_class "size:m type:initiative" "$_rk_without")"
  [[ "$R" == "debt" ]] || die "self-test 4(p) AC-5 CONTROL: WITHOUT the fixture pack the same label must NOT resolve to feature — got '$R'. The two arms do not discriminate, so the subject arm passes whether or not the pack was read."
  [[ "$_rk_with" != "$_rk_without" ]] || die "self-test 4(p) AC-5: the with-fixture and without-fixture kind sets are byte-identical ('$_rk_with') — the fixture was not read and the pair is degenerate"

  # ...and a kind present in NO selected pack resolves to feature in neither arm.
  # This is the over-broadness control: the derivation must not accept any
  # `type:*`-shaped token, only a DECLARED one.
  R="$(labels_to_work_class "size:m type:zzfabricatedkind" "$_rk_with")"
  [[ "$R" == "debt" ]] || die "self-test 4(p) CONTROL: a fabricated kind declared by no selected pack resolved to '$R' — the derivation is over-broad and is prefix-matching rather than resolving"
  R="$(labels_to_work_class "size:m zz-fabricated-label" "$_rk_with")"
  [[ "$R" == "debt" ]] || die "self-test 4(p) CONTROL: a fabricated non-kind label resolved to '$R', expected debt"
  /bin/rm -rf "$_rk_fx"

  # Test 4(d): the DEGRADE path is announced, never silent. A source set that
  # declares no kinds is an EMPTY result and NOT a degrade (exit 0, no output);
  # an unreadable source is a degrade. The two must be distinguishable, or an
  # under-reported feature bucket looks identical to an honest one.
  _rk_empty="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rv-selftest-nokinds-XXXXXX")" \
    || die "self-test 4(d): could not create the kinds-free fixture directory — the control did not run, which is a FAIL, not a skip"
  /usr/bin/printf '[[labels]]\nname = "zz-fixture"\n' > "$_rk_empty/pack.toml"
  resolve_declared_kinds "$_rk_empty/pack.toml"
  [[ -z "$_RV_DECLARED_KINDS" ]] || die "self-test 4(d): a kinds-free source must resolve to the EMPTY set, got '$_RV_DECLARED_KINDS'"
  [[ -z "$_RV_KIND_DEGRADED" ]] || die "self-test 4(d): an empty result was reported as a DEGRADE ('$_RV_KIND_DEGRADED') — an honest empty set and an unavailable resolver are then indistinguishable"
  # CONTROL — an unreadable source MUST set the degrade reason, or the check above
  # is satisfied by a resolver that never reports a degrade at all.
  resolve_declared_kinds "$_rk_empty/definitely-absent.toml"
  [[ -n "$_RV_KIND_DEGRADED" ]] || die "self-test 4(d) CONTROL: an unreadable source produced no degrade reason — the emptiness assertion above is vacuous because this resolver can never report a degrade"
  [[ -z "$_RV_DECLARED_KINDS" ]] || die "self-test 4(d) CONTROL: a degraded resolution must resolve to the empty set, got '$_RV_DECLARED_KINDS'"
  /bin/rm -rf "$_rk_empty"
  _RV_KIND_DEGRADED=""

  # Test 4(x): AC-9 — THE TWO IMPLEMENTATIONS AGREE.
  #
  # WHY THIS ARM EXISTS. There are two work-class implementations in this file:
  # `labels_to_work_class` (bash) is the self-tested REFERENCE and has zero call
  # sites outside this self-test block; `work_class` (python, in the production
  # pass below) is the EMITTER whose value reaches the ledger. Every arm above
  # grades the reference. A change that lands only in the reference therefore
  # turns this whole file green while the emitted allocation does not move — the
  # exact failure this card was opened against. This arm closes that: it extracts
  # the emitter's OWN SHIPPED SOURCE from this file, loads it as a module, and
  # requires the two to return the same class for every fixture label-set.
  #
  # It reads the shipped text rather than a copy on purpose. A re-typed fixture of
  # the emitter would agree with the reference forever while the real emitter
  # drifted underneath it — a check that grades a transcription is not a check.
  #
  # The MUTATION CONTROL is required, not decorative: the same comparison is re-run
  # against a deliberately-corrupted copy of the extracted source, and it MUST
  # report a divergence. A cross-implementation check that cannot be shown to fail
  # on a planted divergence is indistinguishable from a constant PASS.
  #
  # The fixture list lives in ONE place — the bash array below — and both sides
  # read it, so the comparison cannot decay into two different populations.
  #
  # Labels are `|`-delimited because the two implementations take DIFFERENT
  # argument shapes and the fixture has to be faithful to both: the bash
  # reference takes one space-separated string (so the pipes are joined with
  # spaces), the python emitter takes a LIST of label names (so the pipes are
  # split). A space-split would shred every canonically-spaced label —
  # `cluster: process-protocol` would reach the emitter as two labels and the
  # comparison would grade a fixture neither implementation ever sees in
  # production.
  _wc_fixtures=(
    "size:m|enhancement|status: done"
    "size:s|protocol|cluster: process-protocol"
    "size:m|cluster: process-protocol"
    "size:l|bug"
    "size:m|cluster: tech-debt"
    "size:m|cluster: architecture"
    "size:m"
    "enhancement|bug|protocol"
    "size:m|improvement|type:story|status: done"
    "size:m|status: done"
    "size:m|type:story"
    "size:m|improvement"
    "size:l|bug|type:bug"
    "size:m|protocol|type:task"
    "size:l|type:bug"
    "size:m|type:zzfabricatedkind"
    "size:m|zz-fabricated-label"
    "size:m|routing-rules|type:epic"
    "size:m|tracker-schema"
    "size:m|structure|type:task"
    "size:m|documentation|type:card"
    "size:m|skill-update|type:story"
    "size:m|type:card|type:epic"
    "size:m|cluster: architecture|type:story"
    "size:m|documentation|improvement|type:task"
    # The two REAL label shapes from v3.100 (milestone decision-telemetry-emission),
    # verbatim — the release whose 0/20/0 reading opened this card. Carried here so
    # the AC-8 re-derivation is graded against the shipped implementations rather
    # than a transcription of them.
    "bug|project:pipeline|size:S|status: approved|type:bug"
    "cluster: pipeline-definitions|improvement|project:pipeline|size:M|status: approved|type:story"
  )
  # The reference verdicts come from the bash implementation itself, so the
  # comparison is genuinely cross-implementation and not python-against-python.
  _wc_ref_lines=""
  for _wc_fx in "${_wc_fixtures[@]}"; do
    _wc_ref_lines+="${_wc_fx}"$'\t'"$(labels_to_work_class "${_wc_fx//|/ }" "$_rk_corpus")"$'\n'
  done

  _wc_ref_file="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/rv-selftest-ref-XXXXXX")" \
    || die "self-test 4(x): could not stage the reference verdicts — the AC-9 comparison did not run, which is a FAIL, not a skip"
  /usr/bin/printf '%s' "$_wc_ref_lines" > "$_wc_ref_file"

  _wc_agree_out=""; _wc_agree_rc=0
  _wc_agree_out="$(_rv_work_class_agreement "${BASH_SOURCE[0]}" "$_rk_corpus" "$_wc_ref_file" 2>&1)" || _wc_agree_rc=$?
  /bin/rm -f "$_wc_ref_file"
  [[ "$_wc_agree_rc" -eq 0 ]] || die "self-test 4(x) AC-9: the bash reference and the python emitter do not agree (exit $_wc_agree_rc)
$_wc_agree_out"
  case "$_wc_agree_out" in
    *"MUTATION-DIVERGENCES=0"*) die "self-test 4(x) AC-9 CONTROL: the planted divergence was not detected — $_wc_agree_out" ;;
  esac
  echo "  AC-9 cross-implementation agreement: $_wc_agree_out"

  # Test 4(v): THE DEFECT ITSELF, as a permanent regression arm.
  #
  # v3.100 (milestone `decision-telemetry-emission`) recorded `allocation 0/20/0`
  # on a membership of three bugs and three stories. The bucket was defensible;
  # the ROUTE was not — the three stories carry `improvement` + `type:story`, and
  # neither could register as feature allocation regardless of content. This arm
  # replays that membership offline and pins BOTH readings: the retired map must
  # still reproduce the ledger row (the fidelity control — without it a green run
  # cannot distinguish "the fix works" from "the fixture never had the defect"),
  # and the shipped map must move it.
  #
  # The membership is a frozen snapshot of a CLOSED release, so it is a durable
  # fixture rather than a live value that rots.
  _v3100_feat=0; _v3100_debt=0; _v3100_slack=0; _v3100_old_debt=0; _v3100_total=0
  for _v3100_spec in \
    "bug project:pipeline size:s status: approved type:bug|2" \
    "cluster: pipeline-definitions improvement project:pipeline size:m status: approved type:story|4" \
    "cluster: pipeline-definitions improvement project:pipeline size:m status: approved type:story|4" \
    "improvement project:pipeline size:m status: approved type:story|4" \
    "bug project:pipeline size:s status: approved type:bug|2" \
    "bug project:pipeline size:m status: approved type:bug|4" ; do
    _v3100_labels="${_v3100_spec%%|*}"; _v3100_pts="${_v3100_spec##*|}"
    _v3100_total=$((_v3100_total + _v3100_pts))
    # The RETIRED map, inlined as the fidelity control: `enhancement` was its only
    # live feature token and none of these six members carries it.
    case " $_v3100_labels " in
      *" enhancement "*) ;;
      *) _v3100_old_debt=$((_v3100_old_debt + _v3100_pts)) ;;
    esac
    case "$(labels_to_work_class "$_v3100_labels" "$_rk_corpus")" in
      feature) _v3100_feat=$((_v3100_feat + _v3100_pts)) ;;
      slack)   _v3100_slack=$((_v3100_slack + _v3100_pts)) ;;
      debt)    _v3100_debt=$((_v3100_debt + _v3100_pts)) ;;
    esac
  done
  [[ "$_v3100_old_debt" -eq 20 && "$_v3100_total" -eq 20 ]] \
    || die "self-test 4(v) FIDELITY CONTROL: the retired map must reproduce the v3.100 ledger row 0/20/0 on this fixture — it read 0/$_v3100_old_debt/0 over $_v3100_total pts, so the fixture does not carry the defect and this arm asserts nothing"
  [[ "$_v3100_feat" -eq 12 && "$_v3100_debt" -eq 8 && "$_v3100_slack" -eq 0 ]] \
    || die "self-test 4(v): the v3.100 membership must re-derive to 12/8/0 under the shipped map (the three improvement-carrying stories register as feature allocation); got $_v3100_feat/$_v3100_debt/$_v3100_slack"
  [[ $((_v3100_feat + _v3100_debt + _v3100_slack)) -eq "$_v3100_total" ]] \
    || die "self-test 4(v): the three buckets no longer partition delivered on the v3.100 fixture ($_v3100_feat/$_v3100_debt/$_v3100_slack vs $_v3100_total)"
  echo "  AC-8 v3.100 re-derivation: retired map 0/20/0 (matches the ledger) -> shipped map $_v3100_feat/$_v3100_debt/$_v3100_slack, both partitioning $_v3100_total"

  # Test 5: allocation sums to delivered (invariant — three buckets partition delivered points)
  #   delivered = {enhancement size:m=4, bug size:s=2, protocol size:l=8} -> feat 4 / debt 2 / slack 8 ; sum 14
  feat=0; debt=0; slack=0
  for spec in "enhancement 4" "bug 2" "protocol 8"; do
    set -- $spec
    wc="$(labels_to_work_class "$1" "$_rk_corpus")"
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
      case "$(labels_to_work_class "$_vd_labels" "$_rk_corpus")" in
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
  echo "  work-class 3-tier resolution (4k/4t/4e/4m/4p/4x/4v) validated offline: kind tier with its over-broadness control / tier-order regression guard with a firing sensitivity arm / empty-kind-set degrade / T1-token membership against the pack set with a firing control / AC-5 fixture-pack pair, BOTH arms, discriminating / degrade-vs-empty distinguishable with a firing control / bash-reference-vs-python-emitter agreement graded on the emitter's own shipped source with a planted-divergence mutation control / the v3.100 defect replayed with the retired map as a firing fidelity control"
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
#
# The DECLARED-KIND SET crosses on argv[4], resolved ONCE in bash by
# resolve_declared_kinds() — exactly as _STATUS_NOT_DELIVERED crosses on argv[2],
# and for the same reason. The tier ORDER is re-implemented on both sides (that
# is what makes the bash half a testable reference), but the kind SET is not:
# python never reads a pack, so the two cannot drift on the kind axis at all, and
# self-test 4(x) asserts they cannot drift on the order axis either by grading
# this function's own shipped source against the bash reference.
resolve_declared_kinds
if [[ -n "$_RV_KIND_DEGRADED" ]]; then
  echo "NOTE: work-class kind tier degraded (${_RV_KIND_DEGRADED}) — allocation resolves from declared category/cluster signals only and may UNDER-report the feature bucket; the delivered total and the partition invariant are unaffected." >&2
fi

COMPUTED="$(/usr/bin/python3 - "$MEMBERS_JSON" "$_STATUS_NOT_DELIVERED" "$RECOVERED_PTS" "$_RV_DECLARED_KINDS" <<'PY' || die "membership parse failure (malformed gh JSON or out-of-set size label)" 2
import json, sys, math

members = json.loads(sys.argv[1])

# The SAME exclusion constant the bash reference `labels_to_delivered` reads —
# passed in rather than re-declared, so the two consumers cannot drift.
NOT_DELIVERED = {s.strip().lower() for s in sys.argv[2].split(",") if s.strip()}

# Points for the members Phase A2 removed from this milestone on the way out.
RECOVERED = [int(p) for p in sys.argv[3].split(",") if p.strip()]

# The declared `type:<kind_id>` set, resolved ONCE in bash by
# resolve_declared_kinds() and passed in rather than re-derived here. Empty is a
# legitimate value: the resolution degrades to T1 + T3, which bash announces.
DECLARED_KINDS = {k.strip().lower() for k in (sys.argv[4] if len(sys.argv) > 4 else "").split() if k.strip()}

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
    # THE EMITTER. Mirror of the bash reference `labels_to_work_class`, tier for
    # tier — T1 declared category/cluster, T2 declared work-item kind as a
    # RESIDUAL feature signal, T3 stated default. The order is load-bearing: a
    # kind label whose name is co-extensive with a category row is one assertion
    # at two altitudes, so the category altitude resolves first (ADR-173).
    # Self-test 4(x) extracts THIS function from the shipped source and grades it
    # against the bash reference over every fixture label-set, with a mutation
    # control. NOTE for anyone editing this block: it is a quoted heredoc nested
    # inside a command substitution, and bash still tokenizes the body looking for
    # the matching paren -- so an APOSTROPHE here makes the whole file fail to
    # parse, with the error reported hundreds of lines away. Write around it.
    s = set(n.lower() for n in labels)
    # T1 — declared category / cluster signal.
    if s & {"enhancement"}:
        return "feature"
    if s & {"protocol", "cluster: process-protocol", "routing-rules", "tracker-schema"}:
        return "slack"
    if s & {"bug", "structure", "cluster: architecture", "skill-update", "documentation"}:
        return "debt"
    # T2 — declared work-item kind, residual. The set is resolved in bash and
    # passed on argv[4]; this side never parses a pack.
    if s & DECLARED_KINDS:
        return "feature"
    # T3 — stated conservative default (release-velocity-tracking.md § 4 + FM3).
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

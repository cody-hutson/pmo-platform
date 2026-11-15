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
#   ./compute-release-velocity.sh <version> --milestone <N> --cost-row --out-dir <dir>
#        [--hub-session <stem>]... [--store <usage.jsonl>] [--source-root <dir>]
#        [--since <ISO-8601>] [--force]
#                                               # the per-release cost row (below)
#   ./compute-release-velocity.sh <version> --milestone <N> --quality-share [--json]
#                                               # the quality-share reading (below)
#   ./compute-release-velocity.sh <version> --quality-share --window-json <file> [--json]
#                                               # the same reading over a fixture window
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
# THE PER-RELEASE COST ROW (--cost-row) — a separate mode, not a fourth signal. It
# writes ONE JSON row per release, <out-dir>/release-cost/<slug>.json (rewritten
# atomically; a re-run replaces only that slug's row), holding per-response token
# totals by stage x role x token type, the release's planned and delivered points
# from the delivery predicate above, and weekly points at both ends of the cost
# unit's bracket. Stdout is exactly two lines: one derived-only summary line and the
# row path. The row is local operator data: the home must be outside any repository
# or ignored in the one that contains it (exit 2 otherwise). Its schema, method and
# coverage semantics are normative in release-velocity-tracking.md § Per-release
# cost row. In outline:
#   discover  the release's session trees — a main session is a hub when a spawn it
#             made (Agent, Task or spawn_task) carries "Milestone <slug>" in its
#             prompt or description; its nested files belong to it by path; a chip
#             joins by an exact, whitespace-normalized prompt match. The walk skips
#             symlinked project directories and duplicate inodes, and reads no main
#             file older than the milestone (or --since).
#   count     through the FinOps usage extractor over a FRESH scratch store built on
#             a hard-link view of exactly those files (one directory per file, so
#             each record keys on its file path), never the operator's live store;
#             --store injects a store instead (refused below schema 2.0.0).
#   classify  each session into a stage x role cell, from content — a stage from the
#             brief, the spawn description, or a chip's stage; the reviewer role
#             from the review persona header. Hub cells carry no stage.
#   convert   through the cost unit's ONE conversion (convert-usage.sh); this tool
#             holds no weight, bracket end or K.
#   --out-dir <dir>       the row home (required).
#   --hub-session <stem>  add a tree the predicate cannot see (repeatable).
#   --store <file>        an injected usage store, instead of a fresh scratch one.
#   --source-root <dir>   the transcript root; default $FINOPS_SOURCE_ROOT, else
#                         ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects.
#   --since <ISO-8601>    the discovery window's start; default the milestone's
#                         created_at.
#   --force               replace a stored row whose discovered files the new run
#                         does not all find (refused otherwise: a shrinking row).
# Cost-row exit codes: 0 written (its coverage says fetched or degraded) · 1 invalid
#   args or a missing dependency (gh, jq, python3) · 2 refused — a store below the
#   minimum schema, a home inside a repository and not ignored there, zero trees
#   discovered, or a shrinking re-run · 3 the extractor or the write failed; no row
#   written · 4 written with the unit UNRESOLVED (the conversion could not resolve a
#   value): raw totals kept, no weekly points, the row degraded.
#
# THE QUALITY-SHARE READING (--quality-share) — a separate mode, not a sixth sub-signal.
# It reads the standing quality initiative's share of the items a window of closed
# releases shipped and judges it against the band in the platform-config template's
# [quality_share_band] section, the single home of the band's values and its counting
# rule; this tool states none of them. The method, the record form and the exit codes
# are normative in release-velocity-tracking.md section 7b. In outline:
#   window    the closing release (--milestone) and the releases merged before it that
#             carry a row in release/releases/RELEASE_LOG.md, ordered by first-parent
#             ancestry from the closing merge; a release merge on that history with no
#             row makes the reading NOT-EVALUATED, never a shifted window
#   per item  examined unless it carries the scaffolding label; shipped by the SAME
#             delivery predicate as the field (_STATUS_NOT_DELIVERED); counted when it
#             carries the counted label; unlabelled and bug-typed-elsewhere reported
#             beside the share, with unlabelled kept in the denominator
#   judge     the aggregate judged_on names, in exact fractions; an edge is inside the
#             band; the other aggregate is printed beside it and judged on nothing
#   record    a "#### Quality-share record" block, which Stage 13 Phase A14.2 writes
#             into the release plan's Verification Evidence
# WHY HERE: the share must use this tool's label-based delivery predicate, because at
# Stage 13 the milestone's members are not reliably closed yet, and the mode split
# leaves the **Velocity:** field path byte-identical. WHY THE LOG, NOT THE INDEX: index
# rows land at each release's Stage 13, after later releases may already have merged; log
# rows carry the merge SHA, so merge ancestry orders the window by construction.
# Quality-share exit codes: 0 a reading, inside the band or not · 1 invalid arguments ·
#   3 NOT-EVALUATED — the record is still printed and names the reason.
#
# Cutover of the **Velocity:** field: it applies to releases entering Stage 13
# strictly AFTER the field's introducing-release merge SHA, and the field's
# introducing release itself is exempt. This script does not gate by version — the
# caller (Stage 13 spoke) honors cutover. The cost row (--cost-row) has a cutover of
# its own and is NOT exempt in its introducing release: release-velocity-tracking.md
# § 7a.5.
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
# Guarded and NON-FATAL, unlike automated-closeout.sh's exit-2 entry-gate: this
# tool must still emit a measurement from the corpus packs alone when the
# resolver is unavailable. The absence is ANNOUNCED (resolve_declared_kinds sets
# a degrade reason), never silently absorbed — a silently-dropped K4 leg would
# under-report the feature bucket, which reads as a healthier mix than the truth.
_RV_INSTANCE_LIB="$REPO_ROOT/core/deploy/lib-instance-path.sh"
if [[ -r "$_RV_INSTANCE_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_RV_INSTANCE_LIB" "" || true
fi

# The platform-config rung reader the quality-share reading (--quality-share) resolves
# its band through: the section-aware reader of release/tools/lib/platform-toggle.sh,
# sourced rather than re-derived. That file defines functions and never exits. Guarded
# like the resolver above and non-fatal: without it the quality-share reading is
# NOT-EVALUATED, naming the library, and no other mode is touched.
_RV_TOGGLE_LIB="$SCRIPT_DIR/lib/platform-toggle.sh"
if [[ -r "$_RV_TOGGLE_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_RV_TOGGLE_LIB"
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

# Resolve jq off the pinned PATH, as find_gh does for gh. The cost row's two
# subprocesses (the extractor and the conversion) need it on THEIR PATH, so its
# directory is handed to them explicitly. Empty when not installed.
find_jq() {
  local c
  for c in /usr/bin/jq /opt/homebrew/bin/jq /usr/local/bin/jq "$HOME/.local/bin/jq"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  return 0
}

# The lowest usage-store schema the cost row accepts. Bound to the counting change,
# not to a digit: 2.0.0 is the major that counts once per API response within one
# transcript file (the store schema's § Counting unit). A store below it counted per
# transcript line and is refused (exit 2), injected or fresh.
COST_ROW_MIN_STORE_SCHEMA="2.0.0"

# ─── The per-release cost row engine (--cost-row) ────────────────────────────
#
# One python program, run with /usr/bin/python3 -c. The bash side resolves the
# milestone, its points (the delivery predicate below) and the paths; this engine
# discovers the release's session trees, counts them through the usage extractor
# over a scratch store, classifies each session into a stage x role cell, converts
# through the one cost-unit conversion and writes the row. Its contract — the row
# schema, the method and the coverage semantics — is normative in
# release/references/standards/release-velocity-tracking.md § Per-release cost row.
# `--self-test` runs the cost-row arms offline over inline fixtures (no gh, no
# operator transcript, store, home or configuration).
read -r -d '' _RV_COST_ROW_PY <<'PYEOF' || true
import argparse, hashlib, io, json, os, re, shutil, stat, subprocess, sys, tempfile
from datetime import datetime, timezone

ROW_RECORD = "release-cost-row"
ROW_SCHEMA = "1.0.0"
SPAWN_TOOLS = ("Agent", "Task", "mcp__ccd_session__spawn_task")
CHIP_TOOL = "mcp__ccd_session__spawn_task"
ROLE_ORDER = ("hub", "chip", "spoke", "reviewer", "workflow-agent", "subagent-other")
STAGE_EXEC_RE = re.compile(r"executing Stage[\s-]*(\d{1,2})\b")
STAGE_ANY_RE = re.compile(r"\bStage[\s-]*(\d{1,2})\b")
REVIEW_RE = re.compile(r"adversarial design review", re.I)
PHASE_A65 = "Phase A6.5"
COUNTING_SCOPE = "once per API response within one transcript file"
BOUNDARY = ("spend written after measured_utc (the rest of the close-out, the running hub) "
            "is outside the row, so a row measured at a release's own Stage 13 is a lower bound")
LEAVES = ("input", "output", "cache_read")
CC = ("total", "ephemeral_1h", "ephemeral_5m")
SLUG_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*")


class Refused(Exception):
    pass


class Failed(Exception):
    pass


class UsageError(Exception):
    pass


def norm(s):
    return " ".join(str(s).split())


def semver(v):
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)", str(v or ""))
    return tuple(int(x) for x in m.groups()) if m else None


def iso_epoch(s):
    s = str(s).strip()
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    dt = datetime.fromisoformat(s)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.timestamp()


def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def digest(rel):
    return hashlib.sha256(rel.encode("utf-8")).hexdigest()[:16]


def first_line(s):
    for line in str(s or "").splitlines():
        if line.strip():
            return line.strip()[:240]
    return ""


def parse_lines(data):
    for raw in data.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except ValueError:
            continue
        if isinstance(obj, dict):
            yield obj


def msg(r):
    m = r.get("message")
    return m if isinstance(m, dict) else {}


def msg_text(r):
    c = msg(r).get("content")
    if isinstance(c, str):
        return c
    if isinstance(c, list):
        return "\n".join(b.get("text") for b in c
                         if isinstance(b, dict) and b.get("type") == "text" and isinstance(b.get("text"), str))
    return ""


def first_user(recs):
    for r in recs:
        if r.get("type") == "user" and not r.get("isMeta"):
            t = msg_text(r)
            if t.strip():
                return t
    return ""


def first_user_stream(fp):
    try:
        with open(fp, "rb") as fh:
            for raw in fh:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    r = json.loads(raw)
                except ValueError:
                    continue
                if isinstance(r, dict) and r.get("type") == "user" and not r.get("isMeta"):
                    t = msg_text(r)
                    if t.strip():
                        return t
    except OSError:
        return ""
    return ""


def spawn_calls(recs):
    out = []
    for r in recs:
        if r.get("type") != "assistant":
            continue
        c = msg(r).get("content")
        if not isinstance(c, list):
            continue
        for b in c:
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("name") in SPAWN_TOOLS:
                inp = b.get("input") if isinstance(b.get("input"), dict) else {}
                out.append((b.get("id"), b.get("name"), inp))
    return out


def spawn_agent_ids(recs):
    # tool_use id -> the spawned agent's id, read from the tool result. The agent's
    # transcript is <root>/subagents/agent-<id>.jsonl. A harness per-spawn token
    # total in the same result is NEVER read: it is final context, not consumption.
    out = {}
    for r in recs:
        if r.get("type") != "user":
            continue
        tur = r.get("toolUseResult")
        if not isinstance(tur, dict) or not tur.get("agentId"):
            continue
        c = msg(r).get("content")
        if not isinstance(c, list):
            continue
        for b in c:
            if isinstance(b, dict) and b.get("type") == "tool_result" and b.get("tool_use_id"):
                out[b["tool_use_id"]] = str(tur["agentId"])
    return out


def msg_ids(recs):
    out = set()
    for r in recs:
        if r.get("type") == "assistant":
            i = msg(r).get("id")
            if isinstance(i, str) and i:
                out.add(i)
    return out


def stage_of(first, spawn_desc, inherited):
    m = STAGE_EXEC_RE.search(first or "")
    if m and 1 <= int(m.group(1)) <= 13:
        return int(m.group(1)), "executing-stage"
    m = STAGE_ANY_RE.search(spawn_desc or "")
    if m and 1 <= int(m.group(1)) <= 13:
        return int(m.group(1)), "spawn-description"
    m = STAGE_ANY_RE.search((first or "")[:2000])
    if m and 1 <= int(m.group(1)) <= 13:
        return int(m.group(1)), "first-message"
    if inherited is not None:
        return inherited, "chip-root"
    return None, "none"


def reviewer_signal(first, spawn):
    # The role is read from CONTENT: the review persona header in the linked spawn's
    # description or at the top of the first user message. The agent type is only a
    # secondary signal — reviews are spawned as general-purpose agents with a persona.
    desc = str(spawn.get("description") or "")
    head = (first or "")[:2000]
    if REVIEW_RE.search(desc) or REVIEW_RE.search(head) or PHASE_A65 in desc or PHASE_A65 in (first or "")[:300]:
        return "reviewer-marker"
    if "adversarial" in str(spawn.get("subagent_type") or "").lower():
        return "reviewer-subagent-type"
    return None


def zero_tokens():
    return {"input": 0, "output": 0, "cache_creation": {"total": 0, "ephemeral_1h": 0, "ephemeral_5m": 0},
            "cache_read": 0}


def tokens_ok(t):
    if not isinstance(t, dict) or not isinstance(t.get("cache_creation"), dict):
        return False
    vals = [t.get(k) for k in LEAVES] + [t["cache_creation"].get(k) for k in CC]
    return all(isinstance(v, int) and not isinstance(v, bool) and v >= 0 for v in vals)


def tokens_add(a, t):
    for k in LEAVES:
        a[k] += t[k]
    for k in CC:
        a["cache_creation"][k] += t["cache_creation"][k]


def raw_sum(t):
    return t["input"] + t["output"] + t["cache_creation"]["total"] + t["cache_read"]


def add_count(cell, key, rec):
    v = rec.get(key)
    if cell[key] is None:
        return
    if isinstance(v, int) and not isinstance(v, bool):
        cell[key] += v
    else:
        cell[key] = None  # absent = not evaluated, never 0


def new_cell(stage, role):
    return {"stage": stage, "role": role, "sessions": 0, "responses": 0, "incomplete_responses": 0,
            "unevaluated_responses": 0, "lower_bound": False, "tokens": zero_tokens(), "by_model": {}}


def fold(cell, rec):
    cell["sessions"] += 1
    t = rec.get("turns")
    cell["responses"] += t if isinstance(t, int) and not isinstance(t, bool) else 0
    add_count(cell, "incomplete_responses", rec)
    add_count(cell, "unevaluated_responses", rec)
    tokens_add(cell["tokens"], rec["tokens"])
    bm = rec.get("by_model")
    split = []
    if isinstance(bm, dict) and bm:
        for m_id, v in bm.items():
            tv = v.get("tokens") if isinstance(v, dict) and "tokens" in v else v
            if not tokens_ok(tv):
                split = None
                break
            split.append((str(m_id), tv))
    else:
        split = None
    if split is None:
        split = [("unknown", rec["tokens"])]
    for m_id, tv in split:
        tokens_add(cell["by_model"].setdefault(m_id, zero_tokens()), tv)


def finish(cell):
    inc, unev = cell["incomplete_responses"], cell["unevaluated_responses"]
    if (inc or 0) > 0 or (unev or 0) > 0:
        cell["lower_bound"] = True
    elif inc is None or unev is None:
        cell["lower_bound"] = None
    else:
        cell["lower_bound"] = False


def read_store(path):
    meta, sess = None, []
    with open(path, "rb") as fh:
        for r in parse_lines(fh.read()):
            if r.get("record") == "meta" and meta is None:
                meta = r
            elif r.get("record") == "session":
                sess.append(r)
    return meta, sess


def run_extractor(extractor, store_dir, src, jq_dir):
    env = dict(os.environ)
    env.pop("FINOPS_STORE_PATH", None)
    env["STORE"] = store_dir
    env["FINOPS_SOURCE_ROOT"] = src
    env["PATH"] = (jq_dir + ":" if jq_dir else "") + "/usr/bin:/bin"
    p = subprocess.run(["/bin/bash", extractor, "--rebuild"], env=env, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, universal_newlines=True)
    return p.returncode, p.stderr


def convert(converter, objs, jq_dir, extra_env):
    env = dict(os.environ)
    env["PATH"] = (jq_dir + ":" if jq_dir else "") + "/usr/bin:/bin"
    env.update(extra_env)
    p = subprocess.run(["/bin/bash", converter, "--convert"], input=json.dumps(objs), env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    if p.returncode != 0:
        return None, "convert-usage exit %d: %s" % (p.returncode, first_line(p.stderr))
    try:
        out = json.loads(p.stdout)
    except ValueError:
        return None, "convert-usage wrote output that does not parse"
    if not isinstance(out, dict) or len(out.get("pairs") or []) != len(objs):
        return None, "convert-usage returned a pair count that does not match its input"
    return out, None


def home_guard(out_dir, target):
    # Keyed on the home's CONTAINING repository (the extractor's store-guard shape), with
    # real paths on both sides so a symlinked prefix cannot read as "outside the repo".
    probe = os.path.realpath(out_dir)
    while not os.path.isdir(probe) and os.path.dirname(probe) != probe:
        probe = os.path.dirname(probe)
    if not os.path.isdir(probe):
        return
    p = subprocess.run(["git", "-C", probe, "rev-parse", "--show-toplevel"], stdout=subprocess.PIPE,
                       stderr=subprocess.DEVNULL, universal_newlines=True)
    top = os.path.realpath(p.stdout.strip()) if p.returncode == 0 and p.stdout.strip() else ""
    if not top:
        return  # outside any repository: not committable
    q = subprocess.run(["git", "-C", top, "check-ignore", "-q", "--", os.path.realpath(target)],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if q.returncode != 0:
        raise Refused("the row home is inside a git repository and the row path is NOT ignored there "
                      "(a row is local operator data; add an ignore rule, or pass an ignored --out-dir)")


def discover(a):
    """The release's session trees: hubs by the spawn predicate, their nested files by path,
    chips by exact prompt join, all under a symlink-safe, inode-deduplicated walk."""
    rx = re.compile(r"Milestone " + re.escape(a.slug) + r"(?![a-z0-9-])")
    pb = ("Milestone " + a.slug).encode("utf-8")
    since = iso_epoch(a.since)
    explicit = set(a.hub_session or [])
    seen, aliases, main = set(), 0, []
    try:
        names = sorted(os.listdir(a.source_root))
    except OSError as e:
        raise Failed("the transcript root is unreadable: %s" % e)
    for name in names:
        pdir = os.path.join(a.source_root, name)
        if os.path.islink(pdir):
            aliases += 1  # a symlinked project directory aliases files reached elsewhere
            continue
        if not os.path.isdir(pdir):
            continue
        try:
            fns = sorted(os.listdir(pdir))
        except OSError:
            continue
        for fn in fns:
            if not fn.endswith(".jsonl"):
                continue
            fp = os.path.join(pdir, fn)
            try:
                st = os.lstat(fp)
            except OSError:
                continue
            if not stat.S_ISREG(st.st_mode):
                continue
            key = (st.st_dev, st.st_ino)
            if key in seen:
                aliases += 1
                continue
            seen.add(key)
            main.append((fp, fn[:-6], st.st_mtime))
    hubs, parsed, matched_explicit, scanned = {}, {}, set(), 0
    for fp, stem, mt in main:
        is_explicit = stem in explicit
        if not is_explicit and mt < since:
            continue
        scanned += 1
        try:
            with open(fp, "rb") as fh:
                data = fh.read()
        except OSError:
            continue
        if pb not in data and not is_explicit:
            continue
        recs = list(parse_lines(data))
        parsed[fp] = recs
        if is_explicit:
            hubs[fp] = "explicit"
            matched_explicit.add(stem)
        elif any(rx.search(" ".join(str(inp.get(k, "")) for k in ("prompt", "description")))
                 for _i, _n, inp in spawn_calls(recs)):
            hubs[fp] = "predicate"
    if not hubs:
        raise Refused("zero trees: no session spawned work for 'Milestone %s' since %s, and no --hub-session "
                      "named one" % (a.slug, a.since))
    prompts, n_calls = {}, 0
    for fp in hubs:
        for _i, name, inp in spawn_calls(parsed[fp]):
            if name == CHIP_TOOL:
                n_calls += 1
                p = norm(inp.get("prompt", ""))
                if p:
                    prompts.setdefault(p, []).append(inp)
    chips, joined_prompts = {}, set()
    for fp, stem, mt in main:
        if fp in hubs or mt < since:
            continue
        first = first_user(parsed[fp]) if fp in parsed else (first_user_stream(fp) if prompts else "")
        nf = norm(first)
        if nf and nf in prompts:
            chips[fp] = ("joined", prompts[nf][0])
            joined_prompts.add(nf)
        elif fp in parsed and rx.search(first):
            chips[fp] = ("orphan", {})
    joined_calls = sum(len(v) for k, v in prompts.items() if k in joined_prompts)
    tree, tree_seen = [], set()

    def add(fp, kind, root, via=None, spawn=None, sub_rel=""):
        st = os.lstat(fp)
        k = (st.st_dev, st.st_ino)
        if k in tree_seen:
            return
        tree_seen.add(k)
        recs = parsed.get(fp)
        if recs is None:
            with open(fp, "rb") as fh:
                recs = list(parse_lines(fh.read()))
        tree.append({"fp": fp, "rel": os.path.relpath(fp, a.source_root), "kind": kind, "root": root,
                     "via": via, "spawn": spawn or {}, "sub_rel": sub_rel, "recs": recs,
                     "stem": os.path.basename(fp)[:-6]})

    def add_nested(root_fp):
        sub = os.path.join(root_fp[:-6], "subagents")
        if os.path.islink(sub) or not os.path.isdir(sub):
            return
        for dp, dns, fns in os.walk(sub, followlinks=False):
            dns[:] = sorted(d for d in dns if not os.path.islink(os.path.join(dp, d)))
            for fn in sorted(fns):
                fp = os.path.join(dp, fn)
                if fn.endswith(".jsonl") and stat.S_ISREG(os.lstat(fp).st_mode):
                    add(fp, "nested", root_fp, sub_rel=os.path.relpath(fp, sub))

    for fp in sorted(hubs):
        add(fp, "hub", fp, via=hubs[fp])
        add_nested(fp)
    for fp in sorted(chips):
        add(fp, "chip", fp, via=chips[fp][0], spawn=chips[fp][1])
        add_nested(fp)
    return {"tree": tree, "aliases": aliases, "scanned": scanned,
            "explicit_unmatched": len(explicit - matched_explicit),
            "chips": {"spawn_task_calls": n_calls, "joined": joined_calls, "unjoined": n_calls - joined_calls,
                      "orphan": sum(1 for v in chips.values() if v[0] == "orphan")}}


def classify(tree):
    links = {}
    for t in tree:
        agent_ids = spawn_agent_ids(t["recs"])
        for tu, name, inp in spawn_calls(t["recs"]):
            if name != CHIP_TOOL and tu in agent_ids:
                links["agent-" + agent_ids[tu]] = inp
    by_fp = {t["fp"]: t for t in tree}
    for t in sorted(tree, key=lambda x: 0 if x["kind"] != "nested" else 1):
        first = first_user(t["recs"])
        if t["kind"] == "hub":
            t["stage"], t["stage_basis"], t["role"], t["role_basis"] = None, "hub", "hub", "hub"
        elif t["kind"] == "chip":
            sp = t["spawn"]
            st, sb = stage_of(first, str(sp.get("description") or sp.get("title") or ""), None)
            t["stage"], t["stage_basis"], t["role"] = st, sb, "chip"
            t["role_basis"] = "chip-orphan" if t["via"] == "orphan" else "chip-joined"
        else:
            sp = links.get(t["stem"], {})
            root = by_fp.get(t["root"], {})
            inherited = root.get("stage") if root.get("kind") == "chip" else None
            st, sb = stage_of(first, str(sp.get("description") or ""), inherited)
            t["stage"], t["stage_basis"] = st, sb
            if "workflows" in t["sub_rel"].split(os.sep)[:-1]:
                t["role"], t["role_basis"] = "workflow-agent", "path-workflows"
            else:
                sig = reviewer_signal(first, sp)
                if sig:
                    t["role"], t["role_basis"] = "reviewer", sig
                elif st is not None:
                    t["role"], t["role_basis"] = "spoke", "stage-attributed"
                else:
                    t["role"], t["role_basis"] = "subagent-other", "none"


def subset_rule(tree):
    """A tree file whose message-id set is contained in another's is a resume or fork copy:
    it is left out of the count (its subagents stay, by path). Equal sets keep the first path."""
    ids = {t["rel"]: msg_ids(t["recs"]) for t in tree}
    kept, excluded = [], 0
    for t in sorted(tree, key=lambda x: (-len(ids[x["rel"]]), x["rel"])):
        s = ids[t["rel"]]
        if s and any(s <= ids[k["rel"]] for k in kept):
            t["excluded"] = True
            excluded += 1
        else:
            t["excluded"] = False
            kept.append(t)
    count = {}
    for t in kept:
        for i in ids[t["rel"]]:
            count[i] = count.get(i, 0) + 1
    shared = sum(1 for v in count.values() if v > 1)
    hub_kept = [t for t in kept if t["kind"] == "hub"]
    pairs = sum(1 for x in range(len(hub_kept)) for y in range(x + 1, len(hub_kept))
                if ids[hub_kept[x]["rel"]] & ids[hub_kept[y]["rel"]])
    return excluded, shared, len(hub_kept), pairs


def count_tokens(a, sessions, causes):
    """Join every counted session to its store record. Default: a FRESH scratch store built
    by the extractor over a hard-link view of exactly these files, one directory per file,
    so the record's (project_dir, session_id) keys on the file path, never the stem alone."""
    joined, unextracted, ambiguous = {}, 0, 0
    if a.store:
        meta, recs = read_store(a.store)
        source = "injected"
    else:
        view = os.path.join(a.run_dir, "view")
        os.makedirs(view)
        keyed = {}
        try:
            for i, t in enumerate(sessions):
                d = os.path.join(view, "%05d" % i)
                os.makedirs(d)
                os.link(t["fp"], os.path.join(d, os.path.basename(t["fp"])))
                keyed[("%05d" % i, t["stem"])] = t
            source = "fresh"
        except OSError:
            source = "fallback-full-root"
        store_dir = os.path.join(a.run_dir, "store")
        os.makedirs(store_dir)
        src = view if source == "fresh" else a.source_root
        rc, err = run_extractor(a.extractor, store_dir, src, a.jq_dir)
        if rc != 0:
            raise Failed("the usage extractor exited %d: %s" % (rc, first_line(err)))
        meta, recs = read_store(os.path.join(store_dir, "usage.jsonl"))
        if source == "fresh":
            by_key = {(r.get("project_dir"), r.get("session_id")): r for r in recs}
            missing = [k for k in keyed if k not in by_key]
            if missing:  # a live file can be read mid-append: retry once
                store2 = os.path.join(a.run_dir, "store-retry")
                os.makedirs(store2)
                rc, err = run_extractor(a.extractor, store2, view, a.jq_dir)
                if rc == 0:
                    _m2, recs2 = read_store(os.path.join(store2, "usage.jsonl"))
                    for r in recs2:
                        k = (r.get("project_dir"), r.get("session_id"))
                        if k in keyed and k not in by_key:
                            by_key[k] = r
            for k, t in keyed.items():
                if k in by_key:
                    joined[t["rel"]] = by_key[k]
                else:
                    unextracted += 1
    v = semver((meta or {}).get("schema_version"))
    if v is None or v < semver(a.min_store_schema):
        raise Refused("store schema %s is below the minimum %s: a store that counted per transcript line "
                      "yields no figure in this unit" % ((meta or {}).get("schema_version"), a.min_store_schema))
    if source != "fresh":
        # Real layout: a record keys on (parent directory basename, file stem); a key two
        # files share cannot be told apart, so neither is joined and the row says so.
        want = {}
        for t in sessions:
            want.setdefault((os.path.basename(os.path.dirname(t["fp"])), t["stem"]), []).append(t)
        have = {}
        for r in recs:
            have.setdefault((r.get("project_dir"), r.get("session_id")), []).append(r)
        for k, ts in want.items():
            rs = have.get(k, [])
            if len(ts) > 1 or len(rs) > 1:
                ambiguous += len(ts)
            elif rs:
                joined[ts[0]["rel"]] = rs[0]
            else:
                unextracted += 1
    if unextracted:
        causes.append("unextracted-files")
    if ambiguous:
        causes.append("ambiguous-store-key")
    if source == "fallback-full-root":
        causes.append("fallback-source")
    store_meta = {"source": source, "schema_version": (meta or {}).get("schema_version"),
                  "generator_version": (meta or {}).get("generator_version")}
    return joined, unextracted, ambiguous, store_meta


def summary(a, row, out_path):
    cov = row["coverage"]
    by_role = {r: 0 for r in ROLE_ORDER}
    nonhub = nonhub_null = 0
    for c in row["cells"]:
        by_role[c["role"]] += c["sessions"]
        if c["role"] != "hub":
            nonhub += c["sessions"]
            if c["stage"] is None:
                nonhub_null += c["sessions"]
    tot = row["total"]
    inc = "not-evaluated" if tot["incomplete_responses"] is None else str(tot["incomplete_responses"])
    if "weekly_points" in tot:
        wp = "wp %.2f at w-low · %.2f at w-high (%s)" % (tot["weekly_points"]["at_w_low"],
                                                        tot["weekly_points"]["at_w_high"], row["unit"]["label"])
    else:
        wp = "wp unresolved"
    unstaged = ("%d%%" % round(100.0 * nonhub_null / nonhub)) if nonhub else "n/a"
    line = ("cost-row %s %s: trees %d · sessions %d (hub %d / chip %d / spoke %d / reviewer %d / workflow %d / "
            "other %d) · responses %d · incomplete %s · %s · unstaged %s · cross-file shared %d · "
            "unjoined chips %d · state %s") % (
        row["slug"], row["version"] or "version-less", sum(1 for h in row["hub_trees"] if h["counted"]),
        tot["sessions"], by_role["hub"], by_role["chip"], by_role["spoke"], by_role["reviewer"],
        by_role["workflow-agent"], by_role["subagent-other"], tot["responses"], inc, wp, unstaged,
        cov["cross_file_shared_responses"], cov["chips"]["unjoined"], cov["measurement_state"])
    return [line, "row: " + out_path]


def build_row(a):
    if not SLUG_RE.fullmatch(a.slug or ""):
        raise UsageError("the milestone title is not a filename-safe slug: %r" % a.slug)
    if not a.out_dir:
        raise UsageError("no row home: pass --out-dir <dir>")
    causes = []
    d = discover(a)
    tree = d["tree"]
    classify(tree)
    excluded, shared, hub_files, pairs = subset_rule(tree)
    if shared:
        causes.append("cross-file-shared-responses")
    counted = [t for t in tree if not t["excluded"]]
    sessions = [t for t in counted if any(r.get("type") == "assistant" for r in t["recs"])]
    joined, unextracted, ambiguous, store_meta = count_tokens(a, sessions, causes)
    cells, total, malformed = {}, new_cell(None, "total"), 0
    stage_basis, role_basis = {}, {}
    for t in sessions:
        rec = joined.get(t["rel"])
        if rec is None:
            continue
        if not tokens_ok(rec.get("tokens")):
            malformed += 1
            continue
        key = (t["stage"], t["role"])
        fold(cells.setdefault(key, new_cell(t["stage"], t["role"])), rec)
        fold(total, rec)
        stage_basis[t["stage_basis"]] = stage_basis.get(t["stage_basis"], 0) + 1
        role_basis[t["role_basis"]] = role_basis.get(t["role_basis"], 0) + 1
    if malformed:
        causes.append("malformed-store-record")
    ordered = sorted(cells.values(), key=lambda c: (c["stage"] is None, c["stage"] or 0, ROLE_ORDER.index(c["role"])))
    for c in ordered + [total]:
        finish(c)
    objs = [{"tokens": c["tokens"], "by_model": c["by_model"]} for c in ordered + [total]]
    conv, conv_err = convert(a.converter, objs, a.jq_dir, dict(e.split("=", 1) for e in (a.converter_env or [])))
    if conv is None:
        unit = {"state": "not-run", "cause": conv_err}
        causes.append("unit-unresolved")
    else:
        unit = {"state": "fetched", "params": conv["params"], "label": conv["label"],
                "label_source": conv["label_source"]}
        for c, pr in zip(ordered + [total], conv["pairs"]):
            c["weekly_points"] = {"at_w_low": pr["at_w_low"], "at_w_high": pr["at_w_high"]}
            c["per_model"] = {"split": pr.get("per_model"), "unprobed_models": pr.get("unprobed_models", []),
                              "own_window_models": pr.get("own_window_models", [])}
    total.pop("stage", None)
    total.pop("role", None)
    points = json.loads(a.points_json) if a.points_json else {}
    version = a.version if re.match(r"^v\d+\.\d+", a.version or "") else None
    row = {
        "record": ROW_RECORD, "schema_version": ROW_SCHEMA, "slug": a.slug, "version": version,
        "milestone": int(a.milestone) if str(a.milestone or "").isdigit() else None,
        "measured_utc": utc_now(), "since_utc": a.since,
        "hub_trees": [{"id": t["stem"], "via": t["via"], "counted": not t["excluded"]}
                      for t in tree if t["kind"] == "hub"],
        "points": {k: points.get(k) for k in ("planned", "delivered", "ratio", "na_reason", "flag")},
        "store": store_meta, "cells": ordered, "total": total, "unit": unit,
        "coverage": {
            "measurement_state": "degraded" if causes else "fetched",
            "degraded_causes": sorted(set(causes)),
            "counting_scope": COUNTING_SCOPE,
            "cross_file_shared_responses": shared, "hub_files": hub_files, "sharing_hub_pairs": pairs,
            "subset_files_excluded": excluded,
            "advisor_iterations": "not counted",
            "stage_basis": stage_basis, "role_basis": role_basis, "chips": d["chips"],
            "symlink_aliases_skipped": d["aliases"], "unextracted_files": unextracted,
            "ambiguous_store_keys": ambiguous, "malformed_store_records": malformed,
            "measurement_boundary": BOUNDARY,
            "discovery": {"predicate": "Milestone " + a.slug, "main_files_scanned": d["scanned"],
                          "tree_files": len(tree), "explicit_unmatched": d["explicit_unmatched"],
                          "files": sorted(digest(t["rel"]) for t in tree)},
        },
    }
    if "weekly_points" in total:
        row["weekly_points"] = total["weekly_points"]
    return row, conv is None


def write_row(a, row):
    final = os.path.join(a.out_dir, "release-cost", a.slug + ".json")
    home_guard(a.out_dir, final)
    if os.path.exists(final) and not a.force:
        try:
            with open(final, "r", encoding="utf-8") as fh:
                old = set(json.load(fh)["coverage"]["discovery"]["files"])
        except Exception:
            raise Refused("the stored row at the row path cannot be read; --force replaces it")
        lost = old - set(row["coverage"]["discovery"]["files"])
        if lost:
            raise Refused("a re-run would replace the stored row with one that discovered %d fewer file(s) "
                          "(a shrinking measurement); --force replaces it" % len(lost))
    try:
        os.makedirs(os.path.dirname(final), exist_ok=True)
        tmp = final + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump(row, fh, indent=2)
            fh.write("\n")
        os.replace(tmp, final)
    except OSError as e:
        raise Failed("the row could not be written: %s" % e)
    return final


def main(argv, out=None, err=None):
    out = out or sys.stdout
    err = err or sys.stderr
    ap = argparse.ArgumentParser(prog="compute-release-velocity.sh --cost-row")
    for f in ("--slug", "--version", "--milestone", "--since", "--source-root", "--out-dir", "--points-json",
              "--extractor", "--converter", "--jq-dir", "--run-dir", "--store", "--min-store-schema"):
        ap.add_argument(f, default="")
    ap.add_argument("--hub-session", action="append")
    ap.add_argument("--converter-env", action="append")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args(argv)
    try:
        row, unresolved = build_row(a)
        path = write_row(a, row)
    except UsageError as e:
        print("ERROR (exit 1): %s" % e, file=err)
        return 1
    except Refused as e:
        print("REFUSED (exit 2): %s" % e, file=err)
        return 2
    except Failed as e:
        print("FAILED (exit 3): %s — no row written" % e, file=err)
        return 3
    for line in summary(a, row, path):
        print(line, file=out)
    return 4 if unresolved else 0


# ─── Self-test: the cost-row arms, offline over inline fixtures ──────────────
def U(i, o, cw, cr, h=0):
    return {"input_tokens": i, "output_tokens": o, "cache_creation_input_tokens": cw,
            "cache_read_input_tokens": cr,
            "cache_creation": {"ephemeral_1h_input_tokens": h, "ephemeral_5m_input_tokens": cw - h}}


class Tx(object):
    """One fixture transcript. Every assistant line carries message.id, a usage block and
    the stop_reason key, so the extractor can evaluate each response's completeness."""

    def __init__(self, sid):
        self.sid, self.lines, self.n = sid, [], 0

    def _base(self, typ):
        self.n += 1
        return {"type": typ, "uuid": "%s-%d" % (self.sid, self.n), "parentUuid": None, "isSidechain": False,
                "sessionId": self.sid, "cwd": "/fixture/wt",
                "timestamp": "2026-10-01T00:%02d:%02dZ" % (self.n // 60, self.n % 60)}

    def user(self, text):
        r = self._base("user")
        r["message"] = {"role": "user", "content": text}
        self.lines.append(r)
        return self

    def resp(self, mid, usage, stop="end_turn", blocks=None, model="model-a"):
        blocks = blocks or [{"type": "text", "text": "ok"}]
        for k, b in enumerate(blocks):
            r = self._base("assistant")
            r["message"] = {"id": mid, "role": "assistant", "model": model, "content": [b],
                            "stop_reason": stop if k == len(blocks) - 1 else None, "usage": usage}
            self.lines.append(r)
        return self

    def spawn(self, mid, tu, name, inp, usage, agent=None, tur=None):
        self.resp(mid, usage, stop="tool_use", blocks=[{"type": "tool_use", "id": tu, "name": name, "input": inp}])
        r = self._base("user")
        r["message"] = {"role": "user", "content": [{"type": "tool_result", "tool_use_id": tu, "content": "ok"}]}
        r["toolUseResult"] = tur if tur is not None else ({"status": "completed", "agentId": agent} if agent else
                                                           {"status": "started"})
        self.lines.append(r)
        return self

    def write(self, path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            for r in self.lines:
                fh.write(json.dumps(r) + "\n")


def build_multi_hub(root, slug):
    P = "Milestone " + slug
    hub1 = Tx("hub1").user("Run the release hub.").resp("h1-1", U(10, 5, 100, 1000))
    hub1.spawn("h1-2", "tu1", "Agent", {"description": "Stage 5 solutioning spoke", "subagent_type": "general-purpose",
                                         "prompt": "You are executing Stage 5 (Solutioning) for the card in %s." % P},
               U(10, 5, 0, 1100), agent="s5")
    hub1.spawn("h1-3", "tu2", "Agent", {"description": "Stage 6 engineering spoke", "subagent_type": "general-purpose",
                                         "prompt": "You are executing Stage 6 (Engineering) in %s." % P},
               U(10, 5, 0, 1200), agent="s6")
    hub1.spawn("h1-4", "tu3", "Agent", {"description": "Adversarial design review of the Stage 5 output",
                                         "subagent_type": "general-purpose",
                                         "prompt": "Review the Stage 5 output for %s." % P},
               U(10, 5, 0, 1300), agent="rv")
    hub1.spawn("h1-5", "tu4", CHIP_TOOL, {"title": "a chip", "prompt": "Chip work:   executing Stage 7 for %s\n run the checks." % P},
               U(10, 5, 0, 1400))
    hub1.write(os.path.join(root, "projA", "hub1.jsonl"))
    Tx("s5").user("You are executing Stage 5 (Solutioning) for the card in %s." % P).resp(
        "s5-1", U(20, 10, 200, 2000)).write(os.path.join(root, "projA", "hub1", "subagents", "agent-s5.jsonl"))
    Tx("s6").user("You are executing Stage 6 (Engineering) in %s." % P).resp(
        "s6-1", U(30, 15, 300, 3000), blocks=[{"type": "text", "text": "a"}, {"type": "text", "text": "b"}]).write(
        os.path.join(root, "projA", "hub1", "subagents", "agent-s6.jsonl"))
    Tx("rv").user("Review the Stage 5 output for %s." % P).resp("rv-1", U(5, 5, 50, 500)).write(
        os.path.join(root, "projA", "hub1", "subagents", "agent-rv.jsonl"))
    Tx("wf").user("A workflow step.").resp("wf-1", U(1, 1, 10, 100)).write(
        os.path.join(root, "projA", "hub1", "subagents", "workflows", "agent-wf.jsonl"))
    hub2 = Tx("hub2").user("The second hub.").resp("h2-1", U(10, 5, 100, 1000))
    hub2.spawn("h2-2", "tu6", "Agent", {"description": "Stage 7 dev testing", "subagent_type": "general-purpose",
                                         "prompt": "Please test the change for %s." % P}, U(10, 5, 0, 1000), agent="s7")
    hub2.spawn("h2-3", "tu7", CHIP_TOOL, {"prompt": "An unjoined chip for %s." % P}, U(10, 5, 0, 1000))
    hub2.write(os.path.join(root, "projB", "hub2.jsonl"))
    Tx("s7").user("Please test the change for %s." % P).resp("s7-1", U(40, 20, 400, 4000)).write(
        os.path.join(root, "projB", "hub2", "subagents", "agent-s7.jsonl"))
    Tx("chip1").user("Chip work: executing Stage 7 for %s run the checks." % P).resp(
        "c1-1", U(25, 12, 250, 2500)).write(os.path.join(root, "projC", "chip1.jsonl"))
    Tx("c1s").user("Help with the checks.").resp("c1s-1", U(8, 4, 80, 800)).write(
        os.path.join(root, "projC", "chip1", "subagents", "agent-c1s.jsonl"))
    Tx("orph").user("You are executing Stage 8 (QA) for %s." % P).resp("or-1", U(6, 3, 60, 600)).write(
        os.path.join(root, "projD", "orphan.jsonl"))
    # A near-miss: the slug in prose (not in a spawn, not in the first message), a spawn
    # for ANOTHER milestone, and a longer slug that only shares a prefix.
    other = Tx("oth").user("Status notes.").resp("ot-1", U(1, 1, 1, 1))
    other.user("We discussed %s yesterday." % P)
    other.spawn("ot-2", "tuX", "Agent", {"description": "Stage 3", "prompt": "Work on Milestone another-slug."}, U(1, 1, 1, 1))
    other.spawn("ot-3", "tuY", "Agent", {"description": "x", "prompt": "Work on %s-extended." % P}, U(1, 1, 1, 1))
    other.write(os.path.join(root, "projC", "other.jsonl"))


def self_test(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", required=True)
    ap.add_argument("--jq-dir", default="")
    ap.add_argument("--min-store-schema", required=True)
    s = ap.parse_args(argv)
    extractor = os.path.join(s.repo_root, "core/skills/finops-usage-extractor/scripts/extract-usage.sh")
    converter = os.path.join(s.repo_root, "core/skills/finops-usage-extractor/scripts/convert-usage.sh")
    base = tempfile.mkdtemp(prefix="cost-row-selftest-")
    fails = []

    def ok(name):
        print("  PASS: " + name)

    def bad(name, why):
        fails.append(name)
        print("  FAIL: %s — %s" % (name, why))

    os.makedirs(os.path.join(base, "emptycfg"))
    os.makedirs(os.path.join(base, "nosrc"))
    conv_env = ["PMO_SRC_ROOT=" + s.repo_root, "PMO_PLATFORM_CONFIG_ROOT=" + os.path.join(base, "emptycfg")]

    def run(slug, root, out_dir, extra=None, env=None):
        rd = tempfile.mkdtemp(dir=base, prefix="run-")
        argv2 = ["--slug", slug, "--version", "v0.01", "--milestone", "7", "--since", "2020-01-01T00:00:00Z",
                 "--source-root", root, "--out-dir", out_dir, "--extractor", extractor, "--converter", converter,
                 "--jq-dir", s.jq_dir, "--run-dir", rd, "--min-store-schema", s.min_store_schema,
                 "--points-json", json.dumps({"planned": 8, "delivered": 8, "ratio": "1.00"})]
        for e in (env if env is not None else conv_env):
            argv2 += ["--converter-env", e]
        o, e2 = io.StringIO(), io.StringIO()
        rc = main(argv2 + (extra or []), out=o, err=e2)
        return rc, o.getvalue().splitlines(), e2.getvalue()

    def load(out_dir, slug):
        with open(os.path.join(out_dir, "release-cost", slug + ".json"), encoding="utf-8") as fh:
            return json.load(fh)

    def cellmap(row):
        return {(c["stage"], c["role"]): c for c in row["cells"]}

    def strip_cells(row):
        return [{k: c[k] for k in ("stage", "role", "sessions", "responses", "incomplete_responses",
                                   "unevaluated_responses", "tokens", "by_model")} for c in row["cells"]]

    try:
        slug = "fixture-slug-one"
        root = os.path.join(base, "root")
        build_multi_hub(root, slug)
        out1 = os.path.join(base, "out1")

        # CR-1 multi-hub (the cost-row mode end to end): two hubs with disjoint ids, spokes at
        # stages 5, 6 and 7, a general-purpose reviewer, a workflow agent, an exact-prompt chip
        # whose nested session inherits its stage, an orphan chip and an unjoined spawn.
        rc, lines, err = run(slug, root, out1)
        row = load(out1, slug) if rc == 0 else None
        want = {(None, "hub"): 2, (None, "workflow-agent"): 1, (5, "spoke"): 1, (5, "reviewer"): 1,
                (6, "spoke"): 1, (7, "chip"): 1, (7, "spoke"): 2, (8, "chip"): 1}
        got = {k: c["sessions"] for k, c in cellmap(row).items()} if row else None
        if rc == 0 and got == want and row["coverage"]["chips"] == {"spawn_task_calls": 2, "joined": 1,
                                                                   "unjoined": 1, "orphan": 1}:
            ok("CR-1 multi-hub: the exact stage x role cell set, the chip join and the unjoined spawn")
        else:
            bad("CR-1 multi-hub", "rc %s err %s cells %s" % (rc, err.strip(), got))
        if row:
            tot = zero_tokens()
            meta, recs = None, []
            stg = os.path.join(base, "inj")
            os.makedirs(stg)
            rcx, errx = run_extractor(extractor, stg, root, s.jq_dir)
            meta, recs = read_store(os.path.join(stg, "usage.jsonl"))
            for c in row["cells"]:
                tokens_add(tot, c["tokens"])
            want_tot = zero_tokens()
            for r in recs:
                if r.get("session_id") not in ("other",):
                    tokens_add(want_tot, r["tokens"])
            if rcx == 0 and tot == want_tot == row["total"]["tokens"]:
                ok("CR-1 conservation: the sum of the cells equals the store's sessions, the near-miss excluded")
            else:
                bad("CR-1 conservation", "cells %s store %s (extractor rc %s)" % (tot, want_tot, rcx))
            rb, sb = row["coverage"]["role_basis"], row["coverage"]["stage_basis"]
            if rb.get("reviewer-marker") == 1 and sb.get("chip-root") == 1 and sb.get("spawn-description") == 2:
                ok("CR-1 role and stage from content: a general-purpose reviewer, a description-staged spoke, a chip-inherited stage")
            else:
                bad("CR-1 bases", "role_basis %s stage_basis %s" % (rb, sb))
            if len(lines) == 2 and lines[0].startswith("cost-row %s v0.01: trees 2 · sessions 10" % slug) \
                    and lines[1].startswith("row: "):
                ok("cost-row stdout is exactly two lines: the summary and the row path")
            else:
                bad("cost-row stdout", repr(lines))
            # CR-12: the summary line carries no session id and no parenthesized .md path.
            leak = [x for x in ("hub1", "hub2", "chip1", "agent-", "orphan", "projA", "projC") if x in lines[0]]
            if not leak and not re.search(r"\([^)]*\.md\)", "\n".join(lines)):
                ok("CR-12 the summary line names no fixture session and no .md path")
            else:
                bad("CR-12 summary leak", repr(leak))
            # CR-8 (CIAC-3 both-bracket-ends): the row's pairs ARE the one conversion's pairs over
            # the same objects, keyed by bracket end, and the two ends differ.
            objs = [{"tokens": c["tokens"], "by_model": c["by_model"]} for c in row["cells"]]
            objs.append({"tokens": row["total"]["tokens"], "by_model": row["total"]["by_model"]})
            conv, cerr = convert(converter, objs, s.jq_dir, dict(e.split("=", 1) for e in conv_env))
            mine = [c["weekly_points"] for c in row["cells"]] + [row["total"]["weekly_points"]]
            theirs = [{"at_w_low": p["at_w_low"], "at_w_high": p["at_w_high"]} for p in (conv or {}).get("pairs", [])]
            if conv and mine == theirs and row["weekly_points"] == theirs[-1] \
                    and any(abs(p["at_w_low"] - p["at_w_high"]) > 1e-12 for p in theirs):
                ok("CR-8 CIAC-3 both-bracket-ends: pairs equal the conversion's, at both ends, which differ")
            else:
                bad("CR-8 CIAC-3 both-bracket-ends", "conv err %s; row %s vs conversion %s" % (cerr, mine, theirs))

        # CR-2 killed-spoke: a background spawn whose agent died mid-response. Its last response
        # carries no stop reason on any line; the hub holds a decoy harness total and a failed
        # notification. Tokens come from the transcript, the stage from the spoke's own prompt.
        kslug = "fixture-slug-kill"
        kroot = os.path.join(base, "kroot")
        P = "Milestone " + kslug
        decoy = 987654
        Tx("hub7").user("hub").spawn("k-1", "tuK", "Agent",
                                     {"description": "background work", "run_in_background": True,
                                      "prompt": "You are executing Stage 6 (Engineering) for %s." % P},
                                     U(3, 2, 0, 50),
                                     tur={"status": "async_launched", "isAsync": True, "agentId": "kk",
                                          "totalTokens": decoy}).user(
            "<task-notification><status>failed</status></task-notification>").write(
            os.path.join(kroot, "projK", "hub7.jsonl"))
        Tx("kk").user("You are executing Stage 6 (Engineering) for %s." % P).resp(
            "kk-1", U(11, 7, 60, 600), stop="tool_use").resp(
            "kk-2", U(13, 3, 0, 700), stop=None,
            blocks=[{"type": "text", "text": "a"}, {"type": "text", "text": "b"}]).write(
            os.path.join(kroot, "projK", "hub7", "subagents", "agent-kk.jsonl"))
        kout = os.path.join(base, "kout")
        rc, lines, err = run(kslug, kroot, kout)
        krow = load(kout, kslug) if rc == 0 else None
        kc = cellmap(krow).get((6, "spoke")) if krow else None
        flat = json.dumps(krow["cells"]) if krow else ""
        if kc and kc["incomplete_responses"] == 1 and kc["lower_bound"] is True and kc["tokens"]["input"] == 24 \
                and kc["tokens"]["cache_read"] == 1300 and str(decoy) not in flat \
                and krow["coverage"]["stage_basis"].get("executing-stage") == 1:
            ok("CR-2 killed-spoke: one incomplete response, a lower bound, transcript tokens, the decoy unused")
        else:
            bad("CR-2 killed-spoke", "rc %s err %s cell %s" % (rc, err.strip(), kc))

        # CR-3: a symlinked alias of a hub's project directory does not double the trees.
        os.symlink(os.path.join(root, "projA"), os.path.join(root, "projA-alias"))
        out3 = os.path.join(base, "out3")
        rc, lines, err = run(slug, root, out3)
        r3 = load(out3, slug) if rc == 0 else None
        if r3 and len(r3["hub_trees"]) == 2 and r3["total"]["sessions"] == 10 \
                and r3["coverage"]["symlink_aliases_skipped"] >= 1:
            ok("CR-3 a symlinked project-directory alias is skipped: still 2 trees and 10 sessions")
        else:
            bad("CR-3 symlink alias", "rc %s err %s" % (rc, err.strip()))
        os.remove(os.path.join(root, "projA-alias"))

        # CR-4: the near-miss is not a tree (CR-1's cell set excludes it), and a fabricated
        # slug finds no tree and is refused.
        rc, lines, err = run("fixture-slug-fabricated", root, os.path.join(base, "out4"))
        if rc == 2 and "zero trees" in err:
            ok("CR-4 a fabricated slug finds zero trees and is refused (exit 2)")
        else:
            bad("CR-4 fabricated slug", "rc %s err %s" % (rc, err.strip()))

        # CR-13: fresh-store parity — the cells from the fresh scratch store equal the cells from
        # a store the real extractor built over the real layout, injected.
        inj = os.path.join(base, "inj", "usage.jsonl")
        out13 = os.path.join(base, "out13")
        rc, lines, err = run(slug, root, out13, extra=["--store", inj])
        r13 = load(out13, slug) if rc == 0 else None
        if row and r13 and strip_cells(r13) == strip_cells(row) and r13["store"]["source"] == "injected" \
                and row["store"]["source"] == "fresh":
            ok("CR-13 fresh-store parity: the scratch store and the injected store give the same cells")
        else:
            bad("CR-13 parity", "rc %s err %s" % (rc, err.strip()))

        # CR-5: an injected store whose record lacks incomplete_responses reads null, never 0.
        with open(inj, encoding="utf-8") as fh:
            lines_in = [json.loads(x) for x in fh if x.strip()]
        for r in lines_in:
            if r.get("record") == "session" and r.get("session_id") == "agent-s6":
                r.pop("incomplete_responses", None)
        inj5 = os.path.join(base, "inj5.jsonl")
        with open(inj5, "w", encoding="utf-8") as fh:
            for r in lines_in:
                fh.write(json.dumps(r) + "\n")
        out5 = os.path.join(base, "out5")
        rc, lines, err = run(slug, root, out5, extra=["--store", inj5])
        r5 = load(out5, slug) if rc == 0 else None
        c5 = cellmap(r5).get((6, "spoke")) if r5 else None
        if c5 and c5["incomplete_responses"] is None and c5["lower_bound"] is None \
                and r5["total"]["incomplete_responses"] is None and "incomplete not-evaluated" in lines[0]:
            ok("CR-5 an absent incomplete_responses is not evaluated (null), never 0")
        else:
            bad("CR-5 absent field", "rc %s cell %s" % (rc, c5))

        # CR-6 / INT-1: an injected store below the minimum schema is refused (exit 2).
        for r in lines_in:
            if r.get("record") == "meta":
                r["schema_version"] = "1.2.0"
        inj6 = os.path.join(base, "inj6.jsonl")
        with open(inj6, "w", encoding="utf-8") as fh:
            for r in lines_in:
                fh.write(json.dumps(r) + "\n")
        rc, lines, err = run(slug, root, os.path.join(base, "out6"), extra=["--store", inj6])
        if rc == 2 and "below the minimum" in err:
            ok("CR-6 a store below the minimum schema is refused (exit 2)")
        else:
            bad("CR-6 minimum schema", "rc %s err %s" % (rc, err.strip()))

        # CR-7 and the subset rule: a resume copy (its ids inside another hub's) is left out and
        # the row stays fetched; a fork that continued shares an id the row cannot remove, so
        # the row is degraded and says why.
        sslug = "fixture-slug-two"
        P2 = "Milestone " + sslug
        sp = {"description": "Stage 6", "prompt": "Engineering for %s." % P2}
        r2a = os.path.join(base, "root2a")
        Tx("hub4").user("hub four").spawn("x1", "tA", "Agent", sp, U(5, 5, 5, 5), agent="q1").resp(
            "x2", U(7, 7, 7, 7)).write(os.path.join(r2a, "projE", "hub4.jsonl"))
        Tx("hub6").user("hub four").spawn("x1", "tA", "Agent", sp, U(5, 5, 5, 5), agent="q1").write(
            os.path.join(r2a, "projE", "hub6.jsonl"))
        rc, lines, err = run(sslug, r2a, os.path.join(base, "out2a"))
        ra = load(os.path.join(base, "out2a"), sslug) if rc == 0 else None
        if ra and ra["coverage"]["subset_files_excluded"] == 1 and ra["coverage"]["cross_file_shared_responses"] == 0 \
                and ra["coverage"]["measurement_state"] == "fetched" and ra["total"]["sessions"] == 1:
            ok("subset rule: a resume copy is left out of the count, and the row stays fetched")
        else:
            bad("subset rule", "rc %s err %s cov %s" % (rc, err.strip(), ra and ra["coverage"]))
        r2b = os.path.join(base, "root2b")
        Tx("hub4").user("hub four").spawn("x1", "tA", "Agent", sp, U(5, 5, 5, 5), agent="q1").resp(
            "x2", U(7, 7, 7, 7)).write(os.path.join(r2b, "projE", "hub4.jsonl"))
        Tx("hub5").user("hub four").spawn("x1", "tA", "Agent", sp, U(5, 5, 5, 5), agent="q1").resp(
            "y2", U(9, 9, 9, 9)).write(os.path.join(r2b, "projE", "hub5.jsonl"))
        rc, lines, err = run(sslug, r2b, os.path.join(base, "out2b"))
        rb2 = load(os.path.join(base, "out2b"), sslug) if rc == 0 else None
        cov = rb2["coverage"] if rb2 else {}
        if rb2 and cov["cross_file_shared_responses"] == 1 and cov["sharing_hub_pairs"] == 1 \
                and cov["hub_files"] == 2 and cov["measurement_state"] == "degraded" \
                and "cross-file-shared-responses" in cov["degraded_causes"] and "state degraded" in lines[0]:
            ok("CR-7 two hubs sharing one message id: shared 1, one sharing pair, the row degraded")
        else:
            bad("CR-7 shared ids", "rc %s err %s cov %s" % (rc, err.strip(), cov))

        # CD-1: a conversion that cannot resolve still writes the raw totals, with the unit
        # not run, no weekly points, the row degraded, and exit 4.
        outu = os.path.join(base, "outu")
        rc, lines, err = run(slug, root, outu, env=["PMO_SRC_ROOT=" + os.path.join(base, "nosrc"),
                                                    "PMO_PLATFORM_CONFIG_ROOT=" + os.path.join(base, "emptycfg")])
        ru = load(outu, slug) if os.path.exists(os.path.join(outu, "release-cost", slug + ".json")) else None
        if rc == 4 and ru and ru["unit"]["state"] == "not-run" and "weekly_points" not in ru \
                and all("weekly_points" not in c for c in ru["cells"]) and ru["total"]["tokens"] == row["total"]["tokens"] \
                and "unit-unresolved" in ru["coverage"]["degraded_causes"] and "wp unresolved" in lines[0]:
            ok("CD-1 an unresolved unit writes the raw totals, degraded, exit 4")
        else:
            bad("CD-1 unit unresolved", "rc %s err %s" % (rc, err.strip()))

        # CR-9 (FM-1): the cost-unit record's rule, not its seed. The configured bracket must be
        # well formed, and a bracket that has moved from the authoring bracket the record states
        # must carry a dated revisit line recording a changed value — narrowing AND widening are
        # both sanctioned when recorded (the record's Decision 8). The authoring ends are parsed
        # from the record, never written here.
        adrs = sorted(x for x in os.listdir(os.path.join(s.repo_root, "release/ADRs"))
                      if x.endswith("-release-graph-cost-unit.md"))
        with open(os.path.join(s.repo_root, "release/ADRs", adrs[-1]), encoding="utf-8") as fh:
            adr = fh.read()
        with open(os.path.join(s.repo_root, "core/standards/gate-efficacy-standard.md"), encoding="utf-8") as fh:
            reg = fh.read()
        penv = dict(os.environ)
        penv.update(dict(e.split("=", 1) for e in conv_env))
        penv["PATH"] = (s.jq_dir + ":" if s.jq_dir else "") + "/usr/bin:/bin"
        pp = subprocess.run(["/bin/bash", converter, "--params"], env=penv, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, universal_newlines=True)
        params = json.loads(pp.stdout) if pp.returncode == 0 else {}
        lo, hi = params.get("cache_read_weight_low"), params.get("cache_read_weight_high")
        verdict = bracket_rule(adr, reg, lo, hi) if lo is not None else "unreadable"
        m = AUTH_RE.search(adr)
        if verdict == "holds" and m:
            a_lo, a_hi = float(m.group(1)), float(m.group(2))
            moved_line = "<br>`revisit · 2099-01-01 · run · eligible pairs 3 (pooled 3) · excluded 0 () · pairs held at x · calibration sufficient · values changed`"
            reg_moved = "\n".join((ln + moved_line) if (REG_POP in ln and REG_ROW in ln) else ln
                                  for ln in reg.splitlines())
            arms = [
                (bracket_rule(adr, reg_moved, a_lo * 2, a_hi / 2), "holds", "a narrowed bracket with its revisit line"),
                (bracket_rule(adr, reg_moved, a_lo / 2, min(1.0, a_hi * 2)), "holds", "a widened bracket with its revisit line"),
                (bracket_rule(adr, reg, a_lo * 2, a_hi / 2), "unrecorded-move", "a moved bracket with no revisit line"),
                (bracket_rule(adr, reg_moved, a_hi, a_lo), "malformed", "a bracket whose low end is not below its high end"),
                (bracket_rule(AUTH_RE.sub("", adr), reg, lo, hi), "unparseable", "vacuity: a record that states no authoring bracket"),
            ]
            wrong = [(g, w, n) for g, w, n in arms if g != w]
            if not wrong:
                ok("CR-9 the configured bracket satisfies the cost-unit record's rule; its near-misses and vacuity control fire")
            else:
                bad("CR-9 rule arms", repr(wrong))
        else:
            bad("CR-9 bracket rule", "verdict %s (params rc %s %s)" % (verdict, pp.returncode, first_line(pp.stderr)))

        # CR-10: the home guard — a home inside a repository where the row is not ignored is
        # refused; the same home, ignored, is written.
        repo = os.path.join(base, "repo")
        subprocess.run(["git", "init", "-q", repo], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        rc_a, _l, err_a = run(slug, root, os.path.join(repo, "rows"))
        with open(os.path.join(repo, ".gitignore"), "w") as fh:
            fh.write("/rows/\n")
        rc_b, _l, err_b = run(slug, root, os.path.join(repo, "rows"))
        if rc_a == 2 and "NOT ignored" in err_a and rc_b == 0 \
                and os.path.exists(os.path.join(repo, "rows", "release-cost", slug + ".json")):
            ok("CR-10 the home guard refuses an unignored home in a repository and writes an ignored one")
        else:
            bad("CR-10 home guard", "rc %s/%s err %s %s" % (rc_a, rc_b, err_a.strip(), err_b.strip()))

        # CR-11: a re-run rewrites the same file and leaves another slug's row untouched; a
        # re-run that discovered less is refused unless forced.
        other_row = os.path.join(out1, "release-cost", "another-slug.json")
        with open(other_row, "w") as fh:
            fh.write('{"record": "release-cost-row"}\n')
        rc, lines, err = run(slug, root, out1)
        with open(other_row) as fh:
            untouched = fh.read() == '{"record": "release-cost-row"}\n'
        shrunk = os.path.join(base, "root-shrunk")
        shutil.copytree(root, shrunk, symlinks=True)
        os.remove(os.path.join(shrunk, "projB", "hub2.jsonl"))
        rc_s, _l, err_s = run(slug, shrunk, out1)
        rc_f, _l, err_f = run(slug, shrunk, out1, extra=["--force"])
        if rc == 0 and untouched and rc_s == 2 and "fewer file" in err_s and rc_f == 0:
            ok("CR-11 a re-run rewrites its own row only; a shrinking re-run is refused unless forced")
        else:
            bad("CR-11 re-run", "rc %s untouched %s shrink rc %s force rc %s" % (rc, untouched, rc_s, rc_f))
    finally:
        shutil.rmtree(base, ignore_errors=True)
    if fails:
        print("cost-row self-test: FAIL (%d arm(s): %s)" % (len(fails), ", ".join(fails)))
        return 1
    print("cost-row self-test: PASS")
    return 0


AUTH_RE = re.compile(r"At authoring the bracket is \*\*([0-9.]+)\s*[–-]\s*([0-9.]+)\*\*")
REG_POP = "cost-unit-calibration-revisits"
REG_ROW = "| **class 3-O.**"


def bracket_rule(adr_text, register_text, low, high):
    m = AUTH_RE.search(adr_text)
    if not m:
        return "unparseable"
    if not (isinstance(low, (int, float)) and isinstance(high, (int, float)) and 0 < low < high <= 1.0):
        return "malformed"
    a_lo, a_hi = float(m.group(1)), float(m.group(2))
    if abs(low - a_lo) < 1e-12 and abs(high - a_hi) < 1e-12:
        return "holds"
    rows = [ln for ln in register_text.splitlines() if REG_POP in ln and REG_ROW in ln]
    if rows and re.search(r"revisit · \d{4}-\d{2}-\d{2} · [^`]* · values changed", rows[0]):
        return "holds"
    return "unrecorded-move"


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--self-test":
        sys.exit(self_test(sys.argv[2:]))
    sys.exit(main(sys.argv[1:]))
PYEOF

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

# ─── The quality-share reading (--quality-share) ─────────────────────────────
#
# Seven pure functions, defined here ABOVE the --self-test gate for the reason recorded
# at _rv_select_candidates: below the gate no arm can reach them. Every function except
# _rv_qs_params, which reads the two configuration rungs, takes its inputs on argv; none
# touches gh, git or the network. Each prints its result and then a line OK; a failure
# prints `NE <reason>` and then OK. A missing OK means the pass crashed, and the caller
# reads that as NOT-EVALUATED, never as an empty result. The band's values and its
# counting rule are read from the [quality_share_band] section of the platform-config
# template; nothing here states them. Method: release-velocity-tracking.md section 7b.
#
# THE LOG MAY ARRIVE ON STDIN. _rv_qs_closing and _rv_qs_window take the release log's
# text as $1, and read it from stdin instead when $1 is `-`. The live log is about a
# megabyte, near the platform's argument-size limit, so the live caller redirects the
# file; the self-test passes its inline logs on argv. The first-parent list stays on
# argv: about a tenth of that limit today.
#
# THE RELEASE TABLE. The log's rows are read from the table whose header line's first
# cell is `Version`: that line pins the Milestone, Release PR and Merge SHA columns by
# name, and the rows are the table lines of eight or more cells that follow it without
# a break, so a later table elsewhere in the file is not read as release rows.
read -r -d '' _RV_QS_PY <<'PYEOF' || true
import json, re, sys
from fractions import Fraction

SHA_RE = re.compile(r"\b[0-9a-f]{40}\b")
PR_RE = re.compile(r"#(\d+)")
MERGE_RE = re.compile(r"^Merge pull request #(\d+) from [^/\s]+/(release/\S+)")
KEYS = ["counted_label", "scaffolding_label", "bug_type_label", "share_floor",
        "share_ceiling", "window_releases", "judged_on", "values_set_at"]
FRACTION_RE = re.compile(r"^(0(\.[0-9]+)?|1(\.0+)?)$")
RESETS = 3   # CALIBRATE-AFTER-3: the measured-release count the re-set waits for


class NotEvaluated(Exception):
    pass


def done(text):
    if text:
        print(text)
    print("OK")


def text_arg(v):
    return sys.stdin.read() if v == "-" else v


def cells(line):
    s = line.strip()
    if not s.startswith("|"):
        return None
    s = s[1:-1] if s.endswith("|") else s[1:]
    return [c.strip() for c in re.split(r"(?<!\\)\|", s)]


def log_rows(text):
    hdr, rows, open_table = None, [], False
    for line in text.splitlines():
        c = cells(line)
        if c is None:
            if hdr is not None:
                open_table = False
            continue
        if c and c[0] == "Version" and len(c) >= 8 and hdr is None:
            for name in ("Milestone", "Release PR", "Merge SHA"):
                if name not in c:
                    raise NotEvaluated("the release-log header lacks %s" % name)
            hdr = {n: c.index(n) for n in ("Milestone", "Release PR", "Merge SHA")}
            open_table = True
            continue
        if hdr is None or not open_table or len(c) < 8:
            continue
        if all(re.match(r"^:?-+:?$", x) for x in c if x):
            continue
        rows.append({"milestone": c[hdr["Milestone"]],
                     "prs": {int(n) for n in PR_RE.findall(c[hdr["Release PR"]])},
                     "shas": SHA_RE.findall(c[hdr["Merge SHA"]])})
    if hdr is None:
        raise NotEvaluated("the release log has no table whose header begins with Version")
    return rows


def closing_row(rows, title):
    hits = [r for r in rows if r["milestone"] == title]
    if not hits:
        raise NotEvaluated("the release log has no row for %s (its Stage 12 row has not landed)" % title)
    if len(hits) > 1:
        raise NotEvaluated("%d release-log rows name %s" % (len(hits), title))
    if len(hits[0]["shas"]) != 1:
        raise NotEvaluated("the release-log row for %s carries %d merge SHAs; the window anchor is ambiguous"
                           % (title, len(hits[0]["shas"])))
    return hits[0]


def cmd_params(argv):
    tmpl, indiv = argv[0], argv[1]
    triples = argv[2:]
    values, rung = {}, {}
    where = "(rungs read: template %s · individual %s)" % (tmpl, indiv)
    for i in range(0, len(triples), 3):
        key, tval, ival = triples[i], triples[i + 1], triples[i + 2]
        if ival != "":
            values[key], rung[key] = ival, "individual"
        elif tval != "":
            values[key], rung[key] = tval, "template"
    def bad(key, why):
        raise NotEvaluated("[quality_share_band].%s %s — %s %s" % (key, values.get(key, "absent"), why, where))
    for key in KEYS:
        if key not in values:
            bad(key, "no value at either rung")
        v = values[key]
        if key in ("share_floor", "share_ceiling") and not FRACTION_RE.match(v):
            bad(key, "not a decimal in [0.0, 1.0]")
        if key == "window_releases" and not re.match(r"^[1-9][0-9]*$", v):
            bad(key, "not a positive integer")
        if key == "judged_on" and v not in ("pooled", "mean-of-shares"):
            bad(key, "neither pooled nor mean-of-shares")
        if key == "counted_label" and not re.match(r"^[^:]+:.+$", v):
            bad(key, "no namespace prefix")
    if Fraction(values["share_floor"]) > Fraction(values["share_ceiling"]):
        bad("share_floor", "above share_ceiling %s" % values["share_ceiling"])
    done(json.dumps({"values": values, "rung": rung}, sort_keys=True))


def cmd_closing(argv):
    done(closing_row(log_rows(text_arg(argv[0])), argv[1])["shas"][0])


def cmd_window(argv):
    text, tsv, title, size, set_at, shallow = argv[0], argv[1], argv[2], int(argv[3]), argv[4], argv[5]
    if shallow != "false":
        raise NotEvaluated("the clone is shallow; the merge history the window is read from is incomplete")
    rows = log_rows(text_arg(text))
    crow = closing_row(rows, title)
    csha = crow["shas"][0]
    hist = [ln.split("\t", 1) for ln in tsv.splitlines() if ln.strip()]
    hist = [(h[0], h[1] if len(h) > 1 else "") for h in hist]
    if not hist or hist[0][0] != csha:
        raise NotEvaluated("the first-parent list does not start at the closing merge %s" % csha[:12])
    pos = {}
    for i, (sha, _subj) in enumerate(hist):
        pos.setdefault(sha, i)
    cands = []
    for r in rows:
        if r is crow:
            continue
        on = [pos[s] for s in r["shas"] if s in pos]
        if on:
            cands.append((min(on), r))
    cands.sort(key=lambda x: x[0])
    need = size - 1
    if len(cands) < need:
        raise NotEvaluated("the release log lists %d releases merged before %s; the window needs %d"
                           % (len(cands), title, need))
    members = cands[:need]
    oldest = members[-1][0] if members else 0
    all_shas = {s for r in rows for s in r["shas"]}
    all_prs = {n for r in rows for n in r["prs"]}
    merges = 0
    for i in range(oldest + 1):
        sha, subj = hist[i]
        m = MERGE_RE.match(subj)
        if not m:
            continue
        merges += 1
        if sha not in all_shas and int(m.group(1)) not in all_prs:
            raise NotEvaluated("release merge %s (#%s, %s) precedes %s on main and has no release-log row: "
                               "the window would skip it" % (sha[:8], m.group(1), m.group(2), title))
    placed = [(0, crow)] + cands
    set_pos = None
    for p, r in placed:
        if r["milestone"] == set_at:
            set_pos = p
            break
    measured = None if set_pos is None else sum(1 for p, _r in placed if p <= set_pos)
    done(json.dumps({"releases": [title] + [r["milestone"] for _p, r in members],
                     "merges": [csha] + [hist[p][0] for p, _r in members],
                     "measured": measured,
                     "guard": {"commits": oldest + 1, "release_merges": merges}}, sort_keys=True))


def cmd_resolve(argv):
    by = {}
    for ln in argv[0].splitlines():
        if ln.strip():
            num, _sep, title = ln.partition("\t")
            by.setdefault(title, []).append(int(num))
    out = {}
    for slug in json.loads(argv[1]):
        k = len(by.get(slug, []))
        if k != 1:
            raise NotEvaluated("release %s resolves to %d milestones" % (slug, k))
        out[slug] = by[slug][0]
    done(json.dumps(out, sort_keys=True))


def cmd_member_guard(argv):
    count, limit, slug = int(argv[0]), int(argv[1]), argv[2]
    if count >= limit:
        raise NotEvaluated("membership read for %s returned %d items, the read limit; refusing a possibly "
                           "truncated count" % (slug, limit))
    done("")


def cmd_compute(argv):
    try:
        win = json.loads(argv[0])
    except ValueError:
        raise NotEvaluated("the window input is not JSON")
    p = json.loads(argv[1])
    nd = [x.strip().lower() for x in argv[2].split(",") if x.strip()]
    v = p["values"]
    size = int(v["window_releases"])
    rels = win.get("releases") if isinstance(win, dict) else None
    if not isinstance(rels, list) or len(rels) < size:
        raise NotEvaluated("the window input lists %d releases; the window needs %d"
                           % (len(rels) if isinstance(rels, list) else 0, size))
    rels = rels[:size]
    if win.get("closing") != rels[0].get("slug"):
        raise NotEvaluated("the window input does not start at its closing release %s" % win.get("closing"))
    cl, sl, bl = v["counted_label"], v["scaffolding_label"], v["bug_type_label"]
    prefix = cl.split(":", 1)[0] + ":"
    per = []
    for r in rels:
        c = {"slug": r.get("slug"), "counted": 0, "shipped": 0, "unlabelled": 0, "bug_other": 0,
             "excluded_scaffolding": 0, "excluded_not_shipped": 0}
        for mem in r.get("members", []):
            labels = [str(x) for x in mem.get("labels", [])]
            if sl in labels:
                c["excluded_scaffolding"] += 1
                continue
            if any(lb.strip().lower() in nd for lb in labels):
                c["excluded_not_shipped"] += 1
                continue
            c["shipped"] += 1
            ns = [lb for lb in labels if lb.startswith(prefix)]
            if cl in labels:
                c["counted"] += 1
            if not ns:
                c["unlabelled"] += 1
            if bl in labels and any(lb != cl for lb in ns):
                c["bug_other"] += 1
        per.append(c)
    live = [c for c in per if c["shipped"] > 0]
    if not live:
        raise NotEvaluated("no release in the window shipped an item")
    counted = sum(c["counted"] for c in per)
    shipped = sum(c["shipped"] for c in per)
    pooled = Fraction(counted, shipped)
    mean = sum((Fraction(c["counted"], c["shipped"]) for c in live), Fraction(0)) / len(live)
    judged = pooled if v["judged_on"] == "pooled" else mean
    floor, ceiling = Fraction(v["share_floor"]), Fraction(v["share_ceiling"])
    verdict = "BELOW-FLOOR" if judged < floor else ("ABOVE-CEILING" if judged > ceiling else "IN-BAND")
    rec = {"verdict": verdict, "judged_on": v["judged_on"], "values": v, "rung": p["rung"],
           "releases": per, "counted": counted, "shipped": shipped,
           "pooled": [pooled.numerator, pooled.denominator], "mean": [mean.numerator, mean.denominator],
           "not_delivered": nd}
    if "measured" in win:
        rec["measured"] = win["measured"]
    done(json.dumps(rec, sort_keys=True))


def pct(n, d):
    t = (2 * 1000 * n + d) // (2 * d)
    return "%d.%d%%" % (t // 10, t % 10)


def fpct(f):
    return pct(f.numerator, f.denominator)


def cmd_render(argv):
    src, mode, source = argv[0], argv[1], argv[2]
    mech = "compute-release-velocity.sh --quality-share"
    if src.startswith("NE "):
        reason = src[3:]
        if mode == "json":
            done(json.dumps({"verdict": "NOT-EVALUATED", "reason": reason, "mechanism": mech}, sort_keys=True))
            return
        done("#### Quality-share record\n\n```text\nquality-share: NOT-EVALUATED — %s (no reading was taken; "
             "this is not a clean result)\nmechanism: %s\n```" % (reason, mech))
        return
    r = json.loads(src)
    v, per = r["values"], r["releases"]
    pooled, mean = Fraction(*r["pooled"]), Fraction(*r["mean"])
    judged = pooled if r["judged_on"] == "pooled" else mean
    size = len(per)
    if "measured" not in r:
        meas = "n/a (offline input)"
    elif r["measured"] is None:
        meas = "n/a (set-at release %s is not on this release's merge history)" % v["values_set_at"]
    else:
        meas = "%d of %d toward the re-set" % (r["measured"], RESETS)
    indiv = [k for k in KEYS if r["rung"].get(k) == "individual"]
    prefix = v["counted_label"].split(":", 1)[0] + ":"
    if mode == "json":
        out = dict(r)
        out.update({"window_size": size, "pooled_display": fpct(pooled), "mean_display": fpct(mean),
                    "judged_display": fpct(judged), "source": source, "mechanism": mech,
                    "measured_display": meas, "individual_rung": indiv})
        done(json.dumps(out, sort_keys=True))
        return
    c0 = per[0]
    lines = ["quality-share: %s — %s %s against the band %s–%s, judged over %d releases (an advisory reading, "
             "not a close verdict)" % (r["verdict"], r["judged_on"], fpct(judged),
                                       fpct(Fraction(v["share_floor"])), fpct(Fraction(v["share_ceiling"])), size)]
    share0 = pct(c0["counted"], c0["shipped"]) if c0["shipped"] else "n/a"
    lines.append("this-release: %s · counted %d of %d shipped (%s) · unlabelled %d · bug-typed under another "
                 "initiative %d · excluded: scaffolding %d, not shipped %d"
                 % (c0["slug"], c0["counted"], c0["shipped"], share0, c0["unlabelled"], c0["bug_other"],
                    c0["excluded_scaffolding"], c0["excluded_not_shipped"]))
    pj, mj = ("judged", "reported beside, not judged") if r["judged_on"] == "pooled" else \
             ("reported beside, not judged", "judged")
    lines.append("window: pooled %d of %d (%s, %s) · mean of shares %s (%s) · releases with shipped items %d of "
                 "%d · unlabelled %d · bug-typed under another initiative %d"
                 % (r["counted"], r["shipped"], fpct(pooled), pj, fpct(mean), mj,
                    sum(1 for c in per if c["shipped"]), size, sum(c["unlabelled"] for c in per),
                    sum(c["bug_other"] for c in per)))
    for c in per:
        share = "%d of %d (%s)" % (c["counted"], c["shipped"], pct(c["counted"], c["shipped"])) \
            if c["shipped"] else "n/a (0 shipped)"
        lines.append("release %s: %s · unlabelled %d · bug-typed-other %d"
                     % (c["slug"], share, c["unlabelled"], c["bug_other"]))
    lines.append("counting-rule: counted %s · scaffolding %s excluded · bug-typed %s · unlabelled = no %s label · "
                 "shipped = carries no %s label" % (v["counted_label"], v["scaffolding_label"],
                                                    v["bug_type_label"], prefix, " or ".join(r["not_delivered"])))
    lines.append("values: [quality_share_band] floor %s · ceiling %s · window %s · judged on %s (template; "
                 "individual rung: %s) · set at %s · measured against these values: %s"
                 % (v["share_floor"], v["share_ceiling"], v["window_releases"], v["judged_on"],
                    ", ".join(indiv) if indiv else "none", v["values_set_at"], meas))
    lines.append("source: %s" % source)
    lines.append("mechanism: %s" % mech)
    done("#### Quality-share record\n\n```text\n%s\n```" % "\n".join(lines))


def cmd_window_json(argv):
    # Assemble the live window from the window reading and each release members read,
    # so the live and offline paths feed one computation. argv: title, measured, then
    # slug and members-JSON pairs, newest first.
    title, measured = argv[0], argv[1]
    rels = []
    for i in range(2, len(argv), 2):
        rels.append({"slug": argv[i], "members": json.loads(argv[i + 1])})
    done(json.dumps({"closing": title, "releases": rels,
                     "measured": None if measured == "null" else int(measured)}, sort_keys=True))


CMDS = {"params": cmd_params, "closing": cmd_closing, "window": cmd_window, "resolve": cmd_resolve,
        "member_guard": cmd_member_guard, "compute": cmd_compute, "render": cmd_render,
        "window_json": cmd_window_json}

try:
    CMDS[sys.argv[1]](sys.argv[2:])
except NotEvaluated as e:
    print("NE %s" % e)
    print("OK")
PYEOF

# _rv_qs_params — resolve the eight [quality_share_band] values on their two rungs: the
# template (rung 1) and the individual XDG file (rung 5), the individual value winning
# when non-empty, through the section-aware reader of release/tools/lib/platform-toggle.sh.
# Prints {values, rung} JSON and OK, or NE naming the key. The rung paths it names are
# written repository-relative and with the home directory as ~, so a record never
# carries an operator path.
_rv_qs_params() {
  if ! declare -F _pt_read_field >/dev/null 2>&1; then
    /usr/bin/printf 'NE release/tools/lib/platform-toggle.sh is unavailable; no rung was read\nOK\n'
    return 0
  fi
  local _root _t _i _ts _is _k
  _root="$(_pt_src_root)"
  _t="$_root/core/config/platform-config.toml.template"
  _i="$(_pt_config_file)"
  _ts="core/config/platform-config.toml.template"
  [[ -r "$_t" ]] || _ts="none"
  _is="$_i"
  # shellcheck disable=SC2088  # a literal ~ is the point: a display form, never expanded
  if [[ -n "${HOME:-}" && "$_i" == "$HOME/"* ]]; then _is="~/${_i#"$HOME"/}"; fi
  local -a _a=("$_ts" "$_is")
  for _k in counted_label scaffolding_label bug_type_label share_floor share_ceiling window_releases judged_on values_set_at; do
    _a+=("$_k" "$(_pt_read_field "$_t" quality_share_band "$_k")" "$(_pt_read_field "$_i" quality_share_band "$_k")")
  done
  /usr/bin/python3 -c "$_RV_QS_PY" params "${_a[@]}" 2>/dev/null
}
# _rv_qs_closing LOG TITLE — the closing release's merge SHA from its release-log row.
_rv_qs_closing() { /usr/bin/python3 -c "$_RV_QS_PY" closing "$@" 2>/dev/null; }
# _rv_qs_window LOG FIRST-PARENT-TSV TITLE SIZE VALUES_SET_AT SHALLOW — the window by ancestry.
_rv_qs_window() { /usr/bin/python3 -c "$_RV_QS_PY" window "$@" 2>/dev/null; }
# _rv_qs_resolve MILESTONE-TSV SLUGS-JSON — each slug's milestone number, by exact title.
_rv_qs_resolve() { /usr/bin/python3 -c "$_RV_QS_PY" resolve "$@" 2>/dev/null; }
# _rv_qs_member_guard COUNT LIMIT SLUG — refuse a membership read that hit its own limit.
_rv_qs_member_guard() { /usr/bin/python3 -c "$_RV_QS_PY" member_guard "$@" 2>/dev/null; }
# _rv_qs_compute WINDOW-JSON PARAMS-JSON NOT-DELIVERED — the reading, as a record.
_rv_qs_compute() { /usr/bin/python3 -c "$_RV_QS_PY" compute "$@" 2>/dev/null; }
# _rv_qs_render RECORD-JSON-OR-NE human|json SOURCE — the record; never a share on NE.
_rv_qs_render() { /usr/bin/python3 -c "$_RV_QS_PY" render "$@" 2>/dev/null; }

# _rv_qs_take STEP OUTPUT — strip a function result of its OK sentinel. Sets the GLOBALS
# _QS_BODY (the result) and _QS_NE (a NOT-EVALUATED reason), not stdout, for the reason
# recorded at resolve_declared_kinds. Returns 0 on a result, 3 on an NE line, and 4 when
# the sentinel is missing (the pass crashed), with _QS_NE naming the step.
_rv_qs_take() {
  _QS_BODY=""; _QS_NE=""
  if [[ "$2" == "OK" ]]; then return 0; fi
  if [[ "$2" != *$'\n'OK ]]; then
    _QS_NE="the quality-share step $1 did not complete (no OK sentinel)"
    return 4
  fi
  _QS_BODY="${2%$'\n'OK}"
  if [[ "$_QS_BODY" == "NE "* ]]; then _QS_NE="${_QS_BODY#NE }"; _QS_BODY=""; return 3; fi
  return 0
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

  # Test CR: the per-release cost row (--cost-row), offline over inline fixtures. The
  # arms build transcript trees under a temp directory, run the REAL extractor over a
  # scratch store and the REAL conversion with both of its rung seams pinned (so no
  # operator configuration, store, home or transcript is read), and assert the row:
  # CR-1 multi-hub, CR-2 killed-spoke, CR-3 symlink alias, CR-4 fabricated slug, CR-5
  # absent field, CR-6 minimum schema, CR-7 shared ids and the subset rule, CR-8
  # CIAC-3 both-bracket-ends, CR-9 the cost-unit record's bracket rule, CR-10 the home
  # guard, CR-11 re-run containment, CR-12 the summary line, CR-13 store parity, and
  # an unresolved unit (exit 4). jq is a dependency of both subprocesses.
  _cr_jq="$(find_jq)"
  [[ -n "$_cr_jq" ]] || die "self-test CR: jq not found (looked in /usr/bin, /opt/homebrew/bin, /usr/local/bin, ~/.local/bin) — the cost row's extractor and conversion need it"
  _cr_rc=0
  /usr/bin/python3 -c "$_RV_COST_ROW_PY" --self-test --repo-root "$REPO_ROOT" \
    --jq-dir "$(/usr/bin/dirname "$_cr_jq")" --min-store-schema "$COST_ROW_MIN_STORE_SCHEMA" || _cr_rc=$?
  [[ "$_cr_rc" -eq 0 ]] || die "self-test CR: the cost-row arms failed (exit $_cr_rc) — see the FAIL lines above"

  # Test QS: the quality-share reading (--quality-share), offline. Every arm is hermetic:
  # PMO_SRC_ROOT points the template rung at a temporary tree whose template carries the
  # [quality_share_band] section with the values the band was set with, and
  # PMO_PLATFORM_CONFIG_ROOT points the individual rung at a directory the arm controls,
  # so no arm reads the operator's configuration and the arms hold across a later re-set
  # of the shipped values. The fixtures are read from tests/fixtures/quality-share/. No
  # arm touches gh, git or the network. QS-1 to QS-10 run the real command line in its
  # offline form; QS-11 and QS-12 call the functions its live form runs. Every failure
  # prints the observed value beside the expected one, and every arm runs before the
  # group reports, so a mutation proof can quote the arm it turned red.
  # QS-1 seeded red · QS-2 near-miss with its one-variable control · QS-3 the mean
  # triggers nothing and judged_on is read · QS-4 exclusions and the counts beside ·
  # QS-5 the floor edge · QS-6 the mean computed exactly · QS-7 the verdict is exact and
  # the display is not · QS-8 empty releases · QS-9 fail closed · QS-10 rung precedence
  # and section awareness · QS-11 the window by ancestry and its guard · QS-12 the
  # resolver, the membership guard and the closing row.
  _qs_n=0
  _qs_fail() { echo "  FAIL: $1 — expected: $2 · observed: $3" >&2; _qs_n=$((_qs_n + 1)); return 0; }
  _qs_fx="$SCRIPT_DIR/tests/fixtures/quality-share"
  _qs_tmp="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/rv-selftest-qs-XXXXXX")" \
    || die "self-test QS: could not create the hermetic tree — the quality-share arms did not run, which is a FAIL, not a skip"
  /bin/mkdir -p "$_qs_tmp/src/core/config" "$_qs_tmp/cfg-empty" "$_qs_tmp/cfg-band" "$_qs_tmp/cfg-other"
  _qs_tpl="$_qs_tmp/src/core/config/platform-config.toml.template"
  # _qs_tmpl [KEY=VALUE | KEY]... — write the hermetic template: the band as set, with
  # KEY=VALUE replacing a line and a bare KEY dropping it.
  _qs_tmpl() {
    local _l _k _o _out=""
    for _l in 'counted_label = "project:platform-quality"' 'scaffolding_label = "sub-task"' \
              'bug_type_label = "type:bug"' 'share_floor = 0.15' 'share_ceiling = 0.35' \
              'window_releases = 5' 'judged_on = "pooled"' 'values_set_at = "obligation-runners-declared"'; do
      _k="${_l%% *}"
      for _o in "$@"; do
        if [[ "$_o" == "$_k" ]]; then _l=""; elif [[ "$_o" == "$_k="* ]]; then _l="$_k = ${_o#*=}"; fi
      done
      if [[ -n "$_l" ]]; then _out="${_out}${_l}"$'\n'; fi
    done
    /usr/bin/printf '[quality_share_band]\n%s' "$_out" > "$_qs_tpl"
    return 0
  }
  # _qs_cli CFG-ROOT ARGS... — the real command line, hermetic, run from the repo root.
  _qs_cli() {
    local _c="$1"; shift
    ( cd "$REPO_ROOT" && PMO_SRC_ROOT="$_qs_tmp/src" PMO_PLATFORM_CONFIG_ROOT="$_c" \
        "${BASH:-/bin/bash}" "$SCRIPT_DIR/compute-release-velocity.sh" "$@" 2>&1 )
  }
  # _qs_line OUTPUT PREFIX — the first line of OUTPUT that starts with PREFIX.
  _qs_line() {
    local _l
    while IFS= read -r _l; do
      if [[ "$_l" == "$2"* ]]; then /usr/bin/printf '%s' "$_l"; return 0; fi
    done <<< "$1"
    return 0
  }
  # _qs_win "C/S ..." FILE — write a window, newest first: per release, C counted of S shipped.
  _qs_win() {
    /usr/bin/python3 -c 'import json, sys
rels = []
for i, cs in enumerate(sys.argv[1].split()):
    c, s = (int(x) for x in cs.split("/"))
    ms = [{"number": i * 10000 + j, "labels": ["project:platform-quality" if j < c else "project:other"]} for j in range(s)]
    rels.append({"slug": "qs-release-%d" % (i + 1), "members": ms})
json.dump({"closing": rels[0]["slug"], "releases": rels}, open(sys.argv[2], "w"))' "$1" "$2"
  }
  _qs_rel="release/tools/tests/fixtures/quality-share"

  # QS-1: the seeded red, through the real command line — and the record byte for byte.
  _qs_tmpl
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_rel/out-of-band.json")" || _qs_rc=$?
  _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"
  [[ "$_qs_rc" -eq 0 && "$_qs_v" == "quality-share: ABOVE-CEILING — pooled 40.0%"* ]] \
    || _qs_fail "QS-1 seeded red" "exit 0, quality-share: ABOVE-CEILING — pooled 40.0%" "exit $_qs_rc, $_qs_v"
  _qs_w="$(_qs_line "$_qs_o" "window: ")"
  [[ "$_qs_w" == *"pooled 8 of 20 (40.0%, judged)"* ]] || _qs_fail "QS-1 window" "pooled 8 of 20 (40.0%, judged)" "$_qs_w"
  read -r -d '' _qs_want <<'QSEOF' || true
#### Quality-share record

```text
quality-share: ABOVE-CEILING — pooled 40.0% against the band 15.0%–35.0%, judged over 5 releases (an advisory reading, not a close verdict)
this-release: fixture-release-5 · counted 2 of 4 shipped (50.0%) · unlabelled 1 · bug-typed under another initiative 1 · excluded: scaffolding 1, not shipped 1
window: pooled 8 of 20 (40.0%, judged) · mean of shares 40.0% (reported beside, not judged) · releases with shipped items 5 of 5 · unlabelled 1 · bug-typed under another initiative 1
release fixture-release-5: 2 of 4 (50.0%) · unlabelled 1 · bug-typed-other 1
release fixture-release-4: 2 of 4 (50.0%) · unlabelled 0 · bug-typed-other 0
release fixture-release-3: 1 of 4 (25.0%) · unlabelled 0 · bug-typed-other 0
release fixture-release-2: 2 of 4 (50.0%) · unlabelled 0 · bug-typed-other 0
release fixture-release-1: 1 of 4 (25.0%) · unlabelled 0 · bug-typed-other 0
counting-rule: counted project:platform-quality · scaffolding sub-task excluded · bug-typed type:bug · unlabelled = no project: label · shipped = carries no status: deferred or status: rejected label
values: [quality_share_band] floor 0.15 · ceiling 0.35 · window 5 · judged on pooled (template; individual rung: none) · set at obligation-runners-declared · measured against these values: n/a (offline input)
source: --window-json release/tools/tests/fixtures/quality-share/out-of-band.json
mechanism: compute-release-velocity.sh --quality-share
```
QSEOF
  [[ "$_qs_o" == "$_qs_want" ]] || _qs_fail "QS-1 record" "the record of release-velocity-tracking.md section 7b, byte for byte" "$_qs_o"

  # QS-4: the exclusions, and the counts reported beside the share (the same reading).
  _qs_t="$(_qs_line "$_qs_o" "this-release: ")"
  for _qs_x in "counted 2 of 4" "unlabelled 1" "bug-typed under another initiative 1" "excluded: scaffolding 1, not shipped 1"; do
    [[ "$_qs_t" == *"$_qs_x"* ]] || _qs_fail "QS-4 exclusions" "$_qs_x" "$_qs_t"
  done

  # QS-2: the near-miss, exactly at the ceiling, stays silent; and the two files differ
  # in one variable only.
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_rel/boundary-near-miss.json")" || _qs_rc=$?
  _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"
  [[ "$_qs_rc" -eq 0 && "$_qs_v" == "quality-share: IN-BAND — pooled 35.0%"* ]] \
    || _qs_fail "QS-2 near-miss" "exit 0, quality-share: IN-BAND — pooled 35.0%" "exit $_qs_rc, $_qs_v"
  _qs_w="$(_qs_line "$_qs_o" "window: ")"
  [[ "$_qs_w" == *"pooled 7 of 20 (35.0%, judged)"* ]] || _qs_fail "QS-2 window" "pooled 7 of 20 (35.0%, judged)" "$_qs_w"
  _qs_d="$(/usr/bin/python3 -c 'import json, sys
a, b = (json.load(open(p)) for p in sys.argv[1:3])
fl = lambda d: {(r["slug"], m["number"]): set(m["labels"]) for r in d["releases"] for m in r["members"]}
fa, fb = fl(a), fl(b)
diff = sorted(k for k in set(fa) | set(fb) if fa.get(k) != fb.get(k))
print(len(diff), ",".join(str(k[1]) for k in diff), sum(len(fa.get(k, set()) ^ fb.get(k, set())) for k in diff))' \
    "$_qs_fx/out-of-band.json" "$_qs_fx/boundary-near-miss.json" 2>&1)"
  [[ "$_qs_d" == "1 401 2" ]] || _qs_fail "QS-2 one-variable control" "1 401 2 (one member, 401, with one label swapped)" "$_qs_d"

  # QS-3: the mean triggers nothing under pooled, and judged_on is read.
  _qs_win "1/1 1/1 0/4 0/4 1/4" "$_qs_tmp/w3.json"
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_tmp/w3.json")" || _qs_rc=$?
  _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"; _qs_w="$(_qs_line "$_qs_o" "window: ")"
  [[ "$_qs_v" == "quality-share: IN-BAND — pooled 21.4%"* ]] || _qs_fail "QS-3 pooled" "quality-share: IN-BAND — pooled 21.4%" "$_qs_v"
  [[ "$_qs_w" == *"mean of shares 45.0% (reported beside, not judged)"* ]] || _qs_fail "QS-3 mean beside" "mean of shares 45.0% (reported beside, not judged)" "$_qs_w"
  _qs_tmpl 'judged_on="mean-of-shares"'
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_tmp/w3.json")" || _qs_rc=$?
  _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"
  [[ "$_qs_v" == "quality-share: ABOVE-CEILING — mean-of-shares 45.0%"* ]] || _qs_fail "QS-3 judged_on read" "quality-share: ABOVE-CEILING — mean-of-shares 45.0%" "$_qs_v"
  _qs_tmpl

  # QS-5: the floor edge — one step below it, then exactly at it.
  for _qs_x in "0/4 0/4 0/4 1/4 1/4|BELOW-FLOOR — pooled 10.0%" "1/4 0/4 0/4 1/4 1/4|IN-BAND — pooled 15.0%"; do
    _qs_win "${_qs_x%%|*}" "$_qs_tmp/w5.json"
    _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_tmp/w5.json")" || _qs_rc=$?
    _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"
    [[ "$_qs_v" == "quality-share: ${_qs_x#*|}"* ]] || _qs_fail "QS-5 floor edge" "quality-share: ${_qs_x#*|}" "$_qs_v"
  done

  # QS-6: the mean computed exactly, over the live v5.03 window's shape.
  _qs_win "0/4 0/1 1/2 1/1 1/4" "$_qs_tmp/w6.json"
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_tmp/w6.json")" || _qs_rc=$?
  _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"; _qs_w="$(_qs_line "$_qs_o" "window: ")"
  [[ "$_qs_w" == *"pooled 3 of 12 (25.0%, judged) · mean of shares 35.0%"* ]] || _qs_fail "QS-6 mean exact" "pooled 3 of 12 (25.0%, judged) · mean of shares 35.0%" "$_qs_w"
  [[ "$_qs_v" == "quality-share: IN-BAND — pooled 25.0%"* ]] || _qs_fail "QS-6 verdict" "quality-share: IN-BAND — pooled 25.0%" "$_qs_v"

  # QS-7: the verdict is taken from the exact fraction, never the display: 876/2500 and
  # 875/2500 (3504/10000 and 3500/10000) both display 35.0%.
  for _qs_x in "176/500 175/500 175/500 175/500 175/500|ABOVE-CEILING — pooled 35.0%" "175/500 175/500 175/500 175/500 175/500|IN-BAND — pooled 35.0%"; do
    _qs_win "${_qs_x%%|*}" "$_qs_tmp/w7.json"
    _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_tmp/w7.json")" || _qs_rc=$?
    _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"
    [[ "$_qs_v" == "quality-share: ${_qs_x#*|}"* ]] || _qs_fail "QS-7 exact verdict" "quality-share: ${_qs_x#*|}" "$_qs_v"
  done

  # QS-8: a release that shipped nothing, then a window that shipped nothing.
  _qs_win "4/4 0/0 1/4 1/4 1/4" "$_qs_tmp/w8.json"
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_tmp/w8.json")" || _qs_rc=$?
  _qs_r="$(_qs_line "$_qs_o" "release qs-release-2: ")"; _qs_w="$(_qs_line "$_qs_o" "window: ")"
  [[ "$_qs_r" == "release qs-release-2: n/a (0 shipped)"* ]] || _qs_fail "QS-8 empty release" "release qs-release-2: n/a (0 shipped)" "$_qs_r"
  [[ "$_qs_w" == *"releases with shipped items 4 of 5"* ]] || _qs_fail "QS-8 empty release counted" "releases with shipped items 4 of 5" "$_qs_w"
  _qs_win "0/0 0/0 0/0 0/0 0/0" "$_qs_tmp/w8.json"
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_tmp/w8.json")" || _qs_rc=$?
  _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"
  [[ "$_qs_rc" -eq 3 && "$_qs_v" == "quality-share: NOT-EVALUATED — no release in the window shipped an item"* && "$_qs_o" != *"%"* ]] \
    || _qs_fail "QS-8 empty window" "exit 3, NOT-EVALUATED — no release in the window shipped an item, and no %" "exit $_qs_rc, $_qs_o"

  # QS-9: fail closed — each malformed band value is NOT-EVALUATED, naming its key; the
  # conforming template is the control, read above (QS-1, exit 0).
  for _qs_x in "share_ceiling|share_ceiling|" "share_ceiling=1.5|share_ceiling|" "share_floor=0.40|share_floor|" \
               'judged_on="median"|judged_on|' "window_releases=0|window_releases|" \
               'counted_label="platform-quality"|counted_label|— no namespace prefix'; do
    _qs_p="${_qs_x%%|*}"; _qs_k="${_qs_x#*|}"; _qs_k="${_qs_k%%|*}"; _qs_m="${_qs_x##*|}"
    _qs_tmpl "$_qs_p"
    _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-empty" v0.00 --quality-share --window-json "$_qs_rel/out-of-band.json")" || _qs_rc=$?
    _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"
    [[ "$_qs_rc" -eq 3 && "$_qs_v" == "quality-share: NOT-EVALUATED — [quality_share_band].${_qs_k} "* && "$_qs_v" == *"$_qs_m"* ]] \
      || _qs_fail "QS-9 fail closed ($_qs_p)" "exit 3, NOT-EVALUATED — [quality_share_band].${_qs_k} …${_qs_m:+ $_qs_m}" "exit $_qs_rc, $_qs_v"
  done
  _qs_tmpl

  # QS-10: the individual rung wins, read only from its own [quality_share_band] section.
  /usr/bin/printf '[quality_share_band]\nshare_ceiling = 0.45\n' > "$_qs_tmp/cfg-band/platform-config.toml"
  /usr/bin/printf '[other]\nshare_ceiling = 0.10\n' > "$_qs_tmp/cfg-other/platform-config.toml"
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-band" v0.00 --quality-share --window-json "$_qs_rel/out-of-band.json")" || _qs_rc=$?
  _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"; _qs_r="$(_qs_line "$_qs_o" "values: ")"
  [[ "$_qs_v" == "quality-share: IN-BAND — pooled 40.0%"* && "$_qs_r" == *"individual rung: share_ceiling"* ]] \
    || _qs_fail "QS-10 rung precedence" "IN-BAND — pooled 40.0% with individual rung: share_ceiling" "$_qs_v / $_qs_r"
  _qs_rc=0; _qs_o="$(_qs_cli "$_qs_tmp/cfg-other" v0.00 --quality-share --window-json "$_qs_rel/out-of-band.json")" || _qs_rc=$?
  _qs_v="$(_qs_line "$_qs_o" "quality-share: ")"; _qs_r="$(_qs_line "$_qs_o" "values: ")"
  [[ "$_qs_v" == "quality-share: ABOVE-CEILING — pooled 40.0%"* && "$_qs_r" == *"individual rung: none"* ]] \
    || _qs_fail "QS-10 section awareness" "ABOVE-CEILING — pooled 40.0% with individual rung: none" "$_qs_v / $_qs_r"

  # QS-11: the window, by first-parent ancestry, and its completeness guard. Synthetic
  # SHAs are one hex digit repeated: x = 0..., y = 9..., z = 5.... The log lists its rows
  # out of merge order, with x (merged after a) appended before a.
  _qs_s() { local _h="$1$1$1$1$1$1$1$1"; /usr/bin/printf '%s' "$_h$_h$_h$_h$_h"; }
  _qs_row() { /usr/bin/printf '| v%s | %s | #1 | %s | `%s` | `v%s` | VERIFIED | 2026-01-01 |\n' "$1" "$1" "$2" "$(_qs_s "$3")" "$1"; }
  _qs_hdr='| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |'$'\n''|---|---|---|---|---|---|---|---|'
  _qs_rf="$(_qs_row f '#16' f)"; _qs_re="$(_qs_row e '#15' e)"; _qs_rcc="$(_qs_row c '#13' c)"
  _qs_rd="$(_qs_row d '#14, #41' d)"; _qs_rb="$(_qs_row b '#12' b)"; _qs_rx="$(_qs_row x '#99' 0)"; _qs_ra="$(_qs_row a '#10' a)"
  _qs_log="$_qs_hdr"$'\n'"$_qs_rf"$'\n'"$_qs_re"$'\n'"$_qs_rcc"$'\n'"$_qs_rd"$'\n'"$_qs_rb"$'\n'"$_qs_rx"$'\n'"$_qs_ra"
  _qs_fp=""
  for _qs_x in "a 10 release/a" "9 11 chore/y" "b 12 release/b" "c 13 release/c" "5 41 release/d-part" "d 14 release/d" "e 15 release/e" "f 16 release/f"; do
    set -- $_qs_x
    _qs_fp="${_qs_fp}$(_qs_s "$1")"$'\t'"Merge pull request #$2 from o/$3"$'\n'
  done
  _qs_fp="${_qs_fp%$'\n'}"
  # _qs_call EXPECT-LABEL FN ARGS... — run one function and take its result.
  _qs_call() {
    local _lab="$1" _fn="$2"; shift 2
    _qs_rc=0; _qs_o="$("$_fn" "$@")" || _qs_rc=$?
    _QS_BODY=""; _QS_NE=""; _qs_tk=0; _rv_qs_take "$_fn" "$_qs_o" || _qs_tk=$?
    return 0
  }
  # (a) and (b): the window is a b c d e, x is absent, and y is a silent chore merge.
  _qs_call "QS-11 (a)" _rv_qs_window "$_qs_log" "$_qs_fp" a 5 a false
  [[ "$_qs_tk" -eq 0 && "$_QS_BODY" == *'"releases": ["a", "b", "c", "d", "e"]'* ]] \
    || _qs_fail "QS-11 (a) window" '"releases": ["a", "b", "c", "d", "e"]' "take $_qs_tk: ${_QS_BODY:-$_QS_NE}"
  [[ "$_QS_BODY" == *'"guard": {"commits": 7, "release_merges": 6}'* ]] \
    || _qs_fail "QS-11 (a) guard" '"guard": {"commits": 7, "release_merges": 6}' "${_QS_BODY:-$_QS_NE}"
  [[ "$_QS_BODY" != *'"x"'* ]] || _qs_fail "QS-11 (b) merged after" "x absent from the window" "$_QS_BODY"
  # (c): with c's row deleted, the guard names c's merge.
  _qs_call "QS-11 (c)" _rv_qs_window "$_qs_hdr"$'\n'"$_qs_rf"$'\n'"$_qs_re"$'\n'"$_qs_rd"$'\n'"$_qs_rb"$'\n'"$_qs_rx"$'\n'"$_qs_ra" "$_qs_fp" a 5 a false
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "release merge cccccccc (#13, release/c) precedes a on main and has no release-log row: the window would skip it" ]] \
    || _qs_fail "QS-11 (c) guard red" "release merge cccccccc (#13, release/c) precedes a on main and has no release-log row: the window would skip it" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  # (d): z (#41, no SHA in any row) is accounted for by d's Release PR cell; its firing
  # control drops #41 from that cell.
  _qs_call "QS-11 (d)" _rv_qs_window "$_qs_hdr"$'\n'"$_qs_rf"$'\n'"$_qs_re"$'\n'"$_qs_rcc"$'\n'"$(_qs_row d '#14' d)"$'\n'"$_qs_rb"$'\n'"$_qs_rx"$'\n'"$_qs_ra" "$_qs_fp" a 5 a false
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "release merge 55555555 (#41, release/d-part) precedes a"* ]] \
    || _qs_fail "QS-11 (d) PR-cell control" "release merge 55555555 (#41, release/d-part) precedes a …" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  # (e): a window larger than the history the log can fill.
  _qs_call "QS-11 (e)" _rv_qs_window "$_qs_log" "$_qs_fp" a 7 a false
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "the release log lists 5 releases merged before a; the window needs 6" ]] \
    || _qs_fail "QS-11 (e) short window" "the release log lists 5 releases merged before a; the window needs 6" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  # (f): how many releases have been measured against the values, from values_set_at.
  for _qs_x in "a|1" "c|3" "x|null"; do
    _qs_call "QS-11 (f)" _rv_qs_window "$_qs_log" "$_qs_fp" a 5 "${_qs_x%%|*}" false
    [[ "$_QS_BODY" == *"\"measured\": ${_qs_x#*|},"* ]] || _qs_fail "QS-11 (f) measured from ${_qs_x%%|*}" "\"measured\": ${_qs_x#*|}" "${_QS_BODY:-$_QS_NE}"
  done
  # (g): a shallow clone; (h): a list that does not start at the closing merge.
  _qs_call "QS-11 (g)" _rv_qs_window "$_qs_log" "$_qs_fp" a 5 a true
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "the clone is shallow"* ]] || _qs_fail "QS-11 (g) shallow" "the clone is shallow …" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  _qs_call "QS-11 (h)" _rv_qs_window "$_qs_log" "${_qs_fp#*$'\n'}" a 5 a false
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "the first-parent list does not start at the closing merge aaaaaaaaaaaa" ]] \
    || _qs_fail "QS-11 (h) anchor" "the first-parent list does not start at the closing merge aaaaaaaaaaaa" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"

  # QS-12: the milestone resolver, the membership guard and the closing row.
  _qs_ms=$'7\ta\n8\tb\n9\tb'
  _qs_call "QS-12 resolve" _rv_qs_resolve "$_qs_ms" '["a"]'
  [[ "$_qs_tk" -eq 0 && "$_QS_BODY" == '{"a": 7}' ]] || _qs_fail "QS-12 resolve one" '{"a": 7}' "take $_qs_tk: ${_QS_BODY:-$_QS_NE}"
  _qs_call "QS-12 resolve" _rv_qs_resolve "$_qs_ms" '["zz"]'
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "release zz resolves to 0 milestones" ]] || _qs_fail "QS-12 resolve none" "release zz resolves to 0 milestones" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  _qs_call "QS-12 resolve" _rv_qs_resolve "$_qs_ms" '["b"]'
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "release b resolves to 2 milestones" ]] || _qs_fail "QS-12 resolve two" "release b resolves to 2 milestones" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  _qs_call "QS-12 guard" _rv_qs_member_guard 499 500 s
  [[ "$_qs_tk" -eq 0 && "$_qs_o" == "OK" ]] || _qs_fail "QS-12 guard under the limit" "OK" "take $_qs_tk: $_qs_o"
  _qs_call "QS-12 guard" _rv_qs_member_guard 500 500 s
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "membership read for s returned 500 items, the read limit; refusing a possibly truncated count" ]] \
    || _qs_fail "QS-12 guard at the limit" "membership read for s returned 500 items, the read limit; refusing a possibly truncated count" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  _qs_call "QS-12 closing" _rv_qs_closing "$_qs_log" a
  [[ "$_qs_tk" -eq 0 && "$_QS_BODY" == "$(_qs_s a)" ]] || _qs_fail "QS-12 closing present" "$(_qs_s a)" "take $_qs_tk: ${_QS_BODY:-$_QS_NE}"
  _qs_call "QS-12 closing" _rv_qs_closing "$_qs_log" q
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "the release log has no row for q (its Stage 12 row has not landed)" ]] \
    || _qs_fail "QS-12 closing absent" "the release log has no row for q (its Stage 12 row has not landed)" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  _qs_call "QS-12 closing" _rv_qs_closing "$_qs_log"$'\n'"$_qs_ra" a
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "2 release-log rows name a" ]] || _qs_fail "QS-12 closing twice" "2 release-log rows name a" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  _qs_call "QS-12 closing" _rv_qs_closing "$_qs_hdr"$'\n''| va | a | #1 | #10 | `'"$(_qs_s a)"'` `'"$(_qs_s b)"'` | `va` | VERIFIED | 2026-01-01 |' a
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "the release-log row for a carries 2 merge SHAs; the window anchor is ambiguous" ]] \
    || _qs_fail "QS-12 closing two SHAs" "the release-log row for a carries 2 merge SHAs; the window anchor is ambiguous" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"
  _qs_call "QS-12 closing" _rv_qs_closing '| Version | Milestone | Issues | Release PR | Commit | Tag | State | Date |'$'\n'"$_qs_ra" a
  [[ "$_qs_tk" -eq 3 && "$_QS_NE" == "the release-log header lacks Merge SHA" ]] || _qs_fail "QS-12 closing header" "the release-log header lacks Merge SHA" "take $_qs_tk: ${_QS_NE:-$_QS_BODY}"

  /bin/rm -rf "$_qs_tmp"
  [[ "$_qs_n" -eq 0 ]] || die "self-test QS: $_qs_n quality-share check(s) failed — see the FAIL lines above"

  echo "self-test: PASS"
  echo "  quality-share (QS-1..QS-12) validated offline, hermetic: seeded red byte for byte / near-miss at the ceiling with its one-variable control / the mean triggers nothing and judged_on is read / exclusions and the counts beside / floor edge / exact mean / exact verdict, rounded display / empty releases / fail closed on six malformed values / rung precedence and section awareness / the window by ancestry with its guard, its PR-cell control and its anchors / resolver, membership guard and closing row"
  echo "  cost-row (CR-1..CR-13 + unresolved unit) validated offline: multi-hub cell set + conservation / killed-spoke lower bound with a decoy harness total / symlink alias / fabricated slug refused / absent field not evaluated / minimum schema refused / subset rule + shared-id degrade / CIAC-3 both-bracket-ends / the cost-unit record's bracket rule with near-misses and a vacuity control / home guard / re-run containment / summary leak / fresh-vs-injected store parity"
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
COST_ROW=0              # --cost-row: the per-release cost row instead of the field
CR_OUT_DIR=""
CR_STORE=""
CR_SOURCE_ROOT=""
CR_SINCE=""
CR_FORCE=0
CR_HUB_ARGS=()          # repeated --hub-session <stem>, kept as engine arguments
CR_FLAGS_SEEN=""        # any cost-row-only flag given, for the without---cost-row refusal
QUALITY_SHARE=0         # --quality-share: the quality-share reading instead of the field
QS_WINDOW_JSON=""       # --window-json <file>: the offline window input
QS_WINDOW_SEEN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --milestone) MILESTONE="${2:-}"; shift 2 ;;
    --merge-sha) MERGE_SHA="${2:-}"; shift 2 ;;
    --base) BASE_REF="${2:-}"; shift 2 ;;
    --json) OUTPUT_FORMAT="json"; shift ;;
    --cost-row) COST_ROW=1; shift ;;
    --quality-share) QUALITY_SHARE=1; shift ;;
    --window-json) QS_WINDOW_JSON="${2:-}"; QS_WINDOW_SEEN=1; shift 2 ;;
    --out-dir) CR_OUT_DIR="${2:-}"; CR_FLAGS_SEEN="--out-dir"; shift 2 ;;
    --store) CR_STORE="${2:-}"; CR_FLAGS_SEEN="--store"; shift 2 ;;
    --source-root) CR_SOURCE_ROOT="${2:-}"; CR_FLAGS_SEEN="--source-root"; shift 2 ;;
    --since) CR_SINCE="${2:-}"; CR_FLAGS_SEEN="--since"; shift 2 ;;
    --hub-session) CR_HUB_ARGS+=(--hub-session "${2:-}"); CR_FLAGS_SEEN="--hub-session"; shift 2 ;;
    --force) CR_FORCE=1; CR_FLAGS_SEEN="--force"; shift ;;
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
# The quality-share reading's own argument rules, settled before the field's
# --milestone requirement, because its offline form (--window-json) takes no milestone.
if [[ "$QUALITY_SHARE" -eq 0 && "$QS_WINDOW_SEEN" -eq 1 ]]; then
  die "--window-json applies only with --quality-share"
fi
if [[ "$QUALITY_SHARE" -eq 1 ]]; then
  if [[ "$COST_ROW" -eq 1 || -n "$MERGE_SHA" || -n "$BASE_REF" || -n "$CR_FLAGS_SEEN" ]]; then
    die "--quality-share takes none of --cost-row, --merge-sha, --base or a cost-row flag: --merge-sha and --base apply only to the field, and the others only to the cost row"
  fi
  if [[ "$QS_WINDOW_SEEN" -eq 1 && -z "$QS_WINDOW_JSON" ]]; then
    die "--window-json needs a file: the window input"
  fi
  if [[ -z "$QS_WINDOW_JSON" && -z "$MILESTONE" ]]; then
    die "Required with --quality-share: --milestone <N> (the closing release's milestone number), or --window-json <file>"
  fi
fi
[[ -z "$MILESTONE" && -z "$QS_WINDOW_JSON" ]] && die "Required: --milestone <N> (the bundle's GitHub milestone number)"
if [[ "$COST_ROW" -eq 0 && -n "$CR_FLAGS_SEEN" ]]; then
  die "$CR_FLAGS_SEEN applies only with --cost-row"
fi
if [[ "$COST_ROW" -eq 1 ]]; then
  [[ "$OUTPUT_FORMAT" == "json" ]] && die "--json does not apply to --cost-row (the row itself is the JSON record)"
  [[ -n "$CR_OUT_DIR" ]] || die "Required with --cost-row: --out-dir <dir> (the row home; the row lands at <dir>/release-cost/<slug>.json)"
fi

# ─── The quality-share reading (--quality-share) ─────────────────────────────
#
# A separate mode, dispatched here, before the field path resolves gh, so neither the
# offline input nor a missing gh reaches the field's generic exit 1. Offline
# (--window-json) and live readings feed ONE computation: _rv_qs_compute over a window
# JSON. Exit 0 on a reading, inside the band or not; exit 3 on NOT-EVALUATED, with the
# record printed to stdout first; exit 1 is left to the argument checks above.
#
# The reads of the clone (the merge commit's presence, the shallow flag), the
# membership reads and the counted-label check run only here, so the self-test does not
# reach them; release-velocity-tracking.md section 7b states that bound.
if [[ "$QUALITY_SHARE" -eq 1 ]]; then
  # _rv_qs_ne REASON — print the NOT-EVALUATED record for REASON and exit 3. When the
  # renderer itself cannot run, the two-line record is written here, by hand.
  _rv_qs_ne() {
    local _ro _rc=0
    _ro="$(_rv_qs_render "NE $1" "$OUTPUT_FORMAT" "")" || true
    _rv_qs_take render "$_ro" || _rc=$?
    if [[ "$_rc" -eq 0 ]]; then
      /usr/bin/printf '%s\n' "$_QS_BODY"
    else
      /usr/bin/printf '#### Quality-share record\n\n```text\nquality-share: NOT-EVALUATED — %s (no reading was taken; this is not a clean result)\nmechanism: compute-release-velocity.sh --quality-share\n```\n' "$1"
    fi
    exit 3
  }
  # _rv_qs_val KEY — one resolved band value from the params JSON.
  _rv_qs_val() {
    /usr/bin/python3 -c 'import json, sys; print(json.loads(sys.argv[1])["values"][sys.argv[2]])' "$QS_PARAMS" "$1"
  }

  _qs_o="$(_rv_qs_params)" || true
  _rv_qs_take params "$_qs_o" || _rv_qs_ne "$_QS_NE"
  QS_PARAMS="$_QS_BODY"

  if [[ -n "$QS_WINDOW_JSON" ]]; then
    [[ -r "$QS_WINDOW_JSON" ]] || _rv_qs_ne "the window file $QS_WINDOW_JSON is not readable"
    QS_WINDOW="$(< "$QS_WINDOW_JSON")"
    QS_SOURCE="--window-json $QS_WINDOW_JSON"
  else
    GH="$(find_gh)"
    [[ -n "$GH" ]] || _rv_qs_ne "gh unavailable"
    REPO="${REPO:-$("$GH" repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
    [[ -n "$REPO" ]] || _rv_qs_ne "the target repository could not be resolved (set REPO or run inside a gh-authenticated repo)"
    MS_JSON="$("$GH" api "repos/$REPO/milestones/$MILESTONE" 2>/dev/null || true)"
    MS_TITLE=""
    if [[ -n "$MS_JSON" ]]; then
      MS_TITLE="$(/usr/bin/python3 -c 'import json,sys
try: print(json.loads(sys.argv[1]).get("title") or "")
except Exception: print("")' "$MS_JSON" 2>/dev/null || true)"
    fi
    [[ -n "$MS_TITLE" ]] || _rv_qs_ne "milestone $MILESTONE does not resolve to a title"

    QS_LOG="$REPO_ROOT/release/releases/RELEASE_LOG.md"
    [[ -r "$QS_LOG" ]] || _rv_qs_ne "release/releases/RELEASE_LOG.md is not readable"
    _qs_o="$(_rv_qs_closing - "$MS_TITLE" < "$QS_LOG")" || true
    _rv_qs_take closing "$_qs_o" || _rv_qs_ne "$_QS_NE"
    QS_SHA="$_QS_BODY"
    git -C "$REPO_ROOT" cat-file -e "${QS_SHA}^{commit}" 2>/dev/null \
      || _rv_qs_ne "the closing merge ${QS_SHA:0:12} is not in this clone; fetch origin main"
    QS_SHALLOW="$(git -C "$REPO_ROOT" rev-parse --is-shallow-repository 2>/dev/null || true)"
    [[ "$QS_SHALLOW" == "true" || "$QS_SHALLOW" == "false" ]] || _rv_qs_ne "whether this clone is shallow could not be read"
    QS_FP="$(git -C "$REPO_ROOT" log --first-parent --format='%H%x09%s' "$QS_SHA" 2>/dev/null || true)"
    [[ -n "$QS_FP" ]] || _rv_qs_ne "the first-parent history from ${QS_SHA:0:12} could not be read"
    _qs_o="$(_rv_qs_window - "$QS_FP" "$MS_TITLE" "$(_rv_qs_val window_releases)" "$(_rv_qs_val values_set_at)" "$QS_SHALLOW" < "$QS_LOG")" || true
    _rv_qs_take window "$_qs_o" || _rv_qs_ne "$_QS_NE"
    QS_WIN_READ="$_QS_BODY"

    QS_MS_TSV="$("$GH" api --paginate "repos/$REPO/milestones?state=all&per_page=100" --jq '.[] | [.number, .title] | @tsv' 2>/dev/null || true)"
    [[ -n "$QS_MS_TSV" ]] || _rv_qs_ne "the repository's milestone list could not be read"
    QS_SLUGS="$(/usr/bin/python3 -c 'import json, sys; print(json.dumps(json.loads(sys.argv[1])["releases"]))' "$QS_WIN_READ")"
    _qs_o="$(_rv_qs_resolve "$QS_MS_TSV" "$QS_SLUGS")" || true
    _rv_qs_take resolve "$_qs_o" || _rv_qs_ne "$_QS_NE"
    QS_NUMS="$_QS_BODY"

    # One membership read per release in the window, label names only. A read that
    # returns its own limit is refused as possibly truncated.
    QS_PAIRS=()
    while IFS= read -r _qs_slug; do
      _qs_num="$(/usr/bin/python3 -c 'import json, sys; print(json.loads(sys.argv[1])[sys.argv[2]])' "$QS_NUMS" "$_qs_slug")"
      _qs_mem="$("$GH" issue list --repo "$REPO" --milestone "$_qs_num" --state all --limit 500 \
        --json number,labels --jq '[.[] | {number, labels: [.labels[].name]}]' 2>/dev/null || true)"
      [[ -n "$_qs_mem" ]] || _rv_qs_ne "the membership read for $_qs_slug (milestone $_qs_num) failed"
      _qs_cnt="$(/usr/bin/python3 -c 'import json, sys; print(len(json.loads(sys.argv[1])))' "$_qs_mem" 2>/dev/null || true)"
      [[ -n "$_qs_cnt" ]] || _rv_qs_ne "the membership read for $_qs_slug (milestone $_qs_num) is not JSON"
      _qs_o="$(_rv_qs_member_guard "$_qs_cnt" 500 "$_qs_slug")" || true
      _rv_qs_take member_guard "$_qs_o" || _rv_qs_ne "$_QS_NE"
      QS_PAIRS+=("$_qs_slug" "$_qs_mem")
    done < <(/usr/bin/python3 -c 'import json, sys
for s in json.loads(sys.argv[1]): print(s)' "$QS_SLUGS")
    QS_MEASURED="$(/usr/bin/python3 -c 'import json, sys; m = json.loads(sys.argv[1])["measured"]; print("null" if m is None else m)' "$QS_WIN_READ")"
    _qs_o="$(/usr/bin/python3 -c "$_RV_QS_PY" window_json "$MS_TITLE" "$QS_MEASURED" "${QS_PAIRS[@]}" 2>/dev/null)" || true
    _rv_qs_take window_json "$_qs_o" || _rv_qs_ne "$_QS_NE"
    QS_WINDOW="$_QS_BODY"

    # The counted label must exist: a renamed label would otherwise read 0% as a
    # below-floor finding.
    QS_CL="$(_rv_qs_val counted_label)"
    QS_CL_ENC="$(/usr/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$QS_CL")"
    _qs_le="$("$GH" api "repos/$REPO/labels/$QS_CL_ENC" 2>&1 >/dev/null)" || {
      case "$_qs_le" in
        *"HTTP 404"*|*"Not Found"*) _rv_qs_ne "counted label $QS_CL does not exist on the repository" ;;
        *) _rv_qs_ne "the counted label $QS_CL could not be read from the repository" ;;
      esac
    }

    QS_GUARD="$(/usr/bin/python3 -c 'import json, sys; g = json.loads(sys.argv[1])["guard"]; print("%d commits, %d release merges, each with a row" % (g["commits"], g["release_merges"]))' "$QS_WIN_READ")"
    QS_SOURCE="release/releases/RELEASE_LOG.md by first-parent ancestry from ${QS_SHA:0:12} · guard: ${QS_GUARD} · read $(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)"
  fi

  _qs_o="$(_rv_qs_compute "$QS_WINDOW" "$QS_PARAMS" "$_STATUS_NOT_DELIVERED")" || true
  _rv_qs_take compute "$_qs_o" || _rv_qs_ne "$_QS_NE"
  _qs_o="$(_rv_qs_render "$_QS_BODY" "$OUTPUT_FORMAT" "$QS_SOURCE")" || true
  _rv_qs_take render "$_qs_o" || _rv_qs_ne "$_QS_NE"
  /usr/bin/printf '%s\n' "$_QS_BODY"
  exit 0
fi

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

# ─── --cost-row: the per-release cost row (branches here; the field path below is untouched)
#
# Points come from the SAME delivery predicate as the field. The field's N/A return and
# its plausibility guard do not stop a row: an unsized membership gives null points with
# the reason, and a planned-against-zero-delivered reading keeps its numbers with a flag.
if [[ "$COST_ROW" -eq 1 ]]; then
  CR_JQ="$(find_jq)"
  [[ -n "$CR_JQ" ]] || die "jq not found (looked in /usr/bin, /opt/homebrew/bin, /usr/local/bin, ~/.local/bin) — the cost row's extractor and conversion need it"
  CR_CREATED="$(/usr/bin/python3 -c 'import json,sys
try: print(json.loads(sys.argv[1]).get("created_at") or "")
except Exception: print("")' "$MS_JSON" 2>/dev/null || true)"
  CR_SINCE="${CR_SINCE:-$CR_CREATED}"
  [[ -n "$CR_SINCE" ]] || die "could not read milestone $MILESTONE's created_at; pass --since <ISO-8601>"
  CR_SOURCE_ROOT="${CR_SOURCE_ROOT:-${FINOPS_SOURCE_ROOT:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects}}"
  CR_POINTS="$(/usr/bin/python3 -c 'import json,sys
sized, planned, delivered, ratio = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
if sized == 0:
    out = {"planned": None, "delivered": None, "ratio": None,
           "na_reason": "no size:* labels on milestone membership", "flag": None}
else:
    out = {"planned": planned, "delivered": delivered, "ratio": ratio, "na_reason": None,
           "flag": ("planned %d against delivered 0 (the field refuses this reading)" % planned)
                   if planned > 0 and delivered == 0 else None}
print(json.dumps(out))' "$SIZED_MEMBERS" "$PLANNED_PTS" "$DELIVERED_PTS" "$RATIO")"
  # The scratch view and store live in one run directory, removed on every exit: a hard
  # link left behind would keep a transcript alive past the harness's own deletion.
  CR_RUN="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/cost-row-XXXXXX")" || die "could not create the run directory"
  trap '/bin/rm -rf "$CR_RUN"' EXIT
  trap 'exit 130' INT TERM HUP
  CR_ARGS=(--slug "$MS_TITLE" --version "$VERSION" --milestone "$MILESTONE" --since "$CR_SINCE"
           --source-root "$CR_SOURCE_ROOT" --out-dir "$CR_OUT_DIR" --points-json "$CR_POINTS"
           --extractor "$REPO_ROOT/core/skills/finops-usage-extractor/scripts/extract-usage.sh"
           --converter "$REPO_ROOT/core/skills/finops-usage-extractor/scripts/convert-usage.sh"
           --jq-dir "$(/usr/bin/dirname "$CR_JQ")" --run-dir "$CR_RUN"
           --min-store-schema "$COST_ROW_MIN_STORE_SCHEMA")
  [[ -n "$CR_STORE" ]] && CR_ARGS+=(--store "$CR_STORE")
  [[ "$CR_FORCE" -eq 1 ]] && CR_ARGS+=(--force)
  CR_RC=0
  /usr/bin/python3 -c "$_RV_COST_ROW_PY" "${CR_ARGS[@]}" ${CR_HUB_ARGS[@]+"${CR_HUB_ARGS[@]}"} || CR_RC=$?
  exit "$CR_RC"
fi

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

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Derive milestone `position:` values from the aggregated dependency graph.

Produces the value the live G3-07 "Milestone-Position Resolution" gate consumes
(core/schemas/gate-criteria-spec.md): `position:` override -> `due_on` asc ->
number asc. This tool populates the dormant OVERRIDE tier (`position:`) that the
consumer already knows how to read. Producer for a live-but-fallback-only
consumer (card #52).

Method (AC3): reuse bundle-issues-parser.py's parse_dependencies() to extract
issue-body `### Dependencies` edges (native `blocked-by` is NOT exposed by
`gh issue view --json` in this environment), aggregate issue-level edges up to a
milestone-level dep graph, then derive a total order via Kahn's BFS. An edge
`mA -> mB` means "mA depends on mB", so mB (the prerequisite) MUST sequence
earlier (lower position): Kahn's runs on the REVERSED graph so a milestone with
no outstanding prerequisites emits first (prerequisite-before-dependent). Ready-
set tie-break, applied every time >=2 milestones are simultaneously ready:
  1. inbound-leverage descending (unblocks-the-most emits first);
  2. milestone-title alphabetical (stable, gh-order-independent).
Positions are the 1-based ordinal in emit order (1..N).

Cycle handling (AC6): milestones still unplaced when Kahn's stalls are
cycle-resident. They are appended after the acyclic core (continuing the 1..N
numbering) and annotated with the cycle-membership set for the operator. The
tool does NOT self-break cycles.

Modes (AC4): --dry-run (DEFAULT, mutates nothing) / --apply (PATCHes only
milestones whose computed position differs — idempotent, AC5) / --self-test
(synthetic fixtures, AC7) / --check-drift (deploy.sh Check 52 warn-mode probe).

Reflexive cutover clause (AC10): the position-drift check (Check 52) applies to
milestones entering Stage 3 strictly AFTER this tool's introducing-release merge
SHA (recorded in the release log). The introducing release itself is exempt
(reflexive-pipeline-loop discipline) — consistent with every other pipeline-
internal cutover in gate-criteria-spec.md.

Trigger wiring (AC8): the primary post-deploy trigger is the Stage-13 Close path
(release/tools/automated-closeout.sh phase_post_close_milestone) — after a
release closes and its milestone flips closed, the milestone set changed and
positions should be re-derived via `--apply`. Because that close-out path has
known manual-completion gaps, the invocation is a DOCUMENTED trigger point (a
one-line `--apply` call at the post-close-milestone phase). The Check-52
`deploy.sh --check` drift sub-assertion (below) is the second, passive trigger:
it surfaces drift on every `--check` run (warn-mode), prompting an operator-run
`--apply`. A scheduled/cron wrapper is out of scope (close-out + drift-check
cover the state-change surface).

stdlib-only, Python 3.9+ (AC1) — no 3.10-only syntax (no `match`, no PEP-604
runtime `X | Y` unions; use typing.Optional/List). Reads via `gh` with a
generous `--limit`/`--paginate` (AC2).

Exit codes:
  --self-test   : 0 = OK, 1 = FAIL
  --check-drift : 0 = no drift, 1 = drift found (Check 52 warn aggregator),
                  3 = input failure (gh unreadable / zero data)
  --dry-run     : 0 always (report only), 2 = input failure
  --apply       : 0 = success, 2 = input failure, 1 = one or more PATCHes failed

Usage:
  python3 compute-milestone-positions.py                 # --dry-run (default)
  python3 compute-milestone-positions.py --apply
  python3 compute-milestone-positions.py --check-drift --output-format tsv
  python3 compute-milestone-positions.py --self-test
"""

import argparse
import importlib.util
import json
import os
import subprocess
import sys
from collections import deque
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple

POSITION_RE = None  # lazily compiled in _get_position_re (stdlib re imported there)


# ---- Reuse: bundle-issues-parser.py parse_dependencies (AC3, reuse-first) ----
# The parser filename is hyphenated (not an importable module name), so load it
# by path via importlib. Its `__name__ == "__main__"` guard means import does NOT
# trigger its main(). We reuse parse_dependencies() as-is; we do not re-implement
# dependency extraction (reuse-first + duplicate-source discipline).

def _load_parser():
    here = os.path.dirname(os.path.abspath(__file__))
    parser_path = os.path.join(here, "bundle-issues-parser.py")
    if not os.path.isfile(parser_path):
        raise RuntimeError(
            "reuse dependency missing: {} — parse_dependencies() unavailable".format(parser_path)
        )
    spec = importlib.util.spec_from_file_location("bundle_issues_parser", parser_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return mod


# ---- Data model --------------------------------------------------------------

@dataclass
class Milestone:
    number: int
    title: str
    description: str
    position: Optional[int]  # current `position:` line value, or None if absent


@dataclass
class IssueLite:
    number: int
    milestone_number: Optional[int]
    deps: Set[int] = field(default_factory=set)  # issue numbers this issue depends on
    closed_done: bool = False


# ---- position: line parse / render ------------------------------------------

def _get_position_re():
    global POSITION_RE
    if POSITION_RE is None:
        import re
        # A single leading/trailing metadata line: `position: <int>` (case-insensitive,
        # tolerant of surrounding whitespace). Anchored per-line via MULTILINE.
        POSITION_RE = re.compile(r"(?im)^[ \t]*position:[ \t]*(\d+)[ \t]*$")
    return POSITION_RE


def parse_position(description: str) -> Optional[int]:
    """Return the int value of the first `position:` line in a milestone body, or None."""
    if not description:
        return None
    m = _get_position_re().search(description)
    return int(m.group(1)) if m else None


def render_position(description: str, position: int) -> str:
    """Insert or replace the single `position: N` metadata line, byte-stably.

    - If a `position:` line already exists, replace ONLY that line's value in place
      (no reordering, no prose touch) -> re-render with the same value is a no-op.
    - If absent, append `position: N` as a trailing metadata line (one blank-line
      separator preserved). Body prose is never rewritten.
    This is the idempotency contract (AC5): render(render(body, n), n) == render(body, n).
    """
    desc = description if description is not None else ""
    rx = _get_position_re()
    new_line = "position: {}".format(position)
    if rx.search(desc):
        # Replace only the matched line's content; \g<0> not needed — sub the whole line.
        return rx.sub(new_line, desc, count=1)
    # Append as a trailing metadata line. Normalize trailing whitespace so a second
    # append-then-replace path is byte-stable.
    stripped = desc.rstrip("\n")
    if stripped == "":
        return new_line + "\n"
    return stripped + "\n\n" + new_line + "\n"


# ---- gh reads (AC2) ----------------------------------------------------------

def _resolve_repo() -> Optional[str]:
    """Best-effort {owner}/{repo} for the `gh api` milestone REST surface."""
    env = os.environ.get("AUDIT_REPO") or os.environ.get("GH_REPO")
    if env:
        return env.strip()
    try:
        res = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True, text=True,
        )
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
    except (OSError, ValueError):
        pass
    return None


def gh_open_milestones() -> List[Milestone]:
    """Fetch open milestones via the REST milestones surface, paginated (AC2).

    Uses `gh api ... --paginate --slurp` so all pages are returned even beyond the
    default per-page ceiling (per_page=100). Raises on gh failure (caller -> exit 3).
    """
    repo = _resolve_repo()
    if not repo:
        raise RuntimeError("cannot resolve repo (set AUDIT_REPO/GH_REPO or run inside a gh-authed clone)")
    res = subprocess.run(
        [
            "gh", "api",
            "repos/{}/milestones".format(repo),
            "-X", "GET",
            "-f", "state=open",
            "-f", "per_page=100",
            "--paginate", "--slurp",
        ],
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        raise RuntimeError("gh api milestones failed: {}".format(res.stderr.strip()[:200]))
    # --slurp wraps paginated arrays in an outer array; flatten.
    pages = json.loads(res.stdout or "[]")
    flat: List[Dict] = []
    for page in pages:
        if isinstance(page, list):
            flat.extend(page)
        else:
            flat.append(page)
    out: List[Milestone] = []
    for m in flat:
        desc = m.get("description") or ""
        out.append(Milestone(
            number=int(m["number"]),
            title=m.get("title") or "",
            description=desc,
            position=parse_position(desc),
        ))
    return out


def gh_open_issues(parse_dependencies) -> List[IssueLite]:
    """Fetch open issues + their milestone + dep edges via `gh issue list` (AC2).

    --limit 5000 mirrors bundle-issues-parser.py's generous ceiling. Dep edges are
    extracted by the REUSED parse_dependencies() (issue-body `### Dependencies`).
    """
    res = subprocess.run(
        [
            "gh", "issue", "list",
            "--state", "open",
            "--json", "number,milestone,body,labels,state",
            "--limit", "5000",
        ],
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        raise RuntimeError("gh issue list failed: {}".format(res.stderr.strip()[:200]))
    raw = json.loads(res.stdout or "[]")
    out: List[IssueLite] = []
    for it in raw:
        body = it.get("body") or ""
        deps, _status = parse_dependencies(body)
        ms = it.get("milestone") or {}
        ms_num = int(ms["number"]) if ms and ms.get("number") is not None else None
        out.append(IssueLite(number=int(it["number"]), milestone_number=ms_num, deps=set(deps)))
    return out


# ---- Graph aggregation (issue-level -> milestone-level) ----------------------

@dataclass
class AggregatedGraph:
    # milestone-level edges mA -> mB (mA depends on mB), with leverage weights.
    edges: Set[Tuple[int, int]] = field(default_factory=set)
    leverage: Dict[Tuple[int, int], int] = field(default_factory=dict)  # collapsed issue-edge count
    unresolvable: List[str] = field(default_factory=list)  # R8: loud warnings, not silent drops


def aggregate_edges(
    milestones: List[Milestone],
    issues: List[IssueLite],
) -> AggregatedGraph:
    """Map issue-level dep edges to milestone-level edges, dropping the classes G3-07
    treats as non-ordering and surfacing unresolvable/no-milestone edges loudly (R8, AC6).

    Drop rules (mirror G3-07):
      - same-milestone edge (mA == mB): same-position-class trivial-pass — drop.
      - target issue has NO milestone (unbundled): G3-07 would FAIL; we cannot place
        it, so we record an unresolvable-edge WARNING (never silently dropped, R8).
      - target issue not in the open set / unknown: recorded as unresolvable (loud).
    De-duplicate parallel milestone edges; retain multiplicity as inbound-leverage.
    """
    g = AggregatedGraph()
    ms_of_issue: Dict[int, Optional[int]] = {i.number: i.milestone_number for i in issues}
    open_ms_numbers = {m.number for m in milestones}

    for src in issues:
        if src.milestone_number is None:
            # A source with no milestone still carries ordering signal onto its target,
            # but there is no source-milestone node to order — record loudly and skip.
            if src.deps:
                g.unresolvable.append(
                    "issue #{} has dependencies {} but no milestone — cannot contribute a source node".format(
                        src.number, sorted(src.deps)
                    )
                )
            continue
        for dep in sorted(src.deps):
            tgt_ms = ms_of_issue.get(dep, "__unknown__")
            if tgt_ms == "__unknown__":
                g.unresolvable.append(
                    "edge #{} -> #{}: target issue not in the open-issue set (closed/renumbered?) — ordering signal unplaceable".format(
                        src.number, dep
                    )
                )
                continue
            if tgt_ms is None:
                g.unresolvable.append(
                    "edge #{} -> #{}: target issue has no milestone (unbundled) — G3-07 would FAIL; unplaceable".format(
                        src.number, dep
                    )
                )
                continue
            ma, mb = src.milestone_number, tgt_ms
            if ma == mb:
                continue  # same-milestone: trivial-pass, not an ordering constraint
            if ma not in open_ms_numbers or mb not in open_ms_numbers:
                g.unresolvable.append(
                    "edge m{} -> m{}: a milestone endpoint is not in the open set — unplaceable".format(ma, mb)
                )
                continue
            e = (ma, mb)
            g.edges.add(e)
            g.leverage[e] = g.leverage.get(e, 0) + 1
    return g


# ---- Kahn's BFS with deterministic tie-break (AC3, AC6) ----------------------

@dataclass
class DerivationResult:
    order: List[int]                       # milestone numbers, emit order (position = idx+1)
    positions: Dict[int, int]              # milestone number -> position (1..N)
    cycle_members: List[int]               # milestone numbers appended as cycle-resident
    unresolvable: List[str]                # carried from aggregation (R8)


def derive_positions(
    milestones: List[Milestone],
    graph: AggregatedGraph,
) -> DerivationResult:
    """Kahn's BFS on the REVERSED dep graph so prerequisites emit first.

    An aggregated edge mA -> mB means "mA depends on mB". We want mB before mA.
    Build a "must-precede" relation prereq(mB) -> dependent(mA); a milestone is
    READY when all its prerequisites are already emitted. Equivalently: process a
    milestone once its outstanding-prerequisite count (its out-degree in the
    dependency graph, restricted to not-yet-placed targets) reaches zero.

    Implementation: `remaining_prereqs[m]` = number of distinct milestones m still
    depends on (out-degree over unique targets). Ready set = milestones whose
    remaining_prereqs == 0. When a milestone is emitted, decrement remaining_prereqs
    for every milestone that depends on it (its reverse-adjacency).
    """
    title_of = {m.number: m.title for m in milestones}
    all_nums = [m.number for m in milestones]

    # Unique milestone-level edges (leverage already deduped in graph.edges).
    depends_on: Dict[int, Set[int]] = {n: set() for n in all_nums}        # m -> {prereqs}
    dependents_of: Dict[int, Set[int]] = {n: set() for n in all_nums}     # prereq -> {dependents}
    for (ma, mb) in graph.edges:
        # both endpoints are guaranteed open-set members by aggregate_edges
        depends_on[ma].add(mb)
        dependents_of[mb].add(ma)

    remaining = {n: len(depends_on[n]) for n in all_nums}

    # inbound-leverage(m) = total collapsed issue-edge weight of edges INTO m as a
    # prerequisite (i.e. how much m unblocks). Sum leverage over edges (x -> m).
    inbound_leverage: Dict[int, int] = {n: 0 for n in all_nums}
    for (ma, mb), w in graph.leverage.items():
        inbound_leverage[mb] += w  # mb is the prerequisite that unblocks ma

    def ready_sort_key(num: int) -> Tuple[int, str]:
        # inbound-leverage DESC (negate) -> title alphabetical ASC.
        return (-inbound_leverage[num], title_of.get(num, ""))

    ready = sorted([n for n in all_nums if remaining[n] == 0], key=ready_sort_key)
    ready_dq = deque(ready)
    in_ready = set(ready)

    order: List[int] = []
    placed: Set[int] = set()

    while ready_dq:
        # Re-sort the ready frontier each emission so the tie-break is applied to the
        # CURRENT ready set (newly-ready milestones join the ordering correctly).
        frontier = sorted(ready_dq, key=ready_sort_key)
        node = frontier[0]
        ready_dq = deque(frontier[1:])
        in_ready.discard(node)

        order.append(node)
        placed.add(node)
        for dependent in sorted(dependents_of[node]):
            remaining[dependent] -= 1
            if remaining[dependent] == 0 and dependent not in placed and dependent not in in_ready:
                ready_dq.append(dependent)
                in_ready.add(dependent)

    # Cycle-resident = anything Kahn's never placed (remaining never hit 0).
    cycle_members = [n for n in all_nums if n not in placed]
    # Deterministic append order for cycle members: leverage-desc -> title-alpha.
    cycle_members.sort(key=ready_sort_key)
    order.extend(cycle_members)

    positions = {num: idx + 1 for idx, num in enumerate(order)}
    return DerivationResult(
        order=order,
        positions=positions,
        cycle_members=cycle_members,
        unresolvable=list(graph.unresolvable),
    )


# ---- Reporting / apply -------------------------------------------------------

def _plan_rows(
    milestones: List[Milestone],
    result: DerivationResult,
) -> List[Tuple[int, str, Optional[int], int, str]]:
    """(number, title, current_pos, computed_pos, action) — action NOOP / UPDATE."""
    by_num = {m.number: m for m in milestones}
    rows = []
    for num in result.order:
        m = by_num[num]
        computed = result.positions[num]
        current = m.position
        action = "NOOP" if current == computed else "UPDATE"
        rows.append((num, m.title, current, computed, action))
    return rows


def print_plan(milestones: List[Milestone], result: DerivationResult, applied: bool) -> None:
    rows = _plan_rows(milestones, result)
    header = "  #     current  computed  action    title"
    print(header)
    print("  " + "-" * (len(header) - 2))
    for (num, title, current, computed, action) in rows:
        cur = "-" if current is None else str(current)
        print("  {:<5} {:>7}  {:>8}  {:<8}  {}".format(num, cur, computed, action, title))
    if result.cycle_members:
        print("")
        print("  CYCLE: {} milestone(s) are cycle-resident (appended after the acyclic core;".format(
            len(result.cycle_members)))
        print("         positions assigned so G3-07 has a value, but the ordering is operator-unresolved):")
        by_num = {m.number: m for m in milestones}
        for num in result.cycle_members:
            print("           - m{} (pos {}): {}".format(
                num, result.positions[num], by_num[num].title))
    if result.unresolvable:
        print("")
        print("  UNRESOLVABLE EDGES ({} — surfaced, not silently dropped):".format(len(result.unresolvable)))
        for w in result.unresolvable:
            print("           - {}".format(w))
    updates = sum(1 for r in rows if r[4] == "UPDATE")
    verb = "PATCHed" if applied else "would PATCH"
    print("")
    print("  {} {} milestone(s); {} at target.".format(verb, updates, len(rows) - updates))


def gh_patch_milestone(repo: str, number: int, description: str) -> Tuple[bool, str]:
    """PATCH one milestone description via gh api. Returns (ok, detail)."""
    res = subprocess.run(
        [
            "gh", "api", "-X", "PATCH",
            "repos/{}/milestones/{}".format(repo, number),
            "-f", "description={}".format(description),
        ],
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        return False, res.stderr.strip()[:200]
    return True, ""


def apply_positions(milestones: List[Milestone], result: DerivationResult) -> int:
    """PATCH only milestones whose computed position != current (AC5 idempotency).

    Returns process exit code (0 ok, 1 one or more PATCH failures, 2 no repo).
    """
    repo = _resolve_repo()
    if not repo:
        print("ERROR: cannot resolve repo for --apply (set AUDIT_REPO/GH_REPO)", file=sys.stderr)
        return 2
    by_num = {m.number: m for m in milestones}
    failures = 0
    patched = 0
    for num in result.order:
        m = by_num[num]
        computed = result.positions[num]
        if m.position == computed:
            continue  # idempotency: skip already-at-target
        new_desc = render_position(m.description, computed)
        if new_desc == m.description:
            # Defensive: render was a no-op (value already present as the line) — skip.
            continue
        ok, detail = gh_patch_milestone(repo, num, new_desc)
        if ok:
            patched += 1
            print("  PATCHed m{} -> position: {}".format(num, computed))
        else:
            failures += 1
            print("  FAIL   m{} PATCH failed: {}".format(num, detail), file=sys.stderr)
    print("")
    print("  {} milestone(s) PATCHed; {} failure(s).".format(patched, failures))
    return 1 if failures else 0


# ---- Live pipeline (dry-run / apply / check-drift) ---------------------------

def _load_live() -> Tuple[List[Milestone], DerivationResult]:
    """Fetch live milestones+issues, aggregate, derive. Raises RuntimeError on gh failure."""
    parser_mod = _load_parser()
    milestones = gh_open_milestones()
    issues = gh_open_issues(parser_mod.parse_dependencies)
    graph = aggregate_edges(milestones, issues)
    result = derive_positions(milestones, graph)
    return milestones, result


def run_dry_run() -> int:
    try:
        milestones, result = _load_live()
    except RuntimeError as e:
        print("ERROR: {}".format(e), file=sys.stderr)
        return 2
    print("Milestone position derivation (DRY-RUN — no mutation):")
    print_plan(milestones, result, applied=False)
    return 0


def run_apply() -> int:
    try:
        milestones, result = _load_live()
    except RuntimeError as e:
        print("ERROR: {}".format(e), file=sys.stderr)
        return 2
    print("Milestone position derivation (APPLY):")
    return apply_positions(milestones, result)


def run_check_drift(output_format: str) -> int:
    """deploy.sh Check 52 probe. TSV contract mirrors #30's Check-53 primitive:
        COUNT\t<n>                 always
        DRIFT\tm<num>:<cur>-><new> one line per drifted milestone (only when >0)
    Exit: 0 = no drift, 1 = drift found, 3 = input failure.
    """
    try:
        milestones, result = _load_live()
    except RuntimeError as e:
        # Check 52 treats input failure as exit 3 (the deploy.sh block maps it to a
        # WARN "input failure" — never a silent pass).
        if output_format == "tsv":
            print("ERROR\t{}".format(str(e)[:200]))
        else:
            print(json.dumps({"error": str(e)[:200]}))
        return 3
    rows = _plan_rows(milestones, result)
    drifted = [(num, cur, comp) for (num, _t, cur, comp, action) in rows if action == "UPDATE"]
    if output_format == "tsv":
        print("COUNT\t{}".format(len(drifted)))
        for (num, cur, comp) in drifted:
            print("DRIFT\tm{}:{}->{}".format(num, "-" if cur is None else cur, comp))
    else:
        print(json.dumps({
            "count": len(drifted),
            "drift": [{"milestone": n, "current": c, "computed": p} for (n, c, p) in drifted],
        }))
    return 1 if drifted else 0


# ---- Self-test (AC7) — R5 load-bearing fixtures ------------------------------

def run_self_test() -> int:
    """Synthetic in-memory fixtures — NO live gh calls. R5 makes two of these
    hard gates: (R5a) idempotency over a PROSE-BEARING milestone body proving
    --apply inserts/replaces a single `position:` line byte-stably without
    touching prose; (R5b) a linear-chain A->B->C pinning Kahn's orientation
    (prerequisite emits first). The whole tool's correctness rests on these.
    """
    failures: List[str] = []

    def ms(num, title, desc="", pos=None):
        return Milestone(num, title, desc, pos)

    def iss(num, ms_num, deps):
        return IssueLite(num, ms_num, set(deps))

    # --- R5b (HARD GATE): linear chain A->B->C pins orientation ---------------
    # Milestones: 1="A", 2="B", 3="C". Issues encode A depends on B, B depends on C
    # at the milestone level (issue #101 in A dep #102 in B; #102 dep #103 in C).
    # Dependency direction: A->B->C  => prerequisite chain C (first) -> B -> A (last).
    # Correct orientation MUST emit C, B, A  => positions C=1, B=2, A=3.
    mlist = [ms(1, "A"), ms(2, "B"), ms(3, "C")]
    ilist = [iss(101, 1, [102]), iss(102, 2, [103]), iss(103, 3, [])]
    g = aggregate_edges(mlist, ilist)
    r = derive_positions(mlist, g)
    if r.order != [3, 2, 1]:
        failures.append("R5b orientation: linear chain A->B->C expected emit [3,2,1] (C,B,A prerequisite-first); got {}".format(r.order))
    if r.positions != {3: 1, 2: 2, 1: 3}:
        failures.append("R5b positions: expected {{C:1,B:2,A:3}}; got {}".format(r.positions))

    # --- R5a (HARD GATE): prose-bearing idempotency ---------------------------
    # A realistic multi-line markdown milestone body (H2s + bullets). --apply must
    # insert a SINGLE `position: N` line without disturbing prose, and a second
    # apply must be a byte-stable no-op (zero change).
    prose = (
        "## Outcome\n"
        "Stage 3 Bundling becomes a self-triggering composer.\n"
        "\n"
        "## Scope\n"
        "- derive milestone sequence from the dep graph\n"
        "- feed the live G3-07 gate\n"
        "- carry a bundle-composer identity\n"
        "\n"
        "## Notes\n"
        "See epic #9001. Do not restate design here.\n"
    )
    inserted = render_position(prose, 7)
    # (a) prose is preserved verbatim (every original line still present, in order).
    if not all(line in inserted for line in prose.splitlines()):
        failures.append("R5a prose-preservation: original prose lines missing after insert")
    # (b) exactly one position line, correct value.
    if parse_position(inserted) != 7:
        failures.append("R5a insert: expected position 7, got {}".format(parse_position(inserted)))
    if inserted.count("position:") != 1:
        failures.append("R5a single-line: expected exactly 1 'position:' line, got {}".format(inserted.count("position:")))
    # (c) BYTE-STABLE idempotency: re-render same value == no-op (2nd --apply -> zero PATCH).
    reinserted = render_position(inserted, 7)
    if reinserted != inserted:
        failures.append("R5a byte-stability: second render(7) mutated the body (would PATCH again) — not idempotent")
    # (d) replace-in-place: re-derive to a NEW value replaces only the value, still 1 line, prose intact.
    replaced = render_position(inserted, 3)
    if parse_position(replaced) != 3 or replaced.count("position:") != 1:
        failures.append("R5a replace: expected single position:3 line, got value={} count={}".format(
            parse_position(replaced), replaced.count("position:")))
    if not all(line in replaced for line in prose.splitlines()):
        failures.append("R5a replace prose-preservation: prose disturbed on value replace")
    # (e) replace is itself idempotent.
    if render_position(replaced, 3) != replaced:
        failures.append("R5a replace byte-stability: second render(3) mutated the body")

    # --- fan-in: inbound-leverage-desc tie-break ------------------------------
    # Milestones: 10="hub" (prerequisite), 20="depA", 30="depB". Both depA and depB
    # depend on hub. hub emits first (pos 1). Then depA vs depB are BOTH ready with
    # equal leverage(0) -> title-alpha: "depA" < "depB" -> depA(2), depB(3).
    # Give hub extra inbound leverage via TWO distinct issue-edges collapsing onto
    # the same milestone edge to exercise weight accumulation.
    mlist2 = [ms(10, "hub"), ms(20, "depA"), ms(30, "depB")]
    ilist2 = [
        iss(201, 20, [200]), iss(202, 20, [210]),  # depA has 2 issues, each dep an issue in hub
        iss(203, 30, [200]),                        # depB deps hub once
        iss(200, 10, []), iss(210, 10, []),         # hub's issues
    ]
    g2 = aggregate_edges(mlist2, ilist2)
    r2 = derive_positions(mlist2, g2)
    if r2.order[0] != 10:
        failures.append("fan-in: hub (prerequisite) must emit first; got order {}".format(r2.order))
    if r2.order != [10, 20, 30]:
        failures.append("fan-in alpha tie-break: expected [10(hub),20(depA),30(depB)]; got {}".format(r2.order))

    # --- inbound-leverage strictly orders two ready prerequisites -------------
    # Milestones: 40="Zeta" (unblocks 2), 50="Alpha" (unblocks 1), 60="d1", 70="d2".
    # d1 deps BOTH Zeta and Alpha; d2 deps Zeta only. At start, Zeta+Alpha are ready
    # (no prereqs). Zeta leverage=2 (d1,d2), Alpha leverage=1 (d1) -> Zeta emits
    # before Alpha DESPITE "Zeta" > "Alpha" alphabetically (leverage dominates).
    mlist3 = [ms(40, "Zeta"), ms(50, "Alpha"), ms(60, "d1"), ms(70, "d2")]
    ilist3 = [
        iss(401, 40, []), iss(501, 50, []),
        iss(601, 60, [401, 501]),  # d1 deps Zeta + Alpha
        iss(701, 70, [401]),        # d2 deps Zeta
    ]
    g3 = aggregate_edges(mlist3, ilist3)
    r3 = derive_positions(mlist3, g3)
    if r3.order[:2] != [40, 50]:
        failures.append("leverage-desc: Zeta(lev2) must precede Alpha(lev1) despite alpha order; got {}".format(r3.order))

    # --- cycle handling (AC6) -------------------------------------------------
    # X<->Y cycle plus an acyclic Z (prerequisite of nothing, depends on nothing).
    # Z emits in the acyclic core; X,Y are cycle-resident -> appended + annotated.
    mlist4 = [ms(80, "X"), ms(90, "Y"), ms(100, "Z")]
    ilist4 = [
        iss(801, 80, [901]),  # X deps Y
        iss(901, 90, [801]),  # Y deps X  -> cycle
        iss(1001, 100, []),   # Z acyclic
    ]
    g4 = aggregate_edges(mlist4, ilist4)
    r4 = derive_positions(mlist4, g4)
    if sorted(r4.cycle_members) != [80, 90]:
        failures.append("cycle: expected cycle_members {{80,90}}; got {}".format(r4.cycle_members))
    if 100 not in r4.order[: len(r4.order) - len(r4.cycle_members)]:
        failures.append("cycle: acyclic Z(100) must precede appended cycle members; got order {}".format(r4.order))
    # cycle members still receive a position (so G3-07 has a value).
    if 80 not in r4.positions or 90 not in r4.positions:
        failures.append("cycle: cycle-resident milestones must still receive a position")

    # --- unresolvable edge (R8, AC6): no-milestone target surfaced, not dropped
    mlist5 = [ms(110, "P"), ms(120, "Q")]
    # issue #1101 in P deps #9999 which is NOT in the open-issue set -> unresolvable.
    ilist5 = [iss(1101, 110, [9999]), iss(1201, 120, [])]
    g5 = aggregate_edges(mlist5, ilist5)
    if not any("9999" in w for w in g5.unresolvable):
        failures.append("R8 unresolvable: edge to unknown target #9999 must surface a loud warning; got {}".format(g5.unresolvable))
    # a target that exists but has no milestone:
    mlist6 = [ms(130, "R")]
    ilist6 = [iss(1301, 130, [1302]), iss(1302, None, [])]  # #1302 exists, no milestone
    g6 = aggregate_edges(mlist6, ilist6)
    if not any("no milestone" in w for w in g6.unresolvable):
        failures.append("R8 no-milestone: edge to a milestone-less target must surface a loud warning; got {}".format(g6.unresolvable))

    # --- derivation idempotency (AC5) over a full fixture ---------------------
    # Re-deriving the same graph yields identical positions (fixed point).
    r_a = derive_positions(mlist2, g2)
    r_b = derive_positions(mlist2, g2)
    if r_a.positions != r_b.positions:
        failures.append("AC5 derivation determinism: two derivations differ: {} vs {}".format(r_a.positions, r_b.positions))

    # --- same-milestone edge is dropped (trivial-pass) ------------------------
    mlist7 = [ms(140, "S"), ms(150, "T")]
    ilist7 = [iss(1401, 140, [1402]), iss(1402, 140, [])]  # both issues in milestone S
    g7 = aggregate_edges(mlist7, ilist7)
    if g7.edges:
        failures.append("same-milestone edge must be dropped (trivial-pass); got edges {}".format(g7.edges))

    if failures:
        print("SELF-TEST FAIL:", file=sys.stderr)
        for f in failures:
            print("  - {}".format(f), file=sys.stderr)
        return 1
    print("SELF-TEST OK")
    return 0


# ---- Main --------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true",
                      help="Compute + print the position plan; mutate nothing (DEFAULT).")
    mode.add_argument("--apply", action="store_true",
                      help="PATCH milestones whose computed position differs (idempotent).")
    mode.add_argument("--self-test", action="store_true",
                      help="Run synthetic fixtures (AC7); exit 0 OK / 1 FAIL.")
    mode.add_argument("--check-drift", action="store_true",
                      help="deploy.sh Check 52 probe: report drifted milestones; exit 0/1/3.")
    ap.add_argument("--output-format", choices=["tsv", "json"], default="tsv",
                    help="Machine output format for --check-drift (default tsv).")
    args = ap.parse_args()

    if args.self_test:
        return run_self_test()
    if args.check_drift:
        return run_check_drift(args.output_format)
    if args.apply:
        return run_apply()
    # DEFAULT: dry-run.
    return run_dry_run()


if __name__ == "__main__":
    sys.exit(main())

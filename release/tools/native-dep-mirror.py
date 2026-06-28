#!/usr/bin/env python3
"""Native-Dep Mirror — Stage 2 Triage substep A3.5 (AS2 tracked tool).

Mirrors an issue's body `### Dependencies` field FS+0d subset to GitHub's native
issue-dependency surface (`blocked-by`), per the one-way body→native mirror model
(body is authoritative; native is a projected display surface). This is the
AS2-promoted form of the A3.5 mirror procedure previously specified only as
pseudocode in the Stage 2 triage shard (agent-script promotion framework §1 — see
the promotion decision line in the promoting PR).

Mirror contract (Model A — body→native one-way; the authoritative spec lives in
release/references/specs/ticket-information-architecture.md § Native Dependencies):
  - Eligible body deps: `FS+0d #N` on a **Blocked by: / Depends on:** segment ONLY
    (default / untyped `#N` normalizes to FS+0d). The Dependencies section is a
    labeled-segment grammar — a `#N` on a **Blocks:** segment is the RECIPROCAL
    ("current blocks #N", not "current blocked-by #N") and is NOT mirrored as a
    current-issue blocked-by; a `#N` on a **Relates to: / sibling / pairs** segment
    is non-blocking and is NOT mirrored at all. Non-FS-zero-lag types (`SS`, `FF`,
    `SF`, `FS±Nd`) are body-only by design — native `blocks`/`blocked-by` has only
    one semantic and cannot express them, so they are NEVER mirrored. (Direction-
    blind parsing of `Blocks:` / `Relates to:` targets was the #662 Blocker —
    it inverted edges and wrote false native blocked-by dependencies.)
  - to_add  = eligible body deps NOT present in native blocked-by → add via
    GraphQL addIssueDependency (body wins; auto-resolve).
  - drift   = native blocked-by NOT present in eligible body deps → FLAGGED for
    operator review; body is NOT auto-modified (body remains authoritative).
  - Idempotent: re-running with the same body state is a no-op (modulo the API's
    eventual-consistency window).

Gate posture: A3.5 is NOT gate-blocking. G2-04 (dependency state validation) is
the gate; this mirror is an additive sync step whose failures surface for operator
awareness but do not block the Phase B verdict.

Usage:
  # Mirror a single issue (resolves repo from the cwd's gh context):
  python3 native-dep-mirror.py --issue 662

  # Mirror every open issue in a milestone:
  python3 native-dep-mirror.py --milestone "69-triage-and-bundling-signals"

  # Explicit repo (OWNER/NAME); else resolved via `gh repo view`:
  python3 native-dep-mirror.py --issue 662 --repo OWNER/pmo-platform

  # Plan only — compute + print the mirror plan, perform NO native writes:
  python3 native-dep-mirror.py --issue 662 --dry-run

  # JSON plan/result (machine-consumable):
  python3 native-dep-mirror.py --issue 662 --output-format json

  # Fixture self-test (no network; exercises the deterministic core):
  python3 native-dep-mirror.py --self-test

Exit codes:
  0 — mirror completed (or dry-run plan produced) with no add failures
  1 — one or more native add operations failed (operator awareness; non-gating)
  2 — API / network / scope failure resolving repo or reading issue/native deps
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, asdict, field
from typing import Dict, List, Optional, Set, Tuple


# ---- Typed-dependency parsing (per ticket-information-architecture.md grammar) --
#
# DEPENDENCY  ::= [TYPE_PREFIX][OFFSET] HASH_REF
# TYPE_PREFIX ::= "FS" | "SS" | "FF" | "SF"   (optional; default "FS")
# OFFSET      ::= ("+"|"-") INTEGER "d"        (optional; default "0d")
# HASH_REF    ::= "#" INTEGER                   (required)
#
# Untyped `#N` normalizes to FS+0d (backward-compat shim). The dep-section
# heading is matched suffix-tolerantly and against a closed alias set, mirroring
# bundle-issues-parser.py's DEP_HEADING_ALIASES (the canonical body parser).
#
# DIRECTION IS SEGMENT-SCOPED (#662 Blocker fix). The live body format (rendered
# from improvement.yml's `Dependencies` field) is a labeled-segment grammar, NOT a
# flat "every `#N` is a blocker" list. A single Dependencies section commonly reads:
#
#     Blocked by: — · Blocks: #213 · Relates to: #149, #61
#
# Only `#N` on a **Blocked by: / Depends on:** segment means "current issue IS
# blocked-by #N" (the mirror-eligible direction → native blocked-by(current ← #N)).
# A `#N` on a **Blocks:** segment is the RECIPROCAL ("current BLOCKS #N") — mirroring
# it as blocked-by(current ← #N) INVERTS the edge (the #662 defect: #225's
# `Blocks: #213` was being asserted as "225 blocked-by 213", the opposite of truth).
# `#N` on a relates/sibling/pairs/parent segment is a NON-blocking relationship and
# is never mirrored. Per the sibling precedent bundle-issues-parser.py
# (`derive_artifact_relationships`: "BLOCKS is reachable only from native … in that
# degraded path no BLOCKS edge is emitted and the dependency defaults to the weakest
# correct claim"), the reciprocal-`Blocks:` edge is NOT asserted as a current-issue
# blocked-by; it is left to the target issue's own `Blocked by:` segment to express.

SECTION_HEADING_RE = re.compile(r"^###\s+", re.MULTILINE)

DEP_HEADING_ALIASES = [
    "Dependencies",
    "Dependency",
    "Depends on",
    "Blocked by",
    "Relationships",
]

# Segment-label grammar inside the Dependencies section. The section body is sliced
# into labeled segments at these markers; each `#N` is attributed to the label that
# precedes it. `kind` drives mirror direction:
#   "blocked_by" — current IS blocked-by #N        → mirror-eligible (the only kind)
#   "blocks"     — current BLOCKS #N (reciprocal)   → NOT a current-issue blocked-by
#   "relates"    — non-blocking relationship        → never mirrored
# A `#N` appearing before any label (an unlabeled leading run, e.g. the legacy
# bullet-list `### Dependencies\n- #46` form) is treated as "blocked_by" — that bare
# form has always meant "this issue depends on #N" (backward-compat with the legacy
# fixtures and the spec's untyped-`#N`→blocked-by default).
SEGMENT_LABELS: List[Tuple[str, str]] = [
    # label-kind, regex matching the label token (case-insensitive, colon-tolerant)
    ("blocked_by", r"Blocked\s*by"),
    ("blocked_by", r"Depends\s*on"),
    ("blocked_by", r"Requires"),               # placeholder "Requires #N first"
    ("blocks",     r"Blocks"),
    ("relates",    r"Relates\s*to"),
    ("relates",    r"Relates"),
    ("relates",    r"Related"),
    ("relates",    r"Relationship"),
    ("relates",    r"Pairs\s*with"),
    ("relates",    r"Coordinates\s*with"),
    ("relates",    r"Foundational\s*sibling\s*to"),
    ("relates",    r"Sibling"),
    ("relates",    r"Parent"),
    ("relates",    r"Child"),
    ("relates",    r"Sub-?task\s*of"),
    ("relates",    r"Scope-?boundary"),
    ("relates",    r"See\s*also"),
]

# A single matcher that finds ANY segment label and reports its kind. Longest /
# most-specific alternations first so "Relates to" wins over bare "Relates", etc.
# Anchored to a word boundary on the left; followed by an optional colon.
_SEGMENT_LABEL_RE = re.compile(
    r"\b(?P<label>"
    + "|".join(rf"(?P<k{i}>{pat})" for i, (_kind, pat) in enumerate(SEGMENT_LABELS))
    + r")\s*:?",
    re.IGNORECASE,
)
_LABEL_KIND_BY_GROUP = {f"k{i}": kind for i, (kind, _pat) in enumerate(SEGMENT_LABELS)}

# One dependency token. Type prefix + offset optional; hash-ref required.
# Examples matched: "#46", "FS #46", "FS+0d #46", "SS #46", "FS+3d #46",
# "FS-2d #46". Anchored to a token boundary so "##" or "#46abc" do not match.
#
# COMMA-SAFE (#662 fix): the target is `\d[\d,]*\d|\d` — it captures a full
# comma-grouped integer (`#1,234`) instead of truncating at the comma to `#1`. The
# captured run's commas are stripped before int() (a comma-grouped issue number is
# not a real GitHub id, but capturing the whole run prevents a SILENT mirror against
# the wrong issue `#1`; such tokens are then dropped as out-of-range — see
# parse_body_dependencies). A trailing `\b` still rejects `#46abc`.
DEP_TOKEN_RE = re.compile(
    r"(?P<type>FS|SS|FF|SF)?\s*"
    r"(?:(?P<sign>[+-])(?P<offset>\d+)d)?\s*"
    r"#(?P<target>\d[\d,]*\d|\d)\b"
)


@dataclass
class BodyDep:
    """A single parsed body dependency edge.

    `direction` records which labeled segment the edge came from:
      "blocked_by" — current issue IS blocked-by `target` (the mirror-eligible kind)
      "blocks"     — current issue BLOCKS `target` (reciprocal; never a current-issue
                     blocked-by edge — see is_mirror_eligible)
    Non-blocking relationships (relates/sibling/…) are NOT emitted as BodyDep at all.
    """
    type: str          # "FS" | "SS" | "FF" | "SF"
    offset_days: int   # signed integer; 0 when omitted
    target: int        # the referenced issue number
    direction: str = "blocked_by"  # "blocked_by" | "blocks"

    @property
    def is_mirror_eligible(self) -> bool:
        """Mirror-eligible = FS, zero lag, AND blocked-by direction (Model A subset).

        The blocked-by direction gate is the #662 fix: a `blocks` (reciprocal) edge
        is NEVER mirrored as a current-issue native blocked-by, even when FS+0d —
        mirroring it would invert the dependency direction.
        """
        return (
            self.type == "FS"
            and self.offset_days == 0
            and self.direction == "blocked_by"
        )


def extract_section_aliased(body: str, aliases: List[str]) -> Optional[str]:
    """Return the first '### <alias>' section body (suffix-tolerant; first-match-wins).

    Mirrors bundle-issues-parser.py extract_section semantics: prefix-anchored,
    suffix-tolerant heading match (a trailing parenthetical/colon does not defeat
    it); section ends at the next H2/H3 heading or a two-blank-line gap.
    """
    if not body:
        return None
    for heading in aliases:
        pat = re.compile(
            rf"^#{{2,4}}\s+{re.escape(heading)}\b[^\n]*$", re.MULTILINE | re.IGNORECASE
        )
        m = pat.search(body)
        if not m:
            continue
        rest = body[m.end():]
        end_h3 = SECTION_HEADING_RE.search(rest)
        end_h2 = re.search(r"^##\s+", rest, re.MULTILINE)
        end_blank = re.search(r"\n\s*\n\s*\n", rest)
        cands = [c.start() for c in (end_h3, end_h2, end_blank) if c is not None]
        return rest[: min(cands)] if cands else rest
    return None


def _attribute_segments(section: str) -> List[Tuple[str, str]]:
    """Slice a Dependencies section into (kind, text) segments by labeled marker.

    Walks the section left-to-right, finding each segment label (Blocked by / Blocks
    / Relates to / …); the text from one label up to the next is attributed to that
    label's kind. Any leading text BEFORE the first label is attributed "blocked_by"
    (the legacy bare-`#N` bullet-list form — `### Dependencies\n- #46` — has always
    meant "this issue depends on #46"). Segment slicing is whitespace/newline-blind,
    so it handles BOTH the single-line `A · B · C` form and the multi-line form.
    """
    segments: List[Tuple[str, str]] = []
    matches = list(_SEGMENT_LABEL_RE.finditer(section))
    if not matches:
        # No labels at all → whole section is the legacy blocked-by list.
        return [("blocked_by", section)]
    # Leading run before the first label → legacy blocked-by (bare `#N`).
    if matches[0].start() > 0:
        lead = section[: matches[0].start()]
        if lead.strip():
            segments.append(("blocked_by", lead))
    for i, m in enumerate(matches):
        kind = next(
            (_LABEL_KIND_BY_GROUP[g] for g in _LABEL_KIND_BY_GROUP if m.group(g)),
            "relates",
        )
        seg_start = m.end()
        seg_end = matches[i + 1].start() if i + 1 < len(matches) else len(section)
        segments.append((kind, section[seg_start:seg_end]))
    return segments


def _parse_token(m: "re.Match") -> Optional[Tuple[str, int, int]]:
    """Normalize one DEP_TOKEN_RE match → (type, offset_days, target).

    Returns None for an out-of-range / ambiguous target (e.g. a comma-grouped
    `#1,234` — not a real GitHub issue id; captured whole to avoid a SILENT truncated
    mirror against `#1`, then dropped here so no wrong edge is written).
    """
    raw_target = m.group("target").replace(",", "")
    if "," in m.group("target"):
        # Comma-grouped run: captured to prevent the `#1,234`→`#1` truncation bug,
        # but a comma-grouped number is not a valid issue ref — skip it safely.
        print(
            f"native-dep-mirror: skipping ambiguous comma-grouped token "
            f"'#{m.group('target')}' (not a valid issue id)",
            file=sys.stderr,
        )
        return None
    target = int(raw_target)
    dep_type = m.group("type") or "FS"
    if m.group("offset") is not None:
        offset = int(m.group("offset"))
        if m.group("sign") == "-":
            offset = -offset
    else:
        offset = 0
    return dep_type, offset, target


def parse_body_dependencies(body: str) -> List[BodyDep]:
    """Parse the body Dependencies section into DIRECTIONAL typed edges.

    An ABSENT Dependencies section returns [] (deps are optional at intake). The
    section is sliced into labeled segments (Blocked by / Blocks / Relates to / …);
    each `#N` carries the direction of its segment:
      - Blocked by: / Depends on: / Requires → BodyDep(direction="blocked_by")
      - Blocks:                                → BodyDep(direction="blocks") (reciprocal)
      - Relates to: / sibling / pairs / …      → NOT emitted (non-blocking prose)
    Only "blocked_by" FS+0d edges are mirror-eligible (see BodyDep.is_mirror_eligible)
    — this is the #662 fix that stops `Blocks:` and `Relates to:` targets from being
    written as inverted / false native blocked-by edges. Each matched token is
    normalized (missing type → "FS"; missing offset → 0) and de-duplicated by
    (type, offset_days, target, direction).
    """
    section = extract_section_aliased(body, DEP_HEADING_ALIASES)
    if section is None:
        return []
    seen: Set[Tuple[str, int, int, str]] = set()
    deps: List[BodyDep] = []
    for kind, seg_text in _attribute_segments(section):
        if kind == "relates":
            continue  # non-blocking relationship — never mirrored
        for m in DEP_TOKEN_RE.finditer(seg_text):
            parsed = _parse_token(m)
            if parsed is None:
                continue
            dep_type, offset, target = parsed
            key = (dep_type, offset, target, kind)
            if key in seen:
                continue
            seen.add(key)
            deps.append(
                BodyDep(
                    type=dep_type,
                    offset_days=offset,
                    target=target,
                    direction=kind,
                )
            )
    return deps


def mirror_eligible_targets(deps: List[BodyDep]) -> Set[int]:
    """The FS+0d target subset — the only edges that mirror to native."""
    return {d.target for d in deps if d.is_mirror_eligible}


def compute_mirror_plan(
    body_deps: List[BodyDep], native_blocked_by: Set[int]
) -> Tuple[List[int], List[int]]:
    """Return (to_add, drift) per the A3.5 diff.

    to_add = mirror-eligible body targets absent from native (body wins; add).
    drift  = native blocked-by absent from mirror-eligible body set (flag only).
    Both sorted ascending for stable output.
    """
    eligible = mirror_eligible_targets(body_deps)
    to_add = sorted(eligible - native_blocked_by)
    drift = sorted(native_blocked_by - eligible)
    return to_add, drift


# ---- GitHub API surface (gh CLI; stdlib subprocess only) ----------------------

class GhError(RuntimeError):
    """A gh invocation failed (network / scope / not-found)."""


def _gh(args: List[str]) -> str:
    """Run a gh command; return stdout. Raise GhError on non-zero exit."""
    result = subprocess.run(["gh", *args], capture_output=True, text=True)
    if result.returncode != 0:
        raise GhError(f"gh {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout


def resolve_repo(explicit: Optional[str]) -> str:
    """Resolve OWNER/NAME — explicit arg wins; else `gh repo view`.

    Never hardcodes a repo. The explicit form is validated as OWNER/NAME shape.
    """
    if explicit:
        if "/" not in explicit or explicit.count("/") != 1:
            raise GhError(f"--repo must be OWNER/NAME, got: {explicit!r}")
        return explicit
    out = _gh(["repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"])
    repo = out.strip()
    if not repo:
        raise GhError("could not resolve repo from `gh repo view` (pass --repo OWNER/NAME)")
    return repo


def fetch_issue(repo: str, number: int) -> Dict:
    """Fetch one issue's number/title/state/body."""
    out = _gh([
        "issue", "view", str(number), "--repo", repo,
        "--json", "number,title,state,body",
    ])
    return json.loads(out)


def fetch_milestone_issues(repo: str, milestone: str) -> List[Dict]:
    """Fetch all OPEN issues in a milestone (number/title/state/body)."""
    out = _gh([
        "issue", "list", "--repo", repo, "--milestone", milestone,
        "--state", "open", "--limit", "5000",
        "--json", "number,title,state,body",
    ])
    return json.loads(out)


def resolve_issue_node_id(repo: str, number: int) -> str:
    """Resolve an issue's GraphQL node ID (required by addIssueDependency)."""
    owner, name = repo.split("/", 1)
    query = (
        'query($owner:String!,$name:String!,$num:Int!){'
        'repository(owner:$owner,name:$name){issue(number:$num){id}}}'
    )
    out = _gh([
        "api", "graphql", "-f", f"query={query}",
        "-F", f"owner={owner}", "-F", f"name={name}", "-F", f"num={number}",
        "--jq", ".data.repository.issue.id",
    ])
    node_id = out.strip()
    if not node_id:
        raise GhError(f"could not resolve node id for issue #{number}")
    return node_id


def read_native_blocked_by(repo: str, number: int) -> Set[int]:
    """Read native `blocked-by` issue numbers for an issue via GraphQL.

    Per the A3.5 / A6 spec the canonical native surface is `blockedBy`. The query
    tolerates an unavailable field set (upstream schema variance / missing scope)
    by degrading to an empty set rather than crashing — the mirror is
    non-gate-blocking and body remains authoritative.
    """
    owner, name = repo.split("/", 1)
    query = (
        'query($owner:String!,$name:String!,$num:Int!){'
        'repository(owner:$owner,name:$name){issue(number:$num){'
        'blockedBy(first:50){nodes{number}}}}}'
    )
    try:
        out = _gh([
            "api", "graphql", "-f", f"query={query}",
            "-F", f"owner={owner}", "-F", f"name={name}", "-F", f"num={number}",
            "--jq", ".data.repository.issue.blockedBy.nodes[]?.number",
        ])
    except GhError:
        # Field unavailable / scope gap — degrade to empty native set.
        return set()
    return {int(line) for line in out.split() if line.strip().lstrip("-").isdigit()}


def add_native_dependency(blocked_id: str, blocking_id: str) -> None:
    """Add a native dependency: `blocked_id` is blocked-by `blocking_id`."""
    mutation = (
        'mutation($blocked:ID!,$blocking:ID!){'
        'addIssueDependency(input:{issueId:$blocked,blockingIssueId:$blocking}){'
        'issue{id}}}'
    )
    _gh([
        "api", "graphql", "-f", f"query={mutation}",
        "-F", f"blocked={blocked_id}", "-F", f"blocking={blocking_id}",
    ])


# ---- Per-issue mirror ---------------------------------------------------------

@dataclass
class MirrorResult:
    issue: int
    eligible: List[int]        # FS+0d body targets
    native_blocked_by: List[int]
    to_add: List[int]          # planned / executed adds
    added: List[int] = field(default_factory=list)        # successfully added
    add_failures: List[Dict] = field(default_factory=list)  # {target, error}
    drift: List[int] = field(default_factory=list)         # native-extra (flag only)
    dry_run: bool = False


def mirror_issue(repo: str, number: int, body: str, dry_run: bool) -> MirrorResult:
    """Execute (or plan, when dry_run) the A3.5 mirror for one issue."""
    body_deps = parse_body_dependencies(body)
    native = read_native_blocked_by(repo, number)
    to_add, drift = compute_mirror_plan(body_deps, native)
    res = MirrorResult(
        issue=number,
        eligible=sorted(mirror_eligible_targets(body_deps)),
        native_blocked_by=sorted(native),
        to_add=to_add,
        drift=drift,
        dry_run=dry_run,
    )
    if dry_run or not to_add:
        return res
    blocked_id = resolve_issue_node_id(repo, number)
    for target in to_add:
        try:
            blocking_id = resolve_issue_node_id(repo, target)
            add_native_dependency(blocked_id, blocking_id)
            res.added.append(target)
        except GhError as e:
            # Non-gating: log the failure, continue with remaining deps.
            res.add_failures.append({"target": target, "error": str(e)})
    return res


# ---- Output formatting --------------------------------------------------------

def emit_text(results: List[MirrorResult]) -> str:
    lines: List[str] = []
    for r in results:
        verb = "PLAN" if r.dry_run else "MIRROR"
        lines.append(f"[{verb}] issue #{r.issue}")
        lines.append(f"  eligible (FS+0d body deps): {r.eligible or '(none)'}")
        lines.append(f"  native blocked-by:          {r.native_blocked_by or '(none)'}")
        if r.dry_run:
            lines.append(f"  would add:                  {r.to_add or '(none)'}")
        else:
            lines.append(f"  added:                      {r.added or '(none)'}")
            if r.add_failures:
                for f in r.add_failures:
                    lines.append(f"  ADD FAILED #{f['target']}: {f['error']}")
        if r.drift:
            lines.append(
                f"  DRIFT (native-extra, flag only): {r.drift} "
                "— body authoritative; operator-mediated reconciliation"
            )
    return "\n".join(lines)


def emit_json(results: List[MirrorResult]) -> str:
    return json.dumps([asdict(r) for r in results], indent=2)


# ---- Self-test ---------------------------------------------------------------

def run_self_test() -> int:
    """Deterministic fixtures over the parse + diff core (no network).

    Covers: typed-grammar parsing, FS+0d eligibility filtering, untyped→FS+0d
    normalization, non-FS-zero-lag exclusion, the to_add/drift diff, heading
    aliases/suffix-tolerance, idempotent no-op, absent-section clean parse, AND the
    #662 Blocker fixes — segment-directional parsing (Blocked by vs Blocks vs Relates
    to), the real improvement.yml single-line `Blocked by: — · Blocks: #N` body
    format, non-blocking-relationship exclusion, and comma-grouped `#1,234` safety.
    """
    failures: List[str] = []

    def check(name: str, got, want):
        if got != want:
            failures.append(f"{name}: got {got!r}, want {want!r}")

    # 1. Mixed typed body — only the FS+0d / untyped edges are mirror-eligible.
    body = """### Description
Stuff.

### Dependencies
- #46
- FS #47
- FS+0d #48
- SS #49
- FF #50
- SF #51
- FS+3d #52
- FS-2d #53

### Acceptance Criteria
- [ ] done
"""
    deps = parse_body_dependencies(body)
    check("parse count", len(deps), 8)
    check("eligible subset", mirror_eligible_targets(deps), {46, 47, 48})

    # 2. Typed-field normalization spot-checks.
    by_target = {d.target: d for d in deps}
    check("untyped→FS", (by_target[46].type, by_target[46].offset_days), ("FS", 0))
    check("FS+3d offset", (by_target[52].type, by_target[52].offset_days), ("FS", 3))
    check("FS-2d lag sign", by_target[53].offset_days, -2)
    check("SS not eligible", by_target[49].is_mirror_eligible, False)

    # 3. The diff: eligible {46,47,48}; native already has {47}; native-extra {99}.
    to_add, drift = compute_mirror_plan(deps, native_blocked_by={47, 99})
    check("to_add", to_add, [46, 48])
    check("drift (native-extra)", drift, [99])

    # 4. Idempotent no-op — native already mirrors every eligible edge.
    to_add2, drift2 = compute_mirror_plan(deps, native_blocked_by={46, 47, 48})
    check("idempotent to_add empty", to_add2, [])
    check("idempotent drift empty", drift2, [])

    # 5. Absent Dependencies section parses clean (deps optional at intake).
    check("absent section → []", parse_body_dependencies("### Description\nNo deps.\n"), [])

    # 6. Heading suffix-tolerance + alias resolution.
    suffixed = "### Dependencies (confirmed at Planning)\n- #200\n"
    check("suffixed heading", mirror_eligible_targets(parse_body_dependencies(suffixed)), {200})
    aliased = "### Depends on\n- #201\n- SS #202\n"
    check("alias heading", mirror_eligible_targets(parse_body_dependencies(aliased)), {201})

    # 7. De-duplication of identical tokens.
    dup = "### Dependencies\n- #300\n- FS+0d #300\n"
    # #300 untyped and #300 FS+0d are the SAME edge (FS,0,300) — de-duped to one.
    check("dedup identical edge", len(parse_body_dependencies(dup)), 1)
    check("dedup eligible", mirror_eligible_targets(parse_body_dependencies(dup)), {300})

    # 8. No false match on bare '#' or non-issue hashes inside prose.
    noise = "### Dependencies\nSee the C# notes and issue #401 only.\n"
    check("prose noise → #401 only", mirror_eligible_targets(parse_body_dependencies(noise)), {401})

    # ---- #662 Blocker fixtures (segment-directional / real-format / comma-safe) ----
    # The live improvement.yml `Dependencies` field renders as a labeled-segment line.
    # Direction-blind parsing of `Blocks:` / `Relates to:` targets was the BLOCKER:
    # it wrote inverted / false native blocked-by edges (state-mutating GraphQL writes).

    # 9. The #225-shaped case — the canonical Blocker exemplar. Real body line:
    #    "Blocked by: — (independently shippable). · Blocks: **#213** ... ·
    #     Relates to: **#149**, **#61**, **#288**"
    # TRUTH: 225 BLOCKS 213 (reciprocal), is blocked-by NOTHING, relates-to the rest.
    # The defect asserted "225 blocked-by 213" — the OPPOSITE. Assert that #213 (and
    # the relates targets) are NOT mirror-eligible and that to_add is empty.
    body_225 = (
        "## Dependencies\n\n"
        "Blocked by: — (independently shippable). · Blocks: **#213** "
        "(per the roadmap-deps block — verify at Solutioning).\n"
        "Relates to: **#149** (Stage 6 def), **#61** (decomposition protocol), "
        "**#288** (sub-task API). Scope-boundary: owns the threshold, not #288's API.\n"
    )
    deps_225 = parse_body_dependencies(body_225)
    check("#225 eligible empty (Blocks:/Relates: not mirrored)",
          mirror_eligible_targets(deps_225), set())
    check("#225 #213 NOT blocked-by(225←213)", 213 in mirror_eligible_targets(deps_225), False)
    # The Blocks: edge IS parsed (as a reciprocal record) but is not mirror-eligible.
    blocks_dirs = {d.target: d.direction for d in deps_225}
    check("#225 #213 parsed as blocks-direction", blocks_dirs.get(213), "blocks")
    check("#225 relates targets not parsed as deps",
          (149 in blocks_dirs, 61 in blocks_dirs, 288 in blocks_dirs), (False, False, False))
    to_add_225, _ = compute_mirror_plan(deps_225, native_blocked_by=set())
    check("#225 to_add empty (no false native write)", to_add_225, [])

    # 10. Real single-line form WITH a genuine blocked-by (the #149-shaped case):
    #    "Blocked by: #151 ... · Blocks: — · Pairs with (Path B set): #152, #150 ..."
    # ONLY #151 is a real blocked-by; #152/#150 (Pairs with) must NOT be mirrored.
    body_149 = (
        "## Dependencies\n"
        "Blocked by: #151 (needs its banding contract) · Blocks: — · "
        "Pairs with (Path B set): #152, #150. Coordinates with the hub primitives.\n"
    )
    deps_149 = parse_body_dependencies(body_149)
    check("#149 eligible = {151} only", mirror_eligible_targets(deps_149), {151})
    check("#149 pairs-with #152/#150 excluded",
          (152 in mirror_eligible_targets(deps_149), 150 in mirror_eligible_targets(deps_149)),
          (False, False))

    # 11. Empty-blocked-by single-line form (the #280/#61/#288-shaped case):
    #    "Blocked by: — · Blocks: — · Relates to: #33 ..." → nothing mirror-eligible.
    body_empty = (
        "## Dependencies\n\n"
        "Blocked by: — · Blocks: — · Relates to: **#33** (Bundle def), the "
        "`epic:*` / `cluster:*` taxonomy and native sub-issues.\n"
    )
    check("empty-blocked-by + relates → none eligible",
          mirror_eligible_targets(parse_body_dependencies(body_empty)), set())

    # 12. Multi-line labeled-segment variant — segments on separate lines.
    body_multiline = (
        "### Dependencies\n"
        "Blocked by: #500, #501\n"
        "Blocks: #999\n"
        "Relates to: #777\n"
    )
    deps_ml = parse_body_dependencies(body_multiline)
    check("multi-line blocked-by = {500,501}", mirror_eligible_targets(deps_ml), {500, 501})
    check("multi-line Blocks: #999 not eligible", 999 in mirror_eligible_targets(deps_ml), False)
    check("multi-line Relates: #777 not parsed",
          777 in {d.target for d in deps_ml}, False)

    # 13. Pure relates/sibling section — never mirrored even with bare `#N`.
    body_relates = "### Dependencies\nRelates to: #810. Foundational sibling to #811.\n"
    check("relates+sibling → none eligible",
          mirror_eligible_targets(parse_body_dependencies(body_relates)), set())
    check("relates+sibling → no deps parsed",
          parse_body_dependencies(body_relates), [])

    # 14. Comma-grouped `#1,234` is handled safely — NOT truncated to `#1`.
    #    The whole run is captured (so it can't silently mirror against #1) then
    #    dropped as an invalid id. A real adjacent dep on the same line still parses.
    body_comma = "### Dependencies\nBlocked by: #1,234 and #5\n"
    deps_comma = parse_body_dependencies(body_comma)
    check("comma-grouped #1,234 not mirrored as #1", 1 in mirror_eligible_targets(deps_comma), False)
    check("comma-grouped #1,234 dropped (only #5 survives)",
          mirror_eligible_targets(deps_comma), {5})

    # 15. Legacy clean bullet-list form still works (backward-compat guard):
    #    `### Dependencies\n- #46` with no labels → leading run = blocked-by.
    legacy = "### Dependencies\n- #46\n- FS #47\n- SS #48\n"
    check("legacy bullet-list blocked-by",
          mirror_eligible_targets(parse_body_dependencies(legacy)), {46, 47})

    if failures:
        print("SELF-TEST FAIL:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("SELF-TEST OK")
    return 0


# ---- Main --------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--issue", type=int, help="Single issue number to mirror")
    parser.add_argument("--milestone", help="Mirror all open issues in this milestone")
    parser.add_argument("--repo", help="OWNER/NAME; else resolved via `gh repo view`")
    parser.add_argument("--dry-run", action="store_true",
                        help="Compute + print the mirror plan; perform NO native writes")
    parser.add_argument("--output-format", choices=["text", "json"], default="text")
    parser.add_argument("--self-test", action="store_true",
                        help="Run deterministic fixtures (no network)")
    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    if not args.issue and not args.milestone:
        print("ERROR: provide --issue N or --milestone TITLE (or --self-test)",
              file=sys.stderr)
        return 2

    try:
        repo = resolve_repo(args.repo)
        if args.milestone:
            raw_issues = fetch_milestone_issues(repo, args.milestone)
        else:
            raw_issues = [fetch_issue(repo, args.issue)]
    except GhError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    results: List[MirrorResult] = []
    api_error = False
    for raw in raw_issues:
        try:
            results.append(
                mirror_issue(repo, raw["number"], raw.get("body") or "", args.dry_run)
            )
        except GhError as e:
            print(f"ERROR: issue #{raw.get('number')}: {e}", file=sys.stderr)
            api_error = True

    if args.output_format == "json":
        print(emit_json(results))
    else:
        print(emit_text(results))

    if api_error:
        return 2
    if any(r.add_failures for r in results):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

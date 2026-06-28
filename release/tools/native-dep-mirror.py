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
  - Eligible body deps: `FS+0d #N` ONLY (default / untyped `#N` normalizes to
    FS+0d). Non-FS-zero-lag types (`SS`, `FF`, `SF`, `FS±Nd`) are body-only by
    design — native `blocks`/`blocked-by` has only one semantic and cannot
    express them, so they are NEVER mirrored.
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

SECTION_HEADING_RE = re.compile(r"^###\s+", re.MULTILINE)

DEP_HEADING_ALIASES = [
    "Dependencies",
    "Dependency",
    "Depends on",
    "Blocked by",
    "Relationships",
]

# One dependency token. Type prefix + offset optional; hash-ref required.
# Examples matched: "#46", "FS #46", "FS+0d #46", "SS #46", "FS+3d #46",
# "FS-2d #46". Anchored to a token boundary so "##" or "#46abc" do not match.
DEP_TOKEN_RE = re.compile(
    r"(?P<type>FS|SS|FF|SF)?\s*"
    r"(?:(?P<sign>[+-])(?P<offset>\d+)d)?\s*"
    r"#(?P<target>\d+)\b"
)


@dataclass
class BodyDep:
    """A single parsed body dependency edge."""
    type: str          # "FS" | "SS" | "FF" | "SF"
    offset_days: int   # signed integer; 0 when omitted
    target: int        # the referenced issue number

    @property
    def is_mirror_eligible(self) -> bool:
        """Only FS with zero lag mirrors to native (Model A subset rule)."""
        return self.type == "FS" and self.offset_days == 0


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


def parse_body_dependencies(body: str) -> List[BodyDep]:
    """Parse the body Dependencies section into typed edges.

    An ABSENT Dependencies section returns [] (deps are optional at intake). Each
    matched token is normalized: missing type → "FS"; missing offset → 0. Returns
    one BodyDep per `#N` reference, de-duplicated by (type, offset_days, target).
    """
    section = extract_section_aliased(body, DEP_HEADING_ALIASES)
    if section is None:
        return []
    seen: Set[Tuple[str, int, int]] = set()
    deps: List[BodyDep] = []
    for m in DEP_TOKEN_RE.finditer(section):
        dep_type = m.group("type") or "FS"
        if m.group("offset") is not None:
            offset = int(m.group("offset"))
            if m.group("sign") == "-":
                offset = -offset
        else:
            offset = 0
        target = int(m.group("target"))
        key = (dep_type, offset, target)
        if key in seen:
            continue
        seen.add(key)
        deps.append(BodyDep(type=dep_type, offset_days=offset, target=target))
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
    aliases/suffix-tolerance, idempotent no-op, and absent-section clean parse.
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

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
  - UNLABELLED PROSE IS NOT A DEPENDENCY CLAIM. A Dependencies section whose text
    carries no direction label yields NO mirror-eligible edge: prose states no
    direction, so asserting one is invention. The bare-`#N` backward-compat shim
    applies ONLY to the legacy bare-ref list form it was written for (`- #46`),
    never to free-form sentences. Such refs are reported as `unattributed` so a
    real dependency stated only in prose surfaces for relabelling instead of being
    silently dropped. An epic / parent reference is a sub-issue relationship, not a
    dependency, and is never mirror-eligible in EITHER position — unlabelled prose
    ("Part of epic #N") or trailing a still-open `Blocked by:` segment.
  - to_add  = eligible body deps NOT present in native blocked-by → add via the
    GraphQL `addBlockedBy` mutation, falling back to the REST dependencies
    endpoint when that call fails (body wins; auto-resolve).
  - drift   = native blocked-by NOT present in eligible body deps → FLAGGED for
    operator review; body is NOT auto-modified (body remains authoritative).
  - Idempotent: re-running with the same body state is a no-op (modulo the API's
    eventual-consistency window).
  - The direction grammar is implemented once, in bundle-issues-parser.py beside this
    tool; this tool loads it by path and binds it, so the A3.5 mirror and the parser's
    parse_dependencies read one grammar. A blocked_by label negated on its own line
    ("not blocked by #N", "gated on, not blocked by") is non-blocking: never mirrored.

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

  # Write-surface smoke check — introspect the schema, write nothing, exit
  # non-zero if the mirror has no usable write path at all:
  python3 native-dep-mirror.py --verify-write-surface

Exit codes:
  0 — mirror completed (or dry-run plan produced) with no add failures
  1 — one or more native add operations failed on an EDGE-level cause (dep cap,
      per-issue permission, transient API); operator awareness, non-gating
  2 — API / network / scope failure resolving repo or reading issue/native deps,
      OR the parser beside this tool (bundle-issues-parser.py, the home of the
      section extractor and the direction grammar this tool reads bodies through)
      cannot be loaded,
      OR a CONTRACT-level write failure (the write surface itself is broken —
      e.g. the mutation field is absent from the schema AND the REST fallback
      also failed). A contract breach is deliberately NOT reported as exit 1:
      conflating "this API no longer exists" with "this one edge failed" is what
      let a dead write path run unnoticed across releases.
"""

import argparse
import importlib.util
import json
import subprocess
import sys
from dataclasses import dataclass, asdict, field
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple


# ---- Dependency grammar and section extractor: read from bundle-issues-parser.py ----
#
# The Dependencies-section grammar this tool mirrors from — the typed token grammar
# (`[TYPE][OFFSET] #N`, untyped normalizing to FS+0d), the labeled-segment direction
# rules (Blocked by / Depends on / Requires -> blocked_by; Blocks -> the reciprocal;
# Relates to / Part of epic / sibling / ... -> non-blocking; unlabelled prose -> no
# direction, reported as unattributed; a negated label -> non-blocking), the closed
# heading alias set and the section extractor — lives once, in bundle-issues-parser.py,
# beside this tool. It is loaded by path (see _load_bip below) and its public names are
# bound here, so the mirror and the parser's parse_dependencies read one grammar and a
# fix to it lands once. Only the mirror semantics stay in this file: which parsed edges
# are mirror-eligible (FS+0d blocked_by — BodyDep.is_mirror_eligible, defined with the
# grammar) and the to_add / drift diff below.

_BIP_PATH = Path(__file__).resolve().parent / "bundle-issues-parser.py"


def _load_bip():
    """-> (module, None) or (None, cause). Never raises; modelled on the parser's own
    _load_doc_gates. A failed load is reported by main() and run_self_test() as exit 2,
    the infrastructure-failure class, never as an import-time traceback (exit 1, which
    this tool reserves for an edge-level add failure)."""
    try:
        if not _BIP_PATH.is_file():
            raise FileNotFoundError(f"{_BIP_PATH.name} not found beside {Path(__file__).name}")
        spec = importlib.util.spec_from_file_location("bundle_issues_parser", _BIP_PATH)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]
        return mod, None
    except Exception as e:  # noqa: BLE001 — reported by main(), never raised at import
        return None, f"{type(e).__name__}: {e}"


_BIP, _BIP_CAUSE = _load_bip()
if _BIP is not None:
    # The names this tool has always exposed, now bound from their one home. Two
    # separately loaded copies of the parser are distinct module objects, so nothing
    # here type-checks an object from one copy against a class from another.
    DEP_HEADING_ALIASES = _BIP.DEP_HEADING_ALIASES
    extract_section_with_alias = _BIP.extract_section_with_alias
    extract_section_aliased = _BIP.extract_section_aliased
    # The direction grammar (moved from this file).
    SEGMENT_LABELS = _BIP.SEGMENT_LABELS
    DEP_TOKEN_RE = _BIP.DEP_TOKEN_RE
    DIRECTIONAL_HEADINGS = _BIP.DIRECTIONAL_HEADINGS
    BodyDep = _BIP.BodyDep
    parse_body_dependencies = _BIP.parse_body_dependencies
    unattributed_refs = _BIP.unattributed_refs


def mirror_eligible_targets(deps: "List[BodyDep]") -> Set[int]:
    """The FS+0d target subset — the only edges that mirror to native."""
    return {d.target for d in deps if d.is_mirror_eligible}


def compute_mirror_plan(
    body_deps: "List[BodyDep]", native_blocked_by: Set[int]
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

# The GraphQL mutation that adds a native blocked-by edge. Named as a constant so
# the preflight introspection and the mutation string can never drift apart — the
# dead-write-path incident was exactly a name the code asserted and nothing checked.
# The historical value `addIssueDependency` has NEVER existed on the Mutation type;
# the input shape (issueId + blockingIssueId) was always right, only the field name
# was wrong.
NATIVE_DEP_MUTATION = "addBlockedBy"


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
    """Resolve an issue's GraphQL node ID (required by the addBlockedBy mutation)."""
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


def resolve_issue_database_id(repo: str, number: int) -> int:
    """Resolve an issue's REST database id — the REST fallback's `issue_id`.

    This is NOT the GraphQL node id. The two id spaces are not interchangeable and
    the REST dependencies endpoint takes the numeric database id; passing a node id
    (or an issue NUMBER, which also looks plausible) mis-targets silently rather
    than erroring. Kept as a separate named function so the distinction is visible
    at every call site.
    """
    out = _gh(["api", f"repos/{repo}/issues/{number}", "--jq", ".id"])
    raw = out.strip()
    if not raw.isdigit():
        raise GhError(f"could not resolve database id for issue #{number}: {raw!r}")
    return int(raw)


def add_dependency_graphql(blocked_node_id: str, blocking_node_id: str) -> None:
    """Primary write path — the addBlockedBy mutation (GraphQL node ids)."""
    mutation = (
        'mutation($blocked:ID!,$blocking:ID!){'
        f'{NATIVE_DEP_MUTATION}(input:{{issueId:$blocked,blockingIssueId:$blocking}}){{'
        'issue{id}}}'
    )
    _gh([
        "api", "graphql", "-f", f"query={mutation}",
        "-F", f"blocked={blocked_node_id}", "-F", f"blocking={blocking_node_id}",
    ])


def add_dependency_rest(repo: str, blocked_number: int, blocking_db_id: int) -> None:
    """Fallback write path — the REST dependencies endpoint (database id)."""
    _gh([
        "api", "-X", "POST",
        f"repos/{repo}/issues/{blocked_number}/dependencies/blocked_by",
        "-F", f"issue_id={blocking_db_id}",
    ])


def mutation_field_exists(field: str) -> Optional[bool]:
    """Does `field` exist on the GraphQL Mutation type?

    True / False, or None when introspection itself failed (offline, no scope) —
    None is 'unknown', deliberately distinct from False ('confirmed absent'), so an
    unreachable API is never mistaken for a renamed one.
    """
    query = 'query{__type(name:"Mutation"){fields(includeDeprecated:true){name}}}'
    try:
        out = _gh([
            "api", "graphql", "-f", f"query={query}",
            "--jq", ".data.__type.fields[].name",
        ])
    except GhError:
        return None
    return field in set(out.split())


def _is_already_present(err: str) -> bool:
    """True when the API is reporting the edge already exists (idempotent success).

    The mirror's documented contract is that re-running against unchanged body state
    is a no-op. to_add is a set difference, so this normally cannot fire — but the
    native surface is eventually consistent, so a just-written edge can still be
    missing from the read. Counting that as a failure would make a correct mirror
    look broken.
    """
    low = err.lower()
    return "already been taken" in low or "already exists" in low


def classify_add_failure(err: str, graphql_available: Optional[bool]) -> str:
    """Classify an add failure as "contract" (surface broken) or "edge" (this edge).

    Deliberately conservative: only DEFINITE evidence of surface breakage escalates
    to contract — the preflight confirming the mutation is absent, or the API naming
    an undefined field. Everything else (dep cap, per-issue permission, transient
    5xx) is edge-level and stays non-gating.

    This split is the actual fix for the dead-write-path incident. The old code had
    one undifferentiated failure bucket, so "this API no longer exists" and "this
    one edge failed" were indistinguishable — and because the mirror is non-gating
    by design, the former was absorbed as routine noise across releases.
    """
    low = err.lower()
    if graphql_available is False:
        return "contract"
    if "undefinedfield" in low or "doesn't exist on type" in low:
        return "contract"
    return "edge"


class NativeDepWriter:
    """Writes native blocked-by edges: GraphQL primary, REST fallback.

    Holds the per-run preflight result and memoizes id lookups, so a milestone run
    introspects the schema once rather than once per edge. The two surfaces use
    different id spaces (node id vs database id), which is why resolution is lazy —
    the REST database id is only fetched if GraphQL actually fails.
    """

    def __init__(self, repo: str) -> None:
        self.repo = repo
        self.graphql_available: Optional[bool] = None
        self._checked = False
        self._node_ids: Dict[int, str] = {}
        self._db_ids: Dict[int, int] = {}

    def preflight(self) -> Optional[bool]:
        """Introspect the write surface once; warn loudly if the primary is gone."""
        if self._checked:
            return self.graphql_available
        self._checked = True
        self.graphql_available = mutation_field_exists(NATIVE_DEP_MUTATION)
        if self.graphql_available is False:
            print(
                f"native-dep-mirror: CONTRACT WARNING — GraphQL mutation "
                f"`{NATIVE_DEP_MUTATION}` is ABSENT from the schema. The primary "
                f"write path is dead; falling back to REST for every edge. Correct "
                f"the mutation name before trusting future runs "
                f"(`--verify-write-surface` checks this without writing).",
                file=sys.stderr,
            )
        elif self.graphql_available is None:
            print(
                "native-dep-mirror: could not introspect the GraphQL schema "
                "(offline or missing scope) — attempting the primary path anyway.",
                file=sys.stderr,
            )
        return self.graphql_available

    def _node_id(self, number: int) -> str:
        if number not in self._node_ids:
            self._node_ids[number] = resolve_issue_node_id(self.repo, number)
        return self._node_ids[number]

    def _db_id(self, number: int) -> int:
        if number not in self._db_ids:
            self._db_ids[number] = resolve_issue_database_id(self.repo, number)
        return self._db_ids[number]

    def add(self, blocked_number: int, blocking_number: int) -> str:
        """Write one edge. Returns the surface used: "graphql" | "rest" | "exists".

        Raises GhError with a "<surface>: <error>" trail only when BOTH paths fail.
        """
        self.preflight()
        errors: List[str] = []
        if self.graphql_available is not False:
            try:
                add_dependency_graphql(
                    self._node_id(blocked_number), self._node_id(blocking_number)
                )
                return "graphql"
            except GhError as e:
                if _is_already_present(str(e)):
                    return "exists"
                errors.append(f"graphql: {e}")
        try:
            add_dependency_rest(
                self.repo, blocked_number, self._db_id(blocking_number)
            )
            return "rest"
        except GhError as e:
            if _is_already_present(str(e)):
                return "exists"
            errors.append(f"rest: {e}")
        raise GhError("; ".join(errors))


# ---- Per-issue mirror ---------------------------------------------------------

@dataclass
class MirrorResult:
    issue: int
    eligible: List[int]        # FS+0d body targets
    native_blocked_by: List[int]
    to_add: List[int]          # planned / executed adds
    added: List[int] = field(default_factory=list)        # successfully added
    add_failures: List[Dict] = field(default_factory=list)  # {target, error, kind}
    drift: List[int] = field(default_factory=list)         # native-extra (flag only)
    unattributed: List[int] = field(default_factory=list)  # prose refs, no direction
    surfaces: Dict[str, int] = field(default_factory=dict)  # graphql/rest/exists tally
    dry_run: bool = False

    @property
    def has_contract_failure(self) -> bool:
        """Any failure attributable to the write SURFACE rather than one edge."""
        return any(f.get("kind") == "contract" for f in self.add_failures)


def mirror_issue(
    repo: str,
    number: int,
    body: str,
    dry_run: bool,
    writer: Optional[NativeDepWriter] = None,
) -> MirrorResult:
    """Execute (or plan, when dry_run) the A3.5 mirror for one issue.

    `writer` is threaded in by the caller so a milestone run shares one preflight
    and one id cache across every issue; omitted, a private writer is created.
    """
    body_deps = parse_body_dependencies(body)
    native = read_native_blocked_by(repo, number)
    to_add, drift = compute_mirror_plan(body_deps, native)
    res = MirrorResult(
        issue=number,
        eligible=sorted(mirror_eligible_targets(body_deps)),
        native_blocked_by=sorted(native),
        to_add=to_add,
        drift=drift,
        unattributed=unattributed_refs(body),
        dry_run=dry_run,
    )
    if dry_run or not to_add:
        return res
    if writer is None:
        writer = NativeDepWriter(repo)
    for target in to_add:
        try:
            surface = writer.add(number, target)
            res.added.append(target)
            res.surfaces[surface] = res.surfaces.get(surface, 0) + 1
        except GhError as e:
            # Non-gating for edge-level causes; classified so a surface-level
            # breakage is NOT absorbed as routine per-edge noise.
            res.add_failures.append({
                "target": target,
                "error": str(e),
                "kind": classify_add_failure(str(e), writer.graphql_available),
            })
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
            if r.surfaces:
                tally = ", ".join(f"{k}={v}" for k, v in sorted(r.surfaces.items()))
                lines.append(f"  write surface:              {tally}")
            for f in r.add_failures:
                tag = "CONTRACT" if f.get("kind") == "contract" else "EDGE"
                lines.append(f"  ADD FAILED [{tag}] #{f['target']}: {f['error']}")
        if r.drift:
            lines.append(
                f"  DRIFT (native-extra, flag only): {r.drift} "
                "— body authoritative; operator-mediated reconciliation"
            )
        if r.unattributed:
            lines.append(
                f"  WARNING unattributed refs:  {r.unattributed} — present in the "
                "Dependencies section but under no direction label, so NOT mirrored. "
                "Relabel under `Blocked by:` if these are real dependencies."
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
    if _BIP is None:
        print(f"ERROR: native-dep-mirror cannot load its parser: {_BIP_CAUSE}", file=sys.stderr)
        return 2
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

    # 8. No false match on bare '#' or non-issue hashes ('C#') inside a segment.
    #    Deliberately placed under an explicit label so this fixture asserts TOKEN
    #    matching ONLY; direction is cases 16-20's subject. Pre-fix this body was
    #    unlabelled prose expecting {401}, which quietly encoded the very default
    #    being removed here — prose read as a blocked-by claim. The C#-must-not-match
    #    intent is preserved exactly; only the direction assumption is dropped.
    noise = "### Dependencies\nBlocked by: the C# notes and issue #401 only.\n"
    check("token match skips 'C#', finds #401",
          mirror_eligible_targets(parse_body_dependencies(noise)), {401})

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

    # ---- Dead-write-path + prose-attribution regression fixtures ---------------
    # Two defects found on a live release run. Both are recurrences of the class the
    # module header records — an edge asserted that the body never stated — which is
    # why they are frozen as fixtures rather than point-fixed.

    # 16. THE PROSE DEFECT. A Dependencies section of free-form sentences that names
    #     an epic. Pre-fix this planned `would add: [1189]`: the parent epic written
    #     as a native blocker (an epic is a sub-issue parent, not a dependency),
    #     while every real edge was missed. No label anywhere → nothing eligible.
    body_prose_epic = (
        "### Dependencies\n\n"
        "**Gated on** the host-decision **spike** and on the instrumentation "
        "stories (emit autonomous seams; stable join-key + emission gate) — "
        "building on a 5/8-empty, mis-keyed stream is premature. Composes the "
        "coverage-scorecard **task**. Part of epic **#1189**.\n\n"
        "### Acceptance Criteria\n"
    )
    deps_prose = parse_body_dependencies(body_prose_epic)
    check("prose section → no eligible edges",
          mirror_eligible_targets(deps_prose), set())
    check("prose epic ref is NOT a blocker",
          1189 in mirror_eligible_targets(deps_prose), False)
    to_add_prose, _ = compute_mirror_plan(deps_prose, native_blocked_by=set())
    check("prose section → no native write", to_add_prose, [])

    # 17. THE LABELLED-BODY VARIANT — the worse case, and the reason the epic label
    #     is needed independently of the prose rule. A CORRECT `Blocked by:` label
    #     plus a trailing epic ref: pre-fix the epic was swallowed by the still-open
    #     Blocked by: segment (segments run to the next RECOGNIZED label), so a
    #     well-formed body ALSO produced a false blocker. Authoring discipline alone
    #     could not have avoided this.
    body_labelled_epic = (
        "### Dependencies\n"
        "Blocked by: #4024, #4025, #4026\n"
        "Part of epic **#1189**.\n"
    )
    check("labelled body keeps its real edges",
          mirror_eligible_targets(parse_body_dependencies(body_labelled_epic)),
          {4024, 4025, 4026})
    check("trailing epic excluded from an open Blocked by: segment",
          1189 in mirror_eligible_targets(parse_body_dependencies(body_labelled_epic)),
          False)

    # 18. Unattributed refs are REPORTED, never silently dropped. A section naming
    #     real dependencies only in prose yields no edges AND a non-empty warning —
    #     the shape that says "an author meant something here; relabel it".
    body_prose_refs = (
        "### Dependencies\n"
        "Gated on the host-decision spike #4024 and the instrumentation work "
        "in #4025.\n"
    )
    check("prose refs → nothing mirrored",
          mirror_eligible_targets(parse_body_dependencies(body_prose_refs)), set())
    check("prose refs → surfaced for relabelling",
          unattributed_refs(body_prose_refs), [4024, 4025])
    check("labelled section reports no unattributed refs",
          unattributed_refs(body_labelled_epic), [])

    # 19. A DIRECTIONAL HEADING is itself the label. `### Depends on` states the
    #     direction, so prose beneath it IS a blocked-by list — the prose rule must
    #     not over-correct and discard these.
    check("directional heading confers direction",
          mirror_eligible_targets(parse_body_dependencies(
              "### Depends on\nNeeds the parser work in #201 to land first.\n")),
          {201})
    check("ambiguous heading confers none",
          mirror_eligible_targets(parse_body_dependencies(
              "### Dependencies\nNeeds the parser work in #201 to land first.\n")),
          set())

    # 20. Bare-token runs without list markers remain the legacy blocked-by form.
    check("bare token run stays blocked-by",
          mirror_eligible_targets(parse_body_dependencies("### Dependencies\n#46, #47\n")),
          {46, 47})

    # 21. THE DEAD WRITE PATH. The mutation name is a constant the preflight
    #     introspects, so the query string and the smoke check cannot disagree.
    #     `addIssueDependency` never existed on the Mutation type; the input shape
    #     (issueId + blockingIssueId) was always correct.
    check("write mutation is the real field", NATIVE_DEP_MUTATION, "addBlockedBy")
    check("dead mutation name is gone",
          NATIVE_DEP_MUTATION == "addIssueDependency", False)

    # 22. FAILURE CLASSIFICATION — the split that stops a broken write surface from
    #     being absorbed as routine per-edge noise under the non-gating posture.
    check("undefined-field error → contract",
          classify_add_failure("Field 'x' doesn't exist on type 'Mutation'", True),
          "contract")
    check("confirmed-absent mutation → contract",
          classify_add_failure("some transient blip", False), "contract")
    check("dep-cap error → edge",
          classify_add_failure("dependency cap reached (50)", True), "edge")
    check("unknown introspection does not force contract",
          classify_add_failure("connection reset", None), "edge")
    check("already-present is idempotent success, not failure",
          _is_already_present("Validation failed: Target issue has already been taken"),
          True)

    # 23. BLANK LINES AFTER THE HEADING. The section extractor (read from the parser)
    #     used to end a section at the first two-blank-line run, and that search began
    #     at the heading line's own newline — so a heading followed by two or three
    #     blank lines read as an empty section and mirrored nothing, exiting 0.
    for blanks in (2, 3):
        check(f"{blanks} blank lines after the heading still mirror",
              mirror_eligible_targets(parse_body_dependencies(
                  "### Dependencies" + "\n" * (blanks + 1) + "Blocked by: FS+0d #6396 — x.\n")),
              {6396})

    # 24. A DOUBLED BLANK LINE INSIDE the section reads as a single one: only a
    #     heading or a break line ends a section, never whitespace.
    check("doubled internal blank line keeps both edges",
          mirror_eligible_targets(parse_body_dependencies(
              "### Dependencies\n\nBlocked by: #5\n\n\nBlocked by: #6\n\n### Notes\nx\n")),
          {5, 6})

    # 25. A NEGATED LABEL is not a blocker. "Gated on #N, not blocked by #M" names a
    #     coordination relation and disclaims the edge; the grammar (read from the
    #     parser) attributes the negated label as non-blocking, so #M is never written
    #     as a native blocked-by. A real label on the next line still mirrors.
    body_negated = "### Dependencies\nGated on #5232, not blocked by #5277.\nBlocked by: #6000\n"
    deps_negated = parse_body_dependencies(body_negated)
    check("negated label is not mirror-eligible", mirror_eligible_targets(deps_negated), {6000})
    check("negated label plans no native write",
          compute_mirror_plan(deps_negated, native_blocked_by=set())[0], [6000])
    check("the prose ref before the negation is surfaced", unattributed_refs(body_negated), [5232])

    if failures:
        print("SELF-TEST FAIL:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("SELF-TEST OK")
    return 0


# ---- Write-surface smoke assertion -------------------------------------------

def verify_write_surface() -> int:
    """Smoke assertion: does the mirror still have its primary write path?

    Writes nothing. Exits non-zero when the mutation the tool depends on is absent
    from the schema — precisely the failure the tool previously could not tell apart
    from routine per-edge noise. Cheap enough to run in CI, which is the point: an
    upstream rename should turn a check red rather than quietly degrade releases.

    "Unknown" (introspection unreachable) exits non-zero too. A check that cannot
    see the schema has not verified anything, and reporting that as a pass would
    reintroduce the exact silence this guard exists to remove.
    """
    present = mutation_field_exists(NATIVE_DEP_MUTATION)
    if present is True:
        print(f"WRITE SURFACE OK: Mutation.{NATIVE_DEP_MUTATION} present")
        return 0
    if present is None:
        print(
            "WRITE SURFACE UNKNOWN: schema introspection failed (offline or missing "
            "scope). Inconclusive — not a pass.",
            file=sys.stderr,
        )
        return 2
    print(
        f"WRITE SURFACE BROKEN: Mutation.{NATIVE_DEP_MUTATION} is ABSENT from the "
        f"schema. The mirror's primary write path cannot work and every edge would "
        f"fall through to the REST fallback. Re-check the upstream mutation name.",
        file=sys.stderr,
    )
    return 2


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
    parser.add_argument("--verify-write-surface", action="store_true",
                        help="Introspect the write surface and exit; writes nothing")
    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    if args.verify_write_surface:
        return verify_write_surface()

    if not args.issue and not args.milestone:
        print("ERROR: provide --issue N or --milestone TITLE (or --self-test)",
              file=sys.stderr)
        return 2

    # Every path below reads issue bodies through the parser's extractor.
    if _BIP is None:
        print(f"ERROR: native-dep-mirror cannot load its parser: {_BIP_CAUSE}", file=sys.stderr)
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

    # One writer per run: a single preflight and a shared id cache across issues.
    writer = None if args.dry_run else NativeDepWriter(repo)
    results: List[MirrorResult] = []
    api_error = False
    for raw in raw_issues:
        try:
            results.append(
                mirror_issue(
                    repo, raw["number"], raw.get("body") or "", args.dry_run, writer
                )
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
    if any(r.has_contract_failure for r in results):
        # Exit 2, not 1: a broken write SURFACE is an API failure, not the
        # non-gating per-edge condition exit 1 denotes.
        print(
            "ERROR: at least one add failed at the CONTRACT level — the native "
            "write surface itself is broken, not a single edge. Run "
            "`--verify-write-surface` to confirm.",
            file=sys.stderr,
        )
        return 2
    if any(r.add_failures for r in results):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

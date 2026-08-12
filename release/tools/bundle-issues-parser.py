#!/usr/bin/env python3
"""Bundle Issues Parser — shared-tool for release-planner Bundle mode.

Provides parse_affected_files() + parse_dependencies() from a single GitHub API
read pass. Consumed by release-planner Mode A/B per ADR-1 and ADR-2 contention
output. Companion to dependency-analysis.md Kahn's algorithm.

Per CR Conflict A resolution: single shared tool with umbrella name
'bundle-issues-parser.py' rather than per-concern tools. Stdlib-only Python 3.9+;
matches check-doc-links.py / lint_release_corpus.py precedent.

Parse semantics (#291 v3.20 robustification — DS-1..DS-4 of the ratified Stage 5 spec):
  - Section headings are matched suffix-tolerantly (a trailing parenthetical/colon
    no longer defeats the match) and against a closed alias set (e.g. "Files Affected").
  - Affected-Files paths are extracted by extension-token OR module-prefixed-dir
    matching (bare filenames, skill-relative paths, and `core/`|`release/`|`operations/`
    prefixes all recognized), from bullet AND prose lines.
  - A MISSING Dependencies section parses CLEAN (deps are optional at intake per
    improvement.yml and absent from bug/observation/adr templates) — previously it
    parsed FAILED, a false negative. An AF section with an explicit no-files
    declaration ("None — label-only") parses CLEAN with zero files.
  - The conformant-bundleable parse target (improvement|bug bodies with a recognized
    AF heading) is measured at >=90% combined-clean; the release-planner Mode A
    pre-filter (a separate SKILL.md change, not in this tool) sets aside bodies with
    no recognized AF heading.
  - Priority is sourced from the issue BODY field, never from a label
    (label-taxonomy.md rule 5: priority is body-tracked; no `priority:` label exists).
    One carrier-agnostic detector spans "Priority" (improvement) and "Severity" (bug)
    in both heading and bold-inline form, per gate-criteria-spec.md Gate 1 Adapter
    G1-06-Bug — the P-level DIGIT is the canonical satisfier; the qualifier word is
    discarded. Absent / word-only / out-of-range => None, which sorts LAST in the
    tie-breaker and NEVER contributes to parse_status.

Usage:
  python3 bundle-issues-parser.py --milestone "v2.10-..." [--output-format json|tsv|github]
  python3 bundle-issues-parser.py --issues 46,49,57 [--output-format json]
  echo "46\\n49\\n57" | python3 bundle-issues-parser.py [--output-format json]
  python3 bundle-issues-parser.py --self-test

Exit codes:
  0 — clean parse all issues
  1 — parse failure on >=1 issue (operator action required)
  2 — API/network failure (retry recommended)
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, asdict
from typing import List, Set, Dict, Optional, Tuple


# ---- Data classes (stdlib only) -----------------------------------------------

@dataclass
class FileRecord:
    path: str
    intent: str  # one of: edit, add, delete


@dataclass
class IssueRecord:
    number: int
    title: str
    state: str
    labels: List[str]
    priority: Optional[str]  # P1/P2/P3/P4/None
    milestone: Optional[str]
    parse_status: str  # one of: clean, deferred, failed
    affected_files: List[FileRecord]
    dependencies: List[int]  # sorted ascending
    # #4232 — AC presence axis. Additive and DEFAULTED, so every positional
    # constructor already in the tree keeps working unchanged. Absence is data,
    # never a parse failure: neither field feeds parse_status.
    ac_present: bool = False
    ac_count: int = 0


# ---- Parsing functions --------------------------------------------------------

DEFERRAL_MARKER = "[ASSUMPTION – CONFIRM] TBD — identified in Planning"
SECTION_HEADING_RE = re.compile(r"^###\s+", re.MULTILINE)

# DS-2 (#291) — heading-variant alias sets. Closed, evidence-bounded sets drawn
# from the live open-issue corpus survey (#461 Stage 5 spec); NOT fuzzy matching.
# First-match-wins; ordered most-common first.
AF_HEADING_ALIASES = [
    "Affected Files",
    "Files Affected",
    "Affected surfaces",
    "Affected file",
    "Affected paths",
    "Files / surfaces affected",
]
DEP_HEADING_ALIASES = [
    "Dependencies",
    "Dependency",
    "Depends on",
    "Blocked by",
    "Relationships",
]

# DS-3 (#291) — generalized path extraction. Replaces the legacy
# BACKTICK_PATH_RE (required an internal '/') → WORKSPACE_PATH_RE (required a
# known top-level prefix) cascade, which missed bare filenames (`PMO.md`,
# `deploy.sh`), skill-relative paths (`delivery-engine/references/x.md`), and the
# current module prefixes (`core/`, `release/`, `operations/`). Two ordered
# matchers, backticked-or-not:
#   1. EXT_PATH_RE  — any extension-bearing token (captures bare + relative + prefixed)
#   2. DIR_PATH_RE  — module-prefixed trailing-slash directory tokens
EXT_PATH_RE = re.compile(
    r"`?([A-Za-z0-9_][A-Za-z0-9_./-]*\.(?:md|py|sh|ya?ml|toml|json|txt|j2|cfg))`?"
)
DIR_PATH_RE = re.compile(
    r"`?((?:core|release|operations|docs|packages|pmo-platform|\.claude|projects|memory|\.github)"
    r"/[A-Za-z0-9_./-]*)`?"
)
# DS-4 (#291) — explicit no-files declaration inside a present AF section
# (e.g. "None — label-only update", "no file changes"). Marks the section clean
# with zero files rather than failed.
NONE_FILES_RE = re.compile(
    r"^\s*[-*]?\s*(?:none\b|no file changes\b|no files\b|n/?a\b|label-only\b)",
    re.IGNORECASE,
)

INTENT_RE = re.compile(
    r"\((add|edit|delete)\s*(?:—|--|-)\s*[^)]*\)", re.IGNORECASE
)
DEP_RE = re.compile(r"#(\d+)")


def extract_section(body: str, heading: str) -> Optional[str]:
    """Extract content of a '## <heading>' section until next H2/H3 or two blank lines.

    DS-1 (#291): heading match is prefix-anchored and suffix-tolerant — a trailing
    parenthetical or colon (e.g. '### Affected Files (proposed)', '## Affected Files:')
    no longer defeats the match. Monotonic widening: `\\b[^\\n]*$` is a superset of the
    prior `\\s*$`, so no previously-matched heading is lost.
    """
    if not body:
        return None
    # Find the heading (case-insensitive, prefix-anchored, suffix-tolerant)
    pat = re.compile(
        rf"^#{{2,4}}\s+{re.escape(heading)}\b[^\n]*$", re.MULTILINE | re.IGNORECASE
    )
    m = pat.search(body)
    if not m:
        return None
    start = m.end()
    # End at next H2/H3 or two blank lines
    rest = body[start:]
    end_h = SECTION_HEADING_RE.search(rest)
    end_h2 = re.search(r"^##\s+", rest, re.MULTILINE)
    end_blank = re.search(r"\n\s*\n\s*\n", rest)
    candidates = [c.start() for c in [end_h, end_h2, end_blank] if c is not None]
    if candidates:
        return rest[: min(candidates)]
    return rest


def extract_section_aliased(body: str, aliases: List[str]) -> Optional[str]:
    """DS-2 (#291): return the first section matching any heading alias (first-match-wins)."""
    for heading in aliases:
        section = extract_section(body, heading)
        if section is not None:
            return section
    return None


def _extract_paths(text: str) -> List[str]:
    """DS-3 (#291): extract file-path tokens from a line of AF text.

    Ordered: extension-bearing tokens first (bare/relative/prefixed, backticked or
    not), then module-prefixed trailing-slash directory tokens. Dedup preserving order.
    """
    paths: List[str] = []
    for m in EXT_PATH_RE.finditer(text):
        paths.append(m.group(1))
    for m in DIR_PATH_RE.finditer(text):
        p = m.group(1)
        if p not in paths:
            paths.append(p)
    seen: Set[str] = set()
    ordered: List[str] = []
    for p in paths:
        if p not in seen:
            seen.add(p)
            ordered.append(p)
    return ordered


def parse_affected_files(body: str) -> Tuple[List[FileRecord], str]:
    """Extract Affected Files records. Returns (files, parse_status).

    DS-2/DS-3/DS-4 (#291): alias-aware heading match; generalized path extraction
    (bullets AND prose lines); a present-but-explicit-None section ('None — label-only')
    returns clean with zero files rather than failed. A present section with bullets
    but zero parseable paths and no None-marker stays failed (prose/component-name —
    genuinely unparseable; routes to the Mode A set-aside or body-repair queue).
    """
    section = extract_section_aliased(body, AF_HEADING_ALIASES)
    if section is None:
        return [], "failed"
    if DEFERRAL_MARKER in section:
        return [], "deferred"
    content_lines = [ln.strip() for ln in section.splitlines() if ln.strip()]
    files: List[FileRecord] = []
    for line in section.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("-") or line.startswith("*"):
            item = line.lstrip("-* ").strip()
        else:
            # DS-3: also scan prose lines (FC-3) for path tokens; no intent marker.
            item = line
        found = _extract_paths(item)
        if not found:
            continue
        intent_m = INTENT_RE.search(item)
        intent = intent_m.group(1).lower() if intent_m else "edit"
        for path in found:
            files.append(FileRecord(path=path, intent=intent))
    # Dedup paths preserving first-seen order/intent.
    seen: Set[str] = set()
    deduped: List[FileRecord] = []
    for f in files:
        if f.path not in seen:
            seen.add(f.path)
            deduped.append(f)
    files = deduped
    if not files:
        # DS-4: explicit no-files declaration → clean (zero files); else failed.
        if any(NONE_FILES_RE.match(cl) for cl in content_lines):
            return [], "clean"
        return [], "failed"
    return files, "clean"


def parse_dependencies(body: str) -> Tuple[Set[int], str]:
    """Extract Dependencies references. Returns (deps, parse_status).

    DS-4 (#291): an ABSENT Dependencies section returns (set(), "clean") — deps are
    optional at intake (improvement.yml `required: false`) and absent entirely from
    bug.yml/observation.yml/adr.yml. A previously-returned "failed" on absence was a
    false negative that rolled otherwise-clean issues to non-clean.
    """
    section = extract_section_aliased(body, DEP_HEADING_ALIASES)
    if section is None:
        return set(), "clean"
    if DEFERRAL_MARKER in section:
        return set(), "deferred"
    deps = {int(m.group(1)) for m in DEP_RE.finditer(section)}
    return deps, "clean"


# Canonical priority/severity field detector.
# Grammar authority: core/schemas/gate-criteria-spec.md Gate 1 Priority-Model block
# + Adapter G1-06-Bug — "a single template-agnostic detector covers both field
# names ... the P-level digit, not the field name or qualifier word, is the
# canonical satisfier." Carrier-agnostic by construction: the corpus carries this
# field under a markdown heading (improvement.yml dropdown render) AND as a bold
# inline field (agent-authored bodies / DoR-crisp readiness blocks).
#
# LINE-ANCHORED on purpose. The anchor is what buys specificity: an unanchored
# variant matches a mid-prose mention ("...markers. Priority P3 (immediate...")
# and resolves a priority the author never set. A mid-line carrier is therefore
# deliberately NOT resolved — that is the accepted cost of rejecting prose.
PRIORITY_FIELD_RE = re.compile(
    r'^[ \t]*(?:#{1,6}[ \t]*|[-*][ \t]*)?'         # optional heading hashes OR list bullet
    r'\*{0,2}(?P<field>Priority|Severity)\*{0,2}'  # field name, optional bold
    r'[ \t]*:?[ \t]*\*{0,2}[ \t]*'                 # optional colon / closing bold
    r'(?:\r?\n[ \t]*){0,2}'                        # value on the next line (heading form)
    r'(?:\[[A-Z–— -]+\][ \t]*)*'                   # optional evidence label, e.g. [RECOMMENDED]
    r'P(?P<level>[1-4])\b',
    re.MULTILINE | re.IGNORECASE,
)

# Rank for the priority-desc tie-breaker. Rule authority (not restated here):
# release/skills/release-planner/references/dependency-analysis.md Tie-Breaker Rule.
#
# CANONICAL SIGN CONVENTION — ASCENDING, NEVER NEGATED. Lower rank = higher
# priority; unset sorts LAST at 5. The sort key is (priority_rank(r.priority),
# r.number) sorted ASCENDING. Do NOT negate it: `-priority_rank(p)` inverts the
# documented rule end-to-end (unset first, P1 last) and nothing fails loudly.
# This convention replaces the legacy `-priority_of(p)` form (which presumed the
# INVERSE scale, larger-is-higher-priority, and was undefined for unset); the doc
# was reconciled to this direction in the same change.
PRIORITY_RANK = {"P1": 1, "P2": 2, "P3": 3, "P4": 4}
PRIORITY_RANK_UNSET = 5


def priority_rank(priority: Optional[str]) -> int:
    """Total-order rank for the tie-breaker. P1..P4 -> 1..4; unset -> 5 (sorts last).

    Deliberately NOT serialized into emit_json — an agent derives it from
    `priority` in one line, and adding a JSON key would change a contract read by
    release-planner Mode A for no gain.
    """
    return PRIORITY_RANK.get(priority or "", PRIORITY_RANK_UNSET)


def parse_priority_body(body: str) -> Optional[str]:
    """Extract the P-level from the body Priority/Severity field.

    Returns "P1".."P4", or None when the field is absent, carries no P-level
    (a word-only value such as "Medium"), or is out of range ("P0"/"P5").
    Priority is optional at intake (improvement.yml `required: false`) and is
    NOT defined at all by bug/observation/story/epic/adr templates, so absence
    is conformance — it never contributes to parse_status.
    First-match-wins; verified deterministic against the live corpus (no body
    yields two different P-levels).
    """
    if not body:
        return None
    m = PRIORITY_FIELD_RE.search(body)
    return f"P{m.group('level')}" if m else None


# ---- Acceptance-Criteria presence (#4232) -------------------------------------
#
# A CRITERION is any markdown list item inside the AC section, in ANY of the three
# forms the live corpus uses: GitHub task-list checkbox (`- [ ]` / `- [x]`), plain
# bullet (`-` / `*` / `+`), or ordered (`1.` / `1)`). Counting only checkboxes is a
# measured blindness, not a hypothetical one: gated cards carry template-correct
# ordered-list AC that a checkbox-only counter reads as zero criteria, which is
# indistinguishable from having none.
#
# The marker must be followed by WHITESPACE. That is what keeps a thematic break
# (`---`), a bold run (`**Note:**`) and an em-dash rule from being counted as
# criteria — each of which starts with a bullet character but is not a list item.
AC_CRITERION_RE = re.compile(
    r"^[ \t]*(?:[-*+]|\d+[.)])[ \t]+(?:\[[ xX]?\][ \t]+)?\S", re.MULTILINE
)


def parse_acceptance_criteria(body: str) -> Tuple[bool, int]:
    """Return (section_present, criterion_count) for the body's AC section.

    PRESENCE + NON-EMPTINESS only. This says nothing about whether a criterion is
    well-shaped (G1-05a's job), measurable (G3-05's judgment check), or adequate in
    content — those have their own owners, and widening this predicate into any of
    them would make an absent-AC finding indistinguishable from a badly-worded one.

    Heading matching is DELEGATED to extract_section() — the DS-1 (#291) convention
    `^#{2,4}\\s+<heading>\\b[^\\n]*$` with IGNORECASE — so this function introduces
    NO second heading grammar (ADR-111 § Decision: a consumer of an issue-body field
    reads it through the shared detector rather than authoring its own). That
    delegation is what makes the result independent of heading depth (an H2
    pre-template body and an H3 template body match alike) and of template era.

    Prefix-anchoring is load-bearing in the negative direction too: the sub-task
    scaffold heading `### Cross-Issue Acceptance Criteria` and the stage heading
    `## Stage 8 QA / Acceptance` both correctly return absent, because the first is
    not prefix-anchored on the heading and the second carries no `Criteria` token.

    Absence is DATA, never a parse failure — it must not contribute to parse_status.
    ADR-111 §2 settles the identical question for priority: routing a field's absence
    to parse_status depresses the gated parse rate on conformant bodies and silently
    drops records from the contention map.
    """
    section = extract_section(body, "Acceptance Criteria")
    if section is None:
        return (False, 0)
    return (True, len(AC_CRITERION_RE.findall(section)))


# ---- API surface --------------------------------------------------------------

def gh_issue_view(number: int) -> Dict:
    """Call gh issue view <N> --json ... and return parsed JSON."""
    result = subprocess.run(
        [
            "gh", "issue", "view", str(number),
            "--json", "number,title,state,labels,body,milestone",
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"gh issue view #{number} failed: {result.stderr}")
    return json.loads(result.stdout)


def gh_milestone_issues(milestone: str) -> List[Dict]:
    """List all issues for a milestone."""
    result = subprocess.run(
        [
            "gh", "issue", "list",
            "--milestone", milestone,
            "--state", "open",
            "--json", "number,title,state,labels,body,milestone",
            "--limit", "5000",
        ],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"gh issue list --milestone failed: {result.stderr}")
    return json.loads(result.stdout)


def build_issue_record(raw: Dict) -> IssueRecord:
    body = raw.get("body") or ""
    labels = [lab["name"] for lab in raw.get("labels", [])]
    affected, aff_status = parse_affected_files(body)
    deps, dep_status = parse_dependencies(body)
    parse_status = (
        "failed" if "failed" in (aff_status, dep_status)
        else "deferred" if "deferred" in (aff_status, dep_status)
        else "clean"
    )
    ac_present, ac_count = parse_acceptance_criteria(body)
    milestone = raw.get("milestone") or {}
    return IssueRecord(
        number=raw["number"],
        title=raw["title"],
        state=raw["state"],
        labels=labels,
        priority=parse_priority_body(body),
        milestone=milestone.get("title") if isinstance(milestone, dict) else None,
        parse_status=parse_status,
        affected_files=affected,
        dependencies=sorted(deps),
        ac_present=ac_present,
        ac_count=ac_count,
    )


# ---- Contention map -----------------------------------------------------------

def build_contention_map(records: List[IssueRecord]) -> List[Dict]:
    """Produce 4-tier severity rubric (NONE / BINARY / MULTI-WAY / CONFLICT)."""
    by_path: Dict[str, List[Tuple[int, str]]] = {}
    for r in records:
        if r.parse_status != "clean":
            continue
        for f in r.affected_files:
            by_path.setdefault(f.path, []).append((r.number, f.intent))
    out: List[Dict] = []
    for path, hits in by_path.items():
        if len(hits) < 1:
            continue
        intents = [intent for _, intent in hits]
        intent_mix = {
            "edit": intents.count("edit"),
            "add": intents.count("add"),
            "delete": intents.count("delete"),
        }
        if "delete" in intents and len(hits) >= 2:
            severity = "CONFLICT"
        elif len(hits) == 1:
            severity = "NONE"
        elif len(hits) == 2:
            severity = "BINARY"
        else:
            severity = "MULTI-WAY"
        out.append({
            "path": path,
            "issues": sorted([n for n, _ in hits]),
            "intent_mix": intent_mix,
            "severity": severity,
        })
    out.sort(key=lambda r: (r["severity"] != "CONFLICT", r["path"]))
    return out


# ---- Artifact-relationship derivation (#246) ----------------------------------
# READ-ONLY, ADDITIVE: derives the §Category 4 artifact-relationship type
# (GENERATES / DEPENDS_ON / BLOCKS / SUPERSEDES) per the derivation rule table in
# release/skills/release-planner/references/dependency-analysis.md
# § Artifact-Relationship Classification. Vocabulary referenced from
# core/schemas/frontmatter-schema.md §Category 4; not redefined here.
#
# This is the artifact-relationship axis — ORTHOGONAL to the FS/SS/FF/SF scheduling
# axis. It does NOT touch parse_dependencies / parse_affected_files /
# build_contention_map / emit_tsv; it only adds an 'artifact_relationships' key to the
# JSON output. Native `blocks`/`blocked-by` is unavailable via `gh issue view --json`
# in this environment (the field set has no such field), so the derivation runs the
# spec's degraded-but-complete path: issue→issue edges default to DEPENDS_ON, and
# file-level GENERATES/SUPERSEDES derive from the parsed Affected-Files intents.

# Filename version-supersession pattern (a `_v2` / `-v2` / ` v2` token), per the
# version-detection rule in core/schemas/agent-processing-contracts.md § Version
# detection. Used only to type a Modify as SUPERSEDES; never mutates parse output.
VERSION_SUFFIX_RE = re.compile(r"[._-]v(\d+)\b", re.IGNORECASE)


def derive_artifact_relationships(record: IssueRecord) -> List[Dict]:
    """Return the typed artifact-relationship edges for one issue (additive).

    Deterministic per the derivation rule table:
      - body Dependencies cite #B (no native blocks available) → DEPENDS_ON (default)
      - Affected-Files intent 'add' (File Change Matrix Create) → GENERATES
      - Affected-Files intent 'edit' on a version-suffixed filename → SUPERSEDES

    BLOCKS is reachable only from native `blocks`/`blocked-by`, which `gh issue view
    --json` does not expose here; in that degraded path no BLOCKS edge is emitted and
    the dependency defaults to DEPENDS_ON (the weakest correct claim). Pure function of
    already-parsed fields — no API calls, no mutation of the IssueRecord.
    """
    edges: List[Dict] = []
    # Issue→issue edges: default DEPENDS_ON (degraded — no native blocks signal).
    for dep in record.dependencies:
        edges.append({
            "source": record.number,
            "type": "DEPENDS_ON",
            "target": dep,
            "derived_from": "body Dependencies (default)",
        })
    # File-level edges from the File Change Matrix intents.
    for f in record.affected_files:
        if f.intent == "add":
            edges.append({
                "source": record.number,
                "type": "GENERATES",
                "target": f.path,
                "derived_from": "File Change Matrix (Create)",
            })
        elif f.intent == "edit" and VERSION_SUFFIX_RE.search(f.path):
            edges.append({
                "source": record.number,
                "type": "SUPERSEDES",
                "target": f.path,
                "derived_from": "FCM version pattern",
            })
    return edges


# ---- Output formatting --------------------------------------------------------

def emit_json(records: List[IssueRecord], contention: List[Dict]) -> str:
    payload = {
        "issues": [
            {
                **asdict(r),
                "affected_files": [asdict(f) for f in r.affected_files],
                # #246 additive read-only field — artifact-relationship axis,
                # orthogonal to FS/SS scheduling; does not alter any existing field.
                "artifact_relationships": derive_artifact_relationships(r),
            }
            for r in records
        ],
        "contention_map": contention,
    }
    return json.dumps(payload, indent=2)


def emit_tsv(records: List[IssueRecord], contention: List[Dict]) -> str:
    lines = ["path\tissues\tseverity\tintent_mix"]
    for row in contention:
        if row["severity"] == "NONE":
            continue
        issues = ",".join(f"#{n}" for n in row["issues"])
        mix = ",".join(f"{k}×{v}" for k, v in row["intent_mix"].items() if v)
        lines.append(f"{row['path']}\t{issues}\t{row['severity']}\t{mix}")
    return "\n".join(lines)


# ---- Self-test ---------------------------------------------------------------

def run_self_test() -> int:
    """Synthetic fixtures: clean parse, deferred marker, parse failure, all 4 severity tiers."""
    failures = []

    # Test 1: clean parse
    body = """## Description
Stuff.

### Affected Files
- `pmo-platform/foo.md` (edit — small fix)
- `pmo-platform/bar.md` (add — new section)

### Dependencies
- #46
- #57
"""
    files, status = parse_affected_files(body)
    if status != "clean" or len(files) != 2 or files[0].intent != "edit" or files[1].intent != "add":
        failures.append(f"clean parse: got {status} / {files}")
    deps, dstatus = parse_dependencies(body)
    if dstatus != "clean" or deps != {46, 57}:
        failures.append(f"clean deps: got {dstatus} / {deps}")

    # Test 1b: H2-formatted body (pre-form-template authoring)
    body_h2 = """## Description
Stuff.

## Affected Files
- `pmo-platform/foo.md` (edit — small fix)

## Dependencies
- #46
"""
    files_h2, status_h2 = parse_affected_files(body_h2)
    if status_h2 != "clean" or len(files_h2) != 1 or files_h2[0].intent != "edit":
        failures.append(f"H2 clean parse: got {status_h2} / {files_h2}")
    deps_h2, dstatus_h2 = parse_dependencies(body_h2)
    if dstatus_h2 != "clean" or deps_h2 != {46}:
        failures.append(f"H2 clean deps: got {dstatus_h2} / {deps_h2}")

    # Test 1c: missing Dependencies section parses CLEAN (DS-4 / FC-4 #291).
    # Was "failed" pre-v3.20 — a false negative on optional-at-intake deps.
    body_nodep = """### Affected Files
- `core/foo.md` (edit — fix)
"""
    files_nd, st_nd = parse_affected_files(body_nodep)
    deps_nd, dst_nd = parse_dependencies(body_nodep)
    if st_nd != "clean" or len(files_nd) != 1:
        failures.append(f"FC-4 AF clean (core/ prefix): got {st_nd} / {files_nd}")
    if dst_nd != "clean" or deps_nd != set():
        failures.append(f"FC-4 missing-deps→clean: got {dst_nd} / {deps_nd}")

    # Test 2: deferred marker
    body2 = "### Affected Files\n[ASSUMPTION – CONFIRM] TBD — identified in Planning\n\n### Dependencies\n- #99\n"
    _, s2 = parse_affected_files(body2)
    if s2 != "deferred":
        failures.append(f"deferred: got {s2}")

    # Test 3: parse failure (no AF section at all → FC-6 set-aside class)
    body3 = "## Description\nNo affected files section.\n"
    _, s3 = parse_affected_files(body3)
    if s3 != "failed":
        failures.append(f"parse failure: got {s3}")

    # ---- #291 v3.20 per-failure-class fixtures (DS-6) ----
    # Each asserts the SPECIFIC recovery the ratified #461 spec designed. Where
    # relevant, the same fixture FAILS against the pre-v3.20 parser (regression guard).

    # FC-1a: current module prefixes (core/ release/ operations/) bare in a bullet.
    # Pre-v3.20 WORKSPACE_PATH_RE matched only pmo-platform|.claude|projects|memory.
    fc1a = """### Affected Files
- core/schemas/project-schema.md (edit — add axis)
- release/references/specs/x.md (edit — sibling pattern)
- operations/runbook.md (edit — note)
"""
    f1a, s1a = parse_affected_files(fc1a)
    if s1a != "clean" or [x.path for x in f1a] != [
        "core/schemas/project-schema.md",
        "release/references/specs/x.md",
        "operations/runbook.md",
    ]:
        failures.append(f"FC-1a module-prefix paths: got {s1a} / {[x.path for x in f1a]}")

    # FC-1b: bare filename, backticked, no internal '/' (BACKTICK_PATH_RE missed it).
    fc1b = "### Affected Files\n- `deploy.sh` (edit — workspace root)\n- `CLAUDE.md` (edit — refresh tree)\n"
    f1b, s1b = parse_affected_files(fc1b)
    if s1b != "clean" or [x.path for x in f1b] != ["deploy.sh", "CLAUDE.md"]:
        failures.append(f"FC-1b bare backticked filename: got {s1b} / {[x.path for x in f1b]}")

    # FC-1c: skill-relative path (no known top-level prefix) — recovers via ext-token.
    fc1c = "### Affected Files\n- delivery-engine/references/x.md (edit)\n- weekly-status-rollup/SKILL.md (edit)\n"
    f1c, s1c = parse_affected_files(fc1c)
    if s1c != "clean" or [x.path for x in f1c] != [
        "delivery-engine/references/x.md",
        "weekly-status-rollup/SKILL.md",
    ]:
        failures.append(f"FC-1c skill-relative path: got {s1c} / {[x.path for x in f1c]}")

    # FC-1d: module-prefixed trailing-slash directory (no file extension).
    fc1d = "### Affected Files\n- pmo-platform/engineering/ (edit — directory)\n- core/deploy/tools/ (edit)\n"
    f1d, s1d = parse_affected_files(fc1d)
    if s1d != "clean" or [x.path for x in f1d] != [
        "pmo-platform/engineering/",
        "core/deploy/tools/",
    ]:
        failures.append(f"FC-1d trailing-slash dir: got {s1d} / {[x.path for x in f1d]}")

    # FC-2: heading parenthetical suffix — extract_section must still match (DS-1).
    fc2 = "### Affected Files (directional — confirmed in Planning)\n- `core/foo.md` (edit)\n"
    f2, s2b = parse_affected_files(fc2)
    if s2b != "clean" or [x.path for x in f2] != ["core/foo.md"]:
        failures.append(f"FC-2 heading parenthetical suffix: got {s2b} / {[x.path for x in f2]}")
    # FC-2 variant: trailing colon.
    fc2b = "## Affected Files:\n- `release/bar.py` (edit)\n"
    f2c, s2c = parse_affected_files(fc2b)
    if s2c != "clean" or [x.path for x in f2c] != ["release/bar.py"]:
        failures.append(f"FC-2 heading trailing-colon: got {s2c} / {[x.path for x in f2c]}")

    # FC-2 alias (DS-2): "Files Affected" heading variant resolves.
    fc2_alias = "### Files Affected\n- `core/baz.md` (edit)\n"
    f2d, s2d = parse_affected_files(fc2_alias)
    if s2d != "clean" or [x.path for x in f2d] != ["core/baz.md"]:
        failures.append(f"FC-2 heading alias 'Files Affected': got {s2d} / {[x.path for x in f2d]}")
    # Dep alias resolves too.
    fc_depalias = "### Affected Files\n- `core/q.md` (edit)\n\n### Depends on\n- #123\n"
    _, dep_a_st = parse_affected_files(fc_depalias)
    deps_a, deps_a_st = parse_dependencies(fc_depalias)
    if deps_a_st != "clean" or deps_a != {123}:
        failures.append(f"FC-2 dep alias 'Depends on': got {deps_a_st} / {deps_a}")

    # FC-3: prose-style AF section (paths in a sentence, no dash bullets).
    fc3 = (
        "### Affected Files\n"
        "The fix touches `core/deploy/deploy.sh` and the helper at "
        "release/tools/cleanup-orphan-state.sh as well.\n"
    )
    f3, s3b = parse_affected_files(fc3)
    if s3b != "clean" or set(x.path for x in f3) != {
        "core/deploy/deploy.sh",
        "release/tools/cleanup-orphan-state.sh",
    }:
        failures.append(f"FC-3 prose-style section: got {s3b} / {[x.path for x in f3]}")

    # FC-5: intake-deferral marker → deferred (intended state, not failed). Covered
    # by Test 2 above; re-assert here that a present deferral in AF yields 'deferred'.
    fc5 = "### Affected Files\n[ASSUMPTION – CONFIRM] TBD — identified in Planning\n"
    _, s5 = parse_affected_files(fc5)
    if s5 != "deferred":
        failures.append(f"FC-5 deferral marker: got {s5}")

    # FC-7: explicit no-files declaration inside a present AF section → clean/empty.
    fc7 = "### Affected Files\nNone — label-only update via `gh issue edit --add-label`.\n"
    f7, s7 = parse_affected_files(fc7)
    if s7 != "clean" or f7 != []:
        failures.append(f"FC-7 explicit None declaration: got {s7} / {f7}")
    # FC-7 negative: a present section with a component-name bullet and NO path and
    # NO None-marker stays failed (genuinely unparseable; routes to set-aside).
    fc7n = "### Affected Files\n- 17 GitHub milestones (see table below)\n"
    _, s7n = parse_affected_files(fc7n)
    if s7n != "failed":
        failures.append(f"FC-7 component-name-no-path stays failed: got {s7n}")

    # Test 4: severity tiers
    recs = [
        IssueRecord(1, "a", "open", [], None, None, "clean",
                    [FileRecord("f1.md", "edit")], []),
        IssueRecord(2, "b", "open", [], None, None, "clean",
                    [FileRecord("f1.md", "edit"), FileRecord("f2.md", "edit")], []),
        IssueRecord(3, "c", "open", [], None, None, "clean",
                    [FileRecord("f1.md", "edit")], []),
        IssueRecord(4, "d", "open", [], None, None, "clean",
                    [FileRecord("f3.md", "delete")], []),
        IssueRecord(5, "e", "open", [], None, None, "clean",
                    [FileRecord("f3.md", "edit")], []),
    ]
    cont = build_contention_map(recs)
    sev_by_path = {r["path"]: r["severity"] for r in cont}
    if sev_by_path.get("f1.md") != "MULTI-WAY":  # 3 issues
        failures.append(f"MULTI-WAY: got {sev_by_path.get('f1.md')}")
    if sev_by_path.get("f2.md") != "NONE":
        failures.append(f"NONE: got {sev_by_path.get('f2.md')}")
    if sev_by_path.get("f3.md") != "CONFLICT":  # delete+edit
        failures.append(f"CONFLICT: got {sev_by_path.get('f3.md')}")

    # Test 5: artifact-relationship derivation (#246) — additive, read-only.
    # DEPENDS_ON from body deps (degraded — no native blocks); GENERATES from an
    # 'add' intent; SUPERSEDES from an 'edit' on a version-suffixed filename.
    rec_ar = IssueRecord(
        7, "ar", "open", [], None, None, "clean",
        [FileRecord("new-thing.md", "add"),
         FileRecord("design_v2.md", "edit"),
         FileRecord("plain.md", "edit")],
        [46, 57],
    )
    ar = derive_artifact_relationships(rec_ar)
    ar_types = sorted((e["type"], str(e["target"])) for e in ar)
    expected_ar = sorted([
        ("DEPENDS_ON", "46"), ("DEPENDS_ON", "57"),
        ("GENERATES", "new-thing.md"), ("SUPERSEDES", "design_v2.md"),
    ])
    if ar_types != expected_ar:
        failures.append(f"#246 artifact-relationships: got {ar_types}")
    # Edge: zero deps + zero version/add files → no typed edges (empty-state caller-handled).
    rec_ar_empty = IssueRecord(
        8, "empty", "open", [], None, None, "clean",
        [FileRecord("just-edit.md", "edit")], [],
    )
    if derive_artifact_relationships(rec_ar_empty) != []:
        failures.append(f"#246 empty-state: got {derive_artifact_relationships(rec_ar_empty)}")

    # ---- Priority body-field detector (T-1..T-11) --------------------------------
    # Sensitivity T-1..T-8: every carrier shape observed in the live corpus must
    # resolve. Specificity T-9..T-11: the guards that keep the detector from
    # widening into prose. A detector scored only on sensitivity is how the label
    # regex this replaces stayed silently dead for the whole release history.
    priority_cases = [
        # (leg, body, expected)
        ("T-1 heading + dropdown value", "### Priority\n\nP3 - Medium\n", "P3"),
        ("T-2 heading + bare P-level", "### Priority\n\nP2\n", "P2"),
        ("T-3 H2 heading (pre-form-template)", "## Priority\n\nP4 - Low\n", "P4"),
        ("T-4 DoR-crisp bold-inline",
         "**Priority:** P3 - Medium · **Reversibility:** CHEAP (parser reconcile).\n", "P3"),
        ("T-5 bold-inline + em dash",
         "**Priority:** P2 — High [agent-estimated at intake]\n", "P2"),
        ("T-6 bullet + bold + en dash", "- **Priority:** P3 – Medium\n", "P3"),
        ("T-7 heading + evidence label",
         "### Priority\n\n[RECOMMENDED] P2 - High (keystone)\n", "P2"),
        ("T-8 Severity adapter (G1-06-Bug)", "### Severity\n\nP2 - Material\n", "P2"),
        ("T-9 AC-quotation stays unresolved",
         "- [ ] Confirm `IssueRecord.priority` resolves from the issue body "
         "`### Priority` field for a body carrying `P2 - High`.\n", None),
        ("T-10 word-only value stays unresolved",
         "### Priority\n\nMedium — a real hole.\n", None),
        ("T-11 out-of-range value stays unresolved", "### Priority\n\nP5 - Nope\n", None),
    ]
    for leg, pbody, expected in priority_cases:
        got = parse_priority_body(pbody)
        if got != expected:
            failures.append(f"{leg}: expected {expected!r}, got {got!r}")

    # No-carrier and empty-body arms — absence is conformance, never an error.
    if parse_priority_body("## Description\nNo priority field anywhere.\n") is not None:
        failures.append("priority no-carrier: expected None")
    if parse_priority_body("") is not None:
        failures.append("priority empty-body: expected None")

    # Priority NEVER contributes to parse_status (D-2). A body with an unresolvable
    # priority and a clean AF/Dep parse must still combine to clean.
    body_prio_status = "### Priority\n\nMedium\n\n### Affected Files\n- `core/foo.md` (edit)\n"
    _, af_ps = parse_affected_files(body_prio_status)
    _, dep_ps = parse_dependencies(body_prio_status)
    if af_ps != "clean" or dep_ps != "clean":
        failures.append(f"priority never enters parse_status: got {af_ps} / {dep_ps}")

    # ---- Tie-breaker rank + sort direction (the FMF-2 sign guard) ----------------
    # ASSERTED EMPIRICALLY, not reasoned about. `priority_rank` is ASCENDING and is
    # NEVER negated; the legacy `-priority_of(p)` form presumed the inverse scale.
    # Substituting one into the other silently inverts the whole tie-breaker, so the
    # inversion is asserted here as an executable fact rather than a comment.
    if [priority_rank(p) for p in ("P1", "P2", "P3", "P4", None)] != [1, 2, 3, 4, 5]:
        failures.append(
            f"priority_rank scale: got {[priority_rank(p) for p in ('P1','P2','P3','P4',None)]}"
        )
    if priority_rank("P9") != 5 or priority_rank("") != 5:
        failures.append("priority_rank unrecognized value must fall back to unset rank 5")

    # Canonical key: (priority_rank, issue_number) ASCENDING. Unset sorts last.
    tie_input = [(None, 7), ("P2", 9), ("P3", 3)]
    tie_sorted = sorted(tie_input, key=lambda t: (priority_rank(t[0]), t[1]))
    if tie_sorted != [("P2", 9), ("P3", 3), (None, 7)]:
        failures.append(f"tie-breaker canonical order: got {tie_sorted}")
    # Negated key is the FMF-2 defect — assert it really does invert, so the guard
    # above is known to be load-bearing rather than trivially true.
    tie_negated = sorted(tie_input, key=lambda t: (-priority_rank(t[0]), t[1]))
    if tie_negated != [(None, 7), ("P3", 3), ("P2", 9)]:
        failures.append(f"tie-breaker inversion control: got {tie_negated}")
    # Full P1..P4 + unset ordering, ascending, no negation.
    full_order = sorted(["P4", None, "P1", "P3", "P2"], key=priority_rank)
    if full_order != ["P1", "P2", "P3", "P4", None]:
        failures.append(f"tie-breaker full order: got {full_order}")

    # ---- AC-presence detector (#4232) — AC-P1..AC-P12 ---------------------------
    # Scored on BOTH axes. Sensitivity alone would pass a predicate that returns
    # "present" for every body, which is precisely the shape of the defect this
    # closes (a check that never once emitted an absence finding), so every
    # sensitivity arm below is paired with a specificity arm that must return absent.
    _AC_BULLETS = "- [ ] Verify that `core/deploy/deploy.sh` carries the presence arm\n"

    # AC-P1..AC-P3 — SENSITIVITY across heading depth. The pre-template H2 body is
    # the era the card exists to protect; a depth-keyed predicate scores 0 here.
    for _depth, _tag in (("##", "AC-P1 H2 pre-template"),
                         ("###", "AC-P2 H3 template"),
                         ("####", "AC-P3 H4")):
        _present, _count = parse_acceptance_criteria(
            f"### Description\n\nStuff.\n\n{_depth} Acceptance Criteria\n\n{_AC_BULLETS}"
        )
        if not _present or _count != 1:
            failures.append(f"{_tag}: got present={_present} count={_count}, want True/1")

    # AC-P4 — case + suffix tolerance, inherited from extract_section (DS-1 #291).
    _present, _count = parse_acceptance_criteria(
        f"## Acceptance criteria (proposed)\n\n{_AC_BULLETS}"
    )
    if not _present or _count != 1:
        failures.append(f"AC-P4 case+suffix heading: got present={_present} count={_count}")

    # AC-P5 — SPECIFICITY: the sub-task scaffold heading is NOT the card's own AC.
    # extract_section is prefix-anchored, so this must not match.
    _present, _count = parse_acceptance_criteria(
        f"### Cross-Issue Acceptance Criteria\n\n{_AC_BULLETS}"
    )
    if _present:
        failures.append(f"AC-P5 'Cross-Issue Acceptance Criteria' matched: count={_count}")

    # AC-P6 — SPECIFICITY: a stage heading carrying 'Acceptance' but no 'Criteria'.
    _present, _ = parse_acceptance_criteria(f"## Stage 8 QA / Acceptance\n\n{_AC_BULLETS}")
    if _present:
        failures.append("AC-P6 'Stage 8 QA / Acceptance' matched as an AC section")

    # AC-P7 — THE DEFECT ITSELF: heading present, zero criteria beneath it. This is
    # the empty-set case the shipped shape check fails open on, so it must resolve
    # present-but-empty and be distinguishable from both absent and satisfied.
    _present, _count = parse_acceptance_criteria(
        "### Acceptance Criteria\n\nTo be authored during planning.\n"
    )
    if not _present or _count != 0:
        failures.append(f"AC-P7 heading with zero criteria: got present={_present} count={_count}")

    # AC-P8 — ordered-list criteria. Template-correct bodies use these; a
    # checkbox-only counter reads them as zero and calls a complete card AC-less.
    _present, _count = parse_acceptance_criteria(
        "### Acceptance Criteria\n\n1. Verify the row renders.\n2. Confirm the control fails.\n"
    )
    if not _present or _count != 2:
        failures.append(f"AC-P8 ordered-list criteria: got present={_present} count={_count}")

    # AC-P9 — plain (non-checkbox) bullets.
    _present, _count = parse_acceptance_criteria(
        "### Acceptance Criteria\n\n- Verify the row renders.\n* Confirm the control fails.\n"
    )
    if not _present or _count != 2:
        failures.append(f"AC-P9 plain-bullet criteria: got present={_present} count={_count}")

    # AC-P10 — SPECIFICITY: a thematic break and a bold run both begin with a bullet
    # character and are NOT criteria. Without the required whitespace after the
    # marker, `---` alone would satisfy a presence check on an empty section.
    _present, _count = parse_acceptance_criteria(
        "### Acceptance Criteria\n\n---\n**Note:** none yet.\n"
    )
    if not _present or _count != 0:
        failures.append(f"AC-P10 rule/bold not counted: got present={_present} count={_count}")

    # AC-P11 — MUTATION CONTROL. Remove the section from a body that passes and
    # assert the verdict flips. Without this, every arm above could be a constant.
    _ac_body = f"### Description\n\nStuff.\n\n### Acceptance Criteria\n\n{_AC_BULLETS}"
    _before = parse_acceptance_criteria(_ac_body)
    _mutated = _ac_body.split("### Acceptance Criteria")[0]
    _after = parse_acceptance_criteria(_mutated)
    if _before != (True, 1) or _after != (False, 0):
        failures.append(f"AC-P11 mutation control: before={_before} after={_after}")

    # AC-P12 — AC absence must NOT contribute to parse_status (ADR-111 §2). A body
    # with clean Affected Files and no AC section stays `clean`; routing absence to
    # parse_status would drop conformant records out of the contention map.
    _rec = build_issue_record({
        "number": 4232, "title": "t", "state": "open", "labels": [],
        "body": "### Affected Files\n- `core/foo.md` (edit — fix)\n",
    })
    if _rec.parse_status != "clean" or _rec.ac_present or _rec.ac_count != 0:
        failures.append(
            f"AC-P12 absence-is-data: parse_status={_rec.parse_status} "
            f"ac_present={_rec.ac_present} ac_count={_rec.ac_count}"
        )

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
    parser.add_argument("--milestone", help="Milestone title to fetch all issues from")
    parser.add_argument("--issues", help="Comma-separated issue numbers")
    parser.add_argument("--output-format", choices=["json", "tsv"], default="json")
    parser.add_argument("--self-test", action="store_true", help="Run synthetic fixtures")
    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    issue_numbers: List[int] = []
    raw_issues: List[Dict] = []
    if args.milestone:
        try:
            raw_issues = gh_milestone_issues(args.milestone)
        except RuntimeError as e:
            print(f"ERROR: {e}", file=sys.stderr)
            return 2
    elif args.issues:
        issue_numbers = [int(n.strip()) for n in args.issues.split(",") if n.strip()]
    else:
        for line in sys.stdin:
            line = line.strip()
            if line:
                issue_numbers.append(int(line))

    if issue_numbers and not raw_issues:
        for n in issue_numbers:
            try:
                raw_issues.append(gh_issue_view(n))
            except RuntimeError as e:
                print(f"ERROR: {e}", file=sys.stderr)
                return 2

    if not raw_issues:
        print("ERROR: no issues to parse (provide --milestone, --issues, or stdin)", file=sys.stderr)
        return 2

    records = [build_issue_record(raw) for raw in raw_issues]
    contention = build_contention_map(records)

    if args.output_format == "tsv":
        print(emit_tsv(records, contention))
    else:
        print(emit_json(records, contention))

    if any(r.parse_status == "failed" for r in records):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

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


def parse_priority_label(labels: List[str]) -> Optional[str]:
    for lab in labels:
        m = re.match(r"priority:\s*p([1-4])", lab, re.IGNORECASE)
        if m:
            return f"P{m.group(1)}"
    return None


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
    milestone = raw.get("milestone") or {}
    return IssueRecord(
        number=raw["number"],
        title=raw["title"],
        state=raw["state"],
        labels=labels,
        priority=parse_priority_label(labels),
        milestone=milestone.get("title") if isinstance(milestone, dict) else None,
        parse_status=parse_status,
        affected_files=affected,
        dependencies=sorted(deps),
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


# ---- Output formatting --------------------------------------------------------

def emit_json(records: List[IssueRecord], contention: List[Dict]) -> str:
    payload = {
        "issues": [
            {
                **asdict(r),
                "affected_files": [asdict(f) for f in r.affected_files],
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

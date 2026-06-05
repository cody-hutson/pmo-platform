#!/usr/bin/env python3
"""Bundle Issues Parser — shared-tool for release-planner Bundle mode.

Provides parse_affected_files() + parse_dependencies() from a single GitHub API
read pass. Consumed by release-planner Mode A/B per ADR-1 and ADR-2 contention
output. Companion to dependency-analysis.md Kahn's algorithm.

Per CR Conflict A resolution: single shared tool with umbrella name
'bundle-issues-parser.py' rather than per-concern tools. Stdlib-only Python 3.9+;
matches check-doc-links.py / lint_release_corpus.py precedent.

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
BACKTICK_PATH_RE = re.compile(r"`([^`\s]+/[^`]*)`")
WORKSPACE_PATH_RE = re.compile(
    r"(?:pmo-platform|\.claude|projects|memory)/[^\s,)`]+"
)
INTENT_RE = re.compile(
    r"\((add|edit|delete)\s*(?:—|--|-)\s*[^)]*\)", re.IGNORECASE
)
DEP_RE = re.compile(r"#(\d+)")


def extract_section(body: str, heading: str) -> Optional[str]:
    """Extract content of a '### <heading>' section until next H2/H3 or two blank lines."""
    if not body:
        return None
    # Find the heading (case-insensitive, tolerate trailing whitespace)
    pat = re.compile(rf"^##+\s+{re.escape(heading)}\s*$", re.MULTILINE | re.IGNORECASE)
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


def parse_affected_files(body: str) -> Tuple[List[FileRecord], str]:
    """Extract Affected Files records. Returns (files, parse_status)."""
    section = extract_section(body, "Affected Files")
    if section is None:
        return [], "failed"
    if DEFERRAL_MARKER in section:
        return [], "deferred"
    files: List[FileRecord] = []
    for line in section.splitlines():
        line = line.strip()
        if not line or not (line.startswith("-") or line.startswith("*")):
            continue
        item = line.lstrip("-* ").strip()
        # Try backticked path first
        m = BACKTICK_PATH_RE.search(item)
        if m:
            path = m.group(1)
        else:
            m = WORKSPACE_PATH_RE.search(item)
            if not m:
                continue
            path = m.group(0)
        # Intent
        intent_m = INTENT_RE.search(item)
        intent = intent_m.group(1).lower() if intent_m else "edit"
        files.append(FileRecord(path=path, intent=intent))
    if not files:
        return [], "failed"
    return files, "clean"


def parse_dependencies(body: str) -> Tuple[Set[int], str]:
    """Extract Dependencies references. Returns (deps, parse_status)."""
    section = extract_section(body, "Dependencies")
    if section is None:
        return set(), "failed"
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

    # Test 2: deferred marker
    body2 = "### Affected Files\n[ASSUMPTION – CONFIRM] TBD — identified in Planning\n\n### Dependencies\n- #99\n"
    _, s2 = parse_affected_files(body2)
    if s2 != "deferred":
        failures.append(f"deferred: got {s2}")

    # Test 3: parse failure (no section)
    body3 = "## Description\nNo affected files section.\n"
    _, s3 = parse_affected_files(body3)
    if s3 != "failed":
        failures.append(f"parse failure: got {s3}")

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

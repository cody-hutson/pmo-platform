#!/usr/bin/env python3
"""Generate RELEASE_INDEX.md from RELEASE_LOG.md table rows.

Parses the table rows in pmo-platform/governance/RELEASE_LOG.md, derives
a navigation index pointing at each release's plan + note (if present on
disk), and emits pmo-platform/releases/RELEASE_INDEX.md.

Authored under the Stage 5 spec (Index recommendation option (b) — keep LOG;
add INDEX/DIGEST sidecars).

`--verify` mode added later (engine + deploy.sh
Check 23 wrapper). Re-generates INDEX to memory from current LOG + filesystem
and compares row-by-row against on-disk RELEASE_INDEX.md, emitting TSV-line
diagnostics on mismatch. Reuses parse_log_rows()/find_artifact() for the
expected row set; parse_index_rows() parses the rendered on-disk INDEX.

Usage:
    python3 core/deploy/tools/generate_release_index.py
    python3 core/deploy/tools/generate_release_index.py --output-stdout
    python3 core/deploy/tools/generate_release_index.py --verify
    python3 core/deploy/tools/generate_release_index.py --self-test

Exit codes: 0 = success (or --verify: full match), 1 = parse failure,
write failure, or --verify mismatch.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
LOG_PATH = WORKSPACE_ROOT / "pmo-platform" / "governance" / "RELEASE_LOG.md"
PLANS_DIR = WORKSPACE_ROOT / "pmo-platform" / "releases" / "plans"
NOTES_DIR = WORKSPACE_ROOT / "pmo-platform" / "releases" / "notes"
ARCHIVE_PLANS_DIR = WORKSPACE_ROOT / "pmo-platform" / "releases" / "archive" / "plans"
INDEX_PATH = WORKSPACE_ROOT / "pmo-platform" / "releases" / "RELEASE_INDEX.md"

ROW_RE = re.compile(r"^\| (?P<version>v[0-9][^\|]*?) \| (?P<date>[^\|]+?) \| (?P<rclass>[^\|]+?) \|")
ISSUE_RE = re.compile(r"#[0-9]+|IMP-[0-9]+")
STATUS_TAIL_RE = re.compile(r"\| ([A-Z][A-Z]+|VERIFIED|DEPLOYED|RELEASED|Done) +\|?\s*$")

# INDEX_ROW_RE — parses rendered RELEASE_INDEX.md rows, which carry 8 cells:
#   | {version} | {date} | {class} | {scope} | {plan} | {note} | {log} | {status} |
# Cells are pipe-separated with leading/trailing pipe. Each capture strips
# surrounding whitespace by virtue of " " adjacency in the pattern.
INDEX_ROW_RE = re.compile(
    r"^\| (?P<version>v[0-9][^\|]*?) \| (?P<date>[^\|]+?) \| (?P<rclass>[^\|]+?) "
    r"\| (?P<scope>[^\|]+?) \| (?P<plan>[^\|]+?) \| (?P<note>[^\|]+?) "
    r"\| (?P<log>[^\|]+?) \| (?P<status>[^\|]+?) \|\s*$"
)


def find_artifact(version_key: str, kind: str) -> str | None:
    """Locate a plan or note file by version-key prefix.

    `version_key` is the LOG row's version cell (e.g., "v2.1-deploy-fixes" or "v1.0").
    Match strategy: exact prefix match, then case-insensitive prefix.
    Returns repo-root-relative path string, or None.
    """
    if kind == "plan":
        directory = PLANS_DIR
        suffix = "_RELEASE_PLAN.md"
    else:
        directory = NOTES_DIR
        suffix = "_RELEASE_NOTES.md"

    if not directory.exists():
        return None

    short = version_key.split("-", 1)[0]

    for candidate in sorted(directory.glob(f"*{suffix}")):
        name = candidate.name
        stem_key = name[:-len(suffix)]
        if stem_key == version_key or stem_key == short:
            return f"pmo-platform/releases/{directory.name}/{name}"
        if stem_key.startswith(version_key):
            return f"pmo-platform/releases/{directory.name}/{name}"
        if version_key.startswith(stem_key + "-") and stem_key.startswith(short):
            return f"pmo-platform/releases/{directory.name}/{name}"

    if kind == "plan" and ARCHIVE_PLANS_DIR.exists():
        for candidate in sorted(ARCHIVE_PLANS_DIR.glob(f"*{suffix}")):
            stem_key = candidate.name[:-len(suffix)]
            if stem_key == version_key or stem_key == short:
                return f"pmo-platform/releases/archive/plans/{candidate.name}"

    return None


def parse_log_rows(log_text: str) -> list[dict]:
    rows: list[dict] = []
    for raw_line in log_text.splitlines():
        m = ROW_RE.match(raw_line)
        if not m:
            continue
        version = m.group("version").strip()
        date = m.group("date").strip()
        rclass = m.group("rclass").strip()
        issues = ISSUE_RE.findall(raw_line)
        status_match = STATUS_TAIL_RE.search(raw_line)
        status = status_match.group(1) if status_match else "—"
        rows.append({
            "version": version,
            "date": date,
            "rclass": rclass,
            "issue_count": len(issues),
            "status": status,
        })
    return rows


def render_index(rows: list[dict]) -> str:
    out: list[str] = []
    out.append("# RELEASE_INDEX.md — pmo-platform Release Navigation Surface")
    out.append("")
    out.append("**Purpose:** Single-row-per-release navigation across the release-process output trio")
    out.append("(`pmo-platform/governance/RELEASE_LOG.md` + `pmo-platform/releases/plans/*.md` + `pmo-platform/releases/notes/*.md`).")
    out.append("Generated from RELEASE_LOG.md by `core/deploy/tools/generate_release_index.py`")
    out.append("(authored under the release-index-format decision).")
    out.append("")
    out.append("**Scope:** Every release in RELEASE_LOG.md. New rows append at Stage 13 Close per the")
    out.append("amended `release-process.md` Stage 13 clause (per CR-D6 governance-theater mitigation).")
    out.append("")
    out.append("**Maintenance:** Re-run the generator after each release merges to main, OR hand-append")
    out.append("a row matching the format below. Row count gates Milestone close (per Stage 13 clause).")
    out.append("")
    out.append("**Fields:**")
    out.append("- **Version** — release version key matching the LOG row")
    out.append("- **Date** — release publication date (ISO 8601)")
    out.append("- **Class** — release class from LOG (Foundation / Major / Minor / Patch)")
    out.append("- **Scope** — count of issues bundled in the release")
    out.append("- **Plan** — link to release plan file in `releases/plans/` (— if not present)")
    out.append("- **Note** — link to user-facing note in `releases/notes/` (— if not present)")
    out.append("- **LOG** — link to the LOG row entry (file-level — fragment anchors not yet established; deferred to a future restructure)")
    out.append("- **Status** — final status from LOG (VERIFIED / DEPLOYED / RELEASED / Done / —)")
    out.append("")
    out.append("---")
    out.append("")
    out.append("| Version | Date | Class | Scope | Plan | Note | LOG | Status |")
    out.append("|---------|------|-------|-------|------|------|-----|--------|")
    for r in rows:
        plan_path = find_artifact(r["version"], "plan")
        note_path = find_artifact(r["version"], "note")
        plan_cell = f"[plan](../../{plan_path})" if plan_path else "—"
        note_cell = f"[note](../../{note_path})" if note_path else "—"
        log_cell = "[LOG](../governance/RELEASE_LOG.md)"
        out.append(f"| {r['version']} | {r['date']} | {r['rclass']} | {r['issue_count']} | {plan_cell} | {note_cell} | {log_cell} | {r['status']} |")
    out.append("")
    return "\n".join(out)


def parse_index_rows(index_text: str) -> list[dict]:
    """Parse rendered RELEASE_INDEX.md rows. Mirror schema to parse_log_rows().

    Returns per-row dict with keys: version, date, rclass, issue_count (int),
    status (from rendered Status cell), plan_cell (raw cell text — "—" or
    "[plan](path)"), note_cell (raw cell text).
    """
    rows: list[dict] = []
    for raw_line in index_text.splitlines():
        m = INDEX_ROW_RE.match(raw_line)
        if not m:
            continue
        scope_raw = m.group("scope").strip()
        try:
            issue_count = int(scope_raw)
        except ValueError:
            issue_count = -1
        rows.append({
            "version": m.group("version").strip(),
            "date": m.group("date").strip(),
            "rclass": m.group("rclass").strip(),
            "issue_count": issue_count,
            "status": m.group("status").strip(),
            "plan_cell": m.group("plan").strip(),
            "note_cell": m.group("note").strip(),
        })
    return rows


def verify(log_rows: list[dict], index_rows: list[dict]) -> list[dict]:
    """Compare expected (log_rows + filesystem-derived plan/note paths) vs
    on-disk INDEX rows. Return list of finding dicts.

    Each finding: {version, field, log_value, index_value, recommendation}.
    Empty list = full match.
    """
    findings: list[dict] = []
    log_by_version = {r["version"]: r for r in log_rows}
    index_by_version = {r["version"]: r for r in index_rows}

    # Coexistence — LOG-only
    for v in log_by_version:
        if v not in index_by_version:
            findings.append({
                "version": v, "field": "coexistence",
                "log_value": "present", "index_value": "absent",
                "recommendation": "run generator to add missing INDEX entry",
            })

    # Coexistence — INDEX-only
    for v in index_by_version:
        if v not in log_by_version:
            findings.append({
                "version": v, "field": "coexistence",
                "log_value": "absent", "index_value": "present",
                "recommendation": "INDEX has stale entry; verify LOG row not deleted; re-run generator",
            })

    # Per-row field comparison (only for versions present in BOTH)
    for v in log_by_version:
        if v not in index_by_version:
            continue
        log_r = log_by_version[v]
        idx_r = index_by_version[v]

        if log_r["date"] != idx_r["date"]:
            findings.append({
                "version": v, "field": "date",
                "log_value": log_r["date"], "index_value": idx_r["date"],
                "recommendation": "LOG is canonical for deploy-date; re-run generator to refresh INDEX",
            })

        if log_r["rclass"] != idx_r["rclass"]:
            findings.append({
                "version": v, "field": "class",
                "log_value": log_r["rclass"], "index_value": idx_r["rclass"],
                "recommendation": "re-run generator",
            })

        if log_r["issue_count"] != idx_r["issue_count"]:
            findings.append({
                "version": v, "field": "scope",
                "log_value": str(log_r["issue_count"]), "index_value": str(idx_r["issue_count"]),
                "recommendation": "re-run generator (scope is generator-derived from LOG)",
            })

        if log_r["status"] != idx_r["status"]:
            findings.append({
                "version": v, "field": "status",
                "log_value": log_r["status"], "index_value": idx_r["status"],
                "recommendation": "compare both; LOG row trailer is canonical state; re-run generator (or update LOG row state if Stage 13 transition was missed)",
            })

        # Plan-path validity — generator would emit "[plan](../../{path})" or "—"
        expected_plan = find_artifact(v, "plan")
        expected_plan_cell = f"[plan](../../{expected_plan})" if expected_plan else "—"
        if expected_plan_cell != idx_r["plan_cell"]:
            findings.append({
                "version": v, "field": "plan_path",
                "log_value": expected_plan_cell, "index_value": idx_r["plan_cell"],
                "recommendation": "re-run generator; filesystem moved/added plan file",
            })

        # Note-path validity — symmetric
        expected_note = find_artifact(v, "note")
        expected_note_cell = f"[note](../../{expected_note})" if expected_note else "—"
        if expected_note_cell != idx_r["note_cell"]:
            findings.append({
                "version": v, "field": "note_path",
                "log_value": expected_note_cell, "index_value": idx_r["note_cell"],
                "recommendation": "re-run generator",
            })

    return findings


def _self_test() -> int:
    """In-process synthetic LOG+INDEX pair with known drift. Asserts the
    verifier detects it. Precedent: check-doc-links.py --self-test.
    """
    # Synthetic LOG: 2 rows
    log_text = (
        "| Version | Date | Type | IMP Items | Description | Status |\n"
        "|---------|------|------|-----------|-------------|--------|\n"
        "| v99.01-self-test-a | 2026-05-23 | Foundation | [IMP-9999](u) | \"x\" | DEPLOYED |\n"
        "| v99.02-self-test-b | 2026-05-23 | Patch | [IMP-9998](u), [IMP-9997](u) | \"y\" | VERIFIED |\n"
    )
    log_rows = parse_log_rows(log_text)
    if len(log_rows) != 2:
        print(f"self-test FAIL: parse_log_rows returned {len(log_rows)} rows (expected 2)", file=sys.stderr)
        return 1

    # Synthetic INDEX with deliberate drift:
    #   - row 1 status drift (DEPLOYED in LOG, VERIFIED in INDEX) → C22-06
    #   - row 2 missing entirely → coexistence FAIL
    #   - extra row v99.03 not in LOG → coexistence FAIL (reverse)
    index_text = (
        "| Version | Date | Class | Scope | Plan | Note | LOG | Status |\n"
        "|---------|------|-------|-------|------|------|-----|--------|\n"
        "| v99.01-self-test-a | 2026-05-23 | Foundation | 1 | — | — | [LOG](../governance/RELEASE_LOG.md) | VERIFIED |\n"
        "| v99.03-self-test-c | 2026-05-23 | Patch | 1 | — | — | [LOG](../governance/RELEASE_LOG.md) | DEPLOYED |\n"
    )
    index_rows = parse_index_rows(index_text)
    if len(index_rows) != 2:
        print(f"self-test FAIL: parse_index_rows returned {len(index_rows)} rows (expected 2)", file=sys.stderr)
        return 1

    findings = verify(log_rows, index_rows)

    # Expected: 1 status drift + 1 LOG-only coexistence + 1 INDEX-only coexistence = 3
    expected_signatures = {
        ("v99.01-self-test-a", "status"),
        ("v99.02-self-test-b", "coexistence"),
        ("v99.03-self-test-c", "coexistence"),
    }
    actual_signatures = {(f["version"], f["field"]) for f in findings}
    missing = expected_signatures - actual_signatures
    if missing:
        print(f"self-test FAIL: missing expected findings {missing}", file=sys.stderr)
        print(f"actual findings: {actual_signatures}", file=sys.stderr)
        return 1
    if not expected_signatures.issubset(actual_signatures):
        print(f"self-test FAIL: expected={expected_signatures} actual={actual_signatures}", file=sys.stderr)
        return 1

    print("self-test PASSED — verifier detected 3 expected drift signatures (status, LOG-only, INDEX-only)")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--output-stdout", action="store_true", help="Print to stdout instead of writing to RELEASE_INDEX.md")
    p.add_argument("--verify", action="store_true", help="Re-generate INDEX to memory and diff vs on-disk RELEASE_INDEX.md; exit 1 on mismatch")
    p.add_argument("--self-test", action="store_true", help="Run in-process synthetic LOG+INDEX drift test; exit 0 on PASS")
    args = p.parse_args()

    if args.self_test:
        return _self_test()

    if not LOG_PATH.exists():
        print(f"error: RELEASE_LOG.md not found at {LOG_PATH}", file=sys.stderr)
        return 1

    log_text = LOG_PATH.read_text(encoding="utf-8")
    rows = parse_log_rows(log_text)
    if not rows:
        print("error: no LOG rows parsed — check ROW_RE pattern against current schema", file=sys.stderr)
        return 1

    if args.verify:
        if not INDEX_PATH.exists():
            print(f"error: RELEASE_INDEX.md not found at {INDEX_PATH}", file=sys.stderr)
            return 1
        index_text = INDEX_PATH.read_text(encoding="utf-8")
        index_rows = parse_index_rows(index_text)
        if not index_rows:
            print("error: no INDEX rows parsed — check INDEX_ROW_RE pattern against current rendered schema", file=sys.stderr)
            return 1
        findings = verify(rows, index_rows)
        if not findings:
            return 0
        # TSV-line per finding for downstream parseability
        for f in findings:
            print(f"{f['version']}\t{f['field']}\t{f['log_value']}\t{f['index_value']}\t{f['recommendation']}")
        return 1

    index_text = render_index(rows)

    if args.output_stdout:
        print(index_text)
    else:
        INDEX_PATH.write_text(index_text, encoding="utf-8")
        print(f"wrote {INDEX_PATH.relative_to(WORKSPACE_ROOT)} ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

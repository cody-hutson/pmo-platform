#!/usr/bin/env python3
"""Generate / verify RELEASE_INDEX.md against RELEASE_LOG.md table rows.

Parses the table rows in release/releases/RELEASE_LOG.md (live 8-column schema:
Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date) and
reconciles them against release/releases/RELEASE_INDEX.md (live 6-column schema:
Version | Milestone | Date | Theme | Release PR | Release Notes).

The INDEX is hand-authored at Stage 13 close (the Theme cell is free-prose not
derivable from the LOG). This tool serves two roles:

  default (write/--output-stdout): regenerate the 6-column INDEX from the LOG +
    filesystem (plan/note presence). Hand-authored Theme cells are PRESERVED
    from the existing on-disk INDEX (keyed by Version) so regeneration never
    clobbers prose the generator cannot reproduce; rows with no existing Theme
    get a placeholder.

  --verify (deploy.sh Check 23): re-derive the LOG-sourced fields and diff
    against the on-disk INDEX row-by-row, emitting TSV-line diagnostics on
    mismatch. Compares only LOG-derivable fields (Version coexistence,
    Milestone, Date, Release PR, Release-Notes-link presence) — the Theme cell
    has no LOG source of truth and is intentionally NOT drift-checked.

The earlier 8-column schema (Version|Date|Class|Scope|Plan|Note|LOG|Status) and
its #N-token "Scope" count are RETIRED — the live INDEX has no Scope column, so
the #N-token miscount the generator was filed to fix is moot by construction.

Usage:
    python3 core/deploy/tools/generate_release_index.py
    python3 core/deploy/tools/generate_release_index.py --output-stdout
    python3 core/deploy/tools/generate_release_index.py --verify
    python3 core/deploy/tools/generate_release_index.py --self-test

Exit codes: 0 = success (or --verify: full match), 1 = --verify drift,
3 = path-resolution / parse failure (LOG or INDEX missing/unreadable, or a
resolved file yields zero parseable rows — the surface is unverifiable, not
clean). Exit 3 matches the cross-module-audit.sh family convention (per #459)
so deploy.sh can distinguish "found drift" (1) from "could not run" (3).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
# Live modular-monolith layout (post-restructure). The pre-restructure
# pmo-platform/... prefix is DEAD. RELEASE_LOG.md is under release/releases/
# (NOT governance/).
LOG_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_LOG.md"
PLANS_DIR = WORKSPACE_ROOT / "release" / "releases" / "plans"
NOTES_DIR = WORKSPACE_ROOT / "release" / "releases" / "notes"
ARCHIVE_PLANS_DIR = WORKSPACE_ROOT / "release" / "releases" / "archive" / "plans"
INDEX_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_INDEX.md"

# Live LOG schema: | Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
# Version cell may be a bare version key (v1.06) OR a version-less slug with a
# "(version-less)" qualifier (public-flip-install-blockers (version-less)); the
# anchor must admit both, so it is NOT pinned to a leading "v". Header/separator
# rows are excluded by requiring field 1 to be non-empty and rejecting the
# literal "Version" header and the "---" separator in parse_log_rows.
LOG_ROW_RE = re.compile(r"^\|(?P<cells>(?:[^\|]*\|){7}[^\|]*)\|\s*$")

# Live INDEX schema: | Version | Milestone | Date | Theme | Release PR | Release Notes |
INDEX_ROW_RE = re.compile(
    r"^\| (?P<version>[^\|]+?) \| (?P<milestone>[^\|]+?) \| (?P<date>[^\|]+?) "
    r"\| (?P<theme>.*?) \| (?P<release_pr>[^\|]+?) \| (?P<notes>[^\|]+?) \|\s*$"
)


def _slug_from_version_cell(version_cell: str) -> str:
    """Strip the '(version-less)' qualifier from a LOG Version cell.

    The LOG Version cell is either a bare version key (v1.06) or a version-less
    slug carrying the qualifier (e.g. 'public-flip-install-blockers
    (version-less)'). Artifact filenames use the bare slug, so drop the
    qualifier before matching.
    """
    return version_cell.replace("(version-less)", "").strip()


def find_artifact(version_key: str, milestone: str, kind: str) -> str | None:
    """Locate a plan or note file by version key, then by milestone slug.

    `version_key` is the LOG Version cell (e.g. "v1.06" or a version-less slug);
    `milestone` is the LOG Milestone cell (e.g. "v1.06-solutioning-and-related").
    Artifact filenames key off either, so try the version slug first, then the
    milestone slug. Returns an INDEX-relative path string (the INDEX lives in
    release/releases/, so plan/note links are "plans/<name>" / "notes/<name>"),
    or None.
    """
    if kind == "plan":
        directory = PLANS_DIR
        suffix = "_RELEASE_PLAN.md"
    else:
        directory = NOTES_DIR
        suffix = "_RELEASE_NOTES.md"

    if not directory.exists():
        return None

    vslug = _slug_from_version_cell(version_key)
    mslug = milestone.strip()
    keys = [k for k in (vslug, mslug) if k]
    short = vslug.split("-", 1)[0] if vslug else ""

    for candidate in sorted(directory.glob(f"*{suffix}")):
        name = candidate.name
        stem_key = name[:-len(suffix)]
        for key in keys:
            if stem_key == key:
                return f"{directory.name}/{name}"
            if key and stem_key.startswith(key):
                return f"{directory.name}/{name}"
        if short and (vslug.startswith(stem_key + "-") and stem_key.startswith(short)):
            return f"{directory.name}/{name}"

    if kind == "plan" and ARCHIVE_PLANS_DIR.exists():
        for candidate in sorted(ARCHIVE_PLANS_DIR.glob(f"*{suffix}")):
            stem_key = candidate.name[:-len(suffix)]
            for key in keys:
                if stem_key == key:
                    return f"archive/plans/{candidate.name}"

    return None


def parse_log_rows(log_text: str) -> list[dict]:
    """Parse the live 8-column RELEASE_LOG table by field position.

    Schema: | Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
    Field index (1-based): 1=Version 2=Milestone 3=Issues 4=Release PR
    7=State 8=Date. Header ("Version") and separator ("---") rows are skipped.
    Version-less rows (Version cell carrying "(version-less)") parse normally —
    the slug qualifier is retained in the cell and stripped at artifact lookup.
    """
    rows: list[dict] = []
    for raw_line in log_text.splitlines():
        m = LOG_ROW_RE.match(raw_line)
        if not m:
            continue
        cells = [c.strip() for c in m.group("cells").split("|")]
        if len(cells) != 8:
            continue
        version = cells[0]
        # Skip header + separator rows.
        if not version or version == "Version" or set(version) <= set("-: "):
            continue
        rows.append({
            "version": version,
            "milestone": cells[1],
            "release_pr": cells[3],
            "state": cells[6],
            "date": cells[7],
        })
    return rows


THEME_PLACEHOLDER = "—"


def render_index(rows: list[dict], existing_themes: dict[str, str] | None = None) -> str:
    """Render the live 6-column INDEX from LOG rows + filesystem note lookup.

    Schema: | Version | Milestone | Date | Theme | Release PR | Release Notes |
    The Theme cell is hand-authored prose with no LOG source; `existing_themes`
    (keyed by Version) preserves it across regeneration so the generator never
    clobbers prose it cannot reproduce. Rows with no existing Theme get a
    placeholder for the operator to fill at Stage 13 close.
    """
    existing_themes = existing_themes or {}
    out: list[str] = []
    out.append("# RELEASE_INDEX")
    out.append("")
    out.append("Corpus-level index of all pmo-platform releases. Chronological-recent-first row order. "
               "Appended at Stage 13 chore PR per [`stage-13-close.md § Phase B`](../references/pipeline/stage-13-close.md).")
    out.append("")
    out.append("| Version | Milestone | Date | Theme | Release PR | Release Notes |")
    out.append("|---|---|---|---|---|---|")
    for r in rows:
        note_path = find_artifact(r["version"], r.get("milestone", ""), "note")
        note_cell = f"[{note_path}]({note_path})" if note_path else "—"
        theme = existing_themes.get(r["version"], "").strip() or THEME_PLACEHOLDER
        release_pr = r.get("release_pr", "").strip() or "—"
        out.append(
            f"| {r['version']} | {r.get('milestone', '').strip()} | {r['date']} "
            f"| {theme} | {release_pr} | {note_cell} |"
        )
    out.append("")
    return "\n".join(out)


def parse_index_rows(index_text: str) -> list[dict]:
    """Parse the live 6-column RELEASE_INDEX.md rows.

    Schema: | Version | Milestone | Date | Theme | Release PR | Release Notes |
    Header ("Version") and separator ("---") rows are skipped. Returns per-row
    dict with keys: version, milestone, date, theme, release_pr, notes_cell
    (raw cell text — "—" or "[notes/...](notes/...)").
    """
    rows: list[dict] = []
    for raw_line in index_text.splitlines():
        m = INDEX_ROW_RE.match(raw_line)
        if not m:
            continue
        version = m.group("version").strip()
        if not version or version == "Version" or set(version) <= set("-: "):
            continue
        rows.append({
            "version": version,
            "milestone": m.group("milestone").strip(),
            "date": m.group("date").strip(),
            "theme": m.group("theme").strip(),
            "release_pr": m.group("release_pr").strip(),
            "notes_cell": m.group("notes").strip(),
        })
    return rows


def verify(log_rows: list[dict], index_rows: list[dict]) -> list[dict]:
    """Compare LOG-derived expectation vs the on-disk 6-column INDEX.

    Each finding: {version, field, log_value, index_value, recommendation}.
    Empty list = full match. Compares ONLY LOG-derivable fields — Version
    coexistence, Milestone, Date, Release PR, and the filesystem-derived
    Release-Notes-link presence. The Theme cell is hand-authored prose with no
    LOG source of truth, so it is intentionally NOT drift-checked (Check 23
    detects LOG↔INDEX drift, not Theme-prose edits).
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

        if log_r["milestone"] != idx_r["milestone"]:
            findings.append({
                "version": v, "field": "milestone",
                "log_value": log_r["milestone"], "index_value": idx_r["milestone"],
                "recommendation": "LOG Milestone is canonical; re-run generator to refresh INDEX",
            })

        if log_r["date"] != idx_r["date"]:
            findings.append({
                "version": v, "field": "date",
                "log_value": log_r["date"], "index_value": idx_r["date"],
                "recommendation": "LOG is canonical for deploy-date; re-run generator to refresh INDEX",
            })

        if log_r["release_pr"] != idx_r["release_pr"]:
            findings.append({
                "version": v, "field": "release_pr",
                "log_value": log_r["release_pr"], "index_value": idx_r["release_pr"],
                "recommendation": "LOG Release PR is canonical; re-run generator to refresh INDEX",
            })

        # Release-Notes-link validity — generator would emit "[notes/..](notes/..)" or "—"
        expected_note = find_artifact(v, log_r.get("milestone", ""), "note")
        expected_note_cell = f"[{expected_note}]({expected_note})" if expected_note else "—"
        if expected_note_cell != idx_r["notes_cell"]:
            findings.append({
                "version": v, "field": "notes_link",
                "log_value": expected_note_cell, "index_value": idx_r["notes_cell"],
                "recommendation": "re-run generator; filesystem moved/added note file",
            })

    return findings


def _self_test() -> int:
    """In-process synthetic LOG (8-col) + INDEX (6-col) pair with known drift.

    Asserts the parsers handle the live schemas (including a version-less row)
    and the verifier detects coexistence + per-field drift. Precedent:
    check-doc-links.py --self-test.
    """
    # Synthetic LOG — live 8-column schema, incl. a version-less row.
    log_text = (
        "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| v99.01 | v99.01-self-test-a | #9999 | #100 | `deadbeef` | `v99.01` | VERIFIED | 2026-05-23 |\n"
        "| v99.02 | v99.02-self-test-b | #9998, #9997 | #200 | `cafef00d` | `v99.02` | VERIFIED | 2026-05-23 |\n"
        "| self-test-vl (version-less) | self-test-vl | #9996 | #300 | `feedface` | (none) | VERIFIED | 2026-05-24 |\n"
    )
    log_rows = parse_log_rows(log_text)
    if len(log_rows) != 3:
        print(f"self-test FAIL: parse_log_rows returned {len(log_rows)} rows (expected 3)", file=sys.stderr)
        return 1
    # Field-mapping assertions (the #85 root cause was a field-mismap).
    r0 = log_rows[0]
    if not (r0["version"] == "v99.01" and r0["milestone"] == "v99.01-self-test-a"
            and r0["release_pr"] == "#100" and r0["date"] == "2026-05-23"):
        print(f"self-test FAIL: LOG field-mapping wrong for row 0: {r0}", file=sys.stderr)
        return 1
    # Version-less row must parse (relaxed anchor).
    if log_rows[2]["version"] != "self-test-vl (version-less)":
        print(f"self-test FAIL: version-less LOG row dropped: {log_rows}", file=sys.stderr)
        return 1

    # Synthetic INDEX — live 6-column schema, with deliberate drift:
    #   - v99.01 Milestone drift (LOG says self-test-a; INDEX says WRONG-slug)
    #   - v99.02 missing entirely → coexistence (LOG-only)
    #   - extra v99.90 not in LOG → coexistence (INDEX-only)
    #   - self-test-vl present + aligned (no finding — proves version-less round-trip)
    index_text = (
        "# RELEASE_INDEX\n\n"
        "| Version | Milestone | Date | Theme | Release PR | Release Notes |\n"
        "|---|---|---|---|---|---|\n"
        "| v99.01 | WRONG-slug | 2026-05-23 | Hand-authored theme prose | #100 | — |\n"
        "| v99.90 | v99.90-not-in-log | 2026-05-23 | Stale theme | #900 | — |\n"
        "| self-test-vl (version-less) | self-test-vl | 2026-05-24 | VL theme | #300 | — |\n"
    )
    index_rows = parse_index_rows(index_text)
    if len(index_rows) != 3:
        print(f"self-test FAIL: parse_index_rows returned {len(index_rows)} rows (expected 3)", file=sys.stderr)
        return 1
    # Theme must parse intact (free-prose cell).
    if index_rows[0]["theme"] != "Hand-authored theme prose":
        print(f"self-test FAIL: Theme cell mis-parsed: {index_rows[0]}", file=sys.stderr)
        return 1

    findings = verify(log_rows, index_rows)

    # Expected: v99.01 milestone drift + v99.02 LOG-only + v99.90 INDEX-only.
    expected_signatures = {
        ("v99.01", "milestone"),
        ("v99.02", "coexistence"),
        ("v99.90", "coexistence"),
    }
    actual_signatures = {(f["version"], f["field"]) for f in findings}
    missing = expected_signatures - actual_signatures
    if missing:
        print(f"self-test FAIL: missing expected findings {missing}", file=sys.stderr)
        print(f"actual findings: {actual_signatures}", file=sys.stderr)
        return 1
    # The aligned version-less row must NOT produce a coexistence finding.
    if ("self-test-vl (version-less)", "coexistence") in actual_signatures:
        print("self-test FAIL: aligned version-less row wrongly flagged", file=sys.stderr)
        return 1
    # Theme drift must NOT be flagged (no LOG source of truth).
    if any(f["field"] == "theme" for f in findings):
        print("self-test FAIL: Theme should not be drift-checked (no LOG source)", file=sys.stderr)
        return 1

    print("self-test PASSED — 6-col verifier detected 3 expected drift signatures "
          "(milestone, LOG-only, INDEX-only); version-less round-trip + Theme-skip confirmed")
    return 0


def _existing_theme_map() -> dict[str, str]:
    """Read the on-disk INDEX (if present) and map Version -> Theme so a
    regenerate preserves hand-authored Theme prose. Returns {} if absent."""
    if not INDEX_PATH.exists():
        return {}
    try:
        existing = parse_index_rows(INDEX_PATH.read_text(encoding="utf-8"))
    except OSError:
        return {}
    out: dict[str, str] = {}
    for r in existing:
        theme = r.get("theme", "").strip()
        if theme and theme != THEME_PLACEHOLDER:
            out[r["version"]] = theme
    return out


def _rel(path: Path) -> str:
    try:
        return str(path.relative_to(WORKSPACE_ROOT))
    except ValueError:
        return str(path)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--output-stdout", action="store_true", help="Print to stdout instead of writing to RELEASE_INDEX.md")
    p.add_argument("--verify", action="store_true", help="Re-derive LOG-sourced fields and diff vs on-disk RELEASE_INDEX.md; exit 1 on drift, exit 3 on path/parse failure")
    p.add_argument("--self-test", action="store_true", help="Run in-process synthetic LOG+INDEX drift test; exit 0 on PASS")
    args = p.parse_args()

    if args.self_test:
        return _self_test()

    # Path-resolution failure (clause 1): LOG missing → exit 3, NOT a silent
    # pass and NOT a drift-exit-1. The check is unverifiable; deploy.sh maps
    # exit 3 to FAIL/DRIFT (per #459).
    if not LOG_PATH.exists():
        print(f"error: path-resolution failure — RELEASE_LOG.md not found at {_rel(LOG_PATH)}", file=sys.stderr)
        return 3

    log_text = LOG_PATH.read_text(encoding="utf-8")
    rows = parse_log_rows(log_text)
    if not rows:
        # Parse failure on a resolved file = schema drift between tool and corpus,
        # a config error → exit 3 (NOT a masked exit 0/1).
        print("error: path-resolution failure — no LOG rows parsed (LOG_ROW_RE vs current schema mismatch)", file=sys.stderr)
        return 3

    if args.verify:
        if not INDEX_PATH.exists():
            print(f"error: path-resolution failure — RELEASE_INDEX.md not found at {_rel(INDEX_PATH)}", file=sys.stderr)
            return 3
        index_text = INDEX_PATH.read_text(encoding="utf-8")
        index_rows = parse_index_rows(index_text)
        if not index_rows:
            print("error: path-resolution failure — no INDEX rows parsed (INDEX_ROW_RE vs current rendered schema mismatch)", file=sys.stderr)
            return 3
        findings = verify(rows, index_rows)
        if not findings:
            return 0
        # TSV-line per finding for downstream parseability
        for f in findings:
            print(f"{f['version']}\t{f['field']}\t{f['log_value']}\t{f['index_value']}\t{f['recommendation']}")
        return 1

    index_text = render_index(rows, _existing_theme_map())

    if args.output_stdout:
        print(index_text)
    else:
        INDEX_PATH.write_text(index_text, encoding="utf-8")
        print(f"wrote {_rel(INDEX_PATH)} ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

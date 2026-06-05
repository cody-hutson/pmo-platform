#!/usr/bin/env python3
"""Framework version-anchor drift detection primitive (deploy.sh Check 18).

Catalog-registry-driven (NOT prose corpus-scan) per ADR-v11.12-002.
Reads pmo-platform/reference/specs/framework-catalog.md (the governed registry,
parallels Check 13's TEMPLATE_SYNC_MAP) and runs three sub-checks:

  18a  catalog completeness  — every data row has non-empty framework/class/
       version_anchor/tier/last_reviewed/next_review_due; review_cadence matches
       tier; class/tier within enum. (structural, ~zero-FP) — severity P1.
  18b  catalog<->doc anchor consistency — for each row whose canonical_doc != '—'
       AND that doc carries YAML frontmatter with a framework_version_anchor: key,
       assert it equals the catalog version_anchor. Docs without YAML frontmatter,
       or frontmatter docs lacking the key, are SKIPped (documented v1 limitation;
       the key is a SHOULD demonstration, not a hard requirement — 18b is a
       consistency check, it only fires on an actual disagreement). — severity P1.
  18c  cadence aging — rows where next_review_due (a date) <= today are overdue.
       next_review_due == 'continuous' is skipped (emerging tier). — severity P3.

Interface:
  --catalog-path PATH    catalog markdown (default: pmo-platform/reference/specs/framework-catalog.md)
  --output-format tsv|json   (default tsv)
  --self-test            run internal smoke test and exit

TSV columns: framework<TAB>check<TAB>detail<TAB>severity
Exit codes: 0 = no findings, 1 = findings found.

Authored under the v11.12 Stage 5 spec. Error-isolation idiom
mirrors check-doc-links.py (Check 14): missing catalog -> single clean finding +
exit 1, never an unhandled traceback.
"""
from __future__ import annotations

import argparse
import datetime
import json
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]

DEFAULT_CATALOG_REL = "pmo-platform/reference/specs/framework-catalog.md"

CLASS_ENUM = {"EXTERNAL", "INTERNAL"}
TIER_ENUM = {"stable", "evolving", "emerging"}
TIER_CADENCE = {"stable": "36mo", "evolving": "12mo", "emerging": "continuous"}
REQUIRED_NONEMPTY = ("framework", "class", "version_anchor", "tier", "last_reviewed", "next_review_due")
EXPECTED_COLS = (
    "framework", "class", "version_anchor", "canonical_doc", "adopted",
    "applicability_scope", "tier", "review_cadence", "last_reviewed",
    "next_review_due", "owner",
)
NULL_DOC = {"—", "-", ""}


def _norm_cell(cell: str) -> str:
    return cell.strip().strip("`").strip()


def parse_catalog_table(text: str) -> tuple[list[dict], str | None]:
    """Locate and parse the catalog table. Returns (rows, error).

    The catalog file contains more than one markdown table (a schema table and
    the catalog table). The catalog table is identified as the first table whose
    header cell-set is a superset of {framework, class, version_anchor, tier}.
    """
    lines = text.splitlines()
    header_idx = None
    header_cells: list[str] = []
    for i, line in enumerate(lines):
        s = line.strip()
        if not (s.startswith("|") and s.endswith("|")):
            continue
        cells = [_norm_cell(c) for c in s.strip("|").split("|")]
        cellset = {c for c in cells}
        if {"framework", "class", "version_anchor", "tier"}.issubset(cellset):
            header_idx = i
            header_cells = cells
            break
    if header_idx is None:
        return [], "catalog table not found (no header row containing framework/class/version_anchor/tier)"

    # Next non-empty table line must be the separator (|---|---|...).
    sep_idx = header_idx + 1
    if sep_idx >= len(lines) or "---" not in lines[sep_idx]:
        return [], "catalog table malformed (missing separator row after header)"

    rows: list[dict] = []
    for line in lines[sep_idx + 1:]:
        s = line.strip()
        if not (s.startswith("|") and s.endswith("|")):
            break  # table ended
        cells = [c.strip() for c in s.strip("|").split("|")]
        # Tolerate trailing/leading whitespace count; map by position to header.
        row = {}
        for idx, col in enumerate(header_cells):
            row[col] = cells[idx].strip() if idx < len(cells) else ""
        rows.append(row)
    return rows, None


def check_18a(rows: list[dict]) -> list[dict]:
    findings: list[dict] = []
    for row in rows:
        fw = row.get("framework", "") or "(blank)"
        for col in REQUIRED_NONEMPTY:
            if not row.get(col, "").strip():
                findings.append({
                    "framework": fw, "check": "18a-completeness",
                    "detail": f"required column '{col}' is empty",
                    "severity": "P1",
                })
        cls = row.get("class", "").strip()
        if cls and cls not in CLASS_ENUM:
            findings.append({
                "framework": fw, "check": "18a-completeness",
                "detail": f"class '{cls}' not in enum {sorted(CLASS_ENUM)}",
                "severity": "P1",
            })
        tier = row.get("tier", "").strip()
        if tier and tier not in TIER_ENUM:
            findings.append({
                "framework": fw, "check": "18a-completeness",
                "detail": f"tier '{tier}' not in enum {sorted(TIER_ENUM)}",
                "severity": "P1",
            })
        cadence = row.get("review_cadence", "").strip()
        if tier in TIER_CADENCE and cadence and cadence != TIER_CADENCE[tier]:
            findings.append({
                "framework": fw, "check": "18a-completeness",
                "detail": f"review_cadence '{cadence}' does not match tier '{tier}' (expected '{TIER_CADENCE[tier]}')",
                "severity": "P1",
            })
    return findings


def _read_doc_frontmatter_anchor(doc_path: Path) -> tuple[str | None, str]:
    """Return (anchor_value_or_None, status).

    status ∈ {"no-file", "no-frontmatter", "frontmatter-no-key", "ok"}.
    anchor_value is the stripped framework_version_anchor: value when status=="ok".
    """
    if not doc_path.exists():
        return None, "no-file"
    try:
        text = doc_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None, "no-file"
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, "no-frontmatter"
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if line.startswith("framework_version_anchor:"):
            val = line.split(":", 1)[1].strip()
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
            return val.strip(), "ok"
    return None, "frontmatter-no-key"


def check_18b(rows: list[dict]) -> list[dict]:
    findings: list[dict] = []
    for row in rows:
        fw = row.get("framework", "") or "(blank)"
        doc = row.get("canonical_doc", "").strip()
        if doc in NULL_DOC:
            continue  # no doc to consistency-check
        catalog_anchor = row.get("version_anchor", "").strip()
        doc_path = doc if Path(doc).is_absolute() else WORKSPACE_ROOT / doc
        anchor, status = _read_doc_frontmatter_anchor(Path(doc_path))
        if status in ("no-frontmatter", "frontmatter-no-key", "no-file"):
            # SKIP: documented v1 limitation. No YAML frontmatter / no key /
            # missing doc => nothing to assert (18b is a consistency check, not
            # a presence check). 'no-file' is reported by 18a's path indirectly
            # only if canonical_doc were required; here it is intentionally a
            # silent skip to keep zero-FP in warn-mode shakedown.
            continue
        if anchor != catalog_anchor:
            findings.append({
                "framework": fw, "check": "18b-consistency",
                "detail": f"{doc} framework_version_anchor '{anchor}' != catalog version_anchor '{catalog_anchor}'",
                "severity": "P1",
            })
    return findings


def check_18c(rows: list[dict], today: datetime.date) -> list[dict]:
    findings: list[dict] = []
    for row in rows:
        fw = row.get("framework", "") or "(blank)"
        nrd = row.get("next_review_due", "").strip()
        if not nrd or nrd.lower() == "continuous":
            continue
        try:
            due = datetime.date.fromisoformat(nrd)
        except ValueError:
            # Malformed date is a completeness problem; 18a covers non-empty but
            # not format. Surface here as an aging-check parse note (P3).
            findings.append({
                "framework": fw, "check": "18c-aging",
                "detail": f"next_review_due '{nrd}' is not an ISO date (YYYY-MM-DD)",
                "severity": "P3",
            })
            continue
        if due <= today:
            findings.append({
                "framework": fw, "check": "18c-aging",
                "detail": f"next_review_due {nrd} is on/before today {today.isoformat()} — framework review overdue",
                "severity": "P3",
            })
    return findings


def run_all(catalog_path: Path, today: datetime.date | None = None) -> tuple[list[dict], str | None]:
    if today is None:
        today = datetime.date.today()
    if not catalog_path.exists():
        return [{
            "framework": "(catalog)", "check": "18a-completeness",
            "detail": f"catalog file not found: {catalog_path}", "severity": "P1",
        }], None
    try:
        text = catalog_path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        return [{
            "framework": "(catalog)", "check": "18a-completeness",
            "detail": f"catalog unreadable: {e}", "severity": "P1",
        }], None
    rows, err = parse_catalog_table(text)
    if err:
        return [{
            "framework": "(catalog)", "check": "18a-completeness",
            "detail": err, "severity": "P1",
        }], None
    findings: list[dict] = []
    findings += check_18a(rows)
    findings += check_18b(rows)
    findings += check_18c(rows, today)
    return findings, None


def emit_tsv(findings: list[dict]) -> str:
    header = "framework\tcheck\tdetail\tseverity"
    out = [header]
    for f in findings:
        out.append(f"{f['framework']}\t{f['check']}\t{f['detail']}\t{f['severity']}")
    return "\n".join(out)


def emit_json(findings: list[dict]) -> str:
    return json.dumps(findings, indent=2)


def run_self_test() -> int:
    import tempfile

    clean = """---
title: T
---
# Catalog

| Column | Type | Rule |
|---|---|---|
| framework | string | decoy schema table — must NOT be parsed as the catalog |

## Catalog

| framework | class | version_anchor | canonical_doc | adopted | applicability_scope | tier | review_cadence | last_reviewed | next_review_due | owner |
|---|---|---|---|---|---|---|---|---|---|---|
| Alpha | EXTERNAL | Alpha 1.0 | — | v1 | scope | stable | 36mo | 2026-05-15 | 2099-01-01 | Owner |
| Beta | INTERNAL | v9.0 | — | v9.0 | scope | evolving | 12mo | 2026-05-15 | continuous | Owner |
"""
    with tempfile.TemporaryDirectory() as td:
        p = Path(td) / "framework-catalog.md"
        p.write_text(clean, encoding="utf-8")
        findings, err = run_all(p, today=datetime.date(2026, 5, 15))
        assert err is None, f"unexpected error: {err}"
        assert findings == [], f"clean catalog must yield zero findings, got: {findings}"

        # Decoy-table discrimination: the schema table header is Column|Type|Rule
        # and must be skipped; the real table parsed has Alpha + Beta.
        rows, perr = parse_catalog_table(clean)
        assert perr is None and len(rows) == 2, f"expected 2 data rows, got {len(rows)} ({perr})"
        assert rows[0]["framework"] == "Alpha"

        # 18a: missing version_anchor + bad enum + cadence/tier mismatch.
        dirty = clean.replace(
            "| Alpha | EXTERNAL | Alpha 1.0 | — | v1 | scope | stable | 36mo | 2026-05-15 | 2099-01-01 | Owner |",
            "| Alpha | SIDEWAYS |  | — | v1 | scope | stable | 12mo | 2026-05-15 | 2099-01-01 | Owner |",
        )
        pd = Path(td) / "dirty.md"
        pd.write_text(dirty, encoding="utf-8")
        df, _ = run_all(pd, today=datetime.date(2026, 5, 15))
        kinds = {(f["check"], f["detail"]) for f in df}
        assert any("version_anchor' is empty" in d for _, d in kinds), f"missing-anchor not caught: {df}"
        assert any("class 'SIDEWAYS'" in d for _, d in kinds), f"enum violation not caught: {df}"
        assert any("review_cadence '12mo' does not match tier 'stable'" in d for _, d in kinds), f"cadence mismatch not caught: {df}"

        # 18c: past next_review_due triggers aging (P3).
        aged = clean.replace("2099-01-01", "2020-01-01")
        pa = Path(td) / "aged.md"
        pa.write_text(aged, encoding="utf-8")
        af, _ = run_all(pa, today=datetime.date(2026, 5, 15))
        assert any(f["check"] == "18c-aging" and f["severity"] == "P3" for f in af), f"aging not caught: {af}"

        # 18b: catalog<->doc divergence on a YAML-frontmatter doc.
        doc = Path(td) / "thedoc.md"
        doc.write_text("---\ntitle: D\nframework_version_anchor: \"v8.0\"\n---\n# D\n", encoding="utf-8")
        consist = clean.replace(
            "| Beta | INTERNAL | v9.0 | — | v9.0 | scope | evolving | 12mo | 2026-05-15 | continuous | Owner |",
            f"| Beta | INTERNAL | v9.0 | {doc} | v9.0 | scope | evolving | 12mo | 2026-05-15 | continuous | Owner |",
        )
        pc = Path(td) / "consist.md"
        pc.write_text(consist, encoding="utf-8")
        cf, _ = run_all(pc, today=datetime.date(2026, 5, 15))
        assert any(f["check"] == "18b-consistency" for f in cf), f"18b divergence not caught: {cf}"

        # 18b SKIP: no-frontmatter doc must NOT produce a finding.
        ndoc = Path(td) / "nofm.md"
        ndoc.write_text("# No Frontmatter\n\n**Status:** Canonical\n", encoding="utf-8")
        skipc = clean.replace(
            "| Beta | INTERNAL | v9.0 | — | v9.0 | scope | evolving | 12mo | 2026-05-15 | continuous | Owner |",
            f"| Beta | INTERNAL | v9.0 | {ndoc} | v9.0 | scope | evolving | 12mo | 2026-05-15 | continuous | Owner |",
        )
        ps = Path(td) / "skip.md"
        ps.write_text(skipc, encoding="utf-8")
        sf, _ = run_all(ps, today=datetime.date(2026, 5, 15))
        assert not any(f["check"] == "18b-consistency" for f in sf), f"no-frontmatter doc must SKIP 18b, got: {sf}"

    print("self-test OK")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--catalog-path", default=None,
                    help=f"catalog markdown (default: {DEFAULT_CATALOG_REL} under workspace root)")
    ap.add_argument("--output-format", choices=["tsv", "json"], default="tsv")
    ap.add_argument("--self-test", action="store_true", help="run internal smoke test and exit")
    args = ap.parse_args()

    if args.self_test:
        return run_self_test()

    if args.catalog_path:
        cp = Path(args.catalog_path)
        catalog_path = cp if cp.is_absolute() else WORKSPACE_ROOT / cp
    else:
        catalog_path = WORKSPACE_ROOT / DEFAULT_CATALOG_REL

    findings, err = run_all(catalog_path)
    if err:
        print(err, file=sys.stderr)
        return 1
    if args.output_format == "tsv":
        print(emit_tsv(findings))
    else:
        print(emit_json(findings))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

"""Markdown / text renderers for QA-as-code results.

The Markdown shape follows the established platform test-report template
(core/standards/regression-checks.md § Test Report Template): a header meta
block, a results table, and a summary count block — extended with `Finding` and
`Remedy` columns. The `Finding` column keys each row to its onboarding-QA
finding; `Remedy` carries the actionable fix a downstream doctor surfaces.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Dict, List, Optional

from . import checks

SUITE_NAME = "onboarding-install/update QA-as-code"


def _counts(results: List["checks.CheckResult"]):
    total = len(results)
    passed = sum(1 for r in results if r.status == checks.PASS)
    failed = sum(1 for r in results if r.status == checks.FAIL)
    skipped = sum(1 for r in results if r.status == checks.SKIP)
    return total, passed, failed, skipped


def _cell(text: str) -> str:
    """Make a string safe inside a Markdown table cell (no pipe/newline breaks)."""
    return text.replace("|", "\\|").replace("\n", " ").strip()


def _default_date() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def render_markdown(results: List["checks.CheckResult"], meta: Optional[Dict[str, str]] = None) -> str:
    """Render results as a Markdown regression report (established test-report shape)."""
    meta = dict(meta or {})
    total, passed, failed, skipped = _counts(results)
    verdict = "PASS" if failed == 0 else "FAIL"

    lines: List[str] = []
    lines.append("## QA-as-code Regression Report")
    lines.append("")
    lines.append(f"**Suite:** {meta.get('suite', SUITE_NAME)}")
    lines.append(f"**Date:** {meta.get('date') or _default_date()}")
    if meta.get("version"):
        lines.append(f"**Version:** {meta['version']}")
    if meta.get("sha"):
        lines.append(f"**Repo SHA:** {meta['sha']}")
    lines.append("")
    lines.append("### Results")
    lines.append("")
    lines.append("| Finding | Check | Status | Evidence | Remedy |")
    lines.append("|---|---|---|---|---|")
    for r in results:
        remedy = _cell(r.remedy) if (r.status == checks.FAIL and r.remedy) else "—"
        lines.append(
            f"| {r.finding_id} | {_cell(r.title)} | {r.status} | {_cell(r.evidence)} | {remedy} |"
        )
    lines.append("")
    lines.append("### Summary")
    lines.append(f"- Total checks: {total}")
    lines.append(f"- PASS: {passed}")
    lines.append(f"- FAIL: {failed}")
    lines.append(f"- SKIP: {skipped}")
    lines.append("")
    lines.append(f"**Verdict:** {verdict}")
    lines.append("")
    return "\n".join(lines)


def render_text(results: List["checks.CheckResult"], meta: Optional[Dict[str, str]] = None) -> str:
    """Render results as a compact plain-text report."""
    meta = dict(meta or {})
    total, passed, failed, skipped = _counts(results)
    verdict = "PASS" if failed == 0 else "FAIL"

    lines: List[str] = []
    lines.append(f"QA-as-code Regression Report — {meta.get('suite', SUITE_NAME)}")
    lines.append(f"Date: {meta.get('date') or _default_date()}")
    if meta.get("version"):
        lines.append(f"Version: {meta['version']}")
    if meta.get("sha"):
        lines.append(f"Repo SHA: {meta['sha']}")
    lines.append("-" * 70)
    for r in results:
        lines.append(f"[{r.status:4}] {r.finding_id:<3} {r.title}")
        lines.append(f"        evidence: {r.evidence}")
        if r.status == checks.FAIL and r.remedy:
            lines.append(f"        remedy:   {r.remedy}")
    lines.append("-" * 70)
    lines.append(f"Total: {total}  PASS: {passed}  FAIL: {failed}  SKIP: {skipped}  — VERDICT {verdict}")
    return "\n".join(lines)

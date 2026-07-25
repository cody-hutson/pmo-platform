"""Aggregate the QA checks, render the report, and select a process exit code.

Exit codes:
    0  all checks PASS (SKIP is not a failure)
    1  at least one check FAIL
    2  internal error (a check registry / dispatch fault, not a finding FAIL)
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Set

from . import checks, report

EXIT_OK = 0
EXIT_FAIL = 1
EXIT_ERROR = 2


def run_all(only: Optional[Set[str]] = None, read_only_only: bool = False) -> List["checks.CheckResult"]:
    """Run the registered checks (optionally filtered) and return their results."""
    results: List["checks.CheckResult"] = []
    for c in checks.registry():
        if read_only_only and not c.read_only:
            continue
        if only and c.finding_id not in only:
            continue
        results.append(c.fn(None))
    return results


def exit_code(results: List["checks.CheckResult"]) -> int:
    """0 when no FAIL is present, 1 otherwise (SKIP never fails)."""
    return EXIT_FAIL if any(r.status == checks.FAIL for r in results) else EXIT_OK


def _repo_meta() -> Dict[str, str]:
    """Best-effort header metadata (platform version + short git SHA) for the report."""
    root = Path(__file__).resolve().parents[3]
    meta: Dict[str, str] = {}
    try:
        first_line = root.joinpath(".version").read_text(encoding="utf-8").strip().splitlines()
        if first_line:
            meta["version"] = first_line[0].strip()
    except OSError:
        pass
    try:
        proc = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            meta["sha"] = proc.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    return meta


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        prog="qa", description="pmo-platform QA-as-code regression suite (F1-F10 + R1/R2)"
    )
    parser.add_argument("--only", help="comma-separated finding IDs to run (e.g. F1,F5,R2)")
    parser.add_argument(
        "--read-only", action="store_true",
        help="run only read_only checks (the whole suite is read-only by construction)",
    )
    parser.add_argument("--format", choices=["md", "text"], default="md", help="report format (default: md)")
    parser.add_argument("--list", action="store_true", help="list the registered finding checks and exit")
    args = parser.parse_args(argv)

    if args.list:
        for c in checks.registry():
            sys.stdout.write(f"{c.finding_id}\t{c.title}\n")
        return EXIT_OK

    try:
        only = {x.strip() for x in args.only.split(",") if x.strip()} if args.only else None
        results = run_all(only=only, read_only_only=args.read_only)
    except Exception as err:  # noqa: BLE001 — dispatch fault is EXIT_ERROR, not a finding FAIL
        sys.stderr.write(f"qa: internal error running checks: {err!r}\n")
        return EXIT_ERROR

    meta = _repo_meta()
    out = report.render_markdown(results, meta) if args.format == "md" else report.render_text(results, meta)
    sys.stdout.write(out if out.endswith("\n") else out + "\n")
    return exit_code(results)

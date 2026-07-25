"""pmo-platform QA-as-code regression suite — public package surface + data-flow contract.

This package turns the manual onboarding-install/update QA findings (F1-F10 plus
the two regression-harness guards R1/R2) into a runnable, read-only regression
suite. It is a standalone module: nothing in install.sh / update.sh /
orchestrate.sh imports or invokes it (the auto-run wiring is a deferred
follow-up); it runs via `./qa.sh` or `python3 -m qa`.

────────────────────────────────────────────────────────────────────────────
Data-flow contract (Tier-A design artifact — a cross-component output format
with >=2 downstream consumers). This docstring is the SSOT for that contract.

Producer: this package's check registry.
Consumers:
  - a `doctor` command, which imports the registry read-only subset and filters
    by `CheckResult.read_only` (the whole registry is read-only), surfacing each
    result's `remedy` as an actionable diagnostic;
  - a CI matrix job, which runs `./qa.sh` and asserts the process exit code.

1. Registry API
     registry() -> list[Check]              # insertion-ordered check records
     check(finding_id, title, read_only=True)   # decorator that registers a check
     FINDING_IDS: list[str]                 # canonical enumeration (F1..F10, R1, R2)
   Each Check binds: finding_id, title, read_only, fn(root: Optional[Path]) -> CheckResult.
   Registry invariant (asserted by core/deploy/tests/test_qa_module.py): the set
   of registered finding_ids equals set(FINDING_IDS), 1:1, no duplicates, len 12.

2. CheckResult schema (dataclass)
     finding_id : str   the F#/R# covered
     title      : str   one-line technical description of the guard
     status     : str   "PASS" | "FAIL" | "SKIP"
     evidence   : str   grounding for the status
     remedy     : str   the fix when status == FAIL (empty otherwise)
     read_only  : bool  always True — checks never mutate platform state

3. Report format (report.render_markdown / render_text)
   Markdown = header meta (suite / date / version / repo SHA) + results table
   `| Finding | Check | Status | Evidence | Remedy |` + summary counts
   (Total / PASS / FAIL / SKIP) + verdict. Follows the established platform
   test-report template (core/standards/regression-checks.md).

4. Exit codes (runner.main / qa.sh)
     0  all checks PASS (SKIP is not a failure)
     1  at least one check FAIL
     2  internal error (dispatch fault, not a finding FAIL)
────────────────────────────────────────────────────────────────────────────
"""

from __future__ import annotations

from .checks import Check, CheckResult, FINDING_IDS, check, registry
from .report import render_markdown, render_text
from .runner import EXIT_ERROR, EXIT_FAIL, EXIT_OK, exit_code, main, run_all

__all__ = [
    "Check",
    "CheckResult",
    "FINDING_IDS",
    "check",
    "registry",
    "render_markdown",
    "render_text",
    "run_all",
    "exit_code",
    "main",
    "EXIT_OK",
    "EXIT_FAIL",
    "EXIT_ERROR",
]

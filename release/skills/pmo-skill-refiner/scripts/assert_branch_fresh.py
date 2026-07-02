#!/usr/bin/env python3
"""Stage 7 DT — branch-freshness assertion (executable runner).

Asserts that the release branch has NO commits on its base (default ``origin/main``)
that are unreachable from ``HEAD`` — i.e. the branch is not stale relative to the
line it will merge into. A branch that has fallen behind its base can merge stale;
this runner is the executable half of the Stage-7 branch-freshness check (the graded
eval entry lives in the stage-gate eval home; an ``evals.json`` assertion is prose a
harness grades, not a git check that can pass/fail a branch — hence this script).

Mechanism (the exact command the design names):

    git log --oneline <base> ^HEAD          # commits on <base> not reachable from HEAD

Empty output  -> branch is fresh   -> exit 0, ``PASS``.
Non-empty     -> branch is stale   -> exit 1, ``FAIL`` listing the unreachable commits.

Design (mirrors the hermetic style of test_scaffolder_drift_guard.py and the sibling
test_eval_scripts.py suite): the pure decision core ``is_fresh(base_rev, head_rev,
git_runner)`` is split from the subprocess/argv shell so it is unit-testable with an
injected fake git runner — no live remote required.

Usage:
    python3 release/skills/pmo-skill-refiner/scripts/assert_branch_fresh.py
    python3 release/skills/pmo-skill-refiner/scripts/assert_branch_fresh.py --base origin/main
    python3 release/skills/pmo-skill-refiner/scripts/assert_branch_fresh.py --fetch

Exit codes: 0 = fresh (PASS), 1 = stale (FAIL), 2 = git/invocation error.
"""

from __future__ import annotations

import argparse
import subprocess  # noqa: S404 — invoking git is the point; args are not user-injected shell
import sys
from typing import Callable, List, Tuple

# A git runner takes an argv list (without the leading "git") and returns stdout.
GitRunner = Callable[[List[str]], str]


def is_fresh(
    base_rev: str,
    head_rev: str,
    git_runner: GitRunner,
) -> Tuple[bool, List[str]]:
    """Pure decision core: is ``head_rev`` fresh relative to ``base_rev``?

    Runs ``git log --oneline <base> ^<head>`` via the injected ``git_runner`` and
    returns ``(fresh, unreachable)`` where ``unreachable`` is the list of oneline
    commit rows on ``base`` not reachable from ``head``. ``fresh`` is True iff that
    list is empty. No subprocess or argv parsing here — the runner is injectable so
    the core is hermetically testable.
    """
    out = git_runner(["log", "--oneline", base_rev, f"^{head_rev}"])
    unreachable = [line for line in out.splitlines() if line.strip()]
    return (len(unreachable) == 0, unreachable)


def _real_git_runner(argv: List[str]) -> str:
    """Run a real ``git`` command, returning stdout (raises on non-zero exit)."""
    result = subprocess.run(  # noqa: S603 — fixed argv, no shell=True, not user-injected
        ["git", *argv],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Assert the release branch has no base commits unreachable from HEAD."
    )
    parser.add_argument(
        "--base",
        default="origin/main",
        help="Base ref to compare against (default: origin/main).",
    )
    parser.add_argument(
        "--head",
        default="HEAD",
        help="Head ref to check freshness of (default: HEAD).",
    )
    parser.add_argument(
        "--fetch",
        dest="fetch",
        action="store_true",
        help="Run `git fetch` for the base's remote before checking (default: no fetch).",
    )
    parser.add_argument(
        "--no-fetch",
        dest="fetch",
        action="store_false",
        help="Do not fetch before checking (the default; the Stage-7 caller decides).",
    )
    parser.set_defaults(fetch=False)
    args = parser.parse_args(argv)

    try:
        if args.fetch:
            # Fetch the remote implied by the base ref (e.g. "origin" from "origin/main").
            remote = args.base.split("/", 1)[0] if "/" in args.base else "origin"
            _real_git_runner(["fetch", remote])
        fresh, unreachable = is_fresh(args.base, args.head, _real_git_runner)
    except subprocess.CalledProcessError as exc:
        print(f"ERROR: git command failed: {exc.stderr.strip() or exc}", file=sys.stderr)
        return 2
    except OSError as exc:  # git not found, etc.
        print(f"ERROR: could not run git: {exc}", file=sys.stderr)
        return 2

    if fresh:
        print(
            f"PASS: branch is fresh (0 commits on {args.base} unreachable from {args.head})"
        )
        return 0

    print(
        f"FAIL: {len(unreachable)} commit(s) on {args.base} not reachable from {args.head}:"
    )
    for line in unreachable:
        print(f"  {line}")
    return 1


if __name__ == "__main__":
    sys.exit(main())

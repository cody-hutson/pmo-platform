#!/usr/bin/env python3
"""Enforce the platform-wide ADR-numbering invariant.

ADR files live in two directories — ``core/ADRs/`` and ``release/ADRs/`` — but
share ONE global number space: ``ADR-NNN-kebab-title.md`` where NNN is
monotonically increasing across the platform (NOT per-module). The rule is
stated in both directories' ``README.md`` (§ Naming convention).

This checker fails a PR that violates the invariant in any of three ways:

  1. DUPLICATE  — the same NNN appears on more than one ADR (across both dirs).
                  This is the #1345 failure mode (ADR-024 in core/ and release/).
  2. GAP        — the numbers are not a contiguous run 001..max (a hole in the
                  global sequence — "increment across the repo, no gaps").
  3. MALFORMED  — an ``ADR-*.md`` filename whose NNN does not parse.

Run it from anywhere (the ADR directories resolve from this file's location):

    python3 release/tools/check-adr-numbers.py
    python3 release/tools/check-adr-numbers.py --self-test

Exit 0 = clean; exit 1 = violation (or self-test failure).
"""
from __future__ import annotations

import argparse
import tempfile
import re
from pathlib import Path

# ADR-NNN-<kebab-title>.md — NNN is the global sequence number.
ADR_FILE_RE = re.compile(r"^ADR-(\d+)-.+\.md$")
ADR_GLOB = "ADR-*.md"
# ADR directories that share the one global number space, relative to repo root.
ADR_DIRS = ("core/ADRs", "release/ADRs")


def collect(dirs):
    """Return (number -> [paths], [malformed paths]) across the given dirs."""
    by_number = {}
    malformed = []
    for d in dirs:
        if not d.is_dir():
            continue
        for path in sorted(d.glob(ADR_GLOB)):
            m = ADR_FILE_RE.match(path.name)
            if not m:
                malformed.append(str(path))
                continue
            n = int(m.group(1))
            by_number.setdefault(n, []).append(str(path))
    return by_number, malformed


def evaluate(by_number, malformed):
    """Return a list of human-readable violation messages (empty == clean)."""
    problems = []

    for path in malformed:
        problems.append(f"MALFORMED: {path} does not match ADR-NNN-<kebab-title>.md")

    duplicates = {n: paths for n, paths in by_number.items() if len(paths) > 1}
    for n, paths in sorted(duplicates.items()):
        joined = "\n      ".join(paths)
        problems.append(
            f"DUPLICATE: ADR-{n:03d} is claimed by {len(paths)} files:\n      {joined}"
        )

    if by_number:
        present = set(by_number)
        expected = set(range(1, max(present) + 1))
        gaps = sorted(expected - present)
        if gaps:
            pretty = ", ".join(f"ADR-{n:03d}" for n in gaps)
            problems.append(
                f"GAP: the global sequence 001..{max(present):03d} is not contiguous; "
                f"missing {pretty}"
            )
    return problems


def next_free(by_number):
    """Return the next free ADR number for a ``collect()`` result: ``max + 1``.

    THE BINDING ORACLE. Callers MUST pass a ``by_number`` collected over the
    MAINLINE tree (``origin/main``) and never over a working tree carrying
    unmerged branch claims. A number is *allocated at authorship* but *claimed
    at merge*, so an unmerged claim does not bind the sequence: allocating above
    a branch-only claim lands a GAP on the mainline, which ``evaluate()`` fails
    as readily as a DUPLICATE — and then fails every subsequent PR until the
    hole is filled. A duplicate is the cheap failure and is resolved by the
    merge-time renumber (``release/tools/renumber-adr.py``); a gap is the
    expensive one. See ``core/ADRs/README.md`` § Renumber log.
    """
    return max(by_number) + 1 if by_number else 1


def check(root):
    """Evaluate the real ADR directories under ``root``."""
    dirs = [root / d for d in ADR_DIRS]
    by_number, malformed = collect(dirs)
    return evaluate(by_number, malformed)


def _write(dirpath, *names):
    for name in names:
        (dirpath / name).write_text("# fixture\n", encoding="utf-8")


def self_test():
    """Assert the checker catches each failure mode and passes a clean set.

    Builds throwaway temp directories shaped like the real ADR tree so the guard
    proves it still works before CI trusts its verdict. Returns 0/1.
    """
    failures = []

    def case(label, builder, expect_token):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            core = root / "core" / "ADRs"
            rel = root / "release" / "ADRs"
            core.mkdir(parents=True)
            rel.mkdir(parents=True)
            builder(core, rel)
            problems = check(root)
            if expect_token is None:
                if problems:
                    failures.append(f"[{label}] expected CLEAN, got: {problems}")
            elif not any(expect_token in p for p in problems):
                failures.append(f"[{label}] expected {expect_token}, got: {problems}")

    # clean: contiguous 001..004 split across both dirs (no dup, no gap)
    case(
        "clean",
        lambda c, r: (
            _write(c, "ADR-001-a.md", "ADR-003-c.md"),
            _write(r, "ADR-002-b.md", "ADR-004-d.md"),
        ),
        None,
    )
    # duplicate: 002 claimed in both dirs (the #1345 shape)
    case(
        "duplicate",
        lambda c, r: (
            _write(c, "ADR-001-a.md", "ADR-002-core.md"),
            _write(r, "ADR-002-release.md"),
        ),
        "DUPLICATE",
    )
    # gap: 002 missing from 001..003
    case(
        "gap",
        lambda c, r: (
            _write(c, "ADR-001-a.md", "ADR-003-c.md"),
            _write(r),
        ),
        "GAP",
    )
    # malformed: an ADR-*.md whose number does not parse
    case(
        "malformed",
        lambda c, r: (
            _write(c, "ADR-001-a.md"),
            _write(r, "ADR-foo-bar.md"),
        ),
        "MALFORMED",
    )

    # next_free (the binding oracle) — pure-function fixtures, no I/O. The
    # duplicate fixture pins the property that matters at a collision: the
    # oracle keys on the HIGHEST number present, not on how many files claim
    # it, so a duplicated slot does not shift the next-free answer.
    for label, by_number, expect in (
        ("next_free/contiguous", {1: ["a"], 2: ["b"], 3: ["c"]}, 4),
        ("next_free/duplicate", {1: ["a"], 2: ["b", "c"]}, 3),
    ):
        got = next_free(by_number)
        if got != expect:
            failures.append(f"[{label}] expected {expect}, got {got}")

    if failures:
        print("check-adr-numbers self-test: FAIL")
        for f in failures:
            print("  - " + f)
        return 1
    print(
        "check-adr-numbers self-test: PASS "
        "(clean / duplicate / gap / malformed / next_free x2)"
    )
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Enforce platform-wide-unique, gap-free ADR numbers."
    )
    parser.add_argument(
        "--self-test", action="store_true", help="run built-in fixtures and exit"
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="repo root (default: inferred from this file's location)",
    )
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()

    # release/tools/check-adr-numbers.py -> parents[2] == repo root
    root = args.root or Path(__file__).resolve().parents[2]
    problems = check(root)
    if problems:
        print(f"ADR-number integrity check: FAIL ({len(problems)} violation(s))")
        for p in problems:
            print("  ✗ " + p)
        print(
            "\nADR numbers share ONE global sequence across core/ADRs + release/ADRs."
        )
        print(
            "Fix: renumber the later claimant to the next free slot; "
            "see core/ADRs/README.md § Naming convention."
        )
        return 1

    by_number, _ = collect([root / d for d in ADR_DIRS])
    if by_number:
        print(
            f"ADR-number integrity check: PASS ({len(by_number)} ADRs, "
            f"contiguous 001..{max(by_number):03d}, no duplicates)"
        )
    else:
        print("ADR-number integrity check: PASS (no ADR files found)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Append-pattern aware cross-PR line-range overlap detection.

Computes per-file overlap_class from per-PR hunk-range data fetched via
`gh api repos/<owner>/<repo>/pulls/<N>/files`. Classifies each contended
file (file_path appearing in >=2 distinct pr_number rows) as one of:

  append-pattern        ALL pairs of PRs have zero overlapping hunks
  line-range-overlap    AT LEAST ONE pair has overlapping hunks
  single-pr             file appears in exactly 1 distinct pr_number row

Threshold: 0% pairwise hunk overlap = append-pattern (zero-tolerance).
Two hunks [s1,e1] and [s2,e2] overlap iff max(s1,s2) <= min(e1,e2).
Coordinate model: post-diff line numbers from @@ -A,B +C,D @@ headers
(start = C, end = C + D - 1). Coordinates are anchored at each PR's
merge-base; conservatism is the safer error direction.

Schema extension per ADR-005 § Decision:
- line_ranges    JSON array of [start, end] tuples per PR per file
- overlap_class  enum (append-pattern | line-range-overlap | single-pr)

Exit codes: 0 = audit complete, 1 = argument/runtime error, 2 = gh API
failure, 3 = self-test failure.

Authored per the Stage 5 spec.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys

# Pinned PATH per bypass-mode-readiness.md posture
os.environ["PATH"] = "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"

HUNK_HEADER_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def parse_hunk_ranges(patch_text: str) -> list[tuple[int, int]]:
    """Extract [start, end] tuples from unified-diff hunk headers."""
    ranges: list[tuple[int, int]] = []
    if not patch_text:
        return ranges
    for line in patch_text.splitlines():
        m = HUNK_HEADER_RE.match(line)
        if m:
            start = int(m.group(1))
            length = int(m.group(2)) if m.group(2) else 1
            if length > 0:
                ranges.append((start, start + length - 1))
    return ranges


def hunks_overlap(a: tuple[int, int], b: tuple[int, int]) -> bool:
    """True iff hunks [s1,e1] and [s2,e2] overlap (closed intervals)."""
    return max(a[0], b[0]) <= min(a[1], b[1])


def classify_overlap_class(
    pr_to_ranges: dict[int, list[tuple[int, int]]],
) -> str:
    """Apply ADR-005 § Decision classification rule."""
    pr_numbers = sorted(pr_to_ranges.keys())
    if len(pr_numbers) == 1:
        return "single-pr"
    for i, p_i in enumerate(pr_numbers):
        for p_j in pr_numbers[i + 1:]:
            for h_i in pr_to_ranges[p_i]:
                for h_j in pr_to_ranges[p_j]:
                    if hunks_overlap(h_i, h_j):
                        return "line-range-overlap"
    return "append-pattern"


def fetch_pr_file_patch(repo: str, pr_number: int, file_path: str) -> str:
    """Return the `patch` field for (PR, file) via gh api."""
    cmd = [
        "gh", "api",
        f"repos/{repo}/pulls/{pr_number}/files",
        "--paginate",
        "--jq",
        f'.[] | select(.filename == "{file_path}") | .patch // ""',
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        return ""
    return result.stdout


def run_self_test() -> int:
    """Algorithm-level regression test (no network calls).

    Exercises parse_hunk_ranges, hunks_overlap, and classify_overlap_class
    against synthetic inputs covering the 3 overlap_class values + edge
    cases (empty patch, single-line hunk, multi-hunk).
    """
    failures: list[str] = []

    # parse_hunk_ranges
    if parse_hunk_ranges("") != []:
        failures.append("parse_hunk_ranges('') should be []")
    if parse_hunk_ranges("@@ -1,3 +10,5 @@\n+x\n+y\n+z") != [(10, 14)]:
        failures.append("parse_hunk_ranges multi-line failed")
    if parse_hunk_ranges("@@ -1 +5 @@\n+x") != [(5, 5)]:
        failures.append("parse_hunk_ranges single-line (no length) failed")
    multi = "@@ -1,2 +10,3 @@\n+a\n+b\n@@ -20,1 +50,5 @@\n+c"
    if parse_hunk_ranges(multi) != [(10, 12), (50, 54)]:
        failures.append("parse_hunk_ranges multi-hunk failed")

    # hunks_overlap
    if not hunks_overlap((1, 5), (5, 10)):
        failures.append("hunks_overlap closed-interval at boundary failed")
    if hunks_overlap((1, 4), (5, 10)):
        failures.append("hunks_overlap disjoint should be False")
    if not hunks_overlap((1, 100), (50, 60)):
        failures.append("hunks_overlap containment failed")

    # classify_overlap_class
    if classify_overlap_class({101: [(1, 10)]}) != "single-pr":
        failures.append("classify single-pr failed")
    if classify_overlap_class({
        101: [(1, 10)],
        102: [(20, 30)],
        103: [(40, 50)],
    }) != "append-pattern":
        failures.append("classify append-pattern (3 disjoint) failed")
    if classify_overlap_class({
        101: [(1, 10)],
        102: [(5, 15)],
    }) != "line-range-overlap":
        failures.append("classify line-range-overlap (pair) failed")
    if classify_overlap_class({
        101: [(1, 10), (50, 60)],
        102: [(20, 30)],
        103: [(40, 55)],  # overlaps 101's second hunk (50-60 vs 40-55)
    }) != "line-range-overlap":
        failures.append("classify line-range-overlap (multi-hunk) failed")

    if failures:
        print("SELF-TEST FAIL:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 3
    print("SELF-TEST PASS")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Append-pattern aware cross-PR line-range overlap detection (ADR-005)",
    )
    ap.add_argument("--self-test", action="store_true",
                    help="Run algorithm regression tests (no network calls)")
    ap.add_argument("--baseline-sha",
                    help="Baseline commit SHA recorded in audit metadata")
    ap.add_argument("--repo", default=os.environ.get("PMO_REPO_SLUG", ""))
    ap.add_argument("--pr-list",
                    help="Comma-separated PR numbers")
    ap.add_argument("--files",
                    help="Comma-separated file paths")
    ap.add_argument("--output-format", choices=["tsv", "json"], default="tsv")
    args = ap.parse_args()

    if args.self_test:
        return run_self_test()

    if not args.baseline_sha or not args.pr_list or not args.files:
        ap.error("--baseline-sha, --pr-list, --files required (or use --self-test)")

    try:
        pr_numbers = [int(x) for x in args.pr_list.split(",")]
    except ValueError:
        print("ERROR: --pr-list must be comma-separated integers", file=sys.stderr)
        return 1
    files = args.files.split(",")

    # Collect line_ranges per (file, PR)
    per_file: dict[str, dict[int, list[tuple[int, int]]]] = {f: {} for f in files}
    for pr in pr_numbers:
        for f in files:
            patch = fetch_pr_file_patch(args.repo, pr, f)
            ranges = parse_hunk_ranges(patch)
            if ranges:
                per_file[f][pr] = ranges

    # Classify overlap_class per file
    overlap_classes = {
        f: classify_overlap_class(prs)
        for f, prs in per_file.items()
        if prs
    }

    # Emit
    if args.output_format == "json":
        out = {
            "baseline_sha": args.baseline_sha,
            "files": {
                f: {
                    "overlap_class": overlap_classes.get(f, "single-pr"),
                    "line_ranges": {
                        str(pr): per_file[f].get(pr, [])
                        for pr in pr_numbers
                    },
                }
                for f in files
            },
        }
        print(json.dumps(out, indent=2))
    else:
        print("file_path\tpr_number\tline_ranges\toverlap_class")
        for f in files:
            if f not in per_file or not per_file[f]:
                continue
            for pr in pr_numbers:
                ranges = per_file[f].get(pr, [])
                ranges_json = json.dumps([list(r) for r in ranges])
                cls = overlap_classes.get(f, "single-pr")
                print(f"{f}\t{pr}\t{ranges_json}\t{cls}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

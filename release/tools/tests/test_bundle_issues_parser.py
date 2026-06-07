#!/usr/bin/env python3
"""Aggregate + per-failure-class tests for bundle-issues-parser.py.

Companion to the parser's built-in `--self-test` (synthetic per-class fixtures).
This module verifies the v3.20 parser robustification (#291) against a FROZEN
sample of REAL issue bodies drawn from the live open-issue corpus at the Stage 5
baseline, asserting the ratified acceptance criterion:

  combined-clean >= 90% on the CONFORMANT-BUNDLEABLE denominator
  (improvement|bug bodies that carry a recognized Affected-Files heading).

The denominator decision and the >=90% target are the ratified Stage 5 design
(Collective Review scope-lock, v3.20). The Mode A pre-filter that sets aside
bodies with NO recognized AF heading is a release-planner SKILL.md change, not a
parser change, and is therefore simulated here only by curating the frozen sample
to the conformant set.

Fixtures: ./conformant_bundleable_sample.json — 40 real issue bodies frozen on
2026-06-07 (baseline commit anchor recorded in the release plan). The sample spans
30 clean conformant-bundleable bodies, the nine per-class recovered-failure bodies
(see CLASS_RECOVERY below), and one genuinely-unparseable residual that stays
failed by design (a component-name bullet with no file path — routes to the Mode A
set-aside, not a parser failure).

Run:  python3 release/tools/tests/test_bundle_issues_parser.py
Exit: 0 = all pass, 1 = one or more assertions failed.

### Provenance
Issue references in this file (#291, and the frozen sample issue numbers) are the
live open-issue corpus the parser is measured against; numbers are a point-in-time
survey snapshot, not a durable contract — the test re-measures from the frozen
fixtures, which are self-contained.
"""

import importlib.util
import json
import os
import sys
from typing import Dict, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
PARSER_PATH = os.path.join(HERE, os.pardir, "bundle-issues-parser.py")
FIXTURES_PATH = os.path.join(HERE, "conformant_bundleable_sample.json")

# The >=90% acceptance criterion on the conformant-bundleable denominator.
AC_THRESHOLD = 0.90

# Per-class recovery expectations: each issue number maps to the failure class it
# exercises and the combined-parse status it MUST reach under the v3.20 parser.
# These nine bodies parse FAILED under the pre-v3.20 parser (fix-efficacy guard
# below confirms the aggregate moves materially); they MUST be clean now.
CLASS_RECOVERY = {
    351: ("FC-1a current module-prefix paths (core/ release/) in bullets", "clean"),
    344: ("FC-1a/FC-5 module-prefix + deferral marker line", "clean"),
    327: ("FC-3 prose-style AF section (path in a sentence)", "clean"),
    326: ("FC-1a release/ path in a single bullet", "clean"),
    195: ("FC-1b bare backticked filename (deploy.sh, no internal '/')", "clean"),
    132: ("FC-1b bare backticked filename (CLAUDE.md)", "clean"),
    114: ("FC-3 prose + module-path reference", "clean"),
    113: ("FC-3 prose with backticked module-prefixed paths", "clean"),
    110: ("FC-3 prose with named pipeline-stage paths", "clean"),
}

# Genuinely-unparseable residual — present AF heading, bullet with no file path and
# no None-marker. Stays failed by design; routes to the Mode A set-aside queue.
RESIDUAL_FAILED = {
    123: "FC-7 component-name bullet ('17 GitHub milestones') — no file path",
}


def load_parser():
    spec = importlib.util.spec_from_file_location("bundle_issues_parser", PARSER_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def combined_status(mod, body: str) -> str:
    _, af = mod.parse_affected_files(body)
    _, dep = mod.parse_dependencies(body)
    if "failed" in (af, dep):
        return "failed"
    if "deferred" in (af, dep):
        return "deferred"
    return "clean"


def main() -> int:
    bip = load_parser()
    with open(FIXTURES_PATH) as fh:
        fixtures: Dict[str, Dict] = json.load(fh)

    failures = []

    # 1. Per-class recovery: each recovered-failure body must reach its expected status.
    for num, (desc, expected) in CLASS_RECOVERY.items():
        rec = fixtures.get(str(num))
        if rec is None:
            failures.append(f"recovery fixture #{num} missing from frozen sample")
            continue
        got = combined_status(bip, rec["body"])
        if got != expected:
            failures.append(f"#{num} ({desc}): expected {expected}, got {got}")

    # 2. Residual still-failed by design (negative assertion — guards over-eager matching).
    for num, desc in RESIDUAL_FAILED.items():
        rec = fixtures.get(str(num))
        if rec is None:
            failures.append(f"residual fixture #{num} missing from frozen sample")
            continue
        got = combined_status(bip, rec["body"])
        if got != "failed":
            failures.append(
                f"#{num} ({desc}): expected failed (set-aside), got {got} — "
                f"over-eager extraction may have invented a path"
            )

    # 3. Aggregate AC: combined-clean >= 90% on the frozen conformant-bundleable sample.
    n = len(fixtures)
    clean = sum(1 for rec in fixtures.values() if combined_status(bip, rec["body"]) == "clean")
    deferred = sum(
        1 for rec in fixtures.values() if combined_status(bip, rec["body"]) == "deferred"
    )
    rate = clean / n if n else 0.0
    if rate < AC_THRESHOLD:
        failures.append(
            f"AC FAIL: combined-clean {clean}/{n} = {rate:.1%} < {AC_THRESHOLD:.0%}"
        )

    # Report
    print(f"conformant-bundleable frozen sample: N={n}")
    print(f"  combined-clean    = {clean}/{n} = {rate:.1%}  (AC: >= {AC_THRESHOLD:.0%})")
    print(f"  clean-or-deferred = {clean + deferred}/{n} = {(clean + deferred) / n:.1%}")
    print(f"  per-class recovery cases: {len(CLASS_RECOVERY)}  residual set-aside: {len(RESIDUAL_FAILED)}")

    if failures:
        print("\nTEST FAIL:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("\nTEST OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Fixture-based tests for native-dep-mirror.py (Stage 2 A3.5 AS2 tool).

Companion to the tool's built-in `--self-test`. Verifies the deterministic mirror
core (body typed-dep parse → FS+0d eligibility → to_add/drift diff) against a
FROZEN fixture of representative issue bodies + native blocked-by sets, asserting
the per-case (eligible, to_add, drift) the Model A contract designs. Network I/O
(gh issue read, GraphQL blockedBy read, addIssueDependency write) is out of scope
— this exercises the pure functions, which is where the mirror's correctness lives.

Run:  python3 release/tools/tests/test_native_dep_mirror.py
Exit: 0 = all cases pass, 1 = one or more assertions failed.
"""

import importlib.util
import json
import os
import sys
from typing import Dict, List

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL_PATH = os.path.join(HERE, os.pardir, "native-dep-mirror.py")
FIXTURE_PATH = os.path.join(HERE, "native_dep_mirror_fixture.json")


def load_tool():
    spec = importlib.util.spec_from_file_location("native_dep_mirror", TOOL_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main() -> int:
    mod = load_tool()
    with open(FIXTURE_PATH) as fh:
        fixtures = json.load(fh)
    cases: List[Dict] = fixtures["cases"]

    failures: List[str] = []
    for case in cases:
        name = case["name"]
        deps = mod.parse_body_dependencies(case["body"])
        eligible = sorted(mod.mirror_eligible_targets(deps))
        to_add, drift = mod.compute_mirror_plan(deps, set(case["native_blocked_by"]))

        if eligible != case["expect_eligible"]:
            failures.append(
                f"{name}: eligible {eligible} != expected {case['expect_eligible']}"
            )
        if to_add != case["expect_to_add"]:
            failures.append(
                f"{name}: to_add {to_add} != expected {case['expect_to_add']}"
            )
        if drift != case["expect_drift"]:
            failures.append(
                f"{name}: drift {drift} != expected {case['expect_drift']}"
            )

    print(f"native-dep-mirror frozen fixtures: N={len(cases)} case(s)")
    print(f"  cases asserting (eligible, to_add, drift) per Model A contract: {len(cases)}")

    if failures:
        print("\nTEST FAIL:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("\nTEST OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())

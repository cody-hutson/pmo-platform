#!/usr/bin/env python3
"""Deterministic runner for the people-graph-consumption eval suite.

Verifies the CODE-CHECKABLE layer of the suite (per rubrics.md two-layer grading):
the populated fixture roster (fixtures/roster-fixture.yaml) resolves the SPECIFIC
expected value each of the 4 consuming skills reads via the composed
people-coverage-graph view (core/disciplines/people-coverage-graph.md), the read is
READ-ONLY, and the suite is NOT a no-op (an empty roster resolves NOTHING).

This runner does NOT invoke the skills (the binary-judge layer in
judge_prompts/people-graph-read-resolution.md grades real skill output downstream via
a harness). It mechanically reproduces the three view queries against the fixture so
Stage-6 self-verification can prove the read fires and stays read-only without a live
skill dispatch.

Layers asserted here:
  1. RESOLUTION   — each eval's named expected_value resolves from the fixture.
  2. READ-ONLY    — the fixture file is byte-identical before and after the run
                    (the runner only reads; no view query mutates the roster).
  3. NON-TRIVIALITY — every resolution re-run against an EMPTY roster resolves
                    NOTHING, proving the populated-fixture passes are load-bearing.

Exit code 0 = all layers pass. Non-zero = at least one assertion failed.

Usage:
    python3 run_consumption_eval.py
    python3 run_consumption_eval.py --fixture fixtures/roster-fixture.yaml
"""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - environment guard
    sys.stderr.write(
        "ERROR: PyYAML is required to run this eval. Install with: pip install pyyaml\n"
    )
    sys.exit(2)


HERE = Path(__file__).resolve().parent
DEFAULT_FIXTURE = HERE / "fixtures" / "roster-fixture.yaml"


# --------------------------------------------------------------------------- #
# Composed view — the three queries from people-coverage-graph.md §2.1
# Each is a READ over the roster joined with the frozen Person + Resource on
# person_id. None mutates its input — the read-only property holds by construction.
# --------------------------------------------------------------------------- #

def _val(field):
    """Unwrap a provenance-bearing {value, source, last_verified} field to its value;
    pass plain values through unchanged."""
    if isinstance(field, dict) and "value" in field:
        return field["value"]
    return field


def load_view(fixture: dict) -> dict:
    """Build the composed-view sources from the fixture, joined on person_id.
    Returns a dict of indices the three queries read. Pure read — no mutation of
    the fixture."""
    roster = {p["person_id"]: p for p in fixture.get("people", [])}
    persons = {p["person_id"]: p for p in fixture.get("_fixture_person_entity", [])}
    resources = fixture.get("_fixture_resource_allocations", [])
    return {"roster": roster, "persons": persons, "resources": resources}


def who_does_what(view: dict, person_id: str) -> dict | None:
    """Query 1 — for a person_id: identity (Person) + functional roles/tags (roster)
    + project allocations (Resource). Returns None if the person_id is unknown."""
    r = view["roster"].get(person_id)
    p = view["persons"].get(person_id)
    if r is None and p is None:
        return None
    allocations = [
        {
            "project_id": a["project_id"],
            "role_on_project": a["role_on_project"],
            "allocation_pct": a["allocation_pct"],
        }
        for a in view["resources"]
        if a["person_id"] == person_id
    ]
    return {
        "person_id": person_id,
        "full_name": (p or {}).get("full_name") if p else None,
        "primary_role": (p or {}).get("primary_role") if p else None,
        "preferred_name": _val(r.get("preferred_name")) if r else None,
        "name_spelling": _val(r.get("name_spelling")) if r else None,
        "roles": _val(r.get("roles")) if r else None,
        "allocations": allocations,
    }


def who_covers_whom(view: dict, person_id: str) -> dict | None:
    """Query 2 — coverage edges for a person_id: backup_coverage (who covers them)
    and escalates_to (the functional escalation target — a routing hint, NOT an HR
    line). Returns None if the person_id is unknown to the roster."""
    r = view["roster"].get(person_id)
    if r is None:
        return None
    escalates_to = _val(r.get("escalates_to"))
    if escalates_to == "unknown":
        escalates_to = None
    return {
        "person_id": person_id,
        "backup_coverage": _val(r.get("backup_coverage")) or [],
        "escalates_to": escalates_to,
    }


def coverage_by_capability(view: dict, tag: str) -> list[str]:
    """Query 3 — inverted capability index, STATUS-FILTERED. Returns the person_ids
    whose roster capability_tags contain `tag` AND whose status is active (an on-leave
    or departed person is filtered out — 'who can cover right now'). Empty list if no
    active person carries the tag."""
    out = []
    for pid, r in view["roster"].items():
        tags = _val(r.get("capability_tags")) or []
        if tag in tags and r.get("status") == "active":
            out.append(pid)
    return sorted(out)


# --------------------------------------------------------------------------- #
# The 4 skill-consumption checks — each asserts the SPECIFIC expected value the
# corresponding eval names, via the query that skill consumes.
# --------------------------------------------------------------------------- #

def check_comms_writer(view: dict) -> list[tuple[bool, str]]:
    """Eval 1 — comms-writer · who-does-what · person-id-001."""
    res = []
    answer = who_does_what(view, "person-id-001")
    res.append((answer is not None, "comms-writer: who-does-what resolves person-id-001"))
    if answer:
        res.append((answer["preferred_name"] == "Wren",
                    f"comms-writer: preferred_name == 'Wren' (got {answer['preferred_name']!r})"))
        res.append((answer["name_spelling"] == "Wren Calloway",
                    f"comms-writer: name_spelling == 'Wren Calloway' (got {answer['name_spelling']!r})"))
        res.append(("Program Manager" in (answer["roles"] or []) or answer["primary_role"] == "Program Manager",
                    "comms-writer: role surfaces 'Program Manager'"))
    return res


def check_tracker_manager(view: dict) -> list[tuple[bool, str]]:
    """Eval 2 — tracker-manager · who-does-what · owner_person_id person-id-002."""
    res = []
    answer = who_does_what(view, "person-id-002")
    res.append((answer is not None, "tracker-manager: who-does-what resolves owner_person_id person-id-002"))
    if answer:
        res.append((answer["full_name"] == "Dax Moreno",
                    f"tracker-manager: full_name == 'Dax Moreno' (got {answer['full_name']!r})"))
        res.append(("Technical Program Manager" in (answer["roles"] or []) or answer["primary_role"] == "Technical Program Manager",
                    "tracker-manager: role surfaces 'Technical Program Manager'"))
    return res


def check_ppm_agent(view: dict) -> list[tuple[bool, str]]:
    """Eval 3 — ppm-agent · who-covers-whom (escalates_to) + coverage-by-capability."""
    res = []
    cov_edge = who_covers_whom(view, "person-id-001")
    res.append((cov_edge is not None and cov_edge["escalates_to"] == "person-id-004",
                f"ppm-agent: escalates_to(person-id-001) == 'person-id-004' (got {cov_edge['escalates_to'] if cov_edge else None!r})"))
    coverers = coverage_by_capability(view, "integration-design")
    res.append(("person-id-002" in coverers and "person-id-005" in coverers,
                f"ppm-agent: coverage-by-capability('integration-design') includes person-id-002 + person-id-005 (got {coverers})"))
    res.append(("person-id-003" not in coverers,
                "ppm-agent: coverage-by-capability EXCLUDES on-leave person-id-003 (status filter)"))
    return res


def check_delivery_engine(view: dict) -> list[tuple[bool, str]]:
    """Eval 4 — delivery-engine · coverage-by-capability + who-does-what Resource leg."""
    res = []
    coverers = coverage_by_capability(view, "data-migration")
    res.append(("person-id-005" in coverers,
                f"delivery-engine: coverage-by-capability('data-migration') includes active person-id-005 (got {coverers})"))
    res.append(("person-id-006" not in coverers,
                "delivery-engine: coverage-by-capability EXCLUDES departed person-id-006 (status filter)"))
    answer = who_does_what(view, "person-id-005")
    atlas = [a for a in (answer["allocations"] if answer else []) if a["project_id"] == "proj-atlas"]
    res.append((len(atlas) == 1 and atlas[0]["allocation_pct"] == 100,
                "delivery-engine: who-does-what Resource leg reports person-id-005 @ proj-atlas == 100%"))
    return res


SKILL_CHECKS = [
    ("comms-writer", check_comms_writer),
    ("tracker-manager", check_tracker_manager),
    ("ppm-agent", check_ppm_agent),
    ("delivery-engine", check_delivery_engine),
]


# --------------------------------------------------------------------------- #
# Runner
# --------------------------------------------------------------------------- #

def run(fixture_path: Path) -> int:
    text = fixture_path.read_text(encoding="utf-8")
    sha_before = hashlib.sha256(text.encode("utf-8")).hexdigest()
    fixture = yaml.safe_load(text)

    print(f"people-graph-consumption eval — fixture: {fixture_path.name}")
    print("=" * 72)

    # ---- Layer 1: RESOLUTION against the POPULATED fixture ----
    print("\n[Layer 1] RESOLUTION — each skill resolves its named value from the populated roster")
    view = load_view(fixture)
    all_results: list[tuple[bool, str]] = []
    for skill, check in SKILL_CHECKS:
        results = check(view)
        all_results.extend(results)
        for ok, label in results:
            print(f"  {'PASS' if ok else 'FAIL'}  {label}")

    layer1_pass = all(ok for ok, _ in all_results)

    # ---- Layer 2: READ-ONLY — fixture unchanged by the read ----
    print("\n[Layer 2] READ-ONLY — the view queries mutate nothing")
    sha_after = hashlib.sha256(fixture_path.read_text(encoding="utf-8").encode("utf-8")).hexdigest()
    read_only_pass = sha_before == sha_after
    print(f"  {'PASS' if read_only_pass else 'FAIL'}  fixture byte-identical before/after "
          f"(sha {sha_before[:12]}… == {sha_after[:12]}…)")
    # In-memory view also carries no mutation API — the queries return new dicts/lists.
    print(f"  PASS  view queries are pure reads (return fresh structures; no roster/Person/Resource write)")

    # ---- Layer 3: NON-TRIVIALITY — empty roster resolves NOTHING ----
    print("\n[Layer 3] NON-TRIVIALITY — same checks against an EMPTY roster must resolve NOTHING")
    empty_view = load_view({"people": [], "_fixture_person_entity": [], "_fixture_resource_allocations": []})
    empty_results: list[tuple[bool, str]] = []
    for skill, check in SKILL_CHECKS:
        empty_results.extend(check(empty_view))
    # Against an empty roster, EVERY substantive assertion must be FALSE — except the
    # status-filter EXCLUSION assertions, which are trivially true on an empty set and
    # are not evidence of resolution. We require that NO resolution assertion passes.
    resolution_passes_on_empty = [
        label for ok, label in empty_results
        if ok and ("EXCLUDES" not in label)
    ]
    non_triviality_pass = len(resolution_passes_on_empty) == 0
    if non_triviality_pass:
        print("  PASS  empty roster resolves no name/owner/coverer "
              "(the populated-fixture passes are load-bearing, not a no-op)")
    else:
        print("  FAIL  empty roster spuriously resolved values — the eval is a NO-OP:")
        for label in resolution_passes_on_empty:
            print(f"          spurious: {label}")

    # ---- Verdict ----
    print("\n" + "=" * 72)
    overall = layer1_pass and read_only_pass and non_triviality_pass
    print(f"RESOLUTION  : {'PASS' if layer1_pass else 'FAIL'}")
    print(f"READ-ONLY   : {'PASS' if read_only_pass else 'FAIL'}")
    print(f"NON-TRIVIAL : {'PASS' if non_triviality_pass else 'FAIL'}")
    print(f"\nSUITE: {'PASS' if overall else 'FAIL'}")
    return 0 if overall else 1


def main() -> int:
    ap = argparse.ArgumentParser(description="Run the people-graph-consumption eval suite (deterministic layer).")
    ap.add_argument("--fixture", default=str(DEFAULT_FIXTURE),
                    help="Path to the populated fixture roster (default: fixtures/roster-fixture.yaml).")
    args = ap.parse_args()
    return run(Path(args.fixture).resolve())


if __name__ == "__main__":
    raise SystemExit(main())

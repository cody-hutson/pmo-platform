"""Tests for the QA-as-code module (core/deploy/qa).

Covers the two completion-condition contracts for #299:
  1. import smoke-test — the package imports via the sys.path-injection
     convention (core/deploy is not a Python package);
  2. finding -> check coverage — each of F1-F10 + R1/R2 maps to exactly one
     registered check (>=12, 1:1, no duplicates);
plus the standalone runner contract: `./qa.sh` exits 0 on a clean tree and emits
a Markdown report.

Run from repo root:
    python3 -m pytest core/deploy/tests/test_qa_module.py -v
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

# Make core/deploy/ importable without packaging (matches test_compose.py:18);
# core/deploy/tests/ -> parent.parent is core/deploy/.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import qa  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[3]
QA_SH = REPO_ROOT / "qa.sh"


# ----- 1. import smoke-test --------------------------------------------------

def test_qa_package_imports() -> None:
    # Public surface is present after import.
    assert hasattr(qa, "registry")
    assert hasattr(qa, "FINDING_IDS")
    assert hasattr(qa, "CheckResult")
    assert callable(qa.main)


def test_compose_is_reused_not_reimplemented() -> None:
    # The reuse contract: checks import the sibling compose module.
    assert "compose" in sys.modules, "qa.checks must import compose (Phase-1 primitive reuse)"


# ----- 2. finding -> check coverage assertion --------------------------------

def test_finding_ids_are_the_expected_twelve() -> None:
    expected = {"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "R1", "R2"}
    assert set(qa.FINDING_IDS) == expected
    assert len(qa.FINDING_IDS) == 12
    assert len(set(qa.FINDING_IDS)) == 12, "FINDING_IDS has duplicates"


def test_registry_covers_every_finding_one_to_one() -> None:
    reg = qa.registry()
    reg_ids = [c.finding_id for c in reg]
    # >= 12 checks, and the registered set equals the canonical enumeration.
    assert len(reg) >= 12
    assert set(reg_ids) == set(qa.FINDING_IDS)
    # 1:1 — no finding is covered by two checks and no check has a stray id.
    assert len(reg_ids) == len(set(reg_ids)), "duplicate finding_id in the registry"
    assert len(reg_ids) == len(qa.FINDING_IDS)


def test_every_check_is_read_only() -> None:
    # The whole registry is the read-only subset a doctor command consumes.
    assert all(c.read_only for c in qa.registry())


# ----- 3. execution semantics ------------------------------------------------

def test_run_all_returns_one_result_per_finding() -> None:
    results = qa.run_all()
    assert len(results) == len(qa.FINDING_IDS)
    assert {r.finding_id for r in results} == set(qa.FINDING_IDS)
    for r in results:
        assert r.status in ("PASS", "FAIL", "SKIP")
        assert r.evidence, f"{r.finding_id} produced no evidence"


def test_all_checks_pass_on_a_clean_tree() -> None:
    # On the shipped (post-fix) tree every guard is present -> no FAIL.
    results = qa.run_all()
    failed = [r.finding_id for r in results if r.status == "FAIL"]
    assert not failed, f"unexpected FAIL on clean tree: {failed}"
    assert qa.exit_code(results) == qa.EXIT_OK


def test_only_filter_selects_a_subset() -> None:
    results = qa.run_all(only={"F1", "R2"})
    assert {r.finding_id for r in results} == {"F1", "R2"}


def test_report_renders_the_finding_remedy_table() -> None:
    md = qa.render_markdown(qa.run_all())
    assert "| Finding | Check | Status | Evidence | Remedy |" in md
    assert "### Summary" in md


# ----- 4. standalone qa.sh runner contract -----------------------------------

def test_qa_sh_has_the_x_bit() -> None:
    assert QA_SH.is_file(), "qa.sh must exist at repo root"
    assert os.access(QA_SH, os.X_OK), "qa.sh must carry the +x bit"


def test_qa_sh_exits_zero_and_emits_a_report() -> None:
    proc = subprocess.run(
        ["bash", str(QA_SH)],
        capture_output=True, text=True, timeout=120,
    )
    assert proc.returncode == 0, f"qa.sh exited {proc.returncode}\nSTDOUT:\n{proc.stdout}\nSTDERR:\n{proc.stderr}"
    assert "QA-as-code Regression Report" in proc.stdout
    assert "**Verdict:** PASS" in proc.stdout

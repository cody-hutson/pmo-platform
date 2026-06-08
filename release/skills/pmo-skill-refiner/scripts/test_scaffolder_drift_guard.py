#!/usr/bin/env python3
"""
Stage 7 DT — scaffolder-drift guard (#193) fixtures + assertions.

Demonstrates the fail-loud guard `assert_scaffolder_skeleton` (in quick_validate.py):
  - FIRES (HALT) on simulated scaffolder-output drift, AND
  - PASSES on a conforming control.

A guard that always fails is as broken as one that never fires, so both
directions are exercised. Fixtures are static SKILL.md trees built in a temp
directory — hermetic, no network, no real scaffolder invocation (the guard
operates on on-disk scaffold output).

Fixture matrix (per the #550 Stage 7 DT design):
  F0 clean control            -> PASS  (guards against false-positives)
  F1 frontmatter drift        -> HALT  A1 skill-md-frontmatter
  F2 references singular drift -> HALT  A2 skill-references-directory
  F3 body-anatomy drift       -> HALT  A3 skill-md-body-anatomy
  F4 multi-invariant drift     -> HALT  A1 + A3 (proves all-fail, not first-fail)

Run:  python3 test_scaffolder_drift_guard.py
Exit: 0 = all DT assertions held; 1 = a DT assertion failed.
"""

import sys
import tempfile
from pathlib import Path

# Import the guard from the sibling validator (run from the scripts/ dir, or with
# the scripts/ dir on sys.path). scripts/ is a package (__init__.py present).
sys.path.insert(0, str(Path(__file__).resolve().parent))
from quick_validate import (  # noqa: E402
    assert_scaffolder_skeleton,
    validate_skill,
    format_drift_diagnostic,
    DRIFT_SENTINEL,
)


# --- Fixture builders -------------------------------------------------------

def _write_skill(root, frontmatter_lines, body):
    """Write a SKILL.md with the given frontmatter lines + body into root/."""
    root.mkdir(parents=True, exist_ok=True)
    fm = "\n".join(frontmatter_lines)
    (root / 'SKILL.md').write_text(f"---\n{fm}\n---\n\n{body}\n")
    return root


def build_F0(base):
    """F0 — clean control: valid frontmatter + H1 body, no singular reference/."""
    return _write_skill(
        base / 'F0',
        ['name: clean-control-skill', 'description: A minimal valid scaffold.'],
        "# Clean Control Skill\n\nInstructions go here.",
    )


def build_F1(base):
    """F1 — frontmatter drift: description removed."""
    return _write_skill(
        base / 'F1',
        ['name: missing-description-skill'],
        "# Missing Description Skill\n\nInstructions go here.",
    )


def build_F2(base):
    """F2 — references singular drift: sibling singular reference/ directory."""
    root = _write_skill(
        base / 'F2',
        ['name: singular-reference-skill', 'description: Has a singular reference dir.'],
        "# Singular Reference Skill\n\nInstructions go here.",
    )
    singular = root / 'reference'
    singular.mkdir(parents=True, exist_ok=True)
    (singular / 'doc.md').write_text("# A reference doc under the WRONG (singular) dir\n")
    return root


def build_F3(base):
    """F3 — body-anatomy drift: no top-level '#' H1 (body starts at '##')."""
    return _write_skill(
        base / 'F3',
        ['name: no-h1-skill', 'description: Body has no top-level H1.'],
        "## A subsection, but no H1\n\nProse only, no top-level heading.",
    )


def build_F4(base):
    """F4 — multi-invariant drift: missing description AND no H1."""
    return _write_skill(
        base / 'F4',
        ['name: multi-drift-skill'],
        "## Subsection only\n\nNo description in frontmatter and no H1 in body.",
    )


# --- DT assertions ----------------------------------------------------------

def _check(label, condition, detail=""):
    status = "PASS" if condition else "FAIL"
    print(f"  [{status}] {label}" + (f" — {detail}" if detail else ""))
    return condition


def run():
    all_ok = True
    with tempfile.TemporaryDirectory(prefix='scaffolder-drift-dt-') as tmp:
        base = Path(tmp)

        # ---- F0: clean control PASSES, no sentinel (no false-positive) -------
        print("F0 — clean control (expect PASS, no drift sentinel):")
        f0 = build_F0(base)
        ok, failures = assert_scaffolder_skeleton(f0)
        all_ok &= _check("guard returns ok=True", ok, f"failures={[f['invariant'] for f in failures]}")
        all_ok &= _check("no failing invariants", failures == [])
        # validate_skill composes the guard; F0 also needs a license to pass the
        # FULL validator, but the GUARD itself (skeleton) must not flag F0.
        v_ok, v_msg = validate_skill(f0)
        all_ok &= _check(
            "full validator does NOT emit drift sentinel on F0",
            DRIFT_SENTINEL not in v_msg,
            f"msg={v_msg!r}",
        )

        # ---- F1: frontmatter drift HALTs, names A1 ---------------------------
        print("F1 — frontmatter drift (expect HALT, A1):")
        f1 = build_F1(base)
        ok, failures = assert_scaffolder_skeleton(f1)
        all_ok &= _check("guard returns ok=False", ok is False)
        inv = {f['invariant'] for f in failures}
        all_ok &= _check("A1 reported", 'A1' in inv, f"invariants={sorted(inv)}")
        diag = format_drift_diagnostic(failures)
        all_ok &= _check("diagnostic carries sentinel", DRIFT_SENTINEL in diag)
        all_ok &= _check(
            "diagnostic cites skill-md-frontmatter entry",
            'skill-md-frontmatter' in diag,
        )

        # ---- F2: references singular drift HALTs, names A2 -------------------
        print("F2 — references singular drift (expect HALT, A2):")
        f2 = build_F2(base)
        ok, failures = assert_scaffolder_skeleton(f2)
        all_ok &= _check("guard returns ok=False", ok is False)
        inv = {f['invariant'] for f in failures}
        all_ok &= _check("A2 reported", 'A2' in inv, f"invariants={sorted(inv)}")
        diag = format_drift_diagnostic(failures)
        all_ok &= _check(
            "diagnostic cites skill-references-directory entry",
            'skill-references-directory' in diag,
        )

        # ---- F3: body-anatomy drift HALTs, names A3 -------------------------
        print("F3 — body-anatomy drift (expect HALT, A3):")
        f3 = build_F3(base)
        ok, failures = assert_scaffolder_skeleton(f3)
        all_ok &= _check("guard returns ok=False", ok is False)
        inv = {f['invariant'] for f in failures}
        all_ok &= _check("A3 reported", 'A3' in inv, f"invariants={sorted(inv)}")
        diag = format_drift_diagnostic(failures)
        all_ok &= _check(
            "diagnostic cites skill-md-body-anatomy entry",
            'skill-md-body-anatomy' in diag,
        )

        # ---- F4: multi-invariant drift reports BOTH (all-fail, not first-fail)
        print("F4 — multi-invariant drift (expect HALT, A1 + A3 together):")
        f4 = build_F4(base)
        ok, failures = assert_scaffolder_skeleton(f4)
        all_ok &= _check("guard returns ok=False", ok is False)
        inv = {f['invariant'] for f in failures}
        all_ok &= _check(
            "BOTH A1 and A3 reported in one HALT (not first-fail)",
            {'A1', 'A3'}.issubset(inv),
            f"invariants={sorted(inv)}",
        )

        # ---- Negative control on injection: a HALT gates step 4 -------------
        # The guard composes into validate_skill, which returns False with the
        # drift diagnostic. The Create-New workflow gates injection (step 4) on
        # that validation passing — so a HALT means injection is NOT reached and
        # no PMO stubs are appended to the drifted fixture. We assert the gate
        # signal (False + sentinel) rather than re-running the full workflow.
        print("Injection negative-control (a HALT gates Workflow step 4):")
        v_ok, v_msg = validate_skill(f1)
        all_ok &= _check("validate_skill returns False on drift", v_ok is False)
        all_ok &= _check("validate_skill surfaces the drift sentinel", DRIFT_SENTINEL in v_msg)
        all_ok &= _check(
            "drifted fixture was NOT mutated with PMO injection stubs",
            '## Output Contract' not in (f1 / 'SKILL.md').read_text()
            and '## Dependency Graph Node' not in (f1 / 'SKILL.md').read_text(),
        )

    print()
    if all_ok:
        print("ALL DT ASSERTIONS HELD — guard fires on drift, passes the clean control.")
        return 0
    print("DT FAILURE — at least one assertion did not hold (see [FAIL] rows above).")
    return 1


if __name__ == '__main__':
    sys.exit(run())

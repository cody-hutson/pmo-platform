#!/usr/bin/env python3
"""Hermetic unit tests for the semantic routing-conflict harness (run_routing_audit).

Offline, stub-backend, pure-stdlib — no network, no model, no pip install. Every
fixture is a static SKILL.md written to a temp directory; the semantic layer is
exercised with an injected `embed_fn` returning canned vectors (the same
runner-injection idiom test_eval_scripts.py uses for is_fresh). This suite is
picked up by eval-viewer-tests.yml's `scripts/test_*.py` glob and MUST pass under
its no-pip / no-network run.

Coverage (the #2699 Stage-5 acceptance criteria):
  AC-1  audit() embeds activation surfaces + emits ranked flagged pairs; and
        run_eval_audit.py is reused-by-import, not forked (object identity).
  AC-2  a known semantically-close / lexically-distinct pair IS flagged, while a
        lexically-overlapping pair is EXCLUDED at the Jaccard pre-filter (never
        scored) — proving the "sub-Jaccard-floor" targeting.
  AC-3  cost control: semantic-call count << n^2 — embeds == n (linear, not n^2),
        and the pre-filter drops the lexically-overlapping pair so candidates <
        total_pairs. Run against the REAL stub backend (no heavy dep).

Import model mirrors test_eval_scripts.py: the PARENT of scripts/ is placed on
sys.path so `scripts.<module>` resolves package-qualified.

Run:  python3 release/skills/pmo-skill-refiner/scripts/test_run_routing_audit.py
Exit: 0 = all assertions held; 1 = an assertion failed.
"""

from __future__ import annotations

import math
import sys
import tempfile
from pathlib import Path

_SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(_SCRIPTS_DIR.parent))

from scripts import run_eval_audit as rea  # noqa: E402
from scripts import run_routing_audit as rra  # noqa: E402
from scripts.run_routing_audit import (  # noqa: E402
    audit,
    cosine,
    extract_activation_surface,
    render_markdown,
)


# --- Assertion helper (mirrors test_eval_scripts.py) ------------------------

_FAILURES: list[str] = []


def check(label: str, condition: bool, detail: str = "") -> None:
    status = "PASS" if condition else "FAIL"
    line = f"  [{status}] {label}"
    if detail and not condition:
        line += f"  --  {detail}"
    print(line)
    if not condition:
        _FAILURES.append(label)


def _write_skill(root: Path, name: str, description: str) -> None:
    """Write a minimal valid single-line-description SKILL.md into root/<name>/."""
    (root / name).mkdir(parents=True, exist_ok=True)
    (root / name / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: {description}\n---\n\n# {name}\n\nBody.\n"
    )


def _canned_embed(surface_to_vec: dict[str, list[float]]):
    """Build an embed_fn that returns the canned vector for each surface string."""
    def _embed(surfaces: list[str]) -> list[list[float]]:
        return [surface_to_vec[s] for s in surfaces]
    return _embed


# --- Reuse-by-import guard (AC-1: run_eval_audit.py NOT modified/forked) -----

def test_reuse_is_by_import() -> None:
    print("reuse-by-import (run_eval_audit primitives are shared objects, not forked):")
    check("jaccard is imported from run_eval_audit (same object)", rra.jaccard is rea.jaccard)
    check("tokenize is imported from run_eval_audit (same object)", rra.tokenize is rea.tokenize)
    check(
        "extract_trigger_phrases is imported from run_eval_audit (same object)",
        rra.extract_trigger_phrases is rea.extract_trigger_phrases,
    )


def test_no_heavy_dep_at_import() -> None:
    print("zero-dep offline contract (no heavy embedding lib imported at load):")
    # The api/local backends lazy-import their libs INSIDE the backend fn, so a
    # bare `import run_routing_audit` must not have pulled any of them in.
    for heavy in ("torch", "sentence_transformers", "numpy", "anthropic"):
        check(f"{heavy!r} not imported by loading run_routing_audit",
              heavy not in sys.modules, f"{heavy} unexpectedly in sys.modules")


# --- cosine + surface extraction (unit) -------------------------------------

def test_cosine() -> None:
    print("cosine (pure-Python, no numpy):")
    check("identical unit vectors -> 1.0", abs(cosine([1.0, 0.0], [1.0, 0.0]) - 1.0) < 1e-9)
    check("orthogonal -> 0.0", abs(cosine([1.0, 0.0], [0.0, 1.0])) < 1e-9)
    check("zero vector -> 0.0 (no ZeroDivision)", cosine([0.0, 0.0], [1.0, 1.0]) == 0.0)
    half = cosine([1.0, 0.0], [0.5, math.sqrt(0.75)])  # 60 degrees
    check("60-degree vectors -> 0.5", abs(half - 0.5) < 1e-9, f"got {half}")


def test_extract_activation_surface() -> None:
    print("extract_activation_surface (Use-when + Triggers + Modes):")
    desc = 'Does things. Use when X happens. Triggers: "alpha one", "beta two". Modes: Fast · Slow.'
    surf = extract_activation_surface(desc)
    check("surface contains trigger tokens", "alpha" in surf and "beta" in surf, f"got {surf!r}")
    check("surface contains the Use-when clause", "happens" in surf.lower(), f"got {surf!r}")
    check("surface contains mode names", "Fast" in surf and "Slow" in surf, f"got {surf!r}")
    empty_fallback = extract_activation_surface("A plain description with no structured markers.")
    check("empty structured match -> falls back to whole description (never empty)",
          len(empty_fallback) > 0, f"got {empty_fallback!r}")


# --- AC-1: embeds + emits ranked flagged pairs ------------------------------

def test_ac1_embeds_and_ranks_flagged_pairs() -> None:
    print("AC-1 (embeds activation surfaces + emits RANKED flagged pairs):")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        # Four lexically-distinct skills (disjoint trigger tokens -> all pairs are
        # sub-floor candidates). Canned vectors form TWO flagged pairs at DIFFERENT
        # cosines (P-Q = 1.0, R-S = 0.8) with the cross pairs orthogonal.
        descs = {
            "p": 'P. Triggers: "aaa bbb", "ccc ddd".',
            "q": 'Q. Triggers: "eee fff", "ggg hhh".',
            "r": 'R. Triggers: "iii jjj", "kkk lll".',
            "s": 'S. Triggers: "mmm nnn", "ooo ppp".',
        }
        for name, d in descs.items():
            _write_skill(base, name, d)
        canned = {
            extract_activation_surface(descs["p"]): [1.0, 0.0, 0.0, 0.0],
            extract_activation_surface(descs["q"]): [1.0, 0.0, 0.0, 0.0],   # P-Q cos = 1.0
            extract_activation_surface(descs["r"]): [0.0, 1.0, 0.0, 0.0],
            extract_activation_surface(descs["s"]): [0.0, 0.8, 0.6, 0.0],   # R-S cos = 0.8
        }
        result = audit(
            base, ["p", "q", "r", "s"],
            jaccard_floor=0.30, semantic_threshold=0.60,
            embed_fn=_canned_embed(canned),
        )
        check("audited 4 skills", result["skills_audited"] == 4, f"got {result['skills_audited']}")
        check("embeds == 4 (each involved surface embedded once)", result["embeds"] == 4,
              f"got {result['embeds']}")
        check("exactly 2 pairs flagged", result["flagged"] == 2, f"got {result['flagged']}")

        pairs = result["flagged_pairs"]
        check("flagged pairs sorted by cosine DESC",
              [p["cosine"] for p in pairs] == sorted((p["cosine"] for p in pairs), reverse=True),
              f"got {[p['cosine'] for p in pairs]}")
        check("top flagged pair is P-Q at cosine 1.0",
              {pairs[0]["skill_a"], pairs[0]["skill_b"]} == {"p", "q"}
              and abs(pairs[0]["cosine"] - 1.0) < 1e-6,
              f"got {pairs[0]}")
        check("second flagged pair is R-S at cosine 0.8",
              {pairs[1]["skill_a"], pairs[1]["skill_b"]} == {"r", "s"}
              and abs(pairs[1]["cosine"] - 0.8) < 1e-6,
              f"got {pairs[1]}")

        md = render_markdown(result)
        check("markdown carries the title header",
              "# Cross-Skill Semantic Routing-Conflict Matrix (Automated)" in md)
        check("markdown lists both flagged pairs", md.count("| p | q |") + md.count("| q | p |") >= 1
              and (md.count("| r | s |") + md.count("| s | r |") >= 1))
        check("markdown ends with a trailing newline", md.endswith("\n"))


# --- AC-2: sub-Jaccard-floor targeting --------------------------------------

def test_ac2_flags_semantic_only_excludes_lexical() -> None:
    print("AC-2 (semantic-close/lexically-distinct FLAGGED; lexically-overlapping EXCLUDED):")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        # A,B: disjoint trigger tokens -> Jaccard 0 < floor -> candidate; canned
        #      vectors identical -> cosine 1.0 >= threshold -> MUST flag.
        # C,D: share most tokens -> Jaccard >= floor -> EXCLUDED at Tier 0; even
        #      with identical canned vectors they are never scored -> MUST NOT flag.
        descA = 'A. Triggers: "alpha one", "alpha two".'
        descB = 'B. Triggers: "beta three", "beta four".'
        descC = 'C. Triggers: "shared token here", "common word list".'
        descD = 'D. Triggers: "shared token here", "common word extra".'
        for name, d in (("a", descA), ("b", descB), ("c", descC), ("d", descD)):
            _write_skill(base, name, d)

        vec_ab = [1.0, 0.0]
        vec_cd = [0.0, 1.0]  # orthogonal to A/B so the cross pairs never flag
        canned = {
            extract_activation_surface(descA): vec_ab,
            extract_activation_surface(descB): vec_ab,   # A-B cosine 1.0
            extract_activation_surface(descC): vec_cd,
            extract_activation_surface(descD): vec_cd,   # C-D cosine 1.0 (but excluded)
        }
        result = audit(
            base, ["a", "b", "c", "d"],
            jaccard_floor=0.30, semantic_threshold=0.60,
            embed_fn=_canned_embed(canned),
        )
        flagged_sets = [{p["skill_a"], p["skill_b"]} for p in result["flagged_pairs"]]

        check("the lexically-DISTINCT semantic pair {a,b} IS flagged",
              {"a", "b"} in flagged_sets, f"got {flagged_sets}")
        check("the lexically-OVERLAPPING pair {c,d} is NOT flagged",
              {"c", "d"} not in flagged_sets, f"got {flagged_sets}")
        # 6 total pairs; C-D pre-filtered out -> 5 candidates scored.
        check("total pairs == 6", result["total_pairs"] == 6, f"got {result['total_pairs']}")
        check("candidates == 5 (C-D excluded by the Jaccard pre-filter)",
              result["candidates"] == 5, f"got {result['candidates']}")
        # The one flagged pair satisfies BOTH predicates by construction.
        ab = next(p for p in result["flagged_pairs"] if {p["skill_a"], p["skill_b"]} == {"a", "b"})
        check("flagged pair is above the semantic threshold", ab["cosine"] >= 0.60, f"got {ab['cosine']}")
        check("flagged pair is below the Jaccard floor", ab["jaccard"] < 0.30, f"got {ab['jaccard']}")


# --- AC-3: sub-n^2 cost control (REAL stub backend, no heavy dep) ------------

def test_ac3_cost_control_stub_backend() -> None:
    print("AC-3 (semantic-call count << n^2; real stub backend, no heavy dep):")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        # 6 skills. s0/s1 share tokens (Jaccard >= floor) -> one pre-filtered pair.
        # The rest are disjoint -> candidates. Exercises the ACTUAL stub backend.
        skills = {
            "s0": 'S0. Triggers: "aaa bbb ccc".',
            "s1": 'S1. Triggers: "aaa bbb ddd".',   # shares aaa,bbb with s0 -> overlap
            "s2": 'S2. Triggers: "eee fff ggg".',
            "s3": 'S3. Triggers: "hhh iii jjj".',
            "s4": 'S4. Triggers: "kkk lll mmm".',
            "s5": 'S5. Triggers: "nnn ooo ppp".',
        }
        for name, d in skills.items():
            _write_skill(base, name, d)

        names = list(skills.keys())
        # embed_fn=None -> resolves the REAL "stub" backend (stdlib-only, offline).
        result = audit(base, names, jaccard_floor=0.30, semantic_threshold=0.60, backend="stub")

        n = len(names)
        check("audited all 6 skills", result["skills_audited"] == n, f"got {result['skills_audited']}")
        check("total pairs == 15 (== n(n-1)/2)", result["total_pairs"] == n * (n - 1) // 2,
              f"got {result['total_pairs']}")
        check("embeds == n (LINEAR — not n^2)", result["embeds"] == n, f"got {result['embeds']}")
        check("embeds << total_pairs (linear embed spend beats pairwise)",
              result["embeds"] < result["total_pairs"], f"embeds={result['embeds']} pairs={result['total_pairs']}")
        check("pre-filter DROPPED the lexically-overlapping pair (candidates < total_pairs)",
              result["candidates"] < result["total_pairs"],
              f"candidates={result['candidates']} total={result['total_pairs']}")
        check("candidates == 14 (only s0-s1 excluded)", result["candidates"] == 14,
              f"got {result['candidates']}")
        check("cosines scored == candidates (semantic op only on the sub-floor set)",
              result["cosines"] == result["candidates"], f"got {result['cosines']}")


# --- Tier-2 judge hook (optional, injectable) -------------------------------

def test_tier2_judge_hook() -> None:
    print("Tier-2 judge hook (optional, injectable, off by default):")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        descA = 'A. Triggers: "alpha one".'
        descB = 'B. Triggers: "beta two".'
        _write_skill(base, "a", descA)
        _write_skill(base, "b", descB)
        canned = {
            extract_activation_surface(descA): [1.0, 0.0],
            extract_activation_surface(descB): [1.0, 0.0],
        }
        # Judge OFF by default -> no judge calls even with a flagged pair.
        off = audit(base, ["a", "b"], embed_fn=_canned_embed(canned))
        check("judge off by default -> judge_calls == 0", off["judge_calls"] == 0,
              f"got {off['judge_calls']}")

        # Judge ON with an injected judge_fn -> runs on the flagged set only.
        def _judge(pairs: list[dict]) -> list[dict]:
            for p in pairs:
                p["judge_verdict"] = "both-could-fire"
            return pairs

        on = audit(base, ["a", "b"], embed_fn=_canned_embed(canned), run_judge=True, judge_fn=_judge)
        check("judge on -> judge_calls == flagged count", on["judge_calls"] == on["flagged"],
              f"got judge_calls={on['judge_calls']} flagged={on['flagged']}")
        check("judge verdict recorded on the flagged pair",
              on["flagged_pairs"][0].get("judge_verdict") == "both-could-fire",
              f"got {on['flagged_pairs'][0]}")


# --- runner -----------------------------------------------------------------

def main() -> int:
    print("=== run_routing_audit unit tests (hermetic, stub backend) ===\n")
    test_reuse_is_by_import()
    test_no_heavy_dep_at_import()
    test_cosine()
    test_extract_activation_surface()
    test_ac1_embeds_and_ranks_flagged_pairs()
    test_ac2_flags_semantic_only_excludes_lexical()
    test_ac3_cost_control_stub_backend()
    test_tier2_judge_hook()

    print()
    if _FAILURES:
        print(f"FAILED: {len(_FAILURES)} assertion(s): {', '.join(_FAILURES)}")
        return 1
    print("OK: all run_routing_audit unit tests passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

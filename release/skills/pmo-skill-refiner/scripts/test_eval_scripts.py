#!/usr/bin/env python3
"""Hermetic unit tests for the pmo-skill-refiner eval scripts.

Covers the pure, deterministic functions of the preserved eval harness — the
ones that carried no test coverage before this suite (only the scaffolder-drift
guard was tested). No network, no model call, no real skill invocation: every
fixture is an in-memory dict or a static SKILL.md written to a temp directory,
mirroring the hermetic style of test_scaffolder_drift_guard.py.

Coverage:
  jaccard                 -> 1.0 identical / 0.0 disjoint / 0.0 both-empty
  extract_trigger_phrases -> quoted phrases from a 'Triggers:' description
  tokenize                -> lowercase, stopword-drop, 1-char-drop
  trigger_token_set       -> union of content tokens across phrases
  render_markdown         -> renders a real audit() result dict (via a temp
                             SKILL.md tree, exercising the parse -> audit path)
  split_eval_set          -> holdout ratio + seed reproducibility

Import model: the eval scripts import their siblings package-qualified
(`from scripts.utils import ...`), so the PARENT of scripts/ is placed on
sys.path and the modules are imported as `scripts.<module>`. Importing
run_loop transitively imports run_eval + improve_description; those use PEP-604
(`X | None`) annotations, which only import cleanly on Python 3.9 because each
now carries `from __future__ import annotations`. If that fix regresses, the
import below fails loudly here (which is the intended regression signal).

Run:  python3 release/skills/pmo-skill-refiner/scripts/test_eval_scripts.py
Exit: 0 = all assertions held; 1 = an assertion failed.
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

# Put the PARENT of scripts/ on sys.path so `scripts` is importable as a package
# (scripts/__init__.py is present). This resolves the package-qualified imports
# inside the harness modules (e.g. `from scripts.utils import parse_skill_md`).
_SCRIPTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(_SCRIPTS_DIR.parent))

from scripts.run_eval_audit import (  # noqa: E402
    jaccard,
    extract_trigger_phrases,
    tokenize,
    trigger_token_set,
    audit,
    render_markdown,
)
from scripts.run_loop import split_eval_set  # noqa: E402
from scripts.assert_branch_fresh import is_fresh  # noqa: E402


# --- Assertion helper -------------------------------------------------------

_FAILURES: list[str] = []


def check(label: str, condition: bool, detail: str = "") -> None:
    """Record a pass/fail line; accumulate failures for a non-zero exit."""
    status = "PASS" if condition else "FAIL"
    line = f"  [{status}] {label}"
    if detail and not condition:
        line += f"  --  {detail}"
    print(line)
    if not condition:
        _FAILURES.append(label)


# --- jaccard ----------------------------------------------------------------

def test_jaccard() -> None:
    print("jaccard:")
    ident = jaccard({"a", "b", "c"}, {"a", "b", "c"})
    check("identical sets -> 1.0", ident == 1.0, f"got {ident}")

    disjoint = jaccard({"a", "b"}, {"c", "d"})
    check("disjoint sets -> 0.0", disjoint == 0.0, f"got {disjoint}")

    both_empty = jaccard(set(), set())
    check("both-empty -> 0.0 (no ZeroDivision)", both_empty == 0.0, f"got {both_empty}")

    one_empty = jaccard({"a"}, set())
    check("one-empty -> 0.0", one_empty == 0.0, f"got {one_empty}")

    partial = jaccard({"a", "b"}, {"b", "c"})  # intersection 1 / union 3
    check("partial overlap -> 1/3", abs(partial - (1 / 3)) < 1e-9, f"got {partial}")


# --- extract_trigger_phrases ------------------------------------------------

def test_extract_trigger_phrases() -> None:
    print("extract_trigger_phrases:")
    desc = (
        'Generates status updates from trackers. '
        'Triggers: "generate the AM update", "daily status", "morning update".'
    )
    phrases = extract_trigger_phrases(desc)
    check(
        "extracts quoted phrases in order",
        phrases == ["generate the AM update", "daily status", "morning update"],
        f"got {phrases}",
    )

    no_trig = "A description with no triggers section at all."
    check("no 'Triggers:' -> []", extract_trigger_phrases(no_trig) == [], f"got {extract_trigger_phrases(no_trig)}")

    trig_no_quotes = "Triggers: none listed here without quotes."
    check(
        "'Triggers:' present but no quoted phrases -> []",
        extract_trigger_phrases(trig_no_quotes) == [],
        f"got {extract_trigger_phrases(trig_no_quotes)}",
    )

    multiline = 'Does things.\nTriggers: "first phrase",\n"second phrase".'
    check(
        "multiline description handled (DOTALL)",
        extract_trigger_phrases(multiline) == ["first phrase", "second phrase"],
        f"got {extract_trigger_phrases(multiline)}",
    )

    # --- Fallback branch (SC-2): 'Use whenever ...' / 'phrases like ...' form ---
    # These descriptions carry no 'Triggers:' keyword; without the fallback they
    # would contribute an EMPTY trigger set and be silently un-audited.

    # Sub-form 2 — unquoted comma / " or "-separated verb phrases (eval-writer shape).
    use_whenever = (
        "Authors eval suites. "
        "Use whenever the user asks to write evals, audit evals, or build a rubric."
    )
    check(
        "'Use whenever' unquoted clause -> comma/or-split phrases (non-empty)",
        extract_trigger_phrases(use_whenever)
        == ["the user asks to write evals", "audit evals", "build a rubric"],
        f"got {extract_trigger_phrases(use_whenever)}",
    )

    # Sub-form 1 — quoted phrases inside a 'phrases like' clause (prompt-builder shape).
    phrases_like = (
        'Improves prompts. Use whenever the user asks, '
        'phrases like "improve this prompt", "rewrite this".'
    )
    check(
        "'phrases like' quoted clause -> quoted phrases (non-empty)",
        extract_trigger_phrases(phrases_like) == ["improve this prompt", "rewrite this"],
        f"got {extract_trigger_phrases(phrases_like)}",
    )

    # Regression guard: the fallback is SUBORDINATE — a description that DOES match
    # 'Triggers:' must NOT be re-parsed by the fallback even if it also contains
    # 'Use whenever' prose. Primary path wins, output is the quoted 'Triggers:' set.
    both = (
        'Use whenever you feel like it. '
        'Triggers: "the canonical phrase".'
    )
    check(
        "primary 'Triggers:' wins when both markers present (fallback subordinate)",
        extract_trigger_phrases(both) == ["the canonical phrase"],
        f"got {extract_trigger_phrases(both)}",
    )

    # A description with neither marker still returns [] (no false extraction).
    neither = "A plain description with no trigger clause of any recognized form."
    check(
        "no 'Triggers:' and no fallback marker -> []",
        extract_trigger_phrases(neither) == [],
        f"got {extract_trigger_phrases(neither)}",
    )


# --- tokenize + trigger_token_set -------------------------------------------

def test_tokenize() -> None:
    print("tokenize:")
    toks = tokenize("Generate the AM Update")
    # "the" is a stopword; "am" is deliberately NOT a stopword in this corpus;
    # single-char tokens dropped; everything lowercased.
    check("stopword 'the' dropped, 'am' kept, lowercased", toks == {"generate", "am", "update"}, f"got {toks}")

    punct = tokenize("status-update, EOD!")
    check("splits on non-letters", punct == {"status", "update", "eod"}, f"got {punct}")

    only_stop = tokenize("the and or of")
    check("all-stopword phrase -> empty set", only_stop == set(), f"got {only_stop}")


def test_trigger_token_set() -> None:
    print("trigger_token_set:")
    triggers = ["daily status", "morning update"]
    tset = trigger_token_set(triggers)
    check(
        "union of content tokens across phrases",
        tset == {"daily", "status", "morning", "update"},
        f"got {tset}",
    )
    check("empty trigger list -> empty set", trigger_token_set([]) == set(), "expected empty set")


# --- render_markdown (over a real audit() result) ---------------------------

def _write_skill(root: Path, name: str, description: str) -> None:
    """Write a minimal valid SKILL.md (frontmatter + H1 body) into root/."""
    root.mkdir(parents=True, exist_ok=True)
    fm = f"name: {name}\ndescription: {description}"
    (root / "SKILL.md").write_text(f"---\n{fm}\n---\n\n# {name}\n\nBody.\n")


def test_render_markdown() -> None:
    print("render_markdown (via audit()):")
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        # Two skills that share the domain token "status" -> a non-zero pair.
        _write_skill(base / "alpha", "alpha", 'Does A. Triggers: "daily status".')
        _write_skill(base / "beta", "beta", 'Does B. Triggers: "weekly status".')
        result = audit(base, ["alpha", "beta"], threshold=0.30)

        check("audit() audited 2 skills", result["summary"]["skills_audited"] == 2,
              f"got {result['summary']['skills_audited']}")
        check("audit() produced 1 pair", result["summary"]["total_pairs"] == 1,
              f"got {result['summary']['total_pairs']}")

        md = render_markdown(result)
        check("render_markdown returns a str", isinstance(md, str))
        check("markdown carries the title header",
              "# Cross-Skill False-Positive Matrix (Automated)" in md)
        check("markdown reports the verdict", f"**{result['summary']['verdict']}**" in md)
        check("markdown ends with a trailing newline", md.endswith("\n"))

        # Missing SKILL.md is skipped gracefully (not counted).
        result_missing = audit(base, ["alpha", "does-not-exist"], threshold=0.30)
        check("audit() skips a missing SKILL.md",
              result_missing["summary"]["skills_audited"] == 1,
              f"got {result_missing['summary']['skills_audited']}")


# --- split_eval_set (holdout + seed reproducibility) ------------------------

def _eval_set(n_trigger: int, n_no_trigger: int) -> list[dict]:
    items = [{"query": f"t{i}", "should_trigger": True} for i in range(n_trigger)]
    items += [{"query": f"n{i}", "should_trigger": False} for i in range(n_no_trigger)]
    return items


def test_split_eval_set() -> None:
    print("split_eval_set:")
    eval_set = _eval_set(10, 10)

    train, test = split_eval_set(eval_set, holdout=0.2, seed=42)
    # holdout 0.2 of 10 per group = 2 test each -> 4 test, 16 train.
    check("holdout 0.2 -> 4 test items", len(test) == 4, f"got {len(test)}")
    check("holdout 0.2 -> 16 train items", len(train) == 16, f"got {len(train)}")
    check("train + test partitions the whole set",
          len(train) + len(test) == len(eval_set), f"got {len(train)}+{len(test)}")

    # No item appears in both partitions.
    train_q = {e["query"] for e in train}
    test_q = {e["query"] for e in test}
    check("train and test are disjoint", train_q.isdisjoint(test_q), "overlap detected")

    # Seed reproducibility: same seed -> identical split.
    train2, test2 = split_eval_set(eval_set, holdout=0.2, seed=42)
    check("same seed reproduces the split",
          [e["query"] for e in test] == [e["query"] for e in test2],
          "split differed across identical seeds")

    # Each group keeps at least one test item (max(1, ...) floor).
    tiny = _eval_set(1, 1)
    t_train, t_test = split_eval_set(tiny, holdout=0.2, seed=1)
    check("min-1 test floor per group with tiny set", len(t_test) == 2, f"got {len(t_test)}")


# --- assert_branch_fresh (pure is_fresh core, injected git runner) ----------

def test_is_fresh() -> None:
    print("is_fresh (branch-freshness pure core):")

    # Empty git output -> branch is fresh, no unreachable commits.
    fresh, unreachable = is_fresh("origin/main", "HEAD", lambda argv: "")
    check("empty git output -> fresh", fresh is True and unreachable == [],
          f"got fresh={fresh} unreachable={unreachable}")

    # Non-empty output -> stale, and the unreachable lines are returned verbatim.
    two_lines = "abc1234 chore: a\ndef5678 feat: b"
    fresh, unreachable = is_fresh("origin/main", "HEAD", lambda argv: two_lines)
    check("two commit lines -> stale with 2 unreachable",
          fresh is False and unreachable == ["abc1234 chore: a", "def5678 feat: b"],
          f"got fresh={fresh} unreachable={unreachable}")

    # Whitespace-only output is treated as empty (fresh) — no phantom stale commit.
    fresh, unreachable = is_fresh("origin/main", "HEAD", lambda argv: "\n   \n")
    check("whitespace-only output -> fresh (no phantom commit)",
          fresh is True and unreachable == [],
          f"got fresh={fresh} unreachable={unreachable}")

    # The core issues exactly `git log --oneline <base> ^<head>` (the design command).
    captured: dict = {}

    def _spy(argv: list) -> str:
        captured["argv"] = argv
        return ""

    is_fresh("origin/main", "HEAD", _spy)
    check("issues `git log --oneline origin/main ^HEAD`",
          captured.get("argv") == ["log", "--oneline", "origin/main", "^HEAD"],
          f"got {captured.get('argv')}")


# --- runner -----------------------------------------------------------------

def main() -> int:
    print("=== pmo-skill-refiner eval-script unit tests (hermetic) ===\n")
    test_jaccard()
    test_extract_trigger_phrases()
    test_tokenize()
    test_trigger_token_set()
    test_render_markdown()
    test_split_eval_set()
    test_is_fresh()

    print()
    if _FAILURES:
        print(f"FAILED: {len(_FAILURES)} assertion(s): {', '.join(_FAILURES)}")
        return 1
    print("OK: all eval-script unit tests passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

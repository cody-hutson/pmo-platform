#!/usr/bin/env python3
"""Cross-skill trigger audit harness (authoritative false-positive detection).

Reads N SKILL.md files, extracts each skill's trigger set from the frontmatter
`description:` field ("Triggers: ..." prose), and produces a pairwise + group-level
routing-conflict report. Pre-merge guardrail for the cross-skill trigger audit
(Decision 3 Option c).

Mechanism: content-token Jaccard overlap + exact-phrase overlap per skill pair.
Stopwords (articles, prepositions, pronouns, auxiliaries, generic fillers) are
stripped so scoring reflects routing-relevant domain tokens only. Verdict:
PASS if all pairs < threshold (default 0.30); ESCALATE otherwise (Tier 2
inter-stage feedback per release-process.md).

Whole-suite resolution: `--skills-dir` is REPEATABLE (`action="append"`), so one
invocation can span the three module roots of the modular monolith
(`core/skills`, `operations/skills`, `release/skills`). A single root is
structurally blind to every cross-module pair, so a per-root run can never
substitute for one whole-suite run. When `--skills-dir` is omitted the roots are
resolved self-locatingly from this file's own position; when nothing resolves,
or a skill name resolves in zero or in more than one root, the run FAILS LOUD
(exit 3) rather than auditing a silently truncated population.

Composition-awareness (CR-1): with `--composition-aware` plus `--registry`, a
pair whose two skills carry a `DEPENDS_ON` edge in the skill registry is exempt
from the WATCH band ONLY — the ESCALATE band applies to it unchanged. A role and
the function-skill it composes legitimately share vocabulary; a role and its
engine colliding at or above the ESCALATE threshold is still a defect. The
exempted set is reported (`exempt_watch`), never silently dropped.

Imports: parse_skill_md from scripts.utils. Does NOT modify the single-skill
API surface of run_eval.py (depended on by run_loop.py). The lexical primitives
`extract_trigger_phrases` / `tokenize` / `jaccard` keep their signatures — they
are the single metric source shared with run_routing_audit.py (ADR-084 D3).

Usage:
    python3 release/skills/pmo-skill-refiner/scripts/run_eval_audit.py \\
        --skills-dir core/skills --skills-dir operations/skills --skills-dir release/skills \\
        --skills ppm-agent,comms-writer,daily-status \\
        --registry core/skills/registry.md --composition-aware \\
        --threshold 0.30

Exit codes: 0 = PASS, 1 = ESCALATE (any pair >= threshold), 2 = input error
(argparse / empty --skills), 3 = resolution failure (no skill root resolved, or a
skill name resolving in zero or in >1 root). Exit 3 exists because the shipped
behaviour was to warn on stderr and drop the name — which turned an unresolvable
population into `Skills audited: 0 … Verdict: PASS`, exit 0. A zero here is not a
clean result; it is an unestablished population.
"""

# PEP 604 (`X | None`) annotations are used below and the platform's runtime
# interpreter is 3.9, where those are a TypeError at def-time. Deferring annotation
# evaluation is the in-repo fix — scripts/test_eval_scripts.py already does exactly
# this. Keep this import first; it must precede all other imports.
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import tempfile
from itertools import combinations
from pathlib import Path
from typing import Optional, Sequence, Union

# Self-locating package bootstrap: makes this script runnable from ANY cwd with no
# PYTHONPATH set. Mirrors the pattern already used by scripts/test_eval_scripts.py
# (which runs bare from the repo root today, including in CI). Guarded so repeated
# imports — run_routing_audit.py imports this module — do not accumulate sys.path
# entries. Without it, `from scripts.utils import ...` below raises ModuleNotFoundError
# and any gate wired to this script dies at import: a dormant gate reported as a
# broken one.
_PKG_PARENT = str(Path(__file__).resolve().parent.parent)
if _PKG_PARENT not in sys.path:
    sys.path.insert(0, _PKG_PARENT)

from scripts.utils import parse_skill_md  # noqa: E402


class SkillResolutionError(RuntimeError):
    """A skill name resolved in zero roots, or ambiguously in more than one.

    Raised only in strict mode. Mapped to exit 3 by main(). Ambiguity is a repo
    defect (two module roots carrying the same skill directory name), never a
    silent first-root pick.
    """

# Stopwords stripped before tokenization. Matches Batch 1 rationale: articles,
# prepositions, pronouns, auxiliaries, and generic filler verbs that do not
# carry routing signal. Domain-informative tokens (e.g., "just", "testing",
# "weekly") are preserved.
STOPWORDS = frozenset({
    "a", "an", "the",
    "in", "on", "at", "of", "for", "to", "with", "by", "from", "about",
    "under", "over", "through", "into", "onto", "out", "off", "up", "down",
    "i", "me", "my", "mine", "we", "us", "our", "ours", "you", "your", "yours",
    "he", "him", "his", "she", "her", "hers", "it", "its", "they", "them", "their",
    "this", "that", "these", "those", "there", "here",
    "is", "are", "was", "were", "be", "been", "being",
    # NOTE: "am" is deliberately NOT a stopword — it's domain-meaningful
    # ("AM update" / "AM testing") in this skills corpus.
    "have", "has", "had", "having", "do", "does", "did", "doing",
    "will", "would", "shall", "should", "may", "might", "must", "can", "could",
    "and", "or", "but", "nor", "if", "then", "else", "when", "while", "as", "than",
    "what", "who", "whom", "which", "whose", "why", "how",
    "came", "come", "coming", "get", "got", "getting",
    "not", "no", "yes",
    "s", "t", "re", "ve", "ll", "d", "m",
})


def extract_trigger_phrases(description: str) -> list[str]:
    """Extract trigger phrases from a skill description.

    Primary path (unchanged): the ``Triggers: ...`` prose convention — extract the
    ``"..."``-quoted phrases from the region after the ``Triggers:`` keyword.

    Additive fallback (fires ONLY when the primary path yields nothing): descriptions
    that carry their trigger clause in the ``Use whenever ...`` / ``Use when ...`` /
    ``phrases like "..."`` form instead of a ``Triggers:`` keyword. Without this branch
    such descriptions contribute an EMPTY trigger token set and are silently un-audited
    by the cross-skill routing-conflict check (e.g. eval-writer, prompt-builder). A
    skill with an empty token set scores J = 0.0 against every other skill
    unconditionally, so it is not "clean" — it is unexamined, and the gate would
    publish it inside a denominator it never actually looked at.

    ``Use when`` is the third live clause form and is ordered AFTER ``Use whenever`` in
    the alternation: the alternation is leftmost-first at a shared start position, so
    ``Use whenever`` must be offered first or it would be consumed as ``Use when`` +
    a stray ``ever``.

    The fallback is subordinate by construction: any description matched by the primary
    ``Triggers:`` path returns before it is reached, so already-audited skills keep
    byte-identical output (regression-preserving).

    Returns phrases in source order. Handles multiline descriptions.
    """
    match = re.search(r"Triggers\s*:\s*(.+)", description, re.DOTALL | re.IGNORECASE)
    if match:
        trigger_region = match.group(1)
        phrases = re.findall(r'"([^"]+)"', trigger_region)
        return [p.strip() for p in phrases if p.strip()]

    # Fallback (primary matched nothing): the "Use whenever ..." / "Use when ..." /
    # "phrases like ..." trigger-clause form. Anchor on whichever marker appears first,
    # then read to the end of the description.
    fallback = re.search(r"(?:phrases like|Use whenever|Use when)\s*(.+)", description,
                         re.DOTALL | re.IGNORECASE)
    if not fallback:
        return []
    trigger_region = fallback.group(1)

    # Sub-form 1: quoted phrases inside the clause (e.g. prompt-builder's
    # `phrases like "help me write a prompt for…", "improve this prompt"`).
    quoted = re.findall(r'"([^"]+)"', trigger_region)
    if quoted:
        return [p.strip() for p in quoted if p.strip()]

    # Sub-form 2: unquoted, comma / " or "-separated verb phrases (e.g. eval-writer's
    # `Use whenever the user asks to write evals, audit evals, add eval coverage, …`).
    # Split on commas and the " or " connective; STOPWORDS in tokenize() strip the
    # connective/filler tokens so scoring stays on domain tokens.
    candidates = re.split(r",|\bor\b", trigger_region)
    return [p.strip(" .\t\n") for p in candidates if p.strip(" .\t\n")]


def tokenize(phrase: str) -> set[str]:
    """Lowercase, split on non-letter chars, drop stopwords and 1-char tokens."""
    return {
        tok for tok in re.findall(r"[a-z]+", phrase.lower())
        if tok not in STOPWORDS and len(tok) > 1
    }


def trigger_token_set(triggers: list[str]) -> set[str]:
    """Union content-token set across all trigger phrases for a skill."""
    tokens: set[str] = set()
    for phrase in triggers:
        tokens |= tokenize(phrase)
    return tokens


def jaccard(a: set[str], b: set[str]) -> float:
    union = a | b
    if not union:
        return 0.0
    return len(a & b) / len(union)


def parse_depends_on_edges(registry_path: Path) -> dict[str, set[str]]:
    """Parse the skill registry's markdown CI table into a DEPENDS_ON adjacency map.

    Reads the pipe-table rows, taking column 1 as the CI name (unwrapping the
    ``[`name`](path)`` markdown-link form) and the ``dependencies`` column's
    ``DEPENDS_ON <name>`` entries as edges. Edges are accumulated (never
    overwritten) so a name appearing in more than one table keeps all its edges,
    and every edge is stored in BOTH directions — CR-1's exemption predicate is
    symmetric ("linked in either direction").

    ``RELATES_TO`` is deliberately NOT an edge here: it is a soft catalogue
    affinity, not the compose-not-absorb relationship ADR-019 describes, and it
    must not confer a band exemption.
    """
    edges: dict[str, set[str]] = {}
    if not registry_path.exists():
        return edges
    name_re = re.compile(r"^\[`([^`]+)`\]|^`?([a-z0-9][a-z0-9-]+)`?$")
    for line in registry_path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 5:
            continue
        m = name_re.match(cells[0])
        if not m:
            continue
        name = m.group(1) or m.group(2)
        for dep in re.findall(r"DEPENDS_ON\s+([a-z0-9][a-z0-9-]+)", cells[4]):
            edges.setdefault(name, set()).add(dep)
            edges.setdefault(dep, set()).add(name)
    return edges


def _resolve_skill_dir(roots: list[Path], name: str, strict: bool) -> Path | None:
    """Locate <root>/<name>/SKILL.md across the roots. Fail loud in strict mode."""
    hits = [root / name for root in roots if (root / name / "SKILL.md").is_file()]
    if len(hits) == 1:
        return hits[0]
    if not hits:
        msg = (f"no SKILL.md for '{name}' under any of: "
               f"{', '.join(str(r) for r in roots)}")
        if strict:
            raise SkillResolutionError(msg)
        print(f"Warning: {msg}", file=sys.stderr)
        return None
    msg = (f"'{name}' resolves in {len(hits)} roots ({', '.join(str(h) for h in hits)}) "
           f"— ambiguous; a duplicated skill directory name is a repo defect")
    if strict:
        raise SkillResolutionError(msg)
    print(f"Warning: {msg} — using the first", file=sys.stderr)
    return hits[0]


def audit(skills_dir: Union[Path, Sequence[Path]], skill_names: list[str],
          threshold: float, *, edges: Optional[dict] = None,
          composition_aware: bool = False, strict: bool = False) -> dict:
    """Run the cross-skill audit; return structured results.

    ``skills_dir`` accepts a single ``Path`` (the historical form — preserved so
    existing positional callers such as scripts/test_eval_scripts.py are
    untouched) or any sequence of ``Path``s (the whole-suite form). Roots are
    searched in order and a name must resolve in exactly one of them.

    ``strict`` (default False, preserving the historical warn-and-skip library
    contract) turns an unresolvable or ambiguous name into a
    ``SkillResolutionError``. The CLI sets it; main() maps it to exit 3.

    ``composition_aware`` applies CR-1: a pair carrying a ``DEPENDS_ON`` edge in
    ``edges`` is exempt from the WATCH band only. Exempted pairs are recorded in
    ``summary.exempt_watch`` with their raw status, so the suppression is
    auditable rather than silent.
    """
    roots = [skills_dir] if isinstance(skills_dir, (str, Path)) else list(skills_dir)
    roots = [Path(r) for r in roots]
    edges = edges or {}

    skill_records: list[dict] = []
    for name in skill_names:
        skill_path = _resolve_skill_dir(roots, name, strict)
        if skill_path is None:
            continue
        _, description, _ = parse_skill_md(skill_path)
        triggers = extract_trigger_phrases(description)
        skill_records.append({
            "skill": name,
            "triggers": triggers,
            "tokens": trigger_token_set(triggers),
        })

    pairs: list[dict] = []
    exempt_watch: list[dict] = []
    for a, b in combinations(skill_records, 2):
        j = jaccard(a["tokens"], b["tokens"])
        if j >= threshold:
            raw_status = "ESCALATE"
        elif j >= threshold * 0.67:
            raw_status = "WATCH"
        else:
            raw_status = "PASS"
        linked = b["skill"] in edges.get(a["skill"], ())
        status = raw_status
        if composition_aware and linked and raw_status == "WATCH":
            # CR-1: composition linkage suppresses the WATCH band ONLY. ESCALATE is
            # never suppressed — every composition-linked defect measured on this
            # corpus sat at or above the ESCALATE threshold, so a blanket skip would
            # have suppressed 100% of the gate's own findings.
            status = "PASS"
            exempt_watch.append({
                "skill_a": a["skill"], "skill_b": b["skill"],
                "jaccard": round(j, 3), "raw_status": raw_status,
            })
        pairs.append({
            "skill_a": a["skill"],
            "skill_b": b["skill"],
            "token_intersection": sorted(a["tokens"] & b["tokens"]),
            "jaccard": round(j, 3),
            "exact_phrase_overlap": sorted(set(a["triggers"]) & set(b["triggers"])),
            "status": status,
            "raw_status": raw_status,
            "composition_linked": linked,
        })

    escalate = [p for p in pairs if p["status"] == "ESCALATE"]
    watch = [p for p in pairs if p["status"] == "WATCH"]
    max_jaccard = max((p["jaccard"] for p in pairs), default=0.0)

    # Auditable-population reporting. A skill whose description yields no trigger
    # phrases contributes an EMPTY token set and scores 0.0 against everything, so
    # every pair it belongs to is structurally incapable of returning non-zero.
    # Publishing only the nominal counts would let "nothing found" read identically
    # to "nothing examined" — the exact failure the DENOM line exists to prevent.
    blind = sorted(s["skill"] for s in skill_records if not s["tokens"])
    n_disc = sum(1 for p in pairs
                 if p["skill_a"] not in blind and p["skill_b"] not in blind)

    return {
        "threshold": threshold,
        "roots": [str(r) for r in roots],
        "composition_aware": composition_aware,
        "skills": [
            {"skill": s["skill"], "trigger_count": len(s["triggers"]), "tokens": sorted(s["tokens"])}
            for s in skill_records
        ],
        "pairs": pairs,
        "summary": {
            "skills_audited": len(skill_records),
            "total_pairs": len(pairs),
            "pairs_escalate": len(escalate),
            "pairs_watch": len(watch),
            "max_jaccard": max_jaccard,
            "skills_with_triggers": len(skill_records) - len(blind),
            "blind_skills": blind,
            "discriminating_pairs": n_disc,
            "exempt_watch": exempt_watch,
            "verdict": "ESCALATE" if escalate else ("WATCH" if watch else "PASS"),
        },
    }


def render_markdown(result: dict) -> str:
    s = result["summary"]
    lines = [
        "# Cross-Skill False-Positive Matrix (Automated)",
        "",
        f"**Mechanism:** `run_eval_audit.py` — content-token Jaccard + exact-phrase overlap.",
        f"**Threshold:** {result['threshold']} (pair at/above → ESCALATE; two-thirds of threshold → WATCH).",
        f"**Skills audited:** {s['skills_audited']}",
        f"**Total pairs:** {s['total_pairs']}",
        f"**Max Jaccard:** {s['max_jaccard']}",
        f"**Verdict:** **{s['verdict']}**",
        "",
        "## Non-Zero Pairs (sorted by Jaccard desc)",
        "",
        "| Skill A | Skill B | Intersection | Jaccard | Status |",
        "|---|---|---|---|---|",
    ]
    non_zero = sorted(
        (p for p in result["pairs"] if p["jaccard"] > 0.0),
        key=lambda x: (-x["jaccard"], x["skill_a"], x["skill_b"]),
    )
    for p in non_zero:
        tokens = ", ".join(p["token_intersection"]) or "(empty)"
        lines.append(
            f"| {p['skill_a']} | {p['skill_b']} | {{{tokens}}} | {p['jaccard']:.3f} | {p['status']} |"
        )
    if not non_zero:
        lines.append("| *(no pairs with Jaccard > 0.0)* | | | | |")

    lines += ["", "## Zero-Overlap Pair Count", ""]
    zero_count = sum(1 for p in result["pairs"] if p["jaccard"] == 0.0)
    lines.append(f"{zero_count} of {s['total_pairs']} pairs have zero token overlap.")
    return "\n".join(lines) + "\n"


DEFAULT_MODULE_ROOTS = ("core", "operations", "release")

# ─── Committed self-test fixture set ─────────────────────────────────────────
# Fixture CONTENT is committed here and materialized into a temp root at run time.
# This is the same shape core/deploy/tools/check-citation-anchors.sh uses for its
# own committed fixture set, and it is deliberate: a fixture tree of real
# `SKILL.md` files under a module skill root would enter every corpus census that
# globs that tree (the 55-skill roster probe, the tracked-`*.md` scan) and silently
# move denominators that other checks pin.
#
# TWO ARMS, and both are required:
#   must-flag      — high trigger overlap, NOT composition-linked -> must ESCALATE.
#                    Sensitivity: a probe that cannot be shown to detect proves
#                    nothing, so a clean corpus arm means nothing without it.
#   must-not-flag  — WATCH-band overlap (J = 0.250, inside [0.201, 0.300)), and
#                    composition-linked -> raw WATCH, reported PASS via CR-1.
#                    Specificity: it differs from the flag arm only in the property
#                    under test (band + linkage), so the two are discriminated.
SELF_TEST_SKILLS: dict[str, str] = {
    "must-flag-a":
        "Fixture A for the sensitivity arm. "
        'Triggers: "reconcile the widget ledger", "close the widget ledger", '
        '"widget ledger variance".',
    "must-flag-b":
        "Fixture B for the sensitivity arm; deliberately collides with must-flag-a. "
        'Triggers: "reconcile the widget ledger", "widget ledger variance", '
        '"close the widget ledger".',
    "near-miss-a":
        "Fixture A for the specificity arm. "
        'Triggers: "approve the hedge mandate", "quarterly ledger posture".',
    "near-miss-b":
        "Fixture B for the specificity arm; overlaps near-miss-a inside the WATCH "
        "band only. "
        'Triggers: "hedge ledger posture reprice", "settlement break triage", '
        '"swap book".',
}

# Fixture registry, in the real markdown CI-table shape so --self-test exercises
# parse_depends_on_edges() itself rather than a hand-built dict. near-miss-a and
# near-miss-b are linked; the must-flag pair deliberately is NOT, so no exemption
# can reach it. The RELATES_TO row is the negative control for the edge parser.
SELF_TEST_REGISTRY = """\
| name | kind | module | lifecycle-state | dependencies | owner |
|---|---|---|---|---|---|
| `must-flag-a` | function-skill | fixture | active | — | fixture |
| `must-flag-b` | function-skill | fixture | active | RELATES_TO must-flag-a | fixture |
| `near-miss-a` | role-Specialist | fixture | active | DEPENDS_ON near-miss-b | fixture |
| `near-miss-b` | function-skill | fixture | active | — | fixture |
"""


def resolve_default_roots() -> list[Path]:
    """Self-locate the module skill roots from this file's own position.

    <repo>/release/skills/pmo-skill-refiner/scripts/run_eval_audit.py
      parents[4] == <repo>
    Derived, never hardcoded-absolute, so the script keeps working from a packaged
    or relocated checkout. Only roots that actually exist are returned; the caller
    treats an empty result as a resolution failure (exit 3), never as a clean run.
    """
    repo_root = Path(__file__).resolve().parents[4]
    return [repo_root / m / "skills" for m in DEFAULT_MODULE_ROOTS
            if (repo_root / m / "skills").is_dir()]


def run_self_test(threshold: float) -> int:
    """Exercise the committed fixture set: a must-flag arm and a must-not-flag arm.

    A probe that cannot be shown to detect proves nothing, so the gate runs this
    BEFORE the corpus arm. The must-flag arm must return non-zero (sensitivity);
    the composition-linked near-miss arm must be exempted to PASS by CR-1 while
    its raw status stays WATCH (specificity — the two differ only in the property
    under test). Returns 0 when both arms behave, 1 when an arm misbehaves, 3 when
    the fixture set cannot be materialized.
    """
    try:
        tmp = tempfile.mkdtemp(prefix="c67-selftest-")
    except OSError as exc:
        print(f"SELF-TEST: cannot create fixture root: {exc}", file=sys.stderr)
        return 3
    root = Path(tmp)
    for name, description in SELF_TEST_SKILLS.items():
        (root / name).mkdir(parents=True, exist_ok=True)
        (root / name / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: {description}\n---\n\n# {name}\n\n"
            "Self-test fixture, not a deployed skill.\n", encoding="utf-8")
    registry = root / "fixture-registry.md"
    registry.write_text(SELF_TEST_REGISTRY, encoding="utf-8")

    edges = parse_depends_on_edges(registry)
    ok = True
    # Arm 0 — the edge parser must DISCRIMINATE: DEPENDS_ON is an edge, RELATES_TO
    # is not. Without this arm a parser that returned every edge type would still
    # look healthy on the two scoring arms.
    edge_ok = ("near-miss-b" in edges.get("near-miss-a", set())
               and "must-flag-a" not in edges.get("must-flag-b", set()))
    if not edge_ok:
        ok = False
    print(f"self-test edge-parse arm:    DEPENDS_ON linked={sorted(edges.get('near-miss-a', ()))} "
          f"RELATES_TO_ignored={'must-flag-a' not in edges.get('must-flag-b', set())} -> "
          f"{'OK' if edge_ok else 'FAIL (edge parser did not discriminate the edge types)'}")

    flag = audit(root, ["must-flag-a", "must-flag-b"], threshold,
                 edges=edges, composition_aware=True, strict=True)
    fs = flag["summary"]
    flag_ok = fs["skills_audited"] == 2 and fs["pairs_escalate"] == 1
    if not flag_ok:
        ok = False
    print(f"self-test must-flag arm:     skills={fs['skills_audited']} "
          f"pairs={fs['total_pairs']} maxJ={fs['max_jaccard']:.3f} "
          f"ESCALATE={fs['pairs_escalate']} -> "
          f"{'OK' if flag_ok else 'FAIL (probe did not detect)'}")

    near = audit(root, ["near-miss-a", "near-miss-b"], threshold,
                 edges=edges, composition_aware=True, strict=True)
    ns = near["summary"]
    raw_watch = [p for p in near["pairs"] if p["raw_status"] == "WATCH"]
    near_ok = (ns["skills_audited"] == 2 and len(raw_watch) == 1
               and len(ns["exempt_watch"]) == 1 and ns["pairs_watch"] == 0
               and ns["pairs_escalate"] == 0)
    if not near_ok:
        ok = False
    print(f"self-test must-not-flag arm: skills={ns['skills_audited']} "
          f"pairs={ns['total_pairs']} maxJ={ns['max_jaccard']:.3f} "
          f"raw_WATCH={len(raw_watch)} exempted={len(ns['exempt_watch'])} "
          f"reported_WATCH={ns['pairs_watch']} -> "
          f"{'OK' if near_ok else 'FAIL (CR-1 exemption did not apply as specified)'}")

    shutil.rmtree(root, ignore_errors=True)
    print(f"SELF-TEST: {'PASS' if ok else 'FAIL'} — 3 arms "
          "(edge-parse discrimination, must-flag sensitivity, must-not-flag specificity)")
    return 0 if ok else 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Cross-skill trigger audit harness (false-positive detection)."
    )
    # NOTE: action="append" with a non-None default would APPEND to the default
    # rather than replace it (the classic argparse footgun). default=None plus
    # post-parse resolution avoids it.
    parser.add_argument("--skills-dir", action="append", default=None, type=Path,
                        help="Root directory containing <skill>/SKILL.md subfolders. "
                             "REPEATABLE — pass once per module root to audit the whole "
                             "suite in a single invocation. Omit to self-locate "
                             "core/operations/release skill roots.")
    parser.add_argument("--skills",
                        help="Comma-separated skill names (must match subfolder names).")
    parser.add_argument("--threshold", type=float, default=0.30,
                        help="Jaccard threshold for ESCALATE verdict.")
    parser.add_argument("--output-json", type=Path, default=None,
                        help="Write full audit result JSON here.")
    parser.add_argument("--output-md", type=Path, default=None,
                        help="Write human-readable markdown matrix here.")
    parser.add_argument("--verbose", action="store_true",
                        help="Print per-pair WATCH/ESCALATE rows to stderr.")
    parser.add_argument("--registry", type=Path, default=None,
                        help="Path to the skill registry markdown whose DEPENDS_ON "
                             "edges define composition linkage. Never hardcoded.")
    parser.add_argument("--composition-aware", action="store_true",
                        help="Apply CR-1: a DEPENDS_ON-linked pair is exempt from the "
                             "WATCH band ONLY; the ESCALATE band applies unchanged. "
                             "Exempted pairs are reported, never silently dropped.")
    parser.add_argument("--self-test", action="store_true",
                        help="Run the committed fixture arms (must-flag + "
                             "composition-linked must-not-flag) and exit.")
    args = parser.parse_args()

    if args.self_test:
        return run_self_test(args.threshold)

    if not args.skills:
        print("Error: --skills is required (or use --self-test).", file=sys.stderr)
        return 2
    skill_names = [s.strip() for s in args.skills.split(",") if s.strip()]
    if not skill_names:
        print("Error: --skills cannot be empty.", file=sys.stderr)
        return 2

    roots = args.skills_dir or resolve_default_roots()
    if not roots:
        print("Error: no skill root resolved — the population was never established, "
              "so any verdict here would be untrustworthy. Pass --skills-dir "
              "explicitly (repeatable).", file=sys.stderr)
        return 3
    missing = [r for r in roots if not r.is_dir()]
    if missing:
        print("Error: --skills-dir does not exist: "
              + ", ".join(str(m) for m in missing), file=sys.stderr)
        return 3

    edges: dict[str, set[str]] = {}
    if args.composition_aware:
        if args.registry is None or not args.registry.is_file():
            print("Error: --composition-aware requires --registry <path to an existing "
                  "registry markdown>; without it the run would silently degrade to a "
                  "non-composition-aware audit.", file=sys.stderr)
            return 3
        edges = parse_depends_on_edges(args.registry)
        if not edges:
            print(f"Error: no DEPENDS_ON edges parsed from {args.registry} — the "
                  "composition graph is empty, so every exemption decision would be "
                  "vacuous.", file=sys.stderr)
            return 3

    try:
        result = audit(roots, skill_names, args.threshold, edges=edges,
                       composition_aware=args.composition_aware, strict=True)
    except SkillResolutionError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 3

    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(json.dumps(result, indent=2, default=sorted))
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(render_markdown(result))

    s = result["summary"]
    print(f"Verdict: {s['verdict']}")
    print(f"Roots: {', '.join(result['roots'])}")
    print(f"Skills audited: {s['skills_audited']}  |  Pairs: {s['total_pairs']}")
    # The auditable population, always printed: a skill with no extractable trigger
    # phrases scores 0.0 against everything, so its pairs cannot return non-zero.
    # Reporting only the nominal counts would make "nothing found" indistinguishable
    # from "nothing examined".
    print(f"Auditable: {s['skills_with_triggers']} skills with non-empty trigger sets "
          f"|  {s['discriminating_pairs']} discriminating pairs")
    if s["blind_skills"]:
        print("Blind (no extractable trigger phrases — authoring gap, not a clean "
              "result): " + ", ".join(s["blind_skills"]))
    print(f"Max Jaccard: {s['max_jaccard']:.3f} (threshold {args.threshold})")
    print(f"ESCALATE: {s['pairs_escalate']}  |  WATCH: {s['pairs_watch']}")
    if result["composition_aware"]:
        ex = s["exempt_watch"]
        print(f"Exempt (composition-linked, WATCH band suppressed; ESCALATE never "
              f"suppressed): {len(ex)}"
              + ("" if not ex else " — " + "; ".join(
                  f"{e['skill_a']} <-> {e['skill_b']} J={e['jaccard']:.3f}"
                  for e in sorted(ex, key=lambda x: -x["jaccard"]))))

    if args.verbose:
        for p in result["pairs"]:
            if p["status"] in ("ESCALATE", "WATCH"):
                print(
                    f"  [{p['status']}] {p['skill_a']} ↔ {p['skill_b']} "
                    f"J={p['jaccard']:.3f} ∩={{{', '.join(p['token_intersection'])}}}",
                    file=sys.stderr,
                )

    return 1 if s["verdict"] == "ESCALATE" else 0


if __name__ == "__main__":
    sys.exit(main())

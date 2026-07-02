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

Imports: parse_skill_md from scripts.utils. Does NOT modify the single-skill
API surface of run_eval.py (depended on by run_loop.py).

Usage:
    python -m scripts.run_eval_audit \\
        --skills-dir pmo-platform/skills \\
        --skills ppm-agent,comms-writer,daily-status \\
        --threshold 0.30 \\
        --output-json pmo-platform/analysis/trigger-audit-2026-04-19/_scores/false-positive-matrix.json \\
        --output-md pmo-platform/analysis/trigger-audit-2026-04-19/_scores/false-positive-matrix.md

Exit codes: 0 = PASS, 1 = ESCALATE (any pair >= threshold), 2 = input error.
"""

import argparse
import json
import re
import sys
from itertools import combinations
from pathlib import Path

from scripts.utils import parse_skill_md

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
    that carry their trigger clause in the ``Use whenever ...`` / ``phrases like "..."``
    form instead of a ``Triggers:`` keyword. Without this branch such descriptions
    contribute an EMPTY trigger token set and are silently un-audited by the
    cross-skill routing-conflict check (e.g. eval-writer, prompt-builder). The
    fallback is subordinate by construction: any description matched by the primary
    ``Triggers:`` path returns before it is reached, so already-audited skills keep
    byte-identical output (regression-preserving).

    Returns phrases in source order. Handles multiline descriptions.
    """
    match = re.search(r"Triggers\s*:\s*(.+)", description, re.DOTALL | re.IGNORECASE)
    if match:
        trigger_region = match.group(1)
        phrases = re.findall(r'"([^"]+)"', trigger_region)
        return [p.strip() for p in phrases if p.strip()]

    # Fallback (primary matched nothing): the "Use whenever ..." / "phrases like ..."
    # trigger-clause form. Anchor on whichever marker appears first, then read to the
    # end of the description.
    fallback = re.search(r"(?:phrases like|Use whenever)\s*(.+)", description,
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


def audit(skills_dir: Path, skill_names: list[str], threshold: float) -> dict:
    """Run the cross-skill audit; return structured results."""
    skill_records: list[dict] = []
    for name in skill_names:
        skill_path = skills_dir / name
        if not (skill_path / "SKILL.md").exists():
            print(f"Warning: no SKILL.md at {skill_path}", file=sys.stderr)
            continue
        _, description, _ = parse_skill_md(skill_path)
        triggers = extract_trigger_phrases(description)
        skill_records.append({
            "skill": name,
            "triggers": triggers,
            "tokens": trigger_token_set(triggers),
        })

    pairs: list[dict] = []
    for a, b in combinations(skill_records, 2):
        j = jaccard(a["tokens"], b["tokens"])
        if j >= threshold:
            status = "ESCALATE"
        elif j >= threshold * 0.67:
            status = "WATCH"
        else:
            status = "PASS"
        pairs.append({
            "skill_a": a["skill"],
            "skill_b": b["skill"],
            "token_intersection": sorted(a["tokens"] & b["tokens"]),
            "jaccard": round(j, 3),
            "exact_phrase_overlap": sorted(set(a["triggers"]) & set(b["triggers"])),
            "status": status,
        })

    escalate = [p for p in pairs if p["status"] == "ESCALATE"]
    watch = [p for p in pairs if p["status"] == "WATCH"]
    max_jaccard = max((p["jaccard"] for p in pairs), default=0.0)

    return {
        "threshold": threshold,
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


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Cross-skill trigger audit harness (false-positive detection)."
    )
    parser.add_argument("--skills-dir", default="pmo-platform/skills", type=Path,
                        help="Root directory containing <skill>/SKILL.md subfolders.")
    parser.add_argument("--skills", required=True,
                        help="Comma-separated skill names (must match subfolder names).")
    parser.add_argument("--threshold", type=float, default=0.30,
                        help="Jaccard threshold for ESCALATE verdict.")
    parser.add_argument("--output-json", type=Path, default=None,
                        help="Write full audit result JSON here.")
    parser.add_argument("--output-md", type=Path, default=None,
                        help="Write human-readable markdown matrix here.")
    parser.add_argument("--verbose", action="store_true",
                        help="Print per-pair WATCH/ESCALATE rows to stderr.")
    args = parser.parse_args()

    skill_names = [s.strip() for s in args.skills.split(",") if s.strip()]
    if not skill_names:
        print("Error: --skills cannot be empty.", file=sys.stderr)
        return 2

    result = audit(args.skills_dir, skill_names, args.threshold)

    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(json.dumps(result, indent=2, default=sorted))
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(render_markdown(result))

    s = result["summary"]
    print(f"Verdict: {s['verdict']}")
    print(f"Skills audited: {s['skills_audited']}  |  Pairs: {s['total_pairs']}")
    print(f"Max Jaccard: {s['max_jaccard']:.3f} (threshold {args.threshold})")
    print(f"ESCALATE: {s['pairs_escalate']}  |  WATCH: {s['pairs_watch']}")

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

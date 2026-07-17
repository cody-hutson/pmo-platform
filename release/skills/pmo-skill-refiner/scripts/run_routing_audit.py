#!/usr/bin/env python3
"""Semantic cross-skill routing-conflict audit harness (sibling of run_eval_audit).

Detects the routing collisions the *lexical* audit (run_eval_audit.py) misses:
pairs of skills that are **semantically close but lexically distinct** — a user
request could satisfy both activation predicates even though their trigger
vocabularies barely overlap. run_eval_audit.py catches high-Jaccard (shared-word)
collisions; this harness catches the sub-Jaccard-floor set by embedding each
skill's activation surface and scoring pairwise cosine similarity.

Deferred code half of #704 (spec shipped v3.37); design per the #2699 Stage-5
Solutioning spec (BUILD-OWN — no importable embedding substrate shipped with #17).

Three-tier pipeline (AC-3 sub-n² cost control):
  Tier 0 — Jaccard PRE-FILTER (pure-stdlib, imported from run_eval_audit).
           Compute Jaccard over every pair's activation surface. Partition:
             jaccard >= floor  -> EXCLUDE (already escalated by the lexical audit)
             jaccard <  floor   -> CANDIDATE (the collisions the lexical check misses)
           The imported `jaccard` function is the single source of truth for the
           metric, so "below the floor" means exactly "not escalated by the
           lexical audit" — the two harnesses cannot drift on what "already
           caught" means.
  Tier 1 — EMBED (once per skill, O(n) — the actual spend) + pure-Python cosine
           on the CANDIDATE set only (free local math). Flag a pair when
             cosine >= semantic_threshold  AND  jaccard < jaccard_floor.
  Tier 2 — OPTIONAL bounded agent-runtime judge on the flagged set only
           ("could one user request satisfy both activation predicates?"),
           mirroring #17's reserve-the-judge-for-the-residual pattern. Off by
           default; no library — the judge is an agent-runtime step, not code.

Dependency posture (ADR-084): the embedding backend is a **pluggable, lazily-
imported optional dependency** with a **stub fallback**. The harness skeleton
(pre-filter, cosine math, threshold gating, rendering) is pure-stdlib and imports
with NO pip install and NO network; the heavy embedding library (api/local
backend) is imported *inside* its backend function at run time, never at module
load, so CI and the offline test-suite run the `stub` backend green forever.
This is the platform's first optional-heavy-dependency in the zero-dep eval
corpus — recorded in ADR-084. Reversibility: MODERATE (revertible to Jaccard-only).

Reuse seam: imports `tokenize`, `jaccard`, `extract_trigger_phrases` from
run_eval_audit.py (READ-ONLY — run_eval_audit.py is never modified; its zero-dep
offline CI contract is guarded by test_eval_scripts.py) and `parse_skill_md`
from utils.py.

Testability: `audit()` accepts an injected `embed_fn` (and `judge_fn`), mirroring
the `is_fresh(base, head, runner)` runner-injection idiom already used in this
scripts package, so the semantic layer is exercised offline with canned vectors.

Usage:
    python -m scripts.run_routing_audit \\
        --skills-dir pmo-platform/skills \\
        --skills ppm-agent,comms-writer,daily-status \\
        --embedding-backend stub \\
        --dry-run

Exit codes: 0 = clean (no sub-floor pair crossed the semantic threshold),
            1 = flagged pairs found, 2 = input/usage error.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import re
import sys
from itertools import combinations
from pathlib import Path

# READ-ONLY reuse of the lexical primitives. run_eval_audit.py is NEVER edited
# (AC-1): importing `jaccard` here makes the lexical floor a single source of
# truth shared with the lexical audit. `tokenize` reuses the same stopword set,
# so the token surfaces of the two harnesses cannot drift.
from scripts.run_eval_audit import extract_trigger_phrases, jaccard, tokenize
from scripts.utils import parse_skill_md

# --- Defaults ---------------------------------------------------------------

# Mirrors run_eval_audit.py's argparse default (0.30). It is re-declared here,
# not imported, because run_eval_audit.py exposes the floor only as an argparse
# default (not a module constant) and AC-1 forbids editing it to add one. The
# *metric* single-source-of-truth is the imported `jaccard` function above; this
# is only the shared threshold VALUE. Keep the two in sync if run_eval_audit's
# default ever changes.
DEFAULT_JACCARD_FLOOR = 0.30

# NEW canonicalization (#2699 Stage-5 Evidence-Grounding R1): no cosine/semantic
# threshold precedent exists in-repo (survey 2026-07-12 = 0 hits), so this is a
# set-our-own starting knob the operator calibrates on the first real semantic
# run — exposed as a tunable CLI param. [RECOMMENDED], not a measured claim.
DEFAULT_SEMANTIC_THRESHOLD = 0.60

# Stub-embedding vector dimensionality. Only used by the offline stub backend.
_STUB_DIM = 64

EMBEDDING_BACKENDS = ("stub", "api", "local", "agent")


# --- Activation-surface extraction ------------------------------------------

def extract_activation_surface(description: str) -> str:
    """Concatenate a skill's routing-relevant activation surface from `description`.

    Broader than `extract_trigger_phrases` (which returns only the trigger
    phrases): the semantic embedding wants the full activation predicate, so this
    joins three regions of the description —
        (1) the ``Use when`` / ``Use whenever`` clause,
        (2) the ``Triggers:`` phrases (via the imported `extract_trigger_phrases`,
            so the two harnesses share one trigger-extraction path), and
        (3) the ``Modes:`` names.
    Falls back to the whole description when none of the three regions match, so a
    skill never contributes an EMPTY surface (which would zero out both its
    embedding and its Jaccard token set).
    """
    parts: list[str] = []

    # (1) "Use when" / "Use whenever" clause — from the marker to the next
    #     section marker (Triggers: / Modes:) or end of description.
    use = re.search(
        r"(Use when(?:ever)?\b.*?)(?:Triggers\s*:|Modes\s*:|$)",
        description, re.DOTALL | re.IGNORECASE,
    )
    if use:
        parts.append(use.group(1).strip())

    # (2) Trigger phrases — reuse the imported extractor (single trigger-parse path).
    parts.extend(extract_trigger_phrases(description))

    # (3) Modes names.
    modes = re.search(
        r"Modes?\s*:\s*(.+?)(?:\.\s|Triggers\s*:|Use when|$)",
        description, re.DOTALL | re.IGNORECASE,
    )
    if modes:
        for mode in re.split(r"·|,|/|\||;", modes.group(1)):
            mode = mode.strip(" .\t\n")
            if mode:
                parts.append(mode)

    surface = " ".join(p for p in parts if p).strip()
    return surface if surface else description.strip()


def surface_token_set(surface: str) -> set[str]:
    """Content-token set of an activation surface (imported tokenizer = shared stopwords)."""
    return tokenize(surface)


# --- Embedding backends (pluggable, lazily imported, stub fallback) ---------

def _stub_embed(surfaces: list[str]) -> list[list[float]]:
    """Deterministic offline stub embedding — NO network, NO model, NO pip install.

    Seeds a PRNG from a stable hash of each surface and emits a unit vector.
    This is a structural stand-in for CI and offline tests: it is deterministic
    and dependency-free, but it is NOT a semantic model — distinct surfaces map
    to near-orthogonal vectors, so a stub-backed run correctly finds no real
    semantic collisions. Real detection needs the `api`/`local` backend (opt-in,
    off the CI path). Tests that need controlled cosine inject their own
    `embed_fn` with canned vectors.
    """
    vectors: list[list[float]] = []
    for surface in surfaces:
        seed = int.from_bytes(hashlib.sha256(surface.encode("utf-8")).digest()[:8], "big")
        rng = random.Random(seed)
        vectors.append(_normalize([rng.gauss(0.0, 1.0) for _ in range(_STUB_DIM)]))
    return vectors


def _api_embed(surfaces: list[str]) -> list[list[float]]:
    """Remote-API embedding backend — heavy dependency imported LAZILY, never at load.

    Opt-in only. The import lives inside the function so the module stays
    stdlib-only at import time (the zero-dep CI contract). Absence degrades with a
    clear, actionable message rather than a module-load ImportError.
    """
    try:
        # Lazy import — deliberately inside the function body (ADR-084). The exact
        # client/model is an operator-configured detail; this backend is exercised
        # only on a live semantic pass, never in CI.
        import importlib

        client_mod = importlib.import_module("anthropic")  # noqa: F401
    except ImportError as exc:  # pragma: no cover - offline path not exercised in CI
        raise RuntimeError(
            "The 'api' embedding backend requires an embeddings client "
            "(optional, opt-in). Install it for a live semantic pass, or use "
            "--embedding-backend stub for the offline/CI structural run."
        ) from exc
    raise NotImplementedError(  # pragma: no cover
        "Wire the configured embeddings endpoint here for a live semantic pass; "
        "the stub backend covers the offline/CI structural contract."
    )


def _local_embed(surfaces: list[str]) -> list[list[float]]:
    """Local-model embedding backend (e.g. sentence-transformers) — LAZY import.

    Opt-in only; the heavy transitive deps (torch, etc.) are imported inside the
    function so they never touch module load or CI.
    """
    try:
        import importlib

        st_mod = importlib.import_module("sentence_transformers")  # noqa: F401
    except ImportError as exc:  # pragma: no cover - offline path not exercised in CI
        raise RuntimeError(
            "The 'local' embedding backend requires sentence-transformers "
            "(optional, opt-in, heavy). Install it for a live semantic pass, or "
            "use --embedding-backend stub for the offline/CI structural run."
        ) from exc
    raise NotImplementedError(  # pragma: no cover
        "Wire the configured local model here for a live semantic pass; the stub "
        "backend covers the offline/CI structural contract."
    )


def _agent_embed(surfaces: list[str]) -> list[list[float]]:
    """Agent-runtime backend placeholder.

    The agent-runtime judgment path (mirroring #17) is a Tier-2 *judge*, not an
    embedding source; there is no callable agent embedding in-repo. Selecting it
    as an embedding backend is a usage error surfaced clearly rather than silently
    producing garbage vectors.
    """
    raise RuntimeError(  # pragma: no cover - guarded at CLI parse
        "The 'agent' path is the Tier-2 judge (run_judge), not an embedding "
        "backend. Use --embedding-backend {stub|api|local} and enable the judge "
        "separately."
    )


_BACKEND_DISPATCH = {
    "stub": _stub_embed,
    "api": _api_embed,
    "local": _local_embed,
    "agent": _agent_embed,
}


def resolve_embed_fn(backend: str):
    """Map an --embedding-backend name to its embedding function (dispatch)."""
    try:
        return _BACKEND_DISPATCH[backend]
    except KeyError:
        raise ValueError(
            f"Unknown embedding backend {backend!r}; choose one of {EMBEDDING_BACKENDS}."
        )


def embed(surfaces: list[str], backend: str = "stub") -> list[list[float]]:
    """Embed activation surfaces with the named backend (convenience wrapper)."""
    return resolve_embed_fn(backend)(surfaces)


# --- Pure-Python cosine (no numpy) ------------------------------------------

def _normalize(vec: list[float]) -> list[float]:
    norm = math.sqrt(sum(x * x for x in vec))
    if norm == 0.0:
        return list(vec)
    return [x / norm for x in vec]


def cosine(a: list[float], b: list[float]) -> float:
    """Cosine similarity of two equal-length vectors — pure arithmetic, no numpy."""
    if len(a) != len(b):
        raise ValueError(f"cosine: length mismatch ({len(a)} vs {len(b)})")
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    if na == 0.0 or nb == 0.0:
        return 0.0
    return dot / (na * nb)


# --- Default Tier-2 judge (agent-runtime; offline no-op) ---------------------

def _default_judge(flagged_pairs: list[dict]) -> list[dict]:
    """Offline default judge: records the residual for agent-runtime evaluation.

    The real Tier-2 judge is an agent-runtime conversational step orchestrated by
    the SKILL.md (mirroring #17's judge), NOT a library call. Offline this returns
    an 'unevaluated' verdict so the pipeline is complete and testable without an
    agent. Tests inject their own `judge_fn` to exercise the hook.
    """
    for pair in flagged_pairs:
        pair["judge_verdict"] = "unevaluated (agent-runtime judge not run offline)"
    return flagged_pairs


# --- The audit --------------------------------------------------------------

def audit(
    skills_dir: Path,
    skill_names: list[str],
    *,
    jaccard_floor: float = DEFAULT_JACCARD_FLOOR,
    semantic_threshold: float = DEFAULT_SEMANTIC_THRESHOLD,
    backend: str = "stub",
    max_pairs: int | None = None,
    embed_fn=None,
    judge_fn=None,
    run_judge: bool = False,
) -> dict:
    """Run the three-tier semantic routing-conflict audit; return structured results.

    `embed_fn` (callable[list[str]] -> list[list[float]]) and `judge_fn`
    (callable[list[dict]] -> list[dict]) are injectable for offline testing; when
    None they resolve to the named `backend` / the default agent-runtime judge.

    The returned dict carries instrumentation counts — `embeds`, `cosines`,
    `judge_calls`, `total_pairs`, `candidates`, `flagged` — for the AC-3
    sub-n² cost assertion (`embeds == n`, `cosines == candidates <= total_pairs`).
    """
    if embed_fn is None:
        embed_fn = resolve_embed_fn(backend)

    # Load skill records with their activation surfaces + Jaccard token sets.
    records: list[dict] = []
    for name in skill_names:
        skill_path = skills_dir / name
        if not (skill_path / "SKILL.md").exists():
            print(f"Warning: no SKILL.md at {skill_path}", file=sys.stderr)
            continue
        _, description, _ = parse_skill_md(skill_path)
        surface = extract_activation_surface(description)
        records.append({
            "skill": name,
            "surface": surface,
            "tokens": surface_token_set(surface),
        })

    n = len(records)
    total_pairs = n * (n - 1) // 2

    # Tier 0 — Jaccard pre-filter. Partition every pair into already-lexically-
    # caught (>= floor, EXCLUDE) vs. sub-floor candidate (< floor).
    candidate_pairs: list[tuple[int, int, float]] = []  # (i, j, jaccard)
    for i, j in combinations(range(n), 2):
        jac = jaccard(records[i]["tokens"], records[j]["tokens"])
        if jac < jaccard_floor:
            candidate_pairs.append((i, j, jac))
    # Deterministic order (lowest Jaccard first — the "most lexically distinct"
    # candidates), then cap to max_pairs if the operator bounded the spend.
    candidate_pairs.sort(key=lambda t: (t[2], t[0], t[1]))
    if max_pairs is not None:
        candidate_pairs = candidate_pairs[:max_pairs]

    # Tier 1 — embed each surface ONCE (O(n) — the actual spend), then cosine on
    # the candidate set only (free local math). Only embed surfaces that appear
    # in >= 1 candidate pair, but count `embeds` as the number of embed calls.
    involved = sorted({i for i, _, _ in candidate_pairs} | {j for _, j, _ in candidate_pairs})
    surfaces = [records[i]["surface"] for i in involved]
    vectors = embed_fn(surfaces) if surfaces else []
    vec_by_index = {idx: vectors[pos] for pos, idx in enumerate(involved)}
    embeds = len(surfaces)

    flagged: list[dict] = []
    cosines = 0
    for i, j, jac in candidate_pairs:
        cos = cosine(vec_by_index[i], vec_by_index[j])
        cosines += 1
        if cos >= semantic_threshold:
            flagged.append({
                "skill_a": records[i]["skill"],
                "skill_b": records[j]["skill"],
                "cosine": round(cos, 4),
                "jaccard": round(jac, 4),
                "surface_a_excerpt": records[i]["surface"][:160],
                "surface_b_excerpt": records[j]["surface"][:160],
                "verdict": "semantic-only-collision (sub-Jaccard-floor)",
            })

    # Rank flagged pairs by cosine descending (strongest semantic collision first).
    flagged.sort(key=lambda p: (-p["cosine"], p["skill_a"], p["skill_b"]))

    # Tier 2 — optional bounded agent-runtime judge on the flagged set only.
    judge_calls = 0
    if run_judge and flagged:
        judge = judge_fn if judge_fn is not None else _default_judge
        flagged = judge(flagged)
        judge_calls = len(flagged)

    return {
        "jaccard_floor": jaccard_floor,
        "semantic_threshold": semantic_threshold,
        "backend": backend,
        "skills": [{"skill": r["skill"], "surface_tokens": sorted(r["tokens"])} for r in records],
        "flagged_pairs": flagged,
        # Instrumentation (AC-3): embeds == n_involved (linear); cosines ==
        # candidates (only sub-floor pairs scored); both <= total_pairs << n^2.
        "embeds": embeds,
        "cosines": cosines,
        "judge_calls": judge_calls,
        "total_pairs": total_pairs,
        "candidates": len(candidate_pairs),
        "flagged": len(flagged),
        "skills_audited": n,
    }


# --- Rendering --------------------------------------------------------------

def render_markdown(result: dict) -> str:
    """Ranked flagged-pair report (cosine desc), mirroring run_eval_audit's shape."""
    lines = [
        "# Cross-Skill Semantic Routing-Conflict Matrix (Automated)",
        "",
        "**Mechanism:** `run_routing_audit.py` — embed activation surfaces + pairwise cosine, "
        "flagging pairs **above the semantic threshold but below the Jaccard lexical floor** "
        "(the collisions `run_eval_audit.py` misses).",
        f"**Embedding backend:** {result['backend']}",
        f"**Jaccard floor:** {result['jaccard_floor']} (>= floor -> already escalated by the lexical audit -> excluded).",
        f"**Semantic threshold:** {result['semantic_threshold']} (cosine at/above -> flagged).",
        f"**Skills audited:** {result['skills_audited']}",
        f"**Total pairs:** {result['total_pairs']}  |  "
        f"**Sub-floor candidates scored:** {result['candidates']}  |  "
        f"**Embeds:** {result['embeds']}  |  **Flagged:** {result['flagged']}",
        "",
        "## Flagged Pairs (semantic-close, lexically-distinct — sorted by cosine desc)",
        "",
        "| Skill A | Skill B | Cosine | Jaccard | Verdict |",
        "|---|---|---|---|---|",
    ]
    for p in result["flagged_pairs"]:
        verdict = p.get("judge_verdict", p["verdict"])
        lines.append(
            f"| {p['skill_a']} | {p['skill_b']} | {p['cosine']:.4f} | "
            f"{p['jaccard']:.4f} | {verdict} |"
        )
    if not result["flagged_pairs"]:
        lines.append("| *(no sub-floor pair crossed the semantic threshold)* | | | | |")

    lines += [
        "",
        "## Cost (AC-3 — sub-n^2)",
        "",
        f"Embeds: {result['embeds']} (== involved skills, linear) · "
        f"Cosines: {result['cosines']} (== sub-floor candidates) · "
        f"Judge calls: {result['judge_calls']} · "
        f"vs. total pairs {result['total_pairs']}.",
    ]
    return "\n".join(lines) + "\n"


# --- CLI --------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Semantic cross-skill routing-conflict audit (sibling of the lexical run_eval_audit)."
    )
    parser.add_argument("--skills-dir", default="pmo-platform/skills", type=Path,
                        help="Root directory containing <skill>/SKILL.md subfolders.")
    parser.add_argument("--skills", required=True,
                        help="Comma-separated skill names (must match subfolder names).")
    parser.add_argument("--jaccard-floor", type=float, default=DEFAULT_JACCARD_FLOOR,
                        help="Below this Jaccard, a pair is a semantic candidate "
                             "(mirrors run_eval_audit's default; shared metric via the imported jaccard).")
    parser.add_argument("--semantic-threshold", type=float, default=DEFAULT_SEMANTIC_THRESHOLD,
                        help="Cosine at/above which a sub-floor pair is flagged (tunable; calibrate on first run).")
    parser.add_argument("--embedding-backend", default="stub", choices=EMBEDDING_BACKENDS,
                        help="stub (offline/CI default) | api | local (opt-in heavy dep) | agent (judge only).")
    parser.add_argument("--max-pairs", type=int, default=None,
                        help="Cap the number of candidate pairs scored (cost governor).")
    parser.add_argument("--run-judge", action="store_true",
                        help="Run the optional Tier-2 agent-runtime judge on flagged pairs.")
    parser.add_argument("--output-json", type=Path, default=None,
                        help="Write full audit result JSON here.")
    parser.add_argument("--output-md", type=Path, default=None,
                        help="Write the human-readable markdown matrix here.")
    # Cost governor: --dry-run is the DEFAULT. --run opts into a live semantic pass.
    parser.add_argument("--run", dest="dry_run", action="store_false",
                        help="Opt into a live semantic pass (default is --dry-run: plan + estimate only).")
    parser.add_argument("--dry-run", dest="dry_run", action="store_true",
                        help="Print the plan + estimated spend without scoring (DEFAULT).")
    parser.set_defaults(dry_run=True)
    args = parser.parse_args(argv)

    skill_names = [s.strip() for s in args.skills.split(",") if s.strip()]
    if not skill_names:
        print("Error: --skills cannot be empty.", file=sys.stderr)
        return 2

    n = len(skill_names)
    if args.dry_run:
        # Cost governor: estimate the plan without embedding/spending.
        est_pairs = n * (n - 1) // 2
        print("DRY RUN (default). No embedding calls made; pass --run for a live semantic pass.")
        print(f"Skills: {n}  |  Total pairs: {est_pairs}")
        print(f"Backend: {args.embedding_backend}  |  "
              f"Jaccard floor: {args.jaccard_floor}  |  Semantic threshold: {args.semantic_threshold}")
        print(f"Plan: Jaccard pre-filter over {est_pairs} pairs (free) -> embed <= {n} surfaces "
              f"(the spend) -> cosine on sub-floor candidates only.")
        if args.max_pairs is not None:
            print(f"Candidate cap (--max-pairs): {args.max_pairs}")
        return 0

    try:
        result = audit(
            args.skills_dir, skill_names,
            jaccard_floor=args.jaccard_floor,
            semantic_threshold=args.semantic_threshold,
            backend=args.embedding_backend,
            max_pairs=args.max_pairs,
            run_judge=args.run_judge,
        )
    except (ValueError, RuntimeError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2

    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(json.dumps(result, indent=2, default=sorted))
    if args.output_md:
        args.output_md.parent.mkdir(parents=True, exist_ok=True)
        args.output_md.write_text(render_markdown(result))

    print(f"Backend: {result['backend']}  |  Skills: {result['skills_audited']}  |  "
          f"Pairs: {result['total_pairs']}")
    print(f"Sub-floor candidates: {result['candidates']}  |  Embeds: {result['embeds']}  |  "
          f"Cosines: {result['cosines']}  |  Flagged: {result['flagged']}")
    for p in result["flagged_pairs"]:
        print(f"  [FLAG] {p['skill_a']} <-> {p['skill_b']}  "
              f"cos={p['cosine']:.4f}  jac={p['jaccard']:.4f}")

    return 1 if result["flagged"] else 0


if __name__ == "__main__":
    sys.exit(main())

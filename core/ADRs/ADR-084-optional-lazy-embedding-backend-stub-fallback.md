<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-084 — Optional, lazily-imported embedding backend with a stub fallback (first optional-heavy-dependency in the zero-dep eval corpus)"
status: Accepted
date: 2026-07-12
release: v3.77 skill-hardening
deciders: "Stage-5 Solutioning D2 (the load-bearing embedding-backend D-fork, HIGH confidence) + Collective Review scope-lock (operator elected IMPLEMENT) — recorded at Stage-6 authoring"
tags: [eval-harness, embeddings, optional-dependency, lazy-import, zero-dep-ci, routing-conflict, pmo-skill-refiner, supply-chain]
source_observations:
  - "The pmo-skill-refiner scripts corpus is deliberately zero-dependency: stdlib-only Python that CI runs with 'no pip install, no network' (run_eval_audit.py, utils.py, test_eval_scripts.py). A deliberate design note in tracker-manager/references/tracker-schemas.md records 'Jaccard chosen over cosine / embedding similarity: no embedding substrate ships in-repo' — the absence of an embedding capability is a choice, not an omission."
  - "#2699 (semantic routing-conflict detection, deferred code half of #704) REQUIRES an embedding capability to flag the routing collisions the lexical Jaccard audit misses (semantically close, lexically distinct). Every real embedding backend is a heavy dependency: a remote API (network + key) or a local model (sentence-transformers -> torch, hundreds of MB). Adding one naively would break the zero-dep offline CI contract that the whole scripts corpus depends on."
  - "The Stage-5 spike CONFIRMED #17 (skill-compliance-auditor) shipped no importable embedding/cosine/judge code — it is a pure-bash grep classifier whose 'judge' is an agent-runtime step. There is no in-repo embedding substrate to reuse, so #2699 must introduce the capability itself. That makes the dependency posture a durable, precedent-setting decision, not an incidental one."
---

# ADR-084 — Optional, lazily-imported embedding backend with a stub fallback (first optional-heavy-dependency in the zero-dep eval corpus)

## Status

**Accepted.** The pluggable-lazy-backend-plus-stub design was selected at Stage-5 Solutioning as decision D2 (the load-bearing embedding-backend fork, HIGH confidence) and carried through the Collective Review scope-lock when the operator elected to IMPLEMENT #2699. It is recorded here at Stage-6 authoring because it is the platform's **first optional-heavy-dependency in the otherwise zero-dependency eval-scripts corpus** — the precedent every future embedding/model-backed harness in that corpus will follow. This ADR is the durable record; the Stage-9 review verifies implementation conformance, it does not re-decide the posture.

## Context

The `pmo-skill-refiner/scripts/` corpus is deliberately **zero-dependency**. Its harnesses are stdlib-only Python, and CI (`release-tooling-smoke.yml`, `eval-viewer-tests.yml`) runs them with **no pip install and no network** — the offline contract that keeps the eval tooling reproducible and un-flaky. The lexical routing-conflict audit (`run_eval_audit.py`) embodies this: it scores trigger-token **Jaccard** overlap, and a standing design note (`tracker-manager/references/tracker-schemas.md`) records that Jaccard was chosen over cosine/embedding similarity precisely because *no embedding substrate ships in-repo* and token-set Jaccard is transparent and hand-reproducible.

Issue #2699 (the deferred code half of #704) needs to catch the routing collisions that the **lexical** audit structurally cannot: pairs of skills whose activation surfaces are **semantically close but lexically distinct** — a user request could satisfy both activation predicates even though their trigger vocabularies barely overlap. Detecting that requires **semantic embeddings** and pairwise cosine, not token overlap.

Every real embedding backend is a **heavy dependency**: a remote embeddings API (network access + an API key — unavailable and undesirable in CI) or a local model such as `sentence-transformers` (which pulls `torch` and hundreds of megabytes of transitive deps). A naive `import` of either at module load would **break the zero-dep offline CI contract** for the entire scripts corpus, because CI imports and runs these modules with nothing installed.

The Stage-5 spike confirmed there is **no existing embedding substrate to reuse** (#17 shipped a pure-bash grep classifier with an agent-runtime judge — no importable embedding/cosine code). So #2699 must **introduce** the capability, and the way it introduces it sets platform-wide precedent for the first time. The decision is therefore not *whether* to embed, but *how to add an embedding capability without forfeiting the zero-dep offline CI posture the corpus is built on.*

## Decision

**D1 — The embedding backend is a pluggable seam, selected at runtime, and the heavy library is imported LAZILY inside its backend function — never at module load.** The new harness (`run_routing_audit.py`) exposes `--embedding-backend {stub|api|local|agent}`. The module's top-level imports are **pure stdlib** (`hashlib`, `math`, `random`, `re`, `json`, `argparse`). The heavy library for the `api`/`local` backends is imported **inside** that backend's function body, so it is touched only when an operator actually runs a live semantic pass. The harness skeleton — Jaccard pre-filter, candidate partitioning, cosine arithmetic (pure Python, no numpy), threshold gating, and report rendering — carries **no** third-party import.

**D2 — A `stub` backend is the offline/CI default, so the harness imports and its tests pass with zero pip install and no network.** The `stub` backend returns deterministic, hash-seeded unit vectors from pure stdlib. It is not a semantic model — distinct surfaces map to near-orthogonal vectors, so a stub-backed run correctly finds no real semantic collisions — but it exercises the **entire** pipeline structurally, offline, forever. CI runs the stub; the harness's own test suite (`test_run_routing_audit.py`) runs the stub and injects canned vectors (the runner-injection idiom already used for `is_fresh`) to exercise the semantic layer without any model. Absence of the heavy dependency **degrades gracefully** to the stub, and a missing `api`/`local` library raises a clear, actionable "opt-in" message rather than a module-load `ImportError`.

**D3 — The lexical audit is reused by read-only import, keeping one metric source of truth.** `run_routing_audit.py` imports `jaccard`, `tokenize`, and `extract_trigger_phrases` from `run_eval_audit.py` and never modifies it, so "below the Jaccard floor" means exactly "not escalated by the lexical audit." The two harnesses cannot drift on what "already caught" means. (The floor *value* is re-declared as a local constant only because `run_eval_audit.py` exposes it solely as an argparse default and must stay byte-identical.)

**D4 — Home in `core/ADRs/`.** The optional-heavy-dependency posture is a cross-cutting engineering/supply-chain precedent for the whole eval-scripts corpus, not a release-pipeline (SDLC) stage decision, so this record lives in `core/ADRs/`.

## Alternatives Considered

| Option | Trade-off | Verdict |
|---|---|---|
| **Hard-import a local model at module load** (e.g. top-level `import sentence_transformers`) | Simplest code, but **breaks the zero-dep offline CI contract** for the entire scripts corpus — CI imports these modules with nothing installed, so the import would fail every run. | Rejected — forfeits the corpus's defining posture. |
| **API-only backend** (no local option, no stub) | No local heavy dep, but requires **network + an API key in CI**, which the offline contract forbids; also non-reproducible and flaky. | Rejected — CI cannot reach the network; not reproducible. |
| **Stub-only (never a real embedding)** | Keeps CI trivially green, but the harness could **never** perform real semantic detection — it would ship as permanent scaffolding with no production capability, failing the actual #2699/#704 requirement. | Rejected — defeats the feature; the stub is the offline stand-in, not the whole product. |
| **Vendor an embedding model into the repo** | Offline and reproducible, but adds **hundreds of MB** of binary weight to a governance repo, plus model licensing and supply-chain review overhead, and bloats every clone/package. | Rejected — disproportionate weight and supply-chain surface for an opt-in operator audit. |
| **A second heavyweight judge stack (own embedding infra distinct from #17)** | #17 shipped no reusable embedding infra, so there is nothing to be "second" to — but standing up permanent embedding *infrastructure* (a service, a cached model) for a periodic operator-run audit is over-built. | Rejected — the pluggable seam + agent-runtime Tier-2 judge reuses #17's proven pattern without new infrastructure. |

## Consequences

**Positive.**
- The zero-dep offline CI contract is **preserved by construction**: the harness skeleton and the stub backend are pure stdlib, so CI and the offline test-suite stay green with no pip install and no network.
- Real semantic detection is available **opt-in**: an operator runs `--embedding-backend api|local --run` for a live pass; the heavy dependency is touched only then, quarantined behind one seam.
- A reusable, precedent-setting **dependency posture** (pluggable backend + lazy import + stub fallback) for any future model-backed harness in the eval-scripts corpus, recorded so a later author neither rips it out nor hard-imports the model.
- The Jaccard floor stays a **single source of truth** (imported, not reimplemented), so the lexical and semantic audits cannot disagree on what "already caught" means.

**Negative / accepted.**
- The eval-scripts corpus gains its **first optional-heavy-dependency**. Bounded: optional, opt-in, lazily imported, never installed in CI, and absent-by-default (the stub covers the offline path). Future authors MUST respect the seam — a heavy import that migrates to module top-level silently breaks the contract, so the posture is load-bearing and is the reason this ADR exists.
- The `stub` backend is **not a semantic model**; a stub-backed run cannot find real collisions (by design). Anyone reading a clean stub-run report must understand it proves the pipeline runs, not that the catalog is collision-free — real detection requires an opt-in live pass.
- The `api`/`local` backend functions are **stubs pending an operator-configured endpoint/model**; wiring a concrete embeddings client is deferred to first live use, out of scope for this harness's offline contract.

**Reversibility: MODERATE.** The capability is additive — reverting to Jaccard-only is deleting `run_routing_audit.py` + `test_run_routing_audit.py` (no change to `run_eval_audit.py`, no consumer to unwind). It is not CHEAP only because, once an operator wires a live backend and downstream tooling begins consuming the semantic report, removing it would strand those consumers — the same posture #17 flagged for its calibration surface. Confidence: HIGH.

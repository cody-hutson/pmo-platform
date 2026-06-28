<!-- reference-durability: allow-link -->
# Knowledge Manager — Composition & Reversibility Reference

This reference holds the granular composition contract for `pmo-knowledge-manager` and its skill-specialized reversibility tier vocabulary. The SKILL.md `## Composition` and `## Reversibility Discipline` sections are the operating contract; this file is the detailed surface they derive from. Both are consumed by the composing skill via invocation, never re-implemented ([ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)).

## 1. Composition contract

This Specialist **composes** two function-skills by **invoking them through the `core/`-registry skill-chain** (runtime chaining), and **re-implements neither** — per [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md) (a Specialist composes a shared function-skill by *invoking* it, **not** by copying its logic). The composed skills are read-only here; their modes, gates, staging, and output contracts are owned by them. The Knowledge Manager holds **no** standalone generation or routing mechanics — it adds only the capture-structure-route-steward coherence layered on their outputs.

| Composed function-skill | Invoked for | Modes / capability invoked (owned by the composed skill — NOT re-implemented here) |
|---|---|---|
| [`artifact-generator`](../../artifact-generator/SKILL.md) | **Produce/stage** the asset, and **steward** the KB | **Generate Mode** (Steps 1-6 — produce + stage in `08-Generated/`, `lifecycle_state: draft` + `promotion_state: staged`) · **Wrapper Mode** (Step 4-W — ingest an external asset, never mutate the body) · **Artifact Health Check + Documentation-Debt Register** (zombie >30d / no-longer-current-but-live upkeep) |
| [`file-router`](../../file-router/SKILL.md) | **Classify and route** to the **governed home** | **Layer 1 content / Layer 2 project / Layer 3 filename** classification + **Confidence Thresholds & Actions** (>=90 auto / 60-89 propose / <60 queue) + **Routing Targets** map; **Unclassified Queue + Multi-Project Routing** (gap scan) |

**Compose-not-absorb boundary (ADR-019):** the Knowledge Manager does **not** re-derive any artifact-production, staging, content-classification, or routing-target logic. A mode that "composes `file-router` classification" **chains to** `file-router` and **consumes its classification output as the single source of truth for the asset's governed home** — never inventing a folder; a mode that "composes `artifact-generator` Generate Mode" **chains to** `artifact-generator` and consumes the staged `DRAFT` — never writing the body or header. `artifact-generator` remains the single source of knowledge-artifact generation/staging; `file-router` remains the single source of classification/routing. The Knowledge Manager forks neither. (Enforced by the DT-3 compose-not-absorb review gate per [`skill-pipeline-alignment.md`](../../../../core/standards/skill-pipeline-alignment.md) §6 and the cross-skill false-positive harness.)

**Pipeline relation (skill-pipeline-alignment §2): R3 — cross-stage composing.** Knowledge capture and stewardship is invoked across delivery, close, and operational rhythm alike — no single home stage. The Knowledge Manager declares **R3**, stays stage-agnostic, and composes via skill-chaining (the posture the composed function-skills hold): a Specialist over two R3 services inherits R3.

**Single-source-of-truth routing seam (the role's defining behavior):** Mode 1 produces a `DRAFT` in `08-Generated/`; Mode 3 then runs `file-router` and **the asset's governed home is whatever `file-router` classifies** — never hard-coded. This fixes "generating artifacts and routing them as two disconnected steps": the route is chained off the capture, and the classification output *is* the home.

## 2. Reversibility tier vocabulary

These are the skill-specialized instances of the canonical tiers in [`reversibility-protocol.md`](../../../../core/specs/reversibility-protocol.md). Every decision-class output — enumerated per mode in the SKILL.md `## Reversibility Discipline` — carries a tier + confidence.

**Tier vocabulary (CHEAP-dominant by construction):**
- **CHEAP** (undo in hours) — the dominant tier: a `DRAFT` asset staged in `08-Generated/` nobody has reviewed; a HIGH-confidence auto-route into an auto-write folder (`05-Transcripts/`, `06-Emails/`, `08-Generated/`); an `_unclassified/` queue park; a recommend-only gap-audit item. State the tier, proceed.
- **MODERATE** (undo in days, minor data loss) — a placement that commits a knowledge asset into a project folder and notifies downstream consumers; a Wrapper ingest circulated for review. State the tier, surface the key assumption in ≤1 sentence, invite a reviewer pass.
- **EXPENSIVE** (undo in weeks, stakeholder impact) — a knowledge asset **promoted** into a Tier-1 governed folder (`01-Governance/`, `07-Reference/`) and consumed by reviewers, or a routing-rule change reshaping future classification. Document rationale (≥2 sentences), state the rollback (revert + manual re-classify), name the affected cohort.
- **IRREVERSIBLE** (cannot undo) — a knowledge asset promoted to an external / audit-of-record surface. Rollback infeasible -> name the counter-commitment + sign-off authority, pair with an explicit downside.

Reversibility is *what-if-wrong cost*; confidence is *how-likely-wrong* — both travel together. A HIGH-confidence EXPENSIVE promotion still requires the rationale + rollback.

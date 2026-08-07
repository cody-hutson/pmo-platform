<!-- reference-durability: allow-link -->
# System Architect — Composition Contract, Reversibility Rubric & Blast-Radius Reference

Reference detail for `pmo-architect`. The SKILL.md `## Composition`, `## Modes`, `## Reversibility Discipline`, and `## Output Contract` sections are the authoritative contract; this file carries the per-mode invocation mapping, the full reversibility-tier rubric, and the system blast-radius procedure that the SKILL.md summarizes. Read it when authoring a Mode 1/2/3 output or running as a Stage-5 spoke.

## 1. Per-mode composition mapping

Every technical / risk claim in a System Architect output is sourced to one of the composed-skill modes below — a claim with no composition reference is dropped before output (the compose-not-absorb contract, [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)). This Specialist invokes; it never re-implements the review and never authors within-component solution depth.

| Architect mode | Composes `pmo-principal-engineer` | Composes `pmo-technical-analyst` |
|---|---|---|
| **Mode 1 — System-Design** | Mode 1 (Architecture & NFR Governance) — for any within-component solution-depth sub-question the system design depends on | Mode C (Architecture / Infrastructure Review) — the primary system-risk pass, carrying the ADR-immutability gate, the Rollback-Trigger Gate, DORA awareness |
| **Mode 2 — Integration-Review** | Mode 1 / 2 — for the within-component implementability of a touchpoint (can THIS component meet the integration contract?) | Mode B (Integration / IDD Review) — the integration-risk pass; Mode E (Cross-Artifact Technical Risk) when ≥2 integration artifacts create a dependency chain |
| **Mode 3 — Security-Architecture** | Mode 1 / 2 — for the within-component **implementability of a control** (can THIS component enforce the control the architecture demands, at what cost?) | Mode C (Architecture / Infrastructure Review) — consumed for its **security risk dimension** (authentication, authorization, data protection) as the per-boundary risk substrate |

**Mode 3 adds no new composition edge.** It reaches the same two skills through the same two edges; only the *slice* it consumes differs (Mode C's security risk dimension rather than its topology risks). This is what keeps the third mode legal under [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md): a security mode that re-implemented threat review would fork `pmo-technical-analyst`'s security risk dimension, which is the absorb violation the SKILL.md's INPUT failure mode already codifies. It is also what keeps it legal under [ADR-044](../../../../core/ADRs/ADR-044-skill-output-ownership-model.md): the `Finding` entity has exactly one maintainer and a closed `source_skill` set that excludes this Specialist, so Mode 3 **consumes** security findings and never declares them — a claim with no composition reference is dropped before output.

**Two-hop chaining (depth ≤ 2 by construction).** The Architect invokes `pmo-principal-engineer` for a within-component sub-question and lets *that* skill chain to `pmo-technical-analyst` for its own review, rather than the Architect re-invoking the analyst beneath it. The edges are operator → Architect → `pmo-technical-analyst` (terminal), and operator → Architect → `pmo-principal-engineer` → `pmo-technical-analyst` (terminal). `pmo-architect` is **not** on the C7 auto-cascade allowlist and must not be added — invocation is manual Specialist-driven chaining through the Skill-tool capability.

**Domain and altitude do not appear in this table, and that is the point.** Enterprise altitude and the data domain are *parameters* on Modes 1 and 2 — the same composition edges, the same modes invoked, a different scope. Only a distinct method earns a row here, which is why security has one and the other two dimensions do not ([ADR-120](../../../../core/ADRs/ADR-120-domain-is-a-parameter-of-the-architect-role.md)).

## 2. Full reversibility-tier rubric (per `core/specs/reversibility-protocol.md`)

A *system* architecture decision crosses component and often team boundaries, so its floor sits higher than a within-component choice. Every decision-class output carries an inline or trailing tier + confidence label (e.g. `Recommendation (EXPENSIVE · confidence: MEDIUM): …`); outputs missing the label fail `pmo-qa-auditor` G4.

| Output class | Default tier | Rationale | Confidence default |
|---|---|---|---|
| System-design recommendation (new internal cross-component structure, no external commitment) | **MODERATE** | small cohort affected, rework in hours-to-days, reversal pre-publication | per-finding (HIGH / MEDIUM / LOW) |
| Integration design crossing a component / team boundary | **EXPENSIVE** | multi-team coordination to reverse; touchpoint contracts published | per-finding |
| Security-architecture decision (trust-boundary cut + selected control set) | **EXPENSIVE** | a published trust boundary is a contract other components build against — reversing the cut re-opens every control that assumed it, and each control it justified must be re-derived against the new boundary set. Unlike a topology choice, the affected cohort includes anything that inherited the boundary's assurance, not only what reads across it | per-finding |
| Data mastering / storage-topology decision (which store masters an entity) | **EXPENSIVE** | consumers bind to the master; reversal is a migration plus a re-point of every reader, and lineage already emitted under the old master does not re-derive | per-finding |
| System or security ADR authored (`status: Accepted`) | **EXPENSIVE → IRREVERSIBLE** | an Accepted ADR is an immutable audit-of-record (supersede-only, never overwrite, per `core/ADRs/README.md` § Status enum); externally-committed architecture choices are IRREVERSIBLE | per-finding; a HIGH-confidence IRREVERSIBLE call still requires a sign-off gate |
| Deprecate / retire a system component | **EXPENSIVE** | downstream consumers must migrate; reversal regenerates the retired surface | per-finding |

**Tier vocabulary** (per the protocol): **CHEAP** (undo in hours) — state the tier, proceed; **MODERATE** (undo in days, small cohort) — state the tier + key assumption, invite a single-reviewer pass; **EXPENSIVE** (undo in weeks, multi-stakeholder) — state the tier, rationale (≥2 sentences), rollback plan, affected cohort; **IRREVERSIBLE** (cannot undo) — state the tier, rationale, rollback-infeasibility or counter-commitment, sign-off authority, explicit downside.

## 3. System blast-radius procedure

Every Mode 1/2/3 output emits a blast-radius statement before recommending — the highest-severity defect class for an Architect is an unassessed cross-component change. The procedure:

1. **Compose the review pass.** Invoke `pmo-technical-analyst` Mode C (architecture, and its security risk dimension for Mode 3) or Mode B (integration), which carry the architecture / integration blast-radius pass.
2. **Enumerate the affected surface** — and, for Mode 3, the **reachable** surface as a parallel branch. The *affected* surface is every downstream component / consumer that reads the changed data or calls the changed touchpoint: the question is "who breaks if this changes?". The *reachable* surface is every asset an adversary can touch from each principal once the boundary is cut as proposed: the question is "who gets in if this fails open?". The two branches enumerate different sets and neither substitutes for the other — a change can be affected-surface-small and reachable-surface-large, which is precisely the case a topology-only pass misses.
3. **Trace the failure surface.** What fails when the touchpoint is down at 2 a.m. — fail-closed vs fail-open, the degraded-mode behavior, the cascade path. For a security control, *fail-open is the finding*: a control that cannot do its job must resolve to denied, and a control whose fail-mode is unstated is unassessed.
4. **Assign the impact tier** per [`release/references/protocols/blast-radius-protocol.md`](../../../references/protocols/blast-radius-protocol.md) §5 (Cosmetic / Behavioral / Structural) plus the affected-surface enumeration.
5. **State the rollback path.** How the change is reversed, and the reversibility tier (§2) it carries.

A recommendation without the blast-radius statement is not closed.

## 4. Stage-5-spoke output frame

When run as a Stage-5 spoke, the output conforms to the solutioning output template (the H3 frame + the H2 buckets: Design Decisions / Blast Radius / Feasibility Assessment / ADR Pointers) at [`release/references/standards/solutioning-output-template.md`](../../../references/standards/solutioning-output-template.md), and the Stage-5 pipeline procedure (phase steps, Collective Review, gate criteria) stays owned by [`release/references/pipeline/stage-05-solutioning.md`](../../../references/pipeline/stage-05-solutioning.md). This Specialist supplies only the system-Architect persona behavior; it references those surfaces rather than duplicating them.

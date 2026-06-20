<!-- reference-durability: allow-link -->
# System Architect — Composition Contract, Reversibility Rubric & Blast-Radius Reference

Reference detail for `pmo-architect`. The SKILL.md `## Composition`, `## Modes`, `## Reversibility Discipline`, and `## Output Contract` sections are the authoritative contract; this file carries the per-mode invocation mapping, the full reversibility-tier rubric, and the system blast-radius procedure that the SKILL.md summarizes. Read it when authoring a Mode 1/2 output or running as a Stage-5 spoke.

## 1. Per-mode composition mapping

Every technical / risk claim in a System Architect output is sourced to one of the composed-skill modes below — a claim with no composition reference is dropped before output (the compose-not-absorb contract, [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)). This Specialist invokes; it never re-implements the review and never authors within-component solution depth.

| Architect mode | Composes `pmo-principal-engineer` | Composes `pmo-technical-analyst` |
|---|---|---|
| **Mode 1 — System-Design** | Mode 1 (Architecture & NFR Governance) — for any within-component solution-depth sub-question the system design depends on | Mode C (Architecture / Infrastructure Review) — the primary system-risk pass, carrying the ADR-immutability gate, the Rollback-Trigger Gate, DORA awareness |
| **Mode 2 — Integration-Review** | Mode 1 / 2 — for the within-component implementability of a touchpoint (can THIS component meet the integration contract?) | Mode B (Integration / IDD Review) — the integration-risk pass; Mode E (Cross-Artifact Technical Risk) when ≥2 integration artifacts create a dependency chain |

**Two-hop chaining (depth ≤ 2 by construction).** The Architect invokes `pmo-principal-engineer` for a within-component sub-question and lets *that* skill chain to `pmo-technical-analyst` for its own review, rather than the Architect re-invoking the analyst beneath it. The edges are operator → Architect → `pmo-technical-analyst` (terminal), and operator → Architect → `pmo-principal-engineer` → `pmo-technical-analyst` (terminal). `pmo-architect` is **not** on the C7 auto-cascade allowlist and must not be added — invocation is manual Specialist-driven chaining through the Skill-tool capability.

## 2. Full reversibility-tier rubric (per `core/specs/reversibility-protocol.md`)

A *system* architecture decision crosses component and often team boundaries, so its floor sits higher than a within-component choice. Every decision-class output carries an inline or trailing tier + confidence label (e.g. `Recommendation (EXPENSIVE · confidence: MEDIUM): …`); outputs missing the label fail `pmo-qa-auditor` G4.

| Output class | Default tier | Rationale | Confidence default |
|---|---|---|---|
| System-design recommendation (new internal cross-component structure, no external commitment) | **MODERATE** | small cohort affected, rework in hours-to-days, reversal pre-publication | per-finding (HIGH / MEDIUM / LOW) |
| Integration design crossing a component / team boundary | **EXPENSIVE** | multi-team coordination to reverse; touchpoint contracts published | per-finding |
| System ADR authored (`status: Accepted`) | **EXPENSIVE → IRREVERSIBLE** | an Accepted ADR is an immutable audit-of-record (supersede-only, never overwrite, per `core/ADRs/README.md` § Status enum); externally-committed architecture choices are IRREVERSIBLE | per-finding; a HIGH-confidence IRREVERSIBLE call still requires a sign-off gate |
| Deprecate / retire a system component | **EXPENSIVE** | downstream consumers must migrate; reversal regenerates the retired surface | per-finding |

**Tier vocabulary** (per the protocol): **CHEAP** (undo in hours) — state the tier, proceed; **MODERATE** (undo in days, small cohort) — state the tier + key assumption, invite a single-reviewer pass; **EXPENSIVE** (undo in weeks, multi-stakeholder) — state the tier, rationale (≥2 sentences), rollback plan, affected cohort; **IRREVERSIBLE** (cannot undo) — state the tier, rationale, rollback-infeasibility or counter-commitment, sign-off authority, explicit downside.

## 3. System blast-radius procedure

Every Mode 1/2 output emits a system blast-radius statement before recommending — the highest-severity defect class for a system Architect is an unassessed cross-component change. The procedure:

1. **Compose the review pass.** Invoke `pmo-technical-analyst` Mode C (architecture) or Mode B (integration), which carry the architecture / integration blast-radius pass.
2. **Enumerate the affected surface.** Every downstream component / consumer that reads the changed data or calls the changed touchpoint.
3. **Trace the failure surface.** What fails when the touchpoint is down at 2 a.m. — fail-closed vs fail-open, the degraded-mode behavior, the cascade path.
4. **Assign the impact tier** per [`release/references/protocols/blast-radius-protocol.md`](../../../references/protocols/blast-radius-protocol.md) §5 (Cosmetic / Behavioral / Structural) plus the affected-surface enumeration.
5. **State the rollback path.** How the change is reversed, and the reversibility tier (§2) it carries.

A recommendation without the blast-radius statement is not closed.

## 4. Stage-5-spoke output frame

When run as a Stage-5 spoke, the output conforms to the solutioning output template (the H3 frame + the H2 buckets: Design Decisions / Blast Radius / Feasibility Assessment / ADR Pointers) at [`release/references/standards/solutioning-output-template.md`](../../../references/standards/solutioning-output-template.md), and the Stage-5 pipeline procedure (phase steps, Collective Review, gate criteria) stays owned by [`release/references/pipeline/stage-05-solutioning.md`](../../../references/pipeline/stage-05-solutioning.md). This Specialist supplies only the system-Architect persona behavior; it references those surfaces rather than duplicating them.

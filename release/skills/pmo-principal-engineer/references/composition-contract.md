<!-- reference-durability: allow-link -->
# Principal Engineer — Composition Contract & Stage-5 Output Reference

Reference detail for `pmo-principal-engineer`. The SKILL.md `## Composition`, `## Modes`, and `## Output Contract` sections are the authoritative contract; this file carries the per-mode invocation mapping, the worked Stage-5-spoke output frame, and the RECONCILE subsumption ledger that the SKILL.md summarizes. Read it when authoring a Mode 1/2 output or running as a Stage-5 spoke.

## 1. Per-mode invocation mapping (composed `pmo-technical-analyst` modes)

Every technical/risk claim in a Principal Engineer output is sourced to one of these invoked modes — a claim with no composition reference is dropped before output (the compose-not-absorb contract, ADR-019). This Specialist invokes; it never re-implements the review.

| PE mode | Decision the PE adds (solution-design synthesis) | `pmo-technical-analyst` mode(s) invoked | Consumed from the composed mode |
|---|---|---|---|
| **Mode 1 — Architecture & NFR Governance** | Selects the within-component architecture; sets the binding NFR thresholds (quantitative values + rollback-trigger quantification); authors the ADR when non-obvious + cross-cutting. | **Mode C** (Architecture / Infrastructure Review) primary; **Mode A** (FDD Review) when the input is an FDD. | Risk matrix; FDD Quality Score (Mode A); ADR-immutability verdict; Rollback-Trigger Gate verdict; DORA-measurability flags (Mode C). |
| **Mode 2 — Build-vs-Buy & Design Review** | Renders the build-vs-buy verdict; builds the options / trade-off matrix; runs the design review on the surviving approach. | **Mode C** (each candidate's architecture risks); **Mode E** (Cross-Artifact Risk) for multi-artifact decisions; **Mode B** (Integration / IDD Review) when the decision turns on an integration surface. | Per-candidate risk reads; cross-artifact compound-risk patterns (Mode E); integration failure-mode coverage (Mode B). |

**Invocation mechanism.** Manual Specialist-driven Skill-tool invocation at cascade-depth 0→1 (operator → Principal Engineer → `pmo-technical-analyst`, terminal). NOT the C7 auto-cascade allowlist (comms-writer / delivery-engine / tracker-manager / artifact-generator) — that allowlist governs PPM-triggered Document-Tier-2 auto-writes and `pmo-technical-analyst` is not on it and is not added. Depth stays ≤ 2 by construction (the C1 bound: a target refuses invocation at depth ≥ 2).

## 2. RECONCILE subsumption ledger — who owns what (post-reconcile)

The Specialist **composes** `pmo-technical-analyst`; it does not subsume it. The split below records what each owns so the compose-not-absorb boundary is auditable. No edits to `pmo-technical-analyst` are made by this build — its hardening capabilities ship as-is and are inherited by invocation.

| Capability | Owner (post-reconcile) | Why |
|---|---|---|
| FDD-quality scoring (numeric rubric) | `pmo-technical-analyst` Mode A | Review-mechanic; the PE invokes it. |
| Integration / IDD failure-mode coverage | `pmo-technical-analyst` Mode B | Review-mechanic; the PE invokes it. |
| ADR-immutability enforcement at review time (reject in-place edit of an Accepted ADR) | `pmo-technical-analyst` Mode C | Review-time gate; the PE composes Mode C and inherits it. |
| Quantitative rollback-trigger validation | `pmo-technical-analyst` Modes A/C | Review-time gate; the PE invokes it. |
| DORA-metric measurability awareness | `pmo-technical-analyst` Mode C | Review-time awareness flag; the PE invokes it. |
| SIOR emission for CRITICAL/HIGH findings | `pmo-technical-analyst` | Finding-emission format; the PE consumes SIOR-formatted findings and routes them into its decision. |
| **ADR authoring** (the new monotonic `ADR-NNN`; the design decision it records) | **`pmo-principal-engineer`** (NEW) | `pmo-technical-analyst` enforces ADR *immutability* and reviews ADR *changes*; it does not author the design decision. |
| **NFR threshold-setting** (deciding the binding value) | **`pmo-principal-engineer`** (NEW) | `pmo-technical-analyst` drafts an NFR and flags absence; the PE decides the value as the design owner. |
| **Build-vs-buy adjudication + options/trade-off matrix** | **`pmo-principal-engineer`** (NEW) | No `pmo-technical-analyst` mode renders a build-vs-buy decision; this is Mode 2's distinctive value. |

**Subsumption statement (canonical):** `pmo-technical-analyst` owns technical *review* (FDD/integration/architecture review, FDD-quality scoring, ADR-immutability enforcement, rollback-trigger gating, DORA awareness, SIOR finding-emission). `pmo-principal-engineer` owns solution *design decisions* (architecture choice, NFR threshold-setting, build-vs-buy adjudication, ADR authoring) and *composes* `pmo-technical-analyst` for the review substrate. The PE does not subsume `pmo-technical-analyst`; it composes it (ADR-019).

## 3. Stage-5-spoke output frame

When the Principal Engineer runs as a Stage-5 Solutioning spoke, the output conforms to the solutioning output template (`release/references/standards/solutioning-output-template.md`) — this Specialist supplies the persona behavior, not the pipeline procedure (the phase steps, Collective Review, and gate criteria stay owned by `release/references/pipeline/stage-05-solutioning.md`). The template's H2 buckets map to PE output as:

| Template bucket | PE content |
|---|---|
| **Design Decisions** | The selected architecture + rationale; the binding NFR thresholds (with quantified rollback triggers); the build-vs-buy verdict with rejected-path costs. Each carries a reversibility tier + confidence. |
| **Blast Radius** | The downstream consumers / components each decision touches (composed from the `pmo-technical-analyst` review + the PE's own dependency trace). |
| **Feasibility Assessment** | The load-bearing risks carried from the composed review, in conditional form ("feasible IF …") where a dependency is unconfirmed. |
| **ADR Pointers** | The ADR authored (or a "no ADR — obvious/reversible" note), with the immutability discipline (supersede, never edit-in-place an Accepted ADR). |

## 4. Worked Mode 1 output (illustrative)

> **Audience:** technical. **Decision:** adopt write-through cache (approach B) for the reservation read-path.
> Per `pmo-technical-analyst` Mode C, the proposed write-behind cache (approach A) has no measurable rollback trigger and a 5xx-amplification risk on the warehouse-refresh path [SOURCE]. **Options:** (A) write-behind [cost: unmeasurable rollback, silent-staleness], (B) write-through [cost: +8ms p99 write latency], (C) no cache + read-replica [cost: replica lag, infra spend]. **Decision: B** — closes the silent-staleness path and makes the rollback trigger measurable.
> **NFR thresholds:** cache-staleness < 5s; rollback trigger = "revert to no-cache if stale-read rate > 1% sustained over 10 min" [ASSUMPTION – CONFIRM threshold with the platform lead].
> **Blast radius:** 2 downstream consumers of the reservation read event, both already tolerant of ≤5s staleness [SOURCE: `pmo-technical-analyst` Mode E].
> **Reversibility:** MODERATE · confidence: HIGH (undoable in days pre-Engineering; crosses to EXPENSIVE once built against).
> **ADR:** authored — `ADR-0NN` (cache-consistency strategy for the reservation read-path); non-obvious + cross-cutting → ratification is IRREVERSIBLE-as-audit-of-record.

This is illustrative — the values are not platform facts; it shows the required shape (audience-framing, every risk sourced to a composed mode, options + blast radius + reversibility on the decision, ADR pointer).

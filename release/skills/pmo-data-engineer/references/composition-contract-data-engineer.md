<!-- reference-durability: allow-link -->
# Data Engineer — Composition Contract, Boundary Ledger & Worked-Output Reference

Reference detail for `pmo-data-engineer`. The SKILL.md `## Composition`, `## Boundary`, `## Modes`, `## Output Contract`, and `## Reversibility Discipline` sections are the authoritative contract; this file carries the per-mode invocation mapping, the full boundary ledger against the three deconflicted peers, the per-output-class reversibility rubric the SKILL.md summarizes, and worked output frames for the two modes whose shape is easiest to get wrong. Read it when authoring a pipeline or data-quality output, or when the request brushes the architecture-decision surface.

## 1. Per-mode invocation mapping (composed function-skills)

Every upstream-contract, risk, or planning claim in a `pmo-data-engineer` output is sourced to one of these invoked modes — a claim with no composition reference is dropped before output (the compose-not-absorb contract, [ADR-019](../../../../core/ADRs/ADR-019-specialists-compose-not-absorb.md)). This Specialist invokes; it never re-implements.

| `pmo-data-engineer` mode | Synthesis the Specialist adds | Composed skill + mode invoked | Consumed from the composed mode | Autonomy tier of the action |
|---|---|---|---|---|
| **Mode 1 — Pipeline-Build** | The declared grain, the source-to-target mapping, the transformation, and the demonstrated idempotency property. | `pmo-technical-analyst` **Mode B** (Integration Spec / IDD Review); **Mode E** (Cross-Artifact Technical Risk Assessment) when the lineage chain spans ≥2 artifacts. `implementation-planner` when the change set warrants an RT-classified plan. | The upstream source's contract, availability, delivery/ordering guarantees, and failure modes; the RT-classified, sequenced, Edit-ready Implementation records. | **Tier 1 — Recommend** for the change set (operator approves before merge); **Tier 0** for any destructive backfill (see § 3). |
| **Mode 2 — Data-Quality** | The named invariant, the standing assertion suite, the reconciliation record and its business explanation, the residual-risk statement. | `pmo-technical-analyst` — **only** when a breach warrants a tracked `Finding`. | The composed skill's finding. This Specialist consumes it; it never creates one. | **Tier 1 — Recommend.** A breach diagnosis is a recommendation until the operator accepts the disposition. |
| **Mode 3 — Analytics-Enablement** | The serving grain, the conformed dimensions, the published contract, the assertion binding. | None additional — Mode 3 consumes Mode 1's build and Mode 2's assertions. | — | **Tier 1 — Recommend.** Publishing a contract other teams build against is EXPENSIVE (§ 3) and is operator-confirmed. |

**Invocation mechanism.** Explicit Specialist-driven Skill-tool invocation at cascade-depth 0→1, terminal on both edges. Neither `implementation-planner` nor `pmo-technical-analyst` is on the 4-skill C7 auto-cascade allowlist (comms-writer / delivery-engine / tracker-manager / artifact-generator), so both chains are always operator- or Specialist-explicit, never an automatic cascade.

**`pmo-software-engineer` is deliberately NOT invoked.** Chaining it would produce `operator → pmo-data-engineer → pmo-software-engineer → implementation-planner` — a **depth-3** chain breaching cascade rule **C1 (max depth 2)**, the bound that makes ADR-019's compose-not-absorb enforceable rather than aspirational. It would also compose the very peer this Specialist is boundary-tested against, re-colliding the boundary it exists to draw. The exclusion is a boundary statement, not an omission; do not "fix" it by adding the edge.

## 2. Boundary ledger — who owns what

The line that keeps `pmo-data-engineer`, `pmo-architect`, `pmo-software-engineer`, and `pmo-devops-sre` from cross-firing.

| Skill | Role | Owns | Does NOT own | Relationship to `pmo-data-engineer` |
|---|---|---|---|---|
| `pmo-architect` (data dimension) | role Specialist — design authority | Where an entity is mastered; how data flows across systems; the storage and lineage topology; the system ADR and its blast radius | The physical grain, the transformation, any assertion, any reconciliation — its traversal terminates in a topology and an impact bound, and reconciles no row | **Upstream sibling.** Renders the decision this Specialist builds against. Deconflicted on all three conjuncts: trigger surface (decision-shaped vs operation-shaped), write-scope (decision + blast radius vs pipeline + standing assertions), primary role (design authority vs hands-on build). The tokens *lineage* and *mastered* are ceded to it and appear in no trigger here. |
| **`pmo-data-engineer`** (this skill) | role Specialist — hands-on build | Ingestion and transformation; physical grain, keys, partitioning; standing data-quality assertions; source↔target reconciliation; idempotent backfill and replay; the curated serving dataset and its published refresh contract | The topology decision; the RT taxonomy and Edit-spec generation; `Finding` creation | — (this skill) |
| `pmo-software-engineer` | role Specialist — plan executor | Stage-6 execution of an **approved plan** → executed change, verification, PR, version-log entries | Anything arriving without a plan — a bare ask is out of contract at its own input gate | **Peer, disjoint by input contract.** Every data-engineering ask arrives bare, so the two trigger surfaces cannot both fire on one request. **Never composed — C1.** |
| `pmo-devops-sre` | role Specialist — deploy mechanics | The deploy pipeline, rollout configuration, reliability and rollback triggers | Data pipelines, transformation, data quality | **Peer, vocabulary-deconflicted.** *pipeline* is qualified `ingestion pipeline` in every trigger here and never used bare. |

**The temporal discriminator, stated precisely.** `pmo-software-engineer`'s accountability ends at the pull request: its verification evidence attests to one change and is never read again. This Specialist's primary deliverable — the assertion suite — **executes on every future run, indefinitely**. A skill whose main output outlives its own pull request is not writing into the executor's surface, and that difference is temporal rather than scoped, so no parameterization of the executor reaches it.

**Why this is not absorption (vs `implementation-planner`):** the planner produces RT-classified, Edit-ready specs and stops; it has no model of a grain, an assertion, or a reconciliation. This Specialist supplies exactly those and consumes the planner's output for the mechanical change set. The two are layered, not overlapping.

## 3. Per-output-class reversibility rubric

The SKILL.md `## Reversibility Discipline` states the tier vocabulary and the data-domain asymmetry. This is the per-output-class default it summarizes. Defaults, not verdicts — state the tier the specific case earns, and pair it with a confidence level.

| Output class | Default tier | Default confidence | Rationale |
|---|---|---|---|
| Unmerged transformation edit; draft assertion; mapping revised before any load | **CHEAP** | HIGH | Nothing has touched a populated target; discard costs the edit. |
| Merged pipeline change not yet run against production data | **MODERATE** | HIGH | Reversible by revert, but the merge is now on a shared branch other work builds on. |
| Reconciliation verdict circulated for review | **MODERATE** | MEDIUM | Confidence is MEDIUM by default because distinguishing a business difference from data loss depends on a source the reviewer may not share. |
| Assertion suite added to a running load | **MODERATE** | HIGH | Removing an assertion is cheap; the cost is the window in which it was failing loads. |
| **Grain change on a populated table** | **EXPENSIVE** | HIGH | Every stored aggregate and every downstream report built on the old grain is invalidated; the fix is a coordinated re-model plus a backfill. |
| **Published dataset contract other teams have built reports against** | **EXPENSIVE** | HIGH | Reversing it re-opens every downstream consumer. State the rollback plan and name the consumer cohort. |
| **Destructive backfill or truncate over source-of-record data with no recoverable source** | **IRREVERSIBLE** | — | There is no revert for deleted rows. Never self-authorized: surface a Decision Briefing carrying the IRREVERSIBLE tier, the blast radius **stated in rows**, and a rollback-infeasibility statement, and wait for operator sign-off. |

**Label format** (any accepted): inline `Recommendation (EXPENSIVE · confidence: HIGH): …`; trailing `… [MODERATE · confidence: HIGH]`; or a structured `Reversibility` column. Outputs missing a tier on a decision-class item fail `pmo-qa-auditor` G4.

## 4. Worked Mode 2 output (illustrative — a reconciliation with a residual difference)

> **Audience:** mixed. **Correctness call:** the nightly load is correct; the residual difference is a business truth, not data loss.
> **Grain:** one row per order line per load date. Uniqueness asserted on `(order_id, line_no, load_date)` — holds.
> **Reconciliation:** loaded 1,284,301 rows against 1,284,447 at source. The 146-row difference is orders cancelled after the extract watermark, traced row-for-row against the cancellation feed [SOURCE: cancellation feed, same window]. **Explained in full — no unattributed residual.**
> **Standing assertions bound to this table:** grain uniqueness; referential integrity on `customer_id`; completeness against source within the explained-cancellation tolerance; freshness bound 2 h (observed 41 min).
> **Residual data risk:** a cancellation arriving *before* the watermark but *after* the source system's own commit would be double-counted as a load gap. The assertion set cannot distinguish that case; it needs a source-side commit timestamp the feed does not currently carry `[ASSUMPTION – CONFIRM: the feed can expose it — proposed as the next change]`.
> **Reversibility:** MODERATE · confidence: HIGH — the assertion suite is live on a running load; removing it is cheap.

## 5. Worked Mode 1 output (illustrative — the handoff that must not be skipped)

> **Audience:** technical. **Grain declared:** one row per shipment line per status-change event.
> **Upstream contract** [SOURCE: `pmo-technical-analyst` Mode B, integration review]: at-least-once delivery, out-of-order arrival up to 6 h, no delete semantics — so the load is idempotent on `(line_id, event_ts)` and late arrivals merge rather than append.
> **Source-to-target mapping:** authored with per-column provenance; two derived columns name their derivation inline.
> **Idempotency:** demonstrated on partition `2026-07-14` — second run produced a byte-equivalent target. Backfill of an arbitrary partition is therefore safe **for this shape only**; re-demonstrate after any key change.
> **Failure posture:** a load that cannot resolve the natural key fails the run visibly; it does not land partial data.
> **Not done:** the pipeline is **not** complete. Handing the assertion set to Mode 2 — execution success is a property of the code, correctness is a property of the data.
> **Reversibility:** MODERATE · confidence: HIGH — merged, not yet run against production data.

These are illustrative — the values are not platform facts. They show the required shape: audience-framing, a declared grain on every pipeline claim, every correctness claim sourced to a named assertion or a stated reconciliation, every upstream-contract claim sourced to the composed review mode, and a reversibility tier + confidence on the decision-class item.

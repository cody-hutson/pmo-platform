---
title: Ticket-Architecture Reconciliation Discipline
type: discipline
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
composes_with: [discovery-discipline.md, decision-discipline.md, review-discipline-principles.md, reconcile-dont-annotate.md, ../../release/references/standards/triage-design-rereview.md]
consumers: "Stage 4 Planning spokes (Phase A0); Stage 5 Solutioning spokes (Phase 0.5); the planning-solutioning-handoff §3.2 structural-premise-review obligation; stage-05-solutioning §7.2 SR-G1"
---
<!-- reference-durability: allow-link -->
# Ticket-Architecture Reconciliation Discipline

**The pre-build step that reconciles a tracked ticket's premise against the live architecture BEFORE design begins** — so a ticket authored against an architecture that has since moved is caught at stage-entry, not built stale.

## § 1. Scope + relationship to the sibling disciplines

This is **NOT a new activity-class peer** to Discovery — Discovery already owns "before the artifact exists." It is the **ticket-vs-live-architecture specialization** of two existing mechanisms:

- **[discovery-discipline.md](discovery-discipline.md)** — its stage-entry premise-currency check. This discipline is Discovery narrowed to the specific question *"is this ticket's premise still valid against the dated live architecture?"*.
- **[decision-discipline.md](decision-discipline.md) § 2.1.1 Audit-Snapshot Reconciliation** — the decision-side twin (a stale point-in-time artifact at recommendation-render). This discipline is the ticket-side twin, fired at build-entry rather than at the recommendation point.

It is positioned exactly as [reconcile-dont-annotate.md](reconcile-dont-annotate.md) is positioned — a named specialization / sub-mechanism, not a peer activity-class. It **cites** its siblings; it restates none of them.

## § 2. When it fires (activity-entry)

Fires at **Stage 4 Planning entry (Phase A0 currency check)** and **Stage 5 Solutioning entry (Phase 0.5 re-review delta)** when BOTH hold:
1. a tracked ticket's build is about to begin, AND
2. the ticket names or touches **≥1 architecture surface** — an ADR, a governing discipline, a registry / ledger / charter, or a roadmap.

**Non-ceremony guard ([decision-discipline.md](decision-discipline.md) G2).** A ticket that touches no architecture surface, OR a ticket filed *after* the most recent merge to every surface it touches, **OMITS** the reconciliation output — omission is the correct signal, not a gap.

**Ticket-age-as-staleness-signal (the load-bearing heuristic).** A ticket filed *before* the most recent merge to `main` for a surface it touches is **unverified until reconciled**. The staleness signal is **ticket age relative to the architecture it touches** — not the digit-count in the ticket body (a renumbered `#NNNN` in a body is not staleness; a superseded structural premise is). Artifact age is a staleness *signal*, not a verdict — it triggers the reconciliation, which then renders the finding.

## § 3. The reconcile procedure (4 steps)

Each step names its output surface.

1. **Identify the architecture surfaces the ticket touches.** Enumerate the ADRs / disciplines / registries / ledgers / charters / roadmap entries the ticket's premise names or depends on.
2. **Compare ticket-filing-date vs each governing surface's date.** For each surface, compare the ticket's filing date against the surface's most-recent-merge / adoption date. A surface newer than the ticket is a reconciliation candidate.
3. **Reconcile stale citations/paths + bind the governing discipline + update the consistency surfaces (not just behavior).** Fix stale citations and paths; bind the current governing discipline; AND **update the ledger / registry / charter the ticket's premise would otherwise leave stale** — not only the behavior. Leaving the consistency surface stale while changing behavior is the recurring drift signature (a ledger row reading "no counterpart observed" when a counterpart now exists).
4. **Surface each reconciliation as an explicit decision.** Route each reconciliation as a D-class decision per [decision-discipline.md](decision-discipline.md), classified C1 (current) / C2 (candidate-for-amendment) / C3 (should-be-challenged) per [triage-design-rereview.md](../../release/references/standards/triage-design-rereview.md) § 3. A C3 premise fires **Tier 0 — Premise Rejection**.

## § 4. Output (where the reconciliation record lands)

The reconciliation record is a structured block in the Stage 4 sub-task comment (Phase A0) and/or the Stage 5 sub-task `### Output for Stage 6` (Phase 0.5) — a `#### Ticket-vs-Architecture Reconciliation` section listing, per touched surface:

`surface · ticket-filing-date vs surface-governing-date · finding {current | stale-citation | stale-premise} · reconciliation action · C-classification`

This is the exact location [`stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) §7.2 **SR-G1's Method column** cites as the reconciliation record it confirms. When the ticket touches no architecture surface, the block is omitted (the non-ceremony signal per § 2).

## § 5. Composition map (compose-not-duplicate)

| Sibling | Relationship |
|---|---|
| [discovery-discipline.md](discovery-discipline.md) § 3.1 stage-entry premise-currency | This discipline is its **ticket-vs-architecture specialization** (the general premise-currency activity narrowed to the ticket-vs-dated-architecture question). |
| [decision-discipline.md](decision-discipline.md) § 2.1.1 Audit-Snapshot Reconciliation | The **decision-side twin** (stale point-in-time artifact at recommendation-render); this is the **ticket-side** twin at build-entry. |
| [reconcile-dont-annotate.md](reconcile-dont-annotate.md) | The **edit-time twin** (reconcile-not-annotate when editing stale state); this fires **pre-build** rather than at edit-time. |
| [triage-design-rereview.md](../../release/references/standards/triage-design-rereview.md) § 3 / § 6 | The **C1/C2/C3 machinery** this discipline routes to — it delegates the currency-classification, does not re-implement it. |
| CLAUDE.md § Universal Preferences — *verify-before-recommend* | The **workspace-global posture** this discipline operationalizes at the pipeline surface. |
| [`planning-solutioning-handoff.md`](../standards/planning-solutioning-handoff.md#structural-premise-review-obligation) §3.2 + [`stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) §7.2 SR-G1 | This discipline is the **pre-build reconciliation method**; the §3.2 obligation + SR-G1 gate are the **exit-gate** that confirms it was done (entry-reconcile → exit-gate). |

## § 6. Domain-best-practice failure modes

**FM-1 — reconcile behavior, leave the consistency surface stale** · [PROC]
- *Signature:* behavior is reconciled to current architecture, but the ledger / registry / charter row the ticket's premise referenced is left un-updated (e.g., a ledger row reading "no counterpart observed" when one now exists).
- *Conditional:* do NOT close a reconciliation after changing behavior alone when the ticket's premise also referenced a consistency surface, because the stale surface silently re-introduces the drift the reconciliation was meant to remove.
- *Root cause:* [reconcile-partial pattern] → [step 3 read as behavior-only] → [observable: a consistency surface contradicts the reconciled behavior].
- *Mitigation:* procedure step 3 names "update the consistency surfaces, not just behavior" as an explicit sub-step; the reconciliation record (§4) lists the surface + its reconciliation action.
- *Principal-vs-junior:* a principal re-greps the surface the ticket's premise referenced after reconciling behavior; a junior stops at the behavior change.

**FM-2 — treat a DoR-ready ticket as authoritative, skip reconciliation** · [TRIG]
- *Signature:* the reconciliation is skipped because the ticket is DoR-ready / well-formed, without checking ticket-age vs the architecture it touches.
- *Conditional:* do NOT treat a ticket's DoR-readiness as evidence its structural premise is current, because DoR gates form/completeness, not currency-vs-live-architecture.
- *Root cause:* [DoR-conflated-with-currency pattern] → [readiness gate mistaken for a currency gate] → [observable: a stale-premise ticket sails through because it is well-formed].
- *Mitigation:* the § 2 fire-predicate is ticket-touches-a-surface AND age-relative-to-that-surface — independent of DoR state; the ticket-age heuristic is named as load-bearing.
- *Principal-vs-junior:* a principal checks the filing date against the surfaces the ticket touches even for a crisp ticket; a junior trusts the DoR label.

**FM-3 — "reconciled" recorded with no explicit decision / no C-classification** · [OUT]
- *Signature:* the reconciliation record says "reconciled ✓" with no D-class decision and no C1/C2/C3 classification.
- *Conditional:* do NOT record a reconciliation as complete without an explicit decision + C-classification, because an unclassified "reconciled" is reconciliation theater — indistinguishable from not having reconciled.
- *Root cause:* [presence-of-text-not-quality-of-decision pattern] → [the record checkable by a tick, not a classified decision] → [observable: `reconciled ✓` passes a naive check].
- *Mitigation:* procedure step 4 requires routing each reconciliation as a D-class decision with a C-classification; the §4 record schema has a `C-classification` field.
- *Principal-vs-junior:* a principal classifies each reconciliation (C1/C2/C3) and routes C3 to Tier 0; a junior writes "reconciled" and moves on.

## § 7. Applicability

This discipline governs every ticket entering Stage 4 Planning or Stage 5 Solutioning: when a tracked ticket touches an architecture surface (an ADR, a governing discipline, a registry / ledger / charter, or the roadmap), the reconciliation step fires at stage entry. It is a standing entry-gate obligation alongside the sibling design-stage disciplines — a discipline governs the work done after it exists, and needs no release-scoped rollout clause.

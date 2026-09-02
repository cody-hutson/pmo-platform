---
title: "ADR-093 — Scoped, conditional-binding acceptance-fit gate at Stage 2 with phased rollout"
status: Accepted
date: 2026-07-25
release: intake-and-gate-protocol-hardening (version bound at Stage 12)
deciders: "operator (plan approval / Stage 9 ratification gate) + Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + Phase A6.5 adversarial design reviewer"
tags: [release-ops, triage, acceptance-gate, provenance, architectural-fit, conditional-binding, shadow-rollout, ceremony-management, trust-boundary, defense-in-depth]
source_observations:
  - "The release pipeline's front door treated a well-formed intake issue as accept-by-default: Stage 2 Triage validated completeness, duplicates, dependency state, priority, sizing, and similarity, but no criterion asked whether an idea should be accepted at all given the existing architecture/governance/discipline network. An architecture evaluative-lens shipped after this gap was filed, but it is deliberately advisory (it informs the recommendation and adds no gate ID) — so a binding acceptance counterweight was still absent."
  - "The auto-logging rule requires agents to file an improvement/bug on every detected gap, with no acceptance counterweight keyed to provenance. Auto-logging plus accept-by-default is a backlog-bloat and architectural-drift vector where volume accrues authority simply by existing."
  - "Phase A6.5 adversarial review established that the provenance marker introduced here grants no privilege — its only consumer raises the acceptance bar — so the marker being body-spoofable is harmless, and the trust-before-provenance ordering with the sibling author-association work is defense-in-depth, not load-bearing. The load-bearing invariant is that trust is decided from the repository-relationship API field, never from the body or the marker."
---
<!-- reference-durability: allow-link -->

# ADR-093 — Scoped, conditional-binding acceptance-fit gate at Stage 2 with phased rollout

## Status

Accepted — ratified at the operator's Stage 9 plan-review gate for the intake-and-gate-protocol-hardening release.

**Stage-9 ratification recorded (2026-07-25):** at the v3.94 Stage 9 plan-review GO gate the operator ratified this decision AND exercised the Automation-posture lever straight to **enforce** (see Decision § 4) — G2-13 ships enforce from v3.94, not a shadow shakedown. Per the ADR ratification-flip convention (Stage-13 G-CL9), the `status:` enum remains **Proposed** until the release's Stage-13 Close flips it to Accepted; this note records the ratification event without pre-empting that flip.

## Context

Stage 2 Triage renders an Approve / Reject / Defer verdict after validating a well-formed issue against completeness, duplicates, dependency state, priority, sizing, and similarity. None of those criteria asked the prior question: **should this idea be accepted at all**, given the platform's existing architecture / governance / discipline network — does it *relate to and remain compatible with* a named existing anchor, or is it a free-floating suggestion that, if built, would erode safety / stability / scalability / maintainability?

An architecture **evaluative-lens** was later added at Stage 2, but it is **deliberately advisory** — it informs the triage recommendation, adds no gate ID, and never blocks. That advisory posture is a considered choice grounded in ceremony-management: a gate must fire only when fit is genuinely in question, because a blanket acceptance interrogation burns throughput and operator attention on every routine ticket.

The gap is acute for **agent-self-created intake**: the auto-logging rule requires agents to file on every detected gap, with no acceptance counterweight. **Auto-logging plus accept-by-default is a backlog-bloat and architectural-drift vector in which volume accrues authority simply by existing.** The design tension is therefore real and two-sided: a *binding* acceptance counterweight is wanted, but a *blanket* binding gate would violate the deliberate advisory choice and over-gate routine intake.

This decision also composes with a sibling change in the same release that extends the author-association trust boundary to issue-body ingestion, and with the Phase A6.5 adversarial review of the combined intake surface.

## Decision

1. **Add a gate-expressed criterion (G2-13) — scoped, conditional-binding.** Acceptance-fit is a gate criterion with an ID (evaluated every triage, surfaced in the summary, `deploy.sh --check`-visible), not a triage-doc-only statement that would go unenforced. When it fires, the **Approve** verdict requires a recorded `#### Acceptance-Fit` determination — `relates to {named anchor: an ADR · an initiative/epic · a governing standard · a named discipline} — compatible because {evidence}`. Absent a credible anchor, the expected disposition is **Reject or Defer**, and that Reject is a **first-class, expected outcome** for an anchor-less idea in the fire subset — not a triage failure.

2. **A two-limb conditional-fire predicate scopes it to where fit is genuinely in question.** G2-13 fires only when EITHER limb holds: **(a)** the issue is agent-authored (its body carries the machine-emitted provenance marker), OR **(b)** the architecture evaluative-lens flagged it as introducing/reshaping a component (net-new build or sweeping / cross-cutting change). When neither limb fires — a routine operator-authored, non-component-reshaping ticket — G2-13 **passes trivially**, and the ticket stays on the advisory lens path. The fire-predicate *is* the "fit genuinely in question" test that ceremony-management demands, which is precisely why a scoped gate does not violate the deliberate advisory choice.

3. **Consume the advisory lens; do not make it binding.** G2-13 reads the lens's net-new/sweeping classification as fire-limb (b) — it does **not** convert the lens itself into a gate. The lens stays advisory and untouched; the new teeth live in G2-13.

4. **Rollout — enforce from v3.94 (operator-ratified flip from the phased shadow → warn → enforce plan).** G2-13 was designed to ship **shadow / recommend** (determination surfaced advisorily; a missing block logs rather than blocks) and graduate to **enforce** (a missing determination blocks Approve when a limb fires) once the false-positive / throughput rate on the scoped subset was characterized — the criterion's **Automation posture being the single operator-ratification lever** (recommend → auto) at the Stage 9 Plan Review gate. **At the v3.94 Stage 9 plan-review GO gate (2026-07-25) the operator exercised that lever straight to enforce:** G2-13 **ships enforce from v3.94** (day-one gate-blocking on the fire subset), not a shadow shakedown. **Introducing-release-exempt:** v3.94 itself is not gated by G2-13 (reflexive-pipeline-loop discipline — the release shipping the criterion cannot fire its own gate); enforcement binds issues entering Stage 2 Triage strictly AFTER the v3.94 introducing-release merge SHA, with pre-cutover issues grandfathered. The shadow-rollout machinery this reused (the Stage-5 solutioning gate family) remained available as the fallback had the operator chosen a shakedown; day-one enforce was ratified given the criterion's structural (determination-present) check and MODERATE reversibility.

5. **Provenance marker — an acceptance-scrutiny signal, never a trust input (defense-in-depth).** The agent auto-intake path emits an HTML-comment provenance marker as the first body line of the issues it creates; it is invisible in render, grep-checkable, and reuses the established body-marker convention rather than minting a new label group. Its **only** consumer is G2-13, whose firing *raises* the acceptance bar — so a body-spoofed marker is harmless (it only self-imposes more scrutiny). The **load-bearing invariant** is stated explicitly and MUST be preserved by every future consumer: **trust is decided solely by the author-association boundary, from the repository-relationship API field, never from the issue body or from the marker.** The trust-before-provenance ordering with the sibling author-association work is therefore **defense-in-depth, not load-bearing** — the marker grants no privilege, so even if a reader consulted the marker before the trust check, nothing would be granted. No future edit may read "agent-authored" as "skip human review / auto-approve"; doing so would convert a spoofable marker into a privilege-escalation vector.

## Alternatives Considered

- **Blanket binding (every Approve requires a recorded anchor).** Rejected: it fires when fit is *not* in question, violating ceremony-management, and directly conflicts with the deliberate advisory-lens choice. Throughput cost is high and the reversibility of the throughput shock is EXPENSIVE.
- **Advisory-only (ship the provenance marker + reject-doctrine, leave acceptance advisory, no gate ID).** Rejected: it drops the binding intent entirely — the acceptance criterion would never be evaluated and the auto-log vector keeps its accept-by-default teeth-lessness.
- **Provenance as a new label group.** Rejected: a provenance/authorship label would be a net-new label-taxonomy group with its own pack row and label-parity gate — a blast radius disproportionate to the signal. The HTML-comment body marker reuses an existing convention with zero label-set growth.
- **Provenance as a template form-field.** Rejected: it would burden the human intake path (every human file picks provenance) while the agent path is programmatic; the marker must be machine-emitted on the agent path, not a human form choice.

## Consequences

- **(+)** Delivers the binding acceptance-fit intent **without** over-gating — the scoped predicate bites exactly the auto-log + net-new/sweeping vector and omits routine tickets.
- **(+)** **No new evaluator code:** the criterion is `validation` / `structural` / `auto`, so the stage-gate evaluator routes it by the existing `Check` column and the existing structural checker handles it.
- **(+)** **Low blast radius:** reuses the advisory lens's classification and the established body-marker seam; all edits are additive/in-place with no ID renumber, no verdict-enum change, no evaluator change.
- **(+)** Names **Reject as a first-class expected outcome** for anchor-less ideas, counterbalancing the auto-logging rule so volume does not accrue authority.
- **(−)** Requires an **emitter** — the auto-logging author (intake-desk Mode C) must emit the provenance marker; until an emitter exists the gate has no teeth on limb (a), so limb (a) is inert without it (limb (b), net-new/sweeping, still fires).
- **(−)** The **enforce** posture is a throughput step-change → **MODERATE** reversibility, which is why the shadow→enforce lever was operator-gated at Stage 9 rather than shipped hot; the operator ratified day-one enforce at the v3.94 Stage 9 GO gate (2026-07-25), accepting the step-change with the documented self-repair override path (and the introducing-release exemption keeping v3.94 itself unaffected).
- **Distinctness (no duplication):** acceptance-fit at Stage 2 asks *should we take this on at all* (verdict: accept / reject / defer); the Stage-5 structural gate asks *is the chosen structure right* (verdict: redesign-before-build); the extend-vs-build disposition asks *extend an existing surface before creating net-new*. A ticket rejected at acceptance never reaches the structural gate; a ticket accepted still faces it. Upstream vs downstream — no overlap.

## Reversibility

**MODERATE / Confidence HIGH.** The **enforce** posture is the MODERATE element — it changes triage throughput on the scoped subset — and was therefore held behind the operator-ratification lever (the Automation posture) at Stage 9. **The operator exercised that lever to day-one enforce at the v3.94 Stage 9 GO gate (2026-07-25)**, with a documented override path per the criterion's self-repair row. Reverting enforce → shadow is a CHEAP text-only change to the criterion's Automation posture (the fire predicate and determination format are unchanged), so the MODERATE tier reflects throughput impact, not rollback cost; the introducing-release exemption keeps v3.94 itself unaffected.

## Related ADRs

- [ADR-016 — intake front-door architectural boundary](../../core/ADRs/ADR-016-intake-front-door-architectural-boundary.md): intake elicits work-to-be-done and hands off owned assumptions; this decision extends that boundary to the *acceptance* decision ("must relate to existing architecture to be accepted").
- [ADR-062 — substrate-vs-canonical precedent](../../core/ADRs/ADR-062-substrate-vs-canonical-precedent.md): the issue body stays historical record; the corrected acceptance scope lives in the canonical spec, not an auto-amended body — consumed by this design's reconciliation posture.
- [ADR-076 — comment author-association trust boundary](ADR-076-comment-author-association-trust-boundary.md): the author-association trust anchor this decision composes with. ADR-076 gates the comment-I/O channel by repository relationship; the sibling issue-body trust extension applies the same anchor to issue-body ingestion, and this ADR's non-authorization invariant (trust is decided from the API field, never from the provenance marker) is the reason the trust-before-provenance ordering is defense-in-depth rather than load-bearing.

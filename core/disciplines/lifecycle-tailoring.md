---
title: Lifecycle Tailoring
purpose: Documents the platform's deliberate PMBOK-7 lifecycle tailoring — the two-layer split between the 3 top-level agent states (ACTIVE / CLOSING / CLOSED) that bound agent cadence and the granular per-project PROJECT.md phase timelines that govern operational reporting — and why this is more granular than, and a faithful tailoring of, the canonical 5-process-group model. Cites the five-function-spine process-group definitions rather than restating them.
applies_to: every project's lifecycle handling — the CLAUDE.md § Project Lifecycle agent-state model, each PROJECT.md "Phase Timeline", and any skill that branches on project state or reports against a phase
parallel_to:
  - five-function-spine-and-process-flows.md   # canonical 5-process-group definitions this doc CITES, not redefines (ADR-004)
  - context-lifecycle-model.md                 # the inbound-content state machine (a different lifecycle); sibling in the disciplines "Lifecycle, concurrency, & safety" group
source: tree-audit (2026-04-18) AUDIT_OPERATIONS.md §O7 — the tailoring rationale was undocumented, so auditors and new team members could not tell whether the 3-state + granular-phase split was intentional or accidental; grounded in PMBOK 7 §1.5 (tailoring is expected and should be documented for transparency and reuse)
type: discipline
reversibility: CHEAP
---
<!-- reference-durability: allow-link -->

# Lifecycle Tailoring

A PMBOK-7 tailoring record. It does not define a new state machine and it does not redefine the PMBOK process groups — those live in [`five-function-spine-and-process-flows.md`](five-function-spine-and-process-flows.md) (ADR-004) and are cited here. It documents *why* the platform runs a coarse 3-state agent lifecycle alongside fine-grained per-project phase timelines, so the deliberateness of that choice is legible to future auditors.

## What — two lifecycle layers

The platform tracks project lifecycle at two deliberately different granularities:

| Layer | Where it lives | Granularity | What it governs |
|---|---|---|---|
| **Agent-state lifecycle** | CLAUDE.md § Project Lifecycle | 3 states: `ACTIVE` / `CLOSING` / `CLOSED` | **Agent cadence and decision-branching** — full processing vs. reduced-cadence hypercare vs. read-only. |
| **Phase timeline** | each project's `PROJECT.md` "Phase Timeline" | Domain-specific (e.g. Development → UAT → Issue Resolution → Mock Go-Live → Training → Cutover → Hypercare) | **Operational reporting** — status narration, stakeholder communication, milestone framing. |

The agent-state layer is intentionally coarse; the phase-timeline layer is intentionally rich. They are not redundant — they answer different questions (*how should the agent behave?* vs. *where in delivery are we?*).

## Why — the 5-process-group model is too coarse for the agent-state layer alone

The canonical PMBOK 5-process-group model (Initiating / Planning / Executing / Monitoring & Controlling / Closing — defined in [`five-function-spine-and-process-flows.md`](five-function-spine-and-process-flows.md), ADR-004) is the right frame for the *pipeline*, but two pressures pull in opposite directions at the *project* level:

- **Reporting needs more granularity than 5 groups.** In ERP-implementation reality, UAT, Issue Resolution, Cutover, and Hypercare each carry distinct stakeholder expectations and status semantics. Collapsing them to a single "Executing" or "Closing" group would erase reporting signal the operator and stakeholders depend on. Hence the granular phase timeline.
- **Agent decision-branching needs *less* granularity.** An agent that branched its cadence across a dozen named phases would be brittle and over-specified. Three states (`ACTIVE` / `CLOSING` / `CLOSED`) bound the decision tree to the transitions that actually change agent behavior, while the phase timeline preserves operational granularity underneath.

This two-layer split *is* the tailoring: PMBOK-7 §1.5 states tailoring is expected and should be documented for transparency and reuse. This file is that documentation.

## Mapping — agent-states + representative phases → the 5 process groups

The table below maps the 3 agent-states and a **representative** ERP-implementation phase sequence onto the 5 PMBOK process groups. The process-group definitions are **cited** from [`five-function-spine-and-process-flows.md`](five-function-spine-and-process-flows.md) / [ADR-004](../ADRs/ADR-004-five-function-spine.md) — they are **not** restated here.

| Agent state | Representative phase-timeline phase(s) | PMBOK process group(s) — *defined in five-function-spine* |
|---|---|---|
| `ACTIVE` | Initiation / kickoff | Initiating |
| `ACTIVE` | Planning, Design | Planning |
| `ACTIVE` | Development, Cutover, Mock Go-Live | Executing |
| `ACTIVE` | UAT, Issue Resolution, Training | Monitoring & Controlling (with Executing overlap) |
| `CLOSING` | Hypercare, Transition, Knowledge Transfer | Monitoring & Controlling → Closing |
| `CLOSED` | Archived | Closing (complete) |

**Mapping note (representative, not exhaustive).** The phase column is *illustrative*, not a closed enumeration: phase timelines are project-specific and live in each `PROJECT.md`. A project with a different domain (or methodology) extends or substitutes its own phases; the mapping principle — coarse agent state over rich reporting phase, both projecting onto the same 5 groups — holds regardless. Authoring this column exhaustively was deliberately rejected to keep this K1 doc from drifting against per-project timelines.

## Applicability — when a different tailoring fits

The ERP-implementation tailoring above is the platform's default because its anchoring project is an ERP go-live. It is **not** universal. Worked alternative:

- **Research-PMO tailoring (discovery-weighted, no fixed go-live).** A research or discovery program has no single cutover event and no hypercare tail; its value accrues through iterative discovery, not a deployment milestone. Its phase timeline would weight Initiating/Planning-class discovery loops heavily and may carry *no* `CLOSING` hypercare phase at all — a project can move `ACTIVE → CLOSED` when the research question is answered. The agent-state layer is unchanged (the same 3 states bound cadence); only the phase-timeline projection differs. (The `Deep Research PMO` knowledge-base is cited here as grounding for the discovery-weighted shape, not as itself a documented tailoring.)

The rule: **keep the 3 agent states fixed; tailor the phase timeline to the delivery domain; document the tailoring here when it materially differs from the ERP default.**

## Related references
- [`five-function-spine-and-process-flows.md`](five-function-spine-and-process-flows.md) — canonical 5-process-group definitions (cited, not restated).
- [ADR-004](../ADRs/ADR-004-five-function-spine.md) — design rationale for the five-function spine.
- CLAUDE.md § Project Lifecycle — the 3 agent-state definitions (workspace-root governance file; tracked in-repo as [`../CLAUDE.md.template`](../CLAUDE.md.template) § Project Lifecycle).
- [`context-lifecycle-model.md`](context-lifecycle-model.md) — the inbound-content lifecycle (a distinct machine; sibling in the disciplines "Lifecycle, concurrency, & safety" group).

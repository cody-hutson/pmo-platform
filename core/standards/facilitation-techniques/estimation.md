---
title: Facilitation Techniques — Estimation Domain
purpose: The estimation lifecycle-domain file of the facilitation-techniques corpus. Carries the facilitation techniques an operator runs when a team sizes work — surfaced by delivery-engine Mode D (Sprint Planning) when an estimation activity is in scope. Cards conform to the 9-field schema defined in the corpus index (README.md).
type: standard
reversibility: CHEAP / Confidence HIGH
domain: facilitation
lifecycle_phase: estimation
framework_version_anchor: "v2.22"
consumers: "operations/skills/delivery-engine/SKILL.md Mode D (Sprint Planning) — the surfacing trigger consults this file's cards for the estimation domain"
owner: "Workspace owner ([OPERATOR_NAME])"
---
<!-- reference-durability: allow-version-ref -->

# Facilitation Techniques — Estimation Domain

Techniques for facilitating a team that is sizing work — assigning relative effort/complexity to backlog items so a forecast can be built. Each card conforms to the 9-field schema in [the corpus index](README.md). `delivery-engine` Mode D consults this file when a sprint-planning input involves an estimation activity, and surfaces at most one technique that fits the in-scope activity, the project methodology, and is not contraindicated — silent otherwise.

These techniques are the *facilitation* layer of estimation. They are distinct from, and compose with, the estimation *discipline* the consumer already enforces (Cone-of-Uncertainty range widths, focus-factor capacity, planning-horizon rules in `operations/skills/delivery-engine/references/estimation-standards.md`): the discipline governs how an estimate must be expressed and validated; these techniques govern how a group arrives at the estimate in the room.

## Planning Poker

| Field | Value |
|---|---|
| **name** | Planning Poker |
| **lifecycle_phase** | estimation |
| **methodology_compatibility** | Scrum / SAFe / any timeboxed iterative cadence. Not Waterfall (no relative-sizing ritual in a predictive lifecycle). |
| **what_it_is** | A consensus-based relative-estimation technique. Each estimator privately selects a card from a bounded scale (commonly a modified Fibonacci sequence — 1, 2, 3, 5, 8, 13, 20, …) representing the effort/complexity of a backlog item; all reveal simultaneously; divergence drives a short discussion that surfaces hidden assumptions; the round repeats until the group converges. |
| **when_to_use** | A whole-team relative sizing session on a refined backlog — sprint-planning or backlog-refinement estimation where the team estimates together and the *conversation surfaced by divergence* is itself the value (it exposes differing readings of scope/risk before commitment). Best when items are comparably sized and the team has shared context. |
| **when_NOT_to_use** | Do NOT surface on a 1–2-person team (no divergence to discuss — the ritual is pure overhead); when items are too large/unrefined to size (split them first — sizing an epic produces noise); when a hard estimate-by date forces a single fast pass (use a quicker batch technique like affinity sizing); or when the team has no shared product context yet (estimates would be guesses dressed as consensus). |
| **participants_time_materials** | *Who:* the whole delivery team (the people who will do the work) + a facilitator; a product owner available for scope questions. *Typical duration:* ~1–2 minutes per item once warmed up; a refinement session of 10–15 items runs ~30–45 minutes. *Materials:* a card deck (physical Fibonacci cards or any synchronous planning-poker tool), the refined backlog items visible to all. |
| **steps_or_source_pointer** | Canonical source — Mike Cohn, *Agile Estimating and Planning* (Prentice Hall, 2005), ch. 6 ("Estimating in Story Points") and the Planning Poker treatment therein. Steps are not re-derived here (anti-maintenance-debt): the technique is well-documented and stable in its canonical source. |
| **evidence_tier** | `established` — a canonical, widely-adopted Agile estimation technique with a stable primary source. |

## Relative / Affinity Sizing

| Field | Value |
|---|---|
| **name** | Relative / Affinity Sizing |
| **lifecycle_phase** | estimation |
| **methodology_compatibility** | Scrum / Kanban / SAFe / any iterative cadence. Not Waterfall. |
| **what_it_is** | A fast batch relative-estimation technique. Items are physically (or virtually) grouped by similarity of size — estimators silently place items relative to one another on a spectrum (or into t-shirt-size buckets: XS / S / M / L / XL), then the group discusses only the outliers and the boundaries. Converts a long one-by-one estimation queue into a single rapid pass. |
| **when_to_use** | A large backlog needs a first-pass relative sizing quickly (dozens of items where item-by-item Planning Poker would be too slow); an initial release/PI sizing where coarse magnitude (not precision) is the goal; or when establishing the relative baseline that a later Planning Poker pass refines. |
| **when_NOT_to_use** | Do NOT use when a *precise* per-item estimate is required for commitment (affinity sizing is deliberately coarse — refine the committed slice with Planning Poker); when the team lacks a shared size-reference anchor (calibrate on 1–2 reference items first); or for a handful of items where the batch overhead exceeds the benefit (just size them directly). |
| **participants_time_materials** | *Who:* the delivery team + a facilitator. *Typical duration:* ~30–60 minutes for a backlog of 30–60 items (far faster per-item than Planning Poker). *Materials:* a wall/board (physical sticky notes) or a virtual board with a size spectrum or t-shirt-size columns; the backlog items as movable cards. |
| **steps_or_source_pointer** | Canonical source — Mike Cohn, *Agile Estimating and Planning* (Prentice Hall, 2005) (relative/affinity estimation and the t-shirt-sizing magnitude approach). Steps not re-derived (anti-maintenance-debt). |
| **evidence_tier** | `established` — a canonical, widely-adopted relative-estimation technique. |

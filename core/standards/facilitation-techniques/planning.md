---
title: Facilitation Techniques — Planning Domain
purpose: The planning (iteration/release) lifecycle-domain file of the facilitation-techniques corpus. Carries the facilitation techniques an operator runs when a team plans an iteration or release — setting the iteration goal and cutting scope to capacity — surfaced by delivery-engine Mode D (Sprint Planning) when an iteration/release-planning activity is in scope. Cards conform to the 9-field schema defined in the corpus index (README.md).
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
domain: facilitation
lifecycle_phase: planning
consumers: "operations/skills/delivery-engine/SKILL.md Mode D (Sprint Planning) — the surfacing trigger consults this file's cards for the iteration/release-planning activity, distinct from the estimation activity that consults estimation.md"
owner: "Workspace owner ([OPERATOR_NAME])"
---
<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-link -->

# Facilitation Techniques — Planning Domain

Techniques for facilitating a team that is planning an iteration or release — arriving at a committed goal and cutting scope to fit capacity. Each card conforms to the 9-field schema in [the corpus index](README.md). `delivery-engine` Mode D consults this file when a planning input involves an **iteration/release-planning activity**, and surfaces at most one technique that fits the in-scope activity, the project methodology, and is not contraindicated — silent otherwise.

**Activity boundary (this file vs. its neighbors).** This is the *goal-setting and scope-cut facilitation* layer of planning, and it is deliberately distinct from two adjacent layers Mode D already handles:
- It is **not** the *estimation* (sizing) layer. The facilitation techniques for sizing work live in [`estimation.md`](estimation.md) and surface under the estimation activity. A *planning* activity sets the iteration goal and decides what is in/out at the chosen capacity; an *estimation* activity sizes items so that capacity question can be answered. Both can co-occur in one sprint-planning session, but they are separate activities — Mode D surfaces at most one estimation card AND at most one planning card, each gated independently.
- It is **not** the *Cost-of-Delay / tech-debt ranking* lens. Mode D already owns value/CoD ranking for the tech-debt slice (`references/tech-debt-classification.md`). MoSCoW below is a planning-time *scope-bucketing* technique, not a value-ranking method — the card states that boundary so the two do not overlap.

## Sprint / Iteration Goal-Setting (goal-first planning)

| Field | Value |
|---|---|
| **name** | Sprint / Iteration Goal-Setting (goal-first planning) |
| **lifecycle_phase** | planning |
| **methodology_compatibility** | Scrum / SAFe / any timeboxed iteration. The Sprint Goal is a first-class Scrum artifact and generalizes to any timeboxed cadence with a single iteration objective. Not Waterfall (a predictive phase has a milestone scope, not a team-committed iteration goal). |
| **what_it_is** | A goal-first facilitation of iteration planning. Before the team fills the iteration with scope, the facilitator drives the team to articulate **one** coherent objective for the iteration — the single sentence that says why this iteration is worth running and what "done well" means — and then scope is selected *in service of that goal* rather than as an unordered pull from the top of the backlog. The goal becomes the commitment anchor and the in-iteration decision filter (when a trade-off arises mid-iteration, the goal decides it). |
| **when_to_use** | An iteration-planning session where the team needs to **commit to a coherent objective**, not just assemble a scope list — especially when recent iterations have been a grab-bag of unrelated items with no through-line, or when a stakeholder needs a one-line statement of what the iteration will deliver. Surface when the planning activity is in scope and a goal has not yet been set or is being set. |
| **when_NOT_to_use** | Do NOT surface for a pure capacity-rebalance where the goal is already fixed and unchanged — re-deriving a goal the team already holds is wasted ceremony. Do NOT use to force a single goal onto an iteration that is legitimately maintenance/keep-the-lights-on with no single theme (a contrived goal is worse than an honest "this is a stabilization iteration"). Do NOT use as a substitute for scope-cutting when the real problem is over-capacity — a goal does not resolve a plan that does not fit; pair it with a scope-cut technique. |
| **participants_time_materials** | *Who:* the whole delivery team (who commit to the goal) + a facilitator; the product owner present to confirm the goal reflects the right priority. The team commits; the facilitator facilitates. *Typical duration:* ~10–20 minutes at the front of an iteration-planning session, before scope selection. *Materials:* a visible place to record the goal (the board, the iteration record) so it stays present through planning and the iteration. |
| **steps_or_source_pointer** | Canonical source — Ken Schwaber & Jeff Sutherland, *The Scrum Guide* (2020), the Sprint Goal as the single objective for the Sprint; cross-ref Mike Cohn, *Agile Estimating and Planning* (Prentice Hall, 2005), the iteration- and release-planning chapters. Steps not re-derived (anti-maintenance-debt): goal-first planning is well-documented and stable in its canonical sources. |
| **evidence_tier** | `established` — a canonical practice anchored in the Scrum Guide with a stable primary source. |

## MoSCoW (Must / Should / Could / Won't) scope prioritization

| Field | Value |
|---|---|
| **name** | MoSCoW (Must / Should / Could / Won't-this-time) scope prioritization |
| **lifecycle_phase** | planning |
| **methodology_compatibility** | Scrum / Kanban / SAFe / Waterfall. Scope-bucketing is methodology-neutral — it partitions a candidate set into priority bands regardless of whether the container is a sprint, a release, or a predictive phase. |
| **what_it_is** | A planning-time scope-prioritization technique. Candidate items are sorted into four bands — **Must** (without these the iteration/release fails its purpose), **Should** (important but the plan survives a deferral), **Could** (desirable if capacity allows), **Won't-this-time** (explicitly out of scope for this round, recorded so it is a decision, not an omission). The explicit Won't band is the discipline's point: it makes the cut a stated, visible decision rather than a silent drop, and it gives stakeholders a clear in/out picture against capacity. |
| **when_to_use** | A planning session where a candidate scope **exceeds capacity** and the team must decide what is in and what is out for this iteration/release — MoSCoW gives a shared, four-band vocabulary for that cut and a place (the Won't band) to record deferrals as decisions. Strong fit for a stakeholder-facing scope conversation where "what's in vs. out, and why" must be legible. Directly feeds Mode D's reduced-scope option path (the "Option B: Reduced scope" route). |
| **when_NOT_to_use** | Do NOT surface when the backlog is **already force-ranked by a single ordered priority** — MoSCoW re-buckets work that an ordered rank already settled, adding ceremony with no gain (just take the top items that fit capacity). Do NOT use it as a **value / Cost-of-Delay ranking** — that is the tech-debt CoD lens Mode D already owns (`references/tech-debt-classification.md`); MoSCoW buckets by must-have-ness, not by economic value, and conflating the two double-counts the prioritization. Do NOT use when capacity comfortably exceeds the candidate scope (there is nothing to cut — the bands are theater). |
| **participants_time_materials** | *Who:* the delivery team + a facilitator + the product owner / stakeholder who owns the priority call (the Must/Won't line is a business decision, not a team-only one). *Typical duration:* ~20–40 minutes for an iteration's candidate scope, longer for a release-level set. *Materials:* four labeled bands (Must / Should / Could / Won't-this-time) on a physical or virtual board, the candidate items as movable cards, and the team's capacity figure visible so the cut is made against a real ceiling. |
| **steps_or_source_pointer** | Canonical source — DSDM Consortium, the MoSCoW prioritization technique (the canonical primary source; widely adopted across Agile and predictive delivery). Steps not re-derived (anti-maintenance-debt): the four-band method is well-documented and stable. |
| **evidence_tier** | `established` — a canonical, widely-adopted scope-prioritization technique with a stable primary source. |

## Provenance

Seeded in the v2.33 release as part of the Activity-Techniques Library increment that ships the Retrospective and Planning facilitation domains. The remaining lifecycle domains are deferred per the corpus index domain manifest; the tracking story for the remaining-domains decompose is recorded in the corpus index References block.

---
title: Facilitation-Techniques Corpus — Index
purpose: A K1 universal corpus of delivery-lifecycle facilitation techniques — one card per technique, organized by lifecycle domain — for in-execution surfacing by a delivery skill at recommendation time. This index defines the corpus purpose, the per-entry schema, the refresh protocol, the boundary against the intake-elicitation peer library, and the domain manifest.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
domain: facilitation
framework_version_anchor: "v2.22"
consumers: "operations/skills/delivery-engine/SKILL.md Mode D (Sprint Planning — estimation surfacing) and Mode E (Execution Control — retro/standup context hook); core/specs/framework-catalog.md (the facilitation-techniques-corpus INTERNAL row drives the refresh cadence)"
owner: "Workspace owner ([OPERATOR_NAME])"
---
<!-- reference-durability: allow-version-ref -->

# Facilitation-Techniques Corpus

A K1 reference corpus of **delivery-lifecycle facilitation techniques** — the named techniques an operator runs with real people in a live room across the delivery lifecycle (estimation, retrospective, planning, stand-up, prioritization, and the rest). Each technique is a card conforming to the 9-field schema below. Cards are organized into one markdown file per lifecycle domain (`estimation.md`, `retrospective.md`, …); this `README.md` is the registry index and the stable citation target.

This corpus is **not** new machinery: its directory shape borrows from the `core/standards/domain-best-practices/` precedent (an index posture + per-domain files under `standards/`), its per-card schema generalizes the proven shape of the `operations/skills/intake-desk/references/technique-library.md` cards, and its refresh protocol registers as one row in `core/specs/framework-catalog.md` exactly as every other named standard does.

## What this corpus is for

A delivery skill consults this corpus at recommendation time. When a facilitation-shaped activity is in scope (a sprint-planning estimation session, a retrospective, a stand-up), the consuming skill matches the in-scope activity to a technique's `when_to_use`, checks the technique fits the project's methodology and is not contraindicated, and surfaces **one** suggestion in-context. The corpus is **silent by default** — a technique is suggested only when it genuinely fits; it is never a technique dump. This is the anti-over-suggestion discipline the `when_NOT_to_use` field exists to enforce.

The corpus is **methodology-agnostic**: each card declares its `methodology_compatibility` so the consumer can filter to techniques that fit the project's `delivery_approach` (Planning Poker fits Scrum/SAFe/any timeboxed cadence; it does not fit Waterfall).

## Per-entry schema (9 fields)

Every technique card carries all nine fields. Each field is load-bearing — a card missing any field is non-conforming.

| # | Field | Type | What it carries |
|---|---|---|---|
| 1 | `name` | string | Canonical technique name (e.g., "Planning Poker"). Identity + citation anchor. |
| 2 | `lifecycle_phase` | enum (the domain set: estimation / retrospective / planning / requirements / story-writing / standup / decision / discovery / prioritization / conflict-alignment) | The surfacing trigger keys off this — the consumer matches the in-scope activity to this field. Without it, no in-context surfacing is possible. |
| 3 | `methodology_compatibility` | string (Scrum / Kanban / SAFe / Waterfall / any) | Lets the trigger filter to techniques that fit the project's `delivery_approach`. Composes with the `methodology-archetype-matrix.md` enum. |
| 4 | `what_it_is` | prose (1–3 sentences) | The technique definition. |
| 5 | `when_to_use` | prose / bullet | The positive surfacing condition — the activity signal that makes this technique a fit. |
| 6 | `when_NOT_to_use` | prose / bullet | The anti-over-suggestion field. The contraindication the consumer reads to STAY SILENT (e.g., Planning Poker on a 2-person team is noise). This is what distinguishes a principal catalog from a technique dump. |
| 7 | `participants_time_materials` | structured (who / typical duration / what's needed) | Operator-facing practicality — a technique the operator can't staff or time-box is not actionable. |
| 8 | `steps_or_source_pointer` | steps list OR canonical-source pointer | Well-documented techniques carry a canonical-source pointer (rather than re-deriving steps the platform would have to maintain); novel/platform-specific techniques carry inline steps. Anti-maintenance-debt. |
| 9 | `evidence_tier` | enum (`established` / `emerging` / `experimental`) | The corpus's own per-entry efficacy/maturity signal — feeds the refresh protocol's efficacy trigger (RP-T2 below). An `experimental` card refreshes faster than an `established` one. |

**Owner:** the corpus has a single owner — the workspace owner ([OPERATOR_NAME]) — recorded once here, not per card.

## Boundary against the intake-elicitation peer library

This corpus and `operations/skills/intake-desk/references/technique-library.md` are **peers, not overlaps**, partitioned by lifecycle anchor. There is **zero card overlap** between them, and neither duplicates the other's cards.

| | `intake-desk/references/technique-library.md` (peer) | `core/standards/facilitation-techniques/` (this corpus) |
|---|---|---|
| **Domain** | Requirements **elicitation** at intake | Delivery-lifecycle **facilitation** in-execution |
| **Source body** | IIBA BABOK Guide v3 (Interviews, Laddering, Document Analysis, Workshops, Observation) | Agile/lean facilitation practice (Planning Poker, relative sizing, 4Ls, prime directive, MoSCoW, lean coffee, …) |
| **Context** | Single-user, async, agent-mediated (one user, no live room) | Multi-person, live room — the operator facilitating real people |
| **Lifecycle anchor** | Activity-**entry** (turning an idea into a typed work item) | Activity-**execution** (running estimation/retro/planning sessions) |
| **Consumer** | `intake-desk` (elicitation loop) | `delivery-engine` (Mode D/E) |

The peer library carries elicitation cards only — interview, laddering, document analysis, and their kin — and contains zero lifecycle-facilitation techniques. The two libraries grow independently; a technique belongs to exactly one of them per its lifecycle anchor. When adding a card here, confirm it is delivery-facilitation (live room, in-execution), not intake-elicitation — if it is the latter, it belongs in the peer.

## Refresh protocol

The corpus is registered as one INTERNAL row in `core/specs/framework-catalog.md`:

- `framework`: `facilitation-techniques-corpus`
- `tier`: `emerging` → `review_cadence`: `continuous` (an INTERNAL standard in its first releases of life)
- `canonical_doc`: this `README.md`

`continuous` cadence means: review every release that touches the consuming surface (`delivery-engine`). The corpus refreshes on any of these explicit triggers:

- **RP-T1 — New consumer / new domain (structural):** a new per-domain card adds a domain file, OR a second skill begins consuming the corpus → re-review the index, the schema's continued fit, and the new domain's `evidence_tier` assignments at that change's Stage 5.
- **RP-T2 — Efficacy signal (outcome):** an `experimental`/`emerging`-tier entry has been surfaced by the consumer across ≥2 releases with no operator adoption/feedback, OR an entry's underlying technique is superseded in its canonical source → re-tier or retire the entry. (The per-card `evidence_tier` field is the per-entry input.)
- **RP-T3 — Cadence aging (informational):** the framework-catalog drift check surfaces the row when `next_review_due ≤ today` (n/a while the tier is `emerging`/`continuous`, but the row enters scope the moment it graduates `emerging → evolving`).

## Domain manifest

One file per lifecycle domain. The corpus seeds its first domain with a real consumer; the remaining domains are deferred per the foundation-increment scope.

| Domain | File | Status | Consumer surface |
|---|---|---|---|
| **Estimation** | `estimation.md` | SEEDED (this release) | `delivery-engine` Mode D (Sprint Planning) |
| **Retrospective** | `retrospective.md` | SEEDED (v2.33) | `delivery-engine` Mode E (retro context) |
| **Planning (iteration/release)** | `planning.md` | SEEDED (v2.33) | `delivery-engine` Mode D |
| Requirements (facilitated) | `requirements.md` | DEFERRED | `pmo-process-designer` / `pmo-business-analyst` |
| User-story writing | `story-writing.md` | DEFERRED | `delivery-engine` Mode C (DoR) |
| Stand-up | `standup.md` | DEFERRED | `delivery-engine` Mode E |
| Decision-making | `decision.md` | DEFERRED | `comms-writer` / `ppm-agent` |
| Discovery | `discovery.md` | DEFERRED | discovery-discipline consumers |
| Prioritization | `prioritization.md` | DEFERRED | `delivery-engine` / `ppm-agent` |
| Conflict/alignment | `conflict-alignment.md` | DEFERRED | `comms-writer` / `pmo-scrum-master` |

**Deferred-domain discipline (anti-maintenance-debt):** a domain is seeded only when a consuming skill cites it — never speculatively. Each deferred domain is a separate follow-on card; each seeds its domain *with* its consumer and runs its own Stage 5 to wire its surfacing trigger. An unseeded domain is not debt — it is deferred scope. The deferred cards file under the KA-Reference epic (see the References block).

## References

This index references the following work items by number; each is summarized inline above so the meaning survives renumbering.

- **#56** — the foundation increment that established this corpus (schema + first domain + one surfacing consumer + refresh protocol + this boundary statement).
- **#1173** — `[Epic] KA-Reference`, the home for the deferred per-domain facilitation cards.

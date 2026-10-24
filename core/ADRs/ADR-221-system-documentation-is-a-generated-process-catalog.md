---
title: "ADR-221 — A repository's system documentation is one generated catalog of process pages, written as text, placed outside the durable-corpus paths"
status: Accepted — operator-ratified at the process-baseline planning gate, 2026-10-23; numbered and landed through the release pipeline
date: 2026-10-22
release: documentation-model-adopted
deciders: "Process-baseline lead session; operator ratification"
tags: [architecture, documentation, system-documentation, process-map, catalog]
source_observations:
  - "Phase 1 Discovery records of the process-baseline effort (inventory of 2,516 elements; event, GitHub and transcript mining; 451 classified controls; refuter sample of 71 claims)"
supersedes: none
---

# ADR-221 — A repository's system documentation is one generated catalog of process pages, written as text, placed outside the durable-corpus paths

## Status

Accepted by the operator at the process-baseline planning gate (2026-10-23); it lands as a tracked ADR through the release pipeline, numbered by adr-helper. Answers the documentation-model spike: D1 the model, D2 the written-to-visual rule, D6 the minimal
set — plus the placement, identity, lifecycle and generation questions the process baseline surfaced. It is an
EXPENSIVE scope-lock: every page, check and view is shaped by it.

## Context

- When the documentation-model spike was filed, design knowledge was scattered across 40 declared design artifacts,
  mostly tables, each inside the document it explained; there was no catalog, no parent and sub-flow structure, and
  one human-process flow.
- A hand-kept index over embedded artifacts was rejected once already, because a section added without an index entry
  silently goes missing (ADR-089). Any catalog must be generated.
- The reference-durability detector bans Markdown link sequences in the durable-corpus paths (rules, standards, specs,
  disciplines, schemas, release references and governance, skill files). A navigable process graph needs links on
  every page.
- Phase 1 proved the shape on real data: three universes and fifteen value streams, approved by the operator; a page
  schema read through the platform's shared frontmatter reader; a validator that runs the platform's own frontmatter
  and link gates; seed-yield measurements per source class (workflows and hooks seed fully; skills mostly; stage
  specs partly).
- The Stage 7 pilot (eight pages, 53 steps) passed the validator cleanly; after one correction round an independent
  refuter's 83 checks read 72 hold, 10 partly, 0 fail, 1 cannot be settled. Its errors were systematic — numbers copied
  instead of computed, actors and classes borrowed from the nearest mechanism, summaries not derived from their own
  tables — and each is now a checkable rule (decision 12). Stage 7's steps came 24 from the spec's structure, 22 from
  its prose and 7 from other evidence. Four of eight pages read cleanly to a newcomer; the other four leave platform
  terms unexplained, which decision 12 also addresses.

## Decision

1. **D1 — Model: a generated catalog over text pages.** One Markdown page per node at L0–L3 (universe, value stream,
   sub-process, activity); L4 steps are rows in their activity's page; L5 detail is linked, never restated. The index,
   the graph (`graph.json`) and every cross-cutting view (structure, data flow, state and lifecycle, controls,
   interfaces, jobs) are **generated** from page frontmatter and the element inventory — never hand-maintained.
2. **D2 — Written-to-visual rule: visuals are text in the same page.** Each page's flow is a Mermaid block written as
   text beside the prose it depicts, so the page is the single source and the visual matches by construction. No
   separately drawn diagrams; no proprietary tools as a source.
3. **D6 — Minimal set: one page per node, plus generated views.** A node earns a page only by passing its level's
   decision test; a page orients and links, never restating a SKILL.md, spec or standard. The reader map decides entry
   points: one root pointer, an index under 4,000 tokens, pages under their level's token budget. This is the
   design-axis × reader grid with the orient-and-link filter the operator endorsed on the spike card, made concrete:
   the process-flow axis is the pages; the structure, data and behaviour-over-time axes are the generated views; the
   readers (operator, agent planning a change, small-context local model, adopter) are the reader map's entry points.
4. **Placement:** a new folder under `core/` that is **outside** the durable-corpus path set — so links are allowed —
   and **inside** the depersonalization gate's scope. The folder joins the shared link-check scope list.
5. **Identity:** stable kebab-case IDs, minted centrally, never positional; the filename is the ID; a step is addressed
   as `<activity-id>#<step-slug>`.
6. **Lifecycle:** the platform-doc `status` field (DRAFT, ACTIVE, SUPERSEDED, DEPRECATED) is the page lifecycle; no new
   state names. Stale is derived — a depicted file changed after `last_verified_commit` — and never stored.
7. **Generation boundary:** L0–L2 are written; L3 is seeded from source where the source class allows and corrected by
   hand; L4 rows are generated and reviewed. Every page links to the source it summarizes.
8. **Reciprocal links:** the design-artifact standard's rule that each depicted source links back to its artifact is
   replaced, for process pages, by the generated graph's inbound index. Sources are not edited to point at pages.
9. **Frontmatter lists are inline** (`[a, b]`), because the shared reader returns block-form lists empty.
10. **Generated output is committed** so GitHub renders it and any agent reads it with plain file reads; a CI step
    regenerates and diffs to catch drift.
11. **The control layer** (hooks, permission rules, CI gates) is a generated view and a column on every page, not a
    value stream.
12. **Authoring rules the validator enforces** (from the pilot): every executed number cites a saved query and its
    output, with its population rule; a Controls row names its control ID and its class must equal the controls
    register's; a hand-run detector is `code-warn` on an `agent-run` surface; summary counts are computed from the
    page's own Steps table; source links start at the repository root (`/…`); a platform term is linked or explained on
    first use; L0 and L1 `lens_status` is derived from the children, never set by hand; the L2 token budget is 2,500
    (the pilot's five-activity stage needed 1,976 of 2,000).

## Alternatives Considered

- **Today's embedded model only** — no catalog, no drill-down, no navigation; fails the operator's readability goal.
- **A hand-kept catalog over embedded artifacts** — rejected by ADR-089's reasoning; it silently loses entries.
- **Placement inside a durable-corpus path** — every page would need a link-override marker.
- **Placement under `docs/`** — links allowed, but outside the depersonalization gate; public safety would rest on
  review alone.
- **Diagrams drawn separately with a consistency check** — two sources that drift; a checker to maintain.
- **One document per top-level process and component class** (the spike's other D6 option) — a top-level process
  held in one document has no drill-down below its own level and no per-level decision test, so a reader who needs
  one activity reads the whole process, and the pilot's single five-activity stage already needed 1,976 of its
  2,000-token budget (decision 12); a document per component class would hand-write the structure that decision 1
  generates as a view. The spike's grid named its readers as operator, requester and AI agent; the reader map in
  decision 3 names operator, agent planning a change, small-context local model and adopter, so the requester is
  no longer a separate entry point.

## Consequences

- The design-artifact standard is extended with the catalog layer, link types, a state and lifecycle flow
  class, and the reciprocal-link exception above.
- Documentation Impact gains `retire` on every work-item form; planning reads and close verifies.
- The engine is the small generator the engine decision recommends.
- The terms this effort introduced (universe, value stream, sub-process, activity, step; the enforcement classes) are
  registered in the glossary.
- The pilot settled the page budgets (decision 12), the template fixes (listed in its notes) and the L3 seeding rule:
  seed from structure where it exists, read the prose for the rest, and expect stage specs to need the most authoring.

## Reversibility

EXPENSIVE — a later change of model rewrites every page and generator. Confidence: HIGH on D1, D2 and placement (the
pilot built and validated pages on them); MEDIUM on how much of the release pipeline's L3 the seeding rule covers.

## Related ADRs

- ADR-089 — the embedded-artifact declaration marker. Its reasoning against a hand-kept index is why this record's
  catalog is generated (decision 1); the marker continues to govern embedded artifacts.
- ADR-211 — the four design axes. Decision 3 places the process-flow axis in the pages and the structure, data and
  behaviour-over-time axes in the generated views.
- ADR-015 — the homes for dedicated diagram files. Decision 4 adds a separate home under `core/` for catalog pages and
  leaves those homes unchanged.
- ADR-181 — citation binding: other files cite this record by its slug token until the release claim binds its number.

## References

- #8117 — the documentation-model spike this record answers: D1 the model, D2 the written-to-visual rule, D6 the
  minimal set
- #8111 — the documentation-model epic, which frames the extension of the design-artifact standard
- #8494 — the card that extends the design-artifact standard with the catalog layer, link types, the state and
  lifecycle flow class and the reciprocal-link exception, in the release that lands this record
- #8119 — the card that gives Documentation Impact its retire action on every shipping work-item form, in the same
  release
- #8114 — the epic for keeping documentation current through the release pipeline: planning reads it, close verifies it
- #8495 — the card that makes planning read the current-state pages and close-out run its documentation gates, in the
  same release
- #8118 — the engine decision card; still open, and in no release, when this record landed — a forward reference,
  not a dependency

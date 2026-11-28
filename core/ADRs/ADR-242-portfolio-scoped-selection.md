---
title: ADR-242 — Portfolio-level surfaces select by portfolio_id, keep one composed file per portfolio folder, and fail closed
status: Proposed (flips to Accepted when the workspace owner ratifies it at the release's close)
date: 2026-11-28
release: rollups-select-projects-by-portfolio
deciders: "Workspace owner (Stage-4 plan gate; Stage-5 design gate, two rounds); the design authored at Stage 5 Solutioning and refined by two adversarial design reviews"
tags: [architecture, data-architecture, portfolio, selection, composer, fail-closed, reversibility-moderate]
source_observations:
  - "Before this record, every portfolio-level surface (the weekly roll-up and its composer, the daily-status multi-project run, the health-check portfolio roll-up audit, the ppm-agent status answer, and project-initiator's registration and closure) read one PORTFOLIO.md, and none read portfolio_id; the entity model already admitted more than one Portfolio record and gave each Project an optional portfolio_id (the card that framed the gap is in § References)."
  - "Keeping one portfolio's projects out of another portfolio's roll-ups rested on a behavioral correction and manual overrides of project-initiator Steps 5 and 5a — separation by prose, not by the surfaces."
  - "The composer's discovery walk is shared with two other corpus walkers through one traversal predicate and held by a parity suite, so a portfolio filter could not sit inside the walk."
  - "The rollup contract states a seven-field count in several places, one of them a Tier-0-floored governance file, so a portfolio key added as an eighth contract field would cascade into an operator-executed edit."
---

# ADR-242 — Portfolio-level surfaces select by portfolio_id, keep one composed file per portfolio folder, and fail closed

## Status

**Proposed** — authored at Stage 6 Engineering for the `rollups-select-projects-by-portfolio` release, as the record the Stage-5 design called for. Ratification is recorded in this file's frontmatter `status:` field, which is where it must be verified, and is never inferred from milestone closure.

**Numbering provenance.** Claimed as **242** against an anchor of **241** on `origin/main`, read from `release/tools/renumber-adr.py --detect` immediately before this file was created. A branch claim is detection-only and never binds; at authoring, a sibling release in flight held a branch claim on the same slot. Whichever of the two merges second is moved by the renumbering tool at merge time, which appends one provenance note per hop. Citations from other branch-authored artifacts use the slug token keyed on this record's slug, which carries no number shape and resolves at the claim.

## Context

The entity model admits several Portfolio records and an optional `Project.portfolio_id`, but every portfolio-level surface read one `PORTFOLIO.md` and none read the key. An operator running a second portfolio could keep its projects out of the first portfolio's roll-ups only by never listing them, by overriding project-initiator's registration steps by hand, and by a behavioral correction every session had to read. The failure mode is disclosure: one portfolio's projects appearing in another portfolio's stakeholder output.

A fix had to hold four constraints at once. A single-portfolio install had to compose the bytes it composed before. The composer's discovery walk is shared with two other walkers and could not fork. The rollup's seven-field count could not move. And the selection had to survive any narrowing of the composer's scan root, because a narrowed root would otherwise hide the records that decide membership.

## Decision

- **D1 — One rule.** The portfolio-tier selection rule lives once, in `core/standards/portfolio-writeback-contract.md` § Portfolio scoping, and every portfolio-level surface — and the cross-tier contract that builds on it — cites that heading rather than restating it.
- **D2 — Membership turns on the number of active portfolios.** That number is the count of distinct `portfolio_id` values held by active Portfolio records. With none, surfaces run unscoped as before, except that when the projects' keys name two or more portfolios the run stops and names the Portfolio records to create. With one, a project that names it or names none belongs to it, and a key that names no record is excluded and listed as unresolved, because it may name a second portfolio whose record does not exist yet. With two or more, a project belongs to the portfolio its key names, and a project that names none is unassigned: in no output, listed to the operator, and nothing stops. **There is no default portfolio.**
- **D3 — The rollup carries the key; the composer checks it.** The rollup carries `portfolio_id` beside `project_id`, outside the seven contract fields. The composer cross-checks it against the project's own `PROJECT.md`, read with the same slug test; a disagreement holds the rollup out of every output until it is re-emitted, and a polluted `PROJECT.md` key holds it and is reported as such.
- **D4 — One composed file per portfolio folder.** Each portfolio's composed file is `projects/_config/<portfolio_id>/PORTFOLIO.md`, created with its record; an install with no active Portfolio record keeps `projects/_config/PORTFOLIO.md`. While the root file exists beside an active Portfolio record, every surface stops and names the move.
- **D5 — The composer reads the records itself.** It reads them directly in `<root>/_config/` and one slug-named folder below it, never the config folder's own `releases/` folder, and never in a composed `PORTFOLIO.md`, which is never a record. It refuses a scoped run at a root holding no active record and an unscoped run at a root holding one, so narrowing its root cannot change membership. One id held in two states, or a reserved id, is a configuration error.
- **D6 — Drift and exclusion are reported, never rendered.** Join-key drift halts every portfolio's run. Field drift halts only its own portfolio's run and is counted, not named, elsewhere. Unassigned, unresolved, inactive and held projects are reported operator-side, never in the stakeholder body.
- **D7 — Cross-portfolio references are masked as defense in depth.** A member's reference to a discovered project of another portfolio renders `[OTHER PORTFOLIO]`: a `project_id` and the entity ids it prefixes match by prefix, the longer prefix deciding, and a `PROJECT.md` id matches exactly. The selection guarantee is graded on subject rows, not on this masking.
- **D8 — The composer limb binds only when the composer runs.** The skills' own text is the primary production control; the composer's self-test is the rule's executable half.

## Alternatives Considered

- **A declared default portfolio.** Rejected by the operator: a project with no key on a multi-portfolio install is unassigned, not defaulted, so no portfolio's output ever takes a project on a guess.
- **A second composed file beside an unchanged root file.** Rejected by the operator in favour of the same filename per portfolio folder, so no portfolio is special-cased.
- **An eighth contract field.** Rejected: the seven-field count is stated in a Tier-0-floored governance file, and a join key beside `project_id` reaches the same outcome with no count change.
- **A composer join to `PROJECT.md` as the selector.** Rejected as the selector: it fails at a narrowed scan root, where the Project record falls outside the scan. It is kept as the cross-check, read by an ancestor lookup rather than a second walk.
- **Folder-scoped roots.** Rejected: the tier taxonomy classifies by frontmatter `*_id`, never by folder location.
- **Sections in one file.** Rejected: every prose surface that loads the file loads it whole, so separation would rest on prose again.
- **A separately passed config root, or the caller passing the portfolio count.** Rejected: the first lets a scoped run proceed at a narrowed root and under-redact; the second restates the rule in five skills.
- **Dropping cross-portfolio edges from the served output.** Rejected: a red dependency on another portfolio's project would vanish from the member's dashboard, the watermelon shape the contract exists to prevent.
- **A Portfolio template.** Rejected: it would be a second copy of the seeding protocol's Portfolio-tier key set.

## Consequences

- Five skills and the composer cite one rule, and the cross-tier contract adopts it by citation.
- A single-portfolio install and an install with no Portfolio record compose the same stakeholder-facing bytes as before.
- An install that gains a Portfolio record must move its composed file into the portfolio's folder; until it does, every portfolio-level surface stops, loudly and by design.
- The configuration reader's portfolio rung reads exactly one composed file or none; per-project selection of that rung remains its own work.
- The prose surfaces' resolution of the served portfolio is the primary control and can drift; a deterministic served-portfolio resolver is the follow-up that would narrow it.

## Reversibility

MODERATE — the repository changes revert per slice, and the skill packages regenerate from the reverted sources; an install that already moved its composed file into a portfolio folder needs an operations session to move it back.

## Related ADRs

- ADR-019 — specialists compose shared function-skills; health-check composes weekly-status-rollup's Section 6 rather than absorbing it.
- ADR-044 — the decision that last re-froze the entity roster; the rollup stays a composed read-surface and this record adds no entity.
- ADR-138 — the per-entity Axis-1 carrier; its rejected alternative declines to give the Portfolio record a declared producer, and this record likewise reads records and authors none.
- ADR-092 — plan-file claim-time stamping, the version-binding precedent this release follows.

## References

- #8478 — the card: portfolio-level surfaces read one PORTFOLIO.md and never filter by portfolio_id.
- #5828 — the parent epic: the cross-tier resolution contract this rule is the portfolio tier of.
- #9179 — the Stage-5 design and its two decision records.
- #9197 — the two adversarial reviews of that design.

---
title: ADR-235 — The chain-head set derives from tracker labels, standing is declared on the label, and the epic child-set rule has one home
status: Proposed — authored at Stage 6 Engineering of the sequencing-layer-foundation release; ratified at that release's Stage 13 Close
date: 2026-11-05
release: sequencing-layer-foundation
deciders: "Workspace owner (Collective Review scope lock; ratification at Stage 13); design authored at Stage 5 Solutioning and revised on the Phase A6.5 adversarial review"
tags: [release-pipeline, work-graph, initiative-labels, derived-view, single-source, standing-initiative]
source_observations:
  - "At the 2026-11-05 Stage-5 read, 6 open epics carried no project label, and all 6 were evergreen intake containers; the share of each container's children (all states) carrying the standing initiative's label ran from 64% to 100%, so a strict majority captured 6 of 6."
  - "At the same read, 1 of 11 live project-label descriptions began with the word Standing, and 0 of 10 operator-local roadmap instances declared permanent sunset criteria; there was no roadmap for the standing initiative at all, and roadmap instances are git-ignored and absent from a fresh install."
  - "At the same read, the only epic child-set rule in the tree lived inline in the epic rollup-close audit, inside a single-quoted python program that no second reader could load."
  - "The Phase A6.5 review measured 633 initiative members on the 2026-11-05 tracker: 618 rows carried parent_issue_url and 15 did not; the host omits the key, rather than nulling it, for an issue that has no parent."
  - "At the Stage-6 live run (2026-11-05), the view rendered 10 initiative heads and 0 lone-epic heads over 792 open issues (the search total also read 792), absorbed 6 flow containers, and every partition summed; 59 reads, 0 failed."
supersedes: none
---

# ADR-235 — The chain-head set derives from tracker labels, standing is declared on the label, and the epic child-set rule has one home

## Status

**Proposed** — authored at Stage 6 Engineering of the `sequencing-layer-foundation` release, after the operator's Collective Review scope lock rendered the decisions it records. It is ratified at that release's Stage 13 Close; the ratification is recorded in this file's frontmatter `status:` field and is never inferred from a review comment or from milestone closure.

**Numbering provenance.** This record was authored at the next free number on its branch. The mainline anchor plus one is claimed by a sibling record shipping in this same release, so this record takes the slot after it rather than duplicating it; stepping further would leave a gap, which the contiguity gate fails as readily as a duplicate. A branch claim is detection-only and never binds for mainline purposes. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note per hop. Other branch-authored artifacts cite this record by the ADR slug token carrying the slug `chain-head-set-derives-from-tracker-labels`, which has no number shape and resolves at the claim.

**Numbering provenance — `231 → 235`.** Held **ADR-231** branch-local; renumbered to **ADR-235** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 231. In-release citations that read "ADR-231" denote this record.

## Context

The platform's work tracker groups work above the epic tier only by a `project:` label and an operator-local roadmap document. An operator who wants to see every line of work at once — each initiative, the epics under it, and their children — has to assemble that view by hand, and an interim generator kept outside the platform did so from two hand-kept lists: one of initiatives with their outcome lines, and one of the evergreen intake containers that hold no initiative label of their own.

The set of heads is mixed by construction: initiatives are labels and lone epics are issues, so no tracker search returns it. An initiative is never materialized as an issue (label taxonomy, § Initiative Labels), so the set can only be derived, and a derived view needs three rules a hand-kept list never stated: which labels are heads, where a label-less epic belongs, and which initiatives are standing rather than finite. A standing initiative groups recurring work that never terminates and is governed by capacity, not burned down, so showing it a completion percentage misstates it.

The view also needs each epic's children. The platform already had one rule for that — native sub-issues together with issues linked by an `epic:` label, the carrier excluded — but it lived inline in the epic rollup-close audit, where no second reader could load it.

## Decision

1. **The head set is derived, never registered.** Every `project:` label carrying at least one open issue is an initiative head; a label with none is listed as empty, not drawn. Every open `type:epic` issue carrying no `project:` label is a lone-epic head, except as rule 2 places it. Adding an epic to an initiative needs only the label.
2. **A label-less epic is absorbed by strict majority.** When more than half of a label-less epic's children, counted over all states, carry one standing initiative's label, the epic renders inside that initiative as a flow container. A tie between standing labels, a share of one half or less, an empty child set, or a child-set read that failed leaves it a lone-epic head; a failed read is marked unmeasured and is never absorbed.
3. **Standing is declared on the label.** An initiative is standing when its label description, left-stripped, begins with the word `Standing`. A standing head shows no completion percentage. When no initiative reads as standing the view stops with an error that names the cause, so an edit that drops the word cannot silently turn the standing initiative finite and put every flow container back as a separate head.
4. **The epic child-set rule has one home.** `release/tools/_epic_child_set.py` holds it; the epic rollup-close audit and the chain-head view both load it by path, and a failed load stops either reader rather than falling back to a copy.
5. **The view renders structure and counts, never a sequence.** Its order is a display order and says so. Dependency edges come only from the single-sourced grammar in the bundle parser, and every facet the view could not read is marked unmeasured rather than shown as zero — a missing parent field included, which the host omits for an issue with no parent and which therefore counts as unparented.

## Alternatives Considered

**Where the evergreen containers belong.**

- *Label hygiene* — give each container the standing initiative's label. Rejected: the containers' own contract says they are deliberately not coextensive with any initiative, the label is repository state outside any diff, and the containers' taxonomy shape is owned elsewhere.
- *A registry of containers*, as the interim generator kept. Rejected: a new container would need a registry edit, which is exactly what a derived head set exists to remove.
- *Render them as heads with a badge.* Rejected: heads that are not lines of work over-claim structure.
- *Detect them lexically* from title or body. Rejected: one title edit would move an epic.

**Where the standing declaration lives.**

- *Roadmap frontmatter declaring permanent sunset criteria*, the declaration the taxonomy cites. Rejected: roadmap instances are operator-local and absent from a fresh install and from CI, and no instance declared it.
- *A platform-configuration key.* Rejected on blast radius: three governed files outside the change, a configuration resolver, and an instance label shipped in a platform default.
- *Hard-code the standing label in the tool.* Rejected: an instance fact in platform code.
- *Infer standing from structure* ("a standing initiative has no epics"). Rejected: falsified by a finite epic carrying the standing label.
- *Also declare the label as a row a parity check compares.* Not adopted: the initiative labels are a namespace pattern that no pack declares rows for, so nothing would compare against it. The fail-loud guard in rule 3 closes the false-negative direction instead.

**Where the child-set rule lives.**

- *Re-implement it in the view* with a parity fixture. Rejected: a twin rule is the duplication the register-or-remove rule forbids.
- *Call the audit and read its output.* Rejected: the audit's output carries counts, not child identities.
- *Put it in the bundle parser's shared home.* Rejected: it would mix a tracker-graph rule with issue-body grammar and couple two unrelated changes. The module is net-new because extending in place is infeasible: the rule lived inside a shell-quoted program no second reader can load (extend-before-create).

## Consequences

- The head set follows the tracker: a new initiative label with an open issue appears on the next run, and an emptied one moves to the empty list.
- The standing declaration is a word in a label description, which is repository state outside git. Dropping the word makes the one command fail with an error naming the remedy, rather than misreporting; a finite label whose description happens to begin with the word would lose its percentage, which loses information but claims nothing false.
- The epic rollup-close audit, which Stage 13 close-out runs, now loads a module at classify time; a missing module halts that close-out phase loudly. Its self-test carries an arm that proves the module loads and a control that proves a missing one fails.
- The view is only as complete as the sub-issue graph. Unparented members are counted per head, so decay in the graph is visible rather than silent.
- Milestone lanes and run order stay out of this view: a later sequencing layer derives them from directed dependency edges.

## Reversibility

**CHEAP** — one merge revert restores the audit's inline rule and removes the view; nothing is persisted on the host, because the view writes neither labels nor edges. Confidence **MEDIUM**, because the standing declaration rides on a mutable label description.

## Related ADRs

- ADR-049 — an initiative is a grouping label, never an issue; this record derives the view that grouping implies.
- ADR-012 and ADR-046 — roadmap instances are operator-local, which is why the standing declaration cannot live in roadmap frontmatter.
- ADR-094 — extend-before-create: the child-set module is net-new only because in-place extension is infeasible.
- `ADR-234` — the bundle parser as the single home of issue-body reads, whose dependency grammar this view reads edges through.

## References

- #6398 — the card: render every chain head in one view, derived from tracker labels, with drill-down to epics and children.
- #6443 — the sequencing layer that owns milestone lanes and run order, which this view deliberately does not render.
- #6429 — the evergreen flow-container shape, which the absorption rule holds under either outcome.

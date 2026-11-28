---
title: "ADR-242 — The issue body's contract sections are the scope of record; its record sections are never rewritten"
status: Proposed — to be ratified at this release's Stage 13 Close (Phase A13); never inferred from milestone closure
date: 2026-11-28
release: issue-body-is-the-scope-of-record
deciders: "Workspace owner (operator), who chose the direction on 2026-09-26 (decision D1), ruled its four open points on 2026-11-14, and at the Stage 5 design gate settled the governing table's scope, acceptance criteria at Planning and the writers of an added line + the Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment), which designed the section cut + the operator at the Stage 13 ratification gate"
tags: [architecture, release-pipeline, issue-body, source-of-truth, field-lifecycle, write-authority, supersession, reversibility-cheap]
supersedes: ADR-062 in-part (Decision item 2) — the body-wide historical-record clause; canonical-surface precedence and the Stage-5 substrate-citation translation stand
source_observations:
  - "A source-of-truth review of 436 approved and future-bundled cards (snapshot 2026-09-26 at origin/main 35dbf418) found 252 whose current scope lived in comments rather than in the body."
  - "At the release baseline 8ed5e273 six normative surfaces restated ADR-062's body-wide no-rewrite rule: ADR-062 Decision item 2, its core ADR index entry, stage-05 Phase A1.5, the hub-spoke bridge's Stage 5 substrate-drift chip pattern, the release-personas Stage 5 line and the failure-mode standard's intake-substrate-drift example."
  - "At the same baseline the field lifecycle matrix and the ticket spec's Agent Write Permissions table disagreed in six cells (Evidence at Triage and at Close, Documentation Impact at Triage and at Bundle, Priority at Dev Testing and at QA) although the table's own note promised the two would never re-diverge undetected; each table's prose named a different authority; and the surfaces that refine acceptance criteria at Planning, on a currency mismatch or on a re-review refinement, did so where the matrix locked them."
  - "The two steps that added a line beside another card's record section at the baseline, the Stage 2 counted-observation line and the Stage 13 folded follow-up line, were each applied only after the operator confirmed them, and the Stage 2 step read trusted bodies only."
  - "This record's own card was revised under the rules it records: the 2026-11-14 ruling rewrote Considered Options, Decision and Consequences in place, added one line beside Context and removed none, and left one comment giving the date, what changed and why."
---

# ADR-242 — The issue body's contract sections are the scope of record; its record sections are never rewritten

## Status

Proposed. Authored at Stage 6 of the `issue-body-is-the-scope-of-record` release from its Stage 5 design. Ratification is the operator's, rendered per record at that release's Stage 13 Close (Phase A13) and verified there by Gate 13 row G-CL9; it is never inferred from milestone closure.

**Numbering provenance.** This record was authored at the next-free number computed from the mainline anchor. An ADR number is allocated at authorship but claimed at merge; should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Citations use the slug token `{{ADR:issue-body-contract-sections-are-the-scope-of-record}}`, which resolves at the claim.

This decision is extended or reversed only by a successor ADR, never by an in-place edit of this record.

## Context

- Two surfaces disagreed about who owns an issue body, and neither cited the other. The ticket information architecture spec names the body the single authoritative record, updated in place as facts change. ADR-062 Decision item 2 holds that an issue body remains historical record, and that a spoke does not rewrite it to correct a stale or substrate-level citation.
- The disagreement had a measured cost: scope that changed after intake lived in comments, so a reader of the body planned against stale scope (`source_observations`).
- ADR-062 states that its decision is extended or reversed only by a successor record, so settling the conflict needs a record, not an edit.
- ADR-210 already makes the issue body the list of record for acceptance-criterion ordinals. This record extends that anchor to the card's scope and dependencies.
- The section names the operator ruled are the improvement template's headings. The intake templates carry different section sets, so a rule naming only those headings would not reach a decision card, a story or a bug.
- Two tables stated which stage may write a body field, each named a different authority, and one was a hand-kept copy of the other that had drifted from it. Several surfaces also refined acceptance criteria at Planning while the matrix locked them there.

## Decision Drivers

- **One authority.** One place states where a work item's current scope, acceptance criteria and dependencies live.
- **Keep ADR-062's valid core.** A canonical-spec edit still wins over a substrate-body mutation when Stage 5 translates substrate-level citations.
- **Unblock the held work.** Card-body edits held behind this decision proceed under a stated rule.
- **Comments carry the why, not the state.**
- **The smallest change that leaves no live contradiction.** The fix lands in the surface the rule names, and every surface that restates the rule is narrowed in the same change.

## Decision

An issue body's **contract sections** are the source of truth for the work item's scope, acceptance criteria and dependencies, and are edited in place. Its **record sections** hold what was observed, and are never rewritten. The canonical corpus, not the body, owns platform facts: a body states what the card asks for, points at a platform fact by file and section rather than restating it, and stays directional about structure.

**1. Sections — what a section holds decides its class.**

- A **contract section** states what the card asks for: the change, the condition that proves it done, the files and documents it touches, the work it waits on and the effects it is expected to have; on a decision card, the drivers, the options weighed, the decision and its consequences. It is edited in place, replacing the superseded text, never appended beside it.
- A **record section** states what was observed: the problem as seen at intake, its evidence, the conditions it was seen under, and later notes. It is never rewritten. A later observation may be added beside it as one line that names its source; adding that line is an edit like any other, and rule 2 says who may make it.
- A section that holds both is a record section, and a change to what the card asks for is written into a contract section. Every intake template carries at least one contract section, so scope always has a home.
- On the improvement template the contract sections include Proposed Change, Acceptance Criteria, Affected Files and Dependencies, and the record sections include Description and Evidence. The ticket information architecture spec keeps the classification of every intake template's sections, as a projection of this rule.
- A single-value field — a priority, a category, a severity, a domain, a status, a size, a parent link — places the card and holds no prose. It is not a section, so this rule does not classify it. It follows its row in the field lifecycle matrix, which also names the row that a field without one of its own follows.
- Rule 1 binds every writer, the operator included. A ruling that changes what a card asks for is written into a contract section; one that adds to what is known is added beside a record section.

**2. Writers — the field lifecycle matrix is the governing table for body fields.**

- The field lifecycle matrix (`core/schemas/field-lifecycle-matrix.md` § Body Fields Lifecycle) governs which stage may write each body field. The ticket spec's § Agent Write Permissions table points each stage's body updates at the matrix's column for that stage rather than restating them. Where any other surface disagrees with the matrix on a body field, the matrix wins. This record governs body-field writes only; it says nothing about labels, Projects fields or any other channel outside the body.
- A stage agent edits a contract section inside the stages the matrix opens for that field, and leaves one why-comment when the edit changes scope, acceptance criteria or fix direction. A cell the matrix marks as conditional opens the field only under the conditions its footnote names.
- Outside those stages — a root-cause analysis, a readiness-sweep decision, cross-release routing, anything after Stage 5, any field the matrix shows locked — an agent edits only to carry out a decision the operator has recorded. That is the path for changing a locked field.
- A line added beside a record section is an edit like any other. It is made at a step that adds one today — the Stage 2 counted-observation line on an owning item, and the Stage 13 folded follow-up line on an owner, each applied only after the operator confirms it — or to carry out a decision the operator has recorded. Any other later observation is a comment. Both of today's steps write to another card, so neither is a cell of the matrix, whose columns describe the card a stage is processing.

**3. Citations.** A stale file path or line number in a body is replaced, on the card's next edit, by the file and section name with no line number. The rule rides an edit that rule 2 or rule 4 authorizes; it never authorizes an edit by itself, so a stale citation is never on its own a reason to edit a body. A citation fix changes how a path is written, not what was observed, so it is not a rewrite under rule 1. Evidence pinned to a commit stays as written.

**4. Operator rulings.** A ruling that changes a card is written into the section it changes, in place, with one short comment giving the date, what changed and why.

**The why-comment rule.** A body edit that changes scope, acceptance criteria or fix direction gets one short comment giving the date, what changed and why. A hygiene or citation fix gets none, and neither does a line added beside a record section, which names its own source. The ticket spec's § Body Update Protocol carries the rule's operational rows.

**What stands from ADR-062.** Its canonical-surface precedence (Decision item 1) and its Stage-5 cross-repo-citation translation (Decision item 3, carried by stage-05 Phase A1.5) stand: the remediation of a platform fact lands at its canonical governed home, never in a body, and translating a substrate citation never edits the body. Decision item 2 is superseded: a body is no longer historical record as a whole; its record sections are. ADR-062's rejection of its option (B), rewriting the body to correct stale citations, rested on Decision item 2 and falls with it for contract sections. Its concern — a second source of truth for platform facts — is met by the platform-facts clause and by rule 3, because a body points at a platform fact rather than restating it.

**Scope of the rules (introducing-release-exempt cutover).** The rules govern card-body edits made after this record is ratified — once its `status:` reads `Accepted` on main, which happens at the Stage 13 Close of the release that introduces it. Until then ADR-062 governs as in force. The release that introduces this record runs every one of its stages under ADR-062, its own Stage 13 Close included, and during that release no agent edits a card body except to carry out a decision the operator has recorded. If the operator declines to ratify this record at that Close, it stays `Proposed` and binds nothing: the decline is recorded there, and the edits the introducing release made to cite this record are reverted by a follow-up change the decline routes, so that no surface on main states a rule nobody ratified. This record does not revisit body edits made before it was ratified; the held stale-citation edits proceed as operator-authorized backlog work under rule 3.

## Alternatives Considered

- **(A) A scoped successor, cut per body section — chosen.** It keeps ADR-062's canonical-surface precedent, gives scope one authority, and follows the line the field lifecycle matrix already draws between updatable and locked fields.
- **(B) Reverse ADR-062 fully — rejected.** Bodies would be freely rewritten, substrate citations included, and the canonical-spec-wins precedent for substrate citations would be lost.
- **(C) Keep ADR-062 as is — rejected.** Scope changes would stay in comments, and bodies would keep drifting from current scope.
- **The permissions table as the governing table — rejected.** The writers rule as ruled names the matrix, and the permissions table already called the matrix authoritative.
- **One merged table — rejected.** It would move the permissions table's comment, sub-issue, native-dependency and approval columns, which are channels rather than fields, into a schema that models field state, and restructure two specifications many surfaces cite. Pointing the permissions table's body-update cells at the matrix removes the same duplicate inside the cells this change already touches.
- **Hand-kept field lists in the permissions table — rejected.** That arrangement had already drifted from the matrix in six cells under a sentence promising it would not. A cell that points at the matrix's column cannot disagree with it.
- **Opening acceptance criteria at Planning without condition — rejected.** It would let a Planning agent change criteria for any reason, wider than any surface that refines them at Planning. The matrix's conditional cell opens them on the two triggers those surfaces name.
- **Narrowing the Planning-stage acceptance-criteria openers instead of opening the matrix cell — rejected.** It would edit a governance file and a skill outside this record's change set, and the openers already confine a Planning-stage criteria change to those two triggers.
- **A channel for added lines open at every stage and to every writer — rejected.** Both steps that add such a line today are operator-confirmed, and the Stage 2 step reads trusted bodies only; an open channel would drop both gates.
- **Classifying sections only by a per-template list — rejected.** An immutable record holding a list of mutable templates goes stale when a template gains a field; the rule classifies by content, and the list is its projection.
- **A third section class for single-value fields — rejected.** The operator ruled two classes; a single-value field is outside the class system rather than a third kind of section.
- **Governing labels and Projects fields in this record — rejected.** The four rulings are about body sections. Fixing the authority of a channel outside the body in an immutable record would need another successor record to correct.

## Consequences

**Positive:**
- Readiness, planning and acceptance read one surface for a card's current scope.
- A card whose criteria are corrected after intake carries them in its body.
- The held stale-citation edits have a rule to follow.
- One table governs body-field write permission, and the other points at it, so the two cannot drift apart again.

**Negative:**
- ADR-062 is superseded in part, and the surfaces that restated its body-wide rule are narrowed in the same change.
- Each producer that changes a card's scope needs a body-update step; that is follow-on work outside this record.
- A Planning agent may now edit acceptance criteria at Stage 4 on the two triggers the matrix's conditional cell names, recording practice the codified surfaces already state; any other criteria change at Planning carries out a decision the operator has recorded.
- Surfaces that write card bodies under rules of their own — a wholesale body re-scaffold, a re-review refinement routed to the issue body, an observation converted to another template — are read under this record, but do not yet state it; bringing each into line is follow-on work outside this record.

## Reversibility

CHEAP · confidence HIGH. Reverting the release's single pull request removes this record, the pointer on ADR-062 and every narrowing edit together, with no data migration. Card bodies edited under the rules after ratification stay valid under either regime, because their record sections were never rewritten.

## Related ADRs

- ADR-062 — superseded in part (Decision item 2). Its canonical-surface precedence and the Stage-5 substrate-citation translation stand.
- ADR-210 — the issue body is the list of record for acceptance-criterion ordinals; this record extends that anchor to scope and dependencies.
- ADR-211 — relies on the Body Update Protocol row this record generalizes into the why-comment rule.
- ADR-181 — ADR citations bind at the claim; in-release prose cites this record by its slug token.

## References

- #7970 — the ADR card holding this decision, the 2026-09-26 direction and the 2026-11-14 rulings.
- #7953 — the umbrella for keeping card bodies current; this record is its requirement R1 and carries its R3, the why-comment rule.
- #7676 — the ADR card for the issue body as the list of record for acceptance criteria, which this record extends.
- #6170 — a card whose corrected criteria wait on this record.
- #7680 — the slice for re-scoped or added acceptance criteria, which applies rule 1.
- #9147 — the Stage 4 planning sub-task, carrying the plan and the operator's plan-gate decisions.
- #9151 — the Stage 5 solutioning sub-task, carrying this record's design and the operator's Stage 5 design decisions.

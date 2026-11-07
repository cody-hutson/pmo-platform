---
version: stage-document-model-decision
date: 2026-11-07
type: note
issues: ["#8153", "#8154", "#8155", "#8156", "#8157"]
pr: "#8814"
links:
  plan: release/releases/plans/_unversioned/stage-document-model-decision_RELEASE_PLAN.md
  log_anchor: "#stage-document-model-decision-version-less"
reversibility-tier: CHEAP
themes: ["cluster:documentation", "project:knowledge-corpus"]
summary: "What each delivery stage writes was split across two tables that disagree. One ratified design now answers it for releases and projects."
requires_action: false
breaking: false
components: ["operational-artifacts", "stage specs", "process catalog", "ADR corpus"]
followups: ["#8150"]
---

# One ratified design now says what every delivery stage writes

2026-11-07 · stage-document-model-decision

What each stage of a release or a project should write down was spread across two tables that disagree on the list of stages, and the design a change was built from did not outlast its release. A design the operator ratified now settles what each stage writes, how long each document stays current, where it lives and who reads it next. That holds for both the release pipeline and project delivery, under any delivery methodology. Nothing is built against it yet: it is the plan the next three milestones build.

> **Skip the rest** unless you plan or build the stage-document work, maintain the stage specs, or rely on the stage tables in the operational-artifacts standard.

## Who this affects

- Anyone planning or building the stage-document work: the design names seven slices of that work and groups them into three milestones.
- Anyone who maintains a release stage's spec or a project-delivery template: what each stage owes is now decided in one place, ahead of being built.
- Anyone who relies on the stage tables in the operational-artifacts standard: those tables are scheduled to be replaced by a citation of the new declaration.

## What changed for everyone using the platform

- **What each stage writes is decided once, for releases and projects alike.** One planned standard will declare every stage's documents. Each document row states its lifecycle class, its template, its home, who reads it next, and how often it is written. *Why it matters:* the two tables in use today disagree on which stages exist and name no reader, so nothing downstream can tell what a stage owes.

- **Both kinds of delivery share one vocabulary of eight stages of work, without renaming anything.** Every release stage and every project phase maps to one of Concept, Define, Design, Build, Test, Transition, Operate and Close. *Why it matters:* a release's design document and a project's design document can now be found by the same key, while every existing stage name and number stays as it is.

- **The delivery methodology changes when a document is written, not what the document is.** Each methodology's variant is declared per document: phased work writes at the phase gate, timeboxed work writes within the increment, and continuous flow writes per item. *Why it matters:* a team choosing Scrum, Kanban or a phased approach gets the right document timing, without a separate document model to maintain for each.

- **A change's design will outlast its release.** The design now names living homes for what a change designs: the process-catalog page of each process it alters, and a decision record when the decision is large enough. It also names the check that reads what was built against what was designed. *Why it matters:* today the design reaches only a stage comment and is lost when the release ends, so the next change cannot read why things are the way they are.

## Known limits

- This release decides; it builds nothing. No standard, template, stage spec or check changes until the delivery milestones ship, and the operational-artifacts tables stay in force until then.
- Two parts are provisional by the ratification's own terms. The rule for where each kind of document lives waits on the separate decision about where out-of-git data belongs. And the default that keeps a timeboxed design document living is a labelled default, because the sources name no design document for those methodologies.
- The per-document inventories that informed the design are working records outside the repository. They expire unless the delivery work carries them forward.

Report issues by opening an issue on the platform repository.

## Reversibility

CHEAP / HIGH. Until the delivery milestones build against it, the decision record can be amended or superseded at no cost: nothing depends on it yet. Once the declaration, the stage specs and the checks are built, a change of model becomes EXPENSIVE.

---

### Operator and engineering detail

**The decision record.** The ratified design ships as ADR-232, *Each delivery stage's documents are declared once, keyed to a shared layer of delivery spans, and projected onto the release pipeline and project delivery*. It was authored `Proposed` at Stage 6. The operator ratified it with amendments at the Stage 9 gate on 2026-11-05, and it merged `Accepted`. The amendments:
- point-in-time binds to Domain C, reopening the frozen Axis-2 set only on a shown need;
- the timeboxed and continuous design default is a labelled default;
- the risk-class home decision is re-checked;
- the node-delta lint is adopted on its supporting-grade premise.

**Delivery cut.** The record proposes seven slices in three milestones, so that the second milestone carries no more than two external dependencies:
- *One declaration*: the standard, the lifecycle-register additions, the methodology section, span-keyed gap detection and the template gap list.
- *The design lives in the catalog*: the node-delta block and the build-commit page writes.
- *The catalog keeps its integrity*: the integrity checks, which wait on the catalog generator.

**How the design was reached.** Four discovery cards measured the current state before the design was written: the release-stage inventory, the project-delivery inventory, the stage-model crosswalk and the methodology variation. Their records are git-ignored working analysis. Five adversarial design reviews and per-card Stage 7 and Stage 8 reviews preceded the ratification.

**ADR number.** The record was drafted as ADR-230. A sibling release merged its own ADR-230 first, so the Stage 12 reconciliation renumbered it to ADR-232 before the merge, and the index's renumber log records the move. The release's file-integrity criterion was amended in the Stage 12 chore pull request to admit that one log line.

For full implementation detail see the [RELEASE_LOG entry](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/RELEASE_LOG.md#stage-document-model-decision-version-less), [the release plan](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/plans/_unversioned/stage-document-model-decision_RELEASE_PLAN.md) and [ADR-232](https://github.com/cody-hutson/pmo-platform/blob/main/core/ADRs/ADR-232-stage-documents-are-declared-once-and-projected-twice.md).

### References

- Milestone: [stage-document-model-decision](https://github.com/cody-hutson/pmo-platform/milestone/432)
- Integration PR: [#8814](https://github.com/cody-hutson/pmo-platform/pull/8814) at `b0763aac5c144b241c72b6c20cd827af5a840a0e`
- Stage 12 chore PR: [#8828](https://github.com/cody-hutson/pmo-platform/pull/8828) at `97d32b27e7f9644cf6be6f12204c6591fe09b714`
- Closed issues: [#8153](https://github.com/cody-hutson/pmo-platform/issues/8153) · [#8154](https://github.com/cody-hutson/pmo-platform/issues/8154) · [#8155](https://github.com/cody-hutson/pmo-platform/issues/8155) · [#8156](https://github.com/cody-hutson/pmo-platform/issues/8156) · [#8157](https://github.com/cody-hutson/pmo-platform/issues/8157)
- Follow-up: [#8150](https://github.com/cody-hutson/pmo-platform/issues/8150) (the stage-document epic, whose delivery cut this design proposes)

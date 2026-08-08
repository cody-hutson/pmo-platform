<!-- reference-durability: allow-link -->
---
title: ADR-123 — The epic rollup-close surface is an audit, not a gate, and its two undecidable gates are annotated rather than adjudicated
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-07
release: methodology-fields-and-statuses
deciders: "Workspace owner (mechanism ratified at the Stage-5 wave-1 gate, together with the suppression design and the acceptance-criteria refinement); designed at Stage 5 Solutioning, authored at Stage 6 Engineering"
tags: [architecture, release-pipeline, close-out, epics, labels, taxonomy, detective-tooling, operator-judgment, reversibility-cheap]
source_observations:
  - "The label taxonomy exempts the epic type from the status-label invariant on the stated ground that an epic is a container / grouping tier rather than a lifecycle work item, holding no lifecycle position of its own because its children carry the state. That exemption is a deliberate operator decision, not an oversight."
  - "At the build baseline, 42 open epics partition exactly into 15 rollup-close candidates, 21 with at least one open child, and 6 with no children at all. The partition was verified exact rather than assumed."
  - "Two independent topological predicates were built to decide whether a candidate is a true epic or an initiative container mislabelled as one. Both over-matched at 14 of 15, and the narrower one additionally produced a false negative on the single candidate carrying the initiative-container shape it was built to catch."
  - "The cause of that failure is structural: the taxonomy places the initiative label on the container AND on every one of its children, so container and thrust are label-identical by construction. The distinguishing fact lives only in body prose."
  - "9 of 15 candidates carry at least one child closed as abandoned rather than delivered, one of them 7 of 14. A criterion reading 'all children closed' admits every one of them as complete."
  - "1 of 15 candidates has a child set consisting entirely of research spikes — research answered, with no capability necessarily shipped."
  - "The label-linked and native child mechanisms are not kept in sync. At the baseline 0 open children were reachable by label alone, but 29 such children exist historically, 21 of them under a single epic. The sensitivity arm is non-zero, so the zero is a real transient absence rather than a broken probe."
  - "The carrier epic self-labels: the taxonomy applies the epic label to the umbrella ticket as well as its children. A child-set query that does not exclude the carrier returns the epic as its own open child."
  - "The close-out script already invokes two population-scoped detective tools in dry-run, captures their reports, and gates nothing. The pattern being extended is established, not invented."
---

# ADR-123 — The epic rollup-close surface is an audit, not a gate, and its two undecidable gates are annotated rather than adjudicated

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. Authored at Stage 6 per the Stage-6 ADR-authoring precedent. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** This record's number is the mainline anchor plus one, where the anchor already includes this release's three earlier records, derived at build time per the rule the numbering ADR ratifies. Sibling branches hold unmerged claims on lower numbers; those claims are *advisory* and do not bind the sequence. A reservation strictly above every sibling claim was considered and rejected on that ADR's own ground — a gap blocks the repository where a duplicate merely inconveniences one branch. The allocation was verified against the enforcing predicate rather than argued from the document: the union of both record directories is contiguous at `001..122` with no gaps and no duplicates, making this number the next free slot. If a sibling merges first, this record renumbers at merge time by the sanctioned tool and this section gains a numbering-provenance note.

## Context

An epic stays open forever after its work ships. GitHub does not close a parent when its last sub-issue closes, and the release close-out automation closes *milestones* — it has no step that revisits a closed issue's parent. Every epic sits outside any milestone, so the only closure automation that exists never touches one.

The originating card framed this as a missing close-out step and deferred the mechanism. The mechanism question turned out to be secondary to a prior one: **by what authority may anything assert that an epic is done?**

**The root cause is a governance exemption, and it is deliberate.** The label taxonomy exempts the epic type from the status-label invariant, on the stated ground that an epic is a container / grouping tier rather than a lifecycle work item — it holds no lifecycle position of its own, because its children carry the state. That single clause explains the entire defect. An epic is *structurally invisible* to every lifecycle mechanism that would otherwise surface it for close. Nothing is broken; a deliberate decision has an unattended consequence.

**The rubric was already known to be three gates, and only one of them is decidable.** Practice had established that "all children closed" is necessary but not sufficient: a rollup-alone signal produces false positives. The real check also asks whether the issue is a true epic rather than an initiative container mislabelled as one, and whether the parent's own body scope actually shipped.

The second of those was probed empirically rather than assumed. Two independent topological predicates were built. **Both over-matched at 14 of 15**, and the narrower one additionally returned a **false negative** on the one candidate carrying exactly the initiative-container shape it was built to catch. The cause is structural and not fixable by a better predicate: the taxonomy places the initiative label on the container **and** on every one of its children, so container and thrust are **label-identical by construction**. The distinguishing fact lives only in body prose.

**Two further gates were decidable, cheap, and absent from the original criteria.** 9 of 15 candidates carry at least one child closed as *abandoned* rather than delivered — one of them 7 of 14 — so a criterion reading "all children closed" admits every one of them as complete. And 1 of 15 has a child set consisting entirely of research spikes: research answered, capability not necessarily shipped. Adding both narrows the population from 42 to 15 to 5.

## Decision

**(1) The surface is an audit. It gates nothing, and it renders no close verdict.**

This follows from the exemption rather than from caution. **A gate cannot assert on a field that governance explicitly exempts.** Hosting this as a blocking check over a judgment-requiring predicate would wire a false-positive engine — measured at 14 of 15 — to a surface that stops a release. The audit reports; the operator dispositions. Findings never produce a non-zero exit, so a run surfacing forty candidates and a run surfacing none are indistinguishable to any caller that reads exit status.

The rejected alternative is recorded so it is not re-proposed: hosting this as a deploy-time lint was declined **on the merits**, not merely because that file was out of scope for the release. A blocking gate over a non-decidable predicate is the wrong instrument at any scope.

**(2) The two undecidable gates are annotated, never adjudicated — and this is the load-bearing constraint.**

The tier question (true epic or mislabelled initiative) and the scope question (did the parent's own body scope ship) are emitted as **evidence columns**: the open sibling epics sharing an initiative label, whether the candidate is an initiative-label singleton, and pointers for the reader to check scope against the release ledger. No code path may mark an issue closed on either signal. They are rendered **before** the mechanical verdict, so the reader meets the tier question first rather than reading a verdict and then its caveats.

The honest cost is recorded rather than suppressed: this leaves real judgment with the operator on every candidate, and the audit will keep surfacing candidates it cannot resolve. That is the correct trade. The alternative — a verdict derived from a predicate proven wrong in both directions — converts an open question into a confident error, and a wrongly-closed epic is discovered late, if ever.

A separate initiative is codifying and linting the initiative-is-not-an-epic rule. That work is **declared, not absorbed, and not a blocker**: this annotation is strictly weaker and ships standalone. If that lint lands, the tier gate can be upgraded from annotation to filter without redesigning anything here.

**(3) The child set is the union of both linkage mechanisms, and the carrier is excluded from its own child set.**

The label-linked and native mechanisms are not kept in sync, so a single-mechanism read closes epics that still carry open work. At the baseline, zero open children were reachable by label alone — but 29 such children exist historically, 21 under a single epic, and the sensitivity arm is non-zero. **The zero is a transient absence, not a structural one**, and a native-only design is one new label-linked issue away from a false closure.

The carrier exclusion is the non-obvious half. The taxonomy applies the epic label to the umbrella ticket as well as to its children, so an unguarded label query returns the epic **as its own open child** — which makes it permanently unclosable. The failure is silent, off-by-one, and fatal to the whole capability, so it is guarded explicitly and asserted by a dedicated offline fixture rather than left to reviewer attention.

**(4) Suppression is a disposition marker in an operator comment. Zero new labels.**

A recurring audit that re-surfaces the same declined candidates every release becomes noise the operator learns to skip — which would defeat the capability as surely as never running it. An operator declines a candidate by leaving a structured HTML comment on the epic, which later runs read back to suppress it. Suppressed epics are counted and listed separately, so suppression is never silent.

A label was rejected twice over. A new trigger for an existing state does not earn a parallel label — that is a codified anti-pattern in this corpus, for a structurally identical case. And the epic type is status-label-exempt anyway, which is the very exemption that created this defect. Only comments from trusted repository roles are honoured, so the marker cannot be forged by an outside commenter.

**(5) Detection is separated from disposition in the code, not only in the doctrine.**

The network read and the gate evaluation are separate stages: one fetches, the other is a pure function from fetched data to verdicts, with no network and no file access. This is what makes the classifier testable offline in continuous integration, which the self-test discovery gate requires on both runner partitions. It is a structural requirement rather than a stylistic one — a network-dependent self-test fails on every runner.

Transport is **REST throughout, with no GraphQL dependency**. Sub-issues, labels, issue search, and comments are all reachable over REST, and REST stays healthy when the GraphQL quota is exhausted. That condition is not hypothetical: it occurred during this very release, and a separate availability defect was filed against a sibling check that returns an error status under exactly that outage. A detective tool whose whole purpose is to run at release close must not be unavailable exactly when releases close.

**(6) The mutation path exists, and is narrow.**

The tool can close candidates, but only under double opt-in: an apply flag **plus** an explicit per-issue authorization naming each issue. It closes only issues the same run classified as candidates on the mechanical gate, and never acts on an annotation. An apply invocation carrying no authorization is a validation failure, not a close-everything.

## Consequences

**The capability now has a cadence, which is the failure mode the card itself documents.** A detective tool that exists and nobody remembers to invoke reproduces the exact gap being closed. It is therefore invoked by default from an existing mandatory close-out beat, positioned after the release's own issues and milestone close so it reads fresh state — an epic whose last child closed in *this* release surfaces on *this* run.

**Operator attention is the cost, and it is bounded and legible.** First fire surfaces a single-digit set of clean candidates plus a flagged remainder, each carrying a stated reason. Every exclusion is legible: an epic with no children at all is excluded as *rollup-undefined* rather than satisfied, because the signal is absent rather than positive.

**Reversibility is CHEAP** and genuinely git-native for everything this record decides. The tool is a new file, the close-out phase is additive, and the governance paragraph is an append; no state is migrated and nothing is renumbered. The one non-git-native action is an operator closing an epic — undone by reopening it.

**The exemption is documented, not amended.** This record does not propose making epics carry lifecycle labels. That would trade a small, well-understood blind spot for a large invariant-maintenance obligation across a container tier whose children already carry the state. The blind spot is instead covered by an external detective sweep — which is the appropriate instrument for a deliberate exemption.

**What this record does not settle.** Whether any individual epic *should* close remains an operator judgment on every candidate, permanently. This record makes the population visible, the mechanical part reliable, and the judgment part explicit — it does not automate the judgment, and the design's central claim is that it should not.


## Alternatives Considered

| Option | Verdict | Why |
|---|---|---|
| **(a) Detective audit alone** | Rejected | A capability with no invocation cadence re-creates this card's own originating failure — the thing exists and nobody runs it. |
| **(b) Pipeline step alone** | Rejected | Fails on false-positive cost. A naive rollup signal over-matches at 14 of 15; gating a release on a predicate that is not mechanically decidable converts a reporting problem into a blocking one. |
| **(c) Hybrid — report-only audit + signal-only close-out phase + a named Stage-13 paragraph** | **SELECTED** | Supplies the capability, the cadence, and the name, while gating nothing. Not invented for this card: `automated-closeout.sh` phases 16 and 16.5 already invoke population-scoped detective tools in dry-run and surface their reports. |
| **(d) Host the check in `deploy.sh --check`** | Rejected **on the merits** | Recorded so it is not re-proposed. It would make a blocking gate out of a non-decidable predicate — and `type:epic` is exempt from the status-label invariant (`label-taxonomy.md:99`), so a gate cannot assert on the field at all. |

## Reversibility

**CHEAP · confidence HIGH.** Every artifact is additive: one net-new report-only tool, one signal-only close-out phase that renumbers nothing, two appended governance paragraphs, and two allowlist rows. Reverting the merge in first-parent form returns every surface in one operation. The audit creates no labels, mutates no issue, and gates nothing, so there is no repository state to unwind — this record carries none of the not-git-native rollback burden that the label-materialization half of this release does.

## Related ADRs

- **ADR-124 — Axis-1 work-status label surface.** Establishes the work-status group this release's other cards project over. Independent of this record: the audit reads epic membership, not work-status.
- **ADR-122 — the sub-task status mirror is not resynced.** Same release; shares the finding that a specification without a bound writer is not an implemented behaviour.
- **ADR-125 — K1 status fallback / K4 adapter binding.** Same release; its § Consequences carries this release's symptom-honesty statement.
- **ADR-115 — an ADR number claim binds at merge.** Governs this record's own number, which moved from an earlier allocation when a sibling release merged ahead of it.

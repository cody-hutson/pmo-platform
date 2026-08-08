<!-- reference-durability: allow-link -->
---
title: ADR-127 — The close class is a declared deliverable-type value that conditions one gate spec, never a parallel close path
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-07
release: 58-task-artifact-lifecycle-and-knowledge
deciders: "Workspace owner (D-A, D-A.1, D-A.2, D-A.3 ratified at the Stage-5 design gate; scope re-affirmed at Collective Review); designed at Stage 5 Solutioning, authored at Stage 6 Engineering"
tags: [architecture, release-pipeline, close-out, gates, deliverable-type, typed-branch, declaration-gated, knowledge-artifacts, reversibility-cheap]
source_observations:
  - "The task-artifact and artifact-acceptance vocabulary occurred zero times across the tracked corpus at design time, over a 1621-file denominator, with a live sensitivity arm (a known token returned 15 files) and a clean specificity arm (a nonsense token returned 0). The gap was real and unstarted, not merely undocumented."
  - "The Stage-6 engineering spec contained the string 'deliverab' zero times. There was no deliverable state to omit — the noun was absent entirely, so the omission read as an oversight rather than as a decision."
  - "The close-gate set grew from seven criteria to nine after the originating card was written. The two additions are both warn-mode, which is the risk: a gate a typed branch mis-conditions degrades to a log line rather than a block, so the miss would be silent."
  - "A shipped precedent for exactly this conditioning shape already existed on a sibling criterion, conditioned on the same deliverable-type axis, and the gate spec's own versioning block states the discipline verbatim: extend the criterion body, do not add an ID. Two further criteria independently cite that same shape as the one they adopted."
  - "The deliverable-type axis is a live open enum whose openness is already exercised in production — one named class ships a best-practice guide and a registry row while being absent from the project schema's recognized list. Adding a value is a supported operation with in-corpus precedent, not a schema change."
  - "The release-log header states its status lattice and its date anchor and mandates no universality. Which releases write a row is specified in the stage specs, not there — so a class that writes no row contradicts nothing in that file, and no convention edit is required."
  - "Two of the nine close gates were verified by reading their criterion text rather than by assumption: the goal-attainment gate already admits a grep as an evidence anchor, and the operational-manifest gate already carries an empty-manifest skip path. Neither needed conditioning."
  - "The two Stage-12 execute gates hard-require a release-log row with no class conditioning, so a genuine task-artifact-class release cannot complete Stage 12 today. This was verified at the criterion rows, not inferred."
  - "Blast radius over the four governance targets returned Structural on all four (first-order fan-out 47 to 178 inbound references each). That is expected for keystone governance surfaces and is the reason the design is additive-only: no inbound reference's meaning changes because the deployable path is byte-unchanged."
---

# ADR-127 — The close class is a declared deliverable-type value that conditions one gate spec, never a parallel close path

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. Authored at Stage 6 per the Stage-6 ADR-authoring precedent. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** This record's number is the mainline anchor plus one, re-derived at Engineering Commit 0 rather than pre-allocated. The allocation was verified against the enforcing predicate rather than argued: the union of both record directories is contiguous with no gaps and no duplicates up to the anchor, making this number the next genuinely free slot rather than merely an unused one. The number-checking tool reads the *worktree* and would pass on a number already taken on the mainline, so it was not used as the allocator. If a sibling merges first, this record renumbers at merge time by the sanctioned tool and this section gains a numbering-provenance note.

## Context

The pipeline closes releases on **deployment**. That is a reasonable default and it is wrong for a whole class of work.

Some work's definition of done is an **artifact**: a research document, a codification standard, a findings register, an analysis. Nothing deploys. There is no Layer-2 propagation target, no user-visible capability to describe in a release note, and no honest way to fill a deployment ledger. Before this decision, the close gates asserted a release-log `DEPLOYED → VERIFIED` transition and an executed deployment manifest **unconditionally**, so such work had exactly two options — pretend its artifact was a deployed file, or stall short of close. Both are bad, and the first is worse, because a manufactured deployment row corrupts every downstream check that iterates those rows.

**The absence was total, not partial.** At design time the vocabulary for this class occurred zero times across the tracked corpus, and the engineering stage spec contained no deliverable-state noun at all. This mattered for how the gap read: a *named* state that was merely optional would have been a judgment call, but there was no state to make optional. The stage's artifact-outputs row listed deployed copies as *"(if applicable)"*, and a task-class deliverable that let the "(if applicable)" lapse reached **no** named end state whatsoever. The omission looked like an oversight because, structurally, that is what it was.

**Two forces constrained the shape of any fix.**

First, **the close-gate set had grown from seven criteria to nine after the originating card was written**, and both additions ship warn-mode. A warn-mode gate that a typed branch mis-conditions does not block — it writes a log line. So the cost of an unstated disposition is not a loud failure but a silent one, precisely on the two gates a designer is least likely to think about.

Second, **the obvious fix is the wrong one.** The intuitive move is to give the task class its own close specification. That produces two close paths which must be kept in agreement forever, across a criterion set that demonstrably grows. Divergence is not a risk of that design; it is its steady state.

**A precedent for the right shape already shipped.** A sibling criterion is already conditioned on this same deliverable-type axis, and the gate spec's own versioning block states the discipline verbatim: *extend the criterion body, do not add an ID*. Two further criteria independently cite that shape as the one they adopted. So the question was not whether the platform knows how to condition a gate — it does, three times over — but whether this case is one of them.

## Decision

**(1) The close class is a VALUE on the existing deliverable-type axis, not a new axis and not a new gate.**

`task-artifact` is registered as a named class in the deliverable-class value space. The axis already exists, is already open, and its openness is already exercised in production — one named class ships a guide and a registry row while being absent from the project schema's recognized list. Adding a value is a supported operation, not a schema change: nothing migrates, no field is renamed, no shape moves.

The rejected alternative is recorded because it is what a fresh designer reaches for: **introducing a new `close_class` axis**. It was declined on the reuse-first bar — the discriminator exists, so a second axis must clear a *necessity* test rather than a plausibility one, and it does not. Two axes that must agree about the same release are a drift surface, and the platform has a rule against exactly that.

**(2) The conditioning lives in the criterion BODY of two existing gates. No criterion ID is added.**

The terminal-record gate is re-expressed at its true altitude — *the release's terminal state is recorded and verified in the ledger appropriate to its close class* — and then branched. The verification-evidence gate is purely additive. **Zero criterion IDs are added, renumbered, removed, or re-typed**, which is not a cosmetic property: the criterion-ID enumeration is the denominator of a gate pass-rate metric, a criterion count, and a standing check's evaluated set. Adding an ID would move all three for a change that alters no gate's population.

**One gate spec, one typed branch. There is deliberately no second close specification**, and this is the constraint most likely to be eroded later by someone adding a task-class close path "for clarity".

**(3) The branch is DECLARATION-GATED, and absence resolves to the base path.**

The branch fires only on the literal recognized value. Unrecognized, misspelled, absent, or free-form values resolve **deployable** — today's exact behavior. A close class is something a release *declares*; it is never inferred from a file list, a label set, or a milestone name. This is the platform's existing absence-falls-to-the-else-as-no-op rule applied verbatim, and it is what makes the whole change fail-safe: **nothing that exists today can route into the new path.**

**(4) The fall-through is REPORTED, never silent — and this is a separate decision from (3).**

Routing to the default is correct. Routing there *quietly* is what turns a typo in a release plan's declared domain into a wrong close that nobody sees. The closer records one line naming the resolved class and the rung it resolved through. The line **gates nothing** — it is a report entry, not a check — which is the point: it makes the default pathway load-bearing rather than invisible, at zero enforcement cost.

**(5) The substitution re-anchors the obligation. It does not remove it.**

On the task-artifact branch, no release-log row is written and the terminal-record gate is satisfied instead by an **Artifact-Acceptance Record** — one row per declared deliverable, carrying its canonical path, its landing commit, an acceptance verdict, and an acceptor. **Absent ⇒ FAIL, never N/A.** An unrecorded acceptance is an unclosed release exactly as an unrecorded deployment is.

This is the line between a typed branch and an exemption, and it is the one a later simplification is most likely to blur. Three alternatives were rejected: manufacturing a release-log row for a release that deployed nothing (the fabrication the class exists to prevent); extending the release-log status lattice with an accepted state (which would force a convention edit on that file, collide with the per-row maximum rule the concurrent-merge doctrine depends on, **and still require a row**); and forking the spec, per (2).

The record's **home is the existing verification-evidence section**, not a new ledger. That section is already mandated by the gate this decision makes additive, four close phases already write per-check verdicts into it, and a sibling gate already sets the precedent of appending a verdict-plus-narrative there. A new file would need its own presence check, its own concurrent-merge invariant, and its own archival policy to cover ground an existing surface already covers.

**(6) All nine close gates carry a recorded disposition, and seven of them are explicit no-ops.**

This is the part that looks like paperwork and is not. **An unstated gate is a gap, not a no-op**, because a reader cannot distinguish "considered and deliberately left alone" from "never considered" — and the two demand opposite responses from the next editor.

Both warn-mode gates land in the explicit-no-op column with stated reasons, since those are the two rows where a miss would be silent. The documentation-impact gate's tempting exemption — *the artifact is the doc* — is **rejected on the merits and recorded as rejected**: its scope key is a derived body property, chosen precisely because form and kind literals are not evaluable for every work-item kind, and a deliverable-class exemption re-introduces that exact defect. A gate must not stop asserting on a field that governance has not exempted. The ADR-ratification gate additionally received a second-order check: had this design waived the Stage-9 review for the task class, that gate's ratifying referent would vanish and it would pass vacuously. It does not — the branch changes only the close-**evidence anchor**, never the review path.

**Minimal conditioning is the goal, not a shortcut.** Every gate left alone is one fewer place two paths can drift.

**(7) Engineering names the positive state.**

`deliverable_state: artifact-accepted` is a first-class sibling of the deployed-copy state, not an exemption from it. A deliverable that produces no deployed copy is not an incomplete deployment — it is a **complete artifact**. Its exit condition (the artifact at its declared canonical path, plus a populated acceptance row) is what makes the close class evaluable downstream; without a positive state named at build time, the close gate would have nothing to read.

## Alternatives Considered

| Option | Verdict | Why |
|---|---|---|
| **(a) A second, parallel close specification for the task class** | Rejected | Produces two criterion sets that must be kept in agreement across a set that demonstrably grew from seven to nine mid-flight. Divergence is the steady state of that design, not its risk. This is the named divergence hazard the originating card called out. |
| **(b) A new `close_class` axis** | Rejected | Fails the reuse-first bar. The deliverable-type discriminator already ships and is already consumed by a gate; a second axis must clear a necessity test, not a plausibility one. Two axes that must agree about one release are a drift surface. |
| **(c) Exempt the task class from the deployment-gated criteria** | Rejected | An exemption removes the obligation; nothing then asserts that the artifact landed or was accepted. The class needs a *different* terminal record, not *no* terminal record — the difference between a typed branch and a hole. |
| **(d) Extend the release-log status lattice with an `ACCEPTED` state** | Rejected on three independent grounds | It would force a convention edit on the release-log file (a third named-governance-surface touch, which re-renders the release class), collide with the per-row maximum rule the Stage-13 concurrent-merge doctrine depends on, and **still require a row** — which is the thing the class exists to avoid. Any one ground is sufficient. |
| **(e) Condition the criterion bodies of the two gates, on a registered deliverable-type value, with a recorded disposition for all nine** | **SELECTED** | The only shape satisfying the one-spec constraint while leaving the criterion-ID enumeration and its three downstream denominators untouched. Not invented here — it mirrors a shipped conditioning on the same axis, and the gate spec's own versioning block states the discipline verbatim. |

## Consequences

**Adding a future deliverable class costs one value and nine dispositions** — no new gate ID, no new spec, no new file. That bound is a property of branching on a *value* rather than on a class-specific code path, and the disposition table is the extension point. Cost per class is constant and legible.

**The end-to-end task-artifact *release* path is incomplete, by design, and this is stated rather than discovered.** Two Stage-12 execute gates still hard-require a release-log row with no class conditioning, so a genuine task-artifact-class release would halt at Stage 12 before ever reaching the close gates this record conditions. Conditioning them here would have added a third named-governance-surface touch and re-rendered the release class on a bundle already over its size band — for a path no release can currently take. **The incompleteness is bounded by the declaration gate, not latent:** it is unreachable rather than merely unlikely, and it is routed as follow-up rather than absorbed silently.

**There is no automated completeness enforcement for a task-artifact close, and there will not be one from this change.** The two close-completeness checks iterate release-log rows, so a row-less release is invisible to both. That is why there is no false failure (favourable) and equally no enforcement (a real gap). Enforcement rests on the close-time completion-verification table plus the additive evidence gate. Proportionate under the governance domain guide's contraindication against research-grade controls at this posture — but recorded as a gap, not dressed as coverage.

**The introducing release ships the mechanism without exercising its crux.** This release resolves to the governance domain, so it takes the deployable branch; the terminal-record substitution ships correct and fail-safe but unexercised. It **does** dogfood the additive mode, recording acceptance for its own two knowledge artifacts while closing deployable. The milestone's original claim to *prove* the path by exercising it was **withdrawn rather than left to fail** at review — the honest statement is ship-and-document, and the first genuine end-to-end close of this class happens in a later release.

**Reversibility is genuinely cheap, for a structural reason rather than a hopeful one.** Because the branch is declaration-gated and no release declares the class, no issue's closure state becomes path-dependent; reverting the merge orphans nothing and requires no migration and no backfill. **The cheap window closes at the first task-artifact-class release, not at this one** — which cannot occur before this one ships. This corrects the planning-stage reading, which placed the window's close at this release's own Stage 13.

**What this record does not settle.** Whether any *particular* body of work is task-class remains a declaration the release makes and the operator reviews — this record makes the class expressible and its close evaluable; it does not classify anything. Nor does it author the best-practice guide for the class: that guide's absence *is* the codified demand signal, and a guide-less named class is already the majority state rather than an exception.

## Reversibility

**CHEAP-to-MODERATE · confidence HIGH.** Every edit is additive prose or a criterion-body refinement inside an existing table: no executable, no schema shape, no routing primitive, and no continuous-integration engine is touched, and no data migrates. Reverting the release merge in first-parent form returns every surface in one operation. The pre-cutover corpus is untouched by construction, since the branch is declaration-gated and every new clause carries an introducing-release-exempt cutover.

The one condition that would make it expensive is named plainly rather than left implicit: **a subsequent release actually closing as task-artifact class.** From that point, reverting the branch would leave a closed release without a lifecycle state. That cannot happen before this release ships, so the window closes at the first such release — not at this one.

## Related ADRs

- **The deliverable-domain axis ADR.** Establishes the axis this record consumes and settles the direction that its `domain`-named fields are disambiguated by indexing rather than renamed. This record adds a value to that axis and registers it in the index that decision prescribed; it introduces no new axis.
- **The design-gate conditioning ADR.** The closest structural sibling — a gate conditioned on a declared delivery property rather than forked into a parallel path. This record applies the same shape at the close boundary.
- **The plan-file claim-time stamping ADR.** Governs this release's own identity: the plan is slug-primary and carries a placeholder resolved at the atomic claim. Independent of this record's subject, but the reason this release's artifacts carry no version stem.
- **The ADR-number-binds-at-merge ADR.** Governs this record's own number, which was re-derived against the mainline at Engineering Commit 0 rather than pre-allocated.

## References

- #101 — the keystone card: add a non-deliverable / task-artifact lifecycle that closes on artifact-acceptance rather than deployment. The originating work item this record decides.
- #335 — codify the host-API typed-field discipline as a K1 standard. One of the two knowledge artifacts whose acceptance this release records additively.
- #21 — author the orchestration-mechanisms K1 discipline doc. The second such artifact.
- #351 — the deliverable-type axis this record's branch reads. Closed; the external dependency, satisfied.

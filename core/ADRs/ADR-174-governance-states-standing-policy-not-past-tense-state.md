<!-- reference-durability: allow-link -->
---
title: "ADR-174 — A governance spec states standing policy, never a past-tense claim about repository state"
status: Accepted
date: 2026-09-01
release: label-and-reference-integrity
deciders: "Stage 5 Solutioning spoke (three-option analysis on the disposition branch, two on the declaration branch) + Stage 6 Engineering spoke (build, re-measurement) + Collective Review (the irreversible label cascade is gated separately at Stage 9)"
tags: [label-taxonomy, label-grammar, label-parity, governance-drift, standing-policy, verdict-class, fail-open, ADR-070, ADR-155]
source_observations:
  - "A governance section headed with a past-tense removal claim asserted that four default labels had been removed as not applicable. All four were live. The document stated a completed action that never happened, and had been stating it for long enough that nothing noticed."
  - "The parity gate read both surfaces and could not name the disagreement: it classified the four rows as live-but-unregistered, the same class as a label nobody had ever declared. The two conditions have opposite remedies — an unregistered row may simply need registering, whereas a declared-removed-but-live row means one of the two surfaces is lying — so folding them into one class discarded the only information an operator needed."
  - "The same document declared three concrete triage-flag rows that had never been created. A tree-wide search found only documentary mentions and no application site; the skill that runs the triage stage performs no label operation at all. Their lifecycle metadata referred to a triage-run process the current pipeline does not implement."
  - "Both findings are the same error at two altitudes: a spec asserting a fact about repository state, in a tense that cannot stay true. One asserted a past deletion; the other asserted a present existence. Facts rot; policies do not."
  - "All four declared-removed labels carry GitHub's stock default colour and description verbatim and had zero carriers, open and closed, against controls that fired. The deletion's blast radius is therefore four label objects whose entire durable state is four name/colour/description triples — but the labels are platform defaults, and the taxonomy already documents an ungoverned path by which an unrecognized label enters the live set. A one-time deletion does not keep them deleted."
  - "The consuming gate's clean verdict was computed by filtering the primitive's output for the class values it already knew and testing those extractions for emptiness. A row of any other class matched no filter and was discarded, after which the emptiness test passed — so adding a verdict class would have made the gate report parity while holding a finding."
---

# ADR-174 — A governance spec states standing policy, never a past-tense claim about repository state

## Status

**Accepted.** Authored at Engineering for the `label-and-reference-integrity` release.

**Numbering provenance.** Held **ADR-174** branch-local, allocated as the next free number across both ADR directories at authoring time. If the mainline claims 170 first, `release/tools/renumber-adr.py` renumbers this record at merge and in-release citations that read "ADR-174" denote it.

**Numbering provenance — `170 → 174`.** Held **ADR-170** branch-local; renumbered to **ADR-174** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 170. In-release citations that read "ADR-170" denote this record.

## Context

A K1 governance spec carried a section asserting that four default labels "were removed as not applicable to a single-operator PMO", and listed them with a reason each. All four were live in the repository. The section was not ambiguous or out of date at the margin — it stated a completed action that had not been completed.

Two things had to be decided, and they turned out to be one thing.

**First, what to do about the four rows.** Two branches were live and each was individually coherent. The document could **withdraw** the table — delete it with a rationale, which is cheap and revertible and makes the false claim go away. Or the platform could **register** the four rows as intentional members of the canonical set, which is equally cheap and makes the document agree with the world.

Withdrawal makes the document *silent* rather than *true*. The four rows then sit permanently in the gate's unregistered-label class with no record of why they are unwanted; the institutional judgment that produced the exclusion is destroyed rather than corrected; and the same four names keep reappearing in every parity run with no governance basis to appear against. Registration is worse: it canonicalizes four labels that have zero carriers and a written rationale for *not* wanting them, converting a false claim into a false endorsement.

**Second, why the false claim was invisible.** The parity gate reads both surfaces — the declared set and the live set — and therefore had, in principle, everything needed to notice. It could not say so, because its vocabulary had two verdicts: a canonical label absent from the live set, and a live label registered nowhere. A declared-removed-but-live label landed in the second class alongside labels nobody had ever mentioned. Those two conditions have **opposite remedies**: the unregistered one may simply need registering, while the declared-removed one means one of the two surfaces must change. Collapsing them threw away the only fact that distinguishes them.

**Third, the same error at a second altitude.** The same document declared three concrete triage-flag rows that had never been created and that nothing applies. A search across the tracked tree returned only documentary mentions, no application site, and the skill that runs the triage stage performs no label operation whatsoever. Their lifecycle metadata cited run numbers from a backlog-triage process this pipeline does not implement. The first case asserted a past deletion that had not happened; this one asserts a present existence that has not happened. Same failure, opposite sign.

## Decision

**A governance spec states standing policy in the present tense. It never asserts a past-tense fact about repository state, and where the declared and actual states disagree, the state is reconciled to the policy while the gate reports the gap as its own verdict class rather than folding it into an existing one.**

Three obligations follow, and none of them substitutes for the others.

**1. Convert the claim, do not delete it.** The section becomes a present-tense exclusion policy: these labels are *excluded from this platform's canonical set*; a label named here is *expected to be absent*; its presence is a *finding*. That sentence is true before the labels are deleted, true after, and true again if one reappears. The historical form was true only in the window between a deletion and the next change — and its rationale, which is the part worth keeping, survives the conversion untouched.

This matters because reappearance is expected rather than hypothetical. All four are platform defaults, and the taxonomy already documents the path by which an unrecognized label enters the live set: applying one to an issue brings it into existence with a default colour and no description. A section headed with a past-tense removal claim would be false again the moment one returned, and nothing would notice. A standing policy plus a verdict class makes the third case observable.

**2. Give the disagreement its own verdict class.** The gate gains a third class naming a live label the grammar declares excluded, distinct from the unregistered class because the remedies are opposite, and mutually exclusive with it so no row is double-counted. The class is routed through the same escalation path as every other arm rather than through a structurally non-escalating emitter — an unresolved contradiction between two governed surfaces is a real finding.

**3. Withdraw a declaration nothing implements; do not materialize it.** A declared-but-never-created row whose only appearances are documentary is withdrawn, with the withdrawal basis recorded next to the names so a future reader finds a decision rather than a gap. Creating it instead would add live labels nothing applies — precisely the unused row a later audit proposes deleting, which is the churn loop this decision exists to break. The **group** stays: it is grammar, and a deployment that runs labeled triage contributes its own rows into it.

**One consequence of decision 2 is structural rather than editorial.** A gate that gains a verdict class must have a consumer that cannot silently drop one. The consumers in this cohort selected the classes they knew by value and tested those extractions for emptiness, so a row of any other class was discarded and the emptiness test then reported clean. Guarding the output's *shape* cannot see this — the primitives emit a fixed number of fields, so a new class preserves column count and order perfectly while the filter selects on the column's value. The consumers therefore route unrecognized class values into a residual bucket that reports them, and gate the clean verdict on the output being empty rather than on the known extractions being empty. **An unrecognized verdict is a finding, never an absence.**

## Decision kernel (version-agnostic)

> A governance spec asserts standing policy in the present tense, never a completed action or a current fact about state outside its own file. Where the declared and actual states disagree, reconcile the state to the policy and give the disagreement its own verdict class — never fold it into a class whose remedy is different. A consumer of a classified verdict stream treats an unrecognized class as a finding, never as an absence, because a new class preserves output shape perfectly and no shape guard can see it arrive.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Withdraw the table** with a rationale | Rejected | Makes the document silent rather than true. Destroys the institutional judgment instead of correcting it, and leaves the four rows recurring in the gate forever with no governance basis to appear against. |
| **Register the four rows** as intentional canonical members | Rejected | Canonicalizes four labels with zero carriers and a written rationale for not wanting them — converts a false claim into a false endorsement. |
| **Convert to standing policy + delete the labels + new verdict class** | **Selected** | The only option that makes the document true rather than silent, keeps the rationale, states the exclusion in a tense that cannot rot, and makes a reappearance observable. |
| Declare the exclusions in a **methodology pack** rather than in the grammar | Rejected | The pack label facet is a *contribution* surface — unioned across selected packs and overridable by operator-local rows. An exclusion a pack can be added to override is not an exclusion. |
| Give the excluded table a **colour column** so its rows are reconstructible | Rejected — on consequence | The row parser keys on a backticked hex in column two, and that is the only structural reason the table stays out of the canonical union. A colour column would make all four rows canonical, and once the labels are deleted they would flip from the warn-capable excluded arm into the enforce-capable absent arm. |
| **Materialize** the three declared triage rows | Rejected | Creates three live labels nothing applies, and stacks a second repository-state action onto a release already carrying an irreversible one. |
| Add the new class to the consumer as **one more value selector** | Rejected | Re-commits the defect at the next class. The fourth class hits the identical wall. |
| Gate the clean verdict on **row count alone**, with no residual bucket | Rejected as sole answer | Makes the false green unreachable but reports an unrecognized row with no detail — silent-but-red. Both guards ship, because a row-count guard alone yields a red with no content and a residual bucket alone is defeated by a malformed sub-field row. |

## Consequences

**The gate can now say the thing it previously could only imply.** A contradiction between two governed surfaces reports as a contradiction, with a remedy the operator can act on from the token alone.

**Deleting the labels is irreversible and is deliberately not part of this decision's execution.** Label state lives outside version control: reverting the commit that declared a row does not delete the label, and no snapshot in this repository holds one. The reconstruction record is an operator-captured live-label listing taken immediately before the deletion — which, at zero carriers, is *complete* rather than partial, and that is exactly why it is the right mitigation. The deletion is an operator-run action gated at plan review, never executed from an engineering agent.

**The zero-carrier measurement is a default-to-zero classification and must be re-taken.** It is the single measurement the delete branch rests on, over a population that can grow: one carrier appearing later invalidates the zero-data-loss premise. Re-measure immediately before authorizing the deletion, not from a stored figure.

**A group may now legitimately contribute no rows, and must say why.** Two of the taxonomy's groups now contribute none, for two different reasons — one because its members are namespace patterns rather than an enumerated set, one because this deployment runs no labeled triage process. An empty group is a grammar slot awaiting a deployment that needs it. Each states its reason inline, so the gap reads as a decision rather than an omission.

**Renaming the policy section is fail-loud, not silently empty.** The section is parsed by its heading, so a rename would empty the excluded set and the new class would report clean — the same defect one layer up from the one this ADR closes. The parser therefore refuses: when at least one markdown source is supplied and none carries the header, it exits on the existing "registry moved or renamed" contract.

**The residual-bucket obligation generalizes beyond this gate.** The fail-open shape was a class rather than an instance across the whole cohort of checks that consume a classified verdict stream. Every one of them now buckets unrecognized values. The cost is two lines per consumer; the property bought is that a future class reports without requiring a consumer edit.

**The next two candidates are already visible.** Two further platform-default labels remain unregistered and out of scope here. They are the same class this ADR governs, and adding them later is a table row rather than a new decision — which is the test of whether this record generalizes.

## Reversibility

**CHEAP / Confidence HIGH** for every content change — the policy conversion, the withdrawn declarations, the new verdict class, the consumer rewrite, and the pack row. All are repository content, revertible by reverting the commit.

**IRREVERSIBLE / Confidence HIGH** for the label deletions this decision authorizes but does not execute. Label state is not in version control; a revert of the declaring commit does not restore a deleted label, and any issue carrying one loses it permanently. Measured blast radius at authoring time: four label objects, zero carriers, complete durable state captured as four name/colour/description triples. Process weight scales accordingly — the deletion carries an explicit sign-off gate with a rollback-infeasibility statement, while everything else carries lightweight confirmation. Rollback ordering matters if it is ever needed: revert the content first, then re-create the labels, so the gate does not immediately re-report the re-creation as a fresh contradiction.

## Related ADRs

- **ADR-070** — fixes the methodology-pack composition grammar: the grammar owns groups and rules, packs contribute concrete rows. This ADR homes the exclusion policy in the grammar under that division of authority rather than working around it, and its reasoning is what disqualifies the pack as a home.
- **ADR-155** — added the eighth label group under the same grammar-owns-groups division, and established that testing every existing group and recording why each fails is the way a new member of a closed set is admitted. This ADR applies the same method to a verdict class rather than a label group.

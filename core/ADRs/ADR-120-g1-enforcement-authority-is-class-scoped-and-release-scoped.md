<!-- reference-durability: allow-link -->
---
title: ADR-120 — G1 enforcement authority is class-scoped and release-scoped; the evaluated population is the deploying milestone
status: Proposed — flips to Accepted at this release's operator gate. The flip is verified against this file's `status:` field, never inferred from milestone closure, a review comment, or a plan row.
date: 2026-08-06
release: release-check-enforcement-gates
deciders: "Workspace owner (scope-lock granted at Collective Review, with one Blocker deferred into Engineering as a gating acceptance criterion); two-axis scope model designed at Stage 5 Solutioning across two design passes and two independent adversarial reviews; resolution mechanism re-designed on remand; authored at Stage 6"
tags: [architecture, governance, gate, enforcement, scope, deploy-check, triage-readiness, fail-open, reversibility-cheap]
source_observations:
  - "The deploy-time G1 gate held one authority over the entire open `status: bundled` population. Re-measured at build time by driving the shipped evaluation region over the live population: 258 structural findings backlog-wide, of which 1 belongs to the release being deployed. A gate whose blocking set is 258 findings across dozens of milestones cannot be cleared by the operator shipping any one of them."
  - "The G1 criteria are written against the governance-intake field set. Applying them to form families they were not written for is the false-positive direction the gate's own template-awareness precondition already names. Measured: 108 of the 258 findings sit on cards outside that family — 94 of them on the label-count criterion alone, which is the criterion those cards are structurally guaranteed to fail."
  - "The bundling gate already exempts `sub-task decompositions within an already-bundled parent` by name. The deploy-time gate never received that exemption. Measured: 90 of 256 bundled cards carry the sub-task label, and 24 of the 31 cards in this release's own milestone are pipeline stage sub-tasks."
  - "Two axes were measured separately and both are load-bearing. Class-scope alone leaves 150 gating findings backlog-wide; milestone-scope then takes that to 1. Neither axis alone yields a gate an operator can clear."
  - "The first design of the resolution mechanism could not distinguish `no release in flight` from `in flight but unidentified` from `identified but wrong`, and every one of those states resolved to a verdict indistinguishable from a clean run. Reproduced directly: an issue query filtered by a nonexistent milestone returns an empty list at exit 0 with empty stderr — byte-identical to a clean release."
  - "The re-designed validator was specified without pagination. `gh api` does not auto-paginate and the default page is 30 rows. Measured at build time against the live tracker: the open-milestone set is 45 and the default read returns 30, so the specified form was ALREADY dropping a third of the population it was validating against — a legitimate in-flight release beyond the first page would have been reported as a nonexistent milestone, in a gating finding whose stated reason was false."
  - "The correct paginated form of that exact call already existed in this repository, in a sibling card's edit surface in this same release, above a comment stating the precise harm: a truncated membership set turns every unlisted card into a phantom miss and must never be silently accepted."
  - "A verdict-enum-decoupled-from-emit resolver already exists in the same file for the same reason, and an emitter that is structurally incapable of incrementing the issue counter already exists beside it. Neither had to be invented."
---

# ADR-120 — G1 enforcement authority is class-scoped and release-scoped; the evaluated population is the deploying milestone

## Status

**Proposed** — authored at Stage 6 per the Stage-6 ADR-authoring precedent, flipping to **Accepted** at this release's operator gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering provenance — allocated `120`, and the contention is expected rather than avoided.** The Stage-4 plan named ADR-119; that number bound to a sibling release which merged mid-remand. The re-design then allocated 120 against a mainline that topped out at 119. At authorship time **two live sibling release branches each also hold an ADR-120**, and the first instinct — step past the contention to 121 — was tried and is **wrong**: the numbering gate enforces a **gap-free** global sequence, so a record merging at 121 while 120 is unclaimed on the mainline lands a gap that fails every subsequent pull request. This was not reasoned out; it was caught by running the governed checker, which rejected 121 with `GAP: the global sequence 001..121 is not contiguous`. The rule the ADR README already records is the operative one: **an unmerged claim does not bind the sequence, first-to-merge takes the number, and the other claimants renumber at merge.** This record therefore holds 120 branch-local and expects to renumber if a sibling merges first; each hop appends its own `old → new` provenance note here.

## Context

`deploy.sh --check` Check 22 is the deploy-time enforcement surface for Gate 1 (Triage Readiness). It exists because Stage 2 Triage was the only early stage with no tooling enforcement at all. It was shipped in warn mode with a graduation to enforce deferred until a shakedown window showed no false positives.

That graduation has been blocked ever since, and the reason is not the check's accuracy. It is the check's **authority**, which was never scoped. Check 22 held one undifferentiated FAIL-capable authority over every open `status: bundled` issue in the tracker, on every criterion, in every form family, in every milestone. Three consequences follow, and they compound:

**The blocking set is not drainable.** Measured at build time by driving the shipped evaluation region over the live population: **258** structural findings across the backlog. An operator shipping one release cannot clear defects belonging to dozens of other releases, so the flip to enforce is permanently deferred — not because the gate is wrong, but because it blocks on a set nobody owns.

**A large share of those findings are the gate speaking outside its competence.** The G1 criteria are authored against the governance-intake field set, and the gate's own template-awareness precondition already names the false-positive direction that follows from applying them elsewhere. **108** of the 258 sit on cards outside that family, **94** of them on the label-count criterion alone — a criterion those cards are structurally guaranteed to fail, with a remediation that instructs a correctly-labelled author to break their card. Ninety of those cards are the pipeline's own stage sub-tasks, a class the **bundling** gate already exempts by name and which this surface never received.

**And the gate blocks the wrong transition.** A gate blocks the transition it guards. A backlog-wide gate at deploy time guards nothing in particular: it is a corpus sweep wearing a gate's authority.

There is a fourth problem, and it is the one that made this hard rather than merely tedious. **Narrowing the gate to "the release being deployed" requires knowing which release that is** — and a deploy-time check has no reliable, free channel to that fact. Every mis-resolution is silent: an issue query filtered by a nonexistent milestone returns an empty list at exit 0 with empty stderr, which is byte-identical to a clean release. A narrowed gate that resolves the wrong scope reports a clean run and blocks nothing, and at warn mode it also silently empties the very shakedown log the graduation decision is made from. So the narrowing that fixes the drainability problem introduces a fail-open one, and the fail-open one is worse, because it is invisible.

## Decision

**Split Layer-B into two authorities, and give the gate a resolution contract that can say it does not know.**

**1. Two surfaces, one check.**

- **Layer-B(d) — recommend-tier detection.** Every finding outside the gate's FAIL-capable authority is emitted at recommend-tier rather than gating-tier, never FAIL-capable.
- **Layer-B(g) — release gate.** Evaluates the milestone being deployed and holds the only authority to block.

**What shipped, stated against the code rather than against the intent.** Layer-B(d)'s **tier semantics shipped; its population did not.** Check 22 holds exactly **one** issue-list query and that query carries `--milestone`, so both surfaces read the *same* milestone-scoped population and differ only in tier. There is no backlog-wide sweep. The two-authority split is real and is what this record decides; the claim that detection continues to cover the whole backlog is **not** true of the shipped implementation, and every statement of it in this record has been reconciled to the implementation rather than left standing.

The consequence is the whole point of stating it: a structural G1 defect on a bundled card in **any other milestone** is not demoted to recommend-tier — it is **never evaluated**, and emits at no tier at all. Measured live at `2026-08-07T20:07:19Z` (baseline pinned per audit-baseline discipline; the population is mobile and this figure is not a constant): **207** open `status: bundled` issues spread across **48** milestone buckets, of which **10** sit in the deploying milestone and **197** across the other 47 are outside every query the check makes. The Stage-8 QA measurement of the same structure at its own earlier anchor read 204 of 235 across 46 milestones, and 15 of 16 measurable G1-01 defects emitting at no tier. The two anchors differ because the backlog moved; the **structure** they measure is the same and is not a function of the anchor.

**This is a description correction, not a scope reversal.** The milestone-scoped evaluation is the decision, it stands, and nothing here re-opens it. What was wrong was the record, not the code.

**2. The enforce-population contract.**

> `authority = structural ∧ F1 ∧ ¬sub-task ∧ in-deploying-milestone`

`structural` is the existing criterion-type partition, so judgment criteria are outside the enforce population under every population choice, including criteria added later. `F1` restricts authority to the governance-intake family the criteria were written for. `¬sub-task` applies an exemption the platform had already decided at the bundling gate. `in-deploying-milestone` makes the gate guard the transition it is attached to.

`¬sub-task` moves **zero** cards today: every bundled sub-task currently carries zero intake-tier labels and is already outside F1. It is written as a real predicate anyway, because that escape is a coincidence of one template's label set rather than a construction — a single label edit re-arms a configuration in which the pipeline's own bookkeeping cards gate the release they are bookkeeping. A guard whose cell is empty is still a guard; deleting it because the cell is empty is how the cell gets filled.

**3. Release identity resolves to one of four states, and each routes to exactly one existing emitter.**

| Verdict | Meaning | Disposition |
|---|---|---|
| `RESOLVED` | a candidate was derived **and validated present-and-open** | gate the resolved milestone |
| `NONE` | nothing asserted and no release branch attached | **not applicable** — evaluate nothing, block nothing. Because the two surfaces share one milestone-scoped query, "evaluate nothing" is **total**: no detection runs either, and the run emits no G1 finding at any tier |
| `UNRESOLVED` | a release context exists but no title validated, or the validator could not be read | fail-closed if **asserted**; advisory if **detected** |
| `INVALID` | a candidate was derived and rejected — absent, or present but closed | fail-closed if **asserted**; advisory if **detected** |

Three properties of this contract are load-bearing and are stated rather than left to the reader.

**Provenance decides the disposition, not the outcome.** A candidate supplied by an operator through the environment is an **assertion**: refusing to gate on a scope you were told to use and could not honour is correct, so it fails closed. A candidate derived from a branch name is a **detection**: a regex fired with no operator intent, so it degrades to advisory. Inheriting "fail closed" for both turns ordinary release-workflow states — a milestone closed at release close while a worktree is still attached, an offline run on a release branch, an unrecognized branch-naming form — into gating findings on work nobody asserted.

**The validator reads its population to exhaustion.** The milestone membership test is paginated. This is the single most consequential line in the mechanism: the platform's issue-tracker API does not auto-paginate and its default page is 30 rows, while the open-milestone population measured at build time is 45. An unpaginated read was therefore not a latent hazard but an **active** one, dropping a third of the set it validated against and reporting a legitimate in-flight release as a nonexistent milestone — a gating finding whose stated reason is false, with no arm distinguishing *truncated* from *absent*. The paginated form was not invented here; it was already in this repository, in a sibling card's edit surface in this same release, above a comment stating exactly this harm. The state filter is also deliberate: reading each milestone's state is what makes *closed* and *absent* two different answers with two different remediations.

**A zero read is never evidence of absence.** If the milestone set comes back empty, or the validator cannot be reached, the verdict is `UNRESOLVED` and never `INVALID`. A probe whose population came back empty has not shown the candidate is missing; it has shown the probe did not run.

**4. Nothing here changes posture.** The check still ships warn. This decision changes **what would block if the mode were flipped**, never whether it is flipped.

## Alternatives Considered

**Leave the gate backlog-wide (status quo).** Rejected on measurement, not on taste: 258 gating findings across the backlog, versus 1 for the release being deployed. The graduation to enforce has been deferred release after release, and this is why. Keeping it also keeps the gate FAIL-capable against form families its criteria were never written for.

**Narrow by class only — restrict authority to the governance-intake family and drop the milestone conjunct.** This is the smallest possible change and it eliminates every release-identity failure mode with it, which is a genuine argument. Re-measured at build time rather than assumed: class-scope alone still leaves **150** gating findings backlog-wide. That is a smaller undrainable set, not a drainable one. The milestone conjunct is load-bearing.

**Narrow by milestone only — keep every form family, gate the deploying release.** Rejected: it leaves the gate rendering verdicts on cards whose forms do not carry the fields being checked, which is the false-positive class the check's own template-awareness precondition names. It would also gate this release on its own 24 pipeline stage sub-tasks.

**Shift the check left to the bundling transition instead of deploy time.** The right long-term answer, and it is recorded here as a named successor rather than dismissed. The bundling gate already declares a body-compliance precondition; it has no runner. Building that runner is a larger change on a different surface, and it does not remove the need for a correctly-scoped deploy-time gate in the interim.

**Resolve release identity from the release plan file added on the branch.** Measured and rejected: the plan filename does not reliably carry the milestone title. Re-derived at build time against the fully-paginated milestone universe, **28 of 154** plan basenames match a milestone title, across several incompatible naming conventions. The same measurement run against a truncated milestone universe returns 18 of 154 — which is how the design's original figure was produced, and is itself a demonstration of the pagination defect this record exists partly to close.

**Resolve release identity from the release ledger.** Reviewed and rejected **for now**, with reasons, and recorded as the named successor: the ledger carries no in-flight state, its row grammar cannot match a release whose version is not yet bound, and making it a resolver requires writes at two additional pipeline stages — a governance change on the close-out surface, inside a release already carrying three other edits to the same file.

**Add a shared availability helper for the degraded-state postures across the sibling cards editing this block.** Offered twice during this release and declined twice, including here. The postures are deliberately different shapes — one withholds a single criterion across the whole population, another withholds a family assignment for part of it — so a shared helper would have to parameterize the withheld scope, which is more surface than it removes.

## Consequences

**Positive.**

- The gate becomes drainable: the blocking set for this release is 1 finding, and it is a genuine, in-scope, two-minute defect on one of the release's own member issues. That is the gate working.
- The graduation to enforce becomes a decision about a bounded set rather than an unbounded one. The measured shakedown signal also stops being dominated by findings on cards no release owns.
- Three previously-indistinguishable states — no release in flight, unidentified release, invalid release — become three distinct log shapes with distinct reason tokens. A mis-resolved run is now visible in the same log the graduation decision reads.
- No new emitter, no new check, no new file, and no third milestone-lookup form. The resolver copies a verdict-enum-decoupled-from-emit shape already in the file; the not-applicable state routes to an emitter that already exists and already cannot escalate.
- Within the deploying milestone, a finding that used to gate and no longer does is still emitted, at recommend-tier, with its tier named in the message. **Detection coverage outside that milestone is not preserved** — see the corresponding entry under Negative, which is where this consequence actually lands.

**Negative, and stated rather than minimized.**

- **Findings outside the enforce population lose their teeth — and findings outside the deploying milestone lose their voice.** Two different losses, and the second is the larger one. *Within* the milestone, 108 structural findings move from gating to advisory: still reported, with nothing forcing anyone to act on them. *Outside* it, findings are not demoted — they are **not produced**, because the population is never queried. At the pinned baseline that is 197 of 207 bundled cards across 47 other milestone buckets emitting at no tier. The mitigation is therefore **only** the named bundling-gate successor; the backlog-wide detector is not available as a mitigation because it was not built. Stating it as one would be the same over-claim this ADR was corrected for.
- **The gate now depends on resolving a release identity**, which is a new class of thing that can be wrong. The four-state contract bounds *how* it can be wrong; it does not eliminate the dependency.
- **Validation proves existence, not correctness.** A candidate that resolves to a different, concurrently-open release passes validation untouched, and concurrent release branches make that reachable. This residual is **bounded by disclosure, not closed**: the resolved slug, the source that produced it, and the milestone-set denominator are logged before any finding, so a wrong scope is legible at read time rather than silent. This record does not claim otherwise, and a later summary of it must not either.
- **Branch-name detection is not total over naming history.** Two documented release-branch forms are parsed and both candidates are tried; a third form and any future variant resolve to advisory rather than to a false gating finding. Detached HEAD — which the session protocol prescribes at session end — and post-merge mainline both resolve to `NONE`. Layer-B(g)'s live window is therefore **an attached release branch during Engineering through Plan Review**, narrower than the stage range alone implies.
- **The warn-mode log now carries three row shapes where it carried one.** Any consumer counting gating rows must filter on shape rather than on presence.
- **One runtime message still asserts the detector that was not built, and is knowingly left in place.** The `NONE`-branch advisory emitted by the check states that *"the Layer-B(d) backlog-wide detector is unaffected and G1 defects remain visible at recommend-tier"*. Under the shipped single milestone-scoped query that is false: on `NONE` the whole evaluation is skipped and no G1 finding is emitted at any tier. It is **not** corrected here because this reconciliation is scope-locked to the record, and the file carrying that string is under concurrent edit by three sibling cards in this release; a text-only change to a four-way-contended surface buys a merge conflict for no behavioural gain. It is recorded here so a reader who finds the message and this ADR disagreeing knows which one is right — **this record is** — and so the correction is a known, owned follow-on rather than a rediscovery.

**Durability of the contract, stated precisely.** This contract is **fail-closed on an asserted-but-unresolvable or invalid release identity**, and **not-applicable when no release is in flight**. It is **not** fail-closed in the general sense: when no release identity is asserted, Layer-B(g) does not evaluate and does not block, by design. The property that makes the not-applicable branch safe is not a default value but the **emitter** — a helper that contains no mode branch and no issue-counter increment anywhere in its body, and therefore cannot escalate under any future mode flip. A reader summarizing this record as "fail-closed" has mis-stated it. This paragraph exists because an ADR outlives the release that wrote it, and a wrong durability claim outlives them both.

**What this record does not do.** It does not reverse the intake-scope determination that the population is bundled-only and is not extended to `status: proposed`. That determination is on the **status** axis, it remains true, and the two axes added here sit beside it. It does not change the check's mode. It adds, renumbers, removes and re-types **no** criterion.

## Reversibility

**CHEAP.** A single-commit revert restores the prior authority. Confidence **HIGH**. The check ships warn either way, so a revert never leaves a broken gate — only a wider advisory sweep. The residual is that deploys between merge and revert evaluate under the narrowed scope; since the mode is warn, the effect of that window is on the evidence log rather than on any blocked deploy.

## Related ADRs

- **ADR-111** — the priority-carrier decision this check's G1-06 criterion delegates to. Cited, not superseded; a sibling card in this same release performs that reconciliation.
- **ADR-115** — an ADR number is allocated at authorship and binds at merge, and only the mainline binds. This record's numbering provenance note is that rule applied twice.
- **ADR-092** — release identity is slug-primary and the version binds atomically at the release merge. This is why the resolver keys on a slug rather than on a version stem, and why a version-prefixed branch form must also be parsed.
- **ADR-033** — configuration belongs in configuration, not in conditionals baked into a methodology-neutral gate. The form-family partition this record scopes authority over is resolved from configuration for the same reason.
- **ADR-062** — an issue body is a historical record and is not rewritten to match a later decision.

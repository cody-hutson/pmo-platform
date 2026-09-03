<!-- reference-durability: allow-link -->
---
title: "ADR-183 — The behavioural-regression pass-rate floor and the boundary the gate binds at"
status: Accepted
date: 2026-09-02
release: regression-corpus-gates-releases
deciders: "Stage 5 Solutioning spoke (five-decision design with measured trade-off matrices) + Stage 6 Engineering spoke (record authored at Commit 0 under operator authorization at the Stage 5 gate) + operator GO at the Stage 4 plan gate"
tags: [behavioral-regression, pass-rate-floor, release-gate, major-release-boundary, warn-mode-initial, never-fail, gate-efficacy, platform-config, ADR-182]
source_observations:
  - "Measured over the whole tag history at the release baseline: 192 tags across 4 major families, with one clean major-bump event in 89 days — a minor-to-major ratio of roughly 48 to 1. A gate bound exclusively to the major boundary runs about quarterly and would ship months before its first real exercise."
  - "The standard that carries the platform's behavioural checks has zero fixtures. Its own procedure instructs the reader to prepare a test artifact and use a known-good one. It is an assertion bank, not a corpus: the missing layer is scenarios plus fixtures, which the bank never carried and structurally cannot carry."
  - "That standard is a registered template-sync mirror: the deploy machinery registers it as a mirrored reference, the source-tree copy is injected at package build time, and the shipped skill package carries it as an internal reference file. Editing it stales that package, which two independent freshness gates observe."
  - "A precedent gate in the same workflows directory already ships a warn-mode-initial posture with a documented graduation clause — a committed enforcement token, registration as a required status check, and removal of its path filter. It is titled a corpus gate and gates release-documentation completeness, so a second thing called a corpus gate in the same directory is a collision for readers, searches, and required-check names."
  - "A configuration field already exists that records a parse-rate floor as a single numeric value in the platform behaviour configuration, with its semantics stated elsewhere and its magnitude restated nowhere. That is a worked precedent for recording a threshold as data."
  - "An unresolvable numeric floor that defaults to zero satisfies every greater-than-or-equal comparison and greens the gate permanently. The platform already carries a contract for the opposite posture: empty means unresolved, never zero."
---

# ADR-183 — The behavioural-regression pass-rate floor and the boundary the gate binds at

## Status

**Accepted.** Authored at Engineering Commit 0 for the `regression-corpus-gates-releases` release, under the authorization the operator gave at the Stage 5 gate.

**Authorship note.** This record is owed by the corpus-and-gate half of the release, and it is authored here — at the first Engineering commit, by the runner half's spoke — because its decision content was settled in full at Solutioning and depends on no implementation. The spoke that builds the gate consumes this record; it does **not** author a second one, and it must not allocate another decision-record number for the same decisions.

**Numbering provenance — `178 → 181`.** Held **ADR-178** branch-local; renumbered to **ADR-181** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 178. In-release citations that read "ADR-178" denote this record.

**Numbering provenance — `181 → 183`.** Held **ADR-181** branch-local; renumbered to **ADR-183** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 181. In-release citations that read "ADR-181" denote this record.

## Context

The platform commissioned a standing behavioural regression corpus that runs as a pre-release gate on a pass-rate threshold. It does not exist. Continuous integration carries a viewer test suite — which tests a viewer, not a corpus of "this skill must still do these things" run against a floor before a release ships. As distribution goes public the stated risk becomes live: a regression breaks an adopter's install rather than only this instance's.

Two decisions were deferred to design: **what the threshold is and where it is recorded**, and **which release boundary the gate binds at**. Both were deferred because the commissioning work item correctly declined to guess them, and both have non-obvious answers.

**The boundary question is the one that nearly shipped a gate that cannot fail.** "Gate major releases" is the plain reading of the commission, and taken alone it is a trap. Measured over the whole tag history, this platform produces one clean major-bump event roughly every quarter against a minor cadence roughly forty-eight times higher. A gate bound *exclusively* to that boundary would run about four times a year and would ship months before its first genuine exercise — which is the never-FAIL anti-pattern arriving through the front door, shipped as infrastructure. A gate whose first real run is a quarter after it merges is a gate nobody has seen fail.

**The threshold question is really two questions**, and conflating them is how a magnitude ends up restated in four places. *What the number is* is a calibration judgment that will change. *Where it lives* is a structural decision that must not. The platform already carries a worked precedent for the second: a parse-rate floor recorded as a single numeric field in the platform behaviour configuration, its semantics stated in prose elsewhere, its magnitude restated nowhere.

**And a third force constrains where the corpus itself can live.** The standard that carries the platform's behavioural checks looks like a corpus and is not one: it has **zero fixtures**, and its own procedure tells the reader to go find a known-good artifact. It is an assertion bank. The layer the gate needs — scenarios plus fixtures — is the layer the bank never carried and cannot carry without becoming a different document. So the choice is not mechanize-in-place versus author-a-parallel-corpus. It is *supply the missing layer and cite the existing one*, which satisfies the duplicate-source discipline without needing a mirror registration. That reading matters mechanically as well as conceptually: the standard is a registered template-sync mirror shipped inside a skill package, so mechanizing it in place would have put executable fixtures inside a distributed documentation package.

## Decision

**1 — The pass-rate floor is `1.00`, recorded as a single numeric field in the platform behaviour configuration.** Every scenario in the corpus must pass. The field is the **one** numeric home: its semantics are stated in the decision record and in the regression standard, and **no other surface restates the magnitude**, so a recalibration is a one-line edit rather than a cascade. The value is a seed, explicitly marked for recalibration once enough releases have exercised it; the *recording surface* is not.

**A floor of one is chosen because the corpus is small and hand-authored.** A fractional floor on a two-scenario corpus is arithmetic theatre — it encodes "one of these may break" before anyone has observed which one does. When the corpus grows past the size where a single expected-open defect is normal, the floor is the thing that moves, and it moves in one place.

**2 — An unresolvable floor fails closed.** Empty means unresolved, never zero. A zero default satisfies every comparison and would green the gate permanently — the same absence-read-as-zero failure the runner's own zero-denominator rule exists to prevent, arriving from the configuration side instead of the report side.

**3 — The gate binds at the major-release boundary and runs advisory on every pull request.** These are two rungs of one gate, both legible in a single trigger block:

- The **binding** rung is the signed release tag matching the platform's major-bump output. It is machine-exact and inspectable without reading a script, which is what the commissioning criterion's stated verification method — inspect the workflow trigger — actually inspects.
- The **advisory** rung is filter-free and fires on every pull request. It carries no path filter at all, deliberately, because a path filter on a *regression* gate is self-defeating: the changes most likely to regress behaviour are exactly the ones a path filter would not have predicted.

Separating *where the gate runs* from *where it binds* is the whole mitigation for the cadence measurement above. It is what makes both control arms run continuously rather than once at authoring time.

**4 — The tag pattern is asserted by a committed fixture, not by reading its glob.** The filter must flag the major forms and must not flag the minor, patch, or single-digit-minor forms. The assertion runs through an entry point invocable locally **and** invoked by the job. A pattern verified only by a human reading the glob is unverified, and a release-boundary filter that silently matches nothing is indistinguishable from one that works.

**5 — The gate adopts the platform's existing warn-mode-initial posture,** from the precedent gate in the same directory, with **one deliberate divergence**: no path filter. The precedent's graduation clause has three steps — commit the enforcement token, register the context as a required check, delete the path filter. With no filter to delete, the clause collapses to two. The divergence is not a departure from the precedent; it is the precedent's own lesson applied.

**6 — No identifier this gate introduces carries the token `corpus`.** The workflow, its job, its status-check context, and its enforcement sentinel are all named for behavioural regression instead. A gate already in that directory is titled a corpus gate and gates something else entirely — release-documentation completeness. Two things called a corpus gate in one directory is a collision for readers, for searches, and, once registered, for required-check names.

**7 — The threshold comparison belongs to the runner, not to the workflow.** The workflow reads the floor from configuration and passes it to the runner as a command-line value; the runner performs the comparison and sets the exit status; the gate consumes **only** that exit status and never parses the report. This is what makes the release's one-definition-of-the-contract constraint structural rather than disciplinary: the workflow cannot restate a report field it never reads.

## Decision kernel (version-agnostic)

> A release gate has two independent properties — the boundary it **binds** at and the cadence it **runs** at — and collapsing them into one trigger is how a gate that cannot fail gets shipped. Bind at the boundary the commission names; run advisory everywhere, so both control arms are exercised continuously rather than at the boundary's cadence. Record the threshold's **magnitude** in exactly one numeric home and its **meaning** wherever a reader needs it, so recalibration is a one-line edit; make an unresolvable threshold fail closed, because a zero default satisfies every comparison and greens the gate forever. And keep the comparison in the executor rather than the gate wiring: a gate that consumes only an exit status cannot restate the contract it would otherwise have to parse.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Bind the gate to the major-release boundary only** — the plain reading of the commission | Rejected | Measured cadence puts the gate's first real exercise roughly a quarter after it merges. A gate nobody has watched fail is the never-FAIL anti-pattern shipped as infrastructure. |
| **Run the gate on every pull request as a blocking check** | Rejected | Over-binds. A behavioural corpus in its first releases will surface expected-open defects, and blocking every pull request on them converts the gate into an obstacle to be routed around — which is how a gate becomes a rubber stamp. |
| **Record the floor in the workflow file** | Rejected | Puts a calibration value inside gate wiring, where changing it is a workflow edit and where it is invisible to the configuration catalogue a reader consults. It also violates the commission's own criterion that the threshold be recorded rather than implicit in code. |
| **Record the floor in the regression standard's prose** | Rejected | Restating the magnitude in a document makes the document a second home for it; the two then drift on the first recalibration. The standard names the field **by role**, never its value. |
| **Set a fractional floor** — for example, most scenarios must pass | Rejected — for now, with the reversal condition stated | On a small hand-authored corpus a fractional floor encodes a tolerance nobody has measured. The floor is the calibration surface and it is expected to move; the recording surface is not. |
| **Mechanize the existing behavioural-check standard in place** as the corpus | Rejected | It has zero fixtures and its procedure tells the reader to supply one, so it is an assertion bank rather than a corpus. It is also a registered template-sync mirror shipped inside a skill package, so mechanizing it in place would put executable fixtures inside a distributed documentation package. |
| **Author a parallel corpus that restates the check definitions** | Rejected | Two homes for one fact. The corpus cites the check definitions by identifier and adds only the scenario-and-fixture layer; the standard keeps single-source authority over the definitions themselves. |
| **Design a gate posture from scratch** | Rejected | A worked warn-mode-initial pattern with a documented graduation clause already ships in the same directory. Extending it costs one committed token; inventing a second posture costs a second thing for an operator to learn. |
| **Have the workflow parse the report and compare** | Rejected | Puts a second reader of the report contract in the tree and makes the one-definition constraint a matter of discipline rather than structure. Consuming only the exit status makes the property hold by construction. |

## Consequences

**The gate is exercised every release and blocks roughly quarterly, and those are different facts.** A reader who sees the gate green on a pull request has learned that the corpus scored at or above the floor; they have not learned that a release was gated. Anyone auditing enforcement coverage must read which rung is which, not merely that the workflow exists.

**Registering the status-check context makes the gate's name expensive to change.** Renaming a required context breaks it silently — the old name simply stops reporting and the branch protection waits forever on a check that no longer runs. The naming decision above is therefore cheap now and expensive after registration, which is why it was decided rather than defaulted.

**The floor of one means a single expected-open defect fails the gate.** That is intentional at this corpus size and it is the property most likely to force a revision. Two remedies exist and the record deliberately does not pre-choose between them: raise the corpus's capacity to express an expected-failing scenario, or lower the floor. Whichever is taken, it is taken in one place.

**The standard becomes a pointer surface as well as a definition surface.** After this release a reader arriving at the behavioural-check standard finds the runner, the corpus location, the threshold named by role, and the failure semantics. The definitions stay there; the scenarios do not. A reader who expects the standard to be runnable will still be wrong, and the added section says so.

**The corpus is a new consumer of the eval-harness schema, so the schema now has a consumer outside the skill that owns it.** That is the condition under which promoting the runner to the shared kernel becomes worth revisiting — noted here so a future reader has the trigger written down rather than having to rediscover it.

**One package rebuild is now coupled to a documentation edit in a non-obvious way.** The standard is a registered mirror shipped inside a skill package, so editing it stales that package and two freshness gates observe it. The coupling is invisible from the standard itself, which is why it is recorded here.

## Reversibility

**CHEAP / Confidence HIGH for the whole design.** Every deliverable is additive — a new suite, a new workflow, a new configuration field, a committed posture token, and one bounded section in an existing standard. Reverting removes the gate and restores the current ungated state.

Per-decision, where the tiers differ:

- **The floor's value** — CHEAP / MEDIUM. One configuration line; the value is explicitly a seed pending calibration.
- **The floor's recording surface** — CHEAP / HIGH before consumers exist; it is the surface this record most wants to keep stable.
- **The binding boundary** — MODERATE / HIGH. Re-declaring it is cheap in the file and expensive in expectation once releases rely on the gate.
- **The corpus location** — MODERATE / HIGH. Relocating moves a directory and every pointer to it.
- **The gate's name** — CHEAP / HIGH before merge; **EXPENSIVE** once the context is registered in branch protection, because a renamed required context fails silently rather than loudly.
- **The posture** — CHEAP / HIGH. One committed token.

**The standing caveat, stated rather than buried:** once a corpus gate exists and passes, downstream releases begin relying on it. Rollback is cheap now and grows more expensive with each release that trusts the gate.

## Related ADRs

- **ADR-182** — decided that the output-scoring runner consumes the eval-harness schema the platform already ships and emits the report contract the framework already defines, and froze the runner's command-line signature and its closed exit-code set. This record binds to that signature from the other side: the workflow reads the floor from configuration and passes it as a command-line value, and consumes only the exit status. The two halves compose structurally — the runner owns the comparison, the gate owns the boundary, and neither restates the other's contract.

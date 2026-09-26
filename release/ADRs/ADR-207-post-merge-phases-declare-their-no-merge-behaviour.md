<!-- reference-durability: allow-link -->
---
title: "ADR-207 — Post-merge phases declare their --no-merge behaviour once; the deferral, the reports and the tests derive from the declaration"
status: Accepted
date: 2026-09-25
release: closeout-verification-rows-consistent
deciders: "Stage 5 Solutioning spoke (six-candidate design exploration) + independent adversarial design review + operator decision at the Collective Review scope-lock (Plan amendment 1: this record authored, ADR-158 left untouched, the structural first-statement arm added) + Stage 6 Engineering spoke (build, paired arms, structural first-statement check)"
tags: [close-out, no-merge, dry-run, membership, declaration, automated-closeout, paired-arms, first-statement-contract, ADR-158]
source_observations:
  - "The close-out tool's --no-merge deferred set existed as eight hand-written copies — four phase guards, two report lists, the --help text and one self-test loop — and a post-merge phase that carried none of them halted every --no-merge close with a false finding."
  - "The same phase's tag-to-Release limb halted the first dry-run over a release whose ledger row read VERIFIED: a fifth member of the class ADR-158 records as closed at four, missed by that ADR's census because the sweep dispositioned the phase by its ledger-parity limb alone."
  - "The closing release's own tag was excluded from the parity population only through ledger state — the in-flight set reads the row, which phase 6 flips — so the exclusion held on some paths and not others."
  - "The adversarial review found that no behavioural arm can tell a phase that defers through the declared helper from one that defers through its own hand-written guard, because both record the same observable; the one member another card added to the post-merge region in the same release was designed with a hand-written guard."
  - "The tool's --help renders the header comment line by line, so a check that a deferred phase is annotated reads one rendered line at a time; the header's inventory rows already wrap onto continuation lines."
---

# ADR-207 — Post-merge phases declare their --no-merge behaviour once; the deferral, the reports and the tests derive from the declaration

## Status

**Accepted.** Authored at Stage 6 Engineering for the `closeout-verification-rows-consistent` release. The design set this record's status to Accepted on the ratification of its record decision, and the Collective Review's decision to author it was that ratification. The `Proposed` status that review named applies to the release's other new record, which supersedes an earlier decision in part and is ratified at the release's close; it does not apply here.

**Numbering provenance.** Claimed as **207** against an anchor of **206** on `origin/main`, read from the repository's own ADR-numbering tool at Engineering Commit 0 rather than computed as one past the highest number visible on any branch. A sibling release branch carries its own branch-local claims on this number, and branch-local claims do not bind. The number binds at the Stage-12 claim, and in-release prose cites this record by slug rather than by number.

## Context

The close-out tool's `--no-merge` flag suppresses exactly one step: the merge of the Stage-13 chore PR. Every phase dispatched before that merge cannot consume it, so the flag changes nothing there. Every phase dispatched at or after it can, and those phases do not all respond alike. Some are unaffected and run as on a merge run. Some are not applicable, because their only input is the merge this run did not perform. One evaluates and records without blocking, because its verdict does not depend on the merge. The rest are owed on the follow-up run after the operator merges: the close steps that must follow the merge, and the assertions over something only the merge produces. That is four behaviours, not one.

The tool carried none of that as a declaration. The deferred set existed only as copies — a hand-written guard at the head of each deferring phase, a hand-maintained list in each of the two report renderers, a list in the `--help` text and a list in one self-test loop — and nothing checked the copies against each other. The tag-to-Release parity phase belonged in the set and appeared in none of the copies. So a `--no-merge` close halted there on a Release that the publish phase had itself deferred, one phase before the phases the report would otherwise have reached.

The same phase carried a second defect. Its tag-to-Release limb read the closing release's own tag as a sibling, and excluded it only through ledger state — the in-flight set, which reads the release's row, which phase 6 flips to `VERIFIED`. On a dry-run whose row already read `VERIFIED`, the exclusion did not hold, and the dry-run halted on a Release it had itself declined to publish. That is a member of the class ADR-158 records — a phase that aborts a dry-run on its own no-op — and ADR-158's census, which dispositioned this phase by its ledger-parity limb alone, missed it. This record carries that member here, in its own Context. ADR-158's decision is applied, not changed, so ADR-158 is neither amended nor superseded.

## Decision

**Every phase dispatched at or after the merge phase declares exactly one `--no-merge` behaviour — `run`, `skip`, `record` or `defer` — in one table inside the tool, and every surface that shows or enforces the membership derives from that table.**

- **The deferral.** One helper applies it, as the **first statement** of every phase the table declares `defer`, above every guard, so it fires before any network call. The helper decides from the table: a phase that calls it while declared anything else proceeds. A phase that defers through its own hand-written guard is non-conformant even though it records the same observable, and the self-test checks the first statement structurally for every `defer` row, with controls that show the check rejects a hand-written guard.
- **The reports.** Both renderers derive the deferred list from the table: the markdown report's deferred section and the JSON report's deferred array. A phase joins the list by its row, and neither renderer is edited.
- **The tests.** The self-test derives its membership, behaviour, report and help-parity arms from the table. A phase dispatched at or after the merge with no row fails the suite, and so does a row that names no such phase or declares a value outside the closed set.
- **The help text.** A `defer` row's `--help` inventory entry carries the token `DEFERS under --no-merge` on the line that names the phase. `--help` renders the header line by line, so the convention is what makes the token readable per phase; the table's own comment states it, and the self-test checks every `defer` row against it.
- **The own tag.** The closing release's own tag is partitioned out of the sibling and history parity population by its version — never by ledger state or phase order — and is asserted by its own limb under ADR-158's per-limb rule: for real at `--apply`, after the publish phase converges the Release; predicted at `--dry-run` only in the one bounded state the publish phase's own no-op produces, as a conjunction and never a mode-wide suppression; and, with the whole phase, deferred under `--no-merge`. The own limb reads neither exemption set, so neither key masks a genuine own-tag gap at `--apply`.

## Decision kernel (version-agnostic)

> In phased tooling where a mode flag suppresses one step, every phase that runs after that step declares its behaviour under the flag once, from a closed set, and every surface that shows or enforces the membership derives from the declaration; a phase that runs after the step without a declaration fails the tool's own tests. Membership is never restated per surface, because a restated set loses a member without any surface noticing — and a contract about how a member applies its declaration is checked by structure, because behaviour cannot tell a declared deferral from a hand-written one.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| A declared table, one helper as the first statement of each `defer` phase, and derived reports and tests | **Selected** | Composes with the phase record and the existing dispatch-to-record parse; the dispatch text is unchanged |
| A further hand-written guard in the omitted phase | Rejected | Reproduces the root cause: one more copy of a set that already lost a member |
| A presence lint over the post-merge phases | Rejected | A presence check passes on defective code, and the report lists stay hand-written |
| A dispatch wrapper reading a registry | Rejected | Silently narrows the self-test parsers that key on the dispatch lines' text |
| Dispatch-time function override | Rejected | Runtime redefinition is hard to audit and to restore inside the self-test harness |
| The declaration carried as dispatch-line comments, parsed at runtime | Rejected | The dispatch sits outside the function-only slice a test harness sources, so the parse would read nothing there |
| Behavioural enforcement of the first-statement contract only | Rejected | A hand-written guard records the same observable and passes every behavioural arm; the structural check is the only one that separates the two |
| A row-aware help-parity parse that reads each inventory row with its continuation lines | Rejected in favour of the stated name-line convention | Robust to wrapped rows, but its row-boundary parse needs its own controls; the convention keeps the check simple and the table's comment states it where a new row is written |
| A whole-phase dry-run prediction for the tag-to-Release phase | Rejected | ADR-158 rejects it at this phase: two of the phase's limbs are mode-invariant and must keep running at `--dry-run` |

## Consequences

**What improves.** The deferred set can no longer lose a member silently: a new post-merge phase costs one row, and a phase with no row fails the suite. The two report renderers, the help text and the self-test stop carrying copies of the set. A `--no-merge` close reaches every phase after the tag-to-Release phase, and a dry-run over a release whose row already reads `VERIFIED` reaches it too. The own-tag detection power at `--apply` is unchanged; only the finding's label and its mode branch change.

**What it costs.** Under `--no-merge` the tag-to-Release phase defers whole, including its offline limbs — the tagger-identity and ledger-parity checks — so a `--no-merge` pass reports none of them. They run on the follow-up `--apply`, which is mandatory to close the milestone and publish the Release, so no check is lost, only moved to the run that completes the close. The `--help` annotations remain documentation, but documentation the suite checks; the price is the name-line convention, which each new `defer` row must follow.

**What it does not do.** It does not change what `--no-merge` suppresses, the behaviour of any phase dispatched before the merge, or any phase's behaviour on a merge run. It adds no flag and no report key.

## Reversibility

**CHEAP · confidence HIGH.** One tool and one stage-spec paragraph. A revert restores the prior bytes, and the paired arms fail on a reverted tree, so a partial revert cannot pass the suite unnoticed. No `--apply` output changes except the own-tag finding's label, so a revert cannot strand a partially applied close.

## Related ADRs

- [`ADR-158`](ADR-158-dry-run-predicts-apply-asserts-mode-branch-placement.md) — dry-run predicts, apply asserts. Applied at the own-tag limb as a per-limb conjunction; not superseded and not edited. The class member its census missed is recorded in this record's Context.
- [`ADR-181`](ADR-181-adr-citations-bind-at-the-claim-not-at-authorship.md) — ADR citations bind at the claim, not at authorship. Governs this record's slug-token citation form and its numbering provenance.

## References

- #7465 — the card whose `--no-merge` and `--dry-run` halts at the tag-to-Release parity phase this decision resolves
- #5284 — the Phase C5 thread-lock card whose new post-merge phase joins the table as a `defer` row in the same release

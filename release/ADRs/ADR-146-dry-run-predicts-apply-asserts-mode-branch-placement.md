<!-- reference-durability: allow-link -->
---
title: "ADR-146 — Dry-run predicts, apply asserts: mode-branch placement in phased close-out tooling"
status: Accepted
date: 2026-08-27
release: ci-stable-under-transient-conditions
deciders: "Stage 5 Solutioning spoke (four-option design exploration; fork resolved on commit ancestry) + Collective Review (scope-lock; the second class member was admitted into scope) + Stage 6 Engineering spoke (build, sweep re-derivation, mutation verification)"
tags: [close-out, dry-run, apply, mode-branch, phased-tooling, automated-closeout, prediction, anti-vacuity, paired-arms, ADR-092]
source_observations:
  - "The same defect was found three times, in three separate releases, by three different stages, one instance at a time — each fix correct and correctly scoped to the instance in front of it, and each time the next instance surfaced later at greater cost."
  - "The convention the three fixes share exists only as three code comments inside one 12,000-line shell tool. A corpus-wide search for its wording outside that file returns zero files; the control search inside the file returns three hits."
  - "The third instance carried an in-code comment asserting the pre-branch ordering was deliberate. Commit ancestry falsified that: the comment is a git ancestor of the commit that ratified the convention, so it was never an exemption from the rule — it was an unreconciled predecessor the ratifying commits never swept back over."
  - "That comment's stated benefit is also unreachable in the case the acceptance criterion exercises. It promises the dry-run shows the exact bytes apply will write; the input it resolves is written by a phase that deliberately no-ops in dry-run, so on a first close it showed a failure state apply never enters."
  - "A structural sweep of all 36 phase functions found a fourth instance that no line-pinned reading could have reached: a phase with no mode branch at all, whose ledger-parity limb is off-by-one in dry-run by construction. Fixing the third instance alone only MOVED the halt to it."
  - "A presence check — does a mode branch exist in this function? — passes on every defective instance, because the branch was always present and merely stranded below an aborting return. Only a paired reachability arm distinguishes the two."
  - "The runner aborts the whole run on any non-zero phase, so a single mode-blind abort makes every later phase unreachable for any release that has not already closed — which is why these instances stayed invisible until the first genuine unclosed-release dry-run."
---

# ADR-146 — Dry-run predicts, apply asserts: mode-branch placement in phased close-out tooling

## Status

**Accepted.** Authored at Engineering for the `ci-stable-under-transient-conditions` release, under the Collective Review scope-lock that admitted the second class member into this card's scope.

## Context

The automated close-out tool runs a fixed sequence of phase functions in two modes. Under `--apply` a phase performs its write; under `--dry-run` it is supposed to *describe* the write without performing it. The runner is unforgiving about the boundary: every phase is dispatched as `phase_x || { generate_report; exit 3; }`, so **one non-zero phase terminates the entire run** and no later phase enumerates.

That structure creates a specific, recurring defect. Some phases resolve an input — a projector call, a presence check, a path — **above** their mode test. When that input is written by an *earlier* phase that deliberately no-ops under `--dry-run`, the resolution fails on the script's own no-op, the phase returns non-zero, and the run dies there. Not because anything is wrong with the release, but because a dry-run was asked to inspect an artifact the dry-run itself declined to create.

**The defect is invisible until the exact moment it matters.** Its trigger is a dry-run over a release that has not already closed — and until this release, no such run had ever completed far enough to reach these phases. Every prior dry-run in the tool's history was over an already-closed release, where the artifacts happen to exist. So the phases past the first mode-blind abort had never been exercised at all.

Three instances were found this way, one at a time, across three releases, by three different stages. Each fix was correct. Each was scoped to the instance in front of it. And each time, the next instance was found later, by someone else, at greater cost. The card that produced this ADR named that pattern in its own constraint section and asked for a sweep instead of a fourth point fix.

Two findings during that sweep are the reason this is an ADR and not a commit message.

**First, the third instance carried a comment asserting its ordering was deliberate** — that resolving before the mode branch let the dry-run show the exact bytes `--apply` would write. Read at face value, that is a genuine design fork: two siblings fixed one way, a third documented the opposite way. It resolves on ancestry rather than on preference. The comment was introduced five days *before* the commit that ratified the convention, and is that commit's git ancestor. There was never an exemption to reverse — only a predecessor the two ratifying commits never swept back over. The comment's promise is also unachievable in the case the acceptance criterion exercises: the input it resolves is the release note, and the note-scaffolding phase writes nothing in dry-run, so on a first close the pre-branch resolution showed not the apply bytes but a failure state `--apply` never enters.

**Second, the structural sweep found a fourth instance that no line-pinned reading could have reached.** A phase with **no mode branch at all**, whose ledger-row-parity limb is off-by-one in dry-run by construction: the upstream ledger row lands before close-out runs, while the downstream row is added by a phase that writes nothing in dry-run. Fixing the third instance alone would have **moved the halt to it** and left the acceptance criterion failing exactly as before.

The root cause of all four is the same, and it is not any of the four sites. **The convention exists only as three code comments inside one 12,000-line file.** A corpus-wide search for its wording outside that file returns zero files; the control search inside returns three. A rule with no governed home is a rule that gets rediscovered, one instance at a time, forever.

## Decision

**In phased dual-mode tooling, `--dry-run` PREDICTS and `--apply` ASSERTS — and the mode test's placement is a positional rule with two boundaries, not a preference.**

**The rule.** The `MODE == dry-run` test is placed:

- **BELOW** every guard whose inputs are mode-**invariant** *and* whose `--apply` behaviour is something other than performing the phase's write — a SKIP, a deferral, a malformed-input failure. Predicting "would do X" below such a guard would be a **false prediction**, and surfacing a genuinely bad input at dry-run is what dry-run is for.
- **ABOVE** every statement whose input is written by a phase that no-ops under `--dry-run`. Resolving one of those can only fail on the script's own no-op, and because the runner exits on any non-zero phase, that abort makes every later phase unreachable.

This is deliberately **not** "put the mode test first." The literal-first-line shape is the weaker of the two sibling precedents, and it is wrong wherever a phase carries mode-invariant guards: a phase whose `--apply` path SKIPs must not predict that it will write.

**Two constraints make the prediction safe.**

1. **The prediction is STATIC.** It states what `--apply` will do; it does not pre-evaluate any of it. A dry-run limb that stats a file, reaches a remote, or reads a projector exit code to recover fidelity is the same defect wearing a different shape. This is the one refinement the ratified precedent states in its own words, and it is what distinguishes this decision from the superficially attractive alternative of keeping the resolution and downgrading only its failure disposition.
2. **The recorded detail is a two-valued vocabulary.** It carries no field delimiter (the phase record is delimiter-separated and rendered as a report table row), and it carries the "would fail" token if and **only if** `--apply` would fail — a downstream classifier reads that token to decide whether a producer's output will be present. A reworded detail that violates either constraint silently flips a downstream verdict.

**Where a phase has no single branch point, scope the limb — do not relocate the phase.** Some phases carry limbs that are mode-invariant and *should* keep running in dry-run, co-tenanted with one limb that is not. There, the correct shape is the per-limb downgrade the tool already uses in three places: scope the one mode-dependent limb as a **conjunction bounded to the exact state the no-op produces**, never as a mode-wide suppression. A whole-phase relocation in that situation is the mode-blindness defect inverted — it stops the mode-invariant assertions from running at all.

**Every fix under this rule ships a PAIRED arm, and the pairing is the load-bearing part.** A presence check — *does a mode branch exist in this function?* — **passes on the defective code**, because the branch was always there, just stranded below an abort. So each fixture is driven through both modes: the dry arm must reach the limb and record the literal dry-run outcome (a vacuous pass also returns zero and must not count), and the apply arm on the **identical** fixture must still abort with its message preserved. Without the apply arm, the dry arm is satisfiable by gutting the guard or by a fixture that does not actually omit what it claims to omit.

## Decision kernel (version-agnostic)

> In tooling that runs a fixed phase sequence in a predict mode and an execute mode, where any phase's failure aborts the run: the mode test belongs **below** every guard whose inputs are mode-invariant and whose execute-mode behaviour is not the phase's write, and **above** every statement whose input is produced by a phase that no-ops in predict mode. The prediction is static — a predict-mode limb that computes a result is the same defect in a new shape. Where mode-invariant and mode-dependent limbs are co-tenanted, scope the single mode-dependent limb as a conjunction bounded to the no-op's exact state; never relocate the whole phase and never suppress mode-wide. Every such fix ships a paired predict/execute arm over one fixture, because a presence check passes on the defective code.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| **Relocate the mode test** (the sweep's direction) | **Selected** | Exactly consistent with both ratified siblings; one function, one file; the residual it concedes is the one the siblings already accepted and named. |
| **Keep the pre-branch resolution** and revert the two siblings to match the third site's comment | Rejected — on evidence, not preference | Rests entirely on the comment being a deliberate carve-out. Ancestry falsifies that: the comment predates the convention and is its ancestor. Adopting it would revert two shipped fixes and delete the paired arms whose apply-side limb exists precisely so a "fix" cannot be satisfied by gutting a guard. |
| **Keep the resolution; mode-scope only the failure disposition** | Rejected — and this is the interesting rejection | Not obviously wrong: it buys back the preview the selected option concedes. It is rejected because the ratified convention already adjudicated this exact trade, accepted the identical residual in the identical words, and then **forbade this mechanism by name** — a dry-run that stats the input or reads an exit code is the mode-blindness defect wearing a different shape. Adopting it would make one phase the only one in the file whose dry-run limb computes, which is the divergence the sweep exists to end. |
| **Fix the projector instead of the caller** — make the emitter tolerate an absent input | Rejected | Outside the declared change surface, and it would let `--apply` write a durable ledger row with no source note. That defeats the fail-loud posture the emitter deliberately preserves, trading a visible dry-run abort for a silent wrong row in a permanent artifact. |
| **Suppress all aborting returns mode-wide under dry-run** | Discarded pre-matrix | Would gut every genuine preflight. Dry-run's value is that it surfaces real problems early; a mode that cannot fail cannot warn. |
| **Pass the mode into the projector as a CLI flag** | Discarded pre-matrix | Moves close-out mode semantics into a tool that has no business knowing about close-out modes, and spreads the convention across a second executable instead of consolidating it. |
| **Whole-phase relocation at the fourth site** (apply the 9.55/15.5 shape uniformly) | Rejected | Two of its three limbs are mode-invariant and must keep running in dry-run. A whole-phase relocation would return zero before either ran — suppressing a tagger-identity and a set-parity assertion to fix a row-count off-by-one. The per-limb conjunction preserves the assertion instead of trading it away. |
| **Fix only the named third instance and re-scope the acceptance criterion** | Rejected | Measured: fixing it alone moves the halt to the fourth instance and the criterion still fails. Re-scoping would have shipped a card whose criterion was written down as unreachable — repeating the pattern that surfaced this defect in the first place. |
| **Codify the rule in the pipeline governance file in this release** | **Deferred, not rejected** | The correct governed home, and it is owed. That file is claimed by two other in-release cards and one unmerged sibling; a third concurrent claimant is a live collision. This ADR carries the durable record until the codification lands. |

## Consequences

**A residual is conceded, and it is the same one both siblings already accepted.** Dry-run no longer previews a failure in the *resume* case — a close re-run after the upstream artifact landed but the downstream entry did not. The gate loses nothing: the check still runs at `--apply`, before anything is written, and the post-write detectors are unchanged. What is lost is the preview, and only in that case. Naming it here means the next reader who notices the gap finds a decision rather than an oversight.

**The class is now closed at four of thirty-six, with the denominator reported.** The sweep enumerated every phase function and gave each a disposition — not just the hits. That matters more than the two fixes: a future sweep starts from a prior instead of from scratch, and a phase added later is measured against a stated population rather than against whichever instances someone happens to remember.

**A fifth instance is predicted, named, and left in place.** One phase is mode-safe by *version-scoping* rather than by a mode test: its findings are filtered to the closing version's path, so an absent artifact produces no finding. It is correct today. A future lint rule of the form "the artifact must exist" would silently make it the next class member. Recorded as an accepted residual so the next sweep inherits the warning.

**The paired-arm discipline is now the cost of a fix in this class, and it is not optional.** The presence-check failure mode is the whole reason: a check that passes on the defective code is worse than no check, because it converts an open defect into a closed one on paper. Every fix under this rule owes a dry arm, an apply arm on the identical fixture, and — where the fix is a bounded conjunction — one negative arm per conjunct, so a conjunct dropped in a later edit fails a named arm instead of silently widening the prediction.

**The rule still has no governed home, and that is the unfinished half.** This ADR is the durable record, but an ADR is a decision log, not a lookup surface: nobody authoring a new phase function reads it. The in-file consolidation shipped alongside this decision — the rule stated once at the top of the tool rather than three times inside three phase bodies — is the interim mitigation and is where a new author will actually encounter it. The pipeline-governance codification is deferred to a follow-on on collision grounds, and until it lands the rule remains discoverable only from inside the tool it governs.

**The fix widens dry-run's reach in one direction only.** After it, a dry-run can reach phases it previously could not; it cannot skip a phase it previously ran, and it cannot pass a state it previously failed. The bounded conjunction at the fourth site is what keeps that true: any gap other than the exact one the no-op produces reports in both modes, unchanged.

## Related ADRs

- **[ADR-142](ADR-142-resolve-the-root-do-not-exempt-the-fixture.md)** — resolve the root, do not exempt the fixture. The same posture on a different surface: this decision reconciles the misleading in-code comment rather than deleting it, and closes the class rather than exempting the instance that surfaced it.
- **[ADR-092](../../core/ADRs/ADR-092-plan-file-claim-time-stamping.md)** — plan-file identity binds at claim-time stamping. The close-out phase that asserts that identity is one of the five phases with **no** mode branch, and the sweep dispositioned it correct-by-design for a reason worth recording: its input is authored on the release branch and is therefore present in both modes, so it is not a class member. This ADR does not disturb it.

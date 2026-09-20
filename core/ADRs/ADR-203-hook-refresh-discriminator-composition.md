<!-- reference-durability: allow-link -->
---
title: ADR-203 — The hook-refresh discriminator is a bounded git-history walk; the force path is a recovery role, not the discriminator
status: Accepted
date: 2026-09-19
release: hook-publisher-republishes
deciders: "Stage 5 Solutioning spoke for the hook-publisher-republishes release (design exploration, five-candidate trade-off matrix, three evidence-grounding canonicalizations) + the hub's adversarial design review, which re-verified the persister finding independently + the Stage 6 Engineering spoke that authored this record and built the composition"
tags: [hook-publisher, installer, drift-classification, git-history-walk, fail-safe-direction, operator-edit-preservation, checksum-baseline, recovery-path, role-separation, duplication-registered]
source_observations:
  - "The deployed hook bundle is advanced by the update path over time, while the recorded checksum baseline is written only by a full installer run. On a surveyed live instance the two dates diverged by nearly three weeks: the state file predated the deployed security hook it claimed to describe. The divergence is structural rather than an anomaly of that instance — the two writers are different code paths with different trigger conditions."
  - "The refresh predicate overwrites only when the deployed file's hash still equals the recorded baseline hash. Any other value is classified as an operator edit and preserved, emitting a warning rather than an error, so the run exits zero and reads as successful. Measured on the surveyed instance: three distinct hashes for one hook — recorded baseline, deployed actual, and repository source, all different — so the preserve branch was taken on a file that was a platform version, not an operator edit."
  - "The preserve branch does not only warn. It re-anchors the recorded baseline to the DEPLOYED bytes. Composed with the refresh predicate one line above it, a persister that wrote the whole checksum map back to the state file would make the SECOND refresh overwrite whatever the first one preserved — converting a today-harmless in-memory re-anchor into a durable clobber of a genuine operator edit. This is a two-line deduction from verbatim source, and it inverted the originally-planned fix."
  - "A three-valued drift classifier with exactly the needed semantics already shipped in the deploy checker: STALE (the deployed bytes ARE some historical revision of the mapped source — refreshable), DIVERGENT (they match no revision within the cap — an operator decision), and UNCLASSIFIED-DEPTH past the cap, on the stated rule that an unfinished search is not a finding. Its own header names the misclassification this release fixes, and names the missing persister sibling by the exact identifier the acceptance criteria later adopted."
  - "The two folded source cards prescribed opposing mechanisms for one acceptance criterion: one required the git-history test to be the discriminator rather than a force flag; the other required a supported force path that reconciles without a full re-bootstrap. Read as competing answers to one question they are irreconcilable; read as answers to two questions — what decides, and what an operator does about a genuine divergence — they compose."
  - "Cost of the history walk, measured on the widest hook in the bundle: 39 distinct blobs across 41 commits touching that path, against a walk cap of 60. The whole hook directory totals 199 commit-touches across 24 hooks, so the walk is bounded by one hook's own history and fires only on the preserve branch, which a healthy instance never reaches."
  - "No pre-existing regression arm exercised a latched baseline. Both repeat-refresh fixtures in the suite are built by a helper that records baseline equal to the source hash for every hook, so every hook takes the already-in-sync arm and the refresh-mode block is never entered. An arm that cannot reach the branch under test measures nothing about it."
---

# ADR-203 — The hook-refresh discriminator is a bounded git-history walk; the force path is a recovery role, not the discriminator

## Status

**Accepted.** Authored at Stage 6 Engineering for the `hook-publisher-republishes` release, alongside the three limbs it records.

**Numbering provenance.** Claimed as **203** against an anchor of **202** on `origin/main`, read from the repository's own ADR-numbering detector rather than computed as one past the highest number visible on any branch. ADR numbering spans two directories and a sibling release can take a slot mid-flight, so a branch-local maximum does not bind. The number binds at the Stage-12 claim; in-release prose cites this record by slug.

**Authoring provenance.** The Stage-5 design named this record; the File Change Matrix ratified at the Stage-4 gate did not carry a path for it. The Stage-6 instruction directs that it be authored at Commit 0, so the matrix gains one row and the release plan's Deviation Log records the amendment with its authority.

## Context

A security-hook fix that merges does not reach a running instance, and nothing in the output says so.

The hook publisher decides, per hook, whether a deployed file may be overwritten. Its predicate is baseline equality: overwrite when the deployed content still hashes to the value the installer recorded, or when no value was recorded; otherwise classify the file as operator-edited and preserve it with a warning. The intent is sound — an operator edit should never be silently clobbered.

The predicate is keyed to a baseline that nothing keeps current. The deployed bundle is advanced by the update path; the baseline is written only by a full installer run. On any normally-maintained instance the two diverge, and from that point every refresh misclassifies a platform-updated hook as an operator edit and refuses to touch it. The refusal is a warning, so the run exits zero. The operator believes the fix is live while the superseded hook keeps enforcing. The full-update path delegates to the same code and inherits the same outcome, and the accepted flag set carries no force or overwrite option, so both documented ways to update hooks are inoperative and both report success.

Two properties of the existing code decide the shape of the fix, and neither is obvious from the failure report.

**The preserve branch writes.** It re-anchors the recorded baseline to the deployed bytes. Today that write is harmless, because the refresh path never persists the checksum map back to the state file. Add a whole-map persister — the obvious fix, and the one originally planned — and the re-anchor becomes durable: the second refresh finds recorded equal to deployed, takes the overwrite arm, and clobbers the operator edit the first refresh preserved. The naive fix converts a silent refusal into a silent destruction, which is strictly worse.

**A classifier already exists.** The deploy checker carries a bounded git-history walk returning three verdicts, with the fail-safe direction already reasoned out in its own header, and that header names this exact misclassification. The discriminator did not need designing; it needed adopting.

The two folded source cards each prescribed a remedy, and read as competing answers they conflict: one requires the history test to be the discriminator *rather than* a force flag, the other requires a force path to exist. They are answers to different questions.

## Decision

Three mechanisms, each with one stated role, together satisfying both source cards without overriding either.

### 1. The persister is field-scoped — Prevention

A narrow persister writes the checksum baseline back into the state document in place, updating only the keys for hooks **this run actually deployed** — the install, refresh, in-sync and mode-repair outcomes — and touching nothing else. It is modelled on the existing narrow settings-baseline persister rather than on the whole-document state writer, for the reason that function's own header already states: the whole-document writer rebuilds state from per-run scratch and would blank the verified-artifact record and the recorded directory layout on a refresh that never populated them.

**The persister never records the preserve branch's re-anchor.** This is the load-bearing constraint, not an implementation detail. A whole-map persister is a security regression: it converges the self-latch and clobbers genuine operator edits on the second refresh, indiscriminately. Field-scoping is what makes preservation stable across any number of refreshes.

### 2. The discriminator is a bounded git-history walk — Decision on evidence

On the preserve branch only — a state that is already a divergence — the publisher consults the source repository's own history for the deployed bytes. A deployed hook is a **known platform version** when its hash equals the hash of that same source path at some revision reachable within a declared walk cap. The three verdicts and the cap are adopted verbatim from the shipped classifier, so the two copies cannot disagree:

| Condition | Verdict | Action |
|---|---|---|
| Deployed hash matches a revision within the cap | `STALE` | **REFRESH**, reporting how many source commits behind |
| Matches no revision, full history searched | `DIVERGENT` | **PRESERVE**, naming the recovery flag |
| Past the cap · history unreadable · not a git checkout · `git` absent · shallow clone | `UNCLASSIFIED-DEPTH` | **PRESERVE** — an unfinished search is not a finding |

**Every degraded outcome resolves to PRESERVE.** A shallow clone, an absent `git`, a source tree that is not a checkout, or a history deeper than the cap all land on exactly the behaviour that shipped before this change. The change can therefore only widen what is recognised as refreshable; it can never narrow what is preserved. That direction is what keeps operator-edit protection true under every condition the classifier cannot evaluate.

### 3. The force path is a recovery role — Operator escape hatch

A reconcile flag forces a deployed hook back to source without a full re-bootstrap. It is **not** the discriminator: it is what an operator invokes deliberately after the discriminator has honestly reported `DIVERGENT` on a copy the operator alone can adjudicate. The preserve warning names it, so the printed remedy is one that changes the outcome rather than a re-run that provably cannot.

The three roles are disjoint. The first card's constraint is satisfied because the *discriminator* is the history test. The second card's criterion is satisfied because a supported force path exists. Neither source is overridden, and the conflict dissolves because it was never one question.

### Duplication is registered, not hidden

The history-classification algorithm now exists in two places — the deploy checker and the installer — with no shared primitive between them. This is a deliberate `net-new because in-place is infeasible` determination: the deploy checker is declared explicit non-scope for this release, so extracting a shared callable would breach the ratified scope lock, and a new shared executable would fire the new-executable companion obligation this release's matrix otherwise avoids. Semantics are adopted verbatim — the three verdicts, the cap value, and the unfinished-search rule — so the copies cannot return opposite verdicts on one input. **Successor scope:** extract a shared history-classifier primitive consumed by both the deploy check and the installer.

## Alternatives Considered

| # | Candidate | Verdict |
|---|---|---|
| A | Git-history probe on the preserve branch | **Selected for the discriminator role.** The only candidate that reaches an already-latched instance, preserves a genuine operator edit, requires no operator judgement, introduces no new artifact, and already exists in-repo |
| B | A new force/reconcile flag as the discriminator | **Rejected for that role.** It clobbers genuine edits by design, which is precisely the objection one folded source card states. **Retained for the recovery role**, where operator judgement is the input rather than a substitute for evidence |
| C | Persist the whole checksum map and rely on the preserve branch's re-anchor to converge on the second run | **Rejected — actively harmful.** It does converge the latch, and it converges an operator edit into the same overwrite. A silent refusal becomes a silent destruction |
| D | Ship a manifest of released hook hashes alongside the bundle | **Rejected.** A new artifact with its own staleness surface and its own publisher problem — the same class of defect this release exists to fix, relocated rather than removed |
| E | A + a field-scoped persister + B in a recovery role | **Selected.** The composition above |

Candidate C is the one worth recording in detail, because it was the planned fix and it reads as obviously correct. Its defect is invisible unless the preserve branch's write is read together with the refresh predicate two lines above it — which is why this record names both, rather than only the conclusion.

## Consequences

**A merged hook fix reaches a maintained instance.** The forward case is closed by the persister: the baseline can no longer go stale against the bundle it describes, because the path that deploys a hook is now the path that records it. The already-latched case is closed by the discriminator, which does not depend on the baseline at all.

**Operator edits survive an unbounded number of refreshes.** Under the whole-map alternative they survived exactly one. The regression arm that pins this is authored against a deliberately whole-map persister and observed failing before the field-scoped one lands, so the protection is measured rather than argued.

**A declined hook is loud.** A refresh that leaves at least one control on a superseded version emits a summary line naming the count and exits with a distinct status, and the full-update path discriminates that status from a failed-to-run status rather than folding both into a warning. An operator reading only the exit code can no longer miss it.

**Cost is bounded and lands only on the unhealthy path.** The walk is per-hook, capped, and reached only when the baseline predicate has already failed. A healthy instance takes the in-sync arm and consults no history at all.

**Two copies of one algorithm now exist.** Registered above with its successor-extraction pointer, rather than left to be discovered.

## Reversibility

**CHEAP · confidence HIGH.** Every limb is an additive change to tracked files on a single branch with a single merge, so reverting the merge restores the prior behaviour byte-for-byte. Nothing in the composition writes a new persistent artifact, changes a file format, or alters a schema: the persister updates two existing keys of an existing state document in place, and the discriminator is a read of history that already exists. An instance that has run the new publisher and then reverts simply returns to the previous classification rule with its baseline more current than before — a strictly better starting state than the one this release found.

## Related ADRs

- The settings-baseline refresh record establishes the narrow-persister pattern and the baseline-anchored guard this persister is modelled on, including the reason a refresh flow must not call the whole-document state writer.
- The canonical link-resolution record and the plan-file claim-time stamping record are unrelated to this decision and are named here only to be excluded — neither governs hook deployment.

## References

- Parent work item: the hook-publisher defect card, which reports that the refresh path silently deploys nothing once the checksum baseline goes stale, and carries the twelve-criterion reconciled acceptance set this composition satisfies.
- Two folded source cards supplied the operational definition of *known platform version*, the byte-exact falsification of the operator-edited classification, the constraint that the history test fill the discriminator role, the self-latch mechanism, and the narrow-persister identifier.
- The shipped three-valued drift classifier in the deploy checker is the semantic source for the verdict set, the cap, and the unfinished-search rule.

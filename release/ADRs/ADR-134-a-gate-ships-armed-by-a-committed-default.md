<!-- reference-durability: allow-link -->
---
title: ADR-134 — A gate ships armed by a committed default; arming is never deferred to a later step that can be forgotten
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-14
release: stage9-gate-integrity
deciders: "Workspace owner (disposition ③d rendered at the v4.03 Collective Review scope-lock; D-ADR-Disposition re-affirmed at the stage9-gate-integrity Stage-5 design gate and again at its Collective Review). Owed by release closeout-output-set-integrity (v4.03); authored retroactively at Stage 6 Engineering of stage9-gate-integrity."
supersedes: none
tags: [architecture, release-pipeline, gates, arming, warn-mode-initial, committed-default, retroactive-record, reversibility-cheap]
source_observations:
  - "The record itself was the deferred step. v4.03's approved File Change Matrix declared `release/ADRs/<self-arming-conditional-gate-posture>.md` as an unconditional ADD; the merge (2adf533e) delivered 24 files with 5 A-status paths, none of them this record, and the plan's Deviation Log carries no entry explaining the omission. The posture this ADR states is the posture whose own record was forgotten."
  - "The arming is a committed default, verifiable in the shipped source. `core/deploy/deploy.sh:1390` reads `local cc_cutoff=\"${CLOSE_COMPLETENESS_CHECK_CUTOFF:-v3.89}\"` — the cutoff has a value in the repository, so the gate EVALUATES on every run rather than SKIPping until someone sets an environment variable."
  - "The disarm path is explicit, named, and asymmetric to the arm path. `CLOSE_COMPLETENESS_CHECK_CUTOFF=__none__` re-dormants the gate and the tool prints that it was explicitly re-dormanted, naming the variable to unset. Turning the gate OFF is therefore a deliberate, logged act; leaving it ON requires nothing."
  - "The armed default and the blocking mode are separate dials, and only the first is self-arming. `.github/close-completeness.enforce` still carries the token `warn`, and its own header records the two remaining flip-to-enforce steps. Arming (does the gate evaluate) shipped committed; enforcement (does a finding block) stayed on the calibration ladder."
  - "The cutoff value was chosen so the warn log starts clean. The sentinel's header states the cutoff is the oldest value with zero standing findings, precisely so a log pre-poisoned by known legacy debt could not make the enforce flip unevaluable."
  - "The corpus-home-adapter constraint card applies the same posture to a constraint rather than a check. `release/references/standards/corpus-home-adapter-constraints.md` is explicitly anticipatory — no corpus-home adapter exists — yet it ships WITH an executable assertion (`release/tools/tests/test_corpus_home_tolerance.sh`, wired into the `closeout-smoke` CI job) so the constraint cannot be silently violated by the adapter that eventually lands."
  - "The cost asymmetry is stated contemporaneously in that constraint artifact and is the general argument, not a local one: discovering the constraint later means a required gate is red on every PR at the moment the adapter lands, with the fix competing against the pressure to disable the gate — and 'gates that are disabled to unblock a merge do not come back.'"
---

# ADR-134 — A gate ships armed by a committed default; arming is never deferred to a later step that can be forgotten

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Retroactive authorship, stated plainly.** This record was owed by release `closeout-output-set-integrity` (shipped as v4.03, merge `2adf533e`). It was declared as an unconditional ADD in that release's operator-approved File Change Matrix, it did not ship, and no Deviation-Log entry recorded the omission. It is authored here, in `stage9-gate-integrity`, as the AC5 obligation of the work item that found the gap. The content is transcription rather than reconstruction: the posture is stated in v4.03's own plan (§ File Change Matrix, amendment 4) and is verifiable in the artifacts that release shipped, both cited above.

**Numbering.** `133` is the mainline anchor plus one, re-derived against `origin/main` at Engineering time across **both** record directories rather than pre-allocated at design time. The union of the two directories reaches `ADR-132` on the mainline, and no open sibling branch claims `133`. A number claimed at Stage 5 and merged weeks later is a reservation hazard against a sibling's unmerged claim, so the allocation deliberately happens here.

**Numbering provenance — `133 → 134`.** Held **ADR-133** branch-local; renumbered to **ADR-134** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 133. In-release citations that read "ADR-133" denote this record.

## Context

A conditional gate has two independent dials, and conflating them is how gates end up asserting nothing:

1. **Arming** — does the check *evaluate*, or does it short-circuit to `SKIP`?
2. **Enforcement** — when it evaluates and finds something, does that *block*, or merely report?

The platform's `warn-mode-initial` posture is a well-founded answer to dial 2. A new check runs in report-only mode for a calibration window, its false-positive rate is characterized against a real log, and only then does it graduate to blocking. That ladder exists because a check that blocks on day one, before its precision is known, teaches everyone to route around it.

The failure mode this record addresses is what happens when that same reasoning is applied, by analogy, to dial 1 — when the *arming* is also deferred. The shape is always the same: the check ships complete and correct, but its activating value is left unset, to be supplied "when we cut over." The activating value is an environment variable nobody exports, a cutoff nobody picks, a sentinel file nobody creates.

**A gate in that state is indistinguishable from a gate that is passing.** It runs, it emits `SKIP`, the roll-up is green, and the release log records a check that was never in a position to fail. The deferred step has no owner, no due date, and no observing step of its own — so nothing ever notices that it did not happen. The gate becomes a permanent, well-tested no-op.

The two v4.03 cards that motivated this record hit the same wall from opposite directions. The **close-completeness arming card** had a completed check whose cutoff had no carrier — nowhere for the armed value to live. The **corpus-home-adapter constraint card** had a constraint that no code would honour for months, because the adapter it constrains does not exist yet.

## Decision

**A gate ships armed by a committed default. Arming is never left to a subsequent step.**

Concretely, four clauses:

1. **The activating value lives in the repository, not in an environment.** `core/deploy/deploy.sh` ships `CLOSE_COMPLETENESS_CHECK_CUTOFF:-v3.89`. Because the default is committed, a fresh clone evaluates the gate. Nothing has to be remembered, exported, or provisioned.

2. **The asymmetry runs toward evaluation.** Disarming is an explicit, named, logged act — `CLOSE_COMPLETENESS_CHECK_CUTOFF=__none__`, whose SKIP message states the variable to unset in order to restore the armed default. Arming requires nothing. Whichever direction is cheaper is the direction the system drifts, so the cheap direction must be the safe one.

3. **Arming and enforcement graduate separately.** Shipping armed does NOT mean shipping blocking. `.github/close-completeness.enforce` still reads `warn`, and its header names the two remaining steps (a ≥3-day zero-false-positive warn-log review, then adding the job to branch-protection required checks). The calibration ladder is preserved in full; what it no longer covers is whether the check runs at all. The armed cutoff was chosen as the oldest value with zero standing findings precisely so the warn log starts clean and the enforce flip stays evaluable.

4. **A constraint that no code honours yet ships with an executable assertion, not a promise.** `corpus-home-adapter-constraints.md` describes a seam that does not exist, and it ships with `test_corpus_home_tolerance.sh` wired into a CI job. The document alone would be a note; the document plus the assertion is a control that the eventual adapter cannot silently violate.

**The generalization, and it is the load-bearing sentence:** *a deferred arming step is a control with no observing step.* It looks like scheduled work, but nothing observes whether it happened, and its absence is byte-identical to success. That is the same defect class as a check whose verdict nothing reads, a record nothing verifies, and — as this record's own three-release delay demonstrates — a declared deliverable nothing reconciles against the merged diff.

## Alternatives Considered

**A1 — Ship dormant; arm in a follow-up issue.** The status quo this rejects. It has a real virtue: the arming release is trivially safe, because nothing can newly fail. The cost is that the follow-up is a control with no observing step. Rejected on evidence: the ADR you are reading was itself the follow-up step of a scope-locked deliverable, and it was forgotten for three releases without a single gate noticing.

**A2 — Ship armed AND enforcing on day one.** Collapses both dials to "on". Rejected: it discards the `warn-mode-initial` calibration window for no gain. Arming is what makes the false-positive rate *measurable*; enforcing before it is measured is what teaches people to disable gates. The two dials are separate because they answer different questions.

**A3 — Arm via CI configuration rather than a committed default.** Set the activating value in the workflow instead of in the tool. Rejected: it arms exactly one caller. An agent-side or local invocation still SKIPs, so the same check reports two different things depending on who runs it — and the quieter answer is the one a contributor sees first.

**A4 — Record the omission as an accepted deviation instead of authoring this ADR.** Considered seriously at the `stage9-gate-integrity` design gate and rejected on a specific, non-obvious ground: recording the deviation requires writing a `NOT DELIVERED` row into **v4.03's own plan**, which is the exact artifact the new declared-vs-delivered gate replays as its strongest, non-synthetic anti-vacuity control. That row would convert the control's must-flag arm into `deviation-recorded → PASS` and destroy the only real proof available that the gate works. Choosing A4 would have been a self-inflicted verification loss in a release whose entire subject is verification integrity. A fifth option — author the record *and* log a pointer deviation — was also rejected: it contaminates the same fixture for no added information.

## Consequences

**Positive.**
- A conditional gate's default state is legible from the repository alone; no environment reconstruction is needed to know whether it evaluates.
- The warn-mode ladder still governs blocking, so precision is still characterized before anything is enforced.
- The "arm it later" backlog item — a work class with no owner and no observer — stops being generated.
- Anticipatory constraints acquire executable assertions by default, which is what makes them survive contact with the code that eventually lands.

**Negative, stated rather than minimized.**
- Shipping armed means the introducing release must absorb whatever the gate finds on the existing corpus. That is real work, and it is front-loaded. The mitigation is the cutoff-selection rule in clause 3 (choose the oldest value with zero standing findings), which bounds the work without hiding the debt — but bounding is not eliminating, and a gate over a genuinely dirty corpus will still cost the introducing release.
- A committed default is a decision made once for every caller. Where callers legitimately differ, clause 2's named disarm path is the only escape, and it is deliberately conspicuous.

**Reversibility: CHEAP / Confidence HIGH.** This record states a posture already implemented in shipped artifacts; it introduces no runtime surface. Reverting the posture means changing the committed defaults in the tools that carry them, each a one-line change under `git revert`.

**Scope boundary.** This ADR governs the *arming* of conditional gates and the *assertion* accompanying anticipatory constraints. It does not govern which checks should exist, what they should assert, or when a warn-mode check should graduate to enforce — `core/standards/gate-efficacy-standard.md` owns that ladder and is unchanged by this record.

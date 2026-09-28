---
title: ADR-208 — Checkpoint B's host-API axis reads its own probe, in-band
status: Proposed — the design was locked at the controls-fail-loud Collective Review and at the short scope lock that followed its scoped re-design; the transition to Accepted belongs to the release's Stage 13 ratification beat
date: 2026-09-27
release: controls-fail-loud
deciders: "Workspace owner (operator) — decisions rendered at the release's Stage-5 Collective Review, which returned the design for a scoped re-design, and at the short scope lock that followed it, with two independent adversarial reviews folded in; design by the Stage 5 Solutioning spoke; authored by the Stage 6 Engineering spoke"
tags: [quota-budget, checkpoint-b, host-api, rate-limit, graphql, in-band, anchor, evidence-grading, fail-open, refusal-classifier, repo-host-adapter]
supersedes: ADR-156 in-part (the host-API instrument and its evidence grade; the unstarted-window residual)
source_observations:
  - "The pool-status endpoint was measured blind: across 35 reads in about half an hour, every read reported the core pool as an unstarted window (5000/5000, used 0, a reset sliding to one hour out), while the counter the host enforces, read in-band from real calls in the same minutes, climbed from 733 to 1172 used on core and from 759 to 1145 on graphql against fixed resets. Earlier, 12 reads inside 3.6 seconds had returned 6 distinct reset epochs per pool, with 8 of the 12 reporting an unstarted window."
  - "A GraphQL query that selects the rate-limit object alone is not charged in a started window: in an interleaved comparison inside one window it advanced the counter by 0 on 4 of 4 reads, while three shapes that select one more field (viewer id, __typename, a meta field) advanced it by exactly 1 on 15 of 15. The response body reported a cost of 1 for every shape, the uncharged one included. An independent review measured the same shape at 0 on 36 of 37 same-window pairs, and the hub reproduced it once more."
  - "At a live core window rollover, the first charged REST probe of the new window read used 1 with a reset equal to its own Date plus 3600 seconds — it started the window itself — and the next read was one higher on the same reset; a pool-status read one second later still reported core as unstarted. At a live GraphQL rollover the uncharged shape read used 1 in the new window's first second, which could not separate a foreign window-start from a charged window-starting read."
  - "2 of 128 individual in-band GraphQL readings came from a window other than the enforcing one; 0 of 48 in-band core readings did. Eight concurrent core probes read eight consecutive counter values."
  - "Recorded refusals while every pool read full carried the host's primary-limit wording on both surfaces; during one wait loop, 13 of 24 real calls were refused while the pool-status endpoint read every pool full."
  - "Re-measured at authoring, within eleven seconds: the pool-status endpoint read core 5000/5000 with used 0 and a reset one hour out, and graphql 4976/5000; the counters read in-band showed core 4233/5000, and graphql 3587 then 3586 — a charged pair one unit apart on one reset."
---
<!-- reference-durability: allow-link -->

# ADR-208 — Checkpoint B's host-API axis reads its own probe, in-band

## Status

**Proposed.** The design was locked by the operator at the controls-fail-loud Collective Review, which returned it for a scoped re-design, and at the short scope lock that followed; the transition to Accepted belongs to the release's Stage 13 ratification beat, not to authoring.

**Numbering provenance.** Claimed as **208** against a mainline anchor of **206** plus this release branch's own ADR-207, read from the repository's ADR-numbering detector as the next free number rather than computed as one past the highest number visible on any branch; other open release branches carry 207 to 210 as detection-only claims. The number binds at the Stage-12 claim; if the mainline claims it first, the renumbering tool moves this record at merge and appends a provenance note here.

## Context

ADR-156 made Checkpoint B's second axis — the host's REST and GraphQL quota pools — a measured input, read from the host's pool-status endpoint once per routing turn. Two findings recorded against it, before and after it shipped, left the axis rendering PROCEED where it should not. The endpoint was **non-deterministic**, so ADR-156 withdrew its figures from a source grade; and it presented an exhausted state and a fresh one identically, as a full pool with `used = 0`, so presentation (b) — a successful read of a window that had not started — was recorded as a named residual pending a declared-state input nobody had specified. A third presentation followed: a limit in force while every pool reads full, which the endpoint cannot show at all.

Measurement then made the endpoint's defect worse than non-determinism: it was **blind**. Every read reported an unstarted `core` window while the counter the host actually enforces, readable from the response headers of any real call, showed hundreds of requests already drawn. No sampling discipline over that endpoint could recover a quantity it does not carry. The candidate declared-state inputs — an operator-stated window anchor, a persisted prior-draw record, a hub first-draw timestamp — each either could not be stated or could only flag the artifact without supplying a true reading.

The input that could separate the two presentations was the probe's own draw. A request that draws from a pool is reported by that pool's counter on its own response, so a reading that shows no draw cannot be a report of the request that drew. The first design used that idea with a GraphQL probe that selected the rate-limit object alone; an adversarial review measured that shape as uncharged in a started window, so its "declared draw" was false for that pool and a genuinely fresh GraphQL window would have been deferred. The Collective Review returned the design for a scoped re-design, and this record states the re-designed decision.

## Decision

1. **The instrument is metered probes, read in-band and bound through `[adapters].repo_host`.** Each probe draws at least one unit by construction: a repository-free REST read, and a GraphQL query that selects a field beyond the rate-limit object. REST `core` is probed once; GraphQL twice. The pool-status endpoint is not an input.
2. **The probe's own draw anchors the reading.** A reading is anchored when it is answered, names the probed pool, shows a draw (`used ≥ 1`, `remaining < limit`), and falls in the window measured against the response's own `Date` header. For GraphQL, two anchored readings must also agree: the same `reset`, and a later `used` that exceeds the earlier by the later probe's draw. There is one re-probe per pool. After it: the most conservative anchored reading, flagged unresolved; or `UNANCHORED` → DEFER when none anchors. Answered-without-counter → `UNSTATED`.
3. **The refusal-reason classifier reads only the refusing call's own response.** It is one transport-aware library with a fixed four-class contract, shared by every tool that classifies a host response; quota wording anywhere else — a quoted comment, a successful body, an agent-runtime notice — is never a refusal.
4. **Grades are per pool.** An anchored REST `core` reading is `[SOURCE]`. A GraphQL reading is `[ASSUMPTION – CONFIRM]` until three releases after this record's introduction pass with no calibration event: a run reporting `used_zero ≥ 1`, or an unresolved GraphQL agreement. The hub records each event as an action item that the close-out ledger gate surfaces. Headroom at launch is `[ASSUMPTION – CONFIRM]` for both pools.
5. **A mechanized evaluator whose exit status carries evaluability, never the verdict.** It exits 0 when it evaluated, and the verdict lives only in its `HOST-API` record; 2 is a usage error or a selector outside the declared value space; 3 is a scan-surface error; any other value is a fault. No exit code means DEFER, so a crashed evaluator can never read as one, and the hub fails open on any non-zero exit.
6. **The budget probe and the refusal-classification binding are named gaps of the `repo_host` interface**, owned by the repository-host abstraction work. Until they are declared there, the evaluator's GitHub arm performs them behind the selector, and its self-test requires an explicit arm for every allowed selector value.

Retained from ADR-156: grades attach per axis (and now per pool), never averaged; the two axes combine by DEFER-dominant disjunction and no verdict token is minted; a probe failure fails open with its basis rendered; and the axis is evaluated once per routing turn, not per spoke.

## Alternatives Considered

| Option | Verdict | Basis |
|---|---|---|
| An operator-stated window anchor | Rejected | Other sessions draw the pools, so nobody can state the value even in principle — ADR-156's own rejection of declared host-API state. |
| A persisted prior-draw or last-reading ledger | Rejected | Yields only an upper bound on what remains, useful for DEFER and never for PROCEED; useless when every endpoint reading is the artifact; adds hub state. |
| A hub first-draw timestamp checked against the endpoint | Rejected | Identifies the artifact without ever supplying a true reading, so it defers on the common case — every reading, when measured. |
| Conservative DEFER on every full-pool endpoint read | Rejected | The same total false-DEFER rate on the common case. |
| Keep the endpoint and add probes beside it | Rejected | Two readings that disagree on every sample, with no rule for which wins; the endpoint's early warning was inert on `core` and wrong on `graphql`. |
| Probe only when the endpoint reads pristine | Rejected | The trigger keys on `used = 0`; the endpoint's GraphQL figure reads `used ≥ 1`, so the pool the axis exists for would never be probed. |
| A scripted replay used only at Dev Testing | Rejected | The gate stays hub-interpreted prose, regression protection is one-off, and the host-agnostic protocol would have to name host commands. |
| An offline classifier script with prose probing | Rejected | The costs of both options and the protection of neither. |
| A GraphQL probe that selects the rate-limit object alone | Rejected | Measured uncharged in a started window, so it cannot declare a draw. |
| A single GraphQL read | Rejected | A reading from another window passes an absolute anchor on its own. |
| `UNANCHORED` on a persistent GraphQL disagreement | Rejected | Adds an operator stop with no reduction in risk: an unstarted reading can never be the conservative pick, and the most conservative anchored reading is safe against every observed candidate. |
| A REST probe of the release repository, resolved from the checkout | Rejected | The git remote is the wrong source of the repository, and the adapter's own resolver draws on the GraphQL pool, so the `core` reading would fail exactly when GraphQL is exhausted. |
| Declaring the budget probe as an operation of the `repo_host` interface now | Rejected for this release | The right end-state, and cheapest before a second adapter exists; it belongs to the repository-host abstraction work, and doing a slice of it here buys less than it costs. |
| Minting a new verdict token for the new basis | Rejected — on consequence | A downstream rule enumerates its briefing triggers by name, so a new token would match nothing and a blocked launch would proceed silently, as ADR-156 recorded. |

## Consequences

- **The draw is certain and bounded:** three metered requests per routing turn, at most five with re-probes, plus one hub tool call against the usage window.
- **Presentation (b) cannot reach the verdict.** An unstarted-window reading fails the anchor and defers; a genuinely fresh window reads the probe's own draw and proceeds.
- **The calibration counts are emitted per run** (`reset_disagreements`, `used_zero`), and a calibration event reopens decision 4 rather than going unrecorded.
- **The write-scoped half of presentation (c) stays a named residual** — content creation and mutation weight — discriminated by a hub-side count of content-generating requests that no axis yet carries. A host-API PROCEED attests that reads were available at the probe, not that writes will be.
- **One transport-aware refusal classifier lives in `release/tools/lib/`**, shared with the close-out tooling. Reverting this change after that tooling sources the library means reverting the tooling first.
- **A new executable to maintain**, with a hermetic self-test that runs in a required CI context.
- **The fixed 20 % floor now reads live data** from the enforcing counter, and the change in `used` between routing turns makes its successor form computable, though it is not built here.
- **Requests per interval are still unmetered.** The probe detects the refusal a fan-out provokes; it does not throttle the fan-out.
- **Effective from the Stage-12 release-hub deploy.** This release's own launches used the previous axis.

## Reversibility

**MODERATE.** A runtime gate consulted before every launch changes: revert the release's commits for this record as one unit — after the close-out tooling that sources the shared classifier, where that has landed — then rebuild and redeploy the release-hub package. Nothing here migrates data or leaves host-side state.

## Related ADRs

- **[ADR-156](ADR-156-checkpoint-b-second-axis-is-measured-not-declared.md)** — superseded in part: its instrument, its evidence grade and its unstarted-window residual. Its per-axis grading, its DEFER-dominant disjunction, its fail-open rule on a probe failure and its two-basis rendering stand.
- **[ADR-157](ADR-157-wave-width-is-a-second-checkpoint-b-output-not-a-verdict.md)** — wave width, the usage-window axis's second output; untouched.
- **[ADR-109](../../core/ADRs/ADR-109-external-target-knowledge-scope.md)** — its decision 5 is the named-gap precedent for a host operation the `repo_host` interface lacks.
- **[ADR-102](ADR-102-quota-budget-successor-substrate-finops-cumulative-draw.md)** and **[ADR-026](ADR-026-spoke-launch-quota-reservation-telemetry-event.md)** — the usage-window substrate and the unwired startup-reservation event; untouched, and this gate still emits no event.

## References

- #6237 — the card: Checkpoint B's host-API axis rendered PROCEED on a window it could not tell from a fresh one.
- #7806 — the card's Stage-5 design record, carrying the baseline design, the scoped re-design and their measurements.
- #7883 — the adversarial review whose uncharged-probe finding returned the design for its re-design.
- #7683 — the release's planning record, carrying the Collective Review and the short scope-lock decisions.
- #6871 — the close-out transport card that sources the shared refusal classifier.
- #10 — the repository-host abstraction work that owns the interface's named gap.
- #6439 — the usage-window axis card, deliberately not presupposed here.
- #7427 — the first measured instance of a limit in force while every pool read full.
- #7847 — the requests-per-interval gap, which carries the write-scoped discriminator.

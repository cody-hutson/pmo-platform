<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-102 — The quota-budget gate's per-spoke cost successor is the FinOps store's cumulative per-spoke draw, not ADR-026's `spoke-launch` startup reservation
status: Proposed
date: 2026-07-28
release: agent-finops-intelligence (v4.0)
deciders: "Workspace owner — D-Substrate ADOPTED at Collective Review. Framed (not rendered) by the Stage-5 Solutioning design for the estimation-engine slice; authored at Stage 6."
tags: [architecture, quota-budget, telemetry, finops, token-spend, pipeline-event-log, supersession, estimation]
supersedes: ADR-026 (substrate choice only — the event definition stands)
source_observations:
  - "quota-budget-protocol.md § 5 declares its own successor: once the `spoke-launch` / `quota-reservation` event has accumulated per-spoke startup-token observations, the ordinal size-bucket band is replaced by observed medians per size bucket."
  - "That declared substrate has NO producer. A structured probe over the whole corpus, controlling for the historical release corpus and the ADR record, finds `spoke-launch` in exactly four live sites — the schema enum row, two quota-budget-protocol citations, and the writer's static-fallback enum — and zero emitters. release-hub's own references/spoke-launch.md never mentions quota-reservation, tokens_used, or startup cost."
  - "The declared unit is not the quantity the gate consumes. § 4.1 names the input per-spoke STARTUP-cost telemetry, but § 4.2 step 2 computes N_planned x per-spoke-cost and compares it to the remaining usage-window envelope — and the usage window meters CUMULATIVE total token consumption (§ 1). A spawn-time reservation is the prompt-construction cost at spawn; it is not what a spoke draws over its life."
  - "The FinOps usage store measures cumulative per-spoke draw exactly: a spoke is its own session file, and session.tokens is captured from message.usage. The estimation engine reads it locally and reproducibly, with no network call."
  - "Changing the declared successor substrate without a record would be a silent contradiction of an Accepted ADR — the drift the platform's Stability value exists to guard."
---

# ADR-102 — The quota-budget gate's per-spoke cost successor is the FinOps store's cumulative per-spoke draw, not ADR-026's `spoke-launch` startup reservation

## Status

**Proposed.** Authored at Stage 6 per the Stage-6 ADR-authoring precedent (ADR-096 / ADR-097 / ADR-101). The decision was rendered by the workspace owner as **D-Substrate**, **ADOPTED at Collective Review** for this release. It flips to **Accepted** at this release's Stage-9 plan-review gate; per ADR-098's precedent the flip is verified against this file's own `status:` field and never assumed from milestone closure.

**Numbering — a contention that materialized, and was resolved by renumbering.** ADR numbers are platform-global monotonic across **both** homes (`core/ADRs/` + `release/ADRs/`), and the claimed set includes **in-flight pull-request claims**, not just what is on `origin/main`.

Authored provisionally as **ADR-100** against a recomputation that read `origin/main` at highest ADR-098. Both provisional numbers were then invalidated: `origin/main` took **ADR-099** (`release/ADRs/ADR-099-mode-r-disposition-set-fit-test.md`), colliding with this release's sibling ADR, and an open release pull request holds a live claim on **ADR-100**, colliding with this one. Recomputed at the Stage-9 GO gate across `origin/main` + both ADR homes + the changed files of every open pull request, the next free slots are **101** and **102**; this release's two ADRs took them in authoring order — the sibling to **[ADR-101](../../core/ADRs/ADR-101-finops-store-frozen-kind-versioning-exemption.md)**, this one to **ADR-102**.

This is exactly the convention ADR-026 records: **the later claimant renumbers.** The renumber was applied here as a full reference cascade (file rename plus every referring line in the schema, the release plan, the skill, and the quota-budget standard), not a bare `git mv`. One consequence is worth stating plainly rather than discovering at merge: on this branch in isolation the sequence now skips **099** and **100**, both of which are held elsewhere — `099` on `main` and `100` by the open pull request. The CI gate (`release/tools/check-adr-numbers.py`, wired in `repo-integrity.yml`) evaluates the **merge** of this branch into `main`, so the sequence closes as the two holders land; the `ADR-100` holder merging first is the pre-merge condition this release verifies at Stage 12, and the gate is the mechanism that refuses to let a real gap ship silently.

## Context

[`release/references/standards/quota-budget-protocol.md`](../references/standards/quota-budget-protocol.md) § 5 sizes a spoke by an **ordinal band** keyed to its work-item size label (`size:S` → lowest … `size:XL` → highest). The band is a relative ranking, deliberately not an absolute token count: it lets Checkpoint A rank a batch's worst-case draw before any telemetry exists.

§ 5 then names its own successor:

> Once the `spoke-launch` / `quota-reservation` event … has accumulated per-spoke startup-token observations, the heuristic is replaced by observed medians per size bucket, and the cost estimate becomes an absolute figure Checkpoint B compares against the remaining envelope directly.

That event was created by **[ADR-026](ADR-026-spoke-launch-quota-reservation-telemetry-event.md)**, which decided — correctly, on the evidence then available — that per-spoke quota telemetry needed a new top-level `event_type` rather than a `tokens_used:` key on the existing `test-run` event. ADR-026's reasoning about the *writer contract* remains sound and is not disturbed here.

Three findings, established at Stage 5 and re-verified at Stage 6, change what "the successor" should be.

**1 — The declared substrate has no producer.** A structured probe over the whole corpus (not a substring sample), with the historical release corpus and ADR records excluded as controls, finds `spoke-launch` in exactly **four live sites**: the `pipeline-event-log-schema.md` § 3 enum row, two citations inside `quota-budget-protocol.md` itself, and the `append-pipeline-event.sh` static-fallback validator enum. **Zero emitters.** `release-hub`'s own `references/spoke-launch.md` — the file that governs the spoke-launch step — never mentions `quota-reservation`, `tokens_used`, or startup cost. The event type is **defined and validated but never written**.

**2 — The declared unit is not the quantity the gate consumes.** § 4.1 names the input "per-spoke **startup-cost** telemetry"; ADR-026 calls it "per-spoke **startup-token** consumption." But § 4.2 step 2 computes `N_planned × per-spoke-cost-estimate` and compares the product to the **remaining usage-window envelope** — and the usage window meters *cumulative total token consumption* (§ 1). A startup reservation is the prompt-construction cost at spawn. It is not what a spoke draws over its life, and the two differ by roughly the whole body of the spoke's work. Substituting one for the other would make the gate's arithmetic confidently wrong in the safe-looking direction: it would under-estimate the batch's draw.

**3 — The keys do not line up, but a local bridge exists.** § 5 keys on **size bucket per spoke**; the FinOps store keys on **work item**. The bridge is entirely in-repo: a `rollup` row keyed `milestone:vX.Y` joins `RELEASE_LOG.md`'s governed `**Velocity:**` field for that version → `(planned points, release class)` → **tokens-per-point** → × the canonical point scale (`size:M` = 4 pts) → an **absolute token figure per size bucket**. Every hop is local, tracked, and reproducible.

So the estimation engine shipping in this release is a materially better successor on **substrate availability**, **unit correctness**, and **locality**. Recording that requires a decision, because it contradicts a recorded one.

## Decision

**The FinOps usage store's cumulative per-spoke draw — surfaced by `core/skills/finops-usage-extractor/scripts/estimate-usage.sh` — becomes the primary successor substrate for `quota-budget-protocol.md` § 5's per-spoke cost estimate. ADR-026's `spoke-launch` / `quota-reservation` event is retained as a declared-but-unwired secondary signal, not deleted.**

Four consequences, all of which land in this release:

1. **§ 5's supersession sentence is replaced by a per-bucket, conditioned cutover predicate** (below). The ordinal band is **retained as the floor** for any bucket that does not meet it.
2. **§ 5 names both candidate substrates and their unit divergence** — `spoke-launch` / `quota-reservation` measures a *startup reservation* and is **defined in the schema enum but not currently emitted**; `estimate-usage.sh` measures *cumulative per-spoke draw*, which is the quantity § 4.2's arithmetic consumes.
3. **§ 4.1's "Observed per-spoke actuals" input row gains the second source** with its unit label.
4. **`stage-04-planning.md`'s `### Quota Budget` source enum is extended** so a release plan can actually express the new source.

**What is NOT decided here.** ADR-026 is **not reversed** and its event is **not retired**. Its writer-contract reasoning stands, its schema row stays, and `pipeline-event-log-schema.md`'s "consumed by the quota-budget gate" phrasing remains true — the event is still a *declared* input. If it is ever wired, it supplies a genuinely different (startup-only) signal that **composes** with cumulative draw rather than competing with it: startup cost bounds the fixed per-spawn overhead, cumulative draw bounds the total. The supersession is scoped to the **substrate choice for § 5's cost estimate**, nothing wider.

### The cutover predicate — per bucket, never global

Per size bucket `B`, the telemetry estimate supersedes the ordinal band for `B` when **all** of the following hold at evaluation time:

| # | Condition | Provenance |
|---|---|---|
| **(i)** | `n_B ≥ 3` eligible comparables contribute to `B`'s figure | the platform-wide N=3 calibration threshold (`gate-evaluation-spec.md`) |
| **(ii)** | `rMAD_B ≤ 0.50` | the attribution convention's WARN boundary. Above it the telemetry's spread exceeds the ordinal band's own resolution, so an absolute figure is *less* informative than a ranking, not more |
| **(iii)** | the estimate's rendered confidence for `B` is **≥ MEDIUM after all caps** | so a network-resolved or best-effort-heavy population cannot silently promote itself |
| **(iv)** | the best-effort attribution **token fraction** for `B`'s comparable set is `≤ 0.50` | the convention's FAIL boundary |
| **(v)** | the **leave-one-out median absolute percentage error** over `B`'s comparables is `≤ 50 %` | measured by `estimate-usage.sh --delta`, which ships in this release |

**A bucket failing any condition keeps its ordinal band.** A **mixed state — some buckets superseded, some not — is the expected steady state, not a defect.** § 5 says so explicitly, because a reader who treats partial supersession as a broken cutover will either force it or abandon it.

Conditions (i)–(iv) measure **precision** — that the comparables agree *with each other*. Only **(v)** measures **accuracy** — that they agree *with reality*. A tight cluster of systematically-wrong comparables passes (i)–(iv) cleanly. Condition (v) is admissible only because `--delta` ships here; had it been deferred, § 5 would have had to state in the same sentence that the supersession is precision-validated only.

All five thresholds are `[CALIBRATE-AFTER-3]`: no usage distribution exists to calibrate them against, because data hygiene forbids reading the operator-local store from the public repo and no store is committed.

## Alternatives Considered

| Option | Verdict | Rationale |
|---|---|---|
| **(A)** FinOps store becomes the successor; `spoke-launch` telemetry is **retired** as the declared input | **REJECTED** | Cleanest on paper, but it reverses ADR-026 rather than refining it, and it discards an event whose *startup-only* signal is genuinely different from cumulative draw. Retiring a surface that has never been tried is a decision made on absence of evidence. |
| **(B) — ADOPTED** | **SELECTED** | FinOps primary, `spoke-launch` retained as declared-but-unwired, both recorded in § 5 with their unit difference. Minimal-change and honest: it preserves ADR-026's decision as *not yet realized* rather than *reversed*. Reversibility **CHEAP**, confidence **HIGH** — the § 5 amendment is text in one file, revertable in one commit, with no data migration and no runtime behavior change (Checkpoint A stays advisory; Checkpoint B's verdict logic is untouched). |
| **(C)** Wire `spoke-launch` emission in this release and use it | **REJECTED** | Out of scope — a `release-hub` / `hub-spoke-bridge` change with zero overlap with the estimation slice's affected-files set, and it would still measure the wrong quantity for § 4.2's arithmetic. |
| **(D)** Change nothing in § 5 | **REJECTED** | Leaves the protocol pointing at an unwired substrate while a wired one ships in the same release. It also fails the estimation slice's own stated scope, which names the § 5 reconciliation. |
| **(E)** Amend § 5 silently, with no ADR | **REJECTED** | The change contradicts an Accepted ADR's substrate choice. Nygard: a recorded decision is extended or reversed by a successor, never edited out from underneath. A silent swap is precisely the drift this record exists to prevent. |

## Consequences

**Positive.** § 5's successor is a substrate that (a) exists and is emitted today, (b) measures the quantity § 4.2 actually consumes, and (c) is local and reproducible, so a cutover decision can be re-derived from the repo at any later date. The cutover is *conditioned* rather than declarative, so it cannot fire on a population too thin or too dispersed to support it. Condition (v) makes it the first cutover in the corpus gated on measured **accuracy** rather than self-consistency alone.

**Negative / accepted.** The corpus now carries two declared substrates for one estimate, which a reader could mistake for redundancy; § 5 mitigates this by naming the unit divergence in the same paragraph. `pipeline-event-log-schema.md`'s "consumed by the quota-budget gate" phrasing describes a declared consumer that has never fired — **accepted as residual** and flagged here so a later reader does not mistake it for a wired integration; revisit if a future ADR takes option (A).

**Blast radius.** `quota-budget-protocol.md` carries a 24 first-order / 321 second-order referrer fan-out (**Structural**). The edit is therefore deliberately confined to one amended sentence, one appended paragraph, one input-table row note, and one calibration bullet — **no section renumber, no heading change, no deletion**. Of the 24 first-order referrers, 19 are historical release plans, notes, and log rows (immutable records, not edited); of the five live consumers, only `stage-04-planning.md` restates the substrate enum and it takes a one-line extension.

**Reversibility: CHEAP · Confidence: HIGH.** Reverting is a text revert in two files plus a status flip on this ADR. No data migration, no schema change, no runtime behavior change: the estimator is read-only and the gate's verdict logic is untouched.

## Related ADRs

- **[ADR-026](ADR-026-spoke-launch-quota-reservation-telemetry-event.md)** — creates the `spoke-launch` / `quota-reservation` event. **Superseded in its substrate choice for § 5 only**; its writer-contract reasoning and its schema row stand.
- **[ADR-101](../../core/ADRs/ADR-101-finops-store-frozen-kind-versioning-exemption.md)** — the FinOps store's schema-versioning exemption; the same release, the same store.
- **[ADR-094](ADR-094-extend-before-create.md)** — extend-before-create; the reason the estimation capability extends `finops-usage-extractor` rather than shipping a sibling skill.
- `release/references/standards/quota-budget-protocol.md` § 4.1 / § 5 / § 7 — the amended surfaces.
- `release/references/pipeline/stage-04-planning.md` — the `### Quota Budget` plan scaffold whose source enum this decision extends.

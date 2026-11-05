---
title: "ADR-230 — Release cost is stated in weekly points of one account, counted once per API response, attributed to the release run graph's four elements, and reported at both ends of the cache-read-weight bracket"
status: Proposed — authored at Stage 6 Engineering for the release-usage-measured-right release; re-grounded while Proposed at the release's first calibration revisit, against its harness-and-meter probe results; ratification is the operator's at the Stage 13 close gate and is recorded in this field.
date: 2026-11-05
release: release-usage-measured-right
deciders: "Workspace owner (D-Home and D-Revisit rendered at the Collective Review scope-lock; ratification at this release's Stage 13 close gate); direction set at Stage 5 Solutioning against scored candidate sets and an independent adversarial design review; authored at Stage 6"
tags: [architecture, finops, cost-model, measurement, quota, calibration, release-mechanics, platform-config, reversibility-moderate]
source_observations:
  - "The filing card found three unit errors when reconciling release-efficiency figures against transcripts: a usage store counting per transcript line (×2–3), a harness subagent total that is final context rather than consumption (≈100×), and weekly-meter deltas shared with concurrent runs (≈5×)."
  - "A local census of release sessions on disk (operator-local, not tracked; 4,047 spokes and 207 hubs over about two months to 2026-09-26) found cache reads ≈97% of raw tokens but a minority of the allowance draw. It fixed weekly points of one account, bracketed on the cache-read weight, as its ranking unit before any lever was ranked."
  - "Calibration at authoring (same census): 857 meter readings. Clean pairs — exactly one session tree active — numbered 1 on the five-hour window and 0 on the weekly window, below the three-pair floor, so the calibration was declared insufficient and bracketed. A Theil–Sen fit put the cache-read weight near 0.0075 (weekly) and 0.011 (five-hour) of an uncached input token, attenuation-biased low; the API list-price ratio is 0.10. Weighted tokens per weekly point, median over account-clean weekly pairs (intervals in which only this account drew, possibly across several session trees): 3.94M low (IQR 2.37–5.56M) and 12.39M high (IQR 6.79–14.25M). One weekly point ≈ 4.1 five-hour points at both ends. Absolute figures were stated at about ±30%. The census recorded no per-model split, so the seed calibration names no calibration model."
  - "The cache-write (1.25 five-minute, 2.0 one-hour) and output (5.0) weights are API-price-relative assumptions, not fitted; the output weight is unconstrained by the data."
  - "Per-line ÷ per-response factors at filing: ×2.33 cache-read, ×2.74 cache-write, ×1.78 output, ×3.35 uncached input. At this release's planning (2026-11-05) a one-session re-run gave 2.50–2.91."
  - "Coverage limits measured at this release's design (2026-11-05). Two lower the figures: advisor and fallback sub-call usage, carried only in other-type usage iterations, is not read by the store (≈0.49% of raw mass in a sample); and on some harness builds most spawned-agent responses carry no final usage (53–93% of them on the affected builds; at least 15.9% of per-response spoke output across the local transcripts), which the store flags as incomplete. One raises them: count-once holds within a transcript file, so a response that a resumed or forked session copies into a second file is counted twice — 2.52% of per-response mass across the full local population, 7.39% of main-session mass and 0.28% of subagent mass. Each also enters every absolute figure through K, which is fitted from the same store."
  - "Composition at the census mix (cache reads ≈35.7B of ≈36.4B raw tokens; inferred from the census figures): the bracketed cache-read term is at most ≈28% of W at the low end of the bracket and at least ≈50% at the high end. The rest of a low-end figure rides on the price-relative weights, chiefly the unfitted output weight."
---

# ADR-230 — Release cost is stated in weekly points of one account, counted once per API response, attributed to the release run graph's four elements, and reported at both ends of the cache-read-weight bracket

## Status

**Proposed.** Authored at Stage 6 Engineering for `release-usage-measured-right`. While it is Proposed, the release's first calibration revisit re-grounds it against the harness-and-meter probe results that bear on the unit — which weekly windows each model and the advisor draw — and re-confirms or amends Decision 1 (the window) and Decision 3 (per-model draw) there. Ratification is the operator's at the Stage 13 close gate and is recorded in the frontmatter `status:` field.

*Numbering:* allocated at authorship from the mainline anchor, bound at merge. In-release citations of this record are slug tokens until the Stage-12 stamp (ADR-115, ADR-181).

## Context

- Release efficiency has been argued in raw tokens and harness totals. Reconciling them against transcripts found **three unit errors**, each large enough to reverse a conclusion:
  1. **Per-line counting.** The store summed usage over every transcript line, while the transcript writes one line per content block and repeats the response's usage on each. Figures were inflated by a type-dependent factor, between about ×1.8 and ×3.4 when the defect was found.
  2. **Final context reported as consumption.** The harness's per-spoke token total is the size of the final context, not the draw. Read as a cost, it misstates consumption by about two orders of magnitude.
  3. **Shared weekly-meter deltas.** The weekly meter is account-level, so a delta read across a run includes every concurrent session — about five times the run's own draw on the run that exposed it.
- Raw tokens also mislead on their own. Cache reads are almost all raw tokens but a minority of the draw.
- The meter's cache-read weight is unpublished, and concurrency left too few clean intervals to fit it, so it is known only as a bracket.
- "Release graph" already names the issue-dependency graph the Stage-3 critical-path analysis walks. The cost model needs a different graph, and a different name for it.
- *Drivers:* figures falsifiable against transcripts; robust to the unknown weight; attached to the run's elements, so levers compare.

## Decision

1. **The unit.**
   - One **weekly point (wp)** is one percentage point of a single account's shared all-models weekly allowance; 100 wp is one account's full week.
   - Points of any other window — the five-hour window, a per-model weekly window — are other units. They are reported as their own figures, never summed into wp or converted silently.
   - A release that drew on several accounts sums points of one account's week. That presumes one plan, because the calibration is per plan.
   - A *planned point* (size points) is a different quantity. A per-planned-point figure divides wp by the release's **raw** planned points as its velocity field records them, never by class-weighted effective points.
2. **Counting.**
   - Token totals enter the unit only as counted once per API response **within one transcript file**: the assistant records of a transcript that share one `message.id`, each usage field taken at its maximum across them, and a record with no `message.id` its own response.
   - The store schema's § Counting unit is the single definition, adopted here, not restated.
   - **A copied response is counted again.** A response that a resumed or forked session copies into a second transcript file is counted once in each file. The residual raises figures, and most in main-session (hub) figures (source observation 6). Removing it needs a cross-file index, which the store does not carry.
   - Only top-level usage is read. Usage carried only in other-type usage iterations (an advisor or fallback sub-call) is outside every figure until the store reads it.
   - A store written before per-response counting yields no figure in this unit; its `meta.schema_version` names its counting unit.
   - A harness per-session total is never a consumption figure.
3. **Conversion.**
   - `W(w) = input + c5·cache_write_5m + c1·cache_write_1h + o·output + w·cache_read`, in uncached-input-equivalent tokens. `c5`, `c1` and `o` are the price-relative weights of a five-minute cache write, a one-hour cache write and an output token; `w` is the cache-read weight.
   - A figure is `wp = W(w) / K(w)`, summed over the responses it covers.
   - Thinking is part of output. A cache write with no tier split (written before the one-hour tier existed) is weighted at the five-minute tier.
   - The price-relative weights are **API-price-relative assumptions, not fitted**; the output weight is unconstrained by the authoring data. Only `w` is bracketed, and only `K` is fitted, until a revisit fits the output weight (Decision 8). Their values were seeded once, at authoring — `c5` 1.25, `c1` 2.0, `o` 5.0 — and are named by role everywhere else.
   - **Per-model draw.** A model's draw per weighted token can differ from the calibration model's. The numeric home carries an optional per-model axis: a **draw multiplier** relative to the calibration model, and the **weekly window or windows** the model draws. The conversion applies a recorded multiplier per model over the store's exact per-model split. A model with no recorded entry is **unprobed**: its figures use the shared values and say so. A model whose recorded windows exclude the shared all-models window draws no weekly points; its draw is a figure in its own unit (Decision 1).
4. **The bracket.**
   - `w` is bracketed between a low end, where the meter readings point, and a high end, the API list-price ratio. At authoring the bracket is **0.0075–0.10**, the ends seeded in the numeric home and named by role everywhere else.
   - A figure in this unit **is a pair**: the low end computed with the low `w` and its own `K`, the high end with the high `w` and its own `K`.
   - A single number, a midpoint, or a value mixing one end's `w` with the other's `K` is not a figure in this unit.
5. **Claims.**
   - An efficiency claim in this unit leads with **shares** at each end. `K` cancels out of a share, so shares are robust to the calibration of `K` — **not to the price-relative weights**, which do not cancel. At the authoring census mix most of a low-end figure rides on those unfitted weights (source observation 7), so a low-end share for an output-heavy element is mostly the assumed output weight.
   - Shares are taken over the grand total, the unplaced remainder included (Decision 6), and the remainder's share is reported beside every lever claim.
   - Absolute figures are labelled `calibration: insufficient` while fewer than three eligible clean pairs exist (Decision 8).
   - A comparison whose direction or rank differs between the ends is labelled `bracket-sensitive`.
   - A comparison that spans a change of store coverage — a harness build that writes final usage where an earlier one did not, or a store that reads usage an earlier one could not — is labelled `coverage-sensitive`, because coverage moves figures as well as efficiency does.
   - A comparison that spans a change to a calibrated value re-expresses both sides under one set of values, from their stored per-response totals.
   - **A choice between alternatives goes by dominance.** An alternative is better only when it is better at both ends. A `bracket-sensitive` comparison is reported as unresolved, never settled by either end alone.
6. **The release run graph.** (The filing card's "release-graph elements" are these four.)
   - **Nodes** are model sessions — hub, Agent-tool spoke, chip, workflow agent, reviewer — each one context window's lifetime, with stage and role as attributes.
   - **Edges** are a spawn (a brief), a return (a result) and a wait (CI, another node's runtime, an operator gate, a usage-window reset).
   - Each node's spend partitions into four **elements**. Every block of context is costed at its write plus its re-reads on every later response.

   | Element | What it holds | Lever family |
   |---|---|---|
   | node bootstrap | the fixed starting load: system prompt, tool definitions, always-loaded instructions, anything injected before turn one | lean, node-scoped context |
   | edge payload | what crosses an edge: a brief (the parent's output; the child writes and re-reads it) and a return (the child's output; the parent writes and re-reads it) | templated briefs, bounded returns |
   | edge wait | what waiting costs: the rewrite of already-written context when the first response after an idle gap longer than the cache lifetime rewrites it, and turns whose only act is to wait or poll | the wait-edge contract |
   | node loop | everything else a node spends on its own work: output that is not a payload, tool calls and results, reads, and their re-reads | verify-not-rediscover; scripts |

   - Tokens a classifier cannot place in an element are a named remainder, **unplaced**, never folded into an element. Unplaced is orthogonal to the attribution convention's `unattributed` work-item bucket (ADR-097): unplaced asks which element, unattributed asks which work item, and one figure can be either, both or neither.
   - An attribution reports its unplaced share. A conservation identity over the elements and the remainder holds for any placement, placing nothing included, and so proves nothing: a classifier is proven by labelled fixtures, not by conservation (ADR-097's rule, carried forward).
   - Graph shape and scheduling are causes, not elements. A killed node keeps its spend in its elements and is flagged lost.
   - Lever claims attribute to the elements. The per-release accounting row attributes by stage, role and token type, and adds the element split once a classifier exists.
7. **One numeric home, one implementation.**
   - The calibrated values — both ends' `w` and `K`, the price-relative weights, the calibration model and the per-model axis — live only in the `[cost_unit]` section of the platform behaviour configuration.
   - At authoring it was seeded with the values above, with `K` at 3.94M (low) and 12.39M (high) input-equivalent tokens per weekly point, no calibration model (the authoring census recorded no per-model split) and no per-model entry.
   - Every other surface names the values by role and restates no magnitude, so a recalibration is a one-line edit. The section resolves on two rungs, the shipped default and the operator's individual configuration; an operator calibrating for their own plan sets the individual rung.
   - Every figure-producing tool gets wp from one conversion in the FinOps measurement layer. It reads that section and fails closed: an unresolvable value yields an unresolved figure, never zero and never a built-in constant.
   - A change to what the unit **is** (its window, counting, terms, partition or pair rule) supersedes this record. A change to a calibrated **value** is an edit to the numeric home.
8. **Calibration and its revisit.**
   - A *clean pair* is two readings of one meter instance (one window label, one reset time), at settled boundaries and at least two points apart. Over its interval exactly one instrumented session tree drew on the account, and the operator attests no other Claude usage — chat and desktop-agent usage draw the same meter and leave no transcript.
   - A clean pair is **eligible** for the shared calibration only when its interval is also:
     - **single-model** — every response ran on the calibration model or on a model with a recorded multiplier; while the numeric home names no calibration model, a revisit whose eligible pairs all ran on one model names that model;
     - **advisor-free** — no response carries an advisor or fallback iteration, while the store cannot read them;
     - **store-complete** — no response is flagged incomplete, and no message id is duplicated across transcript files.

     A probe that varies the model tier or calls the advisor by design yields pairs that are ineligible for the shared calibration; its readings serve the per-model axis instead. A revisit that pools zero eligible pairs is an expected, honest outcome.
   - `K` at each end is the median, over eligible pairs, of weighted tokens per point. The calibration is **sufficient** at three eligible pairs.
   - **After each instrumented run** — a probe window or a run on an otherwise idle account whose weekly-meter readings bracket the work at settled boundaries — the calibration is revisited:
     - the run's eligible pairs are pooled with the earlier ones;
     - `K` is recomputed at both ends;
     - when the pooled pairs vary in output share, the output weight is fitted alongside `w`, and it is bracketed once a pair constrains it.
   - **A value moves only on sufficient evidence.** Below three pooled eligible pairs, the revisit records each pair's ratio and the seeded values stand. From three, `K` moves to the recomputed median. The `w` bracket narrows only when both hold: the fit's interval lies inside the current bracket, and the pooled pairs span distinct cache-read shares, whose least and greatest the revisit records. A fit outside the bracket widens it, and that is recorded.
   - **Each revisit leaves one dated line, changed or not**, in this rule's row of the gate-coverage register (`core/standards/gate-efficacy-standard.md`). The line names the record that holds its pairs — each pair's readings, window label, reset time, and `W` at both ends — so a reviewer can recompute it. It states the pairs pooled, the pairs excluded and why, whether the calibration is sufficient, and whether a value changed. The numeric home moves only when a value does.
   - Runner: NONE — a registered named gap. The declared observable is that line, held in the gate-coverage register.

## Alternatives Considered

- **Raw total tokens** — REJECTED: it ranks levers by the cheapest token.
- **API-price weights alone** — REJECTED: one guess at the weights; kept as the high end, not as the unit.
- **One fitted point** — REJECTED: confounded and biased low, and it hides bracket sensitivity.
- **The midpoint** — REJECTED: it asserts an unmeasured weight.
- **Five-hour points** — REJECTED: the weekly allowance is the binding axis across concurrent releases.
- **A per-release meter delta as the cost** — REJECTED: unit error 3; it calibrates the unit, it cannot replace it.
- **Six elements, adding graph shape and scheduling** — REJECTED: they double-count.
- **A remainder named `unattributed`** — REJECTED: that word is ADR-097's work-item bucket, and one figure would carry two meanings.
- **Values held in this record** — REJECTED: each recalibration would need a superseding record (ADR-183).
- **Values held as constants beside the conversion** — REJECTED: no instance override, so an operator on another plan would edit a tracked file the update path overwrites.
- **A model-agnostic numeric home** — REJECTED: a model comparison could only be stated outside the unit, which is a parallel unit decision.
- **Per-consumer conversions** — REJECTED: two implementations drift.
- **A value moved on any revisit** — REJECTED: one pair would replace the seed, with nothing a reviewer can recompute.

**Chosen:** weekly points of one account, counted once per API response within a transcript file, converted by one implementation from one numeric home, reported as a pair at the two ends of the cache-read-weight bracket, attributed to the release run graph's four elements plus a named unplaced remainder, and recalibrated only on sufficient eligible evidence.

## Consequences

- **Easier:** claims are comparable and falsifiable; a lever names the element it moves; recalibration is a value edit; a model's draw lands as a value edit once a probe records it; the cost row keeps per-response totals by type, so it can be re-expressed.
- **Harder:** every figure is a pair; absolutes stay labelled until three eligible clean pairs exist; earlier per-line figures are incomparable; a low-end share rides largely on the unfitted output weight until a revisit fits it. Advisor sub-calls and incomplete responses lower the figures, and copied session history raises them, until the store reads them correctly. Each also moves every absolute figure through `K`, which is fitted from the same store, so these are limits of the unit's absolutes as well as of the store; shares within one coverage regime do not depend on `K`.
- **Consumers — each states its figures in this unit and records no parallel unit decision:**
  - the Stage-13 per-release cost row (by stage, role and token type, at both bracket ends);
  - the release-run efficiency criteria of the thrust's outcome check (already stated in this unit);
  - the quota-budget gate's weekly-allowance axis;
  - the command-template cost ranking;
  - the model-use policy's cost claims (with Decision 3's per-model labels and Decision 5's dominance rule).
- **Not changed:** the store's record kinds; the quota gate's verdict logic and its per-spoke substrate (ADR-102); the standing model and effort directive.

## Reversibility

- **MODERATE / Confidence MEDIUM** for the definition: restating the criteria, the row and the reports means days of rework within one project, and no data is lost.
- **CHEAP** for a calibrated value: a one-line edit to the numeric home.

## Related ADRs

- ADR-096 — the usage store and its data home.
- ADR-097 — the attribution convention, whose `unattributed` work-item bucket the unplaced remainder is orthogonal to.
- ADR-101 — how a counting change to the store is versioned; not re-decided here.
- ADR-102 — the quota-budget gate's per-spoke substrate, given a calibrated expression.
- ADR-183 — one numeric home, with meaning stated by role.
- ADR-022 — why the platform behaviour configuration holds the values.
- ADR-095 — where a model-use change lands.
- ADR-115 and ADR-181 — the number binds at merge, and in-release citations are slug tokens.

## References

- #7940 — the card that filed this decision.
- #7937 — per-response counting and the store schema's § Counting unit.
- #7938 — the incomplete-response flag.
- #7943 — the per-release cost row and the single conversion.
- #7854 — the outcome check whose criteria use this unit.
- #7536 — the weekly-allowance axis that adopts it.
- #7945 — the command-template cost ranking.
- #8041 — the model-use policy.
- #7935 — the harness-and-meter probes that first revisit the calibration.
- #7934 — the token-efficiency thrust.

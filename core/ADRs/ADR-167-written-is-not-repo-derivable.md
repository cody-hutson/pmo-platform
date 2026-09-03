<!-- reference-durability: allow-link -->
---
title: "ADR-167 — A warn-mode declaration carries two axes; only the repo-derivable one can end a shakedown"
status: Accepted
date: 2026-08-29
release: warn-mode-gate-graduation
deciders: "Stage 5 Solutioning spoke (design, evidence-grounding) + operator ratification at Collective Review (D-5 AC re-render, D-6 window acceptance, D-9 fork resolution, D-11/D-23 ADR authorization) + Stage 6 Engineering spoke (build, cross-sibling reconciliation)"
tags: [gate-efficacy, warn-mode, progressive-rollout, deploy-check, flip-decision-register, drain-evidence, ADR-166, ADR-106]
source_observations:
  - "The ticket named the defect as `the declared *-warn-log drain sinks are never written`. Measured at the release baseline, that premise was 2-of-3 true: the two per-gate sinks (`gate-g3-14-warn-log.jsonl`, `gate-g3-15-warn-log.jsonl`) are genuinely absent, but the third named sink — the shared `deploy-check-warn-log.jsonl` — carries 385,770 rows across 62 distinct check ids and is written continuously."
  - "The cohort whose sink IS written cannot graduate either. Checks 8 / 10 / 13b / 34–37 write to that shared sink at scale and have been held at an undated `shakedown continues` throughout. Writtenness was therefore never the binding constraint, and a convention naming only that axis would have licensed the identical dead end."
  - "Every `*-warn-log.jsonl` in this repository is git-ignored. A pull-request agent, a CI runner, and a fresh clone are all structurally blind to every drain, so implementing the two missing sinks would have produced two more files nobody reviewing a change can read."
  - "Zero executables reference `g3-14` or `g3-15`. Across every `.sh` / `.py` / `.yml` / `.yaml` file at the baseline the only hit was a comment; the control arm on a gate known to have a runner returned a non-zero count and the fabricated-id specificity arm returned zero. There was no emitter to append a row to — `implement the sink` meant inventing a writer class on a surface that had none."
  - "The corpus had already solved this once, for a different subject. The `BLOCK-DESTRUCTIVE-022` exec arm is recorded as DEFERRED WITH A DEADLINE, splitting its criterion into a repo-derivable deadline arm and an operator-local evidence arm, and the flip-decision register states the generalization in prose immediately below it: *make the forcing function repo-derivable and let the evidence stay operator-local*. It had exactly one instance and no binding force."
---

# ADR-167 — Written is not repo-derivable

## Status

**Accepted.** Ratified at the `warn-mode-gate-graduation` release's plan-review gate.

**Numbering provenance.** Allocated at this Engineering commit as the next number above the union of the mainline anchor and this branch's own in-flight claim. `renumber-adr.py --detect` reported `ANCHOR 162 origin/main`, `NEXT-FREE 163`, and `CLAIMED-SET-BRANCH-ONLY 163 (detection only — never binds)` — the oracle is anchored on mainline and cannot see a sibling's unmerged claim, so `--next-free` alone would have collided with [ADR-166](ADR-166-split-predicate-gate-graduation.md) on this same branch. 164 was taken against the union and re-verified to report `BINDS`. A gap blocks the repo; a duplicate is tooled at merge, so the union is the safe side to err on.

**Numbering provenance — `164 → 167`.** Held **ADR-164** branch-local; renumbered to **ADR-167** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 164. In-release citations that read "ADR-164" denote this record.

## Context

`core/standards/gate-efficacy-standard.md` § *Flip-decision status* records, per warn-mode gate, whether it graduates to enforce. Its stated criterion is the gate's **drain history** — the accumulated rows in its `*-warn-log.jsonl` — and it is explicit that a green-on-current-tree snapshot is not a substitute.

That criterion cannot be evaluated by anything in the pipeline. Every drain is git-ignored, so the reader who would act on it — a pull-request agent, a CI job, a fresh clone — cannot see it. The register knows this and says so in its own premise. The consequence is that `shakedown continues` became a disposition with no observation that ends it, and the register accumulated rows that could not be closed.

The originating ticket read this as an **implementation gap**: two gates declare sinks that are never written, so write them. That reading is half right and, taken alone, would have made things worse.

**The measured shape of the defect is different, and the difference is the whole decision.** A warn-mode declaration makes two separable claims that the register's single criterion conflates:

- **Is the sink written?** Does any code path append rows for this gate's id to a file that exists?
- **Is the shakedown terminable?** Is there an exit criterion evaluable from committed state?

These are independent, and the cohort splits on them. Checks 8 / 10 / 13b / 34–37 answer **yes** to the first — 385,770 rows, 62 ids, written continuously — and **no** to the second, and they have been stalled the entire time. G3-14 / G3-15 answered **no** to both. Implementing the two missing sinks would have moved the first axis for two gates and moved nothing at all on the axis that was actually holding the cohort, while adding two more git-ignored files a reviewer still cannot read.

A convention naming only writtenness would therefore have been *satisfiable by a change that fixes nothing*, and would have licensed the identical dead end for the next gate that declared one.

## Decision

**A warn-mode declaration carries two axes, and both are stated per gate in its flip-decision register row.**

- **W1 — the sink is written.** A drain-history flip criterion may be declared only where some code path appends rows for that gate's id to a sink that exists. Otherwise the declaration carries the `specified, not yet emitting` disclosure and declares no drain-history criterion. A zero drain is **INSTRUMENTATION-SUSPECT**, never "no evidence yet" — a zero whose instrument was never connected measures the wiring, not the behaviour.
- **W2 — the shakedown is terminable.** The exit criterion must be evaluable from **committed state**: a deadline arm, a committed phase constant, or another repo-derivable forcing function. The evidence arm may stay operator-local; it informs and triggers nothing.

Three subordinate rulings follow, each recorded because a future author would otherwise re-derive it:

**1. The forcing function is repo-derivable; the evidence stays operator-local.** This generalizes the `BLOCK-DESTRUCTIVE-022` DEFERRED WITH A DEADLINE shape from its founding hook instance to the stage-gate class, and gives the register's own prose recommendation binding force. The split is deliberately asymmetric: the deadline arm reads committed constants and today's date and may increment `ISSUES`; the evidence arm reads a drain and touches `ISSUES` on no path, so CI and a fresh clone observe no behaviour change from it at all.

**2. Per-gate sink files are not the convention and are not introduced.** The platform's only realized sink form is the single shared `$(pmo_instance_path)/deploy-check-warn-log.jsonl`, discriminated by the row's `check:` field, carrying 62 live ids. The per-gate form had zero instances in code, and the `core/hooks/<rule>-warn-log.jsonl` shape G3-14 / G3-15 borrowed is the **hook-layer per-rule** surface — a cross-layer borrow, not a stale prefix. When a runner lands for either gate, its rows go to the shared sink under its `check:` id.

**3. A deadline is a forcing function, not a blocker — so W2 does not reach a disposition that declines the flip.** [ADR-166](ADR-166-split-predicate-gate-graduation.md) § *Second altitude* rules that a disposition must name its **blocker**, not its schedule, because a schedule is unfalsifiable. W2 does not weaken that. The row still names the blocker; the repo-derivable exit criterion is what makes resolving that named blocker non-optional. A row carrying a date and no blocker fails ADR-166; a row naming a blocker with no repo-derivable exit fails W2; a conforming row does both. It follows that `RATIFIED ADVISORY`, and the permanent-residual limb of a `SPLIT DISPOSITION`, are **exempt from W2** — they are not shakedowns, and arming a deadline against a declined flip would manufacture the inverse of this release's defect: a permanent advisory wearing the shape of a temporary one.

### Relationship to the class-3 runner-resolution rule

`gate-efficacy-standard.md` § *Runner resolution — class 3* asks a neighbouring question — does anything **execute** this predicate (R1 carried ∧ R2 reached)? — and the two rules are deliberately recorded as **adjacent axes rather than one rule at two altitudes.** They are disjoint on their own motivating cases in both directions:

- Class 3 admits only passages for which **L2** holds (nothing implements the assertion). Checks 8 / 10 / 13b / 34–37 are implemented `--check` gates, so L2 is false and class 3 structurally never reaches them — yet they are exactly the population W2 exists to catch.
- A class-3-O named-gap row declares no shakedown at all, so W1/W2 never fires on it.

Where a gate is both — class 3 at authoring time *and* holding a warn-mode shakedown, which G3-14 / G3-15 were at the release baseline — they compose in order and neither is optional: class 3's dispositions settle the **runner**; W1/W2 then settles the **sink and the exit** for whatever remains held at warn.

On the overlap, **W2 is strictly stronger, and that is the non-duplicative delta.** Class 3's own enumerated limits record that its declared observable is *reviewer-verified, not machine-checked* (limit 7) and that `runner-def:` cannot reach a surface outside the repository (limit 2). For a warn-mode shakedown, a reviewer-verified observable living in a git-ignored sink **is** the failure mode, so W2 requires the ending condition be repo-derivable — a requirement class 3 does not make and, by its own limit 2, cannot.

## Consequences

**Positive.**

- The register's stated criterion is superseded for a class rather than patched for a gate: a warn-mode shakedown now has a stated, checkable ending condition, and `shakedown continues` is no longer authorable as an undated deferral.
- Two phantom sink declarations are retired rather than implemented. Net surface **decreases** — zero new files, zero new sinks — and the one new check reads committed constants and a date.
- The `BLOCK-DESTRUCTIVE-022` shape acquires a second instance and binding force, so the next author inherits a pattern instead of re-deriving one.
- The evidence arm's inability to gate is a **structural** guarantee (no `ISSUES` path exists) rather than a default a later edit could flip.

**Negative, and accepted.**

- **The 60/90-day windows rest on N=1.** `BLOCK-DESTRUCTIVE-022` is the only in-tree precedent for a repo-derivable rollout deadline, and its values were adopted rather than calibrated. The alternative — these gates' own declared `2–3 release` threshold — was rejected on derivability, because it needs a release-ledger parse rather than date arithmetic and that ledger is reached through an operator-instance token, re-importing the exact portability problem the deadline arm exists to escape. The release-count *intent* survives as prose in the register row. This is recorded as a known-thin premise, accepted by the operator with its basis stated, and it is the value most worth revisiting once a second instance exists.
- **A deadline can be extended by re-dating a constant.** That is deliberate — the one-line edit IS the audit record — but nothing prevents indefinite re-dating. The mitigation is that each extension is a visible, attributable commit rather than silence, which is the whole difference from an undated deferral. No mechanism forbids the pattern, and none is proposed here.
- **W1's disclosure limb makes an honest declaration, not a graduated gate.** Adding `specified, not yet emitting` to a row moves it out of a false claim and into a true one; it does not move the gate. The seven sibling rows already carrying that disclosure remain exactly as unrealized as before.

**Neutral.**

- The convention is class-scoped, so a new warn-mode gate adds a **row**, not a mechanism.
- Seven further gates in `gate-criteria-spec.md` (G4-01, G6-01, G6-06, G-CL6, G-CL7, G-CL8, G-CL9) carry the `specified, not yet emitting` disclosure and satisfy W1 on limb 2 while owing an ending condition under W2. This ADR makes that gradable; it is **not** a claim that any of them has been graduated, and the sweep is deliberately out of scope.

## Alternatives considered

| # | Alternative | Why rejected |
|---|---|---|
| A1 | **Implement per-gate sink emitters** — the ticket's option (a), read literally | Close to infeasible as written (no emitter exists for either id, so it means inventing a writer class on a surface with none) and, more decisively, it would not close the loop: the sinks are git-ignored, so two more unreadable files leave the flip exactly as un-actionable. It also mints the platform's first per-gate sink file, against 62 live ids on the shared form. |
| A2 | **Emit into the shared sink under `check: "g3-14"` / `"g3-15"`** | Correct in form and recorded as the **forward** shape for when a runner lands — but it hits the same wall today: the sink is git-ignored, so writing rows into it does not make the shakedown terminable. Adopted as the forward convention, rejected as this card's mechanism. |
| A3 | **Replace the drain-history criterion with a green-on-current-tree snapshot** — the ticket's option (b), read literally | Eliminated by the register's own text, which states that a green-on-current-tree snapshot is *not* the shakedown criterion because the drain history is. Substituting the thing the register already rejected is not a resolution of the contradiction. |
| A4 | **Retire both gates to `RATIFIED ADVISORY`** | Would declare the flip architecturally refused for both halves. Contradicted by a live sibling card that makes the tree-resident half genuinely gateable, and later contradicted in fact when that card shipped a `required` posture for it. Refusing a flip that is reachable is as wrong as scheduling one that is not. |
| A5 | **State W1 alone** — the ticket's framing, that a warn-mode declaration must name a written sink | The measured case refutes it: the cohort whose sink IS written has been stalled throughout. A one-axis convention would be satisfiable by a change that moves nothing, and would license the same dead end for the next gate. This is the alternative the evidence most directly rules out. |
| A6 | **Generalize Check 71 to carry both subjects** | Its constants and extraction are hard-coded to `DESTRUCTIVE_022_*`; generalizing is a wider refactor of a live gate whose subject is unrelated. The two subjects are separately dispositioned and separately dated, so one check reading both would couple two rollouts that have no reason to move together. |

## References

- [`core/standards/gate-efficacy-standard.md`](../standards/gate-efficacy-standard.md) — § *Written sink and terminable shakedown* (the clause this record decides), § *Runner resolution — class 3* (the adjacent axis), and § *Flip-decision status* (the register this writes into)
- [`core/schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) — G3-14 / G3-15 declarations; the four reconciled sink declarations live here
- [`core/ADRs/ADR-166-split-predicate-gate-graduation.md`](ADR-166-split-predicate-gate-graduation.md) — the split-by-locus-of-input graduation path and the *blocker-not-schedule* disposition rule this record reconciles W2 against
- [`core/ADRs/ADR-106-generated-artifact-retention-purge-declined.md`](ADR-106-generated-artifact-retention-purge-declined.md) — the derived ledgers' **read-path volume obligation**: after an archival sweep, any claim of the form *"X has no source in the ledger"* must be probed across the segment family or it silently under-measures its own control. Measured there on a control that returns **2** against the hot file alone where the true population-wide count is **10**, because the sweep had moved 8 rows into segments. This record applies that obligation to a rotating warn-log drain
- [`core/standards/progressive-rollout-convention.md`](../standards/progressive-rollout-convention.md) — owns the `shadow → warn → enforce` ladder and the phase enum; advance is an operator decision, never auto-promoted by row count

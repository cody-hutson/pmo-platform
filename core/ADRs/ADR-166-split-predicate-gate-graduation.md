<!-- reference-durability: allow-link -->
---
title: "ADR-166 — A gate whose subject is out-of-tree state graduates by splitting its predicate, CI-gating only the tree-resident half"
status: Proposed — flips to Accepted when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-08-29
release: warn-mode-gate-graduation
deciders: "Stage 5 Solutioning spoke (design, evidence-grounding) + hub Procedure 4 adversarial evaluation (D-8 ownership resolution, D-11/D-16 authorization) + Stage 6 Engineering spoke (build, seeded-failure verification)"
tags: [gate-efficacy, verdict-input-closure, progressive-rollout, ci-gates, warn-mode, requirement-b-prime, deploy-check, ADR-092]
source_observations:
  - "G3-14 (Mode-A combined-clean parse-rate floor) and G3-15 (per-milestone risk-weighted size bound) shipped declaring a `warn → enforce` ladder and naming per-gate warn-log sinks. Measured at the release baseline: ZERO executable artifacts implemented either predicate and ZERO computed `effective_pts`; the only `deploy.sh` contact with their config fields was Check 33's field-presence assertion. The ladder had no rung to stand on. Three parties measured this independently — the Stage-5 spoke, the sibling sink-naming card's spoke, and the hub — and agreed."
  - "The hub had told the operator at the Stage-4 D-3 gate that these gates were `deploy-time-only with no CI mirror`. That was wrong, and the error is instructive: the hub had verified only the NEGATIVE half (0 of 22 workflows reference them) and adopted the positive half from the milestone description without measuring it. A verified negative does not license an unverified positive."
  - "Both gates' declared sinks (`gate-g3-14-warn-log.jsonl`, `gate-g3-15-warn-log.jsonl`) are never written. The cohort's advance signal was therefore a file that does not exist, read from a location a pull-request agent cannot reach — so `shakedown continues` was unfalsifiable and self-perpetuating, and the flip-decision register recorded these two gates under the evidence-blocked shape when their blocker was never evidence at all."
  - "Requirement (b′) derives `posture` from the runner: a check with no CI mirror must not declare `required`. Across a denominator of 22 workflow files, 0 reference either gate; sensitivity arm — 13 reference `deploy.sh`; specificity arm — a fabricated gate id returns 0. The zero is a real absence, not a dead probe, so WAITING could never clear the precondition."
  - "Both gates' SUBJECT is out-of-tree GitHub state — issue bodies for G3-14, a milestone's bundled membership for G3-15. Under § Verdict-Input Closure, VIC(W) is defined over repo paths, so that subject class is empty in-tree. G3-15 additionally has no PR-time subject at all: `which milestone?` is undefined outside a Stage-3 Bundle event."
  - "The corpus already carried the shape of the answer in a THIRD disposition it had minted for a different reason: the `version-freeness` row records a flip DECLINED on architectural grounds rather than postponed on evidence, and states plainly that flipping would `declare an enforcement the surface cannot deliver, which Requirement (b) forbids`."
---

# ADR-166 — Split-predicate gate graduation

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering provenance.** Allocated at Engineering Commit 0 by `release/tools/renumber-adr.py --next-free`, which returned **162** against a mainline anchor of ADR-161 across both ADR directories. A concurrent unmerged branch (`release/declarations-have-a-firing-surface`) also claims 162; that claim is advisory until it merges, and the platform's rule is that a duplicate is tooled at merge time by `renumber-adr.py` while a gap blocks the repo. If this record renumbers at merge, the provenance note is appended here rather than rewritten.

**Numbering provenance — `162 → 163`.** Held **ADR-162** branch-local; renumbered to **ADR-163** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 162. In-release citations that read "ADR-162" denote this record.

**Numbering provenance — `163 → 166`.** Held **ADR-163** branch-local; renumbered to **ADR-166** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 163. In-release citations that read "ADR-163" denote this record.

## Context

The gate-efficacy standard's **Requirement (b′)** derives a gate's declared `posture` from its runner: a check that no CI job executes must not declare `required`, because the declaration would claim an enforcement the surface cannot deliver. This is a good rule, and it produced a class of gates that could never advance.

G3-14 and G3-15 are the founding members of that class. They are stage-gate criteria evaluated at the Stage-3 → Stage-4 (Bundle → Planning) boundary, and their subject is out-of-tree GitHub state: the parse quality of issue bodies, and the risk-weighted point sum of a milestone's bundled membership. Neither is a repo path.

That creates a trap with three walls:

1. **Requirement (b′) blocks `required`** while no CI job runs the gate.
2. **A CI job on the live evaluation is architecturally wrong.** Under § Verdict-Input Closure, a workflow's verdict inputs are repo paths. A merge gate reading the live backlog would go red for reasons no PR author can see, cannot reproduce, and cannot fix by editing their branch — and G3-15 has no PR-time subject at all, because a pull request is not a Bundle event.
3. **The recorded disposition was `shakedown continues`, pending drain evidence** from per-gate warn logs that are never written, in a location a PR agent cannot read.

So the gate could not advance by waiting (wall 3 has no producer), could not advance by building the obvious mirror (wall 2), and could not declare the posture it wanted (wall 1). It had been sitting in that state across the `2–3 release` calibration window it declared for itself.

The naive readings both fail. **Build the live mirror** walks into wall 2. **Record a permanent deferral** is honest about the live half but throws away a real, gateable invariant along with it — and it re-litigates a decision the operator had already made the other way.

## Decision

**A gate whose subject is out-of-tree state graduates by SPLITTING ITS PREDICATE BY LOCUS OF INPUT, and CI-gating only the tree-resident half.**

Concretely, for such a gate:

1. **Identify the tree-resident half.** Not the gate's *subject*, but its *machinery*: the evaluator, the fixtures that exercise it, the sink it declares, and the config it reads. All of these are committed files, so all of them are inside VIC.
2. **Gate that half at `required`.** It is network-free and install-independent by construction, so it qualifies for the pre-merge required subset. Its content assertion is stated narrowly and honestly — *the machinery computes its declared predicate and fires on a breach* — and its id names that scope (`bundle-metrics-gate-integrity`, never `bundle-metrics`).
3. **Record the backlog-resident half as a PERMANENT advisory residual**, at its declared stage-gate runner, with the architectural ground stated in the row. Not "deferred", not "shakedown continues" — both of those tell a reader a flip is coming.
4. **Never let the tree-resident row imply the backlog-resident claim.** The coverage row must say what it does *not* assert, in the row, not in a footnote.

The distinguishing test for whether this ADR applies: **can a pull-request author change the gate's verdict by editing their branch?** If yes for some inputs and no for others, the predicate is splittable and this is the graduation path. If no for all inputs, the gate is wholly out-of-tree and belongs at a stage-gate runner in full.

### What makes this honest rather than a workaround

The failure mode this pattern must avoid is **proxy assertion** — gating something cheap and claiming credit for something expensive. Requirement (a) already forbids it. Three properties keep the split on the right side of that line:

- **The narrow claim is stated in the id and in the row.** A reader who sees the check green learns "the machinery discriminates", not "the backlog is clean".
- **The residual is written down as permanent, with its ground.** It is not an open gap someone might later think they should close; it is a recorded architectural fact.
- **The tree-resident half is falsifiable and is falsified on every run.** Its fixtures sit exactly at the threshold, so the comparator itself is under test, and an anti-vacuity control fails unless each gate produced an opposite-verdict pair. A split that gated something unfalsifiable would be a proxy no matter how narrowly it was worded.

### Second altitude — the disposition vocabulary

This decision also fixes the register's disposition vocabulary, and that half generalizes beyond gate graduation.

The flip-decision register's original two dispositions — `flipped` and `shakedown continues` — both imply a flip is coming. `version-freeness` had already minted a third, **RATIFIED ADVISORY** (declined on architectural grounds), and Checks 45(b) / 62 a fourth, **DEFERRED — precondition-blocked, NOT evidence-blocked**. This release adds a fifth: **SPLIT DISPOSITION**, where the two halves of one predicate have different blockers and must not share a verdict.

The generalization: **a disposition must name its BLOCKER, not its schedule.** "Shakedown continues" names a schedule and is therefore unfalsifiable — there is no observation that ends it. "Precondition-blocked", "declined on architectural grounds", and "split by locus of input" each name a condition a reader can go and check. A register whose rows name schedules accumulates rows that can never be closed, which is exactly the state this milestone found.

## Consequences

**Positive.**

- G3-14 and G3-15 gain a real blocking pre-merge assertion, and the cohort they belonged to can now terminate.
- **No gate flips warn → enforce to achieve it.** The `deploy-check-ci.enforce` sentinel still reads `warn`; the unconditional blocking comes from the `install-tests.yml` discrimination arm, which honours no sentinel. The premature-flip blast radius the release classified EXPENSIVE is not incurred.
- Zero new workflows, zero new `.enforce` sentinels, zero new branch-protection contexts, zero added macOS jobs. The two extended workflows were already filter-free, and the required-subset runner's own declaration named this milestone as its back-fill vehicle — so the roster grew through the mechanism it declared rather than around it.
- The `--check-required-subset` roster's growth prediction is now exercised rather than hypothetical, and the deleted `paths:` filter is what made that growth free.

**Negative, and accepted.**

- **Check-run granularity is lost.** Both gates report under one check id and one check-run name. This is the identical tradeoff the required subset already accepted for Check 38; it is mitigated in-band by the runner's per-member `required-subset: <id> — OK/FAIL` line and by the verdict detail naming the failing gate and conjunct.
- **The live half remains unasserted by anything mechanical, permanently.** That is the honest position, not a gap to close, and the register says so in the row rather than in a tracker.
- **A future reader may mistake the narrow claim for the broad one.** The `-gate-integrity` id suffix and the explicit "this row does NOT assert the live rate" clause are the whole mitigation. If either is edited away, the row becomes a proxy assertion.

**Neutral.**

- The pattern is reusable and binds every future warn-mode gate whose subject is not a repo path. `gate-criteria-spec.md` currently carries "specified, not yet emitting" on G4-01, G6-01, G6-06, G-CL6, G-CL7, G-CL8 and G-CL9 — the same declared-but-unrealized class, one altitude up. This ADR is the method for graduating any of them whose subject is out-of-tree; it is not a claim that any of them has been graduated.

## Alternatives considered

| # | Alternative | Why rejected |
|---|---|---|
| A1 | **Two dedicated workflows** (`g3-14-parse-rate.yml`, `g3-15-size-bound.yml`) + 2 `--check-*` flags + 2 sentinels | SR-G6 extend-before-create fires and is not rebutted: two existing filter-free workflows already cover the capability. Adds 2 unconditional macOS jobs (billed 10×), 2 sentinels and 2 branch-protection contexts, and contradicts `close-completeness.yml`'s recorded "rather than add a fourth workflow and a fourth `.enforce` sentinel" precedent. |
| A2 | **One combined dedicated workflow** | Same objection as A1 at ×1 rather than ×2. Still net-new surface where an extend is available. |
| A3 | **Live-backlog evaluation as a blocking pre-merge check** — the naive reading | Rejected on architecture, and this is the alternative the ADR exists to rule out. Non-deterministic verdict; G3-15 has no PR-time subject; a red verdict is unfixable from the PR. It would declare an enforcement the surface cannot deliver — the thing Requirement (b) forbids. |
| A4 | **Decline the flip; record RATIFIED ADVISORY for both halves; build nothing** | Honest about the live half but discards a genuinely gateable invariant with it, and re-litigates the operator's decision to bring a CI runner into scope. The tree-resident half has real Verdict-Input Closure; declining to gate it would be leaving a closable gap open on the strength of an argument that applies only to its sibling. |
| A5 | **Co-locate in `close-completeness.yml`**, reusing the "rather than add a fourth workflow" precedent literally | Rejected on coherence: that workflow is release-close-scoped and paths-filtered. Bundle metrics share neither its subject nor its trigger set, and joining a filtered workflow would reintroduce the always-reports problem the required posture forbids. |

## References

- [`core/standards/gate-efficacy-standard.md`](../standards/gate-efficacy-standard.md) — Requirements (a) / (b) / (b′), § Verdict-Input Closure, the gate-coverage register and the § Flip-decision status register this ADR writes into
- [`core/schemas/gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) — G3-14 / G3-15 predicate definitions (the definitional home; not edited by this record)
- [`core/standards/progressive-rollout-convention.md`](../standards/progressive-rollout-convention.md) — owns the `warn → enforce → removed` ladder; advance is an operator decision, never auto-promoted by hit count
- [`release/references/standards/bundle-composition-doctrine.md`](../../release/references/standards/bundle-composition-doctrine.md) — § 3 Step 5 Risk-Weighting, the round-half-up definitional home G3-15 cites by reference and conjunct C73-c asserts resolvable
- [`core/ADRs/ADR-092-plan-file-claim-time-stamping.md`](ADR-092-plan-file-claim-time-stamping.md) — the defer-to-claim precedent this record's disposition vocabulary follows: a gate must not be authoritative over a value that is not yet bound
- #4214 — the sibling sink-naming card (“warn-mode declarations must name a written sink”) whose spoke measured the same absence independently; it is the third of the three concurring measurements this record's `source_observations` cite. Its decision record is [`ADR-167`](ADR-167-written-is-not-repo-derivable.md).

---
title: Release Plan — required-checks-enforce-as-declared (Required checks enforce as declared)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; provisional display v4.82; the concrete number binds at the Stage-12 atomic claim)
milestone: required-checks-enforce-as-declared
release_class: novel
reversibility: MODERATE / Confidence HIGH — two warn-to-enforce flips plus tool, test and standard edits on one branch with one merge. Reverting the merge restores main byte-for-byte, but the whole-release rollback is ordered — the operator un-registers both contexts first, then the merge is reverted, then GATE_ROLLOUT_ARMED is re-dated past Check 74's escalation window — so it is MODERATE rather than CHEAP. Each context, and items 2 and 3, revert on their own at CHEAP. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `required-checks-enforce-as-declared`

**Milestone:** `required-checks-enforce-as-declared` (milestone 442). The Stage-4 planning sub-task **#8604** carries the approved plan and the Stage-4 gate's Decision Recorded. The Stage-5 designs and their independent Phase A6.5 adversarial reviews are on **#8615** (#8325) and **#8616** (#8424); the Collective Review scope-lock Decision Recorded is on **#8616**. This file is Engineering Commit 0, authored by the first Stage-6 spoke on **#8617** (#8325).

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v4.82`** (the next-free minor recomputed at this commit). The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only.

**Topology:** D-C **SINGLE** — one release branch, `release/required-checks-enforce-as-declared`, one pull request opened in **draft** after #8325's slice lands, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — Commit 0 and step 1 (#8325, sub-task #8617), then steps 2–6 (#8424, sub-task #8618), one Engineering spoke at a time, each syncing `origin/main` before it starts. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel` — trigger (b), the divergence-definition D-class decision; Stage 9 review depth **Deep** (§ Release Class declaration).

**Date:** merge by **Wednesday 2026-11-25** (Check 74 day 88); the hard date is **Friday 2026-11-27** (day 90). The valve checkpoint is **Tuesday 2026-11-17** (Stage 7 entry, day 80), and steps 1–3 are the valve-safe set.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8604 and is amended by four records, in order: the Stage-4 Decision Recorded on #8604 (plan approved with an AC7 limb added to the Outcome; `novel`; SINGLE; P0; the valve at Stage 7 entry; the #8325 body refresh skipped; D-Version recorded), the two Stage-5 designs, their two Phase A6.5 adversarial reviews, and the Collective Review scope-lock Decision Recorded on #8616 (scope hard-locked through Stage 9; divergence shape (a); bare `posture=required` with AC7 moved into the valve-safe set; a closed posture vocabulary; the five-item adjustment set). Where the plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): protocol text added and modified, per the Bump-Class Selection Guide. Provisional display `v4.82`, re-verified free at Engineering Commit 0 (§ Commit-0 Version Re-Verify Record); the concrete number binds at the Stage-12 atomic claim (ADR-092). It rises to major only if a card selects a skill behavioural change, and none does |
| **Date Created** | 2026-11-03 (Tuesday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — Stage 6 Engineering: Commit 0 (this file), then step 1 (#8325) |
| **Branch** | `release/required-checks-enforce-as-declared` |
| **PR** | opened in **draft** at Stage 6 Phase C2 after #8325's slice; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `required-checks-enforce-as-declared` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-03, domain: governance }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal pmo-platform artifact — CI workflows and a sentinel, the deploy script, a standard, a pipeline stage spec, a tool, its README and its test — so no external body of practice is consumed. Dominant domain **`governance`**; secondary domain software (the reconciler and its conformance suite). Transcribed unchanged from the Stage-4 plan (Phase A1.5).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `f8d88626` (`f8d8862668aa373a37f36f309c54eb364fae2d9b`), equal to the Stage-4 baseline pin. This file is written on that base |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha f8d8862668aa373a37f36f309c54eb364fae2d9b --bump minor --dry-run` (the adapter's own allocation; no tag pushed) | **`v4.82`** (exit 0; "would claim v4.82 (no tag pushed)"). The Stage-4 plan picked no number, so the planned version is this recomputed next-free |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each read by one python3 line scan that compares exact (major, minor) version
             tuples carrying no patch component
Denominator: 452 ls-remote lines (227 distinct versions; the highest is v4.81); 225 published
             Releases (under the 5000 limit, so not truncated); the ledger at origin/main,
             2,892 lines
Control - sensitivity: the same scan on the v4.81 slot — 2 tag lines, 1 Release line and
             7 ledger lines. Every arm returns non-zero, so a zero on the v4.82 slot is a
             real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple
             has no near-miss class the probe must reject (the comparator is tuple equality,
             so v4.8.2 and v4.820 are different tuples, not prefixes)
Extraction:  the whole ls-remote output, the whole Release list and the whole ledger
             (932,894 bytes) read from origin/main, never the worktree copy
Result:      0 occupants of the (4,82) slot on every arm
Verdict:     CLEAN — v4.82 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** none. 0 open pull requests and 0 remote `release/*` heads (§ Cross-PR Overlap Audit → In-Flight Release Roster).

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp required-checks-enforce-as-declared`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-11-03`** (Tuesday). The Stage-5 designs record the date-variable trigger as not firing: no identifier this release creates carries a date, and the dates inside the two flip records (2026-09-11, 2026-10-25, 2026-10-27) are past facts, not identifiers. The valve fallback header's `ratified 2026-10-27` is the operator decision's date, not a resolved variable.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited; the Stage-5 conditional resolutions applied at this commit) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria `CIAC-1`..`CIAC-3` | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence (the approved build order, as Stage 5 and the scope-lock resolved it) | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA, which is also the Commit-0 base) | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Issue | Priority | Title | Disposition |
|---|---|---|---|
| #8325 | P2 | Check 74 gate-rollout graduation deadline has no card tracking the warn-to-enforce decision it will force | carried; Stage-5 design on #8615 with its A6.5 review (Minor); scope-lock adjustment items 1 and 2 applied in step 1 |
| #8424 | P2 | Required-context posture: own the two held flips and close the reconciler's blind spots | carried, kept whole with the valve (operator, 2026-10-27); Stage-5 design on #8616 with its A6.5 review (CONDITIONAL, one Major); scope-lock adjustment items 3 and 4 applied in steps 2–6 |

### Exclusions

| Item | Why it is out of scope | Routed to |
|---|---|---|
| The token↔phase residual: nothing compares the sentinel token with `GATE_ROLLOUT_PHASE`, an absent or unrecognised token reads `warn`, and no committed self-test exercises the runner's sentinel branch | Disclosed in the flip record and the sentinel note; the runner agreement assertion offered on #8615 (CD-2) is **not adopted** | enriches #7021 (scope-lock item 5); exact text to the operator before posting |
| The three deferred follow-ons the Stage-5 designs name | outside this release's capability boundary | fold into an existing slice of epic #5867 at Stage 13 (scope-lock item 5) |
| Check 71's retreat wording (`BLOCK-DESTRUCTIVE-022`), the same widening as Check 74's | another constant family; its graduation card is closed | enriches #8549 (scope-lock item 5) |
| The skill-count detector's `++` added-line gap | approved and owned outside the release; named as a residual in the skill-count flip record | #8482 |
| The `RC -eq 0` consumer of the renamed gate step | a dormant sibling's scope; this release changes only the step name, not its body | #7466 (re-baselines on the renamed step) |
| #4714's containment premise ("the sentinel reads `warn`") | reads false after the merge; not this release's file | a note on #4714 at Stage 13 (AI-002) |

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-03)

| Decision | Rendered |
|---|---|
| PA-001 Plan + Release Outcome Statement | **Approved, with an AC7 limb added.** The Outcome's AFTER gains "A malformed `gate-efficacy:` header fails naming the malformed workflow", the BEFORE its contrast, and the `**Limb owners:**` line carries seven limbs (two owned by #8325, five by #8424) |
| PA-002 D-ReleaseClass | **`novel`** (trigger (b)): Stage 9 Deep, Stage 5 for both cards, 30-day outcome window |
| PA-003 D-C branch topology | **SINGLE**: one branch, one PR, the plan file at Engineering Commit 0 |
| PA-004 D-Concurrency posture | **P0, fully serial** |
| PA-005 Valve checkpoint | **Stage 7 entry, Tuesday 2026-11-17 (Check 74 day 80).** If steps 4–5 are not committed and self-verified by then, the valve is invoked: Stage 9 ships the two flips and #8424 items 2 and 3 are recorded documented-deferred (amended by PA-009 for step 3) |
| PA-006 #8325 body refresh | **Skipped.** The 2026-10-27 decision comment on #8325 carries the four shipping files and resolves the open assumption |
| D-Version | **Recorded, not asked:** bump class minor; the number binds at the Stage-12 atomic claim |
| Per-card disposition | #8325 `card-disposition:carried` · #8424 `card-disposition:carried`. AI-002 opened: at Stage 13, a note on #4714 (R14). The milestone description gained a `## Parallelization Map (recorded 2026-11-03)` section (the Phase A0 Tier 1 [ADJUST] finding) |

### Collective Review scope-lock (operator, 2026-11-03)

| Decision | Rendered |
|---|---|
| PA-007 Scope-lock | **Approved with adjustments** (the adjustment set below). Scope is hard-locked through Stage 9; Engineering is authorized |
| PA-008 D-Divergence-Definition | **Shape (a).** *Held* means a `required(warn-mode-initial)` declaration with a HOLD-family row in § Declared-required contexts. A qualified declaration with no such row, absent from the live set, is a fourth divergence class (unrecorded hold). *Held and registered* still keys on the qualifier alone. Stated once in Requirement (b) and computed by the reconciler; it must leave behavioral-regression and link-check `RECONCILED` |
| PA-009 D-HeaderForm and the valve | **Bare `posture=required` on both flipped workflows, with AC7 (step 3) moved into the valve-safe set (steps 1–3).** If step 3 is not committed and self-verified at the Stage 7 entry checkpoint, the two flips ship with `required(enforce; ratified 2026-10-27)` on both headers, and Outcome limb 7 is re-pointed together with limbs 4–6 |
| PA-010 D-AC7-Mechanism | **A closed posture vocabulary.** The `posture` key is mandatory and its value matches `required` or `advisory` with an optional parenthesized qualifier. The attribution repair is added; the embedded-key check stays as a diagnostic that names the collapsed separator. Arms cover a misspelled posture and a missing posture field; the 44 live declarations are the specificity input |
| N-way consistency | 7 conventions; 5 aligned; 2 disagreed (the `:614` lead wording and the retreat-note shape), both resolved by adjustment item 1's single wording, so no override is needed |

**Adjustment set (part of PA-007):**

1. **Step 1 text (#8325):** the 14 standard rows, plus the `:514` lede; one `:614` provenance clause for both cards, covering entries that own a row and entries that name a residual a row carries, with #8424's `### Source(s)` entry led by its handle; `:520` names the registration only as following the flip in Requirement (b)'s order, never as taken; one retreat shape for both cards — un-register first, then revert the flip commit's edits to the token, `GATE_ROLLOUT_PHASE`, the workflow header and the flip record together, and past Check 74's escalation window re-date `GATE_ROLLOUT_ARMED`; Check 74's falsification line names a phase below `enforce`, and the four retreat sites are reconciled.
2. **`deploy.sh`'s dispatcher roster comment** reads Checks 38, 73, 77 and 78 (it omitted 78).
3. **The ruleset reader dispatches by allow-list.** Rule types known to add no merge gate are ignored, `required_status_checks` is read, and every other type, including any type the host adds later, reads `degraded`. The read lives in the workflow, and a verdict needs both live reads to return.
4. **Stage 6 instructions:** promote the README and workflow conditional rows; `${WARN_MODE:-false}` in the skill-count flip commit; P1–P3 `runner-def:` anchors in the sentences that carry their verdicts; the table-reader self-test arms renamed TB1–TB6 and registered in tier 2; this plan names both live inputs wherever a reconciler run is expected to read `RECONCILED`; Stage 7 confirms `rules_status=fetched` on the first PR run after step 4.
5. **Routing, with no new issues** (the exact text goes to the operator before anything is posted): the token↔phase residual enriches #7021; the three deferred follow-ons fold into an existing slice of epic #5867 at Stage 13; Check 71's retreat wording enriches #8549. **Not adopted:** the runner agreement assertion offered on #8615.

---

## Dependency Graph

```
native edges (GraphQL blockedBy / blocking): 0 in and 0 out on both cards
parents: #7932 (#8325, an evergreen flow container) · #5867 (#8424, epic)
logical edges inside the release (A -> B means B consumes A's output):
  #8325 flip (sentinel + GATE_ROLLOUT_PHASE + header)  -> #8424 AC2 read-back ("each flip" includes this one)
  #8325 flip + #8424 item 1 flip                       -> #8424 item 2 (the new divergence rule is validated
                                                          against the post-flip held set: behavioral-regression, link-check)
  #8424 AC7 (the shared header parser in test_gate_efficacy_declarations.py)
                                                       -> #8424 item 2 (the reconciler imports that parser; tier-2 arms)
  #8325 + #8424 item 1 + item 2 + item 3 + AC7 (PR green) -> operator registration -> merge -> live read-back
  #8424 item 3 (register rows)                         -- independent of items 1 and 2 except the shared standard file
cross-milestone (no native edges; Parallelization Map recorded 2026-11-03):
  ms#347 governance-obligations-measured   discharged (merged 2026-10-30)
  ms#443 releases-file-only-the-follow-ups-that-matter   this-blocks-other (stage-07-dev-testing.md; skill-count gate)
  ms#438 guards-judge-every-spelling-alike   this-blocks-other (soft: Check 38 under enforce)
  ms#422 instrument-failure-is-never-a-verdict   this-blocks-other (the renamed gate step)
```

Circular chains: **0** — a DAG over 6 nodes; every edge points toward registration.

---

## Implementation Sequence

Single branch `release/required-checks-enforce-as-declared`, posture **P0 (fully serial)**. Every slice is a separate commit so the flips can be read, falsified and, if the valve fires, shipped on their own. Each slice is pushed on landing (Write-Early).

| Step | Card / item | What lands (as Stage 5 and the scope-lock resolved it) | Ends when |
|---|---|---|---|
| **0** | plan | this file, carrying the Commit-0 Survival Set and the stamp manifest in its Header `**Version**` cell | `claim-version.sh --verify-stamp` exits 0 before the commit |
| **1** | #8325 | **one commit**: the sentinel token `enforce` with its note rewritten (graduation note, the one retreat shape, the absent-token disclosure); `GATE_ROLLOUT_PHASE="enforce"`; `deploy.sh`'s 12 reconciled comment sites (the exit set as the code computes it, Check 74's falsification below `enforce`, the C73 tree-resident posture, Checks 77 / 78 posture blocks, the runner header) plus the dispatcher roster comment; `deploy-check-ci.yml` header bare `posture=required`, its falsification line, its warn-mode paragraph rewritten as a condition statement, and its gate step renamed `Gate decision (exit code -> job conclusion)`; the standard's 14 rows (`:324`–`:327`, `:343`, `:359`, `:360`, the census row `:460` in the same commit as the rename, `:520`, `:534`–`:537`, `:588` as a **REGISTER** flip record), the `:514` lede, the `:614` provenance clause for both cards and this card's `### Source(s)` entry | the subset job on the release PR runs in enforce mode and is green |
| **2** | #8424 item 1 | `WARN_MODE: 'false'` with the `${WARN_MODE:-false}` default; header bare `posture=required`; its posture note and env comment rewritten in the one retreat shape; the standard's skill-count row becomes a **REGISTER** flip record (130-run sample, the empty-firing-population disclosure, #8482 named as a residual); its `### Source(s)` entries, the #8424 entry led by its handle | the skill-count job on the release PR runs in enforce mode and is green |
| — | Stage 7 G-PR4 (can start here) | falsification run per flipped context in PR context, then revert (§ Verification Plan) | both runs recorded with their check-run links |
| **3** | #8424 AC7 (valve-safe) | the closed posture vocabulary (PA-010) in `test_gate_efficacy_declarations.py`: mandatory `posture` key, value `required` or `advisory` with an optional parenthesized qualifier; the malformed-header attribution repair; the embedded-key diagnostic naming the collapsed separator; arms for a misspelled posture, a missing posture field and the four single-edit variants; the 44 live declarations as the specificity input | the ratchet and `reconcile-gate-posture.py --self-test --require-parser` both pass |
| **4** | #8424 item 2 | divergence shape (a) stated once in Requirement (b); the reconciler's unrecorded-hold class and its disposition-table reader (self-test arms TB1–TB6, registered in tier 2); the ruleset read of the rules that apply to `main`, dispatched by allow-list (no-merge-gate types ignored, `required_status_checks` read, every other type `degraded`), living in `gate-posture-reconciliation.yml`, with a verdict only when both live reads return; register row `:372`'s stated limit; the tools README row | reconciler self-test green with the new arms; a run against both live inputs — the branch-protection object and `rules/branches/main` — reads `RECONCILED` with 2 held |
| **5** | #8424 item 3 | three register rows for P1, P2, P3 (runner, or NAMED GAP with its observable), each with a `**Population:**` declaration; `runner-def:` anchors in `stage-07-dev-testing.md`, in the sentences that carry their verdicts | Check 62 resolves every new pointer |
| **6** | release | the standard's Version History row (both cards' clauses merged by the step-6 author); DTA-7 cascade sweeps for every renamed identifier, with pre and post counts | sweeps read post 0 |
| **7** | operator, Stage 12 | with the PR open and green: register `Pre-merge load-bearing check subset` and `Skill-count / IMP-XXX delta`, re-run both checks on the PR, merge, read back `main`'s live required contexts | 24 live contexts including both; reconciliation on the merge push, with both live inputs returned (the branch-protection object and `rules/branches/main`), reads `RECONCILED`, held = 2 |

**Valve (PA-005 as amended by PA-009).** At the Stage 7 entry checkpoint, Tuesday 2026-11-17: if steps 4–5 are not committed and self-verified, Stage 9 ships the two flips, #8424 items 2 and 3 are recorded documented-deferred, and Outcome limbs 4–6 are re-pointed, in the same edit, to an open owner outside the release (an existing epic-#5867 slice, not a new issue). If step 3 is not committed and self-verified, both flipped headers ship as `required(enforce; ratified 2026-10-27)` instead of the bare form, and Outcome limb 7 is re-pointed together with limbs 4–6.

### #8325 — change specification (step 1; Stage-5 design on #8615, scope-lock items 1 and 2 applied)

**Files:** `.github/deploy-check-ci.enforce`, `core/deploy/deploy.sh`, `.github/workflows/deploy-check-ci.yml`, `core/standards/gate-efficacy-standard.md`. All four land in **one commit**: the ratchet keys the census on `(workflow, step, var)`, so the renamed step and its census row must land together, and the token and the phase must move together because nothing compares them.

**Design decisions applied.** D-HeaderForm (a) bare `posture=required` (PA-009). D-StepName (a) `Gate decision (exit code -> job conclusion)` — a mode-independent name for a mode-independent step, so a later retreat does not rename it; the job `name:`, which is the registered context, does not change. D-DeployShScope — the semantic-touch criterion: reconcile every line that states the subset's pre-merge posture, the sentinel's current value or Check 74's exit set, and leave lines that describe the mechanism conditionally and lines about the deploy-time lifecycle surface, which this change does not touch. D-FlipRecordForm **REGISTER** — the section's closed three-disposition vocabulary. D-ProvenanceLead — one `:614` clause for both cards.

**The scope-lock's item-1 amendments, as this card applies them.**
- **The standard's edit set** is the 14 rows plus the `:514` lede (A6.5 PR-2): the flip-decision table now records a flipped limb, so its lede reads "deferred, declined or flipped".
- **`:520`** records the token flip on the operator's graduation decision and states that the context's registration follows it in Requirement (b)'s order; it never records the registration as taken (A6.5 FM-3).
- **One retreat shape**, written into the sentinel note and the `:588` flip record: un-register the context first, then revert the flip commit's edits to the token, `GATE_ROLLOUT_PHASE`, the workflow header and the flip record together, and past Check 74's escalation window re-date `GATE_ROLLOUT_ARMED` (A6.5 FM-2).
- **Check 74's exits** are stated as the code computes them — advance the phase to `enforce`, or re-date the arming constant; a retreat alone discharges nothing — at the four sites (`deploy.sh` constants comment, Check 74's header, its remediation log line, the standard's `:520`), and its falsification line names a phase below `enforce`, because at `enforce` the deadline arm is short-circuited.
- **`:614`** gains one clause that covers both kinds of later entry: work items that own a row, and residuals a row carries.

**Not adopted from the A6.5 review:** relabelling the "GRADUATED." notes as history (FM-1 mitigation 2) and the runner agreement assertion (CD-2); the residual they address routes to #7021.

**Census and cascade.** DTA-7 over the pair this release renames: the old step name on `deploy-check-ci.yml` and its census row, **pre 2 / post 0**; tree-wide the old name reads 7 before and 5 after (four other workflows and the `version-freeness.yml` census row keep it, as different census members). The step's `run:` body is unchanged; #7466 owns that consumer.

**Version History clause** (handed to the step-6 author, who merges it with #8424's): "**The pre-merge load-bearing subset graduates to enforce.** The sentinel token and the rollout phase move together, the workflow header declares `required`, and § Declared-required contexts records the flip as REGISTER with its specificity reading and owner; every register, census and flip-decision row that stated the subset's warn-mode posture is reconciled, and Check 74's exits are stated as the code computes them — advance to enforce, or re-date; a retreat alone discharges nothing."

### #8424 — change specification (steps 2–6)

Carried by its own Stage-5 design (#8616, comment on that sub-task), its A6.5 review and scope-lock items 3 and 4, and recorded in this file by its own Stage-6 spoke (#8618) as each slice lands. The File Change Matrix below already carries every path its design and the scope-lock name.

### Back-schedule against the date

[RECOMMENDED — derived backwards from the merge-by date, not an effort estimate.]

| Stage | Latest-safe finish | Check 74 day |
|---|---|---|
| 4 plan gate | Tuesday 2026-11-03 to Wednesday 2026-11-04 | 66–67 |
| 5 Solutioning (D-class rendered at Collective Review) | Monday 2026-11-09 | 72 |
| 6 steps 0–2 (both flips pushed) | Tuesday 2026-11-10 | 73 |
| 6 steps 3–6 | Monday 2026-11-16 | 79 |
| **Valve checkpoint** — Stage 7 entry | **Tuesday 2026-11-17** | 80 |
| 7 Dev Testing | Wednesday 2026-11-18 | 81 |
| 8 QA | Friday 2026-11-20 | 83 |
| 9 Plan Review GO | Monday 2026-11-23 | 86 |
| 12 registration + merge | Tuesday 2026-11-24 (target), Wednesday 2026-11-25 (latest) | 87–88 |

Stages 4 and 5 both finished on Tuesday 2026-11-03 (day 66), ahead of their latest-safe dates. Check 74 counts days on the UTC date, so day 90 begins at 00:00 UTC on Friday 2026-11-27 — the evening of Thursday 2026-11-26 (a US holiday) on any clock west of UTC. The merge-by date is unaffected; a slipped merge meets the hard date about half a day earlier than it reads.

---

## Stage Applicability Matrix

| Card | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|---|
| #8325 | APPLY (ran) | APPLY | APPLY (G-PR4 run 1; Check 74 strict run) | APPLY | APPLY (Deep) | COMPRESS (git-native) | COMPRESS (git-native) | APPLY (registration, merge, read-back) | APPLY |
| #8424 | APPLY (ran) | APPLY | APPLY (G-PR4 run 2; reconciler run) | APPLY | APPLY (Deep) | COMPRESS | COMPRESS | APPLY | APPLY |

Skips: none at 5–9 — both cards change merge-blocking behaviour, so neither is trivial and neither is free of functional impact.

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. A shared path is listed once, under the first card that edits it; the cards that edit it are named after the verb.

```
# ── Engineering Commit 0 ──
release/releases/plans/required-checks-enforce-as-declared_RELEASE_PLAN.md  ADD
# ── #8325 (step 1) ──
.github/deploy-check-ci.enforce  EDIT
core/deploy/deploy.sh  EDIT
.github/workflows/deploy-check-ci.yml  EDIT
core/standards/gate-efficacy-standard.md  EDIT  8325 step 1 · 8424 steps 2, 4, 5, 6
# ── #8424 (steps 2–5) ──
.github/workflows/skill-count-imp-check.yml  EDIT
core/deploy/tests/test_gate_efficacy_declarations.py  EDIT
core/deploy/tools/reconcile-gate-posture.py  EDIT
.github/workflows/gate-posture-reconciliation.yml  EDIT
core/deploy/tools/README.md  EDIT
release/references/pipeline/stage-07-dev-testing.md  EDIT
```

#### Read-only inputs

```
core/deploy/tools/check-skill-count-imp.py  READ
release/tools/check-dark-branch.py  READ
.github/workflows/install-tests.yml  READ
core/schemas/gate-criteria-spec.md  READ
release/references/specs/release-outcome-statement-template.md  READ
core/deploy/tools/build-hook-registry.py  READ
```

#### Release-wide explicit non-scope

```
core/ADRs/ADR-166-split-predicate-gate-graduation.md  NOT EDITED
release/releases/RELEASE_LOG.md  NOT TOUCHED
release/releases/notes/  NOT TOUCHED
core/rules/  NOT TOUCHED
```

The repository-root `CHANGELOG.md` is also not touched (the Stage-13 chore PR writes it). It is named here rather than as a fenced row because the matrix reader recognises no repository-root path that carries no directory segment, so a fenced row would read as uninterpreted rather than excluded.

**The Stage-4 conditional rows are resolved at this commit.** `STAGE5-RULESET-READ-IN-WORKFLOW` fired — the ruleset read lives in the workflow (scope-lock item 3) — so `.github/workflows/gate-posture-reconciliation.yml` and `core/deploy/tools/README.md` are promoted into the unconditional set. `STAGE5-P1P3-RUNNER-ANCHORS` fired — the P1–P3 `runner-def:` anchors go in the sentences of `stage-07-dev-testing.md` that carry their verdicts (scope-lock item 4) — so that file is promoted too. No CONDITIONAL row remains.

**Non-scope reasons.** ADR-166 is an Accepted record; its "sentinel still reads warn" line is history-anchored. The release log, notes and changelog are written by the Stage-12 and Stage-13 chore PRs. `core/rules/`: no mirror-pair member changes, so no rules-mirror deploy is owed; the Stage-7 G-PR4 run 1 falsification commit edits one `core/rules/bypass-mode-readiness/` source and its revert restores it, so the net diff on `core/rules/` across the release is zero.

**Zero `ADD` rows for executables** → the new-executable companion obligation (an allowlist row and CI wiring) does not fire. **No path is renamed, moved or deleted** → the mover set is empty. **One `pipeline/stage-*.md` file** is edited (stage-07), below the cross-cutting threshold, and none of the six rule-defining surfaces, so the class stays `novel`. Branch protection is the operator's out-of-tree step 7; no file carries it.

### Agent-Editability Read

Transcribed from the Stage-4 derivation, controls read at `f8d88626`, and re-applied to the promoted rows. The Tier-0 floor's surviving union is the basenames `CLAUDE.md`, `OPERATIONS.md` and `RELEASE_PROTOCOL.md` at any depth; no matrix path carries one. The sanctioned-session gate's first conjunct needs a `*/skills/<name>/` segment; no matrix path carries one, so conjunct 3 (its exemption list, recorded `undetermined` at Stage 4 under a control firing) decides no row.

| Card | Write-set paths | Tier-0 ∩ | Skill-gate ∩ | Card class | Execution path |
|---|---|---|---|---|---|
| plan | this file | ∅ | ∅ — conjunct 1 false | — | first Engineering spoke (Commit 0) |
| #8325 | the sentinel · `deploy.sh` · `deploy-check-ci.yml` · gate-efficacy standard | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #8424 | `skill-count-imp-check.yml` · gate-efficacy standard · the conformance suite · the reconciler · `gate-posture-reconciliation.yml` · tools README · stage-07 | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |

Every card is `unconstrained`. That says no control refuses the writes; it does not make them ungoverned — the branch-protection registration is still an irreducible operator act.

---

## Contention Map

**Within release (serial P0 order resolves every row):**

| File | Cards | Regions | Resolution |
|---|---|---|---|
| `core/standards/gate-efficacy-standard.md` | #8325, #8424 | #8325: `:324`–`:327`, `:343`, `:359`, `:360`, `:460`, `:514`, `:520`, `:534`–`:537`, `:588`, `:614`; #8424: Requirement (b)'s divergence paragraph, `:372`, `:574`, new P1–P3 rows, `:590`; both: `### Source(s)` (append) and Version History (step 6) | sequence 1 → 2 → 4 → 5 → 6; adjacent rows `:588` and `:590` are written in steps 1 and 2, never in parallel |
| `core/deploy/tests/test_gate_efficacy_declarations.py` ↔ `core/deploy/tools/reconcile-gate-posture.py` | #8424 AC7, #8424 item 2 | the reconciler imports the parser | AC7 first (step 3), then item 2 (step 4) |

**Cross-release** (baseline-pinned at `f8d88626`; Stage 9 A6.5 re-measures):

| File / surface | This release | Sibling or dormant item | Disposition |
|---|---|---|---|
| `release/references/pipeline/stage-07-dev-testing.md` | P1–P3 `runner-def:` anchors | ms#443's card edits its *Routing on Defer* rows | different section; this release merges first and ms#443 rebases |
| `.github/workflows/deploy-check-ci.yml` | header, falsification, warn-mode paragraph, step name | #7466 (dormant) converts the step's `RC -eq 0` consumer | this release lands first; #7466 re-baselines on the renamed step |
| `.github/workflows/skill-count-imp-check.yml` | header, env, default | #8482 (approved, unbundled) edits the awk guard | distinct line ranges: informational |
| `core/standards/gate-efficacy-standard.md` | many rows | 17 milestone-assigned issues cite it | `append-pattern`, structurally high and operationally low; none is in the decided order |
| `core/deploy/deploy.sh` | constants comment, Checks 73 / 74 / 77 / 78 comments, the runner header, the dispatcher comment | 52 milestone-assigned issues cite it; 0 in ms#443 or ms#438 | single-PR in the decided order |
| **Gate behaviour, not a file** | enforces Checks 38 / 73 / 77 / 78 and the skill-count delta on every PR from the merge | ms#443's added `.md` lines meet the skill-count gate; ms#438's hook-source edits need the regenerated index | behavioural coupling, recorded in the Risk Register (R9); no serialization edge |

## Cross-PR Overlap Audit

### Baseline SHA

`f8d8862668aa373a37f36f309c54eb364fae2d9b` — the Stage-4 Phase A0 pin, re-read unchanged by both Stage-5 designs and both adversarial reviews, and the Commit-0 base: this file is written on exactly this commit.

**Pre-change reconciler measurement (Stage 4, the tool before step 4 adds its rules read):** against the branch-protection object alone, `RECONCILED`; 26 declared-required contexts, 22 live, 4 held (the two flipped here plus behavioral-regression and link-check). This is a baseline observation, not an expectation; every `RECONCILED` this plan expects after step 4 rests on both live inputs.

### In-Flight Release Roster

**Measured at:** `f8d88626` · `2026-11-03T22:38Z` (Engineering Commit 0) · **Population:** n=0 sibling(s)

**None in flight at `f8d88626` / Engineering Commit 0.** Probe: open pull requests, limit 200 → 0 (control: the same reader on merged pull requests, limit 3 → 3); remote heads → 1, `main` only, so 0 remote `release/*` heads (control: the `main` head itself is returned). This is a pinned measurement with no verdict; Stage 9 Phase A6.6 re-measures it. ms#443 and ms#438 are planned siblings with no branch yet.

### Structural sub-audit

No file is renamed, moved or deleted, so the mover set is empty. `SURFACE(R)` is the version-slot token `Δversion/minor@v4.81` only.

---

## Risk Register

| # | Risk | Owner | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|
| R1 | **Deadline.** A merge after Friday 2026-11-27 turns every strict `deploy.sh --check` red on Check 74 — every operator run and every release's Stage 12 / 13 deploy check — until the phase reads `enforce` or the arming date moves | hub, at each stage gate | Back-schedule above; flips first (steps 1–2 by 2026-11-10); valve checkpoint 2026-11-17; last resort, an operator re-date of `GATE_ROLLOUT_ARMED` with its reason (a retreat alone does not discharge Check 74) | MODERATE / HIGH |
| R2 | **Items 2 and 3, or AC7, overrun.** The reconciler work or the posture vocabulary slips | operator (valve) | At the 2026-11-17 checkpoint: steps 4–5 not committed and self-verified → Stage 9 ships the flips, #8424 items 2 and 3 are recorded documented-deferred, Outcome limbs 4–6 re-pointed in the same edit to an existing epic-#5867 slice; step 3 not committed and self-verified → both flipped headers ship as `required(enforce; ratified 2026-10-27)` and limb 7 is re-pointed with limbs 4–6 | CHEAP / MEDIUM |
| R3 | **Bare issue numbers in the standard.** Naming a card's number in a disposition row reddens `Durable-corpus fragile-reference delta`, a registered required check | Stage 6 | Name the owner in prose in the row; carry the number in `### Source(s)` with an inline summary; 0 of the standard's table rows carry a bare number at the pin | CHEAP / HIGH |
| R4 | **Rename cascade.** Renaming the `deploy-check-ci.yml` gate step leaves the census row naming a step that no longer exists; the census is graded as a set by the conformance suite | Stage 6 | The step and its census row land in one commit; DTA-7 over the pair, pre 2 / post 0. The other 4 workflows using the old step name keep it | CHEAP / HIGH |
| R5 | **The release PR meets its own gate.** After step 2, the skill-count detector scans this PR's added `.md` lines in enforce mode, including this file and the standard's new text | Stage 6 | No totalizing skill-roster phrase in added text; run `check-skill-count-imp.py` over the added lines before each push | CHEAP / HIGH |
| R6 | **Registration window.** Between registration and merge, `main`'s reconciler reads DIVERGED (held and registered); any PR open then shows that red. From step 1 until registration, the release PR's own `Gate posture reconciliation (declared vs live)` check reads DIVERGED (unregistered), which is that check's declared falsification | operator | Expected and advisory; Stages 7, 8 and 9 record it as expected, not as a regression; Stage 12 re-runs it after registration and merges only once it reads RECONCILED | CHEAP / HIGH |
| R7 | **Empty firing population.** The skill-count specificity reading has 0 firings in 130 sampled runs; specificity rests on the detector's constructed self-test | operator (accepted at Stage 9) | Disclosed in the flip record; G-PR4 run 2 gives one real firing in PR context | CHEAP / MEDIUM |
| R8 | **Known sensitivity gap.** #8482: an added line whose content starts with `++` is dropped by the detector's added-line mapper | #8482 (approved, outside the release) | Named as a residual in the flip record; a missed line is a false negative and cannot block a merge wrongly | CHEAP / HIGH |
| R9 | **Sibling PRs meet enforcing gates.** ms#443 and ms#438 open their PRs after this merge; ms#438's hook-source edits need the regenerated index (Check 38), ms#443's `.md` additions meet the skill-count gate | sibling hubs | A cross-milestone notice at merge; sibling Stage 6 runs `deploy.sh --check-required-subset` and the detector before pushing | CHEAP / HIGH |
| R10 | **macOS required job.** The subset job runs on `macos-latest`; a runner outage leaves a required context pending on every PR | operator | Temporary un-registration is the settings-side escape; the job's cost was accepted when its filter was removed | MODERATE / MEDIUM |
| R11 | **New verdict input for the reconciler.** Reading the disposition table makes the standard's table format a verdict input; a format drift must fail the instrument (exit 2), never read as a clean set | Stage 6 (#8424) | The read fails closed, with self-test arms TB1–TB6 on malformed tables, registered in tier 2 | CHEAP / MEDIUM |
| R12 | **Ruleset read permission.** The `rules/branches/main` read with the workflow token may refuse or fail | Stage 6 (#8424) | A refused or failed read is `NOT-EVALUATED`, never `RECONCILED`; scoped to rules on `main` (0 today), not the repository's ruleset list (1, `tag`); unknown rule types read `degraded`; Stage 7 confirms `rules_status=fetched` on the first PR run after step 4 | CHEAP / MEDIUM |
| R13 | **Falsification commits.** The G-PR4 commits could trip unrelated required gates or the commit-message gates | Stage 7 | Use the two variants in § Verification Plan; commit messages carry no close-family verb or identity string; revert by a new commit (no force-push) | CHEAP / HIGH |
| R14 | **Stale downstream premises.** #4714 (dormant) states its blast is bounded because the subset sentinel reads `warn`; that sentence reads false after the merge | hub | AI-002: a note on #4714 at Stage 13; not in scope here | CHEAP / MEDIUM |
| R15 | **The disarm-by-edit residual.** After the flip, an absent sentinel file or a first token other than `enforce` reads as `warn`, so removing or blanking the token disarms a registered gate while it reads green; nothing compares the token with `GATE_ROLLOUT_PHASE` | operator | Disclosed in the flip record and the sentinel note; routed to #7021 (scope-lock item 5); a disarming edit is a visible one-file diff in review | CHEAP / MEDIUM |

Rollback complexity is MODERATE for the whole release (the settings-then-revert order plus the re-date) and CHEAP per context or item (§ Rollback Strategy).

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8325 × #8424 on `core/standards/gate-efficacy-standard.md` § Declared-required contexts):** neither flipped context's disposition row still carries a hold disposition after the release. *Method:* `grep -c -E "^[|] .(Pre-merge load-bearing check subset|Skill-count / IMP-XXX delta). [|].*\*\*(HOLD|CORRECT-THEN-HOLD)\*\*" core/standards/gate-efficacy-standard.md` expect 0. *Graded at Stage 9 QC3.5 on the merged PR.* Control on the same instrument and file: `grep -c -E "^[|] .(Behavioral-regression pass-rate gate|Cross-reference integrity [(]governance [+] reference [+] rules [+] skills[)]). [|].*\*\*(HOLD|CORRECT-THEN-HOLD)\*\*" core/standards/gate-efficacy-standard.md` → 2 (at the pin the subject arm reads 2 and the control 2).
- [ ] **CIAC-2 (#8325 × #8424 on `core/standards/gate-efficacy-standard.md` § Declared-required contexts):** both flip records carry a specificity reading, so the two flips are recorded in one shape. *Method:* `grep -c -E "^[|] .(Pre-merge load-bearing check subset|Skill-count / IMP-XXX delta). [|].*[Ss]pecificity reading" core/standards/gate-efficacy-standard.md` at least 2. *Graded at Stage 9 QC3.5 on the merged PR.* (0 at the pin; the same pattern on any row reads 8.)
- [ ] **CIAC-3 (#8325 × #8424 on `main`'s live required contexts and the posture reconciler):** after the merge both flipped contexts are live, and the reconciler on the merge push — with both live inputs returned, the branch-protection object and `rules/branches/main` — reads `RECONCILED` with exactly the two unflipped held contexts. *Method:* declared, verification deferred to `core/deploy/tools/reconcile-gate-posture.py` as run by the measurement job of `gate-posture-reconciliation.yml` on the merge-commit push, beside the Stage 12 live required-context read-back. *Graded at Stage 9 QC3.5 on the merged PR.*

The CIAC lint on the Stage-4 body read `declared=3 parsed=3 clean=2 declared-deferral=1 flagged=0`; it is re-read on this committed file at Stage 6 A1 (§ Verification Evidence) and at Stage 9 A3.6.

---

## Verification Plan

**AC baseline:** #8325 = **2** criteria, #8424 = **7** criteria, read at `f8d88626` (bodies at `2026-11-03T19:48:29Z` and `2026-10-27T21:20:50Z`).

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8325 | AC-1 | `grep -c -F 'readonly GATE_ROLLOUT_PHASE="enforce"' core/deploy/deploy.sh` expect 1 | 1 — the phase reads `enforce`; the decision and its owner are on record in the card's 2026-10-27 operator comment |
| #8325 | AC-2 | [DEFERRED — Stage 7 runs a strict deploy-check on the release head and records Check 74's own line reading OK for the GRADUATED reason; the deploy check's exit status covers the whole run, so it cannot carry one Check's verdict] | Check 74 OK because the phase is enforce, not because of the date |
| #8424 | AC-1 | `grep -c -E "^- #8[34]2[45] — " core/standards/gate-efficacy-standard.md` at least 2 [READER-GRADED — each of the two disposition rows names its owning card in prose and points at that Source(s) entry] | at least 2 Source(s) entries (0 at the pin; control: 3 existing entries on the same pattern shape) |
| #8424 | AC-2 | `grep -c -x -F "enforce" .github/deploy-check-ci.enforce` expect 1 [READER-GRADED — skill-count-imp-check.yml sets WARN_MODE to 'false', and the Stage 12 live read-back lists both contexts] | 1 (0 at the pin; control token `warn` reads 1 at the pin) |
| #8424 | AC-3 | [DEFERRED — answered on the record by the operator's 2026-10-27 decision comments on both cards, before the 2026-10-28 review; no file in this release carries it] | both decision comments present |
| #8424 | AC-4 | [DEFERRED — the reconciler self-test arm for a seeded held declaration with no disposition row, named at Stage 5 and run by the measurement job of gate-posture-reconciliation.yml] | DIVERGED, naming the context |
| #8424 | AC-5 | [DEFERRED — the reconciler self-test arm for a ruleset-delivered required context, named at Stage 5 and run by the same measurement job] | reconciled, or NOT-EVALUATED; never a clean verdict over an unread ruleset |
| #8424 | AC-6 | `grep -c -F "stage-07-dev-testing.md" core/standards/gate-efficacy-standard.md` at least 4 [READER-GRADED — P1, P2 and P3 each have their own row with a runner or a NAMED GAP and its observable, each row declares a Population, and Check 62 resolves every new pointer] | at least 4 (1 at the pin) |
| #8424 | AC-7 | [DEFERRED — the four single-edit malformed-header variants and the PA-010 closed-vocabulary arms in core/deploy/tests/test_gate_efficacy_declarations.py, run by install-tests.yml; arm labels named at Stage 5] | each variant fails naming its own workflow; the specificity arm reports an unattributable over-match as its own instrument failure |

`ac_baseline: { #8325: 2, #8424: 7, read_at: f8d88626 }`

**Null and threshold rows carry a same-target control** (AC-Binding Limb 2): every count row names a control read with the same instrument on the same file, and that control returns non-zero at the baseline.

### G-PR4 observed-acting runs (Stage 7, one per flipped context, in pull-request context)

1. **`Pre-merge load-bearing check subset`** (after step 1 is pushed, with the release PR open as a draft). Record the subset job green on that head (`all 4 load-bearing check(s) passed`). **F:** in `core/rules/bypass-mode-readiness/block-mcp-writes.md`, change its `Scope` row's text without running `build-hook-registry.py`; the commit message carries no issue reference. **Expected:** the job is red, and its step output carries both `required-subset: hook-registry-index-freshness — FAIL (STALE)` and `load-bearing check(s) FAILed (sentinel enforce) — blocking exit 1`. A red job without the second string is an ERROR or fail-closed red, which is **not** evidence of the flip: record it NOT-EVALUATED and repair the input. **R:** revert by a new commit and confirm byte-exactness (`git diff <F>^ HEAD -- <the source>` empty); expect green. Cite the warn-side arm: the 2026-09-19 STALE episode in the 985-run reading, same job and input class, which read STALE and passed.
2. **`Skill-count / IMP-XXX delta`** (after step 2 is pushed): push a commit that adds a stale literal skill-roster total to a changed `.md` line → the job exits 1 (red); push the revert → green. Prefer this variant to a deprecated IMP-series reference: that variant also reddens the required `Issue-reference validity gate`, which muddies the reading.
3. Both contexts are still unregistered at Stage 7, so the observation is "the job turns red in PR context". That a registered red context blocks the merge is host behaviour, observed at Stage 12 only as the read-back; state it as the residual.

**Also at Stage 7:** a strict `deploy.sh --check` on the release head, reading Check 74's own block (#8325 AC-2): subject `ok=1 denom_enforce=1 fail_or_warn=0` (the `OK: … GRADUATED to enforce` line and a `DENOM` line carrying `phase=enforce`); sensitivity arm the same read at Commit 0, where the phase is `warn` and the day count is past the review threshold → `WARN: … GRADUATION-DUE`; a block of 0 lines means Check 74 did not run (NOT-EVALUATED, never a pass). And the reconciler against both live inputs — the branch-protection object and `rules/branches/main` — reading `RECONCILED`, held = behavioral-regression and link-check, once the flips are in the PR tree and step 4 has landed; Stage 7 confirms `rules_status=fetched` on the first PR run after step 4.

### G-CL10 arm (i) — prose rows this release adds

The three P1–P3 rows lead their Surface cell with `prose`, so each carries `**Population:** <name> — population: …; probe: …; threshold: …%`, and this file's § Verification Evidence carries each population's record at close.

### Release-Level Verification

These checks use tools or shapes outside the plan verifier's runnable set, so each is declared deferred to the Stage-6 C4 run that executes it; the commands and observed results land in § Verification Evidence as each slice lands.

| Check | Verification Method | Expected |
|---|---|---|
| Required subset under enforce | [DEFERRED — deploy.sh --check-required-subset at Stage 6 C4 after step 1; result in § Verification Evidence] | all 4 load-bearing checks pass, and the runner reads `enforce` |
| Conformance ratchet | [DEFERRED — core/deploy/tests/test_gate_efficacy_declarations.py at Stage 6 C4 per slice] | exit 0, no unrecorded or stale census member |
| Reconciler self-test | [DEFERRED — reconcile-gate-posture.py --self-test at Stage 6 C4 per slice] | pass |
| Doc-link integrity | [DEFERRED — the doc-link checker over each slice's edited docs, with the plan-depth lint on this plan, at Stage 6 C4] | no new broken link |
| Skill-roster totals on added lines (R5) | [DEFERRED — check-skill-count-imp.py over each slice's added lines, at Stage 6 C4] | clean |
| Fragile references in the standard (R3) | [DEFERRED — a scan of the standard's table rows for a bare issue number, at Stage 6 C4 per slice] | 0 in table rows; the numbers sit in Source(s) |
| Cascade sweeps (DTA-7) | [DEFERRED — the Stage-5 sweeps S-a to S-h plus S-i over the four step-1 files, pre and post, at Stage 6 C4] | every surviving hit is a PRESERVE or N/A row |
| CIAC authoring lint | [DEFERRED — the plan verifier's CIAC lint over this file, at Stage 6 A1 and Stage 9 A3.6] | declared=3 parsed=3 flagged=0 |
| Package consequence | [DEFERRED — the package resolver reading each changed path on STDIN, at Stage 6 C4 per slice] | empty — no rostered skill's package is staled |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential (P0 serial; contention-driven) |
| Commit strategy | Commit 0 (this plan), then one commit per plan step, each pushed on landing (Write-Early); messages carry the `required-checks-enforce-as-declared:` prefix and a reference-only `(#N)` |
| Review approach | Single release PR, draft until Stage 9 Phase A8 |
| Registration | Operator, Stage 12: both contexts registered with the PR open and green, immediately before the merge; both checks re-run; live required contexts read back after the merge |
| Deployment mechanism | Git merge. No skill package and no rules-mirror member changes |
| Stacked-base cleanup | N/A (single branch) |

The PR body is parser-clean: each card is named in the dedicated Issue References block; no close-family verb precedes an issue number anywhere else.

---

## Rollback Strategy

| Scope | Method | Complexity |
|---|---|---|
| Whole release | The operator un-registers both contexts first, then the merge is reverted (`git revert -m 1 <merge>`). The order matters: reverting first leaves two registered contexts whose jobs swallow findings. The revert puts `GATE_ROLLOUT_PHASE` back to `warn` past day 90, so Check 74 reads GRADUATION-OVERDUE; the rollback therefore carries a re-date of `GATE_ROLLOUT_ARMED` with its reason | MODERATE / HIGH |
| One context (the retreat shape, both cards alike) | Un-register the context first, then revert the flip commit's edits together — for the subset: the sentinel token, `GATE_ROLLOUT_PHASE`, the workflow header and the flip record; for the skill-count delta: `WARN_MODE`, the header qualifier and the flip record — and, for the subset past Check 74's escalation window, re-date `GATE_ROLLOUT_ARMED`, because below `enforce` that deadline re-arms. The skill-count flip reverts without touching Check 74 | CHEAP / HIGH |
| Items 2 and 3, AC7 | Tool, test and standard edits revert by commit; nothing outside the tree changes | CHEAP / HIGH |
| Version tag | Retained and recorded per Tag Retention; never deleted | — |

Rollback infeasibility: none; every step is a commit or a settings change.

---

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A), transcribed from Stage 4.
**Parallel-eligible spokes per parallel stage:** Stage 5: 2 · Stage 7: 2 · Stage 8: 2 (Stage 6 is serial).
**Per-spoke cost estimate:** ordinal band — `size:L` moderate–high, `size:XS` below the lowest named bucket (heuristic).
**Assumed remaining usage-window envelope:** unstated at hub start; conservative default 50% of a window [ASSUMPTION – CONFIRM].
**Estimated cumulative draw (worst parallel batch):** about 15% of a window, about 30% of the assumed envelope.
**Routing:** PASS → proceed; Checkpoint B re-validates at every launch.

---

## Release Class declaration

**`novel`** — trigger (b) fires: #8424 item 2 needed a D-class decision on the divergence definition, rendered at the Collective Review as shape (a) (PA-008). `cross-cutting` does not fire: 1 `pipeline/stage-*.md` file (stage-07), 0 of the six rule-defining surfaces, and 1 cross-issue compositional edge (#8325 → #8424). `hotfix` does not fire: no deployed-release defect. `effective_pts: 9 × 1.15 = 10.35`, in the acceptable band (10–15), under the 15–25 target; the deadline argues against adding scope. Differentiation posture: engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.

---

## Release Outcome Statement

Transcribed from the milestone description at Engineering Commit 0.

**AFTER** — The two required checks held in warn mode block a merge: the pre-merge load-bearing subset (Checks 38, 73, 77 and 78) and the skill-count delta. Each context is registered in branch protection and read back, each workflow header declares `posture=required` with no hold qualifier, and the gate-efficacy standard records each flip with its specificity reading and its owner. Check 74 reads green because the phase is `enforce`, not because of the date. The posture reconciler reports a held declaration with no disposition row as diverged, and a ruleset-delivered required check as not evaluated; Stage 7's roster predicates P1 to P3 each have a register row or a named-gap disposition. A malformed `gate-efficacy:` header fails naming the malformed workflow.

**BEFORE** — Both contexts run in warn mode: `.github/deploy-check-ci.enforce` and `GATE_ROLLOUT_PHASE` read `warn`, and the skill-count workflow sets `WARN_MODE: 'true'`, so neither blocks a merge. Check 74's deadline, armed 2026-08-29 (Saturday), turns a strict `deploy.sh --check` red on Friday 2026-11-27 unless the phase reads `enforce`. The reconciler treats a `(warn-mode-initial)` qualifier as an exemption and reads only classic branch protection, and Stage 7's P1 to P3 have no register row. A malformed header can be reported against the wrong workflow.

**Actor(s):** every pull request against `main`; the operator, who registers both contexts.

**Success Indicator:** both contexts appear in the live required contexts read after the merge; a strict `deploy.sh --check` on the merge commit reads Check 74 green; the reconciler's new fixtures read `DIVERGED` and `NOT-EVALUATED`; one PR for the milestone.

**Limb owners:** pre-merge load-bearing subset blocks a merge (flip committed, context registered and read back, header `required`, flip record with its reading and owner) → #8325 · skill-count delta blocks a merge (the same four parts) → #8424 · Check 74 reads green because the phase is `enforce` → #8325 · a held declaration with no disposition row reads diverged → #8424 · a ruleset-delivered required check reads not evaluated → #8424 · Stage 7's P1–P3 each have a register row or a named-gap disposition → #8424 · a malformed `gate-efficacy:` header fails naming its own workflow → #8424

If the valve fires, limbs 4–6 (and limb 7, when step 3 is not committed and self-verified) are re-pointed in the same edit to an open owner outside the release (R2).

---

## Operational Deployment Manifest

| Surface | Propagation | Mechanism |
|---|---|---|
| Every matrix path | **Repository-only** — none is under a skills tree or in the rules mirror set, so no installed copy exists | none required |
| `core/deploy/deploy.sh`, the reconciler and the conformance suite | Run from the repository at check time and in CI; nothing is copied | none required |
| Branch protection (`main`'s required contexts) | Out-of-tree repository settings, operator-side at Stage 12 | the registration, then the live read-back |

**`deliverable_state: deployed-copy-synced`** — the release declares no Layer-2 propagation target, which this state admits ("or the release declares no propagation target").

### Schema Migrations

N/A — enumerated over data-file formats, register and ledger schemas, the pipeline-event-log schema, the deploy-check warn-log row shape and the gate-criteria schema columns; none migrates. The `gate-efficacy:` header grammar is narrowed to a closed posture vocabulary (PA-010) that every one of the 44 live declarations already satisfies.

### Memory Evictions

N/A — enumerated over memory eviction, memory re-point and archive disposition; no codification card in this release is tied to an auto-memory entry, so nothing is evicted.

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

Run by the Stage-6 spoke on #8617 after this file was written and before it was committed, on base `f8d88626`.

| Check | Command | Observed |
|---|---|---|
| Stamp manifest (step 3b) | `bash release/tools/claim-version.sh --verify-stamp required-checks-enforce-as-declared` | exit 0 — "verify-stamp OK … carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". The file carries exactly 1 literal placeholder (python count) |
| CIAC authoring lint (A1) | `bash release/tools/verify-release-plan.sh --ciac-lint release/releases/plans/required-checks-enforce-as-declared_RELEASE_PLAN.md` | exit 0 — `CIAC-LINT-SUMMARY declared=3 parsed=3 clean=2 declared-deferral=1 flagged=0`; CIAC-1 and CIAC-2 CLEAN, CIAC-3 DECLARED. G4-06 holds on the committed plan |
| Full verifier (RED arm) | `bash release/tools/verify-release-plan.sh release/releases/plans/required-checks-enforce-as-declared_RELEASE_PLAN.md` | exit 3 — **4 PASS / 7 FAIL / 16 SKIP / 0 UNRUNNABLE / 0 ERROR over 27 records** (18 per-issue, 3 cross-issue, 6 always-on). Every runnable per-issue row (4) reads FAIL against the baseline tree — each row's sensitivity arm for its later GREEN; CIAC-1 reads 2 (wanted 0) and CIAC-2 reads 0 (wanted at least 2), likewise. `FCM-COVERAGE` PASS: `declared=21 interpreted=21 obligations=1 excluded=10 conditional=0 uninterpreted=0 pathless=0 prose_led=0`; FCM-1 FAIL pre-commit (this file, which delivers at this commit). `PROV-PRESENCE` / `PROV-GRAMMAR` PASS (Form X) |
| Doc links and plan depth | `python3 core/deploy/tools/check-doc-links.py --target-paths release/releases/plans/required-checks-enforce-as-declared_RELEASE_PLAN.md --require-targets`; `python3 release/tools/check-release-links.py`, bare and with `--plan-depth-lint` | doc links exit 0, no findings; release links exit 0 and plan depth exit 0, 0 findings. Sensitivity arm: with CIAC-1 spelled as the Stage-4 comment wrote it, the same two reads returned exit 1 and 2 findings each (DEV-15) |
| Skill-roster totals (R5) | `python3 core/deploy/tools/check-skill-count-imp.py --files <this file> --mode both` | exit 0, no finding. Control: a one-line content file carrying a seeded roster total, scanned as this path with `--scan-pair`, exits 1 with one count finding |
| Identity strings, host URLs, link sequences | a python line scan of this file for the operator handle, name and home path, an email address, a hyphen-suffixed repository slug, a raw host URL and a markdown link sequence | 0 in every class. Control: one constructed line carrying one of each fires every class but the bare-username class, whose input it does not carry; the home-path class covers that spelling |
| Close-family keywords | a python scan for a close-family verb followed by an issue number | 0 in this file |

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **The Outcome gains a seventh limb** — "a malformed `gate-efficacy:` header fails naming its own workflow → #8424" — with its AFTER sentence and BEFORE contrast; the `**Limb owners:**` line carries 7 limbs (2 owned by #8325, 5 by #8424) | Stage-4 Decision Recorded, PA-001 | **APPLIED** — § Release Outcome Statement |
| **DEV-2** | **The valve.** Its checkpoint is Stage 7 entry, Tuesday 2026-11-17 (PA-005), not Stage 9; AC7 (step 3) moved into the valve-safe set, steps 1–3, with the qualified-header fallback `required(enforce; ratified 2026-10-27)` and limb 7 re-pointed with limbs 4–6 when step 3 is not ready (PA-009). R2 is rewritten to match | Stage-4 Decision Recorded PA-005; scope-lock PA-009 | **APPLIED** — § Implementation Sequence, § Risk Register |
| **DEV-3** | **D-Divergence-Definition rendered as shape (a)** — *held* needs the qualifier and a HOLD-family row; a qualified declaration with no row, absent from the live set, is the fourth class (unrecorded hold); *held and registered* keys on the qualifier alone. The Stage-4 plan routed three candidate shapes to Stage 5 without a recommendation | scope-lock PA-008 | **APPLIED** — step 4 |
| **DEV-4** | **D-HeaderForm rendered as bare `posture=required`** for both flipped workflows; the Stage-4 plan routed the bare form and `required(enforce; ratified <date>)` to Stage 5 | scope-lock PA-009 | **APPLIED** — steps 1 and 2 |
| **DEV-5** | **D-AC7-Mechanism rendered as a closed posture vocabulary** (mandatory `posture` key; `required` or `advisory` with an optional parenthesized qualifier; the attribution repair; the embedded-key check kept as a diagnostic; arms for a misspelled posture and a missing posture field; 44 live declarations as the specificity input) | scope-lock PA-010 | **APPLIED** — step 3 |
| **DEV-6** | **Step 1 widened.** The Stage-4 step named 4 standard rows; Stage 5 found 14 (13 the flip makes false, plus the census row the rename touches), and the scope-lock adds the `:514` lede, one `:614` clause for both cards, `:520` wording that never records the registration as taken, one retreat shape for both cards, and Check 74's falsification line below `enforce`. `deploy.sh`'s edit set is the 12 sites of the semantic-touch criterion. The gate step is renamed `Gate decision (exit code -> job conclusion)`, so the census row changes in the same commit; the warn-mode paragraph is `:85-90`, not the Stage-4 `:85-92`. The flip-record disposition token is `**REGISTER**` | Stage-5 design on #8615; its A6.5 review (PR-2, FM-2, FM-3); scope-lock adjustment item 1 | **APPLIED** — step 1 |
| **DEV-7** | **`deploy.sh`'s dispatcher roster comment** reads Checks 38, 73, 77 and 78 — a site the Stage-5 design routed as out-of-scope drift, taken into step 1 by the scope-lock | scope-lock adjustment item 2 | **APPLIED** — step 1 |
| **DEV-8** | **The ruleset reader dispatches by allow-list**, lives in the workflow, and yields a verdict only when both live reads return. Every place this plan expects a reconciler run to read `RECONCILED` names both live inputs — the branch-protection object and `rules/branches/main` (step 4, step 7, CIAC-3, the Stage-7 reconciler run) | scope-lock adjustment items 3 and 4 | **APPLIED** — step 4; § Implementation Sequence, § Cross-Issue Acceptance Criteria, § Verification Plan |
| **DEV-9** | **The three Stage-4 CONDITIONAL matrix rows are promoted** into the unconditional set: `.github/workflows/gate-posture-reconciliation.yml` and `core/deploy/tools/README.md` (`STAGE5-RULESET-READ-IN-WORKFLOW` fired) and `release/references/pipeline/stage-07-dev-testing.md` (`STAGE5-P1P3-RUNNER-ANCHORS` fired; anchors in the sentences that carry their verdicts) | scope-lock adjustment item 4 | **APPLIED** — § File Change Matrix |
| **DEV-10** | **Stage-6 instructions for #8424:** `${WARN_MODE:-false}` in the skill-count flip commit; the table-reader self-test arms renamed TB1–TB6 and registered in tier 2; Stage 7 confirms `rules_status=fetched` on the first PR run after step 4; #8424's `### Source(s)` entry led by its handle | scope-lock adjustment items 1 and 4 | **RECORDED** — applied by #8424's Stage-6 spoke |
| **DEV-11** | **Routing with no new issues:** the token↔phase residual enriches #7021; the three deferred follow-ons fold into an existing epic-#5867 slice at Stage 13; Check 71's retreat wording enriches #8549; the exact text goes to the operator before anything is posted. The runner agreement assertion offered on #8615 is not adopted | scope-lock adjustment item 5 | **RECORDED** — § Exclusions |
| **DEV-12** | **#8325's body is not refreshed** (A0.6 advisory): its Affected Files still lists `core/hooks/` and its open assumption stands in the body; the 2026-10-27 decision comment resolves both | Stage-4 Decision Recorded, PA-006 | **RECORDED** — the body stays as historical record |
| **DEV-13** | **The milestone description gained a Parallelization Map** recorded 2026-11-03, the Phase A0 Tier 1 [ADJUST] finding | Stage-4 Decision Recorded | **APPLIED** (milestone description, read back equal) |
| **DEV-14** | **Commit 0 and step 1 were authored outside the hub-named release worktree.** The spoke's session harness isolated it to its own worktree on the same base (`f8d88626`) and refused git operations in the hub's release worktree; the commits are pushed to `release/required-checks-enforce-as-declared` by the detached-HEAD refspec. The hub's local release branch stays at the base until it is fast-forwarded to the remote | the harness control; the persona's branch-checkout-conflict recovery | **RECORDED** — execution only; no plan content changes |
| **DEV-15** | **CIAC-1's method respelled, not changed.** As the Stage-4 comment wrote it, the bold-token class `[*][*]` followed by the parenthesized alternation reads to the release link checker as two markdown links whose target is the alternation, so committing it verbatim made `check-release-links.py` report two broken links in this file (exit 1) — the reader behind the required Dead-file-reference gate. The subject and control arms now spell the literal `**` as `\*\*`. The match set is unchanged: at the pin both spellings read 2 on the subject arm and 2 on the control arm, under `grep -E`, `/usr/bin/grep -E` and Python `re` alike | Stage-6 A1 (this commit) | **APPLIED** — § Cross-Issue Acceptance Criteria |

---

## Issue References

- **#8325** — the gate-rollout graduation card: the pre-merge load-bearing subset flips to enforce and Check 74 reads green for the recorded reason. Mark as closed at Stage 13.
- **#8424** — the required-context posture card: the skill-count flip, the reconciler's blind spots, the P1–P3 register rows and the malformed-header attribution. Mark as closed at Stage 13.
- **#8604 · #8615 · #8616 · #8617 · #8618** — the Stage-4 sub-task (plan and gate record), the two Stage-5 sub-tasks (designs, adversarial reviews, scope-lock), and the two Stage-6 sub-tasks.
- **#7932 · #5867** — the parents: an evergreen flow container (#8325) and the epic (#8424).
- **#7021** — owner of the sentinel-and-restated-mode class; enriched with the token↔phase residual.
- **#8549** — enriched with Check 71's retreat wording.
- **#8482** — the skill-count detector's `++` added-line gap, a residual of the skill-count flip record.
- **#7466** — the dormant consumer of the renamed gate step.
- **#4714** — the containment premise that reads false after the merge (AI-002).
- **#6195 · #7026** — the same-shape graduation-deadline cards for the egress rule and Check 71.

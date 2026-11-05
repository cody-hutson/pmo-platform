---
title: Release Plan — release-usage-measured-right (Usage measured right)
type: release-plan
plan_type: release
status: IN PROGRESS
release: versioned (bump-class minor; provisional display v5.02; the concrete number binds at the Stage-12 atomic claim)
milestone: release-usage-measured-right
release_class: novel
reversibility: MODERATE / Confidence MEDIUM — the FinOps store's counting unit changes under a MAJOR schema bump, two decision records are added, and the Stage-13 close-out gains a cost-row phase. Reverting the release merge and rebuilding the store restores the prior counting (the store is a derived cache, and the pre-fix store is preserved once); a merged ADR is superseded, never deleted; a claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `release-usage-measured-right`

**Milestone:** `release-usage-measured-right` (milestone 429), MS-0 of the token-efficiency thrust (epic #7934). The Stage-4 planning sub-task **#8662** carries the approved plan, the Stage-4 gate's Decision Recorded and the Collective Review scope-lock Decision Recorded. The eight Stage-5 designs are on #8712–#8719 and their independent Phase A6.5 adversarial reviews on #8799, #8800, #8801, #8809, #8810, #8812, #8813 and #8819. This file is Engineering Commit 0, authored by the first Stage-6 spoke on **#8724** (#7940).

**Version identity:** **versioned** — bump-class **`minor`**, provisional display **`v5.02`** (the next-free minor recomputed at this commit). The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only.

**Topology:** D-C **SINGLE** — one release branch, `release/release-usage-measured-right`, one pull request opened in **draft** after beat 1 lands, one merge into `main`.

**Concurrency posture:** **P0 fully serial** — one Engineering spoke at a time, in the Implementation Sequence order; each spoke syncs `origin/main` before it starts. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`, with a recorded override of cross-cutting trigger (c) (PA-002); the Collective Review accepted the bundle over band (PA-007). Stage 9 review depth **Deep** (§ Release Class declaration).

**Date:** no external deadline. The release PR waits for #7935's probe window after the weekly reset of Thursday 2026-11-12 (PA-003), and #8041 is authored after the probes it is graded on.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8662 (comment 6662846825) and is amended by three records, in order: the Stage-4 plan-gate Decision Recorded on #8662 (comment 6663038872; "Approve all", PA-001 to PA-006), the eight Stage-5 designs with their eight Phase A6.5 reviews, and the Collective Review scope-lock Decision Recorded on #8662 (comment 6670127013; "Keep all 8", PA-007 to PA-016, with the hub's adjustment ledger applied at this commit). Where the Stage-4 plan and a later record differ, the later record wins, and each such change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): new decision records and new scripts, per the Bump-Class Selection Guide. Provisional display `v5.02`, re-verified free at Engineering Commit 0 (§ Commit-0 Version Re-Verify Record); the concrete number binds at the Stage-12 atomic claim (ADR-092). Five of the six in-flight sibling releases also compute `v5.02`, so the claim will likely resolve higher; the atomic claim absorbs the race (R6) |
| **Date Created** | 2026-11-05 (Thursday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | In progress — Stage 6 Engineering; Engineering Commit 0 landed, beat 1 (#7940) next |
| **Branch** | `release/release-usage-measured-right` |
| **PR** | opened in **draft** at Stage 6 Phase C2 after beat 1; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `release-usage-measured-right` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-05, domain: software }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix row is an internal pmo-platform artifact — FinOps skill scripts, fixtures and references, a schema, a configuration template with its schema and catalog, two decision records and their index, a standard, a release tool, the close-out pair and a stage spec — so no external body of practice is consumed. Dominant domain **`software`** (five of eight cards change scripts); secondary domain governance (two ADRs, a register row and a stage spec). Guide: `core/standards/domain-best-practices/software.md`. Transcribed unchanged from the Stage-4 plan (Phase A1.5).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `b1042eec` (`b1042eecd6294d4c460c109f2c4b8dd6ed9896a9`), the Stage-4 sibling-merge re-check head. The 5 commits since the Stage-4 pin `ac96b3ea` touch 7 release-corpus paths (the v5.01 Stage-13 chore), none in this matrix. This file is written on that base |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha b1042eecd6294d4c460c109f2c4b8dd6ed9896a9 --bump minor --dry-run` (the adapter's own allocation; no tag pushed) | **`v5.02`** (exit 0; "would claim v5.02 (no tag pushed)"), equal to the Stage-4 provisional display |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each read by one python3 line scan that compares exact (major, minor) version
             tuples carrying no patch component
Denominator: 457 ls-remote lines (222 distinct versions; the highest is v5.01); 228 published
             Releases (under the 5000 limit, so not truncated); the ledger at origin/main,
             2,935 lines. The ledger's highest tuple reads v9.99, a placeholder in prose, not a
             claim; it does not touch the v5.02 slot
Control - sensitivity: the same scan on the v5.01 slot — 2 tag lines, 1 Release line and
             7 ledger lines. Every arm returns non-zero, so a zero on the v5.02 slot is a
             real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version tuple
             has no near-miss class the probe must reject (the comparator is tuple equality,
             so v5.0.2 and v5.020 are different tuples, not prefixes)
Extraction:  the whole ls-remote output (26,701 bytes), the whole Release list (22,567 bytes)
             and the whole ledger (950,013 bytes) read from origin/main, never the worktree copy
Result:      0 occupants of the (5,2) slot on every arm
Verdict:     CLEAN — v5.02 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** six sibling release pull requests are open, five of them `minor` and one version-less (§ Cross-PR Overlap Audit → In-Flight Release Roster). Each `minor` sibling recomputes the same `v5.02` slot; whichever merges first takes it, and every later atomic claim computes the next slot. This is the Tier-S version edge the Stage-4 plan recorded, now with five contenders rather than one.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp release-usage-measured-right`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file. For the same reason this file names the ADR citation tokens rather than reproducing them: the Stage-12 stamp resolves every token in the branch diff, and an unresolvable one (a record that left the release) would refuse the stamp.

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0, as `date -u +%Y-%m-%d` → **`2026-11-05`** (Thursday). It fills the cost-unit ADR's `date:` field and the seed line of its gate-coverage register row at beat 1 (#7940's design), and the date of the store schema's new Version-History row at beat 2 (#7937's design). Historical dates inside `source_observations:` and the dated census figures are past facts, not resolved variables.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited; the Stage-5 and Collective Review resolutions applied at this commit) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria `CIAC-1`..`CIAC-6` | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence (the approved build order, as Stage 5 and the scope-lock resolved it) | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA `ac96b3ea`; the Commit-0 base `b1042eec`) | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Issue | Priority | Title | Disposition |
|---|---|---|---|
| #7940 | P2 | The release-graph cost model and unit | carried; Stage-5 design on #8716 with its A6.5 review on #8809 (CONDITIONAL, aggregate Major); D-Home (A) and D-Revisit (A) rendered at the scope-lock |
| #7937 | P2 | finops extract-usage.sh counts every assistant line, over-counting API responses 1.8–3.4× | carried; design on #8713, review on #8801 (CONDITIONAL, aggregate Major); D-1 MAJOR `2.0.0` and D-3 preserve-once rendered |
| #7938 | P2 | finops extractor silently under-counts output when only a partial output_tokens is written | carried; design on #8714, review on #8799 (PASS, aggregate Minor) |
| #7939 | P2 | report-usage.sh rejects every real store: its started_utc check forbids fractional seconds | carried; design on #8715, review on #8800 (PASS, aggregate Minor); AC-4 added at the Stage-4 gate |
| #7943 | P2 | Stage 13 records each release's cost: a usage row by stage, role and token type | carried; design on #8717, review on #8810 (CONDITIONAL, aggregate Major); D-Thinking and D-HomeAnchor rendered; AC-1 amended (thinking counted inside output) |
| #7945 | P3 | Rank retyped command templates by cost to feed the agent-to-script promotion ladder | carried; design on #8718, review on #8819 (CONDITIONAL, aggregate Major); D-Threshold rendered |
| #7935 | P2 | Seven cheap probes that decide which token levers are real | carried; design on #8712, review on #8812 (CONDITIONAL, aggregate Major); D-WindowBudget rendered; its Stage 6 is hub-run (spokes cannot spawn sessions) |
| #8041 | P2 | Model-use policy for release runs: which model and effort each role runs on, and where the advisor is consulted | carried; design on #8719, review on #8813 (CONDITIONAL, aggregate Major); D-Status, D-Coverage, D-Flagship, D-Margin and D-Beat8 rendered; AC-4's method narrowed (PA-012) |

### Exclusions

| Item | Why it is out of scope | Routed to |
|---|---|---|
| The cross-file `message.id` residual (copies across resumed or forked sessions; 2.52 % of per-response mass overall, 7.39 % of main-session mass) | needs a cross-file index, a new abstraction; the per-file unit is disclosed in the schema and the cost-unit ADR instead | a follow-up, re-sized on main-session figures (#8801 PR-1) |
| Advisor and fallback sub-call usage the store cannot read | measured by #7935 probes 3–4 first | a follow-up after the probes (#8713) |
| The lower-bound label on report, contract and estimate figures for incomplete responses | a user-visible feature beyond #7938's flag | a follow-up (#8714 R4) |
| The quota-budget § 5.2 FinOps substrate, overstated until #7937 lands | another card's surface | #7536's owner |
| The drift the Stage-4 plan gate held as follow-up candidates (the G-PL5 title guard, the unarmed skill-edit marker, the Stage-3 trigger (c) check, the undefined "compositional edge", a stale upstream-catalog entry) | filing-step candidates | the Stage-13 filing step |
| `[spoke_runtime]` and the standing model-and-effort directive | #8041 AC-4 holds them unchanged | none |

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-05)

| Decision | Rendered |
|---|---|
| PA-001 Plan + Release Outcome Statement | **Approved** ("Approve all"), with the `**Limb owners:**` line added to the Outcome |
| PA-002 D-ReleaseClass | **(B) `novel`**, with a recorded override of cross-cutting trigger (c) (three in-bundle edges, all depth 1, in two disjoint chains; one stage spec and no rule-defining surface change) |
| PA-003 D-ProbeWindow | **(A)** the window after the Thursday 2026-11-12 weekly reset, with the other release hubs paused for the probe interval; probes 1, 2, 6 and 7 run earlier; #8041 follows the window and the PR waits for it |
| PA-004 D-DataHome | **(A)** #7945's report under `<OPERATOR_INSTANCE_ANALYSIS_PATH>`; #7943's row in placement-rules-and-adr's `/local-state/telemetry/` home. Only beat 5b waits on that milestone; fallback (B) if it has not merged by Stage 9 |
| PA-005 D-RankerHome | **(A)** a new script under `core/skills/finops-usage-extractor/scripts/` |
| PA-006 D-Concurrency Posture + D-C Branch Topology | **P0 fully serial · SINGLE** |
| D-Version | **Recorded, not asked:** bump class minor, provisional `v5.02`; the atomic claim absorbs the race with the concurrent claimants |
| Per-card disposition | `card-disposition:carried` for all 8 cards |

### Collective Review scope-lock (operator, 2026-11-05)

Operator verdict "Keep all 8". **Scope is hard-locked through Stage 9; Engineering is authorized.** PA-008 to PA-016 were rendered as recommended; none was overridden by name.

| Decision | Rendered |
|---|---|
| PA-007 D-Scope | **(B)** keep all 8 cards; **over-band accepted** (record below) |
| PA-008 #7937 D-1 | **MAJOR `2.0.0`** for the store schema; the ADR-101 frozen-kind exemption is not claimed |
| PA-009 #7937 D-3 | preserve the pre-fix store **once**, in a `prior/` directory form (CD-2 of #8801) |
| PA-010 #7940 D-Home | **(A)** the `[cost_unit]` numeric home in the platform behaviour configuration, created in **#7940's** slice (not #7943's), with one conversion and **CD-2's per-model axis** (#8809) |
| PA-011 #7940 D-Revisit | **(A)** the first calibration revisit runs in this release, after #7935's probes, over **eligible pairs only** (#8809 PR-1 and FM-1) |
| PA-012 Tier-2 scope change raised by #7940 | **approved** — #8041 AC-4's method narrows from a whole-file diff of the configuration template to a section compare of `[spoke_runtime]` at the merge-base, keeping the whole-file diff for the overrides allowlist |
| PA-013 #7943 D-Thinking + D-HomeAnchor | no fifth token leaf (thinking is counted inside output; AC-1 amended); the row lives in `/local-state/telemetry/` |
| PA-014 #7935 D-WindowBudget | ≈ 8 weekly points and one quiet day; control = an equal no-activity interval; a beat-P dry run first |
| PA-015 #8041 D-Status / Coverage / Flagship / Margin / Beat8 | Proposed until the parity arms run; per-role detection evidence; the directive governs until Accepted; the spoke's default margin; authored after the recorded probes |
| PA-016 #7945 D-Threshold | Mode C holds candidates and the report is the deliverable; CD-1 to CD-4 (privacy controls first) land before engineering |

**Over-band record** (bundle-composition-doctrine over-band acceptance):
- **Size:** ≈ 42 raw / ≈ 48 effective points against the 25 ceiling. #7943 and #7945 were re-sized to L by their Stage-5 verdicts; #7937 → L and #7938, #7939, #7940, #8041 → M are hub projections from each card's File Change Matrix. Size labels are not re-stamped.
- **Rationale:** the operator kept the milestone whole as MS-0 of #7934, including the probes and the model-use ADR.
- **Consequence:** the release PR waits for #7935's probe window before #8041 is authored; Stage 6 is long and serial (P0); Stage 9 is Deep over a large diff.

**The adjustment ledger** (about 40 CHEAP Tier-1 [ADJUST] edits drawn from the Stage-5 outputs and reviews, part of PA-007) is applied at this commit where it amends the plan — the File Change Matrix, the per-card write sets, the Implementation Sequence, the Stage Applicability Matrix and the Verification Plan (§ Deviation Log DEV-1 to DEV-9). The ledger's per-card design adjustments are applied by each card's own Engineering beat, from that card's Stage-5 output and review.

---

## Dependency Graph

```
native edges (GraphQL blockedBy / blocking, 2026-11-05; 8 cards; 3 blockedBy edges, every blocker inside the bundle):
  #7937 ──► #7938
    └─────► #7943 ──► #8051, #7950        (successors, outside)
  #7935 ──► #8041
    └─────► #7936, #7942, #8051           (successors, outside)
  #7939 · #7940 · #7945                   (no native edge)
soft planning edges (A -> B means B consumes A's output):
  #7937 -> #7939                 shared fixtures and package
  #7940 -> #7943, #7945, #8041   the unit and its numeric home are their design input; the ADR is cited by slug token
  #7943 beat 5a -> #7945 beat 6  the single conversion (the ranker calls it, never re-implements it)
  #7935 window W -> #7940 beat 1R  the probe readings the first calibration revisit pools
  placement-rules-and-adr -> #7943 beat 5b (D-DataHome A)
cross-milestone: see § Cross-PR Overlap Audit
```

Circular chains: **0** — the graph is acyclic; a topological order exists (the Implementation Sequence below).

---

## Implementation Sequence

Single branch `release/release-usage-measured-right`, posture **P0 (fully serial)**. Each beat is committed and pushed on landing (Write-Early). It follows the operator order: #7937 before #7938 and #7943; #7935 before #8041; #7940's beat 1 first because the unit and its numeric home are the design input of #7943, #7945 and #8041.

| # | Beat | Card | What lands (as Stage 5 and the scope-lock resolved it) | Start condition |
|---|---|---|---|---|
| 0 | Engineering Commit 0 | — | this file, carrying the Commit-0 Survival Set and the stamp manifest | operator plan approval and scope-lock; Commit-0 version re-verify (steps 1–3 and 3b) |
| 1 | cost-unit ADR and its numeric home | #7940 | the ADR (number from `renumber-adr.py --next-free` for its filename, title and H1; cited elsewhere by its slug token), the regenerated release ADR index, one class-3-O gate-coverage register row, and the `[cost_unit]` section with its per-model axis in the configuration template, its schema rows and its catalog section (D-Home A); the #8809 CHEAP adjustments folded in | — |
| 2 | per-response counting, schema MAJOR `2.0.0`, preserved prior store, SKILL.md note | #7937 | per #8713's commit order (C1–C5, then C7–C8, then C6, C9, C10 and, if accepted, C11), with #8801's adjustments | — |
| 3 | incomplete-response flag | #7938 | per #8714, inside #7937's per-response reduction | beat 2 committed |
| 4 | report accepts real timestamps | #7939 | one commit, Changes 1–4 per #8715, the validator widening and the filter change together | beat 2 committed (fixtures) |
| 5a | per-release cost row: computation, the single conversion, fixtures, self-test (injected path) | #7943 | per #8717: `convert-usage.sh` (the one conversion over `[cost_unit]`), its allowlist rows and CI loop entry, the two public-API rows, the velocity standard, then `--cost-row` | beats 1, 2 and 3 committed |
| 5b | default home via the registered token, and the Stage-13 hook wiring | #7943 | the home rows in one commit, then the close-out pair | D-DataHome A: placement-rules-and-adr merged (gates shipping, not building); fallback (B) at Stage 9 |
| 6 | command-template ranker | #7945 | per #8718's commit order (lib resolver, fixtures, ranker, allowlist and CI, SKILL.md and the framework), CD-1 to CD-4 first | beat 5a committed (the conversion) and beat 2 committed |
| 7 | package-rebuild beat | — | one `bash core/deploy/tools/build-skill-packages.sh finops-usage-extractor` plus the `version:` stamp | last skill slice committed; allocator dry-run re-run |
| P | probes 1, 2, 6 and 7, and the beat-P dry run | #7935 | hub-run; produces no commit | after plan approval |
| W | probes 3–5 with control readings | #7935 | hub-run; D-ProbeWindow (A), D-WindowBudget | after the 2026-11-12 reset, other hubs paused |
| 1R | first calibration revisit; re-ground the cost-unit ADR | #7940 | pool only **eligible** clean pairs (FM-1); append the dated revisit line to the register row; edit `[cost_unit]` only if a value moves under the ADR's sufficiency rule; while the ADR is still Proposed, add the probe 3 and 4 results that bear on the unit to its `source_observations:` and re-confirm or amend Decision 1 (which window) and Decision 3 (per-model draw) against them (PR-1) | window W recorded on #7935 |
| 8 | model-use ADR | #8041 | per #8719, after D-Beat8's entry rule passes; the next branch-local ADR number after beat 1's | probes 3, 4 and 6 recorded on #7935 |

Cross-release merge order: this release merges before the slot `finops-estimator-correctness` is composed.

### Card change specifications

Each card's change specification is its Stage-5 design comment as amended by its A6.5 review and the scope-lock; this file does not restate them. The bindings this file carries:

- **#7940 (beat 1, 1R)** — design #8716; review #8809. **Applied at beat 1:** D-1 (A) the defined term "release run graph" with the slug `release-graph-cost-unit` kept as the identifier; D-2 (A) the counting definition adopted from the store schema by reference; D-3 (A) four elements plus a named remainder; D-4 = D-Home (A); D-5 (A) raw planned points; D-6 (A) the revisit rule as a class-3-O named gap. **Folded from #8809 (CHEAP):** PR-3 (sign and magnitude of the store's coverage limits, which enter the unit through `K`; store-complete clean pairs), FM-5 (the counting unit is scoped to one transcript file; INT-1 gains a sixth property, same scope) together with #8801 PR-1's per-file counting-scope sentence, FM-3 (the remainder renamed "unplaced", orthogonal to ADR-097's `unattributed`; shares over the grand total), FM-6 (the dominance rule), FM-2 (the evidence-and-versioning contract in Decisions 3, 4, 5 and 8 and the register line format), PR-2 (Decision 5: shares are robust to `K`, not to the weights). **With D-Home (A):** CD-2's optional per-model axis (draw multiplier and weekly windows per model; absent means unprobed). **With D-Revisit (A):** PR-1 and FM-1 at beat 1R. The conversion itself is #7943's (beat 5a); the ADR names it by role.
- **#7937 (beat 2)** — design #8713; review #8801: D-1 MAJOR, D-2 (A), D-3 preserve-once (A, the `prior/` form), D-4 (A), D-5 (A), D-6 (A) and the `rollup-attribution.sh` re-stamp; PR-1's one disclosure sentence on the per-file scope in the schema's § Counting unit, its Version-History row and the SKILL.md note; CD-1's version-aware predicate and message; FM-1 to FM-3 inside C2, C3, C5 and sub-test 11.
- **#7938 (beat 3)** — design #8714; review #8799: `incomplete` computed inside #7937's per-response reduction (FM-1/PR-1); the lower-bound label is a follow-up.
- **#7939 (beat 4)** — design #8715; review #8800: REC-1 (the contract and the fixture README in the write set), REC-3 (the validator widening and the filter change in one commit), F1/F2 text edits inside the write set; Stage 7 executes the bash control flow of Changes 1c–1f, which no spoke ran.
- **#7943 (beats 5a, 5b)** — design #8717; review #8810: PR-2, CD-1, FM-1, FM-3, FM-4, CD-2 and FM-2's text inside the write set; the TOML reader lifted verbatim from the master-enable reader; join on file path, not stem; scratch store under a run temp directory with a cleanup trap; the placement-rules relays (the XDG state telemetry decision, the `/local-state/` main-checkout carve-out and the register-to-hook parity check) in the beat-5 brief.
- **#7945 (beat 6)** — design #8718; review #8819: CD-1 to CD-4 (privacy controls first) before engineering (PA-016); Mode C holds candidates.
- **#7935 (beats P, W)** — design #8712; review #8812: hub-run; the per-site decision rules bound to the G1 rubric, the window's control and attribution under D-WindowBudget, the R-6 calibration block for beat 1R.
- **#8041 (beat 8)** — design #8719; review #8813: the F1–F6 frame, the option × probe table, the four-part pass rule, the admissibility, evidence and cost-leg decisions under PA-015, and the AC-4 section compare (PA-012).

---

## Stage Applicability Matrix

| Card | S5 | S6 | S7 | S8 | S9–S13 |
|---|---|---|---|---|---|
| #7935 | APPLY (ran): probe protocol | APPLY (hub-run): run probes, post results (no commit) | SKIP: no tracked change | APPLY | release-scoped |
| #7937 | APPLY (ran) | APPLY | APPLY | APPLY | release-scoped |
| #7938 | APPLY (ran) | APPLY | APPLY | APPLY | release-scoped |
| #7939 | APPLY (ran) | APPLY | APPLY | APPLY | release-scoped |
| #7940 | APPLY (ran): ADR authoring | APPLY | **APPLY** — D-Home (A) puts the `[cost_unit]` section, its schema rows and its catalog section in this card's slice, so its Stage-7 SKIP no longer holds (Check 33 parse, the configuration surface's readers, the ADR lints) | APPLY | release-scoped |
| #7943 | APPLY (ran) | APPLY | APPLY | APPLY | release-scoped |
| #7945 | APPLY (ran) | APPLY | APPLY | APPLY | release-scoped |
| #8041 | APPLY (ran) | APPLY | SKIP: no functional impact (ADR lints run at S6 C4 and in CI) | APPLY | release-scoped |

Parallel-eligible: S5 8 (ran) · S7 6 · S8 8.

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. A shared path is listed once, under the first beat that edits it; the cards that edit it are named in § Per-card write sets. `NNN` is the ADR number allocated at authorship and bound at the Stage-12 claim.

```
# ── Engineering Commit 0 ──
release/releases/plans/release-usage-measured-right_RELEASE_PLAN.md  ADD
# ── #7940 (beat 1; beat 1R) ──
release/ADRs/ADR-NNN-release-graph-cost-unit.md  ADD
release/ADRs/README.md  EDIT
core/standards/gate-efficacy-standard.md  EDIT
core/config/platform-config.toml.template  EDIT
core/schemas/platform-config-schema.md  EDIT
docs/platform-config-reference.md  EDIT
# ── #7937 (beat 2) ──
core/skills/finops-usage-extractor/scripts/extract-usage.sh  EDIT
core/skills/finops-usage-extractor/test-fixtures/per-response/  ADD
core/skills/finops-usage-extractor/test-fixtures/usage.expected.json  EDIT
core/skills/finops-usage-extractor/test-fixtures/README.md  EDIT
core/schemas/finops-usage-store-schema.md  EDIT
core/skills/finops-usage-extractor/scripts/rollup-attribution.sh  EDIT
core/skills/finops-usage-extractor/references/reporting-contract.md  EDIT
core/skills/finops-usage-extractor/SKILL.md  EDIT
# ── #7939 (beat 4) ──
core/skills/finops-usage-extractor/scripts/report-usage.sh  EDIT
core/skills/finops-usage-extractor/test-fixtures/report/usage.jsonl  EDIT
core/skills/finops-usage-extractor/test-fixtures/report/README.md  EDIT
# ── #7943 (beats 5a, 5b) ──
core/skills/finops-usage-extractor/scripts/convert-usage.sh  ADD
core/config/allowlists/script-execution-allowlist.txt  EDIT
.github/workflows/release-tooling-smoke.yml  EDIT
core/README.md  EDIT
docs/module-apis.md  EDIT
release/references/standards/release-velocity-tracking.md  EDIT
release/tools/compute-release-velocity.sh  EDIT
core/deploy/lib-instance-path.sh  EDIT
core/deploy/tests/test_lib_instance_path.sh  EDIT
core/config/operator.toml.template  EDIT
core/config/operator-toml-schema.json  EDIT
core/standards/depersonalization-spec.md  EDIT
release/tools/automated-closeout.sh  EDIT
release/references/pipeline/stage-13-close.md  EDIT
# ── #7945 (beat 6) ──
core/skills/finops-usage-extractor/scripts/rank-command-templates.sh  ADD
core/skills/finops-usage-extractor/test-fixtures/rank/  ADD
core/standards/agent-script-promotion-framework.md  EDIT
# ── #8041 (beat 8) ──
release/ADRs/ADR-NNN-model-use-policy-for-release-runs.md  ADD
# ── package-rebuild beat (beat 7) ──
packages/finops-usage-extractor.skill  EDIT
packages/finops-usage-extractor.skill.sha256  EDIT
# ── conditional ──
core/standards/finops-attribution-convention.md  EDIT  CONDITIONAL:attribution-note-accepted
core/ADRs/README.md  EDIT  CONDITIONAL:adr-renumbered-at-claim
```

#### Read-only inputs

```
core/config/allowlists/agents-model-overrides.txt  READ
release/references/standards/quota-budget-protocol.md  READ
core/ADRs/ADR-101-finops-store-frozen-kind-versioning-exemption.md  READ
release/ADRs/ADR-102-quota-budget-successor-substrate-finops-cumulative-draw.md  READ
core/ADRs/ADR-097-finops-usage-attribution-convention.md  READ
release/tools/lib/platform-toggle.sh  READ
```

#### Release-wide explicit non-scope

```
core/skills/finops-usage-extractor/scripts/estimate-usage.sh  NOT EDITED
core/skills/finops-usage-extractor/test-fixtures/report/report.expected.json  NOT EDITED
core/hooks/  NOT TOUCHED
core/rules/  NOT TOUCHED
release/releases/RELEASE_LOG.md  NOT TOUCHED
release/releases/notes/  NOT TOUCHED
```

**The repository-root `.gitignore` is EDITED** — one stem for #7937's preserved store at beat 2 (#7937 C10) and #7943's home block at beat 5b (C12). It is named here rather than as a fenced row because the matrix reader recognises no repository-root path that carries no directory segment, so a fenced row reads as uninterpreted rather than as an edit; it is an EDIT, not an ADD, so no delivery obligation is lost.

The `[spoke_runtime]` section of `core/config/platform-config.toml.template` is **not edited** (#8041 AC-4): beat 1 appends the `[cost_unit]` section to that file and touches no other section. The deployed `.claude/` tree is not touched, and the repository-root `CHANGELOG.md` is written by the Stage-13 chore PR; neither is a fenced row, for the same reason and because the deployed tree is not tracked.

**The Stage-4 conditional rows are resolved at this commit** (rule 5 of the declared-vs-delivered contract; DEV-1):
- `CONDITIONAL:fixture-multiline` **fired** (#7937 C4, #7938 Change 4) → `usage.expected.json` promoted.
- `CONDITIONAL:schema-major` **fired** (PA-008, MAJOR `2.0.0`) → `rollup-attribution.sh` promoted (its re-stamp); `estimate-usage.sh` is **not** edited — it has no version gate and its control fixture is valid at any version (#8713) — so it moves to the non-scope block rather than staying conditional.
- `CONDITIONAL:contract-states-unit` **fired** (#7937 C8 § 2; #7939 Change 4 §§ 1, 6 and 8) → `reporting-contract.md` promoted.
- `CONDITIONAL:report-output-shift` **did not fire** — #7939's corrected render stays byte-identical to `report.expected.json`, so the oracle is not edited (#8715 D-3, REC-4) → moved to the non-scope block. If a later beat shifts the render, the row is promoted with its real basis recorded.
- `CONDITIONAL:ranker-in-skill` **fired** (PA-005, D-RankerHome A) → the ranker, its `rank/` fixtures, the allowlist and the smoke workflow promoted.
- `CONDITIONAL:framework-names-detector` **fired** (#7945 C12) → `agent-script-promotion-framework.md` promoted.
- `CONDITIONAL:row-schema-home` **fired** (#7943 C8) → `release-velocity-tracking.md` promoted.
- `CONDITIONAL:home-before-ms428` — the four home rows (`.gitignore`, `lib-instance-path.sh`, `operator.toml.template`, `depersonalization-spec.md`) are **owed under D-DataHome (A) too** (#8717) → promoted; beat 5b, which writes them, still waits on placement-rules-and-adr.

**Rows added at this commit** (Tier-1 [ADJUST]): `core/config/platform-config.toml.template` moves from Read-only to EDIT, with `core/schemas/platform-config-schema.md` and `docs/platform-config-reference.md` (D-Home A, PA-010); `core/standards/gate-efficacy-standard.md` (#7940 C3); `core/ADRs/README.md` as `CONDITIONAL:adr-renumbered-at-claim` (#7940 C4, #8041 C3 — written only by the renumber tool if a number moves at the claim); `core/skills/finops-usage-extractor/test-fixtures/README.md` (#7937 C5, #7938 Change 5, #7945 C6); `core/skills/finops-usage-extractor/test-fixtures/report/README.md` (#7939 Change 3); `.gitignore` for #7937's preserved-store stem (#7937 C10); `convert-usage.sh` with its allowlist rows and CI loop entry, `core/README.md`, `docs/module-apis.md` and `core/config/operator-toml-schema.json` (#7943 C2–C7, C15); `core/deploy/tests/test_lib_instance_path.sh` (#7943 C19, #7945 C11). `core/standards/finops-attribution-convention.md` moves from Read-only to `CONDITIONAL:attribution-note-accepted` (#7937 C11, RECOMMENDED; it resolves in beat 2's brief, and a declined note is an accepted residual).

**New-executable companion obligation.** Two `ADD` rows are executables: `convert-usage.sh` (#7943) and `rank-command-templates.sh` (#7945). Each carries its four `script-execution-allowlist.txt` invocation forms in the same release, and each is added to the `finops-selftest` job's loop in `release-tooling-smoke.yml` (the loop enumerates the FinOps self-tests; no other job runs them).

**Mover set:** empty — no path is renamed, moved or deleted. **One `pipeline/stage-*.md` file** is edited (`stage-13-close.md`), below the cross-cutting threshold, and none of the six rule-defining surfaces.

### Per-card write sets

- #7940: the cost-unit ADR, `release/ADRs/README.md`, the gate-coverage register row, the `[cost_unit]` section, its schema rows and its catalog section; conditionally `core/ADRs/README.md`.
- #7937: `extract-usage.sh`, the per-response fixtures, `usage.expected.json`, the fixture README, the store schema, `rollup-attribution.sh`, the reporting contract's § 2, the SKILL.md note, `.gitignore`; conditionally the attribution convention.
- #7938: `extract-usage.sh`, the store schema, a per-response fixture, `usage.expected.json`, the fixture README.
- #7939: `report-usage.sh`, the report fixture, the report fixture README, the reporting contract's §§ 1, 6 and 8.
- #7943: `convert-usage.sh`, the allowlist, the smoke workflow, SKILL.md, `core/README.md`, `docs/module-apis.md`, the velocity standard, the velocity tool, and at beat 5b `.gitignore`, `lib-instance-path.sh`, `operator.toml.template`, `operator-toml-schema.json`, `depersonalization-spec.md`, the close-out pair and `test_lib_instance_path.sh`.
- #7945: the ranker, its `rank/` fixtures, the fixture README, SKILL.md, the allowlist, the smoke workflow, `lib-instance-path.sh`, `test_lib_instance_path.sh`, the promotion framework.
- #8041: the model-use ADR and `release/ADRs/README.md`; conditionally `core/ADRs/README.md`.
- Package-rebuild beat: the package and its sidecar.
- #7935: none.

### Agent-Editability Read

Transcribed from the Stage-4 derivation (controls read at `ac96b3ea`) and re-applied to the promoted and added rows. **Tier-0 floor:** the surviving union of `core/hooks/block-autonomy-ceiling.sh`'s two `always_block "BLOCK-AUTONOMY-001"` blocks is the basenames `CLAUDE.md`, `OPERATIONS.md` and `RELEASE_PROTOCOL.md` at any depth; no matrix path carries one. **Sanctioned-session gate** (`core/hooks/block-skill-direct-edit.sh`): its scope regex matches `core/skills/finops-usage-extractor/SKILL.md` and `core/skills/finops-usage-extractor/references/reporting-contract.md` (conjunct 1 true), but the owning SKILL.md carries no skill-edit arming key (conjunct 2 false, re-read at this commit), so the gate does not arm; the skill is absent from the operator-instance exemption list (conjunct 3).

| Card | Write-set paths | Tier-0 ∩ | Skill-gate ∩ | Card class | Execution path |
|---|---|---|---|---|---|
| plan | this file | ∅ | ∅ — conjunct 1 false | — | first Engineering spoke (Commit 0) |
| #7940 | the ADR · the index · the standard · the configuration template, schema and catalog | ∅ | ∅ — conjunct 1 false | `unconstrained` | ordinary Engineering spoke |
| #7937 | the extractor, fixtures, schema, rollup, contract, SKILL.md, `.gitignore` | ∅ | SKILL.md and the contract: conjunct 1 true, **conjunct 2 false** | `unconstrained` | ordinary Engineering spoke; pmo-skill-editor discipline still applies by conduct (`Skill-Editor-Audit-Trail:` trailer) |
| #7938 · #7939 | extractor or report scripts, fixtures, schema, contract | ∅ | the contract: conjunct 2 false | `unconstrained` | ordinary Engineering spoke |
| #7943 | the conversion, allowlist, workflow, READMEs, standards, config template and schema, the lib and its test, the velocity tool, the close-out pair | ∅ | SKILL.md: conjunct 2 false | `unconstrained` | ordinary Engineering spoke |
| #7945 | the ranker, fixtures, allowlist, workflow, lib, test, SKILL.md, framework | ∅ | SKILL.md: conjunct 2 false | `unconstrained` | ordinary Engineering spoke |
| #8041 | the ADR and the index | ∅ | ∅ | `unconstrained` | ordinary Engineering spoke |
| beat 7 | the package and sidecar | ∅ | n/a: build output takes its source's class | — | ordinary Engineering spoke |
| #7935 | none tracked | — | — | `unconstrained` | hub-run probes; probe 7 needs an isolated hook layout, because the deployed `.claude/hooks/` arm is floored |

`unconstrained` says no control refuses the writes; it does not make them ungoverned.

---

## Contention Map

**Within release** (ADR-005 `overlap_class`; the serial P0 order resolves every row):

| File | Writers | overlap_class | Resolution |
|---|---|---|---|
| `extract-usage.sh` | #7937, #7938 | line-range-overlap (the same per-response reduction) | serialize beat 2 → 3 |
| `finops-usage-store-schema.md` | #7937, #7938 | line-range-overlap (versioning and session fields) | one MAJOR bump covers both; serialize |
| `usage.expected.json` | #7937, #7938 | line-range-overlap | serialize beat 2 → 3 |
| `test-fixtures/README.md` | #7937, #7938, #7945 | append-pattern | serialize |
| `reporting-contract.md` | #7937 (§ 2), #7939 (§§ 1, 6, 8) | append-pattern, disjoint sections (#8715 REC-1) | serialize beat 2 → 4 |
| SKILL.md | #7937, #7943, #7945 | append-pattern (distinct sections) plus one shared `version:` line | serialize; stamp once at beat 7 |
| `script-execution-allowlist.txt` · `release-tooling-smoke.yml` | #7943, #7945 | append-pattern (the ranker's block after the conversion's; one loop) | serialize beat 5a → 6 |
| `lib-instance-path.sh` · `test_lib_instance_path.sh` | #7945 (beat 6), #7943 (beat 5b) | append-pattern (distinct functions and cases) | serialize; beat 5b rebases on beat 6 |
| `.gitignore` | #7937 (one stem), #7943 (beat 5b block) | append-pattern | serialize |
| `release/ADRs/README.md` | #7940, #8041 | append-pattern (generated index rows) | beats 1 and 8; regenerated, never hand-edited |
| `core/ADRs/README.md` | #7940, #8041 (conditional) | renumber log, written by the tool only | Stage 12 |
| `platform-config.toml.template` | #7940 (`[cost_unit]`); #8041 AC-4 reads `[spoke_runtime]` | disjoint sections | AC-4's section compare (PA-012) |
| package and sidecar | beat 7 | single writer by construction | one rebuild after the last slice |
| velocity tool; close-out pair | #7943 | single-pr | rebase on the base at beat 5 |

**Cross-release** (pinned at Engineering Commit 0, `b1042eec`, 2026-11-05T21:45Z; a measurement with no verdict — Stage 9 Phase A6.6 re-measures):

| File / surface | This release | Sibling | Note |
|---|---|---|---|
| `core/schemas/platform-config-schema.md` · `docs/platform-config-reference.md` | beat 1 appends the `[cost_unit]` rows and section | placement-rules-and-adr (#8817) edits both | both append; the later merge rebases over the earlier one's rows |
| `core/standards/gate-efficacy-standard.md` | beat 1 appends one register row | #8817 and framing-altitude-and-slip-model (#8816) edit it | append-pattern on the register's last row; the later merge rebases |
| `core/config/operator.toml.template` · `operator-toml-schema.json` · `depersonalization-spec.md` | beat 5b | #8817 edits all three | the D-DataHome (A) edge already orders beat 5b after #8817 |
| `release/ADRs/README.md` and the ADR number space | beats 1 and 8 | sequencing-layer-foundation (#8811) adds `ADR-230` under `release/ADRs/` and edits the index; guards-judge-every-spelling-alike (#8651) holds core `ADR-230`/`231` | numbers bind at merge (`renumber-adr.py --detect` / `--stamp`); the index is regenerated at Stage 12 (R7) |
| `script-execution-allowlist.txt` · `release-tooling-smoke.yml` | beats 5a and 6 | #8811 edits both | append-pattern; the later merge rebases |
| `core/ADRs/README.md` | conditional | #8651 and #8817 edit it | the renumber log is appended only on a move |

---

## Cross-PR Overlap Audit

### Baseline SHA

`ac96b3ea123f6092070f29ca380ad159c1d87ab3` — the Stage-4 Phase A0 pin, re-read by the eight Stage-5 designs and their reviews. The Commit-0 base is `b1042eecd6294d4c460c109f2c4b8dd6ed9896a9`: `git log ac96b3ea..b1042eec --name-status` lists 5 commits touching 7 release-corpus paths (the v5.01 Stage-13 chore: the release log, index, digest and notes, the v5.01 plan, `CHANGELOG.md` and `.version`); ∩ this matrix = ∅, so the pin holds.

### In-Flight Release Roster

**Measured at:** `b1042eec` · `2026-11-05T21:45Z` (Engineering Commit 0) · **Population:** n=6 sibling(s)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `placement-rules-and-adr` | `#8817` (draft) | `9645f807` | `minor` | none read | `v5.02` | `core/ADRs/README.md`, `core/config/operator-toml-schema.json`, `core/config/operator.toml.template`, `core/schemas/platform-config-schema.md`, `core/standards/depersonalization-spec.md`, `core/standards/gate-efficacy-standard.md`, `docs/platform-config-reference.md` |
| `framing-altitude-and-slip-model` | `#8816` | `7aabc832` | `minor` | none read | `v5.02` | `core/standards/gate-efficacy-standard.md` |
| `composition-method-host-decision` | `#8815` | `19a0afe8` | `minor` | none read | `v5.02` | — |
| `stage-document-model-decision` | `#8814` (draft) | `36c6bd9b` | N/A — version-less (its plan's Bump Class row) | none | — (claims no slot) | — |
| `sequencing-layer-foundation` | `#8811` (draft) | `beb07cf4` | `minor` | none read | `v5.02` | `.github/workflows/release-tooling-smoke.yml`, `core/config/allowlists/script-execution-allowlist.txt`, `release/ADRs/README.md`, plus its own `release/ADRs/ADR-230-…` |
| `guards-judge-every-spelling-alike` | `#8651` (draft) | `3cadca6c` | `minor` | none read | `v5.02` | `core/ADRs/README.md` |

Population: open pull requests with a `release/*` head (6, every one carrying a `release/*` head) plus remote `release/*` heads with no open pull request (0) [SOURCE: `gh pr list --state open --limit 200` → 6 and `git ls-remote --heads origin 'release/*'` → 6 at the stamped instant]. Each sibling's bump class is read from the `**Bump Class**` row of its plan file on its own branch; the recomputed next-free applies the allocation rule to the fetched tags (anchor `v5.01`). EDITSET is each pull request's changed-file list. The Stage-4 roster (n=1 at `b1042eec`, 16:06Z) counted only #8651; five siblings opened their pull requests since, and their intersections are new inputs for Stage 9 Phase A6.6 (DEV-8).

### Structural sub-audit

No file is renamed, moved or deleted, so the mover set is empty. `SURFACE(R)` is the version-slot token `Δversion/minor@v5.02`, which five siblings share — a Tier-S version edge, serialized at the atomic claim (CHEAP).

---

## Risk Register

| ID | Risk | Sev | Owner | Mitigation |
|---|---|---|---|---|
| R1 | Probes 3–5 read concurrent spend as this release's (≥5 live hubs; the meter is account-level) | HIGH | operator | D-ProbeWindow (A) with the other hubs paused; a no-activity control of equal length (PA-014). Fallback: label the readings confounded and never record them as results |
| R2 | #8041 sits on the critical path through the window and holds the single release PR | MED | operator | accepted at the scope-lock (PA-007): the PR waits for the window |
| R3 | Schema-bump class for the changed meaning of `session.tokens` | — | — | **Resolved:** MAJOR `2.0.0`, the exemption not claimed (PA-008); the pre-fix store preserved once (PA-009) |
| R4 | Downstream figures drop about 2–3× after the fix: estimate-usage medians, the quota-budget § 5.2 FinOps substrate, comparables | MED | Stage-6 spoke (#7937) | name the consumers in the schema note; route the quota-budget impact to #7536's owner (out of scope) |
| R5 | Several slices share extractor files, fixtures, SKILL.md, the allowlist, the smoke workflow and one package | MED | hub | P0; a fixture subdirectory per card; one rebuild at beat 7; the pre-merge freshness gate |
| R6 | SKILL.md `version:` and the claimed number carry the provisional `v5.02` while five siblings compute the same slot (ms#438 and four more) | LOW | beat-7 spoke and the Stage-12 executor | stamp at beat 7 after an allocator dry-run; re-run at the Stage-12 pre-merge freeness check, and restamp and rebuild on the branch if the slot moved |
| R7 | ADR numbers collide: `--next-free` reads 230, which #8651 holds in `core/ADRs/` and #8811 holds in `release/ADRs/` on their branches | LOW | Stage-12 executor | number the files at authorship from `--next-free`; cite by slug token; `--detect` and `--stamp` at Stage 12; regenerate the index |
| R8 | #7943 edits a hot pair (the close-out script and its stage spec), and this release's own Stage 13 is the first run of the new step | MED | Stage-6 spoke (#7943) | plan at the base; a minimal hook-call diff; Stage-9 A6.5 divergence re-check; fixture coverage before the first live run |
| R9 | #7943's data home depends on placement-rules-and-adr, and AC-3 cannot pass on the legacy tree | MED | operator | D-DataHome (A): only beat 5b waits on that milestone; fallback (B) if it has not merged by Stage 9 |
| R10 | The ranker's output re-exposes transcript text through Mode C items on the public repository | HIGH | Stage-6 spoke (#7945) | CD-1 to CD-4, privacy controls first (PA-016); the report stays under the analysis token; Mode C items are abstracted |
| R11 | #7938's population is unstable (0.1–85 % by window) | LOW | Stage-6 spoke (#7938) | characterized by spawn class and harness build at Stage 5 (#8714) |
| R12 | Probes 7 and 1 in the deployed configuration would write floored or live surfaces | MED | hub (#7935) | an isolated configuration root; where a sealed session needs an auth token, the operator runs it and the agent never requests the token |
| R13 | The milestone could close before #8051 creates MS-1 or records its deferral | MED | hub (Procedure 7) | the close precondition in § Delivery Strategy |
| R14 | The G-PL5 title guard misfires on real cards titled "Stage N …" | LOW | hub | absorbed at Stage 4; held as a filing-step candidate |
| R15 | Rollback: the store semantics change, an ADR renumber can leave a gap, Stage 13 writes local rows | MED | operator | § Rollback Strategy |
| R16 | Cross-release file overlap measured at Commit 0: three siblings edit files beat 1 and beats 5–6 append to (the configuration schema and catalog, the gate-efficacy standard, the allowlist, the smoke workflow, the release ADR index) | MED | hub (Stage 9 A6.6) and the Stage-12 executor | append-pattern edits; whichever merges later rebases over the earlier rows; Stage 9 re-measures the roster before GO |
| R17 | The first calibration revisit (beat 1R) may find zero eligible clean pairs: probe readings vary the model tier or call the advisor by design, and a clean pair needs readings at least two points apart | LOW | beat-1R spoke | FM-1's eligibility rule; a revisit line that records zero eligible pairs is the expected honest outcome, and the seed values stand |

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#7937 × #7938 on `core/skills/finops-usage-extractor/scripts/extract-usage.sh`):** one per-response aggregation carries both behaviours: a response spanning several transcript lines is counted once, and the same record is flagged incomplete when no line carries its final output count. *Method:* `grep -c -F "CIAC-1 per-response-incomplete" core/skills/finops-usage-extractor/scripts/extract-usage.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.* The arm's behaviour is graded by the finops-selftest CI job.
- [ ] **CIAC-2 (#7937 × #7938 × #7939 on `packages/finops-usage-extractor.skill`):** the package is rebuilt once, after the last extractor slice, and its content hash matches a rebuild of the final source. *Method:* declared, verification deferred to .github/workflows/skill-package-freshness.yml (the pre-merge content-freshness job). *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#7940 × #7943 on `release/tools/compute-release-velocity.sh`):** the cost row reports weekly points at both ends of the cache-read-weight bracket recorded in the cost-unit ADR, computed from per-response totals. *Method:* `grep -c -F "CIAC-3 both-bracket-ends" release/tools/compute-release-velocity.sh` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.* The arm's behaviour is graded by the release-tools self-test discovery job.
- [ ] **CIAC-4 (#7935 × #8041 on the model-use ADR):** every option the ADR rejects as infeasible cites a probe result recorded on #7935, and no option is assessed against an unrecorded or confounded reading. *Method:* declared, verification deferred to #8041 AC-2 and #7935 AC-1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#7940 × #7945 on the ranking report):** the ranker states cost in the cost-unit ADR's unit (weekly points at both bracket ends), not in a parallel unit. *Method:* declared, verification deferred to #7945 AC-1 and #7940 AC-1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-6 (#7943 × #7945 on the non-tracked data homes):** both new local outputs resolve through a registered operator-instance token to an in-repo git-ignored path, and neither lands under the legacy instance tree. *Method:* declared, verification deferred to #7943 AC-3 and #7945 AC-3. *Graded at Stage 9 QC3.5 on the merged PR.*

The CIAC lint on the Stage-4 draft read `declared=6 parsed=6 clean=2 declared-deferral=4 flagged=0`; it is re-read on this committed file at Stage 6 A1 (§ Verification Evidence) and at Stage 9 A3.6.

---

## Verification Plan

**AC baseline:** #7935 = **4**, #7937 = **4**, #7938 = **2**, #7939 = **4**, #7940 = **3**, #7943 = **4**, #7945 = **4**, #8041 = **4** — **29** criteria, read at `b1042eec` on 2026-11-05. The Stage-4 baseline read 28 at `ac96b3ea`; #7939 gained AC-4 (the boundary-second fixture) at the Stage-4 gate, so this baseline moves to 29 (DEV-4). #7943's AC-1 was amended in place at the scope-lock (thinking counted inside output) without changing its count.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #7935 | AC-1 | declared, verification deferred to Stage 8 (reads the probe-result comments on #7935) | seven probes, each with method, observed result, and the lever it confirms or retires |
| #7935 | AC-2 | declared, verification deferred to Stage 8 (probe 3 and 4 comments) | a no-activity control reading over an equal interval, inside the D-ProbeWindow window |
| #7935 | AC-3 | declared, verification deferred to Stage 8 | windows moved per model and per advisor call; availability for hub, Agent-tool spoke, chip and Workflow agent |
| #7935 | AC-4 | declared, verification deferred to Stage 8 (reads #7942, #8041 and #7936) | each target carries the cross-link |
| #7937 | AC-1 | declared, verification deferred to the finops-selftest job and a Stage-7 re-run of the Phase-A0 G-PL4 repro | store equals the per-response sum on 4/4 fields (baseline: equals the per-line sum, ratio 2.50–2.91) |
| #7937 | AC-2 | `grep -c -F "three-block" core/skills/finops-usage-extractor/scripts/extract-usage.sh` at least 1 | self-test arm present; finops-selftest grades the behaviour |
| #7937 | AC-3 | `grep -c -F "partial-output" core/skills/finops-usage-extractor/scripts/extract-usage.sh` at least 1 | arm present |
| #7937 | AC-4 | `grep -c -F "2.33" core/schemas/finops-usage-store-schema.md` at least 1 [READER-GRADED — schema_version advanced past 1.2.0 in frontmatter and meta] | measured corpus factors cited; version bumped |
| #7938 | AC-1 | `grep -c -F "incomplete" core/skills/finops-usage-extractor/scripts/extract-usage.sh` at least 1 | flag present (baseline 0; same-file control `toksum` → 5) |
| #7938 | AC-2 | `grep -c -F "no-final-output" core/skills/finops-usage-extractor/scripts/extract-usage.sh` at least 1 | arm present |
| #7939 | AC-1 | declared, verification deferred to a Stage-7 re-run of the Phase-A0 G-PL4 repro (report over a one-session real store) | renders (baseline: exit 3) |
| #7939 | AC-2 | `grep -c -E "started_utc.:.[0-9T:-]+[.][0-9]+Z" core/skills/finops-usage-extractor/test-fixtures/report/usage.jsonl` at least 1 | at least 1 fractional-seconds record (baseline 0) |
| #7939 | AC-3 | `grep -c -F "malformed session.started_utc" core/skills/finops-usage-extractor/scripts/report-usage.sh` at least 1 | guard kept; negative arm in the report self-test |
| #7939 | AC-4 | `grep -c -F "SM-6b" core/skills/finops-usage-extractor/scripts/report-usage.sh` at least 1 | the boundary-second assertion is present (baseline 0); finops-selftest grades the behaviour |
| #7940 | AC-1 | declared, verification deferred to Stage 8 (reads the cost-unit ADR at the final head) | unit, per-response counting, four graph elements, bracket 0.0075–0.10 |
| #7940 | AC-2 | declared, verification deferred to Stage 8 | three unit errors and the revisit rule named |
| #7940 | AC-3 | declared, verification deferred to Stage 8 | #7536, #7854 and #7943 named as consumers |
| #7943 | AC-1 | declared, verification deferred to the velocity-tool self-test (release-tools discovery job) and this release's own Stage-13 row | one row with every listed field, at both bracket ends; thinking counted inside output |
| #7943 | AC-2 | `grep -c -F "cost-row" release/tools/compute-release-velocity.sh` at least 1 | the extended tool carries the mode |
| #7943 | AC-3 | declared, verification deferred to Stage 7 (git check-ignore on the resolved row path) | exit 0 (Phase A0: legacy tree 128 · analysis/ 0 · local-state/ 1 at the pin · tracked control 1) |
| #7943 | AC-4 | `grep -c -F "killed-spoke" release/tools/compute-release-velocity.sh` at least 1 | arm present |
| #7945 | AC-1 | `test -f core/skills/finops-usage-extractor/scripts/rank-command-templates.sh` | file exists |
| #7945 | AC-2 | declared, verification deferred to the ranker self-test (finops-selftest job) and Stage 8 | occurrences, stages, cost and AS rung for each candidate |
| #7945 | AC-3 | declared, verification deferred to Stage 8 (the report under the analysis token; the Mode C records) | derived figures only; items abstracted |
| #7945 | AC-4 | `grep -c -F "near-miss" core/skills/finops-usage-extractor/scripts/rank-command-templates.sh` at least 1 | control and near-miss arms present |
| #8041 | AC-1 | declared, verification deferred to Stage 8 (reads the model-use ADR against the probes recorded on #7935) | each option assessed against probes 3, 4 and 6 |
| #8041 | AC-2 | declared, verification deferred to Stage 8 | every ruled-out option cites its probe |
| #8041 | AC-3 | declared, verification deferred to Stage 8 | roles, parity arms, milestone and pass rule for each surviving change |
| #8041 | AC-4 | `git diff --name-only origin/main...HEAD -- core/config/allowlists/agents-model-overrides.txt` expect 0 [READER-GRADED — the spoke_runtime section of core/config/platform-config.toml.template, extracted at the merge-base and at HEAD by the section compare #8719 specifies, reads identical; the template itself changes in this release, because beat 1 appends the cost_unit section] | 0 changed paths on the overrides allowlist and an identical section · control: the same scope instrument with pathspec release/releases/plans → ≥1 once Commit 0 lands |

`ac_baseline: { #7935: 4, #7937: 4, #7938: 2, #7939: 4, #7940: 3, #7943: 4, #7945: 4, #8041: 4, total: 29, read_at: b1042eec }`

**Null and threshold rows carry a same-target control** (AC-Binding Limb 2): #7938 AC-1 names its same-file control; #8041 AC-4's scope assertion names the plan-path control on the same instrument, and its section compare carries the sensitivity and specificity arms #8719 specifies (a changed `chip_model` value makes the compare differ; a new section placed after `[spoke_runtime]` leaves it identical).

**#8041 AC-4 narrowing (PA-012).** The Stage-4 method was a whole-file diff of the configuration template and the overrides allowlist, expecting 0. Under D-Home (A) beat 1 adds the `[cost_unit]` section to the template, so that method would fail on a conforming release. The approved narrowing compares the `[spoke_runtime]` section only, at the merge-base rather than `origin/main` (at Stage 8 `origin/main` may carry another release's edit to that section), and keeps the whole-file diff for the overrides allowlist. The criterion's text on #8041 is unchanged; only its method moves.

### Release-Level Verification

These checks use tools or shapes outside the plan verifier's runnable set, so each is declared deferred to the Stage-6 C4 run that executes it; commands and observed results land in § Verification Evidence as each beat lands.

| Check | Verification Method | Expected |
|---|---|---|
| ADR index freshness | [DEFERRED — generate-adr-index.py with --write then --verify at Stage 6 C4 on beats 1 and 8, and at Stage 12 after the stamp] | COUNT 0 |
| ADR number integrity and durability | [DEFERRED — check-adr-numbers.py and check-adr-durability.py at Stage 6 C4 on beats 1 and 8; the CI jobs on the PR] | pass; warn-mode durability findings read |
| Configuration surface | [DEFERRED — deploy.sh Check 33 parse rule and the section-aware reader over the template at Stage 6 C4 on beat 1] | parse-clean; the cost_unit keys resolve |
| FinOps self-tests | [DEFERRED — extract-usage, rollup-attribution, report-usage, convert-usage and the ranker self-tests at Stage 6 C4 per beat; the finops-selftest job] | pass |
| Velocity tool and close-out self-tests | [DEFERRED — compute-release-velocity.sh and automated-closeout.sh self-tests at Stage 6 C4 on beats 5a and 5b] | pass |
| Doc-link integrity | [DEFERRED — the doc-link checker over each beat's edited docs, with the plan-depth lint on this plan, at Stage 6 C4] | no new broken link |
| Skill-roster totals on added lines | [DEFERRED — check-skill-count-imp.py over each beat's added lines before each push] | clean |
| Package consequence | [DEFERRED — the package resolver reading each changed path on STDIN, at Stage 6 C4 per beat; one rebuild at beat 7] | the FinOps package is the only rostered package staled; rebuilt once |
| CIAC authoring lint | [DEFERRED — the plan verifier's CIAC lint over this file, at Stage 6 A1 and Stage 9 A3.6] | declared=6 parsed=6 flagged=0 |

---

## Delivery Strategy

| Aspect | Decision |
|---|---|
| Implementation approach | Sequential (P0 serial; contention-driven) |
| Commit strategy | Commit 0 (this plan), then one or more commits per beat, each pushed on landing (Write-Early); messages carry the `release-usage-measured-right:` or `release(release-usage-measured-right):` prefix and a reference-only trailing issue number |
| Review approach | Single release PR, draft until the Stage-9 Phase A8 transition |
| Package | Rebuilt once, at beat 7, in the release PR; the pre-merge `skill-package-freshness` gate asserts it |
| Stage 12 | Atomic version claim (minor); `python3 release/tools/renumber-adr.py --detect`, then `--stamp`, for the two ADRs; `deploy.sh --deploy` for the FinOps skill |
| Stage 13 | This release's own close-out writes its cost row (the Success Indicator) |
| Close precondition (Procedure 7) | The milestone stays open until #8051 has created MS-1 or recorded its deferral |
| Card closure | Each card is marked as closed at Stage 13 through the release PR's Issue References block |

The PR body is parser-clean: each card is named in the dedicated Issue References block; no close-family verb precedes an issue number anywhere else.

---

## Rollback Strategy

| Scope | Method | Complexity |
|---|---|---|
| Whole release | Revert the release-PR merge, then run `extract-usage.sh --rebuild`; the store is a derived cache, so the prior counting returns, and the pre-fix store preserved at the unit boundary stays on disk | MODERATE / MEDIUM |
| An ADR | A merged ADR is superseded, never deleted. A revert made after `--stamp` must also revert the stamp or renumber commit, or the ADR-number integrity job reports a gap | MODERATE / HIGH |
| A calibrated value | A one-line edit to the `[cost_unit]` section (the numeric home); figures computed under the old value are re-expressed from their stored per-response totals | CHEAP / HIGH |
| Cost rows already written | Local data that keep per-response totals by type, so they can be re-expressed (#7940 Reversibility) | CHEAP / HIGH |
| Version tag | Retained and recorded per Tag Retention; never deleted | — |

Rollback infeasibility: none; every step is a commit, a store rebuild or a local value edit.

---

## Quota Budget

**Verdict:** WARN, on basis `UNSTATED` (conservative default, per `quota-budget-protocol.md` Checkpoint A), transcribed from Stage 4 [ASSUMPTION – CONFIRM].
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 8 (ran) · Stage 7: 6 · Stage 8: 8 (Stage 6 is serial).
**Per-spoke cost estimate:** size-bucket ordinal band (heuristic). Telemetry medians are not used, because the FinOps substrate over-counts 2–3× until #7937 lands.
**Assumed/stated remaining usage-window envelope:** UNSTATED; several hubs draw on the account.
**Estimated cumulative draw % (worst parallel batch):** not synthesized (§ 6.1). The worst batch is Stage 8, at 8 spokes.
**Routing:** WARN → window-aware launch timing plus a split batch; Stage 8 runs in two waves.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API axis, combined DEFER-dominant (§ 4.3b); Checkpoint A stays usage-window-only (§ 3.1). The bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**`novel`**, with a recorded override of cross-cutting trigger (c) (PA-002). **Triggers that fire:** novel (a) — #7945 adds a script, #7943 adds the conversion script, and two ADRs are new decision records; novel (b) — this plan carries D-class decisions; novel (c) — two Stage-5 ADRs; **cross-cutting (c)** — three in-bundle compositional edges (#7937 → #7938, #7937 → #7943, #7935 → #8041). **Triggers that do not fire:** cross-cutting (a), because one `pipeline/stage-*.md` file changes (`stage-13-close.md`); cross-cutting (b), because none of the six rule-defining surfaces change; hotfix, because no deployed-release defect is repaired. **Size:** ≈ 42 raw / ≈ 48 effective points against the 25 ceiling, accepted over band at the scope-lock (PA-007). **Posture:** engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.

---

## Release Outcome Statement

Transcribed verbatim from the milestone description at Engineering Commit 0.

**AFTER** — Each release's close-out records what the release cost, by stage, role and token type. Usage is counted once per API response and stated in one calibrated unit (weekly points of one account, at both ends of the cache-read-weight bracket), and the usage report runs over real stores. The seven harness and meter behaviours the thrust's levers rest on are measured and recorded, including which allowance each model and the advisor draw and which spawn classes can call the advisor. The cost unit and the model-use policy are decided in ADRs grounded on those results, and the commands agents keep retyping are ranked by cost as promotion candidates.

**BEFORE** — The usage store over-counts API responses 1.8–3.4× and silently under-counts spoke output. The usage report rejects every real store. No release records its own cost, and efficiency claims mix three incompatible units. The token levers and any model-use change rest on untested harness behaviour.

**Actor(s):** Stage-6 engineering spokes (the extractor, the report, the cost row and the ranking script); a probe run in an otherwise idle account window (#7935 probes 3–5); spokes authoring the two ADRs; the operator at Stage 9 and at the probe window.

**Success Indicator:** At Stage 13 this release writes its own per-release cost row, with per-response counts. #7935 carries seven recorded probe results. #7940 and #8041 are authored on `main`, with #8041 assessing each option against the probes. The successor card #8051 has created MS-1, or recorded its deferral, before this milestone closes.

**Limb owners:** per-release cost row at close-out → #7943 · usage counted once per API response, incomplete responses flagged → #7937, #7938 · one calibrated unit at both bracket ends → #7940 · usage report runs over real stores → #7939 · seven harness and meter behaviours measured and recorded → #7935 · cost-unit and model-use ADRs grounded on the results → #7940, #8041 · retyped commands ranked as promotion candidates → #7945

---

## Operational Deployment Manifest

| Surface | Propagation | Mechanism |
|---|---|---|
| `core/skills/finops-usage-extractor/` (scripts, fixtures, references, SKILL.md) | the installed skill copy | `deploy.sh --deploy finops-usage-extractor` at Stage 12 (S-2 copy), after the beat-7 package rebuild |
| `packages/finops-usage-extractor.skill` and its sidecar | the distribution artifact | committed in the release PR (beat 7) |
| The two ADRs, the release ADR index, the standards, the schemas, the stage spec, the docs | repository-only | none required |
| `core/config/platform-config.toml.template` | read in place from the clone (no installed copy) | none required; an operator's own calibration is a Track-B individual-rung value |
| The velocity tool, the close-out pair, `lib-instance-path.sh` | run from the repository at check and close time | none required |

**`deliverable_state: deployed-copy-synced`** — the FinOps skill reaches it when its installed copy is synced at Stage 12; every other deliverable is repository-only, which this state admits ("or the release declares no propagation target").

### Schema Migrations

- **FinOps usage store schema `1.2.0` → `2.0.0` (MAJOR, PA-008).** The counting unit changes from per transcript line to once per API response within a transcript file. A store written under another schema version is never rebuilt over in place: it is preserved once at the unit boundary (PA-009), then rebuilt by `extract-usage.sh --rebuild`. Consumers that pin `>= 1.2.0` are named in the schema note (R4).
- **Platform configuration:** additive — a new `[cost_unit]` section; no existing key changes.

Enumerated over data-file formats, the store schema, the platform configuration schema, the pipeline-event-log schema and the release-velocity row shape; the two above are the only changes.

### Memory Evictions

N/A — enumerated over memory eviction, memory re-point and archive disposition; no codification card in this release is tied to an auto-memory entry, so nothing is evicted.

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

Run by the Stage-6 spoke on #8724 after this file was written and before it was committed, on base `b1042eec`.

| Check | Command | Observed |
|---|---|---|
| Stamp manifest (step 3b) | `bash release/tools/claim-version.sh --verify-stamp release-usage-measured-right` | exit 0 — "verify-stamp OK … carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". The file carries exactly 1 literal placeholder (python count), in the Header `**Version**` cell |
| CIAC authoring lint (A1) | `bash release/tools/verify-release-plan.sh --ciac-lint release/releases/plans/release-usage-measured-right_RELEASE_PLAN.md` | exit 0 — `CIAC-LINT-SUMMARY declared=6 parsed=6 clean=2 declared-deferral=4 flagged=0`; CIAC-1 and CIAC-3 CLEAN, CIAC-2 and CIAC-4 to CIAC-6 DECLARED. G4-06 holds on the committed plan, matching the Stage-4 record |
| Full verifier (RED arm), with the Stage-4 comment supplied for the provenance delta | `bash release/tools/verify-release-plan.sh --stage4-comment <the Stage-4 comment, saved> release/releases/plans/release-usage-measured-right_RELEASE_PLAN.md` | exit 3 — **6 PASS / 19 FAIL / 29 SKIP / 1 UNRUNNABLE / 1 ERROR over 56 records** (38 per-issue, 6 cross-issue, 12 always-on). The 10 runnable per-issue rows that read FAIL do so against the baseline tree — each is its row's sensitivity arm for a later GREEN — and #7939 AC-3 reads PASS (the guard exists at the base and is kept). CIAC-1 and CIAC-3 read 0 (wanted at least 1), likewise. #8041 AC-4 reads UNRUNNABLE, the outcome a designated PASS takes beside a reader-graded limb. #7945 AC-4 reads ERROR because its input file does not exist until beat 6 (count unreadable, not zero). `FCM-COVERAGE` PASS: `declared=52 interpreted=52 obligations=7 excluded=12 conditional=0 uninterpreted=0 pathless=0 prose_led=0`; FCM-1 to FCM-7 FAIL pre-commit (this file delivers at this commit; the other six ADDs at beats 1, 2, 5a, 6 and 8). `PROV-PRESENCE`, `PROV-GRAMMAR` (Form X) and `PROV-DELTA` (`prov-no-loss`, 4 comment elements, all present) PASS |
| Doc links and plan depth | `python3 core/deploy/tools/check-doc-links.py --target-paths release/releases/plans/release-usage-measured-right_RELEASE_PLAN.md --require-targets`; `python3 release/tools/check-release-links.py`, bare and with `--files <this file> --check-anchors --plan-depth-lint` | doc links exit 0, no findings; release links exit 0 and plan depth exit 0, 0 findings. The file carries 0 markdown link sequences by construction (a count of the closing-bracket, opening-parenthesis pair), so neither reader has a link to resolve, and no relative link can break at the Stage-12 rename |
| Skill-roster totals | `python3 core/deploy/tools/check-skill-count-imp.py --files release/releases/plans/release-usage-measured-right_RELEASE_PLAN.md --mode both` | exit 0, no finding. The Stage-4 Agent-Editability Read's literal arming-key census is not transcribed as a count (§ Agent-Editability Read names the one unarmed skill instead) |
| Identity strings, host URLs, link sequences, close-family keywords, citation tokens | a python line scan of this file for the operator handle and name, a home path, an email address, a raw host URL, a markdown link sequence, a close-family verb followed by an issue number, and the double-brace version and ADR tokens | 0 in every class, except exactly 1 version placeholder (the Header cell) and 0 ADR tokens. Control: one constructed line carrying one of each fires every class once |

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **The Stage-4 conditional rows are resolved, and the ledger's rows are added.** Promoted: `usage.expected.json` (fixture-multiline), `rollup-attribution.sh` (schema-major), `reporting-contract.md` (contract-states-unit), the four ranker rows (ranker-in-skill), the promotion framework (framework-names-detector), the velocity standard (row-schema-home) and the four home rows (home-before-ms428, owed under D-DataHome A too). Not promoted and moved to the non-scope block: `estimate-usage.sh` (schema-major fired, but the file needs no edit) and `report.expected.json` (report-output-shift did not fire). Added: the rows listed under § File Change Matrix → Rows added at this commit. Remaining conditional: the attribution-convention note (resolves in beat 2's brief) and the renumber log (written by the tool only on a move) | scope-lock PA-007 (the adjustment ledger); #8713, #8714, #8715, #8716, #8717, #8718, #8719 | **APPLIED** — § File Change Matrix |
| **DEV-2** | **D-Home (A): the numeric home is #7940's.** The `[cost_unit]` section with CD-2's per-model axis, its schema rows and its catalog section land at beat 1 rather than in #7943's beat 5a, so `core/config/platform-config.toml.template` moves from Read-only to EDIT and #7940's Stage-7 cell moves from SKIP to APPLY. The single conversion stays #7943's (`convert-usage.sh`, beat 5a) | scope-lock PA-010 | **APPLIED** — § File Change Matrix, § Stage Applicability Matrix, § Implementation Sequence |
| **DEV-3** | **#8041 AC-4's method narrowed** to a section compare of `[spoke_runtime]` at the merge-base, keeping the whole-file diff for the overrides allowlist; the criterion's text is unchanged | scope-lock PA-012 (the Tier-2 scope change raised by #7940's design) | **APPLIED** — § Verification Plan |
| **DEV-4** | **#7939 AC-4 row added and the AC baseline moved from 28 to 29.** Method `grep -c -F "SM-6b"` on `report-usage.sh`, at least 1 | #8715 REC-2; scope-lock PA-007 | **APPLIED** — § Verification Plan |
| **DEV-5** | **The Implementation Sequence gains beat 1R and reorders beat 6.** Beat 1R (the first calibration revisit after window W, over eligible pairs only, re-grounding the cost-unit ADR while it is Proposed) follows from D-Revisit (A) with #8809 PR-1 and FM-1. Beat 6 (#7945) starts after beat 5a, because the ranker calls #7943's single conversion. Beat 5a starts after beats 1, 2 and 3 (#8717). The soft edge #7935 → #7940 beat 1R is added to the Dependency Graph (#8712 R-5) | scope-lock PA-011; #8716; #8717; #8712 | **APPLIED** — § Implementation Sequence, § Dependency Graph |
| **DEV-6** | **Over-band acceptance recorded:** ≈ 42 raw / ≈ 48 effective points against the 25 ceiling, the milestone kept whole as MS-0 of #7934 | scope-lock PA-007 | **RECORDED** — § Decision Record, § Release Class declaration |
| **DEV-7** | **Card-level scope-lock renderings carried into this file:** #7937 MAJOR `2.0.0` and preserve-once (PA-008, PA-009; R3 resolved), #7943 no thinking leaf and the `/local-state/telemetry/` home (PA-013), #7935's window budget (PA-014), #8041's frame decisions (PA-015), #7945's threshold and privacy-first order (PA-016) | scope-lock PA-008 to PA-016 | **RECORDED** — § Decision Record, § Card change specifications |
| **DEV-8** | **The In-Flight Release Roster is re-measured at Commit 0:** n=6 siblings (the Stage-4 roster counted 1). Four of them edit files in this matrix, and #8811 holds `ADR-230` in `release/ADRs/` on its branch. Recorded as a pinned measurement with no verdict; R7 and R16 carry the consequences | Stage-6 A1 (this commit) | **RECORDED** — § Cross-PR Overlap Audit, § Contention Map, § Risk Register |
| **DEV-9** | **Card bodies already carry the approved criterion edits:** #7939 AC-4 (added at the Stage-4 gate) and #7943 AC-1 (thinking counted inside output, at the scope-lock); read back at this commit. #8041's criterion text needs no edit; its method narrows here | Stage-4 Decision Recorded; scope-lock PA-012, PA-013 | **RECORDED** — read back at `b1042eec` |

---

## Issue References

- **#7940** — the cost-unit card: the decision record for weekly points of one account, counted once per API response and attributed to the release run graph, with its numeric home. Mark as closed at Stage 13.
- **#7937** — per-response counting in the FinOps extractor, with the MAJOR store-schema bump. Mark as closed at Stage 13.
- **#7938** — the incomplete-response flag. Mark as closed at Stage 13.
- **#7939** — the usage report accepts fractional-second timestamps and buckets boundary seconds correctly. Mark as closed at Stage 13.
- **#7943** — the per-release cost row at Stage-13 close-out. Mark as closed at Stage 13.
- **#7945** — the command-template cost ranking. Mark as closed at Stage 13.
- **#7935** — the seven harness and meter probes. Mark as closed at Stage 13.
- **#8041** — the model-use policy decision record. Mark as closed at Stage 13.
- **#8662** — the Stage-4 planning sub-task (plan, plan gate, scope-lock). **#8712–#8719** — the Stage-5 sub-tasks. **#8799 · #8800 · #8801 · #8809 · #8810 · #8812 · #8813 · #8819** — the Phase A6.5 adversarial reviews. **#8724** — the Stage-6 sub-task for #7940 (this commit).
- **#7934** — the token-efficiency thrust (epic). **#8051** — the successor card that composes MS-1. **#7854** — the outcome check whose criteria use the unit. **#7536** — the weekly-allowance axis that adopts the unit. **#7942 · #7936 · #7950 · #1494 · #8049** — downstream and related cards named in the graph and the specifications.

---
title: Release Plan — release-usage-measured-right (Usage measured right)
type: release-plan
plan_type: release
status: ACTIVE
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
| **Status** | In progress — Stage 6 Engineering; Engineering Commit 0, beat 1 (#7940), beat 2 (#7937), beat 3 (#7938), beat 4 (#7939) and beat 5a (#7943) landed; beat 5b's registration rows (#7943) landed under the operator's D-5b = B (DEV-36), and its default home, close-out phase and stage text stay held (DEV-35); beat 6 (#7945) landed, the command-template ranker with the Collective Review's counter-designs (DEV-41 to DEV-47); beat 7 (the package rebuild and the `version:` stamp) is next |
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
core/standards/finops-attribution-convention.md  EDIT
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
core/standards/instance-data-placement-standard.md  EDIT
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
- #7937: `extract-usage.sh`, the per-response fixtures, `usage.expected.json`, the fixture README, the store schema, `rollup-attribution.sh`, the reporting contract's § 2, the SKILL.md note, `.gitignore`, and the attribution convention (its conditional note accepted at beat 2, DEV-17).
- #7938: `extract-usage.sh`, the store schema, a per-response fixture, `usage.expected.json`, the fixture README.
- #7939: `report-usage.sh`, the report fixture, the report fixture README, the reporting contract's §§ 1, 6 and 8.
- #7943: `convert-usage.sh`, the allowlist, the smoke workflow, SKILL.md, `core/README.md`, `docs/module-apis.md`, the velocity standard, the velocity tool, and at beat 5b `.gitignore`, `lib-instance-path.sh`, `operator.toml.template`, `operator-toml-schema.json`, `depersonalization-spec.md`, the placement standard's surface register (DEV-37), the close-out pair and `test_lib_instance_path.sh`.
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
| #7937 | the extractor, fixtures, schema, rollup, contract, SKILL.md, `.gitignore`, the attribution convention | ∅ | SKILL.md and the contract: conjunct 1 true, **conjunct 2 false** | `unconstrained` | ordinary Engineering spoke; pmo-skill-editor discipline still applies by conduct (`Skill-Editor-Audit-Trail:` trailer) |
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
| `lib-instance-path.sh` · `test_lib_instance_path.sh` | #7945 (beat 6), #7943 (beat 5b) | append-pattern (distinct functions and cases) | serialize; beat 5b landed first (DEV-36), so beat 6 appends after its resolver and its test case |
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
| #7943 | AC-3 | declared, verification deferred to Stage 7 (git check-ignore -q local-state/telemetry/release-cost/release-usage-measured-right.json, run from the release worktree root against the branch's ignore rules; Stage 13 re-runs it in the main checkout after the post-merge sync) | exit 0 (Phase A0: legacy tree 128 · analysis/ 0 · local-state/ 1 at the pin · tracked control 1; beat 5b: 0 in the release worktree) |
| #7943 | AC-4 | `grep -c -F "killed-spoke" release/tools/compute-release-velocity.sh` at least 1 | arm present |
| #7945 | AC-1 | `test -f core/skills/finops-usage-extractor/scripts/rank-command-templates.sh` | file exists |
| #7945 | AC-2 | declared, verification deferred to the ranker self-test (finops-selftest job) and Stage 8 | occurrences, stages, cost and AS rung for each candidate |
| #7945 | AC-3 | declared, verification deferred to Stage 8 (one live run: its report folder resolves under the analysis token and `git check-ignore` reads 0; its `## Routing outcomes` table holds one row per Mode C record, each carrying the verdict Mode C returned; the self-test's leak and signals arms, run by the finops-selftest job) | derived figures only; every record routed through Mode C and held below the filing threshold, so a pending row, a missing row or another verdict fails; the operator promotes (AC-3 as amended, DEV-41) |
| #7945 | AC-4 | `grep -c -F "near-miss" core/skills/finops-usage-extractor/scripts/rank-command-templates.sh` at least 1 | control and near-miss arms present |
| #8041 | AC-1 | declared, verification deferred to Stage 8 (reads the model-use ADR against the probes recorded on #7935) | each option assessed against probes 3, 4 and 6 |
| #8041 | AC-2 | declared, verification deferred to Stage 8 | every ruled-out option cites its probe |
| #8041 | AC-3 | declared, verification deferred to Stage 8 | roles, parity arms, milestone and pass rule for each surviving change |
| #8041 | AC-4 | `git diff --name-only origin/main...HEAD -- core/config/allowlists/agents-model-overrides.txt` expect 0 [READER-GRADED — the spoke_runtime section of core/config/platform-config.toml.template, extracted at the merge-base and at HEAD by the section compare #8719 specifies, reads identical; the template itself changes in this release, because beat 1 appends the cost_unit section] | 0 changed paths on the overrides allowlist and an identical section · control: the same scope instrument with pathspec release/releases/plans → ≥1 once Commit 0 lands |

`ac_baseline: { #7935: 4, #7937: 4, #7938: 2, #7939: 4, #7940: 3, #7943: 4, #7945: 4, #8041: 4, total: 29, read_at: b1042eec }`

**Null and threshold rows carry a same-target control** (AC-Binding Limb 2): #7938 AC-1 names its same-file control; #8041 AC-4's scope assertion names the plan-path control on the same instrument, and its section compare carries the sensitivity and specificity arms #8719 specifies (a changed `chip_model` value makes the compare differ; a new section placed after `[spoke_runtime]` leaves it identical).

**#8041 AC-4 narrowing (PA-012).** The Stage-4 method was a whole-file diff of the configuration template and the overrides allowlist, expecting 0. Under D-Home (A) beat 1 adds the `[cost_unit]` section to the template, so that method would fail on a conforming release. The approved narrowing compares the `[spoke_runtime]` section only, at the merge-base rather than `origin/main` (at Stage 8 `origin/main` may carry another release's edit to that section), and keeps the whole-file diff for the overrides allowlist. The criterion's text on #8041 is unchanged; only its method moves.

### G-CL10 arm (i) — prose rows this release adds

Beat 1 adds one register row whose Surface leads with `prose`: the cost unit's calibration-revisit rule in `core/standards/gate-efficacy-standard.md` § Gate-coverage register, a class-3-O named gap. It carries `**Population:** cost-unit-calibration-revisits` (instrumented runs recorded against the cost unit since its seed line, each conforming when the row carries a revisit line dated on or after it; a record-census probe; threshold 100%), and this file's § Verification Evidence carries that population's record at close. Window W is the release's own instrumented run, so under D-Revisit (A) beat 1R appends the population's first member; a revisit that pools zero eligible pairs still appends its line and conforms.

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
| The velocity tool, the close-out pair | run from the repository at check and close time | none required |
| `core/deploy/lib-instance-path.sh` | sourced from the repository by the deploy and release tools, and published byte-exact into the deployed hook tier as a co-deployed primitive | **(a) propagate**, the hook-bundle convention's default: a full `./update.sh` (its Phase 5c hook refresh) or the operator's targeted `docs/scripts/setup-workspace.sh --refresh-hooks` refreshes the hook-tier copy, and deploy Check 79 reports the copy as drifted until then (DEV-40) |

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

### Beat 1 (#7940) — Stage 6 C4

Run by the Stage-6 spoke on #8724 over the beat-1 commit `783048a8` (the cost-unit ADR, the release ADR index, the register row, and the `[cost_unit]` template section, schema rows and catalog section) and re-run where it applies over the follow-up commit that carries this table, which also clarifies two sentences of the ADR (Decision 3: the calibration model needs no per-model entry; Decision 8: how a pair qualifies while no calibration model is named) and adds the matching template comment line.

| Check | Command | Observed |
|---|---|---|
| ADR index freshness | `python3 release/tools/generate-adr-index.py --write`, then `--verify` | 70 rows written; `--verify` → `COUNT 0`. This release adds a record under `release/ADRs/`, so `release/ADRs/README.md` is regenerated, committed and declared EDIT in § File Change Matrix |
| ADR number integrity | `python3 release/tools/check-adr-numbers.py` | PASS — contiguous, no duplicates on this branch. Siblings hold the same number on their own branches (R7); it binds at merge |
| ADR durability | `python3 release/tools/check-adr-durability.py --files release/ADRs/ADR-238-release-graph-cost-unit.md --diff-base origin/main`; `--self-test` | `COUNT 0`; self-test all pass. Sensitivity: the same instrument on the same file with the design's bullet-led `## Status` read R7, `COUNT 1`, before the reflow (DEV-14) |
| Reference placement | `awk '/^## References/{exit} 1' <the ADR> \| grep -c -E '#[0-9]{3,}'` | 0 above the reference block; sensitivity without the cut → 10 |
| #7940 AC-1 probes (Stage 8 grades the criterion) | `grep -c -F '0.0075–0.10'` and `grep -c -E 'node bootstrap\|node loop\|edge payload\|edge wait'` on the ADR | 1 and 4 |
| Issue references | `check-issue-ref-validity.sh --path` over the ADR, the standard, the schema and the catalog | every `#N` resolves in-repo and sits in a reference block; the schema and the standard carry the whole-file marker |
| Configuration surface | a TOML parse of the template; Check 33's parse rule; the `[spoke_runtime]` section compare at the merge-base (#8041 AC-4's method) | 12 sections, `[cost_unit]` 10 keys of the asserted types; 0 non-assignment lines (sensitivity: one seeded malformed line → 1); `[spoke_runtime]` identical, 46 lines each side (sensitivity: a changed `chip_model` → differs; specificity: a new section after it → identical). The section-aware reader idiom over `[cost_unit]` is **NOT-EVALUATED** here — sourcing its library was refused by a hook — and is exercised by the conversion's self-test at beat 5a |
| Runtime suite (selection-map row 5: `core/config/*.template`) | `bash core/deploy/tests/run-install-regression.sh` (sandbox: self) | `INSTALL-REGRESSION: 3392 passed, 0 failed — VERDICT PASS [env: home-account; skipped: 0]`, exit 0, on the beat-1 tree (the follow-up below changes one template comment line only). One `test-run/suite-pass` event emitted for this release (stage 6, actor `spoke:#8724`, payload carrying the counts and the head), read back 0 → 1; the runner's own built-in emission carries no release and is not counted here |
| Plan verifier after beat 1 | `bash release/tools/verify-release-plan.sh --stage4-comment <the Stage-4 comment, saved> <this file>`, range `b1042eec..783048a8` (merge-base) | 8 PASS / 17 FAIL / 29 SKIP / 1 UNRUNNABLE / 1 ERROR over 56 records. FCM-1 (this file) and FCM-2 (the cost-unit ADR; the `NNN` placeholder matched the delivered number) now PASS; `FCM-COVERAGE` PASS with 0 uninterpreted rows. Every remaining FAIL is a later beat's row or ADD; the ERROR and the UNRUNNABLE are unchanged from Commit 0 |
| Citation tokens | `python3 release/tools/renumber-adr.py --stamp` (dry run) | 4 tokens across 3 files would be stamped (the template, the schema row, and the register row with its Version History line), resolved from the on-disk ADR file set |
| Doc links, release links, skill-roster totals | `check-doc-links.py --require-targets` over the five edited docs; `check-release-links.py --check-anchors`; `check-skill-count-imp.py --mode both` | 0 findings each |
| Package consequence | the seven beat paths on STDIN to `build-skill-packages.sh --skills-for-paths` | no rostered package staled; control (a FinOps skill path) → `finops-usage-extractor` |
| Identity strings, host URLs, link sequences, close-family keywords | a python line scan of the ADR and of every added line | 0 identity strings in either; 2 link sequences in added lines, both pre-existing in kind (the schema § 6 line's existing link and the generated index row) |

### Beat 2 (#7937) — Stage 6 C4

Run by the Stage-6 spoke on #8721 over the beat-2 commits `9722b9c6` (the extractor's per-response reduction, the counting-unit boundary, the self-test arms, two fixtures, two oracle rows, the fixture README), `ca5b9dce` (the roll-up preserves the version; the reporting contract § 2), `e2aa4610` (store schema `2.0.0`, the SKILL.md note, the ignore rule, the attribution convention) and `3e7acea0` (the extractor's help prints its whole header). Head at the runs: `3e7acea0`.

| Check | Command | Observed |
|---|---|---|
| FinOps self-tests | `bash core/skills/finops-usage-extractor/scripts/<script>.sh --self-test`, for extract-usage, rollup-attribution, report-usage and estimate-usage | all four PASS, exit 0. The roll-up prints 21 PASS lines and 0 FAIL; the extractor prints only failures, and printed none |
| Runtime suite (selection-map row 7: `core/skills/*/scripts/*.sh`) | each changed script's `--self-test </dev/null`: extract-usage and rollup-attribution | both PASS. Two `test-run/suite-pass` events emitted (stage 6, actor `spoke:#8721`, subject #7937, payload `selected-by:glob-7`, `sha:3e7acea0`), read back with `query-pipeline-event.sh --release release-usage-measured-right --stage 6 --event-type test-run --count`: 1 → 3 |
| Authoring-time mutation arms | seven mutations applied in place to the committed beat, one at a time, each run then reverted; the tree read back byte-identical to the commit (`git diff` clean) | every one turns the self-test RED at the arm built for it: last-line-wins merge → three-block arm (cache-read 232, want 233); per-line counting → three-block arm `[109,71,48,491,6,2]` and partial-output arm `[27,2,80]`; the fail-closed `return 3` removed → arm 11b (exit 0, store rewritten); the boundary keyed on the full version string → arm 11c (fell back, and kept a same-unit store); a message calling every store per-line → arm 11d; first-line-wins merge → partial-output arm `[2,1,40]` and `[2,1]`; the roll-up re-stamp restored → roll-up (H) (got 1.2.0, want the sentinel) |
| CI precision-probe anchors | the dim_agg seed line and the carry-forward binding line, each found by another token on the line (the anchors' own text holds a token a hook reads as a script path); `git diff -U0` over the beat for changed lines touching them | each line present once; 0 changed lines touch either. Sensitivity: the same diff probe sees the 6 changed `dim_agg(` call lines. The CI steps assert exactly-once at run time |
| #7937 AC-2, AC-3, AC-4 | the § Verification Plan grep methods, on this head and on the pre-beat base `a8e3ac6d` | AC-2 `three-block` 4 (base 0) · AC-3 `partial-output` 6 (base 0) · AC-4 `2.33` 2 on the schema (base 0). AC-4's reader limb, read: frontmatter `schema_version: "2.0.0"`, meta row `current "2.0.0"` |
| #7937 AC-1 on real transcript shapes (Stage 7 grades the criterion) | a scratch store built by the committed extractor from a deterministic sample of the local transcripts (every 6th main and every 27th spawned-agent file under 400 KB, by sorted path: 25 + 24 = 49 files), compared with an independent python parser's per-`message.id` max-merge | 43 of 43 session records equal on all four token fields; 6 files carry no assistant record and yield none. Sensitivity: 34 of the 43 files hold a multi-line response, and on all 34 the per-line sum differs from the per-response sum, so the prior counting would fail them. Aggregates only; no value leaves the machine |
| CIAC-1 | `grep -c -F "CIAC-1 per-response-incomplete"` on the extractor | 0 — the marker belongs to beat 3 (#7938), placed when the second behaviour exists |
| Plan verifier after beat 2 | `bash release/tools/verify-release-plan.sh --stage4-comment <the Stage-4 comment, saved> <this file>`, range `b1042eec..3e7acea0` (merge-base) | 11 PASS / 13 FAIL / 29 SKIP / 2 UNRUNNABLE / 1 ERROR over 56 records. FCM-3 (the `per-response/` ADD) and #7937 AC-2 and AC-3 now PASS; #7937 AC-4 reads UNRUNNABLE, its grep limb PASS beside its reader-graded limb (read above); `FCM-COVERAGE` PASS with 0 uninterpreted rows. Every remaining FAIL is a later beat's row or ADD |
| Doc links and release links | `check-doc-links.py --require-targets` over the five edited documents; `check-release-links.py --roots core release docs .github --check-anchors` over the same files; its `--self-test` | 0 findings each; the subjects carry 11 link sequences, and the release-link self-test reports its planted absent target |
| Skill-roster totals | `check-skill-count-imp.py --files <the five edited documents> --mode both` | exit 0, no finding |
| Issue references | `check-issue-ref-validity.sh --base a8e3ac6d --head HEAD` | pass; the schema and SKILL.md carry the whole-file marker and are skipped |
| Skill-edit probes (SKILL.md, the reporting contract) | the issue-reference, absolute-path, home-path, identity, raw-URL, link-sequence, strikethrough, placeholder and bypass-token classes over the added lines, with one planted control line | 0 in every class over the contract's 7 added lines; SKILL.md's 15 read 0 except 1 home-path hit, a pre-existing shell-variable expression on the line this beat appended to. Each of 9 controls fires |
| Reference-durability cutover pattern | the shared detector's pattern over every added line of the beat, under BSD grep | 0; control (a planted cutover sentence) 1. The local default grep rejected the pattern as too complex and returned nothing for the control as well, so that run was discarded as a broken probe |
| Pipe into a short-circuiting reader | a grep over the beat's added shell lines for a pipe into `head`, a quiet or max-count grep, `read`, or a `sed`/`awk` that quits | 0. Sensitivity: the same pattern finds the 2 such pipes this beat removed |
| Ignore rule | `git check-ignore -v --no-index` | `x/finops/prior/schema-1.0.0/usage.jsonl` ignored by the new rule; control `x/finops/usage.jsonl` ignored by the existing rule; near-miss `x/finops/notprior/…` not ignored |
| Close-family keywords | `check-commit-close-keywords.py --base origin/main --head HEAD` before each push | CLEAN at 4, 5 and 7 commits examined; 0 findings each |
| Package consequence | the beat's 11 changed paths on STDIN to `build-skill-packages.sh --skills-for-paths` | `finops-usage-extractor` only (control: `.gitignore` alone → none). Not rebuilt here: the single rebuild is beat 7, so the pre-merge package-freshness job is expected to read the package stale until then |
| ADR index | — | N/A — this beat adds no record under `release/ADRs/` |

### Beat 3 (#7938) — Stage 6 C4

Run by the Stage-6 spoke on #8722 over the beat-3 commits `badadca1` (the incomplete-response flag in the extractor's per-response reduction, the CIAC-1 marker, the two record counts, the rebuild summary, the `no-final-output` arm, the eight-response fixture, one oracle row, the fixture README) and `35b7d218` (the store schema, and one extractor comment reworded so it cites no issue number). Head at the runs: `35b7d218`.

| Check | Command | Observed |
|---|---|---|
| FinOps self-tests | `bash core/skills/finops-usage-extractor/scripts/<script>.sh --self-test`, for extract-usage, rollup-attribution, report-usage and estimate-usage, each by its literal path | all four PASS, exit 0. The extractor prints only failures, and printed none; the roll-up prints 0 FAIL lines |
| Runtime suite (selection-map row 7: `core/skills/*/scripts/*.sh`) | the changed script's `--self-test </dev/null`: extract-usage | PASS, 0 FAIL lines. One `test-run/suite-pass` event emitted (stage 6, actor `spoke:#8722`, subject #7938, payload `selected-by:glob-7`, `sha:35b7d218`), read back with `query-pipeline-event.sh --release release-usage-measured-right --stage 6 --event-type test-run --count`: 3 → 4 |
| Authoring-time mutation arms | ten mutations applied in place to the committed extractor, one at a time, each run by the repository-relative path and then reverted; the bytes read back hash-identical after each, and `git diff --quiet` held at the end | the unmutated control exits 0; every mutation turns the self-test red at its own arm. Each guard clause deleted (message id / usage / stop-reason key) → `[4,2]` on the fixture, corpus `[4,9]`; the key test narrowed to the message placement → `[2,4]`; the any-line-null detector → `[4,3]`, corpus `[7,10]` and the partition invariant; reading `.message.stop_reason` past the `stop_of` seam → corpus `[3,11]` and the partition invariant (the fixture alone stays `[3,3]`); the counts dropped from the subagent record → its `[null,null]` and the presence invariant; the incomplete count reading the unevaluated tag → corpus `[10,10]` and the heuristic bound; the tag never set → `[0,0]`; self-test 8b back to 2 → the 8b assertion |
| Independent control | a python recompute of every fixture transcript's per-response totals and states, written without the extractor | equal to the scratch store's records for all 8 sessions and 3 subagent records, and to the new oracle row (input 280, output 356, cache-write 2800, cache-read 11400; 8 responses, 1 heuristic; complete 2, incomplete 3, unevaluated 3). The same instrument reproduces beat 2's three-block totals, so it reads what the extractor reads |
| #7938 AC-1, AC-2 and CIAC-1 | the § Verification Plan grep methods, on this head and on the pre-beat base `a7a24222` | AC-1 `incomplete` 33 (base 0; same-file control `toksum` 5 at both) · AC-2 `no-final-output` 9 (base 0) · CIAC-1 `CIAC-1 per-response-incomplete` 2 (base 0). An independent line count agrees with each |
| CI precision-probe anchors | a python count of the dim_agg seed line and the carry-forward binding line, each by its exact text (beat 2 met a hook refusing a Bash grep that carries the jq alternative operator, so the count runs from a file) | each present exactly once; control (the `dim_agg` definition line) 1 |
| Plan verifier after beat 3 | `bash release/tools/verify-release-plan.sh --stage4-comment <the Stage-4 comment, saved> <this file>`, range `b1042eec..35b7d218` (merge-base) | 14 PASS / 10 FAIL / 29 SKIP / 2 UNRUNNABLE / 1 ERROR over 56 records. #7938 AC-1, AC-2 and CIAC-1 now PASS; `FCM-COVERAGE` PASS with 0 uninterpreted rows. Every remaining FAIL is a later beat's row or ADD (#7939 AC-2 and AC-4, #7943 AC-2 and AC-4, #7945 AC-1, CIAC-3, FCM-4 to FCM-7); the ERROR and the UNRUNNABLE rows are unchanged. CIAC lint `flagged=0`; `--verify-stamp` OK |
| Consumers, end to end | a scratch store built from the fixtures, then `rollup-attribution.sh` over it (hub-state pointed at an empty scratch directory) and `report-usage.sh --since 2020-01-01 --until 2020-12-31 --json` | roll-up exit 0 (1 rollup and 1 coverage record); report exit 0, 8 sessions in the window, schema `2.0.0`. Neither consumer reads the two counts, and both accept a store that carries them |
| Store schema frontmatter | a YAML parse of the frontmatter (Ruby Psych) | 7 keys parse, and the edited purpose and consumers values read back as written. Sensitivity: the same parser rejects a planted plain scalar holding a colon |
| Cascade sweep (the "v2.0.0 changes no record shape or field" claims) | a python count of each old phrase in the schema before and after the beat | 4 phrases (frontmatter consumers, intro, § Versioning, the 2.0.0 Version-History row), each 1 before and 0 after; control (the v1.1.0 "frozen v1.0.0 kinds are unchanged" phrase) 2 |
| Doc links, release links, roster totals | `check-doc-links.py --require-targets` over the schema and the fixture README; `check-release-links.py --roots core release docs .github --check-anchors` over the same files; `check-skill-count-imp.py --mode both`; each tool's `--self-test` | 0 findings each; the subjects carry 1 link sequence; the release-link self-test reports its planted absent target, and the roster self-test passes 19 invariants |
| Issue references | `check-issue-ref-validity.sh --base a7a24222 --head 35b7d218` | pass; the schema carries the whole-file marker and is skipped, and the README adds no reference |
| Content probes on added lines | eleven classes (operator handle, name, email, home path, raw URL, link sequence, strikethrough, placeholder, bypass token, issue number, pipe into a short-circuiting reader) over the beat's 186 added lines under `core/`, with one planted control line | 0 in every class; each control fires. The pipe class's specificity: the arm's `printf … \| sed` lines, a reader that does not quit, read 0 |
| Reference-durability cutover pattern | the shared detector's pattern, evaluated in python with its POSIX classes translated, over the schema's 23 added lines | 0; control (a planted cutover sentence) 1 |
| Close-family keywords | `check-commit-close-keywords.py --base origin/main --head HEAD` before each push | CLEAN at 9 and 10 commits examined; 0 findings each |
| Package consequence | the beat's 5 changed paths on STDIN to `build-skill-packages.sh --skills-for-paths` | `finops-usage-extractor` only (control: the schema alone → none). Not rebuilt here: the single rebuild is beat 7 |
| ADR index | — | N/A — this beat adds no record under `release/ADRs/` |

### Beat 4 (#7939) — Stage 6 C4

Run by the Stage-6 spoke on #8723 over the beat-4 commit `4c2bf7e1`: the validator widening and the instant comparison in `report-usage.sh`, the SM-3b and SM-5 expected values from a date-prefix check, the SM-6b and SM-10f arms, the boundary session in the report fixture, the fixture README row, and the reporting contract's §§ 1, 6 and 8. All four changes are in one commit (REC-3). Head at the runs: `4c2bf7e1`.

| Check | Command | Observed |
|---|---|---|
| FinOps self-tests | `bash core/skills/finops-usage-extractor/scripts/<script>.sh --self-test`, for extract-usage, rollup-attribution, report-usage and estimate-usage, each by its literal path | all four PASS, exit 0. The report prints 41 PASS lines and 0 FAIL (38 at the pre-beat base `ea96b02a`); the other three print 0 FAIL lines |
| RED, then GREEN (REC-3) | the report self-test in the working tree, in three states, before the commit | (1) the new fixture on the unfixed code: the first render exits 3 with `malformed session.started_utc on 1 session record(s)`. (2) The validator widened and the filter unchanged: SM-3b (9750, want 11750), SM-5 (27000 against 37000), SM-6 (0, want 1), SM-6b (lower leg 0, upper leg 1, trend parity broken), the SM-6b population (2 and 8) and SM-11 FAIL, 35 PASS. (3) The full change: 41 PASS, 0 FAIL |
| Validator mutants (#8800 F1) | two mutations of the widened validator, applied in place one at a time, each run by the repository-relative path and then reverted; the script hashed before and after | `Z` made optional → SM-10f FAIL at the missing-`Z` leg only; a comma admitted → SM-10f FAIL at the comma leg only. The script reads back hash-identical after both |
| Runtime suite (selection-map row 7: `core/skills/*/scripts/*.sh`) | the changed script's `--self-test </dev/null`: report-usage, at head `4c2bf7e1` | PASS, 41 PASS and 0 FAIL. One `test-run/suite-pass` event emitted (stage 6, actor `spoke:#8723`, subject #7939, payload `selected-by:glob-7`, `sha:4c2bf7e1`), read back with `query-pipeline-event.sh --release release-usage-measured-right --stage 6 --event-type test-run --count`: 4 → 5 |
| #7939 AC-2, AC-3 and AC-4 | the § Verification Plan grep methods, on this head and on the pre-beat base `ea96b02a` | AC-2 1 (base 0; same-file control `started_utc` 9 at the base) · AC-3 3 (the guard is kept) · AC-4 `SM-6b` 8 (base 0) |
| CI precision-probe anchors | a python count, over `git show` of the base and the head, of the `leaf_total` wrapper line and the `SM-3b SA-3` failure label, each by its exact text | each present exactly once at the base and at the head; control (the `ok()` definition line) 1 at both. SM-3b's label is unchanged (#8715 Mode 3 flag 2) |
| Oracle (REC-4) | SM-11 in the GREEN run | `report.expected.json` is not edited and still matches modulo `generated_utc`; `CONDITIONAL:report-output-shift` stays unpromoted |
| Plan verifier after beat 4 | `bash release/tools/verify-release-plan.sh --stage4-comment <the Stage-4 comment, saved> <this file>`, range `99c8b442..4c2bf7e1` (merge-base) | 16 PASS / 8 FAIL / 29 SKIP / 2 UNRUNNABLE / 1 ERROR over 56 records. #7939 AC-2, AC-3 and AC-4 PASS (AC-1 is declared-deferred to Stage 7); the CIAC lint reads `flagged=0`. Every remaining FAIL is a later beat's row or ADD (#7943 AC-2 and AC-4, #7945 AC-1, CIAC-3, FCM-4 to FCM-7) |
| Content probes on added lines | eleven classes (operator handle, name, email, home path, raw URL, link sequence, strikethrough, placeholder, bypass token, issue number, pipe into a short-circuiting reader) over the beat's 131 added lines under `core/`, with one planted control line | 0 in every class; each control fires |
| Doc links, release links | `check-doc-links.py --require-targets` and `check-release-links.py --roots core release docs .github --check-anchors --files` over the contract and the fixture README; each tool's `--self-test` | 0 findings. The two files carry 0 link sequences (python count; control: the skill's `SKILL.md`, 4), so this is N/A for the beat's edits rather than a measured clean. Both self-tests pass |
| Close-family keywords | `check-commit-close-keywords.py --base origin/main --head HEAD` before each push | CLEAN at 18 and 19 commits examined; 0 findings each |
| Package consequence | the beat's 4 changed paths on STDIN to `build-skill-packages.sh --skills-for-paths` | `finops-usage-extractor` only (control: `.gitignore` alone → none). Not rebuilt here: the single rebuild is beat 7, so the pre-merge package-freshness job is expected to read the package stale until then |
| Check roster | read once after the push | NOT-EVALUATED — dark head. #8821 reads `CONFLICTING` / `DIRTY` at `4c2bf7e1`, so its `pull_request` gates did not dispatch; no CI-backed claim is made for this head. The local self-tests above stand on their own |
| ADR index | — | N/A — this beat adds no record under `release/ADRs/` |

### Beat 5a (#7943) — Stage 6 C4

Run by the Stage-6 spoke on #8725 over the beat-5a commits `7b75b277` (the conversion `convert-usage.sh`, its four allowlist forms, the finops-selftest loop entry), `e2c2fa7e` (the conversion's SKILL.md section; the core public-API script table and its mirror), `acd8c2f1` (the velocity tool's `--cost-row` mode and its 18 self-test arms) and `e1ee70ab` (the velocity standard's § 7a, § 7, § 11 and § 13). Beat 5b is not built (DEV-35).

| Check | Command | Observed |
|---|---|---|
| Conversion self-test | `bash core/skills/finops-usage-extractor/scripts/convert-usage.sh --self-test` | **Local: refused** — the script-execution hook has no permitted form for a new script until the allowlist this beat adds is deployed (DEV-34). **CI: PASS** — the finops-selftest job on `7b75b277` printed 17 PASS lines, 0 FAIL, and `OK: convert-usage` (Release tooling smoke run, FinOps job green) |
| Velocity tool self-test | `bash release/tools/compute-release-velocity.sh --self-test`, at `acd8c2f1` | PASS, exit 0: the 18 cost-row arms (CR-1 to CR-13, the subset rule, the unresolved unit, CR-9's rule with four near-misses and a vacuity control) and the pre-existing arms. Running it exercises the conversion's `--convert` and `--params` through the cost row's own call path, against the shipped template with both rung seams pinned |
| Authoring-time mutation arms | nine mutations of the committed engine, applied in place one at a time, each run by the repository-relative path and reverted; the file hashed before and after | every one turns the self-test red at its own arm: the subset rule off → subset arm; an absent count read as 0 → CR-5; the chip-root stage rule off → CR-1; the pair ends swapped → CR-8; an unrecorded bracket move accepted → CR-9; the lower bound from the unevaluated count only → CR-2; symlinks and inodes followed → CR-3; the home guard off → CR-10; the containment check off → CR-11. The file read back byte-identical |
| #7943 AC-2, AC-4 and CIAC-3 | the § Verification Plan grep methods, on this head and on the pre-beat base `4511155c` | AC-2 `cost-row` 28 (base 0) · AC-4 `killed-spoke` 5 (base 0) · CIAC-3 `CIAC-3 both-bracket-ends` 5 (base 0) |
| INT-5, both arms (FM-3) | `git grep -n -E` for the three seed literals #8810 FM-3 names (the low cache-read weight and both `K` values) over `release/tools` and `core/skills`, the conversion excluded; `git grep -n -F tokens_per_weekly_point` over `*.sh` and `*.py` under the same two trees | literal arm 0; sensitivity (the template) 6. Key arm: the conversion only (7 lines) |
| Plan verifier after beat 5a | `bash release/tools/verify-release-plan.sh --stage4-comment <the Stage-4 comment, saved> <this file>`, range `37520993..e1ee70ab` (merge-base) | 20 PASS / 4 FAIL / 29 SKIP / 2 UNRUNNABLE / 1 ERROR over 56 records. #7943 AC-2, AC-4, CIAC-3 and FCM-4 (the conversion ADD) now PASS; `FCM-COVERAGE` PASS with 0 uninterpreted rows. Every remaining FAIL is a later beat's row or ADD (#7945 AC-1, FCM-5 to FCM-7) |
| Doc links, release links, roster totals | `check-doc-links.py --require-targets` over the five edited documents; `check-release-links.py --check-anchors`; `check-skill-count-imp.py --mode both`; the link checker's `--self-test` | 0 findings each; the link self-test passes its 12 fixtures. The two added link sequences (the module-API mirror's script table, in that file's convention) resolve |
| Content probes on added lines | twelve classes (operator handle, name, email, home path, raw URL, link sequence, issue number, strikethrough, placeholder, close keyword, short-circuit pipe, a seed literal of the cost unit) over each slice's added lines, with one planted control line | 0 in every class over 519 + 35 + 1,359 + 88 added lines, except the two link sequences above; each control fires |
| Skill edit (SKILL.md) | pmo-skill-editor Mode A by conduct, recorded in the slice's `Skill-Editor-Audit-Trail:` trailer | the skill carries no edit-arming key, so the gate does not arm; registry impact: one outbound relation, no inbound edge |
| Close-family keywords | `check-commit-close-keywords.py --base origin/main --head HEAD` before each push | CLEAN at 24 to 28 commits examined; 0 findings each |
| Package consequence | the beat's nine changed paths on STDIN to `build-skill-packages.sh --skills-for-paths`, run after the first record of this row was written | `finops-usage-extractor` only (control: `.gitignore` alone → none). Not rebuilt here: the single rebuild is beat 7, so the pre-merge package-freshness job reads the package stale until then |
| The shell entry, live | `compute-release-velocity.sh unclaimed --milestone <this milestone> --cost-row --out-dir <a folder in the spoke's run directory>` | exit 0; two stdout lines; empty stderr; a `fetched` row of 5 cells carrying no home path and no path-encoded folder name. Aggregates only: 1 tree, 23 sessions (1 hub, 14 spokes, 8 reviewers — the release's 8 adversarial reviews), 3,311 responses, 0 incomplete, weekly points at both bracket ends, 0 % unstaged, 0 cross-file shared |
| Shell-entry refusals | a cost-row flag without `--cost-row`; `--cost-row` without `--out-dir`; `--json` with `--cost-row` | exit 1, exit 1, refused — each with its own message |
| Runtime suites (selection-map rows 4, 5 and 7) | row 4 (`release/tools/*.sh`): the changed tool's self-test run directly, and the discovered set's macOS partition by `check-selftest-coverage.py --run --runner macos`; row 5 (`core/config/allowlists/**`): `bash core/deploy/tests/run-install-regression.sh` (sandbox: self); row 7 (`core/skills/*/scripts/*.sh`): the conversion's self-test | row 4: the velocity tool PASS, and CI's Ubuntu discovery job green on `acd8c2f1`. The macOS partition read 3 of 4 OK on its first run: `automated-closeout.sh` failed one wall-clock arm (expected at most 2 s, took 3 s) while the install suite ran beside it. Re-run alone on an idle machine it PASSES (exit 0); the file is untouched by this beat. Row 5: `INSTALL-REGRESSION: 4408 passed, 0 failed — VERDICT PASS [env: home-account; skipped: 1]`. Row 7: the CI run in the first row of this table. Three `test-run/suite-pass` events emitted (stage 6, actor `spoke:#8725`, subject #7943, payloads `selected-by:glob-4`, `glob-5` and `glob-7`), read back with `query-pipeline-event.sh --release release-usage-measured-right --stage 6 --event-type test-run --count`: 5 → 8 |
| Reader parity | the awk program of the conversion's TOML reader against `master-enable.sh`'s, byte for byte | identical, 18 lines each; control: `platform-toggle.sh`'s copy is identical too; a one-character mutation breaks equality |
| Check roster | `gh pr checks` once on `e3c7e120`, without waiting | 57 checks: 48 pass, 9 pending (macOS jobs and pre-merge gates), 0 failing — the dead-file-reference, issue-reference, both depersonalization, cross-reference, fragile-reference, release-link and both ADR gates among the passes. CI's Ubuntu discovered-self-test job (the velocity tool is a manifest-floor member) concluded success on `acd8c2f1` |
| Post-push mergeability | `gh pr view` after each push | CLEAR at `7b75b277`, `e2c2fa7e`, `acd8c2f1`, `e1ee70ab` and `e3c7e120` |
| ADR index | — | N/A — this beat adds no record under `release/ADRs/` |

### Beat 5b (#7943) — Stage 6 C4

Run by the Stage-6 spoke on #8725 over the beat-5b commits `792d1791` and `f1c6f46e`. The first carries the registration rows: the resolver and its header rows, the `[paths]` key and its declaration, the §4 token row, the value pin and the surface-register row S-45. The second carries the `/local-state/telemetry/*` ignore rule. Beat 5b ran as option B of the operator's D-5b decision, so the default home, the close-out phase and its stage text are not built (DEV-35, DEV-36).

| Check | Command | Observed |
|---|---|---|
| Resolver value pin (C19) | `bash core/deploy/tests/test_lib_instance_path.sh` | 24 passed, 0 failed (20 before the beat). Case 8's four arms pin the default `/ws/pmo-platform/local-state/telemetry`, the override, and that neither `PMO_INSTANCE_PATH` nor an ambient `CLAUDE_WORKSPACE_ROOT` moves it. `HOME` is sandboxed, so the live operator config never enters |
| Authoring-time mutation arms | three mutations of the resolver, each applied in place, run and reverted; the lib hashed before and after | rooted under the instance container → 8a, 8c and 8d red; the toml tier dropped → 8b red; the ambient root preferred → 8d red. The lib read back hash-identical after each |
| AC-3 in the release worktree (#8810 FM-2) | `git check-ignore -q <path>` from the worktree root, in the baseline's invocation shape | row path `local-state/telemetry/release-cost/release-usage-measured-right.json` 0 (1 before the beat); tracked control `README.md` 1; analysis control `analysis/x/y.md` 0; near-misses `local-state/README.md`, `local-state/release-runs/x.json` and `core/local-state/telemetry/x.json` 1 each. `-v` names the new `/local-state/telemetry/*` line |
| Register-to-registry Class parity | a python pass over §4's token rows and the register's Resolves-today cells, with one planted class flip | 18 tokens, each named by a register row; 0 class disagreements (S-45 and the new §4 row both read `Working state`). The planted flip reads 1 |
| Three-registry parity (C70c, C70d) | deploy Check 70 inside `bash core/deploy/deploy.sh --check`. The direct run of the schema check is refused by the script-execution hook; CI's operator.toml declared-schema gate runs all three modes, C70e included | self-test 9 of 9 arms. C70c compared 54 declared keys against 54 template keys (53 and 53 before the beat). C70b found 0 literal emits over 231 lines. C70d compared 18 §4 rows against 18 template and 18 declared `operator_instance_*` keys (17 each before). The new key is opt-in, so C70a's delivered set is unchanged. 0 findings, OK |
| Token conformance | deploy Check 44 | unchanged: 5 un-codified angle tokens over 103 raw matches before and after (the new token is codified in the same commit); no square-bracket finding; OK |
| Hook-tier publish parity | deploy Check 79 | advisory, as expected. The deployed hook-tier copy of `lib-instance-path.sh` reads DRIFT, "a stale PLATFORM copy", one source commit behind: MATCH 32 / DRIFT 1 (33 / 0 before). This is the manifest's propagate disposition (DEV-40); the remedy the check names is the hook carrier's `--refresh-hooks` |
| Deploy check delta | `bash core/deploy/deploy.sh --check`, at `e8c9db56` and at `f1c6f46e` | 4 issues before and 4 after, and the FAIL and DRIFT lines are identical. The five lines are: the FinOps package stale until beat 7, its user-local mirror, Check 47's 13 release-body-drift findings, and a count-structure finding at six sites in four files, none of them this beat's. Check 14 (doc links) is OK; Check 43 (path portability) is unchanged at its one pre-existing warning; Check 7's rebuilt FinOps hash is identical. The after-run's later checks, from around Check 38 on, ran while this file was being edited, so they read its in-progress, uncommitted state, placeholders included; the identical FAIL set clears the two code commits either way |
| Pre-merge subset | `bash core/deploy/deploy.sh --check-required-subset` | all 4 (Checks 38, 73, 77, 78) PASS, before and after |
| Runtime suites (selection-map rows 2 and 5) | rows 2 (`core/deploy/**`: the lib and its test) and 5 (`core/config/*.template`) → `bash core/deploy/tests/run-install-regression.sh` (sandbox: self), which enrolls the resolver test, at `f1c6f46e`. The schema JSON and `.gitignore` match no row: the schema is an input that row 5's members read, and the ignore rule is graded by AC-3. Install-tests' version-skew step and the resolver round-trip test have no allowlisted local form and run on CI | the 15 deploy-test members: 499 passed, 0 failed, 1 skipped, the resolver test's 24 among them. The hook-test floor was still running under heavy machine load when this table was committed. The sub-task #8725 output records whether the floor concluded and which `test-run` events (stage 6, actor `spoke:#8725`) were emitted; Stage 7 A8 re-runs the suite as the authoritative gate |
| Content probes on added lines | twelve classes (operator handle, name, email, home path, raw URL, link sequence, issue number, strikethrough, placeholder, close keyword, temporal framing, version cutover) and the shared fragile-reference detector's cutover and link patterns, over the 118 added lines of the two code commits, each with one planted control line | 0 in every class; each control fires |
| Cascade sweep (stated counts on edited lines) | a count of each old phrase before and after the beat | "the two in-repo homes" (§4) 1 → 0; "2 of the codified tokens" (resolver test) 1 → 0; "the three ambient resolvers below" (resolver lib) 1 → 0. No other tracked file states the size of the token registry or the surface register (a python sweep of 1,157 files; its 8 near-misses are unrelated counts) |
| Doc links, release links, roster totals | `check-doc-links.py --require-targets` over the two edited standards; `check-release-links.py --roots core --check-anchors`, read for them; `check-skill-count-imp.py --mode both` and its `--self-test` | 0 findings each in the edited files; the walk's one broken link and its missing anchors are elsewhere. The roster self-test passes 19 invariants |
| Issue references | `check-issue-ref-validity.sh --base <the pre-beat branch head> --head HEAD`, with the repository named | pass |
| Close-family keywords | `check-commit-close-keywords.py --base origin/main --head HEAD` before each push | CLEAN at 31 commits examined, 0 findings |
| Check roster | the head's check runs, read once on `f1c6f46e` without waiting | 57 runs: 47 passed, 10 queued or running, 0 failed. The operator.toml declared-schema gate (all three modes, C70e included), the depersonalization, dead-file-reference and issue-reference gates and the durable-corpus fragile-reference delta had all passed |
| Post-push mergeability | `gh pr view` after each push | CLEAR at `f1c6f46e`; the push that carries this table is recorded on the sub-task #8725 output |
| Package consequence | the beat's paths on STDIN to `build-skill-packages.sh --skills-for-paths` | none (control: the FinOps SKILL.md → `finops-usage-extractor`). Deploy Check 7's rebuilt FinOps hash is identical before and after the beat |
| Plan verifier after beat 5b | `bash release/tools/verify-release-plan.sh --stage4-comment <the Stage-4 comment, saved> <this file>`, range `37520993..f1c6f46e` (merge-base) | 20 PASS / 4 FAIL / 29 SKIP / 2 UNRUNNABLE / 1 ERROR over 56 records, as after beat 5a. `FCM-COVERAGE` PASS with `declared=53 interpreted=53` (the placement standard's row) and 0 uninterpreted. AC-3 stays a declared deferral with its refined method; every FAIL is beat 6's or beat 8's. CIAC lint `flagged=0`; `--verify-stamp` OK |
| ADR index | — | N/A — this beat adds no record under `release/ADRs/` |

### Beat 6 (#7945) — Stage 6 C4

Run by the Stage-6 spoke on #8726 over the beat-6 commits `d65beb82` (the analysis resolver and its Case 9), `a98f8683` (the ranker, its fixtures, the allowlist forms, the loop entry, the probes and the parity step), `72f6dc89` (two self-test plumbing defects the first CI run found) and `01762ac5` (the SKILL.md section and the framework paragraph). The ranker cannot run locally before its allowlist rows deploy, so CI is its runner (DEV-42).

| Check | Command | Observed |
|---|---|---|
| Ranker self-test | `bash core/skills/finops-usage-extractor/scripts/rank-command-templates.sh --self-test` | **Local: refused** — the script-execution hook has no permitted form for a script this beat adds (DEV-34's class). **CI: PASS** — the finops-selftest job on `72f6dc89` printed 23 PASS lines, 0 FAIL, and `OK: rank-command-templates`; the other five FinOps self-tests stayed green. On `a98f8683` it read 22 of 23 (the canonicalizer arm compared a trailing newline; the EXIT trap named a function-local variable), fixed in `72f6dc89` |
| Privacy controls, RED then GREEN (CD-1, FM-1) | the probe step plants one defect per run in a throwaway copy; the unmutated loop step is its green twin in the same job run | P1 (the default class renders a word): exit 1, `FAIL: leak arm: 1 literal(s) leaked` (arm 1 fails beside it, as FM-1 predicted). P1b (an unlisted flag renders itself): exit 1, the leak arm red. P1c (a flag after an interpreter's script renders itself): exit 1, the leak arm red. Green: the leak arm passes over 17 literals, each in the staged input, each consumed by its declared class inside its declared procedure, none in any written or printed byte, and every one of nine classes carrying a literal in a ranking procedure |
| Other planted defects | the same step | P2 (the session floor at one): the runtime canary refuses, `FATAL (exit 3): the runtime canary failed` (DEV-44). P3 (`w × (R + 1)`): `FAIL: cost arm`, cache read 1820 against the hand-computed 1456. P4 (a vocabulary word added without a repin): `FAIL: vocabulary arm`, digest mismatch |
| Stage-pattern parity (CD-5 b) | the parity step | OK: both pattern lines appear once in each file and match byte for byte |
| Resolver value pin (C11) | `bash core/deploy/tests/test_lib_instance_path.sh` | 28 passed, 0 failed (24 before the beat): Case 9's four arms pin the default `/ws/pmo-platform/analysis`, the override, a control that the override leaves the instance base where it was, and that neither `PMO_INSTANCE_PATH` nor an ambient `CLAUDE_WORKSPACE_ROOT` moves it. `HOME` is sandboxed |
| Resolver mutation arms | two mutations applied in place, run and reverted; the lib hashed before and after | rooted under the instance container → 9a and 9d red; the toml tier dropped → 9b red. The lib read back hash-identical |
| #7945 AC-1 and AC-4 | the § Verification Plan methods | AC-1: `test -f` passes (absent at the base `0d7626d4`). AC-4: `near-miss` 6 in the ranker (the same pattern on `extract-usage.sh` reads 3, so the probe detects) |
| INT-2 (the single conversion) | the design's `grep -c -E` for the conversion's key names and seed literals | 0 in the ranker; 19 on `convert-usage.sh`, the sensitivity arm |
| Content probes on added lines | ten classes (issue number, home path, raw root, raw URL, link sequence, strikethrough, placeholder, close keyword, short-circuit pipe, operator handle) over the documents' 74 added lines, one planted control each; the path-leak primitive over the script, the fixtures and their README | 0 in every class; each control fires. The path-leak scan reads 0 lines (the fixture lines carrying a fabricated home hold the per-line marker) |
| Doc links | `check-doc-links.py --require-targets` over SKILL.md, the framework, both fixture READMEs and this file | 0 findings |
| Issue references | `check-issue-ref-validity.sh --base 0d7626d4 --head <beat head>` | pass |
| Plan verifier after beat 6 | `bash release/tools/verify-release-plan.sh --stage4-comment <the Stage-4 comment, saved> <this file>` | 24 PASS / 1 FAIL / 29 SKIP / 2 UNRUNNABLE / 0 ERROR over 56 records. #7945 AC-1, AC-4, FCM-5 and FCM-6 now PASS; `FCM-COVERAGE` PASS with `declared=53 interpreted=53` and 0 uninterpreted. The one FAIL is beat 8's ADR ADD. CIAC lint `flagged=0` |
| Package consequence | the beat's paths on STDIN to `build-skill-packages.sh --skills-for-paths` | `finops-usage-extractor` only (control: `.gitignore` alone → none). Not rebuilt here: beat 7 rebuilds once, so the pre-merge package-freshness job reads the package stale until then |
| Close-family keywords | `check-commit-close-keywords.py --base origin/main --head HEAD` before each push | CLEAN at every push |
| Post-push mergeability | `gh pr view` after each push | CLEAR at `d65beb82`, `a98f8683`, `72f6dc89` and `01762ac5` |
| ADR index | — | N/A — this beat adds no record under `release/ADRs/` |

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
| **DEV-10** | **`[cost_unit]` carries a `calibration_model` key, seeded empty.** CD-2's multiplier is "relative to the calibration model" and FM-1's eligibility rule admits pairs "on the calibration model", so the calibration must name that model; Decision 7 puts every calibrated value in the numeric home, so the name lives there too. The authoring census recorded no per-model split, so the seed names none, every model's figures carry the unprobed label until a revisit names one, and Decision 8 lets a revisit whose eligible pairs all ran on one model name it. Without the key a conversion could not tell the calibration model from an unprobed one | Stage-6 B3 (minor adjustment, to make the adopted CD-2 and FM-1 well-defined) | **APPLIED** — beat 1 (template, schema, catalog, ADR Decisions 3, 7 and 8) |
| **DEV-11** | **The per-model axis is two inline tables** (`model_draw_multipliers`, `model_weekly_windows`, each defaulting to `{}`), not one sub-table per model. The section-aware reader idiom the conversion lifts reads a known section by exact header, so it can read an inline table in one call but cannot enumerate per-model sub-tables; `{}` follows the template's `type_mapping_overrides` precedent and keeps the "every field ships a global default" rule true; both forms are Check-33 parse-clean | Stage-6 B3 (minor adjustment; representation only, CD-2's content unchanged) | **APPLIED** — beat 1 |
| **DEV-12** | **CD-1's state keys are not adopted, and FM-4's reader and override arm are not beat 1's.** PA-010 renders D-Home (A) with CD-2's per-model axis and names no other counter-design, so `calibration_clean_pairs` and a plan label are not added; the `calibration: insufficient` label takes its pair count from the revisit lines. FM-4 (the section-aware reader and a rung-5 override arm) binds the single conversion, which is #7943's at beat 5a | scope-lock PA-010; the #7940 Stage-6 brief | **RECORDED** — carried to beat 5a's brief |
| **DEV-13** | **Stale enumerations reconciled on the lines beat 1 edits.** The template header listed 3 of its sections and now orients without enumerating; the schema's § 1 orientation and § 6 section list, and the catalog's § 1 category list, gain the cost-unit section and the behavioral-regression floor they already omitted. Check 33's comment names only the fields its default-presence arm gates, which do not include `[cost_unit]` (the `pass_rate_floor` precedent), so it stays accurate and is not edited | #8716 Cascade-Sweep handoff; reconcile-not-annotate | **APPLIED** — beat 1 |
| **DEV-14** | **The standard's Version History gains one line** for the new register row, as the file's convention records register additions; and the ADR's `## Status` leads with the bold status token rather than the design's bullet, so the durability lint's status-agreement rule reads it | Stage-6 B3 (minor adjustment) | **APPLIED** — beat 1 |
| **DEV-15** | **The prior store is kept in the `prior/` form, layout only.** `--rebuild` keeps a store of another counting unit once at `<store>/prior/schema-<old>/usage.jsonl`, a verbatim hard link the existing tools open with `STORE=<store>/prior/schema-<old>`, instead of the design's `usage.schema-<old>.jsonl`; the ignore rule is `**/finops/prior/`. CD-2's optional projection of `cwd` to its basename while preserving was not rendered at the scope-lock and is not applied, so the copy stays byte-identical to the store it replaces (asserted by `cmp`). A failed preservation removes only what it created (a partial copy, the directories it made), so the store directory is left as it was | scope-lock PA-009 (CD-2 of #8801) | **APPLIED** — beat 2 |
| **DEV-16** | **CD-1 adopted in full.** The boundary keys on the schema major — the counting unit — never on the full version string, in both `--rebuild` (preserve) and `--incremental` (fall back); an unreadable version never matches. The operator messages say "counted per transcript line" for a 1.x store only. Sub-test 11 carries the review's arms: 11b makes the fail-closed path fire (FM-3), 11c is the same-unit near-miss (`2.0.1-selftest`), and 11d pins the non-1.x message | the beat-2 brief (#8801 CD-1 and FM-3, folded at the scope-lock) | **APPLIED** — beat 2 |
| **DEV-17** | **The conditional attribution-convention note fired.** The design's recommended C11 removes two store-schema version parentheticals that would read as a stale pointer once the schema is `2.0.0`; the beat-2 brief did not decline it, so the row moves from the conditional block to the beat-2 block as an EDIT, and the convention's version moves to `1.2.1` | #8713 C11; the beat-2 brief | **APPLIED** — beat 2; § File Change Matrix, § Per-card write sets |
| **DEV-18** | **Stale text reconciled on lines beat 2 edits, beyond the design's sweep.** The extractor's exit-code line still said "four causes" in lowercase (the sweep's case-sensitive grep for the capitalised word missed it), now "five". SKILL.md's roll-up-has-run failure mode said both phases stamp the version, which the roll-up no longer does; it now says a store carries the same version whether or not the roll-up has run. And the extractor's `--help` printed a fixed 40 comment lines, which cut the grown header off mid-sentence; it now prints the header block itself | Stage-6 B3 (minor adjustment; reconcile, not annotate) | **APPLIED** — beat 2 |
| **DEV-19** | **The per-file scope is stated wherever the unit is named.** Beyond the three places #8801 PR-1 names (the schema's § Counting unit, its Version-History row, the SKILL.md scope note), the extractor's header comment and the reporting contract's § 2 also say "within one transcript file", matching the cost-unit ADR's Decision 2, which INT-1 grades for the same scope | Stage-6 B3 (minor adjustment; wording only) | **APPLIED** — beat 2 |
| **DEV-20** | **The incomplete test reads the stop reason through `stop_of`, on the merged record, exactly as the `stop_reason` histogram does.** The design's predicate re-read `.message.stop_reason` on each line; #8799 FM-1 moved it into `per_response` through `stop_of`. Reading the merged record's `stop_of` with `dim_key` is FM-1's "no line carries a non-null stop reason" with one refinement: an empty-string stop reason counts as none, as the histogram counts it. So "no stop reason" and the histogram's `"unknown"` bucket are one set by construction. The evaluability clauses run on the raw lines, and the key clause accepts either placement `stop_of` reads (FM-1) | #8799 FM-1, folded at the scope-lock; Stage-6 B3 (minor adjustment) | **APPLIED** — beat 3 |
| **DEV-21** | **PR-1 is adopted with a second always-present count, `unevaluated_responses`, and different bounds.** PR-1's literal assertion `incomplete + unevaluated ≤ turns − heuristic_turns` is false on the committed `proj-beta` fixture, whose one usage-less response is heuristic and unevaluated at once (1 > 0). The arm asserts `incomplete ≤ turns − heuristic_turns` (an incomplete response carries usage on every line) and `incomplete + unevaluated ≤ turns` on every record, and on session records the equality `incomplete + unevaluated == stop_reason."unknown"` in place of the design's NF4 inequality, since DEV-20 makes it hold by construction | #8799 PR-1, folded at the scope-lock; Stage-6 B3 (minor adjustment) | **APPLIED** — beat 3 |
| **DEV-22** | **The fixture holds eight responses, not the design's four, and the arm expects `[3,3]`.** #8799 FM-2 (a) asked for one response that fails only the key clause; the beat pins every clause: E (no `stop_reason` key), F (no `message.id`) and G (no usage block) each fail exactly one clause, and H carries the key only at the record's top level. Deleting any clause, or either placement of the key test, turns the arm red (§ Verification Evidence → Beat 3, ten mutations). Under R3 branch B every record is a sidechain, so self-test 8b moves from 2 to 3 records and `subin` stays proj-gamma-scoped at 28. The oracle row is hand-computed for eight responses and reads `token_source: mixed`, because G is usage-less; the oracle projection carries neither count, so the existing rows are unchanged | #8799 FM-2 (a), extended; #8714 R3 branch B; Stage-6 B3 (minor adjustment) | **APPLIED** — beat 3 |
| **DEV-23** | **No CI precision probe is added for the arm.** #8799 FM-2 (b) would add one to the smoke workflow, which is outside #7938's write set. FM-2 (c) is applied instead: the arm's comment states that no CI precision probe reads it, rather than copying the probe-marker sentence of the carry-forward block. The ten authoring-time mutations stand in for the probe at authoring time only | #8799 FM-2 (b), (c); the beat's write set | **RECORDED** — a probe is a candidate for a later beat or a follow-up (sub-task #8722 output) |
| **DEV-24** | **The schema states the lower bound over every figure, extends the existing data-flow table, and reconciles four statements.** Per #8799 CD-1, a non-zero `incomplete_responses` makes all four `tokens` leaves and `tool_use` lower bounds, not output alone; the new section's heading follows the file's convention, "Incomplete responses (v2.0.0, additive)". Per CD-2 there is no second data-flow table: the Tier-A table under § Counting unit names the two fields and each consumer's effect. Four places said 2.0.0 changes no record shape or field (the frontmatter consumers line, the intro, § Versioning and the Version-History row); each now says what it does change, beyond the design's 2d, which named the row and the narrative. In the fixture README, "two per-response rows" and "exactly two subagent records" now read three | #8799 CD-1, CD-2; #8714 Change 2; reconcile-not-annotate | **APPLIED** — beat 3 |
| **DEV-25** | **The rebuild summary prints both counts, and "?" for a missing one.** The design's summary line summed `incomplete_responses // 0`, which reads an absent count as zero (#8799 PR-1). The summary names the incomplete and the unevaluated totals, and prints "?" when any session record lacks either | #8799 PR-1; Stage-6 B3 (minor adjustment) | **APPLIED** — beat 3 |
| **DEV-26** | **SM-10f asserts every malformed class the contract names.** The design's loop carried two near-misses (a bare `.` and a numeric offset), while the contract's § 6 names four. The loop adds a comma and a missing `Z`, so a validator regression in either class no longer ships green. The closing check is derived from the loop's own count (every attempted value must exit 3, and at least one is attempted) rather than a literal, and the § 8 row says each class § 6 names exits 3, in place of "admits exactly the transcript form" | #8800 F1; the scope-lock fold (Tier 1 [ADJUST]) | **APPLIED** — beat 4; both mutants recorded in § Verification Evidence → Beat 4 |
| **DEV-27** | **The contract's window formula is replaced, not annotated.** § 6 now states `--since D` as `started_utc[0:19] + "Z" >= D + "T00:00:00Z"` and `--until D` in the same form, with the instant clause after the inclusive-bounds and UTC sentences; the raw `>=` formula is gone. § 1's parenthetical says the extractor's sort is a total key for byte-determinism, not a chronological claim, so mixed precision cannot affect it | #8800 F2; the scope-lock fold (Tier 1 [ADJUST]) | **APPLIED** — beat 4 |
| **DEV-28** | **Two optional items are not taken in this beat.** #8715's optional Change 4e (naming the `--trend` gate, SM-7c, on the SM-7 row) was not in this beat's fold list, so § 8 still omits SM-7c. #8800 C1 (a clause on the store schema's `started_utc` row stating the form and the comparison rule) stays with the REC-5 roll-up follow-up, as the hub's brief decided | #8715 Change 4e; #8800 C1; the beat-4 brief | **RECORDED** — both remain candidates for the REC-5 follow-up |
| **DEV-29** | **The hard-link view puts each counted file in its own directory, not the source layout.** The design's view preserved the layout, and the review asked that each store record join on its file path, not its stem. The extractor records only a file's stem and its parent directory's basename, so a preserved layout cannot key on the path: two hubs' nested `agent-<id>` files collide on the same pair. One directory per file makes the parent basename a per-file index, so every record joins on its exact path; the extractor reads nothing else from the layout. An injected store has no view, so it joins on its real layout, and a key two files share joins neither and is counted (`ambiguous_store_keys`, cause `ambiguous-store-key`) | #8810 interrogation row 2 (join on the file path); Stage-6 B3 (minor adjustment, to make the adopted join well-defined) | **APPLIED** — beat 5a |
| **DEV-30** | **CR-9 asserts the cost-unit record's rule as it landed, which sanctions a recorded widening.** FM-1's mitigation reads "narrowing is allowed and widening refused", but the record's Decision 8, committed at beat 1, says a fit outside the bracket widens it and that is recorded, so an arm refusing widening would turn a sanctioned revisit red — FM-1's own failure in the other direction. CR-9 asserts that the configured bracket is well formed (low above 0, below high, high at most 1) and that a bracket moved from the authoring bracket the record states carries a dated revisit line in the register recording a changed value. Its arms: a narrowed and a widened bracket, each with its line, hold; a moved bracket with no line fails; a malformed bracket fails; a record stating no authoring bracket reads unparseable (the vacuity control). The authoring ends are parsed from the record and never written in the tool | #8810 FM-1; the cost-unit record's Decision 8 (beat 1) | **APPLIED** — beat 5a |
| **DEV-31** | **The calibration label is read from the register's latest dated line.** DEV-12 settled that the label takes its pair count from the revisit lines. The conversion reads the latest dated seed or revisit line of the cost unit's gate-coverage register row (population `cost-unit-calibration-revisits`) and emits `calibration: sufficient` or `calibration: insufficient`; an unreadable register yields `calibration: unresolved`, and the figures are still computed. The register is a core standard, so the core conversion reads no release surface | DEV-12; #8717 D-5 | **APPLIED** — beat 5a |
| **DEV-32** | **Exit 4 is a row written with the unit unresolved; exit 3 is no row.** CD-1 replaces the design's exit 3 (the conversion failed, no row) with a written row whose unit is `not-run`, raw totals kept, and exit 4. Exit 3 now means the extractor or the write failed and no row exists. `--json` is refused with `--cost-row`, and every cost-row flag is refused without it, so the field mode's output and exit codes stay as they were | #8810 CD-1; #8717 C1 | **APPLIED** — beat 5a |
| **DEV-33** | **FM-6 resolved with the response-level count beat 3 adopted.** Beat 3 adopted `unevaluated_responses` (DEV-21), so each cell carries both sums, `lower_bound` is true when either is above zero, and an absent count makes its sum `null`. With a minimum schema of `2.0.0` only an injected store can lack a count, so CR-5 strips one from an injected record | #8810 FM-6; #8799 PR-1 (DEV-21) | **APPLIED** — beat 5a |
| **DEV-34** | **The conversion's self-test runs in CI until its allowlist rows are deployed.** The script-execution hook refused the self-test by its repository-relative path (`BLOCK-DESTRUCTIVE-022`): the deployed allowlist carries no form for a script this beat adds, and the rows the beat adds reach it only at deploy. No permitted form existed, so the refusal stood. The finops-selftest job ran the self-test green on the slice's head, and the velocity tool's allowlisted self-test drives the conversion's `--convert` and `--params` paths locally | the Hook-Response Discipline; § Verification Evidence → Beat 5a | **RECORDED** — beat 6's new script meets the same refusal |
| **DEV-35** | **Beat 5b is held: the merged placement standard admits no session write into the main checkout's `/local-state/` yet.** The brief's condition holds — placement-rules-and-adr merged — but the standard it merged names preconditions 5b's design did not, and they are unmet on `origin/main`: `/local-state/`, its README and ignore-rule pair and the commit guard come from the in-repo-home-is-guarded milestone; `/local-state/` joins the main-checkout carve-out hook's static set only in the worktree-sessions slice, "and until then no session writes `/local-state/` in the main checkout"; a home is provisioned by the installer, never by its first writer; and a new surface takes a register row in the placement standard, which this matrix does not carry. D-HomeAnchor (A) anchors the default home on the main checkout and phase 6.65 writes it from a spoke session, so the default home (C1), the phase (C17) and its stage text (C18) cannot ship as designed. The token rows (C13–C16, C19) and an ignore rule (C12) could land alone, but would register a home no session may write, and the token would take the merged naming rule's class segment rather than the design's fallback spelling | the merged placement standard: § Registered in-repo git-ignored homes, § New-surface checklist, § Path-token naming rule; #8717 D-6, D-7 | **HELD** — an operator decision, carried on the sub-task #8725 output |
| **DEV-36** | **Beat 5b lands its registration rows only, under the operator's D-5b = B.** The token, its resolver and value pin, its `[paths]` key and declaration, its §4 row and the narrower ignore rule land in the design's order: C13–C16 with C19 in one commit, then C12. The default home on the cost-row mode (C1's 5b half), the close-out phase (C17) and its stage text (C18) stay held under DEV-35. They write the main checkout's `/local-state/`, which no session may do until the worktree-sessions slice and the `/local-state/` home land, so `--out-dir` stays required. Their two File Change Matrix rows stay declared for the Stage-9 D-5b-residual decision. Until then, this release's own Stage-13 row is written by the hub with an explicit `--out-dir` into the install-scoped telemetry home (D-5b-Stage13), not by the close-out phase § Delivery Strategy names. Beat 5b landed before beat 6, so beat 6 appends its resolver and test case after this beat's (§ Contention Map) | Decision Recorded on #8725 (D-5b = B, the operator's answer) | **APPLIED** — beat 5b |
| **DEV-37** | **The surface register gains a row of its own, S-45, and the placement standard joins the File Change Matrix.** The matrix carried no register row, and the placement standard's new-surface checklist requires one (Step 2). S-06 is not extended. Its class is Working state, install-scoped, and the standard's Class-column rule makes the token registry's Class cell repeat the class of the register row that names the token, so a working-state token in S-06's row would contradict its own class segment. Step 2 also makes a new subfolder of a registered home a row of its own. S-06's derived-row note stays as written, and no References bullet is added | Decision Recorded on #8725 (D-5b = B names the register row); the placement standard's § Surface register, § New-surface checklist Step 2 and § The token registry's Class column | **APPLIED** — beat 5b; § File Change Matrix, § Per-card write sets |
| **DEV-38** | **The token takes the merged naming rule's class segment.** It is `<OPERATOR_INSTANCE_WORKING_STATE_TELEMETRY_PATH>`, with the key `operator_instance_working_state_telemetry_path`, its exact lowercase, in place of D-6's provisional spelling. The class is Working state, admitted under the admission test's derived-row clause. The resolver keeps the design's name, `pmo_telemetry_path_for`, with two declared tiers: the key, else `<workspace-root>/pmo-platform/local-state/telemetry`. It has no environment tier, and the instance-container override does not relocate it | the placement standard's § Path-token naming rule and § The admission test; #8717 D-6 | **APPLIED** — beat 5b |
| **DEV-39** | **The declaration's `since` is provisional: `5.08`, the allocator's dry-run answer at this beat.** The plan's provisional `v5.02` has since been claimed by another release. The Stage-12 executor re-reads it against the claimed version and edits the one value if the slot moved, as the placement-rules-and-adr release did for its own key | Stage-6 B3 (minor adjustment); § Risk Register R6 | **RECORDED** — a Stage-12 re-verify item |
| **DEV-40** | **Stated counts are reconciled on lines this beat edits, AC-3's method is refined, and the manifest names the hook-tier copy.** The §4 canonical-defaults paragraph's "the two in-repo homes" now reads "the in-repo homes". The resolver test's Case-6 comment counts three codified tokens with in-repo defaults, not two. The resolver lib's toml-reader comment names the new caller. AC-3's method takes the worktree-root form #8810 FM-2 asks for, with the literal row path; run from the main checkout before its post-merge sync, it reads 1 by construction. `lib-instance-path.sh` is also published byte-exact into the deployed hook tier, so the Operational Deployment Manifest gives it the hook-bundle convention's default disposition, (a) propagate, in place of "none required" | reconcile-not-annotate; #8810 FM-2 (the Per-AC table); the Stage-12 hook-bundle propagation convention | **APPLIED** — beat 5b; § Verification Plan, § Operational Deployment Manifest |
| **DEV-41** | **#7945 AC-3 is graded against its amended routing clause.** Under the filing-threshold ruling Mode C holds every promotion candidate at every dial, so the criterion now reads "routed through `intake-desk` Mode C (Ambient Auto-Log), which records each held below the filing threshold; the operator promotes". The privacy clause and the criteria count (4) are unchanged. The Verification Plan's AC-3 row now names an observable that can fail: the report's `## Routing outcomes` table, one row per Mode C record carrying the verdict Mode C returned, so a malformed record, a skipped hand-off or another verdict shows. | Collective Review PA-016 (CD-3 of #8819); the hub's criterion amendment on #7945 | **APPLIED** — § Verification Plan |
| **DEV-42** | **The ranker landed in one commit, and its CI wiring landed with it.** The design's order ran the lib resolver, the fixtures, the ranker, then the allowlist and CI, then SKILL.md and the framework. The ranker can execute only in CI until its allowlist rows are deployed (`BLOCK-DESTRUCTIVE-022`, as DEV-34 recorded for the conversion), so its `finops-selftest` loop entry, the four allowlist forms and the probe and parity steps shipped in the ranker's own commit; a head nothing runs would have proven nothing. CD-1 to CD-4 landed in that commit too, not as separate slices. Privacy came first in the evidence instead: each privacy control was shown failing before passing by a CI precision probe that plants its defect in a throwaway copy (P1 the default class, P1b the closed flag class, P1c the interpreter-flag class), beside the unmutated self-test in the same job run. | Stage-6 B3 (minor adjustment); the brief's privacy-first order | **APPLIED** — beat 6; § Verification Evidence → Beat 6 |
| **DEV-43** | **CD-2 step 4 is a clamp, not a calibration.** A segment whose predicted re-reads exceed its measured cache reads is scaled down to them. Each bound's violations are counted (`coverage.cost_bound_violations`), and above 5 % of segments, a [RECOMMENDED] start, the cost status reads `degraded`. Of the two options, only the clamp could be proven from fixtures without a live run; calibrating the result side on context growth needs live readings and a second constant, so it is a follow-up candidate. | the brief's step-4 call; #8819 CD-2 | **APPLIED** — beat 6 |
| **DEV-44** | **Two readings of the design changed in the self-test.** The masked-program fingerprint is not rendered: variants show `<CODE>` and `<HEREDOC>`, which settles the review's cosmetic finding the way the design's header invariant states, and arm 1's variant pattern reads them. Probe P2 expects the runtime canary's refusal, not the near-miss arm: every run replays the near-miss fixtures before it reads anything, so a floor of one fails there first. The self-test carries 23 arms against the design's 15, because the counter-designs and failure-mode mitigations each added one. | #8819 (the cosmetic finding, FM-1, CD-2 to CD-4, FM-2 to FM-5); Stage-6 B3 | **APPLIED** — beat 6 |
| **DEV-45** | **The SKILL.md change is one section of the ranker's own.** The brief bounds the skill edit to the ranker's own section. So the CLI, the exit codes and the dependencies sit inside `## Promotion-candidate ranking`, as the conversion's section carries its own. The design's edits to the shared Scope line, Usage, Dependencies, Read-only posture and the skill-wide exit-code rows are not made. Three failure modes are appended to the skill's list. The description and `version:` lines are untouched; beat 7 stamps the version. | the beat-6 brief; the conversion section's precedent (beat 5a) | **APPLIED** — beat 6 |
| **DEV-46** | **Fixtures A and C carry a fabricated non-home path.** The PII pre-commit guard refused the first commit of the fixtures: its always-block tier admits no macOS-shaped home path into the tracked corpus, and it has no fixture marker. Its bypass is the operator's alone, so the design's macOS home (H_A) became a non-home path holding the same leak literal. B's Linux-shaped home (H_B) is unchanged and still exercises the home shape. The cost oracle follows the new lengths: output 976/3, rounded half-up to 325; cache write 364 (91 one-hour, 273 five-minute); cache read 1456. | the Hook-Response Discipline (a different action, recorded under Control firings) | **APPLIED** — beat 6 |
| **DEV-47** | **FM-4, CD-5 and PR-6 as dispositioned.** The ranker resolves the workspace root in four steps — `WORKSPACE_ROOT`, then `CLAUDE_WORKSPACE_ROOT`, then `operator.toml`'s `claude_workspace_root`, then the default — and the checkout through `PMO_SRC_ROOT`, its own checkout, or `<root>/pmo-platform`, else exit 2. The root arm covers the root that is set only in `operator.toml`. `pmo_telemetry_path_for` is unchanged (Case 8 pins it), and the single shared root helper is held. CD-5 takes option (b), a standing parity step in the `finops-selftest` job; option (a), one core definition, is held. PR-6 (`[adapters].ai_tool`) is held. A same-day re-run takes `command-template-ranking-run<N>-<date>/`, which keeps the analysis standard's `<name>-YYYY-MM-DD/` form. | the beat-6 brief (FM-4 mitigations 2 and 3, CD-5 (b), PR-6 held); the hub's held follow-ups for the Stage-13 filing step | **RECORDED** — beat 6 |

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
- **#8662** — the Stage-4 planning sub-task (plan, plan gate, scope-lock). **#8712–#8719** — the Stage-5 sub-tasks. **#8799 · #8800 · #8801 · #8809 · #8810 · #8812 · #8813 · #8819** — the Phase A6.5 adversarial reviews. **#8724** — the Stage-6 sub-task for #7940 (this commit). **#8721** — the Stage-6 sub-task for #7937 (beat 2). **#8722** — the Stage-6 sub-task for #7938 (beat 3). **#8723** — the Stage-6 sub-task for #7939 (beat 4). **#8725** — the Stage-6 sub-task for #7943 (beats 5a and 5b). **#8726** — the Stage-6 sub-task for #7945 (beat 6).
- **#8019 · #8022** — the worktree-sessions slice (the main-checkout carve-out hook) and the `/local-state/` home with its ignore rule and commit guard: the merged preconditions beat 5b waits on (DEV-35). The `/local-state/` home card should absorb beat 5b's narrower ignore rule (DEV-36). **#8020** — the resolver slice (one resolver per class), which should fold in `pmo_telemetry_path_for` (DEV-38).
- **#7934** — the token-efficiency thrust (epic). **#8051** — the successor card that composes MS-1. **#7854** — the outcome check whose criteria use the unit. **#7536** — the weekly-allowance axis that adopts the unit. **#7942 · #7936 · #7950 · #1494 · #8049** — downstream and related cards named in the graph and the specifications.

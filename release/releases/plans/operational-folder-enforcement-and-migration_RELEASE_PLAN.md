---
title: Release Plan — operational-folder-enforcement-and-migration
purpose: Stage-4 release plan for the corpus half of the operational-folder enforcement bundle.
type: release-plan
status: ACTIVE
reversibility: EXPENSIVE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->

# Release Plan — `operational-folder-enforcement-and-migration`

## Header

| Field | Value |
|---|---|
| Milestone | `operational-folder-enforcement-and-migration` |
| Version | **Not claimed.** Rule-computed at Stage 12 per `claim-version.sh`; bump class **minor**, identity **slug-only** per ADR-092. Mainline is `v4.33`. **D-38** sequences this milestone AHEAD of `migration-protocol-and-skill-integration`, so this release claims first — but the number binds at the atomic claim, not here. |
| Release Class | `novel` — `class_weight` 1.15 (`core/config/platform-config.toml.template` `[bundling].release_class_capacity_weights`) |
| Raw points | **20** — #5668 `size:M`=4 · #3123 `size:L`=8 · #5741 `size:L`=8 |
| `effective_pts` | **23** — `round_half_up(20 × 1.15)`. In band (15–25), **2 points of headroom**, **no override taken** |
| Branch topology | **SINGLE** — one branch, one PR, one merge gate |
| Concurrency | Stage 6 **fully serial (P0)**. Forced build order `#5668 → #3123 → #5741` is load-bearing, not a convenience — see the Contention Map |
| Baseline | `origin/main` @ `e4052fec` (*Merge pull request #5749*), 2026-08-20 |
| Provenance | Split from the original six-card bundle at Stage 5 exit, operator decision **D-37**. Scope-locked at **D-47** — the sixth scope-lock event on this milestone and the first to pass |

## Scope

**Outcome.** The node-frontmatter classifier becomes aware of the ADR-080 five-bin project taxonomy so that files in a modern project stop orphaning; the operational corpus is then backfilled with node frontmatter against that corrected classifier; and conformant Project, Person and Portfolio entity records are seeded into the corpus so that a downstream completeness score measures a non-empty population.

**Out of scope.** The skill and protocol half — the migration-enforcement protocol, `project-initiator` intake wiring and bin orientation cards, and the `health-check` `structure` mode — ships in `migration-protocol-and-skill-integration`. That milestone does not enter Engineering until this one deploys (**D-38**).

**Two of the three cards mutate the git-ignored Layer-2 operational corpus.** That mutation is not deliverable through this PR's diff and is not reversible by `git revert`. Each corpus-writing card's PR-side gradeable artifact is an **evidence record** committed into this plan file; the corpus write itself is a Stage-12 action executed from an operations-rooted session. The Rollback Strategy states the two paths as independent, because they are.

## Card Labels

| Card | Size | Type | Cluster |
|---|---|---|---|
| #5668 | `size:M` | `bug` | `cluster: architecture` |
| #3123 | `size:L` | `type:task` | *(no cluster label)* |
| #5741 | `size:L` | `type:task` | `cluster: process-protocol` |

All three carry `project:project-data-architecture` and `status: bundled`. Membership was read directly from the milestone at planning time: three delivery cards, plus the release-scoped and per-card sub-tasks.

## Dependency Graph

```
#5668 ──HARD──▶ #3123 ──SHARED-CLAUSE──▶ #5741
  (classifier          (agent-processing-contracts.md:170
   union-awareness)     — D-44, #3123 owns the line)

External, DOWNSTREAM:
  #5741 (seed entity records) ──▶ #158 AC-3
    in milestone migration-protocol-and-skill-integration
    (that milestone waits on this one — D-38)
```

**Internal order: `#5668` → `#3123` → `#5741`. Acyclic, and forced.**

**The `#5668 → #3123` edge is a hard build edge.** #3123's own body states its steps 1–3 do not start until #5668 merges, and its AC-1 restates that as a gate. Backfilling the corpus against a classifier that orphans every file in a five-bin project would write the wrong answer at scale.

**The `#3123 → #5741` edge is a shared-clause edge, not a build dependency.** Both cards replace the same single line whole. It is recorded here because under single-branch serial commits it has no mechanical enforcement — see D-44 in the Contention Map.

## Implementation Sequence

Single branch, serial commits, in dependency order.

| Commit | Card | Deliverable |
|---|---|---|
| 0 | — | Branch cut; contention sweep re-run against the merge base; **`D-5668-OPTION` resolved** (Y1 vs Y2) and any fired conditional rows promoted; **`D-48-ROUTING` resolved** and rows 7–8 either dropped or promoted; **package-rebuild ownership confirmed** |
| 1 | #5668 | Classifier union-awareness: the five-bin map, sub-bin table, exclusion sets, walk / extractor / tier / call-site changes, self-test extension, docstring cascade |
| 2 | #3123 | Node-frontmatter backfill: the `_superseded` member and self-test extension, the D-12 non-bin-sentinel tier across five schema and governance surfaces, the ADR, and the Part-A evidence record |
| 3 | #5741 | Entity-record seeding: the `project-schema.md` §3b block and §7 seeding protocol, the V-CORE-03 amendment plus its presence guard, the ADR, and the Part-A evidence record |
| 4 | — | `project-initiator` package rebuild + hash, executed and diffed **in the PR** (the CI gate does not block — see the Verification Plan) |

**Commit 0 is not ceremony.** Three decisions are genuinely open at plan time and each one changes the matrix: the #5668 option fork, the D-48 routing, and package-rebuild ownership. Each is named in Operator Decisions Recorded with its fallback.

**Why the order cannot be relaxed.** #5668 must precede #3123 because the backfill reads the classifier. #3123 must precede #5741 because #3123 owns the contested line at `core/schemas/agent-processing-contracts.md:170` and #5741 re-authors against #3123's version of it. Reordering does not make the second constraint go away; it inverts who silently overwrites whom.

## File Change Matrix

Path-first columnar form with an explicit intent verb on every row, per the FCM authoring contract. A marker-less path is `unknown`, never `edit` — no row below is marker-less.

```
# ── #5668 — classifier union-awareness (Commit 1) ──
core/deploy/tools/stamp-node-frontmatter.py                               edit
core/deploy/tools/backfill-relationship-edges.py                          edit

# ── #3123 — node-frontmatter backfill (Commit 2) ──
core/deploy/tools/stamp-node-frontmatter.py                               edit
core/schemas/frontmatter-schema.md                                        edit
core/schemas/sqlite-index-schema.md                                       edit
core/schemas/agent-processing-contracts.md                                edit
core/governance/OPERATIONS.md                                             edit
operations/skills/project-initiator/SKILL.md                              edit
operations/templates/project-md-composed-index-template.md                edit
core/ADRs/ADR-*-project-root-is-a-non-bin-sentinel.md                     add
release/releases/plans/operational-folder-enforcement-and-migration_RELEASE_PLAN.md   edit

# ── #5741 — seed conformant entity records (Commit 3) ──
core/schemas/project-schema.md                                            edit
core/schemas/entity-field-schemas.md                                      edit
core/schemas/frontmatter-schema.md                                        edit
core/schemas/agent-processing-contracts.md                                edit
core/ADRs/ADR-*-project-entity-axis-1-carrier.md                          add
release/releases/plans/operational-folder-enforcement-and-migration_RELEASE_PLAN.md   edit

# ── #5741 — CONDITIONAL:D-48-ROUTING (retained here only if the sibling milestone declines) ──
operations/skills/project-initiator/SKILL.md                              edit    CONDITIONAL:D-48-ROUTING
operations/templates/project-md-composed-index-template.md                edit    CONDITIONAL:D-48-ROUTING

# ── Package rebuild (tool-generated; triggered by #3123's SKILL.md edit at Commit 2) ──
packages/project-initiator.skill                                          edit
packages/project-initiator.skill.sha256                                   edit

#### Read-only inputs
core/disciplines/project-entity-model.md                                  READ
core/specs/health-check-specification.md                                  READ
core/config/allowlists/script-execution-allowlist.txt                     READ
operations/templates/project-bins/                                        READ

#### Release-wide explicit non-scope
core/hooks/block-fs-boundary.sh                                           NOT EDITED
core/hooks/block-autonomy-ceiling.sh                                      NOT EDITED
core/schemas/portfolio-writeback-contract.md                              NOT EDITED
operations/skills/health-check/SKILL.md                                   NOT EDITED
operations/skills/file-router/SKILL.md                                    NOT EDITED
```

### Per-row measurement

Every figure below was measured by the owning card against a built prototype or a counted draft, not estimated. Line counts are **point-in-time** and are re-derived at Stage 6 against the merged branch.

**#5668 — 2 files, 0 new, `+220 / −18`**

| Path | Region | Δ | Note |
|---|---|---|---|
| `core/deploy/tools/stamp-node-frontmatter.py` | five-bin map + sub-bin table, exclusion sets, walk / extractor / `_classify_type` / tier / call site, self-test, module docstring | `+193 / −18` | Unconditional under both options |
| `core/deploy/tools/backfill-relationship-edges.py` | binding + tier + self-test arm | `+27 / −0` | **Option-dependent — see `D-5668-OPTION`.** This row is the card's only second file and 12% of its diff |

**#3123 — 9 files, 1 new, `≈ +355 / −14`**

| Path | Region | Δ | Note |
|---|---|---|---|
| `core/deploy/tools/stamp-node-frontmatter.py` | the `_superseded` exclusion member, docstring cascade, self-test extension and in-process assertion | `+78 / −5` | **Contended with #5668 on the same file.** Commit order resolves it: #5668 at 1, #3123 at 2. The card's own analysis expects a real merge inside `classify()` |
| `core/schemas/frontmatter-schema.md` | `:197` — Category 6 Classification, the `folder` enum row | `+1 / −1` | Structural blast radius; 81 first-order readers |
| `core/schemas/sqlite-index-schema.md` | column comment | `+1 / −1` | No CHECK constraint to alter |
| `core/schemas/agent-processing-contracts.md` | `:170` — the Skill-6 `Writes` row | `+1 / −1` | **D-44 — this card OWNS the line** |
| `core/governance/OPERATIONS.md` | non-bin-sentinel statement | `+1 / −1` | Governance file; governed path already discharged |
| `operations/skills/project-initiator/SKILL.md` | `188–194` — the born-entity-frontmatter block, 6-field → 7-field | `+8 / −4` | Skill edit ⇒ package rebuild + `pmo-skill-editor` obligation + Check-7 exposure |
| `operations/templates/project-md-composed-index-template.md` | the born block and its `:13` explanatory comment | `+2 / −1` | Same claim as the SKILL.md row, on the mirrored surface |
| `core/ADRs/ADR-*-project-root-is-a-non-bin-sentinel.md` | new ADR | `+~100` | **Number NOT reserved here** — allocated at Stage 6 via `adr-helper` |
| this plan file | `## Node-Backfill Evidence Record` H2 | `+≥163` | The card's **only** PR-side gradeable artifact. Volume computed from measured table-row counts, not estimated |

**#5741 — 6 files unconditional (1 new), `+236 / −7`; 8 files with the conditional rows, `+245 / −13`**

| Path | Region | Δ | Note |
|---|---|---|---|
| `core/schemas/project-schema.md` | §3b entity-record block, §7 Entity-Seeding Protocol S1–S6, snapshot / mover / restore ordering, frontmatter `consumers:` and §8 row | `+65 / −1` | Largest single component |
| `core/schemas/entity-field-schemas.md` | V-CORE-03 rule text, §3.0 framing, V-PRJ-03 annotation, `NT-PRJ-5` — **plus the D-42 presence guard** | `+~5 / −4` | The highest blast-radius-per-line change in the release: all 19 entities inherit this rule set |
| `core/schemas/frontmatter-schema.md` | `:93` — Category 3 Provenance, the `id` row | `+2 / −1` | **Disjoint from #3123's row at `:197`** — 104 lines apart, different categories. Verified, not assumed |
| `core/schemas/agent-processing-contracts.md` | `:170` — the Skill-6 `Writes` row | `+1 / −1` | **D-44 — re-authored at build time against #3123's landed version** |
| `core/ADRs/ADR-*-project-entity-axis-1-carrier.md` | new ADR | `+~100` | Allocated at Stage 6 **after** #3123's ADR exists on the branch, so `--next-free` does not return the same number twice |
| this plan file | Part-A evidence record + Stage-12 restore ordering + Tier-A declaration | `+64` | Second claimant on this file; append-pattern, distinct H2 |
| `operations/skills/project-initiator/SKILL.md` | `188–194` — the `:193` "born-aligned entity record" misnomer | `+6 / −4` | **CONDITIONAL:D-48-ROUTING** |
| `operations/templates/project-md-composed-index-template.md` | `:13–16` — inside the opening HTML comment | `+3 / −2` | **CONDITIONAL:D-48-ROUTING** |

### Matrix notes

**Shared-file note — four paths carry two claimants each.** `core/deploy/tools/stamp-node-frontmatter.py` (#5668 × #3123), `core/schemas/agent-processing-contracts.md` (#3123 × #5741), `core/schemas/frontmatter-schema.md` (#3123 × #5741), and this plan file (#3123 × #5741). Only the first two are collisions; the other two are shared files with disjoint regions. The Contention Map states each one's resolution.

**Conditional-promotion rule.** `D-5668-OPTION` and `D-48-ROUTING` resolve at or before Engineering Commit 0. A row left CONDITIONAL after its condition has fired is an authoring defect — promote it in that commit, carrying its concrete path. The converse also binds: if a row's declared condition turns out false and the file is edited anyway, promote it with the real basis recorded rather than leaving it shielded by a predicate that never fired.

**Package rows are declared here, not by either card.** Neither #3123's nor #5741's design carries a `packages/` row, yet #3123's own FCM note names the `.skill` rebuild, the `pmo-skill-editor` obligation and Check-7 exposure as consequences of its SKILL.md edit. The rows are added at the plan surface so the obligation is planned rather than rediscovered at Engineering. This is the plan's finding, not the cards'.

**⚠️ The automated FCM check reads only part of this matrix — bug #5757.** `release/tools/verify-release-plan.sh`'s `pathof()` matches declared paths against a closed prefix allowlist — `core`, `release`, `docs`, `packages`, `projects`, `roadmaps`, `.github`, `.claude` — that **omits `operations/`**. Read directly from the shipped tool at the release baseline. Every `operations/` row is dropped before classification, and a dropped row is **not** counted as `uninterpreted`, so the checker can report a clean parse over a matrix it only partly read.

**Measured against this matrix, and the reconciliation is exact.** Running the shipped extractor and `pathof()` over the fence above: **30 declaration rows · 23 parsed · 7 dropped**, and all 7 dropped rows are the `operations/` rows (`23 + 7 = 30`). Of the 7: **four are change-obligation rows** — #3123's two born-block edits and #5741's two conditional rows — and three are non-change rows (one `READ`, two `NOT EDITED`).

**Consequence for Stage 9.** **G-PR11's `fcm-delivery` verdict on this release is partial, not clean.** Both unconditional ADDs are `core/ADRs/` rows and both parse, so the ADD obligation itself *is* covered — the blind spot is entirely on the edit rows, and those are precisely the rows carrying the born-block contention. Until #5757 ships, grade the four `operations/` change rows by **direct diff inspection** against this matrix. Reading a `fcm-delivery` PASS as full coverage here would be a false green.

**And the executor cannot be run agent-side at all on this release.** `release/tools/verify-release-plan.sh` is **absent from the script-execution allowlist** — from the repo-source allowlist and from the deployed one. Attempting to run it is refused by the destructive-command hook as un-allowlisted subprocess execution. Sensitivity arm: the deployed allowlist carries 257 entries and does list sibling `release/tools/*.sh` scripts, so the absence is specific to this tool rather than a broken lookup. This is exactly the condition the Stage-4 script-execution companion obligation exists to prevent — a delivered script that is unrunnable agent-side on arrival. **Stage 9 must therefore treat the `fcm-delivery` verdict as unavailable, not as passing**, and grade the matrix by inspection until a row for this tool enters the allowlist.

**Not in this matrix, by construction.**
- **Neither corpus mutation contributes a row.** #3123's backfill and #5741's seeding both target the git-ignored Layer-2 operational corpus, outside the repository. Their PR-side gradeable artifacts are the two evidence records declared above.
- **Close-out artifacts** — `CHANGELOG.md`, `.version`, the release log, index and digest, and the release notes — land via the Stage 13 close-out chore PR, not this PR. Declaring them here would register a delivery obligation this PR's merged diff cannot satisfy.
- **No new executable scripts**, so the `script-execution-allowlist.txt` companion obligation does not fire. The allowlist is declared READ because both corpus writers invoke already-allowlisted tools.

**`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-21, domain: governance }`** — every row is an internal platform artifact: two deploy tools, five schema and governance surfaces, one skill definition, one template, two ADRs. Dominant domain **governance**; secondary **software** (the two Python tools). Sourcing-exempt, domain-classified.

## Contention Map

| File | Claimants | Order | Resolution |
|---|---|---|---|
| `core/deploy/tools/stamp-node-frontmatter.py` | #5668, #3123 | 1 → 2 | **Serialize.** Both edit `classify()`; #3123 adds a positional tier where #5668 restructures. Expect a genuine merge, resolved by the author of commit 2 |
| `core/schemas/agent-processing-contracts.md` `:170` | #3123, #5741 | 2 → 3 | **D-44 — #3123 owns the line; #5741 re-authors one line at build time.** See below. This is the release's highest-risk item |
| `core/schemas/frontmatter-schema.md` | #3123 (`:197`), #5741 (`:93`) | 2 → 3 | **No conflict.** Different field categories, 104 lines apart. Composable in either order |
| this plan file | #3123, #5741 | 2 → 3 | Append-pattern, distinct H2 headings. No coordination cost |
| `core/ADRs/` allocation | #3123, #5741 | 2 → 3 | **Allocate in commit order, never pre-reserve.** #5741's Stage-6 `--next-free` must run against a branch state that already contains #3123's ADR file, or both take the same number |
| `operations/skills/project-initiator/SKILL.md` `188–194` | #3123, #5741 *(conditional)* | 2 → 3 | Resolved by `D-48-ROUTING`. If #5741's rows route out, #3123 is the sole claimant. If they are retained, the D-44 re-authoring discipline extends to this hunk too |
| `operations/templates/project-md-composed-index-template.md` `:13–16` | #3123, #5741 *(conditional)* | 2 → 3 | As above |

### D-44 — why the `:170` collision is not solved by ordering

`core/schemas/agent-processing-contracts.md:160` opens `## Skill 6: Project Initiator`; `:170` is that table's `Writes` row — a single inline emit list. Verified against the tracked file at the release baseline, not inferred from either design. Both cards append a key to that list and both measure their change as `+1 / −1`: each is a **whole-line replacement** of the same baseline line.

**Under parallel branches this would raise a git merge conflict** — loud, and impossible to miss. Under single-branch serial commits there is no merge machinery between the two. #5741's hunk was measured against `origin/main`, i.e. pre-#3123. Applied literally at commit 3 it whole-line-replaces and **silently reverts #3123's key** — no conflict marker, no failing check, and the resulting line still looks well-formed.

**Sequencing therefore converts a loud failure into a silent one.** The forced order is a necessary condition for the fix, not the fix itself.

**The binding instruction for Stage 6:** at commit 3, #5741 adds its Axis-1 carrier key to **#3123's landed version of `:170`**, rather than applying its own baseline-authored hunk. Both keys land. Cost: one line of build discipline and this note. No new scope. **CIAC-2 grades the result.**

**Why nobody caught this in three rounds.** Both designs reference each other heavily — but every one of their cross-references is about the Layer-2 corpus, snapshot ordering, ADR-number allocation or build sequence. A probe for a claimant declaration naming a *tracked-repo file* returns **0** in both directions, against a sensitivity arm of **3** for the same probe shape on #3123 × #5668. The two cards coordinated carefully on one axis and never ran the check on the other. That is a structural gap in the adversarial-review brief, not a lapse by either card.

## Integration Points

| # | Seam | Cards | Contract |
|---|---|---|---|
| INT-1 | Corrected classification consumed by the backfill | #5668 → #3123 | #5668 makes the five-bin taxonomy resolvable; #3123 backfills against the corrected classifier. **HARD** — #3123's steps 1–3 do not start until #5668 merges |
| INT-2 | The Skill-6 emit contract carries both new keys | #3123 → #5741 | #3123 owns `agent-processing-contracts.md:170`; #5741 re-authors against its landed state. Graded by **CIAC-2** |
| INT-3 | Seeded records are valid against the amended rule set | #5741 internal | The V-CORE-03 amendment in `entity-field-schemas.md` is the prerequisite for the seeded records being valid rather than valid-by-agreement-with-one-consumer. The amendment must land in the same commit as the seeding protocol |
| INT-4 | Entity records exist before a completeness score is meaningful | #5741 → #158 (**external**) | #158 lives in `migration-protocol-and-skill-integration`. **This milestone ships first (D-38)**; that one does not enter Engineering until it deploys. Nothing is graded here |

## Cross-Issue Acceptance Criteria

Two cohesion constraints span two or more cards. Graded at Stage 9 QC3.5 / Phase A3.6 on the merged PR. Distinct from the per-issue-pair `INT-N` authored at Stage 5.

- [ ] **CIAC-1 (sixth form) — #5668 × #3123, graded on the classifier's structured output.**
  1. **Census, not a scalar.** A post-merge `--dry-run --scope active --output-format json` run is read for the `orphans` array, and the **distribution of orphan reasons** is compared against the expected class set declared below. The criterion asserts *which classes remain and why*, never a bare count.
  2. **Every remaining orphan class has a named disposition** — owned by a card in this release, or recorded as accepted-residual with a next-release owner. A class with no disposition is a FAIL.
  3. **Exclusions are reported, not prohibited.** Every exclusion introduced by any card is listed with its measured Δ on the orphan population. The criterion does not forbid exclusions; it forbids **undeclared** ones. An exclusion present in the diff and absent from the report is a FAIL.
  4. **Probe validity is mandatory.** Counts are read from structured JSON, never grepped from a reason string. The same invocation against the pre-fix tool must yield a materially different census. A census whose sensitivity arm is identical is a broken probe, not a clean corpus.

  *Shared surface:* the classifier's `classify()` structured output and the counts recorded in #3123's evidence record. *Graded at Stage 9 QC3.5 on the merged PR.*

  **The expected orphan-class declaration (CIAC-1 clause 1).** Measured over 97 live orphans at the pinned anchor:

  | Class | Claimant | Disposition |
  |---|---|---|
  | File inside a five-bin project | #5668 | Fixed in-release by the classification union |
  | Cross-project staging tier | #5668 | Excluded in-release |
  | `_`-prefixed top segment | #5668 | Excluded in-release |
  | Free-text folder segment in a legacy project | #5668 (per **D-38**) | Claimed in-release. **See the reconciliation note below** |
  | Project-root governance file at depth 2 | #3123 | Fixed in-release by the non-bin-sentinel tier |
  | **Depth-1 corpus-root file** | **NONE** | **Accepted-residual, next-release owner.** Program-scoped operational config, not project content — it should never have been a node candidate. Correct long-run home is the non-project-top-segment tier |

  **Expected residual: exactly ONE orphan.** Not zero. The `orphans == 0` premise that three cards were carrying is retired.

  **Reconciliation note (D-38), stated because it is a join across two measurements.** A census run recorded five unclaimed orphans; a prior decision had, eleven hours earlier, assigned four of them to #5668's scope, and the census was joined against the claimant table as it stood before that assignment. `5 − 4 = 1`. Corroborated three ways: the earlier decision's recorded purpose is verbatim to claim those four files; a later justification table already carries that class at orphan-Δ `+4`; and the owning card's own round-2 reconciliation states it took ownership of the class. Nothing was mis-measured — the census was joined against a stale table. **The residual of 1 stands, and it is re-derived at Stage 6 and again immediately before the Stage-12 write.**

  **The `D-5668-OPTION` fork does not move this declaration.** The two options' excluded-set delta under `--scope active` — the scope CIAC-1 grades — is measured **0 / 0**. The 15-file divergence between them appears only under `--scope all` and sits entirely under an archived top segment. The census is therefore invariant to that decision.

  **Stated so it can be falsified rather than assumed:** this form fails if the expected-set declaration above goes stale — if a card changes its orphan classes without updating this table. That is a real exposure, it is the one to watch at Stage 9, and it is the failure mode this shape cannot rule out.

- [ ] **CIAC-2 — #3123 × #5741 on `core/schemas/agent-processing-contracts.md:170`.** The merged Skill-6 `Writes` row carries **both** new keys: #3123's non-bin folder sentinel **and** #5741's Axis-1 carrier. Neither card's key is absent, and the row is well-formed as a single emit list. *Shared surface:* the `| **Writes** |` row of the `## Skill 6: Project Initiator` table. *Method:* extract that row from the merged file and assert both key tokens are present in it. **Control arm:** the identical extraction against the release baseline must return the row carrying **neither** key — a pass that also passes on the baseline is a broken probe, not a clean merge. *Graded at Stage 9 QC3.5 on the merged PR.*

  **Why this criterion exists.** It is the only gate that can catch the D-44 silent revert. There is no merge marker, no failing check and no lint that fires when commit 3 whole-line-replaces commit 2's version of this row. A reviewer reading the final line sees a well-formed emit list either way.

## Verification Plan

### Per-Issue Verification

| Issue | AC | Predicate class | Verification Method | Expected Result |
|---|---|---|---|---|
| #5668 | AC-2 | file-state | Run the tool's shipped `--self-test` on the merged branch | Exit 0; the five-bin classification arm passes |
| #5668 | AC-6 | file-state | Assert the program-scoped-config path appears in `excluded` with its non-project-top-segment reason, and appears in neither `orphans` nor `would_stamp` | Present in `excluded`; absent from both other arrays |
| #5668 | AC-11 | file-state | Run the sibling edge planner over the subject file set and compare planned-edge count against the control population | 0 edges over the excluded set; control population unchanged |
| #3123 | AC-1 | file-state | Grep the merged tool for the orphan-reason token AC-1 asserts — **restated per DR-R3-1**, because the literal the original AC greps is one #5668 deletes | The restated token resolves; the retired literal is absent by design |
| #3123 | AC-4 | runtime-suite | Re-run the card's stated sampling expression against the post-write corpus and read the pass rate | ≥ 95% on the drawn sample, with N and N/`would_stamp` both stated |
| #3123 | AC-8 | file-state | **Restated per DR-R3-2.** Assert the pre-write snapshot exists, is complete, and a restore has been demonstrated — **not** that a `--strip` flag is present | Snapshot verified restorable before the write is authorized |
| #3123 | — | integration | The CIAC-1 census above, read from structured JSON with its sensitivity arm | Census matches the declared class table; residual 1 |
| #5741 | V-CORE-03 | file-state | Assert the amended rule resolves the Axis-1 carrier for all 19 entities, and that the separate presence guard for the Project entity is present | 19/19 resolve; presence guard present |
| #5741 | `NT-PRJ-5` | runtime-suite | Re-run the card's declared negative test against the amended rule set | Passes as declared, with the D-42 residual recorded rather than silently satisfied |
| #5741 | seeding | declared, verification deferred to the Stage-12 evidence record | The corpus write is not readable from the PR diff; the gradeable artifact is the Part-A evidence record committed to this plan | Evidence record present, internally consistent, counts re-derived at write time |
| #3123, #5741 | — | integration | CIAC-2 above, with its baseline control arm | Both keys present in the merged `:170` row |

### Release-Level Verification

Authored as a list rather than a table **deliberately**: the per-issue table above is machine-read row by row, and a second table inside the same section is parsed with the first table's column map, injecting malformed check records. These four are release-scoped obligations, not per-issue checks, and they are graded by the Stage-6/7 executor's own regression and sync families rather than from this list.

- **Regression —** `pmo-skill-editor` regression pass, run **once against the final combined state** of `project-initiator/SKILL.md`. Applies to #3123, plus #5741 if `D-48-ROUTING` retains its rows. Running it against an intermediate state grades a file that will not ship.
- **Regression —** both deploy tools' shipped self-tests green on the merged branch. Applies to #5668 and #3123; both tools are already in the self-test coverage manifest.
- **Sync —** `project-initiator` package rebuilt and hash-matched to source, at Commit 4. **See the gate-coverage caveat below.**
- **Regression —** the deploy check suite green, including package freshness and byte-identity.

**Gate-coverage caveat, stated rather than implied.** The `.github/skill-package-freshness.enforce` sentinel carries the token `warn`, read directly from the tracked file at the release baseline. In `warn` mode a stale `.skill` package is reported with a non-zero advisory exit code but **does not block the merge** — it fails later, at deploy time. #3123's SKILL.md edit makes the package stale by construction, so **the rebuild-and-diff must be executed inside the PR** rather than deferred to the gate. Grading the package obligation against a gate that ships non-blocking would be a false pass.

## Risk Register

| # | Risk | Sev | Owner | Mitigation | Reversibility |
|---|---|---|---|---|---|
| R1 | **The `:170` silent revert (D-44).** Commit 3's baseline-authored hunk whole-line-replaces commit 2's key with no conflict marker and no failing check | **HIGH** | Stage 6 | Re-author one line against landed state at commit 3; **CIAC-2 with a baseline control arm** is the only gate that can catch it | CHEAP to prevent · MODERATE to detect after merge |
| R2 | **Corpus drift is live and measured.** The stamp-candidate count moved 180 → 181 (Σ 2858 → 2859) mid-review with the tool byte-identical across anchors. Every count in the record is point-in-time; one member of the residual orphan class was **zero days old** when measured | **HIGH** | Stage 12 | **Re-measure every count immediately before any Stage-12 write** — this is AI-010 and it is a gate, not a note. Stage 6 re-derives against the merged branch; Stage 12 re-derives against the corpus at write time | N/A — measurement discipline |
| R3 | **The reverser assumed by earlier records does not exist.** #3123's AC-8 certifies reversibility against a `--strip` flag; a repo-wide search returns **0 occurrences** against a working sensitivity arm. The real reversal path is the pre-write snapshot (D-11, ~4.47 MB / 187 files) | **HIGH** | Stage 12 | **AI-006** — verify the snapshot is taken **and demonstrably restorable** *before* the corpus mutation is authorized, not after. A stamp written without a verified snapshot is unreversible by any designed path | **EXPENSIVE** |
| R4 | **#3123's two round-3 declines rest on a retired premise.** Both were argued on a "76% over ceiling" band figure that D-37 eliminated — the milestone is now at 23 of 25 with headroom | MED | Stage 6 | The declines may still hold, but must be **re-argued structurally** rather than on a band figure that no longer exists. Do not carry them forward unexamined | CHEAP |
| R5 | **#3123 AC-8 grades presence, not function.** Two code-verified defects against the snapshot artifact — the edge write-set is not obtainable from the tool's JSON, and the sidecar restore is a no-op on the mutated path — are **unanswered across all three design rounds**. Term census on the design comments: 19 → 0 → 0. The reviewer is explicit that this is silence, not rebuttal | MED | Stage 6 | Answer both defects on the record before the snapshot is relied on as the reversal path. R3 depends on this being real | EXPENSIVE if it fires |
| R6 | **#3123 T1 is unreachable by construction yet ships as a HALT-eligible gate that cannot fire.** Separately, the "ceiling 6 vs budget 9" argument compares a *population* bound to a *population* budget while AC-4 grades the **sample** — at K=6 the hypergeometric probability the sample fails is **17.3%**, which is precisely the after-the-snapshot Stage-12 hazard the bound was built to remove | MED | Stage 6 | Either make T1 reachable or retire it; re-render AC-4's bound against the sample rather than the population | MODERATE |
| R7 | **#5668 AC-6's restatement was dropped between rounds** while the sweep went one deeper on AC-2. Token census across the two design comments: the AC-6 restatement and its supporting finding appear 11× and 3× in round 2 and **0× and 0×** in round 3, while the underlying topic remains live (6 occurrences) — so the absence is specific to the criterion, not a probe artefact. The card's own selected option is recorded as failing AC-6's literal wording | MED | Stage 6 | Re-add the round-2 restatement verbatim. One line, zero code. AC-7 is the weaker twin of the same shape and should be checked with it | CHEAP |
| R8 | **#5668's differentiator books one population as both credit and defect.** The same 15 archived files are a credit in the reach ground and a defect in the failure-mode section; the protective population measures **0** and is unpinned. **Third recurrence of the same root cause in this release** | MED | Stage 6 | Reduce the differentiator to its one surviving ground (comment accuracy) and pin the protective population with a baseline, per audit-baseline discipline | CHEAP |
| R9 | **`D-48-ROUTING` is unresolved and its target milestone's plan does not name the regions.** Probed directly against that plan: the born-block token and all three region line-anchors return **0**, against sensitivity arms of 11 and 2 on the same document and a specificity arm of 0. The route-out is a stated intent that the receiving plan has not yet recorded | MED | hub | Rows 7–8 ship **CONDITIONAL**. **Fallback if the sibling declines: retain both rows in this release**, and extend the D-44 re-authoring discipline to both hunks — three re-authored hunks instead of one. In that case the "7-field entity block" versus "not an entity record" contradiction must be reconciled *within* this release | CHEAP |
| R10 | **The automated FCM check cannot see the `operations/` rows — bug #5757.** Verified at source and measured against this matrix: 30 declaration rows, 23 parsed, **7 dropped**, all `operations/`, four of them change obligations. Dropped rows are not counted as uninterpreted, so the checker reports a clean parse over a partial read | MED | Stage 9 | Grade the four `operations/` change rows by **direct diff inspection**. Do not read a `fcm-delivery` PASS as full coverage | CHEAP |
| R17 | **The plan-verification executor is not runnable agent-side.** `release/tools/verify-release-plan.sh` is absent from both the repo-source and the deployed script-execution allowlist; invoking it is refused by the destructive-command hook. Sensitivity arm: 257 deployed entries, sibling `release/tools/*.sh` scripts present — so the absence is specific, not a lookup failure. Compounding R10: the check that would partly cover the matrix cannot be executed at all | MED | Stage 9 | **Treat the `fcm-delivery` verdict as unavailable, not as passing.** Grade by inspection. An allowlist row for this tool is the durable fix and belongs to a separate intake item, not to this release's scope | CHEAP |
| R11 | **The package rebuild is undeclared by both card designs and its CI gate ships non-blocking.** #3123's SKILL.md edit makes the package stale; the freshness sentinel reads `warn` | MED | Commit 4 | Package rows are declared in this matrix; execute rebuild-and-diff **in the PR**. Confirm ownership at Commit 0 | CHEAP |
| R12 | **The V-CORE-03 amendment carries two measured defects, routed from a sibling milestone's card.** Its discriminator keys on one lexical form (`= Axis-1`) that matches **2** field rows against a control arm of **51** — the file's own named house-style exemplar uses a bolded form with no `=` and would be **silently mis-resolved**, yielding a false failure on every record of that type. Separately, one entity has no Axis-1 enum for the rule's membership limb to resolve against | MED | Stage 6 | Both fixes are zero-cost **at the amendment** and not zero-cost after it merges. Key on the per-entity Axis-1 restatement row instead — uniform 19/19. **This milestone ships first, so the defect would ship and the downstream consumer would inherit it** | CHEAP now · EXPENSIVE after merge |
| R13 | **D-42 residual — the amendment removes an enforcement path.** After it, a Project record *lacking* the carrier field **passes** V-CORE-03; the card's own negative test asserts exactly that as a PASS. Declared requiredness is unchanged; its enforcement path is removed for one entity | MED | Stage 6 | Keep a **separate presence rule** so the declared requirement retains an enforcement path. Costs about one line, and it stops the cheap path from depending on winning an interpretive argument at Stage 9 | CHEAP |
| R14 | **`D-5668-OPTION` is undecided and the cost column was never priced.** The design of record takes the two-file option; the counter-design achieves the same measured invariant with the sibling **unedited**, removing the card's only second file and 12% of its diff. The reviewer explicitly declines to assert the counter-design dominates — the operator has not seen the cost column | LOW | Commit 0 | Decide at Commit 0. **This is the one decision that does not move CIAC-1** — the two options' excluded-set delta under the graded scope is 0. Whichever way it goes, promote or drop the second row in that commit | CHEAP |
| R15 | **A release session rooted in the platform repo cannot write the operations corpus, and an operations-rooted session cannot commit its own evidence record back.** The cross-domain write block is Tier-0 and ignores the automation level in both directions | MED | Stage 12 | Both corpus writes execute from an **operations-rooted session**; the evidence records are **staged and handed off** for commit from the repo-rooted session. Never bypass the control. Sequence: #3123 writes, then #5741 | MODERATE |
| R16 | **Band headroom is 2 points, and two of three cards sit at `size:L` on judgment rather than arithmetic.** #5741's own design says plainly that `size:M` is the defensible volume-weighted alternative and that `size:L` rests on four character discriminators | LOW | hub | Any Stage-6 re-size **upward** triggers a re-bundle decision, not a silent override. Five overrides carried this milestone as high as 44 before the split; all five are retired and none returns | CHEAP |

## Delivery Strategy

Single branch, one PR, one merge gate. Stage 6 fully serial (P0) — three cards, three collisions, and a shared-clause hazard with no mechanical enforcement. Stages 5, 7 and 8 are parallel-eligible per card; Stages 6 and 13 are write-serialized. Stages 10 and 11 are **compressed** for git-native releases — the git history is the snapshot and the PR diff is the dry run — and their sub-tasks are created then immediately closed so the rationale has a durable home.

**The corpus writes are the exception to all of the above.** They are not git-native, not visible in the diff, and not covered by the merge gate. They execute at Stage 12 from an operations-rooted session, after a verified pre-write snapshot, in the order #3123 then #5741.

## Stage Applicability Matrix

| Stage | Applies | Note |
|---|---|---|
| 4 Planning | ✅ | this document |
| 5 Solutioning | ✅ | complete for all three; Phase A6.5 adversarial review run three rounds, re-reviewed 2026-08-21 |
| 6 Engineering | ✅ | fully serial; three commits plus the package rebuild |
| 7 Dev Testing | ✅ | parallel-eligible ×3 |
| 8 QA Testing | ✅ | parallel-eligible ×3. **#3123 and #5741 are partly ANOMALOUS** — their corpus deliverable is not readable from the PR diff; QA grades the evidence records |
| 9 Plan Review | ✅ | **Deep** review depth per `novel` class |
| 10 Dry Run | ⏭️ | compressed — PR diff is the dry run |
| 11 Snapshot | ⏭️ | compressed for the repo; **NOT compressed for the corpus** — the Layer-2 pre-write snapshot is a real, separate, load-bearing artifact (R3) |
| 12 Execute | ✅ | version claimed here; both corpus writes execute here |
| 13 Close | ✅ | 30-day outcome window per `novel` class |

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **0** (complete) · Stage 7: **3** · Stage 8: **3**
**Per-spoke cost estimate:** size-bucket ordinal band — worst batch = 1 × `low–moderate` (`size:M`) + 2 × `moderate` (`size:L`). Source: heuristic; no telemetry medians available, and no bucket meets the per-bucket cutover predicate.
**Assumed/stated remaining usage-window envelope:** **`UNSTATED`** — no operator quota state was declared at hub start; the conservative default applies.
**Estimated cumulative draw % (worst parallel batch):** **not rendered.** Per refuse-to-synthesize, a percentage here would be a projection of a band nobody stated, presented as a measurement. The basis is recorded as `UNSTATED` rather than a synthesized figure. `[ASSUMPTION – CONFIRM]`
**Routing:** **PASS — proceed parallel.** The worst batch is 3-wide at two stages, down from the pre-split 6-wide at three stages that returned WARN. Stage 6 is serial, so its commits draw sequentially rather than concurrently.
**Note:** Checkpoint A is advisory. The load-bearing gate is Checkpoint B, re-validated at **every** `Agent`-tool launch — wave or singleton, every stage — with PROCEED / SERIALIZE / DEFER / REDUCE-scope for a wave and the reduced PROCEED / DEFER form for a singleton. This is a usage-window budget, not a rate-limit problem: staggering is a secondary rate-limit-only defense and is never the mitigation for a window overrun. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

## Rollback Strategy

### Per-Issue Rollback

**Repo-side.** Every tracked file is git-tracked and each card's commit is revertible in isolation, in reverse dependency order (#5741 → #3123 → #5668). Package artifacts are regenerated, not hand-edited, so a revert plus a rebuild restores them. Reversibility **CHEAP · confidence HIGH**.

**Corpus-side — and this is the asymmetry that defines the release.** Two of the three cards mutate the git-ignored Layer-2 corpus. Neither mutation is touched by any `git revert`. Their only reversal path is the **pre-write snapshot** taken at Stage 12, restored against the same corpus root. The flag-based reverser that earlier records assumed **does not exist** — a repo-wide search returns 0 occurrences against a working sensitivity arm.

**Therefore the snapshot is a gate, not a precaution.** It must be verified taken **and demonstrably restorable** before either write is authorized. A corpus stamped without a verified restorable snapshot is unreversible by any designed path. Reversibility **EXPENSIVE · confidence MEDIUM** — medium because a restore has been specified but, as of plan time, not demonstrated.

### Whole-Release Rollback

Revert the merge commit. That restores every tracked surface — both deploy tools, five schema and governance files, the skill and template surfaces, both ADRs, and this plan — and leaves **both corpus mutations in place**.

**The two rollback paths are independent and must be briefed as such at Stage 9.** Reverting the PR without restoring the corpus snapshot leaves a corpus stamped by a classifier that is no longer in the tree. Whole-release reversibility is therefore **EXPENSIVE · confidence MEDIUM**, governed by the corpus limb, not the repo limb.

## Operator Decisions Recorded

| # | Decision | Verdict | Reversibility |
|---|---|---|---|
| D-37 | Bundle split on the corpus seam | Corpus half retained here; skill/protocol half moved to the sibling milestone. **All five prior overrides retired** | MODERATE · HIGH |
| D-38 | Orphan-census reconciliation **and** milestone sequencing | Residual unclaimed is **1**, not 5 — the census was joined against a stale claimant table. **This milestone ships first** | MODERATE · HIGH |
| D-40 | Pricing of the V-CORE-03 amendment | **Tier-2 + ADR pricing RETRACTED.** The cited precedent was falsified at source: it was a type lift plus a new field — two frozen limbs — where this change alters no type, adds no field and changes no cardinality. **4-line in-file amendment; no unfreeze, no ADR** | CHEAP · HIGH |
| D-41 | Are the two #5741 blockers independent? | **Yes — verdict ONE.** Narrowing the build rule closes one cleanly and does not remove the need to amend the rule | CHEAP · HIGH |
| D-42 | The enforcement-path residual | **Keep a separate presence rule** so the declared requirement retains an enforcement path. ~1 line | CHEAP · HIGH |
| D-43 → D-46 | Cross-card ownership collision | Adjudicated: **one hard collision, two conditional, three non-collisions.** The four-file framing was wrong in both directions | CHEAP · HIGH |
| D-44 | Ownership of `agent-processing-contracts.md:170` | **#3123 owns the line; #5741 re-authors one line at build time.** Not optional — see the Contention Map | CHEAP · HIGH |
| D-45 / D-48 | Routing of the born-block misnomer correction | **Route by region owner, not by card.** D-45's own commit condition was falsified — the named card owns neither region — so D-48 refines it: the template region to the card that already opens that file, the skill region to the card that writes it last | CHEAP · HIGH |
| D-47 | **SCOPE-LOCK** | **Three cards, `effective_pts` 23, in band, zero overrides.** Sixth scope-lock event; first to pass | MODERATE · HIGH |
| D-49 | Stage-9 visibility flag | **A hub decision overriding a card's own design must be visible at Plan Review rather than discovered there.** #5741's design of record recommends *absorb*; D-45/D-48 override it. Legitimate post-split — both absorb premises died with D-37 — and recorded here so Stage 9 reads it as a decision, not a defect | — |
| D-50 | Probe-validity method note | A first read of the planning issue returned 71 bytes with its sensitivity arm at 0 — a transport failure, not an empty result. Refetched via paginated REST. **Recorded as method:** a zero whose control arm also returns zero is a broken probe | — |

### Open at plan time — resolve at Engineering Commit 0

| Token | Question | Fallback if unresolved |
|---|---|---|
| **`D-48-ROUTING`** | Does the sibling milestone accept the two born-block regions? Its Stage-4 plan **does not yet name them** (verified: 0 against sensitivity arms of 11 and 2) | **Retain both rows in this release** and extend the D-44 re-authoring discipline to both hunks. The misnomer is pre-existing in the mainline, so deferring is debt, not regression — but retaining is the safe default when the receiving plan is silent |
| **`D-5668-OPTION`** | The two-file option of record, or the one-file counter-design that achieves the same measured invariant with the sibling tool unedited? | **Ship the design of record (two files).** The FCM declares both rows unconditionally on that basis; adopting the counter-design at Commit 0 drops the second row and requires a Deviation Log entry naming the dropped path |
| **Package-rebuild ownership** | Which commit rebuilds `project-initiator`? | **Commit 4**, after the last SKILL.md writer. Executed and diffed in the PR, because the CI gate ships non-blocking |

## Superseded Decisions

Recorded so that a reader of the decision chain does not mistake a retired position for a live one. The chain carried no supersession markers until scope-lock; six dead decisions read as live at that point.

| Superseded | Killed by | What it was |
|---|---|---|
| D-7, D-9, D-16, D-26, D-29 | **D-37** | Five successive band overrides, carrying the milestone as high as `effective_pts` **44**. The split retired all five. **Any argument resting on "76% over ceiling" is stale** — that figure no longer exists |
| D-30 | **D-33** | A narrowed CIAC-1 clause forbidding any exclusion whose removal moves the orphan count. Two reviewers on different cards independently proved it **jointly unsatisfiable** with clause 1: clause 1's census is achievable only *because* of an exclusion clause 2 forbade |
| The Tier-2 + ADR pricing of the V-CORE-03 amendment | **D-40** | Priced on a precedent that was cited from its status section and never read at source. The precedent took a type lift plus a field addition; this change takes neither |
| AI-002 | AI-006 | Its reverser premise is false — the assumed `--strip` flag has **0 occurrences repo-wide** |
| AI-007's "5 unclaimed" | **D-38** | A census joined against a stale claimant table. The residual is **1** |
| #5741's own `D-5741-2` recommendation to *absorb* | D-45 / **D-48** | Both absorb premises died with the split: the sibling rebuild it would have ridden is in the other milestone, and the card is the 2nd claimant here rather than the 4th. Flagged for Plan Review visibility by **D-49** |
| D-5741-4 (the re-bundle call at 44) | D-37 | Withdrawn as a live question. The card no longer moves the band |

## Deviation Log

| Path or token | Status | Basis |
|---|---|---|
| *(none yet — populated at Engineering)* | — | A declared ADD that legitimately does not ship requires a row here carrying the literal `NOT DELIVERED` and the declared path, or — for a conditional row — its condition token |

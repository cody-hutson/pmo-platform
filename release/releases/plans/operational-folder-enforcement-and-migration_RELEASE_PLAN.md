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

# ── #5741 — PROMOTED at Commit 3: D-48-ROUTING resolved RETAIN (sibling plan silent → stated fallback) ──
operations/skills/project-initiator/SKILL.md                              edit
operations/templates/project-md-composed-index-template.md                edit

# ── Package rebuild (tool-generated; triggered by #3123's SKILL.md edit at Commit 2) ──
packages/project-initiator.skill                                          edit
packages/project-initiator.skill.sha256                                   edit

# ── ADR index (tool-generated; emitted by renumber-adr.py R4 at the ADR-137→139 renumber) ──
core/ADRs/README.md                                                       edit

# ── Stage-9 repair — MAJOR-5: the BELONGS_TO representative resolver is legacy-token-only ──
core/deploy/tools/build-doc-index.py                                      edit

#### Read-only inputs
core/disciplines/project-entity-model.md                                  READ
core/specs/health-check-specification.md                                  READ
core/config/allowlists/script-execution-allowlist.txt                     READ
operations/templates/project-bins/                                        READ

#### Release-wide explicit non-scope
core/hooks/block-fs-boundary.sh                                           NOT EDITED
core/hooks/block-autonomy-ceiling.sh                                      NOT EDITED
core/standards/portfolio-writeback-contract.md                            NOT EDITED
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

**#5741 — 8 files, 1 new, `+245 / −13`** — one unconditional figure. `D-48-ROUTING` resolved **RETAIN** at Commit 3, so both former conditional rows are live and there is no conditional set left to describe.

| Path | Region | Δ | Note |
|---|---|---|---|
| `core/schemas/project-schema.md` | §3b entity-record block, §7 Entity-Seeding Protocol S1–S6, snapshot / mover / restore ordering, frontmatter `consumers:` and §8 row | `+65 / −1` | Largest single component |
| `core/schemas/entity-field-schemas.md` | V-CORE-03 rule text, §3.0 framing, V-PRJ-03 annotation, `NT-PRJ-5` — **plus the D-42 presence guard** | `+~5 / −4` | The highest blast-radius-per-line change in the release: all 19 entities inherit this rule set |
| `core/schemas/frontmatter-schema.md` | `:93` — Category 3 Provenance, the `id` row | `+2 / −1` | **Disjoint from #3123's row at `:197`** — 104 lines apart, different categories. Verified, not assumed |
| `core/schemas/agent-processing-contracts.md` | `:170` — the Skill-6 `Writes` row | `+1 / −1` | **D-44 — re-authored at build time against #3123's landed version** |
| `core/ADRs/ADR-*-project-entity-axis-1-carrier.md` | new ADR | `+~100` | Allocated at Stage 6 **after** #3123's ADR exists on the branch, so `--next-free` does not return the same number twice |
| this plan file | Part-A evidence record + Stage-12 restore ordering + Tier-A declaration | `+64` | Second claimant on this file; append-pattern, distinct H2 |
| `operations/skills/project-initiator/SKILL.md` | `188–194` — the `:193` "born-aligned entity record" misnomer | `+6 / −4` | **PROMOTED — `D-48-ROUTING` → RETAIN.** Delivered operator-side in the combined edit at `2b4f9062` |
| `operations/templates/project-md-composed-index-template.md` | `:13–16` — inside the opening HTML comment | `+3 / −2` | **PROMOTED — `D-48-ROUTING` → RETAIN.** Delivered at Commit 3 |

### Matrix notes

**Shared-file note — four paths carry two claimants each.** `core/deploy/tools/stamp-node-frontmatter.py` (#5668 × #3123), `core/schemas/agent-processing-contracts.md` (#3123 × #5741), `core/schemas/frontmatter-schema.md` (#3123 × #5741), and this plan file (#3123 × #5741). Only the first two are collisions; the other two are shared files with disjoint regions. The Contention Map states each one's resolution.

**Conditional-promotion rule.** `D-5668-OPTION` and `D-48-ROUTING` resolve at or before Engineering Commit 0. A row left CONDITIONAL after its condition has fired is an authoring defect — promote it in that commit, carrying its concrete path. The converse also binds: if a row's declared condition turns out false and the file is edited anyway, promote it with the real basis recorded rather than leaving it shielded by a predicate that never fired.

**Package rows are declared here, not by either card.** Neither #3123's nor #5741's design carries a `packages/` row, yet #3123's own FCM note names the `.skill` rebuild, the `pmo-skill-editor` obligation and Check-7 exposure as consequences of its SKILL.md edit. The rows are added at the plan surface so the obligation is planned rather than rediscovered at Engineering. This is the plan's finding, not the cards'.

**⚠️ The automated FCM check reads only part of this matrix — bug #5757.** `release/tools/verify-release-plan.sh`'s `pathof()` matches declared paths against a closed prefix allowlist — `core`, `release`, `docs`, `packages`, `projects`, `roadmaps`, `.github`, `.claude` — that **omits `operations/`**. Read directly from the shipped tool at the release baseline. Every `operations/` row is dropped before classification, and a dropped row is **not** counted as `uninterpreted`, so the checker can report a clean parse over a matrix it only partly read.

**Measured against this matrix, and the reconciliation is exact.** Running the shipped extractor and `pathof()` over the fence above: **32 declaration rows · 25 parsed · 7 dropped**, and all 7 dropped rows are the `operations/` rows (`25 + 7 = 32`). Verb histogram `{edit 21, NOT EDITED 5, READ 4, add 2}`. Of the 7 dropped: **four are change-obligation rows** — #3123's two born-block edits and #5741's two now-promoted rows — and three are non-change rows (one `READ`, two `NOT EDITED`). *Arms:* sensitivity — 25 rows match `pathof()`; specificity — a bogus prefix `zzz/foo.md` matches **0**; control — `operations/x/SKILL.md` matches `pathof()` **False**, which is bug #5757 reproduced directly rather than cited.

**Re-derived at Stage 9 (was 30 · 23 · 7).** Two rows were added by the Stage-9 repair and both parse: the tool-generated `core/ADRs/README.md` index (an undeclared delivery — the ADR-137→139 renumber emitted it, and the same renumber rewrote citations across the tree, so a reader who cannot see the index row cannot tell whether the renumber was declared at all), and `core/deploy/tools/build-doc-index.py` (MAJOR-5). **The index row is declared rather than exempted deliberately:** this plan already accepts that obligation for exactly this class — the `packages/` pair is itself tool-generated and *is* declared, with its trigger named — so exempting a tool-maintained index would stand up a second, unstated exemption class beside a declared one, and `G-PR11`'s `fcm-delivery` reconciliation would stop being exact.

**One `NOT EDITED` row carried a wrong parent directory and is corrected here.** It read `core/schemas/portfolio-writeback-contract.md`; **no such path exists**, so the row could not fail — nothing can edit a file that is not there. The contract is real and lives at **`core/standards/portfolio-writeback-contract.md`**, verified at source and measured unchanged on this branch. *Arms:* sensitivity — `core/deploy/tools/build-doc-index.py` resolves; specificity — a fabricated `core/schemas/this-path-does-not-exist.md` does not; control — the corrected path shows **0** changed lines while `core/ADRs/README.md` shows **1**, so the unedited reading is a measurement rather than a dead probe. **Grading rule this makes explicit: resolve every `NOT EDITED` row to an extant path before grading it.** The other four `NOT EDITED` paths all exist and all show zero changes.

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

**Row identity, reconciled at Stage 9.** The `AC` column names the **card-body** criterion each row verifies. #5668's card body carries **9** unnumbered checkbox criteria (read at source), numbered `AC-1`…`AC-9` in reading order throughout this release. Two labels here did not resolve against that numbering and are corrected: the `--self-test` row was labelled `AC-2` but verifies card **AC-4**, and **`AC-11` does not exist on the card** — it is a plan-authored row, relabelled `VP-5668-E` so it stops claiming a card antecedent it never had. No card body was edited to achieve this: the plan was wrong, not the card.

| Issue | AC | Predicate class | Verification Method | Expected Result |
|---|---|---|---|---|
| #5668 | AC-4 *(was mislabelled `AC-2`)* | file-state | Run the tool's shipped `--self-test` on the merged branch | Exit 0; the five-bin arm **(i)** passes, including its COVERAGE GUARD |
| #5668 | AC-6 — restated per **R-5668-6** | file-state | Assert **`_pmo`** — the ADR-058 shared-entity store, named explicitly — appears in `excluded` with reason `non-project top segment (_pmo)`, and in neither `orphans` nor `would_stamp`. **Never phrase this as "program-scoped-config"**: that term denotes `_config`, which is excluded at *both* revisions and so cannot fail | 1 file in `excluded`. **Baseline control arm, mandatory:** the identical probe against the release baseline must find it in `orphans`, **not** `excluded` (measured 0 → 1). A pass that also passes on the baseline is a broken probe |
| #5668 | **VP-5668-E** *(plan-authored; the card has no `AC-11`)* — restated per **R-5668-11** | file-state | **Limb 1 — the FK invariant over the EMITTED population:** every file for which `plan_edges` returns ≥ 1 edge must appear in the node tool's stamp set. Grade over `plan.edges`, **not** over `disposition == 'ok'` — disposition is not a gate; `run()` emits on `plan.edges`. **Limb 2 — retained control:** planned-edge count over an untouched control population | **Limb 1:** baseline **95** violations (sensitivity arm fires); HEAD **1** — the declared depth-1 accepted residual, **named as an accepted exception, never counted as a pass**. **Limb 2:** 112 files STAMP at both revisions, 109 edges, unchanged. *(Retired wording — "0 edges over the excluded set" — measured 0 at both revisions: `plan_edges` applies the same exclusion gates in the same order, so it was structurally unfailable.)* |
| #3123 | AC-1 | file-state | Grep the merged tool for the orphan-reason token AC-1 asserts — **restated per DR-R3-1**. **Superseded for grading by R-3123-1**, which grades a classification *outcome* rather than a token in source | The restated token resolves; the retired literal is absent by design |
| #3123 | AC-4 | runtime-suite | Re-run the card's stated sampling expression **against the pre-write corpus**. **Temporal anchor restored:** the card reads *"before any write"*; the prior "post-write corpus" wording inverted it and destroyed the row's function as a gate — a post-write AC-4 failure has no complete undo | ≥ 95% on the drawn sample, with N and N/`would_stamp` both stated. Bound stated per **R-3123-4**: at the measured divergence ceiling the probability the *sample* fails is **≈ 10%**, not zero |
| #3123 | AC-8 | file-state | **Restated per DR-R3-2, sharpened per R-3123-8.** Assert the pre-write snapshot exists, is complete over the § 9 scope **including the derived `<source>.meta.yml` paths**, and that a restore has been **demonstrated on one file of each of the three `sidecar_disposition` states** — **not** that a `--strip` flag is present, and **not** that a snapshot is merely present | Snapshot verified **restorable** before the write is authorized, with the `pre-existing` disposition in the demonstration set. **Currently FAILS**: § 10 states in its own words that the restore is not yet demonstrated |
| #3123 | — | integration | The CIAC-1 census above, read from structured JSON with its sensitivity arm | Census matches the declared class table; residual 1 |
| #3123 | — | integration | **Grades the Node-Backfill Evidence Record itself** — present, and internally consistent against the merged tree. Added at Stage 9: that record is declared #3123's *only* PR-side gradeable artifact, yet no #3123 row graded it, which is how a stale § 12 reached the merged tree unchallenged | Record present; **no § 12 or Deviation-Log row declares a path undelivered that the merged diff delivers** |
| #5741 | V-CORE-03 — restated per **R-5741-1** | file-state | **Limb 1 (discriminating):** assert **§3.1 Project resolves its Axis-1 carrier to `status`** and the other **18 to `lifecycle_state`** — not merely that 19/19 resolve to *something*. **Limb 2 (function, not presence):** a Project record carrying `status: ACTIVE` **and** `lifecycle_state: emerging` must **PASS** V-CORE-03 under the shipped rule and **FAIL** it under the release baseline; and a Project record lacking `lifecycle_state` must **fail an L1 rule** | Shipped: 18 → `lifecycle_state`, §3.1 → `status`; synthetic record **PASS**. Baseline: the same record **FAIL**. *(Retired wording — "19/19 resolve" — returns 19/19 under the **release-baseline** rule as well, because the default carrier is total: a green was compatible with the amendment never landing.)* |
| #5741 | `NT-PRJ-5` | runtime-suite | Re-run the card's declared negative test against the amended rule set | Passes as declared, with the D-42 residual recorded rather than silently satisfied |
| #5741 | seeding | declared, verification deferred to the Stage-12 evidence record | The corpus write is not readable from the PR diff; the gradeable artifact is the Part-A evidence record committed to this plan. **The `internally consistent` limb is load-bearing** — it is the only criterion in this plan that catches an §A3-class contradiction between an evidence record and the protocol it documents | Evidence record present, internally consistent, counts re-derived at write time |
| #3123, #5741 | — | integration | CIAC-2 above, with its baseline control arm | Both keys present in the merged `:170` row, **and the row well-formed as a single emit list** — the key count it names must equal the key count it lists |

### Criterion Restatements — Stage-9 repair

**Why this section exists.** Six independent graders — three Dev Testing, three Acceptance — reached the same conclusion: **the code is sound and the criteria are not.** Of 37 criteria across the three cards, **8 could not have failed** against the change they grade, and 5 fail on their own wording. A criterion that cannot fail certifies nothing, and one of them — #3123's AC-6 — passed green while **38.4% of the corpus lost every guaranteed edge**.

**Where restatements live, and why not on the cards.** This plan is the established home for AC restatements in this release: `DR-R3-1` and `DR-R3-2` already restate two of #3123's criteria here, and the Verification Plan grades the restated form. Every restatement below follows that precedent. **No card body was edited.** Editing the public issue bodies would put the corrected text outside the PR diff — unreviewable at Stage 9 and unrevertable by `git revert` — and the card bodies are the historical record of what was *asked*, not of how it is *graded*.

**The authoring rule these all obey**, reached independently by two graders and already embodied in the classifier's arm (i) coverage guard: **a criterion must name a structured output field, must carry a sensitivity arm, and may never name a literal the diff under test can delete.** Four of the five #5668 defects die at authoring under that rule.

#### #5668 — classifier union-awareness

| ID | Criterion | Why it could not fail | Restated form |
|---|---|---|---|
| **R-5668-2** | AC-2 — *"zero `no resolvable NN- folder prefix` orphans over a new-taxonomy project"* | **Two independent defects.** The literal exists in **0** repo files at HEAD (baseline: 1) — this commit deletes it, so the assertion holds for every project, improved or not. **And its stated method makes it worse:** *"`--dry-run` scoped to a 5-bin project"* executes as `--root <project dir>`, which floors `classify()`'s token walk at index 1 where `parts[0]` is now the *bin* — measured **0 stamped / 24 orphaned** and **0 / 46**, i.e. the criterion reads green on a run in which **100% of its target orphans** | *From the corpus root, `--dry-run --scope active --output-format json`; filter the `orphans` array **structurally** to records whose first path segment is a five-bin project. Assert **0**. **Sensitivity arm:** the same filter against the pre-fix tool must return **71** across the two projects. **Never scope by `--root <project>`** — the token walk floors at index 1 and the bin becomes structurally unreachable.* |
| **R-5668-3** | AC-3 — *"the three legacy projects still yield **170** would-stamps"* | **Falsified in both limbs, by this card's own scope.** Legacy would-stamps measure **190 → 162 → 115** across the three revisions; **"170" matches no revision.** Invariance is broken by the card's own `templates` tier. Root cause: a **baseline measurement carried forward as a post-change expectation** | *Assert **field-level identity over retained records**: 0 field-value changes across every record present at both revisions (measured 0 over 162, 179 and 112 retained). **Comparator sensitivity arm:** one injected field mutation must be detected as exactly 1 change. Drop the figure 170 — a stamp-count invariance this card's own `templates` tier is designed to break is not a regression criterion.* |
| **R-5668-6** | AC-6 — *"`projects/_pmo/**` classifies to a resolvable (domain, default_type)"* | **The criterion is wrong; the code is right.** `frontmatter-schema.md` § Scope — the authority the card's own Expected Behavior names — reads *"Exclusions: navigation layer pages (`_pmo/`) …"*. **Satisfying AC-6 as worded would re-create the drift this card exists to close.** Left unrestated, Stage 8 renders a FAIL on correct code | *Assert `_pmo` resolves to **`excluded`** with reason `non-project top segment (_pmo)`, conforming to `frontmatter-schema.md` § Scope, and appears in neither `orphans` nor `would_stamp`. **Baseline control arm:** the same probe against the release baseline must find it in `orphans` (measured 0 → 1).* |
| **R-5668-7** | AC-7 — *"`projects/Transcripts/**` classifies without inventing a project"* | **Passes identically on the baseline.** Only a *stamped* record carries a `project` field; at baseline these 17 files were **orphans**, which carry no fields at all — so nothing was invented pre-fix either. No corpus state and no revision can fail it | *Assert the **disposition transition**: the 17 files under the cross-project staging root move from `orphans` at baseline to `excluded` with reason `non-project top segment (transcripts)` at HEAD. **Specificity arm:** **0** records in `would_stamp` carry the staging root as their `project` value, at either revision.* |
| **R-5668-8** | AC-8 — *"a full `--scope active` dry-run returns **zero** files carrying the reason `no resolvable NN- folder prefix`"* | **Vacuous by rename.** The literal goes **97 → 0** by the rename alone; a commit that renamed the string and fixed nothing else passes identically. **And its intended form is false:** the semantically equivalent literal carries **1** at HEAD | ⚠️ **Do not simply swap in the new literal and keep the word "zero" — that converts a vacuous PASS into a genuine FAIL, because the true residual is 1.** *Read the `orphans` array **structurally**, never by grepping a reason literal. Assert the residual is **exactly 1**, that it is the declared **depth-1 corpus-root accepted-residual class**, and that every other declared orphan class has gone to **0**. **Sensitivity arm:** the same invocation against the pre-fix tool must return **97 orphans over 8 exclusion classes**, versus **1 over 13**.* CIAC-1 already states this number correctly (*"expected residual: exactly ONE. Not zero"*); AC-8 must inherit **that number**, not merely that discipline |
| **R-5668-11** | The Verification Plan's `AC-11` row — *"0 edges over the excluded set"* | **Structurally unfailable at both revisions.** `plan_edges()` applies the same four exclusion gates as `classify()`, in the same order, binding the same frozensets at import — so an edge over an excluded file is impossible at baseline *and* at HEAD (measured 0 / 0). **Worse, it sits directly on top of the one invariant that DID move by two orders of magnitude and grades the half that could not move** | Re-pointed at the FK invariant over the **emitted** population — full wording in the `VP-5668-E` row above. **The correction to the record: the FK invariant is 95 → 1, not 8 → 0** (see the note below) |

**Correction to the record — the FK invariant is `95 → 1`, not `8 → 0`.** Stage 7 measured the FK population as `disposition == 'ok'`. **That is not the population the writer touches.** In `plan_edges`, step 6 appends the `BELONGS_TO` edge **before** step 8 assigns `no-provenance-anchor`, and `run()` emits on `if do_emit and plan.edges:` — **disposition is not a gate.** Both populations, re-derived side by side from git-extracted revisions run against the same live corpus, each revision isolated in its own process so the two cannot cross-import:

| Population | `origin/main` | HEAD |
|---|---|---|
| files with ≥ 1 **planned (emitted)** edge | 282 → **95 unstamped** | 181 → **1 unstamped** |
| the `disposition == 'ok'` subset only | 47 → **8 unstamped** | 38 → **0 unstamped** |
| node stamp set | 190 | 185 |

Both figures reproduce; the prior `8 → 0` is a true reading of the **wrong population**. **The card under-claimed its own best result by roughly 12×**, and no acceptance criterion credits it — not one card AC mentions edges.

**The surviving violation is NOT inert — recorded as an AI-010 Stage-12 item against CIAC-1's accepted-residual disposition.** The one remaining FK violation *is* the declared accepted-residual orphan: the corpus-root `.md` at one path segment (opaque key `6ebdb617a810`), carried at `disposition: no-provenance-anchor` with exactly one planned edge. On the **node** axis it is an orphan — reason `no resolvable folder token (no confident domain)`, never stamped, no `project` field — and CIAC-1's disposition is sound as a node-axis statement. On the **edge** axis it is active: `_project_of()` returns `rel_path.parts[0]`, which for a corpus-root file **is the whole filename**, so the planner emits a `BELONGS_TO` whose target is **the filename verbatim, suffix included** — measured `target == basename+suffix` **True**, `target == basename stem` **False**. *(The stem reading was recorded upstream and is imprecise; a Stage-12 guard keyed on the stem would not match.)* The target resolves to no stamped project — measured **False** against the live project set. At Stage 12 that would write an edge naming a project that does not exist, onto a file with no node record. **This falsifies a claim the commit makes about itself**: `c7de12fa`'s message and the `NONRECORD_PROJECT_SEGMENTS` comment both state *"the edge population stays a SUBSET of the node population."* Directional test at HEAD: `edges ⊆ stamped` → **False, by exactly one file.** The mirroring covers the **exclusion** tiers; it does not cover the **orphan** class. **Severity MODERATE, not Blocker** — one file, one edge, `--emit` is gated (verified exit 3 without the token) and the D-11 snapshot covers the reversal. **Stage-12 obligation:** confirm the emit skips it, or add a depth guard to `plan_edges` so a depth-1 corpus-root file plans no `BELONGS_TO`.

#### #3123 — node-frontmatter backfill

| ID | Criterion | Why it could not fail | Restated form |
|---|---|---|---|
| **R-3123-1** | AC-1 — *"assert zero `no resolvable NN- folder prefix` orphans"* | Same mechanism as R-5668-8: #5668 **deletes** that literal, so no orphan can bear that reason and the assertion holds even if every five-bin file orphaned | *Over a dry-run of the merged classifier scoped to each ADR-080 five-bin project, assert `counts.orphans == 0` for that project's candidate set **and** that its files appear in `would_stamp` carrying a five-bin `folder` value — read from structured JSON, with the **baseline tool as the sensitivity arm**, which must return a non-zero orphan count over the same set.* (Measured: merged 0 / 0; baseline 25 / 46.) |
| **R-3123-4** | AC-4's accuracy bound | Not vacuous, but **unsound two ways**: § 7 compares a *population* ceiling to a *population* budget while AC-4 grades the **sample**; and the Verification-Plan row restated the target as *"against the post-write corpus"*, **inverting the card's own "BEFORE any write"** and destroying its function as a gate | *Restore the pre-write temporal anchor, and state the bound **against the sample**: at the measured divergence ceiling the hypergeometric probability that the sample fails is **≈ 10%** (9.57% at the record's instant, 10.49% live), **not** the "does not fail" § 7 claims.* A post-write AC-4 failure has no complete undo — it composes with the snapshot defect. |
| **R-3123-6** | AC-6 — *"edges populate and the index rebuilds"* | **The vacuity actively concealed a defect.** The edge tool guarantees a `BELONGS_TO` for every non-excluded project-resolvable file **by design** — its own docstring calls it *"the always-safe edge the design guarantees"* — so non-emptiness is structural. **AC-6 read green at 62% edge coverage** while 3 of 5 projects lost every edge | *For every project in the indexable set, assert inserted `BELONGS_TO` edges **== indexed files minus one** (the self-edge to the project's own representative), **and assert the builder's dangling-edge WARN list is empty**.* **This is the criterion that would have caught MAJOR-5.** |
| **R-3123-7** | AC-7 — *"Query-4 and Query-5 return non-empty"* | **Query-4 is vacuous:** `FROM files … GROUP BY` is non-empty iff any file is indexed, which stamping 185 nodes guarantees — it asserts nothing about the warehouse. **Query-5 is genuinely contingent and is predicted to FAIL** | See the adjudication immediately below. |

**MAJOR-4 adjudication — AC-7 is split, and the answer is "both", stated plainly rather than papered over.**

*The Query-4 half is a wrong criterion.* Restated: *assert `COUNT(*) FROM files` equals the re-derived `would_stamp` count **exactly**, and that no indexed row is missing a NOT-NULL core field.* Predicted at HEAD: **185 rows**, Query-4 returning **13** `(project, lifecycle_state)` groups.

*The Query-5 half is a genuine coverage gap, and it is recorded as a **known limitation**, not repaired.* Re-derived at HEAD **after** the MAJOR-5 fix (which moves edge resolution, so the earlier prediction could not simply be carried forward): the backfill plans **zero** `DEPENDS_ON`/`BLOCKS` edges — 181 inserted edges, of which **169 `BELONGS_TO`**, 5 `DEPENDS_ON`, 6 `GENERATES`, 1 `SUPERSEDES`. The corpus's own pre-existing `relationships[]` frontmatter carries **14 carriers** inside the indexable set with a verb histogram of `{DEPENDS_ON 8, GENERATES 8, BLOCKS 3, SUPERSEDES 2}`. Resolving those through the builder's actual path: **10 dangling · 5 same-project · 0 cross-project.**

⇒ **Query-5 predicted row count: 0.** *Arms:* sensitivity — same-project `DEPENDS_ON`/`BLOCKS` returns **5**, so the harness is live; specificity — a bogus verb returns **0**; and a **positive control** — the identical Query-5 SQL over one synthetic cross-project `DEPENDS_ON` returns **1**, proving the live zero is a measurement and not a dead join.

**The honest reading: the corpus genuinely has no cross-project dependency edges.** That is a corpus fact, not a tool defect and not something this release can manufacture without fabricating data. **Query-5's non-emptiness is therefore demoted from an acceptance gate to a recorded observation**, until the corpus is known to carry cross-project edges. Leaving it as a gate would fail AC-7 at Stage 12 — *after* an EXPENSIVE corpus write whose undo is incomplete — for a benign reason. **Stage-12 obligation:** re-derive the prediction immediately before the write per AI-010, and record the observed value whatever it is.

*Adjacent, not graded (it belongs to the index builder, not this card):* pass 1 stores `edges_by_source` keyed on **bare filename**, so two indexed files sharing a basename silently clobber each other's edge list. Measured: **5 ambiguous basenames** among the 185.

#### #5741 — seed conformant entity records

| ID | Criterion | Why it could not fail | Restated form |
|---|---|---|---|
| **R-5741-1** | VP-1 — *"19/19 resolve"* | **The count is invariant to the amendment.** The **release-baseline** V-CORE-03 — which names `lifecycle_state` verbatim with no override clause — returns **19/19 over the same 19 sections**, because the default carrier is total: every section resolves to *something* under either rule. **A green on this row is compatible with the amendment never having landed** | Full discriminating wording in the `#5741 · V-CORE-03` row above. Run: shipped **PASS** · baseline **FAIL** on the same synthetic record — which is the original defect, since under the baseline rule *no* Project record could be valid (the Project Axis-1 enum and the Domain-B file-axis values are disjoint) |
| **R-5741-AC1** | AC-1 — *"a documented, repeatable seeding procedure exists"* | The `exists` limb is falsifiable but trivial; **`repeatable` is asserted and nothing tests it**, even though S4's add-absent-keys-only makes it directly testable and the entire no-overwrite argument rests on it. The substantive limb — *"naming its source of truth for each entity kind"* — **genuinely FAILS** (see § A3 below) | *…and **re-running the procedure over the same population produces zero writes** — idempotence **demonstrated, not asserted**.* |
| **R-5741-AC2** | AC-2 — *"`entity_type` present and schema-valid across the **seeded** population"* | **Self-selecting denominator.** The seed writes `entity_type` as a constant literal on every record it writes, and the denominator is defined by the writer, so the predicate is true by construction. It **cannot detect the failure that actually matters** — an in-scope record the seed *should* have written and did not, e.g. one refused by the §3b status parse, which is a live refusal path | *"…present and schema-valid across the **in-scope** population — denominator stated (the 4 depth-≤1 non-archived `PROJECT.md` + 1 Person + 1 Portfolio) — with **every excluded record accounted by count and reason**, and a sensitivity arm proving the probe is live."* § A2 already does the accounting; the criterion never required it |
| **R-5741-AC4** | AC-4 — *"three completeness factors resolve against a non-empty population, with per-factor denominators stated"* | *"Denominators stated"* is a **presence predicate on a number the card itself authors** — § A6 writes 6 / 9 / 3 and the criterion is satisfied by the act of writing them. The other limb grades **#158's** factors, and #158 is OPEN in a different milestone | *"…and each denominator is **re-derived from the shipped §3.N required-field sets** rather than restated; the `%relationships-valid` grain is named explicitly (scalar ref keys V-PRJ-05 / V-PRJ-08 **vs** V-CORE-07 `relationships[]`) and **that reading is recorded as a decision**, because #158 owns the factor and is unshipped."* |
| **R-5741-VP3** | VP-3's `internally consistent` limb | **Not vacuous — it is the sharpest criterion in the plan, and it fires.** It is the only criterion that catches the § A3 contradiction; no card AC covers that | Retained verbatim. The **delivery** failed it, not the criterion. Every finding it caught — the four stale delivery limbs, the § A3 contradiction, the V-PORT mis-citation, the non-reproducing § A2 histogram — is repaired in this commit set |

**Criteria that are genuinely well-built — recorded so the pattern is reusable rather than rediscovered.** Four criteria across the three cards need no repair and were deliberately left alone: **#5668 AC-4** (the only self-maintaining criterion in the release — its COVERAGE GUARD fails the build when a table row gains no case, which is the shape every other criterion here should have had); **#5741 AC-5** (demands a **demonstrated** restore, not a present snapshot — it does not repeat the presence-not-function defect its own plan books against a sibling card); **#5741 AC-6's third limb** (*"no assumption of independence"* **forbids a specific wrong answer** rather than requiring a presence, which is why it is unfakeable); and **CIAC-2** (the only criterion in this set that **builds its own falsification requirement into the criterion text** — *"a pass that also passes on the baseline is a broken probe, not a clean merge"* — and the reason the D-44 silent revert could be ruled out rather than assumed).

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
| **`D-48-ROUTING`** — **RESOLVED at Commit 3: RETAIN** | Does the sibling milestone accept the two born-block regions? Its Stage-4 plan **does not yet name them** (verified: 0 against sensitivity arms of 11 and 2). Re-checked at Commit 3: the sibling's only in-flight PR carries a single file and does not answer, so the plan's stated fallback fires | **Retain both rows in this release** and extend the D-44 re-authoring discipline to both hunks. The misnomer is pre-existing in the mainline, so deferring is debt, not regression — but retaining is the safe default when the receiving plan is silent. **Applied:** both rows promoted to unconditional in the FCM; the template row is **delivered** (re-authored against Commit 2's landed text, `_project-root` sentence byte-identical); the SKILL.md row is **hook-blocked and folded into the single combined operator-side edit** (Deviation Log; § A12) |
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
| `core/governance/OPERATIONS.md` | **DELIVERED — `2b4f9062`** | Blocked at Engineering by `.claude/hooks/block-autonomy-ceiling.sh:BLOCK-AUTONOMY-001`. The rule matches `*/OPERATIONS.md` unconditionally — no worktree carve-out, no mode gate, no session sentinel — so no agent-side path existed. **Not bypassed**, and `CLAUDE_HOOK_BYPASS` was never set. **Delivered operator-side at `2b4f9062` (`+1 / −1`):** the ADR-080 taxonomy note's union carries ` + _project-root` and the NON-BIN SENTINEL sentence, matching § 12's specified change in substance; the ADR citation was renumbered to **ADR-139** at `be0c5bb8`. The deviation is retained as the durable record of the Tier-0 block and its operator-side resolution — it is no longer an open obligation |
| `operations/skills/project-initiator/SKILL.md` | **DELIVERED — `2b4f9062`** — **two claimants, one combined operator-side edit** (`+12 / −7`); package rebuilt at `eeb85bf0`; ADR citation renumbered at `be0c5bb8` | Blocked at Engineering by `.claude/hooks/block-skill-direct-edit.sh:BLOCK-SKILL-EDIT-001` in enforce mode (the skill carries the `skill_discipline_migrated_v10_2` marker). The sanctioned path is a genuine `pmo-skill-editor` session sentinel; `pmo-skill-editor`'s own guardrail forbids self-creating that sentinel to clear the gate, so it was not created. Impact analysis was completed and is recorded in § Node-Backfill Evidence Record § 12. **#5741's misnomer correction (`D-48-ROUTING` → RETAIN) joins this same row rather than opening a second one**, because the Release-Level Verification list requires the `pmo-skill-editor` regression pass to run once against the **final combined state**; landing the two changes separately would grade a file that never ships. The combined required change is specified in § Entity-Seeding Evidence Record § A12 |

## Node-Backfill Evidence Record

*Part A (pre-write), authored at Stage 6 per **D-3123-E**. This is #3123's PR-side gradeable artifact — the surface Stage 7 DT and Stage 8 QA grade, because the card's corpus deliverable is not readable from the PR diff. **Part B (post-write) appends here via the Stage-12 Phase-B5 chore PR.***

**Corpus-privacy construction, stated because it changes how §§ 5–8 read.** This plan is a tracked file in a **public** repository; the corpus it measures is git-ignored Layer-2 client-engagement material. Every per-file row below is therefore keyed by an **opaque stable file key** — `sha256(<corpus-relative path>)[:12]` — never by a path, project name, or filename. The keys are deterministic and reproducible by anyone holding the corpus, so per-file auditability is preserved without publishing any corpus identifier. Everything else emitted here is a count, a depth index, a platform-vocabulary token, or a tool-emitted enum value.

### § 1 — Measurement instant

| Field | Value |
|---|---|
| Merge base | `origin/main` @ `ccd3be07` |
| Branch state measured | Commit 1 (#5668) + Commit 2 (#3123) applied |
| Date | 2026-08-21 |
| Invocation | `stamp-node-frontmatter.py --dry-run --scope active --output-format json --root <corpus>` |
| Mode | read-only throughout; `--dry-run` is the default and is not gated, and `--stamp` was never invoked |

**Every figure below is a point-in-time observation and MUST be re-derived immediately before the Stage-12 write (AI-010).** The corpus moved **three times during this Stage-6 session alone**, with the tool byte-identical across every read: baseline `would_stamp` 186 → 187 → 190. It had already moved 180 → 181 during review. The **class structure** is the durable output of this record; every **count** is an observation.

**The third move is recorded rather than absorbed, because it is the strongest available evidence for that distinction.** A re-measurement taken minutes after the tables below were computed — between authoring this record and committing it — read `would_stamp` **185**, `excluded` **2682**, Σ **2868**. The whole delta reconciles to one cause: `_superseded` grew **32 → 50** as 18 artifacts were retired into it mid-session, and three new candidate files appeared. **`orphans` stayed at exactly 1, on the same file key.** Every table below is left at its coherent 200-population instant rather than partially re-derived, because re-deriving one section and not the others would make the record internally inconsistent and would be stale again by the time it merged. **The class structure held across all three moves; only the counts moved.** That is the record's thesis, demonstrated rather than asserted — and it is why Stage 12 re-derives rather than reads.

### § 2 — Post-fix counts

| Counter | Baseline (`ccd3be07` tool) | Merged branch | Δ |
|---|---|---|---|
| `would_stamp` | 187 | **200** | +13 |
| `orphans` | 97 | **1** | −96 |
| `excluded` | 2581 | **2664** | +83 |
| `stamped` / `created` / `skipped_complete` | 0 / 0 / 0 | 0 / 0 / 0 | — |
| **Σ candidates** | 2865 | **2865** | 0 — closes exactly |
| exit code | 1 | **1** | unchanged |

**Exit 0 is not the readiness gate.** The tool returns 1 whenever `counts.orphans` is non-zero, and the merged branch leaves exactly one declared accepted-residual orphan, so a green exit is unreachable by design. Read the per-class census in § 3, not the exit code.

### § 3 — Orphan census, per reason × per class, with a disposition for every class

Read structurally from the `orphans` array — **never** by grepping a reason literal, which is the defect DR-R3-1 records.

**Baseline (97), classified against every claimant on record:**

| Class | Claimant | n | Disposition |
|---|---|---|---|
| File inside an ADR-080 five-bin project | #5668 core | 68 | Fixed in-release by the classification union |
| Cross-project staging tier | #5668 / D-7 | 17 | Excluded in-release |
| `_`-prefixed top segment | #5668 / D-7 | 1 | Excluded in-release |
| Free-text folder segment in a legacy project | #5668 / D-25 (per **D-38**) | 4 | Excluded in-release by the positional out-of-taxonomy tier |
| Project-root governance file at depth 2 | **#3123 / D-12** | 6 | Fixed in-release by the `_project-root` non-bin sentinel |
| **Depth-1 corpus-root file** | **NONE** | **1** | **Accepted-residual, next-release owner** |
| | | **Σ 97 ✓** | |

**Merged residual: exactly 1.**

| Key | Depth | Suffix | Reason | Disposition |
|---|---|---|---|---|
| `6ebdb617a810` | 1 | `.md` | `no resolvable folder token (no confident domain)` | **Accepted-residual.** Program-scoped operational config at the corpus root with no project segment — it should never have been a node candidate. Its correct long-run home is the non-project-top-segment tier, which is #5668's surface; claiming it here would be a count-driven carve-out. Next-release owner |

**D-38's residual-of-1 is re-derived here rather than carried.** Post-#5668 the residual is **7** (the six depth-2 governance files plus the depth-1 corpus-root file); post-#3123/D-12 it is **1**. Both arms: *sensitivity* — the five-bin token detector returns **68** over the claimed bucket; *specificity* — a bogus bin token returns **0** over the same population. The D-12 third-guard discriminator returns **6** with the `_`-prefix guard and **7** without it, so the guard is measurably load-bearing rather than decorative.

### § 4 — N derivation (rule, then literal)

**Rule (D-3123-C).** Zero-defect hypergeometric acceptance number: the smallest `n` such that `C(N−D, n) / C(N, n) ≤ 0.05`, where `D = floor(0.05 · N_pop) + 1`. This buys 95% confidence that the population defect rate is ≤ 5%.

| Term | Value |
|---|---|
| `N_pop` (post-fix `would_stamp`) | **200** |
| `D` = `floor(0.05 × 200) + 1` | **11** |
| `n_min` | **47** |
| `P(accept | D)` at `n_min` | 0.0481 |
| `n_min / N_pop` | 23.5% |

**Stratified top-up (mandatory).** The seeded draw (`random.Random(1469)`, the tool's own sampler seed) covers **12 of the 14** live `(domain, type)` cells. Uncovered: `(source, export)` and `(source, plan)`. Top-up is the lexicographically-first file in each — deterministic and reproducible: `(source, export)` → key `4fe577a22aec`; `(source, plan)` → key `91ddf07f5493`.

| | |
|---|---|
| **`N_eff`** | **49** |
| **`N_eff` / `would_stamp`** | **24.5%** |

`(source, export)` is one of the sub-bin cells #5668 introduces — the random draw misses the exact cell the fix creates, which is why the top-up is a gate and not a nicety.

### § 5 — Cell census

**33 distinct `(folder, domain, type, lifecycle_state, trust_category, file_format)` cells over 200 files.** Every cell's `type` was checked against `TYPES_BY_DOMAIN[domain]` — the schema's type-taxonomy-matches-domain rule: **33 / 33 valid, 0 violations.**

| n | folder | domain | type | lifecycle | trust | format |
|---|---|---|---|---|---|---|
| 40 | `08-generated` | generated | analysis | draft | interpretation | md |
| 21 | `_generated` | generated | analysis | draft | interpretation | md |
| 14 | `04-operations` | managed | tracker | current | controlled-truth | md |
| 12 | `01-governance` | source | reference | created | evidence | md |
| 12 | `05-transcripts` | source | transcript | created | evidence | txt |
| 12 | `06-emails` | source | email | created | evidence | md |
| 10 | `4-Evidence` | source | email | created | evidence | md |
| 9 | `05-transcripts` | source | transcript | created | evidence | pdf |
| 9 | `2-Delivery` | source | fdd | created | evidence | md |
| 9 | `3-Operations` | managed | tracker | current | controlled-truth | md |
| 6 | `3-Operations` | managed | status-log | current | controlled-truth | md |
| 6 | **`_project-root`** | managed | project-page | current | controlled-truth | md |
| 4 | `04-operations` | managed | status-log | current | controlled-truth | md |
| 4 | `07-reference` | source | reference | created | evidence | md |
| 4 | `4-Evidence` | source | email | created | evidence | pdf |
| 3 | `04-operations` | managed | risk-register | current | controlled-truth | csv |
| 3 | `04-operations` | managed | tracker | current | controlled-truth | html |
| 2 | `04-operations` | managed | tracker | current | controlled-truth | csv |
| 2 | `07-reference` | source | plan | created | evidence | md |
| 2 | `08-generated` | generated | readiness-assessment | draft | interpretation | md |
| 2 | `3-Operations` | managed | risk-register | current | controlled-truth | csv |
| 2 | `3-Operations` | managed | tracker | current | controlled-truth | csv |
| 2 | `4-Evidence` | source | transcript | created | evidence | txt |
| 1 | `01-governance` | source | plan | created | evidence | md |
| 1 | `02-design` | source | fdd | created | evidence | md |
| 1 | `03-testing` | source | test-plan | created | evidence | md |
| 1 | `07-reference` | source | reference | created | evidence | pdf |
| 1 | `08-generated` | generated | analysis | draft | interpretation | html |
| 1 | `08-generated` | generated | analysis | draft | interpretation | pdf |
| 1 | `08-generated` | generated | analysis | draft | interpretation | txt |
| 1 | `08-generated` | generated | runbook | draft | interpretation | md |
| 1 | `2-Delivery` | source | test-plan | created | evidence | md |
| 1 | `4-Evidence` | source | export | created | evidence | md |

**Declared coverage gap, stated so the audit claims no coverage it lacks:** `1-Governance` and `5-Reference` have **zero** live population in this corpus, so the cell census exercises neither. Both are covered by the classifier's own `(i)` self-test arm with literal expected values; the census does not and cannot corroborate them.

**Instrument-bias note.** The census is derived by importing the shipped module and reading its structured output — never by mirroring `FOLDER_PREFIX_MAP` or `FILENAME_TYPE_SIGNALS` into the probe, because a mirrored copy drifts silently and would grade the tool against itself. Cell *validity*, by contrast, is judged against the schema rule, not against the tool's constants.

### § 6 — Sample verdicts

The `N_eff = 49` draw and its two top-up files are **derived and pinned** above (seed `1469` over a pool of 200, plus the two named top-up keys), so the sample is reproducible byte-for-byte at Stage 12.

**Per-file PASS/FAIL adjudication is deliberately NOT rendered here, and this is a scope statement rather than an omission.** A verdict on whether a given file's eleven proposed fields are *correct* requires reading that file's content — client-engagement material that cannot be quoted, characterised, or summarised in a public repository. The mechanical half is complete: every sampled file's proposed tuple is fully determined by the cell census in § 5, and § 5 shows **0 schema violations across all 33 cells**, which bounds the *cell-level* defect surface at zero. What remains is the *file-level* judgement — does this particular file deserve the type its filename signalled — and § 7 isolates exactly the sub-population where that judgement can go wrong.

**Stage-12 obligation:** render the 49 + 2 verdicts in Part B, from the operations-rooted session where the content is readable, against the pinned keys above.

### § 7 — Accuracy: the divergence census (D-3123-G)

Computed by importing the shipped module and resolving each record against the tool's own tables.

| Measure | Value |
|---|---|
| Population (`would_stamp`) | 200 |
| Files firing any domain-valid filename signal | **48** |
| Signal **agrees** with the bin default | 26 |
| Signal **diverges** from the bin default (signal wins) | **21** |
| Signal diverged but was **suppressed by an authoritative sub-bin** | **1** |
| Files firing **no** signal | 152 |

**Divergence composition:**

| n | needle | default → resolved | folder |
|---|---|---|---|
| 6 | `status` | `tracker` → `status-log` | `3-Operations` |
| 4 | `status` | `tracker` → `status-log` | `04-operations` |
| 3 | `raid` | `tracker` → `risk-register` | `04-operations` |
| 2 | `raid` | `tracker` → `risk-register` | `3-Operations` |
| 2 | `plan` | `reference` → `plan` | `07-reference` |
| 2 | `readiness` | `analysis` → `readiness-assessment` | `08-generated` |
| 1 | `plan` | `reference` → `plan` | `01-governance` |
| 1 | `runbook` | `analysis` → `runbook` | `08-generated` |

**T1 — cross-domain override (HALT-eligible): 0.** Not a lucky corpus — unreachable by construction, because the classifier accepts a signal type only when it is valid for the file's domain. Since the schema's validation rule is exactly `type ∈ TYPES_BY_DOMAIN[domain]`, **the divergence class cannot produce a schema-invalid stamp at all.** Every live divergence is a *specialization within one domain*: a generic bin default yielding to a more specific type. A divergence is prima-facie evidence the classifier worked.

**FM-2 confirmed live, once.** Exactly one file (key `1e55b531c870`, in `4-Evidence`) has a filename signal that would give `plan` where the authoritative sub-bin correctly gives `email`. This is the mechanism working, and it is a **defect count of 1**, not the size of the 14-file class it sits in.

**T2 — the genuine over-claim sub-class.** Divergent rows whose stem carries a non-instance marker (`template`, `prompt`, `example`, `sample`, `boilerplate`, `skeleton`, `starter`) — a form or exemplar naming a type it is not an instance of:

| Key | default → resolved | folder |
|---|---|---|
| `8e184904bdcf` | `reference` → `plan` | `07-reference` |
| `723bf352faaa` | `reference` → `plan` | `07-reference` |
| `8ec4b7a405f4` | `tracker` → `status-log` | `04-operations` |
| `9f12cff8e8e7` | `tracker` → `status-log` | `3-Operations` |
| `451825add420` | `tracker` → `status-log` | `3-Operations` |

**AC-4 arithmetic.** Budget = `floor(0.05 × 200)` = **10**. Measured candidate ceiling = **5**. **Margin 5, on measurement.** AC-4 does not fail first at Stage 12 after the snapshot — which was the precise hazard this instrument exists to remove.

**Stated honestly: 5 is a *candidate* ceiling, not an adjudicated defect count.** Each of the five is hand-verified at Stage 12 and recorded individually in Part B; some will prove correct.

**Arms (all three mandatory, all three fired).** *Sensitivity:* the marker probe over the whole `would_stamp` set returns **7** — it is live and is not merely re-matching the divergence set (5). *Specificity:* a bogus marker returns **0**. *Non-degeneracy:* 152 files fire no signal at all, so the bound is not vacuous.

### § 8 — Pre-write marker gate (HALT-eligible, re-run immediately before the write)

**Predicate (D-3123-F).** For every file in the write set: `lifecycle_trigger ∈ _absent_core_keys(existing, proposed)` **OR** the file has no parseable frontmatter (a whole-block write includes the marker by construction). **The gate is a SET-IDENTITY assertion, never count-equality** — any file failing the predicate that is not in the enumerated exception list below is a **HALT**.

| Outcome | n |
|---|---|
| Write set | 200 |
| No parseable frontmatter → whole-block write, marker by construction | 132 |
| Marker present in the added-key set | 56 |
| **Exceptions — already carry a `lifecycle_trigger`, so the marker is NOT added** | **12** |

The 12 are correct, not a defect: `_absent_core_keys()` writes only ABSENT keys, and these files carry **real provenance** that must not be overwritten. That is also precisely why a marker-scan reversal is unsound — it would skip exactly these 12 — and why the reversal path is a **path-keyed snapshot** instead.

| Key | Existing `lifecycle_trigger` | Added-key set |
|---|---|---|
| `e87e279581ea` | `operator-send` | `filename`, `path` |
| `1cf9a6ca3108` | `user-request` | `filename`, `path` |
| `706dcef74e42` | `user-request` | `filename`, `path` |
| `5bc4d8bbab5b` | `user-request` | `filename`, `path` |
| `dc1e568e5e54` | `operator-decision` | `filename`, `path` |
| `df6a11ecee34` | `user-request` | `filename`, `path` |
| `2623104aa7cc` | `operator-confirmed-send` | `filename`, `path` |
| `73aa5a6f8cc4` | `user-request` | `filename`, `path` |
| `cdb3a2e2dda5` | `user-request` | `filename`, `path` |
| `4757305b29ed` | `transcript-processing` | `filename`, `path` |
| `16f04670f28e` | `transcript-processing` | `filename`, `path` |
| `062c3f2a792d` | `user-request` | `filename`, `managed_by`, `path`, `type` |

Existing-trigger histogram: `user-request` ×7 · `transcript-processing` ×2 · `operator-send` ×1 · `operator-decision` ×1 · `operator-confirmed-send` ×1. Added-key-count histogram across the whole write set: `{2: 11, 3: 15, 4: 1, 6: 2, 8: 2, 10: 16, 11: 16, 12: 5}`.

### § 9 — Snapshot plan (D-11, as corrected by D-3123-A′)

| Field | Value |
|---|---|
| **Scope** | The **union of BOTH writers' file sets** — node `would_stamp[]` ∪ the edge planner's plan-with-edges. A node-only snapshot misses every file the edge writer mutates. **Plus the derived sidecar path:** for every `would_stamp[]` entry whose suffix is **not** markdown, also snapshot `<source>.meta.yml` **if it already exists**. Without this clause the append-case files below are un-restorable — `stamp_sidecar()` mutates the *sidecar*, `iter_corpus_files()` skips `*.meta.yml`, and `run()` records the *source* path, so the mutated path can never enter a `would_stamp`-keyed snapshot. **No tool change is required to obtain these paths:** every mutated sidecar path is deterministically derivable from `would_stamp[]` alone — verified by set identity, derived-set == on-disk set, **4 = 4, symmetric difference 0** |
| **Measured** | node **200** · edge **196** · node-only **5** · edge-only **1** · both **195** ⇒ **union 201 files / 5.70 MB**. Point-in-time; re-derived immediately before the write per **AI-010** |
| **Sidecar disposition — a two-way split, not one class** | Re-derived live over `would_stamp` **185**: **143 markdown** (in-file frontmatter, no sidecar) · **38 non-markdown with no sidecar → CREATE** · **4 non-markdown with a pre-existing `.meta.yml` → APPEND**. Sum check `143 + 38 + 4 = 185`. The prior single figure of **39** asserted a class — *all non-markdown are creates* — that **no longer holds**: `stamp_sidecar()` takes its `if existing:` branch for the 4 and appends the absent keys to the sidecar. Restore must therefore **DELETE** a `created` sidecar and **RESTORE** a `pre-existing` one — the two are opposite operations and a boolean cannot carry both. *Arms:* sensitivity — 4 `*.meta.yml` on disk under the corpus root; specificity — a derived `<source>.meta.zzz` matches **0**; control — `iter_corpus_files()` yields **zero** `*.meta.yml` paths, so the walker's silence is a real exclusion rather than an empty disk |
| **Destination** | `[CLAUDE_WORKSPACE_ROOT]/.backup-pre-node-backfill-${BACKFILL_TS_UTC}/` |
| **Timestamp** | `date -u +%Y%m%dT%H%M%SZ`, sampled **once**, immediately before the snapshot. **Not a date.** All 30 shipped `.backup-pre-*` directories carry a full UTC timestamp and none carries a date-only suffix; nine distinct days in the snapshot history already hold more than one snapshot, and the worst holds six — a date-only suffix would have destroyed the rollback path on nine separate occasions |
| **Pre-existing target** | **Refuse and HALT.** An existing directory means a prior attempt; writing into it overlays the only good pre-write copy |
| **Manifest** | Per file: relative path, pre-write SHA-256 **of the path the writer actually mutates**, `sidecar_disposition ∈ {created, pre-existing, n/a-markdown}`, and the exact added-key set. **The boolean it replaces was a 2-state key for a 3-state problem** — `sidecar_created: false` is true of both a markdown file and an append-case sidecar, and those two take opposite restore actions |
| **Placement** | **Outside** the corpus root, so no tool rooted at the corpus re-scans it; the dot-prefix is a second, independent guarantee (`iter_corpus_files` skips any dot-leading segment) |
| **Verification** | Verify the copy by file count **and** byte total before the write proceeds. A failed or unverified snapshot ⇒ **HALT** |

**Token note:** `[CLAUDE_WORKSPACE_ROOT]` is the registered square-bracket form (94 files); the previously-recorded `${OPERATOR_WORKSPACE_ROOT}` is **unregistered** (0 files) *and* in a rendering form the depersonalization spec forbids. `${BACKFILL_TS_UTC}` is a genuine shell variable in a documented command sequence, not an operator-identity token.

### § 10 — Rollback: two independent paths

**Repo-side.** `git revert` of the merge restores the classifier, the schema surfaces, the ADR and this record. Reversibility **CHEAP · confidence HIGH**.

**Corpus-side.** Restore the snapshot, **path-keyed, never marker-keyed**. Branch on the manifest's 3-state `sidecar_disposition`:

| `sidecar_disposition` | Restore action |
|---|---|
| `created` | **DELETE** the `.meta.yml` — the writer created it, so there is nothing to restore to |
| `pre-existing` | **COPY THE SNAPSHOTTED `.meta.yml` BACK.** This is the case the boolean form silently no-op'd: it fell through to "copy the source file back", restoring a source the writer never touched while the appended keys stayed on the sidecar |
| `n/a-markdown` | Copy the source file back (in-file frontmatter) |

Then **re-hash the RESTORED path** — the path named by the disposition above, not the source path — against the manifest's pre-write SHA-256; **any mismatch ⇒ halt and report, never partially restore.** *Re-hashing the source is what made the old verification step unable to detect its own failure:* on the append case the source never changed, so its hash matched and the check passed over a restore that had not happened.

Reversibility **EXPENSIVE · confidence MEDIUM** — medium because the restore is specified but **not yet demonstrated**. **S6-equivalent obligation, and it is a Stage-12 gate rather than a note:** a demonstrated restore-then-re-apply on at least one file of **each of the three dispositions** converts this to HIGH, and the restated AC-8 below cannot honestly pass until it has run. A `pre-existing` case must be in that demonstration set — it is the disposition the prior spec got wrong, so a demonstration over markdown alone re-certifies the path that was never broken.

**The two paths are independent and must be briefed as such.** A `git revert` does **not** touch the corpus: it leaves files carrying `folder: _project-root` while the tree no longer defines that value, and the stamp writes only absent keys so it will not self-correct on a re-run. **The `--strip` flag that earlier records named as the reverser does not exist** — a repo-wide search returns 0 occurrences against a working sensitivity arm. A corpus stamped without a verified restorable snapshot is unreversible by any designed path.

**Ordering constraint against #5741.** #3123's corpus write executes **first**, then #5741's seeding. A restore that unwinds #3123 after #5741 has seeded must unwind #5741 first, or the seeded records are left referencing a classification vocabulary the corpus no longer carries.

### § 11 — Exclusion report (CIAC-1 clause 3)

Every exclusion introduced by any card in this release, with its measured Δ on **both** counters. Clause 3 does not forbid exclusions; it forbids **undeclared** ones.

| Exclusion | Card | Δ `orphans` | Δ `would_stamp` | Δ `excluded` |
|---|---|---|---|---|
| `NONPROJECT_TOP_SEGMENTS += transcripts` | #5668 / D-7 | −17 | 0 | +17 |
| `NONPROJECT_TOP_SEGMENTS += _pmo` | #5668 / D-7 | −1 | 0 | +1 |
| `EXCLUDE_PATTERNS += _inbox` | #5668 | −1 | 0 | +1 |
| `NONRECORD_PROJECT_SEGMENTS = {templates}` | #5668 / D-25 | −4 | −28 | +32 |
| `EXCLUDE_PATTERNS += _superseded` | **#3123** | **0** | **−32** | **+32** |
| | | | **total +83** | |

**Reading the Δ on one counter systematically understates an exclusion.** `templates` reads −4 on orphans and **−28 on `would_stamp`** — 28 blank forms that stop being stamped as records. `_superseded` reads **0** on orphans and **−32** on `would_stamp`: it is **aggregation-inert on `counts.orphans`**, which is the counter the exit rule reduces, so it provably cannot be "an exclusion added to drive the count down." Both columns are reported because either alone misleads.

**Baseline exclusion classes (unchanged by this release), for completeness:** `Archive/ excluded under scope=active` 1912 · `snapshot` 403 · `body-backups` 175 · `_archived` 44 · `staging` 23 · `_config` 22 · `_unclassified` 1 · `phase3-scratch` 1.

### § 12 — Tier-0-blocked rows and the operator-side change each required — **both now DELIVERED**

Two FCM rows were blocked at Engineering by Tier-0 controls. **Neither was bypassed**, and `CLAUDE_HOOK_BYPASS` was never set. Both were subsequently **delivered operator-side at `2b4f9062`**, an ancestor of HEAD, and both are reconciled in the Deviation Log above.

**This section was authored at the instant of the hook block and was not re-derived after the operator-side commit landed** — a `reconcile-dont-annotate` failure at the record surface, found independently by two graders on two different cards. It is reconciled here rather than annotated. The changes below are retained as the **specification** each row was measured against, not as outstanding work.

**Row 5 — `core/governance/OPERATIONS.md` — DELIVERED (`2b4f9062`, `+1 / −1`).** The union restatement at the ADR-080 taxonomy note gains the sentinel. Specified change, one line: after the existing union `{legacy 01-08, new 1-Governance…5-Reference + _inbox/_generated}`, add ` + _project-root`, and append the sentence: *"`_project-root` is a NON-BIN sentinel, not a sixth bin (ADR-139) — it names a project's own root-level governance files, which sit outside the taxonomy; the closed-set invariant above is unaffected and agents never route into it."* **Delivered as specified in substance**; the ADR citation was renumbered 137 → **139** at `be0c5bb8`.

**Row 6 — `operations/skills/project-initiator/SKILL.md` — DELIVERED (`2b4f9062`, `+12 / −7`).** The born-entity-frontmatter block moves from a 6-field to a 7-field block: add `folder: _project-root` after `domain: managed`, change "the 6-field entity block" to "the 7-field entity block", change "Five values are fixed" to "Six values are fixed", and state that `folder` is a NOT-NULL core field carrying the ADR-139 sentinel because PROJECT.md sits at the project root rather than in a bin. **Impact analysis is complete and cleared the edit:** the skill registry lists `project-initiator` as a `function-skill` with **no registered consumers** (control arm — `delivery-engine` returns 8 registry mentions, so the probe is live), so the Cross-Skill Impact set is legitimately empty. **The single hunk carries BOTH claimants** — #3123's 6→7-field block and #5741's misnomer correction — which is what the Release-Level Verification list requires, since the `pmo-skill-editor` regression pass grades the final combined state. The mirrored surface `operations/templates/project-md-composed-index-template.md` was delivered at Commit 3, and the two surfaces now **agree** on both the field count and the axis attribution.

**Consequence for the package rebuild (Commit 4) — FIRED, not pending.** `project-initiator/SKILL.md` **was** modified on this branch by `2b4f9062`, so its `.skill` package **was** stale, and the rebuild obligation fired. **Executed at `eeb85bf0`:** the `.skill` binary changed (82157 → 82348 bytes) and `.sha256` moved `+1 / −1`. The sequencing rule held — the rebuild landed after the SKILL.md edit, not before. *(The retired sentence read "`project-initiator/SKILL.md` is presently unmodified on this branch, so its `.skill` package is not stale on the current tree." **False on both clauses at HEAD.** A Stage-8 reviewer grading the package obligation against it would have concluded the rebuild never fired.)*

## Entity-Seeding Evidence Record

*Part A (pre-write), authored at Stage 6 Commit 3. This is #5741's PR-side gradeable artifact — the surface Stage 7 DT and Stage 8 QA grade, because the card's corpus deliverable is not readable from the PR diff. **Part B (post-write) appends here via the Stage-12 chore PR.*** The corpus-privacy construction is the one declared for the node-backfill record above and is not restated: every per-file row is keyed by the same opaque stable file key — `sha256(<corpus-relative path>)[:12]` — and everything else is a count, a depth index, a platform-vocabulary token or a schema key name.

### § A0 — Measurement instant

| Field | Value |
|---|---|
| Merge base | `origin/main` @ `ccd3be07` |
| Branch state measured | Commits 1–3 applied (#5668 + #3123 + #5741) |
| Date | 2026-08-21 |
| Mode | read-only throughout; no corpus file was opened for write and no seeding step was executed |

**Every count below is a point-in-time observation and MUST be re-derived immediately before the Stage-12 write (AI-010).** Two figures already moved between the node-backfill record and this one, on a byte-identical probe: the corpus `.md` denominator read **2 136** at Stage 5 and **2 142** here, and the `lifecycle_state:` sensitivity arm read **43** at Stage 5, **46** in the card body, and **46** here. The class structure is the durable output; the counts are observations.

### § A1 — Baseline census (every arm re-derived at Commit 3)

| Probe | Denominator | Result | Sensitivity arm | Specificity arm | Valid |
|---|---|---|---|---|---|
| `^entity_type:` corpus-wide | 2 142 `.md` | **0** | `^lifecycle_state:` → **46** | `^entity_typo:` → **0** | yes |
| `^owning_agent:` corpus-wide | 2 142 `.md` | **0** | as above | as above | yes |
| `^content_lifecycle_pattern:` corpus-wide | 2 142 `.md` | **0** | as above | as above | yes |
| `^portfolio_id:` / `^program_id:` corpus-wide | 2 142 `.md` | **0** / **0** | as above | as above | yes |
| `^id:` on in-scope `PROJECT.md` | 4 | **0** | `^---` opener → **4 / 4** | — | yes |
| `entity_type:` at the **project** tier | 4 | **0** | as above | — | yes |
| `entity_type:` at the **portfolio** tier | 22 `.md` | **0** | any `^<key>:` line → **3 / 22** | `^entity_typo:` → **0** | yes |
| `entity_type:` at the **shared-entity** tier | **1** `.md` | **0** | **none can fire — see below** | — | **arm declared weak** |

**The shared-entity tier's arm is disclosed as weak rather than reported as clean.** That tier holds a single `.md` file and it carries no frontmatter at all, so every in-tier arm attempted (`^---` opener, `^title:`, any `^<key>:` line) also returns **0**. A zero whose control arm also returns zero is a broken probe (D-50), so the liveness of this probe is established at the **corpus** level instead — the identical pattern returns 46 over 2 142 files — and the tier-local result is reported as *empty on a denominator of 1*, which is what it is. All three tiers are empty of conformant records; that part of the card's premise reproduces exactly.

### § A2 — Scope and denominators

| Population | n | Basis |
|---|---|---|
| `PROJECT.md` files anywhere in the corpus | **22** | depth histogram `{1: 4, 2: 11, 3: 2, 4: 4, 6: 1}` |
| Excluded — under the archived top segment | **18** | `CLOSED` / archived: read-only reference per `CLAUDE.md § Project Lifecycle` |
| **In-scope candidates** (depth ≤ 1, non-archived) | **4** | the seeding population |
| Resolving in-enum under the §3b parse rule | **4 / 4** | all resolve `ACTIVE` |
| Excluded for unresolved status | **0** | the refusal path exists but does not fire on this corpus |

**The §3b parse rule was corrected at build, and the correction is the difference between delivering and not.** The Stage-5 draft specified *"first whitespace-delimited token, upper-cased, require membership"*. Measured against the live corpus that rule resolves **0 of 4** — every in-scope file writes the value inside backticks, so the naive first token is never in-enum and the protocol would write **no Project record at all**.

**Wrapper and compound census, re-derived — the previously published histogram did not reproduce.** Leading wrapper: **single backtick 4 / 4**; double backtick **0 / 4**. *(The retired figure `` {`: 2, ``: 2} `` does not reproduce on any leading-wrapper reading.)* The real 2/2 is a **different axis, and it is the load-bearing one**: **2 of the 4 in-scope records carry a compound `**Status:**` value** — code spans of **3** and **4** whitespace tokens, against **1** token each for the other two — so **half the in-scope population is resolved by §3b's compound-value clause** (*"a compound value contributes its leading token only"*), which the record never said. The complementary 2/2 is trailing content after the code span, on the opposite pair of records. *Arms:* sensitivity — all **4 / 4** have a parsable code span; specificity — leading `*` or `_` wrappers **0 / 4**. **S5 must re-derive the compound incidence at write time**, so the branch's firing rate is a measurement rather than an assumption. Adding the normalization step (strip surrounding `` ` `` / `*` / `_` and trailing punctuation before the enum test) resolves **4 of 4**. Specificity arm: the normalized token matches a bogus enum `{ARCHIVED, PENDING}` on **0 of 4**, so normalization is not simply making everything pass. The shipped §3b rule carries the step as step 2 of 3, marked load-bearing.

### § A3 — Per-tier write plan (project tier, realized add-key sets)

Nine-key set per §3b; `lifecycle_state` and `created_date` are in the **untouched** set on the **Project tier (S4) only**, because that tier's backing file is a stamped ecosystem node and the node stamper supplies both keys. **On the Portfolio (S2) and Person (S3) tiers nothing else supplies them, so the seed writes both.**

**This sentence previously read *"at every tier, without exception"*, and that contradicted the shipped `project-schema.md` §7, which scopes the exclusion to S4.** Following it literally would have broken **four distinct L1 rules per record** on each unstamped tier — Person: **V-PER-05** (`lifecycle_state` ∈ {active, inactive}), **V-PER-06** (`created_date`, = V-CORE-06 instance), inherited **V-CORE-03** and **V-CORE-03b**; Portfolio: **V-PORT-04**, **V-PORT-05** (= V-CORE-06 instance), **V-CORE-03** and **V-CORE-03b**. The gate this breaks is **`project-schema.md` §7 S5** — *"every L1 rule for that entity satisfied (V-CORE-03 **and** V-CORE-03b)"* — **not** card AC-2, which grades `entity_type` alone. **S3 is the worse of the two tiers:** S2 at least said *"its `lifecycle_state` is unambiguously the entity's Axis-1"*, which signals a write, while §3.10's field table does not list `lifecycle_state` at all (it is inherited Core, surfaced nowhere in that section's own rows), so an executor reading S3 got **no signal whatsoever** that it must be written. Both tiers now carry an explicit write instruction and a full per-tier key enumeration in `project-schema.md` §7.

**The FM3-1 enumeration mitigation was measured absent and is now delivered.** Probe over the three #5741-shipped artifacts (`project-schema.md`, this plan, ADR-138): `portfolio_name` → **0 / 0 / 0**. *Sensitivity:* `portfolio_id` 2 / 4 / 0 · `person_id` 24 / 1 / 0 · `entity_type` 2 / 7 / 2 — all fire. *Specificity:* `portfolio_nayme` → **0** everywhere. The field is **defined** in `entity-field-schemas.md` §3.13 (3 occurrences) and was **never sourced** in any write set. The measured tier asymmetry was the finding: **Project 9 of 9 keys sourced with a named target file · Person 3 of ~11 · Portfolio 1 of ~10, and neither S2 nor S3 named its target file at all** — a write set computed against the one tier that has a collision, generalised to the two that do not, which is FM3-1 verbatim.

**Scoped honestly:** the *enumeration* is delivered (both tiers, every key, in `project-schema.md` §7). Completing the **sourcing** is not a text fix — six keys across the two tiers have no value source anywhere on this branch, so they are marked `UNSOURCED` and collected as operator inputs at Stage 12, with S5 asserting each present-and-non-empty or halting. The two **target filenames** are likewise recorded as an explicit operator decision rather than invented, because `project-entity-model.md` §7 defers physicalization and ADR-138 declined to give the Portfolio record a declared producer.

| Key | add | already present | `NEVER`-set keys already on file |
|---|---|---|---|
| `199cd64d52c3` | 7 | `status`, `delivery_approach` | — |
| `694a627ca59d` | 9 | — | — |
| `9dc4fd4bad65` | 9 | — | `lifecycle_state`, `created_date` |
| `ab36874e0baf` | 9 | — | `lifecycle_state`, `created_date` |

Add-count histogram `{7: 1, 9: 3}`. **Add-absent-keys-only** makes the one partially-populated record a 7-key add rather than an overwrite, which is the property that makes a re-run a no-op.

**The two files carrying no `lifecycle_state` are the ordering constraint, made concrete.** V-CORE-03b (the D-42 presence guard, ADR-138 D5) is discharged on a `PROJECT.md` by the node stamper's value. Two of four in-scope files do not carry it yet. Seeding before the backfill would therefore leave **2 of 4** seeded records failing an L1 rule through no fault of the seed. This is not a restatement of the plan's ordering claim — it is the measurement that makes it load-bearing rather than tidy.

### § A4 — Source of truth per key

| Key | Derivation | Class |
|---|---|---|
| `id` | project folder slug, normalized per the artifact-naming standard | derived |
| `entity_type` | literal `Project` | constant |
| `status` | inline `**Status:**` line via the §3b 3-step parse rule | derived |
| `content_lifecycle_pattern` | literal `Living` — frozen per-entity Axis-2 constant | constant |
| `owning_agent` | literal `ppm-agent` — maintain side of the frozen triplet | constant |
| `project_name` | project folder display name | derived |
| `delivery_approach` | file key when present (**1 of 4**), else `operator.toml` default | derived / config |
| `project_owner` | the operator's `person_id` | **operator-supplied** `[ASSUMPTION – CONFIRM]` per D-5741-9 |
| `portfolio_id` | the `portfolio_id` of the record seeded at S2 | FK, resolved in-run |

No key is defaulted where it is underivable: `project_owner` is listed as operator-supplied rather than invented, and an unresolved `status` refuses the record instead of coercing it.

### § A5 — FK resolution table

| Ref key | Target | Rule | on-unresolved | Resolvable because |
|---|---|---|---|---|
| `project_owner` | Person record | V-PRJ-08 | **BLOCK-WRITE** | S3 runs before S4 |
| `portfolio_owner` | the same Person record | V-PORT-03 / V-PORT-06 | **BLOCK-WRITE** | S3 runs before S2's owner is read back at S5 |
| `portfolio_id` | Portfolio record | V-PRJ-05 | WARN-HEALTH | S2 runs before S4 |

**Tier order S2 → S3 → S4 is forced by FK direction, and two of the three edges are BLOCK-WRITE.** Reordering does not degrade the records; it makes them invalid at the instant they are written.

### § A6 — Audit-readiness arithmetic

Each entity-grain completeness factor, stated as `n/d` with the denominator it will carry post-seed. Pre-seed every `d` is **0**, which is the readiness gap this card closes.

| Factor | `d` pre-seed | `d` post-seed | Note |
|---|---|---|---|
| `%entities-present` | 0 | **6** (4 Project + 1 Person + 1 Portfolio) | three tiers, all non-empty |
| `%fields-populated` | 0 | **9 per Project record**; per-entity field count at the other two tiers | denominators are the §3.N required sets, not a flat constant |
| `%relationships-valid` | 0 | **3** scalar ref edges (§ A5) | `relationships[]` is deliberately not written, so the factor measures the scalar refs |

**Coverage envelope, named rather than dropped.** Sixteen of the nineteen entity types are **not** seeded by this card and are expected-absent, not missing: the seed covers Project, Person and Portfolio only. A completeness score that counts the other sixteen as absent-therefore-incomplete is measuring the card's declared scope as a defect.

### § A7 — Non-interference assertions

- **N-1 — disjoint key sets.** The seeded 9-key set ∩ the node stamper's core field set = **∅**. *Sensitivity:* the same intersection computed over the 9-key set **plus** the two `NEVER` keys returns **2** (`lifecycle_state`, `created_date`), so the method returns non-empty when overlap exists and the empty result is a measurement rather than a broken probe.
- **N-2 — no counter movement.** The seed adds no exclusion, no classifier table entry and no new file to any scanned population, so the stamper's `counts` block is invariant across it. The seeded Portfolio record lands in a non-project top segment; the Person record lands in a segment that joins that set in this release; the snapshot lands outside the corpus entirely **and** dot-leading.
- **N-3 — no new orphan.** Project records modify files already in the census. The orphan **reason census** is therefore invariant under the seed, which is a stronger and more directly gradeable statement than scalar invariance.
- **Stated as assertions, not as independence.** The two writes are *ordered* and the ordering is load-bearing (§ A3). Nothing here claims they are independent.

### § A8 — Snapshot plan and mover survival

| Field | Value |
|---|---|
| Destination | `[CLAUDE_WORKSPACE_ROOT]/.backup-pre-entity-seed-<YYYYMMDDTHHMMSSZ>/` |
| Timestamp form | `date -u +%Y%m%dT%H%M%SZ`, sampled once, immediately before the copy |
| Convention corroboration | **30** `.backup-pre-*` directories at the workspace root; **30 / 30** carry a full UTC timestamp, **0** carry a date-only suffix. *Sensitivity:* `.backup-*` → **32**. *Specificity:* `.backup-zzz-*` → **0** |
| Pre-existing target | `.backup-pre-entity-seed-*` → **0** today. S1 **refuses and halts** if the resolved directory exists |
| Manifest | per file: relative path, pre-write SHA-256, pre-existing frontmatter key set, exact added-key set, and `RESTORE-ORDER` |
| Verification | file count **and** byte total verified before any mutation; unverified ⇒ **HALT** |

**Mover survival, each dispositioned.** The generated-bin destination is excluded because the folder-taxonomy reshape renames that bin — a reversal path the operation itself relocates mid-flight is not a reversal path. A project-root destination is excluded because the write set spans three tiers, two of which are not project roots. The workspace root survives both: the corpus iterator skips any dot-leading path segment, so the destination is **structurally** unreachable rather than policy-excluded, and it sits outside the corpus root as a second independent guarantee.

**Token note.** `[CLAUDE_WORKSPACE_ROOT]` re-verified at Commit 3: registered in the depersonalization spec's token table, **86** files carry it. `OPERATOR_WORKSPACE_ROOT` returns **1** file — this plan, in the node-backfill record's own token note — confirming it is discussed but never used as a token.

### § A9 — Rollback: two independent paths

**Repo-side.** `git revert` restores the four schema surfaces, the ADR and this record. It reaches **no** corpus file. Reversibility **CHEAP · confidence HIGH**.

**Corpus-side.** Restore the S1 snapshot, **path-keyed**: copy each manifest entry back and re-hash against its pre-write SHA-256; any mismatch ⇒ halt and report, never partially restore. Reversibility **EXPENSIVE · confidence MEDIUM** — medium because the restore is specified and, as of this record, demonstrated on no record. S6 exists to convert that to HIGH before the release closes.

**A revert decided after the Stage-12 write must do both.** Reverting the repository alone leaves seeded records valid against a rule the tree no longer defines.

### § A10 — Stage-12 restore ordering (binds both corpus-writing cards)

Two pre-write snapshots will exist over an overlapping file set, taken at different instants. They do not compose in either direction:

> The backfill's snapshot is **pre-seed** — restoring it after the seed has landed silently discards the seed on every shared file. The seed's snapshot is **post-backfill** — restoring it after a backfill restore re-applies the backfill. **LIFO only:** restore the seed's snapshot before the backfill's, and re-run the seeding protocol S1–S6 after any backfill restore.

The same rule is carried in the seed snapshot's `RESTORE-ORDER` manifest field, because a rollback operator on a git-ignored tree reads the snapshot directory rather than a tracked plan. Write order is #3123 then #5741; restore order is the exact inverse.

### § A11 — Tier-A design artifact (declared for Stage-13 G-CL6)

Activated by the Data-flow row — this release modifies schema and contract files with cross-component data flow. Produced **embedded** (below the ≥3-parent-doc centralization threshold) as the two-record key table and the persisted-key-set table in `project-schema.md` §3b, plus the FK resolution table at § A5 above.

### § A12 — Tier-0-blocked row for this card — **DELIVERED**

**`operations/skills/project-initiator/SKILL.md` — the `:193` "born-aligned entity record" misnomer.** `D-48-ROUTING` resolved to **RETAIN** (the sibling milestone's Stage-4 plan never named the regions, so the plan's stated fallback applies), and the row was promoted from CONDITIONAL to live. It was blocked at Engineering for the same Tier-0 reason as row 6 of the node-backfill record — `BLOCK-SKILL-EDIT-001` in enforce mode, whose sanctioned path needs a session sentinel the agent is forbidden to self-create. **It was not bypassed and `CLAUDE_HOOK_BYPASS` was never set.** **It is now DELIVERED — `2b4f9062`**, in the single combined operator-side edit, with the package rebuilt at `eeb85bf0` and the ADR citation renumbered at `be0c5bb8`.

**The change, as specified and as delivered, folded into the same combined edit as row 6:** the block is the **node axis**, not the entity record — replace "born-aligned entity record" with a node-frontmatter framing, and correct the `lifecycle_state` characterization, which read as the ENTITY maturity axis and is the FILE/NODE content-maturity axis. The Project entity's Axis-1 carrier is `status` (ADR-138 D1, V-PRJ-03), the entity-record keys are not part of the born block, and they are seeded by `project-schema.md` §7 rather than written at scaffold time.

**Why one combined edit rather than two.** The Release-Level Verification list requires the `pmo-skill-editor` regression pass to run **once against the final combined state** of this file. Landing #3123's 6→7-field change and this misnomer correction separately would have graded an intermediate state that never ships. **The mirrored template surface — `operations/templates/project-md-composed-index-template.md` — was delivered at Commit 3**, with both corrections applied and #3123's `_project-root` sentence preserved byte-identical. **The two surfaces now AGREE**: both say "7-field node block", both name `status` as the Project entity's Axis-1 carrier with the same two citations, and both cite ADR-139. *(The retired tail — "so until the combined edit lands the SKILL.md text and the template disagree on both the field count and the axis attribution" — described a state this branch has left.)*

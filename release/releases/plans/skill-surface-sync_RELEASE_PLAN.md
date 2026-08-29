---
title: Release Plan — skill-surface-sync
purpose: Stage-4 release plan for the six skill-surface defects — a skill's shipped surface, its deployed copy, and the checks that verify them tell one consistent story.
type: release-plan
plan_type: release
status: ACTIVE
release_class: novel
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->

# Release Plan: skill-surface-sync — A Skill's Source, Its Shipped Package, and the Checks That Verify Them Tell One Story

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #6261, **reconciled to the two PLAN CORRECTIONS comments on that same sub-task** (wave-1 Corrections 1–4, wave-2 Corrections 5–9) and to the six Stage-5 Solutioning outputs. The correction comments **supersede** the Stage-4 comment; where they differ, the corrected text is what appears below and the § Deviation Log records the delta. Authored at Engineering Commit 0 by the first Engineering spoke (sub-task #6325, issue #5236).

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure against tags ∪ published Releases ∪ ledger `DEPLOYED`/`VERIFIED` rows ∪ in-flight sibling holds; anchor **v4.43**, recomputed next-free **v4.44**, planned value free. |
| **Date Created** | 2026-08-29 (Saturday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/skill-surface-sync` |
| **PR** | not yet opened — the release ships as a SINGLE PR with one merge gate, opened after the last Engineering spoke |
| **Milestone** | `skill-surface-sync` |
| **Release Class** | `novel` — re-classified from the declared `routine` at the Stage-4 D-Gate on verified trigger evidence |
| **Effective points** | **23** — `round_half_up(20 × 1.15)` across 6 issues, inside the 15–25 band. No re-bundle required. |
| **Branch topology** | **SINGLE** (D-C) — one branch, one PR, one merge gate; this plan lands as Engineering Commit 0 |
| **Concurrency posture** | **P0 fully-serial** — one Engineering chip at a time; the next chip waits until the prior commit lands. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `e19a9d30` — re-fetched at Engineering Commit 0 and **verified unchanged** from the Stage-4 and Stage-5 pins, so no re-baseline was required |

## Release Outcome Statement

**AFTER** this release: a skill's authored source, its shipped `.skill` package, and the governance surfaces that describe both tell one consistent story — the checks that claim to verify that story either resolve or say plainly that they do not.

**BEFORE:** `pmo-skill-editor` Mode C instructs the reader to run six `RC-NN` check IDs that resolve to nothing, and cites a "Check Application Matrix" section that does not exist. `delivery-engine` is named the sole maintainer of the Axis-1 work-state machine and references that field in 0 of its 12 files. `pmo-architect` carries two live `UNSOURCED-DOMAIN` residuals because the security and data domain guides were never authored. Post-merge skill deployment is a manual step documented as manual, so source and installed copy drift silently. The chained-invocation arg contract is `key=value` with no JSON form. And the package-freshness gate that would catch a stale shipped surface runs in `warn` posture behind no required-status context — so it cannot block anything.

**#196 is a declared composition exception** — it is retained by operator decision as a capacity extension against unfired demand, and is deliberately **not** claimed by this Outcome Statement. If capacity forces a cut, it is the correct and honest drop candidate, which is why it is sequenced last.

## Scope

### Issues Included

| # | Issue | Title (abbreviated) | Size | Stage 5 |
|---|-------|---------------------|------|---------|
| 1 | #5236 | re-verify then drain the reported stale `.skill` packages | S | APPLIED (trivial) |
| 2 | #4975 | author `security.md` + `data.md` domain best-practice guides | M | APPLIED |
| 3 | #4442 | `pmo-skill-editor` Mode C instructs running checks that do not exist | S | APPLIED |
| 4 | #5056 | `delivery-engine` does not reference the Axis-1 work-status field | M | APPLIED |
| 5 | #192 | automate post-merge skill deployment to prevent source/install drift | M | APPLIED |
| 6 | #196 | upgrade chained skill invocation arg encoding to JSON | M | APPLIED |

Six members, 20 raw points, 23 effective under the `novel` 1.15 multiplier. All six admit into the release. Zero C3 findings, zero Tier-0 escalations, zero hard blocking dependencies inside the bundle.

### Composition Lock

**Locked at:** Stage 4 Planning entry · 2026-08-29 (Saturday) · planning sub-task #6261. Additions to the bundle are forbidden from Stage 5 Collective Review; removals require a governed override.

## Dependency Graph

Native GitHub edges, read at `e19a9d30`:

```
#196 --blocked-by--> #618   [SATISFIED — #618 CLOSED/COMPLETED]
#196 --blocked-by--> #160   [REMOVED — waived at the readiness gate as sequencing-only; not re-litigated]
#192 --parent-------> #1182  (epic; inherits design, not a blocking edge)
#196 --parent-------> #1107  (epic; inherits design, not a blocking edge)
#4442, #4975, #5056, #5236  — no parent, no blocked-by, no blocking
```

**Hard blocking edges inside the bundle: 0.** Probe: the `blocked-by` field read over all six members; non-empty on exactly one (#196 → #618, closed). Control: the same field renders populated for #196, so the empty reads on the other five are a real absence, not a field that never populates.

Compositional (soft) edges — these order the work, they do not gate it:

```
#4442 ──shared-file──> #196     release/skills/pmo-skill-editor/SKILL.md   [DISSOLVED at Stage 5 — see below]
#5056 ──shared-file──> #196     operations/skills/delivery-engine/SKILL.md (+ its .skill package)
#192  ──narrative────> #5236    core/rules/skill-deployment.md: the post-merge deploy mechanism and the
                                package-rebuild obligation are two halves of one skill-surface-sync story
#5236 ──prerequisite-> (out-of-scope enforce-flip; owned by NO member — carried, not closed; AI-003)
```

**The `#4442 ──> #196` shared-file edge DISSOLVED at Stage 5** (Correction 6): #196's design no longer touches `release/skills/pmo-skill-editor/SKILL.md`, so that file is now single-claimed by #4442. This is what drives the CIAC-2 re-scope (D-L).

**Zero circular chains.** The directed edge set admits a topological order (the Implementation Sequence below); a cycle would make that impossible. Control arm: deliberately adding the reverse edge `#196 → #4442` to the same set produces a detectable 2-cycle, so the acyclicity check is non-vacuous.

## Implementation Sequence

Dependency-ordered, contention-minimizing. One PR, one merge, on a single `release/skill-surface-sync` branch.

| Order | Issue | Size | Why here |
|---|---|---|---|
| **1** | **#5236** | S | Zero file contention; recording-only. Landing it first converts the freshness narrative from an open question into a settled prerequisite the rest of the release can cite — in particular #192 at position 5, which must not describe the freshness gate as merge-blocking (INT-1). |
| **2** | **#4975** | M | Purely additive on its two new guides. Highest estimate variance in the bundle (external evidence-tier sourcing), so it starts early where it has room to run long. |
| **3** | **#4442** | S | Settles the `RC-` namespace question and rewrites Mode C. Its shared-file edge to #196 dissolved at Stage 5, so this position is now driven by layer order rather than contention. |
| **4** | **#5056** | M | Settles `delivery-engine`'s mode and gate bodies **before** #196 appends a parse clause to the same file. |
| **5** | **#192** | M | Isolated from every skill body. Lands after the skill edits so the first exercise of the new deploy mechanism runs against the release's real changed-skill set. Reads #5236's record before writing the freshness narrative. |
| **6** | **#196** | M | **Last, for three converging reasons.** (a) It is the only member that still co-edits a file owned by another member (`delivery-engine/SKILL.md`, with #5056) — applying a small additive parse clause to an already-settled body is strictly less rework than the reverse order. (b) It carries the release's largest residual scope risk. (c) It is the declared composition exception, so the tail is the honest place for it. |

**Package rebuild discipline (Engineering constraint, not a preference).** Every skill-source edit stales its `.skill` package. Rebuild each affected package **once, after its final source touch**, via `bash core/deploy/tools/build-skill-packages.sh <skill>`, and commit the package plus its `.sha256` content-baseline sidecar in the same PR. `delivery-engine` is touched twice under this sequence (steps 4 and 6) — it is rebuilt **once, after step 6**. Historical precedent for getting this wrong: v3.35 shipped 9 edited skills with 0 rebuilt packages and 28/28 CI green.

**Mandatory tooling.** Every `SKILL.md` edit MUST route through `pmo-skill-editor` per the mandatory-tooling clause of [`skill-deployment.md`](/core/rules/skill-deployment.md). `deploy.sh --check` Check 10 asserts the editor audit-trail trailer on the last non-merge commit.

**Edit by anchor, never by line number (Correction 9).** Cited line positions in issue bodies and Stage-5 specs are historical, and sibling cards move lines within this release. This binds #196 specifically: it anchors at the heading `### Step 1 — Check for chained invocation` and at the bolded phrase `**chained=true** arg semantics`. The latter sits **below** #5056's `TRACKER_UPDATE` insertion points, so its line number shifts within this release. Anchor by heading and bolded phrase, never by `:484`.

## Stage Applicability Matrix

Default is all stages apply. Stage 5 skips only on triviality; Stages 7–8 skip only on no functional impact.

| Issue | S5 | S6 | S7 | S8 | S9 | S12 | S13 | Notes |
|-------|----|----|----|----|----|-----|-----|-------|
| #5236 | ✓ *(trivial)* | **minimal** | **SKIP** | ✓ | ✓ | ✓ | ✓ | **The one deviation from all-stages-apply.** S6 produces **no in-tree source change** — the deliverable is the recorded verdict table plus the three-vector invisibility-cause statement. S7 is skipped under the stage rule (no functional change to test). **S8 is retained** — AC-1..AC-4 are per-criterion gradable against the record, and that grading is the card's actual value. |
| #4975 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | S7 must verify the `domain_practice` provenance label (Mode B) — this is the release's flagged domain. |
| #4442 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Full ladder. |
| #5056 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | AC-5 is `[DEFERRED]` — declared method, execution post-deploy. Carries a Stage-13 G-CL6 refresh obligation. |
| #192 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | AC-5 is `[DEFERRED]` — spans ≥3 subsequent releases; route to the S13 outcome window. Authors an ADR at S6 as its first commit. |
| #196 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | Full ladder. AC-4b is `[DEFERRED]` — runtime observation. |

## Contention Map

### Within-release

Files claimed by ≥2 change-specs, after the Stage-5 corrections:

| Path | Claimed by | Class | Resolution |
|------|------------|-------|------------|
| `operations/skills/delivery-engine/SKILL.md` | **#5056**, #196 | `line-range-overlap` | Sequence #5056 (4) before #196 (6). #5056 rewrites mode and gate bodies; #196 appends a parse clause to the settled result, anchored by heading and bolded phrase (Correction 9). |
| `packages/delivery-engine.skill` + `.sha256` | **#5056**, #196 | rebuild collision | Rebuild **once**, after step 6. |

**Contended paths: 2.** Both serialized by the Implementation Sequence. Every other path in the matrix is claimed by exactly one issue.

**Two Stage-4 contention rows dissolved at Stage 5.** `release/skills/pmo-skill-editor/SKILL.md` and `packages/pmo-skill-editor.skill` + `.sha256` were recorded as `#4442 × #196` collisions. Correction 6 confirms #196 no longer touches that file, so both paths are now single-claimed by #4442. **#192 and #4442 share zero files** (Correction 5): #192's `core/deploy/deploy.sh` row resolved NOT-SELECTED, so D-G's post-#4442 sequencing constraint is moot.

### Cross-release

**Open PRs: 0** repo-wide at the pin. Per audit-baseline discipline this zero is **explicitly not load-bearing on its own** — it is a transiently-empty population, and it is recorded with its pin rather than as a finding: *none open at `e19a9d30` / 2026-08-29T04:17:24Z*. Stage 9 Phase A6.6 re-measures fresh.

**Recently-merged (last 12 PRs):** union = 45 distinct paths; intersection with this release's projected matrix = **3** — `core/deploy/deploy.sh`, `core/config/allowlists/script-execution-allowlist.txt`, `core/standards/gate-efficacy-standard.md`. All three counterparties are already merged and included in the base pin, so `overlap_class = single-pr` for each: informational, no sequencing mitigation owed. Sensitivity arm: the same intersection against a known-touched probe set returns a non-empty result. Specificity arm: a fabricated path returns ∅.

**Structural-blast-radius (Tier-S) sub-audit:** this release's mover-set is **empty** — no member renames, relocates, or deletes any path (3 pure adds, the rest edits). With an empty mover-set, `SURFACE(R)` is empty and no sibling can intersect it. Tier-S serialization edges: **0**.

### In-Flight Release Roster

**Measured at:** `e19a9d30` · `2026-08-29` (Engineering Commit 0 re-measure) · **Population:** n=2 siblings (1 genuinely in flight)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|------|----|----|----|----|----|----|
| `declarations-have-a-firing-surface` | — | `9a06be99` | **version-less (theme-named)** | none — claims no slot | **N/A — no version slot contended** | — (its Commit-0 delta vs `main` is its own plan file only) |
| `operational-folder-enforcement-migration` | — | `9dcb960f` | UNRESOLVABLE | — | UNRESOLVABLE | — (empty) |

**`declarations-have-a-firing-surface` is new since the Stage-4 roster** — it branched after the Stage-4 measurement and is **12 commits ahead** of `origin/main`, baselined at the same `e19a9d30`. It is recorded here rather than inherited from Stage 4 because the roster is a pinned measurement and this one was re-taken at Commit 0. Its own plan file declares it **version-less / theme-named — no tag is claimed at Stage 12**, so it holds **no version slot** and cannot contend with this release's `v4.44`. Its Commit-0 delta against `main` adds exactly one path (its own plan file), which intersects this release's File Change Matrix at ∅.

`operational-folder-enforcement-migration` is **0 commits ahead** of `origin/main` — fully merged, so its EDITSET is empty and it cannot contend. It is recorded as a row rather than omitted, per the never-a-silent-omission rule. It declares no bump-class, so both version columns render `UNRESOLVABLE` — an unknown, not an absence.

## File Change Matrix (machine-readable)

`domain_practice: { source: UNSOURCED-DOMAIN, date: 2026-08-28, rationale: #4975 authors the security + data domain guides for two domains the corpus does not encode; pmo-architect carries 2 live UNSOURCED-DOMAIN residuals at e19a9d30, domain: governance }`

> **Mode B, not Form X — and the choice is deliberate.** The matrix consists entirely of internal pmo-platform artifacts, which would permit the sourcing-exempt Form X (`N/A — pipeline-internal release`). That reading is rejected as **vacuous here**: this release exists in part to author the domain guides for two domains the corpus demonstrably does not encode, and declaring the release sourcing-exempt would paper over the exact gap #4975 closes. Dominant `domain:` class is `governance` (the matrix is governance, standards, rules and skill artifacts); secondary `software` (#192's hook script and `core/deploy/deploy.sh`).

**Zero CONDITIONAL rows remain.** Every Stage-4 conditional resolved at Stage 5 and is promoted into the unconditional set in this commit, or dropped to the non-scope block with its basis — per the fired-conditional promotion rule. A row left CONDITIONAL after its condition has resolved is an authoring defect, so none are carried.

```
# ── #5236 — freshness measurement + recording ──
# No in-tree source change. The deliverable is a recorded verdict table plus the
# three-vector invisibility-cause statement, posted on the parent thread (#5236),
# which is the surface AC-2's own grading method names. Nothing is rebuilt and no
# package is edited: both named packages measured content-fresh.

# ── #4975 — domain best-practice guides (security + data) ──
core/standards/domain-best-practices/security.md                              add
core/standards/domain-best-practices/data.md                                  add
core/specs/framework-catalog.md                                               edit
release/skills/pmo-architect/SKILL.md                                         edit
release/skills/pmo-data-engineer/SKILL.md                                     edit
core/specs/domain-token-registry.md                                           edit
release/references/pipeline/stage-04-planning.md                              edit
packages/pmo-architect.skill                                                  edit
packages/pmo-architect.skill.sha256                                           edit
packages/pmo-data-engineer.skill                                              edit
packages/pmo-data-engineer.skill.sha256                                       edit

# ── #4442 — pmo-skill-editor Mode C check resolution ──
release/skills/pmo-skill-editor/SKILL.md                                      edit
core/standards/gate-efficacy-standard.md                                      edit
core/standards/canonical-skill-structure.md                                   edit
core/deploy/deploy.sh                                                         edit
packages/pmo-skill-editor.skill                                               edit
packages/pmo-skill-editor.skill.sha256                                        edit

# ── #5056 — delivery-engine Axis-1 state binding ──
operations/skills/delivery-engine/SKILL.md                                    edit
operations/skills/delivery-engine/references/lifecycle-stages.md              edit
operations/skills/delivery-engine/references/gate-definitions.md              edit
operations/skills/delivery-engine/references/gate-checklists.md               edit
packages/delivery-engine.skill                                                edit
packages/delivery-engine.skill.sha256                                         edit

# ── #192 — post-merge deploy automation (Approach B selected) ──
core/rules/skill-deployment.md                                                edit
docs/INSTALL.md                                                               edit
docs/UPDATE.md                                                                edit
docs/scripts/setup-workspace.sh                                               edit
core/hooks/git-post-merge-deploy.sh                                           add
core/config/allowlists/script-execution-allowlist.txt                         edit

# ── #196 — JSON chained-arg encoding (4 contract-carrying skills) ──
core/governance/OPERATIONS.md                                                 edit
operations/skills/artifact-generator/SKILL.md                                 edit
operations/skills/comms-writer/SKILL.md                                       edit
operations/skills/delivery-engine/SKILL.md                                    edit
operations/skills/tracker-manager/SKILL.md                                    edit
core/skills/pmo-qa-auditor/references/conditional-auq-presence-detection.md   edit
packages/artifact-generator.skill                                             edit
packages/artifact-generator.skill.sha256                                      edit
packages/comms-writer.skill                                                   edit
packages/comms-writer.skill.sha256                                            edit
packages/delivery-engine.skill                                                edit
packages/delivery-engine.skill.sha256                                         edit
packages/tracker-manager.skill                                                edit
packages/tracker-manager.skill.sha256                                         edit
packages/pmo-qa-auditor.skill                                                 edit
packages/pmo-qa-auditor.skill.sha256                                          edit
```

#### Read-only inputs

```
core/standards/entity-lifecycle-protocol.md                                   READ
core/standards/review-composition-framework.md                                READ
core/ADRs/ADR-125-status-fallback-k1-binding-k4.md                            READ
core/standards/regression-checks.md                                           READ
.github/workflows/skill-package-freshness.yml                                 READ
.github/skill-package-freshness.enforce                                       READ
core/deploy/tests/test_package_freshness_exit_codes.sh                        READ
```

#### Release-wide explicit non-scope

```
packages/finops-usage-extractor.skill                                         NOT EDITED
packages/pmo-skill-refiner.skill                                              NOT EDITED
core/standards/regression-checks.md                                           NOT EDITED
core/schemas/work-item-type-schema.md                                         NOT EDITED
core/deploy/deploy.sh                                                         NOT EDITED
.github/workflows/skill-deploy.yml                                            NOT EDITED
operations/skills/tracker-manager/SKILL.md                                    NOT EDITED
required_status_checks (branch protection)                                    NOT EDITED
.github/skill-package-freshness.enforce                                       NOT EDITED
```

**Why each non-scope row is there** — an exclusion with no recorded basis is indistinguishable from an omission:

- **`finops-usage-extractor.skill` / `pmo-skill-refiner.skill`** — both measured content-fresh at two pins with an executed control arm. The reported drain population is empty, so no rebuild is owed. This is #5236's whole finding.
- **`core/standards/regression-checks.md`** — **removed from #4442 by Correction 2.** The SKILL.md's `references/regression-checks.md` path **resolves correctly at runtime**: `TEMPLATE_SYNC_MAP` in `core/deploy/deploy.sh` carries the `pmo-skill-editor:regression-checks.md:references/regression-checks.md` entry, injecting the canonical file into the package. No skill-local source file exists, and rewriting that path to `core/standards/` **would break a working reference**. It stays a READ input.
- **`core/schemas/work-item-type-schema.md`** — **removed from #5056 by Correction 8** (7 paths → 6). Its § 5 line 536 states verbatim that the one-time generalization teaching each reader skill to read the registry *"is not in this document."* That is a registry-**READ** refit; #5056 is a state-**WRITE** binding. Different slice.
- **`core/deploy/deploy.sh` (for #192)** and **`.github/workflows/skill-deploy.yml`** — both Stage-4 CONDITIONAL rows resolve **NOT-SELECTED** (Correction 5). Approach B calls the already-supported `deploy.sh --deploy <names>` form, so no deploy.sh change is owed and no CI workflow is added. `deploy.sh` **is** edited in this release, but by **#4442** only.
- **`operations/skills/tracker-manager/SKILL.md` (for #5056)** — a one-line emitter-enumeration correction that #5056 **considered and declined**: #196 already claims that file at sequence 6, so taking it would have manufactured a contention that does not otherwise exist. Routed as a follow-on. The file **is** in scope for #196.
- **`required_status_checks`** — out-of-tree branch protection, owned by no member (R6 / AI-003).
- **`.github/skill-package-freshness.enforce`** — the enforce-flip token. **Explicitly not flipped in this release** (R6 / AI-003). Flipping it alone is a no-op.

**Path repair recorded, not silently applied.** Correction 3 names `operations/skills/pmo-data-engineer/SKILL.md`. That path **does not exist**; the skill's live home is `release/skills/pmo-data-engineer/SKILL.md` (verified by tracked-file enumeration, with `release/skills/pmo-architect/SKILL.md` as the control arm resolving present in the same tree). The matrix carries the resolved path. This is a citation repair — the skill identity is unchanged and the correction's intent (bounded to the enumeration correction) is unaffected — not a scope change.

**Two derived rows, with their derivation stated.** `packages/pmo-data-engineer.skill` and its `.sha256` are not named in Correction 3's prose; they are the mandatory build consequence of editing a **rostered** skill's `SKILL.md` (the package exists in `packages/`, so the skill is rostered). The package-rebuild obligation is asserted by Check 7, by the CI freshness gate, and by CIAC-3 below. Counting the package as one cascade surface, Correction 3's "four omitted cascade surfaces" resolves exactly: the skill file, `stage-04-planning.md`, `domain-token-registry.md`, and the package.

**One promoted conditional, with its basis stated.** `core/standards/gate-efficacy-standard.md` entered Stage 4 as `CONDITIONAL:mode-c-rows-exist`. The condition **resolved TRUE**: Mode C is a prose-class runner declaring via `**Runner:**` at lines 195, 196 and 197 — a population of **3**, not the 0 the Stage-4 pass measured against the wrong token. It is therefore promoted to an unconditional `edit` in this commit. **Residual stated honestly:** re-verification may find the three rows already conformant, in which case no edit lands and a `NOT DELIVERED` Deviation-Log row is owed. Leaving the row CONDITIONAL after its condition resolved would have bought exemption from the check for the price of one token, which is the authoring defect the promotion rule names.

**New-executable companion obligation, discharged.** #192 adds one tracked executable, `core/hooks/git-post-merge-deploy.sh`. Its companion row `core/config/allowlists/script-execution-allowlist.txt` is carried in the same matrix and lands in the same release. **CI wiring:** the script is **not CI-executed** — it is a local git hook installed by `docs/scripts/setup-workspace.sh` at one-time operator setup. That is the whole point of Approach B: a CI runner structurally cannot reach the local install path, which is why Approach A was rejected.

## Risk Register

| ID | Risk | Owner-issue | Severity | Reversibility | Mitigation |
|----|------|-------------|----------|---------------|------------|
| **R1** | **#196's consumer population** was under-specified (4 / 12 / 17 candidates against a card that said 2). Selecting 12 would take the card above `size:M` and the release above the 25-pt ceiling. | #196 | **HIGH** → **DISCHARGED** | MODERATE | Resolved at Stage 5: the binding population is the **4 contract-carrying skills** (`artifact-generator`, `comms-writer`, `delivery-engine`, `tracker-manager`), matching the cascade allowlist exactly. AC-4a names all four. The release stays at 23 effective points. The remaining 8 parse-surface skills route to a follow-on. |
| **R2** | Package-rebuild omission across the affected skills blocks the release head at Check 7. | all skill-editors | **HIGH** | CHEAP | Rebuild once per skill after its final source touch. The CI gate now runs with **no path filter**, so a miss fails pre-merge rather than at Stage 13. Precedent: v3.35 (9 edited, 0 rebuilt, 28/28 green). |
| **R3** | `delivery-engine/SKILL.md` double-touch (#5056 → #196) causes rework. | #5056, #196 | MEDIUM | CHEAP | Sequence order 4 → 6, with #196 anchoring by heading and bolded phrase rather than line number (Correction 9). |
| **R4** | ~~`pmo-skill-editor/SKILL.md` double-touch~~ | — | **DISSOLVED** | — | #196 no longer touches that file (Correction 6). The path is single-claimed by #4442. Recorded rather than deleted so the dissolution is auditable. |
| **R5** | **#4442 AC-3 was restated against the wrong token.** The Stage-4 pass measured `enforcement-surface:`, obtained a true zero with a live control arm, and restated AC-3 as a null-with-arms over an empty population. | #4442 | MEDIUM → **CORRECTED** | CHEAP | The population is **3**, not 0. `enforcement-surface:` scopes to the two automated-assertion classes; Mode C is a **prose class** declaring via `**Runner:**`. AC-3 is corrected on the card to re-verify the three rows under R1∧R2 with both arms. **A wrong-denominator error is structurally invisible to a control arm** — the control proved the token was live in the file, never that it was the right token for the class. |
| **R6** | **The freshness enforce-flip is INERT, not incomplete.** | #5236 (carried) | MEDIUM | CHEAP | **Limb 1 alone is a no-op, and this is the risk.** The workflow's gate-decision handler maps advisory exit-2 to `exit 0`, so the check run is **green on a genuinely stale roster**. Branch protection on `main` holds **9** required contexts and the job's context `Pre-merge .skill package content-freshness gate` is **not among them** — no context matches `freshness` at all. Sensitivity: the list is populated (9 entries). Specificity: a fabricated context returns absent. **Flipping the sentinel `warn → enforce` therefore turns the job red and still does not block a merge.** The merge aggregate is structurally incapable of being gated on package freshness until the context is added — an out-of-tree branch-protection change owned by no member of this milestone. Carried as **AI-003**. Do not scope the flip into this release; do not report it as achieved. |
| **R7** | **#192 Approach A is infeasible** — a CI runner cannot reach the local install path. | #192 | MEDIUM → **DISCHARGED** | CHEAP | Approach **B** selected: a local hook installed by `docs/scripts/setup-workspace.sh`. Evidence: 0 of 22 workflows write the install path; control — 13 of 22 invoke `deploy.sh` in validator form. |
| **R8** | **Baseline pin goes stale.** It did twice during Stage-4 planning. | release-wide | MEDIUM | CHEAP | Re-fetched at Engineering Commit 0 and verified unchanged at `e19a9d30`. Re-run the sibling-merge predicate at Stage 9 entry (Phase A6.5). The trigger is live, not theoretical. |
| **R9** | **#4975 is the only research-shaped member** — evidence-tier-labeled external sourcing plus catalog registration. Highest estimate variance in the bundle. | #4975 | MEDIUM | CHEAP | Start early (sequence 2). Purely additive on its two new guides, so a partial landing is revertible without touching any other member. |
| **R10** | Direct `Write`/`Edit` to a `SKILL.md` bypasses `pmo-skill-editor` and fails Check 10's audit-trail assertion. | all skill-editors | LOW | CHEAP | Route every skill edit through `pmo-skill-editor` Mode A. |
| **R11** | **Check 50 / Check 18b IFF coupling.** `deploy.sh` Check 50 is a global committed-default ENFORCE over `core/standards/**`, IFF-coupled to Check 18b (`framework_version_anchor` iff cataloged), the two agreeing by construction. | #4975 | MEDIUM | CHEAP | **The two new guides and their `framework-catalog.md` rows cannot land in separate commits.** This binds Stage 6 regardless of any other decision. |
| **R12** | **Line-number rot.** Cited positions in issue bodies and Stage-5 specs are historical, and sibling cards move lines within this release. | #196, #5056 | MEDIUM | CHEAP | Edit by marker or content, never by line number. #196's `:484` anchor sits below #5056's `TRACKER_UPDATE` inserts and **will** shift (Correction 9). |
| **R13** | **`deploy.sh` is the platform's own verification instrument.** A defective edit does not merely fail — it blinds the checks that would detect the defect. | #4442 | MEDIUM | MODERATE | Rollback is `git revert` (CHEAP mechanically); the hazard is *detection*, not reversal. Capture a full `deploy.sh --check` transcript pre-merge as the diff baseline and re-run post-merge. |
| **R14** | **Quota.** Worst parallel batch is 6 spokes against an unstated envelope. | release-wide | MEDIUM | CHEAP | Split the 6-wide Stage 5 and Stage 8 batches into two sub-waves of 3. Checkpoint B is the load-bearing gate at every launch. |

**Rollback strategy.** Single release branch, one commit group per issue in sequence order. Per-issue rollback is `git revert <commit>` — each member is independently revertible because the only shared file is sequenced, not interleaved. #4975 is purely additive on its two guides (**CHEAP**; no existing surface changes behavior). #196 touches the most files and is last, so reverting it restores the release to a coherent 5-member state that still fully satisfies the Outcome Statement — the composition exception is, by construction, the safe cut. Package rebuilds revert with their source commit. Whole-release rollback is `git revert -m 1 <merge-sha>`, the standard operator-authorized path.

## Quota Budget

**Verdict:** **WARN** (Checkpoint A)
**Parallel-eligible spokes per parallel stage:** Stage 5: **6** · Stage 7: **5** (#5236 skipped) · Stage 8: **6**
**Per-spoke cost estimate:** size-bucket ordinal band — worst batch mix **2 × `size:S`** + **4 × `size:M`**. Source: heuristic; no telemetry medians available, so no bucket has met the supersession conditions.
**Assumed/stated remaining usage-window envelope:** **UNSTATED** — no operator quota band was stated at hub start. The conservative default applies.
**Estimated cumulative draw % (worst parallel batch):** **not rendered.** Per the refuse-to-synthesize rule this axis has no instrument; with an `UNSTATED` basis a percentage would be a sourced-looking number nobody measured. Basis token: **`UNSTATED`**. `[ASSUMPTION – CONFIRM]`
**Routing:** **WARN** → window-aware launch timing plus quota-budgeting. Split the 6-wide Stage 5 and Stage 8 batches into **two sub-waves of 3**, re-running the check before each. Recommended `W_max ≈ 3` — width does not reduce cumulative draw, but it bounds interruption loss linearly.
**Note:** Checkpoint A is advisory. The load-bearing gate is **Checkpoint B**, re-validated at every spoke launch — wave or singleton, every stage — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton. Checkpoint B also gates on the host-API axis, combined DEFER-dominant. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

## Cross-Issue Acceptance Criteria

Release-scoped cohesion predicates spanning ≥2 issues. Graded at Stage 9 QC3.5 on the merged PR.

- [ ] **CIAC-1 (#5056 × #196 on `operations/skills/delivery-engine/SKILL.md`):** after both land, the single file carries **both** the Axis-1 state-write beats and the JSON chained-arg parse clause — neither edit has overwritten the other. *Method:* `python3 -c "import re,pathlib; t=pathlib.Path('operations/skills/delivery-engine/SKILL.md').read_text(); print(len(re.findall('lifecycle_state',t)), len(re.findall('chained=true',t)))"` — both counts must be ≥1. *Baseline at `e19a9d30`: 0 and 1.*

- [ ] **CIAC-2 (#4442 on `release/skills/pmo-skill-editor/SKILL.md`):** after #4442 lands, every check ID Mode C cites resolves to a definition or has been removed, and the "Check Application Matrix" reference resolves or has been replaced. *Method:* `python3 -c "import re,pathlib; t=pathlib.Path('release/skills/pmo-skill-editor/SKILL.md').read_text(); print(sorted(set(re.findall(r'RC-\d{2}',t))), t.count('Check Application Matrix'))"` — the `RC-NN` list must be empty **or** every element must resolve in the definition bank, and the matrix reference must be 0 or resolvable. *Baseline at `e19a9d30`: 6 unresolvable IDs, 1 unresolvable matrix reference.* **Re-scoped from `#4442 × #196` to #4442 alone (D-L):** it spanned a surface #196 no longer modifies, and left as written Stage 9 would have graded #196 against a file it never touched. Retained as a CIAC rather than folded into the per-issue plan because it grades the *integrated* state of a file this release settles.

- [ ] **CIAC-3 (#4442 × #4975 × #5056 × #196 × `pmo-qa-auditor` on `packages/*.skill.sha256`):** every skill whose source this release edited has a rebuilt package on the release head — the release does not ship the v3.35 shape. *Method:* `bash core/deploy/deploy.sh --check-package-freshness` must exit **0** and report the full rostered count content-fresh. **Null-arm:** this expects a zero-stale result, so the control arm is `bash core/deploy/tests/test_package_freshness_exit_codes.sh`, which must report **11 passed, 0 failed** — its PF-2/PF-3/PF-6 arms return non-zero on a deliberately-staled package on the same instrument, proving an empty stale set is a real absence and not a dead probe. **Spanned surfaces:** `pmo-architect`, `pmo-data-engineer`, `pmo-skill-editor`, `delivery-engine`, `artifact-generator`, `comms-writer`, `tracker-manager`, **`pmo-qa-auditor`** (added by Correction 7).

- [ ] **CIAC-4 (#192 × #5236 on `core/rules/skill-deployment.md`):** the deploy-automation mechanism and the package-freshness record tell **one** consistent story on the shared surface — the file states both the automated post-merge deploy path (#192) and the mandatory package-rebuild obligation whose gate #5236 measured. *Method:* `python3 -c "import re,pathlib; t=pathlib.Path('core/rules/skill-deployment.md').read_text(); print(len(re.findall(r'post-merge',t)), len(re.findall(r'package-freshness|build-skill-packages',t)))"` — both counts must be ≥1. *Baseline at `e19a9d30`: 3 and ≥1.*

## Integration Points

Per-issue-pair integration criteria authored at Stage 5 Phase A4.2, graded at Stage 8.

- [ ] **INT-1 (#192 vs #5236) on `core/rules/skill-deployment.md`:** #192's edits to the post-merge deploy / package-rebuild narrative remain mutually consistent with #5236's recorded invisibility-cause statement — specifically, **#192's documentation must not describe the `skill-package-freshness` CI gate as blocking or as merge-gating**, since #5236's record establishes it is neither (warn sentinel **and** absent required-status context). *#5236 is sequenced first and #192 fifth, so #192's spoke is the one that must read this record; this criterion is the read-obligation's anchor.*

## Delivery Strategy

| Aspect | Decision |
|--------|----------|
| **Implementation approach** | Sequential (dependency-ordered), per the Implementation Sequence |
| **Commit strategy** | One commit group per issue, in sequence order, referencing the source issue number in the message body. This plan file is **Engineering Commit 0**, committed alone. |
| **Review approach** | Single PR for the entire release, one merge gate; created in draft and transitioned to ready-for-review at the Stage 9 gate |
| **Deployment mechanism** | Git merge + S-2 skill copy + manifest execution |
| **Concurrency posture** | **P0 fully-serial.** Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Stacked-base cleanup posture** | Not applicable — SINGLE topology, no stacked bases |

## Verification Plan

Per-issue: each card's own acceptance criteria, verified by the method the criterion names. Every claim of the form *zero occurrences* / *no findings* / *clean* / *absent* carries a probe record — the invocation, the denominator, a sensitivity arm with a non-zero observed result, and a specificity arm where applicable. **A zero whose control arm also returned zero is a broken probe, not a clean result.** A control arm proves the instrument fires; it cannot prove it was aimed at the right population — three counts in this release were wrong for exactly that reason, and each is recorded where it was corrected.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|---------------------|-----------------|
| #5236 | AC-1 | `bash core/deploy/deploy.sh --check-package-freshness`, with the roster denominator read independently via `ls packages/*.skill \| wc -l` | Compared count equals live `.skill` count; both recorded · control: a fabricated package name is absent from the compared set → NOT-IN |
| #5236 | AC-2 | The per-package verdict table posted on the parent thread with the pinned `origin/main` short SHA | Table row count equals the roster count; baseline SHA present |
| #5236 | AC-3 | `bash core/deploy/tests/test_package_freshness_exit_codes.sh` on the same instrument | Genuinely-stale set is **empty** · sensitivity control: PF-2/PF-3/PF-6 each observed NON-ZERO on a deliberately-staled fixture · specificity control: PF-1/PF-4/PF-5/PF-7 each observed ZERO, and the fabricated name `zzz-nonexistent-skill` is absent from the compared set |
| #5236 | AC-4 | Named read of three surfaces: the workflow trigger block, the sentinel file's first non-comment token, and the branch-protection required-contexts list | Three named vectors, each cited — a specific filter or posture, never "warn mode" generically |
| #4975 | AC-1 | Named read of `core/standards/domain-best-practices/security.md` | Exists; covers architecture-level threat modeling and trust-boundary decomposition, distinct from `software.md § Security`; every concept carries an evidence-tier label |
| #4975 | AC-2 | Named read of `core/standards/domain-best-practices/data.md` | Exists on the same terms |
| #4975 | AC-3 | Extract every external framework cited by either guide; assert each is registered in the `core/specs/framework-catalog.md` catalog-proper table | Every cited framework registered · **the catalog holds 41 data rows, not ~52** — probe the catalog table (header L41) only, never the file, which sweeps in the 11-row schema table |
| #4975 | AC-4 | `python3` count of `UNSOURCED-DOMAIN` in `release/skills/pmo-architect/SKILL.md` | 0 remaining for the security and data dimensions; each cites its guide · *baseline at `e19a9d30`: 2 live residuals* · control: the token is live corpus vocabulary elsewhere, so the zero is a real absence |
| #4442 | AC-1 | `python3 -c "import re,pathlib; print(sorted(set(re.findall(r'RC-\d{2}', pathlib.Path('release/skills/pmo-skill-editor/SKILL.md').read_text()))))"`, each hit resolved against the definition bank | Every cited ID resolves or is removed · *baseline: `RC-01, RC-20, RC-26, RC-27, RC-31, RC-32` cited, 0 defined* · control: `RCP-01..03` = 3 defined in the same bank, so the zero is a real absence · **beware the near-miss namespace**: `review-composition-framework.md` defines 17 `RC-<stage>-<slug>` IDs; assert against the *named* namespace so `RC-20` and `RC-1-intake-readiness` are not conflated |
| #4442 | AC-2 | `grep -c 'Check Application Matrix'` in the same file, plus a section-resolution read | Reference resolves to a real section or is replaced · *baseline: 0 sections, 1 dangling reference* · control: `Mode C` = 12 occurrences in the same file, so the section absence is real |
| #4442 | AC-3 | Re-verify the three prose-class rows at `core/standards/gate-efficacy-standard.md` L195/L196/L197 under the R1∧R2 resolution rule (carried **and** reached) | All three re-verified · **population is 3, not 0** · sensitivity control: `**Runner:**` occurs 10 times in that file, so 3 is a subset of a live population · specificity control: the same probe against a fabricated mode name returns 0 · *supersedes the Stage-4 restatement, which measured `enforcement-surface:` — the wrong token for the prose class* |
| #4442 | AC-4 | Run the new guard: Check 62 `_rr_compute_verdict` in `core/deploy/deploy.sh` extended with a symmetric `runner-src:` arm | The guard asserts Mode C's cited IDs resolve, so the class cannot silently regress · not a new check — an extension of an existing one |
| #5056 | AC-1 | `grep -rl` for the Axis-1 field name across `operations/skills/delivery-engine/` | ≥2 files (SKILL.md and the lifecycle-stages reference at minimum) · *baseline: 0 of 12* · control: `DoD` present in 6 of 12, so the zero is real · corpus sensitivity: the field appears in 101 of 1258 corpus `.md` files, so it is live vocabulary |
| #5056 | AC-2 | For each of `backlog→ready`, `ready→in-progress`, `in-progress→in-review`, `in-review→done` and the three `→cancelled` edges, grep the skill for the transition and its qualifying evidence | Each § 3.10 transition has a corresponding named beat · citation `entity-lifecycle-protocol.md` L205–L218 verified current |
| #5056 | AC-3 | Named read of the DoR and DoD gate mode sections | Each names the state **write** and the label it applies — not only the evaluation |
| #5056 | AC-4 | `bash core/deploy/deploy.sh --check` Check 7 content-hash freshness on the release head | Clean; `packages/delivery-engine.skill.sha256` changed in the same release as the skill-source edit |
| #5056 | AC-5 | `[DEFERRED — requires post-deploy runtime observation of a live work item; method declared, execution deferred. Grade in the Stage 13 outcome window; do not gate Stage 8.]` | SKIP at Stage 8 |
| #192 | AC-1 | Named read of the Stage-5 Solutioning output on the A/B/C selection | **Approach B selected** with rationale — the only approach reaching the local install path. Evidence: 0 of 22 workflows write the install path; control 13 of 22 invoke `deploy.sh` in validator form |
| #192 | AC-2 | Synthetic reproduction: merge a `SKILL.md` change and observe the installed copy | Installed copy updates without a manual `--deploy` |
| #192 | AC-3 | `grep` the post-merge deploy mechanism in `core/rules/skill-deployment.md` § Deployment Steps | Documented at the canonical home · *baseline: step 1 still documents the manual `./deploy.sh --deploy`* |
| #192 | AC-4 | `grep` the hook install in `docs/scripts/setup-workspace.sh` | Install wired into one-time operator setup, not a manual step |
| #192 | AC-5 | `[DEFERRED — post-release outcome metric spanning ≥3 subsequent releases; not gradable on the merged PR by construction. Grade in the Stage 13 30-day outcome window; do not gate Stage 8.]` | SKIP at Stage 8 |
| #196 | AC-1 | Section-scoped grep for `JSON` in `core/governance/OPERATIONS.md` § Skill Chaining Protocol | ≥1 · *baseline: 0 in-section* · control: `chain` = 8 in the same section, so the zero is a real absence and the section is the right home |
| #196 | AC-2 | Named read of the same section for the compatibility limb | `key=value` compat preserved **or** an explicit migration documented in the same section |
| #196 | AC-3 | Enumerate the binding population and assert each member updated | Population is the **4 contract-carrying skills** — selected and recorded at Stage 5 from candidates 4 / 12 / 17 over a denominator of 56 skills carrying a `SKILL.md`. Control: fabricated token `chained=zzz` → 0 |
| #196 | AC-4a | Assert the JSON parse clause, discriminated by a leading `{`, is present in all four contract-carrying skills | Present in 4 of 4 · sensitivity control: the same probe returns non-zero on a fixture skill deliberately given the clause · specificity control: a skill outside the cascade allowlist returns zero |
| #196 | AC-4b | `[DEFERRED — requires runtime observation; live chained invocation is not a repo assertion. Grade in the Stage 13 outcome window; do not gate Stage 8.]` | SKIP at Stage 8 |

**AC baseline** — per-issue criterion counts as read at plan time, and the commit SHA read against:

`ac_baseline: { #192: 5, #196: 4, #4442: 4, #4975: 4, #5056: 5, #5236: 4, read_at: e19a9d30 }`

**Re-bind recorded (the baseline's whole purpose).** #196 now carries **5** criteria against a baseline of 4: Stage 5 split AC-4 into **AC-4a** (structural, gradable on the merged PR) and **AC-4b** (`[DEFERRED]`, runtime observation). The count mismatch is the mechanical signal the baseline exists to raise, and the table above is re-bound to 5 rows accordingly. **27 verification rows total** against a 26-count baseline. #4975's four criteria are authored as **numbered prose outcomes, not a checkbox list**, so its `AC-1..AC-4` identifiers bind to that numbering — stated explicitly because the ordinal convention's usual substrate is absent on that card.

### Release-Level Verification

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity — `core/deploy/deploy.sh --check` Check 14 doc-link integrity on modified markdown
- [ ] Skill Invocation
- [ ] Output Contract Compliance

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Complexity |
|-------|-----------------|------------|
| #5236 | No commit to revert — the deliverable is a thread record | None |
| #4975 | `git revert <commit>` | Low — purely additive on the two new guides |
| #4442 | `git revert <commit>` | Medium — touches `deploy.sh`, the platform's own verification instrument (R13) |
| #5056 | `git revert <commit>` | Low — isolated to one skill tree |
| #192 | `git revert <commit>` | Low — a local hook and its allowlist row are removable in minutes |
| #196 | `git revert <commit>` | Low — last in sequence; reverting restores a coherent 5-member release |

### Whole-Release Rollback

`git revert -m 1 <merge-sha>` — **CHEAP / HIGH confidence** mechanically. The one qualification is R13: on the `deploy.sh` surface the binding constraint is *detection*, not reversal, which is why a pre-merge `--check` transcript is captured as the diff baseline.

## Operational Deployment Manifest

Layer-2 propagation targets for Stage 12/13:

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|------------------|------------------|-----------|--------------|
| 1 | `release/skills/pmo-architect/SKILL.md` | installed skill path | S-2 direct copy | `diff` shows no differences |
| 2 | `release/skills/pmo-data-engineer/SKILL.md` | installed skill path | S-2 direct copy | `diff` shows no differences |
| 3 | `release/skills/pmo-skill-editor/SKILL.md` | installed skill path | S-2 direct copy | `diff` shows no differences |
| 4 | `operations/skills/delivery-engine/SKILL.md` | installed skill path | S-2 direct copy | `diff` shows no differences |
| 5 | `operations/skills/artifact-generator/SKILL.md` | installed skill path | S-2 direct copy | `diff` shows no differences |
| 6 | `operations/skills/comms-writer/SKILL.md` | installed skill path | S-2 direct copy | `diff` shows no differences |
| 7 | `operations/skills/tracker-manager/SKILL.md` | installed skill path | S-2 direct copy | `diff` shows no differences |
| 8 | `core/skills/pmo-qa-auditor/references/` | installed skill path | S-2 direct copy | `diff` shows no differences |
| 9 | `core/hooks/git-post-merge-deploy.sh` | local git hook install | `docs/scripts/setup-workspace.sh` at one-time operator setup | hook present and executable; a merged `SKILL.md` change updates the installed copy with no manual `--deploy` |

### Schema Migrations

N/A — enumerated over the classes this release could touch (entity-field schemas, tracker schemas, frontmatter schema, the work-item type schema, the event-log schema); none present in this release. `core/schemas/work-item-type-schema.md` was **removed** from scope by Correction 8, so the one candidate that existed at Stage 4 is out.

## Verification Evidence

(Populated at Stage 6 C4 self-verification and after Stage 12 execution.)

## Deployment Execution Log

(Populated during Stage 12.)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Hub-Rendered D-Decisions

| # | Decision | Verdict | Reversibility |
|---|----------|---------|---------------|
| **D-ReleaseClass** | Release class | **`novel`** — re-classified from the declared `routine`. Two `novel` triggers fire on verified evidence (#4975 adds two new K1 reference docs; ≥4 D-class decisions in the plan); three `routine` triggers are affirmatively falsified. `cross-cutting` does not fire. Capacity survives: 23 effective points, inside the 15–25 band. **Posture:** engagement density Standard · Stage 9 depth **Deep** · Stage 5 activation ALL · Stage 13 outcome-window 30-day. | CHEAP · HIGH |
| **D-Version** | Version selection | **minor bump**; anchor `v4.43`, recomputed next-free **v4.44**. Recorded determination, not an operator gate. Re-verified at Engineering Commit 0 against tags ∪ published Releases ∪ ledger `DEPLOYED`/`VERIFIED` rows ∪ in-flight sibling holds. The number binds only at the Stage-12 atomic claim; the branch and this plan file stay slug-primary until then. | CHEAP · HIGH |
| **D-C** | Branch topology | **SINGLE.** One branch, one PR, one merge. Per-issue branches would shift contention to PR-merge order without reducing it. | CHEAP · HIGH |
| **D-Concurrency** | Concurrency posture | **P0 fully-serial.** The default, and independently the right answer on the contention map. Force-push prohibited on the shared branch. | CHEAP · HIGH |
| **D-G** | #4442 takes `core/deploy/deploy.sh` | **Accepted** (Tier-2 scope change). AC-4's guard extends Check 62 `_rr_compute_verdict` with a symmetric `runner-src:` arm — not a new check. Its post-#4442 sequencing constraint against #192 is **moot**: #192's `deploy.sh` row resolved NOT-SELECTED, so the two share zero files. | MODERATE · HIGH |
| **D-H** | #4975 takes `pmo-data-engineer/SKILL.md` | **Accepted** (Tier-2 scope change), bounded to the enumeration correction. Path resolved to `release/skills/pmo-data-engineer/SKILL.md` at Commit 0. | MODERATE · HIGH |
| **D-I** | `security.md` ADR question | **Ships under § 5.7 SHIP-WITH-FLAG; no ADR.** | CHEAP · MEDIUM |
| **D-J** | Wave-1 mechanical corrections | **Apply Corrections 1–4** and file the `CANARY_SKILLS` intake item (filed as #6354). | CHEAP · HIGH |
| **D-K** | #5056 scope reduction | **Accepted** (Tier-2 reduction). `core/schemas/work-item-type-schema.md` leaves the FCM, 7 paths → 6; the false discharge claim is corrected on the card. | CHEAP · HIGH |
| **D-L** | CIAC-2 re-scope | **Re-scoped to #4442.** It spanned a surface #196 no longer modifies; left as written, Stage 9 would have graded #196 against a file it never touched. | CHEAP · HIGH |
| **D-M** | Wave-2 corrections batch | **Approve Corrections 5–9.** | CHEAP · HIGH |

## Stage 6 and Stage 13 Obligations

- **#192 ADR — AUTHORIZED.** Authored at Stage 6 as that card's **first commit**. The threshold is met on the `core/rules/` cross-cutting limb only. **No number is reserved:** ADR numbering is global-monotonic across both ADR homes, so allocation happens at authoring — a speculative reservation can block a sibling.
- **#5056 Stage-13 obligation.** The edit is a `design-artifact-standard.md` § 7 **Tier-B** artifact, so the **G-CL6 refresh fires** for `delivery-engine`'s embedded skill-flow artifact. No Tier-A artifact is produced.
- **`WorkItem-<state>` canonicalized** with a full Evidence-Grounding artifact. Verified unminted: **0** occurrences corpus-wide, control arm live, specificity 0. Load-bearing — the bare state words are ordinary English in this skill (`ready` 38, `done` 32), so #5056's AC-1/AC-2/AC-3 are only mechanically gradable on the distinctive token.
- **Deliverable state.** #5236 reaches `artifact-accepted` — its definition of done *is* the recorded measurement, and it produces no deployed copy. Every other member reaches `deployed-copy-synced`.

## Action-Item Ledger

| ID | Item | State |
|----|------|-------|
| **AI-001** | Were the gate-efficacy Mode C rows removed, never authored, or under a different name? | **done** — answered by the third option. `enforcement-surface:` scopes to the two automated-assertion classes while the prose class declares via `**Runner:**`; Mode C is a prose-class runner naming 3 rows. Filing an intake item would have filed an answered question. |
| **AI-002** | The `~52` catalog-row figure | **cancelled** — premise falsified. The catalog holds **41** data rows; `~52` conflated the 11-row schema table (41 + 11 = 52). A substring scan over the whole file yields a third wrong number (45) by sweeping in schema rows that merely *mention* the provenance values. Only the table-scoped probe is valid. Do not inherit `~52` downstream. |
| **AI-003** | The freshness enforce-flip | **open — HARD gate, carried forward.** Sharpened per R6: the flip is **INERT**, not incomplete. It needs both the in-tree token **and** an out-of-tree `required_status_checks` change owned by no member. #5236 supplies only the data prerequisite. **Do not report the flip as achieved.** |
| **#6354** | `CANARY_SKILLS` roster asymmetry — `_c7_compute_verdict` excludes the canary array while the `--report` loop and ADR-008 include it. The two exclusions currently cancel because the canary has no package, which is *why* 55 == 55. | filed |
| **#6356** | A post-merge auto-deploy hook is inert until installed, and nothing reports when it is not. | filed |

## Deviation Log

A deviation is flagged, never silently taken. Recorded per spoke as deviations arise.

| Deviation | Basis | Disposition |
|-----------|-------|-------------|
| **DEV-0 (Engineering Commit 0, position-1 spoke) — version-half re-verify.** | The recomputation ran against tags (187 version-shaped) ∪ published Releases (185) ∪ ledger `DEPLOYED`/`VERIFIED` rows (192 of 204 table rows read), each arm non-zero; specificity arms clean (a fabricated `v9.99` absent; `v4.44` absent from the claimed set). The ledger arm parses the log **as a table**, reading the `Version` column of `DEPLOYED`/`VERIFIED` rows only — deliberately not a substring scan, which matched version-shaped strings in ledger *prose* on a prior release and produced a nonsensical anchor. In-flight holds: **0** (the one genuinely in-flight sibling is version-less and claims no slot). | **PROCEED.** `claimed_set()` = 193; `anchor()` = `v4.43`; minor floor = `v4.44`; recomputed next-free = **`v4.44`** = the planned value, and not in the claimed set. Both HALT conjuncts hold. |
| **DEV-1 (Engineering Commit 0) — `pmo-data-engineer` path repair.** | Correction 3 names `operations/skills/pmo-data-engineer/SKILL.md`; that path does not exist. Tracked-file enumeration resolves the skill to `release/skills/pmo-data-engineer/SKILL.md`, with `release/skills/pmo-architect/SKILL.md` as the control arm resolving present in the same tree. | **Repaired in the matrix, recorded here.** A citation repair, not a scope change — same skill, different tree prefix. |
| **DEV-2 (Engineering Commit 0) — two derived package rows on #4975.** | `packages/pmo-data-engineer.skill` and its `.sha256` are not named in Correction 3's prose. They are the mandatory build consequence of editing a rostered skill's source, asserted by Check 7, the CI freshness gate, and CIAC-3. | **Added with the derivation stated.** Counting the package as one cascade surface makes Correction 3's "four omitted cascade surfaces" resolve exactly. |
| **DEV-3 (Engineering Commit 0) — one promoted conditional.** | `core/standards/gate-efficacy-standard.md` entered as `CONDITIONAL:mode-c-rows-exist`; the condition resolved TRUE (population 3, at L195/196/197). | **Promoted to unconditional `edit` in this commit** per the fired-conditional rule. Residual stated: if re-verification finds the three rows conformant, no edit lands and a `NOT DELIVERED` row is owed here. |

## Change Description

(Authored by the Stage 6 spoke at PR-creation time — operator-facing, pre-merge, six sub-sections. Distinct from the user-facing release note authored at Stage 13 per [`release-notes-standard.md`](/release/references/standards/release-notes-standard.md).)

## Issue References

Members of this release: #5236, #4975, #4442, #5056, #192, #196.

Each member is **marked as closed at Stage 13** per the block-close protocol. No close-family verb appears against these numbers anywhere else in this document.

Supporting references, with inline summaries so the numbers are not load-bearing on their own:

- **#4708** — removed the `paths:` trigger filter from the package-freshness workflow; the file now carries the literal header `NO PATH FILTER, BY DESIGN`. Merged; its effect is included in this release's baseline.
- **#618** — the chained-invocation deferral this release's #196 extends. Closed/completed, so #196's native blocking edge is satisfied.
- **#160** — waived at the readiness gate as sequencing-only; not re-litigated.
- **#6354** — intake item for the `CANARY_SKILLS` roster asymmetry.
- **#6356** — intake item for the uninstalled-hook reporting gap.
- **#6261** — the Stage-4 planning sub-task carrying this plan's source comment and both PLAN CORRECTIONS comments.

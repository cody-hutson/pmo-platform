# Release Plan: adr-corpus-status-integrity — ADR Corpus Status Integrity

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. Anchor `v4.45`; provisional next-free `v4.46`, re-verified at Engineering Commit 0 against a freshly-fetched claimed set. The concrete number binds only at the Stage-12 atomic claim (ADR-092). |
| **Date Created** | 2026-09-01 (Tuesday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | release/adr-corpus-status-integrity |
| **PR** | (populated at Stage 6 PR assembly) |
| **Milestone** | adr-corpus-status-integrity |

**Baseline pin (audit-baseline discipline):** `origin/main` @ `539c4440` · probed `2026-09-01T18:52:49Z` · Stage-4 planning sub-task comment is the source of every section transcribed below.

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-01, domain: governance }`

Classification rationale (A3-time, from the matrix): every path in the matrix is an internal pmo-platform artifact — schemas, standards, ADR records, pipeline shards, module READMEs, and two release-side tools. No application source, no external surface. Dominant domain `governance`; the secondary domain is `software` (three Python/shell tools: `generate-adr-index.py`, `check-adr-durability.py`, `automated-closeout.sh`), recorded here rather than left ambiguous. Sourcing-exempt per the pipeline-internal rule; **not** domain-less.

## Release Class

**`novel`** — operator-rendered at the Stage-4 Phase B gate, 2026-09-01.

Zero `routine` triggers fire on live membership; three `novel` triggers do: a new reference doc/schema is introduced (the founding ADR plus the `adr-schema.md` §2/§5 amendment), the plan carries ≥1 D-class decision, and a Stage-5 ADR is authored in-slice. Multi-trigger resolution (`cross-cutting` > `novel` > `routine`) resolves to `novel`.

**Differentiation posture:** engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.

**Coupling the operator accepted explicitly:** `novel` → `class_weight` 1.15 → `effective_pts = round_half_up(25 × 1.15) = 29` > 25 — a genuine G3-15 breach, proceeding under recorded operator override. The prior BREACH record is superseded, not carried forward: it described an 8-ticket bundle at weight 1.0 that no longer exists.

## Scope

### Issues Included

| # | Issue | Title | Priority | Category | Size |
|---|-------|-------|----------|----------|------|
| 1 | #6230 | Partial-supersession carrier + reciprocity | P2 | Protocol | `size:M` |
| 2 | #6231 | Land the supersession edges on their targets | P2 | Protocol | `size:M` |
| 3 | #4761 | Status-flip owner + two-surface reconciliation | P3 | Protocol | `size:M` |
| 4 | #4762 | `G-EX9` method predicate | P3 | Protocol | `size:S` |
| 5 | #6232 | Pattern index | P3 | Protocol | `size:S` |
| 6 | #5823 | ADR-032 disposition + successor ownership | P2 | Protocol | `size:L` |

**Raw: 25 pts** · Release Class `novel` → `class_weight` **1.15** · **effective_pts 29** — breach of the 15–25 band, proceeding under recorded operator override.

#4726 (`size:XS`, 1 pt) closed 2026-08-30 at pre-flight; its residual (AC2 population, AC3 mechanism) is #4761's declared class scope. #4758 was de-bundled by the operator on 2026-08-31 and is not a member.

### Dependency Graph

Probed natively in both directions on every member.

```
#4761  ──(isolated)
#4762  ──(isolated)
#5823  ──(isolated)
#6230  ──blocking──▶  #6231       (FS+0d, intra-milestone)
#6231  ──blocked_by──  #6230
#6232  ──(isolated)
```

**Exactly one dependency edge exists across this bundle, and it is intra-milestone.** Zero circular chains — a 6-node DAG with 1 edge cannot cycle. Zero external blocking edges.

Collective Review additionally recorded four **soft** consumption edges that the native graph does not carry and that the implementation sequence already satisfies: `#5823 → #6230` (`superseded_by:` is on 0 of 169 records today; #5823 is its first consumer), `#4761 → #6231`, `#4762 → #4761`, `#6232 → #6230`.

### File Contention Map

**(1) Within-release contention — literal shared paths**

| Path | Claimed by | Severity | Resolution |
|---|---|---|---|
| `core/schemas/adr-schema.md` | #6230, #4761 | BINARY | **Sequence.** #6230 first (§2 field table + §5 supersession representation), #4761 second (§3 body-restates-frontmatter contract). Different sections, one file. |
| `core/schemas/gate-criteria-spec.md` | #4761, #4762 | BINARY | **Sequence.** #4761 adds a criterion row at the owning gate; #4762 amends the `G-EX9` Method cell. Disjoint cells. **One schema-version bump for the release, not two** — CIAC-4. |
| `release/tools/generate-adr-index.py` | #6230, #6232 | BINARY | **Sequence.** #6230 decides the partial-carrier projection; #6232 consumes that decision. #6232 must not run first. |
| `core/skills/adr-helper/references/scaffolding-procedure.md` | #6230 (RF-1 grant), #4761 | BINARY | **Sequence.** RF-1 granted step-3 partial-branch repair to #6230 at Stage 5; #4761 retains the rest of the file. |

**(2) Within-release contention — shared ADR *records***

`#4761 ∩ #6231` on the `## Status` section of five records:

```
release/ADRs/ADR-026-spoke-launch-quota-reservation-telemetry-event.md
core/ADRs/ADR-038-registry-as-cmdb.md
core/ADRs/ADR-045-cross-surface-memory-contract.md
core/ADRs/ADR-046-roadmap-instance-in-repo-home.md
core/ADRs/ADR-136-hook-dependency-integrity-invariant.md
```

**Resolution: sequence #6231 before #4761.** This is same-file *same-section*, so it is not resolvable by parallel branches.

`#6230 ∩ #6231` on **ADR-046** and **ADR-078**. The FS+0d edge already orders these correctly. ADR-012's frontmatter is co-edited by #6230 and #6231 on adjacent, disjoint lines (logged at Collective Review as RF-D, not escalated).

**Duplicate obligation across two cards:** ADR-046's false back-pointer is named by **#6230 AC5** *and* **#6231 AC3**. One remediation must satisfy both — #6230 owns it, #6231 verifies; CIAC-2 grades it.

**Frozen record — hard exclusion.** `core/ADRs/ADR-029-memory-corpus-ssot-boundary.md` takes no edits, including hygiene. It is in #6231's target set and is **verify-only**. Byte anchor: `sha256 = 5e39926c8306c495b650433ed372ac7a9a79aa28ad61ee6cd2e07d9fc2e08dcc`. Any plan step that edits this file is a defect (CIAC-5).

**(3) Cross-PR / cross-milestone contention**

Open-PR population `n=0` at baseline, measured against a firing control arm. Milestone `label-and-reference-integrity` (#337) was concurrent at Stage 4; intersecting the two milestones' declared surfaces (29 paths × 24 paths) yields **exactly 1** shared path — `core/deploy/deploy.sh`, mine via #5823's `CONDITIONAL:corpus-path-binding` branch. #337's #5258 edits `core/hooks/block-fragile-refs.sh`, whose scope-gate case arm covers this release's own plan file; that is a behavior edge, carried as R8 rather than a file overlap.

### Exclusions

- **#4758** — de-bundled by the operator 2026-08-31 (`demilestoned`, label transition `status: bundled` → `status: approved`). The section-completeness sub-capability left with it.
- **`ADR-090 → ADR-068`** — excluded from the supersession-edge carrier population. ADR-090 states in its own words that ADR-068 is "qualified, not contradicted", and ADR-068 carries zero back-references. Routed to #6231 as an open question with evidence (RF-4), not as a settled hub verdict.

## Implementation Sequence

```
1. #6230   Partial-supersession carrier + reciprocity        [size:M · hard predecessor of #6231]
2. #6231   Land the supersession edges on their targets      [size:M · BLOCKED BY #6230]
3. #4761   Status-flip owner + two-surface reconciliation    [size:M · 5-record collision with #6231]
4. #4762   G-EX9 method predicate                            [size:S · gate-criteria-spec.md after #4761]
5. #6232   Pattern index                                     [size:S · generate-adr-index.py after #6230]
6. #5823   ADR-032 disposition + successor ownership         [size:L · zero shared surface · Tier-0 gate]
```

**Positions 1→2→3 are constrained** (1→2 by the native dependency edge, 2→3 by the five-record `## Status` collision). **Positions 4, 5 and 6 are recommended, not constrained** — #4762, #6232 and #5823 declare no dependency edge and may be reordered among themselves without violating anything.

Rationale per position:

- **#6230 first.** It is the only hard predecessor in the bundle and it authors the carrier that three downstream cards consume (#6231's edge form, #6232's index projection decision, #4761's `adr-schema.md` co-edit). Running it first turns three latent collisions into ordered edits.
- **#6231 immediately follows #6230**, per the FS+0d edge. Nothing may be inserted between them.
- **#4761 follows #6231.** Both rewrite the `## Status` section of five shared records. Running #6231 first lets #4761's build-time probe reconcile once against final content instead of re-deriving a normalization #6231 overwrote.
- **#4762 follows #4761** — additive-then-corrective on `core/schemas/gate-criteria-spec.md`.
- **#6232 follows #6230** — it consumes #6230's index-projection decision and cannot assert a clean `--verify` against an undecided projection contract.
- **#5823 last** — zero shared files with any member; late position maximizes the window on its Tier-0 operator decision.

**D-Concurrency Posture: P0 fully-serial.** Positions 1→2→3 are hard-constrained and the remaining three do not justify a non-serial posture.

### Per-Issue Change Specifications

#### Issue #6230: Partial-supersession carrier + reciprocity

- **Files modified:** `core/schemas/adr-schema.md`, `core/standards/adr-authoring-guide.md`, `release/tools/check-adr-durability.py`, `release/tools/generate-adr-index.py`, `core/ADRs/ADR-046-roadmap-instance-in-repo-home.md`, `core/ADRs/ADR-012-roadmap-instance-descope.md`, `core/ADRs/ADR-017-distribution-architecture.md`, `core/skills/adr-helper/references/scaffolding-procedure.md`; adds one new ADR.
- **Change description:** Establish a frontmatter inverse pair `supersedes:` / `superseded_by:` with a two-token `whole` | `in-part` scope grammar, `superseded_by:` being partial-only. Add reciprocity lint rule R6, delta-scoped on the existing `--diff-base` machinery, warn-mode at the existing CI surface. Record the index non-projection decision with its measured reason. Land the shared ADR-046 back-pointer remediation via the pointer-added branch.
- **Estimated complexity:** Medium
- **Dependencies:** None (position 1)

#### Issue #6231: Land the supersession edges on their targets

- **Files modified:** `core/ADRs/ADR-*.md`, `release/ADRs/ADR-*.md` — record set **re-derived at Engineering time against the then-current denominator, never transcribed**. ADR-029 excluded (frozen).
- **Change description:** Land each partial supersession edge on its target as a `superseded_by:` entry in #6230's grammar. No mechanical flip of any target's `status:` leading token.
- **Estimated complexity:** Medium
- **Dependencies:** #6230 (FS+0d, hard)

#### Issue #4761: Status-flip owner + two-surface reconciliation

- **Files modified:** `core/skills/adr-helper/references/scaffolding-procedure.md`, `operations/templates/adr-template.md`, `core/schemas/gate-criteria-spec.md`, `core/schemas/adr-schema.md`; conditionally one of `release/references/pipeline/stage-13-close.md` / `stage-09-plan-review.md`.
- **Change description:** Name exactly one stage as owner of the `Proposed → Accepted` flip and reconcile the frontmatter/body two-surface disagreement cohort. Cohort **re-derived at build time** — the Stage-4 figure of 28 is superseded by four independent measurements returning 30.
- **Estimated complexity:** Medium (Collective Review flagged a likely `M → L` re-size; re-derive at Stage 6)
- **Dependencies:** #6231 (contention-ordered, not a dependency edge)

#### Issue #4762: `G-EX9` method predicate

- **Files modified:** `core/schemas/gate-criteria-spec.md`
- **Change description:** Amend the `G-EX9` Method cell so the predicate binds to the performed move rather than to a bare `NNN → NNN` shape. Cite by symbol, never by line number — all three cited line refs have drifted.
- **Estimated complexity:** Low
- **Dependencies:** #4761 (same file, additive-before-corrective)

#### Issue #6232: Pattern index

- **Files modified:** `core/ADRs/README.md`; conditionally `release/ADRs/README.md` + `release/tools/generate-adr-index.py`.
- **Change description:** Author the ADR pattern index. Cluster inventory **re-derived at build time**. AC1's population is recorded as unreproducible as written — an open disposition carried into Stage 6, not a blocker.
- **Estimated complexity:** Low
- **Dependencies:** #6230 (consumes its projection decision)

#### Issue #5823: ADR-032 disposition + successor ownership

- **Files modified:** `core/ADRs/ADR-032-release-corpus-public-vs-instance-split.md`, `release/references/standards/release-notes-standard.md`; conditionally a successor ADR, `core/config/platform-config.toml.template`, `core/deploy/deploy.sh`, `core/deploy/tools/generate_release_index.py`, `release/tools/automated-closeout.sh`.
- **Change description:** Render and land the ADR-032 disposition (supersede / amend / re-affirm), operator-decided at the Stage-4 Phase B gate to be rendered inside this release. AC1 is recorded as unsatisfiable as written — an open disposition carried into Stage 6. The successor adapter needs a work item under epic #1184 and cannot be a member of this milestone (composition lock).
- **Estimated complexity:** High
- **Dependencies:** #6230 (first consumer of `superseded_by:`)

## Stage Applicability Matrix

Stages 10 and 11 are **PLATFORM-SATISFIED** for every release on this path (the PR diff *is* the dry run; git history *is* the snapshot).

| Issue | S5 Solutioning | S6 Engineering | S7 Dev Test | S8 QA/Acceptance | S9–S13 |
|---|---|---|---|---|---|
| #6230 | APPLY (T1 + T3 + T4) | APPLY | APPLY | APPLY | release-scoped |
| #6231 | APPLY (T6) | APPLY | APPLY | APPLY | release-scoped |
| #4761 | APPLY (T3 + T6) | APPLY | APPLY | APPLY | release-scoped |
| #4762 | APPLY (whole-release activation) | APPLY | APPLY | APPLY | release-scoped |
| #6232 | APPLY (T4) | APPLY | APPLY | APPLY | release-scoped |
| #5823 | APPLY (T3 + T4) | APPLY | APPLY | APPLY | release-scoped |

**Stage 5 activation — ACTIVATE, whole release.** The matrix is OR across T1–T6 on *any* in-bundle issue and there is no per-issue activation surface. No stage is skipped for any issue.

## File Change Matrix

```
# ── #6230 — partial-supersession carrier + reciprocity ──
core/schemas/adr-schema.md                                                  edit
core/standards/adr-authoring-guide.md                                       edit
release/tools/check-adr-durability.py                                       edit
release/tools/generate-adr-index.py                                         edit
core/ADRs/ADR-046-roadmap-instance-in-repo-home.md                          edit
core/ADRs/ADR-012-roadmap-instance-descope.md                               edit
core/ADRs/ADR-017-distribution-architecture.md                              edit
core/skills/adr-helper/references/scaffolding-procedure.md                  edit

# ── #6231 — land the supersession edges (ADR-029 EXCLUDED, frozen) ──
core/ADRs/ADR-*.md                                                          edit
release/ADRs/ADR-*.md                                                       edit

# ── #4761 — status-flip owner + two-surface reconciliation ──
operations/templates/adr-template.md                                        edit
core/schemas/gate-criteria-spec.md                                          edit
core/schemas/adr-schema.md                                                  edit
release/references/pipeline/stage-13-close.md                               CONDITIONAL:owner-is-stage-13 edit
release/references/pipeline/stage-09-plan-review.md                         CONDITIONAL:owner-is-stage-09 edit

# ── #4762 — G-EX9 method predicate ──
core/schemas/gate-criteria-spec.md                                          edit

# ── #6232 — pattern index ──
core/ADRs/README.md                                                         edit
release/ADRs/README.md                                                      CONDITIONAL:release-side-projected edit
release/tools/generate-adr-index.py                                         CONDITIONAL:release-side-projected edit

# ── #5823 — ADR-032 disposition + successor ownership ──
core/ADRs/ADR-032-release-corpus-public-vs-instance-split.md                edit
release/references/standards/release-notes-standard.md                      edit
core/config/platform-config.toml.template                                   CONDITIONAL:adapter-selector-key edit
core/deploy/deploy.sh                                                       CONDITIONAL:corpus-path-binding edit
core/deploy/tools/generate_release_index.py                                 CONDITIONAL:corpus-path-binding edit
release/tools/automated-closeout.sh                                         CONDITIONAL:corpus-path-binding edit
```

The founding ADR #6230 authors is an unconditional **add** whose filename carries a number that binds at merge (ADR-115). It is declared here in prose rather than as a matrix `add` row precisely because the `fcm-delivery` family compares declared unconditional ADDs against the merged diff by literal path, and a path containing an unbound number would be reported declared-but-absent on every run. The delivered path is recorded in the Verification Evidence section at Stage 6 instead.

```markdown
#### Read-only inputs (excluded from the delivery obligation set)
core/schemas/frontmatter-schema.md                                          READ
core/disciplines/km-protocols.md                                            READ
release/tools/renumber-adr.py                                               READ
release/ADRs/ADR-115-adr-number-claim-binds-at-merge.md                     READ
release/ADRs/ADR-117-adr-index-derived-surface-and-scoped-conformance-claim.md  READ
release/ADRs/ADR-146-supersession-is-an-append-and-integrity-is-a-dated-read-only-sweep.md  READ
core/ADRs/ADR-051-health-check-mcp-primary-source-set.md                    READ
.github/workflows/repo-integrity.yml                                        READ
release/references/pipeline/stage-04-planning.md                            READ

#### Release-wide explicit non-scope
core/ADRs/ADR-029-memory-corpus-ssot-boundary.md                            NOT EDITED
core/ADRs/ADR-078-security-hook-dependency-resolution-posture.md            NOT EDITED in #6230 (migration stated; landed by #6231)
```

**Placement rationale (G-PL3):** no reorg merged after this release's base (empty window), so every path above is placed at current-`main` topology by construction.

**Two glob rows carry a build-time derivation obligation.** `core/ADRs/ADR-*.md` / `release/ADRs/ADR-*.md` under #6231 and the #4761 status reconciliation both resolve to record sets that are **re-derived at Engineering time against the then-current denominator, never transcribed from this plan or from the issue bodies.** As of `539c4440` the sets measure 25 (#6231, minus ADR-029 = 24 editable) and 30 (#4761), overlapping on 5. Both figures are pinned measurements, not obligations.

**No `add` row targets a tracked executable script**, so the `core/config/allowlists/script-execution-allowlist.txt` companion obligation does not fire.

## Integration Points

| # | Integration surface | Issues | Contract |
|---|---|---|---|
| I-1 | The `superseded_by:` carrier grammar | #6230 defines · #6231, #5823 consume | `SUPERSESSION_ENTRY_RE` is defined once in `core/schemas/adr-schema.md` §2 and cited — never restated — by the lint and by consuming cards. `superseded_by:` is partial-only; a whole edge's reciprocal is the existing Nygard `status: Superseded by ADR-NNN` transition. |
| I-2 | `core/schemas/adr-schema.md` §2/§5 vs §3 | #6230 then #4761 | Disjoint sections, ordered edits. #6230 lands the field table and the supersession-representation split; #4761 lands the body-restates-frontmatter contract. |
| I-3 | `core/schemas/gate-criteria-spec.md` version-history block | #4761 then #4762 | **Exactly one** new schema-version entry for the release. The bump is claimed by #4762, sequenced second, per the file's *one block, one bump* rule. |
| I-4 | `release/tools/generate-adr-index.py` managed region | #6230 then #6232 | #6230's edit is **docstring-only**, leaving `--verify` byte-identical; #6232 must not perturb the managed region of `release/ADRs/README.md`. |
| I-5 | The `## Status` section of five co-edited ADR records | #6231 then #4761 | #6231's supersession pointer must not reintroduce the frontmatter/body disagreement #4761 removes. Same-section, so serialization is the only resolution. |
| I-6 | `core/ADRs/ADR-046` back-pointer remediation | #6230 specifies · #6231 verifies | One remediation, pointer-added branch (forced by the authoring guide's closed forbidden list item 3). #6231 verifies; it does not re-apply. |

## Risk Register

| # | Risk | Owner | Severity | Reversibility · Confidence | Mitigation | Earliest detector |
|---|---|---|---|---|---|---|
| R1 | **Mechanical supersession flip injects false retirements.** #6231 lands edges into a binary `status:` enum where most are partial. A flip to bare `Superseded` asserts something the superseder explicitly denies — and silently removes still-binding records from the durability lint's population via `FROZEN_STATUSES`. | #6231 spoke | **Critical** | EXPENSIVE · HIGH | #6231 AC2 forbids it; #6230's carrier lands first (FS+0d) so partial edges have a form to land *in*. Positions 1→2 are constrained, not recommended. | Stage 8 per-criterion verdict on #6231 AC2; CIAC-1 at Stage 9. |
| R2 | **ADR-029 edited.** The frozen record sits inside #6231's declared target set; a spoke working the list mechanically will reach it. | #6231 spoke | **Critical** | IRREVERSIBLE in effect · HIGH | Explicit `NOT EDITED` row in the FCM; byte anchor recorded; CIAC-5 grades it with a control arm. | CIAC-5 at Stage 9; `git diff` on the merged PR. |
| R3 | **Stale inventories transcribed instead of re-derived.** Every card's counts are days and records behind. A spoke that copies a figure from a body ships an under-scoped fix that passes its own AC. | All Stage 5/6 spokes | **High** | MODERATE · HIGH | Every count in this plan is labelled a pinned measurement; the two glob FCM rows carry an explicit build-time derivation obligation. | Stage 7 re-execution of each card's probe against the then-current denominator. |
| R4 | **#4761 and #6231 collide on five ADR records' `## Status` section.** Same file, same section, two cards. | Sequence | **High** | CHEAP · HIGH | Sequence #6231 → #4761. Do not parallelize positions 2 and 3. | Merge conflict at Engineering, or a silently-reverted normalization at Stage 8. |
| R5 | **#5823's Tier-0 decision arrives late and routes to "re-affirm",** stalling a release whose other five cards are done. | Operator | **High** | EXPENSIVE · MEDIUM | Disposition pulled forward to the Stage-4 Phase B D-Gate and **rendered there** — operator elected to render inside this release. | Phase B D-Gate — discharged. |
| R6 | **Version collision on the provisional `v4.46` with milestone #337,** which recorded the same provisional. | Hub | Medium | CHEAP · HIGH | Expected under slug-primary planning; nothing binds until the Stage-12 ref-CAS and the loser re-versions. | **Commit-0 version re-verify** — run at this commit; PROCEED (see § Verification Evidence). |
| R7 | **`core/deploy/deploy.sh` contended with #337** (my side conditional on #5823's corpus-path-binding branch). | Sequence | Medium | CHEAP · HIGH | If the conditional fires, serialize the merge on that file; #5823 is sequenced last, maximizing the chance #337 has already merged. | Stage 9 Phase A6.5 mid-pipeline divergence re-check. |
| R8 | **`block-fragile-refs.sh` scope gate changes under this release's own plan file** (#337's #5258 edits the hook whose case arm covers `release/releases/plans/*_RELEASE_PLAN.md`). | Hub | Medium | CHEAP · MEDIUM | Author every intra-repo link in this plan in the workspace-rooted form (leading `/`, never `../`) — correct under both the current and any tightened gate. | `--plan-depth-lint` on the release PR. |
| R9 | **#6230 designs against a falsified exemplar** (the card names an ADR-078 frontmatter tail that does not exist). | #6230 spoke | Medium | CHEAP · HIGH | Correction recorded: ADR-078 is body-only; the live exemplars are ADR-051 → ADR-164 and ADR-009 → ADR-085, carrying two different spellings. | Stage 5 Phase 0.5 Re-Review Delta — discharged. |
| R10 | **Duplicate remediation on ADR-046** — two cards own the false back-pointer and may fix it twice, differently. | Sequence | Low | CHEAP · HIGH | One remediation; #6230 runs first and owns it, #6231 verifies. CIAC-2 grades it. | CIAC-2 at Stage 9. |
| R11 | **Two schema-version bumps on `gate-criteria-spec.md`.** | Sequence | Low | CHEAP · HIGH | One bump for the release, claimed by #4762. CIAC-4 grades it. | CIAC-4 at Stage 9. |

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered), P0 fully-serial concurrency posture |
| **Branch topology** | **D-C SINGLE** (default) — one release branch, `release/adr-corpus-status-integrity`; no per-issue branches |
| **Commit strategy** | Small reviewable commits with conventional-commit subjects; issue numbers referenced in messages; the release plan file is Engineering Commit 0 |
| **Review approach** | Single PR for the entire release, created in draft at Stage 6 and transitioned to ready at the Stage 9 gate |
| **Deployment mechanism** | Git merge + S-2 skill copy + manifest execution |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dep (default — Option A) |

## Verification Plan

**Provenance note:** the Stage-4 planning comment emitted no `## Verification Plan` section. The per-issue rows below are therefore **constructed at Commit 0 from each issue's own acceptance criteria** rather than transcribed, and are flagged as such so a reviewer does not read them as Stage-4 determinations. Every other section of this plan is transcribed from the Stage-4 comment.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #6230 | AC-1 | `grep -n "superseded_by" core/schemas/adr-schema.md core/standards/adr-authoring-guide.md` — the carrier is defined once between the two normative surfaces | Both files resolve; the grammar and `SUPERSESSION_ENTRY_RE` are stated in the schema and cited (not restated) by the guide |
| #6230 | AC-2 | Read the DERIVATION RULES docstring of `release/tools/generate-adr-index.py` for the recorded non-projection decision, then `python3 release/tools/generate-adr-index.py --verify` | Non-projection recorded with its measured reason; `--verify` exits 0 with `COUNT 0` (docstring-only edit leaves derived cells byte-identical) |
| #6230 | AC-3 | `python3 release/tools/check-adr-durability.py --self-test` exercising R6 with a one-sided partial pair | Self-test passes; R6 is delta-scoped on the existing `--diff-base` machinery so it does not fire on pre-existing edges · control: the one-sided partial fixture must FAIL R6 → observed non-zero finding |
| #6230 | AC-4 | `grep -n "ADR-078" core/schemas/adr-schema.md core/standards/adr-authoring-guide.md` plus a read of ADR-078's frontmatter | ADR-078's migration is stated explicitly; its frontmatter is unchanged in this card (landing is #6231's) |
| #6230 | AC-5 | `git grep -c ADR-046 -- core/ADRs/ADR-012-*.md core/ADRs/ADR-017-*.md` | Non-zero on both · control: `git grep -c ADR-012 -- core/ADRs/ADR-012-*.md` must return non-zero, proving the path resolves and the matcher fires |
| #6230 | AC-6 | `test -f` on the authored ADR at its delivered path; `python3 release/tools/renumber-adr.py --next-free` re-run at authoring | Founding ADR exists with a number read (not reserved) from the oracle; number binds at merge per ADR-115 |
| #6231 | AC-1 | Re-derive the supersession-edge set at build time against the then-current denominator, then confirm each landed edge carries a `superseded_by:` entry in #6230's grammar | Every re-derived partial edge is landed on its target; the ADR-090 → ADR-068 non-edge is excluded with its exclusion recorded |
| #6231 | AC-2 | Structural probe over the full ADR denominator for `status:` leading tokens changed by this release | Zero targets mechanically flipped to `Superseded` · control: a synthetic flipped fixture must be detected → observed non-zero |
| #6231 | AC-3 | Verify (do not re-apply) #6230's ADR-046 remediation | ADR-012 and ADR-017 each carry a pointer naming ADR-046 |
| #6231 | AC-4 | `python3 release/tools/check-adr-durability.py --diff-base <release-base>` | R6 reports zero unreciprocated edges over the landed set |
| #6231 | AC-5 | `shasum -a 256 core/ADRs/ADR-029-memory-corpus-ssot-boundary.md` | Equals `5e39926c8306c495b650433ed372ac7a9a79aa28ad61ee6cd2e07d9fc2e08dcc` |
| #6231 | AC-6 | Read the widened non-ADR class of three recorded at Collective Review | Each of the three is dispositioned |
| #4761 | AC-1 | Read `core/schemas/gate-criteria-spec.md` for the named owning stage of the `Proposed → Accepted` flip | Exactly one stage named |
| #4761 | AC-2 | Re-derive the two-surface disagreement cohort at build time | Cohort re-derived, not transcribed (Stage-4's 28 superseded by four measurements returning 30) |
| #4761 | AC-3 | Structural leading-token agreement probe over the full ADR denominator | Zero disagreements · control: a synthetic disagreeing fixture must return 1 |
| #4761 | AC-4 | `grep -n` the scaffolding procedure and `operations/templates/adr-template.md` for the reconciled status contract | Both surfaces state the same contract |
| #4761 | AC-5 | Re-derive the affected record set at build time | Population re-derived against the then-current denominator |
| #4761 | AC-6 | `bash core/deploy/deploy.sh --check` | No new drift rows introduced by the reconciliation |
| #4761 | AC-7 | Read the #4726 residual (AC2 population, AC3 mechanism) | Residual explicitly dispositioned within #4761's class scope |
| #4762 | AC-1 | Read the `G-EX9` Method cell in `core/schemas/gate-criteria-spec.md` | Cell no longer contains the bare `NNN → NNN` shape pattern |
| #4762 | AC-2 | Read the same cell for a binding to the performed move | Method binds to the performed move · control: `G-EX8` must still resolve in the same file and be unmodified |
| #4762 | AC-3 | Exercise the corrected predicate against both control arms named in the card | Predicate discriminates: fires on a real renumber, silent on a non-move |
| #4762 | AC-4 | Confirm citations are by symbol, not line number | Zero line-number citations introduced · control: the symbol names `G-EX9` / `PROVENANCE_RE` must resolve → observed non-zero |
| #6232 | AC-1 | Re-derive the cluster inventory at build time | **[DEFERRED — the population is unreproducible as written; carried into Stage 6 as an open disposition per Collective Review]** |
| #6232 | AC-2 | `python3 release/tools/generate-adr-index.py --verify` | Exits 0, reports `COUNT 0` · control: a hand-edited row inside the managed region must report non-zero `COUNT` |
| #6232 | AC-3 | `test -f core/ADRs/README.md` and read the authored pattern index | Pattern index present at its declared path |
| #6232 | AC-4 | Confirm the derived-surface contract of ADR-117 is respected | Managed region unperturbed; `core/ADRs/README.md` treated as curated, not derived |
| #5823 | AC-1 | Read the rendered ADR-032 disposition | **[DEFERRED — unsatisfiable as written; carried into Stage 6 as an open disposition per Collective Review]** |
| #5823 | AC-2 | Read `core/ADRs/ADR-032-*.md` frontmatter `status:` after the disposition lands | Status reflects the operator-rendered disposition |
| #5823 | AC-3 | `grep -n "post-extraction\|until the extraction lands" release/references/standards/release-notes-standard.md` | Zero stale occurrences · control: the file must resolve and a known-present token must hit → observed non-zero |
| #5823 | AC-4 | Confirm the successor adapter work item is filed under epic #1184 | Work item exists outside this milestone (composition lock) |
| #5823 | AC-5 | Read the corrected config path reference | `core/config/platform-config.toml.template` (the card's `core/config/platform-config.toml` does not exist) |
| #5823 | AC-6 | Read the `stateReason` of the withdrawn migration issue named in the card | `stateReason` corrected so a withdrawn migration no longer reads as delivered |

**AC baseline** — per-issue criterion counts as read at plan time, and the commit SHA read against. Counts derived by a structured section-scoped checkbox probe over each issue body (extraction non-empty 6/6; specificity control with a fabricated section name returned 0/6).

`ac_baseline: { #6230: 6, #6231: 6, #4761: 7, #4762: 4, #6232: 4, #5823: 6, read_at: 539c4440 }`

### Release-Level Verification

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity
- [ ] Skill Invocation
- [ ] Output Contract Compliance

## Cross-Issue Acceptance Criteria

Five predicates, each spanning ≥2 issues, each graded on the merged PR at Stage 9 QC3.5 / Phase A3.6.

- [ ] **CIAC-1 (#4761 × #6231 on the `## Status` section of the co-edited ADR records):** After the merge, no ADR record in either corpus directory has a frontmatter `status:` leading token that disagrees with its `## Status` body's first status token — including the five records both cards edit (ADR-026, ADR-038, ADR-045, ADR-046, ADR-136), where #6231's supersession pointer must not reintroduce the disagreement #4761 removed. *Shared surface:* the `## Status` section of `core/ADRs/ADR-*.md` and `release/ADRs/ADR-*.md`, denominator re-derived at grading time. *Method:* run the leading-token agreement probe over the full denominator; expect **0** disagreements. Null predicate, so it carries its arms: **control:** the same probe against a synthetic record whose frontmatter reads `Accepted` and whose `## Status` body opens `**Proposed.**`, placed in the same directory → must return **1**; and non-empty extraction asserted on the full denominator. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#6230 × #6231 on ADR-046's back-pointer):** Exactly one remediation of ADR-046's false back-pointer lands, and the merged state is internally consistent under whichever branch was taken — either ADR-012 **and** ADR-017 each carry a pointer naming ADR-046 (pointer-added branch), **or** ADR-046 no longer asserts that they do (sentence-corrected branch). The state where ADR-046 still asserts the pointer while ADR-012 and ADR-017 lack it is NOT MET, and so is a state where both cards landed contradicting remediations. *Shared surface:* `core/ADRs/ADR-046-roadmap-instance-in-repo-home.md`, `core/ADRs/ADR-012-*.md`, `core/ADRs/ADR-017-*.md`. *Method:* `git grep -c ADR-046 -- core/ADRs/ADR-012-*.md core/ADRs/ADR-017-*.md` and read ADR-046's consequence sentence; the two readings must agree on one branch. **control:** `git grep -c ADR-012 -- core/ADRs/ADR-012-*.md` must return non-zero, proving the path resolves and the matcher fires. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (#6230 × #6232 on `release/tools/generate-adr-index.py`):** The derived release-side index remains self-consistent after both cards land — #6230's partial-supersession carrier is either projected by the generator or its non-projection is recorded with a reason, and #6232's pattern index does not perturb the managed region. *Shared surface:* `release/tools/generate-adr-index.py` and the delimited managed region of `release/ADRs/README.md`. *Method:* `python3 release/tools/generate-adr-index.py --verify` exits 0 and reports `COUNT 0`. **control:** the same invocation against a working tree with one hand-edited row inside the managed region must report a non-zero `COUNT` — proving `--verify` still discriminates rather than passing vacuously after the edits. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-4 (#4761 × #4762 on `core/schemas/gate-criteria-spec.md`):** Both cards' criterion changes are present in the merged file under **exactly one** new schema-version entry for this release — #4761's status-ownership criterion at the owning gate, and #4762's corrected `G-EX9` Method predicate bound to the performed move rather than to any `NNN → NNN` shape. Two independent version bumps for one release is NOT MET. *Shared surface:* `core/schemas/gate-criteria-spec.md` — the criterion tables plus the version-history block. *Method:* read the version-history block and count entries added relative to `origin/main` at the release base; expect exactly 1. Then confirm the `G-EX9` Method cell no longer contains the bare shape pattern and does contain a binding to the performed move. **control:** `G-EX8` must still resolve in the same file and be unmodified, proving the read targets the live table rather than a stale copy. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-5 (#6231 × #4761 on the frozen record):** `core/ADRs/ADR-029-memory-corpus-ssot-boundary.md` is byte-unchanged across the merged PR, notwithstanding that it appears in #6231's declared target set and sits in the corpus #4761 sweeps. *Shared surface:* `core/ADRs/ADR-029-memory-corpus-ssot-boundary.md`. *Method:* `git diff <release-base>...HEAD -- core/ADRs/ADR-029-memory-corpus-ssot-boundary.md` returns empty, and `shasum -a 256` on the merged file equals `5e39926c8306c495b650433ed372ac7a9a79aa28ad61ee6cd2e07d9fc2e08dcc`. Null predicate, so it carries its arms: **control:** the identical `git diff` invocation against `core/ADRs/ADR-046-roadmap-instance-in-repo-home.md` — a record this release *does* edit, on the same instrument against the same tree — must return a non-empty diff. An empty result on both arms means the diff range is wrong, not that the freeze held. *Graded at Stage 9 QC3.5 on the merged PR.*

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #6230 | Whole-PR revert preferred — the carrier is consumed by three downstream cards | Medium — entangled by design |
| #6231 | **Whole-PR only.** Reciprocity is a graph property; a partial single-file revert is never correct | High |
| #4761 | Whole-PR revert | Medium |
| #4762 | `git revert` of the isolated commit | Low — one table cell |
| #6232 | `git revert` of the isolated commit | Low |
| #5823 | Whole-PR revert | Medium |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Full Restore** | Systemic failure | `git revert` of the merge commit restores every surface atomically — this is why Stage 11 is PLATFORM-SATISFIED |
| **Partial Revert** | Isolated issue failure | Available only for #4762 and #6232; never for #6231 |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per the rollback protocol |

**Two rollback asymmetries, named rather than assumed symmetric:**

**(a)** The founding ADR authored by #6230 (and #5823's conditional successor) claims a number at merge. A revert frees the number, but any sibling release that allocated *above* it in the interim will not renumber — so a revert-then-reland re-claims a *different* number and every citation authored in the interim must be re-derived.

**(b)** #6231's edits land reciprocal pointers across roughly two dozen records. A partial revert (single-file) is never correct: the reciprocity invariant is a graph property, so rollback is whole-PR or nothing.

## Quota Budget

**Verdict:** WARN (per the quota-budget protocol, Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **6** · Stage 7: **6** · Stage 8: **6**
**Per-spoke cost estimate:** size-bucket ordinal band (source: heuristic — no telemetry medians available). Worst batch mix: 1 × `size:L` + 3 × `size:M` + 2 × `size:S`.
**Assumed/stated remaining usage-window envelope:** **`UNSTATED`** — no operator quota band was captured at hub start.
**Estimated cumulative draw % (worst parallel batch):** **not rendered.** Per the refuse-to-synthesize rule on the usage-window axis, a draw percentage against an unstated envelope would be a sourced-looking figure this session could not have obtained. `[ASSUMPTION – CONFIRM]`
**Routing:** WARN → window-aware launch timing + quota-budgeting (split batch). The `UNSTATED` basis maps to `W_max = 2` at Checkpoint B, turning each 6-wide parallel stage into **3 sub-waves, re-gated** — so the split the WARN band recommends is already the runtime default under this basis.
**Contention context:** the parallel-eligible count of 6 is **not fully realizable** regardless of quota. Positions 1→2→3 are constrained, so the true worst *concurrent* batch is 4 (positions 3–6 once 1–2 have landed). The plan-time estimate uses 6 because Checkpoint A's input contract reads the matrix, not the sequence — the divergence is recorded rather than silently substituted.

## Operational Deployment Manifest

**N/A — enumerated over the Layer-2 propagation classes this release could touch: installed skill copies (`skills/**` sources), `core/rules/` mirror pairs, and compiled `.skill` packages.**

At plan time the matrix carries one `skills/**` surface — `core/skills/adr-helper/references/scaffolding-procedure.md` (#6230 via the RF-1 grant, and #4761) — which stales the `adr-helper` package and its `.sha256` sidecar. That rebuild is a Stage-6 C4 obligation (`core/deploy/tools/build-skill-packages.sh adr-helper`) rather than a Stage-12 manifest row, and is recorded in the Verification Evidence section as it lands. Zero `core/rules/` files are in the matrix, so no mirror-pair sync is owed. The manifest table is therefore empty by measurement, not by omission; it is repopulated if a later card adds a propagation target.

### Schema Migrations

**N/A — enumerated over the migration classes this release could carry: ADR frontmatter field additions, gate-criteria schema-version entries, and derived-index column changes.**

The `superseded_by:` field addition is **additive and optional**, so no existing record requires migration — the frontmatter reader carries unknown keys rather than rejecting them, and the four records with a non-`none` `supersedes:` value take a normalization, not a migration. The `gate-criteria-spec.md` version-history entry (#4762, one bump for the release) is a schema-version record, not a data migration. No derived-index column is added (#6230 D-6, do-not-project). No migration script ships.

## Verification Evidence

(Populated across Stage 6 → Stage 12. Commit-0 entries recorded below as they land.)

### Commit-0 version re-verify

| Step | Result |
|---|---|
| 1. `git fetch --tags origin && git fetch origin main` | Refreshed; `origin/main` = `539c4440` |
| 2. Recompute next-free (bump-class `minor`) | `anchor()` = **v4.45** across all three claimed-set arms; floor = v4.46 |
| 3. Planned version not in claimed set AND equals recomputed next-free | **PROCEED** — v4.46 absent from origin tags, published Releases, and the release-log arms |

**Claimed-set arms, each with a firing control:**

| Arm | Result | Control |
|---|---|---|
| Published Releases (REST) | max `v4.45` | list non-empty (12 rows read) |
| Origin tags | max `v4.45`; `v4.46` → 0 hits | `v4.45` → 2 hits (same instrument, same target) |
| `RELEASE_LOG.md` `DEPLOYED` rows (read via `git show origin/main:`) | **0 rows**, header located (no HALT) | same column predicate with `VERIFIED` → **194 rows**, max `v4.45` — the zero is a real absence, not a broken probe |

The sibling milestone `label-and-reference-integrity` (#337) recorded the same provisional `v4.46`. It has claimed nothing: `v4.46` is absent from every arm above. Under slug-primary planning the number binds only at the Stage-12 ref-CAS, so both releases may proceed and whichever reaches the atomic claim first wins; the loser re-versions. R6 is therefore live but non-blocking.

## Deployment Execution Log

(Populated during Stage 12)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | | |
| Merge PR | | | |
| Tag release | | | |
| Skill deployment | | | |
| Manifest execution | | | |
| State anchor update | | | |
| Post-execution verification | | | |

## Change Description

(Authored by the Stage 6 release-engineering spoke at PR-creation time per [`release/governance/RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Change Description Protocol. Populated when the release PR is assembled — the release branch accumulates all six cards' commits before a single PR is opened.)

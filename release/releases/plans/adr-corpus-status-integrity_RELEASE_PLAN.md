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
- **The release-corpus home adapter successor** — **created as #6627 on epic #1184 (PORT-Adapters), outside this milestone.** #6627 is a native sub-issue of #1184, `state: open`, and **unmilestoned**. The Stage-4 composition lock was therefore never engaged: `release-process.md` § A7 bars adding an issue *to a composition-locked Milestone* (`issues_added` MUST be **0** for every refresh disposition), and it says nothing about creating one elsewhere. The successor sits outside this release's composition because that is where the work belongs — under the adapters epic — not because a bar prevented it. The separate Stage-6 spoke-scope rule explains only why a Stage-6 spoke did not create it itself; it is not a bar on the release. The spec #6627 carries, verified live rather than transcribed:
  - **Config surface — `operator.toml [adapters] corpus_home`, NOT `platform-config.toml`.** ADR-022 Decision 1 keeps host-adapter selectors in `operator.toml [adapters]` (ADR-017 §S2-faithful) and reserves `platform-config.toml` for the platform-behaviour categories ADR-017 did not enumerate — so the card's named surface is the wrong layer. The name and home are already anticipated by shipped test infrastructure: `test_corpus_home_tolerance.sh`'s arming needle enumerates *"an `operator.toml [adapters] corpus_home` selector in either read shape"*. This is adoption, not minting. Measured: `corpus_home` occurs **0** times in `core/config/operator.toml.template`.
  - **A fifth selector has a hardcoded consumer.** `core/deploy/deploy.sh` Check 33 iterates a literal list — `for _ad in repo_host ticketing kb ai_tool` — asserting each *named* selector carries a default. A `corpus_home` added without extending that loop (or deriving the list from the template) ships **silently unvalidated**: the check never asks about a selector it does not name.
  - **The genuinely-missing half is the location decision**, which `corpus-home-adapter-constraints.md` §6 reserves to "the corpus-home adapter design (not yet written)" — measured absent across the 1,899-file tracked set. Re-proposing the withdrawn 2026-06-29 migration is **not** that decision and is out of scope: its three measured grounds now apply against **445** tracked files under `release/releases/` rather than 75.
  - **NOT in scope — already shipped.** The normative constraint standard (CH-1..CH-4 with fixtures), `release/tools/tests/test_corpus_home_tolerance.sh`, `.github/corpus-home-tolerance.arming` (token `armed`), the instance-aware `check_paths()` resolver, ADR-135 and the required CI gate. Measured on this tree, the suite's own verdict is `PASS-SEAM-LANDED`. The seam landed; the selector and the location decision are what remain owed.

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

**Row-confirmation log.** Because the rows are constructed rather than determined, each card confirms or corrects its own at Stage 6 rather than inheriting them. **#6231 — reviewed 2026-09-01: AC-5 confirmed as written; AC-1, AC-2, AC-3, AC-4 and AC-6 corrected.** Four of the five were aimed at a predicate narrower than the criterion (a file census standing in for a two-sided edge; a corpus-wide count that is invariant under a swap; a prose-mention `grep` that would pass a record carrying no pointer; a bare `COUNT 0` with no firing arm), and AC-6 was aimed at the **wrong artifact** — it grepped the plan and the card body, so a plan merely listing three record names would have passed it while the corpus carried nothing.

**#4762 — reviewed 2026-09-01: all four rows corrected, none confirmed as written.** AC-1's row asserted an **absence only**, which deleting the conjunct outright satisfies while adding no move-keyed predicate — and, executed, it **passed pre-fix**: the cell stored the shape pattern markdown-escaped as backslash-`d` literals, so both natural digit-class readings returned a confident zero on the unmodified cell. AC-3's row named `renumber-adr.py --detect`, which grades whether a **number claim** binds against the mainline and mentions provenance zero times — a sound probe aimed at the wrong predicate, structurally unable to discriminate a stale earlier-hop note from a correct one. AC-4's row was aimed at the **wrong artifact entirely**, probing for line-number citations rather than the fail-closed clause, and its pattern matched 1 line of 1238. AC-2's row stated no machine-checkable predicate at all, and the set's only symbol-resolution control named `PROVENANCE_RE` — the symbol being **removed** from the cell — rather than `provenance_head`, the one being cited. Every corrected row now carries a control whose failure mode is named, and the two rows asserting a **removal** or a **preservation** grade against the mainline blob, because a post-fix-only probe cannot tell either claim from an empty read.

**#4761 — reviewed 2026-09-01: all seven rows corrected, none confirmed as written.** Three were aimed at a different criterion than the one they graded — AC-2's row tested the cohort (AC-5's subject), AC-3's row tested the whole-corpus probe (AC-6's subject), and AC-1's row grepped the gate spec for a string that already occurs there several times, so it could not distinguish "one stage named as owner" from "the arrow appears in prose". AC-4's row was aimed at the **wrong artifact entirely**: it grepped the two scaffold surfaces for a supersession string, when the criterion asks for a *disagreement detector* — and those two surfaces were separately falsified as never having carried the promise at all. AC-5's row used `grep -l`, a file census that structurally cannot express a two-token comparison. AC-6's row named `deploy.sh --check`, which does not run the probe the criterion is about. AC-7's row predated the 2026-09-01 amendment and still graded the #4726 residual rather than the sweep. Every corrected row now carries a control arm whose failure mode is named, because six of the seven original rows would have passed against work that was not done. **The #4726 residual (AC2 population, AC3 mechanism) is graded on the Stage-6 output against the corpus, not by grepping the issue body** — a card body that merely names the residual would satisfy the original row while the corpus carried nothing.

**#5823 — reviewed 2026-09-01: all six rows corrected, none confirmed as written. Two (AC-3, AC-6) were recorded UNMET at build time; both were resolved before merge and now grade MET — see their rows below.** Five of the six were aimed at a different criterion than the one they graded — the set runs one off from AC-2 onward, so the row nominally grading "does a successor ADR exist" actually probed `status:`, and the row grading the epic sub-issue probed the release plan. Two were aimed at the **wrong artifact entirely**: AC-5's row ran `test -f` on a config template, which grades nothing about the discrimination arm AC-5 exists to be and would pass on any tree where that file exists; AC-6's row grepped the #5823 card body, so a body merely *naming* the disposition would have passed while #1549's `state_reason` stayed `completed` — which, measured, it was at build time; it reads `not_planned` at merge. AC-1's `[DEFERRED — unsatisfiable as written]` was correct and is replaced rather than removed: its closed binary offers only the barred migration or the rejected freeze. Every corrected row carries a control whose failure mode is named, and the rows asserting an **unchanged** value or a **removal** grade against the mainline blob or a corpus arm, because a post-fix-only probe cannot tell either claim from an empty read.

**#6232 — reviewed 2026-09-01, corrected 2026-09-02 at the Stage-7 DT iteration.** This was the **last card in the release still carrying uncorrected rows**: the Stage-6 review identified the defects and authored replacement text, but no `fix(release):` commit landed them, so the defective rows survived into Dev Testing while five sibling cards had already been repaired. **AC-3 and AC-4 corrected; AC-2 confirmed as written** (the first row in this release to survive its own execution). AC-3's row ran `test -f` on a file that already existed, so it **exited 0 on the unmodified base tree** — green before any of this card's work existed — and it graded AC-1's subject rather than its own negative. AC-4's row named a literal occurring **zero times at base and at head**, so it could not pass on any tree; that defect was written in by a **cross-card formatting pass on a sibling card** (`438d5b38`, #6230) rather than by this card's authoring, which is the second distinct mechanism this release has produced for a defective row and is routed to Stage 13 as such. AC-1's row is a separate, still-open item: it states an activity rather than a predicate and its expected result is a deferral, and it is superseded by the operator's 2026-09-02 amendment binding AC-1 to the adjudicated roster by reference — the row is left for that amendment to land rather than corrected here. Both corrected rows were **re-executed with their controls firing** before being recorded.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #6230 | AC-1 | `grep -n "superseded_by" core/schemas/adr-schema.md core/standards/adr-authoring-guide.md` — the carrier is defined once between the two normative surfaces | Both files resolve; the grammar and `SUPERSESSION_ENTRY_RE` are stated in the schema and cited (not restated) by the guide |
| #6230 | AC-2 | `grep -n "NOT projected" release/tools/generate-adr-index.py` for the recorded non-projection decision, then `python3 release/tools/generate-adr-index.py --verify` | Non-projection recorded with its measured reason; `--verify` exits 0 with `COUNT 0` (docstring-only edit leaves derived cells byte-identical) |
| #6230 | AC-3 | `grep -c "R6" release/tools/check-adr-durability.py` then `python3 release/tools/check-adr-durability.py --self-test` exercising R6 with a one-sided partial pair | Self-test passes; R6 is delta-scoped on the existing `--diff-base` machinery so it does not fire on pre-existing edges · control: the one-sided partial fixture must FAIL R6 → observed non-zero finding |
| #6230 | AC-4 | `grep -n "ADR-078" core/schemas/adr-schema.md` (the §5.2 migration note) plus `grep -c "^status:" core/ADRs/ADR-078-*.md` | Migration stated explicitly — ADR-078 gains the frontmatter half it never had and keeps `status: Accepted`; its own file is unchanged in this card, the landing being #6231's |
| #6230 | AC-5 | `git grep -c ADR-046 -- core/ADRs/ADR-012-*.md core/ADRs/ADR-017-*.md` | Non-zero on both · control: `git grep -c ADR-012 -- core/ADRs/ADR-012-*.md` must return non-zero, proving the path resolves and the matcher fires |
| #6230 | AC-6 | `test -f` on the authored ADR at its delivered path; `python3 release/tools/renumber-adr.py --next-free` re-run at authoring | Founding ADR exists with a number read (not reserved) from the oracle; number binds at merge per ADR-115 |
| #6231 | AC-1 | `grep -c "^superseded_by: ADR-" core/ADRs/ADR-*.md release/ADRs/ADR-*.md` — target-side entry census, re-derived at build time | One target-side entry per adjudicated partial edge. This count is **necessary, not sufficient** — a file census cannot assert a two-sided edge. The grading arm parses BOTH fields with `SUPERSESSION_ENTRY_RE` and asserts the superseder-side and target-side partial-edge sets are EQUAL (symmetric difference empty), with ADR-090 → ADR-068 and ADR-060 both absent as standing specificity controls |
| #6231 | AC-2 | `grep -l "^status: Superseded" core/ADRs/ADR-*.md release/ADRs/ADR-*.md` | Exactly one record — the corpus's single whole-supersession target, which is frozen. A corpus-wide **count is invariant under a swap**, so the grading arm is a PER-RECORD status-token map compared base-vs-head over the intersecting record set, asserting zero changed tokens, plus a planted `Superseded` sensitivity arm the same instrument must read back |
| #6231 | AC-3 | `grep -c "^superseded_by: ADR-046 in-part" core/ADRs/ADR-012-*.md core/ADRs/ADR-017-*.md` — verify, do not re-apply | Non-zero on both. The pointer must be in the **field**: a `git grep -c ADR-046` counts `## Related ADRs` prose mentions and would PASS a record that carries no pointer at all. Scope labels byte-identical to ADR-046's own `supersedes:` field. Control: `grep -c "ADR-012" core/ADRs/ADR-012-*.md` non-zero, proving the path resolves and the matcher fires |
| #6231 | AC-4 | `grep -c "R6" release/tools/check-adr-durability.py` — rule-presence only; `python3` is outside the executor's runnable-verb allowlist, so the lint run itself is an honest SKIP here and is graded by re-execution at Stage 7 | R6 present. The grading arm is the delta-scoped run `check-adr-durability.py --root . --diff-base <release-base>` reporting `COUNT 0` **together with a firing sensitivity arm** — remove one landed back-pointer, expect `COUNT 1` naming that exact edge, then restore byte-identically. `COUNT 0` on **both** arms means the delta scoping is mis-wired, not that the corpus is clean; with no `--diff-base` R6 emits a CONFIG skip that must never be read as green |
| #6231 | AC-5 | `shasum -a 256 core/ADRs/ADR-029-memory-corpus-ssot-boundary.md` — the digest must be present and unchanged | Equals `5e39926c8306c495b650433ed372ac7a9a79aa28ad61ee6cd2e07d9fc2e08dcc`. Control: a diff of a record this release DOES edit, on the same instrument and range, must be non-empty — an empty result on both arms is a wrong diff range, not a held freeze |
| #6231 | AC-6 | `grep -c "adr-supersession: reciprocity-exempt" core/ADRs/ADR-060-*.md core/ADRs/ADR-095-*.md` — asserted against the **records**, not against the plan or the card body | Non-zero on both. ADR-141 is deliberately UNMARKED and this is the finding, not an omission: the marker is extracted whole-file, so it is record-scoped rather than edge-scoped, and ADR-141 also carries the landed edge ADR-141 → ADR-096. Marking it emits a false `reciprocity-exempt` row for a two-sided edge and skips that edge's real check in both directions (measured). ADR-141 is graded on limb 2 — its `## Supersession` bullet 1 records the relation. Control: `grep -c "adr-supersession" core/ADRs/ADR-141-*.md` returns 0 while the two above return non-zero; zero on all three is a broken probe |
| #4761 | AC-1 | `grep -c "Phase A13" release/references/pipeline/stage-13-close.md` — asserted on the STAGE spec, which is where AC-1 places the ownership statement. The gate spec is AC-3's subject, not this one | Non-zero, and the phase states the Tier-0 operator-authorization posture explicitly. Control: `grep -c "Phase A13" release/references/pipeline/stage-09-plan-review.md` returns 0 — if two stage specs both claimed a performing beat, "exactly one owner" would be false while the first grep still passed, so the specificity arm is what makes the claim mean anything |
| #4761 | AC-2 | `grep -c "Stage 13 Close ratification beat" core/ADRs/README.md` and the same pattern on `release/ADRs/README.md` — the two live status-enum surfaces, asserted against the RECORDS' own governing enum rather than against the plan | Non-zero on both, naming the same owning gate as `stage-13-close.md`. Control (the falsification arm): `grep -c "flips to Accepted" core/skills/adr-helper/references/scaffolding-procedure.md` returns 0, confirming the two scaffold surfaces the card names never carried the promise and are correctly out of scope rather than silently skipped |
| #4761 | AC-3 | `grep -c "never inferred from milestone closure" core/schemas/gate-criteria-spec.md` — asserted on the criterion TEXT at the owning gate | Non-zero, and the `G-CL9` row carries the authored-by-this-release limb requiring a terminal token read from the file's own `status:` field. Control: the same pattern against `release/references/pipeline/stage-09-plan-review.md` returns 0 — the criterion must sit at the owning gate, not the rejected one |
| #4761 | AC-4 | `grep -c "R7" release/tools/check-adr-durability.py` — rule-presence only; `python3` is outside the executor's runnable-verb allowlist, so the lint run itself is an honest SKIP here and is graded by re-execution at Stage 7 | R7 present. Grading arm: `--self-test` reports the R7 arms passing, AND a whole-corpus run reports zero R7 rows **together with a firing sensitivity arm** — plant a disagreeing body into the real record map, expect exactly 1 row naming that record, then assert the unplanted map returns 0. Zero on **both** arms means the rule is not wired, not that the corpus is clean |
| #4761 | AC-5 | A two-token structural probe per record — extract the frontmatter `status:` leading token and the `## Status` body's first status token, then compare — over the whole ADR denominator re-derived at build time. A `grep -l` file census cannot express this predicate: it lists files containing a pattern and cannot compare two extracted tokens, so it would pass a record carrying both | Cohort re-derived at build time (never transcribed) and reconciled to zero, denominator stated. Control: the frontmatter and body token histograms must be EQUAL after the edit, and before it the arithmetic cross-check (body-`Proposed` minus frontmatter-`Proposed`) must equal the reported cohort — an independent arm that does not share the comparison's own code path |
| #4761 | AC-6 | `python3 release/tools/check-adr-durability.py` with no `--files`, reading the R7 rows and the `SCANNED` denominator. `bash core/deploy/deploy.sh --check` does NOT run this probe and cannot grade this criterion | `SCANNED` equals the build-time record count; zero R7 rows; and the number of records R7 actually EVALUATED is reported separately from the scan count, so a zero cannot be produced by an empty evaluation. Frozen-exempt records are reported as a named subtraction, never silently dropped |
| #4761 | AC-7 | Sweep population re-derived at build time (frontmatter `Proposed`, promise-carrying, excluding this release's own in-flight records) and enumerated per record with its current status, the stage its promise names, and the proposed terminal status. Applied-flip count asserted from `git diff` | Edit set PREPARED and presented for the operator gate; **zero** `Proposed → Accepted` transitions applied by the agent — a flip applied without that gate is a governance defect regardless of whether the resulting status is correct. Control: the same diff assertion must detect a planted frontmatter change, or its zero is an empty read |
| #4762 | AC-1 | Two limbs, each a single-pattern probe. **Positive:** `grep -c "for each hop this release actually performed" core/schemas/gate-criteria-spec.md` — the Method's own words for the per-hop binding, which is what AC-1 actually claims. **Negative, and it must be a fixed-string match:** `grep -cF '\d{3} → \d{3}' core/schemas/gate-criteria-spec.md`. The cell stored the pattern markdown-escaped as backslash-`d` literals, so a digit-class regex finds no three-digit run and returns a confident **zero on the unmodified cell** — measured, `grep -cE '\d{3} → \d{3}'` and `grep -cE '[0-9]{3} → [0-9]{3}'` both return 0 pre-fix | Positive limb non-zero; fixed-string limb returns 0. **Control, and it is what makes the zero mean removal rather than an empty read:** the same fixed-string probe against `git show origin/main:core/schemas/gate-criteria-spec.md` must return non-zero. Absence is insufficient on its own in any case — deleting the conjunct outright also satisfies it while adding no move-keyed predicate, which is why the positive limb is graded first |
| #4762 | AC-2 | Two single-pattern probes plus a form check. **Citation present:** `grep -c "renumber-adr.py::provenance_head" core/schemas/gate-criteria-spec.md`. **Symbol resolves:** `grep -c "def provenance_head" release/tools/renumber-adr.py`. **Cited by symbol, never by line:** the citation carries no `:NNN` locator — this card exists because a predicate drifted from its subject, and a line-pinned cite reproduces that defect | Both probes non-zero. **Specificity control:** `grep -c "def provenance_headXX" release/tools/renumber-adr.py` returns 0, proving the resolution discriminates rather than matching any substring. The original row's only symbol control named `PROVENANCE_RE` — the symbol being **removed** from the cell — rather than the one being cited. **Recorded residual, graded as a known gap rather than a pass:** the resolution is performed by a reader, not a check. This file carries **zero** `runner-def:` pointers, so the citation orphans silently if the symbol is renamed |
| #4762 | AC-3 | Import `provenance_head` from `release/tools/renumber-adr.py` and evaluate it on a live multi-hop record — `core/ADRs/ADR-118-*.md`, hops `110 → 114` then `114 → 118` — across two arms: the complete record, and a counterfactual with the **last** hop's note deleted. `renumber-adr.py --detect` is **not** this row's subject: executed, it emits ANCHOR / NEXT-FREE / CLAIM lines grading whether a number claim binds against the mainline and mentions provenance **zero** times, so it cannot discriminate a stale note from a correct one | Complete arm SATISFIED, defect arm NON-SATISFIED, both with non-empty extraction. **Control, and it is the point of the row:** the old shape predicate `PROVENANCE_RE` on the **same** defect arm must be SATISFIED, returning the `110 → 114` note as its evidence for a hop that wrote nothing. If both predicates agree on the defect arm the correction achieved nothing, so agreement is the failure signal, not the pass |
| #4762 | AC-4 | `grep -c "Fail-closed: an indeterminate read" core/schemas/gate-criteria-spec.md`, read on the `G-EX9` criterion row. The original row probed for **line-number citations**, a different claim entirely, and was near-vacuous even for that claim — its pattern matched 1 line of 1238 | Non-zero, and the clause names the indeterminate cases slug resolution can actually produce (a slug resolving to zero records or to more than one). **Control, because this criterion asserts PRESERVATION rather than addition:** the same probe against `git show origin/main:core/schemas/gate-criteria-spec.md` must **also** be non-zero. A probe firing only post-fix would grade the clause as newly introduced, which is not the claim AC-4 makes |
| #6232 | AC-1 | Cluster inventory re-derived at build time | **[DEFERRED — the population is unreproducible as written; carried into Stage 6 as an open disposition per Collective Review]** |
| #6232 | AC-2 | `python3 release/tools/generate-adr-index.py --verify` | Exits 0, reports `COUNT 0` · control: a hand-edited row inside the managed region must report non-zero `COUNT` |
| #6232 | AC-3 | **Corrected — the original row ran `test -f core/ADRs/README.md`, which exits 0 on the unmodified base tree and grades AC-1's subject (index presence) rather than AC-3's own negative.** AC-3 is the negative *"no new ADR authored; no existing ADR record edited."* A presence probe cannot express it. Method, two arms over this card's own commit range (`98d43b4d..fdae31d1`, matched by commit subject — the branch was re-signed, so positions are stable and SHAs are not): `git diff --name-only <range> -- 'core/ADRs/ADR-*.md' 'release/ADRs/ADR-*.md'` for the edit limb, and the same range with `--diff-filter=A` for the authorship limb | **Zero paths on both arms** — measured 0 records edited, 0 files added; the card's whole delta is 3 files, none an ADR record. **Control, and it is what makes the zero a held negative rather than a wrong diff range:** the identical instrument over the sibling range that *does* rewrite records (#6231, `438d5b38..2188999a`) must return non-empty — **measured 23 paths**. Zero on both arms would mean the range is wrong, not that the negative holds |
| #6232 | AC-4 | **Corrected — the original row grepped `release/ADRs/README.md` for the literal `managed region`, which occurs 0 times there at base AND at head, so it could not pass on any tree.** The defect was introduced by a cross-card formatting pass (`438d5b38`, #6230), not by this card's authoring. AC-4's real subject is the *recorded determination*, which lives in the Derived-Surface Contract, not in the release-side README. Method, two limbs over `release/references/standards/release-corpus-schema.md`: count `Cross-cutting pattern index` base-vs-head, and assert the markdown table row count is **unchanged** — the determination must land inside the existing `core/ADRs/README.md` row rather than as a new row | Needle **0 at base → 1 at head**, and that single occurrence sits on the row that names `core/ADRs/README.md`. Table pipe-lines **132 → 132**: no row added. **Control (sensitivity), and it is the whole of the second limb:** a planted row must break the equality — measured **133 vs 132**, so the instrument discriminates rather than returning a constant. **Second sensitivity arm:** the matcher fires on strings known present in the same file (`Derived-Surface Contract` → 3, `RELEASE_LOG.md` → 10). **Specificity arm:** a fabricated needle returns 0 on that same file, so the base-side 0 is a real absence and not a dead matcher |
| #5823 | AC-1 | **Corrected; the original `[DEFERRED — unsatisfiable]` verdict was right and is replaced, not removed.** AC-1's stated method is a closed binary whose only exits are executing the withdrawn migration (barred by the card's own Risks section) or freezing the record (rejected at the Tier-0 gate), so no lawful work could satisfy it. Replacement predicate, graded on the record: ADR-032 carries a landed reachable record of its execution disposition, its `status:` leading token is UNCHANGED, and no live path reference names a retired home. Method: extract the leading token with the durability tool's own `_leading_status_token`, parse `superseded_by:` with its own `SUPERSESSION_ENTRY_RE`, and count the retired leaf | Token `Accepted`; exactly one `in-part` entry naming ADR-141 with a scope label and zero malformed chunks; 0 occurrences of the retired leaf. **Control, and it is what makes "unchanged" mean anything:** the token is compared base-vs-head against `git show 539c4440:core/ADRs/ADR-032-release-corpus-public-vs-instance-split.md`, because a post-fix-only read cannot distinguish an unchanged token from an unread file. **Second control:** `grep -rl "personal/pmo-instance" core/ADRs/` must still return records, so the subject's 0 is a removal rather than a broken matcher |
| #5823 | AC-2 | **Corrected — the original row graded `status:`, which is AC-1's subject.** AC-2 is conditional ("If superseded, the successor ADR file exists and ADR-032 names it"); the operator rendered no status change, so its antecedent is FALSE and it passes vacuously. A vacuous pass is not evidence, so the row grades both limbs: assert the antecedent is false (leading token `Accepted`, not `Superseded`), AND assert the record names its superseding record anyway, which is the substance AC-2 reaches for. Method: `grep -c "^superseded_by: ADR-141 in-part" core/ADRs/ADR-032-*.md` — the pointer must be in the FIELD, since a `git grep -c ADR-141` counts prose mentions and would PASS a record carrying no pointer at all | Antecedent false; field-anchored pointer non-zero. **Control:** `grep -c "ADR-032" core/ADRs/ADR-141-*.md` non-zero, which proves in one read that the path resolves, the matcher fires, and the edge is two-sided rather than orphaned |
| #5823 | AC-3 | **Corrected, and SATISFIED before merge.** The original row carried the release-notes probe, one criterion off. AC-3 requires an open child of epic #1184 whose title names the release corpus. At build time no such child existed and the row was recorded UNMET; the child was created on 2026-09-02 as **#6627** *"Declare the release-corpus home selector and decide the corpus location"*. The composition lock never applied to it: `release-process.md` § A7 bars adding an issue *to a composition-locked Milestone*, and #6627 is unmilestoned. Method, two parts: `grep -n "corpus_home" release/releases/plans/adr-corpus-status-integrity_RELEASE_PLAN.md` reading the `### Exclusions` entry; then the card's own predicate, `gh api repos/{owner}/{repo}/issues/1184/sub_issues` | Routed spec present, naming the selector, its config surface, the hardcoded Check-33 consumer and the still-owed location decision — and #6627 carries that spec in its body, not merely in its title. Sub-issue limb **MET**: #6627 `state: open`, native sub-issue of #1184, `milestone: none`. **Control, and it is what makes the non-zero a creation rather than an empty read:** the same `gh api` call returns **13** children (10 open / 3 closed) and exactly **one** names the release corpus, so the read is non-empty and the matcher discriminates |
| #5823 | AC-4 | **Corrected by re-aiming: the original AC-3 row carried this method and its control, one criterion off.** Two single-pattern probes over `release/references/standards/release-notes-standard.md`, `grep -c "post-extraction"` and `grep -c "until the extraction lands"`, run separately because an alternation cannot survive markdown-cell pipe-escaping into the executor | 0 on each arm. **Control:** `grep -c "release note"` non-zero, proving the file resolves and the matcher fires. **Second control, and it is what stops a destructive pass:** AC-4's other exit is "consistent with a still-Accepted ADR-032", so the Surface-3 privacy cell must still classify the surface as operator-instance content — deleting that classification would satisfy the zero while contradicting the decision this card preserves |
| #5823 | AC-5 | **Corrected — the original row ran `test -f` on a config template, which grades nothing about discrimination and would pass on any tree where that file exists.** AC-5 asks whether the audit flags a legitimately-scoped open deferral. Method: run the audit this card actually used against the record AC-5 names — `python3 release/tools/check-adr-durability.py --files core/ADRs/ADR-082-headless-dom-test-tool-jsdom.md` — and read `COUNT` | `COUNT 0`, with ADR-082's "deferred, not foreclosed" clause confirmed present so the record graded is the one AC-5 names. **Control, and it is the whole row:** the SAME invocation on the SAME record with a planted durability defect must report non-zero, then restore byte-identically — a zero on both arms means the record was never evaluated, not that it was found clean. The no-`--diff-base` run emits visible `CONFIG R5/R6 SKIPPED` lines rather than counting them green |
| #5823 | AC-6 | **Corrected — the original row grepped the #5823 card body, the wrong artifact entirely; a body merely naming the disposition would pass while the metadata stayed `completed`.** AC-6 grades #1549's close reason. Method: `gh api repos/{owner}/{repo}/issues/1549 --jq .state_reason` — the porcelain `gh issue view` routes through GraphQL and is unavailable at this quota | `not_planned` — **measured `not_planned` at merge**, so AC-6 grades MET. At build time the field read `completed` against a `status: rejected` label; a Stage-6 spoke may mutate no issue but its own sub-task, so the correction was routed to the hub/operator and the row recorded UNMET. The hub corrected it on 2026-09-02; metadata and label now agree. **Control, re-aimed because the row's original control no longer discriminates:** #2427 returns `not_planned`, now identical to the subject, so it can no longer separate the two values. The same call against #2379 — a sibling child of #1184 closed as completed — returns `completed`, proving the field is read and its value discriminates rather than every issue returning one string |

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

(Authored per [`release/governance/RELEASE_PROTOCOL.md`](/release/governance/RELEASE_PROTOCOL.md) § Change Description Protocol. Written at the Stage-8 reconciliation pass rather than at Stage-6 PR assembly, under the protocol's own refresh clause — the section is written or refreshed on the release branch when Stage 7/8 surface material changes. PR #6626 carries all 28 commits from all six cards. Distinct artifact from the user-facing release note authored at Stage 13 Close.)

### Outcome

A record superseded on one clause no longer has to choose between a false whole-record `Superseded` flip and a silent contradiction: the ADR corpus gains a reciprocal partial-supersession carrier (`supersedes:` / `superseded_by:` with an `in-part` scope label), a standing reciprocity rule in the durability lint, and eleven adjudicated edges landed on their targets. The corpus also gains a named owner for the ADR ratification flip (Stage 13), a standing detector for `## Status` bodies that disagree with their own frontmatter, and a hand-authored cross-cutting pattern index that makes five convergent decision clusters reachable from either module README. ADR-032's long-standing repository-versus-record contradiction is dispositioned rather than left open — the record stays `Accepted`, carries a clause-scoped `superseded_by:` on its Decision-1 home path only, and the successor work it still owes is tracked as an open child of the adapters epic.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #6230 | Partial-supersession carrier as a reciprocal frontmatter pair, R6 reciprocity in `check-adr-durability.py`, index non-projection, and the ADR-170 founding record. | PARTIAL |
| #6231 | The eleven adjudicated partial-supersession edges land on their target records, with machine-discoverable markers for non-ADR counterparties. | DONE |
| #4761 | Stage 13 owns the ADR ratification flip; R7 `STATUS-AGREEMENT` ships as a standing two-surface detector; 30 records' `## Status` body reconciled to their frontmatter; ADR-171 records the authority. | PARTIAL |
| #4762 | `G-EX9` resolves a hop by slug and asserts the performed move rather than the note's shape; `gate-criteria-spec.md` bumped to v2.17. | DONE |
| #6232 | Hand-authored cross-cutting pattern index — 5 clusters, 27 records — in the core ADR README, reachable from the release ADR README, with the curated-not-projected choice registered in the Derived-Surface Contract. | DONE |
| #5823 | ADR-032 re-affirmed `Accepted` with a clause-scoped `superseded_by: ADR-141 in-part`; its retired instance leaf repointed; release-notes and corpus-home standards reconciled; successor scope created as #6627 under epic #1184. | PARTIAL |

`PARTIAL` on #6230 and #4761 records one criterion each that Stage-8 QA graded `PARTIAL` rather than `MET`; `PARTIAL` on #5823 records AC-1, graded `FLAG-UPSTREAM` and routed to the Stage 9 operator gate. None is a `NOT MET`, and no Operator Override Record is owed on any of the six.

### Key decisions

This release has no `## Hub-Rendered D-Decisions` section; the operator-rendered decisions are recorded in the sections named below rather than restated here.

- **ADR-032 disposition — re-affirm (Tier-0, operator-rendered at the Stage-4 Phase B D-Gate).** `status:` stays `Accepted` at base and at head; a clause-scoped `superseded_by: ADR-141 in-part` carries Decision 1's operator-instance home path and nothing else. A whole-record `Superseded` flip would have forfeited the right to repair the record's genuinely false path strings — a repair this release then made. Recorded at § Risk Register, row R5.
- **Release Class `novel` (operator-rendered at the Stage-4 Phase B gate).** Three `novel` triggers fire on live membership; `class_weight` 1.15 yields `effective_pts` 29 against the 15–25 band — a recorded G3-15 breach proceeding under operator override. Recorded at § Release Class.
- **#6232 roster concession (operator-rendered 2026-09-02).** The index's only demonstrated negative was falsified on the section's own criteria, so ADR-010 is admitted and the roster becomes 5 clusters / 27 records. The operator elected to concede rather than re-word the cluster question, and the index states the resulting limitation instead of manufacturing a replacement exclusion. Recorded on #6232's card body.

### Reversibility

**CHEAP — HIGH confidence.** `git revert` of the release PR restores the prior state exactly: every change is markdown or an in-repo Python/shell tool edit, § Schema Migrations is empty by measurement, and § Operational Deployment Manifest carries no Stage-12 row — so there is no migrated data and no deployed external state to unwind.

### Downstream impact

- **R6 reciprocity and R7 `STATUS-AGREEMENT` run on every later durability scan**, so a one-sided supersession edge, or a `## Status` body that disagrees with its own frontmatter, surfaces at the next release instead of accumulating silently.
- **Consuming surfaces:** `check-adr-durability.py` (R6/R7), `generate-adr-index.py` (index non-projection), `gate-criteria-spec.md` v2.17 (`G-EX9`), `release/references/pipeline/stage-13-close.md` (ratification-flip ownership), and the `adr-helper` scaffolding procedure, whose compiled package is rebuilt as a Stage-6 C4 obligation.
- **Carry-forward — #6627**, an open, unmilestoned native child of epic #1184, owns the release-corpus home selector and the still-owed corpus-location decision. It needs a milestone before it can be scheduled.
- **Carry-forward — ADR-032's Decision-1 assignment still binds** while the corpus surfaces it assigns to the operator-instance home remain tracked in-repo. Stage-8 QA graded this `FLAG-UPSTREAM` for the Stage 9 operator gate; the milestone close-out must not report it closed.
- **Carry-forward — #4761 AC-7's `Proposed`-record ratification batch** is satisfiable only by an operator-rendered decision at Stage 9 Plan Review, enumerated per record, never by an agent-applied flip.

### Cross-references

- Release plan: this file, top section
- Milestone: `adr-corpus-status-integrity`
- User-facing release notes: authored at Stage 13 Close into `release/releases/notes/`, per [`release/references/standards/release-notes-standard.md`](/release/references/standards/release-notes-standard.md)

<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
# Release Plan: governance-pointer-fixes — Governance surfaces cite their owner or the live mechanism

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The provisional slot recorded at the Stage-4 D-Gate is `v4.61`, re-verified free at Engineering Commit 0; the concrete number binds only at the Stage-12 atomic claim (ADR-092), so the branch, this file's name and the milestone all stay slug-primary until then. |
| **Date Created** | 2026-09-10 (Thursday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | release/governance-pointer-fixes |
| **PR** | #7401 (draft; transitions to ready-for-review at the Stage 9 gate) |
| **Milestone** | governance-pointer-fixes |

**Release Outcome Statement.** Four governance surfaces each assert something about a mechanism they do not own, and each assertion is wrong in the same shape: it states a conclusion without naming the artifact that owns it. This release corrects all four so that every one names the owner or the live mechanism — a stale layout instruction cites the standard that superseded it, a readiness state records its safety basis, a skill's absence-claim names the hook that actually matches, and a pipeline instruction names the provenance form its own resolver recognises.

## Scope

### Issues Included

| # | Issue | Title | Priority | Category | Labels |
|---|-------|-------|----------|----------|--------|
| 1 | #5892 | RELEASE_PROTOCOL.md instructs note foldering that the amended flat-notes standard forbids (tier inversion) | P2 | bug | `bug`, `cluster: documentation`, `size:XS`, `type:bug`, `project:platform-quality` |
| 2 | #6409 | stage-05-solutioning § 5.7 instructs a non-conformant provenance form | P3 | bug | `bug`, `size:XS`, `type:bug`, `project:platform-quality` |
| 3 | #6241 | Release-readiness state 4 renders clean without consulting merge-state, and its safety basis is unrecorded | P3 | bug | `bug`, `size:XS`, `project:platform-quality` |
| 4 | #6394 | intake-desk Mode C states no hook sees `gh issue create`, but block-gh-path-leak.sh matches it and reads the body | P3 | bug | `bug`, `size:XS`, `type:bug`, `project:platform-quality` |

**Four members, 4 raw / 4 effective points.** Deliberately below the 15–25 point band: this bundle was split out of `governance-docs-reconciled` when the parent exceeded the 25-point ceiling, so under-filling after a governed split is the split working rather than a capacity defect.

### Withdrawn member — #4982

`#4982` (*hub-session-continuity glosses 3 of 6 fields with no pointer to their contract*) was **withdrawn and closed as not-reproducible** at the Stage-4 plan gate under D-4982-Disposition, and is closed carrying `status: rejected`. Its headline premise — a 6-field record at `core/standards/hub-session-continuity.md:213` — does not exist at the baseline pin: a structured enumeration of all 12 markdown table headers in that file returns column counts `3 · 13 · 4 · 4 · 7 · 4 · 4 · 3 · 4 · 4 · 2 · 4`, none of which is 6, and `:213` resolves to `## 6. Decision Log Mechanism`, a 4-column table that already carries a contract pointer. The same verdict was reached independently by the operator's own readiness sweep at an earlier baseline, with the sensitivity arm firing nine times. The record is retained rather than deleted because the card's transferable lesson survives its withdrawal: *a deferral justified by "a reader can recover it" should be tested against the surface being deferred.* Reopenable at any time with a pinned surface.

**Consequence for this plan:** `core/standards/hub-session-continuity.md` is **not** in this release's write set, and the Stage-4 comment's `CONDITIONAL:4982-pinned` File Change Matrix row is removed rather than carried forward. `issues_added` remains **0** — a withdrawal is not an addition, so the composition lock is intact.

### Dependency Graph

```
#5892   (isolated)   release/governance/RELEASE_PROTOCOL.md
#6409   (isolated)   release/references/pipeline/stage-05-solutioning.md
#6241   (isolated)   release/references/specs/release-readiness-scan-spec.md
#6394   (isolated)   operations/skills/intake-desk/SKILL.md
                     operations/skills/intake-desk/references/output-contract.md

in-bundle edges: 0        circular chains: 0
```

**Measured, not asserted.** Tested three ways, all zero at the baseline pin: **write-set intersection** — 0 of 10 unordered pairs over the original five-card set (sensitivity arm: injecting a sixth card writing `RELEASE_PROTOCOL.md` yields 1 contended pair, so the comparator fires; specificity arm: two cards in the same directory with different basenames yields 0, correctly); **declared dependencies** — only `#6241` declares one, and it points *outward*; **content edges** — no member's acceptance criteria reference another member's target file, and no member's edit precedes another's. `#6394` and `#6409` share a defect shape, and `#5892` and `#6241` share another, but a shared shape is not a dependency edge.

**One outward edge, satisfied by content rather than by state.** `#6241` declared a dependency on the CI-stability work tracked as `#4974`. That issue is closed, and — the load-bearing check — the classification changes it delivered are present on the pinned baseline: state 2 of § 5.1 carries the collapsed-denominator fix verbatim (*"…OR the observed required-row count is fewer than that count"*). The edge was verified by reading the section, not by reading the issue's state.

**No typed artifact relationships** — the bundle has no native or body dependency edges and no Create/supersede file changes.

### File Change Matrix

```
# ── Unconditional EDIT rows ──────────────────────────────────────────
release/governance/RELEASE_PROTOCOL.md                            edit
release/references/pipeline/stage-05-solutioning.md               edit
release/references/specs/release-readiness-scan-spec.md           edit
operations/skills/intake-desk/SKILL.md                            edit
operations/skills/intake-desk/references/output-contract.md       edit
packages/intake-desk.skill                                        edit
packages/intake-desk.skill.sha256                                 edit

# ── Unconditional ADD row ────────────────────────────────────────────
# Authored at Engineering Commit 0. Slug-primary until the Stage-12 claim
# renames it under plans/v<MAJOR>/ per ADR-092.
release/releases/plans/governance-pointer-fixes_RELEASE_PLAN.md   add

# ── Read-only inputs (excluded from the delivery obligation) ─────────
core/standards/duplicate-source-discipline.md                     READ
core/hooks/block-gh-path-leak.sh                                  READ
core/hooks/block-autonomy-ceiling.sh                              READ
core/hooks/block-skill-direct-edit.sh                             READ
core/rules/bypass-mode-readiness.md                               READ
release/references/standards/release-notes-standard.md            READ
release/references/pipeline/stage-04-planning.md                  READ
release/ADRs/ADR-147-domain-practice-source-grammar-routes-it-does-not-extend.md   READ
release/tools/verify-release-plan.sh                              READ

# ── Release-wide explicit non-scope ──────────────────────────────────
release/releases/RELEASE_LOG.md                                   NOT EDITED
release/releases/RELEASE_INDEX.md                                 NOT EDITED
core/standards/hub-session-continuity.md                          NOT EDITED
```

**Three paths entered this matrix after the Stage-4 comment was authored, each under a named Stage-5 determination.**

| Path | Determination | Why it is here |
|---|---|---|
| `operations/skills/intake-desk/references/output-contract.md` | **D-6394-Scope** — widen to both files | The originating finding named the mirror explicitly; the card's Affected Files field dropped it. Both files ship inside one `.skill` package, so correcting only `SKILL.md` leaves the shipped skill self-contradictory at the surface a Mode C run actually reads — while the milestone reads green. |
| `packages/intake-desk.skill` | **D-Package-Rebuild** — the rebuild lands in this pull request | Not a release-cut step. See the correction note below. |
| `packages/intake-desk.skill.sha256` | **D-Package-Rebuild** | The content-baseline sidecar is rebuilt and committed with its package, never separately. |

**The package rebuild lands IN this pull request, and this corrects the approved plan.** The Stage-4 risk register recorded the rebuild as a release-cut step with an expected interim staleness reading through Stages 6–12. That was true under the gate's prior warn-mode posture and became false when the gate graduated. At the baseline pin, `.github/skill-package-freshness.yml` declares `posture=required(enforce; ratified 2026-09-04)` with **no path filter, by design**, and `.github/skill-package-freshness.enforce` contains exactly one non-comment token: `enforce`. A STALE verdict exits 1, and the job is a red required check on a branch-protected branch. The alternative to rebuilding in this PR is a pull request that cannot merge, so there was no choice to render. The tracked package additionally embeds both edited files today (`SKILL.md` at 6 token hits, `references/output-contract.md` at 2) — a defective surface no markdown-only sweep can see.

**New-executable companion obligation: N/A** — enumerated over the matrix's `add` and `edit` rows; zero of them is a tracked `*.sh`, so no `core/config/allowlists/script-execution-allowlist.txt` row is owed.

### File Contention Map

**Within-release contention: ZERO. Measured.**

```
Probe:       pairwise set-intersection of per-card write sets (python3)
Denominator: 4 cards -> 6 unordered pairs; 5 distinct corpus write-set paths
             (+2 package paths, both owned solely by #6394)
Control - sensitivity: inject a card writing RELEASE_PROTOCOL.md
             (a genuine collision) -> observed 1 pair   [FIRES]
Control - specificity: two cards in the SAME directory, different
             basenames (stage-04 vs stage-05) -> observed 0   [correct]
Extraction:  all write-set paths tested for existence; all EXIST
Result:      0 of 6 pairs contended
Verdict:     CLEAN
```

Each corpus target sits in a distinct directory, so even the weaker directory-collision test reads zero. `#6394` owns both of its own two files plus both package paths, so its internal multiplicity is not contention — a single writer.

**Cross-PR contention: ZERO at the pin, re-checked at Commit 0.** Two concurrent releases are in flight, both draft and both unmerged: `closeout-correctness-batch` (19 files) and `pack-conformance-and-parity` (1 file). Neither changed-file set intersects this release's write set. The near-miss worth naming, because it is where a careless re-check produces a false positive: the first of those touches `core/standards/hub-action-tracking.md` — same directory and a similar name to the withdrawn `#4982`'s target, a different file.

**Structural-blast-radius (Tier-S): no edge.** The mover set is **empty** — zero renames, relocations or deletions, and the only `add` is this plan file. So the moved-surface set is empty and its intersection with every sibling release's edit set is empty by construction.

**Version-slot (`Δversion/<claim-key>`): one real Tier-S edge, governed rather than blocking.** Both concurrent releases are candidates for the same `v4.61` slot. Governed by the atomic claim: whichever release merges and pushes its signed tag first claims the slot, and the others re-derive. Because the branch, this plan file and the milestone are all slug-primary, nothing renames if the slot moves. See D-Version and R-4.

### Cross-Milestone Dependency Validation

#### G3-07 Status

`PASS — 1 dependency edge checked, 0 cross-milestone violations`

The single edge is `#6241`'s outward declaration, whose target is closed and whose delivered content is present on the pinned baseline. No in-release edges exist to check.

### Exclusions

- `#4982` — withdrawn and closed as not-reproducible at the Stage-4 plan gate; see § Withdrawn member above.
- `release/releases/RELEASE_LOG.md` and `RELEASE_INDEX.md` — release-corpus governance artifacts land via the Stage-12 and Stage-13 chore PRs, never in the release PR.

## Implementation Sequence

`#5892` → `#6409` → `#6241` → `#6394`.

With zero dependency edges the sequence is a **constraint-class ordering, not a dependency constraint**: operator-executed first, then unconstrained agent work, then the package-tailed card last. The milestone's own *"largest first"* ordering optimizes for nothing here.

| # | Card | Rationale |
|---|---|---|
| **0** | **#5892** | **Operator-executed, and the only fixed-cost step.** Its target is Tier-0 floored, so it cannot batch with agent work; landing it first means the branch carries it before any spoke touches the tree, surfacing the gate at the first step rather than the second. |
| 1 | #6409 | Smallest, fully-specified, single-region edit; cheapest verification first, and the only card in the release whose acceptance criterion has a runnable resolver. |
| 2 | #6241 | Additive prose only; no predicate changes. |
| 3 | #6394 | Last of the agent set: the only card whose scope widened at Stage 5 (two files, four clauses), the only one triggering the skill-edit discipline, and the only one with a package-rebuild tail. |

### Issue #5892: RELEASE_PROTOCOL.md instructs note foldering the amended standard forbids

**Change Specification:**
- **Files modified:** `release/governance/RELEASE_PROTOCOL.md`
- **Change description:** Three stale layout assertions, at the File Structure fence's `plans/` and `notes/` rows, the naming-convention paragraph, and the normative sentence about flat files at the `notes/` root. The third is the consequential one — it is a live normative instruction directing a future release to fold release notes in a way the amended flat-notes standard forbids, which is a tier inversion rather than a cosmetic staleness. The corrected text must not merely stop contradicting the standard; it must *cite* it, so the inversion cannot silently re-open. The applied text is parameterized (`v<MAJOR>/`) and carries no counts, so it survives corpus drift.
- **Acceptance criteria:** 5 (AC-1 flat tree with `_unversioned/` only and parameterized plans rows · AC-2 naming convention distinguishes plans from notes and cites the standard · AC-3 the normative sentence no longer instructs foldering · AC-4 claim-axis sweep returns zero with a firing sensitivity arm · AC-5 the deploy-check layout check and the corpus linter run clean)
- **Estimated complexity:** Low
- **Dependencies:** None
- **Execution path:** **operator-executed** — see § Agent-Editability Read
- **`deliverable_state`:** `artifact-accepted` — the release declares no Layer-2 propagation target for a governance-prose edit.
- **Note on AC-1's parenthetical:** the criterion's rationale cites a stale file count. The *applied* text is count-free, so no re-derivation of the fix is owed; only the parenthetical is corrected.

### Issue #6409: stage-05-solutioning § 5.7 instructs a non-conformant provenance form

**Change Specification:**
- **Files modified:** `release/references/pipeline/stage-05-solutioning.md`
- **Change description:** § 5.7's upgrade-mechanism **step 2** instructs replacing the label's `source: UNSOURCED-DOMAIN` value with *"the cited source list"* — a prose phrase that the `_prov_source_form` resolver in [`release/tools/verify-release-plan.sh`](/release/tools/verify-release-plan.sh) returns **NONE** for, because the resolver matches the value against a closed grammar rather than reading it as prose. Rewrite the step so it instructs a value the resolver resolves to a **named** form, by naming the form and deferring to its owner. **The grammar is not restated here or in the edit** — the Stage-4 Planning spec's Phase A1.5 step owns the `source:` value grammar and Stage 5 inherits it, so a second copy in Stage 5 would author exactly the defect class this release corrects and would fail the release's own CIAC-2.
- **Acceptance criteria:** 3 (AC-1 the instruction names a form the resolver resolves, not NONE · AC-2 a probe over § 5.7 shows zero NONE-resolving instruction-shaped directives, both arms · AC-3 the instruction-vs-count shape gap is noted so a future cascade can see this section)
- **Estimated complexity:** Low
- **Dependencies:** None
- **Execution path:** ordinary Engineering spoke
- **`deliverable_state`:** `artifact-accepted`
- **Tier 1 [ADJUST] carried from Stage 4:** the card cites the defect at line 161; it had drifted to line 165 by the baseline pin. The fix **restates the citation as a content anchor — *§ 5.7, upgrade-mechanism step 2*** — rather than repairing the number. A content anchor cannot drift, and that is the card's own transferable point.
- **Root cause, recorded because it is the transferable part:** the cascade that introduced the closed grammar swept on a **count** axis (the phrase *"one of three legitimate forms"*, a 3-to-4 count change). § 5.7 states the rule in **instruction** shape and names no count, so a count-shaped sweep was structurally blind to it. The section acquires a note saying so, which is what makes a future cascade able to find it.

### Issue #6241: Release-readiness state 4 records no safety basis

**Change Specification:**
- **Files modified:** `release/references/specs/release-readiness-scan-spec.md`
- **Change description:** § 5.1's state 4 derives its verdict from *"every required row is `pass` AND `isDraft` is true"* — no merge-state term. The section covers state 5's borrowed pass set, the draft predicate, the settle allowance and the fail-closed posture, but records no safety basis for state 4. Add the missing basis as **additive prose only**: state 2's population floor as state 4's safety basis, and the workflow-trigger-configuration dependency the card's own evidence names. Recording *why* the ordering is safe is the durable form; reordering is explicitly **not** requested, and every state predicate and the precedence order stay unchanged.
- **Acceptance criteria:** 2 (AC-1 § 5.1 states state 4's safety basis naming the required mechanisms · AC-2 the precedence order and every state predicate are unchanged)
- **Estimated complexity:** Low
- **Dependencies:** None in-release; the one outward edge is satisfied by content on the pinned baseline.
- **Execution path:** ordinary Engineering spoke
- **`deliverable_state`:** `artifact-accepted`
- **Hub divergence carried into the build (Tier 1 [ADJUST]) — the delta is narrower than the card states.** The card reads as though § 5.1 names *neither* required mechanism. It already names the second: the gate identifier appears in a paragraph that closes by tying itself to *"this dimension's state-4 PASS"*, and a pickaxe search dates that sentence to before the card was filed. Engineering adds the two genuinely-absent limbs and **must not re-assert the mechanism that is already named** — a second copy of an existing claim is this release's own defect class and would fail CIAC-2.

### Issue #6394: intake-desk Mode C states no hook sees `gh issue create`

**Change Specification:**
- **Files modified:** `operations/skills/intake-desk/SKILL.md`, `operations/skills/intake-desk/references/output-contract.md`, `packages/intake-desk.skill`, `packages/intake-desk.skill.sha256`
- **Change description:** The skill asserts that no hook observes a `gh issue create` call. A hook does match it and read its body. Every occurrence of that universal-absence claim is corrected — **not only the two the card's AC-1 names.** Each corrected sentence names the hook whose coverage it asserts, states the hook's shipped mode, and cites the hook's path, so a later matcher change makes the claim falsifiable against a named file.
- **Acceptance criteria:** 2, with AC-1 **re-scoped** (see below)
- **Estimated complexity:** Low
- **Dependencies:** None
- **Execution path:** ordinary Engineering spoke, with a **gating** skill-edit discipline pass before push
- **`deliverable_state`:** `deployed-copy-synced` — the `.skill` package rebuild is this card's propagation target and it lands in this PR.
- **AC-1 re-scoped (Tier 1 [ADJUST]).** AC-1 says *"both … sentences"*. A whole-file sweep returns **6** occurrences across at least **3** distinct sites, two of which sit **outside** the Mode C body. AC-1 is re-scoped to *every occurrence of the universal-absence claim in both files*, verified by whole-file count rather than by the two named lines. This is recorded because an enumerated repair list read as a ceiling is a failure shape already on this platform's record: the spoke fixes the two named sentences and leaves the others asserting the same falsehood.
- **D-741-Fence.** One occurrence was classified in-scope by the design pass and out-of-scope by the adversarial review. It is **qualified rather than adjudicated**: it gains the scoping enumeration its three already-true neighbours carry, which makes it true under both readings. The disagreement was routed rather than settled — two composed specialists disagreeing on a domain judgment is not the orchestrator's call.
- **D-Replacement-Wording.** The design's proposed replacement clause was an unqualified absolute of exactly the class this release corrects, and it is **rejected as authored**. The correct form states what the hook does **where its wiring is loaded**, names its shipped mode, and says plainly that an un-rehomed instance does not load it at all — because the loading condition fails for any session rooted in the repo or a worktree. Recorded rather than gated: CIAC-2 already forbids the unqualified form, and the wording is Engineering's to author.
- **Regression arm is a FLOOR, not an equality.** The pre-fix occurrence count is a floor: the enforcement-absence claim survives the fix and the operative conclusion is present verbatim. As an equality over prose the same build rewrites, the arm fails on a *correct* build.
- **Re-address by verbatim anchor text, and apply edits bottom-up.** The design's own first edit invalidates its later line addresses, and one prescribed line range enclosed a scoped-true clause it meant to preserve.

### Agent-Editability Read

**Derivation** — controls read at commit `a3083858`:

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — `case` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"`: **2** observed. The first is anchored to the platform checkout; the second is a repository-membership block, anchor-free and guarded by a platform-worktree test. Projecting the anchored arms into repo-relative form and testing each against the tracked index at that SHA discards the three arms naming the *deployed* agent-config surface, which the repository does not track at all. Surviving union: `{*/CLAUDE.md, */OPERATIONS.md, */RELEASE_PROTOCOL.md}`. **The membership block is the operative arm** — being anchor-free and worktree-guarded, it fires wherever an Engineering worktree sits. The guard is a *condition to fire*, not an exemption.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — the skill-scope regex matches `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`; the arming key is a frontmatter migration flag grepped per-file, whose failure branch exits 0 (*"not yet gated"*); the exemption list resolves against the **deployed** hook directory and is **`undetermined`** on this host, because that directory does not exist here.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|------|----------------|----------|--------------|-----------|-----------|----------------|
| #5892 | `release/governance/RELEASE_PROTOCOL.md` | **YES** — membership arm `*/RELEASE_PROTOCOL.md`, unconditional block | n/a (Tier-0 precedence) | `tier-0-floored` | `tier-0-floored` | **operator-executed** |
| #6409 | `release/references/pipeline/stage-05-solutioning.md` | no | conjunct **1 FALSE** — not under a `*/skills/*/` path | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6241 | `release/references/specs/release-readiness-scan-spec.md` | no | conjunct **1 FALSE** | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6394 | `operations/skills/intake-desk/SKILL.md` | no | conjunct 1 TRUE (matches the scope regex); conjunct **2 FALSE** — the file carries **0** matches for the arming key | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6394 | `operations/skills/intake-desk/references/output-contract.md` | no | conjunct 1 TRUE; conjunct **2 FALSE** — same file-level arming key, same absence | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6394 | `packages/intake-desk.skill` · `.sha256` | no | conjunct **1 FALSE** — not under a `*/skills/*/` path | `unconstrained` | `unconstrained` | ordinary Engineering spoke (tool-generated) |

Per-path rows are retained, never collapsed into the card class.

**`#6394` is decided by conjunct 2 — a discriminating read, not a lucky one.** The path *does* match the scope regex, so conjunct 1 does not settle it. The arming key is absent, and the sensitivity arm makes that meaningful: of **57** tracked `SKILL.md` files, **52** carry the key; `intake-desk` is one of five that do not. Because conjunct 2 is FALSE the conjunction is FALSE regardless of the `undetermined` exemption list, so the fail-safe rule (conjuncts 1 and 2 true with 3 undetermined ⇒ sanctioned-session-required) is **not reached**. Had the key been present, this row would read `sanctioned-session-required` on the undetermined conjunct alone.

**Consequence, stated because the obligation outlives the enforcement:** no control will stop a spoke editing these skill files without the skill-edit discipline pass. R-7 exists because the obligation is real and the enforcement is not.

**`#5892` presents no split decision** — its write set is a single floored path, so there is no unconstrained limb to land separately.

### Integration Points

| Point | Members | What must hold |
|---|---|---|
| The flat-notes standard ↔ `RELEASE_PROTOCOL.md` | #5892 | The corrected text must not merely stop contradicting the standard — it must *cite* it, so the tier inversion cannot silently re-open. |
| The path-leak hook ↔ `intake-desk` SKILL.md and its output contract | #6394 | Each corrected sentence must name the hook whose coverage it asserts and state its shipped mode, so a later matcher change makes the claim falsifiable against a named file. |
| The closed `source:` grammar and its Stage-4 owner ↔ `stage-05-solutioning.md` § 5.7 | #6409 | The instruction must produce a value the resolver resolves to a **named** form — the one point in this release with a **runnable** resolver, verified by execution rather than by reading. Stage 4 owns the label schema and Stage 5 inherits it, so the instruction names the form and defers; restating the grammar creates a second source. |
| § 5.1 ↔ the readiness gate and the Stage-12 pre-merge phase | #6241 | The added prose names two external mechanisms; both must exist and be named accurately, or the fix reproduces this release's own defect class. |
| Release PR ↔ the operator-applied commit | #5892 × all | Under D-5892-Delivery option (a) both share one branch, and the operator's commit must land **before** Stage 7, or Stage 7 dev-tests a tree missing a member. |
| `.skill` package ↔ both edited skill files | #6394 | The package rebuild must land in the same PR as the last skill edit, or the enforcing freshness gate turns the required check red. |

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| **R-2** | **`#5892` cannot be delivered by any agent** — the Tier-0 block is unconditional, mode-independent, and carves out no worktree | High (certain) | Major | D-5892-Delivery option (a): the operator commits onto the release branch before Stage 7. Landed at Commit 0's parent. Stating it in the plan prevents a spoke spending its budget reaching a wall the plan already knew about | Operator |
| **R-3** | **The `.skill` package reads stale and turns the required freshness check red** | High | Major | **Superseded and inverted by D-Package-Rebuild.** The Stage-4 register recorded a stale package as *expected and not a defect* through Stages 6–12; the gate has since graduated to enforcing with no path filter, so a stale package is now a red required check and an unmergeable PR. The rebuild lands in **this** PR, after the last skill edit | Engineering |
| **R-4** | **Provisional `v4.61` is contested** by two concurrent in-flight releases | Medium | Minor — governed | The version binds only at the atomic claim; the losers re-derive at their own Commit-0 re-verify and at the Stage-12 freeness check. Branch, plan file and milestone stay slug-primary, so nothing renames if the slot moves. Re-verified free at this Commit 0 | Hub |
| **R-5** | **`#6394`'s AC under-counts its scope**, and an enumerated repair list becomes a ceiling — the spoke fixes two sentences and leaves the rest asserting the same falsehood | Medium | Major | AC-1 re-scoped to *every* occurrence across both files; verified by whole-file count, with the regression arm specified as a floor rather than an equality | Engineering |
| **R-6** | **`#6409`'s line citation drifts again** — it already moved once between filing and planning | High | Minor | The fix restates the citation as a content anchor (*§ 5.7, upgrade-mechanism step 2*) rather than repairing the number | Engineering |
| **R-7** | **Skill-edit discipline skipped on `#6394`** — editing a skill surface obliges a skill-editor regression pass before push | Medium | Major | A gating step in the Verification Plan. The sanctioned-session hook is **inert on these files** (conjunct 2 false), so **no hook will stop a spoke that skips this.** Conduct-enforced, which is exactly why it is written down | Engineering |
| **R-8** | **A partial delivery ships** — the milestone asserts a member set that the PR's file set does not match, with no recorded pointer | Low | Minor | CIAC-3 makes the intended set an assertion rather than an assumption, and its expected set is enumerated below | Hub |
| **R-9** | **Rollback of `#5892` is operator-only** — the control is symmetric, so no agent can revert it either | Low | Minor | Recorded in the Rollback Strategy. CHEAP — a three-hunk prose revert in one file | Operator |
| **R-10** | **A fix authors a new unqualified absolute while correcting three** | Medium | Major | CIAC-2 grades the merged diff's **added** lines for exactly this. It is this release's most specific regression exposure, and D-Replacement-Wording is one instance already caught before it landed | Engineering |

**Scope risk: none.** Composition locked with `issues_added` = 0; 4 effective points against a 15–25 band, deliberately below it after a governed split. **Capacity: NOT over-scoped.**

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential — constraint-class ordered (operator-executed → unconstrained → package-tailed). Zero dependency edges, so the ordering is a convenience rather than a constraint |
| **Commit strategy** | One commit per issue, plus Engineering Commit 0 for this plan file |
| **Review approach** | **Single PR for the entire release** (topology SINGLE) |
| **Concurrency posture** | **P0 — fully serial.** Opt-in parallelism; SINGLE maps to P0, and an undeclared posture defaults to it. With three agent-built commits, zero contention and no dependency ordering to exploit, serial dispatch costs nothing measurable and keeps the force-push prohibition moot |
| **Deployment mechanism** | Git merge + the `.skill` package rebuild committed in this PR |
| **Stacked-base cleanup posture** | N/A — enumerated over the branch topology: SINGLE, one branch off `origin/main`, no stacked bases planned |

**Topology SINGLE — grounded in this release's own contention map, not in convention.** Zero of the measured pairs are contended and there are zero in-bundle dependency edges. Per-issue branching exists to isolate collisions; there are none to isolate. It would add three branches, PRs and merge gates for zero isolation gain, and it would break CIAC-3, which is a predicate over one PR's file set. SINGLE also lets the operator's `#5892` commit and the spoke commits share one reviewable diff.

**Issue-reference discipline for the PR body.** Close-family verbs paired with an issue number belong **only** in the dedicated Issue References block. This release's members close at Stage 13 rather than on merge, so every member takes a `References` form and no close-family verb appears anywhere near a number — not in the Summary, not in a table cell, not in a checklist line. The auto-close parser is lexical: section context does not constrain it and negation does not disable it.

## Verification Plan

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #5892 | AC-1 | File-content assertion on the File Structure fence: read the `notes/` and `plans/` rows | Notes `v1/ v2/ v3/` row absent; plans row reads `v<MAJOR>/`; fence alignment preserved |
| #5892 | AC-2 | File-content read plus a citation-resolves probe on the named standard | Naming-convention sentence present; the standard cited and its path resolving |
| #5892 | AC-3 | **Claim-axis semantic sweep** (layout vocabulary ∩ artifact subject), hand-classified — **not** a token sweep, which is structurally blind to this site | Zero stale layout assertions · control: the same sweep over the pre-fix text → the three known sites, and the `_unversioned/` row fires |
| #5892 | AC-4 | The AC-3 sweep re-run with both arms declared | Zero · sensitivity fires on the `_unversioned/` row · specificity reads 0 |
| #5892 | AC-5 | `bash core/deploy/deploy.sh --check` plus the release-corpus linter, scoped to this file | Both green on this file |
| #6409 | AC-1 | **Execute** the `_prov_source_form` resolver against the value shape the corrected instruction produces. Patterns extracted from `release/tools/verify-release-plan.sh` rather than retyped; run on two independent engines (the real `grep -E` and a `python3` re-implementation) so a single-engine quirk cannot produce a plausible-wrong answer | Returns a **named** form (`A`), not `NONE` · control: the pre-fix instructed shape (`the cited source list`) returns `NONE` on both engines, so the arm demonstrably discriminates · specificity: a bare word, an untracked extension and a prose-then-path string all return `NONE` |
| #6409 | AC-2 | Probe § 5.7 for instruction-shaped provenance directives whose instructed value resolves to `NONE`; denominator is the section's line span | Zero · sensitivity: the same probe over the pre-fix section returns 1 (the step-2 instruction) · specificity: 0 outside the section's span |
| #6409 | AC-3 | File-content assertion for the instruction-vs-count shape note | Note present, in § 5.7, adjacent to the section's other cascade-visibility clause |
| #6241 | AC-1 | Read § 5.1; assert state 4 is connected to **both** genuinely-absent limbs — state 2's population floor and the workflow-trigger-configuration dependency | Both named · and the already-present gate identifier is **not** re-asserted (a second copy would fail CIAC-2) |
| #6241 | AC-2 | Diff § 5.1 against its pre-change form | Only additive prose; same number of states, same order, same predicates |
| #6394 | AC-1 (re-scoped) | Whole-file count of the universal-absence claim across **both** files, each occurrence classified in-scope or out-of-scope with a one-line reason | Every in-scope occurrence names the hook · **zero** unqualified absolutes remain · the count arm is read as a **floor**, not an equality, because the enforcement-absence claim survives the fix |
| #6394 | AC-2 | File-content read plus a hook-source citation-resolves probe | Coverage stated, shipped mode named, hook path cited and resolving |
| #6394 | (gating, not an AC) | Skill-editor regression pass over the diff **before push** | Clean; no cross-skill contract regression |
| #6394 | (gating, not an AC) | `bash core/deploy/tools/build-skill-packages.sh intake-desk`, then the freshness verdict | Package and `.sha256` rebuilt and committed in this PR; freshness verdict FRESH. Resolve the change set against the roster by piping the changed paths **on STDIN** to `--skills-for-paths` — an argv invocation returns empty for every input, which reads as "nothing to rebuild" while having measured nothing |
| — | CIAC-1 · CIAC-2 · CIAC-3 | As specified below | Graded on the merged PR at the Stage-9 release-integration check |

**AC baseline** — per-issue criterion counts as read at plan time, and the commit read against:

`ac_baseline: { #5892: 5, #6241: 2, #6394: 2, #6409: 3, read_at: a30838589583bcddf5f88183cfff1a8ea2475300 }`

**Two expected non-findings, stated once so they are not re-derived at three stages:** a `RELEASE_PROTOCOL.md` write refusal at any stage is **the control working**, not a tooling fault; and the withdrawn `#4982` remaining attached to the milestone as a closed member is the expected shape for a card withdrawn at planning, not a scaffold defect.

### Release-Level Verification

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity
- [ ] Skill Invocation
- [ ] Output Contract Compliance

### Cross-Issue Acceptance Criteria

Three cohesion constraints span two or more members. Each is graded on the **merged PR** at the Stage-9 release-integration check; none is expressible as a per-issue acceptance criterion.

| Identifier | Issues spanned | Predicate | Shared surface | Verification method |
|---|---|---|---|---|
| **CIAC-1** — every corrected surface names a live, resolvable authority | #5892 · #6241 · #6394 · #6409 | Each member's added text cites the artifact that actually owns the claim — the flat-notes standard for #5892, state 2's floor plus the readiness gate for #6241, the path-leak hook for #6394, the closed `source:` grammar and its Stage-4 owner for #6409 — and **every such citation resolves at the merge SHA** | The citation form. This release's thesis is *a governance surface names the thing that owns the claim*; a fix that introduces its own dangling pointer fails that premise | `python3 core/deploy/tools/check-doc-links.py` over the changed set, plus a per-citation existence probe for the non-link forms (a hook rule ID, a gate ID, a named grammar). Sensitivity arm: inject one fabricated citation and confirm it is flagged |
| **CIAC-2** — no edit introduces a new unqualified absolute about a mechanism | #5892 · #6394 · #6409 | The merged diff's **added** lines contain zero sentences asserting the universal presence or absence of a mechanism without naming it | The defect class all three instantiate: an over-broad absolute, or an instruction naming no concrete form. Fixing three instances while authoring a fourth is this release's most specific regression exposure — and D-Replacement-Wording is one instance already caught before it landed | The claim-axis sweep #5892 pioneered (vocabulary ∩ subject, hand-classified) over **added lines only** — not a token sweep, which is blind to a claim naming no path. Sensitivity arm: the pre-fix text of #5892's normative site must be flagged by the same sweep |
| **CIAC-3** — the delivered file set equals the set the D-verdicts imply | All four members | The merged PR's changed-file set **equals exactly** the set implied by D-5892-Delivery (option a), D-4982-Disposition (withdraw), D-6394-Scope (widen to both files) and D-Package-Rebuild (rebuild in this PR). No partial, no extra | The PR file set. One member is deliverable only by the operator, one was withdrawn, and one had its write set widened twice after planning — so *"did everything intended land"* is a release-level question no per-issue criterion can ask | `gh pr view <N> --json files`, intersect with the expected set below, assert set **equality**. Sensitivity arm: confirm the comparator flags a deliberately-omitted path |

**CIAC-3's expected file set — exactly these eight paths:**

```
release/governance/RELEASE_PROTOCOL.md
release/references/specs/release-readiness-scan-spec.md
operations/skills/intake-desk/SKILL.md
operations/skills/intake-desk/references/output-contract.md
packages/intake-desk.skill
packages/intake-desk.skill.sha256
release/references/pipeline/stage-05-solutioning.md
release/releases/plans/governance-pointer-fixes_RELEASE_PLAN.md
```

`core/standards/hub-session-continuity.md` must **NOT** appear — `#4982` was withdrawn, so that path is out of the write set entirely rather than conditionally in it.

## Rollback Strategy

**Reversibility: CHEAP · confidence HIGH.** Prose edits across five corpus files plus one tool-generated package pair: no schema change, no migration, no new executable, and no downstream consumer reading any of them programmatically except the provenance resolver — which reads a *form*, not this document.

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #5892 | `git revert <commit>` — **operator-only in both directions.** The Tier-0 control blocks the revert exactly as it blocks the edit | Low — three prose hunks, one file |
| #6409 | `git revert <commit>` | Low — one region, one file |
| #6241 | `git revert <commit>` | Low — additive prose only |
| #6394 | `git revert <commit>` **and** re-run `build-skill-packages.sh intake-desk`, or the freshness gate inverts | Medium — the package pair must be regenerated, not reverted in isolation |

Zero contention means no member's revert depends on another's — the payoff of the measured-zero contention map.

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Pre-merge** | Any blocking finding at Stage 9 | Close the PR and delete the branch; nothing has landed |
| **Partial Revert** | Isolated member failure post-merge | Revert that member's commit |
| **Full Restore** | Systemic failure | Revert the merge commit and record the rollback. **The version tag is retained, never deleted** — it is host-protected, and the claim record survives a withdrawal |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch off `main` |

No snapshot step is owed — git history is the snapshot and the PR diff is the dry-run review.

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | `operations/skills/intake-desk/SKILL.md` · `operations/skills/intake-desk/references/output-contract.md` | The installed `intake-desk` skill | S-2 direct copy at Stage 12/13 deploy | `bash core/deploy/deploy.sh --check` reports no drift for `intake-desk` |

The three governance-prose members (`#5892`, `#6241`, `#6409`) declare **no** Layer-2 propagation target — they are pipeline and governance corpus, read in place — and take `deliverable_state: artifact-accepted` accordingly. That is a first-class terminal state, not a lapsed deployment.

### Schema Migrations

**N/A — enumerated over the classes reasoned over:** frontmatter schema changes, tracker schema changes, event-log schema changes, allowlist-format changes, and package-format changes. None is present in this release.

### Quota Budget

**Verdict:** PASS
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **1** · Stage 6: **3** (dispatched serially under P0) · Stage 7: **1** · Stage 8: **1**
**Per-spoke cost estimate:** size-bucket ordinal band, **lowest** — all four members are `size:XS` at filing (source: heuristic, not telemetry; the usage-estimator medians were not consulted and the spoke-launch telemetry surface has no producer)
**Assumed/stated remaining usage-window envelope:** **`partial-N%`** — the operator stated at the Stage-4 plan gate that the five-hour window was roughly half drawn, which moves the concurrent-wave ceiling from 2 to 3
**Estimated cumulative draw % (worst parallel batch):** **not rendered.** With the envelope basis a stated band rather than a measured figure, this check synthesizes no percentage — a sourced-looking number the session could not have obtained is worse than none
**Routing:** PASS — proceed
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, at every stage — against the *remaining* envelope, and it gates a second axis these fields deliberately omit: the host-API pools, combined DEFER-dominant. A singleton is **not** exempt; the counterexample on record is a read-only singleton that died at the per-account session limit after thirty tool uses while a gated two-spoke wave completed. Bands and the cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM confidence.

## Stage Applicability Matrix

| Stage | #5892 | #6409 | #6241 | #6394 |
|---|---|---|---|---|
| **5 Solutioning** | **SKIP** | **SKIP** | **SKIP** | **REDUCE** |
| **6 Engineering** | **N/A — operator-executed** | APPLY | APPLY | APPLY |
| **7 Dev Testing** | APPLY | APPLY | APPLY | APPLY |
| **8 QA / Acceptance** | APPLY | APPLY | APPLY | APPLY |
| **9 · 12 · 13** | APPLY, release-scoped | — | — | — |
| **10–11** | compressed (git-native) | — | — | — |

**Stage 5 SKIP, argued per card.** The question is whether design uncertainty exists that Engineering would otherwise resolve ad hoc. `#5892` — the design output already existed and was verbatim-verified as applying unchanged. `#6241` — the card states the sentence's content, its insertion point, and that nothing else may change. `#6409` — the form is fixed by a closed three-form grammar, so there is exactly one conformant answer.

**`#6394` — REDUCE, not SKIP,** and it was the right call: the reduced pass widened the card's write set, re-scoped its AC-1, qualified a disputed occurrence, rejected the design's own proposed wording as a new absolute, filed a successor card for an out-of-scope causal-chain defect, and corrected the approved plan's package-rebuild risk. A SKIP would have surfaced none of it.

**Stages 7 and 8 APPLY for every member — no reduction.** Prose corrections to governance surfaces are exactly the class where *"no functional impact"* is the tempting and wrong call: `#5892`'s third site is a *normative instruction* directing a future release's action, and `#6409`'s is an *instruction* a Stage-6 spoke already had to correct mid-build once. A defect that changes what an agent does next has functional impact by definition. Every member ships its own executable probe, so both stages have real work rather than ceremony. Under SINGLE, Stages 7 and 8 run as **release-scoped singletons** — one spoke over the whole PR each — rather than per-issue waves.

## Baseline pin

`origin/main` = **`a3083858`** (`a30838589583bcddf5f88183cfff1a8ea2475300`), fetched at Stage-4 entry and unchanged at Engineering Commit 0.

Repo-wide at Commit 0: **2** open draft release PRs other than this one, **204** canonical version tags on `origin` with the frontier at `v4.60`, and this release's milestone carrying 4 open members plus its sub-tasks. This pin is re-checked at Stage-9 entry for mid-pipeline divergence.

## Operator Decisions (D-Gate Block)

### D-C — Branch Topology

**SINGLE** — one release branch, one PR, one merge gate, members as ordered commits. Grounded in the measured contention map rather than in convention: zero contended pairs and zero in-bundle dependency edges, so per-issue branching would isolate nothing while adding three branches, PRs and merge gates and breaking CIAC-3. Reversibility CHEAP · HIGH. Recurring-D: a recorded determination, ratified at the plan gate.

### D-Concurrency Posture

**P0 — fully serial.** Opt-in parallelism; an undeclared posture defaults to P0, and SINGLE maps to it. With three agent-built commits, zero contention and no dependency ordering to exploit, serial dispatch costs nothing measurable and keeps the force-push prohibition moot. CHEAP · HIGH.

### D-ReleaseClass

**`routine` — CONFIRMED** on two independently measured triggers: every change-spec file has three or more prior release touches (measured per file, with a fabricated-path specificity arm reading 0), and the matrix adds zero new corpus files (its only `add` is this plan, which is pipeline apparatus rather than corpus content).

**The honest tension, recorded rather than smoothed.** The `routine` trigger requiring *all issues P3/P4* **fails** — `#5892` is P2. And the `novel` trigger *at least one D-class decision* fires on a literal reading, since this plan renders several. That reading is rejected on the qualifier: `routine`'s own clause says *zero **new** D-class decisions*, and most entries here are recurring-D entries every plan carries. Reading the `novel` trigger literally would classify every release `novel`, which is the documented anti-pattern shape. The enum is *any one fires*, and `routine` fires on two measured triggers.

**Differentiation posture:** engagement density **Light** (routing absorbed into standing-GO, completions batched to gate boundaries; per-D-decision briefings still fire) · Stage 9 depth **Standard** · Stage 5 bias **SKIP-biased**, honored with one REDUCE carve-out · Stage 13 outcome-window **standard**. Cheaper-to-stricter is CHEAP; nothing argues for stricter.

### D-Version

**`v4.61`** — provisional, recorded as a determination rather than a question. Under ADR-092 the version binds only at the Stage-12 atomic claim, and the branch, this plan file and the milestone all stay slug-primary in flight, so nothing renames if the slot moves.

**Re-verified free at Engineering Commit 0**, because two concurrent releases recorded the same slot and a three-way race is real work rather than ceremony. The tag arm is what binds — a version is claimed the moment its release merges and pushes the signed tag, so a missing ledger row is **not** evidence of freeness, the ledger chore PR landing after the release PR it describes. The authoritative selector's own read-only path recomputes `v4.61` as next-free, `v4.61` is absent from the 204 canonical tags on `origin`, the frontier reads `v4.60` (so the sensitivity arm fires), a fabricated slot reads absent (so the specificity arm is clean), and both concurrent releases remain open drafts with nothing merged. CHEAP · HIGH — nothing is claimed by recording it.

### D-5892-Delivery — how the Tier-0 member lands

**Option (a)** — the operator commits the `#5892` edit onto the release branch before Stage 7, so one PR carries every built member.

The constraint was **cited rather than tested**: the Tier-0 hook invokes an unconditional block from a `case` matching the three governance basenames, guarded by a platform-worktree test that is a *condition to fire* rather than an exemption. Neither the planning spoke nor the hub attempted the write — attempting a refused action to observe the refusal is not a probe, and the source settles it. Consequence for the build set: Stages 7 and 8 grade a tree that contains the member, and CIAC-3 stays a set-equality over one PR's file set rather than degrading to a subset claim. **Applied** — the commit is Commit 0's parent on this branch.

Reversibility CHEAP · HIGH, with the symmetry worth naming: the control blocks the revert exactly as it blocks the edit, so rollback of this member is operator-only in both directions.

### D-4982-Disposition — withdraw and close as not-reproducible

**Withdrawn and closed**, on two independent measurements at two baselines with a firing sensitivity arm each time. See § Withdrawn member for the probe record. The nearest real surface in that file is a *seven*-field record with six unglossed fields and no contract pointer — a genuine instance of the card's stated *principle* at a different arity and the inverse shape. Pinning it would author a new requirement, which is why it belongs in a separate card if the operator wants it, not in a re-scope of this one. CHEAP · HIGH — reopenable at any time with a pinned surface.

### D-Plan-Approval

**APPROVED as planned**, carrying D-C SINGLE, release class `routine` CONFIRMED, Stage 5 SKIP ×3 plus REDUCE ×1, Stages 7 and 8 APPLY to every member with no reduction, the constraint-class implementation sequence, and CIAC-1/2/3 graded on the merged PR. Build set: four members. Reversibility MODERATE · HIGH — approval authorizes branch creation, scaffolding and spoke fan-out, all git-revertable and none public-facing until the PR opens.

### D-6394-Scope — widen to both files

`#6394`'s write set becomes **both** `operations/skills/intake-desk/SKILL.md` and `operations/skills/intake-desk/references/output-contract.md`; all four in-scope clauses are built in one Stage-6 pass. The originating finding named the mirror explicitly and the card's Affected Files field dropped it. Both files ship inside one `.skill` package, so correcting only the first leaves the shipped skill self-contradictory at the surface a Mode C run actually reads, while the milestone reads green. Widening a card's write set adds no issue, so `issues_added` remains 0. CHEAP · HIGH.

### D-741-Fence — qualify rather than adjudicate

One occurrence of the absence claim gains the scoping enumeration its three already-true neighbours carry, making it true under both readings. The design pass classified it in-scope (it restates the absolute adjectivally, as settled fact — the most quotable form); the adversarial review classified it out-of-scope (it asserts no failure-to-observe). The asymmetry that made it genuinely ambiguous is that the three true neighbours each carry an explicit scoping enumeration and this one carries the adjective bare — which is exactly what the chosen disposition removes. Routed rather than adjudicated: two composed specialists disagreeing on a domain judgment is not the orchestrator's call to settle. CHEAP · MEDIUM (the confidence is on the classification dispute, not on the remedy).

### D-CausalChain — file a successor card

A distinct defect was found and **not** folded into `#6394`: the three scoped-true sentences are *true in conclusion but state a false causal chain*, attributing the hook's non-firing to payload-detectability when the operative reason is tool-surface — the Tier-0 floor is gated on a Write/Edit tool name and a resolved target path, and the Bash arm maps no patterns, so a `gh issue create` never reaches the floor at all. It is a different defect class on a different axis, and its corpus surface is unmeasured: the sibling sweep measured the absolute class, not this one. Establishing that surface is the successor card's work, not an input to it. A pre-creation duplicate check ran first across the full open-issue population plus closed: no open owner. CHEAP · HIGH.

### D-Package-Rebuild — the rebuild lands in this pull request

**Hub-rendered determination, not a gate**, because there was no choice to render: the freshness gate is enforcing with no path filter, so a stale package is a red required check and the alternative is an unmergeable PR. This **corrects** the Stage-4 risk register and the Stage-5 note, which both recorded the rebuild as a release-cut step with an expected interim staleness reading. That was true under the prior warn-mode posture and became false when the gate graduated — six days before this release entered Stage 4. Every actor in the chain inherited the claim and restated it rather than re-measuring it; the independent reviewer, carrying no shared context, is what caught it. CHEAP · HIGH.

### D-Replacement-Wording — reject the proposed clause as authored

The design's proposed replacement was an unqualified absolute of exactly the class this release corrects, and it would fail the release's own CIAC-2. The correct form states what the hook does **where its wiring is loaded**, names its shipped mode, and says plainly that an un-rehomed instance does not load it at all — the loading condition fails for any session rooted in the repo or a worktree, and the hook's own header says so ten lines below the line the design cited. Recorded rather than gated: CIAC-2 already forbids the unqualified form, and the wording is Engineering's to author. CHEAP · HIGH.

## Domain Practice Provenance

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-10, domain: governance }`

**Form X — EXEMPT**, verbatim. Classified from the File Change Matrix: every row is an internal pmo-platform artifact, so the release is sourcing-exempt from the external-sourcing step. Sourcing-exempt is **not** domain-less — the `domain:` class is `governance` because five of the seven edited paths are governance and pipeline prose; the two `intake-desk` files are edited as *prose about a control* rather than as behavior, so they do not pull the dominant class toward `software`, and the two package paths are tool-generated projections of them. No secondary domain.

## Deviation Log

| # | Deviation | Class | Basis | Recorded by |
|---|---|---|---|---|
| 1 | `core/standards/hub-session-continuity.md` — the Stage-4 comment's `CONDITIONAL:4982-pinned` row is **removed**, not carried forward as a conditional | Scope reduction | D-4982-Disposition withdrew `#4982`; a row left CONDITIONAL after its condition has resolved is indistinguishable from one whose condition never fired | Commit 0 |
| 2 | `operations/skills/intake-desk/references/output-contract.md` — **added** to the matrix as an unconditional `edit` | Scope widening | D-6394-Scope | Commit 0 |
| 3 | `packages/intake-desk.skill` and its `.sha256` — moved from `NOT EDITED` to unconditional `edit`, in **this** PR rather than at release-cut | Correction of the approved plan | D-Package-Rebuild; the freshness gate graduated to enforcing before this release entered Stage 4 | Commit 0 |
| 4 | Risk R-3 — **inverted**: a stale package was recorded as expected-and-not-a-defect; it is now a red required check | Correction of the approved plan | D-Package-Rebuild | Commit 0 |
| 5 | `#6409`'s citation restated as a content anchor (*§ 5.7, upgrade-mechanism step 2*) rather than as a repaired line number | Tier 1 [ADJUST] | The number had already drifted once between filing and planning; a content anchor cannot drift | Commit 0 |
| 6 | `#6241`'s delta narrowed — the already-present gate identifier must **not** be re-asserted | Tier 1 [ADJUST] | Hub re-read of § 5.1 at the plan gate; a second copy of an existing claim would fail CIAC-2 | Commit 0 |
| 7 | `#6394`'s AC-1 re-scoped from two named sentences to every occurrence across both files | Tier 1 [ADJUST] | Whole-file sweep returned six occurrences across at least three sites | Commit 0 |
| 8 | The `#6394` verification detector was committed at `operations/skills/intake-desk/evals/detect-hook-absolute.py`, then **removed from the tree in the same PR** | Tier 1 [ADJUST] | Committing it made the delivered set **nine** paths where CIAC-3 requires exactly the eight its expected-set block enumerates. Widening that predicate is a recorded hub determination — it was for D-Package-Rebuild — so the spoke held the predicate instead. The blob stays reachable at `cd8cec21`, so the detector is recoverable byte-for-byte and reproducibility is not reduced | `#6394` Stage-6 spoke |
| 9 | `#6394`'s three fenced scoped-true sentences addressed by **verbatim anchor**, edits applied **bottom-up**, rather than by the design's line numbers | Tier 1 [ADJUST] | The design's own first edit invalidates its later line addresses, and one prescribed range (`output-contract.md` L119–121) enclosed a scoped-true clause it meant to preserve. Anchor-addressing plus bottom-up ordering removes the coordinate-frame drift | `#6394` Stage-6 spoke |

## Verification Evidence

(Stage 6 self-verification below; Stage 12 execution evidence appended at deploy.)

### Stage 6 — `#6394` (Engineering spoke, sub-task `#7352`)

Every claim below carries its probe. The local `grep` is `ugrep` and returns a
plausible zero on a pattern it rejects, so every load-bearing detector is
`python3 re`, and every zero is paired with a control arm observed non-zero in the
same run.

**The detector.** Sentence-scoped, re-derived from the Stage-5 D1 record: newlines
collapsed to spaces *before* sentence splitting, because every in-scope claim wraps
across a line break (a line-scoped probe for the card's own quoted phrase returns
0). Three arms: `observ` (the false class — an unqualified claim that a control does
not observe the create), `enforce` (the true class — no mechanical enforcement behind
the Tier-0 floor), `fence` (the scoped-true sentences that must not be edited).
Recoverable byte-for-byte at
`git show cd8cec21:operations/skills/intake-desk/evals/detect-hook-absolute.py`;
`--self-test` reproduces 5/5 sensitivity and 7/7 specificity.

| Check | Probe | Result |
|---|---|---|
| AC-1 — zero unqualified absolutes, both files | `observ` arm over each file | **PRE 4 → POST 0** (SKILL.md 3→0, output-contract.md 1→0). Sensitivity arm observed **5/5** in the same run, so the zero is evidence rather than a silent miss |
| AC-1 — the three scoped-true sentences survive | content-hash identity of each fenced line, matched by hash rather than line number | **5/5 BYTE-IDENTICAL** — SKILL.md L224 (unmoved), L481→L494, L735→L748; output-contract.md L118 + L119 (unmoved). The L735 case is the clause-surgical one: it shares a sentence with an edited clause |
| AC-1 — the fence was not miscounted | `fence` arm, tolerant of both an intervening determiner (*only **the** payload-detectable*) and markdown emphasis markers | **3 in SKILL.md** — independently confirming the fence is 3, not the 2 a literal matcher reports. The arm initially read 2/3 against its own fixture; that was a probe defect, fixed before use |
| AC-2 — coverage stated with its mode, hook cited | read of § *Honest safety read* | `core/hooks/block-gh-path-leak.sh` named, its `gh (issue|pr) (create|edit|comment)` match and body read stated, shipped mode **`warn`** named, and its four-condition coverage boundary stated — it is not active at any mode on an instance whose PreToolUse wiring has not been re-homed |
| AC-2 — the enforcement hook is named | same read | `core/hooks/block-autonomy-ceiling.sh` named at all four corrected sites' governing section; stated **once** at the normative site, cited (not restated) at the other three |
| Operative conclusion preserved | `enforce` arm, specified as a **floor**, never an equality | **8 → 8** (SKILL.md 6, output-contract.md 2). An equality arm over prose this build rewrites would fail a correct build; the floor is ≥1 per file plus the verbatim conclusion present |
| Containment corpus-wide | `observ` arm over **1,378** tracked `*.md` (`git ls-files '*.md'`) | **0 hits inside the `intake-desk` skill.** 5 residual hits hand-classified: 2 are the corrective record quoting the false sentence in order to correct it (ADR-162, the `declarations-have-a-firing-surface` plan's F-2 row) and must not be "fixed"; 3 are true or unrelated (ADR-031's *remaining* irreducible classes, an ADR-112 options row, a terminal v4.18 risk row) |
| CIAC-2 — no new unqualified absolute in added lines | `observ` arm over this spoke's **added** lines, with the **removed** lines as control | added **0** / removed **3 [FIRES]** → PASS. The control is what makes the 0 meaningful |
| CIAC-3 — delivered set equals the expected eight | `git diff --name-only origin/main...HEAD` | **exactly 8**, path-for-path. See the Deviation Log row this spoke added — the detector was removed from the tree to hold this predicate |
| Package rebuilt and fresh | `core/deploy/tools/build-skill-packages.sh intake-desk`, then `deploy.sh --check-package-freshness` | STALE (1, `intake-desk`) **→ 55 rostered packages content-fresh — OK** |
| Package embeds the corrected text | unzip the rebuilt archive; run all three arms against the **embedded** copies, not the source | `observ` **0/0** · `fence` **3/1** · `enforce` **6/2** · both embedded files **byte-identical to source** · token count **6→4** and **2→1**. This is the check a source-only sweep cannot make |
| Doc-link integrity | `check-doc-links.py --require-targets` over both files, plus its own `--self-test` | self-test **OK (11 fixtures)**; **0** broken refs, exit 0. `--require-targets` means the globs resolved to real files rather than reading green on an empty scan |
| Skill-editor discipline | `pmo-skill-editor` Mode C (Regression) | GR-01..GR-07 and XC-01..XC-08 run; **no regression**. Category-7 RCP predicates **out of scope by the trigger table** — it is keyed on the edited file and names neither of these two. Conduct-enforced: `block-skill-direct-edit.sh` is inert here (no `skill_discipline_migrated_v10_2` key) |
| Cross-skill contract surface | `core/skills/registry.md` | 3 consumers (`pmo-tier-1-support`, `pmo-wms-specialist` DEPENDS_ON; `pipeline-triage`, `roadmap-curator` RELATES_TO). **No contract surface touched** — no section heading, mode definition, output-contract structure, tag taxonomy, RAID prefix or field set changed; the edit is prose internal to two sections |
| Pre-packaging | frontmatter inspection | `description` **1005** chars (limit 1024) — PASS, unchanged; frontmatter keys unchanged |
| ADR index freshness | — | **N/A — this release adds no record under `release/ADRs/`.** The honest no-op, recorded rather than silent |
| Runtime suite | `runtime-suite-selection-map.md` | **`test-run/suite-skip`** — doc/governance-only change matches the map's explicit no-match row |

## Deployment Execution Log

(Populated during Stage 12.)

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

(Authored at PR-creation time; refreshed by the last Stage-6 spoke if Tier 1 [ADJUST] commits change which members land or which decisions stand.)

### Outcome

Four governance surfaces stop asserting things about mechanisms they do not own. Each one now names the owner or the live mechanism instead: a release-protocol layout instruction cites the standard that superseded it rather than directing a future release to do the forbidden thing; a readiness-scan state records the safety basis its clean verdict rests on; an intake skill names the hook that actually matches `gh issue create` instead of claiming none does; and a pipeline instruction names the provenance form its own resolver recognises instead of a prose phrase the resolver reads as nothing at all. At Stage 9 the operator reviews one PR carrying all four, plus the rebuilt skill package the last of them requires.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #5892 | The protocol's layout rows and its normative sentence describe the flat-notes reality and cite the standard that governs it | DONE |
| #6409 | § 5.7's upgrade-mechanism step names a provenance form the resolver resolves, and records why a count-shaped cascade could not see the section | DONE |
| #6241 | § 5.1 state 4 records its safety basis, additively, with every predicate unchanged | PENDING — its own Stage-6 spoke |
| #6394 | Every occurrence of the no-hook-sees-it claim, across both skill files, names the hook and its shipped mode; the package is rebuilt in this PR | DONE |

### Key decisions

- **D-C:** SINGLE topology. Zero contended pairs and zero dependency edges, so per-issue branching would isolate nothing.
- **D-5892-Delivery:** option (a) — the operator commits the Tier-0-floored member onto this branch, so Stages 7 and 8 grade a complete tree.
- **D-4982-Disposition:** withdraw and close as not-reproducible, on two measurements at two baselines.
- **D-6394-Scope:** widen to both skill files — the mirror ships inside the same package.
- **D-Package-Rebuild:** the `.skill` rebuild lands in this PR, correcting the approved plan; the freshness gate is enforcing with no path filter.
- **D-Replacement-Wording:** the design's proposed clause is rejected as a new unqualified absolute of the class this release corrects.

### Reversibility

**CHEAP — HIGH confidence.** `git revert <commit>` per member, or revert the merge commit for the whole release; `#6394`'s revert additionally requires regenerating the package pair. `#5892`'s revert is operator-only in both directions, because the Tier-0 control is symmetric.

### Downstream impact

- The Stage-5 § 5.7 correction removes a mid-build correction a Stage-6 spoke has already had to make once, so the next release upgrading a provenance label follows an instruction that works.
- The successor card filed under D-CausalChain carries the false-causal-chain defect forward on its own axis, with its own unmeasured corpus surface to establish.
- The `intake-desk` package rebuild is the only Layer-2 propagation this release carries; the three prose members declare none and take `artifact-accepted`.

### Cross-references

- Release plan: this file
- Milestone: `governance-pointer-fixes`
- User-facing release notes: authored at Stage 13 Close per [`release/references/standards/release-notes-standard.md`](/release/references/standards/release-notes-standard.md)

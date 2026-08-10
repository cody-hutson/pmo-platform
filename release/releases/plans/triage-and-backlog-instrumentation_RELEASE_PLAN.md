<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — triage-and-backlog-instrumentation

> **Milestone:** `triage-and-backlog-instrumentation` (325) · **Release Class:** `novel` (Standard engagement / **Deep** Stage-9 review / Stage-5 ALL / 30-day outcome window) · **Version:** `{{RELEASE_VERSION}}` — **unbound; binds only at the Stage-12 atomic claim (ADR-092)** · **Scope:** 7 issues, indexed below · **Topology:** D-C `SINGLE` · **Concurrency posture:** P0 fully-serial · One release branch, one PR, one merge gate · **Branch:** `release/triage-and-backlog-instrumentation` (slug-primary, no version stem).

This file is the Stage-4 release plan, committed as **Engineering Commit 0** on the release branch per the D-C SINGLE topology. It is reconciled with every decision rendered since that plan was written — the Stage-4 operator gate, the six Stage-5 design specs, and the Stage-5 decision records. Superseded Stage-4 statements are marked where they land rather than silently overwritten, so the record shows what moved and why.

## Issue References

Card index for this release. Every issue reference in this plan resolves against this table.

| Card | Size | One-line scope |
|---|---|---|
| #4463 | `size:M` | Lint-card AC sets gain a precision obligation — a named near-miss the check must not flag, at each narrowing invocation parameter |
| #4891 | `size:M` | The deploy-tools README states its coverage rule and backfills the residual undocumented tools |
| #4708 | `size:S` | The skill-package-freshness path filter widens to the three canonical template-sync trees; absent-is-pass corrected |
| #4899 | `size:S` | A detection leg that catches stage sub-tasks left invisible to milestone-scoped queries |
| #4926 | `size:S` | The initiative-is-not-an-epic rule becomes an enforceable assertion with a lint keyed on the label-family shape |
| #4901 | `size:M` | The issue-reference gate's inline logic is extracted to an invocable checker with a fixture suite |
| #4462 | `size:M` | A blast-radius disposition is recorded rather than deferred a fifth time — operator decision, no code surface |

## Release Identity — slug-primary, version unbound

The plan file, the branch, and all hub state are keyed on the milestone **slug**, never a version. This file carries the literal token `{{RELEASE_VERSION}}` and **no baked version number anywhere**, per ADR-092: the version binds only at the Stage-12 atomic compare-and-swap, where git's ref CAS is the authority.

**This is not ceremony on this release — the slot has already moved three times under it.** The Stage-4 D-Version determination named a specific minor slot, derived by a clean three-arm freeness probe (tags 0 / ledger 0 / published Releases 0) with sensitivity proven on two known-claimed versions and a fabricated control returning FREE. That determination is **dead**: three consecutive candidate slots were claimed by sibling releases while this release sat in Stages 4 and 5. **Nothing in this release baked a number, so the loss cost exactly nothing** — no file edit, no rename, no citation repair. The determination is retained as the record of a sound derivation against a moving population, not as a live claim.

| Rung | Obligation |
|---|---|
| Engineering Commit 0 (this file) | Carry `{{RELEASE_VERSION}}`; bake nothing. **Discharged.** |
| Stage 9 | Advisory version-freeness re-check; still non-binding |
| Stage 12 pre-merge | Freeness re-check across all three arms |
| Stage 12 atomic claim | **The only binding moment.** Re-derive next-free; the git ref CAS is the authority |

## Reconciliation — what moved after the Stage-4 plan

| # | Section | Stage-4 statement | Reconciled statement | Basis |
|---|---|---|---|---|
| 1 | Release Class | Declared `routine`; spoke recommended `novel` | **`novel`** — rendered at the Stage-4 operator gate. `effective_pts = round_half_up(22 × 1.15) = 25` ≤ 25 → **G3-15 PASS at the ceiling, zero headroom.** Any scope addition from here breaks the 15–25 band | Stage-4 gate decision ① |
| 2 | Scope of the sub-task-visibility card | One card; population re-measured 14 → 278 | **Split.** The detection leg stays in this release at `size:S`; the 278-issue backfill left the release as its own work item. Raw scope stays 22 pts | Stage-4 gate decision ②, Tier 2 |
| 3 | Scope of the README-coverage card | AC-1 read "add the Check 56 row" | **Re-scoped** — that row already landed in an earlier release. AC-1 re-baselined from *add* to *verify*; the real scope is the coverage rule plus the residual 20-tool backfill. Card stays `size:M` | Stage-4 gate decision ③, Tier 1 |
| 4 | Routing of the blast-radius card | Routed to a Stage-5 design spoke | **Phase-B D-Gate** `D-BlastRadiusDisposition`. **Stages 5 and 7 are skipped** — it asks for an operator disposition, not a design, and has no functional change to test | Stage-4 gate decision ④ |
| 5 | Implementation sequence | The two trailing cards were ordered the other way | The lint card moves ahead of the gate-extraction card so the allowlist edit lands once and the gate-extraction card stays last behind its re-baseline trigger. Full order below | Stage-4 plan, § Implementation Sequence |
| 6 | File set for the precision card | 2 files (the intake form and the gate schema) | **3 files** — `release/references/how-to/intake-style-guide.md` added. **Compelled, not discretionary**: `gate-criteria-spec.md:232` registers a prose exemption whose stated consideration is *"an edit to any doctrine line above must land on both surfaces in the same change"* | Stage-5 design spec, D-4 · hub-verified verbatim |
| 7 | What the precision arm binds to | "each scope the ACs themselves reference" | **The check's own declared invocation surface** — each parameter that narrows the examined population or changes the comparison set. The card's own formulation is self-referential and vacuous against its motivating defect | Stage-5 design spec, D-2 |
| 8 | Enforcement surface for the tiering lint | `[ASSUMPTION – CONFIRM]`; Stage-4 guessed a new **Check 69** slot | **Extends the existing Check 55** (work-hierarchy drift) rather than claiming a new slot. No new check number is taken by this release | Stage-5 design spec for that card |
| 9 | Enforcement surface for the detection leg | New leg plus a README row | **Extends the existing Check 56** (milestone↔epic membership). No new check number | Stage-5 design spec for that card |
| 10 | ADRs | None allocated | **ADR-131** and **ADR-132** allocated, 133 free. Re-derived against `origin/main` at Commit 0 — see § ADR Allocation | Stage-5 design spec D-5 + hub cross-spoke resolution |
| 11 | Cross-release serialization | A sibling release PR held the workflow file the gate-extraction card must edit | **That sibling PR has merged and the serialization point has cleared.** The gate-extraction card stays sequenced last and **must re-baseline and re-run its fixture suite against the post-merge inline behavior** before extracting | Stage-5 design spec § out-of-scope drift; baseline-pinned, re-check at that card's chip |

**One known-stale figure is recorded rather than silently corrected.** The milestone's Outcome Statement BEFORE clause reads *"14 sub-tasks are invisible to milestone-scoped queries"*. The measured population is **278** (7 open / 271 closed; sensitivity arm 3,092, control 0). Correcting the milestone description was not in the Stage-4 enumerated authorization, so the hub surfaced it rather than editing it, and it remains the operator's call. This plan states the accurate figure wherever the population is load-bearing; the milestone text is unamended.

## Release Outcome Statement

**AFTER** — Backlog instrumentation is queryable, and lint cards can express precision as well as capability.

**BEFORE** — Blast radius carries inherited-unverified across four stages, lint-card ACs cannot express "and it does not flag correct content", stage sub-tasks are invisible to milestone-scoped queries, and the initiative-is-not-an-epic rule has no lint.

**Success Indicator:** every ticket is verified against its acceptance criteria, and the gate or check each one names demonstrates a real failure on a fixture before it is trusted.

---

## Implementation Sequence

Dependency-ordered. This deviates from the milestone description's declared internal sequence, which was a filing-order listing rather than a dependency order.

| # | Card | Why here |
|---|---|---|
| 1 | **#4463** | Authors the precision obligation. Landing it first means the three check-shipping cards in *this same release* are authored against the new shape — the release becomes its own first test of the obligation, and the card's own retrospective AC is discharged with live evidence rather than against closed ancestors |
| 2 | **#4891** | Establishes the `core/deploy/tools/README.md` **coverage rule** and backfills the residual tools. Every later card that adds a tool then *appends under an established rule* instead of racing to define one. This is what defuses the four-way contention |
| 3 | **#4708** | Fully disjoint file surface. No contention in-bundle or in-flight. Placed early to bank a clean merge |
| 4 | **#4899** | Detection leg extending Check 56 plus a README append. Lands after the coverage rule. The 278-issue backfill is out of this release |
| 5 | **#4926** | Taxonomy assertion, the lint, the Check 55 extension, and a README append. After the coverage rule; **before** the gate-extraction card so the allowlist edit lands once |
| 6 | **#4901** | **Last of the code cards, deliberately.** It mutates a required status check protecting `main`. Going last minimises the window in which the branch holds an unmerged edit to that gate. Its sibling collision has since cleared — it must re-baseline against post-merge inline behavior before extracting |
| — | **#4462** | **No code surface.** Rendered as its own operator decision at the Phase-B D-Gate `D-BlastRadiusDisposition`; records into the residual log of an earlier release plan |

**Raw scope: 22 pts** · `class_weight` **1.15** (`novel`) · **`effective_pts` 25** ≤ 25 — **at the ceiling, zero headroom.**

## Stage Applicability Matrix

| Issue | S5 | S6 | S7 | S8 | S9 | S12 | S13 |
|---|---|---|---|---|---|---|---|
| #4462 | **SKIP** — operator disposition, not a design; routed to the D-Gate | APPLY | **SKIP** — no functional change to test | APPLY | APPLY | APPLY | APPLY |
| #4463 | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| #4708 | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| #4891 | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| #4899 | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| #4901 | APPLY (**mandatory**) — mutates a required status check | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |
| #4926 | APPLY (**mandatory**) — its own deferred design decision resolves here | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY |

**Stages skipped: 2** — the blast-radius card at Stage 5 and Stage 7. Stages 10 (Dry Run) and 11 (Snapshot) are **N/A for the Claude Code path**: PR review *is* the dry run and git history *is* the snapshot.

## File Change Matrix

Consolidated from the six Stage-5 design specs. **16 distinct paths.**

| Issue | Path | Intent |
|---|---|---|
| #4462 | `release/releases/plans/corpus-integrity-lints-and-refs_RELEASE_PLAN.md` | MODIFY — the residual log reflects the disposition rendered at the D-Gate |
| #4463 | `core/schemas/gate-criteria-spec.md` | MODIFY — conditional conformance test `U5` plus one anti-pattern in § Capability-Class Usability-AC Requirement; the G1-05b self-repair row extended; schema version bumped |
| #4463 | `release/references/how-to/intake-style-guide.md` | MODIFY — mirror `U5` and the anti-pattern into §4b (**compelled by the registered prose exemption**); add a check-shaped worked example |
| #4463 | `.github/ISSUE_TEMPLATE/improvement.yml` | MODIFY — one-line pointer on the AC field description. **Pointer only, no doctrine** — it does not join the co-edit set |
| #4708 | `.github/workflows/skill-package-freshness.yml` | MODIFY — widen `paths:` to **3** canonical trees; correct absent-is-pass |
| #4708 | `core/deploy/lib-template-sync-source.sh` | MODIFY — expose the canonical source-tree set so the filter derives rather than restates |
| #4891 | `core/deploy/tools/README.md` | MODIFY — state the coverage rule; backfill the residual tools; re-baseline the count with its measurement date |
| #4899 | `core/deploy/tools/check-milestone-epic-membership.py` | MODIFY — the milestone-less stage-sub-task detection leg |
| #4899 | `core/deploy/deploy.sh` | MODIFY — **Check 56 region only** (lines 9609–9769). No new check number |
| #4901 | `.github/workflows/repo-integrity.yml` | MODIFY — the gate job invokes the checker; no residual detection logic left inline |
| #4901 | `core/deploy/tools/check-issue-ref-validity.sh` | **ADD** — extracted invocable checker |
| #4901 | `core/deploy/tools/fixtures/issue-ref/` | **ADD** — fixture suite (reference blocks, inline provenance, fences, overrides, exemptions, legacy identifiers, unresolvable references) |
| #4901 | `core/config/allowlists/script-execution-allowlist.txt` | MODIFY — **companion obligation**, four invocation-form rows for the added `.sh` |
| #4926 | `core/specs/label-taxonomy.md` | MODIFY — initiative-is-not-an-epic as an enforceable assertion naming the label-family signal |
| #4926 | `core/deploy/tools/check-initiative-tiering.py` | **ADD** — the lint |
| #4926 | `core/deploy/deploy.sh` | MODIFY — **Check 55 region only** (lines 9534–9608). No new check number |
| — | `release/releases/plans/triage-and-backlog-instrumentation_RELEASE_PLAN.md` | This file — Engineering Commit 0, then accreted through the release |

Machine-readable path list for deterministic Stage 7 / 8 / 9 chip extraction — **16 paths, one per line**:

```
.github/ISSUE_TEMPLATE/improvement.yml
.github/workflows/repo-integrity.yml
.github/workflows/skill-package-freshness.yml
core/config/allowlists/script-execution-allowlist.txt
core/deploy/deploy.sh
core/deploy/lib-template-sync-source.sh
core/deploy/tools/README.md
core/deploy/tools/check-initiative-tiering.py
core/deploy/tools/check-issue-ref-validity.sh
core/deploy/tools/check-milestone-epic-membership.py
core/deploy/tools/fixtures/issue-ref/
core/schemas/gate-criteria-spec.md
core/specs/label-taxonomy.md
release/references/how-to/intake-style-guide.md
release/releases/plans/corpus-integrity-lints-and-refs_RELEASE_PLAN.md
release/releases/plans/triage-and-backlog-instrumentation_RELEASE_PLAN.md
```

**Two ADR records are additional new files and are enumerated in § ADR Allocation below, not in the list above** — the list is the change-surface extraction contract for the cards' own edits, and an ADR record is a decision artifact keyed to its card. Stated explicitly so the omission reads as a boundary, not a miss.

**New-executable companion obligation.** The matrix carries one `ADD` row for a tracked `*.sh` (`core/deploy/tools/check-issue-ref-validity.sh`) and therefore carries its `script-execution-allowlist.txt` companion row. The convention is **four rows per script** (`[PMO_PLATFORM_ROOT]/…`, `[PMO_PLATFORM_ROOT]/.claude/worktrees/*/…`, `./…`, bare). The tiering lint is authored as `.py` and carries **no** allowlist obligation.

## Contention Map

### Within-release

| File | Claimed by | Class | Resolution |
|---|---|---|---|
| `core/deploy/tools/README.md` | **#4891, #4899, #4901, #4926** (4-way) | append-pattern after the coverage rule lands | **The README card is sequenced second and defines the coverage rule the other three append under.** That converts three would-be conflicting edits into three appends. Under D-C SINGLE they still serialize at push, but the *semantic* conflict is gone. This is the load-bearing sequencing decision in the plan |
| `core/deploy/deploy.sh` | **#4899, #4926** (2-way) | **non-overlapping regions** | The detection leg edits the **Check 56** region (9609–9769); the tiering lint edits the **Check 55** region (9534–9608). Disjoint line ranges in a 12,606-line file, and neither card takes a new check number. Sequence per the implementation order; a textual conflict is not expected, and a *reported* one is the signal that a region boundary moved — not a routine resolve |
| `core/config/allowlists/script-execution-allowlist.txt` | **#4901** only | append-pattern | Single edit — the tiering lint stayed `.py`, so the two-way contention the Stage-4 plan anticipated did not materialize |

### Cross-release

The Stage-4 plan recorded a **hard serialization point**: an in-flight sibling release PR edited `.github/workflows/repo-integrity.yml`, the same file the gate-extraction card must edit. **That PR has merged and the serialization point has cleared.** The consequence is not "no action" but a re-baseline: the card must re-run its fixture suite against the **post-merge inline behavior** before extracting, because a byte-identical-verdict assertion is meaningless against a superseded baseline.

**Audit-baseline discipline:** the open-PR population read **0** at Stage-5 entry, pinned to `origin/main`. A transiently-empty population is not a durable finding. **Re-check the population before the gate-extraction card's Engineering chip launches.**

The sibling milestone `corpus-tolerance-and-hygiene` remains **adjacent, not overlapping** — a coordination note, not a card move. Its AC-presence check and this release's precision obligation are both AC-quality work on different files. If that check later graduates to grading AC *shape*, `U5` is its natural rule source.

## ADR Allocation

Re-derived against `origin/main` at Commit 0 — **not** against the worktree. `check-adr-numbers.py` reads the worktree and will PASS on a number already taken upstream, so it is not a safe allocator here.

**Measurement:** `git ls-tree -r --name-only origin/main core/ADRs/ release/ADRs/` → **130** records across both directories, max **ADR-130**, contiguous through the tail. Fabricated control `ADR-999` → **0**.

| ADR | Card | Home | Subject |
|---|---|---|---|
| **ADR-131** | #4463 | `release/ADRs/` | The precision obligation binds to the check's declared parameter surface, not to the ACs' self-reported scopes. A release-pipeline gate decision |
| **ADR-132** | #4926 | `core/ADRs/` | The enforcement-surface decision the tiering card deferred at Stage 4 and resolved at Stage 5 |
| 133 | — | — | Free |

**Numbering is global across BOTH directories in one sequence.** A cross-spoke conflict was resolved at Stage 5: the freshness card independently recorded 131 for a follow-up that does **not** author in-release. Since the precision card authors here, **131 is that card's**, and the follow-up re-derives at its own authoring time and must not carry a baked 131.

## Risk Register

| ID | Risk | Class | Owner | Mitigation | Reversibility / Confidence |
|---|---|---|---|---|---|
| R1 | **The gate-extraction card mutates a required status check protecting `main`.** A regression silently weakens the gate — and a weakened gate fails *open*, so nothing surfaces it | Rollback complexity | Stage 6 | Land fixtures against the **current inline** behavior first, then extract, then assert **byte-identical** verdicts across the suite with a must-fail control. Do not merge the extraction and the fixtures in one commit | MODERATE / HIGH |
| R2 | **The re-baseline is skipped.** The sibling PR merged after those fixtures were designed; a suite run against the superseded inline behavior proves nothing | Contention | Stage 6 | Re-check the open-PR population at chip entry; re-baseline the branch; re-run the suite against post-merge behavior *before* extracting | CHEAP / HIGH |
| R3 | **The precision obligation becomes vacuous boilerplate** — the card names this itself: *"a vacuously-satisfied precision criterion is worse than none, because it looks like coverage"* | Design | Stage 6 → Stage 8 | Scope the clause to mechanical-check cards by an **inherited** predicate (C1 ∧ C2 ∧ C3), not an invented one; require a *named* near-miss; ship the anti-pattern that makes it falsifiable; validate against this release's own three check cards (CIAC-2) with a negative control | CHEAP / MEDIUM |
| R4 | **The two-surface edit lands one-sided.** `U5` rides a registered prose exemption with **no mechanical drift detection** — nothing fails when the copies diverge | Governance | Stage 6 → Stage 7 | Both files edited in the **same commit**. Stage 7 owes a byte-comparison of the mirrored doctrine region. A follow-up parity check is named as the debt-retirement lever, not built here | CHEAP / HIGH |
| R5 | **`core/deploy/deploy.sh` is high-traffic** (213 prior touches, 12,606 lines) and is edited by two cards here plus concurrent siblings | Contention | Stage 6 | Disjoint regions declared with line ranges; neither card takes a new check number. Coordinate slot allocation with the sibling milestone before either wires anything new | CHEAP / MEDIUM |
| R6 | **Zero headroom on the size band.** `effective_pts` = 25 of 25 | Scope | Hub | **Any scope addition breaks the band.** A Tier 2 [SCOPE CHANGE] on any card requires an explicit re-plan, not absorption | CHEAP / HIGH |
| R7 | **The version slot moves again.** Three slots were lost during Stages 4 and 5 | Governance | Stage 12 | Structurally mitigated — nothing is baked. Re-derive at the Stage-12 atomic claim; the git ref CAS is the authority | CHEAP / HIGH |
| R8 | **The Stage-8 batch is N=7 against an UNSTATED usage envelope** | Capacity | Hub | Split the Stage-8 batch 4 + 3 rather than launching seven concurrent spokes. The hub's per-launch checkpoint is the load-bearing gate; the Stage-4 pre-check estimate is advisory | CHEAP / MEDIUM |
| R9 | **The reference-durability hook blocks edits to this plan file and to in-scope corpus files that carry issue references.** Discovered at Engineering Commit 0 — see § Engineering Notes | Tooling | Hub | This file carries a designated `## Issue References` block so its references are in-block and self-describing. Following spokes must do the same on in-scope paths | CHEAP / HIGH |

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#4891 × #4899 × #4901 × #4926 on `core/deploy/tools/README.md`):** after all four land, **every** `.py`/`.sh` in `core/deploy/tools/` is named in `README.md` — including the tools this release adds — and the README states the coverage rule that makes the file exhaustive, with its measurement baseline date. *Method:* enumerate `.py`/`.sh` on the merged head, assert each basename appears; assert the rule text is present. *Control:* a fabricated basename must be absent. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#4463 × #4708 × #4901 × #4926):** the precision obligation authored by the first card is **satisfied by this release's own three check-shipping cards** — each names a concrete near-miss input and an expected zero, exercised at each declared invocation parameter that narrows the examined population or changes the comparison set. *Method:* read the three cards' final AC sets plus their Stage-8 per-criterion verdicts. *Control:* **#4462 must NOT carry one** — it ships no check and is correctly exempt (E5, spike/decision-record). A precision criterion appearing there is the signal that the obligation leaked into universal boilerplate, which is exactly what the card's own AC-2 forbids. *Graded at Stage 9 QC3.5.*
- [ ] **CIAC-3 (#4901 on `core/config/allowlists/script-execution-allowlist.txt`):** every tracked `*.sh` this release adds under `core/deploy/tools/` carries **all four** invocation-form rows. *Method:* for each added `.sh`, grep the four forms; assert count = 4. *Control:* a fabricated script path yields 0. *Graded at Stage 9 QC3.5.*
- [ ] **CIAC-4 (#4899 × #4926 on `deploy.sh --check`):** both extended check legs are reachable from `deploy.sh --check` and each **fails on a purpose-built fixture** and **passes on a conformant control** — the conjunction, never one arm. *Method:* run `deploy.sh --check` against both fixtures and both controls. *Graded at Stage 9 QC3.5.*

**Integration ACs (`INT-N`) — the upstream half of the precision-obligation contract**, pre-authored so the downstream spokes adopt them verbatim. This is what makes the release its own first test of the obligation.

| ID | Owed by | Upstream | Shared surface | Assertion |
|---|---|---|---|---|
| **INT-1** | #4708 | #4463 | `U5` × the workflow's `paths:` filter | Does the final AC set carry a discrimination arm naming a concrete near-miss — a PR touching a tree the filter must **not** trigger on — with an expected zero, exercised at the path-filter scope? Its AC-2 today names only the sensitivity arm |
| **INT-2** | #4901 | #4463 | `U5` × the extracted checker's fixture suite | Does the final AC set assert that the must-not-flag fixture classes — overrides, exemptions, fenced blocks, inline provenance — return **zero**, at each invocation form (CI job and direct local invocation)? Its current must-fail control is a sensitivity control on the comparison, not a specificity arm on the checker |
| **INT-3** | #4926 | #4463 | `U5` × the tiering lint | Does the AC set retain its named near-miss (*"does not flag a genuine leaf epic"*) **and** state the expected zero explicitly, at each scope the lint accepts? **This card already substantially conforms — it is the positive control** proving the shape is authorable without added ceremony |

## Verification Plan

| Issue | Verification method | Expected result |
|---|---|---|
| #4462 | file-content assertion on the disposition record and the residual-log entry | Exactly one disposition recorded with a date, a reversibility tier, and (if accepted-residual) a named bound, falsifying signal, and reopen trigger |
| #4463 | file-content assertion on all three files; **mirror-parity diff** of the doctrine region across the exemption pair; cascade-closure grep; **plus** the CIAC-2 self-application check | `U5` present on both doctrine surfaces (control: a fabricated test ID returns 0 on both); mirrored rows byte-identical; `all four` and `Four conformance` return **0** post-change (sensitivity: 2 pre-change); the Check 22 verdict set byte-unchanged |
| #4708 | re-run the structural `paths:` probe on the merged head; derive the tree set from the template-sync map and diff | Difference **empty** across all **3** trees; a skipped job no longer reports satisfied; the staling shape reproduced by a regression fixture and detected |
| #4891 | enumerate `.py`/`.sh` in `core/deploy/tools/`, assert each named in README; assert the rule text and its baseline date present | All named (re-baseline the count at merge — the directory grows); rule stated; control basename absent |
| #4899 | fixture test for the detection leg via `deploy.sh --check` | Fixture surfaced; conformant control **not** surfaced; no write call |
| #4901 | run the fixture suite against the pre-extraction inline logic and the post-extraction checker | **Byte-identical** verdicts on every fixture; the must-fail fixture fails in **both**; the checker runs outside CI; the gate job holds no residual detection logic |
| #4926 | locate the rule in `label-taxonomy.md`; run the lint against the live tracker; inspect exit and report behaviour | Rule names the label-family signal; lint surfaces the known-open cases and does **not** flag a genuine leaf epic; **no write call** |

Every entry is a `file-path+state` or `explicit predicate` AC class; none is behavioral/domain, so no declared-verification-deferred case arises in this release.

## Rollback Strategy

**Reversibility is not uniform across this release — treat it per card.**

- **Git-revertible (CHEAP):** all six code cards are file edits on one branch. Rollback = revert the release merge commit.
- **The gate-extraction card carries the highest re-verify cost.** Reverting restores the inline gate logic, so the **fixture suite must be re-run against the restored inline behavior** to confirm the gate is back to its pre-release verdicts. A revert that silently changes gate behavior is the failure mode.
- **The precision card carries a co-edit liability, not a rollback risk.** A revert must take **both** doctrine surfaces together; reverting one leaves the exemption pair divergent with nothing to detect it.
- **The IRREVERSIBLE half is out of this release.** The 278-issue milestone backfill was split out at the Stage-4 gate precisely because `git revert` cannot undo a GitHub state mutation.
- **Version:** no rollback surface — nothing is claimed until the Stage-12 atomic claim.

## Issue Disposition

All seven cards are **marked as closed at Stage 13** via the mandated automated close-out path. No close-family verb paired with an issue reference appears in any section of this plan, or in any section of the release PR body outside its designated Issue References block.

## Engineering Notes

**Tier-2 finding raised at Commit 0 — the reference-durability hook contradicts itself on this file class.** The hook `block-fragile-refs.sh` applies its positional issue-reference rule (`BLOCK-FRAGILE-REF-003`) to `release/releases/plans/*_RELEASE_PLAN.md`, which its scope gate lists explicitly. But the hook's own ledger-exemption comment asserts that the scope gate *"already excludes `release/releases/*`"* and treats that tree as a ref-permitted ledger surface where a reference is native provenance. Both statements cannot hold. The scope gate was widened to cover release plans without reconciling the positional rule to the ledger-surface model, and there is no per-file override marker for the issue-reference class (only link, version-ref, and URL). The observable consequence: **no existing release plan in this repository could be written today** — each carries bare references throughout — and every spoke that edits a plan file is blocked until it adds a designated reference block.

**Disposition here: comply, do not bypass.** This file carries a designated `## Issue References` block positioned before any reference, so every reference is in-block and self-describing. No hook bypass was used and none should be. **Following spokes on this branch inherit the same constraint** on every in-scope durable-corpus path — the `core/`, `release/references/`, `release/governance/`, `skills/`, and release-plan globs. Routed to the hub as a Tier-2 finding against the hook, not against any card in this release.

---

## Change Description

> **Accretes across the release.** This section is authored per the Change Description Protocol and is completed before the PR is transitioned from draft to ready-for-review at the Stage 9 gate. Rows land as each card's Engineering chip completes.

### Outcome

Backlog instrumentation becomes queryable, and the intake AC surface gains the half it was missing: a card shipping a mechanical check must now state not only that the check fires on the defect class, but that correct content stays unflagged — and must exercise that arm at each invocation parameter that narrows what the check examines.

### Issues resolved

| Card | Landed | Deliverable |
|---|---|---|
| #4463 | yes | Conditional conformance test `U5` on both doctrine surfaces of the registered exemption pair, plus an anti-pattern that makes it falsifiable, plus an intake-form pointer. ADR-131 |
| #4891 | pending | Coverage rule and residual-tool backfill in the deploy-tools README |
| #4708 | pending | Workflow path filter widened to three canonical trees; absent-is-pass corrected |
| #4899 | pending | Milestone-less stage-sub-task detection leg on Check 56 |
| #4926 | pending | Initiative-is-not-an-epic assertion and lint on Check 55. ADR-132 |
| #4901 | pending | Gate logic extracted to an invocable checker with a fixture suite |
| #4462 | pending | Blast-radius disposition rendered at the `D-BlastRadiusDisposition` D-Gate |

### Key decisions

- **Release Class `novel`** — rendered at the Stage-4 gate. Drives **Deep** Stage-9 review, which is the control on the gate-extraction card's mutation of a required status check.
- **The precision obligation binds to the parameter surface, not to self-reported scopes** — the card's own formulation would have passed the very check whose over-firing motivated it. Recorded in ADR-131.
- **The obligation extends the existing capability-class block rather than authoring a parallel one** — the mechanical-check scoping is *inherited* from C1 ∧ C2 ∧ C3, not invented, which is what keeps it off every non-check card.
- **Prospective, not retroactive** — the obligation applies from this release forward. The live test set is the three sibling cards in this bundle, not three closed ancestors.
- **No new check number is taken** by this release; two cards extend Checks 55 and 56 in disjoint regions.

### Reversibility

**CHEAP** for every code card (revert the merge commit), with two named caveats: the gate-extraction card requires a post-revert fixture re-run to confirm the gate returned to its pre-release verdicts, and the precision card's two doctrine surfaces must revert together or the registered exemption pair diverges silently. Confidence **HIGH**.

### Downstream impact

The `U5` obligation is graded at Stage 8 against three cards in this same release (CIAC-2), with the no-code card as the negative control. Downstream, it becomes the rule source if the sibling milestone's AC-presence check later graduates to grading AC *shape*. The debt it creates is named rather than hidden: five doctrine elements now hand-synced across two files with no mechanical drift detection, and a byte-parity check for that pair is the named retirement lever.

### Cross-references

- Stage-4 release plan and operator gate: the planning sub-task on this milestone
- Stage-5 design specs: one sub-task per card
- ADR-131 (`release/ADRs/`) — the parameter-surface binding
- ADR-132 (`core/ADRs/`) — the tiering enforcement surface

---
title: Release Plan — hooks-block-their-declared-subject (make each hook rule's enforced scope match its declared scope)
type: release-plan
plan_type: release
status: CLOSED
release: version-less (capability-slug identity; no tag claimed)
milestone: hooks-block-their-declared-subject
release_class: routine
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `hooks-block-their-declared-subject`

**Milestone:** `hooks-block-their-declared-subject` · hub sub-task #5915 = Stage 4 plan source · #5950 = D-ScriptScope gate record · #5938 = the Stage 6 Engineering sub-task that authored this file
**Version identity:** **version-less** — release-identity mode declared at Bundle; identity is the capability slug alone. D-Version escalation condition **(B)**, recorded not asked. **No `v*` tag is claimed at Stage 12**, and per `release/governance/RELEASE_PROTOCOL.md` § Versioning § Phase 1 the plan file and branch stay **slug-primary permanently** — the claim-time rename never fires. The Engineering-Commit-0 version re-verify and the Stage-12 atomic version claim are **inapplicable, not skipped**; the per-step disposition is recorded in § Commit-0 Version Re-Verify Disposition below.
**Topology:** D-C SINGLE — one release branch (`release/hooks-block-their-declared-subject`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial — Stage 6 slices route one at a time in dependency order on the single branch. Force-push (including `--force-with-lease`) on the shared release branch is prohibited under any non-serial posture; moot at P0, recorded for completeness.
**Release class:** `routine` — confirmed at the Stage 4 gate. Differentiation posture: engagement density Light · Stage 9 review depth Standard · Stage 5 activation bias SKIP-where-trivial · Stage 13 outcome-window 30-day.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #5915, together with the Stage-4 addendum and the **Decision Recorded — Stage 4 plan-approval gate** comment on the same sub-task, and reconciles both to the **D-ScriptScope** verdict recorded on #5950 and to the **Collective Review scope-lock** relayed at the Stage 5→6 boundary. Where a later disposition superseded a Stage-4 assumption, the transcribed sections preserve the Stage-4 plan of record and § Deviation Log records the ratified delta. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke (sub-task #5938, card #5593).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less (capability-slug identity; no tag) |
| **Bump Class** | N/A — `version-less` release; no bump-class intent is declared and no floor is derived |
| **Date Created** | 2026-08-23 (Sunday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/hooks-block-their-declared-subject` |
| **PR** | (populated at PR creation, Stage 6 Phase C2 — hub-owned) |
| **Milestone** | `hooks-block-their-declared-subject` |

---

## Commit-0 Version Re-Verify Disposition

`release/references/how-to/hub-spoke-bridge.md` § Procedure 0 § Canonical location requires the **first** Engineering spoke under SINGLE topology to re-run the authoritative-version-selection check across the plan-file write and its commit. That procedure is stated unconditionally for the first Engineering spoke, while `RELEASE_PROTOCOL.md` § Versioning makes the whole two-phase allocation rule conditional on release-identity mode `versioned`. This release is `version-less`. Each step therefore carries an explicit disposition rather than a silent skip.

| Step | Disposition | Basis |
|---|---|---|
| **1** — `git fetch --tags origin && git fetch origin main` | **EXECUTED.** `origin/main` = `8dc00db134b500d16f7168e16bfe4cd604d41b8e`. | Executed on its own merit: the release branch is cut from fresh authoritative `origin/main`, which this step supplies regardless of identity mode. Its *downstream* purpose — feeding steps 2–3 — does not apply. |
| **2** — recompute next-free for the plan's bump-class | **N/A.** No bump-class exists to derive a floor from, and no candidate is computed. | `RELEASE_PROTOCOL.md` § Release-identity mode: for `version-less` the allocation rule is *"inapplicable, not failed: there is no floor to derive, no candidate to compute, and no tag to claim."* The same section forbids synthesizing a placeholder version to force the release through the rule. |
| **3** — PROCEED/HALT on claimed-set membership | **N/A.** The predicate *"the planned version is NOT in the claimed set AND equals the recomputed next-free"* has no operands — there is no planned version. A vacuous PROCEED would assert a verification that did not occur. | Same section. D-Version recorded the determination at Stage 4: *"No next-free version was computed and none should be."* |
| **3b** — `release/tools/claim-version.sh --verify-stamp <slug>` | **N/A, and running it would be incorrect.** Its subject is the release-version stamp manifest — the double-brace `RELEASE_VERSION` placeholder token, named here rather than reproduced (see the note below) — which exists solely so the plan can be renamed and its token resolved at the Stage-12 atomic claim. For a `version-less` release the rename never fires, so a conformant plan carries no such token — and the verb returns exit 1 `TOKEN-LESS PLAN` on it by construction. | `RELEASE_PROTOCOL.md` § Phase 1: *"For a `version-less` release the plan and branch stay slug-primary permanently — there is no number to bind, and the rename never fires."* `claim-version.sh` § `--verify-stamp` documents `TOKEN-LESS PLAN` as one of its three exit-1 verdicts, and the claim tool's own STEP 0.5 carries an explicit *"a version-less release [is] byte-unaffected"* carve-out. |

**Consequence for this plan file:** it deliberately carries **no stamp-manifest token**, and does not reproduce that token verbatim anywhere — not even in the prose above. Two reasons, both load-bearing. First, inserting one to satisfy step 3b would declare a versioned identity this release does not have. Second, `claim-version.sh` derives its stamp slug by scanning pre-claim plans at the `plans/` root for that literal token, and declines when two or more carry it; a version-less plan that merely *mentions* the token would register as a second candidate and make a concurrent versioned release's claim decline its rename — a silent failure by construction. The construct is therefore named, never spelled.

**Precedent:** the shipped version-less plan `release/releases/plans/governance-ci-gates_RELEASE_PLAN.md` records the same disposition in its own header (*"the Engineering-Commit-0 version re-verify and the Stage-12 atomic version claim are inapplicable"*).

**Recorded gap (out of this release's scope, reported not acted on):** the bridge's § Canonical location procedure carries no release-identity-mode precondition, so a spoke reading only the bridge would rehearse a version claim for a release with no version to claim. The two surfaces agree in intent; the bridge simply does not state the precondition. On a milestone whose subject is *declared scope matching enforced scope*, that is a same-class mismatch and is worth an intake ticket.

---

## Change Description

*Scaffolded at Engineering Commit 0; authored in full at Stage 6 Phase C1 per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol, before the draft PR is transitioned to ready-for-review at the Stage 9 gate. Operator-facing voice.*

**Outcome (as declared at Bundle).** Every rule in the bypass-mode hook layer enforces exactly the scope it declares. Today four matchers declare more than they enforce or enforce more than they declare: a skill-edit gate whose regex sees only one directory level, two autonomy matchers that are unanchored or direction-blind, a destructive-script rule whose stated scope is broader than either of its arms reaches, and a spec that still names a file the hook stopped governing.

**Issues in scope.** #4977 · #5250 · #5293 · #5515 · #5568 (remnant) · #5593 · #5812. Each is marked as closed at Stage 13 per the close-out procedure; no close-family keyword is carried in this file or in the PR body outside the PR's dedicated Issue References block.

**Reversibility.** **CHEAP / HIGH** for the release as a whole — one PR, one merge, rollback is `git revert -m 1` of the merge commit. The single asymmetry is risk R5 below: a `BLOCK-AUTONOMY-002` widening that escaped review would be EXPENSIVE to detect after the fact, because it fails *open* on a disclosure control.

**Downstream impact and cross-references.** Populated at Phase C1 when the full change-set has landed.

---

## Phase A0 — Triage→Design Re-Review (transcribed from Stage 4)

```
stage:            4 — Release Planning
spoke_author:     Stage-4 planning spoke (release-scoped singleton), sub-task #5915
re_review_date:   2026-08-23
milestone:        hooks-block-their-declared-subject
cards_in_scope:   7 (#4977 #5250 #5293 #5515 #5568 #5593 #5812)
baseline_pin:     origin/main @ 096ced7e  (fetched at A0 entry)
rows_source:      phase-a0-native
effort_tier:      standard
```

**G-PL5 cache-read → MISS.** Named operand: no marker-bearing comment from the trusted author set existed on #5915 at Phase A0 entry. Cache absence is never a FAIL; PT-1..4 ran natively and all 8 header fields are authored above.

**G-PL4 — Bundle-Entry Freshness Re-Verification** (each card's own reproduction re-run against pinned `main` @ `096ced7e`):

| Card | Verdict | Empirical basis |
|---|---|---|
| #4977 | **admit-still-valid** | `SKILL_SCOPE_RE` at `block-skill-direct-edit.sh:182` still carries the single-level `references?/[^/]+\.md` form. Nested-reference population re-counted = exactly 12, matching the card. |
| #5250 | **admit-still-valid** (partially pre-satisfied) | `block-destructive.sh:932` — `bash\|sh\|zsh) script_verb="interp"` is the only interpreter arm; an interpreter-less invocation cannot match. AC-4 is already met by the fragment at `bypass-mode-readiness/block-destructive.md:37`; AC-2 is not — the registry row at `:62` still reads the unqualified "Bash subprocess script execution". |
| #5293 | **admit-still-valid** | `block-autonomy-ceiling.sh:502-503` — one `always_block "BLOCK-AUTONOMY-002"` on any direction mismatch; direction used in the message string only. `BLOCK-AUTONOMY-004` occurrences = 0 (id still free). |
| #5515 | **admit-still-valid** | `autonomy-tiers.md:161` item 6 still enumerates `SKILL.md`. |
| #5568 | **`close-resolved`** *(superseded at the gate — see § Deviation Log D-1)* | Fix `f6b7d620` and its regression arms `2afb785d` both landed 2026-08-15, ~47 minutes after the card was filed. |
| #5593 | **admit-still-valid** | `normalize_script_token` at `:292-297` strips exactly one leading and one trailing quote character. The `:980` interpreter arm is `*.sh` (suffix-anchored); the `:976` source arm is `/*\|./*\|../*\|~/*\|*.sh\|*.bash` (prefix alternatives). The measured asymmetry is present verbatim. |
| #5812 | **admit-still-valid** | `block-autonomy-ceiling.sh:473` is the bare glob `*/CLAUDE.md`, registered through `always_block` at `:479`. |

Per G-PL4 a `close-resolved` verdict never auto-closes — it routes to operator confirmation.

---

## Dependency Graph

Directional. Every edge reconfirmed against the cited card's own declared text, not against the milestone description.

```
#4977  ──────────────────────────────────────────►  (no inbound, no outbound)
                                                     original "must land AFTER #5515" edge: DISCHARGED

#5812  ──── file-serialize ────►  #5293  ──── file-serialize ────►  #5515
        (block-autonomy-ceiling.sh)      (autonomy-tiers.md: item 7 → item 6)

#5250  ◄──── co-scoped ────►  #5593        ordering SET at Collective Review: #5593 first
        (block-destructive.sh + shared rule fragment + shared test suite)

#5293  ──── hard, cross-milestone ────►  #5518  (ms #369 governance-declarations-match-enforcement)

#5568  ──  retained as a remnant (two unmet ACs)
```

**Circularity probe.** Denominator: 7 cards, 5 intra-milestone edges. Cycle count = 0. *Sensitivity arm:* the transitive chain `#5812 → #5293 → #5515` is 3 nodes deep and was detected non-empty, so the walk traverses. *Specificity arm:* injecting a synthetic `#5515 → #5812` back-edge produces a cycle, confirming the detector can fire. A zero here is a real acyclic graph, not an empty walk.

**Cross-milestone edges — all four confirmed against the sibling's declared `## Affected Files`:**

| Sibling | Verdict |
|---|---|
| #5518 (ms #369) | **CONFIRMED, and under-stated.** #5518 declares `core/hooks/block-autonomy-ceiling.sh` in its own Affected Files — the edge is hard *and* file-contention. |
| #5505 (ms #367) | **CONFIRMED.** Declares both `core/hooks/block-autonomy-ceiling.sh` and `core/specs/autonomy-tiers.md` — contends with #5812, #5293 and #5515. |
| #5661 / #5558 / #5227 (ms #336) | **PARTIALLY CONFIRMED.** #5558 and #5227 declare `core/config/allowlists/script-execution-allowlist.txt`; #5661 declares the *deployed* path `.claude/script-execution-allowlist.txt` instead. Still effectively contended, by a different mechanism than the milestone map states. |
| #5280 (ms #348) | **CONFIRMED.** Declares `core/config/allowlists/script-execution-allowlist.txt`. |

The two allowlist edge-sets (ms #336, ms #348) were conditional on D-ScriptScope at Stage 4. **D-ScriptScope has since resolved to the widened reading, so those edges are now ACTIVE** — see § Deviation Log D-2.

---

## Implementation Sequence

Four tracks. A and C are mutually parallel-safe; B is internally serial; D is the terminal join.

| # | Track | Cards | Constraint |
|---|---|---|---|
| 1 | **A — skill-edit scope** | #4977 | Sole owner of `block-skill-direct-edit.sh`. No inbound edge. Start immediately. |
| 2 | **B — autonomy matchers** (serial) | #5812 → #5293 → #5515 | #5812 and #5293 share `block-autonomy-ceiling.sh` and its test file. #5293 and #5515 share `autonomy-tiers.md` (items 7 and 6). Strictly serial, in this order. |
| 3 | **C — destructive allowlist evaluation** (serial) | **#5593 → #5250** | Same file, same rule, same test suite, same rule fragment. **Land order set at Collective Review: #5593 first.** #5250's new `exec` arm calls `normalize_script_token` and inherits #5593's fix, so the normalization must land beneath it. |
| 4 | **D — registry regeneration** (terminal) | #5293's declared regeneration | **Must run after B and C both land.** `core/rules/bypass-mode-readiness.md` is a generated index; regenerating before the fragment edits land silently drops them. |

Rationale for #5812 before #5293: #5812 is an anchoring correction to the `-001` case arm; #5293 restructures the `-002` branch and adds `-004`. Landing the smaller anchoring change first keeps #5293's diff readable and avoids re-basing the new rule onto a moving matcher block.

---

## Stage Applicability Matrix

Milestone Stage-5 activation bias: **SKIP-where-trivial**.

| Issue | Size | S5 | S6 | S7 | S8 | S9 | S12 | S13 | Basis for any SKIP |
|---|---|---|---|---|---|---|---|---|---|
| #4977 | S(2) | **SKIP** | Y | Y | Y | Y | Y | Y | Regex widening plus a regression arm; the design is a one-token change (`[^/]+` → `.+`). The false-positive question is bounded by a fully-enumerated 12-file population. |
| #5250 | M(4) | **APPLY** | Y | Y | Y | Y | Y | Y | The deliverable *is* a D-class decision. Not trivial by construction. |
| #5293 | M(4) | **APPLY (light)** | Y | Y | Y | Y | Y | Y | New rule id, security-relevant surface, master-activation-gate semantics change. Design pre-authored in the card — Stage 5 verifies rather than authors. |
| #5515 | S(2) | **SKIP** | Y | Y (doc-verify) | Y | Y | Y | Y | Spec reconciliation, zero behavioral change. The AC is a probe with a mandated control arm — a Stage-7 verification, not a design question. |
| #5568 | S(2) | **SKIP** | Y | Y | Y | Y | Y | Y | Re-scoped at the gate to two unmet ACs (see § Deviation Log D-1). |
| #5593 | S(2) | **SKIP** *(with a binding design constraint)* | Y | Y | Y | Y | Y | Y | Token normalization plus an arm-symmetry assertion, bounded by the specificity arm. **Constraint carried below.** |
| #5812 | S(2) | **SKIP** | Y | Y | Y | Y | Y | Y | Anchoring correction with a shipped in-file precedent (the `SKILL.md` removal at `:452-461`) to mirror. |

**Binding Stage-6 design constraint on #5593 (carried because Stage 5 is SKIPped).** #5593's AC-2 requires the two `-022` arms behave symmetrically on a shared input set. A shipped comment at `block-destructive.sh:970-974` **explicitly forbids the obvious route to that**: *"Do NOT unify it with the interpreter arm's `*.sh`: narrowing silently drops `/*`, `~/*` and `*.bash` coverage, and widening the interpreter arm to `/*` opens a false-positive surface with no defect behind it."* The conformant fix is **AC-1's normalization** — strip all trailing punctuation in `normalize_script_token` so both arms receive a clean token — **not** filter unification. An engineer who reads AC-2 without this constraint will take the forbidden route. **Reinforced, not relaxed, at Collective Review:** the comment stays unedited, #5250's design deliberately rejected the option that would have violated it, and its `exec` arm adopts the interpreter arm's expression as a **separate** `case` so an edit to one cannot silently retarget the other.

Stages 10/11 (Dry-Run / Snapshot) are Cowork-path stages; under the Claude Code path PR review is the dry-run gate and git history is the snapshot.

---

## Contention Map

Adopted at **5 rows** at the Stage 4 gate (the milestone description carried 3; declared `## Affected Files` support 5).

| File | Cards | Verdict |
|---|---|---|
| `core/hooks/block-autonomy-ceiling.sh` | #5812, #5293 | Carried in the milestone table — AGREE. |
| `core/specs/autonomy-tiers.md` | #5515 (item 6), #5293 (item 7) | Carried — AGREE. |
| `core/hooks/block-destructive.sh` | #5250, #5593 | Carried as "+ its test" — AGREE on the hook; the "+ its test" half is wrong, only #5593 declares `core/hooks/tests/block-destructive.test.sh`. |
| `core/hooks/tests/block-autonomy-ceiling.test.sh` | #5293 (explicit), #5812 (as the directory form `core/hooks/tests/`) | **NEW ROW** — missing from the milestone table. Does not change the serialization verdict; the row belongs in the table. |
| `core/rules/bypass-mode-readiness/block-destructive.md` | #5250 (explicit), #5593 (implied by its AC-5) | **NEW ROW** — missing from the milestone table. |

**Sole-owner rows (no contention):** `core/hooks/block-skill-direct-edit.sh` (#4977), `core/hooks/tests/block-destructive.test.sh` (#5593), `core/hooks/block-egress.sh` + `core/hooks/tests/block-egress.test.sh` (#5568).

**Probe record (PV-0..PV-7).** Invocation: `python3` structural join of hand-extracted declared-`## Affected Files` sets over all 7 cards (`grep` is shimmed to `ugrep` on this host and `git grep -E` does not honour `\b`, so neither was used for a load-bearing count). Denominator: 7 cards, 12 distinct declared paths. *Sensitivity arm:* `core/hooks/block-autonomy-ceiling.sh` → 2 cards, non-zero, so the join extracts. *Specificity arm:* `core/hooks/block-egress.sh` → 1 card, correctly **not** classified contention. *Control arm:* `core/hooks/block-credential-reads.sh` (a real hook named in no card) → absent, as expected. Extraction non-empty for the subject and both arms. Result: 5 contention rows, 7 sole rows, 12 paths.

### Build-order constraint (a generation edge, not a contention row)

`core/rules/bypass-mode-readiness.md` is a **generated index**, assembled by `core/deploy/tools/build-hook-registry.py` from the per-hook fragments under `core/rules/bypass-mode-readiness/` (`SOURCE_DIR_REL` / `INDEX_REL` at `:62-63`; deterministic, byte-identical output). Verified by content: the *"by construct"* text appears at fragment `block-destructive.md:37` **and** at index `bypass-mode-readiness.md:119` — the index embeds the fragment.

Consequence: **#5293 declares regeneration of the index; #5250 and #5593 edit a fragment that feeds it.** If the regeneration runs before the fragment edits land, the index reverts them and Checks 37/38 go red on a state no one authored. This is why track D is terminal. **Every Engineering spoke on tracks B and C edits the fragment, never the generated index.**

### File Change Matrix (machine-readable)

```
core/hooks/block-skill-direct-edit.sh                        edit
core/hooks/tests/block-skill-direct-edit.test.sh             edit
core/hooks/block-autonomy-ceiling.sh                         edit
core/hooks/tests/block-autonomy-ceiling.test.sh              edit
core/specs/autonomy-tiers.md                                 edit
core/hooks/block-destructive.sh                              edit
core/hooks/tests/block-destructive.test.sh                   edit
core/rules/bypass-mode-readiness/block-destructive.md        edit
core/rules/bypass-mode-readiness/block-autonomy-ceiling.md   edit
core/rules/bypass-mode-readiness.md                          edit
core/config/allowlists/script-execution-allowlist.txt        edit
core/hooks/block-egress.sh                                   edit
core/hooks/tests/block-egress.test.sh                        edit
release/releases/plans/hooks-block-their-declared-subject_RELEASE_PLAN.md   add

# ── Read-only inputs ──
core/deploy/tools/build-hook-registry.py                     READ
core/hooks/tests/test-runner.sh                              READ
core/hooks/tests/setup-ci-layout.sh                          READ
```

Two Stage-4 conditionals have since fired and are promoted to unconditional rows above: the allowlist row (D-ScriptScope resolved to the widened reading) and both `block-egress` rows (#5568 retained as a remnant rather than descoped). See § Deviation Log D-1 and D-2.

### A0.7 placement forward-check (G-PL3) — FIRED, verdict PASS

The mover-classifier over `2351582c..origin/main` returns a non-empty result — 124 directory-crossing renames — so a structural reorg has merged since this release's base and G-PL3 fires rather than skipping.

| Merged reorg (old → new directory) | Bearing on this release |
|---|---|
| `release/releases/plans/*` → `release/releases/plans/v4/*` | **None for placement.** That relocation is the Stage-12 claim-time rename into a version subdirectory. This release is version-less and claims no version, so its plan stays slug-primary and flat at `release/releases/plans/hooks-block-their-declared-subject_RELEASE_PLAN.md`. |
| `release/releases/notes/v{1,2,3}/*` → `release/releases/notes/*` (flattened) | **Bears on Stage 13.** Release notes are now flat in `release/releases/notes/`. Recorded here so Stage 13 places its note at the post-reorg path. |
| `core/hooks/reference-durability-allowlist.txt` → `core/config/allowlists/reference-durability-allowlist.txt` | **Confirms the allowlist home.** `core/config/allowlists/` is the current-main location, which is where the allowlist row already points. |

*In-scope deletes:* 0. Control arm: 3 total deletes in the window, non-zero, so the delete-class filter extracts. Every one of the 12 declared paths was independently confirmed present on disk at `096ced7e`. **No new-file placement targets a pre-reorg directory → G-PL3 PASS.**

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-23, domain: software }`

### In-Flight Release Roster

**Measured at:** `096ced7e` · `2026-08-23T00:00:00Z` · **Population:** n=0 siblings.

**Audit-baseline caveat — this zero is not load-bearing on its own.** Per audit-baseline discipline a default-to-zero over a transiently-empty population is usable only with its baseline pinned alongside it, which is why the SHA and timestamp are recorded. Four sibling milestones (#336, #348, #367, #369) carry cards declaring files this release edits; any one of them branching after that instant is invisible here. The verdict is rendered downstream at Stage 9 Phase A6.6, which re-measures fresh pre-GO. **Re-check before relying on it.**

---

## Lifecycle Definition

The File Change Matrix introduces exactly one new file — this plan. Every other row is an edit to an existing artifact, so no other lifecycle definition is owed.

| Question | Answer for `hooks-block-their-declared-subject_RELEASE_PLAN.md` |
|---|---|
| Growth pattern | Fixed — one file per release, appended to only during this release's own Stage 6–13 window. |
| Size discipline | No hard cap; bounded by the release's own scope. |
| Cleanup trigger | None during the release. |
| Archive path | Resolves to `release/releases/plans/_unversioned/` at Stage 13, per the plans README disposition rule (rule 2, second bullet — a version-less release whose LOG row records Tag `(none)`). It is **not** `git mv`'d into a `v<MAJOR>/` subfolder, because no version is ever claimed. |
| Ownership | Platform-level; the release hub owns it in flight, the release corpus owns it after close. |
| Exit conditions | Permanent — the plan is the release's audit record. |

---

## Risk Register

| # | Risk | Class | Sev | Owner stage | Mitigation | Reversibility |
|---|---|---|---|---|---|---|
| R1 | **Registry regeneration reverts fragment edits.** #5293 regenerates `bypass-mode-readiness.md` from fragments #5250 and #5593 are editing. Wrong order means silently dropped edits plus red Checks 37/38 on unauthored state. | Contention (generation) | **High** | Stage 6 | Track D is terminal by construction. CIAC-4 makes it testable. | CHEAP |
| R2 | **#5568 graded against ACs that already pass.** Two of its four ACs were met by a fix that shipped 47 minutes after the card was filed. | Scope | **High** | Stage 4 (rendered) | Re-scoped to the two unmet criteria at the gate — see § Deviation Log D-1. | CHEAP |
| R3 | **D-ScriptScope swings two cross-milestone edges.** The allowlist row is conditional on the gate; ms #336 and ms #348 contention exists only under the widened reading. | Dependency | **High** | Stage 4 (rendered) | Gate rendered on #5950 — widened reading adopted, so both edge-sets are ACTIVE. Stage 9 A6.5/A6.6 re-measures. | MODERATE |
| R4 | **#5593's AC-2 read literally leads to a forbidden fix.** The shipped comment at `:970-974` prohibits unifying the arms; AC-2 asks for symmetry. Stage 5 is SKIPped for this card, so nothing else would surface it. | Scope / correctness | **Medium** | Stage 6 | The binding design constraint is carried in the Stage Applicability Matrix above and was transcribed into #5593's Stage-6 chip prompt. **Discharged at Commit 1** — the arms were not unified; the fix is normalization, and the parity assertion is scoped to the arms' shared operand domain. | CHEAP |
| R5 | **Security-relevant widening on `-002`.** #5293 must not widen `projects → pmo-platform` by one path. | Security | **Medium** | Stage 7 | #5293's own fixture matrix asserts that direction blocks under all three `.autonomy-mode` values including `off`. Non-negotiable at Stage 8. | EXPENSIVE if wrong |
| R6 | **Source-vs-deployed drift.** The two hook copies already differ by content hash, and `--refresh-hooks` can exit 0 having deployed nothing on a stale baseline. | Deployment | **Medium** | Stage 12 | Verify deployed hooks by **content hash, never exit status**. Use `--all`, not `--deploy`. Forward-deploy source-over-deployed; never hand-merge. | MODERATE |
| R7 | **#4977 widens a gate to 12 more files.** Under-enforcement becomes work stoppage if the sanctioned editor path is unreachable for any of them. | Scope | **Medium** | Stage 7 | The blocker is discharged (`2351582c` plus the minter `start-skill-editor-session.sh`). Verify the sanctioned path is reachable for at least one newly-gated file before merge. | CHEAP |
| R8 | **Cross-milestone collision on `block-autonomy-ceiling.sh` / `autonomy-tiers.md`.** #5505 (ms #367) declares both; #5518 (ms #369) declares the hook. | Contention (cross-release) | **Medium** | Stage 9 | Serialization point — one merges, the other re-baselines. Baseline-pinned here; Stage 9 A6.5/A6.6 re-measures. | MODERATE |
| R9 | **`-022`'s widened surface cannot graduate on evidence it is not accumulating.** `BLOCK-EGRESS-007`'s widening drain holds 2 rows total, so it can never graduate. Shipping #5250's drain without a graduation criterion reproduces that failure. | Observability | **Medium** | Stage 6 | Binding condition on #5250: a named drain, an explicit graduation criterion in the rule's registry entry, and a must-flag / must-not-flag pair — all three ship together or the change is non-conformant. | MODERATE |
| R10 | **#4977's missing `## Affected Files` section** is invisible to the FCM parser and to sibling contention scans. | Governance | **Low** | Stage 6 | Tier-1 `[ADJUST]` body edit. | CHEAP |

**Rollback strategy.** Single-branch topology, one PR, one merge. Rollback = revert the merge commit; every card is CHEAP-reversible on its own terms. The one asymmetry is R5: a `-002` widening that escaped review would be EXPENSIVE to detect after the fact because it fails *open* on a disclosure control. That is why #5293's fixture matrix asserting the high-risk direction blocks under all three modes — including `off` — is a merge-blocking arm, not a nice-to-have.

---

## Cross-Issue Acceptance Criteria

Four. Each spans two or more issues, asserts a cohesion constraint no single-issue AC covers, and is graded at Stage 9 QC3.5 / Phase A3.6 on the merged PR.

- [ ] **CIAC-1 (#5250 × #5593 on `core/rules/bypass-mode-readiness/block-destructive.md`):** after both land, the fragment's stated scope for `BLOCK-DESTRUCTIVE-022` matches what the merged hook enforces on **both** bypass paths — the `:62` registry row no longer reads the unqualified "Bash subprocess script execution", and the fragment no longer asserts a closure the trailing-punctuation shape falsifies. Landing either card alone leaves the fragment over-claiming. *Method:* `python3` assertion over the merged fragment for the absence of the unqualified scope string and the presence of a qualifier naming both paths.

- [ ] **CIAC-2 (#5293 × #5515 on `core/specs/autonomy-tiers.md`):** the merged file carries both edits and neither reintroduces what the other removed — item 6 no longer enumerates `SKILL.md`, item 7 carries the two-direction split, and the two items do not contradict each other on whether a sanctioned session can satisfy a Tier-0 floor. *Method:* `python3` — assert `SKILL.md` absent from the item-6 governance enumeration **with a control arm confirming `CLAUDE.md` / `OPERATIONS.md` / `RELEASE_PROTOCOL.md` are still present**, plus assert item 7 contains two directional rows.

- [ ] **CIAC-3 (#5812 × #5293 on `core/hooks/block-autonomy-ceiling.sh`):** after both land, no `always_block` registration in the file matches on basename alone — the `-001` set is anchored to the primary root, and `-002` fires only on `projects → pmo-platform` with `-004` carrying the reverse under `apply_block`. *Method:* `python3` — assert zero bare `*/`-prefixed globs remain in the `-001` case arm (control arm: the anchored `${PRIMARY_ROOT}/.claude/hooks/*` entry is still present, so a zero is a real absence), and assert `BLOCK-AUTONOMY-004` is present and routed through `apply_block`.

- [ ] **CIAC-4 (#5250 × #5593 × #5293 on `core/rules/bypass-mode-readiness.md`):** the generated index is regenerated **after** all fragment edits and is byte-identical to a fresh generator run — no fragment edit is silently absent from the index, and the index carries no content no fragment produced. *Method:* the generator's own determinism mode, exit 0 on the merged tree.

---

## Verification Plan

| Family | Check | Owner stage |
|---|---|---|
| Runtime suite | `core/hooks/tests/test-runner.sh`, run against the materialized deployed layout produced by `core/hooks/tests/setup-ci-layout.sh`. Aggregate must be FAIL=0. Baseline at Commit 0: **PASS=895 / FAIL=0**, of which `block-destructive.test.sh` contributed 214/0. | Stage 6 C4 (per spoke), Stage 7 (authoritative) |
| Per-issue | Each card's own ACs, graded against the landed diff. | Stage 8 |
| Cross-issue | CIAC-1..CIAC-4 above. | Stage 9 QC3.5 |
| Sync | `core/deploy/deploy.sh --check`. Deployed hook copies verified by **content hash, not exit status** (R6). | Stage 6 C3 / Stage 12 |
| Doc-link integrity | `deploy.sh --check` Check 14 over modified markdown; plan links use the workspace-rooted form. | Stage 6 C4 |
| Registry freshness | Checks 37/38 — the committed index must match a fresh generator run. Meaningful only after track D lands. | Stage 6 (track D) / Stage 9 |

---

## Deviation Log

Ratified deltas against the Stage-4 plan of record. Each names its authority.

| # | Delta | Authority |
|---|---|---|
| **D-1** | **#5568 is RETAINED, re-scoped to a remnant** — not removed. The Stage-4 spoke recommended `close-resolved`; hub adversarial verification confirmed the *defect* is fixed but found only two of the card's four ACs met (AC-3 is CONDITIONAL — the widened surface is in `shadow` phase and permits rather than blocks; AC-4 is NOT MET — zero mutation/fixture arms exist in `block-egress.test.sh` while three sibling hook test files carry them). The card stays at S, narrowed to exactly those two. Both `block-egress` FCM rows are therefore `edit`, not explicit non-scope. | Decision Recorded — Stage 4 plan-approval gate, on #5915 |
| **D-2** | **D-ScriptScope resolved to the WIDENED reading** — the script-execution allowlist governs **execution capability**, shipped **warn-mode first behind a drain**, with a **required graduation criterion**. The Stage-4 spoke recommended the interpreter-only reading; the operator diverged. Interpreter-only was rejected because it would leave the rule's own message (*Red Team C1 — script-laundering mitigation*) claiming coverage it does not have. Three things ship together or the change is non-conformant: (1) a named drain for the widened `-022` surface, written on every would-fire; (2) an explicit graduation criterion — row count, time bound, or both — recorded in the rule's registry entry; (3) a must-flag / must-not-flag test pair per #5250's AC-3, with the in-tree false-positive surface assessed and recorded. The allowlist FCM row is promoted to unconditional and both cross-milestone edge-sets (ms #336, ms #348) are ACTIVE. | #5950 |
| **D-3** | **Track C land order SET: #5593 → #5250 → regenerate.** Stage 4 recorded "no hard ordering edge" between the two. Collective Review set one: #5250's new `exec` arm calls `normalize_script_token`, so #5593's normalization must land beneath it. | Collective Review scope-lock, relayed on #5938 |
| **D-4** | **#5593's arm-symmetry assertion generalizes to a 3-arm parity table** (`interp` / `source` / `exec`) rather than a 2-arm one, so #5250's third arm slots in without re-authoring the test. | Collective Review scope-lock, relayed on #5938 |
| **D-5** | **Two cards' handoff mis-declaration corrected.** #5515 and #5293 both declared their `core/specs/autonomy-tiers.md` edit operator-applied per Hook-Blocked → User-Side Handoff. Verified false at `block-autonomy-ceiling.sh:472-483`: the `BLOCK-AUTONOMY-001` governance set is exactly `*/CLAUDE.md`, `*/OPERATIONS.md`, `*/RELEASE_PROTOCOL.md`, `.claude/settings.json`, `.claude/hooks/*`, `.claude/rules/*`, and `core/specs/autonomy-tiers.md` is not in it — those edits are agent-performable. #5293's **deployed hook copy** handoff is correctly declared and stays. | Decision Recorded — Stage 4 plan-approval gate, on #5915 |
| **D-6** | **Contention model adopted at 5 rows.** The hub's own Decision Briefing reported 3 against the spoke's 5 and marked the delta a divergence at HIGH confidence; the hub's extractor required a file extension and silently missed #5812's declaration of the directory form `core/hooks/tests/`. The spoke was right. Routing impact: none — both additional rows pair cards already serialized on another shared file. | Decision Recorded — Stage 4 plan-approval gate, on #5915 |
| **D-7** | **Four Collective Review scope additions (a)–(d) are IN for this release.** Their content is enumerated on the hub thread and on the affected cards' own Stage-6 sub-tasks; none of the four lands in #5593's slice, and their sequencing effects are captured as D-3 and D-4 above. Recorded here as ratified scope rather than restated, so this plan does not assert content the authoring spoke did not read. The spokes that own them reconcile this row as they land. | Collective Review scope-lock, relayed on #5938 |

---

## Actions Carried From Stage 4

1. **Tier-1 `[ADJUST]` on #4977** — add a conventional `## Affected Files` section naming the hook and its test file. Owner: the #4977 Engineering spoke.
2. **Amend the milestone's intra-milestone contention table** to 5 rows and record the terminal registry-regeneration constraint. Owner: hub.
3. **Do not merge #5812 into #5293** despite the shared file. Different rules, different risk profiles; serialization already resolves the contention.
4. **No splits recommended.** The two `size:M` cards are cohesive; splitting either would create a partial control change.

## Out-of-Scope Discoveries (recorded, not acted on)

- `core/rules/bypass-mode-readiness/block-skill-direct-edit.md` **does not exist**, while fragments exist for `block-destructive`, `block-autonomy-ceiling` and `block-egress`. `BLOCK-SKILL-EDIT-001` — the subject of #4977 — therefore has no per-hook registry fragment. Adjacent to this milestone's theme (a hook whose declared subject has no declaration surface at all) but outside every card's scope. Worth an intake ticket.
- **#5893 is OPEN and carries no milestone**, despite being the required gate input for D-ScriptScope and the owner of the warn-mode-drain gap. Recommend triaging it into a milestone.
- **The Commit-0 version re-verify carries no release-identity-mode precondition** in `hub-spoke-bridge.md` § Canonical location — see § Commit-0 Version Re-Verify Disposition.
- **#5568's own Notes section warned about exactly the failure that produced it**: *"The pattern of diagnosing a hook from its firings rather than its source has now cost this milestone two wrong conclusions."* A class-potential observation for `domain: release-ops`, theme *diagnose-from-source-not-firings*; logged as a candidate, not promoted.

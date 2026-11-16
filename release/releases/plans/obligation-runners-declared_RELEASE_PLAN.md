---
title: Release Plan — obligation-runners-declared (a declared governance obligation has a runner or a recorded decision that it will not)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the rule-computed next-free at Engineering Commit 0 is v5.08; the concrete number binds at the Stage-12 atomic claim)
milestone: obligation-runners-declared
release_class: novel
reversibility: MODERATE / Confidence HIGH — one revert of the release merge restores every file, the operator-committed RELEASE_PROTOCOL.md limb included; the moved release note's path is cited by a sibling milestone's pending links.plan edits, so a revert is re-read against that sibling. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `obligation-runners-declared`

**Milestone:** `obligation-runners-declared` (milestone 400). Four cards: **#6227**, **#6226**, **#6225** and **#7842**, all native children of epic #5867. The Stage-4 planning sub-task **#8897** carries the approved plan (`#8897 comment 6858855052`, part 1, and `#8897 comment 6858858487`, part 2) and the Stage-4 gate's Decision Recorded (`#8897 comment 6859598248`). The Stage-5 designs are **revision 1** on four sub-tasks: #6227 on **#8917** (`#8917 comment 6865285888`, `6865288966`, `6865291333`), #6226 on **#8918** (`#8918 comment 6865472443`, `6865472881`, `6865473339`), #6225 on **#8919** (`#8919 comment 6866284208`, `6866286597`, `6866289061`) and #7842 on **#8920** (`#8920 comment 6866285043`, `6866287296`, `6866290078`). The Collective Review's design-decision record is `#8917 comment 6864580721`; its conformance record and scope lock is `#8917 comment 6866868670`. The Stage-6 Engineering sub-task for beat 1 is **#8921**; this file is Engineering Commit 0, authored by the beat-1 spoke on #8921, which also builds beat 1a (#6227's agent limbs).

**Version identity:** **versioned** — bump-class **`minor`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v5.08`**, equal to the Stage-4 provisional display (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/obligation-runners-declared`, cut from `origin/main` at `29c60404` (the Stage-4 pin, unchanged at Commit 0); one pull request opened in **draft** at Stage 6 Phase C2; one merge into `main`.

**Concurrency posture:** **P0 fully serial** — one Engineering spoke at a time, in beat order #6227 → #6226 → #6225 → #7842. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep** (§ Release Class declaration).

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #8897 and is amended, in order, by: the Stage-4 gate's Decision Recorded on #8897 (plan approval with [ADJUST] A-1 to A-12, D-Outcome (A), D-Editability-6227 (A), the G-PL4 re-scope of #6227 confirmed); the Stage-5 Collective Review design decisions on #8917 (D5-4 pooled, D5-6 (A′), D5-5 (B′), the revision-1 package with OD-2); and the Collective Review conformance record and scope lock on #8917 (C1, C2, C3, the corrected N7, and the 31-path write set). The designs Stage 6 builds are the four Stage-5 **revision-1** outputs, never the earlier outputs they supersede. Where the plan and a later record differ, the later record wins, and each stale Stage-4 premise is corrected by a row in § Deviation Log rather than by rewording the transcribed plan text (hub value N18). Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): the Bump-Class Selection Guide row "Protocol text addition or modification", validated against the File Change Matrix. The Stage-4 provisional display was `v5.08`; the rule-computed next-free re-verified at Engineering Commit 0 is `v5.08` (§ Commit-0 Version Re-Verify Record). Four in-flight sibling releases are also `minor` and compute the same slot, so the slot is settled by merge order and the compare-and-swap. The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-13 (Friday, UTC) |
| **Release Manager** | Agent-assisted (release-hub) |
| **Status** | Executing — #7842's Stage-6 fix(dt) pass 1, carrying #6225's F-10, is on the branch and awaits the hub's consumption. On the branch, in this order: Engineering Commit 0 (this file) and beat 1a (#6227's agent limbs); beat 2 (#6226); beat 3 (#6225), during which the operator's `release/governance/RELEASE_PROTOCOL.md` commit landed; beat 1b (#6227's second agent limb), which followed that commit under C2 (A); the Stage-7 fix(dt) pass 1 and the Stage-8 fix(qa) pass 1; the merge of `origin/main` after PR #8821 merged (DEV-21); beat 4 (#7842's quality-share reading, with the #6226 and #6225 fix(qa) carries); beat 5 (§ Change Description and the release-wide self-verification); the merge of `origin/main` after PR #9030 merged (DEV-21); and #7842's fix(dt) pass 1, for its Stage-7 pass-1 findings, with #6225's F-10 carried (DEV-24). Next: a DT check of that pass, then #7842's Stage-8 QA; #6225 has completed Stage 8, pending two CI rows, its QA pass 2 recommending acceptance |
| **Branch** | `release/obligation-runners-declared` |
| **PR** | opened in **draft** at Stage 6 Phase C2; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `obligation-runners-declared` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-13, domain: governance }`

#### Domain Practice Provenance

**Form X** (sourcing-exempt): every File Change Matrix path is an internal pmo-platform artifact (governance standards and disciplines, pipeline shards, release-corpus files, a `deploy.sh` check and a release read-model), so the release consumes no external body of practice. Dominant domain **`governance`**; secondary domain `software` (#6225's check primitive and #7842's read-model extension). Transcribed unchanged from the Stage-4 plan (Phase A1.5).

---

## Commit-0 Version Re-Verify Record

Run at Engineering Commit 0, both halves, per `release/references/how-to/hub-spoke-bridge.md` Procedure 0 § Canonical location (single-branch topology, steps 1 to 3b).

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin`, then `git fetch origin main` | both exit 0; `origin/main` = `29c60404` (`29c604045def22ebd21fb4a758c3bb56be277b20`), the Stage-4 pin, unchanged. The release branch was cut from it before this file was written |
| **2** | Recompute next-free for bump-class **`minor`** through the adapter itself: `release/tools/claim-version.sh --sha 29c604045def22ebd21fb4a758c3bb56be277b20 --bump minor --dry-run` (the adapter's own allocation; no tag pushed) | **`v5.08`** (exit 0; "would claim v5.08 (no tag pushed)") — equal to the hub-recorded D-Version determination (provisional `v5.08`) |
| **3** | HALT unless the planned version is absent from the claimed set AND equals the recomputed next-free. The tag arm binds; the published-Release and ledger arms corroborate | **absent on every arm, equal to next-free → PROCEED** |

**Probe record for the step-3 zero** (per `core/disciplines/review-discipline-principles.md` § 8, elements PV-0 to PV-7):

```
Probe:       git ls-remote --tags origin                                   (tag arm — binds)
             gh release list --limit 5000                                  (Release arm)
             git show origin/main:release/releases/RELEASE_LOG.md          (ledger arm)
             each saved to a file and read by one python3 line scan that matches the
             exact two-digit version token on each arm
Denominator: 468 ls-remote lines (235 distinct versions, the highest v5.07); 233 published
             Releases (under the 5000 limit, so not truncated); the ledger at origin/main,
             3,084 lines
Control - sensitivity: the same scan on the v5.07 slot reads 2 tag lines, 1 Release line and
             6 ledger lines; on the v5.06 slot it reads 2, 1 and 7. Every arm returns
             non-zero on a claimed slot, so a zero on the v5.08 slot is a real negative
Control - specificity: NOT TRIGGERED — a slot-occupancy question over one exact version token
             has no near-miss class the probe must reject (the comparator is token equality)
Extraction:  every line of the three reads, the ledger read from origin/main (never the
             worktree copy)
Result:      0 occupants of the v5.08 slot on every arm
Verdict:     CLEAN — v5.08 is free and equals the recomputed next-free; no HALT
```

**In-flight state at Commit 0:** five sibling releases are open as draft pull requests (§ Cross-PR Overlap Audit → In-Flight Release Roster). Four are `minor` and recompute next-free to the same `v5.08` slot; the fifth is `version-less` and claims no slot. That is a Tier-S serialization point resolved by merge order and the atomic claim, not a HALT at this rung: the slot binds at the claim, and Stage 12's pre-merge freeness check and the compare-and-swap are the later rungs.

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp obligation-runners-declared`, run after this file was written and before it was committed; exit 0 is required. The result is recorded in § Verification Evidence.

This file carries **exactly one** literal double-brace release-version placeholder — the Header `**Version**` cell. Every other mention names the placeholder rather than reproducing it, because the claim resolves the token by substitution across the whole file. The transcribed Stage-4 Implementation Sequence named the placeholder literally in its beat-0 row; that one span is rendered by name here (DEV-13).

### Date variable

`${AUDIT_DATE_UTC}` is resolved **once**, at Engineering Commit 0 (the Stage 6 first commit), as `date -u +%Y-%m-%d` → **`2026-11-13`** (Friday). Its one consumer in this release is #6225's beat 3, per that card's Stage-5 Date Variable block: the check's W2 armed date, `readonly ENUMERATION_DRIFT_ROLLOUT_ARMED="${AUDIT_DATE_UTC}"` in `core/deploy/deploy.sh`, used verbatim with this value; the flip-decision row names the constant, not the date. No other identifier in this release carries a date.

### Commit-0 Survival Set

Every element determined at Stage 4 that a named downstream consumer reads **from this file** (`release/references/pipeline/stage-04-planning.md` § 6). Dropping one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, so no Mode-B rationale) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited), rendered at the scope-locked 31-path write set | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria, CIAC-1 to CIAC-5 | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan, with the AC baseline | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace placeholder in the Header `**Version**` cell; bump class in the `**Bump Class**` row) | § Header |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (the Stage-4 `origin/main` SHA) and the Commit-0 base | § Cross-PR Overlap Audit → Baseline SHA |

---

## Scope

### Issues Included

| Issue | Priority | Size | Title | Beat | Stage-5 design (revision 1) | Disposition |
|---|---|---|---|---|---|---|
| #6227 | P2 | M | Determinations that constrain a code path are recorded only on transient surfaces | 1 | `#8917 comment 6865285888`, `6865288966`, `6865291333` | carried; the `RELEASE_PROTOCOL.md` limb is operator-executed (D-Editability-6227 (A)) |
| #6226 | P3 | M | A written convention and live practice diverge with no rule naming which side is authoritative | 2 | `#8918 comment 6865472443`, `6865472881`, `6865473339` | carried |
| #6225 | P2 | L | Hand-maintained enumerations drift from the populations they describe, and nothing detects it | 3 | `#8919 comment 6866284208`, `6866286597`, `6866289061` | carried |
| #7842 | P3 | M | Set and measure the capacity band for the standing quality initiative | 4 | `#8920 comment 6866285043`, `6866287296`, `6866290078` | carried; beat 4 follows the rebase onto ms#429's merge |

**Size:** 20 raw points, **23 effective** under `novel` (×1.15), inside the 15–25 band; unchanged at the scope lock.

### Exclusions

| Item | Why it is out of scope | Routed to |
|---|---|---|
| #6887 (unmilestoned) — the same enumeration mechanism proposed as a Check 63 arm | D5-1 chose a sibling check (OD-9); the two were coordinated at Stage 5 | stays open on its own card |
| #7414 (unmilestoned) — Check 63 is red on `main` (6 FAIL rows at `29c60404`) | owned there; this release reads the new check's own rows, never the `--check` exit status (R3) | #7414 |
| #6625 (unmilestoned) — `version-field-semantics.md` has no version-less coverage | related, not edited; the when-to-version rule reuses that standard's material-edit test (D5-2) | #6625 |
| #7537 (unmilestoned) — per-release inflow attribution | related only; scaffolding is excluded by the `sub-task` label ([ADJUST] A-11) | #7537 |
| `release/skills/release-planner/SKILL.md` Mode B step 3 (its version mapping has no identity-mode branch) | OD-5 (A′): no skill edit this release; one precedence sentence in § Versioning subordinates it | a Stage-13 follow-up, `follow-up: user-visible · bug` |
| Two further hand-maintained counts of #6225's class (`core/rules/bypass-mode-readiness.md` "seven hooks"; the charter template's five-value bullet against the design-principle register) | Related only; not added to the AC set (Stage-4 out-of-scope discoveries) | the filing step |
| #7842's R8 (Check 33's default-presence list) and R14 (the `[overrides]` section mismatch) | out of the card's scope | release follow-ups, filed only if they pass the filing threshold |

---

## Decision Record

### Stage-4 plan gate (operator, 2026-11-13)

Rendered by the operator on 2026-11-13 (Friday) in the hub session's main-thread briefing (`#8897 comment 6859598248`). **Approved:** the plan, with [ADJUST] A-1 to A-12 applied as listed in its Recommendations (MODERATE · HIGH); **D-Outcome (A)**, the revised Release Outcome Statement with a #7842 limb and the required `**Limb owners:**` line; **D-Editability-6227 (A)**, the operator commits #6227's when-to-version rule into the Tier-0-floored `RELEASE_PROTOCOL.md` from agent-prepared text; the G-PL4 `re-scope-changed` verdict on #6227, restating AC-3's input to live practice ([ADJUST] A-8). **Recorded with the plan, not asked:** D-ReleaseClass `novel`; D-C SINGLE; D-Concurrency Posture P0; D-Sequence (A), #6227 → #6226 → #6225 → #7842; D-Version minor, provisional `v5.08`. **Card dispositions:** all four carried. **Not covered by that approval:** the Stage-5 decisions D5-1 to D5-6, the Collective Review scope lock, and any agent write to `RELEASE_PROTOCOL.md`. **Working assumption** recorded there: if PR #8821 has not merged when #7842's beat comes up, that beat waits while beats 1–3 proceed through Stages 7–8; a still-open #8821 at Stage 9 goes to the operator there.

### Stage-4 D-Gate block (as approved)

#### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** the trigger evaluation above; the 2026-09-27 rendering (`novel`) recorded in the milestone description.
**Pre-decided:** `novel`, operator-ratified 2026-09-27 (milestone amendment of that date); unchanged by the 2026-11-05 amendment.
**Gate decision:** (A) routine · (B) novel · (C) cross-cutting · (D) hotfix.
**Blocks:** the Stage-9 review depth; the Stage-5 activation bias.
**Upstream compatibility:** N/A — Release Class is PMO-internal taxonomy and touches no skill-authoring surface.
**Design-Principle Conformance:** N/A — no design-principle `scope_predicate` matches a classification choice.
**Reversibility / Confidence:** CHEAP / HIGH (re-classifiable under the taxonomy's Re-Classification Protocol).
**Recommendation:** (B) `novel` `[RECOMMENDED]`; re-check at Stage 5 against the cross-cutting watch item.

#### D-Version: What version does this release claim? (recorded determination)
`versioned`, bump-class **minor** — the Bump-Class Selection Guide row "Protocol text addition or modification", validated against this FCM [SOURCE: `RELEASE_PROTOCOL.md` § Bump-Class Selection Guide]. Provisional display **v5.08**, from `claim-version.sh --sha 29c60404… --bump minor --dry-run`, which read the authoritative claimed set after `git fetch --tags origin` (latest tag v5.07) [SOURCE, 2026-11-13]. Re-verification rungs: Engineering Commit 0 (steps 1–3, then `--verify-stamp`) and the Stage-12 atomic claim. No (B) or (C) escalation condition is present. ms#429, ms#439 and ms#440 compute the same slot, and the compare-and-swap settles it. **Watch:** if Stage 5 creates a new governance file (`CONDITIONAL:marker-own-standard`), the guide's "New governance file created" row maps to **major**, so Stage 5 should prefer an existing home.

#### D-C Branch Topology
**Gate input:** 4 cards, 0 edges; shared hot files (`gate-efficacy-standard.md` ×3–4, `duplicate-source-discipline.md` ×2); one operator-committed limb; the milestone rule of one PR and one merge.
**Gate decision:** (A) SINGLE — one release branch and one PR · (B) OPTION-A — per-issue branches, PRs and early merges.
**Blocks:** Procedure 1 scaffolding; the plan-file commit route.
**Upstream compatibility:** N/A — branch topology touches no skill-authoring surface.
**Design-Principle Conformance:** (A) ALIGNED DP-4 (Simplicity, `core/disciplines/build-philosophy.md:51`) — one branch and one rebase point. (B) **CONFLICT.** DP-4 (Simplicity) — four PRs each rebase on the same register tail; mitigation: SINGLE. The register's `last_verified_date` is 2026-07-27, more than 90 days old; the staleness is noted.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** (A) SINGLE `[RECOMMENDED]`.

#### D-Concurrency Posture
**Gate input:** the A4 contention map (`gate-efficacy-standard.md` with 3–4 writers on one insertion point; `duplicate-source-discipline.md` with 2 writers and a semantic seam); D-C SINGLE; 4 beats; the operator limb between beats 1 and 2.
**Gate decision:** P0 fully serial · P1 serialized commit lane · P2 per-sub-task-branch merge queue · P3 parallel-push rebase-retry.
**Blocks:** Stage-6 dispatch.
**Upstream compatibility:** N/A.
**Design-Principle Conformance:** P0 ALIGNED DP-5 (Stability, `build-philosophy.md:52`) — no concurrent writer on a contended insertion point. P2/P3 **CONFLICT.** DP-5 — concurrent appends at :403; mitigation: P0.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** **P0** `[RECOMMENDED]` (also the undeclared default).

#### D-Editability-6227: Who writes #6227's when-to-version rule into the Tier-0-floored `RELEASE_PROTOCOL.md`?
**Gate input:** the Agent-Editability Read. Both BLOCK-AUTONOMY-001 blocks match the path. #6227 AC-3 names § Versioning as the rule's home.
**Pre-decided:** none on record. **Precedent — the limb has gone undelivered before.** In v4.32 and v4.60 the `RELEASE_PROTOCOL.md` limb did **not** land in-release. The finished replacement text was carried on the owning sub-task as an operator handoff, and the path was recorded as an undischarged obligation for the Stage-9 gate [SOURCE: v4.32 plan :440; v4.60 plan :234].

**Miss path, if the operator commit is absent at Stage 8:**
- AC-3 grades NOT MET.
- The `stage-03-bundle.md` citation has not been committed (beat 1 orders it after the operator commit), so nothing dangles.
- At Stage 9 the operator either commits before GO, or carries AC-3 as undischarged. #6227 then stays open past Stage 13 and is not marked as closed, its other criteria are recorded delivered, and the hub routes the text to the follow-up filing step.
**Gate decision:**
- (A) The operator commits the floored limb from agent-prepared replacement text. The agent writes `decision-discipline.md`, `stage-03-bundle.md` and the register rows. AC-3 stays as written.
- (B) Re-home the rule's body in `stage-03-bundle.md` § Release-Identity Mode, with § Versioning carrying only a one-line citation. This still needs an operator commit, and AC-3 needs an amendment.
- (C) Split AC-3 out to a follow-up card, and ship the surface requirement alone.
**Blocks:** #6227 Stage 6 beat 1; Stage 8 AC-3.
**Upstream compatibility:** N/A — the governance-doc location touches no skill-authoring surface.
**Design-Principle Conformance:**
- (A) ALIGNED DP-3 (Maintainability, `build-philosophy.md:50`) — the rule lands once, beside the enum it governs. ALIGNED DP-7 (Track-all-edits, `:56`) — the floored edit is still a reviewed PR commit.
- (B) **CONFLICT.** DP-3 — it splits the versioning rule from the § Versioning enum it governs; mitigation: cite-not-restate, so the guide stays the single home.
- (C) N-A DP-3 (the rule is not written at all this release); ALIGNED DP-7. Its cost is scope — the card is left partly delivered — not a principle conflict.
- Register staleness (`last_verified_date` 2026-07-27) noted.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** (A) `[RECOMMENDED]`.

#### D-Outcome: Approve the revised Release Outcome Statement (M-1, M-2)
**Gate input:** Mode R M-1 (no `**Limb owners:**` line; required since 2026-10-29; lock 2026-11-13); the AFTER paragraph has no #7842 limb.
**Gate decision:** (A) approve the draft below as written · (B) approve with edits · (C) keep the current statement and accept a G-CL10 arm (ii) FAIL at close (warn-mode, logged).
**Blocks:** the Phase B1 milestone-description PATCH; Stage 13 G-CL10 arm (ii).
**Upstream compatibility:** N/A.
**Design-Principle Conformance:** (A) ALIGNED DP-7 (`build-philosophy.md:56`) — the obligation's owner is declared where the gate reads it. (C) **CONFLICT.** DP-5 (Stability) — a known FAIL is accepted; mitigation: (A).
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** (A) `[RECOMMENDED]`.

#### D-Sequence: Move #6227 to the front of the internal sequence?
**Gate input:** the Implementation Sequence; the operator limb's fixed overhead.
**Gate decision:** (A) #6227 → #6226 → #6225 → #7842 · (B) keep #6226 → #6227 → #6225 → #7842.
**Blocks:** Stage-6 dispatch order.
**Upstream compatibility:** N/A.
**Design-Principle Conformance:** N/A — no design-principle `scope_predicate` matches a sequencing choice.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** (A) `[RECOMMENDED]`. Both orders keep #7842 last, after the ms#429 rebase.

### Stage-5 Collective Review — design decisions (operator, 2026-11-13)

Rendered by the operator on 2026-11-13 (Friday) after the four Stage-5 designs and their Phase A6.5 adversarial reviews (`#8917 comment 6864580721`). **D5-4 (#7842):** pooled, with the mean printed beside it (MODERATE · MEDIUM). **D5-6 (#6225):** (A′), the executor census plus a comment-only citation in `install-tests.yml` (CHEAP · HIGH). **D5-5 (#6226):** (B′), decline the index-vs-notes assertion, with an upgrade trigger in `notes/README.md` (CHEAP · MEDIUM). **The revision-1 package, with OD-2:** a release whose only product is a decision record ships `version-less` (CHEAP · HIGH). Revision-1 resolutions the package carries: OD-1 the material-edit rule, confidence relabelled MEDIUM; OD-3 confirm; OD-4 (A′); OD-5 (A′) one sentence in the operator patch, a Mode-B dry run, the `release-planner` step-3 follow-up filed at Stage 13 with no skill edit; OD-6 (B) no Stage-13 re-declaration, owner #5867, members keyed by trigger; OD-9 keep the sibling check with a re-derived reason; OD-10 wildcard-segment keys; OD-11 deploy-time only; OD-12 out of scope; OD-17 the window from the release log by merge ancestry, with a completeness guard; OD-18 no ADR, one at-path sentence for D5-2's rejected alternative. **Correction recorded there:** pooled is less sensitive to re-bundling than the mean, not immune.

### Scope lock and hub conformance (operator, Stage 5 revision 1)

Rendered by the operator in the hub session's main-thread briefing; posted as `#8917 comment 6866868670` at 2026-11-13T22:49Z. The re-scan returned NOT CONFORMING on 3 cross-card collisions with 0 open rows; the hub closed them as C1–C3:

- **C1 — Version History rows (hub value N9):** every card that adds a register row appends one Version History row at the table end, in beat order.
- **C2 — the operator's `RELEASE_PROTOCOL.md` commit (operator decision (A)):** beats 2–4 do not wait. Whenever the operator's commit lands before the Stage-9 GO, a spoke runs **beat 1b** immediately after it and before the next gate: the `stage-03-bundle.md` citation, register row B, and the second `spec-practice-adjudications` record line. With no commit by Stage 9, #6227 AC-3 takes the plan's miss path. The hub's earlier determination that the hub writes line 2 before Stage 7 is withdrawn.
- **C3 — Deviation Log form:** one `DEV-<n>` sequence under `| ID | Stage | Deviation | Basis |`; `verify-release-plan.sh` reads only `NOT DELIVERED` and the path, so no check is affected.
- **N7, corrected after reading `core/standards/gate-efficacy-standard.md`:197:** a register row that names a runner carries one `runner-def:` pointer; a named-gap row carries none.
- **Recorded form deviation (not a block):** nine Evidence-Grounding entries keep their survey commands inside table cells rather than on a labelled `**Survey command:**` line; each command is present and reproducible.

**Scope lock (operator):** scope is locked at the **31-path write set** — 16 planned paths, 8 fired CONDITIONAL rows and 7 FCM-delta rows — at 20 raw / 23 effective points (`novel`, inside 15–25), bump-class minor, not cross-cutting (2 stage files; at most 2 of the 6 rule-defining surfaces). Post-lock changes go through a Decision Briefing with an impact assessment. **Superseded in #6227's revision 1:** Output for Stage 6 step 4's two-state consequence list, by C2 (A); the `DL-6227-n` labels, by C3's `DEV-<n>` sequence (§ Deviation Log).

### Hub N-way values (as applied by the four revision-1 designs)

| Value | Ruling | Source |
|---|---|---|
| **N7** (corrected) | A gate-coverage register row that names a runner carries one `runner-def:` pointer; a named-gap row carries none | scope lock (`#8917 comment 6866868670`); applied by each card |
| **N8** | Each card states only its own Check-62 pointer delta; the release-level count is graded once, by the hub, at Stage 7. Stated deltas: #6227 +0 · #6226 +0 · #6225 +2 · #7842 +1 | each card's revision 1 |
| **N9** (C1) | Every card that adds a register row appends one Version History row at the table end, in beat order | scope lock C1 |
| **N18** | A stale Stage-4 premise is corrected only by a Commit-0 deviation-log entry; no plan text is reworded | each card's revision 1; § Deviation Log DEV-1 to DEV-10 |
| **N19** | FCM delta, per card: #6227 none · #6226 1 · #6225 5 · #7842 1 (7 rows, each a Tier 1 [ADJUST] at Commit 0) | each card's revision 1; § File Change Matrix |
| **N20** (C2 (A)) | Beat 1b runs immediately after the operator's commit whenever it lands before the Stage-9 GO; with no commit by Stage 9, #6227 AC-3 takes the miss path. Supersedes the beat-2 trigger in #6227's revision 1 | scope lock C2 |
| **N21** | #6225's live red is stated once, in its Stage-5 Detail § Live red (1 DRIFT row on the mark commit, then 0), and cited everywhere else; not applicable to #6227 | `#8919 comment 6866284208`; `#8917 comment 6865285888` |
| **N23** | The gate-coverage register holds 91 data rows at the pin (header at :311) | each card's revision 1 |
| **N25** | Every D-decision carries an Upstream-compatibility field (`N/A — no skill-authoring surface` where none is touched) | each card's revision 1 |
| **C3** | One `DEV-<n>` sequence under `| ID | Stage | Deviation | Basis |` | scope lock C3 |

### Stage-5 D-class decisions — as planned at Stage 4, and as rendered

**Stage-5 owned D-class decisions (listed, not decided here):**
- **D5-1** (#6225): extend Check 63 or add a sibling check. Coordinate with #6887 (same mechanism) and #7414 (Check 63's current red). Record the choice at the code path (CIAC-3).
- **D5-2** (#6227): the when-to-version rule's content, against live practice that is now predominantly `versioned` (A-8). Coordinate with #6625 so `version-field-semantics.md` agrees.
- **D5-3** (#7842): where the band values live — a parameter the doctrine cites, or doctrine text. The values are re-set after three measured releases.
- **D5-4** (#7842, operator): the band's aggregation for the real measure — a rolling mean of per-release shares (the card's Notes) or a pooled share. Measured over the last five closed releases: mean of shares 47%, pooled 38%. Per-release shares swing between 0% and 100% because releases carry one to five non-scaffolding items (R7). Criterion 2 is settled and stays closed.
- **D5-5** (#6226): adopt the optional index-vs-notes assertion, and if so, as a #6225 marker instance or its own check.
- **D5-6** (#6225): the #5502 remedy — discover suites in `install-tests.yml` or mark the enumeration, with the 6 unwired suites run first (R6).

**As rendered at Stage 5 (revision 1, ratified at Collective Review):**
- **D5-1 (#6225):** a sibling check, `core/deploy/tools/check-enumeration-drift.py`, behind a new `deploy.sh --check` block directly after Check 63's, warning on its own committed dial (OD-9); recorded at the tool's module docstring and the check header (CIAC-3).
- **D5-2 (#6227):** the material-edit test (P-A), confidence MEDIUM (OD-1); a decision-record-only release is `version-less` (OD-2); the guide's precedence paragraph and one behavioral-correction `patch` row (OD-4 (A′)); one precedence sentence subordinating `release-planner` Mode B's version step (OD-5 (A′)); population B keyed on the declaration trigger (OD-6 (B)); no ADR, one at-path sentence rejecting the tracked-file test (OD-18). Recorded at `RELEASE_PROTOCOL.md` § Versioning by the operator's commit.
- **D5-3 (#7842):** the band is a parameter, a new `[quality_share_band]` section of `core/config/platform-config.toml.template`; the host is a `--quality-share` mode of `release/tools/compute-release-velocity.sh`; the record is Stage 13 Phase A14.2.
- **D5-4 (#7842, operator):** pooled, with the mean printed beside it; the window is the release log by merge ancestry with a completeness guard (OD-17).
- **D5-5 (#6226, operator):** (B′) decline, with the decision, its reason and its upgrade trigger recorded at `release/releases/notes/README.md`.
- **D5-6 (#6225, operator):** (A′) the #5502 site graded against the existing executor census, with one comment-only citation in `install-tests.yml`.

---

## Dependency Graph

**Native edges: 0.** `blockedBy` 0 and `blocking` 0 on all four cards. Each card's only edge is its native parent, #5867 [SOURCE: GraphQL `blockedBy` / `blocking` / `parent` per card. Same-instrument sensitivity arm: 16 of the 100 most recently updated open issues carry a native edge, e.g. #8562 `blockedBy=8`].

**Prose edges: 0.** The A9.6 reconfirm scan reads `{"CLEAN":4,"NO-SECTION":1}`, with `edge_candidates: []`. The `NO-SECTION` member is #8897, the sub-task, which carries no Dependencies section by template [SOURCE: the published reconfirm `--jq` scan].

```
#6227 ──┐
#6226 ──┼── (no in-bundle edge; all four are native children of epic #5867)
#6225 ──┤      CONDITIONAL edge (Stage 5): #6226's optional index-vs-notes assertion
#7842 ──┘      becomes a #6225 marker instance ⇒ #6225 → #6226-assertion (D5-5)
```

**Cross-milestone:**
- No hard edge.
- #7842's named precondition #8146 shipped in v5.00 releases-file-only-the-follow-ups-that-matter. #5286 shipped in v4.81 [SOURCE: issue state].
- Soft or merge-order neighbours:
  - #6887 (unmilestoned; same mechanism)
  - #7414 (unmilestoned; owns Check 63's red)
  - #6625 (unmilestoned; version-less coverage)
  - #5655 (unmilestoned) and #7256 (ms#424) on `core/CLAUDE.md.template`
  - #5498 and #5499 (ms#363) on the moved note's `links.plan`
  - #7537 (unmilestoned; inflow attribution, not a scaffolding exclusion)
  - #7841 (unmilestoned #5867 child; "a real run and a proven red before done", which this plan's M-4 arms honour)

**Cycles: 0** (no edges). Critical path: none by dependency. The schedule-critical items are the Tier-0 operator limb (#6227) and ms#429's merge, which #7842 rebases onto.

---

## Implementation Sequence

`[RECOMMENDED]` order, Stage 6 serial (P0), one release branch. Every beat is committed and pushed as it completes (write-early):

| Beat | Card | Work | Why here |
|---|---|---|---|
| 0 | — | Engineering Commit 0: plan file `release/releases/plans/obligation-runners-declared_RELEASE_PLAN.md` carrying the Commit-0 Survival Set, the double-brace release-version placeholder in the Header `**Version**` cell, the Commit-0 version re-verify, then `claim-version.sh --verify-stamp obligation-runners-declared` | Procedure 0 § Canonical location |
| 1 | #6227 | Surface requirement in `decision-discipline.md` (reconciled with :489). Register rows with `**Population:**`. **Prepare the finished `RELEASE_PROTOCOL.md` § Versioning replacement text on the #6227 Stage-6 sub-task; the operator commits that floored limb at a hub-scheduled pause after beat 1's push.** The one-line citation in `stage-03-bundle.md` § Release-Identity Mode is committed only once the operator's commit is on the branch (first step of beat 2 if it lands after beat 1), so the citation never points at a rule that is not there | The only operator-executed limb. Leading puts its fixed handoff overhead, and any refusal, at the first spoke |
| 2 | #6226 | `git mv` the note into `notes/_unversioned/`. Repair `RELEASE_INDEX.md`:129. Run the REFCASCADE sweep. Add the adjudication clause in `duplicate-source-discipline.md` and record the release's own resolution (CIAC-4). Register row with `**Population:**` | Small and self-contained; it lands the first `duplicate-source-discipline.md` edit that #6225 then extends |
| 3 | #6225 | Marker convention (home per Stage 5). The check, extending Check 63 or as a sibling (D5-1), with its gate-efficacy declaration, W1, W2 and population. Seeded-mismatch and `subset-of` fixtures. Mark the three sites → **observe drift on all three** → reconcile or cite → observe zero. Register row. `duplicate-source-discipline.md` enumeration instance | The largest card; it runs after both doc-only beats so its `duplicate-source-discipline.md` and register edits land on settled text |
| 3b | #6226 | CONDITIONAL:assertion-adopted — the index-vs-notes structural assertion, as a #6225 marker instance or its own check (D5-5), observed red on a seeded flat version-less note and silent on a flat versioned near-miss | Only if Stage 5 adopts it; it reuses #6225's mechanism when possible |
| — | — | **Rebase onto ms#429 once PR #8821 merges** (it shares `gate-efficacy-standard.md`'s register tail and `docs/module-apis.md`) | Planned rebase point, before beat 4 |
| 4 | #7842 | Band and classification in the Stage-5-chosen home (D5-3). Share computation with the aggregation (D5-4) in the extended read-model. Out-of-band fixture → **observe the flag** → in-band near-miss → observe silence. Register row if its runner is a prose procedure | Shares `compute-release-velocity.sh` and the platform-config surfaces with ms#429; landing it after that merge removes the overlap |
| 5 | — | Release-wide: doc-link check, corpus lint, reference-durability lint, and the CIAC lint on the committed plan | Stage-6 C4 self-verification |

This amends the milestone's recorded internal sequence (#6226 → #6227 → #6225 → #7842) only by moving #6227 to the front (D-Sequence; A-4) `[CHEAP · confidence: HIGH]`.

### Change specifications

Each beat builds its card's Stage-5 revision-1 **Output for Stage 6**, which is that card's change specification and is not restated here: #6227 — `#8917 comment 6865291333`; #6226 — `#8918 comment 6865473339`; #6225 — `#8919 comment 6866289061`; #7842 — `#8920 comment 6866290078`. Under C2 (A) beat 1 runs in three parts: **1a** (Engineering spoke) — Change 1, `core/disciplines/decision-discipline.md` § 3.2 and one G3 sentence, and Change 2, gate-coverage register row A and #6227's Version History row; **the operator's commit** — Change 3, `release/governance/RELEASE_PROTOCOL.md` § Versioning, three insertion-only hunks (+22 / −0, post-apply sha256 `7164cc1c76a85fc6…` at the pin), which no agent writes, stages or applies; **1b** (Engineering spoke) — Change 4, the `stage-03-bundle.md` citation, Change 5, register row B and #6227's final Version History row, and #6226's second `spec-practice-adjudications` record line, run immediately after the operator's commit whenever it lands before the Stage-9 GO (DEV-3).

### Agent-Editability Read

**Derivation.** Controls read at commit `29c60404`.

**Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` carries **2** `case "$ABS_TARGET"` blocks whose arms invoke `always_block "BLOCK-AUTONOMY-001"` (blocks at :725 and :770 of the four `case "$ABS_TARGET"` statements in the file).

Block 1 (anchored) arms, verbatim:
- `"${PRIMARY_ROOT}/CLAUDE.md"`
- `"${PRIMARY_ROOT}/projects/CLAUDE.md"`
- `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"`
- `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"`
- `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"`
- `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"`
- `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"`
- `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"`
- `"${PRIMARY_ROOT}/.claude/settings.json"`
- `"${PRIMARY_ROOT}/.claude/hooks/"*`
- `"${PRIMARY_ROOT}/.claude/rules/"*`

Block 2 (membership) arm, verbatim: `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`

Projected union over tracked paths:
- **Live arms:** `*/OPERATIONS.md` (`core/governance/OPERATIONS.md`, `operations/OPERATIONS.md`) and `*/RELEASE_PROTOCOL.md` (`release/governance/RELEASE_PROTOCOL.md`).
- **`CLAUDE.md` and `*/CLAUDE.md`** match no tracked file today (`git ls-files` → 0 basenames `CLAUDE.md`). They stay live arms: they fire the moment one is tracked.
- **Discarded as outside the repository:** the workspace-root and `projects/` arms, and the three `.claude/` arms (`git ls-files .claude` → 0; same-instrument control `git ls-files core/hooks` → 84).
- **`core/CLAUDE.md.template` is not floored:** its basename is `CLAUDE.md.template`, which neither `*/CLAUDE.md` arm matches.

**Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh`.
- `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`
- Arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`. The failure branch is `exit 0  # not yet gated`. 52 of 57 tracked `SKILL.md` carry the key; `release-planner` does.
- Exemption list resolved at the deployed location: the operator-instance file that `pmo_skill_editor_exemption_list_for` returns for the workspace root two levels above the deployed hook directory (`CLAUDE_WORKSPACE_ROOT` unset). **Present (1 entry: the canary)** [SOURCE: the deployed resolver read by `grep`; the file read directly].

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| Commit 0 | release/releases/plans/obligation-runners-declared_RELEASE_PLAN.md | no | no (conjunct 1 false) | unconstrained | — | ordinary Engineering spoke |
| #6227 | core/disciplines/decision-discipline.md | no | no (conjunct 1 false) | unconstrained | **tier-0-floored** | ordinary Engineering spoke |
| #6227 | release/governance/RELEASE_PROTOCOL.md | **yes** — Block 1 arm `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"` (a worktree under the checkout) and Block 2 arm `*/RELEASE_PROTOCOL.md` (repository membership, for a worktree elsewhere) | not evaluated (Tier-0 precedence) | tier-0-floored | tier-0-floored | **operator-executed**: the agent prepares the finished replacement text, the operator commits it on the release branch, and the agent never uses a hook bypass |
| #6227 | release/references/pipeline/stage-03-bundle.md | no | no | unconstrained | | ordinary Engineering spoke |
| #6227 | core/standards/gate-efficacy-standard.md | no | no | unconstrained | | ordinary Engineering spoke |
| #6227 | CONDITIONAL:stage3-skill-cite — release/skills/release-planner/SKILL.md | no | **yes**: conjunct 1 true, conjunct 2 true, conjunct 3 true (absent from the 1-entry list) | sanctioned-session-required | | sanctioned-session: `pmo-skill-editor` Mode A |
| #6226 | release/releases/notes/_unversioned/governance-ci-checks_RELEASE_NOTES.md (ADD) | no | no | unconstrained | unconstrained | ordinary Engineering spoke (`git mv`) |
| #6226 | release/releases/notes/governance-ci-checks_RELEASE_NOTES.md (DELETE) | — | — | out-of-scope (destructive-control class) | | delivered as the same rename |
| #6226 | RELEASE_INDEX.md · duplicate-source-discipline.md · gate-efficacy-standard.md | no | no | unconstrained | | ordinary Engineering spoke |
| #6225 | core/CLAUDE.md.template | no (basename `CLAUDE.md.template`) | no | unconstrained | unconstrained | ordinary Engineering spoke |
| #6225 | docs/module-apis.md · .github/workflows/install-tests.yml · core/deploy/deploy.sh · duplicate-source-discipline.md · gate-efficacy-standard.md · CONDITIONAL tool, fixture, baseline and allowlist rows | no | no | unconstrained | | ordinary Engineering spoke |
| #7842 | label-taxonomy.md · initiative-roadmap-framework.md · stage-13-close.md · CONDITIONAL read-model, config and fixture rows | no | no | unconstrained | unconstrained | ordinary Engineering spoke |

`unconstrained` means no control refuses the write; it never means the change is ungoverned. **#6227 is partly floored and partly free.** That scope decision is the operator's, at this gate (D-Editability-6227).

---

## Stage Applicability Matrix

| Card | S5 | S6 | S7 | S8 | S9–S13 |
|---|---|---|---|---|---|
| #6225 | APPLY: D5-1 extend-vs-sibling (with #6887 and #7414), marker grammar (`count` / `list` / `subset-of`), W1/W2, population, fixture design, the #5502 remedy (D5-6) | APPLY | APPLY: new check — self-test, the seeded red, the near-miss, the live-site red→zero | APPLY | release-scoped |
| #6226 | APPLY (light): clause wording, `**Population:**` design, D5-5 optional assertion, REFCASCADE plan | APPLY | APPLY (light): doc-link and corpus lint after the move; the assertion's red→silent run if adopted | APPLY | release-scoped |
| #6227 | APPLY: D5-2 rule content (with #6625), surface-requirement scope, two `**Population:**` designs, the operator handoff text | APPLY (agent limbs; operator commits the floored limb) | APPLY (light): durability and link lints on the changed doctrine; a dry run of the AC-5 fixture | APPLY: AC-5 usability run | release-scoped |
| #7842 | APPLY: D5-3 band home, D5-4 aggregation, read-model host, fixture design | APPLY | APPLY: share computation over named releases; out-of-band red and in-band silence | APPLY | release-scoped |

- **Parallel-eligible spokes:** S5 4 · S7 4 · S8 4.
- **Stage 5 activation:** honours the `novel` bias ALL. Every card carries at least one open design question, so the activation criteria in `planning-solutioning-handoff.md` are met [INFERRED: from the D5-* list below].
- **No stage is skipped:** every card changes either a gate, a check or agent-loaded doctrine.

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. The matrix is rendered at the **scope-locked 31-path write set** (`#8917 comment 6866868670`): the 16 planned paths, the 8 CONDITIONAL rows Stage 5 fired, promoted here with their concrete paths (rule 5 of the declared-vs-delivered contract), and the 7 FCM-delta rows the designs admitted as Tier 1 [ADJUST]s (N19). A path shared by cards is listed once, under the first beat that edits it (DEV-11).

```
# ── Engineering Commit 0 ──
release/releases/plans/obligation-runners-declared_RELEASE_PLAN.md  ADD
# ── shared: #6227 #6226 #6225 #7842 (register rows, beat order) ──
core/standards/gate-efficacy-standard.md  EDIT
# ── shared: #6226 #6225 ──
core/standards/duplicate-source-discipline.md  EDIT
# ── #6227 (beat 1) ──
core/disciplines/decision-discipline.md  EDIT
release/governance/RELEASE_PROTOCOL.md  EDIT
release/references/pipeline/stage-03-bundle.md  EDIT
# ── #6226 (beat 2; the note is delivered as a rename) ──
release/releases/notes/_unversioned/governance-ci-checks_RELEASE_NOTES.md  ADD
release/releases/notes/governance-ci-checks_RELEASE_NOTES.md  DELETE
release/releases/RELEASE_INDEX.md  EDIT
release/releases/notes/README.md  EDIT
# ── #6225 (beat 3) ──
core/CLAUDE.md.template  EDIT
docs/module-apis.md  EDIT
.github/workflows/install-tests.yml  EDIT
core/deploy/deploy.sh  EDIT
core/deploy/tools/check-enumeration-drift.py  ADD
core/deploy/tests/fixtures/enumeration-drift-fixtures.txt  ADD
core/config/allowlists/script-execution-allowlist.txt  EDIT
core/deploy/allowlists/count-structure-baseline.txt  EDIT
core/deploy/allowlists/selftest-coverage-manifest.txt  EDIT
core/deploy/tools/README.md  EDIT
core/deploy/tests/test_warn_log_json_escape.sh  EDIT
# ── #7842 (beat 4) ──
core/specs/label-taxonomy.md  EDIT
core/standards/initiative-roadmap-framework.md  EDIT
release/references/pipeline/stage-13-close.md  EDIT
release/tools/compute-release-velocity.sh  EDIT
core/config/platform-config.toml.template  EDIT
core/schemas/platform-config-schema.md  EDIT
docs/platform-config-reference.md  EDIT
release/tools/tests/fixtures/quality-share/out-of-band.json  ADD
release/tools/tests/fixtures/quality-share/boundary-near-miss.json  ADD
release/references/standards/release-velocity-tracking.md  EDIT
```

**How the 31 locked rows map onto the paths above.**

| Locked row class | Rows | Paths above |
|---|---|---|
| Planned at Stage 4 (unconditional) | 16 | the plan file; `gate-efficacy-standard.md`; `duplicate-source-discipline.md`; `decision-discipline.md`; `RELEASE_PROTOCOL.md` (operator-executed); `stage-03-bundle.md`; the note's ADD and DELETE (one rename); `RELEASE_INDEX.md`; `core/CLAUDE.md.template`; `docs/module-apis.md`; `install-tests.yml`; `deploy.sh`; `label-taxonomy.md`; `initiative-roadmap-framework.md`; `stage-13-close.md` |
| Fired CONDITIONAL (promoted) | 8 | `c63-sibling` ×2 — the tool, resolved to `check-enumeration-drift.py`, and the `enumeration-markers/` fixture directory, refined by #6225 to the one case file `enumeration-drift-fixtures.txt` (the same deliverable as FCM-delta row 1, so it is listed once); `new-script` — `script-execution-allowlist.txt`; `band-in-velocity` — `compute-release-velocity.sh`; `band-as-parameter` ×3 — the platform-config template, its schema and its reference; `band-fixtures` — `release/tools/tests/`, narrowed by #7842 to the two fixture files |
| FCM delta (Tier 1 [ADJUST]) | 7 | #6226: `release/releases/notes/README.md` · #6225: `enumeration-drift-fixtures.txt`, `count-structure-baseline.txt`, `selftest-coverage-manifest.txt`, `core/deploy/tools/README.md`, `test_warn_log_json_escape.sh` · #7842: `release-velocity-tracking.md` · #6227: none |

**Operator-executed row.** `release/governance/RELEASE_PROTOCOL.md` is Tier-0-floored (BLOCK-AUTONOMY-001). The operator commits it on this branch from the finished patch posted in `#8917 comment 6865291333` (Change 3); no agent writes, stages or applies it, and no hook bypass is used.

#### Release-wide explicit non-scope

```
core/governance/OPERATIONS.md  NOT EDITED
core/deploy/tools/check-milestone-epic-membership.py  NOT EDITED
core/standards/template-protocol.md  NOT EDITED
release/releases/plans/v4/v4.12_RELEASE_PLAN.md  NOT EDITED
core/hooks/block-destructive.sh  NOT TOUCHED
```

**Stage-4 CONDITIONAL rows Stage 5 resolved not-fired** (each condition resolved false, so each path is not edited; rule 5 of the declared-vs-delivered contract):

```
core/deploy/tools/check-count-structure.py  NOT EDITED
core/deploy/tools/run-count-structure-fixtures.sh  NOT EDITED
core/deploy/tests/fixtures/count-structure-fixtures.txt  NOT EDITED
core/standards/enumeration-marker-convention.md  NOT EDITED
release/skills/release-planner/SKILL.md  NOT EDITED
packages/release-planner.skill  NOT EDITED
packages/release-planner.skill.sha256  NOT EDITED
release/tools/automated-closeout.sh  NOT EDITED
core/deploy/tools/check-doc-gates.py  NOT EDITED
.github/workflows/release-tooling-smoke.yml  NOT EDITED
release/ADRs/README.md  NOT EDITED
```

The not-fired condition tokens, in Stage-4 order: `c63-extend` (three rows; D5-1 chose the sibling), `marker-own-standard` (the marker convention lands in an existing standard, `duplicate-source-discipline.md` § 1.1), `stage3-skill-cite` (three rows; OD-5 (A′), no skill edit), `band-in-closeout` (two rows; #7842 eliminated Rα and H3), the `band-fixtures` workflow row (the selftest-discovery job already discovers the tool's `--self-test`), and `stage5-adr` (two rows; OD-18, no ADR — the `release/ADRs/ADR-NNN-*.md` placeholder is not listed above, because no ADR is authored). Twelve not-fired rows plus eight fired rows account for the Stage-4 plan's twenty conditional rows.

**New-executable companion obligation.** Any new `*.sh` (or a new `*.py` invoked through an interpreter) carries its `core/config/allowlists/script-execution-allowlist.txt` rows under `CONDITIONAL:new-script`, in all four invocation forms the Check 63 primitive's rows already use (lines 1207–1210). **CI wiring:**
- A tool under `core/deploy/tools/` or `release/tools/` that dispatches on `--self-test` is run by the `selftest-discovery` job in `release-tooling-smoke.yml` by discovery, not by roster. Its `# scope:` globs cover `release/tools/*.sh`, `release/tools/*.py`, `core/deploy/tools/*.py` and `core/deploy/tools/*.sh` [SOURCE: that workflow's header].
- So #6225's primitive (extended or sibling) and a #7842 read-model under `release/tools/` are CI-exercised through their `--self-test`, and a sibling primitive must ship one.
- The corpus run itself — the check over the live tree — stays deploy-time only, as Check 63's does today (no CI workflow runs the full `--check` suite; Check 63 header). Stage 5 states that boundary in the new check's declaration.

**Deliverable domain:** `governance`, with `software` secondary. **Deliverable state:** every edited file reaches `deployed-copy-synced` at Stage 12 or declares no propagation target (§ Operational Deployment Manifest); this file is the release's own record.

---

## Contention Map

**Within-release** (ADR-005 `overlap_class`, projected from the write sets above; this release has no branch yet):

| File | Writers | overlap_class | Resolution |
|---|---|---|---|
| `core/standards/gate-efficacy-standard.md` (register tail, after :403) | #6227, #6226, #6225 (+ #7842 if prose) | append-pattern within the release, serialized one beat each | P0 order (beats 1→2→3→4); each beat appends its rows after the last |
| `core/standards/duplicate-source-discipline.md` | #6226 (adjudication clause), #6225 (enumeration instance) | append-pattern (distinct clauses) plus one semantic seam (opposite default authority) | beat 2 then 3; CIAC-1 grades the seam |
| `core/deploy/deploy.sh` | #6225 (+ #6226 if D5-5 makes its assertion a deploy check) | single-pr unless D5-5 | — |
| `release/references/pipeline/stage-13-close.md` | #7842 | single-pr | — |

Probe record: writer sets come from the per-card write sets (4 cards; 16 unconditional and 20 conditional paths). Sensitivity arm: `gate-efficacy-standard.md` carries 3 unconditional writers. Specificity: `stage-03-bundle.md` carries exactly 1 (#6227) [SOURCE: the FCM above].

**REFCASCADE pre-count for #6226's move** (rename-reference-cascade § 2; the post-count is owed at beat 2):

`[REFCASCADE: git grep -n -F "governance-ci-checks_RELEASE_NOTES" over all tracked files → pre 2 (RELEASE_INDEX.md:129 live link; v4/v4.12_RELEASE_PLAN.md:209 terminal, preserved by rule) / post owed at beat 2]`

The slug form `governance-ci-checks` has 29 hits in 13 files, all read and classified as not-a-path-reference to the note: the release log, the digest, the archive log, the plan's own metadata, a test fixture title and a family-slug test. One form no in-repo checker reads is the note's own frontmatter `links.plan`, which names `release/releases/plans/governance-ci-checks_RELEASE_PLAN.md`. That path is unchanged by the move, and ms#363's #5498 and #5499 own it [SOURCE: this run's sweep].

### Parallelization Map (as applied to the milestone by [ADJUST] A-3)

**Verdict:** Tier-B soft-coupled, plus Tier-S version and merge-order edges; no hard blocking dependency.

| Other milestone | Direction | Edge type | Body confirmation |
|---|---|---|---|
| release-usage-measured-right (ms#429) | other → this (ahead; merge first) | file-contention + Tier-S version | Draft PR #8821 shares `gate-efficacy-standard.md` (register tail, line-range-overlap) and `docs/module-apis.md` (disjoint). Conditionally it also shares `compute-release-velocity.sh` and the platform-config trio. Both releases are minor and both compute next-free v5.08 [SOURCE: allocator dry-run]. Rebase after its merge |
| script-guard-reads-every-token-as-the-shell-does (ms#439) | bidirectional | Tier-S version only | Its cards name `core/hooks/block-destructive.sh`, its test and `bypass-mode-readiness/` fragments: 0 of this FCM. Both are minor (v5.08). It keeps merge priority on a same-day tie [CONTEXT: hub brief] |
| script-guard-refuses-only-what-executes (ms#440) | bidirectional | Tier-S version only | Same file family as ms#439, 0 of this FCM; minor; ships after ms#439 [SOURCE: its description] |
| plan-corpus-identity-and-pointers (ms#363) | bidirectional | Tier-S merge-order (F3 `links.plan` of the moved note) | #5498 relocates the plan the note names; #5499 rewrites `links.plan` pointers across the notes corpus. Whichever lands second re-reads the note's path |
| comms-drafts-send-ready (ms#424) | merge-order | file-contention | #7256 adds a pointer to `core/CLAUDE.md.template`, which #6225 edits at :211 |

Unmilestoned neighbours (not milestones, recorded for completeness): #5655 (`CLAUDE.md.template` ≤200 lines; merge-order), #6887 (same mechanism; coordinate at Stage 5), #7414 (Check 63's red).

`version-axis: minor → provisional v5.08 (allocator dry-run, 2026-11-13).` The reconfirm procedure is the A9.6 block verbatim (Stage 3 shard), run here with result `CLEAN 4 · NO-SECTION 1 (#8897)`.

---

## Cross-PR Overlap Audit

### Baseline SHA

- **Stage-4 baseline pin:** `29c604045def22ebd21fb4a758c3bb56be277b20` (the merge of PR #8844), fetched 2026-11-13T15:53Z, recorded at Stage-4 Phase A0 as `rows_source: phase-a0-native`, `baseline_pin: origin/main @ 29c60404`.
- **Commit-0 base:** `29c604045def22ebd21fb4a758c3bb56be277b20` — `origin/main` had not moved when this file was written (`git fetch origin main` at Commit 0). The Stage-9 A6.5 divergence re-check reads from the Stage-4 pin.

### Stage-4 overlap audit (as planned)

**Baseline SHA:** `29c60404` (2026-11-13T15:53Z).
- **Open PRs:** 1, cross-checked by two instruments (`gh pr list --state open --limit 500` → 1; REST `pulls?state=open` → 1).
- **#8821** (ms#429 `release-usage-measured-right`, draft, head `8974f500`, merge-base = `29c60404`): 47 files [SOURCE: `pulls/8821/files`, paginated].
  - **∩ unconditional FCM = 2:**
    - `core/standards/gate-efficacy-standard.md` — #8821 inserts a register row after :403 and edits :459, :482 and :661. Our rows append after :403 too, so this is **line-range-overlap at one insertion point** and a conflict on rebase. Resolution: rebase after #8821 merges, and place our rows after its row.
    - `docs/module-apis.md` — #8821 inserts 7 lines after :157 and we edit :165 onward: **append-pattern** (disjoint, 8 lines apart). Rebase second.
  - **∩ CONDITIONAL FCM = 7:** `compute-release-velocity.sh` (+1365), `platform-config.toml.template` (+98), `platform-config-schema.md`, `docs/platform-config-reference.md`, `script-execution-allowlist.txt` (+16 after :673), `release-tooling-smoke.yml` (+155), `release/ADRs/README.md`. All resolve by #7842 (and any #6225 script) landing after the rebase.
  - Sensitivity arm: the intersection is non-zero (2). Specificity: #8821 ∩ `core/hooks/block-destructive.sh` = 0.
  - #8821 also edits `core/deploy/tests/test_lib_instance_path.sh`, one of #6225's 6 unwired suites, without wiring it (0 `test_*.sh` added to any workflow in its diff). So the #5502 site count is unchanged by it.
- **Sibling-merge re-check:** `git log 29c60404..origin/main --name-status --find-renames` → 0 lines at 2026-11-13T16:01Z, so the pin holds [SOURCE].
- **Structural blast radius (A4 sub-audit):**
  - Mover set = 1 R row: `release/releases/notes/governance-ci-checks_RELEASE_NOTES.md` → `release/releases/notes/_unversioned/…`, directory-crossing.
  - SURFACE(R) = {`release/releases/RELEASE_INDEX.md` (F1 link), `release/releases/plans/v4/v4.12_RELEASE_PLAN.md` (F2 inline path, terminal), the note's `links.plan` field (F3 frontmatter)} ∪ {`Δversion/minor@v5.08`}.
  - EDITSET(#8821) ∩ SURFACE(R) on paths = ∅. Its post-merge Stage-13 chore will edit `RELEASE_INDEX.md` near the top (new rows), disjoint from :129 [INFERRED: from the INDEX's newest-first layout].
  - ms#363 (#5498 moves the plan `links.plan` names; #5499 rewrites `links.plan` pointers) intersects the F3 form → **Tier-S merge-order edge** (no branch in flight today).
  - The version token is shared with ms#429, ms#439 and ms#440 → Tier-S version edges, serialized at the atomic claim.

### In-Flight Release Roster

**Stage-4 measurement (transcribed):**

**Measured at:** `29c60404` · `2026-11-13T16:01:47Z` · **Population:** n=1 sibling

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `release-usage-measured-right` | `#8821` (draft) | `8974f500` | `minor` | `v5.02` (its plan's provisional display, now claimed) | `v5.08` | `core/standards/gate-efficacy-standard.md`, `docs/module-apis.md` (+7 CONDITIONAL) |

Population: open PRs with a `release/*` head (1) plus remote `release/*` heads with no open PR (0). `git ls-remote --heads origin 'release/*'` → 1 head [SOURCE]. ms#439 and ms#440 have no branch and no PR, so they are not in flight [SOURCE: same read].

**Commit-0 re-measurement.** **Measured at:** `29c60404` · `2026-11-13T23:13Z` · **Population:** n=5 sibling(s) (open pull requests with a `release/*` head, drafts included, 5; remote `release/*` heads without a pull request, 0; this release excluded).

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `release-usage-measured-right` | `#8821` (draft) | `8974f500` | `minor` | `v5.02` (stale) | `v5.08` | 8 paths: `core/standards/gate-efficacy-standard.md` and `docs/module-apis.md` (the Stage-4 unconditional pair); `release/tools/compute-release-velocity.sh`, `core/config/platform-config.toml.template`, `core/schemas/platform-config-schema.md`, `docs/platform-config-reference.md` and `core/config/allowlists/script-execution-allowlist.txt` (fired CONDITIONAL rows); `release/references/standards/release-velocity-tracking.md` (#7842's FCM-delta row) |
| `engineering-harness-pages-published` | `#8983` (draft) | `016dc32b` | `minor` | `v5.08` | `v5.08` | 3 paths, all #6225's: `core/deploy/allowlists/selftest-coverage-manifest.txt` and `core/deploy/tools/README.md` (FCM-delta rows 3 and 4) and `core/config/allowlists/script-execution-allowlist.txt` (the fired `new-script` row) — merge-order pairs, regenerated or re-read after whichever merges first |
| `deletion-guard-judges-every-segment-and-target` | `#8992` (draft) | `72a83bae` | `minor` | `v5.08` | `v5.08` | — |
| `script-guard-reads-every-token-as-the-shell-does` | `#8993` (draft) | `26e4bf65` | `minor` | `v5.08` (provisional display) | `v5.08` | — |
| `never-invoked-specialists-dispositioned` | `#8994` (draft) | `7b49940d` | `UNRESOLVABLE` (declared `version-less`; no bump-class) | — | `UNRESOLVABLE` (claims no slot) | — |

Counts are from each pull request's file list (`gh api --paginate repos/<owner>/<repo>/pulls/<N>/files`) intersected with the 31 paths above; files listed per pull request at measurement: #8821 47, #8983 91, #8992 10, #8993 4, #8994 2. Bump-class and carried label are read from each sibling's milestone `Release-identity mode:` line and, where the milestone carries none (ms#437), from its plan file's Header. The recomputed next-free is the allocator's `minor` result at this base (one `--dry-run`, above), which every `minor` sibling shares. The roster records a measurement only; Stage 9 A6.6 renders the verdict. The difference from the hub's Stage-6 brief is DEV-12.

---

## Risk Register

| ID | Risk | Sev | Owner | Mitigation |
|---|---|---|---|---|
| R1 | #6227 AC-3's home `RELEASE_PROTOCOL.md` is Tier-0-floored, so an agent cannot write it. If the operator limb is late or skipped, AC-3 is unmet at Stage 8. Twice before (v4.32, v4.60) the limb did not land in-release | MED | operator | D-Editability-6227 (A); beat-1 lead; finished text on the Stage-6 sub-task; the `stage-03-bundle.md` citation is committed only after the operator commit; the miss path is in D-Editability-6227 |
| R2 | `gate-efficacy-standard.md` is the hottest file in scope (120 commits since 2026-08-28). Draft #8821 appends at the same register insertion point (after :403), and 3–4 cards in this release append there too | MED | hub + Stage-6 spokes | P0; one beat per card; planned rebase after #8821 merges; Stage-9 A6.5 re-check |
| R3 | Check 63 is red on `main` (6 FAIL rows at `29c60404`, owned by #7414). `deploy.sh --check` exits non-zero regardless of this release, so its exit status cannot grade #6225 AC-5, and an arm added to Check 63 inherits a red, enforcing base | MED | Stage-5 spoke (#6225) | Verification reads the new check's own rows; D5-1 records the mode resolution for a warn-start arm at the code path |
| R4 | A named-gap population defined as "created after this row's merge" is empty at this release's own Stage 13. G-CL10 arm (i) then passes only with an open owning work item outside the release; otherwise it FAILs (warn-mode) | MED | Stage-5 spokes (#6226, #6227); Stage-13 spoke | Define each population so this release's own artifacts are members (CIAC-3 and CIAC-4 make them so), or name #5867, the open parent epic, as the owner and post the record on it |
| R5 | No `**Limb owners:**` line: G-CL10 arm (ii) FAILs at this release's own close, because the composition lock (2026-11-13) postdates the line becoming required (2026-10-29) | MED | operator (approve) / hub (apply) | D-Outcome; [ADJUST] A-1 |
| R6 | #6225's #5502 remedy (discover suites, or wire the 6) turns unrun suites on in CI. Their pass state is unmeasured | MED | Stage-5 spoke (#6225) | Run the 6 suites locally at Stage 5 before choosing the remedy, and disposition any red suite per suite rather than silently re-skipping it |
| R7 | The band's aggregation swings: per-release shares over the last 8 closed releases range 0–100%. Over the last five, the mean of shares is 47% and the pooled share 38%, so the first real measure reads **above the 35% ceiling** either way | MED | operator | D5-4 at Stage 5; the out-of-band flag is expected to fire on first run and is not a defect |
| R8 | #7842's likely hosts (`compute-release-velocity.sh`, the platform-config trio) are rewritten by #8821 | MED | hub | #7842 is beat 4, after the rebase; Stage 5 reads #8821's head, not `main` |
| R9 | The version slot is contended by ms#429, ms#439 and ms#440, all minor | LOW | Stage-12 executor | Slug-primary identity; Commit-0 re-verify; atomic claim with `--stamp-slug` |
| R10 | The note move breaks a reference no checker reads (frontmatter, prose, tool globs) | LOW | Stage-6 spoke (#6226) | REFCASCADE sweep pre/post over every form; doc-link and corpus lint at S7; ms#363 merge-order recorded |
| R11 | Marker sprawl, or false drift on intentional subsets | LOW | Stage-5 spoke (#6225) | The card's own mitigations: mark only moving populations; a `subset-of` near-miss fixture |
| R12 | #6227's rule changes agent behaviour at version-claim time before anything observes it | LOW | Stage-5 spoke (#6227) | Guidance first: a named-gap row with a declared observable; G3-19 still checks validity only (card) |
| R13 | `core/CLAUDE.md.template` merge-order with #5655 and #7256 (no branch in flight) | LOW | hub | Whichever lands second rebases; #5655 may relocate the bullet, so re-read before rebasing |
| R14 | Mode R deltas carried blind: three of its card deltas are stale, and its D3 cells forced a cache MISS | LOW | hub | Apply only the [ADJUST] list below; the Mode R conformance defect is routed |
| R15 | Rollback spans an operator-committed floored file and a moved corpus file | LOW | operator | One merge revert restores both (Rollback strategy); tag retained |

---

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#6225 × #6226 on `core/standards/duplicate-source-discipline.md`):** the file states the two divergence cases with their opposite default authority: an enumeration that drifts from its population is reconciled toward the population, and a written convention that diverges from live practice is resolved toward the side the spec names. Neither clause's resolution rule is stated as governing the other's case. *Method:* declared, verification deferred to #6225 AC-1 and #6226 AC-3. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#6225 × #6226 × #6227 on `core/standards/gate-efficacy-standard.md`):** every gate-coverage register row this release adds whose Surface cell leads with `prose` carries a `**Population:**` declaration of the form the standard states, and no row this release adds is relabelled away from `prose` to avoid one. *Method:* declared, verification deferred to core/standards/gate-efficacy-standard.md (the added rows, listed by the G-CL10 engine's list mode on the release PR). *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#6225 × #6227 × #7842 on the constrained code paths):** every Stage-5 determination this release renders that constrains a code path — #6225's extend-or-sibling choice, and #7842's band-value home and aggregation — is recorded at the path it constrains (the check's header or module docstring, or the governing spec section), not only in a Stage-5 comment, as #6227's surface requirement requires. *Method:* declared, verification deferred to #6227 AC-1, #6225 AC-2 and #7842 AC-1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#6226 × #6227 on the governance-ci-checks relocation record):** the release's own spec-versus-practice resolution — moving the flat note toward the placement `release-notes-standard.md` names — is recorded on a durable surface that names which side changed and why, as #6226's adjudication clause and #6227's surface requirement both require, and not only in a sub-task comment or the PR body. *Method:* declared, verification deferred to #6226 AC-3 and #6227 AC-1. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#6225 × #7842 on the release's new runners):** every runner the release adds ships a seeded fixture it must flag and a near-miss it must not flag, and the release plan's Verification Evidence records each fixture's observed failing run before the passing run. *Method:* declared, verification deferred to #6225 AC-3 and #7842 AC-4. *Graded at Stage 9 QC3.5 on the merged PR.*

Lint record (`bash release/tools/verify-release-plan.sh --ciac-lint` on this draft, rc 0): `CIAC-LINT-SUMMARY declared=5 parsed=5 clean=0 declared-deferral=5 flagged=0`. Sensitivity arm: a seeded copy with CIAC-5's method rewritten as prose → `CIAC-5 FLAG no-runnable-command`, `flagged=1`, rc 3. Every CIAC is graded from the evidence its declaration names, one per-issue criterion per spanned issue or a repository path.

---

## Verification Plan

**AC baseline** (read at `29c60404`, 2026-11-13): #6225 6 · #6226 4 · #6227 5 · #7842 4 — 19 criteria, 5 of them discharged at bundling. Control: the sub-task body counts 0 [SOURCE: the checkbox parse of each body's Acceptance Criteria section].

`ac_baseline: { #6225: 6, #6226: 4, #6227: 5, #7842: 4, read_at: 29c604045def22ebd21fb4a758c3bb56be277b20 }`

Re-read at Engineering Commit 0 against the cards' current bodies: the same four counts (6 · 4 · 5 · 4 = 19), so the ordinals the rows below bind to are unchanged.

**Evidence shape (M-4): red before green, per runner.**
- #6225's check is observed failing twice before it is shown passing. (1) The seeded mismatch fixture must produce a drift row. (2) The three live sites, once marked and before they are reconciled, must produce 3 drift rows (a real red). The `subset-of` near-miss must produce 0 rows, and the reconciled sites 0.
- #7842's out-of-band flag must fire on a seeded fixture whose share lies outside the band, and stay silent on an in-band near-miss at the boundary. The first real measure (above the ceiling today, R7) is a second, real red.
- #6226's optional assertion, if adopted, must flag a seeded flat version-less note (and the live note before the move), and stay silent on a flat versioned near-miss.
- A declared runner with no observed red is recorded as a claim, not as evidence.

**Stage-13 population records (M-3):** one A14.1 block per added `prose` row. Planned names, defined at Stage 5:
- `spec-practice-adjudications` (#6226 AC-3) — its first member is this release's governance-ci-checks resolution.
- `constraint-determinations-at-path` (#6227 AC-1) — its first members are D5-1, D5-3 and D5-4.
- `release-identity-rule-citations` (#6227 AC-3) — this population may be empty at close; owner #5867 if so.
- A #7842 row only if its runner is a prose procedure.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #6225 | AC-1 | `grep -c -F "enumerates:" core/standards/duplicate-source-discipline.md` at least 1 [READER-GRADED — the convention defines `count`, `list` and `subset-of` and its source binding; rebind the path if D5-1 or the marker home picks another file] | defined (baseline 0) |
| #6225 | AC-2 | `grep -c -F "# gate-efficacy:" core/deploy/deploy.sh` at least 6 [READER-GRADED — invariant, falsification, W1 sink, W2 exit evaluable from committed state, declared population] | declaration present (baseline 5 lines) |
| #6225 | AC-3 | declared, verification deferred to Stage 7 (runs the check against the seeded mismatch fixture, then the subset-of near-miss, then the marked live sites before and after reconciliation) | 1 drift row · 0 rows · 3 rows then 0 |
| #6225 | AC-4 | `git diff --name-only origin/main...HEAD -- core/CLAUDE.md.template docs/module-apis.md .github/workflows/install-tests.yml` expect 3 [READER-GRADED — each site is a marker that resolves clean, or a citation] | 3 changed paths · control: the same instrument with pathspec release/releases/plans → at least 1 once Commit 0 lands |
| #6225 | AC-5 | declared, verification deferred to Stage 8 (runs deploy.sh --check at the release head and reads the new check's DENOM, drift and control rows; never the run's exit status, which Check 63's existing red keeps non-zero) | zero drift over N markers, control arm firing in the same run |
| #6225 | AC-6 | declared, verification deferred to Stage 8 (reads the four superseded observations' state and supersession comments) | discharged at bundling |
| #6226 | AC-1 | `grep -c -F "Neither supersedes the other" core/standards/template-protocol.md` at least 1 | 1 (discharged; observed 1 at the pin) |
| #6226 | AC-2 | `test -f release/releases/notes/_unversioned/governance-ci-checks_RELEASE_NOTES.md` [READER-GRADED — every version-less RELEASE_INDEX row has its note under notes/_unversioned/, and the REFCASCADE post-count is 0 on live forms] | exists (baseline: absent, rc 1; the flat note present, rc 0) |
| #6226 | AC-3 | `grep -c -i -F "adjudicat" core/standards/duplicate-source-discipline.md` at least 1 [READER-GRADED — names the authoritative side; resolves toward the spec where the spec names it; declares a runner or a named-gap row with its observable and population] | clause present (baseline 0; same-file control `register-or-remove` → 5) |
| #6226 | AC-4 | declared, verification deferred to Stage 8 (reads #3922 and #5194, each closed as superseded and linked to this issue) | discharged at bundling |
| #6227 | AC-1 | declared, verification deferred to Stage 8 (reads decision-discipline.md at the final head for the surface requirement, its negative case and its reconciliation with the citation rule at :489, plus its register row) | requirement, negative case, reconciliation and register row present (baseline: 0 hits for the three probe phrases) |
| #6227 | AC-2 | `grep -c -F "M3_SCAN" core/deploy/tools/check-milestone-epic-membership.py` at least 1 | 9 at the pin (discharged) |
| #6227 | AC-3 | declared, verification deferred to Stage 8 (reads RELEASE_PROTOCOL.md § Versioning at the final head, after the operator-committed limb, and its one-line citation in stage-03-bundle.md § Release-Identity Mode) | rule beside the enum and the guide; citable in one line; register row present |
| #6227 | AC-4 | declared, verification deferred to Stage 8 (reads both superseded observations) | discharged at bundling |
| #6227 | AC-5 | declared, verification deferred to Stage 8 (runs the Stage-3 identity-mode declaration step against the fixed three-card fixture #6225, #6226, #6227 and reads the declared line) | mode matches the rule's verdict; the line cites the rule |
| #7842 | AC-1 | declared, verification deferred to Stage 8 (reads the surface D5-3 selects for the floor, the ceiling and the judgment window) | 15% floor, 35% ceiling, rolling five-release judgment, re-set after three measured releases |
| #7842 | AC-2 | declared, verification deferred to Stage 8 (reads the classification in that same surface) | the 2026-11-05 rule transcribed verbatim in substance |
| #7842 | AC-3 | declared, verification deferred to Stage 7 (re-runs the share computation from labels alone for the last three closed releases) | a number per release (Stage-4 baseline: ms#441 1 of 1, ms#411 1 of 3, ms#438 3 of 3) |
| #7842 | AC-4 | declared, verification deferred to Stage 7 and this release's own Stage-13 record (out-of-band fixture first, then the in-band near-miss) | flag fires on the fixture, silent on the near-miss; unlabelled items reported as their own count |

### Release-Level Verification

The release-wide checks the Implementation Sequence's beat 5 names, run at Stage 6 C4 and re-run at Stage 7, are recorded in § Verification Evidence as each runs: the doc-link check (`deploy.sh --check` Check 14), the release-corpus lint, the reference-durability lint over the changed durable-corpus files, `verify-release-plan.sh --ciac-lint` on this file, and `verify-release-plan.sh` on this file.

---

## Delivery Strategy

- **Branch and PR:** `release/obligation-runners-declared` (slug-primary), one release PR (D-C SINGLE). The PR body uses `References #N` in its Issue References block, never a close-family verb, and the commit-message close-keyword check runs before every push.
- **Operator limb:** the #6227 `RELEASE_PROTOCOL.md` § Versioning text is posted as finished replacement text on the #6227 Stage-6 sub-task. The operator commits it on the release branch between beats 1 and 2. Stage 8 grades AC-3 against the committed text.
- **Rebase:** onto `origin/main` once draft PR #8821 (ms#429) merges, before beat 4. The Stage-9 A6.5 divergence re-check reconfirms the pin.
- **Stage 12:** atomic version claim (minor) with `--stamp-slug obligation-runners-declared`. If Stage 5 authors an ADR: `renumber-adr.py --detect`, then `--stamp`.
- **Stage 13:** a `#### Population record — <name>` block (A14.1) for every `prose` register row this release adds, plus G-CL10 arm (ii) over the revised `**Limb owners:**` line. #7842's own read-model reports this release's share as its first real output.
- **Card closure:** mark #6225, #6226, #6227 and #7842 as closed at Stage 13, through the release PR's Issue References block.

---

## Rollback Strategy

- Revert the release-PR merge. The note returns to `notes/` and `RELEASE_INDEX.md`:129 with it. The new check and the band read-model ship advisory or warn-mode, so a revert removes advisory output only.
- The `RELEASE_PROTOCOL.md` limb reverts with the merge. The revert is operator-authorized per RELEASE_PROTOCOL.md § Rollback protocol, which already holds for every release.
- The version tag is retained and the rollback recorded (§ Tag Retention). A merged ADR, if Stage 5 adds one, is superseded, never deleted.
- Population records and Stage-13 rows already written stay as history.
- Reversibility of the whole release: **MODERATE** — one revert; the moved note's path is cited by a sibling's pending `links.plan` edits.

---

## Quota Budget

**Verdict:** WARN, on basis `UNSTATED` (conservative default, per `quota-budget-protocol.md` Checkpoint A) [ASSUMPTION – CONFIRM]
**Parallel-eligible spokes per parallel stage (from A2 Stage Applicability Matrix):** Stage 5: 4 · Stage 7: 4 · Stage 8: 4
**Per-spoke cost estimate:** size-bucket ordinal band (heuristic, § 5): #6225 at moderate–high (size:L); #6226, #6227 and #7842 at low–moderate (size:M).
**Assumed/stated remaining usage-window envelope:** UNSTATED — no quota state was passed to this spoke [CONTEXT: hub brief].
**Estimated cumulative draw % (worst parallel batch):** not synthesized (§ 6.1). The worst batch is Stage 5: 4 spokes, one at L.
**Routing:** WARN → window-aware timing, with the batch split to the `UNSTATED` wave width (`W_max` 2, § 4.3c). Stage 5 runs as two sub-waves: (#6225, #6226) first, because they share `duplicate-source-discipline.md` and D5-5 couples them; then (#6227, #7842). Stage 7 and Stage 8 run as two sub-waves of 2 each.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — and it is the load-bearing runtime check: PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave, PROCEED/DEFER for a singleton. STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API axis, combined DEFER-dominant (§ 4.3b); Checkpoint A stays usage-window-only (§ 3.1). Bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

## Release Class declaration

**Proposed:** `novel` — the trigger evidence from the 2026-09-27 rendering still holds [SOURCE: `release-class-taxonomy.md` § Class Enum, re-evaluated against this plan].

- **Fires — novel (b):** this plan carries D-class decisions (D5-1 through D5-6, owned by Stage 5).
- **Conditional — novel (a):** fires if Stage 5 creates a new reference doc or schema (`CONDITIONAL:marker-own-standard`). **novel (c)** fires if Stage 5 authors an ADR.
- **Routine — does not fire:** (a) #6225 and #6227 are P2, and #6225 is L. (c) The release adds files (the note at its new path, fixtures). (d) It carries D-class decisions.
- **Cross-cutting — does not fire today; a watch item for Stage 5:**
  - (a) Two `pipeline/stage-*.md` files are projected (stage-03, stage-13); a third would fire it.
  - (b) Two of the six rule-defining surfaces are projected: `RELEASE_PROTOCOL.md`, and `CLAUDE.md` through its tracked template. A third (`gate-criteria-spec.md`, `release-process.md`, `hub-spoke-bridge.md` or `OPERATIONS.md`) would fire it.
  - (c) The release has 0 in-bundle edges.
  - **If cross-cutting fires, effective points become 20 × 1.3 = 26, above the 25 ceiling.** That would be a re-bundle conversation, not a silent reclassification.
- **Differentiation posture:** Engagement density **Standard** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day**.

---

## Release Outcome Statement

Approved at the Stage-4 gate (D-Outcome (A)) and applied to the milestone description by [ADJUST] A-1.

**AFTER:** A declared governance obligation either has a runner or a recorded decision that it will not: hand-maintained enumerations are reconciled against the populations they describe, a convention that diverges from live practice names which one governs, and a determination that constrains a code path is recorded where the code reads it. The standing quality initiative's capacity band is recorded in a governed surface, and each release close-out reports the measured share against that band and flags a measure outside it.

**BEFORE:** Enumerations drift silently from their populations, a written convention and live practice disagree with no rule naming the authority, and determinations that bind code live only in prose the code never reads. The quality initiative is declared as measured against a floor, yet no floor is set and nothing measures the share.

**Actor(s):** platform engineering session; the Stage 13 close-out for the band measure.

**Success Indicator:** every member's own acceptance signal verified at Stage 8, with each runner this release adds observed failing on a seeded fixture before it is shown passing; one PR.

**Limb owners:** enumerations reconciled against their populations → #6225 · convention-vs-practice authority named → #6226 · constraining determinations recorded where the code reads them → #6227 · the quality band set and measured → #7842

---

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|---|---|---|---|
| 1 | `core/CLAUDE.md.template` | the rendered workspace charter | the operator's next composition refresh, outside this release (#6225's Stage-5 Blast Radius names it the one out-of-repo consumer of the :211 change) | the rendered charter carries the citation that replaces the five-value bullet |

Every other edited path is a corpus, tool, check or fixture file read in the repository, so it has no Layer-2 propagation target. Enumerated over the classes {skill package, rules-mirror member, hook-tier file, harness artifact, operator-instance configuration}: no skill package is rebuilt (`CONDITIONAL:stage3-skill-cite` did not fire); no `core/rules/` file is edited, so no mirror member changes; no hook is edited; no harness artifact is touched; and the operator-instance `platform-config.toml` receives no write — an instance without the new `[quality_share_band]` section reads `NOT-EVALUATED` under #7842's absent-value contract, never a default (`#8920 comment 6866290078`).

### Schema Migrations

N/A — enumerated over the classes {data-schema change, frontmatter-schema change, config-key change, log-record shape change}. One config-key addition is present: #7842's `[quality_share_band]` section in the platform-config template, documented in `core/schemas/platform-config-schema.md` and `docs/platform-config-reference.md` in the same release; it needs no migration, because an instance that lacks it reads `NOT-EVALUATED` rather than failing.

### Memory Evictions

N/A — enumerated over the classes {memory eviction, memory re-point}; none present in this release (no card is a codification card tied to an auto-memory entry).

---

## Deviation Log

Ten inherited rows carry the four designs' Commit-0 entries, renumbered in beat order (#6227, #6226, #6225, #7842) and each citing its source comment. DEV-11 to DEV-13 are the Commit-0 spoke's own entries, and every row after them was added by the beat or the pass its Stage cell names. No transcribed plan text is reworded to absorb a correction (N18).

| ID | Stage | Deviation | Basis |
|---|---|---|---|
| DEV-1 | 6 (Commit 0) | The Stage-4 plan states that ms#445 shows `version-less` "is now chosen where a release changes no tracked file" (Phase A0, the #6227 AC-3 row's D3 cell; [ADJUST] A-8, the Proposed Change 3 parenthetical). Corrected value: `version-less` is chosen where the change set is **record-only** (a decision record, plan or ADR). Both live cases change tracked files (PR #8814). The card body was corrected at Collective Review; the plan keeps its Stage-4 text | `#8917 comment 6865291333` (#6227 Stage-5 revision 1, Commit-0 deviation-log entries), entry DL-6227-1 |
| DEV-2 | 6 (Commit 0) | The Stage-4 census reads "of the 17 created since 2026-09-27, 15 and 2" (also "61 declare a mode") (Phase A0, the #6227 AC-3 row; [ADJUST] A-8). Corrected value: **18** declarations since 2026-09-27 — 16 `versioned`, 2 `version-less`. ms#428 declares its mode under a heading, which the line census missed. Re-read on 2026-11-13: 62 label-form lines (50 / 12) plus 2 heading-form declarations. No design input depends on the total | `#8917 comment 6865291333` (#6227 Stage-5 revision 1, Commit-0 deviation-log entries), entry DL-6227-2 |
| DEV-3 | 6 (Commit 0) | The Stage-4 Implementation Sequence's beat-1 row commits the `stage-03-bundle.md` citation "first step of beat 2 if it lands after beat 1". Corrected value, under C2 (A), which supersedes the value #6227's revision 1 gave: beats 2 to 4 do not wait for the operator's `RELEASE_PROTOCOL.md` commit; whenever it lands before the Stage-9 GO, a spoke runs **beat 1b** immediately after it and before the next gate — the `stage-03-bundle.md` citation, register row B with #6227's final Version History row, and the second `spec-practice-adjudications` record line. With no commit by Stage 9, #6227 AC-3 takes the plan's miss path. Withdrawn: revision 1's "if the operator commit is not on the branch when beat 2 is due, beat 1b is not committed", and the hub's earlier "the hub writes line 2 before Stage 7" | `#8917 comment 6865291333` (#6227 Stage-5 revision 1, Commit-0 deviation-log entries), entry DL-6227-3; `#8917 comment 6866868670` (scope lock, C2 (A)) |
| DEV-4 | 6 (Commit 0) | The Stage-4 Verification Plan names the first members of population `constraint-determinations-at-path` as "D5-1, D5-3 and D5-4" (Stage-13 population records, M-3). Corrected value: the members also include #6227's own constraint-bearing determinations — D5-2 with OD-2, OD-4 (A′), the OD-5 (A′) precedence sentence, and D-Surface — per register row A's own member definition (CIAC-3, plan R4) | `#8917 comment 6865291333` (#6227 Stage-5 revision 1, Commit-0 deviation-log entries), entry DL-6227-4 |
| DEV-5 | 6 (Commit 0) | The Stage-4 REFCASCADE pre-count for #6226's move (Contention Map) searches the basename `governance-ci-checks_RELEASE_NOTES`, which a directory move keeps, so its post-count cannot reach 0. Corrected value: the path-form search split by folder, with P = `(^\|[^/])governance-ci-checks_RELEASE_NOTES\|[^d]/governance-ci-checks_RELEASE_NOTES` — (i) `git grep -n -E "$P" -- ':!release/releases/plans/'`, pre 1 / post 0; (ii) `git grep -n -E "$P" -- release/releases/plans/`, reported row by row with no zero owed; (iii) `grep -c -F 'notes/_unversioned/governance-ci-checks_RELEASE_NOTES.md' release/releases/RELEASE_INDEX.md`, 0 → 1. AC-2's "REFCASCADE post-count is 0 on live forms" reads as (i) | `core/rules/rename-reference-cascade.md` § 2; #6226 Stage-5 revision 1 (the A6.5 review's FM-1, applied at Collective Review); `#8918 comment 6865473339` (#6226 Stage-5 revision 1, Commit 0) |
| DEV-6 | 6 (Commit 0) | `CONDITIONAL:assertion-adopted` is not fired: D5-5 was rendered (B′), decline with an upgrade trigger. Beat 3b, the dependency graph's CONDITIONAL edge #6225 → #6226-assertion, the Verification Plan's evidence-shape bullet for #6226's optional assertion and the Contention Map's "+ #6226 if D5-5" on `core/deploy/deploy.sh` do not apply. The decision, its reason and its trigger are recorded at `release/releases/notes/README.md` § Directory layout, an FCM delta admitted as Tier 1 [ADJUST] | Collective Review decision record (D5-5); `#8918 comment 6865473339` (#6226 Stage-5 revision 1, Commit 0) |
| DEV-7 | 6 (Commit 0) | The Contention Map row for `core/standards/duplicate-source-discipline.md` names #6226's write as "adjudication clause". Corrected value: #6226 (beat 2) writes § 1.2 and one sentence each in the `purpose:` frontmatter, the Purpose paragraph and § 3, and owns `purpose:`; #6225 (beat 3) writes § 1.1, § 2 and `consumers:` and leaves `purpose:`, Purpose and § 3 to beat 2 | #6226 Stage-5 revision 1 (the A6.5 review's FM-5); `#8918 comment 6865473339` (#6226 Stage-5 revision 1, Commit 0) |
| DEV-8 | 6 (Commit 0) | The Stage-4 premise: the six `core/deploy/tests` suites named in no workflow are unwired, unrun, with their pass state unmeasured (carried by: Risks R6; Phase 0.5 AC-4 row, D3 cell ("the 6 unwired suites persisted"); the Contention Map note on #8821 ("one of #6225's 6 unwired suites"); the Stage-5 D-gate list, D5-6 ("with the 6 unwired suites run first (R6)")). Corrected value: All six are `REGRESSION_MEMBERS` of `core/deploy/tests/run-install-regression.sh`, and the install-regression job runs them twice per run. CI run 43158451444 at `29c60404` passed 22/42/70/51/30/20 assertions with 0 failed, and the census reads 92 suites, 1 zero-executor (`release/tools/test_version_freeness.sh`). D5-6 (A′) turns no suite on | `#8919 comment 6866289061` (#6225 Stage-5 revision 1, Commit-0 deviation log, entry DEV-6225-1) |
| DEV-9 | 6 (Commit 0) | The Stage-4 premise: the three live sites, once marked, produce 3 drift rows (carried by: Verification Plan, Evidence shape (M-4), #6225 bullet item (2); Per-Issue Verification AC-3 expected result "3 rows then 0"; Implementation Sequence beat 3 ("Mark the three sites → observe drift on all three")). Corrected value: **1 DRIFT row, then 0** (Detail § Live red): #3433 and #5502 are converted to citations (Proposed Change step 4; D5-6 (A′)), and a citation carries no marker. AC-4's `expect 3` changed paths is unchanged | `#8919 comment 6866289061` (#6225 Stage-5 revision 1, Commit-0 deviation log, entry DEV-6225-2) |
| DEV-10 | 6 (Commit 0) | Stage-4 R7: "Over the last five, the mean of shares is 47% and the pooled share 38%, so the first real measure reads **above the 35% ceiling** either way". The Evidence-shape (M-4) bullet rests on it: "The first real measure (above the ceiling today, R7) is a second, real red." **Corrected: the first reading depends on merge order and on the window anchor, and is not fixed at Stage 4.** D5-4 is pooled and the window is the release log by merge ancestry (OD-17), so the first reading reads this release plus the four releases merged immediately before it that carry log rows. ms#429's release merges first, because beat 4 waits on #8821. Readings, on memberships as of 2026-11-13: ms#429 alone → 5/19 = 26.3%, in band; ms#429 and ms#437 → 2/25 = 8.0%, below the floor; ms#429 and ms#439 → 9/23 = 39.1%, above the ceiling; ms#429, ms#439 and ms#440 → 12/24 = 50.0%, above. It reads `NOT-EVALUATED` if an earlier-merged release's Stage-12 log row has not landed. The release's red evidence is the seeded fixture plus the live reading of v5.07's window (5/13 = 38.5%, above the ceiling); a first reading inside the band is not a missed red. | Stage 5 revision 1 on #8920; the #8917 Collective Review decision record (D5-4 pooled; OD-17); `#8920 comment 6866287296` (#7842 Stage-5 revision 1, the R7 entry); `#8917 comment 6864580721` (the Collective Review decision record) |
| DEV-11 | 6 (Commit 0) | The File Change Matrix is rendered at the scope-locked 31-path write set rather than the Stage-4 matrix of 16 unconditional and 20 conditional rows. The 8 fired CONDITIONAL rows are promoted with their concrete paths (`c63-sibling`'s directory row refined to the one fixture file that is also #6225's FCM-delta row 1, so it is listed once; `band-fixtures` narrowed to two fixture files); the 12 not-fired rows are listed `NOT EDITED`; the 7 FCM-delta rows are admitted as Tier 1 [ADJUST]s (#6226 1, #6225 5, #7842 1). Neither watch item trips: no new governance file, 2 stage files, at most 2 rule-defining surfaces | `#8917 comment 6866868670` (scope lock); each card's FCM delta (N19); `release/references/pipeline/stage-04-planning.md` § 6, the declared-vs-delivered contract, rule 5 |
| DEV-12 | 6 (Commit 0) | The In-Flight Release Roster is re-measured at Commit 0 rather than copied from the hub's Stage-6 brief. The brief named #8983 (ms#437) at head `b65c6a48` with 61 files, and #8992 with 1 file and no overlap. Measured: #8983 at `016dc32b` with 91 files, overlapping three of #6225's paths (two FCM-delta rows and the fired `new-script` allowlist row); #8992 at `72a83bae` with 10 files, no overlap; and two further draft release pull requests open, #8993 (ms#439, 4 files) and #8994 (ms#445, `version-less`, 2 files), neither overlapping. #8821's overlap is now 8 paths, because five of its Stage-4 conditional intersections fired, plus `release-velocity-tracking.md`, a new delta path that was not a Stage-4 intersection | Commit-0 measurement, `2026-11-13T23:13Z` (§ Cross-PR Overlap Audit → In-Flight Release Roster); the hub's Stage-6 brief for #8921 |
| DEV-13 | 6 (Commit 0) | One transcribed Stage-4 span is rendered by name: the Implementation Sequence's beat-0 row named the double-brace release-version placeholder literally, and it now names it in words, so the file carries exactly one literal placeholder — the Header `**Version**` cell — and the Stage-12 claim's whole-file substitution changes nothing but that cell | `release/skills/release-planner/references/release-plan-template.md` § Template Usage Rules, rule 7; § Commit-0 Version Re-Verify Record → Manifest half |
| DEV-14 | 6 (beat 2) | DEV-12 is corrected in place. It read that #8821's overlap of 8 paths arose "because six of its Stage-4 conditional intersections fired or became FCM-delta rows". Corrected value: five of the seven Stage-4 conditional intersections fired — `compute-release-velocity.sh`, the platform-config template, its schema, its reference and `script-execution-allowlist.txt`. The other two, `release-tooling-smoke.yml` and `release/ADRs/README.md`, did not fire, so #8821's edits to them overlap nothing in this release. The eighth path, `release/references/standards/release-velocity-tracking.md`, is #7842's FCM-delta row, a new delta path that was not a Stage-4 intersection. The Stage-4 unconditional pair, five fired rows and one delta row make the 8. Re-read at beat 2: #8821 at `8974f500` lists 47 files, all ten of those paths among them | the hub's beat-2 brief; § Cross-PR Overlap Audit (the Stage-4 audit's seven CONDITIONAL intersections; the Commit-0 roster row for #8821); #8821's file list, paginated, at beat 2 |
| DEV-15 | 6 (beat 3) | The A2 container predicate, read for beat 3 alone, selects the GitHub sub-issue container: six logical units (Commits A to F), multi-file and structure-changing (a new check, its primitive and its self-test group). The release keeps the PR-body checklist container beat 1 opened, and no sub-issue was created, because the beat-3 brief bounds this spoke's GitHub writes to its one output comment on #8923. The rows are rendered in that comment for C2's body, and the container question is routed to the hub | `release/references/pipeline/stage-06-engineering.md` § Process, A2; the hub's beat-3 brief; #8923 Stage-6 output, Decisions & Recommendations |
| DEV-16 | 6 (beat 3) | Five implementation determinations the Stage-5 specification does not name, each made inline and recorded at the path: (a) "when `--root` is a git work tree" is read as the top level of one — `git rev-parse --show-toplevel` equal to the root — so the live worktree (whose `.git` is a file) takes `git ls-files`, while a `mktemp` sandbox under a symlinked temporary directory, and a subdirectory of a work tree, take `os.walk`; (b) a glob with no wildcard segment keys by its whole path; (c) a link inside a code span is not a link; (d) the fixture file is parsed strictly — a non-comment line outside a case block, an unterminated block or a case with no `POPULATION:` line is an input failure (exit 3), so a mistyped header cannot silently drop a case; (e) `--fixtures` and `--self-test` are mutually exclusive (argparse usage error, exit 2), and the `INPUT-FAILURE:` line goes to stderr, as in Check 63's primitive. None changes a verdict the specification states; (a) and (b) are recorded in the tool's module docstring | #6225 Stage-5 revision 1, Output for Stage 6, Commit A (`#8919 comment 6866289061`); `core/deploy/tools/check-enumeration-drift.py` module docstring |
| DEV-17 | 6 (beat 3) | The merge-order pairs are re-measured at beat 3 rather than copied. #8983 (ms#437) at `e584b4d3`, 99 files, overlaps **four** of beat 3's paths — the three the Stage-5 design named (`script-execution-allowlist.txt`, `selftest-coverage-manifest.txt`, `core/deploy/tools/README.md`) and `core/standards/gate-efficacy-standard.md`, a shared path. #8821 (ms#429) at `8974f500`, 47 files, overlaps three: `docs/module-apis.md`, `gate-efficacy-standard.md` and `script-execution-allowlist.txt`. #8992, #8993 and #8994 overlap none. No open release branch claims a `Check 83` header (control: each of the five carries Check 82's, 5 of 5) | the hub's beat-3 brief; each pull request's file list, paginated, at beat 3 |
| DEV-18 | 6 (beat 1b) | Two sentences of this file are corrected in place. (a) The Header **Status** cell still read "Executing — Stage 6 Engineering, beat 1", although beats 2 and 3 and the operator's `release/governance/RELEASE_PROTOCOL.md` commit had landed; it now states the Stage-6 position after beat 1b. (b) The Deviation Log's opening sentence called every row after the tenth "this spoke's own Commit-0 entries", but DEV-14 was added at beat 2 and DEV-15 to DEV-17 at beat 3; it now names DEV-11 to DEV-13 as the Commit-0 entries and dates each later row by its Stage cell. Neither sentence is transcribed Stage-4 text, so N18 is not engaged | Beat 2's Stage-6 output (`#8922 comment 6867973393`, Decisions & Recommendations item 3) and beat 3's (`#8923 comment 6870137196`, item 8), each of which routed both corrections to the hub; the hub's beat-1b dispatch on #8921 |
| DEV-19 | 6 (fix(dt) pass 1) | Five Stage-7 findings are fixed on the branch, one commit each: four at Tier 1, and #6227 F-02 under the operator's decision (A). (1) #6225 F-01 (Major): the `dup` rule had no fixture case and no self-test arm, so a mutant with duplicate detection off passed both. Fixture case 20, `DRIFT list duplicate-item`, lists every member once and one of them again, so only the repeat can drift; case 3, the same list without the repeat, is its near-miss. The fixture totals this file quotes are restated at 20 cases beside the beat-3 observations they extend, each from a run at this pass. No self-test arm is added: the self-test pins each relation in both directions, not each rule, and the fence, link-resolution and one-level-glob rules are fixture-only as well. So the CI `--self-test` still does not see a `dup` regression, and Check 83's fixtures do. (2) #6225 F-02 (Minor): the group-ED header comment in `core/deploy/deploy.sh` no longer says the fixtures run in CI. (3) #6225 F-04 (Cosmetic): Check 83's fixtures line no longer prints `self-test:` twice. (4) #6227 F-02 (Minor, operator decision (A), post-lock): register row B's probe reads a milestone's mode declaration in any form, so a heading-form declaration is examined and non-conforming instead of falling outside the population. The row's name, kind, 100% threshold and named-gap form are unchanged, and the row no longer matches #6227's Stage-5 specification byte for byte. (5) #6226 F-03 (Minor): the #6226 AC-4 Verification Method cell read "declared, verification deferred to Stage 8 (reads both superseded observations)" and now names the two observations, so the binder reads it BOUND. The cell is transcribed Stage-4 text, so N18 is engaged: it is reworded at the hub's instruction, and its Stage-4 wording is kept here. This log's opening sentence now dates a row by the beat or the pass its Stage cell names | `#8927 comment 6871935332` (#6225 Stage-7 pass 1: F-01, F-02 and F-04); `#8925 comment 6870949633` (#6227 Stage-7 pass 1: F-02); `#8926 comment 6871078798` (#6226 Stage-7 pass 1: F-03); the operator's decision record, `#8927 comment 6872035212`; the hub's fix(dt) pass-1 brief |
| DEV-20 | 6 (fix(qa) pass 1) | #6225 QA-F1 (Major, Tier 1), four of its five rules. The fixture file's header said its cases pin each binding, key and relation rule the tool's module docstring states, and five such rules were pinned by neither the `--self-test` nor the fixtures, so a mutant with any one of them off passed both. Four are now pinned, one case each, appended as cases 21 to 24 so that no existing case number moves: case 21, `UNRESOLVED list malformed-glob-recursive`, a `**` glob, which with the rule off is read one level deep and reads clean; case 22, `DRIFT list table-body-rows`, a two-row table, which with the header and separator counted as items reads `boundary-disagreement`; case 23, `CLEAN list link-fragment-and-query`, links carrying `#L3` and `?plain=1`, which drift with either strip off; case 24, `CLEAN list link-in-code-span`, whose first link sits inside a code span, which drifts with masking off. Each of those mutants reads `fixtures: 20/20 passed` over the 20-case set and `23/24` over the 24-case set, its one FAIL naming its own case, and each passes the `--self-test`. The fifth rule, the `boundary-disagreement` verdict, is not pinned, and no fixture can pin it: the item splitter computes the count by the same steps as `structure_at`, so no document makes the two disagree (0 of 438,160 structures over 200,000 generated documents, against 38,179 for a splitter that counts the table header), and the tool with the verdict removed reads `24/24`. Pinning it needs a self-test arm that injects a disagreement, a tool change this pass does not make; it is routed to the hub. The header's claim is replaced by what each case pins; it names the verdict as the one rule no case pins, and notes under case 21 that the leading-`/` and `..` limbs of the malformed-glob rule cannot be told apart by a case. The tally reads 7 DRIFT · 10 CLEAN · 6 UNRESOLVED · 1 SCOPE-OUT, 24 in all, and the beat-3 fixture figures gain the 24-case readings taken in this pass. Case 25, `CLEAN list external-link-skipped`, then pins the external-scheme limb of the link skip, which this pass found unpinned although it changes a verdict: the item's first link is `https:`, and with the limb removed that link reads as an extra path, so the set reads `24/25` where it read `24/24` before the case; the tally becomes 7 DRIFT · 11 CLEAN · 6 UNRESOLVED · 1 SCOPE-OUT, 25 in all, and the beat-3 figures gain the 25-case readings. No tool, `deploy.sh` or self-test line changes. At beat 4, cases 26 to 40 pin the fifteen rules a 46-mutant sweep over the 25-case set found pinned by neither instrument (Stage 7's F-07), one case each, taken verbatim from the hub's probe set, so that every mutant is killed by the `--self-test` or the 40 cases except the two equivalents, the `boundary-disagreement` verdict and the pure-anchor link skip (44 of 46), and cases 26 and 27 withdraw the note under case 21 that the leading-`/` and `..` limbs cannot be told apart by a case (F-08); the tally becomes 10 DRIFT · 19 CLEAN · 9 UNRESOLVED · 2 SCOPE-OUT, 40 in all | `#8939 comment 6879427711` (#6225 Stage-8 QA pass 1: QA-F1); the hub's fix(qa) pass-1 brief |
| DEV-21 | 6 (beat 4) | The planned rebase onto `origin/main` once PR #8821 merges (the Implementation Sequence's unnumbered row before beat 4; the Delivery Strategy's **Rebase** bullet) is executed as one signed merge commit, `dfd60b3b`, because the branch is already pushed and a rebase would need a force-push, which this branch never takes. `origin/main` was `1c2130c5`, the merge of PR #8821 (ms#429), 145 commits and 66 files past the release base `29c60404`. One file conflicted, `core/standards/gate-efficacy-standard.md`, in two hunks: the gate-coverage register's tail and the Version History table's tail, where PR #8821 adds two rows each. Both keep PR #8821's rows first and this release's after them in beat order (rows A, B, R-1, R-A, R-B; the #6227, #6226 and #6225 history rows). The merge also clears Stage 7's S7-I04 branch-freshness Blocker: `assert_branch_fresh.py --base origin/main --head HEAD` reads `PASS … (0 commits on origin/main unreachable from HEAD)`, where at `8f9497ea` the same runner reads `FAIL: 145 commit(s)`, exit 1. At the #7842 fix(dt) pass 1, the second freshness merge is recorded here. While beat 5 ran, `origin/main` moved to `d293361e`, the merge of PR #9030 (ms#429's Stage-12 release-log chore), and the same runner read `FAIL: 3 commit(s)` at `ac4acd77`. The merge took the same Stage-7 S7-I04 Tier-1 route, as one signed merge commit, `fc82efbb`, with parents `ac4acd77` and `d293361e`. The hub executed it, acting as Engineering. The dry merge was clean, the merge brings only `release/releases/RELEASE_LOG.md` and the v5.09 plan's rename, and none of the release's own paths changes. The runner then reads `PASS`, exit 0 | `#8927 comment 6882304610` (#6225 Stage-7 re-review: F-06, S7-I04 branch freshness, Blocker routed Tier 1 — Engineering merges the base, never by rebase or force-push); the hub's beat-4 brief (hub value C3); `#8924 comment 6904652333` (the hub's beat-5 decision: the second merge, executed by the hub acting as Engineering) |
| DEV-22 | 6 (beat 4) | Beat 4 launched against a Checkpoint-B DEFER. The singleton check read DEFER on the usage-window axis, with the weekly window 95% used and its reset at 2026-11-20 15:00Z, and PROCEED on the host-API axis. The operator's instruction to continue overrode it, which the quota-budget protocol reads as the override to PROCEED. § Quota Budget is unchanged; this row records the one launch that ran against a DEFER | the hub's decision record on #8924 (`#8924 comment 6902322860`); `quota-budget-protocol.md` § 4.5 |
| DEV-23 | 6 (beat 4) | Eight implementation determinations the #7842 specification does not name, each made inline and recorded at the path, none changing a verdict, line form or exit code the specification states. (a) `_rv_qs_closing` and `_rv_qs_window` take the release log as `$1`, or from stdin when `$1` is `-`: the live log is 1,011,829 bytes against an argument-size limit of 1,048,576, so the argv form of the function table would fail on every live reading; the self-test keeps inline argv logs, and the 106 KB first-parent list stays on argv, about a tenth of macOS's limit but over four fifths of the 128 KiB Linux allows one argument, so a live reading on Linux fails closed once the list passes it (routed to the hub). (b) The release rows are the table lines of eight or more cells that follow the `Version` header line without a break, so a later table in the file is not read as release rows. (c) A rung path in a `NOT-EVALUATED` record is written repository-relative for the template and with the home directory as `~` for the individual file, so no record carries an operator path. (d) Every Test QS check runs before the group reports, and a failing group then exits through `die` naming its count, so a red run shows every failing arm (49 checks across all twelve arms with the functions absent) rather than the first. (e) QS-1 to QS-10 run the real command line in its offline form, from the repository root and hermetic on both rungs; QS-11 and QS-12 call the functions the live form runs; QS-1 also compares the printed record with § 7b's byte for byte; QS-7 reads 219/625 and 7/20, the same fractions as 3504/10000 and 3500/10000, kept small because the offline path passes the window file as one argument. (f) The live path assembles its window JSON through an eighth subcommand of the same Python body, `window_json`, so the live and offline paths feed one computation. (g) The live counted-label check names a 404 as the label's absence and any other failed read as an unreadable label, so a network error never reads as a renamed label. (h) The Version History row prefixes the specification's R-VH sentence with a bold lead, the form of the table's other rows | #7842 Stage-5 revision 1, Output for Stage 6, Changes 6 and 11 (`#8920 comment 6866290078`), and its R-VH recommendation (`#8920 comment 6866287296`); `release/tools/compute-release-velocity.sh`, the quality-share function block's comments |
| DEV-24 | 6 (#7842 fix(dt) pass 1) | Three of #7842's Stage-7 pass-1 findings and #6225's F-10 are fixed on the branch, in three commits. (1) F-02 (Minor, Tier 1): § 7b's Known bounds gain one bullet. It names the argv bound: the live first-parent list reaches the quality-share step as one argument, so Linux's 131,072-byte per-argument cap bounds it. It gives the headroom: 106,502 bytes, 81.3% of the cap, read on `main` at `d293361e`, growing about 470–524 bytes a release. It names what a capped reading prints, the window step's no-OK-sentinel reason, which names no cause. Moving the list off argv stays F-01's deferred follow-up. (2) F-03 (Minor, Tier 2), under the operator's decision PA-015 (A): A14.2's single in-phase re-run now also applies, at once, when the `NOT-EVALUATED` reason names a failed read. The four reasons are quoted as the tool prints them: the membership read, the milestone list, the counted-label read and the first-parent history. Every other reason is still written as printed, and the bold `quality-share-record` anchor is unchanged. The rule's one other tracked statement, § Change Description's Stage-13 bullet, is updated in the same commit. The other read-shaped reasons PA-015 does not name are still written as printed, and are routed to the hub: a shallow flag that `could not be read`, a target repository that `could not be resolved`, a milestone that `does not resolve to a title`, an unreadable release log, a closing merge not in the clone, a membership read that `is not JSON`, and a step with no OK sentinel. (3) F-04 (Cosmetic): beat 4 step 3 gave the printed record's size as its character count without the final newline; the record is 1,484 bytes, and the byte-for-byte equality stands. (4) #6225 F-10 (Minor, Tier 1), under the operator's decision PA-016 (A): the fixture header names `C-guard` and `C-nested` as rules no case pins and only the `--self-test` kills, beside the two equivalents, in comment lines only. #6225's DT↔Engineering loop is past its cap, and PA-016 is the operator's authorization for this edit. (5) DEV-21 gains the second freshness merge, and the Header Status and § Change Description's `DONE (Stage 6)` note are restated to the branch after this pass | `#8929 comment 6905430111` (#7842 Stage-7 pass 1: F-01 to F-04); `#8929 comment 6905462174` (the hub's routing of those findings); `#8929 comment 6905582890` (PA-015); `#8927 comment 6905104097` (#6225 Stage-7 pass 4: F-10); `#8927 comment 6905583291` (PA-016); the hub's fix(dt) brief |

---

## Verification Evidence

### Engineering Commit 0 — Stage 6 A1

- **Version re-verify:** PROCEED at `v5.08` (§ Commit-0 Version Re-Verify Record).
- **Stamp manifest (step 3b):** `release/tools/claim-version.sh --verify-stamp obligation-runners-declared` → exit 0, "verify-stamp OK — obligation-runners-declared carries a resolvable stamp manifest; plan-only manifest (0 --stamp-file target(s))". It ran after this file was written and before it was committed, and again after this line was added. Remote tags at this run end at `v5.07`, so `v5.08` reads free.
- **Date variable:** `${AUDIT_DATE_UTC}` = `2026-11-13` (Friday), resolved at this commit for #6225's beat 3.
- **ADR index:** N/A — this release adds no record under `release/ADRs/` (OD-18).
- **Commit:** Engineering Commit 0 is `29680e8c`, signed, pushed to `release/obligation-runners-declared`; the branch was created at `29c60404` and pushed with upstream tracking before this file was written.
- **CIAC authoring lint (Stage-6 A1, G4-06 on the committed plan):** `bash release/tools/verify-release-plan.sh --ciac-lint` on this file → exit 0, `CIAC-LINT-SUMMARY declared=5 parsed=5 clean=0 declared-deferral=5 flagged=0`, the same summary the Stage-4 draft recorded. No CIAC is a CAVEATS input.
- **Plan verifier (Stage-6 C4 self-verification):** `bash release/tools/verify-release-plan.sh --format=json --stage4-comment <the Stage-4 part-1 body>` on this file at `29680e8c`, and again at `a15b9e33` after beat 1a → the same roll-up both times: 8 PASS · 10 FAIL · 17 SKIP · 0 UNRUNNABLE · 0 ERROR over 35 records (19 per-issue rows, 5 cross-issue, 11 always-on), exit 3. Every FAIL is a deliverable of a later beat, read before it exists: #6225 AC-1, AC-2 and AC-4 (beat 3), #6226 AC-2 and AC-3 (beat 2), and the five unconditional ADDs not yet delivered (the moved note, the drift tool, its fixture file and the two quality-share fixtures). `FCM-COVERAGE` PASS: `declared=47 interpreted=47 obligations=6 excluded=16 conditional=0 uninterpreted=0 pathless=0 prose_led=0`; `FCM-1` PASS, this file delivered as an addition. The 2 PASS per-issue rows are the two criteria discharged at bundling (#6226 AC-1, #6227 AC-2). #6227's other rows are declared-deferred SKIPs graded at Stage 8.
- **Provenance family:** `PROV-PRESENCE`, `PROV-GRAMMAR` (Form X, date `2026-11-13`) and `PROV-COVERAGE` PASS. **`PROV-DELTA` reads PASS, but on this host that verdict is not evidence:** the delta limb builds its set difference with `awk -v have="<newline-separated list>"`, and the host's awk refuses a newline inside a `-v` value ("newline in string domain_practice-labe…", three times on stderr), which leaves the lost-set empty and so reads no-loss whatever the inputs. The set difference was taken directly instead, by one python3 pass applying the limb's five element tests to the Stage-4 part-1 body and to this file: 5 of 5 present in each, lost = none; control, the same tests on a file carrying none of the elements → 0 of 5. The tool defect is routed to the hub (sub-task #8921 output), not fixed here.
- **Plan-identity lint:** `python3 core/deploy/tools/lint_release_corpus.py --check plan-identity` → exit 0; no finding names this file (the advisories it prints are the corpus's recorded residuals).
- **Links in this file:** a fixed-string count of the markdown link opener (a closing square bracket immediately followed by an opening parenthesis) on this file → 0 (control: the same count on the release-plan template → 2), so the plan-depth link rule has nothing to grade. `check-release-links.py --roots release/releases/plans --plan-depth-lint` read 0 files, a vacuous zero, and is not cited as evidence. `check-doc-links.py --require-targets` over this file and the two beat-1a files → 0 broken references, exit 0 (control: its `--self-test`, 12 fixtures passed).
- **Identity and placeholder probes:** the handle, a home path, a scratch path and a GitHub host string each → 0 in this file (control: the Stage-4 comment's saved copy → 1); the literal release-version placeholder → exactly 1.

### Beat 1a — #6227's agent limbs (Stage 6 B1/C4)

- **Commit:** `a15b9e33`, signed — Change 1 and Change 2 of #6227's revision-1 Output for Stage 6, each block taken from the posted comment by script, every anchor asserted to occur once before the edit.
- **Diff:** `git diff --numstat` → `17  1  core/disciplines/decision-discipline.md` and `2  0  core/standards/gate-efficacy-standard.md`, the counts the design specifies (+17 / −1 and +2 / −0).
- **AC-1 Stage-7 probes, read early:** `grep -c -F "### 3.2 A constraining determination is recorded where it constrains" core/disciplines/decision-discipline.md` → 1; `grep -c -F "never the sole home of a constraint-bearing determination (§ 3.2)" core/disciplines/decision-discipline.md` → 1; `grep -c -F "Nor is a record of the release" core/disciplines/decision-discipline.md` → 1; `grep -c -F "constraint-determinations-at-path" core/standards/gate-efficacy-standard.md` → 1 (baseline 0 · 0 · 0 · 0).
- **No beat-1b text landed:** `grep -c -F "release-identity-rule-citations" core/standards/gate-efficacy-standard.md` → 0 (control, the same instrument and file: `constraint-determinations-at-path` → 1). `release/references/pipeline/stage-03-bundle.md` and `release/governance/RELEASE_PROTOCOL.md` are unchanged on the branch.
- **Register:** row A sits after the last row at the pin (the instance-data new-surface row), so the register reads 92 data rows; it carries no `runner-def:` pointer (N7), so #6227's Check-62 delta is +0 (N8). #6227's one Version History row is appended at the table end in its beat-1a form (N9); beat 1b replaces it with the two-row form.
- **Check 63 primitive:** `python3 core/deploy/tools/check-count-structure.py --root .` before and after the edit → the same 6 FAIL rows (#7414's red) and `pairs_examined=545` both times; controls PASS. Beat 1a adds no count/structure finding.
- **Reference durability:** the four detector expressions of `core/hooks/lib/fragile-ref-patterns.sh` (markdown link, version-cutover apparatus, raw issue/PR/milestone URL, bare issue reference) over the 11 added lines → 0 each; control, a seeded file carrying one instance of each → 1 each.
- **Runtime suite:** none selected — the change is doc and governance text only (the runtime-suite selection map's no-match row), so the honest record is a suite skip.

### Beat 2 — #6226's note move and adjudication clause (Stage 6 B1/C4)

- **Branch check at entry:** `git log --format=%h origin/main..origin/release/obligation-runners-declared -- release/governance/RELEASE_PROTOCOL.md` → empty at `bc191755`, and again at each fetch before a push. The operator's commit is not on the branch, so record line 2 is not written here; beat 1b writes it immediately after that commit lands (C2 (A)). The hub re-runs the check at the release head before Stage 7.
- **Commit 1 (`5cd64b80`, signed):** the note's `git mv` into `notes/_unversioned/` (rename R100; blob `95a8c3ee` before and after, so `links.plan` is unchanged), row 129's Release Notes cell, and the notes README's line 20 replaced by the two D5-5 (B′) paragraphs. numstat: `1 1` the index, `3 1` the README, `0 0` the rename.
- **Instrumented control:** `/usr/bin/python3 core/deploy/tools/generate_release_index.py --verify` after the `git mv` and before the cell edit → exactly one `notes_link` row, for `governance-ci-checks (version-less)`. Its `log_value` was written to the cell verbatim; the other five cells are byte-identical and the index was not regenerated. After the edit → no `notes_link` row. The one remaining row is `v4.17 row_order` (#7894's), read by field, never by exit status.
- **Reference cascade:** `[REFCASCADE: git grep -n -E "$P" -- ':!release/releases/plans/' over all tracked files outside release/releases/plans/ → pre 1 / post 0]`, with `P` as DEV-5 defines it. Pre: the index's row 129, at `bc191755`. Post: 0 at `5cd64b80`, and still 0 after Commit 2's text.
  - Arm (ii), inside `release/releases/plans/`, pre 6 lines: this file's Agent-Editability row, its FCM `DELETE` line, its Stage-4 REFCASCADE line, its structural-blast-radius bullet and DEV-5 (which quotes the pattern), and the v4.12 plan's terminal record at :209. Each is preserved: v4.12 is terminal, and this file is the move's own record. Post: the same 6 lines, because this subsection names the note by slug, never by its old path; no zero is owed.
  - Arm (iii), the bounded control: `0` with exit 1 → `1`. Sensitivity, the same file: `notes/_unversioned/` → 18 before, 19 after.
- **Upgrade trigger (the README's observable):** version-less arm 1 → 0, and 19 of 19 version-less rows now link through `notes/_unversioned/`. Versioned arm 0 → 0 over its near-miss, the 240 flat versioned rows.
- **Links and the note lint:**
  - `check-doc-links.py --require-targets` over the index, the README and the moved note → 0 broken. Sensitivity: a run-directory fixture pairing the pre-move cell with the moved note → 1 `broken-cross-ref`. Specificity: the post-move cell → 0. Its `--self-test` passes 12 fixtures.
  - `check-release-links.py --check-anchors --images` over all six beat-2 files → 0 broken; its `--self-test` passes.
  - `lint_release_corpus.py --check note-content` → exit 0. Its discovery idiom, `rglob("*_RELEASE_NOTES.md")`, reaches 259 notes, the moved note among them, and its `links.plan` tally sums to the same 259.
- **Commit 2 (`a38e28b8`, signed):** each block was taken from the Stage-5 comment by script, with every anchor asserted to occur once.
  - Change C — § 1.2, plus one sentence each in `purpose:`, Purpose and § 3; numstat `18 2`. `consumers:`, § 2, the counts and § 6 are untouched (beat 3's).
  - Change D — R-1 directly after row A (the register reads 93 data rows), and one Version History row after #6227's at the table end (N9); numstat `2 0`. `origin/main` is still `29c60404` and #8821 is open, so the planned rebase that places R-1 after #8821's row has not happened yet.
  - Change E — this file's `### Adjudication records` subsection with record line 1; numstat `4 0`.
- **R-1 grammar:** a read-only import of `core/deploy/tools/check-doc-gates.py`.
  - `register_rows` reads 93 data rows with R-1 last; `row_cells` reads 5; `surface_word` reads `prose`.
  - `parse_population` accepts it: name `spec-practice-adjudications`, threshold 100.
  - Controls: copies with a 0% threshold or a hyphen after `census` are refused, and the 11 other population rows all parse clean.
- **Check 62 pointers:** its own `runner-def:` and `runner-src:` greps over the 13 added non-blank doctrine lines → 0 and 0. Control: Check 82's register row → 2. Specificity: the bare token in R-1's prose, followed by a backtick, → 0, as the parser intends. #6226's delta is +0 (N8).
- **AC-3 probes:** `grep -c -i -F "adjudicat" core/standards/duplicate-source-discipline.md` → 1 (baseline 0). `grep -c -F 'spec-practice-adjudications' core/standards/gate-efficacy-standard.md` → 2: R-1 and its Version History row.
- **Record-line count:** the bounded count over `### Adjudication records` → 1, and the unbounded anchored grep → 1, so there is no copied line. Specificity, on a run-directory copy of this file seeded with a fenced column-0 copy under another heading and a mid-line label: bounded 1, anchored 2, unanchored 3.
- **Count-structure (the Check 63 primitive):**
  - `--path` on the host → FAIL=0 with pairs_examined 1 over 21,153 chars, the Stage-5 preview's figures. On the register → FAIL=0, pairs_examined 4.
  - The whole tree at `a38e28b8` gives the same 6 FAIL rows (#7414's) and pairs_examined=545 as at `bc191755`, with controls PASS.
- **Reference durability:** the four detector expressions of `core/hooks/lib/fragile-ref-patterns.sh` were read as text and run through python3 `re` over beat 2's 28 added lines.
  - The host: link 2 — the Purpose line's existing workspace-charter link and § 1.2's register link, covered by the file's `allow-link` marker — and cutover 0, raw URL 0, issue reference 0.
  - The register: 0 · 0 · 0 · 0. This file: 0 · 0 · 0 · 0.
  - The README and index lines fall outside the library's durable scope (`is_durable`).
  - Control: a seeded file with one instance of each → 1 · 1 · 1 · 1. The library's own run comes through `reference-durability.yml` on the release PR.
- **Plan verifier (C4):** `bash release/tools/verify-release-plan.sh --format=json --stage4-comment <the Stage-4 part-1 body>` at `a38e28b8` → 9 PASS · 7 FAIL · 17 SKIP · 2 UNRUNNABLE · 0 ERROR over 35 records, exit 3.
  - FCM-2, the moved note's ADD, now passes.
  - #6226 AC-2 and AC-3 move from FAIL to UNRUNNABLE: each one's machine limb passes (`test -f` on the new path; the `adjudicat` count), and its `[READER-GRADED]` limb is one this verifier does not grade. Stage 8 grades it.
  - Every FAIL is a beat-3 or beat-4 deliverable: #6225 AC-1, AC-2 and AC-4, and the four unconditional ADDs not yet delivered (the drift tool, its fixture file and the two quality-share fixtures).
  - `FCM-COVERAGE` PASS: `declared=47 interpreted=47 obligations=6 excluded=16 conditional=0 uninterpreted=0 pathless=0`.
  - `PROV-DELTA` is not cited: the BSD-awk defect recorded at Commit 0 reproduces, with the same stderr.
- **CIAC lint:** `--ciac-lint` on this file → `declared=5 parsed=5 clean=0 declared-deferral=5 flagged=0`, rc 0.
- **Skill packages:** `build-skill-packages.sh --skills-for-paths` over beat 2's six paths, read from stdin → 0 skills. Control: `release/skills/release-hub/SKILL.md` → `release-hub`. No package is rebuilt.
- **Runtime suite:** none selected. The change is doc and governance text only (the selection map's no-match row), so the honest record is a suite skip.

### Beat 3 — #6225's enumeration-drift check and its three sites (Stage 6 B1/C4)

- **Branch check:** `git log --format=%h origin/main..origin/release/obligation-runners-declared -- release/governance/RELEASE_PROTOCOL.md` → empty at entry (`87b77d59`) and at the fetches before pushes A to E (control: the same instrument over `docs/module-apis.md` → `14f1cf93` once Commit E landed). The operator's commit `642345e5` landed on top of `14f1cf93` during the beat; Commit F was rebased onto it (a fast-forward, no conflict: it touches only that file). No beat-1b text is written here.
- **Check number:** `<N>` resolves to **83**. The highest `# Check <n>` header at `87b77d59` is 82, and no tracked line outside the frozen release corpus names Check 83; none of the five open release branches carries a `Check 83` header (control: each carries Check 82's, 5 of 5). All eleven bind sites carry 83, and the placeholder occurs on 0 added lines.
- **Commits, each signed and pushed as it landed:** A `3d5347c8` the primitive, its fixtures and companions · B `cafb4d1a` the `deploy.sh` block, verdict tail, deadline arm and group ED, with the escape-suite pins · C `d75c45a9` the doctrine · D `e5b1b691` the two citations · E `14f1cf93` mark · F `8ce39a10` reconcile.
- **Primitive — red before green.**
  - `--self-test` → exit 0: `count sens=1/1 spec=0/1; list sens=1/1 spec=0/1; subset-of sens=1/1 spec=0/1; unresolved=1/1; parity=ok; keys spec=0/2 guard=1/1`.
  - Six mutants of the tool, each with one rule broken, run from the run directory. `subset-of` asserting completeness → `subset-of spec=1/1`, FAIL. Basename keys → `keys spec=1/2`, FAIL. A count that never drifts → `count sens=0/1`, FAIL. A second preamble line allowed → `unresolved=0/1`, FAIL. The ambiguity guard removed → `guard=0/1`, FAIL. A glob that crosses `/` → self-test PASS, but fixtures 18/19 (case 7), 19/20 when re-run over the 20-case set at the fix(dt) pass (DEV-19), 23/24 over the 24-case set at the fix(qa) pass, and 24/25 over the 25-case set once that pass added case 25 (DEV-20), and 39/40 over the 40-case set once beat 4 added cases 26 to 40. Every mutant reads red on at least one of the two instruments.
  - Candidate source (DEV-16 (a)): the worktree root, whose `.git` is a file → `git ls-files`; a `mktemp -d` sandbox under the symlinked temporary directory, and the `core/` subdirectory → `os.walk`.
- **Fixtures:** `--fixtures` → `19/19 passed` at Commit A, and `20/20 passed` since the fix(dt) pass added case 20, whose row reads `missing=- extra=- dup=alpha.sh` (DEV-19), and `24/24 passed` since the fix(qa) pass added cases 21 to 24, whose rows read `malformed-glob` (case 21) and `missing=gamma.sh` (case 22), with cases 23 and 24 clean, and `25/25 passed` once the same pass added case 25, which reads clean (DEV-20), and `40/40 passed` since beat 4 added cases 26 to 40. Each case's row matches the design's table: case 1 `missing=gamma.sh`; case 4 `extra=delta.sh`; case 5 `stated=2 population=3`; case 18 `extra=lib/other.sh`; case 19 `missing=b/y.md`; cases 9 to 13 `unbound`, `unkeyed-item`, `count-target`, `empty-population` and `malformed`. The harness's own sensitivity arm, a copy with case 1 relabelled `CLEAN`, reads `18/19`, exit 1, `19/20` over the 20-case set, `23/24`, exit 1, over the 24-case set, `24/25`, exit 1, over the 25-case set, and `39/40`, exit 1, over the 40-case set.
- **Companions:** the self-test manifest, regenerated with `--emit-manifest` → +1 line, `check-enumeration-drift.py` after `check-doc-links.py`. `check-selftest-coverage.py --reconcile` → CLEAN, exit 0: Arm B 85 paths, Arm E 49 of 49 tools documented, Arm F 10 of 10 spec invocations admitted.
- **`deploy.sh` (Commit B):**
  - `--self-test` → PASS with the group-ED line. Red first: the committed tail with its W1 sink and its exit-1-naming-nothing arm removed → `self-test: FAIL (3 failure(s))`, ED-1, ED-4 and ED-5. Restored byte-for-byte, then PASS.
  - `test_warn_log_json_escape.sh` → 11/11: A7 `1 1 12 0`, A8 `12 0 0`, A9 10 of the 12 reconstructed sites.
  - `test_gate_efficacy_declarations.py` → OK. Population reach: 7 declarations, 37 roots, 37 resolving.
  - `test_advisory_emitter_contract.sh` → 19 passed. Red first: the dial passed to `_ed_report` as an argument → WE-K FAIL naming the Check 83 dispatch line (`unrecognized-dial-test-shape`). Restored, then PASS.
  - `check-extraction-contract.py` → `DEFBLOCKS 83 · RETIRED 15,24 · EMITTERS 81 · COUNT 0`.
  - Counts: header lines 87 → 88; `json_escape_detail` call sites 11 → 12; `# gate-efficacy:` lines 5 → 6 (#6225 AC-2's probe).
- **Doctrine (Commit C):**
  - Check 63's primitive over `duplicate-source-discipline.md` → pairs 1 (the `Six registered` preamble over 6 rows), FAIL 0; over the standard → FAIL 0.
  - Check 62's `runner-def:` count over the standard 53 → 55 (+2, R-A and the flip row, N8); `runner-src:` 8 → 8.
  - A read-only import of `check-doc-gates.py`: the register reads 95 data rows, with R-A and R-B last. R-A's Surface is `deploy-time` and R-B's `prose`. `parse_population` accepts R-B as `enumeration-sites-registered`, threshold 100.
- **Citations (Commit D):** in `install-tests.yml`, the parsed YAML is equal before and after, and its 54 `run:` steps are equal. The added comment lines match neither the gate-efficacy header form nor the population form (control: the header form matches the unedited file once).
- **Live red (Commit E, `14f1cf93`):**
  - `check-enumeration-drift.py --root . --output-format tsv` → `DENOM files=997 markers=1 resolved=1 unresolved=0 drift=1`, and one row: `DRIFT docs/module-apis.md 165 list core/hooks/block-*.sh listed=11 population=14 missing=block-autonomy-ceiling.sh,block-draft-files.sh,block-external-seam-shape.sh,block-fragile-refs.sh,block-gh-path-leak.sh,block-scope-segregation.sh extra=core/hooks/allowlist-add.sh,core/hooks/audit-mcp-usage.sh,core/hooks/notify-version-skew.sh dup=-`. That is the design's stated red (DEV-9).
  - `deploy.sh --check`, Check 83's own lines:
    - `OK: enumeration-drift-fixtures — self-test: … controls PASS …; fixtures: 19/19 passed`; since the fix(dt) pass the line reads `OK: enumeration-drift-fixtures — self-test: controls PASS — …; fixtures: 20/20 passed` (DEV-19), and since the fix(qa) pass its fixtures figure is `fixtures: 24/24 passed`, and `fixtures: 25/25 passed` once case 25 landed (DEV-20), and `fixtures: 40/40 passed` once cases 26 to 40 landed at beat 4, composed from the two invocations Check 83 runs;
    - `DENOM: enumeration-drift — status=fetched declared=8 resolved=8 examined=995 exempted=527 markers=1 resolved.markers=1 unresolved.markers=0 drift=1`;
    - `CTRL: enumeration-drift — PASS: …`;
    - one `WARN:` line naming the six missing and three extra;
    - `OK: enumeration-drift shakedown — within the review window (1d of 60d)`.
    The WARN wrote one row to the shared warn log under `"check":"enumeration-drift"` (`2026-11-14T01:03:18Z`), so W1 is observed live. The run's other FAIL lines belong to other checks (release-body drift; Check 63's #7414 rows), and its exit status is not read.
  - Check 63's primitive → FAIL 6 (#7414's), KNOWN 72, STALE 0, with the module-apis pair still `KNOWN` at `965df7a5030020ed`.
- **Live green (Commit F, `8ce39a10`):**
  - `check-enumeration-drift.py --root . --output-format tsv` → `DENOM files=997 markers=2 resolved=2 unresolved=0 drift=0`, CONTROL PASS, exit 0. The `list` marker reads 14 of 14. The `subset-of` marker reads 6 items, all members of the 24 files of `core/hooks/*.sh`.
  - Check 63's primitive → FAIL 6 (unchanged), KNOWN 71, STALE 0, and 0 rows for `docs/module-apis.md`.
  - `deploy.sh --check`, Check 83's own lines: the fixtures line as at E; `DENOM: enumeration-drift — status=fetched declared=8 resolved=8 examined=995 exempted=527 markers=2 resolved.markers=2 unresolved.markers=0 drift=0`; `CTRL: enumeration-drift — PASS: …`; `OK: enumeration-drift — 0 drift over 2 marker(s)`; and the shakedown OK line. No new warn-log row was written: the count of `"check":"enumeration-drift"` rows stays 1. Check 63's block reads `pairs=544` (545 at E) and FAILs only on #7414's rows, and neither run printed a `count-structure-baseline` stale line.
- **U5 limb 3 — the near-miss arm at every narrowing parameter, each with its must-flag twin:**
  - default (`--root .`) → 0 DRIFT for the live `subset-of` marker; the twin, the same text with that marker turned to `list`, run through the real `evaluate()` over the tracked list → 1 DRIFT (`listed=6 population=24`).
  - `--path docs/module-apis.md` → drift 0, and `--paths-from <file listing docs/module-apis.md>` → drift 0.
  - `--root <temp non-git tree>` with `--path`: `pop/*.sh subset-of` over a and b → drift 0; the same document marked `list` → 1 (`missing=c.sh`).
  - `--fixtures`: cases 2 and 15 to 17 → 0, with cases 1 and 18 → 1 each.
  - `--self-test`: `subset−` and the two `keys` arms → flagged 0, with `list+` → 1.
- **Reference durability:** the four detector expressions of `core/hooks/lib/fragile-ref-patterns.sh` were read as text and run through python3 `re` over beat 3's added markdown lines:
  - `duplicate-source-discipline.md`: link 1 (§ 1.1's register link, covered by the file's `allow-link` marker), with cutover, raw URL and issue reference each 0.
  - the standard: 0 · 0 · 0 · 0.
  - `docs/module-apis.md` and the tools README sit outside the library's durable scope (`is_durable`).
  - Control: a seeded file with one instance of each → 1 · 1 · 1 · 1.
- **Links:** `check-doc-links.py --require-targets` over the five changed markdown files and the template → 0 broken, exit 0 (control: its `--self-test`, 12 fixtures passed).
- **Skill packages:** `build-skill-packages.sh --skills-for-paths` over beat 3's 13 paths, on stdin → 0 skills. Control: `release/skills/release-hub/SKILL.md` → `release-hub`. No package is rebuilt.
- **Runtime suites** (the selection map's rows 2, 4 and 5):
  - Row 2 (`core/deploy/**`): the escape suite, the advisory-emitter contract, the gate-efficacy declarations suite and `deploy.sh --self-test` pass (above), and so do `test_deploy_sandbox.sh` (6 passed, 0 failed) and `test_deploy_path_literals.sh` (10 passed, 0 failed) at the green head. `test_sandbox_roots.sh` and `test_install_exit_propagation.sh` were each refused locally by `BLOCK-DESTRUCTIVE-022`, as scripts outside the execution allowlist, and `test_notify_version_skew.sh` is absent from that allowlist too and was not attempted. None of the three is run here; the release PR's `Shell harness (macOS)` job runs them.
  - Row 4 (`check-selftest-coverage.py --run`): 80 of 81 discovered self-tests pass, `check-enumeration-drift.py` among them. The one failure, `release/tools/cleanup-orphan-state.sh`, is a 300-second timeout (exit 124) under host load, outside beat 3's write set. Its interrupted run left an untracked copy of itself in `release/tools/`, which was moved to the Trash.
  - Row 5 (`run-install-regression.sh`, with `PMO_REGRESSION_EMIT=0`): `INSTALL-REGRESSION: 4410 passed, 0 failed — VERDICT PASS [env: home-account; skipped: 0]`, at the green head, its hook-test floor included (`AGGREGATE: PASS=3913 FAIL=0`).
  - No `test-run` event was emitted (#8923 output, Decisions & Recommendations).
- **Plan verifier (C4):** `bash release/tools/verify-release-plan.sh --format=json --stage4-comment <the Stage-4 part-1 body>` at `8ce39a10` → 11 PASS · 2 FAIL · 17 SKIP · 5 UNRUNNABLE · 0 ERROR over 35 records, exit 3.
  - FCM-3 and FCM-4, the drift tool's and its fixture file's ADDs, now pass.
  - #6225 AC-1, AC-2 and AC-4 move from FAIL to UNRUNNABLE. Each one's machine limb passes (the `enumerates:` count 3; the `# gate-efficacy:` count 6; the three-site diff 3 over 20 changed paths), and its `[READER-GRADED]` limb is one this verifier does not grade, so Stage 8 grades it.
  - The two FAILs are beat-4 deliverables: #7842's two quality-share fixture ADDs.
  - `FCM-COVERAGE` PASS (`declared=47 interpreted=47 obligations=6 excluded=16 conditional=0 uninterpreted=0 pathless=0`).
  - `PROV-DELTA` is not cited: the BSD-awk defect recorded at Commit 0 reproduces, with the same stderr.
- **CIAC lint:** `--ciac-lint` on this file → `declared=5 parsed=5 clean=0 declared-deferral=5 flagged=0`, rc 0.

### Beat 1b — #6227's second agent limb (Stage 6 B1/C4)

- **Entry — the operator's commit:** `642345e5`, signed, is on the branch and touches only `release/governance/RELEASE_PROTOCOL.md`. numstat against `origin/main` → `22 0`; the file's blob is `009d7f04`, sha256 prefix `7164cc1c76a85fc6`, the post-image the Form 1 patch states. The five read-backs of #6227's Change 3 → 1 · 1 · 1 · 1 · 0 (the rule's heading, the `· when-to-version: WV-` segment, the behavioral-correction `patch` row, `Release Planning mode (Mode B)`, and the dropped "how chosen in practice" clause). This beat neither writes nor stages that file.
- **Commit 1 (`b873e554`, signed):** Change 4 and Change 5, each block taken by script from #6227's revision-1 Output for Stage 6 (`#8917 comment 6865291333`), every anchor asserted to occur once. numstat: `2 0` for `stage-03-bundle.md` and `2 1` for the standard, the counts the design specifies.
  - The citation paragraph sits after the `version-less` bullet and before the paragraph opening "The mode is **orthogonal to bundle size**".
  - Row B sits directly after row A, so it now stands between row A and #6226's R-1. The order of the register rows stays by beat.
  - #6227's Version History row is replaced in place with its two-row form. It is no longer the table's last row, and #6226's and #6225's rows stay after it.
- **Commit 2 (`cff3c35e`, signed):** record line 2, taken verbatim from #6226's Change E (`#8918 comment 6865473339`), directly under line 1, with one blank line between them so that each renders as its own paragraph.
  - `changed: the document` and `why:` keep their specified values. The operator's commit changes only `RELEASE_PROTOCOL.md` and re-classifies no live release.
  - Its rule names the case in § Versioning, which is what `duplicate-source-discipline.md` § 1.2 step 2 describes.
- **AC-3 Stage-7 probes, read early:** `grep -c -F "when-to-version" release/references/pipeline/stage-03-bundle.md` → 1 (0 before commit 1). `grep -c -F "release-identity-rule-citations" core/standards/gate-efficacy-standard.md` → 1 (0 before; control, row A's name in the same file → 1).
- **AC-1 probes, re-read:** 1 · 1 · 1 · 1.
- **Row B grammar:** a read-only import of `core/deploy/tools/check-doc-gates.py`.
  - `register_rows` reads 96 data rows (95 before). Row B is at row A's index plus one, and R-1 at plus two.
  - `row_cells` reads 5 and `surface_word` reads `prose`. `parse_population` accepts the row as `release-identity-rule-citations`, threshold 100.
  - Controls: copies with a 0% threshold, or with a hyphen in place of the dash after `census`, are refused. All 14 population rows parse clean.
  - `deploy.sh --check-doc-gates --gate g-cl10 --pr <N> --list` is not run: no release pull request exists yet.
- **Check 62 pointers:** the check's own `runner-def:` and `runner-src:` pointer greps over the standard → 55 and 8, before and after commit 1. #6227's delta is +0 (N8). Control: Check 82's register row → 2.
- **Record-line count:** the bounded count over `### Adjudication records` → 2; the same count over this file at `b873e554`, before commit 2 → 1. The unbounded anchored grep → 2, so there is no copied line.
  - Specificity: a run-directory copy of this file, seeded with a fenced column-0 copy under another heading and a mid-line label. Bounded 2, anchored 3, unanchored 4.
- **Population A instrument, at D5-2's path:** `when-to-version` in `RELEASE_PROTOCOL.md` → 0 at the pin and 3 lines at the head (control, `release-identity mode` case-insensitive at the pin → 3). Non-conforming at the pin and conforming at the head, as the design predicts; the census itself is Stage 13's.
- **Population B instrument:** this spoke's reading of row B's hand-census definition, applied to seven fixture pairs kept in the run directory, untracked. It is a reading, not a runner.
  - Red: the label-form line with no segment → examined 1, conforming 0.
  - Green: the same line with `· when-to-version: WV-1` → 1 of 1.
  - Must flag: the heading form with the segment; `version-less` with `WV-1` and no override; and a prose mention of the rule off the mode line → each examined and non-conforming.
  - Must conform: an override with its reason, and a re-declared mode change carrying the matching row.
  - Near-miss: ms#400 and ms#445, both declared before this release merges, with one live read of each supplied as both the merge read and the census read → not examined. That exercises the instrument's unchanged arm; it does not show the two milestones held still over time. The live read is one paginated read of all 333 milestones (50 open and 283 closed, each cross-checked against the API's pagination links).
  - Of the 62 label-form lines in that read, 0 carry a `when-to-version:` segment yet. Control: the same count over a run-directory copy in which ms#400's line is given the segment → 1.
- **Check 63 primitive:** `python3 core/deploy/tools/check-count-structure.py --root .` before and after commit 1 → `FAIL=6 KNOWN=71 STALE=0`, `pairs_examined=544`, controls PASS. The row sets are identical (#7414's six FAIL rows), so the "one row" to "two rows" Version History change adds no count/structure finding. This file is outside the primitive's scope: `--path` on it resolves 0 files and the primitive refuses with an input failure rather than reporting a zero.
- **Reference durability:** the four detector expressions of `core/hooks/lib/fragile-ref-patterns.sh`, read as text and run through python3 `re` over commit 1's three added lines → link, cutover, raw URL and issue reference 0 each. Control: a seeded file with one instance of each → 1 · 1 · 1 · 1. This file's added lines are not examined by `reference-durability.yml`, whose path allowlist exempts `release/releases/plans/`.
- **Links:** `check-doc-links.py --require-targets` over `stage-03-bundle.md`, the standard, `decision-discipline.md` and this file → 0 broken, exit 0 (control: its `--self-test`, 12 fixtures passed). The markdown link opener occurs 0 times in this file.
- **Skill packages:** `build-skill-packages.sh --skills-for-paths` over beat 1b's three paths, on stdin → 0 skills. Its rule (b) covers injected canonicals. Control: `release/skills/release-hub/SKILL.md` → `release-hub`. No package is rebuilt.
- **Plan checks on this file:**
  - `claim-version.sh --verify-stamp obligation-runners-declared` → exit 0, a plan-only manifest.
  - `--ciac-lint` → `declared=5 parsed=5 clean=0 declared-deferral=5 flagged=0`, rc 0.
  - `lint_release_corpus.py --check plan-identity` → exit 0, and no finding names this file.
  - The literal release-version placeholder → exactly 1.
  - The handle, a home path, a scratch path and a GitHub host string → 0 each. Controls, each from the run directory: the handle → 1 in the saved milestone read; the home path and the scratch path → 1 each in a seeded file; the host string → 1 in the seeded file of the reference-durability control.
- **Plan verifier (C4):** `bash release/tools/verify-release-plan.sh --format=json --stage4-comment <the Stage-4 part-1 body>` → 11 PASS · 2 FAIL · 17 SKIP · 5 UNRUNNABLE · 0 ERROR over 35 records, exit 3. The roll-up is the same at `8a414501`, at `cff3c35e`, and on this file once this subsection was written.
  - #6225 AC-4's scope limb now reads 3 over 21 changed paths, where it read 20: `stage-03-bundle.md` is the new path.
  - The two FAILs are beat 4's two quality-share fixture ADDs.
  - `FCM-COVERAGE` PASS (`declared=47 interpreted=47 obligations=6 excluded=16 conditional=0 uninterpreted=0 pathless=0`).
  - `PROV-DELTA` is not cited, because the BSD-awk defect reproduces.
- **Runtime suite:** none selected. The change is doc and governance text only (the selection map's no-match row), so the honest record is a suite skip.

### Beat 4, step 1 — the merge of `origin/main` (Stage 6 B1/C4)

- **Entry:** PR #8821 reads `MERGED`, merge commit `1c2130c5`. The release head was `8f9497ea`, as the hub's brief expected.
- **Out-of-scope check before the merge:** `git diff --stat 29c60404 origin/main` over `release/skills/release-planner/`, `release/governance/RELEASE_PROTOCOL.md` and `release/references/pipeline/stage-03-bundle.md` → empty, so the merge brings no text that would re-open #6227's AC-5 run (i). Control, the same instrument over `gate-efficacy-standard.md` and `compute-release-velocity.sh` → `7 +-` and `1368 +`.
- **Dry merge:** `git merge-tree --write-tree --name-only HEAD origin/main` → one conflicted file, `core/standards/gate-efficacy-standard.md`, the hub's reading at launch. `script-execution-allowlist.txt`, `docs/module-apis.md` and `RELEASE_INDEX.md` auto-merge.
- **Resolution (DEV-21):** two hunks, (5 ours, 2 main) at the register's tail and (3, 2) at the Version History tail, each resolved by one scripted pass that emits main's side and then ours. Set check: every line of main's file is in the result, and every line of the release head's file is too, except the base's census line `examined: 22 …`, which main itself changed to `examined: 23 …` in a clean hunk. The register now ends with main's two rows (the calibration-revisit rule and the cost row's interim hub write), then A, B, R-1, R-A and R-B.
- **Commit:** `dfd60b3b`, signed (`%G?` → `G`), parents `8f9497ea` and `1c2130c5`, pushed.
- **Freshness (S7-I04):** `python3 release/skills/pmo-skill-refiner/scripts/assert_branch_fresh.py --base origin/main --head HEAD` → `PASS: branch is fresh (0 commits on origin/main unreachable from HEAD)`, exit 0. Sensitivity, the same runner with `--head 8f9497ea` → `FAIL: 145 commit(s) on origin/main not reachable from 8f9497ea…`, exit 1.
- **The release's runners, re-run at the merge:**
  - `check-enumeration-drift.py --self-test` → exit 0, the line unchanged: `count sens=1/1 spec=0/1; list sens=1/1 spec=0/1; subset-of sens=1/1 spec=0/1; unresolved=1/1; parity=ok; keys spec=0/2 guard=1/1`.
  - `--fixtures core/deploy/tests/fixtures/enumeration-drift-fixtures.txt` → `fixtures: 25/25 passed`, exit 0.
  - The live scan, `--root . --output-format tsv` → `DENOM files=1001 markers=2 resolved=2 unresolved=0 drift=0`, CONTROL PASS, exit 0. The 997 files of beat 3 are 1001 with main's additions, and main's auto-merged edit to `docs/module-apis.md` leaves its `list` marker clean.
  - Check 63's primitive, `check-count-structure.py --root .` → `FAIL=6 KNOWN=71 STALE=0`, `pairs_examined=546` (544 at beat 1b), controls PASS.
  - `verify-release-plan.sh --format=json --stage4-comment <the Stage-4 part-1 body>` → 11 PASS · 2 FAIL · 17 SKIP · 5 UNRUNNABLE · 0 ERROR over 35 records, exit 3, the roll-up of beat 1b. The two FAILs are FCM-5 and FCM-6, `declared-add-not-delivered` for the two quality-share fixtures, read over the range `1c2130c5..dfd60b3b`. `PROV-DELTA` is not cited: the BSD-awk defect reproduces.
- **Post-push mergeability:** #8995 head `dfd60b3b` → CLEAR (`MERGEABLE`, `BLOCKED`).

### Beat 4, step 2 — #6225's fixture cases 26 to 40 (Stage 6 B1/C4)

- **Inputs:** the hub's mutant map, its 19 probe cases and its 46 mutants, read from the hub's staging. The 15 cases are the map's rows in its order, each probe block appended verbatim; the map's four excluded probes are not added. The mutants were applied by a run-directory harness that imports the hub's `MUTANTS` table, calls none of its helpers, and writes each mutant over a pristine run-directory copy of the tool beside a copy of `check-count-structure.py`, which the tool loads from its own directory. All 46 anchors occur exactly once, and every mutant differs from the tool. The pristine copy reads `controls PASS` and `25/25`, so a red from that copy is not an import failure. Its sha256 prefix, `c84e08f91804d540`, equals the committed tool's before and after every run.
- **Red, then green, one case per row:**
  - Thirteen of the fifteen mutants read `fixtures: 39/40 passed`, exit 1, over the 40-case set, and each one's only FAIL is its own new case: R21c case 26, R21d case 27, S-tilde case 28, S-strip case 29, S-cstruct case 30, S-mask case 31, S-blank1 case 32, S-cblank case 33, S-subdup case 34, S-prefix case 35, S-fullspan case 37, S-spanslash case 38 and S-linkslash case 40. Each read `25/25` over the 25-case set, so the new case is what turns it red.
  - S-len and S-literal end on a traceback, exit 1, over the 40-case set. Run singly, each on a file holding only its own case, they end the same way: S-len with `IndexError: list index out of range` on case 36, and S-literal with `ValueError: max() arg is an empty sequence` on case 39. The pristine copy reads `1/1` on each file.
  - Green: the committed tool reads `fixtures: 40/40 passed`, exit 0, and its `--self-test` line is unchanged.
- **The 46-mutant sweep (the exit criterion):** over the 25-case set, 29 of 46 are killed by the `--self-test` or the fixtures, and 17 survive. Over the 40-case set, 44 are killed, and the two survivors are RBD (the `boundary-disagreement` verdict) and R25a (the pure-anchor limb of the link skip), the two equivalent mutants the header names. C-guard and C-nested are killed by the `--self-test` alone.
- **Header:** the note under case 21 that the malformed-glob rule's leading-`/` and `..` limbs cannot be told apart by a case is withdrawn, because cases 26 and 27 tell them apart with synthetic populations (F-08). The "not pinned" list names exactly the two equivalents, and the tally reads 10 DRIFT · 19 CLEAN · 9 UNRESOLVED · 2 SCOPE-OUT, 40 in all.
- **Check 83's fixtures line**, composed from its two invocations: `OK:    enumeration-drift-fixtures — self-test: controls PASS — …; fixtures: 40/40 passed`, and over a copy with case 1 relabelled `CLEAN`, `FAIL:  enumeration-drift-fixtures — self-test exit 0, fixtures exit 1: fixtures: 39/40 passed (hard-fail on every mode)`.
- **No other tracked file quotes the set's total:** a search of the tracked files outside `release/releases/plans/` for `25/25`, `24/25`, `25 in all`, `25-case` and `25 cases` returns 9 lines, each a release-log check count or an unrelated figure. Control: the same search over this file, before this step's edits → 5 lines: DEV-20 and the beat-3 Primitive, Fixtures and Check 83 bullets, each extended with the 40-case reading and its older readings kept as labelled history, and step 1's own reading at the merge, kept as it was taken.

### Beat 4, step 3 — #7842's quality-share reading (Stage 6 B1/C4)

- **Base:** the five paths PR #8821 also changed were read at the merged text before any edit. Its change to `compute-release-velocity.sh` (+1368 lines, the `--cost-row` mode and Test CR) is unchanged since `8974f500`, the head the Stage-5 anchors were read at. The other four moved only in `[cost_unit]` wording and the cost-row cutover. `label-taxonomy.md`, `initiative-roadmap-framework.md` and `stage-13-close.md` are unchanged by main.
- **Commits, each signed and pushed as it landed:** `0fbd8d57` the mode, its functions, Test QS and the two fixtures · `a5b19da5` the band's home in the template, its schema rows and notes, the reference subsection, the label-taxonomy and roadmap-framework sentences, and § 7b with its CLI lines and consumer row · this subsection's commit, the register row, its Version History row and A14.2.
- **Byte-identity of the other modes:** before any edit, the field (`v5.07 --milestone 441`), its `--json`, and four refusals (`--out-dir` without `--cost-row`, `--cost-row` without `--out-dir`, `--cost-row --json`, no `--milestone`) were saved. After the mode landed, all eight stdout and stderr captures compare equal (`cmp`). The `--self-test` output is unchanged except for one added summary line.
- **The mode, red then green:**
  - Before any edit, `bash release/tools/compute-release-velocity.sh v0.00 --quality-share --window-json release/tools/tests/fixtures/quality-share/out-of-band.json` → `ERROR: Unknown flag: --quality-share`, exit 1.
  - With the mode and before the template section: the same command → exit 3, `quality-share: NOT-EVALUATED — [quality_share_band].counted_label absent — no value at either rung (rungs read: template core/config/platform-config.toml.template · individual …)`.
  - With the section: exit 0, `quality-share: ABOVE-CEILING — pooled 40.0% against the band 15.0%–35.0%, judged over 5 releases (an advisory reading, not a close verdict)`, the this-release line carrying `unlabelled 1`, and the window line `pooled 8 of 20 (40.0%, judged) · mean of shares 40.0% (reported beside, not judged)`. The printed record equals the specification's record byte for byte (1,484 bytes).
  - The near-miss, `boundary-near-miss.json` → exit 0, `quality-share: IN-BAND — pooled 35.0%`: silent at the ceiling.
- **Test QS, red then green:** the twelve arms went in with no function, argument or dispatch behind them. `--self-test` → exit 1, `ERROR: self-test QS: 49 quality-share check(s) failed`, with a FAIL line in every arm from QS-1 to QS-12, each naming the expected and the observed value (for example `FAIL: QS-1 seeded red — expected: exit 0, quality-share: ABOVE-CEILING — pooled 40.0% · observed: exit 1,` and `FAIL: QS-11 (c) guard red — expected: release merge cccccccc (#13, release/c) precedes a … · observed: take 127:`). With the implementation → exit 0, with the new summary line. Mutations m1 to m6 are Stage 7's, in a throwaway worktree, per the specification.
- **Argument refusals:** `--window-json` without `--quality-share`, `--quality-share` with `--cost-row`, `--merge-sha` or a cost-row flag, and `--quality-share` with neither `--milestone` nor `--window-json` → exit 1 each, naming the rule.
- **The plan verifier, red then green:** at the merge it read FCM-5 and FCM-6 FAIL, `declared-add-not-delivered`, for the two fixtures. At `0fbd8d57` → 13 PASS · 0 FAIL · 17 SKIP · 5 UNRUNNABLE · 0 ERROR over 35 records, exit 0, with FCM-5 and FCM-6 `declared-add-delivered`.
- **The A14.2 obligation's runner (Check 62), red then green:** the register row went in before A14.2. `bash core/deploy/deploy.sh --check` then printed `runner-def release/references/pipeline/stage-13-close.md::quality-share-record — file exists but does NOT carry anchor 'quality-share-record' (R1 fails: named runner cannot surface this predicate)` and `WARN:  register-runner-resolution — 1 of 64 register resolution pointer(s) do not resolve`. With A14.2 in, the same run reads `OK:    all 64 gate-coverage register resolution pointer(s) resolve`. The Check 62 pointer grep reads `runner-def` 55 → 56 (+1, N8) and `runner-src` 8 → 8. In `stage-13-close.md`, `quality-share-record` occurs once and `quality-share-records` 0 times. A read-only import of `check-doc-gates.py` reads 99 register data rows with this one last: 5 cells, Surface `prose`, and `parse_population` gives `quality-share-records` at threshold 100. Its controls, a 0% threshold and a hyphen after `census`, are refused, and all 17 population rows parse. Over the two files, the doc-link check finds 0 broken, and the four durability detectors read 0 each over the 4 added lines. Each run's exit status is not read: both carry the same two pre-existing FAIL lines, release-body drift and Check 63's six rows. The population half of this runner is first observed at this release's own Stage 13.
- **Lints:** `check-doc-links.py --require-targets` over the five changed markdown files → 0 broken, exit 0 (its `--self-test`: 12 fixtures passed). The four detector expressions of `core/hooks/lib/fragile-ref-patterns.sh`, run through python3 over the 72 added doctrine lines → cutover, raw URL and issue reference 0 each. The link class reads 2, each a link already on a line the edit changed, in a file that declares `allow-link`; control, a seeded file → 1 · 1 · 1 · 1. Check 63's primitive → `FAIL=6 KNOWN=71 STALE=0`, the merge's six rows, none in a changed file. The template section's eight non-comment lines each parse as `key = value`. On the tool's added lines, a pipe into a short-circuiting reader → 0 over 867 lines (control 2 of 2), and shellcheck reports one warning there, a deliberate `~` display form, now carrying its own disable directive with its reason.
- **Live smoke (a Stage-6 check, not the graded reading):** `bash release/tools/compute-release-velocity.sh v5.07 --milestone 441 --quality-share` → exit 0. It reads `ABOVE-CEILING — pooled 38.5%` (5 of 13), with the mean of shares 46.7% reported beside it. The window is v5.07, v5.06, v5.05, v5.04 and `stage-document-model-decision`, the guard counts 15 commits and 5 release merges, each with a row, and the per-release lines give 1 of 1, 1 of 3 and 3 of 3. That is the specification's Stage-7 step-5 prediction. The first live run of the dispatch reached all five membership reads. `--json` on the seeded fixture → `ABOVE-CEILING`, 40.0%, pooled 2/5.
- **QS-7 resized:** its windows were 128,762 bytes, passed as one argument, within 2.3 KB of Linux's 128 KiB per-argument cap. They now read 219/625 and 7/20, the same fractions, at about a quarter of the size, and the self-test still passes.
- **Not run here:** the graded live readings (Stage 7 steps 5 to 8) and the mutation proofs (step 4) are Stage 7's. The population half of the A14.2 runner is first observed at this release's own Stage 13.

### Beat 5 — release-wide self-verification (Stage 6 C4)

- **Entry:** the remote release branch read `c28ec4dd` and `origin/main` read `1c2130c5`. `assert_branch_fresh.py --base origin/main --head HEAD` → `PASS: branch is fresh (0 commits on origin/main unreachable from HEAD)`. Each check below ran at `50da3d5f`, the C1 commit. The release-link, CIAC and verifier checks ran again on this file with this subsection written.
- **Baselines at `c28ec4dd`, before any edit:** G6-05's grep, `grep -qE '^#{2} Change Description' <this file>` → exit 1 (control: the v5.08 plan → exit 0). The link openers in this file → 0. The literal release-version placeholder → 1. The verifier and CIAC readings are given below.
- **C1 (`50da3d5f`):** § Change Description is appended after `### Adjudication records`, because this plan has no Deployment Execution Log. It runs 51 lines from its heading to the end of the file, inside the protocol's range of 40 to 100. G6-05's grep now reads exit 0. Neither the protocol nor stage C1 names a lint for the section, so G6-05 is the only check that reads it. The section writes no markdown link; its last cross-reference gives the reason.
- **1. Doc-link check** (Check 14's engine, with `link-check.yml`'s arguments): `python3 core/deploy/tools/check-doc-links.py --target-paths-file core/deploy/allowlists/doc-link-target-paths.txt --allowlist core/deploy/allowlists/skip-doc-link-check-ci.txt --output-format github --require-targets --exclude-code-blocks` → exit 0, with no annotation (the JSON form reads `[]`). `--self-test` → 12 fixtures passed, exit 0.
  - Population, from the tool's own resolver: 19 scope globs resolve to 543 files, 0 of them allowlisted, so 543 are scanned. Of these, 14 are among this release's 30 changed paths (`git diff --name-only origin/main...HEAD`) and give 0 findings. The other 529 are pre-existing and also give 0. This file is outside the scope, because `release/releases/` belongs to `check-release-links.py`.
  - Red: a full-tree copy, made with `rsync` and without `.git`, run through the same arguments plus `--workspace-root <copy>`. Unseeded, it exits 0, not 3, so the copy is complete. With one broken link appended to the copy's `core/standards/duplicate-source-discipline.md`, it exits 1 with one `broken-cross-ref` annotation at that line.
- **2. Release-corpus link checker:**
  - The Dead-file-reference gate's delta form: `python3 release/tools/check-release-links.py --roots core release docs .github --top-level-md --check-anchors --images --diff-base 1c2130c5 --files <the 17 changed markdown files>` → `0 broken links across 0 files`, exit 0, with no missing-anchor block. That summary counts files with a break, not files read. The tool's own `iter_markdown` and `added_lines_for` give the denominator: 17 changed markdown files, none absent and none carrying the gate's override marker. All 17 are in the walk and each has added lines; this file is one of them.
  - `release-link-check.yml`'s three steps: `--self-test` → exit 0. The bare `python3 release/tools/check-release-links.py` → 0 broken over 731 markdown files under `release/`, exit 0. `--plan-depth-lint` → 0 depth-sensitive plan links, exit 0.
  - Red: one broken relative link appended to an already-committed line of § Change Description, in the working tree only, with the line count unchanged and nothing staged. The delta form → 1 broken, exit 1. The bare walk → 1 broken, exit 1. The depth lint → 1 depth-sensitive link, exit 1. The exact reverse edit then restored the line; `git status --porcelain` read empty, and the file's blob equalled HEAD's (`bc539481`).
  - A copy outside the repository cannot serve as this arm. The delta form reads its added lines from committed history, so a seed in a copy, or in an untracked file, reads green.
- **3. Reference durability** (`reference-durability.yml`):
  - The workflow's own run at `c28ec4dd` (job `Durable-corpus fragile-reference delta`, success). Its fixture probe → `27 FLAG / 24 CLEAN, 51 passed, 0 failed`, which is that job's sensitivity and specificity arm. Its scan → `Population: 17 changed .md file(s); 11 in the durable corpus, of which 2 exempted by the path allowlist, 0 deleted (nothing to scan) and 9 examined`, with no net-new fragile reference.
  - That verdict carries to this head [INFERRED]. Beat 5 adds lines only to this file, which the path allowlist exempts as `release/releases/plans/`, so neither the examined set nor its added lines change. The job's run at this head is NOT-EVALUATED here: this spoke does not wait on CI.
  - The step itself is not run locally. It is a shell body that sources `core/hooks/lib/fragile-ref-patterns.sh`, and a run-directory shell script is outside the script-execution allowlist (`BLOCK-DESTRUCTIVE-022`, as at beat 4).
  - The local reading is therefore a labelled transliteration, not the step. A python3 pass reads the library's constants as text and applies the step's scope, its fence-aware added-line mapping and its per-file markers. Its population reads 17 · 11 · 2 · 0 · 9, the job's own figures. Classes L, V and U → 0 on each of the 9 files' added lines, and the issue-reference class, run through the job's own `core/hooks/lib/positional-issueref.awk`, → 0 on each.
  - Red, through the same pass: a seeded file → L 1 · V 1 · U 1 · issue-reference 1. Near-misses: a cutover sentence with no version token → V 0, and a hex colour → issue-reference 0.
- **4. CIAC lint:** `bash release/tools/verify-release-plan.sh --ciac-lint <this file>` → `CIAC-LINT-SUMMARY declared=5 parsed=5 clean=0 declared-deferral=5 flagged=0`, exit 0, at `c28ec4dd`, at `50da3d5f` and on this file. Red: a scratch copy with CIAC-5's method rewritten as prose → `CIAC-5 FLAG no-runnable-command`, `flagged=1`, exit 3.
- **5. Plan verifier:** `bash release/tools/verify-release-plan.sh --stage4-comment <file> <this file>`, where `<file>` holds the bodies of `#8897 comment 6858855052` and `#8897 comment 6858858487`, in that order, joined by one newline.
  - Result: 13 PASS · 0 FAIL · 17 SKIP · 5 UNRUNNABLE · 0 ERROR over 35 records, exit 0, at `c28ec4dd`, at `50da3d5f` and on this file. That is the hub's reading, with no difference.
  - `FCM-COVERAGE` → `declared=47 interpreted=47 obligations=6 excluded=16 conditional=0 uninterpreted=0 pathless=0`.
  - One of the 13 PASS rows is `PROV-DELTA`, and on this host it is vacuous: stderr carries `awk: newline in string domain_practice-labe…` three times, the BSD-awk defect recorded at Commit 0.
  - Red: one undelivered ADD seeded into this file's File Change Matrix, in the working tree → FCM-7 `declared-add-not-delivered`, 13 PASS · 1 FAIL over 36 records, exit 3. The exact reverse edit restored it, and the blob again equalled HEAD's.
  - A seeded copy outside the repository is not a control. It reads 26 records, not 35, because the always-on families need the plan inside the repository, so it cannot read red.
- **Supplementary — the release-corpus lint**, which the Implementation Sequence's beat-5 row may also mean by "corpus lint": `python3 core/deploy/tools/lint_release_corpus.py --check all` → exit 1, on one line: `FILENAME-NONCOMPLIANT` for `release/releases/plans/v3.96_agent-finops-foundation_RELEASE_PLAN.md`. That file is outside this release's diff and was last changed on `main` at `11f31da7`, so the finding is reported, not fixed. Every other line is an advisory, and none names this file or the moved note. `--check plan-identity` and `--check note-content` → exit 0 each.
- **Other C4 items:**
  - `claim-version.sh --verify-stamp obligation-runners-declared` → exit 0, a plan-only manifest.
  - `build-skill-packages.sh --skills-for-paths`, reading this file's path on stdin → 0 skills (control: `release/skills/release-hub/SKILL.md` → `release-hub`). No package is rebuilt.
  - Runtime suite: none selected. The change is plan text only, the selection map's no-match row, so the honest record is a suite skip.
  - The literal release-version placeholder → 1. Link openers → 0. `**Adjudication record:**` label lines → 2, both under `### Adjudication records`.
  - The handle, a home path, a scratch path and a GitHub host string over this beat's added lines → 0 (control: the saved Stage-4 comment record → 1).
- **`origin/main` moved during this beat.** At the fetch before the beat-5 push, `origin/main` read `d293361e`, the merge of PR #9030, ms#429's Stage-12 release-log chore. That is 3 commits past `1c2130c5`, and `assert_branch_fresh.py --base origin/main --head HEAD` now reads `FAIL: 3 commit(s) on origin/main not reachable from HEAD`. Main is not merged here; merging it is the hub's routing call. The checks above are unaffected, because each three-dot range takes the merge base `1c2130c5`, which has not changed.
- **Findings on lines this release added:** three, each fixed in this beat. (1) § Change Description's Stage-13 bullet stated that ms#429's release-log row was absent from `main`, and PR #9030 has since put it there; the bullet now states the dependency rather than the state. (2) Its #6225 row credited the 40 cases alone with killing 44 of 46 mutants; beat 4 step 2 records that C-guard and C-nested fall to the `--self-test` alone, and the row now says so. (3) Its C2 (A) bullet placed beat 1b during beat 3; the first-parent log puts Commit F and beat 3's evidence between the operator's commit and beat 1b. Findings (2) and (3) were found by reading the section's figures and order words against their sources after the first push of this beat. The release-link, CIAC and verifier checks were re-run on the corrected file with the same results. No file other than this one is touched. The one pre-existing finding is the `FILENAME-NONCOMPLIANT` line above, which is reported.
- **Header Status:** rewritten to the branch as it stands after this beat. It is a maintained field (the template's usage rule 2), so no deviation row is added.
- **Post-push mergeability:** #8995 head `50da3d5f` → CLEAR (`MERGEABLE`, `BLOCKED`).

### fix(dt) pass 1 — #7842, with #6225's F-10 (Stage 6 B1/C4)

- **Entry:** the remote release branch read `fc82efbb`, the brief's precondition, and `origin/main` read `d293361e`. `assert_branch_fresh.py --base origin/main --head HEAD` → `PASS: branch is fresh (0 commits on origin/main unreachable from HEAD)`, exit 0.
- **Commits, each signed and pushed as it landed:** `40f7aaf8` Steps 1 and 2 · `0b391110` Step 3 · this subsection's commit, Step 4.
- **Step 1 — F-02, the argv bound in § 7b:**
  - The reason line is read from the tool. `_rv_qs_take` sets `the quality-share step <step> did not complete (no OK sentinel)` when a step prints no `OK`. The first-parent list enters the `window` step as one argument, and that step's stderr goes to `/dev/null`. A capped reading therefore prints `quality-share: NOT-EVALUATED — the quality-share step window did not complete (no OK sentinel)`, exit 3, and names no cause.
  - Re-measured as the tool holds the list, the joined `git log --first-parent --format=%H%x09%s` lines without the final newline. On `main` at `d293361e`, the history a closing merge's reading walks, it is 106,502 bytes over 884 commits: 81.3% of 131,072, with 24,569 bytes of headroom counting the terminating NUL. That is DT's figure exactly.
  - The release head's own first-parent list, at `fc82efbb`, reads 110,872 bytes over 915 commits (84.6%). It runs down the branch's own commits, which a release merge puts on its second parent, so no reading passes that list, and the bullet gives `main`'s figure. The growth rate, 470–524 bytes a release, is DT's measure and is not re-measured here.
  - Before the edit, § 7b's Known bounds carried 3 bullets and 0 mentions of `MAX_ARG_STRLEN`; after it, 4 and 1.
- **Step 2 — F-03 under PA-015 (A), A14.2's re-run:**
  - The reasons are read from the tool's `--quality-share` path, which prints 13 literal reasons. Five of them say that a read failed or could not be read, and the clause quotes the four that PA-015 names. The fifth, `whether this clone is shallow could not be read`, is not one of PA-015's reads, so it is still written as printed. A python3 comparison of the clause's four code spans with the tool's `_rv_qs_ne` reason strings, each placeholder normalized, → 4 of 4 equal.
  - **Red — a forced failed read.** The session worktree stood in for the throwaway copy. One unknown flag was seeded onto the membership call's `gh issue list` line, in the working tree only. `bash release/tools/compute-release-velocity.sh v5.07 --milestone 441 --quality-share` → exit 3, `quality-share: NOT-EVALUATED — the membership read for fs-boundary-refuses-parameter-transformation (milestone 441) failed (no reading was taken; this is not a clean result)`, with stderr empty. The exact reverse edit then restored the line: the file's blob equalled HEAD's (`16fcb1c1`), and `git status --porcelain` read empty.
  - Control: the same command on the unmodified tool → exit 0, `ABOVE-CEILING — pooled 38.5%` (5 of 13), mean of shares 46.7%, guard 15 commits and 5 release merges. That is DT pass 1's live reading.
  - **Why the worktree and not a copy.** A git configuration injected through the environment, to fail `git log` alone, was refused three times by the worktree-isolation control, and was not attempted by another route. A copy of the shell tool under the run directory sits outside the script-execution allowlist, as at beats 4 and 5, and a nested worktree is barred.
  - **Not covered — a non-read reason.** This is the brief's example, a template with no `[quality_share_band]` section. `PMO_SRC_ROOT` pointed at a run-directory tree whose template copy lacks the section's 82 lines, and `PMO_PLATFORM_CONFIG_ROOT` at an empty run directory. Over the offline fixture `out-of-band.json` → exit 3, `NOT-EVALUATED — [quality_share_band].counted_label absent — no value at either rung (rungs read: template core/config/platform-config.toml.template · individual …)`.
  - **Matched against the clause.** A python3 matcher is built from the four code spans of A14.2's line, each placeholder a wildcard, and classifies printed reasons.
    - Re-run allowed, 5 of 5: the forced record; DT pass 1's v5.08 record, `the membership read for never-invoked-specialists-dispositioned (milestone 445) failed`, transcribed; and the other three forms, filled in.
    - Written as printed, 0 of 7 matched: the non-read record and six near-misses. The near-misses are a counted label that `does not exist on the repository`, a membership read refused at its limit, one that `is not JSON`, a milestone that `does not resolve to a title`, a step with no OK sentinel and an unreadable shallow flag.
  - **The anchor.** `**quality-share-record**` occurs once in `stage-13-close.md`, bolded, on A14.2's line; the bare token occurs once, and `quality-share-records` 0 times. Control: the token over `core/standards/gate-efficacy-standard.md` → 4.
  - **Cascade**, the rename-reference-cascade discipline applied to a restated rule. Probe, over the 2,226 tracked files: `git grep -n -i -E '(re-run|once more).{0,200}(row (lands|reaches)|has not landed)|(row (lands|reaches)|has not landed).{0,200}(re-run|once more)'`.
    - At `fc82efbb` it returns 2 lines, A14.2 and § Change Description's Stage-13 bullet, and 0 of the 2 names the failed read. After Step 2 it returns the same 2, and both do. With this subsection written it returns 4: those 2, plus the bullet above, which quotes the probe, and the wider-search line below, which quotes its phrases. Neither of those restates the rule.
    - A wider phrase search (`replaces the first`, `once the row lands`, `run the same command once more`, `one re-run`, `single re-run`, `in-phase re-run`, `re-run once`) returns 7 lines at `fc82efbb`. The other 5 are unrelated re-runs.
    - Kept unchanged, each because it states no re-run rule: § 7b, which says A14.2 writes the block; the gate-coverage register row, whose Act clause writes the block or the hand-written record, and which Stage 7 found byte-identical to the specification's Change 11; and the platform-config reference's window paragraph, which says a lagging row reads `NOT-EVALUATED`.
- **Step 3 — #6225 F-10 under PA-016 (A):**
  - One sentence over three comment lines, after the two equivalents' bullets and before the tally. It stands at block level, because neither rule is an equivalent.
  - `check-enumeration-drift.py --fixtures core/deploy/tests/fixtures/enumeration-drift-fixtures.txt` → `fixtures: 40/40 passed`, exit 0, before and after. `--self-test` → exit 0, its output byte-identical before and after (`cmp`): `count sens=1/1 spec=0/1; list sens=1/1 spec=0/1; subset-of sens=1/1 spec=0/1; unresolved=1/1; parity=ok; keys spec=0/2 guard=1/1`.
  - `git diff -U0` of the file → 3 lines added and 0 removed, and every added line opens on `#`. Control: a run-directory copy with the first new line un-commented → `INPUT-FAILURE: … line 107 is neither a comment nor a case header`, exit 3. The parser reads the new lines as comments because of their `#`.
  - The 46-mutant reading is the hub's to confirm after this edit, as its decision record states; it is not run here.
- **Step 4 — this file:**
  - F-04: `wc -c` on the printed record of `out-of-band.json` → 1,484 bytes. The record is 1,453 characters, and 1,452 without the final newline. Search, over the tracked files: `git grep -n -E '1,?452 ?bytes|1,?452 B\b|1,?452-byte'` → 1 line before (beat 4 step 3), 0 after.
  - DEV-21 is extended with the second freshness merge, and DEV-24 is added, so the one `DEV-<n>` sequence runs DEV-1 to DEV-24 under one header.
  - The Header Status names this pass. § Change Description's `DONE (Stage 6)` note still sent #7842 to Stage 7 and #6225 to its pass 4, so it is restated to the branch after this pass. Its #7842 and #6225 rows remain true and are unchanged.
- **Runtime suite:** the fixture file matches the selection map's row 2 (`core/deploy/**`).
  - Its only executable consumer is `core/deploy/deploy.sh` Check 83, whose two invocations are run above. A search of the tracked files for the file's name returns `deploy.sh`, the tools README, this file and the fixture file itself.
  - Two row-2 suites ran here: `test_deploy_sandbox.sh` → 6 passed, 0 failed, and `test_deploy_path_literals.sh` → 10 passed, 0 failed. The other row-2 suites are left to the release pull request's jobs, which this pass does not wait on.
  - The other three changed files are doc and plan text, the no-match row.
  - No skill package is affected: `build-skill-packages.sh --skills-for-paths`, reading the four paths on stdin, names none. Control: `release/skills/release-hub/SKILL.md` → `release-hub`.
- **Post-push mergeability:** #8995 head `40f7aaf8` → CLEAR (`MERGEABLE`, `BLOCKED`); head `0b391110` → CLEAR (`MERGEABLE`, `BLOCKED`).

### Adjudication records

**Adjudication record:** a version-less release's note sat flat at the `notes/` root, where the release-notes standard places every version-less note under `notes/_unversioned/` · authority: the standard — `release/references/standards/release-notes-standard.md` § File Location, Naming, Frontmatter — which has named the case since 2026-08-22, before this release resolved it · changed: practice — the `governance-ci-checks` note moved under `notes/_unversioned/` and its `RELEASE_INDEX.md` row followed · why: the standard already names the case, and the note was written before that rule landed

**Adjudication record:** `release/governance/RELEASE_PROTOCOL.md` documented `versioned` as the release-identity default, and live practice, as re-read at Stage 4, did not always follow it · authority: the document — `release/governance/RELEASE_PROTOCOL.md` § Versioning, which stated the default and no rule for when a release departs from it · changed: the document — § Versioning gains the when-to-version rule, which names when each release-identity mode applies · why: the document was silent on the case, so this release names it there (`core/standards/duplicate-source-discipline.md` § 1.2, step 2)

---

## Change Description

Authored at Stage 6 C1 per `release/governance/RELEASE_PROTOCOL.md` § Change Description Protocol, from the branch: `git diff --stat origin/main...HEAD`, the first-parent commits, and this file's Decision Record, Delivery and Rollback strategies and Deviation Log. It stands last because this plan carries no Deployment Execution Log section, and it is refreshed if a later Tier 1 [ADJUST] commit changes which issues land or which decisions stand. It is not the user-facing release note.

### Outcome

A governance obligation this release touches now has a runner or a recorded decision that it will not: `deploy.sh --check` gains Check 83, which reports a hand-maintained enumeration whose list or count disagrees with the tracked files its marker's glob matches; `core/standards/duplicate-source-discipline.md` § 1.2 names the side that governs when a written convention and live practice disagree; and `core/disciplines/decision-discipline.md` § 3.2 requires a determination that constrains a code path to be recorded at that path. The standing quality initiative's band is set in the platform-config template's `[quality_share_band]` section — a 15% floor and a 35% ceiling, judged pooled over five releases — and `release/tools/compute-release-velocity.sh --quality-share` measures a release against it, a reading Stage 13 now records at every close (A14.2). The operator-committed hunks in `RELEASE_PROTOCOL.md` § Versioning add the rule for when a release is `versioned` and when it is `version-less`.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #6227 | A constraining determination is recorded where it constrains (`decision-discipline.md` § 3.2); the when-to-version rule sits in `RELEASE_PROTOCOL.md` § Versioning, committed by the operator, and is cited at `stage-03-bundle.md` § Release-Identity Mode; register rows `constraint-determinations-at-path` and `release-identity-rule-citations` | DONE (Stage 6) |
| #6226 | A convention and live practice that disagree are settled by the owning document (`duplicate-source-discipline.md` § 1.2); the flat `governance-ci-checks` note moves under `release/releases/notes/_unversioned/`, its `RELEASE_INDEX.md` row with it; register row `spec-practice-adjudications`; two adjudication records in § Verification Evidence | DONE (Stage 6) |
| #6225 | `core/deploy/tools/check-enumeration-drift.py` behind Check 83 (warn-mode, deploy-time only) reports enumeration drift; 40 fixture cases, which with the `--self-test` kill 44 of 46 mutants (C-guard and C-nested fall to the self-test alone), the two survivors being equivalents; the `docs/module-apis.md` hook list is marked and reconciled (1 drift row, then 0), and two enumerations become citations of their populations; register rows for Check 83 and `enumeration-sites-registered` | DONE (Stage 6) |
| #7842 | `[quality_share_band]` in `core/config/platform-config.toml.template`, with its schema and reference rows; the `--quality-share` mode and its Test QS group (QS-1 to QS-12); § 7b of `release-velocity-tracking.md`; Stage 13's A14.2 and register row `quality-share-records`; an out-of-band fixture that reads `ABOVE-CEILING` and a near-miss at the ceiling that reads `IN-BAND` | DONE (Stage 6) |

`DONE (Stage 6)` records what the branch delivers, not a graded criterion: #7842 goes from its Stage-7 pass 1 and its fix(dt) pass to a DT check of that pass, then to Stage-8 QA; #6225 has completed Stage 8, pending two CI rows; and the criteria are graded at the stages § Verification Plan names.

### Key decisions

Each is rendered in § Decision Record (the Stage-4 gate, the Stage-5 Collective Review and its scope lock):

- **D-Editability-6227 (A):** the operator commits the Tier-0-floored `RELEASE_PROTOCOL.md` limb from agent-prepared text, and no agent writes, stages or applies that file (commit `642345e5`, 22 lines added).
- **C2 (A):** beats 2 to 4 do not wait for that commit, which landed during beat 3; beat 1b ran after beat 3's last commit and before the next gate.
- **D5-1:** a sibling check, Check 83, not an arm of Check 63, whose red on `main` belongs to #7414; the choice is recorded in the tool's module docstring and the check's header.
- **D5-2 with OD-2:** the material-edit test selects the release-identity mode, and a release whose only product is a decision record ships `version-less`.
- **D5-3 and D5-4:** the band is a parameter, judged pooled with the mean of shares printed beside it, over the release log read by merge ancestry with a completeness guard (OD-17).
- **D5-5 (B′):** the index-versus-notes assertion is declined; the decision and its upgrade trigger are recorded in `release/releases/notes/README.md`.
- **D5-6 (A′):** the #5502 site is graded against the existing executor census, with one comment-only citation in `install-tests.yml`; no test suite is switched on.
- **D-C SINGLE, P0 and D-Version minor:** one branch, one pull request, one merge and one writer at a time, at bump-class minor with the number bound at the Stage-12 claim; the planned rebase onto PR #8821's merge ran as a merge commit instead, because this branch never force-pushes (DEV-21).

### Reversibility

**MODERATE — HIGH confidence.** One revert of the release merge restores every file, the operator-committed `RELEASE_PROTOCOL.md` hunks and the moved note included, under the Rollback protocol in `RELEASE_PROTOCOL.md` § Pre-Change Snapshot Protocol; the claimed version tag is retained and recorded, never deleted, and because ms#363's pending `links.plan` edits cite the note's path, a revert is re-read against that sibling.

### Downstream impact

- **This release's Stage 13:** A14.1 writes a population record for each of the five `prose` register rows this release adds (`constraint-determinations-at-path`, `release-identity-rule-citations`, `spec-practice-adjudications`, `enumeration-sites-registered` and `quality-share-records`), and A14.2 takes this release's own quality-share reading. That reading needs the release-log row of every earlier-merged release on `main`, ms#429's among them: a missing row prints `NOT-EVALUATED`, and A14.2 allows one re-run once the row lands, or at once after a failed read (DEV-10).
- **Every later close:** A14.2 runs at each Stage-13 close, and the band's values are re-set after three measured releases. An operator-instance `platform-config.toml` without the `[quality_share_band]` section reads `NOT-EVALUATED`, never a default (§ Operational Deployment Manifest).
- **Deploy time:** `deploy.sh --check` gains Check 83, warn-mode on its own dial, with its shakedown armed on 2026-11-13; the flip to enforce is an operator decision. The corpus scan runs at deploy time only, and CI runs the tool's `--self-test` through the `selftest-discovery` job.
- **Workspace charter:** `core/CLAUDE.md.template` turns one bullet into a citation, which the rendered charter takes at the operator's next composition refresh. No skill package, rules-mirror member, hook or harness artifact changes (§ Operational Deployment Manifest).
- **Carried forward:** the live first-parent list passed on argv, over four fifths of Linux's per-argument cap (DEV-23 (a)); the `PROV-DELTA` limb's BSD-awk defect, which leaves that row's PASS vacuous on this host (§ Verification Evidence, Engineering Commit 0); and the `release-planner` Mode B step-3 follow-up, filed at Stage 13 (§ Scope, Exclusions).
- **Merge order:** ms#363's `links.plan` edits re-read the moved note's path, and the version slot is shared with the other in-flight `minor` releases and settled at the atomic claim (§ Cross-PR Overlap Audit).

### Cross-references

- This plan: § Header (version identity: the double-brace release-version placeholder in the **Version** cell, bound at the Stage-12 claim), § Decision Record, § Implementation Sequence, § Deviation Log and § Verification Evidence.
- Milestone `obligation-runners-declared` (milestone 400), under epic #5867; release pull request #8995, opened in draft at Stage 6; the Release Outcome Statement, in § Release Outcome Statement and in the milestone description.
- The user-facing release note: written at Stage 13 Close under `release/releases/notes/`, named for the version the Stage-12 claim binds, per `release/references/standards/release-notes-standard.md`.
- No markdown link is written here, although the protocol asks for links: the note does not exist before Stage 13, a milestone URL would carry the repository owner's handle into a `release/` file, which the depersonalization gate refuses, and this file carries no link opener (§ Verification Evidence, Engineering Commit 0).

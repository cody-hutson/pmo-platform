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
| **Status** | Executing — Stage 6 Engineering, after beat 1b. On the branch, in this order: Engineering Commit 0 (this file) and beat 1a (#6227's agent limbs); beat 2 (#6226); beat 3 (#6225), during which the operator's `release/governance/RELEASE_PROTOCOL.md` commit landed; and beat 1b (#6227's second agent limb), which followed that commit under C2 (A). Beat 4 (#7842) is not yet on the branch |
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
| #6226 | AC-4 | declared, verification deferred to Stage 8 (reads both superseded observations) | discharged at bundling |
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

Ten inherited rows carry the four designs' Commit-0 entries, renumbered in beat order (#6227, #6226, #6225, #7842) and each citing its source comment. DEV-11 to DEV-13 are the Commit-0 spoke's own entries, and every row after them was added by the beat its Stage cell names. No transcribed plan text is reworded to absorb a correction (N18).

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
  - Six mutants of the tool, each with one rule broken, run from the run directory. `subset-of` asserting completeness → `subset-of spec=1/1`, FAIL. Basename keys → `keys spec=1/2`, FAIL. A count that never drifts → `count sens=0/1`, FAIL. A second preamble line allowed → `unresolved=0/1`, FAIL. The ambiguity guard removed → `guard=0/1`, FAIL. A glob that crosses `/` → self-test PASS, but fixtures 18/19 (case 7), and 19/20 when re-run over the 20-case set at the fix(dt) pass (DEV-19). Every mutant reads red on at least one of the two instruments.
  - Candidate source (DEV-16 (a)): the worktree root, whose `.git` is a file → `git ls-files`; a `mktemp -d` sandbox under the symlinked temporary directory, and the `core/` subdirectory → `os.walk`.
- **Fixtures:** `--fixtures` → `19/19 passed` at Commit A, and `20/20 passed` since the fix(dt) pass added case 20, whose row reads `missing=- extra=- dup=alpha.sh` (DEV-19). Each case's row matches the design's table: case 1 `missing=gamma.sh`; case 4 `extra=delta.sh`; case 5 `stated=2 population=3`; case 18 `extra=lib/other.sh`; case 19 `missing=b/y.md`; cases 9 to 13 `unbound`, `unkeyed-item`, `count-target`, `empty-population` and `malformed`. The harness's own sensitivity arm, a copy with case 1 relabelled `CLEAN`, reads `18/19`, exit 1, and `19/20` over the 20-case set.
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
    - `OK: enumeration-drift-fixtures — self-test: … controls PASS …; fixtures: 19/19 passed`;
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

### Adjudication records

**Adjudication record:** a version-less release's note sat flat at the `notes/` root, where the release-notes standard places every version-less note under `notes/_unversioned/` · authority: the standard — `release/references/standards/release-notes-standard.md` § File Location, Naming, Frontmatter — which named the case before the divergence was reported · changed: practice — the `governance-ci-checks` note moved under `notes/_unversioned/` and its `RELEASE_INDEX.md` row followed · why: the standard already names the case, and the note was written before that rule landed

**Adjudication record:** `release/governance/RELEASE_PROTOCOL.md` documented `versioned` as the release-identity default, and live practice, as re-read at Stage 4, did not always follow it · authority: the document — `release/governance/RELEASE_PROTOCOL.md` § Versioning, which stated the default and no rule for when a release departs from it · changed: the document — § Versioning gains the when-to-version rule, which names when each release-identity mode applies · why: the document was silent on the case, so this release names it there (`core/standards/duplicate-source-discipline.md` § 1.2, step 2)

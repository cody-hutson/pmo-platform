---
version: never-invoked-specialists-dispositioned
date: 2026-11-13
type: plan
status: ACTIVE
issues: ["#8452"]
reversibility-tier: CHEAP
themes: ["cluster:skill-modes"]
audit_class: false
---

# Release Plan — never-invoked-specialists-dispositioned

> **Status:** Stage 6 Engineering. This file is Engineering Commit 0 on the release branch.
> **Identity: VERSION-LESS** (D-IdentityMode, operator, 2026-11-13). The release identity is the capability slug `never-invoked-specialists-dispositioned`. No version key is claimed at any stage, no release-version stamp token is authored, and the Stage-12 rename never fires. At Commit 0, steps 1–3 (version re-verify) are N/A and step 3b (`claim-version.sh --verify-stamp`) reads `TOKEN-LESS PLAN`, which is the correct version-less state and not a HALT. **Do not add the release-version stamp token to make it pass.** The plan moves to `plans/_unversioned/` at Stage 13 close.
> **Topology:** D-C SINGLE — one release branch, one pull request, one merge. **Concurrency:** P0, fully serial.
> **Release Class:** `novel` · **Milestone:** `never-invoked-specialists-dispositioned`.
> **Source of record:** this file. The Stage-4 planning output (comment 6858955934 on #8896) was the working reference until this commit landed. It is transcribed below with the Commit-0 Survival Set, the operator's Stage-4 gate decisions (comment 6859672229 on #8896), the locked Stage-5 specification (revision 2, comment 6863639250 on #8930, §§ 2–5) and the Stage-5 lock with its amendments (comment 6865383443 on #8930). Every departure from the transcribed text is a row of § Deviation Log. Where a lock amendment and revision 2 disagree, the amendment wins.

## Header

| Field | Value |
|-------|-------|
| **Version** | (none) — version-less |
| **Bump Class** | N/A — version-less release; no number binds at Stage 12 (D-IdentityMode rendered version-less by the operator on 2026-11-13) |
| **Date Created** | 2026-11-13 (Friday) |
| **Release Manager** | Agent-assisted (release hub + stage spokes) |
| **Status** | Executing — Stage 6 Engineering |
| **Branch** | `release/never-invoked-specialists-dispositioned` |
| **PR** | the draft release PR opened at Stage 6 Phase C2 |
| **Milestone** | never-invoked-specialists-dispositioned |

### Baseline pin

- **Stage-4 planning baseline:** `origin/main` @ `29c604045def22ebd21fb4a758c3bb56be277b20` (2026-11-13, Friday). Every Stage-4 and Stage-5 probe was run against that commit.
- **Commit-0 base:** `origin/main` @ `29c604045def22ebd21fb4a758c3bb56be277b20`, re-fetched at Engineering Commit 0 — 0 commits since the Stage-4 baseline.
- **`${AUDIT_DATE_UTC}` = `2026-11-13`** (Friday), resolved once with `date -u +%Y-%m-%d` at Engineering Commit 0 and recorded here. Every later session reads this value from this file.

### Commit-0 Survival Set

The nine elements `stage-04-planning.md` § 6 enumerates, and where this file carries each.

| # | Survival element | Where it sits in this file |
|---|---|---|
| 1 | `domain_practice` label | § Recommendations › Release Class declaration — one label, transcribed; no second copy anywhere in this file |
| 2 | File Change Matrix (machine-readable) | § Implementation Sequence › File Change Matrix — fenced; the record row resolved to its literal path (DEV-2) |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria — none; a single-issue release (CIAC lint re-run at Commit 0, § Verification Evidence) |
| 4 | Verification Plan | § Recommendations › Verification Plan — 6 ACs (DEV-3) |
| 5 | release-version stamp manifest | N/A — version-less: the Header **Version** cell reads `(none)`; step 3b reads `TOKEN-LESS PLAN` |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | the Header blockquote and § Recommendations › Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin | § Baseline pin |

## Recorded decisions

### Stage 4 plan gate (operator, 2026-11-13)

**Rendered by:** the operator, 2026-11-13 (Friday), through the hub's plan-gate prompt. **Plan:** the Stage 4 comment above (6858955934).

| Decision | Rendered | Reversibility · confidence |
|---|---|---|
| Plan approval | **approved** | MODERATE · HIGH |
| D-IdentityMode | **version-less**: the close has no version tag and no GitHub Release. The planner recommended versioned · minor; the hub recommended version-less, on the release's starting brief and the `stage-document-model-decision` precedent | CHEAP · MEDIUM |
| D-WorkProductHomes | **(A) one decision record in `core/ADRs/`** holding the Current State (with the census section), Future State, Gap Map and the disposition table | CHEAP · HIGH |
| D-Amendments | **(A) all edits; size stays M.** The planner proposed L; the size rubric counts surfaces, and the largest open option is three surfaces with a new file. Size does not rise for review depth or criteria count | CHEAP · HIGH |
| Milestone-description write | **allowed.** One combined edit landed at 2026-11-13T17:05:13Z | CHEAP · HIGH |

**Recorded determinations, not gates:**
- Release Class `novel`.
- D-C: one branch, `release/never-invoked-specialists-dispositioned`.
- D-Concurrency P0, fully serial.
- D-Version: n/a (version-less).

**Applied:**
- **#8452 body.** AC-1 to AC-3 sharpened; AC-5 and AC-6 added (AC baseline 4 → 6); the E5 exempt line; Affected Files marked as the decision's subject; Documentation Impact names the decision record.
- **ms#445 description:**
  - Outcome Statement refreshed, with the required `Limb owners` line and a Success Indicator aligned with the follow-up sweep;
  - identity-mode line, recording version-less as the operator's confirmation;
  - Documentation Impact;
  - a dated Parallelization Map (no version-slot edge, since the release is version-less);
  - a `[BUNDLE AMENDMENT]` line;
  - the Composition Lock.

**Hub evaluation of the plan's findings:**
- **A0 correction:** concurred after re-running the probe. The briefing's staleness probe was broken, so it read 0 against a true 2. Both commits are body edits, 0 of 22 `description:` fields changed, and the GO stands.
- **Discovery 1:** carried to the Stage 9 ledger as tagged. Its proximate cause was a one-off hub command that passed paths through an unsplit shell variable, not a tracked tool.

**For the Stage-5 brief:** the issue-reference gate blocks a bare issue reference outside a reference block. Inside the record, name downstream cards in prose and list their numbers under `## References`.

**Events emitted (as recorded by the hub)** (stage 4; each read back as `POST == PRE + N`):
- `decision/scope-lock`, operator, milestone (0 → 1)
- `decision/outcome-statement-authored`, operator (0 → 1)
- `decision/d-class`, operator, ×2: `issue:#8452` `card-disposition:carried`, and the milestone's D-decisions (0 → 2)
- `decision/action-item-opened`, `action-item-started` and `action-item-resolved` for AI-001, the Composition Lock (each 0 → 1)

**Next:** Procedure 1 scaffolding. Stages 5–8 for #8452, plus release-scoped Stages 9–13; Stages 10 and 11 close as skipped (compressed, git-native).

### Stage 5 lock (operator, 2026-11-13)

Rendered at the hub's Stage-5 gate. Collective Review does not fire for this release, because only one issue has Solutioning activated, so the lock is per-spoke Procedure 4 handling, recorded as `decision/d-class`.

| Decision | Rendered | Reversibility · confidence |
|---|---|---|
| D-Stage5Lock | **Lock revision 2, with the round-2 review's lock amendments as text** (listed below). The census block stays byte-identical. | CHEAP · HIGH |
| D-OQ1-SAFe | The operator's answer: "I don't have config in toml for safe currently. that may change." So the release train engineer's row reads **keep (dormant by design)**, conditioned on that configuration: if a SAFe configuration appears, the ADR-033 activation gate turns the Specialist on without a record change. | CHEAP · HIGH |
| D-RoundOneScrub | **Scrub.** The first Stage-5 comment named per-account app-data directories, so it was deleted. A line-preserving redaction was re-posted as comment 6865348481, so line citations into the original still match. | IRREVERSIBLE · HIGH |

### D-Ratify (Stage 9) — pending

After Stages 7 and 8 verify the record, the operator renders every disposition in one gate: ratify, ratify with row amendments, or redirect. A redirect sets `iterate:stage-6`. On ratification a Tier 1 commit writes the operator's value into every G4 row and flips the record's `status:` from `Proposed` to `Accepted` before the merge. EXPENSIVE / HIGH.

## Stage-4 plan (transcribed)

## Phase A0 — Triage→Design Re-Review artifact (#8452)

**G-PL5 cache-read: HIT.** `rows_source: mode-r-cache`. Briefing: comment 6857860325 on #8896 (association `OWNER`, the only marker-bearing comment, `part: 1/1`, `schema_version: v1.0`), `emitted_at: 2026-11-13T15:43:04Z`.

| Operand | Recorded (marker, relay time) | Recomputed 2026-11-13T15:53:31Z (Friday), `set -o pipefail`, every read exit 0 | Equal |
|---|---|---|---|
| L1+L2 `card_set_fingerprint` | `f9af849eec1310bea1b6493c12735696808ca6b92f24276dfbb4c0d6c3208556` | same (card set `8452:2026-11-05T16:56:17Z`; 2 returned against `--limit 500`) | yes |
| L3a `milestone_updated_at` | `2026-11-13T15:47:09Z` | `2026-11-13T15:47:09Z` | yes |
| L3b `milestone_description_sha256` | `4467b8c3a03becf1b833602dc007f9b38a0965d2f3d59852fba812bb9c7f5d53` | same | yes |
| L4 `main_head_sha` | `29c604045def22ebd21fb4a758c3bb56be277b20` | same (`git fetch origin && git rev-parse origin/main`; `git ls-remote` agrees) | yes |
| L5 age | `emitted_at` 2026-11-13T15:43:04Z | 0.18 h | within 7 days |

- **The expected operand change lies outside the guard.** The briefing body's capture-time table records `milestone_updated_at` = `2026-11-05T16:59:08Z`. The relay-time marker records `2026-11-13T15:47:09Z`, measured after #8896 was created at 15:47:08Z. The guard tests the marker, so L3a reads equal. [SOURCE: briefing; `hub-spoke-bridge.md` Procedure 0 Step 5(c) § Measurement instant]
- **Byte control:** `printf '8452:2026-11-05T16:56:17Z\n' | shasum -a 256` reproduces `f9af849e…`. The same line without its LF gives `5af42a24…`, and the empty digest is `e3b0c442…`, so the fingerprint is not a failed-read digest. (PV-1, PV-2)
- **MISS conditions all clear:**
  - count 2 < limit 500, and the card set is non-empty;
  - the only `^Stage [0-9]` title belongs to #8896, which carries `sub-task`;
  - the table is the six-column form, 8 rows, with no empty D1/D2/D3 cell. The same parser catches a planted blank-D2 row (control 1);
  - all 8 header fields are present.
- **§ 3.1 PT-2 freshness re-run:** N/A. Enumerated over 8 rows (6 C2, 2 C1): no C3, so no PT-2 citation exists.

**Header (authored at A0):**

| Field | Value |
|---|---|
| `issue_number` | #8452 |
| `release_milestone` | `never-invoked-specialists-dispositioned` (ms#445; identity mode per D-IdentityMode) |
| `stage` | 4 |
| `spoke_author` | Stage 4 Release Planning spoke (Release Manager — Release Planning persona) |
| `re_review_date` | 2026-11-13 |
| `issue_body_revision` | 2026-11-05T16:56:17Z (`updatedAt`; body last edited 16:55:00Z) |
| `triage_decision_date` | 2026-10-24 |
| `effort_tier` | standard (size:M; touches skills) |

**Adopted per-requirement table (verbatim from the briefing):**

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1: census re-run with a control arm, a stated denominator and per-Specialist counts | `review-discipline-principles.md` § 8.1 PV-0 / PV-1 / PV-2 require the exact invocation, the denominator examined and a non-zero sensitivity arm, and AC1 names all three. [SOURCE] | The point-in-time figures the card carries are re-runnable over the same channels (direct `Skill` calls, subagent calls, `<command-name>` slash calls) against the registry's 21 role-Specialist rows. [SOURCE: #8452 § Carried from the observation; `core/skills/registry.md` roster note] | The roster was not deployed at once: `102-specialist-role-coverage` (v4.17, 2026-08-07) last changed the registry. A flat session denominator counts sessions from before a Specialist existed. [SOURCE: RELEASE_LOG v4.17 row; commit `58f11f35`] | C2 | Record each Specialist's exposure window (sessions since its registration) beside its count, so "never invoked" is read against sessions in which it was deployed. |
| AC2: every never-invoked Specialist has exactly one disposition (re-trigger / re-home / retire) with its reason | `decision-discipline.md` § 1.1 makes each disposition decision-class; `reversibility-protocol.md` requires a tier and confidence on each. A retire is not CHEAP: it touches the deploy arrays, packages, registry rows and the roster count. [SOURCE] | ADR-033 § Decision: a methodology-conditional skill is DORMANT under a non-matching `delivery_approach`. The registry marks the RTE "SAFe-conditional: active only under a SAFe `delivery_approach`, dormant otherwise". The live operator config sets no `delivery_approach`, so the default applies. [SOURCE] | A current-state review on 2026-10-25 found that one goal phrase ("are we ready for go-live") reaches two skills with different readiness rules, so a re-trigger can create a collision as well as fix reachability. [SOURCE: #8452 comment, 2026-10-25] | C2 | Add a fourth value, **keep (dormant by design, ADR-033)**, decided against activation config rather than raw count. Each row carries a reversibility tier and confidence. A re-trigger row names any trigger it would collide with. |
| AC3: the table states whether the listing renders Specialists without descriptions, and why | `review-discipline-principles.md` § 8.1 PV-3 (extraction) separates "description missing" from "description not rendered", and AC3's method is that comparison. [SOURCE] | In this session's rendered skill listing (2026-11-13), 16 of 21 role Specialists are name-only: 11 of 14 in operations and 5 of 7 in release. Function-skills render name-only too (`change-management`, `daily-status`, `build-reviewer`), so it is not Specialist-specific. [SOURCE: this session's skill listing] | The 2026-10-16 read was 18 of 21. The count moved by two with no change to any Specialist file since 2026-08-07, so rendering varies by session, not by file. [SOURCE: #8452 body; [INFERRED] from the 0-commit drift probe] | C2 | Compare at least two sessions' listings, and state the mechanism with its evidence label. A single session cannot separate a budget cut-off from a per-skill defect. |
| AC4: the router has its own row | `decision-discipline.md` § 1.1: keeping, re-scoping or retiring the router is a decision in its own right. [SOURCE] | The router classifies role-shaped requests against the `kind == role-Specialist` view and is not itself a routing target. #8818's AC1 names the router as a method for reaching new capabilities. [SOURCE: `core/skills/registry.md` § Routing view and § What qualifies; #8818 body] | The router had zero invocations at the point-in-time census. [SOURCE: #8452 body] | C1 | — |
| Proposed change: re-run the census before deciding | `decision-discipline.md` § 2.1.1 (Audit-Snapshot Reconciliation): a recommendation drawn from a point-in-time artifact is re-verified first. [SOURCE] | The card's own Notes require the re-run before acting. [SOURCE: #8452 § Carried from the observation, Notes] | No registry, router or Specialist file has changed since triage: 0 commits over the 23 paths, with 3 in the control window. Only usage can have moved. [SOURCE: `git log origin/main`] | C1 | — |
| R-1: Documentation Impact "None" and the version-less rationale "changes no tracked file" | `decision-discipline.md` § 2.1.1: the bundle-time premise is itself a point-in-time artifact, re-verified against the release's done-bar. [SOURCE] | `stage-03-bundle.md` § 4: identity mode is an identity-axis value, orthogonal to whether tracked files change. The milestone's own clause re-declares versioned · minor if the table lands in a tracked file. [SOURCE: ms#445 description] | `stage-document-model-decision` shipped version-less with a founding ADR and its release plan (3 files). `composition-method-host-decision` and `framing-altitude-and-slip-model` took versioned · minor for a decision record. [SOURCE: RELEASE_LOG row and Deployment Log for stage-document-model-decision; ms#420 and ms#431 descriptions] | C2 | Stage 4 names the tracked homes (decision record; disposition table) and updates Documentation Impact. The identity mode goes to the operator at the Stage-4 plan gate with both precedents. |
| R-2: downstream couplings (#8451's host; #8818's candidate hosts) | `reversibility-protocol.md`: a retire that removes a downstream card's candidate host raises that disposition's undo cost. [SOURCE] | #8540 notes that the spike may move #8451's host. #8818 (`status: proposed`, no parent) names `pmo-knowledge-manager` and `pmo-architect` as candidate hosts, and both are in this spike's subject set. [SOURCE: #8540 body; #8818 body] | The 2026-11-05 bundling sequenced #8304 and #8451 after this table lands. [SOURCE: #8452 comment, 2026-11-05] | C2 | The table records, per affected Specialist, the downstream card it touches. This release edits neither card; follow-ups wait for Stage 13's filing step. |
| R-3: decision-record number collision with sibling hubs running now | `reversibility-protocol.md`: a renumber before merge is CHEAP; after merge it is a cascade. [SOURCE] | ADR numbers form one gap-free sequence across `core/ADRs` and `release/ADRs`; the ADR-number integrity job blocks a duplicate or a gap. [SOURCE: `core/rules/git-workflow.md` § Non-blocking integrity jobs] | `stage-document-model-decision` renumbered its ADR before merge after a sibling ADR merged first. [SOURCE: RELEASE_LOG, Deployment Log and Release Learnings for stage-document-model-decision] | C2 | Plan a pre-merge renumber check. The hook chain keeps merge priority on a same-day tie. |

### A0 correction to the adopted evidence (classifications unchanged)

[DTA-2: re-read the briefing's staleness claim with `git log origin/main` over its own 23-path population → it under-counted both arms]

- **The claim** (group 3a; D3 of rows "Proposed change" and AC3): 0 commits on the 23 paths (registry, router, 21 Specialist directories) since triage, against a control of 3 since 2026-08-01.
- **Direct read** of the same population: **2** commits since 2026-10-24 (1 on the first-parent chain) and **21** since 2026-08-01 (7 first-parent). The briefing's instrument read low on both its subject and its control, so its zero was not evidence (PV-2).
  - The two are `769ed8ca` (`pmo-qa-lead/SKILL.md`) and `72c928ba` (`pmo-release-manager/SKILL.md`), both 2026-11-03 (Tuesday), from release `releases-file-only-the-follow-ups-that-matter`. Both are body edits.
- **The conclusion survives on a correct probe.**
  - `description:` changed in **0 of 22** files (the 21 Specialists and the router) between `7301d635` (2026-10-15) and `origin/main`.
  - The same instrument over the same files finds 8 of 22 changed since 2026-08-01, so it does detect change.
  - The AC3 inference (rendering varies by session, not by file) therefore stands, on this probe's evidence.
- **Second rendering (an AC3 datum).**
  - In this spoke's skill listing on 2026-11-13, 16 of 21 Specialists render name-only (11 of 14 operations, 5 of 7 release), as does the router.
  - With descriptions: `pmo-knowledge-manager`, `pmo-ocm-lead`, `pmo-product-owner`, `pmo-architect`, `pmo-principal-engineer`. [SOURCE: this session's listing]
  - Function-skills split too: `comms-writer` renders a description while its alphabetical neighbours `change-management` and `context-budget-auditor` do not. So the selection is per skill, not a position cut-off.
  - The briefing read the same 16. Two renderings on one day are weakly independent, so AC3 still needs a rendering from a different day. [INFERRED]

### Ticket-vs-Architecture Reconciliation

| Surface | Ticket filed 2026-10-16 (Friday) vs surface's last merge | Finding | Action | C |
|---|---|---|---|---|
| `core/skills/registry.md` | 2026-08-07 (`58f11f35`), older | current | none | C1 |
| ADR-019, ADR-033, ADR-035, ADR-038 | 2026-08-04 to 2026-09-02, older | current; ADR-033's dormancy rule is uncited by the card | carried as the AC2 delta ("keep — dormant by design") | C2 |
| router `SKILL.md` | 2026-08-04, older | current | none | C1 |
| 21 Specialist `SKILL.md` | 2 newer (2026-11-03) | body-only; 0 description changes, so the registry `trigger surface` rows still match | none | C1 |
| `finding-disposition-framework.md` § 8; `work-item-filing-threshold.md` | both 2026-11-03 (`c23d2141`), newer | **stale-premise.** The Success Indicator says each implementation "is filed as its own card". § 8.6 gathers follow-ups into one sweep issue per repository unless a row is tagged ` · bug` or ` · feature`, and the threshold files only user-visible items at Minor or above | reword the Success Indicator (draft below); the Stage-5 spec sets the per-row tag rule | C2 |
| initiative roadmap entry | operator-local instance; not read on this public surface | — | — | — |

### Sibling Phase A0 gates (all ran; the cache HIT skips none)

- **A0.5 / G-PL1: PASS.** Every path the ACs and Affected Files name exists at `29c60404`: the registry; 14 Specialist directories under `operations/skills/` and 7 under `release/skills/` (0 under `core/skills/`); the router under `core/skills/`. No version reference or retired artifact is cited.
- **A0.6 / G-PL2: PASS, with one recommend-flag.**
  - G1-02, G1-04 (WHAT altitude, no mechanism), G1-05a (4 of 4 bullets verb-first) and G1-05b (i) all pass.
  - **G1-05b (ii) flag:** the card is not capability-class (C3 fails; its output is knowledge), but its AC set does not name its exempt class, and "silence is not an exemption". The fix is one E5 line, in D-Amendments.
  - A recommend-tier flag leaves the plan unchanged. [INFERRED]
- **A0.7 / G-PL3: fired on the raw signal, PASS on disposition.**
  - Window: bundling (2026-11-05T16:55:20Z; no release base exists yet) → `origin/main`, 202 commits.
  - Result: 7 directory-crossing `R` rows, and 0 `D` rows in the release's surface. Control over the full history: 398 and 8.
  - All 7 are the release-plan close-time move class (6 into `plans/v5/`, 1 into `plans/_unversioned/`). None eliminates a directory this release writes into.
  - Placement rationale: the plan is authored at `release/releases/plans/never-invoked-specialists-dispositioned_RELEASE_PLAN.md` and ends in `plans/v5/` or `plans/_unversioned/`, per D-IdentityMode.
- **A0.8 / G-PL4: documented pass-through.** The card is general-class (0 matches for `drift` / `reconcil` / `project:governance-hygiene`; not under the KA-Drift epic). Every AC method is a named read, so no runnable check exists, and that silence is not corroboration.
- **Parallelization-Map currency (A7 T5): FIRES.** A9.6 binds every milestone that reaches Bundle, and ms#445's description has no map (0 headings; control `## Scope` reads 1). Routed Tier 1 [ADJUST]: the scan was re-run and a dated map is drafted below.
- **A7 T4 boundary (T1–T3 since bundling): 0 fire.**
  - T1: the 3 approved, unmilestoned `project:skill-suite` issues (#8540, #8451, #8304) were all labelled on 2026-10-25, before bundling.
  - T2: no edit to #8452, or to those three, since bundling.
  - T3: 0 `blockedBy` and 0 `blocking`; the control read returns #8540's 3 sub-issues.
  - T6: no namesake moved.
- **Evaluative lens (advisory):** N/A for this release's own deliverable, which reshapes no component. It goes to Stage 5 as a per-row input: triple-Venn for re-trigger versus re-home, plug-and-play for universal versus install-scoped.
- **§ 11 lens:** adopted from the briefing's group 9 (PV-A; AL-FIT), not re-run.

**A0 currency-decision confidence gate:** the A7 outcome is **(2) amend**. T5 fired, `issues_added == 0`, the theme is preserved, and the amendment is the map record only. The signal is **CONVERGENT**: the scan, the native graph and the roster agree on zero hard edges. It proceeds at the existing authorization, an operator-approved amendment at the plan gate that the hub applies with a `[BUNDLE AMENDMENT]` record. Lock state reads `UNMARKED` (0 Composition Lock headings); the marker is pending at the plan gate, and this spoke does not author it.

## Summary (30 seconds)

- **Ready for the plan gate, with conditions.** One card, one branch and one PR, run serially. Release Class `novel`, 4 points raw and 5 effective. I recommend a size re-check to L (9 effective), which keeps the single-item spike shape valid.
- **Two decisions shape the plan.**
  - **D-IdentityMode:** I recommend **versioned · minor**, MEDIUM confidence. Versioned is the documented default, the milestone's own clause asks for it, and the Bump-Class guide maps a reference-document addition to minor. The briefing's reading of `stage-03-bundle.md` § 4 is wrong: the text makes identity mode orthogonal to bundle size, not to tracked-file change.
  - **D-WorkProductHomes:** I recommend **one decision record in `core/ADRs/`**. It holds Current State (with the census section), Future State, Gap Map and the disposition table, the shape both versioned decision-record precedents shipped. No work product is left without a home.
- **A0 is a G-PL5 HIT, with two corrections to the briefing.** Its staleness probe under-counted (2 commits since triage, not 0; the conclusion still holds), and its R-1 citation overreaches.
- **Tier 1 edits for the hub on approval.**
  - #8452's body: refine AC-1 to AC-3; add AC-5 and AC-6 for the design-milestone bar; name exempt class E5; mark Affected Files as the decision's subject; fill in Documentation Impact.
  - The ms#445 description: a dated Parallelization Map; an Outcome Statement carrying the required `**Limb owners:**` and a follow-up-aligned Success Indicator; the identity-mode line; the pending Composition Lock.
- **Stages run as follows:**
  - Stage 5 writes the spec only.
  - Stage 6 re-runs the census and authors the record, status `Proposed`.
  - Stage 7 verifies it in a reduced posture; Stage 8 grades each criterion.
  - Stage 9 runs Deep, with **D-Ratify** as one operator gate for every disposition.
  - Stages 10 and 11 are compressed.
  - Stage 13 files the tagged follow-ups.

## Dependency Graph

- **In-milestone:** a single node, so 0 edges and 0 cycles. Native graph: 0 `blockedBy`, 0 `blocking`, 0 sub-issues; parent #8540 is open (the control read returns its 3 sub-issues). [SOURCE: GraphQL]
- **Outbound, sequencing only (none blocks this release):**
  - Composing slot `review-lenses-answer-goal-shaped-asks` (#8304 + #8451) waits for this release, because the table may move #8451's host. That is a ship-gate on the slot, not a build-block here.
  - #8818 (status: proposed, unmilestoned) asks to "sequence the host decision after #8452 or alongside it". Prospective.
- **Inbound:** none. A body search for `8452` finds #8818, #8540, #8451 and #8896, none in another milestone (the control search for `8451` finds 4).

## Implementation Sequence

**Wave 1 (only): #8452**, serial. Gate: **D-Ratify at Stage 9**.

| Step | Where | Work |
|---|---|---|
| 0 | Stage 6, Commit 0 | Transcribe this comment into the plan file with the Commit-0 Survival Set. Under D-IdentityMode (A), run Commit-0 steps 1–3 and 3b. Under (B), steps 1–3 are N/A and 3b reads `TOKEN-LESS PLAN`, which is correct, not a HALT. |
| 1 | Stage 6, local and read-only | **Re-run the census** per the Stage-5 spec. Raw per-session data stays in the operator's local transcript store (install-scoped working state, ADR-231); only per-Specialist aggregates leave it. |
| 2 | Stage 6 | **Compare the listing** across at least two renderings from different days, against each `SKILL.md` description and the census's invoked set (R4). |
| 3 | Stage 6 | **Author the record** with `status: Proposed`, per D-WorkProductHomes, with recommended dispositions plus the router row. Citations use `{{ADR:<slug>}}`; the filename takes `renumber-adr.py --next-free` at authoring time. |
| 4 | Stage 6, C4 self-verification | `check-adr-durability.py` on the record; `renumber-adr.py --detect`; `path-leak-patterns.sh --scan-file` on the record and every comment; the PR-time link gates; the release-level scope assertion. |
| 5 | Stages 7 → 8 → 9 | Verify the record, then a Deep review with **D-Ratify**. On ratification, a Tier 1 commit flips it to `Accepted` before the merge. |
| 6 | Stages 12 → 13 | Merge; Stage 12 A.5.7 runs `renumber-adr.py --detect` / `--stamp`; claim the version only under (A); close-out runs the § 8 filing step. |

**#8452 Stage-5 input register (binding).** Carry the six C2 deltas and the A0 correction.
- **Census method:**
  - three channels: direct `Skill` calls, calls inside subagent transcripts, and slash `<command-name>` turns;
  - population: the 21 routing-view rows plus the router at the census head SHA, with the session denominator;
  - a per-Specialist exposure window from its registration commit;
  - a sensitivity arm (skills known to be in use read non-zero) and a specificity arm (mention-only sessions read 0). Every listing names all 21, so a substring count is a broken probe;
  - the resolved `delivery_approach` for methodology-conditional rows: an absent field reads DORMANT, never a default (ADR-033);
  - the method kept as a fenced, re-runnable procedure, not an executable file.
- **Table:**
  - one row per census row at 0, plus the router;
  - values: re-trigger, re-home, retire, keep (dormant by design);
  - per row: reason, tier and confidence, the downstream card (#8451's host, #8818's candidate hosts, or none), and a § 8.2 `follow-up:` tag (none for keep);
  - re-trigger rows name their collisions in Check 67's WATCH/ESCALATE vocabulary (ADR-114);
  - retire and re-home rows carry their referencing-site pre-count (`rename-reference-cascade.md` § 4). The router alone is named in 16 tracked files.
- **Riders:**
  - § 3.1, name the seam each disposition extends: `description:` and the registry trigger surface; the CMDB `lifecycle-state` (`active → deprecated → retired`) rather than deletion; the receiving skill's modes; the ADR-033 gate.
  - § 3.2: "reviewed → retained / changed because …" for the role-Specialist kind, the routing view (ADR-038), and the router as the only goal-to-role mapper.

### File Change Matrix

```
# ── Engineering Commit 0 ──
release/releases/plans/never-invoked-specialists-dispositioned_RELEASE_PLAN.md  ADD
# ── #8452 — the decision record (D-WorkProductHomes (A); NNN = 238, from renumber-adr.py --next-free at authoring on 2026-11-13; the number binds at the Stage-12 merge) ──
core/ADRs/ADR-238-each-never-invoked-specialist-takes-one-disposition.md  ADD
# ── CONDITIONAL — resolves at the Stage-12 merge, not at Commit 0 ──
core/ADRs/README.md  EDIT  CONDITIONAL:renumber-log
```

### Read-only inputs

```
core/skills/registry.md  READ
core/skills/pmo-skill-router/SKILL.md  READ
operations/skills/pmo-*/SKILL.md  READ
release/skills/pmo-*/SKILL.md  READ
core/ADRs/ADR-019-specialists-compose-not-absorb.md  READ
core/ADRs/ADR-033-methodology-conditional-skill-activation.md  READ
core/ADRs/ADR-038-registry-as-cmdb.md  READ
core/ADRs/ADR-114-composition-aware-trigger-collision-gate.md  READ
core/ADRs/ADR-231-non-tracked-data-homed-by-risk-class.md  READ
core/schemas/adr-schema.md  READ
core/standards/work-item-filing-threshold.md  READ
release/references/standards/finding-disposition-framework.md  READ
core/skills/finops-usage-extractor/SKILL.md  READ
```

### Release-wide explicit non-scope

```
core/skills/registry.md  NOT EDITED
operations/skills/pmo-*/SKILL.md  NOT EDITED
release/skills/pmo-*/SKILL.md  NOT EDITED
core/skills/pmo-skill-router/SKILL.md  NOT EDITED
core/deploy/deploy.sh  NOT EDITED
packages/  NOT TOUCHED
core/rules/  NOT TOUCHED
release/releases/RELEASE_LOG.md  NOT TOUCHED
```

**Matrix notes.**
- The ledgers, notes and changelog belong to the Stage-12 and Stage-13 chore PRs.
- 0 executable `ADD` rows, so the script-allowlist companion obligation does not fire.
- The mover set is empty; a Stage-12 ADR renumber is a same-directory rename made by the tool.
- **Deliverable domain (A3):** every row is an internal platform artifact, so the domain is `governance`.

## Agent-Editability Read

**Derivation**, controls read at commit `29c60404`:
- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` holds **2** `case "$ABS_TARGET"` blocks that invoke `always_block "BLOCK-AUTONOMY-001"`, out of the file's 4 `case "$ABS_TARGET"` blocks. Their arms, verbatim:
  - Block 1 (lines 725–741):
    ```
    "${PRIMARY_ROOT}/CLAUDE.md" \
    | "${PRIMARY_ROOT}/projects/CLAUDE.md" \
    | "${PRIMARY_ROOT}/pmo-platform/CLAUDE.md" \
    | "${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md" \
    | "${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md" \
    | "${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md" \
    | "${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md" \
    | "${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md" \
    | "${PRIMARY_ROOT}/.claude/settings.json" \
    | "${PRIMARY_ROOT}/.claude/hooks/"* \
    | "${PRIMARY_ROOT}/.claude/rules/"*)
    ```
  - Block 2 (lines 770–783, the membership stage): `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md)`
  - **Surviving union**, projected and tested against the tracked index at `29c60404`: the `OPERATIONS.md` basename is tracked 2 times and `RELEASE_PROTOCOL.md` once, at depth; `CLAUDE.md` is tracked 0 times; the workspace-root, `projects/` and `.claude/` arms fall outside the repository. Re-derive every release.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh`.
  - `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`
  - arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`
  - exemption list (resolved by `pmo_skill_editor_exemption_list_for`) = **undetermined**: not read, and immaterial, since conjunct 1 is false on every row.
  - Probe: both regexes read false on all 4 candidate write paths and on the registry. Controls: `operations/skills/pmo-scrum-master/SKILL.md` matches the scope regex; `core/governance/OPERATIONS.md` matches the floor.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #8452 (Commit 0) | `release/releases/plans/never-invoked-specialists-dispositioned_RELEASE_PLAN.md` | no | no (conjunct 1 decides) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8452 | `core/ADRs/ADR-NNN-<record-slug>.md` | no | no (conjunct 1 decides) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8452 (CONDITIONAL, Stage 12) | `core/ADRs/README.md` | no | no (conjunct 1 decides) | unconstrained | unconstrained | written by `renumber-adr.py` at Stage 12 A.5.7 (the class of its source) |
| #8452 (CONDITIONAL, option B) | `core/specs/<census-record>.md` | no | no (conjunct 1 decides) | unconstrained | unconstrained | ordinary Engineering spoke |

**Integration points:** none in code. The integration is a content join: census rows at 0 match disposition rows one-to-one, with the router row added. The couplings to #8451, #8818 and the composing slot are recorded, not acted on.

## Stage Applicability Matrix

| Stage | #8452 |
|---|---|
| 5 Solutioning | ✓ **ACTIVATE**: the spec only (census method, table schema, record outline, verification bindings, T3 riders); scope lock at exit (operator) |
| 6 Engineering | ✓ Commit 0, census re-run, listing comparison, the record (`Proposed`) |
| 7 Dev Testing | ✓ **Reduced** [RECOMMENDED]: doc-conformance (ADR lint, links, path-leak), an independent re-derivation of sampled census rows and both arms, and a refuter pass on the recommended dispositions. No test authoring. Not skipped, per the design-milestone bar. |
| 8 QA Testing | ✓ AC-1..AC-4 (plus AC-5 if amended); AC-6 graded at Stage 13 |
| 9 Plan Review | release-level **Deep** + the **D-Ratify** gate |
| 10 / 11 | N/A, compressed: git-native, no deploy target, nothing to snapshot |
| 12 Execute | B1 merge · A.5.7 ADR reconciliation and stamp · B3 under (A) only · B4 with no skill targets · B5 RELEASE_LOG chore PR |
| 13 Close | close-out per identity mode · the § 8 filing step · **mark #8452 as closed at Stage 13** once the ratification is recorded |

**Stage 5 activation (`planning-solutioning-handoff.md` § 4):**

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | Rationale |
|---|---|---|---|---|---|---|---|---|
| #8452 | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ | ACTIVATE | **T1**: a new decision record with tables, via R-1 (the body as written declares no new file). **T2 ✗**: the listed `SKILL.md` files are the decision's subject and none is edited. **T3**: the disposition enum and the table and census schemas constrain the follow-up cards. **T4**: re-trigger, re-home, retire or keep per Specialist, with non-trivial cost and reversibility differences. **T5 ✗**: 0 governance files. **T6 ✗**: this release's own change set is determinate. |

**Rollup: ACTIVATE**, all-or-nothing; `novel` biases toward ALL anyway.

## Contention Map

- **Within the release: none.** 2 unconditional paths with one writer each, serialized by P0.
  - Probe: `bundle-issues-parser.py --issues 8452,7408`. #8452 declares 4 subject paths, read as `edit` by the parser's default: the registry, `SKILL.md`, `operations/skills/`, `release/skills/`. The control #7408 returns 3, so the parser works.
  - The write set ∩ those paths = ∅. D-Amendments marks them as subject, so no mechanical reader takes them for edits.
- **Cross-PR** (baseline `29c60404`, 2026-11-13T16:07Z): **1 open PR**, #8821 (draft, 47 files).
  - #8821 ∩ the matrix = `core/ADRs/README.md` only (the CONDITIONAL row). #8821 appends 3 renumber-log lines there, so `overlap_class` = **append-pattern**, informational: the renumber runs at Stage 12 against fresh `main`.
  - #8821 ∩ `core/ADRs/ADR-*.md` = 0. Its `release/ADRs/ADR-238-…` is a number edge, not a file edge (`renumber-adr.py --detect`: anchor 237, next-free 238, `CLAIMED-SET-BRANCH-ONLY 238`).
  - Control: #8821's own plan path is in its list (1).
- **Hook-chain (ms#439, ms#440) and ms#444: no shared file.** Their primary files (`core/hooks/block-destructive.sh`, `core/hooks/block-rm-prefer-trash.sh` and their rule fragments) ∩ the matrix = ∅. The only common surfaces are the Stage-12/13 ledgers (`release/releases/RELEASE_LOG.md`, `RELEASE_INDEX.md`, `RELEASE_DIGEST.md`, plus `CHANGELOG.md` under (A)), each appended by every release's own chore PR in merge order. The hook-chain releases keep priority on a same-day tie.
- **Structural:** the mover set is ∅, so `SURFACE(R)` = ∅. A `Δversion` token exists only under (A): ms#400, ms#429, ms#439, ms#440 and ms#444 all declare versioned · minor, and the atomic claim settles the race.

## In-Flight Release Roster

**Measured at:** `29c60404` · `2026-11-13T16:07:37Z` · **Population:** n=1 sibling(s) (open `release/*` PRs, drafts included: 1; `release/*` heads without a PR: 0)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `release-usage-measured-right` | `#8821` | `8974f500` | `minor` | `v5.02` (stale) | `v5.08` (allocation rule on tags fetched 2026-11-13, anchor `v5.07`; allocator not invoked, since `claim-version.sh --dry-run` needs a merge SHA) | `core/ADRs/README.md` (CONDITIONAL row) |

No verdict here; Stage 9 A6.6 re-measures. Five further milestones moved today with no branch yet: ms#400, ms#437, ms#439, ms#444, and this one. [SOURCE: milestone `updated_at`]

## Risk Register

| # | Risk | L / I | Mitigation | Owner |
|---|---|---|---|---|
| R1 | The census counts listing mentions as invocations (every listing names all 21) or misses the subagent channel | M / H | A structure-shaped probe over tool-use and command records; specificity arm 0 on mention-only sessions; sensitivity arm non-zero; both re-derived at Stage 7 | Stage-5 spec; Stage-6; Stage-7 |
| R2 | Raw session data, a session ID, or a path with a user-named segment reaches the record or a comment | M / H | Aggregates only (raw data stays install-scoped, ADR-231); `path-leak-patterns.sh` on the record and every comment; checked at Stage 9 | each spoke; hub |
| R3 | A flat denominator overstates "never invoked" for Specialists registered later | M / M | A per-Specialist exposure window (AC1) | Stage-6 |
| R4 | Two same-day renderings mislead, or the listing gap is a *consequence* of non-use, which would make a re-trigger edit ineffective | M / M | A rendering from a different day. If the rendered set coincides with the invoked set, the record says a description may not render until a skill is used, and every re-trigger row notes it. [INFERRED hypothesis, to test] | Stage-6 |
| R5 | A methodology-conditional Specialist is retired on raw counts | M / H | "keep (dormant by design)", decided against the resolved activation config (ADR-033) | Stage-6; operator |
| R6 | A re-trigger creates a routing collision (the readiness case: `change-management` Mode C versus `pmo-ocm-lead` Mode 3) | M / M | Re-trigger rows name their collisions in Check 67's vocabulary; the follow-up resolves them | Stage-6; follow-up |
| R7 | The Success Indicator ("filed as its own card") conflicts with § 8.6 and the threshold | H / M | Reword it (draft below); the Stage-5 tag rule; the Stage-9 A7.6 ledger and cut (§ 8.7) | Stage-5; operator |
| R8 | An ADR-number collision with sibling hubs (238 is already claimed on #8821's branch) | H / L | `{{ADR:<slug>}}` tokens; `--next-free` at authoring; Stage-12 A.5.7 `--detect` / `--stamp`; the CONDITIONAL README row | Stage-6; Stage-12 |
| R9 | ADR lint R2 flags counts ("rows", "skills", "CIs" and "entries" are in its noun list; floor 5) | H / L (warn) | Every count line carries a history anchor from the lint's closed set ("as of …", "point-in-time", "at authoring") or sits in a fence; lint at Stage-6 C4 | Stage-6 |
| R10 | (A): version-slot contention with five versioned-minor siblings. (B): a stray release-version stamp token makes a versioned sibling's stamp-slug derivation ambiguous | H / L · L / M | (A): the atomic claim; re-versioning up is routine. (B): no stamp token anywhere in the plan; step 3b reads `TOKEN-LESS PLAN` | Commit-0; Stage-12 |
| R11 | The design-milestone bar (future state, gaps, ratification) overruns size M | M / M | Size re-check to L; a Stage-5 time-box; an overrun becomes Tier 2 [SCOPE CHANGE] | Stage-5; operator |
| R12 | A downstream card is mutated in-release, or the slot is composed early | L / M | Couplings recorded only; Stage 9 checks #8451 and #8818 are unchanged since 2026-11-13 | hub |
| R13 | A retire or re-home row understates its reference cascade | M / M | A pre-count and tier per row; retire through the CMDB lifecycle states, not deletion | Stage-6 |
| R14 | Ratification read as a spoke act, or an amended row left unverified | L / H | Only the operator ratifies, and the hub posts the decision verbatim; amended rows land as one Tier 1 commit that the hub re-reads | hub |
| R15 | The weekly usage budget is shared with five other active hubs | M / M | Singleton launches; Checkpoint B at each launch; the census parse is a local script | hub |

## Cross-Issue Acceptance Criteria

**None.** Enumerated over the issue population {#8452}, one non-sub-task card. A CIAC needs at least two issues. The release-wide scope constraint a CIAC would carry here is a Release-Level Verification row instead. CIAC lint: `CIAC-LINT-SUMMARY declared=0 parsed=0 clean=0 declared-deferral=0 flagged=0` (`verify-release-plan.sh --ciac-lint` on this drafted plan, exit 0; control: the same lint on the `stage-document-model-decision` plan reads `declared=6`).

## Recommendations

### Release Class declaration

**Release Class: `novel`**, carried.
- **Triggers that fire:** novel (a), a new decision record; novel (b), per-Specialist dispositions and Stage-4 D-decisions.
- **Triggers that fail:** routine (a) (P2) and (d); cross-cutting (a) to (c) (0 stage files, 0 rule-defining surfaces, 0 in-bundle edges); hotfix does not apply.
- **Posture:** engagement density Standard; Stage 9 depth **Deep**; Stage 5 bias **ALL**; outcome window **30-day**.
- **Effective size:** 4 × 1.15 = 4.6 → **5**, or 8 × 1.15 = 9.2 → **9** if re-sized. Both are below the 10-point floor, and a single-item spike is a first-class shape (doctrine § 3 Step 5). Not over-scoped.

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-13, domain: governance }`

Form X: every row in the matrix is internal; `core/standards/domain-best-practices/governance.md` encodes the practice.

### Operator Decisions (D-Gate Block)

There is no `## Gate-Class Framing Directives` block (0; control `## Release Class` reads 1), so every gate uses hub defaults. The register's entries were last verified 2026-07-27, more than 90 days ago, and the verdicts note it.

#### D-IdentityMode: Does the release stay version-less or become versioned · minor?
**Gate input:** row R-1 (C2); the milestone's own clause ("If Stage 5 records the table in a tracked file, Stage 4 re-declares the mode as versioned · minor"); the design-milestone bar, which puts the records in tracked files.
**Gate decision:**
- (A) versioned · minor [RECOMMENDED]
- (B) stay version-less
**Blocks:** Commit 0 (the plan's Version cell carries the release-version stamp token under (A) and none under (B)); Stage 12 B3; the Stage-13 close-out. Under (A) that is the automated close-out with a GitHub Release, a CHANGELOG key and `.version`. Under (B) it is a hand-assembled Phase-B chore PR with neither.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:**
- (A): ALIGNED DP-7 (Track-all-edits, `core/disciplines/build-philosophy.md:56`), since the corpus addition gets a versioned, release-noted record. N-A DP-4 (the default mode adds no step beyond itself), DP-3, DP-5.
- (B): ALIGNED DP-4 (Simplicity, `build-philosophy.md:51`), with fewer Stage-12/13 steps. ALIGNED DP-7. N-A DP-3, DP-5.
**Reversibility / Confidence:** CHEAP / MEDIUM. It can be re-rendered until Stage 12; the branch and plan names are slug-primary under both.
**Recommendation (M1 Localization):**
- `versioned` is the documented default; `version-less` began as an operator exception. [SOURCE: `stage-03-bundle.md` § 4]
- "Reference document addition or update" maps to minor. [SOURCE: `RELEASE_PROTOCOL.md` Bump-Class Selection Guide]
- Two of three decision-record precedents took minor: `composition-method-host-decision` (v5.04) and `framing-altitude-and-slip-model` (v5.02). [SOURCE: `release/releases/plans/v5/`]
- "A release never ships version-less to dodge a collision", so slot contention is no reason for (B). [SOURCE: `bundle-composition-doctrine.md` § 9.1]
**Opposing view (M2):** (B) has a same-day precedent. `stage-document-model-decision` shipped a founding ADR version-less, the operator re-confirming "Stay version-less (Recommended)". A decision record changes no behaviour, its follow-ups ship versioned in their own releases, and (B) avoids five `Δversion` edges. If design-only releases are version-less by the operator's policy, (B) is right.
**Correction to the briefing:** R-1 D2 says § 4 makes the mode "orthogonal to whether tracked files change". § 4 and `RELEASE_PROTOCOL.md` § Versioning say orthogonal to **bundle size**. Probe: version-less lines that also mention track, file, ADR, record or orthogonal, across `stage-03-bundle.md`, `bundle-composition-doctrine.md`, `RELEASE_PROTOCOL.md` and `stage-13-close.md`. It returns no rule tying the mode to tracked files, and the sensitivity arm finds the bundle-size lines in two of those files. No rule forces either option.

#### D-WorkProductHomes: Where does each work product live?
**Gate input:** the design-milestone bar (current state, future state, gaps, and the disposition table with its decision record, each needing a durable, readable, tracked home); carry-forward 2; row R-1.
**Gate decision:**
- **(A) [RECOMMENDED] One decision record**, `core/ADRs/ADR-NNN-<record-slug>.md`. It carries the seven schema sections plus:
  - `## Current State`, holding the census section (method, denominator, exposure windows, both arms, and aggregate per-Specialist counts as a dated, history-anchored snapshot) and the listing finding;
  - `## Future State`, what a goal-shaped ask should reach;
  - `## Gap Map`.
  The disposition table sits in `## Decision`. This is the v5.02 shape ("explicit Current State, Future State and Gap Map sections in the record") and the v5.04 shape ("Current state, Future state and Gaps inside the record's Context").
- **(B)** The same record without the census section, plus a separate tracked census record at `core/specs/<census-record>.md` (the CONDITIONAL row), cited by the record.
- **(C)** Per-Specialist annotations in `core/skills/registry.md`, an implementation change the card scopes out.
**Homes under (A):**
- Every work product, and the census record, lives in the decision record.
- The census method sits in the census section as a fenced, re-runnable procedure, which the epic's sunset re-run cites.
- Raw per-session data lives only in the operator's local transcript store; aggregate counts, each with its exposure window, go in the census section.
- **No work product lacks a tracked home.**
- **Module:** `core/ADRs/`. The subject is the core registry and router, and ADR-019, 033, 035, 038 and 114 are core. `release/ADRs/` is rejected: the subject is not the release pipeline.
**Blocks:** the Stage-5 outline; the CONDITIONAL row; Stage-6 step 3.
**Upstream compatibility:** N/A — no option modifies skill-authoring surface. (C) edits the registry, a PMO-internal CMDB, not a `SKILL.md` or a skill directory. Upstream compatibility check does not apply.
**Design-Principle Conformance:**
- **(A):**
  - ALIGNED DP-4 (Simplicity, `build-philosophy.md:51`): one file.
  - ALIGNED DP-3 (Maintainability, `:50`): each count has one home, and the Decision cites it.
  - ALIGNED DP-7.
  - N-A DP-1, DP-5.
- **(B):**
  - **CONFLICT.** DP-3: the record's summary would restate the census headline. Mitigation: cite it, restate no count.
  - **CONFLICT.** DP-4: a second file beyond the smallest change. Mitigation: worth it only for a living, maintained method. Default CHEAP, so annotate and proceed.
  - ALIGNED DP-1 (`:48`): evidence sits apart from decision.
- **(C):**
  - **CONFLICT.** DP-5 (Stability, `:52`): it edits the router's classification source, a runtime routing surface. Default EXPENSIVE, so it needs sign-off. Mitigation: route registry changes to the follow-up cards.
  - **CONFLICT.** DP-7: outside the card's approved scope.
**Reversibility / Confidence:** (A) and (B) CHEAP / HIGH before Stage 12 (sections move between files), MODERATE after merge. (C) MODERATE.
**Recommendation:** (A). The trade-off: an `Accepted` record is not edited, so the sunset re-run cites the method and records its results elsewhere (on the epic, or in a later record). A tracked census script is out of scope here; it is a follow-up candidate on the transcript extractor (Discoveries).

#### D-Amendments: Apply the Tier 1 [ADJUST] body and description edits?
**Gate input:** the six C2 deltas; the G-PL2 flag; T5; the R7 reconciliation; the Outcome Statement schema (`**Limb owners:**` is REQUIRED and absent: 0 lines; control `**Success Indicator:**` reads 1).
**Gate decision:**
- (A) [RECOMMENDED] apply everything under "Proposed edits";
- (B) apply the refinements only (AC-1 to AC-3, E5, Affected Files, Documentation Impact). Residual: Stage 8 cannot grade the bar's extra products;
- (C) defer the body edits to the Stage-5 scope lock.
**Blocks:** the Stage-5 spawn, which reads the ACs; the rows for AC-5 and AC-6.
**Upstream compatibility:** N/A — no skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:** (A) ALIGNED DP-7 (`build-philosophy.md:56`); (B) and (C) ALIGNED DP-4. N-A DP-1, DP-3, DP-5.
**Reversibility / Confidence:** CHEAP / HIGH.

#### D-ReleaseClass: What Release Class does this release carry?
**Gate decision:**
- (A) routine
- (B) novel [RECOMMENDED; evidence above]
- (C) cross-cutting
- (D) hotfix
**Blocks:** the per-class posture.
**Upstream compatibility:** N/A — Release Class is PMO platform internal taxonomy; no Anthropic upstream surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:** N/A — no design-principle `scope_predicate` matches this option's change surface.
**Reversibility / Confidence:** CHEAP / HIGH.

#### D-C Branch Topology: recorded determination
**SINGLE:** one branch `release/never-invoked-specialists-dispositioned`, one PR. Not a click-gate. CHEAP / HIGH.

#### D-Concurrency Posture: Which Stage-6 parallelism posture?
**Gate decision:**
- (A) P0 fully serial [RECOMMENDED]: one card and one writer.
- (B) P1, which buys nothing here.
**Blocks:** Stage-6 dispatch.
**Upstream compatibility:** N/A — this D-decision does not modify skill-authoring surface. Upstream compatibility check does not apply.
**Design-Principle Conformance:** N/A — no design-principle `scope_predicate` matches this option's change surface.
**Reversibility / Confidence:** CHEAP / HIGH. No force-push of any kind.

#### D-Version: recorded determination, conditional on D-IdentityMode
- **Under (A):** bump-class **minor**; provisional display **`v5.08`** (anchor `v5.07` on tags fetched 2026-11-13). It is a label, not a reservation. Re-verified at Commit 0 (steps 1–3, 3b), Stage 9 A6.6 and the Stage-12 atomic claim; five versioned-minor siblings compute the same next-free, and the claim settles it. No (B) or (C) override condition is present.
- **Under (B):** **N/A**, recorded. No version string, and no stamp token.
- CHEAP / HIGH.

### D-Ratify (Stage 9; placed now so Stage 5 designs for it)
After Stages 7 and 8 verify the record, the operator renders **all dispositions in one gate**: ratify / ratify with row amendments / redirect.
- A redirect sets `iterate:stage-6`.
- On ratification, a Tier 1 commit flips `status:` from `Proposed` to `Accepted` before the merge. Check 58 is an advisory backstop (G-CL9 is the authority), so the hub reads `status:` itself.
- EXPENSIVE / HIGH: the dispositions bind follow-up cards and may remove skills.

### Merge / split
Keep #8452 whole. A separate census card would ratify a table whose evidence ships apart, and the card's Notes require the census first. **Size re-check:** M → **L** [RECOMMENDED], since the bar adds the future-state and gap products and a ratification gate. MODERATE / MEDIUM.

### Proposed edits for the hub to apply after plan approval (D-Amendments (A))

**#8452 body** (amending a criterion obliges its bound row in the same change):
- **AC-1:** add "…and each Specialist's count with its exposure window (sessions since its registration), and the resolved activation config for methodology-conditional Specialists".
- **AC-2:** the values become "re-trigger, re-home, retire, or keep (dormant by design, ADR-033, decided against the resolved activation config)". Add "…each with its reason, a reversibility tier and confidence, the triggers a re-trigger would collide with, and the downstream card it touches".
- **AC-3:** the method becomes "compare at least two sessions' rendered listings, from different days, with the SKILL.md descriptions".
- **AC-4:** unchanged.
- **Add AC-5:** "Verify the record states the current state (the 21 role Specialists and the router, with the census as evidence), the future state (what a goal-shaped ask should reach) and the gaps between them (method: read the Current State, Future State and Gap Map sections)".
- **Add AC-6:** "Verify the operator ratified the record, which reads `status: Accepted` on main, and each re-trigger, re-home or retire row carries a release follow-up tag (method: read `status:` and the operator's recorded decision; graded at Stage 13)".
- **Exempt-class line:** "Usability AC: exempt — E5 (spike / decision record; the deliverable is the finding and the record)".
- **Affected Files:** label the entries "the decision's subject — not edited in this release; each disposition's implementation edits them in its own card".
- **Documentation Impact:** replace `None` with the tracked homes from D-WorkProductHomes.
- **Label:** `size:M` → `size:L`, if accepted.

**ms#445 description:**
- Replace the Release Outcome Statement with the draft below.
- Set the identity-mode line per D-IdentityMode.
- Append the Parallelization Map below, with a `[BUNDLE AMENDMENT]` entry.
- Append the Composition Lock block, pending the operator, per Procedure 0 Step 5(b).

### Release Outcome Statement (Stage-4 draft)

```
### Release Outcome Statement

**AFTER** — Every registered role Specialist that operators never invoke, and the router, has exactly one ratified disposition with its reason, reversibility tier and confidence: re-trigger it with goal-shaped trigger phrases, re-home its content into a skill that is used, retire it, or keep it dormant by design under its methodology's activation config. The dispositions rest on a re-run, re-runnable invocation census (direct, subagent and slash invocations over a stated denominator, with each Specialist's exposure window and a non-zero control arm) and a cross-session reading of whether the skill listing renders Specialists without their descriptions. Current state, future state, gaps and the disposition table are readable in one tracked decision record.

**BEFORE** — A point-in-time census found 15 of 21 role Specialists never invoked. Their triggers use role vocabulary while operators ask by goal, the router that should map goal-shaped asks to them never runs, and nothing decides what an unused Specialist is for.

**Actor(s):** the operator, who ratifies the dispositions at Stage 9; the Stage-6 session that re-runs the census and authors the record; the platform's role Specialists and its router.

**Success Indicator:** on main, the decision record reads `status: Accepted`; its census states its denominator, the exposure windows and the control arm's non-zero count; every never-invoked Specialist and the router has one row; and each re-trigger, re-home or retire row carries a release follow-up tag that Stage 13's filing step files or the Stage 9 gate consolidates.

**Limb owners:** re-run census with denominator, exposure windows and both arms → #8452 · one ratified disposition per never-invoked Specialist and the router → #8452 · cross-session listing finding → #8452 · current state, future state and gaps in a tracked record → #8452
```

### Parallelization Map (draft for the ms#445 description)

```
## Parallelization Map (recorded 2026-11-13)

**Verdict:** Tier-A clean on hard and file-contention edges; Tier-S on the ADR-number sequence with release-usage-measured-right; Tier-S on the version slot with every in-flight versioned-minor sibling only if D-IdentityMode renders versioned · minor — bidirectional scan.

| Other milestone | Direction | Edge type | Body confirmation |
|---|---|---|---|
| release-usage-measured-right (PR #8821) | bidirectional | structural-blast-radius (ADR number; `core/ADRs/README.md` renumber-log append) | #8821 adds `release/ADRs/ADR-238-release-graph-cost-unit.md` and appends 3 renumber-log lines; this release binds its number at merge with `renumber-adr.py`; append-pattern, settled by merge order |
| obligation-runners-declared · script-guard-reads-every-token-as-the-shell-does · script-guard-refuses-only-what-executes · deletion-guard-judges-every-segment-and-target | bidirectional | structural-blast-radius (`Δversion`), only under versioned · minor | all versioned · minor, so all compute next-free `v5.08`; the atomic claim settles; the hook-chain releases keep merge priority on a same-day tie |
| composing slot review-lenses-answer-goal-shaped-asks (#8304 + #8451; not yet a milestone) | this-blocks-other | soft (ship-gate, not build-block) | the disposition table may move #8451's host (#8540 Notes; the 2026-11-05 bundling comment) |

**Reconfirm procedure:** run the A9.6 hard-vs-soft scan as published in `release/references/pipeline/stage-03-bundle.md` § A9.6 over this milestone (2026-11-13: members 2, counts NO-SECTION 2, edge_candidates none; resolved from the native graph: 0 blockedBy, 0 blocking), AND re-test the ADR-number and version-slot edges against any sibling whose plan adds a decision record or changes its bump-class.

Reconfirmed at Stage 3 A7 refresh and Stage 4 Phase A0 entry; stale-dated map = finding.
```

### Verification Plan

#### Per-Issue Verification

Every row is graded at Stage 8 by a named read, except AC-6 (Stage 13). The plan verifier runs none of them (SKIP); its one runnable command is the scope assertion below. This table carries the D-Amendments (A) rows (AC-5, AC-6) and the Stage-5 lock amendment 2 bindings (AC-3, AC-4, AC-6); see § Deviation Log DEV-3.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8452 | AC-1 | declared, verification deferred to Stage 8 QA — read of the record's census method and census results | the three channel predicates; class counters, each 0 or explained; the store floor; 22 rows, each with its window, listed and no-record counts, per-channel counts, errors and verdict; strata, zeros included; the control at least 1; the nonce arm; the activation read; no path, id or per-session row · control: Stage 7 re-runs self-test, mutations and run at the same --head and --until, and a recorded zero that turns non-zero is a defect |
| #8452 | AC-2 | declared, verification deferred to Stage 8 QA — join of the census rows at 0 against the disposition rows | each census row at 0, the router and any probe-only subject has exactly one disposition row carrying every revision-2 § 3 column · control: the same join over a copy with one disposition row removed → 1 unmatched |
| #8452 | AC-3 | declared, verification deferred to Stage 8 QA — read of the listing finding against at least two renderings from different UTC days | at least 2 UTC days; windowed tallies; no-record sessions kept apart; per-subject description changes with INDETERMINATE named; the mechanism with its evidence label; both rates · control values at `29c60404`: --since 2026-10-15T23:59:59 → 0 changed; --since 2026-08-01T00:00:00 → 7 changed and 1 INDETERMINATE (re-derived at the census head if it differs) |
| #8452 | AC-4 | declared, verification deferred to Stage 8 QA — read of the disposition table's router row | one router row carrying R6's recommended value and its alternative |
| #8452 | AC-5 | declared, verification deferred to Stage 8 QA — read of the Current State, Future State and Gap Map sections | all three present, and each gap names the disposition rows it informs |
| #8452 | AC-6 | [DEFERRED — graded at Stage 13, after the Stage-9 D-Ratify gate, by reading the record's status:, the hub-posted D-Ratify decision and the disposition table's remaining assumption labels] | `status: Accepted` on main; the hub-posted D-Ratify decision present; 0 `[ASSUMPTION – CONFIRM]` labels left in the disposition table; every re-trigger, re-home or retire row carries a follow-up tag |

**AC baseline**, read at Stage 4 and updated with D-Amendments (A) in the same change:

```
ac_baseline: { #8452: 6, read_at: 29c60404 }
```


#### Release-Level Verification
- [ ] **Scope:** no `SKILL.md`, registry or router changes. *Method:* `git diff --name-only origin/main...HEAD -- '*/skills/*/SKILL.md' core/skills/registry.md` expect 0 · control, same instrument: `git diff --name-only origin/main...HEAD -- release/releases/plans/never-invoked-specialists-dispositioned_RELEASE_PLAN.md` expect 1. Graded at Stage-6 C4 and at Stage 9.
- [ ] **File integrity:** the diff equals the matrix's unconditional rows, plus the README line only on a Stage-12 renumber (`fcm-delivery`).
- [ ] **Record conformance:** `check-adr-durability.py` shows no R1/R3/R4/R5/R7 finding on the record, and any R2 count is history-anchored.
- [ ] **Cross-reference validity:** the PR-time link gates pass; plan links use the workspace-rooted form.
- [ ] **Egress:** `path-leak-patterns.sh --scan-file` exits 0 on the record and on every stage comment.
- [ ] **Skill invocation / output contracts:** N/A, since no skill changes.

### Delivery Strategy

| Aspect | Decision |
|---|---|
| Branch / PR | `release/never-invoked-specialists-dispositioned`; one PR, draft from Stage 6 Phase C2, ready at the Stage-9 gate, merged at Stage 12 B1 |
| Commits | Commit 0 (the plan) → the record → the Stage-9 ratification flip; P0, no force-push of any kind |
| Deployment | git merge only (B4 with no skill targets) |

### Rollback Strategy
**CHEAP.**
- Before Stage 12: abandon the branch.
- After the merge: `git revert` the release PR and its chore PRs.
- A D-Ratify redirect is an iteration, not a rollback.
- Under (A) the tag is retained and the revert recorded; a version tag is never deleted.
- Follow-ups not yet filed are withdrawn with the revert.

### Operational Deployment Manifest
**N/A.** Enumerated over skill copies (S-2), harness artifacts, rules-mirror pairs, operator-instance seed files and Layer-2 targets: none is present. A plan and a decision record do not propagate.

### Quota Budget

**Verdict:** PASS (`quota-budget-protocol.md` Checkpoint A). No parallel batch exists.
**Parallel-eligible spokes per parallel stage (from the A2 Stage Applicability Matrix):** Stage 5: 1 · Stage 7: 1 · Stage 8: 1
**Per-spoke cost estimate:** ordinal band, low–moderate for `size:M` (moderate–high for `size:L`). Datum: about 5% of a 5-hour window for a heavy spoke [INFERRED, from an operator-local observation, not pipeline telemetry]. The census parse is a local script.
**Assumed/stated remaining usage-window envelope:** unstated, so 50% of the window is assumed. The weekly budget is shared with five other hubs active today (ms#400, ms#429, ms#437, ms#439, ms#444); weekly headroom is unstated `[ASSUMPTION – CONFIRM]`.
**Estimated cumulative draw % (worst parallel batch):** one spoke ≈ ≤5% of a window ≈ ≤10% of the envelope. About 6 serial spokes in all (Stages 5, 6, 7, 8, 12, 13) ≈ 20–30% of one window, spread across windows [INFERRED].
**Routing:** PASS: proceed; launch every stage as a singleton, as weekly headroom allows.
**Note:** Checkpoint B (singleton form PROCEED / DEFER, at every `Agent`-tool launch) is the load-bearing gate, and its host-API axis is runtime-only. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

### Decision-discipline application
- **D-IdentityMode, D-WorkProductHomes, D-Amendments:** all three mechanisms, M1 Localization, M2 Opposing View and M3 Pattern Cache Scan, applied inline above.
- **D-ReleaseClass, D-Concurrency:** M1 only, since rule tables decide them.
- **D-C, D-Version:** recorded, exempt as determinate classification (§ 3).
- **Stage applicability:** M1 against `planning-solutioning-handoff.md` § 3.
- **Risk severity:** read against this release's own surfaces.
- **M3, Pattern Cache Scan:** the persona's domain-prefixed glob matches no entry in the operator-local cache, so its general correction entries were scanned and are cited in paraphrase only:
  - one milestone, one PR → D-C SINGLE;
  - decide at planning rather than reflex-defer → D-IdentityMode carries a recommendation;
  - extend before building → census tooling as a follow-up;
  - structure-shaped probes with controls → R1;
  - make claims executable → the scope assertion;
  - run the verification stages for real → Stages 7 and 8;
  - abstract public surfaces → R2.
  - No emergence candidate applies. No operator correction occurred, so no observation was logged.

### Discoveries outside scope (tagged per § 8.2; nothing filed)
1. **The release-hub Mode R staleness probe (group 3a) under-counts.** It read 0 against 2, and its control read 3 against 21, on its own population. A GO briefing built on it could lead a planner to skip reconciliation on a changed surface. The reproduction is this artifact's A0 correction. `follow-up: user-visible · bug` — Severity: Minor.
2. **The persona card's Pattern Cache Scan glob** (`feedback_<domain>_*.md`, `feedback_general_*.md`) matches no entry in the live cache. Read literally, the scan is a zero with no control. `follow-up: none` — Severity: Cosmetic.
3. **A mechanical census for the epic's sunset re-run.** An invocation dimension on the transcript extractor would turn the recorded procedure into one command. #8821 is changing that extractor now, so it is best sequenced after it. `follow-up: none · feature` — Severity: Minor.

### Spoke housekeeping
[DTA-9: mandate = "Do not execute implementation — planning only" → analysis-only; holding the #8452 body edit, the ms#445 description PATCH and the Composition Lock marker, all of which the hub applies on operator approval]

`${SCRATCH_BASE}/spoke-4-8896-9SCfuI`

Control firings: none

**Canonical-checklist attestation:** every codified Phase step in `pipeline/stage-04-planning.md` § 5 ran, or is explicitly recorded N/A-with-reason:
- **A0:** the G-PL5 cache-read (HIT); ticket-architecture reconciliation; the evaluative lens (advisory, N/A with reason); A0.5; A0.6; A0.7; A0.8 (pass-through); Parallelization-Map currency (T5 fired); the currency-decision gate.
- **A1:** the entry gate: status `bundled` with milestone set; G3-19 identity mode valid (version-less, no version string); G3-20 Documentation Impact gradable; Release Class declared.
- **A1.5:** Form X.
- **A2:** sequence and stage applicability.
- **A3:** change specification and the matrix.
- **A3.5:** the agent-editability read.
- **A4:** within-release, cross-PR, structural, and the roster.
- **A5:** the plan; CIAC (none, linted); the Verification Plan with AC-Binding and the baseline; Delivery; Rollback; the Manifest.
- **A6:** the quota budget.
- **Phase B:** the operator's.

## Stage 5 — locked specification (revision 2, §§ 2–5)

Transcribed from revision 2 of the Stage-5 output. The census procedure below is the locked block, byte for byte (sha256 `6b43236f9fce612f96b3c29db0138b66f17bb75b8ce53733cf0bef0ac6fe7a59`). Read it together with § Stage 5 lock amendments, which win where they disagree.

### 2. Census method

**Channels** are record predicates, never substrings:
- **ch1:** in a top-level `<projects>/<dir>/<session>.jsonl`, a `type == "assistant"` record holding a `tool_use` named `Skill`.
- **ch2:** the same, under `<session>/subagents/**`, or in any nested file carrying `isSidechain: true`.
- **ch3:** a top-level, non-`isMeta` user turn whose text opens with `<command-message>` or `<command-name>`.

Keys: `tool_use.id`, or the record `uuid` for ch3. A call whose `tool_result` has `is_error: true` counts in `skill_call_errors`, not in `total`. Never counted: attachments, `api-request*` replicas, `tool_result` text, prose, `audit.jsonl` and `history.jsonl`. A session is a file with ≥ 1 assistant record that starts by `--until`.

**Store classes.** Roots, in precedence order: `$HOME/.claude/projects` (`cli`), `$CLAUDE_CONFIG_DIR/projects` (`config-dir`), `$FINOPS_SOURCE_ROOT` (`extractor-root`), then every app-data dir the vendor-default glob matches, default first and read whole. An app-data dir that shares a session with another store and wins none is a **copy**. The default is **`agent-mode`** (absent a default, the first non-copy dir with sessions takes the label); the rest are **`profile-N`**. `--roots` replaces all of this with `override-N`.

| Class | Holds | Spec-time counts (Q2, Q3) |
|---|---|---|
| `cli` | CLI and desktop Code sessions | 0 unclassified `.jsonl` |
| `agent-mode` | agent-mode sessions; audit replicas | 0 unclassified; 214 audit replicas |
| `agent-mode-copy` | a copy of `agent-mode` | 0 unclassified; 191 audit replicas |
| `profile-1` to `profile-3` | per-account dirs with no transcripts | 0 |

**Record types** (distinct `type` values at spec time): 26 in `cli` sessions and 11 in its subagent files; 8 and 5 in each agent-mode class. Two carry invocations: `assistant` and `user`. Of 49 attachment subtypes, two matter: `skill_listing` and `invoked_skills`.

**Elements 2 to 5:**
- **Population:** the registry's `## Configuration Items` rows of kind role-Specialist or router, at head (22 at `29c60404`), plus their DEPENDS_ON targets.
- **Window:** max(registration, floor) to `--until`. Registration is the first first-parent commit carrying the row, in UTC.
- **Arms:** per-class strata, zeros printed; the control `release-hub` ≥ 1; the nonce-located census transcript **file**, with mentions > 0 and events 0 (keyed by file, because a spawned session shares its parent's id); `self-test`; `mutations`.
- **Activation:** only the RTE has a `-Conditional Activation` gate (EG-7). It reads DORMANT unless a rung names SAFe, and a `Custom` rung goes to the operator. Program and project rungs are the operator's (OQ-1).

**The procedure:** copy it byte for byte. The record carries the same block.

```python
#!/usr/bin/env python3
# Role-Specialist invocation census: read-only; aggregates keyed by store CLASS, never a path, id, prompt or per-session row.
# Modes: self-test | mutations | nonce | activation | collisions --head H | run --head H --until T --nonce N [--since T] [--roots P:P] [--json F]
# TMPDIR must be the run directory: `run` writes the path-to-class map there.
import argparse, glob, hashlib, json, os, re, secrets, shutil, subprocess, sys, tempfile
from collections import Counter, defaultdict
from datetime import datetime, timedelta
HOME, CONTROL, APP = os.path.expanduser("~"), "release-hub", "Claude"  # APP: the vendor's default app-data directory name
TAG = re.compile(r"<command-name>\s*/?([^<\s]+)\s*</command-name>")
ROW = re.compile(r"^\|\s*\[?`([a-z0-9][a-z0-9-]*)`")
ENTRY = re.compile(r"^- ([A-Za-z0-9_.-]+(?::[A-Za-z0-9_.-]+)?)(.*)$")
J = os.path.join
def norm(n): n = (n or "").strip().lstrip("/"); return (n.split()[0] if n else n).rsplit(":", 1)[-1]
def ts(d): t = d.get("timestamp"); return t[:19] if isinstance(t, str) else None
def store_roots(home=None, env=None, override=None):  # precedence order; whole app-data dirs
  home, env = home or HOME, os.environ if env is None else env
  if override: return [os.path.normpath(r) for r in override.split(os.pathsep) if os.path.isdir(r)]
  r = [J(home, ".claude", "projects")] + ([J(env["CLAUDE_CONFIG_DIR"], "projects")] if env.get("CLAUDE_CONFIG_DIR") else []) + ([env["FINOPS_SOURCE_ROOT"]] if env.get("FINOPS_SOURCE_ROOT") else [])
  r += sorted(glob.glob(J(home, "Library", "Application Support", APP + "*")), key=lambda p: (os.path.basename(p) != APP, os.path.basename(p)))
  out = []
  for x in map(os.path.normpath, r):
    if os.path.isdir(x) and x not in out: out.append(x)
  return out
def kind_of(root, home, env):
  for k, p in (("cli", J(home, ".claude", "projects")), ("config-dir", env.get("CLAUDE_CONFIG_DIR") and J(env["CLAUDE_CONFIG_DIR"], "projects")), ("extractor-root", env.get("FINOPS_SOURCE_ROOT"))):
    if p and root == os.path.normpath(p): return k
  if os.path.dirname(root) == os.path.normpath(J(home, "Library", "Application Support")): return "app-default" if os.path.basename(root) == APP else "app"
  return "override"
def classify(p):  # ("top"|"sub"|"nested", session) for a file under a projects/ segment, else None
  parts = p.split(os.sep)
  if "projects" not in parts: return None
  rest = parts[len(parts) - parts[::-1].index("projects"):]
  if len(rest) == 2: return ("top", rest[1][:-6])
  return ("sub" if rest[2] == "subagents" else "nested", rest[1]) if len(rest) >= 4 else None
def read(p, kind, nonce, subjects):
  f = dict(start=None, last="", n=0, asst=0, side=False, listed=None, calls=[], slash=[], err=set(), inv=set(), origin=Counter(), raw=0, nonce=False)
  for line in open(p, encoding="utf-8", errors="replace"):
    try: d = json.loads(line)
    except ValueError: continue
    if not isinstance(d, dict): continue
    t, ty = ts(d), d.get("type"); f["n"] += 1; f["last"] = max(f["last"], t or "")
    if ty in ("user", "assistant") and t: f["start"] = min(f["start"] or t, t)
    if ty in ("user", "assistant") and isinstance(d.get("entrypoint"), str): f["origin"][d["entrypoint"]] += 1
    f["asst"] += ty == "assistant"; f["side"] |= d.get("isSidechain") is True
    a = d.get("attachment") if ty == "attachment" else None
    if isinstance(a, dict) and a.get("type") == "skill_listing" and a.get("isInitial") and f["listed"] is None:
      f["listed"] = ({norm(x) for x in a.get("names") or []}, {norm(m.group(1)): "described" if m.group(2).startswith(": ") else "name-only"
             for m in map(ENTRY.match, (a.get("content") or "").splitlines()) if m}, len(a.get("content") or ""))
    if isinstance(a, dict) and a.get("type") == "invoked_skills": f["inv"] |= {norm(s.get("name")) for s in a.get("skills") or [] if isinstance(s, dict)}
    if nonce: f["nonce"] |= nonce in line; f["raw"] += sum(line.count(s) for s in subjects)
    c = d["message"].get("content") if isinstance(d.get("message"), dict) else None
    if ty == "assistant" and isinstance(c, list):  # ch1/ch2
      f["calls"] += [(i.get("id") or "%s/%d" % (d.get("uuid"), k), norm(str((i.get("input") or {}).get("skill") or (i.get("input") or {}).get("command") or "")), t)
             for k, i in enumerate(c) if isinstance(i, dict) and i.get("type") == "tool_use" and i.get("name") == "Skill"]
    if ty == "user" and isinstance(c, list):
      f["err"] |= {i.get("tool_use_id") for i in c if isinstance(i, dict) and i.get("type") == "tool_result" and i.get("is_error") is True}
    if ty == "user" and kind == "top" and not d.get("isMeta"):  # ch3: text that OPENS with the tag
      for x in [c] if isinstance(c, str) else [i.get("text", "") for i in c if isinstance(i, dict) and i.get("type") == "text"] if isinstance(c, list) else []:
        s = x.lstrip()
        if s.startswith(("<command-message>", "<command-name>")) and TAG.search(s):
          f["slash"].append((d.get("uuid") or hashlib.sha1(line.encode()).hexdigest(), norm(TAG.search(s).group(1)), t)); break
  return f
def scan(roots, until, nonce, subjects, home=None, env=None):  # every copy is read
  home, env = home or HOME, os.environ if env is None else env
  files, extra = [], defaultdict(Counter)
  for ri, root in enumerate(roots):
    for dp, _, fn in os.walk(root):
      for name in sorted(x for x in fn if x.endswith(".jsonl")):
        k = classify(J(dp, name))
        if not k: extra[ri]["audit_logs" if name == "audit.jsonl" else "unclassified_jsonl"] += 1; continue
        f = read(J(dp, name), k[0], nonce, subjects); f.update(ri=ri, kind=k[0], sid=k[1], name=name)
        if k[0] == "nested":
          if f["side"]: f["kind"] = "sub"
          else: extra[ri]["unclassified_jsonl"] += 1; extra[ri]["unclassified_skill_calls"] += len(f["calls"]); continue
        files.append(f)
  return files, [kind_of(r, home, env) for r in roots], extra
def aggregate(files, kinds, extra, subjects, reg, until, neighbours=()):
  ok = [f for f in files if f["asst"] and f["start"] and f["start"] <= until]
  rank = lambda f: (f["last"], f["n"], -f["ri"])  # the most recent copy wins
  win = {}
  for f in ok:
    k = (f["kind"], f["sid"], f["name"] if f["kind"] == "sub" else "")
    if k not in win or rank(f) > rank(win[k]): win[k] = f
  W = {id(f) for f in win.values()}; S = {k[1]: f for k, f in win.items() if k[0] == "top"}
  share, wins, by = Counter(), Counter(), defaultdict(list)
  for f in ok:
    if f["kind"] == "top": by[f["sid"]].append(f)
  for fs in by.values():
    if len({f["ri"] for f in fs}) > 1:
      for f in fs: share[f["ri"]] += 1; wins[f["ri"]] += id(f) in W
  held, cls, nc, npf, am = Counter(f["ri"] for f in S.values()), {}, 0, 0, "app-default" in kinds
  for ri, k in enumerate(kinds):
    if k in ("cli", "config-dir", "extractor-root"): cls[ri] = k
    elif k == "override": cls[ri] = "override-%d" % (ri + 1)
    elif share[ri] and not wins[ri]: nc += 1; cls[ri] = "agent-mode-copy" + ("-%d" % nc) * (nc > 1)
    elif (k == "app-default" or (not am and held[ri])) and "agent-mode" not in cls.values(): am = True; cls[ri] = "agent-mode"
    else: npf += 1; cls[ri] = "profile-%d" % npf
  errs, occ = set().union(*[f["err"] for f in ok]), defaultdict(list)
  for f in ok:
    for ch, lst in (("ch1" if f["kind"] == "top" else "ch2", f["calls"]), ("ch3", f["slash"])):
      for key, n, t in lst: occ[key].append((t, f, ch, n))
  ev, hit, inv = {}, defaultdict(set), defaultdict(set)
  for key, os_ in occ.items():
    tl = [o[0] for o in os_ if o[0]]
    if not tl: continue
    t = min(tl)  # an event's time is its earliest copy
    o = next((o for o in os_ if id(o[1]) in W), min(os_, key=lambda o: o[0] or "9"))
    ev[key] = (o[2], o[3], t, cls[o[1]["ri"]], key in errs, (o[1]["origin"].most_common(1) or [("absent", 0)])[0][0])
    for o in os_:
      if key not in errs: hit[o[1]["sid"]].add(o[3])
  for f in ok: inv[f["sid"]] |= f["inv"]
  inwin = lambda e, r: r <= e[2] <= until and not e[4]
  floor = min((f["start"] for f in S.values()), default=None)
  strata = Counter((e[3], e[0]) for e in ev.values() if inwin(e, ""))
  keys = {(cls[f["ri"]], c) for f in S.values() for c in ("ch1", "ch3")} | {(cls[f["ri"]], "ch2") for k, f in win.items() if k[0] == "sub"}
  sens = {"%s | %s" % k: strata.get(k, 0) for k in sorted(keys | set(strata))}
  def counts(s, r):
    c = Counter(e[0] for e in ev.values() if e[1] == s and inwin(e, r))
    return dict(ch1_direct=c["ch1"], ch2_subagent=c["ch2"], ch3_slash=c["ch3"], total=sum(c.values()), skill_call_errors=sum(1 for e in ev.values() if e[1] == s and e[4] and r <= e[2] <= until))
  per = {}
  for s in subjects:
    r = reg.get(s, "9999"); ws = [f for f in S.values() if r <= f["start"] <= until]
    listed = Counter(cls[f["ri"]] for f in ws if f["listed"] and s in f["listed"][0])
    res = sum(1 for x, f in S.items() if r <= f["start"] and s in inv[x] and s not in hit[x])
    el = ["%s | %s blind" % k for k in sorted(keys) if k[0] in listed and strata.get(k, 0) == 0] + ["invoked_skills residue %d" % res] * bool(res)
    per[s] = dict(registered=r, window_start=max(r, floor or r), sessions_in_window=dict(Counter(cls[f["ri"]] for f in ws)), listed_sessions_in_window=dict(listed), sessions_without_listing_record=dict(Counter(cls[f["ri"]] for f in ws if not f["listed"])),
           **counts(s, r), pre_registration=sum(1 for e in ev.values() if e[1] == s and e[2] < r and not e[4]), invoked_skills_unexplained=res,
           by_origin=dict(Counter(e[5] for e in ev.values() if e[1] == s and inwin(e, r))),
           verdict="UNEXPOSED" if not listed else "CLEAN" if not el else "INDETERMINATE: " + "; ".join(el))
  nb = {n: counts(n, "") for n in neighbours}
  days, tally, r4, dn, ln, evs = Counter(), defaultdict(Counter), Counter(), [], [], defaultdict(list)
  for e in ev.values():
    if inwin(e, ""): evs[e[1]].append(e[2])
  for f in S.values():
    if not f["listed"]: continue
    names, forms, size = f["listed"]; days[f["start"][:10]] += 1; ln.append(size); dn.append(sum(v == "described" for v in forms.values()))
    lo = (datetime.fromisoformat(f["start"]) - timedelta(days=14)).isoformat()
    for n, v in forms.items(): r4[v, any(lo <= t < f["start"] for t in evs.get(n, ()))] += 1
    for s in subjects:
      if reg.get(s, "9999") <= f["start"]: tally[s][forms.get(s, "listed-unparsed" if s in names else "not-listed")] += 1
  q = lambda x: [min(x), sorted(x)[len(x) // 2], max(x)] if x else None
  rate = lambda u: "%d/%d" % (r4["described", u], r4["described", u] + r4["name-only", u])
  cnt = lambda C, c: sum(1 for f in C if cls[f["ri"]] == c)
  classes = {c: dict(sessions=cnt(S.values(), c), copy_sessions_skipped=cnt([f for f in ok if f["kind"] == "top" and id(f) not in W], c),
           copy_only_sessions=cnt(S.values(), c) * c.startswith("agent-mode-copy"), sessions_with_listing=cnt([f for f in S.values() if f["listed"]], c), subagent_files=cnt([f for k, f in win.items() if k[0] == "sub"], c),
           **{x: extra[ri][x] for x in ("unclassified_jsonl", "unclassified_skill_calls", "audit_logs")}) for ri, c in cls.items()}
  nf = [f for f in ok if f["nonce"]]
  return {"until": until, "store_floor": floor, "classes": classes, "sessions_by_store": {c: v["sessions"] for c, v in classes.items() if v["sessions"]},
      "subagent_files_by_store": {c: v["subagent_files"] for c, v in classes.items() if v["subagent_files"]},
      "arms": {"sensitivity_by_store_channel": sens, "control_" + CONTROL: sum(1 for e in ev.values() if e[1] == CONTROL and inwin(e, "")),
          "specificity_nonce_files": len(nf), "specificity_nonce_raw_subject_mentions": sum(f["raw"] for f in nf),
          "specificity_nonce_subject_events": sum(1 for f in nf for _, n, _ in f["calls"] + f["slash"] if n in subjects)},
      "subjects": per, "neighbours": nb, "_classmap": cls,
      "listing": {"days_with_listings": len(days), "sessions_with_listing": sum(days.values()), "described_per_listing": q(dn),
            "described_if_used_in_prior_14d": rate(True), "described_if_not_used": rate(False), "per_subject": {s: dict(c) for s, c in tally.items()}}}
def git(*a): return subprocess.run(["git", *a], capture_output=True, text=True, check=True, env=dict(os.environ, TZ="UTC")).stdout
def population(head):
  subj, deps, on = [], {}, False
  for line in git("show", head + ":core/skills/registry.md").splitlines():
    if line.startswith("## "): on = line.startswith("## Configuration Items")
    m = ROW.match(line) if on else None
    if m and line.split("|")[2].strip() in ("role-Specialist", "router"): subj.append(m.group(1)); deps[m.group(1)] = re.findall(r"DEPENDS_ON ([a-z0-9-]+)", line.split("|")[5])
  return subj, deps
def registration(head, subj):
  reg = {}
  for line in git("log", "--first-parent", "--reverse", "--date=format-local:%Y-%m-%dT%H:%M:%S", "--format=%H %cd", head, "--", "core/skills/registry.md").splitlines():
    sha, when = line.split()
    for s in set(subj) & {m.group(1) for m in map(ROW.match, git("show", sha + ":core/skills/registry.md").splitlines()) if m}: reg.setdefault(s, (when, sha))
  return reg
def base_before(head, when): return git("rev-list", "-1", "--before=" + when, head).strip()
def descriptions_changed(head, subjects, bases):  # bases: {subject: commit or ""}; an empty base is INDETERMINATE
  def desc(sha, s):
    p = [l for l in git("ls-tree", "-r", "--name-only", sha).splitlines() if l.endswith("/skills/%s/SKILL.md" % s)]
    m = re.search(r"^description:[ \t]*[>|]?-?[ \t]*\n?((?:[ \t]+.*\n?)+|.*)", (git("show", "%s:%s" % (sha, p[0])) if p else "").split("\n---", 1)[0], re.M)
    return " ".join(m.group(1).split()) if m else None
  out = {"changed": [], "indeterminate": [], "unchanged": 0}
  for s in subjects:
    b = bases.get(s); x, y = (desc(b, s), desc(head, s)) if b else (None, None)
    if x is None or y is None: out["indeterminate"].append(s)
    elif x != y: out["changed"].append(s)
    else: out["unchanged"] += 1
  return out
def toml_key(path, sec, key):
  cur = None
  for line in open(path, encoding="utf-8", errors="replace") if os.path.isfile(path) else []:
    m = re.match(r"^\s*\[([^\]]+)\]", line)
    if m: cur = m.group(1).strip(); continue
    m = re.match(r'^\s*%s\s*=\s*"([^"]*)"' % re.escape(key), line)
    if cur == sec and m: return m.group(1)
  return "absent"
def activation(home=None, ws=None, template="core/config/operator.toml.template"):
  home = home or HOME; ws = ws or os.environ.get("CLAUDE_WORKSPACE_ROOT", J(home, "Claude")); pf = J(ws, "projects/_config/PORTFOLIO.md")
  rungs = [("tracked default", toml_key(template, "methodology", "default_delivery_approach")), ("individual config", toml_key(J(home, ".config/pmo-platform/operator.toml"), "methodology", "default_delivery_approach"))]
  rungs += [("portfolio file", v) for v in re.findall(r"delivery_approach:\s*\"?([A-Za-z0-9]+)", open(pf, encoding="utf-8").read().split("\n---", 1)[0])] if os.path.isfile(pf) else []
  safe = next((c for c, v in rungs if v == "SAFe"), None); cust = next((c for c, v in rungs if v == "Custom"), None)
  return {"pmo-release-train-engineer": "ACTIVE-POSSIBLE" if safe else "OPERATOR-CONFIRM (Custom)" if cust else "DORMANT",
      "deciding_rung_class": safe or cust or "none", "rungs_read": sorted({c for c, v in rungs if v != "absent"}), "operator_confirms": "program, project"}
def collisions(head, subjects, min_tokens=3):
  phr = {}
  for f in git("ls-tree", "-r", "--name-only", head).splitlines():
    if re.match(r"^(core|operations|release)/skills/[^/]+/SKILL\.md$", f):
      phr[f.split("/")[2]] = {p for p in {" ".join(re.findall(r"[a-z0-9]+", q.lower())) for l in git("show", head + ":" + f).splitlines()
                  if re.search(r"Trigger|→ \*\*Mode|\|\s*Mode\b", l) for q in re.findall(r'"([^"]{6,80})"', l)} if len(p.split()) >= 2}
  def hit(x, y):
    a, b = sorted((x, y), key=len)
    return x == y or (len(a.split()) >= min_tokens and " %s " % a in " %s " % b)
  return [(a, b, x, y) for a in subjects for b in phr if b != a for x in phr.get(a, ()) for y in phr[b] if hit(x, y)]
def self_test():  # synthetic HOME and git history only
  global git
  tmp = tempfile.mkdtemp(); h = tmp + "/home"; app = h + "/Library/Application Support/"; c = h + "/.claude/projects/p/"
  S = ["pmo-" + x for x in ("architect", "ocm-lead", "qa-lead", "program-manager", "tier-1-support", "data-engineer", "release-manager", "scrum-master", "devops-sre", "software-engineer")]
  def w(p, *recs): os.makedirs(os.path.dirname(p), exist_ok=True); open(p, "w").write("\n".join(json.dumps(r) for r in recs) + "\n")
  def R(ty, u, t, c, **k): return dict({"type": ty, "uuid": u, "timestamp": t, "message": {"content": c}}, **k)
  def A(u, t, *items, **k): return R("assistant", u, t, [i if isinstance(i, dict) else {"type": "tool_use", "id": i[0], "name": "Skill", "input": {"skill": i[1]}} for i in items], **k)
  def L(t, desc): return {"type": "attachment", "timestamp": t, "attachment": {"type": "skill_listing", "isInitial": True, "names": S + [CONTROL, "fx-engine"],
              "content": "\n".join("- %s%s" % (s, ": d" * (s in desc)) for s in S + [CONTROL, "fx-engine"])}}
  D1, D2, D5, OK, E = "2026-11-01T10:00:00Z", "2026-11-03T10:00:00Z", "2026-11-05T10:00:00Z", {"type": "text", "text": "ok"}, {"entrypoint": "claude-desktop"}
  tag = lambda n: "<command-name>/%s</command-name>" % n; nb = "NONCE-X " + " ".join(S)
  s1 = [L(D1, {S[0]}), R("user", "u1", D1, "<command-message>pmo-ocm-lead</command-message>\n" + tag(S[1]), **E), R("user", "u2", D1, tag("x:" + S[3]), **E),
     A("a1", D1, ("T1", S[0]), ("T10", "fx-engine"), **E), {"type": "attachment", "timestamp": D1, "attachment": {"type": "invoked_skills", "skills": [{"name": S[0]}, {"name": S[2]}]}},
     A("a9", "2026-12-03T10:00:00Z", ("T11", S[5]), **E)]
  w(c + "S1.jsonl", *s1); w(c + "S2.jsonl", *s1)
  w(c + "S1/subagents/agent-1.jsonl", A("a2", D1, ("T2", S[2]), isSidechain=True), R("user", "u7", D1, tag(S[4]), isSidechain=True))
  w(c + "S1/workflows/run-1/agent-w.jsonl", A("a8", D1, ("T8", S[9]), isSidechain=True))
  w(c + "S1/tool-results/x.jsonl", A("a10", D1, ("T14", S[8])))
  w(c + "S3.jsonl", L(D1, {S[0]}), R("user", "u3", D1, [{"type": "tool_result", "content": nb + tag(S[0])}]), R("user", "u4", D1, tag(S[4]), isMeta=True),
   R("user", "u15", D1, "see %s above" % tag(S[8])), {"type": "api-request-blob", "timestamp": D1, "message": {"content": [A("x", D1, ("T9", S[5]))["message"]["content"][0], {"type": "text", "text": tag(S[0])}]}},
   A("a3", D1, {"type": "text", "text": S[0]}, {"type": "tool_use", "id": "T3", "name": "Read", "input": {"file_path": "operations/skills/pmo-ocm-lead/SKILL.md"}}))
  w(c + "S5.jsonl", R("user", "u5", D1, tag(S[0])))
  w(c + "S6/subagents/agent-n.jsonl", R("user", "u6", D1, [{"type": "tool_result", "content": nb}], isSidechain=True), A("a6", D1, OK, isSidechain=True))
  w(c + "S6/subagents/agent-m.jsonl", A("a7", D1, ("T7", S[4]), isSidechain=True))  # a sibling in the nonce file's lineage
  w(c + "S10.jsonl", A("a11", D5, ("T5", S[6]))); w(c + "S11.jsonl", R("user", "u11", "2026-11-20T10:00:00Z", "go"), A("a11", "2026-12-05T10:00:00Z", ("T5", S[6])))
  w(c + "S12.jsonl", R("user", "u12", "2026-12-02T10:00:00Z", "go"), A("a13", "2026-12-02T10:00:00Z", ("T12", S[5])))
  w(c + "S13.jsonl", L(D2, {S[0], S[1]}), R("user", "u13", D2, "go", entrypoint="sdk-cli"), A("a14", D2, ("T13", S[7])),
   R("user", "u14", D2, [{"type": "tool_result", "tool_use_id": "T13", "is_error": True, "content": "no"}]), A("a15", D2, OK), L(D2, set()))
  lam, T1, T2 = "/local-agent-mode-sessions/x/y/local_z/", "2026-10-01T09:00:00Z", "2026-10-05T09:00:00Z"
  for d, s4 in ((APP, [A("a4", T1, OK), A("a5", T2, ("T4", CONTROL))]), (APP + "-zz", [A("a4", T1, OK)])):
    w(app + d + lam + ".claude/projects/p/S4.jsonl", *s4); w(app + d + lam + ".claude/projects/p/S4/subagents/agent-2.jsonl", A("a16", T1, OK, isSidechain=True))
  w(app + APP + lam + "audit.jsonl", A("a5", T2, ("T4", CONTROL))); w(app + APP + "-zz" + lam + ".claude/projects/p/S8.jsonl", A("a17", T1, OK))
  w(app + APP + "P" + lam + ".claude/projects/p/S9.jsonl", A("a18", T1, OK)); w(app + APP + "Q" + lam + ".claude/projects/p/S9.jsonl", A("a18", T1, OK), A("a19", T2, ("T15", "fx-engine")))
  os.makedirs(app + APP + "R")  # an empty profile directory; APP+"P" is a stale copy of profile APP+"Q" that sorts before it
  U = "2026-12-01T00:00:00"; reg = dict({s: "2026-06-20T00:00:00" for s in S}, **{S[3]: "2026-11-05T00:00:00"})
  roots = store_roots(home=h, env={}); r = aggregate(*scan(roots, U, "NONCE-X", S, home=h, env={}), S, reg, U, neighbours=["fx-engine"])
  P, Ar, G, C = r["subjects"], r["arms"], r["listing"], r["classes"]
  want = dict(zip(S, [(1, 0, 0), (0, 0, 1), (0, 1, 0), (0, 0, 0), (0, 1, 0), (0, 0, 0), (1, 0, 0), (0, 0, 0), (0, 0, 0), (0, 1, 0)]))
  sens = {"agent-mode | ch1": 1, "agent-mode | ch2": 0, "agent-mode | ch3": 0, "agent-mode-copy | ch1": 0, "agent-mode-copy | ch3": 0, "cli | ch1": 3, "cli | ch2": 3, "cli | ch3": 2, "profile-1 | ch1": 1, "profile-1 | ch3": 0}
  checks = [("roots", [os.path.basename(x) for x in roots] == ["projects", APP, APP + "-zz", APP + "P", APP + "Q", APP + "R"]),
       ("channels", all((P[k]["ch1_direct"], P[k]["ch2_subagent"], P[k]["ch3_slash"]) == v for k, v in want.items())),
       ("sessions", r["sessions_by_store"] == {"cli": 6, "agent-mode": 1, "agent-mode-copy": 1, "profile-1": 1}),
       ("counters", (C["agent-mode-copy"]["copy_sessions_skipped"], C["agent-mode-copy-2"]["copy_sessions_skipped"], C["agent-mode-copy"]["copy_only_sessions"],
                            C["cli"]["unclassified_jsonl"], C["cli"]["unclassified_skill_calls"], C["agent-mode"]["audit_logs"]) == (1, 1, 1, 1, 1, 1)),
       ("subagent files", r["subagent_files_by_store"] == {"cli": 4, "agent-mode": 1}),
       ("strata", Ar["sensitivity_by_store_channel"] == sens and Ar["control_" + CONTROL] == 1),
       ("nonce", (Ar["specificity_nonce_files"], Ar["specificity_nonce_subject_events"]) == (2, 0) and Ar["specificity_nonce_raw_subject_mentions"] > 0),
       ("errors, pre-registration", (P[S[7]]["total"], P[S[7]]["skill_call_errors"], P[S[3]]["pre_registration"]) == (0, 1, 1)),
       ("verdicts", [P[k]["verdict"] for k in (S[0], S[2], S[3])] == ["CLEAN", "INDETERMINATE: invoked_skills residue 1", "UNEXPOSED"]),
       ("origin, neighbours", P[S[0]]["by_origin"] == {"claude-desktop": 1} and r["neighbours"]["fx-engine"]["total"] == 2),
       ("listing", (G["days_with_listings"], G["described_if_used_in_prior_14d"], G["described_if_not_used"]) == (2, "2/7", "3/41")
       and G["per_subject"][S[0]] == {"described": 4} and S[3] not in G["per_subject"])]
  rm = "## Configuration Items\n\n| name | kind | module | lifecycle | dependencies | owner | trigger | modes |\n|---|---|---|---|---|---|---|---|\n"
  row = lambda n, k, d: "| [`%s`](x) | %s | m | active | %s | o | t | m |\n" % (n, k, d)
  sm = lambda n, ds, tr: "---\nname: %s\ndescription: >\n  %s\n---\n**Trigger:** %s\n" % (n, ds, tr)
  c1 = {"core/skills/registry.md": rm + row(S[0], "role-Specialist", "DEPENDS_ON fx-engine") + row("fx-engine", "function-skill", "—"), "release/skills/pmo-architect/SKILL.md": sm(S[0], "A", '"are we ready for go-live", "integration risk"')}
  c2 = dict(c1, **{"core/skills/registry.md": c1["core/skills/registry.md"] + row(S[3], "role-Specialist", "—") + row("pmo-skill-router", "router", "—"),
          "release/skills/pmo-architect/SKILL.md": sm(S[0], "B", '"are we ready for go-live", "integration risk"'),
          "operations/skills/pmo-program-manager/SKILL.md": sm(S[3], "P", '"are we ready", "tie the integration risk to the sprint plan"')})
  hist = [("c1", "2026-06-20T00:00:00", c1), ("c2", "2026-11-05T00:00:00", c2)]
  def fake(*a):
    snap = lambda x: next((f for s, _, f in hist if s == x), {})
    if a[0] == "show": x, p = a[1].split(":", 1); return snap(x).get(p, "")
    if a[0] == "log": return "\n".join("%s %s" % (s, t) for s, t, _ in hist)
    if a[0] == "rev-list": return ([s for s, t, _ in hist if t <= a[2].split("=", 1)[1]] or [""])[-1]
    return "\n".join(sorted(snap(a[3])))
  real, git = git, fake
  try: sj, deps = population("c2"); rg = registration("c2", sj); dc = descriptions_changed("c2", sj, {S[0]: "c1", S[3]: rg[S[3]][1]}); co = collisions("c2", [S[0]])
  finally: git = real
  os.makedirs(h + "/.config/pmo-platform"); open(h + "/.config/pmo-platform/operator.toml", "w").write('[methodology]\ndefault_delivery_approach = "Custom"\n')
  open(tmp + "/tpl.toml", "w").write('[methodology]\ndefault_delivery_approach = "Scrum"\n'); ac = activation(home=h, ws=tmp + "/ws", template=tmp + "/tpl.toml")
  checks += [("population", (sj, deps[S[0]]) == ([S[0], S[3], "pmo-skill-router"], ["fx-engine"])),
       ("registration", (rg[S[0]], rg[S[3]][0]) == (("2026-06-20T00:00:00", "c1"), "2026-11-05T00:00:00")),
       ("descriptions", dc == {"changed": [S[0]], "indeterminate": ["pmo-skill-router"], "unchanged": 1}),
       ("collisions", co == [(S[0], S[3], "are we ready for go live", "are we ready")]),
       ("activation", ac["pmo-release-train-engineer"] == "OPERATOR-CONFIRM (Custom)" and ac["deciding_rung_class"] == "individual config")]
  shutil.rmtree(tmp)
  for name, ok in checks: print(("PASS " if ok else "FAIL ") + name)
  return 0 if all(ok for _, ok in checks) else 1
MUTATIONS = [  # (id, defect, old, new): each must turn self-test FAIL; `mutations` re-runs them all (Stage 7's sensitivity arm)
  ("M1", "replica counted", 'if ty == "assistant" and isinstance(c, list):', 'if ty in ("assistant", "api-request-blob") and isinstance(c, list):'),
  ("M2", "dedupe removed", "occ[key].append((t, f, ch, n))", "occ[(key, len(occ))].append((t, f, ch, n))"),
  ("M3", "tag anywhere", 's.startswith(("<command-message>", "<command-name>")) and TAG.search(s)', "TAG.search(s)"),
  ("M4", "walk-order precedence", 'rank = lambda f: (f["last"], f["n"], -f["ri"])', 'rank = lambda f: (-f["ri"],)'),
  ("M5", "no spend filter", 'if f["asst"] and f["start"] and', 'if f["start"] and'),
  ("M6", "nonce by lineage", 'for f in nf for _, n, _ in f["calls"]', 'for g in nf for f in ok if f["sid"] == g["sid"] for _, n, _ in f["calls"]'),
  ("M7", "no registration bound", "inwin = lambda e, r: r <= e[2] <= until", "inwin = lambda e, r: e[2] <= until"),
  ("M8", "zero strata dropped", "strata.get(k, 0) for k in sorted(keys | set(strata))}", "v for k, v in sorted(strata.items())}"),
  ("M9", "isMeta counted", 'kind == "top" and not d.get("isMeta"):', 'kind == "top":'),
  ("M10", "errors counted", 'i.get("is_error") is True}', 'i.get("is_error") is None and False}'),
  ("M11", "verdict over unlisted", "if k[0] in listed and strata", "if strata"),
  ("M12", "tally unwindowed", 'if reg.get(s, "9999") <= f["start"]: tally', "if True: tally"),
  ("M13", "no neighbours", 'nb = {n: counts(n, "") for n in neighbours}', "nb = {}"),
  ("X1", "no upper bound", "r <= e[2] <= until and not e[4]", "r <= e[2] and not e[4]"),
  ("X2", "no session filter", 'f["start"] and f["start"] <= until]', 'f["start"]]'),
  ("X3", "latest copy", "t = min(tl)", "t = max(tl)"),
  ("X4", "glob narrowed", 'APP + "*")', "APP)"),
  ("X5", "last registration", "reg.setdefault(s, (when, sha))", "reg.__setitem__(s, (when, sha))"),
  ("X6", "no kind filter", 'strip() in ("role-Specialist", "router")', 'strip() != "?"'),
  ("X7", "rates swapped", "rate(True), \"described_if_not_used\": rate(False)", "rate(False), \"described_if_not_used\": rate(True)"),
  ("X8", "Custom ignored", 'cust = next((c for c, v in rungs if v == "Custom"), None)', "cust = None"),
  ("X9", "nested as subagent", 'if f["side"]: f["kind"] = "sub"', 'if 1: f["kind"] = "sub"'),
  ("X10", "no description diff", 'elif x != y: out["changed"].append(s)', "elif 0: pass"),
  ("X11", "last listing", ' and f["listed"] is None:', ":"),
  ("X12", "subagent turns counted", 'if ty == "user" and kind == "top" and', 'if ty == "user" and'),
  ("X13", "2-token containment", "len(a.split()) >= min_tokens", "len(a.split()) >= 2")]
def mutations():
  code, table = open(__file__).read().split("\nMUTATIONS = [", 1); missed = []
  for mid, what, old, new in [("C0", "none (control)", "", "")] + MUTATIONS:
    assert not old or code.count(old) == 1, mid
    d = tempfile.mkdtemp(); p = J(d, "m.py"); open(p, "w").write(code.replace(old, new, 1) * bool(old) + code * (not old) + "\nMUTATIONS = [" + table)
    rc = subprocess.run([sys.executable, "-I", p, "self-test"], capture_output=True, text=True, env=dict(os.environ, TMPDIR=d)).returncode; shutil.rmtree(d)
    ok = (rc == 0) if mid == "C0" else (rc != 0); missed += [mid] * (not ok); print("%-4s %-24s %s" % (mid, what, "caught" if ok and old else "ok" if ok else "MISSED"))
  return 1 if missed else 0
if __name__ == "__main__":
  ap = argparse.ArgumentParser(); ap.add_argument("mode", choices=["self-test", "mutations", "nonce", "run", "activation", "collisions"])
  for f in ("--head", "--until", "--nonce", "--json", "--since", "--roots"): ap.add_argument(f)
  o = ap.parse_args()
  if o.mode in ("self-test", "mutations"): sys.exit(self_test() if o.mode == "self-test" else mutations())
  if o.mode in ("nonce", "activation"): sys.exit(print("census-nonce-" + secrets.token_hex(8) if o.mode == "nonce" else json.dumps(activation(), indent=1)))
  subj, deps = population(o.head)
  if o.mode == "collisions": sys.exit(print("\n".join(" | ".join(r) for r in collisions(o.head, subj))))
  until, regs, roots = o.until[:19], registration(o.head, subj), store_roots(override=o.roots)
  out = aggregate(*scan(roots, until, o.nonce, subj), subj, {s: w for s, (w, _) in regs.items()}, until, neighbours=sorted({t for v in deps.values() for t in v}))
  cm = out.pop("_classmap"); open(J(tempfile.gettempdir(), "census-class-map.txt"), "w").write("".join("%s\t%s\n" % (cm[i], r) for i, r in enumerate(roots)))
  ws = lambda s: out["subjects"][s]["window_start"]
  bases = {s: base_before(o.head, o.since) if o.since else regs[s][1] if ws(s) == regs[s][0] else base_before(o.head, ws(s)) for s in regs}
  out.update(head=o.head, subject_count=len(subj), stores_covered=sorted(out["classes"]), descriptions=descriptions_changed(o.head, subj, bases))
  if o.json: json.dump(out, open(o.json, "w"), indent=1)
  print(json.dumps(out, indent=1))
```

**Run steps.** Run them in Stage 6, from the worktree root. The census session invokes no subject skill.

```bash
git fetch origin main && HEAD_SHA=$(git rev-parse origin/main)
export TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/census-XXXXXX")"     # the run directory; save the block as "$TMPDIR/census.py"
python3 -I "$TMPDIR/census.py" self-test && python3 -I "$TMPDIR/census.py" mutations   # all PASS, then 0 MISSED, or stop
python3 -I "$TMPDIR/census.py" nonce                             # leave the nonce in this transcript
UNTIL=$(date -u +%Y-%m-%dT%H:%M:%S)
python3 -I "$TMPDIR/census.py" run --head "$HEAD_SHA" --until "$UNTIL" --nonce '<printed nonce>' --json "$TMPDIR/census.json"
python3 -I "$TMPDIR/census.py" run --head "$HEAD_SHA" --until "$UNTIL" --nonce '<printed nonce>' --since 2026-10-15T23:59:59 --json "$TMPDIR/ctl.json"  # AC-3 control: 0 changed
python3 -I "$TMPDIR/census.py" activation; python3 -I "$TMPDIR/census.py" collisions --head "$HEAD_SHA" > "$TMPDIR/body.txt"
# Check 67's harness: the run_eval_audit.py invocation in core/deploy/deploy.sh's Check 67 block, plus --output-json "$TMPDIR/c67.json"
for s in $(python3 -I -c 'import json,sys;print(" ".join(json.load(open(sys.argv[1]))["subjects"]))' "$TMPDIR/census.json"); do printf '%s\t' "$s"
  git grep -l -wF "$s" "$HEAD_SHA" -- . | sed 's/^[^:]*://' | awk '/^(release\/releases\/|CHANGELOG\.md$)/{h++} /^packages\//{a++} {n++} END{printf "all=%d history=%d artifacts=%d live=%d\n",n,h,a,n-h-a}'; done
```

Only printed aggregates enter the record. A description that changed inside a window is named, and its render forms are compared only after that change.

### 3. Disposition table: schema, coding scheme and rubric

**One row per subject with total 0, plus the router.** Columns:
- subject · kind · module;
- census and `verdict`, cited by name;
- listed and no-record sessions per class;
- activation (RTE only);
- persona card;
- **disposition** — `re-trigger` · `re-home` · `retire` · `keep (dormant by design, ADR-033)`, where the router takes no `keep`;
- rule · reason;
- tier · confidence;
- collisions, for re-trigger: the Check 67 band of the max-J pair with its counterpart, J, `exact_phrase_overlap` and linkage, plus exact or ≥ 3-token body overlaps;
- pre-count, for re-home and retire: `pre <live> live / <all> (history, artifacts)`, plus the out-of-repo copies;
- receiving skill and mode;
- downstream work, in prose (numbers go under `## References`);
- covariates: neighbours, `by_origin`, any downstream-card mention;
- `follow-up: <class>[ · bug | · feature]` with its Severity, per § 8.2; `none` only on `keep`.

**Coding scheme.** The first rule that decides wins.

| Rule | Condition → outcome |
|---|---|
| R0 | total 0 in the window → the row enters, carrying its printed verdict. The router always enters |
| R1 | methodology-conditional and DORMANT → `keep`, CHEAP, `follow-up: none`. Otherwise continue |
| R2 | 0 listed sessions in a class: a qualifier, not a value. The reason names the gap, and any re-trigger then depends on fixing it, which is its own follow-up |
| R3 | only where a persona card's scope covers the registry trigger surface. The card names the skill, and the skill holds `Modes:` or headings the card lacks (a G1 read) → `re-trigger` through the **persona seam**. Otherwise → `re-home` if unique content exists, else `retire` |
| R4a | against used sibling Specialists: ADR-019's three conjuncts. Trigger = a Check 67 band or an exact or ≥ 3-token body overlap; write = the Output Contract emission; role = the primary role. Any failure → `re-home` into that sibling; ≥ 2 failures → the tie rule |
| R4b | against a composed function-skill: is there an Output Contract element absent from every composed skill's contract (a G1 read)? No → `retire`; yes → R5 |
| R5 | → `re-trigger` (goal-shaped, collisions named), or `retire` via `lifecycle-state` `active → deprecated → retired`. Neighbour demand and downstream cards are covariates the operator weighs |
| R6 | the router: an operator decision at D-Ratify, recorded G4, with a recommended value and an alternative, resting on its verdict and stale self-counts |
| tie | evidence below G2, or ≥ 2 failing siblings in R4a → `[ASSUMPTION – CONFIRM]` plus the alternative; the operator decides |

**Rubric (MD-G5):**
- **G1:** [SOURCE] with a CLEAN probe or verdict.
- **G2:** [SOURCE] with one or more INDETERMINATE elements, each named.
- **G3:** [INFERRED].
- **G4:** [ASSUMPTION – CONFIRM], or an operator decision.
- **The bar:** an R0 zero needs G1, or G2 with its elements named; deciding evidence needs G1 or G2. An UNEXPOSED zero enters R0 under R2.

### 4. Record outline. Slug for the scope lock: `each-never-invoked-specialist-takes-one-disposition`

**Path:** `core/ADRs/ADR-NNN-each-never-invoked-specialist-takes-one-disposition.md`. NNN comes from `renumber-adr.py --next-free` at authoring (238 today, branch-claimed by #8821), and the number binds at Stage 12. Cite it elsewhere as `{{ADR:each-never-invoked-specialist-takes-one-disposition}}`, in prose only.

**Frontmatter and section order** follow the Change 1 scaffold. `## Status` opens with the token line, and D-Ratify edits both statements (lint R7). The sections:
- `## Context`: the three signals, ending "Its current state, future state and gap map follow `## Related ADRs`."
- `## Decision`: the coding table, the disposition table, and "What this record does not do" — no `SKILL.md`, registry or router edit; a retire or re-home is a tagged follow-up through `pmo-skill-editor`.
- `## Alternatives Considered`: blanket re-trigger, blanket retire, registry annotations, a separate census record, nothing.
- `## Reversibility`: EXPENSIVE; the record changes only by supersession.
- `## Related ADRs`: ADR-019, 033, 035, 038, 114, 181, 230, 231.
- `## Current State` ("As of authoring:"): threats first, then the class-keyed results, activation, listing, collisions and the persona map.
- `## Future State`: authored archetype asks.
- `## Gap Map`: `# · Gap · Current · Future · Rows · Where closed`.
- `## References`: every number, each with a summary.

**Durability (lint):**
- every count line carries an "as of", "point-in-time" or "at authoring" anchor, or sits in a fence;
- SHAs only in `source_observations` or a fence;
- `#N` only under `## References`;
- no handle;
- no store path.

### 5. Verification bindings

| AC | Stage 8 reads → passes when | Control |
|---|---|---|
| AC-1 | `### Census method` and `### Census results` show all of:<br>• the § 2 predicates;<br>• class counters, each 0 or explained;<br>• the floor;<br>• 22 rows, each with its window, listed and no-record counts, per-channel counts, errors and `verdict`;<br>• strata, zeros included;<br>• the control ≥ 1;<br>• the nonce arm;<br>• the RTE verdict.<br>No path, id or per-session row | Stage 7 re-runs `self-test`, `mutations` and `run` at the same `--head` / `--until`. A recorded zero that turns non-zero is a defect |
| AC-2 | each row at 0 joins exactly one disposition row, carrying all § 3 columns | the same join with one row deleted gives 1 unmatched |
| AC-3 | `### Listing finding` covers:<br>• ≥ 2 UTC days;<br>• windowed tallies;<br>• no-record sessions apart;<br>• per-subject description changes, INDETERMINATE named;<br>• the mechanism, labelled;<br>• both rates | `--since 2026-10-15T23:59:59` → 0 changed; `--since 2026-08-01T00:00:00` → 7 changed and 1 INDETERMINATE |
| AC-4 | one router row, decided per R6 | — |
| AC-5 | the three H2 sections, with each gap naming its rows | — |
| AC-6 | `status: Accepted` on `main`; every non-`keep` row tagged | graded at Stage 13 |

## Stage 5 lock amendments

Transcribed from the Stage-5 Decision Recorded comment. These are zero-code: none changes the census block.

**Lock amendments.** These are zero-code: none changes the block. Each one cites its item in the round-2 review.
1. **Collisions and R4a (CD2-1).**
   - An overlap counts only where each phrase sits on a line stating that skill's *own* triggers: its `description:`, its `**Trigger:**` lines, or its mode-routing lines. A phrase found only in a comparison-table row or a deconfliction sentence does not count. Stage 6 reads this per counted row, as a G1 read.
   - Near-miss arm: the tier-1 / tier-2 comparison table must read 0.
   - R4a reads siblings that are not the subject's DEPENDS_ON targets. R4b reads every DEPENDS_ON target, of any kind.
   - The write comparator and the role source are stated. If either cannot be stated, that conjunct is G3 and the row goes to the tie.
2. **R4b, R5, the tie and the write-back (CD2-2).**
   - R4b compares the subject's `Modes:` with the modes of the skills it composes. The audience and sourcing clauses that every Specialist's template carries do not count as a role layer. A subject whose every mode is a composed mode retires.
   - **R5 becomes an operator decision at D-Ratify, recorded G4,** in the same shape as R6: a recommended value from a stated predicate (for example, `re-trigger` when the verdict is CLEAN and R2 names no exposure gap; otherwise `retire`), plus its alternative.
   - Tie precedence: a rule whose deciding read is below G2 sends the row to the tie; it never falls through to the next rule.
   - D-Ratify writes the operator's value into every G4 row. The bindings read it:
     - AC-4 at Stage 8 checks that the router row carries R6's recommended value and its alternative.
     - AC-6 at Stage 13 checks for `status: Accepted`, the hub-posted D-Ratify decision, and 0 `[ASSUMPTION – CONFIRM]` labels left in the disposition table.
     - AC-3's control values are stated as "at `29c60404`".
3. **The bar and the run steps (CD2-3).**
   - A zero whose verdict carries an `invoked_skills` residue is below the bar, and so is a zero for which every stratum of its listed classes is blind. Either goes to the tie.
   - Every remaining G2 zero carries a D-Ratify flag.
   - The CD2-3 (d) code line is NOT adopted. The record states instead that each verdict's sensitivity arms are store-wide, not windowed per subject.
   - Run steps: run with `FINOPS_SOURCE_ROOT` unset (the operator has named none) and with no `--roots`. The record reads `unclassified_skill_calls` as covering nested files only.
4. **R3 (CD2-4).**
   - R3 reads the card's persona role against the subject's role. The card's `Replacement:` line becomes a covariate on the row.
   - Keep the `Modes:` test; drop "or headings the card lacks".
   - "Covers" means the card's stage is one the subject's registry trigger surface names (a G1 read).
   - R3's else-branch does not decide: the row continues to R4a and R4b.
5. **Probe-only use (FM2-5).**
   - R0 also admits a subject whose every in-window event sits in a session whose origin is `sdk-cli`, as a `probe-only` row the operator weighs.
   - The record states two limitations: a subagent event's origin reads `absent`, and neighbour counts are store-wide.
6. **Class labels (FM2-7).** Stage 6 stops and reports if the `agent-mode` class reads 0 sessions while another non-copy app-data class holds sessions.

**Expected consequence, stated for the operator:** most disposition rows will reach R5 or the tie, so the operator decides them at D-Ratify, each with a recommended value and its alternative.

## Deviation Log

Departures from the transcribed text, all minor (formatting or recorded-resolution); none changes scope.

| ID | Where | Departure | Reason | Severity |
|---|---|---|---|---|
| DEV-1 | whole file | The transcribed comments' headings are promoted by one level outside fences, and the Stage-4 comment's own title line is dropped, so each transcribed section sits under this file's H1. No body text changed | file structure; the plan verifier locates sections by heading prefix | minor (formatting) |
| DEV-2 | § Implementation Sequence › File Change Matrix | The record row's `ADR-NNN-<record-slug>` placeholder is resolved to `core/ADRs/ADR-238-each-never-invoked-specialist-takes-one-disposition.md` (the scope-locked slug and the `--next-free` number at authoring). The `CONDITIONAL:homes-option-b` row is dropped: D-WorkProductHomes rendered (A), so the conditional resolved unfired | recorded resolutions of the Stage-4 gate and the Stage-5 lock | minor |
| DEV-3 | § Recommendations › Verification Plan | The per-issue table carries AC-5 and AC-6 and the amended AC-1 to AC-3 text (D-Amendments (A)), and the AC-3, AC-4 and AC-6 bindings of lock amendment 2; the AC baseline reads 6 | D-Amendments (A) states the rows land in the same change as the body edit; lock amendment 2 binds the AC-4 and AC-6 reads | minor |
| DEV-4 | § Recommendations | The D-IdentityMode, D-WorkProductHomes and D-Amendments recommendations are transcribed as the planner wrote them; the operator's renderings, which differ for D-IdentityMode (version-less), are in § Recorded decisions | the transcription keeps the planner's text; the decision record is the authority | minor |

## Verification Evidence

### Engineering Commit 0

Run on this file after it was written and before it was committed, on 2026-11-13 (Friday).

| Check | Command | Result |
|---|---|---|
| Version re-verify, steps 1–3 | — | N/A: version-less (D-IdentityMode) |
| Stamp manifest, step 3b | `release/tools/claim-version.sh --verify-stamp never-invoked-specialists-dispositioned` | `verify-stamp TOKEN-LESS PLAN`, exit 1 — the correct version-less outcome, not a HALT |
| CIAC authoring lint (A1, G4-06) | `release/tools/verify-release-plan.sh --ciac-lint <this file>` | `CIAC-LINT-SUMMARY declared=0 parsed=0 clean=0 declared-deferral=0 flagged=0`, exit 0 · control, same lint on the `stage-document-model-decision` plan: `declared=6 parsed=6 clean=1 declared-deferral=5 flagged=0` |
| Census block survives transcription | re-extract the python fence from this file; `sha256` | `6b43236f9fce612f96b3c29db0138b66f17bb75b8ce53733cf0bef0ac6fe7a59`, equal to the locked value |
| Survival elements 1 and 5 | count of `domain_practice` labels; count of release-version stamp tokens | 1 label; 0 tokens |

**A1 entry-contract gate: PROCEED.** The release plan, sequence, specs, matrix, strategy, risks and verification plan are present for a Solutioning-level spec (revision 2 with its lock amendments). **A2 container:** PR-body checklist — 2 planned sub-tasks (the plan, the record), doc-only, no calibration-sensitive or cross-file structural change. **A3 snapshot:** the 23 subject paths (the registry, the router and the 21 Specialist `SKILL.md` files) are unchanged since the Stage-4 baseline: `origin/main` has 0 commits after `29c60404`.

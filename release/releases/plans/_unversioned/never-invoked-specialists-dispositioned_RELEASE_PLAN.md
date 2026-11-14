---
version: never-invoked-specialists-dispositioned
date: 2026-11-13
type: plan
status: ACTIVE
issues: ["#8452"]
reversibility-tier: CHEAP
themes: ["cluster:skill-modes"]
audit_class: true
---

# Release Plan — never-invoked-specialists-dispositioned

> **Status:** Stage 6 Engineering. This file is Engineering Commit 0 on the release branch.
> **Identity: VERSION-LESS** (D-IdentityMode, operator, 2026-11-13). The release identity is the capability slug `never-invoked-specialists-dispositioned`. No version key is claimed at any stage, no release-version stamp token is authored, and the Stage-12 rename never fires. At Commit 0, steps 1–3 (version re-verify) are N/A and step 3b (`claim-version.sh --verify-stamp`) reads `TOKEN-LESS PLAN`, which is the correct version-less state and not a HALT. **Do not add the release-version stamp token to make it pass.** The plan sits under `plans/_unversioned/`, the permanent home of a version-less plan, from Stage 6 on (DEV-12).
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

**Audit class.** Declared in this file's frontmatter (the `audit_class` key). The deliverable is an analysis-class research artifact whose follow-up items are the decision record's tagged disposition rows, which release-diff folder detection cannot see, so without the declaration the Stage-13 follow-up sweep would never read them.

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

**Events emitted** (stage 4; each read back as `POST == PRE + N`):
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
  - Placement rationale: the plan is authored at `release/releases/plans/_unversioned/never-invoked-specialists-dispositioned_RELEASE_PLAN.md` and ends in `plans/v5/` or `plans/_unversioned/`, per D-IdentityMode.
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
release/releases/plans/_unversioned/never-invoked-specialists-dispositioned_RELEASE_PLAN.md  ADD
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
| #8452 (Commit 0) | `release/releases/plans/_unversioned/never-invoked-specialists-dispositioned_RELEASE_PLAN.md` | no | no (conjunct 1 decides) | unconstrained | unconstrained | ordinary Engineering spoke |
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
- [ ] **Scope:** no `SKILL.md`, registry or router changes. *Method:* `git diff --name-only origin/main...HEAD -- '*/skills/*/SKILL.md' core/skills/registry.md` expect 0 · control, same instrument: `git diff --name-only origin/main...HEAD -- release/releases/plans/_unversioned/never-invoked-specialists-dispositioned_RELEASE_PLAN.md` expect 1. Graded at Stage-6 C4 and at Stage 9.
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

Transcribed from revision 2 of the Stage-5 output. The census procedure itself is not repeated: § 2 points to the record's copy of the locked block (sha256 `6b43236f9fce612f96b3c29db0138b66f17bb75b8ce53733cf0bef0ac6fe7a59`). Read it together with § Stage 5 lock amendments, which win where they disagree.

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

> **The census procedure is not copied here.** The decision record `core/ADRs/ADR-238-each-never-invoked-specialist-takes-one-disposition.md` carries the locked block byte for byte, in its `### Census method` section (sha256 `6b43236f9fce612f96b3c29db0138b66f17bb75b8ce53733cf0bef0ac6fe7a59`). Extract and hash that copy before running it.

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

**Path:** `core/ADRs/ADR-NNN-each-never-invoked-specialist-takes-one-disposition.md`. NNN comes from `renumber-adr.py --next-free` at authoring (238 today, branch-claimed by #8821), and the number binds at Stage 12. Cite it elsewhere as `ADR-238`, in prose only.

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
| DEV-5 | frontmatter | Commit 0 carried an `audit_class: false` key that no input declared; the record commit removes it, returning the file to the Stage-4 state (no declaration). The key is the fallback declaration for an audit whose analysis folder detection cannot see; whether Stage 13's filing step should read the record's follow-up tags through it is the hub's call | an unsourced addition, corrected | minor |
| DEV-6 | this file and the record | Each carried the repo-integrity dead-file-ref override comment. The locked census block holds a self-test line that builds a registry row with the link-syntax literal `(x)`, and the dead-file-reference checker scans fenced code for links, so it reads that literal as a dead link in both files. The block cannot change; the marker is the gate's documented override. Neither file carries any other markdown link | a byte-locked block; the checker's fence handling differs from the doc-link standard's statement (§ Verification Evidence) | minor |
| DEV-7 | the census run steps | The referencing-site pre-count ran as one `git grep -l -wF <name> <head> -- .` call per table row (14) plus an absent-name control, aggregated into the same four classes, instead of the run steps' loop over all 22 subjects. The worktree isolation guard refused the loop form | a control refused the action's form; the predicate and classes are unchanged | minor |
| DEV-8 | the census run steps | One extra `run` of the locked block, at the same `--head` and nonce with `--until 2026-06-21T03:43:04` (one second before the earliest registration), sources the record's R2 reading: it reads the same `agent-mode` session count as the full run | the R2 reading decides every recommended value, so it is sourced rather than inferred | minor |
| DEV-9 | the census run steps | Check 67's harness ran with its `--skills` roster text-extracted from the four `deploy.sh` skill arrays (no execution of `deploy.sh`), with `--output-json` into the run directory | the harness needs the roster the deploy check passes | minor |
| DEV-10 | the record, § Decision › Readings and the tie rows | A third commit corrects the tie's stated basis. The first record commit said both of R4a's write and role conjuncts were G3 against every used sibling; the write read rested on two sampled Output Contracts, and the role read holds against every used sibling for 7 of the 10 rows only. The tie now rests on the probe-backed role read: two used siblings, the OCM lead and the principal engineer, state no tier. No row's rule, value or alternative changes | a claim stated more broadly than its probe, corrected before Stage 7 | minor |
| DEV-11 | the record, § Current State › Listing finding | The specification asks that render forms be compared only after a description change inside a window; the locked procedure has no split, so the record names the 7 changed descriptions (3 of them rows) and states that their tallies span the change | the procedure is byte-locked | minor |
| DEV-12 | the file's path | Moved from the plans root to `release/releases/plans/_unversioned/`, and the file's four citations of its own path repointed, including the transcribed Stage-4 placement rationale and the Release-Level Verification control; the Header line on where the plan moves now reads that it sits there from Stage 6 | hub call, Stage-6 correction round 1: `RELEASE_PROTOCOL.md` keeps a version-less plan slug-keyed permanently under `_unversioned/` | minor |
| DEV-13 | § Stage 5 › 2. Census method; the file head | The plan's copy of the census block is replaced by a pointer to the record's copy (its `### Census method` section, sha256 `6b43236f9fce612f96b3c29db0138b66f17bb75b8ce53733cf0bef0ac6fe7a59`), and the plan's `allow-dead-file-ref` override and its explanation are removed, because the plan no longer carries the fenced `(x)` literal. The record keeps its own override. The Commit-0 and Stage-6 evidence rows above that hash or link-check the plan's copy record the state at those commits | hub call, Stage-6 correction round 1: a second copy of the block in `release/` is a duplicate source, and it was what read red in the advisory link check | minor |
| DEV-14 | frontmatter; § Header › Audit class | `audit_class: true` declared, with its rationale, in the form of the version-less design-record precedent. This settles DEV-5's open call | hub call, Stage-6 correction round 1: the follow-up items live in the record's disposition rows, which folder detection cannot see | minor |
| DEV-15 | § Deviation Log, DEV-6 | DEV-6 quoted the override comment in full, and the dead-file gate matches that comment as a substring anywhere in a file, so the quotation alone still exempted this plan. DEV-6 now names the override in words. This plan carries no override marker, not even quoted, and stays inside the dead-file gate; the record keeps its real marker | hub finding, Stage-6 follow-up: restore the gate's coverage of the plan | minor |
| DEV-16 | the record, § Decision › Readings and the tie rows; § Change Description | DT iteration 1 (Stage 7 F-01 to F-04, F-06, F-08, F-10), re-derived from source at the census head with no census re-run. The role probe states its forms and arms and reads 12 of 21 sources; the tie rests on the OCM lead alone. Every tie row records its three R4a conjuncts with grades. First-rule-wins gives `re-home` at R4a on the project-manager and devops rows. R4b is read from source under one stated criterion and its alternative, and retires no row. The R5 predicate's one-value-per-reading property is stated. The split on the handed rows moves from 8 re-trigger · 3 retire to 9 re-trigger · 2 re-home · 0 retire. Gap Map G8, the counts paragraph and two R3 covariates are corrected | hub routing, DT iteration 1 (Tier 1, fixable within scope): the locked rules applied as written; every affected row stays a G4 row for D-Ratify | minor |
| DEV-17 | the record: § Status, § Decision (the coding scheme's R5 and R6, § Readings, the disposition table, what the record does not do), § Consequences, Gap Map G1, G3 and G6; § Change Description | R5's one-value predicate is replaced by a per-row test: demand read from the composed skills each row uses for its own work (G2, store-wide; zeros not read), plus a served-elsewhere read of the persona cards and governed surfaces (G1); its direction is demand, with substitution as the alternative; a sensitivity arm shows both values. Seven rows are decided `re-trigger` by it, two tie (the first-line support and WMS Specialists), and none retires. The project-manager and devops rows are re-triggered as operator decisions, with the colliding phrase pair named; both seams are ratified, the QA lead's across both QA Lead cards; every re-trigger carries the exit test; one consolidated dispositions card replaces "in its own card". F-11, F-12 (0 of 32 and 5 of 32 composed modes; the project tier read by its noun), QA-02, QA-04, QA-05 and QA-08 are folded in. The record stays Proposed | operator redirect at the Stage-9 gate | scope change (Tier 2, operator-rendered) |
| DEV-18 | the record: frontmatter `status:` and § Status; the coding scheme's R4a, R5, R6 and tie rows; § Readings (R5); the disposition table; the counts; Future State; Gap Map G1 and G5; § Change Description | The record is ratified: `status: Accepted`. The per-row test states the operator's two readings. The role is held elsewhere only when another skill holds the Specialist's role, and persona-card Replacement lines read the same way for R3 and R5. The direction is read per row by exposure, with a 10% threshold on the printed listing tallies. The scrum master is retired by the test. The router is retired by the operator (its role is held by `ppm-agent`, `core/governance/OPERATIONS.md:34`). The WMS Specialist is re-triggered on its in-scope intake demand, and the first-line support Specialist by the operator. 0 assumption labels remain in the table. Both retire rows run through `lifecycle-state` and carry no exit test, and all 11 re-trigger rows carry it. F-17 to F-20 are applied | operator D-Ratify row amendments | minor (Tier 1, operator-rendered) |

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

### Stage 6 — the census and the record (C4 self-verification)

Run on 2026-11-13 (Friday) with the record and this file staged. The census ran read-only on the operator's local transcript stores; only its printed aggregates are carried, in the record.

| Check | Command | Result |
|---|---|---|
| Census block before running | `shasum -a 256` of the block extracted from the locked comment | `6b43236f9fce612f96b3c29db0138b66f17bb75b8ce53733cf0bef0ac6fe7a59`, equal to the lock |
| Instrument | `census.py self-test`; `census.py mutations` | 16 PASS; 26 caught, control ok, 0 MISSED |
| Census | `census.py run --head 29c604045def22ebd21fb4a758c3bb56be277b20 --until 2026-11-13T21:42:22 --nonce <printed>` | 22 subjects; 13 Specialists and the router at total 0; control `release-hub` 434; nonce arm 1 file, 0 subject events; amendment-6 stop not triggered (`agent-mode` 209 sessions) |
| AC-3 control | the same run with `--since 2026-10-15T23:59:59` | 0 changed, 0 INDETERMINATE |
| R2 source (DEV-8) | the same block with `--until 2026-06-21T03:43:04` | `agent-mode` 209 sessions, equal to the full run |
| Activation · collisions · Check 67 | `census.py activation`; `census.py collisions --head <head>`; `run_eval_audit.py --composition-aware --output-json` | RTE `DORMANT`; 51 rows; 56 skills, 1540 pairs, 0 ESCALATE, 0 WATCH |
| Record durability | `python3 release/tools/check-adr-durability.py --files <record> --diff-base origin/main` | `COUNT 0` · control: a copy with one unanchored count line → `R2-COUNT`, `COUNT 1` |
| ADR numbering | `python3 release/tools/renumber-adr.py --detect` | anchor 237, next-free 238; `CLAIM ADR-238 … BINDS BRANCH-CLAIM`; 238 is also claimed on a sibling branch, so Stage 12 Phase A.5.7 rebinds it if the sibling merges first |
| Egress | `bash core/deploy/tools/path-leak-patterns.sh --scan-file` on the record and this file | exit 0 on both · control: a planted absolute home path → exit 1 |
| App-data directory names | a count of the class map's per-account directory names in the record and this file | 0 and 0 · control: one name planted → 1 |
| Link gates | `check-release-links.py --roots core release --check-anchors --images --files <record> <this file>`; `check-doc-links.py --target-paths <record> --require-targets` | release-links: 2 findings, both the census block's fenced `(x)` literal, and both files carry the gate's `allow-dead-file-ref` override (DEV-6); doc-links: exit 0, no finding |
| Skill-package freshness | `git diff --name-only origin/main...HEAD \| bash core/deploy/tools/build-skill-packages.sh --skills-for-paths` (stdin; first run on the staged set as `git diff --cached --name-only origin/main`) | names no skill · control: a Specialist `SKILL.md` path → names that skill |
| Scope | `git diff --name-only origin/main...HEAD -- '*/skills/*/SKILL.md' core/skills/registry.md core/skills/pmo-skill-router` | 0 · control, `git diff --name-only origin/main...HEAD -- <this file>` → 1; `git diff --name-only origin/main...HEAD` lists only this file and the record |
| CI on the draft PR | `gh pr checks` | the required Dead-file-reference gate passes (the override, DEV-6); the reference-durability, ADR durability, ADR-number, issue-reference and commit-message gates pass; the advisory `Verify intra-repo links in release/` check reads red on this file's fenced `(x)` literal, because that workflow has no per-file override (DEV-6) |
| ADR index | — | `ADR index: N/A — this release adds no record under release/ADRs/` |
| Runtime suite | `append-pipeline-event.sh … --event-type test-run --event-subtype suite-skip …` | appended; read back: this release's `test-run` rows 0 → 1 |

**C3 (deployed-copy sync):** N/A — the release ships no skill, rule mirror or harness artifact. **Deliverable state:** both deliverables — this plan and the record — declare `deliverable_state: artifact-accepted`; each exists at its declared canonical path on the release branch, and its Artifact-Acceptance Record row is populated at Stage 13 Phase A7.5.

## Change Description

### Outcome

The platform now has one tracked decision record that says, for every role Specialist operators never invoke and for the router, what each is for. The record re-runs the invocation census with a stated method, per-subject exposure windows and both control arms; it reads the rendered skill listing across 153 UTC days; and it gives each of 14 subjects one disposition row. The record is `Accepted`, ratified by the operator at the Stage-9 D-Ratify gate on 2026-11-14.

### Issues resolved

- #8452 — the census, the disposition table, the listing finding, and the current state, future state and gap map, in `core/ADRs/ADR-238-each-never-invoked-specialist-takes-one-disposition.md`. It is marked closed at Stage 13, once the ratification is recorded.

### Key decisions

- **Ten rows are decided by the scheme.** The release train engineer is kept dormant by design, conditioned on the operator's answer that no SAFe configuration exists today. The software engineer and the QA lead are re-triggered through their persona cards; the operator ratified both seams at the Stage-9 gate, and the QA lead's covers both QA Lead cards. The per-row test that replaced R5 — read, as the operator ratified, with the role held elsewhere and with the direction set per row by exposure — re-triggers six more on their own demand evidence (the business analyst, the portfolio manager, the program coordinator, the escalation support Specialist, the WMS Specialist and the data engineer) and retires the scrum master, whose description was shown in about a fifth of its listings and still not chosen.
- **Four rows are the operator's own decisions, all ratified.** At the Stage-9 gate the project manager and the devops Specialist were re-triggered, not re-homed, each follow-up narrowing its colliding phrase against the release manager. At the D-Ratify gate the first-line support Specialist was re-triggered, as the cheaper value to reverse, and the router was retired, because its role is held elsewhere: `core/governance/OPERATIONS.md` gives strategic routing to `ppm-agent`.
- **The split:** 1 keep, 11 re-trigger, 2 retire, 0 re-home; no row is handed back. Every re-trigger carries the operator's exit test: the follow-up first gets the description in front of the operator, and a row still at 0 at the sunset re-run converts to retire. Both retires run through `lifecycle-state`, never deletion. The record is Accepted, ratified at the D-Ratify gate on 2026-11-14.
- **The listing finding conditions every re-trigger:** a skill not used recently renders its description in a minority of listings, so a description edit alone may not reach an operator.

### Reversibility

CHEAP before the merge: abandon the branch, or edit the record while it is `Proposed`. After the merge the record changes only by supersession (EXPENSIVE once ratified, because the dispositions bind follow-up cards). No tag is claimed; a revert of the release PR removes the record.

### Downstream impact

No skill, registry row or router changes in this release. Each non-keep row carries a `follow-up:` tag, and one consolidated dispositions card, filed at Stage 13 with a ` · feature` tag, carries all of them. The next slice of the parent epic waits on this table, because it may move one of its cards' host.

### Cross-references

- The decision record: `core/ADRs/ADR-238-each-never-invoked-specialist-takes-one-disposition.md`.
- The locked specification and its amendments: § Stage 5 and § Stage 5 lock amendments of this file.
- The operator's gates: § Recorded decisions.

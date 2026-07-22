---
title: Release Plan — governance-ci-checks (governance self-validates)
type: release-plan
plan_type: release
status: ACTIVE
release: version-less (theme-named; no tag claimed)
milestone: 266-governance-ci-checks
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `governance-ci-checks`

**Milestone:** `governance-ci-checks` (#266) · hub sub-task #3622 = Stage 4 plan source · #3652 = Stage 5 Solutioning source
**Version identity:** **version-less / theme-named** — D-Version condition **(B)** per the D-Gate Template (milestone title is slug-only). **No tag is claimed at Stage 12**; the Engineering-Commit-0 version re-verify and the Stage-12 atomic version claim are **inapplicable** (there is no version slot to contend for).
**Topology:** D-C SINGLE — one release branch (`release/governance-ci-checks`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (operator-ratified) — Stage 6 slices route one at a time in dep order on the single branch.
**Release class:** `cross-cutting` (operator-decided 2026-07-19).

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #3622, reconciled to the approved **Stage-5 Solutioning** designs and the **Collective Review scope-lock dispositions** posted on #3652 (decisions D-A / D-B / D-C). Where a scope-lock disposition superseded a Stage-4 assumption, the transcribed sections preserve the Stage-4 plan of record and the **§ Deviation Log** records the ratified delta. Authored at Engineering Commit 0 by the Wave-A Engineering spoke (#3655).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less (theme-named; no tag) |
| **Date Created** | 2026-07-19 (Sunday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/governance-ci-checks` |
| **PR** | (populated at PR creation, Stage 6) |
| **Milestone** | `governance-ci-checks` (#266) |

---

## Scope

### Summary

Six members, all OPEN/bundled. Raw Σ = 22 pts; effective_pts ≈ **26** (cross-cutting-weighted) — marginally over the 15–25 band; the **G3-15 ship-as-one override carries** (operator stance 2026-07-19; trend 34 → 29 → 26 after #1490's relocation). Build posture: **single branch, P0 fully-serial** (contention-justified; one PR / one merge per "milestone = one PR").

The release's capability outcome: **governance self-validates** — every structural invariant the corpus asserts in prose gains a machine gate that fails when the prose and the live state diverge.

### Members

| # | Issue | Size | Surface |
|---|-------|------|---------|
| 1 | **#1039** work-hierarchy drift gate | M(4) | `core/deploy/deploy.sh` |
| 2 | **#2219** milestone↔epic membership check | S(2) | `core/deploy/deploy.sh` (D-A) |
| 3 | **#2682** status-label integrity | S(2) | `core/deploy/deploy.sh` + `core/specs/label-taxonomy.md` |
| 4 | **#2106** extraction-contract validity check | S(2) | `core/deploy/deploy.sh` |
| 5 | **#2685** residual dead-ref coverage | S(2) | `.github/workflows/link-check.yml`, `release/tools/check-release-links.py` |
| 6 | **#3009** ADR flip audit + close-out verification | L(8) | `gate-criteria-spec.md`, `release-process.md`, `deploy.sh`, ADR corpus |

**Relocated out of scope:** **#1490** (ADR durability lint) moved to `adr-corpus-conformance` (#286) at Stage-4 plan review, co-located with its #1488 prerequisite. Membership 7 → 6.

### Wave Structure (Stage 6 Engineering)

| Wave | Members | Rationale |
|------|---------|-----------|
| **A** | #1039 → #2219 → #2682 → #2106 | The `deploy.sh` cluster. Serial; #2682 is the sole in-place modifier and is kept a single focused commit. |
| **B** | #2685 | Independent surface (`link-check.yml` + `check-release-links.py`); no contention with Wave A. |
| **C** | #3009 | ADR corpus data flips + G-CL9 + Stage-13 narrative. Mechanism commits kept separate from data-flip commits (R5). |

---

## Dependency Graph

Directional edges (`A ──▶ B` = B depends on A). External nodes in brackets.

```
[#563 CLOSED]  ──MET──▶  #1039        (SSOT/T2 baseline — satisfied)
[#2095 CLOSED] ──MET──▶  #2106        (enumeration baseline — satisfied; premise re-scoped, see D-C)
#1039 ──adjacent-invariant (same drift class; soft)──▶ #2219
[#1488 OPEN, ms#286 adr-corpus-conformance] ──edit-order coord (ADR files; soft)──▶ #3009
```

- **No HARD intra-milestone blockers.** The only former HARD edge (`#1488 → #1490`) left the milestone with #1490.
- **Soft/coordination edges:** ADR-file edit ordering (#3009 ↔ #1488); drift-class adjacency (#1039 ↔ #2219).

---

## Implementation Sequence

Single branch, serial:

| # | Issue | Why here |
|---|-------|----------|
| 1 | **#1039** | Foundational `deploy.sh` gate; dep #563 MET. First `deploy.sh` editor. |
| 2 | **#2219** | Adjacent drift-class invariant to #1039. Placement resolved at Stage 5 → `deploy.sh` (D-A). |
| 3 | **#2682** | The sole **in-place** `deploy.sh` modifier (Check 16 edit). Kept a single focused commit so it is independently revertible. |
| 4 | **#2106** | Must land **after** #1039/#2682 so its own extraction-contract assertion sees their new checks (CIAC-2). |
| 5 | **#2685** | Independent surface; no contention with 1–4. |
| 6 | **#3009** | **LAST.** Edits ADR *content* (~25 flips) + `release-process.md` + `gate-criteria-spec.md` + a `deploy.sh` backstop check. Coordinates cross-milestone with #1488. |

Rationale for serial: the `deploy.sh` cluster (steps 1–4, +6's backstop) all edit one file; the ADR corpus (step 6) collides cross-milestone. Serial build eliminates same-file parallel-commit hazards and honors the P0-default posture.

---

## Stage Applicability Matrix

Default = all apply. **No stage skips for any member** — every member is a governance-as-code gate with fixture/negative-test AC (functional impact → Stages 7–8 apply).

| Issue | S5 | S6 | S7 | S8 | S9–S13 |
|-------|----|----|----|----|--------|
| #1039 | ✅ | ✅ | ✅ | ✅ | ✅ |
| #2219 | ✅ | ✅ | ✅ | ✅ | ✅ |
| #2682 | ✅ | ✅ | ✅ | ✅ | ✅ |
| #2106 | ✅ | ✅ | ✅ | ✅ | ✅ |
| #2685 | ✅ | ✅ | ✅ | ✅ | ✅ |
| #3009 | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## Contention Map

| Shared surface | Issues | Level | Note |
|----------------|--------|-------|------|
| `core/deploy/deploy.sh` | #1039, #2219, #2682, #2106, #3009 | **HIGH** (5) | Serialize on one branch. Four are **append-only** (ADR-005 append-pattern → structurally HIGH / operationally LOW); **#2682 alone is in-place** and is the real merge hazard. |
| `core/ADRs/*.md` + `release/ADRs/*.md` (content) | #3009 (~25 flips) + **#1488-ext** | **MEDIUM (cross-milestone)** | Edit-order collision **CONFIRMED** (the flip promise lives in the `status:` frontmatter line and the Status body section). Mitigated by M1 + M2 below. |
| `.github/workflows/link-check.yml` | #2685 | none | Sole editor. |
| `release/tools/check-release-links.py` | #2685 | none | Sole editor. |
| `core/specs/label-taxonomy.md` | #2682 | none | Sole editor. |
| `release/governance/release-process.md`, `core/schemas/gate-criteria-spec.md` | #3009 | none | Sole editor. |

---

## Risk Register

| ID | Class | Sev | Risk | Owner | Mitigation | Reversibility |
|----|-------|-----|------|-------|------------|---------------|
| **R2** | Contention | MEDIUM | `deploy.sh` edited by 5 issues on one branch. | eng | Serial build in stated sequence; append-pattern checks; **#2682 isolated to one commit**; single PR/merge. | CHEAP |
| **R3** | Contention | MEDIUM | ADR content (#3009 flips) ↔ #1488 conformance sweep collide cross-milestone. **Overlap confirmed at Stage 5** — the naive "different lines merge cleanly" claim does **not** hold. | operator/eng | **Order inverted at Stage 5** (see § Cross-Milestone Coordination): #3009 proceeds now with **M1** (surgical status+provenance-only edits, no structural reflow) + **M2** (coordination note on #1488). | MODERATE |
| **R4** | Scope | MEDIUM | effective_pts ≈ 26, marginally over band. | operator | G3-15 override recorded (ship-as-one). Cross-cutting posture: deeper Stage-9 review, full DT/QA per issue. | CHEAP pre-Eng / MODERATE after |
| **R5** | Rollback | LOW–MED | Gates are additive warn-mode → `git revert`-clean. **Exception:** #3009's ~25 ADR status flips are DATA changes to governance files. | eng | Separate the gate-mechanism commits from the data-flip commits so the gate reverts without unwinding the audit. | mechanisms CHEAP / flips MODERATE |
| **R7** | Audit-baseline | LOW | #3009 Proposed set grew 21→25 since filing. | eng | Pin baseline `f935185`; **re-derive** the Proposed set at audit time. | CHEAP |
| **R8** | Zero-population | MEDIUM | #2682's orphaned-bundle population is **0** live; #1039's epic-under-epic population is drained (#563 closed). Efficacy is **not** provable from live state. | eng | **Seed/synthetic fixtures are mandatory, not optional** (audit-baseline discipline) for #2682, #2219, #2106, #1039 Leg B. | CHEAP |
| **R9** | False-FAIL | **HIGH** | Widening Check 16's scope without the `type:epic` exemption immediately false-FAILs on **38 statusless epics**. | eng | The I2 epic exemption is **load-bearing** and lands **with or before** the scope widening, in the same commit as the `label-taxonomy.md` wording. | CHEAP |

---

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (all 6 members, on each gate's mode flag):** every net-new gate lands **warn-mode-initial** (no hard-fail on first PR), per `core/rules/bypass-mode-readiness.md § Shakedown → Enforce Transition Checklist`. *Method:* `grep` each new/widened check for its warn-mode default + absence of first-land hard-fail; confirm no gate ships enforce-first. *Graded at Stage 9 QC3.5.*
- [ ] **CIAC-2 (#1039 × #2219 × #2682 × #2106 on the `deploy.sh` roster):** after all `deploy.sh`-editing issues land, `deploy.sh --check` runs clean/warn-green on the reconciled branch **and #2106's own extraction-contract check passes** — i.e., every check this release adds emits both a `# Check N` definition block and a matching `log "Check N: …"` line. **Self-referential in the good way:** the release's own new checks are the first test data for the check that guards extraction. *Graded at Stage 9 QC3.5.*
- [ ] **CIAC-3 (#3009):** post-audit, `grep -lE '^status:[[:space:]]*Proposed' core/ADRs/*.md release/ADRs/*.md` returns only **correctly-pending** ADRs. *(The #1490 durability-lint half of the original CIAC-3 moved to #286 with #1490.)* *Graded at Stage 9 QC3.5.*

---

## File-Change Matrix

Intent tokens: `ADD` (new file) · `EDIT` (modify) · `DATA` (content edit to governed files).

```
EDIT  core/deploy/deploy.sh                                   # #1039 (Check 55 drift gate); #2219 (Check 56 membership); #2682 (Check 16 in-place widen); #2106 (Check 57 extraction contract); #3009 (backstop check)
ADD   core/deploy/tools/check-work-hierarchy.py               # #1039 (H1 doc + H2 batched-GraphQL backlog primitive; carries --self-test)
ADD   core/deploy/tools/check-milestone-epic-membership.py    # #2219 (membership + description-reconciliation primitive; carries --self-test)
ADD   core/deploy/tools/check-extraction-contract.py          # #2106 (deploy.sh-internal extraction-contract primitive; carries --self-test)
(none) .claude/work-hierarchy-exemption-list.txt              # #1039 — see Δ10: operator-instance state, NOT tracked (Check-16 precedent)
EDIT  core/specs/label-taxonomy.md                            # #2682 (per-type status applicability table + epic exemption; Rule 6 restatement)
ADD   core/deploy/tools/tests/test-status-label-invariant.sh  # #2682 (mandatory seed fixture — proves widened I1–I4 fire; live orphaned-bundle pop = 0)
EDIT  release/references/specs/ticket-information-architecture.md  # #2682 (Δ12 — reconcile Check-16 invariant table: all-intake scope + I2 epic/sub-task exemption + decoupled mode)
EDIT  .github/workflows/link-check.yml                        # #2685 (extend --target-paths; warn-mode)
EDIT  release/tools/check-release-links.py                    # #2685 (reconcile is_skippable for 3 filename shapes)
EDIT  release/governance/release-process.md                   # #3009 (Stage 13 close ADR-flip verification step)
EDIT  core/schemas/gate-criteria-spec.md                      # #3009 (G-CL9 + schema v2.1→v2.2 + cutover/reflexive exemption)
DATA  core/ADRs/*.md                                          # #3009 (one-time audit; ~25 Proposed live; each governed per-ADR; status+provenance ONLY)
DATA  release/ADRs/*.md                                       # #3009 (same one-time audit across release ADRs)
ADD   release/releases/plans/governance-ci-checks_RELEASE_PLAN.md  # this plan (version-less/theme-named slug — D-Version condition B)
```

**Explicitly NOT edited:** `core/rules/skill-deployment.md` — per **D-C**, #2106 adds **no doc-side marker**; commit `f0a0516` deliberately removed the enumeration in favour of a derive-from-source pointer, and re-adding a marker would re-create the duplicate surface that removal eliminated.

---

## Check-Number Allocation

`deploy.sh` defines Checks **1–54**; **15 and 24 are RETIRED with their numbers reserved** (never reused). Next free = **55**.

| Check | Member | Mode file |
|-------|--------|-----------|
| **55** | #1039 work-hierarchy drift | `work-hierarchy-drift.mode` |
| **56** | #2219 milestone↔epic membership | `milestone-epic-membership.mode` |
| **57** | #2106 extraction-contract validity | `check-extraction-contract.mode` |
| *(none)* | #2682 — **in-place Check 16 edit**, no new number | `status-label-invariant.mode` (decoupled) |
| **58** | #3009 ADR flip backstop (Wave C) | `adr-flip-verify.mode` |

Allocation is made **at implementation time**, not inherited from the Stage-5 provisional numbers — the corpus records two prior Stage-5→6/9 renumbers. Wave A's allocation (55/56/57) reconciled to and **matches** the Stage-5 provisional.

---

## Operator Decisions (recorded)

### D-ReleaseClass — SETTLED
- **Value:** **cross-cutting** (operator-decided 2026-07-19). effective_pts ≈ 26. Differentiation posture: deep Stage-9 Collective Review, full DT/QA per issue, cross-issue-coherence emphasis (CIAC-1/2/3).
- **Reversibility / Confidence:** CHEAP / HIGH.

### D-Version — RECORDED DETERMINATION (rule-determined; not an operator gate)
- **Determination:** **version-less / theme-named**, condition **(B)** — milestone title is slug-only; **no tag claimed at Stage 12**. Bump-class / next-free: N/A.
- **Reversibility / Confidence:** CHEAP / HIGH.

### D-Concurrency Posture
- **P0 fully-serial** (operator-ratified).

### D-A · #2219 placement — **`deploy.sh --check`**
Sibling to Check 16's `gh issue list` + jq invariant pattern. `repo-integrity.yml` rejected as **altitude mismatch** (milestone↔epic membership is repo-state, not a PR-diff property → every PR would pay a full backlog scan for unrelated drift); the #228 convention linter rejected as **file-oriented** (it lints files, not live-backlog edges). · **CHEAP / HIGH.**

### D-B · #3009 mechanism — **Both**
A **G-CL9** close-gate criterion as the **authority**, plus a `deploy.sh` advisory backstop that is **never enforce-capable** (free-text ratifying references are not reliably mechanizable). Mirrors the live G-CL8 + Check-28 pairing. · **CHEAP (mechanisms) / MODERATE (data flips) · HIGH.**

### D-C · #2106 disposition — **Re-scope to extraction-contract validity**
The original premise is **dead**: `f0a0516` resolved #2095 by *converting the enumeration to a derive-from-source pointer* (removed, not cleaned). The re-scoped check asserts the contract **entirely inside `deploy.sh`** (`log "Check N:"` emitters ↔ `# Check N` definition blocks) with **no doc-side marker**. · **CHEAP / MEDIUM-HIGH.**

---

## Cross-Milestone Coordination — #3009 ↔ #1488

**Recorded Stage-4 position:** sequence #1488's structural sweep FIRST, then #3009's flips on the conformed corpus.

**Stage-5 finding:** #1488 is the sole member of `adr-corpus-conformance` (#286), **OPEN and not started**. Strict adherence blocks #266's final sequence step on an unstarted milestone — indefinitely. The edits are **overlapping, not disjoint**: the flip promise lives in the `status:` frontmatter line itself *and* in the Status body section.

**Ratified position: invert the recorded order — #3009 proceeds now; #266 is not blocked on #286.**

1. The blocking cost is **unbounded** (#286 not started); the collision cost is bounded and mechanical.
2. **Asymmetry of rework:** #3009's expensive part is the *classification judgment* (free-text ratifying-review → milestone → closed?), which is **invariant to ADR structure**. #1488's sweep is mechanical and cheap to rebase. Put the cheap-to-rebase work last.
3. Collision is contained by the surgical constraint.

**Required mitigations (both must land):**
- **M1:** #3009's flips are **surgical** — status field + provenance only. No section reordering, no header rewrites, no reflow.
- **M2:** post-audit, record the flipped ADR set as a **coordination note on #1488** so #286's sweep does not "restore" a stale `Proposed` during normalization.

**Reversibility MODERATE · Confidence MEDIUM-HIGH.**

---

## Deviation Log

Deltas between the Stage-4 plan of record and the ratified Stage-5 scope-lock. All are **refinements or reductions**; none re-opens the bundle.

| # | Stage-4 record | Ratified delta | Basis |
|---|----------------|----------------|-------|
| **Δ1** | #1490 in scope (7 members, Σ 26, effective 34) | **#1490 relocated to #286**; 6 members, Σ 22, effective ≈ 26 | Stage-4 plan review (operator, 2026-07-19) |
| **Δ2** | #2682 = "orphaned-bundle detector + half-labeled detector + doc edit" (M) | **Detector already exists** — Check 16 invariant **I4** (`deploy.sh:3499-3513`). Collapses to **one fetch-scope widen + I2 epic exemption + doc edit**. Re-sized **M → S** | Stage-5 grounding vs live `main` |
| **Δ3** | #2106 = "parity check + machine-extractable marker in `skill-deployment.md`" | **Premise dead** (`f0a0516` removed the enumeration). Re-scoped to **extraction-contract validity inside `deploy.sh`**; **no doc edit** | D-C |
| **Δ4** | #2219 placement TBD (3 candidates) | **`deploy.sh --check`** | D-A |
| **Δ5** | #3009 mechanism TBD | **Both** — G-CL9 authority + never-enforce-capable backstop | D-B |
| **Δ6** | #2685 also edits `repo-integrity.yml` | **Corrected** — #2685 edits `link-check.yml` + `check-release-links.py` only | Stage-4 divergence 1 |
| **Δ7** | #3009 audit = "21 of ~66" ADRs | **25 Proposed of 85** (17 core + 8 release); re-derive at audit time | Stage-5 census |
| **Δ8** | Sequence #1488 sweep FIRST, then #3009 | **Inverted** — #3009 proceeds now with M1 + M2 | Stage-5 § Cross-Milestone Coordination |
| **Δ9** | Populations per issue bodies (22 orphaned bundles, 56 statusless epics) | **Drained:** orphaned bundles **0**; statusless epics **38 of 39**. Fixtures become mandatory; epic exemption becomes load-bearing | Stage-5 live re-derivation |
| **Δ10** | `ADD .claude/work-hierarchy-exemption-list.txt` (#1039, "may ship empty") | **Not created / not tracked.** `.claude/` exemption lists are **operator-instance runtime state** — Check 16's own `.claude/status-label-invariant-exemption-list.txt` is likewise untracked, and `.gitignore` treats `.claude/hooks/.mode` + siblings the same way. Both the primitive and the deploy.sh block degrade correctly on an absent file (verified). Shipping a tracked empty file would invert the established precedent | Stage-6 grounding vs `git ls-files` + `.gitignore` |
| **Δ11** | #1039 H1 predicate = "flag any token **outside the licensed kind vocabulary** in parent position" | **Narrowed to the ADR-049 closed banned-tier set** `{Initiative, Roadmap}`, case-sensitive. The broad form was implemented first and measured: **8 findings, 8 false positives** (the KM altitude ladder `Unit → Task`, the SAFe row of the Layer-2 methodology map `Feature → Story`, ADR-018's `Issue → Story` projection, and ADR-049's own lowercase `initiative→epic` **label-mapping** title). Flagging the SSOT map for containing methodology tier names is incoherent; the narrowed form is the exact class #1039 names and returns **0** on reconciled `main` | Stage-6 self-verification against live corpus |
| **Δ12** | #2682 file-change matrix = `deploy.sh` + `label-taxonomy.md` only | **Added `release/references/specs/ticket-information-architecture.md`** to the #2682 edit set. Widening Check 16 rendered its §Invariant-Enforcement table factually false (it asserted "4 atomic invariants on open `improvement` issues", a stale I2 rule with no exemption, and the pre-decouple mode file). This is the **identical self-contradicting-doc defect** the Stage-5 spec flagged for `label-taxonomy.md` Rule 6, in a second file the spec's grep missed — reconciled surgically per reconcile-dont-annotate. The v1.22 release-log / plan / notes hits are **frozen historical records** (terminal, describe the state at v1.22) and were correctly **left untouched** | Stage-6 corpus-wide grep for stale Check-16-scope claims |
| **Δ13** | #2682 warn-mode = "decouple to `status-label-invariant.mode`" (Stage-5 recommendation) | **Implemented the full decouple.** Check 16 previously read the shared `$DEPLOY_CHECK_MODE` via `flag_warn_or_issue`; it now resolves `resolve_check_mode "status-label-invariant"` and emits via a local `flag_status_label` (the Check-22 `flag_g1_enforcement` precedent), so the widened net cannot be enforce-flipped by an unrelated shared-cohort change. Absent a dedicated `.mode` file it falls back to the shared mode (byte-identical prior behavior). The stale `c14_`/`C14_` variable prefix inside Check 16 was **flagged, not renamed** — a rename is a reference-cascade better kept out of the sole in-place-modifier commit | Stage-6 implementation |

---

## Rollback

Per `RELEASE_PROTOCOL.md § Rollback protocol` (operator-authorized).

| Surface | Rollback | Tier |
|---------|----------|------|
| Checks 55/56/57/58 (append-only) | `git revert` the slice commit | **CHEAP** |
| Check 16 widen (#2682, in-place) | `git revert` the single focused commit — restores the `--label improvement` fetch | **CHEAP** |
| `link-check.yml` / `check-release-links.py` (#2685) | `git revert` | **CHEAP** |
| `gate-criteria-spec.md` G-CL9 + `release-process.md` (#3009 mechanism) | `git revert` the mechanism commit | **CHEAP** |
| **ADR status flips (#3009 data)** | **NOT a clean single revert** — per-ADR data edits to governance files. Kept in commits separate from the mechanism so the gate reverts without unwinding the audit | **MODERATE** |

---

*Closure-phrasing note: every per-issue closure reference in this plan is written as "mark #N as closed at Stage 13" — no close-family verbs bound to an issue number, so transcription into PR bodies will not trip GitHub's close parser.*

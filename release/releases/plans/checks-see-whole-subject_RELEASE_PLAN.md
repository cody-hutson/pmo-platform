---
title: Release Plan — checks-see-whole-subject
purpose: Stage-4 release plan for the nine defects in which an enforcement surface evaluates less than its declared subject and reports clean over the remainder.
type: release-plan
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->

# Release Plan: checks-see-whole-subject — A Check Evaluates Its Whole Declared Subject

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure via `release/tools/claim-version.sh --bump minor --dry-run`: next-free is **v4.39**. Corroborated independently — highest claimed tag is `v4.38`, and the highest `v4.x` row in the release ledger is `v4.38`. `v4.39` is absent from origin's tag set and from the ledger, with a firing control arm on `v4.38` in both populations. |
| **Date Created** | 2026-08-24 (Monday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | release/checks-see-whole-subject |
| **PR** | (populated at Stage 6 PR creation) |
| **Milestone** | checks-see-whole-subject |
| **Release Class** | `cross-cutting` — re-rendered from `routine` at the Stage-4 D-ReleaseClass gate (`class_weight` 1.3) |
| **Raw points** | **30** — bundling baseline 24, plus #4992 `size:M`→`size:L` (D-3) and #4720 `size:S`→`size:M` (D-9) |
| **Effective points** | **39** — `round_half_up(30 × 1.3)`. **+14 over the 25-pt G3-15 ceiling, shipped under a recorded operator override.** Membership unchanged at 9; no card trimmed to reach the band. |
| **Branch topology** | **SINGLE** (D-C) — one branch, one PR, one merge gate |
| **Concurrency posture** | **P0 fully-serial.** Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Baseline** | `origin/main` @ `8dc00db1` — the Stage-4 pin, still current at Engineering Commit 0 |

### Release Outcome Statement

**AFTER** this release: a check evaluates its whole declared subject — no silent truncation, scope gap, or blind arm.

**BEFORE:** checks silently scan a subset and report clean over the remainder.

### Differentiation posture (`cross-cutting`)

| Facet | Setting |
|---|---|
| Engagement density | Tight |
| Stage 9 review depth | Deep |
| Stage 5 activation bias | ALL |
| Stage 13 outcome-window | 30-day |

---

## Scope

### Issues Included

| # | Issue | Title | Priority | Size | Band |
|---|-------|-------|----------|------|------|
| 1 | #4981 | `git grep -E` silently returns zero for boundary-escape patterns — count-cascade sweeps can report a false CLEAN | P2 | S | foundation |
| 2 | #4720 | `fetch_stage_titled` silently truncates at the search 1000-cap against a ~2988 population | P2 | M | infra |
| 3 | #5260 | `blast-radius.sh` reports `second_order_count` 0 at depth 1, indistinguishable from a measured empty set | P2 | S | infra |
| 4 | #5074 | `blast-radius.sh` enumerates git-ignored trees, inflating every impact denominator | P2 | S | infra |
| 5 | #4734 | Check 35 classifies single-mode skills as multi-mode by matching a mode marker anywhere in the file | P2 | S | skill-core |
| 6 | #4992 | Token-registry conformance check reaches only half the token surface — one prefix, one file extension, three of four roots | P2 | L | skill-core |
| 7 | #4440 | Check 45(b) drift guard is fragment-based: repointing the b-loop input makes the check a silent no-op that still declares success | P2 | S | skill-core |
| 8 | #5252 | Seven workflows still carry absent-is-pass — disposition each trigger-vs-verdict scope | P2 | M | eval |
| 9 | #4931 | Section anchors cited in issue bodies are never validated against the referenced file | P2 | S | eval |

Point scale: `XS=1 / S=2 / M=4 / L=8 / XL=16`. Raw sum 30; `effective_pts` 39 at `class_weight` 1.3.

### Dependency Graph

No hard build-blocking edge exists between any two cards. Every edge is **soft** — informational or substrate-currency — and the direction is load-bearing even though the blocking is not. The operator ruled at D-ReleaseClass that soft edges count as compositional edges for `cross-cutting` trigger (c); three such edges are enumerated, meeting the threshold.

```
#4981 ──soft(idiom)──▶ every card's control arm
                       (prescribes the whole-token matching idiom the
                        falsification arms are authored against)

#4720 ──soft(precedent)──▶ #5260
                       (#5260 names check-milestone-epic-membership.py's
                        status-handling pattern as the shape to follow)

#5260 ──soft(vocabulary)──▶ #5074
                       (#5074's non-git scan-scope case is a not-computed
                        state; it consumes #5260's typed-status slot)

#4734, #4992, #4440 ── mutually independent (same file family, line-disjoint)
#5252, #4931       ── independent; no in-bundle upstream
```

**Cycles: zero.** Four directed edges over nine nodes, enumerated by hand from issue-body citations and walked for cycles. Sensitivity arm: inserting `#5074 → #5260` alongside the existing `#5260 → #5074` produces a detected 2-cycle, so the walk discriminates. Specificity arm: the acyclic set as authored returns zero cycles.

**Native dependency mirror:** all nine report `blocked-by:` and `blocking:` empty on the GitHub Dependencies surface. Consistent with a soft-only edge set — soft edges are correctly not mirrored as native blockers.

---

## Implementation Sequence

Build order per operator decision **D-5** (the Stage-4 spoke's divergence inside the infra band, adopted):

| Position | Issue | Band | Note |
|---|---|---|---|
| 1 | **#4981** | foundation | Lands the whole-token matching and engine-parity guidance every later card's control arm is authored against. |
| 2 | **#4720** | infra | Its status-handling pattern is the precedent #5260 reads; landing it first keeps that precedent current. |
| 3 | **#5260** | infra | Establishes the typed-status mechanism and the `stats_extra` seam. |
| 4 | **#5074** | infra | Consumes the vocabulary #5260 established. |
| 5 | **#4734** | skill-core | Two predicate sites — the check body and its report mirror. |
| 6 | **#4992** | skill-core | Two arms on the token surface, not three. |
| 7 | **#4440** | skill-core | Pins the b-loop input selector inside the test. |
| 8 | **#5252** | eval | Seven workflows, one disposition sweep. |
| 9 | **#4931** | eval | Last is correct — it benefits most from the preceding eight landing first. |

**#5260 and #5074 build as ONE Engineering unit** (operator decision **D-4**). They are the release's only genuine same-region collision — the same emit block and the same self-test suite — and #5074's hermeticity problem is solved by #5260's typed-status mechanism. Both cards remain open with their own sub-tasks, their own acceptance criteria and their own closure records; the merge is of the *build*, not of the tickets.

**Concurrency posture is P0 fully-serial.** The hub routes one Engineering chip at a time in the order above; the next chip waits until the prior commit lands on the release branch.

---

## Stage Applicability Matrix

Stage 5 is a **release-level** verdict — the All-or-Nothing Rule in [`/core/standards/planning-solutioning-handoff.md`](/core/standards/planning-solutioning-handoff.md) § 2 disables per-issue routing. Triggers T3, T4 and T6 fire on the bundle. **Release-level Stage 5 verdict: ACTIVATE, all nine.**

| Issue | S5 | S6 | S7 | S8 | S9 | S10 | S11 | S12 | S13 |
|---|---|---|---|---|---|---|---|---|---|
| #4981 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4720 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #5260 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #5074 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4734 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4992 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4440 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #5252 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |
| #4931 | ACTIVATE | ✅ | ✅ | ✅ | ✅ | PLATFORM-SATISFIED | PLATFORM-SATISFIED | ✅ | ✅ |

**Stages 10 and 11 are PLATFORM-SATISFIED and already closed.** The PR diff is the dry run and git history is the snapshot; no agent action is required. The documented escape hatches — non-git deployments, database state, external integrations, binary artifacts, multi-system coordination — are absent from this release's entire change spec.

**Stage 2 Applicability correction, resolved at Commit 0.** The Stage-4 matrix carried T2 (skill logic changes) as CONDITIONAL, gated on whether #4981's worked probe record landed in a skill reference. #4981's design places the worked record in `core/disciplines/review-discipline-principles.md` § 8.2, **but the card edits a skill reference anyway** for its gate-clause change. **T2 resolves to ✓.** The release-level verdict is unaffected — ACTIVATE already held via T3/T4/T6.

---

## File Change Matrix

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-24, domain: governance }`

Every path is an internal platform artifact — deploy and CI tooling, pipeline specs, standards, disciplines and their fixtures. Secondary domain `software` on the executable surfaces. Dominant domain recorded as `governance`; sourcing-exempt, domain-classified.

**This matrix is the Stage-4 matrix corrected upward against each card's Stage-5 design as amended.** Several cards expanded; one withdrew a file. Every `CONDITIONAL:` row from the Stage-4 matrix is resolved below and carries its concrete path — a row left conditional after its condition has resolved is an authoring defect.

### #4981 — probe validity and engine parity (4 files)

```
core/disciplines/review-discipline-principles.md                          edit
release/references/pipeline/stage-05-solutioning.md                       edit
core/skills/pmo-qa-auditor/references/cascade-completeness-detection.md   edit
core/ADRs/ADR-142-word-boundary-matching-is-engine-parity-not-syntax.md   add
```

Resolves Stage-4 `CONDITIONAL:4981-probe-in-skill` — the row **fires**, but on a re-stated condition. The worked probe record lands in the discipline file, not the skill reference; the skill reference is edited for the gate-clause change instead. Editing a skill's `references/` is a skill edit: the `.skill` package and its content-baseline sidecar rebuild in the same PR.

### #4720 — transport truncation (3 files)

```
core/deploy/tools/check-milestone-epic-membership.py                      edit
core/deploy/deploy.sh                                                     edit
core/deploy/tools/README.md                                               edit
```

### #5260 + #5074 — blast-radius scope and status (8 files, one joint matrix)

Both cards declare the same 8-row matrix because they build as one Engineering unit.

```
release/tools/blast-radius.sh                                             edit
release/tools/lib/schema-v1-emit.sh                                       edit
release/tools/tests/test_structural_blast_radius.sh                       edit
release/tools/tests/fixtures/blast-radius-f1/normalized-golden.json       regenerate
release/tools/tests/fixtures/blast-radius-f1/verify-golden.sh             edit
release/tools/tests/fixtures/blast-radius-f1/README.md                    edit
release/references/protocols/blast-radius-protocol.md                     edit
release/references/templates/design-review-checklist.md                   edit
```

### #4734 — mode-arity predicate (1 edit + 1 add)

```
core/deploy/deploy.sh                                                     edit
core/deploy/tools/<check35-mode-arity-oracle>.py                          add
core/config/allowlists/script-execution-allowlist.txt                     edit   (companion)
```

**Expansion surfaced, not absorbed.** The card's own Stage-5 round-3 amendment states `deploy.sh` is "still the sole file" and, in the same amendment, introduces instruction 1i: land the acceptance oracle as a checked-in `python3` script under `core/deploy/tools/` rather than a session artifact. Those two statements cannot both be true. The added script also triggers the new-executable companion obligation — an allowlist row and stated CI wiring in the same release. The concrete filename binds when #4734's Engineering chip runs. **This is a matrix expansion the card did not restate as one; it is recorded here so Stage 9 reviews it rather than discovering it in the diff.**

### #4992 — token-surface reach (4 files, one withdrawn)

```
core/deploy/deploy.sh                                                     edit
core/standards/depersonalization-spec.md                                  edit
CHANGELOG.md                                                              edit   (allow-marker)
docs/scripts/setup-workspace.sh                                           edit   (allow-marker)
core/ADRs/ADR-<n>-token-surface-reach.md                                  add    (number at Commit 0)
```

**Withdrawn — do not create:** `core/config/allowlists/token-registry-uncodified.txt`. Its round-3 amendment strikes the row explicitly. The un-codified set is derived live from the spec table and the enumerated corpus; if the #4992 Engineering chip finds itself writing a list of token names to disk, the amendment has been mis-read.

**Conditional, operator-gated:** `.github/workflows/repo-integrity.yml` enters only on an affirmative answer to that card's D-14. It is **not** created speculatively.

### #4440 — drift-guard input selector (2 files)

```
core/deploy/tests/test_check45_governing_doc_name_match.sh                edit
core/standards/gate-efficacy-standard.md                                  edit   (falsification column, additive)
```

`core/deploy/deploy.sh` is **READ-only** for this card — the fix pins the selector inside the test; the check itself is unchanged. The second row is a spoke-level expansion over the Stage-4 declaration of one row.

### #5252 — absent-is-pass disposition (8 files)

```
.github/workflows/close-completeness.yml                                  edit   (BIND + graduation-note)
.github/workflows/deploy-check-ci.yml                                     edit   (CONVERT)
.github/workflows/release-corpus-completeness.yml                         edit   (RECORD: graduation-note only)
.github/workflows/release-link-check.yml                                  edit   (CONVERT)
.github/workflows/release-tooling-smoke.yml                               edit   (BIND)
.github/workflows/skill-license-check.yml                                 edit   (CONVERT + invariant-line correction)
.github/workflows/version-freeness.yml                                    edit   (BIND)
core/standards/gate-efficacy-standard.md                                  edit   (register membership)
```

Resolves the four Stage-4 `CONDITIONAL:tier-a-disposition` / `CONDITIONAL:tier-b-disposition` rows into 3 CONVERT / 3 BIND / 1 RECORD.

### #4931 — issue-body section-anchor validation

```
core/deploy/tools/<check-issue-body-anchors>.sh                           add    (D-4931-Landing: new tool)
core/deploy/tools/tests/fixtures/<anchor-fixtures>                        add
core/config/allowlists/script-execution-allowlist.txt                     edit   (companion)
core/deploy/deploy.sh                                                     edit   (Check 71 block)
release/references/how-to/intake-style-guide.md                           edit
core/standards/reference-durability-standard.md                           edit
core/ADRs/ADR-<n>-issue-body-anchor-resolution.md                         add    (number at Commit 0)
```

Resolves Stage-4 `CONDITIONAL:d-4931-new-file` — **fires**. D-4931-Landing resolved to a new tool rather than an extension of the existing issue-reference validator, so the required branch-protection context is untouched and blast radius on required contexts stays zero. The `CONDITIONAL:d-4931-extend` row does **not** fire and is struck. The new-executable companion obligation is mandatory in the same release: the allowlist row plus stated CI wiring. Concrete filenames bind when the #4931 chip runs.

### Read-only inputs

```
core/deploy/deploy.sh                        READ  (#4440 — the b-loop selector is pinned FROM here, not changed)
core/deploy/tools/check-pv7-vocabulary.sh    READ  (#5260/#4720 — Register B gate; does NOT cover Register A)
.github/workflows/skill-package-freshness.yml READ (#5252 — filter-free exemplar, already converted)
.github/workflows/link-check.yml             READ  (#5252 — filter-free same-class exemplar)
.github/workflows/install-tests.yml          READ  (#4440 — the runner that invokes the test)
```

### Release-wide explicit non-scope

```
core/standards/depersonalization-spec.md § registry additions   NOT EDITED  (the name-unregistered angle-bracket tokens are separately owned scope)
core/config/allowlists/token-registry-uncodified.txt            NOT CREATED (withdrawn by #4992's round-3 amendment)
release/references/pipeline/stage-07-dev-testing.md             NOT EDITED  (#4981 routed its unqualified boundary-escape claim to a next-release issue)
core/rules/bypass-mode-readiness.md + its mirror                NOT EDITED  (#4981 accepted-residual; conservative security-hook posture)
core/standards/evidence-grounding-standard.md                   NOT EDITED  (#4981 routed the stale PV range string to a next-release issue)
```

### Package-rebuild consequence

```
packages/pmo-qa-auditor.skill                                             rebuild  (#4981 edits its references/)
packages/pmo-qa-auditor.skill.sha256                                      rebuild  (content-baseline sidecar)
```

Enforced pre-merge by the skill-package-freshness CI gate. The rebuild lands in the same PR as the reference edit, not at release-cut.

---

## Contention Map

| Rank | Shared surface | Issues | `overlap_class` | Operational risk |
|---|---|---|---|---|
| **1** | `release/tools/blast-radius.sh` and `release/tools/lib/schema-v1-emit.sh` | **#5260 × #5074** | `line-range-overlap` | **Resolved by construction** — D-4 merges them into one Engineering unit, one commit sequence, one test pass. |
| **2** | `core/deploy/deploy.sh` | **#4720 × #4734 × #4992 × #4931** | `line-range-overlap` (four in-release writers) | **MEDIUM-HIGH** — see the correction below. |
| **3** | `core/deploy/deploy.sh` × mainline | #4720/#4734/#4992/#4931 | `line-range-overlap` (cross-PR) | **MEDIUM** — highest-traffic file in the repo, roughly 10 commits per fortnight. |
| **4** | `core/standards/gate-efficacy-standard.md` | **#4440 × #5252** | `single-pr` | **LOW-MEDIUM** — see the correction below. |
| **5** | `core/config/allowlists/script-execution-allowlist.txt` | **#4734 × #4931** | `single-pr` | **LOW** — both append companion rows for a new executable; append-only, different rows. |
| 6 | `.github/workflows/*.yml` | #5252 (sole writer) | `single-pr` | LOW |

**Correction 1 — `deploy.sh` has four in-release writers, not two or three.** The Stage-4 map recorded two, corrected at D-6 back to three (#4734, #4992, #4720). #4931's design then landed a Check 71 block in the same file, making four. The hunks remain line-disjoint and marker-anchored, so conflicts should be textual rather than semantic — but a four-writer file under P0 serial execution is the release's largest sequencing constraint after the blast-radius pair, and the build order above already separates the four writers by three positions or more.

**Landed hunks in `deploy.sh`, recorded as each writer lands** — so the three writers after each entry can confirm line-disjointness against measured lines rather than against the plan's estimate.

| Writer | Position | Landed region (post-edit) | Anchor |
|---|---|---|---|
| **#4720** | 2 | **`10638`–`10687`**, one contiguous block (pre-edit `10638`–`10654`; +33 lines) | Inside the Check-56 M3 leg, entirely AFTER the `C56-EMIT-END` sentinel at `:10615`, so the extraction-test region is untouched. Anchored on the `CAVEAT:` comment text and on the existing `awk -F'\t' '$1=="…"'` reads, never on a line number. |

**Correction 2 — `gate-efficacy-standard.md` is a two-writer surface.** #4440's design added it at DEC-5 as a spoke-level expansion; #5252 already carried it as its sole non-workflow row. Both edits are additive and target different rows — #4440 appends to the falsification column of one gate's row, #5252 amends register membership. The overlap was classified weak and logged by #4440's spoke rather than escalated. **It is recorded here because the Stage-4 Contention Map does not carry it**, and the build order places #4440 at position 7 and #5252 at position 8 — adjacent, which is the sequencing that makes an additive collision cheapest to resolve.

**Cross-PR Overlap Audit — baseline `8dc00db1`.**

`### In-Flight Release Roster` — **Population: n=0**, recorded explicitly per audit-baseline discipline rather than omitted. Open PRs repo-wide measured at 0 against a whole-repo denominator, not a `release/*` filter, so the zero is not a filter artifact. The one remote `release/*` head at measurement time was an ancestor of `main` — a merged-and-undeleted branch, not an in-flight sibling. **Re-check obligation:** re-measure this population at Stage 9 before it is relied on; a single entry appearing later silently invalidates the row.

---

## Risk Register

| ID | Risk | Owner | Severity | Reversibility | Mitigation |
|---|---|---|---|---|---|
| **R-1** | **#5074's original acceptance criteria conflicted with the `blast-radius.sh` self-test's documented hermeticity.** The suite states it uses no git and builds fixtures with bare temp trees; a git-dependent enumeration collapses there. | #5074 | HIGH | MODERATE | **Resolved at Stage 5.** Git-optional scoping: tracked enumeration when the root is a work tree, the existing filesystem walk otherwise, with the non-git case emitted as a distinct typed status rather than a silent fallback. Composes with #5260 and preserves hermeticity. |
| **R-2** | **#4931's landing surface was undeclared.** | #4931 | MEDIUM | CHEAP | **Resolved at Stage 5** — D-4931-Landing rules a new tool, with the allowlist companion row and CI wiring pre-declared in the matrix above. The required branch-protection context is untouched. |
| **R-3** | **#5260's originating body cited the wrong probe-validity element.** Building to the cited element would produce a conformant-looking fix that misses the field-absence requirement. | #5260 | MEDIUM | CHEAP | Engineering cites the measurement-state rider and its absence-not-zero clause; the status vocabulary is adopted verbatim, never re-coined. Graded by CIAC-1. |
| **R-4** | **#4720's transport failure surface grows** from 10 to 54 requests once pagination replaces the capped search. | #4720 | MEDIUM | CHEAP | **Operator ruled IN-SCOPE at D-9** rather than an accepted residual; the card re-sized `size:S` → `size:M`. Mitigated by the partial-transport helper and the five-valued status enum. |
| **R-5** | **G3-15 band breach at +14.** | release | MEDIUM | CHEAP | **Shipped under a recorded operator override.** Every point added came from evidence a Stage-5 spoke produced — a class re-render and two evidence-driven scope corrections — not from bin-packing. |
| **R-6** | **Two of #5252's seven workflows are single-touch files**, and both declare a required posture. Low prior-touch count means low regression coverage and no established edit pattern. | #5252 | MEDIUM | CHEAP | Disposition those two with the most care; treat any filter removal as CI-cost-visible and verify on a PR touching an unrelated path. |
| **R-7** | **`deploy.sh` mainline churn** against four in-release writers. | #4720, #4734, #4992, #4931 | MEDIUM | CHEAP | Marker-anchored edits only, never line-anchored; re-baseline before Stage 9; the build order separates the four writers. |
| **R-8** | **Line citations in several issue bodies have drifted** since the readiness pre-flight. | #4992, #4720 | LOW | CHEAP | Engineering re-resolves by marker, never by the cited line number. Expected churn on a high-traffic file; not a defect in the cards. |
| **R-9** | **#4734's residual is expected to be non-zero.** Its acceptance oracle reports a residual of 5 or 7 files depending on the path taken; a run reporting 0 means the oracle was re-derived from the recognizer under test and is broken. | #4734 | MEDIUM | CHEAP | Stage 7 grades a zero as a **failure**, not a pass. The oracle exits non-zero when any of its own control arms is inconsistent. |
| **R-10** | **#4734's build path is unruled.** The operator has not ruled between the two paths its design offers. | #4734 | LOW | CHEAP | **Default to Path 1** and proceed — do not block. If the operator rules Path 2, the delta is exactly three named changes. |
| **R-11** | **Sibling integration criteria inherited a superseded permitted-form list.** Two cards' integration criteria enumerate probe forms from a list #4981's round-3 amendment superseded, and they grade at Stage 8 under a per-criterion verdict enum — so a correct arm can grade non-conforming. | release | MEDIUM | CHEAP | Two limbs. **(a)** the hub re-issues the corrected form list to the affected sub-tasks at Collective Review; **(b)** #4981's own change states that an integration criterion naming a form list grades against the **shipped** list, not its own inline enumeration. Limb (b) is durable and lands inside a file #4981 owns; it is why the closed-enumeration failure cannot recur. |

**Rollback strategy.** Every card is `git revert`-ible at commit granularity, and the release ships as a single PR and a single merge under D-C SINGLE, so `git revert -m 1 <merge-sha>` reverts the whole release. Two cards deserve a named per-card exit: **#5074** — if the hermeticity resolution proves wrong at Stage 7, revert that commit alone; the self-test is the canary and fails loud. **#5252** — a filter removal that proves too CI-expensive reverts to the filter plus a recorded disposition, with no code change stranded. Destructive reset is blocked by platform settings; only forward-moving `git revert` is permitted.

---

## Cross-Issue Acceptance Criteria

Four criteria. Each spans two or more issues, asserts a cohesion constraint the *integrated* release must hold, and is graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 (#5260 × #5074 × #4720 — measurement-state vocabulary).** Every not-computed, not-measured or truncated state introduced by these three cards is emitted using a member of the closed machine-readable status set defined in [`/core/disciplines/review-discipline-principles.md`](/core/disciplines/review-discipline-principles.md) § 8.1, with no locally-coined token; and on any non-measuring status the counter is **absent**, never `0`. *Method:* extract every status-field literal introduced by the merged diff in the two executable surfaces; assert set-membership in the closed enum, and assert no zero-initializer survives on a non-measuring path. **Control:** a seeded token outside the enum must be reported. *Why release-scoped:* the shipped gate enforces the human-readable register only; the machine-readable register has no enforcing gate, so nothing else binds these three to one vocabulary.

- [ ] **CIAC-2 (#4734 × #4992 × #4440 — two-site parity in `core/deploy/deploy.sh`).** No fix in this release repairs one occurrence of a duplicated predicate while leaving its mirror on the old idiom. *Method:* for #4734 assert zero remaining occurrences of the superseded mode-marker probe across both sites; for #4992 assert both check limbs derive from the same prefix and delimiter source; for #4440 assert the pinned fragment set covers the b-loop input selector at both selector sites. **Control:** the site counts are re-measured on the merged tree, never carried from this plan.

- [ ] **CIAC-3 (#4981 × #5074 × #5260 × #4992 × #5252 — falsifiable-control parity).** Every new or amended check, probe record or worked example introduced by this release carries **both** control arms with observed results — a sensitivity arm shown non-zero and a specificity arm shown zero over a non-empty input — and no card reports a clean zero whose control arm also returned zero. *Method:* enumerate every zero-, clean-, absent- or N-of-M-shaped claim in the merged evidence; assert each carries invocation, denominator, both arms and an extraction record. **Control:** a deliberately arm-less claim must be flagged. *Why this release:* the outcome statement is that a check evaluates its whole subject — a member shipping an unfalsifiable green would contradict it.

- [ ] **CIAC-4 (#5252 × #4992 × #4931 — declared-versus-actual scope).** Where a card changes what a gate reaches, the gate's own **declared** scope is updated in the same commit as the reach change. *Method:* for each workflow compare the declared posture against the presence or absence of a path filter and assert zero mismatches; and assert the token-vocabulary spec states the widened prefix **and** delimiter set. **Baseline pinned at `8dc00db1`: 22 of 22 workflows carry a declaration and 0 mismatches exist**, so any mismatch present at Stage 8 is attributable to this release. **Control:** a deliberately mismatched fixture is detected.

---

## Verification Plan

All nine cards' acceptance criteria are file-path-plus-state or explicit-predicate class, so each maps to a re-runnable command rather than a declared-but-unbuilt method. No card carries a behavioural criterion whose executor does not yet exist, so no deferred-verification entry applies.

| Family | Check | Scope |
|---|---|---|
| Per-issue | Each card's acceptance criteria re-run against the merged tree at its own Engineering chip and again at Stage 8 | all nine |
| Integration | CIAC-1 … CIAC-4 above | release |
| Regression | `core/deploy/deploy.sh --check` | release |
| Doc-link integrity | `core/deploy/deploy.sh --check` link resolution over every modified markdown file | release |
| Sync | Deployed-copy sync for any mirrored rule file touched | release |
| Package freshness | `.skill` package plus content-baseline sidecar rebuilt for every rostered skill whose `SKILL.md` or `references/` changed | #4981 |
| Runtime suite | The suite selected by the runtime-suite selection map, run under a temporary-home sandbox, per card | per card |

**Seeded-fixture cases.** #4981's worked-probe criterion and #4992's negative-control criterion are the two cards whose criteria require a fixture to be shown **firing** and then shown **clearing** when the fixture is removed. A gate that cannot go red is a broken probe; a fixture arm that is only ever asserted green has not been run.

### Verification Evidence

Populated per Engineering chip as each card lands, in the order of § Implementation Sequence. Each entry records the card, the checks run, their observed results, and the landing commit.

#### #4981 — probe validity and engine parity · position 1 · landed `90189947`

| Check | Family | Observed |
|---|---|---|
| Defect-idiom census, re-measured at fix time | per-issue (AC-3) | **0** across both script-class populations — 231 files / 143,805 lines, and 296 files / 152,375 lines with workflow YAML. Tree-wide: exactly **1**, and it is prose in an archived release plan warning about this defect, not an invocation. |
| Detector sensitivity arm | per-issue (AC-2) | 5 seeded must-flag lines carrying the full defect idiom, 2 of them with a git global option between command and subcommand. Original predicate flags **2 of 5**; repaired predicate flags **5 of 5**. PASS — NON-ZERO. Arm input 161 bytes, non-empty. |
| Detector specificity arm | per-issue (AC-2) | 6 near-miss lines, each differing from a true positive in exactly one property. Both predicates flag **0 of 6**. PASS — ZERO. Arm input 178 bytes, non-empty. |
| Cascade-completeness sweep | per-issue | 14 patterns over 3 files / 1,402 lines / 151,169 bytes, engine `python3` `re.search`, file-scoped. Every UPDATE target moved to 0; every PRESERVE target intact — `7 classes` 1, the boundary labels 2, the element-range string 1, `15 rules` 1. Control arms: sensitivity 4 and 8, specificity 0. |
| Doc-link integrity | integration | `deploy.sh --check` Check 14 — **OK, no broken cross-refs in scope.** |
| ADR number integrity | integration | `check-adr-numbers.py` — **PASS**, 142 ADRs contiguous, no duplicates. |
| ADR durability lint | integration | `check-adr-durability.py` — ADR-142 clean; the 2 residual findings are pre-existing on another record. |
| Skill-package freshness | regression | `pmo-qa-auditor` rebuilt and **fresh**; package plus content-baseline sidecar committed in the same commit as the reference edit. |
| Runtime suite | self-verification | **`suite-skip`** — the honest no-op. No changed path matches rows 1–5 of the runtime-suite selection map; the change is doc, governance and spec only. Control: a `core/deploy/deploy.sh` probe selects row 2, so the selector discriminates. |
| Full `deploy.sh --check` | regression | 4 FAIL rows, **none in this change set** — a stale package for a skill this card does not touch, release-body drift across previously logged releases, and a count-structure finding in a file from an earlier release. Probe: 0 of 6 changed paths intersect any FAIL subject; control arm fires at 3 for the subject this card does own. |

**AC-4 resolves via its second limb.** No committed-scripts lint arm ships. The population is measured at zero, and a new executable would carry an allowlist row and CI wiring for no yield. The flip trigger is recorded in ADR-142: the first live occurrence of the forbidden form in a committed script re-opens the decision.

---

#### #4720 — transport truncation · position 2 · landed `bee56cdf`

| Check | Family | Observed |
|---|---|---|
| Self-test suite | per-issue (AC-3) | **104 legs, 104 green.** Fourteen are this card's: T-S1 / T-S1c / T-S1c2 / T-S2 / T-S3 / T-S4 / T-S4c / T-S5 / T-S6 / T-S7 / T-S8-ctrl / T-S9 / T-S11 / T-S11c, plus the rc-bearing T-S10 / T-S10b / T-S10c. |
| Mutation kill-map, both directions | per-issue (AC-3) | **11 mutations, each run against the ASSEMBLED suite**, not against the function in isolation. Every one reddens the legs its row names, and in all 11 the suite stayed intact at 104 rendered legs — so a red leg is attributable to the mutation rather than to an aborted run. The two rows this release turns on: **restoring `_gh` at the call site reddens exactly `{T-S10, T-S10b}` and nothing else** — every rc-0 arm unchanged, which is what makes it attributable to the one token; **dropping the `ndocs == 0` guard reddens `{T-S8-ctrl, T-S10}`**. |
| FM-2 (`max(totalCount)`) | per-issue (operator-folded) | **Fixed and covered.** T-S11 drives a two-document stream whose second page reports a HIGHER `totalCount`; it reads `fetched` under first-page binding and `truncated` under `max()`. Restoring `max()` reddens **T-S11 alone**. Near-miss control T-S11c (a genuinely short walk) stays **truncated** under both, so T-S11 is not satisfiable by a mutation that reads `fetched` everywhere. |
| CD2-2 / AC2-5 (degraded path emits) | per-issue | **Discharged, measured on stdout rather than asserted from code shape.** The degraded `--leg M3` path now emits **2 rows** (`M3_SCAN degraded - - -`, `M4_SCAN not-run - - scope:m3-only`) and then exits 3; **no `COUNT_M3*` row is emitted** (PV-7b absence-not-zero). Control arm over the SAME code path with a measured walk emits **4 rows** including `M3_SCAN fetched 1 1 1` and both `COUNT_M3*` rows, and exits 0 — so neither arm is vacuous and the difference is the measurement state, not the path. |
| Emit-on-every-path | per-issue | Fixture run emits `M3_SCAN fixture - - - scope:fixture`; `--leg M1` emits `M3_SCAN not-run - - - scope:leg-M1` with no M3 rows and no counters. |
| Doc-link integrity | integration | `deploy.sh --check` Check 14 — **OK, no broken cross-refs in scope.** |
| PV-7a Register B spelling (Check 69) | integration (CIAC-1) | **OK, and the check is ENFORCING, not warn-mode.** 1,770 tracked files enumerated, 13 carrying a token rendering, control 81 sanctioned occurrences observed non-zero, 0 unsanctioned. The `DEGRADED` token this card adds to `deploy.sh` is the sanctioned spelling. |
| Runtime suite | self-verification | **Rows 2 and 4 selected** (`core/deploy/**` and `core/deploy/tools/*.py`). Row 4 run: `check-selftest-coverage.py --run` — **ARM A PASSED, 62 of 62** discovered tools, and the modified tool is IN that set with its 104 legs green (verified by name in the run log, not assumed). Row 2 (`install-tests.yml` deploy steps) not run locally — a CI-hosted job; it gates pre-merge. |
| Full `deploy.sh --check` | regression | **4 issues = 2 FAIL + 2 DRIFT, none in this change set.** FAIL: a stale `release-planner` package (that skill is unchanged on this branch — `git log 8dc00db1..HEAD` over its tree is empty) and a `count-structure` finding in `core/references/reference/operator-instance-home-and-isolation-key.md`. DRIFT: `pmo-qa-auditor` installed-copy drift, which is position 1's change not yet deployed to the operator install — operator-instance, never CI. Probe: **0 of 3 changed paths intersect any FAIL subject**; sensitivity control fires at 1 on a seeded row naming this card's file, specificity control returns 0 on a near-miss filename. |

**Accepted Verification 2 and 3 are NOT satisfied and are owed to Stage 7.** The run above could not exercise the new walk live: the GitHub GraphQL quota was exhausted (0 remaining) for the whole session, and **five** gh-dependent checks reported input failure — including Check 56 itself. The live `M3_SCAN` row reading `fetched`, and `matched` exceeding 1,000, are the two assertions that state the card's whole claim as a number the run emits, and neither has been observed. Stage 7 must run them once quota recovers; a green self-test is not a substitute.

**One live observation the rate limit handed us for free.** Check 56's exit 3 came from `fetch_milestones` — the FIRST raise-on-rc fetcher — three calls before the stage-title walk was attempted. That is the empirical premise D-4720-B′ rests on, observed rather than argued: a genuine global input failure never reaches this fetcher, which is why a failure that DOES reach it is a per-leg measurement outage.

---

#### #5260 + #5074 — blast-radius scope and status · positions 3–4, one build unit (D-4) · landed `efd2b821`

*Backfilled at position 5 from the Stage-6 outputs posted on the two sub-tasks; no figure here is invented, and none is re-derived.*

| Check | Family | Observed |
|---|---|---|
| Typed-status discrimination, `--depth` | per-issue (#5260) | The defect is gone by SHAPE, not by prose. On the frozen corpus `--depth=1` and `--depth=2` used to emit 751-byte envelopes differing at exactly one byte — the echo of the requested depth. They now differ structurally: depth 1 → `second_order_status: not-run`, `second_order_count` **absent**, reason names the depth; depth 2 → `second_order_status: fetched`, `second_order_count: 0` — a **measured** empty. |
| Enumeration-drop discrimination, three arms | per-issue (#5074, the pass-2 BLOCKER) | Purpose-built git fixture, precondition `uid=501` asserted first. **SUBJECT** (tracked file behind a mode-000 directory) → `scan_scope_status: degraded`, `total_files_scanned` 3, reason present. **CONTROL** (same fixture, directory readable) → `fetched`, 4, reason absent. **SPECIFICITY** (tracked file *and* tracked directory deleted from the worktree) → `fetched`, 3, reason absent. The records differ in a **status field**, not only in a count no consumer can ground — and the specificity arm is what earns the classifier over a naive `[ -x parent ]` test, which mis-classifies exactly that row. |
| Disjoint-population confirmation | per-issue (#5074) | The SUBJECT arm reads `unreadable_files: 0` **beside** `scan_scope_status: degraded` — the two counters measure disjoint populations, so the census structurally cannot see an enumeration drop and the classifier is the only instrument that can. `scan_scope_status` never branches on `UNREADABLE_COUNT`. |
| `degraded` on the second path | per-issue (#5074) | **T5h** forces `ls-files` to fail against a corrupt index while `rev-parse` still succeeds; the reason names exit 128. `degraded` ships **tested**, not asserted, so the "do not ship an untested member" rule does not fire. |
| R3-2 emit clause, six arms | per-issue (#5260) | Arms A–D as specified, plus **two non-vacuity controls**: arm E (`fetched` + 0) keeps the counter **present at 0**, and arm F confirms every #5074 key survives. Without E and F a clause that simply deleted every zero would pass A–D and destroy the card's whole purpose. Arm C shows the FM2-2 hazard is **unreachable** — its output is identical to arm B. |
| Naive-derivation falsification | per-issue (#5260) | `rtrimstr("_status")` alone reproduces broken in **both** directions — `second_order_count` survives at 0 *and* `scan_scope` is deleted. The shipped `rtrimstr("_status") + "_count"` does neither. |
| Positional-binding detector (INT-1) | per-issue | `python3` literal substring over 15,496 bytes of `schema-v1-emit.sh`. Subject `${16` → 2; `${17`–`${20` → **0**. Sensitivity `${15` → **1** (non-zero); specificity `${99` → 0 over the same extraction (non-vacuous). Registry exactly 7 members, 4 + 3. |
| Sibling byte-identity | regression | `domain-blast-radius.sh` **0 lines changed**; ADR-068 **0 lines changed**. With the library edit complete and `blast-radius.sh` untouched, the F1 golden **reproduced at 751 B and its committed digest** and the domain suite passed 22/22 — byte-identity proved through the amended library against the repo's own pinned oracle. Sibling `.stats` key set unchanged in membership *and* order. |
| Golden regeneration | per-issue | **883 B / `ec46e8a7cd67b2b9e6bf742340f1272a812374cf302f2390b28ec4c7aa461ecb`**, read off the regenerated artifact rather than carried. The predicted digest matches to the full 64 characters. The open 930 B question **resolves to 883 by observation**: `scan_scope_status_reason` is emitted on the fixture root but `normalize()` deletes it, so it never enters the compared surface. Two further README claims measured, not asserted: in-repo-root recipe **881 B**, unwidened del-set **982 B**. |
| Suites | regression | `blast-radius.sh --self-test` **36/36, 0 skipped** (from 13; the inherited 31→33 figure assumed #5260 lands at 21 — it lands at 24, so the composed total reconciles to 13 + 11 + 12 = 36). `test_domain_blast_radius.sh` 22/0/0. `test_structural_blast_radius.sh` 15/0. `check-selftest-coverage.py --run` **ARM A 62 of 62**. `check-adr-numbers.py` PASS, 143 contiguous. Check 14 doc links OK. Check 69 vocabulary 0 unsanctioned, control 81 non-zero. |
| FM-3 — the unexecutable assertion | per-issue (#5260) | **Discharged by substitute, and the blocker is named rather than worked around.** `verify-golden.sh` is still absent from the execution allowlist (`BLOCK-DESTRUCTIVE-022`, reproduced this session, no bypass), so the script could not be run. All **13** `chk` predicates were parsed from the shipped script and reproduced inline against the regenerated golden, plus both spec constants — 13 of 13 expected == actual, with a firing near-miss control that correctly differs. |

**Two claims this unit corrected against itself, recorded because self-correction is the evidence.** The spoke first wrote that "no other card in this release edits `test_domain_blast_radius.sh`" and then withdrew it as over-scoped: the probe's denominator was the **three build units landed at `efd2b821`**, and five of eight had not run. The sound statement is *among landed units, this is the only writer*. **Round-3 Decisions item 5 therefore stays OPEN**, and the release-level file inventory must re-measure the population at the last build unit rather than reading the figure forward. Position 5 adds one data point and no more: **#4734 does not touch that file.**

---

## Delivery Strategy

- **Branch:** `release/checks-see-whole-subject`, cut from `origin/main` @ `8dc00db1`. Slug form, not version form — the version is provisional until the Stage-12 atomic claim.
- **Topology:** D-C **SINGLE**. One branch, one PR, one merge gate. Issues are delivery slices on one branch.
- **Commits:** one commit or short commit sequence per card, in build order, each referencing its source issue. Commit 0 is this plan file.
- **Sub-task container:** GitHub sub-issues (the structured path). The decomposition is nine multi-file, calibration-sensitive units well above the checklist threshold, and several carry native dependency edges.
- **PR:** created in **draft** at Stage 6 and transitioned to ready-for-review at the Stage 9 gate.
- **Version binding:** the `**Version**` cell above carries the placeholder token. It resolves, and this file is renamed to its versioned home, at the Stage-12 claim.
- **Force-push prohibited** on the shared release branch under P0 serial execution, including `--force-with-lease`.

---

## Decisions Register

| # | Decision | Outcome | Gate |
|---|---|---|---|
| D-1 | Plan + Release Outcome Statement | **Approved** | Stage 4 |
| D-2 | Release Class | **Re-rendered `routine` → `cross-cutting`.** Soft edges count as compositional edges per the Stage-4 dependency graph, so trigger (c) fires at three in-bundle edges. Highest-ceremony resolution applies. | Stage 4 |
| D-3 | #4992 sizing | **`size:M` → `size:L`** with a recorded band override; the delimiter-axis split was rejected as contradicting the Release Outcome Statement. | Stage 4 |
| D-4 | #5260 + #5074 | **One Engineering build-unit**, both cards remaining open with their own sub-tasks and closure records. | Stage 4 |
| D-5 | Implementation sequence | **Spoke divergence adopted** — infra band ordered #4720 → #5260 → #5074. | Stage 4 |
| D-6 | Plan amendment (consolidated) | **Approved** — File Change Matrix expanded; Contention Map amended; `deploy.sh` in-release writer count corrected. | Stage 5 wave 1 |
| D-7 | CIAC-1 scope | **Approved** — extraction scoped to status fields, so population labels are not graded as measurement states. | Stage 5 wave 1 |
| D-8 | ADR authorization | **Approved, all three.** Each claims next-free per the renumber oracle; none reserves above a sibling's unmerged claim — a gap blocks the repo, a duplicate is tooled. | Stage 5 wave 1 |
| D-9 | #4720 risk R-4 | **Ruled IN-SCOPE**, diverging from the hub recommendation. Consequence: #4720 re-sized `size:S` → `size:M`. | Stage 5 wave 1 |
| D-Version | Release version | **v4.39**, recorded at Stage 4 and re-verified at Engineering Commit 0. | Stage 4 / Commit 0 |
| D-Concurrency | Concurrency posture | **P0 fully-serial** under D-C SINGLE. | Stage 4 |
| D-ADR-4981 | ADR number for #4981 | **142** — the renumber oracle's next-free at the release baseline, computed across both ADR directories. Assigned at Commit 0 per D-2 of that card's design. | Commit 0 |

### Decisions still requiring operator judgment

| # | Decision | Recommendation | Reversibility / Confidence |
|---|---|---|---|
| **D-A1** | #4981's gate change re-aims an existing check from a zero-occurrence population to a live, currently-failing one. It is the better discharge and makes the check pass on what the release actually does, but it is a materially different gate change from the narrower one approved at the wave-1 gate. | **Adopt** | CHEAP / HIGH |
| **D-A2** | The sibling check inside the same skill reference still mandates the invocation form the re-aimed check now admits alongside others. Left unchanged, one file contradicts itself. | **Adopt** | CHEAP / HIGH |
| **D-A3** | Two sibling cards' integration criteria carry a superseded permitted-form list with a **closed** enumeration, and they grade at Stage 8. A spoke cannot edit a sibling's sub-task. | **(a)** hub re-issues the corrected list at Collective Review, **and (b)** #4981's change states that an integration criterion naming a form list grades against the shipped list. See R-11. | CHEAP / HIGH |
| **D-4734-Path** | #4734's build path is unruled. | Default to Path 1; Stage 6 is unblocked either way. | CHEAP / HIGH |
| **D-4992-D14** | Whether #4992 ships a pull-request-time reporting arm on the repository-integrity workflow. | Operator's call; the workflow file is **not** created speculatively. | CHEAP / HIGH |

---

## Change Description

### Outcome

Nine enforcement surfaces across the deploy, CI, pipeline-spec and disciplines layers each evaluated less than the subject they declared, and each reported clean over the remainder. After this release every one of them either evaluates its whole declared subject or says, in a distinct and machine-readable way, that it did not. The release is deliberately a set rather than a sweep: the failures share a mechanism, so one outcome statement covers them, and the fix is a coherent change to one property — *what a check can see* — rather than nine unrelated point repairs.

### Issues resolved

Nine, listed in § Scope. Each is marked as closed at Stage 13 on its own evidence, including #5260 and #5074, which build as one unit but close separately.

### Key decisions

The release class was re-rendered from `routine` to `cross-cutting` when the original rationale was falsified against live evidence, which carried the point total above the band and put it there under an explicit operator override rather than by trimming a card. Two cards were re-sized upward on evidence a Stage-5 spoke produced. Two cards were merged into a single Engineering unit without merging their tickets. #4981's design was amended twice under adversarial review — the second amendment withdrew a validity rule that would have condemned 18 of 30 correct probes on a working engine, and replaced it with a one-time engine assertion against a purpose-built fixture.

**#4720** was ruled in-release rather than accepted as a residual. Its Stage-5 spoke surfaced that replacing a capped search call with a cursor-paginated walk grows the transport failure surface from 10 requests to 54, and that a transport failure still exits 3 and takes two unrelated legs down with it; the spoke recommended accepting that and the hub concurred. The operator diverged, the card re-sized from `size:S` to `size:M`, and the resilience handling was designed and built rather than deferred. Its change surface widened from one file to three on the same decision — two of the additions being reconciliations of text this change falsifies, not new scope. A second operator decision folded the pass-1 adversarial finding **FM-2** in as a specified build item rather than shipping it as a residual, so the truncation predicate now reads its bound under first-page binding instead of a running maximum.

### Reversibility

**CHEAP / Confidence HIGH.** Every card reverts at commit granularity and the whole release reverts by reverting the merge. Two cards carry named per-card exits. No migration, no data change, no external system.

### Downstream impact

The probe-validity guidance #4981 lands is cited by every review-class skill that loads the discipline file and by the Stage-5 evidence-grounding review, so its blast radius is delivery-wide even though its diff is prose. The typed-status vocabulary #5260 and #5074 land becomes the shape later tools follow. The workflow dispositions #5252 lands change which checks report on which pull requests.

### Cross-references

Milestone `checks-see-whole-subject`. Stage-6 obligations for this file: each Engineering chip appends its entry to § Verification Evidence, and the final chip refreshes this section if the landed set differs from the plan.

---

## Canonical-checklist attestation

Recorded per stage as each completes. Stage 4 ran every codified phase step or recorded it N/A with reason; Stages 10 and 11 are PLATFORM-SATISFIED and closed.

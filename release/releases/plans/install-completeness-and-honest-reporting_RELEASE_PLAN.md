<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Release Plan — install-completeness-and-honest-reporting (a maintenance run that reports success has actually finished, and the tools that check it stop lying about a healthy install)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: install-completeness-and-honest-reporting
release_class: novel
domain_practice: { source: N/A — in-repo precedent governs; no external practice consulted, date: 2026-08-09, domain: software }
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `install-completeness-and-honest-reporting`

**Milestone:** `install-completeness-and-honest-reporting` (milestone 330). Four members — three build cards and one verify-only card — on one branch, one pull request, one merge.
**Version identity:** **slug-only** per **ADR-092**. This file is `install-completeness-and-honest-reporting_RELEASE_PLAN.md` and the branch is `release/install-completeness-and-honest-reporting`; no version stem appears in the filename, in the branch name, or in this plan's identity prose. Bump class is `minor`. The concrete number binds at the **Stage-12 atomic compare-and-swap**, which renames this file into its major-version bucket.
**Topology:** **SINGLE** — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** (undeclared at Stage 4, so the codified default applies). Stage-6 work routes one card at a time in the approved sequence on the shared branch. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`novel`** — trigger (a): one member introduces new install-time artifacts. Posture: engagement density **Standard** · Stage-9 review depth **Deep** · Stage-5 activation bias `ALL`, activated on 4 of 4 · Stage-13 outcome window **30-day**.

---

## Provenance

This file transcribes the **Stage-4 Release Planning** analysis relayed onto this milestone's release-scoped planning sub-task, reconciled forward through the mid-pipeline divergence re-measurement, the four **Stage-5 Solutioning** designs, and the **Collective Review scope-lock** that ratified them. Where a later measurement superseded a Stage-4 figure, **this file carries the decided state** and § Deviation Log records the delta. The Stage-4 and Stage-5 output comments are the historical record and are not edited. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke.

Every issue reference below sits inside the reference block at the end of this section and is accompanied by the summary that makes it readable without opening the ticket. Elsewhere in this plan the four cards are named by their short labels — **Partial install**, **Roster false-positive**, **Ambient intake**, and **Autonomy default** — so every table reads correctly even if the numbers rot.

### Issue References

- **#4449 — "Partial install."** `update.sh` reports "Update complete." at exit 0 while leaving a partial install: hook-tier composition surfaces absent, and `core/deploy/deploy.sh` non-executable. First card in the sequence.
- **#4450 — "Roster false-positive."** `validate-install.sh` check A9 flags operator-authored personal skills as platform-roster failures, which suppresses all of Mode B. Depends on the Partial-install card for evidence.
- **#4721 — "Ambient intake."** Ambient intake never activates on install: no inbox drop-zone, no sweep registration, no automation dial. Depends on the Partial-install card for exit semantics and on the Autonomy-default card for install-time surface precedence.
- **#1864 — "Autonomy default."** `setup-workspace.sh` did not install the autonomy-mode artifact, so the autonomy-ceiling hook defaulted to `enforce` rather than the documented `warn` on fresh installs. **Verify-only** in this release: the artifact already landed in a prior release; Stages 6, 7 and 8 verify it rather than author it.
- **#2250** — a sibling milestone owns a content widening of `core/deploy/deploy.sh`. Named here only to record that it does not contend with this release's mode-only change to the same path.
- **#302 and #1850** — the origin of the sourced-library executability exemption that `doctor.sh` already ships and that this release propagates to the second validator.

---

## Release Outcome Statement

**AFTER** — A maintenance run that reports success has actually finished, and the tools that check an install stop reporting failures that are not there.

**BEFORE** — `update.sh` exits 0 announcing "Update complete." over a workspace it left half-configured; the shipped `core/deploy/deploy.sh` carries no executable bit, so the documented operator invocation fails and the validator check that would have caught it early-returns without running; and `validate-install.sh` fails a *healthy* install because one of its checks disagrees with the exemption its sibling validator already ships.

**Success Indicator:** every ticket below closes with its acceptance criteria verified, and each new gate or assertion demonstrates a **real failure on a fixture** before it is trusted.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | slug-only pre-claim per ADR-092; bump class `minor`; recorded determination **v4.22** |
| **Date Created** | 2026-08-08 (Saturday) — Stage-4 planning, relayed |
| **Commit 0 authored** | 2026-08-09 (Sunday) |
| **Release Manager** | Agent-assisted, release-hub Mode O |
| **Status** | Executing — Stage 6 Engineering |
| **Branch** | `release/install-completeness-and-honest-reporting` |
| **Base commit** | `db0293de`, equal to `origin/main` at branch cut on 2026-08-09 |
| **Pull request** | populated at PR creation, Stage 6 — one PR across all four cards |
| **Milestone** | `install-completeness-and-honest-reporting`, milestone 330 |
| **Release class** | `novel` |
| **Topology and posture** | SINGLE topology, P0 fully-serial posture |

**Commit-0 version re-verify (detect-and-HALT, executed 2026-08-09): PROCEED.** After `git fetch --tags origin && git fetch origin main`, the allocator dry-run `claim-version.sh --bump minor --sha db0293de --dry-run` returned **`v4.22`**, matching the value this release carried into Stage 6. All three freeness arms agree: the highest tag on the remote is `v4.21`, the highest release-ledger row read at the remote tip is `v4.21`, and the highest published release is `v4.21`.

**A concurrent release carries the same recorded determination.** The in-flight sibling on branch `release/closeout-output-completeness` recorded `v4.22` at its own Commit 0 earlier the same day, against the same baseline. This is **not** a defect and **not** a reason to halt: under ADR-092 the number is a recorded determination rather than a reservation, and it binds only at the Stage-12 compare-and-swap, which the two releases reach at different times. Whichever merges first claims `v4.22`; the other recomputes and claims the next free slot. The structural protection is that **no version literal is written into any artifact this release ships** — not the branch name, not this filename, not any code or frontmatter — so a recomputation costs nothing but a re-read.

---

## Scope

Four cards, scope **LOCKED** at the Collective Review gate. No card was added, removed, or resized at that gate.

| Card | Problem | Class | Stage 6 authorship |
|---|---|---|---|
| Partial install | A maintenance run exits 0 over a half-configured workspace | bug, P2 Material | 6 MODIFY, 0 NEW |
| Roster false-positive | A validator check flags personal skills as platform failures, suppressing a whole mode | bug | 2 MODIFY, 1 NEW |
| Ambient intake | A shipped capability never activates on install | bug | 11 MODIFY, 0 NEW |
| Autonomy default | Fresh installs defaulted an enforcement ceiling above its documented level | observation | **verify-only — 0 files authored** |

### Approved implementation sequence

**Partial install → Roster false-positive → Ambient intake**, with **Autonomy default** verified at any point in the wave.

The order is rule-determined by the contention analysis rather than chosen: both downstream cards state the dependency in their own bodies. The Roster card consumes the Partial-install card's evidence — specifically, the mode fix changes what validator check A8 *does*, so the Roster card's residual failure count must be derived after the Partial-install card lands, never inherited from the pre-fix observation. The Ambient-intake card depends on the Partial-install card's exit semantics to fail loudly, and on the Autonomy-default card's install-time surface precedence. Hunks were verified disjoint function-by-function; this is ordering on one branch, not conflict.

---

## Release Class

`novel`, on trigger (a) — the Ambient-intake card introduces new install-time artifacts (an inbox drop-zone and the directories around it) that did not previously exist on any installed workspace.

The pre-split Stage-4 matrix was computed under class `cross-cutting`, which sets Stage-5 activation bias `ALL`. Re-classifying to `novel` **also** sets bias `ALL`, so the applicability matrix carries forward unchanged. The real delta is engagement density, which moved from Tight to **Standard**; Stage-9 review depth stays **Deep**.

---

## Dependency Graph

Three directional edges, all internal to this release. The three-way split that produced this milestone severed none of them.

- **Partial install → Roster false-positive** — evidence dependency. The Roster card's target figures are derived from the post-fix validator state.
- **Autonomy default → Ambient intake** — surface precedence. Both write install-time state; the autonomy-mode artifact must exist before ambient intake registers against it.
- **Partial install → Ambient intake** — surface precedence. The new install-time artifacts rely on the partial-install exit semantics to fail loudly rather than silently.

Zero cycles. The Partial-install and Autonomy-default cards are independently startable; Partial install is sequenced first because two cards wait on it.

---

## Stage Applicability Matrix

| Stage | Partial install | Roster false-positive | Ambient intake | Autonomy default |
|---|---|---|---|---|
| 5 Solutioning | APPLY | APPLY | APPLY | APPLY |
| 6 Engineering | APPLY | APPLY | APPLY | APPLY (verify-only) |
| 7 Dev Testing | APPLY | APPLY | APPLY | APPLY |
| 8 QA Testing | APPLY | APPLY | APPLY | APPLY |

No skips in this release. Stages 10 and 11 are closed as platform-satisfied under the codified stage-compression rule rather than by the applicability matrix; the rationale is recorded on their own release-scoped sub-tasks.

The Autonomy-default row carried a pre-split annotation reading "would SKIP — trivial" under a `DEFAULT` activation bias. That bias does not apply to a `novel` release, and the card changes fresh-install enforcement posture from `enforce` to `warn`, which is functional rather than cosmetic. It is verify-only here because the artifact already shipped, not because it is trivial.

---

## Contention Map

### Within-release — `docs/scripts/validate-install.sh`

Three cards touch this file. The contention is **DISSOLVED**, not merely sequenced, and the finding is recorded because a spoke resolved it rather than escalating a scope change nobody needed:

| Card | Region it edits | Shared lines with the other two |
|---|---|---|
| Partial install | check A3, hook layout — the sourced-library exemption | zero |
| Roster false-positive | check A9, skill roster, plus the Mode A denominator constant and the A3b skip | zero |
| Ambient intake | check A2, workspace layout — extends an existing check | zero |

The Ambient-intake design extends an existing check rather than adding one, which is what leaves the Mode A denominator untouched and produces no overlap with either sibling. Build order still applies for readability of the diff, but no merge conflict is possible between these three hunks.

### Within-release — `update.sh` and `core/deploy/tests/test_install_end_to_end.sh`

The Partial-install and Ambient-intake cards both touch both files. In `update.sh` the two edits land in disjoint regions: Partial install inserts a completeness gate between the skill redeploy and the hook refresh, Ambient intake adds a directory-scaffold phase in the earlier scaffold band. In the end-to-end test both cards **append a new stage after the last existing stage**, so the later card rebases onto the earlier card's stage rather than replacing it. Whichever spoke runs second re-reads the file's tail before appending.

### Cross-release — `core/deploy/deploy.sh`

The sibling milestone `path-and-citation-reconciliation` owns a content widening of this same file. **No collision.** This release changes only the git index **mode** attribute and zero content bytes; the sibling changes blob content. Git merges a mode change and a content change to the same path independently and conflicts only when both change the *mode*. The mitigation carried from the Stage-4 risk register is retained: the mode change ships in its **own isolated commit**, so a rebase cannot silently absorb it into a content hunk.

### Structural blast radius

`update.sh` classifies **Structural** (six or more first-order consumers requiring awareness). `docs/scripts/validate-install.sh` and `core/deploy/tests/test_install_end_to_end.sh` classify Structural by the same measure once all three build cards land. The `core/deploy/deploy.sh` change classifies **Cosmetic at the content layer** — zero bytes — with a precisely enumerated four-row invocation-form radius recorded under § Risk Register R14.

---

## Risk Register

| # | Risk | Severity | Mitigation | State at Commit 0 |
|---|---|---|---|---|
| R2 | The Autonomy-default card's target region sat inside an unmerged sibling's hunk, so its plan-time line numbers are stale | **HIGH** | Re-derive every target against current `main`; anchor on strings, never line numbers | **Materialized.** The sibling merged during the planning halt, so those line numbers have moved. The string-anchor constraint is load-bearing, not precautionary. The card is verify-only, which further reduces exposure to zero authored lines. |
| R14 | The `core/deploy/deploy.sh` mode change conflicts differently from a content change and is easy to lose in a rebase | LOW | Isolate it in its own commit; verify with a tree-entry read at Stage 7 | Mitigation applied at Commit 1. |
| R9 | The Ambient-intake rollback is not revert-able if registration and install-root state are written | MEDIUM | Record deregistration steps explicitly in the Stage 12 deploy log | **Exposure dropped to zero** at the scope-lock: the ratified posture performs no registration, so there is nothing to deregister. The non-git residue is three empty inert directories. |
| R10 | The Ambient-intake default posture — a fresh install landing with ambient intake active — changes what a new install does unprompted | MEDIUM | Explicit operator decision at the review gate | **Resolved** at the scope-lock: the installer scaffolds directories and seeds the dial; registration stays operator-owned and documented. |
| R8 | The Roster card's predicate could mask a platform skill that genuinely lacks a version field | MEDIUM | The card's acceptance criteria already require a positive control; graded at Stage 8 as must-pass | Open, carried to Stage 8. |
| R5 | The mode fix makes validator check A8 stop early-returning and start actually invoking the deploy check. Its verdict is **unpredicted** | MEDIUM | Capture the observed A8 verdict as Stage 7 evidence; do not inherit a pre-fix figure | Open, carried to Stage 7. If A8 fails, Mode B is suppressed again — by a genuine actionable cause rather than a false positive, which is the gate working correctly, but this release's Success Indicator would then not be met by these cards alone. |
| R15 | A concurrent in-flight release recorded the same provisional version | LOW | Ship no version literal in any artifact; let the Stage-12 compare-and-swap arbitrate | Open by construction; costs a re-read, not a rollback. |

### Carried forward, not a release gate

The destructive-command guard selects the **last** shell-script token in a command as its allowlist target, so a tool invoked with a script path as an *argument* is checked against the argument rather than the executed script. Four spokes across this release have now hit the rule. The allowlist lookup is correct; the target selection is inverted. This is governed runtime harness tooling, so it needs its own bug ticket and an approved plan — it is **not** fixed here, and it is not a gate on this release.

---

## Cross-Issue Acceptance Criteria

The pre-split cross-issue criteria were authored at a twelve-card scope and do not transfer. These are derived against this release's actual membership.

| # | Criterion | Method | Owner stage |
|---|---|---|---|
| X1 | After all cards land, a full `update.sh` against a healthy sandboxed workspace still exits 0 or 64 — the new gate never fires on a healthy install | Run the install end-to-end suite; assert the healthy-workspace arm | Stage 7 |
| X2 | After all cards land, `validate-install.sh` Mode A against a healthy sandboxed install reports zero FAIL rows attributable to a false positive | Run the validator against the end-to-end sandbox; classify each FAIL as true or false positive | Stage 8 |
| X3 | The Mode A pass/fail denominator the validator reports equals the number of check emitters it actually runs | Compare the declared total against the emitter count in the Mode A routing function | Stage 8 |
| X4 | Every new gate and assertion this release adds has demonstrated a real failure on a fixture — no assertion is trusted that has not been shown capable of failing | Each card's own anti-vacuity arm, collected | Stage 8 |
| X5 | `core/deploy/deploy.sh` is executable in the git index at the merge commit, and the sibling milestone's content change to the same file merges without conflict | Tree-entry read at the merge SHA; merge result | Stage 12 |

---

## File Change Matrix

**Release total: 16 distinct source paths — 15 MODIFY, 1 NEW, 0 DELETE, 0 new executables**, plus this plan file. The one new file is a regression-suite member invoked as `bash <path>` by the aggregating runner, exactly as its twelve siblings are — not a new command-line entry point — so **no script-execution allowlist companion row is owed by this release**. See D-9 for the precise basis and for the one operational consequence that follows from having no row.

| # | Path | Card | Intent | Reversibility |
|---|---|---|---|---|
| 1 | `core/deploy/deploy.sh` | Partial install | MODIFY — git index **mode only**, zero content bytes | CHEAP |
| 2 | `docs/scripts/validate-install.sh` | all three build cards | MODIFY — A3 sourced-library exemption; A9 predicate plus denominator reconciliation and the A3b skip; A2 layout extension | CHEAP |
| 3 | `update.sh` | Partial install, Ambient intake | MODIFY — completeness gate and new exit code; ambient-directory scaffold phase | CHEAP |
| 4 | `core/deploy/tests/test_install_end_to_end.sh` | Partial install, Ambient intake | MODIFY — gate regression and positive control; ambient-artifact regression | CHEAP |
| 5 | `core/deploy/tests/test_refresh_hooks.sh` | Partial install | MODIFY — entrypoint executability assertion plus anti-vacuity arm | CHEAP |
| 6 | `docs/UPDATE.md` | Partial install | MODIFY — new exit-code troubleshooting section and the documented gap | CHEAP |
| 7 | `core/deploy/tests/test_validate_install.sh` | Roster false-positive | **NEW** — the positive control, four arms | CHEAP |
| 8 | `core/deploy/tests/run-install-regression.sh` | Roster false-positive | MODIFY — one regression-member row | CHEAP |
| 9 | `docs/scripts/setup-workspace.sh` | Ambient intake | MODIFY — directory layout plus automation-dial seed | CHEAP |
| 10 | `core/deploy/lib-instance-path.sh` | Ambient intake | MODIFY — three new path resolvers | CHEAP |
| 11 | `docs/INSTALL.md` | Ambient intake | MODIFY — the activation step's documented home | CHEAP |
| 12 | `docs/GETTING_STARTED.md` | Ambient intake | MODIFY — capability discoverability | CHEAP |
| 13 | `core/config/operator.toml.template` | Ambient intake | MODIFY — comment accuracy on the seeded dial | CHEAP |
| 14 | `core/standards/c1-ambient-inbox-cursor.md` | Ambient intake | MODIFY — note the install-provisioning dependency | CHEAP |
| 15 | `core/standards/c2-intake-sweep-path-a.md` | Ambient intake | MODIFY — pointer to the documented registration home | CHEAP |
| 16 | `core/standards/c3-external-sync-path-b.md` | Ambient intake | MODIFY — same pointer | CHEAP |

**Machine-readable path list.** One repository-relative path per line, no annotations, so a downstream stage extracts the set deterministically without parsing the table above.

```
core/deploy/deploy.sh
docs/scripts/validate-install.sh
update.sh
core/deploy/tests/test_install_end_to_end.sh
core/deploy/tests/test_refresh_hooks.sh
docs/UPDATE.md
core/deploy/tests/test_validate_install.sh
core/deploy/tests/run-install-regression.sh
docs/scripts/setup-workspace.sh
core/deploy/lib-instance-path.sh
docs/INSTALL.md
docs/GETTING_STARTED.md
core/config/operator.toml.template
core/standards/c1-ambient-inbox-cursor.md
core/standards/c2-intake-sweep-path-a.md
core/standards/c3-external-sync-path-b.md
release/releases/plans/install-completeness-and-honest-reporting_RELEASE_PLAN.md
```

**Dropped from the cards' stated Affected Files, with reason.** `core/deploy/composition-surface-manifest.sh` — named on the Partial-install card but data-only; both allowlists it would need are already correctly rowed, so no change is required. `docs/scripts/setup-workspace.sh` is **not** dropped: the Partial-install card requires no change to it, but the Ambient-intake card does.

**Schema-level impact:** none. No file under `core/schemas/` is touched by any card.

**This plan file supersedes every card's own Affected Files block.** Where a card body and this matrix disagree, the matrix governs.

---

## Verification Plan

### Per-issue

| Card | Check | Method |
|---|---|---|
| Partial install | The completeness gate fires on an incomplete workspace and stays silent on a healthy one | End-to-end suite: remove one hook-tier surface, assert the new exit code and that the hook refresh did not run; restore, assert 0 or 64 |
| Partial install | Hook entrypoints carry the executable bit; sourced libraries need only be readable | Refresh-hooks suite: entrypoint assertion with the sourced-library discriminator, plus an anti-vacuity arm proving the assertion can fail and a specificity arm proving the exemption fires |
| Partial install | `core/deploy/deploy.sh` is executable in the index | Tree-entry read at HEAD against two sibling control arms known to be executable |
| Roster false-positive | A9 no longer misclassifies operator-authored personal skills, and still catches a platform skill genuinely missing its version field | New four-arm positive control, registered as a regression member |
| Ambient intake | The install lands the ambient directories and seeds the dial; nothing registers unprompted | End-to-end suite: assert the landed directories and dial plus a negative arm |
| Autonomy default | The autonomy-mode artifact lands on a fresh install with the documented default | Existing per-hook mode-file assertion in the end-to-end suite — verify-only, no new code |

### Release-level

Run the install regression suite in full and record pass and fail counts. Run the deploy-check drift pass. Confirm the doc-link integrity check over every modified markdown file. Confirm the skill-package freshness gate reports nothing owed — no card in this release edits a rostered skill's definition.

**Sandbox discipline:** every suite runs under a temporary-directory `HOME` override so the operator's live configuration is never a test target. Two of the suites additionally capture a before-and-after manifest of the live skills mirror as their own safety assertion.

---

## Rollback Strategy

**First-parent revert of the release merge commit.** This requires a true two-parent merge commit; a squash merge would break it.

All sixteen source paths revert cleanly. The mode change reverts with the tree entry — no data migration, no deploy reversal, no operator-instance state touched. The only non-git residue after a revert is the set of empty inert directories the Ambient-intake installer creates on any workspace that ran the shipped installer before the revert; they hold no data and removing them is optional.

**Reversibility: CHEAP · Confidence HIGH.**

---

## Domain Practice Provenance

No external domain practice was consulted. Every design decision in this release rests on **in-repo precedent** rather than an outside standard, and the precedent is cited at each decision point:

- The sourced-library executability invariant is not a new decision. `doctor.sh` already implements it, states its rationale in full, and a regression test pins it by deliberately seeding those libraries at a non-executable mode. This release propagates that shipped decision to the one validator that silently disagreed with it.
- The extend-before-create structural rule governed three of the four cards and resolved to `extend` on every surface. No card creates a net-new mechanism where an existing one could be extended.
- The exit-code choice sits in the installer family's own custom numbering scheme. No mapping to a POSIX convention is claimed, and none is implied.

---

## Deviation Log

| # | Deviation | Rationale | Disposition |
|---|---|---|---|
| D-1 | The Partial-install card's first acceptance criterion had a second limb requiring the executable bit on every file under the deployed hook library directory. That limb is **struck**. | Those files are sourced libraries consumed under a readability guard, never executed. They are correct at their shipped mode, and a regression test pins that mode as correct. Implementing the limb literally would have contradicted regression-pinned precedent and likely broken that test. | **Ratified by the operator** at the Collective Review scope-lock. The adopted invariant is: entrypoint implies executable; sourced library implies readable. |
| D-2 | Fixing the **tracked** mode bit of `core/deploy/deploy.sh` is treated as in scope, though the card frames the defect as an `update.sh` symptom. | The deployed copy inherits its mode from the source through a plain copy, and the source has carried a non-executable mode since a single accidental transition. No clone has ever had the bit, so there is nothing for `update.sh` to "retain" — the card's fourth acceptance criterion is otherwise unsatisfiable. Verified as the only such transition in the repository's entire history against a non-empty control. | **Ratified.** Shipped in an isolated commit per R14. |
| D-3 | The Ambient-intake default posture ships **inert and discoverable** rather than active. Two of its acceptance criteria consequently grade as requiring operator activation. | The reframing that decided it: only registration makes the platform act unprompted, and the installer's language cannot reach that surface at all. Active-on-install would require net-new auto-registration machinery, which the extend-before-create rule gates. | **Ratified**, with the counter-argument — that the capability ships dormant again — stated rather than suppressed, and accepted as the cost. |
| D-4 | The Roster card fixes the Mode A denominator constant and unifies the sub-modes, but the self-asserting drift check it proposed is **declined**. | Extend-before-create sets the bar at *necessary*, not *plausible*. The constant is read nowhere — one occurrence, the declaration itself — so this is a source-honesty defect, not a behavioral one. Killing the drift class remains a legitimate goal and is routed as separate intake. | **Ratified.** |
| D-5 | The Partial-install design specified an anti-vacuity arm asserting that the hook refresh **restores** an executable bit stripped from a content-identical entrypoint. Implemented instead as an arm asserting that the **assertion detects** the stripped bit, plus a specificity arm proving the sourced-library exemption fires. | The specified form cannot pass against live code. The refresh compares source and target by **content** hash; stripping the executable bit changes no content, so the run takes the unchanged-file path and returns before reaching any of the four sites that set the bit. The design's own testability table specifies the implemented form — strip the bit, the case fails — so the two halves of the design disagreed and the achievable half was taken. | Recorded at Commit 2. The underlying gap — a mode-only drift on a content-identical hook is never repaired — is a **real finding**, routed as separate intake rather than absorbed. |
| D-6 | The completeness gate fires under `--dry-run` as well as on a real run. | The design is silent on the preview path. Two readings were available: skip the gate under preview, since nothing lands and no asymmetry is created; or fire it, because a preview that reports "no update needed" over a missing security-control allowlist is precisely the dishonest-reporting pattern this release exists to remove. The literal reading of the card's own criteria — exit non-zero when a deployed control is left list-less, and never report success over a partial install — selects firing. Verified non-breaking: every existing non-preview test arm runs against a fully-installed sandbox, and the sparse preview arms in the sibling durability suite assert on output text rather than exit code. | Recorded at Commit 2; named as a Stage-7 verification point. |
| D-7 | The `docs/UPDATE.md` cross-reference edit lands in the "Verify" subsection of the procedure section rather than the section the design named. | The design named a section that does not contain the anchor line; the anchor lives one section earlier, in the subsection that already tells the operator to run the validator. That is the intended location by content. | Recorded at Commit 3. |
| D-8 | The Roster card's design places the roster-exclusion INFO record between the check's failure branches and its terminal pass, so an excluded skill is announced only when the check otherwise passes. Implemented instead with the INFO emitted as soon as the population scan completes — ahead of every verdict — and the anti-vacuity guard moved ahead of the two skill-health failure branches. Both failure diagnostics also gained the denominator the pass already stated. | The design was **internally inconsistent**: its testability table specifies an arm whose fixture carries both a platform skill missing its version field *and* an excluded operator-authored skill, and requires that run to emit an INFO naming the exclusion — a run in which the check fails and returns before reaching the INFO under the specified ordering. The two halves cannot both hold. Reconciled toward the testability table, which is the half carrying the reason: which skills a narrowed check declined to assert over is a property of the scan, not of the outcome, and a reader debugging a failure needs the exclusion list more than one watching a pass. An exclusion visible only on success is the silent narrowing the guard exists to prevent. No behaviour changes on the pass path. | Recorded at Commit 6. |
| D-9 | This plan states that no script-execution allowlist companion row is owed by this release. **The conclusion stands; one supporting premise does not.** The Roster card's design asserted that no existing member of the install regression suite carries an allowlist row. One does — the most recently added member. | Verified directly against the allowlist: six files under the deploy-test directory carry rows, and one of them is a standing regression member (its row was added in the commit that created the script, not in the later commit that enrolled it — so the row travels with script creation, not with suite enrolment). The conclusion is unaffected on the mechanism: the allowlist governs whether an **agent session** may execute a script, not whether the platform or CI can. The new member runs correctly under the runner and in CI without a row, and eleven of the now-thirteen members — including the direct analogue this file is modelled on — carry none. **The practical consequence is real and is not a code defect:** without a row, neither Engineering nor Dev Testing can execute the new suite from an agent session. Not acted on here — the allowlist is a security control under a separate governed change. | Recorded at Commit 7. Surfaced to Dev Testing with the exact command. |

---

## Change Description

*Operator-facing. Authored at Engineering Commit 0 for the release as scope-locked; each card's Engineering spoke extends the per-card detail as its work lands.*

### Outcome

Three tools stop lying about the state of an install. The maintenance command stops announcing success over a workspace it left half-configured — it now refuses to install a security control whose escape hatch is missing, names what is absent, and exits with a dedicated code. The deploy script ships executable again, so the invocation the documentation has always told operators to run actually works, and the validator check that exists to run it stops silently skipping. And the install validator stops failing a healthy install over a class of file that is correct exactly as it ships.

### Issues resolved (4)

Three build cards and one verify-only card, listed in § Scope and enumerated with their numbers in § Provenance. The verify-only card confirms an artifact that shipped in a prior release actually lands on a fresh install.

### Key decisions

Two premises stated in the tickets were rejected and the rejections ratified by the operator before any code was written. The first: a set of deployed files flagged as "hooks that can never run" are not hooks — they are libraries other hooks read, and they are correct without an executable bit. The real defect was one validator disagreeing with its sibling. The second: a capability that "never activates on install" ships scaffolded and documented rather than auto-registered, because the installer structurally cannot reach the surface that would register it.

### Reversibility

**CHEAP.** First-parent revert of the release merge restores every file. No data migration, no deployment to reverse, no operator data touched.

### Downstream impact

One validator check changes *kind* rather than merely verdict: it stops early-returning and starts actually invoking the deploy check. Its outcome is deliberately not predicted here and is captured as evidence at Dev Testing.

### Cross-references

A sibling milestone changes the content of one file this release changes the mode of. The two merge independently; the mode change ships isolated so a rebase cannot absorb it.

---

## Verification Evidence

*Populated by each card's Engineering spoke as its work lands, and consolidated before the review gate.*

### Roster false-positive — Engineering

**Executed.** The QA-as-code suite in read-only mode: **12 PASS / 0 FAIL**. Its member-integrity check independently confirms the suite enrolment landed — it reports all **thirteen** regression members resolving to real test files, where the prior run reported twelve. The deploy-check drift pass: **exit 0**, which also discharges the doc-link integrity check over the modified markdown. Parse checks and static analysis on all three touched shell files: clean, with **no new static-analysis findings**; the two findings the validator carries are present identically at the pre-change baseline and are themselves the corroboration that the Mode A total was a dead constant. Skill-package freshness: **nothing owed by this card** — its four changed paths include none under any module's skills directory.

**One inherited condition, surfaced because it is a likely pre-merge blocker and this release did not cause it.** The drift pass reports three findings. Two are the count-structure pair the upstream card already recorded as pre-existing, in files no card here touches. The third is new since that run and is more consequential: the packaged artifact for one skill is **stale against its own source**, and package freshness is a **hard pre-merge gate**, not a warn-mode advisory. Attribution is unambiguous — the branch is byte-identical to the mainline for both that skill's source and its package, so nothing here introduced it; the source was last changed by an automated dependency bump to a lockfile under that skill's evaluation-viewer tests, two days *after* its package was last rebuilt, and no rebuild followed. The remedy is a single package-rebuild invocation, but the skill is unrelated to this release and rebuilding it here would widen the change set beyond the locked scope. **Routed to the review gate as an operator call rather than absorbed.**

**Residual, re-derived rather than inherited.** The card predicted a post-upstream state of ten passes and one failure. That prediction is superseded and was not carried. Measured against the live deployed mirror at the branch tip, by two independent methods that agree:

| Quantity | Observed | Method |
|---|---|---|
| Deployed skills in the mirror | 54 | directory enumeration |
| Declared in the source roster | 56 | source-tree enumeration |
| Recognised as platform-managed | 52 | set intersection — **non-zero, so the anti-vacuity guard correctly does not fire** |
| Excluded as non-platform | 2 | set difference — exactly the two operator-authored skills the card names |
| In the roster but not deployed | 4 | set difference the other way — correctly ignored, which is the intersection-filter invariant holding on live data |
| Deployed skills lacking a version field, whole mirror | 2 | independent field grep — the same two names, by a different method |
| **Platform-managed skills lacking a version field** | **0** | intersection of the two above |

So the check flips from failing to passing on real operator state, emits one informational record naming the two excluded skills, and stops suppressing the first-task validations. The arithmetic closes in both directions (52 + 2 = 54 deployed; 52 + 4 = 56 declared), and the pass now states that denominator itself.

**What the mode-A total resolves to.** Both sub-modes emit twelve step records, counted directly from each routing function against a control that discriminates. The informational record is excluded by construction, so it does not move the total.

**Not executed, and why.** The four-arm control could not be run from the Engineering session: the destructive-action guard blocks subprocess execution of any script without an allowlist row, and neither the new suite nor the validator it drives carries one. The stdin-redirect and guard-bypass workarounds were declined as evasion of a security control rather than compliance with it, matching the upstream card's call. What was verified instead: both directions of the version-field predicate the arms pivot on were evaluated directly and return one and zero as designed. The runtime command is handed to Dev Testing, which owns the authoritative run.

**Contention held.** Zero shared lines with the upstream card's edit to the same file, verified at line-content level rather than by hunk range: the intersection of the lines that card added with the lines this card removed is empty, against a positive control that returns non-empty when a shared line is deliberately planted, and all twenty-two of its added lines remain present in the merged file.

---

## Deployment Execution Log

*Populated at Stage 12.*

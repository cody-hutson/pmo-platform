<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
---
version: regression-corpus-gates-releases
date: 2026-09-02
type: plan
status: ACTIVE
issues: ["#5863", "#5864"]
pr: "populated at Stage 6"
reversibility-tier: CHEAP
themes: ["cluster:eval-quality"]
---

<!--
The `domain_practice` provenance label has ONE home in this file — the
`### Release Class declaration` H3 below, the placement the Phase A1.5 schema
names. It is deliberately not duplicated into this frontmatter block: a second
copy is a shadow source that drifts the moment one of the two is edited, and the
provenance-survival coverage limb reports a multi-label plan as a visible
ambiguity rather than resolving it silently.
-->

# Release Plan — regression-corpus-gates-releases

> **Status:** Engineering Commit 0 (release branch `release/regression-corpus-gates-releases`).
> **Topology:** D-C SINGLE — one release branch, sequential Engineering commits, one pull request opened after the build completes.
> **Release Class:** `novel` · **Milestone:** `regression-corpus-gates-releases`.
> **Source of record:** this file. The Stage-4 planning sub-task comment was the working reference until this commit landed; from here the plan file is the durable surface every later stage reads.

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. Provisional display value at Engineering Commit 0 is `v4.49`; the concrete number binds only at the Stage-12 atomic claim (ADR-092). The slot is contended — see the Risk Register. |
| **Date Created** | 2026-09-02 (Wednesday) |
| **Release Manager** | Agent-assisted (release hub + stage spokes) |
| **Status** | Executing |
| **Branch** | `release/regression-corpus-gates-releases` |
| **PR** | populated at Stage 6 close (single pull request, opened after the build completes) |
| **Milestone** | regression-corpus-gates-releases |

### Version determination — recomputed at Engineering Commit 0

The version half of the Commit-0 obligation ran before any file in this release was written. Both authoritative surfaces were refreshed from the host first (`git fetch --tags origin`, `git fetch origin main`), and the ledger input was read from the mainline (`git show origin/main:release/releases/RELEASE_LOG.md`) rather than from any worktree copy.

| Field | Value at Commit 0 |
|---|---|
| Bump class (durable) | **minor** |
| Tag anchor | `v4.48` — highest `v4.*` on the remote, signed annotated tag |
| Ledger anchor | `v4.48` — highest version row on the mainline release ledger |
| Sources agree? | **Yes** — both surfaces now carry the claim that was mid-flight at Stage 4 |
| Recomputed next-free (minor) | **`v4.49`** — computed by the repository-host adapter's own allocator, not by hand |
| `v4.49` in the claimed set? | **No** — absent from the remote tag surface |
| Verdict | **PROCEED** — the planned value equals the recomputed next-free and is unclaimed |

The rule applied is `anchor + bump-class floor`, never `max(claimed) + 1`; branch-side claims by sibling releases are non-binding and were not consulted as constraints. The number remains provisional and binds only at the Stage-12 atomic compare-and-swap.

### Release Class declaration

**Release Class: `novel`** — operator-rendered at the Stage-4 plan gate. Consequences carried through the pipeline: Stage 5 activation bias **ALL**, Stage 9 review depth **Deep**, Stage 13 outcome window **30-day**, engagement density **Standard**.

**Domain-practice provenance.** `domain_practice: { source: core/standards/domain-best-practices/software.md, date: 2026-09-02, domain: software }`

**Transcription note, stated rather than left implicit.** Stage 4 emitted this label in the pipeline-internal exemption form (`source: N/A — pipeline-internal release`) on the reasoning that the File Change Matrix consists entirely of internal platform artifacts. Stage 5 ran the § 5.7 sourcing step again and recorded a **Mode B → Mode A upgrade**: the software domain guide exists, its Applicability Profile (`APPLIES-WHEN: deliverable domain == software`) is satisfied because the dominant deliverable is executable code, and no contraindication fires. The label above carries the Stage-5 determination — the guide actually consulted — because it is the later and more specific of the two, and carrying the superseded exemption form would silently discard a determination a downstream stage reads. The two design frameworks Stage 5 cited alongside the guide are recorded here in prose rather than inside the label body: a design-pattern catalogue (Gang of Four, 1994) and the architecture-decision-record form (Nygard, 2011), both external-tertiary. `domain: software` rather than `governance` because the dominant deliverable is an executable runner; the secondary domain is `governance` (four bounded documentation edits and two decision records).

### Baseline pin

- **Stage-4 planning baseline:** `origin/main` @ `4f7e1ce3`. Every Stage-4 and Stage-5 probe was run against that commit.
- **Engineering Commit-0 baseline:** `origin/main` @ `3659f97f`. The mainline advanced by 27 files between the two pins while the Stage-5 spokes ran, carrying a sibling release's Stage-12 and Stage-13 corpus commits.
- **Divergence check on this release's surface: ZERO.** The set difference of changed paths against this release's File Change Matrix surface is empty over a denominator of 27 changed files, with a sensitivity arm on the `core/` prefix returning 20 — so the instrument reached the population and the zero is a measured absence, not an unreachable one. No change specification is invalidated by the advance.

## Scope

### Issues Included

| # | Issue | Title | Priority | Category | Labels |
|---|-------|-------|----------|----------|--------|
| 1 | #5863 | Build the output-scoring scenario runner the eval suite was opened for | P2 | Enhancement | `size:L`, `type:story`, `cluster:eval-quality` |
| 2 | #5864 | Gate major releases on a behavioural regression corpus pass rate | P2 | Enhancement | `size:L`, `type:story`, `cluster:eval-quality` |

### Dependency Graph

#### Topologically Sorted Sequence

| Position | Issue | Priority | Status | Dependencies (in-release) | Edge Type |
|---|---|---|---|---|---|
| 1 | #5863 | P2 | in-progress | (none — root) | — |
| 2 | #5864 | P2 | bundled | #5863 | BLOCKS |

**One edge, zero cycles.** The edge is registered in the repository host's dependencies API in both directions, not merely asserted in prose: the runner card reports the gate card as blocked by it, and the gate card reports the reciprocal. It was validated at Stage 4 rather than adopted on the milestone description's assertion.

**Classification: BUILD-BLOCKING, not ship-gating.** The gate card's pass-rate extraction, its invocation of the corpus, and both of its control-arm acceptance criteria are unverifiable until the runner executes. Because the release ships as one pull request on one branch, ship-order enforcement is structurally unnecessary; the classification is load-bearing for Stage-6 dispatch order alone, and there it binds — Engineering serializes.

**The seam is narrower than the whole card.** The runner's report contract and CLI invocation signature are an early deliverable of the runner card, not its last. Once frozen, the gate card's corpus authoring and workflow scaffold proceed against them while the runner's scoring internals are still being built. Stage 5 froze both deliberately; that freeze is this release's principal parallelization lever and it is discharged.

#### Artifact Relationship Graph

| Source | Type | Target | Direction | Derived from |
|---|---|---|---|---|
| #5863 | BLOCKS | #5864 | #5863 → #5864 | native `blocking` / `blocked-by` edge in the dependencies API |
| #5863 | GENERATES | release/skills/pmo-skill-refiner/scripts/run_scenario_eval.py | #5863 → file | File Change Matrix (add) |
| #5863 | GENERATES | release/skills/pmo-skill-refiner/references/scenario-eval-contract.md | #5863 → file | File Change Matrix (add) |
| #5864 | GENERATES | .github/workflows/behavioral-regression.yml | #5864 → file | File Change Matrix (add) |
| #5864 | GENERATES | core/disciplines/evals/behavioral-regression/evals.json | #5864 → file | File Change Matrix (add) |

#### Tie-Breaker Trace

No ties existed in the emission — the two-node graph has exactly one edge and a single admissible order.

### File Change Matrix

Intent markers use the `add | edit | delete` enum. Path-first columnar form inside the fence. The `#5863` block is delivered by this Engineering spoke; the `#5864` block is delivered by the spoke that follows it on this branch.

```
# ── Adds (#5863 — the output-scoring runner) ──
release/releases/plans/regression-corpus-gates-releases_RELEASE_PLAN.md          add
release/skills/pmo-skill-refiner/scripts/run_scenario_eval.py                    add
release/skills/pmo-skill-refiner/references/scenario-eval-contract.md            add
release/skills/pmo-skill-refiner/evals/scenario-runner/evals.json                add
release/skills/pmo-skill-refiner/evals/scenario-runner/fixtures/baseline.yaml    add
release/skills/pmo-skill-refiner/evals/scenario-runner/fixtures/regressed.yaml   add
release/skills/pmo-skill-refiner/evals/scenario-runner/fixtures/empty.yaml       add
core/ADRs/ADR-182-output-scoring-runner-consumes-the-shipped-eval-harness-schema.md   add
release/ADRs/ADR-181-behavioral-regression-floor-and-major-release-binding-boundary.md   add

# ── Edits (#5863 — derived-surface consequence of the decision-record add) ──
release/ADRs/README.md                                                           edit

# ── Edits (#5863 — bounded documentation reconciliation) ──
release/skills/pmo-skill-refiner/references/schemas.md                           edit
release/skills/pmo-skill-refiner/references/eval-framework.md                    edit
release/skills/pmo-skill-refiner/SKILL.md                                        edit
core/skills/eval-writer/SKILL.md                                                 edit

# ── Edits (#5863 — package consequence of the two skill-file edits above) ──
packages/pmo-skill-refiner.skill                                                 edit
packages/pmo-skill-refiner.skill.sha256                                          edit
packages/eval-writer.skill                                                       edit
packages/eval-writer.skill.sha256                                                edit

# ── Adds (#5864 — the corpus and its gate) ──
core/disciplines/evals/behavioral-regression/README.md                           add
core/disciplines/evals/behavioral-regression/evals.json                          add
core/disciplines/evals/behavioral-regression/rubrics.md                          add
core/disciplines/evals/behavioral-regression/fixtures/                           add
core/disciplines/evals/behavioral-regression/judge_prompts/                      add
.github/workflows/behavioral-regression.yml                                      add
.github/behavioral-regression.enforce                                            add

# ── Edits (#5864) ──
core/config/platform-config.toml.template                                        edit
core/schemas/platform-config-schema.md                                           edit
docs/platform-config-reference.md                                                edit
core/standards/gate-efficacy-standard.md                                         edit
core/standards/regression-checks.md                                              edit    (LAST, ONCE — the single coordinated edit)
packages/pmo-skill-editor.skill                                                  edit    (consequence of the line above)
packages/pmo-skill-editor.skill.sha256                                           edit

# ── Release-wide explicit non-scope ──
release/skills/pmo-skill-refiner/scripts/run_eval.py                                     NOT EDITED
core/skills/skill-compliance-auditor/references/scenario-and-calibration-schema.md       NOT EDITED
```

**The `CONDITIONAL:schema-extension-selected` row from Stage 4 resolved to NOT-FIRED.** Stage 4 recorded a conditional row against the trigger-rate schema under `skill-compliance-auditor`, to be promoted into the unconditional set if the schema decision selected an extension of it. Stage 5 selected a third option — adopt the eval-harness schema the platform already ships — so the condition did not fire and the row is recorded above as explicit non-scope rather than dropped. Recording the non-firing positively is what stops a later reader from reading the absence as an oversight.

**`run_eval.py` is explicit non-scope, not merely absent.** The runner card's second acceptance criterion requires that the trigger-eval path be unchanged. The file therefore carries an explicit `NOT EDITED` row, and the criterion's verification is a mechanical assertion over the delivered diff.

**The release-module decision-record index is a derived surface, not a hand-maintained one.** Adding a record under `release/ADRs/` obliges a regeneration of that module's index by its own projector, and a hand-added row fails the projector's verification. The core module's record README is the opposite by decision — a curated thematic document that has never enumerated the full record set — so the core record added here correctly adds no row anywhere.

**Both decision records are authored by this release's first Engineering spoke.** The record under `release/ADRs/` belongs to the gate card's decisions, and its content was settled in full at Solutioning with no dependency on implementation, so it is authored at Commit 0 rather than deferred. The gate card's spoke **consumes** it and must not allocate a second record number for the same decisions.

**Package-rebuild obligation.** Two rostered skills have `SKILL.md` or `references/` content edited, and both ship distribution packages with committed content-baseline sidecars. The freshness assertion is content-based, not modification-time-based, so a fresh checkout does not mask staleness. Both packages and both sidecars are rebuilt with the platform's own package builder and committed alongside the edits that stale them. The third package listed above is staled by the gate card's coordinated edit, because the standard it edits is a registered template-sync mirror shipped inside that package; that rebuild belongs to the gate card's Engineering spoke.

### File Contention Map

| Path | This milestone | Contends with (other milestones) |
|---|---|---|
| `core/standards/regression-checks.md` | #5863 (pointer), #5864 (corpus + threshold + failure semantics) | none |
| every other path in the matrix | one issue each | none |

**One within-release contention point, and this release's design removed one of its two claimants.** Stage 4 recorded both cards as editing the regression standard. Stage 5's design for the runner card places the runner's own contract in a dedicated reference document under the skill that owns the eval framework, so the runner card does **not** edit the standard at all. The coordinated edit is therefore a single-writer edit made once, last, by the gate card's spoke — an ordering constraint on one branch, never a merge conflict.

**Cross-PR contention: ZERO on the shared surface,** measured at the Stage-4 pin over a denominator of 130 sibling editset paths across 7 sibling releases, with a fired sensitivity arm on the `core/standards/` prefix (3 hits) and a zero specificity arm. The directory-level intersections with sibling releases under the workflows directory are co-location, not contention: four sibling-touched workflow files exist and this release adds a new one.

### Cross-Milestone Dependency Validation

#### G3-07 Status

`PASS — 1 dependency edge checked, 0 cross-milestone violations`

Both endpoints of the single edge sit in this milestone, so no cross-milestone gap can arise.

#### Violations

N/A — enumerated over the one in-release dependency edge and over both cards' body `Dependencies` fields; no edge crosses a milestone boundary, so no violation class is reachable.

#### Registered Exceptions

N/A — enumerated over the violation set above, which is empty; no exception was needed or registered.

### Bundle Refresh State

N/A — enumerated over the four refresh triggers (new approved theme-matching issues, priority shift, dependency-state change, stage-4 boundary). None fired non-no-op since the bundle was composed, so the conditional section is correctly absent in substance and present in form.

### Exclusions

Items explicitly NOT in this release and why:

- **The LLM-judge scoring layer.** The runner executes the deterministic assertion types only. The judgment and acceptance types stay runner-inert after this release, so the deferred runner-wiring commitment recorded in the acceptance-assertion-type decision record is **partially**, not fully, discharged. Stage 6 must not overclaim it as closed.
- **The absence-reads-as-zero default in the benchmark aggregator.** A missing pass rate is read as total failure by a shipped consumer. It is a pre-existing defect, outside both cards' acceptance criteria, and changing it is a behaviour change to a shipped consumer. Routed as a next-release item, not fixed here.
- **A corpus-wide disambiguation of the bare `pass_rate` token.** Three unrelated metrics share the name. The design mitigates it by requiring every consumer to parse the fully-qualified path; renaming across the corpus is a larger governance change than this release warrants.
- **Promotion of the runner into the shared kernel.** Argued and rejected for this release — relocating the eval framework is a strictly larger change than adding its missing executor. A clean follow-up if a consumer outside the release module emerges.

## Implementation Sequence

Single branch, serial dispatch (**D-Concurrency Posture: P0 fully-serial** — the default when undeclared, and correct here on a build-blocking edge plus a genuine within-release contention).

| # | Work | Card | Gate to advance |
|---|---|---|---|
| 1 | Freeze the consumed-schema decision | #5863 | **DONE at Stage 5** — adopt the shipped eval-harness schema; rationale and four-candidate exploration recorded in the decision record this release adds |
| 2 | Freeze the report contract and CLI invocation signature — the seam the gate card binds to | #5863 | **DONE at Stage 5** — contract, pass-rate field, CLI flags and the closed exit-code set all frozen |
| 3 | Build the output-scoring runner; commit baseline and deliberately-regressed fixtures | #5863 | AC-1, AC-2, AC-3 pass — regressed scores below baseline, control arm at baseline |
| 4 | Author the corpus (more than one scenario) against the frozen schema | #5864 | AC-1 — corpus runs on demand through the step-3 runner |
| 5 | Wire the CI gate: invoke corpus, compare to threshold, fail below | #5864 | AC-2, AC-3 — gate fails below and passes above |
| 6 | Record the threshold and release boundary as data, not code | #5864 | AC-4 |
| 7 | **Single coordinated edit** to the regression standard — runner pointer, corpus location, threshold by role, failure semantics — written as one coherent section | #5864 (sole writer) | CIAC-3 — the standard reads as one coherent account |

Step 7 is deliberately last and deliberately single-writer. Stage 5's design removed the runner card from the file entirely, so there is exactly one writer rather than two sequenced ones.

### Issue #5863: Build the output-scoring scenario runner the eval suite was opened for

**Change Specification:**

- **Files modified:** the nine adds and four bounded edits in the `#5863` blocks of the File Change Matrix, plus the two package rebuilds they stale.
- **Change description:** add an output-scoring runner that consumes the eval-harness schema the platform already ships, extended by exactly one optional field — a declarative predicate object on each graded assertion. The predicate vocabulary is a closed five-value set derived by construction from the deterministic values already in the assertion-type enum, so the runner adds no new semantics; it makes executable the semantics the enum already declares and the eval-authoring skill records as unexecuted. An assertion carrying no predicate is ungraded and leaves both numerator and denominator, so every suite already in the corpus remains valid input unmodified. The runner emits the report contract the framework already defines, adds no second definition of it, and writes no report at all when nothing was gradable. Four bounded documentation edits reconcile the surfaces this design touches to what the corpus actually contains.
- **Acceptance criteria:** four, transcribed verbatim into the Verification Plan below.
- **Estimated complexity:** Medium.
- **Dependencies:** None — this is the root of the single in-release edge.

### Issue #5864: Gate major releases on a behavioural regression corpus pass rate

**Change Specification:**

- **Files modified:** the seven adds and six edits in the `#5864` blocks of the File Change Matrix, plus the package rebuild the standard edit stales.
- **Change description:** add a standing behavioural-regression corpus as a new suite in the platform's existing cross-skill eval home, and a gate that runs it. The pass-rate floor is recorded once, as a single numeric field in the platform behaviour configuration; no other surface restates the number. The gate binds at the major-release tag boundary and additionally runs advisory on every pull request, so it is exercised continuously rather than quarterly. The workflow reads the floor from configuration and passes it to the runner as a command-line value; the runner performs the comparison and sets the exit status, and the gate consumes only that exit status.
- **Acceptance criteria:** four, transcribed verbatim into the Verification Plan below.
- **Estimated complexity:** Medium.
- **Dependencies:** #5863 — build-blocking.

## Stage Applicability Matrix

| Stage | #5863 | #5864 | Basis |
|---|---|---|---|
| 5 Solutioning | APPLY | APPLY | Both cards defer genuine design decisions; Release Class `novel` sets activation bias ALL, which agrees independently |
| 6 Engineering | APPLY | APPLY | — |
| 7 Dev Testing | APPLY | APPLY | Both ship executable artifacts; the no-functional-impact skip cannot fire |
| 8 QA / Acceptance | APPLY | APPLY | Both carry control-arm criteria that must be graded in both directions — precisely the case a skip would lose |
| 9 Plan Review | APPLY | APPLY | Release Class `novel` → review depth Deep |
| 10–13 | APPLY | APPLY | Standard |

**Parallel-eligible spoke count:** Stage 5 = 2 · Stage 7 = 2 · Stage 8 = 2. No stage is skipped for either card, so the matrix contributes no reduction. Stage 6 runs serial regardless, on the build-blocking edge.

## Cross-PR Overlap Audit

### In-Flight Release Roster

**Measured at the Stage-4 pin, `4f7e1ce3`. Population: 7 siblings** (6 with an open pull request, 1 remote head with none).

| Slug | Bump class | Recomputed next-free | Editset ∩ this release's surface |
|---|---|---|---|
| `adr-corpus-integrity` | minor | v4.48 at pin | two workflow files — different files |
| `hooks-block-only-their-scope` | minor | v4.48 at pin | — |
| `hub-spoke-run-and-planning-discipline` | UNRESOLVABLE | UNRESOLVABLE | two workflow files — different files |
| `kit-unit-and-selection` | minor | v4.48 at pin | — |
| `label-and-reference-integrity` | minor | v4.46 at pin (stale) | one workflow file — different file |
| `operational-folder-enforcement-migration` | UNRESOLVABLE | UNRESOLVABLE | — (editset 0) |
| `pda-decisions-and-conformance-baseline` | UNRESOLVABLE | UNRESOLVABLE | — |

**The version-axis exposure is live and moved once already.** One sibling in this roster claimed the slot this release had provisionally computed, while the Stage-4 planning spoke was still running. The recorded determination was correct both times and the rule never changed; only the anchor advanced. Three siblings remain ahead of this release, so the exposure persists for the recomputed slot.

**Structural blast radius: none.** No sibling declares a rename, relocation, or deletion touching this release's surface, so no serialization edge arises from a mover collision.

## Risk Register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|-----------|-------|
| 1 | **Version-slot contention.** Three in-flight siblings remain ahead of this release and any may claim the recomputed slot before Stage 12. | High | Low | **No action, by design.** The recorded determination is correct: the rule is anchor plus bump-class floor, and branch-side claims are non-binding. The Commit-0 re-verify (discharged above) and the Stage-12 atomic compare-and-swap are the two resolving rungs. Pre-emptive renumbering would violate the allocation rule. | Stage 12 |
| 2 | **Consumed-schema ambiguity.** The runner card cites a trigger-rate schema as the schema its output-scoring runner consumes. Building against it would yield a runner that scores nothing while satisfying the letter of the first criterion. | High | High | **RESOLVED at Stage 5.** The citation was confirmed wrong and classified a refinement rather than a premise failure; the design adopts the shipped eval-harness schema instead, and the decision record this release adds carries the four-candidate exploration and the rationale. | Stage 5 — closed |
| 3 | **Duplicate corpus.** The gate card defers the corpus location while the regression standard already carries eight categories of behavioural checks in manual prose. Authoring a parallel corpus would create two homes for one fact. | Medium | Medium | **RESOLVED at Stage 5.** The standard is an assertion bank with zero fixtures, not a corpus; the corpus supplies the scenario-and-fixture layer the bank never carried and cites the check definitions by identifier. The standard keeps single-source authority over the definitions. | Stage 5 — closed |
| 4 | **A gate that cannot fail in practice.** A synthetic control arm proves the gate *can* fail; it does not prove a real regression trips the threshold. A threshold set too loose ships a green gate that never fires. | High | High | Two structural defenses rather than discipline. The runner writes **no report and exits with a distinct status** when nothing was gradable, so an all-ungraded corpus cannot produce a green pass rate — it produces no pass rate at all. And the gate runs advisory on every pull request rather than only at the release boundary, so both control arms are exercised continuously. CIAC-1 composes the two cards' control arms end-to-end. | Stage 8 |
| 5 | **Contention on the regression standard.** Two cards editing one 582-line file; an uncoordinated second write contradicts or strands the first. | Low | Low | Reduced to a single-writer edit by the Stage-5 design — see the File Contention Map. CIAC-3 grades the result. | Stage 6 |
| 6 | **Report contract emerges late,** lengthening the serial chain to the full width of both cards. | Medium | Medium | **RESOLVED at Stage 5.** Contract, pass-rate field, CLI signature and exit codes were all frozen before Engineering began, and both Stage-5 spokes converged on the same seam independently. | Stage 5 — closed |
| 7 | **Mid-pipeline divergence.** The audit is baseline-pinned; sibling pull requests are open and several are near merge, so contention can appear after the pin. | Medium | Medium | Re-checked at Engineering Commit 0 against the advanced mainline — zero divergence on this release's surface, measured with a fired sensitivity arm. Stage 9 re-checks as the primary halt-eligible rung; Stage 12 is the last resort. | Stage 9 |

**Rollback strategy.** Both deliverables are additive. The runner is a separate module and does not modify the trigger-eval path, so reverting it cannot disturb trigger detection. The gate is a new workflow file; reverting removes the gate and restores the current ungated state. The single edit to the regression standard reverts with its commit. No migration, no data, no state. **Whole-release reversibility: CHEAP / Confidence HIGH.** One caveat worth stating: once a corpus gate exists and passes, downstream releases begin relying on it, so rollback is cheap now and grows more expensive with each release that trusts the gate.

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered) — P0 fully-serial on the build-blocking edge |
| **Commit strategy** | Grouped commits, one per coherent slice, pushed as each slice lands rather than banked to a terminal push |
| **Review approach** | Single pull request for the entire release |
| **Deployment mechanism** | Git merge + skill-package rebuild; no operations-tier propagation target |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dependency (default — Option A). No stacked-base wave is planned. |

## Verification Plan

**Acceptance-criterion baseline, as read at plan time** against `origin/main` @ `3659f97f`: #5863 = 4 criteria · #5864 = 4 criteria. A criterion count that no longer matches this baseline is a mechanical signal to re-bind the rows below.

`ac_baseline: { #5863: 4, #5864: 4, read_at: 3659f97f0788e2203e532273ecf5fb647d4d7338 }`

### Per-Issue Verification

**Why every method cell below is a `grep` / `test` / `ls` probe rather than the command a reader would actually run.** The plan-verification executor holds a deliberately closed read-only verb set — `grep test ls head wc cat` — and refuses `python3`, `bash` and `git` by design, because a verification harness driven by an authored artifact must not acquire a code-execution channel. It also classifies a row by **method-string keyword only**: the `Predicate class` column below is authored, parsed, and then deliberately not wired to the classifier (its single call site passes an empty hint), so a prose method cell reaches no family and grades as an unclassifiable error rather than as a check. Rows are therefore authored in **two arms**, the pattern the corpus already uses: a **mechanical arm** the executor can run and grade now, and a **runnable arm** — named, required, and re-executed at Stage 7 — that carries the substantive behavioural claim a text probe cannot make. Every threshold below is **pinned to a measurement taken at Commit 0**, not chosen; a threshold set without measuring its baseline produces a false verdict in whichever direction it misses.

| Issue | AC | Predicate class | Verification Method | Expected Result |
|-------|----|---|-------------------|----------------|
| #5863 | AC-1 | file-content | `grep -c '"check"' release/skills/pmo-skill-refiner/evals/scenario-runner/evals.json` ≥ 11 | Two arms. *Mechanical:* the committed suite declares 11 graded predicates across 2 scenarios, so there is something to score end-to-end; measured 11 at Commit 0, and 0 before this release because the file did not exist. *Runnable arm, required:* `python3 -m scripts.run_scenario_eval --suite evals/scenario-runner/evals.json --out <run>/grading.json` from `release/skills/pmo-skill-refiner/` exits 0 and writes a report carrying `summary.pass_rate` of `1.0` over the committed baseline fixture. Scored from committed inputs with no live model call, so the run is reproducible rather than sampled. |
| #5863 | AC-2 | file-content | `test -f release/skills/pmo-skill-refiner/scripts/run_eval.py` | Two arms, split because the second is structurally outside this executor's reach — it excludes `git` from its runnable verb set by design, so a diff assertion cannot be graded here. *Mechanical:* the trigger runner still exists at head, alongside the new one. *Reviewer arm, required:* the delivered diff does **not** list `release/skills/pmo-skill-refiner/scripts/run_eval.py`. Measured at Commit 0 over the 18-path delivered diff: **0** occurrences · *control, same instrument and same target:* `run_scenario_eval.py` in that same list returns **1**, so the extraction reaches the directory and the zero is a measured absence rather than an unreachable one. The trigger-eval path is unchanged. |
| #5863 | AC-3 | file-content | `test -f release/skills/pmo-skill-refiner/evals/scenario-runner/fixtures/regressed.yaml` | Two arms. *Mechanical:* the three committed fixtures — unregressed baseline, deliberately-regressed subject, structurally-empty control — exist; measured 3 at Commit 0, 0 before. *Runnable arm, required:* running the same suite against the baseline and then against the regressed fixture yields a **strictly lower** pass rate for the regressed input, with the baseline at ceiling. Measured at Commit 0: baseline `1.0000` exit 0, regressed `0.5455` exit 1 · control arm: the unregressed fixture scores at baseline, proving the score discriminates rather than always passing. A second, declarative control ships inside the suite — every resolution predicate is re-run against the empty fixture and **all** must fail; that arm was itself mutation-tested by pointing the control at the baseline, which correctly reported 5 spurious resolutions and forced exit 1. |
| #5863 | AC-4 | file-content | `grep -c 'fail-under' release/skills/pmo-skill-refiner/references/scenario-eval-contract.md` ≥ 5 | Two arms. *Mechanical:* the contract document names the threshold flag in the command-line signature, the exit-code table and the gate-consumption note; measured 5 at Commit 0, 0 before. *Reviewer arm, required:* read the document **without opening the runner source** and confirm it carries the scenario schema, the closed predicate vocabulary with each member's shape, the suite-level control block, the command-line signature and the closed exit-code set, with the grading fields **cited** to the framework's schema document rather than restated. The acid test is the second suite: the gate card authors its corpus from this document alone. |
| #5864 | AC-1 | file-content | `grep -c '"assertions"' core/disciplines/evals/behavioral-regression/evals.json` ≥ 2 | Two arms. *Mechanical:* the corpus carries more than one scenario, each with graded statements. Baseline **0** — the file does not exist at Commit 0, so this row reads FAIL until the gate card's spoke lands it, which is the correct signal rather than a premature green. *Runnable arm, required:* the corpus scores end-to-end through the runner delivered by #5863, via the same documented interface a third corpus would use — no corpus-specific code path in the runner and no runner-specific logic in the corpus. |
| #5864 | AC-2 | file-content | `grep -c 'v\*\.00' .github/workflows/behavioral-regression.yml` ≥ 1 | Two arms. *Mechanical:* the workflow's trigger block names the major-release tag pattern literally. Baseline **0** — the file does not exist at Commit 0. *Reviewer arm, required:* the trigger block is legible in one read — a filter-free pull-request rung that exercises the gate every release, and a tag rung bound to the major-release boundary — with both visible without reading a script, which is what this criterion's stated method inspects. |
| #5864 | AC-3 | file-content | `grep -c 'behavioral-regression' .github/workflows/behavioral-regression.yml` ≥ 1 | Two arms. *Mechanical:* the gate job exists and is named for behavioural regression rather than for a colliding corpus token. Baseline **0**. *Runnable arm, required:* dispatch the gate against the regressed fixture and against the baseline fixture — it **FAILS** on the regressed input and **PASSES** on the baseline · control: it passes when above, proving it can fail. The tag-pattern filter is separately asserted by a committed fixture through an entry point invocable locally **and** invoked by the job; a filter verified only by reading its glob is unverified. |
| #5864 | AC-4 | file-content | `grep -c 'pass_rate_floor' core/schemas/platform-config-schema.md` ≥ 1 | Two arms. *Mechanical:* the floor carries a declared field row in the configuration schema. Baseline **0**. *Reviewer arm, required:* confirm the magnitude is recorded in exactly **one** numeric home and restated on no other surface — the regression standard names the field by role only — and that an unresolvable floor fails closed. Empty means unresolved, never zero: a zero default satisfies every comparison and greens the gate permanently. |

**The four `#5864` rows do not grade at Engineering Commit 0, and that is the correct reading rather than a defect.** Their subjects are the gate card's deliverables and this release is fully serial, so at Commit 0 three of the four probe a file that does not yet exist (unreadable → error) and the fourth probes an existing file that does not yet carry the token (readable → fail). Both are honest signals of undelivered work, and they are the same signal the file-change-matrix delivery limb reports for the same seven paths. They self-correct as the gate card's spoke lands its files, and they are graded for real at Stage 7 and Stage 8, when the whole release is on the branch. A deferral marker was considered and rejected: it would report a skip *after* the files land, which is worse than an error that resolves itself.

### Release-Level Verification

- File integrity: every declared add exists at its declared path on the merged branch; no declared non-scope file appears in the diff.
- Content correctness: the runner's own suite scores at baseline on the committed baseline fixture and strictly below it on the regressed fixture.
- Cross-reference validity: every internal link in every modified markdown file resolves, including anchors.
- Skill-package freshness: every edited rostered skill's package and its content-baseline sidecar are rebuilt and committed in the same change.
- Output-contract compliance: the emitted report carries exactly the keys the frozen contract names and no stubbed extras.
- Decision-record integrity: the record numbering is gap-free and duplicate-free across both record directories on the merged branch.

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**

- [ ] **CIAC-1 (#5863 × #5864 on the score→pass-rate→threshold path):** the deliberately-regressed fixture that satisfies the runner card's third criterion must, when run through the gate card's corpus and gate, drive the pass rate **below** the recorded floor and cause the gate to FAIL — and the unregressed baseline fixture must drive it above and PASS. The two control arms must compose end-to-end, not merely hold independently. *Shared surface:* the runner's exit status, as consumed by the gate. *Method:* `dispatch the corpus gate against both the baseline and the regressed fixtures; assert exit-status FAIL on regressed and PASS on baseline`. *Graded at Stage 9 on the merged pull request.*
- [ ] **CIAC-2 (#5863 × #5864 on the report contract):** exactly **one** definition of the report contract exists in the merged tree. The runner card documents it by citation to the framework's existing schema document; the gate card consumes the runner's **exit status** and never parses the report at all. *Shared surface:* the runner's reference document and the gate's workflow file. *Method:* `grep -rn "summary.pass_rate" --include=*.md --include=*.yml .` → the qualified field appears in the framework schema document as its definition and in the runner's reference document as a citation, and **null limb** — zero occurrences in the workflow file, because the workflow never reads the report. *Control (same instrument, same target):* the same search for the defining document must return at least one non-zero hit, proving the pattern and paths resolve. *Graded at Stage 9 on the merged pull request.* **This criterion is satisfied structurally rather than by discipline** — the workflow cannot restate a field it never reads.
- [ ] **CIAC-3 (#5863 × #5864 on `core/standards/regression-checks.md`):** after both cards land, the standard reads as **one** coherent account — a reader arriving at it can reach the runner, the corpus location, the threshold by role, and what a failing run means for a release, with no contradiction and no orphaned pointer. *Shared surface:* `core/standards/regression-checks.md`. *Method:* `anchor-resolution over core/standards/regression-checks.md: every added pointer resolves to an existing path, and the corpus/threshold/failure-semantics statements are mutually consistent` — reviewer read plus link resolution. *Graded at Stage 9 on the merged pull request.* **Note that this release reduced the file to a single writer:** the runner card does not edit it, so "no contradiction between two cards' additions" is satisfied by construction and the remaining grading is whether the one added section is internally coherent and its pointers resolve.

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #5863 | `git revert` of the runner commits | Low — every deliverable is additive and the trigger-eval path is untouched |
| #5864 | `git revert` of the gate commits | Low — the gate is a new workflow file; reverting restores the current ungated state |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated issue failure | Revert the specific commits |
| **Full Restore** | Systemic failure | Revert the merge commit with `git revert -m 1`, which requires the merge to be taken as a two-parent merge commit rather than a squash |
| **Forward Fix** | Minor issue, fix well understood | Fix branch |

## Operational Deployment Manifest

N/A — enumerated over the two propagation classes the manifest recognizes: installed skill copies and schema migrations. This release edits two rostered skills, and their propagation target is the committed distribution package rebuilt in the same change rather than an operations-tier file copy; there is no operations-tier target and no migration. The deliverable end state for every artifact in this release is therefore `deployed-copy-synced` by way of the package rebuild.

### Schema Migrations (if applicable)

N/A — enumerated over every schema this release touches: the eval-harness input schema gains one **optional** field, so every existing suite remains valid input unmodified, and the report contract gains no field a consumer must migrate to. No migration step exists.

## Quota Budget

**Verdict:** PASS (Checkpoint A)
**Parallel-eligible spokes per parallel stage:** Stage 5: 2 · Stage 7: 2 · Stage 8: 2
**Per-spoke cost estimate:** moderate–high ordinal band — both cards are `size:L` (source: size-bucket ordinal heuristic; the per-bucket cutover to observed medians was not established, so the ordinal band binds as the retained floor)
**Assumed/stated remaining usage-window envelope:** `UNSTATED` — no quota band was stated at hub start; the conservative default applies
**Estimated cumulative draw % (worst parallel batch):** not rendered. When no band is stated the check renders the basis as `UNSTATED` and does not synthesize a figure — a sourced-looking percentage this session could not have obtained would be worse than none. `[ASSUMPTION – CONFIRM]`
**Routing:** PASS — proceed parallel; no warning in plan. The worst parallel batch is 2 spokes, and no contention makes that width unrealizable. Stage 6 runs serial regardless.

## Deviation Log

| # | Deviation | Stage | Rationale | Disposition |
|---|---|---|---|---|
| D-1 | The `domain_practice` label carries Stage 5's Mode-A determination rather than the Stage-4 exemption form the Commit-0 transcription instruction named. | 6 | Stage 5 re-ran the sourcing step and recorded a Mode B → Mode A upgrade. Carrying the superseded exemption form would silently discard a determination that a downstream close-class rung reads. Separately, the literal string Stage 5 emitted — a bracketed framework citation — is outside the closed source grammar the mechanical guard recognizes, so it would have registered as an unrecognized form; the guide file Stage 5 actually consulted is the grammar-conformant expression of the same determination. Both facts are disclosed in the transcription note beside the label. | Recorded, not escalated — Tier 1 |

## Change Description

### Outcome

This release gives the platform a way to catch a change to one skill silently regressing another. It ships the **output-scoring runner** the eval suite was opened for — the missing executor for a schema and a report contract the platform had already declared and left inert — plus a standing **behavioural-regression corpus** and the CI gate that runs it against a recorded pass-rate floor. At Stage 9 Plan Review the operator sees a runner that scores a committed scenario end-to-end and discriminates a deliberately-regressed fixture from its baseline, a gate that runs advisory on every pull request and binds at the major-release boundary, and a threshold recorded as data in exactly one place. Before this release, nothing in the tree could fail on a behavioural regression.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #5863 | An output-scoring runner that grades a suite's assertions against a committed fixture, emits the framework's existing report contract, and refuses to report a pass rate when nothing was gradable | DONE |
| #5864 | A behavioural-regression corpus and the gate that runs it against a recorded floor, advisory on every pull request and binding at the major-release tag | DONE |

### Key decisions

- **D-Version-R2:** bump class `minor`. The slot this release provisionally held was claimed by a concurrent release mid-planning; the rule never moved, only the anchor. Recomputed at Commit 0 against both authoritative surfaces, which now agree.
- **D-Concurrency Posture:** `P0` fully-serial. A build-blocking edge plus a genuine within-release file contention; Engineering runs one spoke at a time on one branch.
- **D-ReleaseClass:** `novel` — new runner, new corpus, new workflow, and three D-class decisions in the plan.
- **ADR-182 (consumed schema):** the runner consumes the eval-harness schema the platform already ships, rather than the trigger-rate schema the commissioning item cites or a new one. The citation was wrong; the delta is one optional field, so no existing suite needs migrating.
- **ADR-181 (floor and boundary):** the floor is recorded once as a numeric configuration field and restated nowhere; the gate binds at the major-release tag and runs advisory on every pull request, because a gate bound only to a boundary this platform crosses about quarterly would ship months before its first real exercise.
- **The contract gained a SECOND optional field, on operator authorization mid-release.** The schema delta ADR-182 records is one optional field, and that record stands as written — it is a dated decision, not a live rule. What shipped is two: `assertions[].check`, and `assertions[].expect`, added to discharge the open integration criterion the corpus needed. The count moved; the ADR's stated bound did not, because that bound is backward compatibility rather than arithmetic — `expect` defaults to the identity, so every suite committed before it existed scores byte-identically, verified by comparing the upstream card's own reports across the amendment. Recorded here rather than by editing an accepted decision record.
- **The advisory rung is non-blocking in the tree, not merely unregistered.** The workflow itself enforces the context clause of the blocking predicate. Branch protection is repository settings, lives outside the tree, and no committed file can state which contexts are required — so leaving "the pull-request rung never blocks" to non-membership would have made a load-bearing property contingent on a fact nothing here can assert.

### Reversibility

**CHEAP — HIGH confidence.** Every deliverable is additive. `git revert` of the release commits removes the runner, the corpus and the gate and restores the current ungated state; the trigger-eval path is not modified, so no revert can disturb trigger detection. The one caveat, stated rather than buried: once a corpus gate exists and passes, downstream releases begin relying on it, so rollback grows more expensive with each release that trusts the gate.

### Downstream impact

- The eval-harness schema now has a **deterministic** producer of the pass-rate field alongside the model-judged one, so a benchmark aggregate can mix reproducible and sampled runs. A reader of that aggregate needs to know which producer wrote each run.
- The deferred runner-wiring commitment recorded in the acceptance-assertion-type decision is **partially**, not fully, discharged — the model-judged assertion types stay runner-inert. Do not read it as closed.
- The regression standard becomes a pointer surface as well as a definition surface: a reader arriving there finds the runner, the corpus, the threshold by role, and the failure semantics.
- One package rebuild is coupled to a documentation edit in a non-obvious way — the standard is a registered mirror shipped inside a skill package — and that coupling is invisible from the standard itself.
- A consumer of the eval framework now exists outside the module that owns it, which is the trigger for revisiting whether the runner belongs in the shared kernel.
- **The platform acquires a 23rd workflow and a new branch-protection context**, `Behavioral-regression pass-rate gate`. It shares no identifier token with the existing release-documentation gate, so the two contexts cannot be conflated by a reader of the settings page — but registering it is an operator action outside the tree, and until it happens the gate reports without being required even after the sentinel flips.
- **The corpus ships thin — 3 scenarios — and that is the reason the gate ships in warn mode.** Its shakedown exit criterion is committed in the sentinel and evaluable from the tree, so the decision to arm it will not depend on a log nobody can read back.
- **A known-open defect is now tracked as a corpus assertion rather than a note.** The check bank's Reference section cites the output-contracts document at an absolute path under a root that exists nowhere in this repository. Repairing it is out of both cards' scope, so the corpus carries it as an expected-FAIL: the run names it every time, and turns red on the day it is fixed — which is the prompt to retire the exception in that same change.

### Cross-references

- Release plan: this file, top section
- Milestone: `regression-corpus-gates-releases`
- Decision records: `core/ADRs/ADR-182-output-scoring-runner-consumes-the-shipped-eval-harness-schema.md` and `release/ADRs/ADR-181-behavioral-regression-floor-and-major-release-binding-boundary.md`
- Runner contract: `release/skills/pmo-skill-refiner/references/scenario-eval-contract.md`
- User-facing release notes: authored at Stage 13 Close, under `release/releases/notes/`

## Verification Evidence

(Populated after Stage 12 execution.)

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

## Issue References

- References #5863 — build the output-scoring scenario runner. Marked as closed at Stage 13.
- References #5864 — gate major releases on a behavioural regression corpus pass rate. Marked as closed at Stage 13.

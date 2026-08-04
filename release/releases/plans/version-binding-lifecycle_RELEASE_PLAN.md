<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — `version-binding-lifecycle`

**Milestone:** `version-binding-lifecycle` · **Repo:** `cody-hutson/pmo-platform`
domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-04, domain: governance }
**Version:** `{{RELEASE_VERSION}}` *provisional-display* · **Bump-class:** `minor`
**Release identity mode:** `versioned` · **Release Class:** `novel`
**Planned:** 2026-08-03 (Mon) · **Engineering Commit 0:** 2026-08-04 (Tue)
**Baseline pin:** `origin/main` @ `41d12ed8` (release branch created off this SHA)
**Branch:** `release/version-binding-lifecycle` — slug-primary; the branch name binds no version.
**Plan-file identity:** slug-keyed and flat at `plans/` top level per `plans/README.md` § Disposition rule **rule 0** (pre-claim / in-flight). It advances to `plans/v<MAJOR>/v<X.Y>_RELEASE_PLAN.md` via `git mv` only at the Stage-12 claim, per ADR-092 (`core/ADRs/ADR-092-plan-file-claim-time-stamping.md`).

> **Version binding.** Every version reference in this file is the `{{RELEASE_VERSION}}` token, never a literal. The concrete number is unknown until the Stage-12 Phase B3 atomic ref-CAS. Per `release/governance/RELEASE_PROTOCOL.md` § Versioning Phase 1, *the provisional-display version is a label, not a reservation*.

---

## Summary (30 seconds)

Six cards, one branch, one PR, one merge. The bundle is **thematically** coherent — all six orbit the version-binding contract — but it is **not** dependency-tight: of the milestone's 5 claimed sequence edges, Stage-4 validation confirmed exactly **1** (`#3619 → #3828`, and only for #3828's version-slot half). Sequencing is therefore driven by **contention and gate-dependency**, not by a chain.

Three release-level facts an operator should carry into review:

1. **This release edits the machinery that governs concurrent releases, while concurrent releases are in flight.** At Stage-4 pin the in-flight population was 1 open PR; at Engineering Commit 0 it is **4 open PRs and 5 remote `release/*` heads**. The release is a live worked instance of the very defect #3828 exists to detect. Treat every baseline pin in this plan as perishable and re-measure before relying on it.
2. **The version slot is contested and that is a designed-for outcome, not an incident.** Several in-flight siblings resolve to the same next-free slot. Under ADR-092 a lost race is a `{{RELEASE_VERSION}}` re-stamp, not a rename cascade. Do not hedge by pre-claiming.
3. **The release ships ADR-free.** Each design that considered an ADR concluded against one on duplicate-source grounds (the governing decisions are already recorded in ADR-036 / ADR-088 / ADR-092), and the Phase-A6.5 adversarial review surfaced a live ADR-number collision in the in-flight population that makes number allocation inside this release unsafe. Decisions are recorded in the registers that already own them.

---

## Dependency Graph

**Milestone-described sequence:** `#4194 → #3619 → #3828 → #4199 → #4174 → #4031`
**Validated verdict: 1 of 5 edges holds.** Reported as a finding; the unvalidated chain is not adopted.

```
#3619 ──(version-slot half only)──▶ #3828
#4194      (independent)
#4199      (independent)
#4174      (independent)
#4031      (independent)
```

1 edge · 0 cycles · 5 independent nodes. The zero-cycle property is structural, not a search over an empty population: a single directed edge over 6 nodes cannot form a cycle.

**Native dependency-link mirror:** none — `blocked_by` and `blocking` are empty for all 6 issues. The proposed sequence existed only as prose in the milestone description, which has been reconciled.

**Correction of record:** the milestone's rationale that #4194 "establishes the binding contract" is factually wrong. That contract shipped 2026-07-26 (`RELEASE_PROTOCOL.md` § Versioning + ADR-092, via #2548). #4194 governs the skill `version:` frontmatter field and the stamp→package-staleness path — a different object.

---

## Implementation Sequence

| # | Issue | Size | Why here |
|---|---|---|---|
| 1 | **#3619** | M (4) | Gates #3828's version-slot half (the one real edge). Its posture decision is the release's highest-information decision — landing it first lets #3828 cite a settled posture. |
| 2 | **#4194** | M (4) | Establishes the post-CAS obligation in `claim-version.sh` before #4174 touches the same block. Contention-driven placement, not a dependency. |
| 3 | **#3828** | L (8) | Consumes #3619's posture. Largest card; its surfaces collide with in-flight siblings, so mid-sequence keeps the collision window observable. |
| 4 | **#4174** | M (4) | Follows #4194 on `claim-version.sh`. Writer + schema + consumers. |
| 5 | **#4199** | S (2) | Independent doc sweep on `hub-spoke-bridge.md`, a cross-release contended file — late placement shrinks the stale-base window. |
| 6 | **#4031** | S (2) | Independent historical-record audit + git renames. Last, so the renames do not sit under other cards' churn. |

**Delivery Strategy.** Single branch `release/version-binding-lifecycle`, one PR, one merge. Plan file authored as Engineering Commit 0 with the Commit-0 version re-verify per `hub-spoke-bridge.md` § Canonical location.

---

## Operator Decisions (D-Gate block)

### D-C Branch Topology — **SINGLE** (recorded)
1 dependency edge and two real intra-release file collisions (`stage-09-plan-review.md`, `claim-version.sh`) make per-issue branches a net cost. Reversibility CHEAP / Confidence HIGH.

### D-Concurrency Posture — **P0 fully-serial** (recorded)
Two same-file/same-section co-edit pairs inside the release (`stage-09-plan-review.md` § Phase A6.5: #3619 × #3828; `claim-version.sh` post-CAS block: #4194 × #4174). P0 is the evidenced choice here, not merely the default. One Engineering chip at a time; the next waits until the prior commit lands. Reversibility CHEAP / Confidence HIGH.

### D-ReleaseClass — **`novel`** (validated, declaration stands)
Trigger (b) `≥1 D-class decision` MET decisively (≥4 genuine per-release D-class decisions). Cross-cutting check does **not** fire: `pipeline/stage-*.md` files touched = 2 definite, and the conditional third (`stage-12-execute.md`) was **ruled out at Stage 5** — #4194's ratified design explicitly excludes it. Trigger (a) therefore stays at 2 and the class does not re-render.
**Differentiation posture:** engagement density Standard · Stage 9 review depth Deep · Stage 5 activation bias ALL · Stage 13 outcome window 30-day.

### D-Version — **recorded determination, not a gate**
**Bump-class:** `minor`. The concrete number is `{{RELEASE_VERSION}}` and binds only at the Stage-12 Phase B3 atomic ref-CAS.
**Escalation conditions evaluated — none met.** A sibling known to be claiming *next-free at its own claim time* is precisely the case the CAS arbitrates, not a case for a plan-time click-gate.
**Re-verification rungs** (durability of the determination, not gates): (1) Engineering **Commit-0 re-verify** — single detect-and-HALT, **executed at this commit, verdict PROCEED**; (2) Stage-9 Phase A6.5 version dimension — advisory `FREE`/`TAKEN`; (3) Stage-12 Phase A.5.6c pre-merge freeness — the HALT-eligible stop; (4) Stage-12 Phase B3 atomic CAS — the only binding moment.
**Blocks:** the Stage-12 atomic claim and any `version:` frontmatter this release writes. Per ADR-092, **not** the branch name and **not** the plan-file path.
**Live-risk note:** with several siblings resolving to the same slot, a rung (1) or (3) fire on this release is a realistic, expected, cheap outcome — a `{{RELEASE_VERSION}}` re-stamp, not a rename cascade. Budget for it; do not treat it as an incident.
Reversibility CHEAP / Confidence HIGH.

---

## Stage Applicability Matrix

| Issue | S5 | S6 | S7 | S8 | S9 | S10–13 | Notes |
|---|---|---|---|---|---|---|---|
| **#3619** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Posture rendered at S5; S7 narrows to doc-verification under the rendered posture. |
| **#4194** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Two D-class forks, both rendered at S5. |
| **#3828** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | L-sized; new advisory sub-step across two pipeline specs. |
| **#4174** | APPLY | APPLY | APPLY | APPLY | APPLY | APPLY | Writer + schema + consumers. |
| **#4199** | APPLY (light) | APPLY | **SKIP** | APPLY | APPLY | APPLY | Documentation-conformance sweep on one file; no executable, schema, or CI surface. The § 5 skip predicate is met exactly. |
| **#4031** | APPLY (light) | APPLY | APPLY (narrow) | APPLY | APPLY | APPLY | S7 is narrow but real: the corpus lint must stay green across the renames. |

Stages 10–13 are release-scoped and apply uniformly.

---

## File Change Matrix

Machine-readable — one path per line, for deterministic Stage 7/8/9 extraction.

```
release/references/pipeline/stage-09-plan-review.md
.github/workflows/version-freeness.yml
core/deploy/deploy.sh
core/standards/gate-efficacy-standard.md
core/deploy/tools/check-canonical-structure.sh
core/standards/version-field-semantics.md
release/tools/claim-version.sh
core/deploy/tools/build-skill-packages.sh
release/references/pipeline/stage-04-planning.md
release/tools/append-pipeline-event.sh
release/references/standards/pipeline-event-log-schema.md
release/tools/query-pipeline-event.sh
release/tools/verify-release-plan.sh
release/references/pipeline/stage-13-close.md
core/skills/session-retro/references/emission-contract.md
core/skills/session-retro/SKILL.md
release/tools/synthesize-release-learnings.sh
release/tools/compute-cycle-time.sh
release/tools/compute-dora-metrics.sh
packages/session-retro.skill
packages/session-retro.skill.sha256
core/deploy/tests/run-install-regression.sh
release/references/how-to/hub-spoke-bridge.md
release/releases/plans/v3.55_RELEASE_PLAN.md
release/releases/plans/v3/v3.61_RELEASE_PLAN.md
release/releases/plans/_unversioned/81-stage3-bundling-composer-and-identity_RELEASE_PLAN.md
release/releases/plans/v3/v3.56_RELEASE_PLAN.md
release/releases/notes/v3.61_RELEASE_NOTES.md
release/releases/notes/v3.56_RELEASE_NOTES.md
release/releases/plans/version-binding-lifecycle_RELEASE_PLAN.md
```

### Release-wide explicit non-scope

Each entry is a recorded decision, not an omission.

```
.github/version-freeness.enforce                  — NOT CREATED  (#3619 DD-1: the rendered posture IS the absence)
core/rules/git-workflow.md                        — NOT EDITED   (#3619 DD-5: zero version-freeness content; the register owns the decision)
release/references/pipeline/stage-12-execute.md   — NOT TOUCHED  (#3619 + #4194 + #3828 + #4174 all exclude it; keeps cross-cutting trigger (a) at 2)
core/ADRs/ADR-092-*.md                            — NOT TOUCHED  (the status-flip gap is routed to its existing owner)
release/skills/release-planner/references/dependency-analysis.md — NOT TOUCHED (head-on sibling collision + would add Check-7 package exposure, currently zero)
core/schemas/gate-criteria-spec.md                — NOT EDITED   (#3828 DD-5: advisory ⇒ no gate criterion ID)
release/governance/release-process.md             — NOT EDITED   (#3828 DD-7: additive H3 leaves the mirror pair untouched)
release/releases/plans/v3/v3.99_RELEASE_PLAN.md   — PRESERVE     (archived historical record)
new ADR                                           — NOT AUTHORED (release ships ADR-free; see § ADR disposition)
```

---

## Per-issue change specification

### 1 · #3619 — Version-collision detection posture

**Rendered posture: (b) — ratify advisory-as-designed.** Reversibility CHEAP / Confidence HIGH.

The card asked the platform to replace a half-warn/half-silent status quo with a determinate posture, offering (a) enforce-earlier or (b) ratify-advisory. Stage 5 rendered **(b)** on three grounds. **Ground 1 was subsequently measured FALSE at Stage 7 (2026-08-04) and is retained below only as the record of what was believed.** The posture is unchanged and rests on grounds 2 and 3 plus the binding-moment argument; grounds 2 and 3 remain independently sufficient. The grounds as rendered at Stage 5 were:

1. **[FALSIFIED 2026-08-04 — see the correction below.] The CI gate cannot detect a collision in its shipped configuration.** `version-freeness.yml` sets a bump-class and never sets an explicit candidate, so the candidate is derived by running the allocator, which returns *next-free* — then compared against the same claimed-set that produced it. The verdict is `FREE` by construction. Flipping the enforce sentinel adds **zero** detection and only converts the fail-closed `UNDECIDABLE` arms into merge-blocking red on a transient network or auth failure. Strictly dominated.
2. **Stage 9 is not the earliest hard stop — Stage 6 is, and it already HALTs.** The Commit-0 version re-verify is a single detect-and-HALT and is detection rung 1, three stages before Stage 9. Making Stage 9 HALT-eligible cannot "save the Engineering-through-Stage-11 span" because a hard stop already guards the entry to that span.
3. **The Stage-9 advisory has never settled a re-version.** Zero ledger rows carry `resolved_at_stage = S9`, a value the schema explicitly admits. Granting HALT authority to a zero-fire signal buys nothing and risks a false NO-GO on a condition the shipped contract declares recoverable.

**Governance blocker on (a), independent of all three:** `gate-efficacy-standard.md` conditions a flip on drain evidence, and no `NOT_FREE` verdict had been observed at plan time. **That is no longer true — see the correction below.** The drain-evidence condition itself is unaffected: one reproduced verdict is not a drain window.

**CORRECTION — ground 1 falsified at Stage 7 (2026-08-04, Tue).** Dev Testing built a differential harness and produced `NOT_FREE`, rc=1, from the workflow's exact bump-class-only configuration. The two compared populations are not the same population: the allocator's `claimed_set()` is orphan-filtered (`lineage()==MAINLINE`) and the pre-merge gate's `_vf_build_claimed_set` is not, so when the derived candidate is itself orphan-classified the gate returns `NOT_FREE` — and in that state the verdict is correct. The orphan class is live in this repository. Three prior passes — Stage 5, adversarial design review, and the release hub — each read the call graph and agreed on the tautology; only an executed differential disagreed. **The advisory posture is retained on the binding-moment argument**: a version binds only at the Stage-12 atomic claim, so a pre-claim gate cannot be authoritative over an identifier that is not yet bound. That ground never depended on detectability. The set-divergence is filed as its own bug and is not remediated by this release. Flipping would declare an enforcement the surface cannot deliver — which the same standard forbids, and which is that standard's own founding anti-pattern.

**What #2548 bore on the decision (AC-3).** #2548 landed 2026-07-26, founding ADR-092. It moved plan-file and branch identity to slug-primary until the CAS and made the plan's version a provisional-display label. An early HALT on "your label is stale" would hard-stop on an artifact the shipped governance contract declares non-binding. #2548 did not merely lower the cost of a late catch — it removed the warrant for an early hard stop. That settles the card's open question toward (b).

| # | Path | Change |
|---|---|---|
| 1 | `release/references/pipeline/stage-09-plan-review.md` | § Phase A6.5, version-dimension sentence span only — append a dated ratification clause carrying (i) advisory-by-design-and-ratified, (ii) the architectural reason (the version binds only at the Stage-12 atomic CAS; the pre-claim label is not a reservation), (iii) the hard stops that DO exist, in pipeline order, (iv) a pointer to the durable decision record. |
| 2 | `.github/workflows/version-freeness.yml` | Header comment block only — posture token, the ratified statement + register pointer, repoint a dangling citation, and one honest-predicate line stating what the gate actually asserts. **Zero** changes to `on:` / `paths:` / `permissions:` / `jobs:` / `env:` / any `run:` block. |
| 3 | `core/deploy/deploy.sh` | Check-41 header comment block only — posture token, the gate-efficacy declaration's register pointer, and correction of a header overclaim about a plan-file input the resolver does not read. **No** change to `_vf_*` bodies, `cmd_check_version_freeness`, `resolve_check_mode`, the verdict contract, or Check-41 control flow. |
| 4 | `core/standards/gate-efficacy-standard.md` | § Flip-decision status register — **append one row**. No existing row edited. |

**Surface fence (binds #3828, Wave B).** `stage-09-plan-review.md` is single-paragraph-dense: all of Phase A6.5 is one line. #3619 owns the **version-dimension** sentence span and the trailing **Composition** sentence span; the Phase A6.5 header parenthetical is read-only for #3619 and **frozen** for #3828 (it encodes the ratified posture). The **file-dimension (G-PR8)** span and the **Cutover discipline** sentence are free. #3828 authors its cross-release signal as a **new sibling `Phase A6.6`** inserted after the A6.5 paragraph — an append-pattern insert with byte-level isolation, matching how A3.5 / A3.6 / A7 / A9 were each added.

### 2 · #4194 — Skill `version:` field gate + post-CAS package rebuild

**Defect 1 → make the gate real.** `check-canonical-structure.sh` gains a version-format predicate plus sensitivity and specificity self-test assertions; `version-field-semantics.md` § Format gains one clause naming the enforcing surface; `deploy.sh` Check-6 posture comment block is reconciled to what the gate now asserts. The change is zero-migration — every live `version:` value already conforms to the regex the governing standard already states, including the `-canary` sentinel, which the ratified regex admits by construction.

**Defect 2 → auto-rebuild, with fail-loud retained as the error path.** `claim-version.sh` gains a pre-flight validation extension, a `_host_rebuild_packages()` seam, and a post-CAS rebuild that rides the *same* stamp commit — atomicity, because a two-commit shape leaves a stale window. Fail-loud as primary is rejected on evidence: a post-CAS abort strands a half-applied stamp *and* a stale package, because the stamp contract never un-claims the tag. `build-skill-packages.sh` gains a path→affected-skill query mode.

**`claim-version.sh` surface fence (binds #4174).** #4194 claims exactly four regions: the `_preflight_stamp()` body (append-only, existing checks unchanged), a pure-insertion new function between `_preflight_stamp` and `_stamp_release_identity`, the `_stamp_release_identity()` tail before the commit-push call, and self-test fixtures appended before the PASS banner. **The entire CAS-retry loop including the post-CAS win block is NOT touched** — if #4174 needs a post-CAS hook, that block is its to edit.

**Explicitly out of scope:** `stage-12-execute.md`. The card's premise that the shard carries a per-release hand-written rebuild obligation to retire is false at live state — that obligation lives in an archived release plan, which is historical record and must not be edited. The AC is discharged by verification, not edit. This is what keeps cross-cutting trigger (a) at 2 and the Release Class at `novel`.

### 3 · #3828 — Cross-release contention signal

Two files, both additive, both append-pattern.

**`stage-09-plan-review.md`** gains a new `Phase A6.6 — Cross-release contention signal (advisory)` paragraph inserted at the blank line between A6.5 and A7 — **no bytes written inside the A6.5 line #3619 reserved**. It must carry: purpose and population (open PRs with a `release/*` head, **drafts included**, ∪ remote `release/*` heads with no open PR, minus self); the verbatim-runnable commands with the CLI page-limit default named explicitly (a truncated population produces a false clean); the co-edit predicate with per-path classification delegated to the existing line-range-overlap machinery (no second classifier); the version-slot predicate keyed on **recomputed next-free, never the carried label** (a stale label recomputes upward, so label equality returns a false negative); a **new** verdict family, not a reuse of the existing ones; the non-reservation statement naming the Stage-12 Phase B3 CAS as the binding moment and declaring the signal **advisory by construction, not advisory pending graduation**; and non-gating guarantees, composition, empty-population degeneracy, and cutover.

**`stage-04-planning.md`** gains a new `### In-Flight Release Roster` H3 appended to the existing Cross-PR Overlap Audit output section, as a sibling to the baseline-SHA H3. One row per in-flight sibling with slug, PR number or `—`, head SHA, bump-class, carried label, recomputed next-free, and intersecting paths, plus a measurement timestamp and baseline SHA. It must state that the roster is **a pinned measurement with no verdict** — Stage 4 cannot render a durable cross-release verdict because the audit is baseline-pinned by construction. An empty roster records an explicit `none in flight at <SHA>/<timestamp>`, never an omitted section.

**Integration AC (INT-1, upstream #3619):** does #3828's Phase A6.6 declare its version dimension advisory on the same binding-moment grounds #3619's A6.5 ratification clause states, without contradicting it, and without writing any bytes inside the reserved A6.5 span? Graded MET / NOT MET / PARTIAL at Stage 8.

### 4 · #4174 — Pipeline-event release join key

The event log's release key moves from the version string to the **milestone slug**, enforced at the writer. `append-pipeline-event.sh` gains a `--version` guard (grammar reject + unresolved-token reject + explicit `(none)` sentinel) plus self-test assertions. `pipeline-event-log-schema.md` gains a writer-enforcement clause and a **quantified** legacy caveat, and its example rows are re-keyed. Consumers are corrected in lockstep: `query-pipeline-event.sh` usage examples, `verify-release-plan.sh` fallback, `stage-13-close.md` Phase A7.1, the session-retro emission contract and SKILL.md, `synthesize-release-learnings.sh`, `compute-cycle-time.sh` (a silent-zero fix), and `compute-dora-metrics.sh`.

**Re-specified AC.** The card's stated method — "re-run the historical probe and expect zero foreign rows" — is **unsatisfiable on an append-only log** and is replaced, not waived: the forward assertion is that every row this release emits carries the slug and a slug-scoped query returns them with zero foreign-milestone rows; the legacy assertion is that an ambiguous historical query *reports* its ambiguity rather than silently resolving it.

**Historical rows are not rewritten.** The log is append-only; unattributable rows get a recorded, quantified caveat, never fabricated attribution.

**Package-freshness obligation.** This card edits `core/skills/session-retro/SKILL.md` and its `references/emission-contract.md` — both inside the rostered `session-retro` package. The `.skill` package and its `.sha256` sidecar **must be rebuilt and committed in this same PR** via `core/deploy/tools/build-skill-packages.sh session-retro`. This is the exact class #4194's Defect 2 exists to close at the tool level; the release must not commit it at the card level.

**Implementation notes (Stage 6) — three deviations from the Stage-5 spec, each recorded rather than silent.**

1. **The version grammar is SOURCED, not mirrored.** The spec proposed a `VERSION_KEY_REJECT_RE` literal in `append-pipeline-event.sh` carrying a "keep in lockstep" comment. `version-grammar.sh`'s own consumer contract forbids exactly that — *"SOURCE, do not copy. A copied-inline regex is a divergence defect"* — so the guard sources the library (with the established empty-positional idiom, so the library's `--self-test` cannot fire on the caller's `$1`) and calls `version_canonical`. This implements the spec's stated intent (*cite it, do not re-author it*) via the mechanism the library mandates, and removes the shadow-SSOT the literal would have created. The guard **fails closed** if the library is absent: a silently-skipped guard is the failure class it exists to remove.
2. **`compute-cycle-time.sh` carried a second, pre-existing defect.** Re-pointing it to `--release` made it find rows for the first time — and it then died on `ts_iso parse failure`, because it read `$2` (the **version** column) as `ts_iso`. `$1` retains the row's leading `"| "` under `FS=" | "`, so ts_iso is `$1`-minus-the-prefix and `$2` is the key. Verified pre-existing: the pristine tool at the branch head fails identically on a version-keyed release. The tool has therefore **never** produced a number — it returned `N/A` when the filter matched nothing and errored when it matched. Fixed in-scope (both extraction sites) because a consumer re-point that leaves the metric uncomputable does not deliver this card's stated purpose. Evidence: `corpus-integrity-lints-and-refs` now computes `13h21m` where the pristine tool returned `N/A`, with a genuinely-absent release still returning `N/A` as the control.
3. **The synthesizer's `--version` keeps taking the shipped `vX.Y` at Stage 13.** The spec said "per-release mode routes via `--release`" — correct for row *selection*, which is what changed. But the same argument is rendered verbatim into the `#### Release Learnings <value>` H4 heading that § 11.3 and the RELEASE_LOG placement convention both specify as `vX.Y`. Selection now goes through the § 2a ladder (so a `vX.Y` resolves to its slug-keyed rows instead of matching the raw column); the argument's display role is unchanged. `stage-13-close.md` Phase A7 is therefore **not** re-pointed; Phase A7.1 — the raw `query-pipeline-event.sh --version` call, which has no display role — is.

**Consumer-set correction.** The card names 6 consumers; the true set is **17** — 5 named correctly, 1 phantom (`compute-release-velocity.sh`, not a consumer), and **12** omitted. Two of the omitted are **writers**, not readers, which is the category that breaks loudly rather than silently:

- `release/tools/verify-release-plan.sh` — emitted the version-shaped sentinel `v0.0.0`. Now resolves the plan's milestone slug, falling back to the reserved `(none)` rather than to a synthesized placeholder version. (Named by the Stage-5 design.)
- `core/deploy/tests/run-install-regression.sh` — **found at Stage 6 by an independent writer sweep; absent from the Stage-5 enumeration of 16.** It emitted the contents of `.version` (currently `v4.06`) with a `v0.0` fallback — both version-shaped, so both now rejected. Its emission is best-effort and swallows failure into an "emission skipped" message, so the rejection would never have surfaced: the suite would simply have stopped emitting, permanently and silently. It now emits under `(none)`, being a regression suite with no release context. **This file is an addition to the card's File Change Matrix**, taken on the same rationale the Stage-5 design used to fold in `verify-release-plan.sh`: shipping a guard that knowingly breaks an in-repo emitter is shipping a self-inflicted defect.

The writer sweep is the load-bearing probe here, because a missed writer is a silent permanent emission loss. Method: every tracked file invoking `append-pipeline-event.sh`, then per-file inspection of the `--version` argument. Denominator **1521** tracked files; **33** invoke the writer; **6** pass a `--version`. Sensitivity arm: the sweep returns both already-known writers. Specificity arm: `append-pipeline-eventZZQ.sh` returns **0**.

### 5 · #4199 — Pre-claim identifier conformance in `hub-spoke-bridge.md`

One file. The card is a **discriminated** sweep, not a find-and-replace: pre-claim occurrences migrate to the slug form, post-claim occurrences stay on the versioned form. A blanket replace corrupts every post-claim reference.

- **Pre-claim → rewrite:** four plan-path references (State-Persistence row, § Canonical location, Option-A step 1, Procedure-1 sub-task template) move to the `<slug>_RELEASE_PLAN.md` form; four branch references move from the version form to the milestone form — one of which is a `git checkout` command that **fails as written today**.
- **Stale prose claim → rewrite:** the D-Version `Blocks:` list and its adjacent reversibility line still name the branch name and plan-file path as blocked identifiers. ADR-092 removed both. The list must still name the Stage-12 atomic claim and any `version:` frontmatter.
- **Post-claim → leave unchanged:** the remaining occurrences are legitimately post-claim.

### 6 · #4031 — Plan-file historical-record reconciliation

Two `git mv` renames and two single-line pointer repairs. Zero files created, zero deleted, zero tooling changes.

- `plans/v3.55_RELEASE_PLAN.md` → `plans/v3/v3.61_RELEASE_PLAN.md` — the plan is milestone #256's, which shipped as `v3.61`; `v3.55` was named but never shipped.
- `plans/_unversioned/81-stage3-bundling-composer-and-identity_RELEASE_PLAN.md` → `plans/v3/v3.56_RELEASE_PLAN.md` — resolves the `v3.56` case by recovery rather than by a documented-absent note.
- Both release-notes files' frontmatter `links.plan:` pointers are repaired; one of the two is a **pre-existing dangling pointer**.

**Do not edit either plan file's body.** Their self-referential paths are frozen historical record of the plan-time state, and `plans/README.md` is explicit that historical bodies retain their as-authored paths. Rewriting them would falsify the audit trail this card exists to protect.

**Do not re-run a bare index generator.** `plans/README.md` prohibits a full regenerate (it restamps grandfathered date cells). Neither target has an index pointer, so no index repair is required; confirm with the read-only verify mode.

---

## ADR disposition — the release ships **ADR-free**

No new ADR is authored. Two independent grounds:

1. **Duplicate-source.** The architectural principle every one of these decisions applies is already recorded: **ADR-036** (version-claim determinism — defer-to-claim + atomic compare-and-swap; ship-order = merge-order = tag-order), **ADR-088** (release-state binding and the mechanical-merge boundary), and **ADR-092** (plan-file claim-time stamping, extending the binding point to the plan file and branch). A new ADR would restate an already-decided principle in different words.
2. **Number-allocation hazard.** ADR numbering is global-monotonic across two directories *and* in-flight branches. The Phase-A6.5 adversarial review measured a live duplicate in the in-flight population and a taken number that two designs had both computed as free. Allocating a number inside this release is unsafe under that contention.

Decisions are recorded in the registers that already own them — the `gate-efficacy-standard.md` enforce-flip decision register for the detection posture, and the pipeline shards themselves for the sub-step contracts.

---

## Contention Map

### Within-release

| Surface | Issues | Class | Mitigation |
|---|---|---|---|
| `release/references/pipeline/stage-09-plan-review.md` § Phase A6.5 | **#3619 × #3828** | line-range-overlap (HIGH) | Sentence-span fence (above). #3619 lands first; #3828 inserts a **sibling** `Phase A6.6` at the blank line rather than editing inside A6.5. Graded by CIAC-3. |
| `release/tools/claim-version.sh` post-CAS region | **#4194 × #4174** | line-range-overlap (HIGH) | Four-region fence (above). #4194 lands first; the CAS-retry loop is explicitly left free for #4174. Graded by CIAC-5. |
| `core/deploy/deploy.sh` | **#3619 × #4194** | co-edit, line-disjoint | #3619 edits the Check-41 header block; #4194 edits the Check-6 posture block. ~3800 lines apart. |

Every other file in the matrix is claimed by exactly one issue.

### Cross-release — **re-measured at Engineering Commit 0; the Stage-4 pin was stale**

The Stage-4 audit pinned the in-flight population at 1 open PR with no PR-less `release/*` heads. **That pin did not survive.** Re-measured at Commit 0 (2026-08-04):

| Surface | Stage-4 pin (2026-08-03) | Commit 0 (2026-08-04) |
|---|---|---|
| Open PRs | 1 | **4** |
| Remote `release/*` heads | 1 | **5** (3 with no open PR) |
| `core/deploy/deploy.sh` co-editors | 2-way (in-release only) | **5-way** — 2 in-release × 3 cross-release |

**`core/deploy/deploy.sh` is the release's most contended surface and every co-edit is line-disjoint** at Commit 0. Disjointness re-measured per PR at hunk granularity; the in-release edit points (Check-6 posture block; Check-41 header block) do not intersect any sibling hunk. **This measurement is perishable** — re-verify before each subsequent chip that touches the file, and again at Stage 9.

The version slot is contested by multiple siblings. Per the D-Version live-risk note, this is a designed-for outcome resolved by the CAS in merge order, not a condition to hedge against.

---

## Risk Register

| # | Risk | Severity | Owner action | Reversibility |
|---|---|---|---|---|
| **R1** | A sibling merges first and takes the slot. | HIGH likelihood / LOW impact | None pre-emptive. ADR-092 makes the loss a `{{RELEASE_VERSION}}` re-stamp. Rungs (1)/(3) catch it. Do **not** pre-claim. | CHEAP |
| **R2** | Semantic collision with in-flight siblings on `hub-spoke-bridge.md` / `stage-04-planning.md` — siblings insert new material into the *same procedures* #4199 and #3828 modify. | MEDIUM / MEDIUM | #4199 and #3828 sequenced late. At Stage 6, re-read the target region from `origin/main` immediately before authoring. If a sibling lands mid-flight, the Stage-9 file dimension HALTs and the text is re-authored. | CHEAP |
| **R3** | #3828 scope creeps into the dependency-classifier reference — head-on sibling collision plus new Check-7 package exposure. | MEDIUM / HIGH | Scoped out at Stage 5 and recorded in § non-scope. | MODERATE if it lands |
| **R4** | `stage-09-plan-review.md` § A6.5 double-edit. | MEDIUM / MEDIUM | Sentence-span fence + sibling-insert topology + hard sequence. Graded by CIAC-3. | CHEAP |
| **R5** | `claim-version.sh` post-CAS double-edit. | MEDIUM / MEDIUM | Four-region fence + hard sequence. Graded by CIAC-5. | CHEAP |
| **R6** | **#4174 edits packaged skill content without rebuilding the package** — the exact class #4194 fixes at the tool level. Would land Check 7 red on main. | MEDIUM / HIGH | Rebuild `session-retro` + commit the package and its `.sha256` sidecar in the same PR. Named as an explicit obligation in the #4174 change spec. | CHEAP |
| **R7** | #4174's consumer set is under-specified in the card body. | MEDIUM / HIGH | Stage 5 swept and enumerated the full consumer set in the change spec above. | MODERATE |
| **R8** | #4174's historical rows may be unattributable. | LOW / MEDIUM | Record a quantified caveat. No-invention forbids fabricating attribution. | MODERATE (data) |
| **R9** | Baseline staleness across the whole plan. | **HIGH / MEDIUM** | **Demonstrated live: the Stage-4 pin inverted within one day.** Re-measure the in-flight population before relying on any contention verdict — at each chip, and again at Stage 9. | CHEAP |

**Systemic pattern.** R1 / R2 / R4 / R5 / R9 are one pattern at two scales: *this release edits the very machinery that governs concurrent releases, while concurrent releases are in flight.* The uniform mitigation is **read the target region from `origin/main` immediately before authoring, at every stage** — never trust a pin.

---

## Cross-Issue Acceptance Criteria

Graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 — binding-moment citation (#3619 × #3828 × #4199 × #4174).** Every passage this release authors that states *when a release version becomes authoritative* **cites** `RELEASE_PROTOCOL.md` § Versioning or ADR-092 as the owning source rather than restating the rule. *Method:* diff the four surfaces for binding-moment prose; for each added passage assert an owning-source citation within the same block. Live control: at least one such passage exists before the citation predicate is asserted.
- [ ] **CIAC-2 — posture consumption (#3619 × #3828).** #3828's version-slot predicate **names the determinate posture #3619 recorded** — the dated advisory ratification — not a generic "the version binds at Stage 12." *Method:* grep both pipeline specs for the ratified-posture token; specificity control asserts the *other* posture's token returns zero.
- [ ] **CIAC-3 — A6.5 coherence (#3619 × #3828).** After both edits land, the Phase A6.5 region carries **exactly one** determinate version-posture statement — no residual sentence contradicting the ratification, no duplicated contention prose, and no bytes written inside the reserved span. *Method:* grep the A6.5 advisory sentence (expect exactly 1 under the rendered posture) and assert consistency with the absence of the enforce sentinel. Live control: the pre-change file returns 1.
- [ ] **CIAC-4 — provisional-vs-bound vocabulary (#4174 × #4199 × #3828).** No surface this release authors describes a **pre-claim** version as `bound`, `claimed`, or `authoritative`; each pre-claim reference reads `provisional` or carries `{{RELEASE_VERSION}}`. *Method:* diff-scan for those adjectives; for each hit assert it describes a post-CAS state. Live control: `provisional` on the same diff returns non-zero.
- [ ] **CIAC-5 — post-CAS single-producer integrity (#4194 × #4174).** *Re-specified at Stage 6 (#4174). The original criterion graded a two-obligation ordering in the post-CAS region — #4194's rebuild obligation plus "any #4174 hook". That premise was **vacated at Stage 5**: #4174 rendered D-3 **DECLINED**, so no #4174 hook exists and `claim-version.sh` is not in #4174's File Change Matrix. Grading a sequence with one absent member would pass vacuously. The criterion is replaced, not waived, and now grades what the dissolution has to be true for:* the post-CAS region has **exactly one** producer of its obligations — #4194's — and #4174 contributed no second emitter anywhere in `claim-version.sh`. **Correspondingly, the slug↔version binding row remains emitted by Stage-12 Phase B3.1 alone**, which is the reason declining the hook was safe. *Method (three assertions):* **(a)** `claim-version.sh` is byte-identical between the #4194 landing commit and the release-branch head — assert on the whole file, not a line range, because #4194's own commit moved every downstream anchor (`claim_version()` sits at **873**, not the 733 the Stage-5 design recorded, so a range-pinned diff would silently compare the wrong region); sensitivity control: the same diff against a one-line perturbation of the file must report a difference. **(b)** #4194's rebuild obligation is present and reachable — the rebuild grep returns non-zero; specificity control: a nonexistent token on the same file returns zero. **(c)** Stage-12 Phase B3.1 still passes `$MILESTONE_SLUG` to the binding emit; live control: the B3.1 block exists in `stage-12-execute.md` before the predicate is asserted.

---

## Verification Plan

| Issue | Method class | Expected result |
|---|---|---|
| **#3619** | system-state + file-content assertion | The dated ratification note is present on **both** named surfaces; the enforce sentinel remains **absent** (the rendered decision); the register carries exactly one new row; the repointed citation returns zero hits on its old target; the disposition cites #2548 as *landed*. Regression: the workflow diff contains no `on:` / `paths:` / `jobs:` / `run:` / `env:` line, and the verdict-contract self-test is unchanged. |
| **#4194** | file-content + system-state | A malformed `version:` fixture makes the structure check exit non-zero and the failure text names the observed value; the `-canary` sentinel fixture still exits zero (the discriminating specificity arm). The stamp path's rebuild fires on the same commit; read the freshness check's **verdict text**, not only its exit code. |
| **#3828** | file-content assertion | Both new sub-steps present and named; the version half cites the binding contract and declares itself advisory *by construction*; the disposition fires pre-GO; **zero** bytes changed inside #3619's reserved A6.5 span; **zero** gate-criterion IDs introduced; exactly 2 files changed, both `.md`. |
| **#4174** | file-content + reproduction | The writer rejects a version-shaped key and accepts a slug; the schema documents the enforcement and carries the quantified legacy caveat; an ambiguous legacy query *reports* its ambiguity; the `session-retro` package is content-fresh after rebuild. |
| **#4199** | file-content assertion | The `Blocks:` line names neither the branch name nor the plan-file path, and **still** names the Stage-12 atomic claim and `version:` frontmatter (live control). All pre-claim occurrences read the slug form; the post-claim occurrences are **unchanged** (specificity control). Migrated passages cite the owning source. |
| **#4031** | system-state + predicate | Every versioned plan file matches a VERIFIED ledger row (live control: the pre-change probe returns the orphan). Both renames register as **git renames** with content intact; both notes pointers resolve; the corpus lint is green; the index verify is clean. |

**Release-level:** `deploy.sh --check` reported as a **delta against a pre-change baseline**, never as a raw count — the operator instance carries substantial pre-existing drift, and the residual is the control proving the probe still has power. CI green on all workflows. CIAC-1…CIAC-5 graded at Stage 9.

**Probe-validity discipline.** Every "0 occurrences" / "no findings" / "CLEAN" / "N of M" claim in this release's stage outputs carries a probe record: invocation, denominator, a sensitivity arm with its observed non-zero, and a specificity arm with its observed zero. **A zero whose control arm also returned zero is a broken probe — reported unusable, never as an empty population.**

---

## Rollback Strategy

**Topology:** single branch, one PR, one merge. Primary rollback is a revert of the merge commit, restoring every file in the matrix atomically. Rollback is operator-authorized per `RELEASE_PROTOCOL.md` § Rollback protocol. The revert form depends on the merge's parent count — a squash merge yields a single-parent commit for which the mainline-parent flag does not apply; determine the form from the actual merge commit rather than assuming.

| Issue | Complexity | Reversibility | Note |
|---|---|---|---|
| #3619 | Trivial | **CHEAP / HIGH** | Comment and prose only; zero executable change. The cheapest-to-undo card in the bundle. |
| #4199, #4031 | Trivial | CHEAP / HIGH | Doc edits + two git renames. Revert restores byte-for-byte. |
| #3828 | Low | CHEAP / HIGH | Pipeline-spec prose; no runtime data mutation. |
| #4194 | Low | CHEAP / HIGH | Script + doc edits. **Caveat:** if a `.skill` package was rebuilt, the revert must also restore the package and its sidecar or the freshness check goes red on main. |
| #4174 | **Moderate — the only non-CHEAP element** | **MODERATE / MEDIUM** | The code revert is clean, but the event log is append-only: reverting the writer does not un-write emitted rows. Treat any data operation as separately reversible from the key change. |

**Release-level rollback triggers:** package-freshness red on main post-merge (the exact failure #4194 exists to prevent — a reflexive risk worth naming) · a mis-keyed emission degrading metrics further than the original contamination.

**Rollback is NOT the mitigation for a lost version race.** A lost slot is handled by re-stamping `{{RELEASE_VERSION}}` per ADR-092, never by reverting the release.

---

## Issue References

Issues in this release: #3619, #4194, #3828, #4174, #4199, #4031. Each is marked as closed at Stage 13 per the standard close-out — no close-family verb is bound to any issue number outside this block, per the PR-body parser-clean discipline.

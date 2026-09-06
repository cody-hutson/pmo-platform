---
title: Release Plan — release-tools-invocable-gates-enforced (a declared gate or a mandated tool that does not actually work)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — a concrete version binds only at the Stage-12 atomic claim)
milestone: release-tools-invocable-gates-enforced
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — `release-tools-invocable-gates-enforced`

> **Milestone:** `release-tools-invocable-gates-enforced` (336) · **Release Class:** `cross-cutting` — held at Stage 5 (Tight engagement density / **Deep** Stage-9 review depth / Stage-5 activation bias ALL / 30-day outcome window) · **Version:** `{{RELEASE_VERSION}}` — **unbound through Stages 4–11; binds at the Stage-12 atomic claim (ADR-092)** · **Scope:** 5 cards, 13 raw pts × 1.3 = **17 effective** (band 15–25, PASS) · **Topology:** D-C `SINGLE` · **Concurrency posture:** P0 fully-serial · One release branch, one PR, one merge gate · **Branch:** `release/release-tools-invocable-gates-enforced` (slug-primary, no version stem).

This file is the Stage-4 release plan, committed as **Engineering Commit 0** on the release branch per the D-C SINGLE topology. It is reconciled with every decision rendered since that plan was written — the Stage-4 operator gate (D-1 … D-3), the Stage-5 consolidated gate (D-4 … D-6), the Collective Review scope-lock (D-8 / D-9), and the post-slice-1 scope change (D-10). Superseded Stage-4 statements are marked where they land rather than silently overwritten, so the record shows what moved and why.

**Transcription honesty.** Four of the nine Commit-0 Survival Set elements were **never determined at Stage 4** and are therefore recorded here as gaps rather than synthesized. They are enumerated in § Commit-0 Survival Set Transcription below, and each carries the consumer that will read an empty input. A transcription that invented them would have been worse than one that names them: element 5 gates the Stage-12 atomic claim, and element 1 gates the Stage-13 close-class resolver.

---

## Issue References

Card index for this release. Every issue reference in this plan resolves against this table — including the File Change Matrix rows and the Verification Plan rows, whose Issue column indexes back here rather than making free-standing prose references. This block is positioned **before any reference in the file** because the fragile-reference guard evaluates release-plan files positionally.

| Card | Size | Wave | One-line scope |
|---|---|---|---|
| #5227 | `size:M` | W1 | Stage-mandated release tools carry no script-execution allowlist rows, so the agent a pipeline spec mandates cannot run what the spec tells it to run. Ships the canonical four-form registration for four tools plus Arm F, a standing class-closing assertion that every spec-prescribed invocation is admitted by the allowlist. |
| #5283 | `size:XS` | W1 | `compute-release-velocity.sh` ships executable but is allowlisted on neither the source nor the deployed surface. **Co-discharged into #5227** (Stage-4 decision D2, carrier #5227) — the two edit the same rows. |
| #4216 | `size:S` | W2 | Check 61 (`decision-emission`) is advisory and deploy-time-only, so a release can close with zero decision events and green CI. Ships the CI mirror that makes its posture question answerable. |
| #4217 | `size:S` | W2 | No standing assertion that `deploy.sh`'s required path literals resolve, so a born-wrong or rotted root is silently skipped and overstates a check's denominator. |
| #5033 | `size:M` | W3 | The ADR-number integrity gate is not a required status check, so a duplicate or gap in the ADR sequence can merge to `main`. Widened at D-3 to the class of declared-but-unregistered contexts. |
| #5053 | `size:M` | — | **CLOSED at D-4, premise-rejected.** Its Stage 6–8 sub-tasks closed with rationale. Retained in this index because the Stage-4 dependency graph and contention map still name it, and a reader of those sections needs to resolve the reference. |

---

## Header

| Field | Value |
|-------|-------|
| **Version** | `{{RELEASE_VERSION}}` — unbound; the concrete `vX.Y` binds at the Stage-12 atomic claim (ADR-092). This cell is the machine-read **stamp manifest**, not prose. |
| **Bump Class** | **NOT DETERMINED AT STAGE 4** — `[ASSUMPTION – CONFIRM]`. Survival element 5's determining decision (`D-Version`) was never rendered; see § Commit-0 Survival Set Transcription gap G-5. Release-identity mode resolves to `versioned` by the Stage-3 shard's **stated default**, not by an authored declaration. |
| **Date Created** | 2026-09-05 (Saturday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering, slice 2 of 4) |
| **Branch** | `release/release-tools-invocable-gates-enforced` |
| **PR** | (populated at PR creation — hub-owned; one PR for the whole milestone, opened after all four Engineering slices land) |
| **Milestone** | `release-tools-invocable-gates-enforced` (336) |
| **Baseline pin** | `origin/main` = `18e3e787fe56efeab50a8f96660cffaa322e9d6c` (short `18e3e787`), fetched 2026-09-05 |

---

## Commit-0 Survival Set Transcription

The nine elements the plan file must carry out of Stage 4, each with the consumer that reads it from this file. **Rows 1–5 are mechanically guarded; rows 6–9 are reviewer-read.** Where an element is recorded ABSENT, the absence is the honest state of the Stage-4 output, established by a control-armed probe over the Stage-4 planning comment (191 lines / 27,607 chars; control arm `Contention Map` → 1, specificity arm `zzz-nonexistent` → 0).

| # | Survival element | Determined at | State | Where it lands in this file |
|---|---|---|---|---|
| 1 | `domain_practice` label | Stage 4 A1.5 | **ABSENT — gap G-1** | Recorded as a gap below; no label is synthesized |
| 2 | File Change Matrix (machine-readable) | Stage 4 A3 | **ABSENT at Stage 4 — reconstructed from Stage 5, gap G-2** | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria (`CIAC-N`) | Stage 4 A5 | **PRESENT** (CIAC-1 / CIAC-2 / CIAC-3) | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan | Stage 4 A5 | **ABSENT at Stage 4 — reconstructed from Stage 5, gap G-4** | § Verification Plan |
| 5 | `{{RELEASE_VERSION}}` stamp manifest | Stage 4 D-Version | **Token PRESENT; the determination behind it ABSENT — gap G-5** | § Header, `**Version**` cell |
| 6 | Stage Applicability Matrix | Stage 4 A2 | **PRESENT** | § Stage Applicability Matrix |
| 7 | Release Class declaration | Stage 4 D-ReleaseClass | **PRESENT** (`cross-cutting`, held at D-5) | § Header and § Release Class |
| 8 | Implementation Sequence | Stage 4 A2 | **PRESENT** | § Implementation Sequence |
| 9 | Baseline pin (`origin/main` SHA) | Stage 4 A0 | **PRESENT** (`18e3e787`) | § Header |

### The four gaps, stated rather than filled

**G-1 — `domain_practice` was never determined (element 1).** The Stage-4 planning comment carries **zero** occurrences of the token. The Stage-4 A1.5 phase that determines it produced no output. **Consumers that will read an empty input:** the Stage-13 close-class resolver at rung 1 (falls through to its default branch), the Stage-5 A3.1 impact-method selector (already ran — each Stage-5 spoke selected its own method and recorded the selection in its own design), the design-review checklist § 4.6 guide resolution, and Stage-7 Phase A + Phase C. **Not synthesized here.** A Stage-6 spoke inventing a Stage-4 determination would hand all four consumers a fabricated input that reads as authoritative. `verify-release-plan.sh`'s `PROV-PRESENCE` assertion FAILs on this file for exactly this reason, and that FAIL is the correct verdict, not a defect in the transcription. **Routing:** operator determination at Stage 9, or an explicit acceptance that the close-class resolver takes its default branch.

**G-2 — no machine-readable File Change Matrix was authored at Stage 4 (element 2).** The Stage-4 comment carries a **Contention Map** — a per-file, per-issue overlap analysis — which is a different artifact answering a different question. The per-card change sets exist, but they were authored at **Stage 5**, one per card, in each card's Solutioning sub-task comment. § File Change Matrix below transcribes those Stage-5 change specifications and labels their provenance as Stage 5 rather than presenting them as a Stage-4 determination. The Contention Map is preserved separately and unaltered.

**G-4 — no Verification Plan was authored at Stage 4 (element 4).** No `### Verification Plan`, no `Per-Issue Verification` table, and no AC baseline. The per-card acceptance criteria exist, authored at **Stage 5** in each card's design. § Verification Plan below transcribes them with Stage-5 provenance. **The AC baseline is recorded as of the transcription commit, not as of plan time**, because plan time produced no baseline to record — stated so a later ordinal-drift check is measured against a real anchor rather than a back-dated one.

**G-5 — `D-Version` was never rendered, so no bump-class intent exists (element 5).** The Stage-4 comment carries zero occurrences of `D-Version`, `Bump Class`, or `{{RELEASE_VERSION}}`. Two facts are separable here and are kept separate:

- **The release-identity mode is `versioned`** — not by an authored declaration, but by the **stated default** in the Stage-3 bundle shard's Release-Identity Mode enum, where `versioned` is marked *the default* and `version-less` is the operator exception. No `version-less` exception was declared at Bundle, at Stage 4, or at any decision gate through D-10. The milestone name being slug-only is **not** evidence either way: on 2026-09-05 this repository shipped one version-less release (`freshness-gate-measures-then-blocks`, Tag `(none)`) and one versioned release (`v4.56 | kit-content-and-defaults`) from slug-only milestone names on the same day.
- **The bump class was never determined.** `versioned` obliges a declared bump-class intent at the Bundle→Planning boundary. None exists. The `**Bump Class**` cell records that gap rather than deriving a floor from nothing, because a fabricated bump class would feed the Stage-12 next-free computation a floor no one chose.

The `{{RELEASE_VERSION}}` token in the `**Version**` cell is a **literal placeholder, not a value** — carrying it invents no version and is precisely what a pre-claim `versioned` plan is required to carry so the Stage-12 CAS-win path has something to resolve. **Routing:** the operator renders the bump class at or before Stage 12; the Stage-12 next-free computation cannot run without it.

### Commit-0 Version Re-Verify Disposition

Procedure 0 § Canonical location requires the **first** Engineering spoke under SINGLE topology to re-run the authoritative-version-selection check across the plan-file write and its commit. This plan lands from the **second** Engineering slice, not the first — the deviation, its cause, and its authorization are recorded in § Deviation Log Δ1. Each step carries an explicit disposition rather than a silent skip.

| Step | Disposition |
|---|---|
| 1 · `git fetch --tags origin && git fetch origin main` | **PERFORMED.** Authoritative host state refreshed at Commit-0 time. |
| 2 · Recompute next-free for the plan's bump class | **CANNOT BE PERFORMED — the input does not exist.** The allocation rule derives its floor from the bump class, and no bump class was determined (G-5). This is a *missing input*, not a computed result, and no candidate is synthesized. |
| 3 · PROCEED / HALT on a taken version | **INAPPLICABLE.** Step 3's predicate compares *the planned version* against the claimed set. There is no planned version to compare, so the collision test the step exists to run has no operand. Recorded as inapplicable rather than PROCEED — a PROCEED would assert a comparison that never ran. |
| 3b · `release/tools/claim-version.sh --verify-stamp <slug>` | **PERFORMED, post-write and pre-commit.** Real output recorded in the Stage-6 verification evidence for this slice. The plan carries the `{{RELEASE_VERSION}}` token, so the manifest half of the re-verify is assertable even though the version half is not. |

**What this leaves for Stage 12.** The manifest is intact and stampable; the *floor* the claim computes against is not determined. Stage 12 must obtain a bump-class determination from the operator before its Phase B3 atomic claim, or the release ships version-less by omission rather than by decision. Recorded as an open action item — see § Action Items, **AI-003**.

---

## Release Class

`cross-cutting` — **CONFIRMED at Stage 4 on trigger (c) alone, then HELD at Stage 5 (D-5) after that trigger weakened.** The honest trigger accounting, both readings preserved:

| Trigger | Stage 4 reading | Stage 5 reading (after #5053 closed) |
|---|---|---|
| (a) ≥3 `pipeline/stage-*.md` files changed | **DOES NOT HOLD** — zero stage specs touched | unchanged |
| (b) ≥3 of the 6 rule-defining governance surfaces | **DOES NOT HOLD** — zero touched | unchanged |
| (c) ≥3 in-bundle compositional edges | **HOLDS** — 4 edges | **DOES NOT STRICTLY HOLD** — 2 edges; #5053's departure removed two |
| `novel` trigger (b) — ≥1 D-class decision | HOLDS | HOLDS |

Multi-trigger resolution orders `cross-cutting` > `novel`, which is what made `cross-cutting` dominant at Stage 4. At Stage 5 the mechanical class would have fallen to `novel`. **D-5 held it at `cross-cutting` deliberately:** reclaiming already-budgeted ceremony mid-release is a poor trade, and the stricter-to-cheaper move would require explicit risk acceptance. **Differentiation posture:** engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome window **30-day**.

**`routine` is disqualified twice over:** #5033 is P2, and #4216 adds a new file.

---

## Composition

| Field | Value |
|---|---|
| **Shape** | capability-slice |
| **Frame** | F1 — SAFe Feature-Slicing + Vertical Slice |
| **Members (live, post-D-4)** | #5227 · #5283 · #4216 · #4217 · #5033 — **5 cards** |
| **Size** | 13 raw pts × `cross-cutting` class_weight 1.3 = **17 effective** (`round_half_up(16.9)`), inside the 15–25 band |
| **Band exception** | The 2026-08-16 operator-accepted band exception at 31 effective pts is **retirable**, not load-bearing — the composition sits inside the band without it. Retire or reaffirm at Stage 9. |

**Point arithmetic, live:** #5227 M=4 · #5033 M=4 (re-sized `size:S` → `size:M` at Stage 5 under D-3/D-6) · #4216 S=2 · #4217 S=2 · #5283 XS=1 → **raw 13** → `round_half_up(13 × 1.3)` = `round_half_up(16.9)` = **17**.

> **[SUPERSEDED — Stage 4 reading.]** The Stage-4 plan computed 6 cards / raw 15 / **20 effective**, and the Stage-4 decision record then warned that D-3's widening of #5033 would return the bundle *above* band. Both statements were correct when written. What actually happened is the opposite: D-4 removed #5053 (−4 raw) while D-3's widening added only #5033's re-size (+2 raw), so the net moved *down*. Preserved rather than overwritten because the Stage-4 warning is why a reader should expect a number above 20 and find 17 instead.

### Release Outcome Statement

**AFTER** this release: Every stage-mandated tool is invocable, and every declared gate either is enforced in CI or carries an explicit, verified record of the operator action still required to enforce it.

**BEFORE:** Mandated tools are unreachable, declared gates never run as required checks, and the gap between a gate's declared posture and its live enforcement is invisible.

> **Amended at D-1.** The prior statement promised every declared gate "is actually enforced in CI". That over-promised: registering a required status check is a repository-settings action a pull request structurally cannot perform. The statement above admits the operator-action path explicitly rather than assuming it away.

---

## Dependency Graph

Directional. Edge class distinguishes **build-blocking** (B cannot be built until A lands) from **ship-gating** (B can be built in parallel but should not ship before A).

```
#5227  (allowlist sweep + class-closing check)
  |--[co-discharge, build-blocking]--> #5283  (compute-release-velocity.sh form completion)
  |--[build-blocking, conditional]---> #4217  (new checker needs allowlist rows)

#4216  (decision-emission CI mirror) --[shared ledger, ship-gating]--> #5033
```

| Edge | Class | Basis |
|---|---|---|
| #5227 → #5283 | **build-blocking** | #5283's subject (`compute-release-velocity.sh`) is one of the tools #5227's AC-1 names. Same file, same rows. Fixing #5283 separately means editing the same rows twice. |
| #5227 → #4217 | **build-blocking (conditional)** | #4217 ships a standing assertion whose new test script incurs the same allowlist obligation, so the form-set convention must be settled first. Settled at **four canonical forms** (#5227 D-1). |
| #4216 → #5033 | **ship-gating** | Both write posture/flip-ledger rows into `core/standards/gate-efficacy-standard.md`. **Serialize the writes; do not serialize the builds.** #4216's ledger correction lands first; #5033's C-5 is the last ledger write. |

**Circular chains: 0.** The graph is a DAG with #5227 as source and #5033 as sole sink; no node reaches itself. **Sensitivity arm:** the graph is non-empty (3 edges over 5 nodes), so the zero is a real acyclicity result and not an empty-graph artifact.

> **[SUPERSEDED — Stage 4 reading.]** The Stage-4 graph carried two further edges — `#5053 ↔ #4216` (shared-seam, ship-gating only) and `#5053 → #5033` (shared ledger, ship-gating). Both vanished with D-4. Their removal is what dropped trigger (c) from 4 edges to 2 and prompted the D-5 release-class decision.

---

## Implementation Sequence

Single release branch. Waves are merge-order within it, not separate PRs — **this milestone ships as ONE pull request.**

| Wave | Issues | Why here |
|---|---|---|
| **W1** | **#5227** (+ **#5283** co-discharged) | Establishes the canonical invocation-form set and the class-closing invariant check. Every later wave that adds an agent-executed script depends on that convention being settled. Also unblocks #4217's host. |
| **W2** | **#4216**, then **#4217** | Both add an enforcement surface. #4216 precedes #4217 in the write-serialized Stage-6 order below. #4217's host allowlisting is resolved by W1. |
| **W3** | **#5033** | Last, deliberately. Its ledger row must be written after #4216's, and its real deliverable — registering a context in branch protection — is an operator action taken *outside* the PR, so the required-check set should be stable before it is touched. |

**Stage-6 engineering order (write-serialized, one spoke at a time, ratified at Collective Review):**

```
#5227  →  #4216  →  #4217  →  #5033
```

This order satisfies both dependency edges: #5227 settles the form count #4217 consumes, and #4216's ledger correction lands before #5033's C-5 write. Each slice is preceded by its own quota-budget gate and concurrent-PR check.

---

## Stage Applicability Matrix

Default is all stages. Deviations are named with a reason.

| Issue | Size | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9–S13 | Note |
|---|---|---|---|---|---|---|---|
| **#5227** | M | **APPLY** | APPLY | APPLY | APPLY | APPLY | The class-closing invariant check is a genuine design question — where the check lives, and how "cited as mandatory by a pipeline spec" is made machine-decidable. |
| **#5283** | XS | **SKIP** | APPLY | APPLY | APPLY | APPLY | Design subsumed by #5227's. One exception: the retire-vs-allowlist decision is carried into #5227's Stage 5 as a named decision, rendered **RETAIN**. |
| **#4216** | S | **APPLY** | APPLY | APPLY | APPLY | APPLY | A real design fork (thin-caller vs extracted-predicate), which Solutioning then found was dominated by a prior finding. |
| **#4217** | S | **APPLY** | APPLY | APPLY | APPLY | APPLY | Host choice (extend `check-convention.sh` vs a new test under `core/deploy/tests/`) is a D-class decision. |
| **#5033** | M | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY | Stages 7/8 retained despite the change being configuration rather than code: registering a required context changes what can merge, and that is exactly what must be dev-tested and accepted. |
| **#5053** | M | ~~HELD~~ | — | — | — | — | **CLOSED at D-4, premise-rejected.** Stages 6–8 sub-tasks closed with rationale. |
| **Release-scoped** | — | — | — | — | — | **Stages 10 + 11 COMPRESSED** | Git-native release: the PR diff is the dry run and git history is the snapshot. Both sub-tasks closed as skipped per this matrix. |

**Parallel-eligible counts** (excluding closed #5053, treating #5227+#5283 as one unit): **S5 = 4 · S7 = 4 · S8 = 4.** Worst parallel batch = **4**.

---

## File Change Matrix

> **Provenance: Stage 5, not Stage 4.** No machine-readable File Change Matrix was authored at Stage 4 (gap G-2). The rows below transcribe each card's **Stage-5 change specification** from its Solutioning sub-task comment, plus slice 1's **as-delivered** set read from the branch. Rows marked *(as-delivered)* are read from `git diff --name-status 18e3e787..<slice head>`; all others are *declared* and become as-delivered when their slice lands.

Machine-readable path list — one path per line, `<VERB>  <path>`. Intent tokens: `add` (new file) · `edit` (modify).

```
# ── Engineering Commit 0 — the plan file itself ──
add   release/releases/plans/_unversioned/release-tools-invocable-gates-enforced_RELEASE_PLAN.md
# ── slice 1 — #5227 (+ #5283 co-discharged) — as-delivered, 5 commits d77ba567..9178a746 ──
edit  core/config/allowlists/script-execution-allowlist.txt
edit  release/tools/check-selftest-coverage.py
edit  .github/workflows/release-tooling-smoke.yml
edit  core/standards/agent-script-promotion-framework.md
add   release/ADRs/ADR-191-allowlist-form-set-four-canonical-fifth-form-is-a-widening.md
edit  release/ADRs/README.md
# ── slice 2 — #4216 (declared; D-8 places the deploy.sh engine change in scope) ──
add   .github/workflows/decision-emission.yml
edit  core/deploy/deploy.sh
edit  core/standards/gate-efficacy-standard.md
edit  .github/decision-emission.enforce
edit  release/references/pipeline/stage-13-close.md
# ── slice 3 — #4217 (declared) ──
add   core/deploy/tests/test_deploy_path_literals.sh
edit  .github/workflows/install-tests.yml
# ── slice 4 — #5033 (declared) ──
edit  .github/workflows/repo-integrity.yml
edit  core/deploy/tests/test_gate_efficacy_declarations.py
```

**Paths declared by more than one slice** are listed once above and enumerated here so the double-write is visible rather than hidden by de-duplication:

| Path | Slices | Ordering constraint |
|------|--------|---------------------|
| `core/config/allowlists/script-execution-allowlist.txt` | 1 (#5227), 2 (#5227 attribution — D-10 `./update.sh` rows), 3 (#4217) | Append-only per tool block; no shared row. **Slice 2's rows are attributed to #5227**, the allowlist card, not to #4216. |
| `core/standards/gate-efficacy-standard.md` | 2 (#4216), 4 (#5033) | **HARD 2-way.** #4216's rows land **first**; #5033's C-5 is the last ledger write. Only this file's writes serialize. |
| `core/deploy/deploy.sh` | 2 (#4216 — exit contract), 3 (#4217 — `c31_globs` + 3 markers) | **SOFT.** Non-adjacent regions of an 18k-line file: #4216 targets `cmd_check_decision_emission` and the dispatcher; #4217 targets `c31_globs` at `:10299` and three fallback candidates. |

**Per-path intent and note.**

| Path | Intent | Issue | Note |
|------|--------|-------|------|
| `release/releases/plans/_unversioned/release-tools-invocable-gates-enforced_RELEASE_PLAN.md` | add | release | **Engineering Commit 0.** Staged under `_unversioned/` as a pre-claim plan — a sanctioned resident of that bucket. At the Stage-12 claim a `versioned` release's plan is renamed into `plans/v<MAJOR>/`. |
| `core/config/allowlists/script-execution-allowlist.txt` | edit | #5227, #4217 | Canonical **four** invocation forms per registered tool. Five/six are per-tool exceptions each carrying a written reason. The two deliberately-short blocks stay short — completing them would make this release's own CIAC-1 control arm green by construction. |
| `release/tools/check-selftest-coverage.py` | edit | #5227 | **Arm F** — asserts that every invocation a pipeline spec *prescribes* is admitted by the allowlist, adjudicated by the hook's own match rule. Asserts the **matcher**, never a row count. Reports findings on arrival and is **not expected green**. |
| `.github/workflows/release-tooling-smoke.yml` | edit | #5227 | Triggers selftest-discovery on Arm F's inputs. |
| `core/standards/agent-script-promotion-framework.md` | edit | #5227 | States the allowlist obligation's real trigger: it fires when a script becomes **agent-executed**, not only when a script is added. |
| `release/ADRs/ADR-191-allowlist-form-set-four-canonical-fifth-form-is-a-widening.md` | add | #5227 | Records the form-set decision: four canonical; the fifth `*/…` form subsumes forms 1–3, does not cover form 4, and admits an arbitrary path prefix. **The path is written in full rather than elided** — the delivery checker reads this column as declared paths, so an abbreviated path is a declared ADD that can never resolve. |
| `.github/workflows/decision-emission.yml` | add | #4216 | **Two jobs, two postures** per ADR-166. Integrity arm runs `deploy.sh --self-test` (hermetic, red-capable today, honours no sentinel). Live arm thin-calls the probe and reports **NOT-EVALUATED**, never a pass. Filter-free; two `gate-efficacy:` declarations, both `always-reports=yes`, neither carrying `skip-semantics`. |
| `core/deploy/deploy.sh` | edit | #4216, #4217 | #4216: `--check-decision-emission` `SKIP` → **exit 3**, mirroring `--check-package-freshness`, so CI branches on exit codes and re-encodes no predicate (**D-8**). #4217: −3 dead `c31_globs` roots, +3 line-scoped markers. **Neither slice adds `decision-emission` to `rs_checks`** — that roster maps `SKIP` into its pass arm. |
| `core/standards/gate-efficacy-standard.md` | edit | #4216, #5033 | #4216 corrects two measurably false claims about Check 61 and reshapes its flip row into the **SPLIT DISPOSITION** form. #5033 appends its register + flip-ledger rows **after**. |
| `.github/decision-emission.enforce` | edit | #4216 | **Comment only — the token stays `warn`.** Completes the graduation clause so whoever performs the flip reads the remaining steps here. |
| `release/references/pipeline/stage-13-close.md` | edit | #4216 | Keeps the A8.2 instruction true after the exit contract changes: adds the exit-3 = NOT-EVALUATED meaning; keeps the advisory framing and the *"emit the missing rows, never waive the finding"* clause verbatim. |
| `core/deploy/tests/test_deploy_path_literals.sh` | add | #4217 | Bash, read-only, `set -euo pipefail`. Arms PL-1..PL-8. Mandatory denominator line every run. Exit `0` clean · `1` findings · `3` scan-surface error. |
| `.github/workflows/install-tests.yml` | edit | #4217 | **+1 step** in `shell-tests` invoking the new test. No `continue-on-error`. |
| `.github/workflows/repo-integrity.yml` | edit | #5033 | 8 missing `gate-efficacy:` declaration blocks + 2 header corrections. |
| `core/deploy/tests/test_gate_efficacy_declarations.py` | edit | #5033 | Per-job assertion extending the ratchet, plus the advisory reconciliation reporter. Must not change `evaluate()`'s return arity. |

**ADR rows are deliberately outside the fenced block where their number is unallocated.** ADR numbering is a global sequence spanning `core/ADRs/` and `release/ADRs/`, allocated against the mainline anchor at commit time and never reserved ahead of a sibling's unmerged claim. Slice 1's ADR is listed with its **allocated** path because it has already landed; a later slice's ADR, if any, is recorded in § Deviation Log once allocated.

---

## Contention Map

Established at Stage 4 by reading the cards' Affected Files against live file content. **Preserved as authored**, with a live-state annotation where D-4 moved it.

| File / surface | Issues | Overlap class | Live state after D-4 |
|---|---|---|---|
| `core/standards/gate-efficacy-standard.md` | ~~#5053~~, #4216, #5033 | **HARD — was 3-way, now 2-way** | The release's highest-contention file. Serialize writes: #4216 first, #5033 last. |
| `core/config/allowlists/script-execution-allowlist.txt` | #5227, #5283, #4217 | **HARD — 2 certain, 1 conditional** | Co-discharge collapses the certain pair to one edit. #4217's rows are a separate tool block. |
| `core/deploy/deploy.sh` | ~~#5053~~, #4217, **#4216 (added at D-8)** | **SOFT — different regions** | #5053's region is moot. #4216 (exit contract) and #4217 (`c31_globs`) are non-adjacent. |
| `.github/workflows/repo-integrity.yml` | #5033 | NONE | Header/posture declarations only. |
| `.github/workflows/` (new file) | #4216 | NONE | New workflow. No existing workflow file is replaced. |
| Branch protection on `main` (out-of-repo) | #5033 | **NONE in-repo — see R2** | Not a repo file. No diff, no PR, no revert. |

**Explicit negative result.** Enumerated over the union of all cards' declared Affected Files plus every file the Stage-4 analysis read. **#5033 and #5227 share zero files** — despite both being "gate enforcement" cards, their surfaces are disjoint (branch protection + workflow header vs allowlist + tools). **Denominator:** 11 distinct paths. **Sensitivity arm:** the same enumeration returned a 3-way overlap on `gate-efficacy-standard.md` and a 2-way on the allowlist, so the disjoint result is a real separation and not an empty extraction.

---

## Quota Budget

**Verdict:** PASS (Checkpoint A)
**Parallel-eligible spokes per parallel stage:** Stage 5: 4 · Stage 7: 4 · Stage 8: 4
**Per-spoke cost estimate:** ordinal band `lowest` to `low–moderate` (size-bucket heuristic). The bundle contains no `size:L` and no `size:XL` card — sizes are XS ×1, S ×2, M ×2 — so every spoke in the worst batch sits at the low end of the ordinal scale. No telemetry medians exist for these buckets, so the ordinal band binds.
**Assumed/stated remaining usage-window envelope:** **`UNSTATED`** — no operator band was stated. The conservative default applies; no figure is fabricated for the unstated envelope.
**Estimated cumulative draw % (worst parallel batch):** 4 spokes × (lowest…low–moderate) against the conservative default envelope → **below the 50 % PASS boundary** `[ASSUMPTION – CONFIRM]`. This is a projection of a declared band, never a measurement — the usage-window axis has no instrument.
**Routing:** PASS → proceed parallel; no warning carried into the plan.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton. Checkpoint B also gates on the host-API axis (`core`/`graphql` pools), read at runtime and combined DEFER-dominant. Checkpoint A stays usage-window-only. Bands + cumulative-draw budget + host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

> **[SUPERSEDED — Stage 4 reading.]** Stage 4 recorded worst parallel batch = **5** over 6 live cards. D-4 closed #5053, reducing it to 4.

---

## Risk Register

| ID | Risk | Class | Reversibility | Confidence | Mitigation |
|---|---|---|---|---|---|
| **R1** | ~~#5053's premise is falsified; building it as filed ships a fix for a non-defect.~~ | Scope / premise | CHEAP | HIGH | **CLOSED at D-4.** The card was closed premise-rejected. Solutioning and the hub independently confirmed the residual already ships as a hermetic CI-run fixture, and a scan of the flip-decision table returned **zero** rows citing rehearsal as a blocker. |
| **R2** | **#5033's primary deliverable cannot be performed by a PR.** `required` is unavailable until the context is registered in branch protection, which a PR cannot do. The release can merge fully green with the gate still advisory. | Rollback / verification | **MODERATE** — the config change has no diff, no revert, and is outside merge-revert rollback | HIGH | Make context registration an explicit **operator action at Stage 12**, gated and evidenced by a live `gh api …/branches/main/protection` read-back, not by a green PR. Record the read-back in the Stage-13 close-out. Tracked as **AI-002**. |
| **R3** | **`gate-efficacy-standard.md` append conflict** — multiple cards write ledger rows into one table. | Contention | CHEAP | HIGH | Serialize the writes in slice order: #4216 first, #5033 last. One writer per slice. Now 2-way rather than 3-way. |
| **R4** | **#5033 is under-sized.** Labelled `size:S` (2 pts) while its review criterion has a real denominator. | Scope | CHEAP | HIGH | **RESOLVED.** Re-sized `size:S` → `size:M` at Stage 5. D-6 additionally corrected the declared denominator to **19** (not 18) and established that only **6** of the 9 unregistered contexts are structurally capable of a red verdict. |
| **R5** | **Card line-number citations are stale.** Cited positions had drifted from live ones; the "four canonical forms" claim disagreed with a file carrying five. | Currency | CHEAP | HIGH | **RESOLVED at #5227 D-1** — four canonical, fifth and sixth are per-tool exceptions with written reasons, recorded in ADR-191 and in the file's own convention block. #5283's count criterion resolves to four, so a correct implementation grades MET. |
| **R6** | ~~The canonical form-set is genuinely ambiguous.~~ | Design | CHEAP | HIGH | **RESOLVED at #5227 D-1** (see R5). Convention block and rows now agree. |
| **R7** | Adding a **path-filtered** job as a required context can deadlock PRs that never trigger it. | Delivery | MODERATE | MEDIUM | Confirm the workflow-level `on:` block has no `paths:` filter before registering. **#4216's new workflow ships filter-free by design**, which is a prerequisite for any `required` trajectory, not a later optimization. |
| **R8** | **`main` moved during planning.** A sibling milestone closed 2026-09-05, adding the 10th required context. | Baseline | CHEAP | HIGH | Baseline pinned at `origin/main` = `18e3e787`. **Re-read branch protection at Stage 12** rather than trusting this plan's snapshot. |
| **R9** | **The `{{RELEASE_VERSION}}` stamp is intact but its bump class is not determined** (G-5), so Stage 12's next-free computation has no floor. | Release identity | CHEAP (a determination costs nothing) | HIGH | Operator renders the bump class at or before Stage 12. Tracked as **AI-003**. Do not synthesize a floor. |
| **R10** | **`domain_practice` was never determined** (G-1), so the Stage-13 close-class resolver falls through to its default branch and `verify-release-plan.sh` `PROV-PRESENCE` FAILs on this file. | Provenance | CHEAP | HIGH | Operator determination at Stage 9, or explicit acceptance of the default branch. Do not synthesize a label. Tracked as **AI-004**. |
| **R11** | **Deploy lag on the allowlist.** The source allowlist carries the new rows; the *deployed* copy the hook reads does not until a deploy runs, so a newly-registered tool stays blocked in a live agent session mid-release. | Sequencing | CHEAP | HIGH | Not a defect in the change. Where an in-release execution blocks, assert the row's presence and its `fnmatch` match instead, and record deploy-lag as the reason. Stage-12 sequencing note. |

---

## Cross-Issue Acceptance Criteria

Three predicates, each spanning ≥2 issues and asserting a cohesion property no single card can verify alone. Graded at **Stage 9 QC3.5 on the merged PR**.

- [ ] **CIAC-1 (#5227 × #5283 × #4217 on `core/config/allowlists/script-execution-allowlist.txt`):** Every tool this release makes agent-invocable carries the *same* invocation-form set, and that set matches the count the file's own convention block documents — no tool ships a partial set, and the convention comment agrees with the rows. *Method:* enumerate non-comment entries with `python3`, group by basename for each tool the release touches, and assert every named tool reports the same count and that the count equals the number stated in the convention block. **Two blocks are deliberately short of four and must stay short** — completing them makes this criterion's own control arm green by construction. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#4216 × #5033 on `core/standards/gate-efficacy-standard.md`):** For every gate whose posture this release changes, three surfaces agree — the workflow's `gate-efficacy:` header, the flip-decision ledger row, and live branch protection. No gate declares an enforcement the surface does not deliver. *Method:* read live `required_status_checks.contexts` via `gh api repos/cody-hutson/pmo-platform/branches/main/protection`, extract every `enforcement=branch-protection:` value from `.github/workflows/*.yml`, and assert each context named in a `posture=required enforcement=branch-protection` header appears in the live list, for every gate this release touched. *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (#5227 × #4217 on the release's own new artifacts) — the reflexive one:** Every agent-executed script this release *itself* introduces or modifies carries its full allowlist form-set. The release must not reproduce, in its own diff, the defect class it exists to close. *Method:* enumerate scripts added or modified by the release diff via `git diff --name-only --diff-filter=AM <release-base>..HEAD -- '*.sh' '*.py'`, then for each, assert a matching row count in the allowlist. **Null predicate — control arm:** where the release adds no new script, the assertion is vacuous, so the same enumeration is additionally run against `path-leak-patterns.sh` on the same instrument and same file, which must return its non-zero form count (observed: 5 rows). A zero from both arms is a broken probe, not a clean result. *Graded at Stage 9 QC3.5 on the merged PR.*

---

## Verification Plan

> **Provenance: Stage 5, not Stage 4** (gap G-4). No Verification Plan was authored at Stage 4. The rows below transcribe each card's Stage-5 acceptance criteria and declared methods.

### AC baseline

Per-issue acceptance-criterion counts, with the commit the read was taken against. **The baseline is a pinned measurement and carries no verdict.** It is recorded **as of Engineering Commit 0**, not as of plan time, because plan time produced no baseline — stated so a later ordinal-drift check is measured against a real anchor rather than a back-dated one.

| Issue | AC count | Source of the criteria | Read at |
|-------|----------|------------------------|---------|
| #5227 | **6** (V-1 … V-6) | Stage-5 design, § *Verification the Engineering spoke owes* | `18e3e787` |
| #5283 | **2** (AC-1 retire-vs-allowlist decision; AC-2 form count) | Issue body; both rendered inside #5227's Stage-5 design | `18e3e787` |
| #4216 | **6** (AC-1 … AC-6) | Stage-5 design, § *Acceptance criteria for Stage 8* | `18e3e787` |
| #4217 | **7** (AC-1 … AC-7) + 2 integration (INT-1, INT-2) | Stage-5 design, § *Output for Stage 6* | `18e3e787` |
| #5033 | **4** (AC-1 … AC-4) + 2 integration (INT-1, INT-2) | Stage-5 design, § *Output for Stage 6* | `18e3e787` |

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|--------------------|-----------------|
| #5227 | AC-1 | Execute `bash release/tools/check-release-body-drift.sh --self-test` from the repository root · **deploy-lag caveat:** the hook reads the *deployed* allowlist, which lags the branch until Stage 12, so an in-release execution may still block. Where it does, assert the row's presence and its `fnmatch` match instead, and record deploy-lag as the reason | Runs without a `BLOCK-DESTRUCTIVE-022` block, or the row-presence substitute is recorded with its reason |
| #5227 | AC-2 | Re-run the form-set histogram over `core/config/allowlists/script-execution-allowlist.txt`, grouped by basename · control arm, same instrument, same target: the pre-change file must report a populated 1-form bucket → non-zero | The histogram gains no new 1-, 2- or 3-form basename; the surviving 2-form pair is exactly the two deliberate partials |
| #5227 | AC-3 | `python3 release/tools/check-selftest-coverage.py --reconcile`; assert exit 1 and that the output names `check-release-body-drift.sh` **before** the fix and not after · control arm: the pre-fix allowlist yields a strictly larger finding count | Arm F fires, discriminates pre-vs-post, and names each finding with spec file, line and exact command |
| #5227 | AC-4 | Run Arm F's engine-parity self-test | The parity table passes, each negative arm fires, and a NOT-EVALUATED parity result is reported as a failure rather than passing silently |
| #5227 | AC-5 | Read the convention block and every exception-form row | The block names four canonical plus two exception forms, and every fifth/sixth-form row sits under a comment stating its reason |
| #5227 | AC-6 | CIAC-3's declared method run at the unit level · **null predicate — control arm:** the release adds no new executable, so run the declared control arm against `path-leak-patterns.sh` on the same instrument and same file, which must return its non-zero form count (observed 5) | The release does not reproduce its own defect class. A zero from both arms is a broken probe, not a clean result |
| #5283 | AC-1 | Read #5227's Stage-5 design for the rendered retire-vs-allowlist decision and its recorded reason | **RETAIN**, with the reason recorded: the tool is a manifest FLOOR member whose absence the manifest header declares a hard failure, and the `RELEASE_LOG` Velocity field template names it as the mechanism verbatim |
| #5283 | AC-2 | Count the tool's allowlist rows and compare against the count the convention block documents | **4** — the count resolves to four under #5227 D-1, so a correct implementation grades MET rather than tripping the literal-reading hazard |
| #4216 | AC-1 | `python3 core/deploy/tests/test_gate_efficacy_declarations.py`; assert exit 0 and that its reported declaration count rises by exactly 2 · control arm, same instrument: the pre-change tree reports the lower count → non-zero delta | Two `gate-efficacy:` declarations present, each `always-reports=yes` with no `skip-semantics`; the workflow carries no `paths:`/`paths-ignore:` key |
| #4216 | AC-2 | **Falsification arm.** On a scratch copy of the tree, mutate one assertion in self-test group DE so it must fail; observe the integrity arm go **red** with `.github/decision-emission.enforce` still reading `warn`. Revert → green | The integrity arm is red-capable and honours no sentinel. **A green result in both arms is a broken probe, not a pass** |
| #4216 | AC-3 | Invoke the standalone probe `--check-decision-emission` (engine: `bash core/deploy/deploy.sh`) with the event-log path pointed at a nonexistent path → assert exit **3** · **control arm, same instrument, same target:** the same invocation against a seeded complete fixture exits **0**, so the 3 is a real classification and not a constant. *(Flag written ahead of the engine deliberately — see Deviation Log Δ8.)* | The live arm reports NOT-EVALUATED, never a pass; the job summary carries an explicit "not a pass" statement; the job itself exits 0 |
| #4216 | AC-4 | Re-run the exit-contract consumer sweep over the corpus; assert every hit is either updated or is a historical release plan · control arm: the same sweep for `--check-package-freshness` returns its far larger reference count → non-zero | The contract is documented at all four surfaces that state it, and the sole executable consumer (the dispatcher) is consistent with it |
| #4216 | AC-5 | Scan `core/standards/gate-efficacy-standard.md` for a surviving "no CI mirror" claim within the Check 61 rows · **control arm, same instrument, same target:** the same scan over Check 62's row, which legitimately still carries the phrase, returns non-zero | Zero surviving claims on Check 61; its flip row states a **blocker, not a schedule**. A zero from both arms is a broken probe |
| #4216 | AC-6 | `git diff` over four loci: the sentinel token, the check-mode default, the `rs_checks` roster, and branch protection | **Nothing was flipped.** The sentinel still reads `warn`; the check-mode default is unchanged; `rs_checks` still has exactly 4 members; branch protection is untouched |
| #4217 | AC-1 | `bash core/deploy/tests/test_deploy_path_literals.sh` against `main` with the remediation applied | Exit `0`, and the output carries the denominator line naming literals scanned, required, marked and excluded |
| #4217 | AC-2 | Read the test's arms and their comments | Every arm PL-1..PL-8 present and passing; each of PL-1..PL-7 names, in a comment, the mutation that must turn it red |
| #4217 | AC-3 | Read PL-6's four marker cases | All four asserted: reasoned-suppresses-and-is-counted, bare-`allow`-does-not, whitespace-only-reason-does-not, and both separators suppress |
| #4217 | AC-4 | Inspect a run of `install-tests.yml` for the new step | The step appears and executes. **A green run in which the step does not appear does not satisfy this** |
| #4217 | AC-5 | Compare Check 31's emitted `files_scanned` count before and after the `c31_globs` removal | The three dead roots are gone and the count is **unchanged** — evidence the removal is behaviour-preserving |
| #4217 | AC-6 | Count the new test's allowlist rows and their forms | Exactly the four canonical forms. **Five or six forms is a fail**, as is any directory glob in place of a named row |
| #4217 | AC-7 | `git diff` over `check-convention.sh` and its allowlist block | **Byte-unchanged.** Any completion of that block to four forms is NOT MET — it would make this release's own CIAC-1 control arm green by construction |
| #4217 | INT-1 | *Upstream #5227, shared surface the allowlist.* Assert the four-row registration is consistent with #5227 D-1 | Four forms canonical. A five-form registration contradicts D-1 and is **NOT MET** |
| #4217 | INT-2 | *Upstream #5227, shared surface the `check-convention.sh` allowlist block.* Assert the block is left byte-unchanged | Consistent with #5227's disposition of it as exempt-with-reason |
| #5033 | AC-1 | Read the `ADR-number integrity gate` declaration in `repo-integrity.yml`, then a live `gh api …/branches/main/protection` read-back recorded at Stage 12 | The declaration carries `posture=required enforcement=branch-protection` plus `invariant:` and `falsification:`, **and** the context appears in live `required_status_checks.contexts` |
| #5033 | AC-2 | Read the per-context disposition table recorded in `core/standards/gate-efficacy-standard.md`, then the same live read-back | The 9 declared-but-unregistered contexts are enumerated with a per-context disposition (REGISTER / HOLD-with-reason / CORRECT-THEN-HOLD); the REGISTER contexts appear in live branch protection |
| #5033 | AC-3 | Run `test_gate_efficacy_declarations.py` with its **sensitivity arm** (delete a context from a header → must fire) and its **specificity arm** (a single-job workflow naming no context → must not fire) | Every job producing a named check-run in a context-naming workflow carries a declaration stating its actual posture; both arms observed behaving as stated |
| #5033 | AC-4 | Inspect the reconciliation reporter's PR output and its posture declaration; `git diff` the `rs_checks` roster | It reports the declared-vs-live delta on every PR, is declared `advisory`, and is **absent from `rs_checks`** |
| #5033 | INT-1 | *Upstream #4216, shared surface `gate-efficacy-standard.md`.* Assert this card's register/ledger additions are consistent with #4216's Check 61 row on the same file | No duplicated row for one gate, no contradictory posture for one check-id, and the flip-decision table's disposition vocabulary unchanged |
| #5033 | INT-2 | *Upstream #5053.* | **INAPPLICABLE — #5053 closed at D-4.** Recorded rather than dropped so a reader of the Stage-5 design finds its counterpart resolved |

---

## Deployment Mechanism

**Git merge.** No S-2 skill copy and no manifest execution is anticipated: no path in the declared File Change Matrix is under `skills/`, `packages/`, `harness/` or `core/rules/`. **This is a plan-time projection, not a Stage-12 finding** — Stage 12 enumerates the actual branch diff and resolves the Operational Deployment Manifest from it. Two classes must be checked **separately** rather than folded into one count, because `deploy.sh --deploy` does not carry the second:

1. **Skill / package / harness class** → `deploy.sh --deploy` (+ a `.skill` rebuild where a skill source changed).
2. **Composition-surface class** (`core/config/`, any `CLAUDE.md.template`) → `./update.sh --surfaces-only`. A clean `--deploy` result says **nothing** about this class, and there is no automated detection backstop for it. **#5227 and #4217 both edit `core/config/allowlists/script-execution-allowlist.txt`**, which is under `core/config/` — so this class is **live for this release** and the manifest must carry its own row.

---

## Rollback Strategy

**Whole-release rollback:** `git revert -m 1 <merge-SHA>` against the single two-parent merge commit. Reversibility **MODERATE**, confidence **HIGH**.

Two elements sit **outside** merge-revert rollback and are named rather than assumed covered:

| Element | Why it is outside | Recovery |
|---|---|---|
| Branch-protection context registration (#5033) | A repository-settings change with no diff and no revert | Operator de-registers the context through repository settings. Evidenced by a live protection read-back both ways. |
| A claimed version tag | Version tags are permanent and host-protected; no account can delete one | Not deleted. Revert the merge and record the rollback; the tag remains as the record that the version was claimed and then withdrawn. |

---

## Action Items

| id | category | trigger | target | state |
|---|---|---|---|---|
| **AI-001** | `decision-deferred` | stage-boundary — Stage 5 entry for #5053 | Stage 5 Solutioning sub-task | **RESOLVED at D-4** (card closed premise-rejected) |
| **AI-002** | `verification` | stage-boundary — Stage 12 Execute | branch protection `required_status_checks.contexts` | **OPEN.** The release can merge fully green with the gates still advisory, and that gap sits outside merge-revert rollback. Gated by a live protection-API read-back at Stage 12. |
| **AI-003** | `determination-missing` | stage-boundary — before Stage 12 Phase B3 | bump class (Survival element 5 / gap G-5) | **OPEN.** Opened at Engineering Commit 0. The next-free computation has no floor without it. Do not synthesize one. |
| **AI-004** | `determination-missing` | stage-boundary — Stage 9 Plan Review | `domain_practice` (Survival element 1 / gap G-1) | **OPEN.** Opened at Engineering Commit 0. Four downstream consumers read an empty input; `PROV-PRESENCE` FAILs until it is determined or its absence is explicitly accepted. |

---

## Operator Decisions

Every decision rendered on this release, in order. Decisions D-1 … D-3 were rendered at the Stage-4 plan gate; D-4 … D-6 at the Stage-5 consolidated gate; D-8 / D-9 at the Collective Review scope-lock; D-10 after Engineering slice 1.

| id | Decision | Rendered at | Reversibility / confidence |
|---|---|---|---|
| **D-1** | **Plan approved; Release Outcome Statement amended.** The prior statement promised every declared gate "is actually enforced in CI", which over-promised — registering a required status check is a repository-settings action a PR structurally cannot perform. | Stage 4 plan gate | MODERATE / HIGH |
| **D-2** | **#5053 disposition deferred to Stage 5 Solutioning.** Carried into Stage 5 unchanged; Solutioning renders the disposition with implementation context rather than deciding at planning altitude. Recorded as AI-001. | Stage 4 plan gate | CHEAP / HIGH |
| **D-3** | **Scope widened on #5033.** The 9 contexts declaring `posture=required enforcement=branch-protection` that are absent from live branch protection (7 hard, 2 warn-mode-initial) are folded into #5033 rather than filed separately. #5033 moves from a single-gate fix to the class. | Stage 4 plan gate | CHEAP / MEDIUM |
| **D-4** | **#5053 closed, premise-rejected.** The residual the card pointed at already ships as a hermetic fixture run in CI. A scan of the flip-decision table returned **zero** rows citing rehearsal as a blocker, so no build option unblocks any pending flip. Stages 6–8 sub-tasks closed with rationale; AI-001 resolved. | Stage 5 gate | CHEAP / HIGH |
| **D-5** | **Release Class held at `cross-cutting`.** #5053's departure drops in-bundle compositional edges from 4 to 2, so trigger (c) no longer strictly fires and the mechanical class would fall to `novel`. Held deliberately: reclaiming already-budgeted ceremony mid-release is a poor trade, and the stricter-to-cheaper move would require explicit risk acceptance. | Stage 5 gate | CHEAP / HIGH |
| **D-6** | **The D-3 widening is kept as designed.** Solutioning established that #5033's own subject is **undeclared** rather than declared-but-unregistered — it names no posture at all — so D-3 joined the card to a class its subject does not belong to. The widening is retained because the design absorbs both classes. Two corrections stand: the declared denominator is **19**, not 18; and only **6** of the 9 unregistered contexts are structurally capable of a red verdict, because two declare `required` while running warn-mode and exiting 0. | Stage 5 gate | CHEAP / MEDIUM |
| **D-8** | **The `deploy.sh` engine change is IN SCOPE with #4216.** `--check-decision-emission` currently returns `SKIP … return 0`; the design changes it to **exit 3**, mirroring `--check-package-freshness`, so the workflow branches on exit codes instead of re-encoding the predicate in YAML. Without it the live arm cannot distinguish *measured nothing* from *measured and passed*. **Stage 6 must enumerate and verify every other caller**, since they inherit the new contract. | Collective Review scope-lock | CHEAP / HIGH |
| **D-9** | **#4217 fixes the three born-wrong literals and runs the predicate on the two the hub found.** The three-line `c31_globs` deletion ships with the card: three declared roots do not exist and are silently skipped by the loop's directory guard, overstating Check 31's denominator by 30%. The two additional literals the hub surfaced are **not** pre-classified as defects — they route through the spoke's four structural exclusions first. | Collective Review scope-lock | CHEAP / HIGH |
| **D-10** | **`./update.sh` allowlist registration added to this release.** Arm F surfaced `./update.sh` as mandated by the pipeline specs at two sites with **zero** allowlist rows. Unlike the five remaining `.py` findings it is remediable now, so it enters scope rather than deferring. **Four canonical forms, never five** — the fifth `*/…` form admits an arbitrary path prefix and is a security widening. Attributed to #5227, the allowlist card. | Tier 2 `[SCOPE CHANGE]` gate, after Engineering slice 1 | CHEAP / HIGH |

> **D-7 is not transcribed.** The Collective Review record enumerates "D-1…D-9", so a D-7 was rendered, but it appears on none of the surfaces this Commit-0 transcription read (the Stage-4 planning sub-task, the milestone description, the Collective Review scope-lock record, or the four Stage-5 Solutioning sub-tasks). **Recorded as unread rather than reconstructed** — a decision log that invents a missing row is worse than one that admits a hole. Resolve at Stage 9.

---

## Deviation Log

| Δ | Deviation | Cause | Authorization |
|---|---|---|---|
| **Δ1** | **Engineering Commit 0 lands from slice 2, not slice 1.** The canonical procedure makes the *first* Engineering spoke responsible for committing the plan file under SINGLE topology. | The hub's brief to slice 1 scoped it to its Stage-5 design and said "nothing else", which scoped away a spec obligation its own sub-task binds in full. Slice 1 surfaced the conflict rather than improvising a nine-element Survival Set plus a stamp manifest that gates the Stage-12 claim — the right judgment. | Hub verification on the slice-1 Engineering sub-task routed it explicitly into slice 2 with the path resolved. Deviates from the procedure's letter and achieves its purpose: the plan is on the branch before the slices accumulate. |
| **Δ2** | **Four Survival Set elements are recorded as gaps rather than transcribed** (G-1, G-2, G-4, G-5). | They were never determined at Stage 4. Established by a control-armed probe over the Stage-4 comment, not by assumption. | Stage-6 brief: *"Do NOT invent a Survival element the Stage 4 plan does not carry… An invented value is worse than a recorded gap."* Each gap names its consumer and its routing. |
| **Δ3** | **The File Change Matrix and Verification Plan carry Stage-5 provenance**, not Stage-4. | Consequence of Δ2 (G-2, G-4). The per-card change sets and acceptance criteria exist only in the Stage-5 designs. | Transcription of an authored, approved downstream artifact with its provenance labelled — not invention. The Stage-4 Contention Map is preserved separately and unaltered. |
| **Δ4** | **The plan file is staged under `plans/_unversioned/`** rather than flat at the `plans/` root. | This release is slug-primary and pre-claim; a flat placement is the versioned post-claim form. | The plans README names a pre-claim plan staged in `_unversioned/` as a legitimate resident, and the claim tool's pre-claim plan resolver searches both locations. |
| **Δ5** | **`verify-release-plan.sh` `PROV-PRESENCE` FAILs on this file**, and the failure is reported rather than engineered away. | Direct consequence of G-1. | The correct verdict for a plan carrying no `domain_practice` label. Making it pass would require synthesizing the label, which Δ2 forbids. |
| **Δ6** | **D-7 is recorded as unread.** | It appears on none of the surfaces this transcription read. | Recorded rather than reconstructed; routed to Stage 9. |
| **Δ7** | **26 of 29 per-issue verification rows grade `unclassified-method (no family match)` → ERROR** under `verify-release-plan.sh`. | Consequence of Δ3. The executor is a thin dispatcher over a **five-family registry** (sync · regression · runtime-suite · integration · fcm); the Stage-5 acceptance criteria were authored for a human or spoke to execute, not for that registry, so most method cells match no family. | **Left as authored, and reported rather than engineered away.** Rewriting approved Stage-5 acceptance criteria into executor-family shapes would change what the release is graded against in order to make a tool green — the inverse of what the tool is for. The ERROR verdicts are an honest statement of executor coverage over these criteria, not findings about the release. |
| **Δ8** | **A method cell naming a single-check probe misdispatches to the `sync` family and produces a false FAIL.** Observed on #4216 AC-3, which named `deploy.sh --check-decision-emission`; the executor ran a full `deploy.sh --check` instead and reported `deploy --check non-clean (exit 1)`. | The classifier's fallback arm globs `*deploy.sh*--check*`, which matches **every** single-check probe flag because each begins `--check` — `--check-close-completeness`, `--check-release-corpus`, `--check-package-freshness`, `--check-version-freeness` and `--check-decision-emission` alike. A probe assertion is silently graded by a different oracle. | **Worked around here, not fixed here.** The AC-3 cell now names the flag ahead of the engine so it lands in `unclassified` with its 25 siblings rather than in a false `sync` FAIL. **The classifier defect is out of this card's scope and is surfaced, not silently repaired** — it belongs to `release/tools/verify-release-plan.sh` and affects every release plan citing a single-check probe. Routed to Stage 9 for disposition. |
| **Δ9** | **`FCM-4` / `FCM-8` FAIL with `declared-add-not-delivered: core/deploy/tests/test_deploy_path_literals.sh`.** | Correct verdict, expected state. The path is declared for **slice 3 (#4217)**, which has not run at the time of this transcription. | No action. The FAIL resolves when slice 3 lands; a plan that declared only what was already built would be a record of the past rather than a plan. |

---

## Provenance

This file transcribes the **Stage-4 Release Planning** output posted on the Stage-4 planning sub-task, together with the **Decision Recorded — Stage 4 Plan Gate** comment on the same sub-task, and reconciles both to the **Stage-5 decisions** recorded on the milestone description, the four approved **Stage-5 Solutioning** designs and their hub verifications, the **Collective Review scope-lock** record, and the **post-slice-1 scope change**. Where a later disposition superseded a Stage-4 assumption, the transcribed sections **preserve the Stage-4 plan of record** under a `[SUPERSEDED]` marker and the § Deviation Log records the ratified delta. Authored at Engineering Commit 0 by the **second** Stage-6 Engineering spoke (card #4216) under the routing recorded in § Deviation Log Δ1.

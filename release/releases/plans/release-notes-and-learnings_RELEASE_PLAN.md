<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — release-notes-and-learnings

> **Milestone:** `release-notes-and-learnings` (#305) · **Release Class:** `routine` (capacity weight 1.0, **Deep** Stage-9 review depth) · **Version:** `{{RELEASE_VERSION}}` *(unresolved by design — the token binds to the won tag at the Stage-12 atomic claim, when `claim-version.sh --stamp-slug` resolves it and renames this file; the provisional determination re-verified at Engineering Commit 0 is recorded in § Commit-0 Version Re-Verify, per ADR-092)* · **Scope:** 5 issues · 22 effective pts · One release branch, one PR, one merge gate (D-C **SINGLE**, D-Concurrency **P0 fully-serial**).

This plan is the Stage-4 release plan (rendered on sub-task #4507, approved at the plan gate 2026-08-02 Sunday) written to disk as **Engineering Commit 0** by the first Stage-6 spoke, reconciled against the five Stage-5 Solutioning outputs consumed at the Collective Review scope-lock (2026-08-03 Monday) and against live mainline state at Commit 0. Deltas discovered between plan approval and Commit 0 are folded into the § Deviation Log rather than silently applied.

## Summary (30 seconds)

Five issues, one theme: **the release-notes and learnings surfaces stop reporting coverage they do not have.** After this release the note-content lint actually reads version-less notes, every published GitHub Release body matches its canonical note under a gate that runs on an automatic CI path, close-out both emits *and* asserts its mandated Stage-13 outputs, and a learning that occurs once has a routed disposition instead of a dead end.

- **The dependency graph is far flatter than the milestone's asserted linear chain.** Of five edges asserted at bundling, **three do not hold**. The only hard edge is `#4451 ──► #4452` (an assertion needs a producer to assert against). `#4451 ──► #3121` is moderate (semantic, no file overlap).
- **`#3809`'s two blind spots are in series, not peers.** The discovery glob and the cutover floor are independent skip paths, and a glob-only fix is a **measured no-op** — the scanned count does not move. The fix lands whole or not at all.
- **`#3699`'s premise was falsified by measurement at the plan gate.** Check 47 is **RED now**, not structurally blind: five drifting versions sit *above* the armed cutoff and all five merged after the gate was armed. Root cause is that Check 47 has no automatic CI path.
- **The baseline moved mid-pipeline.** `governance-hardening` (#290) shipped as **v4.06** during this release's Stage 5, which is why D-Version re-determined `v4.06 → v4.07`. Slug-primary artefacts made that a one-line correction rather than a rename cascade.
- **Four vacuity traps were found across the release**, each defeating the previous obvious observable — exit code, corpus-wide grep, "the file changed", and "the field parses". Every verification method in this plan names an observable that survives all four.
- **Rollback: MODERATE** whole-release. Four of five members revert trivially; `#3699`'s re-emit step is **IRREVERSIBLE** and is gated behind a capture-before-overwrite merge.

## Commit-0 Version Re-Verify

Run at Engineering Commit 0 on **2026-08-03 (Monday)** per the release-identity two-phase binding discipline. `v4.06` was rule-computed as provisional at Stage 4 (bump-class `minor`, anchor `v4.05`), then **re-determined to `v4.07`** on 2026-08-03 when `governance-hardening` (#290) claimed `v4.06` mid-Stage-5. This re-verify is the **first detection rung**; the Stage-12 atomic claim is the resolving authority. Protocol is **detect-and-HALT, no auto-retry** — a collision here stops Engineering and returns D-Version to the operator.

**Method.** `git fetch --tags origin && git fetch origin main`, then each arm of the claimed set evaluated independently against `origin/main` at `41d12ed8`. Ledger input read via `git show origin/main:<path>`, never the worktree copy.

| Claimed-set arm | Probe | Result |
|---|---|---|
| Origin tags | `git tag -l \| sort -V` after `--tags` fetch | highest = `v4.06`; **no `v4.07`** (control: `refs/tags/v4.06` resolves, so the tag probe is live) |
| Mainline release ledger | `git show origin/main:release/releases/RELEASE_LOG.md` | `v4.07` occurs **0** times over a **932-line** denominator (control: `\| v4.06 \|` occurs 1 time, so the row probe is live) |
| Rule-computed next-free | `claim-version.sh --sha <origin/main> --bump minor --dry-run` | **`v4.07`** |
| Live release branches | `git ls-remote --heads origin` | only `release/release-bundle-and-sequence-gates` — **slug-primary, binds no version** (defer-to-merge, ADR-092) |

**Verdict: PROCEED.** `anchor()` = `v4.06`; floor (`minor`) = `v4.07`; `claimed_set()` has no member at or above the floor. **`v4.07` remains next-free.** No HALT condition present.

**Grammar note (recorded, not a divergence).** The per-release increment in this repo advances the **MINOR** component of the two-component `vMAJOR.MINOR` grammar, which is what `claim-version.sh --bump minor` computes. `--bump patch` computes the three-component hotfix slot (`v4.00.1`) and is **not** the cadence bump. The recorded determination `v4.07` equals the `minor` next-free.

**Watch item (not an override trigger).** Milestone #299 `release-bundle-and-sequence-gates` is in flight on its own slug-primary branch and binds no version. Whichever release reaches Stage 12 first wins the number by compare-and-swap; the loser re-versions upward. Recorded, not mitigated.

## Scope

### Outcome Statement

**AFTER** — The note-content lint actually scans version-less notes, every published GitHub Release body matches its canonical note with `deploy.sh` Check 47 green and running on an automatic CI path, close-out both emits AND asserts its mandated Stage-13 outputs, and a learning that occurs once has a routed disposition instead of a dead end.

**BEFORE** — The lint is blind to version-less notes twice over (glob AND cutover floor); eleven published Release bodies drift from their canonical notes — five of them above the armed cutoff and all five shipped after the gate was armed, so Check 47 is RED — and the emit path that produced them is still open: three live surfaces prescribe the `--notes-file` invocation the standard forbids; `automated-closeout.sh` emits neither the Phase-B velocity field nor the Phase-A7 learnings triple on any code path, and no gate reports it; a single non-recurring learning is captured and then reaches no disposition.

### Members

| Issue | Size | Title | Wave |
|---|---|---|---|
| #3809 | `M` | note-content lint skips ALL version-less / `_unversioned` release notes | W1 |
| #3699 | `L` | Eleven published Release bodies drift from their canonical notes; the emit path is still open | W1 |
| #4451 | `M` | `automated-closeout.sh` does not emit the Phase-B velocity field or the Phase-A7 learnings triple (producer half) | W1 |
| #4452 | `M` | Check 48 does not assert the Phase-B velocity field or the Phase-A7 learnings triple (gate half) | W2 |
| #3121 | `S` | Close-out should capture session/chat learnings into the backlog | W2 |

**Scope LOCKED at Collective Review, 2026-08-03 (Monday)** — 5 members / 22 effective pts, inside the 15–25 target band. All five Stage-5 designs accepted; **zero HALTs outstanding**.

## Dependency Graph

```
#3809                    (isolated — the soft #3698 edge is moot; #3698 deferred + de-bundled)
#3699                    (isolated — the asserted #3698 ──► #3699 and #3699 ──► #4451 edges do NOT hold)
#4451 ═══hard═══► #4452  an assertion needs a producer to assert against
#4451 ┄┄moderate┄► #3121 semantic only; no file overlap
```

**Waves:** W1 = {#3809, #3699, #4451} · W2 = {#4452, #3121}.

**Dependency-edge correction (Stage 4, 2026-08-02).** Of the five edges asserted at bundling, **three do not hold**: `#3698 ──► #3699` fails (all eleven drifting versions carry flat notes; highest foldered version is `v3.53`), `#3699 ──► #4451` fails, and `#3809 ──► #3698` was soft and is now moot.

## Implementation Sequence

**Stage 6 Engineering routes write-serialized in dependency order on ONE branch** (`D-C = SINGLE`, `D-Concurrency = P0 fully-serial`). The next slice waits until the prior commit lands on the release branch. Force-push — including `--force-with-lease` — is prohibited on the shared branch under any multi-chip activity.

| Order | Slice | Why here |
|---|---|---|
| 0 | **Commit 0** — this plan file | Plan on disk before any implementation commit |
| 1 | **#3809** | Fix the lint first so it can see the corpus |
| 2 | **#4451** | Producer; independent, and #4452 cannot assert against nothing |
| 3 | **#3699** | Independent content remediation + CI enrollment. **Part 0 (emit-path fix) lands before its Part A re-emit** |
| 4 | **#4452** | Gate; MUST follow #4451 |
| 5 | **#3121** | Needs #4451's reliable capture to act on |

## Stage Applicability Matrix

**Zero stage skips.** All five members run Stages 5–13.

| Issue | Size | S5 | S6 | S7 | S8 | S9 | S12/13 |
|---|---|---|---|---|---|---|---|
| #3809 | M | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| #3699 | L | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| #4451 | M | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| #4452 | M | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| #3121 | S | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## File Change Matrix

**Machine-readable path list** — one repo-relative path per line, for deterministic extraction by Stages 7 / 8 / 9. A trailing `/**` denotes a directory whose contents are in scope.

```
core/deploy/deploy.sh
core/deploy/tools/lint_release_corpus.py
core/standards/public-repo-vs-operator-instance-taxonomy.md
release/references/how-to/hub-spoke-bridge.md
release/references/pipeline/stage-13-close.md
release/references/standards/release-notes-standard.md
release/references/standards/release-velocity-tracking.md
release/references/standards/_examples/dual-write-illustrative-v2.01.md
release/releases/README.md
release/releases/RELEASE_LOG.md
release/releases/notes/README.md
release/releases/notes/_unversioned/public-flip-depersonalization-enforcement_RELEASE_NOTES.md
release/releases/notes/_unversioned/public-flip-install-blockers_RELEASE_NOTES.md
release/releases/plans/release-notes-and-learnings_RELEASE_PLAN.md
release/skills/release-executor/SKILL.md
packages/release-executor.skill
packages/release-executor.skill.sha256
release/tools/automated-closeout.sh
release/tools/capture-release-bodies.sh
release/tools/reemit-release-bodies.sh
release/tools/synthesize-release-learnings.sh
release/tools/tests/fixtures/versionless-notes/**
release/tools/tests/test_lint_release_corpus_versionless.sh
release/releases/_captures/2026-08-04-release-body-precapture/**
.github/workflows/close-completeness.yml
```

**Out-of-repo mutation (not a file path, listed for completeness):** eleven published GitHub Release bodies re-emitted via `gh release edit --notes` under #3699. **IRREVERSIBLE.**

### Per-member detail

| Member | Path | Intent | Reversibility |
|---|---|---|---|
| #3809 | `core/deploy/tools/lint_release_corpus.py` | MODIFY — both discovery globs; named `VERSIONLESS_KEY`; `is_versionless` branch; three stale comments reconciled | CHEAP |
| #3809 | `release/references/standards/release-notes-standard.md` | MODIFY — §3.2 gains an explicit, layout-independent in-scope statement | CHEAP |
| #3809 | `release/tools/tests/test_lint_release_corpus_versionless.sh` | NEW — negative-control harness | CHEAP |
| #3809 | `release/tools/tests/fixtures/versionless-notes/**` | NEW — 2 committed fixture notes (must-flag / must-not-flag) | CHEAP |
| #3809 | `release/releases/notes/_unversioned/public-flip-install-blockers_RELEASE_NOTES.md` | MODIFY — 12 impact beats (approved in-release remediation) | CHEAP |
| #3809 | `release/releases/notes/_unversioned/public-flip-depersonalization-enforcement_RELEASE_NOTES.md` | MODIFY — 1 missing Section 6a (approved in-release remediation) | CHEAP |
| #3699 | `release/references/how-to/hub-spoke-bridge.md` | MODIFY — `--notes-file` → `--notes` (Part 0 emit-path fix) | CHEAP |
| #3699 | `release/skills/release-executor/SKILL.md` | MODIFY — three `--notes-file` sites → `--notes` | CHEAP |
| #3699 | `release/releases/README.md` · `release/releases/notes/README.md` · `core/standards/public-repo-vs-operator-instance-taxonomy.md` | MODIFY — descriptive `--notes-file` → `--notes` | CHEAP |
| #3699 | `release/references/standards/_examples/dual-write-illustrative-v2.01.md` | MODIFY — PRESERVE the example, add one bracketed "pre-§5.1 idiom" note | CHEAP |
| #3699 | `core/deploy/deploy.sh` | MODIFY — lexicographic compare → shared file-order latch; two cutoff constants | CHEAP |
| #3699 | `release/tools/automated-closeout.sh` | MODIFY — shared cutoff default cascade | CHEAP |
| #3699 | `.github/workflows/close-completeness.yml` | MODIFY — add the notes path filter; reconcile the prerequisite warning text | CHEAP |
| #3699 | `release/releases/_captures/2026-08-04-release-body-precapture/**` | NEW — 11 published-body captures + `MANIFEST.md` + `SHA256SUMS` | CHEAP (additive) |
| #3699 | `release/tools/capture-release-bodies.sh` | NEW — pre-overwrite capture tool; REFUSES to overwrite an existing capture (directory- and file-level guards, no `--force`) | CHEAP (additive) |
| #3699 | `release/tools/reemit-release-bodies.sh` | NEW — §5.6 re-emit tool; dry-run by default, capture is a hard precondition, per-version atomic, drift check is the resume ledger. **Authored at Stage 6; EXECUTED at Stage 12** | CHEAP (additive; its `--execute` run is IRREVERSIBLE) |
| #3699 | `packages/release-executor.skill` · `.sha256` | MODIFY — package rebuild for the Mode F SKILL.md edit (CI-gated package-freshness beat) | CHEAP |
| #4451 | `release/tools/automated-closeout.sh` | MODIFY — emit the Phase-B velocity field + the Phase-A7 learnings triple | CHEAP |
| #4451 | `release/references/standards/release-velocity-tracking.md` | MODIFY — §3.3 grammar stated normatively | CHEAP |
| #4451 | `release/references/how-to/hub-spoke-bridge.md` | MODIFY — Stage-13 chip gains the A7 emit step | CHEAP |
| #4452 | `core/deploy/deploy.sh` | MODIFY — Check 48 sub-checks (j)/(k) + `CLOSE_COMPLETENESS_OUTPUTS_CUTOFF` | CHEAP |
| #4452 | `release/releases/RELEASE_LOG.md` | MODIFY — backfill the `v4.06` learnings block for a clean arming baseline | CHEAP |
| #3121 | `release/references/pipeline/stage-13-close.md` | MODIFY — Phase A7 sub-threshold disposition paragraph | CHEAP |
| #3121 | `release/tools/synthesize-release-learnings.sh` | MODIFY — near-threshold band + out-of-window render | CHEAP |
| #3121 | `release/tools/automated-closeout.sh` | MODIFY — `phase_pattern_scan` wiring | CHEAP |

## Contention Map

| ID | Surface | Members | Resolution |
|---|---|---|---|
| C1 | `release/tools/automated-closeout.sh` | #3699 × #4451 × #3121 | **Serialize.** Disjoint function regions; the serial Stage-6 order makes this a no-op |
| C2 | `core/deploy/deploy.sh` | #3699 × #4452 | **Serialize**, #3699 first. #3699 touches the drift-latch + cutoffs; #4452 touches `_cc_row_findings` / `_cc_compute_verdict` |
| C3 | `release/references/how-to/hub-spoke-bridge.md` | #3699 (Part 0) × #4451 (M3) | **Serialize.** Also contends with open PR #4568 on `release-bundle-and-sequence-gates` — **cross-release, sequence at merge** |
| C4 | `release/references/standards/release-notes-standard.md` | #3809 only | **RESOLVED** — #3698 deferred + de-bundled, so the asserted second party is gone. CIAC-2 retired for want of a second party |

## Risk Register

| ID | Risk | Owner | Mitigation | Reversibility |
|---|---|---|---|---|
| R1 | #3699's re-emit overwrites a published body with no recoverable prior state | Engineering | **Capture-before-overwrite**: all 11 bodies captured and merged to `main` before any `gh release edit` runs; per-version verify after each | IRREVERSIBLE |
| R2 | The #3809 fix surfaces pre-existing findings and reads as a regression | Engineering | Remediate the 2 affected notes in-release (operator decision at Stage 5). Framing: Check 20 is **already RED** and **warn-mode** — this is red→redder, not green→red | CHEAP |
| R3 | Producer (#4451) and gate (#4452) agree in prose but not in bytes | Engineering | CIAC-1 grades byte-identity of the emitted vs asserted tokens | CHEAP |
| R4 | Cross-release contention with open PR #4568 on `hub-spoke-bridge.md` | Hub | Sequence at Stage 6; re-check mergeability at Stage 9 Phase A6.5 | CHEAP |
| R5 | The concurrent milestone #299 claims `v4.07` first | Hub | Two-phase claim: the Stage-12 compare-and-swap resolves it; the loser re-versions upward | CHEAP |

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 (#4451 × #4452 — the close-out output contract):** the field name and block heading the producer emits are **byte-identical** to the tokens the gate asserts — the Phase-B velocity field and the `#### Release Learnings v<X.Y>` block. *Issues spanned:* #4451, #4452. *Shared surface:* the emitted token set in `release/tools/automated-closeout.sh` vs the asserted token set in `core/deploy/deploy.sh` Check 48. *Method:* extract each asserted literal from Check 48 and `grep -F` it against the closeout emit path; expect 1:1 correspondence with **zero orphans on either side**, with the extraction shown non-empty.
- [ ] **CIAC-2 — RETIRED.** It spanned #3809 × #3698 on `release-notes-standard.md`; #3698's de-bundling leaves it with no second party, so it is not gradable. Retired with that reason recorded.
- [ ] **CIAC-3 (#3809 — layout-independence, graded on this card alone):** the lint's discovery rule resolves **every** note under the live layout and contains **no hardcoded** `_unversioned/` or major-version subfolder segment. *Shared surface:* the discovery globs in `core/deploy/tools/lint_release_corpus.py` vs the `release/releases/notes/` tree. *Method:* assert `rglob("v*.md")` occurrences = **0** in the file (control: the two `rglob("v11.04b-3*.md")` sites still = 2); assert the discovery count equals the full `*_RELEASE_NOTES.md` population (**166** at the Commit-0 baseline); assert no subfolder literal appears at either call site.

## Verification Plan

### Per-issue AC → verification method

**#3809 — note-content lint reaches version-less notes**

| AC | Method | Expected observable |
|---|---|---|
| AC-1 standard states scope | read §3.2 | unambiguous in-scope statement present; the layout and naming rules untouched |
| AC-2 discovers all 11 | `rglob("*_RELEASE_NOTES.md")` count under `NOTES_DIR` | **166**; the 10 `_unversioned/` notes plus the flat `governance-ci-checks_RELEASE_NOTES.md` all present |
| AC-3 actually linted, not floor-skipped | run the negative-control harness | **must-flag path appears verbatim in stdout**; must-not-flag absent; exit 1 |
| AC-4 no hardcoded layout segment | read both call sites | no `_unversioned` / `v1` / `v2` / `v3` literal in either glob |
| AC-5 both call sites fixed | `grep -cF 'rglob("v*.md")'` on the lint | **0**; control — `grep -cF 'rglob("v11.04b-3*.md")'` still **2** |

**Regression assertions for #3809 (Stage 7 DT).** Corpus-wide `--check note-content` returns **exactly 12** findings at exit 1 *after* the approved remediation lands (the widening adds 13 and the remediation removes 13). **Zero** baseline findings lost. `_find_note_for_version()` resolutions unchanged for version-keyed inputs — **expected: no behaviour delta from that call site; do not record its absence as a defect.** The three non-subject `rglob(` sites unchanged.

**#3699 — published bodies match their canonical notes.** Full-population re-probe after re-emit, with both control arms reported and the denominator stated. Per-version `check-release-body-drift.sh` must return exit 0 before the next version is touched.

**#4451 / #4452 — producer and gate.** CIAC-1 above. Plus: `deploy.sh --self-test` fixtures re-pinned for the new outputs cutoff — **RUN at Stage 7, do not predict.**

**#3121 — sub-threshold disposition.** The near-threshold section renders on the live corpus, where the qualifying set is empty — the placement is load-bearing because the zero-qualifying path early-exits.

### Release-scoped verification

- `core/deploy/deploy.sh --check` — full run at Stage 7; every FAIL either fixed or explained.
- Doc-link integrity (Check 14) on all modified `.md` files.
- Skill-package freshness: `release/skills/release-executor/SKILL.md` is edited under #3699, so its `.skill` package and `.sha256` sidecar are rebuilt and committed in the SAME PR.

### Anti-vacuity discipline (release-wide)

**Four vacuity traps were found across this release**, each defeating the previous obvious observable:

1. **Exit code** — the live gate reports `INCOMPLETE` and still exits 0.
2. **Corpus-wide grep** — matches somewhere in the corpus without proving the subject surface changed.
3. **"The file changed"** — a diff is not a behaviour delta.
4. **"The field parses"** — a wrong-surface write is identical to a correct one under exit code, grep, and grammar; only co-location separates them.

Every verification method above therefore names an observable that survives all four. Every count carries its denominator, a sensitivity arm with an observed non-zero, and a specificity arm with an observed zero. **A zero whose control arm also returned zero is a BROKEN PROBE, not a clean result.**

## Rollback Strategy

**Whole-release reversibility: MODERATE / Confidence HIGH.**

- **Reversible (all git-revertable):** every file change in the matrix above. `git revert -m 1` of the release PR restores each file's bytes. No state migration, no deploy step for the content edits.
- **IRREVERSIBLE:** #3699's re-emit of eleven published GitHub Release bodies. Mitigated — not undone — by the capture-before-overwrite gate: all eleven prior bodies are captured to `release/releases/_captures/` and merged to `main` before the first `gh release edit`, so the prior state is recoverable from the repo even though the published surface is not revertable by git.
- **Partial-ship is NOT safe for #3809.** Splitting its discovery fix from its floor fix produces a measured no-op at the intermediate state while making the gate *read* as covering notes it drops. That member lands whole or not at all.

## Operator Decisions (D-Gate Block)

| ID | Decision | Verdict | Rendered |
|---|---|---|---|
| D-A | Release-notes corpus layout | **#3698 DEFERRED and de-bundled** pending #4455 | 2026-08-02 |
| D-B | Are version-less notes in scope for the §3.2 content checks? | **IN SCOPE** — resolved by plan approval; the approved Outcome Statement says the lint *actually scans* them | 2026-08-02 |
| D-B2 | Does check 13 (link purity) also apply to version-less notes? | **Variant A (narrow)** — content checks only; +13 findings on 2 notes, not Variant B's +24 on 8 | 2026-08-02 |
| D-C | Branch topology | **SINGLE** — one branch, one PR, one merge | 2026-08-02 |
| D-D | How is #3699 re-scoped against measured state? | **Re-scoped**: 10 drifting versions plus CI enrollment; re-sized `S → L`; capture-before-overwrite added as an AC | 2026-08-02 |
| D-ReleaseClass | Release Class | **`routine` held, with Deep Stage-9 review depth** | 2026-08-02 |
| D-Concurrency | Stage-6 parallelism posture | **P0 fully-serial** | 2026-08-02 |
| D-Version | Version determination | **`v4.07`** (re-determined from `v4.06` on 2026-08-03 when #290 claimed `v4.06`). Recorded determination, **not a gate** — binds at the Stage-12 claim | 2026-08-03 |
| — | Blast radius of the #3809 widening | **REMEDIATE IN-RELEASE** — 12 impact beats + 1 missing section | 2026-08-02 |
| — | BS-4 (Check 48 sub-check (g) flat-path blindness) | **Route into #4452's Stage-5 brief** as a named finding | 2026-08-02 |
| — | v4.06 learnings backfill | **DO IT** — a clean arming baseline for #4452; recorded scope cross, finding owned by #4573 | 2026-08-03 |
| — | BS-4 fabrication half | **DEFER** (zero in-scope foldered notes today); filed separately as #4703 | 2026-08-03 |
| — | Capture-passthrough surface | **Spoke decline UPHELD** as re-inflation of the 2026-08-01 trim; filed as #4704 for independent triage | 2026-08-03 |

## Deviation Log

**DEV-1 — The pinned baseline moved before Engineering started.** `governance-hardening` (#290) merged to `main` and shipped as **v4.06** while this release was in Stage 5, advancing the baseline `7943ae4a → 41d12ed8` (8 commits) and closing 94 issues including **#4455** — the XL card assessed at the plan gate as "real but not imminent". It was imminent. Resolved by construction: this release branch is cut from post-merge `main`. D-Version was re-determined `v4.06 → v4.07`; because all pre-claim artefacts are slug-keyed per ADR-092, the correction cost one line rather than a rename cascade.

**DEV-2 — #4455's landed change is confirmed non-colliding with #3809.** Stage 5 predicted the collision as **LOW** — same file, disjoint functions. Verified at Commit 0 against the actual landed diff: `core/deploy/tools/lint_release_corpus.py` changed by **+33 / −25**, entirely within the module docstring, the retired `check_index_row_count()` block, and the `main()` dispatch. **Zero** line-range overlap with `check_note_content()` or `_find_note_for_version()`. The prediction is now a measurement.

**DEV-3 — the corpus denominator moved by one.** Stage 5 measured 166 files / 165 notes / 154 scanned at pin `7943ae4a`. At Commit 0 the tree holds **167 files / 166 notes / 155 scanned** — the `v4.06` note, added by #290's close-out. **The gap is invariant at exactly 11**, and the eleven gained paths are byte-identical to the Stage-5 enumeration. Every count downstream of this plan is stated against the Commit-0 denominator, not the Stage-5 one.

**DEV-4 — #4451's Stage 5 was re-run against current main.** `automated-closeout.sh` was rewritten `+563 / −168` under #290's "one projector over typed sources". Finding and function anchors survived; line-level placements did not. The re-run (sub-task #4578) found **3 INVALIDATED** placements the pre-sweep design would otherwise have carried into Engineering.

**DEV-5 — event-log retag (operator-authorized).** 16 rows emitted pre-claim under `v4.06` were retagged to `v4.07`. They belonged to this release and would otherwise have polluted every query against `governance-hardening`'s genuine `v4.06` history. Backup retained. Root cause is hub error — applying a version to pre-claim events instead of honouring slug-primary.

## Out of Scope — Logged, Not Acted On

1. **BS-4 — `deploy.sh` Check 48 sub-check (g) is blind to every foldered note.** It greps a flat version-stem path while the lint emits foldered paths, so a foldered note's finding never matches. Routed into #4452's Stage-5 brief; the fabrication half filed as #4703.
2. **`release-notes-standard.md` naming and flat-layout rules are both contradicted by the live corpus.** Owned by #3698, deferred by operator decision.
3. **`release/releases/plans/` carries a mixed flat-slug and foldered-version layout.** Recorded so the deferral is made on complete information; not this release's scope.
4. **Check 20 has been RED for some time and is warn-mode, so nothing surfaces it.** Same systemic pattern as #3699's root cause — an armed gate with no automatic invocation path — on a different check. Worth intake.

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing. Populated as each member lands; see the release PR body for the current state.*

### Outcome

Three release-facing surfaces stop claiming coverage they do not have. The note-content lint reads every release note instead of only the ones whose filename starts with a version number. Every published release page matches the note that is supposed to be its source. And the close-out routine both writes its required end-of-release facts and is checked on whether it wrote them.

### Issues delivered

#3809 · #3699 · #4451 · #4452 · #3121. All five are marked as closed at Stage 13; none closes at merge.

### Key decisions

Version-less notes are **in scope** for the content checks and are admitted by an explicit version-less branch rather than by lowering a floor — the floors encode a real forward-only policy and are left untouched. The published-body repair is **detective plus operator-executed**, never auto-remediating, because the surface is public and irreversible.

### Reversibility

**MODERATE / Confidence HIGH.** Every file change reverts with `git revert -m 1`. The eleven re-emitted release pages do not revert; their prior bodies are captured into the repo before the first overwrite.

### Downstream impact

*(Populated at Stage 6 completion.)*

### Cross-references

Milestone #305 · Stage-4 plan #4507 · Stage-5 designs #4538, #4542, #4546, #4550, #4554, #4578 · Stage-9 review #4558.

## Identity Note (ADR-092)

This plan file and its branch are **slug-primary**. The identity field in the header carries the literal `{{RELEASE_VERSION}}` token and is **deliberately left unresolved**: `claim-version.sh --stamp-slug` resolves it to the won tag on the compare-and-swap win path and renames this file to the version-keyed form in the same stamp commit. The token is load-bearing, not decorative — the stamp pre-flight **HALTs the claim** on a plan that carries none, and the slug-primary conformance check keys its pre-claim window on the token's presence, so a plan that hardcodes its provisional number instead is skipped by the very check meant to grade it.

The concrete version named in § Commit-0 Version Re-Verify is a **dated measurement**, not an identity binding — it records what was observed and computed at Commit 0 and is deliberately NOT tokenized, because resolving it at claim time would rewrite the evidence. Until the claim lands, no downstream artefact may treat any version as claimed for this release.

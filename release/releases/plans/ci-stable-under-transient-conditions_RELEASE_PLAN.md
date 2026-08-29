---
title: Release Plan — ci-stable-under-transient-conditions
purpose: Stage-4 release plan for the ci-stable-under-transient-conditions bundle, reconciled to the eight approved Stage-5 Solutioning designs and the Collective-Review scope-lock.
type: release-plan
plan_type: release
status: ACTIVE
release: ci-stable-under-transient-conditions
milestone: 353-ci-stable-under-transient-conditions
release_class: cross-cutting
reversibility: MODERATE / Confidence HIGH
consumers: Stage 5-9 spokes; the release hub; Stage 9 Plan Review
---
<!-- reference-durability: allow-link -->

# Release Plan — `ci-stable-under-transient-conditions`

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #6123, reconciled to the eight approved **Stage-5 Solutioning** designs (#6124, #6133, #6134, #6135, #6136, #6137, #6139, #6140 — #6138 was skipped-trivial) and the **Collective Review scope-lock** dispositions posted on #6123. Where a Stage-5 or scope-lock disposition superseded a Stage-4 assumption, the transcribed sections **preserve the Stage-4 plan of record** and the [§ Deviation Log](#deviation-log) records the ratified delta. Authored at **Engineering Commit 0** by the first Engineering spoke (sub-task #6146, issue #5240).

## Header

| Field | Value |
|---|---|
| **Milestone** | `ci-stable-under-transient-conditions` (#353) |
| **Version** | `{{RELEASE_VERSION}}` |
| **Bump Class** | `minor` — the durable determination. This plan is **slug-primary**; the concrete number is not carried here and binds only at the **Stage-12 atomic claim**, when `claim-version.sh --stamp-slug ci-stable-under-transient-conditions` resolves the token above and renames this file into `plans/v<MAJOR>/` (ADR-092). Recomputed at Engineering Commit 0 per the authoritative-version-selection procedure against freshly-fetched authoritative state: origin tags max **v4.38**, published-Releases max **v4.38**, `RELEASE_LOG` mainline rows max **v4.38** ⇒ next-free **v4.39**, corroborated by `claim-version.sh --dry-run` (see [§ Commit-0 Version Re-Verify](#commit-0-version-re-verify)). |
| **Topology** | **D-C SINGLE** — one branch (`release/ci-stable-under-transient-conditions`), one PR, one merge gate |
| **Concurrency posture** | **P0 fully-serial**. All nine slices land serially on the one branch. Force-push on the shared release branch is prohibited, including `--force-with-lease`. |
| **Release Class** | `cross-cutting` — re-classified from the milestone-declared `routine` at the Stage-4 plan gate (D2, 2026-08-27). Trigger (a) fires with margin; see [§ Release Class Declaration](#release-class-declaration). |
| **Differentiation posture** | Engagement density **Tight** · Stage 9 review depth **Deep** · Stage 5 activation bias **ALL** · Stage 13 outcome-window **30-day** |
| **Size** | **26 pts** across 9 issues — 5 × `size:S` + 4 × `size:M`. The 26-pt deviation was operator-accepted 2026-08-15 and is **not re-opened**. |
| **Date Created** | 2026-08-27 (Thursday) |
| **Release Manager** | Agent-assisted (release hub, hub-spoke topology) |
| **Status** | Executing |
| **Branch** | `release/ci-stable-under-transient-conditions` |
| **Baseline** | `origin/main` @ `8dc00db134b500d16f7168e16bfe4cd604d41b8e`, 2026-08-23T19:05:11-05:00. Mainline had not advanced at Commit-0 time. |
| **Provenance** | Bundled 2026-08-14; Mode R readiness pre-flight 2026-08-15; Stage-4 plan approved 2026-08-27 (#6123); Stage-5 → 6 scope-lock 2026-08-27 (#6123) |

### Commit-0 Version Re-Verify

Run before this file was written, per `hub-spoke-bridge.md` Procedure 0 § Canonical location steps 1–3.

| Arm of `claimed_set()` | Denominator | `v4.39` | Sensitivity | Specificity |
|---|---|---|---|---|
| origin tags (`git ls-remote --tags origin`, post-`git fetch --tags`) | 362 refs · 39 `v4.x` | **0** | `v4.38` × 1, `v4.37` × 1 | `v4.99` × 0 |
| published GitHub Releases | 180 releases · 39 `v4.x` | **0** | `v4.38` × 1, `v4.37` × 1 | `v4.99` × 0 |
| mainline ledger rows — `git show origin/main:release/releases/RELEASE_LOG.md` | 182 structured version rows · 39 `v4.x` | **0** | `v4.38` × 1 | `v4.99` × 0 |

`anchor()` = **v4.38**; bump-class floor `minor` ⇒ recomputed next-free = **v4.39**; `v4.39` is absent from all three arms **and** equals the recomputed next-free ⇒ **PROCEED**. Independently corroborated by the adapter itself: `claim-version.sh --sha 8dc00db1… --bump minor --dry-run` → `v4.39` (exit 0, no tag pushed). Zero in-flight `DEPLOYED`-not-`VERIFIED` rows on the ledger.

**Recorded contention, not a claim.** Draft PR #6119 carries `v4.39` in its *title* and is unmerged; `claimed_set()` unions published Releases ∪ origin tags ∪ `DEPLOYED` ledger rows, and a draft-PR title is none of those. Per ADR-092 the slot binds at whichever release reaches the Stage-12 CAS first; the loser re-versions up, which is routine and not an error. This plan therefore carries no baked number — the token above is the only version identity it holds.

## Scope

### Issues Included

| # | Issue | Title | Size | Labels | ADR |
|---|---|---|---|---|---|
| 1 | #5240 | `extract-usage.sh` carries a same-direction fail-open distinct from the `--incremental` defect | S | `bug`, `cluster: automation`, `size:S` | — |
| 2 | #5067 | Pattern auto-promotion can never fire: the promoter invokes bare `gh` under a pinned PATH, and its label does not exist | M | `bug`, `cluster: automation`, `size:M` | warranted |
| 3 | #4227 | Quota-budget protocol models only per-wave usage-window draw: serial accumulation is ungated and the host-API axis is unmodelled | M | `improvement`, `cluster: process-protocol`, `size:M` | warranted |
| 4 | #4200 | Quota-budget Checkpoint B has no wave-width heuristic — interruption cost scales with width, total draw does not | M | `improvement`, `size:M` | warranted |
| 5 | #4974 | A CONFLICTING PR dispatches no gates, so a conclusion-only check read reports green against a collapsed denominator | S | `bug`, `cluster: automation`, `size:S`, `project:pipeline` | not warranted |
| 6 | #5268 | Sweep `automated-closeout.sh` for pre-mode-branch resolution — third instance found at phase 9.5 `append_changelog` | S | `bug`, `cluster: automation`, `size:S` | warranted |
| 7 | #4416 | Check 5's post-close re-read loses to GraphQL index lag — single 2s retry under-settles on the last-closed issue | S | `bug`, `cluster: automation`, `size:S`, `project:pipeline`, `type:bug` | not warranted |
| 8 | #4912 | `sed` frontmatter-strip idiom fail-opens on GNU — `check-release-body-drift` reports no drift on Linux regardless of drift | S | `bug`, `cluster: automation`, `size:S` | warranted |
| 9 | #5253 | Coverage rule for `core/deploy/tools/README.md` ships with no mechanical enforcement | M | `improvement`, `cluster: documentation`, `size:M`, `project:pipeline`, `type:task` | warranted |

Priority limb (load-bearing for the Release Class): **#4912 is P1 - Critical**, **#4974 is P1 - Significant**, **#5067 is P2 - Material**.

### Exclusions

No merges, no splits, no deferrals. **Scope locked** at Collective Review (D-CR4) — 9 members. Merging #4227 + #4200 was among the options the operator reviewed and declined at the 2026-08-15 pre-flight and is not re-proposed; they remain distinct cards for traceability while behaving as one slice at the file level.

## Dependency Graph

Directional. `A → B` reads *A must land before B*.

```
                     (external, DISCHARGED)
  #4891 ──(state: closed, 2026-08-12)──▶ #5253

  HARD BUILD-ORDER EDGE (carried from Mode R pre-flight, not re-opened)
  #4227 ──────▶ #4200
      shared lines: quota-budget-protocol.md § Checkpoint B
                    spoke-launch.md § Concurrency

  FILE-SERIALIZATION CLUSTER (no logical dependency; one file, three claimants)
  #5268 ──▶ #4416 ──▶ #4912        all on release/tools/automated-closeout.sh

  INDEPENDENT (no in-bundle edge, inbound or outbound)
  #5240      #5067      #4974      #5253
```

**Logical dependencies inside the bundle: zero.** No member's correctness depends on another member's output. Every edge above is either discharged-external (#4891) or **contention-derived** — a build-order constraint arising from shared write surfaces, not a semantic prerequisite. The distinction matters: a contention edge is satisfiable by ordering alone and cannot block the release; a logical edge could.

**Circular chains: 0** over a denominator of 9 members and 3 edges. The edge set is a DAG by construction — `#4227 → #4200` and `#5268 → #4416 → #4912` share no vertices. Control arm: a synthetic `#4200 → #4227` edge closes a 2-cycle and is detected, so the absence of a cycle is measured, not asserted.

**Cross-release edges (open, not satisfiable inside this release):**

| Edge | Direction | Class |
|---|---|---|
| PR #6119 `selftests-actually-test` ↔ **#5253** | bidirectional serialization on `release/tools/check-selftest-coverage.py` | Tier-S — one merges, the other re-baselines |
| PR #6120 `pipeline-spec-self-consistency` ↔ **#4227 #4974 #5067 #4416 #4912 #5268** | bidirectional serialization on shared paths | Tier-S |
| PR #6119 (v4.39 provisional stamp) ↔ this release's version identity | version-slot contention | provisional until the Stage-12 atomic claim |
| **#4714** (OPEN issue, milestone `note-resolver-and-corpus-lint`) ↔ **#4912** | shared edit surface `release/tools/check-release-body-drift.sh` | **Unmapped at Stage 4** — routed at scope-lock; re-check before touching that file |

## Implementation Sequence

**D-Concurrency Posture: P0 fully-serial (D-C SINGLE topology).** The contention map independently justifies it — three members on one 12,428-line file, two on the same protocol section, two unmergeable binary artifacts. Recorded, not raised as a gate.

One release branch. One PR. One merge. Commits land in this order:

| # | Issue | Slice | Why here |
|---|---|---|---|
| 1 | **#5240** | `extract-usage.sh` `do_incremental()` — make both drop-set suppression sites fail loud; add the mutation arm | Fully isolated: zero intersection with any other member and with both sibling PRs. Banks work before the contended surfaces open — the write-early posture #4227 itself argues for |
| 2 | **#5067** | Lazy absolute-`gh` resolution; declare `auto-promoted-pattern` in `core/packs/_common/pack.toml`; add the `provenance` group to `label-taxonomy.md`; reconcile `stage-13-close.md` Phase A7 | Isolated from every other member. Collides only with sibling #6120 on `stage-13-close.md` |
| 3 | **#4227** | Checkpoint B host-API second axis in a **new sibling § 4.3b**; write-early guidance in the bridge; `stage-04-planning.md` § 5.8; `release-hub/SKILL.md` | **FIRST of the hard pair.** Adds the second axis to the input contract; #4200 then layers width guidance onto the verdict that axis feeds |
| 4 | **#4200** | Checkpoint B `W_max` width output; `hub-spoke-bridge.md` consuming rules; `spoke-launch.md` § Concurrency; rebuild `packages/release-hub.skill` | **SECOND of the hard pair — never parallel.** Both cards rewrite the same Checkpoint B region and the same § Concurrency paragraph |
| 5 | **#4974** | Denominator assertion at Stage 7 / 8 entry, lifting the shipped `release-readiness-scan-spec.md` § 5.1 six-state classifier | Placed adjacent to #4227 so all pipeline-spec edits form one contiguous region — a single rebase pass answers sibling #6120 for the whole surface instead of four |
| 6 | **#5268** | Relocate the mode branch in `phase_append_changelog` (15.5's shape); AC3 regression arm in `self_test()`; `phase_assert_anchor_hygiene` (15.55) | **FIRST of the closeout cluster.** It is the structural sweep; landing it first means the two point-fixes rebase onto a swept baseline. Reversed, the sweep's denominator would shift under it mid-flight |
| 7 | **#4416** | Replace the single sleep-and-retry with an **attempt-bounded** settle poll (`VERIFY_RECHECK_ATTEMPTS`) | Bounded change to one retry path, disjoint from the phase-mode surface #5268 just swept |
| 8 | **#4912** | Extract the frontmatter strip to `release/tools/lib/frontmatter-strip.sh` (awk state machine); align 2 Python mirrors; conformance fixture; empty-body guard; doc sweep | **LAST of the closeout cluster** — the only member reaching outside `automated-closeout.sh`; it should settle after the in-file work is stable |
| 9 | **#5253** | Add Arm E (HARD) to `check-selftest-coverage.py --reconcile`; backfill the 2 undocumented `core/deploy/tools/README.md` rows | **LAST overall.** Heaviest sibling contention (#6119 widens the same engine), so the rebase window is shortest here; and its check's denominator is verified against the final tool population |

**Hunk-disjointness declarations on `release/tools/automated-closeout.sh`** (confirmed at scope-lock; line pins are current-at-`8dc00db1` only — resolve by symbol):

| Member | Declared regions |
|---|---|
| #5268 | `phase_append_changelog` `:3796-3908` · `self_test()` `~:7037-7090` · `phase_assert_anchor_hygiene` `:6071-6122` |
| #4416 | `:539` (declaration) · `:5671` (settle region in `phase_run_verification`) · `:8701-8780` (self-test group 4d.3) |
| #4912 | `SCRIPT_DIR` preamble · `phase_publish_github_release()` |

**Zero overlap.** #4912 touches no line of `self_test()`.

**`#4227 → #4200` interface (mandated coordination).** §§ 4.3 / 4.3a are **untouched by #4227**; the host-API axis lands in a **new sibling § 4.3b**, and the opaque pass-through carries #4200's width guidance with zero edits from #4227. Neither card overwrites the other.

Each slice is `mark #N as closed at Stage 13`; **no member closes mid-release.**

## Stage Applicability Matrix

Default all. Stage 9 is a gate (no spoke). Stages 10 and 11 are **PLATFORM-SATISFIED** for git-native releases — the Stage 9 PR diff *is* the dry run and git history *is* the snapshot, per their own specs — so they are release-scoped and carry no per-issue row.

| Issue | Size | 5 Solutioning | 6 Eng | 7 DT | 8 QA | 9 Review | 12 Exec | 13 Close |
|---|---|---|---|---|---|---|---|---|
| #4200 | M | **YES** — the width heuristic itself is the design | YES | YES | YES | gate | rel | rel |
| #4227 | M | **YES** — a new pre-launch check on a second axis is a design, not a transcription | YES | YES | YES | gate | rel | rel |
| #4416 | S | **YES** — the poll budget must be sized against observed lag, not guessed (AC6) | YES | YES | YES | gate | rel | rel |
| #4912 | S | **YES** — two forks: which portable form, and which occurrences are in the obligation set | YES | YES | YES | gate | rel | rel |
| #4974 | S | **YES** — the assertion target is undecided in the card | YES | YES | YES | gate | rel | rel |
| #5067 | M | **YES** — the card names its own fork for `stage-13-close.md` Phase A7 | YES | YES | YES | gate | rel | rel |
| #5240 | S | **SKIP — trivial** | YES | YES | YES | gate | rel | rel |
| #5253 | M | **YES** — must re-baseline against ADR-119's engine and sibling #6119's head | YES | YES | YES | gate | rel | rel |
| #5268 | S | **YES** — the C2 fork is a genuine design decision | YES | YES | YES | gate | rel | rel |

**The one skip, justified explicitly.** #5240 is a bounded change with a named in-file precedent ~6 lines below the defect (the #4188 fix: fail-closed with `return 3`, comment *"Never `2>/dev/null || true` on this path"*). There is nothing to design — the shape to copy is adjacent to the defect. This is the only member meeting the trivial bar; the other eight each carry a stated or discovered fork. **All eight fired and closed.**

**No Stage 7/8 skips.** Every member has functional impact, including the two protocol-only cards: their ACs are replay-shaped and gradeable. Collapsing those into CI plus a Stage-9 read would leave them ungraded.

**Parallel-eligible counts** (feeds Checkpoint A): Stage 5 = **8** · Stage 7 = **9** · Stage 8 = **9**. Worst parallel batch = **9**.

## Contention Map

### Within-release

| Path | Claimants | Section / region | Resolution |
|---|---|---|---|
| `release/references/standards/quota-budget-protocol.md` | **#4227, #4200** | #4227: new § 4.3b + § 3.1 / § 6.1 axis-scoping. #4200: § 4.3 / § 4.3a verdict output | **Hard serial, #4227 then #4200.** Interface fixed at scope-lock: §§ 4.3 / 4.3a untouched by #4227 |
| `release/skills/release-hub/references/spoke-launch.md` | **#4200, #4227** | § Concurrency, gate-2 paragraph — a cite-not-restate summary of both gates | Same serial pair. The paragraph summarizes the protocol, so both axes land in the same sentence |
| `release/references/how-to/hub-spoke-bridge.md` | **#4227, #4200** | #4227: write-early guidance. #4200: 2 of 3 `PROCEED → launch all N` consuming rules | Same serial pair. **Scope addition** for #4200 — without it `W_max` ships inert |
| `release/skills/release-hub/SKILL.md` | **#4227** | the "zero tool calls" assertion falsified by the measured gate | **Scope addition.** Single claimant |
| `release/tools/automated-closeout.sh` | **#5268, #4416, #4912** | disjoint regions declared above | **Serial: #5268 → #4416 → #4912.** Structural sweep first so point-fixes rebase onto a settled denominator |
| `packages/release-hub.skill` + `.sha256` | **#4200, #4227** | whole artifact (zip) | **Rebuild, never merge.** Rebuild once, after slice 4 |
| `release/references/pipeline/stage-04-planning.md` | **#4227** | § 5.8 Phase A6 input table | Single claimant |
| `release/references/pipeline/stage-07/-08` | **#4974** | Stage 7 Phase A entry; Stage 8 Phase A entry | Single claimant across two files (`stage-09` dropped — see Deviation Log row 3) |
| `release/references/pipeline/stage-13-close.md` | **#5067** | Phase A7 auto-promotion statement | Single claimant |
| `core/specs/label-taxonomy.md` | **#5067** | new `provenance` group | Single claimant. `LABEL-GRAMMAR-ROW` **FIRES** — see Deviation Log row 5 |
| `core/deploy/tools/README.md` | **#5253** | inventory table — 2 backfilled rows | Single claimant |

### Cross-PR

Baseline-pinned at `8dc00db1`, measured 2026-08-27. Both siblings are **drafts based on the same commit as this release**, so every intersection is a live collision, not a historical one. Hub-verified totals at scope-lock: **#6120 → 14 shared paths**; **#6119 → 5 shared paths**.

| Sibling | Shared path | This release's claimants | Severity |
|---|---|---|---|
| #6120 | `release/tools/automated-closeout.sh` | #5268, #4416, #4912 | **HIGH** — 3 of 9 members |
| #6120 | `release/references/pipeline/stage-08-qa-testing.md` | #4974 | HIGH |
| #6120 | `release/references/pipeline/stage-09-plan-review.md` | *(none — dropped at Stage 5)* | **retired** |
| #6120 | `release/references/pipeline/stage-04-planning.md` | #4227 | MODERATE |
| #6120 | `release/references/pipeline/stage-13-close.md` | #5067 | MODERATE |
| #6120 | `release/references/how-to/hub-spoke-bridge.md` | #4227, #4200 | MODERATE |
| #6120 | `packages/release-hub.skill` + `.sha256` | #4200, #4227 | **HIGH** — binary; no 3-way merge exists |
| #6119 | `release/tools/check-selftest-coverage.py` | #5253 | HIGH — **softened** from CRITICAL at scope-lock: measured **+62/−7**, a widening not a rewrite |
| #6119 | `core/deploy/allowlists/selftest-coverage-manifest.txt` | #5253, #4912 (conditional) | HIGH |
| #6119 | `core/deploy/allowlists/selftest-coverage-exclusions.txt` | #5253 (conditional) | MODERATE |
| #6119 | `.github/workflows/release-tooling-smoke.yml` | #4912 AC4 (conditional) | MODERATE |

**`overlap_class`** (ADR-005): every intersection is `line-range-overlap`, not `append-pattern` — targeted edits to existing prose and code, not appends to a growing table. The append-pattern informational discount does **not** apply; ADR-001 sequencing/scope-split mitigation is retained. The two `packages/*.skill` rows are a third case the enum does not model: binary artifacts where any concurrent edit is a guaranteed conflict.

**Structural blast radius (A4 sub-audit): CLEAN, with a pinned denominator.** A mover-classifier over both siblings' full file lists returned **zero** rows outside `added` / `modified` — no rename, no relocate, no delete. `SURFACE(R)` is empty and no Tier-S mover edge exists. Baseline pinned at `8dc00db1` / 2026-08-27; the sibling population (n=2 open PRs, 6 remote `release/*` heads) is transient and **must be re-measured at Stage 9 Phase A6.6**.

**In-flight sibling population, recorded:** open `release/*`-head PRs = **2** (#6119, #6120, both draft at Commit 0). Remote `release/*` heads = **6**; four carry no open PR and were not editset-measured, so their intersections are **UNRESOLVABLE at this baseline, not zero**.

## File Change Matrix

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-27, domain: governance }`

*Classification rationale (A3-time):* 21 unconditional Stage-4 rows — 9 governance/pipeline-spec documents, 8 executable tools, 3 config/package artifacts, 1 release plan. Dominant domain **governance**; secondary **software**. Every path is an internal pmo-platform artifact, so A1.5 external sourcing does not fire.

```
# ── Unconditional edits + adds (Stage-4 plan of record) ─────────────────────
release/releases/plans/ci-stable-under-transient-conditions_RELEASE_PLAN.md  add
core/deploy/tools/README.md  edit
core/deploy/tools/lint_release_corpus.py  edit
core/packs/_common/pack.toml  edit
core/skills/finops-usage-extractor/scripts/extract-usage.sh  edit
packages/release-hub.skill  edit
packages/release-hub.skill.sha256  edit
release/references/how-to/hub-spoke-bridge.md  edit
release/references/pipeline/stage-04-planning.md  edit
release/references/pipeline/stage-07-dev-testing.md  edit
release/references/pipeline/stage-08-qa-testing.md  edit
release/references/pipeline/stage-09-plan-review.md  edit
release/references/pipeline/stage-13-close.md  edit
release/references/standards/quota-budget-protocol.md  edit
release/skills/release-hub/references/spoke-launch.md  edit
release/tools/automated-closeout.sh  edit
release/tools/check-release-body-drift.sh  edit
release/tools/check-selftest-coverage.py  edit
release/tools/preflight-release-body-reemit.py  edit
release/tools/reemit-release-bodies.sh  edit
release/tools/synthesize-release-learnings.sh  edit
```

```
# ── Stage-5 ratified delta to the unconditional set (see Deviation Log) ─────
core/specs/label-taxonomy.md  edit           # LABEL-GRAMMAR-ROW FIRES (#5067 D-4)
release/skills/release-hub/SKILL.md  edit    # scope addition (#4227)
release/tools/lib/frontmatter-strip.sh  add  # shared awk transform (#4912)
release/references/standards/release-notes-standard.md  edit   # IDIOM-DOC-SWEEP FIRES (#4912)
release/references/pipeline/stage-12-execute.md  edit          # IDIOM-DOC-SWEEP FIRES (#4912)
release/references/specs/release-readiness-scan-spec.md  edit  # R3 consumers: note (#4974) — 2 lines; see Deviation Log row 24
release/releases/notes/README.md  edit                         # IDIOM-DOC-SWEEP FIRES (#4912)
release/skills/release-executor/SKILL.md  edit                 # IDIOM-DOC-SWEEP FIRES (#4912)
packages/release-executor.skill  edit                          # IDIOM-DOC-SWEEP FIRES (#4912)
packages/release-executor.skill.sha256  edit                   # IDIOM-DOC-SWEEP FIRES (#4912)

# ── Stage-5 ratified REMOVAL from the unconditional set ─────────────────────
release/references/pipeline/stage-09-plan-review.md  NOT EDITED  # #4974 design: Stage 9 already discharges both AC limbs
```

```
#### CONDITIONAL rows — Stage-5 resolutions recorded
core/deploy/allowlists/selftest-coverage-manifest.txt    CONDITIONAL:PARTITION-STORED   → DOES NOT FIRE
core/deploy/allowlists/selftest-coverage-exclusions.txt  CONDITIONAL:PARTITION-STORED   → DOES NOT FIRE
.github/workflows/release-tooling-smoke.yml              CONDITIONAL:PARTITION-STORED   → DOES NOT FIRE
core/config/allowlists/script-execution-allowlist.txt    CONDITIONAL:NEW-EXECUTABLE     → DOES NOT FIRE (the lib is sourced, never executed)
.github/workflows/release-tooling-smoke.yml              CONDITIONAL:SELFTEST-FETCH-DEPTH → conditional on #4912 D6 branch (b); unresolved at Commit 0
```

```
#### Release-wide explicit non-scope
release/releases/plans/v2/v2.37_RELEASE_PLAN.md  NOT EDITED
release/references/standards/_examples/dual-write-illustrative-v2.01.md  NOT EDITED
```

Both carry the non-portable `sed` idiom in prose and both are **immutable historical artifacts** — a shipped release plan and a frozen illustrative example. They are excluded from #4912's obligation set by construction, which is precisely why AC1's global `git grep → 0` form cannot be satisfied and must be scoped to executable call sites.

```
#### Read-only inputs
release/references/specs/release-class-taxonomy.md  READ
release/references/standards/triage-design-rereview.md  READ
release/ADRs/ADR-119-selftest-coverage-is-discovered-with-a-committed-manifest-floor.md  READ
core/deploy/tools/check-label-parity.py  READ
```

**New-executable companion obligation.** The Stage-4 matrix carried no `add` row for a tracked `*.sh`. Stage 5 added one — `release/tools/lib/frontmatter-strip.sh` — and resolved `NEW-EXECUTABLE` as **DOES NOT FIRE**: the library is `source`d, never executed, and all three existing `release/tools/lib/*.sh` are likewise absent from `script-execution-allowlist.txt`. Stated affirmatively so the absence is a checked result rather than an omission.

## ADR Allocation

**D-CR2 (Collective Review): follow the oracle — allocate from 142.** Ratified basis: `renumber-adr.py --next-free` returns **142**; both unmerged siblings claim 142 and PR #6120 claims through 147, but the tool structurally cannot see unmerged PRs and **unmerged claims are advisory**. A numbering **gap** blocks the repo; a **duplicate** is tooled and reconcilable by `renumber-adr.py` once the siblings land.

Re-verified at Engineering Commit 0: `renumber-adr.py --detect` → `ANCHOR 141 (origin/main)` · `NEXT-FREE 142` · `CLAIMED-SET-BRANCH-ONLY 142,143,144,145,146,147 (detection only — never binds)`.

| Slot | Status | Claimed by |
|---|---|---|
| ADR-142 | **withdrawn — no longer allocatable** | Taken on `origin/main`: sibling PR #6119 **merged during Engineering** (`15e6bf01`), landing `release/ADRs/ADR-142-…`. The claim that was advisory at Commit 0 is now real, and the oracle re-anchored `ANCHOR 142 / NEXT-FREE 143` accordingly. See Deviation Log 21 |
| ADR-155 | **claimed** | #5067 — `core/ADRs/ADR-155-provenance-is-the-eighth-label-group.md` (slice 2) |
| ADR-156 | **claimed** | #4227 — `release/ADRs/ADR-156-checkpoint-b-second-axis-is-measured-not-declared.md` (slice 3). Lowest unclaimed slot per the allocation rule below; the oracle's live `NEXT-FREE 143` was correctly **not** used, since 143 is already taken on this branch by slice 2 |
| ADR-151 | **claimed** | #4200 — `release/ADRs/ADR-151-wave-width-is-a-second-checkpoint-b-output-not-a-verdict.md` (slice 4). Lowest unclaimed slot per the allocation rule; the oracle's live `NEXT-FREE 143` was again **not** used — 143 and 144 are already taken on this branch by slices 2 and 3. ADR index regenerated in the same commit |
| ADR-152 | **claimed** | #5268 — `release/ADRs/ADR-152-dry-run-predicts-apply-asserts-mode-branch-placement.md` (slice 6). Lowest unclaimed slot per the allocation rule; the oracle's live `NEXT-FREE 143` was again **not** used — 143, 144 and 145 are already taken on this branch by slices 2, 3 and 4. Verified free in BOTH ADR dirs on the branch and on `origin/main` before claiming. ADR index regenerated in the same commit |
| ADR-153 | **claimed** | #4912 — `release/ADRs/ADR-153-one-frontmatter-strip-bound-to-a-conformance-fixture.md` (slice 8). Lowest unclaimed slot per the allocation rule; the oracle's live `NEXT-FREE` was again **not** used — 143–146 are already taken on this branch by slices 2, 3, 4 and 6. Verified free in BOTH ADR dirs on the branch and on `origin/main` before claiming. ADR index regenerated in the same commit (`--verify` → `COUNT 0`). **The table is deliberately NOT extended:** this claim exhausts the five reserved slots, which matches the Stage-5 forecast of five distinct decisions from six proposals. If slice 9 (#5253) proves distinct rather than a dedup, it extends the table itself per the extension rule below |
| ADR-154 | **claimed** | #5253 — `release/ADRs/ADR-154-arm-e-population-is-the-directory-never-the-manifest.md` (slice 9). **The table is extended by one slot per the extension rule below**: the Stage-5 forecast of five distinct decisions from six proposals assumed one dedup pair, and no dedup materialized — #5253's decision (which SET a second invariant on a shared engine counts) is distinct from all five landed records, dedups into none of them, and extends ADR-119 rather than superseding it. Extension performed as the rule requires: oracle re-run against `origin/main` (`ANCHOR 142` · `NEXT-FREE 143`) **and** both branch ADR dirs scanned — 143–147 taken on this branch, 148 free in BOTH dirs and absent from `origin/main`. The only claim on 148 anywhere is unmerged sibling branch `origin/release/pipeline-spec-self-consistency`, which is **advisory** on D-CR2's own ratified basis; taking 149 to dodge it would open the numbering **gap** that D-CR2 identifies as the blocking failure, where a duplicate is tooled. `--detect` confirms `CLAIM ADR-154 … BINDS`; ADR index regenerated in the same commit (`--verify` → `COUNT 0`) |

**The Slot column carries FINAL numbers, and they are deliberately not ascending.** Rows stay in Implementation-Sequence order, which is the order the allocation rule reads in. Two collision recoveries have since moved the numbers off that order (Deviation Log 41 and 42): the second recovery moved **only** the two records the mainline actually collided with — slice 2 to **ADR-155** and slice 3 to **ADR-156** — and **held slices 4, 6, 8 and 9 fixed at 151–154**, because those four were uncontested. Moving all six would have stranded 151–154 as an empty range, and the contiguity gate fails a **gap** as readily as a duplicate. Each row's prose below records the reasoning as it stood at *allocation* time, when the slots read 143–148; the per-record `## Status` provenance notes carry the full lineage (`143 → 149 → 155`, `144 → 150 → 156`).

**Allocation rule — collision-safe under P0 serial.** `renumber-adr.py --next-free` anchors on `origin/main`, so it returns the **same** number for every spoke on this branch regardless of what earlier slices already committed — and that number is **not stable across the release**: it re-anchors whenever a sibling merges to `origin/main`, which is exactly what happened to 142 mid-Engineering. Do **not** re-derive the number per spoke and do **not** treat a fresh oracle reading as your allocation. Instead: each ADR-warranted spoke, in Implementation-Sequence order, claims the **lowest unclaimed slot in the table above**, writes its ADR file on the branch, and updates the row in the same commit. A spoke whose proposal deduplicates into an ADR already written on the branch **cites it and claims no slot**.

**Warranted set (Stage 5): six proposals — #5067, #4227, #4200, #5268, #5253, #4912 — resolving to five distinct decisions after dedup**, which is why five slots are reserved. The scope-lock record does **not** name which two proposals merge; that determination belongs to the second of the two merging spokes at its own commit. `[ASSUMPTION – CONFIRM]` If a sixth *distinct* decision emerges, the spoke extends the table by re-running the oracle against `origin/main` **and** scanning the branch's own `core/ADRs/` ∪ `release/ADRs/`, and records the extension in the Deviation Log. **Not warranted:** #4974 (adopts a shipped classifier rather than re-deciding it), #4416 (bounded parameter, one function, revertable).

## Risk Register

| ID | Class | Risk | Owner-side mitigation | Reversibility / Confidence |
|---|---|---|---|---|
| **R1** | Contention | Sibling draft PR **#6120** edits 14 shared paths, including `automated-closeout.sh` (3 members) and 5 pipeline stage specs. Both branches sit on the same base, so every hunk is a live collision | **Tier-S serialization point.** D3: proceed now, rebase after siblings land. Re-measure at Stage 9 Phase A6.6 — this Stage-4 reading is baseline-pinned and cannot see a post-audit push | MODERATE / HIGH |
| **R2** | Contention + scope | Sibling draft PR **#6119** touches `release/tools/check-selftest-coverage.py` — #5253's implementation surface — plus both selftest allowlists and the smoke workflow | **Softened at scope-lock**: measured **+62/−7** with `_SCOPE_DIRECTIVE_RE`, `parse_manifest`, `advertises`, `discover`, `Ctx` all untouched — a widening, not a rewrite. #5253 stays sequenced **last** to shorten the rebase window | MODERATE / MEDIUM |
| **R3** | Contention (binary) | `packages/release-hub.skill` is a zip. Git cannot three-way-merge it, and #6120 edits it too. A textual merge produces a corrupt package that still hashes | **Never merge the artifact — rebuild it.** After slice 4, run the package build and verify `deploy.sh --check` Check 7 green. On any rebase against a sibling, discard both sides and rebuild from source | CHEAP / HIGH |
| **R4** | Sequencing | **#4227 → #4200** rewrite the same Checkpoint B region and the same § Concurrency paragraph. Parallel build guarantees a conflict | Carried constraint; not re-opened. Slices 3 and 4, adjacent, one branch, P0 serial. Interface fixed at scope-lock (§§ 4.3 / 4.3a untouched by #4227; host-API in a new § 4.3b) | CHEAP / HIGH |
| **R5** | Contention (intra-file) | Three members edit one 12,428-line file. Regions are disjoint but commits still serialize at push | Order #5268 → #4416 → #4912; hunk-disjointness declared and verified zero-overlap. CIAC-3 grades that none regressed another | CHEAP / HIGH |
| **R6** | Scope | **#4912 AC1 is unachievable as literally written.** The idiom lives in 12 files; 2 are immutable historical artifacts and 5 are prose. A global `git grep → 0` can never pass | Scope AC1's denominator to executable call sites. `IDIOM-DOC-SWEEP` resolved **FIRES** at Stage 5 | CHEAP / HIGH |
| **R7** | Scope addition | **#5253's gap has already reopened**: 36 tools, 34 rows, 2 undocumented at `8dc00db1`. A check built to the card's spec goes red on arrival | Backfill `check-operator-toml-schema.sh` and `start-skill-editor-session.sh` rows **in the same change** as the check | CHEAP / HIGH |
| **R8** | Design fork | **#5268's "mode-blindness" framing was contradicted by a shipped in-code assertion** | **RESOLVED at Stage 5 → Disposition A**, on the evidence that the comment (`39284a2d`, 2026-08-04) is a git *ancestor* of the ratifying commit (`da363fdd`, 2026-08-09): there was never an exemption to reverse, only an unreconciled predecessor | CHEAP / HIGH |
| **R9** | Verification reach | **FALSIFIED and CLOSED at Stage 7 — this risk does not exist.** It formerly read *#5240's mutation arm will not be CI-enforced*, reasoning from the `--self-test` *discovery manifest* (`# scope: release/tools/*.sh`; `core/skills/` contributes 0 of 65 entries) to the conclusion that no CI job runs the arm. **That inference does not follow:** a job can name a script **explicitly** without being discovered by the manifest, and one does | **CI-enforced, measured.** `.github/workflows/release-tooling-smoke.yml` job `finops-selftest` — *FinOps usage-extractor script self-tests (Ubuntu)* — runs `bash core/skills/finops-usage-extractor/scripts/extract-usage.sh --self-test` by name, which is the AC's method verbatim, and the mutation arms (10a/10b/10b2) plus their control arm live inside that self-test. **Conclusion `success` on branch head `ebc700c4`** (48/48 checks green, read via REST). The job also carries a precision probe that breaks a real invariant and fails if the self-test degrades to zero assertions, so the green is not a fail-open. Locally re-run at `ebc700c4`: `--self-test: PASS`. The manifest-scope observation stays true and stays out of scope — it was never the thing that determined CI reach | **n/a — risk retired** (formerly CHEAP / HIGH) |
| **R10** | Rollback | Whole release is `git revert`-ible. **Two residuals a code revert does not undo:** the `auto-promoted-pattern` GitHub label (host-side state) and the two `packages/*.skill` artifacts | `git revert -m 1` the merge commit; delete the label host-side if the revert is total; rebuild packages from reverted source and re-verify Check 7 | CHEAP / HIGH |
| **R11** | Currency | #5268 cited `:2887-2893`; the symbol opens at `:3796` with its mode branch at `:3856` | Resolve by symbol (`phase_append_changelog`), never by line. Tier-1 `[ADJUST]` applied | CHEAP / HIGH |
| **R12** | Currency | #5253's Affected Files named `core/deploy/tools/check-selftest-coverage.py`; the tool is at `release/tools/check-selftest-coverage.py`. Its AC4 targeted a README row the tool cannot own | Tier-1 `[ADJUST]` applied to both. The corrected path is carried in the matrix above | CHEAP / HIGH |
| **R13** | Currency | #4912 AC4 cited *"partition counts move from 54/3"*. Live: manifest 65 entries, exclusions 16, macos pins 3 | Re-derive pre/post partition counts at build time and record the observed figures in the PR body rather than asserting the recorded pair | CHEAP / HIGH |
| **R14** | Version | PR #6119 provisionally stamps **v4.39** in its title and is further along the pipeline | Provisional until the Stage-12 atomic claim (ADR-092). The Commit-0 re-verify ran and returned PROCEED; the pre-merge freeness gate and the atomic CAS are the later rungs. **Re-versioning up at Stage 12 is routine, not an error** | MODERATE / HIGH |
| **R15** | Contention (unmapped) | **#4714** (OPEN, milestone `note-resolver-and-corpus-lint`) edits `release/tools/check-release-body-drift.sh`. The Stage-4 Contention Map measured only in-release members and open PRs; the hub's per-wave pre-spawn check queries open **PRs**, not open **issues** on shared paths | **Engineering must re-check #4714's state before touching that file** (slice 8). Routed at scope-lock; the structural gap in the pre-spawn check is routed to the hub as a separate finding | MODERATE / MEDIUM |

**Residual accepted at Stage 4:** the four remote `release/*` heads carrying no open PR were not editset-measured. Their intersection with this release is **UNRESOLVABLE, not zero** — recorded per audit-baseline discipline so a later re-measure has a prior to diff against.

## Cross-Issue Acceptance Criteria

Five predicates span ≥2 members each. All graded at Stage 9 QC3.5 / Phase A3.6 on the merged PR.

- [ ] **CIAC-1 (#4227 × #4200 on `quota-budget-protocol.md` § Checkpoint B):** the merged § 4 carries **both** the host-API second axis and the wave-width guidance, with neither overwriting the other, **and** the verdict enum remains the same closed set — width guidance rides *alongside* the verdict and mints no new verdict token. *Method:* assert `GraphQL` ≥ 1 **and** a width-guidance token ≥ 1 in the merged file, **and** that the set of rendered verdict tokens is exactly `{PROCEED, SERIALIZE, DEFER, REDUCE-scope}` for a wave and `{PROCEED, DEFER}` for a singleton. **Control:** at `8dc00db1` both terms return 0, so a post-merge non-zero is non-vacuous.

- [ ] **CIAC-2 (#4227 × #4200 on `spoke-launch.md` § Concurrency + `packages/release-hub.skill`):** § Concurrency **cites** the protocol's new width and host-API elements rather than restating them, **and** the rebuilt package's `release-hub/references/spoke-launch.md` member is byte-identical to the source file. *Method:* extract the package member and `diff` against source → identical; plus `./deploy.sh --check` Check 7 green. **Control:** re-run against a deliberately un-rebuilt package and assert it goes red.

- [ ] **CIAC-3 (#5268 × #4416 × #4912 on `release/tools/automated-closeout.sh`):** after all three land, the file's own self-test passes **and** a full `--dry-run` against an unclosed-release fixture reaches phase 16 exit 0 with the bounded poll and the portable strip both on the executed path — i.e. no member's fix regressed another's. *Method:* `bash release/tools/automated-closeout.sh --self-test` exit 0 **and** the #5268 dry-run arm exit 0, both at the final merged head. **Control:** each of the three arms is individually red at `8dc00db1`, so a green triple is not achievable by an unchanged file.

- [ ] **CIAC-4 (#4912 × #5253 on the self-test discovery surface):** #4912 removes two `# selftest-runner: macos` pins and #5253 extends the coverage engine; the **same** final head must satisfy both reconciliations. *Method:* `python3 release/tools/check-selftest-coverage.py --reconcile` exit 0 **and** the `core/deploy/tools/README.md` documented `comm`-based re-derivation prints empty. **Control:** at `8dc00db1` that re-derivation prints exactly 2 lines (`check-operator-toml-schema.sh`, `start-skill-editor-session.sh`), so an empty result post-merge is evidence rather than a broken pipe.

- [ ] **CIAC-5 (#5067 × #5253 on the declared-vs-enforced parity capability):** after this release, **no platform surface declares an artifact its own parity or coverage checker cannot see.**

  *Method (parity limb) — **MISSING-set membership**, not exit 0.* Run the checker the way Check 51 does, over the full source union:

  ```
  python3 core/deploy/tools/check-label-parity.py \
    --source core/specs/label-taxonomy.md \
    --source core/packs/_common/pack.toml \
    --source core/packs/kanban/pack.toml \
    --source core/packs/scrum/pack.toml \
    --output-format tsv
  ```

  **Assert `auto-promoted-pattern` appears as a `MISSING` row.** That is the correct pre-materialization state and it is the *stronger* assertion: the checker can only report a label MISSING if it first parsed it into the canonical set, so one row proves both that #5067's declaration landed **and** that materialization (D-CR3) has not yet run.

  **Exit 0 is structurally unreachable here and must not be asserted.** The tool is `return 1 if (missing or orphan)`, and at the merged head it reports 4 MISSING and 15 ORPHAN rows, nearly all unrelated to this release (`triage: duplicate` / `triage: quick-win` / `triage: stale`; `size:*`, `layer:*`, `adr`, GitHub defaults). Exit 0 would require closing every one of them — scope this release never took. Measured at `ebc700c4`: **exit 1**. Running the tool the literal way (`python3 core/deploy/tools/check-label-parity.py` with no `--source`) instead yields **exit 3** — the union parses to zero labels once the concrete rows moved into the packs (#1970), so the bare invocation grades nothing at all. *Corrected at Stage 7: two spokes independently measured exit 1 and exit 3 against the original `exit 0` assertion.*

  **Assert the exit-3 CAUSE on stderr, never the bare code — `3` is ambiguous and this criterion depends on which `3` it is.** The tool returns 3 from **three** distinct sites on the gate path, and the exit code alone cannot separate them: `parsed zero canonical labels from N source(s)` (the one this criterion means), `cannot read live label set: …` (the `gh label list` read failed — no auth, no repo context, rate limit), and `source unreadable: …` (a source path that did not resolve, which is what a wrong cwd produces). A grader running without `gh` auth gets **exit 3 for a reason that never occurred** and passes this limb on it. So the assertion is:

  ```
  exit 3 AND stderr contains "parsed zero canonical labels"
  ```

  **Control (the assertion must be able to fail).** Measured at `63f08c87`: the bare invocation returns 3 with `parsed zero canonical labels from 1 source(s) (core/specs/label-taxonomy.md)` → the clause holds. The same tool driven to the live-read failure returns 3 with `cannot read live label set: gh label list failed: …`, and to the unreadable-source failure returns 3 with `source unreadable: …` — the clause is **false** on both, so it discriminates rather than passing on any 3. A negative control alone would not have shown this: it proves the probe *can* return zero, not that it can return non-zero on the wrong cause.

  *Method (coverage limb) — unchanged and verified:* `python3 release/tools/check-selftest-coverage.py --reconcile` → **exit 0** (measured at `ebc700c4`; Arms B/C/E pass, Arm D emits a `::warning::` that does not affect exit).

  **Control (non-vacuity).** At `8dc00db1` `auto-promoted-pattern` is absent from **both** source files, so it cannot be reported MISSING — the membership assertion is `false` at base and `true` at head, and flips on exactly the declaration this criterion grades. Positive control on the same probe: `status:` returns 12 hits at base, so a zero is a true zero rather than a broken pattern. The coverage limb's own base control (the re-derivation printing 2) is unchanged.

  **Precondition:** CIAC-5's label limb is gated on the Stage-12 operator materialization step (D-CR3) — declaration alone does not create the live label. **After materialization the assertion inverts**: `auto-promoted-pattern` must then be *absent* from the MISSING set. Grade the pre-materialization form at Stage 9 on the merged PR; the post-materialization form belongs to Stage 12.

## Verification Plan

### Per-Issue Verification

| Issue | Verification Method | Expected Result |
|---|---|---|
| #5240 | `bash core/skills/finops-usage-extractor/scripts/extract-usage.sh --self-test` | exit 0; the pre-existing carry-forward arm and the new drop-set mutation arms all green |
| #5240 | Mutation arm — force the drop-set read to fail under `do_incremental()` | exit **3**, a `FATAL (exit 3)` line naming the drop-set read, and the store **byte-unchanged** |
| #5240 | Control arm — the same harness with no injected failure | exit 0, store rewritten; proves the harness is not what makes it fail |
| #5067 | `bash release/tools/synthesize-release-learnings.sh --self-test` under a pinned PATH | `gh` resolves lazily against three candidates; no hard-exit at load; ubuntu-discoverable |
| #5067 | `python3 core/deploy/tools/check-label-parity.py` **with the full `--source` union** (grammar doc + all `core/packs/*/pack.toml`) — the bare invocation exits **3** *with stderr `parsed zero canonical labels`* and grades nothing — assert that **cause**, not the bare code: two other gate-path sites also return 3 (`cannot read live label set`, `source unreadable`), so an unauthenticated grader passes on a 3 that never happened. See CIAC-5 | `auto-promoted-pattern` present as a **`MISSING` row** (proves it parsed into the canonical set, pre-materialization); process exit **1**, not 0 — see CIAC-5. `--emit-fix` renders the operator `gh label create` |
| #4227 | Replay a recorded `GraphQL 0/5000 + REST 4966/5000` state against the authored rule | DEFER-dominant disjunction fires; healthy pools preserve today's behavior bit-for-bit |
| #4200 | Replay the observed 3-wide wave's envelope | `W_max` rendered as a second output; verdict enum unchanged |
| #4200 | **AC3 — grade the RESTATEMENT below, not the card's literal text** | `spoke-launch.md` § Concurrency forecloses the substitution: `W_max` comes from Checkpoint B's remaining-envelope basis and **never** from the stage's parallelism class. **Control:** the bare orthogonality sentence alone cannot discriminate — it is present unchanged on `origin/main` |
| #4974 | Replay a CONFLICTING PR's required-context read at Stage 7 / 8 entry | P1 fires **Blocker** on the conflict; with P1 suppressed, `0 of 9` required rows fires the **P2 denominator floor** — Blocker at Stage 7, entry-validation failure at Stage 8 — *before* § 5.1 is consulted. `PASS` is unreachable on both paths |
| #4974 | Replay a still-dispatching roster whose count rises between consecutive polls | Renders **Warning — unsettled**, never a shortfall. The settle poll keys on `status == COMPLETED`, so an empty conclusion cannot short-circuit it into the false collapsed-denominator alarm |
| #5268 | `automated-closeout.sh --dry-run` on a first-close fixture | Reaches phase 16 exit 0; no pre-mode-branch abort at 9.5 or 15.55 |
| #5268 | **AC3 — grade the RESTATEMENT below, not the card's literal text** | The CLASS arm (group CA) asserts the two properties that are TOTAL over the phase population — CA-1 bijection with the guarded top-level dispatch, CA-2 mutating ⇒ mode-disposed with the exempt set DERIVED — each behind its own anti-vacuity floor, plus CA-2m sensitivity and CA-2c specificity. The ORDERING half is deliberately NOT decided at class level and stays with the per-phase paired arms. **Control:** a synthetic mutating phase with no mode branch IS reported and its removal returns the arm to silence |
| #4416 | Never-converging self-test leg at `VERIFY_RECHECK_DELAY=0` | Terminates on the **attempt** bound; renders `PARTIAL … unsettled`, never `PASS`; suite does not hang |
| #4912 | Conformance fixture across all implementations | Byte-identical output on 198/198 live notes and all edge cases; a deliberately-wrong implementation differs (firing control) |
| #4912 | Empty-body guard | `gh release edit --notes ""` is unreachable on the strip path |
| #5253 | `python3 release/tools/check-selftest-coverage.py --reconcile` | Arm E green on arrival with both README rows backfilled; sensitivity arm (inject a fabricated tool) flags; specificity arm does not |

#### AC restatement — #4200 AC3 (Stage 8 grades this wording)

**The card's literal AC3 is satisfied by an unchanged file, so grading it as written measures nothing.** #4200 AC3 reads: *"Assert the protocol states explicitly that parallel-safety is a file-contention property orthogonal to the usage-window envelope, so the coordination property cannot be read as license for width."* The leading clause is already true on `origin/main` — `quota-budget-protocol.md` has carried the **Parallelism Rules orthogonality** bullet since before this release opened, and the card's own Description concedes it (*"The spec is explicit that it is orthogonal"*). A grader working from the literal text returns **MET** without inspecting any delivered work, and would have returned MET before a line was written.

**What Engineering actually built is the second clause, and it is strictly stronger.** The card's real complaint is not that the orthogonality goes unstated; it is that stating it *changes nothing*, because nothing stops a reader deriving width from the parallelism class anyway. The delivered decision (ADR-151) forecloses that derivation at the point width is decided.

**Grade AC3 as: the protocol and § Concurrency FORECLOSE the substitution — `W_max` is sourced from Checkpoint B's remaining-envelope basis and never from the stage's parallelism class — and the orthogonality statement is present as the premise of that foreclosure rather than as a standalone assertion.**

*Method:* assert `spoke-launch.md` § Concurrency carries the not-a-licence-for-width clause naming `W_max`'s Checkpoint B source, **and** that the orthogonality bullet is cited by it rather than left free-standing. **Control (required, and it is what makes this non-vacuous):** run the same assertion against `origin/main`. The orthogonality sentence is present there and the foreclosure clause is absent, so a probe that fires on both is measuring the wrong thing. **`[SOURCE]`** measured 2026-08-28 against `origin/main`, both arms: `quota-budget-protocol.md` returns **1** `orthogonal` match on the mainline (so the literal AC3 discriminates nothing), while `spoke-launch.md` returns **0** foreclosure clauses on the mainline against **1** on this branch (so the restated AC3 discriminates exactly the delivered work).

This restatement lives here and **not** in the issue body: per ADR-062 a shipped card's acceptance criteria are not retro-edited, so the plan carries the sharpened wording and Stage 8 reads the plan. Routed four times before this pass without action; recorded so it is gradeable rather than re-routed.

#### AC restatement — #5268 AC3 (Stage 8 grades this wording)

**The card's literal AC3 is broader than the arm that was deliberately built, so grading it as written measures a property the delivered work does not claim.** #5268 AC3 reads: *"A regression arm fails if any future phase reintroduces the pattern (method: assert the arm goes red on a deliberately mode-blind fixture — a check that has never been observed failing is not trusted)."* Read literally, *"the pattern"* is the card's own name — a projector or presence check resolved **above** the mode branch — and the delivered class arm does not decide that. Stage 8 measured the gap directly: an independently authored synthetic phase that **mutates, has a mode branch, and resolves a presence check above it** returns `rc=0 PASS` and **survives** (Variant C). The superseded verification row — *"Fails on a reintroduced pre-branch resolution"* — is falsified by that measurement.

**The narrower arm is the correct engineering, and the bound is disclosed rather than papered over.** Four candidate orderings were measured against the shipped population before the arm was written and **every one was falsified by conformant phases** — *"no abort above the short-circuit"* false-fires on 9, *"short-circuit is the first MODE reference"* on 7, *"no ledger read above the short-circuit"* on 3, *"a SKIP guard must sit above the short-circuit"* on 9. A detector that guessed the ordering would be a false-alarm generator, which is strictly worse than one that does not try. So the arm asserts the two properties that **are** total over the population and leaves the ordering half to the per-phase paired arms that can see the fixture.

**Grade AC3 as: the CLASS arm asserts the two total properties, each behind an anti-vacuity floor and both directions of control, and states its own undecided half.**

- **CA-1 — the population is BIJECTIVE with the guarded top-level dispatch.** The placement rule only bites because `phase_x || { generate_report; exit 3; }` makes one non-zero phase fatal, so a phase defined but not dispatched under that guard — or dispatched twice — voids the premise every other arm in the file rests on. Anti-vacuity on each side, plus a floor of 30 on the enumeration itself.
- **CA-2 — a phase that MUTATES must be mode-disposed.** The exempt set is **DERIVED** (bodies carrying no write signature), never enumerated, so a 37th mutating phase with no mode branch fires on the day it lands. Two-sided anti-vacuity (floors of 15 mutating and 4 read-only) so the write signature can neither match nothing nor match everything. `declare -f` emits the PARSED body with comments stripped, so a prose mention of MODE cannot satisfy CA-2 and a commented-out write cannot defeat it.
- **The ordering half is NOT decided here, by design.** It stays with the per-phase paired arms. This is the bound Variant C confirms, and it is stated in the shipped block comment and the attestation clause rather than left for a grader to discover.

*Method:* assert group CA carries CA-1 and CA-2 with their anti-vacuity floors, **and** that the block comment states the undecided ordering half. **Controls (required, and they are what make this non-vacuous):** `CA-2m` — a synthetic mutating phase with no mode branch **is** reported, and its removal returns the arm to silence, so a green CA-2 is distinguishable from one that can never fire; `CA-2c` — a synthetic **read-only** phase with no mode branch is **not** flagged, which is what keeps the derived exemption from collapsing into the presence check the placement header warns passes on the defective code. **`[SOURCE]`** measured at Stage 8 on an independently authored synthetic 37th phase: (A) mutates, no mode branch → `rc=1`, **exactly one** failure, `CA-2` naming the phase; (B) read-only, no mode branch → `rc=0 PASS`; (C) mutates, has a mode branch, presence check resolved above it → `rc=0 PASS, SURVIVES` — the disclosed bound, reproduced.

**The ordering sub-shape's remainder is operator-ratified deferred** (DT-M-J, scoped to the class arm alone) and is therefore not an AC blocker. What was **not** ratified was the plan asserting a property the arm does not have; that is what this restatement corrects.

This restatement lives here and **not** in the issue body: per ADR-062 a shipped card's acceptance criteria are not retro-edited, so the plan carries the sharpened wording and Stage 8 reads the plan. Raised as Stage 7's F-11, re-measured independently at Stage 8, and landed here as the Stage-9 clearing condition.

### Release-Level Verification

Per `verification-checklist.md`:

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity
- [ ] Skill Invocation
- [ ] Output Contract Compliance
- [ ] `./core/deploy/deploy.sh --check` green (Check 7 package freshness in particular, after the slice-4 rebuild)

## Quota Budget

**Verdict:** WARN (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage:** Stage 5: 8 · Stage 7: 9 · Stage 8: 9
**Per-spoke cost estimate:** size-bucket ordinal band per § 5 (no telemetry medians available; no bucket satisfies the § 5.1 five-condition cutover). Worst batch — 4 × `size:M` + 5 × `size:S` at Stage 7/8. Source: heuristic.
**Assumed/stated remaining usage-window envelope:** **UNSTATED** — no operator quota state was captured. Per § 6.1 the conservative default of § 3.1 applies and **no figure is synthesized**.
**Estimated cumulative draw % (worst parallel batch):** **not rendered.** `[ASSUMPTION – CONFIRM]` — a percentage here would be a projection of a band nobody stated, presented as a measurement.
**Routing:** WARN → window-aware launch timing + quota-budgeting (split batch) recommended.

The binding quantity is *cumulative* consumption inside the sliding five-hour window, and a 9-wide batch draws all nine spokes' full lifetime cost against one envelope regardless of spacing. **STAGGER is not a mitigation here** and is not proposed. `[RECOMMENDED]` split each of Stage 7 and Stage 8 into three waves of three, converting one large cumulative draw into three gated ones and letting Checkpoint B re-read the remaining envelope between them.

**This plan-time estimate is advisory; the load-bearing gate is Checkpoint B at every launch, and this section never substitutes for it.**

## Release Class Declaration

**Milestone declared `routine`. Re-classified to `cross-cutting`** at the Stage-4 plan gate (D2, 2026-08-27, operator).

**`cross-cutting` trigger (a) fires with margin — the dominant trigger.** The Stage-4 File Change Matrix declares **5** `pipeline/stage-*.md` files (`stage-04`, `-07`, `-08`, `-09`, `-13`) against a ≥3 threshold. Stage 5 subsequently removed `stage-09-plan-review.md` from #4974's editset, so the **live count is 4**. **The classification is unaffected — trigger (a) clears at 5 and at 4.** (See Deviation Log row 2 for the hub's superseded count of 6.)

**`cross-cutting` trigger (c) supports.** ≥3 in-bundle compositional edges: the #4227→#4200 hard edge, the three-claimant `automated-closeout.sh` cluster, and the #4912↔#5253 selftest-surface coupling. **Trigger (b) does not fire** — 1 of 7 named governance surfaces.

**Why `routine` fails on its own triggers:** trigger (a) is **FALSIFIED** — #4912 is P1-Critical, #4974 P1-Significant, #5067 P2-Material (sizes do hold: 5 × S, 4 × M, but the priority limb does not). Trigger (b) is **NOT CLEAN** — `release/tools/check-selftest-coverage.py` has 2 prior release touches against a ≥3 bar. Trigger (c) is **AMBIGUOUS** and not leaned on. Trigger (d) is **CONTESTED** — two genuine design forks (R6, R8).

**Multi-trigger resolution:** `cross-cutting` > `novel` > `routine`. **Cost of the re-classification: CHEAP / HIGH** — cheaper-to-stricter; it adds ceremony, invalidates no downstream artifact, and can revert at the next gate.

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Complexity |
|---|---|---|
| #5240 | `git revert <commit>` | **CHEAP** — one function plus its self-test arm |
| #5067 | `git revert <commit>` | **MODERATE** — reverting the code does not delete a GitHub label already created by the Stage-12 operator step (R10) |
| #4227 / #4200 | `git revert <commit>` + rebuild `packages/release-hub.skill` | **CHEAP** — protocol prose; the package must be rebuilt, never restored by revert alone |
| #4974 | `git revert <commit>` | **CHEAP** — spec prose, no executable path |
| #5268 / #4416 / #4912 | `git revert <commit>` in reverse order | **CHEAP** per member; **MODERATE** as a set — the three regions are disjoint but the file is single |
| #5253 | `git revert <commit>` | **CHEAP** — additive check arm plus two README rows |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|---|---|---|
| **Partial Revert** | Isolated issue failure | Revert specific commits per `rollback-protocol.md` |
| **Full Restore** | Systemic failure | `git revert -m 1` the merge commit per `rollback-protocol.md`. **Does not delete the `auto-promoted-pattern` label** (host-side state) and **does not rebuild the two `packages/*.skill` artifacts** — both are R10 residuals with named follow-on steps |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch per `rollback-protocol.md` |

**Whole-release reversibility: MODERATE / Confidence HIGH.** No schema change, no data migration, no destructive operation. The merge is taken as a true two-parent merge commit so the `git revert -m 1` form applies.

## Operational Deployment Manifest

| # | Step | Owner | Mechanism | Verification |
|---|---|---|---|---|
| 1 | Rebuild `packages/release-hub.skill` + `.sha256` after slice 4 | Engineering (#4200 spoke) | package build from source | `./deploy.sh --check` Check 7 green; CIAC-2 member diff identical |
| 2 | Rebuild `packages/release-executor.skill` + `.sha256` if `IDIOM-DOC-SWEEP` edits `release-executor/SKILL.md` | Engineering (#4912 spoke) | package build from source | `./deploy.sh --check` Check 7 green |
| 3 | **Create the `auto-promoted-pattern` GitHub label** | **Operator, Stage 12** | `gh label create` — command rendered read-only by `check-label-parity.py --emit-fix` | Label present in the live label set; **`auto-promoted-pattern` has left the `MISSING` set** (see § Verification after execution). **NOT exit 0** — the tool is `return 1 if (missing or orphan)` and unrelated MISSING/ORPHAN rows keep it non-zero; measured exit 1 at `ebc700c4`. *Corrected at Stage 7.* |

**Step 3 is D-CR3 and is not discharge-able inside the PR.** `label-taxonomy.md` states it in one sentence: *reconciliation DETECTS; it does not MATERIALIZE.* Declaration and materialization are two obligations. #5067's AC3 is satisfied by the operator step, not by the merge — and CIAC-5's label limb is gated on it.

**Step 3 — exact invocation.** Rendered read-only by `--emit-fix` at Engineering and reproduced verbatim; run it from the repo root so `gh` resolves the repo from the remote (no `--repo` literal, per the path-portability rule):

```bash
# Re-render first, then run ONLY the auto-promoted-pattern CREATE line:
python3 core/deploy/tools/check-label-parity.py \
  --source core/specs/label-taxonomy.md \
  --source core/packs/_common/pack.toml \
  --emit-fix

gh label create 'auto-promoted-pattern' --color 'D4C5F9' --description 'Filed automatically by the release-learnings synthesizer'\''s cross-release pattern detector; awaiting triage. Persists through close (the schema-maintenance trigger counts it).'
```

**Effect:** creates one GitHub label. **Reversibility: MODERATE** — a label is repository *state*; `git revert` does not remove it, and deletion is a separate `gh label delete 'auto-promoted-pattern' --yes`. **Rollback ordering:** revert the merge **first**, then delete the label, so the parity checker does not immediately re-flag the deletion as fresh drift.

**Verification after execution:** re-read the live set (`gh label list --limit 500 --json name`) and assert the name is present against a non-zero control arm (`improvement` must also return present); then re-run `check-label-parity.py` and assert the row has left MISSING.

**Expected-until-executed, not a defect.** Between merge and Step 3, Check 51 reports `auto-promoted-pattern` as MISSING. That report is the gate working correctly — a check that cannot create a label cannot clear a MISSING it reports. It moves the MISSING set from 3 entries to 4; it **cannot** turn `deploy.sh --check` red, because `label-parity` resolves to `warn` (no `.mode` file is tracked) and the warn arm does not increment `ISSUES`. Three pre-existing entries (`triage: stale`, `triage: duplicate`, `triage: quick-win`) are already in that set at HEAD and are **not** this release's scope.

### Schema Migrations

None. No schema change, no data migration, no destructive operation in this release.

## Hub-Rendered D-Decisions

| ID | Decision | Verdict | Reversibility · Confidence | Where recorded |
|---|---|---|---|---|
| **D1** | Stage 4 release plan + Release Outcome Statement | **Approved as-is** | MODERATE · HIGH | Stage 4 gate, #6123 |
| **D2** | D-ReleaseClass | **`routine` → `cross-cutting`** | CHEAP · HIGH | Stage 4 gate, #6123 |
| **D3** | Sibling-PR serialization posture | **Proceed now, rebase after siblings land** | MODERATE · MEDIUM | Stage 4 gate, #6123 |
| **D4** | Tier-1 `[ADJUST]` issue-body corrections | **All 11 authorized** (6 cards: #4227 ×1 · #4912 ×3 · #4974 ×1 · #5240 ×1 · #5253 ×3 · #5268 ×2) | CHEAP · HIGH | Stage 4 gate, #6123 |
| **D-CR1** | Scope additions | **All 4 admitted** | MODERATE · HIGH | Collective Review, #6123 |
| **D-CR2** | ADR numbering | **Follow the oracle — allocate from 142** | CHEAP · MEDIUM | Collective Review, #6123 |
| **D-CR3** | #5067 label materialization | **Stage-12 operator step in the deployment manifest** | CHEAP · HIGH | Collective Review, #6123 |
| **D-CR4** | Scope lock | **Locked** — 9 members, no merges, no splits, no deferrals | MODERATE · HIGH | Collective Review, #6123 |
| **D-Concurrency Posture** | **P0 fully-serial**, single branch, single PR | recorded determination | CHEAP · HIGH | Stage 4, #6123 |
| **D-Version** | Bump class `minor`; identity **slug-primary**, number binds at the Stage-12 atomic claim | recorded determination (not a gate) | CHEAP · HIGH | Engineering Commit 0, #6146 |

**D4 scope — explicitly NOT covered:** closing or reopening any member, changing any `size:` label, or resolving #5268's C2 design fork (that fork routed to Stage 5 and was resolved there).

## Deviation Log

| # | Stage-4 plan of record | Ratified delta | Source |
|---|---|---|---|
| 1 | Milestone declares Release Class `routine` | **`cross-cutting`** — trigger (a) fires with margin; downstream posture moves to Tight / Deep / ALL / 30-day | **D2**, Stage 4 gate, 2026-08-27 |
| 2 | Stage-file count for trigger (a) = **5** (spoke); the hub's Decision-Recorded comment claimed **6** and called the spoke's count low | **The hub's 6 was a counting error and the direction was inverted.** The 6 came from a regex over the whole plan document, sweeping in `stage-12-execute.md`, which appears only as prose that #4912's AC1 scopes *out*. The spoke's 5 was correct. Classification unaffected — trigger (a) requires ≥3 | Correction comment on #6123 |
| 3 | #4974's editset = 3 files (`stage-07`, `-08`, `-09`) | **2 files.** `stage-09-plan-review.md` **drops out** — Stage 9 already discharges both AC limbs (`G-PR5` reads `gh pr view --json mergeable`, and all 9 required contexts are `pull_request`-dispatched so a CONFLICTING PR returns 0 of 9, already classified `checks-unreadable` → PARTIAL). Live stage-file count → **4**. This also retires one of the two HIGH-severity #6120 collisions | #6136 (#4974 Stage-5 design) |
| 4 | Four scope items unrecognized at Stage 4 | **All 4 admitted (D-CR1):** #5268 + `phase_assert_anchor_hygiene` (15.55) — without it the halt relocates and AC1 still fails; #4200 + `hub-spoke-bridge.md` — 2 of 3 `PROCEED → launch all N` rules live there, unedited the feature ships **inert**; #4227 + `release-hub/SKILL.md` — the measured gate falsifies its "zero tool calls" assertion; #4912 + the empty-body guard at `:5919` — it blocks the release's only IRREVERSIBLE path (`gh release edit --notes ""` blanks a published Release body, and GitHub keeps no body history) | **D-CR1**, Collective Review |
| 5 | `LABEL-GRAMMAR-ROW` **does not fire** — the concrete row homes in `pack.toml`, so no grammar edit is owed | **FIRES**, on a basis Stage 4 did not model: the label has no home in the 7-group grammar at all (`category` breaks Rule 1, `triage-flag` breaks §11.6, `disposition` mis-describes a machine-applied marker). A new **`provenance` group** is added to `core/specs/label-taxonomy.md`. Verified zero-risk to automation — `check-label-parity.py:93` collects only `name|color|description`; `group` is documentation-only | #6137 (#5067 Stage-5 design) |
| 6 | Stage 4 read `pack.toml` declaration as satisfying #5067's AC3 | **False — and the corpus says so in one sentence.** `label-taxonomy.md:183`: *"Reconciliation DETECTS; it does not MATERIALIZE."* AC3 is **not satisfiable inside the PR**; it needs a Stage-12 operator `gh label create`. Stage 4 saw the property (R10 names the label as host-side state a revert cannot undo) but the `[ADJUST]` wording did not carry it forward | #6137 → **D-CR3** |
| 7 | `IDIOM-DOC-SWEEP` undecided; `PARTITION-STORED` undecided; `NEW-EXECUTABLE` carried speculatively | **`IDIOM-DOC-SWEEP` FIRES** (5 files promoted to unconditional + `packages/release-executor.skill` + `.sha256`). **`PARTITION-STORED` DOES NOT FIRE** — the partition is derived from the in-file pin, so no manifest / exclusions / workflow edit participates. **`NEW-EXECUTABLE` DOES NOT FIRE** — the new lib is sourced, never executed. One *new* conditional appears: `SELFTEST-FETCH-DEPTH`, gated on #4912's D6 falsification run | #6135 (#4912 Stage-5 design) |
| 8 | #4912's defect = one idiom at four call sites | **One intent with three divergent implementations across six sites**, already producing different bytes for 3 of 198 live notes. The fix is a **canonicalization**, not a substitution: extract to `release/tools/lib/frontmatter-strip.sh` (awk state machine), align both Python mirrors, bind all three to one committed conformance fixture. `awk` won Fork 1 on measured evidence (byte-identical on 198/198 with a firing control arm) | #6135 |
| 9 | #4912's severe site = `check-release-body-drift.sh` | **`automated-closeout.sh` is the severe site.** The drift check fail-*opens*; `reemit-release-bodies.sh` fail-*safes*; `automated-closeout.sh` has **no guard at all** — an empty strip there runs `gh release edit --notes ""` and irreversibly blanks a published Release body. Latent today only because the tool is macOS-pinned. This is the basis for the D-CR1 empty-body-guard addition | #6135 |
| 10 | #5268's C2 fork open — (a) keep pre-branch resolution vs (b) move after the branch | **Disposition A, on grounds neither the card nor Stage 4 identified.** The in-code comment (`39284a2d`, 2026-08-04) is a git **ancestor** of the ratifying commit (`da363fdd`, #4765, 2026-08-09): the siblings never diverged from a deliberate decision — the comment predates the rule. There was no exemption to reverse, only an unreconciled predecessor. The fix takes **15.5's shape** (mode test above the mode-*dependent* aborts, below the mode-invariant guards), not 9.55's literal-first-line shape | #6140 (#5268 Stage-5 design) |
| 11 | #5268's AC1 satisfiable by fixing phase 9.5 | **Unachievable by 9.5 alone.** The sweep found a second, unnamed class member — `phase_assert_anchor_hygiene` (15.55) has no mode branch at all. After 9.5 is fixed the dry-run halts there instead, one phase-group short of Phase 16 | #6140 → **D-CR1** |
| 12 | #4974's assertion target = one of two candidates the card offered | **Neither.** The target is the **live branch-protection required-context count**, already canonicalized on 2026-08-07 (`05c965a3`) in `release-readiness-scan-spec.md` § 5.1 — seven days before the card was filed. The design is **extend, not invent**. Candidate (a) is empirically falsified (7 of 22 workflows carry path filters, so full-rollup cardinality legitimately varies); candidate (b) would ground the assertion in a **shadow SSOT** (in-repo annotations declare 14 required contexts; branch protection registers 9) | #6136 |
| 13 | #4416's fix = a bounded poll sized against observed lag | **Attempt-bounded, not deadline-bounded** (`VERIFY_RECHECK_ATTEMPTS=15` × the unchanged 2s interval = a 30s budget). The file's own deadline idiom accumulates elapsed seconds from its own `sleep`, so at interval 0 elapsed never advances — an infinite loop, and check 5's self-test has a **mandatory never-converging leg** that runs at interval 0. Copying the deadline idiom verbatim hangs the suite. Root cause of the lag also re-framed: it is `search`-index lag, not primary-store lag | #6134 (#4416 Stage-5 design) |
| 14 | #4200's declared surface = the protocol + `spoke-launch.md` + the package | **`hub-spoke-bridge.md` is load-bearing and was undeclared.** Three consuming rules bind PROCEED to *"launch all N"* and **two of the three live in the bridge**. Un-edited, `W_max` is **inert**. Second finding: **AC3 is vacuously satisfiable today** — the orthogonality statement it asks for already exists verbatim at `quota-budget-protocol.md:199`, so a Stage-8 grader running AC3's literal method returns MET against the *unchanged* file. AC3 needs a placement + anti-substitution delta | #6124 (#4200 Stage-5 design) → **D-CR1** |
| 15 | #4227's two axes are symmetric | **They carry different evidence grades, and the asymmetry is the design.** `gh api rate_limit` returns `resources.core` / `resources.graphql` without drawing against them, so the host-API reading is `[SOURCE]` while the usage-window reading stays `[ASSUMPTION – CONFIRM]` under § 6.1. Consequences: the combination rule is a **DEFER-dominant disjunction** (mints no verdict token, preserves today's behavior bit-for-bit on healthy pools); § 6.1's refuse-to-synthesize rule and the § 4 preamble's *"cannot measure remaining quota"* must be **scoped to the usage-window axis** or they become false blanket claims | #6133 (#4227 Stage-5 design) → **D-CR1** |
| 16 | #5253's design premise threatened by PR #6119 rewriting the engine (R2, CRITICAL) | **Overstated.** #6119 measures **+62/−7** on the tool — it widens `TEST_SUITE_GLOBS`, extracts a `test_suites()` helper, adds three tests; `_SCOPE_DIRECTIVE_RE`, `parse_manifest`, `advertises`, `discover`, `Ctx` and Arms A/B/C are **untouched**. Every load-bearing assumption holds identically at `main@8dc00db1` and at `#6119@90ff9fe0` (36/34/2 at each head). R2 softened to HIGH/MEDIUM | #6139 (#5253 Stage-5 design) |
| 17 | #5253's inherited-filter hazard = the `--self-test` manifest | **A fourth mouth exists and is the most tempting:** `ctx.scope_members` today equals the directory population exactly (36) and is manifest-`# scope:`-derived, so narrowing a directive would silently shrink Arm E's population for the two **non-advertising** tools Arm B(i) structurally cannot protect. Arm E's population is therefore declared as **two literal globs on the tool itself, filtered by nothing** | #6139 |
| 18 | Contention map is complete over in-release members + open PRs | **#4714** (OPEN issue, milestone `note-resolver-and-corpus-lint`) edits `release/tools/check-release-body-drift.sh` and appears in **neither** the Stage-4 Contention Map nor the hub's per-wave pre-spawn check — that check queries open **PRs**, not open **issues** on shared paths. Recorded as **R15**; Engineering must re-check before touching that file | Collective Review, carried into Engineering |
| 19 | ADR numbering unresolved (ADR-142 double-claimed by two unmerged siblings) | **Follow the oracle — allocate from 142.** Unmerged claims are advisory: a numbering **gap** blocks the repo, a **duplicate** is tooled. All five ADR-proposing spokes recommended 148+; the operator followed the oracle instead. Re-verified at Commit 0: `ANCHOR 141 (origin/main)` · `NEXT-FREE 142` | **D-CR2**, Collective Review |
| 20 | D-Version recorded as **v4.39** at Stage 4 | **Re-verified at Engineering Commit 0 → PROCEED, and deliberately NOT baked into this file.** Three claimed-set arms each with sensitivity + specificity controls return `v4.39` × 0; `claim-version.sh --dry-run` independently recomputes `v4.39`. The plan is slug-primary per ADR-092 and carries `{{RELEASE_VERSION}}`, so a concurrent sibling claiming the slot costs a re-version at Stage 12 and **no edit to this file** | Engineering Commit 0, #6146 |
| 21 | ADR slots reserved as **142–146**; ADR-142 allocatable because the two sibling claims on it were unmerged and therefore advisory | **ADR-142 withdrawn; #5067 takes ADR-155; table extended to 147.** Sibling PR #6119 **merged to `origin/main` during Engineering** (`15e6bf01`), landing `release/ADRs/ADR-142-…`. Its claim stopped being advisory at that moment, and the oracle re-anchored: `ANCHOR 142 (origin/main)` · `NEXT-FREE 143`. Taking 142 would now duplicate **merged mainline**, not an unmerged claim — a materially different thing from the case D-CR2 ratified. Following the oracle (D-CR2's operative instruction) therefore yields **143**. Verified free in BOTH ADR dirs on the branch and on `origin/main` before claiming; `--detect` confirms `CLAIM ADR-155 … BINDS`. Table extended by one slot to preserve five allocatable slots, per the extension rule in § ADR Allocation | Engineering slice 2, #6145 |
| 22 | § Implementation Sequence states, as the `#4227 → #4200` mandated-coordination interface, that **§§ 4.3 / 4.3a are untouched by #4227** | **True of both verdict tables and of § 4.3a's SERIALIZE-meaningless sentence — proved byte-identical with a firing control — but NOT of § 4.3a's trailing "Cost, and why per-launch firing is affordable" paragraph, which #4227 rewrote.** That paragraph is not a verdict surface; it is the cost claim (*"the check is zero tool calls … it is not an instrument"*), and the Stage-5 Cascade-Sweep marked it **UPDATE** on the same evidence that admitted `release-hub/SKILL.md` into scope: making the gate measured falsifies it. Leaving it standing would have shipped the same self-contradiction the scope addition existed to prevent. #4200's own assumption **A4** anchors on the SERIALIZE-meaningless sentence, which is untouched, so the assumption holds as written; #4200's **A2** (a § 4.2 step that renders the verdict) is the one that moved — the verdict-render step is now the combination step's named usage-window branch. Both restated for hub reconciliation before slice 4 | Engineering slice 3, #6141 |
| 23 | § Implementation Sequence + #4200's Stage-5 design both name **§ 4.3b** as the new sibling section — #4227's host-API axis AND #4200's width guidance were each specified into the same identifier | **#4200's width guidance lands in a NEW § 4.3c**, immediately after #4227's § 4.3b and before § 4.4. #4227 shipped first and took § 4.3b, exactly as the plan's interface clause says it would; the collision is between the two Stage-5 designs, not with the plan. All of #4200's own cross-references (§ 4.2's usage-window branch sentence, § 4.3's PROCEED row, § 4.3a's inert-at-N=1 sentence, § 7, § 8, both bridge consuming rules, `spoke-launch.md`) cite **§ 4.3c**. Ordinal position is preserved, no identifier is reused, and #4227's § 4.3b is byte-untouched | Engineering slice 4, #6125 |
| 24 | #4974 editset = 2 files; `release-readiness-scan-spec.md` listed under § File Change Matrix **Read-only inputs** | **3 files.** The Stage-5 design's OPTIONAL third file (R3) is **taken IN** at the hub's recommendation: two `consumers:` frontmatter lines naming Stages 7 and 8, so a future edit to § 5.1 can see the two call sites it acquired. Genuinely two lines — the design's companion one-sentence § 5.1 note was **dropped** to hold R3 at its stated size. The file moves from Read-only inputs to the ratified-delta edit set. Verified clear of sibling PR #6120 (its 61-file editset does not contain this path, re-measured 2026-08-27). No `version:` field touched | Engineering slice 5, #6144 |
| 25 | #4416's Stage-5 design fixes the shipped test expectations: leg (f) settles at **"settled after 6 poll"**, and leg (i) asserts the stub's `calls` counter reads **exactly 2** | **Both expectations were wrong, and the second was measuring the wrong population.** The poll count is DERIVED, not fitted: `phase_detect_open_issues` makes read #1, `phase_manual_close_release_issues` makes no `issue list` read at all, so check 5's first read is #2, poll *k* reads #(2+*k*), and at an injected lag L the first drained read is poll *k*=L — **`_v5_polls` settles at exactly L, so leg (f) asserts 5, not 6.** Leg (i)'s counter is **phase-scoped, not check-5-scoped**: the gate-passage-proof rung calls `resolve_stage13_subtask`, which issues a THIRD `issue list` after check 5 has already rendered, so an arm pinned to it measures the phase rather than the settle scope it claims to. Replaced by an assertion on the check-5-scoped instrument (`check-5 settled at poll 0/15`, whose moving control is leg (f)'s `poll 5/15`) plus an honest CEILING arm on the counter. Third, smaller: the design's `local _v5_try` is dropped — it is never referenced, and shipping an unused local into a hardened tool is worse than a recorded no-op. **The ratified delta in row 13 is untouched** — attempt-bounded, `VERIFY_RECHECK_ATTEMPTS=15`, 30s budget, all as designed; only the design's own arithmetic for what the tests should expect is corrected. **This row is not the settled state of leg (i): see row 48** — Stage 7 F-01 subsequently found the exhaustion-suffix render guard wrong and added leg (i.2), and leg (i)'s counter assertion here was re-pointed to the check-5-scoped `poll 0/15` instrument plus a `<= 3` ceiling | Engineering slice 7, #6142 |

| 26 | #4912's AC4 is executed at Engineering: run the D6 falsification, then remove the two `# selftest-runner: macos` pins | **D6 was NOT EXECUTED, and the pins therefore STAY ON — AC4 reads NOT MET with a stated cause** (Stage-5 branch (c) shape). D6 requires running `check-release-body-drift.sh --self-test` and `reemit-release-bodies.sh --self-test` under a depth-1 checkout; both are absent from `.claude/script-execution-allowlist.txt`, so the security hook `BLOCK-DESTRUCTIVE-022` refuses to execute either from this environment. Surfaced rather than routed around — no bypass was set and no second tool was used to re-attempt the refused command. What **was** established: the depth-1 sandbox was built and confirmed to have no `origin/main`; a static sweep of both `self_test()` bodies (with two-directional controls) found **0** invocations that read the ambient checkout — every canonical-mode case exports `REPO_ROOT` into a bare-origin sandbox it builds in `$tmp`, and the drift tool's canonical block is guarded by `[[ -x /usr/bin/git ]]`, an executable-present test, not an ambient-repo test. That evidence **falsifies the degradation hypothesis** and favours branch (a), but a static sweep is not the falsification the gate names, and moving two suites onto a partition they have never run on, on unexecuted evidence, is the trade the release exists to prevent. **Reconciled regardless, per the Stage-5 cascade sweep:** both tool headers now record that the pins' ORIGINAL basis (the non-portable strip) is discharged and state the narrower basis that remains plus what would lift it; the smoke workflow's stale `57 = 54 + 3` partition narrative is corrected to the build-time re-derivation `66 = 63 + 3`; its "Today exactly one tool declares it" is corrected to three, with the two reasons distinguished; and its contested `fetch-depth: 0` degradation claim is marked contested with the measured counter-evidence rather than silently flipped. `SELFTEST-FETCH-DEPTH` therefore **does not fire** — branch (b) was never reached, so the workflow-edit-vs-doctrine trade named for operator decision does not arise | Engineering slice 8, #6143 |
| 27 | #4912 touches **no line** of `automated-closeout.sh`'s `self_test()` (Stage-5 declared regions A + B only) | **Exceeded, deliberately, by this slice — and the reason is the verification standard, not convenience.** The empty-body guard closes the release's only IRREVERSIBLE path, and an unexecutable arm is exactly the weak-arm class this release keeps finding. Four arms were added inside the `phase_publish_github_release` test group (**Test 4h**, arms e–i): the EDIT-path guard, the CREATE-path guard, an anti-vacuity control for each proving the same stub reaches the mutation for a well-formed note, and a conformance-fixture arm with a vacuity floor. **Disjointness is preserved where it was load-bearing:** re-mapped per-commit against each landed slice's own post-image, #5268 (slice 6) occupies `self_test :: Test 4b / Test 14 / Test 15` and #4416 (slice 7) `self_test :: Test 4d / Test 15`; **Test 4h is touched by neither**, so no sibling's declared region is entered. All four arms are **proven by mutation** (7 mutants, each classified REACHED/CRASHED before scoring). **Consequence for CIAC-3 / INT-2:** their stated confirmation that `self_test()` carries #4416's edits "and none from #4912" is now false as written — the correct reading is that #4912's edits are confined to Test 4h and do not intersect #4416's Test 4d or #5268's Test 4b/14. Flagged for the hub rather than silently satisfied | Engineering slice 8, #6143 |
| 28 | #4912's Stage-5 edge-case table records the pre-repair inline form diverging on **2** of 7 edge cases (lead-in **and** fence-trailing-whitespace) | **1 of 7 against the committed fixture, and the difference is fixture construction rather than a defect.** Stage 5's trailing-whitespace case put the padded fence in the OPENING position; the committed fixture puts it in the CLOSING position, which is the shape that actually tests S5 (does a padded fence close the block?). In the committed shape both forms return empty and agree. Recorded rather than re-cut to force a second control firing — the fixture already carries three independent controls, two of which fire on that case. The linter's pre-change model, added as a third control, diverges on **6** of 7 | Engineering slice 8, #6143 |

| 29 | #4912's Stage-5 design D2/D5 says the three shell tools **source** the shared library; the shape of that source was left to Engineering | **A load-time hard failure was the wrong shape, and CI proved it inside one push.** The library source was first written to `exit 2` at load time when the library was unreadable, on the reasoning that a close-out unable to derive a Release body should not start. `automated-closeout.sh`'s own corpus-home conformance suite reddened immediately: its four fixtures stage exactly **two** files into a synthetic tree (`cp "$CLOSEOUT" …`, `cp "$INSTANCE_LIB_SRC" …`), so a load-time dependency on a third file aborted every fixture before it ran — all four returned exit 2, the in-tree baseline read `R1 … REGRESSED`, and `--check-paths` violated `corpus-home-adapter-constraints.md` **CH-1** (instance-absence MUST record N/A and exit 0). A read-only probe must not be gated on a library only the publish path needs. **Corrected:** the source is tolerant, and the refusal moved to a **transform-present guard** inside `phase_publish_github_release` — strictly stronger than the adjacent `version-grammar.sh` degrade pattern, because it substitutes nothing and declines to publish. Reproduced and fixed **by mutation, not by re-running until green**: reinstating the load-time exit reproduces `R1 … fixture D exit 2` exactly, and the fixed source returns the expected per-fixture codes (A=0, B=0, C=1, D=0) with `PASS-SEAM-LANDED`. **The arm for the new guard was itself corrected in the same pass**, and that correction is the more useful record: arm `4h-j`'s first form asserted only that the phase FAILs and issues no edit, and it **passed with the transform-present guard deleted** — an undefined function still yields an empty capture, so the empty-body backstop caught it and the arm graded the wrong guard. It now grades the FAIL **detail**, the only signal distinguishing which guard ran, and fires when the guard is removed | Engineering slice 8, #6143 |

| 30 | #5253's Stage-5 design specifies **seven** Arm E self-test arms, `T-40`..`T-46`, covering the undocumented leg, the orphan leg, the parse rule, the not-run guard and the denominator identity | **Nine arms, `T-40`..`T-48`. The design's set leaves one HARD leg ungraded.** Arm E fails on `undocumented`, `orphan` **or** `duplicate`, and the duplicate leg is what enforces the README's own *"exactly one row"* rule — but no specified arm exercises it, so deleting it would have shipped green. Added `T-47` (a second row for a basename the table already contains FAILS as `DUPLICATE ROW`, with neither other leg firing) and its one-fact control `T-48`. Confirmed by mutation: neutering the duplicate leg is detected by `T-47` **alone** of the nine | Engineering slice 9, #6147 |
| 31 | #5253's Stage-5 design specifies `T-43`'s fixture decoy as a trailing table row of the form `\| 1 \| \`decoy.sh\` \| nothing \|` | **That decoy makes `T-43`'s terminator half VACUOUS, and the same is true of the live README.** The row-key rule keys on the first *backticked* token in column 1; a decoy whose column 1 is `1` is never a candidate, so the parse returns the identical list with the blank-line terminator honoured or ignored — measured directly: removing the `break` changes nothing, on the fixture **or** on the real file, whose two trailing tables are both of that harmless shape. **Fixed by diagnosis, not by adjusting the expectation:** the decoy's first column is now backticked, which makes the fixture the one place the terminator's removal is detectable. Re-proved by mutation — `break → continue` is now caught by `T-43` and `T-41`; before the fix it was caught by neither. The `doc_rows()` docstring records that the live README's terminator is belt-and-braces today, so the next reader does not mistake the fixture for a redundant copy of a live property | Engineering slice 9, #6147 |
| 32 | § ADR Allocation records five reserved slots as sufficient — *"six proposals resolving to five distinct decisions after dedup"* — and the ADR-153 row states the table is **deliberately NOT extended** | **No dedup materialized; the table is extended to ADR-154.** All six ADR-warranted proposals resolved to six distinct decisions. #5253's — that when one engine hosts two invariants, each population belongs to its *rule* rather than to the engine — dedups into none of the five landed records and **extends** ADR-119 rather than superseding it (ADR-119 stays `Accepted`). Extension executed per the rule the ADR-153 row points at: oracle re-run against `origin/main` **and** both branch ADR dirs scanned. Sibling branch `origin/release/pipeline-spec-self-consistency` also claims 148; that claim is **unmerged and therefore advisory** on D-CR2's own ratified basis, and stepping to 149 would open the numbering **gap** D-CR2 names as the blocking failure while a duplicate is tooled | Engineering slice 9, #6147 |
| 33 | #5253's Stage-5 design and § Implementation Sequence treat the two backfilled README rows as content carried forward from the design draft | **Every factual cell was re-verified against the tools themselves before it was written, and three claims in the draft were corrected — but this row's own first claim was NOT, and Stage 7's F-01 falsified it.** `check-operator-toml-schema.sh` exits **0 clean / 1 findings / 3 input-or-scan failure**, matching the corrected README row at `core/deploy/tools/README.md:97` and the tool's own header at `:59-63` (*"1  one or more findings (one FAIL line each; WARN lines do not set this)"*). The 1 is raised by the **ENFORCING C70b/C70c legs**; the mode-dialed C70a emits WARN lines that never set it, and `--emit-delta` **reuses 1** to signal a non-empty delta to `update.sh`. The superseded cell — *"exits **0 / 3** (there is no exit 1 in the file)"* — was **false**: `sys.exit(1)` at `:262` and `sys.exit(1 if findings else 0)` at `:264` are the clean/finding terminals, and `--self-test` at `:371` plus the dispatch tail at `:383` propagate them through `exit $?`. The parenthetical is *literally* true of a naive bare-`exit 1` grep — the exits are Python, inside the embedded heredoc — which is the exact trap Stage 7 named; a structured enumeration of every `sys.exit` / `exit` site returns **14**, of which **2** are the 1-class (positive control: 21 lines contain `exit`; negative control: a fabricated token returns 0). **F-01's fix corrected the README and left this cell stale**, so the row's stated warrant — *"Every factual cell was re-verified against the tools themselves"* — is precisely the claim this cell falsified, and it is recorded that way rather than quietly overwritten. Its C70a leg is **mode-dialed** via `resolve_check_mode "operator-toml-schema" "warn"` rather than unconditionally warn, and its declared coverage boundary (key SETS and absence of a hand-written emit — NOT `enum` or `type` enforcement) is stated in the row because the tool's own header states it. `start-skill-editor-session.sh` exits **0 / 1 / 2 / 3**, not "exit 2 usage" alone. Both tools' manifest membership and allowlist paths were confirmed live rather than transcribed | Engineering slice 9, #6147 |
| 34 | Stage-6 **C1** places the `## Change Description` in the release plan FILE; the slice-9 chip directs it to the PR #6169 body | **Authored to BOTH, deliberately — they are not alternatives.** C1 and `RELEASE_PROTOCOL.md` § Change Description Protocol require the section committed on the release branch *before* the PR is marked ready, so it is visible in the PR **diff** at Stage 9 Plan Review and so `G6-05` reads it structurally; the chip's PR-body placement makes it visible without opening the diff. Writing only to the PR body would have left the protocol's named location empty and `G6-05` measuring nothing. Both surfaces carry identical content | Engineering slice 9, #6147 |
| 35 | #4227's host-API axis carries `[SOURCE]`-grade figures because the pools are instrument-read | **Grade WITHDRAWN — the instrument is non-deterministic.** Measured at `ebc700c4`: 12 `gh api rate_limit` reads inside **3.6 s** returned **6 distinct `reset` epochs per pool**, `core.remaining` ∈ {4981, 5000} and `graphql.remaining` ∈ {4882, 5000}, with **8 of 12 reporting an unstarted window** (`used = 0`) interleaved with reads showing `graphql.used = 118`; a deterministic local control over the same 12 samples returned exactly 1 distinct value, so the variance is the instrument's. A Stage-7 reviewer independently observed `graphql 5000/5000` reported while GraphQL calls were being rejected. Both axes now render `[ASSUMPTION – CONFIRM]`. Edited: protocol § 1, § 4 preamble, § 4.1, § 4.3a, § 4.3b, § 4.3c, § 6.1 — the usage-window axis's own treatment is untouched | Stage 7 DT, #6149 |
| 36 | § 4.3b: exhaustion *presents as a successful read returning zero remaining* | **Not exhaustive — a second presentation exists and is the dangerous one.** Exhaustion can also present as a successful read of a **full, unstarted window**, on which the axis renders **PROCEED into the exact harm § 4.3b exists to prevent**: the spoke spends its full usage-window draw, completes, then cannot post its Issue comment. Now stated as a two-row case table with the consequence named, and recorded as an **undischarged residual** rather than a solved problem. The probe-*failure* fail-open reasoning is unchanged and still stands | Stage 7 DT, #6149 |
| 37 | ADR-156 `source_observations` #2: `core.used` stayed 0 across 9+ reads, **therefore** the probe does not draw against the pools it measures | **Inference CONFOUNDED — a read of an unstarted window reports `used = 0` regardless.** The observation cannot distinguish the two cases, so the claim is **UNVERIFIED** (neither asserted nor denied) and is withdrawn as evidence everywhere it was leaned on: ADR Context, Consequences, the *Estimate pool draw* alternative's basis, and protocol § 4.3a's cost paragraph. Observation #3's non-exhaustive case analysis corrected in the same pass. **ADR-156's decision is unchanged and this Stage-7 finding did not renumber it** (the later collision recoveries in rows 41 and 42 did, `144 → 150 → 156`); `generate-adr-index.py --verify` → `COUNT 0` | Stage 7 DT, #6149 |
| 38 | **Fork A's A4** — a complementary declared-state input for the host-API axis | **DEFERRED to a follow-on, operator-ratified.** A4 would let the axis distinguish a genuinely fresh window from an unstarted-window artifact, which is the only real mitigation for deviation 36. It is a **mechanism change**, and the Stage-7 remediation scope is **prose-only**, so it is recorded as deferred rather than implemented. Until it lands, presentation (b) stays a named residual of the axis | Stage 7 DT, #6149 — operator-ratified scope boundary |
| 39 | **CIAC-5's method** and **Deployment-Manifest Step 3** both assert `check-label-parity.py` **exit 0** | **Unreachable — restated as MISSING-set membership.** The tool is structurally `return 1 if (missing or orphan)`; at `ebc700c4` it reports **4 MISSING and 15 ORPHAN** rows, nearly all unrelated to this release, so exit 0 would require closing scope this release never took. Two spokes measured this independently: **exit 1** (correct multi-`--source` invocation) and **exit 3** (the literal bare invocation, which parses zero canonical labels post-#1970 and grades nothing). Restated in **both** places as *`auto-promoted-pattern` appears as a `MISSING` row* — the correct pre-materialization state, and a **stronger** assertion, since only a label already parsed into the canonical set can be reported MISSING. Control: at `8dc00db1` the label is in neither source file, so the assertion is `false` at base and `true` at head. The § Per-Issue Verification row for #5067 was reconciled in the same pass; the coverage limb (`check-selftest-coverage.py --reconcile` → exit 0) was **re-measured and is correct as written** | Stage 7 DT, #6149 |
| 40 | Risk **R9** — *#5240's mutation arm will not be CI-enforced / CI verification deferred* | **FALSIFIED — the risk does not exist and is retired.** R9 reasoned from the `--self-test` **discovery manifest** to CI reach, but a workflow can name a script explicitly without being discovered, and one does: `release-tooling-smoke.yml` job `finops-selftest` runs `extract-usage.sh --self-test` **by name** — the AC's method verbatim — and the mutation arms (10a/10b/10b2) plus their control arm live inside it. Conclusion **`success` on branch head `ebc700c4`** (48/48 green, read via REST); the job additionally carries a precision probe that fails if the self-test degrades to zero assertions. Corrected in the Risk Register **and** in the PR #6169 `## Known residual` section — an unretracted false residual would otherwise land permanently in the release log | Stage 7 DT, #6149 |
| 41 | § ADR Allocation binds this release's records at **ADR-143–148**, and PR #6169 dispatches its full required-context set | **Both falsified by a sibling merge, and both repaired by this recovery.** Sibling PR #6120 merged to `origin/main` and landed ADRs at **every number this release had claimed** — both trees peaked at ADR-148 carrying different records at 143–148. The PR went `CONFLICTING`, and GitHub does not dispatch on a conflicted head, so the required-context count collapsed to **0 of 9**: the same collapsed-denominator failure #4974 exists to detect, observed on this release's own PR. Repaired by **merging** `origin/main` (never rebasing) and renumbering the six claims **143–148 → 149–154**, order-preserving, via `renumber-adr.py --renumber … --apply` — the governed tool and D-CR2's ratified remedy, whose own oracle independently returned `NEXT-FREE 149` and the same order-preserving assignment. Sibling branch claims on 149/150 stayed **advisory** per D-CR2. Three true conflict files of ten overlapping: `automated-closeout.sh` (both sides' additions kept — #4912's transform-present guard and the mainline's DR-6 locals), `release/ADRs/README.md` (re-projected, never hand-merged), and `packages/release-hub.skill` (binary, no 3-way merge exists — rebuilt from the merged sources). Verified: `check-adr-numbers.py` PASS (contiguous `001..154`), `generate-adr-index.py --verify` → `COUNT 0`, `automated-closeout.sh --self-test` exit 0, and the required-context count recovered to **9 of 9** | Collision recovery, #6149 |
| 42 | § ADR Allocation binds this release's records at **ADR-149–154** — the state row 41 left | **Falsified again by a third sibling merge, and repaired the same way with one deliberate difference.** A sibling merged to `origin/main` claiming **149** (`core/ADRs/ADR-149-cross-domain-bridge-writes-are-not-symmetric.md`) and **150** (`core/ADRs/ADR-150-block-destructive-022-governs-execution-capability.md`), colliding with exactly two of this release's six records. Repaired by **merging** `origin/main` (never rebasing) — 32 commits, **one** overlapping file, **one** true conflict hunk — and renumbering **only the two collisions**, `149 → 155` and `150 → 156`, via `renumber-adr.py --renumber … --apply`; the tool's own `--detect` independently returned that same assignment. **ADR-151–154 were HELD FIXED**, which is the substantive difference from row 41: moving all six would have stranded 151–154 as an empty range, and D-CR2's ratified basis names the numbering **gap** — not the duplicate — as the blocking failure. The single conflict was the append-only **§ Renumber log** in `core/ADRs/README.md`, where the two sides had appended *different* entries. That file is a curated thematic document and **not** a projected surface — `generate-adr-index.py` § SCOPE excludes it by operator-ratified determination — so no re-projection could have repaired a wrong pick, and taking either side would have dropped the other's provenance rows permanently; it was resolved as the **union** of both tails, mainline entries first, with all nine (slug, new-number) pairs verified present under a structured probe carrying both a must-fire and a must-not-fire control. `core/ADRs/README.md` was passed `--exclude-path` on both hops so the citation sweep could not rewrite the mainline's own historical entries at 149/150 — the case the tool's own R3 scoping rule flags as needing a hand pass. Verified **against a pinned baseline** — `origin/main` at `b528f47d`, measured 2026-08-28: `check-adr-numbers.py` **PASS (156 ADRs, contiguous `001..156`, no duplicates)**, `generate-adr-index.py --write` → `UNCHANGED` (projection idempotent). **The baseline is stated because it does not hold indefinitely, and it has already moved:** `origin/main` advanced to `0ae7a583` during this same pass, and sibling PR #6182 landed records at **151, 152, 153 and 154** — every number this recovery deliberately held fixed. The oracle now returns `ANCHOR 154 / NEXT-FREE 155` with `151→157, 152→158, 153→159, 154→160` and 155/156 BINDING, which is a materially different assignment from the one this row records. **Deferred to the hub, not executed here:** the mapping diverges from this pass's scoped instruction, a third renumber would re-invalidate every ADR citation this pass just corrected, and choosing between chasing the mainline again and serialising the release is a sequencing decision above this slice. See Deviation Log 43 | Stage 7 DT pass 2, #6149 |
| 43 | The ADR number space is stable enough for a per-collision recovery to settle | **Contended beyond what per-collision recovery can absorb — a standing finding, not a one-off.** `origin/main` moved **twice inside this single Stage-7 pass** (`b528f47d` → `0ae7a583`), and across the release the same six records have now been renumbered by **three** separate sibling merges: `143–148 → 149–154` (recovery 1), `149→155` + `150→156` (recovery 2, this pass), and a pending third that would move `151–154 → 157–160`. Each recovery is individually correct and each is invalidated by the next. The mechanism is behaving exactly as ADR-115 says it must — a number is allocated at authorship and claimed at merge — so this is **contention, not drift**, and the remedy is not a better renumber tool. It is a sequencing decision: serialise the concurrent releases, or accept that a long-lived release branch re-numbers once per sibling merge and defer the citation sweep to a single pass at Stage 12. Recorded so the cost is visible to whoever makes that call | Stage 7 DT pass 2, #6149 |
| 44 | CIAC-5's restated method (Deviation 39) grades the bare invocation on **exit 3** | **Ambiguous — `3` alone does not identify the cause, so the limb can pass on a failure that never happened.** `check-label-parity.py` returns 3 from **three** distinct gate-path sites: `parsed zero canonical labels` (the state CIAC-5 means), `cannot read live label set` (the `gh label list` read failed — no auth, no repo context, rate limit), and `source unreadable` (an unresolved `--source`, which is what a wrong cwd produces). A Stage-7/8 reviewer reached the second path accidentally and could not tell it from the first by exit code. A grader without `gh` auth therefore passes CIAC-5 on a `3` that never occurred. Restated as **exit 3 AND stderr contains `parsed zero canonical labels`**, in CIAC-5 and in the § Per-Issue Verification row it cross-references. Measured at `63f08c87`: the clause is **true** on the meant cause and **false** on both others, so it discriminates rather than accepting any 3 — the specificity a bare-code assertion never had. Note Deviation 39 remains correct as far as it went; the exit-**1** limb and the MISSING-set restatement are unchanged | Stage 7 DT pass 4, #6149 |
| 45 | #5240 declares **Documentation Impact: NONE**, on the ground that *the exit-3 contract is already documented in the script header* | **The premise was true when the card was written and the slice itself falsified it.** `6359bdf0` added **two** new exit-3 causes (drop-set read, drop-set assembly) and did not touch the header block that `--help` prints, so the documented contract listed 2 of the eventual 4 causes and understated its own tool. The header now enumerates all four, states that each prints its own `FATAL (exit 3):` line, and says plainly that a caller branching on the code alone cannot separate *nothing to read* from *store intact but stale*. Verified structurally, not by eye: the four `FATAL (exit 3)` message sites are harvested from the source and set-compared against the four `--help` bullets, with both must-fail controls firing (that probe caught a real wording drift in the first draft of this very fix). The status row moves NONE → UPDATED. **Package coupling honoured in the same commit** — the script is a `.skill` member, so `packages/finops-usage-extractor.skill` + `.sha256` are rebuilt or the freshness gate goes red | Stage 7 DT pass 4, #6149 |
| 46 | #4227's write-early discipline ships into `hub-spoke-bridge.md` plus a Spoke-Template block, with the `spoke-launch.md` reinforcement disclosed as a deliberate omission (Stage 6 Rec 4; Stage 7 F-04, raised three times and skipped three times) | **Closed rather than re-deferred.** `spoke-launch.md` is what governs how the hub *renders* a brief, and it carried the `MUST carry … verbatim` reinforcement for both sibling blocks (Run-Directory, Hook-Response) and **zero** mentions of write-early — measured, with the two siblings as the positive control. A § Write-early guard section now sits alongside them, matching their shape: the MUST clause, the citation (cite-not-restate), and the byte-identical honest-scope paragraph, plus one boundary the siblings do not own — that for a comment-channel spoke the discipline bounds loss **within a resumable session only** and banks nothing across a re-spawn. Package coupling honoured: `packages/release-hub.skill` + `.sha256` rebuilt in the same commit | Stage 7 DT pass 4, #6149 |
| 47 | #4227's Documentation Impact row records SHAs `b5e81dff`, `c4ab70d6` | **Incomplete — `f4bb23cd` is missing**, and it edited `hub-spoke-bridge.md`, a doc the card itself declares. Clerical, and the omission is now closed. Verified by sweeping every branch commit touching either declared doc (`quota-budget-protocol.md`, `hub-spoke-bridge.md`) rather than by re-reading the row: six commits touch them, of which `b4d0aacb` and `79602237` are correctly attributed to #4912 and #4200 on their own rows and `d424e0d1` is an integration merge — leaving `f4bb23cd` as the single genuine omission | Stage 7 DT pass 4, #6149 |
| 48 | #4416's settle group ships as **five** arms, legs (f)-(j), with row 25's replacement assertion for leg (i) as the resolved state, and the shipped exhaustion-suffix render guard correct as written | **Six arms — (f), (g), (h), (i), (i.2), (j) — and the render guard was WRONG.** Stage 7 F-01 found the exhaustion-suffix guard in `phase_run_verification` at `:5905` was `-gt 0` rather than the loop's own `-ge "$VERIFY_RECHECK_ATTEMPTS"` terminal, so a run that broke out MID-POLL still appended `unsettled after 30s (15 polls)` — a constant budget figure the run never spent, contradicting both the comment above the guard and leg (i) verbatim. **Leg (i) was structurally incapable of catching it:** it only ever exercises polls=0, where the suffix is unreachable by construction under EITHER guard, so it was green for a reason unrelated to what it grades — which is exactly how `-gt 0` survived it. New leg **(i.2)** at `:9340-9366` drives the one state that separates the two guards: in-scope #401 holds the poll open across a 3-read injected lag, out-of-scope #999 then surfaces and breaks the loop with **3 of 15** attempts spent and the budget never waited. Behind an anti-vacuity floor pinned to the check-5-scoped instrument (`check-5 settled at poll 3/15`), whose moving controls are leg (f)'s `poll 5/15` and leg (i)'s `poll 0/15`, so the floor is a real reading and not a dead readout. **Proved by A/B mutation, not by reading:** Stage 8 lifted the settle block verbatim into an isolated harness and ran twelve fixtures under both guards — **12 of 12** shipped assertions of (f)/(g)/(i)/(i.2) pass under `-ge`; **exactly one** fails under `-gt 0`, leg (i.2)'s suffix arm at `:9366`, and it is the **sole** arm that does. Leg (i) was re-pointed in the same pass off the stub's **phase-scoped** `calls` counter — the gate-passage-proof rung calls `resolve_stage13_subtask`, which issues a third `issue list` after check 5 has already rendered — onto the check-5-scoped `poll 0/15` instrument plus an honest `<= 3` ceiling arm. **Recorded as its own row rather than as an amendment to row 25**: row 25 is Engineering slice 7's correction of the Stage-5 design's arithmetic, while this is a Stage-7 DT remediation of a shipped defect — a different pass, a different source and a different defect — and rows 45-47 set the release's convention that a DT-pass correction of this substance gets a row. The four durable surfaces that describe the ladder (this row, the group attestation clause at `:13324`, the PR-body arm roster, and the mutation table) were propagated at the Stage-9 clearing pass; the F-01 fix had landed in code and on none of them | Stage 7 DT (F-01), `63f08c87`, #6149 · re-measured Stage 8, #6158 |

## Operator Override Records

**Granted by the operator at the Stage 9 gate (Decision 2, recorded on #6128): all four.** Every reviewer surfaced the requirement and declined to author it — an override is a transfer of accountability, not a piece of prose, and the grant is the operator's. These records are the durable form of a grant already made. They authorize **no** criterion beyond the four below.

**Common cause for records 1-3.** #4912's AC2, AC3 and AC4 each specify an execution on a **GNU/Linux userland that the authoring environment cannot provide**. All three library consumers are macOS-pinned, so the GNU arm was never executed at any stage of this release; the transform's equivalence is measured on one userland and argued structurally for the other. The argument is strong — the chosen program uses no construct whose behaviour is in dispute — but it is an argument, not execution-grade evidence, and that distinction is what these records preserve. The remainder for all three is carried forward in **#6240** (open), which states the residual in exactly those terms.

| # | Card · Criterion | Criterion verbatim | Why unreachable in this environment | Grant | Where the remainder is carried |
|---|---|---|---|---|---|
| **OOR-1** | **#4912 AC2** | *"Confirm the frontmatter strip returns an identical non-empty body on BSD and GNU (method: run the strip on the same fixture under both, assert byte-identical and non-empty; a zero-length result on either arm fails)."* | The method names a **two-userland** run. The authoring host provides BSD only, and all three library consumers carry `# selftest-runner: macos`, so no GNU arm exists to run the fixture against. The BSD half is satisfied against the committed conformance fixture (198/198 live notes, byte-identical, with a deliberately-wrong implementation as the firing control); the GNU half is **unexecuted, not failed** | **Granted** — blocking condition unreachable from PR content. Operator, Stage 9 gate, #6128 Decision 2 row 1 | **#6240** (open) — successor to #4912, carrying AC2/AC3/AC4 forward with the residual stated as *equivalence measured on one userland and argued structurally for the other* |
| **OOR-2** | **#4912 AC3** | *"Confirm `check-release-body-drift.sh` **detects seeded drift on Linux** (method: seed a known divergence, run on the Ubuntu partition, assert non-zero exit and the drift named — this is the fail-open closing, and it must be exercised, not asserted)."* | The criterion's own method forbids the substitution that would make it satisfiable here: it must be **exercised, not asserted**. The tool is `# selftest-runner: macos`-pinned, so it is not in the ubuntu partition to be exercised; running it locally exercises the macOS partition and proves nothing about the GNU arm the criterion names | **Granted** — blocking condition unreachable from PR content. Operator, Stage 9 gate, #6128 Decision 2 row 2 | **#6240** (open) |
| **OOR-3** | **#4912 AC4** | *"Confirm the `# selftest-runner: macos` pins on `check-release-body-drift.sh` and `reemit-release-bodies.sh` are **removed** once the tools pass on both partitions (method: the discovery gate reports both in the ubuntu partition; re-derive the partition counts at build time — do not assert against a stored figure)."* | AC4 is **conditional on AC2 and AC3**: the pins may be lifted only *"once the tools pass on both partitions,"* which OOR-1 and OOR-2 establish did not happen. Removing them anyway would assert a passage never observed. The D6 falsification that would have discharged it was additionally refused by `BLOCK-DESTRUCTIVE-022`, and **Stage 8 graded that restraint correct**. Recorded at Deviation Log row 26 as NOT MET **with a stated cause**, per the Stage-5 branch (c) shape — the pins therefore **stay on**, and the tools' headers record that the pins' original basis is discharged and what would lift them | **Granted** — blocking condition unreachable from PR content. Operator, Stage 9 gate, #6128 Decision 2 row 3 | **#6240** (open) — and the two pins themselves, which remain in place solely because that evidence does not yet exist |
| **OOR-4** | **#5268 AC1 (remainder)** | *"A full `--dry-run` on an unclosed release exits 0 through phase 16 (method: run against a `DEPLOYED`-not-`VERIFIED` release; sensitivity arm — confirm the pre-fix run halts at 9.5 with exit 3)."* | **Structural half MET and measured**; the **end-to-end half** had no stage that was ever going to execute it. Stage 10 Dry Run was formally SKIPPED as PLATFORM-SATISFIED for git-native releases (#6129); Stages 7 and 8 are read-only by mandate; and **no fixture existed** — `origin/main` censused 190 rows / 190 `VERIFIED` / **zero** `DEPLOYED` (positive control 190, negative control 0). The criterion names a runtime execution without naming a stage that would perform it | **Granted**, dispositioned **Defer**. Operator, Stage 9 gate, #6128 Decision 2 row 4 | **This release's own Stage 12**, where the bounded state arises **by construction**. Stage 8 drove `ledger_gap_is_this_close` directly across every conjunct and proved the shipped predicate returns **PREDICT** for exactly that bounded state — this-release gap + dry-run → `rc=0 PREDICT`; identical fixture at `--apply` → `rc=1`; sibling gap → `rc=1`; two-row gap → `rc=1`; no gap → `rc=1`. **The discharge is therefore mechanical, not hopeful** |

**Scope of this grant, stated so it cannot be read wider.** These four records cover exactly the four criteria named above. They do not extend to any other criterion on #4912, #5268, or any other member of this release; they are not a precedent for deferring an executable criterion where an execution path exists; and they do not alter #4974's disposition, which closes on its delivered scope with its own successor issue (#6128 Decision 3). Reversibility **CHEAP** / confidence **HIGH** — each record is prose in this plan, and each remainder is carried by an open work item rather than dropped.

## Verification Evidence

*(Populated after Stage 12 execution — see `verification-checklist.md` for format.)*

## Deployment Execution Log

*(Populated during Stage 12 — see `execution-checklist.md`.)*

| Step | Timestamp | Result | Notes |
|---|---|---|---|
| Pre-execution check | | PASS/FAIL | |
| Merge PR | | PASS/FAIL | |
| Tag release | | PASS/FAIL | |
| Skill deployment | | PASS/FAIL | |
| Manifest execution (incl. operator label create) | | PASS/FAIL | |
| State anchor update | | PASS/FAIL | |
| Post-execution verification | | PASS/FAIL | |

## Closure Posture

All nine members are to be **marked as closed at Stage 13**, not before. #4912 in particular must not be marked resolved until its re-armed checks demonstrate fail-closed behavior on the ubuntu partition — the GNU-side behavior of both the old and the new frontmatter-strip form is unexecuted from the authoring host, and the first real GNU-arm evidence this release produces is at Stage 7.

## Change Description

### Outcome

This release makes the pipeline's own automation trustworthy under conditions that are transient rather than exceptional — a slow index, a busy API, a conflicted PR, a different `sed`. Nine gates and tools that could report success while measuring nothing now either measure the thing they name or say plainly that they could not. The unifying change is not a feature: it is that a claim which used to be carried by a comment, a hardcoded expectation, or a silent default is now carried by an executable arm that can fail.

### Issues resolved

| # | Outcome | Status |
|---|---|---|
| #5240 | `extract-usage.sh` no longer swallows a failed usage read: the two suppression sites now surface, so a run cannot exit clean with a silently duplicated store | DONE |
| #5067 | Pattern auto-promotion can fire. The promoter resolves `gh` through an explicit gate instead of inheriting a pinned PATH, and its missing label is declared in the taxonomy under a new `provenance` group | PARTIAL — the live label itself is a Stage-12 operator `gh label create`; a declaration detects, it does not materialize (D-CR3) |
| #4227 | Checkpoint B gained a measured second axis: host-API headroom read once per routing turn, combined with the usage-window verdict by DEFER-dominant disjunction, so healthy pools behave byte-identically | DONE |
| #4200 | Checkpoint B now also renders `W_max`, a cap on spokes in flight. Cumulative draw is invariant under width; interruption cost is linear in it, and every rule that bound PROCEED to "launch all N" now binds to `min(N, W_max)` | DONE |
| #4974 | Stages 7 and 8 check PR mergeability before reading gate conclusions, and floor the check classification on the live branch-protection required-context count — so a conflicted PR that dispatches nothing can no longer read green against a collapsed denominator | DONE |
| #5268 | Both members of the pre-mode-branch resolution class are fixed: phase 9.5 takes the mode test above the mode-dependent work, and phase 15.55 takes a per-limb downgrade because two of its three limbs must keep running at dry-run | DONE |
| #4416 | Check 5's single 2-second retry is now an attempt-bounded settle poll with a 30-second budget that exits the instant the open list drains and treats a failed read as a non-observation rather than a termination | DONE |
| #4912 | One frontmatter-strip transform, extracted to a shared library with two language mirrors, all three bound to a committed conformance fixture; and the publisher gained the empty-body guard standing in front of this release's only irreversible path | PARTIAL — AC4's depth-1 falsification was refused by a security hook and was surfaced rather than routed around, so the two runner pins stay on with the reason recorded (Deviation 26) |
| #5253 | The `core/deploy/tools/README.md` coverage rule is mechanically enforced. Arm E reconciles the directory listing against the inventory table bidirectionally, and the two rows the rule was already missing are backfilled in the same change | DONE |

### Key decisions

- **D2 — Release Class re-classified `routine` → `cross-cutting`** at the Stage-4 gate. Trigger (a) fires with margin, which moves the downstream posture to Tight engagement, Deep Stage-9 review, ALL Stage-5 activation, and a 30-day outcome window. See § Release Class Declaration.
- **D-CR1 — four scope items admitted at Collective Review.** Each was admitted because the member would otherwise ship inert or leave its stated defect live, not to widen the release: #5268 needed a second class member, #4200 needed the bridge rules that actually bind the verdict, #4227 needed the skill file whose cost claim its own change falsifies, and #4912 needed the empty-body guard on the irreversible path. See § Hub-Rendered D-Decisions.
- **D-CR2 — follow the ADR oracle rather than the sibling claims.** An unmerged claim is advisory; a numbering gap blocks the repository while a duplicate is tooled. This decision was re-exercised twice under pressure: once when a sibling merged mid-Engineering and turned an advisory claim real (Deviation 21), and once at the final slot (Deviation 32).
- **D-CR3 — a declaration detects, it does not materialize.** #5067's label limb cannot complete inside the PR and is an operator step in the deployment manifest. Recorded because Stage 4 had read the declaration as satisfying the criterion.
- **D-CR4 — scope locked at nine members.** No merges, no splits, no deferrals; the #4227 + #4200 merge was reviewed and declined at the pre-flight and is not re-proposed.
- **D-Concurrency — P0 fully-serial on one branch, one PR, one merge gate**, with force-push prohibited on the shared branch including `--force-with-lease`.

### Reversibility

**CHEAP / Confidence HIGH** for the release as a whole: every member reverts by `git revert` of its own commits with no schema change, no data migration and no host-side state, and the one host-side item (the operator label create) is an additive Stage-12 step recorded in the deployment manifest rather than something the merge performs.

### Downstream impact

- **The verification bar moved, and it is now the release's most reusable output.** Every one of the nine slices found a weak arm in its own harness — a shell-dependent `echo`, a `grep -q` inverted by `pipefail`, a counter scoped to the wrong phase, an arm that passed with its guard deleted, a fixture decoy that was never a candidate. All were fixed by diagnosis and re-proved by mutation. The next release inherits the expectation that an arm is not done until a mutant kills it.
- **Two records generalize past this release.** ADR-153 establishes that an invariant spanning several implementations must be executable rather than annotated; ADR-154 establishes that when one engine hosts more than one invariant, each population belongs to its rule rather than to the engine. Both are cited rather than restated by the surfaces they govern.
- **Carry-forward, explicit.** #4912's AC4 stays open with a stated cause, and the two runner pins stay on until the depth-1 falsification can actually be executed; the tools' headers now record that the pins' original basis is discharged and what would lift them. #4912 must not be marked resolved until its re-armed checks demonstrate fail-closed behavior on the ubuntu partition — the first real GNU-side evidence this release produces is at Stage 7.
- **Affected surfaces:** the close-out and release-body tooling, the quota-budget protocol and its bridge consumers, the self-test coverage engine, the label taxonomy, and the Stage 7/8/9 pipeline specs.

### Cross-references

- Release plan: this file, `release/releases/plans/ci-stable-under-transient-conditions_RELEASE_PLAN.md` — see § Deviation Log for the ratified deltas between the Stage-4 plan of record and what shipped. The count is deliberately not restated here: it was correct when authored and went stale during the ADR-numbering recovery, which is the same class of defect the log's own rows record. Every row carries a **Source** stamp, so the Stage-7 Dev-Testing remediation entries are identifiable by that column rather than by a row range that re-breaks on the next append.
- Milestone: `ci-stable-under-transient-conditions` (#353) — https://github.com/cody-hutson/pmo-platform/milestone/353
- User-facing release note (authored at Stage 13, not by this section): `release/releases/notes/{{RELEASE_VERSION}}_RELEASE_NOTES.md`
- Architecture records added by this release: ADR-151, ADR-152, ADR-153, ADR-154, ADR-155, ADR-156 — see § ADR Allocation.

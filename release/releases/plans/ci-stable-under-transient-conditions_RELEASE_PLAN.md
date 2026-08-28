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
| ADR-143 | **claimed** | #5067 — `core/ADRs/ADR-143-provenance-is-the-eighth-label-group.md` (slice 2) |
| ADR-144 | **claimed** | #4227 — `release/ADRs/ADR-144-checkpoint-b-second-axis-is-measured-not-declared.md` (slice 3). Lowest unclaimed slot per the allocation rule below; the oracle's live `NEXT-FREE 143` was correctly **not** used, since 143 is already taken on this branch by slice 2 |
| ADR-145 | **claimed** | #4200 — `release/ADRs/ADR-145-wave-width-is-a-second-checkpoint-b-output-not-a-verdict.md` (slice 4). Lowest unclaimed slot per the allocation rule; the oracle's live `NEXT-FREE 143` was again **not** used — 143 and 144 are already taken on this branch by slices 2 and 3. ADR index regenerated in the same commit |
| ADR-146 | **claimed** | #5268 — `release/ADRs/ADR-146-dry-run-predicts-apply-asserts-mode-branch-placement.md` (slice 6). Lowest unclaimed slot per the allocation rule; the oracle's live `NEXT-FREE 143` was again **not** used — 143, 144 and 145 are already taken on this branch by slices 2, 3 and 4. Verified free in BOTH ADR dirs on the branch and on `origin/main` before claiming. ADR index regenerated in the same commit |
| ADR-147 | reserved | *(unclaimed)* — table extended by one to preserve five allocatable slots after 142's withdrawal, per the `[ASSUMPTION – CONFIRM]` extension rule below |

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
| **R9** | Verification reach | **#5240's mutation arm will not be CI-enforced.** The selftest manifest declares `# scope: release/tools/*.sh` and siblings; `core/skills/` contributes **0 of 65** entries and `extract-usage` is absent | The AC's method is **locally-runnable** (`bash core/skills/finops-usage-extractor/scripts/extract-usage.sh --self-test`) and **declared, CI verification deferred**. Widening discovery scope to `core/skills/**` is a separate governed change, explicitly out of this release's scope | CHEAP / HIGH |
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

- [ ] **CIAC-5 (#5067 × #5253 on the declared-vs-enforced parity capability):** after this release, **no platform surface declares an artifact its own parity or coverage checker cannot see.** *Method:* `python3 core/deploy/tools/check-label-parity.py` exit 0 with `auto-promoted-pattern` in its known set, **and** `check-selftest-coverage.py --reconcile` exit 0. **Control:** at `8dc00db1` the label is absent from the live 80-label set and from both source files, and the coverage re-derivation prints 2 — both arms currently fail, so the paired pass is non-vacuous. **Precondition:** CIAC-5's label limb is gated on the Stage-12 operator materialization step (D-CR3) — declaration alone does not create the live label.

## Verification Plan

### Per-Issue Verification

| Issue | Verification Method | Expected Result |
|---|---|---|
| #5240 | `bash core/skills/finops-usage-extractor/scripts/extract-usage.sh --self-test` | exit 0; the pre-existing carry-forward arm and the new drop-set mutation arms all green |
| #5240 | Mutation arm — force the drop-set read to fail under `do_incremental()` | exit **3**, a `FATAL (exit 3)` line naming the drop-set read, and the store **byte-unchanged** |
| #5240 | Control arm — the same harness with no injected failure | exit 0, store rewritten; proves the harness is not what makes it fail |
| #5067 | `bash release/tools/synthesize-release-learnings.sh --self-test` under a pinned PATH | `gh` resolves lazily against three candidates; no hard-exit at load; ubuntu-discoverable |
| #5067 | `python3 core/deploy/tools/check-label-parity.py` | `auto-promoted-pattern` in the known set; `--emit-fix` renders the operator `gh label create` |
| #4227 | Replay a recorded `GraphQL 0/5000 + REST 4966/5000` state against the authored rule | DEFER-dominant disjunction fires; healthy pools preserve today's behavior bit-for-bit |
| #4200 | Replay the observed 3-wide wave's envelope | `W_max` rendered as a second output; verdict enum unchanged |
| #4974 | Replay a CONFLICTING PR's required-context read at Stage 7 / 8 entry | `0 of 9` required rows classifies `checks-unreadable` → PARTIAL, never PASS |
| #5268 | `automated-closeout.sh --dry-run` on a first-close fixture | Reaches phase 16 exit 0; no pre-mode-branch abort at 9.5 or 15.55 |
| #5268 | AC3 regression arm in `self_test()` | Fails on a reintroduced pre-branch resolution |
| #4416 | Never-converging self-test leg at `VERIFY_RECHECK_DELAY=0` | Terminates on the **attempt** bound; renders `PARTIAL … unsettled`, never `PASS`; suite does not hang |
| #4912 | Conformance fixture across all implementations | Byte-identical output on 198/198 live notes and all edge cases; a deliberately-wrong implementation differs (firing control) |
| #4912 | Empty-body guard | `gh release edit --notes ""` is unreachable on the strip path |
| #5253 | `python3 release/tools/check-selftest-coverage.py --reconcile` | Arm E green on arrival with both README rows backfilled; sensitivity arm (inject a fabricated tool) flags; specificity arm does not |

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
| 3 | **Create the `auto-promoted-pattern` GitHub label** | **Operator, Stage 12** | `gh label create` — command rendered read-only by `check-label-parity.py --emit-fix` | Label present in the live label set; `check-label-parity.py` exit 0 |

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
| 21 | ADR slots reserved as **142–146**; ADR-142 allocatable because the two sibling claims on it were unmerged and therefore advisory | **ADR-142 withdrawn; #5067 takes ADR-143; table extended to 147.** Sibling PR #6119 **merged to `origin/main` during Engineering** (`15e6bf01`), landing `release/ADRs/ADR-142-…`. Its claim stopped being advisory at that moment, and the oracle re-anchored: `ANCHOR 142 (origin/main)` · `NEXT-FREE 143`. Taking 142 would now duplicate **merged mainline**, not an unmerged claim — a materially different thing from the case D-CR2 ratified. Following the oracle (D-CR2's operative instruction) therefore yields **143**. Verified free in BOTH ADR dirs on the branch and on `origin/main` before claiming; `--detect` confirms `CLAIM ADR-143 … BINDS`. Table extended by one slot to preserve five allocatable slots, per the extension rule in § ADR Allocation | Engineering slice 2, #6145 |
| 22 | § Implementation Sequence states, as the `#4227 → #4200` mandated-coordination interface, that **§§ 4.3 / 4.3a are untouched by #4227** | **True of both verdict tables and of § 4.3a's SERIALIZE-meaningless sentence — proved byte-identical with a firing control — but NOT of § 4.3a's trailing "Cost, and why per-launch firing is affordable" paragraph, which #4227 rewrote.** That paragraph is not a verdict surface; it is the cost claim (*"the check is zero tool calls … it is not an instrument"*), and the Stage-5 Cascade-Sweep marked it **UPDATE** on the same evidence that admitted `release-hub/SKILL.md` into scope: making the gate measured falsifies it. Leaving it standing would have shipped the same self-contradiction the scope addition existed to prevent. #4200's own assumption **A4** anchors on the SERIALIZE-meaningless sentence, which is untouched, so the assumption holds as written; #4200's **A2** (a § 4.2 step that renders the verdict) is the one that moved — the verdict-render step is now the combination step's named usage-window branch. Both restated for hub reconciliation before slice 4 | Engineering slice 3, #6141 |
| 23 | § Implementation Sequence + #4200's Stage-5 design both name **§ 4.3b** as the new sibling section — #4227's host-API axis AND #4200's width guidance were each specified into the same identifier | **#4200's width guidance lands in a NEW § 4.3c**, immediately after #4227's § 4.3b and before § 4.4. #4227 shipped first and took § 4.3b, exactly as the plan's interface clause says it would; the collision is between the two Stage-5 designs, not with the plan. All of #4200's own cross-references (§ 4.2's usage-window branch sentence, § 4.3's PROCEED row, § 4.3a's inert-at-N=1 sentence, § 7, § 8, both bridge consuming rules, `spoke-launch.md`) cite **§ 4.3c**. Ordinal position is preserved, no identifier is reused, and #4227's § 4.3b is byte-untouched | Engineering slice 4, #6125 |
| 24 | #4974 editset = 2 files; `release-readiness-scan-spec.md` listed under § File Change Matrix **Read-only inputs** | **3 files.** The Stage-5 design's OPTIONAL third file (R3) is **taken IN** at the hub's recommendation: two `consumers:` frontmatter lines naming Stages 7 and 8, so a future edit to § 5.1 can see the two call sites it acquired. Genuinely two lines — the design's companion one-sentence § 5.1 note was **dropped** to hold R3 at its stated size. The file moves from Read-only inputs to the ratified-delta edit set. Verified clear of sibling PR #6120 (its 61-file editset does not contain this path, re-measured 2026-08-27). No `version:` field touched | Engineering slice 5, #6144 |

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

All nine members are to be **marked as closed at Stage 13**, not before. #4912 and #4974 in particular must not be marked resolved until their re-armed checks demonstrate fail-closed behavior on the ubuntu partition — the GNU-side behavior of both the old and the new frontmatter-strip form is unexecuted from the authoring host, and the first real GNU-arm evidence this release produces is at Stage 7.

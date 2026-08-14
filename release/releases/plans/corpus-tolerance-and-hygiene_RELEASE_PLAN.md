<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
---
title: Release Plan — corpus-tolerance-and-hygiene (tolerance suites accept conformant layouts, and structural gaps in bundling and signing are closed)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: corpus-tolerance-and-hygiene
release_class: novel
domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-12, domain: governance }
reversibility: CHEAP / Confidence HIGH
---
# Release Plan — `corpus-tolerance-and-hygiene`

**Milestone:** `corpus-tolerance-and-hygiene` (milestone 324). Six build cards on one branch, one pull request, one merge.
**Version identity:** **slug-only** per **ADR-092**. This file is `corpus-tolerance-and-hygiene_RELEASE_PLAN.md` and the branch is `release/corpus-tolerance-and-hygiene`; no version stem appears in the filename, in the branch name, or in this plan's identity prose. The concrete number binds at the **Stage-12 atomic compare-and-swap**, which renames this file into its major-version bucket.
**Topology:** **D-C SINGLE** (Stage-4 default, operator-approved) — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** **P0 fully-serial** (D-Concurrency Posture, Stage-4). Stage-6 work routes one card at a time in the approved sequence on the shared branch. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`novel`** — corrected from the declared `routine` at the Stage-4 gate, operator-rendered (D-1). Posture: engagement density **Standard** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL**, activated on 6 of 6 · Stage-13 outcome window **30-day**.

---

## Provenance

This file transcribes the **Stage-4 Release Planning** analysis approved at the plan-approval gate, reconciled forward through the six **Stage-5 Solutioning** designs and the eight operator decisions rendered at the **Collective Review scope-lock gate on 2026-08-12 (Wednesday)**. Where a later measurement superseded a Stage-4 figure, **this file carries the decided state** and § Deviation Log records the delta. The Stage-4 and Stage-5 output comments are the historical record and are not edited; the Tier-1 [ADJUST] correction comment on planning sub-task #5094 — the Stage-4 planning record — is the correction of record for that sub-task and **must be read alongside it at Stage 9**.

**Why this plan is the second commit in commit order.** The release's first Engineering commit (`f8c755b2`, the R5-discriminator card #4429) declined to author this file because it sat outside that card's scope-locked two-file change matrix. Reporting the gap rather than silently widening scope was the correct call; the artifact was reassigned to a dedicated remediation spoke, which authored this file. It is still **Engineering Commit 0** in the Stage-6 Phase C1 sense — it lands on the release branch before the pull request is marked ready-for-review, and every later card inherits it.

Every issue reference below sits inside this reference block and is accompanied by the summary that makes it readable without opening the ticket.

---

## Release Outcome Statement

**AFTER** — Tolerance suites accept conformant layouts, and structural gaps in bundling and signing are closed.

**BEFORE** — The tolerance suite fails a conformant resolver and its arming transition is manual and reversible; no check asserts AC presence at bundling; two result labels are un-emittable; there is no signature gate; ADR numbering forces repeated renumber sweeps.

**Success Indicator:** every ticket below closes with its acceptance criteria verified, and the gate or check each one names demonstrates a **real failure on a fixture** before it is trusted.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | slug-only pre-claim per ADR-092; recorded determination **v4.23**, **PROVISIONAL** — see the note below |
| **Date Created** | 2026-08-09 (Sunday) — Stage-4 planning |
| **Scope-lock / Collective Review** | 2026-08-12 (Wednesday) |
| **Commit 0 authored** | 2026-08-12 (Wednesday) |
| **Release Manager** | Agent-assisted, release-hub Mode O |
| **Status** | Executing — Stage 6 Engineering |
| **Branch** | `release/corpus-tolerance-and-hygiene` |
| **Base commit** | `a5138652`, equal to `origin/main` at branch cut and still equal to `origin/main` at Commit 0 |
| **First build commit** | `f8c755b2` — the R5-discriminator card #4429, CI-green |
| **Pull request** | **#5269** — the single draft release pull request carrying all six cards |
| **Milestone** | `corpus-tolerance-and-hygiene`, milestone 324 |
| **Release class** | `novel` |
| **Topology and posture** | D-C SINGLE topology, P0 fully-serial posture |

**D-Version is `v4.23` and is PROVISIONAL.** It is a *recorded determination*, not a reservation: it binds only at the Stage-12 atomic compare-and-swap per ADR-092, and the plan file, the branch, and all hub state key on the **milestone slug**, never on the version. The determination was **re-computed twice during Stage 5** as sibling releases claimed slots ahead of this one; the superseded numbers are not restated here, because they are falsified and a reader must not carry one forward. The durable record of each re-determination is the `T-1` row in the hub's Decision Recorded comments on the Stage-5 design sub-tasks. Two sibling milestones sit at Stage 8 ahead of this one, so **a further re-determination at Stage 12 is expected, not exceptional**, and no version literal ships in this release's code.

---

## Scope

| Ticket | Size | Pts | Priority | Disposition | One-line scope |
|---|---|---|---|---|---|
| #4429 | `size:S` | 2 | P3 | build, sequence position 1 — **BUILT**, `f8c755b2` | the tolerance suite fails a conformant Check-26-layout resolver at R5 |
| #4428 | `size:M` | 4 | P3 | build, sequence position 2 | the suite's arming transition is manual, untracked, silently reversible |
| #4235 | `size:S` | 2 | P2 | build, sequence position 3 | two result labels are structurally un-emittable |
| #4232 | `size:M` | 4 | P2 | build, sequence position 4 | no check asserts AC presence at `status: bundled` |
| #4236 | `size:S` | 2 | P2 | build, sequence position 5 | no signature gate anywhere in the pipeline |
| #4237 | `size:S` | 2 | P2 | build, sequence position 6 | a renumber stales packages and neither rebuilds nor names them |

**Raw 16 points** · release class `novel` → `class_weight` **1.15** · **effective points 18** (`round_half_up(16 × 1.15) = 18`), inside the 15–25 band. The G3-15 gate is an upper-bound predicate only; verdict **PASS**. The weights are declared in `core/config/platform-config.toml.template` under `[bundling].release_class_capacity_weights`, so no degraded-path computation and no operator confirmation of the figure is owed.

**Composition Lock:** locked at Stage-4 Planning entry, 2026-08-08 (Saturday), on the Stage-4 planning sub-task. **Zero membership change since the lock** — every adjustment recorded below is an `amend`-class change inside the locked set.

### Approved implementation sequence

```
#4429 → #4428 → #4235 → #4232 → #4236 → #4237
```

This sequence **inverts** the milestone description's declared first pair and was corrected at the Stage-4 plan-approval gate, operator-approved (D-3).

**The ordering stands; its originally-stated cause is falsified.** The Stage-4 rationale claimed R5 fires through the `ARMED` disjunct of `a != 0 && (ARMED || b == 0)`, making the arming card's posture work the reason to sequence behind the R5 fix. The R5-discriminator card's Stage-5 spoke tested that claim by deleting the disjunct: **R5 still failed.** A conformant Check-26-layout resolver fails fixture A (`a != 0` — fixture A does not model that layout) while correctly tolerating the absent root (`b == 0`, CH-1 conformant), so `b == 0` satisfies the disjunct alone. The sharper root cause is that **the false red is coupled to CH-1 conformance** — the more conformant a resolver is on CH-1, the more certainly R5 false-reds it. The order is retained on the two surviving grounds, both of which are sufficient on their own.

| # | Issue | Why it sits here |
|---|---|---|
| 1 | **#4429** — the R5 discriminator | **Shared-file serialization.** Both this card and the arming card edit `release/tools/tests/test_corpus_home_tolerance.sh`; landing the contained `size:S` fix first on the shared file is the lower-conflict order. The arming card should also pin its posture onto a suite whose R5 no longer false-reds — a posture assertion pinned against a mis-verdicting suite bakes in the wrong baseline. |
| 2 | **#4428** — the arming-posture sentinel | Builds the sentinel on a now-trustworthy suite, and re-derives every numeric anchor against the post-discriminator file. |
| 3 | **#4235** — event-label scoping | Promoted to position 3 as the only card with **zero** contention, intra-release or cross-PR. Lands a clean win early and repairs the event-emission path this release's own Stage-13 close may need. |
| 4 | **#4232** — AC presence at bundling | Serialized ahead of the signature card because its mechanism was settled earliest in the design pass. Its `core/deploy/deploy.sh` edit is in-place inside a marker-delimited region. |
| 5 | **#4236** — the signature check | Follows the AC-presence card on the original `deploy.sh` serialization plan. Under the accepted design it adds **no** deploy rung at all, so the intended contention is empty rather than merely ordered. |
| 6 | **#4237** — renumber disclosure | Last by design; no sibling touches either of its two files, so it can rebase onto a fully settled branch at zero cost. |

---

## Release Class

The class is **`novel`**, corrected from the milestone's declared `routine` at the Stage-4 gate and operator-rendered as **D-1**.

| `routine` trigger | Verdict | Evidence |
|---|---|---|
| (a) all issues P3/P4 and `size:S`/`size:M` | **FALSIFIED** | two cards are P3, but **four of six are P2** |
| (b) all change-spec files have three or more prior release touches | **FALSIFIED** | three files sit below the threshold — `test_corpus_home_tolerance.sh` 2 · `corpus-home-adapter-constraints.md` 2 · `check-adr-numbers.py` 2 |
| (c) zero new files added | **FALSIFIED** | this plan file is an `add`, and two cards each add a file |
| (d) zero new D-class decisions | **FALSIFIED** | five of six cards carry an explicit design-direction decision |

| `novel` trigger | Verdict | Evidence |
|---|---|---|
| (b) at least one D-class decision in the release plan | **FIRES** | five cards defer a mechanism selection to design time; the Deviation Log below records nineteen entries, eight of them operator-rendered at Collective Review |

`cross-cutting` fires none of its three triggers — **0** pipeline stage files in the Stage-4 matrix, **1** named governance surface, and **1** in-bundle compositional edge against a threshold of three. Multi-trigger ordering `cross-cutting` > `novel` > `routine` resolves to **`novel`**.

**Anti-pattern self-check.** The `novel` anti-pattern warns against classifying a routine ticket as novel because *the ticket* is new. That is not the basis here: the basis is that five of six cards defer a **mechanism selection** to design time, which is protocol-newness. The `routine` anti-pattern — classifying aggregate design load as routine because individual issues are small — is precisely what the declared class was doing.

---

## Dependency Graph

Directional. Every edge carries its evidence; no card is called independent without a stated basis.

```
#4429 ══[shared file + shared header block]══> #4428     (serialization edge, not a blocker)
#4235   (independent — zero contention)
#4232   (independent)
#4236   (independent)
#4237   (independent)
```

**Native dependency edges: zero.** All six cards return an empty `blocked_by` set from the GitHub Issue Dependencies API. *Probe validity:* the denominator is all 6 in-scope cards plus 5 out-of-scope controls; the **sensitivity arm** returned a non-zero `blocked_by` elsewhere in the repository, so the endpoint demonstrably reports edges when they exist. The zero is **valid, not a broken probe**.

| Edge | Class | Evidence |
|---|---|---|
| **#4429 → #4428** — discriminator ahead of sentinel | SHARED-FILE (soft, directional) | Both edit `release/tools/tests/test_corpus_home_tolerance.sh`, and both grow the same header block that the file's own `--help` range must be re-synced against. Not a blocking edge — a serialization edge, operator-adopted as D-3. |
| **#4235 independent** — event-label scoping | — | Its edit targets are `release/tools/append-pipeline-event.sh` and `release/references/standards/pipeline-event-log-schema.md`; no other card in the bundle and no in-flight sibling touches either. |
| **#4232 independent** — AC presence | — | Its two related-to cards are both CLOSED and non-blocking. Its `deploy.sh` edit is in-place inside the `C22-EVAL-BEGIN/END` markers. |
| **#4236 independent** — signature check | — | Under the accepted Direction B design it adds a **standalone new workflow** and touches no file any sibling card edits except the contended gate register. |
| **#4237 independent** — renumber disclosure | — | Its two files, `release/tools/renumber-adr.py` and `release/tools/tests/test_renumber_adr.sh`, are claimed by no sibling card and no in-flight sibling pull request. |

**Circular chains: zero.** The denominator is 15 ordered pairs over six build cards.

**In-bundle compositional edges: 1** — below the `cross-cutting` trigger threshold of three.

---

## Stage Applicability Matrix

Per the milestone's own Success Indicator, **no card skips any stage** — every one changes executable behavior and claims a testable failure.

| Issue | Stage 5 | Stage 6 | Stage 7 | Stage 8 | Stages 9–13 | Stage-5 rationale |
|---|---|---|---|---|---|---|
| #4429 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | Mechanism choice; the fix must not convert a false red into a false green. |
| #4428 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | Three named candidate mechanisms of differing weight. |
| #4235 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | Its whole-population sweep over declared subtypes is analysis better sited at Stage 5 than improvised at Engineering. |
| #4232 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | Runner selection explicitly routed to Stage 5 by the card. |
| #4236 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | Direction (1) versus (2) is an explicit acceptance criterion. |
| #4237 | **ACTIVATE** | ✓ | ✓ | ✓ | ✓ | The re-scope decision is itself design work. |

**Skips: none.** All six cards ran Stage 5 and all six run Stages 6–13. The `novel` class sets the Stage-5 activation bias to **ALL**, which is why the event-label card — the one genuine `SKIP-where-trivial` candidate under a `routine` class — activated.

**Parallel-eligible spoke counts:** Stage 7 **6** · Stage 8 **6**. Worst parallel batch **6**. The Stage-4 Quota Budget returned **WARN** against a conservative-default envelope and recommends splitting each parallel stage into **two batches of 3**, keeping the two shared-file cards in the same batch so their reviewers share context. Checkpoint A is advisory; the load-bearing gate is Checkpoint B at each launch.

---

## Contention Map

**Baseline pin:** `origin/main` @ `a5138652`, re-measured 2026-08-12T04:35Z at Commit 0. `origin/main` has not moved since branch cut.

### Within-release

| Path | Claimed by | Overlap verdict | Resolution |
|---|---|---|---|
| `release/tools/tests/test_corpus_home_tolerance.sh` | the discriminator card and the sentinel card | **TRUE OVERLAP** — `line-range-overlap` | Strict serialization, discriminator first. Both edit existing rule and function bodies; this is not an append pattern, so ADR-005's informational treatment does not apply and the mitigation is sequencing per ADR-001. |
| `release/references/standards/corpus-home-adapter-constraints.md` | the discriminator card and the sentinel card | **ADJACENCY** in §5 | The discriminator card owns line 62 and the fixture table; the sentinel card appends R8 to the rule block and edits the posture and retirement lines. §3 and the `CH-1..CH-4` identifiers are **no-edit** for both — R6 greps for them and line 44 forbids renumbering. |
| `core/standards/gate-efficacy-standard.md` | the sentinel card and the signature card | **APPEND-PATTERN**, ordered | Each appends one register row at the end of the table. The sentinel card's row lands first by sequence; the signature card re-derives the append point from the file at build time by content anchor. The AC-presence card's conditional row is **DECLINED** (D-9), which drops this from four-way to three-way contention counting the in-flight sibling. |
| `core/deploy/deploy.sh` | the AC-presence card only | **SOLE CLAIMANT** | The Stage-4 map predicted a three-way convergence across three cards. The sentinel card's accepted design lands a sentinel file plus suite edits and adds no deploy rung; the signature card's accepted Direction B adds a standalone workflow and no deploy rung. **The intra-release three-way collapsed to one claimant** — the hub required the signature card's spoke to test rather than inherit that assessment, and it tested empty. |
| `.github/workflows/` | the signature card only | **SOLE CLAIMANT** | Direction B ships `.github/workflows/commit-signature-check.yml` as a **new standalone workflow** rather than a step inside an existing one, which removes the predicted collision with the sentinel card's smoke-workflow edit — an edit that itself did not survive into the accepted design. |

**The silent breaker — the highest-value contention finding in this release, and it does not present as contention.** `release/tools/tests/test_corpus_home_tolerance.sh` line 240 carries `sed -n '3,187p'`, the range its own `--help` branch prints. The discriminator card re-derived that range from `3,127p` to `3,187p` after its header growth. **The sentinel card must re-derive it again** after its own header growth, from the file itself — never from a number quoted in any design document. This is the one collision between the two cards that **breaks silently**: a stale range either truncates the help text or over-runs into executable code, and nothing fails. Operator decision **D-6** makes this re-derivation a binding Stage-6 requirement, and integration criterion **INT-1** grades it.

### Cross-PR contention

Two sibling pull requests are open at the Commit-0 baseline. Intersections computed as a set intersection over each sibling's full file list against this release's File Change Matrix.

| Sibling | Intersection with this release's file set | Class | Action |
|---|---|---|---|
| the triage-and-backlog-instrumentation release (draft) | **3 paths** — `core/standards/gate-efficacy-standard.md`, `core/schemas/gate-criteria-spec.md`, `core/deploy/deploy.sh` | `line-range-overlap` on the two governance surfaces; `append-pattern` on `deploy.sh` | **Material.** Whichever merges second rebases. The sibling edits a gate-register row in place while this release appends; the AC-presence card re-derives the `gate-criteria-spec.md` schema version from the mainline at build time rather than taking any number from its design spec. |
| the install-completeness-and-honest-reporting release (ready) | **1 path** — `core/deploy/deploy.sh` | `append-pattern` | Informational. |

*Probe validity:* the intersection is a computed set operation over each sibling's live file list, 40 and 19 paths respectively. **Sensitivity:** the same procedure returned non-empty for both siblings, so it detects intersections when they exist. **Specificity:** a control path present in neither side's list returned absent for both.

**Sibling-merge stale-pin self-invalidation trigger.** Re-run the intersection at Stage 9 entry and again at Stage 12 Phase A.5. Both siblings intersect materially and the population turned over completely inside one day earlier in this release — **treat re-validation as expected, not exceptional.** This is carried as action item AI-001 from Stage 5 and applies under audit-baseline discipline.

### Structural blast radius

**No movers.** The bundle declares zero renames, relocations, or deletions — every card is an in-place edit to an existing file, plus two `add`s of new files into existing directories. No sibling serializes on a mover axis.

---

## Risk Register

| ID | Risk | Severity | Owner action | Mitigation | Reversibility |
|---|---|---|---|---|---|
| **R1** | **Shared-file semantic merge** on the tolerance suite between the discriminator card and the sentinel card — a merge that compiles but mis-verdicts. | **HIGH** | Serialize | Strict serialization on one branch; **no parallel Stage-6 chips on this file**. CIAC-1 grades coexistence at Stage 9. **The discriminator has landed**, so the live residual is the sentinel card's edit onto a settled file. | CHEAP / HIGH |
| **R2** | **The `sed` help range goes stale silently** after the sentinel card's header growth (the silent breaker above). | **HIGH** | Re-derive | D-6 binds Stage 6 to re-derive the range from the file itself after both header growths. INT-1 grades the shipped `--help` output for truncation and over-run. **This is the release's only failure mode that produces no signal on its own.** | CHEAP / HIGH |
| **R3** | **Cross-PR contention with the triage-and-backlog sibling** on three paths, two of them `line-range-overlap` on governance surfaces. | **MED** | Serialize merge | Whichever merges second rebases; the register edits are an in-place row versus an appended row. The AC-presence card re-derives the schema version at build time. Re-check at Stage 9 entry. | CHEAP / MEDIUM |
| **R4** | **Opposing pressures on one verdict path.** The sentinel card requires the suite stay green while the seam legitimately does not exist; the discriminator card required that its fix not convert a false red into a false green. Over-correcting either un-arms the suite. | **MED** | Anti-vacuity arms | Both cards' anti-vacuity controls are **mandatory, not optional**. The discriminator shipped three in-suite controls that run on every invocation; the sentinel card ships three more, of which the comparator non-vacuity control must not be omitted. CIAC-1 requires both sets present and demonstrably firing. | CHEAP / HIGH |
| **R5** | **The signature check blocks this release's own merge.** A check shipping in this release applies to this release's branch. | **MED** | Cutover clause | Resolved by design: the check is **advisory and explicitly never registered as a required branch-protection context** (D-11), and the Stage-12 sub-step carries an **introducing-release-exempt** cutover clause. The documented remedy for a real violation is **re-sign the commit**, never an administrative override. | CHEAP / HIGH |
| **R6** | **The AC-presence check applied retroactively fails the backlog.** | **MED** | Cutover posture | **Blast radius re-measured and materially smaller than Stage 4 stated: 2 of 86** gated cards — the two AC-less cards #2577 and #4185, both confirmed OPEN, `status: bundled`, gated template, zero acceptance criteria. The Stage-4 figure counted cards the check cannot gate. With a true blast radius of two, the posture question turned on *which two*, and **D-8** renders the answer: the arm inherits the existing `g1-enforcement.mode` **warn** posture. | CHEAP / HIGH |
| **R7** | **An unenforceable cutover clause ships as prose.** The card recommended grandfathering anchored at the introducing-release merge SHA; no label-application timestamp is reachable inside the check's one-issue-list-read budget. | **MED** | Do not author it | **Resolved by D-8.** Ship the presence arm at **warn** by inheriting an existing, already-flip-levered mode rather than authoring a clause the check cannot honour. Authoring an unenforceable cutover is exactly the false-confidence defect this milestone exists to close. | CHEAP / HIGH |
| **R8** | **The gate register becomes multi-way contended for documentation of gates rather than for the gates themselves.** | **LOW** | Decline the marginal row | **Resolved by D-9** — the AC-presence card's conditional register row is declined. The renumber card's disclosure step is not a gate, so it earns no row either. Two rows land, both from cards that ship an actual gate. | CHEAP / HIGH |
| **R9** | **The renumber disclosure step alters the tool's exit contract.** A naive subprocess call with failure propagation would fail a fully-verified renumber. | **MED** | Degrade, never fail | The new step is wrapped: on **any** subprocess failure it emits a degraded notice and continues, and **must not alter the return value under any circumstance**. The degradation fixture arm pins this against the fixture's natural state, in which the resolver script is absent. | CHEAP / HIGH |
| **R10** | **The AC presence arm leaks into shape checking**, newly failing 7 gated cards whose acceptance criteria use ordered lists. | **MED** | Keep the arms separate | The presence arm and the existing shape arm are **independent**; the shape arm is byte-unchanged and the new counter does not feed it. An ordered-list fixture arm guards the boundary. The wider shape defect is routed out, not fixed here. | CHEAP / HIGH |
| **R11** | **A sibling merges between this baseline and Stage 12**, invalidating the contention map. | **LOW** | Re-check | AI-001: re-intersect the roster at Stage 9 entry and at Stage 12 Phase A.5. The population turned over completely inside one day during Stage 4, so this window is real and short. | CHEAP / HIGH |

**Rollback complexity.** Ten of eleven entries are **CHEAP** to reverse — single-file edits to tools, tests, schemas and standards, all revertable by `git revert` with no data migration and no external state. **R5 is the operational exception:** a CI check, once live, is observed by every subsequent pull request, so reverting it is mechanically CHEAP but operationally **MODERATE**. Because the check is advisory and unregistered, that residual is smaller than it would be for a required context. No entry is EXPENSIVE or IRREVERSIBLE.

---

## Cross-Issue Acceptance Criteria

Four release-scoped cohesion constraints. Each spans two or more issues, asserts a constraint no per-issue criterion covers, and is graded on the merged pull request at **Stage 9 Phase A3.6 / QC3.5** under the Stage-8 per-criterion verdict enum.

- [ ] **CIAC-1 — coexistence on the tolerance suite, spanning the discriminator card and the sentinel card.** Both changes coexist without either defeating the other: a conformant Check-26-layout resolver **passes** the suite **when the arming declaration matches what the suite observes (`armed`)** and, when the declaration reads `pending`, fails on **R8 alone** with R1–R7 all passing; the arming posture is recorded on a surface **outside** the suite's own authoring files; and **both** cards' anti-vacuity controls are present and demonstrably fire.
  *Shared surface:* `release/tools/tests/test_corpus_home_tolerance.sh`.
  *Precondition — the suite is posture-bound, and this recipe does not run without setting it.* Since the sentinel card landed rule R8, the suite compares the arming posture it OBSERVES against the posture the repository DECLARES, and fails on any divergence. A conformant resolver run against the committed `pending` sentinel therefore exits 1 **by design**, not by defect. Every arm below states which declaration it runs under: for an `armed` arm, point `CORPUS_HOME_ARMING_FILE` at a sentinel whose first non-comment non-blank line is `armed`; for a `pending` arm, leave it unset so the committed `.github/corpus-home-tolerance.arming` applies. An arm run without setting this is not a failing criterion — it is an un-run one.
  *Method:* **(a)** run the suite against the conformant fixture **under an `armed` declaration** and assert **exit 0**. **(b)** re-run the **identical** conformant fixture under the committed **`pending`** declaration and assert **exit 1 with R8 as the sole failing rule** — R1–R7 all PASS. **(c)** run against a non-demonstrating fixture and assert non-zero. Arm (b) carries the coexistence assertion proper, and it is graded in both directions: a conformant resolver reddening any of R1–R7 would mean the sentinel card defeated the discriminator card, while R8 failing to fire would mean the discriminator card defeated the sentinel card. Then count matches for the posture record on its non-authoring surface, expecting at least one. *Anti-vacuity:* the pre-change count on that surface is **0**.

- [ ] **CIAC-2 — every new mechanical check names its runner and its posture, spanning the AC-presence card and the signature card.** Each new mechanical check this release ships states **both** its runner and its cutover posture at its documented home, in the vocabulary the gate spec already uses.
  *Shared surface:* the documented home of each new check — the `G3-05` rows in `core/schemas/gate-criteria-spec.md` and the register rows in `core/standards/gate-efficacy-standard.md`.
  *Method:* for each new check, search its documented home for a runner reference and a posture reference; expect at least one match of each. *Control:* the same searches against a pre-change checkout return **0**. Note that under D-8 the recorded posture is **warn-inheritance**, not a merge-SHA anchor — a criterion that graded the presence of a SHA anchor would now fail correctly.

- [ ] **CIAC-3 — no duplicate check identifier and a clean `--check`, spanning any card landing in `core/deploy/deploy.sh`.** Where a card lands or modifies a check rung, the rungs carry **distinct** identifiers with no duplicate or reused number, and `core/deploy/deploy.sh --check` runs with all rungs present.
  *Shared surface:* `core/deploy/deploy.sh`.
  *Method:* run `bash core/deploy/deploy.sh --check`; extract the check-ID list and assert `sort | uniq -d` is empty. *Scope note, recorded honestly:* the Stage-4 form of this criterion anticipated three claimants. Under the accepted designs the **AC-presence card is the sole claimant and adds no new rung** — its edit is in-place inside the existing evaluation region. The criterion is retained because the duplicate-identifier assertion is cheap and because an in-flight sibling also edits this file, so it still grades a real merge property; it must not be reported as having graded a three-way in-release convergence that did not occur.

- [ ] **CIAC-4 — mutation-proof discipline, spanning all six cards.** Every check, gate, or fixture this release ships or repairs is **mutation-proven** — the release's evidence names, per card, the specific mutation applied and the observed failure it produced. A control that is documented but never demonstrated to fire does not satisfy this predicate.
  *Shared surface:* the per-card Stage-7 Dev Testing reports.
  *Method:* each card's report carries a mutation row naming the mutation and the observed non-zero exit; Stage 9 reads the emitted verdicts read-only. **Declared, verification executed at Stage 7.**

---

## File Change Matrix

**Machine-readable path list** — one path per line, so Stage 7, 8 and 9 chips extract this block deterministically:

```
release/releases/plans/corpus-tolerance-and-hygiene_RELEASE_PLAN.md
release/tools/tests/test_corpus_home_tolerance.sh
release/references/standards/corpus-home-adapter-constraints.md
.github/corpus-home-tolerance.arming
core/standards/gate-efficacy-standard.md
release/tools/append-pipeline-event.sh
release/references/standards/pipeline-event-log-schema.md
release/tools/bundle-issues-parser.py
core/deploy/deploy.sh
core/schemas/gate-criteria-spec.md
core/deploy/tests/test_g1_form_family.sh
release/tools/tests/test_bundle_issues_parser.py
release/references/pipeline/stage-03-bundle.md
.github/workflows/commit-signature-check.yml
release/references/pipeline/stage-12-execute.md
release/tools/renumber-adr.py
release/tools/tests/test_renumber_adr.sh
```

| Path | Intent | Owning cards |
|---|---|---|
| `release/releases/plans/corpus-tolerance-and-hygiene_RELEASE_PLAN.md` | add | this plan, landing as Engineering Commit 0 |
| `release/tools/tests/test_corpus_home_tolerance.sh` | edit | the R5-discriminator card #4429 (**landed**) and the arming-sentinel card #4428 |
| `release/references/standards/corpus-home-adapter-constraints.md` | edit | the R5-discriminator card #4429 (**landed**) and the arming-sentinel card #4428 |
| `.github/corpus-home-tolerance.arming` | **add** | the arming-sentinel card #4428 — the committed posture sentinel, modelled on the existing `.github/close-completeness.enforce` convention |
| `core/standards/gate-efficacy-standard.md` | edit | the arming-sentinel card #4428 and the signature card #4236, one appended register row each. The AC-presence card's conditional row is **declined** (D-9) |
| `release/tools/append-pipeline-event.sh` | edit | the event-label scoping card #4235 |
| `release/references/standards/pipeline-event-log-schema.md` | edit | the event-label scoping card #4235 — §11.8 consumer description, plus the §11.4 window-rationale clause folded in under D-7 |
| `release/tools/bundle-issues-parser.py` | edit | the AC-presence card #4232 — the presence primitive |
| `core/deploy/deploy.sh` | edit | the AC-presence card #4232 only, in-place inside the `C22-EVAL-BEGIN/END` markers |
| `core/schemas/gate-criteria-spec.md` | edit | the AC-presence card #4232 — the `G3-05` criterion row, its self-repair row, the Gate-3 minimum re-check set, and a version-history bump re-derived from the mainline at build time |
| `core/deploy/tests/test_g1_form_family.sh` | edit | the AC-presence card #4232 — eight new arms including a control, a mutation control, and a degraded-state arm |
| `release/tools/tests/test_bundle_issues_parser.py` | edit | the AC-presence card #4232 — primitive-level cases |
| `release/references/pipeline/stage-03-bundle.md` | edit | the AC-presence card #4232 — the `G3-05` row of the Gate-3 procedure table |
| `.github/workflows/commit-signature-check.yml` | **add** | the signature card #4236 — Direction B, a standalone advisory workflow |
| `release/references/pipeline/stage-12-execute.md` | edit | the signature card #4236 — a new sub-step discriminating the signature cause of a blocked merge state |
| `release/tools/renumber-adr.py` | edit | the renumber-disclosure card #4237 — rationale correction at two sites, plus a new post-apply disclosure step |
| `release/tools/tests/test_renumber_adr.sh` | edit | the renumber-disclosure card #4237 — a new fixture block with behavioural, negative-control and degradation arms |

**Two `add`s, both verified absent at Commit 0.** Every other path in the list is verified present on the branch at `f8c755b2`.

**No ADR file.** Next-free is **`ADR-131`**, verified live at Commit 0 by `python3 release/tools/renumber-adr.py --next-free`. Per **ADR-115** an unmerged branch claim is **advisory**, and next-free is `anchor(origin/main) + 1`, never `max(claimed_set) + 1` — allocating above the mainline slot creates a gap, and a gap blocks the repository while a duplicate inconveniences one branch and is resolved by tooling at Stage 12. **This release authors no ADR file at all** under operator decisions D-5 and D-14, so the number is recorded for correctness and not claimed.

**New-executable companion obligation: does NOT fire.** No tracked executable shell script is an `add` in this matrix. The two new files are a plain-text sentinel and a GitHub Actions workflow, neither of which is agent-invoked, so no `core/config/allowlists/script-execution-allowlist.txt` row is owed. Both existing in-scope scripts are already allowlisted.

---

## Verification Plan

### Per-issue

- **The R5-discriminator card #4429 — BUILT at `f8c755b2`.** A conformant Check-26-layout resolver passes the suite; a genuinely non-demonstrating resolver still fails R5 with a distinct reason; the three-token status enum separates *the resolver does not satisfy CH-2* from *the fixture did not exercise CH-2*; and three synthetic controls run in-suite on every invocation, including a hermeticity guard asserting the adaptive seed cannot write outside the temp tree.
- **The arming-sentinel card #4428.** The posture record exists on a surface outside the suite's authoring files; a landed seam with an unflipped sentinel exits 1; reverting a landed seam produces an observable failure rather than a second green; the suite stays green when no seam is present; and the comparator control asserts all six synthetic pairs, including that an `armed`-declared, `pending`-observed pair returns `un-armed` rather than `aligned`.
- **The event-label scoping card #4235.** A conforming payload emits for both previously-blocked result subtypes, and both are covered by a self-test fixture; breaking the type-and-subtype scoping fails the fixture; the whole-population sweep confirms no other subtype is blocked by the same scoping, with the population stated in closing evidence. The self-test's schema-to-mirror lockstep assertion is replaced with a whole-registry bidirectional comparison, because the prior two-name form would pass vacuously after the re-key. **Plus the D-7 fold-in:** the §11.4 window-rationale clause is corrected, and **a matching acceptance criterion is authored on the card at Stage 6** so Stage 8 does not grade an uncovered edit.
- **The AC-presence card #4232.** A fixture pair asserts heading-depth and template-era independence, both passing; a heading with zero criteria beneath **fails** the presence arm; removing the section from a fixture fails and reverting restores; a sub-task card is detected at recommend tier and never gates; an ordered-list card passes the presence arm with the shape arm silent; and the degraded arm emits exactly **one** population-wide not-evaluated finding with **zero** per-issue failures when the primitive is unavailable.
- **The signature card #4236.** Pushing an unsigned commit to a test branch produces a named finding **identifying the SHA** before the merge boundary, and a signed commit passes; the failure message's documented remedy is **re-sign the commit**, explicitly not an administrative override; the check is confirmed **absent** from the repository's required-context list.
- **The renumber-disclosure card #4237.** The behavioural arm asserts a staled package archive is named in standard output after an apply, and fails against the pre-fix tool; the negative-control arm asserts the none-affected line and no package name; the degradation arm asserts the run still exits 0 with the resolver script absent from the fixture tree; and a search for the falsified rationale string in the tool returns **0 rows**.

### Integration criteria

Three integration criteria are emitted for the arming-sentinel card against the upstream discriminator card — covering the `--help` range after both header growths, the rule list agreeing between header and executable body, and the standard's §5 rule block naming one rule set rather than two partial ones. One is emitted for the renumber-disclosure card against the package builder's path-to-skill query mode, discharging a read-only-verification limitation recorded at Stage 5 when a destructive-action control blocked executing that tool. All are graded at Stage 8 Phase B under the per-criterion verdict enum.

### Release-level

- `core/deploy/deploy.sh --check` against an expected-red baseline pinned at branch cut, including doc-link integrity across modified markdown files and the register-row resolution-pointer recomputation. Every register row this release appends anchors on a **function name, never a line number**, because that check recomputes each row's pointer and the register's own rows record that every line pin in that file has drifted this release.
- Runtime-suite selection per the runtime-suite selection map, driven by the modified path set; one `test-run` event per suite.
- The four Cross-Issue Acceptance Criteria above, graded at Stage 9.

---

## Rollback Strategy

A `git revert -m 1 <merge-sha>` on the single merge commit restores every surface atomically. There is no migration, no data mutation, no external state, no schema versioning, and no corpus backfill. **CHEAP / HIGH.**

Per-card pre-merge rollback is equally cheap: each card is a distinct commit in a known sequence and can be dropped or amended before the pull request merges. The two coupled cards are the one asymmetry — reverting the sentinel card leaves the discriminator intact, but reverting the discriminator alone requires re-checking the sentinel card's posture assertion and the `--help` range, since both were derived against the post-discriminator file. **MODERATE** for that single direction.

The one obligation that does not revert cleanly with the branch is the new CI workflow: once observed, any branch that adapted to it must be re-checked. Because the check is **advisory and never registered as a required context**, that residual is bounded — no pull request is blocked by its absence or its presence.

**Rollback trigger conditions:** (1) the tolerance suite reddens on a legitimately absent seam, which would indicate an over-correction; (2) the signature check produces a finding on a branch with no unsigned commit, a false positive; (3) the AC-presence arm fires on a card outside its gated class, a scoping defect.

**Rollback is operator-authorized.** No spoke initiates a rollback; a spoke surfaces the trigger and the operator renders it.

---

## Domain Practice Provenance

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-12, domain: governance }`

Sourcing-exempt: the entire File Change Matrix is internal platform artifacts. The domain is classified from the matrix — the dominant domain is **`governance`**, being a gate schema, two standards, two pipeline stage documents, and a bundle procedure, with **`software`** secondary for the four tool and test scripts and the workflow. Sourcing exemption and domain classification are distinct properties; exemption from external sourcing does not make the release domain-less.

---

## Deviation Log

Every entry is operator-rendered or hub-recorded at a named decision point, with the surface it deviates from stated. **D-1 through D-3** were rendered at the Stage-4 plan-approval gate; **D-4 through D-7** at the Stage-5 wave-1 Decision Briefing; **D-8 through D-14** at the Collective Review scope-lock gate on 2026-08-12 (Wednesday). **D-15 through D-19** are hub-recorded corrections, not separate operator gates.

| # | Deviation | Deviates from | Decision point | Disposition |
|---|---|---|---|---|
| D-1 | **Release class corrected `routine` → `novel`** | the milestone description's declared class | Stage-4 plan approval | **Adopted.** All four `routine` triggers tested and none fires; `novel` (b) fires. Sets Stage-9 depth Deep and Stage-5 bias ALL. Milestone description patched. |
| D-2 | **The renumber card was re-scoped `size:M` → `size:S`**, and its residual re-characterized | the card's filed scope | Stage-4 plan approval | **Adopted, with the hub diverging on the residual's nature.** Three of four original criteria shipped in a prior release. The real defect is an **ordering gap** — a renumber leaves affected packages stale and neither rebuilds nor flags them — not a citation-rewriting gap. The card body and all four criteria were rewritten; the original scope is preserved in-body for lineage. |
| D-3 | **Implementation sequence corrected**, the discriminator ahead of the sentinel and the event-label card promoted to position 3 | the milestone's declared Internal Sequence | Stage-4 plan approval | **Adopted.** Zero membership change, so this is an `amend`-class change. See § Scope for the corrected rationale — the stated cause was later falsified, the ordering was not. |
| D-4 | **The optional cross-card edit to the suite's landed-seam terminal block was DROPPED** | the sentinel card's own optional change | Collective Review | **Dropped.** The post-retirement residual is documented and accepted: retiring the suite's pending branch without also removing the sentinel and its rule would leave a `pending` declaration failing closed. The obligation is recorded in the standard's retirement condition instead of in the suite's terminal prose. |
| D-5 | **Both recommended ADRs DEFERRED** | the two Stage-5 spokes' ADR recommendations | Stage-5 wave-1 | **Deferred.** Neither spoke marked its ADR `required`, and both patterns are fully documented in their durable Stage-5 output comments. Re-filed as follow-ups after the renumber card ships. |
| D-6 | **The `--help` range re-derivation is BINDING on Stage 6** | taking the range from either card's design document | Stage-5 wave-1 | **Adopted.** Stage 6 re-derives `sed -n '3,Np'` and every other numeric anchor **from the file itself** after both header growths. This is the one collision that breaks silently. |
| D-7 | **The §11.4 window-rationale fix is FOLDED IN to the event-label card as a Tier-1 [ADJUST]** | routing it out as a next-release issue, the spoke's stated alternative | declared deferral at Stage-5, rendered at Collective Review | **Folded in — with a matching acceptance criterion authored on the card at Stage 6.** The clause claims per-release result rows would dominate the cluster signal; both synthesizer read paths are subtype-scoped and the window is applied after filtering, so such a row can never enter the window. The added criterion is not optional: without it Stage 8 would grade an edit no criterion covers. |
| D-8 | **The AC-presence arm inherits the existing `g1-enforcement.mode` warn posture** | the card's recommended merge-SHA grandfathering anchor | Collective Review | **Adopted.** The card's anchor is **not mechanically implementable** — no label-application timestamp is reachable within the check's one-issue-list-read budget. Warn-inheritance uses a lever that already exists and is already flippable, and it is a **true** statement at the documented home rather than an unenforceable one. |
| D-9 | **The AC-presence card's conditional gate-register row is DECLINED** | the spoke's conditional change | Collective Review | **Declined.** Accepting it would make `core/standards/gate-efficacy-standard.md` four-way contended for *documentation of* a gate rather than for the gate. The card's other four changes are complete and self-consistent without it. |
| D-10 | **A Tier-1 [ADJUST] correction was posted to the CLOSED Stage-4 planning sub-task** | amending the sub-task body | Collective Review | **Comment, not rewrite.** The body is left unamended as historical record per ADR-062; the comment is the correction of record and Stage 9 must read it alongside the plan. Two claims are corrected — the AC-check mechanism and the retroactive-failure figure. |
| D-11 | **The signature card builds Direction B** — an advisory CI check using the GitHub API as its oracle, **explicitly never registered as a required branch-protection context** | the card's pre-selected required-check framing | Collective Review | **Adopted.** The card's stated ground for preferring one direction was falsified on a *different* ground than the card argued: the alternative is not weaker, it is **unbuildable**, because the repository mixes two signature types and no local-git oracle can verify the population. Branch protection already blocks unsigned merges; the real gap is **diagnostic legibility**, not enforcement. Keeping the check unregistered keeps the misfiring-required-check blast radius out of this release entirely. |
| D-12/13 | **Three out-of-scope findings routed to next-release intake** | absorbing them into this release | Collective Review | **Routed out.** The general discriminator for an undiagnosable blocked merge state (a more recent recurrence exists whose commits were all verified, so signatures were not its cause), the policy home for administrative merges, and commit-signing codification in `core/rules/git-workflow.md`. The last is a `core/rules/` governance edit requiring its own approval. Each needs its own issue; **none enters this milestone.** |
| D-14 | **The ADR deferral is RE-CONFIRMED after one of its original grounds was found false** | the deferral's stated rationale | Collective Review | **Deferral stands; the reasoning is corrected.** One stated ground was *avoid a renumber sweep*. That ground does not hold — a sweep is cheap and tooled, and next-free is `ADR-131` rather than any higher number, because an unmerged branch claim is advisory under ADR-115. The two surviving grounds stand on their own: neither ADR was marked `required`, and both patterns are fully documented in durable Stage-5 comments. **This release authors no ADR file.** |
| D-15 | **The Stage-4 blast-radius figure for the AC-presence card is superseded** | the Stage-4 plan's stated retroactive-failure count | Collective Review, via the correction comment | **Corrected to 2 of 86.** The original figure counted cards the check cannot gate. Only the two AC-less gated cards #2577 and #4185 are genuinely in the gated set. This materially changed the cutover decision — with a blast radius of two, the question became *which two*, not *how many*. |
| D-16 | **The Stage-4 AC-check mechanism is falsified** | the card body's and the Stage-4 plan's stated mechanism | Collective Review, via the correction comment | **Corrected.** Applicability for the gated family is set **unconditionally from the applies-to triple** at `core/deploy/deploy.sh:6573-6577`; the heading search that both documents named sits in the `else` branch and governs the other families only. The real defect is the **fail-open on the empty set at `:6718`** — with zero criteria the bad-count is zero, so nothing is emitted. A design built on the stated mechanism would have hardened a code path that was never the problem. Card bodies left as historical record per ADR-062. |
| D-17 | **The intra-release three-way convergence on `core/deploy/deploy.sh` did not materialize** | the Stage-4 contention map | Stage-5, hub-verified | **Collapsed to one claimant.** Two of the three predicted claimants add no deploy rung under their accepted designs. The hub required the third spoke to **test** rather than inherit the assessment; it tested empty. Recorded so no reviewer reports CIAC-3 as having graded a three-way that never existed. |
| D-18 | **The in-flight sibling roster was corrected at Stage 4, and turned over again since** | the hub's injected three-sibling roster | Stage-4 planning, re-measured at Commit 0 | One listed sibling had merged roughly one minute before the Stage-4 baseline. The live population at Commit 0 is again **two**, but they are **different** pull requests. Audit-baseline discipline applies: the roster is pinned, and re-checking at Stage 9 is mandatory. |
| D-19 | **Two Stage-4 path-currency mismatches were corrected before Engineering** | two cards citing paths absent from the mainline | Stage-4 Phase A0.5 | **Resolved in the matrix, not deferred.** Two standards had relocated to `core/standards/`. A third flagged path resolved exactly where cited and was an over-fire — directory existence is not file existence. Worth naming: one correction is what **created** the cross-PR contention on the gate register. |

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing. Refreshed on any Tier 1 adjustment that changes which issues land or which decisions stand.*

### Outcome

The corpus-home tolerance suite stops failing resolvers that are actually correct, and starts recording its own arming posture in a file a reviewer can diff instead of inferring it from a green log. Alongside that, three structural gaps close: acceptance-criteria presence becomes a mechanically asserted precondition of bundling rather than an unchecked convention, two result labels that were structurally impossible to emit become emittable, an unsigned commit becomes legible before the merge boundary rather than surfacing as an unexplained blocked state, and a renumber run now names the packages it staled together with the command that rebuilds them.

### Issues resolved (6)

Status uses the protocol's `DONE / PARTIAL / DEFERRED` enum, which grades **final disposition**. At Commit 0 only the first card is built; the remaining five are designed and scoped but not yet implemented, so their disposition is not yet gradable. This table is refreshed on the pass before the pull request is marked ready-for-review.

| Issue | What lands | Status at Commit 0 |
|---|---|---|
| **#4429** — the R5 discriminator | R5's verdict routes through a falsifying coverage discriminator built from the resolver's own output. A conformant resolver passes; a resolver that genuinely fails to demonstrate the constraint still fails, with a reason naming which of three statuses was observed. | **DONE** — `f8c755b2`, CI-green |
| **#4428** — the arming sentinel | The suite's arming posture is declared in a committed sentinel and asserted against what the run observes, failing closed in both directions. A landed seam cannot go undeclared and a reverted seam cannot return the suite to a second green with nothing recording the loss. | build pending |
| **#4235** — event-label scoping | Label validation resolves by event type **and** subtype, falling back to the type-level set. Two previously un-emittable result labels become emittable, and the self-test's lockstep assertion is replaced with one that cannot go vacuous. | build pending |
| **#4232** — AC presence at bundling | Acceptance-criteria **presence** is asserted at the bundling transition, independently of heading depth and template era, through a delegated predicate rather than a second heading grammar. The existing shape check is untouched. | build pending |
| **#4236** — the signature check | An advisory workflow names any unverified commit and its SHA on every pull request, with re-signing documented as the remedy. A new Stage-12 sub-step stops a blocked merge state from being a silent pass when signatures are its cause. | build pending |
| **#4237** — renumber disclosure | A renumber run names every package archive it staled plus the exact rebuild command, degrading to a generic notice rather than failing when the resolver is unavailable. The tool's falsified exclusion rationale is corrected at both sites where it appears. | build pending |

### Key decisions

Nineteen deviations are logged above. The five an operator would most want surfaced:

- **D-11** — the signature check ships **advisory and unregistered**, because branch protection already blocks unsigned merges and the real gap is diagnostic legibility. This also keeps a misfiring-required-check blast radius out of the release.
- **D-8** — the new bundling check inherits an existing warn posture rather than shipping a grandfathering clause the check cannot mechanically honour.
- **D-16 and D-15** — the mechanism and the blast radius that both the card body and the Stage-4 plan asserted for that check were **wrong**, and were corrected by reading the substrate rather than reasoning about it. The real blast radius is **2 of 86**, not an order of magnitude larger.
- **D-14** — no ADR file ships in this release, and the deferral was re-confirmed after one of its three original grounds was found false.
- **D-6** — the suite's `--help` range must be re-derived from the file, not from any design document. It is the release's only failure mode that produces no signal when it goes wrong.

### Reversibility

**CHEAP / HIGH.** One branch, one merge, one `git revert -m 1`. No migration, no data mutation, no external state, no corpus backfill. The single operational residual is the new advisory CI workflow, which is observed by later pull requests but blocks none of them.

### Downstream impact

- The tolerance suite gains one adaptive fixture path and one new rule; the sentinel it reads is a new committed file, and retiring the suite's pending branch must remove both together.
- The gate-coverage register gains two rows, each anchored on a function name so the register's own recomputation stays correct.
- The bundling gate gains a presence assertion at warn; two backlog cards will report against it on first run, both known and named.
- A new advisory workflow appears on every pull request. It is never a required context, so no merge outcome changes.
- The renumber tool gains a disclosure step that cannot alter its exit status.
- Three findings are routed to next-release intake rather than absorbed here: a general discriminator for an undiagnosable blocked merge state, the policy home for administrative merges, and commit-signing codification in the git-workflow rules.

### Cross-references

- Release plan: this file, `release/releases/plans/corpus-tolerance-and-hygiene_RELEASE_PLAN.md`.
- Milestone 324, `corpus-tolerance-and-hygiene`.
- The Stage-4 planning sub-task #5094, carrying the approved plan **and its Tier-1 [ADJUST] correction comment** — both must be read together.
- The six Stage-5 design sub-tasks #5098, #5102, #5106, #5110, #5114 and #5118, each carrying one card's design output and its hub Decision Recorded comment.
- Pull request #5269 — the single draft release pull request carrying all six cards.
- User-facing release notes: authored at Stage 13 to `release/releases/notes/`, version-keyed at the Stage-12 claim.

---

## Verification Evidence

**Not yet populated — one of six cards is built.** This section is populated at Stage 6 self-verification and refreshed by Dev Testing at Stage 7, per the release-plan authoring contract. At Commit 0 only the R5-discriminator card has landed and only its CI result exists, so writing per-card evidence rows now would either be blank or fabricated. The pull request's checks are green at `f8c755b2`; the per-card evidence, the mutation rows CIAC-4 requires, and the integration-criteria verdicts are produced by the Stage-7 and Stage-8 spokes and land here.

---

## Deployment Execution Log

**Not yet populated — the release has not reached Stage 12.** This section is populated at Stage 12 Execute with the merge SHA, the claimed version, the tag, and the close-out outcome. None of those values exists at Commit 0, and the version determination in § Header is explicitly provisional until the atomic claim.

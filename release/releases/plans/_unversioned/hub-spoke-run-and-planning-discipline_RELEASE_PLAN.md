<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
# Release Plan — hub-spoke-run-and-planning-discipline

> **Status:** Engineering Commit 0 (release branch `release/hub-spoke-run-and-planning-discipline`).
> **Identity:** VERSION-LESS — identity is the capability slug; no version key is claimed and no signed version tag is produced at Stage 12.
> **Topology:** D-C SINGLE · **Concurrency posture:** P0 fully-serial · **Milestone:** `hub-spoke-run-and-planning-discipline`.
> **Source:** Stage 4 Release Planning spoke output (working reference: the Stage 4 planning sub-task), transcribed here at Commit 0 with the six corrections recorded in § Corrections Carried Into Commit 0. From this commit the plan FILE is the durable surface every later stage reads; the sub-task comment is superseded.

---

### Summary (30 seconds)

Seven cards on one branch, one PR. The release makes a hub session's staging bounded by the same run-directory discipline a spoke's is, gives Stage-4 planning an agent-editability dimension so a Tier-0-floored card surfaces at planning rather than at Engineering, and reconciles the Stage-13 `.version` stamp with Surface-1 publication.

- **Class `novel`** — promoted at the Stage-5 exit gate by operator decision D17 on trigger **(c)** (`≥1 Stage-5 ADR`). Trigger (a) never fired: all eight designs chose extend-an-existing-seam over authoring a new artifact, and the only file adds in the release are four test fixtures on #6596.
- **Stage 9 review depth: Deep** (was Standard). Engagement density Light. Stage-13 outcome-window 30 days. Stage-5 activation bias `SKIP-where-trivial` is spent — it reached no card.
- **30 effective points against a 15–25 band.** The override is accepted and extended: D13 recorded 28 after the D7 scope expansion; D26 extended it to 30 when the #5505 packaging cascade surfaced. Recorded here rather than left implicit.
- **Three original cards are gated.** #5833 (`BLOCK-SKILL-EDIT-001` + `-002`), #5084 (via D5), #5505 (via D11) each require a live `pmo-skill-editor` Mode A session with a 1800 s sentinel TTL. The `unconstrained` classification arm is carried by late-add #6597.
- **The Stage-5 ADR carries no number.** Cite it as **#6617**. D27 deferred number allocation to Stage 12 after three concurrent releases collided on 170/171; a numbered form written now would be a claim this release cannot honour.

---

### Baseline pin

`origin/main` @ **`539c4440`** · pinned 2026-09-01 · re-verified identical at branch creation 2026-09-02. Every count in this plan is measured against this pin and is **not durable** — re-measure at Stage 9 Phase A6.5/A6.6 and at Stage 12 pre-merge per audit-baseline discipline.

### Domain-practice label

```
domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-01, domain: governance }
```

Sourcing-exempt (**Form X**, verbatim): every write path is an internal pmo-platform artifact. Dominant domain **`governance`**; secondary domain **`software`** for `release/tools/automated-closeout.sh`, `release/tools/tests/test_spoke_run_directory.sh` and #6596's two scripts `core/skills/finops-usage-extractor/scripts/rollup-attribution.sh` and `core/skills/finops-usage-extractor/scripts/estimate-usage.sh`, whose changes are executable shell and whose design-review resolves against the software guide rather than the governance one.

### Stamp manifest — recorded N/A, evidenced

`{{RELEASE_VERSION}}` stamp manifest: **N/A — version-less release; no version key is claimed, so `claim-version.sh --verify-stamp` has no operand.** Corroborated rather than asserted: `{{RELEASE_VERSION}}` occurs **0** times across all **8** plans in `release/releases/plans/_unversioned/`; control arm on the same instrument and the same token over the adjacent versioned plan directories (**144** files) returns **4 occurrences**. The control fires, so the zero is a real negative and not a rejected pattern.

---

### Corrections Carried Into Commit 0

The Stage-4 plan comment is superseded on six points. Each correction is recorded with the evidence that overturned the original claim, so a reader can reproduce the reversal rather than take it on trust.

| # | Original claim | Corrected record | Warrant |
|---|---|---|---|
| **1** | `SKILL.md` gate-armed denominator **513 files / 468 carrying the marker** | **57 tracked files / 52 carrying `skill_discipline_migrated_v10_2: true`** | The original probe walked the filesystem and swept `.claude/worktrees/` mirrors. Re-run over `git ls-files`: denominator **57**, sensitivity arm (marker present) **52** — non-zero, so the detector fires; specificity arm (a bogus `v99_9` marker) **0**; mirror control (tracked paths under `.claude/worktrees/`) **0**, which is why a filesystem walk and a tracked walk could differ by an order of magnitude. The verdict — the gate is armed on `release/skills/release-hub/SKILL.md` — is unaffected. |
| **2** | **CIAC-2** graded against a two-value floored/unfloored classification | **CIAC-2 amended (D8).** The floored arm is supplied two ways: a real tracked path (`core/governance/OPERATIONS.md`) and a real-history arm (`2351582c^` carried `*/SKILL.md`; `main` does not). Expected verdicts: **#5833 `sanctioned-session-required`, #5084 `sanctioned-session-required`, #5505 `sanctioned-session-required`** — all three original cards are gated. The `unconstrained` arm sources from **two** late-add witnesses — **#6597** and **#6596** — not one. | The original CIAC-2 expected #5084 and #5505 `unconstrained`; D5 reclassified #5084 and D11 reclassified #5505, leaving no `unconstrained` witness among the original three. A three-outcome classification graded against a population with only one outcome present is not a fixture. **Updated at #6596's Stage-6 correction:** #6596 is `unconstrained` on the three-conjunct determination (§ Stage Applicability Matrix), so the arm has a second witness. This is a genuine strengthening, not bookkeeping — an arm resting on a single card is vacated by any later reclassification of that one card, which is precisely how the arm came to need a late add in the first place. The two witnesses also fail the conjunction at *different* conjuncts: #6597's change set matches no scope path at all, while #6596 matches the scope regex and fails on the absent arming key. A classifier that got the second case wrong by reading only the first conjunct would still pass against #6597 alone. |
| **3** | *(absent — no CIAC covered the #5505 × #6599 predicate collision)* | **CIAC-4 added.** The contested `hub-spoke-bridge.md` step states **one** predicate after #5505's EDIT 5 and #6599's EDIT 4 both land, with a firing control arm. | Operator decision D10 knowingly accepted a predicate collision between #5505's EDIT 5 and #6599's home (3) in one region of one branch, mitigated by design rather than by separation. An accepted collision with no grading criterion is an unmeasured mitigation. |
| **4** | Contention Map modelled **three** cards and recorded **zero open PRs** | **Contention Map amended** to model the four D7 late adds (#6596, #6597, #6598, #6599) **and** live draft PR **#6626**, which modifies `release/references/pipeline/stage-13-close.md` (+5 −1) — #5084's primary surface. | The zero-open-PR reading was pinned to `539c4440` / 2026-09-01 and was explicitly flagged transiently-empty. Re-measured 2026-09-02: **two** open draft PRs. #6626 overlaps; #6621 (`release/kit-unit-and-selection`) was checked against every surface in this release's change set and returns no overlap. |
| **5** | `core/specs/autonomy-tiers.md` listed under **read-only inputs** ("referenced, not modified") | **Moved to the unconditional change set as `edit`.** | Late-add **#6597** writes the file: it states the governed set twice, non-identically, one list ending in `etc.`. The read-only classification was correct for #5505, which is the card the row was authored against; it is wrong for the release. A read-only row is excluded from the delivery obligation set, so leaving it there would have made a delivered edit invisible to the matrix. |
| **6** | **#6596 AC1** as written: *"fix all three `v[0-9]` sites"* | **All three reviewed and dispositioned — by literal site, 1 updated and 2 preserved, plus 1 sibling arm added.** | AC1's premise is wrong. Two of the three `v[0-9]` sites are the `test` and `capture` limbs of one **branch predicate** that parses version-keyed branch names — **435 distinct** across `main`'s merge history (an append-only population, so a re-measure reads higher); "fixing" it would break working behaviour to satisfy a uniform sweep. The AC's *intent* — no run key is silently dropped — is served by reviewing every site and recording its disposition, which is what ships. |

---

### Release Class declaration

**Class: `novel`.** Promoted `routine → novel` at the Stage-5 exit gate, operator decision **D17**, 2026-09-01.

| Trigger | Fired? | Basis |
|---|---|---|
| `novel` (a) — ≥1 new reference doc, schema, or skill | **No** | Never fired at any point. All eight designs (seven cards plus the E-13 addendum) chose extend-an-existing-seam. The only file adds in the release are four test fixtures on #6596, which trigger (a) does not name. The operator's D2 pre-authorization for a trigger-(a) promotion went **unexercised**. |
| `novel` (b) — ≥1 D-class decision | Recurring only | Recurring-D entries do not fire the trigger. |
| `novel` (c) — ≥1 Stage-5 ADR | **FIRES** | The operator elected to create the ADR recording #5505's substrate selection — tracked as **#6617**. |
| `cross-cutting` (a)/(b)/(c) | No | Does not fire on any limb. |
| `hotfix` | No | No P1/P2 raised against a deployed release. |

**Differentiation posture, as amended:** Engagement density **Light** · Stage 9 review depth **Deep** *(was Standard)* · Stage 5 activation bias `SKIP-where-trivial` *(spent — reached no card)* · Stage 13 outcome-window **30-day**.

**One ADR deliberately omitted.** #6596's spoke drafted an ADR body and then recommended against creating it: its work is conformance to the already-ratified ADR-092, not new architecture, and an ADR for conformance would set a precedent that every conformance card owes one. The body remains recorded on that card's Stage-5 sub-task as durable design rationale.

**The ADR carries no number.** Operator decision D27 deferred number allocation to Stage 12 after three concurrent releases collided on 170/171. Every reference in this plan and in the PR cites **#6617**; no `ADR-17x` form is authored anywhere in this release.

### Size and band override

| | |
|---|---|
| Original bundle (#5833, #5505, #5084) | 16 pts |
| D7 late adds (#6596 S/2, #6597 S/2, #6598 M/4, #6599 M/4) | +12 |
| **D13 re-derivation** | **28 effective** against band **15–25** — breached, override accepted |
| D26 — #5505 packaging cascade (+2) | +2 |
| **D26 re-derivation** | **30 effective** against band **15–25** — override **extended** |

The D26 rows are structural, not discretionary: Check 7 (skill-package content-freshness) is always-enforce, so a rostered skill's package and its `.sha256` sidecar must be rebuilt and committed the moment its `SKILL.md` is edited. Declining them would not reduce scope; it would fail CI pre-merge.

**Risk carried by the override:**

1. **Coupling across seven cards on one branch.** Topology is D-C SINGLE. #5505 × #6599 and #5833 × #6598 both contend on `release/references/how-to/hub-spoke-bridge.md`. Merge ordering is load-bearing — #6599's EDIT 4 depends on #5505's EDIT 5 having landed, and carries a stop-and-surface rule if the anchor string is absent.
2. **Three of seven cards are `sanctioned-session-required`.** The deployed gate is in `warn` mode while the repo source reads `enforce`, and the hook scripts are byte-identical. This is **two switches from binding, not one**: `block-skill-direct-edit.sh` resolves precedence `bypass → master-activation → .mode → rule`, and the `workflow`-class master-activation gate runs at layer 2 *before* the `.mode` read, so syncing the sidecar is necessary but not sufficient. Treat a missing sanctioned session as a discipline violation review will catch, not one the control will.
3. **A knowingly accepted predicate collision (D10)** between #5505's EDIT 5 and #6599's home (3), mitigated by design rather than by separation, and graded at Stage 9 by **CIAC-4**.
4. **The late adds were absent from the Stage-4 File Change Matrix and Contention Map.** Both are amended in this file rather than read stale at Stage 9.

---

### Implementation Sequence

**Order: #5833 → #5505 → #5084 → #6596 → #6597 → #6598 → #6599.** P0 fully-serial: the next card waits until the prior commit lands on the release branch.

| Seq | Card | Pts | Why this position |
|---|---|---|---|
| 1 | **#5833** | 4 | The first gated card and the author of Commit 0. Leading with it pays the sanctioned-session overhead once on a branch with no prior commits to rebase, and surfaces a gate failure at the first spoke rather than the second. *(The rationale originally recorded — "it bounds the staging surface the other two write into" — was withdrawn at Stage 4: #5505 and #5084 edit corpus files and consume no hub staging at build time. The order is unchanged; only its warrant is.)* |
| 2 | **#5505** | 8+2 | Largest card and the widest design surface. Sequencing it second gives a landed #5833 to read as a concrete fixture rather than a planned one. Carries the D26 packaging cascade. |
| 3 | **#5084** | 4 | Fully specified. Its `hub-spoke-bridge.md` hunks sit at the file's tail, farthest from the other two, so it inherits the least anchor drift. Placing the only `bug` last keeps its regression arm adjacent to Stage 7. |
| 4 | **#6596** | 2 | FinOps rollup attribution filters run keys to `v[0-9]*`, dropping every slug-keyed hub-state directory. Independent surface. |
| 5 | **#6597** | 2 | `autonomy-tiers.md` states the governed set twice, non-identically, one list ending in `etc.` Supplies CIAC-2's `unconstrained` classification arm. |
| 6 | **#6598** | 4 | Hub-state run key spelled two ways across the corpus. Owns the `hub-state/README.md` "First emit" bullet (D14/D29). |
| 7 | **#6599** | 4 | Agent-editability remediation homes (2) and (3). **Sequenced last by dependency**: its EDIT 4 requires #5505's EDIT 5 to have landed, and carries a stop-and-surface rule if the anchor string is absent. |

**Branch topology: D-C SINGLE.** One release branch, one PR, seven delivery slices. Zero hard dependency edges among the original three means no early-merge value; seven cards sharing `hub-spoke-bridge.md` makes per-issue PRs a merge-conflict generator rather than a parallelism win.

---

### Dependency Graph

**Zero hard dependency edges among the original three cards** — native `blocked-by` empty on #5833, #5505, #5084; the body-regex predicate (`blocked by|depends on|requires|after #N`) returns zero over all three. Sensitivity arm: the same relationship reader returns a non-empty `parent` field on #5084, so it is not returning a blanket null.

**One hard authoring edge among the late adds:**

```
#5505 (EDIT 5) ──[anchor-string precedence]──▶ #6599 (EDIT 4)
```

#6599's EDIT 4 depends on #5505's EDIT 5 having landed. It carries a stop-and-surface rule rather than a fallback: if the anchor string is absent at branch tip, the spoke stops. This is why #6599 is sequenced last and #5505 second.

**Soft edges (real, not build-blocking):**

| Edge | Direction | Kind | Consequence |
|---|---|---|---|
| **E1** | #5833 → #5505, #5084, #6598 | File contention on `hub-spoke-bridge.md` | Region-disjoint. Serializes automatically under D-C SINGLE + P0. |
| **E2** | #5833 → #5505 | Fixture | #5505's AC1 requires a fixture milestone carrying one floored and one unfloored card. Satisfied by this plan's own classification. Graded as **CIAC-2**. |
| **E3** | #5833 → #6598 | Scope boundary (D14/D29) | The `hub-state/README.md` "First emit" bullet belongs to #6598; #5833 owns the two `hub-spoke-bridge.md` run-key sites. Neither card touches the other's line. |

---

### Stage Applicability Matrix

**Agent-editability read** — the three-outcome dimension #5505 ships, applied to this release's own cards.

| Card | Tier-0 `BLOCK-AUTONOMY-001` ∩ | Skill-gate `BLOCK-SKILL-EDIT-*` ∩ | Editability class | Execution path |
|---|---|---|---|---|
| **#5833** | ∅ | **2 paths** — `release/skills/release-hub/SKILL.md` (`-001`), `release/skills/release-hub/references/spoke-launch.md` (`-002`) | **sanctioned-session-required** | Agent-executed inside a live `pmo-skill-editor` Mode A session. Never `CLAUDE_HOOK_BYPASS=1`. |
| **#5505** | ∅ | **≥1 path** under `release/skills/release-planner/` (D11) | **sanctioned-session-required** | Same. |
| **#5084** | ∅ | **≥1 path** under `release/skills/release-executor/` (D5) | **sanctioned-session-required** | Same. |
| **#6596** | ∅ | **1 path in scope · 0 gated** — `core/skills/finops-usage-extractor/SKILL.md` matches `SKILL_SCOPE_RE`, but that `SKILL.md` does **not** carry the arming key `skill_discipline_migrated_v10_2`, so the gate's conjunction is false | **unconstrained** | Ordinary Engineering spoke. Second `unconstrained` witness for CIAC-2. |
| **#6597** | ∅ | ∅ | **unconstrained** | Ordinary Engineering spoke. Supplies CIAC-2's `unconstrained` arm. |
| **#6598** | ∅ | ∅ | **unconstrained** | Ordinary Engineering spoke. |
| **#6599** | ∅ | ∅ | **unconstrained** | Ordinary Engineering spoke. |

**#6596's row carries per-path evidence rather than a bare `∅`; its class is unchanged from the Stage-4 plan. The other six rows are unchanged.** The card body reads *"Ungated — `scripts/` does not match `SKILL_SCOPE_RE`"*, which is true of `scripts/` but became incomplete when Stage 5 added `core/skills/finops-usage-extractor/SKILL.md` to the change set — so the original `∅` was **right in its verdict and wrong in its evidence**. The row now names the in-scope path and the conjunct that fails, so a reader sees *why* the card is unconstrained instead of assuming no intersection exists.

**The determination is a three-way conjunction, and reading only the first conjunct is what makes this row easy to get wrong.** Per `stage-04-planning.md` § *Sanctioned-session gate*, a write-set path is gated when it matches the scope regex **and** its owning skill's `SKILL.md` carries the arming key **and** the skill is absent from the exemption list. Measured against `core/hooks/block-skill-direct-edit.sh` at the branch tip:

| Conjunct | Source | Result |
|---|---|---|
| matches `SKILL_SCOPE_RE` | hook line assigning `SKILL_SCOPE_RE` | **TRUE** — `core/skills/finops-usage-extractor/SKILL.md` matches; both scripts, all fixture paths, both corpus docs and the package artefact do not |
| owning `SKILL.md` carries the arming key `skill_discipline_migrated_v10_2` | the hook's own arming grep, whose failure branch reads `exit 0  # not yet gated` | **FALSE** — the subject is one of exactly **5 of 56** in-scope `SKILL.md` files without it |
| skill absent from the exemption list | `EXEMPTION_LIST`, which resolves against the **deployed** hook directory | **not determining** — the conjunction already fails at conjunct 2, so this was not resolved and is not claimed as verified |

**Conjunction false ⇒ `unconstrained`.**

*Probe record.* Denominator **56** in-scope tracked `SKILL.md`; sensitivity **51** carry the arming key; **5** do not; specificity arm on a bogus `v99_9` key **0**. Note the denominator trap: **57** `SKILL.md` files are tracked, but `operations/skills/_templates/system-specialist/SKILL.md` sits one directory deeper than `[^/]+/SKILL.md` admits and is therefore out of scope — the gating denominator is 56, not 57. Scope sensitivity arm `release/skills/release-hub/SKILL.md` → matched; specificity arm `README.md` → no match.

**Warn mode is not the reason.** The dimension is explicit that the gate's mode changes only whether a violation is refused or logged, never whether a path is gated — a control in warn mode still yields `sanctioned-session-required`. This card is unconstrained because the **arming key is absent**, which is a different fact and the only one load-bearing here.

**CIAC-2 gains a witness rather than losing one** — see correction 2.

`block-skill-direct-edit.sh` is a **routing requirement, not a hard block**: every `apply_block` call is reached from a sentinel condition, and with a valid sentinel the hook falls through to `exit 0`. Contrast `BLOCK-AUTONOMY-001`, which calls `always_block` and has no sanctioned path. The two controls differ in kind, not in degree.

**Stage applicability, per stage:**

| Stage | Verdict | Rationale for any non-APPLY |
|---|---|---|
| 5 Solutioning | **APPLY** — complete | 7 designs, 8 adversarial reviews, 6 remediation passes, ~60 findings resolved, 15 disputed with evidence and upheld, no selected mechanism overturned. |
| 6 Engineering | **APPLY** | Three cards gated. |
| 7 Dev Testing | **APPLY (mandatory)** | No skip is available on any card. #5084's defining property is that its own verification probe confirms the bug rather than catching it. |
| 8 QA / Acceptance | **APPLY** | Per-criterion verdicts on every card's AC set. |
| 9 Plan Review | **APPLY — depth Deep** | Class `novel` per D17. |
| 10 Dry Run | **COMPRESSED** | Claude Code path — the PR diff is the dry-run gate. |
| 11 Snapshot | **COMPRESSED** | Git history is the snapshot set. |
| 12 Execute | **APPLY** | Phase B3 atomic version-claim is **N/A by construction** — no version key is claimed, `claim-version.sh` does not run, no signed version tag is produced. Recorded as N/A rather than omitted. **The ADR number is allocated here** (D27). |
| 13 Close | **APPLY** | Phase B5.7 `.version` stamp runs **SKIP** on a version-less release, so #5084's AC4 cannot be evidenced by this release's own close-out — it requires a constructed out-of-order fixture. |

---

### File Change Matrix

Machine-readable per the declared-vs-delivered authoring contract — one path per line, columnar-in-fence, `add | edit | delete`.

```
# ── Unconditional change set ──────────────────────────────────────────
release/references/how-to/hub-spoke-bridge.md                      edit
release/releases/hub-state/README.md                               edit
core/standards/gate-efficacy-standard.md                           edit
release/tools/tests/test_spoke_run_directory.sh                    edit
release/skills/release-hub/SKILL.md                                edit
release/skills/release-hub/references/spoke-launch.md              edit
packages/release-hub.skill                                         edit
packages/release-hub.skill.sha256                                  edit
release/references/pipeline/stage-04-planning.md                   edit
release/skills/release-planner/SKILL.md                            edit
release/skills/release-planner/references/release-plan-template.md edit
packages/release-planner.skill                                     edit
packages/release-planner.skill.sha256                              edit
release/references/pipeline/stage-13-close.md                      edit
release/tools/automated-closeout.sh                                edit
release/skills/release-executor/SKILL.md                           edit
packages/release-executor.skill                                    edit
packages/release-executor.skill.sha256                             edit
core/specs/autonomy-tiers.md                                       edit
core/skills/finops-usage-extractor/scripts/rollup-attribution.sh   edit
core/skills/finops-usage-extractor/scripts/estimate-usage.sh       edit
core/skills/finops-usage-extractor/SKILL.md                        edit
core/standards/finops-attribution-convention.md                    edit
core/schemas/finops-usage-store-schema.md                          edit
core/skills/finops-usage-extractor/test-fixtures/rollup/README.md   edit
core/skills/finops-usage-extractor/test-fixtures/rollup/rollup.expected.json  edit
core/skills/finops-usage-extractor/test-fixtures/rollup/usage.jsonl edit
core/skills/finops-usage-extractor/test-fixtures/estimate/RELEASE_LOG.fixture.md  edit
packages/finops-usage-extractor.skill                              edit
packages/finops-usage-extractor.skill.sha256                       edit
.github/workflows/release-tooling-smoke.yml                        edit
core/deploy/tests/test_version_stamping.sh                         edit
.github/workflows/install-tests.yml                                edit
release/references/standards/release-notes-standard.md             edit
release/references/pipeline/stage-12-execute.md                    edit
release/tools/version-grammar.sh                                   edit
release/references/standards/version-grammar.md                    edit
core/standards/hub-action-tracking.md                              edit
core/standards/public-repo-vs-operator-instance-taxonomy.md        edit
docs/release-record-keeping.md                                     edit
release/releases/README.md                                         edit
core/deploy/composition-surface-manifest.sh                        edit
```

```
# ── Read-only inputs (excluded from the delivery obligation set) ──────
core/hooks/block-autonomy-ceiling.sh                               READ
core/hooks/block-skill-direct-edit.sh                              READ
core/standards/analysis-workspace-standard.md                      READ
core/standards/hub-session-continuity.md                           READ
core/standards/depersonalization-spec.md                           READ
release/references/specs/release-class-taxonomy.md                 READ
release/references/standards/quota-budget-protocol.md              READ
```

```
# ── CONDITIONAL ───────────────────────────────────────────────────────
PROMOTED:6596-fixtures  core/skills/finops-usage-extractor/test-fixtures/rollup/hub-state/synthetic-slug-release/sessions.md      add
PROMOTED:6596-fixtures  core/skills/finops-usage-extractor/test-fixtures/rollup/hub-state/synthetic-collision-peer/sessions.md   add
PROMOTED:6596-fixtures  core/skills/finops-usage-extractor/test-fixtures/rollup/hub-state/synthetic-malformed/sessions.md        add
PROMOTED:6596-fixtures  core/skills/finops-usage-extractor/test-fixtures/rollup/hub-state/synthetic-managed-fence/sessions.md    add
```

**Row-set notes.**

- **`core/specs/autonomy-tiers.md` moved from READ to `edit`** — correction 5. It was correctly read-only for #5505 ("referenced, not modified"), and that is the card the original row was authored against. Late-add #6597 writes it, so the release-scoped intent is `edit`.
- **The four `packages/*.skill` + `.sha256` pairs are structural obligations, not discretionary rows.** Check 7 / the `skill-package-freshness` CI gate hashes every file in a packaged tree; editing a rostered skill's `SKILL.md` or `references/` changes the content hash by construction. Each card that edits a rostered skill rebuilds and commits its package and sidecar **in this PR**. Unrebuilt, the release merges red. **The fourth pair — `packages/finops-usage-extractor.skill` — was added at #6596's Stage-6 commit.** That cascade is wider than the other three: the packaged tree contains both edited scripts, `SKILL.md` **and the whole `test-fixtures/rollup/` tree**, so seven of this card's paths cascade and the four fixture adds become new archive entries. Measured with the resolver's documented **stdin** form (`printf '%s\n' <path> | build-skill-packages.sh --skills-for-paths`); passing a path as an argument returns empty for every input including a known-cascading control, which reads as "no cascade" while measuring nothing.
- **The two Stage-4 CONDITIONAL `add` rows did not fire.** `CONDITIONAL:5833-distinct-staging-standard` resolved to *extend an existing seam*, not a new standard; `CONDITIONAL:5505-derivation-substrate` resolved without a new substrate file. Neither is promoted, and neither needs a Deviation-Log row.
- **`CONDITIONAL:6596-fixture-pair` fired, and was re-pointed rather than promoted as written.** It named `release/tools/tests/fixtures/` — a real directory, but not one this card touches; the design places every fixture under `core/skills/finops-usage-extractor/test-fixtures/rollup/hub-state/`. Promoting it verbatim would have declared a path the card never writes while leaving the paths it does write undeclared. It resolved to **four** fixture adds, not a pair: the slug-keyed run directory, its collision peer, a malformed-table fixture, and the managed-section-fence fixture that D39 added. These remain the release's **only** file adds.
- **Each following card's spoke amends its own rows at its commit.** #5505 carries a second gated path under `release/skills/release-planner/` (D11/D26) whose concrete name is set by that card's spoke; it is not guessed here. A row promoted at a later commit carries its concrete path in that commit, per the contract.
- **New-executable companion obligation: N/A.** The matrix carries zero `add` rows for `*.sh`; the only added paths are test fixtures. No `core/config/allowlists/script-execution-allowlist.txt` companion row is owed.

---

### Contention Map

Probed by **full path**, never basename — a basename probe on `SKILL.md` matches every skill in the repo and inflates the edge set.

**Within-release contention.**

| File | Cards | Regions |
|---|---|---|
| `release/references/how-to/hub-spoke-bridge.md` | #5833, #5505, #5084, #6598, #6599 | **#5505** Procedures 1 and 3 · **#5833** § For the Hub Agent, the temp-file idiom bullet, § Run-Directory Discipline (inside the fence), Procedure 7 Step 6, and two run-key sites · **#5084** the file tail · **#6598** run-key sweep sites · **#6599** the EDIT-4 region, downstream of #5505's EDIT 5 |
| `release/references/pipeline/stage-04-planning.md` | #5505, #6599 | Phase-A editability dimension and its remediation homes |
| `core/specs/autonomy-tiers.md` | #6597 | Sole writer |

Under D-C SINGLE + P0 serial this resolves by sequencing. The residual is anchor drift, not conflict — which is why **CIAC-3** grades reference-anchor form rather than line stability.

**Cross-milestone contention (declared-edge, full-path).**

| Surface | This milestone | Sibling milestones | Class |
|---|---|---|---|
| `release/skills/release-hub/SKILL.md` | #5833 | `hub-emits-state-gates-read` [#5232, #5522] · `work-item-ownership-and-closure` [#5277] · `authoring-conventions-enforced-or-retired` [#4022] | Narrow — serialization-relevant |
| `release/references/pipeline/stage-04-planning.md` | #5505, #6599 | `work-item-ownership-and-closure` [#4201] · `authoring-conventions-checkable-whole-population` [#5824] | Narrow — serialization-relevant |
| `release/skills/release-hub/references/spoke-launch.md` | #5833 | none milestoned — 4 unmilestoned: #5899, #6185, #6237, #6425 | Adjacency only |
| `release/references/how-to/hub-spoke-bridge.md` | 5 cards | 10 milestones | Hot-path — Tier-B soft; does not drive grouping |
| `release/references/pipeline/stage-13-close.md` | #5084 | 11 milestones | Hot-path — Tier-B soft |
| `release/tools/automated-closeout.sh` | #5084 | 8 milestones | Hot-path — Tier-B soft |

`work-item-ownership-and-closure` remains the only sibling contending on both narrow surfaces.

**Cross-PR Overlap Audit — re-measured 2026-09-02, and the Stage-4 zero no longer holds.**

Stage 4 recorded **0 open PRs repo-wide**, pinned to `539c4440` / 2026-09-01 and explicitly flagged transiently-empty. Re-measured at branch creation: **2 open PRs, both draft.**

| PR | Head | State | Overlap with this release's change set |
|---|---|---|---|
| **#6626** | `release/adr-corpus-status-integrity` | draft | **YES** — modifies `release/references/pipeline/stage-13-close.md` (**+5 −1**), which is #5084's primary surface. |
| #6621 | `release/kit-unit-and-selection` | draft | **None.** Checked against every path in the unconditional change set; zero intersection. |

**Consequence, and it is a real serialization point, not a note.** #5084 edits `stage-13-close.md`; so does #6626. Whichever merges first, the other re-baselines. Because #6626 is a **draft**, it is invisible to any settled-state probe (merged-state or claimed-set), which is precisely the population the in-flight roster exists to record. **Re-check #6626's state before #5084's spoke writes `stage-13-close.md`, and again at Stage 12 pre-merge.**

**In-Flight Release Roster.**

**Measured at:** `539c4440` · `2026-09-02` · **Population:** n=2 sibling(s)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `adr-corpus-status-integrity` | `#6626` | *(draft head)* | `UNRESOLVABLE` | — | `UNRESOLVABLE` | `release/references/pipeline/stage-13-close.md` |
| `kit-unit-and-selection` | `#6621` | *(draft head)* | `UNRESOLVABLE` | — | `UNRESOLVABLE` | — |

Both siblings declare no bump-class, so both render `UNRESOLVABLE` in the bump-class and recomputed columns rather than a blank — an unresolvable slot is an unknown, not an absence. This release claims no version slot, so it contributes no version-collision token and no Tier-S serialization edge arises from version contention; the #6626 edge is **file contention**, which the roster's `EDITSET ∩ FCM` column carries.

---

### Verification Plan

**AC baseline** — per-issue acceptance-criterion counts as read at plan time, taken at `539c4440`: #5833 **6** · #5505 **4** · #5084 **4** · #6596 **3** · #6597 **3** · #6598 **3** · #6599 **3**. A count that no longer matches its baseline is a mechanical signal to re-bind, not a verdict.

**Re-bind recorded — #6596: 3 → 6.** Its acceptance criteria were replaced wholesale by the Phase A6.5 adversarial review (the card body opens `⚠ ACCEPTANCE CRITERIA REPLACED`), not merely extended: three of the original five were defective — one vacuous, one using the wrong denominator, and one admitting a metric that would certify the exact failure the card exists to close. Grade against **AC1–AC6**, and note that **AC1's literal wording must not gate acceptance** (correction 6 / deviation (f)).

**Re-bind recorded — #6598: 3 → 4.** Its card body carries **AC1–AC4**; the plan-time baseline read 3. This is a count change with no wholesale replacement (unlike #6596), so the mechanical signal is satisfied by re-binding to the live set. Grade against **AC1–AC4**.

**Per-issue verification — #5833** (the card landing at this commit; each following card's spoke extends this table with its own rows).

**Rows for the remaining five cards were added at Stage 7 remediation, not by their own spokes.** #5505, #5084, #6596, #6597 and #6598 each carried the row-authoring obligation and none discharged it, so Stage 8 had no declared per-AC method for five of seven cards — a Blocker raised at Stage 7 dev testing. The rows below are authored against **what each card actually shipped at branch tip**, not against what its design proposed. Two carry an explicit negative finding rather than a method: **#5505 AC4 limb 2** has no fixture and is graded by inspection, and **#6598 AC4**'s machine-consumer limb is discharged jointly with #6596. An honest "no declared method" is recorded where that is the true state; no method is named that was not read at branch tip.

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #5833 | AC-1 | Read § Run-Directory Discipline in `release/references/how-to/hub-spoke-bridge.md`; confirm a `**Scope —**` paragraph states whether the hub is in scope | Heading unchanged; the parenthetical is no longer the only scope signal |
| #5833 | AC-2 | Locate the naming clause in § Hub Staging Discipline; confirm it resolves to one path, and that `hub-state/README.md` and the hub-session-continuity standard agree on the run key | One determinate location, not a choice |
| #5833 | AC-3 | Inspect every added path literal | All `<OPERATOR_INSTANCE_HUB_STATE_PATH>`-rooted (registered-token form). No absolute path, no username segment, no bare relative operator-instance path |
| #5833 | AC-4 | Read the lifecycle clause | End condition names **Procedure 7 Step 6, orphan-state cleanup, after Milestone close** — a stage and an event, not a duration or a judgement call |
| #5833 | AC-5 | Read Mode O in `release/skills/release-hub/SKILL.md` | Staging location and cleanup point both present and cited to the governing reference |
| #5833 | AC-6 | Read the deliberate-retention clause | Retained content goes to the operator's own area — a location distinct from the run staging directory · control: the same read against `539c4440` → **no such clause** (observed absence, so a "present" verdict is discriminating) |
| #6599 | AC1 | Read § D-3 and § D-4 of the Stage-5 design **as amended by the Stage-5 Remediation**, which supersedes the original § Output for Stage 6 | Home (2): 5 candidates / 3 bands / 3 eliminated. Home (3): 5 / 2 bands / 2 eliminated / 3 scored incl. the null candidate. The rejected-candidate warrant is the **replaced** one and the eliminated-candidate kill-reason is the **struck-limb** version |
| #6599 | AC2 | Read § D-2 | Home (2) **composes**; home (3) **composes, with one deliberate revision** — the revision named, not implied |
| #6599 | AC3 — **structural arm** | For EDITs 1, 3, 5, 6, assert each quoted anchor is present in `origin/main@539c4440` | **1 occurrence each** · *control: three bogus-token variants of the same anchors → 0, so the ones discriminate* |
| #6599 | AC3 — **dynamic arm** | For EDITs 2 and 4, assert each anchor is **absent** at `origin/main@539c4440` **and** present on the release branch immediately before that edit ran | **0 at `539c4440`** (the discriminating control) and **1 at the branch tip** for both. An edit applied with its anchor absent and no stop-and-surface recorded is an AC3 failure |
| #6599 | AC4 — token arm | Scan the merged file for editability class tokens | Exactly the three home (1) ships, plus the transport state `unresolved` with exactly the two reason strings EDIT 2 defines. **No fourth class token** |
| #6599 | AC4 — derivation arm | Scan the merged file's added text for governance-path lists / Tier-0 path enumerations | **0** — every reference is to `§ 5.9` · *control, same instrument over `core/hooks/block-autonomy-ceiling.sh` → non-zero, so the zero discriminates* |
| #6599 | AC4 — premise arm | Read § Decisions | Two premise rejections recorded rather than resolved silently — including the card's own home-(3) predicate |
| #6599 | AC3-b | Scan the release diff's added lines for `Procedure\s*\d+[, ]+\s*Step\s*\d+` and bare `Step \d+`, **net of text re-emitted by a whole-line replacement** | **0 net-new.** Grade on the file's total ordinal population (tip → merged), not the raw added-line set: a whole-line replacement re-emits pre-existing ordinals as added lines and reads as a false positive · *control, same instrument on the merged file → non-zero, so the zero discriminates* |
| #5505 | AC1 | Read `### Agent-Editability Read` in `release/references/pipeline/stage-04-planning.md` § 5.9, then this plan's own § Stage Applicability Matrix as the live fixture | The spec rosters the H3 and its seven-column table (`Card` / `Write-set path` / `Tier-0 ∩` / `Skill-gate ∩` / `Path class` / `Card class` / `Execution path`); this plan carries all seven cards classified — **3 `sanctioned-session-required`, 4 `unconstrained`** — so a floored and an unfloored witness are both present in one fixture. Graded jointly as **CIAC-2** |
| #5505 | AC2 | Read § 5.9's *"The set is read, never restated"* paragraph and the **Derivation** block of the `### Agent-Editability Read` template | The spec **names no governance path**. The Tier-0 floor is cited to `core/hooks/block-autonomy-ceiling.sh` (the `always_block "BLOCK-AUTONOMY-001"` `case` arms, quoted at a read SHA) and the gate to `core/hooks/block-skill-direct-edit.sh` (`SKILL_SCOPE_RE` + arming key + exemption list). Probe: inline governance-path enumerations in § 5.9 → **0** · *control, same instrument over `block-autonomy-ceiling.sh` → non-zero, so the zero discriminates* |
| #5505 | AC3 — specificity arm | Read the `Tier-0 ∩` and `Skill-gate ∩` columns for the four late adds in § Stage Applicability Matrix | **4 of 7 cards unflagged** → `unconstrained`. The check discriminates rather than warning on everything. #6596 is the load-bearing case: it fails at **conjunct 2** (arming key absent) while matching the scope regex, so a classifier reading only the first conjunct would still pass against #6597 alone and fail here |
| #5505 | AC4 | **Two limbs, and only the first has a declared method.** Limb 1 — read the `Execution path` column for each floored card. Limb 2 — the AC's *"a fixture asserts the output never recommends setting the hook bypass"*: scan the three delivered #5505 surfaces for the bypass token | Limb 1: every floored row reads *"Agent-executed inside a live `pmo-skill-editor` Mode A session. Never `CLAUDE_HOOK_BYPASS=1`"* — an operator-execution path. Limb 2: **no such fixture ships.** The token occurs **0** times across `stage-04-planning.md`, `release-planner/SKILL.md` and `release-plan-template.md` · *control: 72 files repo-wide carry it, so the zero is a real negative*. **No declared method for limb 2 — graded by inspection; Stage 8 must not read it as mechanically asserted** |
| #5084 | AC1 | Read the stamp condition in **both** surfaces — `release/references/pipeline/stage-13-close.md` Phase B5.7 (spec) and `phase_bump_version()` in `release/tools/automated-closeout.sh` (enforcer) | Both state the condition as **monotonicity**, not idempotency. Probe: `monoton*` → **4** in the spec, **12** in the enforcer — both non-zero, so neither surface still carries the old wording |
| #5084 | AC2 | Read the three `.version` verification sites in `release/references/how-to/hub-spoke-bridge.md` (lines **2368**, **2415**, **2470**) | All three resolve through `version_stamp_state` in the SSOT `release/tools/version-grammar.sh` and assert `>= v<X.Y>`. Probe: `grep -qx` — the string-equality form the card names — → **0** in the bridge · *control, the same needle in `release/tools/tests/test_spoke_run_directory.sh` → 4, so the zero discriminates.* Fixing one site and leaving two would leave two sites confirming the bug; the count is why three are named |
| #5084 | AC3 | Read the Surface-1 create path in `automated-closeout.sh` plus the two remaining construction sites | `gh release create` carries `--latest="$s1_latest"` — **resolved explicitly, never defaulted** — with the value from `version_badge_latest` in the SSOT, which yields false when a higher version is already published |
| #5084 | AC4 | **`core/deploy/tests/test_version_stamping.sh`** — its `M-1`…`M-15` ordered-pair monotonicity arms and `V-1`…`V-3` doc-site predicate arms; CI-wired in `.github/workflows/install-tests.yml`. Companion arms: `automated-closeout.sh --self-test` groups **(c2) MONOTONICITY CANARY** and **(L-1)..(L-7) SURFACE-1 `--latest` RESOLUTION ARMS** | 15 + 3 arms present. Probe: `M-<n>` → **15** distinct, `V-<n>` → **3** distinct · *specificity arm on a bogus `Z-<n>` series → 0*. **This names the constructed out-of-order fixture the closing note below calls for and left unnamed** — the arms are a fixture table, not this release's own close-out, which correctly runs `SKIP` at Phase B5.7 on a version-less release |
| #6596 | AC1 | Read the disposition of all three `v[0-9]` sites across `core/skills/finops-usage-extractor/scripts/rollup-attribution.sh` and `estimate-usage.sh` | **Counted by literal site: 1 updated, 2 preserved**, plus **1 sibling arm added** — the disposition correction 6 records. All three baseline sites sit in `rollup-attribution.sh` at `539c4440`: the hub-state directory-admission filter (line 144) is the one **updated**; the `test` and `capture` limbs (lines 238–239) are the two **preserved**, and those two are the halves of a **single branch predicate** — a predicate-level count of the same disposition reads "1 preserved", which is the reading to state rather than mix. Preserving it was correct: the predicate parses version-keyed branch names, **435 distinct** of which appear across `main`'s merge history (distinct branch names carrying a `vX.Y` key, parsed from merge-commit messages — an append-only population, so a re-measure reads higher, while a *live-heads* count reads near zero and is the wrong instrument). A uniform "fix" would break working behaviour to satisfy a sweep |
| #6596 | AC2 | Read arm ordering in `rollup-attribution.sh --self-test`: the branch-axis arm must evaluate **after** the authored hub-state tier — then **run the reorder mutation** | `shadowing-guard` arm present. **The arm must turn RED on a deliberate reorder.** A green suite after reordering is a failed AC, not a passing one — so Stage 8 must execute the mutation rather than observe green, which is the one way this criterion can be mis-graded as passing |
| #6596 | AC3 | Scan the emitted attribution label form for `milestone:<release-key>` | The work-item key space is widened to `milestone:<release-key>`, so a corrected filter cannot begin emitting a malformed label — a new silent defect of the same family |
| #6596 | AC4 | Read the **attributed-session** count before and after, from the card's Stage-6/7 record — **never** the directory-admission count | Graded on attributed sessions, with a firing sensitivity arm and a specificity arm at zero. A directory-admission metric moving 0 → 9 is **explicitly inadmissible**: it goes green while the tier stays dead, which is the exact failure this card exists to close |
| #6596 | AC5 | Read the card's explicit disposition of the Phase A6.5 zero-benefit finding | The directory axis is recorded as delivering **no measured attribution** — the `worktree`-field precondition is unsatisfied (3,225 records, non-empty `worktree` on **0**) — and the card's value is attributed to the branch-axis arm. **Silence would fail the criterion**; a disposition is present |
| #6596 | AC6 | For every whole-line replacement in the files shared with #6598, assert the anchor was present **at branch tip** when the edit ran, not at `539c4440` | Each replacement carries a stop-and-surface rule; a silent no-op with no surfaced halt is an AC6 failure. Seven named self-test arms back the fixture set: `run-key-sensitivity`, `run-key-specificity`, `shadowing-guard`, `collision-determinism`, `malformed-table-rejection`, `sticky-header-bind`, `legacy-run-key-regression`. **Verify an arm by its `PASS:`/`FAIL:` emission, never by string presence** — `managed-section` and `header-skip` are *mentions*, not arms (`managed-section` occurs in a comment and inside `sticky-header-bind`'s own `FAIL:` string; `header-skip` in a comment only), so a presence probe finds all four names and wrongly reports no problem |
| #6597 | AC1 | Read the three formerly-restating sites in `core/specs/autonomy-tiers.md` — the Tier-0 observable indicator, Boundary Test 4, and Irreducible Human Tasks item 6 | In-file governed-set enumerations go **3 → 0**. Each site states it decides no membership and routes to item 6, so a reader lands on one answer. In-file copies of the authority citations go 3 → 1 (consolidated at item 6, not replicated) |
| #6597 | AC2 | Read each site's reconciliation against the live enforcing set in `core/hooks/block-autonomy-ceiling.sh` | Each names *governed* (item 6 **Source rule**) and *mechanically blocked* (item 6 **Enforcement**) as **two different questions**, asserting no relation between their extents. One difference is **named rather than settled**: the Tier of a write to `PORTFOLIO.md` / `SESSION_STATE.md` is answered inconsistently across those authorities and `memory-architecture.md` § 2, and the indicator says so instead of resolving it. **Known residual** — the `BLOCK-AUTONOMY-001` block comment in the hook still restates a set this spec no longer states; knowingly left (a comment, no parser reads it, no runtime effect) and routed as a follow-on |
| #6597 | AC3 — **two limbs; grade them separately** | **Limb 1 (`etc.` → illustrative):** probe `core/specs/autonomy-tiers.md` for `etc.` and **classify every survivor** rather than reading the bare count. **Limb 2 (*"and the hook is authoritative"*):** read item 6's *Enforcement* clause and assert whether the spec confers authority over the **governed set** on `block-autonomy-ceiling.sh` | **Limb 1 — MET.** The governed-set `etc.` is **removed**: item 6 now *"names the obligation, not its members"* and states the prior enumeration was illustrative and open-ended, with **no closed set derivable** from it or anything else in the document. Probe: `etc.` **3 → 2**, and both survivors are **out of scope** — the file-router folder list (line 80) and the Automation Tier schema-doc list (line 127), neither the governed set. A reviewer grading the count alone will mis-read this as a partial fix. **Limb 2 — NOT MET, deliberately (operator decision D41).** The spec declines to declare the hook authoritative because the hook's **11-arm anchored `case`** (`core/hooks/block-autonomy-ceiling.sh` lines 704–714) **excludes `PORTFOLIO.md` and `SESSION_STATE.md`**, both of which the charter names — so conferring authority would **narrow** the governed set, not settle it. Item 6 instead routes membership to the hook's *registry entry* and states it answers neither question itself. **The conflict is three-way, not two:** `memory-architecture.md` § 2 classes those two files **Tier 2 / auto-write**, the charter's "No ungoverned changes" list implies **Tier 0**, and the hook blocks **neither** — probe: both filenames → **0** lines across the hook · *sensitivity, same instrument: `CLAUDE.md` → **16**, `OPERATIONS.md` → **6**; specificity `ZZPORTFOLIO.md` → **0**, so the zero discriminates*. **Stage 8 must record the not-met verdict together with this reason; a bare PASS on limb 1 loses exactly what D41 exists to preserve** |
| #6598 | AC1 | Enumerate the divergent subset from the 51-file hub-state denominator, with a sensitivity arm that fires and a specificity arm at zero | The enumeration is the card's Stage-6 record. A bare count without both arms does not satisfy this criterion |
| #6598 | AC2 | Read the Evidence-Grounding artifact backing the choice of surviving spelling | **`<milestone-slug>` survives**, chosen against evidence rather than asserted |
| #6598 | AC3 | Read the disposition carried by every consumer found during enumeration | **Six consumers, all dispositioned by rewrite**: `release/releases/hub-state/README.md`, `core/standards/hub-action-tracking.md`, `core/standards/public-repo-vs-operator-instance-taxonomy.md`, `docs/release-record-keeping.md`, `release/releases/README.md`, `core/deploy/composition-surface-manifest.sh` |
| #6598 | AC4 | Post-sweep probe that the live population is reachable under the surviving spelling — **and classify what kind of consumer each rewritten site is** | Reachable. Grading note: every run-key reference in `composition-surface-manifest.sh` is a **comment** (its only CODE lines are three template registrations carrying no run-key filter), so #6598's edit there is a documentation correction, not a filter fix. The one **executable** run-key filter is `rollup-attribution.sh`, corrected under **#6596** — so AC4's machine-consumer limb is discharged **jointly with #6596**, not by #6598 alone. Stage 8 should not credit #6598 with an executable-filter fix it did not make |

**Regression arm (release-wide, runs after every `hub-spoke-bridge.md` hunk — operator decision D6):**

```
bash release/tools/tests/test_spoke_run_directory.sh
```

Baseline at `539c4440`: **`NC-NS-1: 16 passed, 0 failed`** (independently reproduced twice). Expected after #5833's clause arms land: **`NC-NS-1: 19 passed, 0 failed`**. Any drop from the running baseline is a regression introduced by the hunk that preceded it.

**Running baseline advanced to `NC-NS-1: 25 passed, 0 failed`** at the Stage-7 remediation of #5833 F-03. The ungraded packaged copy of the hub-staging clause in `release/skills/release-hub/SKILL.md` gained four arms (**C1–C4**) plus a **C-NEG** deletion-sensitivity arm and its retention control — six additions, all in a new `packaged_arms()` function. The existing nine-arm **A-NEG** control is untouched and still reports **0 survivors** at an unchanged retention figure (3067 of 3138 lines), which is the property that had to survive: an arm added inside `clause_arms()` instead would have passed against the A-NEG-mutated bridge, counted as a survivor, and disabled that control. Grade against **25** from this commit forward; a reading of 19 now indicates the C arms did not run.

**Heading constraint — the one rule that reddens CI if broken.** `test_spoke_run_directory.sh` extracts its section with an **anchored exact-string** `awk` match on `## Run-Directory Discipline (all spokes)`, present in **two** matchers (`extract_section()` and the A-NEG mutation builder). Renaming that heading — the wording, the parenthetical, or one character — empties the extractor and reddens arms A1–A4. The suite is CI-wired with no `continue-on-error`.

**#5084 AC4 cannot be evidenced by this release's own close-out.** Phase B5.7 runs `SKIP` on a version-less release, so the monotonicity predicate this release ships is never executed here. AC4 requires a **constructed out-of-order fixture**. Stage 8 must reject "our close-out passed" as AC4 evidence.

**The constructed fixture is now named** (Stage 7 remediation). It is `core/deploy/tests/test_version_stamping.sh` — the `M-1`…`M-15` ordered-pair monotonicity arms and the `V-1`…`V-3` doc-site predicate arms, CI-wired in `.github/workflows/install-tests.yml`, with `automated-closeout.sh --self-test` groups **(c2) MONOTONICITY CANARY** and **(L-1)..(L-7)** as companions. The foreclosure above stands unchanged — the close-out is still not admissible evidence — but the substitute it called for is no longer unnamed, which is what left AC4 ungradeable.

---

### Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**

- [ ] **CIAC-1 (#5833 × #5505 × #5084 on `release/references/how-to/hub-spoke-bridge.md`):** the merged file simultaneously carries all three cards' edits with no card's region clobbered by a later one — (a) a hub-scope statement on § Run-Directory Discipline, (b) an agent-editability read in Procedure 1 or Procedure 3, and (c) a version-comparison predicate at all three former `grep -qx` sites. *Method:* `python3 -c "import re;t=open('release/references/how-to/hub-spoke-bridge.md').read();i=t.find('## Run-Directory Discipline');print(len(re.findall(r'grep -qx',t)), bool(re.search(r'(?i)hub',t[i:i+3000])))"` — the `grep -qx` count must read **0** and the hub-scope limb **True**; *control: the same count at `539c4440` → **3** (observed non-zero).* *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-2 (#5505 × #5833 × #5084 × #6597 × #6596 on the editability classification) — AMENDED per D8:** the agent-editability read #5505 ships emits **three** outcome values, not two, and classifies this milestone's own cards correctly. Expected verdicts: **#5833, #5084 and #5505 all `sanctioned-session-required`**; the **`unconstrained`** arm carries **two** witnesses, which falsify the gate's three-way conjunction at **different conjuncts** — **#6597** matches no in-scope path at all (**conjunct 1**), while **#6596** matches `SKILL_SCOPE_RE` at `core/skills/finops-usage-extractor/SKILL.md` but that file does not carry the arming key `skill_discipline_migrated_v10_2` (**conjunct 2** — one of exactly **5 of 56** in-scope `SKILL.md` files without it). **Both witnesses are required:** a classifier that evaluates only the scope-regex conjunct passes against #6597 and fails only against #6596, so neither witness alone lets this criterion discriminate. The floored arm is supplied two ways so a single fixture's absence cannot vacate it: a **real tracked path** (`core/governance/OPERATIONS.md`) and a **real-history arm** (`2351582c^` carried `*/SKILL.md`; `main` does not). *Method:* read the shipped classification clause in `release/references/pipeline/stage-04-planning.md`; assert it enumerates three outcomes; hand-apply it to the seven cards and compare against § Stage Applicability Matrix above. *Control: applying the clause to `core/governance/OPERATIONS.md` must return the floored outcome, and to `#6597`'s change set the `unconstrained` outcome — a classifier returning one value for both is not discriminating.* *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-3 (all seven cards on reference-anchor form):** no line added by this release introduces a **new** line-number-form cross-reference to `hub-spoke-bridge.md` — references use section headings or quoted predicates, so the next release's briefs do not inherit the anchor drift this plan already found. *Method:* `git diff origin/main...HEAD -U0 | grep '^+' | grep -cE 'hub-spoke-bridge\.md:[0-9]+'` must read **0**; *control, same instrument same target-class: the same regex over the tracked corpus at `539c4440` → **4 occurrences across 3 files** — observed non-zero, so a zero on the diff means "none added", not "pattern never matches".* *Graded at Stage 9 QC3.5 on the merged PR.*

- [ ] **CIAC-4 (#5505 × #6599 on the contested `hub-spoke-bridge.md` step) — ADDED at Commit 0:** after **both** #5505's EDIT 5 and #6599's EDIT 4 land, the contested step states **exactly one** predicate — not two, and not a merge artefact carrying both. This is the grading criterion for the predicate collision operator decision D10 knowingly accepted and mitigated by design rather than by separation. *Method:* extract the contested step from the merged file and count its stated predicates; the count must read **1**. A count of **2** is the failure this CIAC exists to catch.

  *Control — **RE-PINNED at Stage 6 under operator decision D44**; the authored control had decayed and is withdrawn. It named `539c4440`, but the contested step **does not exist at that revision** (measured: **0** occurrences of the step's leader) — #5505's EDIT 5 is what creates it. The prescribed extraction therefore cannot return 1 there; it can only return the "extractor found nothing" reading the control claimed to exclude. Separately, `539c4440` stopped being the pre-state once #5505 landed on this branch.*

  *Re-pinned to the **operative pre-state** — the release branch tip immediately before #6599's EDIT 4 (`19174ae9`) — and graded on the two literals that **discriminate**. They move in **opposite directions**, so an edit that does nothing cannot satisfy both:*

  | Literal | pre-state `19174ae9` | required post-EDIT-4 | Discriminates? |
  |---|---|---|---|
  | `a brief is generated for every class` | **1** | **0** | **YES** — a 1 after EDIT 4 means the retirement did not land |
  | `renders no refusal of its own` | **0** | **1** | **YES** — a 0 after EDIT 4 means the replacement did not land |
  | `renders no refusal` | 1 | 1 | **NO — do not grade on this limb** |

  *The third limb reads **1** at the pre-state, put there by #5505's EDIT 5 — the very edit #6599 is sequenced behind — so it passes whether or not EDIT 4 runs. Grading on it measures nothing. Both graded limbs read non-zero on one side, so neither is a broken probe.* *Graded at Stage 9 QC3.5 on the merged PR.*

---

### Risk Register

| # | Risk | Sev | Lik | Owner | Mitigation | Reversibility |
|---|---|---|---|---|---|---|
| **R-1** | **Sanctioned-session TTL vs spoke budget.** `SENTINEL_TTL_SECONDS = 1800`, re-checked on every Write/Edit. Three cards edit gated paths. | HIGH | MED | Stage 6 | Invoke `pmo-skill-editor` Mode A **immediately before** the gated writes with no analysis between minting and writing; batch a card's gated edits inside one window; on expiry **re-invoke Mode A**. Never `CLAUDE_HOOK_BYPASS=1`. | CHEAP |
| **R-2** | **The release edits the file that launches its own spokes.** Once #5833's commit lands, a later spoke reading the branch working copy could see modified launch guidance mid-release. | MED | LOW | Hub | `spoke-launch.md` changes take effect **post-merge only**. The hub constructs briefs from `main`-resolved procedure text for the remainder of this run. The same holds for § Hub Staging Discipline: the hub running this release is not bound by it until it merges. | CHEAP |
| **R-3** | **Anchor drift across seven sequential edits to one file.** Every landed edit shifts the anchors the next card's brief cites. | LOW | HIGH | Stage 6 briefs | Cite section headings and quoted predicates only. Graded as **CIAC-3**. | CHEAP |
| **R-4** | **Cross-milestone narrow-surface collision — and it is now live.** Draft PR #6626 modifies `stage-13-close.md`, #5084's primary surface. Stage 4's zero-open-PR reading is superseded. | MED | **HIGH** | Stage 9 / 12 | Re-check #6626 before #5084's spoke writes that file, and again at Stage 12 pre-merge. Whichever merges first, the other re-baselines. | MODERATE |
| **R-5** | **#5084's fix is not exercised by this release's own close-out.** Version-less ⇒ Phase B5.7 `SKIP`; the monotonicity predicate ships into a path Stage 13 will not execute here. | MED | HIGH | Stage 7/8 | AC4's regression arm must be a **constructed out-of-order fixture**, never this release's own Stage 13. | CHEAP if caught at Stage 8; EXPENSIVE if it ships unverified |
| **R-6** | **Skill-package staleness reddens the merge.** Three rostered skills are edited; each package `.sha256` hashes every file in its tree. | MED | MED | Stage 6 | Each card runs `core/deploy/tools/build-skill-packages.sh <skill>` and commits the package + sidecar in this PR. Verified at C4. | CHEAP |
| **R-7** | **The gate is in `warn` mode, so it will not catch a missing sanctioned session.** The deployed `.mode` reads `warn`, in which `apply_block` logs and exits 0. | MED | MED | Stage 9 | Conformance is standing discipline, observable only in review. Two switches from binding, not one — the `workflow`-class master-activation gate runs before the `.mode` read. | CHEAP |
| **R-8** | **Predicate collision (D10) between #5505 EDIT 5 and #6599 EDIT 4** on one region of one branch, mitigated by design rather than separation. | MED | MED | Stage 9 | #6599 sequenced last with a stop-and-surface rule on the anchor string. Graded by **CIAC-4**. | MODERATE |
| **R-9** | **Second-order blast-radius fan-out never measured** on the three Structural-tier targets (`--depth=1` bound declared; `--depth=2` exceeded a 120 s budget). | LOW | — | Stage 7 | Under an additive-only change with no anchor removed, second-order break-surface is structurally nil — but that is an argument, not a measurement, and is labelled as such. **Accepted, explicitly.** | CHEAP |
| **R-10** | **Domain-practice conformance not assessed** (design-review checklist 4.6, domain `governance`). | LOW | — | Stage 7 Phase C | Surfaced forward per the check's own routing; does not block Engineering. | CHEAP |

**Rollback strategy.** Single branch, single PR. Zero deletes, zero renames; the only adds are four test fixtures. Rollback is `git revert` of one merge commit. No data migration, no deploy artifact, no external state. **Reversibility: CHEAP · confidence HIGH.** The one asymmetry is R-5: if the monotonicity predicate ships wrong and is not exercised until a later out-of-order close, detection is delayed even though the revert stays cheap.

---

### Quota Budget

**Verdict:** **WARN** (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from § Stage Applicability Matrix):** Stage 5: **7** (complete) · Stage 7: **7** · Stage 8: **7**
**Per-spoke cost estimate:** size-bucket ordinal bands — `size:S` → *low* · `size:M` → *low–moderate* · `size:L` → *moderate–high*. The § 5.1 cutover to observed medians is **not met** for any bucket (no `estimate-usage.sh` median population available), so every bucket keeps its ordinal band.
**Assumed/stated remaining usage-window envelope:** **`UNSTATED`** — no operator quota band was relayed. The conservative default applies.
**Estimated cumulative draw % (worst parallel batch):** **not rendered.** With basis `UNSTATED` this check does not synthesize a figure. `[ASSUMPTION – CONFIRM]`
**Routing:** **WARN → window-aware launch timing + quota-budgeting (split batch) recommended.** WARN rather than PASS because a PASS asserts *"< 50 % of envelope"*, which has no grounding while the envelope is `UNSTATED`; WARN rather than FAIL because nothing indicates a > 80 % draw. **The batch is larger than Stage 4 modelled** — seven parallel-eligible spokes at Stages 7 and 8, not three — which is a further reason to split rather than launch a single wave.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API quota axis, combined DEFER-dominant. Checkpoint A stays usage-window-only. Bands + cumulative-draw budget + the host-API floor are `[CALIBRATE-AFTER-3]` MEDIUM.

---

### Deviation Log

Departures from the as-filed issue bodies and the as-authored Stage 4 plan, with rationale. No close-family verb precedes any `#N` below.

| # | Deviation | Driver | Rationale |
|---|---|---|---|
| **(a)** | **Three files beyond the Stage-4 File Change Matrix are edited for #5833:** `release/releases/hub-state/README.md`, `core/standards/gate-efficacy-standard.md`, `release/tools/tests/test_spoke_run_directory.sh`. | Stage-5 design, all three warranted. | **README:** AC2 demands the staging location resolve to one determinate path; the file spelled the run key `vX.Y` while the substrate authority spells it `<milestone-slug>`, so without the repair a fresh agent derives two paths. Its ASCII tree is also an architecture-class artifact gaining a member — refreshing in-release prevents this release from *introducing* the drift. **Gate-efficacy register:** design-review checklist 4.9 is blocking and the design adds a class 3-O obligation-shaped predicate; both available dispositions are register-anchored, so the row is owed either way. **Test suite:** 4.9's wire-it disposition for the presence half of that predicate. |
| **(b)** | **`packages/release-hub.skill` and its `.sha256` are added to the deliverable set** — absent from both the Stage-4 matrix and the Stage-5 change set, which declared "0 adds" against a 6-file population. | Check 7 / `skill-package-freshness` CI gate. | The sidecar is a content hash computed over every file in the packaged tree. Editing `SKILL.md` or `references/spoke-launch.md` changes that hash by construction. Unrebuilt, the release merges red. The same cascade applies to `release-planner` (#5505, D26) and `release-executor` (#5084, D5/AI-017). |
| **(c)** | **The Stage-5 design text is not transcribed verbatim.** Six determinate corrections are applied at implementation — the H8 register row's column shape and heading level, its `runner-def:` anchor, the FM-1 repair scope, H7 Edit 1's replacement span, A8/A9's grep scope, and both A-NEG arm-count literals. | The Stage-5 adversarial review (FM-1 … FM-8) was never remediated back into the design text. | The design predates its own review. Its H7/H8/H9 text still contains the defects the review names, each fully specified in the review and carryable at Engineering — which is why Phase A returned CAVEATS rather than HOLD. Transcribing literally would emit a malformed register row, an anchor that resolves CLEAN before any arm exists, a bare `vX.Y` sweep corrupting 11 unrelated sites, a leftover `vX.Y` on a replaced line, an arm that survives its own deletion control, and a half-updated arm count. |
| **(d)** | **The Stage-5 design's "next release" routing for the run-key sweep is not acted on** (its D-1 / RS-7 out-of-scope item (b)). | Operator decision **D7**, which post-dates the design. | D7 pulled the hub-state run-key sweep into this milestone through a second Solutioning wave. A spoke reading only the Stage-5 output would act on stale routing. |
| **(e)** | **RS-5's mitigation is not carried; the risk cannot fire.** Class-L structurally cannot fire on `hub-state/README.md` (the file matches no durable-corpus glob in either enforcing surface, which share one predicate), and Class-V's `CUTOVER_RE` requires a concrete `v[0-9]+\.[0-9]+`, which `vX.Y` is not. | #6598's remediation pass, hub-confirmed on the two enforcing surfaces. | The design's H7 Constraint paragraph carries a "confirm the reference-durability check's disposition before merging" step predicated on a risk that cannot fire. Carried as a gate it would be ceremony. **Label subtlety worth stating:** the brief's "RS-5" resolves **by content** to that Constraint paragraph, not by label to the design's own RS-5 (which is "second-order fan-out never measured", already dispositioned Accepted). Act on content, not the label. |
| **(f)** | **#6596's AC1 is dispositioned rather than executed as written.** "Fix all three `v[0-9]` sites" becomes "all three reviewed and dispositioned" — by literal site, 1 updated and 2 preserved, plus 1 sibling arm added. | The AC's premise is wrong. | Two of the three sites are the two limbs of one branch predicate that parses version-keyed branch names — 435 distinct across `main`'s merge history. A uniform sweep would break working behaviour to satisfy the AC's letter while defeating its intent. |
| **(g)** | **The Stage-5 ADR ships without a number**, cited as **#6617** throughout. | Operator decision **D27**. | Three concurrent releases collided on 170/171. Number allocation moves to Stage 12, where the claim is atomic. A number written now would be a claim this release cannot honour. |
| **(h)** | **#6596's editability class was changed to `sanctioned-session-required` at the Stage-6 commit and then restored to `unconstrained`.** Net effect on the class: none. What did change is its **evidence** — column 2 now names the in-scope path and the failing conjunct instead of a bare `∅` — and its File Change Matrix rows, which expand from one to twelve (including the fourth `packages/*` pair). | The reclassification read only the **first** of the gate's three conjuncts; the correction reads all three. | `stage-04-planning.md` § *Sanctioned-session gate* gates a path on scope-regex match **and** the arming key **and** exemption-list absence. `core/skills/finops-usage-extractor/SKILL.md` matches the regex — which is what prompted the change — but does **not** carry `skill_discipline_migrated_v10_2` (5 of 56 in-scope files do not), so the hook takes its `exit 0  # not yet gated` branch and the conjunction is false. The Stage-4 verdict was right; only its `∅` evidence was wrong, and that is what the restored row fixes. **The round trip is recorded rather than erased** — a class that changed and changed back is exactly the kind of churn a deviation log exists to make visible. No other card's row was touched at any point. |
| **(i)** | **The D39 sticky-header-bind fixture is an added unit beyond the eight Stage-5 units**, with its own sub-issue and its own CI precision probe. | Operator decision **D39**. | The Stage-5 remediation specified a sticky per-file column bind whose failure mode is silence, but the property was unreachable from tracked artifacts: the in-repo hub-state template carries no managed-section fences — they are composed at install. The operator chose to build the fixture rather than grade the property by inspection. Carried as its own unit rather than folded into the parser unit because its acceptance is a distinct both-arms demonstration. |
| **(j)** | **Two CI precision probes added to `release-tooling-smoke.yml`**, and the estimate fixture gains a synthetic ledger table plus three `SE-7b` arms. | AC2's "must turn red on a reorder", and the same standard applied to the other two silent-failure properties this card introduces. | AC2 requires the shadowing guard turn red on a deliberate reorder — a requirement that is unverifiable unless something performs the reorder. The probes follow the job's established mutation pattern and each asserts its anchor matches exactly once, so a probe that can no longer find what it breaks reports that rather than passing quietly. |
| **(k)** | **`.github/workflows/release-tooling-smoke.yml` and `core/skills/finops-usage-extractor/test-fixtures/estimate/RELEASE_LOG.fixture.md` are edited beyond the Stage-5 change set.** | Deviations (i) and (j). | The workflow carries the two new precision probes; the estimate fixture carries the ledger table without which the new alias path in `release_log_velocity_map()` would ship untested — the accessor's alias branch had no fixture coverage at all, so a regression there would have been invisible. |

---

### Scope boundary — D14 as corrected by D29

Two adjacent repairs in two different files, easy to conflate and consequential to get wrong. Recorded here because both failure directions are silent.

| Owner | Scope |
|---|---|
| **#6598** | the **"First emit" bullet in `release/releases/hub-state/README.md`** — that line only |
| **#5833** | the **two `vX.Y` run-key sites in `release/references/how-to/hub-spoke-bridge.md`** — never routed away |

Measured, three arms: `"First emit"` occurs **1×** in `hub-state/README.md` and **0×** in `hub-spoke-bridge.md`; control `emit` → **69** in the bridge, so the probe fires; specificity `"Firstzz emit"` → **0**. A spoke **over-reading** the routing as covering the bridge **skips the run-key repair entirely**; a spoke **under-reading** it repairs the README bullet and **collides with a sibling card on one line**. Neither failure produces an error — the over-read silently omits work, the under-read silently no-ops against a sibling's edit.

---

_Engineering Commit 0. The Stage-4 planning sub-task comment is the working reference up to this commit; from here the plan file is the durable surface. `## Change Description` is authored on this branch before the PR is marked ready-for-review, per the Change Description Protocol._

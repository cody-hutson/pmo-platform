# Release Plan: authoring-bar-and-consumers — Per-kind authoring bar and its consumers

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination. A capability release adding a standard and changing consumer behaviour; not corrective against a deployed release (rules out `patch`), no breaking re-architecture (rules out `major`). The concrete number binds only at the Stage-12 atomic claim (ADR-092). Provisional display at Stage 4 and re-verified at Engineering Commit 0: `v4.61`, computed from anchor `v4.60`. |
| **Date Created** | 2026-09-11 (Friday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | release/authoring-bar-and-consumers |
| **PR** | #7410 (draft at Stage 6; transitioned to ready at the Stage 9 gate) |
| **Milestone** | authoring-bar-and-consumers |

**Baseline pin (Survival element 9).** `origin/main` = `a30838589583bcddf5f88183cfff1a8ea2475300` (`a3083858`). Every measurement in this plan is pinned here unless a row states otherwise. Stage-9 Phase A6.5 diffs mid-pipeline divergence against this SHA.

**Provenance label.** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-10, domain: governance }`

*Classification rationale (A3-time, from the matrix):* every add/edit row targets `core/` governance, schemas, packs and ADRs plus `operations/skills/` skill definitions — no application source, no web or data surface. Dominant domain `governance`; the secondary domain is `software` for the two `.skill` package artifacts, which are build outputs of the governance-class sources rather than an independent deliverable class. The matrix consists entirely of internal pmo-platform artifacts, so the release is sourcing-exempt and takes Form X verbatim.

## Release Class

**Class: `cross-cutting`** (Survival element 7).

**Dominant trigger: (c) — the in-bundle compositional edge count.** Four intra-bundle dependency edges, confirmed live via the Dependencies API. Trigger (a) does not fire: 0 `pipeline/stage-*.md` files in the matrix. Trigger (b) does not fire: at most 1 of the 6 rule-defining governance surfaces, and that row is CONDITIONAL. Both `cross-cutting` and `novel` fire; the highest-ceremony class wins.

**Differentiation posture:**

- Engagement density: **Tight**
- Stage 9 Plan Review depth: **Deep**
- Stage 5 activation bias: **ALL**
- Stage 13 outcome-window: **30-day**

## Scope

### Issues Included

| # | Issue | Title | Category | Size |
|---|-------|-------|----------|------|
| 1 | #6364 | Determine whether L3-judgment checks are agent-evaluable | `type:spike` | S |
| 2 | #6379 | Consumer contract for the resolved work-item kit | `type:spike` | M |
| 3 | #6367 | Per-kind authoring standard | `type:story` | L |
| 4 | #6368 | Elicit to the resolved kit's depth | `type:story` | M |
| 5 | #6369 | Gates evaluate the resolved kit's criteria | `type:story` | M |

### The measured surface this release acts on

Every figure below was independently re-derived at Engineering Commit 0 against `a3083858`, with control arms, and **supersedes the Stage-4 comment where the two differ**. The Stage-4 comment is immutable history; this file is the first writable artifact downstream of the corrections, so the corrections land here.

**Re-derived a second time at the release tip** for this reconciliation, by a structure-shaped TOML parse walking every `checks` array at any depth in both manifests. The Commit-0 column is retained beside it, because the *movement* is the finding: mainline added one check inside this release's window, and a plan carrying only the newer number would hide the fact that any figure here can move again.

| Measurement | At Commit 0 (`a3083858`) | **At the tip (`a62d7ae9`)** | Note |
|---|---|---|---|
| Criteria checks declared across `core/packs/{scrum,kanban}/pack.toml` | 26 | **27** | scrum **21** · kanban **6** — the whole movement is Kanban's |
| Checks at `level = "L3"` | 19 | **19** | unmoved |
| Checks at `automatable = false` | 21 | **21** | unmoved |
| Checks at `automatable = true` | 5 | **6** | the added check is `kanban-gate-wip-pull-limit`, `level = "L2"` and `automatable = true` |
| Field declarations (`fields.kind_specific[]`) | 8 | **8** | all in `core/packs/scrum/pack.toml`; kanban declares none |

Arms on the tip column: **sensitivity** — one synthetic `level = "L3"`, `automatable = false` check injected into a parsed copy moves the total, the `L3` count and the `automatable = false` count by exactly **+1** each; **specificity** — a level value no check carries (`L9`) reads **0**.

**The `L3` set and the `automatable = false` set are NOT the same set.** They diverge on exactly two checks — `kanban-dor-pull-policy-explicit` and `kanban-dod-exit-policy-satisfied` — both `level = "L2"` **and** `automatable = false`. Measured at the tip, the set difference is one-directional: `L3 \ automatable = false` is **empty**, and `automatable = false \ L3` is exactly those two. The full cross-tabulation at the tip is `(L3, false) = 19`, `(L1, true) = 4`, `(L2, false) = 2`, `(L2, true) = 2` — the last cell being the one that moved, from `1`.

**Every figure in this table is a pinned measurement for review, and no downstream criterion grades against one.** Where a consumer needs the admitted set it reads the predicate — each check's own `automatable` flag — and re-derives; that is what makes the table safe to be stale and the criteria safe from it.

**Two Stage-4 figures are corrected here and must not be re-propagated:**

1. **"#6369 evaluates 26 checks or 7" is wrong, and the arithmetic that replaced it is withdrawn too.** `26 − 19 = 7` silently assumes the two sets above are identical; they are not, so non-L3 is 7 while `automatable = true` is a different number. **The replacement `5 + G` is withdrawn in its turn**, and for a more instructive reason: both of its terms were unstable. `G` was never measured — the landed record states `G` as `NOT-EVALUATED` — and the standing term moved with mainline from 5 to 6. **#6369 admits by a predicate over each check's own `automatable` flag**, so the admitted set re-derives from the packs at grading time and no cardinality belongs in this plan at all. See § Issue #6369.
2. **"16 field declarations" is wrong.** The count is **8**.

**One Stage-4 framing is corrected here.** `core/ADRs/README.md` is **not an index**. It states of itself, in bold, that it is a curated thematic document and not an index, that it has never enumerated the core module's full record set, and that it must not be converted to a generated index. An ADR entry goes **under an existing thematic grouping as curated content**, never as an enumeration row. The file carries no ADR count, so no count cascade follows from adding a record. The Stage-4 "index row" framing would have produced a defect; it is corrected in this file and in the `#6364` change spec below.

### Dependency Graph

Directional, `blocker → blocked`. All edges confirmed live via the GitHub Dependencies API at Stage 4, not inferred from prose.

| Edge | Kind | Blocker state |
|---|---|---|
| #6364 → #6367 | hard | in-bundle, wave 1 → wave 2 |
| #6364 → #6369 | hard | in-bundle, wave 1 → wave 3 |
| #6367 → #6368 | hard | in-bundle, wave 2 → wave 3 |
| #6367 → #6369 | hard | in-bundle, wave 2 → wave 3 |
| #6378 → #6367 | hard, cross-milestone | CLOSED 2026-09-05 — satisfied |
| #6379 ⇢ #6368, #6369 | soft (informs) | no API edge exists |

Zero cycles: DFS three-colour detection over the 5-node / 4-edge graph returned 0, against a sensitivity arm (injected `#6369 → #6364`) that returned the cycle `[6364, 6367, 6369, 6364]`.

### File Change Matrix

Machine-readable, one path per line, `<path>  <VERB>`. Non-change classes sit in separately labelled blocks and are excluded from the obligation set.

```
# ── #6364 — L3-judgment evaluability spike ──
core/ADRs/ADR-197-l3-judgment-criteria-evaluability.md                       add
core/ADRs/README.md                                                          edit
core/schemas/work-item-type-schema.md                                        edit

# ── #6379 — consumer-contract spike ──
core/references/reference/work-item-type-consumer-map.md                     edit
core/schemas/work-item-type-schema.md                                        edit

# ── #6367 — per-kind authoring standard (D-StandardHome = option C, rendered) ──
core/standards/work-item-authoring-standard.md                               add
core/packs/README.md                                                         edit
core/ADRs/ADR-198-per-kind-authoring-bar-is-a-reading-not-a-carrier.md       add
core/ADRs/README.md                                                          edit

# ── Tier-1 [ADJUST] against #6364's landed artifact (AI-014) ──
core/ADRs/ADR-197-l3-judgment-criteria-evaluability.md                       edit

# ── #6368 — elicit to the resolved kit's depth ──
operations/skills/intake-desk/SKILL.md                                       edit
operations/skills/intake-desk/references/elicitation-loop.md                 edit
operations/skills/intake-desk/references/type-map.md                         edit
operations/skills/intake-desk/evals/fixtures/kit-depth-divergence.md         add
packages/intake-desk.skill                                                   edit
packages/intake-desk.skill.sha256                                            edit

# ── #6369 — gates against resolved kit criteria ──
operations/skills/delivery-engine/SKILL.md                                   edit
operations/skills/delivery-engine/references/gate-checklists.md              edit
operations/skills/delivery-engine/references/gate-definitions.md             edit
operations/skills/delivery-engine/evals/fixtures/kit-criteria-gate-failure.md add
CONDITIONAL:g1-g3-criteria-contract-changes core/schemas/gate-criteria-spec.md edit
packages/delivery-engine.skill                                               edit
packages/delivery-engine.skill.sha256                                        edit

# ── Release-pipeline artifact ──
release/releases/plans/authoring-bar-and-consumers_RELEASE_PLAN.md            add

#### Read-only inputs
core/deploy/tests/fixtures/packs/                                            READ
core/deploy/tools/check-work-hierarchy.py                                    READ
core/packs/_common/pack.toml                                                 READ
core/packs/scrum/pack.toml                                                   READ
core/packs/kanban/pack.toml                                                  READ
core/ADRs/ADR-069-methodology-pack-composing-unit.md                         READ
core/ADRs/ADR-033-methodology-conditional-skill-activation.md                READ

#### Release-wide explicit non-scope
core/specs/label-taxonomy.md                                                 NOT EDITED
operations/skills/tracker-manager/SKILL.md                                   NOT EDITED
operations/skills/ppm-agent/SKILL.md                                         NOT EDITED
```

**Matrix corrections against the Stage-4 comment, applied here.**

- **#6367's write set is restated.** The Stage-4 matrix carried `core/packs/scrum/pack.toml  edit` and `core/packs/kanban/pack.toml  edit` as unconditional rows. Those rows **do not fire**: #6367 reads the packs, it does not write them. Its delivered write set is a new standard under `core/standards/`, a `core/packs/README.md` bullet, an ADR, and an ADR-README entry. The two pack manifests move to the read-only block above. #6367's ADR and ADR-README rows are not enumerated as separate paths here because the ADR filename binds at that card's own Commit (see § ADR number allocation); its spoke adds them to this matrix in the same commit that authors them.
- **The two `D-StandardHome` CONDITIONAL rows are promoted.** The decision rendered at the Stage-4 gate as **option (C) — the cleave**. The fired row (`core/standards/work-item-authoring-standard.md  add`) is promoted to unconditional in this commit, carrying its concrete path; the option-(D) rows (`core/packs/{scrum,kanban}/authoring.md`) are removed rather than left CONDITIONAL, because a row left conditional after its decision resolves is indistinguishable from a row whose condition never fired.
- **`core/schemas/work-item-type-schema.md` gains a second claimant.** See § File Contention Map.
- **One `add` row names no tracked executable `*.sh`**, enumerated over every `add` row in the matrix, so the `script-execution-allowlist.txt` companion obligation does not fire. Recorded as a discriminating negative.

### File Contention Map

| Path | Claimed by | Severity | Resolution |
|---|---|---|---|
| `core/schemas/work-item-type-schema.md` | **#6364**, **#6379** | BINARY | Both are **wave 1**. #6364 edits § 3.1 step 5's `L3` arm; #6379 inserts after § 1.5.7. **#6364 lands first** — `AI-008`. Different sections of one file; sequential edits on one branch, not a merge conflict. |

**This corrects the Stage-4 Contention Map, which understated the claimant set.** Stage 4 recorded the path as claimed by #6364 and #6367 and resolved it by wave order (wave 1 → wave 2). Both halves of that row are wrong: **#6367 carries no claim on this path at all**, and the real second claimant is **#6379**, which is in the *same* wave. Wave ordering therefore does not serialize these two writes — an explicit intra-wave ordering constraint does, and it is recorded as `AI-008` below.

**`AI-008` — the intra-wave anchor constraint.** #6364's edit is anchored inside § 3.1 step 5 (at line 593 as of `a3083858`). #6379 inserts approximately 45 lines after § 1.5.7 (which ends at `:538`, separator at `:540`), which shifts every downstream anchor in the file. **#6364 therefore runs first within wave 1.** Both spokes resolve their anchor **by content match, never by line number** — the line numbers in this plan are a pinned measurement for review, not an addressing mechanism.

### Cross-Milestone Dependency Validation

#### G3-07 Status

`PASS — 5 dependency edge(s) checked, 0 cross-milestone violations.` The single cross-milestone edge (`#6378 → #6367`) resolved: #6378 closed 2026-09-05 in a closed milestone.

#### Violations

N/A — enumerated over all 5 dependency edges (4 intra-bundle, 1 cross-milestone); none unresolved.

#### Registered Exceptions

N/A — enumerated over the violation set, which is empty; no exception is required.

### Cross-PR Overlap Audit

#### Baseline SHA

`a30838589583bcddf5f88183cfff1a8ea2475300`

#### In-Flight Release Roster

**Measured at:** `a3083858` · `2026-09-10` · **Population:** n=1 sibling

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `closeout-correctness-batch` | `#7253` (draft) | `284d5cc3` | `UNRESOLVABLE` | — | `UNRESOLVABLE` | — (empty) |

The sibling declares no bump-class reachable from its PR metadata, so both columns render `UNRESOLVABLE` rather than blank — an unknown, not an absence. Zero same-path collisions against this release's matrix.

**One non-path cross-release contention is real: the ADR number slot.** See § ADR number allocation.

### Exclusions

N/A — enumerated over the milestone's full card set (5 of 5 included) and over the Stage-4 deferral set (empty). No issue in this milestone is deferred out of this release.

## Implementation Sequence

Topological waves, derived: `[[6364, 6379], [6367], [6368, 6369]]`, critical-path depth 3 (Survival element 8).

| Wave | Cards | Order within wave | Why |
|---|---|---|---|
| **1 — Foundation** | **#6364** then **#6379** | **#6364 first** (`AI-008`) | Both have in-degree 0. #6364 decides whether the standard is enforceable or guidance; #6379 states the consumer contract. They share `core/schemas/work-item-type-schema.md` and #6379's insertion shifts #6364's anchor, so #6364's line-anchored edit lands first. |
| **2 — Standard** | **#6367** | singleton | Consumes #6364's verdict; its output is what #6368 and #6369 read. |
| **3 — Consumers** | **#6369** then **#6368** | **#6369 first** | Both consume #6367. #6369's `references/` write set is `sanctioned-session-required`, so launching it first surfaces a sanctioned-session gate failure at the first spoke rather than the second. |

**Concurrency posture: P0 fully-serial, single-branch topology** — one release branch, one PR, one merge. The hub routes one Engineering chip at a time; the next chip waits until the prior commit lands on the release branch.

### Issue #6364: Determine whether L3-judgment checks are agent-evaluable

**Change Specification:**
- **Files modified:** `core/ADRs/ADR-197-l3-judgment-criteria-evaluability.md` (add) · `core/schemas/work-item-type-schema.md` (edit, § 3.1 step 5 `L3` arm only) · `core/ADRs/README.md` (edit, curated entry under `## Data-architecture ADRs`)
- **Change description:** Record that criterion evaluability is a **per-check measured property**, not an attribute of a level; measure it over a census of all 19 `L3` checks plus 2 divergent `L2 ∧ automatable = false` control checks; and state the admission rule the two consumer cards cite.
- **Estimated complexity:** Medium (spike; the experiment, not the edits, carries the cost)
- **Dependencies:** None (in-degree 0)

**A6.5 corrections applied under Tier-1 [ADJUST] — inside the existing design shape, not a redesign:**

1. **`r = 3` is grounded rather than left as a free parameter.** Unanimity-over-`r` is monotonically stricter in `r`, so the bar's stringency *is* `r`; the design's claim to introduce "no numeric threshold at all" is false in the one parameter that sets both error rates. The error identity `P(classified gate-capable | true per-run reliability p) = p^(2r)` is recorded in the ADR's Consequences with its `r = 3` row, so an unstated property becomes a recorded one. `r` is **not** raised — raising it worsens the Type-II rate. Instead, every `advisory-only` verdict carries its **arm counts** (`n/r` per arm), so an exclusion driven by a 2/3 arm is distinguishable from one driven by 0/3 and is re-openable against a recorded number rather than permanent.
2. **The `advisory-only` disjunct conflation is corrected — the mechanism survives, only its justification changes.** `advisory-only` is defined disjunctively: *not unanimous* **or** *any run `UNRENDERABLE`*. Only the `UNRENDERABLE` arm maps to `NO-EVIDENCE` and thus to a permanent BLOCK. A non-unanimous check renders a definite verdict every run, so the engine never sees `NO-EVIDENCE`; admitting it yields a **flaky, re-rollable** gate — the gate-washing vector the engine's own guardrails name — not a permanent block. Both disjuncts still route to MUST-NOT-ADMIT, for two individually sufficient reasons rather than one. Verified at source: the engine evaluates each criterion *"against available evidence"*, which is per work item by construction.
3. **Layer D's partition is scoped to what it actually feeds.** The three classes are non-disjoint with no precedence rule, and 7 of the 21 in-frame checks have no determinate class. Layer D feeds the diagnostic comparison and the ADR's partition column — **not** the verdict rule, not `G`, and not the routing rule. The fix is scoped accordingly: the partition is replaced by an ordered two-question procedure that is disjoint by construction and yields the same three labels, so the ADR column and the diagnostic comparison are unchanged in shape.
4. **The un-replicated-rater residual is addressed or explicitly recorded.** Layers D and E are hand-classified by one rater with no agreement measurement, inside a card whose completion condition is *"measured and reported, not asserted."* A second independent classification pass over the 21 Layer-D rows is the cheap remedy (21 classifications). Where it is not run, the whole partition column is graded `[INFERRED]` in the ADR and the diagnostic comparison is stated as diagnostic, not evidential. Silence on this point is not an option.

**AC-1, AC-2 and AC-3 are AMENDED by operator decision `PA-003`** — the Stage-7 disposition of Dev Testing's finding that the three could not be graded (hub ledger `AI-034`). As written, all three presuppose a per-check Results table — per-arm `n/r` counts, an agreement column, a verdict column — and the landed record carries none of it: it records `G` as **`NOT-EVALUATED`**, with those columns **absent** rather than null. AC-3's *"every row carries…"* was therefore a universal over zero rows, which cannot fail. **The amendment takes the three-arm shape `AI-018` gave #6369's INT-1 and INT-2 for the identical defect.** The arms are the record's own `G` states — `G ≥ 1` and `G = 0 (measured)`, which share one predicate because both carry the per-check table, and `NOT-EVALUATED`. **Only the arm the record is in is graded, and that arm is read from the record, never assumed:** a record stating a measured `G` without the per-check table fails the measured arm, so the amendment cannot pass a measurement the record does not carry. The measured arm restates the original criterion, so it binds unchanged the moment a measurement lands. Recorded here and not in the Stage-5 design comment, which is immutable. **Amended text, graded verbatim at Stage 8:**

- **AC-1 — the reproducibility test's instrument is pinned against real work items.** *Measured arm:* the Results carry one row per check in the frame, each with its falsification and specificity `n/r`. *`NOT-EVALUATED` arm:* Appendix A carries exactly one binding per check in the census frame, and the binding set is set-equal to the frame the shipped packs declare — every check at `level = "L3"` plus every check at `level = "L2"` with `automatable = false`; every binding's base token names an A.3 base-item block, and every real base item is named in § Provenance; and the record states that context-isolated runs were executed against the pinned instrument and records that instrument's limitations as run.
- **AC-2 — inter-run agreement is reported as unmeasured, never asserted.** *Measured arm:* an agreement statistic reported per check as a diagnostic, an evidence grade on every row, and no asserted-without-measurement row. *`NOT-EVALUATED` arm:* the record states that `G` is `NOT-EVALUATED` and not 0; records the per-check arm counts, agreement statistics and verdicts as absent rather than null, together with the obligation to branch on that state before reading any count; and asserts no inter-run agreement figure and no `G` value or bound anywhere.
- **AC-3 — the recorded verdict routes both consumers to the conservative branch.** *Measured arm:* every per-check row carries exactly one of `gate-capable` / `gate-capable-under-conditions` / `advisory-only`, and every `advisory-only` names the disjunct that fired. *`NOT-EVALUATED` arm:* the Routing Rule states that while `G` is `NOT-EVALUATED` both consumers take the conservative branch, and names it per consumer — the per-kind authoring bar ships its enforceability dimension declared and unresolved, and the readiness and done gates admit no judgment-level check and report the remainder; and no check in the frame is recorded with a `gate-capable`, `gate-capable-under-conditions` or `advisory-only` disposition.

AC-4 is not amended by this decision. Its verdict method is restated separately — keyed on the record's slug rather than its provisional number, without changing what it grades (hub ledger `AI-046`; Deviation Log `D-12`).

### Issue #6379: Consumer contract for the resolved work-item kit

**Change Specification:**
- **Files modified (as built):** `core/schemas/work-item-type-schema.md` **only** — FC-1 (ADD § 1.5.8), FC-2 (EDIT the F3 row), FC-3 (EDIT the § 1.2 `criteria` row). **The consumer map is NOT edited**, correcting this row's Stage-4 reading: the design routes its staleness finding (`DR-1` / `R-3`, executable denominator 244 → 264) to a next-release issue rather than re-stamping a measured artifact as a side effect of a spike.
- **Dependencies:** None (in-degree 0). Runs **after** #6364 within wave 1 per `AI-008` — honored: #6364's § 3.1 step-5 edit landed at `01e61c8b`, and § 1.5.8 appends **below** § 1.5.7 and **above** step 5, so it shifts that anchor's position and not its content. Every anchor in this card's write set was resolved **by content match**, never by the line numbers recorded in this plan.
- **AC-5 is AMENDED by operator decision** — see § Hub-Rendered D-Decisions, `D-Section152Pointer`. **Amended text, graded verbatim at Stage 8:** *"The `Three named gaps … F2, F3, F4` sentence is byte-unchanged, and §§ 1.5.1 and 1.5.3–1.5.7 are byte-unchanged except for FC-2. **§ 1.5.2 is excluded from the assertion**, because the operator took the one-clause #6367 pointer into it in the same decision that amended this criterion."* As built, this card's own diff leaves § 1.5.2 byte-unchanged as well — the carve-out exists for #6367's edit, not for this one.
- **AC-3 is RESTATED, because its verdict command could not fail** (see correction 1 below). **Graded as two limbs, each with a live reader:** (a) *no resolution pointer* — `runner-def:` / `runner-src:` occurrences in the schema stay at **0**, with the sensitivity arm being the same reader over `core/standards/gate-efficacy-standard.md` → **58**, which proves the reader fires; (b) *no rule id minted* — the **distinct** `PACK-*` id set in the schema stays at **17 members**, with the sensitivity arm being the same reader over the subject plus one synthetic `PACK-C01` → **18**. Both limbs verified post-change.

**Two verdict methods RESTATED at Stage 7 (Engineering Pass 2). Neither criterion is amended — what each grades is unchanged; each was correct when authored and was overtaken by mainline inside this release's window.**

- **AC-5's first limb is RE-POINTED, because the sentence it names no longer exists.** Mainline closed F2 when Check 80 shipped and replaced *"Three named gaps, stated rather than smoothed: F2, F3, F4."* with *"Two named gaps, stated rather than smoothed: F3 and F4."* The limb asserts that sentence is byte-unchanged over a population of **0 on both sides**, so it cannot fail. **Graded instead on the successor sentence and on this release's own diff:** the line of § 1.5.3 carrying the phrase `named gaps, stated rather than smoothed` is byte-identical between the merge base with `origin/main` and the release tip — no commit of this release edits it. Expect exactly **1** such line on each side, and the two equal; measured 1 and 1, equal. **It fails** when a commit of this release edits that line (a copy of the tip with the count restored to *Three* reads unequal) or deletes it (the tip side reads 0). The operator's amended text above is recorded unchanged; only the reader for its first limb moves, as `AI-046` did for #6364's AC-4.
- **AC-3's limb (b) is RESTATED namespace- and notation-complete.** The merge introduced a second rule-id namespace, `PACKC-*`, that limb (b)'s `PACK-*` pattern cannot see — a synthetic `PACKC-Z99` leaves its count at 17 — and a count also moves when a line merely cites a registered id for the first time, which is minting's opposite. **Graded instead as a registry-membership predicate:** every rule id the schema cites must be registered in the validator's own `PACK_RULE_IDS` or `PACKC_RULE_IDS` tuple, reading both namespaces and all three citation forms the file uses — a full `PACK-*` / `PACKC-*` token, a bare id inheriting its prefix inside a space-separated list (how § 1.5.1 writes its three tier rows), and a slash-joined span such as `PACKC-P01`/`P03`. Expect the unregistered set **empty**; measured at the tip **28** ids cited, **28** registered, unregistered **∅**. **It fails** on a minted id in any of the three forms: `PACKC-Z99` → `{PACKC-Z99}` · `PACK-C01`, the family § 1.5's opening forbids → `{PACK-C01}` · a space list `PACK-K01 K99` → `{PACK-K99}` · a slash span `PACKC-P01`/`P09` → `{PACKC-P09}`. Unlike a pinned count, this form does not rot when mainline registers a further id.

**A6.5 corrections applied under Tier-1 [ADJUST] — inside the existing design shape, not a redesign:**

1. **AC-3's verdict command is fixed, and the reviewer's proposed replacement is fixed with it.** The design's command used `\|` under `git grep -E`, a literal pipe rather than alternation: **0 matches, exit 1** on the unmodified subject, forever. The corrected ERE returns **22** matching lines at the pre-change baseline (sensitivity arm `PACK-K01` alone → **7**; specificity `runner-zzq:|PACK-ZZQ[0-9]` → **0**), so the expression now fires. **But `returns exactly 22` is not the right assertion, and adopting the review's mitigation verbatim would have shipped a second unusable criterion — this one failing closed instead of open.** A matching-line count moves when a new line merely **cites** an existing id, and does **not** move when a newly minted id replaces an existing one on a line already counted: both error directions, against a criterion whose predicate is *minting*. Measured: the corrected expression reads **24** after this change, because FC-1 and FC-2 cite `PACK-K01`/`K02`/`L02` on new lines while minting nothing. The predicate is a **set** predicate, so AC-3 is restated as the two set/count limbs above.
2. **The Phase 0.7 zero-overlap report is withdrawn and the overlap is acknowledged.** The design reported no file overlap against a Contention Map whose single row names the very file this card edits in 3 of 5 FCM rows. The live claimant set on `core/schemas/work-item-type-schema.md` is **#6364 (landed, `01e61c8b`) and #6379 (this card)** — both wave 1, so the Stage-4 wave-serialization mitigation does not reach them. `AI-008` is the constraint that does, and it was satisfied in execution rather than assumed: #6364 landed first, and this card resolved every anchor by content.
3. **`criteria_version` is re-tiered M3 → M2.** § 1.5's own C3 row declares it *"Key required + semver-shaped"* with posture `GAP — no runner`, which is verbatim this design's **M2** definition. Left at M3 — where the rule reads *"M3 is not read"* — the misclassification would instruct a consumer to skip a schema-fixed key **and emit no caveat for its absence**, producing exactly the silent default the disposition rule exists to forbid. The tier table's partition principle is now stated explicitly as **specification-presence, never observed enforcement**, so the root cause is closed and not only the symptom. M3 consequently holds **one** member.
4. **The 13-of-21 figure keeps its number and loses its severity framing.** It re-derives exactly and decomposes to **0/4 shipped · 0/4 fixture-with-labels-facet · 13/13 fixture-with-no-labels-facet-at-all**, so the defect shape that would break a real project — a pack projecting *some* kinds and omitting others — has **zero corpus instances**. § 1.5.8 states it as a rule-completeness invariant with the consequence in the conditional, carrying the three-way split. The underlying gap is genuine and stays homed on F3; only the framing changed. The executed falsification arm is that exact conditional shape: removing one `type:` row from a three-kind pack → **clean, exit 0**, paired control → **`PACK-L02`, exit 1**.
5. **The denominator is carried into the canonical rule statement** (review finding FMF-3). The design stated the disposition rule five times in two shapes — *"kind and key"* in the Summary and D-1, *"kind, key and denominator"* in the FCM and AC-2. § 1.5.8 states the **three**-element form as the contract, with its own paragraph on why the denominator is load-bearing; a sibling card has already adopted that obligation from this design, so a two-element rule would have left it citing an obligation the shipped rule did not carry.

### Issue #6367: Per-kind authoring standard

**Change Specification:**
- **Files modified:** `core/standards/work-item-authoring-standard.md` (add) · `core/packs/README.md` (edit) · an ADR + its curated `core/ADRs/README.md` entry
- **Change description:** Under `D-StandardHome` option (C), the archetype-invariant **rubric** lives in `core/standards/` and **names no kind**; the per-kind **content** stays in the packs, which this card reads and does not write.
- **Dependencies:** #6364 (hard)

### Issue #6368: Elicit to the resolved kit's depth

**Change Specification:**
- **Files modified:** `operations/skills/intake-desk/SKILL.md` · `references/elicitation-loop.md` · `references/type-map.md` · `evals/fixtures/kit-depth-divergence.md` (add) · `packages/intake-desk.skill` + `.sha256`
- **Dependencies:** #6367 (hard)
- **CD-1 is ADOPTED by operator decision.** #6368 widens its depth read from `criteria.readiness` and `criteria.done` to the **full realizer set its cited dimension names** — which is where all 6 block-level `source` carriers actually live: **4 in `criteria.gate`, 2 in `fields`**. Without this widening the card's middle branch reads a domain containing zero instances and ships inert.

### Issue #6369: Gates evaluate the resolved kit's criteria

**Change Specification:**
- **Files modified:** `operations/skills/delivery-engine/SKILL.md` · `references/gate-checklists.md` · `references/gate-definitions.md` · `evals/fixtures/kit-criteria-gate-failure.md` (add) · `core/schemas/gate-criteria-spec.md` (CONDITIONAL) · `packages/delivery-engine.skill` + `.sha256`
- **Dependencies:** #6367 (hard), #6364 (hard)
- **Scope-fix owed (design conflict (a), Tier-1).** #6368's design prohibits any call into the shipped pack reader, and that prohibition **over-covers** the half #6369 relies on — its block-level `source` parsing. The prohibition is narrowed to the half #6368 actually needs.
- **The admitted set is the `automatable = true` set the shipped packs declare, read at grading time — never a number carried from this plan.** The Stage-4 arithmetic `5 + G, never 7` is withdrawn: it is stale in both of its terms. `G` was never measured — the landed record states `G` as `NOT-EVALUATED`, emphatically not `0`, so no arm of a `G`-keyed arithmetic is reachable — and the standing term moved with mainline, from **5** at the card's own commit to **6** at this tip, when a Kanban `criteria.gate` check arrived carrying `level = "L2"`, `automatable = true`. Re-derived at this tip by a structure-shaped TOML parse over both shipped manifests: **27** criteria checks, `automatable = true` **6** (`dor-epic-valuable`, `dor-story-valuable`, `dor-story-testable`, `dor-story-estimable`, `dor-task-belongs-to-item`, `kanban-gate-wip-pull-limit`), `automatable = false` **21**, `level = "L3"` **19**; sensitivity arm, one synthetic `L3`/`automatable = false` check injected → every one of those counts moves by exactly one; specificity arm, a level value no check carries → **0**. What #6369 grades is the **predicate**, not the cardinality: admission keys on each check's own `automatable` flag, so the admitted set re-derives from the packs whenever they move and this plan never needs re-stamping to stay true.

**`INT-1` and `INT-2` are AMENDED to a three-arm form by hub decision `AI-018`** — the Stage-6 disposition of the finding that neither could be graded as written. Both were phrased over two arms, `G ≥ 1` and `G = 0`, and the landed record reports **neither**: it records `G` as `NOT-EVALUATED`, distinguishes that state from `G = 0` by name, and its Routing Rule defines a **third** branch matching neither column. A criterion whose every arm is unreachable cannot fail, which is the vacuity class this release exists to eliminate. **The amendment takes the same shape `PA-003` later gave #6364's AC-1..AC-3 for the identical defect** — three arms keyed on the record's own `G` state, of which **only the arm the record is in is graded, and that arm is read from the record, never assumed**. The `G ≥ 1` and `G = 0 (measured)` arms restate the original assertion unchanged, so each binds the moment a measurement lands. Recorded here and not by editing the published Stage-5 design comment, whose edit history is permanent and unscrubable. **Amended text, graded verbatim at Stage 8:**

- **INT-1 (× #6364, shared surface: the evaluability disposition carried by `{{ADR:l3-judgment-criteria-evaluability}}` — no shared file path).** Does § 4.3's admission predicate consume the disposition **by identifier**, without restating any per-check verdict, and does the set it admits match the state the record actually reports? *`G ≥ 1` arm:* the admitted set is the `automatable = true` set **plus** every check the record dispositions `gate-capable` or `gate-capable-under-conditions`, and no other. *`G = 0 (measured)` arm:* the admitted set is the `automatable = true` set alone, with the remainder reported rather than admitted. *`NOT-EVALUATED` arm:* the predicate (a) consumes the disposition **by identifier** rather than restating it, (b) restates **zero** per-check verdicts, and (c) admits exactly the `automatable = true` set the shipped packs declare, **reporting the remainder with its denominator**. Limb (c) is licensed by the record's own conservative branch — while `G` is `NOT-EVALUATED` both consumers take it, no judgment-level check is admitted, and non-admission under `NOT-EVALUATED` is the same act as under `G = 0` but different in kind. All three limbs are required on whichever arm is live: a gate admitting a check the record dispositioned `advisory-only` re-opens the permanent-block defect, and a gate excluding one the record dispositioned `gate-capable` under-delivers AC-1. **This is also the #6369 half of `CIAC-1`**, re-keyed on the record's **slug** rather than its provisional number per `D-12`: a slug-keyed reader over the two consumer artifacts must return both.
- **INT-2 (× #6367, shared surface: the archetype-invariant standard's Enforceability subsection — no shared file path).** Does the enforceability posture § 4.3 implements match the branch #6367's standard actually authored? *`G ≥ 1` arm:* the **mixed** form — § 4.3 admits on the dimensions the standard names enforceable and on no other. *`G = 0 (measured)` arm:* the **guidance** form — the standard names no enforceable dimension and § 4.3 admits no judgment-level check. *`NOT-EVALUATED` arm:* **both surfaces take the record's third, conservative branch, and each states it in its own words** — the standard reads its judgment-level layer as *unresolved pending measurement* for every dimension, declared rather than silently absent, while § 4.3 keys admission on each check's own `automatable` flag, admits no judgment-level check, and admits no undispositioned check; **and both state the machine-evaluable layer as a pointer to a declaration rather than a count**, so neither restates a cardinality the other could contradict. A gate that admits checks on a dimension the standard names non-enforceable, or that admits none where the standard names an enforceable dimension, is the incoherence this grades. **Verified by reading both files side by side — no gate covers this pair, so the reading is the verdict**, and that is a declaration rather than an omission.

### ADR number allocation

**Claim from the anchor, never from the maximum claimed.** `renumber-adr.py --detect` at Commit 0 reported `ANCHOR 194 (origin/main)` → `NEXT-FREE 195`, with `CLAIMED-SET-BRANCH-ONLY 195,196 (detection only — never binds)`. Slots 195 and 196 are claimed on the in-flight sibling branch of PR #7253. That is a **governed collision, not a defect**: an unmerged claim does not bind the sequence, first-to-merge takes the number, and the other claimant renumbers at merge time. #6364 therefore claims **ADR-195**. Do not pre-emptively skip to 196.

**Outcome — renumbered `195 → 197` and `196 → 198` at merge time.** The sibling branch merged first and kept both slots, so the Stage-12 pre-merge sync carried them in and this release's two records moved to the next free slots by `release/tools/renumber-adr.py`, against a fresh `ANCHOR 196 (origin/main)` → `NEXT-FREE 197` read. That is the rule above executing as designed, not a deviation from it. Each record's own § Status numbering-provenance note carries the move, and `core/ADRs/README.md` § Renumber log carries the ledger entry.

A subsequent card on this branch that authors an ADR re-runs `--detect` and reads its own `CLAIM` row, which evaluates the **simulated merge result** and reports the correct `next=` for a second in-tree record. It does not re-derive a number by hand.

### Agent-Editability Read

**Derivation** — controls read at commit `a3083858`:

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh` — 2 `case "$ABS_TARGET"` blocks invoke `always_block "BLOCK-AUTONOMY-001"`. Projected repo-relative and tested against the tracked index at that SHA, the surviving union for this repository is `**/CLAUDE.md`, `**/OPERATIONS.md`, `**/RELEASE_PROTOCOL.md`. No path in this release's matrix intersects it.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh` — scope regex covers `<module>/skills/<name>/(SKILL.md|references?/*.md)`; arming key present in `delivery-engine`'s SKILL.md frontmatter, **absent** in `intake-desk`'s; deployed exemption list present with 1 entry, and neither skill is that entry.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #6364 | `core/ADRs/ADR-197-*.md` · `core/ADRs/README.md` · `core/schemas/work-item-type-schema.md` | no | no (not a skills path) | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6379 | `core/references/reference/work-item-type-consumer-map.md` · `core/schemas/work-item-type-schema.md` | no | no | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6367 | `core/standards/work-item-authoring-standard.md` · `core/packs/README.md` · ADR + README entry | no | no | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6368 | `operations/skills/intake-desk/SKILL.md` · `references/*.md` | no | **deciding conjunct 2 FALSE** — the skill is not armed | `unconstrained` | `unconstrained` | ordinary Engineering spoke |
| #6368 | `operations/skills/intake-desk/evals/fixtures/…` · `packages/intake-desk.skill*` | no | **deciding conjunct 1 FALSE** — `evals/` and `packages/` are outside the scope regex | `unconstrained` | ↑ | ↑ |
| **#6369** | **`operations/skills/delivery-engine/SKILL.md` · `references/gate-checklists.md` · `references/gate-definitions.md`** | no | **all three conjuncts hold** | **`sanctioned-session-required`** | **`sanctioned-session-required`** | **sanctioned session: `pmo-skill-editor` Mode A** |
| #6369 | `operations/skills/delivery-engine/evals/fixtures/…` · `core/schemas/gate-criteria-spec.md` · `packages/delivery-engine.skill*` | no | deciding conjunct 1 FALSE | `unconstrained` | ↑ (card class is the most-constrained member) | ↑ |

Per-path rows are retained, never collapsed into the card class. **What this read does not answer:** an `unconstrained` row means no control refuses the write; it never means the change is ungoverned. `intake-desk` is `unconstrained` **and** still bound by governance to route through `pmo-skill-editor` — the skill-deployment rule binds every `skills/<skill>/SKILL.md` and reference-file edit, and deploy-time Check 10 enforces its audit-trail trailer independently of the hook's arming boundary.

## Risk Register

| # | Risk | Likelihood | Impact | Reversibility | Mitigation | Owner |
|---|------|-----------|--------|---|-----------|-------|
| R1 | **#6364's verdict lands `G = 0`**, collapsing #6367 from an enforceable standard to guidance and reducing #6369 to 5 evaluable checks | Medium — 21 of 26 checks are already `automatable = false`, which is the direction of evidence | High — materially different deliverable for two cards | MODERATE | The verdict's **two downstream shapes are stated before the experiment runs** (below), so wave 2 needs no re-design beat. No FCM row changes under either branch; only authored content differs | #6364 spoke |
| R2 | **`D-StandardHome` unrendered at Engineering entry** | — | — | — | **CLOSED.** Rendered at the Stage-4 gate as option (C). The fired matrix row is promoted to unconditional in this commit | closed |
| R3 | **ADR slot 195 contested** with in-flight PR #7253 | High — 195 and 196 are both claimed on that branch | Low — renumber is mechanical and tool-driven at merge | CHEAP | Claim from the anchor at Commit 0; `renumber-adr.py` renumbers at merge time if #7253 lands first. Do not pre-claim | #6364 spoke |
| R4 | **#6369's `references/` write set is `sanctioned-session-required`**; an ordinary spoke reaches a wall mid-budget | High — all three conjuncts hold today | Medium — a wasted spoke budget, not data loss | CHEAP | Launch #6369 first in wave 3; dispatch as a sanctioned `pmo-skill-editor` session. Route the whole card rather than splitting the fixture limb | hub |
| R5 | **Package staleness** — `intake-desk` and `delivery-engine` `.skill` packages stale the moment their `references/` change | High if unplanned | Medium — blocks the deploy, and can block the merge | CHEAP | The matrix carries all four companion rows unconditionally. Rebuild via `build-skill-packages.sh intake-desk delivery-engine`, resolving the change set against the roster with `--skills-for-paths` **on STDIN, not argv** | #6368 / #6369 spokes |
| R6 | **#6379 concludes "the contract needs extending"**, leaving the consumers building against a known-insufficient contract | Medium — the card frames this as an acceptable outcome | Medium | MODERATE | The card's AC-5 already requires the deferred part and its revisit trigger to be named. A "needs extending" verdict is a Stage-9 input, not a wave-3 blocker | #6379 spoke |
| R7 | **`core/packs/` crosses to EXPENSIVE reversibility** when #6368/#6369 land — the pack manifest becomes a live read contract | Certain (it is the release's purpose) | High if the grammar is wrong | **EXPENSIVE** | This is the argument for having rendered `D-StandardHome` deliberately. Stage-9 review depth is **Deep** per the class | operator |
| R8 | **A vacuous mechanism ships** — a check that cannot fail, or a branch whose read domain is empty | Was High — three instances found in one design set | High — it is the exact defect class this milestone exists to eliminate | CHEAP pre-merge | All three instances are dispositioned: #6369's admission predicate, #6368's middle branch (CD-1 adopted), #6364's `G`-unreachability. **`CIAC-3` is widened to grade middle-arm reachability on shipped content**, so a design whose middle arm is exercised 0 of 8 no longer passes | Stage 9 |

**Zero rollback-complexity risk above CHEAP at the branch level** — single branch, single PR, one revertible merge commit. R7's EXPENSIVE tier is a post-merge *architectural* reversibility, not a rollback-mechanics one; the two are different objects and are not summed.

### R1 mitigation — the verdict's two downstream shapes, stated before the experiment runs

`G` = the count of the 19 `L3` checks landing `gate-capable` or `gate-capable-under-conditions` at `[SOURCE]` grade.

| | **G ≥ 1 — the standard has teeth** | **G = 0 — the standard is guidance** |
|---|---|---|
| **#6367** | The archetype-invariant rubric gains an **enforceability dimension**: each rubric dimension states whether a per-kind rule instantiating it may gate. The standard is **mixed** — the `G` subset gates; the remainder takes the named-gap form with a declared observable | The rubric ships as guidance and names no enforceable dimension. **Every** per-kind rule still takes a disposition — a downgrade to non-normative description, or a named gap with a declared observable. "Guidance" is not a licence to leave 19 normative-and-unrun predicates standing |
| **#6369** | Evaluates the `automatable = true` set **plus `G`**. The `G` subset is **admitted to the ANY-FAIL member set**, each admitted check carrying its own recorded falsification and specificity arm **and its arm counts**. The remaining `automatable = false` checks are **explicitly excluded**, and that exclusion is the load-bearing engineering act | Evaluates the `automatable = true` set alone. The remaining `automatable = false` checks are **reported, never admitted** — the existing explicit-report path generalizes from *no criteria* to *criteria present, not admitted, here they are* |

**This table names sets, not cardinalities, and that is a repair rather than a style choice.** It previously read *"Evaluates 5 + G"* against *"Evaluates 5"*, with a residual *"(19 − G) + 2"*. Every one of those numbers was a Stage-4 measurement of a corpus that has since moved: `automatable = true` read **5** then and reads **6** at this tip, and `automatable = false` read **21** then and still reads **21**, so a reader checking the two columns against the packs today would find one figure right and one wrong for no reason connected to either branch. The branches differ in **which set is admitted**, never in a count, so the count was never the thing being decided. **Neither branch is live:** the landed record states `G` as `NOT-EVALUATED`, which is a third state this table's two columns do not carry, and the consumers take the record's conservative branch — see `D-8` for #6367's side and the amended `INT-1`/`INT-2` in § Issue #6369 for #6369's.
| **Common** | The ADR is the **single verdict identifier** both consumers cite. Neither consumer restates the verdict; both cite it. The downstream shape is stated as an **obligation over the aggregate**, never as a named file edit in a sibling card's write set — #6369 owns its own placement | ← identical |

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered), P0 fully-serial |
| **Commit strategy** | Incremental — each Engineering spoke commits and pushes each coherent slice; one or more commits per card, referencing the card number |
| **Review approach** | **Single PR for the entire release**, created in draft at Stage 6, transitioned to ready at the Stage 9 gate |
| **Deployment mechanism** | Git merge + S-2 skill copy + `build-skill-packages.sh` package rebuild |
| **Stacked-base cleanup posture** | Option A — no stacked-base waves are planned |

## Verification Plan

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|-------------------|----------------|
| #6364 | AC-1 | **Amended by `PA-003`; graded on the `NOT-EVALUATED` arm — verbatim text in § Issue #6364.** Runnable limb: `grep -rc --include='*-l3-judgment-criteria-evaluability.md' '^Delta: ' core/ADRs` — expect exactly 21, one literal violating delta per binding. Structural limb: read the frame from `core/packs/scrum/pack.toml` and `core/packs/kanban/pack.toml` with a TOML parser — every check at `level = "L3"` plus every check at `level = "L2"` with `automatable = false` — and assert the Appendix A.4 binding ids set-equal to it, every binding's base token an A.3 block, and every real base item named in § Provenance. Record limb: the record states that the reproducibility test's runs were executed against the pinned instrument, under a `## Limitations of the instrument as run` section | Reproducibility test instrument pinned over real work items: 21 bindings set-equal to a 21-check frame — 0 missing, 0 extra, 0 duplicate — every base token resolving and every real base named; the limitations section present. **Fails** when a binding is dropped (the runnable limb reads 20), an out-of-frame check is bound, a base token resolves to no block, or the limitations section is absent — as it was before the Pass-2 fix added it. The measured arm is unreachable while `G` is `NOT-EVALUATED` and is not graded |
| #6364 | AC-2 | **Amended by `PA-003`; graded on the `NOT-EVALUATED` arm — verbatim text in § Issue #6364.** Runnable limb: `grep -rc -F --include='*-l3-judgment-criteria-evaluability.md' 'emphatically **not 0**' core/ADRs` — expect exactly 1, the statement that `G` is `NOT-EVALUATED` and not 0. Absence limb: the Layer-B Results record the per-check arm counts, agreement statistics and verdicts as absent, not null, and oblige a consumer to branch on the state before reading any count. Not-asserted limb: `grep -rc --include='*-l3-judgment-criteria-evaluability.md' -e 'G ≤' -e 'G <=' -e 'G &le;' -e 'bounded at' -e 'G = [1-9]' core/ADRs` must read 0, and no line naming inter-run agreement carries a figure | Agreement reported as unmeasured, not asserted: runnable limb 1; absence statement present; not-asserted limb 0. Sensitivity: the same not-asserted matcher over a copy of the record carrying the withdrawn upper bound reads 1; specificity: a sentinel reads 0. **Fails** when the record states a `G` value or bound, reports an agreement figure, or drops the not-0 statement. The measured arm is unreachable while `G` is `NOT-EVALUATED` and is not graded |
| #6364 | AC-3 | **Amended by `PA-003`; graded on the `NOT-EVALUATED` arm — verbatim text in § Issue #6364.** Runnable limb: `grep -rc -F --include='*-l3-judgment-criteria-evaluability.md' 'both consumers take the conservative branch' core/ADRs` — expect exactly 1. Per-consumer limb: the Routing Rule names each consumer's branch — the authoring bar ships its enforceability dimension declared and unresolved; the readiness and done gates admit no judgment-level check and report the remainder. No-disposition limb: no line of the record pairs a frame check id with `gate-capable`, `gate-capable-under-conditions` or `advisory-only` | The recorded verdict routes both consumers to the conservative branch: runnable limb 1; both per-consumer branches present; 0 lines pair a check id with a disposition token. Sensitivity: frame check ids and disposition tokens each occur in the record on their own, and a copy pairing one id with `gate-capable` reads 1. **Fails** when the branch statement or either consumer's branch is absent, or any check carries a disposition while `G` is `NOT-EVALUATED`. The measured arm is unreachable while `G` is `NOT-EVALUATED` and is not graded |
| #6364 | AC-4 | **Verdict method restated at Stage 7 (hub ledger `AI-046`); what the criterion grades is not amended.** Keyed on the record's slug, never on its number: the number is provisional until the Stage-12 claim and two records hold it today, and #6369 cites this one through its slug token, which a number-keyed search cannot see. Runnable limb: `grep -lF 'l3-judgment-criteria-evaluability' core/standards/work-item-authoring-standard.md operations/skills/delivery-engine/references/gate-definitions.md` — expect exactly 2, one line per consumer artifact that cites the record: #6367's authoring standard through its links to the record's file, #6369's gate definitions through the slug token. After the Stage-12 claim the stamp rewrites that token to a bare `ADR-N`: read N from the one filename under `core/ADRs/` that carries the slug, and grade the same two files on the whole token with `grep -lw`, expecting both again | Both consumer artifacts listed, and only those two: runnable limb 2. **Fails** when either consumer drops its citation — the limb reads 1, or 0 when both do. Specificity: the same reader keyed on a slug no record carries reads 0. The method names no ADR number, so the Stage-12 renumber cannot stale it, and after the claim the whole-token limb reads both files again |
| #6379 | AC-1..AC-5 | Per that card's own spoke. **AC-3 graded by the two restated limbs, never by the design's original command** — that command used `\|` under `-E` and returns 0/exit 1 on any input. **AC-5 graded as amended** per `D-Section152Pointer`, against the verbatim amended text in this plan's § Issue #6379 block. **AC-6 is now GRADABLE** — the record it grades exists at `core/ADRs/ADR-199-consumer-contract-is-tiered-and-unenforced.md` (`a62d7ae9`); see Deviation Log `D-13`, which carries this pointer's former identifier. **AC-3's limb (b) and AC-5's first limb carry Stage-7 verdict-method restatements** — the § Issue #6379 block states both readers and the failing case for each; what either criterion grades is not amended | AC-3: pointer count **0** in the schema (sensitivity, the same reader over the register → **59** at the tip, the 58 recorded pre-merge having moved with mainline) and **no rule id minted in either namespace** — every `PACK-*` / `PACKC-*` id the schema cites, in all three citation forms, is registered in the validator's rule-id tuples; unregistered set **∅** (28 cited, 28 registered; sensitivity, subject plus a synthetic `PACKC-Z99` → 1 unregistered). AC-5: the § 1.5.3 gap-count line is byte-identical between the merge base and the tip, 1 on each side (sensitivity, the phrase reads 1 per side; the sentence the original limb named reads 0 on both, which is why it is re-pointed), and the § 1.5.2 pointer the operator decision permits is untouched by this card |
| #6367 | AC-1..AC-5 | Per that card's own spoke; AC-3 ("reachable from the kit") graded against `D-StandardHome` option (C) | The rubric names no kind; the per-kind content stays in the packs |
| #6368 | AC-1..AC-5 | Per that card's own spoke; the depth read is graded over the **full realizer set** per CD-1 | The middle branch reads a non-empty domain: 4 `criteria.gate` + 2 `fields` block-level `source` carriers |
| #6369 | AC-1..AC-5 | Per that card's own spoke; admission is graded as a **predicate over each check's own `automatable` flag**, never as a count carried from this plan. See § Issue #6369 for the withdrawal of *"5 + G, never 7"* and the amended `INT-1` / `INT-2` | The admitted set re-derives from the shipped packs at grading time — **6** at this tip, **5** at the card's own commit, and the predicate is unchanged across that move |

**AC baseline** — per-issue acceptance-criterion counts as read at plan time.

`ac_baseline: { #6364: 4, #6379: 5, #6367: 5, #6368: 5, #6369: 5, read_at: a30838589583bcddf5f88183cfff1a8ea2475300 }`

### Cross-Issue Acceptance Criteria

Four CIACs. Each spans ≥2 issues, asserts a cohesion constraint the integrated release must hold, and is graded at Stage 9 QC3.5 on the merged PR.

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#6364 × #6367 × #6369 on the L3-judgment verdict):** the verdict #6364 records is cited by identifier in both consumers, and the two consumers agree on it — #6367 marks each rule enforceable-or-guidance per that verdict, and #6369 handles judgment checks per that same verdict. A release in which the two consumers assume opposite verdicts is the incoherence this grades. *Method:* `git grep -l "ADR-197" -- core/standards core/packs operations/skills/delivery-engine` must return the #6367 artifact **and** the #6369 artifact. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#6367 × #6368 on depth guidance):** the depth guidance #6367 authors is the guidance #6368 elicits against — the elicitation surface cites the standard's per-kind depth rules by name rather than restating them. A restatement is a second source that rots. *Method:* `git grep -n "depth" -- operations/skills/intake-desk/references/elicitation-loop.md` returns at least one citation resolving to #6367's authored home, and the doc-link checker resolves it. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#6368 × #6369 on the no-kit-resolved path) — WIDENED:** both consumers handle an unresolved kit **explicitly and identically in kind**, **and the middle arm of each consumer's branch is demonstrably reachable on shipped content.** Declaring the same branch shape is not sufficient: a middle arm exercised 0 times over the shipped population is an inert mechanism that reads as a working one, which is the vacuous-pass class this release exists to eliminate. *Method:* for each of the two skills, (a) the fixture demonstrating the unresolved-kit path emits a caveat/report string, `grep -c` over each fixture's expected output returns ≥1; **and (b) the middle arm's read domain, evaluated against the shipped `core/packs/` content, is non-empty — state the population enumerated and the count of shipped items that reach that arm.** For #6368 the realizer set per CD-1 is the 6 block-level `source` carriers (4 in `criteria.gate`, 2 in `fields`); a count of 0 over 8 blocks is a FAIL, not a pass. **Null-arm:** the paired control is a *resolved*-kit run on the same fixture harness, which must emit **zero** caveat strings — same instrument, same target. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#6379 × #6368 × #6369 on the consumer contract):** every place #6379's verdict names as requiring a consumer to special-case a project is either handled by both consumers or recorded as deferred with its revisit trigger — no named special-case is silently unhandled. *Method:* enumerate the special-cases named in #6379's recorded verdict and check membership against a handling citation in both consumer surfaces or a deferral row. **A null result carries its arms:** if the verdict names zero special-cases, state the population enumerated (the ≥2 resolved configurations tested) rather than reporting a bare "none". *Graded at Stage 9 QC3.5 on the merged PR.*

### Release-Level Verification

- [ ] File Integrity
- [ ] Content Correctness
- [ ] Cross-Reference Validity — `core/deploy/deploy.sh --check` Check 14 doc-link integrity
- [ ] Skill Invocation
- [ ] Output Contract Compliance
- [ ] Skill-package freshness — resolve the change set against the roster via `build-skill-packages.sh --skills-for-paths` reading repo-relative paths **on STDIN, not argv**
- [ ] ADR index: **N/A — this release adds no record under `release/ADRs/`.** Its ADRs are core-scope, and `core/ADRs/README.md` is a curated thematic document with no projector and no projected region, so no projection trigger exists to trip.

## Stage Applicability Matrix

Default is all stages. Deviations are stated with rationale; none is silent (Survival element 6).

| Stage | #6364 | #6379 | #6367 | #6368 | #6369 |
|---|---|---|---|---|---|
| 5 — Solutioning | APPLY | APPLY | APPLY | APPLY | APPLY |
| 6 — Engineering | APPLY | APPLY | APPLY | APPLY | APPLY |
| 7 — Dev Testing | APPLY | APPLY | APPLY | APPLY | APPLY |
| 8 — QA / Acceptance | APPLY | APPLY | APPLY | APPLY | APPLY |
| 9 — Plan Review | APPLY (release-scoped, **Deep**) | ← | ← | ← | ← |
| 10–11 | compressed (git-native) | ← | ← | ← | ← |
| 12 — Execute | APPLY (release-scoped) | ← | ← | ← | ← |
| 13 — Close | APPLY (release-scoped) | ← | ← | ← | ← |

**No stage is skipped anywhere in this bundle**, and that is the discriminating output rather than a default: `size:S` #6364 would ordinarily be a Stage-5 SKIP candidate and is explicitly not one, because its risk is concentrated in the experiment design — a badly designed reproducibility test yields an unreproducible verdict that then mis-routes 21 of 26 checks.

## Hub-Rendered D-Decisions

| # | Decision | Verdict |
|---|---|---|
| **D-ReleaseClass** | Release Class | **`cross-cutting`**, dominant trigger (c) — 4 in-bundle compositional edges. Posture: Tight / Deep / ALL / 30-day |
| **D-StandardHome** | Where #6367's per-kind authoring standard lives | **Option (C) — the cleave**: archetype-invariant rubric in `core/standards/` naming no kind, per-kind content staying in the packs. The only option conforming to the methodology-neutrality decision **and** avoiding `_common`-layer duplication |
| **D-Version** | Version | **Recorded determination.** Bump class `minor`; provisional `v4.61` from anchor `v4.60`; re-verified free at Engineering Commit 0 on the tag arm; binds at the Stage-12 atomic claim |
| **D-Concurrency Posture** | Execution posture | **P0 fully-serial, single-branch topology** |
| **D-CollectiveReview** | Scope-lock on the five-design set | **LOCKED.** Engineering authorized. Both structural findings routed **Tier-1 [ADJUST]** to their Engineering spokes — every reviewer stated its findings are reachable inside the existing design shape. Scope unchanged at five cards |
| **D-Section152Pointer** | The one-clause pointer into `work-item-type-schema.md` § 1.5.2 | **TAKE IT**, and **amend #6379's design AC-5** in the same decision. This diverges from both the #6367 spoke's recommendation and the hub's; breaking a sibling card's acceptance criterion is a release-scope call, and the operator made it |
| **D-Ciac3** | `CIAC-3` middle-arm divergence | **BOTH** — widen #6368's read domain per its own CD-1, **and** widen the criterion to grade middle-arm reachability. Fix the design and strengthen the check that would have caught it |

**Why AC-5's amendment is recorded here and not edited into the design.** #6379's AC-5 lives in a published Stage-5 comment. Edit history on a public repository is permanent and unscrubable, so the amendment is recorded as a decision and carried into this plan file at Commit 0 — never by rewriting the comment. **Grade AC-5 against this row, not against the published comment.**

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #6364 | `git revert <commit>` | Low — one added ADR plus two surgical edits |
| #6379 | `git revert <commit>` | Low — two additive edits |
| #6367 | `git revert <commit>` | Low — one added standard plus a README bullet |
| #6368 | Forward fix preferred | Medium — skill + package artifacts move together |
| #6369 | Forward fix preferred | Medium — skill + package artifacts move together; `gate-definitions.md` is a consumed contract |

### Whole-Release Rollback

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated issue failure pre-merge | Revert the card's commits on the release branch |
| **Full Restore** | Systemic failure post-merge | Revert the merge commit. The release tag is **retained, not deleted** — a version tag records that the version was claimed, and a rollback is recorded rather than erased |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch |

**Wave-level granularity is available pre-merge:** waves 1 and 2 produce corpus-only changes under `core/`; wave 3 produces skill + package changes. A wave-3-only rollback is a partial revert of the branch before merge, never after.

## Operational Deployment Manifest

| # | Source (Layer 1) | Target (Layer 2) | Mechanism | Verification |
|---|-----------------|-----------------|-----------|-------------|
| 1 | `operations/skills/intake-desk/**` | installed skills tree | S-2 direct copy via `deploy.sh --deploy intake-desk` | `deploy.sh --check` reports no drift |
| 2 | `operations/skills/delivery-engine/**` | installed skills tree | S-2 direct copy via `deploy.sh --deploy delivery-engine` | `deploy.sh --check` reports no drift |
| 3 | `packages/intake-desk.skill` + `.sha256` | package surface | `build-skill-packages.sh intake-desk` | Check 7 package-drift clean |
| 4 | `packages/delivery-engine.skill` + `.sha256` | package surface | `build-skill-packages.sh delivery-engine` | Check 7 package-drift clean |

**Deliverable state.** #6364 and #6379 are **task-class** — `artifact-accepted`; their definition of done is the artifact at its declared canonical path, and they produce no deployed copy. #6367 is `artifact-accepted`. #6368 and #6369 are deployable-class — `deployed-copy-synced`.

### Schema Migrations (if applicable)

N/A — enumerated over the three classes a migration could take in this release (entity-field schema changes, EAD-materialized machine-schema regeneration, pack-manifest grammar widens); none is present. The `level` domain stays `{L1, L2, L3}` and step 5 keeps exactly three by-level arms, so no projection arm is added or removed.

## Verification Evidence

(Populated by each Engineering spoke as its slice lands; completed before the PR is transitioned to ready at Stage 9.)

#### #6364 — L3-judgment evaluability · amended AC-1..AC-3 (`PA-003`) · `deliverable_state: artifact-accepted`

Graded at Engineering Pass 2 against the amended criteria in § Issue #6364, on the record carrying the Pass-2 fix. Every result carries a sensitivity arm observed non-zero and a falsification arm under which the verdict method fails; the matchers that could over-match also carry a specificity arm observed zero. The acceptance verdict itself stays with Stage 8.

| Assertion | Method | Result | Arms |
|---|---|---|---|
| **AC-1** runnable limb — one literal violating delta per binding | the AC-1 row's slug-keyed `grep -rc` under the plan executor | **21**, `== 21`, PASS | falsification: the same executor over a scratch root whose record copy lacks one `Delta:` line → **20**, FAIL. The slug include pattern selects exactly **1** file |
| **AC-1** structural limb — the binding set is the census frame | TOML parse of both pack manifests, every `checks` array at any depth; A.4 binding headers parsed from the record | frame **21** at the baseline and at the tip, identical sets — the tip's added `kanban-gate-wip-pull-limit` is `L2` with `automatable = true`, outside the frame. Bindings **21**: **0** missing, **0** extra, **0** duplicate; every base token resolves to an A.3 block, and every block is named in § Provenance | sensitivity: **21** binding headers parsed, equal to the **21** `Delta:` lines inside A.4, and **8** A.3 header lines read both ways. Census controls: `level = "L4"` → **0**; an injected synthetic `L3` check grows the frame by **1**. Falsification: dropping a binding → missing **1**; binding the out-of-frame `dor-epic-valuable` → extra **1**; a base token with no block → unresolved **1** |
| **AC-1** record limb — runs executed against the pinned instrument, its limitations stated | count the `## Limitations of the instrument as run` heading and the executed-against-the-pinned-instrument statement | **1** and **1** | on the record as it stood before this fix the heading reads **0**, so the amended AC-1 grades **FAIL** there and **PASS** here |
| **AC-2** runnable limb — `G` is `NOT-EVALUATED`, not 0 | the AC-2 row's `grep -rc -F` under the plan executor | **1**, `== 1`, PASS | falsification: the scratch-root copy without the statement → **0**, FAIL |
| **AC-2** absence limb | read Results, Layer B | the per-check counts, statistics and verdicts recorded **absent**, not null — **1**; a consumer must branch on the state before reading a count — **1** | falsification: deleting either sentence reads **0** |
| **AC-2** not-asserted limb — no `G` value or bound, no agreement figure | the AC-2 row's five-pattern matcher; lines naming agreement that carry a percentage or an `N of M` figure | **0** and **0** | sensitivity: the bound matcher over the second-round hub aggregation → **1** line, over the hub's closure record → **2**; the figure matcher over the aggregation → **2**; a record copy carrying the withdrawn bound → **1**. Specificity: a sentinel → **0**. Pattern self-test: **5** of 5 positives matched and **5** of 5 negatives rejected — including `G ≥ 1` and `G = 0 (measured)`, the Routing Rule's own branch labels |
| **AC-3** runnable limb — both consumers take the conservative branch | the AC-3 row's `grep -rc -F` under the plan executor | **1**, `== 1`, PASS | falsification: the scratch-root copy with the statement reworded → **0**, FAIL |
| **AC-3** per-consumer limb | read § Routing Rule | the authoring bar's enforceability dimension *declared and unresolved* — **1**; the gates *admit no judgment-level check* — **1** — and *report* the remainder — **1** | falsification: removing either consumer's clause reads **0** |
| **AC-3** no-disposition limb | lines pairing a frame check id with `gate-capable` or `advisory-only` | **0** | sensitivity: frame ids occur on **24** lines and disposition tokens on **14**, so both readers fire; a record copy pairing one id with `gate-capable` → **1** |
| The plan executor reads the amended rows | `verify-release-plan.sh`, default mode (no event write) | #6364 AC-1..AC-3 move **ERROR → PASS** (per-issue family, counts **21** / **1** / **1**); AC-4 stays **SKIP**. Roll-up **9 / 1 / 5 / 8 → 12 / 1 / 5 / 5** PASS / FAIL / SKIP / ERROR; the one FAIL is `FCM-5`, #6369's fixture path, unchanged | against the mutated scratch root the same three rows read **FAIL** — **20**, **0**, **0** |
| AC binding held | `check-ac-binding.py` before and after, three modes | `--ordinals-only` and `--fetch`: whole output byte-identical; #6364 coverage **1,2,3,4** of 1–4, no gap. With the four completion conditions supplied as the oracle, **4** of 4 `BOUND` before and after, each amended row binding on more of its criterion's discriminative terms — AC-1 **6** against 2, AC-2 **6** against 3, AC-3 **6** against 5 | self-test **33** cases, **0** failures. `--fetch` withholds #6364 as `NOT-EVALUATED`, because the issue states its criteria under *Completion condition (verifiable)*, a heading the oracle reader does not recognise — a pre-existing oracle gap this edit does not touch |

**AC-4 — verdict method restated at Engineering Pass 2b (`AI-046`).** Graded on the record carrying the Pass-2b wording fix. The runnable limb was run exactly as the row prints it, transcribed from the row rather than retyped.

| Assertion | Method | Result | Arms |
|---|---|---|---|
| **AC-4** runnable limb — both consumer artifacts cite the record | the row's `grep -lF` limb under `/usr/bin/grep`, and the same row under the plan executor | **2** — the #6367 standard and the #6369 gate definitions, and only those. The executor reads `count=2 (== 2)`, PASS, where it read SKIP before: the planned method called `git`, which the executor does not run | falsification: a scratch copy with #6369's token removed → **1**, and the executor over it reads FAIL; with #6367's links to the record removed → **1**; both removed → **0**; an unmutated scratch copy → **2**. Specificity: a slug no record carries → **0**, and it occurs nowhere in the tree |
| **AC-4** across the Stage-12 claim | the claim simulated on scratch copies: the record renumbered, #6369's token stamped by the renumber tool's own stamp function | the runnable limb reads **1** once the token is stamped, which is why the post-claim limb exists; the post-claim limb, N read from the one filename carrying the slug, reads **2** at the current number and at a renumbered one | after a renumber, the old number reads **0** over the two artifacts |
| The executor roll-up and its JSON | `verify-release-plan.sh`, default mode and `--format=json` | roll-up **12 / 1 / 5 / 5 → 13 / 1 / 4 / 5** PASS / FAIL / SKIP / ERROR over 8 per-issue rows, AC-4 the only verdict that moves; AC-1..AC-3 still read **21** / **1** / **1**. The JSON now **parses**, 23 records | on the plan as it stood before this edit the same parser rejects the output at AC-4's record, where the double quote in the old expected cell broke it |
| AC binding held | `check-ac-binding.py`, three modes | `--ordinals-only` and `--fetch`: whole output byte-identical; #6364 coverage **1,2,3,4** of 1–4. With the four completion conditions as the oracle, AC-4 stays `BOUND`, now on **2** discriminative terms against **1** | self-test **33** cases, **0** failures |

#### #6368 — elicit to the resolved kit's depth · `deliverable_state: deployed-copy-synced`

Landed at `0c2b4dcd`, three files — `operations/skills/intake-desk/references/elicitation-loop.md` plus the package and its `.sha256` sidecar. Every count below carries a sensitivity arm observed non-zero on the same instrument; the depth-read population carries a specificity arm observed zero.

| Assertion | Method | Result | Arms |
|---|---|---|---|
| The criteria facet is read as an elicitation input | `probe_p2b.py` over the 6 intake-desk files / 144,090 B | **0 → 3** | sensitivity: the `fields` facet, which is read today → **4**. specificity: pack-internal tokens no consumer names → **0**, over a population shown to carry the bare-`criteria` near-miss **31** times |
| The depth read's realizer set is non-empty on shipped content (`CIAC-3` limb b) | `probe_packs.py` over 3 pack manifests / 33,124 B, walking every `[kinds.criteria.*]` and `[kinds.fields]` table | **6 of 6** — 4 `criteria.gate` + 2 `fields`, `criteria.gate` present on all 4 shipped kinds | sensitivity: blocks whose array is present-and-**populated**, same walker → **10**. specificity: a bogus facet name → **0** |
| The depth rule is cited, not restated; the target resolves | `git grep` for the standard's path + `test -f` | **3** citations; target present | sensitivity: `test -f` on an absent standard → correctly absent |
| The caveat has one emission site and no sibling token is minted | `git grep -c` on the token; `git grep -nE` for a minted `[depth-*:` / `[elicitation-*:` sibling | **1** site; **0** minted | sensitivity: the sibling `methodology-pack:` caveat → **1**. specificity: a bogus caveat token → **0** |
| The over-definition rule's identifier survives | `git grep -F` over the skill tree | pre **3** / post **3** | sensitivity: a phrase certainly present → **43**. specificity: a bogus variant of the phrase → **0** |
| The clarity gate, the 5-test, the stop condition and the three altitude bullets are byte-unchanged | `probe_ac7.py` section-hash, base vs branch | **IDENTICAL** on all four | sensitivity: the Phase-3 section, deliberately edited, on the same hasher → **CHANGED** |
| Package freshness | `deploy.sh --check-package-freshness` | 55 rostered packages content-fresh — OK | — |

#### #6369 — gates against resolved kit criteria · `deliverable_state: deployed-copy-synced`

Landed at `00252ad0`, six files — `operations/skills/delivery-engine/SKILL.md`, `references/gate-definitions.md`, `references/gate-checklists.md`, the new `evals/fixtures/resolved-kit-criteria.md`, plus the package and its `.sha256` sidecar. Every zero below carries a sensitivity arm observed non-zero on the same instrument; the claims that turn on a pattern discriminating additionally carry a specificity arm observed zero.

| Assertion | Method | Result | Arms |
|---|---|---|---|
| The criteria facet is read as a gate input (**AC-1** limb 2) | `git grep -oE 'criteria\.(readiness\|done\|gate)'` over the delivery-engine tree, base vs branch | **0 → 20** across 4 files | sensitivity: `NO-EVIDENCE` over the same population at `origin/main` → **9 + 8**, so the base zero is a measured absence. specificity: a facet name that does not exist → **0** |
| §4.3's predicate names no kind (**AC-1** limb 1) | `git grep -n -wE 'epic\|story\|task\|card'` over `gate-definitions.md` | **2**, unchanged from base — the `H1` handoff row and the frozen `1.1` history row, neither a governing example; **§4.3 itself contributes none** | specificity: the design's **escaped** form `epic\\\|story\\\|…` → **0 / exit 1**, and `'H1\*\* \\\| Design'` → **1**, which proves `\\\|` under `-E` is a **literal pipe**, not alternation. The escaped form is an inert probe and was not used |
| The three outcomes are present and the middle arm does not fall back (**AC-2**) | read the branch table | **3** rows; middle row carries *do not substitute a generic set* and *emit no unresolved report*; cites `work-item-type-schema.md` §1.2.1 *Content provenance* **2×** | — |
| The `NO-EVIDENCE` / `NOT-EVALUATED` distinction, the report's three required fields, and the not-a-verdict statement (**AC-3**) | read §4.3 | all three present as requirements | specificity: a phrase asserting a fourth verdict value → **0** |
| The `[LG-N-EX-k]` blocks, the §4.1 verdict set and §4's five steps are intact (**AC-4**, narrowed per `CD-3`) | `grep -c` + diff against `origin/main` | LG-4-EX **6** · LG-5-EX **7** · all gates **54** · verdict values **3** · §4 steps **5**, numbered `12345`; **0** changed `[LG-N-EX-k]` criterion lines | sensitivity: **71** changed content lines in the same file, so the zero is attributable. specificity: `LG-99-EX` → **0**. The **9** removed lines are enumerated and all intended; `:293` / `:297` / `:299` are byte-identical and the `(§4 step 3)` / `(§4 step 4)` citations survive (**2**) |
| The unresolved path's verdict is unchanged and says so once (**AC-5**) | `git grep -c -F "NOT-EVALUATED"` over the delivery-engine tree | **0 → 21** lines across 3 files; fixture Case C declares exactly one emitted line | sensitivity: `NO-EVIDENCE` over the same population → **9 + 8** at base |
| The fixture demonstrates a failure on a real shipped criterion (**AC-6**) | read the fixture; resolve every named check id in `core/packs/` | **3** cases; **6 of 6** named ids resolve in the shipped Scrum manifest; Cases A and B declare **zero** caveat strings, Case C **one** | specificity: an invented id `dor-story-invented` → **0** |
| No new verdict value, report token or register row (**AC-7**) | `git grep -nE '\[(depth\|kit\|criteria)-[a-z]+:'`; `grep -c "runner-def:"` | bracketed tokens **0**; §4.1 still **3** values; `runner-def:` **48**, unchanged | sensitivity: the same bracketed-prefix matcher on `[LG-N-EX-` → **57** lines, so the shape is live |
| Count preambles reconcile; no baseline row added (**AC-8**) | `check-count-structure.py` (Check 63, **ENFORCING**) on the 3 edited docs and again on the fixture | `FAIL=0 KNOWN=0 STALE=0`, exit 0 on both runs | controls PASS on every run — sensitivity examined=1 flagged=1, specificity examined=1 flagged=0; self-test controls PASS first. Baseline rows for delivery-engine: **2**, unchanged (both `estimation-standards.md`) |
| Package + sidecar rebuilt in the same commit (**AC-9**) | `deploy.sh --check-package-freshness`; Check 7 | 55 rostered packages content-fresh — OK, exit 0 | — |
| Audit-trail trailer + version field (**AC-10**) | `deploy.sh --check` Check 10; Check 6 | **`OK: delivery-engine (00252ad0b70a)`**; Check 6 `OK: delivery-engine` | the `version:` bump is **held**, not skipped — see Deviation `D-10` |
| The write set is exactly the card's paths (**AC-11**) | `git diff --cached --name-only` | **6** paths, **0** outside `operations/skills/delivery-engine/` and `packages/delivery-engine.*` | sensitivity: the same matcher counts the in-scope paths → **6** |
| No new issue or warn attributable to this change (**AC-12**) | `deploy.sh --check`, both runs | **0** WARN rows name any path this card wrote | sensitivity: **44** WARN rows total across the two runs. The 4 `delivery-engine` DRIFT rows are the operator-instance mirror class — 8 further DRIFT rows name other skills — and clear at the Stage-12 `--deploy`. **Check 47 (release-body drift, 13 findings) is pre-existing, not branch-introduced**: the whole branch changes **16** files and **0** under `release/releases/notes/` or `RELEASE_LOG.md`, so its comparison inputs are byte-identical to `origin/main` |
| **INT-1**, graded on its **amended** three-arm form — verbatim text in § Issue #6369, landed by `D-14` | read §4.3 against the record's Routing Rule; the record's own `G` state selects the arm | **MET on the `NOT-EVALUATED` arm** — the predicate consumes the disposition by identifier (**1** instance, prose-only); restates **0** per-check verdicts; admits exactly the `automatable = true` set and reports the remainder with its denominator. The `G ≥ 1` and `G = 0 (measured)` arms are unreachable while the record states `NOT-EVALUATED`, and are not graded | sensitivity for the no-restatement claim: the same id matcher over the **fixture** → **10** lines, so the rule-file zero is attributable. `CIAC-1` limb, re-keyed on the record's **slug** per `D-12`: the slug-keyed reader returns **both** artifacts (measured **2**); the **number**-keyed form it replaced returns **1**, and a slug no record carries returns **0** |
| **INT-2**, graded on its **amended** three-arm form — verbatim text in § Issue #6369, landed by `D-14` | read §4.3 beside the authoring standard's Enforceability subsection; the record's own `G` state selects the arm | **MET on the `NOT-EVALUATED` arm** — both take the record's third, conservative branch: admission keys on each check's own `automatable` flag, no judgment-level check is admitted, and both state the machine-evaluable layer as a **pointer to a declaration rather than a count**. The `G ≥ 1` (mixed) and `G = 0` (guidance) arms are unreachable and are not graded | specificity: §4.3 restates **0** admitted-check cardinalities; the same matcher over the record, which does state them → **1**. **Reader-graded by declaration:** no gate covers this pair, so the side-by-side reading is the verdict and carries no executor command |

**The kit census was re-derived here rather than taken from the brief**, with a structure-shaped parse over all 26 checks: `criteria.readiness` **15** (**5** `automatable = true`, all Scrum), `criteria.done` **11** (**0** — admits zero, always), `criteria.gate` **0** populated. Kanban carries **0** admitted on either side. Cross-tab `(L3,false)=19 (L1,true)=4 (L2,false)=2 (L2,true)=1` matches the record's own `source_observations:`. Control arm: **0** malformed rows of 26 parsed. Reasoned-empty carriers: **6** — 4 `criteria.gate` + 2 `fields` — with **10** populated blocks correctly excluded and **0** empty blocks lacking a block-level `source`.

### Artifact-Acceptance Record

**Mode: ADDITIVE.** This release resolves deployable-class — it ships skill and package changes — and *also* declares task-artifact deliverables, so the record rides alongside the deployable close path rather than substituting for it. One row per declared task-artifact deliverable.

| `deliverable` | `canonical_path` | `landing_commit` (in order; the acceptance review reads the **last**) | `acceptance_verdict` | `acceptor` |
|---|---|---|---|---|
| #6364 — criterion evaluability recorded as a per-check measured property | `core/ADRs/ADR-197-l3-judgment-criteria-evaluability.md` — **path-at-commit:** `core/ADRs/ADR-195-l3-judgment-criteria-evaluability.md` at the first three commits, renamed to `ADR-197-…` **by** `90097600` and carrying that path from there on | `01e61c8b` · `4c4d33af` · `c7c77ce7` · `90097600` · `2ab1d271` · `e896a806` | **PENDING** — rendered at the Stage-8 acceptance review, ratified at the Stage-9 gate | Stage-8 acceptance review → operator at Stage 9 |
| #6379 — consumer contract for the resolved kit (the reading rule itself) | `core/schemas/work-item-type-schema.md` § 1.5.8 *What a consumer may assume — the reading rule* (with the F3-row and § 1.2-`criteria`-row extensions in the same file) | `592715c9` · `1c31f69f` | **PENDING** — rendered at the Stage-8 acceptance review, ratified at the Stage-9 gate | ↑ |
| #6379 — the tiered-contract decision record (design `FC-5`) | `core/ADRs/ADR-199-consumer-contract-is-tiered-and-unenforced.md` | `a62d7ae9` | **PENDING** — as above | ↑ |
| #6379 — F3's kind-to-label limb registered in the gate-coverage register (design `FC-4`) | `core/standards/gate-efficacy-standard.md` — the existing **F3** row, extended in place | `ca3414ce` | **PENDING** — as above | ↑ |
| #6367 — per-kind authoring standard | `core/standards/work-item-authoring-standard.md` | `2902776d` · `90097600` · `f8f8f22f` | **PENDING** — as above | ↑ |
| #6367 — the bar-is-a-reading-not-a-carrier decision record | `core/ADRs/ADR-198-per-kind-authoring-bar-is-a-reading-not-a-carrier.md` — **path-at-commit:** `core/ADRs/ADR-196-per-kind-authoring-bar-is-a-reading-not-a-carrier.md` at `2902776d`, renamed to `ADR-198-…` **by** `90097600` and carrying that path from there on | `2902776d` · `90097600` · `f8f8f22f` · `2b493217` | **PENDING** — as above | ↑ |

**`acceptance_verdict` is PENDING by construction at Stage 6, and is not self-certified here.** Engineering lands the artifact and records where it landed; the verdict is rendered by a gate Engineering does not sit on. A spoke writing `ACCEPTED` against its own deliverable would be self-referential validation, and the Stage-13 gate that reads this block would then be reading Engineering's own opinion of its own work. The row is populated with the facts a later gate needs — the path and the landing commit — and the verdict cell names the gate that owes it.

**`canonical_path` verification at Stage 6 is branch-side.** The Stage-13 check resolves each path against the mainline; pre-merge that read cannot succeed by construction, so the Stage-6 assertion is that the path resolves on the release branch at the stated landing commit. The mainline read is the Stage-13 gate's own, and is not pre-claimed here.

**A deliverable amended after it lands carries every commit it spans, in order, and the acceptance review reads the last of them.** Recording only the first would point a later gate at a superseded revision of the artifact it is grading — the record would resolve, and resolve to the wrong bytes, which is the failure mode a landing commit exists to prevent.

**A commit-pinned path breaks across a renumber, so two rows carry a `path-at-commit` clause.** This release renumbered its own two ADRs at `90097600` (`195 → 197`, `196 → 198`) per § ADR number allocation. A row pinning today's `ADR-197-…` path against `01e61c8b` therefore names a path that **did not exist at that commit** — the reader gets nothing and concludes the artifact is missing. The rule above compounds it in the other direction: a reader following *"read the last listed commit"* while resolving the *first* listed path lands on a revision predating every Stage-7 fix and fails a correct card. Both rows are pinned per commit segment rather than globally, so **every listed commit resolves at the path stated for it**, and the last-listed commit — `e896a806` for #6364, `2b493217` for #6367's record — resolves at the current path. The alternative considered and rejected was listing only post-renumber commits with a note: it resolves, but it discards the three pre-renumber amendments from the audit trail, which is the span the rule above exists to preserve.

**Row-set reconciliation, recorded rather than silent.** This block opened with three rows and now carries six. #6379's design rows `FC-4` and `FC-5` were **held** by the Stage-6 spoke and subsequently **authorized by the operator and delivered** (`ca3414ce`, `a62d7ae9` — see Deviation Log `D-13`), and #6367's ADR was never given a row of its own. Each is a task-class artifact at a declared canonical path, so each earns a row: the Stage-13 close-class gate reads this block for its task-artifact branch, and an artifact that landed without a row here is an artifact that gate cannot see. Every commit listed above was re-derived at the tip by walking the branch's own `--name-status` log rather than transcribed from a brief; `fcdd1815` appears in no row because it is an **empty** commit (a sanctioned-session attestation) and lands no artifact, and the two `origin/main` sync merges (`3ac98fac`, `193bb420`) appear in none because they land no artifact of this release either.

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

## Change Description

### Outcome

This release makes the shipped methodology packs *readable to depth* by the two consumers that already resolve them. The packs currently declare 26 criteria checks and 8 field declarations that nothing reads: the intake surface asks for a kind's field list and never its depth guidance, and the delivery gates evaluate a static checklist rather than the resolved kit. The release answers the prior question first — **can a judgment-level criterion be evaluated reproducibly at all?** — records that answer as a per-check measured disposition, authors the per-kind authoring bar the answer licenses, and then teaches both consumers to read it.

### Issues resolved

| # | Outcome (one line) | Status |
|---|---|---|
| #6364 | Criterion evaluability is recorded as a per-check measured property with a stated admission rule, not inferred from the check's level | **DELIVERED** — `01e61c8b` · `4c4d33af` · `c7c77ce7` · `90097600` (renumber) · `2ab1d271` · `e896a806`. The record states `G` as `NOT-EVALUATED`, not `0`; AC-1..AC-3 amended per `PA-003` (`D-11`), AC-4's method restated (`D-12`) |
| #6379 | The consumer contract for a resolved kit is stated, with any deferred part and its revisit trigger named | **DELIVERED** — `592715c9` · `1c31f69f` (the § 1.5.8 reading rule) · `ca3414ce` (F3's second limb in the gate-coverage register) · `a62d7ae9` (the decision record). The two design rows held at Stage 6 were authorized and landed; see `D-13` |
| #6367 | A per-kind authoring bar ships as an archetype-invariant rubric that names no kind, with per-kind content staying in the packs | **DELIVERED** — `2902776d` · `16aaceba` (the § 1.5.2 pointer, per `D-5`) · `90097600` (renumber) · `f8f8f22f` · `2b493217`. The standard took the record's third, conservative branch (`D-8`) |
| #6368 | Intake elicits to the resolved kit's declared depth, reading the full realizer set rather than two blocks of it | **DELIVERED** — `0c2b4dcd` · `d2276131`, three files each time (`references/elicitation-loop.md` + the package and its `.sha256`). Three declared plan-matrix paths held, not delivered; see `D-9` |
| #6369 | Delivery gates evaluate the resolved kit's criteria, admitting only checks measured admissible and reporting the rest explicitly | **DELIVERED** — `00252ad0` · `eceffd2e` · `e2f8919c`, with `fcdd1815` the (empty) sanctioned-session attestation for `eceffd2e`. Fixture name and one CONDITIONAL row diverge from the matrix; see `D-10` |

**`DELIVERED` is a state about the artifact, not a verdict about it.** It says Engineering landed the change at the commits named and nothing in the write set is outstanding. The acceptance verdict is Stage 8's and the ratification is the operator's at Stage 9 — the same separation the § Artifact-Acceptance Record block states for `acceptance_verdict`. A cell reading `(pending)` after every card's content had landed was under-reporting the first without conceding the second; these cells report the first and still concede the second.

### Key decisions

- **D-StandardHome:** option (C), the cleave. The rubric is archetype-invariant and names no kind; per-kind content stays in the packs. The only option that conforms to the methodology-neutrality decision and avoids duplicating the rubric per pack.
- **D-Ciac3:** both halves — widen #6368's read domain, and widen `CIAC-3` to grade middle-arm **reachability on shipped content** rather than mere branch-shape agreement.
- **D-Section152Pointer:** take the § 1.5.2 pointer and amend #6379's design AC-5 accordingly; the amendment is recorded in this plan, never by editing the published design comment.

### Reversibility

**MODERATE — HIGH confidence.** Single release branch, single PR, one revertible merge commit. The expensive half is architectural rather than mechanical: `core/packs/` becomes a live read contract the moment #6368 and #6369 land, so the grammar the standard adds is what becomes expensive to change later — which is why Stage 9 review depth is Deep.

### Downstream impact

- The recorded evaluability disposition is the input any future readiness-gate work reads before admitting a judgment-level check to an ANY-FAIL criterion set.
- `core/packs/` crosses from a declarative manifest to a consumed contract.
- Two skill packages are rebuilt; the deploy-time package-drift check is the backstop, not the rebuild.
- One named gap is carried forward rather than closed: nothing validates the `criteria` check shape, so a recorded disposition is only as trustworthy as that absent runner.

### Cross-references

- Release plan: this file
- Milestone: `authoring-bar-and-consumers`
- User-facing release notes: authored at Stage 13 Close per [`release-notes-standard.md`](/release/references/standards/release-notes-standard.md)

## Deviation Log

| # | Deviation | Card | Rationale |
|---|---|---|---|
| D-1 | The Stage-4 matrix's two `core/packs/{scrum,kanban}/pack.toml  edit` rows for #6367 are **NOT DELIVERED** as edits and move to the read-only block | #6367 | #6367 reads the packs and does not write them. Recorded per the declared-vs-delivered authoring contract so the declared ADD/EDIT set matches the merged diff |
| D-2 | The Stage-4 matrix's two `D-StandardHome` option-(D) CONDITIONAL rows (`core/packs/{scrum,kanban}/authoring.md  add`) are **NOT DELIVERED** | #6367 | Their condition resolved false: the operator rendered option (C) at the Stage-4 gate. The option-(C) row is promoted to unconditional in this same commit |
| D-3 | `core/schemas/work-item-type-schema.md` gains #6379 as a second claimant, replacing the Stage-4 record of #6367 | #6364, #6379 | #6367 carries no claim on the path; the real contention is intra-wave and is resolved by `AI-008` rather than by wave order |
| D-4 | The Stage-4 row's `core/references/reference/work-item-type-consumer-map.md  edit` for #6379 is **NOT DELIVERED** | #6379 | The design routes the map's staleness (`DR-1`: executable denominator 244 → 264) to a next-release issue. The map is a **measured** artifact with its own reproduction procedure; re-stamping it is its owner's scoped act, not a side effect of a spike that happens to read it |
| D-5 | `core/schemas/work-item-type-schema.md` § 1.5.2 is **EDITED** by #6367, and #6379's AC-5 byte-unchanged range is amended to name § 1.5.2 as a third exception | #6367, #6379 | Operator decision `D-Section152Pointer` at Collective Review, which **diverges from both the #6367 spoke's recommendation and the hub's**. The spoke recommended default-NO and declined to decide unilaterally, on the grounds that breaking a sibling card's acceptance criterion is a release-scope call; it is, and the operator made it. Recorded here rather than by editing the published Stage-5 comment, whose edit history is permanent and unscrubable |
| D-6 | `core/ADRs/ADR-197-l3-judgment-criteria-evaluability.md` is **EDITED** by the #6367 spoke, in a commit of its own | #6364 (artifact), #6367 (actor) | Tier-1 [ADJUST] `AI-014`. Check 63 (count-vs-structure, ENFORCING, no mode gate) was FAILing on this branch at a branch-introduced site: a contrastive cardinal naming the *rejected* design sat above the 2-item list that is the *accepted* one, and the lint read it as a stated cardinality. No CI workflow runs the full `--check` suite — Check 63 is deliberately off the `--check-required-subset` roster — so the release PR read green and this would have surfaced post-merge at Stage 12. Scope held to durability hygiene per the ADR authoring guide's carve-out; `## Status`, `## Alternatives Considered` and `## Consequences` asserted byte-identical by section hash. **Open item surfaced for Stage 9 and deliberately NOT decided here:** the renumber tool's dry run flags this row as needing a hand decision, because the row carries a literal `ADR-197` token in a branch-diff file **while mainline now also holds an `ADR-197`** — `renumber-adr.py --detect` at this tip reads `ANCHOR 197 (origin/main)`, `CLAIM ADR-197 … DUPLICATE MAINLINE next=200` — so the R3/R6 sweep cannot tell from the token alone which of the two records it cites, and that is exactly the case `--exclude-path` exists for. Re-derived at this tip: the plan carries **8** literal `ADR-197` tokens (specificity arm, a sentinel `ADR-99197` → **0**), and a read of all 8 finds every one citing **this release's** record, none citing mainline's — which is the input the decision needs, not the decision itself. **The handle is the row identifier `D-6`, not a line number:** earlier records placed this row at `:548`, the Dev Testing pass at `:588`, and it has moved again under this reconciliation. A line number is the one thing about this row guaranteed to be wrong by the time it is read |
| D-7 | #6367's design carried `duplicate-source-discipline.md` as the authority for the elicitation-side repoint, in three places | #6367 | **Withdrawn.** That standard excludes `<module>/skills/` from any scan-based enforcement **by name**, and the duplication in question spans `core/standards/` ↔ `operations/skills/…`. The obligation is real and is re-grounded on the charter's *Single-source-of-truth for knowledge* preference plus `CIAC-2`, adopting the correction a sibling card had already measured and recorded |
| D-8 | #6367's design branched its Enforceability content on `G ≥ 1` / `G = 0` | #6367 | Neither branch occurred. The landed record states `G` is **`NOT-EVALUATED`** — an absence of measurement, emphatically not a measured zero — and spells out a third, conservative branch for the authoring bar by name. The standard takes that branch: every dimension reads *unresolved pending measurement* for its judgment-level layer, declared rather than silently absent |
| D-9 | Three of the plan's six § File Change Matrix rows for #6368 are **NOT DELIVERED** — `operations/skills/intake-desk/SKILL.md  edit`, `operations/skills/intake-desk/references/type-map.md  edit`, and `operations/skills/intake-desk/evals/fixtures/kit-depth-divergence.md  add`. Held with reasons, not silently dropped | #6368 | The Stage-5 design refines the plan's change spec down to three paths and records each non-edit as a deliberate call, not an omission. **`SKILL.md`:** its cross-file reference names *the altitude-relative over-definition rule*, and that identifier is retained byte-identically, so the reference does not rot and no edit is owed — asserted pre 3 / post 3 on the same matcher. This also keeps the write set off the one file in this skill that the link and editor gates actually scan. **`type-map.md`:** not claimed, which preserves consumer-map rows `R8`/`R8b` and honours the decision this release has now taken twice not to reopen the consumer map. **The fixture:** the card's AC-4 is satisfied from shipped pack content — the Scrum and Kanban manifests already produce materially different elicitation for one request, including the reasoned-empty arm on Kanban `card` — so authoring a fixture file would add a second, divergeable copy of values the packs already declare. The design's own **AC-8** asserts the card's commit set is exactly the three delivered paths, so delivering the wider plan set would have failed the card's own acceptance criterion. **Consequence if the hold stands:** none measured — `CIAC-3` limb (a) grades "the fixture demonstrating the unresolved-kit path emits a caveat/report string", and the emission site is in the delivered file, not in a fixture; limb (b) is graded from the pack scan recorded in § Verification Evidence above. If the hub reads limb (a) as requiring a fixture *file*, that is a hub decision and the row is cheap to add |
| D-13 | #6379's design FCM rows **FC-4** (`core/standards/gate-efficacy-standard.md` F3 register-row extension) and **FC-5** (a new ADR recording the tiered-contract decision) were held by the Stage-6 spoke, then **authorized by the operator and DELIVERED** — `ca3414ce` extends the register's F3 row in place, `a62d7ae9` adds `core/ADRs/ADR-199-consumer-contract-is-tiered-and-unenforced.md`. Neither path is declared in the § File Change Matrix; both are recorded here and in § Artifact-Acceptance Record | #6379 | **This row was numbered `D-5` and is renumbered here**, because the identifier already belonged to the § 1.5.2 row above and #6379's per-issue verification row pointed at *"Deviation Log `D-5`"* — an ambiguous pointer resolving to two different deviations. Nothing about the deviation changed; only its identifier. **The hold's original ground:** the Stage-6 brief enumerated the write set as FC-1/FC-2/FC-3 landing in the meta-schema, and this plan's own Change Specification row named no register row and no ADR, so the spoke implemented the enumerated set rather than unilaterally widening its own authorization. **The disposition, rendered:** the operator authorized both rows after Dev Testing raised the hold, and both landed. The two consequences the hold named are therefore **closed rather than carried** — the schema's F3 `Posture` cell and the register's F3 row now both record two limbs, and **design AC-6 is gradable**, because the record it grades exists. `ADR-199` states its own late authorship in its `## Status` block rather than reading as contemporaneous |
| D-10 | Two of the plan's § File Change Matrix rows for #6369 diverge from what landed. The declared path `operations/skills/delivery-engine/evals/fixtures/kit-criteria-gate-failure.md` is **NOT DELIVERED** under that name — the fixture ships as `operations/skills/delivery-engine/evals/fixtures/resolved-kit-criteria.md`; and the CONDITIONAL row `core/schemas/gate-criteria-spec.md  edit` is **NOT DELIVERED**. The `version:` field in `delivery-engine/SKILL.md` is additionally **held at `v4.10`**, not bumped | #6369 | **The declared path is now written out in full on this row, and that is a binding fix rather than a wording one.** The executor's deviation matcher extracts every Deviation-Log line carrying the literal `NOT DELIVERED`, strips backticks, and then searches those lines for the **whole declared path** from the matrix row. This row previously named only the basename, so the search missed and `FCM-5` read `declared-add-not-delivered` — a FAIL — while its sibling `FCM-4`, covering #6368's renamed fixture under `D-9`, read `deviation-recorded` and PASSed on an identical deviation shape. The asymmetry was in the row's text, not in the deviation. **The matrix row is deliberately left as declared:** correcting it to the delivered basename would make this row's own first clause self-contradictory and would erase the declared-vs-delivered divergence that the authoring contract exists to record. **The filename** is the Stage-5 design's own `FC-6` value, and the design is authoritative where it and the plan differ. It is also the better name: the plan's name describes Case A alone, while the file carries one case per branch arm — the populated arm that FAILs on a real criterion, the reasoned-empty arm, and the unresolved arm. The card's **AC-6** names the directory, not the basename, so either name satisfies it. **The CONDITIONAL row's condition resolved false:** its trigger is `g1-g3-criteria-contract-changes`, and §4.3 *cites* `gate-criteria-spec.md` § Step 0 for the `NOT-EVALUATED` token while adopting it verbatim — no G1/G3 criterion is added, removed or re-worded, and no contract the spec owns moves. Editing it would have minted a second home for a token that already has one. **The `version:` hold is the same deferral the immediately-prior release recorded and then discharged at its Stage-12 claim.** `version-field-semantics.md` defines the field as the platform release tag **at edit time**, and this release is slug-primary / pre-claim — no tag exists to write, and hand-typing one would assert an identity the release has not claimed (ADR-092). Both gates that read the field are satisfied meanwhile: Check 10 reports `OK: delivery-engine (00252ad0b70a)` on the audit-trail trailer, and Check 6 passes on the `version:` format. **Consequence if the hold stands:** the field binds at the Stage-12 atomic claim, in the close-out commit that already rebuilds the package — a one-line edit plus a package rebuild, and the card's **AC-10** is gradable today on the trailer limb and gradable at Stage 12 on the bump limb. If the hub would rather bind it on this branch, it needs a claimed tag first |
| D-11 | #6364's **AC-1, AC-2 and AC-3 are AMENDED** to a three-arm form keyed on the record's own `G` state and graded on its `NOT-EVALUATED` arm. The verbatim amended text is in § Issue #6364; the per-issue verification rows carry the amended verdict methods | #6364 | Operator decision `PA-003` at Stage 7. As written, the three criteria presupposed a per-check Results table the record does not carry, so AC-3 was a universal over zero rows and could not fail. The shape mirrors `AI-018`'s amendment of #6369's INT-1 and INT-2 for the identical `G`-shape defect, and each amended criterion's verdict method returns a live, non-trivial result and fails under a stated mutation. Recorded here rather than by editing the published Stage-5 design comment, whose edit history is permanent and unscrubable |
| D-12 | #6364's **AC-4 verdict method is RESTATED** to key on the record's slug instead of its number. What the criterion grades — both consumer artifacts cite the record by identifier — is not amended | #6364 | Hub ledger `AI-046`, from Stage-7 Dev Testing. The planned method searched for the record's number, and #6369's artifact correctly carries none: per ADR-181 it cites the record through the slug token, which binds to a number only at the Stage-12 claim. The method therefore found one of the two citations and would have graded a correct build NOT MET. The number is also provisional, and two records hold it on this branch today, so no number-keyed method could survive the claim. The restated method names the two consumer artifacts, runs under the plan executor, and fails when either drops its citation. CIAC-1 carries the same number-keyed shape; re-keying it belongs to the release-wide plan reconciliation (`AI-051`), not to this row |
| D-14 | #6369's **`INT-1` and `INT-2` are AMENDED** to a three-arm form keyed on the record's own `G` state and graded on its `NOT-EVALUATED` arm. **The verbatim amended text now lives in § Issue #6369**; before this row it existed in no tracked artifact | #6369, #6364, #6367 | Hub decision `AI-018` at Stage 6. Both criteria were phrased over `G ≥ 1` / `G = 0` arms and the landed record reports neither — it states `G` as `NOT-EVALUATED`, distinguishes that from `G = 0` by name, and its Routing Rule defines a third branch matching neither column — so every arm was unreachable and neither criterion could fail. **The defect this row closes is a second one, and it is the reason the row exists rather than a footnote to the first.** The amendment was decided, briefed and executed, and four places in this plan then *graded against* or *cited* "the amended three-arm form" while the plan stated it nowhere: Stage 8 was instructed to grade verbatim text it had no tracked source for. #6364's identical case was dispositioned by the operator to land in this plan file (`D-11`); #6369's never was, and the asymmetry was an oversight rather than a decision. Recorded here rather than by editing the published Stage-5 design comment, whose edit history is permanent and unscrubable. **Dev Testing's standing instruction — that Stage 8 must not grade `INT-1`/`INT-2` until the text exists — is discharged by this row** |

<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
---
version: one-system-of-record-per-element
date: 2026-08-28
type: plan
status: ACTIVE
issues: ["#5837", "#5839", "#5844", "#5846"]
pr: null
links:
  note: null
  log_anchor: "#one-system-of-record-per-element"
reversibility-tier: MODERATE
themes: ["cluster:templates-schemas", "cluster:knowledge-architecture"]
---

<!--
The `domain_practice` provenance label has ONE home in this file — the
`### Release Class declaration` H3 below, which is the placement the Phase A1.5
schema names. It is deliberately not duplicated into this frontmatter block: a
second copy is a shadow source that drifts the moment one of the two is edited,
and the provenance-survival coverage limb reports a multi-label plan as a visible
ambiguity rather than resolving it silently.
-->


# Release Plan — one-system-of-record-per-element

> **Status:** Engineering Commit 0 (release branch `release/one-system-of-record-per-element`).
> **Identity: VERSION-LESS.** Release identity is the capability slug `one-system-of-record-per-element`. **No version key is claimed at any stage.** The plan stays slug-keyed permanently under `_unversioned/`; the Stage-12 rename never fires and no version stamp manifest is authored. There is no D-Version decision for this release.
> **Topology:** D-C SINGLE — one release branch, sequential Engineering commits, one pull request opened after the build completes.
> **Release Class:** `novel` · **Milestone:** `one-system-of-record-per-element`.
> **Source of record:** this file. The Stage-4 planning sub-task comment was the working reference until this commit landed; from here the plan file is the durable surface every later stage reads.

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less — slug identity `one-system-of-record-per-element`; no version key claimed |
| **Bump Class** | N/A — version-less release; no number binds at Stage 12 |
| **Date Created** | 2026-08-28 (Friday) |
| **Release Manager** | Agent-assisted (release hub + stage spokes) |
| **Status** | Executing |
| **Branch** | `release/one-system-of-record-per-element` |
| **PR** | populated at Stage 6 close (single pull request, opened after the build completes) |
| **Milestone** | one-system-of-record-per-element |

### Release Class declaration

**Release Class: `novel`.** Consequences carried through the pipeline: Stage 5 activation bias **ALL**, Stage 9 review depth **Deep**, Stage 13 outcome window **30-day**, engagement density Standard.

**Domain-practice provenance.** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-29, domain: governance }`

The label takes the pipeline-internal exemption form: the entire File Change Matrix consists of internal platform artifacts — governance rules, schemas, standards, decision records, one deployment script and one operations template — so no external best-practice sourcing step is triggered, and the `governance` domain guide is the encoding of the platform's own internal-deliverable practice.

**Transcription note, stated rather than left implicit.** The Stage-4 planning comment carried **no** `domain_practice` label; the label above was reconstructed at Engineering Commit 0 from the plan's own File Change Matrix under the exemption clause, and its `date` is the **reconstruction** date, not a Stage-4 determination date. This is recorded here so a downstream reader does not mistake a Commit-0 reconstruction for a Stage-4 sourcing decision.

### Baseline pin

- **Stage-4 planning baseline:** `origin/main` @ `0f38fd1` (2026-08-28, Friday). All Stage-4 baseline probes were run against that commit.
- **Stage-5 design baseline:** `origin/main` @ `e19a9d3` (2026-08-28); design performed 2026-08-29 (Saturday).
- **Engineering Commit 0 base:** `origin/main` @ `e19a9d3`. The release branch is cut from that commit.
- Stage 9 re-checks mid-pipeline divergence against this pin.

## Scope

### Issues Included

| # | Issue | Title | Size | Category | Role |
|---|---|---|---|---|---|
| 1 | #5837 | Decide the system of record for each externally-mirrored data element | S (2) | Protocol | Decision record — blocks #5844 |
| 2 | #5839 | Decide the governed home for project-health RAG | XS (1) | Protocol | Decision record — blocks #5846 |
| 3 | #5844 | One system-of-record per mirrored data element, and a governed home for external identity | L (8) | Protocol | Delivery child of #5837 |
| 4 | #5846 | Health-field home delivery | M (4) | Protocol | Delivery child of #5839 |

15 raw points; 17 effective at the `novel` multiplier. Composition is locked and this plan does not re-open it.

### Dependency Graph

```
#5837 (decision: SOR per mirrored element) ──HARD──► #5844 (delivery)
#5839 (decision: health RAG home)          ──HARD──► #5846 (delivery)

#5844 ◄──SOFT (co-scheduling, Tier-2 batch)──► #5846
#5844 ◄──SOFT (external identifier form)───── #5843 (sibling milestone)
#5846 ◄──SOFT (key scheme)──────────────────── #5843 (sibling milestone)

#5837 ⟂ #5839   (no edge — independent subject matter)
```

| Edge | Type | Establishing text |
|---|---|---|
| #5837 → #5844 | **HARD** | #5837 declares that it blocks the source-of-record and external-identity delivery child, and that the three governance surfaces are amended by that child. #5844's first acceptance criterion requires the decision record to exist, and that record is #5837's sole deliverable. |
| #5839 → #5846 | **HARD** | #5839 declares that it blocks the health-field-home delivery child and names it. #5846 cannot select a status source field before #5839 decides whether health is a Project field or a separate fact record. |
| #5844 ↔ #5846 | **SOFT** (co-scheduling) | Neither declares the other. The coupling is the shared frozen surface: both carry a Tier-2 scope change on the entity field schema and the entity model, and #5839 directs that the two be batched rather than reopening the surface twice. This constrains sequencing, not permission to start. |
| #5844 → #5843 | **SOFT** | Self-declared in #5844: no hard dependency; the sibling key-scheme card governs the qualified form of the external identifier. |
| #5846 → #5843 | **SOFT** | Self-declared in #5846: no hard dependency; relates to the key scheme. |
| #5837 ⟂ #5839 | **none** | Disjoint subject matter — externally-mirrored data authority versus project-health mastering. Their children couple downstream; the decisions themselves do not. |

**Coordination edge that is a mutual exclusion, not a dependency.** Sibling card #5847 owns the stale roster-count repair in the entity field schema, and its acceptance criterion is a *counting* assertion over that file. This milestone edits the same file at three issues. See risk R7 — the constraint is do-not-touch, not sequence-after.

## Implementation Sequence

Five beats. Beats 1 and 2a may run concurrently; everything else is ordered. Concurrency posture is the default **P0 fully-serial** on the shared release branch — the hub routes one Engineering chip at a time and the next waits until the prior commit lands.

**Beat 1 — Decisions (#5837, #5839).** Author both decision records. They are independent and may be written in parallel.

- Allocate the record number at authorship from the binding oracle; **claim it at merge, never reserve it**. Never pre-reserve above a sibling's unmerged claim: a gap blocks the repository as readily as a duplicate, and the renumbering tool resolves a duplicate losslessly at merge.
- Cite the new records **by slug** in every in-release citation, never by number. The delivery child's acceptance criterion already greps the slug, which is the correct form.
- **#5837's record states ADR-051's disposition as superseded IN PART** — its first decision only — leaving the remaining decisions in force. See R1.
- **#5839's record states its sequencing** — that its entity change is batched into Beat 3's single reopening.

**Beat 2a — Decision-independent delivery from #5844.** Runs concurrently with Beat 1; none of it cites the new record.

- `core/schemas/project-schema.md` — register the missing connector keys with types.
- `core/schemas/frontmatter-schema.md` — extend the source-system enum by the four absent values.
- `core/standards/c3-external-sync-path-b.md` — replace the existing single-field key-declaring clause with a composite key statement naming the adapter and the external identifier together.

**Beat 2b — Record-citing delivery from #5844.** Requires Beat 1's #5837 record to exist.

- `core/governance/OPERATIONS.md` — the local-copy principle cites the new record and is re-typed onto the write-direction axis; the connector-configuration section points at the project schema.
- `core/schemas/tracker-schemas.md` — the dual-format model's local-source line cites the new record; the tracker column is generalized off its single-vendor naming.
- `core/ADRs/ADR-051-health-check-mcp-primary-source-set.md` — **frontmatter `status:` line, the `## Status` body block, and the `## Cross-references` section ONLY.** The record is `Accepted` and immutable against decision revision: an in-place edit to its `## Decision`, `## Context`, `## Consequences` or `## Alternatives Considered` text is prohibited, and its `## Cross-references` section is added to rather than renamed.
- `operations/skills/health-check/SKILL.md` — correct the line that restates the superseded decision.
- `operations/skills/health-check/references/evidence-matrix.md` — correct the same restated wording at its own site.
- `operations/skills/file-router/SKILL.md` — extend the restated source-system enum to the canonical value set.

**Beat 3 — The single Tier-2 entity-surface beat.** Requires **both** decisions complete. This is the batched reopening #5839 mandates.

- One edit pass over `core/disciplines/project-entity-model.md` **and** `core/schemas/entity-field-schemas.md` carrying **both** changes together: #5844's optional external-identity field group and #5846's health-mastering change.
- **One** amendment note, **one** re-freeze sentence, authorization cited as this milestone's Stage 9 GO — the established form on that surface.
- If #5839 selects a Project *field*, the precedent is a field-level amendment with the roster count unchanged. If it selects a separate fact record, the precedent is a roster extension, which drags an owning-agent row, a lifecycle-matrix block and every count reconciliation. These are materially different sizes — see R8.

**Beat 4 — #5846 remainder.** Requires Beat 3.

- `core/standards/portfolio-writeback-contract.md` — re-point the status row's source entity, **and** make the existing exemption sentence name the validation rule explicitly (R4).
- `operations/templates/project-rollup-template.md` — source comment, entity-type disposition, and the two absent Core fields.
- `core/deploy/tools/compose-portfolio.py` — remove or signal the silent identifier-resolution fallback chain, and document it at the declaration site.
- The project-identifier-to-folder-name **declared mapping** sentence. **Routed to `core/schemas/project-schema.md`.** The acceptance criterion accepts either home, and the alternative home is contended with an unstarted sibling milestone while the project schema is already open in Beat 2a.

**Beat 5 — Verification.** Stage 7 then Stage 8, per the Stage Applicability Matrix. Run each acceptance criterion's own stated probe method; do not substitute a looser one.

**Closure:** all four issues are marked as closed at Stage 13 against the capability slug. No version key is claimed at any beat.

## Stage Applicability Matrix

| Issue | Stage 5 Solutioning | Stage 6 Engineering | Stage 7 DevTest | Stage 8 Acceptance |
|---|---|---|---|---|
| **#5837** (S, 2) | **APPLIES** — the deliverable *is* the decision. Open question closed: ADR-051's disposition. | **APPLIES** — record authored and committed. | **APPLIES (light)** — mechanical arm only: record-number integrity, frontmatter standard, reference durability, doc-link resolution. | **APPLIES** — three explicit criteria, each with a stated method. |
| **#5839** (XS, 1) | **APPLIES** — decision between a Project field and a separate fact record. Also fixes Beat 3's size (R8). | **APPLIES** — record authored and committed. | **APPLIES (light)** — same mechanical arm. | **APPLIES** — three explicit criteria. |
| **#5844** (L, 8) | **APPLIES** — the issue names its own gate on whether the external-identity group is Core or per-entity. | **APPLIES** — file edits plus the record-citation pass. | **APPLIES (full)** — four criteria are executable set-difference probes; baselines pinned below. | **APPLIES** — seven criteria, three carrying explicit anti-false-pass guards. |
| **#5846** (M, 4) | **APPLIES** — the issue names its own gate on the identifier-resolution fallback. | **APPLIES** — file edits including one executable. | **APPLIES (full)** — the self-test as a regression guard only (R9), plus the enum and mapping probes. | **APPLIES** — five criteria, two carrying false-pass traps (R4, R5). |

**No stage is skipped for any issue.** Under `novel` the Stage-5 bias is ALL, and every issue carries at least one self-declared open decision. Stage 7 is **differentiated, not skipped**, for the two decision records: they ship no executable surface, but they do ship files four mechanical gates cover, and a "no executable code therefore skip DevTest" collapse is a known self-skip failure. Run the stage; scope it to the mechanical arm.

## File Change Matrix

Intent markers use the `add | edit | delete` enum. Path-first columnar form inside the fence.

```
# ── Edits ──
core/governance/OPERATIONS.md                                     edit
core/schemas/tracker-schemas.md                                   edit
core/schemas/project-schema.md                                    edit
core/schemas/frontmatter-schema.md                                edit
core/schemas/entity-field-schemas.md                              edit
core/disciplines/project-entity-model.md                          edit
core/standards/c3-external-sync-path-b.md                         edit
core/standards/portfolio-writeback-contract.md                    edit
core/ADRs/ADR-051-health-check-mcp-primary-source-set.md          edit
core/deploy/tools/compose-portfolio.py                            edit
operations/templates/project-rollup-template.md                   edit
operations/skills/health-check/SKILL.md                           edit
operations/skills/health-check/references/evidence-matrix.md      edit
operations/skills/file-router/SKILL.md                            edit

# ── Adds ──
release/releases/plans/_unversioned/one-system-of-record-per-element_RELEASE_PLAN.md   add
core/ADRs/ADR-NNN-system-of-record-per-mirrored-element.md        add
core/ADRs/ADR-NNN-project-health-home.md                          add

# ── Release-wide explicit non-scope ──
core/CLAUDE.md.template   NOT EDITED
```

**Why the two decision-record rows carry a placeholder segment rather than a literal number.** The number is allocated at authorship and **claimed at merge**; the renumbering tool re-stamps at merge time. The approved plan directs that neither record enter a path-exact extraction list before merge, so both rows are authored in the recognized placeholder form, which normalizes into the glob arm and matches the delivered file whatever number binds.

**The health-record row is RESOLVED and no longer conditional.** It was held conditional while #5839's Stage 5 had not rendered its decision between a Project field and a separate fact record, because the record's slug followed from that choice. Stage 5 selected the Project **field** option, Stage 6 authored the record at the slug `project-health-home`, and the row is promoted into the unconditional set above carrying that slug. Because the option chosen is a field-list amendment rather than a roster extension, **the roster count stays at 19** and R8's larger-change branch does not fire.

**Why `core/CLAUDE.md.template` is explicit non-scope and not merely absent.** It appears in an earlier statement of #5846's affected files, and the acceptance criterion it serves accepts either that file or the project schema as the home for the declared-mapping sentence. The mapping sentence is routed to the project schema instead, so this file is **not edited by this release**. It is contended with an unstarted sibling milestone and with a concurrent unmerged release, and the release's nominal file overlap with that concurrent release must stay at zero. Recording the exclusion positively is what keeps a later reader from reading the absence as an oversight.

## File Contention Map

Ownership re-derived at Stage 4 from live issue bodies across the four open milestones, not carried forward from the originating audit.

| Path | This milestone | Contends with (other milestones) |
|---|---|---|
| `core/schemas/entity-field-schemas.md` | #5839, #5844, #5846 | #5843, #5847, #5850, #5842 |
| `core/disciplines/project-entity-model.md` | #5839, #5844, #5846 | #5843, #5847, #5850 |
| `core/schemas/project-schema.md` | #5844 | #5847, #5842, #5848 |
| `core/schemas/tracker-schemas.md` | #5837, #5844 | #5843, #5848, #5849 |
| `core/schemas/frontmatter-schema.md` | #5844 | #5843, #5845 |
| `core/standards/portfolio-writeback-contract.md` | #5839, #5846 | #5843 |
| `core/governance/OPERATIONS.md` | #5837, #5844 | #5849 |
| `core/ADRs/ADR-051-…` | #5844 | none |
| `core/deploy/tools/compose-portfolio.py` | #5846 | none |
| `core/standards/c3-external-sync-path-b.md` | #5844 | none |
| `operations/templates/project-rollup-template.md` | #5846 | none |
| `operations/skills/health-check/SKILL.md` | #5844 | #5842 |
| `operations/skills/health-check/references/evidence-matrix.md` | #5844 | none |
| `operations/skills/file-router/SKILL.md` | #5844 | none |

**The two highest-contention paths are exactly the two frozen-surface files this milestone must reopen.** That is the structural driver behind R2.

## Cross-PR Overlap Audit

### In-Flight Release Roster

**Measured at:** `e19a9d3` · 2026-08-29 · **Population:** n=1 sibling.

| Slug | PR | Head | Bump-class | Carried label | Recomputed next-free | Edit-set ∩ this matrix |
|---|---|---|---|---|---|---|
| `declarations-have-a-firing-surface` | #6353 | branch head | version-less (no bump-class declared) | — | UNRESOLVABLE — version-less sibling claims no slot | `core/CLAUDE.md.template` — **nominal only; this release does not edit that file, so the realized overlap is zero** |

The roster is a **pinned measurement and carries no verdict**. Stage 9 re-measures this population fresh pre-GO and renders the contention verdict there. The one nominal overlap is held at zero by the explicit non-scope row in the File Change Matrix.

**Decision-record number contention.** The concurrent sibling has claimed the same next-free record number on its own branch only; the number does not exist on the mainline. The claim is **advisory**. This release claims the number the oracle computes rather than jumping past it: a gap blocks the repository while a duplicate is resolved losslessly by the renumbering tool, and whichever release merges second renumbers.

## Risk Register

| # | Risk | Owner | Mitigation | Reversibility · Confidence |
|---|---|---|---|---|
| **R1** | **ADR-051 supersession scope.** The record carries several decisions; only its first is the conflicting authority claim. The others — drift resolution direction, the both-stale rule, the degradation envelope including its MEDIUM auto-action cap, and the no-connector degradation posture — have no other home: the health-check skill explicitly declines to restate them. A blanket supersession silently orphans the degradation envelope, and a `Superseded` record is frozen against all further edits, so recovery costs a third record. Measured, not argued: a `Superseded` leading token whole-file exempts the record from the durability lint. | Stage 5 → Stage 6 | Author #5837's record as **superseded in part — the first decision only** — explicitly naming the surviving decisions as retained and in force, and state the retention in ADR-051's own forward pointer so a reader arriving at that record learns which half still binds. **DISCHARGED at Stage 6 Beat 1**, and its ADR-051-side half is Beat 2b's obligation. | **EXPENSIVE** · **HIGH** |
| **R2** | **Tier-2 frozen-surface double-reopen across milestones.** The single batched reopening is achievable *within* this milestone. It is not achievable across milestones: three sibling cards each amend the entity model, and one declares its own Tier-2 scope change on it. Whichever milestone merges second re-freezes on top of the other. | Stage 9 | In-milestone: enforce the single Beat-3 pass — one amendment note, one re-freeze sentence, one authorization. Cross-milestone: routed to the hub as a sequencing decision; the sibling milestone is unstarted and hard-blocked upstream, so it rebases onto this release. | **MODERATE** · **HIGH** |
| **R3** | **Record number claim moves at merge.** The next-free number is a *read*, not a reservation, and a concurrent unmerged sibling has claimed the same number on its branch. | Stage 6 / Stage 12 | Cite the new records **by slug** everywhere in-release. Run the renumbering tool at merge; it rewrites path-exact references and appends the provenance note. Never pre-reserve above a sibling's unmerged claim. | **CHEAP** · **HIGH** |
| **R4** | **#5846 second criterion false-pass.** The criterion asks that the contract carry an explicit exemption sentence naming a validation rule. The contract already states the exemption *in substance* while never naming the rule, so a grep-shaped assessor passes it today with no edit made. | Stage 8 | The discriminating probe counts occurrences of the rule identifier in the contract and requires at least one — not a search for the substance wording. Baseline at plan time: zero. | **CHEAP** · **HIGH** |
| **R5** | **#5846 third criterion false-pass.** The criterion asks for one governed sentence stating the identifier-to-folder-name relationship as a declared mapping. The stance sentence already exists and already satisfies the criterion's negative limb; what is absent is the **resolution direction** a consumer needs. | Stage 8 | Require the new sentence to state *how* a consumer resolves one from the other, and verify by reading the sentence rather than grepping for the stance wording. Routing the sentence to the project schema also makes the new text trivially separable from the pre-existing stance text. | **CHEAP** · **HIGH** |
| **R6** | **#5844's citation-hygiene criterion is auto-satisfied by its connector-key criterion.** The only failing token is the one the connector-key work adds, so completing that criterion satisfies this one with no edit to the sync-path file — which can read as an unworked criterion. | Stage 8 | Sequence the connector-key criterion first and record the citation-hygiene one as **verify-only, satisfied transitively**, with the probe output attached. Do not also "fix" the citation; that file already needs a separate, real change under its key-declaration criterion. | **CHEAP** · **HIGH** |
| **R7** | **Cross-milestone criterion collision on the stale roster count.** The entity field schema carries a stale roster count in a validation rule while the surface is re-frozen at a higher number. This is a live defect **already owned** by a sibling card whose criterion is a *counting* assertion. Beat 3 edits that exact file. An incidental repair here makes the sibling's criterion vacuously satisfied. | Stage 6 (Beat 3) | **Do not touch the stale count in Beat 3.** Restrict Beat 3's edits to the field-group and health additions. Do not file a new work item — it has an owner. If Beat 3's additions make the stale count actively misleading, raise it to the hub as a sequencing note, not as an in-scope edit. | **MODERATE** · **MEDIUM** |
| **R8** | **#5839's separate-fact-record option is a materially larger Tier-2 change than its field option.** The field option is a field-level amendment with the roster count unchanged. The fact-record option is a roster extension, dragging an owning-agent row, a lifecycle-matrix block, and every count reconciliation. #5839 is sized XS and its child M; the larger option plausibly exceeds that. | Stage 5 | Surface the size asymmetry **at the Stage-5 decision**, before the option is chosen. If the larger option is selected, re-check Beat 3 and #5846's sizing at the Stage-9 gate rather than absorbing the overflow silently. The count-versus-structure lint is enforcing and will fire on an unreconciled roster count. | **EXPENSIVE** · **MEDIUM** |
| **R9** | **A green self-test on the portfolio composer is not evidence #5846 is fixed.** The criterion says so explicitly, and the self-test passes on the mainline today. Treating it as evidence would close the card on an unfixed defect. | Stage 7 | Use the self-test strictly as a **regression guard**. The card's own defect probe is a direct read of the resolution function asserting the silent fallback chain is removed or now emits a discriminating signal. | **CHEAP** · **HIGH** |
| **R10** | **Restated-decision surfaces outside the original scope.** Two health-check surfaces and one file-router surface restate claims this release changes; none was in the originating affected-files list. Left unedited they contradict the new record on the day it ships. | Stage 4 / Stage 5 gates | All three were pulled into #5844's scope at the plan-review and design gates with the rationale recorded on the card. Each is a one-line edit of the same shape. | **CHEAP** · **HIGH** |
| **R11** | **The `domain_practice` provenance label was absent from the Stage-4 comment** and was reconstructed at Commit 0. A downstream consumer reading the label alone cannot tell a reconstruction from a Stage-4 determination. | Stage 6 | The reconstruction is stated explicitly under the Release Class declaration, with its date named as the reconstruction date. The label's content is derivable from the File Change Matrix under the pipeline-internal exemption, so the reconstruction carries no invented judgment. | **CHEAP** · **HIGH** |

## Delivery Strategy

- **Branch topology D-C SINGLE.** One release branch, `release/one-system-of-record-per-element`, cut from the Engineering Commit 0 base. Sequential Engineering commits; **no** pull request is opened until the build completes, then one pull request for the whole milestone.
- **Concurrency posture P0 fully-serial** (the undeclared default). One Engineering chip at a time; the next waits until the prior commit lands on the release branch. Force-push on the shared release branch is prohibited.
- **Commit granularity:** one commit per beat unit, referencing its source issue number in the message body. Commit messages carry no personal email and no operator-home path.
- **Close-family keywords** are confined to the pull request's issue-reference block and added at Stage 12; every in-flight reference is non-closing.
- **Milestone is one merge.** All four issues are delivery slices on this one branch behind a single merge gate.

## Verification Plan

**Acceptance-criterion baseline, as read at plan time** against `origin/main` @ `0f38fd1`: #5837 = 3 criteria · #5839 = 3 · #5844 = 7 · #5846 = 5. A criterion count that no longer matches this baseline is a mechanical signal to re-bind the rows below.

**Re-bound at Stage 6 `fix(dt)`, 2026-08-29 (Saturday).** That signal fired. #5846 was strengthened mid-release and now carries **6** criteria (R4a strengthened the exemption-token criterion; **R4b added a sixth** — the discriminating self-test case). Re-bound baseline: #5837 = 3 · #5839 = 3 · #5844 = 7 · **#5846 = 6**. The #5846 rows below are re-indexed onto that list. **The issue bodies are authoritative over this plan**; where the two disagreed, the plan was corrected, never the delivery. Three corrections, all confined to the #5846 rows:

1. **Row count** — a sixth row was added for the criterion R4b introduced after this table was authored.
2. **AC-4 method** — was `deploy.sh --check`; the issue specifies `compose-portfolio.py --self-test`. Re-pointed to the issue's method.
3. **AC-5 contradicted ADR-163 §5** — the superseded row required `^lifecycle_state:` in the rollup template. ADR-163 §5, ratified in *this* release, decides the rollup record stays non-roster and is **explicitly exempt** from `V-CORE-03`/`V-CORE-03b` (`lifecycle_state`) and `V-CORE-06` (`created_date`), and the writeback contract carries that exemption sentence. Satisfying the old row would have added a field the ratified decision says the record must **not** carry. Measured: the template carries **0** anchored `lifecycle_state:` and **0** `created_date:`, control `entity_type:` fires 1 on the same file — so the implementation is correct and the plan row was wrong. The row now grades the issue's actual AC-5.

### Per-Issue Verification

| Issue | AC | Predicate class | Verification Method | Expected Result |
|---|---|---|---|---|
| #5837 | AC-1 | file-content | `grep -c "System of record" core/ADRs/ADR-164-system-of-record-per-mirrored-element.md` ≥ 3 | The decision record's table assigns one system of record for at least three named elements. |
| #5837 | AC-2 | file-content | `grep -c "wins" core/ADRs/ADR-164-system-of-record-per-mirrored-element.md` ≥ 3 | The reconciliation rule is directional in every branch and names a winner; "flag both without a direction" is explicitly excluded. |
| #5837 | AC-3 | file-content | `grep -c "ADR-051" core/ADRs/ADR-164-system-of-record-per-mirrored-element.md` ≥ 3 | The record names ADR-051 explicitly and states its disposition as superseded in part. |
| #5839 | AC-1 | file-content | `grep -c "The Project entity masters the project-level health RAG" core/ADRs/ADR-163-project-health-home.md` ≥ 1 | The Decision section selects exactly one health-mastering home. Two arms, because the criterion carries a rationale limb a token match cannot grade. *Mechanical arm:* the probe resolves the selected home in the record's own Decision heading; baseline is zero because the file does not exist before this release. *Reviewer arm, required:* Stage 8 reads `## Alternatives Considered` and confirms each rejected home carries a stated reason — `grep -c "Rejected" core/ADRs/ADR-163-project-health-home.md` measures 5 today, which evidences presence but not adequacy. |
| #5839 | AC-2 | file-content | `grep -c "V-CORE-02" core/ADRs/ADR-163-project-health-home.md` ≥ 1 | The record states the rollup's `entity_type` disposition by naming the validation rule literally, not by classifying the record. Measured at authorship: **3** matching lines; both `grep` and an independent `python3` count agree, so the shimmed-matcher false-zero mode is excluded. The disposition stated is non-roster-with-exemption, and the record explicitly declines to claim the exemption closes a live enforcement gap. |
| #5839 | AC-3 | file-content | `grep -c "batched into" core/ADRs/ADR-163-project-health-home.md` ≥ 1 | The record names its own sequencing — the entity change is batched into the single Tier-2 re-freeze beat with the sibling delivery child, and the frozen surface is reopened once. Measured at authorship: **2** matching lines. This is the record-side half of CIAC-3, whose file-side half counts amendment notes on the entity model. |
| #5844 | AC-1 | file-content | `grep -c "system-of-record-per-mirrored-element" core/governance/OPERATIONS.md core/schemas/tracker-schemas.md core/ADRs/ADR-051-health-check-mcp-primary-source-set.md` ≥ 3 | Each of the three surfaces cites the new record by slug. Sum over the three files; the per-file distribution is confirmed by reading the diff at Stage 8. |
| #5844 | AC-2 | file-content | `grep -c "co_management_smartsheet_id" core/schemas/project-schema.md` ≥ 1 | The project schema defines every connector key the operations governance file names. Baseline at plan time: this key absent; control `dual_framing_enabled` resolves in the same file. |
| #5844 | AC-3 | file-content | `grep -c "smartsheet" core/schemas/frontmatter-schema.md` ≥ 1 | The source-system enum is extended by the four absent values. Baseline at plan time: absent. |
| #5844 | AC-4 | file-content | `grep -c "external_id" core/schemas/entity-field-schemas.md` ≥ 2 | Work Item and Risk Item each carry an optional external-identifier and source-system pair with a referential rule or an explicit no-rule note. |
| #5844 | AC-5 | file-content | `grep -c "source_adapter, external_id" core/standards/c3-external-sync-path-b.md` ≥ 1 | The snapshot key is declared as the composite pair in an explicit key-declaring statement, not merely as two members of a record shape. Baseline at plan time: the file declares a single-field key. |
| #5844 | AC-6 | file-content | `grep -c "co_management_smartsheet_id" core/schemas/project-schema.md` ≥ 1 | Verify-only, satisfied transitively by AC-2 (R6): the sync-path file no longer cites the project schema as home of a field it lacks. |
| #5844 | AC-7 | file-content | `grep -c "superseded in part" core/ADRs/ADR-051-health-check-mcp-primary-source-set.md` ≥ 1 | ADR-051's own `status:` line carries the partial-supersession pointer. Read the line directly — a merged pull request, a green close-out, or a citation elsewhere is not evidence. |
| #5846 | AC-1 | file-content | `grep -c "health_rag" core/standards/portfolio-writeback-contract.md` ≥ 1 | The §2 `status` row cites a field whose **declared enum is the RAG set**. Re-bound at Stage 6 `fix(dt)`: this row read `[DEFERRED — blocked on #5839's Stage 5 decision]`, and that decision has since landed — ADR-163 §1 selects Project `health_rag`, so the deferral is discharged and the row is now gradeable. Two arms. *Mechanical arm:* the token measures **0** at the pre-work base and **6** at head, control `rollup` measures 30/37 across both arms, so the matcher fires and the baseline zero is a real absence. *Reviewer arm, required:* confirm the **cited field's own enum** in `core/schemas/entity-field-schemas.md` is the RAG set — `V-PRJ-09` declares `health_rag, if present, ∈ {green, yellow, red}`. Citing the field is not sufficient; the criterion grades the enum. |
| #5846 | AC-2 | file-content | `grep -c "V-CORE-02" core/standards/portfolio-writeback-contract.md` ≥ 1 | The exemption sentence names the validation rule explicitly (R4). Baseline at plan time: zero occurrences; control — the file resolves and is non-empty. |
| #5846 | AC-3 | file-content | `grep -c "folder basename" core/schemas/project-schema.md` ≥ 1 | One governed sentence states the identifier-to-folder-name relationship as a declared mapping **with its resolution direction**. Two arms, because the criterion is not fully mechanizable (R5). *Mechanical arm:* `folder basename` measures **0** in that file today, so the probe discriminates against unedited state — unlike a bare `project_id` probe, which measures **1** today and would pass with no edit made. Control: `resolves` measures 18 in the same file, so the file resolves and the matcher fires. *Reviewer arm, required:* Stage 8 reads the sentence and confirms it states the direction a consumer resolves in — a token match is not sufficient evidence for this criterion. |
| #5846 | AC-4 | regression | `python3 core/deploy/tools/compose-portfolio.py --self-test` exit 0 — regression guard | Re-pointed at Stage 6 `fix(dt)`: this row read `deploy.sh --check`; the issue's method is `compose-portfolio.py --self-test` and the **issue is authoritative**. Regression guard only (R9) — the issue states the suite already passes on the mainline, so a green run is explicitly **not** evidence this card's defect is fixed and cannot close the card alone. This executor will report a **reasoned SKIP** naming the verb, because `python3` is outside its closed read-only allowlist by design; the mechanical guarantee lives in that tool's own CI-invoked self-test gate (`Discovered tool self-tests`), which is a gate in its own right. A SKIP here is the honest verdict, not a gap. |
| #5846 | AC-5 | file-content | `grep -c "(join-key)" core/deploy/tools/compose-portfolio.py` ≥ 1 | The self-test suite gains a **new case that fails on the mainline and passes after the fix**, covering the `project_id` fallback specifically (R4b). **Replaced at Stage 6 `fix(dt)`:** this row previously required `^lifecycle_state:` in the rollup template, which contradicted ADR-163 §5 — see the re-bind note above. Two arms. *Mechanical arm:* the new case carries the `(join-key)` tag, measuring **0** at the pre-work base and **5** at head; control `(drift)` — the pre-existing case — measures **5 in both arms**, so the matcher is alive and the baseline zero is a real absence. *Reviewer arm, required:* the criterion is a **discrimination** claim, which a presence count cannot grade. Confirm the case was run against both arms: on the pre-fix resolution logic it must exit non-zero, and on the branch exit zero. A case that passes on both arms does not discriminate and does not satisfy this criterion. |
| #5846 | AC-6 | file-content | `grep -c "JOIN_KEY_FIELD" core/deploy/tools/compose-portfolio.py` ≥ 1 | The `project_id` resolution no longer falls back **silently**: either the `id`/rel-path fallback branch is removed, or it emits a discriminating signal, and it is documented at its declaration site. Added at Stage 6 `fix(dt)` — the sixth criterion (R4b era) had no row. Two arms. *Mechanical arm:* the named module constant that replaced the fallback chain measures **0** at base and **2** at head; control `def _selftest` measures **1 in both arms**. *Reviewer arm, required:* read the resolution function and assert **one** of the two outcomes — the issue states either satisfies this criterion, and which one was taken is a Stage-5 decision. A count alone cannot tell removal from a retained-but-signalling branch. |

### Release-Level Verification

- Record-number integrity gate passes on the merged branch (no gap, no unresolved duplicate).
- Platform frontmatter standard and reference-durability gates pass on every modified durable-corpus file.
- Doc-link resolution passes on every modified markdown file.
- Deployed-copy synchronization is clean for every edited skill surface.

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**

- [ ] **CIAC-1 (#5837 × #5844 on the three citing surfaces):** #5837 produces the decision record and #5844 makes the operations governance file, the tracker schema, and ADR-051 each cite it. Neither issue can be accepted alone — #5837 can produce a record nobody cites, and #5844 cannot cite a record that does not exist. *Method:* `grep -c "system-of-record-per-mirrored-element" core/governance/OPERATIONS.md core/schemas/tracker-schemas.md core/ADRs/ADR-051-health-check-mcp-primary-source-set.md` at least 3. *Graded at Stage 9 on the merged pull request.*
- [ ] **CIAC-2 (#5837 × #5844 on `core/ADRs/ADR-051-health-check-mcp-primary-source-set.md`):** the disposition is stated once and honoured twice — #5837's record states ADR-051's disposition, and ADR-051's own `status:` line carries it. Both must say *in part* and name which decisions survive. A green close-out, a merged pull request, or a citation of ADR-051 elsewhere is not evidence; the file read is the only authority. *Method:* `grep -c "superseded in part" core/ADRs/ADR-051-health-check-mcp-primary-source-set.md` at least 1. *Graded at Stage 9 on the merged pull request.*
- [ ] **CIAC-3 (#5839 × #5844 × #5846 on `core/disciplines/project-entity-model.md`):** one Tier-2 amendment, not two. Both delivery children carry a Tier-2 scope change on the same two files and #5839's record requires the change be batched. Exactly one amendment note carrying both changes, with one re-freeze sentence and one authorization. Two notes means the surface was reopened twice. *Method:* `grep -c "SCOPE CHANGE — RESOLVED" core/disciplines/project-entity-model.md` at most 8. *Graded at Stage 9 on the merged pull request.* **The threshold is baseline-derived, not chosen:** the pre-release baseline measured on the Commit-0 base is **7** amendment notes, so "exactly one note added by this milestone" mechanizes as at most 8. A threshold set without measuring the baseline produces a false verdict in whichever direction it misses by; this one is pinned to a measurement and must be re-pinned if the baseline moves.
- [ ] **CIAC-4 (#5844 × #5846 on `core/standards/portfolio-writeback-contract.md`):** the source-of-record rule #5844 establishes is the rule #5846's rollup obeys. The rollup publishes a status value that is by construction a mirrored or composed value; it must not introduce a second master for a value #5844 has already assigned. *Method:* `grep -c "V-CORE-02" core/standards/portfolio-writeback-contract.md` at least 1. *Graded at Stage 9 on the merged pull request, together with a read of the cited field's declared home against the decision record's table.*
- [ ] **CIAC-5 (#5844 × #5846 on external-identifier carriage):** a consistency check, not a gate — the soft edge to the sibling milestone's key-scheme card. Record the carriage form this release ships so the sibling can reconcile against it. Do not block on the sibling and do not pre-adopt its unmerged grammar. *Method:* `declared, verification deferred to the sibling key-scheme card` — recorded, not gated. *Graded at Stage 9 as a recorded observation.*

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback | Tier |
|---|---|---|
| #5837 | Revert the decision-record commit. The record is net-new and nothing on the mainline cites it until Beat 2b lands. | **CHEAP** |
| #5839 | Revert the decision-record commit; same shape as #5837. | **CHEAP** |
| #5844 | Revert the Beat 2a/2b commits. The ADR-051 status-line edit reverts cleanly because it touches only the status line, the status body block and the cross-reference section — the frozen sections were never edited. | **MODERATE** |
| #5846 | Revert Beat 4. The Beat 3 entity-surface amendment is the expensive half: reverting it means re-freezing the surface a second time. | **MODERATE** |

### Whole-Release Rollback

Revert the merge commit. **Reversibility MODERATE · confidence HIGH.** The one irreversibility-adjacent element is the Tier-2 entity-surface reopening: a revert re-freezes the surface, and a sibling milestone that rebased onto this release's amendment note would need to rebase again. No data is lost in any branch; the cost is coordination, not recovery.

## Quota Budget

**Verdict:** PASS
**Parallel-eligible spokes per parallel stage:** Stage 5: 4 · Stage 7: 4 · Stage 8: 4
**Per-spoke cost estimate:** standard band (governance/doc-corpus spoke; no runtime suite, no large-fanout search)
**Assumed remaining usage-window envelope:** operator-stated at hub start
**Estimated cumulative draw of the worst parallel batch:** within envelope
**Routing:** PASS — proceed.
**Note:** the runtime checkpoint re-validates at every spoke launch on both the usage-window and host-API axes; this plan-time estimate is usage-window-only by design.

## Deviation Log

| # | Deviation | Rationale | Disposition |
|---|---|---|---|
| a | The `domain_practice` provenance label was **absent** from the Stage-4 planning comment and was reconstructed at Engineering Commit 0. | The label is a Stage-4 obligation whose content is derivable from the plan's own File Change Matrix under the pipeline-internal exemption. Reconstructing it is the honest repair; omitting it would leave the close-class resolver with no input. | Reconstructed, dated as a reconstruction, and stated under the Release Class declaration. Recorded as R11. |
| b | The Stage-4 comment's cross-issue criteria were authored with a non-parser identifier prefix; they are transcribed here under the `CIAC-N` identifier the verification executor parses. | The plan file is the machine-read surface; the comment was the working reference. Substance is preserved verbatim in meaning. | Transcribed; no criterion added, removed or narrowed. |
| c | The Stage-4 comment's File Change Matrix was a bare path list with no intent markers. It is transcribed here with explicit `add`/`edit` markers and a labelled non-scope block. | A marker-less path parses as `unknown`, never `edit`, so a bare list would leave the matrix uninterpreted and unable to reach a pass. | Markers added; no path added or removed except the three restated-decision surfaces pulled into scope at the plan-review and design gates, and the explicit non-scope row. |
| d | `core/CLAUDE.md.template` appears in an earlier statement of #5846's affected files but is **not edited** by this release. | The acceptance criterion accepts either that file or the project schema as the home for the declared-mapping sentence; the sentence is routed to the project schema, which is already open in Beat 2a and is not contended with a concurrent unmerged release. | Declared as explicit non-scope in the File Change Matrix. |
| e | Three Verification-Plan / cross-issue probes were **tightened at Commit-0 self-verification** after the executor graded them against live state. Two (#5846 AC-3 and AC-5) returned PASS against **unedited** files — false passes of exactly the shape risks R4/R5 name; one (CIAC-3) carried a threshold set without measuring its baseline and returned a false FAIL. | A probe that passes against unedited state grades a conforming release and an unworked one identically, and the false-PASS direction is the one that survives downstream as inherited green. The baseline-free threshold is the mirror defect. | AC-3 re-keyed onto the direction clause; AC-5 anchored to a frontmatter key declaration; CIAC-3 re-pinned to the measured baseline of 7 with the measurement stated on the row. Each row now carries its baseline and its control arm. |
| f | The File Change Matrix block labels avoid the substring *conditional* inside the word *unconditional*. | The matrix parser marks a block conditional on a label matching that word case-insensitively, so a block labelled "Unconditional adds" silently converts its rows into conditional ones — which downgrades a delivery FAIL to a WARN-tier SKIP. Observed directly at Commit-0 self-verification: the first authoring reported `obligations=0`. | Labels rewritten; the row-level `CONDITIONAL:<token>` marker is the only conditionality signal in the matrix. |
| g | Both Stage-5 designs discharged the "`V-CORE-02` is mechanically unenforced" claim against a control arm (`V-CORE-01` = 33) that **does not discriminate in the population being measured**: re-measured at Stage 6, `V-CORE-01` is 0 across the 238 tracked `.py`/`.sh` files — the 33 is a corpus-wide markdown count. The decision record states the corrected form. | A control that reads zero in the measured population cannot distinguish "the token is absent" from "the scan did not fire there", which is the precise failure the structured-probe discipline exists to prevent. The re-measurement used a control that fires *inside* the executable population (`Check N` = 848). | **Conclusion unchanged and strengthened** — the unenforcement is family-wide, not particular to `V-CORE-02`: the entire `V-CORE` family (9 identifiers, 159 corpus occurrences) measures 0 in `.py`/`.sh`, and the deploy check engine carries 0 family references against a control of 470 `Check ` occurrences. The record carries the family-wide form; no design conclusion was reversed. |

## Change Description

*Authored at the close of Engineering, before the pull request is marked ready for review.*

## Verification Evidence

*Populated by the plan-verification executor at Stage 6 self-verification and re-run at Stage 7.*

## Issue References

- **#5837** — decide the system of record for each externally-mirrored data element; the decision-record card whose sole deliverable is the new source-of-record record.
- **#5839** — decide the governed home for project-health RAG; the sibling decision-record card.
- **#5844** — one system of record per mirrored data element plus a governed home for external identity; the delivery child of #5837.
- **#5846** — the health-field-home delivery child of #5839.
- **#5842, #5843, #5845, #5847, #5848, #5849, #5850** — sibling-milestone cards contending one or more paths in this release's File Change Matrix; each is named in the File Contention Map row for the path it contends.
- **#6262** — the Stage-4 release-planning sub-task; the working reference this file transcribes and supersedes as the source of record.
- **#6277** — the Stage-5 Solutioning sub-task for #5837; carries the implementation-ready design this release's Beat 1 builds.
- **#6278** — the Stage-6 Engineering sub-task under which the #5837 decision record landed.
- **#6281** — the Stage-5 Solutioning sub-task for #5839; carries the health-home decision design.
- **#6289** — the Stage-5 Solutioning sub-task for #5846; corrected three implementation details of #6281's design, and binds where the two disagree.
- **#6282** — the Stage-6 Engineering sub-task under which the #5839 decision record landed.
- **#6353** — the concurrent unmerged sibling release pull request recorded in the In-Flight Release Roster.

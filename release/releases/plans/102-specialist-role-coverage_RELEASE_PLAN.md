---
title: Release Plan — 102-specialist-role-coverage (one architect flexes across the architecture space; two engineer Specialists earn their own seats by demonstration)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: 102-specialist-role-coverage
release_class: novel
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `102-specialist-role-coverage`

**Milestone:** `102-specialist-role-coverage` (milestone 245). Three member cards, one branch, one pull request, one merge.
**Version identity:** **slug-only** per **ADR-092**. The plan file is `102-specialist-role-coverage_RELEASE_PLAN.md` and the branch is `release/102-specialist-role-coverage`; no version stem appears in the plan filename, the branch name, or this plan's identity prose. Bump class is `minor` — a capability release, not corrective, so the patch floor does not apply. The concrete number binds at the **Stage-12 atomic claim**, which renames this file into the major-version bucket and resolves the `v4.15` token.
**Topology:** **SINGLE** — one release branch, one pull request, one merge gate; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** the Stage-4 recommendation of P0 fully-serial was **superseded at the plan-approval gate**: the operator rendered SINGLE topology with **W2 running its two cards in parallel**, and removed the contention rather than serializing around it by hoisting every registration write into one consolidated W3 commit. Force-push, including the lease-guarded form, is prohibited on the shared branch under any multi-chip activity.
**Release class:** **`novel`** — re-rendered from `cross-cutting` at the Stage-4 plan-approval gate because the declared class fired none of its three triggers while `novel` fired all three. Posture: engagement density **Tight** (operator override of the per-class mapping, so no ceremony is dropped) · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**. Effective size **18** at the `novel` weight.

> **Provenance.** This file transcribes the Stage-4 Release Planning output, reconciled forward through the approved Stage-5 Solutioning designs and the operator decisions rendered at the Stage-4 and Stage-5 gates. Where a later measurement or decision superseded a Stage-4 figure, **this file carries the decided state** and the § Deviation Log records the delta against the Stage-4 plan of record. The Stage-4 output comment is the historical record and is not edited. Authored at Engineering Commit 0 by the first Stage-6 Engineering spoke; the § Change Description is refreshed by the final Engineering slice.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | `v4.15` — slug-only pre-claim (ADR-092); bump class `minor`. Supersedes the provisional `v4.14`, which a sibling release claimed at its own Stage-12 merge. The supersession and its re-run evidence are recorded in § Commit-0 version re-verify below. |
| **Date Created** | 2026-08-07 (Friday) |
| **Release Manager** | Agent-assisted (`release-hub` Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/102-specialist-role-coverage` |
| **Pull Request** | 4979 — created in **draft** at Engineering per the stage contract; transitions to ready-for-review at the plan-review gate |
| **Milestone** | `102-specialist-role-coverage` (245) |
| **Baseline** | `origin/main` @ `f157a811` — Commit-0 re-pin **confirms** the Stage-4 pin; zero commits of drift |

### Commit-0 version re-verify

> **This section carries two records. The Commit-0 record immediately below is SUPERSEDED — it is retained as history, not as evidence. The operative result is § Superseding re-verify at the end of this section.** A passed check whose subject has since changed is worse than no check at all, because a later stage reads the recorded verdict as current. The check did not fail; the world moved under it.

The Stage-4 version determination is **provisional** until the Stage-12 atomic claim, and three sibling releases were in flight when this release entered Engineering, so this re-verify is the rung most likely to fire rather than ceremony. It was re-run at Commit 0 against freshly-fetched authoritative refs, with a known-taken sensitivity arm on every surface:

| Surface | Subject (next-free minor) | Sensitivity arm | Denominator |
|---|---|---|---|
| Origin git tags, freshly fetched (`git fetch --tags origin`) | **0** occurrences | the immediately preceding version: **1** | 157 tags |
| Remote tag refs queried directly at the origin (`git ls-remote --tags`) | **0** occurrences | the immediately preceding version: present | remote ref set |
| Release ledger row, read from `origin/main` with a brace-delimited ref rather than any worktree copy | **0** occurrences | the immediately preceding version: **1** row, state `VERIFIED` | 185 ledger rows |
| Descending version-sorted tag list — the anchor read | anchor resolves to the immediately preceding version, so next-free is the planned version | — | 157 tags |

**Verdict at Commit 0 (`524b40d9`, 2026-08-07 Friday) — SUPERSEDED 2026-08-07, DO NOT READ AS CURRENT: PROCEED.** The planned version is absent from the claimed set on every arm and equals the recomputed next-free off the anchor. No colliding tag or ledger row exists. The branch and this plan file stay slug-primary and do not rename on any later re-derivation.

**Why it is superseded.** The record above was true when it was written and is false now. Between Commit 0 and this entry the sibling `release-check-enforcement-gates` release reached its own Stage-12 atomic claim and bound `v4.14` at merge `52d8a55e`, then closed through Stage 13. Under ADR-092 a version is provisional until that claim, so a superseded provisional is the **designed** path and not a defect in this release's artifacts — the defect would be leaving a passed verdict standing over a subject that has changed. Both records carry an anchor because they fall on the **same calendar day**: a date alone does not separate them, so each is pinned to a SHA.

#### Superseding re-verify — 2026-08-07 (Friday), post-merge

Re-run at merge commit `91f331ab` (this branch after `origin/main` @ `b75feff7` was merged in), against freshly-fetched authoritative refs. Subject is the **candidate** `v4.15`; `v4.14` is carried as the now-taken arm, which doubles as the sensitivity control — a surface that cannot see the version just claimed cannot be trusted to report the next one free.

| Surface | Subject `v4.15` | Now-taken arm `v4.14` | Sensitivity arm `v4.13` | Denominator |
|---|---|---|---|---|
| Origin git tags, freshly fetched (`git fetch --tags origin`) | **0** occurrences | **1** — claimed | **1** | 158 tags (was 157 at Commit 0; the delta is exactly the new tag) |
| Remote tag refs queried directly at the origin (`git ls-remote --tags origin`) | **absent** | **present** | present | 158 remote tag refs |
| Release ledger row, read from `origin/main` with a brace-delimited ref rather than any worktree copy | **0** row-lines | **1** row-line | **1** row-line | 176 ledger table lines |
| Published GitHub Releases (a surface the Commit-0 table omitted) | **absent** | **present** | present | 156 published releases |
| Descending version-sorted tag list — the anchor read | anchor resolves to `v4.14`, so next-free minor is `v4.15` | — | — | 158 tags |

**Verdict: PROCEED at `v4.15`.** The candidate is absent from the claimed set on every arm, the now-taken arm is positively observed on every arm (so no arm is inert), and `v4.15` equals the recomputed next-free off the anchor. The branch and this plan file remain slug-primary and do not rename; the version binds only at the Stage-12 atomic claim, and `claim-version.sh` recomputes it there rather than trusting this row.

**Baseline moved with it.** The § Header `Baseline` row records the Commit-0 re-pin at `origin/main` @ `f157a811` and is retained as that historical statement. The operative baseline for the remainder of this release is `origin/main` @ `b75feff7`, merged in at `91f331ab`; branch freshness against it is **0** commits behind.

**Audit-baseline pin.** Tag sets, ledger rows, and published releases are transiently observable populations — that is precisely how the Commit-0 record went stale. This entry is pinned to `91f331ab` and measured 2026-08-07. **Re-check before relying on it at Stage 12.**

### Domain Practice Provenance

The release plan template predates the `### Release Class declaration` convention, so the provenance label lands here as its sibling H3, per the Stage-4 Planning placement rule.

**Mode B — SHIP-WITH-FLAG.** This is not a purely pipeline-internal release. The *file placement* is entirely internal and therefore exempt from external sourcing, but the *deliverable content* of the security and data cards must encode **external** domain practice — AppSec/SecOps on one side, data engineering on the other — and the platform encodes neither: `core/standards/domain-best-practices/` ships exactly four guides (`governance.md`, `process.md`, `software.md`, `support.md`), with no `security.md` and no `data.md`. Stage 4 therefore resolved Phase A1.5 to the unsourced-domain flag rather than to the pipeline-internal exemption token. The flag travels with this plan by design: Stage 7 Dev Testing verifies its presence and its dated field, and Stage 9 surfaces the gap to the operator rather than letting the pipeline proceed silently. The two missing guides are filed as their own work item — see the § References block — rather than written as a rider here.

**`domain:` classification (A3-time, from the File Change Matrix).** Dominant domain is **`governance`** — the matrix is overwhelmingly instruction corpus (three `SKILL.md` files plus the skill registry), governed by the canonical skill-structure standard. Secondary domain is **`software`** (the deploy-roster array registration and the package rebuild). Recorded as dominant-plus-secondary rather than left ambiguous.

domain_practice: { source: UNSOURCED-DOMAIN, date: 2026-08-06, rationale: "security-engineering and data-engineering practice have no guide under core/standards/domain-best-practices/ (four guides ship: governance, process, software, support); no inline sourcing performed at Stage 4", domain: governance }

The label above is the **Stage-4 rendering, recovered verbatim** — including its original `date` — from the planning sub-task's output comment. It was authored at Stage 4 and dropped in the Commit-0 transcription of that output into this file; Stage 7 Dev Testing found the absence on all three parallel spokes and it is restored here rather than re-authored, so the staleness signal the `date` field exists to carry stays honest. Stage 5 later *refined* the flat "no security guide and no data guide" reading into a split disposition — security partially sourced, data genuinely unsourced — and that refinement is carried in the § Deviation Log row `Δ-unsourced-domain`, which is where a post-Stage-4 delta belongs under this file's own provenance rule.

---

## Change Description

*Operator-facing. Authored at Stage 6 Phase C1; refreshed by the final Engineering slice. The W2 and W3 paragraphs describe planned scope until those slices land.*

**Outcome.** The suite has been answering the same question one skill at a time. Three separate proposals arrived asking for an enterprise architect, a security architect, and a data architect — three new Specialists for three points in one space — and none of them demonstrated the boundary test that a new Specialist owes. This release settles the question as a rule instead of case by case: **domain is a parameter of the architect role, exactly as altitude already was.** It records that rule as a decision record, and then makes the incumbent architect actually carry the space the rule assigns to it — enterprise altitude alongside system altitude, data architecture made real rather than merely claimed, and security as a full third operating mode. Separately and on their own merits, two engineer-role Specialists are built after clearing the same boundary test against the newly-extended architect.

**The through-line.** Every card here turns on one distinction: **is this a different seat, or the same seat at a different setting?** An architect reasoning about security is the same seat with a different method; an engineer running a vulnerability assessment is a different seat. Getting that wrong in either direction is expensive — split too eagerly and the routing surface fills with skills all named "architect" competing for one vocabulary, absorb too eagerly and a genuinely distinct capability ships as a thin sentence. The release pays the price of the honest answer in both directions: the architect absorbs two dimensions as parameters and one as a full mode, and the two engineer proposals are held to a demonstration rather than an assertion.

**Key decisions.** Security ships as a **full third mode**, not a parameter, because the discriminator is *method*, not scope — threat modeling reasons inward from adversary goals through trust boundaries to a control set, and the architect's existing coupling-cost traversal cannot produce that at any parameterization. The decision record was authored at the **mainline next-free number**, not one slot above a sibling branch's unmerged claim, because allocating at the next-free slot is safe under every merge order and allocating above it is safe under exactly one. The architect's frontmatter description was **compressed rather than truncated** to fit the documented character cap — every shipped trigger phrase survives byte-identical, and the six added phrases are domain-anchored rather than a repeated ownership scaffold, which is what keeps the routing surface discriminable. Registration writes for all three cards were **hoisted into one commit** rather than serialized, which removed the contention instead of scheduling around it.

**Reversibility.** **MODERATE** for the release as a whole, with the crossing point being a shipped dimension. The axis rule itself is cheap to supersede at any time — superseding it un-ships nothing, it changes the default for the next domain. The absorbed dimensions are the expensive half: once a dimension's trigger surface is live, the routing vocabulary is claimed, the registry row and the consultation map name the mode, the packaged skill carries it, and extracting the dimension into its own Specialist later is a cross-reference sweep plus a fresh collision audit. Whole-release rollback before deployment is a revert of the merge commit.

**Downstream impact.** A request about the security properties of a design now has an owner that renders a decision rather than only a review. Three previously-open proposals resolve by rule rather than by re-litigation. The architect's trigger surface grows by six phrases; the measured boundary against the within-component principal engineer does not loosen — it tightens, because domain-anchored phrasing adds discriminating vocabulary rather than shared vocabulary. Contributors adding a future architecture domain now have a recorded answer to start from and a stated bar: a domain that cannot be authored to the depth of the existing modes is evidence to revisit the rule, not permission to ship it thin.

**What this release does NOT claim.** It does not claim the platform has an architecture-level threat-modeling practice guide — it does not, the gap is named in the security mode's own sourcing note, and it is filed as its own work item rather than written as a rider here. It does not claim a data-architecture practice source exists — there is none in the corpus. It does not claim that the architect's output ownership was re-derived by tooling: the ownership-invariant check the governing decision record names is designed but unimplemented, so the reconciliation here is manual and is recorded as such. And it does not settle the numbering contest on the decision record: the number is claimed at authorship and bound at merge, so a merge-time renumber is expected and tooled rather than avoided.

---

## Scope

### Summary

Three member cards. One extends a shipped skill along two parameter axes; two build net-new engineer Specialists that must first demonstrate they deserve to exist. One decision record is authored in-scope as the foundation the first card's rationale cites.

### Members

| Card | Size | What it does |
|---|---|---|
| **Extend the architect across altitude and domain** | L / 8 | Adds enterprise altitude and the data dimension as parameters on the existing modes, and security as a full third mode. Supersedes three separate architect proposals. |
| **Build the security-engineer Specialist** | M / 4 | Net-new engineer-role Specialist, boundary-tested against the software engineer, the devops/SRE skill, and the newly-extended architect's security mode. |
| **Build the data-engineer Specialist** | M / 4 | Net-new engineer-role Specialist, boundary-tested against the software engineer and the newly-extended architect's data dimension. |
| **The axis decision record** | in-scope, W0-adjacent | Records that the skill-boundary rule ranges over the domain axis exactly as it already ranged over altitude. Authored `Proposed`; ratified at the release close gate. |

16 raw points, 18 effective at the `novel` class weight — inside the composition band, so no override is required.

### Scope lock

The Stage-5 Collective Review scope-lock rendered three decisions, all recorded on the member cards' Stage-5 sub-tasks:

- **Security shape** — ACCEPT the third mode as designed. The alternative of deferring security and shipping only altitude and data was **declined**. Acceptance grading at Stage 8 is **comparative against the first mode's depth**, not "does a security trigger exist".
- **Unsourced domain** — partial in-scope sourcing plus a separate filing. The software practice guide's security section is cited in-scope as the anchor for the control-selection half of the security mode; a named residual is carried for architecture-level threat modeling and for the data domain; the two missing guides are filed as their own work item.
- **W2 route** — parallel, with a shared constraint. Both engineer cards spawn together carrying the domain-anchored trigger requirement as a hard constraint, and the cross-skill trigger audit runs on the **union** of both trigger sets, not per card. A per-card pass does not imply a pairwise pass.

---

## Dependency Graph

```
architect-extension ──► security-engineer   (hard: the boundary test runs against the EXTENDED architect's security mode)
        │
        └────────────► data-engineer        (hard: the boundary test runs against the EXTENDED architect's data dimension)

security-engineer ── ∥ ── data-engineer     (no dependency edge; independent capability, shared registration surface)
```

**Two directional edges. Zero circular chains.** Both edges are hard rather than stylistic: each engineer card's first acceptance criterion requires distinguishing itself from a surface that the architect extension *changes*. Running that test against the pre-extension architect grades the wrong artifact.

---

## Implementation Sequence

| # | Wave | Work | Rationale |
|---|---|---|---|
| 1 | W1 | Release plan file (this file) | Engineering Commit 0. Carries the version re-verify and the machine-readable file change matrix downstream stages extract. |
| 2 | W1 | The axis decision record | Must land before the architect extension's rationale is citable. The founding decision record for role-scale work is the first slice. |
| 3 | W1 | Architect extension | Foundation. Establishes the extended surface both engineer cards are boundary-tested against. |
| 4 | W2 | Security engineer ∥ Data engineer | Parallel per the operator route. Both carry the domain-anchored trigger constraint; the collision audit runs on the union. |
| 5 | W3 | Consolidated registration + package rebuild | Single commit for the skill catalog row edits, the deploy roster array, and every package rebuild. This is what makes the W2 parallel verdict safe. |

---

## Stage Applicability Matrix

| Card | S5 | S6 | S7 | S8 | S9 | S10-13 | Notes |
|---|---|---|---|---|---|---|---|
| Axis decision record | RUN | RUN | SKIP | SKIP | RUN | RUN | A decision record has no runtime surface to exercise. Graded at plan review. |
| Architect extension | RUN | RUN | RUN | RUN | RUN | RUN | Behavioral: the trigger surface and the mode set both change. |
| Security capability | RUN | RUN | RUN | RUN | RUN | RUN | **Resolved to a dimension pack on an existing skill, not a net-new skill.** Full ladder still applies — the reviewer's trigger surface and pack set both change — but exercise it as a **pack integration**: pack schema conformance and depth, the reviewer's recomposed description, and the union collision audit. There is no new skill directory to scan, and a structural check that does not name a new skill is correct here rather than a gap. |
| Data engineer | RUN | RUN | RUN | RUN | RUN | RUN | Net-new skill; full ladder. |

Dev testing and acceptance testing are genuinely run for the three functional cards — not collapsed into continuous integration plus the plan-review gate.

---

## Contention Map

### Within-release

| Surface | Writers | Disposition |
|---|---|---|
| Skill catalog (`core/skills/registry.md`) | all three cards | **Hoisted to the W3 consolidated commit.** The Stage-4 plan corrected the milestone's parallelization map here: its claim that the two engineer cards share no corpus contention is false — both acceptance criteria name the catalog and the deploy roster verbatim. The parallel *verdict* survives via the hoist; the stated *basis* did not. |
| Deploy roster array (`core/deploy/deploy.sh`) | the two engineer cards only | **Hoisted to W3.** The architect is already in the roster array, so the architect extension owes no edit here — verified at Stage 5, which removed one arm of the contention entirely. |
| Consultation map (`core/specs/skill-consultation-map.md`) | architect extension, and potentially the data-engineer card | **Coordinated, not raced.** The architect extension adds one capability-dimension row and reconciles the two count-bearing sentences into count-free form, which structurally removes the row-count race for any later writer. Recorded in that commit's sweep record. |
| Everything else | one writer each | No contention. |

**Roster-count invariant.** The catalog's routing-view counts move by **+1 skill, not +2**: one of the two engineer proposals resolved to a dimension pack on an existing skill rather than a new catalog row. The non-role catalog-item count is **invariant** across this release — a mechanical "add N everywhere" sweep over the count-bearing cells corrupts it and must not be run.

### Cross-release

Three sibling releases were in flight at the Commit-0 baseline. None of them touches the architect skill directory, the skill catalog, or the consultation map. The only shared file in the Stage-4 release-scoped matrix was the deploy script, whose hunks sit thousands of lines away from the roster array this release edits — a rebase, not a conflict. Residual cross-release contention for the W1 card specifically: **none**.

---

## Risk Register

| ID | Risk | Class | Sev | Reversibility / Confidence | Mitigation |
|---|---|---|---|---|---|
| **R1** | The axis decision is later reversed, inverting the extend-not-split rationale and re-opening three closed proposals. | Scope | HIGH | MODERATE / MEDIUM | The record is authored `Proposed` at W0, *before* the extension builds, so the reversal decision is forced while it is still cheap. Ratified at the release close gate against the file's own status field, never inferred from a review comment or a plan row. |
| **R2** | The security dimension ships thin — threat modeling has a different method from cross-component design and is the dimension most likely to be under-served. | Quality | HIGH | MODERATE / HIGH | Resolved by design, not by hope: security ships as a full mode with its own trigger set, composition edge, five-step process, output contract, reversibility rubric row, and domain failure mode. **Acceptance grades it comparatively against the first mode's depth.** If depth cannot be reached, that is evidence to revisit the axis decision — not licence to ship thin. |
| **R3** | The boundary demonstration fails at solutioning for one or both engineer cards, and the card resolves to a mode on an existing skill. | Scope | MED | CHEAP / HIGH | A legitimate outcome, not a defect — the default the boundary rule prescribes. Both cards cleared their Stage-5 designs; one resolved to a dimension pack rather than a new skill, which is exactly the rule working. |
| **R4** | An output-ownership invariant is violated — a second maintainer lands on an entity that already has one. | Governance | MED | CHEAP / HIGH | No automated check exists; the ownership check the governing decision record names is designed but unimplemented. Reconciled manually, per entity, with the verdict recorded. The architect's security mode **composes** the technical-analyst for security findings and never declares them, which closes the one live risk structurally: the finding source field is a closed enum whose maintainer is a different skill. |
| **R5** | Package drift — a stale packaged-skill baseline fails the deploy check. | Build | MED | CHEAP / HIGH | Every touched skill's package and its content-baseline sidecar are rebuilt from the build tool and committed in the same pull request. Known-recurring cluster. |
| **R6** | Cross-release contention on the deploy script — three siblings hold unmerged edits. | Contention | LOW | CHEAP / HIGH | Disjoint hunks, thousands of lines apart. Re-checked at the plan-review divergence checkpoint and again pre-merge. |
| **R7** | Trigger-collision regression — five role-anchored trigger sets expand at once. | Quality | MED | CHEAP / HIGH | Domain-anchored phrasing is mandatory and measured. A uniform ownership scaffold reproduces the documented five-collision regression at an escalating score between the two engineer peers; domain-anchored phrasing keeps every pair comfortably passing. The audit runs on the **union**. |
| **R8** | Rollback complexity — a shipped dimension's trigger surface is claimed. | Rollback | MED | MODERATE / HIGH | Single pull request, single merge: a revert of one merge commit restores every matrix path atomically. Cheap until deployment, moderate thereafter. |
| **R9** | The decision record's number is contested — two unmerged sibling branches hold the same number for unrelated decisions. | Governance | LOW | CHEAP / HIGH | **Accepted residual, by design.** A number is claimed at authorship and bound at merge; first-to-merge keeps it and the losers renumber with the provisioned tool at the execute stage. Stepping past the claim to a higher slot is the defect, not the remedy — it lands a hole on the mainline that the contiguity gate then fails on every subsequent pull request. |

**Rollback strategy.** The milestone ships as one pull request and one merge. Pre-deployment rollback is a revert of the single merge commit, which restores every matrix path atomically. Post-deployment rollback additionally requires re-running the deploy script to drop the new skill from the deployed roster and restore the architect's package baseline. No data migration, no external state. **Tier: MODERATE, HIGH confidence.**

---

## Cross-Issue Acceptance Criteria

- [ ] **CIAC-1 — trigger surface.** No trigger phrase in the extended architect's security or data dimension collides with a trigger phrase in either engineer Specialist; all trigger sets are domain-anchored rather than uniform ownership scaffolds. *Shared surface:* the frontmatter descriptions of the three skill files plus their catalog rows. *Method:* the cross-skill evaluation audit's collision arm, run on the **union** of the release's trigger sets, with zero new role-to-role collisions against the pre-release baseline. **Baseline to beat: the architect's maximum pairwise score does not exceed its pre-release value.** *Graded at plan review on the merged pull request.*

- [ ] **CIAC-2 — entity ownership.** The union of outputs declared by the release's skills satisfies the two ownership invariants: exactly one maintainer per entity, and any skill declaring maintainer-write to an entity is that entity's recorded maintainer. *Shared surface:* the owning-agent matrix in the project entity model. *Method:* **declared, verification deferred** — the tooling check is designed but unimplemented, so this is reconciled manually at acceptance testing with the verdict recorded per entity. *Graded at plan review on the merged pull request.*

- [ ] **CIAC-3 — roster parity.** Every skill added or edited by this release appears in all four registration surfaces — the skill catalog, the deploy roster array, the packaged skill, and its content-baseline sidecar — with no surface carrying an entry the others lack. *Method:* the deploy check returns no failure line for roster or package drift, cross-checked by a per-surface presence probe. *Graded at plan review on the merged pull request.*

---

## File Change Matrix

Machine-readable path list — one path per line, for deterministic extraction by downstream stage prompts.

```
core/ADRs/ADR-123-domain-is-a-parameter-of-the-architect-role.md
release/skills/pmo-architect/SKILL.md
release/skills/pmo-architect/references/composition-and-reversibility.md
core/specs/skill-consultation-map.md
packages/pmo-architect.skill
packages/pmo-architect.skill.sha256
release/skills/build-reviewer/references/dimension-packs/security-dimensions.md
release/skills/build-reviewer/references/dimension-packs/README.md
release/skills/build-reviewer/SKILL.md
packages/build-reviewer.skill
packages/build-reviewer.skill.sha256
release/skills/pmo-data-engineer/SKILL.md
release/skills/pmo-data-engineer/references/composition-contract-data-engineer.md
core/skills/registry.md
core/deploy/deploy.sh
packages/pmo-data-engineer.skill
packages/pmo-data-engineer.skill.sha256
release/releases/plans/102-specialist-role-coverage_RELEASE_PLAN.md
```

**Matrix reconciled at the final Engineering wave — read this before treating a path as a gap.** The block above was corrected against the branch's actual changed-path set rather than against the wave reports, because it is parsed deterministically and a wrong path reads downstream as a false gap or a hard failure. Two corrections landed.

**(1) The security-engineer paths are gone, and no path replaces them one-for-one.** The security card resolved to **MODE, not SPLIT** at the Stage-5 Collective Review scope-lock: its three-conjunct demonstration failed conjuncts two and three on enumerated evidence — six candidate write surfaces with none unclaimed, and the one distinct method already allocated to the architect's third mode one wave earlier. The capability therefore ships as a **`security` dimension pack on `build-reviewer`**, selected by `--pack=security`, and the three paths the matrix previously carried (`release/skills/pmo-security-engineer/SKILL.md` and its two package artifacts) **will never exist**. They are replaced by the five `build-reviewer` paths above. Consequently this card owes **no** skill catalog row, **no** deploy roster entry, and **no** new package — the earlier contention on those two registration surfaces dissolves to zero for this card and remains only for the sibling engineer card.

**(2) One already-landed path was absent and has been added:** the data-engineer's composition-contract reference file. It landed in the second wave, which correctly declined to edit this shared plan from its own card's scope; it is added here under the same cross-card reconciliation, so the block matches the branch.

**Still pending, correctly listed, not yet landed:** the skill catalog, the deploy roster array, and the data-engineer package plus its sidecar — all owned by the consolidated registration wave.

**Per-wave intent:**

| Wave | Path | Operation | Notes |
|---|---|---|---|
| W1 | this plan file | **add** | Engineering Commit 0, slug-primary; binds to the version-keyed path only at the Stage-12 atomic claim. |
| W1 | the axis decision record | **add** | Authored at the mainline next-free number, `status: Proposed`. Number is claimed here and bound at merge. |
| W1 | architect skill body | **edit** | Description recomposed to the compressed form; a third mode inserted at full depth; the altitude section becomes a three-rung ladder plus a domain row; a fourth domain failure mode added; the mode-count strings swept. **Hook-gated** — routed through the skill-editor discipline, with the audit-trail trailer on the commit. |
| W1 | architect reference file | **edit** | Third-mode composition row, a reversibility rubric row for the new output class, and the reachable-surface branch of the blast-radius procedure. **Hook-gated** — same session. |
| W1 | consultation map | **edit** | The architecture row admits the third mode; one new security-architecture capability-dimension row; the two count-bearing sentences reconciled to count-free form. |
| W1 | architect package + sidecar | **rebuild** | Generated by the package build tool — never hand-edited. |
| W2 | security dimension pack | **add** | **Superseded intent — was "security-engineer skill body / add".** Resolved to MODE: a `security` pack under the reviewer's dimension-pack directory, 8 dimensions in 3 areas. **Not hook-gated** (the skill-edit hook's scope regex is single-level and does not reach a nested reference subtree). |
| W2 | dimension-pack registry | **edit** | One registry row, plus a recorded shadowing property — the platform pack's core-wide glob subsumes two of the security pack's four detection patterns and scans first. **Not hook-gated.** |
| W2 | reviewer skill body | **edit** | Six pack-level triggers, the pack list, the severity-scale line, a seventh domain failure mode, a design-time see-also pointer. **Hook-gated** — routed through the skill-editor discipline, with the audit-trail trailer on the commit. |
| W2 | reviewer package + sidecar | **rebuild** | Generated. Built cleanly — this skill was already rostered, so no pre-registration block applied. |
| W2 | data-engineer skill body | **add** | Net-new Specialist, domain-anchored triggers. |
| W2 | data-engineer reference file | **add** | Composition contract, offloaded because the body crossed the size threshold that makes a non-empty reference directory required. |
| W3 | skill catalog | **edit** | The architect's existing row (mode cell and trigger-surface cell) plus **one** new-skill row. **Do not run a mechanical count sweep** — the non-role item count is invariant, and the roster delta is **+1, not +2**, because the security capability ships as a function-skill's dimension pack rather than as a role Specialist. |
| W3 | deploy roster array | **edit** | One new skill entry. The architect is already present and owes no edit; so is the reviewer. |
| W3 | data-engineer package + sidecar | **build** | Generated. The roster entry must land before or with the build, or the build errors on module resolution. |

**Files deliberately NOT in the matrix, with the reason stated so the omission is visible:** the **project entity model** — the architect extension declares no new entity ownership, and the manual reconciliation confirmed it declares maintainer-write to zero entities before and after; the **per-skill output-contract schema** — no role Specialist has a row there today, so adding only one would create a one-of-twenty asymmetry, and it is routed to a separate work item; the **deploy script** for the architect card specifically — already registered.

---

## Verification Plan

| Card | Verification method | Expected result |
|---|---|---|
| Axis decision record | structural conformance plus the numbering gate | Canonical section headers present; the contiguity gate passes with the record at the mainline next-free slot and no hole. |
| Architect extension — enterprise altitude | section presence plus trigger presence | The altitude section renders three rungs with the solution rung ceded verbatim to the principal engineer; the enterprise trigger phrase is present in the description. |
| Architect extension — security domain | **comparative depth grading**, not trigger presence | The third mode carries every subsection its peer mode carries — trigger, purpose, composition, a five-step process, output contract, and a sourcing note — plus a dedicated failure-mode entry. Graded against the first mode's depth. |
| Architect extension — data domain | parameter declaration plus trigger presence | The data parameter is declared on the existing modes; both data trigger phrases present; the description's pre-existing data claim is made real rather than restated. |
| Architect extension — trigger phrasing | string probe over the trigger clause | No ownership-scaffold string is replicated across dimensions. Every shipped trigger preserved byte-identical. |
| Architect extension — description cap | character count of the frontmatter description | Under the documented cap with headroom. **The cap is documented but not gate-enforced — nothing catches a regression, so it is measured explicitly here.** |
| Architect extension — collision audit | the cross-skill evaluation audit | Corpus verdict passes with zero escalations; the architect's maximum pairwise score does not exceed its pre-release value. |
| Architect extension — ownership | manual reconciliation against the owning-agent matrix | Zero entities carry the architect as maintainer, before and after. The security mode composes rather than declares findings. |
| Both engineer cards | boundary demonstration plus the union collision audit | Each names the boundary test it passed rather than asserting it would pass; the union audit returns zero escalations. |
| Whole release | the deploy check and the package-freshness gate | No failure line for roster or package drift. |

---

## Quota Budget

**Verdict:** **PASS**
**Parallel-eligible spokes per parallel stage:** Stage 5: 3 · Stage 7: 3 · Stage 8: 3. The decision record is excluded from the dev-test and acceptance counts — it skips both.
**Per-spoke cost estimate:** ordinal size-bucket band; source **heuristic**, no telemetry medians for these buckets. Worst batch: one large plus two medium.
**Assumed remaining usage-window envelope:** not operator-stated at hub start; conservative default assumed.
**Estimated cumulative draw:** not numerically derivable — the bands are ordinal, not absolute token counts, and no envelope was stated. Rendering a percentage would be fabricated precision. Ordinal assessment: a three-spoke worst batch is a small fan-out against any plausible envelope, comfortably inside the passing band.
**Routing:** **PASS — proceed parallel.** No warning carried.
**Note:** this is a cumulative-draw budget, not a rate-limit problem — a launch stagger does not reduce cumulative consumption. This one-time estimate is advisory; the runtime checkpoint re-validates at every parallel wave and is the load-bearing gate.

---

## Delivery Strategy

Single release branch, one pull request, one merge gate. Commit 0 is this plan file alone; the remaining commits land one per logical unit in wave order. **Commit-0 version re-verify is mandatory and was run — see § Header.** Commit messages carry no personal email address and no user-home path; continuous integration hard-fails a commit message that does.

The pull request is created in **draft** at Engineering and transitions to ready-for-review at the plan-review gate, so the operator reviews completed work rather than work in progress. The pull request body confines tracker references to a designated block and uses safe phrasing everywhere else, so no auto-close fires at merge; member cards are **marked closed at the release close stage** against close-out evidence.

---

## Rollback

**Whole release:** revert the merge commit. The merge is a true two-parent commit, so the first-parent revert form applies.

**Per wave:** revert that wave's commits. The W1 file set is disjoint from W2's; W3 touches the shared registration surfaces alone, so reverting it cleanly un-registers without disturbing the skill bodies.

**The one asymmetry worth naming.** Reverting the architect extension after deployment does not automatically un-claim the trigger vocabulary in any consumer that has already routed against it. The revert restores the files; the routing behavior follows on the next deploy. That is the reason the release-level tier is MODERATE rather than CHEAP, and it is the same asymmetry the axis decision record names in its own reversibility section.

**Numbering rollback is not a rollback.** If a sibling release merges its competing decision record first, this release's record renumbers with the provisioned tool at the execute stage. That is the designed path, not a failure, and it touches only the record's filename, title, status note, and any in-release citation.

---

## Deviation Log

Deltas against the Stage-4 plan of record. The Stage-4 output comment is historical and is not edited; **this file carries the decided state.**

| ID | Stage-4 plan of record | Corrected state in this file | Source |
|---|---|---|---|
| **Δ-adr-number** | The decision record was to be authored one slot above the mainline top, on the reasoning that the next-free slot was claimed by a further-along sibling branch. | **Authored at the mainline next-free slot.** Next-free is the mainline anchor plus one — never the maximum of the claimed set. An unmerged branch claim is advisory: it changes the report, never the number. Allocating at the next-free slot is safe under every merge order; allocating above it is safe under exactly one, and lands a hole the contiguity gate fails on every subsequent pull request. The higher slot was also itself claimed, so the step-past bought nothing. | Stage-5 blocker finding, hub correction concurring |
| **Δ-security-shape** | Three dimensions implied three parallel treatments. | **Two parameters and one full mode.** Altitude and data are reached by the incumbent's existing method at a different scope, so they are parameters; security runs a different procedure and terminates in a different output shape, so it earns a mode. Shipping security as a parameter *is* the thin mode the card's own watch-item warns about. | Stage-5 design, operator-accepted at scope-lock |
| **Δ-unsourced-domain** | Recorded flatly as "no security guide and no data guide". | **Split.** Security is *partially* sourced — the software practice guide's security section exists and is already the architect's cited design-time anchor, but it covers implementation-level control hygiene rather than architecture-level trust-boundary decomposition. Data is *genuinely* unsourced — zero data-architecture framework sources corpus-wide. The in-scope citation is taken for the control-selection half; the residual is named for the rest; the two guides are filed separately. | Stage-5 refinement, operator-rendered |
| **Δ-deploy-sh-dropped** | The deploy script appeared in the release-scoped matrix as contended for the architect card. | **The architect card owes no deploy-script edit** — it is already in the roster array. This removes one arm of the four-way contention for that card and makes its residual cross-release contention zero. | Stage-5 verification |
| **Δ-consultation-map-added** | The architect card's file set did not include the consultation map. | **Added.** The map names the architect *by mode*, so a third mode must route. One row is added, the architecture row is updated, and the count-bearing prose is reconciled to count-free form so a later writer adding a row does not have to race a number. | Stage-5 blast radius |
| **Δ-registry-hoisted** | The concurrency recommendation was fully-serial execution. | **Parallel W2 with registration hoisted to W3.** The contention was removed rather than serialized around. Registration edits are explicitly out of the W1 card's scope. | Operator decision at the plan-approval gate |
| **Δ-roster-delta** | Two net-new skills implied a roster delta of plus two. | **Plus one.** One of the two engineer proposals resolved at Stage 5 to a dimension pack on an existing skill rather than a new catalog row, so it adds no row. The non-role catalog-item count is **invariant**; a mechanical count sweep corrupts it. | Stage-5 outcome |
| **Δ-description-cap** | Not identified at Stage 4. | **A real feasibility constraint.** The naively-composed description overruns the documented cap by a wide margin; a compressed form fits with headroom and preserves every shipped trigger byte-identical. The cap is documented but **not gate-enforced**, so nothing catches a regression — it is verified by explicit measurement. | Stage-5 feasibility assessment |
| **Δ-class-and-density** | Release class declared `cross-cutting`. | **`novel`**, with engagement density held at **Tight** by operator override so no ceremony is dropped. The declared class fired none of its three triggers; the replacement fires all three. Effective size 18. | Operator decision at the plan-approval gate |

---

## References

Designated reference block. Each entry pairs the tracker number with a summary noun phrase, so the meaning survives even if the number does not.

| Number | What it is |
|---|---|
| Milestone **245** | `102-specialist-role-coverage` — this release's milestone; three member cards, effective size 18, class `novel` with Tight engagement density. |
| **#2110** | Extend the architect across both parameter axes — altitude and domain. The W1 foundation card; supersedes three separate architect proposals. |
| **#2094** | **Resolved to MODE, not SPLIT.** Proposed as a hands-on security-engineer Specialist; the three-conjunct boundary test was run against the software engineer, the devops/SRE skill, and the extended architect's security mode, and it **failed conjuncts two and three** — six candidate write surfaces with none unclaimed, and the one distinct method already taken by the architect's third mode a wave earlier. Ships instead as a **`security` dimension pack on the build reviewer** — 8 review-time AppSec/SecOps dimensions in 3 areas, selected by `--pack=security`. No new skill, no catalog row, no roster entry, no ownership-enum change. The capability is delivered; only its home moved. |
| **#2112** | Build the data-engineer Specialist — engineer-role, hands-on; boundary-tested against the software engineer and the extended architect's data dimension. |
| **#4934** | The Stage-4 release-planning sub-task carrying this plan's source output and the operator's plan-approval decision record. |
| **#4936** | The Stage-5 solutioning sub-task for the architect extension — carries the design spec, the decision-record body, and the operator rulings this file reconciles forward. |
| **#4975** | The missing security and data domain best-practice guides — filed as its own work item rather than written as a rider on a skill extension. |
| **#4929** | The unimplemented output-ownership check — the reason the ownership invariants here are reconciled by hand rather than by tooling. |
| **#4931** | The stale section-anchor citations in the member card bodies, repaired at the Stage-4 gate. |
| **ADR-019** | Specialists compose, not absorb — the three-conjunct skill-boundary test this release's axis decision applies rather than amends. |
| **ADR-038** | The skill catalog as configuration database — the reason a domain absorbed as a mode edits one existing row instead of appending one. |
| **ADR-044** | The skill-output ownership model — the source of the two invariants reconciled manually in CIAC-2. |
| **ADR-092** | Release branches and plan files are slug-primary; the concrete version binds at the Stage-12 atomic claim. |
| **ADR-094** | Extend before create — the general form of this release's default, applied here to a role rather than a file. |
| **ADR-114** | The composition-aware trigger-collision gate — the standing enforcement behind CIAC-1. |
| **ADR-115** | An ADR number is allocated at authorship and bound at merge — the rule that decided this release's decision-record number. |
| **ADR-123** | Domain is a parameter of the architect role, exactly as altitude is — this release's own decision record, authored in-scope at W1. |

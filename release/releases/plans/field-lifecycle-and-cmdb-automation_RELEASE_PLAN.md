<!-- reference-durability: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-version-ref -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — field-lifecycle-and-cmdb-automation

> Stage 4 release plan of record. Authored at Stage 4 Planning; copied to this committed plan file at Stage 6 Engineering Commit 0 (SINGLE-branch topology). Source: Milestone `13-field-lifecycle-and-cmdb-automation`, parent epic project-data-architecture (the L3 entity-lifecycle-automation + write-permission + per-project-CMDB layer). The operator decision record (Stage 4 Plan Approval) is reproduced in the **Operator Decisions** section below as the authoritative gate-decision record for this release.

**Version:** v2.20 (minor — provisional until the Stage 12 atomic claim) · **Release Class:** cross-cutting · **Topology:** single release branch `release/v2.20-field-lifecycle-and-cmdb-automation` off `origin/main` · **Anchor:** v2.19 · **Commit-0 re-verify:** v2.20 free, anchor v2.19, zero in-flight `release/*`/`chore/v*` branches and zero open PRs at branch-cut (2026-06-22).

---

## Stage 4 Release Planning — field-lifecycle-and-cmdb-automation

### Summary (30 seconds)

This milestone delivers the **G8 entity-lifecycle automation + G10 write-permission + per-project CMDB** layer of the Project Data Architecture initiative. The release ships **nine deliverables**: the seven in-scope milestone issues (the project-scoped lifecycle protocol, the shared+portfolio lifecycle protocol, the per-project Artifact-Register + skill-CMDB, the write-permission↔matrix alignment, the project-tracking-integrity sweep, the G10 write-permission matrix, and the skill-integration story) plus two reconciliation deliverables folded in during planning (the artifact-workflow-protocol promotion-state reconciliation and the lifecycle-states-canonical three-way artifact_state mapping).

One dominant dependency spine and two independent satellites:

- **The spine (5 issues):** the project-scoped lifecycle protocol **+** the shared+portfolio lifecycle protocol are **co-dependent** (they share one 5-column transition-table format) and together **block** the skill-integration story (the only behavior-changing issue) and the G10 write-permission matrix; the matrix **blocks** the write-permission↔matrix alignment. Critical path = **{project-scoped protocol ∥ shared+portfolio protocol} → skill integration**.
- **Satellite 1 — the Artifact-Register / CMDB issue:** independent of the spine. Restored to **full scope** (Artifact Register **and** skill-CMDB) per the operator decision, under a hard **single-registry** constraint — the CMDB *mechanism* is a Stage 5 design decision + ADR (Option A: evolve the one registry / realize the CMDB as a reference schema over existing sources), not a second registry.
- **Satellite 2 — the project-tracking-integrity sweep:** the outlier (only `status: deferred`, only `cluster: cross-cutting`). **KEPT in-release** per the operator decision (override of the spoke defer recommendation); it gets a dedicated **Stage 5 Solutioning** wave to set the dormancy window (**10 business days**) and the overdue-decision threshold (**3–5 business days**), which the issue body leaves unset.
- **Release Class = cross-cutting** (operator decision; cross-cutting trigger fires on the ≥3 in-bundle compositional edges in the spine). **Version = v2.20 minor** (operator decision; anchor v2.19, the orphan v3.20 tag correctly excluded by the `git describe` reachability rule).

### Domain Practice Provenance

domain_practice: { source: N/A — pipeline-internal release, date: 2026-06-22, domain: governance }

This is a pipeline-internal / governance release — its entire File Change Matrix is internal pmo-platform artifacts (protocol docs, schemas, governance edits, and skill SKILL.md edits via the pmo-skill-editor discipline). Per `release/references/pipeline/stage-04-planning.md` § 5.7 (Domain-Best-Practice sourcing exemption for software/governance/pipeline-internal releases), no *external* domain best-practice applies; the `governance` domain class points downstream design-aware consumers at the platform's own internal-deliverable practice. Exempt from external sourcing only — NOT from domain classification.

---

### Scope — the nine deliverables

| Deliverable | Type | Role | Stage 5 footprint |
|---|---|---|---|
| Project-scoped entity-lifecycle protocol | task | Author `core/standards/entity-lifecycle-protocol.md` — 10 project-scoped entities' Axis-1 transition tables (G8 protocol). **Wave 0a.** | LIGHT (transcription against the frozen entity model) |
| Shared+portfolio entity-lifecycle protocol | task | Author `core/standards/entity-lifecycle-protocol-shared-portfolio.md` — 8 shared+portfolio entities' Axis-1 transition tables; format-identical co-lock with the project-scoped protocol. **Wave 0a.** | LIGHT (transcription against the frozen entity model) |
| Per-project Artifact Register + skill-CMDB | story | Artifact-Register schema row + template + tracker-manager SKILL.md maintenance; **single-registry** skill-CMDB realized via the Stage 5 mechanism decision + ADR. **Satellite.** | FULL (CMDB architecture + ADR) |
| Write-permission↔matrix alignment | task | Align `release/references/specs/ticket-information-architecture.md` § Agent Write Permissions to the G10 matrix (mechanical cell reconciliation). | SKIP (mechanical reconcile) |
| Project-tracking-integrity sweep | task | Dormancy / overdue-decision / gate-evidence sweep across the tracking skills. **KEPT** per operator; needs thresholds set at Stage 5. **Satellite.** | REQUIRED (dormancy window 10bd + overdue threshold 3–5bd) |
| G10 entity-field-lifecycle write-permission matrix | task | Author `core/schemas/entity-field-lifecycle-matrix.md` — 18 entities × write/append/read-only × conflict-winner × audit-trail. **Wave 1.** | LIGHT (thin design slice: conflict-winner + audit-trail) |
| Skill integration (the value leg) | story | EXTEND ppm-agent / tracker-manager / artifact-generator SKILL.md to emit/consume Axis-1 transitions. **Wave 2.** Behavior-changing — own PR. | FULL (3-skill cascade + Autonomy-Tier guards) |
| Artifact-workflow-protocol promotion-state reconciliation | reconciliation | Fold the Artifact-Workflow operational protocol (`DRAFT→REVIEWED→APPROVED→PROMOTED→ARCHIVED`) into a co-located protocol doc carrying `promotion_state`, reconciled against the Artifact entity Axis-1↔Axis-2 delegation seam. **Wave 0b.** | (folded into the W0b authoring) |
| lifecycle-states-canonical three-way artifact_state mapping | reconciliation | Reconcile the three adjacent artifact-state expressions (entity Axis-1 delegation · Artifact-Workflow `§3.2` · frontmatter-schema Category-2 Domain A/B/C) into one `artifact_state` mapping. **Wave 0b.** | (folded into the W0b authoring) |

**This plan file is authored at Wave 0a (Commit 0).** The two co-dependent protocol docs (project-scoped + shared+portfolio) ship in the same Wave-0a PR with this plan as Engineering Commit 0. The two reconciliation deliverables are **Wave 0b** (a separate spoke) and are NOT authored in this Wave-0a commit set.

---

### Dependency Graph

Directional edges derived from each issue body's `## Dependencies` block (verified against live frozen-surface state):

```
            [frozen: project-entity-model.md §4/§5.1/§6, entity-field-schemas.md §5 — LIVE]
                                        │ (design parents — not in-scope issues)
            ┌───────────────────────────┴───────────────────────────┐
            ▼                                                         ▼
   project-scoped protocol (a)  ◄──co-dependent──►  shared+portfolio protocol (b)
   10 project-scoped entities      (shared 5-column transition-table format)   8 shared+portfolio entities
            │   │                                            │
            │   └──────────────┐                ┌────────────┘
            │                  ▼                ▼
            │            skill integration (c)  [BEHAVIOR-CHANGING — story]
            │            (blocked by BOTH protocol docs)
            ▼
   G10 write-perm matrix   (blocked by a+b — keys on the transitions)
            │
            ▼
   write-perms↔matrix alignment   (blocked by the matrix)

   Artifact-Register / CMDB        — INDEPENDENT satellite (full scope, single-registry, Stage 5 + ADR)
   project-tracking-integrity sweep — INDEPENDENT satellite · KEPT · requires Stage 5 (thresholds)
   artifact-workflow-protocol reconciliation + artifact_state mapping — Wave 0b (downstream of the protocol docs)
```

**Edge ledger (verified against issue bodies):** the two protocol docs are co-dependent on a shared table format and jointly block skill integration; the project-scoped protocol also blocks the G10 matrix; the matrix blocks the alignment task; the Artifact-Register/CMDB and integrity-sweep issues are dependency-independent. All edges match the milestone's frozen-surface derivation.

---

### Implementation Sequence

Dependency-ordered waves. Within a wave, issues are parallel-eligible at the stages the Stage Applicability Matrix marks parallel-safe — subject to the tracker-manager contention note.

**Wave 0a — Co-dependent protocol authoring + the release plan (this commit set, the foundation):**
- Establish the release branch `release/v2.20-field-lifecycle-and-cmdb-automation` off `origin/main`; commit this plan file as Engineering Commit 0.
- Author `core/standards/entity-lifecycle-protocol.md` (10 project-scoped entities, Axis-1 transition tables).
- Author `core/standards/entity-lifecycle-protocol-shared-portfolio.md` (8 shared+portfolio entities) — **same 5-column format**, co-located in `core/standards/` per operator directive (NOT `core/disciplines/`), format-identical to the project-scoped doc.
- *Co-dependent → authored together so the shared 5-column transition-table format is byte-pattern-identical across both docs.*

**Wave 0b — Artifact-state reconciliation (separate spoke — NOT in the Wave-0a commit set):**
- Author/promote the Artifact-Workflow operational protocol doc carrying `promotion_state`.
- Reconcile the three adjacent artifact-state expressions into one `artifact_state` mapping (entity Axis-1 delegation · `lifecycle-states-canonical §3.2` · frontmatter-schema Category-2).
- *Downstream of the Wave-0a protocol docs (consumes the Artifact #9 delegation seam they document).*

**Wave 1 — G10 write-permission matrix:**
- Author `core/schemas/entity-field-lifecycle-matrix.md` (18 entities; write/append/read-only × conflict-winner × audit-trail). *Keys on the Wave-0a transitions; cannot start until both protocol docs are stable.*

**Wave 2 — Skill integration (the value leg) + ticket-level alignment (parallel — disjoint files):**
- EXTEND ppm-agent / tracker-manager / artifact-generator SKILL.md to emit/consume transitions (skill-integration story). *Blocked by Wave 0a (both protocol docs).*
- Align `ticket-information-architecture.md` § Agent Write Permissions to the matrix. *Blocked by Wave 1.*
- *These two touch disjoint file sets → parallel-safe with each other.*

**Satellite waves (NOT on the critical path):**
- Artifact-Register + skill-CMDB — Stage 5 mechanism decision + ADR (single-registry), then schema row + template + tracker-manager SKILL.md edit (SERIALIZE against skill integration on tracker-manager).
- Project-tracking-integrity sweep — dedicated Stage 5 wave to set the dormancy window (10bd) + overdue threshold (3–5bd), then the three SKILL.md edits + tracker-schemas + OPERATIONS edits.

**Critical path:** `{project-scoped protocol ∥ shared+portfolio protocol}` → `skill integration`. The G10-matrix → alignment branch is a shorter parallel branch off Wave 0a.

---

### Stage Applicability Matrix

Default = ALL stages 5–13 apply. Skip Stage 5 only if trivial; skip Stages 7–8 only if no functional impact. Per-deliverable assessment (the operator decision record sets the Stage 5 footprint):

| Deliverable | Type | S5 Solutioning | S6 Eng | S7 DevTest | S8 IntegTest | S9 PlanRev | S10–11 (compressed) | S12 Execute | S13 Close | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| Project-scoped protocol | task | **LIGHT** | ✅ | ✅ (grep-AC) | SKIP (no runtime) | ✅ | ✅ | ✅ | ✅ | Transcription against the FROZEN entity-model §4 — no re-design of state machines. The one canonicalization is the shared 5-column FORMAT. |
| Shared+portfolio protocol | task | **LIGHT** | ✅ | ✅ (grep-AC) | SKIP | ✅ | ✅ | ✅ | ✅ | Same as the project-scoped doc — frozen Axis-1 machines (§4 #10–#17); transcription, format-identical co-lock. |
| Artifact-Register + skill-CMDB | **story** | **FULL** | ✅ | ✅ (schema+regression) | possible | ✅ (Deep) | ✅ | ✅ | ✅ | CMDB mechanism = Stage 5 design decision + ADR under the single-registry constraint. New schema row + template + SKILL.md edit. |
| Write-perms↔matrix alignment | task | **SKIP** | ✅ | ✅ (cell diff) | SKIP | ✅ | ✅ | ✅ | ✅ | Mechanical one-directional table reconciliation. No design content. Narrowest card. |
| Project-tracking-integrity sweep | task | **REQUIRED (full)** | ✅ | ✅ (fixture-AC) | possible | ✅ | ✅ | ✅ | ✅ | Dormancy window + overdue threshold are explicitly unset → Stage 5 sets them (10bd / 3–5bd). The strongest "needs Solutioning" signal in the bundle. |
| G10 write-perm matrix | task | **LIGHT** | ✅ | ✅ (grep-AC) | SKIP | ✅ | ✅ | ✅ | ✅ | Residual = conflict-winner + audit-trail dims over the ticket-matrix pattern; ≥3 worked conflict scenarios is light design judgment. |
| Skill integration | **story** | **FULL** | ✅ | ✅ (grep-AC per skill) | **✅** | ✅ (Deep) | ✅ | ✅ | ✅ | Behavior-changing; 3 SKILL.md EXTEND + cross-entity cascades + Autonomy-Tier guards. Stage 8 integration-test relevant (cascades fire across skills). |
| Artifact-workflow reconciliation (W0b) | reconciliation | (folded) | ✅ | ✅ | possible | ✅ | ✅ | ✅ | ✅ | Promotion-state + three-way artifact_state mapping; downstream of the protocol docs. Authored by the W0b spoke. |

**Two-or-more Solutioning issues → Collective Review is the scope-lock gate** (the Artifact-Register/CMDB, skill-integration, and integrity-sweep deliverables all carry a FULL Stage 5; the cross-issue compositional surface — especially the 3-skill cascade — surfaces design questions the per-issue triggers miss).

---

### Contention Map

Files touched by ≥2 in-scope deliverables, verified against the live tree:

| File | Deliverables | Live status | Resolution |
|---|---|---|---|
| `operations/skills/tracker-manager/SKILL.md` | skill integration, Artifact-Register, integrity-sweep | EXISTS (already carries `lifecycle_state` + `cascade_scope` infra) | **SERIALIZE.** Skill integration adds the lifecycle-write section; the Artifact-Register adds Register-row maintenance; the integrity-sweep adds dormancy/escalation. One pmo-skill-editor pass per edit; do NOT parallelize on this file. |
| `core/governance/OPERATIONS.md` | G10 matrix, Artifact-Register, integrity-sweep | EXISTS | **SERIALIZE / coordinate.** Each edit is its own reviewable diff; append-pattern (distinct sections) so low merge-conflict risk, but order the commits. |
| `core/schemas/tracker-schemas.md` | Artifact-Register, integrity-sweep | EXISTS (no Artifact Register row — verified) | Distinct schema sections → append-pattern, low conflict; serialize. |
| `core/standards/entity-lifecycle-protocol.md` | project-scoped protocol (Wave 0a), shared+portfolio protocol (read for format) | NET-NEW (this release) | The shared+portfolio doc reads the project-scoped doc's 5-column header to keep the format byte-identical; no write contention (separate files). |
| `operations/skills/ppm-agent/SKILL.md` | skill integration only | EXISTS | No contention (single writer). |
| `operations/skills/artifact-generator/SKILL.md` | skill integration only | EXISTS | No contention (single writer). |

**Cross-PR / cross-release (audit-baseline discipline):** Zero open PRs and zero `release/*`/`chore/v*` remote branches at the branch-cut anchor (`origin/main` @ b84ddb6, 2026-06-22) — no concurrent in-flight version claim or file collision detected. This default-to-zero is **not load-bearing on its own**: re-check `gh pr list --state open` + remote `release/*` branches at Stage 9 entry and again at Stage 12 before the version claim is relied upon.

---

### File Change Matrix

Add/edit/delete intent per file, one path per line (downstream-extractable). **W0a = the commit set this plan ships with; W0b/W1/W2/satellite rows are downstream of this Wave-0a commit set.**

```
release/releases/plans/field-lifecycle-and-cmdb-automation_RELEASE_PLAN.md       [plan]   ADD   (W0a — Commit 0, this file)
core/standards/entity-lifecycle-protocol.md                                      [proj]   ADD   (W0a — project-scoped protocol, 10 entities)
core/standards/entity-lifecycle-protocol-shared-portfolio.md                     [shr]    ADD   (W0a — shared+portfolio protocol, 8 entities; co-located in core/standards/ per operator directive)
core/disciplines/project-entity-model.md                                         [proj/shr] READ-ONLY (frozen derivation source §4/§5.1/§6 — cite, do not edit)
core/schemas/entity-field-schemas.md                                             [proj]   READ-ONLY (§5 create-time supply — reference, do not restate)
core/standards/lifecycle-states-canonical.md                                     [proj/shr] READ-ONLY (§2.1 <Entity>-<state> convention + §3.2 Artifact Workflow; §3 registration FLAGGED, not executed — operator-gated governance touch)
core/standards/entity-lifecycle-protocol.md (header co-lock)                      [shr]    READ-ONLY (5-column header read for byte-identity)
core/schemas/entity-field-lifecycle-matrix.md                                    [G10]    ADD   (W1)
release/references/specs/ticket-information-architecture.md                      [align]  EDIT  (W2 — § Agent Write Permissions cells)
operations/skills/ppm-agent/SKILL.md                                             [skill]  EDIT  (W2 — emit Axis-1 transitions; via pmo-skill-editor)
operations/skills/tracker-manager/SKILL.md                                       [skill]  EDIT  (W2 — lifecycle_state write on fired transition, Tier-gated; via pmo-skill-editor)
operations/skills/tracker-manager/SKILL.md                                       [AR]     EDIT  (satellite — maintain Artifact-Register rows; via pmo-skill-editor)  ← SERIALIZE with skill integration
operations/skills/artifact-generator/SKILL.md                                    [skill]  EDIT  (W2 — set entry lifecycle state on create; via pmo-skill-editor)
core/schemas/frontmatter-schema.md                                              [skill/W0b] READ-ONLY/EDIT (Category-2 delegation seam — cite at W0a; the W0b artifact_state mapping reconciles against it)
core/schemas/tracker-schemas.md                                                  [AR]     EDIT  (satellite — ADD Artifact-Register schema row-set)
operations/templates/artifact-register-template.md                               [AR]     ADD   (satellite)
core/governance/OPERATIONS.md                                                    [G10/AR] EDIT  (satellite/W1 — matrix + Artifact-Register cross-references)
CLAUDE.md                                                                        [AR]     EDIT  (satellite — § File Management Protocol references the Artifact Register concept)
core/ADRs/ADR-036-*.md                                                           [AR]     ADD   (satellite — CMDB-mechanism single-registry ADR; Option A)
operations/skills/weekly-status-rollup/SKILL.md                                  [sweep]  EDIT  (satellite — dormancy sweep; via pmo-skill-editor)
operations/skills/project-initiator/SKILL.md                                     [sweep]  EDIT  (satellite — closure-entry dormancy hook; via pmo-skill-editor)
operations/skills/delivery-engine/SKILL.md                                       [sweep]  EDIT  (satellite — DoD gate rejects unbacked Complete; via pmo-skill-editor)
core/schemas/tracker-schemas.md                                                  [sweep]  EDIT  (satellite — Decisions-escalation + milestone-evidence fields)
core/governance/OPERATIONS.md                                                    [sweep]  EDIT  (satellite — overdue-decision escalation protocol)
```

**Note:** the skill-integration / Artifact-Register / integrity-sweep deliverables edit SKILL.md files via the **pmo-skill-editor discipline** (impact + coherence + regression) per skill-deployment.md "Mandatory Tooling for Skill Edits" — direct Write/Edit to migrated SKILL.md is hook-blocked. `.skill` packages rebuild at release-cut, not per-commit.

---

### Risk Register

| # | Risk | Class | Severity | Owner-action / Mitigation |
|---|---|---|---|---|
| R1 | **Shared-SKILL.md write coordination** — skill integration touches all 3 of ppm-agent/tracker-manager/artifact-generator; the Artifact-Register also touches tracker-manager. Parallel edits → coherence drift + merge conflict on the shared `lifecycle_state` write surface. | Contention | **HIGH** | Serialize all tracker-manager edits (skill integration then Artifact-Register). One pmo-skill-editor coherence pass spanning the 3-skill owning-agent contract for skill integration. Do NOT split skill integration across parallel spokes. |
| R2 | **Protocol-before-skills ordering** — skill integration implements transitions; if it runs before the two protocol docs are stable, it codes against an unwritten protocol. | Dependency | **HIGH** | Hard-gate: skill-integration Engineering does not start until BOTH protocol docs (Wave 0a) are merged/stable. Enforced by wave ordering. |
| R3 | **Format divergence between the two protocol docs** — co-dependent docs authored separately could produce two incompatible 5-column formats, breaking skill integration's uniform consumption. | Dependency | **MEDIUM** | Author Wave 0a as one design unit; the 5-column header is byte-pattern-identical across both docs (verified by grep at Engineering). |
| R4 | **G10 matrix keys on transitions that may still move** — write-perm conflict-winner rules reference transition semantics from the two protocol docs. | Dependency | **MEDIUM** | Sequence the matrix strictly after Wave 0a; if a Wave-0a transition changes during authoring, re-derive the affected matrix cell. |
| R5 | **Alignment stale-source drift** — the cell alignment is computed against the LIVE matrix; if the source moves mid-release the target moves. | Scope | **LOW** | The alignment AC mandates a diff showing zero matrix edits; verify the cells against the live source at Engineering Commit 0, not against the issue body's snapshot. |
| R6 | **Integrity-sweep unset thresholds** — without Stage 5 the ACs are unverifiable (no fixture target). | Scope | **MEDIUM** | KEPT per operator → run the mandatory Stage 5 to set + record both thresholds (dormancy 10bd, overdue 3–5bd) before Engineering. |
| R7 | **Rollback complexity — governance + protocol surface** | Rollback | **MEDIUM** | All net-new files (the two protocol docs, the G10 matrix, the artifact-register template, the ADR) are ADD-only → revert = delete; CHEAP. The SKILL.md/OPERATIONS/CLAUDE/tracker-schemas EDITs are the rollback-sensitive surface; `git revert` restores prior SKILL.md contracts; the §3 lifecycle-states-canonical registration is FLAGGED-not-executed so it carries no rollback debt. **Keep skill integration (behavior-changing) on its own PR** for independent rollback. |
| R8 | **Concurrent version claim** between the D-Version recommendation and the Stage 12 atomic claim. | Dependency | **LOW** | Branch-cut re-verify shows zero in-flight claims @ b84ddb6; Commit-0 re-verify + Stage 12 atomic compare-and-swap are the load-bearing rungs. |

**Rollback strategy (release-level):** Single-branch topology; this plan is Engineering Commit 0. Rollback = `git revert` of the merge (or pre-merge, abandon the branch). ADD-only files carry zero rollback debt. The only EXPENSIVE-to-undo element would be the `lifecycle-states-canonical.md §3` registration — and every issue in scope explicitly **flags-not-executes** it (operator-gated Autonomy-Tier-0 governance touch), so the release ships no irreversible governance mutation.

---

### Operator Decisions (rendered at the Stage 4 planning gate)

The release plan above is **APPROVED** with the following operator rulings at the Phase B D-gates (reproduced verbatim from the decision record on the release-planning sub-task). Hub adversarial verification is recorded in the main-thread Decision Briefing (git-describe anchor; Artifact-Register redundancy refutation; contention map; in-flight baseline @ b84ddb6).

| D-Gate | Decision | Note |
|---|---|---|
| **D-752-Scope (integrity sweep)** | **KEEP in-release** | Override of the defer recommendation. The integrity sweep gets a dedicated **Stage 5 Solutioning** wave to set the dormancy window (**10 business days**) + overdue-decision threshold (**3–5 business days**), currently unset in the issue body. |
| **D-Version** | **v2.20 — minor** | anchor = v2.19; the v3.20 tag is reachable-but-abandoned (correctly excluded by `git describe` reachability, not semver-max). Bump-class corrected major→minor. Provisional until the Stage 12 atomic claim. |
| **D-202-Scope (Artifact Register / CMDB)** | **Artifact Register + skill-CMDB** (full original scope restored) | **Hard constraint: a SINGLE skill registry/catalog — no second registry.** `registry.md` is role-Specialist routing-only per ADR-035, so the CMDB **mechanism** — evolve the one registry vs. realize the CMDB as a reference schema over existing sources (`deploy.sh` arrays + SKILL.md `version:` + the 3 contract indexes) + the new lifecycle-state/relationship axes — is a Stage 5 design decision + **ADR-036** (**Option A**), reconciling ADR-035 / ADR-019 / ADR-007. No source duplication. |
| **D-ReleaseClass** | **cross-cutting** | Corrected from the spoke's `novel` — cross-cutting trigger fires (≥3 in-bundle compositional edges in the spine). → Tight engagement density · Deep Stage 9 · ALL Stage 5 bias. |
| **Artifact reconciliation (folded in)** | **In-scope (Wave 0b)** | The artifact-workflow-protocol promotion-state reconciliation and the lifecycle-states-canonical three-way `artifact_state` mapping are folded into this release as Wave 0b deliverables: a co-located Artifact-Workflow protocol doc carrying `promotion_state`, plus a single `artifact_state` mapping reconciling the entity Axis-1 delegation · `lifecycle-states-canonical §3.2` · frontmatter-schema Category-2 Domain A/B/C expressions. Downstream of the Wave-0a protocol docs. |

**Release scope:** the seven milestone issues + the two folded-in reconciliation deliverables = nine deliverables.

**Stage 5 (Solutioning) footprint:** FULL for the Artifact-Register/CMDB (CMDB architecture + ADR-036), skill integration (3-skill cascade), and the integrity sweep (thresholds); LIGHT for the two protocol docs + the G10 matrix (transcription against the frozen entity model); SKIP for the alignment task (mechanical reconcile). Two-or-more Solutioning issues → **Collective Review is the scope-lock gate**.

---

### Recommendations

1. **Approve the wave sequence** with `{project-scoped protocol ∥ shared+portfolio protocol}` as Wave 0a co-developed to a shared, byte-identical transition-table format. Critical path = `{both protocol docs} → skill integration`.
2. **Integrity sweep → KEPT** (operator). Run its dedicated Stage 5 to set + record the dormancy window (10bd) + overdue threshold (3–5bd) before Engineering.
3. **Artifact-Register / CMDB → full scope, single registry** (operator). The CMDB mechanism is a Stage 5 design decision + ADR-036 (Option A); no second registry.
4. **Release Class → cross-cutting; Version → v2.20 minor** (operator). Anchor v2.19; v3.20 excluded as abandoned lineage; zero in-flight contention at branch-cut.
5. **Serialize all `operations/skills/tracker-manager/SKILL.md` edits** (skill integration → Artifact-Register) and run the skill-integration 3-skill EXTEND as ONE pmo-skill-editor coherence pass (R1). Keep skill integration on its own PR for independent rollback (R7).
6. **Re-check the in-flight population** (`gh pr list --state open` + remote `release/*` branches) at Stage 9 entry and again at Stage 12 before the atomic version claim — the zero-contention finding is baseline-pinned to b84ddb6 (2026-06-22) and not load-bearing on its own.
7. **Deferred governance touch (noted, not executed):** the `lifecycle-states-canonical.md §3` registration of the entity Axis-1 state-machine family is the downstream operator-gated G8/G10 governance change. The two protocol docs FLAG it; they do NOT write to `lifecycle-states-canonical.md`. Track it as a separate Autonomy-Tier-0 governance change for a future cycle.

---

### Issue References

Bare issue references for traceability (de-referenced from the prose above per the reference-durability discipline). Each line is the issue and a one-line summary of its role in this release.

- #154 — G10 entity-field-lifecycle write-permission matrix (18 entities × write/append/read-only × conflict-winner × audit-trail). Wave 1.
- #156 — project-scoped entity-lifecycle transition protocol (10 entities → `core/standards/entity-lifecycle-protocol.md`). Wave 0a.
- #202 — per-project Artifact Register + skill-CMDB; full scope, single-registry, Stage 5 mechanism decision + ADR-036 (Option A). Satellite.
- #208 — write-permission↔matrix alignment (`ticket-information-architecture.md` § Agent Write Permissions). Wave 2.
- #752 — project-tracking-integrity sweep (dormancy / overdue-decision / gate-evidence). KEPT; Stage 5 sets dormancy 10bd + overdue 3–5bd. Satellite.
- #1155 — shared+portfolio entity-lifecycle transition protocol (8 entities → `core/standards/entity-lifecycle-protocol-shared-portfolio.md`). Wave 0a; format-identical co-lock with #156.
- #1156 — skill integration (EXTEND ppm-agent / tracker-manager / artifact-generator to emit/consume transitions). Wave 2; behavior-changing; own PR.
- #1865 — artifact-workflow-protocol promotion-state reconciliation (co-located protocol doc carrying `promotion_state`). Wave 0b.
- #1866 — lifecycle-states-canonical three-way `artifact_state` mapping (entity Axis-1 delegation · §3.2 · frontmatter-schema Category-2). Wave 0b.
- #1857 — release-planning sub-task (the Stage 4 plan + operator decision record this file reproduces).
- #1858 — Stage 5 Solutioning spec for #156 (the LOCKED design this release authors against).
- #1859 — Stage 5 Solutioning spec for #1155 (the LOCKED design this release authors against).

---
*Stage 4 Release Planning — baseline pinned at `origin/main` b84ddb6 (2026-06-22, Monday — validated). Evidence labels applied per CLAUDE.md. Commit-0 version re-verify: v2.20 free (no tag), `git describe --tags --abbrev=0 origin/main` = v2.19, zero in-flight `release/*`/`chore/v*` branches and zero open PRs at branch-cut.*

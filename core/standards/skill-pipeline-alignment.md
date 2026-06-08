<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Skill ↔ Pipeline Alignment Standard

**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Governing principle:** [ADR-019 — Specialists compose, not absorb shared function-skills](../ADRs/ADR-019-specialists-compose-not-absorb.md). This standard operationalizes ADR-019 at the skill↔pipeline seam: where ADR-019 fixes the *decomposition axis* (role-named Specialists compose function-named shared skills), this standard fixes how any skill — function-skill or Specialist — *relates to the 13-stage pipeline* it runs inside.
**Primary consumers:** skill authors (`pmo-skill-refiner` Interview/Create/Refine, `pmo-skill-editor` Targeted-edit); skill reviewers (`pmo-qa-auditor` single-output + cross-output, `build-reviewer`); the Stage 5 Solutioning persona when a release touches skill-authoring surface.
**Layer position:** The pipeline is the [Process](../specs/terminology-glossary.md#term-process) layer; this standard is the **Tool-layer alignment contract** per [execution-framework.md § Consumer Contract](../disciplines/execution-framework.md#consumer-contract) — it states how a Tool-layer skill aligns to the Process-layer stages without redefining either.

## §1 Purpose

Skills and the 13-stage pipeline are two different organizing surfaces over the same work. The pipeline ([`stage-NN-*.md`](../../release/references/pipeline/) shards) sequences a release from intake through close; skills (the 22 deployed SKILL.md files in [`deploy.sh`](../deploy/deploy.sh)'s `OPERATIONS_SKILLS` + `RELEASE_SKILLS` + `CORE_SKILLS` rosters) package capability that runs *inside* one or more of those stages. When the two surfaces drift apart, three failures follow:

1. **Orphaned capability** — a skill runs work the pipeline never names, so the work is invisible to stage-gates and audit.
2. **Parallel vocabulary** — a skill coins its own checklist / gate / mode names that shadow the pipeline's canonical IDs, and the two sets drift until a reader cannot tell which governs.
3. **Duplicated stage work** — two skills both implement the same stage-internal step, forking the source of that step (the skill-level instance of the ADR-019 absorb-don't-compose anti-pattern).

This standard gives skill authors and reviewers a **queryable alignment contract**: a single classification (§2) plus three decision-tests (§4–§6) that resolve, at authoring time, where a skill sits relative to the pipeline and how it must name its work. It is the durable replacement for tacit "everyone knows comms-writer runs across stages" knowledge — the same move [upstream-reference-catalog.md](upstream-reference-catalog.md) made for upstream-compatibility knowledge.

The standard is **documentation-and-review enforcement** at current platform scale — the operative gate is the authoring-time decision-tests below, applied by the authoring skill and checked by the reviewing skill. No deploy-time scan ships with this standard; a future check is reserved in §7.

## §2 The alignment principle — three skill↔stage relations

Every deployed skill stands in exactly one of three relations to the pipeline. The relation is a property of the skill's *capability shape*, not of any single invocation.

| Relation | Definition | Pipeline-state contract | Canonical examples (live roster) |
|---|---|---|---|
| **R1 — 1:1 stage-mapped** | The skill's whole capability maps to exactly one pipeline stage; invoking the skill IS doing that stage's work. | The skill MAY read its stage's gate IDs and §-Inputs as its own contract; its modes (if any) are facets of one stage. | `release-planner` ↔ Stage 4 Planning; `intake-desk` ↔ Stage 1 Intake; `release-executor` ↔ Stages 12 Execute + 13 Close. |
| **R2 — N:1 stage-internal** | Several skills each own a distinct *step within one stage*; no one skill is the stage, and the stage is not reducible to any one skill. | Each skill names the stage it serves AND the specific step it owns; it MUST NOT claim the whole stage's gate set. Steps compose, they do not absorb each other (ADR-019 at step granularity). | Within Stage 8 QA: `pmo-qa-auditor` (output-vs-standard review) + `build-reviewer` (production-readiness review of a doc pack) — two distinct steps of one QA stage. |
| **R3 — cross-stage composing** | The skill's capability is invoked from *many* stages as a shared service; it has no single home stage. | The skill declares it is stage-agnostic and composes via skill-chaining (cascade-scope / allowlist per [OPERATIONS.md § Skill Chaining Protocol](../governance/OPERATIONS.md)); it reads the *calling* stage's context rather than hard-coding one stage. | `comms-writer`, `tracker-manager`, `artifact-generator` — invoked across Triage, Solutioning, Close, and operational delivery alike. |

**The alignment rule (one sentence):** A skill MUST declare its relation (R1 / R2 / R3) and MUST align its internal vocabulary to the pipeline at the granularity its relation permits — a 1:1 skill inherits its stage's IDs, an N:1 skill names its step within a stage, a cross-stage skill stays stage-agnostic and composes — and a skill MUST NOT coin a parallel vocabulary that shadows a canonical pipeline ID (§5) nor re-implement a step another skill already owns (§6).

**Why relation, not invocation:** the same trigger phrase can fire different modes (release-planner's "plan the release"), but the skill's *relation to the pipeline* is stable across invocations. Classifying by relation makes the contract durable; classifying by invocation would re-decide it every call.

## §3 Decision-test index

| Test | Question it answers | Fires when |
|---|---|---|
| **DT-1** | Should this skill **ask for its mode**, or **read pipeline state** to resolve it? | A multi-mode skill must choose between an AskUserQuestion gate and reading the calling stage / artifacts to auto-resolve. Composes with the OPERATIONS Mode Selection tiers. |
| **DT-2** | Is this skill's checklist / gate / step vocabulary a **parallel-vocabulary leak**, or a legitimate **skill-local refinement** of a canonical pipeline ID? | A skill defines named gates / checklists (DoR, DoD, readiness criteria) that overlap the pipeline's gate IDs in [gate-criteria-spec.md](../schemas/gate-criteria-spec.md). |
| **DT-3** | Is a stage-internal step owned by **one skill (compose)** or **re-implemented across several (absorb)**? | Two or more skills appear to do the same stage step; the author must decide EXTEND-existing vs build-new. The skill-level form of the ADR-019 skill-boundary test. |

## §4 DT-1 — ask-for-mode vs read-pipeline-state

A multi-mode skill resolves which mode to run one of two ways: **ask** the operator (an AskUserQuestion gate) or **read** the pipeline state / input artifacts and auto-resolve. DT-1 picks between them, and it **composes with — does not replace — the three-tier Mode Selection classification** in [OPERATIONS.md § Mode Selection Protocol](../governance/OPERATIONS.md) (always-ask / ask-when-ambiguous / never-ask). The Mode Selection tiers answer *"does this skill carry a `## Mode Selection` section and when does AUQ fire"*; DT-1 answers the upstream design question *"is mode-resolution a human decision or a state-read"* and feeds the tier choice.

| Resolve by | Choose when… | Maps to OPERATIONS tier |
|---|---|---|
| **Ask (AUQ)** | The same trigger maps to modes whose outputs have **destructive or production-critical asymmetry** OR are **scope-different and unrecoverable** from a wrong-mode run. The operator's intent is genuinely underdetermined by available state. | **always-ask** (or ask-when-ambiguous if only some triggers are ambiguous). |
| **Read pipeline state** | The calling stage, the chained-invocation manifest (`chained=true` + `mode=…`), or the input artifact unambiguously determines the mode. Reading is reliable; asking would be friction-theater. | **never-ask**, or the chain-skip Step-1 branch of any tier. |

**DT-1 decision procedure:** (1) If a chained-invocation manifest carries `mode=…`, read it — never ask (the Mode Selection Protocol chain-skip Step 1). (2) Else, if wrong-mode execution is unrecoverable or production-critical, ask. (3) Else, if the calling stage or input artifact determines the mode, read it. (4) Else (ambiguous, recoverable), ask-when-ambiguous.

**Worked example — R1 skill, ask is correct (`release-planner`):** `release-planner` is 1:1-mapped to Stage 4 Planning. The single trigger "plan the release" maps to three scope-different modes: Backlog analysis (read-only priority recommendation), Release planning (an authoritative plan file written to `release/releases/plans/`), and Dry run (a near-destructive diff preview that anchors operator decisions). A wrong-mode run produces the wrong artifact and erodes trust in the plan file — `[SOURCE: release-planner SKILL.md "three modes that produce scope-different outputs from the same trigger … Mode selection is mandatory on every direct invocation"]`. DT-1 step (2) fires: scope-different + trust-eroding ⇒ **ask**. This is why the skill is correctly classified **always-ask** in the OPERATIONS census — DT-1 and the tier agree. A junior author would auto-route "plan the release" to Release planning and silently overwrite a plan file; a principal author asks because the asymmetry is load-bearing.

**Worked example — read is correct (`file-router`):** `file-router` is never-ask: the mode is fully determined by the input artifact's content/filename classification, so reading the artifact resolves the route. Asking would add a gate with no decision behind it. DT-1 step (3) fires: input artifact determines the mode ⇒ **read**.

## §5 DT-2 — parallel-vocabulary-leak vs gate-criteria-spec gate IDs

The pipeline owns a **canonical gate vocabulary**: stable IDs in [gate-criteria-spec.md](../schemas/gate-criteria-spec.md), in two formats — numeric-gate (`G1-01` … `G3-07`) for the Stage 1–3 named gates, and stage-abbrev (`G-PR`, `G-EX`, `G-CL`, `G-BR`) for the Stage 9 / 12 / 13 named gates plus the cross-stage Bundle-Refresh gate `[SOURCE: gate-criteria-spec.md § Schema ID row]`. When a skill defines its own named gates or checklists, DT-2 decides whether that is a **parallel-vocabulary leak** (two ID sets that will drift) or a **legitimate skill-local refinement** that maps back to a canonical ID.

| Disposition | Signature | Required remediation |
|---|---|---|
| **LEAK** | The skill coins a gate/checklist name that **covers the same predicate** as an existing canonical gate ID, with no declared mapping. Two sources of the same truth ⇒ drift. | Either (a) reference the canonical `G…` ID directly, or (b) declare the skill-local name as a **named refinement** of the canonical ID (state the mapping inline) and register the relationship so drift is detectable. Per [duplicate-source-discipline.md § 1](duplicate-source-discipline.md) register-or-remove. |
| **REFINEMENT (allowed)** | The skill's named checklist is a **stage-internal elaboration** that the canonical gate *delegates to by name*, OR covers a predicate no canonical gate covers. The canonical ID stays authoritative; the skill names the delegation. | Keep, but state the mapping ("this skill's DoR checklist elaborates Stage-N readiness gate `G…`") so a reader can trace skill-local → canonical. |

**Worked example — the named DT-2 finding (`delivery-engine` DoR/DoD vs gate IDs):** `delivery-engine` Mode C (Refinement Manager — DoR Gate) and Mode F (DoD & Release-Readiness Gate) read `references/gate-checklists.md` for their DoR/DoD criteria `[SOURCE: delivery-engine SKILL.md Mode C step "Read references/gate-checklists.md for the DoR criteria"]`. The pipeline independently owns triage-readiness gates `G1-01…G1-09` (the "is this work item ready" predicate) in gate-criteria-spec.md. These two surfaces both express a readiness predicate over a work item — the classic LEAK signature. DT-2 disposition: this is a **REFINEMENT that must declare its mapping**, not a free-standing parallel set. `delivery-engine`'s DoR is an Agile-framing elaboration of the same readiness concept the canonical `G1-*` gates check; the remediation is to state the skill-local-DoR → canonical-`G1-*` correspondence inline so the two cannot silently drift (rather than to delete one — both framings have audiences per the skill's Agile/Waterfall dual-framing contract). A principal author writes the mapping sentence; a junior author ships two unlinked checklists and the platform later cannot tell whether a DoR pass implies a `G1` pass.

**Boundary note:** DT-2 fires on *gate/checklist/readiness* vocabularies — surfaces that shadow gate IDs. It does NOT fire on a skill's ordinary mode names (Elicit, Interview, Backlog scan): mode names are skill-local by design and shadow nothing in gate-criteria-spec.md.

## §6 DT-3 — shared-stage-work extraction (compose vs absorb)

DT-3 is the **skill-level instance of the ADR-019 skill-boundary test**. When two or more skills appear to do the same *stage-internal step*, DT-3 decides whether the step belongs to one skill (the others compose it via skill-chaining) or is legitimately re-implemented. ADR-019 already supplies the test; DT-3 applies it at step granularity and adds the pipeline-stage frame.

A stage step belongs in **one** skill (others compose, do not re-implement) unless the ADR-019 three-conjunct skill-boundary test holds for the second skill — and **all three conjuncts must hold together**:

1. **distinct trigger surface** — the second skill answers a materially different invocation-trigger set, AND
2. **distinct write-scope** — it writes a different artifact / output surface, AND
3. **distinct primary role** — it occupies a different primary role in the work, not a variation of the same one.

If any conjunct fails, the step belongs in the existing owner; the second skill composes it (invokes it via cascade-scope / allowlist) rather than copying its logic — the compose-don't-absorb discipline of ADR-019, verbatim, one layer down.

**Worked example — compose is correct (`release-planner` → `release-executor`, the read/write split):** Both skills touch "release state," which could look like duplicated stage work. Apply the three conjuncts: `release-planner` is **read-only** against governance files and produces a *plan* (Stage 4); `release-executor` *applies* the plan and is production-critical (Stages 12/13) `[SOURCE: release-planner SKILL.md "read-only against governance files by contract"; release-executor SKILL.md "production-critical … Execute applies approved changes"]`. Distinct trigger surface (plan vs deploy) ✓, distinct write-scope (no governance writes vs governance writes) ✓, distinct primary role (planner vs executor) ✓ — all three hold, so these are correctly **two skills**, not a duplication. The plan→execute separation is exactly what the conjuncts protect: collapsing them would let the planner mutate governance, destroying the read-only contract that makes the separation trustworthy. DT-3 verdict: **keep separate (compose)** — `release-executor` consumes `release-planner`'s plan artifact; it does not re-implement planning.

**Worked example — extract is the remedy (a hypothetical absorb):** Were a new "Release Manager" Specialist authored that re-implemented backlog analysis inside its own SKILL.md rather than invoking `release-planner`, the three conjuncts fail on backlog-analysis (same trigger, same read-scope, same primary role as `release-planner` Mode A) ⇒ DT-3 verdict **absorb-detected; extract**: the Specialist must compose `release-planner` via skill-chaining, not fork its logic. This is the precise failure ADR-019 exists to prevent, surfaced at the skill-pipeline seam.

## §7 Enforcement and future check

**Operative gate today (authoring + review):**

- **Authoring time:** `pmo-skill-refiner` (Interview / Create New / Refine Existing) and `pmo-skill-editor` (Targeted edit) apply §2 relation-classification and DT-1/2/3 when creating or changing a SKILL.md. The skill's relation (R1/R2/R3) is stated; any DT-2 refinement states its canonical-ID mapping; any DT-3 shared step composes rather than absorbs.
- **Review time:** `pmo-qa-auditor` (single-output + cross-output coherence) and `build-reviewer` check conformance — a skill that coins a parallel gate vocabulary with no mapping is a DT-2 LEAK finding; a skill that re-implements another's step is a DT-3 absorb finding. This composes with the existing review discipline in [review-discipline-principles.md](../disciplines/review-discipline-principles.md).
- **Pre-creation governance check:** the [CLAUDE.md Pre-creation governance check](<OPERATOR_INSTANCE_CLAUDE_MD>) catches a would-be new skill that duplicates an existing skill's stage step before it enters the corpus.

**Reserved future check (deferred):** A `deploy.sh --check` check that (a) asserts every skill in the rosters declares an R1/R2/R3 relation and (b) flags skill-local gate names that lexically overlap a canonical `G…` ID without a declared mapping is **reserved, not shipped** — manual review suffices at current volume (22 skills). When the roster exceeds a threshold where manual review starts missing leaks (the §6-trigger pattern in [duplicate-source-discipline.md](duplicate-source-discipline.md)), file a follow-up issue to ship it. Creating an empty check now would be enforcement-theater (a gate with no enforcement behind it).

## §8 Cross-references

| Surface | Reference | Role |
|---|---|---|
| Governing ADR | [ADR-019 — Specialists compose, not absorb](../ADRs/ADR-019-specialists-compose-not-absorb.md) | The decomposition-axis principle this standard operationalizes at the skill↔pipeline seam; supplies the three-conjunct skill-boundary test DT-3 reuses. |
| 4-layer model | [execution-framework.md § Consumer Contract](../disciplines/execution-framework.md#consumer-contract) | Places this standard as the Tool-layer alignment contract; the pipeline is the Process layer, skills are Tool layer. |
| Mode Selection tiers | [OPERATIONS.md § Mode Selection Protocol](../governance/OPERATIONS.md) | The always-ask / ask-when-ambiguous / never-ask tier classification that DT-1 composes with (and feeds). |
| Gate vocabulary | [gate-criteria-spec.md](../schemas/gate-criteria-spec.md) | The canonical `G…` gate IDs that DT-2 protects against parallel-vocabulary drift. |
| Pipeline stages | [pipeline/](../../release/references/pipeline/) | The 13-stage Process surface skills map to (R1/R2/R3). |
| Skill-chaining substrate | [OPERATIONS.md § Skill Chaining Protocol](../governance/OPERATIONS.md) | Cascade rules C1–C7 + the 4-skill allowlist; the mechanism by which R3 / composing skills invoke rather than absorb. |
| Register-or-remove | [duplicate-source-discipline.md](duplicate-source-discipline.md) | The §1 register-or-remove rule DT-2 LEAK remediation and the §7 future-check trigger rest on. |
| Review discipline | [review-discipline-principles.md](../disciplines/review-discipline-principles.md) | The review-class discipline `pmo-qa-auditor` / `build-reviewer` apply when checking DT-conformance. |

## §9 References

The issue and ADR numbers below are provenance for this record; the prose above leads with self-describing roles so the meaning survives renumbering. This block is the designated reference home.

- The alignment-standard work item — the protocol issue this standard satisfies, and the reconciliation venue ADR-019 forward-references for the four named role/function overlap pairs: #2.
- The governing decomposition-axis decision record: ADR-019 (`core/ADRs/ADR-019-specialists-compose-not-absorb.md`), authored under the adopting intake #406.
- The role-skill suite epic this standard's reviewers gate downstream: #284.
- The release that ships this standard: skill-suite-architecture-spine (v1.08), Stage 4 plan sub-task #547.

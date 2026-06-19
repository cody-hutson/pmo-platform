# PMO Feeding-Document Format — v0.2

## Format Lock — v0.2 (post-Phase-1)

**This format is locked.** As of the **Phase 1 calibration** (the TPM + Program Coordinator pilot builds — `pmo-technical-program-manager` and `pmo-program-coordinator`), the v0.2 feeding-document format is **format locked**: it was proven on the two autonomy/complexity extremes before the role-skill factory scales up, and is now frozen.

**Build-time field set (the locked set).** The locked format implements exactly the **12 build-time field changes** — **{CS-01, CS-02, CS-03, CS-04, CS-05, CS-06, CS-07, CS-08, CS-09, CS-10, CS-11, CS-13}**. This is the precise set, **not** a contiguous "CS-01…CS-13" range: **CS-12 and CS-14 do not exist** in the canonical correction table, and stating the range contiguously would freeze that imprecision into the locked format.

**CS-15 (cross-boundary influence) — resolved by Phase 1 calibration.** CS-15 was deferred (canonical epic KDD-9) to Phase-1 pilot calibration; it is **not** a build-time field and is **not** promoted into the 12-field set above. The two pilots calibrated it as a **§8 (Cross-Skill Integration) refinement**, and both independently demonstrated the same finding: a thin Specialist that composes ≥2 function-skills **requires an explicit cross-boundary-influence rule** — it must declare how one composed skill's output gates or feeds another composed skill's invocation, because that influence edge is the Specialist's defining synthesis (without it the Specialist degrades into two parallel passes the operator could have run separately).

- **TPM calibration case:** a `pmo-technical-analyst` risk finding gates a `delivery-engine` DoR/DoD decision — the edge must be named (finding → gate it gates → gating relationship), not absorbed into two disconnected passes.
- **Program Coordinator calibration case:** `tracker-manager` state feeds the `daily-status` carry-forward — a disagreement between the two is a data-integrity divergence the role must surface for operator adjudication, not silently reconcile.

**CS-15 resolution (recorded in the locked format):** §8 of a feeding document for a composing Specialist **must** declare the cross-boundary influence edges between its composed skills (which composed skill's output gates/feeds which other composed skill's invocation), and the produced SKILL.md must surface those edges in its `## Composition` section and the relevant modes. This is the calibrated rule the two pilots ratified; it folds into the locked format as the §8 cross-skill-integration obligation for composing Specialists. CS-15 stays excluded from the build-time CS field set.

**Change discipline — post-Phase-1 changes require a governance update.** Now that the format is locked, **any change to this v0.2 feeding-document format** (a new or altered section, a new CS field, a change to the build-time set, a change to the persona-baseline composition, or to the §8 cross-boundary-influence rule) is a governance-class change: it requires a **GitHub Issue + implementation plan + operator approval** per the CLAUDE.md **"No ungoverned changes"** guardrail before it is made. The lock is enforced by **this repo note plus the No-ungoverned-changes governance rule** — the durable, version-controlled surfaces a future role-skill build reads. (The Phase-1 calibration *evidence* — what the 2 pilots taught about the format — is additionally captured operator-local in the Skills-Map CARRY-FORWARD per the Phase-1 acceptance criteria; that operator-local surface is **not** a repo-verifiable gate and is not claimed as one here — the repo note + governance rule are the enforceable lock.)

---

## Usage

A **feeding document** is a filled, role-specific input that drives `pmo-skill-refiner`'s **`## Workflow — Consume Feeding Document`** path (the pre-Interview input branch of Mode 2 / Create New). One filled feeding document per role-Specialist skill: it carries everything the interactive Interview Q1–Q9 would have captured, so the refiner can generate the SKILL.md by *parsing* the document rather than *interviewing* the operator.

This reference documents the **format** — the 14 sections and 3 appendices, each section's purpose, field semantics, quality criteria, and the v0.2 correction (CS) that applies to it. A *filled* feeding-document instance (e.g., the TPM or Program Coordinator pilot) lives operator-local in the Skills-Map staging area (Layer 2, git-ignored); this file is the format spec those instances conform to.

**Section count is the contract.** The format has exactly **14 numbered sections** (§1–§14) plus **3 appendices** (Appendix A–C). The appendices are documented here but are not part of the 14-count. The role-skill factory (`## Workflow — Consume Feeding Document`) validates that all 14 sections are present and non-empty before generating — a missing or empty section HALTS the parse.

**Build-time CS field set.** The consumption path implements the **12 build-time field changes {CS-01..CS-11, CS-13}**. **CS-15 (cross-boundary influence) is deferred to Phase-1 pilot calibration** — it is not a build-time generator obligation; it is captured during pilot calibration and folded in at format-lock. (The originating ticket prose labels the set "CS-01…CS-13 / 13 changes"; that is read as the **13 distinct CS IDs in the canonical epic table** — the 12 build-time IDs plus CS-15-as-deferred — NOT a contiguous CS-01-through-CS-13 range. CS-12 and CS-14 do not exist in the table.)

**Extraction substrate.** Several sections (notably §10 Guardrails, §12 Reference Files) resolve against the 5 shared role-skill reference files under `operations/skills/_shared/` — `behavioral-markers.md`, `anti-pattern-catalog.md`, `five-model-variations.md`, `deployment-strategies.md`, `lifecycle-gates.md`. A feeding document declares *which* shared content its role draws on and at what extraction depth; the consumption path authors the role's own references at that depth against the shared substrate.

---

## §1 Skill Identity

**Purpose.** Establishes the skill's `name`, the `description` seed, and the trigger phrasings — the frontmatter substrate the consumption path injects into the produced SKILL.md.

**Field semantics.**
- `name` — the deployed skill name (kebab-case, e.g., `pmo-technical-program-manager`). Becomes the SKILL.md `name:` frontmatter field verbatim.
- `description` seed — a one-paragraph capability statement the description-trigger optimization loop (`run_loop.py`) refines; it is the *seed*, not the final description.
- trigger phrasings — 3–5 real operator phrasings that should route to this skill, each with T1/T2 evidence (transcript line, ticket, observed invocation miss). Synthetic phrasings are rejected, same as Interview Q2.

**Quality criteria.** `name` is unique against the deployed roster (no collision with an existing `{operations,release,core}/skills/*` directory). The description seed names the role's distinctive capability (not a generic "helps with X"). Every trigger phrasing carries an evidence source.

**Applicable CS.** — (stable from v0.1; no CS change).

## §2 Scope & Boundaries

**Purpose.** Declares what the role **does** and what it explicitly **does not** do — the in-scope / out-of-scope boundary that prevents over-triggering and absorption of adjacent skills' scope.

**Field semantics.**
- in-scope — the capabilities this skill owns.
- out-of-scope — the adjacent capabilities that route elsewhere, each naming the destination skill (the basis for the produced SKILL.md's "When to use vs. skip" routing).
- boundary statements — the system-vs-solution / role-vs-role cuts that distinguish this skill from its neighbors.

**Quality criteria.** Every out-of-scope item names a concrete destination. The boundary is decision-grade — a reader can classify a borderline request from it. No overlap with a composed skill's owned scope (composition is not absorption — see ADR-019).

**Applicable CS.** — (stable from v0.1; no CS change).

## §3 Role Statement

**Purpose.** The role's identity — the **first element of the §3→§4→§5 continuous persona baseline** the consumption path composes as one uninterrupted opening block.

**Field semantics.** The role statement carries **5 elements**: (1) identity (who the role is), (2) primary responsibility, (3) the judgment the role exercises, (4) the altitude/scope it operates at, and (5) **Distinctive value** — what this role uniquely brings that no adjacent role does. The 5th element is the **CS-01** addition.

**Quality criteria.** All 5 elements present. The Distinctive-value element is specific to this role (not a generic "brings expertise"). The statement reads as continuous prose that flows into §4 (it is the opening of a single composed block, not a standalone section).

**Applicable CS.** **CS-01** (compose the 5th element — Distinctive value) · **CS-13** (compose §3→§4→§5 as one continuous opening; see Appendix A).

## §4 Operating Principles

**Purpose.** The role's mandatory behavioral rules — the **second element of the §3→§4→§5 continuous persona baseline**.

**Field semantics.** **4 mandatory principles**, one of which is **Anticipation** (the role anticipates the next need rather than only answering the current ask). Plus a **5-step selection heuristic** the role applies when choosing among actions. The whole §4 block is held to a **300-word budget** (CS-02 enforces the budget so the persona opening stays scannable).

**Quality criteria.** Exactly 4 mandatory principles, Anticipation among them. The 5-step heuristic is concrete (each step is an observable decision). The block is within 300 words. Flows continuously from §3 and into §5.

**Applicable CS.** **CS-02** (enforce 4 mandatory principles incl. Anticipation; apply the 5-step selection heuristic; 300-word budget).

## §5 Input Handling

**Purpose.** How the role reads context — the **third element of the §3→§4→§5 continuous persona baseline**, with §7's audience-framing rule threaded as the output-discipline close.

**Field semantics.** Context-sensitivity rules (what the role attends to in its inputs) plus **org-tier coverage**: the role must cover **≥2 organizational tiers** — its home tier plus at least 1 adjacent tier (e.g., a TPM covers program + project; a Program Coordinator covers project + portfolio-adjacent). The ≥2-tier coverage is the **CS-03** requirement.

**Quality criteria.** ≥2 org tiers covered (home + ≥1 adjacent), each named explicitly. Context-sensitivity rules are observable from the role's actual inputs. Closes the persona-baseline block coherently (it is the last of the three composed sections).

**Applicable CS.** **CS-03** (validate ≥2 org-tier coverage — home + ≥1 adjacent).

## §6 Modes

**Purpose.** The role's operating modes — the per-mode specification that becomes the produced SKILL.md's Modes section.

**Field semantics.** Per mode: trigger, purpose, and process. **Optional per-mode additions (Path B):** an **Analytical framework** (the structured method the mode applies) and an **Output specification** (the exact artifact shape the mode emits). Plus a **Core-Behaviors transformation** — how the role's baseline behaviors specialize within each mode. These optional additions are the **CS-04** changes.

**Quality criteria.** Each mode has a distinct trigger surface (no two modes share a trigger — distinct-trigger conjunct per skill-pipeline-alignment). Path-B additions, when present, are decision-grade (the analytical framework is a real method, not a label). Core-Behaviors transformation is specific per mode.

**Applicable CS.** **CS-04** (handle optional Analytical framework + Output specification (Path B) + Core-Behaviors transformation).

## §7 Output Format

**Purpose.** The shape and discipline of the role's outputs — injected into the produced SKILL.md's `## Output Contract` stub and threaded as the close of the §3→§4→§5 persona baseline.

**Field semantics.** **5 output requirements**, one of which is the **Audience-framing rule**: every output declares its audience (exec / technical / mixed) and frames accordingly (exec = decision + so-what; technical = mechanism + evidence; mixed = layered). The Audience-framing rule is the **CS-05** addition and is injection field 2 (`## Output Contract`).

**Quality criteria.** All 5 output requirements present. The Audience-framing rule names the three audience modes and their framing discipline. Decision-class outputs carry a reversibility tier (per the platform reversibility discipline).

**Applicable CS.** **CS-05** (inject the Audience-framing rule into every output-format section).

## §8 Cross-Skill Integration

**Purpose.** How the role composes with other skills — injected into the produced SKILL.md's `## Dependency Graph Node` stub.

**Field semantics.** Upstream/downstream skill edges plus the **8-tag controlled vocabulary** for cross-skill handoff tags. New tags outside the 8-tag set must be flagged with a `[DOMAIN_ACTION]` marker for review rather than silently introduced. The controlled vocabulary + `[DOMAIN_ACTION]` flag are the **CS-06** changes (injection field 3).

**Quality criteria.** Every cross-skill edge names a real skill. Handoff tags drawn from the 8-tag controlled vocabulary; any new tag carries the `[DOMAIN_ACTION]` flag. Composition edges are skill→skill (not role→role absorption).

**Applicable CS.** **CS-06** (enforce the 8-tag controlled vocabulary + `[DOMAIN_ACTION]` flag for new tags).

## §9 Delivery Model Variation

**Purpose.** How the role's behavior varies across delivery models — the source for the produced SKILL.md's `delivery_approach` frontmatter (injection field 1).

**Field semantics.** Per-delivery-model behavior variation across the 5 models (Waterfall · Agile/Scrum · Kanban · Hybrid · n/a), drawn from the shared `operations/skills/_shared/five-model-variations.md` substrate. The variation must be **decision-grade** — specific enough to drive an implementation decision, not "varies." Decision-grade specificity is the **CS-07** quality gate.

**Quality criteria.** Each model's variation is concrete (a reader can act on it). No "varies by methodology" placeholders. `delivery_approach` resolves to a specific value or `context-aware` derivation.

**Applicable CS.** **CS-07** (quality-gate decision-grade variation specificity).

## §10 Guardrails

**Purpose.** The role's hard rejections and anti-patterns — injected into the produced SKILL.md's `## Domain-Specific Failure Modes` section (injection field 5).

**Field semantics.** The suite-wide guardrails (now **9**, with **Local optimization** — the role does not optimize its own metric at the expense of the program — as the **9th**, CS-08) plus the role's domain-specific failure modes in **detection-grade format**: each entry runs **signal → anti-pattern → corrective** (the observable signal, the failure it indicates, the correction). Detection-grade format is the **CS-08** change; the failure modes themselves draw on `operations/skills/_shared/anti-pattern-catalog.md`.

**Quality criteria.** The 9th suite-wide guardrail (Local optimization) is present. ≥3 domain-specific failure modes, each in the 5-field failure-mode shape (Signature · Conditional · Root cause · Mitigation · Principal-vs-junior) per the failure-mode standard, with the detection-grade signal→anti-pattern→corrective framing. Each carries a TRIG/INPUT/PROC/OUT/HAND category tag.

**Applicable CS.** **CS-08** (inject the 9th suite-wide guardrail — Local optimization; apply the detection-grade signal → anti-pattern → corrective format).

## §11 Shared Behavioral Rules

**Purpose.** The cross-suite behavioral rules the role honors — injected into the produced SKILL.md's `## Evidence Quality Protocol` clause (injection field 4).

**Field semantics.** The shared evidence-quality and behavioral rules (evidence labels, push-to-resolve, no-status-theater) plus a **governance-awareness portability note**: the role validates that a governance/reference file exists before reading it (so a role skill deployed into a workspace missing an optional reference degrades gracefully rather than erroring). The portability note is the **CS-09** addition.

**Quality criteria.** The governance-awareness portability note is present (validate-file-existence-before-read). Evidence-quality protocol clause names the evidence labels the role applies. Shared rules are consistent with the platform's universal preferences.

**Applicable CS.** **CS-09** (include the governance-awareness portability note — validate file existence before read).

## §12 Reference Files

**Purpose.** The role's own reference documents and the **extraction depth** at which they are authored — drives the consumption path's reference-doc authoring step (CS-10).

**Field semantics.** Per reference file the role needs: the file, its content contract, and an **extraction-depth level** — one of **Formula/table** (precise lookup data), **Framework** (a structured method), or **Decision rules** (conditional logic). The extraction-depth declaration is the **CS-10** change; it tells the consumption path how deeply to author each reference against the `operations/skills/_shared/` substrate.

**Quality criteria.** Each reference declares its extraction depth. The depth matches the content (lookup data → Formula/table; a method → Framework; conditionals → Decision rules). References that draw on shared content name the `_shared/` file they extend.

**Applicable CS.** **CS-10** (author references at the specified extraction depth — Formula/table · Framework · Decision rules).

## §13 Test Prompts

**Purpose.** The eval-tier declaration that drives the consumption path's eval-prompt-generation step (CS-11), which seeds the preserved harness at the rejoined Create-New step 5.

**Field semantics.** The declared **eval tier** — **Full**, **Standard**, or **Light** — sets the should-trigger / should-not-trigger prompt-pair allocation the consumption path generates:

| Eval tier | Should-trigger | Should-not-trigger | Total |
|---|---|---|---|
| **Full** | 5 | 5 | 10 |
| **Standard** | 3 | 2 | 5 |
| **Light** | 2 | 0 | 2 |

The tier-allocation is the **CS-11** change. (The TPM and Program Coordinator pilots are both **Full** → 5+5.)

**Quality criteria.** The declared tier matches the role's blast-radius (a high-stakes role → Full). The should-trigger prompts are grounded in §1's evidenced trigger phrasings; the should-not-trigger prompts probe the §2 boundary (adjacent-skill requests that must NOT route here).

**Applicable CS.** **CS-11** (generate eval prompts per tier — Full=5+5 / Standard=3+2 / Light=2+0).

## §14 Verification Criteria

**Purpose.** The per-skill verification checklist the produced SKILL.md must pass — the 11-item check the role-skill build verifies against (and the basis for the L1 Pre-Build Validation of the filled feeding document).

**Field semantics.** The **11-item per-skill verification checklist**: §1 identity present · §2 boundary decision-grade · §3 5-element role statement (incl. Distinctive value) · §4 4 mandatory principles (incl. Anticipation) · §5 ≥2 org-tier coverage · §6 modes with distinct triggers · §7 5 output requirements (incl. Audience framing) · §8 8-tag controlled vocabulary · §9 decision-grade delivery-model variation · §10 9 suite-wide guardrails + ≥3 detection-grade failure modes · §13 eval tier declared with the correct prompt allocation.

**Quality criteria.** All 11 items resolvable to a yes/no against the filled feeding document. The checklist is the contract the L1 validation runs.

**Applicable CS.** — (the checklist enumerates the CS changes; it carries no CS change of its own — stable structure from v0.1, content updated by the CS set above).

---

## Appendix A — Persona-Baseline Composition (§3→§4→§5(→§7))

**The CS-13 composition contract.** The consumption path emits the produced SKILL.md's opening as **one continuous, uninterrupted block** — not three disjoint sections with separate headings. The order is:

1. **§3 Role Statement** — identity + the 5 elements (incl. Distinctive value, CS-01).
2. **§4 Operating Principles** — the 4 mandatory principles (incl. Anticipation, CS-02), within the 300-word budget.
3. **§5 Input Handling** — context sensitivity + ≥2 org-tier coverage (CS-03).
4. **(→§7) Audience-framing close** — §7's Audience-framing rule (CS-05) threaded as the output-discipline close of the block.

This is **generation, not interview**: the path composes the feeding-doc sections into prose, it does not ask questions. **CS-13** is the rule that mandates the continuity; CS-01 / CS-02 / CS-03 supply the three sections' content; CS-05 supplies the close. The result is a single persona-baseline opening that reads as one voice.

## Appendix B — Org-Tier Reference

The org tiers a role's §5 coverage is measured against (home + ≥1 adjacent per CS-03): **Portfolio → Program → Project → Workstream/Team → Individual**. A role declares its home tier and the adjacent tier(s) it covers. Example: a TPM's home tier is Program; adjacent coverage is Project (downward) and Portfolio (upward, partial). A Program Coordinator's home tier is Project; adjacent coverage is Program (upward) and Workstream/Team (downward).

## Appendix C — Eval-Tier Selection Guidance

Which §13 tier a role declares is a blast-radius judgment:

- **Full (5+5)** — high-stakes roles whose mis-trigger or mis-output has program-level consequences, or whose trigger surface overlaps closely with an adjacent skill (deconfliction matters). Both pilots (TPM, Program Coordinator) are Full.
- **Standard (3+2)** — moderate-stakes roles with a reasonably distinct trigger surface.
- **Light (2+0)** — narrow-scope, low-overlap roles where a minimal positive-trigger check suffices and false-positive risk is low.

The tier is declared in §13 of the feeding document; the consumption path generates exactly the declared allocation and seeds it into the preserved harness.

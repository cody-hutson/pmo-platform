---
title: Architecture Evaluative-Lens
purpose: The platform's two cross-cutting design-time evaluative lenses — the triple-Venn (quality work = right skill ∩ right methodology ∩ right altitude) and the plug-and-play scope classifier (K1-universal vs K2–K5-install). Names and routes each constituent to its canonical home; cites, never restates. Consulted as an advisory design check at Stage 2 Triage and Stage 4 Planning when a proposal introduces or reshapes a component.
type: reference
kind: disciplines
status: Canonical
reversibility: CHEAP / Confidence HIGH
version: v1.0
composes_with:
  - knowledge-architecture.md
  - work-organization-mapping-framework.md
  - build-philosophy.md
  - applicability-framework.md
  - decision-discipline.md
consumers: "Stage 2 Triage + Stage 4 Planning + Stage 5 Solutioning personas; any contributor proposing a new component or reshaping an existing one"
---
<!-- reference-durability: allow-link -->

# Architecture Evaluative-Lens

## §Purpose

The platform evaluates a proposed or reshaped component along two cross-cutting **design-time lenses**: a **triple-Venn** that asks whether the work sits at the intersection of the right *skill*, the right *methodology*, and the right *altitude*; and a **plug-and-play classifier** that asks whether the work is *universal* (ships in the corpus) or *install-specific* (operator-local). Both lenses already have their constituents codified — deeply — across the skill suite, [`work-organization-mapping-framework.md`](work-organization-mapping-framework.md), and [`knowledge-architecture.md`](knowledge-architecture.md). What was missing is a single surface that **names the two composite lenses** and **routes each constituent to its enforcing home**, so a contributor can apply both checks at proposal time without re-deriving the underlying models.

This doc is that surface. It is a **naming-and-routing instrument, not a restatement** — the exact posture of the [`build-philosophy.md`](build-philosophy.md) charter. Each circle of the Venn and each tier of the classifier is a **pointer** to where it is already defined; this document adds only the *composite framing* and the *design-time application*.

> **Single-source discipline.** Per [`duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md), every constituent named below is a **pointer** to its canonical home — never a copy of the model. This doc does **not** re-derive what a skill is, what `delivery_approach`/methodology-framing is, what the altitude ladder is, or what K1–K5 are. If a section ever restates one of those bodies, that is a defect: it makes this doc a drift target and violates the Maintainability value it is built on. Cite, do not duplicate.

---

## §1 The Triple-Venn lens (skill ∩ methodology ∩ altitude) {#triple-venn}

Quality work sits at the **intersection** of three circles: it is performed by the **right skill**, framed by the **right methodology**, and placed at the **right altitude**. A component strong in one circle but missing the other two is the defect — not a partial success.

> **The durable rule.** *A proposed component is evaluated against all three circles. Strength in one circle does not compensate for a miss in another. The failure signature is a component that is excellent on one axis and silent on the other two — a powerful skill that places its work at the wrong altitude, or a correctly-placed work item with no methodology framing, is a defect, not a near-pass.*

The three circles and where each is already defined (this doc cites; it does not restate):

| Venn circle | What it is | Canonical home this doc CITES (never restates) |
|---|---|---|
| **Skill** | the executing agent capability that performs the work | the skill suite + [`architecture-overview.md` §Skill Architecture](architecture-overview.md#skill-architecture) (skill model); [`anthropic-base-vs-build-registry.md`](../specs/anthropic-base-vs-build-registry.md) (base↔custom authorship of skills) |
| **Methodology** | the framed view the work operates within — the `delivery_approach`, its rules, standards, and reference corpus | [`work-organization-mapping-framework.md` Layer 2](work-organization-mapping-framework.md#layer-2-map) (hierarchy-by-methodology map) + [Layer 4](work-organization-mapping-framework.md#layer-4-plug-and-play) (plug-and-play override); [`applicability-framework.md`](applicability-framework.md) (when a practice applies / is contraindicated) |
| **Altitude** | the hierarchy of thought the work occupies — the level at which it is placed and tracked | [`work-organization-mapping-framework.md` §1.2 per-level-purpose](work-organization-mapping-framework.md#per-level-purpose) (the **live** altitude ladder); [`project-entity-model.md` §18](project-entity-model.md) (the Work Item leaf) |

**The altitude ladder is the live one.** The altitude circle names the canonical level set from [`work-organization-mapping-framework.md` §1.2](work-organization-mapping-framework.md#per-level-purpose): **Portfolio → Program → Project → Milestone/Workstream → Work Item**. It does **not** use the shorthand "Roadmap → Epic → Story/Task → Subtask" — `Epic` is a banned level-label (a backlog-grouping, not a hierarchy level) and `Roadmap` is a Project-board projection, per the glossary Appendix B. There is one ladder, the canonical one; this lens cites it and introduces no competing level-names.

> **Worked example — strong skill, wrong altitude (the lens catches it).** A proposal introduces a capable "weekly-rollup" skill that aggregates status, but writes its output as a **Portfolio**-level artifact when the content it summarizes is the state of a single **Project**. The skill circle is satisfied (the capability is sound) and a methodology is even named — but the **altitude** circle fails: the work is placed one level too high, so it reads as cross-project health when it is single-project status. The triple-Venn surfaces the miss the skill-quality review alone would pass: the fix is to re-anchor the artifact at the Project altitude (per [`work-organization-mapping-framework.md` §1.2](work-organization-mapping-framework.md#per-level-purpose)), not to improve the skill. A component excellent on one circle and silent on another is the defect the intersection is designed to expose.

---

## §2 The plug-and-play lens (K1-universal vs K2–K5-install) {#plug-and-play}

The second lens classifies a proposal's **scope** at proposal time, to route *where it ships*: **K1-universal** content belongs in the corpus (`core/`, git-tracked, shipped to every deployment); **K2–K5 install-specific** content is operator-local (never in the universal corpus). Getting this wrong is the leakage failure — install-specific content embedded in a universal container, or universal capability stranded in an operator-local file.

This lens is the **proactive, proposal-time twin** of the *retrospective* [`knowledge-architecture.md` §4 Local-Context Leakage Register](knowledge-architecture.md#local-context-leakage-register): §4 catalogs leaks **after** they land; this lens prevents them **before** they are authored, by classifying scope at design time. The two are symmetric halves of the same seam discipline.

**It reuses the existing classifier by pointer — it authors no new test.** The routing question is exactly the [§1 Q1 universality test](knowledge-architecture.md#tier-classifier): *"Would this knowledge be TRUE-AND-USEFUL verbatim for a different org or project running the PMO platform?"* — YES ⇒ K1 (corpus); NO ⇒ K2–K5 (contextual, operator-local). This lens does **not** re-derive the classifier, the 5-tier taxonomy, or the placement model — they live in [`knowledge-architecture.md` §1](knowledge-architecture.md#five-tier-classification) and [§3](knowledge-architecture.md#placement-model). This lens adds only the *design-time routing application* of that test.

| Classifier outcome | Scope | Ships where (per [`knowledge-architecture.md` §3](knowledge-architecture.md#placement-model)) |
|---|---|---|
| **K1** — universal | true-and-useful verbatim for any deployment | the corpus — `core/`, `release/skills/*/SKILL.md` (+ `references/`), `core/rules/` (Layer 1, git) |
| **K2–K5** — install-specific | org / project / situational context only | operator-local — `operator.toml`, `CLAUDE.md §Workspace Owner`, `projects/`, the auto-memory store (never Layer 1) |

The **parameterization seam** ([`knowledge-architecture.md` §3](knowledge-architecture.md#parameterization-seam)) is the boundary this lens guards: a K1 artifact references the K2–K5 *parameter* by pointer (the canonical "workspace owner (from CLAUDE.md)" pattern), never the literal value.

> **Worked example — install-specific reference must NOT land in K1.** A proposal would author a reference doc enumerating the operator's named systems, vendors, and the roster of project owners, and place it in `core/` so "every skill can read it." Run Q1: *would this be true-and-useful verbatim for a different org?* — **NO** (it is one org's institutional facts, K3). The lens routes it **out of K1** to the operator-instance home, and — if a universal skill needs to consume that data — the skill references the K3 *parameter* by pointer across the seam, never the literal roster. The capability (a skill that reads owner/vendor context) is universal and may ship in K1; the *content* (the actual names) is contextual and stays operator-local. Classifying scope at proposal time prevents the leak the §4 register would otherwise have to catch after the fact.

---

## §3 Applying the lenses at design time {#design-time-application}

Both lenses are **consulted, not memorized** — they fire when a proposal **introduces or reshapes a component** (a new skill, a new artifact class, a relocation, a scope decision). They attach to the two existing design-time seams in the pipeline as an **advisory, non-gate-blocking** check:

- **Stage 2 Triage — A4 feasibility quick-check.** When a triaged proposal introduces or reshapes a component, the A4 feasibility check additionally applies a lightweight pass of both lenses (triple-Venn + K1-vs-K2–K5 scope), surfacing any miss in the A6 triage summary. Advisory — it informs the recommendation; it is not a Gate-2 criterion. See [`stage-02-triage.md` §5 Process](../../release/references/pipeline/stage-02-triage.md).
- **Stage 4 Planning — Phase A0 Triage→Design Re-Review.** The design re-review additionally applies both lenses as a design-time check; lens findings are advisory and surface in the re-review artifact. They do **not** route Tier-0/1/2 on their own unless they coincide with an independent premise rejection. See [`stage-04-planning.md` §5 Process](../../release/references/pipeline/stage-04-planning.md).

**Why advisory.** Acceptance is that a design check **references** the lens, not that a new hard gate enforces it. The references above add no new gate ID (no `G2-xx` / `G-PLx`) and change no existing gate-criteria list — matching the platform's standing "ship the lens, prefer the lighter mechanism" posture for this work. An *enforced* gate criterion (a `G`-criterion plus a `deploy.sh --check` detector) would be a scope increase beyond the acceptance contract and is tracked separately if the operator elects it (see [§Provenance](#provenance)).

---

## §4 Boundaries {#boundaries}

What this doc does **not** own (each is named to prevent future duplication, per the single-source discipline above):

| Boundary | Relationship | Action |
|---|---|---|
| **K1–K5 taxonomy + classifier + placement model** ([`knowledge-architecture.md`](knowledge-architecture.md)) | The §2 lens **consumes** the Q1 classifier (§1), placement model (§3), and is the proactive twin of the §4 leakage register. That doc = the taxonomy; this lens = its design-time application. | Cite, do not restate. Author no second classifier. |
| **Methodology map + altitude ladder** ([`work-organization-mapping-framework.md`](work-organization-mapping-framework.md)) | The §1 methodology and altitude circles **cite** this framework's Layer 2 map and §1.2 per-level-purpose ladder. That framework defines the levels; this lens names them. | Cite, do not restate. Name the live ladder only — no competing level-names. |
| **Skill architecture** ([`architecture-overview.md`](architecture-overview.md)) | The §1 skill circle **cites** the skill model. | Cite, do not restate. |
| **Gate specifications** ([`release/references/pipeline/`](../../release/references/pipeline/) stage shards + [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md)) | The §3 references are **advisory** notes on existing design-time seams; this doc is **not** a gate spec and defines no gate ID. | Do not author a gate criterion here. |
| **Build-philosophy coverage matrix** ([`build-philosophy.md`](build-philosophy.md)) | That charter is the **structural sibling** (names-and-routes the engineering *values*); this doc names-and-routes the design-time *lenses*. Distinct instruments, same posture. | Compose, do not merge. |

---

## §Provenance

This discipline was graduated from a pattern review (decision-discipline §4.2, N=2 emergence) over two prior platform observations, both general-agent-behavior, both asking to codify a cross-cutting evaluative lens applied at design/proposal time:

- The **triple-Venn** observation — toolkit quality as the intersection of the right skill, the right methodology, and the right altitude.
- The **plug-and-play** observation — a scope lens classifying build scope as K1-universal vs K2–K5 install-specific, to route work to its correct home.

The pattern review promoted both into this single composite-lens layer. The Stage 2 / Stage 4 references are **advisory** (the acceptance contract is that a design check *references* the lens, not that a new hard gate enforces it). Promoting either reference to an **enforced** gate — a `G`-criterion plus a `deploy.sh --check` detector — is a scope increase tracked as separate downstream work, not part of this layer.

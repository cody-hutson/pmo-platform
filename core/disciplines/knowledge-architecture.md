---
title: Knowledge Architecture & Taxonomy
purpose: 5-tier knowledge classification + the orthogonal universality/authorship axes + the placement model (incl. the parameterization seam) + a bounded local-context leakage register for the PMO platform corpus
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: "corpus-curation.md, applicability-framework.md, km-protocols.md (forward-only — relocated via 2026-05-19 capacity-audit merge); CLAUDE.md §Universal Preferences (Single-source-of-truth for knowledge); memory-corpus-drift-audit.md; deploy.sh Check 36"
glossary_anchor: "umbrella body Glossary (canonical knowledge-tier terms — verbatim source for §1)"
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# Knowledge Architecture & Taxonomy

This document is the platform's classification of **knowledge types** and the **placement model** stating where each type lives. It composes with — and does **not** restate — [`architecture-overview.md`](../disciplines/architecture-overview.md)'s Layer-1/Layer-2 model and the [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Governance File Map. Its three contributions are: (1) the 5-tier classification K1–K5 with a deterministic classifier; (2) the net-new **universality axis** drawn orthogonal to the existing authorship axis, proving *custom ≠ contextual*; (3) the **placement model** whose load-bearing concept is the **parameterization seam** — the boundary where CLAUDE.md "Parameterize over hardcode" bites.

Terminology is locked verbatim to the **umbrella Glossary** (the umbrella body IS the canonical glossary per the anti-maintenance-debt rule). [`terminology-glossary.md`](../specs/terminology-glossary.md) is a **disjoint** methodology glossary (Area / Domain / Function / Process / Stage / WBS / Scope) — it carries no knowledge-tier terms; this doc cross-references both and redefines neither (see [§6 Boundaries](#boundaries)).

---

## §1 Five-Tier Classification {#five-tier-classification}
<!-- design-artifact: flow-class=concept-model; name=knowledge-architecture; depicts=core/disciplines/knowledge-architecture.md -->

Five knowledge types are in play across the platform. The summary table is the at-a-glance index; the per-tier blocks below it carry the stable citation anchors downstream consumers reference.

| Tier | Canonical name (umbrella glossary) | Definition (verbatim) | Source framework (corpus-curation source-taxonomy) | Universality | Mutability (feeds km-protocols staleness-by-criticality) |
|---|---|---|---|---|---|
| **K1** | **Codified knowledge** | Explicit, transferable, decoupled from person/context | Nonaka SECI 1995 (externalization/combination) | **Universal** | Slow — version-anchored (release cadence) |
| **K2** | **Organizational Operating Model (OOM)** | How the org actually works — structure, cadences, norms (WoW = behavioral subset, SAFe/DA) | Business-architecture lit; operating-model.md | **Contextual (org)** | Medium |
| **K3** | **Institutional knowledge** | Persistent org facts (systems, vendors, roster, owner identity/contact) | Walsh & Ungson 1991 | **Contextual (org)** | Slow–medium |
| **K4** | **Instance knowledge** | Project-specific state | PMBOK / ITIL | **Contextual (project)** | Fast |
| **K5** | **Tacit / situated knowledge** | Learned by doing, hard to externalize; the CORRECTIONS.md class | Nonaka SECI 1995 (socialization); Schön reflective practice | **Contextual (situational)** | Emergent / fast |

### K1 — Codified knowledge {#k1-codified}

Explicit, transferable, decoupled from person/context. **Source framework:** Nonaka SECI 1995 (externalization/combination). **Universality:** Universal. **Mutability:** Slow — version-anchored. K1 is **the corpus** (the umbrella glossary "Corpus" term = the K1 set): `core/`, `release/skills/*/SKILL.md` (+ `references/`), `core/rules/`.

### K2 — Organizational Operating Model (OOM) {#k2-oom}

How the org actually works — structure, cadences, norms (Ways of Working is the behavioral subset; SAFe/DA). **Source framework:** business-architecture literature; `operating-model.md`. **Universality:** Contextual (org). **Mutability:** Medium. The OOM *model* is universal (K1); the OOM *values* are K2 parameters consumed from CLAUDE.md § Workspace Owner.

### K3 — Institutional knowledge {#k3-institutional}

Persistent org facts — systems, vendors, roster, owner identity/contact. **Source framework:** Walsh & Ungson 1991 (organizational memory). **Universality:** Contextual (org). **Mutability:** Slow–medium.

### K4 — Instance knowledge {#k4-instance}

Project-specific state. **Source framework:** PMBOK / ITIL. **Universality:** Contextual (project). **Mutability:** Fast. K4 lives only in Layer 2 (`projects/[Project]/`); never in Layer 1.

### K5 — Tacit / situated knowledge {#k5-tacit}

Learned by doing, hard to externalize — the CORRECTIONS.md class. **Source framework:** Nonaka SECI 1995 (socialization); Schön reflective practice. **Universality:** Contextual (situational). **Mutability:** Emergent / fast. Promotion path = observation → pattern → (maybe) governance; never hardcoded into K1.

### Tier-assignment decision rule — the classifier {#tier-classifier}

Implementation-ready, deterministic. **Q1 is the universality test** — the single load-bearing classifier and the exact predicate the [§4 leakage register](#local-context-leakage-register) applies.

```
Q0. Does this fact assert something about a repository or system OTHER than this
    install's own platform (an external TARGET the toolkit operates upon)?
      YES → decompose it before homing (§7.1): the target-side referent is read
             live from the target and stored nowhere; the operator-side practice
             continues to Q1 with the target-side referent REMOVED.
      NO  → go to Q1
Q1. Would this knowledge be TRUE-AND-USEFUL verbatim for a *different* org or
    project running the PMO platform?
      YES → K1 Codified  (universal; lives in Layer 1 platform corpus)
      NO  → go to Q2 (it is contextual)
Q2. What is the contextual SCOPE?
      org-wide, "how we work"        → K2 OOM
      org-wide, "persistent facts"   → K3 Institutional
      one project's live state       → K4 Instance
      emergent/corrective/adaptive   → K5 Tacit
```

---

## §2 Two Axes {#two-axes}

Two **orthogonal** axes describe any knowledge artifact. Conflating them is the structural reason local-context leakage is invisible to an authorship-only audit.

### Universality axis (NET-NEW — this doc's core contribution) {#universality-axis}

*universal ↔ contextual* = **whose context does this knowledge apply to?** (any PMO-platform deployment ↔ only [COMPANY_X] / only this project / only this situation). This is the axis Q1 of the [classifier](#tier-classifier) tests. K1 is universal; K2–K5 are contextual at successively narrower scope.

### Authorship axis (cross-referenced, NOT redefined here) {#authorship-axis}

*base ↔ custom* = **who authored it?** (Anthropic base ↔ PMO custom). [`anthropic-base-vs-build-registry.md`](../specs/anthropic-base-vs-build-registry.md) instantiates this axis for *skills*; this doc generalizes the axis label to all knowledge and declares it orthogonal to universality. This document **cross-references** the authorship axis; it does not redefine it.

### The 2×2 matrix {#axis-2x2}

| | **Base (Anthropic-authored)** | **Custom (PMO-authored)** |
|---|---|---|
| **Universal** | `anthropic-skills:skill-creator` conventions; pptx/docx/pdf skills | **(the bulk of the corpus)** 13-stage pipeline, `decision-discipline.md`, `failure-mode-standard.md`, `km-protocols.md`, `corpus-curation.md`, `applicability-framework.md` — PMO-built, applies to *any* PMO-platform instance |
| **Contextual** | rare — a base skill wrapped with org params (e.g., `pmo-skill-refiner` wrapping skill-creator + [COMPANY_X] injection) | **(the leakage zone)** [COMPANY_X] OOM (K2), owner identity/phone (K3), [PROJECT_KEY] RAID state (K4), CORRECTIONS observations (K5) |

**The dispositive insight:** the matrix proves **custom ≠ contextual**. The authorship axis alone cannot detect local-context leakage because a leak is a **universality-axis** violation (contextual content K2–K5 embedded in a universal container K1), *independent of authorship*. `comms-writer` hardcoding `[OPERATOR_NAME], Senior Program Manager • [OPERATOR_PHONE]` is **custom + contextual** — invisible to an authorship-only audit. This is the structural reason this doc's universality axis is a required net-new artifact and not a duplicate of the authorship registry.

### §2.1 The four-memory-type model and four-axis reconciliation {#four-type-reconciliation}

The four memory **types** — *Work / Knowledge / People / Learning* (the [ADR-029](../ADRs/ADR-029-memory-corpus-ssot-boundary.md) / [§7](#memory-corpus-boundary) set) — are a **functional** partition: each answers *what is the memory FOR?* The table below maps each type to ≥1 memory surface and cross-walks it against the three classification axes already in use: **K1–K5** (universality, [§1](#five-tier-classification)), **Context Tier 1–4** (context-file read-precedence, [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Context File Hierarchy), and **Document-Tier 1–4** (write-approval gate, CLAUDE.md File Management Protocol). The four-type taxonomy is therefore a **composed model** over these axes — not a fourth axis stacked on three others.

| Memory type (what it's *for*) | Primary memory surface(s) | K1–K5 (universality) | Context Tier (1–4, where it's read) | Document-Tier (write-approval) | SSOT verdict |
|---|---|---|---|---|---|
| **Work** — active projects, current decisions, open tasks, session continuity | Operational trackers (`projects/[Project]/04-PMO-Operations/`); the `projects/_config/` state files — `SESSION_STATE.md`, `PORTFOLIO.md`; `PROJECT.md` | **K4** Instance (project-specific state) | **Tier 3** (PROJECT.md) · **Tier 4** (PORTFOLIO.md) · session/state files read at session start | **Document Tier 2** (operational trackers, auto-write) · **Tier 1** (RAID Log, Key Terms) · context-file (PORTFOLIO = bridge) | Operational surface is SSOT (the `projects/` tree + state files); never the corpus |
| **Knowledge** — domain expertise, reusable disciplines, frameworks, gate/CI behavior, methodology | The codified **corpus** (`core/`, `release/skills/*/SKILL.md` + `references/`, `core/rules/`, `CLAUDE.md`) | **K1** Codified (universal) — the corpus IS the K1 set | **Tier 1** (CLAUDE.md) · **Tier 2** (OPERATIONS.md) · K1 corpus read by all agents | **Document Tier 1** (governance/stakeholder-facing, approval-gated) · **Tier 4** (context files: drift-detection) | **Corpus is SSOT** when universal (K1); memory holds it only as a temporary eviction-pointer (ADR-029 Knowledge cut) |
| **People** — contacts, organizations, relationship context | The **shipped functional people-graph**: an operator-instance roster (operator-local, never repo-tracked) read through the in-tree graph view [`people-coverage-graph.md`](people-coverage-graph.md) | **K3** Institutional (persistent org facts — roster, owner identity/contact) | read by comms-writer / tracker-manager / ppm-agent / delivery-engine (operator-instance) | operator-write-only (the roster); the graph view is **Document Tier 1** governance | Operator-local toolkit home is SSOT (the roster + `CLAUDE.md §Workspace Owner` for identity); **never repo-tracked PII** |
| **Learning** — patterns, mistakes, what works for the operator specifically | The operator auto-memory store **`~/.claude/memory/`** (+ its `MEMORY.md` index) | **K5** Tacit/situated (the CORRECTIONS.md class) | **Tier 1.7** (CORRECTIONS.md) · the `~/.claude/memory/` store loaded via `autoMemoryDirectory` | operator-write-only (CORRECTIONS.md, the memory store); graduation → corpus runs the release process | **Memory store is SSOT** for tacit/situated K5; it is the **graduation source** for Knowledge (encode-and-evict) |

**Reading note:** a type may touch more than one surface and more than one Document-Tier (Work spans Tier-1 RAID + Tier-2 trackers); the cells name the *dominant* tier with the spread parenthesized — this is the composite-multi-entity discipline already used in [`operational-artifact-inventory.md` §4](../specs/operational-artifact-inventory.md), not a collision.

#### Axis-collision resolution {#four-axis-collision}

> **Collisions / open: None — axes compose cleanly.**

Four distinct questions are asked over the same memory artifact, and a given artifact carries exactly one value on each axis *simultaneously* with no contradiction:

- **Memory-type axis** answers *what is the memory FOR?* (Work / Knowledge / People / Learning) — a **functional** partition.
- **K1–K5 axis** answers *whose context does it apply to?* (universal ↔ contextual) — the **universality** partition ([§2 universality axis](#universality-axis)).
- **Context Tier (1–4)** answers *how specific is the file that holds it, and in what read-order?* — a **read-precedence** partition (CLAUDE.md Context File Hierarchy).
- **Document-Tier (1–4)** answers *what approval gate governs writing it?* — a **write-authority** partition (CLAUDE.md File Management Protocol).

Orthogonality is *demonstrable, not asserted*: fixing one axis does not determine the others. A CORRECTIONS.md entry is simultaneously **Learning** type / **K5** universality / **Tier-1.7** read-precedence / **operator-write-only** authority — four independent coordinates. This is the same orthogonality the [§2 2×2 matrix](#axis-2x2) proves for the universality×authorship pair, extended to four axes. The reconciliation is therefore a **composition**, not a fourth axis "stacked on three others" (the explicit anti-goal in this taxonomy's source).

---

## §3 Placement Model {#placement-model}

The model composes with (does **not** restate) [`architecture-overview.md`](../disciplines/architecture-overview.md)'s Layer-1/Layer-2 model and the [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) Governance File Map. Its novel contribution is the parameterization seam.

| Tier | Authoritative home | Layer | Owner | Read-by | Parameterization rule |
|---|---|---|---|---|---|
| **K1** | `core/`, `release/skills/*/SKILL.md` (+ `references/`), `core/rules/` | L1 | Claude Code (git) | all agents | MUST NOT embed K2–K5 literals; reference the parameter, never the value |
| **K2** | **Model:** `../disciplines/operating-model.md`  · **Values:** `CLAUDE.md` § Workspace Owner | L1 + parameter | Claude Code | all agents | model universal; *values* are parameters consumed from CLAUDE.md |
| **K3** | `CLAUDE.md` § Workspace Owner + `projects/[Project]/PROJECT.md` | L1 + L2 | mixed | all agents | skills say "workspace owner (from CLAUDE.md)" — never the literal name/number |
| **K4** | `projects/[Project]/` (01–08 + PROJECT.md) | L2 | Claude Code (operations) | Claude Code (operations) | never in L1 |
| **K5** | `projects/_config/CORRECTIONS.md`, the observation log + promoted confirmed-pattern entries (user auto-memory store) | L2 + auto-memory | Claude Code (operations) / auto-memory | both | never hardcoded into K1; promotion path = observation → pattern → (maybe) governance |

**Load-behaviour axis — not carried here.** This model classifies by knowledge tier and universality; it does not distinguish a *rule* from a *skill* or a *reference doc* by how the content loads. That axis — the admission test for the ambiently-loaded rules set, its frontmatter contract, and its byte budget — is owned by [`rules-corpus-admission-standard.md`](../standards/rules-corpus-admission-standard.md). A K1 artifact homed under `core/rules/` in the table above must additionally pass that standard's §1 test; failing it is a placement decision, not a tier reassignment.

### Parameterization seam {#parameterization-seam}

The model's load-bearing concept, consumed by . The **K1↔K2/K3 boundary** is exactly where CLAUDE.md "Parameterize over hardcode" and "Pre-creation governance check" apply. The [§4 leakage register](#local-context-leakage-register) is the catalog of where this seam is currently breached.

**Positive exemplar (the canonical correct pattern):** `daily-status/SKILL.md:97` — *"Items assigned to the workspace owner (from CLAUDE.md)"* — references the K3 parameter by pointer, never the literal name/number. New and edited K1 artifacts MUST follow this pattern at the seam.

---

## §4 Local-Context Leakage Register {#local-context-leakage-register}

**Scope discipline (BOUNDED — per AC + Stage 4 plan "Discoveries outside scope"):** this register is a deliverable that **ENUMERATES and SIZES**; it does **not** remediate. Remediation is owned by **initiative-umbrella child issues**, milestone-agnostic and future. The Stage-4 plan's note tying the register to in-scope child issues is **stale post-D-NEW1(a)** — corrected here: register consumers are remediation children, **not** in-scope consumers (which consume the *taxonomy*, not the *register*).

This register is **retrospective** — it catalogs leaks after they land. Its proposal-time twin is the [`architecture-evaluative-lens.md` §2 plug-and-play lens](architecture-evaluative-lens.md#plug-and-play), which applies this register's universality test *proactively* at design time to route a build's scope before the leak is authored.

**Classification rubric** (the register is not a flat file list):

| Class | Meaning |
|---|---|
| **TRUE-LEAK** | contextual (K2–K5) literal in a universal (K1) container — violates the [seam](#parameterization-seam) |
| **PARAMETERIZED-OK** | references CLAUDE.md / a param — **NOT** a leak (exemplar) |
| **ILLUSTRATIVE** | example / sample data — low severity, register-but-defer |
| **GENERIC-ROLE** | "workspace owner" / "the operator" with no literal — **NOT** a leak |
| **HOST-BINDING-LEAK** | a host tool (`gh` / `git` / a host API) hardcoded as *the* canonical mechanism in a universal (K1) container where the operation belongs behind an adapter seam — an **abstraction-altitude / seam-composition** leak, distinct from the identity/contextual leaks above (the leaked thing is a *mechanism coupling*, not a K2–K5 literal). The host-axis sibling of the path-portability leakage class. |

**Register (logical sources; mirror-copied refs de-duplicated):**

| # | Logical source (files) | Leaked tier | Signature | Class | Severity | Size note |
|---|---|---|---|---|---|---|
| L1 | `comms-writer/SKILL.md:156`, `references/channel-formats.md:88`, `references/voice-guide.md:165` | K3 | `[OPERATOR_NAME], Senior Program Manager • [OPERATOR_PHONE]` (incl. phone — PII-adjacent) | **TRUE-LEAK** | **MEDIUM-HIGH** | 3 files, 1 logical signature block |
| L2 | `project-initiator/references/project-md-template.md:55` + `templates/{communications-tracker,open-meetings-tracker,executive-status-report-prompt}-template.md` | K3 | `[OPERATOR_NAME] \| Senior Program Manager (TPM)` / `Prepared by: [OPERATOR_NAME]` | **TRUE-LEAK** | **MEDIUM** | 4 files; propagates identity on every project-init |
| L3 | `build-reviewer/references/dimension-packs/pmo-platform-dimensions.md:236` | K2+K3 | "[OPERATOR_NAME] — Senior Program Manager / Technical Program Manager at [COMPANY_X]" | **TRUE-LEAK** | **MEDIUM** | 1 file; full OOM+institutional identity in a dimension pack |
| L4 | `eval-writer/references/playbook-per-skill.md:38,44,139` | K2 | "[OPERATOR_NAME] reviews outputs", "already-coded failure modes", single-operator HITL assumed | **TRUE-LEAK** (also an applicability concern) | **LOW-MEDIUM** | 1 file, 3 lines; embeds single-operator OOM assumption |
| L5 | `../governance/OPERATIONS.md:5` | K2+K3 | header "[COMPANY_X] PMO / [OPERATOR_NAME]" | TRUE-LEAK (governance file — expected to carry identity; flag, low priority) | **LOW** | 1 line |
| L6 | `template-protocol.md` ×6 skills (delivery-engine, eval-writer, pmo-process-designer, pmo-skill-refiner, release-planner, project-initiator) lines 75/247/252 | K3 | example `reviewer/owner: [OPERATOR_NAME]` | **ILLUSTRATIVE** | **LOW** | 6 files, **1 logical source** (mirror-copied reference) |
| L7 | `template-storage.md` ×5 skills line 102 | K4 | "projects/[PROJECT_KEY] Implementation/...[PROJECT_KEY]_RAID_Log.csv ... [COLLEAGUE_I] integration delay" | **ILLUSTRATIVE** | **LOW** | 5 files, **1 logical source**; names a real project path |
| L8 | `delivery-engine/references/{dependency-rules,raid-templates}.md`; `change-management/SKILL.md:254`; `ppm-agent/SKILL.md:308` | K4 | `R-[PROJECT_KEY]-042`, "[PROJECT_KEY] go-live, 10.0.47", "steerco on [PROJECT_KEY] cutover" | **ILLUSTRATIVE** | **LOW** | example data; convention parameterized, value is the example |
| HB1 | *(illustrative — the motivating class instance)* universal release governance prescribing `gh`/`git` as *the* version-claim mechanism | — (mechanism coupling, not a tier-literal) | `gh api .../releases/latest` + signed-tag-push named as *the* version-claim mechanism in K1 release governance | **HOST-BINDING-LEAK** | scales with breadth (single-site LOW–MED → corpus-wide canonical mechanism MED–HIGH) | host-axis sibling of the path-portability class; correct pattern = the `[adapters].repo_host` recast per `repo-host-adapter-versioning.md` |
| — | `daily-status/SKILL.md:97`; `release-executor/.../rollback-protocol.md:144`; `file-router/SKILL.md:289`; `prompt-builder/.../critique-rubric.md:138`; `implementation-planner` domain-pack `operator_profile_default:` | — | "workspace owner (from CLAUDE.md)" / generic role / overridable default | **PARAMETERIZED-OK / GENERIC-ROLE** | n/a | **NOT leaks** — `daily-status:97` is the positive exemplar |

**Sizing for triage:** 18 raw grep hits → **8 logical leakage rows** + 5 not-a-leak rows → **4 actionable TRUE-LEAKs at MEDIUM+ (L1–L4)** worth a downstream remediation child issue; L5 LOW (governance, defer); L6–L8 ILLUSTRATIVE LOW (defer or accept-as-example). The scan signatures used (`[COMPANY_X]`, `[OPERATOR_NAME]`/`[OPERATOR_NAME]`, role strings, `[PROJECT_KEY]`) are **not exhaustive** — a remediation child should also sweep vendor names and phone/email PII patterns. Register is **sufficient to triage**, not claimed complete.

**Authoritative inventory:** the complete audit register superseding this bounded snapshot lives in the operator-instance analysis archive (external to this repo) — the deliverable (10 TRUE-LEAK rows + 5 ILLUSTRATIVE rows; 9-column schema per [`universal-vs-localized-context.md` §9](../standards/universal-vs-localized-context.md)). §4 retained here as the **model-illustrating example** (illustrative; not authoritative); the audit register is the operative inventory for remediation triage.

### §4.1 Host-binding leakage class {#host-binding-leakage-class}

The L1–L8 register above catalogs **identity/institutional** leaks — contextual (K2–K5) literals (operator name, phone, company, project key) embedded in universal (K1) containers. **Host-binding** is a leakage class on a *different axis*: it is an **abstraction-altitude / seam-composition** leak, not a contextual-literal leak.

**Definition.** A **host-binding leak** is the hardcoding of a host tool — `gh`, `git`, or a host API — as *the* canonical mechanism inside universal (K1) governance, where the operation in fact belongs behind an **adapter seam**. The leaked content is not a K2–K5 *value*; it is a *mechanism coupling* — K1 governance that should describe a host-agnostic capability instead names one host's tool as the only way to perform the operation. This binds the universal corpus to a single host, defeating the portability the adapter seam exists to provide.

**Why it is invisible to the identity-leak audit.** The §4 universality-axis classifier (Q1: "TRUE-AND-USEFUL verbatim for a different org/project?") catches a contextual *literal* but not a host *mechanism* — `gh pr merge` is arguably "true and useful for a different org" (any org using GitHub), so the universality test does not flag it. The leak is an **abstraction-altitude** failure (the K1 rule solves at the wrong altitude — host-concrete where host-agnostic-plus-adapter is correct), not a universality-scope failure. This is the structural reason it needs its own class, exactly as the [§2 2×2 matrix](#axis-2x2) showed identity leaks need the universality axis the authorship axis cannot see.

**Canonical rule (the seam a host-bound operation should compose with).** Host operations belong behind the `operator.toml [adapters]` selectors, per [`repo-host-adapter-versioning.md`](../standards/repo-host-adapter-versioning.md): a host-agnostic capability calls **named adapter operations** (e.g. `anchor()` / `claimed_set()` / `atomic_claim()` / `lineage()` for version-claiming), and the host mechanism (`gh` / `git`) lives **only** inside the adapter, never inlined into K1 capability text. The selector is `operator.toml [adapters].repo_host` (per [ADR-022](../ADRs/ADR-022-platform-config-vs-operator-toml-split.md)). K1 governance that hardcodes the host tool as the mechanism is the leak; K1 governance that references the adapter operation is the correct pattern.

**Worked example.**
- **Leak:** universal release governance stating *"claim the version by pushing a signed git tag and reading `gh api repos/{REPO}/releases/latest`"* as the version-claim mechanism. This is `gh`/`git` hardcoded as *the* mechanism in K1 governance — a host-binding leak: the version-claim *capability* is host-agnostic (a release claims a collision-free number; *how* the host anchors/arbitrates is a host property), so naming the host tool in K1 couples the corpus to GitHub/git.
- **Correct pattern (extend-seam altitude):** universal governance describing the version-claim as four host-agnostic operations behind `[adapters].repo_host`, with `gh`/`git` confined to the GitHub/git reference adapter — per [`repo-host-adapter-versioning.md`](../standards/repo-host-adapter-versioning.md) §2/§4. The K1 rule names `anchor()`/`claimed_set()`/`atomic_claim()`/`lineage()`; the adapter (not the K1 rule) knows about `gh`/`git`.
- **Detection signature:** a literal `gh ` / `git ` command (or a host API path like `repos/{...}/...`) appearing as the prescribed mechanism in a K1-tier file (`core/`, `release/skills/*/SKILL.md` + `references/`, `core/rules/`, `release/governance/`, `release/references/pipeline/`) — as distinct from (a) a *reference adapter* documenting the host binding (legitimate — that IS the adapter's job, e.g. the §4 table in `repo-host-adapter-versioning.md`), or (b) a *worked example / illustrative* host command. The class fires on host-tool-as-prescribed-mechanism in universal governance, not on every textual occurrence of `gh`/`git`.

**Sibling to the path-portability leakage class.** Host-binding is the **host-axis** member of a two-axis family of install-environment-coupling leaks into universal governance; the **path-axis** sibling is the path-portability leakage class (install-environment/local paths — `$HOME/…`, `/Users/…`, an operator-instance directory — hardcoded into the universal corpus where they must be parameterized, e.g. `${PMO_INSTANCE_PATH}`). Both are abstraction-altitude leaks: a universal rule binding to an install-specific concretion (a path on the one axis, a host tool on the other) that should sit behind a parameter or an adapter seam. The path-portability class is enforced by its own prevention gate (an existing path-portability enforcement surface); the host-binding class is enforced by a sibling **`deploy.sh --check` detector** (`host-binding-leak`, warn-mode-initial) that flags a host tool prescribed as the canonical mechanism in K1-tier governance using the detection signature above — registering this class is the definition that detector consumes.

**Register classification.** A confirmed host-binding leak classifies as **HOST-BINDING-LEAK** in the §4 rubric (the new class), at a severity scaled by the breadth of the host coupling (a single host-op site in one pipeline shard = LOW–MEDIUM; the canonical version-claim mechanism prescribed host-concrete across release governance = MEDIUM–HIGH). Remediation is the lift-to-adapter-seam recast (extend-seam altitude per [`design-exploration.md`](../../release/references/standards/design-exploration.md) §2), owned by the relevant adapter/portability follow-up work, not by this register (which enumerates the class; it does not remediate, per the §4 scope-discipline note).

---

## §5 Organizational-Altitude / Aggregation Axis {#altitude-axis}

This axis answers a **third, independent question about a *learning*** — *at what scope of work was this learning generated, and how does it roll up?* — distinct from the two questions [§1](#five-tier-classification)/[§2](#two-axes) already answer (*whose context does this knowledge apply to?*, the universality axis) and from the question the work-organization framework answers (*where does a unit of WORK sit in the decomposition?*, [`work-organization-mapping-framework.md` §1.2](work-organization-mapping-framework.md#per-level-purpose)). A learning is **not** a work item, so altitude is **not** a new work-level and adds **no** entity-graph node: it is a **captured attribute** the [`km-protocols.md §3`](km-protocols.md#lessons-learned-pipeline) lessons-learned pipeline stamps when a lesson is observed.

> **Orthogonality declaration (the load-bearing statement).** The altitude axis is **orthogonal** to the K1–K5 universality axis ([§1](#five-tier-classification)/[§2](#universality-axis)): a learning carries **one K-tier value AND one altitude value simultaneously, independently** — fixing one does not determine the other. Both axes coexist on every learning. This is the same orthogonality the [§2 2×2 matrix](#axis-2x2) proves for universality×authorship and [§2.1](#four-axis-collision) proves for the four memory types, extended to the altitude attribute.

**Orthogonality proof (demonstrable, not asserted — same style as [§2.1](#four-axis-collision)).** Fixing a learning's K-tier does **not** fix its altitude: a **K1-universal** lesson ("write-first-speak-second prevents status theater") can be generated at **Project** altitude (observed once on one project) *or* at **Portfolio** altitude (observed as a cross-project pattern) — same K-tier, different altitude. And fixing altitude does not fix K-tier: two learnings both generated at **Project** altitude can split **K1** (a universal discipline) vs **K5** (a project-specific corrective that never generalizes). The two coordinates vary independently → the axes are orthogonal.

### §5.1 Altitude ↔ canonical-hierarchy alias {#altitude-alias}

The altitude ladder's seven rungs are **aliased onto** the canonical work-organization hierarchy — they introduce **no competing level-names**. The four middle rungs are **verbatim aliases** of the canonical levels ([`work-organization-mapping-framework.md` §1.2 per-level-purpose](work-organization-mapping-framework.md#per-level-purpose), whose frozen entity floor is the single `Work Item` node and whose `general_level` enum `{Portfolio, Program, Project, Milestone/Workstream, Work Item}` is frozen at the schema layer — cited by pointer, **not** redefined here). The two outer rungs are **out-of-hierarchy alias values** — finer than the modeled floor and coarser than the modeled ceiling — that the lessons pipeline may stamp on a learning **without** adding any entity level:

| Altitude rung | Canonical level it aliases to (`work-organization-mapping-framework.md` §1.2 / frozen `general_level` enum) | Alias semantics |
|---|---|---|
| **Unit** | *sub-Work-Item granularity* (within the `Work Item` entity) | Finer than the finest modeled level. NOT a new entity node — the same collapse the framework applies to Story/Task (methodology levels below Milestone all land on the single `Work Item` entity, distinguished by `work_item_type`, never by adding nodes). "Unit" = a learning generated at the granularity of a single discrete action/change *inside* a Work Item. |
| **Task** | *sub-Work-Item granularity* → the canonical `Task` term ([`terminology-glossary.md#term-task`](../specs/terminology-glossary.md#term-task): a Work Item whose scope is subsumed by a single Stage) | Aliases to the **existing** canonical `Task` term — a stage-scoped Work Item, already a recognized projection within the Work Item level. Introduces nothing new. |
| **Workstream** | **Milestone / Workstream** (canonical level 4) | 1:1 — verbatim alias of the existing canonical level name. |
| **Project** | **Project** (canonical level 3) | 1:1 — verbatim. |
| **Program** | **Program** (canonical level 2) | 1:1 — verbatim. |
| **Portfolio** | **Portfolio** (canonical level 1) | 1:1 — verbatim. |
| **Organization** | *supra-Portfolio roll-up scope* — NOT a modeled entity level | Coarser than the coarsest modeled level. Aliases to the **same disposition the glossary gives `Initiative`** ([`terminology-glossary.md` Appendix B](../specs/terminology-glossary.md): "Portfolio-level concept not modeled at platform layer → cross-Milestone roadmap theme"). "Organization" = a learning that has rolled up across the whole single-operator org (the K2 OOM scope) — a roll-up *scope label*, not an entity the platform tracks. |

> **Boundary note.** This axis adds **no** entity-graph node and changes **no** work-org level or `general_level` enum value. **Unit/Task** (below the floor) and **Organization** (above the ceiling) are altitude-attribute *values* that alias *outside* the modeled 5-level hierarchy — reconciled here by pointer, never authored as new levels. The four middle rungs ARE the canonical work-org vocabulary. The work-org hierarchy, its frozen enum, and the frozen entity roster are untouched (additive-only per [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) surgical-edit discipline).

**Relationship to the design-time altitude lens (distinct, cross-referenced — not merged).** [`architecture-evaluative-lens.md` §1 triple-Venn](architecture-evaluative-lens.md#triple-venn) carries an **altitude circle** asking *at what level is this WORK placed and tracked?* — a **design-time** evaluative lens over the live work-org ladder. This axis asks a **capture-time** question over a *learning* (*at what scope was this learning generated?*). Both cite the **same** canonical ladder (`work-organization-mapping-framework.md` §1.2) by pointer and neither introduces competing level-names; they are **related but distinct** — design-time work-placement lens vs capture-time learning-attribute — and are cross-referenced, never collapsed into one definition.

**Forward pointer.** The capture mechanism (altitude stamped at Step 1 of the lessons-learned pipeline) and the adjacent-altitude rollup relation are owned by [`km-protocols.md`](km-protocols.md) — see [`§3 Lessons-Learned Pipeline`](km-protocols.md#lessons-learned-pipeline) (capture-time attribute) and [`§9 Adjacent-Altitude Rollup`](km-protocols.md#altitude-rollup) (the `ROLLS_UP_TO` relation). This doc owns the *axis + alias*; the pipeline doc owns the *capture + rollup*.

---

## §6 Boundaries {#boundaries}

| Boundary | Relationship | Action |
|---|---|---|
|  — authorship axis (`anthropic-base-vs-build-registry.md`) | **Satisfied.**  owns *base ↔ custom*; this doc owns the orthogonal *universal ↔ contextual* and cross-references  for authorship. | No action — cross-reference only ([§2](#authorship-axis)). |
| Universal-Protocol vs Localized-Context separation (audit + standard) | The audit + enforcement standard **consumes** this doc's universality axis. This doc = the *model*; the standard = the *audit + enforcement standard* on it. **Out of scope here.** | **Do NOT action.** Boundary stated to prevent future duplication. |
| ** / [`operating-model.md`](../disciplines/operating-model.md)** — K2 model home | This doc's placement model assigns the K2 *model* to `operating-model.md`; K2 *values* are CLAUDE.md parameters. | Compose, do not restate. |
| **[`terminology-glossary.md`](../specs/terminology-glossary.md)** — disjoint methodology glossary | Carries Area/Domain/Function/Process/Stage/WBS/Scope — **no** knowledge-tier terms. No collision, no redefinition risk. | Cross-reference; redefine nothing. |
| **[`architecture-evaluative-lens.md`](architecture-evaluative-lens.md)** — design-time plug-and-play lens | The lens **consumes** this doc's [§1 Q1 universality classifier](#tier-classifier) + [§3 placement model](#placement-model) as the *proactive proposal-time* application; the [§4 leakage register](#local-context-leakage-register) is its *retrospective* twin. This doc = the taxonomy; the lens = its design-time application. | Cross-reference; redefine nothing. |
| **External-target facts** — a repository or system the toolkit *operates upon* | The universality axis routes by *whose context*, and its [Q2 scope enumeration](#tier-classifier) is closed over this install's own contexts — it carries no scope value for a repo that is neither this install's platform nor one of its projects. [§7.1](#external-target-scope) adds that scope and its SSOT rule. | Cross-reference; the scope adds no tier and redefines nothing. |

---

## §7 Memory↔corpus boundary {#memory-corpus-boundary}

This section names **which surface is the source of truth (SSOT) when a fact could appear in two places** — the auto-memory store or the codified corpus — and **how knowledge moves from memory into the corpus reliably**. It is a pure consumer of [§1](#five-tier-classification) and [§3](#placement-model): it adds no taxonomy. §3 owns *where each tier lives*; §7 owns *which surface is authoritative when a fact could live in two, and how it migrates*. This respects single-home discipline — the SSOT assignment below is a projection of the §3 "Authoritative home" column onto the auto-memory store specifically, and the routing test is the existing §1 Q1 universality classifier.

Apply the [§1 Q1 universality test](#tier-classifier): TRUE-AND-USEFUL for a different org/project ⇒ K1 ⇒ corpus-SSOT; otherwise it is K2–K5 contextual and its SSOT is the placement-model home in §3. The auto-memory store is the §3 home for K5-tacit only.

**Position in the memory architecture.** This boundary is the **Knowledge cut** of the platform's four-type memory model — *Work* (active projects/tasks → operational state), *Knowledge* (domain expertise, frameworks → codified, corpus-SSOT), *People* (contacts/relationships → the shipped functional people-graph: an operator-instance roster read through the in-tree [`people-coverage-graph.md`](people-coverage-graph.md) view), and *Learning* (patterns/what-works → tacit/situated K5, memory-store-SSOT). Codified Knowledge is corpus-SSOT; the Learning class is memory-store-SSOT; the encode-and-evict lifecycle below is the *graduation* path between them. The architecture, the rejected alternatives, and the extensibility to the other three types are recorded in [ADR-029](../ADRs/ADR-029-memory-corpus-ssot-boundary.md); the full four-axis reconciliation of these types against the K1–K5 / Context-Tier / Document-Tier axes is [§2.1](#four-type-reconciliation), and the whole model slots into the platform's broader cross-surface memory-architecture epic.

<!-- repo-integrity: allow-memory-ref -->

### The two-tier SSOT assignment {#two-tier-ssot}

| Knowledge class | Tier | SSOT surface | May the auto-memory store hold it? |
|---|---|---|---|
| Local / situated — operator identity & attribution, accounts/systems, instance projects, local-machine config, corrections-to-the-agent | K5 (+ operator-config) | **auto-memory store** (`~/.claude/memory/`) for tacit/corrective K5; `operator.toml` + `CLAUDE.md §Workspace Owner` + `projects/` for K2/K3/K4 config/state | **K5 tacit: YES (SSOT).** K2/K3/K4: NO — their SSOT is the operator-local toolkit home; a memory copy is mis-homed. |
| Toolkit-encodeable / codified — general disciplines, reusable references, gate/CI behavior, methodology | K1 | **corpus** (`core/`, `release/skills/*/SKILL.md` + `references/`, `core/rules/`, `CLAUDE.md`) | **Only as a temporary eviction-pointer** tied to a live encode issue; the rule TEXT lives in the corpus, never as a full copy in memory. |

### The no-shadow-SSOT invariant {#no-shadow-ssot}

> **No-shadow-SSOT invariant.** A fact has exactly one source of truth. The auto-memory store is the SSOT for tacit/situated K5 knowledge (and the staging surface for a temporary eviction-pointer); it is **never** a second source of truth for knowledge whose SSOT is the codified corpus or an operator-local toolkit home. A memory entry that holds a full copy of a codified rule is a *shadow SSOT* — it can drift from the corpus, and an agent reading the memory copy lets memory silently override governance. Shadow SSOTs are prohibited: codified knowledge appears in memory only as a pointer to its corpus home (a temporary eviction-pointer while an encode issue is in flight, or a durable cross-reference), never as a duplicate of the governed text.

### Encode-and-evict lifecycle {#encode-and-evict}

Knowledge moves from the auto-memory store into the corpus through five phases (the fifth, RE-POINT, reconciles surviving references after the file leaves). Ordering is **structurally enforced** — the VERIFY-CORPUS gate makes corpus-presence a *precondition of eviction*, so encode-then-evict cannot invert:

```
ENCODE        the codification issue's PR writes the rule text into its corpus home
              (Layer-1, git) and lands on main.  [Stage 6–12 of the encode issue's release]
   │
ARCHIVE       at the encode issue's Stage-13 Phase B-OPS, the full memory-file body(ies)
              + index line(s) + any ledger row are pasted verbatim into the Stage-13
              sub-task comment (recoverable record) — BEFORE any deletion.
   │
VERIFY-CORPUS confirm the corpus home actually contains the rule (grep the encoded
              heading/phrase on main).  Gate: eviction does NOT proceed if the corpus
              write is absent — this is the guard against "issue closed before corpus
              write" content-loss.
   │
EVICT         move the memory file(s) to Trash (CHEAP-recoverable, not rm), remove the
              MEMORY.md index line(s), retire the eviction-pointer/ledger row.
              Post-state verification: file-absence + index-absence + pointer-absence.
   │
RE-POINT      reconcile every SURVIVING memory that [[wikilink]]s the just-evicted
              file. Precedence (deterministic): (1) RE-POINT the link to the corpus
              location now owning the knowledge — already in hand from the VERIFY-CORPUS
              grep, which IS the corpus-home discovery; the link becomes a corpus-path
              cross-reference (the no-shadow-permitted "durable cross-reference" form).
              (2) DROP the link (leaving surrounding prose intact) only when the evicted
              knowledge was split/absorbed with no single citable corpus home. Re-point
              precedes drop — drop is the documented fallback, not the default.
```

**Why encode-then-evict is mandatory.** A naive "issue CLOSED → delete memory" loses content when the close preceded the corpus write — a close-keyword can fire on a PR that did not actually carry the encoding. The VERIFY-CORPUS gate makes the corpus-presence check a precondition of eviction, so the ordering cannot invert; the ARCHIVE-first step makes even an erroneous eviction CHEAP-reversible.

**Why RE-POINT closes the downstream gap.** Before this step, EVICT stopped at the file/index/ledger row, leaving surviving memories that `[[wikilink]]`ed the deleted file dangling — the convention permits dangling links (not an error) and the content lives in the corpus, so nothing breaks, but the links no longer navigate. RE-POINT is a zero-extra-discovery operation (the corpus home is already known from VERIFY-CORPUS) that restores navigability. It is an **operator-authorized Phase B-OPS executor action** (it edits the Layer-2 memory store under the same authorization envelope as EVICT; ARCHIVE already captured the pre-state) — never performed by a deploy check. The standing `deploy.sh --check` Check 36 only *detects* an un-re-pointed dangling link (the `dangling-wikilink-to-evicted-memory` class below); it never re-points. **Reversibility: CHEAP.**

### Trigger + audit {#trigger-and-audit}

Two surfaces with distinct roles (a deploy check validates — it must never mutate the operator memory store; the operational-deploy step executes under operator authorization):

- **PRIMARY executor = Stage-13 `Phase B-OPS` operational-deploy step.** The encode issue's release plan carries an operational-deployment manifest with the memory-eviction entries; Phase B-OPS executes ARCHIVE → VERIFY-CORPUS → EVICT under operator authorization. See [`stage-13-close.md` §5 Phase B-OPS](../../release/references/pipeline/stage-13-close.md) (gated by `G-CL5`, the operational-deployment-manifest-executed gate).
- **STANDING BACKSTOP = `deploy.sh --check` Check 36 (`memory-corpus-tie-drift`, warn-mode-initial).** The non-skippable standing audit that catches what a forgotten manifest entry misses. It runs every `./deploy.sh --check`, **deletes nothing**, and emits the six drift classes as warnings regardless of whether anyone remembered the Phase B-OPS entry. The full human-runnable procedure is [`memory-corpus-drift-audit.md`](../../release/references/how-to/memory-corpus-drift-audit.md); the fixture self-test is `core/deploy/tests/test_check36_drift_classes.sh`.

**Close-time absorption reconciliation (the upstream gate).** The lifecycle above assumes a tracking issue absorbs ALL memories pointing at it before it closes. It has no guard for *partial* absorption: when a codification issue closes COMPLETED having absorbed a SUBSET of the memories that name it in the ledger, the unmatched memories point at a closed-but-unfulfilling issue — tracked in appearance, untracked in fact, and unable to ever evict (their ship-signal already fired). The guard is a **close-time reconciliation** executed at **Stage-13 `Phase B-OPS5` (Absorption reconciliation)**, before the Milestone/issue close: diff the issue's authoritative absorbed-memory-list (its ARCHIVE manifest — already enumerated for EVICT) against every memory naming that issue in the ledger; the set-difference is the stranded set. If non-empty, **flag and block the close** until each unmatched memory is re-homed to a live issue (re-tie the pointer to a still-open codification issue, or file a new encode issue) — preserving the evict-on-ship invariant (a memory's ship-signal may fire only once its issue actually absorbs it). The diff is computable from artifacts that already exist at Phase B-OPS (the ARCHIVE manifest + the ledger); homing the gate there (not at a generic close hook) is correct because codification issues close through the release pipeline — Stage 13 IS their close path. See [`stage-13-close.md` §5 Phase B-OPS5](../../release/references/pipeline/stage-13-close.md). This gate is a *governance precondition on a close*, not a memory mutation — invariant-safe; its continuous detection backstop is the `ledger-pointer-to-closed-issue` class below. **Reversibility: CHEAP.**

This is the same shape as the skill↔reference single-source contract (a single-source executor + an enforced-rebuild deploy check) — applied here to the memory↔corpus surface.

### The six drift classes {#drift-classes}

The drift audit treats issue-number identity as **fragile** (re-versioning renumbers issues): a dead reference is detected by **reference-resolution-failure**, **never** by digit-match (e.g. never "is this issue number below the current max"). Only a resolution probe (`gh issue view N`) is load-bearing. The six classes split by what they probe: three require issue-resolution (`gh`); three — `untied-encodeable`, `dangling-wikilink-to-evicted-memory`, and `external-target-referent-stored` — are local-only and run even when `gh` is unavailable. Check 36, the how-to (`memory-corpus-drift-audit.md`), and the fixture self-test enumerate the *same* six classes by construction.

| Class | Definition | Detection (reproducible) |
|---|---|---|
| **deployed-but-not-evicted** | a memory's tied issue is CLOSED, corpus encoding present on main, but the memory file still exists | for each memory with a `#N` tie → `gh issue view N --json state` == CLOSED **AND** corpus grep of the encoded phrase succeeds **AND** memory file still present ⇒ flag |
| **dead-ref tie** | a memory's eviction-pointer cites an issue # that no longer resolves (re-versioning renumbered it away) | for each `#N` tie → `gh issue view N` returns **NOT_FOUND / resolution-failure** ⇒ flag. NEVER digit-match — only a resolution probe is load-bearing, per the issue-body-renumber-rot lesson |
| **untied-encodeable** | a memory the Q1 classifier marks K1-encodeable but carrying no issue tie and no corpus pointer | heuristic surface: memory whose body matches encodeable signatures (discipline/reference/methodology) with no `#N` and no corpus-path pointer ⇒ flag for operator routing (file an encode issue) |
| **dangling-wikilink-to-evicted-memory** | a surviving memory body links a `[[target]]` whose memory file no longer exists — left dangling by an EVICT that did not RE-POINT (the downstream gap) | for each `[[target]]` wikilink in any memory → the target resolves to `<target>.md` under the store; if that file is **absent** ⇒ flag (re-point to its corpus home or drop, per RE-POINT). **Local-only** (pure filesystem resolution, no `gh`); a warn-mode routing signal, never a FAIL — dangling links are permitted by convention |
| **ledger-pointer-to-closed-issue** | a `MEMORY.md` ledger ("Temporary enhancement pointers") row ties a `#N` that is CLOSED yet the memory was not absorbed/evicted — the partial-absorption residue (the upstream gap) | scan the ledger section; for each row's `#N` tie that **resolves** → `gh issue view N --json state` == CLOSED ⇒ flag (re-home to a live issue per Phase B-OPS5). **Disambiguated** from `deployed-but-not-evicted` by file-section: a `MEMORY.md` ledger row ⇒ this class; a standalone topic memory file ⇒ `deployed-but-not-evicted` |
| **external-target-referent-stored** | a surface of this install holds a resolved target-side referent as a value instead of reading it live, in breach of [§7.1](#external-target-scope) | **declaration-scoped, never content-scoped** — the discriminator is *whose fact it is*, which is semantic, so a scan for referent-shaped text must either miss the class or flood it. Two arms. **Arm 1 (memory store):** a file enters the population only by carrying a live-read declaration (the canonical `ADR-109` citation, else a closed fallback phrase set); the declaration's own parenthetical enumerates the referent **kinds**, and each kind is probed for a value-bearing occurrence on a line outside the declaration window ⇒ flag. Probing only the declared kinds is what keeps a correctly-reconciled note clean. A declaring file yielding no kind list is **not evaluated** and contributes to a summary tally, never a per-file finding. **Arm 2 (operator config):** any key in a `[trackers.<id>]` subtable outside the closed `{id, platform, identifier, scope}` schema ⇒ flag; the sanctioned `identifier` address does not flag because it is *on* the whitelist — a positive structural exemption, not a carve-out. **Local-only** (no `gh`), read-only on both roots |

The decision record for this boundary — the rejected memory-as-cache alternative, the Option-C trigger choice, and the encode-then-evict ordering guarantee — is [ADR-029](../ADRs/ADR-029-memory-corpus-ssot-boundary.md), generalized across all four memory types by [ADR-045](../ADRs/ADR-045-cross-surface-memory-contract.md); the RE-POINT step and close-time reconciliation added here extend the lifecycle both ADRs cite as its canonical home, leaving each ADR's decision record byte-unchanged.

### §7.1 External-target scope {#external-target-scope}

§7 above assigns SSOT between two surfaces that are both **this install's own** — the codified corpus and the auto-memory store. A third case exists and neither pole covers it: a fact about an **external target**, a repository or system the toolkit *operates upon* rather than *is*. The [§1 classifier](#tier-classifier) Q2 contextual-scope enumeration is closed over this install's own contexts and carries no scope value for a target, so a target fact routes by nearest fit — usually to K5 tacit, hence the memory store — where nothing refreshes it. This subsection closes that gap. It is a scope addition on a different axis from [§4.1](#host-binding-leakage-class)'s host-binding class, and it grants no surface any new permission to hold anything.

**The fused fact — the failure this closes.** A target fact is rarely atomic. It fuses an **operator-side practice** (the operator's own decision about how they work with that target — legitimately holdable) with a **target-side referent** (anything observable in the target: a name, an identifier, a state, a file's content). Homing the fused fact by its practice half carries the referent half along as an unowned payload that nothing ever reconciles against the target. Decomposition is therefore a **precondition of homing**, not an optional refinement.

**The decomposition rule (Q0).** Before homing any fact, ask whether it asserts something about a repository or system other than this install's own platform. If it does, split it:

| Half | What it is | Where it lives |
|---|---|---|
| **Target-side referent** | anything observable in the target | **nowhere.** Read live from the target at every use. |
| **Operator-side practice** | the operator's own decision about working with that target, stated *without* the referent | continue to [Q1](#tier-classifier) and home normally |

A fact that cannot be cleanly split is treated as target-side and read live.

**The target-SSOT rule.** **The target is the sole source of truth for its own facts.** No surface of this install may hold a resolved target-side value — not the corpus, not the auto-memory store, not operator config. The one permitted stored item is the target's **address**, which already exists as the `identifier` field of an `operator.toml [trackers.<id>]` destination. The address is irreducible (no read is possible without it), operator-declared rather than agent-inferred, and fails hard rather than plausibly when it goes stale.

**Reading a target-side referent — the requirement, and the operation that does not yet exist.** The read is subject to three requirements, stated host-agnostically because a host tool named as *the* way to perform a K1-governed operation is itself a [§4.1 host-binding leak](#host-binding-leakage-class):

1. **Fresh at every use.** The value is resolved at the moment it is used, against authoritative target state — never from a planning-time snapshot, a prior session, or a remembered answer.
2. **Through the selected host surface.** Which host is active is operator configuration, resolved from the `operator.toml [adapters]` selector table; capability text names the *operation*, never the host tool that satisfies it.
3. **Nothing retained.** The resolved value is used and discarded. Retaining it on any surface of this install re-creates the defect.

**No adapter interface specifies a referent-read operation today.** [`repo-host-adapter-versioning.md`](../standards/repo-host-adapter-versioning.md) is the one adapter interface the corpus specifies, and its operation set is scoped entirely to **version-claiming** — it returns versions and claim outcomes, never a referent. This rule therefore states a **requirement on the read**, not a delegation to an existing operation; an adapter operation that resolves a target-side referent is a named gap, owned by the adapter-interface work, and the requirements above are what that operation must satisfy when it ships. Until then the read is performed directly against the target under the same three requirements, and the absence is recorded here rather than papered over with a citation that would not resolve.

**Behaviour on divergence.** Because no value is stored, a target that has changed cannot produce a stale answer. It produces a **resolution failure**: the live read returns zero matches, or more than one, where the practice expects exactly one. That is a loud, halting signal. The agent surfaces it and asks the operator to restate the practice; it does not guess and does not fall back to a remembered value. **A session that cannot reach the target cannot resolve a target-side referent and halts — there is no offline cache by design, because a fallback cache would reintroduce the very defect this rule removes.**

**Where a target self-describes, that is the preferred source.** When the target documents its own conventions in-repo, reading that file *is* a target-side derivation and is preferred over any operator-side restatement — the convention and its subject then version together. This rule does not require a target to self-describe, and it creates no obligation on a repository the operator may not control.

**Bound — this scope does not weaken the corpus↔memory cut.** The scope applies **only** to a fact whose source of truth is a repository other than this install's platform. Content whose SSOT is the corpus (`core/`, `release/`) is **definitionally outside this scope** and remains governed by [the two-tier assignment](#two-tier-ssot) and [the no-shadow-SSOT invariant](#no-shadow-ssot) unchanged. External-target facts are never universal-for-this-platform, so they never become K1 and never enter the [encode-and-evict lifecycle](#encode-and-evict); that lifecycle, its VERIFY-CORPUS gate, and its ordering guarantee are untouched by this subsection. Nothing here authorises a memory-resident copy of codified knowledge.

**Drift class — `external-target-referent-stored`.** Any surface of this install holding a resolved target-side referent (a target's label name, milestone title, issue state, or file content recorded as a value rather than read live). **Detector shipped.** The class is the sixth of [the drift classes](#drift-classes) Check 36 emits — the deferred-detector posture this subsection originally recorded is discharged, and the class table's count moved five → six as ADR-109 § 8 pre-specified.

The predicate is **declaration-scoped**, and that is a design decision rather than an implementation detail: a resolved target-side referent is not lexically distinguishable from an operator-side practice statement, because the discriminator is *whose fact it is*. The detector therefore never decides whether something is a target fact — the decomposition [Q0](#external-target-scope) assigns to the author at write time is recorded whenever the author states the live-read obligation, and the check verifies that the declaration held. Two consequences follow and are stated rather than left to be discovered. **The sanctioned `[trackers.<id>].identifier` address cannot flag**, because it is on Arm 2's whitelist and the config file carries no live-read declaration at all. And **an undeclared cache is invisible** — the accepted price of a population that admits no false positives, since a detector that flags legitimate binding statements gets muted, which restores the undetected state with added noise.

**Posture: warn-mode-initial, escalating to a deploy-failing FAIL under enforce, identically to the existing five classes.** It is not advisory and it is not structurally incapable of gating: Check 36 routes every class through the same `memory-corpus-tie-drift` emitter, whose enforce branch increments the deploy-check issue count, and a plain `./deploy.sh --check` exits non-zero on that count. What is true today is that the shared default resolves to `warn`. The residual worth naming separately is **temporal**: the detector is invocation-triggered, not write-triggered, so a violation authored today stays undetected until the next `./deploy.sh --check`.

The decision record for this scope — the four rejected alternatives and the bound above — is [ADR-109](../ADRs/ADR-109-external-target-knowledge-scope.md), which **extends** ADR-045's cross-surface cut with a third scope and supersedes nothing.

---

## §Provenance

The [§5 Organizational-Altitude / Aggregation Axis](#altitude-axis) (and its companion edits in [`km-protocols.md §3`](km-protocols.md#lessons-learned-pipeline) capture-attribute + [`§9`](km-protocols.md#altitude-rollup) rollup) was added to give a *learning* a captured **altitude** attribute — *at what scope of work was this learning generated?* — orthogonal to the K1–K5 universality axis this doc already owned, plus a defined adjacent-altitude rollup relation. It extends, and does not restate, the codification axis: a learning now carries one K-tier value *and* one altitude value, independently.

The one design tension settled before authoring was a **vocabulary collision**: the altitude ladder (Unit → Task → Workstream → Project → Program → Portfolio → Organization) overlaps the live work-organization hierarchy ([`work-organization-mapping-framework.md` §1.2](work-organization-mapping-framework.md#per-level-purpose): Portfolio → Program → Project → Milestone/Workstream → Work Item). It was resolved by **alias, not rename** — the four middle rungs are verbatim aliases of the canonical levels, and the two outer rungs (Unit/Task below the frozen floor, Organization above the ceiling) are out-of-hierarchy *altitude-attribute values* that alias to existing dispositions (sub-Work-Item granularity for Unit/Task; the glossary's non-modeled `Initiative` precedent for Organization). No competing level-names enter the work-org framework; its hierarchy, the frozen `general_level` enum, and the frozen entity roster are untouched. The work-organization framework was therefore **not** edited by this axis (its alias home is this doc, self-contained).

This axis is the **capture-time learning** sibling of the **design-time work-placement** altitude circle in [`architecture-evaluative-lens.md` §1 triple-Venn](architecture-evaluative-lens.md#triple-venn) — distinct questions over the same canonical ladder, cross-referenced and not merged. Multi-person / people-involved elicitation is **out of scope** for this axis (the platform's single-operator operating model per [`km-protocols.md §4`](km-protocols.md#bus-factor) bus-factor = 1 is the operating model, not a defect); the axis is single-operator-coherent on its own and the people dimension is separate downstream work. Reversibility: **CHEAP** — additive section/attribute additions removable by section deletion.

The [§7 encode-and-evict lifecycle](#encode-and-evict) gained two symmetrical reference-integrity closures, addressing the mirror-image gaps each surfaced live during a real eviction. **Downstream:** a fifth lifecycle phase **RE-POINT** (after EVICT) reconciles surviving memories whose `[[wikilink]]`s pointed at the evicted file — re-pointing to the corpus home now owning the knowledge (re-point precedes drop). **Upstream:** a **close-time absorption reconciliation** (Stage-13 Phase B-OPS5) blocks a codification issue's close until every memory naming it in the ledger has been absorbed, closing the partial-absorption strand. Both are operator-authorized Phase B-OPS executor actions on the auto-memory store; the standing `deploy.sh` Check 36 backstop gained two warn-mode detector classes (`dangling-wikilink-to-evicted-memory`, `ledger-pointer-to-closed-issue`) that *detect* the omissions but never enact the fix — preserving the check's READ-ONLY-on-the-store invariant — covered by the fixture self-test `core/deploy/tests/test_check36_drift_classes.sh`. **ADR disposition:** the lifecycle change lands only in this canonical §7 (which both [ADR-029](../ADRs/ADR-029-memory-corpus-ssot-boundary.md) and [ADR-045](../ADRs/ADR-045-cross-surface-memory-contract.md) cite as the lifecycle's home) plus `deploy.sh`; both ADR decision records are left **byte-unchanged** — ADR-029 is superseded-and-immutable, and ADR-045 shipped as the operative cross-surface contract, so neither is rewritten in place (the extension reaches them by reference). Reversibility: **CHEAP** — additive doc + warn-mode bash + a new test; `git revert -m 1` restores the prior lifecycle.

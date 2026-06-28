---
title: Knowledge-Management Protocols
purpose: KM-artifact lifecycle state machine + two-key staleness-by-criticality model + the K5→K1 lessons-learned pipeline + bus-factor identification & mitigation + a computable doc-debt scoring model + in-flight capture rules for the PMO platform K1 corpus
type: reference
reversibility: CHEAP / Confidence HIGH
consumers: "corpus-curation.md (hard D-Struct bidirectional cross-ref: curation step 6 binds to #km-artifact-lifecycle; this doc cites #evidence-tier-vocabulary, never redefines it); QA Auditor KM scanning (cross-milestone forward-dep: consumes the §5 doc-debt model + §2 staleness thresholds); KM Governance (cross-reference at §11 Related References of km-governance-framework.md — this doc's §1 KM-Active/Deprecated/Superseded states are cited verbatim by km-governance-framework.md §4.3 retirement-artifact format; §2 staleness model is one of the 4 retirement-trigger sources composed in km-governance-framework.md §4.1)"
---
<!-- reference-durability: allow-link -->

# Knowledge-Management Protocols

This document is the platform's standard for **how managed-knowledge (KM) artifacts are governed over their lifetime** — the lifecycle states a KM artifact moves through, when it goes stale (by criticality, **never** a single uniform age), how tacit lessons are promoted into the codified corpus, how single-point-of-knowledge risk is identified and mitigated, how documentation debt is scored, and when knowledge must be captured *during* work rather than after. It composes with — and does **not** restate — [`knowledge-architecture.md`](knowledge-architecture.md) (the K1–K5 tiers, universality axis, and the Mutability column [§2](#staleness-by-criticality) consumes), [`corpus-curation.md`](corpus-curation.md) (the ET1–ET5 **evidence-tier vocabulary** this doc *cites and never redefines*), [`decision-discipline.md`](decision-discipline.md) (the observation→emergence→governance mechanism [§3](#lessons-learned-pipeline) generalizes), and [`standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) (the `<Object>-<State>` naming convention [§1](#km-artifact-lifecycle) adopts).

Scope is **K1 only** — the codified corpus per [`knowledge-architecture.md#k1-codified`](knowledge-architecture.md#k1-codified). A **KM artifact** is a managed instance of K1: an ADR, a promoted lessons-learned entry, a codified-practice doc, or a `core/` corpus doc (including this one). Contextual K2–K5 knowledge is **not** a KM artifact in this sense — it routes to its tier-specific placement home and is never governed by the lifecycle below.

---

## §1 KM-Artifact Lifecycle {#km-artifact-lifecycle}

The platform's de-facto ADR lifecycle today is informal: an `adr`-labelled GitHub Issue is OPEN (≈ "Proposed") then CLOSED-when-accepted (per [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) §6), with inline ADR drafts carrying `Status: PROPOSED`. Nygard's Architecture Decision Records — `[FRAMEWORK: ADR — Nygard 2011]`, **ET2** per [`corpus-curation.md`](corpus-curation.md) §3 source-taxonomy row D4 — adds *Deprecated* and *Superseded*. This section **codifies** that informal practice into a formal **KM-artifact lifecycle** general enough that [`corpus-curation.md`](corpus-curation.md) curation [§2](corpus-curation.md#curation-protocol) step 6 ("Retire / Supersede") binds to it. ADRs are the canonical *instance*, but the machine governs **any** managed-knowledge artifact — ADR, promoted lessons-learned entry, codified-practice doc, the reference corpus docs themselves — all **K1 Codified** per [`knowledge-architecture.md#k1-codified`](knowledge-architecture.md#k1-codified).

**States** (object-typed per the [`standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) §2 `<Object>-<State>` convention; object prefix `KM-` — see [§8](#lifecycle-states-canonical-registration)):

| Object-typed name | Bare | Semantic | ADR-instance alias (Nygard 2011) |
|---|---|---|---|
| `KM-Proposed` | Proposed | Authored, awaiting operator ratification | ADR "Proposed" |
| `KM-Active` | Active | Ratified / published; current authoritative knowledge | ADR "Accepted" |
| `KM-Deprecated` | Deprecated | No longer recommended; **no successor** authored | ADR "Deprecated" |
| `KM-Superseded` | Superseded | Replaced; `superseded_by:` pointer set (mirrors the [`schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) § Category 2 convention) | ADR "Superseded" |
| `KM-Rejected` | Rejected | Proposed then operator-declined; retained for why-not traceability | ADR "Rejected" |

**Transitions** (enumerated — durable structure per [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "prefer durable structures over static examples"):

| From | To | Trigger | Authority |
|---|---|---|---|
| `KM-Proposed` | `KM-Active` | Operator ratifies (Collective Review / Stage 9 Plan Review) | Operator |
| `KM-Proposed` | `KM-Rejected` | Operator declines | Operator |
| `KM-Active` | `KM-Deprecated` | Evidence overturned **or** context no longer applies; no replacement authored | Operator |
| `KM-Active` | `KM-Superseded` | A superseding artifact reaches `KM-Active`; this artifact's `superseded_by` is set | Operator |

**Terminal states:** `KM-Deprecated`, `KM-Superseded`, `KM-Rejected`.

**Binding to corpus-curation.md (single-home discipline per [`standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md)):** [`corpus-curation.md`](corpus-curation.md) curation step 6 states the retirement *trigger* (its RT-a..RT-d table — evidence overturned / framework deprecated by its body / superseded by a higher-ET practice / ET5 re-review lapsed); **this doc owns the resulting *state*** (`KM-Deprecated` / `KM-Superseded`). One concept, one home — zero duplicated state semantics. See [§7](#cross-reference-corpus-curation).

---

## §2 Staleness by Criticality {#staleness-by-criticality}

The load-bearing design: staleness criticality is a **two-key function**, **never a uniform age** — the originating work item's AC element 2 explicitly forbids a single age. **Primary key = K-tier Mutability**; **secondary key (K1 corpus artifacts only) = ET tier**.

- **Primary key (cited, not redefined):** an artifact's K-tier and its Mutability class are decided by the upstream deterministic classifier ([`knowledge-architecture.md#tier-classifier`](knowledge-architecture.md#tier-classifier)); the Mutability descriptor per tier is consumed verbatim from [`knowledge-architecture.md`](knowledge-architecture.md) §1. This doc maps each Mutability class to a concrete **base review-by age** — the tier/Mutability input is upstream; the age calibration is this doc's KM contribution.
- **Secondary key (cited, not redefined):** for K1 corpus artifacts the base age is refined by ET tier, cited from [`corpus-curation.md#evidence-tier-vocabulary`](corpus-curation.md#evidence-tier-vocabulary). This doc **does not redefine any ET tier, label, or threshold** — it consumes the corpus-curation review-intensity → cadence mapping.

| Artifact K-tier (Mutability) | Base staleness threshold (review-by) | ET refinement — K1 corpus only (cite [`corpus-curation.md#evidence-tier-vocabulary`](corpus-curation.md#evidence-tier-vocabulary)) |
|---|---|---|
| **K1** Codified — *Slow, version-anchored* | 36 mo | ET1 / ET2 → 36 mo (`stable`); ET3 → 12 mo (`evolving`); ET4 → 6 mo (`emerging`); ET5 → 3 mo **+ forced upgrade-or-retire** (per the corpus-curation ET5 row) |
| **K2** OOM — *Medium* | 12 mo | n/a (K2 ∉ corpus; the evidence gate is not applied per the corpus-curation orthogonality axiom) |
| **K3** Institutional — *Slow–medium* | 18 mo | n/a |
| **K4** Instance — *Fast* | per-project cadence (≤ sprint / phase-gate) | n/a |
| **K5** Tacit — *Emergent / fast* | continuous; event-driven (promotion or eviction), no fixed age | n/a |

**Computable rule:**

```
staleness_due(a) = published_date(a) + threshold( K_tier(a), ET_tier(a) )
```

Artifact `a` is **stale** iff `today > staleness_due(a)` **OR** an event trigger fires (the [`corpus-curation.md`](corpus-curation.md) step-6 RT-a..RT-d retirement triggers — these **compose**, they do not duplicate the date test). `K_tier(a)` is decidable via the knowledge-architecture Q1/Q2 classifier; `ET_tier(a)` via the corpus-curation admission rubric. No interpretation lives in the threshold itself — the only judgment is the upstream classifier and the upstream ET admission, both owned upstream.

---

## §3 Lessons-Learned Pipeline {#lessons-learned-pipeline}

The originating contract defines lessons-learned as the **K5→K1 promotion path**. The canonical *existing instance* of K5→K1 promotion is [`decision-discipline.md`](decision-discipline.md) § 4 (observation log → emergence rule → operator-confirmed `feedback_*.md` → governance). This section **generalizes the pipeline framing and cross-references [`decision-discipline.md`](decision-discipline.md) § 4.2 as the authoritative emergence-rule home — it does NOT re-specify the N=2 / 180-day rule** (single-home discipline per [`standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md)).

| Step | Action | K-tier | KM state | Gate / cross-ref |
|---|---|---|---|---|
| **1 Capture** | A lesson observed (retro, incident, operator correction, post-mortem) is recorded as a K5 artifact (the observation log per [`decision-discipline.md`](decision-discipline.md) § 4.1 schema, or a project lessons-learned log), **stamped with an `altitude` attribute** — the scope of work it was generated at, per the [`knowledge-architecture.md#altitude-alias`](knowledge-architecture.md#altitude-alias) ladder (Unit → Task → Workstream → Project → Program → Portfolio → Organization) | K5 | `KM-Proposed` | [`decision-discipline.md`](decision-discipline.md) § 4.1 classification threshold (all-3-hold test) |
| **2 Triage** | Assess class-potential; apply the **[`decision-discipline.md`](decision-discipline.md) § 4.2 emergence rule** as the promotion gate (cited, **not** redefined here) | K5 | `KM-Proposed` | [`decision-discipline.md`](decision-discipline.md) § 4.2 (the N=2 same-(domain,theme) / 180-day window lives there — single home) |
| **3 Integrate (K5→K1)** | Emergence fires **+** operator confirms → the artifact **re-classifies K5→K1** (the knowledge-architecture Q1 universality test now returns YES — the lesson is generalized to platform-wide true-and-useful); codified as `feedback_*.md` / governance / a reference rule | **K5 → K1** | `KM-Active` | [`knowledge-architecture.md#tier-classifier`](knowledge-architecture.md#tier-classifier) Q1; the promoted artifact inherits the K1 staleness cadence per [§2](#staleness-by-criticality) |

The **K5→K1 re-classification at the *Integrate* step is the load-bearing rule this doc owns**; the emergence *mechanism* (the N=2 / 180-day count, tagging, hygiene) stays in [`decision-discipline.md`](decision-discipline.md) § 4. Clean seam, zero duplication.

**Altitude as a capture-time attribute (cross-axis, orthogonal to the K5→K1 promotion above).** Each captured lesson stamps an **`altitude`** attribute at **Step 1** — *the scope of work it was generated at*, drawn from the [`knowledge-architecture.md#altitude-alias`](knowledge-architecture.md#altitude-alias) ladder (orthogonal to the K1–K5 universality axis: a lesson carries one K-tier *and* one altitude, independently). The attribute is **carried through** Triage (Step 2) and Integrate (Step 3) unchanged, so a promoted K1 lesson **retains the altitude it was born at**. Altitude is therefore a first-class capture field, not a post-hoc annotation; the K5→K1 re-classification rule above is unaffected (a lesson's altitude and its K-tier move on independent axes). The adjacent-altitude rollup relation over this attribute is defined in [§9 Adjacent-Altitude Rollup](#altitude-rollup).

---

## §4 Bus-Factor Rules {#bus-factor}

**Premise challenge (is this the right problem?):** the platform is **single-operator** (the workspace owner *is* the K2 Organizational Operating Model — surfaced as the [`knowledge-architecture.md`](knowledge-architecture.md) §4 leakage register leak **L4**, "single-operator HITL assumed"). Bus-factor = 1 is therefore **not a defect to remediate** — it is the operating model. The correct framing: bus-factor rules ensure tacit / institutional knowledge has a *codification path*, not that more people are added.

- **Identification (computable):** a KM artifact is **bus-factor-critical** iff **(a)** its K-tier ∈ {K5 Tacit, K3 Institutional} (it lives in a person, not codified) **AND (b)** no K1 externalization exists (no `promoted_to:` frontmatter field, no inbound K1 cross-reference). Both signals are mechanically checkable from frontmatter + `grep`.
- **Mitigation rule:** every bus-factor-critical artifact MUST carry **either** a scheduled K5→K1 externalization path ([§3](#lessons-learned-pipeline) pipeline) **or** an explicit operator-accepted residual-risk acknowledgment naming risk / owner / mitigation (per [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "No passive risk voice" and [`reversibility-protocol.md`](../specs/reversibility-protocol.md) tiering).
- **The structural control (the load-bearing insight):** the platform's bus-factor mitigation **IS** the *files-are-the-memory* + auto-memory + governance-corpus design — codified K1 survives operator absence. This doc states single-operator **bus-factor = 1 as a named accepted residual** (a K2-OOM property), with the codified corpus as the standing control — not an open risk to be escalated each cycle.

---

## §5 Doc-Debt Scoring {#doc-debt-model}

A per-artifact **deterministic** score that ranks remediation priority. Five inputs, **all mechanically derivable** — no human judgment in the score:

| Input | Range | Derivation (mechanical) |
|---|---|---|
| `S(a)` Staleness | {0,1,2,3} | 0 = within `staleness_due` ([§2](#staleness-by-criticality)); 1 = 0–25 % past; 2 = 25–100 % past; 3 = > 100 % past |
| `C(a)` Criticality | {1,2,3} | K1 doc with ≥ 3 inbound cross-refs = 3; K1 with 1–2 = 2; K3 / K5 or uncited = 1 (inbound count via `grep` / dependency-graph fan-out — same method `blast-radius.sh` uses for existing files) |
| `E(a)` Evidence-gap | {0,1,2} | K1 corpus only: ET1 / ET2 = 0; ET3 = 1; ET4 / ET5 = 2 (cite [`corpus-curation.md#evidence-tier-vocabulary`](corpus-curation.md#evidence-tier-vocabulary)). Non-K1 = 0 |
| `L(a)` Bus-factor | {0,1} | 1 if [§4](#bus-factor) marks the artifact bus-factor-critical; else 0 |
| `B(a)` Broken-refs | int ≥ 0 | count of unresolved outbound links via the existing `check-doc-links.py` primitive (per [`standards/doc-link-maintenance-protocol.md`](../standards/doc-link-maintenance-protocol.md) — reuse, do not reinvent) |

**Formula** (fixed-weight sum; weights are rubric-fixed, tunable, and documented in-doc):

```
doc_debt(a) = 3·S(a) + 2·C(a) + 2·E(a) + 2·L(a) + 1·min( B(a), 3 )
```

**Weight rationale:** staleness dominates (`w_S = 3` — the primary debt signal); criticality / evidence-gap / bus-factor amplify (`w = 2`); broken-refs contribute but are capped at 3 (`w_B = 1`) so one link-rotted doc cannot dominate the ranking. **Range: 0 (clean) … 24 (max:** `3·3 + 2·3 + 2·2 + 2·1 + 1·3`).

**Priority bands** (rubric — aligned to the existing QC4-05 operator-routing vocabulary in [`release-process.md`](../../release/governance/release-process.md) for cross-protocol coherence):

| `doc_debt(a)` | Band | Disposition (operator renders — mirrors QC4-05 A/B/C) |
|---|---|---|
| ≥ 16 | **P1** | Immediate-hotfix-class — bundle into the next-immediate release (QC4-05 route A) |
| 8 – 15 | **P2** | Carry-forward — bundle into the next-routine release (QC4-05 route B) |
| 1 – 7 | **P3** | Backlog / accept-as-residual with rationale (QC4-05 route C) |
| 0 | clean | No action |

Every input computes from frontmatter (`K-tier`, `ET-tier`, `published_date`) + git/`grep` inbound counts + the `check-doc-links.py` primitive. The model is shipped **specified** here; the QA Auditor KM scanning consumer (a cross-milestone forward-dependency, **not** an in-scope gate) consumes this formula directly and ships it **demonstrated**.

---

## §6 In-Flight Capture {#in-flight-capture}

Failure mode: tacit K5 knowledge generated mid-work is **lost** if capture defers to a post-hoc retro (the [§4](#bus-factor) bus-factor failure realized). Rule: **capture latency must be inversely proportional to reversibility cost + class-potential.**

| Trigger condition (during work) | Capture timing | Mechanism |
|---|---|---|
| A decision with reversibility **EXPENSIVE / IRREVERSIBLE** (per [`reversibility-protocol.md`](../specs/reversibility-protocol.md)) | **Capture-during (mandatory)** | ADR authored `KM-Proposed` in the same session — not deferred |
| An operator correction reveals class-potential (per [`decision-discipline.md`](decision-discipline.md) § 4.1 threshold) | **Capture-during (mandatory)** | observation logged in-session per the § 4.1 write procedure |
| A workaround for a non-obvious constraint is applied | **Capture-during (mandatory)** | recorded at point-of-use ([CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "comment only when the WHY is non-obvious" is the code-level instance; this generalizes it to KM artifacts) |
| Routine execution; a CHEAP reversible decision; the knowledge is already codified | Capture-after (acceptable) | a post-work retro suffices |

This composes with [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "Files are the memory. Sessions are ephemeral." and the write-first-speak-second guardrail: **uncaptured knowledge is knowledge lost at session end.** This doc owns the *timing decision table*; the mechanisms (ADR, observation log, point-of-use comment) keep their existing homes.

---

## §7 Cross-Reference: corpus-curation.md {#cross-reference-corpus-curation}

This section states the **D-Struct bidirectional cross-reference contract** between this doc and [`corpus-curation.md`](corpus-curation.md). The two docs partition cleanly along single-home discipline ([`standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md)):

| Concept | Canonical home | Cross-ref direction |
|---|---|---|
| Evidence-tier vocabulary (ET1–ET5 + the five evidence labels + thresholds + orthogonality axiom) | **[`corpus-curation.md`](corpus-curation.md)** [`#evidence-tier-vocabulary`](corpus-curation.md#evidence-tier-vocabulary) | this doc → corpus-curation.md ([§2](#staleness-by-criticality) & [§5](#doc-debt-model) **cite**; **never redefine**) |
| KM-artifact lifecycle (states, transitions, staleness-by-criticality) | **this doc** [`#km-artifact-lifecycle`](#km-artifact-lifecycle) ([§1](#km-artifact-lifecycle)) | corpus-curation.md → this doc (curation step 6 **binds**) |

**Inbound citation (the link this section carries):** [§2](#staleness-by-criticality) and [§5](#doc-debt-model) cite the evidence-tier vocabulary at [`corpus-curation.md#evidence-tier-vocabulary`](corpus-curation.md#evidence-tier-vocabulary). This doc consumes the ET semantics — a low-ET (ET4 / ET5) practice carries higher staleness criticality and a higher `E(a)` doc-debt input than an ET1 / ET2 one — and **never restates** any tier, label, or threshold.

**Atomic binding mechanic (the binding sequencing contract):** [`corpus-curation.md`](corpus-curation.md) shipped at an earlier phase with a reserved prose-only `{#cross-ref-km-protocols}` section carrying **no** live outbound link (the cross-ref sequence placed this doc's authoring phase last; a live forward link would have surfaced as a Check-14 broken-ref). This doc's authoring phase, in **one atomic commit**, (a) creates this doc with the inbound citation to `corpus-curation.md#evidence-tier-vocabulary` **and** (b) back-patches the single live outbound link into that reserved section. Both directions resolve at the same commit → **zero broken-link transient ever exists** → Check-14-clean → the cross-ref sequence is honoured.

---

## §8 Lifecycle-States-Canonical Registration {#lifecycle-states-canonical-registration}

The [§1](#km-artifact-lifecycle) KM-artifact lifecycle is a **genuinely new state machine**. Nygard's *Proposed / Accepted / Deprecated / Superseded / Rejected* is **not** the [`standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) §4.1 Domain-A *Baselined* set (`created / draft / active / superseded / archived`) nor the §4.2 Domain-B *Living* set — force-fitting would lose the well-known ADR vocabulary and create cross-machine semantic confusion. Per [`standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) §8 (Change Protocol) the surface splits cleanly into an in-scope consumer registration and a deferred governed registration.

**In this work item's PR (§8-exempt — §6.1-style consumer registration):** this doc adopts the §2 `<Object>-<State>` convention with the object prefix `KM-` and cross-references [`standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) for that convention. Per [`standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) §6.3 a consumer registers by carrying the cross-reference **in its own doc** (this section *is* that cross-reference); the §8 Change Protocol **exempts** consumer registrations ("consumer adds cross-reference in own release; PR diff carries both ends"). This doc is **internally authoritative** for KM state semantics — its own [`#km-artifact-lifecycle`](#km-artifact-lifecycle) anchor and frontmatter are the canonical home; `lifecycle-states-canonical.md` is cited for the *naming convention only*, not for KM state definitions.

**Deferred to a later milestone (§8-governed — NOT in this work item):** registering `KM-` as a new §4.4 scoped-out vocabulary in [`standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) and adding `Superseded` / `Deprecated` rows to its §5 Cross-Machine Collision Map is a §3/§4/§5 modification — it requires its **own Issue + plan + approval** per the §8 Change Protocol and [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) "No ungoverned changes". That governed follow-up is tracked under the KM-Governance layer — the governance layer *above* this work item. This section deliberately makes **no edit** to `lifecycle-states-canonical.md`.

The decision (new `KM-` machine, this doc authoritative, canonical-source registration deferred) is recorded in the corresponding ADR.

---

## §9 Adjacent-Altitude Rollup {#altitude-rollup}

[§3](#lessons-learned-pipeline) stamps each lesson with an **`altitude`** attribute (the [`knowledge-architecture.md#altitude-alias`](knowledge-architecture.md#altitude-alias) ladder: Unit → Task → Workstream → Project → Program → Portfolio → Organization). This section defines how lower-altitude learnings **aggregate, dedupe, and surface** at the next altitude up — the **`ROLLS_UP_TO`** relation.

**The relation.** `ROLLS_UP_TO` is a **directed learning-aggregation** relation over the altitude ladder: for adjacent altitudes **A (lower) → A+1 (higher)**, learnings captured at altitude A become candidates to surface at altitude A+1. **Adjacent-only** (A → A+1, never skip-level) keeps it a simple transitive ladder — an Organization-altitude surfacing is reached by successive adjacent rollups (Project → Program → Portfolio → Organization), not by a direct edge.

**The dedupe/surface gate (cited, NOT redefined — single-home discipline per [`standards/duplicate-source-discipline.md`](../standards/duplicate-source-discipline.md)).** Lower-altitude learnings surface at A+1 when the **[`decision-discipline.md`](decision-discipline.md) § 4.2 emergence rule** fires — **N = 2 same-(domain, theme) within the 180-day window** — applied **along the altitude axis** (count distinct altitude-A learnings sharing a (domain, theme); on N ≥ 2 surface a single deduped candidate at A+1 for operator confirmation). This is the **same** emergence rule [§3](#lessons-learned-pipeline) already cites for the K5→K1 universality promotion — reused here on the orthogonal altitude axis, **never re-specified**. The N=2 / 180-day parameters live in `decision-discipline.md § 4.2` (its single home); this section only states *which axis* the rule is applied along.

**Distinct from the work-org `BELONGS_TO` rollup edge.** The work-organization framework carries a `BELONGS_TO` rollup edge ([`work-organization-mapping-framework.md` §1.2 per-level-purpose](work-organization-mapping-framework.md#per-level-purpose) — the Work Item is its source) that aggregates **work status** up the *entity* hierarchy. `ROLLS_UP_TO` aggregates **learnings** up the *altitude-attribute* ladder. They are different relations over different things (work status vs learnings) and must not be conflated: `BELONGS_TO` rolls up *what is the state of the work?*; `ROLLS_UP_TO` rolls up *what did we learn, and at what scope does it now apply?*

**Properties.** The relation is **altitude-attribute-driven** (it reads the Step-1 `altitude` stamp; it adds **no** entity-graph node and changes **no** work-org level or `general_level` enum value), **additive**, and **CHEAP / reversible** (a documentation+attribute relation removable by section deletion, matching this doc's `reversibility: CHEAP / Confidence HIGH` frontmatter). Like the rest of this doc it is **K1-scoped** and single-operator-coherent: a solo operator still generates learnings at distinct altitudes (a Project-scope lesson vs a Portfolio-scope lesson), so the rollup is meaningful without multi-person elicitation (which is out of scope here — see [§4](#bus-factor) bus-factor = 1 operating model).

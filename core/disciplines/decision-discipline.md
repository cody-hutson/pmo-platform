---
title: Decision Discipline Framework
purpose: Shared discipline methodology for decision-class work (producing recommendations the operator acts on)
applies_to: hub-spoke-bridge.md, release-personas.md Stage 4, future decision-producing skills (release-planner, principal-engineer, etc.)
parallel_to: review-discipline-principles.md (review-class output discipline)
source: release retrospective + hub-behavior self-review 2026-04-23 (4 context-localization failure instances)
---
<!-- reference-durability: allow-link -->

# Decision Discipline Framework

Shared discipline methodology for decision-class work. When a consumer's primary function is producing a recommendation the operator will act on — architectural decisions, scope changes, PR-routing, D-class gates, severity/priority assessments — it inherits the rules below.

**Relationship to `review-discipline-principles.md`:** Parallel, not extension. Review discipline governs review-class output (findings, severity, root-cause chains — the reviewer audience). Decision discipline governs decision-class producer behavior (localization, opposing view, pattern check — the operator audience). Different artifact types, different consumer audiences, different failure modes. Cross-reference between the two; no inheritance.

---

## Section 1 — Scope and Applicability

### 1.1 What is decision-class work?

Decision-class work produces a recommendation that the operator is expected to act on. Examples:

- Architectural decisions (Layer assignment, file placement, schema changes)
- Scope-change proposals (add/defer/split issue)
- PR-routing / merge-model recommendations (direct-to-main, early-merge, bundled-vs-split)
- D-class decisions (Decision Gate items for operator judgment during Stage 4)
- Severity/priority assessment on findings
- Meta-correction / pattern-recognition recommendations
- Release plan amendment (post-Stage 4)
- Cascade approval scope judgment
- Iteration vs. escalate (Tier 1/2/3 feedback classification)
- Spoke output evaluation (concurs/diverges)

NOT decision-class work: routine orchestration (chip spawning, status reads, RELEASE_LOG appends), deterministic routing (Stage N+1 after N closes), pass-through relaying without evaluation.

### 1.2 Consumer scope

This framework applies to any decision-producing agent. The hub (via `hub-spoke-bridge.md`) is the current primary consumer. Future skills that replace hub functions — `release-planner`, `principal-engineer`, and others — consume the same framework directly. The Stage 4 Release Manager persona (via `release-personas.md`) consumes it for capacity/merge-split/stage-applicability decisions.

The hub is one consumer, not the owner. When `hub-spoke-bridge.md` is eventually deprecated as skills mature, this framework survives intact; only the consumer-binding sections in the deprecated file become archival.

### 1.3 Relationship to review-discipline-principles.md

| Dimension | `review-discipline-principles.md` | `decision-discipline.md` (this file) |
|---|---|---|
| Artifact type | Review findings (audit output) | Recommendations (decision briefings) |
| Consumer audience | Reviewers (QA, auditors) | Operators (decision-makers) |
| Failure mode guarded | Surface-level audit laziness | Context-localization failure at decision point |
| Enforcement | Anti-laziness rules + root-cause format | 3 mechanisms + triage table + ceremony guards |

Review-class skills cite `review-discipline-principles.md`. Decision-class consumers cite this file. A skill performing both functions cites both.

---

## Section 2 — Three Mechanisms

Three mechanisms interrogate a decision at the briefing point, each mapped to one of the three distinct cognitive failure modes surfaced (see § 8 Retrospective Validation). Each is embedded inline in the Decision Briefing when the decision class requires it (per § 3 Triage Table). Exempt decision classes OMIT the section entirely — "N/A" is not written; omission is the non-ceremony signal (see G2 in § 5).

### 2.1 Mechanism 1 — Localization Check

**Purpose:** Catch context-available-but-not-applied failures (Instances 1 + 4). The consumer reaches for a generic heuristic when platform-specific context should localize the decision.

**Template text (inline in Decision Briefing):**

```
## Localization Check (Mechanism 1)

**Decision-class check:** Does this decision class require a Localization
Check per the triage table?
  - [ ] YES — fill section below
  - [ ] NO — exempt; OMIT this section (do not fill with "N/A")

**Platform context that should localize this decision:**
  <Cite specific artifact, prior decision, operator guidance, or governance
  rule that should influence this recommendation. Name files/sections/sub-tasks/
  issue numbers. "Platform conventions" is not a citation — specify which.>

**Generic heuristic I am defaulting to (if any):**
  <State the cross-project rule/heuristic you'd apply in the absence of
  platform context. If none applies, state that explicitly: "No generic
  heuristic applies to this decision class.">

**What would invalidate the heuristic for this release:**
  <Concrete counter-evidence — not "if things change." Name the specific
  condition in THIS release that would overturn the heuristic.>

**Reconciliation:**
  <Does the localized context override the heuristic, reinforce it, or
  leave no conflict? State the final recommendation after reconciliation.>
```

**Decision-class triage rules:** see § 3.

**Load-bearing test criteria:** A Localization Check is load-bearing iff ALL hold:

1. **Cites specific evidence** — names a file, issue, sub-task, prior operator directive, or governance section. Not "platform conventions" / "release context."
2. **Articulates the heuristic honestly** — states the generic rule the consumer would apply, or explicitly says "no generic heuristic applies."
3. **Produces reconciliation** — the final recommendation reflects the localization; doesn't merely mention it and proceed with the generic heuristic anyway.

Reject as ceremony: "Platform context: CLAUDE.md guardrails. Heuristic: none. Reconciliation: proceed."

Accept as load-bearing: "Platform context: release-model directive (operator 2026-04-18) prohibits direct-to-main. Heuristic: 'small hotfix merges directly' (generic GitHub pattern). Reconciliation: heuristic does not apply; recommend PR-through-release-branch even for hotfix."

For recommendations derived from analysis artifacts > 24 hours old, see § 2.1.1 sub-mechanism (audit-snapshot reconciliation).

### 2.1.1 Sub-mechanism — Audit-Snapshot Reconciliation

**Specialization of:** Mechanism 1 (Localization Check, § 2.1). This is not a new mechanism — it is the localization-check pattern applied to one specific failure surface that emerged with sufficient frequency (N=5 in-session within a 22-day window) to warrant a named sub-procedure.

**Purpose:** Catch a class of localization failures where the "platform context" the consumer is reaching for is itself a point-in-time artifact (audit `recommendations.md`, gap analysis, prior-stage triage output, closed sub-task body). The artifact ages; current state diverges; recommendation lifted verbatim from the artifact mis-states what is real.

**When this fires:** Mechanism 1 applies normally per § 3 triage. M1 fires this sub-mechanism when the load-bearing platform context for the decision is an analysis artifact older than ~24 hours, OR an artifact authored before the most recent merge to `main` for the affected file(s) — whichever is older. Examples: a Stage 4 release-plan File Change Matrix authored 3 days before Stage 6 spoke output; a closed sub-task body cited as "the spec" without re-reading the latest sibling comments; a Stage 5 spec citing dependency state that has since transitioned.

**Why this matters:** Analysis artifacts are forward-looking by convention but accumulate shipped status invisibly. Without a re-verification step at the recommendation surface, the consumer treats the artifact's enumerated items as if all still pending — and the operator pays the cost of re-reading the audit they already actioned. In this workspace, audit recommendations are often closed within hours of authoring; consumer trust erodes quickly when shipped work is re-recommended.

**Verification primitives (run before surfacing any audit-derived recommendation):**

| # | Primitive | Surfaces | When to use |
|---|---|---|---|
| 1 | `gh issue list --search "<symbol> in:title,body" --state all --limit 5000` | Existing OPEN / CLOSED Issues touching the same surface | Always; primary signal for "is this work already tracked or shipped?" |
| 2 | `git log --follow <cited-file> --since="<artifact-date>"` | Commits to the cited file since the artifact was authored | When recommendation names a specific file or section |
| 3 | `grep -nE "<cited-symbol>" <cited-file>` | Whether the specific symbol / section / phrase the recommendation proposes still names a gap (or already exists) | When recommendation proposes adding a named symbol, heading, or row |

Apply at least primitives 1 + 2 for every audit-derived recommendation. Apply primitive 3 when the recommendation names a specific symbol or section to add. Negative result on all three (no Issue match, no post-artifact commits, no grep hit) is the load-bearing case for proceeding with the recommendation; positive result on any primitive surfaces "potentially-shipped" — surface evidence to operator BEFORE recommending.

**Evidence trailer format:** Recommendations that cite audit-snapshot reconciliation MUST end with one or more `[VERIFIED <YYYY-MM-DD>: <command> → <result>]` trailers naming the specific primitives executed. Format is structural, not optional — auditors scan for this trailer to confirm verification ran.

```
**Recommendation:** Add `### Foo` section to `bar.md` per audit-2026-05-10.md.
[VERIFIED 2026-05-16: gh issue list --search '"### Foo" in:body' --state all → 0 hits]
[VERIFIED 2026-05-16: git log --follow core/bar.md --since="2026-05-10" → 0 commits]
[VERIFIED 2026-05-16: grep -n "^### Foo" core/bar.md → 0 hits]
```

**Load-bearing example (revised recommendation after verification):** "Audit recommendations.md §B3 proposes adding chip-prompt parser-clean discipline to hub-spoke-bridge.md. [VERIFIED 2026-05-15: gh issue list --search '"chip-prompt parser-clean" in:body' --state closed → a matching Issue closed 2026-05-09 with a PR landing the same content.] Revised: surface to operator as 'B3 may already be shipped; please confirm before re-recommending'."

**Reject as ceremony:** "Verified per audit-snapshot reconciliation. Recommendation: implement B3." No trailers, no evidence of primitives executed, no enumeration of grep / git log / gh issue list results. Bare "verified" claim with no observable verification is the ceremony pattern G1 § 5 catches.

**Empirical basis (N=5 in-session drift, 2026-04-25 through 2026-05-16):**

| # | Date | Drift | Mechanism |
|---|---|---|---|
| 1 | 2026-04-25 | Stage 4 release-plan File Change Matrix cited `pipeline-stages.md` (pre-shard path) without re-checking that the file had been split into per-stage shards | Cited audit artifact (release plan) older than the file-restructure commit |
| 2 | 2026-05-01 | Recommendation surfaced re-implementing a closed-via-PR audit B3 item ("add parser-clean discipline") without searching closed Issues | Cited audit `recommendations.md` without primitive 1 search |
| 3 | 2026-05-09 | Sub-task body referenced a CLOSED dependency as if dependency-met without checking that the linked artifact had since been restructured | Cited prior-stage triage output without primitive 2 since-date check |
| 4 | 2026-05-15 | Stage 4 plan cited bundled-issue title summaries that had drifted from the live issue bodies | Cited operator-summary as canonical content without primitive 3 grep-against-live-body |
| 5 | 2026-05-16 | Stage 6 sub-task body templates the hub authored embedded per-issue PR title summaries that drifted from the Stage 4 plan's ONE-PR specification | Cited Stage 4 plan content via summary embedded in chip scaffolding rather than directing reader to read canonical Stage 4 plan section directly |

**Drift 5:** 2026-05-16 — Stage 6 sub-task body templates the hub authored embedded per-issue PR title summaries that drifted from the Stage 4 plan's ONE-PR specification. Same class of failure: hub summarized the Stage 4 plan into chip scaffolding rather than directing the reader to read the canonical Stage 4 plan section directly. F-1 applied at commit 2c6293f. Validates this sub-mechanism's codification.

**Cousin patterns:**

- `release/references/standards/triage-design-rereview.md` D2 (Stage 4 Phase A0 entry currency check) — the same discipline applied at a different surface (stage entry rather than recommendation rendering). D2 fires at Stage 4 / Stage 5 entry; § 2.1.1 fires at recommendation / chip-launch surface.
- `release/references/how-to/hub-spoke-bridge.md` Procedure 3 §Worktree discipline — adjacent operational discipline for the same hub class (chip-construction surface). The sibling sub-task codifies the chip-prompt-construction-surface variant.
- [`reconcile-dont-annotate.md`](reconcile-dont-annotate.md) — the **edit-time twin** of this sub-mechanism. §2.1.1 governs stale-artifact *recommendations* (verify before you recommend from an aging artifact); reconcile-don't-annotate governs the stale-artifact *edit* (when you are already touching the artifact, reconcile it to current state rather than posting a correction comment and deferring). Same stale-artifact family, opposite action surface (recommend vs. edit); cross-referenced, not merged.

**Consumer-agnostic wording:** This sub-mechanism applies to ANY consumer of `decision-discipline.md` — hub today; `release-planner` / `principal-engineer` skills after skill-replacement (per § 7.3 future consumers). The primitives are tool-agnostic (replace `gh` / `git` / `grep` with the consumer's available verification surface); the discipline survives consumer transition unchanged.

**Cutover discipline:** Applies to all releases going forward.

### 2.1.2 Sub-mechanism — Canonical-Form-Conformance Check

**Specialization of:** Mechanism 1 (Localization Check, § 2.1). Not a new mechanism — it is the localization-check pattern applied to one specific dimension: whether a decision-class output that produces (or directs the production of) a discipline-framed artifact conforms to that artifact's canonical form, or documents a deliberate partial-form conformance with rationale.

**Purpose:** Catch the canonical-form-application degradation class — canon substance applied while the canonical artifact form is partial-or-absent. When a decision produces an artifact that a registered frame governs (an ADR, a retro, a methodology design, an acceptance-test design, an exception plan), the Localization Check must additionally localize on the frame's canonical form, not only on platform context.

**When this fires:** Mechanism 1 applies normally per § 3 triage. M1 fires this sub-mechanism when the decision produces, or directs Engineering to produce, an artifact governed by one of the frames in the canonical-form registry (the registry of frames and their template owners is maintained in `canonical-form-discipline.md` § 4).

**Conformance check (run alongside the § 2.1 Reconciliation):**
  - Identify the frame the produced artifact belongs to (per the canonical-form registry).
  - Localize on its canonical form: does the output produce the canonical-form artifact, OR document partial-form conformance with explicit rationale per `canonical-form-discipline.md` § 3.3?
  - A decision that produces a frame-governed artifact in neither canonical form NOR documented-partial form is incomplete — surface it, do not proceed on the generic heuristic.

**Load-bearing test:** the check is load-bearing iff it names the specific frame, states whether canonical form was produced or partial-conformance was documented-with-rationale, and (if partial) cites the over-formalization rationale. A bare "conforms to canonical form" with no frame named and no produce-vs-document verdict is ceremony (rejected per § 5 G1).

**Consumer-agnostic wording:** applies to any consumer of this framework (hub today; successor skills per § 7.3). The registry it consults lives in `canonical-form-discipline.md`; this sub-mechanism is the decision-side enforcement hook.

### 2.2 Mechanism 2 — Opposing View

**Purpose:** Catch Type A weak-reasoning failures (Instance 2 doc→code naming). The consumer reaches for presentation-scaffolding reasoning instead of articulating real substantive reasoning.

**Template text (inline in Decision Briefing):**

```
## Opposing View (Mechanism 2)

**Strongest reason my recommendation might be wrong:**
  <A specific, testable counter-argument. Name evidence that would
  support the opposing view. Must be concrete — not "something could
  be missed" or "I could be biased.">

**What evidence would confirm the opposing view:**
  <Observable signal that, if present, would overturn the recommendation.
  Must be dismissible-with-evidence, adopted, or escalated to operator.>

**Why I still recommend what I'm recommending (OR change to opposing view):**
  <Cite the evidence that overrides the opposing view in this case. If
  no such evidence exists → CHANGE the recommendation to the opposing
  view. "I don't know which is right" is a valid answer — flag as
  operator decision.>
```

**Concreteness requirements:** An Opposing View is concrete iff ALL hold:

1. **Testable** — validatable/invalidatable by a specific file read, eval execution, or evidence check
2. **Specific** — names the exact mechanism by which the recommendation could fail
3. **Resolvable** — opposing view either adopted (recommendation changes), dismissed with cited evidence, or escalated to operator as "I don't know"

**Non-concrete opposing views (REJECT):**

- "This might not be the best approach" — no mechanism
- "There could be unintended consequences" — no specific consequence
- "Maybe we should reconsider" — not testable
- "I could be wrong" — reviewer-bias deflection, not adversarial insight

**Ceremony-signal detection:**

Across a release with ≥3 Decision Briefings, if every Opposing View is dismissed, that is a theater signal. Two measurements at release close (per § 6):

1. **Adoption counter:** count of Opposing Views that CHANGED the recommendation. Target: >0 per release with ≥3 briefings. Zero = calibration signal.
2. **Escalation counter:** count of Opposing Views escalated to operator as "I don't know." Target: >0 across multi-release window.

If both counters stay at zero across 2+ releases, the consumer self-flags: "possible adversarial-insight decay, recommend recalibration."

### 2.3 Mechanism 3 — Pattern Cache Scan

**Purpose:** Catch Type D narrow-meta-response failures (Instance 3 no-audit-after-M2). When the operator surfaces a class pattern, the consumer must generalize. The pattern cache is the mechanism — backed by an observation log and emergence rule (§ 4) so that **a single instance is data, not pattern**.

**Template text (inline in Decision Briefing):**

```
## Pattern Cache Scan (Mechanism 3)

**Domain of this decision:** [release-ops / project-ops / general-agent-behavior]

**Confirmed-pattern source:**
  The confirmed-pattern store — domain-scoped patterns (one per
  `(domain, theme)`) plus cross-domain-elevated patterns.

**Scan procedure executed:**
  <Enumerate confirmed patterns checked — filtered by this decision's domain +
  cross-domain-general. "<release-ops / context-localization-failure>
  — checked; <general-agent-behavior / scope-discipline> — checked."
  Enumerate; don't claim.>

**Applicable confirmed patterns (and their application):**
  <Per applicable: <entry-name> → <how it applies here> → <what it implies
  for the recommendation>. If none: "None applicable" explicitly.>

**Emergence candidates (awaiting confirmation):**
  <If observation log has ≥2 same-(domain, theme) within 180-day window,
  list candidates. If current decision would inform one, flag that operator
  confirmation would promote it. "No candidates applicable" is a valid
  load-bearing answer.>

**Cross-domain same-theme observations (awaiting operator elevation):**
  <If same theme tagged across multiple domains, flag here. These do NOT
  auto-emerge — they surface for operator judgment only.>

**New observation to log (if operator correction occurred):**
  <If session included operator correction revealing class-potential, draft
  observation now: domain, theme, date, context, correction. If no correction,
  state "No new observation.">
```

**Scan procedure — at session start (one-time per session):**

1. Read the observation log; parse entries.
2. Drop entries with date > 180 days old from emergence count (archive only).
3. Group live entries by (`domain`, `theme`) tuple; flag groups with count ≥ 2 as candidate patterns.
4. Flag same-theme cross-domain observations as cross-domain candidates (do NOT auto-emerge — see § 4.4).
5. Report candidates + cross-domain flags in session startup briefing.

**Scan procedure — per Decision Briefing (when M3 applies per triage):**

1. Identify domain of current decision.
2. Read the confirmed-pattern store — domain-scoped patterns for the current domain + cross-domain-elevated patterns.
3. Enumerate in Scan section; evaluate applicability per entry.
4. Cite applicable confirmed patterns; implications for recommendation.
5. Include session-start emergence candidates if applicable to current decision.

**Write procedure — log an observation:** see § 4.1.
**Write procedure — promote candidate to permanent pattern:** see § 4.5.

---

## Section 3 — Decision-Class Triage Table

Full taxonomy of which decision classes require which mechanisms. Consumer-agnostic ("hub" → "consumer" wording).

| Decision class | M1 Localization | M2 Opposing View | M3 Cache Scan | Rationale |
|---|---|---|---|---|
| Architectural decisions (Layer assignment, file placement, schema changes) | ✅ | ✅ | ✅ | Highest blast radius; platform architecture localizes |
| Scope-change proposals (add/defer/split issue) | ✅ | ✅ | ✅ | Operator bandwidth + downstream workload load-bearing (Instance 4) |
| PR-routing / merge-model recommendations (direct-to-main, early-merge, bundled-vs-split) | ✅ | ✅ | ✅ | Release model is platform-specific (Instance 1) |
| D-class decisions (Decision Gate items for operator judgment) | ✅ | ✅ | ✅ | Full treatment by definition |
| Severity/priority assessment on findings | ✅ | ✅ | ✅ | Review discipline Rule 7 |
| Meta-correction / pattern-recognition recommendations | ✅ | ✅ | ✅ | Instance 3 mechanism |
| Release plan amendment (post-Stage 4) | ✅ | ✅ | ✅ | Re-opens prior operator approval |
| Cascade approval scope judgment | ✅ | ✅ | ✅ | Governance boundary |
| Iteration vs escalate (Tier 1/2/3 feedback) | ✅ | ✅ | ⚠️ optional | Protocol-driven but judgment in tier assignment |
| Downstream-output evaluation (consumer concurs/diverges on spoke or skill output) | ✅ | ✅ | ⚠️ optional | Consumer's value-add, sometimes routine |
| **Exempt: Chip spawning** from existing template | ❌ | ❌ | ❌ | Deterministic routing |
| **Exempt: Status reads** (`gh issue view`, RELEASE_LOG append) | ❌ | ❌ | ❌ | Not a decision |
| **Exempt: Stage-gate applicability** from pre-approved matrix | ❌ | ❌ | ❌ | Plan-driven application |
| **Exempt: Deterministic routing** (Stage N+1 after N closes) | ❌ | ❌ | ❌ | Procedure-driven |
| **Exempt: Downstream-output pass-through** (consumer reports without adding evaluation) | ❌ | ❌ | ❌ | Pass-through; separate evaluation is the subject |

**Rule of thumb:** If the consumer is **recommending to operator** AND operator is **expected to act on it**, all 3 mechanisms apply (or are explicitly exempt per this table, not per consumer whim). If the consumer is **relaying information** or **executing a determined procedure**, mechanisms are exempt.

---

## Section 4 — Pattern Cache Infrastructure

The pattern cache is the persistent memory layer that makes Mechanism 3 load-bearing. Implemented on the user auto-memory system (per CLAUDE.md § auto memory) — above the Layer 1 / Layer 2 boundary, cross-session, cross-work-area, zero new governance-change cost. Two-layer model:

| Layer | Surface | Role | Trigger |
|---|---|---|---|
| **Observation** | Observation log — single append-only file in the user auto-memory store, one index entry | Append-only log of operator-correction observations with domain + theme tags; not a cache, not a pattern | Operator correction identifies class-potential during any session |
| **Confirmed pattern** | Confirmed-pattern entry — one per `(domain, theme)` (domain-scoped) or per cross-domain-elevated theme | Permanent behavioral-rule entry; indexed in the auto-memory store | Emergence rule fires (§ 4.2) + operator confirms (§ 4.5) |

**Engineering does NOT pre-populate these runtime files.** The framework documents the naming conventions, schemas, and procedures; the live consumer writes observations and promotes patterns organically as operator corrections occur.

**Relationship to the pipeline-event-log (additive audit-trail surface):** The unified pipeline-event-log capture surface (schema at [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md)) MAY REFERENCE observation entries via a `cited: <date>/<domain>/<theme>` pointer in its `payload` field — but NEVER duplicates observation content into the pipeline-event-log, and NEVER auto-writes to the observation log. The reference-only contract preserves § 4.1 D-5 (operator-write-only on the observation log) and the Layer 2 boundary (the observation log lives in the user auto-memory store, not under `pmo-platform/`). Pipeline-event-log is one consumer of the observation log by reference; it is not a parallel surface or a retrofit target.

**See also (downstream efficacy consumer):** [`practice-efficacy-framework.md § 3 SIG-G3`](../standards/practice-efficacy-framework.md) consumes the observation log and promoted-feedback memories as the SIG-G3 (Operator-correction frequency) measurement surface — observation-count over a 180-day rolling window feeds the T-OP trigger and contributes to the practice-efficacy ledger.

### 4.1 Observation Log

A single append-only file in the user auto-memory store, with one index entry. Body contains a `## Pending Observations` heading with per-observation blocks. Single-file convention prevents index pollution (observations may reach hundreds over time; they are working data, not permanent memories).

**Observation entry schema:**

```yaml
---
name: Observation — <theme> — <YYYY-MM-DD>
description: <one-line summary of correction>
type: feedback      # closest fit in 4 sanctioned auto-memory types
---
- domain: release-ops | project-ops | general-agent-behavior
- theme: <kebab-case> (e.g., context-localization-failure)
- date: YYYY-MM-DD
- context: <#issue / release / sub-task / session ref>
- correction: <one-sentence summary of what operator said>
```

**Write procedure — log an observation:**

1. Operator correction occurs; consumer classifies as class-potential (per classification threshold below).
2. Consumer drafts observation block; confirms the theme tag with operator ("Logging under theme `<theme>` — correct?").
3. On operator approval: append block to the observation log's `## Pending Observations` section. **Per-write operator approval is required (D-5).**
4. Immediately check: does this observation complete an emergence threshold?
   - If YES (new N=2 same-(domain, theme) within 180 days): surface candidate pattern to operator; offer promotion.
   - If NO: log and proceed.

**Classification threshold — log observation IFF ALL hold:**

1. Operator correction identifies a **class of mistake** (would apply to ≥2 future decisions)
2. The correction reveals **load-bearing context** not already in governance files or CLAUDE.md
3. The pattern is **observable** — there is a detectable signal the consumer can check against

**Do NOT log observation IF ANY hold:**

1. Single-instance fix (wrong date, fabricated metric, typo) — re-check evidence, not pattern learning
2. Already documented in CLAUDE.md, OPERATIONS.md, or `core/rules/` — duplicates existing rule
3. Ephemeral to current release (scope state, in-progress items) — use SESSION_STATE.md (operations-state; consumer reads only)

### 4.1.1 Operational Cadence

§ 4.1 defines the observation log schema and the per-write protocol; the operational cadence that scans the log for emergence is the **Pattern Review Cadence Protocol** in `core/governance/OPERATIONS.md` § Pattern Review Cadence Protocol. The cadence fires event-bound (≥N=2 observations since last review — matching § 4.2 emergence threshold) or on 60-day fallback. The responsible execution surface is the `release-planner` skill Mode D (DRAFT phase — read-only) handing off to `release-executor` skill Mode G (EXECUTE phase — write-authorized) on operator PROMOTE verdict. The two-layer composition is intentional: § 4.1 / § 4.2 own the *schema and threshold*; the cadence protocol owns the *operational fire-rate and execution surface*.

### 4.2 Emergence Rule

**Parameters:**

- **Threshold:** N = 2 (same (domain, theme) observations)
- **Staleness window:** 180 days from observation date

**Within-(domain, theme) emergence (auto-candidate):** any group with count ≥ 2 within 180 days → surface as candidate pattern. Operator confirmation required to promote (§ 4.5).

**Rationale for N = 2:**

- Validated against the retrospective (see § 8): under broad theme tagging, Instances 1 + 4 cluster under `context-localization-failure` (N = 2 auto-emergence candidate); Instances 2 and 3 remain singleton observations awaiting further evidence. N = 3 would delay pattern recognition and under-report the dominant pattern.
- Narrow (instance-specific) tagging would produce 4 singletons; zero emergence; loses signal. Broad tagging preserves signal while respecting emergence discipline.
- Parameters are tunable. If operational experience shows N = 2 over-clusters (false positives on broad themes), tighten to N = 3 or adopt narrower tag granularity. Update this section with rationale.

**Rationale for 180-day staleness:**

- Accommodates slow-release cadences (v10.x releases may span weeks; retrospectives may surface patterns months after the originating incident).
- Tighter windows (90 days) would drop genuine cross-release patterns. Against the retrospective (all 4 instances within ~30 days), 90 and 180 behave identically.
- Tunable. Observations past the staleness window remain archived (for human reference) but are excluded from emergence counts.

### 4.3 Domain and Theme Tagging

**Three domains:**

| Domain | Scope | Example correction |
|---|---|---|
| `release-ops` | Release orchestration (hub/spoke, planning, solutioning, engineering, testing) | "Don't merge release-scope PRs direct to main" |
| `project-ops` | Project operations (PMO workflows, status updates, tracker updates, agenda management) | "Don't generalize project dates — cite specific verified ones" |
| `general-agent-behavior` | Cross-cutting agent conduct (tone, terseness, commit style, question-asking discipline) | "Stop summarizing what you just did at the end of every response" |

**Theme tagging guidance:**

- Use broad mechanism-level tags (e.g., `context-localization-failure`) as the default. Narrow per-instance tags (e.g., `hotfix-release-model-bypass`) prevent emergence under small N — rejected per § 8 validation.
- If a pattern promotes and later proves too broad in practice, operator may demote to a narrower sub-pattern post-promotion.

### 4.4 Cross-Domain Operator-Elevation Gate

Same-theme observations across multiple domains flag a **cross-domain candidate** but do NOT auto-emerge. Rationale: same-theme matches across domains have superficial-match false-positive risk. Example: "scope discipline" in `release-ops` (defer-vs-include issue) vs. "scope discipline" in `project-ops` (meeting agenda length) are thematically similar but cognitively distinct failures; auto-clustering mis-caches.

**Gate procedure:**

1. Session-start scan identifies same theme appearing in ≥2 domains.
2. Cross-domain candidate surfaced to operator in session-start briefing, NOT per-decision (keeps noise low).
3. Operator judges: (a) elevate → draft a cross-domain-elevated confirmed pattern for the theme and promote per § 4.5; (b) leave as domain-local observations (no elevation); (c) demote broader theme to narrower per-domain sub-themes.

Cross-domain elevation is rare in practice. The retrospective (all 4 instances in `release-ops`) produced zero cross-domain candidates. Operator can batch cross-domain review at release close.

### 4.5 Confirmed Pattern Format

When emergence fires (within-domain N = 2) OR operator elevates cross-domain, the candidate promotes to a permanent entry.

**Entry identity:**

- Within-domain: keyed by `(domain, theme)` — e.g., domain `release-ops`, theme `context-localization-failure`.
- Cross-domain elevated: keyed by the elevated theme under the cross-domain (`general-agent-behavior`) scope.

**Promotion procedure:**

1. Emergence fires OR operator elevates cross-domain candidate.
2. Consumer drafts candidate entry with frontmatter (`name`, `description`, `type: feedback`).
3. Body: rule + `**Why:**` (reason; includes prior incidents) + `**How to apply:**` (when/where it kicks in) + `**Source observations:**` (references the 2+ observations that caused emergence).
4. **Operator confirms** → write the entry + add an index line. **Per-write operator approval is required (D-5).**
5. Source observations move from the observation log's `## Pending Observations` section to the new entry's `## Source Observations` section (or remain in the observation log with a `promoted_to:` field pointing to the new entry — implementer's choice; document the decision once in the consumer's operational notes).

### 4.6 Cache Hygiene

| Aspect | Rule |
|---|---|
| Staleness (observations) | 180-day window for emergence count; older entries retained as archive, excluded from count |
| Eviction (confirmed patterns) | Pattern never cited in scans across 3+ releases → evict; pattern contradicted by current governance → evict; pattern subsumed into new governance rule → evict (promote to governance) |
| Consolidation | At release close (consumer's Release Close procedure; e.g., hub Procedure 7), operator optionally invokes `anthropic-skills:consolidate-memory`; observation log reviewed for stale entries |
| Upper bound | ~10–12 active confirmed patterns. Exceeding → consolidate, demote, or promote meta-pattern to governance rule (at which point the cache entry is evicted). Observations unbounded but staleness-capped |
| Domain balance signal | If one domain dominates promotions, signal that framework is under-applied in other domains (monitoring, not rule) |

---

## Section 5 — Ceremony-Management Guards

Seven guards prevent the 3 mechanisms from becoming formatting theater. All 7 apply unchanged regardless of domain or context scope.

**G1 — Load-bearing test (applies to all 3 mechanisms)**

Every filled section must cite specific evidence. Sections listing abstractions without cited artifacts/files/rules are rejected as ceremony.

**G2 — Decision-class triage (prevents uniform application)**

Every Decision Briefing declares applicable mechanisms per the § 3 triage table. Sections NOT required for the decision class are **omitted entirely**, not filled with "N/A" or "exempt." Omission IS the non-ceremony signal. Uniform application is the exact failure the triage prevents.

**G3 — Evidence-citation requirement (extends G1)**

Citations must be resolvable: file paths, issue/sub-task numbers (`#N`), sub-task comments (`#N comment`), quoted operator directives with session context, or governance sections. Vague citations ("platform context", "release history") fail G1/G3.

**G4 — "I don't know" as honest answer**

When the consumer cannot resolve Localization or Opposing View cleanly, the honest answer is to escalate: "Localization: I see conflicting guidance in [A] vs [B]. I do not know which takes precedence. Flagging for operator." Fake certainty is worse than articulated uncertainty. G4 permits honest uncertainty — it IS load-bearing because it surfaces operator-decision need.

**G5 — Operator feedback loop / theater signal (metrics at release close)**

Four metrics reported at release close (per § 6):

1. **M2 adoption rate** — count of Opposing Views that CHANGED the recommendation. Target: >0 per release with ≥3 Decision Briefings.
2. **M3 applicability rate** — count of Pattern Cache Scans that cited applicable patterns. Target: >0 per release.
3. **Observations-logged count** (Iter 2 extension) — count of observations logged per release. Decaying to zero over multiple releases = signal of under-capture (patterns going unlogged because the class-potential threshold is being applied too narrowly).
4. **Emergence-confirmation rate** (Iter 2 extension) — count of candidate patterns surfaced AND promoted per release. Zero across 2+ releases with ≥10 observations logged = signal of over-tagging (patterns clustering not matching operator judgment).

Zero-rate releases: consumer self-flags possible decay; operator may flag theater. These are tripwires, not thresholds.

**G6 — No recursion (mechanisms don't apply to themselves)**

Mechanisms apply to the consumer's recommendations, not to its evaluation of mechanisms themselves. "I need to run M1 on whether to apply M1" is recursive ceremony. The § 3 triage table resolves applicability deterministically.

**G7 — Load-bearing trumps completeness**

A Decision Briefing with ONE load-bearing mechanism section (e.g., M1 cited a specific file; M2/M3 honestly reported "none applicable") is STRONGER than a briefing with THREE filled-but-hollow sections. Completeness for its own sake is the exact failure the mechanisms prevent.

---

## Section 6 — Metrics (Theater Detection)

Four metrics reported at the release-close procedure (e.g., `hub-spoke-bridge.md` Procedure 7 step 3a). Operator reviews for theater signals.

| # | Metric | Compute | Interpretation |
|---|---|---|---|
| 1 | **M2 Opposing-View adoption rate** | Count of Opposing Views that CHANGED the recommendation across all Decision Briefings this release | Target: >0 per release with ≥3 briefings. Zero across 2+ releases = adversarial-insight decay; recalibrate |
| 2 | **M3 Pattern Cache Scan applicability rate** | Count of Pattern Cache Scans that cited applicable patterns (confirmed or emerged-candidate) | Target: >0 per release. Zero across 2+ releases = under-caching or over-specific triage |
| 3 | **Observations-logged count** | Count of observations appended to the observation log during this release | Decaying to zero across multiple releases = under-capture (class-potential threshold too narrow) |
| 4 | **Emergence-confirmation rate** | Count of candidate patterns surfaced AND promoted to permanent entries this release | Zero across 2+ releases with ≥10 observations logged = over-tagging (clustering doesn't match operator judgment) |

**Framing:** Tripwires, not thresholds. A zero-rate release is not automatic failure — it is a signal that either (a) the release genuinely didn't exercise the mechanism, (b) the consumer is drifting toward theater, or (c) calibration parameters need adjustment. Operator interprets.

---

## Section 7 — Consumer Binding

### 7.1 Current primary consumer: `hub-spoke-bridge.md` (hub-and-spoke release bridge)

The hub cites this framework at every Decision Briefing produced under its Operating Principle. Specific binding locations:

- **Operating Principle:** a reference paragraph after the principle block naming this framework.
- **Procedure 0a (Audit-Aware Orientation):** cross-references § 2.1.1 sub-mechanism at the chip-launch / recommendation-rendering surface.
- **Procedure 4 Step 6 (Spoke Completion Handling):** Decision Briefing production applies mechanisms per § 3 triage table.
- **Procedure 5 Step 3 (Gate Handling):** Gate-decision presentation applies mechanisms per § 3 triage table.
- **Procedure 7 (Release Close), new Step 3a:** reports the 4 metrics in § 6 for the release.

### 7.2 Secondary consumer: `release-personas.md` Stage 4 Release Manager

The Stage 4 persona card (Release Manager — Release Planning) embeds behavioral markers that reference this framework (applies § 3 triage table to capacity/merge-split/stage-applicability/risk-severity; scans confirmed + emerged-candidate patterns before finalizing decisions; logs operator-correction observations with `domain: release-ops`). Corresponding anti-patterns reference this framework (does not apply generic capacity heuristics without localization; does not skip Pattern Cache Scan when a confirmed pattern or emerged candidate applies; does not treat single operator corrections as patterns).

### 7.3 Future consumers (skill-replacement successors)

When skills replace hub functions, they inherit this framework directly without modification. Expected future consumers:

- `release-planner` skill — Stage 4 Release Planning successor.
- `principal-engineer` skill — Stage 5 Solutioning successor.
- Any future decision-producing skill — consumer-agnostic triage table (§ 3) applies unchanged.

When `hub-spoke-bridge.md` is deprecated, the consumer-binding section in that file becomes archival; this framework survives intact.

### 7.4 Concrete application (D-Gate upstream-compatibility check)

This applies Mechanism 1 (§ 2.1) to the Operator Decision Gate for the upstream-Anthropic-compatibility dimension. The D-Gate template in `hub-spoke-bridge.md` Procedure 0 carries a REQUIRED-with-N/A-rationale `Upstream compatibility` subsection per D-decision; the template cross-references `§ 2.1 Mechanism 1` as parent framework. It is one concrete M1 application at the D-decision-content level; the briefing-level Localization Check operates at the consumer-recommendation level. They are complementary, not redundant.

The queryable upstream surface that D-Gate verdicts consult is codified at [`upstream-reference-catalog.md`](../standards/upstream-reference-catalog.md) (R2 defense-in-depth bundle). The catalog enumerates `artifact_class` → `upstream_source` mappings with `upstream_required` / `upstream_optional` / `pmo_extensions` fields per entry; future D-Gate spokes render `aligned` / `diverged-with-rationale` / `N/A` verdicts by consulting the relevant catalog entry rather than re-discovering upstream conventions from scratch. The D-Version case study (`skill-md-frontmatter` entry, codifying Anthropic `name` + `description` baseline + PMO `version:` extension) is the worked example.

---

## Section 8 — Retrospective Validation

### 8.1 Per-instance replay mapping

The retrospective produced four hub context-localization failure instances (2026-04-18 through 2026-04-23). Each maps to a primary mechanism with expected catch:

| Instance | Failure | Primary mechanism | Expected catch |
|---|---|---|---|
| Instance 1: PR-0 hotfix / release-model bypass | Accepted spoke Procedure 6 recommendation without checking release model | M1 Localization | **CATCH** — M1 would cite "release-model: no-direct-to-main" as platform context overriding the generic "hotfix merges directly" heuristic |
| Instance 2: doc→code naming / "which came first" | Pseudo-reasoning as presentation scaffolding | M2 Opposing View | **CATCH** — M2 demands concrete counter-argument; "which came first" dissolves under concreteness requirement; consumer articulates "semantic accuracy: does name match current primary function" instead |
| Instance 3: No audit of other D-decisions after M2 | Narrow-meta-response; didn't generalize | M3 Pattern Cache Scan | **CATCH** — After operator correction on M2, consumer logs observation (theme `narrow-meta-response`) AND on next D-decision scan, emergence or cache citation surfaces broad-audit discipline |
| Instance 4: D8 defer-to-next-release | Scope-discipline heuristic without operator-domain-knowledge check | M1 Localization | **CATCH** — M1 cites "operator bandwidth / downstream workload" as load-bearing context; heuristic is challenged |

**Cross-instance pattern check:** Stage 7 DT must verify M2 and M3 are separately load-bearing (not both reducing to M1). M2 catches Instance 2 without invoking M1's localization frame. M3 catches Instance 3 by surfacing the class-pattern observation that Instance 3's operator correction produced.

**Escape detection:** Stage 7 DT additionally checks for failures OUTSIDE these 4 that the mechanisms would have missed. No such escape surfaced during Stage 5 Solutioning.

### 8.2 N = 2 emergence validation under broad theme tagging

Apply the emergence rule (§ 4.2) to the 4 instances under broad mechanism-level theme tagging:

| Instance | Domain | Theme (broad) | Date (approx.) |
|---|---|---|---|
| 1 (PR-0 hotfix / release-model bypass) | release-ops | `context-localization-failure` | 2026-04-18..20 |
| 2 (doc→code naming / pseudo-reasoning) | release-ops | `weak-reasoning-scaffolding` | 2026-04-21..22 |
| 3 (no audit of D-decisions after M2) | release-ops | `narrow-meta-response` | 2026-04-22 |
| 4 (D8 defer-to-next-release / scope without bandwidth) | release-ops | `context-localization-failure` | 2026-04-23 |

**Within-(domain, theme) grouping at 2026-04-24 with 180-day window (all 4 are well within):**

| Group | Count | Emergence result |
|---|---|---|
| (`release-ops`, `context-localization-failure`) | **2** (Instances 1, 4) | ✅ **Candidate surfaces** — operator confirmation promotes to a confirmed pattern keyed by (`release-ops`, `context-localization-failure`) |
| (`release-ops`, `weak-reasoning-scaffolding`) | 1 (Instance 2) | ⚠️ Singleton observation — awaiting further evidence |
| (`release-ops`, `narrow-meta-response`) | 1 (Instance 3) | ⚠️ Singleton observation — awaiting further evidence |

**Cross-domain:** Zero cross-domain observations (all 4 are `release-ops`). Cross-domain elevation gate does not fire; no false positives from this scenario.

**Validation outcome:**

- N = 2 correctly identifies the dominant pattern (`context-localization-failure`), which was indeed the mechanism identified in both `[SOURCE]` operator dialogue AND `[INFERRED]` common-mechanism analysis from the source-issue body.
- Singleton observations retained; not prematurely cached. Matches Principal Engineer intuition: mechanism exists prospectively for weak-reasoning + narrow-meta failures; cache entries emerge only when data earns them.
- Under narrow theme tagging (per-instance: `hotfix-release-model-bypass`, `doc-code-naming-which-came-first`, `no-meta-audit-after-correction`, `defer-without-bandwidth-check`), zero emergence fires — all 4 are singleton themes. Adopted default is broad tagging, per § 4.3.

### 8.3 Stage 7 DT replay procedure (authoritative scaffold)

Stage 7 DT exercises the 3 mechanisms against the 4 failure instances using structured replay, reconstructing decision contexts and synthesized Decision Briefings.

**Per-instance procedure:**

1. Reconstruct the decision context: read the release dialogue at failure point (spoke output, release state, prior decisions).
2. Synthesize the Decision Briefing the consumer WOULD have produced under the new template: apply § 3 triage → fill required sections → evaluate load-bearing test per section (G1, G3).
3. Assess mechanism catch: does the synthesized briefing contain the reasoning that would have prevented/surfaced the failure?
4. Record verdict: **CATCH** / **MISS** / **PARTIAL** (mechanism surfaces uncertainty, needing operator judgment).

**Emergence-check (Iter 2 extension):**

- Apply revised M3 scan procedure to the 4 instances: verify `context-localization-failure` emerges (Instances 1 + 4 → N = 2 within `release-ops`, within 180 days); verify singletons (Instances 2, 3) do not emerge.

**Cross-domain negative-check (Iter 2 extension):**

- Inject a synthetic observation in `project-ops` with the same theme as one of the `release-ops` observations. Verify cross-domain elevation flag surfaces at session start. Verify NO auto-emergence across domains.

**Failure routing (if DT finds a MISS):**

- **Tier 2 (scope change):** Mechanism needs template amendment OR triage rule adjustment → return to Stage 5 Solutioning for revision.
- **Tier 3 (plan rejection):** Framework is fundamentally unworkable for the instance class → return to Stage 4 Planning with evidence.

**PARTIAL verdict handling:** DT accepts with finding "Mechanism surfaces uncertainty; operator judgment required in replay. Validate that the LIVE consumer running this would surface to operator." Record as calibration input, not failure.

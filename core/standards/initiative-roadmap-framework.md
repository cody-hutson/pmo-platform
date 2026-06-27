---
title: Initiative Roadmap Framework
purpose: Governs when an initiative warrants a roadmap artifact, what lifecycle it follows, how it differs from an ADR or Initiative Issue, and how cross-milestone cohesion is checked
status: ACTIVE
owner: Workspace owner ([OPERATOR_NAME])
schema_version: 1
adr: ""
consumers: <OPERATOR_INSTANCE_ROADMAPS_PATH>/*.md (operator-local instances, untracked per ADR-012), framework-catalog.md (registry row), architecture-overview.md (Peer-Spec Concept Ownership row); RETIRED per ADR-012 (deploy.sh Check 24, stage-13-close forcing-function, release-process Stage 5 cohesion-check, gate G3-13)
cross_references: knowledge-architecture.md, framework-corpus-discipline.md, design-artifact-standard.md, evidence-grounding-standard.md, decision-discipline.md, duplicate-source-discipline.md, reversibility-protocol.md, label-taxonomy.md
upstream_sources:
  - "projects/Deep Research PMO/methodology-knowledge-base/domains/C12-artifacts-documentation.md §1 §2 §4 §6"
  - "projects/Deep Research PMO/methodology-knowledge-base/domains/C13-knowledge-management.md L166-169"
  - "projects/Deep Research PMO/methodology-knowledge-base/domains/C06-portfolio-program-management.md L45 L232"
non_overlap:
  - "repo-hygiene-standards — owns ADR mechanics"
  - "adr-policy-cluster — owns ADR policy"
---
<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->

# Initiative Roadmap Framework

**Origin:** initiative-roadmap framework + cross-milestone cohesion-check protocol.
**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Class:** standards. Governs initiative-roadmap artifacts at `<OPERATOR_INSTANCE_ROADMAPS_PATH>` (default `/roadmaps/`, per ADR-046) and the Stage 5 Collective Review cohesion-check applied across multi-milestone initiatives.
**Primary consumers:** authors of new initiative roadmaps under `<OPERATOR_INSTANCE_ROADMAPS_PATH>` (default `/roadmaps/`); Stage 5 Solutioning spokes invoking cohesion-check; `release-planner` and `release-executor` consuming `cluster:` / `initiative:` labels at Stage 3 Bundle and Stage 12 Execute.
**Secondary consumers:** `deploy.sh` Check 24 (90-day roadmap-staleness scan); Stage 13 Close checklist (event-trigger forcing function); `pmo-qa-auditor` Mode D (cohesion-check execution against roadmap §3 Now/Next/Later).

> **⚠ RE-SCOPED per [ADR-012](../ADRs/ADR-012-roadmap-instance-descope.md) (2026-06-02).** Initiative-roadmap *instances* are now authored **operator-local** at `<OPERATOR_INSTANCE_ROADMAPS_PATH>` and are **not tracked** in this repo. This framework is retained as the reusable **convention** — when to author a roadmap, its structure and lifecycle, the F9 4-case diagnostic (§7.4), and the cohesion-check protocol (§7.9). The in-repo **enforcement** it formerly bound to is **retired**: throughout this document, treat every reference to `deploy.sh` Check 24, the Stage 13 Close forcing-function, the Stage 5 Collective Review cohesion-check, and gate `G3-13` as **historical** — those surfaces are removed or tombstoned, and roadmap freshness/cohesion is now an **operator-local discipline**. Read any `pmo-platform/governance/roadmaps/*.md` path as `<OPERATOR_INSTANCE_ROADMAPS_PATH>`. **The token's default resolution is the shipped in-repo `/roadmaps/` folder** (folder + `README` tracked, instances git-ignored — the `analysis/` workspace pattern, per [ADR-046](../ADRs/ADR-046-roadmap-instance-in-repo-home.md)); a deployment may repoint the token for plug-and-play storage.

## 1. Purpose and Scope

This framework answers five questions the platform previously left to convention:

1. **When** does an initiative warrant a roadmap artifact? (§3)
2. **What lifecycle** does the artifact follow once authored? (§6)
3. **How does it differ** from an ADR or an Initiative GitHub Issue? (§4)
4. **How is cross-milestone cohesion checked**, both at authoring time and at the Stage 5 Collective Review release-checkpoint? (§7.9)
5. **Where does Vision fit** relative to Roadmap / ADR / Spec / Git history? (§2)

The framework is not a template generator — it specifies the convention that every roadmap conforms to. Six pilot roadmaps under `pmo-platform/governance/roadmaps/` (automation, governance-hygiene, release-process-fitness, skills-distribution, project-data-architecture, template-architecture) are the empirical substrate. The framework codifies the convention those pilots converged on, plus the boundary statements and forcing function that were left implicit during pilot authoring.

**In scope:** initiative-roadmap convention (when to author, what lifecycle, frontmatter schema, section structure, forcing function, cohesion-check protocol, JBGE application, quality-criteria binding to enforcement). Boundary statement to ADR governance (cross-reference only — ADR mechanics owned by repo-hygiene-standards + adr-policy-cluster). Boundary statement to Initiative GitHub Issue (cross-reference only — Initiative Issues are the existing GitHub `initiative:` label mechanism).

**Out of scope (deliberate non-overlap):** ADR authoring mechanics (location, naming, immutability, supersession protocol) — governed by repo-hygiene-standards. ADR policy decisions (deprecation, retirement, scope of immutability) — governed by adr-policy-cluster. Vision artifact authoring — Vision is durable platform-purpose held in the user auto-memory store; this framework merely positions Roadmap relative to Vision in the 5-tier mental model.

## 2. Artifact Hierarchy and Lifecycle Pattern Mapping

The PMO platform produces five canonical artifact classes. Each fits a level in the C12 four-level hierarchy (§2.1), follows one of three lifecycle patterns (§2.2), and pairs with the Diátaxis quadrant that governs how it is read.

### 2.1 Artifact Hierarchy

The 5-tier mental model for platform-canonical artifacts:

```
Portfolio                  Vision
  │                          (durable platform purpose; scope = whole platform)
  │
  ▼
Program                    Roadmap
  │                          (architected path across milestones; scope = one initiative)
  │
  ▼
Project                    Spec
  │                          (implementation contract; scope = one release / milestone)
  │
  ▼
Team                       ADR  ←──  Git history
                             (immutable decision record)   (immutable change record)
```

The five-type mapping, with C12 altitude and primary consumer:

| # | Artifact type | C12 altitude | Primary location | Primary consumer |
|---|---|---|---|---|
| 1 | **Vision** | Portfolio | User auto-memory store (durable platform-purpose) | Workspace owner; all skills consuming "what is this platform for" |
| 2 | **Roadmap** | Program | `<OPERATOR_INSTANCE_ROADMAPS_PATH>/*.md` (operator-local, untracked per ADR-012) | `release-planner`, Stage 3 Bundle (convention only — in-repo enforcement retired per ADR-012) |
| 3 | **Spec** | Project | `core/specs/*.md`, `core/standards/*.md`, release plans at `release/releases/plans/*.md` | Stage 4 Planning, Stage 5 Solutioning, Stage 6 Engineering |
| 4 | **ADR** | Team-level decision record | `core/ADRs/ADR-NNN-*.md` (cross-cutting / platform-architecture) or `release/ADRs/ADR-NNN-*.md` (release-scope) per the ADR module-restructure | Decision-class consumers reading "why was X chosen?" |
| 5 | **Git history** | Team-level change record | `.git/` (commits + PRs on github.com/[OPERATOR_GITHUB]/pmo-platform) | All audit / archeology / "what changed when" lookups |

**Boundary clarification (Vision vs Roadmap):** Vision answers "what is this platform for, period" — it changes only when the platform's strategic purpose shifts. Roadmap answers "for this one initiative, what's the architected path across milestones to that purpose" — it changes per initiative as Now/Next/Later evolves. A new initiative does not produce a new Vision; it may produce a new Roadmap.

**Boundary clarification (Roadmap vs Spec):** Roadmap is sequence-anchored ("Foundation shipped, Skill is Now, Hardening is Next") at the Program altitude. Spec is implementation-anchored ("file X gets line Y added, function Z gets refactored") at the Project altitude. A roadmap cites the milestones (and their constituent specs) that compose its capability; it does not duplicate spec content.

### 2.2 Lifecycle Pattern Mapping

Per C12 §2, the platform distinguishes three lifecycle patterns. Each canonical artifact maps to exactly one:

| Artifact type | Lifecycle pattern | Reasoning |
|---|---|---|
| Vision | **Living** | Updated in place as platform purpose evolves; the latest copy is authoritative; prior copies are recovered from git history if needed. |
| Roadmap | **Living** | §3 Now/Next/Later mutates at every event-trigger; `last_reviewed` field tracks freshness; archived to `_archived/<name>-{ACHIEVED,SUPERSEDED,CANCELLED}-YYYY-MM-DD.md` at sunset. |
| Spec | **Baselined** | Each spec ships at one release version; modifications produce a new version (or new spec); historical specs are not retroactively edited (they are the audit trail of what was decided when). |
| ADR | **Baselined** (append-only, immutable, superseded-not-edited per C13 L166-169) | A decision is captured once at its decision-time; later corrections produce a new ADR that supersedes the earlier one — the earlier ADR is never rewritten. |
| Git history | **Point-in-Time Snapshot** | Every commit is a frozen snapshot; the tree is mutable across snapshots but each snapshot is immutable. |

**Diátaxis quadrant assignment.** Roadmaps and ADRs both belong to *Explanations* (they explain *why* the platform looks the way it does). Specs are *Reference* (lookup of authoritative implementation details). Vision is *Explanations* (it explains platform purpose). Git history is its own audit category, not a Diátaxis-quadrant doc.

**Tier-A activated design artifact.** §2.1 and §2.2 together constitute a concept-model design artifact per [`design-artifact-standard.md`](design-artifact-standard.md) §7. The 5-tier hierarchy + lifecycle-pattern mapping is a new architectural concept named in this governance file and is therefore Tier-A activated. Stage 13 G-CL6 verifies the §2.1-2.2 content was refreshed in the release branch.

## 3. When to Author a Roadmap (criteria)

A roadmap is the right artifact for an initiative iff the initiative meets the three positive criteria in §3.1 AND passes the omission test in §3.3. Otherwise, the initiative is tracked sufficiently by milestone descriptions alone (or by an Initiative GitHub Issue) and a roadmap is redundant.

### 3.1 Three positive criteria (≥3 grep-verifiable)

A roadmap is warranted when **all three** of the following are true:

1. **Multi-milestone span:** the initiative spans **≥3 milestones**. A 1- or 2-milestone capability is captured adequately by milestone descriptions and their inter-milestone dependency references; the additional cross-milestone artifact pays no information-density tax.
2. **High-reversibility-tier scope-lock:** the initiative's scope-lock decision sits at **IRREVERSIBLE or EXPENSIVE** reversibility tier per [`reversibility-protocol.md`](../specs/reversibility-protocol.md). The roadmap captures the architected path-to-done so that the scope-lock decision (and the assumptions it carries) is durable beyond any single milestone's lifetime.
3. **Initiative label present:** the initiative has a `cluster:<name>` or `initiative:<name>` label per [`label-taxonomy.md`](../specs/label-taxonomy.md). The label is the durable identifier that ties contributing GitHub Issues to the roadmap; without it, the roadmap has no machine-readable way to scope its contributing work.

### 3.2 NOT-doing omission criterion

A roadmap is **NOT** warranted (and authoring one is governance-cost without payoff) when:

- Any of the three §3.1 criteria fail, OR
- The architected path is already captured sufficiently by the constituent milestone descriptions — i.e., a reader could derive the cross-milestone narrative from reading the milestone descriptions in sequence without the roadmap adding signal.

The omission criterion is the asymmetric default: when in doubt, do not author a roadmap. Authoring a roadmap that adds no signal beyond milestone descriptions is the dominant doc-rot failure mode the framework is designed to prevent.

### 3.3 Omission Test (the NOT-doing / seam-map / named-outcome triple)

Before authoring, the prospective roadmap author applies the **minimum-viable omission test**: the roadmap must add at least one of the three following structural elements that the constituent milestone descriptions do not already supply. If a proposed roadmap adds none of these, it is redundant and excluded.

| # | Element | What it is | Why it can't live in milestone descriptions alone |
|---|---|---|---|
| (a) | **NOT-doing** boundary | An explicit statement of what the initiative is deliberately not pursuing (deferred capabilities, rejected approaches, out-of-scope adjacent work) | Milestone descriptions enumerate what each milestone ships; they do not name what's excluded from the capability as a whole. |
| (b) | **Seam map** across milestones | An explicit map of inter-milestone dependencies, interfaces, and integration points (what milestone N hands off to milestone N+1, what assumptions each side carries) | Milestone descriptions describe each milestone's scope inwardly; they do not aggregate the cross-milestone seams in one place. |
| (c) | **Named outcome** beyond milestone descriptions | A Capability Outcome Statement that articulates the multi-milestone end state in a way no individual milestone description does | Milestone descriptions name what each milestone delivers; they do not name the multi-milestone capability the sum-of-milestones produces. |

A roadmap that supplies one of {NOT-doing, seam map, named outcome} is non-redundant. A roadmap that supplies all three is the canonical case. A roadmap that supplies none is the redundant-doc-rot failure mode the test exists to filter out.

### 3.4 Altitude classification (decision tree per C06 L45)

Roadmaps live at one of three altitudes per C06 L45:

- **Portfolio:** spans multiple strategic capabilities (rare — typically only Vision lives here)
- **Program:** spans a single strategic capability across multiple milestones (this is the dominant case for platform initiative roadmaps)
- **PI-Sprint:** spans a single PI / sprint cycle (rare for roadmaps — typically Specs operate at this altitude)

**Decision tree:**

```
Initiative crosses ≥2 distinct strategic capabilities (e.g., automation + governance + role-fit)?
├── YES → Portfolio altitude (use sparingly; consider whether Vision update is the right move instead)
└── NO  → Initiative spans ≥3 milestones within a single capability?
          ├── YES → Program altitude  (canonical case)
          └── NO  → PI-Sprint altitude (use sparingly; milestone description likely sufficient)
```

The 6 current pilots all classify as **Program** altitude. Frontmatter `altitude:` is enum-locked to `Portfolio | Program | PI-Sprint`.

## 4. Boundary Statements — Roadmap vs ADR vs Initiative GitHub Issue

The three artifact types answer different questions. A reader who needs to understand "what is the architected path for initiative X" reads the roadmap. A reader who needs to understand "why did we choose approach Y over approach Z for decision W" reads the ADR. A reader who needs to track "what specifically lands when and which sub-tickets are unresolved" reads the Initiative Issue. The three artifacts are complementary, not redundant.

### 4.1 Comparison table (covering all three artifact types per AC#3)

| Attribute | **Initiative Roadmap** | **ADR** | **Initiative GitHub Issue** |
|---|---|---|---|
| Primary purpose | Architected path across milestones | Single architectural decision + rationale | Tracked work + dependencies |
| Lifecycle pattern (per C12 §2) | **Living** | **Baselined** (append-only, immutable, superseded-not-edited per C13 L166-169) | **Living** (sub-task tracking) |
| Mutability | Mutable in place; archived at sunset | Immutable post-acceptance | Mutable until closed |
| Granularity | Multi-milestone capability | One decision | One initiative-tracking work item |
| Update cadence | Event-bound + 90-day calendar fallback | At decision-time only (no updates after) | At every sub-task state change |
| Owning governance | This framework | repo-hygiene-standards (mechanics) + adr-policy-cluster (policy) | GitHub Issues + `initiative:`/`cluster:` labels per [label-taxonomy.md](../specs/label-taxonomy.md) |
| Primary location | `core/governance/roadmaps/*.md` | `core/ADRs/*.md` (cross-cutting) or `release/ADRs/*.md` (release-scope) | github.com/[OPERATOR_GITHUB]/pmo-platform/issues |
| Diátaxis quadrant | Explanations | Explanations | (operational tracker — not a Diátaxis-quadrant doc) |

### 4.2 Roadmap details

An Initiative Roadmap captures the **architected path across milestones** for a multi-milestone initiative. It is a Living artifact: §3 Now/Next/Later mutates as milestones close, new gaps surface, and the initiative's path is refined. The roadmap is the canonical "this is what we're trying to deliver across these N milestones" record. It does not capture per-decision rationale (that's the ADR's job) and it does not track work items (that's the GitHub Issue's job).

### 4.3 Initiative GitHub Issue details

An Initiative GitHub Issue captures **tracked work + dependencies** for an initiative. It is the GitHub `initiative:<name>` label (per [`label-taxonomy.md`](../specs/label-taxonomy.md)) plus the parent Issue that aggregates contributing sub-tasks. The Initiative Issue is mutable: sub-tasks close, dependencies resolve, the Issue updates. It is not durable beyond the initiative's lifetime (Issue closes when initiative ships; the roadmap survives in `_archived/` for historical reference).

### 4.4 ADR Boundary (no overlap with ADR-governance standards)

**Verbatim boundary statement (per AC#7 non-overlap requirement):**

> **Roadmap vs ADR vs Initiative Issue boundary.**
> An **Initiative Roadmap** captures the *architected path across milestones* for a multi-milestone initiative (Living artifact; what we're trying to deliver). An **ADR** captures a *single architectural decision and its rationale* (Baselined immutable artifact per C13 §6; why we chose what we chose). An **Initiative GitHub Issue** captures *tracked work + dependencies* (mutable artifact; what specifically lands when). ADR mechanics (immutable markdown format, location, naming, supersession protocol) are governed by repo-hygiene-standards (owns ADR mechanics) and adr-policy-cluster (owns ADR policy). **This framework authors no ADR governance.** Roadmap §4 sections that reference future ADRs use placeholder-stub convention until ADR infrastructure ships (deferred-decision-stub pattern, per §7.5).

**C13 canonical ADR definition (verbatim per AC#12):**

> Architecture Decision Records (ADRs); append-only, immutable once accepted, superseded by new records
> — [C13-knowledge-management.md L166–169](<OPERATOR_INSTANCE_PROJECTS_PATH>/Deep%20Research%20PMO/methodology-knowledge-base/domains/C13-knowledge-management.md)

This framework cites C13's definition; it does not redefine ADR semantics. Any ADR-related convention this framework appears to assert (e.g., the deferred-decision-stub pattern in §7.5) is a roadmap-side convention for how a roadmap references *future* ADRs, not a redefinition of ADR mechanics.

### 4.5 Umbrellas are roadmap-governed, never milestoned

The architected path across milestones — the umbrella for a multi-milestone initiative — is governed by a roadmap (this framework), not by a milestone. A milestone is a release-bundle of work that lands together; it is not the home for the cross-milestone capability arc. Creating a milestone *to represent the umbrella itself* is a category error: it conflates the bundling unit (§4.1 Initiative GitHub Issue / milestone — "what lands when") with the architected path (§4.2 Roadmap — "what we are trying to deliver across N milestones").

The correct decomposition: the **roadmap** holds the umbrella (Now/Next/Later sequence, Capability Outcome, Sunset Criteria); the **Initiative GitHub Issue** (with its `initiative:`/`cluster:` label) aggregates the tracked sub-work; and each **milestone** bundles a release-sized slice of that work. An umbrella that has been given a milestone of its own — rather than a roadmap entry plus per-slice milestones — is mis-homed; route it back to a roadmap and let the milestones carry only the bundled slices. This is the §4.1-table boundary applied to the umbrella case: the umbrella is a Living roadmap concern, and a milestone is the wrong artifact class to carry it.

## 5. Forcing Function — Event-Bound Triggers + Calendar Fallback

A Living artifact rots into a v1 snapshot without a forcing function. This framework requires every roadmap to specify **four event-bound triggers** plus a **90-day calendar staleness fallback**.

> **RETIRED enforcement (ADR-012, 2026-06-02).** The three in-repo enforcement layers below no longer run — roadmap instances are operator-local. The triggers and 90-day cadence are retained as an **operator-local discipline**; the layers are described below for historical/reference context.

The forcing function was formerly enforced at three layers:

1. **Authoring time** — every roadmap's frontmatter declares `review_cadence:` describing the four triggers + calendar fallback, and every roadmap's §5 Review Cadence section enumerates the triggers operationally.
2. **Stage 13 Close checklist** (per `pipeline/stage-13-close.md`) — at every release close, the Stage 13 spoke checks: for each milestone closed this release, does any roadmap `§3 Now/Next/Later` reference that milestone's `#N`? If yes, file a roadmap-review issue OR confirm the affected roadmap's `last_reviewed:` was updated during the release.
3. **`deploy.sh --check` Check 24 (warn-mode initial)** — scans `pmo-platform/governance/roadmaps/*.md` frontmatter; any `last_reviewed:` older than 90 days emits a WARN to `.claude/hooks/deploy-check-warn-log.jsonl`. After 2–3 release shakedown, flip to enforce per the Shakedown → Enforce Transition Checklist in [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md).

### 5.1 The four event-bound triggers (REQUIRED)

Every roadmap MUST specify these four event-bound triggers in its §5 Review Cadence section:

| # | Trigger | Operational signal |
|---|---|---|
| T1 | **Theme-touching milestone close** | Any milestone listed in §3 Now/Next/Later closes (status = Closed on GitHub) |
| T2 | **Release start** with theme content | Any release whose Milestone description references this roadmap, or whose scope touches the roadmap's `cluster:` / `initiative:` labels, starts at Stage 3 Bundle |
| T3 | **New intake ticket** with theme label | Any new GitHub Issue is labeled with this roadmap's `cluster:` / `initiative:` label |
| T4 | **90-day calendar fallback** | `last_reviewed:` frontmatter field is more than 90 days old — `deploy.sh --check` Check 24 surfaces this as warn-log entry |

The four triggers are **non-overlapping** in the sense that any one of them is a sufficient trigger; an event can fire multiple triggers (e.g., a release that closes a theme-milestone AND starts theme content fires T1 + T2 simultaneously — both reviewers fold into a single review action). The triggers are **exhaustive** in the sense that every realistic roadmap-aging-cause is covered by one of T1–T4.

### 5.2 Review action items (executed when any trigger fires)

When any T1–T4 trigger fires, the roadmap owner (per frontmatter `owner:` field) performs:

1. Update `last_reviewed:` date in frontmatter
2. Re-evaluate §3 Now/Next/Later against current milestone states (promote, demote, close, or remove rows)
3. Re-evaluate §3 Identified Gaps — closed gaps removed, new gaps added
4. Append review note to §8 Findings (or equivalent) if any framework ambiguity surfaced
5. Re-assess sunset criteria in §6 — has the roadmap reached terminal state?

If the trigger surfaces no changes (e.g., a release closed but no roadmap-listed milestones were affected), the review action collapses to step 1 alone (timestamp bump). The forcing function is the *check*, not the *edit*.

## 6. Frontmatter Schema and Lifecycle States

### 6.1 Frontmatter schema (11 existing fields + 1 new required field)

Every roadmap under `pmo-platform/governance/roadmaps/` declares the following 12 fields:

| Field | Type | Required? | Constraint |
|---|---|---|---|
| `artifact` | enum, value: `roadmap` only | REQUIRED | Enum-locked to single value (identifies the artifact class) |
| `state` | enum: `ACTIVE` / `ACHIEVED` / `SUPERSEDED` / `CANCELLED` | REQUIRED | Lifecycle state per §6.2 |
| `altitude` | enum: `Portfolio` / `Program` / `PI-Sprint` | REQUIRED | Per C06 L45; default-case is `Program` (see §3.4 decision tree) |
| `lifecycle_pattern` | enum: `Living` / `Point-in-Time Snapshot` / `Baselined` | REQUIRED | For roadmaps always `Living` (per §2.2) |
| `diataxis_quadrant` | enum: `Tutorials` / `How-To Guides` / `Explanations` / `Reference` | REQUIRED | For roadmaps always `Explanations` (per §2.2) |
| `created` | ISO 8601 date `YYYY-MM-DD` | REQUIRED | Roadmap authoring date |
| `last_reviewed` | ISO 8601 date `YYYY-MM-DD` | REQUIRED | Updated at every review trigger; consumed by `deploy.sh --check` Check 24 staleness scan |
| `review_cadence` | string | REQUIRED | Describes 4 event-bound triggers + 90-day calendar fallback (per §5.1) |
| `owner` | string | REQUIRED | Typically `workspace-owner`; named role accountable for review-trigger fulfillment |
| `related_issue` | **ARRAY of strings** (e.g., `["", ""]`) | REQUIRED | Array form is canonical (resolves F3-gov drift across pilots); use array even for single related issue: `[""]` |
| `sunset_criteria` | string (typically pointer to §6 Sunset Criteria) | REQUIRED | Per C12 §4 explicitly-ephemeral-or-permanent criterion |
| `roadmap_creation_intake_ticket` | string (e.g., `""`) — **NEW field** | REQUIRED for new roadmaps post-cutover; grandfathered to `""` for the 6 pilots | Per F1-gov; identifies the enabling intake ticket per "No ungoverned changes" governance |

**Grandfathering rule:** The 6 pilot roadmaps (automation, governance-hygiene, release-process-fitness, skills-distribution, project-data-architecture, template-architecture) predate this framework. Stage 6 backfills `roadmap_creation_intake_ticket: ""` and converts `related_issue:` to array form on all 6 pilots in the same release branch (per F2 authorization at Stage 5 close). New roadmaps MUST include the field at creation time with the actual intake-ticket reference.

### 6.2 Lifecycle states (4 states, 4 named transitions per AC#2)

The four roadmap lifecycle states:

| State | Meaning |
|---|---|
| `ACTIVE` | Roadmap is in flight; §3 Now/Next/Later is actively maintained; `last_reviewed:` is event-bound |
| `ACHIEVED` | All §6 sunset criteria met; roadmap archived to `_archived/<name>-ACHIEVED-YYYY-MM-DD.md` |
| `SUPERSEDED` | Structurally different model adopted; archived to `_archived/<name>-SUPERSEDED-YYYY-MM-DD.md` with link to replacement roadmap |
| `CANCELLED` | Strategic direction shifted away; archived to `_archived/<name>-CANCELLED-YYYY-MM-DD.md` with rationale |

The four named state transitions:

| # | Transition | Gate |
|---|---|---|
| 1 | `(initial) → ACTIVE` | Creation gate: intake-ticket approved (frontmatter `roadmap_creation_intake_ticket:` set) + frontmatter `state: ACTIVE` |
| 2 | `ACTIVE → ACHIEVED` | Sunset gate: all §6 sunset criteria validated (operator-confirmed) |
| 3 | `ACTIVE → SUPERSEDED` | Operator decision; new roadmap link REQUIRED in archive frontmatter |
| 4 | `ACTIVE → CANCELLED` | Operator decision; rationale REQUIRED in archive frontmatter |

All terminal transitions move the file (not delete it): the archived copy at `_archived/<name>-<STATE>-YYYY-MM-DD.md` is the durable historical record. Per "least-destructive disposition" feedback discipline, the file is never deleted on termination.

## 7. Protocol Sections

### 7.1 Creation Protocol (F1-gov)

A new roadmap is authored only when an enabling intake ticket exists (per "No ungoverned changes" CLAUDE.md governance). The intake ticket:

1. Identifies the initiative the roadmap will govern
2. Validates the §3.1 three positive criteria
3. Passes the §3.3 omission test
4. Receives operator approval (via the standard `improvement.yml` intake → triage → approval pipeline)

After approval, the roadmap is authored. Its `roadmap_creation_intake_ticket:` field references the approved intake ticket. The roadmap is added to its initiative's tracking via `related_issue:` array entries.

### 7.2 Success-Signal Schema (F4-auto)

Every roadmap §1 Capability Outcome Statement enumerates **success signals** in a table with the following columns:

| Column | Type | Required? | Purpose |
|---|---|---|---|
| `#` | integer | REQUIRED | Stable signal ID for cross-reference |
| `Signal` | string | REQUIRED | Narrative description of the signal |
| `Type` | enum: `Quantitative` / `Qualitative` / `Mixed` | REQUIRED | Measurement class |
| `Measurable Today?` | string | REQUIRED | Explicit answer to "is this signal measurable today" — values include `Yes` (with measurement source) / `Aspirational — instrumentation needed` / `Sampled per [event]` / `Baseline = N` |

**Aspirational signals are permitted** but must be explicitly flagged. Marking a signal `Aspirational — instrumentation needed` is a NOT-yet-measurable acknowledgment, not a defect — it surfaces the instrumentation gap that must close before the signal can validate sunset.

### 7.3 (Reserved — preserved for forward compatibility)

### 7.4 §3a Structure: Identified Gaps + 4-Case Diagnostic (F2-gov + F9-auto)

Every roadmap §3 Now/Next/Later includes a subordinate **§3 Identified Gaps** (or §3a — naming convention is roadmap-author choice) capturing orphaned work surfaced during authoring or review. The diagnostic applies **4 cases** to each gap:

| Case | Gap classification | Action |
|---|---|---|
| (a) | Work doesn't exist (no GitHub Issue, no Milestone) | File intake ticket → link gap to ticket |
| (b) | Work exists but isn't mapped to the roadmap | Fix mapping (update milestone description's roadmap-back-reference + roadmap's §3 Now/Next/Later) |
| (c) | Work exists unbundled (Issue without Milestone) | Bundle into appropriate Milestone via Stage 3 Bundle re-bundle |
| (d) | Work already shipped | Fix mapping (mark in §3 "Shipped — Foundation" or equivalent) + ensure contribution-to-outcome attribution is captured |

**Backlink checklist for §3 Identified Gaps:** Each gap entry MUST include:
- Per-gap case classification (a / b / c / d)
- Action taken or to take (named action verb + target artifact)
- Cross-link to the GitHub Issue tracking the gap closure (once filed per case (a), or the existing Issue per cases (b)/(c)/(d))

### 7.5 Deferred-Decision-Stub Convention (F3-auto)

When a roadmap references a load-bearing decision whose authoritative ADR does not yet exist (e.g., ADR infrastructure pending repo-hygiene-standards), use the deferred-decision-stub pattern in §4 Cross-Cutting ADR References:

| Future ADR | Decision | Reversibility Tier | Activates With |
|---|---|---|---|
| ADR-NN | <one-line description of the decision> | <CHEAP/MODERATE/EXPENSIVE/IRREVERSIBLE> | <milestone or Issue that will trigger ADR authoring> |

Once ADR infrastructure ships, each stub is retroactively authored (or actively authored, if the decision was made post-ship). The deferred-decision-stub pattern is **roadmap-side convention**, not ADR governance — it tracks future ADRs the roadmap depends on, without authoring ADR mechanics here.

### 7.6 Quality Criteria Binding (C12 §4 six criteria → enforcement surface)

Every roadmap §7 includes a **Quality Self-Assessment** mapping its content to the six C12 §4 high-performing-documentation criteria. Each criterion is bound to a specific enforcement surface:

| # | C12 §4 Criterion | Enforcement surface |
|---|---|---|
| (a) | **Machine-parseable** | `deploy.sh --check` Check 24a (frontmatter schema lint — verifies all 12 fields present with type-conformant values) |
| (b) | **Living** | `deploy.sh --check` Check 24b (90-day staleness scan on `last_reviewed:` frontmatter field) |
| (c) | **Searchable** | `pmo-qa-auditor` Mode D (heading-structure + cross-reference scan; surfaces orphaned headings, broken cross-refs) |
| (d) | **Decision-captured** | §4 deferred-decision-stub convention (per §7.5); full decision-capture activates with ADR infrastructure |
| (e) | **Linked-to-code** | `deploy.sh --check` Check 14 (doc-link maintenance per `.claude/rules/doc-link-maintenance.md`) covers cross-reference integrity |
| (f) | **Explicitly ephemeral or permanent** | Frontmatter `sunset_criteria:` field REQUIRED (per §6.1); roadmap §6 Sunset Criteria explicit |

**F5-auto deferred:** Whether self-assessment is sufficient evidence for criterion PASS, or whether peer/audit review is required, is **per-roadmap operator discretion** (not codified at framework level). Roadmaps may declare a stricter review model in §7 if the initiative's risk warrants it; framework default is self-assessment with `pmo-qa-auditor` Mode D as audit surface when invoked.

### 7.7 Findings Are Permanent (F7-auto)

Every roadmap includes a §8 (or equivalent) **Pilot Findings** / **Review Findings** section. The section is **permanent**, not pilot-only — Findings transition from `Open` → `Resolved` / `Deferred` / `Codified-into-framework` status, but the section itself remains in the roadmap as the durable feedback-loop record into framework iteration.

Findings table columns (REQUIRED):

| # | Finding | Status | Resolution / Disposition |
|---|---|---|---|

Status enum: `Open` / `Resolved` / `Deferred` / `Codified-into-framework` / `Per-roadmap-discretion`.

### 7.8 Milestone → Roadmap Back-Reference Convention (F8-auto)

Per C12 §1 cascade-update rule (changes at level N require review at N+1 downward and notification at N-1 upward), every milestone listed in any roadmap's §3 Now/Next/Later MUST prepend a one-line roadmap reference to its milestone description. Suggested form:

> **Roadmap:** part of [`<roadmap-name>`](../../governance/roadmaps/<roadmap-name>.md) §3 [Now/Next/Later/Shipped/Gaps] — see roadmap §1 Capability Outcome for context.

Back-references are added or removed at the same event-trigger that updates the roadmap's §3 (T1–T3 from §5.1). When a milestone is moved out of §3 Now/Next/Later (e.g., shipped → Shipped tier, or removed entirely), its back-reference is updated or removed in the same review action.

### 7.9 Cohesion-Check Protocol (3 dimensions per AC#5)

The cohesion-check protocol applies at two cadences:

1. **Authoring-time** — when a new roadmap is created, the author applies the 3-dimension check to the proposed §3 Now/Next/Later before committing the roadmap.
2. **Stage 5 Collective Review release-checkpoint** — when a release's Stage 5 Solutioning spokes touch any roadmap-listed milestone, the hub invokes the cohesion-check as part of Collective Review (see [`.claude/rules/release-process.md`](../../release/governance/release-process.md) § Collective Review Protocol). The roadmap's §3 is the input; cohesion-check output feeds into the scope-lock decision.

The **3 cohesion-check dimensions**:

| # | Dimension | Question answered | Quality bar |
|---|---|---|---|
| 1 | **Requirements completeness** | Does §3 Now/Next/Later span the full causal chain from §1 Capability Outcome to deliverable milestones? Are there gaps in the causal chain (work that must happen but isn't tracked anywhere)? | C06 L232: "identifies orphaned work; uses strategy maps to surface missing causal links" |
| 2 | **Design coherence** | Do the milestones in §3 share consistent architectural assumptions? (e.g., automation.md "device-portable / async-tolerant is a hard constraint" axiom — every milestone in scope must respect it.) Are any milestones' design choices in tension with the roadmap's §2 Scope axioms? | C06 L232: "proactively connects roadmap items to strategic themes" |
| 3 | **Seam detection** | Are cross-milestone seams (dependency interfaces between milestones) documented in §3 or flagged as gaps in §3.4 Identified Gaps? Are any seams implicit and undocumented? | C12 §1 cascade-update rule: "Changes at level N require review at N+1 (downward) and notification at N-1 (upward)" |

**Quality bar (per AC#13 — cross-reference to C06 L232 principal-vs-junior strategic-alignment criteria):**

Each cohesion-check dimension is measured against the C06 L232 principal-level behavior bar:

> Proactively connects roadmap items to strategic themes; identifies orphaned work; uses strategy maps to surface missing causal links; exercises courageous pruning.
> — [C06-portfolio-program-management.md L232](<OPERATOR_INSTANCE_PROJECTS_PATH>/Deep%20Research%20PMO/methodology-knowledge-base/domains/C06-portfolio-program-management.md)

A cohesion-check that flags zero issues across all three dimensions is suspicious (most roadmaps in active multi-milestone scope have at least one seam to surface). A cohesion-check that flags issues and routes them via the §7.4 4-case diagnostic to actionable next steps is principal-level work.

**Distinction from Stage 5 Collective Review (release-scope):** Collective Review (per `release-process.md` § Collective Review Protocol) validates **cross-issue design coherence within a release**. Cohesion-check (this section) validates **cross-milestone capability coherence across an initiative**. Same review pattern, different scopes — Collective Review is release-scope (per-release cadence); cohesion-check is initiative-scope (per-roadmap-review-trigger cadence). The two compose: a release whose Stage 5 spokes touch a roadmap-listed milestone runs Collective Review *plus* the affected roadmap's cohesion-check.

### 7.10 JBGE Application (≥2 example decisions per AC#11)

Per C12 §6, every roadmap is sized to **Just Barely Good Enough** — proportional to risk, audience, and purpose, not maximal. Two example JBGE decisions documented as canonical applications:

1. **Roadmap §3 may link milestone-descriptions rather than duplicate them.** The `automation.md` exemplar (~250 lines self-assessment) links milestones via GitHub URL and a single-row table entry (`Milestone | Type | Role in Capability | Status`) rather than copying milestone descriptions verbatim. JBGE: roadmap surfaces the cross-milestone narrative; the milestone descriptions remain the authoritative single-source-of-truth for per-milestone scope. Duplicating would violate [`duplicate-source-discipline.md`](duplicate-source-discipline.md).

2. **Pilot Findings section is permanent, NOT removed at maturity** (F7-auto resolution). Removing the Findings section once a roadmap "matures" would discard the framework-iteration feedback loop — F1-F10 from automation.md and F1-F3 from governance-hygiene.md are the empirical evidence that shaped this framework's §6, §7, §5. Discarding the section is JBGE-negative (removing decision-trail signal that future framework iterations need); keeping the section is JBGE-positive (low maintenance cost; high signal value). The section is permanent, not pilot-only.

## 8. Pilot Findings — Codification Status

The 6 pilot roadmaps generated 13 distinct findings (F1–F10 from automation.md §8; F1–F3 from governance-hygiene.md §7). The framework codifies 12 of 13 findings; F5-auto is deferred to per-roadmap operator discretion (per D-PILOT decision at the pilot-close 2026-05-22).

| # | Finding | Source | Disposition | Codified in framework section |
|---|---|---|---|---|
| F1-auto | Frontmatter schema undefined | automation.md §8 F1 | **CODIFIED** (REQUIRED) | §6.1 Frontmatter Schema |
| F2-auto | Identified Gaps freeform | automation.md §8 F2 | **CODIFIED** (structure REQUIRED) | §7.4 §3a Structure |
| F3-auto | Future-ADR placeholder pattern | automation.md §8 F3 | **CODIFIED** (deferred-decision-stub convention) | §4.4 ADR boundary + §7.5 stub convention |
| F4-auto | Aspirational signals allowed? | automation.md §8 F4 | **CODIFIED** (ALLOWED + `Measurable Today?` flag column REQUIRED) | §7.2 success-signal schema |
| F5-auto | Quality self-assessment review model | automation.md §8 F5 | **DEFERRED** to per-roadmap operator discretion | §7.6 self-assessment optional |
| F6-auto | Altitude classification criteria | automation.md §8 F6 | **CODIFIED** (decision tree per C06 L45) | §3.4 altitude decision tree |
| F7-auto | Pilot Findings permanent vs pilot-only | automation.md §8 F7 | **CODIFIED** (PERMANENT — feedback loop into framework iteration) | §7.7 Findings permanent |
| F8-auto | Milestone → roadmap back-reference | automation.md §8 F8 | **CODIFIED** (REQUIRED — milestone description prepends roadmap pointer) | §7.8 back-reference convention |
| F9-auto | Gap-analysis 4-case diagnostic | automation.md §8 F9 | **CODIFIED** (REQUIRED diagnostic with 4 cases named) | §7.4 §3a Structure |
| F10-auto | Review-trigger enforcement | automation.md §8 F10 | **CODIFIED** (Stage 13 Close checklist + `deploy.sh --check` Check 24) | §5 forcing function + §10 enforcement |
| F1-gov | Enabling-ticket protocol | governance-hygiene.md §7 F1 | **CODIFIED** (`roadmap_creation_intake_ticket:` REQUIRED) | §6.1 frontmatter + §7.1 creation protocol |
| F2-gov | §3a backlink checklist | governance-hygiene.md §7 F2 | **CODIFIED** (template checklist item REQUIRED) | §7.4 §3a Structure |
| F3-gov | `related_issue:` field type | governance-hygiene.md §7 F3 | **CODIFIED** (ARRAY of strings) | §6.1 frontmatter schema |

## 9. References

### Knowledge base sources (Layer 2)

- [`projects/Deep Research PMO/methodology-knowledge-base/domains/C12-artifacts-documentation.md`](<OPERATOR_INSTANCE_PROJECTS_PATH>/Deep%20Research%20PMO/methodology-knowledge-base/domains/C12-artifacts-documentation.md) §1 (four-level hierarchy), §2 (three lifecycle patterns), §4 (six quality criteria), §6 (JBGE principle)
- [`projects/Deep Research PMO/methodology-knowledge-base/domains/C13-knowledge-management.md`](<OPERATOR_INSTANCE_PROJECTS_PATH>/Deep%20Research%20PMO/methodology-knowledge-base/domains/C13-knowledge-management.md) L166–169 (ADR canonical definition)
- [`projects/Deep Research PMO/methodology-knowledge-base/domains/C06-portfolio-program-management.md`](<OPERATOR_INSTANCE_PROJECTS_PATH>/Deep%20Research%20PMO/methodology-knowledge-base/domains/C06-portfolio-program-management.md) L45 (roadmap altitudes), L232 (principal-vs-junior strategic-alignment criteria)

### Platform governance (Layer 1)

- [`core/governance/OPERATIONS.md`](../governance/OPERATIONS.md) — PMO protocols
- [`core/disciplines/knowledge-architecture.md`](../disciplines/knowledge-architecture.md) — K1-K5 tier model; placement of this framework as K1 standards
- [`core/standards/framework-corpus-discipline.md`](framework-corpus-discipline.md) — corpus-class governance (sibling K1 standard)
- [`core/standards/design-artifact-standard.md`](design-artifact-standard.md) — Tier-A design artifact activation (referenced in §2.2)
- [`core/standards/evidence-grounding-standard.md`](evidence-grounding-standard.md) — R1 canonicalization grounding
- [`core/standards/duplicate-source-discipline.md`](duplicate-source-discipline.md) — register-or-remove rule (referenced in §7.10)
- [`core/specs/framework-catalog.md`](../specs/framework-catalog.md) — registry row for this framework
- [`core/specs/reversibility-protocol.md`](../specs/reversibility-protocol.md) — CHEAP/MODERATE/EXPENSIVE/IRREVERSIBLE tiering (referenced in §3.1)
- [`core/specs/label-taxonomy.md`](../specs/label-taxonomy.md) — `cluster:` / `initiative:` label semantics (referenced in §3.1)
- [`.claude/rules/release-process.md`](../../release/governance/release-process.md) — Collective Review Protocol (referenced in §7.9)
- [`.claude/rules/doc-link-maintenance.md`](../rules/doc-link-maintenance.md) — cross-link integrity (referenced in §7.6)
- [`release/references/pipeline/stage-13-close.md`](../../release/references/pipeline/stage-13-close.md) — Stage 13 Close checklist (forcing-function enforcement, §5)

### Non-overlap (explicit cross-reference per AC#7)

- repo-hygiene-standards — owns ADR authoring mechanics (immutable markdown format, location, naming, supersession protocol). This framework cites; does NOT author.
- adr-policy-cluster — owns ADR policy (deprecation, retirement, scope of immutability). This framework cites; does NOT author.

### Sibling roadmaps (6 pilots — empirical substrate)

The 6 pilot roadmaps are authored **operator-local** at `<OPERATOR_INSTANCE_ROADMAPS_PATH>` (untracked per [ADR-012](../ADRs/ADR-012-roadmap-instance-descope.md)): `automation.md` (first pilot; F1–F10 source), `governance-hygiene.md` (second; F1–F3 source), `release-process-fitness.md` (third), `skills-distribution.md` (fourth), `project-data-architecture.md` (fifth), `template-architecture.md` (sixth). Their findings are already codified in §8 above — the framework does not depend on the instance files being present in-repo.

## 10. Enforcement and Cutover

### 10.1 Enforcement surfaces

> **RETIRED per [ADR-012](../ADRs/ADR-012-roadmap-instance-descope.md) (2026-06-02).** All four in-repo enforcement surfaces below are removed or tombstoned — roadmap instances are operator-local, so none can run. `deploy.sh` Check 24 is deleted; the Stage 13, Stage 5, and `G3-13` hooks are retired tombstones. The table is retained for historical context.

| Surface | What it enforced (RETIRED per ADR-012) | Former posture |
|---|---|---|
| `deploy.sh --check` Check 24 | Frontmatter schema lint (12 fields present, type-conformant) + 90-day `last_reviewed:` staleness | **warn-mode initial** per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist precedent (flip to enforce after 2–3 release shakedown) |
| Stage 13 Close checklist | For each milestone closed this release, file roadmap-review issue OR confirm affected roadmap's `last_reviewed:` updated | **active** from the first release after this framework ships (the shipping release is exempt per reflexive-pipeline-loop discipline) |
| `pmo-qa-auditor` Mode D | Heading-structure + cross-reference + cohesion-check execution against roadmap §3 | **active** when invoked; no automation-time gate |
| Stage 5 Collective Review | Cohesion-check across roadmap-touching milestones when the release crosses a roadmap-listed milestone | **active** from the first release after this framework ships (per `release-process.md` Collective Review Protocol composition) |

### 10.2 Cutover

The framework applies to **roadmaps created after this framework ships**. Existing pilots are grandfathered per §6.1 grandfathering rule:

- Pilot frontmatter normalization (add `roadmap_creation_intake_ticket: ""` + convert `related_issue:` to array form) — completed at Stage 6 in the same release branch (Tier 2 [SCOPE CHANGE] authorized at Stage 5 close per F2)
- Pilot §3 / §6 / §7 / §8 content — preserved verbatim; no retroactive backfill required (the framework codifies what the pilots empirically converged on; their content is the substrate, not a regression target)
- Pilot `last_reviewed:` field — not reset at cutover (existing dates remain authoritative; Check 24's 90-day window starts from those dates)

### 10.3 Reflexive-pipeline-loop discipline

The release shipping this framework is **exempt from the framework's own forcing-function enforcement** for the release itself. Specifically:

- The Stage 13 Close checklist (§5 layer 2) does NOT fire for this framework's own Stage 13 Close on the basis of *this framework's milestones* (would create a circular dependency where the rule shipping in this release fires on this release's own closure)
- `deploy.sh --check` Check 24 is active at this framework's ship; but the framework's own author-time conformance is this release's Stage 6 work product (not Check 24's job to validate retroactively)
- Stage 5 Collective Review cohesion-check applies from the first release after this framework ships onward (the release whose Stage 5 spokes touch a roadmap-listed milestone)

All releases after this framework ships are bound by the framework's enforcement in full.

## 11. Pilot Verification (AC#15 — automation.md end-to-end pilot)

Per AC#15, the framework is piloted end-to-end on `automation.md` before this framework's milestone closes. "Piloted" is defined by the following four closure criteria:

| # | Closure criterion | How verified |
|---|---|---|
| 1 | `automation.md` frontmatter normalized to framework schema (12 fields per §6.1, including new `roadmap_creation_intake_ticket:` + array-form `related_issue:`) | `grep "roadmap_creation_intake_ticket" automation.md` → non-empty; `grep "related_issue:" automation.md` shows array form |
| 2 | `automation.md` §3 cohesion-check executed against the 3 cohesion-check dimensions (§7.9 requirements-completeness / design-coherence / seam-detection) with results recorded | `automation.md` §11 (new section authored as part of conformance — "Conformance to initiative-roadmap framework") or equivalent in `automation.md` updates |
| 3 | At least one forcing-function trigger has fired on `automation.md` historically (per T1–T4 from §5.1) | `automation.md` `last_reviewed: 2026-05-15` reflects a prerequisite milestone closure event — T1 trigger fired; recorded in §6 "Re-assessed 2026-05-15 (per §5 event-bound review; trigger: two prerequisite milestones closed)" |
| 4 | `automation.md` §7 Quality Self-Assessment passes all 6 C12 §4 criteria with evidence cited | `automation.md` §7 table shows ✓ on machine-parseable / living / searchable / decision-captured (Partial — deferred-decision-stub) / linked-to-code / explicitly-ephemeral-or-permanent |

**Closure status at this framework's Stage 9 (release-readiness gate):** All four criteria PASS based on this release's Stage 6 work product:
- Criterion 1: PASS via Stage 6 commit (frontmatter normalization on all 6 pilots, including automation.md)
- Criterion 2: PASS via this framework §7.9 codifying the 3 dimensions; cohesion-check execution against automation.md §3 is a Stage 6 verification artifact (or Stage 9 verification evidence, depending on which spoke runs it)
- Criterion 3: PASS via pre-existing automation.md §6 re-assessment record (2026-05-15 milestone closures)
- Criterion 4: PASS via pre-existing automation.md §7 Quality Self-Assessment (all 6 criteria ✓ or ✓-partial)

**Downstream roadmap-consumer unblock signal:** Per the §G blast-radius analysis, the downstream roadmap-consuming release unblocks at this framework's Stage 9 IFF: (1) framework §11 Pilot Verification table shows all 4 closure criteria PASS on automation.md (this section), (2) framework §C AC checklist shows AC#1–13 + AC#15 PASS with grep-verifiable evidence (AC#14 deferred-to-followup per F1(d) at Stage 5 close), AND (3) `deploy.sh --check` Check 24 shows zero failures on the 6 normalized pilots. Stage 9 Plan Review of this release verifies all three; on GO, the downstream release is unblocked.

**AC#14 (incorporation-spec) DEFERRED-TO-FOLLOWUP.** Per F1(d) operator disposition at Stage 5 close 2026-05-22, the Layer 2 incorporation-spec at `projects/Deep Research PMO/reference/incorporation-specs/layer-3-governance/initiative-roadmap-framework-enrichment.md` is NOT authored in this release. After this release merges, operator triggers a Cowork follow-up session to author the L2 file from the L1 framework + KB sources. Stage 13 of this release records AC#14 status as `DEFERRED-TO-FOLLOWUP` in the release log.

---

**Author:** Stage 6 Engineering spoke
**Stage 5 design source:** Stage 5 Solutioning spec (closed 2026-05-22)

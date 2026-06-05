---
title: Platform Health Audit Framework
purpose: Anthropic Base-vs-Build observation methodology + audit cadence policy
type: protocol
related: anthropic-base-vs-build-registry.md (instance), successor (mode integration)
audit_baseline_sha: 4a943131c9e0323d5811f92704914657d7f7c314
audit_baseline_date: 2026-05-03
baseline_policy_reference: audit-baseline-when-target-population-is-empty discipline
adr: governing ADR (in the release plan)
---

# Platform Health Audit Framework

## Purpose

Defines the observation methodology and cadence policy for the Anthropic Base-vs-Build audit
class — a recurring observational review that catalogs every PMO source-roster skill against
the Anthropic skill catalog. The framework is **observational**: it describes overlap status
and intentional differentiation; it does NOT prescribe migration, consolidation, or
build-vs-buy actions (per the audit-framework charter body AC3 and the audit-class output discipline at
[review-discipline-principles.md](../../../core/disciplines/review-discipline-principles.md)).

The framework ships alongside the
[anthropic-base-vs-build-registry.md](../../../core/specs/anthropic-base-vs-build-registry.md) instance.
Successor work integrates the framework into pmo-qa-auditor as a
`platform-health` mode (deferred per the Strict scope of this release — see release plan §Stage 13
Obligations).

---

## §1 Anthropic Base-vs-Build Registry

### Purpose

Observational catalog of every PMO source-roster skill (per
[skill-deployment.md](../../../core/rules/skill-deployment.md) §Tracked Skills + ADR-04
canary) mapped against the Anthropic skill catalog (Hybrid baseline per §3.1). Describes
overlap status (one of `extends` / `replaces` / `independent` / `pass-through`) and
intentional differentiation. Consumed by:

- v13.* role-skill milestones — registry rows shape per-skill build/buy/wrap decisions for new
  role-skill authoring (HARD outbound handoff per the milestone description).
- release-planner (future) — registry MAY inform cross-Anthropic-overlap capacity heuristics
  at Stage 3 Bundle (soft outbound; no skill modification in this release).
- Successor release — registry input to pmo-qa-auditor `platform-health` mode (HARD outbound;
  mode integration deferred per Strict scope).

### Instance file

[`../../../core/specs/anthropic-base-vs-build-registry.md`](../../../core/specs/anthropic-base-vs-build-registry.md)

### Row schema

The canonical row schema lives in the registry doc header (§Schema). At a high level, each
row carries: `skill_name`, `deploy_status`, `anthropic_overlap_status` (4-element closed
enum), `anthropic_skill_ref`, `anthropic_skill_provenance`, `overlap_rationale`,
`overlap_notes`, `build_buy_observation`. See registry doc for column-by-column definitions.

### Update protocol

Cross-reference: §3.3 Registry Update Protocol below.

### Observational discipline

Cross-reference: [review-discipline-principles.md](../../../core/disciplines/review-discipline-principles.md) audit-class output discipline. Per the audit-framework charter body AC3, audit deliverables (framework + registry + future audit findings) use
observational language only. Prescriptive verbs (`recommend`, `migrate`, `consolidate`,
`should`) are out-of-bounds in audit content.

### Anthropic catalog source pinning

Cross-reference: §3.1 Anthropic Catalog Source Pinning (Hybrid baseline) below + the
`baseline_policy_reference` frontmatter field, which names the cross-domain
audit-baseline-when-target-population-is-empty discipline
(the D-Hub-3 file-overlap-audit precedent).

---

## §2 Audit Cadence

> **Strict scope note:** This section describes the cadence *policy*. Operationalization via
> `mcp__scheduled-tasks` cadence registration is **deferred to a successor release**. This release
> ships the framework + registry only; the successor wires the cadence task and integrates
> pmo-qa-auditor `platform-health` mode.

### Quarterly cadence

The registry MAY be re-audited quarterly. A quarterly drift check compares the current
Anthropic catalog (re-enumerated per §3.1) against the registry's last-recorded
`audit_baseline_sha` + `audit_baseline_date`. Drift items surface as audit findings; the
registry is updated per §3.3 (a/b/c) trigger taxonomy.

### Reactive cadence

Re-audit triggers fire when any of the following signals occur (event taxonomy per §3.5):

- (a) Anthropic publishes a new plugin pack to `~/.claude/plugins/cache/claude-plugins-official/`
- (b) Anthropic publishes a new `anthropic-skills:*` namespace skill (system-prompt
  available-skills list)
- (c) Anthropic deprecates an existing entry on either surface
- (d) PMO ships a new skill (entry added to `operations/skills/`) that may introduce a new
  overlap relationship with an existing Anthropic skill

### Operationalization (deferred to successor)

Cadence task registration via `mcp__scheduled-tasks` is **out of scope for this release (Strict scope)**.
The successor issue (filed at Stage 13 — see release plan §Stage 13 Obligations)
covers:

- `mcp__scheduled-tasks` quarterly registration with the §3.5 drift trigger conditions
- pmo-qa-auditor `platform-health` mode integration (§4 placeholder cross-ref)
- Inaugural audit folder (`pmo-platform/analysis/platform-health-2026-XX-XX/`)
- OPERATIONS.md Platform Health Audit Protocol section
- Drift detection demonstration (§3.5 trigger types exercised in inaugural audit)
- Owner-authored Overlap Detection Rubric + Scorecard Weighting (registry header)

### Cross-reference

The successor issue at Stage 13 close per this release plan completes the cadence
operationalization layer.

---

## §3 Methodology

### §3.1 Anthropic Catalog Source Pinning (Hybrid baseline)

The Anthropic skill catalog has multiple observable surfaces. Single-source choices have
coverage gaps. The framework adopts a Hybrid baseline (per the governing ADR):

#### Source A — plugin-pack catalog

**Enumeration command:**

```bash
find ~/.claude/plugins/cache/claude-plugins-official -maxdepth 4 -name "skills" -type d
```

The command returns plugin-pack `skills/` paths; iterate to enumerate individual skill names
within each pack. At audit-baseline SHA `4a943131c9e0323d5811f92704914657d7f7c314`
(2026-05-03), the command returns 9 paths covering 17 plugin-cache skills across these packs:
`agent-sdk-dev`, `claude-code-setup`, `claude-md-management`, `code-review`, `code-simplifier`,
`commit-commands`, `explanatory-output-style`, `feature-dev`, `frontend-design`, `hookify`,
`learning-output-style`, `math-olympiad`, `mcp-server-dev`, `playground`, `plugin-dev`,
`pr-review-toolkit`, `ralph-loop`, `security-guidance`, `skill-creator` (19 plugin packs;
9 of them ship a `skills/` subdirectory).

#### Source B — `anthropic-skills:*` namespace

**Enumeration method:** Read the system-prompt available-skills list at audit baseline; filter
to entries with the `anthropic-skills:*` prefix.

At audit-baseline SHA `4a943131c9e0323d5811f92704914657d7f7c314` (2026-05-03), the namespace
contains 9 skills: `setup-cowork`, `xlsx`, `skill-creator`, `pptx`, `pdf`,
`consolidate-memory`, `schedule`, `docx`, `prompt-builder`.

#### Hybrid

The Hybrid baseline = Source A ∪ Source B, deduped on skill name. Each registry row carries an
`anthropic_skill_provenance` tag recording which surface(s) the skill was observed in
(`plugin-cache` / `anthropic-skills` / `both`). For example:

- `skill-creator` appears in both surfaces → provenance `both`
- `prompt-builder` appears only in Source B → provenance `anthropic-skills`
- `frontend-design` (skill within plugin pack) appears only in Source A → provenance `plugin-cache`

#### Baseline anchor

Each audit pins:

- `audit_baseline_sha`: SHA of repo HEAD at audit start (recorded in registry header
  frontmatter)
- `audit_baseline_date`: ISO date of audit (recorded in registry header frontmatter)

The pinned baseline travels with the registry. Future audits update the header per §3.3
trigger taxonomy.

#### Reproducibility

Any reader can re-run the §3.1 enumeration commands at any future SHA + date and observe
drift versus the recorded baseline.

#### Pattern reference

Per the audit-baseline-when-target-population-is-empty discipline
and the D-Hub-3 file-overlap-audit precedent: when a target
population is heterogeneous (multiple sources differ) OR transiently empty (open PRs = []),
Hybrid baseline = SHA pin + observation-window anchor is the canonical mitigation.

### §3.2 Overlap Classification Enum

The closed 4-element enum (per the governing ADR, D-Plan-2b):

| Value | Definition |
|---|---|
| `extends` | PMO skill wraps, augments, or builds on top of an Anthropic skill (e.g., `pmo-skill-refiner` extends `anthropic-skills:skill-creator`) |
| `replaces` | PMO skill performs the same role as an Anthropic skill in the PMO context (e.g., `prompt-builder` namespace collision) |
| `independent` | No direct Anthropic counterpart observed in the Hybrid baseline |
| `pass-through` | PMO skill delegates fully to an Anthropic skill (no current instances; reserved for future) |

#### Free-form `overlap_notes` column

The `overlap_notes` column captures edge-case fidelity (partial-subset, namespace-alias,
intentional-fork rationale, asymmetric coupling intensity, canary-status reference) without
enum bloat. Use cases:

- Namespace collision (`prompt-builder`) — `overlap_notes` describes the intentional separation
  between PMO's and Anthropic's same-named skill
- Asymmetric coupling — `overlap_notes` discloses when an `extends` relationship is
  specialization-by-functional-overlap rather than explicit-wrapping (e.g., `pmo-skill-editor`
  vs. `pmo-skill-refiner`)
- Canary status — the source-only canary row carries `overlap_notes` referencing ADR-04
- Future Anthropic releases that introduce truly novel overlap relationships — `overlap_notes`
  describes the new shape without forcing an enum change

#### Observational discipline

Classifications describe observed conditions only. They do NOT prescribe migration,
consolidation, or build-vs-buy actions (per the audit-framework charter body AC3). The `build_buy_observation` column (renamed from M-AC2's
`build_buy_recommendation` per the governing ADR) is similarly observational — it describes the
observed state, not an action item.

### §3.3 Registry Update Protocol (per M-AC4)

Three trigger types govern registry updates:

#### (a) New PMO skill built

Trigger: a new entry is added to `operations/skills/<new-skill>/`.

Update steps:

1. At skill creation, the skill author re-runs §3.1 Hybrid baseline enumeration.
2. Author classifies the new skill against the (re-enumerated) Anthropic catalog.
3. Add a new row to the registry; commit alongside the new SKILL.md in the same PR.
4. Update registry header `audit_baseline_sha` + `audit_baseline_date` to the commit SHA +
   creation date.

#### (b) Anthropic releases new skill

Trigger: detected via plugin-cache directory diff or system-prompt
`anthropic-skills:*` namespace diff (vs. last-recorded baseline).

Update steps:

1. Add the new Anthropic skill to the baseline-source-of-truth subsection (§3.1 Source A or
   Source B as applicable).
2. Walk the 22 PMO source-roster skills; check whether the new Anthropic skill creates new
   overlap relationships with any.
3. For affected PMO skills, update `anthropic_overlap_status`, `anthropic_skill_ref`,
   `anthropic_skill_provenance`, and `overlap_notes`.
4. Update registry header `audit_baseline_sha` + `audit_baseline_date`.

#### (c) Anthropic deprecates existing skill

Trigger: detected via plugin-cache removal or namespace removal (vs. last-recorded baseline).

Update steps:

1. For PMO skills that referenced the deprecated Anthropic skill via `anthropic_skill_ref`,
   update `anthropic_overlap_status`.
2. If `anthropic_overlap_status` was `extends` or `replaces`, re-classify against the
   post-deprecation Anthropic catalog (likely → `independent` post-deprecation).
3. Add `overlap_notes` documenting the deprecation date + new status.
4. Update registry header `audit_baseline_sha` + `audit_baseline_date`.

### §3.4 Baseline-Empty Policy Reference

When the audit's target population is empty or heterogeneous at audit baseline (multi-source
Anthropic catalog with body-cited packs absent — exactly this release's situation), apply the
Hybrid baseline pattern per the
audit-baseline-when-target-population-is-empty discipline:

- Pin baseline to commit SHA + observation date
- Document the pinned baseline in BOTH the framework doc header AND the registry header
- Re-check at any future audit revision to detect drift versus the recorded baseline

The pattern emerged at the file-overlap-audit (D-Hub-3) and was promoted to permanent feedback memory at
this release's Stage 4 close (2026-05-03) per the N=2 emergence threshold in
[decision-discipline.md](../../../core/disciplines/decision-discipline.md) §4.2.

### §3.5 Drift Trigger Conditions (event taxonomy)

Drift triggers documented for the successor's `mcp__scheduled-tasks` registration:

| Trigger ID | Surface | Detection signal | Update path |
|---|---|---|---|
| T1 | Plugin-cache | `find ~/.claude/plugins/cache/claude-plugins-official -maxdepth 4 -name "skills" -type d` returns new path(s) vs. last baseline | §3.3 (b) |
| T2 | Plugin-cache | `find` returns fewer paths vs. last baseline (existing pack disappeared) | §3.3 (c) |
| T3 | `anthropic-skills:*` namespace | New entry observed in system-prompt available-skills list | §3.3 (b) |
| T4 | `anthropic-skills:*` namespace | Existing entry removed from system-prompt available-skills list | §3.3 (c) |
| T5 | PMO source roster | New entry in `operations/skills/` (verifiable via `ls -1 operations/skills/ release/skills/ core/skills/`) | §3.3 (a) |

---

## §4 Integration with pmo-qa-auditor

> **DEFERRED to a successor issue.** The pmo-qa-auditor `platform-health` mode will
> consume this registry as input to its observational audit output. Mode integration is out
> of scope for this release (Strict scope); see successor issue filed at Stage 13 (per the
> milestone description scope-partition + this release plan's §Stage 13 Obligations).

Cross-reference for the successor implementer:

- This framework doc + the [registry instance](../../../core/specs/anthropic-base-vs-build-registry.md) are
  the inputs to `platform-health` mode.
- Mode integration includes: registry consumption, observational discipline enforcement
  (cross-ref [review-discipline-principles.md](../../../core/disciplines/review-discipline-principles.md)), drift
  detection demonstration (per §3.5), and inaugural audit folder creation under
  `pmo-platform/analysis/platform-health-YYYY-MM-DD/`.
- Owner-authored content (Overlap Detection Rubric + Scorecard Weighting) populates the
  registry header at the successor release (per the audit-framework charter body AC6 + AC7).

---

**End of framework.**

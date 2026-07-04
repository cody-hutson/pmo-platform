---
title: Upstream-Reference Catalog — PMO Skill Artifacts
purpose: Codifies the canonical upstream (Anthropic-compatibility) sources for PMO skill artifacts — the catalog the D-Gate template and Collective Review cross-D scan check skill artifacts against.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the D-Gate Template (hub-spoke-bridge.md); the Collective Review cross-D scan; design-principle-register.md (structural twin); skill-artifact authors verifying Anthropic-compatibility
---
<!-- reference-durability: allow-link -->
# Upstream-Reference Catalog — PMO Skill Artifacts

**Origin:** R2 (Upstream Compatibility Check) — process-hardening defense-in-depth bundle.
**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Primary consumers:** Operator Decision Gate at Stage 4 ([`hub-spoke-bridge.md` §D-Gate Template](../../release/references/how-to/hub-spoke-bridge.md)); Collective Review Decision Briefing at Stage 5→6 ([`.claude/rules/release-process.md`](../../release/governance/release-process.md) Collective Review Protocol bullet 5).
**Secondary consumers:** Stage 5 Solutioning spokes producing Evidence-Grounding artifacts ([`evidence-grounding-standard.md`](evidence-grounding-standard.md) — upstream-reference is one of three justification categories).

## Purpose

Codifies the canonical upstream sources for PMO skill artifacts. The D-Gate Template in [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) and the Collective Review Protocol cross-D scan in [`.claude/rules/release-process.md`](../../release/governance/release-process.md) consult this catalog when rendering Upstream Compatibility verdicts (aligned / diverged-with-rationale / N/A). The catalog gives future spokes a queryable surface — replacing tacit knowledge held by individual operators with a documented reference.

R2 net new work is this catalog. The D-Gate Template's per-D Upstream Compatibility subsection (existed since 2026-04-26) and the CR Protocol cross-D scan (already existing) already enforce verdict scaffolding at the Operator Decision Gate; this catalog is the durable surface those scaffolds consult.

## Schema (per-entry)

| Field | Type | Purpose |
|---|---|---|
| `artifact_class` | string (kebab-case) | E.g., `skill-md-frontmatter`, `skill-references-directory`, `skill-md-body-anatomy` |
| `upstream_source` | string | Canonical authority (e.g., `anthropic-skills:skill-creator` SKILL.md) |
| `upstream_citation` | path + line | Exact file:line pin (e.g., `~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/SKILL.md:1-4`) |
| `upstream_required` | string list | Fields/conventions the upstream marks REQUIRED |
| `upstream_optional` | string list | Fields/conventions the upstream marks OPTIONAL |
| `pmo_extensions` | object list | PMO-specific extensions over upstream — each names: extension field, governing doc, rationale |
| `pmo_restrictions` | object list | PMO-specific narrowing of upstream — each names: restriction, governing doc, rationale |
| `drift_check_protocol` | string | How to verify the catalog entry remains accurate (manual review cadence + drift signal) |
| `last_verified_date` | ISO date | Most recent drift check |
| `last_verified_commit` | short SHA | Commit SHA at verification |

## Entries

### Entry: skill-md-frontmatter

This entry is the **D-Version case study** worked example referenced in the originating release body. The Anthropic upstream `skill-creator` produces `name` + `description` frontmatter only; PMO's D-Version adds `version:` as required. The catalog entry codifies the divergence so future spokes consult the entry rather than re-discovering it.

| Field | Value |
|---|---|
| `artifact_class` | `skill-md-frontmatter` |
| `upstream_source` | `anthropic-skills:skill-creator` |
| `upstream_citation` | `~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/SKILL.md:1-4` |
| `upstream_required` | `name`, `description` |
| `upstream_optional` | (none documented in upstream SKILL.md frontmatter) |
| `pmo_extensions` | `[{field: "version", governing: "version-field-semantics.md", rationale: "Platform release tag at last material edit; dual-gate enforced per D-Version (PreToolUse hook + deploy.sh --check)"}]` |
| `pmo_restrictions` | `[{restriction: "description triggering accuracy convention", governing: "canonical-skill-structure.md", rationale: "PMO triggering tuning per skill-creator README guidance"}]` |
| `drift_check_protocol` | "Verify Anthropic SKILL.md at upstream_citation on every minor PMO release (manual read of frontmatter lines 1-4); surface drift via Stage 13 Close re-verification + Tier 2 [SCOPE CHANGE] for next-release remediation. Future deploy.sh --check Check (deferred — see Drift-check protocol § below). Now also enforced at runtime as invariant A1 by the pmo-skill-refiner pre-injection scaffolder-drift guard (`scripts/quick_validate.py::assert_scaffolder_skeleton`)." |
| `last_verified_date` | `2026-06-11` |
| `last_verified_commit` | `353ad8b` |

> Re-verified 2026-06-08 (v1.08 scaffolder-drift guard): upstream required frontmatter set unchanged (still exactly `name` + `description`). One BENIGN non-structural drift observed — the upstream `description` *text* differs between the two installed copies (cache: "update or optimize"; marketplace: "edit, or optimize"); the required *field set* is unchanged, so this does not affect the asserted invariant. The guard deliberately does NOT assert description wording.
> Re-verified 2026-06-11 (v1.09 agent-script-promotion D-2 side effect): `head -6` on both installed copies — required field set unchanged (exactly `name` + `description`); the benign description-text drift between cache and marketplace copies persists.

**D-Version case study application** — how future spokes use this entry:

1. Stage 4 Operator Decision Gate produces D-decision touching skill frontmatter (e.g., adding new required field, changing required-status).
2. D-Gate spoke reads this entry's `upstream_required` / `upstream_optional` / `pmo_extensions`.
3. D-Gate spoke renders Upstream Compatibility verdict per the D-Gate Template applicability rule:
   - `aligned` — D-decision does not change upstream-required set
   - `diverged-with-rationale` — D-decision adds a PMO extension; rationale references this entry's `pmo_extensions[].governing` (e.g., `version-field-semantics.md` for the `version:` field)
   - `N/A` — D-decision does not modify skill-authoring surface (per D-Gate Template applicability)
4. Collective Review Protocol bullet 5 cross-D scan reads the verdict and aggregates with other D-decisions' Upstream Compatibility findings.

### Entry: skill-references-directory

| Field | Value |
|---|---|
| `artifact_class` | `skill-references-directory` |
| `upstream_source` | `anthropic-skills:skill-creator` |
| `upstream_citation` | `~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/SKILL.md` §Anatomy of a Skill (skill-creator scaffolder uses `references/` plural directory name) |
| `upstream_required` | `references/` (plural) when reference files apply |
| `upstream_optional` | reference files themselves are context-dependent |
| `pmo_extensions` | `[{field: "D-Refs threshold", governing: "canonical-skill-structure.md § 2", rationale: "PMO mandates references/ when skill has sufficient procedural complexity; threshold is context-dependent per D-Refs"}]` |
| `pmo_restrictions` | (none) |
| `drift_check_protocol` | "Verify Anthropic skill-creator scaffolder output on Anthropic skills framework release; surface drift via Stage 13 Close re-verification. Now also enforced at runtime as invariant A2 by the pmo-skill-refiner pre-injection scaffolder-drift guard (`scripts/quick_validate.py::assert_scaffolder_skeleton`) — singular-`reference/` rejection; absence of `references/` is not a failure (upstream-optional)." |
| `last_verified_date` | `2026-06-11` |
| `last_verified_commit` | `353ad8b` |

> Re-verified 2026-06-08 (v1.08 scaffolder-drift guard): upstream §Anatomy still shows the `references/` (plural) directory name; the convention is unchanged. (Benign upstream `description`-text drift noted on the `skill-md-frontmatter` entry does not touch this invariant.)
> Re-verified 2026-06-11 (v1.09 agent-script-promotion D-2 side effect): §Anatomy `references/` (plural) convention unchanged at the cited lines.

**Retrospective evidence:** This entry's `references/` plural canonical resolves the `reference/` vs `references/` 4-way disagreement caught at Stage 7 DT. Future Stage 5 spokes consult this entry when canonicalizing skill directory conventions — the upstream-aligned plural form is the documented canonical.

### Entry: skill-md-body-anatomy

| Field | Value |
|---|---|
| `artifact_class` | `skill-md-body-anatomy` |
| `upstream_source` | `anthropic-skills:skill-creator` |
| `upstream_citation` | `~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/SKILL.md` §Anatomy of a Skill |
| `upstream_required` | H1 skill title + body sections per Anthropic skill-creator §Anatomy |
| `upstream_optional` | section ordering varies by skill |
| `pmo_extensions` | `[{field: "Guardrails (Platform) + Domain-Specific Failure Modes sections", governing: "failure-mode-standard.md + canonical-skill-structure.md", rationale: "PMO mandates structured failure-mode discipline per ≥3 domain-specific anti-patterns enforced at G7 gate"}]` |
| `pmo_restrictions` | `[{restriction: "Body sections follow canonical structure", governing: "canonical-skill-structure.md", rationale: "Triggering accuracy + downstream skill discoverability"}]` |
| `drift_check_protocol` | "Verify Anthropic skill-creator SKILL.md §Anatomy on Anthropic skills framework release; surface drift via Stage 13 Close re-verification. Now also enforced at runtime as invariant A3 by the pmo-skill-refiner pre-injection scaffolder-drift guard (`scripts/quick_validate.py::assert_scaffolder_skeleton`) — asserts ≥1 top-level `#` H1 in the post-frontmatter body." |
| `last_verified_date` | `2026-06-11` |
| `last_verified_commit` | `353ad8b` |

> Re-verified 2026-06-08 (v1.08 scaffolder-drift guard): upstream §Anatomy + §Progressive Disclosure intact; the required body anatomy (H1 title + body sections) is unchanged. (Benign upstream `description`-text drift noted on the `skill-md-frontmatter` entry does not touch this invariant.)
> Re-verified 2026-06-11 (v1.09 agent-script-promotion D-2 side effect): §Anatomy intact (H1 + body-section convention unchanged).

### Entry: skill-progressive-disclosure

| Field | Value |
|---|---|
| `artifact_class` | `skill-progressive-disclosure` |
| `upstream_source` | `anthropic-skills:skill-creator` |
| `upstream_citation` | `~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/SKILL.md` §Progressive Disclosure |
| `upstream_required` | SKILL.md as the entry point; references/ for detail; scripts/ for executables |
| `upstream_optional` | references/ count and granularity varies by skill |
| `pmo_extensions` | `[{field: "PMO-specific reference patterns (e.g., specs/, protocols/)", governing: "canonical-skill-structure.md", rationale: "PMO skills produce additional reference categories beyond Anthropic baseline"}]` |
| `pmo_restrictions` | (none) |
| `drift_check_protocol` | "Verify Anthropic skill-creator SKILL.md §Progressive Disclosure on Anthropic skills framework release." |
| `last_verified_date` | `2026-06-11` |
| `last_verified_commit` | `353ad8b` |

> Re-verified 2026-06-11 (v1.09 agent-script-promotion D-2 side effect): §Progressive Disclosure intact — SKILL.md entry point, `references/` for detail, `scripts/` for executables; the repeated-helper-work → bundle-and-cite guidance ("put it in `scripts/`, and tell the skill to use it") verbatim at the cited section. First re-verification since 2026-05-16.

### Entry: github-issue-dependencies

This entry codifies GitHub's native issue dependencies API (GA August 2025). PMO adoption is governed by [`ticket-information-architecture.md § Native Dependencies`](../../release/references/specs/ticket-information-architecture.md#native-dependencies) under Model A (body→native one-way mirror, body remains authoritative). Source: Stage 5 design.

| Field | Value |
|---|---|
| `artifact_class` | `github-issue-dependencies` |
| `upstream_source` | GitHub Issues platform — native `blocks` / `blocked-by` API (GA Aug 2025) |
| `upstream_citation` | GitHub REST API: `repos/{owner}/{repo}/issues/{issue_number}/dependencies/{blocked_by,blocking}`; GitHub GraphQL API: `addIssueDependency` / `removeIssueDependency` mutations |
| `upstream_required` | Issue node ID (resolved via `gh api graphql -f query='{ repository(owner: "...", name: "...") { issue(number: <N>) { id } } }'`); valid `blocks`/`blocked-by` directionality |
| `upstream_optional` | Per-issue dependency cap (50 native deps per issue — upstream limit, non-configurable) |
| `pmo_extensions` | `[{field: "Typed-dep schema (FS/SS/FF/SF + lead/lag) in body Dependencies field", governing: "ticket-information-architecture.md § Dependencies Field — Typed Schema", rationale: "PMBOK CPM convention is richer than native blocks/blocked-by single-semantic; typed schema is body-only; native mirrors only the FS+0d subset"}, {field: "Body-as-authority invariant", governing: "ticket-information-architecture.md § Conflict Resolution", rationale: "Body remains authoritative; native is a projected display surface. AC#4 reframed at Collective Review 2026-05-22 — drift-detection replaces literal bidirectional auto-sync"}, {field: "Stage 2 A3.5 native-mirror substep", governing: "pipeline/stage-02-triage.md § Native-Dep Mirror", rationale: "One-way mirror fires after G2-04 dependency validation passes; non-gate-blocking; idempotent"}, {field: "deploy.sh Check 21 drift detection", governing: "deploy.sh Check 21", rationale: "Workspace-wide body↔native parity check; warn-mode initial per bypass-mode-readiness.md shakedown precedent"}]` |
| `pmo_restrictions` | `[{restriction: "Native mirror is one-way (body→native only)", governing: "ticket-information-architecture.md § Native Dependencies — Adoption Model", rationale: "Bidirectional sync would invert body-as-authority; one-way + drift-detection preserves the invariant"}, {restriction: "Only FS+0d subset of typed body deps mirrors to native", governing: "ticket-information-architecture.md § Native Dependencies — Adoption Model", rationale: "Native blocks/blocked-by lacks expressivity for SS/FF/SF + lead/lag — those types stay body-only by design"}]` |
| `drift_check_protocol` | Per-release verification at Stage 13 Phase A4.5 (re-run mirror algorithm as parity-check; report drift in Verification Evidence). Workspace-wide drift detection via `deploy.sh --check` Check 21 (warn-mode initial; flip-to-enforce after 2-3 release shakedown). Cap-handling: if `addIssueDependency` returns "cap reached" (50/issue), flag to operator and suspend further mirror writes for that issue; body remains authoritative without native projection. |
| `last_verified_date` | `2026-05-22` |
| `last_verified_commit` | `0f7c9ee` (Engineering Commit 0) |

**Case study application** — how future spokes use this entry:

1. Stage 5 spoke producing a D-decision touching dependency-tracking surfaces (e.g., new dependency edge semantics, new dependency-graph algorithm input) reads this entry's `upstream_required` / `upstream_optional` / `pmo_extensions` / `pmo_restrictions`.
2. D-Gate spoke renders Upstream Compatibility verdict per the D-Gate Template applicability rule:
   - `aligned` — D-decision adopts native blocks/blocked-by verbatim
   - `diverged-with-rationale` — D-decision modifies the mirror subset or invariants; rationale references this entry's `pmo_extensions[].governing` or `pmo_restrictions[].governing`
   - `N/A` — D-decision does not touch dependency-tracking surface
3. Collective Review Protocol bullet 5 cross-D scan aggregates with other D-decisions' Upstream Compatibility findings.

### Entry: github-comment-author-association

Codifies the host's comment author-association field, which the author-association trust boundary ([`release-process.md` § Inter-Stage Feedback Protocol](../../release/governance/release-process.md#inter-stage-feedback-protocol)) gates on. Source: Stage 5 design.

| Field | Value |
|---|---|
| `artifact_class` | `github-comment-author-association` |
| `upstream_source` | GitHub Issues/Pulls — comment `author_association` field (REST) / `CommentAuthorAssociation` enum (GraphQL) |
| `upstream_citation` | GitHub REST issue/PR/review-comment payloads (`author_association`); GraphQL `CommentAuthorAssociation` |
| `upstream_required` | Enum: `OWNER`, `MEMBER`, `COLLABORATOR`, `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `FIRST_TIMER`, `MANNEQUIN`, `NONE` |
| `upstream_optional` | — (closed enum; host-computed, not settable) |
| `pmo_extensions` | Trusted-set partition `{OWNER, MEMBER, COLLABORATOR}` vs untrusted (rest) — governing doc: the § Inter-Stage Feedback Protocol boundary block. Rationale: `OWNER` and `COLLABORATOR` are the write-bearing associations on this user-owned, no-external-PR repository; `MEMBER` is an organization-membership relationship (not necessarily a write grant) included as a deliberate forward trust statement for a future org migration — NOT a zero-cost widening. The trusted set must be re-examined at any org migration (a populated `MEMBER` set would otherwise admit non-write accounts, and `drift_check_protocol` below does not catch it because no enum value changes). |
| `pmo_restrictions` | Pipeline readers never treat untrusted-association comments as stage content/instructions/evidence (surfaced-untrusted handling) |
| `drift_check_protocol` | On host API version migration or enum-change announcement, re-verify the enum set; drift signal: a new association value in live `gh api` comment reads |
| `last_verified_date` | `2026-07-04` |
| `last_verified_commit` | `c9ed39c` (Engineering Commit 0) |

### Entry: stakeholder-comms-structure

This entry is the **first non-skill-creator upstream** and the worked example for the
skill-sourcing-coupling posture ADR (own-with-harvest). comms-writer **owns** stakeholder-email
+ executive-brief generation first-party; Anthropic's `product-management/stakeholder-comms` is a
**design-time** harvest reference (structure/phrasing patterns), never a runtime call. The
posture is governed by [ADR-023](../ADRs/ADR-023-skill-sourcing-coupling-posture.md)
(skill-sourcing-coupling: own-with-harvest default; stakeholder-facing generation never takes a
runtime Anthropic dependency). Source: Stage 5 design.

| Field | Value |
|---|---|
| `artifact_class` | `stakeholder-comms-structure` |
| `upstream_source` | `anthropic-skills:product-management/stakeholder-comms` (or plugin-cache equivalent) |
| `upstream_citation` | Not locally installed at 2026-06-13 (the installed plugin-cache holds `skill-creator` only; the `product-management` pack is absent); harvest from the published Anthropic skill catalog. Re-pin to the installed `stakeholder-comms` SKILL.md path:line on the first release where the pack is locally present. |
| `upstream_required` | (harvest reference — comms-writer owns generation; the upstream marks no field REQUIRED on PMO output) |
| `upstream_optional` | stakeholder-comms structural patterns: audience framing, decision-forward ordering, ask-with-deadline close |
| `pmo_extensions` | `[{field: "PMO-critical rules at generation", governing: "comms-writer/SKILL.md § PMO-Critical Rules + § Domain-Specific Failure Modes", rationale: "no internal IDs / evidence labels / readiness gate / Dual-Framing Bridge / project-context applied first-party at generation, not portable via upstream prompting"}, {field: "voice-guide.md + audience-profiles.md", governing: "comms-writer/references/", rationale: "PMO voice + named audience profiles are first-party assets; upstream provides generic structure only"}]` |
| `pmo_restrictions` | `[{restriction: "No runtime Anthropic invocation for stakeholder-facing generation", governing: "ADR-023 (skill-sourcing-coupling posture)", rationale: "stakeholder-facing = highest blast radius; never runtime-coupled — silent upstream drift must not change an executive briefing"}]` |
| `drift_check_protocol` | "Harvest reference only — drift does not alter runtime behavior (comms-writer owns generation). Re-read upstream `stakeholder-comms` SKILL.md per minor PMO release per ADR-023 §Consequences harvest cadence; on observed structural drift, surface as Tier 2 [SCOPE CHANGE] for a next-release harvest refresh. Bump `last_verified_date` + `last_verified_commit` on each re-verification." |
| `last_verified_date` | `2026-06-13` |
| `last_verified_commit` | `9409bdb` |

[+ additional entries as future spokes discover them; catalog is extensible — new entries follow the same schema and reference patterns]

## Drift-check protocol (catalog hygiene)

The catalog itself is subject to upstream drift. Mitigation:

| Mechanism | Detail |
|---|---|
| Per-release catalog re-verification | Stage 13 Close adds a 1-line check: re-read upstream SKILL.md(s) cited in catalog; verify `upstream_required` / `upstream_optional` unchanged. Bump `last_verified_date` + `last_verified_commit` per affected entry on drift. |
| Future `deploy.sh --check` Check (deferred) | Future check that reads catalog entries' `upstream_citation` and compares against current upstream content. **Not in scope yet** — manual re-verification suffices at current volume (~4 catalog entries). When catalog exceeds ~20 entries, file follow-up issue. |
| Catalog drift surfaces as Tier 2 [SCOPE CHANGE] | If a release's Stage 13 catalog re-verification finds drift, surface as Tier 2 [SCOPE CHANGE] per [`.claude/rules/release-process.md`](../../release/governance/release-process.md) Inter-Stage Feedback Protocol for next-release remediation. |

## Cross-references

| Surface | Reference | Role |
|---|---|---|
| D-Gate Template | [`hub-spoke-bridge.md` §D-Gate Template](../../release/references/how-to/hub-spoke-bridge.md) | Per-D Upstream Compatibility verdict scaffolding consults this catalog |
| Collective Review Protocol | [`.claude/rules/release-process.md` Collective Review Protocol bullet 5](../../release/governance/release-process.md) | Cross-D upstream-compatibility scan consults this catalog |
| Parent framework binding | [`decision-discipline.md` § 7.4](../disciplines/decision-discipline.md) | Mechanism 1 (Localization Check) application at D-decision-content level |
| Evidence-Grounding standard | [`evidence-grounding-standard.md`](evidence-grounding-standard.md) | Upstream-reference is one of three justification categories |
| Version-field-semantics | [`version-field-semantics.md`](version-field-semantics.md) | D-Version case study governance doc; cited in `skill-md-frontmatter` entry |
| Canonical skill structure | [`canonical-skill-structure.md`](canonical-skill-structure.md) | Skill structure governance; cited in `skill-references-directory` + `skill-md-body-anatomy` entries |
| Skill-sourcing-coupling posture | [`ADR-023`](../ADRs/ADR-023-skill-sourcing-coupling-posture.md) | Own-with-harvest sourcing posture; governs the `stakeholder-comms-structure` entry (first non-skill-creator upstream) |

## Cutover

**Applies to:** all D-decisions rendered at the Operator Decision Gate (Stage 4) going forward. The catalog-consultation discipline applies prospectively to all D-decisions after this catalog takes effect.

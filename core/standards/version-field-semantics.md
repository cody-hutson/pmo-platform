# Version Field Semantics — PMO Skills

## Purpose

Defines the `version:` field in every PMO SKILL.md frontmatter — what it means, when it bumps, who maintains it, and what migration backfill values are appropriate.

## Definition

The `version:` field marks **the platform release tag at which this skill was last materially edited**. It is the operator-declared compatibility marker — a reader of the skill knows "this skill was validated against this platform release's contracts."

It is NOT:

- A semver version of the skill itself (skills sync with platform minor versions; they have no independent semver lifecycle)
- An mtime approximation (git provides that directly via `git log`)
- An automated value (operator declares at commit time; the field encodes intent, not state)

It IS:

- A human-declared release-baseline tag
- Enforced by dual-gate (PreToolUse hook + `deploy.sh --check`) per D-Version

## Format

`vMAJOR.MINOR` matching the platform release tag at edit time.

Regex: `^v[0-9]+\.[0-9]+(-[a-z]+)?$`

Examples: `v1.2`, `v1.3`, `v2.0`, `v1.2-canary`

Disallowed: `v1.2.1` (no patch level — skills sync with platform minor versions, not patches), `1.2` (missing v-prefix), `v1.2-beta-1` (multi-part suffix), `v1.2-20260421` (no date-stamped values).

**Canary sentinel:** `-canary` suffix allowed for `pmo-skill-refiner-selftest-canary` per ADR-04. No other skill may use a sentinel suffix.

**Chronological caveat.** This `version:` value is a *platform release tag*, and platform release tags are allocated at claim time and may ship out of numeric order: under parallel releases a higher-numbered release can merge and tag before a lower-numbered one. A skill's `version:` therefore marks the release it was validated against — not a chronological position in a sequence — so reading one skill's number as "edited after" another's lower number is unsound. How a release's `vMAJOR.MINOR` number is allocated (next-free-at-claim) and why numeric order is not ship order are defined by the milestone numbering convention in the Bundle Composition Doctrine; the runtime rule that ship order equals merge order equals tag order is defined by the parallel-release sequencing rules in that same doctrine.

## Bump Rules

Version bumps on **material edit**:

- Frontmatter changes (description, name, other metadata fields)
- Behavior changes (trigger phrases, mode definitions, process steps, failure modes)
- Output contract changes (sections, required elements, validation checks)
- Cross-reference changes (dependency-graph node, principal-standard target, shared contracts)
- Reversibility declaration or evidence-label usage changes

Version DOES NOT bump on:

- Typo fixes in prose that don't change meaning
- Whitespace / formatting-only changes
- Comment-only changes (e.g., clarifying an inline comment)

**Determination mechanism.** The bump / no-bump decision is held by `pmo-skill-editor` during a sanctioned editing session — not by a commit-message marker. The PreToolUse hook gates the edit attempt: direct Write/Edit on a migrated skill's SKILL.md or reference files is rejected unless a valid `pmo-skill-editor` session sentinel is present at `{core,operations,release}/skills/<skill>/.editor-session` (target-skill-matched, within 30-min TTL). Inside the sanctioned session, `pmo-skill-editor` is responsible for classifying the change as material vs cosmetic and bumping the `version:` field per § Bump Rules.

This puts the bump / no-bump decision under the editor's protocol — same forcing-function pattern as `git commit --allow-empty` requiring an explicit flag, but enforced via sentinel-based PreToolUse authorization rather than commit-message inspection.

## Maintenance Protocol (Dual-Gate per D-Version)

The dual-gate naming aligns with [`.claude/rules/skill-deployment.md`](../rules/skill-deployment.md) § Mandatory Tooling for Skill Edits: **Gate 1 = deploy-time spec-compliance check**; **Gate 2 = edit-time editor-invocation hook**. For the structural-contract authority on edit-time hook behavior, see [canonical-skill-structure.md](canonical-skill-structure.md) §2 + §6.

**Gate 1 — `deploy.sh --check` assertion** (built by  as Check 6 + Check 10 of the dual-gate framework):

- For each skill in the per-module arrays (`OPERATIONS_SKILLS`/`RELEASE_SKILLS`/`CORE_SKILLS`) + `SUPPLEMENTARY_SKILLS` + canary:
- Check 6 asserts: the `version:` field is present and matches the format regex
- Check 10 asserts (on migrated skills): the last non-merge commit touching the skill carries the `pmo-skill-editor` audit-trail trailer
- FAIL surfaces the skill path, current value (or missing-field signal), and last-touching commit SHA

**Gate 2 — PreToolUse hook** (built by  as [`.claude/hooks/block-skill-direct-edit.sh`](<OPERATOR_INSTANCE_CLAUDE_DIR>/hooks/block-skill-direct-edit.sh)):

- Layer: Claude Code PreToolUse hook — fires inside Claude Code when Write or Edit is attempted on a SKILL.md or `reference/*.md` / `references/*.md` path. Does NOT run at `git commit` time (this is not a git pre-commit hook).
- Matcher scope: `Write` and `Edit` tool calls targeting `{core,operations,release}/skills/*/SKILL.md`, `{core,operations,release}/skills/*/reference/*.md`, or `{core,operations,release}/skills/*/references/*.md`.
- Activation: only on skills whose frontmatter carries `skill_discipline_migrated_v10_2: true`. Pre-migration skills pass through (exit 0) — non-breaking-on-legacy by design per [`canonical-skill-structure.md`](canonical-skill-structure.md) §3 migration-marker semantics.
- Reject `BLOCK-SKILL-EDIT-001` (SKILL.md) / `BLOCK-SKILL-EDIT-002` (`reference/*.md` or `references/*.md`) when: (a) no `pmo-skill-editor` session sentinel at `{core,operations,release}/skills/<skill>/.editor-session`, OR (b) sentinel `target_skill` does not match the edit target, OR (c) sentinel `started_at` is older than the 30-minute TTL or in the future, OR (d) sentinel JSON is malformed.
- Allow when: (a) the sentinel is present, target-skill-matched, and within TTL — the sanctioned edit path per D-Editor, where `pmo-skill-editor` is responsible for bumping the `version:` field per § Bump Rules during the sanctioned session; OR (b) the skill appears in [`.claude/skill-editor-exemption-list.txt`](<OPERATOR_INSTANCE_CLAUDE_DIR>/skill-editor-exemption-list.txt) (canary + operator-approved exemptions).
- Bypass: set `CLAUDE_HOOK_BYPASS=1` in the operator-launched Claude Code shell (NOT `git --no-verify`; the hook does not run at git commit time). Audit-logged per [`.claude/rules/bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md).
- Warn/enforce posture: governed by [`.claude/hooks/.mode`](<OPERATOR_INSTANCE_CLAUDE_DIR>/hooks/.mode) per the shakedown-to-enforce transition documented in [`.claude/rules/bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist.

The two gates compose: edit-time enforcement via the PreToolUse hook (fast feedback during the edit attempt, before any commit is created) + deploy-time guarantee via `deploy.sh --check` (last line of defense before any release ships).

## Backfill Policy

All skills in `{operations,release,core}/skills/` migrate at the migration baseline. The post-migration state per the Stage 8 QA cohort split (15 + 1 + 5 + 1 = 22 source directories at the migration baseline):

| Cohort | Count | Backfill value | Rationale |
|---|---|---|---|
| Previously untouched | 15 | migration baseline | Migration commit IS a material edit (restores references, migrates vocabulary, applies canonical-spec compliance); commit's release baseline is the migration baseline |
| Previously untouched (re-touched but value unchanged — pmo-skill-editor) | 1 | migration baseline | Same rationale |
| No version field (non-canary) | 5 | migration baseline | First version baseline; migration commit registers the field |
| No version field (canary) | 1 | `-canary` sentinel | Canary sentinel preserves canary-by-design semantics while satisfying field-presence rule |

**Result.** Every skill post-migration carries the migration-baseline `version:` (or the `-canary` sentinel), establishing a clean baseline. Later releases bump only the skills that receive material edits via the editor-via-editor workflow; untouched skills retain the baseline per "validated against that baseline" semantics.

## NEW Skill Registration

When a new skill is added to `{operations,release,core}/skills/` and registered in `deploy.sh` per-module arrays (`OPERATIONS_SKILLS`/`RELEASE_SKILLS`/`CORE_SKILLS`) (or `SUPPLEMENTARY_SKILLS`):

1. Set `version: vX.Y` in frontmatter where `X.Y` matches the platform release tag at registration time (or the in-progress release tag if registering between tags, e.g., `v1.3` while v1.3 is being developed)
2. Canary skills (exempt from D-Refs per `canonical-skill-structure.md` §2) use `version: vX.Y-canary` sentinel format

**Rationale:** Anthropic's upstream `anthropic-skills:skill-creator` produces `name` + `description` frontmatter only. The `version:` field is a PMO-specific addition required by the dual-gate enforcement per D-Version. NEW skills stamped at registration satisfy `deploy.sh --check` Check 6's required-frontmatter assertion and remain compatible with the hook-based dual-gate on subsequent edits.

**Example:**

```yaml
---
name: new-skill-name
description: Does a specific thing for a specific use case
version: v1.3
---
```

## Scope of Enforcement

**Applies to:** Every SKILL.md in `{operations,release,core}/skills/*/`.

**Does NOT apply to:** Reference docs bundled under `{operations,release,core}/skills/<skill>/reference/` — those are skill-internal references, not SKILL.md itself.

**Canary exemption.** `pmo-skill-refiner-selftest-canary` is exempted from the references-required threshold per D-Refs. It is NOT exempted from the version-field requirement; it uses the `-canary` sentinel per § Format.

**NEW skill creation is non-enforced** through PMO tooling per D-Creator. New skills are scaffolded via Anthropic built-in `skill-creator` and adopt this contract on first commit. The forcing function applies to existing-skill modifications, not net-new creation.

## Consumer References

Tools and rules that reference this semantics doc:

- `deploy.sh --check` — Gate 1
- `.claude/hooks/block-skill-direct-edit.sh` — Gate 2
- `release/skills/pmo-skill-editor/SKILL.md` — editor workflow respects this contract
- `release/skills/pmo-skill-refiner/SKILL.md` — refiner workflow sets initial value at skill creation
- `.claude/rules/skill-deployment.md` (and engineering mirror) — deployment doc cross-references this
- [`core/skills/registry.md`](../skills/registry.md) — the skill catalog (CMDB) cites this doc as the authoritative home for the version-field contract

## Reversibility

**Tier:** MODERATE — Confidence: HIGH.

This contract governs every SKILL.md edit going forward. Reverting the contract means reverting the dual-gate hooks, the `version:` backfill across the full skill roster, and consumer references (this doc, dependency-graph, skill-deployment). Per-revert points are clean (one commit per migration), but the contract reverts as a unit.

## Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | 2026-04-22 | Initial release per the Skill Discipline. Defines field semantics, format regex, bump rules, dual-gate maintenance protocol, backfill policy. |
| 1.1 | 2026-06-21 | Adds the § Format chronological caveat: a skill's `version:` marks the release it was validated against, not a chronological ordinal, because release tags are allocated at claim time and may ship out of numeric order under parallel releases. Names the Bundle Composition Doctrine numbering convention + parallel-release sequencing rules as the homes for allocation and ship-order semantics. Prose-only, additive; the field, regex, and dual-gate are unchanged (Check 6 unaffected). |

---

**Document Owner:** PMO Engineering
**Status:** Active

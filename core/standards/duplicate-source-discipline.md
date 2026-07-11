---
title: Duplicate-Source Discipline — Register or Remove
purpose: "The register-or-remove discipline for content reused across files: duplicated content joins the enforced mirror set, consolidates to one canonical source, or is registered as an allowed exception."
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: deploy.sh Check 9 / Check 11 / Check 13 (mirror-set + template-sync registries); authors of any content reused across files; CLAUDE.md §Prefer durable structures
---
<!-- reference-durability: allow-link -->
# Duplicate-Source Discipline — Register or Remove

## Purpose

Defines the platform's discipline for content reused across multiple files: any duplicated content either (a) joins the registered mirror set and gains byte-identity enforcement, (b) is consolidated to a single canonical source with cross-references replacing former duplicate sites, or (c) is registered in a per-domain exemption list with rationale. Establishes the canonical home for the **register or remove** rule, consolidating three implicit anti-duplication guardrails in [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) into a single statement.

This is option (a) per the originating initiative's Stage 5 — documentation-only at current platform scale. Scan-based enforcement (future Check 14) is deferred per §6 escalation triggers; the **CONFLICT** with `anthropic-skills:skill-creator` convention that scan-based enforcement would introduce is preserved here for future re-evaluation, not resolved by enforcement today.

## §1 Principle — register or remove

Content MUST NOT exist in two or more files within `core/` / `release/` or `.claude/` unless one of three conditions holds:

1. **Registered as a mirror.** Both copies are listed in the platform's mirror registry and gain byte-identity enforcement under `deploy.sh --check` Check 9 / Check 11 / Check 13 (see §2). The system enforces drift detection.
2. **Consolidated to a canonical source.** Content lives in exactly one file; former duplicate sites are replaced with cross-references (markdown link to the canonical source).
3. **Registered exemption.** A per-domain exemption is documented in the principle that owns the duplicated surface (e.g., legitimate parallel structures across SKILL.md files governed by [canonical-skill-structure.md](canonical-skill-structure.md); see §3).

Unregistered duplicate content is governance debt. The longer it persists, the higher the drift risk: one copy is updated, the other becomes silently stale, and downstream consumers act on the stale read. The register-or-remove rule forecloses that path.

## §2 Registered enforcement layer

Three `deploy.sh --check` checks today provide byte-identity enforcement on registered mirror surfaces:

| Check | Surface | Enforcement | Source |
|---|---|---|---|
| **Check 9** — Rules-mirror sync | canonical source `core/rules/<name>.md` (for release-process.md the source is `release/governance/release-process.md`) ↔ deployed mirror `~/.claude/rules/<name>.md` | Byte-identity required; mismatch → DRIFT [SOURCE: `deploy.sh:1695`] | — |
| **Check 11** — Harness-mirror sync | `harness/<name>/` ↔ `~/.claude/<name>/` for every entry in `HARNESS_LIST` (currently `account-switcher`) | Byte-identity required on canonical files; operator-state files (per `HARNESS_OPERATOR_STATE` allowlist) preserved [SOURCE: `deploy.sh:1798`] | Per D-1.B |
| **Check 13** — Template-sync drift detection | `TEMPLATE_SYNC_MAP` byte-identity-enforced template pairs | Byte-identity required; matches Check 1 / Check 11 zero-FP posture [SOURCE: `deploy.sh:1929`] | — |

**Out of scope for these checks:**
- Content-level near-duplicates outside the registered mirror set (the gap this principle addresses).
- SKILL.md content duplicates across skills (governed by [canonical-skill-structure.md](canonical-skill-structure.md); see §3).

**Orthogonal:** `deploy.sh --check` Check 3 enforces filename-collision detection (APFS case-sensitivity duplicates in package staging); it covers a different duplicate class than this principle and complements rather than overlaps the register-or-remove rule.

## §3 Scope boundary

This principle covers **content-level duplicates outside the registered mirror set** within `core/` and `release/` (governance, reference/standards/specs/schemas/disciplines, releases) and `.claude/rules/` and workspace-root governance files (CLAUDE.md, README.md).

**Out of scope — governed elsewhere:**
- **SKILL.md boilerplate across skills** is governed by [canonical-skill-structure.md](canonical-skill-structure.md) (the canonical home for skill-authoring discipline). Skills MAY share boilerplate text by design; this preserves compatibility with `anthropic-skills:skill-creator` convention. Any future scan-based enforcement (see §6) MUST exclude `<module>/skills/` from its scope.
- **Filename-collision duplicates** are covered by `deploy.sh --check` Check 3 (orthogonal — see §2 footer).
- **Layer 2 operational content** (`projects/`) is Cowork-managed and outside the engineering governance surface.

## §4 Authoring-time check (operative gate today)

The operative enforcement mechanism at current platform scale is the [CLAUDE.md "Pre-creation governance check" guardrail](<OPERATOR_INSTANCE_CLAUDE_MD>) (line 134):

> Before authoring a new file or artifact, search existing governance for a defined home for that data type. CLAUDE.md governance file map, OPERATIONS.md operational artifacts table, and `pipeline/` stage outputs are the canonical lookup surfaces — milestone descriptions, SKILL.md sections, and reference docs are common pre-defined homes. Authoring a parallel artifact when a governed home exists violates "No ungoverned changes" AND duplicates the governance contract. Cite the search result before drafting any new file.

This guardrail catches duplicate sources at authoring time before they enter the corpus. It is human-in-the-loop and judgment-based; no automated scan runs at deploy.

The companion guardrails this principle consolidates:

- **Intermediate-artifact discipline** ([CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 135) — sizing analyses, scratch breakdowns, and reorganization workings are absorbed into the target structure, not promoted to durable artifacts. Prevents stepping-stone artifacts from accumulating as parallel sources.
- **Prefer durable structures over static examples** ([CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 158) — decision tables, schemas, and parameterized templates are preferred over prose duplication. Prevents the "copy the table into both files" anti-pattern.

Together these three guardrails ARE the platform's anti-duplication enforcement at current scale. This principle doc is their single canonical statement.

## §5 Periodic audit

Operator review for emergent duplicate content occurs at:

1. **Stage 3 Bundle gate.** When bundling release scope, the Stage 3 Pre-creation governance check ([CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 134) covers duplicate-source-as-emergent-pattern. Newly proposed files are checked for canonical-home existence before authoring.
2. **Stage 4 Planning.** When contention maps surface during release planning, file-overlap-audit per `<OPERATOR_INSTANCE_ANALYSIS_PATH>/file-overlap-audit-<date>/` may incidentally surface content duplication along with file-edit contention.
3. **Opportunistic discovery.** Content drift discovered during normal operation (e.g., during `pmo-skill-editor` audits, `pmo-qa-auditor` reviews, governance file edits) is reported as a GitHub Issue per the [CLAUDE.md auto-logging rule](<OPERATOR_INSTANCE_CLAUDE_MD>).

No scheduled scan runs. The cadence is event-driven, not periodic.

## §6 Escalation trigger — future Check 14

Scan-based enforcement (option (b) per Stage 5 of the originating initiative) is deferred at current scale. Re-evaluation is warranted when ANY of the following triggers fire:

1. **Scale trigger.** Platform grows to ≥2× current governance / reference / rules file count (count baseline: SHA at merge of the originating initiative's implementation).
2. **Incident trigger.** ≥3 duplicate-source incidents surface in any 90-day window (incident = stale-read drift causing downstream defect; tracked via `gh issue list --search "is:issue label:bug duplicate-source in:title,body"`).
3. **Manual-review-failure trigger.** Operator manual review starts missing duplicates that subsequently cause drift incidents (signal: a duplicate-source incident is filed AFTER the duplicated content was reviewed at Stage 3 Bundle without being flagged).

When a trigger fires, the future deploy.sh hook is **Check 14** — NOT Check 13 (claimed by the template-sync-drift detection check). The numbering is reserved here to prevent collision at future Stage 4 planning.

### Pre-loaded design (CONFLICT mitigation preference order)

Scan-based enforcement would conflict with `anthropic-skills:skill-creator` convention — skills MAY share boilerplate text by design [SOURCE: convention review at the originating initiative's Stage 5, 2026-05-11]. When Check 14 ships, the CONFLICT MUST be resolved using the preference order rendered at the originating initiative's Stage 5:

1. **Preferred — scope-exclude `<module>/skills/` entirely.** Scan limited to `core/` and `release/` (governance, reference/standards/specs/schemas/disciplines, releases) + `.claude/rules/` + workspace-root governance files. Cleanest CONFLICT resolution; cleanly defers SKILL.md content discipline to [canonical-skill-structure.md](canonical-skill-structure.md).
2. **Section-exempt named SKILL.md boilerplate sections** (e.g., persona blocks, output-contract boilerplate) via section-anchor exemption registered in `.claude/duplicate-source-exemption-list.txt` (new file modeled on `.claude/skill-editor-exemption-list.txt`). Higher maintenance cost; consider only if Check 14 needs partial coverage of `skills/`.
3. **Document as PMO-only constraint with full exemption list.** Highest maintenance cost; consider only if (1) and (2) prove insufficient. Exemption list registered under "No ungoverned changes" protocol.

No exemption-list file is created. The principle doc names `.claude/duplicate-source-exemption-list.txt` as the future artifact (when Check 14 ships); creating an empty placeholder now would be ungoverned-theater (an enforcement surface with no enforcement behind it).

## §7 Cross-references

**Umbrella discipline (the broader authoring rule this register-or-remove principle is one facet of):**
- [minimal-addition-discipline.md](../disciplines/minimal-addition-discipline.md) — the **umbrella authoring discipline** (add the minimum that carries the meaning, in service of *simplicity*) that this register-or-remove rule is **one facet** of (the duplication facet).

**Consolidated guardrails (the three implicit anti-duplication rules this principle makes explicit):**
- [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 134 — Pre-creation governance check (operative gate)
- [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 135 — Intermediate-artifact discipline
- [CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) line 158 — Prefer durable structures over static examples

**Registered-mirror enforcement (the existing 3-check enforcement layer):**
- [.claude/rules/skill-deployment.md](../rules/skill-deployment.md) — Check 9 documentation (rules-mirror sync)
- [.claude/rules/harness-deployment.md](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/harness-deployment.md) — Check 11 documentation (harness-mirror sync)
- [deploy.sh](../deploy/deploy.sh) line 1929 — Check 13 implementation (template-sync drift)

**Out-of-scope governance home (preserves `anthropic-skills:skill-creator` compatibility):**
- [canonical-skill-structure.md](canonical-skill-structure.md) — SKILL.md content discipline canonical home

**Establishing initiative:**
- Originating initiative — Generalized duplicate-source detection beyond known mirror pairs

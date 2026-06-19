<!-- reference-durability: allow-link -->
# Release Corpus Schema — Frontmatter Contract for Plans + Notes

## Purpose

Defines the canonical YAML frontmatter schema applied to every artifact in the **release corpus** — the trio of `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`, `release/releases/plans/*.md`, and `release/releases/notes/*.md`. The schema is the structured-data substrate that powers `release/releases/RELEASE_INDEX.md` (navigation surface) and `release/releases/RELEASE_DIGEST.md` (zoom surface) without hand-curated cross-references.

Authored per the Stage 5 spec + Collective Review. Composes with [release-notes-standard.md](release-notes-standard.md) — that standard owns the user-facing note's BODY content rules; this schema owns the FRONTMATTER contract that lets the platform navigate and digest the corpus.

## Scope

| Artifact class | Path | Frontmatter required? | Schema applies from |
|---|---|---|---|
| Release plan | `release/releases/plans/*.md` | YES | Forward-only (per the historical-backfill umbrella) |
| Release note | `release/releases/notes/*.md` | YES | Forward-only (per the historical-backfill umbrella) |
| Abandoned plan | `release/releases/archive/plans/*.md` | YES | Forward-only |
| Phase plan | `release/releases/plans/v*-*_PHASE_PLAN.md` | YES (`type: phase-plan`) | Forward-only — pre-existing phase plans grandfathered with frontmatter only (filename retained) |
| Audit plan | `release/releases/plans/v*-*-audit_RELEASE_PLAN.md` | YES (`type: audit-plan`) | Forward-only |
| RELEASE_LOG row | `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` | NO (out of scope for this schema) | LOG-row schema owned elsewhere; this schema covers FILE-level frontmatter only |

**Forward-only adoption rationale:** Per the precedent that user-facing notes started at an earlier release (an umbrella campaign tracks retroactive coverage), this schema applies prospectively, forward-only, to bound R-1 restructure-integrity risk. Historical backfill of 76 pre-cutover files is registered as F-3 follow-up gated on schema utility.

## Field Specification

### Required fields (6)

| Field | Type | Format | Notes |
|---|---|---|---|
| `version` | string | `vMAJOR.MINOR[a-z]?[-suffix]` | MUST match the parent Milestone version exactly (e.g., `v1.04b-3`, `v1.03`) |
| `date` | string | ISO 8601 `YYYY-MM-DD` | Plan: date the plan was authored. Note: release publication date. Both reference the canonical date in the LOG row. |
| `type` | enum | One of: `plan`, `note`, `abandoned-plan`, `phase-plan`, `audit-plan` | Discriminator field — see [Type discriminator](#type-discriminator) below |
| `issues` | list of strings | `["#N", "#M", ...]` (each `#`-prefixed) | The release-scope issues. Plan: issues being implemented in this release. Note: issues whose user-visible changes are in this release. |
| `pr` | string or `null` | `"#PRN"` or `null` | Integration PR. `null` for plans authored before PR creation; populated at PR creation. Notes always reference a merged PR. |
| `links` | object | See [Links shape](#links-shape) below | Bidirectional cross-references (plan ↔ note ↔ log_anchor) — the substrate for INDEX/DIGEST generation |

### Optional fields (7)

| Field | Type | Format | When to set |
|---|---|---|---|
| `reversibility-tier` | enum | One of: `CHEAP`, `MODERATE`, `EXPENSIVE`, `IRREVERSIBLE` | Per CLAUDE.md Reversibility Discipline. Optional initially; promoted to required after first DIGEST query proves utility. |
| `themes` | list of strings | `["cluster:<name>", ...]` | Mirrors the issue cluster labels per `label-taxonomy.md`. Enables theme-axis DIGEST queries. |
| `summary` | string | ≤140 chars, single line, plain language | One-line distillation of the release for agent search and INDEX-row content. Optional initially; promoted to required after 3 post-cutover notes carry it (matches `reversibility-tier` promotion pattern). See [Field-utility notes for agent search](#field-utility-notes-for-agent-search). |
| `requires_action` | bool | `true` or `false` | True when the user-facing note's Section 5 ("What you need to do") is non-empty. Enables queries like "which past releases required user action?" |
| `breaking` | bool | `true` or `false` | True when the release ships any Voice-Rule-3 review-surface trigger per [release-notes-standard.md](release-notes-standard.md): deprecation, breaking change, state-mutating default change, removal of capability, or new restriction. Enables queries like "any breaking changes in the last 5 releases?" |
| `components` | list of strings | `["<canonical-name>", ...]` | Platform components touched by this release. Free-form initially; canonical-naming convention published in `release-notes-standard.md` §2.3. Complements `themes` (broad) with entity-level specifics. Enables queries like "when did `release-planner` last change?" |
| `followups` | list of strings | `["#N", "#M", ...]` (each `#`-prefixed) | Follow-up issues filed during this release for future remediation (residual register). Enables queries like "what's still open from vX.Y?" without parsing the body. |

### Type discriminator

The `type:` field discriminates artifact classes for the schema validator and for INDEX/DIGEST query routing. Values and meaning:

| `type:` value | Filename pattern | Required-fields subset | Excluded from |
|---|---|---|---|
| `plan` | `vX.Y[suffix]_RELEASE_PLAN.md` under `releases/plans/` | All 6 | — |
| `note` | `vX.Y[suffix]_RELEASE_NOTES.md` under `releases/notes/` | All 6 | — |
| `phase-plan` | `vX.Y-{Z\|I}_PHASE_PLAN.md` under `releases/plans/` (filename grandfathered) | All 6; `pr:` may be `null` if phase plan never reached PR | INDEX rows (phase plans appear in DIGEST footnotes only) |
| `audit-plan` | `vX.Y-{audit-name}_RELEASE_PLAN.md` under `releases/plans/` | All 6 | — |
| `abandoned-plan` | Any plan moved to `releases/archive/plans/` | All 6; add `status: abandoned` and `abandonment-reason` in body | INDEX rows; DIGEST per-version-family entries |

Validator MUST discriminate by `type:` value and apply the type-specific required-fields subset before flagging missing-field errors.

### Links shape

```yaml
links:
  plan: release/releases/plans/<filename>.md     # required on notes; null on plans
  note: release/releases/notes/<filename>.md     # required on plans (after note authored at Stage 13); null on plans pre-Stage-13
  log_anchor: "#vX-Y-slug"                            # ACTIVE releases — fragment ID in the active RELEASE_LOG.md (slug derived from version key)
  log_archive: "logs/<keyslug>.md"                    # ARCHIVED releases — relative path to the per-release archive file (replaces log_anchor once the row is archived out of the active LOG)
```

**`log_anchor` vs `log_archive` (active+archive split, #48):** a release carries `links.log_anchor` while its Deployment-Log block lives in the active `RELEASE_LOG.md`. When the row is archived out of the active head into `release/releases/logs/<keyslug>.md` (per the Stage 13 archive sweep — see [release-process.md § Stage 13](../../governance/release-process.md)), the Stage 13 spoke replaces `log_anchor` with `log_archive` (the relative path to the archive file), and rewrites any inline `../RELEASE_LOG.md#<anchor>` note link to `../logs/<keyslug>.md`. Exactly one of the two keys is present per release: `log_anchor` for active rows, `log_archive` for archived rows. `<keyslug>` = the version key (`v1.08`) for versioned releases or the milestone slug (`public-flip-install-blockers`) for version-less ones.

Bidirectional invariant: if `plan_X.links.note` resolves to `note_Y`, then `note_Y.links.plan` MUST resolve back to `plan_X`. The schema validator enforces this round-trip on every release-corpus pair. Forward-only: pre-cutover plans without notes (or vice versa) are exempt until F-3 backfill executes.

## Worked example — release plan

```yaml
---
version: v1.04b-3
date: 2026-05-14
type: plan
issues: ["#N", "#N", "#N", "#N", "#N"]
pr: "#N"
links:
  note: release/releases/notes/v1.04b-3_RELEASE_NOTES.md
  log_anchor: "#v1-04b-3-doc-cleanup"
themes: ["cluster:documentation", "cluster:process-protocol"]
---
```

## Worked example — release note (frontmatter applied at Stage 13)

```yaml
---
version: v1.04b-3
date: 2026-05-15
type: note
issues: ["#N", "#N", "#N", "#N", "#N"]
pr: "#N"
links:
  plan: release/releases/plans/v1.04b-3-doc-cleanup_RELEASE_PLAN.md
  log_anchor: "#v1-04b-3-doc-cleanup"
reversibility-tier: CHEAP
themes: ["cluster:documentation", "cluster:process-protocol"]
summary: "Cross-release navigation now exists; doc links scanned automatically on every check."
requires_action: false
breaking: false
components: ["deploy.sh", "RELEASE_INDEX.md", "RELEASE_DIGEST.md", "Stage 12 Execute", "Stage 13 Close"]
followups: ["#N", "#N", "#N"]
---
```

## Field-utility notes for agent search

The optional fields exist to let agents return useful answers about the release corpus without parsing 5KB+ of body content per file. Each maps to a specific query pattern:

| Query an agent might receive | Field that answers it |
|---|---|
| *"What was in this release?"* (one-line answer for chat / INDEX cell) | `summary` |
| *"Which past releases required a user action — toggling a setting, regenerating a token, etc.?"* | `requires_action: true` filter |
| *"Are there any breaking changes in the last N releases?"* (status-report agent, change-management impact assessment) | `breaking: true` filter |
| *"When did `release-planner` last change?"* (debugging, tracing a capability's evolution) | `components` membership filter |
| *"What's still open from vX.Y?"* (residual-risk agent, next-release planner) | `followups` membership |
| *"Show me all releases that touched Stage 5 Solutioning."* | `components` membership |
| *"Which releases shipped under `cluster: documentation`?"* (broad theme) | `themes` membership |
| *"Show me the full release history sorted by date, with one-line headlines."* (INDEX consumer) | `summary` + `date` |

### Canonical naming convention for `components`

The `components` field is free-form initially. Conventional values stabilize agent-search results across releases:

| Component class | Canonical form | Example |
|---|---|---|
| Skills | bare skill name (no `release/skills/` prefix) | `release-planner`, `delivery-engine`, `weekly-status-rollup` |
| Pipeline stages | `Stage NN <Name>` | `Stage 5 Solutioning`, `Stage 13 Close` |
| Governance files | filename only (no path) | `RELEASE_LOG.md`, `OPERATIONS.md`, `CORRECTIONS.md` |
| Reference docs | filename only | `gate-criteria-spec.md`, `failure-mode-standard.md` |
| Engineering tools | bare filename | `deploy.sh`, `lint_release_corpus.py`, `check-doc-links.py` |
| Hooks | bare filename | `block-destructive.sh`, `block-rm-prefer-trash.sh` |
| Release-corpus artifacts | bare filename | `RELEASE_INDEX.md`, `RELEASE_DIGEST.md` |

Promote `components` to controlled vocabulary if drift bites within 5 post-cutover releases. Until then, validator does not enforce the convention — it warns on novel values for operator review.

## Validation Discipline

### Tier 1 — File-level schema

- Every applicable file (per Scope table) carries a YAML frontmatter block delimited by `---` markers as the first lines of the file.
- All 6 required fields present.
- Required-field types match the spec (string / list / enum / object / null).
- `type:` value matches one of the 5 enum values.
- `version:` matches the parent Milestone exactly.
- `links.log_anchor` resolves to an existing fragment in `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`.

### Tier 2 — Cross-reference symmetry (bidirectional)

- For every `plan_X.links.note = note_Y`, assert `note_Y.links.plan = plan_X`.
- For every note, `note.links.log_anchor` resolves to a row in RELEASE_LOG.md whose plan-link cites the note's matching plan file.

### Tier 3 — Type-discriminator coherence

- `type: plan` MUST live under `releases/plans/`; `type: note` MUST live under `releases/notes/`; `type: abandoned-plan` MUST live under `releases/archive/plans/`.
- Filename type-suffix MUST match `type:` field (`_RELEASE_PLAN.md` ↔ `plan`; `_RELEASE_NOTES.md` ↔ `note`; `_PHASE_PLAN.md` ↔ `phase-plan`).

### Validator implementation

A Python validator at `core/deploy/tools/lint_release_corpus.py` (authored alongside this schema as the D5 deliverable) executes Tier 1–3 checks and is invoked by `deploy.sh` Check 20 (note-content lint per release-notes-standard.md §3.2). The earlier Check 15 (release-corpus cross-link integrity) was RETIRED in v2; the release-corpus link surface is covered separately by the doc-link primitive. The validator output discriminates by `type:` value to produce template-aware error messages (per the template-aware gate-checks discipline).

## Failure modes

| Failure | Symptom | Detection mechanism | Resolution |
|---|---|---|---|
| Missing required field | Validator returns non-zero with `MISSING FIELD: <field>` | Tier 1 schema scan | Add field per spec |
| Type mismatch (filename vs. `type:`) | Validator flags `TYPE MISMATCH: filename suggests <X>, type: declares <Y>` | Tier 3 discriminator coherence | Correct `type:` OR rename file |
| Asymmetric cross-link | Validator flags `ASYMMETRIC: plan_X→note_Y but note_Y→plan_Z` | Tier 2 symmetry round-trip | Update `links.plan` or `links.note` to restore bidirectional path |
| log_anchor unresolved | Validator flags `LOG ANCHOR MISSING: #<slug> not found in RELEASE_LOG.md` | Tier 1 anchor resolution | Either add the LOG row OR correct the anchor slug |
| Frontmatter absent (forward-only file) | Validator flags `NO FRONTMATTER: file is post-cutover but lacks `---` block` | Tier 1 presence check | Add frontmatter per spec |
| Frontmatter present on pre-cutover file | No-op — schema is forward-only; pre-cutover files exempt | N/A | N/A — backfill via F-3 backfill executes |

## Composition with adjacent standards

| Standard | Relationship to this schema |
|---|---|
| [release-notes-standard.md](release-notes-standard.md) | Owns the BODY content rules for user-facing notes (audience, voice, sections, JTBD framing). This schema adds the FRONTMATTER contract for those same files. They compose: a release note has both rules applied. |
| [version-field-semantics.md](../../../core/standards/version-field-semantics.md) | Owns `version:` field semantics in SKILL.md frontmatter. Establishes that `version:` is a release-tag-at-last-material-edit field. This schema reuses that field semantics: `version:` in a release plan/note matches the release Milestone, not the last-edit tag (different semantics for different artifact class). The two standards are orthogonal — SKILL.md vs. release corpus — but field naming aligned for query consistency. |
| [doc-link-maintenance-protocol.md](../../../core/standards/doc-link-maintenance-protocol.md) | Owns the link-resolution discipline that powers the `links.*` fields' integrity. This schema's `links:` shape is what the doc-link-maintenance primitive resolves. The earlier deploy.sh Check 15 that invoked the primitive against the release-corpus surface was RETIRED in v2; deploy.sh Check 14 invokes the primitive against the governance + skill SKILL.md corpus, and the release-corpus link surface is covered by the release-corpus link checker. |

## Cutover

This schema applies forward-only (the release that authors it is the first compliant). The release plan and release note are the first compliant artifacts. Pre-cutover plans (33 files) and pre-cutover notes (43 files) remain exempt until the historical-backfill umbrella executes. The Stage 13 Close clause (per CR-D6) mandates that every new release adds frontmatter-bearing plan + note artifacts AND updates RELEASE_INDEX.md + RELEASE_DIGEST.md.

## Cross-references

- [release-notes-standard.md](release-notes-standard.md) — body-content rules for user-facing notes
- [doc-link-maintenance-protocol.md](../../../core/standards/doc-link-maintenance-protocol.md) — link-integrity primitive (consumed by Check 14; the earlier Check 15 release-corpus invocation was retired in v2)
- [version-field-semantics.md](../../../core/standards/version-field-semantics.md) — `version:` field discipline (SKILL.md context; conceptually adjacent)
- [duplicate-source-discipline.md](../../../core/standards/duplicate-source-discipline.md) — register-or-remove rule (the schema is the source of truth; INDEX/DIGEST are derivatives)
- `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` — the LOG anchor target for `links.log_anchor`
- `release/releases/RELEASE_INDEX.md` — derivative navigation surface
- `release/releases/RELEASE_DIGEST.md` — derivative zoom surface

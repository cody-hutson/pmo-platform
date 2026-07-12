<!-- reference-durability: allow-link -->
---
title: ADR-080 — Project folder taxonomy is a uniform closed 5-bin set (reshape from the legacy 8-folder structure)
status: Accepted
date: 2026-07-10
release: v3.70-pda-folder-intake-and-provenance (provisional — v3.69 claimed by a concurrent release; re-versioned up per the forward-only rule; binds at Stage 12)
deciders: "operator (scope-lock gate, 2026-07-10) + release-hub Mode O + Stage-5 Solutioning spokes"
tags: [data-architecture, project-taxonomy, folder-structure, migration, pda, frontmatter-schema, closed-set]
source_observations:
  - "Stage-5 Solutioning discovery (the PDA folder/intake milestone): the artifact frontmatter `folder` field (frontmatter-schema.md:197) IS the project folder taxonomy — its enum `01-governance…08-generated` is the legacy structure the PDA uniform-scaffold work item replaces. Changing the scaffold without migrating the enum yields invalid born-aligned frontmatter."
  - "The legacy→new mapping is a RESHAPE (8→5 with regrouping: 02-design+03-testing→2-Delivery; 05-transcripts+06-emails→4-Evidence), not a 1:1 rename — an architecture decision, not a routine repoint."
  - "The platform already migrated `domain` (A/B/C→source/managed/generated) and `synthesis_scope→source_inputs` via an additive-union deprecation-alias migration-window pattern (frontmatter-schema.md:194,250) — proven rails for exactly this class of enum migration."
---

# ADR-080 — Project folder taxonomy is a uniform closed 5-bin set (reshape from the legacy 8-folder structure)

## Status

Accepted — operator-ratified at the Stage-5 Collective Review scope-lock checkpoint on Friday 2026-07-10, for the PDA folder/intake milestone (provisional v3.70). The founding-ADR content is committed by Engineering Wave 0 on the release branch; this record is immutable below `## Status` per the ADR supersession + immutability policy.

Renumbered from ADR-078 to ADR-079 at merge time — ADR-078 was claimed on main by `ADR-078-security-hook-dependency-resolution-posture`; per the immutable-numbering collision-resolution rule the later claimant takes the next free slot. Re-versioned again 079→080 — the concurrent pipeline-freshness release also claimed 079 (hub-owned-subtask-close); ours takes the next free slot.

## Context

The PDA folder/intake milestone introduces a uniform, methodology-agnostic project scaffold. Stage-5 solutioning surfaced a premise the release plan under-modeled: the artifact frontmatter **`folder` field** is defined as *"Originating folder in the project structure"* (`frontmatter-schema.md:197`), and its enum — `01-governance, 02-design, 03-testing, 04-operations, 05-transcripts, 06-emails, 07-reference, 08-generated` — **is** the legacy project folder taxonomy the scaffold replaces. The two are the same taxonomy, not distinct concerns; a born-aligned artifact stamped with a new-bin `folder` value fails enum validation until the enum is migrated.

The legacy taxonomy is 8 governance-model-branched folders with ~15 speculative empty subfolders, and the Domain-A/B/C classification is coupled to its folder ranges (Domain A = `01-07`, Domain C = `08-generated`). The confirmed blast radius of a taxonomy change spans the schema/contract corpus — `frontmatter-schema.md`, `sqlite-index-schema.md`, `agent-processing-contracts.md`, `entity-field-schemas.md`, `artifact-workflow-protocol.md` — plus `OPERATIONS.md` (59 references) and `routing-rules.md` (9 references).

## Decision

Adopt a **uniform, closed, methodology-agnostic project folder taxonomy**: five canonical numbered bins — **1-Governance, 2-Delivery, 3-Operations, 4-Evidence, 5-Reference** — plus two transient underscore areas — **`_inbox/`** and **`_generated/`**. The set is CLOSED: agents route into it and never create new bins; a non-fitting item goes to the bin root or `_inbox/_unsorted/`, flagged. Changing the set is a governance change (this ADR + the structure lint), not a runtime decision.

The 8→5 mapping:

| Legacy (8) | New (5 canonical + transient) |
|---|---|
| 01-governance | 1-Governance |
| 02-design + 03-testing | 2-Delivery (Requirements/Design/Testing) |
| 04-operations | 3-Operations |
| 05-transcripts + 06-emails | 4-Evidence (Transcripts/Emails/Exports) |
| 07-reference | 5-Reference |
| 08-generated | `_generated/` |

**Migrate the `folder` enum and its consumers via the platform's established additive-union deprecation-alias migration-window pattern** — the same rails already used for `domain` (A/B/C→source/managed/generated) and `synthesis_scope→source_inputs`. During the migration window, enum-validating consumers accept the **union** {legacy 8, new 5-bin + transient}; the migration tail (`agent-processing-contracts.md` emit sites, `sqlite-index-schema.md` CHECK/queries, `entity-field-schemas.md` enum, `artifact-workflow-protocol.md` promotion rule) is sequenced within the milestone build; convergence to the single live 5-bin vocabulary completes over the window. Existing-project migration is **deferred** (out of this milestone's scope).

## Alternatives Considered

- **Descope to scaffold-only — keep the legacy `folder` enum for artifact stamps.** Rejected: a durable two-taxonomy window (new bins in scaffolds, legacy enum in stamps) is a design smell and produces invalid/ambiguous born-aligned frontmatter.
- **Full big-bang replace — retire the legacy taxonomy everywhere at once, migrate existing projects in the same slice.** Rejected: high blast radius, no migration window, breaks existing projects. The platform's proven mechanism for enum evolution is additive-union with a convergence tail, not a synchronized cutover.
- **Treat the `folder` enum as a distinct concern from the project structure.** Rejected: the Stage-5 investigation confirmed they are the same taxonomy (`folder` = "originating folder in the project structure"), so they cannot diverge without incoherence.

## Consequences

- **Positive:** every project is born predictable and methodology-agnostic under one closed taxonomy; born-aligned frontmatter validates; the migration is de-risked by an established, tested pattern; the Domain-A/B/C↔folder coupling is re-expressed once, coherently.
- **Cost:** the uniform-scaffold work item's scope expands beyond the four target skills to the additive enum migration + tail (5 schema/contract files + `OPERATIONS.md` + `routing-rules.md`); a migration window exists during which consumers accept the legacy∪new union.
- **Follow-ups:** existing-project migration (deferred — the milestone's out-of-scope note); full convergence retiring the legacy vocabulary (tail sequenced in the build); the structure lint (currently OPEN as a sibling work item) is the enforcement instrument for the closed set.

## Reversibility

**MODERATE / Confidence HIGH.** While the migration window is open and no existing project has been reshaped, reverting is a git-revert of the enum-union addition + the scaffold change. The tier rises to **EXPENSIVE** once convergence retires the legacy vocabulary and projects are born on the new set (cross-corpus + stamped-artifact impact). The decision is therefore taken now, before Engineering, so the reshape is ratified while it is still cheap to unwind.

## Related ADRs

- ADR-060 — composed-index `PROJECT.md` template (the born frontmatter block composes with it).
- ADR-044 — skill-output ownership / entity model (the Domain-A/B/C classification this taxonomy carries).

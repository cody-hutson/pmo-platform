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
| Archive segment | `release/releases/RELEASE_LOG_ARCHIVE-<family>.md` | NO (it carries the parent ledger's content, not file-level frontmatter) | § Archive Segments below |

**Forward-only adoption rationale:** Per the precedent that user-facing notes started at an earlier release (an umbrella campaign tracks retroactive coverage), this schema applies prospectively, forward-only, to bound R-1 restructure-integrity risk. Historical backfill of 76 pre-cutover files is registered as F-3 follow-up gated on schema utility.

## Derived-Surface Contract

The release corpus records one fact per release — *release X shipped, containing Y, at SHA Z* — across four ledger surfaces. **Two of those surfaces are SOURCE and two are DERIVED, and the split is per-field, not per-file.** This section is the register that `duplicate-source-discipline.md` § 1 requires: every restatement of a release fact either names its source here or is a defect.

**The contract is the pattern, not just the ledger set.** It governs any surface in this repository that RESTATES a fact another file already owns. Two families are registered below: the **release-ledger** family (the four surfaces above, projected by `generate_release_index.py`) and the **release ADR index** (`release/ADRs/README.md`, projected by `generate-adr-index.py`). A third in-corpus instance of the same shape — the generated hook registry — is governed by its own founding record rather than registered here, because its population is not release corpus. A surface that restates a fact and appears in neither register is a defect, not an exception.

### Roles

| Surface | Role | Authoritative for | Notes |
|---|---|---|---|
| `release/releases/RELEASE_LOG.md` — table row | **SOURCE — event record** | the release fact: version, milestone, issues, release PR, merge SHA, tag, state, and the **merge anchor** date | Written by the Stage-12/13 close-out's LOG-transition phase. Carries no `# ` headline and no `summary:` — it is not, and cannot be, the narrative source. |
| `release/releases/RELEASE_LOG.md` — `#### …` H4 prose | **SOURCE — execution record** | the per-release Deployment Log and Release Learnings blocks | Not projected anywhere. |
| `release/releases/notes/*_RELEASE_NOTES.md` | **SOURCE — narrative record** | the headline **seed** (`# ` H1) and the `summary:` **seed** (frontmatter) | The note's own `date:` is written *from* the close-out run anchor — the note is downstream of that anchor, never its origin. |
| `release/releases/RELEASE_INDEX.md` | **DERIVED (5 of 6 columns) · hybrid** | — except the **`Theme`** column, which is the INDEX's own source content | Verified **whole-file**: outside `Theme` the INDEX is not hand-edited. |
| `release/releases/RELEASE_DIGEST.md` | **DERIVED at emission** | — | Verified **closing entry only**: historical entries carry legitimate post-emission operator edits. |
| `CHANGELOG.md` | **DERIVED at emission** | — | Same posture as the DIGEST. |
| `core/ADRs/ADR-*.md` + `release/ADRs/ADR-*.md` — filename + frontmatter | **SOURCE — decision record** | an ADR's number, title, status, decision date and originating release | The record owns every fact about itself. `status:` is enum-prefixed with an optional prose tail per the ADR schema; the **leading token** is the fact, the tail is a ratification anchor that lives on the record. |
| `release/ADRs/README.md` — the `ADR-INDEX` region | **DERIVED (all 5 columns) · whole-table** | — | Verified **region-scoped**: the README's prose sections are hand-authored and outside the projection. No hybrid column — unlike the INDEX's `Theme`, every column here is derivable, so there is no round-trip limb. |
| `core/ADRs/README.md` | **NEITHER — curated thematic document** | its own curation | Deliberately not an index and deliberately not projected. Registered here so the negative is explicit and the question is not re-opened. |

### Per-field provenance

The projector is `core/deploy/tools/generate_release_index.py`. It reads two **files** and takes every non-file input as a **required CLI argument** — it reads no clock, no environment variable, and no operator config.

| Derived field | Source | Kind |
|---|---|---|
| INDEX `Version` / `Milestone` / `Release PR` | LOG row | file |
| INDEX `Date` | LOG row — the **merge anchor**, relayed, never resampled | file |
| INDEX `Release Notes` | filesystem presence of the note file | file |
| INDEX `Theme` | the on-disk INDEX itself (round-tripped, never regenerated) | file — the hybrid column |
| DIGEST headline | the note's `# ` H1, when present; otherwise the operator placeholder filled at chore-PR review | file |
| DIGEST `(date)` | the **close-out run anchor** | run-scoped required argument (`--closeout-anchor`) |
| CHANGELOG `- <date>` | the **close-out run anchor** | run-scoped required argument (`--closeout-anchor`) |
| CHANGELOG summary | the note's frontmatter `summary:`, with the `(see release notes)` fallback | file |
| CHANGELOG Release URL | the repository slug | required argument (`--repo-slug`) |

The ADR-index projector is `release/tools/generate-adr-index.py`. It reads **files only** — the ADR file set and each record's frontmatter — and takes no run-scoped input at all: no clock, no anchor argument, no environment variable, no operator config. Its output is therefore a pure function of the corpus, which is why it can be verified by re-derivation rather than by a stored baseline.

| Derived field | Source | Kind |
|---|---|---|
| ADR-index `ADR` (link text + href) | the record's **filename** | file |
| ADR-index `Title` | the record's `title:`, with its `ADR-NNN — ` prefix stripped | file |
| ADR-index `Status` | the **leading Nygard token** of the record's `status:`; the sanctioned prose tail is not projected | file |
| ADR-index `Date` | the record's `date:` | file |
| ADR-index `Release` | the record's `release:`, with a trailing version-binding parenthetical dropped | file |
| ADR-index row order | ascending by ADR number | derived from the file set |

**Why the Status tail is dropped rather than projected.** A `Proposed (flips to Accepted at Stage 9)` tail is a *promise about a future gate*, tracked on the record and by the Stage-13 ratification-flip backstop. Projecting it into an index would put a second, staler copy of a ratification claim in a navigation surface — the duplicate-source defect this contract exists to prevent, re-created one layer down.

**Why the anchors are arguments and not derivations.** The INDEX and the LOG carry the **merge** anchor; the DIGEST, the note's `date:` and the CHANGELOG carry the **close-out run** anchor. Both are sampled exactly once, by the close-out orchestrator, at sites that already exist. A projector that could reach a clock could become a second writer of a fact that already has one — which is precisely the mechanism that produced the INDEX `Date` grandfathering enumeration the projector still carries. Anchor taxonomy and sampling rules: [`date-variable-convention.md § Emission-Time Anchors`](../../../core/standards/date-variable-convention.md).

### Emission and custody

- The projector emits **one entry to stdout**. It never rewrites a ledger. The calling close-out phase performs the insertion and treats a non-zero exit **or an empty emission** as a failure, never as a no-op.
- Provenance is asserted **at emission**; the file holds **custody** afterwards. A historical DIGEST or CHANGELOG entry edited after emission is that file's own content and is not drift.
- A **whole-file regenerate of the DIGEST or the CHANGELOG is prohibited** — the majority of historical entries carry post-emission editorial content that exists nowhere else, and a regenerate destroys it silently as a clean diff rather than a conflict.

### Verification posture

| Surface | Scope | Gate |
|---|---|---|
| `release/releases/RELEASE_INDEX.md` | whole file, on the 5 derived columns **plus** a `Theme` round-trip integrity limb **plus** a recent-first row-order limb | `generate_release_index.py --verify`, invoked by `deploy.sh` Check 23 |
| `release/releases/RELEASE_DIGEST.md` | the closing version's entry only | close-out `assert_derived_surfaces` phase (presence + residue) and `deploy.sh` Checks 32/48 (presence) |
| `CHANGELOG.md` | the closing version's entry only | same |
| `release/ADRs/README.md` | the `ADR-INDEX` managed region only, on all 5 derived columns, **plus a set-difference in BOTH directions** (a record with no row, and a row with no record) | `generate-adr-index.py --verify`, invoked by the `adr-number-integrity` job in `.github/workflows/repo-integrity.yml` |

A hand-edit to any of the INDEX's five derived columns **fails** Check 23. A hand-edit to INDEX `Theme` is **sanctioned** and protected by the integrity limb. A hand-edit to a historical DIGEST or CHANGELOG entry is **allowed**. A closing DIGEST or CHANGELOG entry that diverges at close-out **fails**. A hand-edit to any cell inside the ADR-INDEX region **fails**, and so does a merged ADR with no row — which is the failure this surface was converted to make impossible.

**Both-directions verification is not optional on a projected index, and the reason is asymmetric.** A per-cell comparison alone would pass a table that is simply missing a record — the exact defect that produced this surface. A coexistence limb alone would pass a table whose every row contradicts its record. The ADR index carried **both** defects simultaneously before conversion, which is why its check asserts both.

**A projector must never silently regenerate to clear a finding.** `--verify` is read-only; the remedy is a separate `--write` invocation the author runs and commits. A check that repaired what it measured could not distinguish a stale index from a corrupted one.

## Archive Segments

An **archive segment** is a same-directory, same-schema continuation of a ledger, holding block bodies that have aged out of that ledger's hot working set. It is a fourth artifact class alongside SOURCE and DERIVED surfaces, and it is neither: it is the **same record as its parent, relocated**.

| Property | Rule |
|---|---|
| Naming | `<PARENT_STEM>_ARCHIVE-<family>.md`, in the parent's own directory. `<family>` is the major release family (`v1`, `v2`, `v3`, …) or `version-less`. |
| Applies to | `release/releases/RELEASE_LOG.md` only. The three derived ledgers are projections; their volume is a projector concern, not an archival one. |
| Class | **Inherited from the parent**, always. A segment is a disposition *destination*, never itself a disposition *source*, and is never eligible for a disposition its parent is not. It is never itself swept. |
| What relocates | `#### Deployment Log <key>` block **bodies**. The release table never relocates and is never split. `#### Release Learnings` blocks never relocate — heading or body, at any window. |
| What stays | Every `#### ` heading stays in the parent, followed by a one-line pointer to its segment. This is what keeps `links.log_anchor` values and in-corpus anchors resolving, and it is the redaction-preserves-presence shape `RECORDS_POLICY.md` § Disposition Rules rule 2 sanctions. |
| Ordering | Selection is oldest-first by the **LOG table's chronology**, never by a block's position in the file. Block order in the file is a convention, not a contract. |
| Boundary | Byte-denominated. Blocks relocate until the hot file is at or under its budget; the number of releases retained is an **output** of that rule and appears nowhere as an input. |
| Growth | Append-only. Idempotent: a block already carrying the pointer line is never moved again. |
| Verification | Destination-side. Conservation is asserted by re-reading the segment FILE and comparing against the pre-sweep content from git — never from a manifest the writer produced about itself. Every named machine contract is satisfied by the retained headings alone, so a truncated segment would pass all of them and fail only here. |

**Reader rule, stated unconditionally.** Any tool that parses content from **inside** a `#### ` block of a ledger with archive segments must read the ledger **and** its sibling segments. Reading the hot file alone shrinks the tool's basis population silently on every sweep. This is the general form of the census question a content relocation must answer: *what reads inside a block* — never *what declares an anchor at it*. An anchor records who points at content and breaks visibly; a body parser degrades silently, and a tolerant body parser degrades silently at exit zero.

Mechanism owned by `release/tools/sweep-release-corpus.py`; disposition classified by `core/governance/RECORDS_POLICY.md` § Retention Schedule; each sweep records one row in `core/governance/RECORDS_ARCHIVE_LOG.md`.

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

**Pre-claim naming lifecycle (additive — the filename patterns above are the *shipped-corpus* form).** The `vX.Y…` filename patterns are the **post-claim** canonical form: a shipped release *is* version-named, and these are the names the corpus carries. While a release is **in flight (pre-claim)**, its plan is authored **slug-primary** — `release/releases/plans/<slug>_RELEASE_PLAN.md`, carrying no version stem, with in-file version references held as the `{{RELEASE_VERSION}}` placeholder. For a `versioned` release the plan is renamed to its `vX.Y_RELEASE_PLAN.md` shipped-corpus form at the Stage-12 atomic claim (the CAS-win rename + placeholder resolution, per ADR-092); a `version-less` release keeps the slug form. This is the corpus-schema projection of the two-phase identity binding in [`../../governance/RELEASE_PROTOCOL.md`](../../governance/RELEASE_PROTOCOL.md) § Versioning — the shipped-corpus filenames above are unchanged.

Validator MUST discriminate by `type:` value and apply the type-specific required-fields subset before flagging missing-field errors.

### Links shape

```yaml
links:
  plan: release/releases/plans/<filename>.md     # required on notes; null on plans
  note: release/releases/notes/<filename>.md     # required on plans (after note authored at Stage 13); null on plans pre-Stage-13
  log_anchor: "#vX-Y-slug"                            # required on both — fragment ID in RELEASE_LOG.md (slug derived from version key)
```

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

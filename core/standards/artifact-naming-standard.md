---
title: Artifact Naming Standard — one canonical POSIX-safe file + folder naming standard
purpose: "The single canonical home for artifact and folder naming: the POSIX-safe charset/separator grammar, the three-tier validation model with one canonical file regex, the deterministic invertible type→segment slug, the folder-naming rule (including the `_`-prefix infrastructure reservation), the filename↔frontmatter boundary, and the retroactive-rename protocol. Cited (never copied) by the artifact-emitting skills, pmo-qa-auditor G10, project-initiator, and OPERATIONS.md."
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: "The artifact-emitting skills (artifact-generator, comms-writer, daily-status, weekly-status-rollup, change-management, delivery-engine, pmo-process-designer) — output-contract conformance; pmo-qa-auditor G10 (filename-conformance gate, structural T1+T2 deterministic); project-initiator folder-name enforcement; core/governance/OPERATIONS.md § Standard Project Folder Structure + Folder Routing Guidelines; ADR-055 (artifact-name-segment-order)"
---
<!-- reference-durability: allow-link -->
# Artifact Naming Standard

## Purpose

This is the single canonical standard for **how artifact files and project folders are named** across the workspace. It exists so that:

- **Filenames are POSIX-safe** — no spaces, no shell-meta characters (`& ( ) /`, space), lowercase extensions — so they survive globs, link validators, search indexes, and shell pipelines unquoted.
- **Filenames are scannable by artifact kind** — the type segment draws from a controlled vocabulary, so a folder listing groups by what each artifact *is*.
- **The naming contract has exactly one home.** Every artifact-emitting skill, the QA auditor's filename gate, and the project scaffolder cite *this* file rather than each carrying its own ad-hoc rule that drifts.

The standard governs **syntax** (charset / separators / segment grammar / ISO-date / project-code) and **semantics** (the controlled type vocabulary). It does **not** govern lifecycle, version, status, or lineage — those are frontmatter concerns (see [§ Filename-vs-Frontmatter Boundary](#filename-vs-frontmatter-boundary)).

## Validation Model

Naming conformance is layered into **three tiers**. The load-bearing principle — stated here because it is the rule every consumer binds to:

> **The validation regex is a Tier-1 charset/separator gate ONLY. Segment grammar, segment order, ISO-date validity, controlled-type membership, and human-readability are Tier-2/Tier-3 properties a charset regex structurally cannot encode; they are enforced by complementary structural checks and out-of-band controls, never asserted as regex guarantees.**

| Tier | Guarantees | Enforced by | Does NOT guarantee |
|---|---|---|---|
| **T1 — Charset / separator** | charset closed to `[A-Za-z0-9_-]` + lowercase extension; `_` is the primary segment separator; `-` only intra-segment; **no shell-meta `& ( ) /` and no space** | **the single canonical file regex** ([§ Syntax Rules](#syntax-rules)) | grammar, segment order/arity, ISO-date validity, type membership, human-readability |
| **T2 — Grammar / structure** | ≥ 2 segments; alpha-led first segment; optional trailing ISO-date segment; ISO-date **validity** (`2026-3-18` rejected) | **structural checks** — G10-03 (date validity) + G10-05 (grammar/order) — NOT the charset regex | type-vocabulary membership; human-readability |
| **T3 — Semantic** | the type segment ∈ the controlled catalog vocabulary (advisory); human-readability | **out-of-band** — G10-04 catalog lookup (**WARN**, not FAIL) + operator confirmation at scaffold/promote time | — |

This is why the QA gate ([§ Conformance Gate](#conformance-gate)) carries G10-03 (date validity) and G10-05 (grammar/order) as checks **distinct from** the charset regex: a charset gate that also tried to assert grammar/order would be over-claiming what a flat segment alternation can structurally enforce.

## Format Specification

The canonical artifact filename shape:

```
[ProjectCode]_[Type]_[…optional descriptor segments…]_[YYYY-MM-DD].ext
```

- **`[ProjectCode]`** — an alpha-led project/abbreviation segment (e.g., `ABC`). First segment; never `_`-prefixed.
- **`[Type]`** — the single `-`-joined slug of a controlled artifact type (segment 2). See [§ Type Vocabulary](#type-vocabulary).
- **`[…descriptor segments…]`** — zero or more optional `_`-separated free segments (an identifier, a topic).
- **`[YYYY-MM-DD]`** — an optional **trailing** ISO-8601 date segment. When a date is part of the name, it is last and ISO-8601.
- **`.ext`** — a lowercase extension (`.md`, `.csv`, `.yml`).

**Conforming examples:**

| Filename | Reading |
|---|---|
| `ABC_Cutover-Plan_2026-03-18.md` | project `ABC`, type `Cutover-Plan`, date 2026-03-18 |
| `ABC_Go-No-Go-Checklist_2026-03-18.md` | project `ABC`, type `Go-No-Go-Checklist` (one segment), date |
| `ABC_RAID-Log.csv` | project `ABC`, type `RAID-Log`, no date |
| `ABC_FDD-Review_FDD002_2026-03-18.md` | project `ABC`, type `FDD-Review`, descriptor `FDD002`, date |
| `ABC_AM-Update_2026-03-18.md` | project `ABC`, type-slug `AM-Update`, date |

**Non-conforming (rejected) examples:**

| Filename | Why rejected |
|---|---|
| `ABC Cutover Plan.md` | spaces (T1) |
| `Q4 Plan & Review.md` | space + `&` shell-meta (T1) |
| `Meeting (final).md` | parentheses + space (T1) |
| `_scratch_notes.md` | leading `_` (the `_`-prefix is reserved for folders only — T1/T2) |
| `Report.MD` | uppercase extension (T1) |
| `123.md` | numeric-led, single segment — no project-code + type structure (T2 / G10-05) |
| `Plan.md` | single segment — no `[ProjectCode]_[Type]` structure (T2 / G10-05) |

## Syntax Rules

The syntax layer (T1) is the **single canonical file regex**, published character-for-character identically everywhere this standard is consumed (the QA G10 gate, the project-scaffolder's references, any future validator). It is the **only** file regex this standard defines:

```
^[A-Za-z0-9]+(-[A-Za-z0-9]+)*(_[A-Za-z0-9]+(-[A-Za-z0-9]+)*)*(_[0-9]{4}-[0-9]{2}-[0-9]{2})?\.[a-z0-9]+$
```

Read as an annotated breakdown of that one string (this is a gloss of the **identical** pattern, never a second pattern):

- `^[A-Za-z0-9]+(-[A-Za-z0-9]+)*` — the first segment: alphanumeric, with `-` permitted **inside** the segment for compound modifiers (`Go-No-Go`). **No leading `_`** (the anchor disallows it; the `_`-prefix is reserved for folders — see [§ Folder & Directory Naming](#folder--directory-naming)).
- `(_[A-Za-z0-9]+(-[A-Za-z0-9]+)*)*` — zero or more additional `_`-separated segments, each itself allowing intra-segment `-`. `_` is the **primary separator**; `-` is the **intra-segment** (compound-modifier) joiner.
- `(_[0-9]{4}-[0-9]{2}-[0-9]{2})?` — an optional trailing ISO-8601 date segment; `-` here is the ISO date separator.
- `\.[a-z0-9]+$` — a lowercase extension.
- **Excludes by construction** space, `&`, `(`, `)`, `/`, and every shell-meta character — the `[A-Za-z0-9_-]` charset is closed.

**T1 scope boundary (stated so no consumer over-binds the regex):** the regex guarantees **charset + separator + no-shell-meta + closed-charset structure**. It does **NOT** validate:

- **ISO-date *validity*** — `ABC_2026-3-18_X.md` (single-digit month) still *matches* the regex, because a malformed date parses as an ordinary free segment, not as the `_YYYY-MM-DD` alternation. Date validity is the **G10-03** structural check (T2), not a regex guarantee.
- **Segment *order* / *arity*** — `ABC_2026-03-18_Cutover-Plan.md` (date in the middle, type after) matches the charset regex; so would any well-charactered string with ≥1 segment. Order and arity are the **G10-05** grammar check (T2) + the write-time emitter convention, not a regex guarantee (see [§ Conformance Gate](#conformance-gate) and ADR-055).

**Self-test (Python `re`, the canonical regex above):**

- PASS (charset-conformant): `ABC_Go-No-Go-Checklist_2026-03-18.md`, `ABC_RAID-Log.csv`, `ABC_Cutover-Plan_2026-03-18.md`.
- FAIL (shell-meta / space / paren / leading-`_` / uppercase-ext): `ABC Cutover Plan.md`, `Q4 Plan & Review.md`, `Meeting (final).md`, `_scratch.md`, `Report.MD`.
- `ABC_2026-3-18_X.md` (single-digit month) **matches** the charset regex — the documented T1/T2 division of labor (ISO-date *validity* is G10-03), not a defect.

## Type Vocabulary

The `[Type]` segment draws from the controlled artifact-type vocabulary in [`../../operations/skills/artifact-generator/references/artifact-catalog.md`](../../operations/skills/artifact-generator/references/artifact-catalog.md) — that catalog is the **single source of truth** for the type set (28 named artifact types in 6 categories at authoring). This standard **cites that catalog by reference and does NOT re-list the types** (a copied list would be a second source that drifts — per [`./duplicate-source-discipline.md`](./duplicate-source-discipline.md) register-or-remove). Each catalog row already carries its own evidence (its Description + Specialist-Skill columns); the requirement that each type cite its evidence source is satisfied by the catalog row, cross-referenced — not re-asserted here.

### The type→segment slug (deterministic, invertible, one segment)

A catalog type is Title Case with spaces and sometimes punctuation (`Cutover Plan`, `Go/No-Go Checklist`). The filename segment is a **single `-`-joined slug** of that type. A type therefore occupies **exactly one segment**, which makes the type↔segment map deterministic *and* invertible — so the QA gate's catalog lookup (G10-04) is a one-line operation rather than an ambiguous multi-segment delimiting problem.

**Canonical `slug(type)` — the durable structure this standard owns:**

1. Trim; collapse internal whitespace runs to a single space.
2. Replace `/` and any run of whitespace-or-punctuation **between word characters** with a single `-`.
3. Drop any remaining character outside `[A-Za-z0-9-]`.
4. Collapse repeated `-`; strip any leading/trailing `-`.

The result is one `-`-joined token in segment position 2 (after the project code). **`unslug` (for G10-04 catalog lookup)** = lowercase-compare the candidate segment — with `-` tolerant of (space | `/`) — against the slugged catalog set.

| Catalog type (SSOT) | Canonical slug (one segment) | Filename example |
|---|---|---|
| `Cutover Plan` | `Cutover-Plan` | `ABC_Cutover-Plan_2026-03-18.md` |
| `Go/No-Go Checklist` | `Go-No-Go-Checklist` | `ABC_Go-No-Go-Checklist_2026-03-18.md` |
| `Meeting Follow-Ups / Action Register` | `Meeting-Follow-Ups-Action-Register` | `ABC_Meeting-Follow-Ups-Action-Register.md` |
| `Weekly Status Roll-Up` | `Weekly-Status-Roll-Up` | `ABC_Weekly-Status-Roll-Up.md` |
| `RAID Log` | `RAID-Log` | `ABC_RAID-Log.csv` |

All five slugged forms pass both the canonical file regex (T1) and the G10-05 grammar check (T2). The type slug is one `-`-joined segment; the `_` separator is reserved for the *boundaries between* segments (project / type / descriptor / date), never inside a type name.

## Folder & Directory Naming

Project and folder names follow a sibling rule, distinct from the file rule (folders are not date-coded and tolerate the established space-or-hyphen word break used by the canonical `01-08` layout, e.g. `01-Governance`, `Change-Management`).

**Folder name regex:**

```
^[A-Za-z0-9]+([ -][A-Za-z0-9]+)*$
```

- **No special characters; human-readable.** Folder names use the alphanumeric charset with a single space-or-hyphen word break — no shell-meta, no date segment, no `_` prefix on a *project* folder.
- **The `_`-prefix is RESERVED for sanctioned infrastructure folders.** The reserved set is named explicitly: **`_pmo/`** (navigation layer) and **`_config/`** (program operational config). Staging-area infrastructure subfolders (e.g. `08-Generated/_unclassified/`) follow the same reservation. Precedent: `frontmatter-schema.md` exempts navigation-layer `_pmo/` pages and the `projects/_config/` governance home; the CLAUDE.md tier system; and the in-repo `_`-folders (`operations/skills/_shared`, `release/references/standards/_examples`).
- **The infrastructure carve-out is explicit** so a folder-name validator can reject a `_`-prefixed *project* folder without breaking `_pmo/` / `_config/` / the staging `_`-subfolders.

**Ownership line:** *This standard owns the folder-naming rule; `project-initiator` enforces it at scaffold time and cites this single home — it does not restate the rule inline.*

## Filename-vs-Frontmatter Boundary

A filename answers **"what is this?"**; frontmatter answers **"what state is it in?"**. The two carriers do not overlap.

| Concern | Carrier | Authority |
|---|---|---|
| What is this? (type / topic / project / date) | **Filename** | this standard |
| What state / version / lineage? (`lifecycle_state`, `version`, `promotion_state`, `supersedes`, `parent_artifact`) | **Frontmatter** | [`../schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) (Categories 2/3/4, Domain-C fields) |

**Rule:** *Versioning, lifecycle status, and lineage are EXCLUDED from the filename — they are frontmatter concerns per `frontmatter-schema.md`. Do not encode `v2`, `draft`, `superseded`, or a parent pointer in the filename.* A version-in-filename such as `XYZ_Cutover_Plan_v1_2026-03-18.md` is an **anti-pattern**: the `v1` is a frontmatter `version`, not a filename segment; the conforming name is `XYZ_Cutover-Plan_2026-03-18.md` with `version: 1` in frontmatter.

## Framework Alignment

NARA / ARMA records-naming guidance is **directional, not adopted verbatim** — the platform's filenames are agent-maintained and frontmatter-backed, so their human-keyed retention coding is over-specified for this corpus.

| Framework principle | Fit | Disposition |
|---|---|---|
| No spaces in filenames | Strong | **ADOPT** (the syntax-layer core) |
| ISO-8601 `YYYY-MM-DD` date coding | Strong | **ADOPT** (the date segment) |
| Machine-parseable separators (`_` / `-`) | Strong | **ADOPT** |
| Leading sequence/retention code keyed by a human records schedule | Weak | **REJECT** — platform artifacts are agent-maintained + frontmatter-backed; retention/disposition lives in the records-management policy + frontmatter `lifecycle_state`, NOT the filename |
| Version-in-filename (`_v2`) | Conflicts | **REJECT** — versioning is a frontmatter concern (see boundary above) |

*NARA/ARMA inform the syntax principles (no spaces, ISO dates, parseable separators); the platform does NOT adopt their human-records-schedule schema, because the platform's provenance/retention model is frontmatter-driven, not filename-driven.*

## Conformance Gate

`pmo-qa-auditor` **G10** is the audit-time enforcement complement to write-time conformance. It binds to the model above — the charset regex is the T1 gate; grammar/order and date validity are T2 structural checks distinct from it.

**G10 — Artifact filename-conformance gate** (conditional-fire; does **not** fire on outputs that name no artifact):

- **Phase 1 (structural, deterministic):**
  - **G10-01** — filename matches the **canonical charset regex** (T1).
  - **G10-02** — no space / `&` / `(` / `)` / `/` (subsumed by T1; kept as an explicit cite).
  - **G10-03** — the date segment, if present, is a **valid** ISO-8601 date (`2026-3-18` rejected) (T2).
  - **G10-05** — filename matches the **grammar/order regex** — ≥ 2 segments, alpha-led first segment (T2, closes the `123.md` / `Plan.md` arity/lead holes):
    ```
    ^[A-Za-z][A-Za-z0-9-]*(_[A-Za-z0-9-]+)+(_[0-9]{4}-[0-9]{2}-[0-9]{2})?\.[a-z0-9]+$
    ```
- **G10-04 (T3, WARN not FAIL)** — the `[Type]` segment (segment 2, `-`→space/`/` normalized) resolves to a type in the catalog. The vocabulary legitimately extends, so a miss is a **WARN**, never a FAIL.

**PASS = G10-01 + G10-02 + G10-03 + G10-05 pass.** FAIL cites the exact filename + the failing rule + the corrected name. Binary — no CONDITIONAL.

**Residual (accepted, T2):** `ABC_2026-03-18_Cutover-Plan.md` (date in the middle, type after) still passes G10-05 because the middle date parses as a free segment — strict *positional* order (date last) is the write-time emitter convention + the one-segment slug rule, a documented convention, not something G10-05 fully pins. G10-05 closes the falsifiable arity/lead holes; strict positional enforcement is a future hardening (a fully position-pinning regex) deferred per ADR-055 — not adopted now.

## Retroactive-Rename Protocol

When an existing file or folder is non-conforming and is renamed to conform:

1. **Use `git mv`** for tracked files so history follows the rename.
2. **Grep for inbound references first.** Before renaming, `grep -rn '<old-name>'` across the corpus (and `deploy.sh --check` Check 14 doc-link integrity after) so no markdown link, skill reference, or script path breaks.
3. **Rename, then re-grep** to confirm zero dangling references to the old name.
4. **Reversibility: MODERATE once files exist.** Renaming after a file is referenced forces updating every inbound reference; renaming a brand-new file before it is referenced is CHEAP. Stage the rename + the reference updates as one change so the corpus is never half-renamed.
5. **Operational-space (`projects/`) migration is operator-side.** The `projects/` tree is Layer-2 (git-ignored); its syntax migration (`find projects -name '* *' -type f` → 0) runs operator-side via `git mv` + link-grep, not in a platform PR.

## Cross-References

This standard **composes by reference** — it does not duplicate the lifecycle, provenance, or vocabulary concepts owned elsewhere.

| Surface | Reference | Role (what this standard does NOT duplicate) |
|---|---|---|
| [`../disciplines/document-ecosystem-design.md`](../disciplines/document-ecosystem-design.md) | Domain C lifecycle + `08-Generated/` staging + sidecar `{filename}.meta.yml` metadata | This standard cross-refs the lifecycle/staging concepts; it does not restate Domain-C states. |
| [`../schemas/frontmatter-schema.md`](../schemas/frontmatter-schema.md) | The filename↔frontmatter boundary; sidecar naming `{filename}.meta.yml`; lineage / version / lifecycle fields | This standard states the boundary and points here for the field definitions. A `.meta.yml` sidecar inherits its base name from the artifact, so it conforms by construction. |
| [`../../operations/skills/artifact-generator/references/artifact-catalog.md`](../../operations/skills/artifact-generator/references/artifact-catalog.md) | The controlled artifact-type vocabulary (28 types / 6 categories) | The `[Type]` segment SSOT — cited, never copied. |
| [`./duplicate-source-discipline.md`](./duplicate-source-discipline.md) | Register-or-remove | Why the type vocabulary is cited, not re-listed. |
| ADR-055 (`artifact-name-segment-order`) | The project-code-first segment-order decision | The order rule + the regex/G10-05 enforcement-vs-convention boundary this standard's gate binds to. |

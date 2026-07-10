---
title: Template Protocol — PMO Platform
purpose: Layer 4 of the 5-Layer Template Architecture — the lifecycle workflow, provenance-header schema, and trigger/promotion protocol governing every template in operations/templates/.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: operations/templates/ template authors; L3 template-storage (single-source-of-truth gate); the template lifecycle and promotion workflow; deploy.sh template checks
---
<!-- reference-durability: allow-link -->
# Template Protocol — PMO Platform

**Last Refreshed:** 2026-05-10
**Authority:** L4 of the 5-Layer Template Architecture. Defines the lifecycle workflow, provenance header schema, and trigger/promotion protocol governing every template in `operations/templates/`. Consumed by L3 Storage (P4 single-source-of-truth gate per [`template-storage.md`](template-storage.md) §6), L5 Governance (consumer-skill integration — ), and instance-level protocols ( provenance /  instance lifecycle /  instance lineage).

**Reversibility tier:** MODERATE — Confidence: HIGH. Protocol doc itself is reversible per file via `git revert`. Coupling intensifies once ≥3 consumer SKILL.md files reference the protocol — at baseline, zero SKILL.md edits have landed (L5 Governance is a separate sub-issue), so revert cost is currently low; retroactive schema change after L5 ships requires `pmo-skill-editor` re-edit of N skills.

## §1 Purpose

This document is L4 of the 5-Layer Template Architecture. It defines (a) the **5-state lifecycle workflow** (DRAFT → REVIEWED → APPROVED → PROMOTED → ARCHIVED) that every canonical template carries, (b) the **provenance header schema** (14 fields) that records that lifecycle state plus authorship, lineage, and canon-compat attribution on each template file, and (c) the **trigger protocol T1-T5 + promotion gates P1-P5** that govern when a document/format becomes a template candidate and when a candidate is promoted to canonical status. It exists in parallel to [`template-taxonomy.md`](template-taxonomy.md) (L1 — what artifact families exist) and [`template-storage.md`](template-storage.md) (L3 — where templates live + how they propagate). Per the layer-per-file architecture, this doc owns the lifecycle + provenance + trigger concerns only; the registry layout and propagation contract live in L3, and the consumer-skill integration pattern lives in L5.

This protocol provides L4 **schema primitives** (state names, provenance field shapes, trigger primitives) consumed **downstream** by L3 Storage (P4 gate-evaluation against `canonical_path`), L5 Governance (when-to-templatize routing), and the three instance-level protocols (provenance header for artifact instances in 08-Generated/, DRAFT→APPROVED workflow for AI-generated artifact instances, artifact-to-artifact lineage on instances). The composition boundary with each of those consumers is documented in §8.

## §2 Scope of Enforcement

### What IS enforced

This protocol governs every file at `operations/templates/` — the canonical-template registry per [`template-storage.md`](template-storage.md) §2.1. Each registered template carries a YAML provenance header (markdown templates) or a sibling `.provenance.yml` file (CSV templates) per §4.4, and progresses through the 5-state lifecycle defined in §3. Sync-map registration in `TEMPLATE_SYNC_MAP` (deploy.sh) is governed by L3 Storage; this protocol governs only the provenance + state attributes on the canonical source files.

### What is NOT enforced (intentional non-enforcement boundary)

- **Artifact instances** generated at `projects/*/08-Generated/`, `projects/*/01-Governance/`, etc. — these are governed by the three instance-level protocols (provenance / workflow / lineage) which compose with this protocol (see §8) but are not enforced by it.
- **Skill-internal-standalone templates** at `<module>/skills/<skill>/references/...-template.md` that are skill-runtime authoring guidance (per [`template-taxonomy.md`](template-taxonomy.md) §5 platform-internal domain) — these are not in the canonical registry and do not carry the L4 provenance header schema.
- **`references/` mirror copies** at `<module>/skills/<skill>/references/<template-or-standard>` — these are byte-identical mirrors of canonical files, propagated via the L3 deploy-sync mechanism. They inherit provenance state from the canonical source; they do not carry independent lifecycle state.

The composition boundary with downstream consumers is documented in §8.

## §3 Lifecycle State Machine

### §3.1 State definitions

| State | Meaning | Who can write the file | What it means for consumers | How detected |
|---|---|---|---|---|
| `DRAFT` | Template authored but not yet reviewed | Skill OR operator | Not propagated to skill `references/` mirrors; not cited from SKILL.md as authoritative | `review_status: DRAFT` in provenance header |
| `REVIEWED` | At least one substantive human read-pass complete; reviewer named | Owner or designated reviewer | Still not propagated to mirrors; eligible for APPROVED transition | `review_status: REVIEWED` + `reviewer:` populated |
| `APPROVED` | All P1-P5 promotion gates evaluated; canon-compat resolved | Operator only | Eligible for propagation to skill mirrors; may be cited from SKILL.md | `review_status: APPROVED` + `canon_compat:` populated |
| `PROMOTED` | Template consumed by ≥1 deployed skill OR cited in operator-facing governance doc; registered in `TEMPLATE_SYNC_MAP` | Skill OR operator | Live in workspace; sync-checked on every `./deploy.sh --check` (Check 13) | `review_status: PROMOTED` + entry in `TEMPLATE_SYNC_MAP` |
| `ARCHIVED` | Template superseded by a successor OR scope retired | Operator only | Read-only reference; no new instances should be produced from this template; consumers cite `superseded_by` for the active replacement | `review_status: ARCHIVED` + `superseded_by:` populated (or scope-retired rationale in `supersedes:`) |

### §3.2 Transition rules

| From | To | Authorizer | Required conditions | Provenance fields updated |
|---|---|---|---|---|
| (none) | `DRAFT` | Skill OR operator | Template file created with required frontmatter; `template_family` + `domain` declared | `created`, `updated`, `review_status: DRAFT`, `generated_by`, `owner` |
| `DRAFT` | `REVIEWED` | Operator (or designated reviewer named in `owner`) | ≥1 substantive read-pass by a human reviewer; reviewer name set in `reviewer:` | `updated`, `review_status: REVIEWED`, `reviewer` |
| `REVIEWED` | `APPROVED` | Operator only (Autonomy Tier 0 — operator-only authority per [`autonomy-tiers.md`](../specs/autonomy-tiers.md)) | All P1-P5 promotion gates evaluated; gate decisions recorded; canon-compat resolution complete | `updated`, `review_status: APPROVED`, `canon_compat` |
| `APPROVED` | `PROMOTED` | Skill OR operator | Template now consumed by ≥1 deployed skill OR cited in operator-facing governance doc; `canonical_path` declared per L3 propagation mechanism; sync-map entry registered if mirrored | `updated`, `review_status: PROMOTED`, `canonical_path` |
| ANY | `ARCHIVED` | Operator only | Template superseded (set `superseded_by:` on this template; set `supersedes:` on the successor) OR template scope retired | `updated`, `review_status: ARCHIVED`, `superseded_by` |
| `ARCHIVED` | (terminal) | — | — | — |

**Backward transitions** (e.g., `APPROVED` → `REVIEWED` if a gate decision is reversed) are operator-authorized only and require a deviation-log entry in the parent release plan. They are not part of the normal forward lifecycle; the canonical path is monotonic state advancement.

### §3.3 State sub-sections

The five state sub-sections below establish the authoritative entry/exit conditions per state. Each sub-section uses the `###` header level required by  AC1 verification (`grep -cE '^### (DRAFT|REVIEWED|APPROVED|PROMOTED|ARCHIVED)$' ≥ 5`).

### DRAFT

**Definition.** The template file exists at its canonical path with the required frontmatter, but no human review has occurred. Default starting state for any new template authored by a skill or operator.

**Entry conditions.** Template file is committed to `operations/templates/` with a complete provenance header per §4.1. Required fields: `artifact_type: template`, `template_family`, `domain`, `canonical_path`, `owner`, `review_status: DRAFT`, `created`, `updated`, `generated_by`. Optional fields may be left as placeholders (e.g., `reviewer: N/A`).

**Exit conditions.** Designated reviewer (named in `owner`, OR operator) completes at least one substantive read-pass and sets `reviewer:` to their name. Trivial whitespace edits or typo fixes do NOT count as substantive review; the read-pass must evaluate structure and content fitness.

**Example.** A skill drafts `raid-log-template.csv` as part of a release. Provenance header: `review_status: DRAFT, reviewer: N/A, created: 2026-05-10, generated_by: pmo-skill-refiner vX.Y`. The template is committed to the canonical registry but not yet referenced from any SKILL.md.

### REVIEWED

**Definition.** A designated reviewer has completed at least one substantive read-pass of the template content. The template is still not propagated to skill mirrors and is not cited from SKILL.md as authoritative.

**Entry conditions.** Reviewer name is set in `reviewer:` field. `review_status` is bumped to `REVIEWED` and `updated:` is bumped to the review date.

**Exit conditions.** Operator evaluates all P1-P5 promotion gates (§6); each gate decision is recorded (per-gate evidence rendered in the parent release plan or in a comment on the parent issue). Once all gates PASS, operator transitions to `APPROVED` and sets `canon_compat:` to the resolution path (a/b/c) per P5.

**Example.** The same `raid-log-template.csv` from the DRAFT example is reviewed by the operator; `reviewer: [OPERATOR_NAME]` is set, `review_status: REVIEWED`. Operator has not yet rendered the P5 canon-compat decision.

### APPROVED

**Definition.** All P1-P5 promotion gates have been evaluated and recorded; the template is eligible for propagation to skill `references/` mirrors and for citation from SKILL.md. The lifecycle exemplar in §7 reaches this state.

**Entry conditions.** Operator-rendered approval (Autonomy Tier 0 per [`autonomy-tiers.md`](../specs/autonomy-tiers.md) — operator-only authority for promotion; no skill or agent can self-approve). `canon_compat:` is set to one of `plugin-aligned` / `PMO-extension` / `none` per P5 resolution. `review_status: APPROVED`. `updated:` bumped to the approval date.

**Exit conditions.** Template is registered in `TEMPLATE_SYNC_MAP` (per L3 [`template-storage.md`](template-storage.md) §6) AND consumed by ≥1 deployed skill OR cited from an operator-facing governance doc — the template transitions to `PROMOTED`.

**Example.** `PMO_Platform_Template.md` reaches `APPROVED` with `canon_compat: none` (per P5 path (c) — project-domain with no Anthropic plugin counterpart for the KT-Onboarding family). See §7.

### PROMOTED

**Definition.** Template is live in workspace consumption — registered in `TEMPLATE_SYNC_MAP`, mirrored to ≥1 skill's `references/` subtree, or directly cited from an operator-facing governance doc. The template is the authoritative source-of-truth for its artifact family per L3 P4 gate.

**Entry conditions.** `canonical_path:` is set to the repo-relative SSoT path. Sync-map entry for the template exists in `deploy.sh` `TEMPLATE_SYNC_MAP` (if mirrored) OR the template is cited from an operator-facing governance doc with a stable link. `review_status: PROMOTED`. `updated:` bumped to the promotion date.

**Exit conditions.** Template is superseded by a successor template (set `superseded_by:` on this template; set `supersedes:` on the successor) OR scope is retired by operator decision — transitions to `ARCHIVED`. PROMOTED is the steady-state of a canonical template; most templates remain PROMOTED for their useful lifetime.

**Example.** `template-taxonomy.md` (L1 standards doc) reaches `PROMOTED` — registered in `TEMPLATE_SYNC_MAP` with 6 mirror entries (one per consumer skill); cited from L3 [`template-storage.md`](template-storage.md) §1 and §9. Note: standards docs are governed by the same protocol as templates per §2 enforcement scope.

### ARCHIVED

**Definition.** Template is no longer the authoritative source for its artifact family. Either superseded by a named successor template OR scope-retired without successor. Read-only reference state; consumers should cite the successor (when present) instead.

**Entry conditions.** Operator-rendered archival decision. Either `superseded_by:` is set to the successor filename (and the successor's `supersedes:` field points back to this archived template — the lineage chain in §9 is updated), OR `supersedes:` is set with a scope-retired rationale and `superseded_by: N/A`. `review_status: ARCHIVED`. `updated:` bumped to the archival date.

**Exit conditions.** Terminal — no further transitions. ARCHIVED templates remain in the canonical registry as read-only historical reference for ≥1 release cycle (per L5 Governance retention policy when finalized), then may be physically removed from the registry in a future release with the lineage record preserved in §9.

**Example.** Hypothetical: `raid-log-template.csv` is superseded by `raid-log-template-v2.csv` at a later release. Archived template's frontmatter: `review_status: ARCHIVED, superseded_by: raid-log-template-v2.csv, updated: 2026-XX-XX`. Successor's frontmatter: `supersedes: raid-log-template.csv`. §9 lineage graph records the chain.

## §4 Provenance Header Schema

### §4.1 YAML schema block (canonical, copy-pasteable)

The canonical YAML provenance block placed at the top of every markdown template (or in a sibling `.provenance.yml` file for CSV templates, per §4.4):

```yaml
---
artifact_type: template
template_family: <ADR | Runbook | Status Report | RAID | KT-Onboarding | ...>  # value from L1 §3-§5
domain: project | software | platform-internal
canonical_path: operations/templates/<file>
owner: <skill-name | operator-name>
review_status: DRAFT | REVIEWED | APPROVED | PROMOTED | ARCHIVED
created: YYYY-MM-DD
updated: YYYY-MM-DD
generated_by: <author-or-skill-name + version, e.g., operator | pmo-skill-refiner vX.Y>
reviewer: <name | N/A>
canon: <Nygard 2011 | PMBOK 7 §Measurement | Google SRE §Runbook Design | ...>  # required for domain: software
canon_compat: plugin-aligned | PMO-extension | none
version: vX.Y  # per version-field-semantics.md regex ^v[0-9]+\.[0-9]+(-[a-z]+)?$
supersedes: <filename | N/A>
superseded_by: <filename | N/A>
---
```

### §4.2 Field-by-field reference

| Field | Required | Type | Allowed values / format | Source / Purpose |
|---|---|---|---|---|
| `artifact_type` | YES | string | `template` (constant) | Distinguishes template files from instance files (which use the  instance enum). The constant `template` value is L4-owned. |
| `template_family` | YES | string (enum) | A value from L1 [`template-taxonomy.md`](template-taxonomy.md) §3-§5 family enumeration | Anchors the template to the L1 taxonomy; informs P5 gate and §8 composition routing. |
| `domain` | YES | enum | `project` \| `software` \| `platform-internal` | Three-domain classification per [`template-taxonomy.md`](template-taxonomy.md) §2; informs P5 path (c) eligibility. |
| `canonical_path` | YES | path string | repo-relative path | P4 gate evaluation input; declares the single-source-of-truth location per L3 propagation mechanism ([`template-storage.md`](template-storage.md) §3 deploy-sync). |
| `owner` | YES | string | skill-name OR operator-name | P1 gate evaluation input. |
| `review_status` | YES | enum | `DRAFT` \| `REVIEWED` \| `APPROVED` \| `PROMOTED` \| `ARCHIVED` | Lifecycle state per §3. P2 gate evaluation input. |
| `created` | YES | date | `YYYY-MM-DD` | Template authoring date (NOT first-use date). |
| `updated` | YES | date | `YYYY-MM-DD` | Last material edit. Parallel convention to `version-field-semantics.md` bump rules — bumped on every state transition and every substantive content edit; not bumped on whitespace fixes. |
| `generated_by` | YES | string | `<author-or-skill> + version` | Template authoring attribution. **Semantic shift from **: 's `generated_by` is the generating skill for an artifact instance; here it is the template-authoring skill OR operator name. Documented in §4.3 + §8. |
| `reviewer` | OPTIONAL | string | name OR `N/A` | Set on `DRAFT` → `REVIEWED` transition; the human who APPROVED the template state. **Semantic overload with **: 's `reviewer` is the instance reviewer; here it is the template approver. Documented in §4.3 + §8. |
| `canon` | YES (for `domain: software`); OPTIONAL otherwise | string | named canon per L1 [`template-taxonomy.md`](template-taxonomy.md) §6 mapping (Nygard 2011 / PMBOK 7 / Google SRE / IETF / etc.) | P5 gate evaluation input. |
| `canon_compat` | YES | enum | `plugin-aligned` \| `PMO-extension` \| `none` | P5 gate evaluation result. Path `none` is permitted ONLY for `domain: project` templates without an Anthropic plugin counterpart (per §6 P5 path (c)). |
| `version` | YES | string | `^v[0-9]+\.[0-9]+(-[a-z]+)?$` per [`version-field-semantics.md`](version-field-semantics.md) regex | Template version. Same release-tag-at-last-material-edit convention as SKILL.md `version:` field. |
| `supersedes` | OPTIONAL | filename | filename OR `N/A` | Lineage primitive — points to the prior template this one supersedes. **Shared field NAME with ** which uses the same field for instance-to-instance lineage. Dual-semantics documented in §8 (file scope distinguishes — templates at `operations/templates/`; instances at `projects/*/08-Generated/`). |
| `superseded_by` | OPTIONAL | filename | filename OR `N/A` | Lineage primitive — points to the successor template that supersedes this one. **Shared field NAME with ** (dual semantics — see §8). |

### §4.3 Compatibility with  (downstream artifact-instance schema)

The provenance header schema in §4.1 is **field-by-field compatible** with the artifact-instance schema. Every L4 field that matches an instance-schema field name uses identical type and format. Two semantic shifts are documented (not naming conflicts; same field-name applied to different populations).

| Field | In  instance schema? | In L4 template schema? | Compatibility status | Note |
|---|---|---|---|---|
| `artifact_type` | YES (enum: Runbook \| SOP \| Status Update \| Briefing \| Analysis \| Plan \| Email Draft) | YES (constant `template`) | **COMPATIBLE** — value space extends; no naming conflict | Templates use single value; instance enum applies to instances. |
| `target_folder` | YES | NO | **N/A** — templates have no target folder | Templates live at canonical path; instances live at target folder. |
| `project` | YES | NO | **N/A** — templates are project-agnostic | |
| `program` | YES | NO | **N/A** — templates are program-agnostic | |
| `created` | YES | YES | **COMPATIBLE** — same name, same format | Same `YYYY-MM-DD` date type. |
| `updated` | YES | YES | **COMPATIBLE** — same name, same format | Same `YYYY-MM-DD` date type. |
| `generated_by` | YES (generating skill + version for instances) | YES (template-authoring skill OR operator name) | **COMPATIBLE WITH SEMANTIC SHIFT** — same field name, scope-shifted value | Documented above (§4.2) and in §8 to prevent reader conflation. |
| `source_inputs` | YES (TR-### \| MSG-### \| file path for instances) | NO | **N/A** — templates are sources, not derivatives | |
| `review_status` | YES (`DRAFT` \| `REVIEWED` \| `APPROVED` \| `PROMOTED` \| `ARCHIVED`) | YES (same enum) | **COMPATIBLE — LOAD-BEARING SHARED FIELD** | This is the load-bearing primitive that  implements as workflow for instances. |
| `confidence` | YES (HIGH \| MEDIUM \| LOW for instances) | NO | **N/A** — confidence applies to instance generation, not to a template | |
| `reviewer` | YES (instance reviewer) | OPTIONAL (template approver) | **COMPATIBLE WITH SEMANTIC OVERLOAD** — same field name, scope-shifted value | Documented above (§4.2) and in §8. |

**Naming conflicts with : NONE.** Every L4 field that shares a name with a  field uses identical type and format. The two semantic shifts (`generated_by` + `reviewer`) are scope-localized interpretations applied to different artifact populations (templates vs instances). These are NOT conflicts; they are the canonical pattern for shared field NAMES across composition boundaries (parallel to how `created` / `updated` mean the same date concept in both schemas — only the population context differs).

**NEW fields in the L4 schema not in :** `template_family`, `domain`, `canonical_path`, `owner`, `canon`, `canon_compat`, `version`, `supersedes`, `superseded_by`. These are L4-owned **primitives**.  MAY cite them when defining instance-level relationships (e.g., a hypothetical `template_origin:` field on an instance pointing back to the template that produced it — IF  adds such a field at its future implementation; not a current-scope concern).

### §4.4 Frontmatter placement convention

**Markdown templates** (`*-template.md` in the canonical registry): Provenance header is a YAML block between `---` markers placed at the top of the file, before any prose content. Standard markdown frontmatter convention.

**CSV templates** (`*-template.csv` in the canonical registry): CSV files do not support inline frontmatter (the header row is data, not metadata). Provenance for CSV templates lives in a sibling `<file>.provenance.yml` file at the same path. Example: `raid-log-template.csv` has its provenance in `raid-log-template.provenance.yml` in the same directory.

**AC4 verification clauses (per template format):**
- For markdown exemplars: `grep -l 'review_status: APPROVED' operations/templates/*.md`
- For CSV exemplars (if ever): `grep -l 'review_status: APPROVED' operations/templates/*.provenance.yml`

CSV-specific handling rationale: Foundation Stage 5 hypothesized CSV templates as `keep-canonical-only` with mechanical drift-detection via `md5sum`; sibling-file provenance preserves CSV format integrity while supporting the same gate evaluation against `review_status`.

## §5 Trigger Protocol — When to Templatize (T1-T5)

A document or format becomes a **template candidate** when ANY of the following triggers fire. T1-T4 are verbatim from the  parent initiative body (operator-approved at Stage 2 Triage). T5 is the L4-refined high-priority trigger that closes the deferred T5-reserved slot from Stage 4 D-Gate.

**T1. ≥2 instances of the same artifact exist across active projects (DRY).** Two or more workspace instances of an artifact in the same family signal a recurring need that warrants a shared format definition. Counting basis: a "workspace instance" is any rendered artifact file at `projects/*/08-Generated/` (or analogous location) with the artifact family identifiable from filename or content.

**T2. The format is stakeholder-facing AND will recur (consistency posture).** Even with a single current instance, a format that goes to stakeholders (PMs / sponsors / SteerCo / external) and is expected to recur (status reports, governance docs, decision briefs, etc.) warrants a template to enforce consistency across future instances.

**T3. ≥1 skill produces it and the format is currently inline in SKILL.md (extraction signal).** A format embedded inline in a SKILL.md (rather than externalized to a `references/` template file) is a code-smell — it conflates skill behavior with artifact structure. Extracting to a canonical template + `references/` mirror is the canonical L5 Governance refactor pattern.

**T4. The artifact appears in PMBOK / native canon for a covered delivery_approach or software-engineering domain.** External best-practice canons (PMBOK 7 / Nygard / Google SRE / IETF / Anthropic plugin convention) prescribe structured artifact formats for many domains; if the artifact family has a named canon-defined structure, a PMO template anchoring to that canon is the canonical path to bring the workspace into alignment with the external best practice.

**T5. Canon-AND-instance evidence (high-priority signal).** An external best-practice canon (PMBOK 7 / Nygard / Google SRE / IETF / Anthropic plugin convention per L1 [`template-taxonomy.md`](template-taxonomy.md) §6 mapping) prescribes a structured artifact for the family **AND** ≥1 instance of the artifact has been observed in workspace history (08-Generated/, project artifacts, transcript references, prior decisions log). Trigger fires when **BOTH** conditions hold; cite the canon section AND the instance evidence (file path or transcript reference). **Distinct from T1** (which counts instances without canon backing) **and from T4** (which counts canon backing without observed instances) — T5 identifies templates with both demand-side (instance-observed) and authority-side (canon-prescribed) signals, raising priority above T1-only or T4-only candidates.

**Composition with T1-T4.** T5 does NOT replace T1-T4; it adds a higher-priority signal when both demand and authority are present. A template candidate may be eligible under T1 only, T4 only, T1+T4 (then evaluated as T5-eligible — citation of both signals satisfies the BOTH clause), or T5 directly. T2 / T3 are independent dimensions that compose with any of T1 / T4 / T5.

## §6 Promotion Gates — Requirements for Canonical Status (P1-P5)

A template candidate is **PROMOTED to the canonical registry** when ALL of P1-P5 are satisfied. P1-P4 are verbatim from the  parent initiative body. P5 is the L4-refined upstream-compatibility gate that closes the deferred P5-reserved slot from Stage 4 D-Gate.

**P1. Owner is named (skill or operator).** The `owner:` field in the provenance header (§4.1) is populated with a non-empty skill name or operator name. Anonymous templates are not eligible for canonical promotion.

**P2. Lifecycle state is APPROVED.** The `review_status:` field is `APPROVED` (per §3.3 APPROVED entry conditions — all P1-P5 gates evaluated; transition operator-rendered). P2 is recursive in the sense that "all gates evaluated" includes P2 itself; the recursion resolves at the operator-authorized transition (Autonomy Tier 0 per [`autonomy-tiers.md`](../specs/autonomy-tiers.md)).

**P3. ≥1 instance exists in 08-Generated/ (project) or analogous proof-of-utility location (software) as evidence.** For project-domain templates, an instance at `projects/*/08-Generated/` (or `01-Governance/`, etc.) demonstrates the template has been exercised in practice. For software-domain templates, the analogous proof-of-utility location may be a rendered artifact at `<OPERATOR_INSTANCE_ANALYSIS_PATH>/`, a governance doc citing the template's structure, or a transcript reference. Cite the instance path.

**P4. Single-source-of-truth declared (no parallel copies).** The `canonical_path:` field declares the SSoT location. Any byte-identical mirror copies (e.g., in skill `references/`) must propagate from the canonical via the deploy-sync mechanism per L3 [`template-storage.md`](template-storage.md) §3 — no parallel-canonical state is permitted. Drift between canonical and mirror is detected by `./deploy.sh --check` Check 13.

**P5. Upstream-compatibility resolution.** Either:

  - **(a) plugin-aligned**: a canonically-mapped Anthropic plugin skill exists for this artifact family per L1 [`template-taxonomy.md`](template-taxonomy.md) §6 mapping AND the PMO template's field shape has been drift-checked at promotion time against the plugin's convention (cite the plugin name, the drift-check date, and the schema-comparison method per [`decision-discipline.md`](../disciplines/decision-discipline.md) §2.1 Mechanism 1 evidence-format), OR
  - **(b) PMO-extension**: operator has explicitly approved PMO-extension status with a documented rationale and a named mitigation (registered in [`canonical-skill-structure.md`](canonical-skill-structure.md) PMO-extensions appendix or equivalent governance artifact) per the D-Gate Template upstream-compatibility subsection per [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) §D-Gate Template, OR
  - **(c) none**: the template's `domain:` is `project` AND no Anthropic plugin counterpart exists for the artifact family (e.g., RAID Log, Status Report, KT-Onboarding) — the upstream-compat dimension does not apply to project-domain artifacts that lack plugin equivalents.

The `canon_compat:` field in the template provenance header (per §4.1) records which path (a/b/c) applies. P5 verification = `grep canon_compat: operations/templates/<file>` returns one of three permitted values; paths (a) and (b) require the cited evidence to be machine-locatable. Path (c) is permitted ONLY when `domain: project` AND no Anthropic plugin counterpart exists per L1 [`template-taxonomy.md`](template-taxonomy.md) §6.

**Composition with cross-D upstream-compatibility scan.** P5 is the per-template instantiation of the cross-D upstream-compatibility scan defined in [`release-process.md`](../../release/governance/release-process.md) Collective Review Protocol. Every D-decision in a release that touches templates must verify P5 alignment per the release's Collective Review.

## §7 Lifecycle Exemplar

### §7.1 Exemplar choice and rationale

The L4 lifecycle exemplar — the template promoted through the full `DRAFT` → `APPROVED` lifecycle as proof-of-protocol — is `operations/templates/PMO_Platform_Template.md`.

**Selection criteria** (per AC4 + L4 Stage 5 DD-E):

1. **Clear provenance addable.** Markdown format; frontmatter goes at the top cleanly without disturbing the prose body.
2. **Viable lineage path.** The template produces stakeholder KT artifacts (HTML or rendered docs) — one observed instance per platform release per L1 [`template-taxonomy.md`](template-taxonomy.md) §3.2 Team domain row.
3. **Lowest blast radius.** `PMO_Platform_Template.md` is **canonical-only** — no project-initiator mirror, no other-skill-embedded copy. Adding frontmatter does NOT trigger L3-Storage deploy-sync entanglement in the same release.

**Comparison vs alternatives.** Of the 12 canonical templates at baseline, `PMO_Platform_Template.md` is the **only** template without a project-initiator mirror — it is the unique candidate with **zero** coupling to L3-Storage's deploy-sync work in the same release. Choosing any mirrored template would couple L4-Lifecycle and L3-Storage Engineering ordering (frontmatter must propagate via deploy-sync, requiring the L3 sync hook to exist before L4 frontmatter add can be end-to-end verified). Choosing `PMO_Platform_Template.md` decouples the two sub-issues entirely.

### §7.2 Exemplar provenance header (rendered)

```yaml
---
artifact_type: template
template_family: KT-Onboarding
domain: project
canonical_path: operations/templates/PMO_Platform_Template.md
owner: [OPERATOR_NAME]
review_status: APPROVED
created: 2026-03-27
updated: 2026-05-10
generated_by: operator
reviewer: [OPERATOR_NAME]
canon: PMBOK 7 §Lifecycle (project closing)
canon_compat: none
version: vX.Y
supersedes: N/A
superseded_by: N/A
---
```

**`canon_compat: none` rationale.** Per P5 path (c): `domain: project` AND no Anthropic plugin counterpart for the KT-Onboarding artifact family. Note: the Anthropic `human-resources:onboarding` plugin is for HR / employee onboarding, NOT for platform / system knowledge-transfer documentation; semantic mismatch — path (c) `none` is correct for this template per the L1 [`template-taxonomy.md`](template-taxonomy.md) §3.2 emergent-gap analysis row.

### §7.3 AC4 verification

The protocol AC4 verification chain:

```
$ grep -l 'review_status: APPROVED' operations/templates/*.md
operations/templates/PMO_Platform_Template.md
$ grep -A 8 '^## §9' core/standards/template-protocol.md | head -12
# (returns the lineage table with the PMO_Platform_Template seed row — see §9)
```

## §8 Composition Boundary with Downstream Consumers

This protocol provides L4 **primitives** (state names, field names, trigger primitives). Three downstream consumers compose with this protocol by REFERENCING those primitives and IMPLEMENTING consumer-specific behavior in their own milestones and SKILL.md files:  (provenance for AI-generated artifact instances in 08-Generated/),  (DRAFT→APPROVED workflow for instances),  (artifact-to-artifact lineage on instances).

### §8.1 Authoritative composition table

| Concern | L4 (this protocol) |  (provenance for AI artifacts in 08-Generated/) |  (DRAFT→APPROVED workflow for AI artifacts) |  (artifact lineage graph) |
|---|---|---|---|---|
| 5-state enum (`DRAFT`/`REVIEWED`/`APPROVED`/`PROMOTED`/`ARCHIVED`) | **DEFINES** (for templates) | **REFERENCES** (for instances) | **IMPLEMENTS** workflow (for instances) | — |
| `artifact_type` field NAME | DEFINES `template` value | DEFINES instance enum (`Runbook` \| `SOP` \| `Status Update` \| `Briefing` \| `Analysis` \| `Plan` \| `Email Draft`) | — | — |
| `created` / `updated` field NAMES | DEFINES (template authoring dates) | DEFINES (instance generation dates) | — | — |
| `generated_by` field NAME | DEFINES (template authoring attribution — operator OR authoring skill+version) | DEFINES (generating skill+version for instances) | — | — |
| `review_status` field NAME | DEFINES (template state) | REFERENCES (instance state — same enum) | IMPLEMENTS state transitions on instances | — |
| `reviewer` field NAME | OPTIONAL (template approver — `REVIEWED` → `APPROVED`) | DEFINES (instance reviewer) | — | — |
| `source_inputs` field | NO | DEFINES (upstream evidence: TR-### / MSG-### / file path) | — | — |
| `target_folder` field | NO | DEFINES (instance target location) | — | — |
| `project` / `program` fields | NO | DEFINES | — | — |
| `confidence` field | NO | DEFINES (`HIGH` \| `MEDIUM` \| `LOW`) | — | — |
| `parent_artifact` / `sibling_topic` fields | NO | — | — | DEFINES (artifact-to-artifact lineage on instances); the authoritative schema home for these instance-lineage fields is `core/schemas/frontmatter-schema.md` (Domain A / Domain C) |
| `supersedes` / `superseded_by` field NAMES | **DEFINES** (template versioning chain) | — | — | **DEFINES** (artifact lineage on instances) — **SHARED FIELD NAME, DUAL SEMANTICS** (see drift-prevention rule 5); the instance-lineage scalar semantics are authoritatively defined in `core/schemas/frontmatter-schema.md` (Domain A / Domain C) |
| `template_family` / `domain` / `canonical_path` / `owner` / `canon` / `canon_compat` / `version` fields | DEFINES (L4-only, not in any consumer) | — | — | — |

### §8.2 Drift-prevention rules

1. **Each consumer (provenance, workflow, lineage) MUST cite this protocol** when defining its instance-level schema. Concrete mechanism: in the consumer's implementation, the instance schema documentation references this `template-protocol.md` §3 (state machine) for the state enum AND §4 (schema) for shared field names. The same pattern applies across all three.
2. **L4 MUST cite each consumer in §8.1.** This protocol enumerates each consumer's owned fields explicitly so a reader of this protocol knows which fields are out of L4 scope. The table in §8.1 is bidirectional reference.
3. **The 5-state enum is L4's authoritative definition.** Consumers REFERENCE it; consumers do NOT redefine it. If a consumer needs an instance-only state (e.g., `IN_REVIEW` distinct from `REVIEWED`), the consumer MUST file an upstream issue against L4 to extend the enum — silent local extension is forbidden.
4. **Field NAMES that appear in both L4 and a consumer schema MUST have aligned semantics in the documentation,** even when the value differs (e.g., `created` means the same date concept; the value population context differs because one is template and the other is instance). Documentation in BOTH locations must reference the other (L4 §4 references  schema;  schema MUST reference L4 §4 in its implementation).
5. **Dual-semantics field names MUST be flagged in BOTH locations.** Specifically: `generated_by` (template-author vs instance-generator), `reviewer` (template-approver vs instance-reviewer), `supersedes` / `superseded_by` (template-version-chain vs instance-lineage). These are NOT conflicts; they are scope-localized interpretations. The flag prevents future readers from collapsing the two interpretations into one. File scope distinguishes (templates at `operations/templates/`; instances at `projects/*/08-Generated/`).

### §8.3 Single load-bearing ambiguity flag

**`supersedes` / `superseded_by` SHARED field name with the artifact-instance lineage schema.** L4 uses these fields for template versioning chains (template v1 → template v2). The instance-lineage schema (authoritatively defined in `core/schemas/frontmatter-schema.md`, Domain A / Domain C) uses the same field names for instance-to-instance lineage (instance A supersedes instance B in a version-iteration chain). Same field name, parallel semantics in two scopes (template versioning vs instance lineage). **Resolution:** documentation discipline per drift-prevention rule 5 above — both this protocol and the frontmatter schema MUST flag the dual semantics in their respective docs. No naming conflict (the file scope distinguishes — templates at `operations/templates/`; instances at `projects/*/08-Generated/`); only documentation discipline is required.

## §9 Lineage Graph

The lineage graph is an appendix recording template-to-template versioning relationships across the canonical registry. Currently, the lineage graph is rendered inline in this protocol; when the dedicated artifact-lineage file ships, the template lineage portion may migrate to a co-located file under `core/` and this §9 will be updated with a supersede pointer.

### §9.1 Schema

Each lineage row carries the following fields:

| Field | Description |
|---|---|
| `template_id` | Canonical template filename |
| `canonical_path` | Repo-relative path to the canonical source |
| `first_committed` | Date of first commit (template `created:` field) |
| `supersedes` | Prior template filename this one supersedes (or `N/A`) |
| `superseded_by` | Successor template filename that supersedes this one (or `N/A`) |
| `known_instance_locations` | Glob pattern(s) for known rendered instances of this template (informational; not authoritative — full instance index lives in the dedicated artifact-lineage file) |

### §9.2 Lineage entries

| `template_id` | `canonical_path` | `first_committed` | `supersedes` | `superseded_by` | `known_instance_locations` |
|---|---|---|---|---|---|
| `PMO_Platform_Template.md` | `operations/templates/PMO_Platform_Template.md` | 2026-03-27 | N/A | N/A | `projects/Archive/*/PMO_Platform_KT_*.html` (informational; one HTML instance per platform release per L1 §3.2) |

Future lineage entries are added at the L4 Stage 6 commit that promotes any subsequent template through the lifecycle. Successor templates' rows also update the predecessor's `superseded_by:` field to maintain a bidirectional chain.

### §9.3 Future location pointer

The full artifact-lineage graph (covering both template lineage AND instance lineage with `parent_artifact:` / `sibling_topic:` fields) ships in a dedicated file (per a dedicated follow-up scope). At that point, this §9 will be updated with a supersede pointer to the new location, and the template-lineage rows may migrate. Until then, this §9 is the authoritative template-lineage record.

## §10 References

- [`template-taxonomy.md`](template-taxonomy.md) — L1 of the 5-Layer Template Architecture (artifact-family taxonomy + canon-per-family mapping)
- [`template-storage.md`](template-storage.md) — L3 of the 5-Layer Template Architecture (canonical registry layout, propagation mechanism, PDA boundary, sync-map registration)
- [`canonical-skill-structure.md`](canonical-skill-structure.md) — Standards-doc style precedent (numbered §sections, table-driven enumerations, Required-vs-Not-Enforced boundaries)
- [`version-field-semantics.md`](version-field-semantics.md) — `version:` field convention (regex, bump rules, dual-gate enforcement) — reused for template `version:` field in §4
- [`../decision-discipline.md`](../disciplines/decision-discipline.md) — Mechanism 1 (Localization Check) cited in §6 P5 path (a) evidence-format requirement
- [`../hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md) — §D-Gate Template upstream-compatibility subsection (cited in §6 P5 path (b))
- [`../autonomy-tiers.md`](../specs/autonomy-tiers.md) — Tier 0 (operator-only authority) cited in §3 `REVIEWED` → `APPROVED` transition
- [`../pipeline/stage-04-planning.md`](../../release/references/pipeline/stage-04-planning.md), [`../pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md), [`../pipeline/stage-06-engineering.md`](../../release/references/pipeline/stage-06-engineering.md) — Stage 4 / 5 / 6 protocol context (parent release pipeline)
- [`../../../.claude/rules/release-process.md`](../../release/governance/release-process.md) — Collective Review Protocol (cited in §6 P5 cross-D upstream-compat composition)
-  — Parent initiative (5-Layer Template Architecture; source for T1-T4 + P1-P4 verbatim text)
-  — L4 Lifecycle sub-issue (this protocol's authoring scope)
-  — L4 Lifecycle Stage 5 Solutioning (DD-A through DD-F — design inputs for this authoring)
-  — Composition consumer: provenance header for artifact instances in 08-Generated/
-  — Composition consumer: DRAFT→APPROVED workflow for AI-generated artifact instances
-  — Composition consumer: artifact-to-artifact lineage on instances

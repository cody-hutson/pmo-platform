<!-- reference-durability: allow-link -->
# Template Storage Protocol — PMO Platform

**Last Refreshed:** 2026-05-10 (template-architecture release)
**Authority:** L3 of the 5-Layer Template Architecture. Declares canonical registry folder layout, propagation mechanism (deploy-sync), Project-Data-Architecture boundary, and sync-map registration workflow. Consumed by `deploy.sh` template-sync hook, L4 lifecycle gates, and L5 governance.

**Reversibility tier:** MODERATE — Confidence: HIGH. Folder layout is git-revertable per file. Propagation contract becomes harder to retire once 5+ skills couple via TEMPLATE_SYNC_MAP — at baseline only 2 skills (project-initiator, pmo-process-designer) are template-sync targets, so revert cost is currently low; standards-doc sync (per R-NEW1 Option A) extends to 6 consumer skills which raises coupling cost MODERATE.

## §1 Purpose

This document is L3 of the 5-Layer Template Architecture. It defines (a) **WHERE** canonical templates and standards docs live in the engineering tree, (b) **HOW** they propagate to skill `references/` mirrors at deploy time (the `deploy.sh` deploy-sync hook), (c) **HOW** drift between canonical and mirror is detected (`./deploy.sh --check` Check 13), and (d) the **boundary** between Template Architecture (typed-format specification) and Project Data Architecture (entity instance storage).

It exists in parallel to [`template-taxonomy.md`](template-taxonomy.md) (L1 — what artifact families exist) and [`template-protocol.md`](template-protocol.md) (L4 — lifecycle gates). Per the layer-per-file architecture, this doc owns the storage concern only; lifecycle and consumer-integration concerns ship in their own layer docs.

## §2 Canonical Registry Layout

### §2.1 Folder placement

- **Canonical home for templates:** `operations/templates/`
- **Canonical home for standards docs:** `core/standards/`
- **Diátaxis classification:** Both folders are sub-genres of "Reference" per the Option A footnote (Stage 4 D3 evidence trail; reaffirmed at the D-Gate 2026-05-10).
- **Per-folder README:** `operations/templates/README.md` enumerates registered templates with cross-links to [`template-taxonomy.md` §6](template-taxonomy.md) (canon-per-family mapping) and §7 of this doc (registered mirrors). The README protocol itself is light currently; the full per-folder-README protocol ships in a later release.

### §2.2 Naming convention

| Class | Pattern | Examples |
|---|---|---|
| Template files | `<artifact-family>-template.<ext>` (kebab-case; `.md` or `.csv`) | `raid-log-template.csv`, `communications-tracker-template.md`, `project-md-template.md` |
| Standards docs (template-architecture) | `template-<aspect>.md` (kebab-case; `.md`) | `template-taxonomy.md`, `template-storage.md`, `template-protocol.md` |

### §2.3 What lives outside the canonical registry

The four skill-internal-standalone templates surfaced by Foundation Stage 5 — `delivery-engine/raid-templates.md`, `eval-writer/rubric-templates.md`, `pmo-skill-refiner/pmo-platform-template.md`, `release-planner/release-plan-template.md` — are **not** canonical templates currently. They are skill-internal authoring guidance (`location_class: skill-internal-standalone` per the Foundation audit). L5 Governance may evaluate canonicalization for any of these in a future release; until then, they remain platform-internal per [`template-taxonomy.md` §5](template-taxonomy.md).

## §3 Propagation Mechanism (deploy-sync per Stage 4 D5 Option 2)

### §3.1 Authority

The declarative source-of-truth for canonical-to-mirror propagation is the `TEMPLATE_SYNC_MAP` constant in [`deploy.sh`](../deploy/deploy.sh). Each entry is a colon-delimited 3-tuple: `<skill>:<canonical-filename>:<target-path-relative-to-skill-root>`. The deploy-sync hook reads this map at every `cmd_deploy()` invocation.

The canonical source path for each entry is resolved by filename pattern in `resolve_template_sync_source()` (and its byte-aligned mirror `resolve_canonical_source()` in `build-skill-packages.sh`): `*-template.{md,csv}` → `operations/templates/`; `template-*.md` → `core/standards/`; and the explicit shared-standards-doc basenames `output-format.md` and `operational-artifacts.md` → `core/standards/`. The two explicit basenames are single-sourced shared references (consolidated from the former per-skill `references/` copies); they match neither the `template-*` nor the `*-template` pattern, so they are mapped by an explicit narrow basename rule rather than a broad "non-template → `core/standards/`" catch-all — a catch-all would silently re-home any future non-template basename. Single-sourcing a further shared standards doc means adding both its `TEMPLATE_SYNC_MAP` entries and an explicit basename to the resolver (and its package-builder mirror).

### §3.2 Hook implementation

The function `sync_canonical_templates_to_source()` (defined in [`deploy.sh`](../deploy/deploy.sh)) is invoked from `cmd_deploy()` BEFORE the per-skill deploy loop. Algorithm:

1. For each entry matching the current skill filter (or all entries if no filter):
   - Resolve source path: lookup `<canonical-filename>` under `operations/templates/` (for `*-template.{md,csv}`) or `core/standards/` (for `template-*.md`). Source-path subdir is determined by file pattern, not declared per-entry.
   - Resolve target: `<module>/skills/<skill>/<target-path-relative-to-skill-root>`.
   - Create target parent dir if missing.
   - `cp` source → target (overwrite).
   - Verify: post-copy `diff -q` against canonical (byte-identical).
2. Per-file `cp` is atomic (single rename on POSIX). Multi-file batch is NOT transactional — a failure on file N leaves files 1..N−1 in place; caller (`cmd_deploy`) treats as deploy-failure via FAILURES array and surfaces to operator.

### §3.3 Why pre-loop (not in-loop)

`sync_canonical_templates_to_source()` writes to the source tree (`<module>/skills/<skill>/references/...`). Subsequent steps in the per-skill deploy loop (SKILL.md copy + supplementary copy + `.skill` package extraction + user-local mirror) read the source tree and propagate to runtime. Running sync before the loop ensures the per-skill deploy reads a synced source.

Running sync inside the loop AFTER `.skill` package extraction (`deploy.sh` line 519-532) would create a window where the install path holds stale (pre-sync) content extracted from the package while source holds synced content. Pre-loop sync + Check 7 (package-freshness) cooperate to prevent that window.

### §3.4 Anthropic schema preservation

Deploy-sync writes ONLY to the `references/` subtree of each skill. It never modifies SKILL.md, frontmatter, `scripts/`, `assets/`, or skill root. Per `anthropic-skills:skill-creator/SKILL.md` lines 78-84 (drift-checked 2026-05-10):

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

`references/` is the documented "Bundled Resources" location; sync preserves the Anthropic per-skill self-contained model. **No `templates:` or `import:` frontmatter field is added; no cross-skill runtime registry exists; propagation is build-time only.** This is the load-bearing localization (per [`decision-discipline.md` §2.1 Mechanism 1](../disciplines/decision-discipline.md)) that distinguishes the chosen mechanism from the rejected DRY-via-import alternatives (D5 Options 1 + 3 carried `**CONFLICT.**` flags against the Anthropic schema; Option 2 deploy-sync does not).

### §3.5 Drift detection

Two cooperating checks, blocking for registered files and collision-detected basenames:

**Check 13 — registered-mirror drift (always-enforce).** `./deploy.sh --check` Check 13 asserts every entry in `TEMPLATE_SYNC_MAP` has a source canonical AND a byte-identical mirror at the registered runtime target. Always-enforce posture (matches Check 1 / Check 11 — structural, zero-FP profile): a registered mirror that diverges from canonical increments the issue count and makes `--check` (without `--warn`) exit non-zero. Failure remediation: `./deploy.sh --deploy <skill>` re-syncs. This is the enforcing freshness gate — registering a shared reference brings it under Check 13, so once `output-format.md` and `operational-artifacts.md` are registered (8 entries homed at `core/standards/` via the explicit-basename resolver rule), mutating any of their mirrors is caught here.

**Check 13b — shared-reference collision (warn-mode initial).** Check 13 only sees REGISTERED files; an *unregistered* reference basename carried by two or more skills is invisible to it — the exact failure mode that let `output-format.md` exist as six independent copies held identical by discipline alone. Check 13b closes that gap: it enumerates every reference basename under `{operations,release,core}/skills/*/references/` and, for any basename carried by 2+ skills that does NOT resolve to a registered `TEMPLATE_SYNC_MAP` canonical, flags both prongs — (a) **byte-identical** copies (unregistered duplicated source that should be single-sourced and registered) and (b) **divergent** copies (same basename, different content — either intentionally per-skill, such as the four distinct per-module `README.md` files, or an unnoticed drift). Registered basenames are exempt (their byte-identity-vs-canonical is Check 13's job, and their source mirrors are deleted by single-source design). Check 13b ships warn-mode initial via the runtime `.claude/hooks/deploy-check.mode` machinery (the same `flag_warn_or_issue` / mode-resolution helper Checks 8–10 use): in warn-mode it logs a `WARN:` and appends to `deploy-check-warn-log.jsonl` without incrementing the issue count; in enforce-mode it increments the count and exits non-zero.

**Flip-to-enforce path (Check 13b).** Per the [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist: (1) ≥3 days of warn-mode activity logged in `deploy-check-warn-log.jsonl`; (2) review every warn entry — each is either a true collision (single-source it + register, so it falls under Check 13) or an intentional per-skill duplicate (record it on the divergent-prong allowlist); (3) no critical false-positive patterns remaining; (4) operator confirms readiness by setting the runtime `.claude/hooks/deploy-check.mode` to `enforce`. The mode file is the RUNTIME `.claude/hooks/deploy-check.mode` (resolved by `cmd_check`); a mode file authored under `core/hooks/` is inert and does not flip the gate. The flip is an operator decision at a future Stage 13 close.

### §3.5b Contract-fidelity (Check 34)

Check 13 and Check 13b both check *copy*-fidelity — whether two files that are supposed to be the same actually are. Neither checks whether a canonical template conforms to the **schema that governs its instances**. A canonical template can ship sections that no longer match its schema, and copy-fidelity stays green because the mirror is a faithful copy of the *drifted* canonical. Check 34 closes this third axis: **contract-fidelity** — for each schema-bearing canonical template, assert the template carries every section its governing schema mandates.

**Check 34 — template↔schema conformance (warn-mode initial).** `./deploy.sh --check` Check 34 reads an explicit manifest, `TEMPLATE_SCHEMA_MAP`, declared in `cmd_check` alongside the check block. Each manifest entry is a `|||`-delimited 4-tuple: `<template-path>|||<governing-schema-path>|||<schema H2 anchor>|||<pipe-delimited expected H2 sections>`. (The field separator is `|||`, not `:`, because the schema-anchor field legitimately contains a `: ` — e.g. `Tracker 3: Open Meetings Tracker`; the section list inside the fourth field stays pipe-delimited.) For each entry the check locates the schema block bounded by `## <anchor>`, then asserts every expected section appears as a `## ` heading in the template. A missing mandated section is a contract breach. Extra template sections — the parameterized `#`-level Header, an operational `## CHANGE SUMMARY` log — are allowed; only a *missing* mandated section breaches the contract. As defence-in-depth, the check also asserts each manifest expected-section name appears in the cited schema block and warns on a manifest↔schema mismatch, so the manifest's hard-coded section list cannot silently drift from the schema it cites.

**Opt-in by manifest presence (the schema-bearing set).** "Schema-bearing" means "listed in `TEMPLATE_SCHEMA_MAP`." A template with no manifest entry is never inspected — the loop simply never touches it — so a schema-less template cannot false-fail. This makes the skip **structural**, not heuristic: the manifest *is* the authoritative schema-bearing set. The initial manifest carries one entry (the Open Meetings Tracker → `core/schemas/tracker-schemas.md` Tracker 3); the other templates under `operations/templates/` are out of scope until added.

**Register-or-extend rule.** Bringing a further schema-governed template under contract-fidelity is one edit: add a `TEMPLATE_SCHEMA_MAP` line naming the template, its governing schema, the schema anchor, and the expected sections — the same register-to-extend shape as the §6 `TEMPLATE_SYNC_MAP` registration step. Reconcile the template to its schema first (so it conforms on the day it is registered), then add the manifest line. The governing schema is the K1 canonical home under `core/schemas/`; a skill `references/` copy of a schema is a downstream consumer, not the contract source, so the manifest points at the `core/schemas/` original.

**Warn-mode initial + flip-to-enforce path.** Check 34 ships warn-mode initial via the same `flag_warn_or_issue` / runtime `deploy-check.mode` machinery Check 13b uses: in warn-mode a breach logs a `WARN:` and appends `deploy-check-warn-log.jsonl` without incrementing the issue count; in enforce-mode it increments the count and makes `--check` (without `--warn`) exit non-zero. Flip-to-enforce follows the [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md) Shakedown → Enforce Transition Checklist (warn-mode activity logged, every warn entry reviewed, no critical false-positive patterns, operator sets the runtime `.claude/hooks/deploy-check.mode` to `enforce`) — the identical posture and the identical RUNTIME mode file as Check 13b; a mode file authored under `core/hooks/` is inert.

## §4 Anthropic Compatibility

| Concern | This protocol's posture | Evidence |
|---|---|---|
| Per-skill self-contained model | Preserved | Sync writes to `references/` only |
| `name` + `description` frontmatter requirement | Untouched | Sync never modifies SKILL.md or frontmatter |
| `references/` as Bundled-Resources subdir | Honored | Sync targets are always under `references/` |
| Cross-skill `templates:` / `import:` mechanism | Not introduced | Build-time copy, no runtime registry, no schema extension |
| Schema drift since Stage 4 D-Gate | Zero | Lines 78-84 verified verbatim 2026-05-10 (DD-B) |

Operator workflow when Anthropic ships a future schema change touching `references/`: re-verify per the [`decision-discipline.md` §2.1 Mechanism 1](../disciplines/decision-discipline.md) Localization Check pattern. The deploy-sync mechanism may need adjustment if Anthropic introduces a registry-aware runtime model; until then, the build-time copy remains compatible.

## §5 Boundary with Project Data Architecture 

Template Architecture (this initiative) and Project Data Architecture (abbreviated **PDA**) are sibling 5-layer initiatives that **operate at different layers of the document ecosystem** and therefore have non-overlapping scope. This section declares the boundary so PDA's L2 Storage implementation (`_pmo/` shared-entity layout; Plans as typed sub-entities) can inherit aligned boundary semantics.

**Layer mapping** (per [`document-ecosystem-design.md` §6 Three-Layer Architecture](../disciplines/document-ecosystem-design.md)):

| Concern | Owned by | Lives in |
|---|---|---|
| **Typed-format specification** (what fields/sections/structure an artifact must have) | **Template Architecture L3** (this doc) | `operations/templates/` (engineering source tree, Layer 1) |
| **Entity instance data** (the actual values populating a template-specified format at runtime) | **PDA L2 Storage** | `projects/[Project]/`, `projects/_pmo/`, `projects/_config/` (operations tree, Layer 2) |

**Concrete example.** A RAID Log template (`operations/templates/raid-log-template.csv`) declares column headers (RAID Item ID, Type, Description, Owner, Status, etc.) — that is Template Architecture L3 turf. A RAID Item ENTITY for the [PROJECT_KEY] project (a row in `projects/[PROJECT_KEY] Implementation/04-PMO-Operations/[PROJECT_KEY]_RAID_Log.csv` with `RAID-001 | Risk | [COLLEAGUE_I] integration delay | ...`) — that is PDA L2 turf. The template governs the contract; the instance is the data. Template Architecture does not govern WHERE risk instances live in the project folder structure; PDA does not govern WHAT fields a risk has.

**Surface boundary rules:**

1. **Templates declare structure; PDA instances populate structure.** Template Architecture changes the canonical template file; PDA changes never modify `operations/templates/`. PDA changes the project entity layout; Template Architecture changes never modify `projects/`.
2. **Schema/Storage/Presentation separation** (per [`document-ecosystem-design.md` §6](../disciplines/document-ecosystem-design.md)) holds: Templates feed the Schema layer (typed-format specification); PDA L2 owns the Storage layer (how the agent persists entity data on source files); rendering of a RAID instance in Obsidian / Teams / status report is Presentation Layer (separate concern, not in either L3 or L2 scope).
3. **Frontmatter ownership.** PDA  specifies frontmatter fields for entity instances (`type: person`, `aliases:`, etc.). Templates may include `{{frontmatter}}` placeholders that PDA's frontmatter-schema fills in at instance-creation time — but the schema definition is PDA's, the placeholder is the template's. Template Architecture does NOT modify `core/schemas/frontmatter-schema.md`; PDA does NOT modify templates to add frontmatter fields.
4. **Sync direction.** Template Architecture L3's deploy-sync moves canonical templates and standards docs `operations/templates/` + `core/standards/` → skill `references/` mirrors (engineering-internal flow). PDA L2 entity files (`_pmo/people/jane-doe.md`) are runtime-created by skills (project-initiator, ppm-agent) consuming templates — that flow is project-initiator's runtime concern, not L3's sync concern.
5. **Drift-detection ownership.** Check 13 (this initiative) validates canonical-to-mirror drift in the engineering tree. PDA's analogous health checks (per its L3 Automation layer; `health-check-architecture.md`) validate instance-level drift in the operations tree. The two check suites do not overlap.

**What composition looks like over time.** A new project type (e.g., a hypercare-only sub-project under PDA's  typed-sub-entities) introduces a new template (Template Architecture authors it under `operations/templates/hypercare-plan-template.md`) AND a new entity-storage convention (PDA  declares `plan_subtype: hypercare` + lifecycle states in frontmatter-schema). The two changes ship in their respective initiatives' release cycles; neither blocks the other once this boundary is in place.

**Where this boundary IS broken (acceptable cases):** Authoring conveniences. A skill consuming PDA frontmatter schemas (e.g., delivery-engine's RAID writers) may include inline frontmatter examples in its SKILL.md — those are not templates in the L3 canonical-registry sense (they are skill-internal authoring guidance per Foundation Stage 5 audit `location_class: skill-internal-standalone`). The boundary applies to canonical templates in `operations/templates/`, not to every appearance of frontmatter-shaped text across the platform.

**Collective Review consumability test:** An operator reading the boundary above should be able to answer the question "If I am working on PDA  next quarter, do I edit any file under `operations/templates/`?" with a confident "No." (Test passed at Collective Review 2026-05-10.)

## §6 Sync-Map Registration Protocol

When a new template enters the canonical registry, OR a new skill consumes a canonical template or standards doc:

1. Add the source file to its canonical home (`operations/templates/<file>` for templates; `core/standards/template-<aspect>.md` for template-architecture standards docs; `core/standards/<file>` for a shared standards doc that is single-sourced across skills, e.g. `output-format.md`, `operational-artifacts.md`).
2. Add a `TEMPLATE_SYNC_MAP` entry in [`deploy.sh`](../deploy/deploy.sh) — colon-delimited 3-tuple `<skill>:<canonical-filename>:<target-path-relative-to-skill-root>` — one entry per consumer skill. (No SKILL.md edit is required for the registration itself; this is a deploy.sh edit, not a skill-internal edit. SKILL.md modifications, when also needed, route through `pmo-skill-editor` per [`.claude/rules/skill-deployment.md`](../rules/skill-deployment.md).)
3. **If the canonical filename matches neither the `*-template.{md,csv}` nor the `template-*.md` pattern** (the resolver's default routes anything else to `operations/templates/`), add an explicit basename to `resolve_template_sync_source()` in `deploy.sh` AND to its byte-aligned mirror `resolve_canonical_source()` in `build-skill-packages.sh`, mapping the basename to its canonical home. The narrow explicit-basename rule is deliberate — never a broad "non-template → `core/standards/`" catch-all.
4. Document the entry in §7 of this doc (Registered Mirrors).
5. Run `./deploy.sh --deploy <skill>` to perform the initial sync.
6. Run `./deploy.sh --check` to confirm Check 13 passes (Check 13b reports no new collision once the basename is registered).
7. Commit the canonical file + deploy.sh edit + this doc's §7 update in a single commit per the standard release flow ([`.claude/rules/git-workflow.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/git-workflow.md)).

**Note on `template-protocol.md` (L4 deliverable):** `TEMPLATE_SYNC_MAP` entries that reference `template-protocol.md` are added in the L4 Stage 6 commit (after the canonical file exists at `core/standards/template-protocol.md`). Adding those entries before L4 Stage 6 lands would cause Check 13 to ENOENT-fail (canonical missing); the L3 Stage 6 commit deliberately defers them to maintain a green Check 13 across the L3→L4 commit window.

## §7 Registered Mirrors (point-in-time snapshot — see TEMPLATE_SYNC_MAP for authoritative source)

The authoritative list is the `TEMPLATE_SYNC_MAP` array in [`deploy.sh`](../deploy/deploy.sh). The table below mirrors that array as of Stage 6 (2026-05-10) for at-a-glance reference; future drift between this table and the deploy.sh array is detected by `./deploy.sh --check` Check 13's source-side enumeration only — this table is informational, not authoritative.

### §7.1 Template mirrors (21 entries)

| Skill | Canonical filename | Target path (under skill root) |
|---|---|---|
| project-initiator | `communications-tracker-template.md` | `references/templates/communications-tracker-template.md` |
| project-initiator | `daily-status-log-template.md` | `references/templates/daily-status-log-template.md` |
| project-initiator | `daily-status-update-framework-template.md` | `references/templates/daily-status-update-framework-template.md` |
| project-initiator | `executive-status-report-prompt-template.md` | `references/templates/executive-status-report-prompt-template.md` |
| project-initiator | `key-terms-glossary-template.csv` | `references/templates/key-terms-glossary-template.csv` |
| project-initiator | `milestone-tracker-template.md` | `references/templates/milestone-tracker-template.md` |
| project-initiator | `open-meetings-tracker-template.md` | `references/templates/open-meetings-tracker-template.md` |
| project-initiator | `raid-log-template.csv` | `references/templates/raid-log-template.csv` |
| project-initiator | `dual-framing-bridge-template.md` | `references/templates/dual-framing-bridge-template.md` |
| project-initiator | `sprint-tracker-template.md` | `references/templates/sprint-tracker-template.md` |
| project-initiator | `transcript-register-template.md` | `references/templates/transcript-register-template.md` |
| project-initiator | `project-md-template.md` (AC6) | `references/project-md-template.md` (top-level; preserves SKILL.md line 167 read path) |
| pmo-process-designer | `requirements-template.md` (AC7) | `references/requirements-template.md` (top-level; preserves SKILL.md lines 156, 513 read paths) |
| comms-writer | `people-roster-template.yaml` (people-roster data surface; leg-D consumer) | `references/people-roster-template.yaml` |
| ppm-agent | `people-roster-template.yaml` (people-roster data surface; leg-D consumer) | `references/people-roster-template.yaml` |
| ppm-agent | `people-graph-clarification-queue-template.md` (leg-C clarification queue; leg-D consumer) | `references/people-graph-clarification-queue-template.md` |
| project-initiator | `project-charter-template.md` | `references/templates/project-charter-template.md` |
| project-initiator | `stakeholder-register-template.csv` | `references/templates/stakeholder-register-template.csv` |
| project-initiator | `raci-template.md` | `references/templates/raci-template.md` |
| project-initiator | `change-log-template.md` | `references/templates/change-log-template.md` |
| project-initiator | `lessons-learned-template.md` | `references/templates/lessons-learned-template.md` |

### §7.2 Template-architecture standards-doc mirrors (18 entries — 6 consumer skills × 3 standards docs, Option A)

Per R-NEW1 Option A (approved at Collective Review 2026-05-10). 6 consumer skills × 3 template-architecture standards docs = 18 entries. `template-taxonomy.md` + `template-storage.md` rows landed at L3 Stage 6; `template-protocol.md` row landed at L4 Stage 6  — all rows now LIVE in `TEMPLATE_SYNC_MAP`.

| Standards doc | Consumer skills | Target path (under each skill root) | Status |
|---|---|---|---|
| `template-taxonomy.md` | pmo-skill-refiner, pmo-process-designer, project-initiator, delivery-engine, eval-writer, release-planner | `references/template-taxonomy.md` | LANDED — L3 Stage 6  |
| `template-storage.md` | pmo-skill-refiner, pmo-process-designer, project-initiator, delivery-engine, eval-writer, release-planner | `references/template-storage.md` | LANDED — L3 Stage 6  |
| `template-protocol.md` | pmo-skill-refiner, pmo-process-designer, project-initiator, delivery-engine, eval-writer, release-planner | `references/template-protocol.md` | LANDED — L4 Stage 6  |

### §7.3 Shared standards-doc mirrors (8 entries — single-sourced shared references)

Two shared standards docs — formerly carried as per-skill `references/` duplicate copies held identical by discipline alone — consolidated to single canonicals at `core/standards/` and registered in `TEMPLATE_SYNC_MAP` (the single-source-shared-references + enforced-rebuild work; provenance in §9). Consumer counts differ per doc (not a clean N×M product), so the entries are listed explicitly rather than as an arithmetic product. Total standards-doc mirror entries across §7.2 + §7.3 = 18 + 8 = 26; total map entries (template mirrors + standards-doc mirrors) = 21 + 26 = 47.

| Standards doc | Consumer skills | Target path (under each skill root) | Status |
|---|---|---|---|
| `output-format.md` | comms-writer, change-management, delivery-engine, pmo-process-designer, pmo-technical-analyst, ppm-agent (6) | `references/output-format.md` | LANDED |
| `operational-artifacts.md` | comms-writer, ppm-agent (2) | `references/operational-artifacts.md` | LANDED |

## §8 Dedup Direction

Active drift surfaced by Foundation Stage 5 audit (row 16): `executive-status-report-prompt-template.md` line 12 differs between canonical and the project-initiator mirror — canonical uses the parameterized form `{{PROJECT_PREFIX}}_RAID_Log.csv`, mirror uses the hardcoded form `RAID Log.csv`.

**Dedup direction: canonical-wins.** Resolution mechanic: `./deploy.sh --deploy project-initiator` invokes `sync_canonical_templates_to_source()` which overwrites the mirror with canonical content. Verification: `diff -q` returns silent (AC3).

**Evidence for canonical-wins** (DD-D): 6 prior project-initiator-generated RAID Log filenames sampled from the live workspace — 5 use the parameterized form (correctly substituted via the project-initiator scaffolding flow); the 6th is a test-stub under `Archive/_Implementation/`, not a real project. Project-initiator SKILL.md line 187 also references the parameterized form at runtime, confirming the canonical content matches the skill's intended runtime substitution. The mirror's hardcoded form is the drift artifact (likely introduced by a manual edit to the mirror that was never reflected back to canonical).

**Future drift detection:** Check 13 catches divergence before deploy. Once a canonical file is registered in `TEMPLATE_SYNC_MAP`, any mirror edit that diverges from canonical surfaces as DRIFT on the next `./deploy.sh --check`.

## §9 References

- [`template-taxonomy.md`](template-taxonomy.md) — L1 of the 5-Layer Template Architecture (artifact-family taxonomy + canon-per-family mapping)
- `template-protocol.md` — L4 of the 5-Layer Template Architecture (lifecycle protocol)
- [`canonical-skill-structure.md`](canonical-skill-structure.md) — Skill structure invariants (mandatory frontmatter, references/ subtree contract, threshold rules)
- [`document-ecosystem-design.md` §6 Three-Layer Architecture](../disciplines/document-ecosystem-design.md) — Schema/Storage/Presentation separation that frames the PDA boundary in §5
- [`decision-discipline.md` §2.1 Mechanism 1](../disciplines/decision-discipline.md) — Localization Check pattern applied to Anthropic compatibility verification
- `anthropic-skills:skill-creator/SKILL.md` lines 78-84 — Per-skill self-contained model + `references/` Bundled-Resources spec (drift-checked 2026-05-10 against `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md`)
- [`.claude/rules/skill-deployment.md`](../rules/skill-deployment.md) — Mandatory tooling for skill edits (this protocol does not require pmo-skill-editor invocation; deploy.sh edits route through normal git-workflow, not the skill-editor gate); also carries the agent rebuild-on-canonical-edit rule for the §7.3 shared standards docs
- Single-source shared references + enforced rebuild — the work that consolidated the six duplicate `output-format.md` copies and two `operational-artifacts.md` copies into the §7.3 canonicals, added the explicit-basename resolver rule, and shipped the Check 13b shared-reference collision detector (warn-mode initial)
-  — Parent initiative (5-Layer Template Architecture)
-  — L3 Storage sub-issue (this protocol's authoring scope)
-  — L3 Storage Stage 5 Solutioning (DD-A function design; DD-C boundary text source; DD-D dedup-direction evidence)
- the release plan (Stage 4 sub-task)
- Operator Decision Record — D2 / D3 / D5 / D-CanonicalPromote / R-NEW1 approvals

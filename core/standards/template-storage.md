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

- **Canonical home for templates:** `pmo-platform/reference/templates/`
- **Canonical home for standards docs:** `pmo-platform/reference/standards/`
- **Diátaxis classification:** Both folders are sub-genres of "Reference" per the Option A footnote (Stage 4 D3 evidence trail; reaffirmed at the D-Gate 2026-05-10).
- **Per-folder README:** `pmo-platform/reference/templates/README.md` enumerates registered templates with cross-links to [`template-taxonomy.md` §6](template-taxonomy.md) (canon-per-family mapping) and §7 of this doc (registered mirrors). The README protocol itself is light currently; the full per-folder-README protocol ships in a later release.

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

### §3.2 Hook implementation

The function `sync_canonical_templates_to_source()` (defined in [`deploy.sh`](../deploy/deploy.sh)) is invoked from `cmd_deploy()` BEFORE the per-skill deploy loop. Algorithm:

1. For each entry matching the current skill filter (or all entries if no filter):
   - Resolve source path: lookup `<canonical-filename>` under `pmo-platform/reference/templates/` (for `*-template.{md,csv}`) or `pmo-platform/reference/standards/` (for `template-*.md`). Source-path subdir is determined by file pattern, not declared per-entry.
   - Resolve target: `pmo-platform/skills/<skill>/<target-path-relative-to-skill-root>`.
   - Create target parent dir if missing.
   - `cp` source → target (overwrite).
   - Verify: post-copy `diff -q` against canonical (byte-identical).
2. Per-file `cp` is atomic (single rename on POSIX). Multi-file batch is NOT transactional — a failure on file N leaves files 1..N−1 in place; caller (`cmd_deploy`) treats as deploy-failure via FAILURES array and surfaces to operator.

### §3.3 Why pre-loop (not in-loop)

`sync_canonical_templates_to_source()` writes to the source tree (`pmo-platform/skills/<skill>/references/...`). Subsequent steps in the per-skill deploy loop (SKILL.md copy + supplementary copy + `.skill` package extraction + user-local mirror) read the source tree and propagate to runtime. Running sync before the loop ensures the per-skill deploy reads a synced source.

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

`./deploy.sh --check` Check 13 asserts every entry in `TEMPLATE_SYNC_MAP` has a source canonical AND a byte-identical mirror at the registered target. Always-enforce posture (matches Check 1 / Check 11 — structural, zero-FP profile). Failure remediation: `./deploy.sh --deploy <skill>` re-syncs.

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
| **Typed-format specification** (what fields/sections/structure an artifact must have) | **Template Architecture L3** (this doc) | `pmo-platform/reference/templates/` (engineering source tree, Layer 1) |
| **Entity instance data** (the actual values populating a template-specified format at runtime) | **PDA L2 Storage** | `projects/[Project]/`, `projects/_pmo/`, `projects/_config/` (operations tree, Layer 2) |

**Concrete example.** A RAID Log template (`pmo-platform/reference/templates/raid-log-template.csv`) declares column headers (RAID Item ID, Type, Description, Owner, Status, etc.) — that is Template Architecture L3 turf. A RAID Item ENTITY for the [PROJECT_KEY] project (a row in `projects/[PROJECT_KEY] Implementation/04-PMO-Operations/[PROJECT_KEY]_RAID_Log.csv` with `RAID-001 | Risk | [COLLEAGUE_I] integration delay | ...`) — that is PDA L2 turf. The template governs the contract; the instance is the data. Template Architecture does not govern WHERE risk instances live in the project folder structure; PDA does not govern WHAT fields a risk has.

**Surface boundary rules:**

1. **Templates declare structure; PDA instances populate structure.** Template Architecture changes the canonical template file; PDA changes never modify `pmo-platform/reference/templates/`. PDA changes the project entity layout; Template Architecture changes never modify `projects/`.
2. **Schema/Storage/Presentation separation** (per [`document-ecosystem-design.md` §6](../disciplines/document-ecosystem-design.md)) holds: Templates feed the Schema layer (typed-format specification); PDA L2 owns the Storage layer (how the agent persists entity data on source files); rendering of a RAID instance in Obsidian / Teams / status report is Presentation Layer (separate concern, not in either L3 or L2 scope).
3. **Frontmatter ownership.** PDA  specifies frontmatter fields for entity instances (`type: person`, `aliases:`, etc.). Templates may include `{{frontmatter}}` placeholders that PDA's frontmatter-schema fills in at instance-creation time — but the schema definition is PDA's, the placeholder is the template's. Template Architecture does NOT modify `pmo-platform/reference/schemas/frontmatter-schema.md`; PDA does NOT modify templates to add frontmatter fields.
4. **Sync direction.** Template Architecture L3's deploy-sync moves canonical templates and standards docs `pmo-platform/reference/{templates,standards}/` → skill `references/` mirrors (engineering-internal flow). PDA L2 entity files (`_pmo/people/jane-doe.md`) are runtime-created by skills (project-initiator, ppm-agent) consuming templates — that flow is project-initiator's runtime concern, not L3's sync concern.
5. **Drift-detection ownership.** Check 13 (this initiative) validates canonical-to-mirror drift in the engineering tree. PDA's analogous health checks (per its L3 Automation layer; `health-check-architecture.md`) validate instance-level drift in the operations tree. The two check suites do not overlap.

**What composition looks like over time.** A new project type (e.g., a hypercare-only sub-project under PDA's  typed-sub-entities) introduces a new template (Template Architecture authors it under `pmo-platform/reference/templates/hypercare-plan-template.md`) AND a new entity-storage convention (PDA  declares `plan_subtype: hypercare` + lifecycle states in frontmatter-schema). The two changes ship in their respective initiatives' release cycles; neither blocks the other once this boundary is in place.

**Where this boundary IS broken (acceptable cases):** Authoring conveniences. A skill consuming PDA frontmatter schemas (e.g., delivery-engine's RAID writers) may include inline frontmatter examples in its SKILL.md — those are not templates in the L3 canonical-registry sense (they are skill-internal authoring guidance per Foundation Stage 5 audit `location_class: skill-internal-standalone`). The boundary applies to canonical templates in `pmo-platform/reference/templates/`, not to every appearance of frontmatter-shaped text across the platform.

**Collective Review consumability test:** An operator reading the boundary above should be able to answer the question "If I am working on PDA  next quarter, do I edit any file under `pmo-platform/reference/templates/`?" with a confident "No." (Test passed at Collective Review 2026-05-10.)

## §6 Sync-Map Registration Protocol

When a new template enters the canonical registry, OR a new skill consumes a canonical template or standards doc:

1. Add the source file to its canonical home (`pmo-platform/reference/templates/<file>` for templates; `pmo-platform/reference/standards/template-<aspect>.md` for standards docs).
2. Add a `TEMPLATE_SYNC_MAP` entry in [`deploy.sh`](../deploy/deploy.sh) — colon-delimited 3-tuple `<skill>:<canonical-filename>:<target-path-relative-to-skill-root>`. (No SKILL.md edit is required for the registration itself; this is a deploy.sh edit, not a skill-internal edit. SKILL.md modifications, when also needed, route through `pmo-skill-editor` per [`.claude/rules/skill-deployment.md`](../rules/skill-deployment.md).)
3. Document the entry in §7 of this doc (Registered Mirrors).
4. Run `./deploy.sh --deploy <skill>` to perform the initial sync.
5. Run `./deploy.sh --check` to confirm Check 13 passes.
6. Commit the canonical file + deploy.sh edit + this doc's §7 update in a single commit per the standard release flow ([`.claude/rules/git-workflow.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/git-workflow.md)).

**Note on `template-protocol.md` (L4 deliverable):** `TEMPLATE_SYNC_MAP` entries that reference `template-protocol.md` are added in the L4 Stage 6 commit (after the canonical file exists at `pmo-platform/reference/standards/template-protocol.md`). Adding those entries before L4 Stage 6 lands would cause Check 13 to ENOENT-fail (canonical missing); the L3 Stage 6 commit deliberately defers them to maintain a green Check 13 across the L3→L4 commit window.

## §7 Registered Mirrors (point-in-time snapshot — see TEMPLATE_SYNC_MAP for authoritative source)

The authoritative list is the `TEMPLATE_SYNC_MAP` array in [`deploy.sh`](../deploy/deploy.sh). The table below mirrors that array as of Stage 6 (2026-05-10) for at-a-glance reference; future drift between this table and the deploy.sh array is detected by `./deploy.sh --check` Check 13's source-side enumeration only — this table is informational, not authoritative.

### §7.1 Template mirrors (13 entries)

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
| project-initiator | `spm-bridge-template.md` | `references/templates/spm-bridge-template.md` |
| project-initiator | `sprint-tracker-template.md` | `references/templates/sprint-tracker-template.md` |
| project-initiator | `transcript-register-template.md` | `references/templates/transcript-register-template.md` |
| project-initiator | `project-md-template.md` (AC6) | `references/project-md-template.md` (top-level; preserves SKILL.md line 167 read path) |
| pmo-process-designer | `requirements-template.md` (AC7) | `references/requirements-template.md` (top-level; preserves SKILL.md lines 156, 513 read paths) |

### §7.2 Standards-doc mirrors (18 entries — 6 consumer skills × 3 standards docs, Option A)

Per R-NEW1 Option A (approved at Collective Review 2026-05-10). 6 consumer skills × 3 standards docs = 18 entries. `template-taxonomy.md` + `template-storage.md` rows landed at L3 Stage 6; `template-protocol.md` row landed at L4 Stage 6  — all rows now LIVE in `TEMPLATE_SYNC_MAP`.

| Standards doc | Consumer skills | Target path (under each skill root) | Status |
|---|---|---|---|
| `template-taxonomy.md` | pmo-skill-refiner, pmo-process-designer, project-initiator, delivery-engine, eval-writer, release-planner | `references/template-taxonomy.md` | LANDED — L3 Stage 6  |
| `template-storage.md` | pmo-skill-refiner, pmo-process-designer, project-initiator, delivery-engine, eval-writer, release-planner | `references/template-storage.md` | LANDED — L3 Stage 6  |
| `template-protocol.md` | pmo-skill-refiner, pmo-process-designer, project-initiator, delivery-engine, eval-writer, release-planner | `references/template-protocol.md` | LANDED — L4 Stage 6  |

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
- [`.claude/rules/skill-deployment.md`](../rules/skill-deployment.md) — Mandatory tooling for skill edits (this protocol does not require pmo-skill-editor invocation; deploy.sh edits route through normal git-workflow, not the skill-editor gate)
-  — Parent initiative (5-Layer Template Architecture)
-  — L3 Storage sub-issue (this protocol's authoring scope)
-  — L3 Storage Stage 5 Solutioning (DD-A function design; DD-C boundary text source; DD-D dedup-direction evidence)
- the release plan (Stage 4 sub-task)
- Operator Decision Record — D2 / D3 / D5 / D-CanonicalPromote / R-NEW1 approvals

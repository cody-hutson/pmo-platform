---
title: core/deploy/tools/
purpose: Inventory and usage reference for the stdlib-only Python primitives invoked by deploy.sh checks and available for ad-hoc operator invocation.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# core/deploy/tools/

Stdlib-only Python primitives invoked by `core/deploy/deploy.sh` checks AND
available for ad-hoc operator invocation. All tools run under
`/usr/bin/python3` (system Python 3.9+; no virtualenv, no external
dependencies). Plus one bash wrapper (`cross-module-audit.sh`) that delegates
to a Python helper.

## Inventory

| Tool | Used by | Mode(s) | Purpose |
|---|---|---|---|
| `check-doc-links.py` | `deploy.sh` Check 14 + operator workflows + audit wrapper | broken-refs, rewrite-map | Doc-link drift detection + per-edit reference rewriting |
| `check-version-anchors.py` | `deploy.sh` Check 18 | structural | Verify version-anchor citations against current state |
| `check-doc-frontmatter.py` | `deploy.sh` Check 50 | structural (warn-mode across `core/`; enforce-flip deferred to the Tier-B/C backfill) | Validate platform-doc frontmatter per the platform-doc frontmatter standard: Tier-1 required fields + `type` singular enum + `framework_version_anchor`-IFF-cataloged + `consumers` for standard/schema/spec + `reversibility` tier-prefix |
| `_frontmatter.py` | `check-version-anchors.py` + `check-doc-frontmatter.py` (shared library) | library (not a check) | The single shared YAML-frontmatter block reader — the F1 consistency seam so Check 18b and Check 50 parse frontmatter byte-identically |
| `generate_release_index.py` | `deploy.sh` Check 23 (`--verify`); `automated-closeout.sh` phases 7/8/9.5 (`--emit`); `release-tooling-smoke.yml` (`--self-test`); `release-executor` Mode E (Stage 13 close — `--verify` only) | `--emit {index,digest,changelog}` (one entry to stdout) / `--verify` / `--self-test` / `--output-stdout` read-only; **bare = destructive full regenerate** | **The release-corpus PROJECTOR** — the single writer of all three DERIVED ledgers (`RELEASE_INDEX.md`, `RELEASE_DIGEST.md`, `CHANGELOG.md`) from their declared sources, per `release-corpus-schema.md` § Derived-Surface Contract. Clock-free and config-free by contract: both date anchors and the repo slug are REQUIRED CLI arguments. Emits **entries, never files** — a whole-file regenerate of the DIGEST or CHANGELOG destroys post-emission editorial content. **Stage 13 is append-only** — a bare invocation rewrites every row and restamps the grandfathered `Date` cells the INDEX header declares must not be rewritten (`release-process.md` § D6 / CR-D6). *Module name understates scope; accepted debt, rename is a legitimate follow-on.* |
| `lint_release_corpus.py` | Operator workflows (release-corpus moved to operator-instance) | structural | Validate release-corpus filename regex + frontmatter schema + type-coherence + note content. Sub-check (c) (INDEX row count) is **RETIRED, identifier reserved** — strictly weaker than Check 23's coexistence limb |
| `cross-module-audit.sh` | Module-restructure audit + operator | audit (read-only) | Cross-module extraction-readiness audit; bash entrypoint |
| `cross_module_audit_helper.py` | Invoked by `cross-module-audit.sh` | audit (read-only) | Imports check-doc-links primitives; classifies cross-module refs by 6 directionality rules + 3 cross-ref-types; emits TSV + markdown report |
| `stamp-node-frontmatter.py` | Operator + Layer-2 Stage-12 backfill | dry-run (default) / stamp | Classify-and-stamp the 11-field node-frontmatter core onto the operational corpus (the vertices of the doc warehouse); folder→domain classification, idempotent, `.meta.yml` sidecars for non-md files |
| `backfill-relationship-edges.py` | Operator + Layer-2 Stage-12 backfill | dry-run (default) / emit (gated) | Backfill `relationships[]` edges (the edges of the doc warehouse) — `BELONGS_TO` always-safe + evidence-anchored `GENERATES`/`DEPENDS_ON`; imports the node tool's classifiers for F1-consistent project derivation |
| `build-doc-index.py` | Operator + the lifecycle-automation incremental caller | rebuild / update-file / query / self-test | Materialize the disposable document-ecosystem SQLite index (`sqlite-index-schema.md`) from node frontmatter + edges — all 7 tables + FTS5 + the 7 named reference queries; deterministic byte-identical rebuild |

## check-doc-links.py — Two Modes

### Mode 1: broken-refs (default)

Scans target files for broken cross-references. Default mode when
`--from-path/--to-path` are NOT supplied.

```bash
# Ad-hoc scan over an explicit scope. `--allowlist` is REPEATABLE and the
# pattern sets UNION — see "Check 14 (deploy.sh) Invocation" below for the
# tracked-base + instance-additions layering the recurring callers use.
python3 core/deploy/tools/check-doc-links.py \
  --target-paths "core/governance/,core/standards/,operations/skills/*/SKILL.md" \
  --allowlist core/deploy/allowlists/skip-doc-link-check-ci.txt \
  --output-format tsv \
  --exclude-code-blocks
```

**Output formats:**
- `tsv` (default): 6 columns — `source_file`, `line`, `target`, `category`,
  `severity`, `remediation_recommendation`
- `json`: array of objects with the same fields
- `github`: GitHub Actions `::warning::` annotations

**Exit codes:**
- `0` — no broken refs found
- `1` — broken refs found (count in TSV body)
- `2` — argparse failure (missing `--target-paths` or `--self-test`)

**Categories:** `broken-cross-ref`, `broken-anchor`, `deleted-target`.

**Severity tiers:**
- **P1** (must-fix): active governance + skill SKILL.md + per-module rules
- **P2** (should-fix): reference docs + per-module disciplines/schemas/specs/standards
- **P3** (informational): archived / audit artifacts (usually allowlisted)

### Mode 2: rewrite-map (EMIT-ONLY)

Scans target files for references whose path starts with `--from-path`,
emits a rewrite map showing the substituted target path under `--to-path`.
Triggered when BOTH `--from-path` AND `--to-path` are supplied. Designed for
per-edit discipline workflows where the operator (or a downstream tool like
`pmo-skill-editor` Mode A) consumes the map and applies the rewrites.

**Tool never mutates any file** — enforced structurally via self-test
Fixture 6 (mtime + content-hash assertion).

```bash
# Generate a rewrite map for a typical path migration
python3 core/deploy/tools/check-doc-links.py \
  --target-paths "core/disciplines/" \
  --from-path "pmo-platform/reference/explanation/" \
  --to-path "core/disciplines/" \
  --output-format markdown > /tmp/rewrite-map.md
```

**Output formats (rewrite-map mode):**
- `tsv` (default): 4 columns — `source_file`, `line`, `old_path`, `new_path`
- `json`: array of objects with the same fields
- `markdown`: GitHub-flavored markdown table for paste into per-edit plans

**Exit codes:**
- `0` — always (regardless of entry count) on successful scan
- `2` — flag asymmetry (one of `--from-path`/`--to-path` provided without the other)
- argparse errors propagate as exit 2 from argparse itself

**Anchor / query preservation:** If a matched ref carries `#anchor` or
`?query`, the suffix mirrors into `new_path` unchanged.

```
old_path: pmo-platform/reference/explanation/foo.md#section-2
new_path: core/disciplines/foo.md#section-2
```

**Operational note (asymmetric-segment-depth caution):** rewrite-map mode
performs prefix-only string substitution. If `--from-path` and `--to-path`
have different segment depths AND the source corpus contains refs with
additional path segments beyond `--from-path`, the substitution preserves
the trailing segments verbatim. Decompose multi-segment restructuring
renames into multiple invocations (one per `from→to` pair). Per failure-mode
FM-2 in adversarial-design-review at Stage 5.

## check-doc-frontmatter.py — Platform-Doc Frontmatter Gate (Check 50)

Validates the YAML frontmatter of authored K1 platform-reference docs under
`core/**` against [`core/standards/platform-doc-frontmatter-standard.md`](../../standards/platform-doc-frontmatter-standard.md).
It is the **presence-and-shape** complement to `check-version-anchors.py`
Check 18b: 18b checks the `framework_version_anchor` **value** and skips
no-frontmatter docs; Check 50 checks frontmatter **presence + required-field
shape** and treats a no-frontmatter doc as the headline finding.

```bash
# deploy.sh Check 50 invocation pattern
python3 core/deploy/tools/check-doc-frontmatter.py \
  --target-paths "core/standards/**/*.md,core/schemas/**/*.md,core/specs/**/*.md,core/disciplines/**/*.md,core/rules/**/*.md,core/governance/**/*.md,core/skills/**/references/*.md" \
  --allowlist core/deploy/allowlists/skip-doc-frontmatter-check.txt \
  --output-format tsv
```

**Six-step per-doc validation** (run for every resolved, non-allowlisted target):

1. **Missing-frontmatter** — first line is not a `---` fence → one finding.
2. **Tier-1 required-field presence** (all classes) — `title` / `purpose` /
   `type` / `status` / `reversibility` each present and non-empty.
3. **`type` ∈ singular enum** — the standard's §5 table (`standard` / `schema` /
   `spec` / `discipline` / `rule` / `protocol` / `how-to` / `template` /
   `reference`); a plural like `standards` flags with a did-you-mean hint.
4. **`framework_version_anchor` present IFF cataloged** — both directions are
   violations (cataloged-but-absent; present-but-not-cataloged). The anchor
   *value* is NOT checked here — that is 18b's job.
5. **`consumers` present for `standard`/`schema`/`spec`** — the blast-radius seam.
6. **`reversibility` tier-PREFIX match** — the value's first token must be one of
   `{CHEAP, MODERATE, EXPENSIVE, IRREVERSIBLE}`; a prose tail is allowed.

**Output (TSV):** header `frontmatter-check <N>`, then columns
`file<TAB>tier<TAB>field<TAB>violation<TAB>severity`. The **`tier` column**
(`A` | `other`) is the routing key `deploy.sh` consumes — `A` for a doc under
one of the six Tier-A governance-class dirs (`core/standards|schemas|specs|
disciplines|rules|governance/`), `other` for the rest of the scanned surface
(`core/skills/**/references/*.md`).

**Exit codes:**
- `0` — no violations
- `1` — violations found (count in the header line)
- `3` — path-resolution failure: a `--target-paths` glob OR `--catalog-path`
  resolved to zero/missing files (unverifiable, not clean — the fail-loud
  contract that 18b and Check 42 also honor).

**Global committed-default enforce posture (frontmatter gate).** The gate
ships **committed-default enforce across the authored-doc surface**: every finding
— Tier A and `other` alike — routes to a hard `FAIL` (the split Tier-A-enforce /
tier-other-warn partition the earlier warn-mode posture shipped has collapsed to one global-enforce
verdict). Activation is the committed default in `deploy.sh` (`c50_mode` is
hardcoded `enforce`) and does **not** depend on an un-committed
`doc-frontmatter.mode` file, so any clone enforces — a fresh non-conformant
`core/` doc `FAIL`s `deploy.sh --check`. The scan surface is the precise
authored-doc subtree globs (the six Tier-A governance-class dirs plus `core/*.md`,
`core/deploy/tools/*.md`, `core/diagrams/*.md`, `core/packs/*.md`,
`core/references/**/*.md`, and `core/skills/**/references/*.md`); `core/ADRs/`
(disjoint ADR schema, owned by a separate ADR-frontmatter effort) and `**/tests/fixtures/**` are excluded by
construction. The global `DEPLOY_CHECK_MODE=off` kill-switch is retained so the
gate stays disable-able in an emergency, not un-disableable.

**F1 consistency (shared with Check 18b).** Check 50 reads each doc's frontmatter
via the shared `_frontmatter.read_frontmatter` and builds the cataloged-doc set
via `check-version-anchors.py`'s own `parse_catalog_table` (imported directly).
So Check 50 and Check 18b cannot disagree about *what a frontmatter block is* or
*which docs are cataloged in `framework-catalog.md`* — they agree by construction.

**Allowlist** (`core/deploy/allowlists/skip-doc-frontmatter-check.txt`):
repo-relative paths, one per line (`#` comments + blanks ignored); a listed file
is skipped entirely. Seeded with the 11 `bypass-mode-readiness` files (1 generated
index + 10 ADR-030 assembly fragments) — generated content the platform-doc
frontmatter standard's §5 carve-out exempts and the Tier-A backfill deliberately
left un-backfilled.

**Self-test:** `python3 core/deploy/tools/check-doc-frontmatter.py --self-test`
runs fixtures (a)–(j): a clean doc, the two falsification fixtures (each Tier-1
field removed; whole frontmatter stripped), the plural-enum case, both IFF
directions plus the satisfied case, missing-consumers, the reversibility
prefix-passes-with-tail proof, tier tagging, and allowlist loading.

## build-doc-index.py — Document-Ecosystem SQLite Index Builder

Materializes the **disposable** document-ecosystem SQLite index defined by
[`core/schemas/sqlite-index-schema.md`](../../schemas/sqlite-index-schema.md).
The database is a **cache** — the files remain the source of truth; deleting the
`.db` and rebuilding produces a byte-identical result. It is the third link in the
doc-warehouse FK chain: `stamp-node-frontmatter.py` (nodes) →
`backfill-relationship-edges.py` (edges) → **`build-doc-index.py`** (reads both +
materializes the queryable index).

```bash
# Full deterministic rebuild from a corpus root.
python3 core/deploy/tools/build-doc-index.py --rebuild \
  --db /path/to/doc-index.db --root ~/Claude/projects

# Incremental single-file update (the lifecycle-automation callee — capability only, no watcher).
python3 core/deploy/tools/build-doc-index.py --update-file <file> \
  --db /path/to/doc-index.db --root ~/Claude/projects

# Run a named reference query (7 supported).
python3 core/deploy/tools/build-doc-index.py --query cross-project-deps \
  --db /path/to/doc-index.db
python3 core/deploy/tools/build-doc-index.py --query blast-radius \
  --db /path/to/doc-index.db --param changed_file=alpha_fdd.md --param max_depth=5
```

**What it builds:** all 7 schema tables — `files`, `relationships`, `files_fts`
(FTS5 external-content), `lifecycle_events`, `navigation_pages` (empty; a future
read-target), `synthesis_scope`. Populated from node frontmatter (the 11-field
NOT-NULL core; a partial stamp yields no `files` row) + `relationships[]` edges +
`source_inputs[]` provenance.

**Domain enum (migrated).** Reads/inserts the human-readable `{source, managed,
generated}` the node tool stamps; `{A, B, C}` are DEPRECATED aliases the schema
CHECK still accepts during the migration window, and the union-enum queries
(rollup / staleness / orphan) collapse both vocabularies.

**Edge resolution.** A `relationships[]` `target` resolves to `files.file_id` by
exact `filename`; a `BELONGS_TO` whose `target` is a **project name** (the shape
`backfill-relationship-edges.py` emits) resolves to that project's governance-root
representative node (`folder='01-governance'`), so a file whose only edge is
`BELONGS_TO` is not a false-positive orphan. A target that resolves to neither is a
**dangling WARN** (row skipped, never fabricated).

**Determinism (byte-identical rebuilds).** Discovered files are sorted by relative
POSIX path before insert, so `file_id` is a pure function of corpus content;
build-time timestamps are never synthesized (a missing `created_date` is stored as
read; `modified_date` is the filesystem mtime — a per-file property identical across
two rebuilds); the staleness queries use query-time `julianday('now')`, which does
not touch stored rows. Verified by SHA-256 over a canonical per-table dump
(`--dump-canonical`).

**Scope (builder / lifecycle-automation boundary).** Ships the incremental-update **capability**
(`update_file`, a tested callable entry point) + full rebuild + the reference
queries. The event source/watcher that auto-invokes `update_file` on a skill-write
is out of this tool's scope — it stays in the lifecycle-automation epic.

**Exit codes:** `0` clean · `1` dangling edges present (count in header) · `2` usage
error · `3` path-unresolvable (`--root`/`--db`).

**Self-test:** `python3 core/deploy/tools/build-doc-index.py --self-test` builds the
committed fixture (`tests/fixtures/doc-index/` — 2 projects, a cross-project
`DEPENDS_ON` edge, 2 Domain-C syntheses) and asserts: all 7 tables + indexes (AC1);
two rebuilds byte-identical (AC2); rebuild < 10s (AC3); portfolio-rollup +
cross-project-deps both non-empty and all 7 queries execute (AC4); `update_file`
round-trip equals a full rebuild of the mutated tree (FMF-2); Query-6's temporal
condition discriminates via a deterministic `os.utime` mtime push (FMF-3).

## Link-Resolution Rule (canonical)

`check-doc-links.py` resolves a markdown link target by one canonical rule
(ADR-085), implemented identically by `release/tools/check-release-links.py`:

1. A link resolves **relative to the source file's directory**.
2. A **leading `/`** denotes the **workspace (repo) root** — the GitHub-faithful
   workspace-rooted form (resolved against `--workspace-root` > `$CLAUDE_WORKSPACE_ROOT`
   > the in-repo default, in that precedence).
3. There is **no bare module-prefix fallback**: a bare `core/…` / `release/…`
   from a non-root file is an ordinary relative path, so it reads **broken**
   (exactly as GitHub renders it).

The earlier V1/V2 workspace-rooted prefix tables (ADR-009 Rule 2), which drove a
bare-prefix workspace-root fallback, were retired here — the fallback masked
links GitHub renders as 404s from non-root files. `core/CLAUDE.md.template`
(which deploys to the repo root) uses the leading-`/` form for its root-anchored
references, so it resolves correctly under the canonical rule both as a template
and as the deployed `CLAUDE.md`.

## Self-Test

```bash
python3 core/deploy/tools/check-doc-links.py --self-test
```

Runs 9 fixtures sequentially. Each fixture uses its own tmpdir scope;
failure on any → exit 1 with explicit assertion message.

| # | Fixture | Verifies |
|---|---|---|
| 1 | code-block exclusion + single broken ref | Original code-block-exclusion behavior |
| 2 | anti-fallback regression guard | a bare module-prefixed link from a non-root file reads BROKEN even when the path exists at the workspace root (ADR-009 Rule-2 fallback retired per ADR-085), while the leading-`/` form of the same target resolves |
| 3 | rewrite-map TSV + JSON + markdown output | All 3 output formats; column counts; header shape |
| 4 | AC-3 five-form parity (doc-links side) | the five link forms return the canonical verdicts: relative-ok / relative-broken / `../`-ok / bare-prefix-broken / `/`-rooted-ok |
| 5 | anchor preservation in rewrite-map | `#section` survives substitution |
| 6 | EMIT-ONLY structural enforcement | mtime + content-hash unchanged after rewrite-map scan (PR-3/FM-1) |
| 7 | `--require-targets` fail-loud | a `--target-paths` glob resolving to zero files is flagged (exit 3); a populated scan-root is not |
| 8 | placeholder / meta-doc-literal exclusion precision | `<…>` tokens, barewords, `...`, and blockquoted worked-example links are skipped while a genuine broken ref still fires |
| 9 | relocatable workspace-root + precedence | a `/`-rooted link re-roots under a sandbox root; CLI > `$CLAUDE_WORKSPACE_ROOT` > default |
| 10 | `--target-paths-file` loader (shared scan-scope SSOT) | one-glob-per-line parsing; blank/comment lines ignored; missing or comment-only file returns `[]` (which `main()` converts to a hard error, never a silent empty scan) |
| 11 | repeatable `--allowlist` UNION (shared tracked base + instance additions) | two allowlist files concatenate in argument order and neither shadows the other; a missing file does not discard the present one; the union actually suppresses (with an unallowlisted control that still fires) |

Expected output: `self-test OK (11 fixtures passed)`.

## Check 14 (deploy.sh) Invocation

`deploy.sh` Check 14 is the primary recurring consumer. Invocation scoped to
the governance + skill SKILL.md surface across all 3 modules:

```bash
python3 core/deploy/tools/check-doc-links.py \
  --target-paths-file core/deploy/allowlists/doc-link-target-paths.txt \
  --allowlist core/deploy/allowlists/skip-doc-link-check-ci.txt \
  --allowlist "$PMO_INSTANCE_PATH/skip-doc-link-check.txt" \
  --output-format tsv \
  --require-targets \
  --exclude-code-blocks
```

Scan scope comes from the shared `--target-paths-file`, the SAME list
`.github/workflows/link-check.yml` passes, so the two callers' scope cannot
drift.

Allowlist layering: `--allowlist` is repeatable and the pattern sets UNION in
argument order. The first is the **tracked corpus-level base** — also the SAME
file `link-check.yml` passes, so the two callers' ignore list cannot drift
either. The second carries operator-instance additions layered on top; when
`$PMO_INSTANCE_PATH/skip-doc-link-check.txt` does not exist, deploy.sh falls
back to `.claude/skip-doc-link-check.txt` (legacy operator-side workspace
location), and an absent instance file simply contributes no patterns.

Warn-mode initial per `core/rules/bypass-mode-readiness.md` shakedown
precedent; flip-to-enforce timeline codified in
`core/standards/doc-link-maintenance-protocol.md`.

## Check 15 (deploy.sh) — RETIRED in v2

Per the Stage 5 spec Surface 4 plus a later operator fix,
the in-repo release-corpus check (`RELEASE_LOG.md`, `releases/plans/`,
`releases/notes/`) is RETIRED in v2 — release-corpus is operator-instance per
the harness plan § 2.4.

The release-time integrity function is upheld by a 3-layer architectural
pattern:

| Layer | Surface | Owner |
|---|---|---|
| 1 (primary, operator-choice) | External release-notes tool — GitHub Releases per dual-write Surface 1 (default) + native validation; OR Azure DevOps; OR JIRA; OR Confluence; OR other | Operator's external system |
| 2 (fallback) | `~/Claude/personal/pmo-instance/tools/check-release-corpus.sh` wrapper invoking `core/deploy/tools/check-doc-links.py` against operator-instance corpus paths | Operator (local) — authoring deferred to P2.5-T1 |
| 3 (release-pipeline gates) | Stage 12 + Stage 13 chip prompts per + Procedure 7 Step 4 completion-verification per fire regardless of Layer 1/2 choice | Hub (release pipeline) |

`deploy.sh` Check 15 block is replaced with a citation comment block.
Check numbering gap (15 retired) preserved for citation continuity of
Checks 16-30 across governance.

## cross-module-audit.sh — Extraction-Readiness Audit

Per the module-restructure Stage 5 spec: scans every file under
`operations/`, `release/`, and `core/` for cross-module references; classifies each per
6 directionality rules + 3 cross-ref-types; emits 7-strategy enum
`recommended_strategy` per finding for cleanup-framework consumption.

```bash
# From repo root (writes to audit-output/ by default; gitignored)
core/deploy/tools/cross-module-audit.sh \
  audit-output/cross-module-audit-$(date -u +%Y-%m-%d).md \
  audit-output/cross-module-audit-$(date -u +%Y-%m-%d).tsv
```

**Architecture (per CD-2 counter-design):** bash entrypoint (`cross-module-audit.sh`)
delegates to Python helper (`cross_module_audit_helper.py`) which imports
`extract_links()` + `resolve_target()` + `strip_code_blocks()` from
`check-doc-links.py` — inheriting FM-1 fenced-code-block stripping + FM-2
anchor-resolution. Primitive stays single-responsibility (link-integrity);
wrapper adds directionality classification + cross-ref-type refinement.

**Exit codes:**
- `0` — no cycle-class violations (clean OR non-cycle violations only)
- `1` — code-import cycle detected (BLOCKS module extraction)
- `2` — non-cycle violations detected (advisory; routes to cleanup queue)
- `3` — script error

**Cross-ref-type refinement (per counter-design CD-3):**
Cat-1/Cat-2 cycle matches are classified as:
- `code-import` — `.sh source X` or `.py from/import X` statements (BLOCKER)
- `markdown-doc-link` — `[text](path)` markdown links (Suspect; carry-forward allowed per ADR-007)
- `narrative-mention` — prose substring (Minor; route to operator)

Documentary references from `core/disciplines + core/schemas` to
`release/governance/release-process.md` + `release/references/pipeline/*` are
classified as `info-adr-007-carry-forward` (accepted cohesion per the ADR-007 carry-forward contract).

**Validation report:** `audit-output/cross-module-audit-<DATE>.md` (relative to repo root)
(markdown summary per Surface 6.2) + `.tsv` (machine-readable per Surface 6.1).
The `audit-output/` directory is gitignored — reports are point-in-time evidence, not committed artifacts.

**Self-test:** `python3 core/deploy/tools/cross_module_audit_helper.py --self-test`
runs 4 fixtures (source/target module classifiers, cross-ref-type classifier,
ADR-007 carry-forward allowance).

**Idempotent:** read-only; re-runs at the same commit emit identical TSV output.

## Related Documentation

- `core/standards/doc-link-maintenance-protocol.md` — full protocol
  (warn-mode posture, flip-to-enforce timeline, Pattern A/B/C definitions)
- `core/rules/doc-link-maintenance.md` — operator-facing recap (mirror)
- `core/rules/bypass-mode-readiness.md` — Shakedown → Enforce Transition Checklist
- Stage 5 spec — canonical authority for tool extension and
  Check 15 retirement
- Adversarial design review at (Stage 5 Phase A6.5) — PR-1, PR-3,
  CD-3 Tier 1 findings implemented in batch 1

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
| `check-doc-frontmatter.py` | `deploy.sh` Check 50 | structural (warn-mode across `core/`; enforce-flip deferred to #2221) | Validate platform-doc frontmatter per the #295 standard: Tier-1 required fields + `type` singular enum + `framework_version_anchor`-IFF-cataloged + `consumers` for standard/schema/spec + `reversibility` tier-prefix |
| `_frontmatter.py` | `check-version-anchors.py` + `check-doc-frontmatter.py` (shared library) | library (not a check) | The single shared YAML-frontmatter block reader — the F1 consistency seam so Check 18b and Check 50 parse frontmatter byte-identically |
| `generate_release_index.py` | `release-executor` Mode E (Stage 13 close) | generative | Generate `RELEASE_INDEX.md` from `RELEASE_LOG.md` |
| `lint_release_corpus.py` | Operator workflows (release-corpus moved to operator-instance) | structural | Validate release-corpus filename regex + frontmatter schema + INDEX row count + type-coherence |
| `cross-module-audit.sh` | Module-restructure audit + operator | audit (read-only) | Cross-module extraction-readiness audit; bash entrypoint |
| `cross_module_audit_helper.py` | Invoked by `cross-module-audit.sh` | audit (read-only) | Imports check-doc-links primitives; classifies cross-module refs by 6 directionality rules + 3 cross-ref-types; emits TSV + markdown report |

## check-doc-links.py — Two Modes

### Mode 1: broken-refs (default)

Scans target files for broken cross-references. Default mode when
`--from-path/--to-path` are NOT supplied.

```bash
# deploy.sh Check 14 invocation pattern (governance + skill SKILL.md scope)
python3 core/deploy/tools/check-doc-links.py \
  --target-paths "core/governance/,core/standards/,operations/skills/*/SKILL.md" \
  --allowlist core/config/allowlists/skip-doc-link-check.txt \
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
`core/**` against [`core/standards/platform-doc-frontmatter-standard.md`](../../standards/platform-doc-frontmatter-standard.md)
(#295). It is the **presence-and-shape** complement to `check-version-anchors.py`
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
  resolved to zero/missing files (unverifiable, not clean — the #459 fail-loud
  contract that 18b and Check 42 also honor).

**Split-mode + warn-mode posture (v3.25 / #2220).** Per the D-4 scope-lock the
gate **ships warn-mode across all of `core/`, Tier A included** — every finding
routes through the warn dispatcher; the gate reports non-compliance but does not
fail the build red, so an incomplete Tier-A backfill on the branch cannot break
CI. The **enforce-flip mechanism** is built: `deploy.sh` resolves a per-check
mode via `resolve_check_mode "doc-frontmatter"` (a dedicated, un-committed
`doc-frontmatter.mode` file). When that flips to `enforce`, the Tier-A leg
graduates to a hard `FAIL` (the dormant enforce branch) while the rest of `core/`
keeps warning; the global flip (route `tier == other` to `FAIL` as well) is the
final graduation. **Both flips are deferred to #2221.**

**F1 consistency (shared with Check 18b).** Check 50 reads each doc's frontmatter
via the shared `_frontmatter.read_frontmatter` and builds the cataloged-doc set
via `check-version-anchors.py`'s own `parse_catalog_table` (imported directly).
So Check 50 and Check 18b cannot disagree about *what a frontmatter block is* or
*which docs are cataloged in `framework-catalog.md`* — they agree by construction.

**Allowlist** (`core/deploy/allowlists/skip-doc-frontmatter-check.txt`):
repo-relative paths, one per line (`#` comments + blanks ignored); a listed file
is skipped entirely. Seeded with the 11 `bypass-mode-readiness` files (1 generated
index + 10 ADR-030 assembly fragments) — generated content the #295 standard's §5
carve-out exempts and the #109 Tier-A backfill deliberately left un-backfilled.

**Self-test:** `python3 core/deploy/tools/check-doc-frontmatter.py --self-test`
runs fixtures (a)–(j): a clean doc, the two falsification fixtures (each Tier-1
field removed; whole frontmatter stripped), the plural-enum case, both IFF
directions plus the satisfied case, missing-consumers, the reversibility
prefix-passes-with-tail proof, tier tagging, and allowlist loading.

## Module-Aware Prefix Table

`check-doc-links.py` recognizes two prefix namespaces as workspace-rooted
(triggers workspace-root fallback that matches GitHub web rendering):

| Prefix family | Entries | Origin |
|---|---|---|
| `V1_PREFIXES` | `pmo-platform/`, `.claude/`, `projects/`, `memory/` | Legacy pmo-platform (source) repo — preserved for backward-compat during the migration window per Don't-break discipline (plan § 4.6) |
| `V2_PREFIXES` | `core/`, `release/`, `operations/`, `docs/` | pmo-platform-v2 modular monolith — bare module names because WORKSPACE_ROOT == v2 repo root in deployed layout |

The two tuples are intentionally separated for repo-boundary audit
traceability per adversarial-review PR-1 at Stage 5.

**Future cleanup path:** Once the legacy prefix family retires, remove `V1_PREFIXES`
from the table. The dual structure forward-compats this — single-tuple edit.

## Self-Test

```bash
python3 core/deploy/tools/check-doc-links.py --self-test
```

Runs 6 fixtures sequentially. Each fixture uses its own tmpdir scope;
failure on any → exit 1 with explicit assertion message.

| # | Fixture | Verifies |
|---|---|---|
| 1 | code-block exclusion + single broken ref | Original code-block-exclusion behavior |
| 2 | module-prefix-resolution | V2_PREFIXES entries trigger workspace-root fallback |
| 3 | rewrite-map TSV + JSON + markdown output | All 3 output formats; column counts; header shape |
| 4 | dual-prefix backward-compat | V1_PREFIXES + V2_PREFIXES both resolve identically |
| 5 | anchor preservation in rewrite-map | `#section` survives substitution |
| 6 | EMIT-ONLY structural enforcement | mtime + content-hash unchanged after rewrite-map scan (PR-3/FM-1) |

Expected output: `self-test OK (6 fixtures passed)`.

## Check 14 (deploy.sh) Invocation

`deploy.sh` Check 14 is the primary recurring consumer. Invocation scoped to
the governance + skill SKILL.md surface across all 3 modules:

```bash
python3 core/deploy/tools/check-doc-links.py \
  --target-paths "core/governance/,core/disciplines/,core/schemas/,core/standards/,core/specs/,core/rules/,core/CLAUDE.md.template,release/governance/,release/references/,release/schemas/,release/specs/,release/standards/,release/rules/,operations/OPERATIONS.md,operations/references/,operations/schemas/,operations/skills/*/SKILL.md,release/skills/*/SKILL.md,core/skills/*/SKILL.md" \
  --allowlist "$PMO_INSTANCE_PATH/skip-doc-link-check.txt" \
  --output-format tsv \
  --exclude-code-blocks
```

Allowlist fallback: when `$PMO_INSTANCE_PATH/skip-doc-link-check.txt` does
not exist, deploy.sh falls back to `.claude/skip-doc-link-check.txt` (legacy
operator-side workspace location).

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

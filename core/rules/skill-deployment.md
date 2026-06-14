<!-- reference-durability: allow-link -->
# Skill Deployment — pmo-platform

## Paths
- Git source: `{core,operations,release}/skills/[skill-name]/SKILL.md` (in repo)
- Cowork install location: `[COWORK_INSTALL_PATH_BASE]/local-agent-mode-sessions/skills-plugin/[SESSION_UUID]/[SESSION_UUID]/skills/[skill-name]/SKILL.md`
- Claude Code user-local mirror: `~/.claude/skills/[skill-name]/` — exposes every PMO skill as a plain `/<skill-name>` slash command. Full skill tree (SKILL.md + references/ + evals/ + any supplementary content) is mirrored on every deploy.
- Previous session (orphaned): `[SESSION_UUID]/[SESSION_UUID]`
- **Session instability note:** Cowork can regenerate session UUIDs (e.g., after plugin reinstall, app update, or account re-auth). When skills disappear, check for a new session path under `skills-plugin/` and redeploy.

## Selected Deployment Mechanism
- Mechanism: S-2 (direct file copy) — applied to BOTH targets (Cowork install path + user-local mirror).
- Test results: S-2 write SUCCESS, S-3 symlink SUCCESS, S-4 script SUCCESS, S-rules SUCCESS, S-doc SUCCESS. All automated mechanisms passed.
- Decision rationale: S-2 is the simplest automated mechanism — direct cp from repo to installed path. No symlink complexity. Fully automatable in Stage 10 of the deployment pipeline.
- User-local mirror: copy chosen over symlink to preserve the structured deploy/verify/check process — edits to `{core,operations,release}/skills/` require explicit `./deploy.sh --deploy` to refresh the user-local copies, matching the Cowork-target governance flow.

## Template-mirror policy

Canonical templates and standards docs live ONCE in the repo:

- `core/standards/template-protocol.md`
- `core/standards/template-storage.md`
- `core/standards/template-taxonomy.md`
- `operations/templates/*.md` and `operations/templates/*.csv`

Per-skill consumers (e.g., `operations/skills/delivery-engine/references/template-protocol.md`) are NOT carried in the source tree. They are runtime artifacts injected by `sync_canonical_templates_to_runtime()` in `deploy.sh` at deploy time, and by `core/deploy/tools/build-skill-packages.sh` at package build time. The mapping (which canonicals inject into which skill) lives in `deploy.sh`'s `TEMPLATE_SYNC_MAP`.

**Editing a per-skill mirror has no effect** — it does not exist as a source-of-truth. To change a template, edit the canonical at the source-of-truth path; downstream consumers (deploy + package build) regenerate runtime copies from canonical.

**Rebuilding .skill packages after editing canonicals:**

```bash
bash core/deploy/tools/build-skill-packages.sh                 # all 21 packages
bash core/deploy/tools/build-skill-packages.sh delivery-engine # subset
```

The build script extracts `TEMPLATE_SYNC_MAP` from `deploy.sh` at runtime, stages each skill in a temp directory, injects canonicals per the map, then invokes the per-skill packager (`release/skills/pmo-skill-refiner/scripts/package_skill.py`) to emit the archive at `packages/`.

**Check 13 (template-injection drift detection):**

Verifies the RUNTIME mirrors (Cowork install + user-local) match canonical. If a runtime mirror is missing or differs from canonical, Check 13 reports DRIFT with `./deploy.sh --deploy <skill>` remediation. If the skill is not yet deployed at a given runtime path, Check 13 silently skips that target's verification (Check 12 separately verifies skill presence). Check 13 is always-enforce — a divergent registered mirror makes `./deploy.sh --check` exit non-zero.

**Check 13b (shared-reference collision detection):**

Closes the "unregistered shared reference" failure mode at its root: Check 13 only sees REGISTERED files, so an unregistered reference basename carried by two or more skills (the original `output-format.md` six-copy gap) is invisible to it. Check 13b enumerates every reference basename under `{core,operations,release}/skills/*/references/` and, for any basename carried by 2+ skills that does NOT resolve to a registered `TEMPLATE_SYNC_MAP` canonical, flags both byte-IDENTICAL duplicates (single-source them and register) and DIVERGENT same-basename files (reconcile, or document as intentionally per-skill). Registered basenames are exempt — their byte-identity-vs-canonical is Check 13's job. Check 13b ships warn-mode initial via the runtime `.claude/hooks/deploy-check.mode` machinery; flip-to-enforce follows the `bypass-mode-readiness.md` Shakedown → Enforce Transition Checklist (codified in `core/standards/template-storage.md` §3.5).

## Agent rebuild-on-canonical-edit

Editing a canonical that is single-sourced into skill `references/` mirrors makes every dependent skill's runtime mirror and `.skill` package stale. The trigger is a path-class, not a fixed file list: **any canonical resolvable by `resolve_template_sync_source()`** — concretely `core/standards/output-format.md`, `core/standards/operational-artifacts.md`, the `template-*.md` standards docs (`template-taxonomy.md`, `template-storage.md`, `template-protocol.md`), and the `operations/templates/*` template files. After editing any such canonical, you MUST re-sync the dependents in the same change:

1. Re-deploy the dependent skills — `./deploy.sh --deploy <skill> …` re-injects the canonical into each runtime mirror (Cowork install + user-local).
2. Rebuild the dependent skills' `.skill` packages — `bash core/deploy/tools/build-skill-packages.sh <skill> …` re-injects the canonical from `TEMPLATE_SYNC_MAP` at build time (package-freshness is enforced by Check 7).
3. Run `./deploy.sh --check` to confirm Check 13 (registered-mirror drift) and Check 13b (collision) are green.

To find a canonical's dependent skills, read its `TEMPLATE_SYNC_MAP` entries in `deploy.sh` (each entry's `<skill>` field). This extends the same discipline as the "Rebuilding .skill packages after editing canonicals" block above to the registered shared standards docs — editing the canonical, not a per-skill mirror, is the only source-of-truth edit; mirrors are runtime-injected and regenerate from canonical.

## Tracked Skills

Current roster: see `deploy.sh`'s per-module arrays
(`OPERATIONS_SKILLS` / `RELEASE_SKILLS` / `CORE_SKILLS`) plus the source-only
`CANARY_SKILLS` (`pmo-skill-refiner-selftest-canary`, per ADR-04). These four
arrays — not a hardcoded name list — are the single source of truth for the
roster; `deploy.sh --check` Check 5 asserts they match the directory listings at
`{core,operations,release}/skills/` (skill-roster-drift sub-assertion).

**Count convention (derive from the arrays; do not hardcode a number here —
Check 5(c) forbids it).** Three coherent totals, each derived from a different
array view:

- **Deployed roster** = `OPERATIONS_SKILLS` (12) + `RELEASE_SKILLS` (6) +
  `CORE_SKILLS` (3) = the deployed-skill set. Every member has a `.skill`
  package in `packages/` (package-freshness enforced by Check 7), so the package
  count equals the deployed-roster size.
- **Directory listing** = deployed roster + `CANARY_SKILLS` (1). The canary adds
  one source-only directory under `release/skills/` with no package (ADR-04), so
  the directory total is one more than the deployed/package total. Check 5
  reconciles this set against the on-disk directories.
- **`SUPPLEMENTARY_SKILLS`** (`pmo-skill-refiner`, `prompt-builder`) is a *subset
  annotation* of the module arrays — it flags which already-rostered skills carry
  supplementary content beyond `SKILL.md` (full-tree copy on deploy). It is **not
  an independent registry and is never added to the totals.** (Historically this
  was the source of a "deployed-vs-custom" off-by-one: `prompt-builder` appears in
  `CORE_SKILLS` *and* `SUPPLEMENTARY_SKILLS`, and double-counting the
  supplementary listing produced a stale lower "custom" figure. The arrays are the
  only count.)

## Version Field

Every SKILL.md frontmatter carries a `version:` field per `core/standards/version-field-semantics.md`. The contract: release-tag-at-last-material-edit, format `vMAJOR.MINOR` (or `-canary` sentinel for the canary), enforced by dual-gate per the D-Version protocol (PreToolUse hook + `deploy.sh --check`). See the standards doc for bump rules, backfill policy, and consumer references.

## Excluded Skills (Cowork-provided, proprietary)
docx, pdf, pptx, xlsx, schedule — managed by Anthropic, not version-controlled.

## Deployment Steps (Post-Merge)
1. Deploy changed skills and packages: `./deploy.sh --deploy`
   - Auto-detects changed skills via tag-based git diff
   - Copies SKILL.md files to Cowork install path (S-2 mechanism)
   - Mirrors `references/` for non-supplementary skills via `cp -R` from source tree (matches supplementary-skill semantics; the `.skill` package is a distribution-only artifact and is not the install-time source of references/)
   - Mirrors full skill tree to `~/.claude/skills/<name>/` for plain `/<skill>` invocation in Claude Code
   - Verifies each copy via diff
   - To deploy specific skills: `./deploy.sh --deploy daily-status comms-writer`
2. Verify deployment: open Cowork, invoke the changed skill, confirm expected behavior. In Claude Code, type `/` and confirm the skill appears as a plain entry (e.g., `/daily-status`).
3. **Rebuild .skill package — MANDATORY for every modified skill** via `python3 -m scripts.package_skill <skill-dir> packages/` from `release/skills/pmo-skill-refiner/`. Every skill in `{core,operations,release}/skills/` has a corresponding `.skill` package in `packages/` — no exceptions. Source-vs-package staleness is a release-blocking compliance gap, structurally enforced by `deploy.sh --check` Check 7 (package-freshness).

## Auto-detect window semantics
`./deploy.sh --deploy` (no args) uses `detect_changed_skills()` to determine
which skills changed since the last deployment reference. Mechanism:

1. Compute `tag = git describe --tags --abbrev=0` (most-recent tag reachable from HEAD).
2. If `tag` points **exactly at HEAD** (standard Stage 12 Chip Pattern — tag pushed before deploy), use the **second-most-recent tag** (`git describe --tags --abbrev=0 HEAD^`) as the diff base. This catches all changes since the prior release, which is the operationally correct window when tagging precedes deployment.
3. Otherwise, use `tag` as the diff base.
4. If no tag exists, fall back to `HEAD~1`.

The diff is filtered by directory (`-- {core,operations,release}/skills/` for
skills, `packages/` for packages, `harness/` for harness
artifacts) — any file change under these trees, including `references/*.md`,
surfaces the parent skill/package/harness in `CHANGED_*` output. 

## Initial bootstrap

A fresh clone bootstraps the **full skill roster automatically**. `install.sh`
Phase 2 — and any bare `./deploy.sh --deploy` (no args) — detects an empty
user-local skills mirror (`$HOME/.claude/skills` carrying no PMO-roster skill;
Cowork-provided skills such as `docx` do not count) and deploys every skill in
the per-module `OPERATIONS_SKILLS` / `RELEASE_SKILLS` / `CORE_SKILLS` arrays
plus all built `.skill` packages. The roster is read from those arrays, never a
hardcoded name list, so it cannot drift from the deployed set
(`pmo-skill-refiner-selftest-canary` is excluded — source-only per ADR-04, no
package). The documented `git clone && ./install.sh` path therefore populates
the mirror unattended, with no flag to remember.

To force a full-roster deploy explicitly — CI, or redeploy-everything after a
manual wipe — run `./deploy.sh --all`. It deploys the same array-derived roster
and all packages regardless of current mirror state.

Manual explicit-name deploys install each named skill's package too. Running
`./deploy.sh --deploy <skill> …` now installs each named skill's same-named
`.skill` package alongside its source dir, so `./deploy.sh --check` Check 2
reports OK for those packages (it no longer leaves them uninstalled). A
source-only skill with no package — the canary — is skipped; only skills that
have a package get one. The explicit equivalent of the auto-bootstrap is the
full roster by name:
```bash
./deploy.sh --deploy artifact-generator build-reviewer change-management comms-writer \
  daily-status delivery-engine eval-writer file-router implementation-planner \
  pmo-process-designer pmo-qa-auditor pmo-skill-editor pmo-skill-refiner \
  pmo-technical-analyst ppm-agent project-initiator prompt-builder \
  release-executor release-planner tracker-manager weekly-status-rollup
```

After bootstrap, a bare `./deploy.sh --deploy` reverts to incremental
tag-diff deployment (the populated mirror is no longer "empty"), keeping the
mirror fresh as skills change. `./deploy.sh --check` Check 12 reports drift on
any mirror that goes stale.

## Mandatory Tooling for Skill Edits

**This section is NON-OPTIONAL.** No "if applicable" escape hatches.

### Existing skills (chained PMO skills)

Modifications to any `{core,operations,release}/skills/<skill>/SKILL.md` (or its `reference/*.md` files) MUST flow through `pmo-skill-editor` (Mode A for edits; Modes B/C/D for audits). Direct Write/Edit to a SKILL.md is blocked at edit-time by `.claude/hooks/block-skill-direct-edit.sh` (BLOCK-SKILL-EDIT-001..002) for any migrated skill (frontmatter `skill_discipline_migrated_v10_2: true`). Deploy-time enforcement via `./deploy.sh --check` Check 10 (editor audit-trail trailer assertion on last non-merge commit). See [canonical-skill-structure.md §2 Scope of Enforcement](../standards/canonical-skill-structure.md) for the full enforcement matrix.

### NEW skills

NEW PMO skills MAY be authored via `anthropic-skills:skill-creator` (Anthropic built-in), `pmo-skill-refiner` Mode 2 (Create New — wraps the Anthropic scaffolder + applies 7-field injection + pre-handoff gate), or direct authoring. **PMO tooling does NOT gate the NEW-skill authoring path.** Direct authoring does NOT automatically satisfy Principal Standard or failure-mode-standard.md requirements — those are checked at PR review + pmo-qa-auditor invocation, not at deploy-time. The intentional non-enforcement boundary is documented in [canonical-skill-structure.md §2](../standards/canonical-skill-structure.md).

### Dual-gate enforcement infrastructure

- **Gate 1 (spec-compliance, deploy-time):** `./deploy.sh --check` Checks 6-10 validate canonical structure, package freshness, canonical-session-path freshness, mirror-sync, editor audit-trail.
- **Gate 2 (editor-invocation, edit-time):** `.claude/hooks/block-skill-direct-edit.sh` PreToolUse hook on Write/Edit matchers. Pattern matches `bypass-mode-readiness.md` hooks exactly.
- **Exemption surface:** `.claude/skill-editor-exemption-list.txt` (canary initially). Operator additions follow "No ungoverned changes" protocol.
- **Shakedown posture:** Initial deploy uses warn-mode for Checks 8-10 and the edit-time hook (per `.claude/hooks/.mode` and `.claude/hooks/deploy-check.mode`). After ≥3 days of warn-log review + false-positive allowlist additions, flip to `enforce` per [bypass-mode-readiness.md Shakedown → Enforce Transition Checklist](bypass-mode-readiness.md).

### Version field

The `version:` field in every SKILL.md frontmatter follows [version-field-semantics.md](../standards/version-field-semantics.md) — release-tag-at-last-material-edit. Dual-gate: the Gate 2 hook routes edits through `pmo-skill-editor`, which is responsible for bumping the field per the semantics doc; `deploy.sh --check` Check 6 asserts presence + format.

## Drift Check
At session start, optionally run: `./deploy.sh --check --warn`
This validates skill sync (Check 1), package sync (Check 2), duplicate detection (Check 3),
governance presence (Check 4), skill-roster drift (Check 5), canonical-structure compliance
(Check 6), package freshness (Check 7), canonical-session-path freshness (Check 8),
rules-mirror sync (Check 9), editor audit-trail on migrated skills (Check 10),
harness sync (Check 11), user-local skills mirror sync (Check 12), template-sync
drift detection (Check 13) + shared-reference collision detection (Check 13b,
warn-mode initial), doc-link maintenance — governance + skill SKILL.md
scope (Check 14; the earlier release-corpus Check 15 was retired in v2),
note-content lint — release-notes-standard.md §3.2 over the release notes
(Check 20), framework-corpus version-anchor
drift detection — catalog-registry scope (Check 18), RELEASE_LOG ↔ RELEASE_INDEX consistency (Check 23), universal-vs-localized-context authoring guardrail — DC1-DC4 signature scan over Layer-1 corpus (Check 25), doc-impact resolution at Stage 13 close — per-issue Documentation Impact declaration verified against release-branch commit range (Check 28), return-value-conformance for hub-spawned spokes — `.claude/agents/pmo-*.md` cross-reference scan (Check 29), slash-command quoting lint — pmo-authored slash commands under `harness/*/commands/*.md` scanned for unquoted `$ARGUMENTS` in Bash-execution context (Check 30), and platform-config surface integrity — `core/config/platform-config.toml.template` parses + every field ships a default + operator.toml `[adapters]` table present + the legacy `[platform].work_board` alias preserved (Check 33).
Use `--check` (without `--warn`) to exit non-zero on any drift. Checks 6-7, 11-13 always-enforce;
Checks 8-10, 13b, 14, 18, 20, 23, 25, 28, 29, 30, and 33 default to warn-mode per `.claude/hooks/deploy-check.mode` during their
respective shakedown windows (Check 13b is the shared-reference collision sub-assertion — its parent Check 13 stays always-enforce). For structured output (Stage 13 evidence): `./deploy.sh --report`

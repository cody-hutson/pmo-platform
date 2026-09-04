---
title: Skill Deployment — pmo-platform
purpose: The deployment rule mapping a skill's git source to its Cowork install and Claude Code user-local mirror locations, and the deploy-sync mechanism that keeps them current.
type: rule
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
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

Canonical templates, standards docs, and schemas live ONCE in the repo, across
**three** canonical source trees. Which tree a given canonical homes to is not
maintained here — it is decided by the arms of `resolve_template_sync_source()`
in `core/deploy/lib-template-sync-source.sh`, the single definition both
consumers (`deploy.sh` and `core/deploy/tools/build-skill-packages.sh`) source.
Read that resolver for the live set; the trees are:

- `core/standards/` — the `template-*.md` standards docs
  (`template-protocol.md`, `template-storage.md`, `template-taxonomy.md`) plus
  the explicitly-registered shared standards docs (`output-format.md`,
  `operational-artifacts.md`, `regression-checks.md`). Injected to a
  `references/<file>` path in each consumer.
- `operations/templates/` — the artifact templates. This tree is the resolver's
  **bare default arm** (`*)`), not a pattern match: a canonical basename that
  no explicit arm claims and that does not match `template-*.md` resolves here
  **whatever its extension**. The tree is therefore NOT confined to
  `*-template.md` / `*-template.csv` — `people-roster-template.yaml` is a
  registered canonical of this tree and matches neither. Injection target is
  **per-entry**, declared by the map entry's third field rather than implied by
  the tree: entries here use BOTH the `references/templates/<file>` shape and
  the flat `references/<file>` shape, and the majority use the former. Read the
  map for a given entry's target; do not infer it from this bullet.
- `core/schemas/` — the canonical schemas. Registered today:
  `core/schemas/tracker-schemas.md`, consumed by `tracker-manager`. This tree
  differs from the two above in its target form: the map entry targets the
  canonical's **repo-relative path** — not a path under `references/` in
  either of the two shapes the trees above use — so the consuming
  SKILL.md's existing citations of `core/schemas/tracker-schemas.md` resolve
  verbatim from the package root with no SKILL.md edit. It is registered as the
  canonical half of a COMPLEMENTARY pair in
  `core/deploy/allowlists/complementary-reference-pairs.txt` — the skill-local
  half is a complement, not a copy — so the byte-identity Check 13 asserts is
  between the canonical and its own injected copy only.

Per-skill consumers (e.g., `operations/skills/delivery-engine/references/template-protocol.md`) are NOT carried in the source tree. They are runtime artifacts injected by `sync_canonical_templates_to_runtime()` in `deploy.sh` at deploy time, and by `core/deploy/tools/build-skill-packages.sh` at package build time. The mapping (which canonicals inject into which skill) lives in `deploy.sh`'s `TEMPLATE_SYNC_MAP`.

**Editing a per-skill mirror has no effect** — it does not exist as a source-of-truth. To change a template, edit the canonical at the source-of-truth path; downstream consumers (deploy + package build) regenerate runtime copies from canonical.

**Rebuilding .skill packages after editing canonicals:**

```bash
bash core/deploy/tools/build-skill-packages.sh                 # all packages
bash core/deploy/tools/build-skill-packages.sh delivery-engine # subset
```

The no-arg form builds the whole package set. **Its size is deliberately not
recorded here.** Per the § Tracked Skills count convention below, the package
count equals the deployed-roster size and is derived from the `deploy.sh` module
arrays (`OPERATIONS_SKILLS` + `RELEASE_SKILLS` + `CORE_SKILLS`) — a literal in
this line would go stale on the next skill added, which is exactly how the
figure this sentence replaced came to be wrong.

The build script extracts `TEMPLATE_SYNC_MAP` from `deploy.sh` at runtime, stages each skill in a temp directory, injects canonicals per the map, then invokes the per-skill packager (`release/skills/pmo-skill-refiner/scripts/package_skill.py`) to emit the archive at `packages/`.

**Check 13 (template-injection drift detection):**

Verifies the RUNTIME mirrors (Cowork install + user-local) match canonical. If a runtime mirror is missing or differs from canonical, Check 13 reports DRIFT with `./deploy.sh --deploy <skill>` remediation. If the skill is not yet deployed at a given runtime path, Check 13 silently skips that target's verification (Check 12 separately verifies skill presence). Check 13 is always-enforce — a divergent registered mirror makes `./deploy.sh --check` exit non-zero.

**Check 13b (shared-reference collision detection):**

Closes the "unregistered shared reference" failure mode at its root: Check 13 only sees REGISTERED files, so an unregistered reference basename carried by two or more skills (the original `output-format.md` six-copy gap) is invisible to it. Check 13b enumerates every reference basename under `{core,operations,release}/skills/*/references/` and, for any basename carried by 2+ skills that does NOT resolve to a registered `TEMPLATE_SYNC_MAP` canonical, flags both byte-IDENTICAL duplicates (single-source them and register) and DIVERGENT same-basename files (reconcile, or document as intentionally per-skill). Registered basenames are exempt — their byte-identity-vs-canonical is Check 13's job. Check 13b ships warn-mode initial via the runtime `.claude/hooks/deploy-check.mode` machinery; flip-to-enforce follows the `bypass-mode-readiness.md` Shakedown → Enforce Transition Checklist (codified in `core/standards/template-storage.md` §3.5).

## Agent rebuild-on-canonical-edit

Editing a canonical that is single-sourced into skill `references/` mirrors makes every dependent skill's runtime mirror and `.skill` package stale. The trigger is a path-class, not a fixed file list: **any canonical resolvable by `resolve_template_sync_source()`** (`core/deploy/lib-template-sync-source.sh`) — which spans all three canonical source trees named under § Template-mirror policy: `core/standards/` (the `template-*.md` standards docs — `template-taxonomy.md`, `template-storage.md`, `template-protocol.md` — plus the registered shared docs `output-format.md`, `operational-artifacts.md`, `regression-checks.md`), `operations/templates/` (the resolver's bare default arm — every canonical basename the explicit arms and `template-*.md` do not claim, whatever its extension, `people-roster-template.yaml` included), and `core/schemas/` (`tracker-schemas.md`). Read the resolver's arms for the live set rather than treating this sentence as the roster. After editing any such canonical, you MUST re-sync the dependents in the same change:

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
array view. The array contents are the only source of truth — read them in
`deploy.sh`; no literal count is maintained here:

- **Deployed roster** = `OPERATIONS_SKILLS` + `RELEASE_SKILLS` + `CORE_SKILLS` =
  the deployed-skill set (the concatenation of the three module arrays). Every
  member has a `.skill` package in `packages/` (package-freshness enforced by
  Check 7), so the package count equals the deployed-roster size.
- **Directory listing** = deployed roster + `CANARY_SKILLS`. The canary adds
  source-only directories under `release/skills/` with no package (ADR-04), so
  the directory total exceeds the deployed/package total by the canary count.
  Check 5 reconciles this set against the on-disk directories.
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

**Step 1 runs automatically on the primary checkout.** A `post-merge` git hook
redeploys the skills a merge brought in, so a merge to `main` no longer depends on
the operator remembering to deploy. The hook is described under *Automatic
post-merge deploy* below; the numbered steps here remain the authoritative
description of what a deploy does, the path to use on any machine where the hook
is not installed, and — for steps 2 and 3 — work the hook does not do at all.

1. Deploy changed skills and packages: `./deploy.sh --deploy`
   - Auto-detects changed skills via tag-based git diff
   - Copies SKILL.md files to Cowork install path (S-2 mechanism)
   - Mirrors `references/` for non-supplementary skills via `cp -R` from source tree (matches supplementary-skill semantics; the `.skill` package is a distribution-only artifact and is not the install-time source of references/)
   - Mirrors full skill tree to `~/.claude/skills/<name>/` for plain `/<skill>` invocation in Claude Code
   - Verifies each copy via diff
   - To deploy specific skills: `./deploy.sh --deploy daily-status comms-writer`
2. Verify deployment: open Cowork, invoke the changed skill, confirm expected behavior. In Claude Code, type `/` and confirm the skill appears as a plain entry (e.g., `/daily-status`).
3. **Rebuild .skill package — MANDATORY for every modified skill** via `python3 -m scripts.package_skill <skill-dir> packages/` from `release/skills/pmo-skill-refiner/`. Every skill in `{core,operations,release}/skills/` has a corresponding `.skill` package in `packages/` — no exceptions. Source-vs-package staleness is a release-blocking compliance gap, structurally enforced by `deploy.sh --check` Check 7 (package-freshness). Check 7 asserts freshness **by content, not by mtime** (per the gate-efficacy standard): each build emits a committed content-baseline sidecar `packages/<skill>.skill.sha256` (the rebuild-stable content-manifest hash), and Check 7 stages a rebuild of source and compares its content hash against that baseline — so a stale package fails even on a fresh checkout where every file mtime is equal, while a mere `touch` of a current package does not. Use `bash core/deploy/tools/build-skill-packages.sh <skill>` (which injects `TEMPLATE_SYNC_MAP` canonicals and writes the sidecar) rather than calling the packager directly when a skill consumes injected templates, so the committed package and its sidecar both reflect current canonical content.

**Package freshness is asserted at two surfaces, and they do not fail alike.** A
criterion that leans on "the freshness gate" has to say which one it means:

- **Deploy-time — `./deploy.sh --check` Check 7.** Always-enforce: its
  `Gate-efficacy posture:` header block in `core/deploy/deploy.sh` declares
  `enforcement-surface: always-enforce (deploy-time)`, so a stale package makes
  `--check` exit non-zero on every run, independent of any mode file. This is the
  surface every "enforced by Check 7" statement in this file refers to.
- **Pre-merge — the `Skill package content-freshness (pre-merge gate)` workflow**
  at `.github/workflows/skill-package-freshness.yml`, a thin caller of
  `deploy.sh --check-package-freshness` that runs Check 7's content-hash verdict
  on every pull request. Whether it BLOCKS is governed by the committed sentinel
  `.github/skill-package-freshness.enforce`, whose first non-comment line is the
  mode token. Read that token; do not infer this surface's mode from the
  deploy-time statements above.

**A stale package is stopped from merging only when both halves hold:** the
sentinel token blocks, so the job goes red, AND the job is a member of the main
branch's `required_status_checks`. That membership is branch-protection state,
which this repository does not version, so it is recorded in the gate-efficacy
register rather than being derivable from the tree. A criterion needing only
"the gate fails on a stale package" depends on the token alone; a criterion
needing "a stale package cannot merge" depends on both halves.

**Current pre-merge mode:** the sentinel token reads `enforce`, so this surface fails
the job red on a rostered package that is stale — or that it could not measure —
rather than annotating it and passing; whether that red job also stops a merge still
depends on the `required_status_checks` half above, which no file here records.

### Automatic post-merge deploy

`core/hooks/git-post-merge-deploy.sh` is installed as the repository's `post-merge`
git hook by `docs/scripts/setup-workspace.sh`, and re-installed by `./update.sh`,
which delegates to the same install pass. It is not a manual step.

When a merge completes, the hook derives the skills that merge brought in and runs
`deploy.sh --deploy <names>` for them — the same targeted form documented in step 1.
It computes its own change set from `ORIG_HEAD` rather than reusing the tag-based
detection, because the tag diff answers "what changed since the last release" while
the question after a merge is "what did this merge bring in". Where no diff base
resolves, or where the merge deleted a skill, it falls back to the no-argument
`deploy.sh --deploy`, which is exactly the manual step-1 behaviour.

Three conditions gate it, and all three must hold:

- **Primary checkout only.** A linked worktree has no hooks directory of its own —
  git reads hooks from the primary checkout — so without this gate a merge inside a
  release worktree would install unmerged branch content over the live copies.
- **`main` only.** A merge on any other branch installs work that is not yet the
  mainline.
- **Not suppressed.** Setting `PMO_SKIP_POST_MERGE_DEPLOY=1` for a single merge
  skips the deploy.

The hook never fails a merge: the merge has already completed by the time it runs,
so every path exits successfully and it reports what it did on standard error.

**The hook deploys; it does not rebuild.** It refreshes installed source and package
copies, and it does not rebuild a stale `.skill` package — that remains step 3, an
obligation of the change that edited the skill, enforced by the package-freshness
gate. A merge whose package was never rebuilt still carries a stale package
afterwards, and the hook is not a substitute for that step.

**The hook is inert until it is installed, and it only repairs merges it observes.**
Drift from a merge that predates the install, or on a machine where the install has
not been run, is not closed by it; the manual step-1 deploy remains the repair.

An operator whose repository is cloned outside the workspace root is told how to
install the hook at setup time rather than having it installed automatically, and
can force the automatic install by setting `PMO_INSTALL_GIT_HOOKS=1`.

## References-only change propagation
A release that touches any `skills/<skill>/references/**` file (a reference doc,
not the `SKILL.md` body) still changes the skill's deployed surface: `deploy.sh`
mirrors `references/` to the Cowork install path (Deployment Step 1, S-2
mechanism) and the `.skill` package carries it. A references-only change is
therefore NOT a no-op — it MUST resolve to one of two dispositions, and the
default is to propagate:

- **(a) Propagate (DEFAULT, primary).** Run `deploy.sh --deploy <skill>` (which
  re-mirrors `references/` per Deployment Step 1) AND rebuild the skill's `.skill`
  package per Deployment Step 3 (`bash core/deploy/tools/build-skill-packages.sh
  <skill>`), at Stage 12, so the mirror and the package stay current with source.
  This is the default because the platform value is no-silent-drift: a
  references-only edit that does not propagate leaves the installed mirror and the
  distributed package stale against source.
- **(b) Record-deferred (explicit fallback).** When propagation cannot run at
  close time (e.g. a doc-only references patch the operator chooses to batch into
  a later deploy), record the deferral with a REQUIRED tracked follow-up — a
  manifest deferral entry (the release plan's Operational Deployment Manifest) OR
  a follow-up issue reference. A deferral without a tracked follow-up pointer is
  not a valid disposition.

`deploy.sh --check` **Check 1** (Skill sync — source-vs-installed `references/`
drift) is the DETECTION backstop, not a substitute for the disposition: it
catches a references-only change that was neither propagated nor deferred. Do NOT
re-implement drift detection — route through Check 1. The worked Stage-12 example
lives in [`pipeline/stage-12-execute.md`](../../release/references/pipeline/stage-12-execute.md)
§ References-only change propagation.

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
have a package get one.

The explicit equivalent of the auto-bootstrap is the full roster by name. Do
not hand-maintain that name list here — it would drift from the arrays (the same
drift class Check 5 guards against). Derive the names from the module arrays in
`deploy.sh` at the moment you need them, then pass them to an explicit-name
deploy:
```bash
# Extract the OPERATIONS_SKILLS + RELEASE_SKILLS + CORE_SKILLS array contents
# from deploy.sh (text-extraction — does NOT execute deploy.sh) and feed the
# array-derived roster to an explicit-name deploy. CANARY_SKILLS is source-only
# (no package, ADR-04) and is intentionally excluded by listing only the three
# module arrays.
roster=$(awk '/^(OPERATIONS|RELEASE|CORE)_SKILLS=\(/{f=1;next} f&&/^\)/{f=0} \
  f&&NF&&$0!~/^[[:space:]]*#/{print $1}' core/deploy/deploy.sh)
./deploy.sh --deploy $roster
```
Equivalently — and simpler — `./deploy.sh --all` deploys the same array-derived
roster (and all packages) in one command without re-listing any names; prefer it
when you just want the full roster.

After bootstrap, a bare `./deploy.sh --deploy` reverts to incremental
tag-diff deployment (the populated mirror is no longer "empty"), keeping the
mirror fresh as skills change. `./deploy.sh --check` Check 12 reports drift on
any mirror that goes stale.

## Mandatory Tooling for Skill Edits

**This section is NON-OPTIONAL.** No "if applicable" escape hatches.

### Existing skills (chained PMO skills)

Modifications to any `{core,operations,release}/skills/<skill>/SKILL.md` (or its `reference/*.md` files) MUST flow through `pmo-skill-editor` (Mode A for edits; Modes B/C/D for audits). Direct Write/Edit to a SKILL.md is blocked at edit-time by `.claude/hooks/block-skill-direct-edit.sh` (BLOCK-SKILL-EDIT-001..002) for any migrated skill (frontmatter `skill_discipline_migrated_v10_2: true`) — **from a main session or a spawned subagent alike, and only while the four-condition coverage boundary holds: loading ∧ no pre-launch `CLAUDE_HOOK_BYPASS` ∧ master-activation class ∧ hook mode.** This hook is `workflow`-class and master activation ships OFF, so condition 3 fails on a default instance and the edit-time gate is then a convention rather than an interlock. Boundary + consequence: [canonical-skill-structure.md § Coverage boundary of the edit-time gate](../standards/canonical-skill-structure.md). Deploy-time enforcement via `./deploy.sh --check` Check 10 (editor audit-trail trailer assertion on last non-merge commit) is **unaffected by that boundary** and is the enforcing half of the pair. See [canonical-skill-structure.md §2 Scope of Enforcement](../standards/canonical-skill-structure.md) for the full enforcement matrix.

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

**The full check set is derived from `deploy.sh`, not enumerated here.** Every
check `deploy.sh` runs logs its own label at runtime (`log "Check N: <label>"`);
to list the live set deterministically, run
`grep -oE 'log "Check [0-9]+[:.]?[^"]*' core/deploy/deploy.sh` (or just
`./deploy.sh --check --warn` and read the per-check log lines). That source — not
a hand-maintained prose list — is the single source of truth for which checks
exist and what each asserts; a hardcoded enumeration here drifts every time a
check is added to `deploy.sh` (the recurring drift this section previously
carried, which left Checks 16/17/19/21/22/24/26/27/31/32/34–46 unlisted). Each
check's `# Check N` comment block in `deploy.sh` carries its full description.

Use `--check` (without `--warn`) to exit non-zero on any drift. Enforcement mode
per `deploy.sh --check` check is **not** maintained here either: it is read from
`.claude/hooks/deploy-check.mode` (a check in its shakedown window runs warn-mode;
an always-enforce check is unaffected by that file). The mode file plus each
check's own `Gate-efficacy posture:` header comment in `deploy.sh` are
authoritative for whether a given check warns or fails. For structured output
(Stage 13 evidence): `./deploy.sh --report`.

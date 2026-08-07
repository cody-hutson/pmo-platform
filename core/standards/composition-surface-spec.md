---
title: Composition-Surface Spec
purpose: Defines the per-category update-time contract and the managed-section / operator-extension marker convention through which package-shipped seed defaults and operator additions coexist durably across version updates. Composes with (does NOT restate) universal-vs-localized-context.md and depersonalization-spec.md.
type: standard
status: ACTIVE
consumers: "deploy.sh / the update mechanism (honors the managed-section + operator-extension markers when applying package-shipped seed defaults across version updates); authors of composable seed-default surfaces (apply the per-category update-time contract); universal-vs-localized-context.md + depersonalization-spec.md (sibling standards this composes with)"
composes_with: [universal-vs-localized-context.md, depersonalization-spec.md, knowledge-architecture.md]
reversibility: CHEAP / Confidence HIGH
---

<!-- reference-durability: allow-link -->

# Composition-Surface Spec

## Purpose

This standard defines the **durability contract** for package-shipped files that operators extend over time — the *composition surface* between the package (universal seed defaults) and the operator (local additions). It exists so that `git pull` of an updated package version preserves operator additions while refreshing package seed content, without manual merge.

This spec owns:

1. The **per-category update-time contract** for the four file categories (Universal, Customizable, Composition-surface, Operator-instance).
2. The **marker syntax convention** for managed-section + operator-extension fences.
3. The **regeneration semantics** under which `update.sh` operates.

This spec does **not** define the universality axis, the leakage rubric, or the token vocabulary — those are owned by [`universal-vs-localized-context.md`](universal-vs-localized-context.md) (audit + enforcement layer) and [`depersonalization-spec.md`](depersonalization-spec.md) (token vocabulary). This spec is the *durability* layer composed on top.

---

## §1 The four file categories

Files in the package fall into one of four categories on the universality × editability matrix. Each category has a distinct **install-time** and **update-time** contract.

| Category | Universality | Operator extends? | Install behavior | Update behavior |
|---|---|---|---|---|
| **Universal** | High (K1) | No | Read in-place from clone | `git pull` updates source; no separate install or update step |
| **Customizable** | Mixed (template + tokens) | No (one-shot resolution) | Token-substitute → write to runtime location | **Not refreshed by `update.sh`.** Re-run `setup-workspace.sh` to recompose from the current template + operator.toml (full-file overwrite). *(An auto-refresh-on-`update.sh` mechanism for Customizable files is specified but not yet implemented.)* |
| **Composition-surface** | Mixed (seed + extensions) | Yes | Token-substitute managed section → write with markers → leave empty operator-additions section | Regenerate managed section from current template + current operator.toml; preserve operator-additions section verbatim |
| **Operator-instance** | Low (K2-K5) | Yes (entirely operator-owned) | Never created by package | Never touched by package |

The durability work this spec introduces closes the update-time gap for the **Composition-surface category** (implemented: `update.sh` regenerates managed sections while preserving operator additions). The **Customizable update behavior** — auto-refresh of Customizable files (CLAUDE.md, settings.json) on `update.sh` — is **specified here but not yet implemented**; Customizable files are refreshed by re-running `setup-workspace.sh`. Pre-spec, the package shipped install-time mechanisms but no update-time mechanism, forcing operators to manually merge on `git pull` or re-install (losing customizations).

### §1.1 Category assignment is durable

Per [`duplicate-source-discipline.md`](duplicate-source-discipline.md), each file belongs to exactly one category. The category is named in either:

- The package manifest — Composition-surface files are declared in the `COMPOSITION_SURFACE_FILES` array ([`core/deploy/composition-surface-manifest.sh`](../deploy/composition-surface-manifest.sh)). Customizable files (CLAUDE.md, settings.json) are composed directly by `setup-workspace.sh` `substitute_templates()`; a parallel `CUSTOMIZABLE_FILES` manifest array is specified but not yet implemented in code.
- An operator-policy registry (for Operator-instance files — never in package).
- Implicit (for Universal files — every K1 file not otherwise classified).

Recategorization is a breaking change — Stage 5 Solutioning gate.

### §1.2 Registered Composition-surface files (informative)

The authoritative manifest is the `COMPOSITION_SURFACE_FILES` array in [`core/deploy/composition-surface-manifest.sh`](../deploy/composition-surface-manifest.sh) (sourced by `setup-workspace.sh` and `update.sh`). The categories of file currently in this surface are the per-domain allowlists (`core/config/allowlists/*.txt`), the hub-state schema templates (`release/releases/hub-state/*.template`), and — as of the adapter-config-foundation release — the platform-behavior config surface [`core/config/platform-config.toml.template`](../config/platform-config.toml.template). Like every composition-surface source file, the platform-config template carries NO fences in source — install-time composition (§3.1) wraps its Layer-1 global defaults in the §2.1 plain-text MANAGED SECTION fence and appends the empty OPERATOR ADDITIONS section the operator then extends. Its per-tier *value* overrides are NOT carried in this surface — they live in separate Layer-2 surfaces (XDG config / `PORTFOLIO.md` / `program-config.toml` / `PROJECT.md`) per [`platform-config-schema.md`](../schemas/platform-config-schema.md).

---

## §2 Marker syntax convention

Composition-surface files at runtime carry two clearly-fenced sections:

### §2.1 Plain-text files (allowlists, mode files, `.txt`, `.conf`)

```text
# === BEGIN MANAGED SECTION (regenerated by update.sh; do not edit) ===
# managed_sha: <sha256 of source template at last regen>
# installed_sha: <sha256 of post-substitution installed managed body — tamper anchor>
# managed_at: <ISO-8601 UTC timestamp>
<content regenerated from template + operator.toml>
# === END MANAGED SECTION ===

# === BEGIN OPERATOR ADDITIONS (preserved across updates) ===
<content operator owns; update.sh never touches>
# === END OPERATOR ADDITIONS ===
```

### §2.2 Markdown files (future markdown composition surfaces)

> **CLAUDE.md is NOT a registered composition surface — it is a Customizable file (§1).** It is composed at install by `setup-workspace.sh` via full-file `[OPERATOR_*]` token substitution and refreshed by re-running `setup-workspace.sh`; it carries no managed-section marker and is absent from `COMPOSITION_SURFACE_FILES`. The markdown marker form below is the **defined form for a future markdown composition surface** — no markdown composition surface is currently registered. (This classification is the recorded decision for CLAUDE.md's category; no separate ADR is filed.)

```markdown
<!-- === BEGIN MANAGED SECTION (regenerated by update.sh; do not edit) === -->
<!-- managed_sha: <sha256 of source template at last regen> -->
<!-- installed_sha: <sha256 of post-substitution installed managed body — tamper anchor> -->
<!-- managed_at: <ISO-8601 UTC timestamp> -->
<content regenerated from template + operator.toml>
<!-- === END MANAGED SECTION === -->

<!-- === BEGIN OPERATOR ADDITIONS (preserved across updates) === -->
<content operator owns; update.sh never touches>
<!-- === END OPERATOR ADDITIONS === -->
```

### §2.3 JSON files (settings.json)

JSON has **no in-file comment syntax** and therefore **no marker carve-out**. Composition is expressed structurally:

- The **entire file is composed at install** from template + operator.toml. Like CLAUDE.md, settings.json is a Customizable file: **`update.sh` does not refresh it** — re-run `setup-workspace.sh` to recompose it (full-file overwrite). Operator customization for JSON-format runtime files flows through:
  - The user-scoped `~/.claude/settings.json` (Claude Code's existing surface for user-global config).
  - New fields added to operator.toml (which the template then resolves when settings.json is recomposed at install/reinstall).

This is a deliberate simplification: JSON-format runtime files are treated as **wholly Customizable** category, not Composition-surface.

### §2.4 Marker properties

| Property | Constraint |
|---|---|
| `managed_sha` | SHA-256 of the **source template** content (pre-substitution). The **regeneration trigger**: source changed ⇒ regenerate. NOT the tamper anchor (for token-bearing files the installed body legitimately differs from the source template). |
| `installed_sha` | SHA-256 of the **post-substitution installed managed-section body** — the exact bytes between the markers, excluding the three marker lines and the OPERATOR ADDITIONS section, trailing newline stripped. The **tamper-detection anchor**: live managed body re-hashed ≠ stored `installed_sha` ⇒ operator hand-edit inside the fence. Distinct from `managed_sha`. The canonical byte-domain is `_extract_managed_body` in `core/deploy/compose.py`, shared by the writer and the `installed-sha` reader so the two cannot drift (ADR-014). Absent on installs predating the marker ⇒ "unknown, not tampered" (self-healing; back-filled on next regen). |
| `managed_at` | ISO-8601 UTC timestamp of last regeneration. Audit trail. |
| Fence text | Verbatim `=== BEGIN MANAGED SECTION ===` / `=== END MANAGED SECTION ===` (with comment-prefix per file syntax). Tools `grep` for these literals. |
| Whitespace inside fences | Preserved verbatim. Tooling does not normalize. |
| Operator additions fence | Required even when section is empty. Absence triggers re-application. |
| Order of fences | MANAGED SECTION always before OPERATOR ADDITIONS. |

### §2.5 Tamper detection

If operator hand-edits content inside the MANAGED SECTION fence, the next `update.sh` invocation:

1. Detects via SHA mismatch: computed SHA of the **current installed managed-section body** vs the stored **`installed_sha`** field. (Token substitution means the installed body legitimately differs from the source template, which is why tamper compares against `installed_sha` (post-substitution) — comparing against `managed_sha` (the pre-substitution source-template hash) would false-positive on every token-bearing file on every run. A missing `installed_sha` ⇒ "unknown, not tampered".)
2. Backs up the tampered file to `~/Claude/.backup-tampered-<ISO8601>/`.
3. Regenerates the managed section from current template + operator.toml.
4. Prints a one-line warning naming the file and backup location.

This protects against silent corruption from manual edits without blocking updates. It is evaluated on **every** file each run, independently of the source-SHA regeneration trigger (§2.4 `managed_sha`) — so an in-fence edit is caught even when the source template is unchanged.

---

## §3 Regeneration semantics

### §3.1 Install (fresh)

`setup-workspace.sh` writes runtime composition-surface files by:

1. Read source template at `core/config/<subdir>/<file>` (in package clone).
2. Read operator.toml at `~/.config/pmo-platform/operator.toml` (created earlier in setup).
3. Substitute tokens (per [`depersonalization-spec.md § 1`](depersonalization-spec.md) vocabulary).
4. Wrap substituted content in MANAGED SECTION fence with current `managed_sha`, `installed_sha` (SHA of the post-substitution body just written), and `managed_at`.
5. Append empty OPERATOR ADDITIONS fence below.
6. Write to runtime location (`~/Claude/.claude/<file>` for hook-tier; `~/Claude/personal/pmo-instance/<file>` for instance-tier).

### §3.2 Update (`./update.sh`)

Two invocation paths regenerate composition surfaces, and they differ only in what else they do. A full `./update.sh` runs the whole update sequence, of which managed-section regeneration is one phase. `./update.sh --surfaces-only` runs the targeted path — pre-flight, schema migration, the instance backup, and managed-section regeneration, and nothing further: no skill redeploy, no security-hook refresh, no `.version` restamp, and no `.last-update` write. The regeneration semantics below are identical on both paths, because both call the same routine; the targeted path exists so a single stale surface can be brought current without the full sequence's blast radius. **`core/deploy/deploy.sh --deploy` is not a third path — it never sources the composition-surface manifest and cannot write a composition surface at all.**

`update.sh` regenerates composition-surface files by:

1. For each file declared in the COMPOSITION_SURFACE_FILES manifest:
   1. Read current source template SHA; parse the installed `managed_sha` and `installed_sha` fields.
   2. **Tamper check (every file, independent of the source-SHA result):** compute the SHA of the current installed managed body and compare to the stored `installed_sha`. On mismatch (and only when `installed_sha` is present — absent ⇒ "unknown, not tampered"), back up the file per §2.5 and force-regenerate it (extract OPERATOR ADDITIONS verbatim, rewrite the fence with fresh `managed_sha` + `installed_sha` + `managed_at`); count it as regenerated; advance.
   3. **If source SHAs match** (and no tamper): no regeneration needed; advance to next file.
   4. **If source SHAs differ**:
      - Extract operator-additions section verbatim.
      - Regenerate managed section from current template + current operator.toml.
      - Write new file: regenerated MANAGED SECTION fence + preserved OPERATOR ADDITIONS fence.
      - Update `managed_sha`, `installed_sha`, and `managed_at` fields.
2. Report per-file outcome (no-change / regenerated / tampered-backed-up) at completion.

### §3.3 Operator-addition rules

Operator additions inside the OPERATOR ADDITIONS fence:

- MAY include comments, blank lines, and content in the file's native format.
- MUST NOT include another BEGIN MANAGED SECTION / END MANAGED SECTION marker pair (the fence is non-recursive).
- MUST NOT span the END OPERATOR ADDITIONS marker (the marker terminates the section).

Operator content outside any fence (above MANAGED SECTION or below OPERATOR ADDITIONS) is **discarded on update** with a warning. This enforces the two-fence structure as the canonical operator-extension surface.

---

## §4 Composition with existing standards

| Boundary | Relationship | Action |
|---|---|---|
| [`universal-vs-localized-context.md`](universal-vs-localized-context.md) | Owns the universality audit (DC1-DC6). Composition-surface files are subject to the same audit; managed-section content MUST pass DC1-DC6 (no operator-name literals, no `#N` refs without §10 disposition, etc.). Operator-additions section is operator-instance content (K2-K5) and is exempt from DC1-DC4 audit. | **Cite.** This spec adds *structure*; audit owns *content correctness*. |
| [`depersonalization-spec.md`](depersonalization-spec.md) | Owns the token vocabulary. Composition-surface managed sections substitute tokens from operator.toml. | **Cite.** Token vocabulary unchanged; this spec adds the durability contract under which substitution operates at install AND update time. |
| [`duplicate-source-discipline.md`](duplicate-source-discipline.md) | Register-or-remove. Each file belongs to exactly one category per §1.1. | Comply. |
| [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | Owns the K1-K5 tier classifier. Composition-surface managed content is K1; operator-additions content is K2-K5. | **Cite.** Tier classifier unchanged; this spec adds the per-tier durability contract. |

---

## §5 Implementation references

The following implementation artifacts realize this spec:

- [`docs/scripts/setup-workspace.sh`](../../docs/scripts/setup-workspace.sh) — install-time composition (writes runtime files with markers).
- `update.sh` (repo root) — update-time regeneration (re-applies markers, preserves operator additions).
- [`core/hooks/notify-version-skew.sh`](../hooks/notify-version-skew.sh) — SessionStart version-notify hook.
- [`docs/UPDATE.md`](../../docs/UPDATE.md) — operator-facing update procedure.

> **Customizable files (CLAUDE.md, settings.json) are not composition surfaces.** They are composed at install by `setup-workspace.sh` `substitute_templates()` (full-file token substitution) and refreshed by re-running `setup-workspace.sh`; `update.sh` regenerates only the registered composition-surface managed sections. `setup-workspace.sh` writes Customizable files by whole-file token substitution (no markers), and writes composition-surface files with the §2 markers.

The `COMPOSITION_SURFACE_FILES` manifest in [`core/deploy/composition-surface-manifest.sh`](../deploy/composition-surface-manifest.sh) (sourced by `setup-workspace.sh` and `update.sh`) is the authoritative list of files in this category — it currently includes the per-domain allowlists, the hub-state schema templates, and [`core/config/platform-config.toml.template`](../config/platform-config.toml.template) (the platform-behavior config surface, adapter-config-foundation). Adding a new composition-surface file is a single appended entry in that manifest — no other code change needed.

---

## §6 Industry precedent

The managed-section + operator-extension pattern composes from multi-decade-precedent across:

| Pattern | Cited from | Element reused here |
|---|---|---|
| Managed-section fence markers | **chezmoi** (dotfiles manager; `# chezmoi:template:start` markers) | Fence syntax; verbatim preservation of operator additions |
| Layered config (user + workspace) | **git** (`~/.gitconfig` + `<repo>/.git/config`) | operator.toml + operator.local.toml resolution order |
| Template + values regeneration | **Helm** (`values.yaml` + `helm upgrade --reuse-values`) | update.sh regeneration semantics |
| New defaults vs. operator edits | **Debian dpkg** (`.dpkg-dist` + 3-way merge) | Backup-on-tamper pattern (§2.5) |
| XDG-spec config location | **FreeDesktop XDG Base Directory Spec** | operator.toml canonical location (`~/.config/pmo-platform/`) |
| Passive version-skew notice | **npm** outdated-notice, **gh CLI** version notice, **brew** update-notice | SessionStart hook UX |

No novel config semantics — the entire pattern is composition of established practice. Public consumers reason about update behavior from prior experience with these tools.

---

## §7 Reversibility

**MODERATE** before the first public-flip release; **EXPENSIVE** post-flip.

Pre-flip: the marker convention is additive. Files without markers are detected by `update.sh` and migrated by its successor when needed. The convention can be revised by a single Stage 5 decision + corresponding update to setup-workspace and update.sh.

Post-flip: changing the marker syntax or category contract becomes a coordinated user-side migration with stakeholder impact. The spec is intended to be **fixed at first public-flip release** and amended only via formal ADR.

---

## §8 Acceptance criteria

This spec is implemented when:

- [ ] Every composition-surface file at runtime carries both MANAGED SECTION and OPERATOR ADDITIONS fences.
- [ ] `update.sh` regenerates managed sections from current template + current operator.toml without touching operator-additions content.
- [ ] An in-fence edit of the installed managed body (live body SHA ≠ stored `installed_sha`) triggers tamper-backup (§2.5) and regeneration — caught even when the source template is unchanged, and without false-positiving on legitimate token substitution.
- [ ] `setup-workspace.sh` install loop writes new composition-surface files with fences from the COMPOSITION_SURFACE_FILES manifest.
- [ ] [`universal-vs-localized-context.md`](universal-vs-localized-context.md) DC1-DC6 audit passes on every managed-section content (no PII; no unresolved `#N` refs).
- [ ] [`depersonalization-spec.md § 1`](depersonalization-spec.md) token vocabulary substitutes correctly in managed sections.

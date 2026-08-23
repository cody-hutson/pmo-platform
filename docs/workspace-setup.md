# workspace-setup.md — Architectural Reference for Workspace Layout

> The "why this" companion to [INSTALL.md](INSTALL.md) ("do this") and [GETTING_STARTED.md](GETTING_STARTED.md) ("try this").
> Audience: operators who completed INSTALL.md and want to understand workspace structure beyond the literal install commands.
> Voice: explanatory, not procedural. For installation steps, see INSTALL.md. For a first-task walkthrough, see GETTING_STARTED.md.

## Table of contents

1. [Why this layout?](#1-why-this-layout)
2. [The five sibling directories](#2-the-five-sibling-directories)
3. [What goes where](#3-what-goes-where)
4. [The operator-instance vs package boundary](#4-the-operator-instance-vs-package-boundary)
5. [Token resolution](#5-token-resolution)
6. [Customization](#6-customization)
7. [Migration from old pmo-platform](#7-migration-from-old-pmo-platform)
8. [Cross-references](#8-cross-references)

---

## 1. Why this layout?

The pmo-platform package is a modular monolith — three modules (`core/`, `operations/`, `release/`) that ship as one repository but maintain crisp inter-module boundaries. The workspace layout exists to keep one boundary CRISPER than any other: **the operator-instance / package boundary**.

The package is shared. Every operator who clones pmo-platform receives the same `pmo-platform/` tree at the same SHA. Operator content — projects, knowledge, personal config, identity-resolved templates — is not shared. It belongs only to the operator. If operator content lived inside `pmo-platform/`, two failures would compound over time:

- **Package upgrades would conflict.** `git pull` of upstream changes would race against operator edits in the same tree. Every upgrade would become a merge exercise.
- **Operator content would accidentally ship to the package.** A misconfigured commit, a stray `git add .`, a copy-paste from a working note — and operator-identifying content lands in the public clone.

The sibling-directory model addresses both. `pmo-platform/` is a clone. Operator content lives in siblings — `projects/`, `knowledge/`, `personal/` — that the package never reads, that the package never writes **operator content into**, and that `git pull` never touches. The boundary is physical, not procedural; the filesystem prevents the failure mode that documentation alone cannot.

The write clause is stated narrowly on purpose. The installer **does** seed a small set of package-managed files into the siblings — the operator-instance surfaces, and the operations context anchor at `projects/CLAUDE.md` — under install-if-missing semantics with a preserved operator-additions fence (§2.2 records the same fact for `projects/` itself, which `setup-workspace.sh` creates). Seeding a managed file the operator then extends is not the failure mode above: the file is never a `git pull` target, and it holds no operator content the package could overwrite. What the package never does is write operator **content** into a sibling.

The rationale for this design is recorded in [ADR-007 — Core module boundary lock-in](../core/ADRs/ADR-007-core-module-boundary.md), which establishes the broader module-boundary principle that the workspace layout expresses operationally.

### 1.1 Why sibling, not parent

A reasonable alternative would be to make `pmo-platform/` itself the workspace root, with `projects/`, `knowledge/`, and `personal/` as children INSIDE it. That model is rejected because it reintroduces the conflict-on-upgrade failure mode:

- Operator content inside `pmo-platform/projects/` would race against any upstream change to `pmo-platform/` (the package directory) during `git pull`.
- Adding `projects/` to `.gitignore` inside the package only avoids accidental commits; it does not avoid the filesystem-level coexistence problem when a future package release adds a `projects/` subdirectory of its own.
- The cleanest decoupling makes operator content a **sibling** of the package, not a child. The clone is a self-contained tree; everything operator-private is outside that tree.

This is the design axis the five-sibling model expresses.

---

## 2. The five sibling directories

```
[CLAUDE_WORKSPACE_ROOT]/        # operator's POSIX workspace root (default: $HOME/Claude)
├── pmo-platform/            # cloned modular-monolith package (immutable from operator perspective)
│   ├── core/                   # shared kernel module
│   ├── operations/             # PMO Operations module
│   ├── release/                # Release Pipeline module
│   ├── docs/                   # user-facing documentation (this directory)
│   └── ...
├── projects/                   # operator's per-project working directories (git-ignored)
│   ├── _config/                # cross-project operational config
│   ├── [Project A]/            # active project
│   └── [Project B]/            # second project
├── knowledge/                  # OPTIONAL: operator's team / company / domain knowledge
│   ├── notes/                  # operator's working notes
│   ├── references/             # external reference material
│   └── domain/                 # team or company knowledge that could reasonably be shared with colleagues
├── pmo-instance/               # platform-written runtime state + operator-instance config the package reads
│   ├── hub-state/              # runtime persistence surfaces
│   ├── inbox/                  # ambient-intake drop-zone
│   └── ...                     # exemption lists, .mode files, needles, roster
└── personal/                   # operator's strictly-private content (NEVER in package)
    ├── notes/                  # personal notes (billing, correspondence)
    └── ...                     # anything irrelevant to the platform
```

Each directory has a distinct role. The sub-sections below name what each one IS, what makes it different from its siblings, and how each is created.

### 2.1 pmo-platform/ — the package

The package directory. Cloned from the upstream pmo-platform repository. Updated by `git pull`. Read-only from the operator's perspective; modifications are pull requests to the upstream repository.

This is the only one of the five sibling directories that is git-tracked AT THE OPERATOR'S WORKSPACE. The other four are operator-instance content; their git posture (if any) is operator-discretionary and lives in a separate repository the operator may or may not maintain.

The package directory hosts:

- The three modules: `core/`, `operations/`, `release/`
- User-facing documentation: `docs/` (this directory)
- Top-level project files: `README.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore`

`pmo-platform/` is created by `git clone https://github.com/cody-hutson/pmo-platform.git ~/Claude/pmo-platform` and refreshed by `git pull` per INSTALL.md.

### 2.2 projects/ — operator's PMO work

The operator's per-project working directories. One sub-directory per active or archived project. Plus a `projects/_config/` directory for cross-project operational config (portfolio health snapshots, session state, active corrections).

Per-project sub-directories contain everything tied to that project: PROJECT.md (project context file), transcripts, status logs, RAID register, communications, and generated artifacts. The PMO skills in `operations/` write into these directories when the operator invokes them.

Why this is separate from the package:

- **Confidential content stays out of the package clone.** A project for client X contains client X's information. The package is public (or will be at the public-flip gate). The two streams must never coexist in the same tree.
- **Per-project size scales independently.** Transcripts, status archives, and meeting notes accumulate. Tying them to package size would slow `git pull` for every operator.
- **Operator-discretionary git posture.** Some operators keep `projects/` in a private repository of their own; others keep it local-only. The package model does not require either choice.

`projects/` is created by `setup-workspace.sh` (per [docs/scripts/setup-workspace.sh](scripts/setup-workspace.sh)) and populated by `mkdir projects/[NewProject]` + author PROJECT.md per [GETTING_STARTED.md](GETTING_STARTED.md).

`projects/CLAUDE.md` — the operations context anchor — is the **only** package-seeded file in `projects/`. The installer writes it if it is absent and never overwrites it; it is pointer-only, naming the platform governance an operations-rooted session loads and restating none of it. Its paths resolve relative to its own location, so it reads correctly from a session rooted at any depth beneath it. No agent can hand-edit it: the autonomy-ceiling control blocks writes to that basename unconditionally, which is what keeps the pointer-only property from depending on review discipline.

### 2.3 knowledge/ — optional knowledge base

The operator's team, company, or domain knowledge. **OPTIONAL** — the platform mechanism does not depend on it. Operators who use external knowledge systems (Notion, Obsidian, Confluence) often skip this directory entirely.

The distinguishing axis: `knowledge/` is content the operator could **reasonably share with their team, organization, or domain peers**. A systems map for the operator's company belongs here. A glossary of domain terms belongs here. External references and white papers belong here. The audience-of-intended-share is what places content in `knowledge/` rather than `personal/`.

When created, `knowledge/` typically holds:

- `knowledge/notes/` — operator's working notes on platform usage, domain concepts, internal processes
- `knowledge/references/` — external reference material (specs, books, articles)
- `knowledge/domain/` — team or company knowledge that could be shared with colleagues

`knowledge/` is OPTIONAL. The setup script creates a placeholder if the operator opts in; the package does not read from this directory.

### 2.4 personal/ — operator's strictly-private content

The operator's content that is **never intended to be shared, even within the operator's organization**. This is the audience-of-intended-share distinction that separates `personal/` from `knowledge/`:

| Distinction | `knowledge/` | `personal/` |
|---|---|---|
| **Intended audience for sharing** | Team, organization, domain peers | Operator only — never shared |
| **Content example** | Domain glossary, internal systems map, external references | Patreon credentials, billing, personal correspondence, operator-instance platform config |
| **Mechanism dependency** | Optional; package does not depend on this directory | None. The package neither reads nor writes anything under `personal/` |

**`personal/` is entirely operator-owned, and the platform provisions nothing inside it.** The setup script does not create it, no package code reads it, and no runtime state is written there.

This section previously described the opposite. It documented an exception — a `pmo-instance/` sub-directory *inside* `personal/` that the package read at deploy time — and that convention originated here rather than in any ratified decision. It has been superseded: the operator-instance family is now a workspace-root sibling, `[CLAUDE_WORKSPACE_ROOT]/pmo-instance/`, listed in the tree above.

The distinction that decided the move is **authored content versus machine-written state**. `personal/` holds the operator's own material — notes, correspondence, working files — and an operator is entitled to treat it as theirs. The instance home holds data the platform writes and reads on its own schedule: hub-state, sweep run-logs, the people roster, the PII needle file, exemption lists and `.mode` files. Nesting the second inside the first made the platform a tenant of the operator's private area and made `personal/` look partly platform-managed, which it is not.

The instance home is resolved by `core/deploy/lib-instance-path.sh` — the single site that spells the leaf — and its per-token defaults and operator.toml overrides are canonical in [`core/standards/depersonalization-spec.md`](../core/standards/depersonalization-spec.md) §4. This document does not restate them.

**If you installed before this change**, your data is still at the old location. Copy it to the new home, keep the originals until you have confirmed the new home works, then remove them. The PII pre-commit guard detects the un-migrated state and says so rather than silently degrading.

### 2.5 Tier semantics — quick reference

| Tier | Directory | Git status | Update mechanism | Operator-vs-package |
|---|---|---|---|---|
| 1 (Package) | `pmo-platform/` | Tracked in clone | `git pull` updates from upstream | Package — read-only from operator perspective; modifications via upstream PR |
| 2 (Operations) | `projects/` | Git-ignored (operator may maintain separate repo) | Operator writes freely | Operator-instance — Cowork-owned per package CLAUDE.md Layer model |
| 3 (Knowledge) | `knowledge/` | Git-ignored (recommended); operator-discretionary | Operator writes freely | Operator-instance — OPTIONAL; some operators use external systems instead |
| 4 (Personal) | `personal/` | Git-ignored | Operator writes freely | Operator-instance — strictly out of package scope; the package neither reads nor writes here |
| 5 (Instance) | `pmo-instance/` | Git-ignored | Created and written by the platform | Operator-instance — platform-written runtime state plus the token-resolved config the package reads; resolved via `core/deploy/lib-instance-path.sh` |

### 2.6 The user-scoped tier — ~/.claude/ and ~/.config/pmo-platform/

Two user-scoped locations hold config scoped to the operator's POSIX user account rather than the workspace root: `~/.claude/` (Claude Code's user-scoped surface) and `~/.config/pmo-platform/` (pmo-platform's canonical operator config, per XDG Base Directory Spec).

These tiers are distinct from `[CLAUDE_WORKSPACE_ROOT]/.claude/` (the workspace-scoped `.claude/` directory inside the workspace root). They are easy to conflate but operate differently:

| Location | Scope | Typical content | Set by |
|---|---|---|---|
| `[CLAUDE_WORKSPACE_ROOT]/.claude/` | Workspace-scoped (this workspace only) | `settings.json` (resolved from template at setup time), `hooks/`, workspace-scoped composition-surface files (allowlists with MANAGED SECTION + OPERATOR ADDITIONS fences) | `setup-workspace.sh` + `update.sh` |
| `[OPERATOR_HOMEDIR_PATH]/.claude/` | User-scoped (all workspaces for this POSIX user) | `.workspace-setup.state` (setup marker), commands the operator wants available everywhere | Claude Code itself + `setup-workspace.sh` initial-run marker |
| `[OPERATOR_HOMEDIR_PATH]/.config/pmo-platform/` | User-scoped (XDG-spec; canonical operator config) | `operator.toml` (canonical operator-instance config; identity + paths + platform-adapter), `.last-update` (timestamp marker from `update.sh`) | `setup-workspace.sh` (creates); `update.sh` (reads + updates `.last-update`) |

Operators encounter `~/.config/pmo-platform/operator.toml` whenever they want to inspect or edit their canonical config (the parameterization source for all `[OPERATOR_*]` / `[CLAUDE_*]` tokens). The file is the single source of truth that `update.sh` reads when regenerating managed sections of composition-surface files. Per-workspace overrides are supported via `<workspace>/operator.local.toml`. Both are documented in [`core/standards/depersonalization-spec.md` §2](../core/standards/depersonalization-spec.md).

---

## 3. What goes where

Canonical artifact-to-directory mapping. When in doubt, use this table.

| Artifact type | Directory | Example |
|---|---|---|
| Package code (skills, hooks, schemas) | `pmo-platform/<module>/` | `pmo-platform/core/skills/prompt-builder/` |
| Package documentation | `pmo-platform/docs/` | `pmo-platform/docs/workspace-setup.md` (this file) |
| Active project artifacts | `projects/[Project]/` | `projects/[PROJECT_KEY] Implementation/05-Transcripts/` |
| Cross-project operational config | `projects/_config/` | `projects/_config/PORTFOLIO.md`, `projects/_config/SESSION_STATE.md` |
| Closed projects (archived) | `projects/Archive/` | `projects/Archive/[OldProject]/` |
| Operator-instance platform config + runtime state | `pmo-instance/` | `pmo-instance/skill-editor-exemption-list.txt`, `pmo-instance/deploy-check.mode`, `pmo-instance/hub-state/` |
| Operator's personal notes | `personal/notes/` | `personal/notes/billing/`, `personal/notes/patreon/` |
| Optional team / company knowledge | `knowledge/domain/` | `knowledge/domain/[COMPANY_X]-systems-map.md` |
| External reference material | `knowledge/references/` | `knowledge/references/scrum-guide-2020.pdf` |
| Workspace-scoped Claude config | `[CLAUDE_WORKSPACE_ROOT]/.claude/` | `.claude/settings.json` (resolved from template), `.claude/hooks/` |
| User-scoped Claude config | `~/.claude/` | `~/.claude/.workspace-setup.state` |

A test for any novel artifact: ask whether the package needs to read it. If yes, it belongs in `pmo-instance/` (operator-instance) or `pmo-platform/` (package itself). If no, ask who the intended audience for sharing is. Operator-only → `personal/`. Team or organization → `knowledge/`. Active project work → `projects/[Project]/`.

---

## 4. The operator-instance vs package boundary

The package / operator-instance distinction is the architectural axis the entire layout serves. Stating the distinction concretely:

- **Package content** is **universal** — every operator who clones `pmo-platform/` receives identical files at the same SHA. Examples: skill definitions, hook scripts, schemas, governance protocols, templates.
- **Operator-instance content** is **localized** — values that resolve differently for each operator. Examples: the operator's name in CLAUDE.md, the workspace root path in settings.json, the operator's exemption lists.

The package ships **templates** carrying token placeholders for the operator-instance values it cares about. The setup script reads operator-provided values once and substitutes tokens, writing the resolved files to operator-instance locations outside the package tree. The package itself is never modified.

This is the **parameterization seam** between package and operator-instance: the package declares the tokens it needs; the operator declares the values for those tokens; the setup script links the two; from that point forward, the package reads resolved values without re-resolving them at runtime.

The canonical reference for the universality axis (which content classes are package vs operator-instance, and why) lives at [`core/standards/universal-vs-localized-context.md`](../core/standards/universal-vs-localized-context.md). The token vocabulary and per-token resolution semantics live at [`core/standards/depersonalization-spec.md`](../core/standards/depersonalization-spec.md). Both documents are the source-of-truth for content classification; this workspace-setup.md document does not restate them.

The operational consequence of the boundary: when an operator wants to **change platform behavior**, the question is "what tier of content does the change touch?" Changes to package code go upstream as pull requests. Changes to operator-instance values go to the operator's local `pmo-instance/` files or to the resolved `[CLAUDE_WORKSPACE_ROOT]/CLAUDE.md` and `[CLAUDE_WORKSPACE_ROOT]/.claude/settings.json`. The boundary is rarely ambiguous once the universality axis is internalized.

---

## 5. Token resolution

The package ships templates carrying square-bracket token placeholders that the setup script substitutes with operator-provided values. The full token vocabulary lives at [`core/standards/depersonalization-spec.md § 1`](../core/standards/depersonalization-spec.md) — this section explains the mechanism, not the vocabulary.

### 5.1 The three-step flow

1. **Templates ship in package.** `pmo-platform/core/CLAUDE.md.template` and `pmo-platform/core/settings.json.template` carry `[TOKEN_NAME]` square-bracket placeholders. Templates are universal — they ship identically to every operator.
2. **`setup-workspace.sh` prompts operator at install time.** The script (at [`docs/scripts/setup-workspace.sh`](scripts/setup-workspace.sh)) prompts for operator-provided values (`[OPERATOR_NAME]`, `[OPERATOR_EMAIL]`, etc.) and infers others from environment (`[CLAUDE_WORKSPACE_ROOT]` from `$HOME/Claude`, `[OPERATOR_GIT_EMAIL]` from `git config user.email`).
3. **Resolved files land in operator-instance locations.** The script writes `[CLAUDE_WORKSPACE_ROOT]/CLAUDE.md` (resolved) and `[CLAUDE_WORKSPACE_ROOT]/.claude/settings.json` (resolved). The templates inside `pmo-platform/core/` remain untouched.

### 5.2 What a token IS

- **Square-bracket bare placeholder** — written as `[OPERATOR_NAME]`, not `${OPERATOR_NAME}`, not `{{OPERATOR_NAME}}`. The bracket form is the canonical rendering convention per [`depersonalization-spec.md § 1`](../core/standards/depersonalization-spec.md), and disambiguates from the `{{PLACEHOLDER}}` form used by project-initiator at scaffold time (different mechanism, different resolution lifecycle) and from `$ENV_VAR` shell substitution.
- **Resolved ONCE, at setup time.** Tokens are not re-resolved at runtime. The setup script does the substitution; from that point on, the resolved files contain the substituted values as literal text.
- **Operator-provided OR environment-inferred.** Some tokens (`[OPERATOR_NAME]`, `[OPERATOR_EMAIL]`) come from explicit operator input at install time. Others (`[CLAUDE_WORKSPACE_ROOT]`, `[OPERATOR_GIT_EMAIL]`) come from environment inference where a reasonable default exists.

### 5.3 Where to read about tokens

For the full canonical token vocabulary — the ~10 tokens the package depersonalizes, the source-of-truth for each, and the consumer surfaces — see [`core/standards/depersonalization-spec.md § 1`](../core/standards/depersonalization-spec.md). For the substitution mechanism implementation, see [`docs/scripts/setup-workspace.sh`](scripts/setup-workspace.sh). For the templates themselves, see [`core/CLAUDE.md.template`](../core/CLAUDE.md.template) and [`core/settings.json.template`](../core/settings.json.template).

---

## 6. Customization

Each of the five sibling directories supports operator customization, with different mechanics per directory — though `pmo-instance/` is platform-managed, so customization there means editing the config files the package reads, not adding content of your own.

### Adding a project

`mkdir projects/[NewProject]` and author `projects/[NewProject]/PROJECT.md` per the project-context-file convention. The platform's PMO operations skills (in the `operations/` module) read PROJECT.md to determine project state; they write generated artifacts into `projects/[NewProject]/08-Generated/`. See [GETTING_STARTED.md](GETTING_STARTED.md) for a first-project walkthrough.

### Adding knowledge

`mkdir knowledge/<sub-dir>` and author whatever the operator's domain calls for. The package does not constrain `knowledge/` structure; operators choose their own organization (notes/references/domain are common but not mandatory). The platform mechanism does not depend on `knowledge/` content; some operators leave the directory empty or skip it entirely and use Notion / Obsidian / Confluence instead.

### Extending personal

`personal/` is operator-discretionary and carries no platform constraint at all — `personal/notes/`, `personal/correspondence/`, `personal/<whatever>/` are entirely the operator's. Operator-instance platform config lives in the workspace-root `pmo-instance/` sibling instead (per Section 2.4); that directory is platform-managed, so it is the one place under the workspace root an operator should not treat as free space.

### Modifying package behavior

Modifications to package code go upstream as pull requests against the canonical pmo-platform repository. The clone in `pmo-platform/` reflects upstream state; do not edit it locally unless preparing a PR. For operator-discretionary behavior changes (which skills to invoke, which hooks to enforce, which checks to run), use operator-instance config in `pmo-instance/` rather than editing package files.

For the operational installation procedure (the literal commands), see [INSTALL.md](INSTALL.md) § Configuration.

---

## 7. Migration from old pmo-platform

Operators migrating from a pre-modular-monolith pmo-platform layout require a selective copy of their operator-instance content into the new sibling-directory layout. The procedure is non-trivial: not every file from the old workspace transfers; some files restructure; some are deprecated.

**Migration is deferred to a later release.** A future release will publish a step-by-step migration procedure.

Until then, operators with content in the old pmo-platform layout should:

- Leave the old workspace in place — it continues to function for governance and tracking purposes.
- Stand up the new pmo-platform workspace from a clean clone per [INSTALL.md](INSTALL.md).
- Avoid attempting to merge the two workspace layouts manually; the migration procedure (forthcoming) handles the boundary semantics deliberately.

---

## 8. Cross-references

### The onboarding trio

- [INSTALL.md](INSTALL.md) — "do this" companion. Step-by-step installation procedure.
- [GETTING_STARTED.md](GETTING_STARTED.md) — "try this" companion. First-task walkthrough after install.
- **workspace-setup.md** (this document) — "why this" companion. Architectural rationale for the workspace layout.
- [UPDATE.md](UPDATE.md) — "keep this current" companion. Version-update procedure that preserves operator additions.

### Mechanism

- [docs/scripts/setup-workspace.sh](scripts/setup-workspace.sh) — the workspace bootstrap script. Creates the sibling directories, resolves tokens, writes the resolved CLAUDE.md and settings.json.
- [docs/module-apis.md](module-apis.md) — consolidated cross-module public API reference.

### Canonical sources (for content classification + token vocabulary)

- [`core/standards/universal-vs-localized-context.md`](../core/standards/universal-vs-localized-context.md) — universality axis; what is package-content vs operator-instance content.
- [`core/standards/depersonalization-spec.md`](../core/standards/depersonalization-spec.md) — canonical token vocabulary; per-token source-of-truth; consumer surfaces.

### Templates the setup script resolves

- [`core/CLAUDE.md.template`](../core/CLAUDE.md.template) — primary workspace-root template (resolved to `[CLAUDE_WORKSPACE_ROOT]/CLAUDE.md`).
- [`core/settings.json.template`](../core/settings.json.template) — settings template (resolved to `[CLAUDE_WORKSPACE_ROOT]/.claude/settings.json`).

### Module entry points

- [`core/README.md`](../core/README.md) — Core module (shared kernel: skills, hooks, schemas, deploy infrastructure).
- [`operations/README.md`](../operations/README.md) — Operations module (PMO practitioner skills, references, templates).
- [`release/README.md`](../release/README.md) — Release module (release pipeline, governance, skills).

### Architectural decision records

- [`core/ADRs/ADR-007-core-module-boundary.md`](../core/ADRs/ADR-007-core-module-boundary.md) — Core module boundary lock-in; the upstream design decision the workspace layout expresses operationally.


---
title: Instance-Data Placement Standard
purpose: Says where every kind of data the platform keeps out of git lives and what protects it there — the four risk classes and their homes, the admission test for a repository's in-repo homes, the protections each class carries, the folder-plus-README-tracked idiom, the register of every non-tracked surface, the five-step checklist a new surface passes, and the naming rule for new path tokens.
type: standard
status: ACTIVE
consumers: "authors and Stage 5 designs that add or move a kind of non-tracked data (the checklist and the register); the main-checkout write carve-out and the hook that enforces it (the registered in-repo homes, held in parity with the hook's static set); the resolver, guard, installer, migration and new-surface-check milestones of the parent epic (classes, homes, protections, register); the token registry in depersonalization-spec.md, whose Class column projects this standard's register"
composes_with: [public-repo-vs-operator-instance-taxonomy.md, depersonalization-spec.md, analysis-workspace-standard.md, initiative-roadmap-framework.md, skill-workspace-location.md, secrets-handling-policy.md, hub-session-continuity.md, gate-efficacy-standard.md]
reversibility: MODERATE / Confidence MEDIUM
---

# Instance-Data Placement Standard

## Purpose

The platform keeps several kinds of data out of git: release-hub run state, the pipeline event log, close-out registers, warn logs, usage telemetry, allowlist instances, the PII scan lists and the people roster, the operator's project content, and the files other tools own. For each of them this standard answers one question: **where does it live, and what protects it there?**

The answer is decided by the data's **risk class** — what would follow if it reached a repository — and not by who writes it. The decision, its alternatives and its consequences are recorded in ADR-231 (the record under `core/ADRs/` whose file name ends `non-tracked-data-homed-by-risk-class.md`). This standard is its operational half: it names the classes and their homes, registers every non-tracked surface against one class, and states the checklist a new surface passes before it has a home.

## Scope and composition

| Question | Where it is answered |
|---|---|
| Does an artifact ship in the repository at all? | `core/standards/public-repo-vs-operator-instance-taxonomy.md` — the public-class axis. Everything this standard places sits on that taxonomy's operator-instance side; this standard decides where it lives. |
| Which path tokens exist, with their canonical defaults and override fields? | `core/standards/depersonalization-spec.md` § Operator-instance path tokens — the token registry. Its Class column repeats this standard's register (§ The token registry's Class column, below). |
| Where do secrets and credentials live? | `core/standards/secrets-handling-policy.md` and its storage tiers. This standard does not home secrets. |
| How is a resolver, guard, installer step or migration built? | The milestones of the parent epic named under § Protections and § New-surface checklist. This standard states what each delivers, not how. |
| When are hub-state resume surfaces written? | `core/standards/hub-session-continuity.md`. |

## The four classes

| Class | What would follow if it reached a repository | Contents | Home | Protection |
|---|---|---|---|---|
| **Working state** | No privacy harm by construction, but machine-written churn in the repository's history and operator-local detail — paths, run identifiers — on a public surface | Release-hub runs, the pipeline event log, close-out registers, warn logs, allowlist instances (each after its identifier check and the admission test), and the read-once analysis and roadmap instances about the repository | An in-repo git-ignored home at the root of the main checkout of the repository the data is about: `/local-state/` for release, run and operating state; `/analysis/` and `/roadmaps/` for their own content | Ignore rule plus commit guard |
| **Working state, install-scoped** | The same, but its records describe work outside any one repository | Usage telemetry, which records every session on the install | `${XDG_STATE_HOME:-$HOME/.local/state}/pmo-platform/telemetry/` | Outside every repository and workspace |
| **Leak-risk** | A privacy or security incident that cannot be withdrawn once pushed to a public remote | The PII scan lists, the people roster, its clarification queue, their backups, and an embargoed security-fix run until disclosure | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` | Outside every repository and workspace; the permission policy; the resolver refuses a home inside a git work tree |
| **Operator PMO content** | The operator's other areas of work — employer or client material — published in a repository that is not about them | Projects, portfolio, meetings, the intake inbox, and the corrections recorded against them | `${CLAUDE_WORKSPACE_ROOT}/projects/`, unchanged | Outside every repository |
| **Tool-owned** | Not this standard's question: the owning tool decides where the data lives and what protects it | The agent harness's config roots (deployed hooks, rules mirror, settings, skills, worktrees), the workspace charter, the memory store, the platform's per-user configuration | Unchanged — where its owning tool puts it | Its owning tool's |

**Outside the four classes.** Two kinds of content the register names are tracked, so no non-tracked class applies to them:

- **Tracked repository content** — the repository's own record, kept in git. The release corpus is the case this standard names (§ The release corpus and its selector).
- **Package content** — files the repository ships for the installer to provision, such as the hub-state templates. The shipped source stays tracked; a provisioned copy is not package content, and lives in the home of the class it seeds.

### Classifying a surface

Ask these in order and take the first answer that is yes.

1. **Does it ship?** If anyone other than the originating operator's sessions reads it, verbatim or as a template, it is tracked repository content or package content, per the public-repo taxonomy, and it is not placed here.
2. **Does an owning tool already govern its location?** The agent harness, or the platform's own per-user configuration: Tool-owned.
3. **Would it be a privacy or security incident in any repository?** Personal data about identifiable people, the operator's scan needles, or a security fix before disclosure: Leak-risk.
4. **Is it the operator's own delivery, project or portfolio work?** Operator PMO content.
5. **Otherwise it is working state.** Apply § The admission test: it is Working state when every record concerns only that repository, and Working state, install-scoped otherwise.

**A surface that mixes classes is split along the line between them, or the whole surface takes the more protective class.** Leak-risk is the most protective, then Operator PMO content, then working state.

### Classes decided per instance

- **An embargoed security-fix run** is Leak-risk until disclosure, then Working state. A hub classifies each run when it starts, and the resolver takes the run's class as an argument.
- **An allowlist instance** is Working state only after two checks pass on it: an identifier check finds no operator identifier in it, and § The admission test admits it — every entry concerns only this repository. An instance that carries an operator identifier is Leak-risk; one whose entries describe the operator's other work takes the class that content earns. Each instance is checked on its own.

## Homes

Each class's home, as a concept model:

```
classes → homes
├── <the main checkout of each repository the platform releases>/
│   ├── local-state/       Working state — that repository's release, run and operating state
│   │   ├── release-runs/   event-log/   registers/
│   │   ├── logs/           telemetry/   allowlists/
│   │   └── process-catalog/
│   ├── analysis/          Working state — read-once analysis about that repository
│   ├── roadmaps/          Working state — roadmap instances for that repository's program
│   └── release/releases/  Tracked repository content — the release corpus (corpus_home = tracked)
├── ${XDG_STATE_HOME:-$HOME/.local/state}/pmo-platform/telemetry/    Working state, install-scoped
├── ${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/   Leak-risk
├── ${CLAUDE_WORKSPACE_ROOT}/projects/                                 Operator PMO content
└── Tool-owned — where each owning tool puts it: the agent-config roots, the memory store,
    the workspace charter, ${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}/
```

**Every repository the platform runs releases for has its own homes.** An external target ships its own `/local-state/`, ignore rule and commit guard; a hub reads the target at run time and stores nothing about it in another repository's home. Where an operator holds more than one clone of a repository, every clone resolves to one designated main checkout's homes.

**No platform folder remains at the workspace root once today's container is retired.** The workspace root then holds the operator's own areas of work, the repository checkouts and `projects/`. The operator's own areas of work, the personal area included, are no class's home: the platform creates nothing there, reads nothing from them and writes no runtime state there, as ADR-231 carries forward from ADR-141 (its § Carried forward from ADR-141, clause 1).

### Registered in-repo git-ignored homes

| Home | Admits | Main-checkout carve-out admits | Governing standard | Ignore-rule pair |
|---|---|---|---|---|
| `/local-state/` | The repository's own release, run and operating state, in the subfolders the concept model names | `/local-state/` and everything under it | This standard | `/local-state/*` then `!/local-state/README.md` |
| `/analysis/` | Read-once analysis about the repository | a subfolder, `/analysis/<sub>/` | `core/standards/analysis-workspace-standard.md` | `/analysis/*` then `!/analysis/README.md` |
| `/roadmaps/` | Initiative-roadmap instances for the repository's program | a roadmap instance, `/roadmaps/<name>` | `core/standards/initiative-roadmap-framework.md` | `/roadmaps/*` then `!/roadmaps/README.md` |

**These three homes are exactly the set the main-checkout write carve-out admits under the superseding record.** The superseding record lets a worktree or spoke session write into the main checkout only inside the paths the carve-out column names, and nowhere else. The hook that enforces the carve-out keeps that set as a static pattern in its own source, never read from this table, because an exemption read from an agent-writable surface would make the guard's escape hatch writable by its own subject. Today the hook's static set holds `/analysis/<sub>/` and `/roadmaps/<name>`; `/local-state/` joins it in the worktree-sessions slice's change, with the parity check, and until then no session writes `/local-state/` in the main checkout. The table and the hook's static set are therefore two surfaces held equal by a parity check, owned by the worktree-sessions slice and the new-surface check (§ References), which fails when they disagree. **Registering a home here admits no write until the hook's static set changes in the same change.** A git-ignored path this table does not list — a tool's scratch output folder, for example — is not a registered home, and becomes one only through § New-surface checklist. A new subfolder of `/local-state/` is registered the same way.

### The release corpus and its selector

The release corpus — the release log with its archives, the release index, the release digest, the reversions ledger, and the notes and plans folders — is tracked repository content, not one of the non-tracked classes. Its home is named per install by `operator.toml [adapters] corpus_home`:

| `corpus_home` | Class | Home | State |
|---|---|---|---|
| `tracked` — the default and the only value; an absent key reads as it | Tracked repository content | `release/releases/` in the repository whose releases it records | In force — today's layout |

**No non-tracked value is reserved.** The selector is declared and not yet read: the close-out tooling's corpus resolver resolves the corpus by presence, the tracked tree first. A non-tracked corpus home is decided, with its class and its path, by the change that teaches that resolver to read the selector, and that change registers the home here through § New-surface checklist. **The leak-risk home is never a corpus home:** the corpus carries no leak-risk content. The decision and its reasons are recorded in ADR-231, in its release-corpus location item.

### Until each repository's cutover

A governed home is where a surface lives after its repository's cutover. Until that cutover the surface resolves to today's path through the pointer its register row names in **Resolves today through** — hub state, for one, through `<OPERATOR_INSTANCE_HUB_STATE_PATH>`. Today's out-of-tree container is `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/`, resolved through `pmo_instance_path` in `core/deploy/lib-instance-path.sh`. One resolver per class sits behind a switch that keeps today's paths and is flipped per repository at its cutover.

**A surface that states where a kind of data lives says both things:** its class and governed home, citing this standard, and the path it resolves to until cutover.

## The admission test

**A repository's in-repo git-ignored homes admit only content about that repository.** Both limbs apply:

1. **`/local-state/` admits only that repository's own release, run and operating state** — what a platform run produces, and the configuration it reads, while releasing or operating that repository. `/analysis/` admits only analysis about that repository, and `/roadmaps/` only roadmap instances for its program, as their own standards state.
2. **Content about the operator's other areas of work never enters a repository's tree, ignored or not.** That covers another repository's runs, the operator's project and portfolio work, and any record that describes a session, folder or work item outside the repository. Stripping an identifier does not admit such a record: removing a folder name removes the path, not the fact that the record describes work elsewhere.

**Applying it.** For every record the surface can hold, ask: *does every record concern only this repository?* The surface is admitted only when the answer is yes for every such record. A surface that is otherwise working state but whose records describe work across the install is Working state, install-scoped, and takes the install-level home. A surface whose records are the operator's other work takes the class that content earns — Operator PMO content or Leak-risk — and never an in-repo home. A hub run for an external target is that target's run state and belongs in the target's own `/local-state/`.

**Derived rows.** A record computed from install-scoped data is admitted when the computed record itself concerns only this repository's work — a per-release cost row for one of this repository's releases, for example — and carries no working folder, session or work item from elsewhere. Such rows may live in `/local-state/telemetry/`; the install-scoped store they are computed from may not.

## Protections

| Class | Protection | Delivered by |
|---|---|---|
| Working state, in-repo | The ignore-rule pair of § The folder-plus-README-tracked idiom; a commit guard, at pre-commit and in CI, over every registered home, a forced add included; and every check that walks the repository tree excludes the homes | The pairs for `/analysis/` and `/roadmaps/` are in the tree. `/local-state/`, its README and pair, the commit guard and the tree-walk exclusions come from the in-repo-home-is-guarded milestone. An ignore rule alone does not stop a forced add, so until the guard ships the rule is the only protection |
| Working state, install-scoped | Outside every repository and workspace | The resolver milestone and the installer milestone |
| Leak-risk | Outside every repository and workspace. **The permission policy:** mode 0700 on each folder and mode 0600 on each file, backups included. The resolver refuses a resolved home that sits inside a git work tree. An operator who syncs or versions the XDG data home excludes this container | The permission policy from the in-repo-home-is-guarded milestone; the refusal from the resolver milestone; provisioning at the policy from the installer milestone; moving today's files under it from the migration milestone |
| Operator PMO content | Outside every repository; never admitted to an in-repo home | Unchanged |
| Tool-owned | Its owning tool's | Unchanged |

The milestones are the parent epic's: in-repo-home-is-guarded, one-resolver-and-release-tool-routing (the resolver), install-provisions-every-home (the installer) and migration-tooling-and-rehearsal (the migration). § References names their work items.

## The folder-plus-README-tracked idiom

Every in-repo git-ignored home has the same four properties. They are stated here once; a home's own standard cites them rather than restating them.

1. **A folder at the root of the repository's main checkout,** named for what it holds.
2. **A tracked `README.md` in the folder** that says what the home admits, that everything else in it is git-ignored, and which standard governs it. It is how a fresh clone discovers the home.
3. **An ignore-rule pair in the repository's `.gitignore`:** `/<home>/*` and then `!/<home>/README.md`, in that order, so the contents are ignored and the README is not.
4. **No other tracked content.** `git ls-files <home>/` lists the README alone. Subfolders are created by provisioning and never tracked; no placeholder file keeps one alive in git.

The folder ships with the repository, so a fresh clone has the home with no install step; provisioning creates the subfolders a home declares.

## Surface register

Every non-tracked platform surface that tracked code resolves or writes today has one row, and a new one gains its row through § New-surface checklist. **Class** holds one term of the closed class vocabulary — `Working state`, `Working state, install-scoped`, `Leak-risk`, `Operator PMO content` or `Tool-owned`, or, for a tracked surface, `Tracked repository content` or `Package content` — spelled as the class table above spells it. A surface whose class is not yet decidable reads `Undecided`, which is a marker and not a class: its **Governed home** cell names, by role, the change that decides it, and no path token is registered for it until then. **Governed home** is where the surface lives after its repository's cutover; **Resolves today through** is the pointer, and the leaf in today's container, it uses until then. **Source** says why the row exists: `fit/gap` for a member of the parent epic's fit/gap population (§ References), `registry` for a surface the token registry names, `design` for one a decision record or a Stage-5 design names, and `code` for a member tracked code resolves under the instance resolver, writes under an in-repo git-ignored path, or reads or writes at the workspace root.

| ID | Surface | Class | Governed home | Resolves today through | Source |
|---|---|---|---|---|---|
| S-01 | Release-hub run folders | Working state | `/local-state/release-runs/` of the repository the run belongs to; an external target's runs go to that target's own home | `<OPERATOR_INSTANCE_HUB_STATE_PATH>` — `hub-state/` in today's container | fit/gap |
| S-02 | Provisioned copies of the hub-state templates | Working state | S-01's home, provisioned by the installer from the shipped source `release/releases/hub-state/*.template`, which is package content and stays tracked | Copies inside today's container, through `pmo_instance_path` | fit/gap |
| S-03 | Pipeline event log | Working state | `/local-state/event-log/`, one log per repository | `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>`, through `pmo_evals_results_path` | fit/gap |
| S-04 | Close-out registers | Working state | `/local-state/registers/` | The container's `releases/registers/` subfolder, through `pmo_instance_path` | fit/gap |
| S-05 | Deploy-check warn logs | Working state | `/local-state/logs/` | The container root, through `pmo_instance_path` | fit/gap |
| S-06 | Usage telemetry store | Working state, install-scoped | `${XDG_STATE_HOME:-$HOME/.local/state}/pmo-platform/telemetry/`; a derived row that passes § The admission test may live in `/local-state/telemetry/` | `<OPERATOR_INSTANCE_FINOPS_STORE_PATH>` | fit/gap |
| S-07 | Allowlist instances, each classed after its identifier check and § The admission test | Working state | `/local-state/allowlists/`; an instance that carries an operator identifier goes to the leak-risk home, and one whose entries describe other work takes the class that content earns | The container root, through `pmo_instance_path`: `skip-doc-link-check.txt`, read by deploy Check 14, and `agents-model-overrides.txt`, read by deploy Check 27; and `skill-editor-exemption-list.txt`, through `pmo_skill_editor_exemption_list`; and `status-label-invariant-exemption-list.txt`, which the installer provisions there through the composition manifest's instance tier (deploy reads its copy under `.claude/`) | fit/gap |
| S-08 | PII scan lists and their backups | Leak-risk | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` | `pmo_localized_needles` — `localized-context-needles.txt` in today's container | fit/gap |
| S-09 | People roster and its backups | Leak-risk | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` | `pmo_people_roster` — `people-roster.yaml` in today's container | fit/gap |
| S-10 | Roster clarification queue and its backups | Leak-risk | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` | The container root, beside the roster | fit/gap |
| S-11 | Intake inbox | Operator PMO content | `${CLAUDE_WORKSPACE_ROOT}/projects/`, at the master inbox's location | `<OPERATOR_INSTANCE_INBOX_PATH>` — `inbox/` in today's container | fit/gap |
| S-12 | Intake-sweep stub | Operator PMO content | `${CLAUDE_WORKSPACE_ROOT}/projects/` for any content it gains; retired while it stays empty | `<OPERATOR_INSTANCE_INTAKE_SWEEP_RUNLOG_PATH>` — `ambient-intake/` in today's container | fit/gap |
| S-13 | External-sync stub | Operator PMO content | `${CLAUDE_WORKSPACE_ROOT}/projects/` for any content it gains; retired while it stays empty | `<OPERATOR_INSTANCE_EXTERNAL_SYNC_SNAPSHOT_PATH>` and `<OPERATOR_INSTANCE_EXTERNAL_SYNC_RUNLOG_PATH>` — `external-sync/` in today's container | fit/gap |
| S-14 | Scratch stub | Operator PMO content | `${CLAUDE_WORKSPACE_ROOT}/projects/` for any content it gains; retired while it stays empty | The container root, through `pmo_instance_path` | fit/gap |
| S-15 | The `scan.sh` script in the container | Leak-risk | Its operator-specific literals join S-08's scan lists; its generic patterns ship in the repository as package content if a reader remains, and are retired otherwise | The container root | fit/gap |
| S-16 | Return-value warn log | Working state | `/local-state/logs/` if a reader is found; retired otherwise | The container root | fit/gap |
| S-17 | Installed copy of the platform-config template | Tool-owned | None: the copy is retired, and the template is read in place from the clone at `core/config/platform-config.toml.template`, which is package content | The container root | fit/gap |
| S-18 | Archived bodies of expired corrections | Operator PMO content | The `projects/` folder that holds the corrections file the entry expired from: `${CLAUDE_WORKSPACE_ROOT}/projects/_config/` for a platform-wide entry, the project's own folder for a project-scoped one | Today's container | fit/gap |
| S-19 | Embargoed security-fix runs, until disclosure | Leak-risk | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/` until disclosure, then S-01's home | S-01's path, until the resolver takes a run's class | design |
| S-20 | Analysis workspace | Working state | `/analysis/` | `<OPERATOR_INSTANCE_ANALYSIS_PATH>` | registry |
| S-21 | Roadmap instances | Working state | `/roadmaps/` | `<OPERATOR_INSTANCE_ROADMAPS_PATH>` | registry |
| S-22 | Judge-calibration ledger | Working state | `/local-state/registers/` | `<OPERATOR_INSTANCE_EVALS_PATH>` | registry |
| S-23 | Projects and the operations config | Operator PMO content | `${CLAUDE_WORKSPACE_ROOT}/projects/` and its `_config/` folder | `<OPERATOR_INSTANCE_PROJECTS_PATH>` and `<OPERATOR_INSTANCE_PROJECTS_CONFIG_PATH>` | registry |
| S-24 | Workspace charter | Tool-owned | `${CLAUDE_WORKSPACE_ROOT}/CLAUDE.md` | `<OPERATOR_INSTANCE_CLAUDE_MD>` | registry |
| S-25 | Agent-config roots: the deployed hooks, the hooks' own mode files and settings in the workspace's agent-config root, and the rules mirror the deploy lays down | Tool-owned | `${CLAUDE_WORKSPACE_ROOT}/.claude/` for the hooks and settings; `~/.claude/rules/` for the rules mirror | `<OPERATOR_INSTANCE_CLAUDE_DIR>` and `<OPERATOR_INSTANCE_CLAUDE_SETTINGS>` | registry |
| S-26 | Deployed skills: the workspace deployment target and the user-local mirror | Tool-owned | `${CLAUDE_WORKSPACE_ROOT}/.claude/skills/`; the user-local mirror at `~/.claude/skills/` | `<OPERATOR_INSTANCE_SKILLS_PATH>` | registry |
| S-27 | Session worktrees | Tool-owned | `${CLAUDE_WORKSPACE_ROOT}/.claude/worktrees/` | `<OPERATOR_INSTANCE_WORKTREES_PATH>` | registry |
| S-28 | Operator memory store | Tool-owned | Where the agent harness keeps it | The harness's own configuration | design |
| S-29 | Platform per-user configuration | Tool-owned | `${PMO_PLATFORM_CONFIG_ROOT:-$HOME/.config/pmo-platform}/` | The same | design |
| S-30 | Release corpus | Tracked repository content | `release/releases/` under `corpus_home = tracked`; § The release corpus and its selector | The close-out tooling's corpus resolver, by presence, the tracked tree first. Deploy Check 26 reads only `RELEASE_LOG.md` and `releases/notes/` in today's container, through `pmo_instance_path`, and reports when they are absent; readers use the in-repo log | design |
| S-31 | Deploy-check and commit-hook mode files: the shared dial, the per-check dials, the named dials and the PII commit hook's dial | Working state | `/local-state/` of the repository whose checks read them, in a subfolder decided by the consumer-routing card's change. A move keeps a fallback rung or asserts the posture positively, because a stranded mode file silently reverts the operator's `enforce` or `off` to the shipped default | `pmo_instance_path` — `deploy-check.mode`, the per-check `<check-id>.mode` family that `resolve_check_mode` reads, and the named dials `registry-field-currency.mode` and `check-convention.mode` — then the legacy home, then `.claude/hooks/` in the checkout; and `git-pre-commit-pii.mode`, read first by `core/hooks/git-pre-commit-pii.sh`, then its legacy and `.claude/hooks/` rungs | code |
| S-32 | Operator methodology packs | Undecided | Decided by the consumer-routing card: Working state in a `/local-state/` subfolder, as configuration read while operating the repository, or Tool-owned beside the platform's per-user configuration, as operator configuration | `pmo_instance_path` — `packs/`, read by deploy Check 51 and the release-velocity tool | code |
| S-33 | Project-key scan list | Leak-risk | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/`, beside S-08 | The `PMO_PROJECT_KEYS` override, else `pmo_instance_path` — `project-keys.txt`, read by deploy Check 25's DC3 pass | code |
| S-34 | Hook runtime logs and state: the hooks' logs, their JSONL records and their session-retro state | Undecided | Decided by the consumer-routing card: Tool-owned beside the deployed hooks, or Working state, install-scoped, because the logs record the working folder of every session on the install. A checkout's copies — written when hooks run from a checkout, and the hook-suite layout `core/hooks/tests/setup-ci-layout.sh` materializes at a checkout root — are engineering and test byproducts kept out of git by the checkout's ignore rules, never a home | The deployed hooks' own folder; in a checkout, `.claude/hooks/` and the runtime files beside the hook sources in `core/hooks/` | code |
| S-35 | Skill-editor session sentinels | Working state | Beside the skill each one unlocks, where the skill-edit hook reads it — a per-session marker with a time limit, not a registered home. Whether it moves under `/local-state/` is decided by the consumer-routing card, which changes the hook and the minter together | `<skill-dir>/.editor-session`, minted by `core/deploy/tools/start-skill-editor-session.sh` | code |
| S-36 | Skill iteration workspaces | Working state | `<module>/skills/<skill>-workspace/`, as `core/standards/skill-workspace-location.md` sets — an in-repo git-ignored path that is not a registered home. Whether it is registered or moves under `/local-state/` is decided by the worktree-sessions slice | The skill-creation and skill-refinement tools write it beside the skill | code |
| S-37 | Cross-module audit output | Working state | Decided by the audit-output card: `/analysis/` or a `/local-state/` subfolder | `audit-output/` at the checkout root, the default output of `core/deploy/tools/cross-module-audit.sh` | code |
| S-38 | The usage store's prior-unit store, preserved once at a counting-unit boundary in a `prior/` directory under the store (`prior/schema-<old>/usage.jsonl`), with its ignore rule | Working state, install-scoped | Beside S-06's store, in the install-scoped telemetry home | `<OPERATOR_INSTANCE_FINOPS_STORE_PATH>`, under `prior/`; ignored by the rule the release-usage-measured-right release adds for it | design |
| S-39 | Operator-touchpoint inventory and phase-out plan: the operator-local instance of `core/schemas/touchpoint-phaseout-schema.md` | Working state | `/roadmaps/`, beside the roadmap instances, or a `/local-state/` subfolder, decided by the consumer-routing card's change | `pmo_instance_path` — `touchpoint-inventory.md` in today's container, then its `governance/roadmaps/` and `roadmaps/` subpaths, read by deploy Check 40 | code |
| S-40 | Pre-update copy of today's container, taken by the update path before it runs | Leak-risk | Decided by the install-and-update card: inside the leak-risk home at its permission policy, or split along the class line; never the workspace root once today's container is retired | `${CLAUDE_WORKSPACE_ROOT}/.backup-pre-update-instance-<ts>/`, written by `update.sh` from `pmo_instance_path_for` | code |
| S-41 | Pre-update and tamper copies taken by the update path and the installer: the charter, the settings, retired hook-tier files, and every composition-surface target the update path regenerates or finds tampered — the hook-tier and instance-tier allowlists and the hub-state template copies among them | Working state | Decided by the install-and-update card: the whole folder in the most protective class it holds — Working state, as S-07's allowlists and S-02's template copies are, and Leak-risk while it holds an allowlist copy that carries an operator identifier — or split along the class line, each copy beside what it copies and in that surface's class, the charter, the settings and the hook-tier files Tool-owned | `${CLAUDE_WORKSPACE_ROOT}/.backup-pre-update-<ts>/`, written by `update.sh` and `docs/scripts/setup-workspace.sh`; and `${CLAUDE_WORKSPACE_ROOT}/.backup-tampered-<ts>/`, written by the same two on a tamper or unparseable-settings regeneration | code |
| S-42 | Install-validation artifacts, written by the install validator for each run | Undecided | Decided by the install-and-update card: Working state, install-scoped, as records of one install's validation run, or Tool-owned beside the installer | `${CLAUDE_WORKSPACE_ROOT}/.workspace-validation/<ts>/`, written by `docs/scripts/validate-install.sh` | code |
| S-43 | Per-workspace operator configuration override, created by the operator and read by the installer and the update path ahead of the per-user configuration | Tool-owned | `${CLAUDE_WORKSPACE_ROOT}/operator.local.toml`, beside the workspace it overrides, as the charter's row sits; the platform never writes it | `${CLAUDE_WORKSPACE_ROOT}/operator.local.toml`, read by `docs/scripts/setup-workspace.sh` and `update.sh` | code |
| S-44 | Hook-tier allowlists the installer provisions into the workspace's agent-config root, named by role — the twelve the composition manifest's hook tier holds today: the eight security-hook allowlists, the reference-durability allowlist the fragile-reference hook reads, the orphan-state cleanup tool's protect list, and the two escape lists deploy Checks 25 and 26 read | Undecided | Decided by the consumer-routing card, for the twelve together or split along their roles: Tool-owned beside the deployed hooks, as S-25's mode files and settings are, or classed per instance as S-07's allowlist instances are, the identifier check reading each installed copy with its tokens resolved | `${CLAUDE_WORKSPACE_ROOT}/.claude/<basename>`, provisioned by the composition manifest's hook tier: `egress-allowlist.txt`, `fs-boundary-allowlist.txt`, `script-execution-allowlist.txt`, `webfetch-allowlist.txt`, `ssh-allowlist.txt`, `mcp-write-allowlist.txt`, `shell-injection-allowlist.txt` and `scope-segregation-allowlist.txt`; `reference-durability-allowlist.txt`; `cleanup-protect-list.txt`; and `skip-localized-context-check.txt` and `skip-release-note-check.txt`, which Checks 25 and 26 open under the checkout's `.claude/` | code |
| S-45 | The private-source pattern file of the process-catalog register check, and its digest file | Leak-risk | `${XDG_DATA_HOME:-$HOME/.local/share}/pmo-platform/pmo-private/`, beside S-08 | The `--private-pattern-file` and `--pattern-digest-file` arguments of the register check; no path token. The holder places both files by hand in the leak-risk home until that home is provisioned | design |
| S-46 | Process-catalog figures: what each registered catalog measure reports on this install — one output file per measure and an index, written by the catalog generator's overlay command | Working state | `/local-state/process-catalog/`. Every measure registered in `core/process-catalog/definitions/measures.tsv` reads tracked files, this repository's host records, or this repository's own working state, and receives them from the generator; that register's input-class column admits no other class. A figure computed from the pipeline event log counts only rows whose release key is a milestone title or a tag name on this repository's host, so § The admission test admits it under its derived-row clause | The generator's `--overlay-root` argument, which has no default; no path token. The folder is made by the operator of the main checkout until install provisions it. The command refuses a root in a linked worktree, and a run from a linked worktree is refused this folder, because no session writes `/local-state/` in the main checkout until it joins the carve-out's static set | design |

**Not registered.** Build and editor artifacts — language caches, build output, operating-system and editor metadata — are not platform data. A stray-copy backstop pattern in `.gitignore` that blocks a copy of a registered surface anywhere in the tree — for the scan lists, the roster, the usage store or the operator configuration — is part of that surface's protection, not a surface of its own.

## New-surface checklist

**When a change introduces a new kind of non-tracked platform data — a writer for a path that no row of § Surface register names, a new resolver function or path token, or a new subfolder of a registered home — or moves an existing surface to another home, that change carries all five steps below and records them in the surface register.** A surface that skips a step has no governed home, and that is how today's container grew by default.

**Runner:** NONE — a registered named gap in the gate-coverage register of `core/standards/gate-efficacy-standard.md`. The new-surface check that fails a surface missing any step is built by the install-provisions-every-home milestone (§ References). Until it ships, the declared observable is a change that adds a non-tracked writer path, a resolver function, a path token or a home subfolder and adds no register row; the reviewer of that change reads it.

### Step 1 — Classify

Apply § Classifying a surface. For a surface proposed for an in-repo home, apply § The admission test; for an embargoed run or an allowlist instance, classify the instance (§ Classes decided per instance). The class goes into the surface's register row, with a short reason wherever the class is not plain from the surface's name.

### Step 2 — Register

Add the surface's row to § Surface register, or update it for a move, with its class, governed home, today's pointer and source. When the surface is reached through a path token, the same change adds the token's row to the token registry, `core/standards/depersonalization-spec.md` § Operator-instance path tokens, with its Class cell, together with the token's `[paths]` override key in `core/config/operator.toml.template` and its declaration in `core/config/operator-toml-schema.json`; the registry legs of `core/deploy/tools/check-operator-toml-schema.sh` already require those three to land together. A new token is named by § Path-token naming rule. A new subfolder of a registered home is a register row of its own.

### Step 3 — Provision

The installer and the update path create the home, create-once and dry-run-aware. An in-repo home ships its folder and README with the repository, per § The folder-plus-README-tracked idiom, and receives its subfolders at install; a per-user home is created at its class's permission policy. No writer creates its own home on first write.

### Step 4 — Protect

Apply the class's protection from § Protections: for an in-repo home, the idiom's ignore-rule pair, the commit guard's coverage and the carve-out hook's static set, changed in the same change as the § Registered in-repo git-ignored homes table; for the leak-risk home, the permission policy and the work-tree refusal. Operator PMO content is protected by never being admitted to a repository; a tool-owned surface keeps its owning tool's protection.

### Step 5 — Validate

Show three things: the home exists where the register says; its protection holds; and every writer and every reader of the surface resolves to the registered home through its class's resolver. The install validator and the new-surface check do this mechanically once they exist; until then the change records the reads it performed.

## Path-token naming rule

**A path token added to the token registry states its class in its name.** Its stem — the part after the `OPERATOR_INSTANCE_` family prefix — opens with the class segment:

| Class | Class segment |
|---|---|
| Working state | `WORKING_STATE` |
| Working state, install-scoped | `INSTALL_STATE` |
| Leak-risk | `LEAK_RISK` |
| Operator PMO content | `PMO_CONTENT` |
| Tool-owned | `TOOL_OWNED` |

No segment is a prefix of another, so a token's class reads unambiguously from its name. The rest of the stem names the surface, and the suffix follows the registry's own stem rule. Written without its angle brackets, an illustrative token for the close-out registers reads `OPERATOR_INSTANCE_WORKING_STATE_REGISTERS_PATH`; it is an example of the form, not a registered token. Its `[paths]` override key is the token lowercased, as the registry already requires.

**A surface classed per instance gets one token per class it can take**, and the resolver's class argument picks between them, so no token's name is wrong for part of what it resolves. **On a reclassification the Class column governs**, and the token is superseded through the registry — a new row, with the old one retired — rather than renamed in place.

**The class rides inside the registered family prefix.** The registry gate and the registry legs of the schema check derive the token families they can see from the registry's own rows, so a token in a family no row registers yet is invisible to both until its first row lands. A new token inside the registered family is within both checks' reach from its first use.

**A registered token is not renamed to satisfy this rule.** A rename cascades through every consumer, and the registry's Class column already states the class of every row whatever its name. A token for a tracked surface takes no class segment; its Class cell names which tracked kind it is. An `Undecided` surface takes no token until its class is decided.

## The token registry's Class column

The token registry in `core/standards/depersonalization-spec.md` § Operator-instance path tokens carries a **Class** column, the last cell of each row: the class of the data the token resolves to, in this standard's closed class vocabulary. The class belongs to the data, not to today's path, so it holds across a repository's cutover while the token's canonical default changes.

**This standard's register is the authority.** Every registered token appears in the **Resolves today through** cell of the register row for its surface, and the registry's Class cell repeats that row's class. Where the two disagree, the register is right and the registry is corrected. The column sits to the right of the token cell because the registry's readers — the conformance gate and the registry legs of the schema check — read the first cell of each row only.

## References

- #8005 — the parent epic. Its fit/gap section, with its proposed-class table for the entries the fit/gap left open, as the body stood after its 2026-10-27 revision, is the population the register's `fit/gap` rows come from; its epic-level design is the class table this standard operates.
- #8016 — the superseding decision record's work item: the classes, the per-user homes, the main-checkout carve-out and the switch.
- #6627 — the release-corpus location decision and the `corpus_home` selector.
- #8017 — this standard's work item.
- #8029 — the new-surface check: it fails a non-tracked surface that skips a checklist step, it replaces this standard's named-gap runner, and it co-owns the parity check between § Registered in-repo git-ignored homes and the carve-out hook's static set. It is built in the install-provisions-every-home milestone, wave 4 of the parent epic.
- #8019 — the worktree-sessions slice: the main-checkout rule and its hook, which admit writes only inside § Registered in-repo git-ignored homes; co-owner of that parity check, and owner of S-36's home.
- #8020 — the resolver slice: one resolver per class, the switch, the work-tree refusal and the designated main checkout.
- #8022 — `/local-state/` with its README and ignore rule, and the commit guard over the in-repo homes.
- #8023 — the tree-walk exclusion of the in-repo homes.
- #8024 — the leak-risk permission policy, set at install and checked.
- #8025 — the consumer-routing card: routes the deploy, install and hook consumers of non-tracked data through the resolver, and decides S-31's subfolder, S-32's, S-34's and S-44's class, S-35's home and S-39's home.
- #8027 — install and update provision every home, and decides S-40's, S-41's and S-42's homes.
- #8032 — leak-risk content moved into the leak-risk home, embargoed runs included.
- #7502 — the audit-output card: the review deliverables' output home, which decides S-37's home.
- #7937 — the usage-store card whose design decision D-3, rendered in its `prior/` form, S-38 registers.

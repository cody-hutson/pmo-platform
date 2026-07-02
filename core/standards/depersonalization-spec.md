---
title: Depersonalization Spec
purpose: Defines the operator-identity token vocabulary and the parameterization seam through which operator-instance values resolve at workspace-setup time. Composes with (does NOT restate) universal-vs-localized-context.md.
type: standard
status: ACTIVE
consumers: "the repo-integrity depersonalization gate (repo-integrity.yml — forbids the operator-identity values this spec catalogs in tracked core/release/operations/packages files); workspace-setup token resolution (resolves [OPERATOR_*] tokens to operator-instance values); every tokenized corpus + template file (carries the [OPERATOR_*] vocabulary this spec defines)"
composes_with: [universal-vs-localized-context.md, knowledge-architecture.md]
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->

# Depersonalization Spec

## Purpose

This standard defines the operator-identity token vocabulary and the parameterization seam through which operator-instance values resolve at workspace-setup time. It exists so platform code, hooks, skills, and documentation can be authored against tokens (`[OPERATOR_NAME]`, `[CLAUDE_WORKSPACE_ROOT]`, …) rather than literal operator values.

This spec is the **inheritance document** for the depersonalization stack. It enumerates:

1. The operator-identity token set.
2. The parameterization seam location.
3. The workspace-setup mechanism dependency.

The standard does **not** define the universality axis, the parameterization seam principle, or the leakage rubric — those are owned by [`universal-vs-localized-context.md`](universal-vs-localized-context.md) and [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md).

---

## §1 Token set

The token vocabulary is:

| Token | Resolves to | Source-of-truth | Used in |
|---|---|---|---|
| `[OPERATOR_NAME]` | Workspace owner's full name | `/CLAUDE.md § Workspace Owner` | Doc prose, frontmatter `owner:`, signature blocks |
| `[OPERATOR_ROLE_TITLE]` | Workspace owner's role title | `/CLAUDE.md § Workspace Owner` | Signature blocks, person-role-tied prose |
| `[OPERATOR_ORGANIZATION]` | Workspace owner's organization | `/CLAUDE.md § Workspace Owner` | Doc prose where org name appears |
| `[OPERATOR_EMAIL]` | Workspace owner's email | `/CLAUDE.md § Workspace Owner` | Signature blocks, contact-line prose |
| `[OPERATOR_PHONE]` | Workspace owner's phone | `/CLAUDE.md § Workspace Owner` | Signature blocks (PII-adjacent — strongest depersonalization candidate) |
| `[OPERATOR_GITHUB]` | Workspace owner's GitHub handle | `/CLAUDE.md § Workspace Owner` OR `git config user.name` | Doc prose where GitHub handle appears |
| `[OPERATOR_GIT_EMAIL]` | Git config email (may differ from above) | `git config user.email` | Doc prose where commit-attribution email appears |
| `[OPERATOR_HOMEDIR_PATH]` | Operator's POSIX home directory path | `$HOME` at workspace-setup time | `~/Library/Application Support/...` references, doc prose paths |
| `[CLAUDE_WORKSPACE_ROOT]` | Claude workspace root path | Operator config at setup | Workspace-root references in load-bearing hooks/config |
| `[PMO_PLATFORM_ROOT]` | pmo-platform repo root (where deploy + release scripts live) | Deploy-time resolution in `core/deploy/compose.py` (NOT operator.toml) | Absolute-path entries in load-bearing hook allowlists (e.g. `script-execution-allowlist.txt`) |
| `[COWORK_INSTALL_PATH_BASE]` | Cowork install path base | Operator config at setup | `~/Library/Application Support/Claude/local-agent-mode-sessions/...` references |
| `[OPERATOR_PROJECT_NAME]` | First active K4 project name (informational only) | `projects/<Project>/PROJECT.md` discovery | K4-leak references in K1 docs |

**Token rendering convention:** square-bracket bare tokens (no `${}`, no `{{}}`) — disambiguates from existing `{{PLACEHOLDER}}` template syntax used by project-initiator and from `$ENV_VAR` shell substitution. Tokens render as text in markdown; they are NOT auto-substituted at read-time. Resolution is the workspace-setup spoke's job.

### §1.1 GitHub Projects board tokens

The GitHub Projects (v2) board identifiers used in `core/disciplines/github-projects-guide.md` and the pipeline references. Source-of-truth: `~/.config/pmo-platform/operator.toml` `[projects]` (operator-instance; obtain once via `gh project field-list --owner <handle> --number <n> --format json`, then record under `[projects]`). Same rendering convention as §1 — square-bracket, render-as-is, not auto-substituted (no code consumes them today; `[projects]` is the operator's canonical record of the IDs for when a consumer needs them).

| Token | Resolves to | Source-of-truth (`operator.toml [projects]`) | Used in |
|---|---|---|---|
| `[OPERATOR_GITHUB_PROJECT_URL]` | The board's web URL | `[projects].board_url` | github-projects-guide.md header |
| `[OPERATOR_PROJECT_NODE_ID]` | Project GraphQL node ID (`PVT_…`) | `[projects].node_id` | `gh project item-edit --project-id` commands |
| `[OPERATOR_PROJECTS_STATUS_FIELD_ID]` | Status single-select field ID | `[projects].status_field_id` | `--field-id` in status-transition commands |
| `[OPERATOR_PROJECTS_STAGE_FIELD_ID]` | Stage single-select field ID | `[projects].stage_field_id` | `--field-id` in stage-transition commands |
| `[OPERATOR_PROJECTS_VIEW_FIELD_ID]` | Priority field ID (the token name says `VIEW` for backward-compat; it resolves the **Priority** field — registered as-is to avoid a multi-file rename cascade) | `[projects].priority_field_id` | `--field-id` in priority-set commands |
| `[OPERATOR_PROJECTS_DATE_FIELD_ID]` | Decision Date field ID | `[projects].decision_date_field_id` | `--field-id` in decision-date commands |

The single-select **option** IDs (the 8-char hex literals in example commands) are NOT tokenized — preserved literally for traceability per github-projects-guide.md.

### §1.2 ADR `deciders:` carve-out

The operator's **literal name** is permitted in the `deciders:` frontmatter field of an ADR file (`core/ADRs/**`, `release/ADRs/**`) — and there only. This is sanctioned architect-of-record authorship attribution on a repo the operator owns; the name is already public via `LICENSE` and git history (operator decision 2026-06-20). The `[OPERATOR_NAME]` token remains the sanctioned representation everywhere else.

**Explicitly still blocked** (the carve-out does NOT loosen these): the operator email and any PII-adjacent value; home/workspace paths; the GitHub handle **on any non-`deciders` line or non-ADR file**; the operator name in any ADR **body** line (only the frontmatter `deciders:` field is exempt); the operator name in **any non-ADR file** under `core/`/`release/`/`operations/`/`packages/`; and the entire **collaborator** dimension. Enforced by the field-scoped skip in the `repo-integrity.yml` depersonalization gate — the skip fires iff the changed file is an ADR (`core/ADRs/*.md` or `release/ADRs/*.md`) **AND** the added line matches `^deciders:` (both ANDed). Exempted lines are reported in the run summary (via the same `SUPPRESSED` channel as the line-scoped override), so the exemption is auditable, not silent.

---

## §2 Parameterization seam location

The parameterization seam lives at:

- **Read-source for `[OPERATOR_*]` tokens:** `~/.config/pmo-platform/operator.toml` (canonical, XDG-spec) with optional per-workspace override at `<workspace>/operator.local.toml`. Resolution order: operator.local.toml > operator.toml > template defaults. Documented surface form: `/CLAUDE.md § Workspace Owner` (the K3 parameter home per `universal-vs-localized-context.md § 4(b)`) is the human-readable view of the same values.
- **Read-source for `[CLAUDE_WORKSPACE_ROOT]` token:** `~/.config/pmo-platform/operator.toml` `[paths].claude_workspace_root` field, created at workspace-setup time. Default fallback: `$HOME/Claude`.
- **Read-source for `[PMO_PLATFORM_ROOT]` token:** resolved at deploy time by `core/deploy/compose.py`, NOT from operator.toml. Precedence: `--repo-root` CLI flag > `$PMO_PLATFORM_ROOT` env > compose.py self-location (`Path(__file__).resolve().parents[2]`). Self-location is always the repo root being composed (compose.py is never copied out of the repo), so the token cannot survive unsubstituted into a deployed file. This token is distinct from `[CLAUDE_WORKSPACE_ROOT]`: the repo MAY live anywhere (a clone, a sibling dev checkout), not necessarily directly under the workspace root.
- **Read-source for `[OPERATOR_HOMEDIR_PATH]` token:** `$HOME` at read-time (no separate config needed).
- **Read-source for `[COWORK_INSTALL_PATH_BASE]` token (Cowork-specific):** discovered at workspace-setup time by scanning `~/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/` for the active session UUID; persisted to `~/.config/pmo-platform/operator.toml` `[paths].cowork_install_path` field.
- **Read-source for `[OPERATOR_PROJECT_NAME]` token:** lazily resolved per K4 surface — read `projects/<Project>/PROJECT.md` at the point the K1 doc is consumed; informational only.

**Resolution mechanism:** the workspace-setup spoke populates `~/.config/pmo-platform/operator.toml` at install time. Consumer skills + hooks + scripts read this canonical config to resolve tokens. The `update.sh` script regenerates resolved files against the current operator.toml on package updates, preserving operator additions per [`composition-surface-spec.md § 3.2`](composition-surface-spec.md). Markdown documentation does NOT auto-resolve tokens — readers see the bracketed token form as-is (acceptable per `universal-vs-localized-context.md § 4(b)` pointer pattern).

---

## §3 Workspace-setup mechanism

The depersonalization stack depends on a workspace-setup mechanism that creates and populates the per-operator config file:

1. Create `~/.config/pmo-platform/operator.toml` (schema: `[meta]`, `[identity]`, `[paths]`, `[platform]` per `core/config/operator.toml.template`). Permissions: `chmod 600` (operator-only read/write).
2. Optionally create `<workspace>/operator.local.toml` for per-workspace overrides; resolution order is operator.local.toml > operator.toml > template defaults.
3. `setup-workspace.sh` script populates the config at install time, prompting for missing values.
4. `update.sh` script regenerates resolved files on package updates per [`composition-surface-spec.md § 3.2`](composition-surface-spec.md).
5. `deploy.sh` reads `[CLAUDE_WORKSPACE_ROOT]` from operator.toml.
6. `.claude/hooks/*.sh` read `[CLAUDE_WORKSPACE_ROOT]` at startup.
7. `.claude/settings.json` is regenerated from `core/settings.json.template` + operator.toml on install and update.
8. `comms-writer` skill reads `[OPERATOR_*]` from `/CLAUDE.md § Workspace Owner` at signature-emission time.
9. `project-initiator` skill resolves `{{OPERATOR_NAME}}` / `{{OPERATOR_ROLE_TITLE}}` placeholders from `/CLAUDE.md § Workspace Owner` at scaffold-time.
10. `core/rules/skill-deployment.md` uses `[COWORK_INSTALL_PATH_BASE]` token.

The implementation lives at `docs/scripts/setup-workspace.sh` per [`docs/workspace-setup.md`](../../docs/workspace-setup.md). Update-time regeneration lives at `update.sh` (repo root) per [`docs/UPDATE.md`](../../docs/UPDATE.md).

---

## §4 Operator-instance path tokens

A parallel-but-distinct angle-bracket convention exists for paths to operator-instance content (per [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) OPERATOR-INSTANCE class). These tokens render as `<OPERATOR_INSTANCE_*_PATH>` (angle brackets, distinct from §1's square-bracket `[OPERATOR_*]` identity tokens) and reference paths that resolve to operator-local locations outside the public-repo source tree.

**Why a separate vocabulary:** Identity tokens (`[OPERATOR_*]`) substitute *values* (operator name, GitHub handle, email). Operator-instance path tokens substitute *paths to artifacts* (release log, hub-state runtime, projects directory). They share the parameterization-seam principle but have different read-sources, different resolution rules, and different consumers — keeping them in separate vocabularies prevents collision and surfaces the semantic distinction at authoring time.

**Resolution rule:** Each `<OPERATOR_INSTANCE_X_PATH>` resolves to either (a) the explicit operator.toml `[paths]` override if set, or (b) the canonical default below. The angle-bracket form renders as-is in markdown documentation; resolution happens in code (deploy.sh, hooks, hub) that reads the operator config.

**Canonical defaults:** All operator-instance paths default to subpaths under `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/`, which is `.gitignored` per the public-repo discipline. The default suffix follows the token stem — `<OPERATOR_INSTANCE_X_PATH>` defaults to `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/<x>/`. Exceptions to this rule (e.g., `<OPERATOR_INSTANCE_CLAUDE_DIR>` → `${CLAUDE_WORKSPACE_ROOT}/.claude`) are documented in the vocabulary table.

**Vocabulary table (incremental — codified as consumers land):**

| Token | Canonical default | operator.toml override field | Codified by |
|---|---|---|---|
| `<OPERATOR_INSTANCE_HUB_STATE_PATH>` | `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/hub-state` | `[paths].operator_instance_hub_state_path` | [`hub-session-continuity.md`](hub-session-continuity.md) §2 + [`public-repo-vs-operator-instance-taxonomy.md`](public-repo-vs-operator-instance-taxonomy.md) §4.3 |
| `<OPERATOR_INSTANCE_ROADMAPS_PATH>` | `${CLAUDE_WORKSPACE_ROOT}/pmo-platform/roadmaps` (the shipped in-repo `/roadmaps/` home — folder + README tracked, instances git-ignored, the `analysis/`-workspace pattern; repointable per deployment) | `[paths].operator_instance_roadmaps_path` | [`initiative-roadmap-framework.md`](initiative-roadmap-framework.md) (in-repo default per [`../ADRs/ADR-046-roadmap-instance-in-repo-home.md`](../ADRs/ADR-046-roadmap-instance-in-repo-home.md), supersedes-in-part the operator-local placement of [`ADR-012`](../ADRs/ADR-012-roadmap-instance-descope.md) + ADR-017) |
| `<OPERATOR_INSTANCE_INBOX_PATH>` | `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/inbox` | `[paths].operator_instance_inbox_path` | [`c1-ambient-inbox-cursor.md`](c1-ambient-inbox-cursor.md) §1 (ambient inbox drop-zone; consumed by the Path A scheduled intake sweep C2) |
| `<OPERATOR_INSTANCE_EXTERNAL_SYNC_SNAPSHOT_PATH>` | `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/external-sync/snapshot.json` | `[paths].operator_instance_external_sync_snapshot_path` | [`c3-external-sync-path-b.md`](c3-external-sync-path-b.md) §3 (Path-B external-sync poll-state snapshot; holds live external IDs/statuses — operator-instance, never git-tracked) |
| `<OPERATOR_INSTANCE_EXTERNAL_SYNC_RUNLOG_PATH>` | `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/external-sync/run-log.jsonl` | `[paths].operator_instance_external_sync_runlog_path` | [`c3-external-sync-path-b.md`](c3-external-sync-path-b.md) §5 (Path-B external-sync run-record; append-only JSONL; the producer side of the C3↔C4 heartbeat contract) |
| `<OPERATOR_INSTANCE_INTAKE_SWEEP_RUNLOG_PATH>` | `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/ambient-intake/run-log.jsonl` | `[paths].operator_instance_intake_sweep_runlog_path` | [`c2-intake-sweep-path-a.md`](c2-intake-sweep-path-a.md) §5 (Path-A intake-sweep run-record; append-only JSONL; field-aligned to the C3 sweep run-record — the producer side of the C2↔C4 heartbeat contract; a distinct file so the two sweeps' records do not interleave) |
| `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>` | `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/evals/results` | `[paths].operator_instance_evals_results_path` | [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) (pipeline event-log writer/reader + release-analytics tools — `append-pipeline-event.sh` / `query-pipeline-event.sh` / `compute-cycle-time.sh` / `synthesize-release-learnings.sh`; two-segment `evals/results` stem documented here per the stem-exception clause above) |

**Convention scope:** Other angle-bracket tokens currently in use across the corpus (`<OPERATOR_INSTANCE_LOG_PATH>`, `<OPERATOR_INSTANCE_RELEASES_PLANS_PATH>`, etc. — see `grep -rohE "<OPERATOR_INSTANCE_[A-Z_]+>" --include="*.md" .` for the current set) inherit the same resolution-rule convention even when not yet codified in the table above. Codification is incremental — when a token's consumer (skill, hook, script) lands or changes, the token's row is added to the vocabulary table. Authoring NEW angle-bracket tokens MUST add a row to this table in the same PR.

**Read-source contract:** The `[paths].operator_instance_*` override fields in `~/.config/pmo-platform/operator.toml` are read at workspace-setup time and at runtime by consumer code. Empty string (the template default) → resolve via the canonical default. Non-empty string → use the override verbatim.

---

## §5 Boundaries

Compose, do not restate. Each row names a doc this standard touches and the action taken.

| Boundary | Relationship | Action |
|---|---|---|
| [`universal-vs-localized-context.md`](universal-vs-localized-context.md) | Owns the DC1-DC4 audit dimensions + § 6 disposition rubric. | **Cite only.** This spec consumes DC1-DC4 + the 4-class rubric verbatim. |
| [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | Owns the K1-K5 tier classifier + parameterization seam principle. | **Cite only.** § 1 token set is keyed to the K1↔K2/K3 seam. |
| [`duplicate-source-discipline.md`](duplicate-source-discipline.md) | Register-or-remove. The reason this spec cites the upstream standards instead of restating them. | Comply. |

---

## §6 Audit method — extract binary archives before scanning

A depersonalization (or PII) audit MUST extract and scan the contents of binary archives, not just the source tree around them. `git grep` and any plain-text scan read compressed archives as opaque bytes: a `.skill` package, `.zip`, or other archived artifact that embeds an operator value passes a text scan as a **false clean**, because the identifying string is inside the compressed payload and never matched.

The audit is incomplete until every archived artifact has been (a) extracted to a scratch location, (b) scanned for the full token set in §1 plus any PII categories in scope, and (c) confirmed to have been built freshly from already-scrubbed source. A package built before its source was scrubbed can still carry the old values even though the source tree reads clean — so "the source grep is clean" does not certify the artifacts. Re-build from scrubbed source, then extract-and-scan the rebuilt artifact, before declaring the surface clean.

This composes with the leakage rubric owned by [`universal-vs-localized-context.md`](universal-vs-localized-context.md) (the rubric defines *what* is a leak; this section defines the *extraction step* an archive-bearing audit must add so the rubric is actually applied to compressed content).

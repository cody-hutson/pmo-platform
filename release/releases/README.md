# release/releases/ — release-corpus scaffolding

This directory is the **public scaffolding** for the release corpus. Per [ADR-032](../../core/ADRs/ADR-032-release-corpus-public-vs-instance-split.md), the per-release CONTENT (the filled `RELEASE_LOG`/`RELEASE_INDEX`/`RELEASE_DIGEST`/`RELEASE_REVERSIONS` + `plans/` + `notes/`) is operator-instance and lives out-of-tree at `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/` (git-ignored). What ships tracked here is the corpus *shape* — this README, the `hub-state/*.template` schemas, and an empty `RELEASE_INDEX.md` seed — so a cloner sees the contract without the maintainer's narrative. The concise public release surface is the root `CHANGELOG.md`.

## Layout (where each artifact lives)

| Artifact | Home (post-ADR-032) | Authored by | Spec |
|---|---|---|---|
| `plans/vX.Y_RELEASE_PLAN.md` — per-release dependency graph, implementation sequence, contention map, risk register, stage applicability matrix | **operator-instance** `<instance>/releases/plans/` (git-ignored) | Stage 4 release-planning spoke (committed as Engineering Commit 0 under D-C SINGLE topology, or via Stage 4 release-plan chore PR under D-C OPTION-A topology) | `../references/how-to/hub-spoke-bridge.md` § Procedure 0 |
| [`hub-state/`](hub-state/) | tracked templates here; runtime instance out-of-tree | Hub at session start (Procedure 0b) and at each routing decision | `../../core/standards/hub-session-continuity.md` |
| `notes/vX.Y_RELEASE_NOTES.md` — user-facing release notes (9-section format) | **operator-instance** `<instance>/releases/notes/` (git-ignored) | Stage 13 close spoke | `../references/standards/release-notes-standard.md` |

## Release-corpus files (operator-instance content, NOT tracked here)

These files are appended/edited at the corpus level. Per ADR-032 they live at the operator-instance corpus root (`<instance>/releases/`), git-ignored — NOT in this tracked directory:

- `RELEASE_LOG.md` — per-release append log (state = `DEPLOYED` → `VERIFIED`); created on first release at Stage 12 Phase B5 chore PR
- `RELEASE_INDEX.md` — corpus-level index of all releases; appended at Stage 13 (an empty public seed IS tracked here for shape)
- `RELEASE_DIGEST.md` — corpus-level digest grouped by version family; appended at Stage 13
- `RELEASE_REVERSIONS.md` — machine-readable re-version ledger; appended only when a release re-versioned mid-pipeline

`install.sh` lays down the empty instance corpus skeleton on install; the first local release's Stage 13 populates it. The Stage 12 / Stage 13 chore-PR mechanism (per [`../references/pipeline/stage-12-execute.md`](../references/pipeline/stage-12-execute.md) and [`../references/pipeline/stage-13-close.md`](../references/pipeline/stage-13-close.md)) writes the corpus to the instance and the tracked `CHANGELOG.md` + `.version` to the chore PR.

## Why these directories are pre-created

The bridge and pipeline shards cite paths under `release/releases/`. Pre-creating the directories (each with a README) ensures:

- Operators cloning the repo can read the runtime contract before running a release
- Stage 4 spokes do not need a `mkdir -p` step in the spoke prompt
- Verification commands (e.g., the Stage 13 completion-verification block in `hub-spoke-bridge.md` Procedure 7 Step 4) have stable paths to test against

## Classification

Artifacts under `release/releases/` split across two of the three taxonomy classes per [`../../core/standards/public-repo-vs-operator-instance-taxonomy.md`](../../core/standards/public-repo-vs-operator-instance-taxonomy.md). The apply test ("does any participant outside the originating operator's session need to read this?") returns different answers per subdirectory:

| Artifact | Class | Apply-test answer | What ships in pmo-platform |
|---|---|---|---|
| `plans/` content | **OPERATOR-INSTANCE** (ADR-032) | Cross-session within the originating operator; the maintainer's per-release planning narrative is not shipped to cloners | NOTHING tracked — the plan file lives at `<instance>/releases/plans/vX.Y_RELEASE_PLAN.md` (git-ignored) |
| `notes/` content | **OPERATOR-INSTANCE** (ADR-032); the public projection is `CHANGELOG.md` | The filled note is instance-side; its public projection is the root `CHANGELOG.md` (the §5.3 transform at Stage 13) + the Stage 12 GitHub Release body | NOTHING tracked here — the note lives at `<instance>/releases/notes/vX.Y_RELEASE_NOTES.md` (git-ignored); `CHANGELOG.md` at repo root is the tracked public surface |
| [`hub-state/`](hub-state/) | **CUSTOMIZABLE-PUBLIC** (template) + **OPERATOR-INSTANCE** (runtime instance) | Templates: YES (operators need the schema to seed first emit). Runtime instance: NO (read only by the same operator's hub across sessions; mutates dozens of times per release) | Schema templates (`pending-approvals.md.template`, `action-items.md.template`, `sessions.md.template`) — git-tracked. Runtime instance lives at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/*` — NOT git-tracked |

Per ADR-032, plans and notes are operator-instance CONTENT — the capability (templates, schema, pipeline, the empty `RELEASE_INDEX` seed, this README) ships; the maintainer's filled per-release content instances out-of-tree. A fresh clone gets the corpus shape without the narrative. Hub-state runtime is likewise operator-local; the schema ships as a template so operators can install / lazy-init their runtime instance.

Operator-instance state (per-machine session logs, secrets, operator-customized config, hub-state runtime instance) lives at operator-local paths per [`../../core/standards/public-repo-gitignore-template.md`](../../core/standards/public-repo-gitignore-template.md) + [`../../core/standards/secrets-handling-policy.md`](../../core/standards/secrets-handling-policy.md). The classifications are exhaustive — every artifact maps to exactly one class.

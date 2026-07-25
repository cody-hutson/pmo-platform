# release/releases/ — runtime release artifacts

This directory holds per-release artifacts produced by the hub-and-spoke pipeline at runtime. Subdirectories are pre-created so file paths cited in [`../references/how-to/hub-spoke-bridge.md`](../references/how-to/hub-spoke-bridge.md), [`../governance/release-process.md`](../governance/release-process.md), and the per-stage pipeline shards under [`../references/pipeline/`](../references/pipeline/) resolve cleanly during a release.

## Layout

| Subdirectory | Contents | Authored by | Spec |
|---|---|---|---|
| [`plans/`](plans/) | `vX.Y_RELEASE_PLAN.md` — per-release dependency graph, implementation sequence, contention map, risk register, stage applicability matrix | Stage 4 release-planning spoke (committed as Engineering Commit 0 under D-C SINGLE topology, or via Stage 4 release-plan chore PR under D-C OPTION-A topology) | `../references/how-to/hub-spoke-bridge.md` § Procedure 0 |
| [`hub-state/`](hub-state/) | `vX.Y/` substrate — `pending-approvals.md`, `sessions.md` (optional), per-release session continuity state | Hub at session start (Procedure 0b) and at each routing decision | `../../core/standards/hub-session-continuity.md` |
| [`notes/`](notes/) | `vX.Y_RELEASE_NOTES.md` — user-facing release notes (9-section format) | Stage 13 close spoke | `../references/standards/release-notes-standard.md` |

## Release-corpus files (committed at the directory root, not in subdirs)

These files are also referenced by the pipeline but are appended/edited at the corpus level rather than authored fresh per release:

- `RELEASE_LOG.md` — per-release append log (state = `DEPLOYED` → `VERIFIED`); created on first release at Stage 12 Phase B5 chore PR
- `RELEASE_INDEX.md` — corpus-level index of all releases; appended at Stage 13 chore PR
- `RELEASE_DIGEST.md` — corpus-level digest grouped by version family; appended at Stage 13 chore PR

These files do not exist until the first release runs. The Stage 12 / Stage 13 chore-PR mechanism (per [`../references/pipeline/stage-12-execute.md`](../references/pipeline/stage-12-execute.md) and [`../references/pipeline/stage-13-close.md`](../references/pipeline/stage-13-close.md)) creates them on first use.

## Why these directories are pre-created

The bridge and pipeline shards cite paths under `release/releases/`. Pre-creating the directories (each with a README) ensures:

- Operators cloning the repo can read the runtime contract before running a release
- Stage 4 spokes do not need a `mkdir -p` step in the spoke prompt
- Verification commands (e.g., the Stage 13 completion-verification block in `hub-spoke-bridge.md` Procedure 7 Step 4) have stable paths to test against

## Classification

Artifacts under `release/releases/` split across two of the three taxonomy classes per [`../../core/standards/public-repo-vs-operator-instance-taxonomy.md`](../../core/standards/public-repo-vs-operator-instance-taxonomy.md). The apply test ("does any participant outside the originating operator's session need to read this?") returns different answers per subdirectory:

| Subdirectory | Class | Apply-test answer | What ships in pmo-platform |
|---|---|---|---|
| [`plans/`](plans/) | **UNIVERSAL-PUBLIC** | YES — every per-issue Stage 5/6/7/8 spoke; hub on session resume; future operators auditing what was planned | The plan file (`vX.Y_RELEASE_PLAN.md`) — git-tracked verbatim |
| [`notes/`](notes/) | **UNIVERSAL-PUBLIC** | YES — `gh release create --notes-file` at Stage 12 Phase B5.5; the §5.3 transform that produces `CHANGELOG.md` at Stage 13; future operators reading historical notes | The notes file (`vX.Y_RELEASE_NOTES.md`) — git-tracked verbatim |
| [`hub-state/`](hub-state/) | **CUSTOMIZABLE-PUBLIC** (template) + **OPERATOR-INSTANCE** (runtime instance) | Templates: YES (operators need the schema to seed first emit). Runtime instance: NO (read only by the same operator's hub across sessions; mutates dozens of times per release) | Schema templates (`pending-approvals.md.template`, `action-items.md.template`, `sessions.md.template`) — git-tracked. Runtime instance lives at `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/*` — NOT git-tracked |

Plans and notes are git-tracked because every participant outside the originating session needs them — they are the **shared pipeline substrate**, not a "fallback for non-git users." Hub-state runtime is operator-local because tracking it would produce dozens of micro-commits per release for state with no cross-operator readership benefit; the schema ships as a template so operators can install / lazy-init their runtime instance.

Operator-instance state (per-machine session logs, secrets, operator-customized config, hub-state runtime instance) lives at operator-local paths per [`../../core/standards/public-repo-gitignore-template.md`](../../core/standards/public-repo-gitignore-template.md) + [`../../core/standards/secrets-handling-policy.md`](../../core/standards/secrets-handling-policy.md). The classifications are exhaustive — every artifact maps to exactly one class.

## Related References

- [`../../docs/release-record-keeping.md`](../../docs/release-record-keeping.md) — human-process design artifact that depicts this directory's per-surface (plans / notes / hub-state) classification when walking an operator through tracing a release record.

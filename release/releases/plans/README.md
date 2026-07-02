# release/releases/plans/ — release plan files

Per-release Stage 4 release plans live here, one file per release: `vX.Y_RELEASE_PLAN.md`.

## File naming

`vX.Y_RELEASE_PLAN.md` where `vX.Y` is the release version matching the GitHub Milestone slug suffix (e.g., `v1.0_RELEASE_PLAN.md` for Milestone `v1.0-initial`).

## Directory layout — major-version subfolders

Plan files are organized into **per-major-version subfolders**, not stored flat. The same scheme applies to `../notes/`. This keeps each directory scannable as the corpus grows.

```
plans/
├── README.md            ← this file (stays at top level)
├── v1/                  ← every v1.x release plan
├── v2/                  ← every v2.x release plan
├── v3/                  ← every v3.x release plan
└── _unversioned/        ← version-less-by-design plans (see disposition rule)
```

Only `README.md` lives at the top level. New releases file their plan under the subfolder for their major version (`plans/v<MAJOR>/vX.Y_RELEASE_PLAN.md`).

### Disposition rule (which subfolder a file belongs to)

Every plan and note resolves to exactly one subfolder by this rule, applied in order:

1. **Version-prefixed filename** (`vX.Y…_RELEASE_PLAN.md`) → `v<MAJOR>/` taken from the filename's major (`v3.45…` → `v3/`).
2. **Version-less filename** (milestone-number-prefixed like `22-ticket-information-architecture_RELEASE_PLAN.md`, or theme-named like `architecture-altitude-discipline_RELEASE_PLAN.md`) — the version binds only at the Stage 12 atomic claim, so these files carry no version stem. Resolve the **shipping release's major** by matching the filename's milestone/theme slug against its row in [`../RELEASE_LOG.md`](../RELEASE_LOG.md):
   - If the slug appears in a **version-keyed** LOG row (e.g. `22-ticket-information-architecture` is the Milestone cell of the `v2.27` row) → file under that major (`v2/`).
   - If the slug appears only in a **version-less LOG row** (the release shipped VERIFIED with Tag `(none)` and never claimed a version) → file under `_unversioned/`.

`_unversioned/` is the single bucket for genuinely version-less releases; no plan or note is ever stranded at the top level. When a version-less release is later assigned a version, move its plan/note from `_unversioned/` into the matching `v<MAJOR>/` subfolder with `git mv` and re-run `../../../core/deploy/tools/generate_release_index.py` to refresh the INDEX links.

### Tooling contract

The generators that read this corpus discover files **recursively** (`rglob`), so subfoldering is transparent to them:
- [`../../../core/deploy/tools/generate_release_index.py`](../../../core/deploy/tools/generate_release_index.py) — resolves each note link to its subfoldered path (`notes/v<MAJOR>/…`) when regenerating `../RELEASE_INDEX.md`.
- [`../../../core/deploy/tools/lint_release_corpus.py`](../../../core/deploy/tools/lint_release_corpus.py) — scans all subfolders for filename-compliance, schema, type-coherence, and note-content checks.

The `../RELEASE_LOG.md`, `../RELEASE_DIGEST.md`, and `../RELEASE_INDEX.md` **path pointers** to these files reflect the subfoldered layout. Historical release-plan and release-note bodies retain their as-authored self-referential paths as a frozen record (not rewritten).

## Authoring contract

- **Authored by:** Stage 4 release-planning spoke (Procedure 0 in [`../../references/how-to/hub-spoke-bridge.md`](../../references/how-to/hub-spoke-bridge.md))
- **Committed by:** Determined by the D-C Branch Topology decision gate:
  - **D-C SINGLE topology** (default): Engineering Commit 0 on the release branch
  - **D-C OPTION-A topology** (per-issue branches): Stage 4 release-plan chore PR landing on main BEFORE per-issue sub-task scaffolding
- **Read by:** All per-issue Stage 5/6/7/8 spokes; the hub Procedure 1 scaffolding; the operator at Stage 9 plan review

## Contents per file

Stage 4 spoke produces the plan with these sections (see [`../../references/pipeline/stage-04-planning.md`](../../references/pipeline/stage-04-planning.md) for the full spec):

- Summary (30 seconds)
- Dependency Graph
- Implementation Sequence
- Stage Applicability Matrix
- Contention Map
- Risk Register
- Operator Decisions / D-Gate blocks
- Release Class declaration
- Recommendations

## Classification

**UNIVERSAL-PUBLIC** per [`../../../core/standards/public-repo-vs-operator-instance-taxonomy.md`](../../../core/standards/public-repo-vs-operator-instance-taxonomy.md). Every per-issue Stage 5/6/7/8 spoke session reads the plan to ground its work; spokes run in isolated worktrees and cannot see operator-local files — git is the substrate that makes hub-spoke coordination work.

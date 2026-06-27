# Analysis workspace — repo-scoped, git-ignored

Home for **repo-scoped, read-once analysis** — release analysis, backlog analysis,
audits, reviews, and gap analyses **about the platform itself**. (Project or
other-work-area analysis does not belong here — it lives with its project/work area.)

> **Everything you write in this folder is git-ignored.** Only this `README.md` is
> tracked, so the folder ships with the repo and agents/operators always know where to
> store and reference analysis — while the analysis artifacts themselves never enter
> git history. This satisfies "analysis is operator working material, not committed
> platform content."

## How to use it

- One **dated subfolder per analysis**: `<name>-YYYY-MM-DD/`
  (e.g. `tree-audit-2026-04-18/`, `milestone-194-readiness-prework-2026-06-27/`),
  with a top-level `SUMMARY.md`.
- Every artifact carries the **analysis frontmatter** and is **linked to its work item**:

  ```yaml
  ---
  analysis_type: release | backlog | audit | review | gap-analysis
  work_item: "<#issue | milestone-NNN | epic #NNN>"   # the work item this analysis serves
  created: YYYY-MM-DD
  sunset: YYYY-MM-DD          # when this goes stale (see the sunset rule)
  status: active | stale | archived
  ---
  ```

- Obey the **sunset rule** so analysis does not accumulate: an artifact goes `stale`
  once past its `sunset` date (default: `created + 90d`, or `work_item` close + 30d —
  whichever is first), then is archived or deleted.

**Full convention** — frontmatter schema, sunset/retention rule, folder layout, and the
relationship to the operator-local personal analysis space:
[`core/standards/analysis-workspace-standard.md`](../core/standards/analysis-workspace-standard.md).

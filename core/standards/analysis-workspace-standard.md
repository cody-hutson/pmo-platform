# Analysis-Workspace Standard

## Purpose

Read-once analysis — release analysis, backlog analysis, audits, reviews, gap analyses
about the platform itself — is **operator working material, not shipped platform
content**. It must not be committed to the repo, yet agents and operators need a
**known, in-repo location** to store and reference it without re-deciding placement
each time.

This standard defines that location, the artifact **frontmatter**, and the **sunset
rule** that prevents unbounded accumulation. It is the tracked *framework* for the
git-ignored `analysis/` workspace — the same framework-tracked / instances-ignored split
the platform already uses for initiative roadmaps
(`core/standards/initiative-roadmap-framework.md` tracked;
`<module>/governance/roadmaps/` instances git-ignored).

## 1. Location & mechanics

| Aspect | Rule |
|---|---|
| **Path** | The repo-root `analysis/` folder. Cross-cutting working material owned by no single module → sited at the root, parallel to the git-ignored `audit-output/` working dir. |
| **Tracked** | Only `analysis/README.md` (the in-folder signpost). The folder ships on clone so the location is always discoverable. |
| **Git-ignored** | Everything else under `analysis/` — every `<name>-YYYY-MM-DD/` subfolder and its contents. Enforced by `.gitignore` (`/analysis/*` with `!/analysis/README.md`). Operator-written analysis never enters git history. |
| **Scaffolding** | None required — the folder exists in the repo via the tracked README; there is no install/resolver step. |

**Scope boundary.** This workspace is for analysis **about the platform/repo** (release,
backlog, platform audits/reviews/gap analyses). It is **not** for:

- **Project** analysis → lives with the project (the Operations domain, `projects/`).
- **Operator personal / cross-cutting** analysis unrelated to the repo → the operator-local
  personal analysis space (outside the repo entirely; an operator-instance location, never tracked).

## 2. Folder convention

Each analysis is one **dated subfolder**: `<name>-YYYY-MM-DD/` (e.g.
`tree-audit-2026-04-18/`, `milestone-194-readiness-prework-2026-06-27/`). Expected
contents: a top-level `SUMMARY.md`; optional `_templates/` / `_scores/` / `_cache/` /
`evidence/` support folders; an optional `issue-drafts/` folder with `NNN-kebab-name.md`
files ready for `gh issue create`. Dating + naming keeps multiple analyses separable and
**links each to the work item it serves** (name the folder for the milestone/issue where
useful).

If an analysis produces a `recommendations.md`, each recommendation carries a per-rec
status badge per `core/standards/audit-recommendation-status-badges.md`
so shipped recommendations stop reading as open scope. That standard governs
*recommendation status*; this one governs *artifact lifecycle* (the sunset rule, §4).

## 3. Frontmatter

Every analysis artifact (at minimum its `SUMMARY.md`) carries:

```yaml
---
analysis_type: release | backlog | audit | review | gap-analysis
work_item: "<#issue | milestone-NNN | epic #NNN>"   # the work item this analysis serves — REQUIRED
created: YYYY-MM-DD
sunset: YYYY-MM-DD          # the date this artifact goes stale (see §4)
status: active | stale | archived
---
```

| Field | Required | Meaning |
|---|---|---|
| `analysis_type` | ✅ | The kind of analysis. |
| `work_item` | ✅ | The linked work item (issue / milestone / epic). **Analysis is linked to its work item** — this is the back-reference that lets a reader find why the analysis exists and whether it is still live. |
| `created` | ✅ | Authoring date (YYYY-MM-DD). |
| `sunset` | ✅ | The staleness date (§4). |
| `status` | ✅ | `active` → `stale` → `archived`. These values are **analysis-artifact-scoped** — they are field values in this frontmatter, not the cross-machine state vocabularies catalogued in `core/standards/lifecycle-states-canonical.md` (which excludes YAML field-value contexts from its collision rule). |

## 4. Sunset rule (anti-buildup)

Analysis accumulates silently — old audits read as current, and the workspace becomes a
drift surface. The sunset rule bounds it:

1. **Set `sunset` at authoring.** Default: **`created + 90 days`**, OR **`work_item`
   close + 30 days**, whichever is **first**. (An analysis whose work item ships is stale
   30 days later; one whose work item lingers is stale at 90 days regardless.) An operator
   may set an explicit later `sunset` with a one-line reason in the artifact.
2. **Past `sunset` → `status: stale`.** A stale analysis is no longer current evidence;
   anything still needed from it should have been promoted to its work item or to
   governance (per the K5 promotion path in `core/disciplines/knowledge-architecture.md`:
   observation → pattern → (maybe) governance).
3. **Stale → archived or deleted.** Because the workspace is git-ignored, removal is a
   local delete (CHEAP, reversible only from local backups) — there is no history to
   prune and no CI to gate it.

> **Enforcement.** This standard ships the convention + frontmatter. An automated sweep
> (list/age/purge past-`sunset` artifacts in one pass) is a deferred follow-up; until it
> lands, the rule is convention-enforced at authoring + review time. The folder being
> git-ignored means a sweep is necessarily an operator-local helper, not a CI gate.

## 5. Knowledge-tier placement

Analysis is **contextual, fast-mutating working knowledge** — K5-adjacent on the
`core/disciplines/knowledge-architecture.md` tier model (situational,
not the universal K1 corpus). That is precisely why it is git-ignored: committing it would
embed contextual K4/K5 material in the tracked K1 surface. Durable findings graduate out of
`analysis/` via the K5 promotion path (into a work item, a governance change, or a
codified standard) — they are never left to rot in the workspace.

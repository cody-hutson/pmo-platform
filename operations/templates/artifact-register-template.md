# {{PROJECT_NAME}} Artifact Register

**Purpose:** Per-project configuration-management catalog of every project artifact (plans, RAID files, FDDs, charters, design docs, …) — its version, baseline status, owner, and retention. The CI catalog for the project: what configuration items exist and which are baselined vs. in-flight.
**Owner:** [OPERATOR_NAME]
**Started:** {{CREATION_DATE}}

> Instantiates as `[Project]/04-PMO-Operations/[Project]_Artifact_Register.md` per active project.
> Schema: see `core/schemas/tracker-schemas.md` § Tracker 6: Artifact Register.

---

## Register

| Artifact Name | Artifact Type | Current Version | Baseline Status | Last Updated | Owner | Retention |
|---------------|---------------|-----------------|-----------------|--------------|-------|-----------|
| (none) | | | | | | |

---

## Notes

- Rows are maintained by the **Tracker Manager** (Document Tier 2 — auto-write): ADD on artifact-generate; MODIFY `Last Updated` / `Current Version` / `Baseline Status` as the artifact or its baseline state changes. The **Artifact entity** itself stays maintained by the PPM Agent (creates: Artifact Generator; route: File Router) — Tracker Manager owns the Register *rows*, not the entity.
- **Artifact Type** uses the Type Taxonomy from `core/schemas/frontmatter-schema.md` (Charter, Plan, RAID, FDD, Design Doc, Requirements, Report, Tracker, …).
- **Baseline Status** is one of `operational` (default), `baselined-at-phase-gate` (set at a phase-gate moment — PRINCE2 configuration-management baselining), or `superseded` (a newer version has replaced it). Superseded rows are **append-only** — never delete them; they are the CI history.
- **Retention** records the artifact's retention policy (e.g., `project+2yr`, `until-closeout`). Free text — the retention policy engine is governed elsewhere.

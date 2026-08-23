# _pmo/ — the cross-project shared-entity store

The SSOT for entities that outlive and span projects: Person · System · Vendor · Workstream · Decision · Cross-Project Dependency. Workspace-level infrastructure — created once, reused by every project, re-scaffolded by none.

**What lands here:** one entity page per real-world entity, filed in the matching subfolder (`people/` · `systems/` · `vendors/` · `workstreams/` · `decisions/` · `dependencies/`). Author new pages from the entity templates in `pmo-platform/operations/templates/`.

**What does not:** project-scoped artifacts. A project's own plans, trackers, and evidence live in `projects/[Project]/`, and reference these pages by id rather than copying them.

**The entity page IS the record.** The people roster and the leadership-owner refs are read-time **consumers** of these pages, never a second copy of them. When a project names an entity that already has a page here, **link to it by its id** — never create a second page for the same entity. The id is the deduplication anchor.

**Authority:** ADR-058 (`pmo-platform/core/ADRs/`); `pmo-platform/core/schemas/entity-field-schemas.md` §3.10–§3.16 (fields and validation rules).

_Orientation only. If this card ever disagrees with its cited authority, the authority wins._

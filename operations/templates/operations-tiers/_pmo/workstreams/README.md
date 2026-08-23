# _pmo/workstreams/ — Workstream entity pages

One page per workstream — a durable stream of related work that spans or outlives a single project. Authored from `pmo-platform/operations/templates/workstream-entity-template.md`.

**What lands here:** the workstream's identity, its lifecycle state, and its lead as a reference to a Person page (`lead_person_id`), not as free text.

**What does not:** a project. A project is a delivery container with its own folder under `projects/`; a workstream is a cross-cutting grouping that projects contribute to. Sprint plans, backlogs, and status logs are project artifacts and stay in the project.

**Shared, not duplicated.** Projects reference the workstream page; they do not restate it. A workstream page duplicated per project stops being the shared record it exists to be.

**Authority:** ADR-058; `pmo-platform/core/schemas/entity-field-schemas.md` § Workstream.

_Orientation only. If this card ever disagrees with its cited authority, the authority wins._

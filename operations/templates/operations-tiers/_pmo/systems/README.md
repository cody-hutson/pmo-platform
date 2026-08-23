# _pmo/systems/ — System entity pages

One page per system or application the workspace touches, from `pmo-platform/operations/templates/system-entity-template.md`. `system_id` is unique within this store.

**What lands here:** the durable record for a system — what it is, its lifecycle state, and its owner as a reference to a Person page (`system_owner_person_id`), not as free text.

**What does not:** project-specific integration designs, cut-over plans, or defect logs. Those are project artifacts and live in the owning project's folder, citing the system by its `system_id`.

**Shared, not duplicated.** Two projects touching the same system reference one page. A second page for the same system forks the record and breaks every reference that resolves against it.

**Authority:** ADR-058; `pmo-platform/core/schemas/entity-field-schemas.md` § System.

_Orientation only. If this card ever disagrees with its cited authority, the authority wins._

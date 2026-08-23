# _pmo/people/ — Person entity pages

One page per person, from `pmo-platform/operations/templates/person-entity-template.md`. `person_id` is **globally unique** across this store and is the deduplication anchor the rest of the entity graph resolves against.

**What lands here:** a Person page for anyone referenced as an owner, lead, contact, attendee, or allocated resource anywhere in the workspace.

**What does not:** a second page for someone who already has one — link by `person_id` instead. Role assignments also do not live here; they live on the record that makes the assignment.

**Never auto-created.** A name with no existing page is routed to the operator clarification queue (`pmo-platform/operations/templates/people-graph-clarification-queue-template.md`) for the operator to add as a Person or record as external. Person creation is operator-confirmed, never scaffold-automatic — and never silently dropped or first-match auto-picked.

**The page is the record; the people roster is a read-time consumer of it.**

**Authority:** ADR-058; `pmo-platform/core/schemas/entity-field-schemas.md` § Person.

_Orientation only. If this card ever disagrees with its cited authority, the authority wins._

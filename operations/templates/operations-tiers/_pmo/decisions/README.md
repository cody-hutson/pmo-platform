# _pmo/decisions/ — Decision entity pages

One page per durable operational decision whose consequences reach beyond the meeting that made it. Authored from `pmo-platform/operations/templates/decision-entity-template.md`.

**What lands here:** the decision, its lifecycle state, and its decision-maker as a reference to a Person page (`decision_maker_person_id`), not as free text.

**What does not:** two neighbours that look similar and are not. **Architecture Decision Records** are platform-engineering artifacts and live git-tracked in the platform repo, never here. **In-flight project decisions** belong to the project's own governance artifacts; a decision graduates to a page here when it becomes durable and cross-project.

**Extraction target.** Decisions surfaced from raw evidence land here as records with a back-link to the artifact they came from — the evidence stays where it was filed and is never modified.

**Authority:** ADR-058; `pmo-platform/core/schemas/entity-field-schemas.md` § Decision.

_Orientation only. If this card ever disagrees with its cited authority, the authority wins._

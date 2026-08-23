# _pmo/vendors/ — Vendor entity pages

One page per external vendor or partner organization, from `pmo-platform/operations/templates/vendor-entity-template.md`. `vendor_id` is unique within this store.

**What lands here:** the durable vendor record — the organization, its lifecycle state, and its primary contact as a reference to a Person page (`primary_contact_person_id`), not as free text.

**What does not:** contracts, statements of work, and vendor-supplied documentation. Those are project evidence and reference material; they file into the owning project's bins, citing the vendor by its `vendor_id`.

**One vendor label, everywhere.** The page name is the single vendor label the workspace uses. Inconsistent vendor naming across artifacts is a guardrail violation; this store is what makes consistency checkable.

**Authority:** ADR-058; `pmo-platform/core/schemas/entity-field-schemas.md` § Vendor.

_Orientation only. If this card ever disagrees with its cited authority, the authority wins._

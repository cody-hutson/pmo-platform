---
# Vendor entity (VEN) — entity-field-schemas.md §3.12. Lives in projects/_pmo/vendors/.
# Cross-project shared entity (SSOT, ADR-054); primary_contact_person_id resolves AGAINST _pmo/people/.
id: {{VENDOR_ID}}                        # = vendor_id (slug); unique within _pmo/ (V-VEN-02)
entity_type: Vendor
lifecycle_state: active                  # Axis-1: active → inactive (V-VEN-04)
content_lifecycle_pattern: Living        # Axis-2 → frontmatter-schema §Cat-2 Domain B
owning_agent: ppm-agent
created_date: {{CREATION_DATE}}          # ISO YYYY-MM-DD, ≤ today (V-VEN-05)
vendor_name: {{VENDOR_NAME}}
vendor_id: {{VENDOR_ID}}                 # unique within the cross-project-shared tier
vendor_category: {{VENDOR_CATEGORY}}     # optional
primary_contact_person_id: {{CONTACT_PERSON_ID}}   # optional → Person.person_id (V-VEN-03 / X-21, WARN-HEALTH); omit if none
---
# {{VENDOR_NAME}}

**vendor_id:** `{{VENDOR_ID}}` · **Category:** {{VENDOR_CATEGORY}} · **Primary contact:** `{{CONTACT_PERSON_ID}}` (→ _pmo/people/) · **Status:** active

> Cross-project Vendor record (SSOT). Referenced by projects via link, not duplicated per project. Consumed by `change-management` (vendor contact for go-live coordination).

## Vendor Profile

- **Services / scope:** {{SERVICES}}
- **Contract / SOW reference:** {{CONTRACT_REF}}
- **Key contacts:** {{CONTACTS}}

## Lifecycle

**Current state:** `active` · _(active → inactive)_

## Notes

{{NOTES}}

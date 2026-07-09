---
artifact_type: template
template_family: RFC
domain: software
canonical_path: operations/templates/rfc-template.md
owner: [OPERATOR_NAME]
review_status: DRAFT
created: 2026-07-04
updated: 2026-07-04
generated_by: release-pipeline v3.66
reviewer: N/A
canon: IETF RFC 7322 + Rust RFC template
canon_compat: none
version: v3.66
supersedes: N/A
superseded_by: N/A
---
<!-- reference-durability: allow-link -->
<!-- The YAML block above is this TEMPLATE FILE's provenance header (core/standards/template-protocol.md §4.1). Do NOT copy it into rendered RFC instances — an instance starts at the H1 below. -->
<!-- canon_compat evidence (template-protocol.md §6): `none` records that no Anthropic plugin counterpart exists for the RFC family — template-taxonomy.md §6 row 4 + §7 declare this family "stands on the upstream canon alone" (IETF RFC 7322 + the Rust RFC template). The value is a forward declaration at DRAFT and is authoritative only at an APPROVED transition; P5 re-evaluates at any future APPROVED transition. -->

# RFC-{{RFC_ID}}: {{TITLE}}

**Purpose:** Propose, specify, and decide a substantial technical or process change through structured peer review — before implementation begins.
**Canon:** IETF RFC 7322 (RFC Style Guide) + the Rust RFC process template — binding per `core/standards/template-taxonomy.md` §6 row 4 (canon sources catalogued in its §8). No Anthropic plugin counterpart exists for this family; the template stands on the upstream canon alone.
**Author:** {{AUTHOR}} · **Status:** {{DRAFT | PROPOSED | ACCEPTED | REJECTED | WITHDRAWN | SUPERSEDED}} · **Created:** {{CREATION_DATE}} · **Tracking:** {{TRACKING_REF}}

---

## Abstract

{{ABSTRACT}} <!-- RFC 7322 §4.3: one self-contained paragraph; intelligible without the body; no citations or footnotes. -->

## Motivation

{{MOTIVATION}} <!-- Why now. The problem, who has it, what happens if nothing changes. Expected outcome stated up front. -->

## Guide-Level Explanation

{{GUIDE_LEVEL}} <!-- Rust RFC convention: explain the change as if it already shipped — how a consumer/operator/engineer would use it, with examples. Teach it, don't defend it. -->

## Reference-Level Explanation

{{REFERENCE_LEVEL}} <!-- Precise technical detail: interfaces, data shapes, state machines, error paths, edge cases. Complete enough that an implementer needs no interpretation. -->

## Drawbacks

- {{DRAWBACK_1}}
- {{ASSUMPTION – CONFIRM}}

## Rationale and Alternatives

| Alternative | Why not chosen |
|---|---|
| {{ALTERNATIVE_1}} | {{WHY_NOT_1}} |
| {{ALTERNATIVE_2}} | {{WHY_NOT_2}} |

**Why this design:** {{RATIONALE}}
**Impact of not doing this:** {{IMPACT_OF_INACTION}}

## Prior Art

{{PRIOR_ART}} <!-- Existing implementations, upstream conventions, earlier internal attempts — and what they teach. -->

## Security Considerations

{{SECURITY_CONSIDERATIONS}} <!-- RFC 7322 §4.8.5: required, even when the honest content is "none identified — because {{REASON}}". -->

## Unresolved Questions

- {{OPEN_QUESTION_1}}

## Future Possibilities

- {{FUTURE_POSSIBILITY_1}}

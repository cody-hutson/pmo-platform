# Technical-Documentation Routing — artifact-generator

<!-- reference-durability: allow-link -->

**Type:** design-time routing reference (consumed by the agent when a user asks for a technical-documentation artifact).

This reference is the per-target routing detail for the **technical-documentation** branch of the artifact-skill routing decision tree. The user-facing "which artifact skill to call" tree lives in [`core/standards/artifact-skill-routing.md`](../../../../core/standards/artifact-skill-routing.md); this file holds the detail for one branch of it. The sibling branch for product-requirement artifacts is [`prd-routing.md`](prd-routing.md).

## Route target

Technical-documentation artifacts route to the purpose-built Anthropic skill **`engineering/documentation`**. artifact-generator does **not** self-produce them — its catalog is deliberately scoped to PMO-unique artifacts (see [`artifact-catalog.md`](artifact-catalog.md)) and these types were offloaded at the catalog-narrowing.

## In-scope types (route OUT — do not self-produce)

| Type | Notes |
|---|---|
| API docs | endpoint reference, request/response schemas, auth |
| README | repository or component entry-point documentation |
| Architecture docs | system/component design, diagrams, decision context |
| Runbooks | operational procedures, incident response, on-call |
| Onboarding guides | developer/operator getting-started material |
| Technical reference | configuration reference, CLI reference, glossary |

## Routing decision

When a user asks for any in-scope type above:

1. **Do NOT self-produce** from a PMO structural template. The PMO catalog no longer carries these entries; a near-miss from a governance-doc template yields a non-authoritative document while the purpose-built Anthropic skill exists.
2. **Direct the user to** the Anthropic `engineering/documentation` skill to produce the content.
3. **Offer Wrapper-Mode staging** of the result so the produced artifact enters the PMO project record with provenance.

## Wrap-back step

The Anthropic-produced document is brought into the project via artifact-generator **Wrapper Mode** (see the SKILL.md §Wrapper Mode). Wrapper Mode prepends the PMO metadata header and stages the file — it never mutates the content body. The header carries:

- `source: external`
- `source_origin: Anthropic engineering/documentation`
- the full Step-5 frontmatter block with `status: Draft` (the lifecycle state on emit)

The artifact then follows the normal PROMOTE / REVISE / REJECT promotion workflow.

## Coupling posture (design-time only — NO runtime call)

This is **user-routing guidance**, not a runtime-coupling spec. There is **no runtime Anthropic call** anywhere in this path: the Anthropic skill is invoked *separately, before* the wrap, and Wrapper Mode touches only the inert output. Per [ADR-023 — Skill sourcing-coupling posture](../../../../core/ADRs/ADR-023-skill-sourcing-coupling-posture.md), artifact-generator remains `independent` / own-with-harvest — routing-out plus wrap-and-stage are not runtime coupling. Structure and conventions are harvested at design time via the [upstream-reference catalog](../../../../core/standards/upstream-reference-catalog.md), the recorded harvest surface; no `extends` / `pass-through` binding is introduced.

## Related

- Decision tree (all branches): [`core/standards/artifact-skill-routing.md`](../../../../core/standards/artifact-skill-routing.md)
- Sibling branch (PRDs / feature specs): [`prd-routing.md`](prd-routing.md)
- PMO-unique catalog (what artifact-generator DOES produce): [`artifact-catalog.md`](artifact-catalog.md)
- Sourcing posture: [ADR-023](../../../../core/ADRs/ADR-023-skill-sourcing-coupling-posture.md)
- Harvest surface: [upstream-reference catalog](../../../../core/standards/upstream-reference-catalog.md)

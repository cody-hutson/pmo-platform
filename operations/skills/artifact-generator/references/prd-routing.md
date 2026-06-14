# PRD / Feature-Spec Routing — artifact-generator

**Type:** design-time routing reference (consumed by the agent when a user asks for a PRD or feature-specification artifact).

This reference is the per-target routing detail for the **PRD / feature-spec** branch of the artifact-skill routing decision tree. The user-facing "which artifact skill to call" tree lives in [`core/standards/artifact-skill-routing.md`](../../../../core/standards/artifact-skill-routing.md); this file holds the detail for one branch of it. The sibling branch for technical-documentation artifacts is [`tech-doc-routing.md`](tech-doc-routing.md).

## Route target

PRD / feature-spec artifacts route to the purpose-built Anthropic skill **`product-management/feature-spec`**. artifact-generator does **not** self-produce them — its catalog is deliberately scoped to PMO-unique artifacts (see [`artifact-catalog.md`](artifact-catalog.md)) and these types were offloaded at the catalog-narrowing.

## In-scope types (route OUT — do not self-produce)

| Type | Notes |
|---|---|
| PRDs | product requirements documents |
| New-feature user stories | feature-level stories with value framing |
| Acceptance-criteria docs | testable acceptance criteria for a feature |
| Success-metric definitions | outcome metrics / success measures for a feature |

## Routing decision

When a user asks for any in-scope type above:

1. **Do NOT self-produce** from a PMO structural template. The PMO catalog no longer carries these entries; a near-miss from a governance-doc template yields a non-authoritative document while the purpose-built Anthropic skill exists.
2. **Direct the user to** the Anthropic `product-management/feature-spec` skill to produce the content.
3. **Offer Wrapper-Mode staging** of the result so the produced artifact enters the PMO project record with provenance.

## Wrap-back step

The Anthropic-produced document is brought into the project via artifact-generator **Wrapper Mode** (see the SKILL.md §Wrapper Mode). Wrapper Mode prepends the PMO metadata header and stages the file — it never mutates the content body. The header carries:

- `source: external`
- `source_origin: Anthropic product-management/feature-spec`
- the full Step-5 frontmatter block with `status: PENDING_REVIEW`

The artifact then follows the normal PROMOTE / REVISE / REJECT promotion workflow.

## Coupling posture (design-time only — NO runtime call)

This is **user-routing guidance**, not a runtime-coupling spec. There is **no runtime Anthropic call** anywhere in this path: the Anthropic skill is invoked *separately, before* the wrap, and Wrapper Mode touches only the inert output. Per [ADR-021 — Skill sourcing-coupling posture](../../../../core/ADRs/ADR-021-skill-sourcing-coupling-posture.md), artifact-generator remains `independent` / own-with-harvest — routing-out plus wrap-and-stage are not runtime coupling. Structure and conventions are harvested at design time via the [upstream-reference catalog](../../../../core/standards/upstream-reference-catalog.md), the recorded harvest surface; no `extends` / `pass-through` binding is introduced.

## Related

- Decision tree (all branches): [`core/standards/artifact-skill-routing.md`](../../../../core/standards/artifact-skill-routing.md)
- Sibling branch (technical documentation): [`tech-doc-routing.md`](tech-doc-routing.md)
- PMO-unique catalog (what artifact-generator DOES produce): [`artifact-catalog.md`](artifact-catalog.md)
- Sourcing posture: [ADR-021](../../../../core/ADRs/ADR-021-skill-sourcing-coupling-posture.md)
- Harvest surface: [upstream-reference catalog](../../../../core/standards/upstream-reference-catalog.md)

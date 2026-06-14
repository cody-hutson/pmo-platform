<!-- reference-durability: allow-link -->
# Process-Flow Diagram Standards

**Status:** Canonical
**Owner:** `core/specs/process-flow-diagram-standards.md`
**Introduced:** 2026-05-15
**Consumers:** Every skill or reference doc that authors/modifies a process-flow diagram. The retrofit track consumes the Adoption § Exemptions Registry anchor.
**Cross-references:** see § Related References at the foot of this file.

## Purpose

This document is the canonical authority for process-flow diagrams authored or materially modified going forward. It codifies the Mermaid syntax template, swimlane notation idiom, and color/shape grammar that every skill and reference doc consumes when depicting a workflow, and codifies the existing plain-fence ASCII flow-block as an accepted lightweight alternative governed by the binary decision rule below. Process-flow diagram style was inconsistent across skills previously; this standard makes the conventions explicit and consistent going forward.

## Scope & Diagram-Form Decision Rule

- Use **Mermaid** when the flow has ≥1 decision/gate node **OR** ≥2 actors (swimlanes) **OR** is cited as canonical by a skill/reference doc.
- Use the **ASCII flow-block** (plain ` ``` ` fence) when the flow is a linear stage/step sequence with no branching and ≤1 actor (e.g., the pipeline implementation-sequence block). ASCII blocks are **accepted, not deprecated** — the right tool for linear sequences.

## Mermaid Syntax Template

```mermaid
flowchart TD
    start([Start / Trigger]) --> step1[Process step]
    step1 --> gate{Decision / Gate}
    gate -->|Yes| step2[Process step]
    gate -->|No| stop([End / Terminal])
    step2 --> artifact[/Artifact or file/]
    artifact --> manual[[Human / Tier-3 action]]
    manual --> stop
    classDef automated fill:#D4EDDA,stroke:#28A745,color:#155724;
    classDef human fill:#D1ECF1,stroke:#17A2B8,color:#0C5460;
    classDef gate fill:#FFF3CD,stroke:#FFC107,color:#856404;
    classDef external fill:#E2E3E5,stroke:#6C757D,color:#383D41;
    classDef risk fill:#F8D7DA,stroke:#DC3545,color:#721C24;
    class step1,step2 automated;
    class manual human;
    class gate gate;
```

## Swimlane Notation Example

```mermaid
flowchart TD
    subgraph HUB[Hub — orchestrator]
        h1[Route sub-task chip] --> h2{Gate decision}
    end
    subgraph SPOKE[Spoke — executor]
        s1[Execute stage task] --> s2[/Post sub-task output/]
    end
    h1 --> s1
    s2 --> h2
    classDef automated fill:#D4EDDA,stroke:#28A745,color:#155724;
    classDef gate fill:#FFF3CD,stroke:#FFC107,color:#856404;
    class s1 automated;
    class h2 gate;
```

> Mermaid has no native swimlane primitive in `flowchart`; **`subgraph NAME[Label] … end` per actor is the standard lane idiom**. Rejected alternative `sequenceDiagram` participants — platform flows are activity flows, not message sequences (rationale recorded in § Design Rationale).

## Color / Shape Grammar

| Element | Mermaid syntax | Semantic | classDef | Fill / Stroke |
|---|---|---|---|---|
| Terminal | `([text])` stadium | Start / trigger / end | — (shape only) | default |
| Process step | `[text]` rect | Automated / agent action | `automated` | `#D4EDDA` / `#28A745` |
| Decision / Gate | `{text}` rhombus | Branch, stage-gate, QA checkpoint | `gate` | `#FFF3CD` / `#FFC107` |
| Artifact / file | `[/text/]` parallelogram | File / comment / document produced or consumed | — (shape only) | default |
| Human / Tier-3 | `[[text]]` subroutine | Operator / irreducible-human action | `human` | `#D1ECF1` / `#17A2B8` |
| External system | `[(text)]` cylinder | GitHub / Cowork / external dependency | `external` | `#E2E3E5` / `#6C757D` |
| Risk / blocked | any shape `:::risk` | Blocked path, risk surface, rollback edge | `risk` | `#F8D7DA` / `#DC3545` |
| Swimlane | `subgraph NAME[Label] … end` | Actor / role lane | — | default |

(Palette is Mermaid-`classDef`-expressible, WCAG-AA text contrast, 5 classes — deliberately minimal so authors can reproduce without a design system.)

## ASCII Flow-Block Convention

The plain-fence ASCII flow-block is the dominant existing form platform-wide — currently exactly one Mermaid diagram exists; every other flow is a plain-fence ASCII block. It is **accepted, not deprecated**: the right tool for a linear stage/step sequence with no branching and ≤1 actor, per the binary rule in § Scope & Diagram-Form Decision Rule. Authors use a plain triple-backtick fence with nodes connected by `→` or `-->` arrows in reading order. Canonical example — the pipeline implementation-sequence block:

```
Stage 5 Solutioning:   Spec-A ∥ Spec-B    (parallel)
   → Collective Review  (release gate — scope-lock)
Stage 6 Engineering:   Spec-A → Spec-B    (serialized)
   → Stage 7 Dev Testing → Stage 8 QA → Stage 9 Plan Review → Stage 12 Execute → Stage 13 Close
```

Promote to Mermaid (per § Scope & Diagram-Form Decision Rule) the moment the flow gains a decision/gate node, a second actor, or a canonical citation.

## Adoption

**Scope: FORWARD-ONLY.** This standard governs every process-flow diagram **when authored or materially modified**. Diagrams that predate this standard's adoption are **grandfathered** — not retroactively non-conformant, requiring no change to remain valid.

**Retroactive retrofit is explicitly OUT OF SCOPE for this standard.** Migrating pre-existing skill/reference diagrams to this standard is tracked separately (HARD-depends on this standard). The retrofit track owns the roster audit, per-skill `pmo-skill-editor` routing, `.skill` rebuilds, and the going-forward conformance-check question.

**Conformance trigger:** a diagram becomes in-scope the first time its enclosing fenced block is added or edited. Editing surrounding prose without touching the diagram does **not** trigger conformance.

### Exemptions Registry

Diagrams that are intentionally exempt are listed here with rationale. **Initially empty** — under forward-only adoption no diagram is exempt by default. The retrofit track populates this registry when its retrofit audit determines a specific diagram should remain non-conforming with stated rationale (this anchor satisfies the retrofit AC1's "listed exempt with rationale in the standard's Adoption section").

| Diagram (file:anchor) | Exempt since | Rationale | Tracking |
|---|---|---|---|
| _(none — forward-only)_ | — | — | — |

## Design Rationale

Inline options analysis (no separate ADR Issue — single reasonable approach per doc-standard; mirrors `five-function-spine-and-process-flows.md`'s ADR-pointer pattern, lighter).

**Why subgraph-as-lane.** Mermaid has no native swimlane primitive in `flowchart`; `subgraph NAME[Label] … end` per actor is the standard lane idiom. Rejected alternative `sequenceDiagram` participants — platform flows are activity flows, not message sequences.

**Why dual-form (Mermaid + ASCII).** Only one Mermaid diagram exists platform-wide; the dominant existing form is plain-fence ASCII. A Mermaid-only standard would be honored in the breach and would maximally inflate the retrofit surface. The standard therefore codifies both Mermaid (AC-required, preferred for branching/multi-actor) and the ASCII flow-block as an accepted lightweight alternative, governed by the binary decision rule.

**Why the `five-function-spine-and-process-flows.md` consumer.** AC2 requires the standard be cited as canonical authority with a resolving reference link; an orphan file nothing points to is not "cited." `five-function-spine-and-process-flows.md` is the platform's self-declared process-flow anchor, already owns a citation registry, is single-source (no mirror pair / no `deploy.sh --check` Check 9 interaction), and is not a high-traffic surface (inter-issue contention stays zero). Rejected `canonical-skill-structure.md` (dual-gate-enforced, high-traffic, expands blast radius into Checks 6–10; also too narrow — reference docs author diagrams too) and `architecture-overview.md` (structural map, does not enumerate reference docs by filename, out-of-pattern).

## Related References

- [`design-artifact-standard.md`](../standards/design-artifact-standard.md) — META / parent framework for all 7 design-artifact flow types; this standard governs the process-flow class specifically. Composed per `design-artifact-standard.md` § 6 Tool Selection.
- [`five-function-spine-and-process-flows.md`](../disciplines/five-function-spine-and-process-flows.md) — the platform's self-declared canonical anchor for cross-cutting process flows; reciprocates the inbound citation from its § Related References.
- [`terminology-glossary.md`](terminology-glossary.md) — canonical term definitions (Function, Process, Methodology, Framework).
- [`pipeline/README.md`](../../release/references/pipeline/README.md) — 13-stage pipeline reference directory.

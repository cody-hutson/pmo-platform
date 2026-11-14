---
title: <Activity name>
purpose: <One line: the one purpose this activity serves>
type: reference
status: DRAFT
reversibility: CHEAP / Confidence HIGH
flow_class: <agent-process | human-process | skill-flow | decision-tree>
depicts: [<path>, <path>]
id: <minted-id>
level: L3
universe: <L0 id>
parent: <L2 id>
precedes: [<sibling id>]
actors: [<actor>]
owner: <actor>
lens_status: not-assessed
last_verified_commit: <sha>
pack_version: 2
---
# <Activity name>

## Summary

<Two to four sentences: who does it, on what, producing what.>

## ICOM

| Inputs | Controls | Outputs | Mechanisms |
|---|---|---|---|
| <what it consumes> | <rules that govern it> | <what it produces> | <skills, tools, hooks, models that perform it> |

## Flow

```mermaid
flowchart TD
    s1[<Step>] --> s2[<Step>]
    s2 --> g1{<Decision>}
    g1 -->|yes| s3[/<Output>/]
    g1 -->|no| s1
    classDef automated fill:#D4EDDA,stroke:#28A745,color:#155724;
    classDef gate fill:#FFF3CD,stroke:#FFC107,color:#856404;
    class s1,s2 automated;
    class g1 gate;
```

## Steps

| Step | Action | Actor | Inputs → outputs (shape) | Controls | Mechanism | Harness | Model need | Source |
|---|---|---|---|---|---|---|---|---|
| <step-slug> | <verb + object> | <actor> | <input shape> → <output shape> | <rule: class> | <skill / tool> | <feature relied on> | <model need, per the pack> | `<path>` |

## Step profile

| Field | Value |
|---|---|
| Deterministic steps | <count of steps a script could do> |
| Judgment steps | <count needing model judgment> |
| Harness features relied on | <list> |
| Context read | <token estimate of what the actor must read> |

## Evidence

| Lens | Source | Observation | Label |
|---|---|---|---|
| designed | `<path>` | <observation> | [SOURCE] |
| built | `<path>` | <observation> | [SOURCE] |
| executed | measure `<measure-id>` — [<script>](/core/deploy/tools/process-catalog-measures/<script>) (population: <the rule, in words>) · [<file>](/.github/workflows/<file>) | <what the measure reports and how to read it; no figure> covers: `<step-key>`, `<step-key>` | [SOURCE] |

## Navigation

<!-- nav:begin -->
Up: [<L2 id>](<path>) · Previous: [<id>](<path>) · Next: [<id>](<path>)
<!-- nav:end -->

## Sources

- `<path>` — <what it contributes>

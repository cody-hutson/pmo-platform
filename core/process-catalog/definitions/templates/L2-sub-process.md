---
title: <Sub-process name>
purpose: <One line: what this sub-process turns its inputs into>
type: reference
status: DRAFT
reversibility: CHEAP / Confidence HIGH
flow_class: <agent-process | human-process | skill-flow | decision-tree>
depicts: [<path>, <path>]
id: <minted-id>
level: L2
universe: <L0 id>
parent: <L1 id>
precedes: [<sibling id>]
actors: [<actor>, <actor>]
owner: <actor>
lens_status: not-assessed
last_verified_commit: <sha>
pack_version: 2
---
# <Sub-process name>

## Summary

<Three to five sentences: what enters, what happens, what leaves, and the gate at each end.>

## Entry and exit

| Side | Criteria | Source |
|---|---|---|
| Entry | <what must be true to start> | `<path>` |
| Exit | <what must be true to finish> | `<path>` |

## Flow

```mermaid
flowchart TD
    subgraph LANE1[<Actor>]
        a1[<Activity>] --> g1{<Gate>}
    end
    subgraph LANE2[<Actor>]
        a2[<Activity>] --> out[/<Artifact>/]
    end
    g1 -->|pass| a2
    g1 -->|fail| a1
    classDef automated fill:#D4EDDA,stroke:#28A745,color:#155724;
    classDef gate fill:#FFF3CD,stroke:#FFC107,color:#856404;
    class a1,a2 automated;
    class g1 gate;
```

## Activities

| Activity | Primary actor | Purpose | Page |
|---|---|---|---|
| <name> | <actor> | <one line> | [<id>](<path>) |

## Controls

| Control | Source | Enforcement class | Surface | Applies to |
|---|---|---|---|---|
| <rule> | `<path>` | <class> | <surface> | <activity id> |

## Evidence

| Lens | Source | Observation | Label |
|---|---|---|---|
| designed | `<path>` | <observation> | [SOURCE] |
| built | `<path>` | <observation> | [SOURCE] |
| executed | measure `<measure-id>` — [<script>](/core/deploy/tools/process-catalog-measures/<script>) (population: <the rule, in words>) | <what the measure reports and how to read it; no figure> | [SOURCE] |

## Navigation

<!-- nav:begin -->
Up: [<L1 id>](<path>) · Previous: [<id>](<path>) · Next: [<id>](<path>) · Down: <activity links>
<!-- nav:end -->

## Sources

- `<path>` — <what it contributes>

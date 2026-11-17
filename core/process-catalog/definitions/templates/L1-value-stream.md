---
title: <Value stream name, verb first>
purpose: <One line: from what trigger to what outcome>
type: reference
status: DRAFT
reversibility: CHEAP / Confidence HIGH
flow_class: <agent-process | human-process | skill-flow | decision-tree>
depicts: [<path>, <path>]
id: <minted-id>
level: L1
universe: <L0 id>
parent: <L0 id>
precedes: [<sibling id>]
triggered_by: [<event:name | schedule:name | external:role | node id>]
actors: [<actor>, <actor>]
owner: <actor>
lens_status: not-assessed
last_verified_commit: <sha>
pack_version: 2
---
# <Value stream name>

## Summary

<Three to five sentences: trigger, outcome, the main sub-processes in order, and the decision points that matter.>

## SIPOC

| Suppliers | Inputs | High-level steps | Outputs | Customers |
|---|---|---|---|---|
| <who supplies> | <what goes in> | <four to seven steps> | <what comes out> | <who uses it> |

## Flow

```mermaid
flowchart LR
    start([<Trigger>]) --> sp1[<Sub-process>]
    sp1 --> g1{<Gate>}
    g1 -->|pass| sp2[<Sub-process>]
    g1 -->|fail| sp1
    sp2 --> done([<Outcome>])
    classDef automated fill:#D4EDDA,stroke:#28A745,color:#155724;
    classDef gate fill:#FFF3CD,stroke:#FFC107,color:#856404;
    class sp1,sp2 automated;
    class g1 gate;
```

## Sub-processes

| Sub-process | Entry | Exit | Page |
|---|---|---|---|
| <name> | <entry criteria> | <exit criteria> | [<id>](<path>) |

## Controls

| Control | Source | Enforcement class | Surface | Applies to |
|---|---|---|---|---|
| <rule, in one line> | `<path>` | <enforcement class, per the pack> | <surface, per the pack> | <sub-process id> |

## Evidence

| Lens | Source | Observation | Label |
|---|---|---|---|
| designed | `<path>` | <what the spec says> | [SOURCE] |
| built | `<path>` | <what code enforces> | [SOURCE] |
| executed | measure `<measure-id>` — [<script>](/core/deploy/tools/process-catalog-measures/<script>) (population: <the rule, in words>) | <what the measure reports and how to read it; no figure> | [SOURCE] |

## Navigation

<!-- nav:begin -->
Up: [<L0 id>](<path>) · Next: [<sibling id>](<path>) · Down: <sub-process links>
<!-- nav:end -->

## Sources

- `<path>` — <what it contributes>

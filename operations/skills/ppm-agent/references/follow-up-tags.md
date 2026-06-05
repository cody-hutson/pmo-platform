# Follow-Up Tag Routing Protocol

## Purpose

Follow-up tags are the inter-skill routing mechanism on the PMO platform. When a skill identifies an action that belongs to another skill's domain, it emits a follow-up tag. The receiving skill processes the tagged action. This document defines the tag vocabulary, format, routing rules, emission rules, and depth constraints.

## Tag Definitions

| Tag | Domain | Description | Typical Trigger |
|-----|--------|------------|-----------------|
| **[DELIVERY]** | Sprint/backlog/timeline management | Affects delivery schedule, backlog ordering, velocity, or sprint commitment | Scope change, blocked item, timeline risk, capacity change |
| **[COMMS]** | Stakeholder communication | Requires a communication to be drafted, reviewed, or sent | Decision made, status change, escalation needed, stakeholder update due |
| **[TECHNICAL]** | Technical review or architecture decision | Requires technical analysis, architecture review, or design decision | Technical risk identified, design trade-off surfaced, integration concern |
| **[PROCESS]** | Process design or requirements work | Requires process analysis, requirements elaboration, or workflow design | Process gap identified, requirements conflict, workflow optimization needed |
| **[CHANGE]** | Change management action | Requires organizational change management — readiness, training, adoption | Go-live approaching, stakeholder resistance detected, training gap, adoption risk |

## Tag Format

Every emitted tag follows a structured format that provides the receiving skill with enough context to act without returning to the emitting skill:

```
[TAG: brief description]
- Context: What triggered this tag
- Source: Which skill/output emitted it
- Scope: What needs to happen (specific enough to act on)
- Inputs: What data/artifacts the receiving skill needs
- Constraints: Deadlines, dependencies, or limitations
```

**Example:**
```
[DELIVERY: Sprint 8 scope at risk due to vendor delay]
- Context: Vendor integration testing delayed 5 days per email from vendor PM (March 28)
- Source: ppm-agent daily processing
- Scope: Assess impact on Sprint 8 commitment; recommend scope adjustment or capacity reallocation
- Inputs: Current sprint backlog, vendor dependency map, team velocity data
- Constraints: Sprint 8 starts April 1; decision needed by March 30
```

**Minimum viable tag:** When full context is not available, the tag must include at minimum the tag type, a description, and the source. Incomplete tags are acceptable at Level 2 resolution (partial resolve per push-to-resolve.md).

## Routing Rules

Tags route to specific receiving skills based on domain:

| Tag | Primary Receiving Skill | Secondary (if primary unavailable) |
|-----|------------------------|-----------------------------------|
| **[DELIVERY]** | delivery-engine | ppm-agent (fallback for strategic delivery decisions) |
| **[COMMS]** | comms-writer | ppm-agent (fallback for stakeholder strategy) |
| **[TECHNICAL]** | pmo-technical-analyst | ppm-agent (fallback for technical governance) |
| **[PROCESS]** | pmo-process-designer | ppm-agent (fallback for process governance) |
| **[CHANGE]** | change-management | ppm-agent (fallback for change strategy) |

**Routing precedence:** When multiple tags are emitted in a single output, they route independently. There is no priority ordering between tag types — each routes to its receiving skill in parallel.

**Unrecognized tags:** If a tag does not match the five defined types, it routes to ppm-agent as the catch-all coordinator. Log an improvement entry for vocabulary expansion.

## Emission Rules

Each skill has a defined set of tags it can emit. This prevents routing loops and ensures clear domain boundaries.

| Emitting Skill | Can Emit | Cannot Emit (would create loop) |
|---------------|----------|--------------------------------|
| **ppm-agent** | [DELIVERY], [COMMS], [TECHNICAL], [PROCESS], [CHANGE] | None (coordinator can emit all) |
| **delivery-engine** | [COMMS], [TECHNICAL], [CHANGE] | [DELIVERY] (self-referential) |
| **comms-writer** | [DELIVERY], [CHANGE] | [COMMS] (self-referential) |
| **pmo-technical-analyst** | [DELIVERY], [COMMS], [PROCESS] | [TECHNICAL] (self-referential) |
| **pmo-process-designer** | [DELIVERY], [COMMS], [TECHNICAL] | [PROCESS] (self-referential) |
| **change-management** | [DELIVERY], [COMMS] | [CHANGE] (self-referential) |
| **release-planner** | [DELIVERY], [TECHNICAL] | N/A |
| **release-executor** | [COMMS], [TECHNICAL] | N/A |
| **daily-status** | [DELIVERY], [COMMS] | N/A |
| **weekly-status-rollup** | [DELIVERY], [COMMS] | N/A |
| **tracker-manager** | [DELIVERY] | N/A |
| **artifact-generator** | None (produces artifacts, does not route) | All |

## Depth Constraint

**Maximum routing depth: 2**

A tag can trigger a skill that emits one more tag, but no further. This prevents infinite routing loops and limits blast radius.

| Depth | What Happens | Example |
|-------|-------------|---------|
| Depth 0 | Original skill processing | ppm-agent processes daily status |
| Depth 1 | First tag emission and routing | ppm-agent emits [DELIVERY]; delivery-engine processes |
| Depth 2 (max) | Second tag emission and routing | delivery-engine emits [COMMS]; comms-writer processes |
| Depth 3+ | **BLOCKED** | comms-writer would emit [DELIVERY] — blocked. Logged as unresolved follow-up for next processing cycle. |

**Depth tracking:** Each tag carries a `depth` counter. Emitting skill increments the counter. Receiving skill checks the counter before emitting further tags.

**Depth violation handling:** When a tag at depth 2 would trigger a depth 3 emission, the receiving skill:
1. Logs the would-be tag as an unresolved follow-up in its output
2. Flags it for the next processing cycle
3. Does NOT suppress the information — it surfaces it without routing

## Tag Lifecycle

| State | Description | Transition |
|-------|-------------|-----------|
| **Emitted** | Tag created by emitting skill in output | Emitting skill completes processing |
| **Routed** | Tag delivered to receiving skill | Platform routes based on tag type |
| **Processing** | Receiving skill acting on the tag | Receiving skill begins processing |
| **Resolved** | Action completed by receiving skill | Receiving skill produces output |
| **Unresolved** | Action could not be completed (depth limit, missing info, requires human) | Logged for next cycle |

## Integration with Push-to-Resolve

Follow-up tags are a push-to-resolve mechanism. When a skill identifies an action outside its domain:
- **Do NOT** just note it ("there may be a communication need here")
- **DO** emit a structured tag with enough context for the receiving skill to act immediately
- This is Invisible Orchestration: routing work to the right skill without being a bottleneck

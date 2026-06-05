# Domain C Lifecycle Protocol — Synthesized Intelligence Artifacts

## Purpose

Defines lifecycle management for files in 08-Generated/ folders. Replaces the current 10-day auto-archive with a governed, state-based lifecycle that distinguishes ephemeral processing output from durable synthesis.

**Grounding:** Design brief §9.3 (Domain C definition), §15.3 (synthesis lifecycle), §32-33 (promotion criteria); C12 (three lifecycle patterns, anti-pattern #5: stale reference); Prototype finding 3 (Domain C needs lifecycle integration)
**Cross-references:** `schemas/frontmatter-schema.md` (lifecycle fields), `schemas/sqlite-index-schema.md` (Query 6: staleness detection)
**Object-typing registration:** This protocol's 5 states (`draft / validated / published / stale / archived`) are registered in [`standards/lifecycle-states-canonical.md`](../../../core/standards/lifecycle-states-canonical.md) under the object-type prefix `Domain-C-`. See canonical source for cross-machine vocabulary reconciliation and the `<Object>-<State>` naming convention.

## Consumers

| Consumer | Role |
|----------|------|
| Artifact Generator | Applies initial lifecycle state on creation |
| Health check engine | Detects lifecycle violations, staleness |
| Navigation layer generator | Surfaces lifecycle state in views, filters active vs. archived |
| Human users | Validate and promote synthesis (draft → validated → published) |
| PPM Agent | Triggers staleness detection when source files change |

---

## Lifecycle States

| State | Description | Who Can Enter | Exit Conditions |
|-------|-------------|---------------|-----------------|
| `draft` | Newly generated, not yet reviewed | Agent (Artifact Generator) | Agent validation pass → `validated`; source changes → `stale`; 30-day timeout → `archived` |
| `validated` | Passed agent consistency checks, awaiting human confirmation | Agent (health check / validation pass) | Human approval → `published`; source changes → `stale` |
| `published` | Human-confirmed as authoritative synthesis | Human only | Source material changes → `stale`; superseding artifact created → `archived` |
| `stale` | Source material has changed since creation/publication | Agent (staleness detection) | Human re-validates → `published`; human archives → `archived` |
| `archived` | No longer current, retained for historical reference | Agent (timeout) or Human | Terminal state |

---

## State Transition Diagram

```
                            ┌──────────────────────────┐
                            │                          │
                            ▼                          │
     ┌─────────┐    agent    ┌───────────┐   human    ┌───────────┐
     │  draft  │───────────►│ validated │──────────►│ published │
     └────┬────┘  validation └─────┬─────┘  approval  └─────┬─────┘
          │         pass           │                         │
          │                        │                         │
          │  source     source ────┘         source ─────────┘
          │  changes    changes              changes
          │         │          │                   │
          │         ▼          ▼                   ▼
          │       ┌──────────────────────────────────┐
          │       │             stale                │
          │       └──────────────┬───────────────────┘
          │                      │
          │  30-day              │  human        human
          │  timeout             │  re-validates  archives
          │                      │       │            │
          ▼                      ▼       │            ▼
     ┌──────────────────────────────────────────────────┐
     │                    archived                      │
     └──────────────────────────────────────────────────┘
```

### Valid Transitions

| From | To | Trigger | Agent/Human |
|------|----|---------|-------------|
| `draft` | `validated` | Agent consistency check passes | Agent |
| `draft` | `stale` | Source material changes before validation | Agent |
| `draft` | `archived` | 30-day timeout without validation | Agent |
| `validated` | `published` | Human confirms synthesis is authoritative | Human |
| `validated` | `stale` | Source material changes before publication | Agent |
| `published` | `stale` | Source material changes after publication | Agent |
| `stale` | `published` | Human re-validates after reviewing source changes | Human |
| `stale` | `archived` | Human determines synthesis is no longer useful | Human |
| `published` | `archived` | Human archives; or superseded by newer synthesis | Human |

### Invalid Transitions

- `archived` → any state (terminal — to resurrect, create new synthesis)
- `stale` → `validated` (must go through human review to `published`)
- `draft` → `published` (must pass agent validation first)
- Any backward transition not listed above

---

## Trigger Specifications

### Staleness Detection Triggers

Staleness is detected by the health check engine (Query 6 in `sqlite-index-schema.md`).

**Trigger 1: Source file modification**
- Condition: any file listed in the synthesis's `synthesis_scope` frontmatter array has been modified since the synthesis `created_date`
- Detection: SQL join between `synthesis_scope` and `files` where `src.modified_date > synth.created_date`
- Action: transition `lifecycle_state` to `stale`
- Priority: P1 — checked after every processing cycle

**Trigger 2: Dependency chain staleness**
- Condition: a file this synthesis `DEPENDS_ON` has transitioned to `stale` or `archived`
- Detection: follow `DEPENDS_ON` relationships from this file; check target lifecycle states
- Action: increase staleness score; transition to `stale` if score exceeds threshold
- Priority: P2 — checked daily

**Trigger 3: Time-based decay (configurable)**
- Condition: `published` state for longer than configurable threshold without source changes
- Default threshold: 30 days for `published` without any source file modification
- Note: this does NOT trigger automatic staleness if sources are unchanged — a stable synthesis over stable sources is healthy. Only triggers if the synthesis references a domain where staleness_threshold_days is exceeded.
- Priority: P3 — checked weekly

### Validation Checks (Draft → Validated)

Agent performs these checks before transitioning from `draft` to `validated`:

| Check | Description | Failure Action |
|-------|-------------|---------------|
| Source existence | All files in `synthesis_scope` still exist and are not `archived` | Block transition; log missing sources |
| Source freshness | No files in `synthesis_scope` have been modified since synthesis creation | Block transition; transition to `stale` instead |
| Internal consistency | Key claims in synthesis do not contradict current tracker values | Block transition; flag contradictions |
| Structural completeness | Frontmatter has all required Domain C fields (`trigger_source`, etc.) | Block transition; queue for frontmatter repair |

---

## Promotion Criteria

When should synthesis be promoted (kept as `validated`/`published`) vs. archived? Derived from design brief §33.

### Promote When

- **Cross-document:** synthesis draws from 3+ source files
- **Reusable:** likely to be referenced in future processing or decision-making
- **Hard to reconstruct:** synthesis required significant analysis or multi-source correlation
- **Central to project understanding:** informs governance, milestone, or stakeholder decisions

### Archive When

- **Purely transactional:** one-time processing output with no ongoing reference value
- **Highly local and temporary:** addresses a single question that has been resolved
- **Superseded:** a newer synthesis covers the same scope with more recent data
- **Orphaned:** no other files reference this synthesis and no human has interacted with it

---

## Governance Rules

| Rule | Rationale |
|------|-----------|
| Only humans can transition to `published` | Agent consistency checks are necessary but not sufficient; human judgment confirms authority (brief §18.1) |
| Agents can transition `draft` → `validated` | Consistency checking is automated; no human judgment needed |
| Agents can transition `published` → `stale` | Staleness detection is factual (source files changed); no judgment needed |
| Agents can transition `draft` → `archived` (30-day timeout) | Unreviewed drafts older than 30 days are presumed abandoned |
| Agents can propose `stale` → `archived` but human confirms | Archival is a judgment call — the synthesis might still be useful despite stale sources |
| Published synthesis that is promoted to `controlled-truth` requires explicit human approval | Trust elevation from `interpretation` to `controlled-truth` is a governance act |

### Trust Category Transitions

| Lifecycle Transition | Trust Category Change |
|---------------------|-----------------------|
| `draft` → `validated` | Stays `interpretation` |
| `validated` → `published` | Stays `interpretation` (unless human explicitly elevates to `controlled-truth`) |
| `published` → `stale` | Stays current trust category (staleness is about freshness, not trust) |
| Any → `archived` | Changes to `historical-record` |

---

## Frontmatter Updates on Transition

When a lifecycle transition occurs, the agent updates these frontmatter fields:

```yaml
# On any transition:
lifecycle_state: <new-state>
lifecycle_changed: <today's date>
lifecycle_trigger: <what caused the transition>

# On transition to stale:
# (no additional fields — staleness is the state itself)

# On transition to archived:
trust_category: historical-record

# On transition to published with trust elevation:
trust_category: controlled-truth
```

Additionally, the agent emits an `[ECOSYSTEM_UPDATE]` inter-skill tag:

```
[ECOSYSTEM_UPDATE: path/to/file.md | LIFECYCLE_CHANGED | draft → validated | agent-consistency-check]
```

---

## Migration from Current 08-Generated/ Behavior

### Current State

- 08-Generated/ files are auto-archived after 10 business days (per CLAUDE.md File Management Protocol)
- No lifecycle states, no frontmatter, no validation checks
- Promotion is manual (user moves file to target folder)

### Migration Steps

1. **Backfill existing files:** all current 08-Generated/ files receive frontmatter with `lifecycle_state: draft`
2. **Age-based triage:**
   - Files older than 30 days with no reference from active trackers or navigation → `lifecycle_state: stale`
   - Files referenced by active trackers, navigation pages, or governance → `lifecycle_state: validated` (pending human review for promotion to `published`)
   - Files younger than 30 days → remain `draft`
3. **Disable 10-day auto-archive:** replaced by the 30-day Draft timeout and governed lifecycle transitions
4. **Preserve promotion path:** manual promotion to target folders still works; lifecycle state transfers with the file

### Backward Compatibility

- Files without frontmatter are treated as `draft` by the health check engine
- The 08-Generated/ folder remains the staging location — lifecycle management doesn't change where files live
- Existing skills that write to 08-Generated/ are enhanced (via agent-processing-contracts.md) to include Domain C frontmatter

---

## Validation Checklist

- [ ] Every file in 08-Generated/ has a `lifecycle_state` field
- [ ] No file in `published` state without a human approval event in `lifecycle_events`
- [ ] Staleness detection runs after every source file modification (Query 6)
- [ ] 30-day Draft timeout is enforced (checked daily)
- [ ] Archived files have `trust_category: historical-record`
- [ ] Archived files are excluded from active navigation views (generated-index shows only draft/validated/published)
- [ ] State transition audit trail exists in `lifecycle_events` table for every transition
- [ ] No `draft` → `published` direct transition (must pass through `validated`)
- [ ] `[ECOSYSTEM_UPDATE]` tag emitted on every transition

# Change Matrix Schema Reference

## Purpose

This reference defines the change matrix data schema, field validation rules, wave
sequencing logic, and cross-change dependency detection rules. It is the authoritative
source for the change-management skill (Mode E) when ingesting, validating, and
assessing change matrices.

## Change Matrix Data Schema

### Core Columns

| Column | Data Type | Required | Description | Validation Rules |
|--------|----------|----------|-------------|-----------------|
| **Change ID** | String (format: CHG-NNN) | Yes | Unique identifier for each discrete change | Must be unique across the matrix; auto-increment if not provided; format: CHG-001, CHG-002, etc. |
| **Change Description** | Text | Yes | Clear description of what is changing from the user's perspective | Must describe the change from the impacted audience's perspective, not the technical implementation. Minimum 10 words. |
| **Impacted Process** | Text | Yes | Business process(es) affected by this change | Must reference specific process names, not generic labels. "Order Entry" not "various processes." |
| **Impacted System** | Text | Yes | System(s) involved in the change | Must reference specific system names (e.g., "the ERP", "the WMS"). |
| **Impacted Roles** | Text (semicolon-delimited list) | Yes | Roles/groups affected by this change | Must name specific roles or groups. "All users" is invalid -- break into specific groups. Semicolon-delimited for multiple roles. |
| **Impact Severity** | Integer (1-4) | Yes | Overall impact severity per the five-dimension framework | Must be 1-4 per impact-assessment.md severity scale. Overall = max across five dimensions. |
| **Process Severity** | Integer (1-4) | Recommended | Process dimension severity | 1-4 per impact-assessment.md |
| **Technology Severity** | Integer (1-4) | Recommended | Technology dimension severity | 1-4 per impact-assessment.md |
| **People Severity** | Integer (1-4) | Recommended | People dimension severity | 1-4 per impact-assessment.md |
| **Organization Severity** | Integer (1-4) | Recommended | Organization dimension severity | 1-4 per impact-assessment.md |
| **Culture Severity** | Integer (1-4) | Recommended | Culture dimension severity | 1-4 per impact-assessment.md |
| **Wave** | Integer or String | Yes | Deployment wave assignment | Must reference a defined wave in the wave sequencing plan. |
| **Dependencies** | Text (semicolon-delimited CHG-IDs) | Recommended | Other changes this change depends on | Must reference valid Change IDs in the matrix. Circular dependencies flagged as errors. |
| **OCM Actions** | Text | Yes | Specific OCM interventions required for this change | Must be specific actions, not "TBD" or "Standard CM." Derived from severity and ADKAR assessment. |
| **Training Required** | Boolean + Text | Yes | Whether training is required and what type | If severity >= 3 on any dimension, Training Required = Yes with specific content description. |
| **Communication Required** | Boolean + Text | Yes | Whether dedicated communication is required and what type | If severity >= 2, Communication Required = Yes with audience and channel specified. |
| **Status** | Enum | Yes | Current status of this change's OCM readiness | Valid values: Not Started, In Progress, Ready, Blocked, Deferred |
| **Current State** | Text | Recommended | As-is process/behavior for impacted roles | Describes what users do today |
| **Future State** | Text | Recommended | To-be process/behavior for impacted roles | Describes what users will do after the change |
| **ADKAR Barrier Point** | Text | Recommended | First ADKAR element scoring <=3 for primary impacted group | Per impact-assessment.md ADKAR integration |
| **Go-Live Date** | Date | Recommended | Target deployment date for this change | Must be a specific date, not a range |
| **Notes** | Text | Optional | Additional context, risks, or considerations | Free text |

### Schema Summary

```
REQUIRED: Change ID, Change Description, Impacted Process, Impacted System,
          Impacted Roles, Impact Severity, Wave, OCM Actions, Training Required,
          Communication Required, Status

RECOMMENDED: Per-dimension severity (5 columns), Dependencies, Current State,
             Future State, ADKAR Barrier Point, Go-Live Date

OPTIONAL: Notes
```

## Wave Sequencing Logic

### What Is a Wave?

A wave is a group of related changes deployed together in a single release event.
Wave sequencing determines which changes deploy together and in what order, based
on dependencies, capacity, and risk.

### Sequencing Rules (Dependency-Driven)

```
RULE 1: Dependency ordering
  IF Change B depends on Change A
  THEN Wave(A) <= Wave(B)
  (A must deploy in the same wave as B or an earlier wave)

RULE 2: No circular dependencies
  IF A depends on B AND B depends on A (directly or transitively)
  THEN FLAG as ERROR -- circular dependency detected
  RESOLUTION: Break the cycle by identifying which dependency is soft
  (can be worked around) vs. hard (cannot proceed without)

RULE 3: Foundation-first
  Changes with no dependencies AND that are depended upon by other changes
  deploy in the earliest possible wave.

RULE 4: Risk-balanced waves
  No single wave should contain more than 2 Critical (severity 4) changes
  unless they are tightly coupled and must deploy together.
  RATIONALE: Concentrating high-severity changes creates cumulative risk
  and overwhelming OCM demand.
```

### Sequencing Rules (Capacity-Constrained)

```
RULE 5: OCM capacity check
  FOR each wave:
    Count changes with Training Required = Yes
    Count impacted roles across all changes in wave
    IF training capacity cannot cover all groups before wave go-live
    THEN redistribute changes to balance training load across waves

RULE 6: Super user capacity check
  FOR each wave:
    Sum impacted users across all changes
    Calculate required super user count at 1:8 go-live ratio
    IF available super users < required count
    THEN redistribute changes or extend wave deployment window

RULE 7: Stakeholder group load balancing
  FOR each stakeholder group:
    Count changes impacting this group in each wave
    IF any group has > 3 changes in a single wave
    THEN consider splitting the wave or deferring lower-severity changes
    REFERENCE: Cumulative change load assessment from impact-assessment.md
```

### Wave Assignment Decision Table

| Scenario | Wave Assignment | Rationale |
|----------|----------------|-----------|
| Change has no dependencies and is depended upon | Wave 1 (foundation) | Must be in place before dependent changes |
| Change depends on Wave 1 changes only | Wave 2 | Earliest possible after dependencies |
| Change depends on changes in multiple waves | Wave N+1 (where N = latest dependency wave) | Cannot deploy until all dependencies are met |
| Change is independent (no dependencies, not depended upon) | Assign to wave with lowest load for impacted groups | Balances capacity without constraint |
| Change is Critical severity and independent | Separate wave or isolated within a wave | Reduces blast radius; dedicated OCM focus |
| Change is deferred | Wave = "Deferred" | Removed from sequencing; tracked separately |

## Cross-Change Dependency Detection Rules

### Automatic Detection (during ingestion)

| Detection Rule | Signal | Action |
|---------------|--------|--------|
| **Same system, same process** | Two changes affect the same system AND the same process | Flag as potential dependency; require human confirmation |
| **Same role group** | Two changes list the same impacted role | Flag for cumulative load assessment; consider sequencing to avoid simultaneous impact |
| **Sequential process steps** | Change A affects step N of a process, Change B affects step N+1 | Flag as likely dependency; A should deploy before or with B |
| **Shared data entity** | Two changes modify the same data entity (customer master, item master, etc.) | Flag as dependency; data migration sequencing required |
| **Training prerequisite** | Change B's training content requires knowledge from Change A | Flag as training dependency; A's training must precede B's |

### Dependency Classification

| Type | Definition | Sequencing Impact |
|------|-----------|------------------|
| **Hard** | Change B cannot function without Change A deployed | A must be in an earlier or same wave as B |
| **Soft** | Change B benefits from Change A but can function with workaround | Prefer A before B; document workaround if B deploys first |
| **Training** | Change B's training requires knowledge from Change A | A's training must complete before B's training begins |
| **Data** | Change B requires data migration or configuration from Change A | A's data changes must be validated before B deploys |
| **Communication** | Change B's messaging depends on audience understanding of Change A | A's communications must be sent before B's |

### Circular Dependency Resolution

When a circular dependency is detected:

1. **Identify the cycle:** List all changes in the cycle (A -> B -> C -> A)
2. **Classify each dependency:** Hard or Soft?
3. **Break at the softest point:** The soft dependency becomes a workaround-documented deployment sequence
4. **If all dependencies are hard:** The changes must deploy in the same wave as a coupled set; document the coupling rationale
5. **Flag for review:** All circular dependency resolutions require human review before wave assignment is finalized

## Ingestion Validation Rules

### Field-Level Validation

| Field | Validation Rule | Error Level | Auto-Fix |
|-------|----------------|-------------|----------|
| Change ID | Unique; format CHG-NNN | Error (blocks) | Auto-assign if missing |
| Change Description | Non-empty; >= 10 words; audience-perspective language | Warning | Cannot auto-fix; flag for review |
| Impacted Roles | Non-empty; no "All users"; semicolon-delimited | Error (blocks) | Cannot auto-fix; flag for remediation |
| Impact Severity | Integer 1-4 | Error (blocks) | Cannot auto-fix if out of range |
| Wave | References defined wave | Warning | Flag unassigned for sequencing |
| Dependencies | References valid Change IDs; no circular deps | Error (circular); Warning (invalid ref) | Flag invalid refs; block on circular |
| OCM Actions | Non-empty; not "TBD" or "Standard CM" | Warning | Flag for remediation |
| Training Required | Boolean; if severity >= 3 then must be Yes | Warning (if severity >= 3 and No) | Flag inconsistency |
| Communication Required | Boolean; if severity >= 2 then must be Yes | Warning (if severity >= 2 and No) | Flag inconsistency |
| Status | Valid enum value | Error (blocks) | Default to "Not Started" if missing |

### Matrix-Level Validation

| Validation Rule | Detection Method | Error Level |
|----------------|-----------------|-------------|
| **Completeness: all required fields populated** | Scan all rows for empty required fields | Error per row with empty required field |
| **Severity distribution plausibility** | Check that severity distribution is not all-same (all 1s or all 4s) | Warning: "Uniform severity detected -- verify each change assessed independently" |
| **Audience coverage** | Compare impacted roles in matrix against known stakeholder map | Warning for any stakeholder group in map but not in matrix |
| **Dependency cycle detection** | Graph traversal (DFS) on dependency relationships | Error: "Circular dependency detected: [cycle path]" |
| **Wave-dependency consistency** | Verify Wave(dependency) <= Wave(dependent) for all dependency pairs | Error: "Wave assignment violates dependency ordering: CHG-X (Wave 3) depends on CHG-Y (Wave 4)" |
| **Orphan changes** | Changes with no wave assignment | Warning: "N changes have no wave assignment" |
| **Duplicate detection** | Changes with >80% text similarity in Description + Process + System | Warning: "Potential duplicates detected: CHG-X and CHG-Y" |

### Completeness Scorecard Output

After validation, produce a completeness scorecard:

| Dimension | Score | Status | Finding |
|-----------|-------|--------|---------|
| **Row completeness** | X% of rows have all required fields | Green >=95% / Amber 80-94% / Red <80% | N rows with missing fields |
| **Severity coverage** | X% of rows have severity assessed | Green >=95% / Amber 80-94% / Red <80% | N rows without severity |
| **Per-dimension severity** | X% of rows have all 5 dimension severities | Green >=80% / Amber 50-79% / Red <50% | N rows with partial dimension coverage |
| **Audience coverage** | X% of known stakeholder groups represented | Green >=90% / Amber 70-89% / Red <70% | N groups missing from matrix |
| **Dependency documentation** | X% of flagged potential dependencies have explicit dependency entries | Green >=80% / Amber 50-79% / Red <50% | N potential dependencies undocumented |
| **Wave assignment** | X% of changes have wave assigned | Green >=90% / Amber 70-89% / Red <70% | N changes without wave |
| **OCM action specificity** | X% of rows have specific OCM actions (not "TBD") | Green >=90% / Amber 70-89% / Red <70% | N rows with generic OCM actions |

## Anti-Patterns

| Anti-Pattern | Signal | Root Cause | Remediation |
|-------------|--------|-----------|-------------|
| **Technology-only matrix** | Only system and process columns populated; People, Organization, Culture dimensions blank | Treating the change matrix as a technical deployment tracker rather than an organizational change tool | Require all five dimension severity columns; flag rows with blank people/org/culture dimensions |
| **"TBD" OCM actions** | OCM Actions column contains "TBD", "Standard CM", or "N/A" for severity >= 2 changes | OCM planning deferred; matrix completed as a compliance exercise | Flag every "TBD" OCM action for changes with severity >= 2; produce specific OCM action recommendations based on severity and ADKAR assessment |
| **"All users" audience** | Impacted Roles column contains "All users" or "Everyone" | No stakeholder segmentation; one-size-fits-all approach | Block on ingestion; require specific role/group names; provide stakeholder map as reference |
| **No dependency tracking** | Dependencies column empty across all rows | Dependencies not assessed; each change planned in isolation | Run automatic dependency detection rules; flag potential dependencies for human review |
| **Static matrix** | Matrix created once and never updated; dates stale; status not current | Treated as a planning document rather than a living tracker | Set review cadence matched to methodology; flag rows where Status = "In Progress" and Go-Live Date is past |
| **Uniform severity** | All changes scored the same severity (e.g., all "2" or all "3") | No differentiated assessment; political smoothing of severity ratings | Flag when >80% of rows have the same severity; require independent reassessment |

## Behavioral Markers

| Dimension | Principal Behavior | Junior Behavior |
|-----------|-------------------|----------------|
| **Schema enforcement** | Validates all required fields on ingestion; flags gaps with specific remediation; does not accept "TBD" for OCM actions on severity >= 2 changes | Accepts incomplete matrices without flagging gaps; allows "TBD" throughout |
| **Dependency detection** | Runs cross-change dependency analysis; identifies potential dependencies from shared systems, processes, and roles; resolves circular dependencies | Treats each change as independent; does not analyze cross-change relationships |
| **Wave sequencing** | Sequences waves based on dependency ordering, capacity constraints, and cumulative load per stakeholder group | Assigns waves arbitrarily or by go-live date only; ignores capacity and dependencies |
| **Five-dimension coverage** | Requires per-dimension severity scores; flags rows with only technology severity populated | Accepts overall severity without dimension breakdown; defaults to technology-only assessment |
| **Completeness assessment** | Produces quantified completeness scorecard with specific findings and remediation per dimension | Declares matrix "complete" or "incomplete" without specific findings |

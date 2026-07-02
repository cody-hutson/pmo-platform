# Routing Patterns — File Classification Rules

This file is the complete reference for all file classification patterns used by the File Router.
It is self-updating: when a user corrects a misclassification, the File Router proposes an update
to this file via the IMPROVEMENTS.md workflow.

**Version:** 1.1
**Last updated:** 2026-07-01

---

## Transcripts (→ 05-Transcripts/)

| Pattern | Sub-folder | Confidence Boost | Content Indicators |
|---------|-----------|-----------------|-------------------|
| Filename: `AM Testing YYYY-MM-DD*` | AM-Testing/ | +20% | Morning testing session, QA discussion |
| Filename: `PM Testing YYYY-MM-DD*` | PM-Testing/ | +20% | Afternoon testing session |
| Filename: `Daily Connect YYYY-MM-DD*` | Daily-Connects/ | +20% | Daily standup, status round-robin |
| Filename: `*Weekly [Ss]tatus [Rr]eport*` | Weekly-Status/ | +20% | Weekly cadence, cross-team updates |
| Filename: `*[Mm]onday [Tt]ouch [Bb]ase*` | Touch-Base/ | +20% | Touch base format, planning discussion |
| Filename: `*SteerCo*` or `*Steering*` | Topic-Sessions/ | +15% | Steering committee, executive review |
| Content: Speaker labels + timestamps | (determine from content) | +30% | Standard transcript format |
| Content: "Transcription Export" suffix | (determine from content) | +25% | Sembly export format |
| Default transcript (no pattern match) | Topic-Sessions/ | — | Fallback for recognized transcripts |

## Emails (→ 06-Emails/)

| Pattern | Target | Confidence Boost | Content Indicators |
|---------|--------|-----------------|-------------------|
| Filename: `FW_*` or `RE_*` | 06-Emails/ | +15% | Forwarded/replied email |
| Filename: `QA*UAT*status*` (PDF) | 06-Emails/ | +15% | QA/UAT status report email |
| Content: From:/To:/Subject: headers | 06-Emails/ | +25% | Email format |
| Content: Daily digest format | 06-Emails/ | +20% | End-of-day summary |

## Design Documents (→ 02-Design/)

| Pattern | Sub-folder | Confidence Boost | Content Indicators |
|---------|-----------|-----------------|-------------------|
| Filename: `FDD*` or `*Functional Design*` | FDDs/ | +15% | FDD section structure |
| Content: Business rules, system behavior, functional specs | FDDs/ | +20% | Functional specification |
| Filename: `*Process Flow*` | Process Flows/ | +15% | Flow diagrams, swim lanes |
| Content: Training objectives, learning outcomes | Training/ | +20% | Training material |

## Governance (→ 01-Governance/)

| Pattern | Confidence Boost | Content Indicators |
|---------|-----------------|-------------------|
| Filename: `*Cutover*` or `*Go-Live*` | +15% | Cutover checklist, go-live plan |
| Filename: `*Communication Plan*` | +15% | Stakeholder comm plan |
| Filename: `*Decision Deck*` | +15% | Decision log or deck |
| Content: Phase gates, milestones, approval workflow | +20% | Governance document |

## Testing (→ 03-Testing/)

| Pattern | Sub-folder | Confidence Boost | Content Indicators |
|---------|-----------|-----------------|-------------------|
| Jira export (CSV with Key, Summary, Status columns) | Jira Export/ | +25% | Jira data structure |
| Filename: `*Test Plan*` or `*Test Exit*` | (root) | +15% | Test documentation |
| Content: Test case IDs, steps, expected/actual | (root) | +20% | Test artifact |

## Reference (→ 07-Reference/)

| Pattern | Confidence Boost | Content Indicators |
|---------|-----------------|-------------------|
| Filename: `*SOP*` or `*Runbook*` | +15% | Standard operating procedure |
| Content: Step-by-step procedure, operational guide | +15% | Reference material |
| Filename: `*Glossary*` or `*Key Terms*` | +15% | Terminology reference |

## Change Management (→ 02-Design/ or 01-Governance/)

| Pattern | Target | Confidence Boost | Content Indicators |
|---------|--------|-----------------|-------------------|
| Content: Impact assessment, role impact matrix | 02-Design/ | +20% | Change management artifact |
| Content: Training plan, hypercare plan | 02-Design/Training/ | +20% | Training/readiness |
| Content: Readiness checklist, adoption tracking | 01-Governance/ | +15% | Go-live readiness |

## PMO Operations (→ 04-PMO-Operations/)

| Pattern | Confidence Boost | Content Indicators |
|---------|-----------------|-------------------|
| Content: Carry-forward items, blocker tracking | +20% | Status log format |
| Content: MSG-### entries, communication tracking | +20% | Communications tracker |
| Content: MTG-### entries, meeting scheduling | +20% | Meetings tracker |

---

## Movement-Direction Rules

The pattern tables above (Transcripts → PMO Operations) are all **direction 1 — Inbound**: classifying a fresh `Context-Captured` arrival into the *active* project's `01-08` tree (drives `Context-Captured → Context-Structured`, mechanism 1 of the [Context Lifecycle Model](../../../../core/disciplines/context-lifecycle-model.md)). The three sections below cover the other three movement directions the File Router governs. Each cites the lifecycle state(s) it drives; the two Domain-C directions **cite** the owning machinery rather than restating it (the `promotion_state` field lives in [`core/schemas/frontmatter-schema.md` § Domain C](../../../../core/schemas/frontmatter-schema.md); the promotion-location protocol is [`core/artifact-workflow-protocol.md` §4](../../../../core/artifact-workflow-protocol.md), Stage-6-current).

### Generated-file staging (direction 2 → 08-Generated/)

| Rule | Target | Gate | Lifecycle state driven |
|------|--------|------|-----------------------|
| A skill emits a synthesized artifact | `08-Generated/` | Tier-2 auto-write (no confidence, no approval) | Domain-C: `(none) → promotion_state: staged` (co-stamped with `lifecycle_state: draft` on emit) |

- Staging is a **file-router-governed action**, not an ad-hoc write: the emitting skill's declared target folder is recorded in the artifact's metadata header for later promotion.
- **Owner of the emit + stamp:** `artifact-generator` (stamps `lifecycle_state: draft` + `promotion_state: staged`). file-router records the staging placement and cites the field — it does not restate the `promotion_state` enum.
- Cited state basis: [`frontmatter-schema.md` § Domain C](../../../../core/schemas/frontmatter-schema.md) (live `promotion_state` field); protocol [`artifact-workflow-protocol.md` §4](../../../../core/artifact-workflow-protocol.md) (Stage-6-current).

### Promotion (direction 3 → 08-Generated/ to target folder)

| Rule | Target | Gate | Lifecycle state driven |
|------|--------|------|-----------------------|
| Operator promotes a staged artifact | The artifact's declared target folder (from its metadata header) | **Flat approval** — required before writing to a non-auto-write folder (01-Governance/, 02-Design/, 03-Testing/, 04-PMO-Operations/, 07-Reference/); aligned to the CLAUDE.md auto-write list | Domain-C: `promotion_state: staged → promoted` |

- file-router **resolves the target and enforces the approval gate**, carrying the artifact's document identity + version fields (already in the frontmatter schema) into target resolution. **Versioning is delegated** to those fields — no parallel version scheme.
- file-router **does NOT move the file and does NOT stamp `promotion_state`**: it cites and defers to the PROMOTE / REVISE / REJECT gate + `## Promotion Workflow` in [`artifact-generator/SKILL.md`](../../artifact-generator/SKILL.md), which owns the physical staged→promoted move and the `promotion_state: promoted` stamp ("the move IS the authorization").
- No confidence variable: the target was pre-stamped at staging, so this is a flat approve/reject, not a HIGH/MEDIUM/LOW decision.
- Cited state basis: [`frontmatter-schema.md` § Domain C](../../../../core/schemas/frontmatter-schema.md); protocol [`artifact-workflow-protocol.md` §4](../../../../core/artifact-workflow-protocol.md) (Stage-6-current).

### Cross-project routing (direction 4 → out to another project's tree)

| Rule | Target | Gate | Lifecycle state driven |
|------|--------|------|-----------------------|
| Layer-2 resolves the file to a project **other than** the active project | `<winning-project>/<01-08 subfolder per classification>` | **Confidence-threshold** (Layer-2 scored) **+ mandatory approval** — a cross-project write is always approval-gated, even into that project's 05/06/08 auto-write folders | Context: `Context-Captured → Context-Structured` **in the target project's tree** (mechanism 1 at cross-project altitude) |

- Resolver: (1) score all active PROJECT.md files; (2) if the winner ≠ active project **and** the top-two gap is ≥ 10 points, resolve to the winning project's `01-08` tree; (3) if the gap is < 10 points, it is a tie — present both and ask.
- **The new gate this skill owns:** auto-write is scoped to the *active* project, so a cross-project placement is never an auto-write. Surface the route for approval with the winning-project score and the second-place gap; write only on confirmation.
- Cited state basis: [`context-lifecycle-model.md` §5](../../../../core/disciplines/context-lifecycle-model.md) — the resolver decides *which project's* Context machine advances.

---

## Special Rules

### Single-Source Recording Detection
When a transcript shows only one speaker but content references multiple viewpoints:
- Flag as `[SINGLE-SOURCE RECORDING]`
- Extract participants from content mentions, not speaker attribution
- Note in Transcript Register entry

### Non-Project Files
Files that match no active project and contain no project-related content:
- 1:1 meetings, personal discussions, general company meetings
- Route to `Non-Project/` folder at workspace root
- Or discard per user preference setting

### Ambiguous Multi-Project Files
Files referencing multiple projects (cross-project meetings, shared resources):
- Present all matching projects with confidence scores
- User selects primary project
- Note cross-references in routing summary

---

## Version History

| Date | Change | Evidence |
|------|--------|---------|
| 2026-03-18 | Initial creation from Phase 1 routing-rules.md | Phase 2, Task 2.1 |
| 2026-07-01 | Added Movement-Direction Rules (generated-staging 2, promotion 3, cross-project 4); framed the existing pattern tables as inbound direction 1. Each new direction cites its Context Lifecycle Model state(s); Domain-C directions cite `frontmatter-schema.md`/`artifact-workflow-protocol.md` and `artifact-generator` rather than restating. | govern-all-movements change, release v3.46 |

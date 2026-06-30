---
title: Health Check Specification — Document Ecosystem Integrity
purpose: Defines every health check the agent runs on the document ecosystem — validating metadata integrity, freshness, coverage, relationship, and navigation consistency, with zero orphans as the primary KPI.
type: spec
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the health-check skill (every ecosystem health check); the document-ecosystem integrity KPIs; the SQLite index and navigation-layer consumers
---
# Health Check Specification — Document Ecosystem Integrity

## Purpose

Defines all health checks the agent performs on the document ecosystem. Health checks validate the integrity, freshness, coverage, and consistency of the ecosystem's metadata, relationships, lifecycle states, and navigation layer. Zero orphans is the primary KPI.

**Source:** Phase 4 Design
**Grounding:** Design brief §30 (9 conceptual health checks), §25-26 (healthy/unhealthy ecosystem behaviors); C12 anti-patterns (zombie artifacts, stale references, documentation debt); Prototype finding 4 (zero orphans target, 99.6% achieved)
**Cross-references:** `sqlite-index-schema.md` (query patterns), `frontmatter-schema.md` (validation rules), `domain-c-lifecycle-protocol.md` (lifecycle compliance), `navigation-layer-schema.md` (coverage validation)

## Consumers

| Consumer | Purpose |
|----------|---------|
| Health check engine | Executes checks on schedule |
| Navigation layer | Surfaces health metrics in Portfolio Dashboard and Project Hub |
| Weekly Status Roll-Up | Incorporates ecosystem health into executive reporting |
| Human governance | Reviews health reports, triages remediation |

---

## Health Check Inventory

### Check 1: Orphan Detection

**C12 Anti-Pattern:** #1 (Zombie Artifacts) — files that exist but serve no purpose in the ecosystem.

| Attribute | Value |
|-----------|-------|
| **Definition** | A file in Projects/[Project]/01-08/ with zero inbound or outbound relationships in the index |
| **Severity** | Critical |
| **KPI** | Orphan count = 0 is the target |
| **Schedule** | After every processing cycle |
| **Query** | SQLite Query 2 (orphan detection) — `LEFT JOIN relationships WHERE no match on source or target` |
| **Exclusions** | Navigation pages (`_pmo/`), governance files (`_governance/`), sidecar `.meta.yml` files |
| **Remediation** | Queue orphan file for File Router re-processing to establish initial frontmatter and BELONGS_TO relationship |
| **Escalation** | If orphan count > 0 after two consecutive daily runs, flag in Portfolio Dashboard |

### Check 2: Staleness Scoring

**C12 Anti-Pattern:** #5 (Stale Reference) — files that appear current but reference outdated information.

| Attribute | Value |
|-----------|-------|
| **Definition** | Files with `lifecycle_state` indicating active status but no modification or relationship activity within domain-specific threshold |
| **Severity** | High |
| **Schedule** | Daily |
| **Query** | SQLite Query 3 (staleness score) — weighted combination of days since modified, lifecycle changed, evidence incorporated |
| **Thresholds** | Domain A: 30 days (source artifacts age naturally — flag but don't transition). Domain B: `staleness_threshold_days` from frontmatter (default 14). Domain C: per `domain-c-lifecycle-protocol.md`. |
| **Remediation** | Domain B: transition `current` → `needs-review`. Domain C: transition `published` → `stale`. Domain A: flag for human review (no automatic transition). |
| **Metrics** | Distribution of staleness scores by domain and project (histogram in health report) |

### Check 3: Contradiction Detection

**Design Brief §30:** Contradictions between synthesis and evidence.

| Attribute | Value |
|-----------|-------|
| **Definition** | Published synthesis artifacts (Domain C) making claims inconsistent with current source state |
| **Severity** | Critical |
| **Schedule** | Weekly |
| **Scope** | Only `published` Domain C files (draft/validated are checked during validation, not health check) |
| **Detection Approach** | Compare key claims in synthesis against current tracker values. Three comparison methods: |
| | 1. **Status comparison:** health/phase/state claims in synthesis vs. current PROJECT.md and tracker state |
| | 2. **Date comparison:** milestone/deadline dates in synthesis vs. current plan dates |
| | 3. **Count comparison:** numeric claims (entry counts, risk counts) vs. current tracker values |
| **Remediation** | Transition `published` → `stale`, flag specific contradictions for human review |
| **Escalation** | Contradictions in `published` synthesis used for stakeholder communication → P1 escalation |

### Check 4: Relationship Integrity

**Design principle:** Relationships are first-class citizens that must resolve to existing files.

| Attribute | Value |
|-----------|-------|
| **Definition** | Relationships in the index pointing to files that no longer exist, have been archived, or have invalid file_ids |
| **Severity** | Medium |
| **Schedule** | After every processing cycle |
| **Query** | `JOIN relationships r ON r.target_file_id = f.file_id WHERE f.file_id IS NULL OR f.lifecycle_state = 'archived'` |
| **Remediation** | Remove broken relationship from source file's frontmatter. Flag source file for review if it lost a DEPENDS_ON or BLOCKS relationship. |
| **Metrics** | Broken relationship count, broken relationship rate (broken / total) |

### Check 5: Frontmatter Completeness

**Frontmatter schema contract:** Every file must have required core fields populated.

| Attribute | Value |
|-----------|-------|
| **Definition** | Files with missing required frontmatter fields (type, managed_by, lifecycle_state, trust_category, domain, file_format, project, folder) |
| **Severity** | Medium |
| **Schedule** | After every processing cycle |
| **Query** | SQLite Query 7 (frontmatter completeness check) |
| **Remediation** | Queue file for File Router re-processing (frontmatter repair). If File Router already processed the file, escalate as a contract violation. |
| **Metrics** | Completeness rate (files with all required fields / total files) |

### Check 6: Domain C Lifecycle Compliance

**Domain C Lifecycle Protocol:** Enforces state transitions, timeouts, and governance rules.

| Attribute | Value |
|-----------|-------|
| **Definition** | 08-Generated/ files violating lifecycle protocol rules |
| **Severity** | High |
| **Schedule** | Daily |
| **Checks** | |
| | 1. **Draft timeout:** `draft` files older than 30 days → should be `archived` |
| | 2. **Published without approval:** `published` files without a human approval event in `lifecycle_events` |
| | 3. **Stale not flagged:** `published` files where source files have changed (Query 6) but state is still `published` |
| | 4. **Invalid trust-lifecycle:** `draft` files with `trust_category: controlled-truth` (prohibited) |
| | 5. **Archived without historical:** `archived` files with `trust_category` not equal to `historical-record` |
| **Remediation** | Execute lifecycle transition per protocol. Draft timeout → archive. Stale not flagged → transition to stale. Trust violations → correct trust_category. |
| **Metrics** | Lifecycle compliance rate, draft timeout violations, stale detection lag (days between source change and stale transition) |

### Check 7: Navigation Coverage

**Prototype target:** 99.6% → 100% (zero files missing from navigation).

| Attribute | Value |
|-----------|-------|
| **Definition** | Source files (01-08) not appearing in any navigation page |
| **Severity** | Medium |
| **Schedule** | Daily (during full rebuild) |
| **Detection** | Compare files in `files` table against wiki-link targets in navigation pages. Files not referenced by any navigation page are uncovered. |
| **Distinction from Check 1:** | A file may have relationships (not an orphan) but still not appear in any navigation page (not covered). Check 1 validates the relationship graph. Check 7 validates the human-visible navigation layer. |
| **Remediation** | Trigger navigation page refresh for the affected folder/project |
| **Metrics** | Coverage rate (files in navigation / total files), uncovered file list |

### Check 8: Supersession Consistency

**Design brief §15:** Superseded files must form valid chains.

| Attribute | Value |
|-----------|-------|
| **Definition** | Files with `SUPERSEDES` relationships that form broken or circular chains |
| **Severity** | Medium |
| **Schedule** | Weekly |
| **Checks** | |
| | 1. **Dangling supersession:** `superseded_by` points to a file that doesn't exist |
| | 2. **Circular chains:** file A supersedes B, B supersedes A |
| | 3. **Inconsistent lifecycle:** superseded file has `lifecycle_state` other than `superseded` or `archived` |
| | 4. **Active chain terminal:** the final file in a supersession chain is in an active state (`active`, `current`, `published`) |
| **Remediation** | Flag for human review (supersession is a semantic judgment) |
| **Metrics** | Supersession chain count, broken chain count |

### Check 9: Trust Category Validation

**Design brief §14:** Trust categories must be consistent with domain and lifecycle.

| Attribute | Value |
|-----------|-------|
| **Definition** | Files with `trust_category` inconsistent with their `domain` or `lifecycle_state` |
| **Severity** | Low |
| **Schedule** | Weekly |
| **Rules** | |
| | 1. `archived` lifecycle → trust must be `historical-record` |
| | 2. `superseded` lifecycle → trust must be `historical-record` |
| | 3. Domain C `draft` → trust cannot be `controlled-truth` |
| | 4. Domain A `active` → trust should be `evidence` (warn if not) |
| | 5. Domain B `current` → trust should be `controlled-truth` (warn if not) |
| **Remediation** | Rules 1-3: correct trust_category automatically. Rules 4-5: warn only (human may have intentionally set a different trust level). |
| **Metrics** | Trust consistency rate, auto-corrected count |

---

## Execution Schedule

| Cadence | Checks | Rationale |
|---------|--------|-----------|
| **After every processing cycle** | 1 (orphans), 4 (relationship integrity), 5 (frontmatter completeness) | Fast, index-only queries. Catch issues immediately after agent processing. |
| **Daily** | 2 (staleness), 6 (Domain C lifecycle), 7 (navigation coverage) | Moderate complexity. Full index scan. Doubles as daily rebuild trigger. |
| **Weekly** | 3 (contradictions), 8 (supersession), 9 (trust validation) | Complex checks requiring content comparison or chain traversal. |

---

## Reporting Format

### Health Dashboard (Portfolio Level)

Displayed in the Portfolio Dashboard navigation page (`_pmo/portfolio.md`).

```markdown
## Ecosystem Health

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Orphan Count | {n} | 0 | {R/Y/G} |
| Coverage Rate | {n}% | 100% | {R/Y/G} |
| Staleness Distribution | {n} stale / {total} | < 5% | {R/Y/G} |
| Contradiction Count | {n} | 0 | {R/Y/G} |
| Frontmatter Completeness | {n}% | 100% | {R/Y/G} |
| Domain C Lifecycle Compliance | {n}% | 100% | {R/Y/G} |

Last health check: {timestamp}
```

### Project Health (Project Level)

Displayed in Project Hub navigation pages (`_pmo/projects/{project}.md`).

```markdown
## Document Health

| Metric | Value |
|--------|-------|
| Total Files | {n} |
| With Frontmatter | {n} ({pct}%) |
| Orphans | {n} |
| Stale Files | {n} |
| Domain A / B / C | {a} / {b} / {c} |
| Published Synthesis | {n} |
| Draft (pending review) | {n} |
```

### Health Status Thresholds

| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Orphan Count | 0 | 1-5 | > 5 |
| Coverage Rate | 100% | 95-99% | < 95% |
| Staleness (% stale) | < 5% | 5-15% | > 15% |
| Contradiction Count | 0 | 1-2 | > 2 |
| Frontmatter Completeness | 100% | 90-99% | < 90% |
| Lifecycle Compliance | 100% | 90-99% | < 90% |

### Trend Reporting

Week-over-week trend for each metric, displayed in the Weekly Status Roll-Up.

| Metric | This Week | Last Week | Trend |
|--------|-----------|-----------|-------|
| Orphans | {n} | {n-1} | {direction indicator} |
| Coverage | {pct}% | {pct-1}% | {direction indicator} |

---

## Remediation Priority

| Priority | Checks | Rationale | Response Time |
|----------|--------|-----------|---------------|
| **P1 (immediate)** | 1 (orphans), 3 (contradictions) | Trust and completeness KPIs — directly impact reliability of the navigation layer and published synthesis | Next processing cycle |
| **P2 (daily)** | 2 (staleness), 6 (lifecycle compliance) | Decay prevention — catching these early prevents cascade into contradictions | Same business day |
| **P3 (weekly)** | 4, 5, 7, 8, 9 (integrity, completeness, coverage, supersession, trust) | Hygiene and consistency — important for long-term health but not immediately trust-breaking | Within 5 business days |

---

## Relationship to Platform Health Check

The Platform Health Check (cross-domain drift, stale references, governance contradictions) addresses health checks at the platform level (governance files, skills, cross-domain sync). This specification addresses health checks at the document ecosystem level (project files, relationships, navigation).

The two are complementary:
- Platform Health Check: governance file drift, skill sync, cross-domain references
- This spec checks: file metadata integrity, relationship graphs, lifecycle compliance, navigation coverage

Both feed into the Portfolio Dashboard but measure different aspects of platform health.

---

## Validation Checklist

- [ ] All 9 checks have documented detection logic (query or algorithm)
- [ ] Orphan detection excludes the correct file types (navigation pages, governance, sidecars)
- [ ] Staleness thresholds are configurable per domain and per file (via `staleness_threshold_days`)
- [ ] Contradiction detection has at least 3 implemented comparison methods (status, date, count)
- [ ] Health report format integrates with navigation layer (Portfolio Dashboard and Project Hub)
- [ ] Remediation actions reference the correct skills and protocols
- [ ] Execution schedule assigns every check to a cadence (per-cycle, daily, weekly)
- [ ] Health status thresholds define Green/Yellow/Red for every metric
- [ ] Trend reporting format supports week-over-week comparison
- [ ] Relationship to the Platform Health Check is documented (no overlap, complementary scope)

# Navigation Layer Schema — View Generation Specification

## Purpose

Defines how navigation pages are generated, structured, and refreshed. Navigation pages are agent-maintained markdown files that organize source files for human consumption across a 4-level PMO hierarchy: Portfolio → Program → Project → Team. Navigation is the Presentation Layer of the document ecosystem — one rendering of the Schema Layer's entity model.

**Grounding:** Prototype evaluation (7 iterations, 488 files); Design brief §17 (navigation model); C02 (15-stage lifecycle), C05 (roles), C06 (portfolio management), C12 (artifact catalogs per gate)
**Cross-references:** `frontmatter-schema.md` (Schema Layer — entity definitions), `sqlite-index-schema.md` (Storage Layer — queries), `agent-processing-contracts.md` (tag application), `document-ecosystem-design.md` §Three-Layer Architecture

## Consumers

| Consumer | Purpose |
|----------|---------|
| Navigation generator | Produces and refreshes pages from index queries |
| Human users | Browse in Obsidian, file explorer, or other markdown viewers |
| Health check engine | Validates coverage (every source file appears in at least one page) |
| Other presentation targets | Teams messages, status reports, and CLI queries use the same Schema/Storage layers but different rendering — this spec defines only the Obsidian rendering |

---

## Three-Layer Context

This schema defines the **Presentation Layer** — how entity data is rendered for human consumption in an Obsidian vault.

| Layer | Concern | This Spec's Role |
|-------|---------|-------------------|
| Schema | What entities exist, what fields they have | References `frontmatter-schema.md` — does not redefine entities |
| Storage | How the agent persists data (frontmatter, index) | References `sqlite-index-schema.md` for queries — does not define storage |
| **Presentation** | **How humans see entity data** | **This spec — defines page types, templates, hierarchy, refresh model** |

Changes to this spec (page layout, sections, callouts) do not affect the Schema or Storage layers. Changes to the Schema (new entity type) require a new page type or template here.

---

## Navigation Hierarchy

The navigation mirrors real-world PMO structure across 4 levels. Each level answers a different question and has its own page types.

```
Level 1: Portfolio           ← "Are we investing in the right things?"
  └─► Level 2: Program       ← "Are the projects delivering together?"
       └─► Level 3: Project   ← "Are we building it right?"
            └─► Level 4: Team  ← "Who's doing what?"
```

**Folder structure in the vault:**

```
_pmo/
├── 1-Portfolio/
│   ├── Portfolio Dashboard.md
│   └── Cross-Project Dependencies.md
├── 2-Program/
│   ├── {Program Name}.md
│   └── Systems/
│       └── {System Name}.md          ← one per system, shared across projects
├── 3-Project/
│   └── {Project Name}/
│       ├── {Project Name}.md         ← project hub
│       ├── Phases/
│       │   └── {Phase Name}.md       ← one per active/upcoming phase
│       ├── Workstreams/
│       │   └── {Workstream Name}.md  ← one per workstream
│       ├── RAID/
│       │   └── {ID} {Description}.md ← one per active risk/issue
│       └── Synthesis/
│           └── Synthesis.md          ← Domain C lifecycle index
├── 4-Team/
│   └── Team Directory.md            ← computed accountability view
└── Source-Files/
    └── {Project}_{Folder}.md         ← folder indexes (supporting)
```

**Key structural rules:**
- Entity pages (risks, workstreams, phases) belong to their project — not shared across projects
- Cross-project entities (shared dependencies, shared systems) live at Program or Portfolio level
- Team Directory is a single computed page, not individual person files
- Source file indexes are supporting navigation, not primary

---

## Level 1: Portfolio

**Question:** Are we investing in the right things?
**Audience:** Executive sponsors, portfolio governance board
**Grounding:** C06 (portfolio lifecycle — 8 stages), C01 (Tier 1 governance)

### Page Types

| Page | Content | Refresh Trigger |
|------|---------|-----------------|
| **Portfolio Dashboard** | Per-project health (R/Y/G), active risk count, cross-project risks (escalated Critical/High), resource contention (people active across multiple projects) | Weekly or on project health change |
| **Cross-Project Dependencies** | What gates what, shared resource conflicts, constraint map | On dependency change |

### Portfolio Dashboard Template

```markdown
# Portfolio Dashboard

Program: [[{Program Name}]]

## Project Health

- [[{Project}]] — {file_count} files, {active_risk_count} active risks ({health})

## Cross-Project Risks

{count} critical/high risks across portfolio. See project RAID pages.

## Resource Contention

- [[{Person}]] — active across {project_list}

## Navigation

- [[Cross-Project Dependencies]]
- [[{Program Name}]]
```

**Node sizing:** Portfolio Dashboard is a medium hub — links to projects and program, not to individual files.

---

## Level 2: Program

**Question:** Are the projects delivering together?
**Audience:** Program managers, technical leads
**Grounding:** C06 (program management), C14 (release engineering)

### Page Types

| Page | Content | Refresh Trigger |
|------|---------|-----------------|
| **Program Hub** | All projects in program, shared systems, escalated risks (count, not individual links), integration points | On project health change |
| **System Page** (one per system) | Role, version, workstreams that use it, related projects | On system configuration change |

### System Page Template

```markdown
# {System Name}

Program: [[{Program Name}]]

**Role:** {description}
**Version:** {version if applicable}

## Used By Workstreams

- [[{Workstream Name}]]

## Related Projects

- [[{Project Name}]]
```

**Programs vs Systems distinction:** A Program is a governance/delivery construct (manages projects). A System is a technology platform (projects implement against it). Systems are shared infrastructure — one page per system, referenced from both Program and Project levels. A system page exists once, not per-project.

---

## Level 3: Project

**Question:** Are we building it right?
**Audience:** Project managers, delivery leads, workstream leads
**Grounding:** C02 (15-stage universal lifecycle), C12 (artifact catalogs per gate), C07 (RAID management)

This is where 90% of PMO navigation happens. The project level supports the full delivery methodology through sub-layers.

### Project Sub-Layers

| Sub-Layer | What It Tracks | Source Data | Page Structure |
|-----------|---------------|-------------|----------------|
| **Phases** | Lifecycle position, gate criteria, blocking items | PROJECT.md phase timeline | Index page + one page per active/upcoming phase |
| **Workstreams** | Functional delivery areas, scope, ownership | Implicit in content; defined by agent | Index page + one page per workstream |
| **RAID** | Risks, assumptions, issues, dependencies | RAID Log (CSV/tracker) | Index page + one page per active risk |
| **Decisions** | Pending and resolved decisions | Daily Status Log DEC-### entries | Referenced in RAID and project hub (not separate pages in MVP — decisions live in their source tracker) |
| **Design** | Functional design, requirements, architecture | 02-Design/ FDDs | Linked from workstream pages (FDDs belong to workstreams) |
| **Testing** | Test plans, defect tracking, gate results | 03-Testing/ files | Linked from phase pages (testing gates phases) |
| **Change Management** | Training, communications, readiness | 01-Governance/ CM files | Linked from workstream (Training & Change Mgmt workstream) |
| **Synthesis** | Agent-generated analysis, reports, packages | 08-Generated/ files | Synthesis index grouped by lifecycle state |
| **Source Files** | File inventories by folder | 01-08 folders | Folder index pages (supporting, not primary navigation) |

### Three-Tier Project Navigation

```
Project Hub                          ← links to sub-layer indexes
  └─► Sub-Layer Index                ← lists entity pages (Phases, RAID, Workstreams)
       └─► Entity Page               ← specific risk, workstream, or phase
            └─► Source Files          ← FDDs, transcripts, trackers, generated artifacts
```

The project hub links to sub-layer indexes — NOT directly to every individual entity. This controls node sizing in the graph (hub is medium, not massive).

### Project Hub Template

```markdown
# {Project Name}

Program: [[{Program Name}]]

> {file_count} files — {domain_a} source, {domain_b} operational, {domain_c} synthesis

> [!warning] {risk_count} Active Risks
> - [[{top_risk_1}]]
> - [[{top_risk_2}]]
> - [[{top_risk_3}]]
> See [[RAID]] for all {risk_count}

> [!note] Current Phase
> [[{active_phase}]] — {dates}

## Delivery

- [[Phases]] — {active_count} active, {total} total
- [[Workstreams]] — {count} functional areas
- [[RAID]] — {active_risk_count} active risks
- [[Synthesis]] — agent-generated analysis

## Team

- [[Team Directory]]
```

**Key principle:** The hub shows only top 3 risks via callout and links to RAID for the full list. Trackers, FDDs, and folder indexes are NOT listed on the hub — they're reachable through sub-layer pages.

### Phase Page Template

```markdown
# {Phase Name}

Project: [[{Project Name}]] | Index: [[Phases]]

**Dates:** {dates}
**Status:** {status}

## Gate Criteria (C12)

{Methodology-appropriate gate artifacts for this phase}

## Blocking Risks

- [[{risk_page}]]

## Related Files

- [[{file related to this phase}]]
```

**Methodology parameterization (C02):** The 15-stage universal lifecycle (Capture → Prepare → Build → Validate → Deliver) compresses/expands per methodology. PROJECT.md's `methodology` field determines which phases are active:

| Methodology | Phases Shown | Gate Model |
|-------------|-------------|------------|
| Waterfall | All 15 stages, sequential | Phase gates with milestone approval |
| Scrum | Sprints (Build+Validate compressed) | Sprint DoR/DoD gates |
| Kanban | Value stream stages (continuous) | WIP limit + SLE gates |
| SAFe | PI increments + sprint cadence | PI planning gates |
| Hybrid ([PROJECT_KEY]) | Phase timeline with flexible execution | Phase gates + sprint-like iteration |

### Workstream Page Template

```markdown
# {Workstream Name}

Project: [[{Project Name}]] | Index: [[Workstreams]]

**Scope:** {description}

## Systems

- [[{System Name}]]

## Design Documents

- [[{FDD filename}]]

## Active Risks

- [[{risk page}]] — {priority}
```

### RAID Entity Page Template

```markdown
# {RAID_ID}

Project: [[{Project Name}]] | Index: [[RAID]]

**Description:** {description}
**Impact:** {impact}
**Owner:** {owner_name}
**Priority:** {priority}
**Status:** {status}
**Action Plan:** {action_plan}

## Workstreams

- [[{workstream}]]

## Related Files

- [[{source file mentioning this risk}]]
```

### Synthesis Index Template

```markdown
# Synthesis — {Project Name}

Project: [[{Project Name}]]

## Published ({count})

- [[{filename}]] — triggered by {trigger_source}

## Validated ({count})

- [[{filename}]] — triggered by {trigger_source}

## Draft ({count})

- [[{filename}]] — triggered by {trigger_source}

## Stale ({count})

- [[{filename}]] — triggered by {trigger_source}
```

---

## Level 4: Team

**Question:** Who's doing what?
**Audience:** Project managers, team leads, individuals
**Grounding:** C05 (roles and accountability)

### Design Decision: Accountability as Query, Not Files

The sandbox tested individual person pages (21 files). This was rejected:
- Person data already lives in source files (RAID owner, Daily Status actions by person, Communications audience)
- Creating duplicate person files violates "files are source of truth"
- 21 static files added graph noise without adding navigational value

**Replacement:** A single Team Directory page computed from ownership data across trackers.

### Team Directory Template

```markdown
# Team Directory

Project: [[{Project Name}]]

## By Risk Ownership

- {Person Name} — [[{risk_1}]], [[{risk_2}]] ({count} active)

## By Open Actions

- {Person Name} — {action_count} open ({summary})

## By Meeting Participation

- {Meeting Series}: {attendee list}
```

**Refresh:** Agent regenerates from RAID Log owners + Daily Status actions by person + Meetings Tracker attendees. No person files maintained.

**Graph impact:** One medium-sized Team Directory node connected to project hub and source trackers. No individual person nodes cluttering the graph.

---

## Supporting: Source File Indexes

Folder indexes provide file-level inventories for each 01-08 folder. These are supporting navigation — users reach them from project sub-layer pages, not as entry points.

### Folder Index Template

```markdown
# {Project Name} — {Folder}

Project: [[{Project Name}]]

> {file_count} files

| File | Type | Lifecycle | Modified |
|------|------|-----------|----------|
| [[{filename}]] | {type} | {lifecycle_state} | {date} |
```

---

## Tag Taxonomy

Tags are search/filter targets and SQLite query keys. Applied by agents during processing, not manually by humans. Tags are **not** the canonical Obsidian graph color group mechanism — see "Obsidian Color Groups" below.

| Tag | Applied To | Purpose |
|-----|-----------|---------|
| `project/{slug}` | Content files in a project | SQLite filter — `WHERE tags @> 'project/acme-implementation'` |
| `delivery/{domain}` | Content files by area | governance, design, testing, operations, transcripts, comms, synthesis |
| `artifact/{type}` | Content files by kind | transcript, design-doc, tracker, report, plan, email, export |
| `status/{state}` | Content files by lifecycle | active, draft, stale, archived |
| `workstream/{slug}` | Files related to a workstream | Functional area sub-clustering |
| `level/{pmo-level}` | Navigation pages only | portfolio, program, project, team |

**Storage-layer scope:** Tags live in YAML frontmatter for markdown files and in `.meta.yml` sidecars for non-markdown files. The Storage Layer (SQLite index) reads both uniformly. Health check filters and agent queries use tags as their primary selector.

**Obsidian limitation:** Obsidian only reads YAML frontmatter from markdown files. Tags applied via sidecars are invisible to Obsidian's `tag:` graph queries. In sandbox testing, ~59% of content files (transcripts, exports, attachments) use sidecars, so tag-based color groups produced sparse, misleading clusters. This is a Presentation Layer constraint, not a Storage Layer defect.

---

## Obsidian Color Groups

The canonical Obsidian graph color group mechanism is **path queries**, not tag queries. Path queries match against folder paths regardless of file type, so they cluster sidecar-bearing files alongside their markdown siblings.

| Query | Cluster | Rationale |
|-------|---------|-----------|
| `path:"_pmo/1-Portfolio"` | Portfolio nav layer | Independent of file frontmatter |
| `path:"_pmo/2-Program"` | Program nav layer | Independent of file frontmatter |
| `path:"_pmo/3-Project"` | Project nav layer | Independent of file frontmatter |
| `path:"_pmo/4-Team"` | Team nav layer | Independent of file frontmatter |
| `path:"{Project Name}"` | One per active project | All file types in the project folder |
| `path:"05-Transcripts"` | Transcripts (cross-project) | Visualizes ingestion volume |
| `path:"08-Generated"` | Synthesis output (cross-project) | Visualizes generated content density |

**Why path queries work:** Obsidian indexes file paths regardless of extension or frontmatter presence. A `.txt` transcript with no readable frontmatter still matches `path:"05-Transcripts"`. This makes path queries the only mechanism that produces consistent visual clusters across both Domain A (source artifacts, often non-markdown) and Domain B (managed knowledge, mostly markdown).

**When tags still work for graph coloring:** Navigation pages (`_pmo/**/*.md`) are 100% markdown with frontmatter, so `tag:level/portfolio` style queries work for the navigation layer. Path queries are still preferred because they remain consistent with the content-layer mechanism.

---

## View Parameterization

Navigation pages are not dynamically filtered per user. The 4-level hierarchy provides natural role-appropriate entry points:

| Role | Entry Point | Typical Path |
|------|-------------|-------------|
| Executive / Sponsor | Portfolio Dashboard | → Program → Project Hub (summary) |
| Program Manager | Program Hub | → Project Hub → RAID → Cross-Project Dependencies |
| PM / Delivery Lead | Project Hub | → Phases, Workstreams, RAID, Synthesis |
| Workstream Lead | Workstream Page | → Related FDDs, risks, systems |

The navigation generator produces all page types. Role parameterization is expressed through entry points, not content filtering.

---

## Refresh Model

### Event-Triggered

| Trigger Event | Pages Refreshed |
|---------------|----------------|
| File added/removed from 01-08 folder | Folder Index, Project Hub (file count) |
| Frontmatter `lifecycle_state` changed | Folder Index, Synthesis Index (if Domain C) |
| RAID entry created/updated | RAID index, risk entity page, Project Hub (risk callout) |
| Cross-project dependency changed | Cross-Project Dependencies page |
| Domain C file reaches `published` | Synthesis Index |
| Weekly Status Roll-Up generated | Portfolio Dashboard, Program Hub, Project Hub |

### Daily Full Rebuild

Regenerates all navigation pages from current index state. Catches missed event triggers and runs orphan sweep.

### Staleness Rule

Navigation pages older than 24 hours without refresh are flagged. Daily rebuild resolves automatically.

---

## Wiki-Link Conventions

Established by prototype iterations 5-7.

1. **Filename-only links** — never relative paths. Obsidian resolves via shortest-path matching.
2. **No pipe aliases in tables** — `[[file|display]]` breaks markdown table parsing. Aliases permitted outside tables.
3. **File/folder name disambiguation** — append entity type if name collides with folder (e.g., `[PROJECT_KEY] Implementation Project.md` vs `[PROJECT_KEY] Implementation/`).
4. **Non-markdown files** — linked by filename, rendered as attachments in Obsidian. Full relationship data in SQLite index regardless of file type.

---

## Graph View Role

The Obsidian global graph is a **supplementary visualization**, not the primary navigation tool. Primary navigation is page-based (clicking through linked pages).

**Graph value:** Visual overview of portfolio complexity, spotting orphans, local graph for "what's related to this?", color groups for cluster identification.

**Graph limitations:** Force-directed layout shows connection density, not hierarchy. Dense meshes are inherent with many shared entities.

**Recommendation:** The navigation generator optimizes page content (what sections, what links, what callouts). Graph appearance follows naturally from link structure. Graph color groups use path queries (see "Obsidian Color Groups" above) — these are written by the generator to `.obsidian/graph.json` so the cluster scheme is consistent across machines, not a per-user preference.

---

## Validation Checklist

- [ ] Every source file in Projects/[Project]/01-08/ appears in at least one navigation page
- [ ] Every navigation page has valid frontmatter with `page_type`, `scope_project`, `last_generated`
- [ ] Zero orphan files (files not linked from any navigation page)
- [ ] No pipe aliases inside table cells
- [ ] Page type coverage: every active project has Project Hub + Phases + Workstreams + RAID + Synthesis indexes
- [ ] Entity pages (risks, workstreams, phases) are nested under their project, not shared
- [ ] Cross-project dependencies visible at Portfolio/Program level
- [ ] Portfolio Dashboard exists with health roll-up
- [ ] Team Directory is a single computed page (no individual person files)
- [ ] Tags from taxonomy present on all content files and navigation pages
- [ ] Wiki-links use filename-only format
- [ ] Navigation pages regenerate within 24 hours of triggering event

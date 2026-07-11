---
title: SQLite Index Schema — Document Ecosystem Cache
purpose: Defines the SQLite schema for the document ecosystem's queryable index — a disposable cache rebuilt entirely from source-file frontmatter, where the files remain the source of truth.
type: schema
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: the document-ecosystem index builder (rebuilt from frontmatter); health-check queries; the queryable-metadata consumers (files remain source of truth)
---
# SQLite Index Schema — Document Ecosystem Cache

## Purpose

Defines the SQLite database schema for the document ecosystem's queryable index. This database is a **disposable cache** rebuilt entirely from frontmatter metadata on source files. It exists to make file metadata queryable — the files themselves remain the source of truth.

**Architecture:** C17 Phase 1 (YAML frontmatter + SQLite index). Phase 2 (Kuzu graph) and Phase 3 (GraphRAG) are future scope.
**Grounding:** C17 (files-as-source-of-truth, FTS5, three-phase artifact linking); frontmatter field definitions in `schemas/frontmatter-schema.md`

## Consumers

| Consumer | Access | Purpose |
|----------|--------|---------|
| Health check engine | Read | Orphan detection, staleness scoring, contradiction queries |
| Navigation layer generator | Read | View queries (portfolio roll-up, folder indexes, cross-project dependencies) |
| Agent skills (PPM Agent Section 8) | Read | Blast radius analysis, impact matrix, dependency scan |
| Index builder | Write | Full rebuild or incremental update from frontmatter |

## Design Principles

1. **Files are source of truth** (C17). Every row in every table is derivable from frontmatter + file content. Deleting the database and rebuilding must produce an identical result.
2. **FTS5 for full-text search** (C17). All text-searchable file content is indexed via SQLite's FTS5 extension for fast keyword search across the corpus.
3. **Recursive CTEs for graph traversal**. Blast radius, impact propagation, and transitive dependency queries use recursive common table expressions.
4. **No data that isn't in frontmatter**. If a field isn't in a file's frontmatter (or derivable from the file system), it doesn't belong in the index.

---

## Table Definitions

### Table: `files`

Core file registry. One row per file in the ecosystem.

```sql
CREATE TABLE files (
    file_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    path            TEXT NOT NULL UNIQUE,           -- Full relative path from projects/ root
    filename        TEXT NOT NULL,                   -- Filename only (for wiki-link resolution)
    file_format     TEXT NOT NULL,                   -- md, txt, csv, xlsx, pdf, docx, html
    domain          TEXT NOT NULL CHECK (domain IN ('source', 'managed', 'generated', 'A', 'B', 'C')),  -- 'A'/'B'/'C' are DEPRECATED aliases of 'source'/'managed'/'generated' (migration window; frontmatter-schema.md Category 6). Union collapses to the 3 human-readable values at tail.
    type            TEXT NOT NULL,                   -- From frontmatter type taxonomy
    project         TEXT NOT NULL,                   -- Project name
    folder          TEXT NOT NULL,                   -- ADR-078 union: legacy 01-governance…08-generated ∪ new 1-Governance…5-Reference + _inbox/_generated (migration window; frontmatter-schema.md § Category 6). No CHECK — folder cardinality left unconstrained at the DB layer; enum validated upstream at write.

    managed_by      TEXT NOT NULL,                   -- Skill name
    parent          TEXT,                            -- Hierarchical parent
    lifecycle_state TEXT NOT NULL,                   -- Current lifecycle state
    lifecycle_changed TEXT,                          -- ISO date of last state change
    trust_category  TEXT NOT NULL CHECK (trust_category IN (
        'evidence', 'controlled-truth', 'interpretation',
        'working-context', 'historical-record'
    )),
    evidence_quality TEXT CHECK (evidence_quality IN (
        'source', 'corroborated', 'inferred', 'assumed'
    )),
    created_date    TEXT NOT NULL,                   -- ISO date
    modified_date   TEXT,                            -- Filesystem modified date
    content_hash    TEXT,                            -- SHA-256 of file content (change detection)
    -- Domain A specific
    approval_state  TEXT CHECK (approval_state IN (
        'draft', 'under-review', 'approved', 'rejected'
    )),
    version         TEXT,                            -- Semantic version X.Y
    superseded_by   TEXT,                            -- Filename of superseding file
    -- Domain B specific
    last_evidence_date TEXT,                         -- ISO date
    staleness_threshold_days INTEGER DEFAULT 14,
    entry_count     INTEGER,
    -- Domain C specific
    trigger_source  TEXT,                            -- What triggered this synthesis
    validation_state TEXT CHECK (validation_state IN (
        'pending', 'passed', 'failed'
    ))
);
```

**Indexes:**

```sql
CREATE INDEX idx_files_project ON files(project);
CREATE INDEX idx_files_domain ON files(domain);
CREATE INDEX idx_files_lifecycle ON files(lifecycle_state);
CREATE INDEX idx_files_type ON files(type);
CREATE INDEX idx_files_trust ON files(trust_category);
CREATE INDEX idx_files_folder ON files(folder);
CREATE INDEX idx_files_filename ON files(filename);
CREATE INDEX idx_files_managed_by ON files(managed_by);
```

---

### Table: `relationships`

Edge table for file-to-file connections. Each row represents one directional relationship.

```sql
CREATE TABLE relationships (
    rel_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    source_file_id  INTEGER NOT NULL REFERENCES files(file_id),
    target_file_id  INTEGER NOT NULL REFERENCES files(file_id),
    relationship_type TEXT NOT NULL CHECK (relationship_type IN (
        'GENERATES', 'DEPENDS_ON', 'BLOCKS', 'SUPERSEDES',
        'BELONGS_TO', 'RELATES_TO', 'ASSIGNED_TO'
    )),
    evidence        TEXT,                            -- What established this connection
    created_date    TEXT NOT NULL,                   -- ISO date
    created_by      TEXT,                            -- Skill or person that created the relationship
    UNIQUE(source_file_id, target_file_id, relationship_type)
);
```

**Indexes:**

```sql
CREATE INDEX idx_rel_source ON relationships(source_file_id);
CREATE INDEX idx_rel_target ON relationships(target_file_id);
CREATE INDEX idx_rel_type ON relationships(relationship_type);
```

---

### Table: `files_fts` (FTS5 Virtual Table)

Full-text search index over file content. Enables keyword search across the entire corpus.

```sql
CREATE VIRTUAL TABLE files_fts USING fts5(
    file_id,                -- Foreign key to files table (unindexed)
    filename,               -- Searchable filename
    content_preview,        -- First 500 characters of file content
    frontmatter_text,       -- Serialized frontmatter fields as searchable text
    content='files',        -- External content table
    content_rowid='file_id'
);
```

**Population query:**

```sql
INSERT INTO files_fts(file_id, filename, content_preview, frontmatter_text)
SELECT file_id, filename,
       substr(content, 1, 500),  -- content read from file during rebuild
       type || ' ' || project || ' ' || folder || ' ' || COALESCE(trigger_source, '')
FROM files;
```

---

### Table: `lifecycle_events`

Audit trail of lifecycle state changes. One row per transition.

```sql
CREATE TABLE lifecycle_events (
    event_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id     INTEGER NOT NULL REFERENCES files(file_id),
    old_state   TEXT,                               -- NULL for initial creation
    new_state   TEXT NOT NULL,
    trigger     TEXT,                               -- What caused the transition
    timestamp   TEXT NOT NULL,                      -- ISO 8601 datetime
    agent       TEXT                                -- Skill or person that triggered the change
);
```

**Indexes:**

```sql
CREATE INDEX idx_lifecycle_file ON lifecycle_events(file_id);
CREATE INDEX idx_lifecycle_timestamp ON lifecycle_events(timestamp);
```

---

### Table: `navigation_pages`

Registry of agent-generated navigation pages. Tracks what pages exist and when they were last generated.

```sql
CREATE TABLE navigation_pages (
    page_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    page_path       TEXT NOT NULL UNIQUE,            -- Path to the navigation page file
    page_type       TEXT NOT NULL CHECK (page_type IN (
        'portfolio-dashboard', 'program-overview', 'project-hub',
        'folder-index', 'workstream-view', 'milestone-view',
        'risk-view', 'decision-view', 'dependency-view',
        'generated-index', 'published-synthesis'
    )),
    scope_project   TEXT,                            -- Which project this page covers (NULL for portfolio/program)
    scope_level     TEXT CHECK (scope_level IN (
        'portfolio', 'program', 'project', 'folder', 'workstream'
    )),
    last_generated  TEXT NOT NULL,                   -- ISO 8601 datetime
    source_query    TEXT                             -- Description of the query that produces this page
);
```

---

### Table: `synthesis_scope` (Junction Table)

Maps Domain C files to the source files they draw from. Derived from the `synthesis_scope` frontmatter array.

```sql
CREATE TABLE synthesis_scope (
    synthesis_file_id INTEGER NOT NULL REFERENCES files(file_id),
    source_file_id    INTEGER NOT NULL REFERENCES files(file_id),
    PRIMARY KEY (synthesis_file_id, source_file_id)
);
```

---

## Named Query Patterns

Documented query patterns for common ecosystem operations. Agents and the health check engine use these.

### Query 1: Blast Radius CTE

Given a file, find all files reachable through `DEPENDS_ON` and `GENERATES` relationships. Used by PPM Agent Section 8 Impact Matrix.

```sql
WITH RECURSIVE blast_radius(file_id, depth, path) AS (
    -- Anchor: the changed file
    SELECT file_id, 0, path
    FROM files WHERE filename = :changed_file

    UNION ALL

    -- Recursive: follow DEPENDS_ON (reverse) and GENERATES edges
    SELECT f.file_id, br.depth + 1, f.path
    FROM blast_radius br
    JOIN relationships r ON r.target_file_id = br.file_id
    JOIN files f ON f.file_id = r.source_file_id
    WHERE r.relationship_type IN ('DEPENDS_ON', 'GENERATES')
      AND br.depth < :max_depth  -- Configurable depth limit (default: 5)
)
SELECT DISTINCT file_id, depth, path
FROM blast_radius
ORDER BY depth;
```

### Query 2: Orphan Detection

Files with zero relationships (neither source nor target). Primary KPI: target is 0.

```sql
SELECT f.file_id, f.path, f.filename, f.type, f.domain
FROM files f
LEFT JOIN relationships r_source ON f.file_id = r_source.source_file_id
LEFT JOIN relationships r_target ON f.file_id = r_target.target_file_id
WHERE r_source.rel_id IS NULL
  AND r_target.rel_id IS NULL
  AND f.domain IN ('source', 'managed', 'generated', 'A', 'B', 'C')  -- Exclude navigation pages; union accepts deprecated A/B/C aliases during the migration window

ORDER BY f.project, f.folder;
```

### Query 3: Staleness Score

Computed score indicating how stale a file is. Higher = more stale.

```sql
SELECT
    f.file_id,
    f.path,
    f.filename,
    f.lifecycle_state,
    f.domain,
    julianday('now') - julianday(f.modified_date) AS days_since_modified,
    julianday('now') - julianday(f.lifecycle_changed) AS days_since_lifecycle_change,
    julianday('now') - julianday(COALESCE(f.last_evidence_date, f.created_date)) AS days_since_evidence,
    -- Staleness formula: weighted combination
    (julianday('now') - julianday(f.modified_date)) * 0.4
    + (julianday('now') - julianday(f.lifecycle_changed)) * 0.3
    + (julianday('now') - julianday(COALESCE(f.last_evidence_date, f.created_date))) * 0.3
    AS staleness_score
FROM files f
WHERE f.lifecycle_state NOT IN ('archived', 'superseded')
  AND f.domain = :domain  -- source, managed, or generated (or a deprecated A/B/C alias during the migration window)
ORDER BY staleness_score DESC;
```

**Staleness thresholds:**

| Domain | Threshold | Transition |
|--------|-----------|-----------|
| A (Source) | staleness_score > 30 | No automatic transition (source artifacts age naturally) |
| B (Knowledge) | staleness_score > 14 (configurable per file via `staleness_threshold_days`) | `current` → `needs-review` |
| C (Synthesis) | staleness_score > 14 OR any source file modified since synthesis creation | `published` → `stale` (per Domain C lifecycle protocol) |

### Query 4: Navigation View — Portfolio Roll-Up

Aggregate health metrics across all projects for the portfolio dashboard.

```sql
SELECT
    f.project,
    f.lifecycle_state,
    COUNT(*) AS file_count,
    SUM(CASE WHEN f.domain IN ('source', 'A') THEN 1 ELSE 0 END) AS source_count,       -- 'A' = deprecated alias of 'source' (migration window)
    SUM(CASE WHEN f.domain IN ('managed', 'B') THEN 1 ELSE 0 END) AS knowledge_count,    -- 'B' = deprecated alias of 'managed'
    SUM(CASE WHEN f.domain IN ('generated', 'C') THEN 1 ELSE 0 END) AS synthesis_count,  -- 'C' = deprecated alias of 'generated'
    SUM(CASE WHEN orphans.file_id IS NOT NULL THEN 1 ELSE 0 END) AS orphan_count
FROM files f
LEFT JOIN (
    SELECT f2.file_id
    FROM files f2
    LEFT JOIN relationships r1 ON f2.file_id = r1.source_file_id
    LEFT JOIN relationships r2 ON f2.file_id = r2.target_file_id
    WHERE r1.rel_id IS NULL AND r2.rel_id IS NULL
) orphans ON f.file_id = orphans.file_id
GROUP BY f.project, f.lifecycle_state
ORDER BY f.project;
```

### Query 5: Cross-Project Dependencies

Dependencies where source and target files belong to different projects.

```sql
SELECT
    fs.project AS source_project,
    fs.filename AS source_file,
    r.relationship_type,
    ft.project AS target_project,
    ft.filename AS target_file,
    r.evidence
FROM relationships r
JOIN files fs ON r.source_file_id = fs.file_id
JOIN files ft ON r.target_file_id = ft.file_id
WHERE fs.project != ft.project
  AND r.relationship_type IN ('DEPENDS_ON', 'BLOCKS')
ORDER BY fs.project, ft.project;
```

### Query 6: Domain C Staleness Detection

Files in 08-Generated where any source file was modified after synthesis creation.

```sql
SELECT
    synth.file_id,
    synth.filename,
    synth.lifecycle_state,
    synth.created_date AS synthesis_date,
    src.filename AS changed_source,
    src.modified_date AS source_modified
FROM files synth
JOIN synthesis_scope ss ON synth.file_id = ss.synthesis_file_id
JOIN files src ON ss.source_file_id = src.file_id
WHERE synth.domain IN ('generated', 'C')  -- 'C' = deprecated alias of 'generated' (migration window)
  AND synth.lifecycle_state IN ('validated', 'published')
  AND src.modified_date > synth.created_date
ORDER BY synth.filename;
```

### Query 7: Frontmatter Completeness Check

Files missing required frontmatter fields.

```sql
SELECT file_id, path, filename, domain,
    CASE WHEN type IS NULL THEN 'type' END AS missing_type,
    CASE WHEN managed_by IS NULL THEN 'managed_by' END AS missing_managed_by,
    CASE WHEN lifecycle_state IS NULL THEN 'lifecycle_state' END AS missing_lifecycle,
    CASE WHEN trust_category IS NULL THEN 'trust_category' END AS missing_trust,
    CASE WHEN domain IS NULL THEN 'domain' END AS missing_domain,
    CASE WHEN file_format IS NULL THEN 'file_format' END AS missing_format,
    CASE WHEN project IS NULL THEN 'project' END AS missing_project,
    CASE WHEN folder IS NULL THEN 'folder' END AS missing_folder,
    CASE WHEN domain IN ('generated', 'C') AND trigger_source IS NULL THEN 'trigger_source' END AS missing_trigger  -- 'C' = deprecated alias of 'generated'
FROM files
WHERE type IS NULL
   OR managed_by IS NULL
   OR lifecycle_state IS NULL
   OR trust_category IS NULL
   OR domain IS NULL
   OR file_format IS NULL
   OR project IS NULL
   OR folder IS NULL
   OR (domain IN ('generated', 'C') AND trigger_source IS NULL);  -- 'C' = deprecated alias of 'generated'
```

---

## Rebuild Protocol

### Full Rebuild

Drop all tables, scan all files, rebuild from frontmatter. Guarantees index matches file state.

**Steps:**
1. Drop all tables and recreate schema
2. Scan `projects/` recursively for `.md` files with YAML frontmatter
3. Scan `projects/` recursively for `.meta.yml` sidecar files
4. For each file with metadata: insert into `files` table, populate domain-specific columns
5. For each relationship in frontmatter: resolve target filename to `file_id`, insert into `relationships`
6. For each Domain C file: populate `synthesis_scope` from frontmatter array
7. Rebuild FTS5 index from file content
8. Insert initial `lifecycle_events` entry for each file (state = current lifecycle_state)

**Estimated time for current corpus:** 488 files + sidecars, target < 10 seconds

### Incremental Update

On file change, update only that file's rows. Faster but may drift if changes are missed.

**Steps:**
1. Reparse frontmatter from changed file
2. Update `files` row (or insert if new)
3. Delete and reinsert `relationships` rows for this file
4. Delete and reinsert `synthesis_scope` rows for this file (if Domain C)
5. Update FTS5 entry
6. Insert `lifecycle_events` row if state changed

### Rebuild Triggers

| Trigger | Action |
|---------|--------|
| Manual command | Full rebuild |
| Daily scheduled job | Full rebuild (doubles as orphan sweep) |
| Health check detects inconsistency | Full rebuild |
| File processed by any skill | Incremental update for that file |
| Navigation page refresh | No rebuild (reads existing index) |

---

## Implementation

This schema is **materialized** by `core/deploy/tools/build-doc-index.py` — a stdlib-only Python 3.9 CLI (`sqlite3` + FTS5 are stdlib). It reads node frontmatter (the 11-field NOT-NULL `files` core stamped by `stamp-node-frontmatter.py`, the node-frontmatter backfill tool) + `relationships[]` edges (emitted by `backfill-relationship-edges.py`, the relationship-edge population tool) and builds all 7 tables above plus the 7 named query patterns.

**Invocation + sync model:**

| Operation | Command | Sync semantics |
|---|---|---|
| Full rebuild | `build-doc-index.py --rebuild --db <path> --root <corpus>` | Drop + rebuild all tables from frontmatter. **Deterministic** — files sorted by relative POSIX path so `file_id` is a pure function of corpus content; two rebuilds are byte-identical (verified via `--dump-canonical` + SHA-256). Never synthesizes a build-time timestamp. |
| Incremental update | `build-doc-index.py --update-file <file> --db <path> --root <corpus>` | Updates one file's rows in place (preserving `file_id` so inbound FKs + the `lifecycle_events` audit trail stay valid); appends a `lifecycle_events` row iff the state changed. This is the **capability** the "File processed by any skill" trigger consumes — the event source that *calls* it is out of this tool's scope, owned by the lifecycle-automation epic (no watcher ships here). |
| Query | `build-doc-index.py --query <name> --db <path> [--param k=v]` | Runs a named reference query (`blast-radius`, `orphan`, `staleness`, `portfolio-rollup`, `cross-project-deps`, `domain-c-staleness`, `frontmatter-completeness`). |
| Self-test | `build-doc-index.py --self-test` | Fixture-based AC1–AC4 + FMF-2/FMF-3 assertions (see the tool README). |

**Edge / project resolution note.** A `relationships[]` `target` resolves to `files.file_id` by exact `filename`. A `BELONGS_TO` edge whose `target` is a **project name** (the shape the relationship-edge population emits) resolves to that project's governance-root representative node (`folder IN ('01-governance', '1-Governance')` — the legacy or the ADR-078 governance bin, union-aware for the migration window) — because `relationships.target_file_id` must reference a real file, a project name cannot be stored directly. A target resolving to neither a file nor a project representative is a dangling **WARN** (row skipped, never fabricated).

**`domain` enum.** The builder reads/inserts the migrated human-readable `{source, managed, generated}` values; the `{A, B, C}` aliases in the `files` CHECK + the union-enum queries remain for the migration window (see the `domain` CHECK note above).

---

## Validation Checklist

- [ ] All files with frontmatter have corresponding rows in `files` table
- [ ] All relationship targets in frontmatter resolve to existing `file_id` values
- [ ] FTS5 index covers all markdown and text files
- [ ] `lifecycle_events` table has at least one entry per file
- [ ] No orphaned relationship rows (both source and target exist in `files`)
- [ ] `synthesis_scope` entries match `synthesis_scope` frontmatter arrays
- [ ] Full rebuild produces identical results to incremental state
- [ ] All CHECK constraints pass (domain, trust_category, relationship_type, etc.)
- [ ] Named queries execute without error against the populated schema

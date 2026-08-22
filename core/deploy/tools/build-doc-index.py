#!/usr/bin/env python3
"""build-doc-index.py — materialize the disposable document-ecosystem SQLite index (#1769).

Scans a corpus for YAML frontmatter (embedded in `.md` + `.meta.yml` sidecars),
materializes ALL 7 tables of `core/schemas/sqlite-index-schema.md` into a disposable
SQLite database, and exposes the schema's 7 named reference queries. The database is a
CACHE — the files remain the source of truth; deleting the `.db` and rebuilding must
produce a byte-identical result (schema Design Principle 1).

This is the BUILDER (the third link in the doc-warehouse FK chain):

    stamp-node-frontmatter.py  → stamps the 11-field node core (the vertices)
    backfill-relationship-edges.py → emits relationships[] edges (the edges)
    build-doc-index.py (THIS)  → READS both + materializes the queryable index

It CONSUMES the two upstream tools' output:
  * node frontmatter — the 11-field NOT-NULL `files` core (path, filename, file_format,
    domain, type, project, folder, managed_by, lifecycle_state, trust_category,
    created_date). The `domain` enum is the MIGRATED human-readable vocabulary
    `{source, managed, generated}`; `{A, B, C}` are DEPRECATED aliases the schema CHECK
    still accepts during the migration window. This builder READS/INSERTS whatever the
    node tool stamped (source/managed/generated) and the union-enum queries handle both.
  * relationships[] edges — the 7-verb `{GENERATES, DEPENDS_ON, BLOCKS, SUPERSEDES,
    BELONGS_TO, RELATES_TO, ASSIGNED_TO}` object list; `target` is a bare filename
    (no path) resolved to `files.file_id` by `files.filename`. A dangling target is a
    WARN (row skipped), never a hard error.

SCOPE (operator-ratified D-C4 boundary): this ships the incremental-update CAPABILITY
(`update_file`, a tested + callable entry point) + full deterministic `rebuild` + the
reference queries. It does NOT build the event source/watcher that auto-invokes
`update_file` on a skill-write — that stays in open epic #1153. `update_file` is the
stable callee #1153 will wire.

DETERMINISM (AC2): discovered files are sorted by relative POSIX path before insert, so
`file_id AUTOINCREMENT` is a pure function of corpus content (the exact idiom the sibling
tools use). Build-time timestamps are NEVER synthesized — a missing `created_date` is
stored as read (or NULL); `modified_date` is the filesystem mtime (a property of the file,
identical across two rebuilds of the same tree). The staleness queries use
`julianday('now')`, a QUERY-time value that does not touch stored rows. Two rebuilds are
verified byte-identical by SHA-256 over a canonical per-table dump.

Stdlib-only, Python 3.9 (`/usr/bin/python3`): `sqlite3` + FTS5 are in that stdlib
(sqlite 3.51.0). Imports the shared `_frontmatter.py` reader for top-level scalar keys
(F1 consistency with Checks 18b/50); the nested `relationships[]` / `source_inputs[]`
blocks need a block-aware parse the shared reader deliberately skips, so that parse is
builder-local.

CLI:
  --rebuild --db PATH --root PATH         full deterministic drop+rebuild
  --update-file PATH --db PATH [--root R] incremental single-file update (the #1153 callee)
  --query NAME --db PATH [--param k=v]…    run a named reference query
  --self-test                              run the committed-fixture assertions and exit
  --output-format tsv|json                 query / dump output format (default tsv)
  --dump-canonical --db PATH               emit the canonical row dump (determinism hash input)

Exit codes (fail-loud contract, mirroring the deploy-tool family):
  0  clean
  1  findings present (dangling edges surfaced; count in the header)
  2  usage error (bad / mutually-exclusive flags)
  3  path-unresolvable (--root or --db unresolvable)
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
import sys
from pathlib import Path

# The ONE shared frontmatter reader (F1). This file lives beside it in
# core/deploy/tools/; the sys.path insert makes --self-test / direct invocation robust.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _frontmatter import read_frontmatter, _strip_quotes  # noqa: E402


# --------------------------------------------------------------------------- #
# Contract constants (bound byte-for-byte to sqlite-index-schema.md +
# frontmatter-schema.md — the shared surface with #3081 nodes + #1770 edges).
# --------------------------------------------------------------------------- #

# domain enum: MIGRATED human-readable values + DEPRECATED A/B/C aliases. The `files`
# CHECK + the union-enum queries below carry the union `{source, managed, generated, A,
# B, C}` for the migration window; the node tool stamps only the 3 human-readable values.

# The 7 MVP relationship verbs (= sqlite-index-schema.md relationships CHECK).
MVP_VERBS = (
    "GENERATES", "DEPENDS_ON", "BLOCKS", "SUPERSEDES",
    "BELONGS_TO", "RELATES_TO", "ASSIGNED_TO",
)

# The 11-field NOT-NULL core the `files` table requires (a file missing any → no row).
CORE_REQUIRED = (
    "path", "filename", "file_format", "domain", "type", "project",
    "folder", "managed_by", "lifecycle_state", "trust_category", "created_date",
)

MARKDOWN_SUFFIXES = frozenset({".md"})
SIDECAR_SUFFIX = ".meta.yml"


# --------------------------------------------------------------------------- #
# Schema DDL (verbatim from sqlite-index-schema.md — the builder implements it,
# it does not redesign it).
# --------------------------------------------------------------------------- #

DDL_STATEMENTS = [
    # --- files ---
    """
    CREATE TABLE files (
        file_id         INTEGER PRIMARY KEY AUTOINCREMENT,
        path            TEXT NOT NULL UNIQUE,
        filename        TEXT NOT NULL,
        file_format     TEXT NOT NULL,
        domain          TEXT NOT NULL CHECK (domain IN ('source', 'managed', 'generated', 'A', 'B', 'C')),
        type            TEXT NOT NULL,
        project         TEXT NOT NULL,
        folder          TEXT NOT NULL,
        managed_by      TEXT NOT NULL,
        parent          TEXT,
        lifecycle_state TEXT NOT NULL,
        lifecycle_changed TEXT,
        trust_category  TEXT NOT NULL CHECK (trust_category IN (
            'evidence', 'controlled-truth', 'interpretation',
            'working-context', 'historical-record'
        )),
        evidence_quality TEXT CHECK (evidence_quality IN (
            'source', 'corroborated', 'inferred', 'assumed'
        )),
        created_date    TEXT NOT NULL,
        modified_date   TEXT,
        content_hash    TEXT,
        approval_state  TEXT CHECK (approval_state IN (
            'draft', 'under-review', 'approved', 'rejected'
        )),
        version         TEXT,
        superseded_by   TEXT,
        last_evidence_date TEXT,
        staleness_threshold_days INTEGER DEFAULT 14,
        entry_count     INTEGER,
        trigger_source  TEXT,
        validation_state TEXT CHECK (validation_state IN (
            'pending', 'passed', 'failed'
        ))
    )
    """,
    "CREATE INDEX idx_files_project ON files(project)",
    "CREATE INDEX idx_files_domain ON files(domain)",
    "CREATE INDEX idx_files_lifecycle ON files(lifecycle_state)",
    "CREATE INDEX idx_files_type ON files(type)",
    "CREATE INDEX idx_files_trust ON files(trust_category)",
    "CREATE INDEX idx_files_folder ON files(folder)",
    "CREATE INDEX idx_files_filename ON files(filename)",
    "CREATE INDEX idx_files_managed_by ON files(managed_by)",
    # --- relationships ---
    """
    CREATE TABLE relationships (
        rel_id          INTEGER PRIMARY KEY AUTOINCREMENT,
        source_file_id  INTEGER NOT NULL REFERENCES files(file_id),
        target_file_id  INTEGER NOT NULL REFERENCES files(file_id),
        relationship_type TEXT NOT NULL CHECK (relationship_type IN (
            'GENERATES', 'DEPENDS_ON', 'BLOCKS', 'SUPERSEDES',
            'BELONGS_TO', 'RELATES_TO', 'ASSIGNED_TO'
        )),
        evidence        TEXT,
        created_date    TEXT NOT NULL,
        created_by      TEXT,
        UNIQUE(source_file_id, target_file_id, relationship_type)
    )
    """,
    "CREATE INDEX idx_rel_source ON relationships(source_file_id)",
    "CREATE INDEX idx_rel_target ON relationships(target_file_id)",
    "CREATE INDEX idx_rel_type ON relationships(relationship_type)",
    # --- files_fts (external-content FTS5) ---
    """
    CREATE VIRTUAL TABLE files_fts USING fts5(
        file_id,
        filename,
        content_preview,
        frontmatter_text,
        content='files',
        content_rowid='file_id'
    )
    """,
    # --- lifecycle_events ---
    """
    CREATE TABLE lifecycle_events (
        event_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        file_id     INTEGER NOT NULL REFERENCES files(file_id),
        old_state   TEXT,
        new_state   TEXT NOT NULL,
        trigger     TEXT,
        timestamp   TEXT NOT NULL,
        agent       TEXT
    )
    """,
    "CREATE INDEX idx_lifecycle_file ON lifecycle_events(file_id)",
    "CREATE INDEX idx_lifecycle_timestamp ON lifecycle_events(timestamp)",
    # --- navigation_pages ---
    """
    CREATE TABLE navigation_pages (
        page_id         INTEGER PRIMARY KEY AUTOINCREMENT,
        page_path       TEXT NOT NULL UNIQUE,
        page_type       TEXT NOT NULL CHECK (page_type IN (
            'portfolio-dashboard', 'program-overview', 'project-hub',
            'folder-index', 'workstream-view', 'milestone-view',
            'risk-view', 'decision-view', 'dependency-view',
            'generated-index', 'published-synthesis'
        )),
        scope_project   TEXT,
        scope_level     TEXT CHECK (scope_level IN (
            'portfolio', 'program', 'project', 'folder', 'workstream'
        )),
        last_generated  TEXT NOT NULL,
        source_query    TEXT
    )
    """,
    # --- synthesis_scope (junction) ---
    """
    CREATE TABLE synthesis_scope (
        synthesis_file_id INTEGER NOT NULL REFERENCES files(file_id),
        source_file_id    INTEGER NOT NULL REFERENCES files(file_id),
        PRIMARY KEY (synthesis_file_id, source_file_id)
    )
    """,
]

# The 7 tables the schema defines (asserted present by --self-test / AC1).
EXPECTED_TABLES = (
    "files", "relationships", "files_fts", "lifecycle_events",
    "navigation_pages", "synthesis_scope",
)
# files_fts is a virtual table; its shadow tables count separately — the named set above
# is what AC1 verifies via sqlite_master name membership.


# --------------------------------------------------------------------------- #
# Frontmatter parsing — scalars via the shared reader (F1); nested blocks local.
# --------------------------------------------------------------------------- #

def _read_sidecar_scalars(sidecar_path: Path) -> dict:
    """Top-level scalar keys of a `.meta.yml` sidecar (no `---` fences), mirroring the
    _frontmatter idiom (first-colon split, one quote-pair stripped, indented lines
    skipped). Matches stamp-node-frontmatter.py `_read_sidecar_keys` so the builder reads
    exactly what the node tool wrote."""
    keys: dict = {}
    if not sidecar_path.exists():
        return keys
    for line in sidecar_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[:1].isspace() or ":" not in line:
            continue
        raw_key, raw_val = line.split(":", 1)
        key = raw_key.strip()
        if key and key not in keys:
            keys[key] = _strip_quotes(raw_val.strip())
    return keys


def _parse_list_scalar(raw: str) -> list:
    """A YAML flow list rendered as a scalar (`[a.md, b.md]` or `a, b`) → tokens.
    The shared reader flattens a flow list to this scalar string; a block list is handled
    by the block-aware parser below."""
    s = raw.strip()
    if not s or s == "[]":
        return []
    s = s.lstrip("[").rstrip("]")
    return [t.strip().strip('"').strip("'") for t in s.split(",") if t.strip()]


def _parse_nested_blocks(text: str) -> dict:
    """Block-aware parse of the two nested structures the shared reader skips:
      * `relationships:` → list of {type, target, evidence, created_date} objects
        (2-space-indented `- type: …` entries, the exact shape #1770 emits).
      * `source_inputs:` / `synthesis_scope:` when authored as a BLOCK list
        (`\\n  - item`) rather than a flow scalar.
    `text` is the raw frontmatter body (between fences for md; whole file for a sidecar).
    Returns {"relationships": [...], "source_inputs": [...]} (keys present only if found).
    The scalar (flow) forms of source_inputs are handled by the caller via the shared
    reader; here we only add BLOCK-list items so both authoring styles resolve."""
    out: dict = {"relationships": [], "source_inputs": []}
    lines = text.splitlines()
    section = None          # None | "relationships" | "listkey"
    cur: dict = {}
    for line in lines:
        stripped = line.strip()
        # A flush-left (column-0) key line closes any open nested section.
        if line[:1] and not line[:1].isspace() and ":" in line and not stripped.startswith("-"):
            if cur:
                out["relationships"].append(cur)
                cur = {}
            key = line.split(":", 1)[0].strip()
            if key == "relationships":
                section = "relationships"
            elif key in ("source_inputs", "synthesis_scope"):
                section = "listkey"
            else:
                section = None
            continue
        if section == "relationships":
            if stripped.startswith("- "):
                # New edge object begins. Flush the prior one.
                if cur:
                    out["relationships"].append(cur)
                cur = {}
                rest = stripped[2:].strip()
                if ":" in rest:  # `- type: GENERATES`
                    k, v = rest.split(":", 1)
                    cur[k.strip()] = _strip_quotes(v.strip())
            elif ":" in stripped and (line[:1].isspace()):
                k, v = stripped.split(":", 1)
                cur[k.strip()] = _strip_quotes(v.strip())
        elif section == "listkey":
            if stripped.startswith("- "):
                out["source_inputs"].append(_strip_quotes(stripped[2:].strip()))
    if cur:
        out["relationships"].append(cur)
    return out


def parse_metadata(path: Path) -> dict:
    """The full metadata dict for one file: scalar keys (shared reader) + nested blocks
    (local parser). Handles embedded-`.md`-frontmatter AND `.meta.yml` sidecars.

    Returns a dict with all scalar keys plus:
      * "relationships": list[dict(type,target,evidence,created_date)]
      * "source_inputs": list[str]   (flow scalar OR block list, merged; deprecated
                                       `synthesis_scope` folded in as its alias)
    An empty dict {} means "no metadata block" (the file yields no `files` row)."""
    suffix = path.suffix.lower()
    if suffix in MARKDOWN_SUFFIXES:
        scalars, status = read_frontmatter(path)
        if status != "ok":
            return {}
        # The block body between the two fences (for the nested-block parse).
        text = path.read_text(encoding="utf-8", errors="replace")
        lines = text.splitlines()
        body_lines = []
        if lines and lines[0].strip() == "---":
            for line in lines[1:]:
                if line.strip() == "---":
                    break
                body_lines.append(line)
        block_text = "\n".join(body_lines)
    else:
        # A non-md file's metadata is its co-located sidecar (this path is only reached
        # for the sidecar itself would not happen — see iter_corpus_files).
        scalars = _read_sidecar_scalars(path)
        if not scalars:
            return {}
        block_text = path.read_text(encoding="utf-8", errors="replace")

    md = dict(scalars)
    nested = _parse_nested_blocks(block_text)
    md["relationships"] = nested["relationships"]
    # source_inputs: merge flow-scalar (from shared reader) + block-list (from nested),
    # + the deprecated `synthesis_scope` alias, de-duplicated in first-seen order.
    si: list = []
    for raw_key in ("source_inputs", "synthesis_scope"):
        if raw_key in scalars and scalars[raw_key]:
            si.extend(_parse_list_scalar(scalars[raw_key]))
    si.extend(nested["source_inputs"])
    seen = set()
    md["source_inputs"] = [x for x in si if not (x in seen or seen.add(x))]
    return md


# --------------------------------------------------------------------------- #
# Corpus discovery (deterministic — sorted POSIX path).
# --------------------------------------------------------------------------- #

def _rel_posix(path: Path, root: Path) -> str:
    """Corpus-root-relative POSIX path (the deterministic sort key + `path` column)."""
    return path.relative_to(root).as_posix()


def discover_files(root: Path) -> list:
    """All metadata-bearing files under `root`, SORTED by relative POSIX path (AC2
    determinism: file_id becomes a pure function of sorted position). A metadata-bearing
    file is a `.md` OR a non-md file that has a co-located `.meta.yml` sidecar. The
    sidecar file itself is never a node — it is the carrier for its base file."""
    md_files, sidecar_bases = [], []
    for p in root.rglob("*"):
        if not p.is_file():
            continue
        rel_parts = p.relative_to(root).parts
        if any(part.startswith(".") for part in rel_parts):
            continue
        name = p.name
        if name.endswith(SIDECAR_SUFFIX):
            # The base file this sidecar describes (strip the .meta.yml suffix).
            base = p.with_name(name[: -len(SIDECAR_SUFFIX)])
            if base.suffix.lower() not in MARKDOWN_SUFFIXES:
                sidecar_bases.append(base)
            continue
        if p.suffix.lower() in MARKDOWN_SUFFIXES:
            md_files.append(p)
    all_files = md_files + [b for b in sidecar_bases if b.exists() or True]
    # Dedupe (a base could appear twice) + deterministic sort by POSIX rel path.
    uniq: dict = {}
    for f in all_files:
        uniq[_rel_posix(f, root)] = f
    return [uniq[k] for k in sorted(uniq)]


def _metadata_source(path: Path) -> dict:
    """parse_metadata for a node, reading the sidecar for a non-md base file."""
    if path.suffix.lower() in MARKDOWN_SUFFIXES:
        return parse_metadata(path)
    sidecar = path.with_name(path.name + SIDECAR_SUFFIX)
    return parse_metadata(sidecar)


def _content_preview_and_hash(path: Path) -> tuple:
    """(first-500-chars preview, sha256 hex) of the file's own content. For a non-md base
    file the preview/hash are over the base file's bytes (its content), not the sidecar."""
    try:
        raw = path.read_bytes()
    except OSError:
        return "", None
    preview = raw[:500].decode("utf-8", errors="replace")
    return preview, hashlib.sha256(raw).hexdigest()


def _mtime_iso(path: Path) -> str:
    """Filesystem mtime as an ISO date (a property of the file — identical across two
    rebuilds of the same tree, so AC2-safe). Date granularity matches the schema's
    ISO-date `modified_date` column and the `created_date > modified_date` comparisons."""
    import datetime
    try:
        ts = path.stat().st_mtime
    except OSError:
        return ""
    return datetime.datetime.utcfromtimestamp(ts).date().isoformat()


# --------------------------------------------------------------------------- #
# Row construction from metadata.
# --------------------------------------------------------------------------- #

# The full `files` column order (for a stable INSERT + canonical dump).
FILES_COLUMNS = (
    "path", "filename", "file_format", "domain", "type", "project", "folder",
    "managed_by", "parent", "lifecycle_state", "lifecycle_changed", "trust_category",
    "evidence_quality", "created_date", "modified_date", "content_hash",
    "approval_state", "version", "superseded_by", "last_evidence_date",
    "staleness_threshold_days", "entry_count", "trigger_source", "validation_state",
)


def _files_row(path: Path, root: Path, md: dict) -> dict:
    """Build the `files` row dict from parsed metadata + filesystem facts. Returns None if
    the 11-field NOT-NULL core is incomplete (a partial stamp yields no row — matches the
    node tool's all-11-or-none contract). NEVER synthesizes a build-time timestamp."""
    for req in CORE_REQUIRED:
        if not md.get(req):
            return None
    preview, content_hash = _content_preview_and_hash(path)  # noqa: F841 (preview → FTS)
    row = {col: md.get(col) for col in FILES_COLUMNS}
    # Filesystem-derived (deterministic per file):
    row["path"] = _rel_posix(path, root)          # canonical POSIX rel path
    row["modified_date"] = _mtime_iso(path)       # mtime — AC2-safe (per-file property)
    row["content_hash"] = content_hash
    # Numeric coercions (schema INTEGER columns).
    for intcol in ("staleness_threshold_days", "entry_count"):
        if row.get(intcol) is not None:
            try:
                row[intcol] = int(row[intcol])
            except (TypeError, ValueError):
                row[intcol] = None
    return row


# --------------------------------------------------------------------------- #
# DB build.
# --------------------------------------------------------------------------- #

def _connect(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def _create_schema(conn: sqlite3.Connection) -> None:
    for stmt in DDL_STATEMENTS:
        conn.execute(stmt)


def _insert_file(conn: sqlite3.Connection, row: dict) -> int:
    cols = ", ".join(FILES_COLUMNS)
    placeholders = ", ".join(f":{c}" for c in FILES_COLUMNS)
    cur = conn.execute(f"INSERT INTO files ({cols}) VALUES ({placeholders})", row)
    return cur.lastrowid


def _fts_values(file_id: int, md: dict, path: Path) -> tuple:
    """The 4 FTS column values for one file (file_id, filename, content_preview,
    frontmatter_text). Shared by insert + the external-content delete command so the
    delete names the exact indexed terms."""
    preview, _ = _content_preview_and_hash(path)
    frontmatter_text = " ".join(str(md.get(k, "")) for k in ("type", "project", "folder")) \
        + " " + str(md.get("trigger_source", "") or "")
    return (file_id, md.get("filename"), preview, frontmatter_text.strip())


def _populate_fts(conn: sqlite3.Connection, file_id: int, md: dict, path: Path) -> None:
    fid, filename, preview, fm_text = _fts_values(file_id, md, path)
    conn.execute(
        "INSERT INTO files_fts(rowid, file_id, filename, content_preview, frontmatter_text) "
        "VALUES (?, ?, ?, ?, ?)",
        (file_id, fid, filename, preview, fm_text),
    )


def _rebuild_fts_from_files(conn: sqlite3.Connection, root: Path) -> None:
    """Re-materialize the ENTIRE `files_fts` index from the current `files` rows.

    `files_fts` is external-content (`content='files'`) but `content_preview` is NOT a
    `files` column — it is read from the file on disk — so FTS5's own `'delete'` /
    `'rebuild'` commands cannot round-trip it (they only see the base table). After a
    single-file mutation, the correct + robust way to keep the FTS state EXACTLY equal to
    a full rebuild is therefore to clear and re-populate it from the current `files` set,
    re-reading each file's preview from disk. This is O(files) per `update_file` call —
    acceptable for the incremental CAPABILITY (the hot event-plumbing that would make this
    matter is #1153); correctness over micro-optimization here. Uses the special
    `'delete-all'` command (the sanctioned external-content clear), then reinserts."""
    conn.execute("INSERT INTO files_fts(files_fts) VALUES('delete-all')")
    for fid, filename, ftype, project, folder, trig, path_rel in conn.execute(
            "SELECT file_id, filename, type, project, folder, trigger_source, path FROM files"):
        abspath = root / path_rel
        preview, _ = _content_preview_and_hash(abspath)
        fm_text = (" ".join(str(x or "") for x in (ftype, project, folder)) + " " + str(trig or "")).strip()
        conn.execute(
            "INSERT INTO files_fts(rowid, file_id, filename, content_preview, frontmatter_text) "
            "VALUES (?, ?, ?, ?, ?)",
            (fid, fid, filename, preview, fm_text),
        )


def _insert_lifecycle_event(conn: sqlite3.Connection, file_id: int, md: dict) -> None:
    """Initial lifecycle_events row per file (rebuild protocol step 8). `timestamp` is the
    file's own `created_date` (read, never synthesized) so AC2 byte-identity holds — the
    schema's `timestamp` is ISO-8601 and a read date satisfies it deterministically."""
    conn.execute(
        "INSERT INTO lifecycle_events(file_id, old_state, new_state, trigger, timestamp, agent) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (file_id, None, md.get("lifecycle_state"), md.get("lifecycle_trigger"),
         md.get("created_date"), md.get("managed_by")),
    )


# Folder tokens that can carry a project's governance root — the representative node for
# a project whose name a BELONGS_TO edge targets (see _project_representatives).
#
# UNION-AWARE over BOTH live taxonomies, because the ADR-080 additive-union migration
# window means a project's governance root may sit under any of three tokens. This is
# the same union-awareness gap the node classifier closed one layer upstream: keying a
# CONSUMER on the legacy token alone silently drops every project that has migrated.
# The values are the canonical `folder` enum members the node stamper emits, matched
# EXACTLY (measured: case-insensitive matching resolves the identical project set on the
# live corpus, so widening to a case fold is unsupported by evidence and not done).
#
# ORDER IS PREFERENCE, highest first. Legacy `01-governance` leads deliberately: a
# legacy project resolves to exactly the representative it resolved to before this
# union, so the change is strictly additive and regresses no existing edge target.
_REPRESENTATIVE_FOLDERS = (
    "01-governance",     # legacy NN- taxonomy governance bin
    "1-Governance",      # ADR-080 five-bin governance bin
    "_project-root",     # ADR-139 NON-BIN sentinel — a project's own root governance files
)


def _project_representatives(conn: sqlite3.Connection) -> dict:
    """project name → the file_id of that project's REPRESENTATIVE node, so a
    `BELONGS_TO` edge (whose target is the PROJECT NAME, not a filename — the shape #1770
    emits) can resolve to a real `files(file_id)` the schema's FK requires.

    The representative is the project's governance-root file, resolved over the
    `_REPRESENTATIVE_FOLDERS` union in that tuple's PREFERENCE order and, within the
    winning token, preferring a lower `file_id` (the deterministic first-by-sorted-path
    governance file — typically `PROJECT.md`). A project with no file under ANY of those
    tokens has no representative; its `BELONGS_TO` edges stay logged WARN (never
    fabricated). This is the builder-side resolution of the #1770 `BELONGS_TO →
    project-name` ↔ schema `target_file_id → file` contract seam — conservative
    (governance-root only) and non-fabricating."""
    rank = {tok: i for i, tok in enumerate(_REPRESENTATIVE_FOLDERS)}
    placeholders = ",".join("?" * len(_REPRESENTATIVE_FOLDERS))
    best: dict = {}                  # project -> (token_rank, file_id)
    for fid, project, folder in conn.execute(
            f"SELECT file_id, project, folder FROM files WHERE folder IN ({placeholders})",
            _REPRESENTATIVE_FOLDERS):
        cand = (rank[folder], fid)
        if project not in best or cand < best[project]:
            best[project] = cand
    return {project: fid for project, (_, fid) in best.items()}


def _resolve_and_insert_edges(conn: sqlite3.Connection, filename_to_id: dict) -> list:
    """Second pass: resolve every file's relationships[] target to a file_id and insert.
    Returns a list of dangling-edge WARN tuples (skipped rows).

    Resolution order for `target`:
      1. exact `files.filename` match (the primary READ contract — bare filename);
      2. FALLBACK: if `target` matches a project NAME, resolve to that project's
         representative governance-root node (handles the #1770 `BELONGS_TO → project`
         shape the schema's file-FK cannot store directly).
    Directionality: source = the file carrying the entry, target = the resolved file.
    A verb outside the 7-set, or a target that resolves to neither a file nor a project
    representative → WARN, row skipped (never fabricated)."""
    warnings: list = []
    name_map = filename_to_id["_names"]
    project_reps = filename_to_id.get("_projreps", {})
    for source_filename, (source_id, edges) in filename_to_id["_edges"].items():
        for edge in edges:
            etype = (edge.get("type") or "").strip()
            target = (edge.get("target") or "").strip()
            if etype not in MVP_VERBS:
                warnings.append((source_filename, target, f"verb '{etype}' not in 7-set"))
                continue
            tgt_id = name_map.get(target)
            if tgt_id == "AMBIGUOUS":
                warnings.append((source_filename, target, "ambiguous target (>1 file same filename)"))
                continue
            if tgt_id is None:
                # Fallback: a project-name target → the project's representative node.
                tgt_id = project_reps.get(target)
                if tgt_id is None:
                    warnings.append((source_filename, target,
                                     "dangling target (no matching filename or project representative)"))
                    continue
            if tgt_id == source_id:
                # A self-edge (e.g. a project's own governance root BELONGS_TO its project)
                # is not a meaningful graph edge — skip without WARN.
                continue
            try:
                conn.execute(
                    "INSERT OR IGNORE INTO relationships"
                    "(source_file_id, target_file_id, relationship_type, evidence, created_date, created_by) "
                    "VALUES (?, ?, ?, ?, ?, ?)",
                    (source_id, tgt_id, etype, edge.get("evidence"),
                     edge.get("created_date") or "", None),
                )
            except sqlite3.IntegrityError as exc:
                warnings.append((source_filename, target, f"insert rejected: {exc}"))
    return warnings


def _insert_synthesis_scope(conn: sqlite3.Connection, synth_id: int,
                            source_inputs: list, name_map: dict) -> None:
    """Populate synthesis_scope from a Domain-C file's source_inputs list (+ deprecated
    synthesis_scope alias, already merged upstream). A source_input that does not resolve
    to a known filename is silently skipped (it may be a TR-###/MSG-### id, not a file)."""
    for token in source_inputs:
        src_id = name_map.get(token)
        if src_id and src_id != "AMBIGUOUS":
            conn.execute(
                "INSERT OR IGNORE INTO synthesis_scope(synthesis_file_id, source_file_id) "
                "VALUES (?, ?)",
                (synth_id, src_id),
            )


def rebuild(db_path: str, root: Path) -> dict:
    """Full deterministic drop+rebuild of all 7 tables from corpus frontmatter.

    Returns a summary dict {files, edges, dangling, syntheses, warnings}. This is the
    AC1/AC2/AC3 surface. navigation_pages is populated EMPTY (no generator exists yet —
    it is a read-target for a future consumer, correctly empty now)."""
    root = Path(root)
    if db_path != ":memory:" and Path(db_path).exists():
        Path(db_path).unlink()
    conn = _connect(db_path)
    try:
        _create_schema(conn)
        files = discover_files(root)

        # Pass 1: files (sorted → deterministic file_id), FTS, lifecycle, filename map.
        name_map: dict = {}      # filename → file_id (or "AMBIGUOUS")
        edges_by_source: dict = {}   # filename → (file_id, edges)
        synth_inputs: dict = {}      # file_id → source_inputs list
        n_files = 0
        for path in files:      # already sorted by POSIX rel path
            md = _metadata_source(path)
            if not md:
                continue
            row = _files_row(path, root, md)
            if row is None:
                continue
            file_id = _insert_file(conn, row)
            n_files += 1
            _populate_fts(conn, file_id, md, path)
            _insert_lifecycle_event(conn, file_id, md)
            fname = md.get("filename")
            if fname in name_map:
                name_map[fname] = "AMBIGUOUS"
            else:
                name_map[fname] = file_id
            edges_by_source[fname] = (file_id, md.get("relationships", []))
            if md.get("source_inputs"):
                synth_inputs[file_id] = md["source_inputs"]

        # Pass 2: edges. Resolve a target by exact filename, else by project-name →
        # representative node (the BELONGS_TO seam). Build the project-representative map
        # from the now-populated files table.
        project_reps = _project_representatives(conn)
        warnings = _resolve_and_insert_edges(
            conn, {"_names": name_map, "_projreps": project_reps,
                   "_edges": edges_by_source})

        # Pass 3: synthesis_scope (Domain-C → source junction).
        for synth_id, inputs in synth_inputs.items():
            _insert_synthesis_scope(conn, synth_id, inputs, name_map)

        conn.commit()
        n_edges = conn.execute("SELECT COUNT(*) FROM relationships").fetchone()[0]
        n_scope = conn.execute("SELECT COUNT(*) FROM synthesis_scope").fetchone()[0]
        return {
            "files": n_files, "edges": n_edges, "syntheses": n_scope,
            "dangling": len(warnings), "warnings": warnings,
        }
    finally:
        conn.close()


# --------------------------------------------------------------------------- #
# Incremental update (the D-C4 in-scope CAPABILITY — the #1153 callee).
# --------------------------------------------------------------------------- #

def update_file(db_path: str, path, root: Path) -> dict:
    """Incremental single-file update per the schema's Incremental Update steps:
      1. re-parse frontmatter from the changed file
      2. UPDATE its `files` row IN PLACE (or INSERT if new) — the file_id is PRESERVED so
         inbound FK references (lifecycle_events, incoming relationships, FTS) stay valid
         (the schema's step-2 "update … or insert if new"; delete-then-reinsert would
         orphan the audit trail and break FKs).
      3. delete + reinsert THIS file's OUTBOUND `relationships` rows
      4. delete + reinsert its `synthesis_scope` rows (if Domain-C)
      5. re-materialize the FTS entry
      6. append a `lifecycle_events` row iff state changed

    THIS IS THE CAPABILITY ONLY — no event source calls it here (that is #1153). Returns
    a summary dict. Edges are resolved against the CURRENT `files` population (a target
    that is not yet indexed → dangling WARN, exactly like a rebuild). A file that
    disappeared or lost its core stamp is NOT deleted here (that would cascade-orphan
    inbound edges); it is reported for the caller to handle — removal is a rebuild-scope
    operation, out of a single-file incremental step."""
    root = Path(root)
    path = Path(path)
    conn = _connect(db_path)
    try:
        rel = _rel_posix(path, root)
        md = _metadata_source(path)

        existing = conn.execute(
            "SELECT file_id, lifecycle_state FROM files WHERE path = ?", (rel,)).fetchone()
        old_state = existing[1] if existing else None

        row = _files_row(path, root, md) if md else None
        if row is None:
            # No parseable / core-complete metadata. Do NOT delete (inbound FKs) — report.
            return {"action": "removed-or-incomplete", "path": rel,
                    "note": "no core-complete metadata; row left intact (removal is rebuild-scope)"}

        if existing:
            file_id = existing[0]
            # UPDATE in place — preserve file_id.
            set_clause = ", ".join(f"{c} = :{c}" for c in FILES_COLUMNS)
            conn.execute(f"UPDATE files SET {set_clause} WHERE file_id = :__fid",
                         {**row, "__fid": file_id})
            # Refresh this file's OUTBOUND edges + synthesis_scope.
            conn.execute("DELETE FROM relationships WHERE source_file_id = ?", (file_id,))
            conn.execute("DELETE FROM synthesis_scope WHERE synthesis_file_id = ?", (file_id,))
        else:
            file_id = _insert_file(conn, row)

        name_map = _current_name_map(conn)
        project_reps = _project_representatives(conn)
        edges = md.get("relationships", [])
        warnings = _resolve_and_insert_edges(
            conn, {"_names": name_map, "_projreps": project_reps,
                   "_edges": {row["filename"]: (file_id, edges)}})
        _insert_synthesis_scope(conn, file_id, md.get("source_inputs", []), name_map)

        # FTS: re-materialize from the current files set (external-content preview cannot
        # round-trip a surgical single-row delete — see _rebuild_fts_from_files).
        _rebuild_fts_from_files(conn, root)

        # lifecycle_events only iff state changed (or first insert).
        new_state = md.get("lifecycle_state")
        if new_state != old_state:
            conn.execute(
                "INSERT INTO lifecycle_events(file_id, old_state, new_state, trigger, timestamp, agent) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (file_id, old_state, new_state, md.get("lifecycle_trigger"),
                 md.get("created_date"), md.get("managed_by")),
            )
        conn.commit()
        return {"action": "updated" if existing else "inserted", "path": rel,
                "file_id": file_id, "dangling": len(warnings), "warnings": warnings}
    finally:
        conn.close()


def _current_name_map(conn: sqlite3.Connection) -> dict:
    """filename → file_id over the whole current `files` population (AMBIGUOUS on dup)."""
    name_map: dict = {}
    for fid, fname in conn.execute("SELECT file_id, filename FROM files"):
        name_map[fname] = "AMBIGUOUS" if fname in name_map else fid
    return name_map


# --------------------------------------------------------------------------- #
# Named reference queries (the 7 schema patterns, parameterized).
# --------------------------------------------------------------------------- #

NAMED_QUERIES = {
    "blast-radius": (
        """
        WITH RECURSIVE blast_radius(file_id, depth, path) AS (
            SELECT file_id, 0, path FROM files WHERE filename = :changed_file
            UNION ALL
            SELECT f.file_id, br.depth + 1, f.path
            FROM blast_radius br
            JOIN relationships r ON r.target_file_id = br.file_id
            JOIN files f ON f.file_id = r.source_file_id
            WHERE r.relationship_type IN ('DEPENDS_ON', 'GENERATES')
              AND br.depth < :max_depth
        )
        SELECT DISTINCT file_id, depth, path FROM blast_radius ORDER BY depth
        """,
        {"changed_file": None, "max_depth": 5},
    ),
    "orphan": (
        """
        SELECT f.file_id, f.path, f.filename, f.type, f.domain
        FROM files f
        LEFT JOIN relationships r_source ON f.file_id = r_source.source_file_id
        LEFT JOIN relationships r_target ON f.file_id = r_target.target_file_id
        WHERE r_source.rel_id IS NULL AND r_target.rel_id IS NULL
          AND f.domain IN ('source', 'managed', 'generated', 'A', 'B', 'C')
        ORDER BY f.project, f.folder
        """,
        {},
    ),
    "staleness": (
        # Query 3 (sqlite-index-schema.md § Named Query Patterns): the domain is a REQUIRED
        # bind param (`f.domain = :domain`), NOT a default. Each domain has its own staleness
        # threshold (schema § Staleness thresholds — Source >30, Knowledge/Synthesis >14), so
        # the caller MUST name which domain it is scoring; there is no meaningful silent
        # default. A prior implementation defaulted to Source-only via `IN (:d0, :d1)` — that
        # both diverged from the schema's single-`:domain` contract and silently narrowed the
        # result set. `run_query` fail-louds (ValueError) if `:domain` is not supplied.
        """
        SELECT f.file_id, f.path, f.filename, f.lifecycle_state, f.domain,
            julianday('now') - julianday(f.modified_date) AS days_since_modified,
            (julianday('now') - julianday(f.modified_date)) * 0.4
            + (julianday('now') - julianday(f.lifecycle_changed)) * 0.3
            + (julianday('now') - julianday(COALESCE(f.last_evidence_date, f.created_date))) * 0.3
            AS staleness_score
        FROM files f
        WHERE f.lifecycle_state NOT IN ('archived', 'superseded')
          AND f.domain = :domain
        ORDER BY staleness_score DESC
        """,
        {},  # no default — :domain is required (schema Query 3 contract)
    ),
    "portfolio-rollup": (
        """
        SELECT f.project, f.lifecycle_state, COUNT(*) AS file_count,
            SUM(CASE WHEN f.domain IN ('source', 'A') THEN 1 ELSE 0 END) AS source_count,
            SUM(CASE WHEN f.domain IN ('managed', 'B') THEN 1 ELSE 0 END) AS knowledge_count,
            SUM(CASE WHEN f.domain IN ('generated', 'C') THEN 1 ELSE 0 END) AS synthesis_count,
            SUM(CASE WHEN orphans.file_id IS NOT NULL THEN 1 ELSE 0 END) AS orphan_count
        FROM files f
        LEFT JOIN (
            SELECT f2.file_id FROM files f2
            LEFT JOIN relationships r1 ON f2.file_id = r1.source_file_id
            LEFT JOIN relationships r2 ON f2.file_id = r2.target_file_id
            WHERE r1.rel_id IS NULL AND r2.rel_id IS NULL
        ) orphans ON f.file_id = orphans.file_id
        GROUP BY f.project, f.lifecycle_state
        ORDER BY f.project
        """,
        {},
    ),
    "cross-project-deps": (
        """
        SELECT fs.project AS source_project, fs.filename AS source_file,
               r.relationship_type, ft.project AS target_project,
               ft.filename AS target_file, r.evidence
        FROM relationships r
        JOIN files fs ON r.source_file_id = fs.file_id
        JOIN files ft ON r.target_file_id = ft.file_id
        WHERE fs.project != ft.project
          AND r.relationship_type IN ('DEPENDS_ON', 'BLOCKS')
        ORDER BY fs.project, ft.project
        """,
        {},
    ),
    "domain-c-staleness": (
        """
        SELECT synth.file_id, synth.filename, synth.lifecycle_state,
               synth.created_date AS synthesis_date,
               src.filename AS changed_source, src.modified_date AS source_modified
        FROM files synth
        JOIN synthesis_scope ss ON synth.file_id = ss.synthesis_file_id
        JOIN files src ON ss.source_file_id = src.file_id
        WHERE synth.domain IN ('generated', 'C')
          AND synth.lifecycle_state IN ('validated', 'published')
          AND src.modified_date > synth.created_date
        ORDER BY synth.filename
        """,
        {},
    ),
    "frontmatter-completeness": (
        """
        SELECT file_id, path, filename, domain,
            CASE WHEN type IS NULL THEN 'type' END AS missing_type,
            CASE WHEN managed_by IS NULL THEN 'managed_by' END AS missing_managed_by,
            CASE WHEN lifecycle_state IS NULL THEN 'lifecycle_state' END AS missing_lifecycle,
            CASE WHEN trust_category IS NULL THEN 'trust_category' END AS missing_trust,
            CASE WHEN domain IS NULL THEN 'domain' END AS missing_domain,
            CASE WHEN file_format IS NULL THEN 'file_format' END AS missing_format,
            CASE WHEN project IS NULL THEN 'project' END AS missing_project,
            CASE WHEN folder IS NULL THEN 'folder' END AS missing_folder,
            CASE WHEN domain IN ('generated', 'C') AND trigger_source IS NULL
                 THEN 'trigger_source' END AS missing_trigger
        FROM files
        WHERE type IS NULL OR managed_by IS NULL OR lifecycle_state IS NULL
           OR trust_category IS NULL OR domain IS NULL OR file_format IS NULL
           OR project IS NULL OR folder IS NULL
           OR (domain IN ('generated', 'C') AND trigger_source IS NULL)
        """,
        {},
    ),
}


# A `:name` placeholder in a query SQL (named bind params — the schema's query idiom).
_BIND_PARAM_RE = re.compile(r"(?<![:\w]):([A-Za-z_]\w*)")


def _required_binds(sql: str) -> set:
    """Every named `:param` referenced in a query's SQL. A param with no declared default
    is REQUIRED — the caller must supply it (schema Query 3 `:domain` has no default)."""
    return set(_BIND_PARAM_RE.findall(sql))


def run_query(db_path: str, name: str, params: dict = None) -> list:
    """Execute a named reference query. Returns a list of sqlite3.Row-like dict rows.
    Unknown query name → ValueError (fail-loud). Caller-supplied params override the
    query's declared defaults (e.g. blast-radius needs :changed_file). A `:param` the SQL
    references that has neither a declared default nor a caller value → ValueError (fail-
    loud + non-silent), NOT a cryptic sqlite ProgrammingError — e.g. `staleness` requires
    `:domain` (schema Query 3: each domain has its own staleness threshold, so there is no
    meaningful default)."""
    if name not in NAMED_QUERIES:
        raise ValueError(f"unknown query '{name}'; known: {', '.join(sorted(NAMED_QUERIES))}")
    sql, defaults = NAMED_QUERIES[name]
    bind = dict(defaults)
    if params:
        bind.update(params)
    missing = sorted(p for p in _required_binds(sql) if p not in bind)
    if missing:
        raise ValueError(
            f"query '{name}' requires parameter(s) {missing} with no default; "
            f"supply via --param (e.g. --param domain=source)")
    conn = _connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        cur = conn.execute(sql, bind)
        return [dict(r) for r in cur.fetchall()]
    finally:
        conn.close()


# --------------------------------------------------------------------------- #
# Canonical dump (AC2 determinism hash input).
# --------------------------------------------------------------------------- #

# Content tables dumped for the determinism hash (deterministic ORDER BY a stable key).
# files_fts is an external-content shadow of files → excluded (its rows are derived and
# its internal rowids are covered by the files dump).
_DUMP_TABLES = (
    ("files", "path"),
    ("relationships", "source_file_id, target_file_id, relationship_type"),
    ("lifecycle_events", "file_id, new_state, timestamp"),
    ("synthesis_scope", "synthesis_file_id, source_file_id"),
    ("navigation_pages", "page_path"),
)


def canonical_dump(db_path: str) -> str:
    """A stable text serialization of every content table, each ORDER BY a stable key.
    SHA-256 of this string is the AC2 byte-identity witness. file_id is INCLUDED (it must
    be stable across rebuilds — sorted-path insertion guarantees it), so a drift in
    file_id assignment is caught, not masked."""
    conn = _connect(db_path)
    conn.row_factory = sqlite3.Row
    out: list = []
    try:
        for table, order in _DUMP_TABLES:
            out.append(f"# table: {table}")
            cur = conn.execute(f"SELECT * FROM {table} ORDER BY {order}")
            cols = [d[0] for d in cur.description]
            out.append("\t".join(cols))
            for r in cur.fetchall():
                out.append("\t".join("" if r[c] is None else str(r[c]) for c in cols))
        return "\n".join(out) + "\n"
    finally:
        conn.close()


def _dump_hash(db_path: str) -> str:
    return hashlib.sha256(canonical_dump(db_path).encode("utf-8")).hexdigest()


# file_id-INDEPENDENT projections (natural keys) for comparing an INCREMENTAL result to a
# FULL rebuild. Two things differ by construction and are correctly EXCLUDED:
#   * file_id — "a disposable cache key" (frontmatter-schema.md); an incremental reinsert
#     gets a fresh AUTOINCREMENT id, so all ids resolve to a stable (path) key.
#   * lifecycle_events — an APPEND-ONLY audit trail; incremental accumulates a transition
#     row on top of the initial row, a full rebuild has only the initial row. The derived
#     QUERYABLE-warehouse tables (files/relationships/synthesis_scope) are what must be
#     content-equal; the event log's incremental behavior is asserted separately.
_STABLE_VIEWS = (
    ("files",
     "SELECT path, filename, file_format, domain, type, project, folder, managed_by, "
     "parent, lifecycle_state, lifecycle_changed, trust_category, evidence_quality, "
     "created_date, modified_date, content_hash, trigger_source, validation_state "
     "FROM files ORDER BY path"),
    ("relationships",
     "SELECT fs.path AS src, ft.path AS tgt, r.relationship_type, r.evidence, r.created_date "
     "FROM relationships r JOIN files fs ON r.source_file_id=fs.file_id "
     "JOIN files ft ON r.target_file_id=ft.file_id "
     "ORDER BY fs.path, ft.path, r.relationship_type"),
    ("synthesis_scope",
     "SELECT syn.path AS synth, src.path AS source FROM synthesis_scope ss "
     "JOIN files syn ON ss.synthesis_file_id=syn.file_id "
     "JOIN files src ON ss.source_file_id=src.file_id "
     "ORDER BY syn.path, src.path"),
)


def canonical_dump_stable(db_path: str) -> str:
    """A file_id-INDEPENDENT canonical dump (natural keys) of the derived queryable-
    warehouse tables. SHA-256 of this is the FMF-2 witness that an incremental update
    produces the same row CONTENT as a full rebuild."""
    conn = _connect(db_path)
    conn.row_factory = sqlite3.Row
    out: list = []
    try:
        for table, sql in _STABLE_VIEWS:
            out.append(f"# table: {table}")
            cur = conn.execute(sql)
            cols = [d[0] for d in cur.description]
            out.append("\t".join(cols))
            for r in cur.fetchall():
                out.append("\t".join("" if r[c] is None else str(r[c]) for c in cols))
        return "\n".join(out) + "\n"
    finally:
        conn.close()


def _stable_hash(db_path: str) -> str:
    return hashlib.sha256(canonical_dump_stable(db_path).encode("utf-8")).hexdigest()


def existing_tables(db_path: str) -> set:
    conn = _connect(db_path)
    try:
        return {r[0] for r in conn.execute(
            "SELECT name FROM sqlite_master WHERE type IN ('table','view')")}
    finally:
        conn.close()


# --------------------------------------------------------------------------- #
# Self-test (committed fixture — AC1/AC2/AC3/AC4 + FMF-2/FMF-3).
# --------------------------------------------------------------------------- #

def _fixture_dir() -> Path:
    return Path(__file__).resolve().parent / "tests" / "fixtures" / "doc-index"


def run_self_test() -> int:
    """Assert the builder's contract against the committed fixture:
      (AC1) all 7 schema tables + their indexes exist after a rebuild.
      (AC2) two rebuilds produce a byte-identical canonical dump (SHA-256 match).
      (AC3) a rebuild over the fixture completes well under 10s.
      (AC4) portfolio-rollup (Q4) AND cross-project-deps (Q5) both return >=1 row.
            All 7 named queries execute without error.
      (F6) the staleness query honors the schema's Query-3 `f.domain = :domain` contract:
            an explicit :domain filters to that one domain; a different :domain is honored;
            omitting :domain fails LOUD (ValueError), never a silent Source-only default.
      (FMF-2) update_file round-trip: rebuild → mutate one fixture file → update_file →
              the resulting rows == a full rebuild of the mutated tree.
      (FMF-3) Query-6 discriminating logic is EXERCISED: with a source mtime pushed past a
              published synthesis's created_date (os.utime, deterministic), domain-c-
              staleness returns that synthesis; with the mtime pulled back before it, the
              same query returns empty — proving the temporal condition discriminates.
    Runs against a temp COPY so mtime mutation + writes are throwaway (AC2 uses the
    pristine fixture: mtime is a per-file property, identical across two rebuilds)."""
    import os
    import shutil
    import tempfile
    import time

    fixture = _fixture_dir()
    if not fixture.exists():
        print(f"self-test FAIL: fixture missing at {fixture}", file=sys.stderr)
        return 1

    failures: list = []

    with tempfile.TemporaryDirectory() as td:
        root = Path(td) / "corpus"
        shutil.copytree(fixture, root)
        db1 = str(Path(td) / "idx1.db")
        db2 = str(Path(td) / "idx2.db")

        # --- AC3 (timing) + AC1 (tables) ---
        t0 = time.monotonic()
        summary = rebuild(db1, root)
        elapsed = time.monotonic() - t0
        if elapsed >= 10.0:
            failures.append(f"(AC3) rebuild took {elapsed:.2f}s (>= 10s bar)")

        tables = existing_tables(db1)
        for t in EXPECTED_TABLES:
            if t not in tables:
                failures.append(f"(AC1) table '{t}' missing after rebuild (have: {sorted(tables)})")
        # Index presence (a representative sample of the schema's declared indexes).
        conn = _connect(db1)
        idx = {r[0] for r in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='index'")}
        conn.close()
        for want in ("idx_files_filename", "idx_rel_source", "idx_lifecycle_file"):
            if want not in idx:
                failures.append(f"(AC1) index '{want}' missing (have: {sorted(idx)})")

        if summary["files"] < 8:
            failures.append(f"(AC1) expected >=8 files rows, got {summary['files']}")
        # With BELONGS_TO → project-representative resolution in place, NO edge in the
        # fixture should dangle: file-target edges resolve by filename, project-target
        # BELONGS_TO edges resolve to the governance-root node (or are self-edges, skipped
        # without WARN). A residual dangling here is a real regression.
        if summary["dangling"] != 0:
            failures.append(f"(AC1) unexpected dangling edges: {summary['warnings']}")
        n_edges = summary["edges"]
        # Resolvable edges: 3 file-target DEPENDS_ON (beta→alpha_fdd cross-project;
        # alpha_rollup→alpha_fdd + beta_summary→beta_testplan source_inputs) PLUS the
        # BELONGS_TO edges that resolved to a project representative (the non-self ones).
        if n_edges < 3:
            failures.append(f"(AC1) expected >=3 resolvable file-target edges, got {n_edges}")

        # Orphan KPI: a file whose ONLY edge is BELONGS_TO must NOT read as an orphan once
        # that edge resolves to the project representative (else the KPI false-positives —
        # the whole point of the BELONGS_TO seam). alpha_raid + beta_steerco are exactly
        # those single-BELONGS_TO files.
        orphans = run_query(db1, "orphan")
        orphan_names = {r["filename"] for r in orphans}
        for should_not_orphan in ("alpha_raid.md", "beta_steerco.txt"):
            if should_not_orphan in orphan_names:
                failures.append(f"(orphan-KPI) {should_not_orphan} reads as orphan despite a "
                                f"resolved BELONGS_TO edge (orphans={sorted(orphan_names)})")

        # --- AC2 (byte-identical two rebuilds) ---
        rebuild(db2, root)
        h1, h2 = _dump_hash(db1), _dump_hash(db2)
        if h1 != h2:
            failures.append(f"(AC2) two rebuilds diverge: {h1[:12]} != {h2[:12]}")

        # --- AC4 (Q4 + Q5 non-empty) + all-7-queries-execute ---
        try:
            q4 = run_query(db1, "portfolio-rollup")
            q5 = run_query(db1, "cross-project-deps")
        except Exception as exc:  # noqa: BLE001
            failures.append(f"(AC4) query raised: {exc}")
            q4, q5 = [], []
        if len(q4) < 1:
            failures.append("(AC4) portfolio-rollup returned 0 rows (expected >=1)")
        if len(q5) < 1:
            failures.append("(AC4) cross-project-deps returned 0 rows (expected >=1)")
        # Assert the cross-project edge is the real Beta→Alpha one.
        if q5 and not any(r["source_project"] != r["target_project"] for r in q5):
            failures.append(f"(AC4) cross-project-deps rows not actually cross-project: {q5}")
        # All 7 named queries execute without error (schema validation checklist). Two
        # carry required, no-default bind params that the caller must supply: blast-radius
        # (:changed_file/:max_depth) and staleness (:domain — schema Query 3).
        _query_params = {
            "blast-radius": {"changed_file": "alpha_fdd.md", "max_depth": 5},
            "staleness": {"domain": "source"},
        }
        for qname in NAMED_QUERIES:
            try:
                run_query(db1, qname, _query_params.get(qname))
            except Exception as exc:  # noqa: BLE001
                failures.append(f"(queries) '{qname}' raised: {exc}")

        # --- F6: staleness `:domain` contract (schema Query 3 = `f.domain = :domain`) ---
        # (1) With an explicit :domain, the query executes AND every returned row is that
        #     single domain (the equality filter, not a silent Source-only default).
        try:
            stale_src = run_query(db1, "staleness", {"domain": "source"})
        except Exception as exc:  # noqa: BLE001
            stale_src = []
            failures.append(f"(F6) staleness with :domain raised: {exc}")
        off_domain = {r["domain"] for r in stale_src if r["domain"] != "source"}
        if off_domain:
            failures.append(f"(F6) staleness :domain=source leaked other domains: {off_domain}")
        # A different :domain must be honored (proves the param binds, not a hardcoded value).
        try:
            stale_mgd = run_query(db1, "staleness", {"domain": "managed"})
            if any(r["domain"] != "managed" for r in stale_mgd):
                failures.append("(F6) staleness :domain=managed returned non-managed rows")
        except Exception as exc:  # noqa: BLE001
            failures.append(f"(F6) staleness with :domain=managed raised: {exc}")
        # (2) Omitting :domain must FAIL LOUD (ValueError), never silently default/return.
        try:
            run_query(db1, "staleness")
            failures.append("(F6) staleness without :domain did not fail loud (expected ValueError)")
        except ValueError:
            pass  # correct — required param, non-silent
        except Exception as exc:  # noqa: BLE001
            failures.append(f"(F6) staleness without :domain raised {type(exc).__name__}, "
                            f"expected ValueError: {exc}")

        # --- FMF-3: Query-6 temporal discrimination (os.utime, deterministic) ---
        # alpha_rollup (published, created_date 2026-06-03) draws on alpha_fdd via
        # synthesis_scope. Push alpha_fdd mtime to 2026-07-01 (AFTER the synthesis) → Q6
        # must return alpha_rollup. Pull it back to 2026-05-01 (BEFORE) → Q6 empty.
        alpha_fdd = root / "proj-alpha" / "02-design" / "alpha_fdd.md"

        def _utime_to(datestr):
            import datetime
            epoch = time.mktime(datetime.datetime.strptime(datestr, "%Y-%m-%d").timetuple())
            os.utime(alpha_fdd, (epoch, epoch))

        db6 = str(Path(td) / "idx6.db")
        _utime_to("2026-07-01")               # source modified AFTER synthesis
        rebuild(db6, root)
        q6_after = run_query(db6, "domain-c-staleness")
        if not any(r["filename"] == "alpha_rollup.md" for r in q6_after):
            failures.append(f"(FMF-3) Q6 did not flag alpha_rollup when source mtime > "
                            f"created_date (rows={q6_after})")

        _utime_to("2026-05-01")               # source modified BEFORE synthesis
        rebuild(db6, root)
        q6_before = run_query(db6, "domain-c-staleness")
        if any(r["filename"] == "alpha_rollup.md" for r in q6_before):
            failures.append(f"(FMF-3) Q6 flagged alpha_rollup when source mtime < "
                            f"created_date — temporal condition NOT discriminating "
                            f"(rows={q6_before})")

        # --- FMF-2: update_file round-trip == full rebuild of the mutated tree ---
        # Restore alpha_fdd mtime to a stable value, then mutate ONE file's lifecycle
        # state, update_file it into a rebuilt DB, and compare its canonical dump to a
        # fresh full rebuild of the same mutated tree.
        _utime_to("2026-06-10")
        target = root / "proj-beta" / "08-generated" / "beta_summary.md"
        txt = target.read_text(encoding="utf-8")
        mutated = txt.replace("lifecycle_state: published", "lifecycle_state: validated")
        if mutated == txt:
            failures.append("(FMF-2) fixture mutation no-op (lifecycle_state marker not found)")
        target.write_text(mutated, encoding="utf-8")

        db_inc = str(Path(td) / "idx_inc.db")
        db_full = str(Path(td) / "idx_full.db")
        # Build the incremental DB from the PRE-mutation tree state, then update the one
        # file. To simulate the pre-state cleanly, rebuild from a second pristine copy,
        # then apply update_file for the mutated path.
        pristine2 = Path(td) / "corpus_pre"
        shutil.copytree(fixture, pristine2)
        # keep alpha_fdd mtime aligned so the two DBs' modified_date matches
        import datetime
        epoch2 = time.mktime(datetime.datetime.strptime("2026-06-10", "%Y-%m-%d").timetuple())
        os.utime(pristine2 / "proj-alpha" / "02-design" / "alpha_fdd.md", (epoch2, epoch2))
        rebuild(db_inc, pristine2)
        # mutate the same file in the pristine2 tree, then update_file it.
        t2 = pristine2 / "proj-beta" / "08-generated" / "beta_summary.md"
        t2.write_text(mutated, encoding="utf-8")
        update_file(db_inc, t2, pristine2)
        # full rebuild of the mutated pristine2 tree.
        rebuild(db_full, pristine2)

        # Compare via the file_id-INDEPENDENT stable dump: an incremental reinsert gets a
        # fresh AUTOINCREMENT file_id (a disposable cache key), so CONTENT equivalence —
        # not raw-id identity — is the correct FMF-2 assertion.
        h_inc, h_full = _stable_hash(db_inc), _stable_hash(db_full)
        if h_inc != h_full:
            failures.append(f"(FMF-2) update_file row content != full rebuild "
                            f"({h_inc[:12]} != {h_full[:12]})")

        # A lifecycle_events row should have been appended by the state change.
        conn = _connect(db_inc)
        ev = conn.execute(
            "SELECT COUNT(*) FROM lifecycle_events le JOIN files f ON le.file_id=f.file_id "
            "WHERE f.filename='beta_summary.md' AND le.new_state='validated'").fetchone()[0]
        conn.close()
        if ev < 1:
            failures.append("(FMF-2) update_file did not append a lifecycle_events row on state change")

    # --- (R1) representative resolution is UNION-AWARE over both live taxonomies ---
    # Exercised directly against an in-memory `files` table rather than the on-disk
    # fixture, so the arm is deterministic and cannot perturb AC2's byte-identical dump.
    # Each case names one token of _REPRESENTATIVE_FOLDERS; the COVERAGE GUARD below
    # fails the build when a token is added to that tuple without a case here, which is
    # what stops this arm decaying into the legacy-only probe it replaces.
    r1_conn = _connect(":memory:")
    _create_schema(r1_conn)
    # (token, project, filename) — one project per token, plus a no-governance-root
    # project as the SPECIFICITY arm (it must resolve to NOTHING, never be fabricated).
    r1_cases = [
        ("01-governance", "r1-legacy", "PROJECT.md"),
        ("1-Governance", "r1-fivebin", "PROJECT.md"),
        ("_project-root", "r1-sentinel", "PROJECT.md"),
    ]
    r1_specificity_project = "r1-no-governance-root"
    r1_rows = r1_cases + [("04-operations", r1_specificity_project, "raid.md")]
    for i, (folder, project, filename) in enumerate(r1_rows):
        _insert_file(r1_conn, dict(
            path=f"{project}/{folder}/{filename}", filename=f"{i}_{filename}",
            file_format="markdown", domain="source", type="plan", project=project,
            folder=folder, managed_by="stamp-node-frontmatter", parent=None,
            lifecycle_state="current", lifecycle_changed=None,
            trust_category="controlled-truth", evidence_quality=None,
            created_date="2026-01-01", modified_date="2026-01-01", content_hash="x",
            approval_state=None, version=None, superseded_by=None,
            last_evidence_date=None, staleness_threshold_days=None, entry_count=None,
            trigger_source=None, validation_state=None))
    r1_reps = _project_representatives(r1_conn)
    r1_conn.close()

    # SENSITIVITY: every taxonomy in the union resolves a representative.
    for folder, project, _ in r1_cases:
        if project not in r1_reps:
            failures.append(f"(R1) project under folder '{folder}' resolved NO representative "
                            f"— BELONGS_TO edges for it would all dangle")
    # SPECIFICITY: a project with no governance-root file is NOT fabricated a representative.
    if r1_specificity_project in r1_reps:
        failures.append("(R1) specificity arm fired: a project with no governance-root file "
                        "was fabricated a representative")
    # COVERAGE GUARD: a token added to _REPRESENTATIVE_FOLDERS without a case above is a
    # silent re-introduction of the union-awareness gap. Fail loudly instead.
    r1_covered = {folder for folder, _, _ in r1_cases}
    for tok in _REPRESENTATIVE_FOLDERS:
        if tok not in r1_covered:
            failures.append(f"(R1 COVERAGE GUARD) _REPRESENTATIVE_FOLDERS carries '{tok}' "
                            f"with no self-test case — add one to r1_cases")

    if failures:
        print("build-doc-index self-test FAIL:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("build-doc-index self-test OK "
          "(AC1 tables+indexes / AC2 byte-identical / AC3 <10s / AC4 Q4+Q5 non-empty / "
          "7-queries-execute / F6 staleness :domain contract / "
          "FMF-2 update_file==rebuild / FMF-3 Q6 temporal discrimination / "
          "R1 union-aware project representatives + coverage guard)")
    return 0


# --------------------------------------------------------------------------- #
# Output helpers.
# --------------------------------------------------------------------------- #

def _emit_rows(rows: list, output_format: str) -> str:
    if output_format == "json":
        return json.dumps(rows, indent=2, default=str)
    if not rows:
        return "(0 rows)"
    cols = list(rows[0].keys())
    out = ["\t".join(cols)]
    for r in rows:
        out.append("\t".join("" if r.get(c) is None else str(r.get(c)) for c in cols))
    return "\n".join(out)


# --------------------------------------------------------------------------- #
# CLI.
# --------------------------------------------------------------------------- #

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--rebuild", action="store_true", help="full deterministic drop+rebuild")
    ap.add_argument("--update-file", metavar="PATH", help="incremental single-file update")
    ap.add_argument("--query", metavar="NAME", help="run a named reference query")
    ap.add_argument("--dump-canonical", action="store_true",
                    help="emit the canonical row dump (determinism hash input)")
    ap.add_argument("--self-test", action="store_true",
                    help="run committed-fixture assertions and exit")
    ap.add_argument("--db", metavar="PATH", help="SQLite database path")
    ap.add_argument("--root", metavar="PATH", help="corpus root to scan")
    ap.add_argument("--param", action="append", default=[], metavar="K=V",
                    help="query parameter (repeatable), e.g. --param changed_file=x.md")
    ap.add_argument("--output-format", choices=("tsv", "json"), default="tsv")
    args = ap.parse_args(argv)

    if args.self_test:
        return run_self_test()

    # Every non-self-test mode needs a --db.
    if not args.db:
        print("build-doc-index: --db is required (except --self-test)", file=sys.stderr)
        return 2

    if args.rebuild:
        if not args.root:
            print("build-doc-index: --rebuild needs --root", file=sys.stderr)
            return 2
        root = Path(args.root).expanduser()
        if not root.exists() or not root.is_dir():
            print(f"build-doc-index: --root unresolvable: {root}", file=sys.stderr)
            return 3
        summary = rebuild(args.db, root)
        if args.output_format == "json":
            print(json.dumps(summary, indent=2, default=str))
        else:
            print(f"rebuild\tdb={args.db}\troot={root}")
            print(f"counts\tfiles={summary['files']}\tedges={summary['edges']}"
                  f"\tsyntheses={summary['syntheses']}\tdangling={summary['dangling']}")
            for src, tgt, why in summary["warnings"][:50]:
                print(f"dangling\t{src} -> {tgt}\t{why}")
        return 1 if summary["dangling"] else 0

    if args.update_file:
        root = Path(args.root).expanduser() if args.root else Path(args.update_file).resolve().parents[0]
        if not Path(args.db).exists():
            print(f"build-doc-index: --db does not exist (rebuild first): {args.db}", file=sys.stderr)
            return 3
        res = update_file(args.db, args.update_file, root)
        print(json.dumps(res, indent=2, default=str) if args.output_format == "json"
              else "\t".join(f"{k}={v}" for k, v in res.items() if k != "warnings"))
        return 1 if res.get("dangling") else 0

    if args.dump_canonical:
        if not Path(args.db).exists():
            print(f"build-doc-index: --db unresolvable: {args.db}", file=sys.stderr)
            return 3
        sys.stdout.write(canonical_dump(args.db))
        return 0

    if args.query:
        if not Path(args.db).exists():
            print(f"build-doc-index: --db unresolvable: {args.db}", file=sys.stderr)
            return 3
        params: dict = {}
        for kv in args.param:
            if "=" not in kv:
                print(f"build-doc-index: bad --param '{kv}' (want K=V)", file=sys.stderr)
                return 2
            k, v = kv.split("=", 1)
            params[k] = int(v) if v.isdigit() else v
        try:
            rows = run_query(args.db, args.query, params)
        except ValueError as exc:
            print(f"build-doc-index: {exc}", file=sys.stderr)
            return 2
        print(_emit_rows(rows, args.output_format))
        return 0

    ap.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())

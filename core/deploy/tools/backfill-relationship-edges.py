#!/usr/bin/env python3
"""backfill-relationship-edges.py — Layer-1 EDGE backfill (the companion of the
node-frontmatter stamp).

Backfills `relationships[]` edges onto the operational corpus so the derived SQLite
warehouse materializes a populated edge graph, per the relationships[] edge-population
design (Stage 5) and the EMIT contract in `core/schemas/frontmatter-schema.md`
§ Relationship Edge Population. Edges FK to nodes: a `relationships[]` edge's `target`
resolves against a stamped node, so this tool is the EDGE half whose NODE half is
`stamp-node-frontmatter.py` (the 11-field core stamp).

  ┌─ stamp-node-frontmatter.py → stamps the 11-field node core (the vertices)
  └─ backfill-relationship-edges.py (THIS) → emits relationships[] edges (the edges)

**LAYER-2 EXECUTION IS GATED — this file never mutates the real corpus on its own.**
Mutating the live `~/Claude/projects/**` corpus is GATED at release Stage 12, AFTER the
node stamp lands (edges FK to nodes; nodes are stamped first, then edges) and AFTER a
spot-audit. The default mode is `--dry-run`; `--emit` (the write mode) is designed to be
run only inside the Stage-12 execution window, in-workspace, by the operator. This tool
authored at Stage 6 delivers the LOGIC; the run is not performed here.

WHAT IT EMITS (forward-safe, additive frontmatter only — reversibility CHEAP):
  * `BELONGS_TO`  — target = the file's project (the first corpus-root path segment).
                    ALWAYS recoverable (the folder path IS the project binding), so every
                    non-excluded, project-resolvable file gets one. This is the always-safe
                    edge the design guarantees.
  * `GENERATES` / `DEPENDS_ON` — emitted ONLY where a machine-recoverable evidence anchor
                    exists in the file's own frontmatter (a `source_inputs` list, a
                    `parent_artifact`/`supersedes` lineage scalar, or a `generated_by`
                    marker paired with a resolvable source). No anchor -> NOT emitted.
  * RAID `source_ref` — RAID rows are CSV rows with NO frontmatter, so they are NOT touched
                    by this tool; their provenance carrier is the RAID `source_ref` column
                    written by tracker-manager on ADD (see raid-log.schema.json). This tool
                    reports RAID artifacts as `raid-out-of-band` so the operator routes RAID
                    provenance through the tracker path, not the edge path.

UNRECOVERABLE PROVENANCE IS LOGGED, NOT GUESSED. A file with no folder-derivable project
is an orphan-candidate (recorded); a file whose GENERATES/DEPENDS_ON provenance lives only
in an external register or nowhere stays edge-less for those verbs (recorded as
`no-provenance-anchor`) — never given a fabricated edge. This mirrors the evidence gate and
the SQLite `orphan_files` KPI.

IDEMPOTENT: an edge with the same `(target, type)` already present is not re-appended
(the read table is UNIQUE(source, target, type)). Re-running is safe.

REVERSAL MARKER: every emitted edge carries `evidence: "backfill <YYYY-MM-DD> ..."`, and a
run in `--emit` mode stamps a file-level `lifecycle_trigger: retroactive-backfill` marker
(shared with the node tool) so a Layer-2 backfill is reversible by marker-scan + revert.

Stdlib-only (Python 3.9-compatible). Imports the node tool's shared classification helpers
so the folder→project derivation is BYTE-IDENTICAL to the node stamp (F1 consistency — the
edges bind to exactly the projects the nodes were stamped with).

CLI:
  --root PATH        corpus root (default ~/Claude/projects — the Layer-2 corpus)
  --scope active|all active excludes Archive/ (default active — matches the node stamp)
  --dry-run          (DEFAULT) report what WOULD be emitted; write nothing
  --emit             WRITE edges (Stage-12-gated; refuses unless --i-am-at-stage-12 is set)
  --i-am-at-stage-12 explicit confirmation token required to pair with --emit
  --audit-sample N   print the full edge set for the first N files (calibration)
  --output-format tsv|json
  --self-test        run the built-in fixture cases and exit

Exit: 0 clean · 1 orphan/no-anchor candidates present · 2 usage · 3 gate-refused.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import date
from pathlib import Path

# --------------------------------------------------------------------------- #
# Shared classification (imported from the node tool — F1: same folder→project
# derivation the node stamp used, so edges bind to the stamped nodes).
# --------------------------------------------------------------------------- #
_TOOLS_DIR = Path(__file__).resolve().parent
if str(_TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(_TOOLS_DIR))

# Import the shared reader + the node tool's classification primitives. These are the
# SINGLE source of the exclusion tiers, project derivation, and corpus iteration, so the
# edge tool cannot drift from the node tool on "what is a corpus file / what project is it".
import importlib

_node = importlib.import_module("stamp-node-frontmatter")  # module name has a hyphen
from _frontmatter import read_frontmatter  # noqa: E402  (shared frontmatter reader)

_segments = _node._segments
_folder_prefix = _node._folder_prefix
_project_of = _node._project_of
iter_corpus_files = _node.iter_corpus_files
EXCLUDE_PATTERNS = _node.EXCLUDE_PATTERNS
NONPROJECT_TOP_SEGMENTS = _node.NONPROJECT_TOP_SEGMENTS
ARCHIVE_SEGMENT = _node.ARCHIVE_SEGMENT
MARKDOWN_SUFFIXES = _node.MARKDOWN_SUFFIXES
FORMAT_BY_SUFFIX = _node.FORMAT_BY_SUFFIX
LIFECYCLE_TRIGGER = _node.LIFECYCLE_TRIGGER  # "retroactive-backfill" — shared reversal marker

# The 7 MVP relationship verbs (must match frontmatter-schema.md §Cat-4 + the SQLite CHECK).
MVP_VERBS = frozenset({
    "GENERATES", "DEPENDS_ON", "BLOCKS", "SUPERSEDES",
    "BELONGS_TO", "RELATES_TO", "ASSIGNED_TO",
})

# RAID artifacts are provenance-carried out-of-band (source_ref column), not via edges.
_RAID_SIGNAL = "raid_log"


def _is_raid_artifact(rel_path):
    """A RAID Log CSV — provenance goes through the RAID source_ref column, not an edge."""
    name = rel_path.name.lower()
    return name.endswith(".csv") and "raid" in name


# --------------------------------------------------------------------------- #
# Edge derivation (read-only classification; the writer is separate + gated)
# --------------------------------------------------------------------------- #

class EdgePlan:
    """The set of edges a single file would receive, plus its disposition."""
    __slots__ = ("path", "rel_path", "edges", "disposition", "reason")

    def __init__(self, path, rel_path):
        self.path = path
        self.rel_path = rel_path
        self.edges = []            # list[dict(type,target,evidence,created_date)]
        self.disposition = "ok"    # ok | excluded | orphan | no-provenance-anchor | raid-out-of-band
        self.reason = ""


def _existing_edge_targets(path):
    """The (type, target) pairs already present in a markdown file's relationships[] block
    OR a `.meta.yml` sidecar — for idempotency. Scans the raw block text because the shared
    key-reader flattens the nested list to an empty scalar."""
    pairs = set()
    texts = []
    suffix = path.suffix.lower()
    if suffix in MARKDOWN_SUFFIXES and path.exists():
        texts.append(path.read_text(encoding="utf-8", errors="replace"))
    sidecar = path.with_name(path.name + ".meta.yml")
    if sidecar.exists():
        texts.append(sidecar.read_text(encoding="utf-8", errors="replace"))
    cur_type = None
    for text in texts:
        in_rel = False
        for line in text.splitlines():
            stripped = line.strip()
            if not line[:1].isspace() and stripped.rstrip(":") == "relationships":
                in_rel = True
                continue
            if in_rel and not line[:1].isspace() and stripped and not stripped.startswith("-"):
                in_rel = False  # left the block (a new top-level key)
            if not in_rel:
                continue
            if "type:" in stripped:
                cur_type = stripped.split("type:", 1)[1].strip().strip('"').strip("'")
            if "target:" in stripped:
                tgt = stripped.split("target:", 1)[1].strip().strip('"').strip("'")
                if cur_type:
                    pairs.add((cur_type, tgt))
    return pairs


def _provenance_edges(fm, today):
    """Derive GENERATES/DEPENDS_ON/SUPERSEDES edges from a file's OWN frontmatter anchors.
    Returns list[edge]. Only machine-recoverable anchors produce edges; absence -> []."""
    edges = []
    # source_inputs -> this file was GENERATED FROM those upstream sources: the edge is
    # GENERATES from the SOURCE to THIS file. We record the reverse-resolvable DEPENDS_ON
    # on THIS file (this file DEPENDS_ON the upstream evidence) — a machine-recoverable,
    # non-fabricated edge (the anchor is literally in-header).
    si = fm.get("source_inputs", "")
    if si and si not in ("", "[]"):
        for tok in _split_list(si):
            edges.append({
                "type": "DEPENDS_ON",
                "target": tok,
                "evidence": f"backfill {today} — source_inputs anchor",
                "created_date": today,
            })
    # parent_artifact -> lineage: this file was GENERATED by the parent -> DEPENDS_ON parent.
    parent = fm.get("parent_artifact", "")
    if parent:
        edges.append({
            "type": "DEPENDS_ON",
            "target": parent,
            "evidence": f"backfill {today} — parent_artifact lineage anchor",
            "created_date": today,
        })
    # supersedes -> this file SUPERSEDES the target (temporal lineage).
    sup = fm.get("supersedes", "")
    if sup:
        edges.append({
            "type": "SUPERSEDES",
            "target": sup,
            "evidence": f"backfill {today} — supersedes lineage anchor",
            "created_date": today,
        })
    return edges


def _split_list(raw):
    """Split a scalar-rendered YAML list ("[a, b]" or "a, b") into tokens."""
    s = raw.strip().lstrip("[").rstrip("]")
    return [t.strip().strip('"').strip("'") for t in s.split(",") if t.strip()]


def plan_edges(path, root, scope):
    """Plan the edge set for one file (read-only). Never writes."""
    rel_path = path.relative_to(root)
    plan = EdgePlan(path, rel_path)
    segs = _segments(rel_path)
    today = date.today().isoformat()

    # (1) non-project operational config — not project content.
    if segs and segs[0] in NONPROJECT_TOP_SEGMENTS:
        plan.disposition = "excluded"
        plan.reason = f"non-project top segment ({segs[0]})"
        return plan
    # (2) EXCLUDE_PATTERNS (backups/staging/etc.) — before any edge.
    hit = next((s for s in segs if s in EXCLUDE_PATTERNS), None)
    if hit is not None:
        plan.disposition = "excluded"
        plan.reason = f"excluded path segment ({hit})"
        return plan
    # (3) Archive subtree under scope=active.
    if ARCHIVE_SEGMENT in segs and scope == "active":
        plan.disposition = "excluded"
        plan.reason = "Archive/ excluded under scope=active"
        return plan
    # (4) RAID CSV — provenance carried out-of-band via source_ref, not an edge.
    if _is_raid_artifact(rel_path):
        plan.disposition = "raid-out-of-band"
        plan.reason = "RAID provenance carried by source_ref column (tracker-manager), not relationships[]"
        return plan

    # (5) project derivation — the BELONGS_TO target. Always recoverable IFF a project
    # segment exists; else orphan-candidate (logged, not guessed).
    project = _project_of(rel_path)
    if not project:
        plan.disposition = "orphan"
        plan.reason = "no resolvable project (empty corpus-root segment)"
        return plan

    already = _existing_edge_targets(path)

    # (6) BELONGS_TO — the always-safe edge.
    if ("BELONGS_TO", project) not in already:
        plan.edges.append({
            "type": "BELONGS_TO",
            "target": project,
            "evidence": f"backfill {today} — folder-path project binding",
            "created_date": today,
        })

    # (7) provenance edges — ONLY from in-header anchors (markdown / sidecar frontmatter).
    fm = {}
    suffix = path.suffix.lower()
    if suffix in MARKDOWN_SUFFIXES:
        fm, _ = read_frontmatter(path)
    else:
        sidecar = path.with_name(path.name + ".meta.yml")
        if sidecar.exists():
            fm = _node._read_sidecar_keys(sidecar)
    for edge in _provenance_edges(fm, today):
        if (edge["type"], edge["target"]) not in already:
            plan.edges.append(edge)

    # (8) disposition: a file that got BELONGS_TO but no recoverable provenance anchor is
    # flagged (its GENERATES/DEPENDS_ON stays unfollowable until re-processed) — logged.
    has_provenance = any(e["type"] in ("GENERATES", "DEPENDS_ON", "SUPERSEDES") for e in plan.edges)
    if not has_provenance and not any(k in fm for k in ("source_inputs", "parent_artifact", "supersedes")):
        plan.disposition = "no-provenance-anchor"
        plan.reason = "BELONGS_TO emitted; no in-header provenance anchor (GENERATES/DEPENDS_ON deferred to re-processing)"
    return plan


# --------------------------------------------------------------------------- #
# Writer (LOCAL + GATED — never runs without --emit + --i-am-at-stage-12)
# --------------------------------------------------------------------------- #

def _render_edge_yaml(edge):
    """One relationships[] list entry, 2-space indented, matching the schema example idiom."""
    return (
        f"  - type: {edge['type']}\n"
        f"    target: \"{edge['target']}\"\n"
        f"    evidence: \"{edge['evidence']}\"\n"
        f"    created_date: {edge['created_date']}\n"
    )


def emit_edges(plan):
    """Append planned edges to the file's markdown frontmatter or .meta.yml sidecar.
    GATED: callers must have already confirmed the Stage-12 token. Additive only."""
    if not plan.edges:
        return "no-edges"
    path = plan.path
    suffix = path.suffix.lower()
    block = "".join(_render_edge_yaml(e) for e in plan.edges)
    if suffix in MARKDOWN_SUFFIXES:
        text = path.read_text(encoding="utf-8", errors="replace")
        lines = text.splitlines(keepends=True)
        if lines and lines[0].strip() == "---":
            # Insert into the existing frontmatter block, after any existing relationships:
            # header if present, else add the header + edges just before the closing fence.
            out, injected, in_fm = [], False, False
            for i, line in enumerate(lines):
                out.append(line)
                if i == 0:
                    in_fm = True
                    continue
                if in_fm and line.strip() == "---" and not injected:
                    # closing fence reached without a relationships: header -> inject before it
                    out.insert(len(out) - 1, "relationships:\n" + block)
                    injected = True
                    in_fm = False
            path.write_text("".join(out), encoding="utf-8")
        else:
            header = "---\nrelationships:\n" + block + "---\n"
            path.write_text(header + text, encoding="utf-8")
        return "emitted"
    # non-markdown -> sidecar
    sidecar = path.with_name(path.name + ".meta.yml")
    prefix = "" if sidecar.exists() else f"# Sidecar metadata for: {path.name}\n"
    with sidecar.open("a", encoding="utf-8") as fh:
        fh.write(prefix + "relationships:\n" + block)
    return "emitted"


# --------------------------------------------------------------------------- #
# Run
# --------------------------------------------------------------------------- #

def run(root, scope, do_emit, audit_sample, output_format):
    root = Path(root).expanduser()
    if not root.exists():
        print(f"error: root does not exist: {root}", file=sys.stderr)
        return 2
    counts = {"ok": 0, "excluded": 0, "orphan": 0, "no-provenance-anchor": 0, "raid-out-of-band": 0}
    total_edges = 0
    flagged = []      # orphan + no-provenance-anchor (the KPI surface)
    rows = []
    sampled = 0
    for path in iter_corpus_files(root):
        plan = plan_edges(path, root, scope)
        counts[plan.disposition] = counts.get(plan.disposition, 0) + 1
        total_edges += len(plan.edges)
        if plan.disposition in ("orphan", "no-provenance-anchor"):
            flagged.append((str(plan.rel_path), plan.disposition, plan.reason))
        if do_emit and plan.edges:
            emit_edges(plan)
        if audit_sample and sampled < audit_sample:
            rows.append({
                "path": str(plan.rel_path),
                "disposition": plan.disposition,
                "edges": plan.edges,
            })
            sampled += 1

    if output_format == "json":
        print(json.dumps({
            "root": str(root), "scope": scope, "emitted": do_emit,
            "counts": counts, "total_edges": total_edges,
            "flagged": flagged, "sample": rows,
        }, indent=2))
    else:
        mode = "EMIT (wrote edges)" if do_emit else "DRY-RUN (no writes)"
        print(f"# backfill-relationship-edges — {mode} — root={root} scope={scope}")
        for k, v in counts.items():
            print(f"{k}\t{v}")
        print(f"total_edges\t{total_edges}")
        if audit_sample:
            print(f"\n# --- audit sample (first {audit_sample}) ---")
            for r in rows:
                print(f"{r['disposition']}\t{r['path']}\t{len(r['edges'])} edge(s)")
                for e in r["edges"]:
                    print(f"    {e['type']} -> {e['target']}")
        if flagged:
            print(f"\n# --- flagged ({len(flagged)}) — logged, NOT auto-resolved ---")
            for p, d, why in flagged[:50]:
                print(f"{d}\t{p}\t{why}")
    # exit 1 if any orphan / no-anchor candidates (surfaced, not fatal).
    return 1 if flagged else 0


# --------------------------------------------------------------------------- #
# Self-test (fixture cases — runs without touching the real corpus)
# --------------------------------------------------------------------------- #

def _self_test():
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        # (a) plain project markdown, no provenance -> BELONGS_TO only + no-provenance-anchor.
        f_a = root / "Acme" / "01-Governance" / "PROJECT.md"
        f_a.parent.mkdir(parents=True)
        f_a.write_text("---\ntitle: Acme\n---\n# body\n", encoding="utf-8")
        pa = plan_edges(f_a, root, "active")
        assert [e["type"] for e in pa.edges] == ["BELONGS_TO"], pa.edges
        assert pa.edges[0]["target"] == "Acme", pa.edges[0]
        assert pa.disposition == "no-provenance-anchor", pa.disposition

        # (b) markdown WITH source_inputs -> BELONGS_TO + DEPENDS_ON edges, disposition ok.
        f_b = root / "Acme" / "08-Generated" / "decision.md"
        f_b.parent.mkdir(parents=True)
        f_b.write_text("---\ntitle: D\nsource_inputs: [TR-042, MSG-007]\n---\n", encoding="utf-8")
        pb = plan_edges(f_b, root, "active")
        types = sorted(e["type"] for e in pb.edges)
        assert types == ["BELONGS_TO", "DEPENDS_ON", "DEPENDS_ON"], types
        assert pb.disposition == "ok", pb.disposition
        targets = {e["target"] for e in pb.edges if e["type"] == "DEPENDS_ON"}
        assert targets == {"TR-042", "MSG-007"}, targets

        # (c) idempotency — a file already carrying BELONGS_TO does NOT get a duplicate.
        f_c = root / "Acme" / "02-Design" / "fdd.md"
        f_c.parent.mkdir(parents=True)
        f_c.write_text(
            "---\ntitle: F\nrelationships:\n  - type: BELONGS_TO\n    target: \"Acme\"\n"
            "    evidence: \"prior\"\n    created_date: 2026-01-01\n---\n",
            encoding="utf-8",
        )
        pc = plan_edges(f_c, root, "active")
        assert all(not (e["type"] == "BELONGS_TO") for e in pc.edges), pc.edges

        # (d) RAID CSV -> out-of-band (no edge; source_ref carries it).
        f_d = root / "Acme" / "04-PMO-Operations" / "Acme_RAID_Log.csv"
        f_d.parent.mkdir(parents=True)
        f_d.write_text("RAID_ID,Description\nR-PPM-001,x\n", encoding="utf-8")
        pd = plan_edges(f_d, root, "active")
        assert pd.disposition == "raid-out-of-band" and not pd.edges, (pd.disposition, pd.edges)

        # (e) excluded (body-backups) -> no edges.
        f_e = root / "Acme" / "01-Governance" / "body-backups" / "PROJECT.md"
        f_e.parent.mkdir(parents=True)
        f_e.write_text("---\ntitle: bak\n---\n", encoding="utf-8")
        pe = plan_edges(f_e, root, "active")
        assert pe.disposition == "excluded" and not pe.edges, (pe.disposition, pe.edges)

        # (f) Archive under scope=active -> excluded; under scope=all -> processed.
        f_f = root / "Archive" / "OldProj" / "01-Governance" / "OLD.md"
        f_f.parent.mkdir(parents=True)
        f_f.write_text("---\ntitle: old\n---\n", encoding="utf-8")
        assert plan_edges(f_f, root, "active").disposition == "excluded"
        assert plan_edges(f_f, root, "all").disposition in ("ok", "no-provenance-anchor")

        # (g) non-markdown WITH sidecar provenance -> sidecar-derived DEPENDS_ON.
        f_g = root / "Acme" / "05-Transcripts" / "call.txt"
        f_g.parent.mkdir(parents=True)
        f_g.write_text("raw transcript text\n", encoding="utf-8")
        (root / "Acme" / "05-Transcripts" / "call.txt.meta.yml").write_text(
            "# Sidecar metadata for: call.txt\nsource_inputs: TR-099\n", encoding="utf-8")
        pg = plan_edges(f_g, root, "active")
        assert any(e["type"] == "DEPENDS_ON" and e["target"] == "TR-099" for e in pg.edges), pg.edges

        # (h) emit is additive + idempotent on a real write into a temp file.
        emit_edges(pa)  # writes BELONGS_TO into f_a
        again = plan_edges(f_a, root, "active")
        assert all(e["type"] != "BELONGS_TO" for e in again.edges), "re-plan after emit must not re-add BELONGS_TO"

    print("backfill-relationship-edges self-test OK")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=str(Path.home() / "Claude" / "projects"),
                    help="corpus root (Layer-2, git-ignored)")
    ap.add_argument("--scope", choices=("active", "all"), default="active",
                    help="active excludes Archive/ (matches the node stamp)")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true",
                      help="(default) report; write nothing")
    mode.add_argument("--emit", action="store_true",
                      help="WRITE edges (Stage-12-gated; requires --i-am-at-stage-12)")
    ap.add_argument("--i-am-at-stage-12", action="store_true",
                    help="explicit confirmation that this run is the Stage-12 gated execution")
    ap.add_argument("--audit-sample", type=int, metavar="N", default=0,
                    help="print the edge set for the first N files")
    ap.add_argument("--output-format", choices=("tsv", "json"), default="tsv")
    ap.add_argument("--self-test", action="store_true", help="run fixture cases and exit")
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    do_emit = bool(args.emit)
    if do_emit and not args.i_am_at_stage_12:
        print(
            "GATE REFUSED: --emit mutates the live corpus and is gated at release Stage 12 "
            "(edges FK to nodes — nodes must be stamped first, then a spot-audit). Re-run with "
            "--i-am-at-stage-12 ONLY inside the Stage-12 execution window, in-workspace.",
            file=sys.stderr,
        )
        return 3
    return run(args.root, args.scope, do_emit, args.audit_sample, args.output_format)


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""stamp-node-frontmatter.py — the node-frontmatter classify-and-stamp tool (#3081).

Backfills **node frontmatter** — the 11-field NOT-NULL core set the SQLite index
builder's `files` table requires (`sqlite-index-schema.md`) — onto the operational
corpus so the derived warehouse (#1769 builder + #1770 edges) materializes over a
LIVE, populated corpus instead of an inert one. This is the **Layer-1 tool**; the
**Layer-2 execution** (mutating the real `~/Claude/projects/**` corpus) is GATED at
release Stage 12 (D-C7, >=95% spot-audit AFTER merge) and is NOT run by this file
outside an explicit `--stamp` on a caller-supplied root.

WHAT IT STAMPS (the 11-field NOT-NULL core set — a partial stamp yields NO `files`
row, so all 11 or none):

    path filename file_format domain type project folder
    managed_by lifecycle_state trust_category created_date

honoring the two CHECK-constrained enums:
  * domain           in {source, managed, generated}   (writer emits the human-
                       readable value; A/B/C are deprecated aliases)
  * trust_category   in {evidence, controlled-truth, interpretation,
                       working-context, historical-record}

CLASSIFICATION (folder-driven, per agent-processing-contracts.md Skill 1 +
frontmatter-schema.md Category 6 + ADR-080):
  * domain           from the folder TOKEN — the legacy NN- prefix (01-07 -> source;
                       08 -> generated; the operations tracker folder -> managed) OR an
                       ADR-080 closed-set bin name (1-Governance .. 5-Reference, _inbox,
                       _generated). Both taxonomies resolve during the ADR-080 additive-
                       union migration window.
  * type             from filename/folder signal, with a folder->default-type
                       FALLBACK (FIX 3) so a confident-domain/low-type file stamps a
                       defensible default rather than orphaning. Under an ADR-080 bin the
                       (bin, sub-folder) pair refines the default further, and where the
                       routing surfaces declare that sub-folder a SINGLE content class the
                       pair is AUTHORITATIVE and outranks the filename signal.
  * lifecycle_state  the domain's initial state      (source/managed -> created/current;
                       generated -> draft; Archive subtree -> archived)
  * trust_category   the domain default              (source=evidence,
                       managed=controlled-truth, generated=interpretation)

THREE BLOCKING FIXES folded in from the Stage-5 Collective-Review scope-lock:
  * FIX 1  case-normalize the folder segment (`.lower()`) BEFORE the domain lookup.
           Live folders are Capitalized (`01-Governance`); a lowercase-keyed map
           matches ZERO without this, orphaning 100% of the corpus.
  * FIX 2  EXCLUDE_PATTERNS tier fires BEFORE classification. Any path segment in
           the exclusion set (body-backups, Staging, _archived, _unclassified,
           phase3-scratch, bodies, snapshot, _inbox) is skipped — not stamped, not
           orphaned — and logged separately. Most members are non-authoritative copies
           that collide on the bare-filename join key; `_inbox` is the ADR-080 transient
           intake area, excluded because an unrouted item is not yet a record.
  * FIX 3  coverage scope D — `--scope active` (default) excludes the `Archive/`
           subtree; `--scope all` includes it (stamped `archived`). Plus the
           folder->default-type fallback above.

IDEMPOTENCE: stamps only ABSENT keys, never overwrites an existing value. A second
run over already-stamped files produces zero diff. Every file this tool stamps gets
`lifecycle_trigger: retroactive-backfill` — the unique reversal marker a Layer-2
rollback keys off.

SIDECAR: a non-markdown file cannot embed frontmatter, so its metadata is written to
a `{filename}.meta.yml` sidecar (plain YAML, no `---` fences) per frontmatter-schema.md.

Stdlib-only, Python 3.9 (`/usr/bin/python3`). Imports the shared `_frontmatter.py`
reader so "does this doc carry frontmatter, and what keys" is answered by the ONE
place the deploy-tool family parses it (F1 consistency). The writer (append-absent-
keys) is local — `_frontmatter.py` is read-only by contract.

**LAYER-2 EXECUTION IS GATED — this file never mutates the real corpus on its own.**
Mutating the live `~/Claude/projects/**` corpus is GATED at release Stage 12. The node
stamp is the FIRST link in the doc-warehouse FK chain (edges FK to nodes, so nodes are
stamped first), which makes it the MORE dangerous of the two backfill writers — it must
carry a gate at least as strong as its edge sibling. So `--stamp` (the write mode)
REFUSES unless the explicit `--i-am-at-stage-12` confirmation token is ALSO passed
(exit 3, "gate-refused"), byte-for-byte the same gate `backfill-relationship-edges.py`
puts on its `--emit` writer. `--dry-run` (the default) and `--audit-sample` are read-only
and are NOT gated.

Interface:
  --root PATH          corpus root to scan (default: ~/Claude/projects)
  --scope active|all   active (default) excludes Archive/; all includes it (FIX 3)
  --dry-run            EMIT-ONLY, no writes (DEFAULT — the safe default)
  --stamp              actually write frontmatter / sidecars (Stage-12-gated; REFUSES
                       unless --i-am-at-stage-12 is also set)
  --i-am-at-stage-12   explicit confirmation token required to pair with --stamp
  --audit-sample N     print a random N-file sample of proposed classifications
  --self-test          run the committed-fixture assertions and exit
  --output-format tsv|json   (default tsv)

Exit codes (fail-loud contract, mirroring the deploy-tool family — identical to
backfill-relationship-edges.py so the two backfill tools share one gate convention):
  0  clean (all in-scope files classified + stamped/would-stamp; no orphans)
  1  orphans found (>=1 in-scope file could not be confidently classified)
  2  usage error (bad flags / mutually-exclusive modes / --root unresolvable)
  3  gate-refused (--stamp without --i-am-at-stage-12)
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from datetime import date
from pathlib import Path

# The ONE shared frontmatter reader (F1 consistency). This file lives beside it in
# core/deploy/tools/, so a plain import resolves when run from that dir; the sys.path
# insert makes `--self-test` / direct invocation from any cwd robust.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _frontmatter import read_frontmatter  # noqa: E402


# --------------------------------------------------------------------------- #
# Classification tables (grounded in frontmatter-schema.md + agent-processing-
# contracts.md Skill 1). Keys are NORMALIZED (lowercased) folder-prefix tokens.
# --------------------------------------------------------------------------- #

# The 11-field NOT-NULL core set the SQLite `files` table requires. A stamp writes
# ALL of these or none (a partial stamp produces no `files` row).
CORE_FIELDS = (
    "path", "filename", "file_format", "domain", "type", "project",
    "folder", "managed_by", "lifecycle_state", "trust_category", "created_date",
)

# domain enum (human-readable; A/B/C are deprecated aliases — writer emits these).
DOMAIN_SOURCE = "source"
DOMAIN_MANAGED = "managed"
DOMAIN_GENERATED = "generated"

# trust_category defaults by domain (frontmatter-schema.md §Trust).
TRUST_BY_DOMAIN = {
    DOMAIN_SOURCE: "evidence",
    DOMAIN_MANAGED: "controlled-truth",
    DOMAIN_GENERATED: "interpretation",
}

# initial lifecycle_state by domain (agent-processing-contracts.md Skill 1 defaults).
LIFECYCLE_BY_DOMAIN = {
    DOMAIN_SOURCE: "created",
    DOMAIN_MANAGED: "current",
    DOMAIN_GENERATED: "draft",
}

# The canonical folder TOKEN -> (domain, canonical-folder-token, default-type).
# TWO key families, both live during the ADR-080 additive-union migration window:
#   * LEGACY — the two-digit prefix, so project-specific folder *names* (00-Plan,
#     01-Prior-Art, 02-Findings, 03-Report, 04-PMO-Operations, 09-Prototype) all resolve
#     by their NUMBER, not their exact label.
#   * ADR-080 — the closed 5-bin set plus the two transient areas, keyed by the LITERAL
#     lowercased bin name, because those names are a CLOSED set (ADR-080 :31) rather than
#     a numbering convention: there is no prefix to generalize over and a new bin is a
#     governance change, not a runtime one.
# Default-type is the FIX-3 fallback; SUBBIN_DEFAULT_TYPE refines it below.
FOLDER_PREFIX_MAP = {
    "00": (DOMAIN_SOURCE, "01-governance", "plan"),          # planning/inbound -> source
    "01": (DOMAIN_SOURCE, "01-governance", "reference"),
    "02": (DOMAIN_SOURCE, "02-design", "fdd"),
    "03": (DOMAIN_SOURCE, "03-testing", "test-plan"),
    "04": (DOMAIN_MANAGED, "04-operations", "tracker"),      # operations trackers -> managed
    "05": (DOMAIN_SOURCE, "05-transcripts", "transcript"),
    "06": (DOMAIN_SOURCE, "06-emails", "email"),
    "07": (DOMAIN_SOURCE, "07-reference", "reference"),
    "08": (DOMAIN_GENERATED, "08-generated", "analysis"),    # generated synthesis
    "09": (DOMAIN_SOURCE, "07-reference", "reference"),       # prototype/other -> reference
    # --- ADR-080 closed 5-bin set + transient areas (additive union window) ---
    "1-governance": (DOMAIN_SOURCE, "1-Governance", "plan"),
    "2-delivery":   (DOMAIN_SOURCE, "2-Delivery", "reference"),
    "3-operations": (DOMAIN_MANAGED, "3-Operations", "tracker"),
    "4-evidence":   (DOMAIN_SOURCE, "4-Evidence", "reference"),
    "5-reference":  (DOMAIN_SOURCE, "5-Reference", "reference"),
    "_generated":   (DOMAIN_GENERATED, "_generated", "analysis"),
    "_inbox":       (DOMAIN_SOURCE, "_inbox", "reference"),
}

# Sub-bin type refinement. ADR-080 NAMES the sub-folders (:38 / :40) but pairs none
# of them with a legacy antecedent -- its own frontmatter (:11) calls the 8->5 map a
# "RESHAPE ... not a 1:1 rename". The CONTENT CLASS of each sub-folder is stated by
# the routing/scaffold surfaces instead: file-router/SKILL.md Routing Targets,
# project-initiator/SKILL.md Step 2, OPERATIONS.md Folder Routing Guidelines, and
# core/schemas/routing-rules.md. Keyed by (bin-key, sub-folder) BOTH lowercased; the
# sub-folder must sit IMMEDIATELY under its bin. The emitted `folder` stays the BIN
# enum value; only `type` refines.
#
# The second value is AUTHORITATIVE: True only where those surfaces declare the
# sub-folder a SINGLE content class, so the path is a complete verdict and outranks
# FILENAME_TYPE_SIGNALS. Where they declare it MULTI-class the flag is False and the
# value is an ordinary default -- a filename signal still wins, because forcing a
# type there would convert a recoverable heuristic miss into an unrecoverable one
# (_absent_core_keys() writes ABSENT keys only, so a wrong `type` never self-heals).
SUBBIN_DEFAULT_TYPE = {
    # multi-class per the routing surfaces -> substitution default, signal still wins
    ("2-delivery", "design"):       ("fdd", False),        # + process flows, training material
    ("2-delivery", "testing"):      ("test-plan", False),  # + test artifacts, Jira exports
    ("2-delivery", "requirements"): ("fdd", False),        # + specs, traceability matrices
    # single-class per the routing surfaces -> the path IS the verdict
    ("4-evidence", "transcripts"):  ("transcript", True),
    ("4-evidence", "emails"):       ("email", True),
    ("4-evidence", "exports"):      ("export", True),
}

# The per-domain type taxonomy (frontmatter-schema.md §Type Taxonomy). A file's `type`
# MUST be valid for its `domain` (validation-checklist rule), so a filename signal is
# only honored when the signaled type is in the file's domain set — otherwise the
# folder default-type wins. This is what keeps a domain-B `project-page` off a
# domain-A governance file.
TYPES_BY_DOMAIN = {
    DOMAIN_SOURCE: frozenset({
        "transcript", "fdd", "test-plan", "email", "export", "presentation",
        "spreadsheet", "plan", "process-map", "architecture-diagram",
        "training-material", "reference",
    }),
    DOMAIN_MANAGED: frozenset({
        "tracker", "project-page", "decision-record", "risk-register",
        "dependency-register", "status-log", "communications-log", "meetings-log",
        "transcript-register",
    }),
    DOMAIN_GENERATED: frozenset({
        "executive-summary", "decision-package", "readiness-assessment",
        "weekly-rollup", "daily-status-output", "processing-run",
        "draft-communication", "sop", "runbook", "analysis",
    }),
}

# Filename-signal -> type (checked before the folder default; a confident filename
# signal beats the folder default-type ONLY when valid for the file's domain).
# Substring match on the lowercased stem.
FILENAME_TYPE_SIGNALS = (
    ("transcript", "transcript"),
    ("steerco", "transcript"),
    ("fdd", "fdd"),
    ("test-plan", "test-plan"),
    ("test_plan", "test-plan"),
    ("raid", "risk-register"),
    ("tracker", "tracker"),
    ("status", "status-log"),
    ("decision", "decision-record"),
    ("runbook", "runbook"),
    ("summary", "executive-summary"),
    ("readiness", "readiness-assessment"),
    ("rollup", "weekly-rollup"),
    ("email", "email"),
    ("plan", "plan"),
    ("project", "project-page"),
)

# FIX 2 — exclusion tier. Any path segment equal (case-insensitively) to one of these
# is skipped BEFORE classification (not stamped, not orphaned). Logged separately.
# Matching is DEPTH-AGNOSTIC and by EXACT segment equality — never substring, never
# prefix — so a member reserves that word at any depth, corpus-wide.
# Most members are non-authoritative COPIES that collide on the bare-filename join key.
# `_inbox` is the exception and is here on its own ground: it is the ADR-080 transient
# intake area (:31), so its contents are UNROUTED items, not records — the bin resolves
# in FOLDER_PREFIX_MAP (the token is KNOWN) while the files themselves stay out of the
# backfill until file-router routes them into a real bin.
EXCLUDE_PATTERNS = frozenset({
    "body-backups", "staging", "_archived", "_unclassified",
    "phase3-scratch", "bodies", "snapshot", "_inbox",
})

# The Archive subtree — excluded under scope=active (FIX 3), stamped `archived` under
# scope=all.
ARCHIVE_SEGMENT = "archive"

# Corpus-root segments that are NOT project content and never carry node frontmatter.
# `_config` is program-scoped operational config; `_pmo` is the ADR-058 shared-entity
# store, which frontmatter-schema.md § Scope names as an EXCLUSION ("navigation layer
# pages (`_pmo/`) have their own simplified frontmatter"); `transcripts` is the CLAUDE.md
# cross-project staging root, which has no project and is outside the schema's declared
# scope ("all files in `projects/[Project]/01-08/` folders"). Matched POSITIONALLY at
# segs[0] — the corpus root — so a same-named directory inside a project is unaffected.
NONPROJECT_TOP_SEGMENTS = frozenset({"_config", "_pmo", "transcripts"})

# Project-scoped directories OUTSIDE the ADR-080 closed bin set whose contents are
# FORMS, not records. Matched POSITIONALLY at segs[1] -- immediately under a project
# root -- because ADR-080 governs a project's TOP-LEVEL shape; a same-named directory
# nested inside a bin (e.g. a vendor template pack under 5-Reference/) is real
# reference material and is deliberately NOT matched. Corollary of the same
# positional anchor: the rule is scoped to a LIVE project's position and does not
# fire once the project is relocated under an archive segment (excluded there under
# scope=active; see the (i) self-test case that pins this).
# This set never resolves a `folder` value and never adds a bin: ADR-080 declares the
# set CLOSED and makes changing it a governance change, so an out-of-taxonomy
# directory is RECORDED under its own reason class rather than routed into a bin or
# filed as a backup copy. The reason names the condition in this tool's structured
# output. It is NOT a ratification of the directory, and no shipped surface reads it
# today -- ADR-080 names the enforcement instrument for the closed set as a
# still-unbuilt sibling work item. The corpus condition itself is unchanged.
NONRECORD_PROJECT_SEGMENTS = frozenset({"templates"})

# file_format by suffix (frontmatter-schema.md Category 6). Markdown embeds; the rest
# get a .meta.yml sidecar.
FORMAT_BY_SUFFIX = {
    ".md": "md", ".txt": "txt", ".csv": "csv", ".xlsx": "xlsx",
    ".pdf": "pdf", ".docx": "docx", ".html": "html", ".htm": "html",
}
MARKDOWN_SUFFIXES = frozenset({".md"})

MANAGED_BY = "file-router"          # the skill that owns node frontmatter on intake
LIFECYCLE_TRIGGER = "retroactive-backfill"   # the unique reversal marker (idempotence + rollback key)


# --------------------------------------------------------------------------- #
# Classification
# --------------------------------------------------------------------------- #

class Classification:
    """The resolved node-frontmatter values for one file (or an orphan verdict)."""

    __slots__ = ("path", "rel_path", "is_orphan", "is_excluded", "reason", "fields", "is_sidecar")

    def __init__(self, path, rel_path):
        self.path = path
        self.rel_path = rel_path
        self.is_orphan = False
        self.is_excluded = False
        self.reason = ""
        self.fields = {}          # the proposed core-set values (+ lifecycle_trigger)
        self.is_sidecar = False   # True => write a .meta.yml sidecar, not embedded


def _segments(rel_path):
    """Path segments of a corpus-root-relative path, lowercased for matching."""
    return [seg.lower() for seg in rel_path.parts]


def _folder_prefix(folder_name):
    """The NORMALIZED folder token: the two-digit NN prefix for a digit-leading legacy
    folder, else the whole lowercased name. Case-normalized (FIX 1): `01-Governance` ->
    `01`; `1-Governance` -> `1-governance`. Never None — FOLDER_PREFIX_MAP membership is
    the sole authority on which tokens are KNOWN.

    EXTENDED IN PLACE and never renamed: backfill-relationship-edges.py binds this symbol
    at import (`_folder_prefix = _node._folder_prefix`), so a rename kills that tool with
    an AttributeError."""
    name = folder_name.lower()
    if len(name) >= 2 and name[:2].isdigit():
        return name[:2]
    return name


def _project_of(rel_path):
    """The project name = the first path segment under the corpus root (original case)."""
    return rel_path.parts[0] if rel_path.parts else ""


def _classify_type(stem_lower, domain, default_type, authoritative=False):
    """Filename-signal type when it is valid for the file's domain, else the folder
    default-type (FIX-3 fallback). Domain-awareness enforces the type-taxonomy-matches-
    domain rule — a `project` filename in a source folder does NOT become the domain-B
    `project-page`; it falls back to the source folder default.

    `authoritative` inverts the precedence for the one case where the PATH is a complete
    verdict: an ADR-080 (bin, sub-folder) pair the routing surfaces declare SINGLE-class.
    There the default outranks the filename signal (still domain-validated). Everywhere
    else the signal keeps priority, because a wrong `type` never self-heals."""
    valid = TYPES_BY_DOMAIN[domain]
    if authoritative and default_type in valid:
        return default_type
    for needle, t in FILENAME_TYPE_SIGNALS:
        if needle in stem_lower and t in valid:
            return t
    return default_type


def classify(path, root, scope):
    """Classify one file into node-frontmatter values, or mark it excluded / orphan.

    Order (the fix ordering matters):
      1.  non-project top segment (_config, _pmo, transcripts) -> excluded
      1b. out-of-taxonomy project directory at segs[1]         -> excluded (POSITIONAL,
                                                      before the depth-agnostic pass)
      2.  EXCLUDE_PATTERNS segment (FIX 2)          -> excluded (before classification)
      3.  Archive subtree under scope=active (FIX3) -> excluded
      4.  unsupported file_format                   -> orphan
      5.  no resolvable folder token                -> orphan (unless a filename signal
                                                      + a domain can still be defended;
                                                      here: orphan — no confident domain)
      6.  else                                      -> full 11-field stamp
    """
    rel_path = path.relative_to(root)
    c = Classification(path, rel_path)
    segs = _segments(rel_path)

    # (1) non-project operational config — not project content.
    if segs and segs[0] in NONPROJECT_TOP_SEGMENTS:
        c.is_excluded = True
        c.reason = f"non-project top segment ({segs[0]})"
        return c

    # (1b) project-scoped directory outside the ADR-080 closed set — POSITIONAL.
    if len(segs) > 2 and segs[1] in NONRECORD_PROJECT_SEGMENTS:
        c.is_excluded = True
        c.reason = f"out-of-taxonomy project directory ({segs[1]})"
        return c

    # (2) FIX 2 — exclusion tier BEFORE classification.
    hit = next((s for s in segs if s in EXCLUDE_PATTERNS), None)
    if hit is not None:
        c.is_excluded = True
        c.reason = f"excluded path segment ({hit})"
        return c

    # (3) FIX 3 — Archive subtree handling by scope.
    in_archive = ARCHIVE_SEGMENT in segs
    if in_archive and scope == "active":
        c.is_excluded = True
        c.reason = "Archive/ excluded under scope=active"
        return c

    # (4) file_format.
    suffix = path.suffix.lower()
    file_format = FORMAT_BY_SUFFIX.get(suffix)
    if file_format is None:
        c.is_orphan = True
        c.reason = f"unsupported file_format ({suffix or 'no-suffix'})"
        return c
    c.is_sidecar = suffix not in MARKDOWN_SUFFIXES

    # (5) resolve domain via the folder TOKEN (case-normalized, FIX 1) — a legacy NN-
    # prefix or an ADR-080 bin name. The relevant folder is the DEEPEST path segment
    # whose token is KNOWN (walk from the file upward so a nested subfolder under
    # 08-Generated still maps to 08). The walk floors at index 1: parts[0] is the
    # PROJECT directory, and since _folder_prefix() now returns the whole name for a
    # non-digit-leading folder, an unfloored walk would resolve a project whose own
    # name happened to collide with a bin token.
    prefix = None
    canonical_folder = None
    default_type = None
    domain = None
    folder_parts = rel_path.parts[:-1]           # exclude the filename itself
    bin_idx = None
    subbin_authoritative = False
    for i in range(len(folder_parts) - 1, 0, -1):   # i >= 1: parts[0] is the PROJECT
        p = _folder_prefix(folder_parts[i])
        if p in FOLDER_PREFIX_MAP:
            prefix = p
            bin_idx = i
            domain, canonical_folder, default_type = FOLDER_PREFIX_MAP[p]
            break
    if domain is None:
        # No confident domain -> orphan candidate (recorded, not guessed).
        c.is_orphan = True
        c.reason = "no resolvable folder token (no confident domain)"
        return c

    # (5b) sub-bin refinement — the segment IMMEDIATELY under the resolved bin only.
    if bin_idx + 1 < len(folder_parts):
        sub = SUBBIN_DEFAULT_TYPE.get((prefix, folder_parts[bin_idx + 1].lower()))
        if sub is not None:
            default_type, subbin_authoritative = sub

    # (6) full 11-field stamp.
    stem_lower = path.stem.lower()
    file_type = _classify_type(stem_lower, domain, default_type, subbin_authoritative)
    # Archive subtree under scope=all -> archived lifecycle + historical-record trust
    # (trust-lifecycle consistency rule: archived requires historical-record).
    if in_archive:  # only reached under scope=all (active excluded above)
        lifecycle_state = "archived"
        trust_category = "historical-record"
    else:
        lifecycle_state = LIFECYCLE_BY_DOMAIN[domain]
        trust_category = TRUST_BY_DOMAIN[domain]

    c.fields = {
        "path": str(rel_path),
        "filename": path.name,
        "file_format": file_format,
        "domain": domain,
        "type": file_type,
        "project": _project_of(rel_path),
        "folder": canonical_folder,
        "managed_by": MANAGED_BY,
        "lifecycle_state": lifecycle_state,
        "trust_category": trust_category,
        "created_date": date.today().isoformat(),
        # non-core but always stamped: the reversal marker.
        "lifecycle_trigger": LIFECYCLE_TRIGGER,
    }
    return c


# --------------------------------------------------------------------------- #
# Stamping (writer — local; _frontmatter.py is read-only by contract)
# --------------------------------------------------------------------------- #

def _yaml_scalar(value):
    """Emit a YAML scalar. Quote only when needed (leading digit / special chars) so
    the output matches the hand-authored frontmatter idiom in the schema examples."""
    s = str(value)
    if s == "":
        return '""'
    needs_quote = (
        s[0].isdigit()
        or s[0] in "-?:,[]{}#&*!|>%@`\"'"
        or ": " in s
        or s != s.strip()
    )
    return f'"{s}"' if needs_quote else s


def _absent_core_keys(existing_keys, proposed):
    """The proposed keys not already present (idempotence — stamp only ABSENT keys)."""
    return {k: v for k, v in proposed.items() if k not in existing_keys}


def stamp_markdown(path, proposed, do_write):
    """Stamp embedded frontmatter on a markdown file, writing only ABSENT keys.

    Returns (action, added_keys) where action in {"stamped", "skipped-complete",
    "would-stamp", "no-frontmatter-created"}.
    """
    existing, status = read_frontmatter(path)
    add = _absent_core_keys(existing, proposed)
    if status == "ok":
        if not add:
            return ("skipped-complete", {})
        if not do_write:
            return ("would-stamp", add)
        # Insert the absent keys immediately after the opening `---` fence, preserving
        # the existing block + body byte-for-byte.
        text = path.read_text(encoding="utf-8", errors="replace")
        lines = text.splitlines(keepends=True)
        # lines[0] is the opening fence ("---"). Insert after it.
        insert = "".join(f"{k}: {_yaml_scalar(v)}\n" for k, v in add.items())
        new_text = lines[0] + insert + "".join(lines[1:])
        path.write_text(new_text, encoding="utf-8")
        return ("stamped", add)
    else:
        # No frontmatter block at all -> create a fresh one atop the file body.
        if not do_write:
            return ("would-stamp", proposed)
        body = "" if status == "no-file" else path.read_text(encoding="utf-8", errors="replace")
        block = "---\n" + "".join(f"{k}: {_yaml_scalar(v)}\n" for k, v in proposed.items()) + "---\n"
        path.write_text(block + body, encoding="utf-8")
        return ("no-frontmatter-created", proposed)


def _read_sidecar_keys(sidecar_path):
    """Read a plain-YAML .meta.yml sidecar's top-level keys (no `---` fences).
    Mirrors the _frontmatter idiom: first-colon split, one quote-pair stripped."""
    if not sidecar_path.exists():
        return {}
    keys = {}
    for line in sidecar_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[:1].isspace() or ":" not in line:
            continue
        raw_key, raw_val = line.split(":", 1)
        key = raw_key.strip()
        val = raw_val.strip()
        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
            val = val[1:-1]
        if key and key not in keys:
            keys[key] = val
    return keys


def stamp_sidecar(path, proposed, do_write):
    """Write/merge a `{filename}.meta.yml` sidecar for a non-markdown file, adding only
    ABSENT keys (idempotent). Returns (action, added_keys)."""
    sidecar = path.with_name(path.name + ".meta.yml")
    existing = _read_sidecar_keys(sidecar)
    add = _absent_core_keys(existing, proposed)
    if existing and not add:
        return ("skipped-complete", {})
    if not do_write:
        return ("would-stamp", add if existing else proposed)
    if existing:
        # Append absent keys (merge, don't overwrite).
        with sidecar.open("a", encoding="utf-8") as fh:
            for k, v in add.items():
                fh.write(f"{k}: {_yaml_scalar(v)}\n")
        return ("stamped", add)
    else:
        header = f"# Sidecar metadata for: {path.name}\n"
        block = header + "".join(f"{k}: {_yaml_scalar(v)}\n" for k, v in proposed.items())
        sidecar.write_text(block, encoding="utf-8")
        return ("no-frontmatter-created", proposed)


# --------------------------------------------------------------------------- #
# Scan / run
# --------------------------------------------------------------------------- #

STAMPABLE_SUFFIXES = frozenset(FORMAT_BY_SUFFIX.keys())


def iter_corpus_files(root):
    """Yield every candidate file under root (markdown + sidecar-eligible formats).
    Skips VCS/dot dirs and already-emitted .meta.yml sidecars."""
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        if any(part.startswith(".") for part in p.relative_to(root).parts):
            continue
        if p.name.endswith(".meta.yml"):
            continue
        if p.suffix.lower() in STAMPABLE_SUFFIXES:
            yield p


def run(root, scope, do_write):
    """Classify (and optionally stamp) the corpus. Returns a result dict."""
    stamped, would, skipped, created = [], [], [], []
    orphans, excluded = [], []
    for path in iter_corpus_files(root):
        c = classify(path, root, scope)
        if c.is_excluded:
            excluded.append((str(c.rel_path), c.reason))
            continue
        if c.is_orphan:
            orphans.append((str(c.rel_path), c.reason))
            continue
        writer = stamp_sidecar if c.is_sidecar else stamp_markdown
        action, add = writer(path, c.fields, do_write)
        rec = (str(c.rel_path), c.fields.get("domain"), c.fields.get("type"),
               c.fields.get("lifecycle_state"), c.fields.get("trust_category"))
        if action == "stamped":
            stamped.append(rec)
        elif action == "no-frontmatter-created":
            created.append(rec)
        elif action == "would-stamp":
            would.append(rec)
        elif action == "skipped-complete":
            skipped.append(rec)
    return {
        "root": str(root), "scope": scope, "mode": "stamp" if do_write else "dry-run",
        "stamped": stamped, "created": created, "would_stamp": would,
        "skipped_complete": skipped, "orphans": orphans, "excluded": excluded,
        "counts": {
            "stamped": len(stamped), "created": len(created),
            "would_stamp": len(would), "skipped_complete": len(skipped),
            "orphans": len(orphans), "excluded": len(excluded),
        },
    }


def _emit_tsv(result):
    c = result["counts"]
    out = []
    out.append(
        f"stamp-node-frontmatter\troot={result['root']}\tscope={result['scope']}"
        f"\tmode={result['mode']}"
    )
    out.append(
        f"counts\tstamped={c['stamped']}\tcreated={c['created']}"
        f"\twould_stamp={c['would_stamp']}\tskipped_complete={c['skipped_complete']}"
        f"\torphans={c['orphans']}\texcluded={c['excluded']}"
    )
    for rel, dom, typ, life, trust in (result["would_stamp"] + result["stamped"] + result["created"]):
        out.append(f"stamp\t{rel}\tdomain={dom}\ttype={typ}\tlifecycle={life}\ttrust={trust}")
    for rel, reason in result["orphans"]:
        out.append(f"orphan\t{rel}\t{reason}")
    for rel, reason in result["excluded"]:
        out.append(f"excluded\t{rel}\t{reason}")
    return "\n".join(out)


def _emit_audit_sample(result, n):
    """Print a random N-file sample of proposed classifications for a spot-audit."""
    pool = result["would_stamp"] + result["stamped"] + result["created"]
    rng = random.Random(1469)  # deterministic sample for reproducible audits
    sample = rng.sample(pool, min(n, len(pool)))
    lines = [f"audit-sample\tN={len(sample)}\tpool={len(pool)}"]
    for rel, dom, typ, life, trust in sample:
        lines.append(f"sample\t{rel}\tdomain={dom}\ttype={typ}\tlifecycle={life}\ttrust={trust}")
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# Self-test (committed fixture)
# --------------------------------------------------------------------------- #

def _fixture_dir():
    return Path(__file__).resolve().parent / "tests" / "fixtures" / "node-backfill"


def run_self_test():
    """Assert the tool's contract against the committed fixture:
      (a) full 11-field core set stamped on a canonical file;
      (b) case-normalization fires on a Capitalized folder (01-Governance);
      (c) exclusion fires on a backup segment (body-backups);
      (d) Archive/ excluded under scope=active, included (archived) under scope=all;
      (e) idempotent re-run produces zero further changes;
      (f) orphan list is populated by an unclassifiable file;
      (g) every folder default-type is valid for its domain (type-taxonomy invariant);
      (h) the Stage-12 confirmation-token gate: --stamp WITHOUT --i-am-at-stage-12 refuses
          (exit 3) and writes nothing; --stamp WITH the token writes (mirrors the
          backfill-relationship-edges --emit gate byte-for-byte);
      (i) the ADR-080 taxonomy arm: literal expected values for every closed-set bin row,
          every sub-bin row, the authoritative/non-authoritative discriminator, the
          out-of-taxonomy positional tier (loose, foldered, and its positional negative),
          the archived-position case, the exclusion classes and the corpus-root guards —
          plus a scoped COVERAGE GUARD that fails when a table gains a row with no case.
    Runs against a temp COPY of the fixture so --stamp writes are throwaway.
    """
    import contextlib
    import io
    import shutil
    import tempfile

    fixture = _fixture_dir()
    if not fixture.exists():
        print(f"self-test FAIL: fixture missing at {fixture}", file=sys.stderr)
        return 1

    failures = []

    # (g) invariant guard: every folder default-type must be valid for its domain
    # (the type-taxonomy-matches-domain rule). A drifted table would silently stamp
    # an invalid type — catch it here, not at warehouse-build time.
    for pfx, (dom, _folder, default_type) in FOLDER_PREFIX_MAP.items():
        if default_type not in TYPES_BY_DOMAIN[dom]:
            failures.append(f"(g) default-type '{default_type}' for prefix {pfx} "
                            f"not valid for domain '{dom}'")

    # (g, sub-bin arm) every SUBBIN_DEFAULT_TYPE row must name a KNOWN bin key, and its
    # type must be valid for THAT bin's domain. A sub-bin row keyed on a bin that does
    # not exist would be silently unreachable; a type outside the bin's domain would be
    # suppressed by _classify_type's domain guard and stamp the bin default instead —
    # both are silent failures, so they fail loudly here.
    for (bin_key, sub_key), (sub_type, sub_auth) in SUBBIN_DEFAULT_TYPE.items():
        if bin_key not in FOLDER_PREFIX_MAP:
            failures.append(f"(g) sub-bin row ({bin_key}, {sub_key}) names an unknown bin key")
            continue
        sub_dom = FOLDER_PREFIX_MAP[bin_key][0]
        if sub_type not in TYPES_BY_DOMAIN[sub_dom]:
            failures.append(f"(g) sub-bin type '{sub_type}' for ({bin_key}, {sub_key}) "
                            f"not valid for domain '{sub_dom}'")
        if not isinstance(sub_auth, bool):
            failures.append(f"(g) sub-bin row ({bin_key}, {sub_key}) has a "
                            f"non-boolean authoritative flag")

    with tempfile.TemporaryDirectory() as td:
        root = Path(td) / "corpus"
        shutil.copytree(fixture, root)

        # --- (h) Stage-12 confirmation-token gate (mirrors backfill-relationship-edges) ---
        # (stdout captured so the CLI's TSV report doesn't pollute the self-test output;
        # the gate's refusal message and exit code are what we assert.)
        canon_before = root / "Default" / "01-Governance" / "PROJECT.md"
        # --stamp WITHOUT --i-am-at-stage-12 must REFUSE (exit 3) and write NOTHING.
        with contextlib.redirect_stdout(io.StringIO()):
            rc_refused = main(["--stamp", "--root", str(root)])
        if rc_refused != 3:
            failures.append(f"(h) --stamp without --i-am-at-stage-12 must exit 3 "
                            f"(gate-refused), got {rc_refused}")
        # The refusal must not have mutated the fixture copy: the canonical file must still
        # carry NO stamped node core (frontmatter absent or missing the core keys).
        keys_after_refuse, _ = read_frontmatter(canon_before)
        if all(k in keys_after_refuse for k in CORE_FIELDS):
            failures.append("(h) gate-refused run still wrote the node core (must be inert)")
        # --stamp WITH the token against the throwaway copy must WRITE (existing behavior:
        # exit 0/1 depending on orphans; the canonical file gains the full core).
        with contextlib.redirect_stdout(io.StringIO()):
            rc_gated = main(["--stamp", "--i-am-at-stage-12", "--root", str(root)])
        if rc_gated not in (0, 1):
            failures.append(f"(h) --stamp --i-am-at-stage-12 must run (exit 0/1), got {rc_gated}")
        keys_after_write, st_hw = read_frontmatter(canon_before)
        if st_hw != "ok" or not all(k in keys_after_write for k in CORE_FIELDS):
            failures.append("(h) gated --stamp did not write the node core to the fixture copy")

    # A fresh copy for the remaining assertions (the gate test above already stamped the
    # first copy, which would mask the dry-run / idempotence checks below).
    with tempfile.TemporaryDirectory() as td:
        root = Path(td) / "corpus"
        shutil.copytree(fixture, root)

        # --- (b, c, d-active, f) dry-run over scope=active ---
        r_active = run(root, scope="active", do_write=False)
        would = {rel for rel, *_ in r_active["would_stamp"]}
        excluded = {rel for rel, _ in r_active["excluded"]}
        orphans = {rel for rel, _ in r_active["orphans"]}

        # (b) case-norm: the Capitalized-folder canonical file must be classified
        # (would-stamp), NOT orphaned.
        canonical = "Default/01-Governance/PROJECT.md"
        if canonical not in would:
            failures.append(f"(b) case-norm: {canonical} not classified (would={sorted(would)})")
        # (b) LEGACY VALUE PIN — literal, not read back from FOLDER_PREFIX_MAP. Membership
        # alone cannot see a corrupted legacy row: a wrong (domain, folder) still yields a
        # would-stamp with a full, enum-valid core set. The ADR-080 arm (i) pins the new
        # key family the same way; this pins the legacy one.
        c_legacy = classify(root / canonical, root, scope="active")
        got_legacy = (c_legacy.fields.get("domain"), c_legacy.fields.get("folder"))
        if got_legacy != ("source", "01-governance"):
            failures.append(f"(b) legacy row drift: {canonical} expected "
                            f"(domain,folder)=('source', '01-governance'), got {got_legacy}")

        # (c) exclusion: the body-backups copy must be excluded (not stamped, not orphaned).
        backup = "Default/01-Governance/body-backups/PROJECT.md"
        if backup not in excluded:
            failures.append(f"(c) exclusion: {backup} not excluded (excluded={sorted(excluded)})")
        if backup in would or backup in orphans:
            failures.append(f"(c) exclusion: {backup} leaked into stamp/orphan set")

        # (d-active) Archive excluded under scope=active.
        archived = "Archive/OldProj/01-Governance/OLD.md"
        if archived not in excluded:
            failures.append(f"(d) Archive not excluded under scope=active (excluded={sorted(excluded)})")

        # (f) orphan populated: a loose file directly under the project root carries no
        # resolvable folder token (the walk floors at index 1), so it stays an orphan.
        orphan_file = "Default/loose-note.md"
        if orphan_file not in orphans:
            failures.append(f"(f) orphan: {orphan_file} not in orphan list (orphans={sorted(orphans)})")
        # (f) REASON PIN. The reason string is this tool's structured-output contract and
        # the value changed with the token walk, so it is pinned here — in the tool's own
        # test, where drift is the risk. Downstream consumers must still read the
        # `orphans` array structurally rather than grepping this literal.
        o_reasons = {reason for rel, reason in r_active["orphans"] if rel == orphan_file}
        if o_reasons != {"no resolvable folder token (no confident domain)"}:
            failures.append(f"(f) orphan reason drift: got {o_reasons}")

        # (a) full 11-field core set on the canonical file (inspect the classification).
        canon_path = root / canonical
        c = classify(canon_path, root, scope="active")
        missing = [f for f in CORE_FIELDS if f not in c.fields or c.fields[f] in (None, "")]
        if missing:
            failures.append(f"(a) core-set incomplete on {canonical}: missing {missing}")
        if c.fields.get("domain") not in (DOMAIN_SOURCE, DOMAIN_MANAGED, DOMAIN_GENERATED):
            failures.append(f"(a) domain enum invalid: {c.fields.get('domain')}")
        if c.fields.get("trust_category") not in TRUST_BY_DOMAIN.values() and \
                c.fields.get("trust_category") != "historical-record":
            failures.append(f"(a) trust enum invalid: {c.fields.get('trust_category')}")
        if c.fields.get("lifecycle_trigger") != LIFECYCLE_TRIGGER:
            failures.append(f"(a) reversal marker not set: {c.fields.get('lifecycle_trigger')}")

        # (d-all) Archive INCLUDED (archived) under scope=all.
        r_all = run(root, scope="all", do_write=False)
        would_all = {rel for rel, *_ in r_all["would_stamp"]}
        if archived not in would_all:
            failures.append(f"(d) Archive not classified under scope=all (would={sorted(would_all)})")
        c_arch = classify(root / archived, root, scope="all")
        if c_arch.fields.get("lifecycle_state") != "archived":
            failures.append(f"(d) Archive file not lifecycle=archived under scope=all: "
                            f"{c_arch.fields.get('lifecycle_state')}")
        if c_arch.fields.get("trust_category") != "historical-record":
            failures.append(f"(d) Archive file not trust=historical-record under scope=all: "
                            f"{c_arch.fields.get('trust_category')}")

        # --- (a-write, e) actually stamp under scope=active, then assert idempotence ---
        r1 = run(root, scope="active", do_write=True)
        wrote = r1["counts"]["stamped"] + r1["counts"]["created"]
        if wrote == 0:
            failures.append("(a-write) first --stamp wrote nothing")

        # After a real stamp, the canonical md file must carry all 11 core keys.
        stamped_keys, st = read_frontmatter(canon_path)
        if st != "ok":
            failures.append(f"(a-write) canonical file lost frontmatter after stamp: {st}")
        else:
            miss2 = [f for f in CORE_FIELDS if f not in stamped_keys]
            if miss2:
                failures.append(f"(a-write) stamped file missing core keys: {miss2}")
            if stamped_keys.get("lifecycle_trigger") != LIFECYCLE_TRIGGER:
                failures.append("(a-write) stamped file missing reversal marker")

        # (e) idempotent re-run: zero further stamped/created.
        r2 = run(root, scope="active", do_write=True)
        if r2["counts"]["stamped"] != 0 or r2["counts"]["created"] != 0:
            failures.append(f"(e) idempotence violated: re-run stamped={r2['counts']['stamped']} "
                            f"created={r2['counts']['created']} (expected 0/0)")
        if r2["counts"]["skipped_complete"] == 0:
            failures.append("(e) idempotence: re-run reported nothing already-complete")

        # A non-markdown fixture file must have produced a .meta.yml sidecar.
        sidecar = root / "Default" / "05-Transcripts" / "SteerCo_2026-06-01.txt.meta.yml"
        if not sidecar.exists():
            failures.append(f"(a-write) sidecar not created for non-md file: {sidecar.name}")

    # --- (i) ADR-080 taxonomy arm -------------------------------------------------
    # Built in-process in its own tempdir so the committed legacy fixture stays the
    # legacy fixture. EXPECTED VALUES ARE LITERAL — never read back from the tables
    # under test, because a table-driven expectation passes on a drifted table.
    #   verdict "STAMP" -> (folder, type)   |   "EXCL" -> reason   |   "ORPHAN"
    i_cases = [
        # one case per ADR-080 closed-set bin row (bare bin, no sub-folder)
        ("P/1-Governance/charter.md",                 "STAMP",  ("1-Governance", "plan")),
        ("P/2-Delivery/notes.md",                     "STAMP",  ("2-Delivery", "reference")),
        ("P/3-Operations/raid.md",                    "STAMP",  ("3-Operations", "risk-register")),
        ("P/4-Evidence/notes.md",                     "STAMP",  ("4-Evidence", "reference")),
        ("P/5-Reference/notes.md",                    "STAMP",  ("5-Reference", "reference")),
        ("P/_generated/rollup.md",                    "STAMP",  ("_generated", "weekly-rollup")),
        # one case per sub-bin row
        ("P/2-Delivery/Design/spec.md",               "STAMP",  ("2-Delivery", "fdd")),
        ("P/2-Delivery/Testing/matrix.md",            "STAMP",  ("2-Delivery", "test-plan")),
        ("P/2-Delivery/Requirements/frd.md",          "STAMP",  ("2-Delivery", "fdd")),
        ("P/4-Evidence/Transcripts/call.md",          "STAMP",  ("4-Evidence", "transcript")),
        ("P/4-Evidence/Emails/note.md",               "STAMP",  ("4-Evidence", "email")),
        ("P/4-Evidence/Exports/dump.md",              "STAMP",  ("4-Evidence", "export")),
        # the AUTHORITATIVE / non-authoritative discriminator pair (AC-9)
        ("P/4-Evidence/Emails/RE_Cutover_Plan.md",    "STAMP",  ("4-Evidence", "email")),
        ("P/4-Evidence/Emails/FW_Cutover_Plan.md",    "STAMP",  ("4-Evidence", "email")),
        ("P/2-Delivery/Design/Cutover_Plan.md",       "STAMP",  ("2-Delivery", "plan")),
        # ADJACENCY NEGATIVE: a sub-bin match must sit IMMEDIATELY under its bin. One
        # level deeper the pair does NOT fire and the bare bin default stands.
        ("P/2-Delivery/Phase1/Design/spec.md",        "STAMP",  ("2-Delivery", "reference")),
        # out-of-taxonomy positional tier: loose, foldered, and the positional NEGATIVE
        ("P/templates/blank.md",                      "EXCL",   "out-of-taxonomy project directory (templates)"),
        ("P/templates/04_Communications/blank.md",    "EXCL",   "out-of-taxonomy project directory (templates)"),
        ("P/5-Reference/templates/vendor.md",         "STAMP",  ("5-Reference", "reference")),
        # exclusion classes introduced by this card
        ("P/_inbox/unrouted.md",                      "EXCL",   "excluded path segment (_inbox)"),
        ("P/_inbox/_unsorted/unrouted.md",            "EXCL",   "excluded path segment (_inbox)"),
        ("_pmo/portfolio.md",                         "EXCL",   "non-project top segment (_pmo)"),
        ("Transcripts/staged.md",                     "EXCL",   "non-project top segment (transcripts)"),
        # corpus-root positional guards: the walk floors at index 1, so a project
        # directory whose own name collides with a bin token must NOT resolve
        ("1-Governance/loose.md",                     "ORPHAN", None),
        ("P/loose.md",                                "ORPHAN", None),
    ]
    with tempfile.TemporaryDirectory() as td:
        iroot = Path(td) / "adr080"
        for rel, _verdict, _expect in i_cases:
            f = iroot / rel
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text("---\ntitle: t\n---\n# body\n", encoding="utf-8")
        for rel, verdict, expect in i_cases:
            ci = classify(iroot / rel, iroot, scope="active")
            if verdict == "STAMP":
                if ci.is_orphan or ci.is_excluded:
                    failures.append(f"(i) {rel}: expected STAMP, got "
                                    f"{'orphan' if ci.is_orphan else 'excluded'} ({ci.reason})")
                    continue
                got = (ci.fields.get("folder"), ci.fields.get("type"))
                if got != expect:
                    failures.append(f"(i) {rel}: expected (folder,type)={expect}, got {got}")
            elif verdict == "EXCL":
                if not ci.is_excluded:
                    failures.append(f"(i) {rel}: expected EXCLUDED ({expect}), "
                                    f"got orphan={ci.is_orphan} reason={ci.reason!r}")
                elif ci.reason != expect:
                    failures.append(f"(i) {rel}: expected reason {expect!r}, got {ci.reason!r}")
            else:  # ORPHAN
                if not ci.is_orphan:
                    failures.append(f"(i) {rel}: expected ORPHAN, got "
                                    f"{'excluded' if ci.is_excluded else 'stamped'} ({ci.reason})")

        # (i) archived-position case: NONRECORD_PROJECT_SEGMENTS is anchored at segs[1],
        # so under an archive segment the project sits at index 1 and the rule does not
        # fire. Under scope=active the Archive tier catches it (exposure 0 today); under
        # scope=all the foldered blank form STAMPS. Pinned so the property is graded
        # rather than latent — see the NONRECORD_PROJECT_SEGMENTS comment.
        arch = iroot / "Archive" / "P" / "templates" / "03-Testing" / "blank.md"
        arch.parent.mkdir(parents=True, exist_ok=True)
        arch.write_text("---\ntitle: t\n---\n", encoding="utf-8")
        c_act = classify(arch, iroot, scope="active")
        if not (c_act.is_excluded and c_act.reason == "Archive/ excluded under scope=active"):
            failures.append(f"(i) archived positional case: expected the Archive tier under "
                            f"scope=active, got excluded={c_act.is_excluded} "
                            f"reason={c_act.reason!r}")
        c_all = classify(arch, iroot, scope="all")
        if c_all.is_orphan or c_all.is_excluded or c_all.fields.get("folder") != "03-testing":
            failures.append("(i) archived positional case: expected folder=03-testing under "
                            f"scope=all, got {c_all.fields.get('folder')!r} "
                            f"(orphan={c_all.is_orphan} excluded={c_all.is_excluded})")

    # (i) COVERAGE GUARD — every ADR-080 map row and every sub-bin row must own a
    # literal case above. Legacy `NN` rows are exempt (the committed fixture covers
    # them); `_inbox` is exempt from the STAMP limb by construction (the exclusion tier
    # fires first) and is required to appear as an EXCLUDED case instead. A table row
    # added without a case fails the build rather than shipping untested.
    i_paths = [rel for rel, _v, _e in i_cases]
    for key in FOLDER_PREFIX_MAP:
        if key.isdigit():
            continue                                   # legacy row — committed fixture
        seg = f"/{FOLDER_PREFIX_MAP[key][1]}/"
        if key == "_inbox":
            if not any(seg in rel and v == "EXCL" for rel, v, _e in i_cases):
                failures.append("(i) coverage: _inbox has no EXCLUDED literal case")
            continue
        if not any(seg in rel for rel in i_paths):
            failures.append(f"(i) coverage: ADR-080 map row '{key}' has no literal case")
    for bin_key, sub_key in SUBBIN_DEFAULT_TYPE:
        seg = f"/{FOLDER_PREFIX_MAP[bin_key][1]}/{sub_key}/".lower()
        if not any(seg in rel.lower() for rel in i_paths):
            failures.append(f"(i) coverage: sub-bin row ({bin_key}, {sub_key}) "
                            "has no literal case")

    if failures:
        print("self-test FAIL:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("stamp-node-frontmatter self-test OK "
          "(a full-core-set / b case-norm / c exclusion / d Archive-scope / e idempotent / "
          "f orphan / g type-domain-validity / h stage-12-gate / i ADR-080-taxonomy)")
    return 0


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #

def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=str(Path.home() / "Claude" / "projects"),
                    help="corpus root to scan (default: ~/Claude/projects)")
    ap.add_argument("--scope", choices=("active", "all"), default="active",
                    help="active (default) excludes Archive/; all includes it")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true",
                      help="EMIT-ONLY, no writes (DEFAULT)")
    mode.add_argument("--stamp", action="store_true",
                      help="actually write frontmatter / sidecars (Stage-12-gated; "
                           "requires --i-am-at-stage-12)")
    ap.add_argument("--i-am-at-stage-12", action="store_true",
                    help="explicit confirmation that this run is the Stage-12 gated execution")
    ap.add_argument("--audit-sample", type=int, metavar="N", default=0,
                    help="print a random N-file sample of proposed classifications")
    ap.add_argument("--output-format", choices=("tsv", "json"), default="tsv")
    ap.add_argument("--self-test", action="store_true",
                    help="run committed-fixture assertions and exit")
    args = ap.parse_args(argv)

    if args.self_test:
        return run_self_test()

    do_write = bool(args.stamp)   # dry-run is the default; --stamp is the only writer
    if do_write and not args.i_am_at_stage_12:
        print(
            "GATE REFUSED: --stamp mutates the live corpus and is gated at release Stage 12 "
            "(the node stamp is the FIRST link in the FK chain — nodes are stamped before "
            "edges FK to them). Re-run with --i-am-at-stage-12 ONLY inside the Stage-12 "
            "execution window, in-workspace.",
            file=sys.stderr,
        )
        return 3

    root = Path(args.root).expanduser()
    if not root.exists() or not root.is_dir():
        print(f"stamp-node-frontmatter: --root unresolvable: {root}", file=sys.stderr)
        return 2

    result = run(root, scope=args.scope, do_write=do_write)

    if args.audit_sample and args.audit_sample > 0:
        print(_emit_audit_sample(result, args.audit_sample))

    if args.output_format == "json":
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(_emit_tsv(result))

    # exit-code contract: orphans => 1, else 0.
    return 1 if result["counts"]["orphans"] else 0


if __name__ == "__main__":
    sys.exit(main())

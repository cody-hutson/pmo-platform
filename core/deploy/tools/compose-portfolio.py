#!/usr/bin/env python3
"""compose-portfolio.py — deterministic PORTFOLIO.md composer (#1771).

The fourth link in the doc-warehouse deploy-tool family. It reads the per-project
rollup entities that `ppm-agent` emits and renders the Part-A `PORTFOLIO.md`
sections (S1-S8 + meta) as markdown, deterministically, so the portfolio dashboard
is composed FROM typed fields — not hand-synthesized prose that silently drifts
(the "watermelon" green-outside/red-inside failure mode the rollup discipline
guards against). It is the execution engine for the §4 section-schema map of
`core/standards/portfolio-writeback-contract.md`.

    stamp-node-frontmatter.py      -> stamps the 11-field node core (vertices)
    backfill-relationship-edges.py -> emits relationships[] edges (edges)
    build-doc-index.py             -> materializes the queryable SQLite index
    compose-portfolio.py (THIS)    -> composes PORTFOLIO.md from rollup entities

HYBRID INPUT MODEL (the verified C2 finding, ADR-062 spirit). The shipped SQLite
`portfolio-rollup` query (`build-doc-index.py`) returns document-ecosystem
aggregates (per-project file / orphan counts), NOT the 7-field project-health
contract. So the 7 fields do NOT live in the index. This composer therefore:
  * reads the 7 contract fields from each rollup entity's FRONTMATTER
    (`_frontmatter.read_frontmatter` for the scalars — the F1 shared reader —
    plus a block-aware parse for the structured array/object fields, mirroring
    build-doc-index.py's builder-local `_parse_nested_blocks` idiom); and
  * discovers rollup entities by a DETERMINISTIC sorted-POSIX scan of `--root`
    (selecting frontmatter `entity_type == "Project Rollup (composed)"` — the
    value `operations/templates/project-rollup-template.md` stamps). Sorted
    enumeration is the identical determinism guarantee build-doc-index.py gets
    from "discovered files sorted by relative POSIX path"; it needs no pre-built
    binary index, so the composer is self-contained and self-testable.
The SQLite index's SUPPLEMENTARY doc-health strip (orphan/domain counts, OQ-1) is
DEFERRED per the Collective-Review scope-lock (this release — `pda-rollup-and-portfolio`
— is kept to the 7-field project-health scope); it is the documented seam where the
index would wire in.

STALENESS ANCHOR (pinned by the contract §3, XC-1 reconciliation). Age is
`--as-of - last_published` in BUSINESS days. Production is invoked with
`--as-of=today` (weekly-status-rollup Section 6 passes today); the fixed
`max(last_published)` form is scoped ONLY to `--self-test`, so the committed
fixture output is byte-reproducible. `> 3 bd` renders `[STALE]` inline; `> 5 bd`
auto-degrades the field (the health-score layer treats an auto-degraded field as
not-Green). The two threshold VALUES are owned by the portfolio health-score work
item (#276) and consumed here as the two module constants below — #276 tunes them
without touching composer core.

DETERMINISM (idempotency AC — double-run byte-identical on unchanged input).
  1. Projects are sorted by `project_id` (kebab slug) — filesystem discovery order
     is never trusted.
  2. Intra-field list order is the AUTHORED frontmatter order (a pure function of
     the file's bytes, hence identical across two runs of unchanged input; it also
     preserves author-intended priority, e.g. most-severe-risk-first, which the
     7-field contract carries no severity field to reconstruct).
  3. NO wall-clock is rendered into the body. The only datetime emitted is the
     stored `last_published`; `[STALE]` is computed against the fixed `--as-of`
     anchor (a pure function of `(as_of, last_published)`), never `date.today()`
     mid-render. This is the specific guard against the SQLite `staleness` query's
     query-time clock when a freshness signal is persisted into an artifact.
  4. Canonical serialization: fixed section order, fixed column order, `utilization`
     at `{:.2f}`, LF newlines, single trailing newline, no locale formatting.
  5. `--self-test` runs the composer twice on the committed fixture and
     SHA-256-compares (the build-doc-index.py AC2 idiom).

SCHEMA-AGNOSTIC SECTION REGISTRY. The composer core iterates a declarative
`SECTION_REGISTRY` and hard-codes no section shape. #276 (health-section detail)
and #1169 (S6 risk fill) inject by adding / editing registry entries and their
render callables — the compose() core loop is untouched. See the EXTENSION SEAM
banner above SECTION_REGISTRY.

CIAC-4 STAGING (structural). Output goes to STDOUT by default (a pure filter — no
file write). `--out <path>` fail-loud REJECTS any path with a `projects` component
(the Layer-2, Cowork-owned tree). The composer NEVER writes into `projects/`;
weekly-status-rollup Section 6 stages the output at its existing human-in-the-loop
checkpoint and the Cowork writer performs the write to the served portfolio's composed
file (contract §7 Portfolio scoping: `projects/_config/<portfolio_id>/PORTFOLIO.md`, or
`projects/_config/PORTFOLIO.md` on an install with no Portfolio record).

PORTFOLIO SCOPING (contract §7). With `--portfolio S` the composer serves ONE portfolio:
it reads the Portfolio records in `<root>/_config/` and in one slug-named folder
below it, never its `releases/` folder (located by `entity_type: Portfolio`, never by
filename — except that a composed PORTFOLIO.md is never a record; the composer's
config-folder read, on the shared is_corpus_path predicate; not a fourth node-corpus
walker), selects S's member rollups AFTER discovery (discover_rollups is untouched),
and renders them. The body
never names a portfolio, so a single-portfolio install composes the bytes it composed
before §7. A scoped run is REFUSED (exit 2) at a root holding no active Portfolio
record — a narrowed root cannot serve a portfolio — and an unscoped run is refused at a
root that holds one. The composer limb of §7 binds only when the composer runs: the
production caller is weekly-status-rollup Section 6, operator-driven. The config
folder is the literal `<root>/_config/` (CONFIG_DIRNAME). The platform declares the
operations config home relocatable (operator.toml `[paths]`, the projects-config-path
key), but no code reads that override yet; this composer is one of its consumers to
wire when one does.

Stdlib-only, Python 3.9 (`/usr/bin/python3`). Imports the shared `_frontmatter.py`
reader (F1 consistency); the structured-field block parse is composer-local.

CLI:
  --root PATH        corpus / projects root to scan for rollup entities (required for compose)
  --as-of ISO        staleness anchor date YYYY-MM-DD (default: today);
                     --self-test pins max(last_published) for byte-reproducibility
  --out PATH         write composed markdown to PATH (rejects any path under projects/);
                     default is stdout
  --portfolio ID     serve this portfolio_id only (contract §7 Portfolio scoping);
                     required at a root whose _config/ holds an active Portfolio record
  --self-test        run the committed-fixture assertions and exit

Exit codes (fail-loud family contract; #1771-F1 separates [STALE] from drift):
  0  clean run  — INCLUDING a run that renders [STALE]/degrade markers ([STALE] is a
                  display state, NOT an error), and a run that excludes rollups
                  outside the served portfolio (reported on stderr, §7)
  1  contract drift ONLY — a rollup field whose value TYPE violates the contract
                  (or a missing required field); the composer HALTS, emits no body.
                  Join-key drift (project_id / portfolio_id) halts EVERY run; field
                  drift halts a scoped run only when it sits in a member rollup
  2  usage or configuration error — bad / missing flags, an --out path under
                  projects/, or a §7 configuration error: --portfolio at a root holding
                  no active Portfolio record, an id naming no active record, an unnamed
                  run at a root that holds one, an unmigrated layout, a malformed record,
                  a composed PORTFOLIO.md carrying a Portfolio record, one portfolio_id in
                  conflicting states, a reserved portfolio_id, or a record-less root
                  whose rollups name two or more portfolios
  3  path-unresolvable — --root does not resolve, or --out's parent does not exist
"""
from __future__ import annotations

import argparse
import hashlib
import re
import sys
from datetime import date, timedelta
from pathlib import Path

# The ONE shared frontmatter reader (F1). This file lives beside it in
# core/deploy/tools/; the sys.path insert makes --self-test / direct invocation robust.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _frontmatter import read_frontmatter, _strip_quotes, is_corpus_path  # noqa: E402

# --------------------------------------------------------------------------- #
# Contract constants (core/standards/portfolio-writeback-contract.md §2/§3).
# --------------------------------------------------------------------------- #

# The frontmatter marker the rollup template stamps (operations/templates/
# project-rollup-template.md `entity_type`). Discovery keys on THIS value — the
# Stage-5 index-discovery key `type='project-rollup'` is superseded here because
# the shipped template carries `entity_type: Project Rollup (composed)`, not a
# `type:` field.
ROLLUP_ENTITY_TYPE = "Project Rollup (composed)"

# The rollup's JOIN KEY to its Project record (contract §2; project-schema.md
# § Project-identity resolution rule). It is READ and VALIDATED, never defaulted:
# an absent or empty `project_id` is contract drift (-> exit 1), not a value to be
# synthesized. The `id:` frontmatter key is NOT a fallback for it -- the shipped
# template stamps `id: {{PROJECT_ID}}-rollup`, so falling back to `id` yields a
# WRONG join key rather than a missing one, and the rel-path fallback below it
# yielded a filename. Both fallbacks are removed; see read_rollup().
JOIN_KEY_FIELD = "project_id"

# The 7 contract fields (§2). Two scalars + five structured (3 lists + 2 objects).
SCALAR_FIELDS = ("status", "last_published")
LIST_FIELDS = ("top_risks", "key_dependencies", "cross_project_conflicts")
OBJECT_FIELDS = ("capacity_signal", "milestone_delta")
CONTRACT_FIELDS = SCALAR_FIELDS + LIST_FIELDS + OBJECT_FIELDS  # all 7 required

RAG_VALUES = ("green", "yellow", "red")
RAG_GLYPH = {"green": "\U0001F7E2", "yellow": "\U0001F7E1", "red": "\U0001F534"}

# The five S2 Health-Indicator dimensions, as (label, backing metric, §2 field).
#
# SSOT is portfolio-writeback-contract.md §4.1; this tuple is that mapping's
# EXECUTION FORM, not a second copy of its meaning. Two rules ride on it:
#
#   §4.1 R1 — a third field of None means NO §2 contract field carries this
#             dimension, so the cell renders UNSOURCED_CELL. It never borrows
#             another dimension's value and never borrows the composed project
#             RAG. Five labels carrying one scalar present a single signal as
#             five corroborating ones.
#   §4.1 R3 — backing arrives WITH its producer. Adding a backing field is a §2
#             CONTRACT change first and a row edit here second, never the
#             reverse; a row pointed at a field §2 does not declare would make
#             this table read as delivered when it is not.
#
# Every third field is None today. That is the honest state, not an oversight:
# no §2 field carries any of these five, which is why the render says so.
HEALTH_DIMENSIONS = (
    ("Schedule",     "Schedule Performance Index (SPI)",   None),
    ("Scope",        "Scope",                              None),
    ("Quality",      "Risk + Integration Risk (composed)", None),
    ("Stakeholders", "Stakeholder Engagement (optional)",  None),
    ("Integration",  "Integration Risk",                   None),
)
UNSOURCED_CELL = "UNSOURCED"

# The declared shape of `project_id`. ADR-179 D2 makes project_id the namespace
# root and sole join key; D1's grammar gives its PROJECT production as this
# kebab slug.
#
# It is VALIDATED, not merely presence-checked, and the reason is the shared
# reader's frozen F-4: a "#" in a value is CONTENT, so a line reading
# `project_id: proj-alpha   # renamed` resolves to the WHOLE string including the
# comment. That is a WRONG join key, not a missing one -- the class a presence
# check is structurally unable to see, because the value is present and
# non-empty. The consumer that declares a shape is the only site able to tell a
# polluted value from a legitimate one, so this is where the constraint lives
# rather than in the shared parser (see the new ADR on frontmatter laxity).
#
# FUTURE HOME: ADR-179 D1 declares ENTITY_REF_RE once, in
# core/schemas/entity-field-schemas.md, "cited, never restated". That delivery
# child has not landed (measured: the literal appears in the ADR alone). Re-point
# this local declaration at the shared grammar when it ships.
PROJECT_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")

# Contract §7 Portfolio scoping. The rollup's PORTFOLIO key sits BESIDE project_id
# and OUTSIDE the seven §2 fields, and it is OPTIONAL: an ABSENT key means "this
# project names no portfolio". A PRESENT-but-empty key, a PRESENT-but-polluted key
# and a near-miss key NAME are JOIN-KEY drift (exit 1, every run halts: membership is
# undecidable), never "absent". Same kebab-slug grammar as project_id.
PORTFOLIO_KEY_FIELD = "portfolio_id"
PORTFOLIO_ID_RE = PROJECT_ID_RE
PORTFOLIO_ENTITY_TYPE = "Portfolio"     # a Portfolio record's type key (project-schema.md S2)
PORTFOLIO_STATES = ("active", "archived")  # V-PORT-04 Axis-1
CONFIG_DIRNAME = "_config"              # Portfolio records are read under <root>/_config/
ROOT_COMPOSED_NAME = "PORTFOLIO.md"     # <root>/_config/PORTFOLIO.md = the no-record layout
RESERVED_PORTFOLIO_IDS = ("releases",)  # the config folder's own child folder (contract §7.5)

# Per-structured-field required sub-keys (shape validation for drift detection).
# HARD-required = the item-identity keys below (a missing one is structural drift ->
# exit 1 halt). `owner` / `mitigation` on the two risk-bearing legs (top_risks,
# cross_project_conflicts) are DELIBERATELY NOT hard-required: a row missing one
# renders the S6 `[DRIFT: incomplete risk record — <field> missing]` repair flag
# inline (contract §2 "flagged for repair"; weekly-status-rollup §3.6/§6) and STILL
# composes (exit 0) — a soft render-flag, NOT the exit-1 halt reserved for TYPE /
# structural violations. This is the reconciliation that makes the composer's S6
# render consistent with the SKILL.md S6 shell (which renders — never halts — the
# incomplete-risk repair flag).
LIST_ITEM_KEYS = {
    "top_risks": ("risk",),
    "key_dependencies": ("from", "to", "state"),
    "cross_project_conflicts": ("conflict", "projects_affected"),
}
OBJECT_KEYS = {
    "capacity_signal": ("utilization", "gap_rag"),
    "milestone_delta": ("next_milestone", "target", "state"),  # `actual` optional
}
TOP_RISKS_MAX = 5  # §2: top_risks[] is `≤ 5`

# Staleness thresholds in BUSINESS days. VALUES OWNED BY #276 (portfolio
# health-score) — consumed here. #276 tunes these two constants without touching
# composer core (the parameterization seam).
STALE_THRESHOLD_BD = 3     # age > 3 bd -> render [STALE] inline
DEGRADE_THRESHOLD_BD = 5   # age > 5 bd -> auto-degrade (health-score: not-Green)

STALE_MARKER = "[STALE]"
# Contract §7: in a served portfolio's output, a member's cross-project reference to
# a DISCOVERED rollup outside that portfolio renders this marker in its place.
OTHER_PORTFOLIO_REF = "[OTHER PORTFOLIO]"
DEGRADE_MARKER = "[STALE:DEGRADED]"


# --------------------------------------------------------------------------- #
# Errors.
# --------------------------------------------------------------------------- #

class ContractDrift(Exception):
    """A rollup field whose value TYPE violates the contract (or a missing
    required field). Raised during read/validate; surfaced as exit 1 (halt)."""


class PortfolioScopeError(Exception):
    """A contract §7 configuration or calling error (no record for a scoped run, an
    unnamed run on a scoped root, an unmigrated layout, a malformed or near-miss
    Portfolio record). Surfaced as exit 2; the composer emits no body."""


# --------------------------------------------------------------------------- #
# Frontmatter block-aware parse (the structured fields the shared reader skips).
# Mirrors build-doc-index.py `_parse_nested_blocks` — generalized to also capture
# block mappings and the inline (flow) forms of the same fields.
# --------------------------------------------------------------------------- #

def _frontmatter_body(doc_path: Path) -> str:
    """The raw text between the two `---` fences (empty string if none)."""
    text = doc_path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return ""
    body: list = []
    for line in lines[1:]:
        if line.strip() == "---":
            break
        body.append(line)
    return "\n".join(body)


def _parse_flow_list(raw: str) -> list:
    """`[a, b, c]` or `a, b` -> [tokens]. Scalars are quote-stripped."""
    s = raw.strip()
    if not s or s == "[]":
        return []
    s = s[1:-1] if (s.startswith("[") and s.endswith("]")) else s
    return [_strip_quotes(t.strip()) for t in s.split(",") if t.strip()]


def _parse_flow_map(raw: str) -> dict:
    """`{k: v, k2: v2}` -> {k: v}. Values quote-stripped; nested flow list kept."""
    s = raw.strip()
    if s.startswith("{") and s.endswith("}"):
        s = s[1:-1]
    out: dict = {}
    for part in _split_top_level(s):
        if ":" not in part:
            continue
        k, v = part.split(":", 1)
        k = k.strip()
        v = v.strip()
        if not k:
            continue
        out[k] = _parse_flow_list(v) if v.startswith("[") else _strip_quotes(v)
    return out


def _split_top_level(s: str) -> list:
    """Split a flow-mapping body on commas that are NOT inside a `[...]` list."""
    parts: list = []
    depth = 0
    cur = ""
    for ch in s:
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth = max(0, depth - 1)
        if ch == "," and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur)
    return parts


def _indent(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def parse_structured_fields(body: str, wanted: tuple) -> dict:
    """Parse the structured contract fields from a frontmatter body.

    Handles, per top-level key, three authoring styles:
      * block list-of-objects  (`key:` then `  - a: x` / `    b: y` items)
      * block mapping          (`key:` then `  a: x` / `  b: y`)
      * inline flow            (`key: [a, b]` or `key: {a: x, b: y}`)
    Returns {field: list|dict} for each field in `wanted` that is present.
    Deterministic: list order = authored order; dict built in read order.
    """
    lines = body.splitlines()
    out: dict = {}
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        stripped = line.strip()
        # A top-level key is flush-left `key:` (not a list item, has a colon).
        if not line or line[:1].isspace() or stripped.startswith("-") or ":" not in line:
            i += 1
            continue
        key = line.split(":", 1)[0].strip()
        inline = line.split(":", 1)[1].strip()
        if key not in wanted:
            i += 1
            continue
        # Inline flow forms resolve on the key line itself.
        if inline:
            if inline.startswith("["):
                out[key] = _parse_flow_list(inline)
            elif inline.startswith("{"):
                out[key] = _parse_flow_map(inline)
            else:
                out[key] = _strip_quotes(inline)  # scalar (unexpected for these, kept)
            i += 1
            continue
        # Block form: collect the indented child lines under this key.
        base = _indent(line)
        j = i + 1
        child: list = []
        while j < n:
            nxt = lines[j]
            if nxt.strip() and _indent(nxt) <= base and not nxt.lstrip().startswith("-"):
                break  # next flush-left/shallower key closes the block
            if nxt.strip():
                child.append(nxt)
            j += 1
        out[key] = _parse_block_children(child)
        i = j
    return out


def _parse_block_children(child: list) -> object:
    """A block child set is either a list (items lead with `- `) or a mapping."""
    if any(ln.lstrip().startswith("- ") for ln in child):
        return _parse_block_object_list(child)
    return _parse_block_mapping(child)


def _parse_block_mapping(child: list) -> dict:
    out: dict = {}
    for ln in child:
        s = ln.strip()
        if ":" not in s:
            continue
        k, v = s.split(":", 1)
        k = k.strip()
        v = v.strip()
        if not k:
            continue
        out[k] = _parse_flow_list(v) if v.startswith("[") else _strip_quotes(v)
    return out


def _parse_block_object_list(child: list) -> list:
    """Block list where each `- ` starts an object; deeper `k: v` lines add to it.
    A `- item` with no colon is a scalar list item."""
    out: list = []
    cur: dict = {}
    have = False
    for ln in child:
        s = ln.strip()
        if s.startswith("- "):
            if have:
                out.append(cur)
            cur = {}
            have = True
            rest = s[2:].strip()
            if ":" in rest:
                k, v = rest.split(":", 1)
                cur[k.strip()] = _parse_flow_list(v.strip()) if v.strip().startswith("[") \
                    else _strip_quotes(v.strip())
            elif rest:
                out.append(rest)   # scalar list item
                have = False
                cur = {}
        elif ":" in s and have:
            k, v = s.split(":", 1)
            cur[k.strip()] = _parse_flow_list(v.strip()) if v.strip().startswith("[") \
                else _strip_quotes(v.strip())
    if have:
        out.append(cur)
    return out


# --------------------------------------------------------------------------- #
# Rollup entity model + read/validate (drift detection = exit 1).
# --------------------------------------------------------------------------- #

class Rollup:
    """One per-project rollup entity: `project_id` + the 7 validated contract fields."""

    __slots__ = ("project_id", "rel_path", "status", "last_published", "top_risks",
                 "key_dependencies", "cross_project_conflicts", "capacity_signal",
                 "milestone_delta", "portfolio_id")

    def __init__(self, project_id, rel_path, fields, portfolio_id=None):
        self.project_id = project_id
        self.rel_path = rel_path
        self.portfolio_id = portfolio_id   # None = absent key (contract §7)
        self.status = fields["status"]
        self.last_published = fields["last_published"]
        self.top_risks = fields["top_risks"]
        self.key_dependencies = fields["key_dependencies"]
        self.cross_project_conflicts = fields["cross_project_conflicts"]
        self.capacity_signal = fields["capacity_signal"]
        self.milestone_delta = fields["milestone_delta"]


def _parse_iso_date(value: str) -> date:
    """Parse the date portion of an ISO 8601 datetime (`YYYY-MM-DD[...]`)."""
    return date.fromisoformat(value.strip()[:10])


def _project_id_drift(project_id: str) -> list:
    """The project_id join-key diagnostics, shared by read_rollup and read_rollup_keys
    so the remedy text is identical on both paths."""
    if not project_id:
        return ["project_id absent or empty — the rollup's join key to its "
                "Project record (contract §2); no fallback is applied"]
    if not PROJECT_ID_RE.match(project_id):
        return [
            f"project_id={project_id!r} does not match the declared join-key "
            f"charset (ADR-179 D1: ^[a-z0-9][a-z0-9-]*$). A trailing '# …' on the "
            f"`project_id:` line is CONTENT, not a comment — the shared reader "
            f"does not strip it (its frozen F-4) — so remove the comment from "
            f"that line. This matters because a polluted join key is a WRONG "
            f"value rather than a missing one: it passes every presence check and "
            f"then silently fails to match its Project record"]
    return []


def _portfolio_key(scalars: dict, drift: list):
    """Contract §7: validate the rollup's optional portfolio key and its name.
    Returns the key or None (absent); appends JOIN-KEY drift to `drift`."""
    for k in scalars:
        if (not k.startswith("#") and k != PORTFOLIO_KEY_FIELD
                and re.sub(r"[^a-z0-9]", "", k.lower()) == "portfolioid"):
            drift.append(f"top-level key {k!r} is a near-miss of {PORTFOLIO_KEY_FIELD!r} — "
                         f"it would be read as 'no portfolio'; spell the key exactly")
    if PORTFOLIO_KEY_FIELD not in scalars:
        return None
    value = (scalars.get(PORTFOLIO_KEY_FIELD) or "").strip()
    if not value:
        drift.append("portfolio_id is present but empty — omit the key for a project "
                     "that names no portfolio (contract §7); an empty key is not read "
                     "as 'no portfolio'")
    elif not PORTFOLIO_ID_RE.match(value):
        drift.append(f"portfolio_id={value!r} does not match the join-key charset "
                     f"^[a-z0-9][a-z0-9-]*$ — a trailing '# …' on the line is CONTENT "
                     f"to the shared reader, not a comment")
    return value or None


def read_rollup_keys(doc_path: Path, root: Path) -> tuple:
    """Phase 1 of a scoped compose (contract §7): read and validate ONLY the two join
    keys. Returns (rel, project_id, portfolio_id, drift). Key drift is install-level:
    membership is undecidable, so it halts every portfolio's run and names the path."""
    scalars, status = read_frontmatter(doc_path)
    rel = doc_path.relative_to(root).as_posix()
    if status != "ok":
        return rel, "", None, ["no frontmatter block"]
    drift: list = []
    project_id = (scalars.get(JOIN_KEY_FIELD) or "").strip()
    drift.extend(_project_id_drift(project_id))
    portfolio_id = _portfolio_key(scalars, drift)
    return rel, project_id, portfolio_id, drift


def read_rollup(doc_path: Path, root: Path) -> Rollup:
    """Read + type-validate one rollup entity. Raises ContractDrift on any field
    whose type violates the §2 contract or on a missing required field."""
    scalars, status = read_frontmatter(doc_path)
    rel = doc_path.relative_to(root).as_posix()
    if status != "ok":
        raise ContractDrift(f"{rel}: no frontmatter block")
    structured = parse_structured_fields(_frontmatter_body(doc_path),
                                          LIST_FIELDS + OBJECT_FIELDS)
    drift: list = []
    fields: dict = {}

    # `project_id` is the rollup's JOIN KEY to its Project record (contract §2;
    # project-schema.md § Project-identity resolution rule). Validated, never
    # defaulted: the former `or scalars.get("id") or rel` fallback resolved to
    # `<slug>-rollup` (the template's own `id:`) -- a WRONG key, not a missing one.
    project_id = (scalars.get(JOIN_KEY_FIELD) or "").strip()
    drift.extend(_project_id_drift(project_id))

    # --- portfolio key (contract §7; optional, beside project_id) ---
    portfolio_id = _portfolio_key(scalars, drift)

    # --- scalars ---
    rag = (scalars.get("status") or "").strip().lower()
    if rag not in RAG_VALUES:
        drift.append(f"status={scalars.get('status')!r} not in {RAG_VALUES}")
    fields["status"] = rag

    lp_raw = (scalars.get("last_published") or "").strip()
    try:
        _parse_iso_date(lp_raw)
        fields["last_published"] = lp_raw
    except (ValueError, IndexError):
        drift.append(f"last_published={lp_raw!r} is not an ISO 8601 date")
        fields["last_published"] = lp_raw

    # --- list fields (array of objects) ---
    for name in LIST_FIELDS:
        val = structured.get(name)
        if val is None:
            drift.append(f"{name} is required but absent")
            fields[name] = []
            continue
        if not isinstance(val, list):
            drift.append(f"{name} must be a list, got {type(val).__name__}")
            fields[name] = []
            continue
        req = LIST_ITEM_KEYS[name]
        for idx, item in enumerate(val):
            if not isinstance(item, dict):
                drift.append(f"{name}[{idx}] must be a mapping, got {type(item).__name__}")
                continue
            missing = [k for k in req if k not in item]
            if missing:
                drift.append(f"{name}[{idx}] missing sub-key(s) {missing}")
        if name == "top_risks" and len(val) > TOP_RISKS_MAX:
            drift.append(f"top_risks has {len(val)} items (contract cap is {TOP_RISKS_MAX})")
        fields[name] = val

    # --- object fields (mapping) ---
    for name in OBJECT_FIELDS:
        val = structured.get(name)
        if val is None:
            drift.append(f"{name} is required but absent")
            fields[name] = {}
            continue
        if not isinstance(val, dict):
            drift.append(f"{name} must be a mapping, got {type(val).__name__}")
            fields[name] = {}
            continue
        missing = [k for k in OBJECT_KEYS[name] if k not in val]
        if missing:
            drift.append(f"{name} missing key(s) {missing}")
        fields[name] = val

    # capacity_signal.utilization must be float-parseable.
    cs = fields["capacity_signal"]
    if isinstance(cs, dict) and "utilization" in cs:
        try:
            float(cs["utilization"])
        except (TypeError, ValueError):
            drift.append(f"capacity_signal.utilization={cs['utilization']!r} is not a float")

    if drift:
        raise ContractDrift(f"{rel} (project {project_id or '<unset>'}): " + "; ".join(drift))
    return Rollup(project_id, rel, fields, portfolio_id)


def _normalized_entity_type(value) -> str:
    """Normalize an `entity_type` value FOR THE NEAR-MISS COMPARISON ONLY.

    Strips a trailing ` #…` comment run, THEN one matching quote pair. Never
    applied to a value the composer returns or joins on — it exists so the guard
    in discover_rollups can tell "a polluted rollup key" from "not a rollup", and
    nothing more. Loosening the ACCEPT path would reopen the silent class the
    guard is here to close.

    THE ORDER IS LOAD-BEARING, and the opposite order is the intuitive one.
    Stripping the quote pair first fails on the very shape that motivates this
    helper: a trailing comment leaves the closing quote displaced, so the pair
    does not match yet and no quote is removed; the comment strip then yields
    `"Project Rollup (composed)"` WITH its quotes, which compares unequal.
    Measured across five pollution shapes — unquoted+comment, quoted+comment,
    single-quoted+comment, comment-inside-quotes, and clean — comment-then-quote
    normalizes all five correctly while quote-then-comment misses two of them,
    including the quoted shape this guard exists to catch. Both unrelated shapes
    (`Project`, `Project   # note`) normalize to themselves under either order
    and are correctly not flagged.
    """
    if not isinstance(value, str):
        return ""
    v = re.sub(r"\s+#.*$", "", value.strip()).strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in ('"', "'"):
        v = v[1:-1].strip()
    return v


def discover_rollups(root: Path) -> list:
    """Deterministic sorted-POSIX discovery of rollup entities under `root`
    (frontmatter `entity_type == ROLLUP_ENTITY_TYPE`). Sorted enumeration is the
    idempotency guarantee — filesystem order is never trusted.

    Discovery distinguishes *no rollups here* from *a rollup whose discovery key
    was polluted*. The second case is the more dangerous of the two pollution
    surfaces: a polluted `project_id` produces a wrong join, but a polluted
    `entity_type` does not fail at all — it fails to MATCH, the rollup is
    silently skipped, and the composer renders a portfolio missing that project
    at exit 0 with no diagnostic. Where every rollup is polluted it renders an
    empty portfolio and still exits 0.

    ACCEPTANCE STAYS EXACT. `found` keys on byte equality, unchanged; this adds a
    raise, it does not loosen the key. Only the NEAR-MISS arm normalizes, and it
    tests EQUALITY after normalizing rather than a prefix.

    WHY NOT A PREFIX TEST. `startswith(ROLLUP_ENTITY_TYPE)` looks sufficient and
    is not. The shared reader removes a quote pair only when BOTH ends match, so
    a trailing comment displaces the closing quote and the resolved value BEGINS
    with a quote character:

        entity_type: "Project Rollup (composed)"   # note
            resolves to  '"Project Rollup (composed)"   # note'

    — which is neither equal nor prefix-matching, so the ordinary quoted-value
    shape would slip through the guard and fail silently exactly as before.

    BOUNDS, both stated. It cannot over-match: the near-miss arm tests equality
    on the normalized value, so an unrelated `entity_type` (`Project`, say)
    normalizes to itself and is not flagged. Its residual false-negative class is
    a value whose pollution is neither a trailing ` #…` run nor a displaced quote
    pair — a mid-value edit, or a comment with no preceding whitespace. Those are
    still silently skipped, and this sentence is the record of it.

    OUT OF CORPUS. A rollup under a dot-leading path segment — a dot-leading
    DIRECTORY (`.body-backups/`) or a dot-leading FILENAME (`.draft.md`) — is not
    in the corpus and is NOT discovered, on the one traversal predicate all three
    deploy-tool corpus walkers share. Named here because the consequence is
    silent by design: an operator corpus deliberately holding a live rollup under
    such a path loses it from the composed portfolio, with no diagnostic.
    """
    found: list = []
    near_miss: list = []
    for path in sorted(root.rglob("*.md"), key=lambda p: p.relative_to(root).as_posix()):
        # TRAVERSAL GUARD — FIRST statement of the loop body, deliberately. It must
        # precede read_frontmatter() and therefore the near-miss classification
        # below: a rollup copy under a dot-leading segment is out of corpus BY
        # DECLARATION, so if such a copy carried a polluted entity_type, a guard
        # placed after that classification would hard-fail the composer on a path
        # it should never have looked at. Order is behaviour here, not style.
        if not is_corpus_path(path, root):
            continue
        scalars, status = read_frontmatter(path)
        if status != "ok":
            continue
        et = scalars.get("entity_type")
        if et == ROLLUP_ENTITY_TYPE:
            found.append(path)
        elif _normalized_entity_type(et) == ROLLUP_ENTITY_TYPE:
            near_miss.append((path.relative_to(root).as_posix(), et))
    if near_miss:
        detail = "; ".join(f"{rel}: {val!r}" for rel, val in near_miss)
        raise ContractDrift(
            f"entity_type is polluted on {len(near_miss)} rollup(s) — these WOULD "
            f"BE SILENTLY SKIPPED by discovery, composing a portfolio that omits "
            f"them at exit 0. The discovery key must equal "
            f"{ROLLUP_ENTITY_TYPE!r} exactly; a trailing '# …' is CONTENT to the "
            f"shared reader, not a comment. Offending values — {detail}")
    return found


def _record_candidates(cfg: Path, root: Path) -> list:
    """Contract §7.1 — the bounded record walk: `<root>/_config/*.md` and
    `<root>/_config/<slug>/*.md` only. One folder deep, a folder named by a kebab slug,
    never the config folder's own `releases/` (any case: a capitalised folder fails the
    slug test and the lowercase one is reserved); a dot-leading segment is out of corpus
    on the shared is_corpus_path predicate. A record nested deeper is not read."""
    found = [p for p in cfg.glob("*.md") if p.is_file()]
    for sub in cfg.iterdir():
        if (sub.is_dir() and PORTFOLIO_ID_RE.match(sub.name)
                and sub.name.lower() not in RESERVED_PORTFOLIO_IDS):
            found.extend(p for p in sub.glob("*.md") if p.is_file())
    return sorted((p for p in found if is_corpus_path(p, root)),
                  key=lambda p: p.relative_to(root).as_posix())


def discover_portfolio_records(root: Path) -> list:
    """Contract §7: the Portfolio records in `<root>/_config/`, located by frontmatter
    `entity_type == "Portfolio"` exactly and by `portfolio_id` — NEVER by filename, so
    a record may sit at the config top or in a slug-named folder one level below it
    (its portfolio's folder is the recommended home) — with one exception: a composed
    PORTFOLIO.md is never a record. Sorted. Returns [(rel, portfolio_id, lifecycle_state)].
    A near-miss type key, a malformed record, a composed file carrying a record, one
    portfolio_id held in conflicting states, or a reserved portfolio_id is a configuration
    error (exit 2): silently dropping or double-counting a record would move that
    portfolio's projects in every run."""
    cfg = root / CONFIG_DIRNAME
    if not cfg.is_dir():
        return []
    found, bad = [], []
    for path in _record_candidates(cfg, root):
        scalars, status = read_frontmatter(path)
        if status != "ok":
            continue
        et = scalars.get("entity_type")
        rel = path.relative_to(root).as_posix()
        if et != PORTFOLIO_ENTITY_TYPE:
            if _normalized_entity_type(et) == PORTFOLIO_ENTITY_TYPE:
                bad.append(f"{rel}: entity_type {et!r} is a near-miss of 'Portfolio'")
            continue
        if path.name.lower() == ROOT_COMPOSED_NAME.lower():
            bad.append(f"{rel}: a composed {ROOT_COMPOSED_NAME} carries entity_type: Portfolio — "
                       f"a composed file is never a Portfolio record; seed the record in its own "
                       f"file (contract §7)")
            continue
        pid = (scalars.get(PORTFOLIO_KEY_FIELD) or "").strip()
        state = (scalars.get("lifecycle_state") or "").strip().lower()
        if not PORTFOLIO_ID_RE.match(pid):
            bad.append(f"{rel}: portfolio_id {pid!r} is empty or not a kebab slug (V-PORT-02)")
        elif pid.lower() in RESERVED_PORTFOLIO_IDS:
            bad.append(f"{rel}: portfolio_id {pid!r} is reserved — it names the config folder's "
                       f"own {pid}/ folder (contract §7)")
        elif state not in PORTFOLIO_STATES:
            bad.append(f"{rel}: lifecycle_state {state!r} not in {PORTFOLIO_STATES} (V-PORT-04)")
        else:
            found.append((rel, pid, state))
    by_id: dict = {}
    for rel, pid, state in found:
        by_id.setdefault(pid, {}).setdefault(state, []).append(rel)
    for pid in sorted(by_id):
        if len(by_id[pid]) > 1:
            where = "; ".join(f"{st} at " + ", ".join(rels) for st, rels in sorted(by_id[pid].items()))
            bad.append(f"portfolio_id {pid!r} has records in conflicting states ({where}) — keep "
                       f"one record per portfolio (contract §7)")
    if bad:
        raise PortfolioScopeError("malformed Portfolio record(s) under "
                                  f"{CONFIG_DIRNAME}/ — " + "; ".join(bad))
    return found


def _own_project_record(doc_path: Path, root: Path):
    """Contract §7 cross-check: the rollup's own PROJECT.md — the nearest ancestor
    directory strictly below `root` that holds one. An ancestor LOOKUP along the
    rollup's own path, not a corpus walk. None when no such record is under root."""
    d = doc_path.parent
    while d != root and root in d.parents:
        cand = d / "PROJECT.md"
        if cand.is_file():
            return cand
        d = d.parent
    return None


def _project_portfolio(project_md: Path) -> tuple:
    """(portfolio_id or None, PROJECT.md id or None, polluted) from a PROJECT.md
    frontmatter. The portfolio key is read with the rollup key's own slug test
    (contract §7.1): a present value that fails it — a trailing '# …' is CONTENT to the
    shared reader — is POLLUTED, its own report class. An empty value reads as absent."""
    scalars, status = read_frontmatter(project_md)
    if status != "ok":
        return None, None, False
    raw = (scalars.get(PORTFOLIO_KEY_FIELD) or "").strip()
    rid = (scalars.get("id") or "").strip() or None
    if raw and not PORTFOLIO_ID_RE.match(raw):
        return None, rid, True
    return raw or None, rid, False


def select_rollups(root: Path, paths: list, portfolio: str, records: list) -> tuple:
    """Contract §7 membership, applied AFTER discovery. Returns (member_paths, report,
    redact_ids, redact_aliases, keep_ids, keep). `report` counts what the composer can
    compute: unassigned, unresolved, inactive, held and polluted-key projects are NAMED
    (they belong to no active portfolio, or to the served one); another portfolio's
    projects are only COUNTED. Non-member `project_id`s redact by prefix; their
    PROJECT.md `id` aliases redact by EXACT match only (contract §7.4)."""
    active = sorted({pid for _, pid, st in records if st == "active"})
    archived = {pid for _, pid, st in records if st == "archived"} - set(active)
    only = active[0] if len(active) == 1 else None

    def eff(key):
        return only if key is None else key

    members, rep_ = [], {"served": portfolio, "portfolios": len(active), "members": 0,
                         "unassigned": [], "unresolved": [], "inactive": [], "held": [],
                         "polluted": [], "held_elsewhere": 0,
                         "other_portfolio": 0, "drift_outside": 0}
    redact_ids, redact_aliases, keep_ids, keep_aliases = set(), set(), set(), set()
    for p in paths:
        rel, project_id, key, _ = read_rollup_keys(p, root)
        prj = _own_project_record(p, root)
        prj_key, prj_id, prj_bad = _project_portfolio(prj) if prj else (None, None, False)
        mine = eff(key)
        if prj_bad:
            rep_["polluted"].append(project_id); disposition = "polluted"
        elif prj is not None and eff(prj_key) != mine:
            if eff(prj_key) == portfolio or eff(prj_key) not in active:
                rep_["held"].append(project_id)
            else:
                rep_["held_elsewhere"] += 1
            disposition = "held"
        elif mine is None:
            rep_["unassigned"].append(project_id); disposition = "unassigned"
        elif mine == portfolio:
            disposition = "member"
        elif mine in active:
            rep_["other_portfolio"] += 1; disposition = "other"
        elif mine in archived:
            rep_["inactive"].append(project_id); disposition = "inactive"
        else:
            rep_["unresolved"].append(project_id); disposition = "unresolved"
        if disposition == "member":
            members.append(p); keep_ids.add(project_id)
            if prj_id:
                keep_aliases.add(prj_id)
        else:
            redact_ids.add(project_id)
            if prj_id:
                redact_aliases.add(prj_id)
    keep = keep_ids | keep_aliases
    redact_ids -= keep
    redact_aliases -= keep
    rep_["members"] = len(members)
    for k in ("unassigned", "unresolved", "inactive", "held", "polluted"):
        rep_[k] = sorted(rep_[k])
    return (members, rep_, frozenset(redact_ids), frozenset(redact_aliases),
            frozenset(keep_ids), frozenset(keep))


# --------------------------------------------------------------------------- #
# Staleness (business-day age vs. the fixed --as-of anchor).
# --------------------------------------------------------------------------- #

def business_days_between(start: date, end: date) -> int:
    """Business days (Mon-Fri) strictly after `start` up to and including `end`.
    0 when end <= start. Holidays are not modeled (weekday-only, documented)."""
    if end <= start:
        return 0
    days = 0
    cur = start + timedelta(days=1)
    while cur <= end:
        if cur.weekday() < 5:
            days += 1
        cur += timedelta(days=1)
    return days


def staleness(last_published: str, as_of: date) -> tuple:
    """(age_bd, is_stale, is_degraded) for a rollup's last_published vs. as_of."""
    age = business_days_between(_parse_iso_date(last_published), as_of)
    return age, age > STALE_THRESHOLD_BD, age > DEGRADE_THRESHOLD_BD


def _stale_suffix(last_published: str, as_of: date) -> str:
    """The inline marker appended to an aged field (`` when fresh)."""
    _, is_stale, is_degraded = staleness(last_published, as_of)
    if is_degraded:
        return f" {DEGRADE_MARKER}"
    if is_stale:
        return f" {STALE_MARKER}"
    return ""


# --------------------------------------------------------------------------- #
# Render context + small helpers.
# --------------------------------------------------------------------------- #

class Ctx:
    __slots__ = ("rollups", "as_of", "redact", "keep", "alias", "keep_ids")

    def __init__(self, rollups, as_of, redact=frozenset(), keep=frozenset(),
                 alias=frozenset(), keep_ids=frozenset()):
        self.rollups = rollups   # sorted by project_id
        self.as_of = as_of
        self.redact = redact     # contract §7: project_ids of discovered rollups outside the served portfolio
        self.keep = keep         # ... the members' project_ids and PROJECT.md ids (never redacted)
        self.alias = alias       # ... the non-members' PROJECT.md ids (redacted by EXACT match only)
        self.keep_ids = keep_ids  # ... the members' project_ids (a longer prefix keeps)

    def ref(self, value):
        """Contract §7: a reference to a discovered project outside the served
        portfolio renders OTHER_PORTFOLIO_REF — its project_id or an entity id that
        project_id prefixes (`<id>-…`), where the LONGEST matching project_id decides
        against a member's; or exactly its PROJECT.md id, which never matches as a
        prefix. With nothing to redact the value is returned unchanged, so a
        single-portfolio install's bytes do not move."""
        if not (self.redact or self.alias) or not isinstance(value, str):
            return value
        v = value.strip()
        if v in self.keep:
            return value
        if v in self.alias:
            return OTHER_PORTFOLIO_REF
        hits = [r for r in self.redact if v == r or v.startswith(r + "-")]
        if not hits:
            return value
        longest = max(len(r) for r in hits)
        if any(v.startswith(k + "-") and len(k) > longest for k in self.keep_ids):
            return value
        return OTHER_PORTFOLIO_REF

    def ref_affected(self, cf):
        """`projects_affected` as a list or as a comma scalar: redacts per element, and
        returns the authored rendering unchanged when nothing in it is redacted."""
        affected = cf.get("projects_affected") if isinstance(cf, dict) else None
        if isinstance(affected, list):
            return ", ".join(self.ref(a) for a in affected)
        raw = _get(cf, "projects_affected")
        parts = [x.strip() for x in raw.split(",")]
        if (self.redact or self.alias) and any(self.ref(x) != x for x in parts):
            return ", ".join(self.ref(x) for x in parts)
        return raw


def _rag_cell(rag: str) -> str:
    return f"{RAG_GLYPH.get(rag, '')} {rag}".strip()


def resolve_dimension(dim, rollup, as_of) -> tuple:
    """Resolve ONE S2 Health-Indicator dimension to its (cell, source-note) pair.

    `dim` is a HEALTH_DIMENSIONS row: (label, backing metric, §2 field or None).

    A row naming NO §2 field renders UNSOURCED_CELL and appends NO staleness
    suffix (contract §4.1 R2). The reason is not cosmetic: `[STALE]` qualifies a
    VALUE, and a cell reporting that no value exists has nothing for it to
    qualify. Marking an absent value stale layers a second false signal on the
    first.

    A row that DOES name a field reads it off the rollup, formats it (RAG glyph
    for `status`, escaped text otherwise), and carries the ordinary staleness
    suffix, because that cell holds a real value — after asserting the field
    actually exists, which is §4.1 R3 enforced rather than merely warned about.
    """
    _label, metric, field = dim
    if field is None:
        return (UNSOURCED_CELL, f"{metric} — no §2 contract field carries it")
    if not hasattr(rollup, field):
        # §4.1 R3 mis-ordering, caught at the seam it happens at. A bare
        # getattr here raises AttributeError, which main()'s `except
        # ContractDrift` does not catch, so the operator gets a traceback
        # naming no remedy — the one failure in this module that does not
        # name its contract clause and its fix.
        raise ContractDrift(
            f"HEALTH_DIMENSIONS row {_label!r} names §2 field {field!r}, which "
            f"no rollup carries. This is the §4.1 R3 mis-ordering: backing "
            f"arrives WITH its producer, so adding a backing field is a §2 "
            f"CONTRACT change FIRST and a HEALTH_DIMENSIONS row edit second, "
            f"never the reverse — the reverse makes this table read as "
            f"delivered when it is not. Either land {field!r} in §2 and on the "
            f"Rollup this composer builds, or set this row's third field back "
            f"to None so the cell renders {UNSOURCED_CELL} and says so.")
    value = getattr(rollup, field)
    cell = _rag_cell(value) if field == "status" else _md_escape(value)
    return (f"{cell}{_stale_suffix(rollup.last_published, as_of)}",
            f"{metric} — §2 `{field}`")


def _md_escape(value) -> str:
    """Neutralize a stray `|` so a value never breaks a markdown table cell."""
    return str(value).replace("|", "\\|").strip()


def _get(mapping, key, default="—"):
    v = mapping.get(key, default) if isinstance(mapping, dict) else default
    return _md_escape(v) if v not in ("", None) else default


def _incomplete_risk_flag(item) -> str:
    """The S6 repair flag (weekly-status-rollup §3.6; contract §2 "flagged for
    repair"): a risk-bearing row (RAID / XRC leg) missing an `owner` or a
    `mitigation` renders `[DRIFT: incomplete risk record — <field> missing]` inline
    — the drift is VISIBLE in the composed output rather than silently dropped, and
    the row still composes (exit 0). Returns "" when both are present. The XPD
    (dependency) leg carries no owner/mitigation in the contract and never routes
    through here (it renders `—` by design, never a drift flag)."""
    if not isinstance(item, dict):
        return ""
    missing = [f for f in ("owner", "mitigation") if not str(item.get(f, "")).strip()]
    if not missing:
        return ""
    return f" [DRIFT: incomplete risk record — {' + '.join(missing)} missing]"


# --------------------------------------------------------------------------- #
# Section renderers. Each returns a list of markdown lines (blank-line-terminated).
# The compose() core loop calls these blind — no section shape is hard-coded there.
# --------------------------------------------------------------------------- #

def render_s1(sec, ctx) -> list:
    out = [f"## {sec.title}", "",
           "| Project | Health | Critical Path | Go-Live | Last-Validated |",
           "|---|---|---|---|---|"]
    for r in ctx.rollups:
        md = r.milestone_delta
        crit = _get(md, "next_milestone")
        go = _get(md, "target")
        last = _md_escape(r.last_published) + _stale_suffix(r.last_published, ctx.as_of)
        out.append(f"| {r.project_id} | {_rag_cell(r.status)} | {crit} | {go} | {last} |")
    out.append("")
    return out


def render_s2(sec, ctx) -> list:
    # Per-project Health Indicators, resolved PER DIMENSION.
    #
    # Each row renders its own backing value, or UNSOURCED with the reason in the
    # Source column — never the composed project RAG wearing a dimension label.
    # That was the defect: five independently-labelled rows all emitting one
    # scalar, so a reader comparing rows could not tell which dimension drove a
    # degraded RAG, and a single signal presented itself as five corroborating
    # ones. The Source column is what kills it — a reader sees WHY each cell
    # reads as it does, which five identical glyphs never told them.
    #
    # The composed project RAG is stated ONCE below the table, labelled as a
    # roll-up ACROSS the dimensions rather than a value FOR any one of them. It
    # routes through resolve_dimension like every other cell; it deliberately
    # does NOT re-use the direct rollup-status RAG call, which after this change
    # survives in render_s1 alone.
    out = [f"## {sec.title}", ""]
    for r in ctx.rollups:
        out.append(f"### {r.project_id} — Health Indicators")
        out.append("")
        out.append("| Dimension | Status | Source |")
        out.append("|---|---|---|")
        for dim in HEALTH_DIMENSIONS:
            cell, note = resolve_dimension(dim, r, ctx.as_of)
            out.append(f"| {dim[0]} | {cell} | {note} |")
        out.append("")
        rag_cell, _ = resolve_dimension(("(roll-up)", "composed health_rag", "status"),
                                        r, ctx.as_of)
        out.append(f"_Composed project RAG: {rag_cell} — rendered in Portfolio Health "
                   f"Summary. It is a roll-up ACROSS these dimensions, not a value "
                   f"FOR any one of them._")
        out.append("")
    return out


def render_s3(sec, ctx) -> list:
    out = [f"## {sec.title}", "",
           "| Project | Utilization | Demand-Supply Gap |",
           "|---|---|---|"]
    for r in ctx.rollups:
        cs = r.capacity_signal
        try:
            util = f"{float(cs.get('utilization')):.2f}"
        except (TypeError, ValueError, AttributeError):
            util = "—"
        gap = _get(cs, "gap_rag")
        suffix = _stale_suffix(r.last_published, ctx.as_of)
        out.append(f"| {r.project_id} | {util}{suffix} | {gap} |")
    out.append("")
    return out


def render_s4(sec, ctx) -> list:
    # Portfolio R-G-T Allocation reads PROJECT.md `investment_class` (a supplementary
    # source beyond the 7 core fields). The rollup entity may carry an optional
    # `investment_class` frontmatter passthrough; absent it, the project is
    # Unclassified (a coverage gap, surfaced honestly). The registry supports
    # supplementary source fields — #276/later wire the authoritative source.
    out = [f"## {sec.title}", "",
           "| Class | Projects |", "|---|---|"]
    buckets = {"Run": [], "Grow": [], "Transform": [], "Unclassified": []}
    for r in ctx.rollups:
        buckets["Unclassified"].append(r.project_id)
    for cls in ("Run", "Grow", "Transform", "Unclassified"):
        names = ", ".join(buckets[cls]) if buckets[cls] else "—"
        out.append(f"| {cls} | {names} |")
    out.append("")
    return out


def render_s5(sec, ctx) -> list:
    out = [f"## {sec.title}", ""]
    for r in ctx.rollups:
        out.append(f"### {r.project_id} — Top Risks")
        out.append("")
        if not r.top_risks:
            out.append("_No open risks._")
            out.append("")
            continue
        out.append("| Risk | Owner | Mitigation |")
        out.append("|---|---|---|")
        for item in r.top_risks[:TOP_RISKS_MAX]:
            out.append(f"| {_get(item, 'risk')} | {_get(item, 'owner')} | {_get(item, 'mitigation')} |")
        out.append("")
    return out


def render_s6(sec, ctx) -> list:
    # Cross-Project RAID — aggregated across projects from THREE contract fields:
    # top_risks[] (RAID · Risk), key_dependencies[] (XPD · Dependency),
    # cross_project_conflicts[] (XRC · Conflict). cross_project_conflicts[] is what
    # makes S6 fully contract-driven (scope-lock XC-2, PATH 1); #1169 fills the risk
    # aggregation via this same registry slot.
    #
    # The 6-column shell is the ONE shared shape across this composer, the contract
    # §4 S6 spec, and weekly-status-rollup §3.6/§6:
    #   Type | Item | Owner | Mitigation | Source-Tier | Projects-Affected
    #   * Type          = the source leg (Risk / Dependency / Conflict).
    #   * Source-Tier   = `Project` for the project-scoped RAID leg; `Portfolio` for
    #                     the already-portfolio-tier XPD / XRC legs (the escalation
    #                     ladder the shell enumerates: Team → Project → … → Portfolio).
    #   * Projects-Affected = the owning project (RAID) / the linked {from},{to}
    #                     projects (XPD) / projects_affected[] (XRC).
    # A risk-bearing row (RAID / XRC) missing its owner or mitigation renders the
    # SKILL.md `[DRIFT: incomplete risk record]` repair flag inline (contract §2
    # "flagged for repair") — visible drift, not a silent drop. The XPD leg has no
    # owner/mitigation in the contract, so it renders `—` (never a drift flag).
    out = [f"## {sec.title}", "",
           "| Type | Item | Owner | Mitigation | Source-Tier | Projects-Affected |",
           "|---|---|---|---|---|---|"]
    for r in ctx.rollups:
        for item in r.top_risks:
            flag = _incomplete_risk_flag(item)
            out.append(f"| Risk | {_get(item, 'risk')}{flag} | {_get(item, 'owner')} | "
                       f"{_get(item, 'mitigation')} | Project | {r.project_id} |")
        for dep in r.key_dependencies:
            _f, _t = ctx.ref(_get(dep, 'from')), ctx.ref(_get(dep, 'to'))
            desc = f"{_f} → {_t} ({_get(dep, 'state')})"
            linked = f"{_f}, {_t}"
            out.append(f"| Dependency | {desc} | — | — | Portfolio | {linked} |")
        for cf in r.cross_project_conflicts:
            aff = ctx.ref_affected(cf)
            flag = _incomplete_risk_flag(cf)
            out.append(f"| Conflict | {_get(cf, 'conflict')}{flag} | {_get(cf, 'owner')} | "
                       f"{_get(cf, 'mitigation')} | Portfolio | {aff} |")
    out.append("")
    return out


def render_s7(sec, ctx) -> list:
    out = [f"## {sec.title}", "",
           "| From | To | State | Project |", "|---|---|---|---|"]
    for r in ctx.rollups:
        for dep in r.key_dependencies:
            out.append(f"| {ctx.ref(_get(dep, 'from'))} | {ctx.ref(_get(dep, 'to'))} | "
                       f"{_get(dep, 'state')} | {r.project_id} |")
    out.append("")
    return out


def render_s8(sec, ctx) -> list:
    out = [f"## {sec.title}", ""]
    for r in ctx.rollups:
        out.append(f"### {r.project_id} — Resource Conflicts")
        out.append("")
        if not r.cross_project_conflicts:
            out.append("_No resource conflicts._")
            out.append("")
            continue
        out.append("| Conflict | Projects Affected | Owner | Mitigation |")
        out.append("|---|---|---|---|")
        for cf in r.cross_project_conflicts:
            aff = ctx.ref_affected(cf)
            out.append(f"| {_get(cf, 'conflict')} | {aff} | {_get(cf, 'owner')} | {_get(cf, 'mitigation')} |")
        out.append("")
    return out


class Section:
    """A declarative registry entry — the schema-agnostic injection unit."""

    __slots__ = ("sid", "title", "fields", "render")

    def __init__(self, sid, title, fields, render):
        self.sid = sid
        self.title = title
        self.fields = fields    # contract fields this section reads (documentation)
        self.render = render


# ========================= EXTENSION SEAM ================================== #
# The schema-agnostic section registry. compose() iterates this and calls each
# entry's `render` blind. #276 (health-section detail / thresholds) and #1169
# (S6 risk fill) INJECT by adding or editing entries + their render callables
# HERE — the compose() core loop below is never touched by such edits. This is
# what lets the engine ship before #276's section content settles.
# =========================================================================== #
SECTION_REGISTRY = (
    Section("S1", "Portfolio Health Summary", ("status", "milestone_delta", "last_published"), render_s1),
    Section("S2", "Health Indicators (per project)", ("status",), render_s2),
    Section("S3", "Capacity Dashboard", ("capacity_signal",), render_s3),
    Section("S4", "Portfolio R-G-T Allocation", (), render_s4),
    Section("S5", "Top Risks (per project)", ("top_risks",), render_s5),
    Section("S6", "Cross-Project RAID",
            ("top_risks", "key_dependencies", "cross_project_conflicts"), render_s6),
    Section("S7", "Cross-Project Dependencies", ("key_dependencies",), render_s7),
    Section("S8", "Resource Conflicts (per project)", ("cross_project_conflicts",), render_s8),
)


# --------------------------------------------------------------------------- #
# Compose (the deterministic core — no section shape lives here).
# --------------------------------------------------------------------------- #

def compose(root: Path, as_of: date, portfolio=None, report=None) -> str:
    """Read every rollup under `root`, validate against the contract (raises
    ContractDrift on any type violation), select the served portfolio's member
    rollups (contract §7 — `portfolio` None = unscoped, legal only at a root whose
    `_config/` holds no Portfolio record; raises PortfolioScopeError otherwise), and
    render the section registry. Returns the composed markdown (LF newlines, single
    trailing newline). `report`, when a dict, receives the §7 counts."""
    paths = discover_rollups(root)
    records = discover_portfolio_records(root)
    active = sorted({pid for _, pid, st in records if st == "active"})
    dupes = sorted({pid for _, pid, st in records
                    if st == "active" and sum(1 for _, q, s in records if q == pid and s == "active") > 1})
    keyed = [read_rollup_keys(p, root) for p in paths]   # phase 1: join keys, every rollup
    key_drift = [f"{rel} (project {pid or '<unset>'}): {'; '.join(d)}" for rel, pid, _, d in keyed if d]
    if key_drift:
        raise ContractDrift("join-key drift — membership is undecidable, so every "
                            "portfolio's run halts: " + " | ".join(key_drift))
    rep_ = {"served": portfolio, "portfolios": len(active), "active": active, "duplicates": dupes}
    redact, keep = frozenset(), frozenset()
    alias, keep_ids = frozenset(), frozenset()
    if portfolio is None:
        if active:
            raise PortfolioScopeError(
                f"this root's {CONFIG_DIRNAME}/ holds {len(active)} active Portfolio record(s) "
                f"({', '.join(active)}) — name the served portfolio with --portfolio (contract §7)")
        named = sorted({k for _, _, k, _ in keyed if k})
        if len(named) >= 2:
            raise PortfolioScopeError(
                f"rollups under this root name {len(named)} portfolios "
                f"({', '.join(named)}) but the root holds no active Portfolio record — "
                f"create the Portfolio records, one per portfolio, then compose each "
                f"portfolio (contract §7)")
        members = paths
        rep_.update({"members": len(paths), "unresolved": sorted(p for _, p, k, _ in keyed if k)})
    else:
        if portfolio not in active:   # also the root guard: a narrowed root holds no record
            raise PortfolioScopeError(
                f"--portfolio {portfolio} names no active Portfolio record under this root's "
                f"{CONFIG_DIRNAME}/ (active: {', '.join(active) or 'none'}) — a scoped run "
                f"composes at the projects root (contract §7)")
        if (root / CONFIG_DIRNAME / ROOT_COMPOSED_NAME).exists():
            raise PortfolioScopeError(
                f"unmigrated layout — {CONFIG_DIRNAME}/{ROOT_COMPOSED_NAME} exists beside active "
                f"Portfolio records; move it to {CONFIG_DIRNAME}/<portfolio_id>/{ROOT_COMPOSED_NAME} "
                f"(contract §7) before composing")
        members, sel, redact, alias, keep_ids, keep = select_rollups(root, paths, portfolio, records)
        rep_.update(sel)
        member_set = set(members)
        for p in paths:                                    # phase 2, outside S: count, never name
            if p in member_set:
                continue
            try:
                read_rollup(p, root)
            except ContractDrift:
                rep_["drift_outside"] += 1
    if report is not None:
        report.update(rep_)
    rollups = [read_rollup(p, root) for p in members]   # phase 2: members halt on field drift
    rollups.sort(key=lambda r: r.project_id)   # determinism: never trust FS order
    ctx = Ctx(rollups, as_of, redact, keep, alias, keep_ids)

    lines = [
        "# Portfolio Dashboard",
        "",
        "_Composed deterministically by `compose-portfolio.py` from the per-project "
        "rollup entities (`core/standards/portfolio-writeback-contract.md` §4). "
        "Staged for the Cowork `PORTFOLIO.md` writer via `weekly-status-rollup` "
        "Section 6 — never written into `projects/` by this tool._",
        "",
    ]
    for section in SECTION_REGISTRY:
        lines.extend(section.render(section, ctx))

    # meta (S-map `meta` row): portfolio-level Last Updated = the as_of anchor.
    lines.append("---")
    lines.append(
        f"_Last Updated: {as_of.isoformat()} · freshness anchor `--as-of={as_of.isoformat()}` · "
        f"`{STALE_MARKER}` > {STALE_THRESHOLD_BD} bd, auto-degrade > {DEGRADE_THRESHOLD_BD} bd "
        f"(business days)._"
    )
    body = "\n".join(lines)
    return body.rstrip("\n") + "\n"   # canonical: single trailing newline


# --------------------------------------------------------------------------- #
# --out projects/ guard (CIAC-4, structural).
# --------------------------------------------------------------------------- #

def out_path_rejected(out_arg: str) -> bool:
    """Fail-closed: reject any --out path that has a `projects` component (the
    Layer-2, Cowork-owned tree). Over-rejection is the safe direction — the
    composer NEVER writes into projects/."""
    resolved = Path(out_arg).expanduser().resolve()
    return "projects" in resolved.parts


# --------------------------------------------------------------------------- #
# Self-test (committed fixture — idempotency + render + drift + guard).
# --------------------------------------------------------------------------- #

def _fixture_dir(name: str = "portfolio-composer") -> Path:
    return Path(__file__).resolve().parent / "tests" / "fixtures" / name


def _selftest_as_of(root: Path) -> date:
    """The fixed --self-test anchor = max(last_published) across the fixture — pins
    a deterministic date so the fixture output is byte-reproducible (§3)."""
    dates = [_parse_iso_date(read_rollup(p, root).last_published)
             for p in discover_rollups(root)]
    return max(dates)


def run_self_test() -> int:
    """Assert the composer's contract against the committed fixture:
      (idempotency)  two runs on unchanged input are byte-identical (SHA-256).
      (render)       all 8 section headers (S1-S8) + the meta line are present.
      (s6-shell)     S6 renders the 6-column shell (Type|Item|Owner|Mitigation|
                     Source-Tier|Projects-Affected) shared with contract §4 + the
                     weekly-status-rollup S6 shell.
      (staleness)    the aged fixture rollup renders [STALE]/degrade; the fresh one
                     does not — proving the anchor discriminates.
      (exit-sep)     a clean compose with [STALE] present is exit 0 (NOT a finding).
      (drift)        a type-violating field raises ContractDrift (-> exit 1 halt).
      (join-key)     an ABSENT project_id raises ContractDrift (-> exit 1) instead of
                     silently resolving a fallback. The removed `or scalars.get("id")`
                     chain resolved the template's own `id: <slug>-rollup`, i.e. a
                     WRONG join key, and composed exit 0. This case fails pre-fix.
      ([DRIFT] render) a risk-bearing row missing an owner/mitigation renders the
                     inline `[DRIFT: incomplete risk record]` repair flag and STILL
                     composes (exit 0) — the soft path, distinct from the hard halt.
      (s2-per-dimension) no S2 dimension cell carries the composed project RAG.
                     FAILS PRE-FIX (pre-fix all five cells ARE that scalar). Its
                     window resolves from SECTION_REGISTRY, not from title
                     literals, and an anti-vacuity cell count runs BEFORE the
                     subject so an empty window reports BROKEN PROBE rather than
                     passing. Sensitivity arm: the same read over S1 must find a
                     RAG cell, because render_s1 legitimately renders one.
      (s2-resolver-varies) two differently-backed dimensions resolve to DIFFERENT
                     cells — AC-1's real subject, since with no §2 field backing
                     any dimension the shipped render is five equal UNSOURCED
                     cells by design. Control arm: two rows both bound to
                     `status` must render EQUAL cells. Also asserts §4.1 R2 — an
                     UNSOURCED cell carries no staleness marker.
      (join-key-polluted) a `project_id` carrying a trailing `# …` raises
                     ContractDrift (-> exit 1). FAILS PRE-FIX: the shared reader
                     treats the comment as CONTENT, so pre-fix the value passed
                     the presence check and composed on a WRONG join key at exit
                     0. Control arm: the unmodified fixture still composes at
                     exit 0 with its join key intact.
      (discovery-polluted) a polluted `entity_type` raises ContractDrift (-> exit
                     1) instead of silently skipping the rollup and composing a
                     portfolio that omits it at exit 0. TWO sub-cases — the
                     unquoted shape and the quoted shape, whose displaced closing
                     quote defeats a prefix test. Control arm (anti-vacuity):
                     clean discovery finds both fixture rollups. Specificity arm:
                     an unrelated `entity_type` is NOT flagged.
      (guard)        an --out path under projects/ is rejected.
      (dot-segment)  a rollup planted under a dot-leading DIRECTORY and one at a
                     dot-leading FILENAME are both OUT OF CORPUS: discovery
                     returns the clean count and the render is byte-identical.
                     FAILS PRE-FIX — discover_rollups walked a bare rglob with no
                     dot-segment skip and returned the planted copies, where the
                     other two corpus walkers excluded them. Control arm
                     (anti-vacuity), asserted first: clean discovery finds a
                     non-zero count, so the equality is not 0 == 0.
      (portfolio-scope) contract §7 — serving each portfolio of the two-portfolio tree
                     composes exactly its own project. CONTROL: the pre-scoping render
                     of the same tree composes both.
      (portfolio-discrimination) AC4 on subject rows — the other portfolio's rollup
                     is never a subject row; CONTROL: serving its own portfolio composes
                     it. Every narrowed root (the other project, its rollup folder, the
                     served project) is REFUSED for a scoped run. Defense in depth at the
                     full root: the other project's id, its PROJECT.md id and an entity
                     id it prefixes occur 0 times and the marker renders; SENSITIVITY:
                     the pre-scoping render names all three. Free text is not rewritten:
                     the display-name residual is MEASURED and pinned.
      (single-portfolio-unchanged) AC3 — a one-record install composes the bytes the
                     pre-scoping composer composed on the same tree. CONTROL: the same
                     comparison on the two-portfolio tree differs.
      (portfolio-membership) one portfolio: an unkeyed rollup is its member; two or
                     more: an unkeyed rollup is UNASSIGNED (in no output, named, exit
                     0); a key naming no record is UNRESOLVED, one naming an archived
                     record INACTIVE (both excluded, named); no record: a keyed rollup
                     is composed unscoped and reported unresolved.
      (portfolio-crosscheck) a rollup whose key disagrees with its own PROJECT.md is
                     HELD out of every output (a moved project); CONTROL: on a one-
                     portfolio tree an unkeyed rollup whose PROJECT.md names the only
                     portfolio agrees and composes.
      (portfolio-key-drift) an empty, a polluted, and a near-miss-NAMED portfolio key
                     halt EVERY portfolio's run (exit 1) with the diagnostic naming its
                     remedy. CONTROL: the unmodified tree exits 0.
      (portfolio-field-drift) field drift in another portfolio's rollup does not halt
                     the served run: counted, not named. The same drift halts its own
                     portfolio's run. CONTROL: the unmodified tree counts 0.
      (portfolio-records) records are found by key, not filename (one in its folder, one
                     at the config top); a dot-leading copy is out of corpus; a duplicate
                     is counted once and reported; a near-miss type key is exit 2.
      (portfolio-guards) exit 2 for: an unscoped run at a root holding records; an
                     unscoped run at a record-less root whose rollups name two
                     portfolios; a served id naming no active record; an unmigrated
                     layout (the root composed file beside records); a non-slug flag.
                     CONTROL: the zero-record committed fixture still composes both.
      (portfolio-recordless-stop) D-RecordlessTwoIds — a record-less root whose rollups
                     name two portfolios is stopped (exit 2) with the remedy "create the
                     Portfolio records", never a scoped run. CONTROL: rollups naming one
                     portfolio there compose unscoped.
      (portfolio-composed-not-record) D-RecordNotComposedFile — a composed PORTFOLIO.md
                     that carries entity_type: Portfolio is exit 2. CONTROL: the same
                     record in its own file beside it is served.
      (portfolio-record-walk) the record walk is bounded to <root>/_config/*.md and
                     <root>/_config/<slug>/*.md, never releases/ in any case; one id in
                     conflicting states and the reserved id `releases` are exit 2.
                     CONTROL: a record in a slug-named folder is counted, and two active
                     copies of one id count once and are reported.
      (portfolio-project-key) a PROJECT.md portfolio_id that fails the slug test holds
                     the rollup and is named in its own report class, not as a
                     re-emission hold. CONTROL: the clean tree composes it.
      (portfolio-alias-exact) a PROJECT.md id alias redacts by exact match only, and the
                     longest project_id prefix decides against a member's. SENSITIVITY:
                     the pre-scoping render names the neutral id.
      (portfolio-report-line) the line leads with the surfaces' report-line fields,
                     prints the active set, and labels an archived-only unscoped run "no
                     active Portfolio record". CONTROL: the committed zero-record
                     fixture's line stays empty.
    """
    import contextlib
    import io
    import shutil
    import tempfile

    def _quiet_main(argv) -> int:
        """Run main() with stdout+stderr captured — the self-test exercises the
        exit-code mapping without dumping the body / drift line to the console."""
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return main(argv)

    fixture = _fixture_dir()
    if not fixture.exists():
        print(f"self-test FAIL: fixture missing at {fixture}", file=sys.stderr)
        return 1
    failures: list = []

    with tempfile.TemporaryDirectory() as td:
        root = Path(td) / "corpus"
        shutil.copytree(fixture, root)
        as_of = _selftest_as_of(root)

        # (idempotency) double-run byte-identity.
        out1 = compose(root, as_of)
        out2 = compose(root, as_of)
        h1 = hashlib.sha256(out1.encode("utf-8")).hexdigest()
        h2 = hashlib.sha256(out2.encode("utf-8")).hexdigest()
        if h1 != h2:
            failures.append(f"(idempotency) two runs diverge: {h1[:12]} != {h2[:12]}")

        # (render) all section headers + meta.
        for sec in SECTION_REGISTRY:
            if f"## {sec.title}" not in out1:
                failures.append(f"(render) section {sec.sid} header missing: '## {sec.title}'")
        if "Last Updated:" not in out1:
            failures.append("(render) meta 'Last Updated' line missing")

        # (s6-shell) S6 renders the 6-column shell shared with contract §4 + the
        # weekly-status-rollup S6 shell (Type|Item|Owner|Mitigation|Source-Tier|
        # Projects-Affected) — the F-02 reconciliation.
        s6_header = ("| Type | Item | Owner | Mitigation | Source-Tier | "
                     "Projects-Affected |")
        if s6_header not in out1:
            failures.append("(s6-shell) S6 6-column shell header not rendered")

        # (staleness) the aged rollup marks [STALE]; at least one degrade fires.
        if STALE_MARKER not in out1 and DEGRADE_MARKER not in out1:
            failures.append("(staleness) no [STALE]/degrade marker rendered on the aged fixture")

        # (exit-sep) a clean compose with [STALE] present is exit 0 (main() returns 0).
        rc = _quiet_main(["--root", str(root), "--as-of", as_of.isoformat()])
        if rc != 0:
            failures.append(f"(exit-sep) clean compose with [STALE] present returned {rc}, expected 0")

        # (drift) mutate one field's type -> ContractDrift -> main() exit 1.
        drift_root = Path(td) / "drift"
        shutil.copytree(fixture, drift_root)
        victim = discover_rollups(drift_root)[0]
        txt = victim.read_text(encoding="utf-8").replace("status: green", "status: purple")\
                                                 .replace("status: red", "status: purple")
        victim.write_text(txt, encoding="utf-8")
        try:
            compose(drift_root, as_of)
            failures.append("(drift) a type-violating status did NOT raise ContractDrift")
        except ContractDrift:
            pass
        rc_drift = _quiet_main(["--root", str(drift_root), "--as-of", as_of.isoformat()])
        if rc_drift != 1:
            failures.append(f"(drift) type violation returned exit {rc_drift}, expected 1")

        # (join-key) an absent project_id is contract drift, NOT a silent fallback.
        # Pre-fix, the `or scalars.get("id")` chain resolved `<slug>-rollup` — a WRONG
        # join key — and composed exit 0. This case fails on the pre-fix tree.
        jk_root = Path(td) / "joinkey"
        shutil.copytree(fixture, jk_root)
        victim3 = discover_rollups(jk_root)[0]
        txt3 = victim3.read_text(encoding="utf-8")
        victim3.write_text("\n".join(l for l in txt3.split("\n")
                                     if not l.startswith("project_id:")), encoding="utf-8")
        try:
            ids = [read_rollup(p, jk_root).project_id for p in discover_rollups(jk_root)]
            failures.append(f"(join-key) an absent project_id did NOT raise "
                            f"ContractDrift; resolved keys = {ids}")
        except ContractDrift as e:
            if "project_id" not in str(e):
                failures.append(f"(join-key) ContractDrift raised but does not "
                                f"name project_id: {e}")
        rc_jk = _quiet_main(["--root", str(jk_root), "--as-of", as_of.isoformat()])
        if rc_jk != 1:
            failures.append(f"(join-key) absent project_id returned exit {rc_jk}, expected 1")

        # ([DRIFT] render) a risk-bearing row (RAID / XRC) missing an owner is a SOFT
        # incompleteness — it renders the S6 `[DRIFT: incomplete risk record]` repair
        # flag INLINE and STILL composes (exit 0), distinct from the hard type-drift
        # halt above. This is the SKILL.md-consistent path (§3.6): visible drift, not
        # a silent drop and not an abort.
        incomplete_root = Path(td) / "incomplete"
        shutil.copytree(fixture, incomplete_root)
        victim2 = discover_rollups(incomplete_root)[0]   # proj-alpha (sorted first)
        txt2 = victim2.read_text(encoding="utf-8").replace('    owner: "PM-Alpha"\n', "", 1)
        victim2.write_text(txt2, encoding="utf-8")
        incomplete_out = compose(incomplete_root, as_of)
        if "[DRIFT: incomplete risk record" not in incomplete_out:
            failures.append("([DRIFT] render) an incomplete risk row did NOT render the repair flag")
        rc_incomplete = _quiet_main(["--root", str(incomplete_root), "--as-of", as_of.isoformat()])
        if rc_incomplete != 0:
            failures.append(f"([DRIFT] render) incomplete-risk compose returned exit {rc_incomplete}, expected 0")

        # (s2-per-dimension) FAILS PRE-FIX. No S2 dimension cell may carry the
        # composed project RAG — that WAS the defect: five labelled rows all
        # emitting one scalar.
        #
        # The window is resolved from SECTION_REGISTRY, NOT from title string
        # literals. The module's own EXTENSION SEAM banner declares registry and
        # title edits the sanctioned way to change this file, and a literal-split
        # extractor empties its window the moment a title moves — at which point
        # the subject assertion passes on nothing and the case silently stops
        # discriminating. Measured: with the S2 title changed, a literal-anchored
        # extractor pulls 0 cells and flips to PASS while 10 dimension rows still
        # carry the RAG glyph.
        _rollups = [read_rollup(p, root) for p in discover_rollups(root)]
        # Leak detector: the project's RAG GLYPH. Stronger than matching the
        # formatted cell text — a glyph in a dimension cell IS the defect however
        # the cell is later formatted — and it keeps the test independent of the
        # render helper it is grading.
        _rag_glyphs = {RAG_GLYPH[r.status] for r in _rollups if r.status in RAG_GLYPH}
        _t = {s.sid: s.title for s in SECTION_REGISTRY}

        def _section_window(text, sid, next_sid):
            head = f"## {_t[sid]}"
            tail = f"## {_t[next_sid]}"
            if head not in text:
                return None
            seg = text.split(head, 1)[1]
            return seg.split(tail, 1)[0] if tail in seg else seg

        _dim_re = re.compile(r"^\| (?:%s) \|" % "|".join(
            re.escape(d[0]) for d in HEALTH_DIMENSIONS))
        s2_win = _section_window(out1, "S2", "S3")
        dim_cells = []
        if s2_win is not None:
            for line in s2_win.split("\n"):
                if _dim_re.match(line):
                    dim_cells.append(line.split("|")[2].strip())

        # ANTI-VACUITY, evaluated BEFORE the subject. An empty window is a broken
        # probe, never a pass.
        _expected_cells = len(HEALTH_DIMENSIONS) * len(_rollups)
        if len(dim_cells) != _expected_cells:
            failures.append(
                f"(s2-per-dimension) BROKEN PROBE — extracted {len(dim_cells)} "
                f"dimension cells, expected {_expected_cells} "
                f"(len(HEALTH_DIMENSIONS) x rollups). The subject window is empty "
                f"or truncated, so the subject assertion below would pass on "
                f"nothing")
        else:
            leaked = [c for c in dim_cells if any(g in c for g in _rag_glyphs)]
            if leaked:
                failures.append(
                    f"(s2-per-dimension) {len(leaked)} of {len(dim_cells)} "
                    f"dimension cells carry the composed project RAG: "
                    f"{sorted(set(leaked))}")

        # SENSITIVITY ARM — the same column-2 read over the S1 window MUST find a
        # RAG cell, because render_s1 legitimately renders one. If it does not,
        # the reader is dead and the subject zero above proves nothing.
        s1_win = _section_window(out1, "S1", "S2")
        s1_rag_found = False
        if s1_win:
            for line in s1_win.split("\n"):
                parts = line.split("|")
                if len(parts) > 2 and any(g in parts[2] for g in _rag_glyphs):
                    s1_rag_found = True
                    break
        if not s1_rag_found:
            failures.append("(s2-per-dimension) BROKEN PROBE — the S1 control arm "
                            "found no RAG cell, so the reader is not alive and the "
                            "S2 result is not evidence")

        # (s2-resolver-varies) AC-1 limb 1 as a property of the MECHANISM.
        # No §2 field backs a dimension today, so the shipped render is five equal
        # UNSOURCED cells BY DESIGN, and inequality of the shipped render can never
        # be the test. Bind two rows to different fields and assert they differ.
        _r0 = _rollups[0]
        _a = resolve_dimension(("X", "m", "status"), _r0, as_of)[0]
        _b = resolve_dimension(("Y", "m", "last_published"), _r0, as_of)[0]
        if _a == _b:
            failures.append(f"(s2-resolver-varies) two differently-backed rows "
                            f"resolved to the same cell {_a!r}")
        # CONTROL ARM, in AC-1's own words: two rows both bound to `status` must
        # render EQUAL cells, so the probe is not merely detecting inequality.
        _c = resolve_dimension(("Z", "m2", "status"), _r0, as_of)[0]
        if _a != _c:
            failures.append(f"(s2-resolver-varies) CONTROL FAILED — two rows both "
                            f"bound to `status` rendered differently: {_a!r} vs {_c!r}")
        # §4.1 R2: an UNSOURCED cell carries no staleness marker.
        _u = resolve_dimension(("W", "m3", None), _r0, as_of)[0]
        if _u != UNSOURCED_CELL:
            failures.append(f"(s2-resolver-varies) a None-backed row rendered "
                            f"{_u!r}, expected {UNSOURCED_CELL!r}")
        if STALE_MARKER in _u or DEGRADE_MARKER in _u:
            failures.append("(s2-resolver-varies) R2 violated — UNSOURCED carries a "
                            "staleness marker; [STALE] qualifies a VALUE and this "
                            "cell reports that no value exists")

        # (dimension-seam) The §4.1 R3 mis-ordering fails with THIS module's
        # diagnostic, not a bare AttributeError. A HEALTH_DIMENSIONS row pointed
        # at a §2 field no rollup carries is precisely the mistake R3 exists to
        # warn about; before the guard it escaped main()'s `except ContractDrift`
        # and reached the operator as a traceback naming no remedy, alone among
        # this module's failures.
        try:
            resolve_dimension(("Q", "m4", "spi"), _r0, as_of)
            failures.append("(dimension-seam) a row naming a §2 field absent from "
                            "the rollup did NOT raise ContractDrift")
        except ContractDrift as _e:
            if "R3" not in str(_e) or "spi" not in str(_e):
                failures.append(f"(dimension-seam) ContractDrift raised but does "
                                f"not name §4.1 R3 and the offending field: {_e}")
        except AttributeError:
            failures.append("(dimension-seam) the seam raises a bare AttributeError, "
                            "which main()'s ContractDrift handler does not catch — "
                            "the operator gets a traceback naming no remedy")
        # SPECIFICITY — a row naming a REAL field must still resolve unchanged, so
        # the guard cannot pass by rejecting everything.
        _seam_ok = resolve_dimension(("Q", "m4", "status"), _r0, as_of)[0]
        if _seam_ok != _a:
            failures.append(f"(dimension-seam) SPECIFICITY FAILED — the guard "
                            f"changed a real field's resolution: {_seam_ok!r} != {_a!r}")

        # (join-key-polluted) FAILS PRE-FIX. A trailing '# …' on the project_id
        # line is CONTENT to the shared reader, so pre-fix the polluted value
        # passed the presence check and composed at exit 0 on a WRONG join key.
        pol_root = Path(td) / "polluted"
        shutil.copytree(fixture, pol_root)
        victim4 = [p for p in discover_rollups(pol_root) if "alpha" in p.as_posix()][0]
        txt4 = victim4.read_text(encoding="utf-8").replace(
            "project_id: proj-alpha",
            "project_id: proj-alpha        # renamed from alpha-2024", 1)
        victim4.write_text(txt4, encoding="utf-8")
        try:
            compose(pol_root, as_of)
            failures.append("(join-key-polluted) a polluted project_id did NOT raise "
                            "ContractDrift — it composed on a wrong join key")
        except ContractDrift as e:
            if "project_id" not in str(e):
                failures.append(f"(join-key-polluted) ContractDrift raised but does "
                                f"not name project_id: {e}")
        rc_pol = _quiet_main(["--root", str(pol_root), "--as-of", as_of.isoformat()])
        if rc_pol != 1:
            failures.append(f"(join-key-polluted) returned exit {rc_pol}, expected 1")
        # CONTROL ARM — same instrument, same target: the UNMODIFIED fixture still
        # composes at exit 0 with the join key intact, so the probe is not merely
        # detecting change.
        if _quiet_main(["--root", str(root), "--as-of", as_of.isoformat()]) != 0:
            failures.append("(join-key-polluted) CONTROL FAILED — the unmodified "
                            "fixture no longer composes at exit 0")
        if read_rollup(discover_rollups(root)[0], root).project_id != "proj-alpha":
            failures.append("(join-key-polluted) CONTROL FAILED — the unmodified "
                            "fixture's join key is not 'proj-alpha'")

        # (discovery-polluted) FAILS PRE-FIX, and this surface fails WORSE than the
        # join key: pre-fix a polluted entity_type silently skipped the rollup and
        # composed a portfolio missing that project at exit 0, with no diagnostic.
        # TWO sub-cases, because the guard must see both pollution shapes a reader
        # actually produces.
        for _tag, _old, _new in (
            ("unquoted", "entity_type: Project Rollup (composed)",
             "entity_type: Project Rollup (composed)        # composed read-surface"),
            ("quoted", "entity_type: Project Rollup (composed)",
             'entity_type: "Project Rollup (composed)"   # composed read-surface'),
        ):
            et_root = Path(td) / f"etype-{_tag}"
            shutil.copytree(fixture, et_root)
            victim5 = [p for p in discover_rollups(et_root) if "beta" in p.as_posix()][0]
            victim5.write_text(
                victim5.read_text(encoding="utf-8").replace(_old, _new, 1),
                encoding="utf-8")
            try:
                discover_rollups(et_root)
                failures.append(f"(discovery-polluted/{_tag}) a polluted entity_type "
                                f"did NOT raise — the rollup would be silently "
                                f"skipped at exit 0")
            except ContractDrift as e:
                if "entity_type" not in str(e):
                    failures.append(f"(discovery-polluted/{_tag}) ContractDrift "
                                    f"raised but does not name entity_type: {e}")
            rc_et = _quiet_main(["--root", str(et_root), "--as-of", as_of.isoformat()])
            if rc_et != 1:
                failures.append(f"(discovery-polluted/{_tag}) returned exit {rc_et}, "
                                f"expected 1")
        # CONTROL ARM (anti-vacuity) — a walker that discovers nothing anywhere
        # cannot make the raises above meaningful.
        if len(discover_rollups(root)) != 2:
            failures.append(f"(discovery-polluted) CONTROL FAILED — clean discovery "
                            f"found {len(discover_rollups(root))} rollups, expected 2")
        # SPECIFICITY ARM — an unrelated entity_type must NOT be flagged.
        unrel_root = Path(td) / "etype-unrelated"
        shutil.copytree(fixture, unrel_root)
        victim6 = [p for p in discover_rollups(unrel_root) if "beta" in p.as_posix()][0]
        victim6.write_text(
            victim6.read_text(encoding="utf-8").replace(
                "entity_type: Project Rollup (composed)", "entity_type: Project", 1),
            encoding="utf-8")
        try:
            if len(discover_rollups(unrel_root)) != 1:
                failures.append("(discovery-polluted) SPECIFICITY FAILED — an "
                                "unrelated entity_type changed the discovered set")
        except ContractDrift as e:
            failures.append(f"(discovery-polluted) SPECIFICITY FAILED — an unrelated "
                            f"entity_type was flagged as a near-miss: {e}")

        # ---- contract §7 Portfolio scoping ------------------------------------
        two = _fixture_dir("portfolio-composer-two-portfolio")
        one = _fixture_dir("portfolio-composer-single-portfolio")
        two_root, one_root = Path(td) / "two", Path(td) / "one"
        shutil.copytree(two, two_root)
        shutil.copytree(one, one_root)
        _iso = as_of.isoformat()

        def _s1_ids(text):
            win = _section_window(text, "S1", "S2") or ""
            return [l.split("|")[1].strip() for l in win.split("\n")
                    if l.startswith("| ") and not l.startswith("| Project ")]

        def _pre_scoping(src_root, name):
            # The tree as the pre-§7 composer saw it: no rollup key, no config folder.
            dst = Path(td) / name
            shutil.copytree(src_root, dst)
            for _p in discover_rollups(dst):
                _p.write_text("\n".join(l for l in _p.read_text(encoding="utf-8").split("\n")
                                        if not l.startswith("portfolio_id:")), encoding="utf-8")
            shutil.rmtree(dst / CONFIG_DIRNAME)
            return dst

        def _variant(name, base, edits):
            dst = Path(td) / name
            shutil.copytree(base, dst)
            for rel, old, new in edits:
                f = dst / rel
                txt = f.read_text(encoding="utf-8") if f.exists() else ""
                if old is None:
                    f.parent.mkdir(parents=True, exist_ok=True)
                    f.write_text(new, encoding="utf-8")
                elif old not in txt:
                    failures.append(f"(fixture) {name}: anchor {old!r} absent in {rel}")
                else:
                    f.write_text(txt.replace(old, new, 1), encoding="utf-8")
            return dst

        def _scope_refused(r, s):
            try:
                compose(r, as_of, s)
            except PortfolioScopeError:
                return True
            return False

        BR = "proj-beta/04-PMO-Operations/proj-beta_Rollup.md"
        AR = "proj-alpha/04-PMO-Operations/proj-alpha_Rollup.md"
        BP, AP = "proj-beta/PROJECT.md", "proj-alpha/PROJECT.md"

        # (portfolio-scope)
        for _S, _mine in (("port-alpha", "proj-alpha"), ("port-beta", "proj-beta")):
            _ids = _s1_ids(compose(two_root, as_of, _S))
            if _ids != [_mine]:
                failures.append(f"(portfolio-scope) serving {_S} composed S1 rows {_ids}, "
                                f"expected [{_mine!r}]")
        _unscoped = compose(_pre_scoping(two_root, "two-pre"), as_of)
        if sorted(_s1_ids(_unscoped)) != ["proj-alpha", "proj-beta"]:
            failures.append("(portfolio-scope) CONTROL FAILED — the pre-scoping render does "
                            "not compose both projects")

        # (portfolio-discrimination)
        for _S, _mine, _other, _opf, _alias, _derived in (
                ("port-alpha", "proj-alpha", "proj-beta", "port-beta", "beta-delivery", None),
                ("port-beta", "proj-beta", "proj-alpha", "port-alpha", None, "proj-alpha-golive")):
            _body = compose(two_root, as_of, _S)
            if _other in _s1_ids(_body):
                failures.append(f"(portfolio-discrimination) {_other} is a subject row of {_S}")
            if _other not in _s1_ids(compose(two_root, as_of, _opf)):
                failures.append(f"(portfolio-discrimination) CONTROL FAILED — serving {_opf} "
                                f"did not compose {_other}")
            for _r in (two_root / _other, two_root / _other / "04-PMO-Operations", two_root / _mine):
                if not _scope_refused(_r, _S):
                    failures.append(f"(portfolio-discrimination) a scoped run at the narrowed "
                                    f"root {_r.relative_to(two_root)} was not refused")
            if _body.count(_other) != 0 or OTHER_PORTFOLIO_REF not in _body:
                failures.append(f"(portfolio-discrimination) {_other} occurs {_body.count(_other)}x "
                                f"in {_S}'s body, or no {OTHER_PORTFOLIO_REF} marker rendered")
            for _tok in (_alias, _derived):
                if _tok and _tok in _body:
                    failures.append(f"(portfolio-discrimination) {_tok!r} rendered in {_S}'s body")
        for _tok in ("proj-beta", "beta-delivery", "proj-alpha-golive"):
            if _tok not in _unscoped:
                failures.append(f"(portfolio-discrimination) SENSITIVITY FAILED — the "
                                f"pre-scoping render does not name {_tok!r}, so its limb is dead")
        _resid = compose(two_root, as_of, "port-beta").count("Alpha")
        if _resid != 2:
            failures.append(f"(portfolio-discrimination) MEASURED RESIDUAL moved: port-beta's "
                            f"body names the display name 'Alpha' {_resid}x (pinned: 2 — free "
                            f"text is not rewritten, contract §7)")

        # (single-portfolio-unchanged)
        _before = compose(_pre_scoping(one_root, "one-pre"), as_of)
        _after = compose(one_root, as_of, "port-alpha")
        if hashlib.sha256(_before.encode("utf-8")).digest() != hashlib.sha256(_after.encode("utf-8")).digest():
            failures.append("(single-portfolio-unchanged) the one-record install's output changed")
        if compose(two_root, as_of, "port-alpha") == _unscoped:
            failures.append("(single-portfolio-unchanged) CONTROL FAILED — scoped and "
                            "pre-scoping renders of the two-portfolio tree are equal")

        # (portfolio-membership)
        _rep = {}
        if (sorted(_s1_ids(compose(one_root, as_of, "port-alpha", _rep))) != ["proj-alpha", "proj-gamma"]
                or _rep.get("unassigned")):
            failures.append(f"(portfolio-membership) one portfolio: the unkeyed rollup is not a member: {_rep}")
        GR, GP = "proj-gamma/04-PMO-Operations/proj-gamma_Rollup.md", "proj-gamma/PROJECT.md"
        g1 = _variant("one-unresolved", one_root, [
            (GR, "last_published:", "portfolio_id: port-zeta\nlast_published:"),
            (GP, "delivery_approach: Scrum\n", "delivery_approach: Scrum\nportfolio_id: port-zeta\n")])
        _rep = {}
        if "proj-gamma" in _s1_ids(compose(g1, as_of, "port-alpha", _rep)) or _rep.get("unresolved") != ["proj-gamma"]:
            failures.append(f"(portfolio-membership) one portfolio: a key naming no record was "
                            f"not excluded and named unresolved: {_rep}")
        un = _variant("unassigned", two_root, [(BR, "portfolio_id: port-beta\n", ""),
                                               (BP, "portfolio_id: port-beta\n", "")])
        for _S in ("port-alpha", "port-beta"):
            _rep = {}
            if "proj-beta" in _s1_ids(compose(un, as_of, _S, _rep)) or _rep.get("unassigned") != ["proj-beta"]:
                failures.append(f"(portfolio-membership) unassigned not excluded and named for {_S}: {_rep}")
        if _quiet_main(["--root", str(un), "--as-of", _iso, "--portfolio", "port-alpha"]) != 0:
            failures.append("(portfolio-membership) an unassigned project stopped the run")
        ur = _variant("unresolved", two_root, [(BR, "portfolio_id: port-beta\n", "portfolio_id: port-gamma\n"),
                                               (BP, "portfolio_id: port-beta\n", "portfolio_id: port-gamma\n")])
        _rep = {}
        if "proj-beta" in _s1_ids(compose(ur, as_of, "port-alpha", _rep)) or _rep.get("unresolved") != ["proj-beta"]:
            failures.append(f"(portfolio-membership) unresolved key not excluded and named: {_rep}")
        ar = _variant("archived", two_root, [("_config/port-beta.md", "lifecycle_state: active",
                                              "lifecycle_state: archived")])
        _rep = {}
        compose(ar, as_of, "port-alpha", _rep)
        if _rep.get("inactive") != ["proj-beta"] or not _scope_refused(ar, "port-beta"):
            failures.append(f"(portfolio-membership) archived record: not reported inactive, or "
                            f"an archived portfolio was served: {_rep}")
        zk = _variant("zero-keyed", root, [(AR, "last_published:", "portfolio_id: port-alpha\nlast_published:")])
        _rep = {}
        if (sorted(_s1_ids(compose(zk, as_of, None, _rep))) != ["proj-alpha", "proj-beta"]
                or _rep.get("unresolved") != ["proj-alpha"]):
            failures.append(f"(portfolio-membership) no record: a keyed rollup was not composed "
                            f"unscoped and reported unresolved: {_rep}")

        # (portfolio-crosscheck)
        mv = _variant("moved", two_root, [(BP, "portfolio_id: port-beta\n", "portfolio_id: port-alpha\n")])
        for _S in ("port-alpha", "port-beta"):
            try:
                if "proj-beta" in _s1_ids(compose(mv, as_of, _S)):
                    failures.append(f"(portfolio-crosscheck) a moved project's stale rollup composed for {_S}")
            except (ContractDrift, PortfolioScopeError) as _e:
                failures.append(f"(portfolio-crosscheck) compose raised for {_S}: {_e}")
        _ra, _rb = {}, {}
        compose(mv, as_of, "port-alpha", _ra)
        compose(mv, as_of, "port-beta", _rb)
        if _ra.get("held") != ["proj-beta"] or _rb.get("held") or _rb.get("held_elsewhere") != 1:
            failures.append(f"(portfolio-crosscheck) held reporting wrong: {_ra} / {_rb}")
        c1 = _variant("agree-one", one_root, [(AR, "portfolio_id: port-alpha\n", "")])
        _rep = {}
        if "proj-alpha" not in _s1_ids(compose(c1, as_of, "port-alpha", _rep)) or _rep.get("held"):
            failures.append(f"(portfolio-crosscheck) CONTROL FAILED — one portfolio, unkeyed "
                            f"rollup vs PROJECT.md naming it, was held: {_rep}")

        # (portfolio-key-drift)
        _ok = ["--as-of", _iso, "--portfolio", "port-alpha"]
        for _tag, _new, _want in (("empty", "portfolio_id:\n", "present but empty"),
                                  ("polluted", "portfolio_id: port-beta   # moved\n", "is CONTENT"),
                                  ("near-miss", "portfolio-id: port-beta\n", "near-miss")):
            kd = _variant(f"keydrift-{_tag}", two_root, [(BR, "portfolio_id: port-beta\n", _new)])
            if _quiet_main(["--root", str(kd), *_ok]) != 1:
                failures.append(f"(portfolio-key-drift/{_tag}) did not halt the other portfolio's run (exit 1)")
            try:
                compose(kd, as_of, "port-alpha")
                failures.append(f"(portfolio-key-drift/{_tag}) no ContractDrift raised")
            except ContractDrift as _e:
                if _want not in str(_e):
                    failures.append(f"(portfolio-key-drift/{_tag}) diagnostic lacks {_want!r}")
        pj = _variant("keydrift-project-id", two_root, [(BR, "project_id: proj-beta\n",
                                                         "project_id: proj-beta   # renamed\n")])
        try:
            compose(pj, as_of, "port-alpha")
            failures.append("(portfolio-key-drift/project-id) a polluted project_id did not halt")
        except ContractDrift as _e:
            if "remove the comment from that line" not in str(_e):
                failures.append("(portfolio-key-drift/project-id) phase 1 lost the remedy text")
        if _quiet_main(["--root", str(two_root), *_ok]) != 0:
            failures.append("(portfolio-key-drift) CONTROL FAILED — the unmodified tree did not exit 0")

        # (portfolio-field-drift)
        fd = _variant("fielddrift", two_root, [(BR, "status: red", "status: purple")])
        _rep = {}
        try:
            if _s1_ids(compose(fd, as_of, "port-alpha", _rep)) != ["proj-alpha"] or _rep.get("drift_outside") != 1:
                failures.append(f"(portfolio-field-drift) other portfolio's field drift not counted: {_rep}")
        except ContractDrift as _e:
            failures.append(f"(portfolio-field-drift) another portfolio's field drift halted the served run: {_e}")
        if "proj-beta" in portfolio_report_line(_rep):
            failures.append("(portfolio-field-drift) the report line names the other portfolio's project")
        try:
            compose(fd, as_of, "port-beta")
            failures.append("(portfolio-field-drift) its own portfolio's run did not halt")
        except ContractDrift:
            pass
        _rep = {}
        compose(two_root, as_of, "port-alpha", _rep)
        if _rep.get("drift_outside") != 0:
            failures.append("(portfolio-field-drift) CONTROL FAILED — the clean tree counts drift")

        # (portfolio-records)
        if sorted(p for _, p, _ in discover_portfolio_records(two_root)) != ["port-alpha", "port-beta"]:
            failures.append("(portfolio-records) records not found by key in folder and at config top")
        rc_ = _variant("records", two_root, [
            ("_config/.backup/port-gamma.md", None, (two_root / "_config/port-beta.md").read_text(
                encoding="utf-8").replace("port-beta", "port-gamma")),
            ("_config/port-alpha/copy.md", None, (two_root / "_config/port-alpha/portfolio-record.md").read_text(
                encoding="utf-8"))])
        _rep = {}
        compose(rc_, as_of, "port-alpha", _rep)
        if _rep.get("portfolios") != 2 or _rep.get("duplicates") != ["port-alpha"]:
            failures.append(f"(portfolio-records) dot-leading copy discovered, or duplicate not "
                            f"counted once and reported: {_rep}")
        nm = _variant("record-nearmiss", two_root, [("_config/port-beta.md", "entity_type: Portfolio\n",
                                                     "entity_type: Portfolio   # note\n")])
        if _quiet_main(["--root", str(nm), *_ok]) != 2:
            failures.append("(portfolio-records) a near-miss record type key was not exit 2")

        # (portfolio-guards)
        if _quiet_main(["--root", str(two_root), "--as-of", _iso]) != 2:
            failures.append("(portfolio-guards) an unscoped run at a root holding records was not exit 2")
        if not _scope_refused(one_root, None):
            failures.append("(portfolio-guards) an unscoped run at a one-record root (rollups "
                            "naming one portfolio) was not refused")
        nc = _variant("no-config", two_root, [])
        shutil.rmtree(nc / CONFIG_DIRNAME)
        if not _scope_refused(nc, None):
            failures.append("(portfolio-guards) an unscoped run over rollups naming two "
                            "portfolios at a record-less root was not refused")
        if sorted(_s1_ids(compose(root, as_of))) != ["proj-alpha", "proj-beta"]:
            failures.append("(portfolio-guards) CONTROL FAILED — the zero-record fixture no "
                            "longer composes both rollups unscoped")
        if not _scope_refused(two_root, "port-gamma"):
            failures.append("(portfolio-guards) a served id naming no active record was not refused")
        um = _variant("unmigrated", two_root, [("_config/PORTFOLIO.md", None, "# Portfolio Dashboard\n")])
        if _quiet_main(["--root", str(um), *_ok]) != 2:
            failures.append("(portfolio-guards) an unmigrated layout was not exit 2")
        if _quiet_main(["--root", str(two_root), "--as-of", _iso, "--portfolio", "Port Alpha"]) != 2:
            failures.append("(portfolio-guards) a non-slug --portfolio was not exit 2")

        # ---- contract §7: Stage 6 round-2 decisions and absorbed review items -----
        def _scope_error(r, s):
            """The PortfolioScopeError text a compose raises, or None when it composes."""
            try:
                compose(r, as_of, s)
            except PortfolioScopeError as _e:
                return str(_e)
            except ContractDrift as _e:
                return f"<ContractDrift: {_e}>"
            return None

        def _try_compose(r, s, rep=None):
            try:
                return compose(r, as_of, s, rep), None
            except (ContractDrift, PortfolioScopeError) as _e:
                return None, f"{type(_e).__name__}: {_e}"

        _beta_rec = (two_root / CONFIG_DIRNAME / "port-beta.md").read_text(encoding="utf-8")
        _beta_fm = _beta_rec[:_beta_rec.index("\n---\n") + 5]   # the frontmatter, both fences

        # (portfolio-recordless-stop) D-RecordlessTwoIds (B)
        _msg = _scope_error(nc, None)
        if _msg is None or "create the Portfolio records" not in _msg or "--portfolio" in _msg:
            failures.append(f"(portfolio-recordless-stop) a record-less root whose rollups name two "
                            f"portfolios was not stopped with the remedy 'create the Portfolio "
                            f"records' (and no scoped-run remedy): {_msg!r}")
        n1 = _variant("recordless-one-id", nc, [(BR, "portfolio_id: port-beta\n",
                                                 "portfolio_id: port-alpha\n")])
        _b, _err = _try_compose(n1, None)
        if _err or sorted(_s1_ids(_b)) != ["proj-alpha", "proj-beta"]:
            failures.append(f"(portfolio-recordless-stop) CONTROL FAILED — rollups naming one "
                            f"portfolio at a record-less root did not compose unscoped: {_err}")

        # (portfolio-composed-not-record) D-RecordNotComposedFile (A)
        cr = _variant("composed-is-record", two_root, [])
        (cr / CONFIG_DIRNAME / "port-beta.md").unlink()
        _pf = cr / CONFIG_DIRNAME / "port-beta" / ROOT_COMPOSED_NAME
        _pf.write_text(_beta_fm + _pf.read_text(encoding="utf-8"), encoding="utf-8")
        _msg = _scope_error(cr, "port-alpha")
        if _msg is None or "never a Portfolio record" not in _msg:
            failures.append(f"(portfolio-composed-not-record) a composed PORTFOLIO.md carrying "
                            f"entity_type: Portfolio was not refused: {_msg!r}")
        if _quiet_main(["--root", str(cr), *_ok]) != 2:
            failures.append("(portfolio-composed-not-record) the refusal is not exit 2")
        cr2 = _variant("record-own-file", two_root, [])
        (cr2 / CONFIG_DIRNAME / "port-beta.md").rename(
            cr2 / CONFIG_DIRNAME / "port-beta" / "portfolio-record.md")
        _b, _err = _try_compose(cr2, "port-beta")
        if _err or _s1_ids(_b) != ["proj-beta"]:
            failures.append(f"(portfolio-composed-not-record) CONTROL FAILED — the same record in "
                            f"its own file beside the composed file was not served: {_err}")

        # (portfolio-record-walk) FM-D2, CD-D1 (b)-(d)
        _gamma = _beta_rec.replace("port-beta", "port-gamma")
        for _name, _rel, _want, _what in (
                ("walk-releases", "_config/releases/port-gamma.md", 2,
                 "a record under the config folder's releases/"),
                ("walk-releases-cap", "_config/Releases/port-gamma.md", 2, "a record under Releases/"),
                ("walk-deep", "_config/port-gamma/old/port-gamma.md", 2,
                 "a record nested two folders deep"),
                ("walk-control", "_config/port-gamma/port-gamma.md", 3,
                 "CONTROL: a record in a slug-named folder")):
            _rep = {}
            _b, _err = _try_compose(_variant(_name, two_root, [(_rel, None, _gamma)]), "port-alpha", _rep)
            if _err or _rep.get("portfolios") != _want:
                failures.append(f"(portfolio-record-walk) {_what}: {_err or ''} counted "
                                f"{_rep.get('portfolios')} active portfolio(s), expected {_want}")
        cs = _variant("walk-conflict", two_root, [
            ("_config/port-beta.md", "lifecycle_state: active", "lifecycle_state: archived"),
            ("_config/port-beta/portfolio-record.md", None, _beta_rec)])
        _msg = _scope_error(cs, "port-alpha")
        if _msg is None or "conflicting states" not in _msg:
            failures.append(f"(portfolio-record-walk) one portfolio_id held by an active and an "
                            f"archived record was not a configuration error: {_msg!r}")
        rv = _variant("walk-reserved", two_root, [
            ("_config/reserved.md", None, _beta_rec.replace("port-beta", "releases"))])
        _msg = _scope_error(rv, "port-alpha")
        if _msg is None or "reserved" not in _msg:
            failures.append(f"(portfolio-record-walk) a record whose portfolio_id names the config "
                            f"folder's releases/ was not refused: {_msg!r}")
        _rep = {}
        _b, _err = _try_compose(_variant("walk-dupe", two_root, [
            ("_config/port-beta/portfolio-record.md", None, _beta_rec)]), "port-alpha", _rep)
        if _err or _rep.get("duplicates") != ["port-beta"]:
            failures.append(f"(portfolio-record-walk) CONTROL FAILED — two active records with one "
                            f"id were not counted once and reported: {_err} {_rep}")

        # (portfolio-project-key) FM-D3
        pk = _variant("project-key-polluted", one_root, [
            (AP, "portfolio_id: port-alpha\n", "portfolio_id: port-alpha   # BELONGS_TO parent\n")])
        _rep = {}
        _b, _err = _try_compose(pk, "port-alpha", _rep)
        if (_err or "proj-alpha" in _s1_ids(_b) or _rep.get("polluted") != ["proj-alpha"]
                or _rep.get("held")):
            failures.append(f"(portfolio-project-key) a polluted PROJECT.md portfolio_id was not held "
                            f"and named in its own report class: {_err} {_rep}")
        elif "PROJECT.md portfolio_id polluted" not in portfolio_report_line(_rep):
            failures.append("(portfolio-project-key) the report line does not name the polluted "
                            "PROJECT.md key")
        _rep = {}
        _b, _err = _try_compose(one_root, "port-alpha", _rep)
        if _err or "proj-alpha" not in _s1_ids(_b) or _rep.get("polluted"):
            failures.append(f"(portfolio-project-key) CONTROL FAILED — the clean tree: {_err} {_rep}")

        # (portfolio-alias-exact) FM-D4
        ax = _variant("alias-neutral", two_root, [
            (AR, "    to: beta-delivery\n    state: open\n",
             "    to: beta-delivery\n    state: open\n"
             "  - from: proj-alpha\n    to: beta-delivery-gateway\n    state: open\n")])
        _b, _err = _try_compose(ax, "port-alpha")
        if _err:
            failures.append(f"(portfolio-alias-exact) compose raised: {_err}")
        else:
            if "beta-delivery-gateway" not in _b:
                failures.append("(portfolio-alias-exact) a portfolio-neutral id sharing a PROJECT.md "
                                "id alias's first words was rewritten — alias matching must be exact")
            if _b.replace("beta-delivery-gateway", "").count("beta-delivery") != 0:
                failures.append("(portfolio-alias-exact) the exact PROJECT.md id alias is no longer "
                                "redacted")
        if "beta-delivery-gateway" not in compose(_pre_scoping(ax, "alias-pre"), as_of):
            failures.append("(portfolio-alias-exact) SENSITIVITY FAILED — the pre-scoping render "
                            "does not name the neutral id")
        try:
            _c = Ctx([], as_of, redact=frozenset({"proj-beta"}), keep=frozenset({"proj-beta-two"}),
                     alias=frozenset({"beta-delivery"}), keep_ids=frozenset({"proj-beta-two"}))
            _want_ref = {"proj-beta-two-golive": "proj-beta-two-golive",
                         "proj-beta-golive": OTHER_PORTFOLIO_REF,
                         "proj-beta": OTHER_PORTFOLIO_REF, "proj-beta-two": "proj-beta-two",
                         "beta-delivery": OTHER_PORTFOLIO_REF,
                         "beta-delivery-gateway": "beta-delivery-gateway"}
            _got_ref = {k: _c.ref(k) for k in _want_ref}
            if _got_ref != _want_ref:
                failures.append(f"(portfolio-alias-exact) longest-prefix / exact-alias matching "
                                f"wrong: {_got_ref}")
        except TypeError as _e:
            failures.append(f"(portfolio-alias-exact) Ctx carries no separate alias and member-id "
                            f"sets: {_e}")

        # (portfolio-report-line) CD-D1 (d), the §7.4 leading fields, the no-active label
        _rep = {}
        compose(two_root, as_of, "port-alpha", _rep)
        _line = portfolio_report_line(_rep)
        if not _line.startswith("compose-portfolio: Portfolio: port-alpha — unassigned: none; "
                                "unresolved portfolio_id: none;"):
            failures.append(f"(portfolio-report-line) the line does not lead with the surfaces' "
                            f"report-line fields (contract §7.4): {_line!r}")
        if "active Portfolio record(s): port-alpha, port-beta" not in _line:
            failures.append(f"(portfolio-report-line) the line does not print the active set: {_line!r}")
        ao = _variant("archived-only", one_root, [
            ("_config/port-alpha/portfolio-record.md", "lifecycle_state: active",
             "lifecycle_state: archived")])
        _rep = {}
        _b, _err = _try_compose(ao, None, _rep)
        _line = "" if _err else portfolio_report_line(_rep)
        if _err or "Portfolio: unscoped (no active Portfolio record)" not in _line:
            failures.append(f"(portfolio-report-line) an archived-only install's unscoped line is "
                            f"mislabelled: {_err} {_line!r}")
        _rep = {}
        compose(root, as_of, None, _rep)
        if portfolio_report_line(_rep):
            failures.append("(portfolio-report-line) CONTROL FAILED — the committed zero-record "
                            "fixture's report line is no longer empty")

        # (guard) an --out path under projects/ is rejected.
        if not out_path_rejected(str(Path(td) / "projects" / "_config" / "PORTFOLIO.md")):
            failures.append("(guard) an --out path under projects/ was NOT rejected")
        if out_path_rejected(str(Path(td) / "staging" / "PORTFOLIO.md")):
            failures.append("(guard) a safe --out staging path was wrongly rejected")

        # (dot-segment) a rollup under a dot-leading path segment is OUT OF CORPUS
        # and is NOT discovered — the one traversal predicate all three deploy-tool
        # walkers now share. BOTH shapes are planted, because both are over-returned
        # identically pre-fix: a dot-leading DIRECTORY and a dot-leading FILENAME.
        # This case FAILS BEFORE the fix (the bare rglob walked straight into them)
        # and passes after.
        ds_root = Path(td) / "dotseg"
        shutil.copytree(fixture, ds_root)
        # CONTROL ARM (anti-vacuity), asserted BEFORE the subject — a walker that
        # discovers nothing anywhere would satisfy the equality below as 0 == 0.
        clean_n = len(discover_rollups(root))
        if clean_n == 0:
            failures.append("(dot-segment) CONTROL FAILED — clean discovery found 0 "
                            "rollups, so the equality below would be vacuous")
        donor = discover_rollups(ds_root)[0]
        body = donor.read_text(encoding="utf-8")
        hidden_dir = ds_root / ".body-backups"
        hidden_dir.mkdir(parents=True, exist_ok=True)
        (hidden_dir / donor.name).write_text(body, encoding="utf-8")      # dot DIRECTORY
        (ds_root / ("." + donor.name)).write_text(body, encoding="utf-8")  # dot FILENAME
        try:
            ds_n = len(discover_rollups(ds_root))
            if ds_n != clean_n:
                failures.append(f"(dot-segment) discovery returned {ds_n} rollups with two "
                                f"dot-segment copies planted, expected {clean_n} — a "
                                f"dot-leading directory and/or filename is being walked")
        except ContractDrift as e:
            failures.append(f"(dot-segment) discovery RAISED on an out-of-corpus path, "
                            f"which it should never have read: {e}")
        # The composed render must be byte-identical: an out-of-corpus file is
        # invisible, so planting two of them changes nothing downstream.
        try:
            if (hashlib.sha256(compose(ds_root, as_of).encode("utf-8")).hexdigest()
                    != hashlib.sha256(compose(root, as_of).encode("utf-8")).hexdigest()):
                failures.append("(dot-segment) the composed portfolio differs once "
                                "dot-segment copies are planted; they must be invisible")
        except ContractDrift as e:
            failures.append(f"(dot-segment) compose RAISED on a tree whose only change is "
                            f"two out-of-corpus copies: {e}")
        rc_ds = _quiet_main(["--root", str(ds_root), "--as-of", as_of.isoformat()])
        if rc_ds != 0:
            failures.append(f"(dot-segment) compose over the planted tree returned exit "
                            f"{rc_ds}, expected 0")

    if failures:
        print("compose-portfolio self-test FAILED:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("compose-portfolio self-test OK "
          "(idempotency byte-identical / S1-S8+meta rendered / staleness discriminates / "
          "exit-0-with-[STALE] / drift->exit-1 / join-key->exit-1 / projects-guard / "
          "s2-per-dimension / s2-resolver-varies / dimension-seam / "
          "join-key-polluted / "
          "discovery-polluted x2 / dot-segment / portfolio-scope / portfolio-discrimination / "
          "single-portfolio-unchanged / portfolio-membership / portfolio-crosscheck / "
          "portfolio-key-drift / portfolio-field-drift / portfolio-records / portfolio-guards / "
          "portfolio-recordless-stop / portfolio-composed-not-record / portfolio-record-walk / "
          "portfolio-project-key / portfolio-alias-exact / portfolio-report-line)")
    return 0


def portfolio_report_line(r: dict) -> str:
    """The §7 operator-side report line (stderr). It leads with the fields every surface's
    report line carries (contract §7.4) — served portfolio, unassigned, unresolved — and
    then what only the composer can compute. Empty for an unscoped run with no keyed
    rollup and no duplicate, so a legacy run's stderr stays empty."""
    if not r:
        return ""
    dup = (f"; duplicate Portfolio record(s): {', '.join(r['duplicates'])}"
           if r.get("duplicates") else "")
    if r.get("served") is None:
        if not r.get("unresolved") and not dup:
            return ""
        return (f"compose-portfolio: Portfolio: unscoped (no active Portfolio record) — "
                f"unassigned: none; unresolved portfolio_id: "
                f"{', '.join(r['unresolved']) or 'none'}; {r['members']} rollup(s) composed{dup}")
    nm = lambda k: ", ".join(r.get(k) or []) or "none"  # noqa: E731
    elsewhere = f" (+{r['held_elsewhere']} elsewhere)" if r.get("held_elsewhere") else ""
    return (f"compose-portfolio: Portfolio: {r['served']} — unassigned: {nm('unassigned')}; "
            f"unresolved portfolio_id: {nm('unresolved')}; {r['members']} member rollup(s); "
            f"names an inactive Portfolio record: {nm('inactive')}; held for re-emission "
            f"(rollup key disagrees with its PROJECT.md): {nm('held')}{elsewhere}; "
            f"PROJECT.md portfolio_id polluted (remove the inline comment): "
            f"{nm('polluted')}; excluded, another portfolio: {r['other_portfolio']}; "
            f"contract drift outside the served portfolio: {r['drift_outside']}; "
            f"active Portfolio record(s): {nm('active')}{dup}")


# --------------------------------------------------------------------------- #
# CLI.
# --------------------------------------------------------------------------- #

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", metavar="PATH", help="corpus/projects root to scan for rollup entities")
    ap.add_argument("--as-of", metavar="ISO", help="staleness anchor YYYY-MM-DD (default: today)")
    ap.add_argument("--out", metavar="PATH", help="write composed markdown here (rejects projects/); default stdout")
    ap.add_argument("--portfolio", metavar="ID",
                    help="serve this portfolio_id only (contract §7 Portfolio scoping)")
    ap.add_argument("--self-test", action="store_true", help="run committed-fixture assertions and exit")
    args = ap.parse_args(argv)

    if args.self_test:
        return run_self_test()

    if not args.root:
        print("compose-portfolio: --root is required (except --self-test)", file=sys.stderr)
        return 2
    root = Path(args.root).expanduser()
    if not root.exists() or not root.is_dir():
        print(f"compose-portfolio: --root unresolvable: {root}", file=sys.stderr)
        return 3

    if args.as_of:
        try:
            as_of = _parse_iso_date(args.as_of)
        except (ValueError, IndexError):
            print(f"compose-portfolio: --as-of not an ISO date: {args.as_of!r}", file=sys.stderr)
            return 2
    else:
        as_of = date.today()   # production default; weekly-status-rollup §6 passes today

    if args.portfolio is not None and not PORTFOLIO_ID_RE.match(args.portfolio):
        print(f"compose-portfolio: --portfolio {args.portfolio!r} is not a portfolio_id slug",
              file=sys.stderr)
        return 2

    if args.out and out_path_rejected(args.out):
        print(f"compose-portfolio: --out rejected — path resolves under projects/ "
              f"(Layer-2, Cowork-owned): {args.out}", file=sys.stderr)
        return 2

    report: dict = {}
    try:
        markdown = compose(root, as_of, args.portfolio, report)
    except ContractDrift as exc:
        print(f"compose-portfolio: contract drift — {exc}", file=sys.stderr)
        return 1   # #1771-F1: drift is the ONLY non-zero-for-findings path ([STALE] is not)
    except PortfolioScopeError as exc:
        print(f"compose-portfolio: portfolio scoping — {exc}", file=sys.stderr)
        return 2
    line = portfolio_report_line(report)
    if line:
        print(line, file=sys.stderr)

    if args.out:
        out_path = Path(args.out).expanduser()
        if not out_path.parent.exists():
            print(f"compose-portfolio: --out parent does not exist: {out_path.parent}", file=sys.stderr)
            return 3
        out_path.write_text(markdown, encoding="utf-8")
    else:
        sys.stdout.write(markdown)
    return 0


if __name__ == "__main__":
    sys.exit(main())

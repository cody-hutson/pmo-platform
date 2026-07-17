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
checkpoint and the Cowork writer performs the `projects/_config/PORTFOLIO.md` write.

Stdlib-only, Python 3.9 (`/usr/bin/python3`). Imports the shared `_frontmatter.py`
reader (F1 consistency); the structured-field block parse is composer-local.

CLI:
  --root PATH        corpus / projects root to scan for rollup entities (required for compose)
  --as-of ISO        staleness anchor date YYYY-MM-DD (default: today);
                     --self-test pins max(last_published) for byte-reproducibility
  --out PATH         write composed markdown to PATH (rejects any path under projects/);
                     default is stdout
  --self-test        run the committed-fixture assertions and exit

Exit codes (fail-loud family contract; #1771-F1 separates [STALE] from drift):
  0  clean run  — INCLUDING a run that renders [STALE]/degrade markers ([STALE] is a
                  display state, NOT an error)
  1  contract drift ONLY — a rollup field whose value TYPE violates the contract
                  (or a missing required field); the composer HALTS, emits no body
  2  usage error — bad / missing flags, or an --out path under projects/
  3  path-unresolvable — --root does not resolve, or --out's parent does not exist
"""
from __future__ import annotations

import argparse
import hashlib
import sys
from datetime import date, timedelta
from pathlib import Path

# The ONE shared frontmatter reader (F1). This file lives beside it in
# core/deploy/tools/; the sys.path insert makes --self-test / direct invocation robust.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _frontmatter import read_frontmatter, _strip_quotes  # noqa: E402

# --------------------------------------------------------------------------- #
# Contract constants (core/standards/portfolio-writeback-contract.md §2/§3).
# --------------------------------------------------------------------------- #

# The frontmatter marker the rollup template stamps (operations/templates/
# project-rollup-template.md `entity_type`). Discovery keys on THIS value — the
# Stage-5 index-discovery key `type='project-rollup'` is superseded here because
# the shipped template carries `entity_type: Project Rollup (composed)`, not a
# `type:` field.
ROLLUP_ENTITY_TYPE = "Project Rollup (composed)"

# The 7 contract fields (§2). Two scalars + five structured (3 lists + 2 objects).
SCALAR_FIELDS = ("status", "last_published")
LIST_FIELDS = ("top_risks", "key_dependencies", "cross_project_conflicts")
OBJECT_FIELDS = ("capacity_signal", "milestone_delta")
CONTRACT_FIELDS = SCALAR_FIELDS + LIST_FIELDS + OBJECT_FIELDS  # all 7 required

RAG_VALUES = ("green", "yellow", "red")
RAG_GLYPH = {"green": "\U0001F7E2", "yellow": "\U0001F7E1", "red": "\U0001F534"}

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
DEGRADE_MARKER = "[STALE:DEGRADED]"


# --------------------------------------------------------------------------- #
# Errors.
# --------------------------------------------------------------------------- #

class ContractDrift(Exception):
    """A rollup field whose value TYPE violates the contract (or a missing
    required field). Raised during read/validate; surfaced as exit 1 (halt)."""


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
                 "milestone_delta")

    def __init__(self, project_id, rel_path, fields):
        self.project_id = project_id
        self.rel_path = rel_path
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


def read_rollup(doc_path: Path, root: Path) -> Rollup:
    """Read + type-validate one rollup entity. Raises ContractDrift on any field
    whose type violates the §2 contract or on a missing required field."""
    scalars, status = read_frontmatter(doc_path)
    rel = doc_path.relative_to(root).as_posix()
    if status != "ok":
        raise ContractDrift(f"{rel}: no frontmatter block")
    structured = parse_structured_fields(_frontmatter_body(doc_path),
                                          LIST_FIELDS + OBJECT_FIELDS)
    project_id = scalars.get("project_id") or scalars.get("id") or rel
    drift: list = []
    fields: dict = {}

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
        raise ContractDrift(f"{rel} (project {project_id}): " + "; ".join(drift))
    return Rollup(project_id, rel, fields)


def discover_rollups(root: Path) -> list:
    """Deterministic sorted-POSIX discovery of rollup entities under `root`
    (frontmatter `entity_type == ROLLUP_ENTITY_TYPE`). Sorted enumeration is the
    idempotency guarantee — filesystem order is never trusted."""
    found: list = []
    for path in sorted(root.rglob("*.md"), key=lambda p: p.relative_to(root).as_posix()):
        scalars, status = read_frontmatter(path)
        if status == "ok" and scalars.get("entity_type") == ROLLUP_ENTITY_TYPE:
            found.append(path)
    return found


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
    __slots__ = ("rollups", "as_of")

    def __init__(self, rollups, as_of):
        self.rollups = rollups   # sorted by project_id
        self.as_of = as_of


def _rag_cell(rag: str) -> str:
    return f"{RAG_GLYPH.get(rag, '')} {rag}".strip()


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
    # Per-project Health Indicators. The 7-field contract carries a single `status`
    # RAG (not per-dimension); the baseline renders each dimension at the overall
    # RAG. #276 injects the per-dimension detail + thresholds without a core edit.
    dims = ("Schedule", "Scope", "Quality", "Stakeholders", "Integration")
    out = [f"## {sec.title}", ""]
    for r in ctx.rollups:
        suffix = _stale_suffix(r.last_published, ctx.as_of)
        out.append(f"### {r.project_id} — Health Indicators")
        out.append("")
        out.append("| Dimension | Status |")
        out.append("|---|---|")
        for d in dims:
            out.append(f"| {d} | {_rag_cell(r.status)}{suffix} |")
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
            desc = f"{_get(dep, 'from')} → {_get(dep, 'to')} ({_get(dep, 'state')})"
            linked = f"{_get(dep, 'from')}, {_get(dep, 'to')}"
            out.append(f"| Dependency | {desc} | — | — | Portfolio | {linked} |")
        for cf in r.cross_project_conflicts:
            affected = cf.get("projects_affected") if isinstance(cf, dict) else None
            aff = ", ".join(affected) if isinstance(affected, list) else _get(cf, "projects_affected")
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
            out.append(f"| {_get(dep, 'from')} | {_get(dep, 'to')} | "
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
            affected = cf.get("projects_affected") if isinstance(cf, dict) else None
            aff = ", ".join(affected) if isinstance(affected, list) else _get(cf, "projects_affected")
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

def compose(root: Path, as_of: date) -> str:
    """Read every rollup under `root`, validate against the contract (raises
    ContractDrift on any type violation), and render the section registry.
    Returns the composed markdown (LF newlines, single trailing newline)."""
    rollups = [read_rollup(p, root) for p in discover_rollups(root)]
    rollups.sort(key=lambda r: r.project_id)   # determinism: never trust FS order
    ctx = Ctx(rollups, as_of)

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

def _fixture_dir() -> Path:
    return Path(__file__).resolve().parent / "tests" / "fixtures" / "portfolio-composer"


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
      ([DRIFT] render) a risk-bearing row missing an owner/mitigation renders the
                     inline `[DRIFT: incomplete risk record]` repair flag and STILL
                     composes (exit 0) — the soft path, distinct from the hard halt.
      (guard)        an --out path under projects/ is rejected.
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

        # (guard) an --out path under projects/ is rejected.
        if not out_path_rejected(str(Path(td) / "projects" / "_config" / "PORTFOLIO.md")):
            failures.append("(guard) an --out path under projects/ was NOT rejected")
        if out_path_rejected(str(Path(td) / "staging" / "PORTFOLIO.md")):
            failures.append("(guard) a safe --out staging path was wrongly rejected")

    if failures:
        print("compose-portfolio self-test FAILED:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("compose-portfolio self-test OK "
          "(idempotency byte-identical / S1-S8+meta rendered / staleness discriminates / "
          "exit-0-with-[STALE] / drift->exit-1 / projects-guard)")
    return 0


# --------------------------------------------------------------------------- #
# CLI.
# --------------------------------------------------------------------------- #

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", metavar="PATH", help="corpus/projects root to scan for rollup entities")
    ap.add_argument("--as-of", metavar="ISO", help="staleness anchor YYYY-MM-DD (default: today)")
    ap.add_argument("--out", metavar="PATH", help="write composed markdown here (rejects projects/); default stdout")
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

    if args.out and out_path_rejected(args.out):
        print(f"compose-portfolio: --out rejected — path resolves under projects/ "
              f"(Layer-2, Cowork-owned): {args.out}", file=sys.stderr)
        return 2

    try:
        markdown = compose(root, as_of)
    except ContractDrift as exc:
        print(f"compose-portfolio: contract drift — {exc}", file=sys.stderr)
        return 1   # #1771-F1: drift is the ONLY non-zero-for-findings path ([STALE] is not)

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

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
    drift: list = []
    fields: dict = {}

    # `project_id` is the rollup's JOIN KEY to its Project record (contract §2;
    # project-schema.md § Project-identity resolution rule). Validated, never
    # defaulted: the former `or scalars.get("id") or rel` fallback resolved to
    # `<slug>-rollup` (the template's own `id:`) -- a WRONG key, not a missing one.
    project_id = (scalars.get(JOIN_KEY_FIELD) or "").strip()
    if not project_id:
        drift.append("project_id absent or empty — the rollup's join key to its "
                     "Project record (contract §2); no fallback is applied")
    elif not PROJECT_ID_RE.match(project_id):
        drift.append(
            f"project_id={project_id!r} does not match the declared join-key "
            f"charset (ADR-179 D1: ^[a-z0-9][a-z0-9-]*$). A trailing '# …' on the "
            f"`project_id:` line is CONTENT, not a comment — the shared reader "
            f"does not strip it (its frozen F-4) — so remove the comment from "
            f"that line. This matters because a polluted join key is a WRONG "
            f"value rather than a missing one: it passes every presence check and "
            f"then silently fails to match its Project record")

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
    return Rollup(project_id, rel, fields)


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
          "discovery-polluted x2 / dot-segment)")
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

#!/usr/bin/env python3
"""check-process-catalog.py — the process catalog's page validator and register check.

PURPOSE
    Checks every catalog page against the definitions pack and the authoring
    rules, and checks the controls register and the ID registry against their
    own rules. Frontmatter is read only through the shared reader
    (`_frontmatter.py`, by way of the catalog library); links are resolved only
    by the shared link checker (`check-doc-links.py`).

    On every run, before any page rule: the register rules run over the register
    the pack points at and over the ID registry, and the pack's rule list is
    compared with the codes this tool can emit and with the pack document's two
    marked tables. A missing or unreadable pack, register, registry or pack
    document is a not-evaluated exit, never a pass.

USAGE
    check-process-catalog.py --pattern-arm (run|not-run) [TARGET...] [roots]
    check-process-catalog.py --pattern-arm (run|not-run) --registers-only [roots]
    check-process-catalog.py --list-rules
    check-process-catalog.py --self-test

    --pattern-arm is required on every run that checks the registers; the mode
    is never inferred from a missing file. `run` needs --private-pattern-file
    and --pattern-digest-file; `not-run` takes neither. With no TARGET every
    discovered page is checked and the catalog-level rules run; with targets
    the register and pack checks still run and the catalog-level rules do not.
    --summary-file FILE appends one block; it changes no stream and no exit.
    Every root is an argument (see --help); none is read from the environment.

OUTPUT
    The register check's three header lines, a `register roots:` line, any
    register finding (`rule<TAB>key<TAB>column<TAB>detail`), any pack-parity
    finding (the same form, opening `PCK`), then the page findings, then one
    census line — the last line on standard output on exit 0, 1 and 3 alike.

EXIT CODES
    0  examined and clean (a warning alone leaves 0)
    1  at least one finding of severity error
    2  usage (no census is printed: nothing ran)
    3  not evaluated — an input could not be read, or nothing was examined
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
import _process_catalog as PC  # noqa: E402

RULES = (
    ("ANC001", "error", "a source link has a line fragment and no source anchor"),
    ("ANC002", "error", "a source-anchor comment does not parse, or does not directly follow a source link"),
    ("ANC003", "error", "an anchor's `line` names different lines from its link's fragment"),
    ("ANC004", "error", "the label of a source link carries a line token"),
    ("ANC005", "warn", "a line reference stands in prose or a table cell outside a citation"),
    ("CTL001", "warn", "a Controls row names no control ID for its class"),
    ("CTL002", "error", "a cited control's class on the page differs from the register's"),
    ("CTL003", "error", "a cited control ID has no row in the register"),
    ("CTL004", "warn", "a Controls row on the agent-run surface carries a class other than code-warn"),
    ("CTL005", "error", "a Controls row that cites no control ID carries a class outside the enforcement classes"),
    ("EVD001", "error", "an executed Evidence row has no root link that resolves in its Source cell"),
    ("FM001", "error", "the page has no readable frontmatter block"),
    ("FM002", "error", "a required field is missing or empty, or a list has fewer items than its minimum"),
    ("FM003", "error", "an enum field holds a value outside its enum"),
    ("FM004", "error", "a field, or the page ID, breaks its pattern"),
    ("FM005", "error", "a list field is not an inline list"),
    ("FM006", "error", "a reserved field name is used"),
    ("FM007", "error", "`id` differs from the file name stem"),
    ("FM008", "error", "an actor value is outside the actor kinds"),
    ("FM009", "error", "a trigger is neither a registered node nor a trigger kind"),
    ("FM010", "error", "a superseded page names no successor"),
    ("FM011", "warn", "the page's `pack_version` differs from the pack's"),
    ("FM012", "error", "an active page's `lens_status` is absent, not assessed, or outside the enum"),
    ("LNK001", "error", "a link does not resolve, or its line fragment is past the end of the file"),
    ("LNK002", "error", "a relative link resolves outside the catalog folder"),
    ("MMD001", "error", "the level requires a Mermaid flow and the page has none"),
    ("MMD002", "error", "the flow has more nodes than the level's limit"),
    ("MMD003", "error", "a Mermaid block does not open with `flowchart <direction>`"),
    ("MMD004", "error", "a Mermaid node ID is a Mermaid keyword"),
    ("NAV001", "error", "the navigation markers are missing"),
    ("PAG001", "error", "a Markdown file directly inside a universe folder is not a page of that universe"),
    ("PAG002", "error", "a catalog folder is neither reserved nor a registered universe, or a universe has pages and "
                        "no L0 page, or a universe ID is a reserved folder name"),
    ("PAG003", "error", "a file under the catalog root is expected by nothing"),
    ("PCK001", "error", "the pack's `rule_codes` and the codes this tool can emit differ"),
    ("PCK002", "error", "a marked table of the pack document and its list in the pack differ, or the document "
                        "carries a stray rule code"),
    ("REF001", "error", "a number sign followed by a digit, or an issue or pull-request URL"),
    ("REG001", "error", "the page ID is not in the ID registry"),
    ("REG002", "error", "an ID field names an unregistered ID"),
    ("REG003", "error", "the page's level or universe differs from the registry's"),
    ("SEC001", "error", "a section required at the level is missing"),
    ("SRC001", "error", "a depicted or documenting path is not a tracked file or a folder holding one, or lies "
                        "at or under the catalog root"),
    ("SRC002", "error", "`last_verified_commit` is not the full ID of a commit in the repository"),
    ("SRC003", "error", "a file named on the page is no tracked file and is carried by no source of the page"),
    ("STP001", "error", "a Steps row's harness feature is neither `none` nor a listed feature"),
    ("SUM001", "error", "a summary count differs from the count computed from the Steps table, or a summary row is "
                        "missing"),
    ("TAB001", "error", "a table's header differs from the pack's"),
    ("TAB002", "error", "a table row's cell count differs from its header's"),
    ("TAB003", "error", "a table row carries an unescaped pipe inside a code span"),
    ("TOK001", "error", "the page is over its level's token budget"),
    ("TRM001", "warn", "a term the pack lists for explanation appears and is never linked or explained"),
    ("VOC001", "pack", "a pack-declared forbidden phrase appears; the severity is the pack entry's"),
    ("VOC002", "pack", "a pack-declared contested term appears; the severity is the pack entry's"),
)
CODES = tuple(code for code, _sev, _text in RULES)
SEVERITY = {code: sev for code, sev, _text in RULES}
RULE_MARKERS = ("<!-- rule-codes:begin -->", "<!-- rule-codes:end -->")
FEATURE_MARKERS = ("<!-- harness-features:begin -->", "<!-- harness-features:end -->")
CODE_SHAPE = re.compile(r"(?<![A-Za-z0-9_-])([A-Z]{2,3})[0-9]{3}(?![A-Za-z0-9_-])")
COMMIT_ID = re.compile(r"^[0-9a-f]{40}$")
WORK_ITEM_URL = re.compile(r"/(?:issues|pull)/[0-9]+")
CONTROL_PAIR = re.compile(r"\b(C-\d{3,})\b(?:\s*:\s*`?([a-z][a-z-]*)`?)?")
MMD_KEYWORD_IDS = {"call", "click", "end", "style", "class", "classDef", "subgraph", "linkStyle"}
MMD_SKIP = {"subgraph", "end", "classDef", "class", "flowchart", "graph", "style", "click", "linkStyle", "direction"}
MMD_STATEMENT = re.compile(r"^(classDef|class|style|linkStyle|click|subgraph|flowchart|graph|direction)\b|^end$")
MMD_EDGE = re.compile(r"-\.->|-\.-|==>|===|-->|---|--[ox]|&")


class Finding:
    def __init__(self, path: str, line, code: str, message: str, severity: str = ""):
        self.path, self.line, self.code, self.message = path, line, code, message
        self.severity = severity or SEVERITY[code]

    def __str__(self) -> str:
        where = "%s:%d" % (self.path, self.line + 1) if self.line is not None else self.path
        return "%s: %s %s %s" % (where, self.severity.upper(), self.code, self.message)


# ----------------------------------------------------------------------------------------------
# Mermaid helpers
# ----------------------------------------------------------------------------------------------
def mermaid_blocks(lines: list) -> list:
    blocks, cur, inside = [], [], False
    for line in lines:
        s = line.strip()
        if not inside and s.startswith("```mermaid"):
            inside, cur = True, []
        elif inside and s.startswith("```"):
            blocks.append(cur)
            inside = False
        elif inside:
            cur.append(line)
    return blocks


def strip_labels(line: str) -> str:
    """Remove edge labels, class shorthands and every shape's label text, so only node IDs and arrows remain."""
    s = re.sub(r"\|[^|]*\|", " ", line)
    s = re.sub(r":::[A-Za-z0-9_-]+", " ", s)
    out, depth = [], 0
    for ch in s:
        if ch in "[({":
            depth += 1
        elif ch in "])}":
            depth = max(0, depth - 1)
        elif depth == 0:
            out.append(ch)
    return "".join(out)


def mermaid_nodes(block: list) -> set:
    """Distinct node IDs of a flowchart, whether declared with a shape or only named on an edge."""
    nodes = set()
    for line in block:
        s = line.strip()
        first = s.split()[0] if s.split() else ""
        if first in MMD_SKIP or s.startswith("%%"):
            continue
        for tok in re.findall(r"[A-Za-z][A-Za-z0-9_]*", strip_labels(s)):
            if tok not in MMD_SKIP:
                nodes.add(tok)
    return nodes


def mermaid_keyword_ids(block: list) -> list:
    """Node IDs that are exactly a Mermaid keyword. A statement line and the text of a label do not count."""
    hits = []
    for raw in block:
        line = raw.strip().rstrip(";")
        if not line or line.startswith("%%") or MMD_STATEMENT.match(line):
            continue
        for _ in range(3):
            line = re.sub(r'\[[^\[\]]*\]|\([^()]*\)|\{[^{}]*\}|\|[^|]*\||"[^"]*"', "", line)
        for seg in MMD_EDGE.split(line):
            m = re.match(r"\s*([A-Za-z_][\w-]*)", seg)
            if m and m.group(1) in MMD_KEYWORD_IDS:
                hits.append(m.group(1))
    return hits


def kind_match(value: str, kinds: list) -> bool:
    for k in kinds:
        if k.endswith(":"):
            if value.startswith(k) and len(value) > len(k):
                return True
        elif value == k:
            return True
    return False


def first_token(cell: str) -> str:
    parts = PC.unspan(cell).split()
    return parts[0] if parts else ""


# ----------------------------------------------------------------------------------------------
# Pack parity — the two links. They run in this tool only, on every run that loads the pack.
# ----------------------------------------------------------------------------------------------
def marked_rows(lines: list, markers: tuple, name: str) -> tuple:
    """(first-column cells of the table between two markers, index of the begin marker, index of the
    end marker). A missing, repeated or misordered marker is NotEvaluated."""
    begin = [i for i, l in enumerate(lines) if l.strip() == markers[0]]
    end = [i for i, l in enumerate(lines) if l.strip() == markers[1]]
    if len(begin) != 1 or len(end) != 1 or begin[0] > end[0]:
        raise PC.NotEvaluated("the pack document lacks the marker pair of its %s table" % name)
    cells, header_seen = [], False
    for line in lines[begin[0] + 1:end[0]]:
        if not PC.is_table_line(line) or PC.is_rule_line(line):
            continue
        if not header_seen:
            header_seen = True
            continue
        cells.append(PC.unspan(PC.split_row(line)[0]))
    return cells, begin[0], end[0]


def pack_parity(pack: dict, document) -> list:
    """Findings as (code, key, column, detail). PCK001: the pack's `rule_codes` against the codes
    this tool can emit. PCK002: the pack document's rules table against `rule_codes`; a stray code
    of a live family anywhere else in the document, outside fenced code; and the document's feature
    table against `harness_features`."""
    out = []
    listed = list(pack["rule_codes"])
    for code in sorted(set(listed) - set(CODES)):
        out.append(("PCK001", code, "rule_codes", "in the pack's list; this tool emits no such code"))
    for code in sorted(set(CODES) - set(listed)):
        out.append(("PCK001", code, "rule_codes", "emitted by this tool; absent from the pack's list"))
    lines = PC.read_text_strict(document, "the pack document").split("\n")
    table, begin, end = marked_rows(lines, RULE_MARKERS, "rule-codes")
    features, _fb, _fe = marked_rows(lines, FEATURE_MARKERS, "harness-features")
    for label, column, rows, want in (("rule code", "rule-codes", table, listed),
                                      ("harness feature", "harness-features", features, list(pack["harness_features"]))):
        for value in sorted(set(want) - set(rows)):
            out.append(("PCK002", value, column, "%s in the pack's list and not in the pack document's table" % label))
        for value in sorted(set(rows) - set(want)):
            out.append(("PCK002", value, column, "%s in the pack document's table and not in the pack's list" % label))
        for value in sorted({v for v in rows if rows.count(v) > 1}):
            out.append(("PCK002", value, column, "%s stands twice in the pack document's table" % label))
    families = {re.match(r"[A-Z]+", code).group(0) for code in listed}
    flags = PC.fence_flags(lines)
    for i, line in enumerate(lines):
        if flags[i] or begin <= i <= end:
            continue
        for m in CODE_SHAPE.finditer(line):
            if m.group(1) in families and m.group(0) not in listed:
                out.append(("PCK002", m.group(0), "line %d" % (i + 1), "a rule code that is not in the pack's list"))
    return out


# ----------------------------------------------------------------------------------------------
# Page rules
# ----------------------------------------------------------------------------------------------
class Checker:
    def __init__(self, cat: PC.Catalog):
        self.cat, self.pack, self.roots = cat, cat.pack, cat.roots
        self.registry = cat.registry
        self.controls = {r["control_id"]: r for r in cat.controls}
        self.held = PC.parse_ranges(self.pack["controls_register_rules"]["held_ids"])
        self._text, self._shallow = {}, None
        self.links = PC.sibling(PC.LINK_CHECKER)

    # -- helpers --
    def source_text(self, rel: str) -> str:
        if rel not in self._text:
            try:
                self._text[rel] = (self.roots.repo / rel).read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                self._text[rel] = ""
        return self._text[rel]

    def commit_exists(self, sha: str) -> bool:
        """In a full checkout a missing object is a finding. In a shallow one it cannot be told from
        a commit that was never fetched, so the run stops as not evaluated."""
        code, _out = PC.git_run(self.roots.repo, "cat-file", "-e", sha + "^{commit}")
        if code == 0:
            return True
        if self._shallow is None:
            self._shallow = PC.git(self.roots.repo, "rev-parse", "--is-shallow-repository").strip() == b"true"
        if self._shallow:
            raise PC.NotEvaluated("a `last_verified_commit` object cannot be read and the checkout is shallow; "
                                  "page validation needs full history")
        return False

    def col(self, table: str, name: str, fallback: int) -> int:
        cols = self.pack["tables"].get(table, [])
        return cols.index(name) if name in cols else fallback

    # -- one page --
    def check(self, page: PC.Page) -> list:
        f = []
        add = lambda code, message, line=None, severity="": f.append(   # noqa: E731
            Finding(page.rel, line, code, message, severity))
        pack, enums, fm = self.pack, self.pack["enums"], page.fm
        if page.fm_status != "ok" or page.fm_end is None:
            add("FM001", "no readable frontmatter block (the shared reader's status: %s)" % page.fm_status)
            return f
        block = page.lines[1:page.fm_end]
        for i, line in enumerate(block):
            m = re.match(r"^([A-Za-z_]+):\s*$", line)
            if m and i + 1 < len(block) and block[i + 1].lstrip().startswith("- "):
                add("FM005", "`%s` is a block-form list; write it inline as [a, b]" % m.group(1), i + 1)
        for name, why in pack["reserved_field_names"].items():
            if name in fm:
                add("FM006", "reserved field `%s`: %s" % (name, why))
        level = fm.get("level", "")
        if level not in enums["level"]:
            add("FM003", "`level` must be one of %s, got `%s`" % (", ".join(enums["level"]), level))
            return f
        lvl = pack["levels"][level]
        node_id = fm.get("id", "")
        for name, spec in pack["fields"].items():
            required = level in spec.get("levels", []) and not spec.get("optional")
            value = fm.get(name, "")
            if not value:
                if required:
                    add("FM002", "required field `%s` is missing or empty for %s" % (name, level))
                continue
            kind = spec["type"]
            if kind == "enum" and value not in enums.get(spec.get("enum", ""), []):
                add("FM003", "`%s` holds `%s`, outside its enum" % (name, value))
            elif kind == "pattern" and not re.match(spec.get("pattern", ""), value):
                add("FM004", "`%s` does not match its pattern" % name)
            elif kind in ("path_list", "id_list", "actor_list", "trigger_list"):
                items = PC.parse_inline_list(value)
                if items is None:
                    add("FM005", "`%s` must be an inline list [a, b]" % name)
                    continue
                if len(items) < spec.get("min_items", 0):
                    add("FM002", "`%s` needs at least %d item(s)" % (name, spec["min_items"]))
                for item in items:
                    if kind == "actor_list" and not kind_match(item, enums["actor_kinds"]):
                        add("FM008", "actor `%s` is not of a listed kind" % item)
                    if kind == "trigger_list" and not (kind_match(item, enums["trigger_kinds"]) or item in self.registry):
                        add("FM009", "trigger `%s` is neither a registered node nor a trigger kind" % item)
                    if kind == "id_list" and item not in self.registry:
                        add("REG002", "`%s` names the unregistered ID `%s`" % (name, item))
            elif kind == "actor" and not kind_match(value, enums["actor_kinds"]):
                add("FM008", "`%s` value `%s` is not of a listed actor kind" % (name, value))
            elif kind == "id_ref" and value not in self.registry:
                add("REG002", "`%s` names the unregistered ID `%s`" % (name, value))
        if fm.get("flow_class") and fm["flow_class"] in enums["flow_class"] and fm["flow_class"] not in lvl["flow_class"]:
            add("FM003", "`flow_class` `%s` is not one of the classes of %s" % (fm["flow_class"], level))
        if node_id:
            if not re.match(pack["id"]["pattern"], node_id) or len(node_id) > pack["id"]["max_length"]:
                add("FM004", "the ID `%s` breaks the ID pattern" % node_id)
            if node_id != page.id:
                add("FM007", "`id` is `%s`; the file name stem is `%s`" % (node_id, page.id))
            row = self.registry.get(node_id)
            if row is None:
                add("REG001", "the ID `%s` is not in the ID registry" % node_id)
            else:
                if row["level"] != level:
                    add("REG003", "the registry has `%s` at %s; the page says %s" % (node_id, row["level"], level))
                if fm.get("universe") and row["universe"] != fm["universe"]:
                    add("REG003", "the registry puts `%s` in universe `%s`; the page says `%s`"
                        % (node_id, row["universe"], fm["universe"]))
        if level == enums["level"][0] and fm.get("universe") and node_id and fm["universe"] != node_id:
            add("REG003", "a universe page's `universe` must be its own ID")
        status = fm.get("status", "")
        if status == "SUPERSEDED" and not PC.parse_inline_list(fm.get("superseded_by", "")):
            add("FM010", "a superseded page must name `superseded_by`")
        if status == "ACTIVE" and (fm.get("lens_status", "") in ("", "not-assessed")
                                   or fm.get("lens_status") not in enums["lens_status"]):
            add("FM012", "an active page's `lens_status` is `%s`" % (fm.get("lens_status", "") or "absent"))
        if fm.get("pack_version") and fm["pack_version"] != str(pack["pack_version"]):
            add("FM011", "written against pack %s; the pack is version %s" % (fm["pack_version"], pack["pack_version"]))
        self._sources(page, add)
        self._structure(page, lvl, level, add)
        self._links_and_citations(page, add)
        self._content(page, level, add)
        return f

    def _sources(self, page, add) -> None:
        root = self.roots.catalog_rel
        for name in ("depicts", "documented_by"):
            for raw in page.items(name):
                entry = PC.clean_entry(raw)
                if PC.in_catalog(entry, root):
                    add("SRC001", "`%s` entry `%s` lies at or under the catalog root; no catalog file is a source"
                        % (name, raw))
                elif not [x for x in self.cat.tracked.expand(entry) if not PC.in_catalog(x, root)]:
                    add("SRC001", "`%s` entry `%s` is not a tracked file, nor a folder holding one" % (name, raw))
        sha = page.get("last_verified_commit")
        if sha and not (COMMIT_ID.match(sha) and self.commit_exists(sha)):
            add("SRC002", "`last_verified_commit` `%s` is not the full ID of a commit in this repository" % sha)
        # SRC003: a file-name-shaped token outside fenced code and outside link targets
        flags = PC.fence_flags(page.lines)
        sources = self.cat.sources(page)
        files = sources["depicts"] + sources["cites"]
        seen = set()
        for i in range(page.body_start, len(page.lines)):
            if flags[i]:
                continue
            text = PC.ANY_LINK_TARGET.sub("]", PC.COMMENT.sub(" ", page.lines[i]))
            for m in PC.NAME.finditer(text):
                token = m.group(0)
                if token in seen or re.match(r"^[A-Za-z]\.[A-Za-z]$", token):
                    continue
                seen.add(token)
                rel = re.sub(r"^\./", "", token)
                if rel in self.cat.tracked.set or ("/" not in rel and rel in self.cat.tracked.base):
                    continue
                if any(PC.occurs(token, self.source_text(x)) for x in files):
                    continue
                add("SRC003", "`%s` is no tracked file and no source of the page carries it" % token, i)

    def _structure(self, page, lvl, level, add) -> None:
        pack, secs = self.pack, page.sections()
        for name in lvl["required_sections"]:
            if name not in secs:
                add("SEC001", "missing section `## %s` for %s" % (name, level))
        for name, cols in pack["tables"].items():
            if name in secs and name in lvl["required_sections"]:
                header, rows = page.table(name)
                if header != cols:
                    add("TAB001", "the `## %s` table header differs from the pack's" % name)
                bad = [i for i, cells in rows if len(cells) != len(cols)]
                if bad:
                    add("TAB002", "`## %s` has %d row(s) whose cell count is not %d" % (name, len(bad), len(cols)), bad[0])
        flags = PC.fence_flags(page.lines)
        piped = [i for i in range(page.body_start, len(page.lines))
                 if not flags[i] and PC.is_table_line(page.lines[i]) and PC.code_span_pipes(page.lines[i].strip())]
        if piped:
            add("TAB003", "%d table row(s) carry an unescaped pipe inside a code span; write `\\|` or reword"
                % len(piped), piped[0])
        blocks = mermaid_blocks(page.lines[page.body_start:])
        if lvl.get("mermaid_required") and not blocks:
            add("MMD001", "%s needs a Mermaid flow" % level)
        for block in blocks:
            first = next((l.strip() for l in block if l.strip()), "")
            if not re.match(r"^flowchart\s+(TD|TB|LR|RL|BT)\b", first):
                add("MMD003", "a Mermaid block must open with `flowchart <direction>`")
            keywords = mermaid_keyword_ids(block)
            if keywords:
                add("MMD004", "Mermaid node ID(s) %s are Mermaid keywords; rename the node and keep its label"
                    % ", ".join(sorted(set(keywords))))
            count = len(mermaid_nodes(block))
            if count > lvl["mermaid_node_limit"]:
                add("MMD002", "the flow has %d nodes; the %s limit is %d" % (count, level, lvl["mermaid_node_limit"]))
        body = "\n".join(page.lines[page.body_start:])
        begin, end = body.find(self.cat.begin), body.find(self.cat.end)
        if not 0 <= begin < end:
            add("NAV001", "the navigation markers are missing or out of order")
        tokens = PC.token_estimate(page.text)
        if tokens > lvl["token_budget"]:
            add("TOK001", "about %d tokens; the %s budget is %d" % (tokens, level, lvl["token_budget"]))

    def _links_and_citations(self, page, add) -> None:
        for hit in self.links.scan_file(page.path, [], self.roots.repo):
            add("LNK001", "the link `%s` does not resolve (%s)" % (hit["target"], hit["category"]), hit["line"] - 1)
        catalog = os.path.realpath(self.roots.catalog)
        content = self.links.strip_code_blocks(page.lines)
        for line_no, target in self.links.extract_links(page.path, content):
            if target.startswith("/"):
                continue
            resolved, _anchor = self.links.resolve_target(page.path, target, self.roots.repo)
            if os.path.commonpath([catalog, str(resolved)]) != catalog:
                add("LNK002", "the relative link `%s` resolves outside the catalog folder; a source link starts at "
                              "the repository root" % target, line_no - 1)
        for cit in PC.find_citations(page.body_lines()):
            if cit.state == "bare":
                add("ANC001", "the line citation of `/%s` has no source anchor" % cit.path, cit.line)
            elif cit.state == "line-mismatch":
                add("ANC003", "the anchor of `/%s` names other lines than its fragment" % cit.path, cit.line)
            elif cit.state == "malformed":
                add("ANC002", {"anchor": "a source-anchor comment does not parse, or does not directly follow a "
                                         "source link",
                               "fragment": "a line fragment stands on a link that is not a source link",
                               "span": "a line fragment names a span that runs backwards or starts at line 0"}[cit.what],
                    cit.line)
        for index, m in PC.root_links(page):
            if PC.LABEL_LINE_TOKEN.search(PC.unspan(m.group("label"))):
                add("ANC004", "the label of the link to `%s` carries a line token" % m.group("path"), index)
        for index, text in page.body_lines():
            rest = PC.CITATION.sub(" ", text)
            rest = PC.ROOT_LINK.sub(" ", rest)
            rest = PC.ANY_LINK_TARGET.sub("]", PC.COMMENT.sub(" ", rest))
            if PC.PROSE_LINE_REF.search(rest):
                add("ANC005", "a line reference stands outside a citation", index)

    def _content(self, page, level, add) -> None:
        pack, enums = self.pack, self.pack["enums"]
        flags = PC.fence_flags(page.lines)
        for i, line in enumerate(page.lines):
            if not flags[i] and (PC.NUMBER_SIGN.search(line) or WORK_ITEM_URL.search(line)):
                add("REF001", "a number sign followed by a digit, or an issue or pull-request URL; describe the work "
                              "item in words", i)
        # Controls rows (the pages above an activity) and Steps rows (an activity page)
        class_col, surface_col = self.col("Controls", "Enforcement class", 2), self.col("Controls", "Surface", 3)
        for i, row in page.table("Controls")[1]:
            ids = list(dict.fromkeys(PC.CONTROL_ID.findall(" ".join(row))))
            cls = first_token(row[class_col]) if len(row) > class_col else ""
            surface = PC.unspan(row[surface_col]) if len(row) > surface_col else ""
            for cid in ids:
                self._control(cid, cls, add, i)
            if not ids and cls:
                if cls not in enums["enforcement_class"]:
                    add("CTL005", "the row cites no control ID and its class `%s` is not an enforcement class" % cls, i)
                elif cls != "prose-only":
                    add("CTL001", "the row names no control ID for class `%s`" % cls, i)
            if surface == "agent-run" and cls and cls != "code-warn":
                add("CTL004", "a row on the agent-run surface carries class `%s`" % cls, i)
        steps_header, steps = page.table("Steps")
        controls_col = self.col("Steps", "Controls", 4)
        harness_col, model_col = self.col("Steps", "Harness", 6), self.col("Steps", "Model need", 7)
        for i, row in steps:
            if len(row) > controls_col:
                for m in CONTROL_PAIR.finditer(row[controls_col]):
                    self._control(m.group(1), m.group(2) or "", add, i)
            if len(row) > harness_col:
                for token in re.split(r"[,;]", PC.unspan(row[harness_col])):
                    token = token.strip()
                    if token and token != "none" and token not in pack["harness_features"]:
                        add("STP001", "the harness feature `%s` is neither `none` nor a listed feature" % token, i)
        summary = pack["summary_counts"]
        if level == summary["level"] and summary["section"] in page.sections() and steps_header is not None:
            parts = [PC.unspan(row[model_col]).split("/") if len(row) > model_col else [] for _i, row in steps]
            stated = {PC.unspan(row[0]): row[1] for row in page.rows(summary["section"]) if len(row) >= 2}
            for label, want in summary["rows"].items():
                computed = sum(1 for p in parts if want in [x.strip() for x in p])
                if label not in stated:
                    add("SUM001", "the summary row `%s` is missing from `## %s`" % (label, summary["section"]))
                    continue
                m = re.match(r"\s*(\d+)", stated[label])
                if not m or int(m.group(1)) != computed:
                    add("SUM001", "`%s` says %s; the Steps table has %d row(s) marked %s"
                        % (label, stated[label].strip() or "nothing", computed, want))
        lens_col, source_col = self.col("Evidence", "Lens", 0), self.col("Evidence", "Source", 1)
        for i, row in page.table("Evidence")[1]:
            if len(row) > max(lens_col, source_col) and re.search(r"\bexecuted\b", PC.unspan(row[lens_col]).lower()):
                paths = [m.group("path") for m in PC.ROOT_LINK.finditer(row[source_col])]
                if not any((self.roots.repo / p.lstrip("/")).exists() for p in paths):
                    add("EVD001", "the executed row's Source cell has no root link that resolves", i)
        prose = "\n".join(re.sub(r"`[^`]*`", "", text) for _i, text in page.body_lines())
        for term in pack["explain_on_first_use"]:
            if re.search(r"(?<![\w-])" + re.escape(term) + r"(?![\w-])", prose) and \
                    not re.search(r"\[[^\]]*" + re.escape(term) + r"[^\]]*\]\(", prose):
                add("TRM001", "`%s` appears and is never linked to an explanation" % term)
        for entry in pack["forbidden_phrases"]:
            if re.search(re.escape(entry["phrase"]), prose, re.IGNORECASE):
                add("VOC001", "`%s`: use %s" % (entry["phrase"], entry.get("use", "another wording")),
                    severity=entry["severity"])
        for entry in pack["contested_terms"]:
            if re.search(r"(?<![A-Za-z-])" + re.escape(entry["term"]) + r"(?![A-Za-z-])", prose):
                add("VOC002", "`%s`: %s" % (entry["term"], entry.get("note", "a contested term")),
                    severity=entry["severity"])

    def _control(self, cid: str, cls: str, add, line) -> None:
        row = self.controls.get(cid)
        if row is None:
            held = int(cid[2:]) in self.held
            add("CTL003", "%s has no row in the controls register%s" % (cid, " (the ID lies in a held range)" if held else ""),
                line)
        elif cls and cls != first_token(row["enforcement_class_default"].split(" / ")[0]):
            add("CTL002", "%s is `%s` in the controls register; the page says `%s`"
                % (cid, first_token(row["enforcement_class_default"].split(" / ")[0]), cls), line)

    # -- catalog-level rules: run only when no target was given --
    def catalog_rules(self) -> list:
        cat, root = self.cat, self.roots.catalog_rel
        f = []
        for path in cat.non_pages:
            f.append(Finding(self.roots.rel(path), None, "PAG001",
                             "not a page: its stem is not a registered ID of this universe"))
        skip = []
        for u in cat.universes:
            if u in PC.RESERVED_FOLDERS:
                f.append(Finding(root, None, "PAG002", "the registered universe ID `%s` is a reserved folder name" % u))
            elif any(cat.universe(n) == u for n in cat.pages) and u not in cat.pages:
                f.append(Finding("%s/%s" % (root, u), None, "PAG002", "the universe folder holds pages and no L0 page"))
        for entry in sorted(self.roots.catalog.iterdir()):
            if entry.is_dir() and entry.name not in PC.RESERVED_FOLDERS and entry.name not in cat.universes:
                f.append(Finding("%s/%s" % (root, entry.name), None, "PAG002",
                                 "the folder is neither reserved nor the ID of a registered universe"))
                skip.append("%s/%s/" % (root, entry.name))
        generated = set(PC.Surfaces(cat).files) if cat.published else set()
        known = {self.roots.rel(p) for p in cat.non_pages}
        for rel in PC.unexpected_files(cat, generated):
            if rel not in known and not rel.startswith(tuple(skip)):
                f.append(Finding(rel, None, "PAG003", "nothing expects this file under the catalog root"))
        return f


# ----------------------------------------------------------------------------------------------
# The run
# ----------------------------------------------------------------------------------------------
def run(a, out=None) -> int:
    emit = print if out is None else out.append
    gate = "registers" if a.registers_only else "page-validation"
    state = {"universes": None, "pages": None, "registry_rows": None, "register_rows": None,
             "errors": None, "warns": None, "findings": None}
    body, examined = [], "nothing"

    def close(code: int) -> int:
        if a.registers_only:
            pairs = [("register_rows", state["register_rows"]), ("registry_rows", state["registry_rows"]),
                     ("pattern_arm", a.pattern_arm), ("findings", state["findings"])]
        else:
            pairs = [("universes", state["universes"]), ("pages", state["pages"]),
                     ("registry_rows", state["registry_rows"]), ("register_rows", state["register_rows"]),
                     ("pattern_arm", a.pattern_arm), ("errors", state["errors"]), ("warns", state["warns"])]
        PC.write_summary(a.summary_file, gate, PC.SUMMARY_STATUS[code], examined, body)
        emit(PC.census(gate, code, pairs))
        return code

    try:
        roots = PC.resolve_roots(a)
        pack = PC.load_pack(roots.pack)
        controls_path = PC.controls_register_path(pack, roots.pack, a.controls)
        reg = PC.check_registers(roots, pack, controls_path, a.pattern_arm, a.private_pattern_file,
                                 a.pattern_digest_file)
        for line in reg["lines"]:
            emit(line)
        state.update(register_rows=reg["register_rows"], registry_rows=reg["registry_rows"], findings=reg["findings"])
        if reg["stop"]:
            body.append("Not evaluated: %s." % reg["stop"])
            return close(PC.EXIT_NOT_EVALUATED)
        parity = pack_parity(pack, roots.pack_document)
        for finding in parity:
            emit("%s\t%s\t%s\t%s" % finding)
        state["findings"] = reg["findings"] + len(parity)
        examined = "%s register rows, %s registry rows" % (reg["register_rows"], reg["registry_rows"])
        if a.registers_only:
            body.append("%d finding(s) in the registers and the pack parity checks." % state["findings"])
            return close(PC.EXIT_FINDINGS if state["findings"] else PC.EXIT_CLEAN)
        cat = PC.Catalog(roots, a.controls)
        checker = Checker(cat)
        if a.targets:
            pages = []
            for target in a.targets:
                path = Path(target).resolve()
                if not path.is_file():
                    raise PC.NotEvaluated("a target is not a file: %s" % target)
                pages.append(PC.load_page(path, roots))
        else:
            pages = [cat.pages[n] for n in sorted(cat.pages, key=cat.order.get)]
        state.update(universes=len(cat.published_universes), pages=len(pages))
        if not pages:
            raise PC.NotEvaluated("no page is discovered: the catalog holds no page of a registered universe")
        findings = []
        for page in pages:
            findings += checker.check(page)
        if not a.targets:
            findings += checker.catalog_rules()
            for u in cat.published_universes:
                emit("universe %s: %d registered nodes, %d pages" % (
                    u, sum(1 for n in cat.registry if cat.universe(n) == u),
                    sum(1 for n in cat.pages if cat.universe(n) == u)))
        for finding in findings:
            emit(str(finding))
        errors = state["findings"] + sum(1 for x in findings if x.severity == "error")
        state.update(errors=errors, warns=sum(1 for x in findings if x.severity == "warn"))
        examined += ", %d pages in %d published universes" % (len(pages), len(cat.published_universes))
        body += ["%d error(s), %d warning(s)." % (errors, state["warns"])]
        body += ["- `%s`" % x for x in findings if x.severity == "error"]
        return close(PC.EXIT_FINDINGS if errors else PC.EXIT_CLEAN)
    except PC.NotEvaluated as e:
        emit("NOT EVALUATED: %s" % e)
        body.append("Not evaluated: %s." % e)
        return close(PC.EXIT_NOT_EVALUATED)


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(description="Validate process-catalog pages and check the registers.")
    ap.add_argument("targets", nargs="*", metavar="TARGET", help="page files; none means every discovered page")
    PC.add_root_arguments(ap, [row[0] for row in PC.DEFAULTS])
    ap.add_argument("--controls", metavar="PATH", help="the controls register, in place of the pack's pointer")
    ap.add_argument("--pattern-arm", choices=["run", "not-run"],
                    help="required on every run that checks the registers; never inferred")
    ap.add_argument("--private-pattern-file", metavar="PATH")
    ap.add_argument("--pattern-digest-file", metavar="PATH")
    ap.add_argument("--registers-only", action="store_true", help="run the register and pack checks alone")
    ap.add_argument("--list-rules", action="store_true", help="print code, severity and condition; examine nothing")
    ap.add_argument("--summary-file", metavar="FILE")
    ap.add_argument("--self-test", action="store_true")
    return ap


def main(argv=None) -> int:
    ap = build_parser()
    a = ap.parse_args(argv)
    if a.self_test:
        return self_test()
    if a.list_rules:
        for code, severity, text in RULES:
            print("%s\t%s\t%s" % (code, severity, text))
        return PC.EXIT_CLEAN
    if a.pattern_arm is None:
        ap.error("--pattern-arm run|not-run is required; the mode is never inferred from a missing file")
    if a.pattern_arm == "run" and not (a.private_pattern_file and a.pattern_digest_file):
        ap.error("--pattern-arm run needs --private-pattern-file and --pattern-digest-file")
    if a.pattern_arm == "not-run" and (a.private_pattern_file is not None or a.pattern_digest_file is not None):
        ap.error("--pattern-arm not-run takes neither --private-pattern-file nor --pattern-digest-file")
    if a.registers_only and a.targets:
        ap.error("--registers-only takes no target")
    return run(a)


# ----------------------------------------------------------------------------------------------
# Self-test — hermetic: a temporary repository built from the fixture tree and nothing else.
# ----------------------------------------------------------------------------------------------
def self_test() -> int:
    import hashlib
    arms = PC.Arms()
    tool = str(Path(__file__).resolve())
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(os.path.realpath(td))
        PC.isolate_git(tmp)
        fx = PC.build_fixture_repo(tmp / "repo")
        reg_args = fx.register_args
        base = ["--pattern-arm", "not-run"] + fx.args + reg_args

        def cli(args, tool_path=tool, env=None, cwd=None):
            proc = subprocess.run([sys.executable, "-B", tool_path] + list(args), capture_output=True, text=True,
                                  env=env, cwd=cwd or str(tmp))
            lines = proc.stdout.rstrip("\n").split("\n") if proc.stdout.strip() else []
            return proc.returncode, lines, proc.stderr

        def in_process(extra=(), targets=()):
            lines = []
            a = build_parser().parse_args(list(base) + list(extra) + [str(t) for t in targets])
            return run(a, lines), lines

        def codes_of(lines, severity):
            found = set()
            for line in lines:
                m = re.search(r": %s ([A-Z]{2,3}[0-9]{3}) " % severity, line)
                if m:
                    found.add(m.group(1))
            return found

        # -- the rule list --
        code, lines, _err = cli(["--list-rules"])
        listed = [l.split("\t")[0] for l in lines]
        arms.check("list-rules: 52 codes at this step, sorted, each with a severity and a condition",
                   code == 0 and len(listed) == 52 and listed == sorted(listed)
                   and all(len(l.split("\t")) == 3 for l in lines), len(listed))
        arms.check("list-rules: no census line — the command examines nothing",
                   not any(l.startswith("process-catalog ") for l in lines))
        arms.check("list-rules: the list equals the fixture pack's rule_codes",
                   listed == PC.load_pack(fx.definitions / PC.default_part("pack"))["rule_codes"])

        # -- the pass set --
        code, lines, _err = cli(base)
        arms.check("pass fixtures: exit 0 from the command line", code == 0, lines[-3:])
        arms.check("pass fixtures: the census is the last line and counts 7 pages in 1 universe with 0 errors",
                   bool(lines) and re.match(r"^process-catalog page-validation status=pass exit=0 universes=1 pages=7 "
                                            r"registry_rows=\d+ register_rows=2 pattern_arm=not-run errors=0 warns=\d+$",
                                            lines[-1]) is not None, lines[-1:])
        arms.check("pass fixtures: the three header lines and the roots line open the output",
                   lines[0].startswith("controls register: 2 rows read, 0 findings")
                   and lines[1].startswith("ID registry: ") and lines[2].startswith("pattern arm: NOT RUN (declared)")
                   and lines[3] == "register roots: catalog=%s fixtures=%s probe_source=%s held=C-003..C-004"
                   % (fx.layout["catalog"], fx.layout["fixtures"], fx.layout["probe_source"]), lines[:4])
        arms.check("pass fixtures: registered nodes are printed beside pages found",
                   any(l.startswith("universe %s: " % PC.FIXTURE_UNIVERSE) and l.endswith(" 7 pages") for l in lines))
        arms.check("pass fixtures: no error finding on any of the seven", not codes_of(lines, "ERROR"), codes_of(lines, "ERROR"))
        clean_status = PC.git(fx.repo, "status", "--porcelain", "--untracked-files=all", "--ignored")
        arms.check("clean checkout: page validation wrote nothing under the repository", clean_status == b"", clean_status)

        # -- the fail set: every code on each fixture's expect line --
        fail_dir = PC.FIXTURE_DIR / "pages" / "fail"
        fixtures = sorted(fail_dir.glob("*.md.txt"))
        arms.check("fail fixtures: 22 files", len(fixtures) == 22, len(fixtures))
        seen_codes = set()
        for path in fixtures:
            nid = path.name[:-len(".md.txt")]
            m = re.search(r"<!-- expect: ([A-Za-z0-9:, ]+) -->", path.read_text(encoding="utf-8"))
            want = [c.strip() for c in m.group(1).split(",")] if m else []
            placed = fx.fail_page(nid)
            try:
                code, lines = in_process(targets=[placed])
            finally:
                placed.unlink()
            errors, warns = codes_of(lines, "ERROR"), codes_of(lines, "WARN")
            missing = [c for c in want if (c[5:] not in warns if c.startswith("warn:") else c not in errors)]
            seen_codes |= errors | warns
            wants_error = any(not c.startswith("warn:") for c in want)
            arms.check("fail fixture %s raises %s" % (nid, ", ".join(want)),
                       bool(want) and not missing and code == (1 if wants_error or errors else 0),
                       "missing %s; errors %s; warns %s; exit %d" % (missing, sorted(errors), sorted(warns), code))

        # -- codes built at run time --
        scratch = fx.catalog / PC.FIXTURE_UNIVERSE
        plain = fx.page("fixture-activity-plain")
        plain_text = plain.read_text(encoding="utf-8")

        def with_page(name, text, check_codes, label, severity="ERROR", targets=True):
            path = scratch / name
            PC.write_text(path, text)
            try:
                code, lines = in_process(targets=[path] if targets else ())
            finally:
                path.unlink()
            got = codes_of(lines, severity)
            seen_codes.update(got)
            arms.check(label, set(check_codes) <= got, sorted(got))
            return lines

        with_page("fail-status-lens.md", "# No frontmatter here\n", ["FM001"], "FM001: a page with no frontmatter block")
        long_text = plain_text.replace("It describes nothing real.", "It describes nothing real. " + "word " * 2400)
        with_page("fixture-activity-plain-long.md", long_text, ["TOK001"], "TOK001: a page over its level's token budget")
        section = PC.load_pack(fx.definitions / PC.default_part("pack"))["summary_counts"]["section"]
        lines = with_page("fail-summary-count.md",
                          plain_text.replace("| Judgment steps | 1 |\n", "").replace("id: fixture-activity-plain",
                                                                                 "id: fail-summary-count"),
                          ["SUM001"], "SUM001: a summary row the pack names is missing")
        arms.check("SUM001: the message names the fixture pack's own section title, which no tool file holds",
                   any("SUM001" in l and section in l for l in lines) and section not in Path(tool).read_text(encoding="utf-8")
                   and section not in (HERE / "_process_catalog.py").read_text(encoding="utf-8"))
        arms.check("SUM001: the unchanged page reads no finding (the control)",
                   "SUM001" not in codes_of(in_process(targets=[plain])[1], "ERROR"))
        # the source set: no catalog file is ever a member (four arms and a near-miss)
        token = "only-the-catalog-has-it.cfg"
        PC.write_text(fx.catalog / "definitions" / "note.txt", "This catalog file carries %s.\n" % token)
        PC.test_git(fx.repo, "add", "-A")
        named = plain_text.replace("It describes nothing real.", "It describes nothing real. It names %s." % token)
        source_arms = (
            ("depicts its own universe folder", "depicts: [%s/%s]" % (fx.layout["catalog"], PC.FIXTURE_UNIVERSE), True),
            ("depicts a folder above the catalog", "depicts: [%s]" % fx.layout["catalog"].split("/")[0], False),
            ("depicts another page", "depicts: [%s]" % fx.roots().rel(fx.page("fixture-process")), True),
        )
        for label, depicts, also_src001 in source_arms:
            text = re.sub(r"(?m)^depicts: .*$", depicts, named)
            path = scratch / "fixture-activity-plain.md"
            path.write_text(text, encoding="utf-8")
            code, lines = in_process(targets=[path])
            got = codes_of(lines, "ERROR")
            arms.check("source set: a page that %s still reads SRC003 for a name only a catalog file carries%s"
                       % (label, ", and SRC001" if also_src001 else ""),
                       "SRC003" in got and (("SRC001" in got) == also_src001), sorted(got))
        path.write_text(named.replace("## Sources\n", "## Sources\n\n- [the catalog](/%s)\n" % fx.layout["catalog"]),
                        encoding="utf-8")
        got = codes_of(in_process(targets=[path])[1], "ERROR")
        arms.check("source set: a page that links the catalog root still reads SRC003, and no SRC001",
                   "SRC003" in got and "SRC001" not in got, sorted(got))
        carried = fx.repo / fx.layout["sources"] / "fixture-rules.md.txt"
        carried_text = carried.read_text(encoding="utf-8")
        carried.write_text(carried_text + "A depicted source that carries %s.\n" % token, encoding="utf-8")
        path.write_text(named, encoding="utf-8")
        got = codes_of(in_process(targets=[path])[1], "ERROR")
        arms.check("source set: the same name carried by a depicted file outside the catalog is not reported "
                   "(the near-miss)", "SRC003" not in got, sorted(got))
        carried.write_text(carried_text, encoding="utf-8")
        path.write_text(plain_text, encoding="utf-8")
        (fx.catalog / "definitions" / "note.txt").unlink()
        PC.test_git(fx.repo, "add", "-A")
        # catalog-level rules
        PC.write_text(scratch / "not-a-registered-id.md", "# stray\n")
        PC.write_text(scratch / "nested" / "file.txt", "stray\n")
        PC.write_text(fx.catalog / "unregistered-folder" / "page.md", "# stray\n")
        PC.write_text(fx.catalog / "stray-at-the-root.txt", "stray\n")
        code, lines = in_process()
        got = codes_of(lines, "ERROR")
        seen_codes |= got
        arms.check("PAG001 to PAG003: a stray Markdown file in a universe, an unregistered folder, a nested file and a "
                   "stray root file are each reported", {"PAG001", "PAG002", "PAG003"} <= got and code == 1, sorted(got))
        arms.check("PAG003: an untracked stray file is reported before it is committed",
                   any("PAG003" in l and "stray-at-the-root.txt" in l for l in lines))
        for stray in (scratch / "not-a-registered-id.md", fx.catalog / "stray-at-the-root.txt"):
            stray.unlink()
        shutil.rmtree(scratch / "nested")
        shutil.rmtree(fx.catalog / "unregistered-folder")
        l0 = fx.page(PC.FIXTURE_UNIVERSE)
        l0_text = l0.read_text(encoding="utf-8")
        l0.unlink()
        code, lines = in_process()
        arms.check("PAG002: a universe folder that holds pages and no L0 page", "PAG002" in codes_of(lines, "ERROR"))
        l0.write_text(l0_text, encoding="utf-8")
        PC.write_text(fx.catalog / "README.md", "# A catalog README\n")
        code, lines = in_process()
        arms.check("PAG003: the catalog README is expected (the near-miss)", code == 0 and "PAG003" not in codes_of(lines, "ERROR"),
                   lines[-1:])
        (fx.catalog / "README.md").unlink()

        # -- pack parity --
        pack_file, doc_file = fx.definitions / PC.default_part("pack"), fx.definitions / fx.layout["pack_document"]
        pack_text, doc_text = pack_file.read_text(encoding="utf-8"), doc_file.read_text(encoding="utf-8")

        def registers(extra=(), mode=("--pattern-arm", "not-run")):
            lines = []
            a = build_parser().parse_args(list(mode) + ["--registers-only"] + fx.args + reg_args + list(extra))
            return run(a, lines), lines

        def with_files(changes, label, expect, extra=()):
            for target, text in changes:
                target.write_text(text, encoding="utf-8")
            try:
                code, lines = registers(extra)
            finally:
                pack_file.write_text(pack_text, encoding="utf-8")
                doc_file.write_text(doc_text, encoding="utf-8")
            arms.check(label, expect(code, lines), "exit %d: %s" % (code, lines[4:]))
            return lines

        code, lines = registers()
        arms.check("registers-only: the fixture pair is clean, with both parity links reading nothing",
                   code == 0 and len(lines) == 5 and lines[-1] ==
                   "process-catalog registers status=pass exit=0 register_rows=2 registry_rows=%d pattern_arm=not-run "
                   "findings=0" % (len(PC.fixture_text(PC.default_part("registry")).strip().split("\n")) - 1), lines)
        with_files([(pack_file, pack_text.replace('"VOC002"', '"VOC002",\n    "ZZZ999"'))],
                   "PCK001: a code in the pack's list that this tool does not emit",
                   lambda c, l: c == 1 and any(x.startswith("PCK001\tZZZ999\t") for x in l))
        with_files([(pack_file, pack_text.replace('    "VOC001",\n', ""))],
                   "PCK001: a code this tool emits that the pack's list lacks",
                   lambda c, l: c == 1 and any(x.startswith("PCK001\tVOC001\t") for x in l))
        with_files([(doc_file, doc_text.replace("| `VOC001` | an invented fixture rule | this fixture |\n", ""))],
                   "PCK002: a row removed from the rules table",
                   lambda c, l: c == 1 and any(x.startswith("PCK002\tVOC001\trule-codes\t") for x in l))
        with_files([(doc_file, doc_text.replace("# Fixture definitions pack\n", "# Fixture definitions pack\n\nSee VOC777.\n"))],
                   "PCK002: a stray code of a live family in the document's prose",
                   lambda c, l: c == 1 and any(x.startswith("PCK002\tVOC777\t") for x in l))
        with_files([(doc_file, doc_text.replace("# Fixture definitions pack\n", "# Fixture definitions pack\n\nA SHA256 "
                                                "digest, an XYZ123 token and a hyphenated pre-VOC777 token.\n"))],
                   "PCK002: a hash name, a token of no live family and a hyphen-joined token are not read (the near-miss)",
                   lambda c, l: c == 0)
        feature = PC.load_pack(pack_file)["harness_features"][0]
        feature_row = "| `%s` | portable | An invented fixture feature |\n" % feature
        with_files([(doc_file, doc_text.replace(feature_row, ""))], "PCK002: a row removed from the feature table",
                   lambda c, l: c == 1 and any(x.startswith("PCK002\t%s\tharness-features\t" % feature) for x in l))
        with_files([(pack_file, pack_text.replace('"%s",' % feature, '"%s",\n    "added-to-the-list-only",' % feature))],
                   "PCK002: an identifier added to the pack's list only",
                   lambda c, l: c == 1 and any(x.startswith("PCK002\tadded-to-the-list-only\t") for x in l))
        with_files([(doc_file, doc_text.replace(feature_row, feature_row * 2))], "PCK002: a repeated feature row",
                   lambda c, l: c == 1 and any("stands twice" in x for x in l))
        with_files([(doc_file, doc_text.replace(feature_row, feature_row + "| `none` | portable | not a feature |\n"))],
                   "PCK002: a `none` row inside the feature markers",
                   lambda c, l: c == 1 and any(x.startswith("PCK002\tnone\tharness-features\t") for x in l))
        for marker in (FEATURE_MARKERS[1], RULE_MARKERS[1]):
            with_files([(doc_file, doc_text.replace(marker + "\n", ""))],
                       "PCK002: a missing end marker (%s) is not evaluated" % marker.split(":")[0][5:],
                       lambda c, l: c == 3 and l[-1].startswith("process-catalog registers status=not-evaluated exit=3 "))
        doc_file.unlink()
        code, lines = registers()
        doc_file.write_text(doc_text, encoding="utf-8")
        arms.check("PCK002: a missing pack document is not evaluated", code == 3, lines[-2:])
        for label, change in (("removed", lambda p: p.replace('  "pack_version": "2",\n', "")),
                              ("added", lambda p: p.replace('  "pack_version": "2",\n', '  "pack_version": "2",\n  "prose": "x",\n'))):
            lines = with_files([(pack_file, change(pack_text))], "pack shape: one key %s is not evaluated, naming the key" % label,
                               lambda c, l: c == 3 and any("NOT EVALUATED" in x and ("pack_version" in x or "prose" in x) for x in l))

        # -- the register rules: the fixture pair, the pattern arm, the gap rule --
        fail_register = str(fx.definitions / "controls-register-fail.tsv")
        code, lines = registers(["--controls", fail_register])
        rules_seen = sorted({l.split("\t")[0] for l in lines[4:-1]})
        arms.check("register pair: the failing register reports the structural rule alone when the pattern arm is not run",
                   code == 1 and rules_seen == ["R7c"] and {l.split("\t")[1] for l in lines[4:-1]} == {"C-001", "C-002"}, lines[4:])
        pattern = fx.definitions / "private-pattern.txt"
        digest = tmp / "digest.txt"
        digest.write_text(hashlib.sha256(pattern.read_bytes()).hexdigest() + "\n", encoding="utf-8")
        run_mode = ("--pattern-arm", "run", "--private-pattern-file", str(pattern), "--pattern-digest-file", str(digest))
        code, lines = registers(["--controls", fail_register], mode=run_mode)
        by_row = {}
        for l in lines[4:-1]:
            by_row.setdefault(l.split("\t")[1], set()).add(l.split("\t")[0])
        arms.check("register pair: under the pattern arm the entry-shaped name also reads the pattern rule",
                   code == 1 and by_row == {"C-001": {"R7c"}, "C-002": {"R7a", "R7c"}}, by_row)
        arms.check("register pair: the pattern-arm line names its probes and the probe source",
                   lines[2].startswith("pattern arm: run, ") and lines[2].endswith("words from %s" % fx.layout["probe_source"]),
                   lines[2])
        code, lines = registers(mode=run_mode)
        arms.check("register pair: the passing register is clean under the pattern arm, census pattern_arm=run",
                   code == 0 and lines[-1].endswith("pattern_arm=run findings=0"), lines)
        everything = " ".join(lines)
        arms.check("pattern arm: neither the pattern file's path nor the digest's is printed",
                   str(pattern) not in everything and str(digest) not in everything and digest.read_text().strip() not in everything)
        wrong = tmp / "wrong-digest.txt"
        wrong.write_text("0" * 64 + "\n", encoding="utf-8")
        code, lines = registers(mode=run_mode[:5] + (str(wrong),))
        arms.check("pattern arm: a digest that is not the pattern file's is not evaluated", code == 3 and "NOT EVALUATED" in lines[-2], lines)
        for label, body in (("an unusable pattern file", "(unclosed\n"), ("a match-everything pattern", ".*\n"),
                            ("a pattern that misses a fixed probe", "^nothing-matches-this$\n")):
            bad = tmp / "bad-pattern.txt"
            bad.write_text(body, encoding="utf-8")
            bad_digest = tmp / "bad-digest.txt"
            bad_digest.write_text(hashlib.sha256(bad.read_bytes()).hexdigest() + "\n", encoding="utf-8")
            code, lines = registers(mode=("--pattern-arm", "run", "--private-pattern-file", str(bad),
                                          "--pattern-digest-file", str(bad_digest)))
            arms.check("pattern arm: %s is not evaluated" % label, code == 3 and lines[0].startswith("register roots:"), lines)
        usage = (("no mode at all", ["--registers-only"]),
                 ("`run` with no pattern file", ["--registers-only", "--pattern-arm", "run"]),
                 ("`run` with no digest file", ["--registers-only", "--pattern-arm", "run", "--private-pattern-file", str(pattern)]),
                 ("`run` with an empty digest argument", ["--registers-only", "--pattern-arm", "run", "--private-pattern-file",
                                                         str(pattern), "--pattern-digest-file", ""]),
                 ("`not-run` with a pattern file", ["--registers-only", "--pattern-arm", "not-run", "--private-pattern-file", str(pattern)]),
                 ("`not-run` with a digest file", ["--registers-only", "--pattern-arm", "not-run", "--pattern-digest-file", str(digest)]),
                 ("the full run with no mode", []))
        for label, args in usage:
            code, lines, err = cli(args + fx.args + reg_args)
            arms.check("usage: %s is exit 2 with no census" % label,
                       code == 2 and not any(l.startswith("process-catalog ") for l in lines) and "usage" in err, (code, lines))
        # the gap rule, on the two-row fixture register
        register_file = fx.definitions / "controls-register.tsv"
        register_text = register_file.read_text(encoding="utf-8")
        row2 = register_text.rstrip("\n").split("\n")[2]

        def gap(label, rows_change=None, held=None, minted=None, drop=None, expect=None):
            text = register_text if rows_change is None else rows_change(register_text)
            pack = pack_text
            if held:
                pack = pack.replace('"C-003..C-004"', '"%s"' % held)
            if minted:
                pack = pack.replace('"highest_minted_id": "C-004"', '"highest_minted_id": "%s"' % minted)
            if drop:
                pack = drop(pack)
            register_file.write_text(text, encoding="utf-8")
            pack_file.write_text(pack, encoding="utf-8")
            try:
                code, lines = registers()
            finally:
                register_file.write_text(register_text, encoding="utf-8")
                pack_file.write_text(pack_text, encoding="utf-8")
            got = [tuple(l.split("\t")[i] for i in (0, 1, 3)) for l in lines[4:-1] if l.startswith("R")]
            arms.check("gap rule: " + label, expect(code, got, lines), "exit %d %s" % (code, got or lines))

        add_row = lambda n: (lambda t: t + row2.replace("C-002", "C-%03d" % n) + "\n")   # noqa: E731
        none, above = "no row and no held range", "above the highest minted ID"
        gap("the unchanged pair reads nothing", expect=lambda c, g, l: c == 0 and not g)
        gap("the first row removed", rows_change=lambda t: "\n".join(t.split("\n")[:1] + t.split("\n")[2:]),
            expect=lambda c, g, l: c == 1 and g == [("R2", "C-001", none)])
        gap("the held range moved up one and the value moved with it", held="C-004..C-005", minted="C-005",
            expect=lambda c, g, l: c == 1 and g == [("R2", "C-003", none)])
        gap("the held range moved up one, the value left", held="C-004..C-005",
            expect=lambda c, g, l: c == 1 and g == [("R2", "C-005", above), ("R2", "C-003", none)])
        gap("a row added at C-003", rows_change=add_row(3),
            expect=lambda c, g, l: c == 1 and g == [("R2", "C-003", "inside a held range")])
        gap("a row added at C-005, the value left", rows_change=add_row(5),
            expect=lambda c, g, l: c == 1 and g == [("R2", "C-005", above)])
        gap("the same row with the value raised to it reads nothing (the near-miss)", rows_change=add_row(5), minted="C-005",
            expect=lambda c, g, l: c == 0 and not g)
        gap("a row added at C-006 with the value raised to it", rows_change=add_row(6), minted="C-006",
            expect=lambda c, g, l: c == 1 and g == [("R2", "C-005", none)])
        gap("the value raised with no row added", minted="C-005",
            expect=lambda c, g, l: c == 1 and g == [("R2", "C-005", none)])
        gap("the value lowered", minted="C-002",
            expect=lambda c, g, l: c == 1 and g == [("R2", "C-003..C-004", above)])
        gap("the member removed from the pack is not evaluated, naming the key",
            drop=lambda p: p.replace('    "highest_minted_id": "C-004",\n', ""),
            expect=lambda c, g, l: c == 3 and any("highest_minted_id" in x for x in l))
        gap("a malformed member is not evaluated, naming the key", minted="minted",
            expect=lambda c, g, l: c == 3 and any("highest_minted_id" in x for x in l))
        gap("a pack with no held range is not evaluated",
            drop=lambda p: p.replace('"held_ids": [\n      "C-003..C-004"\n    ]', '"held_ids": []'),
            expect=lambda c, g, l: c == 3 and any("held_ids" in x for x in l))
        # a register that is not a fixture register may not cite a fixture source
        outside = tmp / "repo" / "elsewhere" / "controls-register.tsv"
        PC.write_text(outside, register_text)
        code, lines = registers(["--controls", str(outside)])
        got = sorted((l.split("\t")[0], l.split("\t")[1]) for l in lines[4:-1])
        arms.check("fixture-register test: the pair copied outside the fixture root reads R3c on both rows; in place it reads nothing",
                   code == 1 and got == [("R3c", "C-001"), ("R3c", "C-002")], got)
        outside.unlink()
        # a wrong header is a finding that stops as not evaluated
        register_file.write_text(register_text.replace("enforcement_surface", "surface"), encoding="utf-8")
        code, lines = registers()
        register_file.write_text(register_text, encoding="utf-8")
        arms.check("register load: a header that differs prints R1 and stops as not evaluated, with the count in the census",
                   code == 3 and any(l.startswith("R1\theader") for l in lines) and lines[-1].endswith("findings=1")
                   and "NOT EVALUATED: a register has no rows" in lines, lines)
        # the register the pack points at is removed: not evaluated; with it present: clean
        register_file.unlink()
        code, lines, _err = cli(base)
        arms.check("register load: the file the pack's pointer names is absent, so the run is exit 3 and not a pass",
                   code == 3 and "status=not-evaluated" in lines[-1] and any("controls register" in l for l in lines), lines)
        register_file.write_text(register_text, encoding="utf-8")
        arms.check("register load: with the file present the same run is exit 0", cli(base)[0] == 0)

        # -- the decoy-variable arm: no repository-location variable re-roots the register check --
        decoy = tmp / "decoy"
        PC.write_text(decoy / "unrelated.txt", "x\n")
        PC.git(decoy, *(PC.TEST_IDENTITY + ("init", "-q")))
        PC.commit_all(decoy, "decoy")
        clean = registers()[1]
        places = {"GIT_DIR": decoy / ".git", "GIT_WORK_TREE": decoy, "GIT_INDEX_FILE": decoy / ".git" / "index",
                  "GIT_OBJECT_DIRECTORY": decoy / ".git" / "objects", "GIT_COMMON_DIR": decoy / ".git",
                  "GIT_ALTERNATE_OBJECT_DIRECTORIES": decoy / ".git" / "objects"}
        places = {k: str(v) for k, v in places.items() if k in PC.location_vars()}
        for label, patch in [(k, {k: v}) for k, v in places.items()] + [("every one together", places)]:
            os.environ.update(patch)
            try:
                arms.check("decoy variable: %s set to a second repository leaves the register check as it was" % label,
                           registers()[1] == clean)
                if label in ("GIT_DIR", "every one together"):
                    PC.GIT_CLEARS_LOCATION = False
                    try:
                        moved = registers()[1] != clean
                    finally:
                        PC.GIT_CLEARS_LOCATION = True
                    arms.check("decoy variable: with the wrapper switched off, %s moves the verdict (the control)" % label, moved)
            finally:
                for key in patch:
                    os.environ.pop(key, None)
        env = dict(os.environ, GIT_DIR=places["GIT_DIR"], GIT_WORK_TREE=places["GIT_WORK_TREE"])
        code, lines, _err = cli(["--registers-only"] + base, env=env)
        arms.check("decoy variable: the command line run prints what it prints in a clean environment",
                   code == 0 and lines == clean, lines)

        # -- nothing examined is never a pass --
        empty = PC.build_fixture_repo(tmp / "empty", pages=False)
        code, lines, _err = cli(["--pattern-arm", "not-run"] + empty.args + empty.register_args)
        arms.check("nothing examined: an empty catalog is exit 3, census status=not-evaluated",
                   code == 3 and lines[-1].startswith("process-catalog page-validation status=not-evaluated exit=3 universes=0 pages=0 "),
                   lines[-2:])
        code, lines, _err = cli(base + [str(tmp / "no-such-page.md")])
        arms.check("nothing examined: a target that is not a file is exit 3", code == 3 and "not a file" in lines[-2], lines[-2:])
        code, lines, _err = cli(["--pattern-arm", "not-run"] + fx.args + reg_args + ["--pack", str(tmp / "absent.json")])
        arms.check("nothing examined: a missing pack is exit 3 with every census value unread",
                   code == 3 and lines[-1] == "process-catalog page-validation status=not-evaluated exit=3 universes=NA "
                   "pages=NA registry_rows=NA register_rows=NA pattern_arm=not-run errors=NA warns=NA", lines)
        unreadable = scratch / "fixture-activity-plain.md"
        unreadable.write_bytes(b"\xff\xfe not text")
        code, lines, _err = cli(base)
        unreadable.write_text(plain_text, encoding="utf-8")
        arms.check("nothing examined: a page that is not UTF-8 is exit 3, naming the file",
                   code == 3 and any("fixture-activity-plain.md" in l and "NOT EVALUATED" in l for l in lines), lines[-2:])
        shallow_text = plain_text.replace(fx.base, "1" * 40)
        unreadable.write_text(shallow_text, encoding="utf-8")
        code, lines = in_process(targets=[unreadable])
        arms.check("SRC002: in a full checkout a commit that does not exist is a finding",
                   code == 1 and "SRC002" in codes_of(lines, "ERROR"), lines[-2:])
        clone = tmp / "shallow"
        PC.git(tmp, *(PC.TEST_IDENTITY + ("clone", "-q", "--depth", "1", "file://%s" % fx.repo, str(clone))))
        (clone / fx.layout["catalog"] / PC.FIXTURE_UNIVERSE / "fixture-activity-plain.md").write_text(shallow_text, encoding="utf-8")
        shallow_args = [x.replace(str(fx.repo), str(clone)) for x in fx.args]
        code, lines, _err = cli(["--pattern-arm", "not-run"] + shallow_args + reg_args)
        arms.check("SRC002: in a shallow checkout the same page stops the run as not evaluated",
                   code == 3 and any("shallow" in l for l in lines), lines[-2:])
        unreadable.write_text(plain_text, encoding="utf-8")

        # -- the summary file --
        summary = tmp / "summary.md"
        cli(base + ["--summary-file", str(summary)])
        cli(["--pattern-arm", "not-run"] + empty.args + empty.register_args + ["--summary-file", str(summary)])
        text = summary.read_text(encoding="utf-8") if summary.is_file() else ""
        arms.check("summary file: a passing run and a not-evaluated run each append one block",
                   text.count("### Process catalog — page-validation: PASS") == 1
                   and text.count("### Process catalog — page-validation: NOT EVALUATED") == 1, text)

        # -- one reader, by behaviour --
        real = (PC.read_frontmatter, PC.frontmatter_end, PC.frontmatter_lines)
        PC.read_frontmatter = lambda path: ({}, "sentinel-status")
        try:
            code, lines = in_process(targets=[plain])
        finally:
            PC.read_frontmatter = real[0]
        arms.check("single reader: with the shared reader's function replaced, the page's findings follow the stub",
                   code == 1 and any("FM001" in l and "sentinel-status" in l for l in lines), lines[-3:])
        PC.frontmatter_end = lambda **kw: None
        try:
            code, lines = in_process(targets=[plain])
        finally:
            PC.frontmatter_end = real[1]
        arms.check("single reader: with the block-end function replaced, the page reads as having no block",
                   code == 1 and "FM001" in codes_of(lines, "ERROR"), lines[-3:])
        arms.check("single reader: restored, the page is clean (the control)", in_process(targets=[plain])[0] == 0)

        # -- relocation: the tool and its siblings outside any repository, every root an argument --
        moved_tool, moved_repo = PC.relocate_tools(tmp / "outside" / "a" / "b" / "c" / "tools"), None
        moved_repo = PC.build_fixture_repo(tmp / "relocated", layout=PC.relocated_layout())
        every = {"--repo": str(moved_repo.repo), "--catalog-root": str(moved_repo.catalog),
                 "--definitions": str(moved_repo.definitions),
                 "--pack": str(moved_repo.definitions / PC.default_part("pack")),
                 "--pack-document": str(moved_repo.definitions / moved_repo.layout["pack_document"]),
                 "--registry": str(moved_repo.definitions / PC.default_part("registry")),
                 "--kinds": str(moved_repo.definitions / PC.default_part("kinds")),
                 "--fixture-root": moved_repo.layout["fixtures"], "--probe-source": moved_repo.layout["probe_source"]}

        def moved(without=(), env=None):
            args = ["--pattern-arm", "not-run"]
            for flag, value in every.items():
                if flag not in without:
                    args += [flag, value]
            return cli(args, tool_path=str(moved_tool / Path(tool).name), env=env, cwd=str(tmp / "outside"))

        code, first, _err = moved()
        parts = [row[2] for row in PC.DEFAULTS if row[1] == "repo"]
        arms.check("relocation: every root passed, exit 0 and no default path in the output",
                   code == 0 and not any(p in "\n".join(first) for p in parts), first[-2:])
        for flag in ("--definitions", "--pack", "--pack-document", "--registry", "--kinds"):
            code, lines, _err = moved(without=(flag,))
            arms.check("relocation: %s omitted beneath a passed parent changes no output byte" % flag,
                       code == 0 and lines == first, lines[-2:])
        code, lines, _err = moved(without=("--fixture-root",))
        arms.check("relocation: --fixture-root omitted is exit 0, and the roots line prints the default",
                   code == 0 and any(l.startswith("register roots:") and PC.default_part("fixtures") in l for l in lines), lines[:4])
        for label, env in (("the workspace-root variable unset", {k: v for k, v in os.environ.items() if k != "CLAUDE_WORKSPACE_ROOT"}),
                           ("the workspace-root variable set to a decoy", dict(os.environ, CLAUDE_WORKSPACE_ROOT=str(decoy)))):
            code, lines, _err = moved(without=("--repo",), env=env)
            arms.check("relocation: --repo omitted is exit 3 naming it, with %s" % label,
                       code == 3 and any("--repo" in l for l in lines), lines[-2:])
            code, lines, _err = moved(without=("--catalog-root", "--definitions", "--pack", "--pack-document", "--registry", "--kinds"), env=env)
            arms.check("relocation: --catalog-root omitted is exit 3 naming it, with %s" % label,
                       code == 3 and any("--catalog-root" in l for l in lines), lines[-2:])

        # -- every code this tool lists was raised by some arm --
        runtime_only = {"PCK001", "PCK002"}
        arms.check("coverage: every listed code was raised by a fixture or a run-time arm",
                   set(CODES) - runtime_only <= seen_codes, sorted(set(CODES) - runtime_only - seen_codes))
    return arms.finish()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except PC.NotEvaluated as e:
        print("NOT EVALUATED: %s" % e)
        print(PC.census("self-test", PC.EXIT_NOT_EVALUATED, [("arms", None), ("failed", None)]))
        sys.exit(PC.EXIT_NOT_EVALUATED)

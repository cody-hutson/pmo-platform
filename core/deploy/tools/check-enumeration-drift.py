#!/usr/bin/env python3
"""check-enumeration-drift.py — the enumeration <-> population drift check (deploy.sh Check 83).

WHAT IT ASSERTS
    A hand-maintained enumeration that carries an enumeration marker agrees with the
    tracked files the marker's glob matches. Under `count` the stated cardinal equals
    their number; under `list` the items name exactly those files; under `subset-of`
    every item names one of them. A malformed or unbound marker is a finding, never a
    silent skip. An enumeration with no marker is not read at all: this tool reads only
    DECLARED bindings and infers nothing.

THE GRAMMAR
    Marker. Outside fenced blocks (the ``` / ~~~ toggle, Check 63's rule), a line whose
    stripped text starts with `<!-- enumerates:` is a marker. It must match
        <!-- enumerates: <glob> <count|list|subset-of> -->
    exactly, or it is UNRESOLVED malformed.

    Glob. Repository-relative, with no leading `/`, no `..` segment and no `**`, or it is
    UNRESOLVED malformed-glob. Matching is segment-equal, with fnmatch.fnmatchcase
    applied per segment, so a wildcard never crosses a `/`. Candidates are
    `git -C <root> ls-files -z`, run once, when --root is the top level of a git work
    tree; otherwise an os.walk of --root. A glob is never passed to git as a pathspec,
    because a git pathspec `*` crosses `/`. Zero matches is UNRESOLVED empty-population.

    Binding. `count`: the next non-blank line must not open a list or table, and after
    mask_noncounting_spans it must carry exactly one CARDINAL_RE match; otherwise it is
    UNRESOLVED count-target. `list` / `subset-of`: skip blank lines, allow at most one
    non-blank prose line (the preamble), then skip blank lines again; the next line must
    open a list or a table per structure_at, otherwise it is UNRESOLVED unbound.

    Items. An item is a top-level list item (structure_at's run rule, where continuation
    and nested lines belong to the item) or a table body row. The item count must equal
    structure_at's count, otherwise it is UNRESOLVED boundary-disagreement.

    Relations. `count` drifts when the cardinal differs from the number of members.
    `list` drifts when `missing` (members no item names), `extra` (item keys that are not
    members, plus off-glob items) or `dup` (repeated keys) is non-empty. `subset-of`
    drifts when `extra` or `dup` is non-empty.

KEYS
    A member's key is its path segments at every glob segment carrying `*`, `?` or `[`,
    joined by `/` — the basename for core/hooks/block-*.sh, the skill directory for
    operations/skills/*/SKILL.md. An item's key comes from its first link `](target)`,
    external schemes and pure anchors skipped: `#...`, `?...` and a trailing `/` are
    stripped; a leading `/` resolves from the root, anything else is
    posixpath.normpath(join(<the document's directory>, target)). The resolved path
    must have at least D+1 segments, where D is the index of the deepest wildcard
    segment, and segments 0..D must each match the glob's segment; then the key is the
    segments at the wildcard indices. Otherwise the item is extra, keyed by its resolved
    path. With no usable link the key comes from the first code span: with a trailing
    `/` stripped, a span with as many `/`-separated parts as the glob has wildcard
    segments is the key; a span with the glob's full segment count is resolved from the
    root, as a link is; anything else is UNRESOLVED unkeyed-item. A glob with no
    wildcard segment at all keys by its whole path — the rule read with every segment
    counted as keyed, so a literal glob still compares like for like.

OUTPUT (--output-format tsv; tab-separated, five row classes and nothing else)
    SCOPE      status=<fetched|degraded>  state=<-|DEGRADED>  files=<n>  read=<n>  unreadable=<n>  exempted=<n>
    DENOM      files=<read>  markers=<m>  resolved=<r>  unresolved=<u>  drift=<d>
    CONTROL    <PASS|FAIL>  count sens=1/1 spec=0/1; list sens=1/1 spec=0/1; subset-of sens=1/1 spec=0/1; unresolved=1/1; parity=ok; keys spec=0/2 guard=1/1
    DRIFT      <path>  <line>  <relation>  <glob>  stated=<n>|listed=<n>  population=<n>  missing=<csv|->  extra=<csv|->  dup=<csv|->
    UNRESOLVED <path>  <line>  <reason>
    `markers` is resolved plus unresolved; `resolved` counts markers that bound and
    keyed, drifting or not; `drift` and `unresolved` equal the rows printed; `listed`
    counts every item. `<line>` is the marker's line. No field is ever empty — an empty
    set prints `-` — because the consumer's `read` collapses empty tab fields.

EXIT CODES (Check 59 contract)
    0 — CONTROL PASS and no DRIFT or UNRESOLVED row.
    1 — any DRIFT or UNRESOLVED row, or CONTROL FAIL.
    3 — input failure: zero readable files, a Check 63 load failure, a failed
        `git ls-files` under a git root, or an unreadable --paths-from / --fixtures file.
        The tool prints one `INPUT-FAILURE: <reason>` line and nothing else. A corpus
        with nothing to examine is not exit 3: it is markers=0 and exit 0.

SELF-CONTROL ON EVERY RUN (PV-5)
    --self-test runs the control arms in memory, with no git and no filesystem, and every
    corpus run runs the same arms and emits them as the CONTROL row, so "zero drift" is
    always distinguishable from "nothing could have drifted". Each arm must examine at
    least one marker: count+ (2 stated against 3) and count- (`three` against 3); list+
    (2 of 3 listed) and subset- (the SAME document under subset-of, the near-miss arm);
    list- (an exact list) and subset+ (an extra member); unresolved (an unbound marker);
    parity (the item count equals structure_at's); keys — a directory-keyed list over
    sk/*/SKILL.md and a count over colliding basenames must not flag, and the guard over
    a synthetic duplicated member list must read ambiguous-population. A broken or
    over-matching arm makes the CONTROL row FAIL and the run exit 1.

WHY NOT AN ARM OF CHECK 63
    An arm is feasible: Check 63 already runs a committed-warn arm (its stale-baseline
    ratchet), and a lettered sub-check could hold the header. This is a sibling for three
    reasons. One primitive per exit contract — the verdict tail reads this primitive's
    exit status against its rows, and a shared invocation would make exit 1 ambiguous
    whenever Check 63 itself has a finding. Different evidence — Check 63 infers
    count/structure pairs within one file and declares cross-file claims outside its
    boundary; this tool reads only declared markers and compares a document with a
    population of files. One dial per predicate, so each graduates on its own decision.
    Check 63's structure predicate and exemption tuple are imported, so "what is a list
    item" has one implementation.

KEYS AND THE AMBIGUITY GUARD
    Keys are read at the wildcard-bearing segments, never at the basename alone. A
    basename key collides for every directory-keyed population — one SKILL.md per skill
    directory — so a list of skills could never be keyed by it; the segments the
    wildcards match are exactly what distinguishes one member from another. Two distinct
    tracked paths that match one glob share its literal segments and therefore differ in
    a wildcard-bearing segment, and the key carries every one of those, so two members
    can never share a key. The ambiguity guard (UNRESOLVED ambiguous-population) is
    therefore a fail-closed assertion rather than a reachable state, and the self-test
    exercises it over a synthetic duplicated member list. It runs under `list` and
    `subset-of` only, because only those relations compare keys; `count` compares a
    number with a number, so a key collision cannot change its verdict.

COVERAGE BOUNDARY
    What the check does not detect. An enumeration with no marker; one in an exempt tree
    (the frozen release corpus, the deliberate-defect fixture trees, `packages/` and
    `.github/`); a population no glob expresses; a relation that filters rows; an inline
    comma-separated list under `list` or `subset-of`; an enumeration outside markdown;
    whether an item's description is still true; and completeness under `subset-of`.
"""

from __future__ import annotations

import argparse
import fnmatch
import importlib.util
import os
import posixpath
import re
import subprocess  # nosec B404 — runs only `git` with a fixed argument vector
import sys

# ── The Check 63 predicate, imported rather than restated ────────────────────
_C63_BASENAME = "check-count-structure.py"
_C63_NAMES = ("EXEMPT_PREFIXES", "LIST_ITEM_RE", "TABLE_SEP_RE", "structure_at",
              "CARDINAL_RE", "NUMBER_WORDS", "cardinal_value", "mask_noncounting_spans")
C63 = None


def load_c63():
    """Load check-count-structure.py by path, relative to this file, never the cwd.
    Its hyphenated basename is not a legal module name, so it goes through importlib
    (the check-rules-budget.py precedent). Raises ImportError on any failure."""
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, _C63_BASENAME)
    if not os.path.isfile(path):
        raise ImportError("not found at %s" % path)
    spec = importlib.util.spec_from_file_location("_check_count_structure", path)
    if spec is None or spec.loader is None:
        raise ImportError("no loader for %s" % path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    missing = [n for n in _C63_NAMES if not hasattr(module, n)]
    if missing:
        raise ImportError("it no longer defines %s" % ", ".join(missing))
    return module


# ── Grammar ──────────────────────────────────────────────────────────────────
MARKER_PREFIX = "<!-- enumerates:"
MARKER_RE = re.compile(r"^<!-- enumerates: (?P<glob>\S+) (?P<rel>count|list|subset-of) -->$")
RELATIONS = ("count", "list", "subset-of")
WILDCARD_CHARS = "*?["
EXTERNAL_RE = re.compile(r"^[a-z][a-z0-9+.-]*:")
CODE_SPAN_RE = re.compile(r"`([^`]+)`")
LINK_RE = re.compile(r"\]\(\s*<?([^)\s>]+)>?(?:\s+[^)]*)?\)")


def _is_fence(line):
    s = line.strip()
    return s.startswith("```") or s.startswith("~~~")


def glob_ok(glob):
    if glob.startswith("/") or "**" in glob:
        return False
    return ".." not in glob.split("/")


def glob_members(gsegs, candidates):
    """Segment-equal matching: a candidate matches only with the same segment count and
    every segment matching its glob segment, so `*` never crosses a `/`."""
    n = len(gsegs)
    out = []
    for path in candidates:
        psegs = path.split("/")
        if len(psegs) == n and all(fnmatch.fnmatchcase(p, g) for p, g in zip(psegs, gsegs)):
            out.append(path)
    return out


def wildcard_indices(gsegs):
    idx = [i for i, s in enumerate(gsegs) if any(c in s for c in WILDCARD_CHARS)]
    return idx or list(range(len(gsegs)))


def member_key(path, widx):
    segs = path.split("/")
    return "/".join(segs[i] for i in widx)


def key_from_resolved(resolved, gsegs, widx):
    """('key', key) when the path names a member shape, else ('extra', resolved)."""
    deepest = max(widx)
    segs = resolved.split("/")
    if len(segs) >= deepest + 1 and all(
            fnmatch.fnmatchcase(segs[i], gsegs[i]) for i in range(deepest + 1)):
        return ("key", "/".join(segs[i] for i in widx))
    return ("extra", resolved)


def _resolve_target(target, doc_dir):
    t = target.split("#", 1)[0].split("?", 1)[0].rstrip("/")
    if not t:
        return None
    if t.startswith("/"):
        return posixpath.normpath(t.lstrip("/"))
    return posixpath.normpath(posixpath.join(doc_dir, t))


def item_key(item_lines, doc_dir, gsegs, widx):
    """('key', k) · ('extra', resolved-path) · ('unkeyed', None)."""
    text = "\n".join(item_lines)
    # A link inside a code span is not a link: blank code-span contents first.
    masked = CODE_SPAN_RE.sub(lambda m: "`" + " " * len(m.group(1)) + "`", text)
    for m in LINK_RE.finditer(masked):
        target = m.group(1)
        if target.startswith("#") or EXTERNAL_RE.match(target):
            continue
        resolved = _resolve_target(target, doc_dir)
        if resolved is None:
            continue
        return key_from_resolved(resolved, gsegs, widx)
    cm = CODE_SPAN_RE.search(text)
    if cm:
        span = cm.group(1).strip().rstrip("/")
        parts = span.split("/")
        if span and len(parts) == len(widx):
            return ("key", span)
        if span and len(parts) == len(gsegs):
            return key_from_resolved(posixpath.normpath(span.lstrip("/")), gsegs, widx)
    return ("unkeyed", None)


def list_items(lines, idx):
    """The items of the list opening at lines[idx], under structure_at's run rule:
    a top-level item owns its continuation and nested lines."""
    base = len(C63.LIST_ITEM_RE.match(lines[idx]).group(1))
    items, cur, j, blanks = [], None, idx, 0
    while j < len(lines):
        ln = lines[j]
        if not ln.strip():
            blanks += 1
            if blanks >= 2:
                break
            j += 1
            continue
        mm = C63.LIST_ITEM_RE.match(ln)
        if mm:
            ind = len(mm.group(1))
            if ind == base:
                cur = [ln]
                items.append(cur)
                blanks = 0
                j += 1
                continue
            if ind > base:
                cur.append(ln)
                blanks = 0
                j += 1
                continue
            break
        if blanks:
            break
        if ln.startswith((" ", "\t")):
            cur.append(ln)
            j += 1
            continue
        break
    return items


def table_items(lines, idx):
    rows, j = [], idx
    while j < len(lines) and lines[j].lstrip().startswith("|"):
        rows.append(lines[j])
        j += 1
    seps = [k for k, r in enumerate(rows) if C63.TABLE_SEP_RE.match(r)]
    body = rows[seps[0] + 1:] if seps else rows[1:]
    return [[r] for r in body]


def _next_nonblank(lines, j):
    while j < len(lines) and not lines[j].strip():
        j += 1
    return j


def bind_structure(lines, mi):
    """(index, kind, count) of the list or table a list/subset-of marker binds, or None."""
    j = _next_nonblank(lines, mi + 1)
    for _attempt in (0, 1):
        if j >= len(lines) or _is_fence(lines[j]) or lines[j].strip().startswith(MARKER_PREFIX):
            return None
        kind, count = C63.structure_at(lines, j)
        if kind:
            return j, kind, count
        j = _next_nonblank(lines, j + 1)   # the one permitted preamble line
    return None


def _csv(values):
    return ",".join(values) if values else "-"


def eval_marker(lines, mi, stripped, path, candidates):
    """One marker's verdict: ('UNRESOLVED', reason) · ('CLEAN', None) · ('DRIFT', fields)."""
    m = MARKER_RE.match(stripped)
    if not m:
        return ("UNRESOLVED", "malformed")
    glob, rel = m.group("glob"), m.group("rel")
    if not glob_ok(glob):
        return ("UNRESOLVED", "malformed-glob")
    gsegs = glob.split("/")
    members = glob_members(gsegs, candidates)
    if not members:
        return ("UNRESOLVED", "empty-population")

    if rel == "count":
        j = _next_nonblank(lines, mi + 1)
        if j >= len(lines) or C63.structure_at(lines, j)[0]:
            return ("UNRESOLVED", "count-target")
        cards = list(C63.CARDINAL_RE.finditer(C63.mask_noncounting_spans(lines[j])))
        if len(cards) != 1:
            return ("UNRESOLVED", "count-target")
        stated = C63.cardinal_value(cards[0].group(1))
        if stated == len(members):
            return ("CLEAN", None)
        return ("DRIFT", [rel, glob, "stated=%d" % stated, "population=%d" % len(members),
                          "missing=-", "extra=-", "dup=-"])

    bound = bind_structure(lines, mi)
    if bound is None:
        return ("UNRESOLVED", "unbound")
    sidx, kind, count = bound
    items = list_items(lines, sidx) if kind == "list" else table_items(lines, sidx)
    if len(items) != count:
        return ("UNRESOLVED", "boundary-disagreement")
    widx = wildcard_indices(gsegs)
    mkeys = [member_key(p, widx) for p in members]
    if len(set(mkeys)) != len(mkeys):
        return ("UNRESOLVED", "ambiguous-population")
    doc_dir = posixpath.dirname(path)
    keyed = []
    for it in items:
        k = item_key(it, doc_dir, gsegs, widx)
        if k[0] == "unkeyed":
            return ("UNRESOLVED", "unkeyed-item")
        keyed.append(k)
    mset = set(mkeys)
    names = [k[1] for k in keyed]
    member_hits = {k[1] for k in keyed if k[0] == "key" and k[1] in mset}
    extra = sorted({k[1] for k in keyed if k[0] == "extra" or k[1] not in mset})
    seen, dup = set(), set()
    for n in names:
        if n in seen:
            dup.add(n)
        seen.add(n)
    missing = sorted(mset - member_hits) if rel == "list" else []
    if missing or extra or dup:
        return ("DRIFT", [rel, glob, "listed=%d" % len(items), "population=%d" % len(members),
                          "missing=" + _csv(missing), "extra=" + _csv(extra),
                          "dup=" + _csv(sorted(dup))])
    return ("CLEAN", None)


def evaluate(text, path, candidates):
    """Every marker in one document. Returns (markers, rows), each row a tuple whose first
    element is DRIFT or UNRESOLVED and whose remaining elements are its TSV fields."""
    lines = text.split("\n")
    in_fence = False
    markers, rows = 0, []
    for i, raw in enumerate(lines):
        s = raw.strip()
        if s.startswith("```") or s.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence or not s.startswith(MARKER_PREFIX):
            continue
        markers += 1
        verdict, detail = eval_marker(lines, i, s, path, candidates)
        if verdict == "UNRESOLVED":
            rows.append(("UNRESOLVED", path, str(i + 1), detail))
        elif verdict == "DRIFT":
            rows.append(("DRIFT", path, str(i + 1)) + tuple(detail))
    return markers, rows


# ── Control arms (run on EVERY invocation — PV-5) ────────────────────────────
_POP = ["pop/alpha.sh", "pop/beta.sh", "pop/gamma.sh"]
_SK = ["sk/alpha/SKILL.md", "sk/beta/SKILL.md"]
_LIST_TWO = "The fixture hooks:\n\n- `alpha.sh`\n- `beta.sh`\n"


def _arm(doc, candidates):
    markers, rows = evaluate(doc, "control.md", candidates)
    drift = sum(1 for r in rows if r[0] == "DRIFT")
    unres = [r[3] for r in rows if r[0] == "UNRESOLVED"]
    return markers, drift, unres


def run_controls():
    """Returns (ok, detail). Every arm must examine >= 1 marker and land on its verdict."""
    ok = True

    def sens(doc, cands):
        nonlocal ok
        mk, drift, unres = _arm(doc, cands)
        if not (mk == 1 and drift == 1 and not unres):
            ok = False
        return "%d/%d" % (drift, mk)

    def spec(doc, cands):
        nonlocal ok
        mk, drift, unres = _arm(doc, cands)
        if not (mk == 1 and drift == 0 and not unres):
            ok = False
        return "%d/%d" % (drift + len(unres), mk)

    c_sens = sens("<!-- enumerates: pop/*.sh count -->\nRead by 2 hooks.\n", _POP)
    c_spec = spec("<!-- enumerates: pop/*.sh count -->\nRead by three hooks.\n", _POP)
    l_sens = sens("<!-- enumerates: pop/*.sh list -->\n" + _LIST_TWO, _POP)
    s_spec = spec("<!-- enumerates: pop/*.sh subset-of -->\n" + _LIST_TWO, _POP)
    l_spec = spec("<!-- enumerates: pop/*.sh list -->\n- `alpha.sh`\n- `beta.sh`\n- `gamma.sh`\n", _POP)
    s_sens = sens("<!-- enumerates: pop/*.sh subset-of -->\n- `alpha.sh`\n- `delta.sh`\n", _POP)

    mk, drift, unres = _arm("<!-- enumerates: pop/*.sh list -->\nOne line of prose.\n"
                            "A second line of prose.\n\n- `alpha.sh`\n", _POP)
    if not (mk == 1 and drift == 0 and unres == ["unbound"]):
        ok = False
    unresolved = "%d/%d" % (len(unres), mk)

    pdoc = ("<!-- enumerates: pop/*.sh list -->\n- `alpha.sh` — first\n"
            "  continued on a second line\n- `beta.sh`\n  - a nested line\n- `gamma.sh`\n")
    plines = pdoc.split("\n")
    pk, pn = C63.structure_at(plines, 1)
    pmk, pdrift, punres = _arm(pdoc, _POP)
    parity_ok = (pk == "list" and pn == 3 and len(list_items(plines, 1)) == pn
                 and pmk == 1 and pdrift == 0 and not punres)
    if not parity_ok:
        ok = False

    k1 = _arm("<!-- enumerates: sk/*/SKILL.md list -->\nThe skills:\n\n- `alpha`\n- `beta`\n", _SK)
    k2 = _arm("<!-- enumerates: sk/*/SKILL.md count -->\nTwo skills.\n", _SK)
    keys_flag = sum(k[1] + len(k[2]) for k in (k1, k2))
    keys_seen = sum(k[0] for k in (k1, k2))
    if not (keys_flag == 0 and keys_seen == 2 and k1[0] == 1 and k2[0] == 1):
        ok = False
    gmk, gdrift, gunres = _arm("<!-- enumerates: pop/*.sh list -->\n" + _LIST_TWO,
                               ["pop/alpha.sh", "pop/alpha.sh", "pop/beta.sh"])
    guard_hits = sum(1 for u in gunres if u == "ambiguous-population")
    if not (gmk == 1 and guard_hits == 1 and gdrift == 0 and len(gunres) == 1):
        ok = False

    detail = ("count sens=%s spec=%s; list sens=%s spec=%s; subset-of sens=%s spec=%s; "
              "unresolved=%s; parity=%s; keys spec=%d/%d guard=%d/%d"
              % (c_sens, c_spec, l_sens, l_spec, s_sens, s_spec, unresolved,
                 "ok" if parity_ok else "FAIL", keys_flag, keys_seen, guard_hits, gmk))
    return ok, detail


# ── Fixtures ─────────────────────────────────────────────────────────────────
FIXTURE_HEADER_RE = re.compile(r"^--- (DRIFT|CLEAN|UNRESOLVED|SCOPE-OUT) (count|list|subset-of) (\S.*)$")


class FixtureError(Exception):
    pass


def parse_fixtures(text):
    cases, cur = [], None
    for n, raw in enumerate(text.split("\n"), 1):
        if cur is None:
            if not raw.strip() or raw.startswith("#"):
                continue
            m = FIXTURE_HEADER_RE.match(raw)
            if not m:
                raise FixtureError("line %d is neither a comment nor a case header: %r" % (n, raw[:60]))
            cur = {"expect": m.group(1), "rel": m.group(2), "label": m.group(3),
                   "population": None, "document": "fixture.md", "body": [], "line": n,
                   "in_body": False}
            continue
        if raw == "--- END":
            if cur["population"] is None:
                raise FixtureError("case at line %d has no POPULATION: line" % cur["line"])
            cases.append(cur)
            cur = None
            continue
        if not cur["in_body"] and raw.startswith("POPULATION:"):
            cur["population"] = raw[len("POPULATION:"):].split()
            continue
        if not cur["in_body"] and raw.startswith("DOCUMENT:"):
            cur["document"] = raw[len("DOCUMENT:"):].strip() or "fixture.md"
            continue
        cur["in_body"] = True
        cur["body"].append(raw)
    if cur is not None:
        raise FixtureError("case at line %d is not terminated by --- END" % cur["line"])
    if not cases:
        raise FixtureError("no case blocks")
    return cases


def run_fixtures(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            cases = parse_fixtures(fh.read())
    except (OSError, FixtureError) as exc:
        print("INPUT-FAILURE: the fixture file %s is unreadable: %s" % (path, exc), file=sys.stderr)
        return 3
    passed = 0
    for c in cases:
        markers, rows = evaluate("\n".join(c["body"]), c["document"], c["population"])
        nd = sum(1 for r in rows if r[0] == "DRIFT")
        nu = sum(1 for r in rows if r[0] == "UNRESOLVED")
        exp = c["expect"]
        good = ((exp == "DRIFT" and nd >= 1 and nu == 0)
                or (exp == "CLEAN" and markers >= 1 and not rows)
                or (exp == "UNRESOLVED" and nu >= 1 and nd == 0)
                or (exp == "SCOPE-OUT" and markers == 0))
        passed += 1 if good else 0
        print("%s  %s %s %s — markers=%d drift=%d unresolved=%d"
              % ("PASS" if good else "FAIL", exp, c["rel"], c["label"], markers, nd, nu))
        for r in rows:
            print("        " + " ".join(r[3:]))
    print("fixtures: %d/%d passed" % (passed, len(cases)))
    return 0 if passed == len(cases) else 1


# ── Corpus driver ────────────────────────────────────────────────────────────

def git_toplevel(root):
    try:
        out = subprocess.run(["git", "-C", root, "rev-parse", "--show-toplevel"],  # nosec B603 B607
                             capture_output=True, encoding="utf-8", errors="replace")
    except OSError:
        return None
    if out.returncode != 0:
        return None
    return out.stdout.strip() or None


def walk_candidates(root):
    out = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        rel_dir = os.path.relpath(dirpath, root)
        for f in filenames:
            rel = f if rel_dir == "." else os.path.join(rel_dir, f)
            out.append(rel.replace(os.sep, "/"))
    return sorted(out)


def _rel(root, p):
    """A requested document, as a root-relative posix path (an absolute path under the
    root is made relative; a leading `./` is dropped)."""
    p = p.strip()
    if os.path.isabs(p):
        r = os.path.relpath(os.path.realpath(p), os.path.realpath(root))
        if not r.startswith(".."):
            p = r
    p = p.replace(os.sep, "/")
    while p.startswith("./"):
        p = p[2:]
    return p


def main(argv=None):
    ap = argparse.ArgumentParser(description="Check 83 — enumeration <-> population drift")
    ap.add_argument("--root", default=".")
    ap.add_argument("--path", action="append", default=[])
    ap.add_argument("--paths-from")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--fixtures")
    mode.add_argument("--self-test", action="store_true")
    ap.add_argument("--output-format", choices=["tsv", "human"], default="human")
    args = ap.parse_args(argv)

    global C63
    try:
        C63 = load_c63()
    except Exception as exc:  # any failure to load the predicate is an input failure
        print("INPUT-FAILURE: cannot load the Check 63 structure predicate (%s)" % exc, file=sys.stderr)
        return 3

    if args.self_test:
        ok, detail = run_controls()
        print("self-test: controls %s — %s" % ("PASS" if ok else "FAIL", detail))
        return 0 if ok else 1
    if args.fixtures:
        return run_fixtures(args.fixtures)

    root = os.path.abspath(args.root)
    top = git_toplevel(root)
    if top is not None and os.path.realpath(top) == os.path.realpath(root):
        try:
            ls = subprocess.run(["git", "-C", root, "ls-files", "-z"],  # nosec B603 B607
                                capture_output=True, encoding="utf-8", errors="replace")
        except OSError as exc:
            print("INPUT-FAILURE: git ls-files could not run under a git root (%s)" % exc, file=sys.stderr)
            return 3
        if ls.returncode != 0:
            print("INPUT-FAILURE: git ls-files failed under a git root (exit %d)" % ls.returncode, file=sys.stderr)
            return 3
        candidates = sorted(p for p in ls.stdout.split("\0") if p)
    else:
        candidates = walk_candidates(root)

    requested = list(args.path)
    if args.paths_from:
        try:
            with open(args.paths_from, "r", encoding="utf-8") as fh:
                requested += [ln for ln in fh.read().split("\n") if ln.strip()]
        except OSError as exc:
            print("INPUT-FAILURE: the --paths-from file is unreadable (%s)" % exc, file=sys.stderr)
            return 3
    if requested or args.paths_from:
        docs = sorted({_rel(root, p) for p in requested})
    else:
        docs = [p for p in candidates if p.endswith(".md")]

    exempt = C63.EXEMPT_PREFIXES
    scoped = [p for p in docs if not p.startswith(exempt)]
    exempted = len(docs) - len(scoped)

    texts, unreadable = [], 0
    for rel in scoped:
        try:
            with open(os.path.join(root, rel), "r", encoding="utf-8", errors="replace") as fh:
                texts.append((rel, fh.read()))
        except OSError:
            unreadable += 1
    if not texts:
        print("INPUT-FAILURE: the requested scope resolved to zero readable files — "
              "refusing to report a clean zero over an empty population", file=sys.stderr)
        return 3

    controls_ok, controls_detail = run_controls()
    markers, rows = 0, []
    for rel, text in texts:
        mk, rr = evaluate(text, rel, candidates)
        markers += mk
        rows += rr
    n_drift = sum(1 for r in rows if r[0] == "DRIFT")
    n_unres = sum(1 for r in rows if r[0] == "UNRESOLVED")
    status, state = ("degraded", "DEGRADED") if unreadable else ("fetched", "-")

    if args.output_format == "tsv":
        print("SCOPE\tstatus=%s\tstate=%s\tfiles=%d\tread=%d\tunreadable=%d\texempted=%d"
              % (status, state, len(scoped), len(texts), unreadable, exempted))
        print("DENOM\tfiles=%d\tmarkers=%d\tresolved=%d\tunresolved=%d\tdrift=%d"
              % (len(texts), markers, markers - n_unres, n_unres, n_drift))
        print("CONTROL\t%s\t%s" % ("PASS" if controls_ok else "FAIL", controls_detail))
        for r in rows:
            print("\t".join(r))
    else:
        note = "" if state == "-" else " — DEGRADED, this is not a clean result"
        print("scope:       status=%s%s — files=%d read=%d unreadable=%d exempted=%d"
              % (status, note, len(scoped), len(texts), unreadable, exempted))
        print("denominator: files=%d markers=%d resolved=%d unresolved=%d drift=%d"
              % (len(texts), markers, markers - n_unres, n_unres, n_drift))
        print("controls:    %s — %s" % ("PASS" if controls_ok else "FAIL", controls_detail))
        for r in rows:
            if r[0] == "DRIFT":
                print("  DRIFT:      %s:%s %s %s — %s %s; %s; %s; %s" % r[1:])
            else:
                print("  UNRESOLVED: %s:%s — %s" % r[1:])
        print("summary: DRIFT=%d UNRESOLVED=%d" % (n_drift, n_unres))

    if not controls_ok:
        return 1
    return 1 if rows else 0


if __name__ == "__main__":
    sys.exit(main())

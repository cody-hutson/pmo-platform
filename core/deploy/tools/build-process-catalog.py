#!/usr/bin/env python3
"""build-process-catalog.py — the process catalog's generator.

PURPOSE
    Generates the catalog's index, graph and cross-cutting views from the pages,
    the definitions pack, the ID registry, the controls register and the
    element-kinds table; converts and re-resolves the pages' source anchors; and
    answers two queries — which pages a change touches, and which pages are stale.

    The generated files are a function of the checked-out tree alone: the list of
    tracked paths and the bytes of the files under the catalog root. No commit,
    date or staleness enters them. Staleness and impact are queries, never stored.
    The generator does not seed pages: a page is written by hand.

USAGE (every root is an argument — see --help — and none is read from the environment)
    build-process-catalog.py build [--out DIR]
    build-process-catalog.py build --check [--summary-file FILE]
    build-process-catalog.py anchors convert [PAGE...] [--refused demote|leave] [--list]
                                             [--worklist FILE] [--dry-run]
    build-process-catalog.py anchors resolve [PAGE...] (--check | --write)
                                             [--sources-changed-in A..B] [--summary-file FILE]
    build-process-catalog.py stale [PAGE...] [--fail-on depicts|any]
    build-process-catalog.py impact (--paths P... | --diff FILE|- | --range A..B) [--json] [--record]
    build-process-catalog.py coverage
    build-process-catalog.py data-flow-unmatched --to FILE
    build-process-catalog.py overlay --overlay-root DIR [--measure ID...] [--input NAME=PATH...]
                                     [--host live | --host-responses DIR] [--today YYYY-MM-DD]
    build-process-catalog.py overlay --show PAGE --overlay-root DIR
    build-process-catalog.py overlay --list
    build-process-catalog.py --self-test

    build            writes the page regions the generator owns (the navigation block; the derived
                     `lens_status` line on L0 and L1, and its floor on L2), then graph.json, views/
                     and INDEX.md. It computes everything first and writes all of it or nothing. It
                     removes a file only when the file carries this generator's `generated_by` line
                     and is no longer produced. With --out, generated files go to DIR and no page is
                     touched.
    build --check    writes nothing; reports every generated file that differs, is missing or is an
                     orphan, and every page whose owned region differs. The remedy is `build`.
    anchors convert  appends a source anchor to each bare line citation, fingerprinting the lines its
                     fragment names in the cited file as it stands at the page's
                     `last_verified_commit`. A citation it refuses is left as written, or with
                     --refused demote rewritten to a whole-file link and listed.
    anchors resolve  re-resolves every citation against the checked-out tree. --check writes nothing;
                     --write rewrites the fragment and `line` of each moved citation and nothing else.
    stale            lists each page's sources whose content changed since its verification commit.
    impact           the pages that depict or cite the changed paths, and the controls registered on
                     them; --record prints the one-line planning record.

    overlay          runs each registered measure on the inputs it is handed and writes its report to
                     `measures/<measure-id>.txt` under the overlay root, then `figures.json`. The
                     root has no default and must exist; it is refused inside a linked work tree,
                     and inside a main work tree unless git reports its files ignored. An input
                     that is not passed is not looked for: every measure that needs it reads
                     `not-evaluated`, which is not a zero. Exit 0 every selected measure measured,
                     1 a measure failed, 3 none failed and one was not evaluated. `--show` prints
                     the reports behind one page's evidence rows. `--list` prints the register and
                     the exact reference text a page carries for each measure; it needs no root,
                     starts nothing and prints no census. No other command reads the overlay.

OUTPUT
    One census line is the last line on standard output on exit 0, 1 and 3 alike. With
    `impact --json`, standard output is exactly one JSON document and the census is its
    `census` member.

EXIT CODES
    0  examined and clean
    1  findings
    2  usage (no census is printed: nothing ran)
    3  not evaluated — an input could not be read, or nothing was examined
"""
from __future__ import annotations

import argparse
import json
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

ROOT_NAMES = ("repo", "catalog", "definitions", "pack", "registry", "kinds", "probe_source", "measures", "measures_dir")
REFUSALS = ("repeated", "blank-edge", "out-of-range", "not-text", "path-absent")
NEEDS_A_PERSON = ("gone", "ambiguous", "path-missing")
NO_PAGES = "no page is discovered: the catalog holds no page of a published universe"
RECORD_EMPTY = "Current-state pages read: none — the catalog holds no pages yet"


class Stop(Exception):
    """Leave a command with a census: (exit code, pairs, lines to print first)."""

    def __init__(self, code, message="", pairs=None):
        self.code, self.message, self.pairs = code, message, pairs


def out(line: str = "") -> None:
    print(line)


def select_pages(cat: PC.Catalog, targets: list) -> list:
    """The pages a citation or staleness command reads: the targets, else every discovered page."""
    if targets:
        pages = []
        for target in targets:
            path = Path(target).resolve()
            if not path.is_file():
                raise PC.NotEvaluated("a target is not a file: %s" % target)
            pages.append(PC.load_page(path, cat.roots))
        return pages
    pages = [cat.pages[n] for n in sorted(cat.pages, key=cat.order.get)]
    if not pages:
        raise PC.NotEvaluated(NO_PAGES)
    return pages


def commit_must_exist(repo, sha: str, what: str) -> None:
    code, _out = PC.git_run(repo, "cat-file", "-e", "%s^{commit}" % sha) if re.match(r"^[0-9a-f]{40}$", sha or "") \
        else (1, b"")
    if code != 0:
        raise PC.NotEvaluated("the commit object %s names cannot be read" % what)


def blob_at(repo, sha: str, path: str):
    """The bytes of a path at a commit, or None when the path is absent there."""
    code, data = PC.git_run(repo, "cat-file", "blob", "%s:%s" % (sha, path))
    return data if code == 0 else None


def working_lines(repo, path: str):
    """(exists, lines or None) of a checked-out file."""
    target = Path(repo) / path
    if not target.is_file():
        return False, None
    try:
        return True, PC.source_lines(target.read_bytes())
    except OSError:
        return False, None


def changed_paths(repo, spec: str) -> list:
    if not re.match(r"^[^\s.][^\s]*\.\.[^\s.][^\s]*$", spec or ""):
        raise PC.NotEvaluated("the range %s is not of the form A..B" % spec)
    code, data = PC.git_run(repo, "diff", "--name-only", "-z", "--no-renames", spec)
    if code != 0:
        raise PC.NotEvaluated("the range %s does not resolve" % spec)
    paths = [p for p in data.decode("utf-8", "surrogateescape").split("\0") if p]
    if not paths:
        raise PC.NotEvaluated("the range %s changes no path" % spec)
    return paths


# ----------------------------------------------------------------------------------------------
# build
# ----------------------------------------------------------------------------------------------
def cmd_build(a, roots) -> tuple:
    cat = PC.Catalog(roots, a.controls)
    state = {"universes": len(cat.published_universes), "pages": len(cat.published), "generated_files": None,
             "differing": None, "missing": None, "orphans": None, "link_findings": None}
    pairs = lambda: list(state.items())    # noqa: E731
    if not cat.published:
        raise Stop(PC.EXIT_NOT_EVALUATED, NO_PAGES, pairs())
    surfaces = PC.Surfaces(cat)
    state["generated_files"] = len(surfaces.files)
    if surfaces.problems:
        for problem in surfaces.problems:
            out("FINDING: %s; nothing was written" % problem)
        return PC.EXIT_FINDINGS, pairs(), ["%d problem(s); nothing was written." % len(surfaces.problems)]
    root = roots.catalog_rel
    differing, missing, body = [], [], []
    for rel, text in sorted(surfaces.files.items()):
        path = roots.catalog / rel
        if not path.is_file():
            missing.append("%s/%s" % (root, rel))
        elif PC.read_text_strict(path, "the generated file %s/%s" % (root, rel)) != text:
            differing.append("%s/%s" % (root, rel))
    changed_pages = [n for n in sorted(surfaces.pages, key=cat.order.get) if surfaces.pages[n] != cat.published[n].text]
    orphans = PC.unexpected_files(cat, set(surfaces.files))
    marker = PC.generated_by_line()
    removable = []
    for rel in orphans:
        try:
            head = (roots.repo / rel).read_text(encoding="utf-8").split("\n")[:12]
        except (OSError, UnicodeDecodeError):
            head = []
        if marker in head and rel[len(root) + 1:].split("/")[0] not in cat.universes:
            removable.append(rel)
    if a.check:
        for rel in differing:
            out("differs: %s — run build" % rel)
        for rel in missing:
            out("missing: %s — run build" % rel)
        for n in changed_pages:
            out("differs: %s (a region the generator owns) — run build" % cat.published[n].rel)
        for rel in orphans:
            out("orphan: %s — nothing expects this file%s" % (rel, "; run build to remove it" if rel in removable else ""))
        links = link_findings(roots, [roots.catalog / rel for rel in surfaces.files if rel.endswith(".md")])
        state.update(differing=len(differing) + len(changed_pages), missing=len(missing), orphans=len(orphans),
                     link_findings=len(links))
        body = ["%d differing, %d missing, %d orphan(s), %d link finding(s)." % (
            state["differing"], len(missing), len(orphans), len(links))]
        body += ["- `%s` differs" % x for x in differing] + ["- `%s` is missing" % x for x in missing]
        body += ["- `%s` differs in a region the generator owns" % cat.published[n].rel for n in changed_pages]
        body += ["- `%s` is an orphan" % x for x in orphans]
        bad = state["differing"] or missing or orphans or links
        return (PC.EXIT_FINDINGS if bad else PC.EXIT_CLEAN), pairs(), body
    # write: everything is computed; now write all of it
    target = Path(a.out).resolve() if a.out else roots.catalog
    if not a.out:
        for n in changed_pages:
            PC.write_text(cat.published[n].path, surfaces.pages[n])
            out("wrote %s (regions the generator owns)" % cat.published[n].rel)
        for rel in removable:
            os.remove(roots.repo / rel)
            out("removed %s (generated earlier, no longer produced)" % rel)
        for rel in orphans:
            if rel not in removable:
                out("orphan: %s — nothing expects this file; it was left in place" % rel)
    for rel, text in sorted(surfaces.files.items()):
        path = target / rel
        if not (path.is_file() and path.read_bytes() == text.encode("utf-8")):
            PC.write_text(path, text)
            out("wrote %s" % (("%s/%s" % (root, rel)) if not a.out else rel))
    left = [] if a.out else [rel for rel in orphans if rel not in removable]
    links = [] if a.out else link_findings(roots, [target / rel for rel in surfaces.files if rel.endswith(".md")])
    state.update(differing=0, missing=0, orphans=len(left), link_findings=len(links))
    return (PC.EXIT_FINDINGS if left or links else PC.EXIT_CLEAN), pairs(), []


def link_findings(roots, paths: list) -> list:
    """The shared link checker's verdict on the generated Markdown that is on disk."""
    scan = PC.sibling(PC.LINK_CHECKER).scan_file
    found = []
    for path in paths:
        if path.is_file():
            for hit in scan(path, [], roots.repo):
                found.append(hit)
                out("link: %s:%d %s (%s)" % (roots.rel(path), hit["line"], hit["target"], hit["category"]))
    return found


# ----------------------------------------------------------------------------------------------
# anchors convert
# ----------------------------------------------------------------------------------------------
def cmd_convert(a, roots) -> tuple:
    cat = PC.Catalog(roots, a.controls, with_controls=False)
    pages = select_pages(cat, a.pages)
    counts = {"pages": len(pages), "bare": 0, "converted": 0, "demoted": 0, "left": 0, "differs": 0}
    worklist = ["page\tpage_line\tpath\told_line\treason\tlabel\tcheckout"]
    write = not (a.dry_run or a.list)
    for page in pages:
        cites = [c for c in PC.find_citations(page.body_lines()) if c.state == "bare"]
        if not cites:
            continue
        sha = page.get("last_verified_commit")
        commit_must_exist(roots.repo, sha, "the page %s" % page.rel)
        lines = list(page.lines)
        endings = page.text.splitlines(keepends=True)
        for cit in sorted(cites, key=lambda c: (c.line, c.start), reverse=True):
            counts["bare"] += 1
            data = blob_at(roots.repo, sha, cit.path)
            then = PC.source_lines(data) if data is not None else None
            _exists, now = working_lines(roots.repo, cit.path)
            reason, text = None, ""
            if data is None:
                reason = "path-absent"
            elif then is None:
                reason = "not-text"
            elif cit.last > len(then):
                reason = "out-of-range"
            else:
                text = PC.cited_text(then, cit.a, cit.b)
                if not then[cit.a - 1].strip() or not then[cit.last - 1].strip():
                    reason = "blank-edge"
                elif len(PC.places(then, cit.last - cit.a + 1, PC.fingerprint(text))) > 1:
                    reason = "repeated"
            same = bool(now) and then is not None and cit.last <= min(len(now), len(then)) and \
                PC.cited_text(now, cit.a, cit.b) == text and reason not in ("path-absent", "not-text", "out-of-range")
            checkout = "same" if same else "differs"
            if not same:
                counts["differs"] += 1
            line = lines[cit.line]
            if reason is None:
                counts["converted"] += 1
                if a.list:
                    out("\t".join([page.rel, str(cit.line + 1), cit.label, cit.path, cit.span,
                                   " ".join(text.split()), checkout]))
                lines[cit.line] = line[:cit.end] + PC.anchor_text(cit.a, cit.b, PC.fingerprint(text)) + line[cit.end:]
            else:
                worklist.append("\t".join([page.rel, str(cit.line + 1), cit.path, cit.span, reason, cit.label, checkout]))
                if a.refused == "demote" and reason != "path-absent":
                    counts["demoted"] += 1
                    lines[cit.line] = line[:cit.start] + "[%s](/%s)" % (cit.label, cit.path) + line[cit.end:]
                    if not a.list:
                        out("demoted: %s:%d /%s#L%s (%s)" % (page.rel, cit.line + 1, cit.path, cit.span.replace("-", "-L"), reason))
                else:
                    counts["left"] += 1
                    if not a.list:
                        out("refused: %s:%d /%s#L%s (%s)" % (page.rel, cit.line + 1, cit.path, cit.span.replace("-", "-L"), reason))
        if write and lines != page.lines:
            PC.write_text(page.path, rejoin(lines, page.lines, endings))
    if a.worklist:
        PC.write_text(Path(a.worklist).resolve(), "\n".join(worklist) + "\n")
    return (PC.EXIT_FINDINGS if counts["left"] else PC.EXIT_CLEAN), list(counts.items()), []


def rejoin(lines: list, before: list, kept: list) -> str:
    """The page text with each line replaced and every line ending kept exactly as it was. `before`
    is the page's lines without their endings and `kept` the same lines with them."""
    return "".join(new + whole[len(old):] for new, old, whole in zip(lines, before, kept))


# ----------------------------------------------------------------------------------------------
# anchors resolve
# ----------------------------------------------------------------------------------------------
def cmd_resolve(a, roots) -> tuple:
    cat = PC.Catalog(roots, a.controls, with_controls=False)
    pages = select_pages(cat, a.pages)
    only = set(changed_paths(roots.repo, a.sources_changed_in)) if a.sources_changed_in else None
    tally = {"current": 0, "moved": 0, "gone": 0, "ambiguous": 0, "other": 0}
    total, rewritten, needs, cache = 0, 0, [], {}
    for page in pages:
        lines = list(page.lines)
        endings = page.text.splitlines(keepends=True)
        for cit in sorted(PC.find_citations(page.body_lines()), key=lambda c: (c.line, c.start), reverse=True):
            if only is not None and cit.path not in only:
                continue
            total += 1
            state, start = cit.state, None
            if state == "anchored":
                if cit.path not in cache:
                    cache[cit.path] = working_lines(roots.repo, cit.path)
                exists, source = cache[cit.path]
                state, start = ("path-missing", None) if not exists else PC.resolve_citation(cit, source)
            if state == "moved" and a.write:
                last = start + cit.last - cit.a
                b = None if cit.b in (None, cit.a) else last
                line = lines[cit.line]
                label_end = line.index("](", cit.start)
                lines[cit.line] = (line[:label_end] + "](/%s%s)" % (cit.path, PC.fragment_text(start, b))
                                   + PC.anchor_text(start, b, cit.fp) + line[cit.end:])
                rewritten += 1
                state = "current"
                out("rewritten: %s:%d /%s %s -> %s" % (page.rel, cit.line + 1, cit.path, cit.span,
                                                        "%d" % start if b is None else "%d-%d" % (start, b)))
            tally[state if state in tally else "other"] += 1
            if state != "current":
                out("%s: %s:%d %s" % (state, page.rel, cit.line + 1,
                                      "/%s#L%s" % (cit.path, cit.span.replace("-", "-L")) if cit.path else "a citation that does not parse"))
                if state != "moved":
                    needs.append((page.rel, page.get("owner") or "—", cit.path or "—", state))
        if a.write and lines != page.lines:
            PC.write_text(page.path, rejoin(lines, page.lines, endings))
    pairs = [("pages", len(pages)), ("citations", total)] + list(tally.items()) + [("rewritten", rewritten)]
    if only is not None:
        bad = any(state in NEEDS_A_PERSON for _p, _o, _c, state in needs)
    else:
        bad = total != tally["current"]
    body = ["%d citation(s): %s; %d rewritten." % (total, ", ".join("%d %s" % (v, k) for k, v in tally.items()), rewritten)]
    if needs:
        body += ["", "| Page | Owner | Cited path | State |", "|---|---|---|---|"]
        body += ["| `%s` | %s | `%s` | %s |" % row for row in needs]
    return (PC.EXIT_FINDINGS if bad else PC.EXIT_CLEAN), pairs, body


# ----------------------------------------------------------------------------------------------
# stale
# ----------------------------------------------------------------------------------------------
def page_changes(cat: PC.Catalog, page: PC.Page) -> list:
    """[(reason, path)] for every source of a page whose blob at its verification commit differs
    from the checked-out file, or that is absent on either side. Content, not history: a change
    that was reverted is not a change, and ancestry is never read."""
    roots = cat.roots
    sha = page.get("last_verified_commit")
    commit_must_exist(roots.repo, sha, "the page %s" % page.rel)
    then_paths = [p for p in PC.git(roots.repo, "ls-tree", "-r", "--name-only", "-z", sha)
                  .decode("utf-8", "surrogateescape").split("\0") if p]
    then = PC.Tracked(roots.repo, paths=then_paths)
    now = cat.sources(page)
    depicted = list(dict.fromkeys(now["depicts"] + PC.expand_entries(page.items("depicts"), then, roots.catalog_rel)))
    linked = [m.group("path") for _i, m in PC.root_links(page)]
    cited = [f for f in dict.fromkeys(now["cites"] + PC.expand_entries(linked, then, roots.catalog_rel))
             if f not in set(depicted)]
    changes = []
    for reason, files in (("depicts", depicted), ("cites", cited)):
        for f in files:
            code, old = PC.git_run(roots.repo, "rev-parse", "--verify", "-q", "%s:%s" % (sha, f))
            old = old.decode("ascii", "replace").strip() if code == 0 else None
            path = roots.repo / f
            new = PC.git(roots.repo, "hash-object", "--", str(path)).decode("ascii").strip() if path.is_file() else None
            if old != new:
                changes.append((reason, f))
    return changes, len(depicted) + len(cited)


def cmd_stale(a, roots) -> tuple:
    cat = PC.Catalog(roots, a.controls, with_controls=False)
    pages = select_pages(cat, a.pages)
    sources = depicted_changed = cited_changed = 0
    for page in pages:
        changes, n = page_changes(cat, page)
        sources += n
        for reason, f in changes:
            if reason == "depicts":
                depicted_changed += 1
                out("%s: STALE depicts %s" % (page.id, f))
            else:
                cited_changed += 1
                out("%s: changed cites %s" % (page.id, f))
    bad = depicted_changed or (a.fail_on == "any" and cited_changed)
    return (PC.EXIT_FINDINGS if bad else PC.EXIT_CLEAN), [
        ("pages", len(pages)), ("sources", sources), ("depicted_changed", depicted_changed),
        ("cited_changed", cited_changed), ("fail_on", a.fail_on)], []


# ----------------------------------------------------------------------------------------------
# impact
# ----------------------------------------------------------------------------------------------
def diff_paths(text: str) -> list:
    paths = []
    for line in text.split("\n"):
        m = re.match(r"^diff --git a/(.+) b/(.+)$", line)
        if m:
            paths += [m.group(1), m.group(2)]
            continue
        m = re.match(r"^(?:---|\+\+\+) [ab]/(.+?)\s*$", line) or re.match(r"^rename (?:from|to) (.+?)\s*$", line)
        if m:
            paths.append(m.group(1))
    return list(dict.fromkeys(paths))


def path_hits(key: str, changed: str) -> bool:
    """A changed path hits a path exactly, as a folder of it, or as a file under it."""
    return key == changed or key.startswith(changed + "/") or changed.startswith(key + "/")


def cmd_impact(a, roots) -> tuple:
    state = {"paths": None, "unmatched": None, "pages": None, "hit_depicts": None, "hit_cites": None,
             "hit_controls": None}
    doc = {"paths": [], "pages": [], "controls": [], "unmatched": []}
    lines = []

    def finish(code, message=""):
        pairs = list(state.items())
        if message:
            doc["not_evaluated"] = message
        if a.json:
            doc["census"] = PC.census("impact", code, pairs)
            sys.stdout.write(json.dumps(doc, indent=2, sort_keys=True, ensure_ascii=False) + "\n")
            return code, None, []
        for line in lines:
            out(line)
        if message:
            out("NOT-EVALUATED: %s" % message)
        return code, pairs, []

    try:
        cat = PC.Catalog(roots, a.controls)
        if a.paths is not None:
            paths, from_git = [PC.clean_entry(p) for p in a.paths if p.strip()], False
            if not paths:
                raise PC.NotEvaluated("no path was given")
        elif a.diff is not None:
            text = sys.stdin.read() if a.diff == "-" else PC.read_text_strict(a.diff, "the diff")
            if not text.strip():
                raise PC.NotEvaluated("the diff is empty")
            paths, from_git = diff_paths(text), True
            if not paths:
                raise PC.Usage("no path could be read from the diff")
        else:
            paths, from_git = changed_paths(roots.repo, a.range), True
        state["paths"] = len(paths)
        if not cat.published:
            if a.record and not a.json:
                lines.append(RECORD_EMPTY)
            doc["record"] = RECORD_EMPTY if a.record else None
            raise PC.NotEvaluated(NO_PAGES)
        surfaces = PC.Surfaces(cat)
        graph = PC.build_graph(surfaces)
        root = roots.catalog_rel
        row_sources = {r["control_id"]: [p.strip() for p in r["source_path"].split(";") if p.strip()] for r in cat.controls}
        named = set(graph["depicted_by"]) | set(graph["cited_by"]) | {p for v in row_sources.values() for p in v}
        hits, controls, unmatched = {}, {}, []
        for path in paths:
            doc["paths"].append({"path": path, "kind": PC.classify_path(path, cat.kinds)})
            if PC.in_catalog(path, root):
                continue                                   # a valid answer with no page: no catalog file is a source
            known = bool(cat.tracked.expand(path)) or any(path_hits(k, path) for k in named)
            if not from_git and not known:
                unmatched.append(path)
                continue
            for reason, index in (("depicts", graph["depicted_by"]), ("cites", graph["cited_by"])):
                for key, ids in index.items():
                    if path_hits(key, path):
                        for nid in ids:
                            hits.setdefault(nid, [])
                            if (reason, path) not in hits[nid]:
                                hits[nid].append((reason, path))
            for cid, sources in sorted(row_sources.items()):
                if any(path_hits(src, path) for src in sources):
                    controls.setdefault(cid, set()).add(path)
        for cid, changed in sorted(controls.items()):
            citing = sorted(surfaces.cites.get(cid, {}), key=cat.order.get)
            doc["controls"].append({"id": cid, "paths": sorted(changed), "pages": citing})
            for nid in citing:
                for path in sorted(changed):
                    hits.setdefault(nid, [])
                    if ("control-source", path) not in hits[nid]:
                        hits[nid].append(("control-source", path))
        state.update(unmatched=len(unmatched), pages=len(hits),
                     hit_depicts=sum(1 for v in hits.values() if any(r == "depicts" for r, _p in v)),
                     hit_cites=sum(1 for v in hits.values() if any(r == "cites" for r, _p in v)),
                     hit_controls=len(controls))
        doc["unmatched"] = unmatched
        for path in unmatched:
            lines.append("unmatched: %s" % path)
        cited_controls = {}
        for cid, by_page in surfaces.cites.items():
            for nid in by_page:
                cited_controls.setdefault(nid, []).append(cid)
        for nid in sorted(hits, key=cat.order.get):
            page = cat.published[nid]
            entry = {"id": nid, "status": page.status, "last_verified_commit": page.get("last_verified_commit"),
                     "reasons": [{"reason": r, "path": p} for r, p in hits[nid]], "parent": cat.parent_of(nid),
                     "downstream": cat.children(nid), "controls": sorted(cited_controls.get(nid, []))}
            doc["pages"].append(entry)
            lines.append("%s (%s) parent=%s downstream=%s controls=%s" % (
                nid, "; ".join("%s %s" % rp for rp in hits[nid]), entry["parent"] or "—",
                ",".join(entry["downstream"]) or "—", ",".join(entry["controls"]) or "—"))
        for item in doc["controls"]:
            lines.append("control %s on %s: cited by %s" % (item["id"], ", ".join(item["paths"]), ", ".join(item["pages"]) or "no page"))
        if a.record:
            record = record_lines(cat, hits, len(paths))
            doc["record"] = "\n".join(record)
            lines += record
        if unmatched:
            raise PC.NotEvaluated("a path given is not tracked and is named by no page and no register row: %s"
                                  % ", ".join(unmatched))
        return finish(PC.EXIT_CLEAN)
    except PC.NotEvaluated as e:
        return finish(PC.EXIT_NOT_EVALUATED, str(e))


def record_lines(cat: PC.Catalog, hits: dict, probed: int) -> list:
    """The planning record. It cites active pages that depict an affected file, with `STALE` where a
    depicted file changed; it cites the successor of a superseded page; and it lists any other
    covering page on a second line as not cited, with its status."""
    covering = [n for n in sorted(hits, key=cat.order.get) if any(r == "depicts" for r, _p in hits[n])]
    cited, others = [], []
    for nid in covering:
        page = cat.published[nid]
        if page.status == "SUPERSEDED":
            for successor in page.items("superseded_by"):
                if successor in cat.published and successor not in cited:
                    cited.append(successor)
            others.append("%s (SUPERSEDED)" % nid)
        elif page.status == "ACTIVE":
            if nid not in cited:
                cited.append(nid)
        else:
            others.append("%s (%s)" % (nid, page.status or "no status"))
    if not cited:
        record = ["Current-state pages read: none — no page covers the area (%d pages scanned, %d affected files probed)"
                  % (len(cat.published), probed)]
    else:
        parts = []
        for nid in cited:
            page = cat.published[nid]
            stale = any(reason == "depicts" for reason, _f in page_changes(cat, page)[0])
            parts.append("%s @ %s%s" % (nid, page.get("last_verified_commit"), " STALE" if stale else ""))
        record = ["Current-state pages read: " + ", ".join(parts)]
    if others:
        record.append("Covering pages not cited: " + ", ".join(others))
    return record


# ----------------------------------------------------------------------------------------------
# coverage and the unmatched data-flow listing
# ----------------------------------------------------------------------------------------------
def cmd_coverage(a, roots) -> tuple:
    cat = PC.Catalog(roots, a.controls, with_controls=False)
    if not cat.published:
        raise Stop(PC.EXIT_NOT_EVALUATED, NO_PAGES)
    depicted = {f for page in cat.published.values() for f in cat.sources(page)["depicts"]}
    table = {}
    files = [f for f in cat.tracked.files if not PC.in_catalog(f, roots.catalog_rel)]
    for f in files:
        row = table.setdefault(PC.classify_path(f, cat.kinds), [0, 0])
        row[0 if f in depicted else 1] += 1
    out("kind\tdepicted\tnot_depicted")
    for kind in PC.kind_order(cat.kinds):
        if kind in table:
            out("%s\t%d\t%d" % (kind, table[kind][0], table[kind][1]))
    return PC.EXIT_CLEAN, [("kinds", len(table)), ("paths", len(files)),
                           ("depicted", sum(1 for f in files if f in depicted))], []


def cmd_unmatched(a, roots) -> tuple:
    target = Path(a.to).resolve()
    catalog = os.path.realpath(roots.catalog)
    if os.path.commonpath([catalog, os.path.realpath(target)]) == catalog:
        raise PC.Usage("--to names a file inside the catalog; the listing is never a catalog file")
    cat = PC.Catalog(roots, a.controls, with_controls=False)
    if not cat.published:
        raise Stop(PC.EXIT_NOT_EVALUATED, NO_PAGES)
    _blocks, _summary, _tail, unmatched, total = PC.data_flow(PC.Surfaces(cat))
    rows = ["universe\tpage\tlocation\tside\treason\tnormalized\tas_written"]
    rows += ["\t".join(re.sub(r"[\t\n]", " ", str(x)) for x in row) for row in unmatched]
    PC.write_text(target, "\n".join(rows) + "\n")
    return PC.EXIT_CLEAN, [("kinds", len({row[4] for row in unmatched})), ("paths", total),
                           ("depicted", total - len(unmatched))], []


# ----------------------------------------------------------------------------------------------
# overlay — the per-install figures. The one command that runs a measure, and the one command that
# can start a program other than `git`: `--host live` starts the host client. No other command of
# this tool reads the overlay, starts a measure or reads the host.
#
# Nothing is resolved from the surroundings. The overlay root is an argument with no default; an
# input that was not passed is not looked for; a host read happens only when `--host` asks for it.
# ----------------------------------------------------------------------------------------------
HOST_CLIENT = "gh"
ORIGIN_FORMS = (
    re.compile(r"^https?://(?P<host>[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)/(?P<owner>[^/\s:@]+)/(?P<name>[^/\s:@]+?)(?:\.git)?/?$"),
    re.compile(r"^ssh://[A-Za-z0-9_-]+@(?P<host>[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)/(?P<owner>[^/\s:@]+)/(?P<name>[^/\s:@]+?)(?:\.git)?/?$"),
    re.compile(r"^[A-Za-z0-9_-]+@(?P<host>[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+):(?P<owner>[^/\s:@]+)/(?P<name>[^/\s:@]+?)(?:\.git)?/?$"),
)
RUN_KEYS = ("event", "conclusion", "status", "created")
RUNS_FILTER = "{workflow_runs: [.workflow_runs[] | {event, conclusion, status, created_at}]}"
LOG_KEYS = ("created", "head", "log")
EVENT_ROW = re.compile(r"^\| [0-9]{4}-")
SLUG_KEY = re.compile(r"^[a-z0-9][a-z0-9.-]*[a-z0-9]$")
LEGACY_KEY = re.compile(r"^v[0-9]")
DATED_FOLDER = re.compile(r"-[0-9]{4}-[0-9]{2}-[0-9]{2}$")
SUMMARY_FILE = "SUMMARY.md"
OVERLAY_MEASURES, OVERLAY_INDEX = "measures", "figures.json"


class MeasureFailed(Exception):
    """A measure that cannot be run to a report: the reason is one of PC.MEASURE_REASONS."""


def parse_origin(address: str):
    """(host, owner, name) of an origin address in one of three forms — a web scheme, the long
    secure-shell form, the short secure-shell form — with a host that contains a dot, exactly two
    path segments and no credentials. Any other shape gives None."""
    for form in ORIGIN_FORMS:
        m = form.match(address.strip())
        if m:
            return m.group("host"), m.group("owner"), m.group("name")
    return None


def reduced_runs(records, what: str) -> list:
    """Run records in the reduced form: a list of objects with exactly the four keys."""
    if not isinstance(records, list) or any(not isinstance(r, dict) or sorted(r) != sorted(RUN_KEYS) for r in records):
        raise PC.NotEvaluated("%s is not in the reduced form: a list of objects with the keys %s and no other"
                              % (what, ", ".join(RUN_KEYS)))
    return records


def runs_text(records: list) -> str:
    rows = sorted("\t".join(str(r[k] or "") for k in RUN_KEYS) for r in records)
    return "".join(row + "\n" for row in rows)


class HostFiles:
    """The host as a folder of reduced-form files: `<kind>--<argument>.json`,
    `host-milestone-titles.json` and `host-tag-names.json`. A file that is absent, holds a key
    outside the reduced form or carries the synthetic mark is not evaluated, naming it."""

    name = "responses"

    def __init__(self, folder, allow_mark: bool = False):
        self.folder, self.allow_mark = Path(folder), allow_mark

    def load(self, file_name: str):
        what = "the host response %s" % file_name
        text = PC.read_text_strict(self.folder / file_name, what)
        if PC.SYNTHETIC_MARK in text and not self.allow_mark:
            raise PC.NotEvaluated("%s carries the synthetic mark; a fixture is not an input" % what)
        try:
            return json.loads(text)
        except ValueError:
            raise PC.NotEvaluated("%s is not JSON" % what)

    def runs(self, workflow: str, params: dict, today: str) -> list:
        name = "%s--%s.json" % (PC.RUN_HISTORY_KIND, workflow)
        return reduced_runs(self.load(name), "the host response %s" % name)

    def latest_log(self, workflow: str, events: list) -> dict:
        name = "host-latest-run-log--%s.json" % workflow
        data = self.load(name)
        if not isinstance(data, dict) or any(not isinstance(v, dict) or sorted(v) != sorted(LOG_KEYS) for v in data.values()):
            raise PC.NotEvaluated("the host response %s is not in the reduced form: per event, the keys %s and no other"
                                  % (name, ", ".join(LOG_KEYS)))
        return data

    def names(self, which: str) -> list:
        name = "host-%s.json" % which
        data = self.load(name)
        if not isinstance(data, list) or any(not isinstance(x, str) for x in data):
            raise PC.NotEvaluated("the host response %s is not a list of names" % name)
        return data


class HostLive:
    """The host, read through the host client. The owner and repository come from the origin
    address by one strict grammar and are passed to the client only; they are never printed or
    stored. `call` is the one function that starts the client; the self-test passes a stub."""

    name = "live"

    def __init__(self, repo, call=None):
        self.call = call or self.client
        code, out = PC.git_run(repo, "remote", "get-url", "origin")
        self.origin = parse_origin(out.decode("utf-8", "replace")) if code == 0 else None

    @staticmethod
    def client(args: list):
        try:
            proc = subprocess.run([HOST_CLIENT] + list(args), capture_output=True)
        except OSError:
            return None
        return proc.stdout.decode("utf-8", "replace") if proc.returncode == 0 else None

    def api(self, path: str, pages: bool = False, keep: str = ""):
        """One read through the host client. `keep` is a filter the client applies to each page, so
        only the fields a measure may receive leave the client."""
        if self.origin is None:
            raise MeasureFailed("host-not-read")
        host, owner, name = self.origin
        out = self.call(["api", "--hostname", host] + (["--paginate"] if pages else [])
                        + (["--jq", keep] if keep else []) + ["repos/%s/%s/%s" % (owner, name, path)])
        if out is None:
            raise MeasureFailed("host-not-read")
        documents, decoder, at = [], json.JSONDecoder(), 0
        try:
            while at < len(out.rstrip()):
                document, at = decoder.raw_decode(out, at + len(out[at:]) - len(out[at:].lstrip()))
                documents.append(document)
        except ValueError:
            raise MeasureFailed("host-not-read")
        if pages:
            return documents
        if len(documents) != 1:
            raise MeasureFailed("host-not-read")
        return documents[0]

    def runs(self, workflow: str, params: dict, today: str) -> list:
        """The trailing window, read in slices. The host's total for a slice is read first; rows
        that differ from it in number fail the measure."""
        import datetime
        window, step = int(params.get("window_days", 0)), int(params.get("slice_days", 0))
        if window < 1 or step < 1:
            raise MeasureFailed("error:params")
        end = datetime.date.fromisoformat(today)
        first, records = end - datetime.timedelta(days=window - 1), []
        while first <= end:
            last = min(first + datetime.timedelta(days=step - 1), end)
            base = "actions/workflows/%s/runs?created=%s..%s" % (workflow, first.isoformat(), last.isoformat())
            total = self.api(base + "&per_page=1", keep="{total_count}").get("total_count", 0)
            rows = [r for page in (self.api(base + "&per_page=100", pages=True, keep=RUNS_FILTER) if total else [])
                    for r in page.get("workflow_runs", [])]
            if len(rows) != total:
                raise MeasureFailed("host-total-differs")
            records += [{"event": r.get("event"), "conclusion": r.get("conclusion"), "status": r.get("status"),
                         "created": (r.get("created_at") or "")[:10]} for r in rows]
            first = last + datetime.timedelta(days=1)
        return records

    def latest_log(self, workflow: str, events: list) -> dict:
        out = {}
        for event in events:
            found = self.api("actions/workflows/%s/runs?event=%s&per_page=1" % (workflow, event)).get("workflow_runs", [])
            if not found:
                continue
            host, owner, name = self.origin
            log = self.call(["run", "view", str(found[0].get("id")), "--repo", "%s/%s/%s" % (host, owner, name), "--log"])
            if log is None:
                raise MeasureFailed("host-not-read")
            out[event] = {"created": (found[0].get("created_at") or "")[:10], "head": found[0].get("head_sha") or "", "log": log}
        return out

    def names(self, which: str) -> list:
        path, key = {"milestone-titles": ("milestones?state=all&per_page=100", "title"),
                     "tag-names": ("tags?per_page=100", "name")}[which]
        return [row.get(key) or "" for page in self.api(path, pages=True) for row in page]


def kept_event_rows(text: str, titles: list, tags: list) -> str:
    """The event-log population rule. A row is kept when its release key is this repository's by a
    positive check: a slug key equal to a milestone title on the host, or a legacy version key equal
    to a tag name on the host. Every other row is excluded — a foreign slug, a row keyed by a
    milestone number only, a placeholder, an unkeyed row — and no count of them is kept. The rule
    holds no repository name and no date."""
    kept = []
    for line in text.split("\n"):
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not EVENT_ROW.match(line) or len(cells) < 10:
            continue
        key = cells[1]
        if LEGACY_KEY.match(key):
            keep = key in tags
        else:
            keep = bool(key) and bool(SLUG_KEY.match(key)) and key in titles
        if keep:
            kept.append(line.rstrip("\r"))
    return "".join(row + "\n" for row in kept)


def summary_block(folder: Path) -> str:
    """The frontmatter block of a dated folder's summary file, and nothing else under the folder."""
    path = folder / SUMMARY_FILE
    if not path.is_file():
        return ""
    lines = PC.read_text_strict(path, "a summary file of the analysis home").split("\n")
    if not lines or lines[0].strip() != "---":
        return ""
    block = []
    for line in lines[1:]:
        if line.strip() == "---":
            return "".join(x + "\n" for x in block)
        block.append(line)
    return ""


def passed_inputs(specs) -> dict:
    """`--input NAME=PATH` values by name. A name outside the list is a usage error; a path that
    was passed and cannot be read, or that carries the synthetic mark, is not evaluated."""
    given = {}
    for spec in specs or []:
        name, sep, value = spec.partition("=")
        if not sep or name not in PC.INPUT_NAMES or name in given or not value:
            raise PC.Usage("--input takes NAME=PATH once for each of: %s" % ", ".join(sorted(PC.INPUT_NAMES)))
        path = Path(os.path.realpath(value))
        if name == "analysis-home":
            if not path.is_dir():
                raise PC.NotEvaluated("the input %s is not a folder that can be read" % name)
        else:
            if PC.SYNTHETIC_MARK in PC.read_text_strict(path, "the input %s" % name):
                raise PC.NotEvaluated("the input %s carries the synthetic mark; a fixture is not an input" % name)
        given[name] = path
    return given


def resolve_inputs(measure, roots, tracked, given: dict, host, today: str, cache: dict) -> dict:
    """What one measure is handed: {register entry: [(label, text)]}. Raises MeasureFailed with the
    reason when an input is unavailable; the measure is then not started."""
    handed = {}
    for kind, arg, entry in measure.inputs:
        if kind == "tracked":
            handed[entry] = [(rel, PC.read_text_strict(roots.repo / rel, "the tracked input %s" % rel))
                             for rel in PC.tracked_matches(tracked, arg)]
        elif kind in (PC.RUN_HISTORY_KIND, "host-latest-run-log"):
            if host is None:
                raise MeasureFailed("host-not-read")
            if entry not in cache:
                if kind == PC.RUN_HISTORY_KIND:
                    cache[entry] = [(arg, runs_text(reduced_runs(host.runs(arg, measure.params, today), "a host read")))]
                else:
                    wanted = measure.params.get("events") or []
                    logs = host.latest_log(arg, [wanted] if isinstance(wanted, str) else list(wanted))
                    cache[entry] = [(event, "created %s\nhead %s\n%s" % (v["created"], v["head"], v["log"]))
                                    for event, v in sorted(logs.items())]
            handed[entry] = cache[entry]
        elif kind == "event-log-rows":
            if "event-log" not in given:
                raise MeasureFailed("input-not-passed")
            if host is None:
                raise MeasureFailed("host-not-read")
            if entry not in cache:
                titles, tags = host.names("milestone-titles"), host.names("tag-names")
                if not titles or not tags:
                    raise MeasureFailed("empty-host-set")
                cache[entry] = [("event-log", kept_event_rows(
                    PC.read_text_strict(given["event-log"], "the input event-log"), titles, tags))]
            handed[entry] = cache[entry]
        elif kind == "analysis-folder-summaries":
            if "analysis-home" not in given:
                raise MeasureFailed("input-not-passed")
            if entry not in cache:
                cache[entry] = [(p.name, summary_block(p)) for p in sorted(given["analysis-home"].iterdir())
                                if p.is_dir() and DATED_FOLDER.search(p.name)]
            handed[entry] = cache[entry]
    return handed


def git_folders(folder):
    """(git folder, common folder, top level) of the work tree a folder lies in, each resolved; or
    None when the folder lies in no work tree."""
    code, out = PC.git_run(folder, "rev-parse", "--git-dir", "--git-common-dir", "--show-toplevel")
    lines = out.decode("utf-8", "replace").strip().split("\n")
    if code != 0 or len(lines) != 3:
        return None
    resolve = lambda x: os.path.realpath(x if os.path.isabs(x) else os.path.join(str(folder), x))   # noqa: E731
    return resolve(lines[0]), resolve(lines[1]), resolve(lines[2])


def overlay_root(roots, value) -> Path:
    """The overlay root, tested before anything is written. It has no default. It is resolved
    first, so every test below reads the folder the files would land in and not a link to it. It
    must exist: the command creates the measures folder and the index inside it and nothing above
    it. It is refused when it lies inside a linked work tree of any repository; when it lies inside
    a main work tree and git does not report as ignored both the index file and a file under the
    measures folder; or when the command runs from a linked work tree and the root lies in that
    repository's main work tree. A root outside every work tree is accepted."""
    if not value:
        raise PC.Usage("overlay needs --overlay-root DIR; the root has no default")
    root = Path(os.path.realpath(value))
    if not root.is_dir():
        raise PC.NotEvaluated("the overlay root does not exist: %s (the command creates no root)" % value)
    place = git_folders(root)
    if place is None:
        return root
    git_dir, common, _top = place
    if git_dir != common:
        raise PC.NotEvaluated("the overlay root lies inside a linked work tree: %s (name a folder outside every "
                              "work tree)" % value)
    own = git_folders(roots.repo)
    if own is not None and own[0] != own[1] and own[1] == common:
        raise PC.NotEvaluated("this run is from a linked work tree and the overlay root lies in the main work tree: "
                              "%s (name a folder outside every work tree)" % value)
    for probe in (root / OVERLAY_INDEX, root / OVERLAY_MEASURES / "probe.txt"):
        if PC.git_run(root, "check-ignore", "-q", "--", str(probe))[0] != 0:
            raise PC.NotEvaluated("the overlay root lies inside a work tree and %s under it is not ignored: %s"
                                  % (probe.relative_to(root).as_posix(), value))
    return root


def write_atomic(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_bytes(data)
    os.replace(temporary, path)


def run_overlay(roots, root: Path, selected, given: dict, host, today: str, synthetic: bool = False,
                layers=None) -> tuple:
    """Run the selected measures into the root. `synthetic` and `layers` are the self-test's seam;
    no command-line argument reaches them. Returns (exit code, census pairs, lines)."""
    import datetime
    import hashlib
    tracked = PC.Tracked(roots.repo)
    measures = PC.load_measures(roots, tracked)
    known = {m.id: m for m in measures}
    for wanted in selected or []:
        if wanted not in known:
            raise PC.Usage("--measure names no registered measure: %s" % wanted)
    chosen = [m for m in measures if not selected or m.id in selected]
    digest = lambda text: hashlib.sha256(text.encode("utf-8")).hexdigest()   # noqa: E731
    cache, index, lines, counts = {}, {}, [], {"measured": 0, "not-evaluated": 0, "failed": 0}
    for m in chosen:
        target = root / OVERLAY_MEASURES / (m.id + ".txt")
        entry = {"script": m.script, "input_class": m.input_class, "status": "", "reason": None, "sha256": None,
                 "bytes": None, "inputs": []}
        try:
            handed = resolve_inputs(m, roots, tracked, given, host, today, cache)
        except MeasureFailed as e:
            reason = str(e)
            entry["status"] = "failed" if reason.startswith(("host-total-differs", "error")) else "not-evaluated"
            entry["reason"] = reason
            handed = None
        if handed is not None:
            entry["inputs"] = [{"kind": key, "files": len(pairs), "sha256": digest("\0".join(t for _l, t in pairs))}
                               for key, pairs in sorted(handed.items())]
            source = PC.read_text_strict(roots.repo / m.script_rel, "the measure file %s" % m.script_rel)
            status, reason, report = PC.run_measure(source, m.script, handed, dict(m.params, today=today), layers=layers)
            entry["status"], entry["reason"] = status, reason or None
            if status == "measured":
                if synthetic:
                    report = PC.SYNTHETIC_MARK + "\n" + report
                write_atomic(target, report.encode("utf-8"))
                entry["sha256"], entry["bytes"] = digest(report), len(report.encode("utf-8"))
        if entry["status"] != "measured" and target.is_file():
            target.unlink()
        counts[entry["status"]] += 1
        index[m.id] = entry
        lines.append("%s: %s%s" % (m.id, entry["status"], " (%s)" % entry["reason"] if entry["reason"] else ""))
    code, head = PC.git_run(roots.repo, "rev-parse", "--short", "HEAD")
    figures = {"schema_version": 1,
               "generated_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
               "today": today, "head": head.decode("ascii", "replace").strip() if code == 0 else None,
               "dirty": bool(PC.git(roots.repo, "status", "--porcelain").strip()),
               "host": host.name if host is not None else "none", "measures": index}
    if synthetic:
        figures["synthetic"] = True
    write_atomic(root / OVERLAY_INDEX, (json.dumps(figures, indent=2, sort_keys=True) + "\n").encode("utf-8"))
    exit_code = PC.EXIT_FINDINGS if counts["failed"] else PC.EXIT_NOT_EVALUATED if counts["not-evaluated"] \
        else PC.EXIT_CLEAN
    if not chosen:
        exit_code = PC.EXIT_NOT_EVALUATED
    pairs = [("measures", len(chosen)), ("measured", counts["measured"]), ("not_evaluated", counts["not-evaluated"]),
             ("failed", counts["failed"])]
    return exit_code, pairs, lines


def evidence_rows(page: PC.Page, measures: list, pack: dict) -> list:
    """(row number, cited measures, marker line or None) for each Evidence row that cites a
    registered measure or carries a held marker."""
    cols = pack["tables"].get("Evidence", [])
    source_col = cols.index("Source") if "Source" in cols else 1
    rows = []
    for n, cells in enumerate(page.rows("Evidence"), start=1):
        source = cells[source_col] if len(cells) > source_col else ""
        cited = [m for m in measures if m.reference in source]
        marker = next((k for k in PC.HELD_MARKERS if k in source), None)
        if cited or marker:
            rows.append((n, cited, PC.carry(source) if marker and not cited else None))
    return rows


def cmd_overlay(a, roots) -> tuple:
    if a.list:
        try:
            for m in PC.load_measures(roots):
                out("%s\t%s\t%s" % (m.id, m.input_class, m.script))
                out("  " + m.reference)
        except PC.NotEvaluated as e:
            out("NOT-EVALUATED: %s" % e)
            return PC.EXIT_NOT_EVALUATED, None, []
        return PC.EXIT_CLEAN, None, []
    if a.host and a.host_responses:
        raise PC.Usage("overlay takes --host live or --host-responses DIR, not both")
    root = overlay_root(roots, a.overlay_root)
    if a.show:
        cat = PC.Catalog(roots, getattr(a, "controls", None))
        page = cat.pages[a.show] if a.show in cat.pages else select_pages(cat, [a.show])[0]
        index_path = root / OVERLAY_INDEX
        if not index_path.is_file():
            raise PC.NotEvaluated("the overlay root holds no index; run `overlay` into it first")
        try:
            index = json.loads(PC.read_text_strict(index_path, "the overlay index"))
        except ValueError:
            raise PC.NotEvaluated("the overlay index is not JSON")
        if index.get("synthetic"):
            out(PC.SYNTHETIC_MARK)
        counts = {"measured": 0, "not-evaluated": 0, "failed": 0}
        shown = 0
        for n, cited, marker in evidence_rows(page, PC.load_measures(roots, cat.tracked), cat.pack):
            if marker is not None:
                out("row %d: %s" % (n, marker))
                continue
            for m in cited:
                entry = index.get("measures", {}).get(m.id) or {"status": "not-evaluated", "reason": "not-run"}
                status = entry.get("status") if entry.get("status") in counts else "not-evaluated"
                counts[status] += 1
                shown += 1
                out("row %d: measure %s: %s%s" % (n, m.id, status, " (%s)" % entry["reason"] if entry.get("reason") else ""))
                report = root / OVERLAY_MEASURES / (m.id + ".txt")
                if status == "measured" and report.is_file():
                    for line in PC.read_text_strict(report, "a report of the overlay").rstrip("\n").split("\n"):
                        out("    " + line)
        code = PC.EXIT_FINDINGS if counts["failed"] else PC.EXIT_NOT_EVALUATED if counts["not-evaluated"] else PC.EXIT_CLEAN
        return code, [("measures", shown), ("measured", counts["measured"]), ("not_evaluated", counts["not-evaluated"]),
                      ("failed", counts["failed"])], []
    import datetime
    today = a.today or datetime.datetime.now(datetime.timezone.utc).date().isoformat()
    try:
        datetime.date.fromisoformat(today)
    except ValueError:
        raise PC.Usage("--today takes a date as YYYY-MM-DD")
    given = passed_inputs(a.input)
    host = HostLive(roots.repo) if a.host == "live" else HostFiles(a.host_responses) if a.host_responses else None
    code, pairs, lines = run_overlay(roots, root, a.measure, given, host, today)
    for line in lines:
        out(line)
    return code, pairs, []


# ----------------------------------------------------------------------------------------------
# The entry point
# ----------------------------------------------------------------------------------------------
GATES = {"build": "generated-output", "convert": "conversion", "resolve": "citations", "stale": "staleness",
         "impact": "impact", "coverage": "coverage", "data-flow-unmatched": "coverage", "overlay": "overlay"}
EMPTY = {
    "generated-output": ("universes", "pages", "generated_files", "differing", "missing", "orphans", "link_findings"),
    "conversion": ("pages", "bare", "converted", "demoted", "left", "differs"),
    "citations": ("pages", "citations", "current", "moved", "gone", "ambiguous", "other", "rewritten"),
    "staleness": ("pages", "sources", "depicted_changed", "cited_changed", "fail_on"),
    "impact": ("paths", "unmatched", "pages", "hit_depicts", "hit_cites", "hit_controls"),
    "coverage": ("kinds", "paths", "depicted"),
    "overlay": ("measures", "measured", "not_evaluated", "failed"),
}


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(description="Generate the process catalog's index, graph and views; convert and "
                                             "re-resolve source anchors; answer impact and staleness queries.",
                                 allow_abbrev=False)
    PC.add_root_arguments(ap, ROOT_NAMES)
    ap.add_argument("--controls", metavar="PATH", help="the controls register, in place of the pack's pointer")
    ap.add_argument("--self-test", action="store_true")
    sub = ap.add_subparsers(dest="command")

    def command(parent, name, **kw):
        p = parent.add_parser(name, allow_abbrev=False, **kw)
        for root, _parent, _part, flag in PC.DEFAULTS:
            if root in ROOT_NAMES:
                p.add_argument(flag, dest="root_" + root, default=argparse.SUPPRESS, metavar="PATH", help=argparse.SUPPRESS)
        p.add_argument("--controls", default=argparse.SUPPRESS, metavar="PATH", help=argparse.SUPPRESS)
        return p

    p = command(sub, "build", help="write the generated files, or with --check compare them")
    p.add_argument("--check", action="store_true")
    p.add_argument("--out", metavar="DIR")
    p.add_argument("--summary-file", metavar="FILE")
    anchors = sub.add_parser("anchors", help="convert or re-resolve source anchors").add_subparsers(dest="anchors_command")
    p = command(anchors, "convert")
    p.add_argument("pages", nargs="*", metavar="PAGE")
    p.add_argument("--refused", choices=["demote", "leave"], default="leave")
    p.add_argument("--list", action="store_true")
    p.add_argument("--worklist", metavar="FILE")
    p.add_argument("--dry-run", action="store_true")
    p = command(anchors, "resolve")
    p.add_argument("pages", nargs="*", metavar="PAGE")
    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--write", action="store_true")
    p.add_argument("--sources-changed-in", metavar="A..B")
    p.add_argument("--summary-file", metavar="FILE")
    p = command(sub, "stale", help="list each page's sources that changed since its verification commit")
    p.add_argument("pages", nargs="*", metavar="PAGE")
    p.add_argument("--fail-on", choices=["depicts", "any"], default="depicts")
    p = command(sub, "impact", help="the pages and controls a change touches")
    source = p.add_mutually_exclusive_group(required=True)
    source.add_argument("--paths", nargs="+", metavar="P")
    source.add_argument("--diff", metavar="FILE")
    source.add_argument("--range", metavar="A..B")
    p.add_argument("--json", action="store_true")
    p.add_argument("--record", action="store_true")
    command(sub, "coverage", help="per element kind, tracked files depicted and not")
    p = command(sub, "data-flow-unmatched", help="write the unmatched data-flow items to a file outside the catalog")
    p.add_argument("--to", required=True, metavar="FILE")
    p = command(sub, "overlay", help="run the registered measures into a per-install overlay, show it, or list the register")
    p.add_argument("--overlay-root", metavar="DIR", help="the folder the figures are written to; it has no default")
    p.add_argument("--measure", action="append", metavar="ID", help="run this measure only; repeatable")
    p.add_argument("--input", action="append", metavar="NAME=PATH", help="event-log=FILE or analysis-home=DIR")
    p.add_argument("--host", choices=["live"], help="read this repository's records from its host")
    p.add_argument("--host-responses", metavar="DIR", help="read the host's records from reduced-form files")
    p.add_argument("--today", metavar="YYYY-MM-DD", help="the run date handed to each measure (default: today, UTC)")
    p.add_argument("--show", metavar="PAGE", help="print the figures behind one page's evidence rows; writes nothing")
    p.add_argument("--list", action="store_true", help="print the register and each measure's reference text")
    return ap


def main(argv=None) -> int:
    ap = build_parser()
    a = ap.parse_args(argv)
    if a.self_test:
        return self_test()
    name = a.command
    if name == "anchors":
        name = a.anchors_command
    if name is None:
        ap.error("a command is required")
    if name == "build" and a.check and a.out:
        ap.error("build --check takes no --out")
    if name == "resolve" and a.sources_changed_in and not a.check:
        ap.error("--sources-changed-in is read with --check")
    gate = GATES[name]
    summary = getattr(a, "summary_file", None)
    handler = {"build": cmd_build, "convert": cmd_convert, "resolve": cmd_resolve, "stale": cmd_stale,
               "impact": cmd_impact, "coverage": cmd_coverage, "data-flow-unmatched": cmd_unmatched,
               "overlay": cmd_overlay}[name]
    empty = [(k, getattr(a, "fail_on", None) if k == "fail_on" else None) for k in EMPTY[gate]]
    body = []
    try:
        code, pairs, body = handler(a, PC.resolve_roots(a))
    except PC.Usage as e:
        print("usage error: %s" % e, file=sys.stderr)
        return PC.EXIT_USAGE
    except (PC.NotEvaluated, Stop) as e:
        message = e.message if isinstance(e, Stop) else str(e)
        if isinstance(e, Stop) and e.pairs:
            empty = e.pairs
        if name == "impact" and a.json:
            sys.stdout.write(json.dumps({"not_evaluated": message, "census": PC.census(gate, PC.EXIT_NOT_EVALUATED, empty)},
                                        indent=2, sort_keys=True) + "\n")
            return PC.EXIT_NOT_EVALUATED
        out("NOT-EVALUATED: %s" % message)
        code, pairs, body = PC.EXIT_NOT_EVALUATED, empty, ["Not evaluated: %s." % message]
    if pairs is None:                      # impact --json has printed its one document
        return code
    PC.write_summary(summary, gate, PC.SUMMARY_STATUS[code], "see the census line", body)
    out(PC.census(gate, code, pairs))
    return code


# ----------------------------------------------------------------------------------------------
# Self-test — hermetic: temporary repositories built from the fixture tree and nothing else.
# ----------------------------------------------------------------------------------------------
EXPECTED_FILES = ["INDEX.md", "graph.json", "views/controls-cited.md", "views/controls-overview.md",
                  "views/controls-prose-rule.md", "views/data-flow.md", "views/interfaces.md", "views/jobs.md",
                  "views/state.md", "views/structure.md"]


def self_test() -> int:
    import contextlib
    import io
    arms = PC.Arms()
    tool = str(Path(__file__).resolve())
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(os.path.realpath(td))
        PC.isolate_git(tmp)

        def roots_of(fx):
            return ["--repo", str(fx.repo), "--catalog-root", str(fx.catalog), "--definitions", str(fx.definitions)]

        def call(args):
            buf = io.StringIO()
            with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(io.StringIO()):
                try:
                    code = main(list(args))
                except SystemExit as e:
                    code = e.code
            text = buf.getvalue()
            return code, (text.rstrip("\n").split("\n") if text.strip() else [])

        def cli(args, tool_path=tool, env=None, cwd=None):
            proc = subprocess.run([sys.executable, "-B", tool_path] + list(args), capture_output=True, text=True,
                                  env=env, cwd=cwd or str(tmp))
            return proc.returncode, (proc.stdout.rstrip("\n").split("\n") if proc.stdout.strip() else []), proc.stderr

        def tree(folder):
            folder = Path(folder)
            return {p.relative_to(folder).as_posix(): p.read_bytes() for p in sorted(folder.rglob("*")) if p.is_file()}

        def generated(fx):
            found = [n for n in (PC.INDEX_NAME, PC.GRAPH_NAME) if (fx.catalog / n).is_file()]
            return sorted(found + ["%s/%s" % (PC.VIEWS_FOLDER, p.name) for p in (fx.catalog / PC.VIEWS_FOLDER).glob("*")])

        def census_of(lines):
            return dict(t.split("=", 1) for t in lines[-1].split(" ")[2:]) if lines else {}

        fx = PC.build_fixture_repo(tmp / "repo")
        G = roots_of(fx)
        rules_src = fx.layout["sources"] + "/fixture-rules.md.txt"
        script_src = fx.layout["sources"] + "/fixture-script.sh.txt"

        # -- build: the literal expected list, and one mutant per emitter --
        code, lines = call(G + ["build"])
        arms.check("build: exit 0 on the fixture corpus", code == 0, lines[-3:])
        arms.check("build: the emitted paths equal the literal expected list", generated(fx) == EXPECTED_FILES, generated(fx))
        arms.check("build: the census is the last line, with 1 universe, 8 pages and 10 generated files",
                   lines[-1] == "process-catalog generated-output status=pass exit=0 universes=1 pages=8 "
                   "generated_files=10 differing=0 missing=0 orphans=0 link_findings=0", lines[-1:])
        for emitter in PC.EMITTERS:
            target = tmp / ("mutant-" + emitter)
            PC.DISABLED_EMITTERS.add(emitter)
            try:
                call(G + ["build", "--out", str(target)])
            finally:
                PC.DISABLED_EMITTERS.clear()
            missing = sorted(set(EXPECTED_FILES) - set(tree(target)))
            arms.check("emission mutant: with the %s emitter disabled the expected-list arm fails, naming %s"
                       % (emitter, ", ".join(missing) or "nothing"), bool(missing))
        whole = tmp / "whole"
        call(G + ["build", "--out", str(whole)])
        arms.check("emission mutant: the unmutated build to a folder emits the whole list (the control)",
                   sorted(tree(whole)) == EXPECTED_FILES)
        PC.commit_all(fx.repo, "built")

        # -- build --check, idempotence, and one deleted surface at a time --
        code, lines = call(G + ["build", "--check"])
        arms.check("build --check: clean after build", code == 0 and census_of(lines).get("differing") == "0", lines[-2:])
        code, lines = call(G + ["build"])
        arms.check("build: a second run writes nothing", code == 0 and not any(l.startswith("wrote") for l in lines), lines)
        for rel in EXPECTED_FILES:
            path = fx.catalog / rel
            saved = path.read_bytes()
            path.unlink()
            code, lines = call(G + ["build", "--check"])
            path.write_bytes(saved)
            arms.check("build --check: %s deleted is exit 1, naming it" % rel,
                       code == 1 and any(l.startswith("missing: ") and l.split(" ")[1].endswith(rel) for l in lines), lines[-2:])
        path = fx.catalog / "views" / "state.md"
        saved = path.read_bytes()
        path.write_bytes(saved + b"hand edit\n")
        code, lines = call(G + ["build", "--check"])
        path.write_bytes(saved)
        arms.check("build --check: a hand-edited generated file is exit 1", code == 1 and census_of(lines)["differing"] == "1")

        # -- the generated content --
        files = tree(fx.catalog)
        texts = {k: v.decode("utf-8") for k, v in files.items() if k in EXPECTED_FILES}
        graph = json.loads(texts["graph.json"])
        nodes = {n["id"]: n for n in graph["nodes"]}
        arms.check("content: no emitted byte holds the temporary folder's path",
                   not any(str(tmp) in t or td in t for t in texts.values()))
        arms.check("content: generated Markdown opens with the platform frontmatter, status ACTIVE, and names its generator",
                   all(t.startswith("---\ntitle: ") and "\nstatus: ACTIVE\n" in t and "\n" + PC.generated_by_line() + "\n" in t
                       for k, t in texts.items() if k.endswith(".md")))
        arms.check("content: no source-anchor comment and no root link reaches a generated file",
                   not any("source-anchor" in t or "](/" in t for t in texts.values()))
        arms.check("content: a source path in a view is a code span", "`%s`" % rules_src in texts["views/structure.md"])
        arms.check("content: the graph carries the three inbound indexes, keyed by path, and no catalog path",
                   rules_src in graph["depicted_by"] and script_src in graph["cited_by"]
                   and script_src in graph["documented_by"]
                   and not any(PC.in_catalog(k, fx.layout["catalog"]) for index in ("depicted_by", "cited_by")
                               for k in graph[index]), sorted(graph["cited_by"]))
        later = nodes["fixture-process-later"]
        arms.check("unpublished node: in the graph with published false and no path",
                   later["published"] is False and later["path"] is None and later["status"] is None)
        arms.check("unpublished node: an edge to it is kept and marked",
                   any(e["type"] == "precedes" and e["to"] == "fixture-process-later" and e["target_published"] is False
                       for e in graph["edges"]))
        pages_text = "\n".join(p.read_text(encoding="utf-8") for p in (fx.catalog / PC.FIXTURE_UNIVERSE).glob("*.md"))
        arms.check("unpublished node: absent from every navigation block, from the index and from every view's links",
                   "fixture-process-later.md" not in pages_text and "fixture-process-later" not in texts["INDEX.md"]
                   and not any("[fixture-process-later](" in t for t in texts.values()))
        arms.check("unpublished universe: no line in the index and no generated file",
                   "fixture-far" not in texts["INDEX.md"] and not any("fixture-far" in k for k in files))
        arms.check("index: one heading per published universe, one bullet per value stream with its sub-process counts, "
                   "and one line per view",
                   "## [Fixture landscape](fixture-landscape/fixture-landscape.md)" in texts["INDEX.md"]
                   and "- [Fixture stream](fixture-landscape/fixture-stream.md) · 5 sub-processes (1 with a page)" in texts["INDEX.md"]
                   and texts["INDEX.md"].count("](views/") == 8, texts["INDEX.md"])
        arms.check("draft mark: directly after the draft page's link in a view cell, and in no page",
                   "[fixture-activity-flow](../fixture-landscape/fixture-activity-flow.md) (DRAFT)" in texts["views/structure.md"]
                   and "(DRAFT)" not in pages_text)
        arms.check("zero-row sections are omitted, and a kind with no row has no view",
                   "External system roles" not in texts["views/interfaces.md"] and "External triggers" in texts["views/interfaces.md"]
                   and "views/controls-ci-job.md" not in files)
        arms.check("state view: the stage chain of the pack's stage stream, the status-label machine and the page lifecycle",
                   all(h in texts["views/state.md"] for h in ("## Release — stages", "## Work item — status labels",
                                                               "## Process page — lifecycle")))
        nav = (fx.page("fixture-process")).read_text(encoding="utf-8")
        arms.check("navigation: Up, Down and no unpublished sibling",
                   "Up: [fixture-stream](fixture-stream.md)" in nav and "Down: [fixture-activity-plain](fixture-activity-plain.md)" in nav
                   and "Next:" not in nav, nav[nav.find("<!-- nav:begin"):][:300])

        # -- the regions the generator owns: sensitivity, and the roll-up --
        def edit(nid, old, new, count=1):
            page = fx.page(nid)
            text = page.read_text(encoding="utf-8")
            assert text.count(old) >= 1, (nid, old)
            page.write_text(text.replace(old, new, count), encoding="utf-8")
            return text

        saved = edit("fixture-process", "Up: [fixture-stream](fixture-stream.md)", "Up: somewhere else")
        code, lines = call(G + ["build", "--check"])
        arms.check("navigation: a hand-edited block is reported by build --check",
                   code == 1 and any("fixture-process.md" in l and l.startswith("differs:") for l in lines), lines)
        call(G + ["build"])
        arms.check("navigation: build restores the block and changes no other byte",
                   fx.page("fixture-process").read_text(encoding="utf-8") == saved)
        saved = edit("fixture-stream", "lens_status: deviates", "lens_status: conformant")
        code, lines = call(G + ["build", "--check"])
        arms.check("roll-up: an L1 value that is not the derived one is reported", code == 1 and any("fixture-stream.md" in l for l in lines))
        call(G + ["build"])
        arms.check("roll-up: build writes the derived value on that one line",
                   fx.page("fixture-stream").read_text(encoding="utf-8") == saved)
        l3_saved = edit("fixture-activity-plain", "lens_status: conformant", "lens_status: deviates")
        code, lines = call(G + ["build", "--check"])
        arms.check("roll-up: an L2 page under a deviating activity is reported — its floor is unmet",
                   code == 1 and any("fixture-process.md" in l for l in lines), lines)
        call(G + ["build"])
        raised = fx.page("fixture-process").read_text(encoding="utf-8")
        arms.check("roll-up: build raises the L2 page to deviates", "\nlens_status: deviates\n" in raised)
        fx.page("fixture-activity-plain").write_text(l3_saved, encoding="utf-8")
        code, lines = call(G + ["build", "--check"])
        arms.check("roll-up: with no deviating activity the L2 page keeps its own value — build never lowers it",
                   not any("fixture-process.md" in l for l in lines), lines)
        fx.page("fixture-process").write_text(raised.replace("\nlens_status: deviates\n", "\nlens_status: conformant\n", 1), encoding="utf-8")
        call(G + ["build"])
        arms.check("roll-up: the corpus is back to its built state", call(G + ["build", "--check"])[0] == 0)

        # -- page status on the generated surfaces --
        saved = edit("fixture-stream", "status: ACTIVE", "status: SUPERSEDED")
        l3_saved = edit("fixture-activity-spans", "status: ACTIVE", "status: DEPRECATED")
        call(G + ["build", "--out", str(tmp / "out-status")])
        marked = tree(tmp / "out-status")
        fx.page("fixture-stream").write_text(saved, encoding="utf-8")
        fx.page("fixture-activity-spans").write_text(l3_saved, encoding="utf-8")
        status_graph = {n["id"]: n for n in json.loads(marked["graph.json"])["nodes"]}
        arms.check("page status: a superseded page is marked in the index, directly after its link",
                   b"- [Fixture stream](fixture-landscape/fixture-stream.md) (superseded) " in marked["INDEX.md"])
        arms.check("page status: a deprecated page is omitted from every view and keeps its status in the graph",
                   not any(b"fixture-activity-spans.md" in data for name, data in marked.items() if name.endswith(".md"))
                   and status_graph["fixture-activity-spans"]["status"] == "DEPRECATED"
                   and b"fixture-activity-spans.md" in files["views/structure.md"])

        # -- determinism: two processes, and a second repository with the same tree --
        outs = []
        for n, (seed, zone) in enumerate((("1", "UTC"), ("4242", "Pacific/Auckland"))):
            home = tmp / ("home-%d" % n)
            home.mkdir()
            env = dict(os.environ, PYTHONHASHSEED=seed, HOME=str(home), TZ=zone, LC_ALL="C" if n else "en_US.UTF-8")
            target = tmp / ("out-%d" % n)
            code, lines, _err = cli(G + ["build", "--out", str(target)], env=env, cwd=str(home))
            outs.append(tree(target))
        arms.check("determinism: two processes with another hash seed, working folder, home, zone and locale emit the same bytes",
                   outs[0] == outs[1] and sorted(outs[0]) == EXPECTED_FILES)
        other = tmp / "another-place" / "clone-of-nothing"
        PC.write_text(other / "unrelated.txt", "an unrelated first commit\n")
        PC.git(other, *(PC.TEST_IDENTITY + ("init", "-q")))
        PC.commit_all(other, "unrelated")
        (other / "unrelated.txt").unlink()
        tracked = [p for p in PC.git(fx.repo, "ls-files", "-z").decode("utf-8").split("\0") if p]
        for rel in tracked:
            PC.write_text(other / rel, (fx.repo / rel).read_text(encoding="utf-8"))
        PC.git(other, "-c", "user.name=Another Author", "-c", "user.email=another.invalid", "-c", "commit.gpgsign=false",
               "-c", "core.hooksPath=" + os.devnull, "checkout", "-q", "-b", "side")
        PC.git(other, "add", "-A")
        PC.git(other, "-c", "user.name=Another Author", "-c", "user.email=another.invalid", "-c", "commit.gpgsign=false",
               "-c", "core.hooksPath=" + os.devnull, "commit", "-q", "-m", "the same tree")
        PC.git(other, "remote", "add", "never-contacted", "file:///nowhere/at/all")
        same_tree = PC.git(other, "rev-parse", "HEAD^{tree}") == PC.git(fx.repo, "rev-parse", "HEAD^{tree}")
        arms.check("second repository: its head commit has the first repository's tree ID", same_tree)
        other_args = ["--repo", str(other), "--catalog-root", str(other / fx.layout["catalog"]),
                      "--definitions", str(other / fx.layout["definitions"])]
        code, lines, _err = cli(other_args + ["build", "--out", str(tmp / "out-other")],
                                env=dict(os.environ, PYTHONHASHSEED="77", TZ="Asia/Kolkata", LC_ALL="C"), cwd=str(other.parent))
        arms.check("second repository: another folder, branch, identity and history emit byte-identical output",
                   code == 0 and tree(tmp / "out-other") == outs[0])
        victim = other / fx.layout["catalog"] / PC.FIXTURE_UNIVERSE / "fixture-stream.md"
        victim.write_text(victim.read_text(encoding="utf-8").replace("title: Fixture stream", "title: Fixture streaM"), encoding="utf-8")
        cli(other_args + ["build", "--out", str(tmp / "out-other-2")])
        arms.check("second repository: one byte changed in one page and the output differs (the control)",
                   tree(tmp / "out-other-2") != outs[0])

        # -- one reader, by behaviour --
        real = PC.read_frontmatter

        def stub(path):
            keys, status = real(path)
            return dict(keys, title="Sentinel title"), status
        PC.read_frontmatter = stub
        try:
            call(G + ["build", "--out", str(tmp / "out-stub")])
        finally:
            PC.read_frontmatter = real
        stubbed = json.loads((tmp / "out-stub" / "graph.json").read_text(encoding="utf-8"))
        arms.check("single reader: with the shared reader's function replaced, every published node's title follows the stub",
                   all(n["title"] == "Sentinel title" for n in stubbed["nodes"] if n["published"])
                   and any(n["published"] for n in stubbed["nodes"]))

        # -- impact --
        def impact(*args):
            code, lines = call(G + ["impact"] + list(args))
            return code, lines, census_of(lines)

        code, lines, c = impact("--paths", rules_src)
        arms.check("impact: a depicted file returns its page and that page's parent",
                   code == 0 and any(l.startswith("fixture-activity-plain (depicts ") and "parent=fixture-process" in l for l in lines), lines)
        arms.check("impact: the controls registered on the path are returned with the pages that cite them",
                   c.get("hit_controls") == "2" and any(l.startswith("control C-001 on ") and "fixture-activity-plain" in l for l in lines), lines)
        readme = fx.layout["fixtures"] + "/README.md"
        code, lines, c = impact("--paths", readme)
        arms.check("impact: a file no page depicts returns no page (the discrimination arm: expected 0)",
                   code == 0 and c.get("pages") == "0" and c.get("hit_depicts") == "0", lines)
        code, lines, c = impact("--paths", fx.layout["sources"])
        arms.check("impact: a folder hits the files beneath it", code == 0 and int(c.get("hit_depicts", 0)) >= 5, lines[-1:])
        code, lines, c = impact("--paths", script_src)
        arms.check("impact: a page that links a file without depicting it is listed, marked cites",
                   any(l.startswith("fixture-process (cites ") for l in lines) and c.get("hit_cites") == "1", lines)
        diff = tmp / "rename.diff"
        diff.write_text("diff --git a/%s b/moved/elsewhere.txt\nsimilarity index 100%%\nrename from %s\nrename to moved/elsewhere.txt\n"
                        % (rules_src, rules_src), encoding="utf-8")
        code, lines, c = impact("--diff", str(diff))
        arms.check("impact: a rename in a diff hits the pages that depict the old path, and the new path is never unmatched",
                   code == 0 and c.get("paths") == "2" and c.get("unmatched") == "0" and int(c.get("hit_depicts", 0)) >= 5, lines[-1:])
        code, lines, c = impact("--paths", "no/such/path.txt")
        arms.check("impact: a path that is not tracked and that nothing names is printed as unmatched and the run is exit 3",
                   code == 3 and "unmatched: no/such/path.txt" in lines and c.get("unmatched") == "1", lines)
        code, lines, c = impact("--paths", fx.roots().rel(fx.page("fixture-process")))
        arms.check("impact: a catalog path is a valid answer with no page", code == 0 and c.get("pages") == "0", lines)
        code, lines, c = impact("--range", "%s..HEAD" % fx.base)
        arms.check("impact: a range whose changed paths are all catalog files is a valid answer with no page",
                   code == 0 and c.get("pages") == "0" and int(c.get("paths", 0)) > 0, lines[-1:])
        code, lines, c = impact("--range", "HEAD..HEAD")
        arms.check("impact: a range that changes no path is exit 3", code == 3 and c.get("status", "not-evaluated"), lines)
        empty_diff = tmp / "empty.diff"
        empty_diff.write_text("", encoding="utf-8")
        arms.check("impact: an empty diff is exit 3", impact("--diff", str(empty_diff))[0] == 3)
        empty_diff.write_text("some text that names no path\n", encoding="utf-8")
        arms.check("impact: a diff from which no path parses is a usage exit", impact("--diff", str(empty_diff))[0] == 2)
        buf_code, buf_lines = call(G + ["impact", "--paths", rules_src, "--json"])
        try:
            doc = json.loads("\n".join(buf_lines))
        except ValueError:
            doc = {}
        arms.check("impact --json: standard output is one JSON document and the census is its member",
                   buf_code == 0 and doc.get("census", "").startswith("process-catalog impact status=pass exit=0 paths=1 ")
                   and any(p["id"] == "fixture-activity-plain" and p["reasons"][0] == {"reason": "depicts", "path": rules_src}
                           for p in doc.get("pages", [])), buf_lines[-3:])
        code, lines, c = impact("--paths", rules_src, "--record")
        arms.check("impact --record: active covering pages are cited at their verification commit; a draft is listed, not cited",
                   any(l.startswith("Current-state pages read: ") and "fixture-activity-plain @ %s" % fx.base in l
                       and "STALE" not in l and "fixture-activity-flow" not in l for l in lines)
                   and any(l.startswith("Covering pages not cited: fixture-activity-flow (DRAFT)") for l in lines), lines)
        code, lines, c = impact("--paths", readme, "--record")
        arms.check("impact --record: the no-page form counts pages scanned and files probed",
                   "Current-state pages read: none — no page covers the area (8 pages scanned, 1 affected files probed)" in lines, lines)

        # -- staleness: content, not history --
        script = fx.repo / script_src
        script_text = script.read_text(encoding="utf-8")

        def stale(*args):
            code, lines = call(G + ["stale"] + list(args))
            return code, lines, census_of(lines)

        code, lines, c = stale()
        arms.check("stale: nothing changed, exit 0, every page counted", code == 0 and c.get("pages") == "8" and c.get("depicted_changed") == "0", lines)
        script.write_text(script_text + "# a change after verification\n", encoding="utf-8")
        code, lines, c = stale()
        arms.check("stale: the page that depicts the changed file reads stale; pages that depict only unchanged files do not",
                   code == 1 and "fixture-activity-spans: STALE depicts %s" % script_src in lines
                   and not any(l.startswith("fixture-activity-plain:") for l in lines) and c.get("depicted_changed") == "1", lines)
        code, lines, c = stale(str(fx.page("fixture-process")))
        arms.check("stale: a changed cited file with an unchanged depicted one is printed, counted and exit 0",
                   code == 0 and "fixture-process: changed cites %s" % script_src in lines and c.get("cited_changed") == "1"
                   and c.get("fail_on") == "depicts", lines)
        code, lines, c = stale(str(fx.page("fixture-process")), "--fail-on", "any")
        arms.check("stale --fail-on any: the same state is exit 1", code == 1 and c.get("fail_on") == "any" and c.get("pages") == "1", lines)
        code, lines, c = impact("--paths", script_src, "--record")
        arms.check("impact --record: a page whose depicted file changed is cited with STALE",
                   any("fixture-activity-spans @ %s STALE" % fx.base in l for l in lines), lines)
        PC.commit_all(fx.repo, "the change, committed")
        script.write_text(script_text, encoding="utf-8")
        PC.commit_all(fx.repo, "the change, reverted")
        arms.check("stale: a change that was committed and then reverted is not stale — ancestry is never read", stale()[0] == 0)
        script.unlink()
        code, lines, c = stale()
        arms.check("stale: a depicted file that is absent now reads stale", code == 1 and c.get("depicted_changed") == "1", lines)
        code, lines = call(G + ["build", "--check"])
        arms.check("unrelated deletion: a deleted depicted source leaves build --check at exit 0 with a non-zero census",
                   code == 0 and census_of(lines).get("pages") == "8", lines[-1:])
        script.write_text(script_text, encoding="utf-8")
        saved = edit("fixture-activity-plain", fx.base, "1" * 40)
        code, lines, c = stale()
        arms.check("stale: a verification commit that cannot be read is exit 3", code == 3 and c.get("status") == "not-evaluated", lines[-2:])
        fx.page("fixture-activity-plain").write_text(saved, encoding="utf-8")

        # -- orphans, the number-sign guard, the pack document, coverage, the unmatched listing --
        stale_view = fx.catalog / "views" / "an-old-view.md"
        PC.write_text(stale_view, PC.generated_header("An old view", "left by an earlier run") + "# An old view\n")
        stray = fx.catalog / "stray-file.txt"
        stray.write_text("not generated\n", encoding="utf-8")
        code, lines = call(G + ["build", "--check"])
        arms.check("orphans: a view no longer produced and a stray file at the catalog root are both reported",
                   code == 1 and census_of(lines).get("orphans") == "2", lines)
        call(G + ["build", "--out", str(tmp / "out-orphans")])
        arms.check("orphans: under --out nothing is removed", stale_view.is_file() and stray.is_file())
        code, lines = call(G + ["build"])
        arms.check("orphans: build removes the file that carries its own mark, leaves the other and reports it",
                   code == 1 and not stale_view.exists() and stray.is_file() and census_of(lines).get("orphans") == "1", lines)
        stray.unlink()
        arms.check("orphans: with the stray file gone the corpus is clean", call(G + ["build", "--check"])[0] == 0)
        before = tree(fx.catalog)
        saved = edit("fixture-process", "a fixture input record exists", "a fixture input record, see item #12, exists")
        code, lines = call(G + ["build"])
        arms.check("number sign: build is exit 1, names the page the text came from, and writes nothing",
                   code == 1 and any("page fixture-process" in l for l in lines)
                   and {k: v for k, v in tree(fx.catalog).items() if k in EXPECTED_FILES} == {k: v for k, v in before.items() if k in EXPECTED_FILES},
                   lines)
        fx.page("fixture-process").write_text(saved, encoding="utf-8")
        document = fx.definitions / fx.layout["pack_document"]
        doc_text = document.read_text(encoding="utf-8")
        clean = call(G + ["build", "--check"])
        document.write_text(doc_text.replace("<!-- rule-codes:end -->\n", ""), encoding="utf-8")
        arms.check("pack document: a defect in it changes neither the exit nor the census of build --check",
                   call(G + ["build", "--check"]) == clean and clean[0] == 0)
        document.write_text(doc_text, encoding="utf-8")
        code, lines = call(G + ["coverage"])
        arms.check("coverage: rows per element kind, the census last",
                   code == 0 and lines[0] == "kind\tdepicted\tnot_depicted" and lines[-1].startswith("process-catalog coverage status=pass exit=0 kinds=")
                   and any(l.startswith("fixture-source\t2\t0") for l in lines), lines)
        code, lines = call(G + ["data-flow-unmatched", "--to", str(fx.catalog / "listing.tsv")])
        arms.check("data-flow-unmatched: a file inside the catalog is a usage exit and nothing is written",
                   code == 2 and not (fx.catalog / "listing.tsv").exists())
        code, lines = call(G + ["data-flow-unmatched", "--to", str(tmp / "listing.tsv")])
        arms.check("data-flow-unmatched: the listing is written outside the catalog",
                   code == 0 and (tmp / "listing.tsv").read_text(encoding="utf-8").startswith("universe\tpage\tlocation\tside\treason\t"))

        # -- citations, in a repository whose cited file differs between two commits --
        ax = PC.build_fixture_repo(tmp / "anchors")
        A = roots_of(ax)
        call(A + ["build"])
        PC.write_text(ax.repo / ax.layout["sources"] / "fixture-blob.bin.txt", "")
        (ax.repo / ax.layout["sources"] / "fixture-blob.bin.txt").write_bytes(b"\xff\xfe\x00 not text\n")
        verified = PC.commit_all(ax.repo, "built, with a file that is not text")
        build_before = tmp / "anchors-before"
        call(A + ["build", "--out", str(build_before)])
        rules = ax.repo / rules_src
        original = rules.read_text(encoding="utf-8")
        original_lines = original.rstrip("\n").split("\n")
        rules.write_text("An inserted first line.\n" + original, encoding="utf-8")
        shifted = PC.commit_all(ax.repo, "the cited file gains a first line")
        blob_src = ax.layout["sources"] + "/fixture-blob.bin.txt"
        cites = {"order": "[the order rule](/%s#L3)" % rules_src, "span": "[`the span`](/%s#L7-L8)" % rules_src,
                 "last": "[the last line](/%s#L13)" % rules_src, "script": "[a script function](/%s#L2)" % script_src,
                 "repeated": "[a repeated line](/%s#L6)" % rules_src, "blank": "[a blank edge](/%s#L4-L5)" % rules_src,
                 "range": "[past the end](/%s#L99)" % rules_src, "binary": "[not text](/%s#L1)" % blob_src,
                 "absent": "[an absent path](/no/such/file.txt#L1)"}
        subject_text = ax.stamp(PC.fixture_text("pages/pass/fixture-activity-plain.md.txt")).replace(ax.base, verified)
        subject_text = subject_text.replace("id: fixture-activity-plain", "id: fail-anchor-bare")
        subject_text += "".join("- %s\n" % v for v in cites.values())
        subject = ax.catalog / PC.FIXTURE_UNIVERSE / "fail-anchor-bare.md"
        anchored_page = ax.page("fixture-activity-anchored")
        anchored_before = anchored_page.read_bytes()

        def convert(*args):
            code, lines = call(A + ["anchors", "convert", str(subject)] + list(args))
            return code, lines, census_of(lines)

        subject.write_text(subject_text, encoding="utf-8")
        code, lines, c = convert("--list")
        rows = [l.split("\t") for l in lines[:-1]]
        arms.check("convert --list: one row per citation it would convert — page, line, label, path, lines, text, and same or differs",
                   len(rows) == 4 and all(len(r) == 7 for r in rows)
                   and {r[2]: r[6] for r in rows} == {"the order rule": "differs", "`the span`": "differs",
                                                      "the last line": "differs", "a script function": "same"}
                   and any(r[5] == original_lines[2] for r in rows), rows)
        arms.check("convert --list: nothing is written", subject.read_text(encoding="utf-8") == subject_text)
        code, lines, c = convert("--dry-run")
        arms.check("convert --dry-run: the census counts what it would do and nothing is written",
                   c.get("bare") == "9" and c.get("converted") == "4" and subject.read_text(encoding="utf-8") == subject_text, lines[-1:])
        code, lines, c = convert()
        converted = subject.read_text(encoding="utf-8")
        want = PC.anchor_text(3, None, PC.fingerprint(original_lines[2]))
        now_line_3 = rules.read_text(encoding="utf-8").split("\n")[2]
        arms.check("convert: the anchor's fingerprint is the cited line's at the page's verification commit, not the "
                   "line of that number in the checked-out file",
                   cites["order"] + want in converted and PC.fingerprint(now_line_3) != PC.fingerprint(original_lines[2]), want)
        arms.check("convert: a span and a code-span label convert, with the span named in the anchor",
                   cites["span"] + PC.anchor_text(7, 8, PC.fingerprint("\n".join(original_lines[6:8]))) in converted)
        arms.check("convert: with refusals left as written the run is exit 1 and each stays bare",
                   code == 1 and c.get("left") == "5" and c.get("demoted") == "0"
                   and all(cites[k] + "\n" in converted for k in ("repeated", "blank", "range", "binary", "absent")), lines)
        for reason in REFUSALS:
            arms.check("convert: the refusal reason %s fires" % reason, any(l.startswith("refused: ") and l.endswith("(%s)" % reason) for l in lines), lines)
        arms.check("convert: a page with no bare fragment is left byte-identical (the discrimination arm)",
                   call(A + ["anchors", "convert", str(anchored_page)])[0] == 0 and anchored_page.read_bytes() == anchored_before)
        subject.write_text(subject_text, encoding="utf-8")
        worklist = tmp / "worklist.tsv"
        code, lines, c = convert("--refused", "demote", "--worklist", str(worklist))
        demoted = subject.read_text(encoding="utf-8")
        listed = [l.split("\t") for l in worklist.read_text(encoding="utf-8").rstrip("\n").split("\n")[1:]]
        arms.check("demote: each refused citation is rewritten to a whole-file link, label and path kept, and listed",
                   c.get("demoted") == "4" and "- [a repeated line](/%s)\n" % rules_src in demoted
                   and "- [not text](/%s)\n" % blob_src in demoted and sorted(r[4] for r in listed) == sorted(REFUSALS), listed)
        arms.check("demote: a citation whose path is absent at that commit is left as written and fails the run",
                   code == 1 and c.get("left") == "1" and cites["absent"] + "\n" in demoted, lines[-1:])
        subject.write_text(demoted.replace("- %s\n" % cites["absent"], ""), encoding="utf-8")
        demoted = subject.read_text(encoding="utf-8")
        code, lines, c = convert("--refused", "demote")
        arms.check("demote: a second run converts nothing, changes no byte and is exit 0 — no bare fragment remains",
                   code == 0 and c.get("bare") == "0" and subject.read_text(encoding="utf-8") == demoted
                   and not [x for x in PC.find_citations(PC.load_page(subject, ax.roots()).body_lines()) if x.state != "anchored"], lines)

        def resolve(*args, pages=(subject,)):
            code, lines = call(A + ["anchors", "resolve"] + [str(p) for p in pages] + list(args))
            return code, lines, census_of(lines)

        code, lines, c = resolve("--check")
        arms.check("resolve --check: text that moved is reported moved, an unmoved citation current, and the run is exit 1",
                   code == 1 and (c.get("citations"), c.get("current"), c.get("moved")) == ("4", "1", "3"), lines)
        arms.check("resolve --check: nothing is written", subject.read_text(encoding="utf-8") == demoted)
        rules.write_text(rules.read_text(encoding="utf-8").replace(original_lines[12], "The last line was edited."), encoding="utf-8")
        code, lines, c = resolve("--check")
        arms.check("mixed: two moved and one gone, exit 1 with those counts",
                   code == 1 and (c.get("moved"), c.get("gone"), c.get("current")) == ("2", "1", "1"), lines)
        summary = tmp / "citations.md"
        code, lines, c = resolve("--write", "--summary-file", str(summary))
        written = subject.read_text(encoding="utf-8")
        gone_line = "- %s%s\n" % (cites["last"], PC.anchor_text(13, None, PC.fingerprint(original_lines[12])))
        arms.check("mixed --write: the two moved citations are rewritten, fragment and line together",
                   c.get("rewritten") == "2" and "[the order rule](/%s#L4)%s" % (rules_src, PC.anchor_text(4, None, PC.fingerprint(original_lines[2]))) in written
                   and "[`the span`](/%s#L8-L9)%s" % (rules_src, PC.anchor_text(8, 9, PC.fingerprint("\n".join(original_lines[6:8])))) in written, written[-900:])
        arms.check("mixed --write: the gone citation is byte-identical, the run is exit 1, and the summary block lists it",
                   code == 1 and gone_line in written and c.get("gone") == "1"
                   and "| gone |" in summary.read_text(encoding="utf-8") and "| hub |" in summary.read_text(encoding="utf-8"), lines)
        arms.check("--write: no other byte changed, and the verification commit is untouched",
                   written.replace("#L4)", "#L3)").replace("line=4;", "line=3;").replace("#L8-L9)", "#L7-L8)").replace("line=8-9;", "line=7-8;") == demoted
                   and "last_verified_commit: %s" % verified in written)
        code, lines, c = resolve("--write")
        arms.check("--write: a second run rewrites nothing and changes no byte",
                   c.get("rewritten") == "0" and subject.read_text(encoding="utf-8") == written)
        arms.check("--write: the shared link checker reads no finding on the rewritten page",
                   PC.sibling(PC.LINK_CHECKER).scan_file(subject, [], ax.repo) == [])
        code, lines, c = resolve("--check", "--sources-changed-in", "%s..%s" % (verified, shifted))
        arms.check("--sources-changed-in: only citations of paths the range changed are read, and a gone one is exit 1",
                   code == 1 and (c.get("citations"), c.get("gone"), c.get("current")) == ("3", "1", "2"), lines)
        code, lines, c = resolve("--check", "--sources-changed-in", "%s..%s" % (ax.base, verified))
        arms.check("--sources-changed-in: a range whose changed paths no page cites is a valid answer, exit 0 with no citation",
                   code == 0 and c.get("citations") == "0", lines)
        code, lines, c = resolve("--check", "--sources-changed-in", "%s..%s" % (shifted, shifted))
        arms.check("--sources-changed-in: a range that changes no path is exit 3, not a clean answer",
                   code == 3 and c.get("status") == "not-evaluated" and any("changes no path" in l for l in lines), lines)
        arms.check("--sources-changed-in: a range that does not resolve is exit 3",
                   resolve("--check", "--sources-changed-in", "no-such-ref..HEAD")[0] == 3)
        rules.write_text(rules.read_text(encoding="utf-8") + original_lines[2] + "\n", encoding="utf-8")
        code, lines, c = resolve("--write")
        arms.check("ambiguous: the cited text now stands twice, the recorded line among the places; no byte changes; exit 1",
                   code == 1 and c.get("ambiguous") == "1" and subject.read_text(encoding="utf-8") == written, lines)
        script_path = ax.repo / script_src
        script_path.rename(script_path.with_name("fixture-script-renamed.sh.txt"))
        code, lines, c = resolve("--write")
        arms.check("path-missing: the cited file was renamed; the citation is not followed, no byte changes; exit 1",
                   code == 1 and any(l.startswith("path-missing: ") for l in lines) and c.get("other") == "1"
                   and subject.read_text(encoding="utf-8") == written, lines)
        script_path.with_name("fixture-script-renamed.sh.txt").rename(script_path)
        malformed = ax.fail_page("fail-anchor-malformed")
        code, lines, c = resolve("--check", pages=(malformed,))
        arms.check("resolve: a line mismatch, a bare fragment and an anchor that follows no link each fail the run",
                   code == 1 and int(c.get("other", 0)) >= 3 and {l.split(":")[0] for l in lines[:-1]} >= {"line-mismatch", "bare", "malformed"}, lines)
        malformed.unlink()
        subject.unlink()

        # -- a source anchor never reaches a generated cell, whatever its line breaks or its end form --
        anchor_tail = "line=3; fp=0123456789abcdef"
        arms.check("views: a carried cell drops an anchor that spans lines, and one that ends with the second end form",
                   PC.carry("[a](/x/y.txt#L3)<!-- source-anchor:\n%s --> b" % anchor_tail) == "a b"
                   and PC.carry("[a](/x/y.txt#L3)<!-- source-anchor: %s --!> b" % anchor_tail) == "a b")
        arms.check("views: a carried cell keeps a comment that is no source anchor (the near-miss)",
                   PC.carry("a <!-- note --> b") == "a <!-- note --> b")

        # -- a rewrite of line fragments changes no generated byte --
        rules.write_text("An inserted first line.\n" + original, encoding="utf-8")
        code, lines, c = resolve("--write", pages=())
        arms.check("fragment rewrite: the anchored fixture page's citations are rewritten",
                   int(c.get("rewritten", 0)) >= 2 and anchored_page.read_bytes() != anchored_before, lines)
        code, lines = call(A + ["build", "--check"])
        arms.check("fragment rewrite: build --check is exit 0 with nothing differing", code == 0 and census_of(lines).get("differing") == "0", lines)
        call(A + ["build", "--out", str(tmp / "anchors-after")])
        arms.check("fragment rewrite: a build to a second folder is byte-identical to the build made before the rewrite",
                   tree(tmp / "anchors-after") == tree(build_before))
        process = ax.page("fixture-process")
        process.write_text(process.read_text(encoding="utf-8").replace("| Entry | a fixture input record exists |",
                                                                      "| Entry | a [relabelled](/%s) record exists |" % rules_src), encoding="utf-8")
        code, lines = call(A + ["build", "--check"])
        arms.check("fragment rewrite: a link's label changed in a cell a view carries, and one file differs (the control)",
                   code == 1 and census_of(lines).get("differing") == "1", lines)

        # -- the commands a publication gate runs write nothing under the repository --
        cx = PC.build_fixture_repo(tmp / "clean")
        C = roots_of(cx)
        call(C + ["build"])
        PC.commit_all(cx.repo, "built")
        for name, args in (("build --check", ["build", "--check"]), ("anchors resolve --check", ["anchors", "resolve", "--check"]),
                           ("stale", ["stale"]), ("stale --fail-on any", ["stale", "--fail-on", "any"])):
            code, lines, _err = cli(C + args)
            status = PC.git(cx.repo, "status", "--porcelain", "--untracked-files=all", "--ignored")
            arms.check("clean checkout: after %s, exit 0 and git status prints nothing" % name, code == 0 and status == b"", (code, status))
        code, lines, _err = cli(C + ["anchors", "resolve", "--check"])
        arms.check("citations: on the fixture corpus every citation is current, and the census counts them",
                   lines[-1] == "process-catalog citations status=pass exit=0 pages=8 citations=2 current=2 moved=0 gone=0 "
                   "ambiguous=0 other=0 rewritten=0", lines[-1:])
        code, lines, _err = cli(C + ["stale", "--fail-on", "any"])
        arms.check("staleness: the census prints pages for the published universe, drafts included",
                   re.match(r"^process-catalog staleness status=pass exit=0 pages=8 sources=\d+ depicted_changed=0 "
                            r"cited_changed=0 fail_on=any$", lines[-1]) is not None, lines[-1:])
        plain = cx.page("fixture-activity-plain")
        plain.write_text(re.sub(r"(?m)^## Sources\n(.|\n)*", "## Sources\n\n- nothing linked by line\n", plain.read_text(encoding="utf-8")),
                         encoding="utf-8")
        code, lines = call(C + ["anchors", "resolve", "--check", str(plain)])
        arms.check("citations: pages examined and no line citation found is exit 0 with citations=0",
                   code == 0 and census_of(lines).get("citations") == "0", lines)

        # -- nothing examined is never a pass --
        ex = PC.build_fixture_repo(tmp / "empty", pages=False)
        E = roots_of(ex)
        for name, args in (("build", ["build"]), ("build --check", ["build", "--check"]), ("anchors convert", ["anchors", "convert"]),
                           ("anchors resolve --check", ["anchors", "resolve", "--check"]), ("stale", ["stale"]),
                           ("coverage", ["coverage"]), ("impact", ["impact", "--paths", rules_src])):
            code, lines = call(E + args)
            arms.check("nothing examined: %s on an empty catalog is exit 3, census status=not-evaluated" % name,
                       code == 3 and " status=not-evaluated exit=3 " in lines[-1] and lines[-1].startswith("process-catalog "), lines)
        PC.write_text(ex.catalog / PC.INDEX_NAME, PC.generated_header("Stray", "stray") + "# stray\n")
        arms.check("nothing examined: a stray generated file does not turn an empty catalog into a pass",
                   call(E + ["build", "--check"])[0] == 3 and not list(ex.catalog.glob("views/*")))
        code, lines = call(E + ["impact", "--paths", rules_src, "--record"])
        arms.check("impact --record: on an empty catalog the record says the catalog holds no pages, and the run is exit 3",
                   code == 3 and RECORD_EMPTY in lines, lines)
        code, lines = call(E + ["impact", "--paths", rules_src, "--json"])
        try:
            doc = json.loads("\n".join(lines))
        except ValueError:
            doc = {}
        arms.check("impact --json: a not-evaluated run still prints one document, with the census and the reason",
                   code == 3 and "not_evaluated" in doc and " status=not-evaluated exit=3 " in doc.get("census", ""), lines)
        summary = tmp / "generated.md"
        call(E + ["build", "--check", "--summary-file", str(summary)])
        arms.check("summary file: a not-evaluated run writes its block before it returns",
                   summary.is_file() and "### Process catalog — generated-output: NOT-EVALUATED" in summary.read_text(encoding="utf-8"))
        for name, target in (("the pack", ex.definitions / PC.default_part("pack")),
                             ("the ID registry", ex.definitions / PC.default_part("registry")),
                             ("the kinds table", ex.definitions / PC.default_part("kinds")),
                             ("the controls register", ex.definitions / "controls-register.tsv")):
            saved = target.read_bytes()
            target.unlink()
            code, lines = call(roots_of(cx) + ["--definitions", str(ex.definitions), "build", "--check"])
            target.write_bytes(saved)
            arms.check("missing input: without %s, build --check is exit 3" % name, code == 3 and "NOT-EVALUATED" in lines[0], lines)
        code, lines = call(["--repo", str(tmp / "no-such-repository"), "build", "--check"])
        arms.check("missing input: a repository root that is no work tree is exit 3, naming it", code == 3 and "--repo" in lines[0], lines)
        saved = (cx.definitions / PC.default_part("pack")).read_text(encoding="utf-8")
        (cx.definitions / PC.default_part("pack")).write_text(saved.replace('  "pack_version": "2",\n', '  "pack_version": "2",\n  "prose": "x",\n'),
                                                              encoding="utf-8")
        code, lines = call(C + ["build", "--check"])
        (cx.definitions / PC.default_part("pack")).write_text(saved, encoding="utf-8")
        arms.check("pack shape: an unknown key is exit 3 naming the key, in this tool as in every other",
                   code == 3 and "prose" in lines[0], lines)


        # ==========================================================================================
        # overlay, the measures and their register — on the fixture tree, with no network, no host
        # client and no file of the surrounding repository but the tool's own siblings
        # ==========================================================================================
        import hashlib
        fixtures = PC.FIXTURE_DIR
        cases_dir = fixtures / "measure-cases"
        planted = json.loads((fixtures / "measures" / "planted-measures.json").read_text(encoding="utf-8"))
        honest = (fixtures / "measures" / "fixture-count-rows.py.txt").read_text(encoding="utf-8")
        own = json.loads((cases_dir / "overlay-inputs.json").read_text(encoding="utf-8"))

        # -- the measure-case arm: each real measure file, found beside this tool, on its case --
        real_dir = HERE / Path(PC.default_part("measures_dir")).name
        real = sorted(real_dir.glob("*.py")) if real_dir.is_dir() else []
        arms.check("measure cases: the measures folder beside the tool holds measure files", bool(real), real_dir.name)
        for path in real:
            case_path = cases_dir / (path.stem + ".json")
            if not arms.check("measure case %s: the measure file has a case" % path.stem, case_path.is_file()):
                continue
            case = json.loads(case_path.read_text(encoding="utf-8"))
            source = path.read_text(encoding="utf-8")
            arms.check("measure case %s: the file is inside the source form" % path.stem,
                       PC.measure_source_findings(source) == [], PC.measure_source_findings(source)[:1])
            got = [PC.run_measure(source, path.name, case["inputs"], case["params"], seed=seed) for seed in PC.CHILD_SEEDS]
            arms.check("measure case %s: both seeds give the report the case states" % path.stem,
                       all(g == ("measured", "", case["expected"]) for g in got), [g[:2] for g in got])
        arms.check("measure cases: every case file but the generator's own belongs to a measure file",
                   sorted(p.stem for p in cases_dir.glob("*.json")) == sorted([p.stem for p in real] + ["overlay-inputs"]))

        # -- the source-check arm --
        arms.check("source check: the honest fixture measure is inside the form", PC.measure_source_findings(honest) == [])
        for item in planted["refused"]:
            rules = [rule for _line, rule, _what in PC.measure_source_findings(item["source"])]
            arms.check("source check: the planted %s is refused naming %s" % (item["name"], item["rule"]),
                       item["rule"] in rules, rules)
            status, reason, _report = PC.run_measure(item["source"], "planted.py", {}, {})
            arms.check("source check: the child refuses the planted %s on the bytes it is handed" % item["name"],
                       status == "failed" and reason.startswith("source-form"), (status, reason))

        # -- the runtime arm, through the test seam --
        canary_dir = tmp / "canary-folder"
        canary_dir.mkdir()
        canary = canary_dir / "fixture-canary.txt"
        canary.write_text("CANARY-TEXT-OF-THE-RUNTIME-ARM", encoding="utf-8")
        no_check, nothing = {"source_check": False}, {"source_check": False, "hook": False, "builtins": False}
        for item in planted["runtime"]:
            source = item["source"].replace("{CANARY}", str(canary)).replace("{FOLDER}", str(canary_dir))
            label = "runtime: the planted %s" % item["name"]
            if item["kind"] == "reach":
                status, reason, report = PC.run_measure(source, "planted.py", {}, {}, layers=no_check)
                arms.check(label + " ends as failed with no canary and no report",
                           status == "failed" and report is None, (status, reason))
                if item["control"]:
                    status, reason, report = PC.run_measure(source, "planted.py", {}, {}, layers=nothing)
                    arms.check(label + " returns the canary with every layer switched off (the control)",
                               status == "measured" and "canary" in report.lower(), (status, reason))
            elif item["kind"] == "swallow":
                status, reason, report = PC.run_measure(source, "planted.py", {}, {}, layers={"source_check": False, "builtins": False})
                arms.check(label + " ends with the refusal status and no report: no handler runs after a refusal",
                           (status, report) == ("failed", None) and reason.startswith("outside-read:"), (status, reason))
                status, reason, report = PC.run_measure(source, "planted.py", {}, {}, layers=nothing)
                arms.check(label + " returns its fallback with the hook switched off (the control)", report == "swallowed", (status, reason))
            elif item["kind"] == "order":
                both = [PC.run_measure(source, "planted.py", {}, {}, seed=seed, layers={"source_check": False, "builtins": False})[2]
                        for seed in PC.CHILD_SEEDS]
                arms.check(label + " gives two different reports under the two seeds — the two-seed run can see set order",
                           None not in both and both[0] != both[1] and sorted(both[0].split(",")) == sorted(both[1].split(","))
                           and len(both[0].split(",")) == 40, [b and b[:30] for b in both])
                again = PC.run_measure(source, "planted.py", {}, {}, seed=PC.CHILD_SEEDS[0], layers={"source_check": False, "builtins": False})[2]
                arms.check(label + " gives the same report twice under one seed: the seed is fixed", again == both[0])
            elif item["kind"] == "zone":
                layers = {"source_check": False, "builtins": False}
                reports = []
                for zone in ("Asia/Tokyo", "America/Chicago"):
                    kept = os.environ.get("TZ")
                    os.environ["TZ"] = zone
                    try:
                        reports.append(PC.run_measure(source, "planted.py", {}, {}, layers=layers)[2])
                    finally:
                        os.environ.pop("TZ", None) if kept is None else os.environ.update(TZ=kept)
                arms.check(label + " gives one report whatever zone this process names", reports[0] is not None and reports[0] == reports[1], reports)
                moved = PC.run_measure(source, "planted.py", {}, {}, layers=layers, zone="Asia/Tokyo")[2]
                arms.check(label + " gives another report when the child's own zone is changed through the seam (the control)",
                           moved is not None and moved != reports[0], moved)
            elif item["kind"] == "address":
                status, reason, report = PC.run_measure(source, "planted.py", {}, {}, layers={"source_check": False, "builtins": False})
                arms.check(label + " is refused by the report check: a report carries no object address",
                           (status, reason, report) == ("failed", "bad-report", None), (status, reason))
        status, _reason, report = PC.run_measure(honest, "fixture.py", {"fixture-input": [["fixture-label", "a\nb\n"]]}, {})
        arms.check("runtime: the honest fixture measure runs under every layer and raises no refused event",
                   (status, report) == ("measured", "fixture-label: lines 2\ntotal: lines 2\n"), (status, report))

        # -- the child's search path --
        plant_dir = tmp / "planted-modules"
        plant_dir.mkdir()
        for module in ("json", "collections", "re", "datetime", "types"):
            (plant_dir / (module + ".py")).write_text('raise SystemExit("PLANTED-MODULE-LOADED")\n', encoding="utf-8")
        status, _reason, report = PC.run_measure(honest, "fixture.py", {"fixture-input": [["fixture-label", "a\n"]]}, {},
                                                 workdir=plant_dir)
        arms.check("search path: a file in the child's working folder that carries a library module's name is not loaded",
                   (status, report) == ("measured", "fixture-label: lines 1\ntotal: lines 1\n"), (status, report))
        proc = subprocess.run([sys.executable, "-B", "-S", "-c", "import json"], capture_output=True, text=True, cwd=str(plant_dir),
                              env={"PYTHONHASHSEED": "1", "TZ": "UTC"})
        arms.check("search path: without the entry code's first line the same start loads the planted file (the control)",
                   "PLANTED-MODULE-LOADED" in proc.stderr, proc.stderr[-80:])
        beside = tmp / "beside-a-measure"
        beside.mkdir()
        (beside / "fixture.py").write_text(honest, encoding="utf-8")
        (beside / "collections.py").write_text('raise SystemExit("PLANTED-MODULE-LOADED")\n', encoding="utf-8")
        status, _reason, report = PC.run_measure((beside / "fixture.py").read_text(encoding="utf-8"), "fixture.py",
                                                 {"fixture-input": [["fixture-label", "a\n"]]}, {})
        arms.check("search path: a file beside a measure that carries a library module's name is not loaded",
                   status == "measured" and "PLANTED" not in report, (status, report))
        proc = subprocess.run([sys.executable, "-B", "-S", str(beside / "fixture.py")], capture_output=True, text=True,
                              env={"PYTHONHASHSEED": "1", "TZ": "UTC"}, cwd=str(tmp),
                              input="")
        (beside / "starter.py").write_text("import collections\n", encoding="utf-8")
        proc = subprocess.run([sys.executable, "-B", "-S", str(beside / "starter.py")], capture_output=True, text=True, cwd=str(tmp))
        arms.check("search path: a child started from a script file in that folder does load it (the control)",
                   "PLANTED-MODULE-LOADED" in proc.stderr, proc.stderr[-80:])
        arms.check("child start: exactly two environment variables, the seeds are the pair, and the entry code strips the "
                   "working-folder entry before its first import",
                   PC.CHILD_SEEDS == ("1", "2") and PC.CHILD_BOOT.split("\n")[1].startswith("sys.path[:] =")
                   and PC.CHILD_BOOT.split("\n")[0] == "import sys")

        # -- the attribute arm, on the landed list and on this interpreter --
        def probe_generator():
            yield 1

        async def probe_coroutine():
            return 1

        coroutine = probe_coroutine()
        try:
            raise ValueError("probe")
        except ValueError as e:
            traceback_object = e.__traceback__
        subjects = [probe_generator, probe_generator(), coroutine, sys._getframe(), probe_generator.__code__, traceback_object,
                    os, type, [].append, len]
        reference = {name for subject in subjects for name in dir(subject) if not name.startswith("_")}
        coroutine.close()
        arms.check("attributes: no listed attribute is an attribute of a function, generator, coroutine, frame, code, "
                   "traceback, module, type, bound-method or built-in-function object",
                   not (set(PC.MEASURE_ATTRIBUTES) & reference), sorted(set(PC.MEASURE_ATTRIBUTES) & reference))
        arms.check("attributes: with the text replace method added the same test fails (the control)",
                   bool((set(PC.MEASURE_ATTRIBUTES) | {"replace"}) & reference))
        used = {"nodes": set(), "attributes": set(), "names": set()}
        import ast
        import builtins
        for source in [p.read_text(encoding="utf-8") for p in real] + [honest]:
            for node in ast.walk(ast.parse(source)):
                used["nodes"].add(type(node).__name__)
                if isinstance(node, ast.Attribute):
                    used["attributes"].add(node.attr)
                if isinstance(node, ast.Name) and hasattr(builtins, node.id):
                    used["names"].add(node.id)
        imported = {n for names in PC.MEASURE_IMPORTS.values() for n in names}
        arms.check("lists: each of the four lists holds only what a landed measure or the fixture measure uses",
                   set(PC.MEASURE_NODES) == used["nodes"] and set(PC.MEASURE_ATTRIBUTES) == used["attributes"]
                   and set(PC.MEASURE_BUILTINS) == used["names"] - imported,
                   [sorted(set(PC.MEASURE_NODES) ^ used["nodes"]), sorted(set(PC.MEASURE_ATTRIBUTES) ^ used["attributes"]),
                    sorted(set(PC.MEASURE_BUILTINS) ^ (used["names"] - imported))])

        # -- the synthetic-values arm: the twenty fixture files of the evidence rules --
        twenty = sorted(cases_dir.glob("*.json")) + [fixtures / PC.default_part("measures")] \
            + sorted((fixtures / "measures").glob("*")) + sorted((fixtures / "workflows").glob("*.txt")) \
            + [fixtures / "pages" / "pass" / "fixture-activity-measured.md.txt"] \
            + sorted((fixtures / "pages" / "fail").glob("fail-evidence-*.md.txt"))
        arms.check("synthetic values: the arm reads twenty fixture files", len(twenty) == 20, len(twenty))
        row_ids = set()
        for name in ("controls-register.tsv", "controls-register-fail.tsv"):
            row_ids |= {line.split("\t")[0] for line in (fixtures / name).read_text(encoding="utf-8").split("\n")[1:] if line}

        def synthetic_findings(text):
            """The digit rule, by length. Set aside first, each with its own bound: a row ID one of the
            fixture registers holds; a section number of at most two digits a part; the fractional part
            of a timestamp when it is zeros only; a legacy version key of one or two digits a side.
            A failing page's expect line is the harness's own and is set aside whole when it holds
            rule codes and nothing else."""
            text = re.sub(r"<!-- expect: (?:(?:warn:)?[A-Z]{2,3}[0-9]{3}(?:, )?)+ -->", " ", text)
            for row_id in sorted(row_ids, key=len, reverse=True):
                text = text.replace(row_id, " ")
            text = re.sub(r"§ [0-9]{1,2}(?:\.[0-9]{1,2})*(?![0-9.])", " ", text)
            text = re.sub(r"(?<=:[0-9]{2})\.0+(?=Z)", " ", text)
            text = re.sub(r"(?<![A-Za-z0-9.])v[0-9]{1,2}\.[0-9]{1,2}(?![0-9.])", " ", text)
            found = [m.group(0) for m in re.finditer(r"[0-9]+", text)
                     if len(m.group(0)) > len(str(PC.SYNTHETIC_MAX)) and m.group(0) != str(PC.SYNTHETIC_YEAR)]
            found += [m.group(0) for m in re.finditer(r"[0-9][,.][0-9]", text)]
            found += [m.group(0) for m in re.finditer(r"\b[0-9a-f]{40}\b", text) if not re.match(r"^[a-f]{40}$", m.group(0))]
            return found

        for path in twenty:
            text = path.read_text(encoding="utf-8")
            arms.check("synthetic values: %s holds no figure outside the rule" % path.name, synthetic_findings(text) == [],
                       synthetic_findings(text)[:3])
            if path.suffix == ".json":
                arms.check("synthetic values: %s opens with the mark" % path.name,
                           next(iter(json.loads(text).items())) == ("synthetic", PC.SYNTHETIC_MARK))
        names = []
        for path in sorted(cases_dir.glob("*.json")):
            case = json.loads(path.read_text(encoding="utf-8"))
            for entry in case.get("inputs", {}):
                names += [entry.split(":", 1)[1]] if ":" in entry else []
        names += own["event_log"]["titles"] + list(own["analysis_home"]["folders"]) \
            + [t for t in own["event_log"]["tags"] if not re.match(r"^v[0-9]{1,2}\.[0-9]{1,2}$", t)]
        register_rows = [line.split("\t") for line in (fixtures / PC.default_part("measures")).read_text(encoding="utf-8").split("\n")[1:] if line]
        names += [cells[0] for cells in register_rows] + [cells[1] for cells in register_rows]
        arms.check("synthetic values: every workflow, measure, title, folder and tracked name in the fixtures begins `fixture-`",
                   bool(names) and all(n.startswith("fixture-") for n in names), [n for n in names if not n.startswith("fixture-")])
        control = "a count of 4107, the year 2002, the grouped figure 12,34, the fraction 1.5 and the run 012"
        arms.check("synthetic values: a planted copy is refused naming a four-digit count, a later year, a grouped figure, "
                   "a decimal fraction and a three-digit run", sorted(synthetic_findings(control)) == ["012", "1.5", "2,3", "2002", "4107"],
                   synthetic_findings(control))
        arms.check("synthetic values: the set-aside kinds are bounded — a four-digit section number, a row ID no register "
                   "holds, a version key with a third digit and a fraction that is not zeros are all read",
                   len(synthetic_findings("§ 1234 and C-777 and v1.234 and 00:00:01.250Z")) >= 4,
                   synthetic_findings("§ 1234 and C-777 and v1.234 and 00:00:01.250Z"))
        arms.check("synthetic values: the allowed forms read clean (the near-miss)",
                   synthetic_findings("§ 13.4, %s, 2001-01-01T00:00:01.0000000Z, v1.02, Check 63, %s"
                                      % (sorted(row_ids)[0], "ab" * 20)) == [])

        # -- the measures register: every load rule --
        ofx = PC.build_fixture_repo(tmp / "overlay-repo")
        O = roots_of(ofx) + ["--probe-source", ofx.layout["probe_source"], "--measures-dir", str(ofx.measures_dir)]
        register = ofx.definitions / PC.default_part("measures")
        register_text = register.read_text(encoding="utf-8")
        o_roots = PC.resolve_roots(build_parser().parse_args(O + ["overlay", "--list"]))
        arms.check("register: the fixture register loads, three rows, classes derived", [m.input_class for m in PC.load_measures(o_roots)]
                   == ["git", "repo-working-state", "host-api"])
        breaches = [
            ("MR1 a header that differs", lambda t: t.replace("params", "args", 1), "header"),
            ("MR1 a row with a missing cell", lambda t: t.replace("\tgit\t\t", "\tgit\t", 1), "cells"),
            ("MR1 no row", lambda t: t.split("\n")[0] + "\n", "no row"),
            ("MR2 an ID with a digit", lambda t: t.replace("fixture-git-rows", "fixture-git-rows2", 1), "measure_id"),
            ("MR2 rows that do not ascend", lambda t: t.replace("fixture-git-rows", "fixture-zebra-rows", 1), "measure_id"),
            ("MR3 a script that is not a tracked file of the folder", lambda t: t.replace("fixture-count-rows.py", "fixture-absent.py", 1), "script"),
            ("MR4 an input kind outside the table", lambda t: t.replace("event-log-rows", "warn-log-rows", 1), "inputs"),
            ("MR4 a repeated input", lambda t: t.replace("event-log-rows", "event-log-rows;event-log-rows", 1), "inputs"),
            ("MR4 a pattern that climbs out", lambda t: t.replace("tracked:core/", "tracked:../core/", 1), "inputs"),
            ("MR4 a pattern that matches no tracked file", lambda t: t.replace("fixture-rules.md.txt", "fixture-absent.md.txt", 1), "inputs"),
            ("MR4 a workflow that is not tracked", lambda t: t.replace("fixture-probe.yml", "fixture-absent.yml", 1), "inputs"),
            ("MR5 a class that the inputs do not derive", lambda t: t.replace("\trepo-working-state\t", "\tgit\t", 1), "input_class"),
            ("MR6 a parameter that is no pair", lambda t: t.replace("window_days=14", "window_days", 1), "params"),
            ("MR6 a value that is neither an integer nor tokens", lambda t: t.replace("window_days=14", "window_days=1.5", 1), "params"),
            ("MR7 a digit in the population", lambda t: t.replace("every line of", "every 12 lines of", 1), "population"),
            ("MR7 a number word in the population", lambda t: t.replace("every line of", "every dozen lines of", 1), "population"),
        ]
        for label, change, needle in breaches:
            register.write_text(change(register_text), encoding="utf-8")
            arms.raises("register: %s stops the load, naming it" % label, lambda: PC.load_measures(o_roots), needle)
        register.write_text(register_text, encoding="utf-8")
        script = ofx.measures_dir / "fixture-count-rows.py"
        script.write_text(honest.replace("\n\ndef measure", "\nimport os\n\n\ndef measure", 1), encoding="utf-8")
        arms.raises("register: MR8 a measure file outside the source form stops the load, naming the rule",
                    lambda: PC.load_measures(o_roots), "MS1")
        code, lines = call(O + ["overlay", "--list"])
        arms.check("register: `overlay --list` runs the source rule too — exit 3, and no census",
                   code == 3 and not any(l.startswith("process-catalog ") for l in lines), lines)
        script.write_text(honest, encoding="utf-8")
        link = ofx.repo / ofx.layout["sources"] / "fixture-link.md.txt"
        os.symlink("fixture-rules.md.txt", link)
        PC.commit_all(ofx.repo, "a tracked symbolic link")
        register.write_text(register_text.replace("sources/fixture-rules.md.txt", "sources/fixture-*.md.txt", 1), encoding="utf-8")
        arms.raises("register: a tracked symbolic link that a pattern matches stops the load, naming the path",
                    lambda: PC.load_measures(PC.resolve_roots(build_parser().parse_args(O + ["overlay", "--list"]))), "fixture-link.md.txt")
        PC.test_git(ofx.repo, "rm", "-q", "--", str(link.relative_to(ofx.repo)))
        register.write_text(register_text, encoding="utf-8")
        PC.commit_all(ofx.repo, "the link removed")
        code, lines = call(O + ["overlay", "--list"])
        arms.check("list: the register and each measure's exact reference text, no census, no root needed",
                   code == 0 and len(lines) == 6 and not any(l.startswith("process-catalog ") for l in lines)
                   and lines[1] == "  " + PC.load_measures(o_roots)[0].reference, lines)

        # -- host forms, the population rule and the generator's own cases --
        arms.check("origin: each accepted shape gives a repository and each refused shape gives none",
                   all(parse_origin(x) for x in own["origins"]["accepted"]) and not any(parse_origin(x) for x in own["origins"]["refused"]),
                   [x for x in own["origins"]["accepted"] if not parse_origin(x)] + [x for x in own["origins"]["refused"] if parse_origin(x)])
        kept = kept_event_rows(own["event_log"]["text"], own["event_log"]["titles"], own["event_log"]["tags"])
        arms.check("population: a host-keyed slug row and a tagged legacy row are kept; a foreign slug, an untagged legacy "
                   "row, a row keyed by a milestone number only and a placeholder row are not",
                   [l.split("|")[2].strip() for l in kept.strip().split("\n")] == own["event_log"]["kept_keys"], kept)
        host_dir = tmp / "host-files"
        host_dir.mkdir()

        def host_file(name, value):
            (host_dir / name).write_text(json.dumps(value), encoding="utf-8")

        host_file("host-workflow-runs--fixture-probe.yml.json", own["host_responses"]["runs"])
        host_file("host-milestone-titles.json", own["event_log"]["titles"])
        host_file("host-tag-names.json", own["event_log"]["tags"])
        event_log = tmp / "fixture-event-log.md"
        event_log.write_text(own["event_log"]["text"], encoding="utf-8")
        home = tmp / "fixture-analysis-home"
        for folder_name, files in own["analysis_home"]["folders"].items():
            for file_name, body in files.items():
                PC.write_text(home / folder_name / file_name, body)
        handed = resolve_inputs(type("M", (), {"inputs": [("analysis-folder-summaries", "", "analysis-folder-summaries")], "params": {}})(),
                                o_roots, PC.Tracked(ofx.repo), {"analysis-home": home}, None, "2001-01-14", {})
        pairs = handed["analysis-folder-summaries"]
        arms.check("analysis home: each dated folder gives its name and its summary's frontmatter block; no other file "
                   "and no undated folder is read", [label for label, _t in pairs] == own["analysis_home"]["labels"]
                   and not any(s in text for _l, text in pairs for s in own["analysis_home"]["sentinels"])
                   and "analysis_type: audit" in dict(pairs)["fixture-health-audit-2001-01-01"], pairs)

        # -- the overlay root --
        (ofx.repo / ".gitignore").write_text("/local-state/process-catalog/*\n", encoding="utf-8")
        PC.commit_all(ofx.repo, "the tracked ignore rule")
        governed = ofx.repo / "local-state" / "process-catalog"
        governed.mkdir(parents=True)
        outside = tmp / "outside-root"
        outside.mkdir()
        full = ["--input", "event-log=%s" % event_log, "--host-responses", str(host_dir), "--today", "2001-01-14"]
        code, lines = call(O + ["overlay"] + full)
        arms.check("root: no --overlay-root is a usage exit with no census", code == 2 and not lines, (code, lines))
        code, lines = call(O + ["overlay", "--overlay-root", str(tmp / "no-such-root")] + full)
        arms.check("root: a root that does not exist is refused and not created",
                   code == 3 and not (tmp / "no-such-root").exists() and lines[-1].startswith("process-catalog overlay status=not-evaluated exit=3"), lines)
        plain_root = ofx.repo / "plain-root"
        plain_root.mkdir()
        code, lines = call(O + ["overlay", "--overlay-root", str(plain_root)] + full)
        arms.check("root: a root inside the main work tree that git does not report ignored is refused, nothing written",
                   code == 3 and not list(plain_root.iterdir()) and any("not ignored" in l for l in lines), lines)
        half = ofx.repo / "half-root"
        half.mkdir()
        (ofx.repo / ".git" / "info" / "exclude").write_text("/half-root/figures.json\n", encoding="utf-8")
        code, lines = call(O + ["overlay", "--overlay-root", str(half)] + full)
        arms.check("root: a root whose index file is ignored and whose measures folder is not is refused",
                   code == 3 and any("measures/probe.txt" in l for l in lines), lines)
        code, lines = call(O + ["overlay", "--overlay-root", str(governed)] + full)
        arms.check("root: the governed folder of the main work tree is written, exit 0, with the census as the last line",
                   code == 0 and lines[-1] == "process-catalog overlay status=pass exit=0 measures=3 measured=3 not_evaluated=0 failed=0", lines)
        ignored = PC.git_run(ofx.repo, "check-ignore", "-v", "--", str(governed / "figures.json"))
        arms.check("root: git reports a written figure file ignored, by the tracked rule",
                   ignored[0] == 0 and b"/local-state/process-catalog/*" in ignored[1]
                   and PC.git_run(ofx.repo, "check-ignore", "-q", "--", str(ofx.catalog / "x.md"))[0] == 1, ignored)
        linked_tree = tmp / "linked-tree"
        PC.test_git(ofx.repo, "worktree", "add", "-q", "--detach", str(linked_tree))
        inside = linked_tree / "local-state" / "process-catalog"
        inside.mkdir(parents=True)
        code, lines = call(O + ["overlay", "--overlay-root", str(inside)] + full)
        arms.check("root: a root inside a linked work tree is refused, though the tracked rule ignores it there too",
                   code == 3 and not list(inside.iterdir()) and any("linked work tree" in l for l in lines), lines)
        L = ["--repo", str(linked_tree), "--catalog-root", str(linked_tree / ofx.layout["catalog"]), "--definitions",
             str(linked_tree / ofx.layout["definitions"]), "--probe-source", ofx.layout["probe_source"], "--measures-dir",
             str(linked_tree / ofx.layout["measures_dir"])]
        before = sorted(p.name for p in governed.rglob("*"))
        code, lines = call(L + ["overlay", "--overlay-root", str(governed)] + full)
        arms.check("root: a run from a linked work tree is refused the main work tree's folder",
                   code == 3 and any("linked work tree" in l for l in lines) and sorted(p.name for p in governed.rglob("*")) == before, lines)
        code, lines = call(L + ["overlay", "--overlay-root", str(outside)] + full)
        arms.check("root: a run from a linked work tree writes a root outside every work tree", code == 0, lines)
        link_root = tmp / "link-to-plain-root"
        os.symlink(str(plain_root), str(link_root))
        code, lines = call(O + ["overlay", "--overlay-root", str(link_root)] + full)
        arms.check("root: a link is resolved before it is tested — a link to a refused folder is refused", code == 3, lines)

        # -- runs: determinism, statuses, exits --
        second = tmp / "second-root"
        second.mkdir()
        code, lines = call(O + ["overlay", "--overlay-root", str(second)] + full)
        arms.check("runs: two runs over the same inputs give byte-identical report files",
                   tree(outside / OVERLAY_MEASURES) == tree(second / OVERLAY_MEASURES) and len(tree(second / OVERLAY_MEASURES)) == 3,
                   sorted(tree(second / OVERLAY_MEASURES)))
        figures = json.loads((second / OVERLAY_INDEX).read_text(encoding="utf-8"))
        arms.check("runs: the index names each measure with its status, digests and input digests, and no synthetic flag",
                   figures["schema_version"] == 1 and figures["host"] == "responses" and "synthetic" not in figures
                   and all(v["status"] == "measured" and len(v["sha256"]) == 64 and v["inputs"] for v in figures["measures"].values()),
                   sorted(figures))
        everything = b"".join(tree(second).values()) + "\n".join(lines).encode("utf-8")
        arms.check("runs: no output byte carries the temporary folder's path, and no owner or repository name is stored",
                   str(tmp).encode("utf-8") not in everything and tmp.name.encode("utf-8") not in everything,
                   [l for l in everything.decode("utf-8", "replace").split("\n") if tmp.name in l][:3])
        state_report = (second / OVERLAY_MEASURES / "fixture-state-rows.txt").read_text(encoding="utf-8")
        arms.check("runs: the working-state measure was handed the kept rows only", state_report == "event-log: lines 2\ntotal: lines 2\n",
                   state_report)
        code, lines = call(O + ["overlay", "--overlay-root", str(second), "--host-responses", str(host_dir), "--today", "2001-01-14"])
        arms.check("runs: an input that is not passed is not looked for — its measure is not evaluated, its earlier report "
                   "is removed, the others are written, exit 3",
                   code == 3 and "fixture-state-rows: not-evaluated (input-not-passed)" in lines
                   and not (second / OVERLAY_MEASURES / "fixture-state-rows.txt").exists()
                   and (second / OVERLAY_MEASURES / "fixture-git-rows.txt").is_file()
                   and lines[-1].endswith("measures=3 measured=2 not_evaluated=1 failed=0"), lines)
        code, lines = call(O + ["overlay", "--overlay-root", str(second), "--today", "2001-01-14", "--input", "event-log=%s" % event_log])
        arms.check("runs: with no host named, every host input and the event log are not evaluated — never read from a default",
                   code == 3 and lines[-1].endswith("measures=3 measured=1 not_evaluated=2 failed=0"), lines)
        code, lines = call(O + ["overlay", "--overlay-root", str(second), "--input", "event-log=%s" % (tmp / "absent.md")] + full[2:])
        arms.check("runs: an input that was passed and cannot be read is exit 3 naming the input",
                   code == 3 and any("the input event-log" in l for l in lines), lines)
        code, lines = call(O + ["overlay", "--overlay-root", str(second), "--input", "warn-log=%s" % event_log] + full[2:])
        arms.check("runs: an input name outside the list is a usage exit", code == 2 and not lines, (code, lines))
        case_as_input = cases_dir / "event-log-population.json"
        code, lines = call(O + ["overlay", "--overlay-root", str(second), "--input", "event-log=%s" % case_as_input] + full[2:])
        arms.check("runs: a case file passed as an input is refused by its mark, exit 3 naming the input",
                   code == 3 and any("synthetic mark" in l and "event-log" in l for l in lines), lines)
        host_file("host-workflow-runs--fixture-probe.yml.json", own["host_responses"]["runs_extra_key"])
        code, lines = call(O + ["overlay", "--overlay-root", str(second)] + full)
        arms.check("runs: a host response with a key outside the reduced form is exit 3 naming the file",
                   code == 3 and any("reduced form" in l and "fixture-probe.yml" in l for l in lines), lines)
        host_file("host-workflow-runs--fixture-probe.yml.json", own["host_responses"]["runs"])
        host_file("host-tag-names.json", own["empty_tag_set"]["tags"])
        code, lines = call(O + ["overlay", "--overlay-root", str(second)] + full)
        arms.check("runs: an empty tag set makes the event-log input not evaluated — never an empty or partial count",
                   code == 3 and "fixture-state-rows: not-evaluated (empty-host-set)" in lines, lines)
        host_file("host-tag-names.json", own["event_log"]["tags"])
        script.write_text('def measure(inputs, params):\n    return open("%s").read()\n' % canary, encoding="utf-8")
        code, lines = call(O + ["overlay", "--overlay-root", str(second)] + full)
        arms.check("runs: a registered measure outside the source form stops the whole command as not evaluated", code == 3, lines)
        script.write_text(honest, encoding="utf-8")
        roots_second = PC.resolve_roots(build_parser().parse_args(O + ["overlay", "--overlay-root", str(second)]))

        class StubLive(HostLive):
            def __init__(self, short):
                self.origin, self.short = ("fixture-host.example", "fixture-owner", "fixture-repo"), short
                self.call = self.stub

            def stub(self, args):
                path = args[-1]
                if "per_page=1" in path and "--paginate" not in args:
                    return json.dumps({"total_count": 2})
                rows = [{"event": "push", "conclusion": "success", "status": "completed", "created_at": "2001-01-02T00:00:00Z"}]
                return json.dumps({"total_count": 2, "workflow_runs": rows * (1 if self.short else 2)})

        for short, want in ((True, "failed (host-total-differs)"), (False, "measured")):
            code, _pairs, lines = run_overlay(roots_second, second, ["fixture-workflow-runs"], {}, StubLive(short), "2001-01-14")
            arms.check("host: through a stub reader, a slice whose rows %s its total is %s"
                       % ("differ from" if short else "equal", want.split(" ")[0]),
                       lines == ["fixture-workflow-runs: " + want] and code == (1 if short else 0), lines)
        arms.check("host: an origin that is no host address gives no repository, and every host input is not evaluated",
                   HostLive(ofx.repo).origin is None
                   and run_overlay(roots_second, second, ["fixture-workflow-runs"], {}, HostLive(ofx.repo), "2001-01-14")[2]
                   == ["fixture-workflow-runs: not-evaluated (host-not-read)"])

        # -- the synthetic seam, --show, and the decoy install --
        seam = tmp / "seam-root"
        seam.mkdir()
        code, _pairs, lines = run_overlay(roots_second, seam, None, {"event-log": event_log}, HostFiles(host_dir), "2001-01-14",
                                          synthetic=True)
        seam_index = json.loads((seam / OVERLAY_INDEX).read_text(encoding="utf-8"))
        arms.check("seam: an overlay built from fixtures says so — the index flag, and the mark as each report's first line",
                   code == 0 and seam_index.get("synthetic") is True
                   and all(p.read_text(encoding="utf-8").split("\n")[0] == PC.SYNTHETIC_MARK for p in (seam / OVERLAY_MEASURES).glob("*.txt")))
        code, lines = call(O + ["overlay", "--show", "fixture-activity-measured", "--overlay-root", str(seam)])
        arms.check("show: one block for each measure a row cites, a marker row as its marker line, the mark first, the "
                   "census last, nothing written",
                   code == 0 and lines[0] == PC.SYNTHETIC_MARK
                   and sum(1 for l in lines if l.startswith("row ") and ": measure fixture-" in l) == 4
                   and sum(1 for l in lines if l.startswith("row ") and ("held local —" in l or "no measure —" in l)) == 2
                   and lines[-1].startswith("process-catalog overlay status=pass exit=0 measures=4 measured=4"), lines)
        code, lines = call(O + ["overlay", "--show", "fixture-activity-measured", "--overlay-root", str(tmp / "canary-folder")])
        arms.check("show: an overlay root with no index is not evaluated", code == 3, lines)
        decoy = tmp / "decoy-install"
        sentinel = "DECOY-SENTINEL-OF-THE-CLEAN-ROOM"
        for rel in ("workspace/fixture-event-log.md", "workspace/fixture-warn-log.jsonl", "container/fixture-event-log.md",
                    "container/results/fixture-event-log.md", "workspace/fixture-health-audit-2001-01-01/SUMMARY.md"):
            PC.write_text(decoy / rel, "| 2001-01-01T00:00:00Z | fixture-release-alpha | %s |\n" % sentinel)
        clean_room = tmp / "clean-room-root"
        clean_room.mkdir()
        env = dict(os.environ, HOME=str(decoy), CLAUDE_WORKSPACE_ROOT=str(decoy / "workspace"), PMO_INSTANCE_PATH=str(decoy / "container"),
                   PMO_EVALS_RESULTS_PATH=str(decoy / "container" / "results"), XDG_DATA_HOME=str(decoy / "share"))
        code, lines, _err = cli(O + ["overlay", "--overlay-root", str(clean_room), "--host-responses", str(host_dir), "--today", "2001-01-14"], env=env)
        produced = b"".join(tree(clean_room).values()) + "\n".join(lines).encode("utf-8")
        arms.check("decoy install: with a decoy home, container and logs named through the environment and no --input, the "
                   "working-state measure is not evaluated and the sentinel is in no output byte",
                   code == 3 and "fixture-state-rows: not-evaluated (input-not-passed)" in lines and sentinel.encode("utf-8") not in produced, lines)
        code, lines, _err = cli(O + ["overlay", "--overlay-root", str(clean_room), "--host-responses", str(host_dir), "--today", "2001-01-14",
                                    "--input", "event-log=%s" % (decoy / "container" / "results" / "fixture-event-log.md")], env=env)
        arms.check("decoy install: the same log passed by name is read (the control — the arm can fail)",
                   "fixture-state-rows: measured" in lines, lines)

        # -- no other command reads the overlay --
        bfx = PC.build_fixture_repo(tmp / "build-repo")
        B = roots_of(bfx)
        first_out, second_out = tmp / "build-without", tmp / "build-with"
        call(B + ["build", "--out", str(first_out)])
        (bfx.repo / ".gitignore").write_text("/local-state/process-catalog/*\n", encoding="utf-8")
        populated = bfx.repo / "local-state" / "process-catalog"
        populated.mkdir(parents=True)
        code, lines = call(B + ["--probe-source", bfx.layout["probe_source"], "--measures-dir", str(bfx.measures_dir), "overlay",
                                "--overlay-root", str(populated)] + full)
        call(B + ["build", "--out", str(second_out)])
        arms.check("build: its output is byte-identical with and without a populated overlay",
                   code == 0 and (populated / OVERLAY_INDEX).is_file() and tree(first_out) == tree(second_out) and bool(tree(first_out)), lines)

        # -- relocation: the tool and its siblings outside any repository, every root an argument --
        moved_tools = PC.relocate_tools(tmp / "outside" / "a" / "b" / "c" / "tools")
        rx = PC.build_fixture_repo(tmp / "relocated", layout=PC.relocated_layout())
        every = {"--repo": str(rx.repo), "--catalog-root": str(rx.catalog), "--definitions": str(rx.definitions),
                 "--pack": str(rx.definitions / PC.default_part("pack")),
                 "--registry": str(rx.definitions / PC.default_part("registry")),
                 "--kinds": str(rx.definitions / PC.default_part("kinds"))}

        def moved(command, without=(), env=None):
            args = []
            for flag, value in every.items():
                if flag not in without:
                    args += [flag, value]
            return cli(args + command, tool_path=str(moved_tools / Path(tool).name), env=env, cwd=str(tmp / "outside"))

        parts = [row[2] for row in PC.DEFAULTS if row[1] == "repo"]
        code, lines, _err = moved(["build"])
        produced = {k: v for k, v in tree(rx.catalog).items() if k in EXPECTED_FILES}
        arms.check("relocation: build with every root passed is exit 0, and no output byte holds a default path",
                   code == 0 and not any(p in "\n".join(lines) for p in parts)
                   and not any(p.encode() in data for p in parts for data in produced.values()), lines[-1:])
        for command in (["build", "--check"], ["anchors", "resolve", "--check"], ["stale"], ["coverage"],
                        ["impact", "--paths", "stuff/sources/fixture-rules.md.txt"]):
            code, first, _err = moved(command)
            arms.check("relocation: %s with every root passed is exit 0 with no default path in its output" % " ".join(command[:2]),
                       code == 0 and not any(p in "\n".join(first) for p in parts), first[-1:])
            for flag in ("--definitions", "--pack", "--registry", "--kinds"):
                code, lines, _err = moved(command, without=(flag,))
                arms.check("relocation: %s with %s omitted beneath a passed parent prints the same bytes" % (" ".join(command[:2]), flag),
                           code == 0 and lines == first, lines[-1:])
        for label, env in (("unset", {k: v for k, v in os.environ.items() if k != "CLAUDE_WORKSPACE_ROOT"}),
                           ("set to a decoy", dict(os.environ, CLAUDE_WORKSPACE_ROOT=str(cx.repo)))):
            code, lines, _err = moved(["build", "--check"], without=("--repo",), env=env)
            arms.check("relocation: --repo omitted is exit 3 naming it, with the workspace-root variable %s" % label,
                       code == 3 and "--repo" in lines[0] and "status=not-evaluated" in lines[-1], lines)
            code, lines, _err = moved(["build", "--check"], without=("--catalog-root", "--definitions", "--pack", "--registry", "--kinds"), env=env)
            arms.check("relocation: --catalog-root omitted is exit 3 naming it, with the workspace-root variable %s" % label,
                       code == 3 and "--catalog-root" in lines[0], lines)
    return arms.finish()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except PC.NotEvaluated as e:
        print("NOT-EVALUATED: %s" % e)
        print(PC.census("self-test", PC.EXIT_NOT_EVALUATED, [("arms", None), ("failed", None)]))
        sys.exit(PC.EXIT_NOT_EVALUATED)

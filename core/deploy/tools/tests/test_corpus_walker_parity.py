#!/usr/bin/env python3
"""test_corpus_walker_parity.py — the three deploy-tool corpus walkers agree on
whether a dot-leading path segment is in the corpus.

WHY THIS SUITE EXISTS, AND WHY IT IS NOT A SELF-TEST. Three tools walk the same
corpus: compose-portfolio.py::discover_rollups, stamp-node-frontmatter.py::
iter_corpus_files and build-doc-index.py::discover_files. They disagreed — two
carried a private dot-segment skip and the third carried none, so a rollup under
a dot-leading directory was out of corpus for two walkers and in it for the
third. This asserts they now agree, and agree on EXCLUSION.

It cannot live inside any one walker's --self-test: that would attribute a
three-party disagreement to whichever tool happened to host the assertion, and
folding it into _frontmatter.py's self-test would make the shared library import
its own consumers. So it is a consumer-level suite, deliberately.

It is also NOT enough to run the walkers' own self-tests. Measured against the
fixed tree: remove the shared skip entirely, or narrow it to directories only,
and stamp-node-frontmatter and build-doc-index BOTH still exit 0. Their
self-tests are blind to the axis this suite covers, and detect only an inverted
guard. For the two behaviour-preserving refactors, this file is the only real
verifier — a green self-test there is necessary, never sufficient.

WHY A PAIRED TWIN, AND NOT SET EQUALITY. The three walkers return DIFFERENT
populations by design — rollup-entity .md files, stampable-suffix files, and
metadata-bearing files including sidecar bases. Comparing their outputs compares
SELECTION, not traversal: a tree carrying one ordinary .md, or one .meta.yml
sidecar pair, splits their counts with zero dot-segments present. So this suite
holds the content CONSTANT and varies only the path's dot-segment shape. The
same bytes are written to a visible path and to two hidden paths; a difference
in verdict is then attributable to the traversal axis alone, which is the only
axis these changes touch.

WHY AGREEMENT ALONE IS NOT THE ASSERTION. "All three return the same inclusion
verdict" is satisfied by removing the skip from all three — they would agree, on
inclusion, having destroyed the corpus definition. A pure agreement test returns
GREEN on that tree. So the verdict arm asserts agreement AND that the agreed
verdict is EXCLUSION, and reports the two failures under distinct diagnostics so
they are never confused: DIVERGENCE (the walkers disagree) versus
AGREED-BUT-INCLUDED (they agree, wrongly).

Stdlib-only; Python 3.9 floor, matching the four tools it loads. No --self-test
flag and no top-level placement, both deliberate: either would pull this file
into the self-test manifest's scope globs and its per-tool row obligations, and
this is a test suite, not a tool. Run it directly:

    python3 core/deploy/tools/tests/test_corpus_walker_parity.py
"""
from __future__ import annotations

import importlib.util
import sys
import tempfile
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent

# The one shape all three walkers select: a rollup-entity markdown doc. The
# entity_type value must equal compose-portfolio's ROLLUP_ENTITY_TYPE EXACTLY —
# a trailing "# …" is CONTENT to the shared reader, not a comment, and would be
# classified as a polluted near-miss rather than a rollup.
DOC_BODY = """---
entity_type: Project Rollup (composed)
project_id: proj-gamma
title: Gamma Rollup
status: green
---

# Gamma Rollup

Body text. Identical at every planted path — only the PATH varies between the
visible twin and its hidden twins, so a verdict difference is attributable to
the dot-segment axis and to nothing else.
"""

VISIBLE = "proj-gamma/04-PMO-Operations/proj-gamma_Rollup.md"
# Hidden twin 1 — a dot-leading DIRECTORY segment.
HIDDEN_DIR = ".body-backups/proj-gamma/04-PMO-Operations/proj-gamma_Rollup.md"
# Hidden twin 2 — a dot-leading FILENAME, with every DIRECTORY segment clean, so
# this arm isolates the filename shape. The issue body names only the directory
# shape; the filename is over-returned identically and a directories-only fix is
# a half-fix that the walkers' own self-tests cannot see.
HIDDEN_NAME = "proj-gamma/04-PMO-Operations/.proj-gamma_Rollup.md"


def _load(filename: str, modname: str):
    """Load a hyphen-named tool module by path — they are not plain-importable.

    IMPLEMENTATION NOTE, learned the hard way. Each walker bootstraps its shared
    helper with a sys.path insert and a plain `import _frontmatter`, so loading
    walkers from MORE THAN ONE tree in a single process silently reuses the FIRST
    tree's _frontmatter — and every later tree reports a confident wrong answer.
    This suite loads one tree only and is unaffected. Any future extension across
    trees MUST purge "_frontmatter" from sys.modules between trees.
    """
    path = TOOLS_DIR / filename
    spec = importlib.util.spec_from_file_location(modname, path)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load %s" % path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[modname] = mod
    spec.loader.exec_module(mod)
    return mod


def _build_tree(root: Path) -> None:
    """Write the SAME bytes to the visible path and to both hidden paths."""
    for rel in (VISIBLE, HIDDEN_DIR, HIDDEN_NAME):
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(DOC_BODY, encoding="utf-8")


def _members(walker, root: Path) -> set:
    """The walker's returned paths, as root-relative POSIX strings.

    A walker that RAISES is not silently read as "returned nothing" — that would
    convert a hard failure into a passing exclusion. The exception propagates to
    main(), which reports it against the walker by name.
    """
    return {Path(p).relative_to(root).as_posix() for p in walker(root)}


def main() -> int:
    cp = _load("compose-portfolio.py", "_cwp_compose_portfolio")
    sn = _load("stamp-node-frontmatter.py", "_cwp_stamp_node")
    bd = _load("build-doc-index.py", "_cwp_build_doc_index")

    walkers = (
        ("cp", "compose-portfolio.discover_rollups", cp.discover_rollups),
        ("sn", "stamp-node-frontmatter.iter_corpus_files", sn.iter_corpus_files),
        ("bd", "build-doc-index.discover_files", bd.discover_files),
    )

    failures = []
    with tempfile.TemporaryDirectory() as td:
        root = Path(td) / "corpus"
        root.mkdir()
        _build_tree(root)

        sets = {}
        for key, label, fn in walkers:
            try:
                sets[key] = _members(fn, root)
            except Exception as exc:                      # noqa: BLE001
                failures.append(
                    "WALKER RAISED: %s raised %s: %s"
                    % (label, type(exc).__name__, exc))
                sets[key] = None

        if any(v is None for v in sets.values()):
            for f in failures:
                print("  - " + f, file=sys.stderr)
            print("corpus-walker parity FAILED: a walker did not return a set",
                  file=sys.stderr)
            return 1

        def triple(rel):
            return tuple(rel in sets[k] for k, _, _ in walkers)

        # (1) PRECONDITION — the visible twin is selected by ALL THREE. Without
        # this the verdict arm below is vacuous: three walkers that select
        # nothing at all would "agree on exclusion" for the hidden twins and pass
        # a broken fixture. It also catches an INVERTED guard, which reads False
        # here and names the walker that inverted it.
        pre = triple(VISIBLE)
        if pre != (True, True, True):
            named = ", ".join(
                "%s=%s" % (walkers[i][1], pre[i]) for i in range(3))
            print("PRECONDITION broken fixture: the VISIBLE twin %s must be "
                  "selected by all three walkers, read (%s) -> %s"
                  % (VISIBLE, named, pre), file=sys.stderr)
            print("corpus-walker parity FAILED: precondition", file=sys.stderr)
            return 1

        # (2) VERDICT — for each hidden twin the three verdicts must be EQUAL and
        # equal to False. Equality alone is not the assertion: see the module
        # docstring's anti-vacuity paragraph.
        for rel in (HIDDEN_DIR, HIDDEN_NAME):
            t = triple(rel)
            if len(set(t)) != 1:
                failures.append(
                    "DIVERGENCE on %s: cp/sn/bd=%s — the walkers disagree on "
                    "whether a dot-leading segment is in the corpus, which is "
                    "the defect this suite exists to catch" % (rel, t))
            elif t[0] is not False:
                failures.append(
                    "AGREED-BUT-INCLUDED %s: cp/sn/bd=%s — all three walkers "
                    "AGREE, and all three are wrong. A dot-leading segment is "
                    "out of corpus; agreeing to include it satisfies 'same "
                    "verdict' while destroying the corpus definition" % (rel, t))

    if failures:
        print("corpus-walker parity FAILED:", file=sys.stderr)
        for f in failures:
            print("  - " + f, file=sys.stderr)
        return 1
    print("corpus-walker parity OK (visible twin selected by all three / "
          "dot-leading DIRECTORY excluded by all three / dot-leading FILENAME "
          "excluded by all three)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

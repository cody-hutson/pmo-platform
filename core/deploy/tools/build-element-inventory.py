#!/usr/bin/env python3
"""build-element-inventory.py — the process catalog's element inventory.

PURPOSE
    Lists every tracked path of the repository with its element kind. A path's
    kind is the first matching row of the element-kinds table, a tracked data
    file (`element-kinds.tsv`) of `kind<TAB>pattern` rows; an unmatched path is
    `other`. Classification is by path alone: no file is ever opened, so no
    content — binary, empty, not UTF-8, a symbolic link — can change a row or
    raise an error.

USAGE (every root is an argument — see --help — and none is read from the environment)
    build-element-inventory.py [--rev REV] [--out FILE] [--summary]
    build-element-inventory.py --self-test

    Paths come from git in both modes: the index by default, a commit under --rev.
    One row per path, tab-separated: element_id (`<kind>:<path>`), kind, path, name
    (the base name without its last ending). A tab, a line feed or a backslash in a
    path is written as a C-style escape. --summary prints one row per kind with its
    count in place of the path rows. --out FILE writes the rows to FILE.

OUTPUT
    The rows, then one census line as the last line on standard output. A reader of
    the rows takes every line but the last.

EXIT CODES
    0  examined and clean
    2  usage (no census is printed: nothing ran)
    3  not evaluated — the kinds table, the repository or the commit could not be
       read, or the repository tracks no path
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
import _process_catalog as PC  # noqa: E402

ROOT_NAMES = ("repo", "catalog", "definitions", "kinds")
HEADER = "element_id\tkind\tpath\tname"


def escape(path: str) -> str:
    return path.replace("\\", "\\\\").replace("\t", "\\t").replace("\n", "\\n")


def tracked_paths(repo, rev=None) -> list:
    if rev is None:
        data = PC.git(repo, "ls-files", "-z")
    else:
        code, data = PC.git_run(repo, "ls-tree", "-r", "-z", "--name-only", rev)
        if code != 0:
            raise PC.NotEvaluated("the commit --rev names cannot be read")
    return sorted({p for p in data.decode("utf-8", "surrogateescape").split("\0") if p})


def inventory(paths: list, kinds: list) -> list:
    """[(element_id, kind, path, name)] — by path alone."""
    rows = []
    for path in paths:
        kind = PC.classify_path(path, kinds)
        base = os.path.basename(path)
        name = os.path.splitext(base)[0] or base
        rows.append(("%s:%s" % (kind, escape(path)), kind, escape(path), escape(name)))
    return rows


def run(a) -> int:
    pairs = [("paths", None), ("kinds", None), ("other", None)]
    try:
        roots = PC.resolve_roots(a)
        kinds = PC.load_kinds(roots.kinds)
        paths = tracked_paths(roots.repo, a.rev)
        if not paths:
            raise PC.NotEvaluated("the repository tracks no path")
        rows = inventory(paths, kinds)
        counts = Counter(row[1] for row in rows)
        if a.summary:
            lines = ["kind\tpaths"] + ["%s\t%d" % (k, counts[k]) for k in PC.kind_order(kinds) if counts.get(k)]
        else:
            lines = [HEADER] + ["\t".join(row) for row in rows]
        if a.out:
            PC.write_text(Path(a.out).resolve(), "\n".join(lines) + "\n")
        else:
            for line in lines:
                sys.stdout.write(line.encode("utf-8", "surrogateescape").decode("utf-8", "replace") + "\n")
        pairs = [("paths", len(rows)), ("kinds", len(counts)), ("other", counts.get("other", 0))]
        code = PC.EXIT_CLEAN
    except PC.NotEvaluated as e:
        print("NOT EVALUATED: %s" % e)
        code = PC.EXIT_NOT_EVALUATED
    print(PC.census("inventory", code, pairs))
    return code


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(description="List every tracked path with its element kind.")
    PC.add_root_arguments(ap, ROOT_NAMES)
    ap.add_argument("--rev", metavar="REV", help="read the paths of this commit in place of the index")
    ap.add_argument("--out", metavar="FILE", help="write the rows to FILE")
    ap.add_argument("--summary", action="store_true", help="one row per kind with its count")
    ap.add_argument("--self-test", action="store_true")
    return ap


def main(argv=None) -> int:
    a = build_parser().parse_args(argv)
    return self_test() if a.self_test else run(a)


# ----------------------------------------------------------------------------------------------
# Self-test — hermetic: a temporary repository built from the fixture tree and nothing else.
# ----------------------------------------------------------------------------------------------
def self_test() -> int:
    arms = PC.Arms()
    tool = str(Path(__file__).resolve())
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(os.path.realpath(td))
        PC.isolate_git(tmp)
        fx = PC.build_fixture_repo(tmp / "repo")
        first = PC.git(fx.repo, "rev-parse", "HEAD").decode("ascii").strip()
        odd = fx.repo / "odd"
        odd.mkdir()
        (odd / "holds-a-nul.bin").write_bytes(b"a\0b")
        (odd / "not-utf8.txt").write_bytes(b"\xff\xfe\xfa")
        (odd / "empty.txt").write_bytes(b"")
        os.symlink("empty.txt", odd / "a-link")
        (odd / "tab\there.txt").write_bytes(b"x")
        (odd / "back\\slash.txt").write_bytes(b"x")
        PC.write_text(fx.repo / "odd" / "deep" / "sources" / "second-match.md", "x\n")
        second = PC.commit_all(fx.repo, "odd files")
        base = ["--repo", str(fx.repo), "--catalog-root", str(fx.catalog), "--definitions", str(fx.definitions)]

        def cli(args, tool_path=tool, env=None, cwd=None):
            proc = subprocess.run([sys.executable, "-B", tool_path] + list(args), capture_output=True, text=True,
                                  env=env, cwd=cwd or str(tmp))
            return proc.returncode, (proc.stdout.rstrip("\n").split("\n") if proc.stdout.strip() else []), proc.stderr

        code, lines, _err = cli(base)
        rows = {l.split("\t")[2]: l.split("\t") for l in lines[1:-1]}
        arms.check("rows: exit 0, a header, one row per tracked path, the census last",
                   code == 0 and lines[0] == HEADER and len(rows) == len(lines) - 2
                   and lines[-1].startswith("process-catalog inventory status=pass exit=0 paths=%d kinds=" % len(rows)), lines[-1:])
        arms.check("rows: no data row opens like a census line",
                   not any(l.startswith("process-catalog ") for l in lines[:-1]))
        source = fx.layout["sources"] + "/fixture-rules.md.txt"
        arms.check("classification: the first matching row wins — a path two rows match takes the earlier kind",
                   rows[source][1] == "fixture-source" and rows[source][0] == "fixture-source:" + source
                   and rows["odd/deep/sources/second-match.md"][1] == "fixture-source", rows.get(source))
        arms.check("classification: an unmatched path is `other`, and the census counts it",
                   rows["odd/empty.txt"][1] == "other" and int(lines[-1].rsplit("other=", 1)[1]) >= 4, lines[-1:])
        arms.check("classification: the name is the base name without its last ending",
                   rows[source][3] == "fixture-rules.md" and rows["odd/a-link"][3] == "a-link")
        for label, path in (("a file that holds a NUL byte", "odd/holds-a-nul.bin"), ("a file that is not UTF-8", "odd/not-utf8.txt"),
                            ("an empty file", "odd/empty.txt"), ("a symbolic link", "odd/a-link")):
            arms.check("no file is opened: %s has a row" % label, path in rows)
        arms.check("escapes: a tab and a backslash in a path are written as C-style escapes",
                   "odd/tab\\there.txt" in rows and "odd/back\\\\slash.txt" in rows, [k for k in rows if k.startswith("odd/")])
        code, at_head, _err = cli(base + ["--rev", "HEAD"])
        arms.check("--rev: HEAD on a clean tree equals the index run", code == 0 and at_head == lines)
        code, at_first, _err = cli(base + ["--rev", first])
        arms.check("--rev: an earlier commit lists that commit's paths",
                   code == 0 and not any("\todd/" in l for l in at_first) and len(at_first) < len(lines))
        (fx.repo / "untracked.txt").write_text("x\n", encoding="utf-8")
        code, with_untracked, _err = cli(base)
        arms.check("the index: an untracked file has no row", with_untracked == lines)
        (fx.repo / "untracked.txt").unlink()
        code, summary, _err = cli(base + ["--summary"])
        arms.check("--summary: one row per kind with its count, in the kinds table's order, summing to the paths",
                   code == 0 and summary[0] == "kind\tpaths" and sum(int(l.split("\t")[1]) for l in summary[1:-1]) == len(rows)
                   and summary[1].startswith("fixture-source\t"), summary)
        target = tmp / "inventory.tsv"
        code, lines_out, _err = cli(base + ["--out", str(target)])
        arms.check("--out: the rows go to the file and standard output carries the census alone",
                   code == 0 and len(lines_out) == 1 and target.read_text(encoding="utf-8", errors="surrogateescape").rstrip("\n").split("\n") == lines[:-1])
        arms.check("clean checkout: the runs wrote nothing under the repository",
                   PC.git(fx.repo, "status", "--porcelain", "--untracked-files=all", "--ignored") == b"")
        code, lines_bad, _err = cli(base + ["--rev", "no-such-commit"])
        arms.check("nothing examined: a commit that cannot be read is exit 3", code == 3 and "status=not-evaluated" in lines_bad[-1], lines_bad)
        code, lines_bad, _err = cli(base + ["--kinds", str(tmp / "absent.tsv")])
        arms.check("nothing examined: a missing kinds table is exit 3, every census value unread",
                   code == 3 and lines_bad[-1] == "process-catalog inventory status=not-evaluated exit=3 paths=NA kinds=NA other=NA", lines_bad)
        empty = tmp / "tracks-nothing"
        (empty / "book").mkdir(parents=True)
        PC.git(empty, *(PC.TEST_IDENTITY + ("init", "-q")))
        code, lines_bad, _err = cli(["--repo", str(empty), "--catalog-root", str(empty / "book"), "--kinds",
                                     str(fx.definitions / PC.default_part("kinds"))])
        arms.check("nothing examined: a repository that tracks no path is exit 3", code == 3, lines_bad)
        code, _lines, err = cli(base + ["--no-such-option"])
        arms.check("usage: an unknown option is exit 2 with no census", code == 2 and "usage" in err and not _lines)
        decoy = tmp / "decoy"
        PC.write_text(decoy / "unrelated.txt", "x\n")
        PC.git(decoy, *(PC.TEST_IDENTITY + ("init", "-q")))
        PC.commit_all(decoy, "decoy")
        code, decoyed, _err = cli(base, env=dict(os.environ, GIT_DIR=str(decoy / ".git"), GIT_WORK_TREE=str(decoy)))
        arms.check("decoy variable: a repository-location variable pointing at another repository changes no row",
                   code == 0 and decoyed == lines)

        # -- relocation --
        moved_tools = PC.relocate_tools(tmp / "outside" / "a" / "b" / "c" / "tools")
        rx = PC.build_fixture_repo(tmp / "relocated", layout=PC.relocated_layout())
        every = {"--repo": str(rx.repo), "--catalog-root": str(rx.catalog), "--definitions": str(rx.definitions),
                 "--kinds": str(rx.definitions / PC.default_part("kinds"))}

        def moved(without=(), env=None):
            args = []
            for flag, value in every.items():
                if flag not in without:
                    args += [flag, value]
            return cli(args, tool_path=str(moved_tools / Path(tool).name), env=env, cwd=str(tmp / "outside"))

        parts = [row[2] for row in PC.DEFAULTS if row[1] == "repo"]
        code, first_run, _err = moved()
        arms.check("relocation: every root passed, exit 0 and no default path in the output",
                   code == 0 and not any(p in "\n".join(first_run) for p in parts), first_run[-1:])
        for flag in ("--definitions", "--kinds"):
            code, again, _err = moved(without=(flag,))
            arms.check("relocation: %s omitted beneath a passed parent prints the same bytes" % flag, code == 0 and again == first_run)
        for label, env in (("unset", {k: v for k, v in os.environ.items() if k != "CLAUDE_WORKSPACE_ROOT"}),
                           ("set to a decoy", dict(os.environ, CLAUDE_WORKSPACE_ROOT=str(decoy)))):
            code, out_lines, _err = moved(without=("--repo",), env=env)
            arms.check("relocation: --repo omitted is exit 3 naming it, with the workspace-root variable %s" % label,
                       code == 3 and "--repo" in out_lines[0], out_lines)
            code, out_lines, _err = moved(without=("--catalog-root", "--definitions", "--kinds"), env=env)
            arms.check("relocation: --catalog-root omitted is exit 3 naming it, with the workspace-root variable %s" % label,
                       code == 3 and "--catalog-root" in out_lines[0], out_lines)
    return arms.finish()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except PC.NotEvaluated as e:
        print("NOT EVALUATED: %s" % e)
        print(PC.census("self-test", PC.EXIT_NOT_EVALUATED, [("arms", None), ("failed", None)]))
        sys.exit(PC.EXIT_NOT_EVALUATED)

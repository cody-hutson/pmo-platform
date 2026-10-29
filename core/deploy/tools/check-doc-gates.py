#!/usr/bin/env python3
"""check-doc-gates.py — the predicate engine behind Check 28's release-context arms.

WHAT IT IS
    The engine `core/deploy/deploy.sh --check-doc-gates` runs at Stage 13 Close to
    evaluate the close gates of `core/schemas/gate-criteria-spec.md` Gate 13 that grade
    ONE release's commit range: g-cl6, g-cl8, g-cl10.

      g-cl6  Design artifacts refreshed: every artifact the release plan's
             "Tier-A activated design artifacts" section declares was touched in
             <base>..<head>, with a body delta above 3 lines (frontmatter excluded).
      g-cl8  Documentation Impact resolved: every issue of the release whose body carries a
             `### Documentation Impact` section has each declared row resolved by the
             action-keyed method of the G-CL8 row (link / create / update / retire),
             or reads exactly `None — no documentation impact (rationale: <phrase>)`.
      g-cl10 Declared obligations measured: every gate-coverage register row whose Surface
             leads with `prose` that <base>..<head> added or modified declares its
             population, and the release plan's record of it meets the threshold or names
             an open owning work item outside the release whose body or comments name the
             population (arm i); every limb of the milestone's Release Outcome Statement
             names an owning work item (arm ii). `--list` prints both before measurement.

    The criteria are NOT restated here; the G-CL6, G-CL8 and G-CL10 rows are their
    authority and this file implements them. Where this file and those rows disagree, the
    rows win and this file is the defect.

    `grade_declaration()` is the G-CL8 declaration grammar alone — no git, no network, no
    release range — and the one implementation of it: `eval_issue` adds the resolution
    pass at close, and Gate 3 criterion G3-20 reads it at the `status: bundled`
    transition through `release/tools/bundle-issues-parser.py`, which loads this file by
    path. The self-test's GD-PARITY arm holds the two to the same verdict whenever
    resolution is held constant.

WHAT IT IS NOT
    It writes nothing. It never touches the warn log, the network or GitHub: deploy.sh
    resolves the release context (the PR, <base>, <head>, the issue bodies, the milestone
    description, each owning work item's JSON and comments) and hands this engine files
    and commit ids, then turns FAIL lines into warn-log rows through the shared sink's one
    append path. Keeping the engine offline is what lets `--self-test` exercise every arm
    in CI with no credentials. It never runs a probe a register row declares: it grades
    the record a Stage 13 spoke wrote, bound to the declaration by the probe string and a
    pin that contains <head>.

OUTPUT CONTRACT (stdout, one line per subject, tab-separated)
    <RESULT>\t<gate>\t<subject>\t<detail>
        RESULT  PASS | FAIL | OUT-OF-SCOPE | NOT-EVALUATED
    SUMMARY\t<gate>\tevaluated=<n>\tfail=<f>\tnot_evaluated=<x>\tout_of_scope=<o>
    Exit 0 = the run completed (the verdict is in the lines); 2 = usage; 3 = an input
    could not be resolved (a commit id, the plan, the issues directory) and nothing was
    evaluated. A subject the engine could not evaluate is NOT-EVALUATED, never PASS.

Stdlib only, plus the platform's shared frontmatter reader (_frontmatter.py) and the
canonical link resolver of check-doc-links.py, both loaded by path.
"""
from __future__ import annotations

import argparse
import difflib
import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    return mod


_fm = _load("_frontmatter", HERE / "_frontmatter.py")

ACTIONS = ("link", "create", "update", "retire")
EXPLICIT_NONE = re.compile(r"^None — no documentation impact \(rationale: (.+)\)$")
# The G-CL8 row's corpus-scope boundary names two out-of-scope classes; a declared row
# under either is recorded OUT-OF-SCOPE, never failed.
OUT_OF_SCOPE_PREFIXES = ("projects/", "release/releases/")
# Re-pointing exclusions for the retire inbound limb (G-CL8 row, Retire verification).
INBOUND_EXCLUDED_PREFIXES = ("release/releases/", "core/ADRs/", "release/ADRs/")
# The G-CL8 row's corpus scope, which bounds whose inbound reference counts as live.
CORPUS_PREFIXES = ("core/", "release/governance/", "release/references/", "docs/")
CORPUS_SKILL_RE = re.compile(r"^(operations|release)/skills/[^/]+/(SKILL\.md|references/)")
PATHLIKE = re.compile(r"^(?:[\w.<>*{}-]+/)+[\w.<>*{}-]*$|^[\w.-]+\.(?:md|ya?ml|sh|py|txt|toml|json)$")
TIER_A_HEADING = re.compile(r"^#{2,4}\s+tier-a activated design artifacts\s*$", re.I)
CATALOG_PREFIX = "core/process-catalog/"


def git(root: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)


def is_commit(root: Path, rev: str) -> bool:
    return git(root, "cat-file", "-e", f"{rev}^{{commit}}").returncode == 0


def exists_at(root: Path, rev: str, path: str) -> bool:
    return git(root, "cat-file", "-e", f"{rev}:{path}").returncode == 0


def show(root: Path, rev: str, path: str) -> str | None:
    r = git(root, "show", f"{rev}:{path}")
    return r.stdout if r.returncode == 0 else None


def show_bytes(root: Path, rev: str, path: str) -> bytes | None:
    """show() without decoding: the blob's bytes, for a file that may not be text."""
    r = subprocess.run(["git", "-C", str(root), "show", f"{rev}:{path}"], capture_output=True)
    return r.stdout if r.returncode == 0 else None


def changed_in_release(root: Path, base: str, head: str, path: str) -> bool:
    """The release changed `path`: its content differs between <base> and <head>. The
    G-CL8 test of a `link` row; `create` and `update` read body_changed_in_release().

    A NET diff, deliberately not `git log <base>..<head> -- <path>`. Over a release range
    that synced main in mid-flight, the log lists the sync MERGES that carried main's own
    edits to the file, so a doc the release never touched reads as modified; and
    `--follow` drops merge commits, so it under-counts the other way. Measured on a real
    release range: plain log 2 commits, --follow 0, net diff none — the declaration was
    genuinely unresolved. A directory path works the same way."""
    r = git(root, "diff", "--quiet", base, head, "--", path)
    return r.returncode == 1


def frontmatter_of(text: str | None) -> tuple[dict, str]:
    """Read a git-object blob through the ONE shared frontmatter reader."""
    if text is None:
        return {}, "no-file"
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as fh:
        fh.write(text)
        tmp = fh.name
    try:
        return _fm.read_frontmatter(Path(tmp))
    finally:
        os.unlink(tmp)


def frontmatter_of_blob(blob: bytes) -> tuple[dict, str]:
    """frontmatter_of() for a blob read as bytes. A blob that is not UTF-8 text, such as
    a binary package, has no frontmatter block and so no `status` field; it is not read
    as text, which would raise, and one row would withhold the gate for the release."""
    try:
        text = blob.decode("utf-8")
    except UnicodeDecodeError:
        return {}, "no-frontmatter"
    return frontmatter_of(text)


def body_lines(text: str | None) -> list[str]:
    """The document minus its frontmatter block (the delta G-CL6 measures)."""
    if text is None:
        return []
    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        for i in range(1, len(lines)):
            if lines[i].strip() == "---":
                return lines[i + 1:]
    return lines


def body_changed_in_release(root: Path, base: str, head: str, path: str) -> bool:
    """The release changed `path`'s BODY: the G-CL8 test of a `create` or `update` row.

    The files the net diff of changed_in_release() names, each compared through
    body_lines() — the frontmatter-excluded reader G-CL6 measures with — so a change
    confined to a document's frontmatter (a `last_verified_commit` restamp alone) does
    not resolve a row, and neither does a created document whose body is empty or blank.
    A directory path resolves when the body of any file under it changed; its own
    `git show` is a tree listing, so it is never compared as one. A file that is not
    UTF-8 text at either end — a binary such as a `.skill` package — has no frontmatter
    block, so its whole content is its body and the two blobs are compared byte for byte;
    reading it as text would raise, and one row would withhold the gate for the release."""
    r = git(root, "diff", "--name-only", "-z", "--no-renames", base, head, "--", path)
    for f in (p for p in r.stdout.split("\0") if p):
        blobs = [show_bytes(root, rev, f) or b"" for rev in (base, head)]
        try:
            before, after = ("\n".join(body_lines(b.decode("utf-8"))).strip() for b in blobs)
        except UnicodeDecodeError:
            before, after = blobs
        if before != after:
            return True
    return False


def leading_token(value: str) -> str:
    m = re.match(r"\s*([A-Za-z]+)", value or "")
    return m.group(1).upper() if m else ""


def in_corpus(path: str) -> bool:
    return (path.startswith(CORPUS_PREFIXES) or bool(CORPUS_SKILL_RE.match(path))
            or path == "core/CLAUDE.md.template")


def short(rev: str) -> str:
    return rev[:8]


# ─── G-CL6 ────────────────────────────────────────────────────────────────────
def _first_repo_path(text: str) -> str | None:
    return next((t.strip().rstrip("/") for t in re.findall(r"`([^`]+)`", text)
                 if "/" in t and " " not in t.strip() and not t.strip().startswith(("http", "#"))), None)


def tier_a_rows(plan_text: str) -> tuple[list[tuple[str | None, str]], str | None]:
    """-> ([(path or None, row text)], error). Empty list + None = no Tier-A section.

    Real plans vary the table: the artifact column is headed `Artifact path` or
    `Artifact`, in any position, and some put the path in a later column. The path is
    the first backticked repository path in the artifact column, else anywhere in the
    row. A row recording a NOT ACTIVATED determination is returned so the caller can
    record it as out of scope; a row naming no path at all is the caller's FAIL."""
    lines = plan_text.splitlines()
    start = next((i for i, l in enumerate(lines) if TIER_A_HEADING.match(l)), None)
    if start is None:
        return [], None
    rows, col, header_seen, in_table = [], None, False, False
    for line in lines[start + 1:]:
        if re.match(r"^#{1,4}\s", line):
            break
        if not line.lstrip().startswith("|"):
            if in_table:
                break
            continue
        in_table = True
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not header_seen:
            header_seen = True
            heads = [c.lower() for c in cells]
            col = next((k for k, c in enumerate(heads) if "artifact" in c and "path" in c),
                       next((k for k, c in enumerate(heads) if "artifact" in c), None))
            continue
        if set("".join(cells)) <= set("-: "):
            continue
        path = (_first_repo_path(cells[col]) if col is not None and col < len(cells) else None) \
            or _first_repo_path(line)
        rows.append((path, line))
    return rows, None


def eval_gcl6(root: Path, base: str, head: str, plan_text: str) -> list[tuple[str, str, str]]:
    rows, err = tier_a_rows(plan_text)
    if err:
        return [("FAIL", "release plan", f"Tier-A section is malformed: {err}")]
    out = []
    for path, cell in rows:
        if re.search(r"\bnot activated\b", cell, re.I):
            out.append(("OUT-OF-SCOPE", path or "release plan row", "the row records a NOT ACTIVATED determination"))
            continue
        if not path:
            out.append(("FAIL", "release plan row", "the declaration names no repository path, so its refresh cannot be checked"))
            continue
        if path.startswith(CATALOG_PREFIX):
            out.append(("OUT-OF-SCOPE", path, "a process-catalog page; G-CL6 does not read catalog pages (design-artifact standard § How the catalog composes with §§ 2–12)"))
            continue
        if re.search(r"[<>*{}]", path):
            out.append(("FAIL", path, "declared path is a placeholder, not a file"))
            continue
        if not exists_at(root, head, path):
            out.append(("FAIL", path, f"declared artifact is absent at the release head {short(head)}"))
            continue
        # Both blobs are read as bytes. An artifact that is not UTF-8 text at either end has
        # no frontmatter block, so its whole content is its body, measured in lines split at
        # its newline bytes; reading it as text would raise and withhold the gate.
        blobs = [show_bytes(root, rev, path) or b"" for rev in (base, head)]
        try:
            old, new = (body_lines(b.decode("utf-8")) for b in blobs)
            delta = sum(1 for d in difflib.unified_diff(old, new, lineterm="", n=0)
                        if d[:1] in "+-" and not d.startswith(("+++", "---")))
        except UnicodeDecodeError:
            old, new = (b.splitlines() for b in blobs)
            delta = sum(1 for d in difflib.diff_bytes(difflib.unified_diff, old, new, lineterm=b"", n=0)
                        if d[:1] in b"+-" and not d.startswith((b"+++", b"---")))
        qual = " (file-level: an embedded artifact's region is not bounded)" if "§" in cell or "#" in cell.split(path)[-1][:3] else ""
        if delta <= 3:
            out.append(("FAIL", path, f"body delta {delta} line(s) <= 3, frontmatter excluded{qual}"))
        else:
            out.append(("PASS", path, f"body delta {delta} lines in {short(base)}..{short(head)}{qual}"))
    return out


# ─── G-CL8 ────────────────────────────────────────────────────────────────────
# An HTML comment as a renderer reads it: `<!-->` and `<!--->` close at once; any other
# `<!--` runs to the first `-->`, to the first `--!>` (HTML reads that as a close too), or
# to the end of the text when it is never closed. The dot matches newlines, so a comment
# spanning lines is one match.
HTML_COMMENT = re.compile(r"<!--(?:-?>|.*?(?:--!?>|\Z))", re.S)


def doc_impact_section(body: str) -> list[str] | None:
    """-> content lines of `### Documentation Impact`, or None when the body has none.

    Comments are stripped from the text after the heading in ONE pass, before the
    section's end is found: a heading inside a comment does not end the section, and a
    row inside a comment, on one line or across several, is not graded."""
    lines = body.replace("\r\n", "\n").split("\n")
    start = next((i for i, l in enumerate(lines) if l.strip() == "### Documentation Impact"), None)
    if start is None:
        return None
    content = []
    for line in HTML_COMMENT.sub("", "\n".join(lines[start + 1:])).split("\n"):
        if re.match(r"^#{1,3}\s", line):
            break
        text = line.strip()
        if not text or text == "_No response_" or text == "— OR —":
            continue
        content.append(text)
    return content


def inbound_refs(root: Path, doc: str, arm: str) -> tuple[list[str] | None, str]:
    """Live inbound referrers of `doc` at the scan root -> (referrers, note); None = not evaluated."""
    tool = root / "release/tools/blast-radius.sh"
    if not tool.is_file():
        return None, "release/tools/blast-radius.sh absent at the scan root"
    args = [str(tool), "--format=json", f"--root={root}"]
    args += ["--mode=structural", doc] if arm == "b" else ["--depth=1", doc]
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode not in (0, 6):
        return None, f"blast-radius.sh exited {r.returncode}"
    try:
        entries = json.loads(r.stdout).get("first_order", [])
        # A referrer whose every match is a supersession line (`supersedes:`) is the
        # successor naming its predecessor, which the G-CL8 row exempts.
        refs = {e["path"] for e in entries
                if not all(m.get("snippet", "").lstrip().startswith("supersedes:")
                           for m in e.get("matches", []) or [{}])}
    except (ValueError, KeyError, TypeError, AttributeError):
        return None, "blast-radius.sh output did not parse"
    if arm == "b":
        links = root / "core/deploy/tools/check-doc-links.py"
        scope = root / "core/deploy/allowlists/doc-link-target-paths.txt"
        if not (links.is_file() and scope.is_file()):
            return None, "check-doc-links.py or its scope list is absent at the scan root"
        r = subprocess.run([sys.executable, str(links), "--workspace-root", str(root),
                            "--target-paths-file", str(scope), "--require-targets",
                            "--output-format", "json"], capture_output=True, text=True)
        if r.returncode == 3:
            return None, "check-doc-links.py could not resolve its scan surface (exit 3)"
        try:
            findings = json.loads(r.stdout or "[]")
            findings = findings.get("findings", findings) if isinstance(findings, dict) else findings
        except ValueError:
            return None, "check-doc-links.py output did not parse"
        resolver = _load("check_doc_links", links)
        gone = os.path.realpath(root / doc)
        for f in findings:
            src = root / f["source_file"]
            resolved, _ = resolver.resolve_target(src, f["target"], root)
            if os.path.realpath(resolved) == gone:
                refs.add(f["source_file"])
    live = sorted(p for p in refs
                  if p != doc and in_corpus(p)
                  and not p.startswith(INBOUND_EXCLUDED_PREFIXES))
    return live, ""


def verify_retire(root: Path, base: str, head: str, doc: str) -> tuple[str, str]:
    """The G-CL8 retire verification. Both blobs are read as bytes: a document that is
    not UTF-8 text at the base carries no `status` field, so it takes arm (b), deletion;
    one that is not text at the head of an arm (a) retire reads its status as absent."""
    base_blob = show_bytes(root, base, doc)
    if base_blob is None:
        return "FAIL", "retire declared for a document absent at the release base"
    keys, status = frontmatter_of_blob(base_blob)
    successor = None
    if status == "ok" and keys.get("status", "").strip():
        arm = "a"
        head_blob = show_bytes(root, head, doc)
        if head_blob is None:
            return "FAIL", "carries the status field and was deleted — retire it by a status move instead"
        hkeys, _ = frontmatter_of_blob(head_blob)
        tok = leading_token(hkeys.get("status", ""))
        if tok not in ("DEPRECATED", "SUPERSEDED"):
            return "FAIL", f"status at head is {tok or 'absent'}, not DEPRECATED or SUPERSEDED"
        successor = hkeys.get("superseded_by", "").strip() or None
        if tok == "SUPERSEDED" and doc.startswith(CATALOG_PREFIX) and not successor:
            return "FAIL", "SUPERSEDED catalog page names no successor in superseded_by"
    else:
        arm = "b"
        if exists_at(root, head, doc):
            return "FAIL", "carries no status field, so retire means deletion, but it still exists at head"
    if git(root, "merge-base", "--is-ancestor", head, "HEAD").returncode != 0:
        return "NOT-EVALUATED", f"inbound limb: the scan root does not contain the release head {short(head)}"
    live, note = inbound_refs(root, doc, arm)
    if live is None:
        return "NOT-EVALUATED", f"inbound limb: {note}"
    if live:
        return "FAIL", f"arm ({arm}): {len(live)} live inbound reference(s): {', '.join(live[:3])}"
    return "PASS", f"arm ({arm}): retired with zero live inbound references"


# ─── G-CL8 declaration grammar ───────────────────────────────────────────────
# One rule decides what a line of the section is. A line carrying `|` is row-shaped:
# it yields graded rows, or it is a named FAIL — never commentary. A line without `|`
# is commentary and is not graded, whatever it names (measured over every issue body
# carrying the section: a stricter rule that also failed pipe-less lines naming a path
# failed scope notes, row continuations and struck-out lines, not undelivered rows) —
# with ONE exception, keyed on the marker and not on the line's shape: a pipe-less line
# carrying the `[ASSUMPTION – CONFIRM]` marker is a declaration not yet decided. It
# FAILs as unresolved, as a qualified action cell does, because both are the same state
# — a conditional declaration, which is resolved at Stage 5 — and one state must not
# read FAIL in one spelling and PASS in the other.
# A row's path is read through every shape the field licenses — a line range, an
# anchor, or a `§` section after the path, and several comma-separated paths in one
# cell — and every row on a line is graded. Every action-word cell must belong to a
# row, so no row-shaped fragment can be dropped while another row PASSes.
PATH_SUFFIX = re.compile(r"(?::\d+(?:-\d+)?|#[^\s|]*)$")   # a line range or an anchor
LEAD_PUNCT, TRAIL_PUNCT = "([{\"'*", ")]}\"'*.,;:"
RUN_CONNECTORS = {",", "and", "&", "+"}
ASSUMPTION_MARKER = re.compile(r"\[ASSUMPTION\b")          # the evidence label of an open assumption


def path_token(tok: str) -> str | None:
    """A repository-path token, normalized, or None. Strips edge punctuation, then a
    trailing line range (`:120-140`) or anchor (`#section`), so the shapes the field
    licenses resolve to the file they qualify."""
    t = tok.lstrip(LEAD_PUNCT).rstrip(TRAIL_PUNCT)
    if "://" in t:
        return None
    t = PATH_SUFFIX.sub("", t).rstrip(TRAIL_PUNCT)
    return t.rstrip("/") if t and PATHLIKE.match(t) else None


def cell_paths(cell: str, first: bool) -> list[str]:
    """The paths a cell declares. The first cell of a line: every path token before a
    `§` section suffix. A later cell is the previous row's reason, and it declares only
    the run of path tokens it ENDS with (the next row's path), optionally followed by a
    `§` suffix."""
    toks = cell.split()
    if first:
        cut = next((k for k, t in enumerate(toks) if t.startswith("§")), len(toks))
        return [p for p in (path_token(t) for t in toks[:cut]) if p]
    last = next((k for k in range(len(toks) - 1, -1, -1) if path_token(toks[k])), None)
    if last is None or (last + 1 < len(toks) and not toks[last + 1].startswith("§")):
        return []
    run, k = [], last
    while k >= 0 and (path_token(toks[k]) or toks[k].lower() in RUN_CONNECTORS):
        if path_token(toks[k]):
            run.insert(0, path_token(toks[k]))
        k -= 1
    return run


def norm_action(cell: str) -> str:
    return cell.strip().strip("*_").rstrip(".,;:").strip().lower()


def is_separator(line: str) -> bool:
    return "|" in line and set(line.replace("|", "").strip()) <= set("-: ") and "-" in line


def parse_row_line(line: str) -> tuple[list[tuple[str, str]], list[str]]:
    """-> ([(path, action cell)], [orphan action cells]) for a line carrying `|`."""
    s = line.strip()
    if s.startswith("|"):
        s = s.strip("|")                                 # a markdown table row's outer pipes
    cells = [c.strip() for c in s.split("|")]
    rows, consumed, i = [], set(), 0
    while i < len(cells) - 1:
        paths = cell_paths(cells[i], first=(i == 0))
        if paths:
            rows += [(p, cells[i + 1]) for p in paths]
            consumed.add(i + 1)
            i += 2
        else:
            i += 1
    orphans = [cells[k] for k in range(1, len(cells))
               if k not in consumed and norm_action(cells[k]) in ACTIONS]
    return rows, orphans


def excerpt(line: str, n: int = 80) -> str:
    return line if len(line) <= n else line[: n - 1] + "…"


def grade_declaration(body: str) -> tuple[str, str, list[tuple[str, str, str, str]] | None, list[str], int]:
    """The G-CL8 declaration grammar alone: no git, no network, no release range.

    -> (verdict, detail, rows, findings, prose)
        verdict   OUT-OF-SCOPE (no `### Documentation Impact` section) | FAIL (a grammar
                  finding) | PASS (a declaration the close gate can grade)
        detail    the grammar's own message
        rows      None when the verdict is already final without a row pass (no section, an
                  empty field, the None forms, no row at all); otherwise every declared row
                  in declaration order as (path, action, kind, finding), kind one of
                  `graded` (left for the resolution pass), `out-of-scope`, `unknown-action`
                  or `placeholder` (the last three carry their message in `finding`)
        findings  the line-level grammar findings: unparseable, orphan action cell,
                  unresolved-assumption line
        prose     commentary lines ignored

    This is the one implementation of the grammar: `eval_issue` adds the resolution pass
    on top of it at close, and the bundle gate G3-20 reads it at the `status: bundled`
    transition through `release/tools/bundle-issues-parser.py`, so the two gates cannot
    disagree about a declaration's grammar."""
    content = doc_impact_section(body)
    if content is None:
        return "OUT-OF-SCOPE", "body carries no ### Documentation Impact section", None, [], 0
    if not content:
        return "FAIL", "Documentation Impact section is present but empty", None, [], 0
    if len(content) == 1 and content[0].lstrip("-*+ ").startswith("None"):
        line = content[0].lstrip("-*+ ").strip("`")
        if EXPLICIT_NONE.match(line) and EXPLICIT_NONE.match(line).group(1).strip():
            return "PASS", "explicit None with a rationale", None, [], 0
        return ("FAIL", "None without the exact `None — no documentation impact (rationale: …)` form",
                None, [], 0)
    lines = [re.sub(r"^\s*(?:[-*+]|\d+[.)])\s+", "", raw).replace("`", "") for raw in content]
    findings, parsed, prose = [], [], 0
    for k, line in enumerate(lines):
        if "|" in line:
            if is_separator(line) or (line.strip().startswith("|") and k + 1 < len(lines)
                                      and is_separator(lines[k + 1])):
                continue                                 # a table's header or separator row
            got, orphans = parse_row_line(line)
            if not got:
                findings.append(f'unparseable declaration line "{excerpt(line)}": it carries "|" '
                                "but names no `path | action | reason` row")
                continue
            parsed += got
            findings += [f'a `{o}` action cell with no path before it, on "{excerpt(line)}"' for o in orphans]
        elif ASSUMPTION_MARKER.search(line):
            findings.append(f'unresolved declaration "{excerpt(line)}": an `[ASSUMPTION – CONFIRM]` '
                            "line in the field is a conditional declaration, resolved at Stage 5 — "
                            "rewrite it as a `path | action | reason` row or remove it")
        else:
            prose += 1          # commentary: the line carries no "|"
    if not parsed and not findings:
        return ("FAIL", "no `path | action | reason` row, and the field is not exactly "
                        "`None — no documentation impact (rationale: …)`", None, [], prose)
    rows: list[tuple[str, str, str, str]] = []
    for path, action_cell in parsed:
        path = "core/CLAUDE.md.template" if path == "CLAUDE.md" else path
        action = norm_action(action_cell)
        if action not in ACTIONS:
            rows.append((path, action, "unknown-action",
                         f"{path}: unknown action `{action_cell}` — the action is exactly one of "
                         "link, create, update or retire; a qualifier belongs in the reason, and a "
                         "conditional declaration is resolved at Stage 5"))
        elif path.startswith(OUT_OF_SCOPE_PREFIXES):
            rows.append((path, action, "out-of-scope", f"{path}: out of the G-CL8 corpus scope"))
        elif re.search(r"[<>*{}]", path):
            rows.append((path, action, "placeholder", f"{path} | {action}: placeholder path"))
        else:
            rows.append((path, action, "graded", ""))
    fails = findings + [f for _, _, kind, f in rows if kind in ("unknown-action", "placeholder")]
    if fails:
        return "FAIL", "; ".join(fails), rows, findings, prose
    notes = [f for _, _, kind, f in rows if kind == "out-of-scope"]
    extra = notes + ([f"{prose} commentary line(s) ignored"] if prose else [])
    gradable = sum(1 for _, _, kind, _ in rows if kind == "graded")
    return ("PASS", f"{gradable} declared row(s) gradable" + (f" ({'; '.join(extra)})" if extra else ""),
            rows, findings, prose)


def eval_issue(root: Path, base: str, head: str, body: str) -> tuple[str, str]:
    """G-CL8 for one issue body: the declaration grammar (`grade_declaration`), then the
    resolution pass over the release range. Findings read in declaration order — the
    line-level grammar findings first, then each row's finding, grammar or resolution."""
    verdict, detail, rows, findings, prose = grade_declaration(body)
    if rows is None:
        return verdict, detail
    fails, notes, unevaluated = list(findings), [], []
    graded = 0
    for path, action, kind, finding in rows:
        if kind == "unknown-action":
            fails.append(finding)
            continue
        if kind == "out-of-scope":
            notes.append(finding)
            continue
        graded += 1
        if kind == "placeholder":
            fails.append(finding)
            continue
        if action == "retire":
            res, why = verify_retire(root, base, head, path)
            if res == "FAIL":
                fails.append(f"{path} | retire: {why}")
            elif res == "NOT-EVALUATED":
                unevaluated.append(f"{path} | retire: {why}")
            continue
        if not exists_at(root, head, path):
            fails.append(f"{path} | {action}: absent at the release head {short(head)}")
        elif action == "link" and not changed_in_release(root, base, head, path):
            fails.append(f"{path} | link: unchanged between {short(base)} and {short(head)}")
        elif action != "link" and not body_changed_in_release(root, base, head, path):
            fails.append(f"{path} | {action}: unchanged between {short(base)} and {short(head)}, "
                         "frontmatter excluded")
    if fails:
        return "FAIL", "; ".join(fails + unevaluated)
    if unevaluated:
        return "NOT-EVALUATED", "; ".join(unevaluated)
    extra = notes + ([f"{prose} commentary line(s) ignored"] if prose else [])
    return "PASS", f"{graded} declared row(s) resolved" + (f" ({'; '.join(extra)})" if extra else "")


def eval_gcl8(root: Path, base: str, head: str, issues_dir: Path) -> list[tuple[str, str, str]]:
    out = []
    for f in sorted(issues_dir.glob("*.md"), key=lambda p: (len(p.stem), p.stem)):
        try:
            body = f.read_text(encoding="utf-8")
        except OSError:
            out.append(("NOT-EVALUATED", f"#{f.stem}", "issue body unreadable"))
            continue
        res, detail = eval_issue(root, base, head, body)
        out.append((res, f"#{f.stem}", detail))
    return out


# ─── G-CL10 ───────────────────────────────────────────────────────────────────
# The declared obligations of one release, measured at close. Arm (i) reads the
# gate-coverage register: every row whose Surface cell leads with `prose` — a predicate
# nothing executes — that the release added or modified carries a `**Population:**`
# segment, and the release plan carries that population's record. Arm (ii) reads the
# milestone's Release Outcome Statement: every limb names an owning work item. The
# criterion is the G-CL10 row; this section implements it and never runs a probe.
REGISTER_PATH = "core/standards/gate-efficacy-standard.md"
REGISTER_HEADING = re.compile(r"^##\s+Gate-coverage register\b")
CELL_SPLIT = re.compile(r"(?<!\\)\|")
POPULATION_SEGMENT = re.compile(
    r"\*\*Population:\*\*\s*`(?P<name>[^`|]+)`\s*—\s*population:\s*(?P<members>.+?);\s*"
    r"probe:\s*`(?P<probe>[^`]+)`;\s*threshold:\s*(?P<threshold>\d{1,3})%")
POPULATION_NAME = re.compile(r"\*\*Population:\*\*\s*`([^`|]+)`")
# The segment closes its cell: normalization drops it through to the cell's end, so a
# row whose only change is the segment is not a row the release modified.
SEGMENT_SPAN = re.compile(r"\*\*Population:\*\*.*?(?=(?<!\\)\||$)")
# The population-record labels of gate-efficacy-standard.md Requirement (c), in order.
RECORD_LABELS = ("population", "probe", "examined", "sensitivity", "specificity", "state", "exempted")
ROS_HEADING = re.compile(r"^###\s+Release Outcome Statement\s*$")
LIMB_LINE = re.compile(r"^\s*\*{0,2}Limb owners:\*{0,2}\s*(.+?)\s*$")
LOCK_DATE = re.compile(r"\*\*Locked at:\*\*\s*Stage 4 Planning entry\s*·\s*(\d{4}-\d{2}-\d{2})")
ABANDONED_REASONS = ("not_planned", "duplicate")


def register_rows(text: str | None) -> list[str] | None:
    """The data rows of the gate-coverage register, raw: the table rows between the
    heading opening `## Gate-coverage register` and the next `## `, header and separator
    excluded. None when the text is absent or carries no such heading."""
    if text is None:
        return None
    lines = text.splitlines()
    start = next((i for i, l in enumerate(lines) if REGISTER_HEADING.match(l)), None)
    if start is None:
        return None
    rows, header = [], False
    for line in lines[start + 1:]:
        if line.startswith("## "):
            break
        if not line.lstrip().startswith("|") or is_separator(line):
            continue
        if not header:
            header = True
            continue
        rows.append(line.strip())
    return rows


def row_cells(row: str) -> list[str]:
    parts = [c.strip() for c in CELL_SPLIT.split(row.strip())]
    if parts and parts[0] == "":
        parts = parts[1:]
    if parts and parts[-1] == "":
        parts = parts[:-1]
    return parts


def surface_word(row: str) -> str:
    """The Surface cell's first word, lowercased, after any leading `*`, `_` or backtick:
    markup is not spelling, so a `**prose**` cell leads with `prose`."""
    cells = row_cells(row)
    if len(cells) < 3:
        return ""
    m = re.match(r"([A-Za-z][A-Za-z-]*)", re.sub(r"^[\s*_`]+", "", cells[2]))
    return m.group(1).lower() if m else ""


def norm_row(row: str) -> str:
    return " ".join(SEGMENT_SPAN.sub("", row).split())


# CD-1: no declaration states its population unmeasurable, in any spelling. A probe is
# an exact invocation or a census definition (`<kind> census — …`); one that OPENS on a
# placeholder word, or on a bare dash or ellipsis, is neither, and would otherwise reach
# the close as `not-run` and pass on an owner alone. The test is the first word, whole
# and case-folded, so a command or census kind that merely begins like one of these
# (`native-dep-mirror.py`, `notes census —`, `tbd-report`) still parses. Whether any
# other string really is an invocation stays the close reviewer's read.
PLACEHOLDER_WORD = re.compile(
    r"none|nil|null|n/?a|n\.a\.?|tb[acd]|todo|unknown|unmeasur(?:able|ed)|immeasurable|"
    r"not|no|nothing", re.I)
BARE_WORD = re.compile(r"[-‐‑‒–—―.…?*_/\\]+")


def placeholder_probe(probe: str) -> str | None:
    """The placeholder `probe` opens on, or None when it opens on a word that can begin an
    invocation or a census definition."""
    words = probe.split()
    if not words:
        return probe
    first = words[0]
    if first[0] in "-‐‑‒–—―" or BARE_WORD.fullmatch(first):
        return first
    word = re.split(r"[–—―]", first, maxsplit=1)[0].strip(".,;:!?()[]{}'\"")
    if not word or PLACEHOLDER_WORD.fullmatch(word):
        return first
    return None


def parse_population(row: str) -> tuple[dict | None, str | None]:
    """-> (declaration, None) or (None, `declaration-missing` / `declaration-malformed` …)."""
    if "**Population:**" not in row:
        return None, "declaration-missing: the row carries no **Population:** segment"
    m = POPULATION_SEGMENT.search(row)
    if not m:
        return None, ("declaration-malformed: the segment does not read "
                      "**Population:** `<name>` — population: <member definition>; "
                      "probe: `<invocation, or a census definition>`; threshold: <1-100>%")
    threshold = int(m.group("threshold"))
    probe = " ".join(m.group("probe").replace("\\|", "|").split())
    if not 1 <= threshold <= 100:
        return None, (f"declaration-malformed: threshold {threshold}% is outside 1-100% "
                      "(0% would admit the case the gate exists to fail)")
    lead = placeholder_probe(probe)
    if lead is not None:
        return None, (f"declaration-malformed: probe `{probe}` opens on the placeholder `{lead}` — "
                      "no declaration states its population unmeasurable; a population no "
                      "instrument reaches is enumerated by hand census (`<kind> census — …`)")
    return {"name": m.group("name").strip(),
            "members": " ".join(m.group("members").replace("\\|", "|").split()),
            "probe": probe, "threshold": threshold}, None


def _plain(line: str) -> str:
    """A record line with its list bullet, backticks and bold markers set aside."""
    return re.sub(r"^\s*(?:[-*+]\s+)?", "", line).replace("`", "").replace("**", "").strip()


def parse_record(plan_text: str, name: str) -> tuple[dict | None, str | None]:
    """The `Population record — <name>` block, found at any heading depth anywhere in the
    plan: one fenced block holding exactly the seven record labels in order, then
    `conforming: <k>` and `owner: #<N>` or `owner: none` before the next heading."""
    lines = plan_text.splitlines()
    heading = re.compile(r"^#{1,6}\s+Population record\s+—\s+" + re.escape(name) + r"\s*$")
    hits = [i for i, l in enumerate(lines) if heading.match(l)]
    if not hits:
        return None, f"record-missing: the release plan carries no `#### Population record — {name}` block"
    if len(hits) > 1:
        return None, f"record-malformed: {len(hits)} records carry the name {name}"
    start = hits[0] + 1
    end = next((k for k in range(start, len(lines)) if re.match(r"^#{1,6}\s", lines[k])), len(lines))
    block = lines[start:end]
    fo = next((k for k, l in enumerate(block) if l.strip().startswith("```")), None)
    fc = next((k for k in range((fo or 0) + 1, len(block)) if block[k].strip().startswith("```")), None) \
        if fo is not None else None
    if fo is None or fc is None:
        return None, "record-malformed: no closed fenced block under the heading"
    body = [l for l in block[fo + 1:fc] if l.strip()]
    got = tuple((re.match(r"^\s*([a-z]+):", l) or re.match(r"()", "")).group(1) for l in body)
    if got != RECORD_LABELS:
        return None, ("record-malformed: the fenced block must carry exactly "
                      f"{', '.join(RECORD_LABELS)}, one line each in that order; it carries "
                      f"{', '.join(g or '?' for g in got) or 'nothing'}")
    rec = {lab: line.split(":", 1)[1].strip() for lab, line in zip(RECORD_LABELS, body)}
    tail = [_plain(l) for l in block[fc + 1:]]
    conf = next((l.split(":", 1)[1].strip() for l in tail if l.startswith("conforming:")), None)
    own = next((l.split(":", 1)[1].strip() for l in tail if l.startswith("owner:")), None)
    if conf is None or not re.fullmatch(r"\d+", conf):
        return None, "record-malformed: no `conforming: <integer>` line after the fenced block"
    if own is None or not re.fullmatch(r"#\d+|none", own, re.I):
        return None, "record-malformed: no `owner: #<N>` or `owner: none` line after the fenced block"
    rec["conforming"] = int(conf)
    rec["owner"] = int(own[1:]) if own.startswith("#") else None
    return rec, None


def resolve_record(root: Path, record: str | None, slug: str | None) -> tuple[str | None, str | None]:
    """The release plan the records live in, read from the working tree: the record is
    written after <head>, and the version stamp renames the plan before Stage 13 runs, so
    an explicit --record wins and otherwise the plan is the ONE plan whose `milestone:`
    frontmatter names the release. -> (text, None) or (None, `record-unresolved: …`)."""
    if record:
        p = Path(record) if Path(record).is_absolute() else root / record
        if not p.is_file():
            return None, f"record-unresolved: {record} is not a file in the working tree"
        return p.read_text(encoding="utf-8"), None
    if not slug:
        return None, "record-unresolved: neither --record nor --milestone-slug names the release plan"
    hits = []
    for p in sorted((root / "release/releases/plans").glob("**/*_RELEASE_PLAN.md")):
        keys, status = _fm.read_frontmatter(p)
        if status == "ok" and keys.get("milestone", "").strip() == slug:
            hits.append(p)
    if len(hits) != 1:
        names = ", ".join(str(h.relative_to(root)) for h in hits) or "none"
        return None, (f"record-unresolved: {len(hits)} release plan(s) declare `milestone: {slug}` "
                      f"({names}); pass --plan <path>")
    return hits[0].read_text(encoding="utf-8"), None


def limb_subjects(outcome: str, created: str | None, required_from: str | None) -> list[dict]:
    lines = outcome.replace("\r\n", "\n").split("\n")
    start = next((i for i, l in enumerate(lines) if ROS_HEADING.match(l)), None)
    if start is None:
        return [{"arm": "ii", "subject": "limbs:outcome", "preset": (
            "FAIL", "no-outcome-statement: the milestone description carries no `### Release Outcome Statement` heading")}]
    end = next((k for k in range(start + 1, len(lines)) if re.match(r"^#{1,3}\s", lines[k])), len(lines))
    line = next((m.group(1) for l in lines[start + 1:end] for m in [LIMB_LINE.match(l)] if m), None)
    if line is None:
        lock = LOCK_DATE.search(outcome)
        key, src = (lock.group(1), "composition-lock") if lock else ((created or "")[:10], "milestone-creation")
        if not (re.fullmatch(r"\d{4}-\d{2}-\d{2}", key) and required_from):
            return [{"arm": "ii", "subject": "limbs:outcome", "preset": (
                "NOT-EVALUATED", "cutover-unknown: no **Limb owners:** line, and the date it would be required from cannot be read")}]
        if key >= required_from:
            return [{"arm": "ii", "subject": "limbs:outcome", "preset": (
                "FAIL", f"limb-owners-missing: no **Limb owners:** line; the {src} date {key} is on or after {required_from}")}]
        return [{"arm": "ii", "subject": "limbs:outcome", "preset": (
            "OUT-OF-SCOPE", f"grandfathered: no **Limb owners:** line; the {src} date {key} precedes {required_from}")}]
    out = []
    for i, entry in enumerate((e.strip().rstrip(".").strip() for e in re.split(r"\s+·\s+", line)), 1):
        if not entry:
            continue
        label, arrow, rhs = entry.partition("→")
        if not arrow:
            label, arrow, rhs = entry.partition("->")
        owners = [int(n) for n in re.findall(r"#(\d+)", rhs)] if arrow else []
        out.append({"arm": "ii", "subject": f"limbs:outcome-limb:{i}", "label": (label if arrow else entry).strip(),
                    "owners": owners})
    return out


def gcl10_subjects(head_reg: list[str], base_reg: list[str], wt_reg: list[str] | None,
                   plan: tuple[str | None, str | None], outcome: str,
                   created: str | None, required_from: str | None) -> list[dict]:
    """The ONE enumeration both --list and the grade read, so the population the wrapper
    counts and the subjects the grade reports come from the same code."""
    base_norms = {norm_row(r) for r in base_reg}
    wt_by_norm = {norm_row(r): r for r in (wt_reg or [])}
    keyed = wt_reg if wt_reg is not None else head_reg
    names: dict[str, int] = {}
    for r in keyed:
        m = POPULATION_NAME.search(r)
        if m:
            names[m.group(1).strip()] = names.get(m.group(1).strip(), 0) + 1
    plan_text, plan_err = plan
    subjects = []
    for row in head_reg:
        if surface_word(row) != "prose" or norm_row(row) in base_norms:
            continue
        drow = wt_by_norm.get(norm_row(row), row)          # the close worktree may repair a declaration
        decl, err = parse_population(drow)
        nm = POPULATION_NAME.search(drow)
        cells = row_cells(row)
        subject = f"obligation:{nm.group(1).strip()}" if nm else f"row:{excerpt(cells[0] if cells else row, 60)}"
        s = {"arm": "i", "subject": subject, "decl": decl, "err": err}
        if decl and names.get(decl["name"], 0) > 1:
            s["err"] = f"declaration-duplicate: the name {decl['name']} keys {names[decl['name']]} register rows"
        if decl and not s["err"]:
            if plan_err:
                s["plan_err"] = plan_err
            else:
                s["rec"], s["rec_err"] = parse_record(plan_text or "", decl["name"])
        subjects.append(s)
    return subjects + limb_subjects(outcome, created, required_from)


def owner_numbers(subjects: list[dict]) -> list[int]:
    nums = set()
    for s in subjects:
        if s["arm"] == "i" and s.get("rec") and s["rec"]["owner"] is not None:
            nums.add(s["rec"]["owner"])
        nums.update(s.get("owners", []))
    return sorted(nums)


def load_owners(owners_dir: Path, numbers: list[int]) -> dict[int, dict]:
    """Each owner as the wrapper read it: `<N>.error` (NOT-FOUND or UNREADABLE), else the
    issue JSON `<N>.json` and its comment bodies `<N>.comments`. A file missing for an
    owner reads UNREADABLE: an owner nobody read is not an owner that passed."""
    out = {}
    for n in numbers:
        err = owners_dir / f"{n}.error"
        if err.is_file():
            tok = err.read_text(encoding="utf-8").strip().upper()
            out[n] = {"err": "NOT-FOUND" if tok == "NOT-FOUND" else "UNREADABLE"}
            continue
        try:
            js = json.loads((owners_dir / f"{n}.json").read_text(encoding="utf-8"))
            comments = (owners_dir / f"{n}.comments").read_text(encoding="utf-8")
        except (OSError, ValueError):
            out[n] = {"err": "UNREADABLE"}
            continue
        out[n] = {"state": str(js.get("state") or "").lower(), "reason": str(js.get("state_reason") or ""),
                  "pr": "pull_request" in js, "repo_url": str(js.get("repository_url") or ""),
                  "text": (js.get("body") or "") + "\n" + comments}
    return out


def _same_repo(o: dict, repo: str) -> bool:
    return o["repo_url"].lower().rstrip("/").endswith("/repos/" + repo.lower())


def names_population(text: str, name: str) -> bool:
    return re.search(r"(?<![A-Za-z0-9_-])" + re.escape(name) + r"(?![A-Za-z0-9_-])", text) is not None


def grade_record(root: Path, head: str, decl: dict, rec: dict) -> tuple[str, str]:
    """-> (PASS | FAIL | NOT-EVALUATED, detail), or ("OWNER", why) when the obligation is
    short of its threshold or unmeasured and so needs an owning work item."""
    if " ".join(rec["population"].replace("\\|", "|").split()) != decl["members"]:
        return "FAIL", "record-unbound: the record's population: line differs from the declared member definition"
    probe, sep, pin = rec["probe"].rpartition(" @ ")
    if not sep or not pin.strip():
        return "FAIL", "record-malformed: the record's probe: carries no ` @ <commit>` pin"
    if " ".join(probe.replace("\\|", "|").split()) != decl["probe"]:
        return "FAIL", "record-unbound: the record's probe differs from the declared probe"
    pin = pin.strip()
    if not is_commit(root, pin):
        return "NOT-EVALUATED", f"pin-unfetched: {pin} is not a commit in the local object store; fetch it, then re-run"
    if git(root, "merge-base", "--is-ancestor", head, pin).returncode != 0:
        return "FAIL", f"pin-outside-release: {short(pin)} does not contain the release head {short(head)}"
    m = re.match(r"(\d+)\b", rec["examined"])
    if not m:
        return "FAIL", "record-malformed: examined: does not open on an integer"
    n, k, t = int(m.group(1)), rec["conforming"], decl["threshold"]
    if k > n:
        return "FAIL", f"record-malformed: conforming {k} exceeds examined {n}"
    sens = re.search(r"observed\s+(\d+)", rec["sensitivity"])
    state = leading_token(rec["state"])
    if state != "FETCHED" or n == 0 or not sens or int(sens.group(1)) < 1:
        why = (f"state {rec['state'].split()[0] if rec['state'] else 'absent'}" if state != "FETCHED"
               else "examined 0" if n == 0 else "the sensitivity arm records no observed count of at least 1")
        return "OWNER", f"unmeasured ({why})"
    pct = (100 * k) // n
    if k >= 1 and k * 100 >= t * n:
        return "PASS", f"threshold-met {k}/{n} ({pct}%) >= {t}%"
    return "OWNER", f"short {k}/{n} ({pct}%) < {t}%"


def _grade_obligation(root: Path, head: str, s: dict, members: set[int], owners: dict[int, dict],
                      repo: str) -> tuple[str, str, str]:
    subj = s["subject"]
    if s.get("err"):
        return "FAIL", subj, s["err"]
    if s.get("plan_err"):
        return "NOT-EVALUATED", subj, s["plan_err"]
    if s.get("rec_err"):
        return "FAIL", subj, s["rec_err"]
    verdict, detail = grade_record(root, head, s["decl"], s["rec"])
    if verdict != "OWNER":
        return verdict, subj, detail
    n, name = s["rec"]["owner"], s["decl"]["name"]
    if n is None:
        return "FAIL", subj, f"unowned: none — {detail}, and the record names no owning work item"
    o = owners.get(n, {"err": "UNREADABLE"})
    if o.get("err") == "UNREADABLE":
        return "NOT-EVALUATED", subj, f"owner-unreadable: #{n} could not be read — {detail}"
    why = ("not-found" if o.get("err") == "NOT-FOUND" else "pull-request" if o["pr"]
           else "other-repository" if not _same_repo(o, repo) else "closed" if o["state"] != "open"
           else "member-of-release" if n in members
           else "population-not-named" if not names_population(o["text"], name) else None)
    if why:
        return "FAIL", subj, f"unowned: #{n} {why} — {detail}"
    return "PASS", subj, f"owned-residual #{n} — {detail}"


def _grade_limb(s: dict, members: set[int], owners: dict[int, dict], repo: str) -> tuple[str, str, str]:
    subj = s["subject"]
    if "preset" in s:
        return s["preset"][0], subj, s["preset"][1]
    if not s["owners"]:
        return "FAIL", subj, f"limb-unowned: {s['label']} names no owning work item"
    bad, unread, abandoned, tags = [], [], [], []
    for n in s["owners"]:
        o = owners.get(n, {"err": "UNREADABLE"})
        if o.get("err") == "UNREADABLE":
            unread.append(f"#{n}")
        elif o.get("err") == "NOT-FOUND" or o["pr"] or not _same_repo(o, repo):
            bad.append(f"#{n} " + ("not-found" if o.get("err") else "pull-request" if o["pr"] else "other-repository"))
        elif o["state"] != "open" and o["reason"] in ABANDONED_REASONS:
            abandoned.append(f"#{n} closed {o['reason']}")
        else:
            tags.append(f"carried-by-nonmember #{n}" if o["state"] == "open" and n not in members else f"#{n}")
    if bad:
        return "FAIL", subj, f"limb-owner-invalid: {s['label']} — {', '.join(bad)}"
    if unread:
        return "NOT-EVALUATED", subj, f"owner-unreadable: {s['label']} — {', '.join(unread)}"
    if not tags:
        return "FAIL", subj, f"limb-owner-abandoned: {s['label']} — every owner closed unworked ({', '.join(abandoned)})"
    return "PASS", subj, f"{s['label']} — owned by {', '.join(tags + abandoned)}"


def eval_gcl10_obligations(root: Path, head: str, subjects: list[dict], members: set[int],
                           owners: dict[int, dict], repo: str) -> list[tuple[str, str, str]]:
    """G-CL10 arm (i): one verdict per declared obligation the release added or modified."""
    return [_grade_obligation(root, head, s, members, owners, repo) for s in subjects if s["arm"] == "i"]


def eval_gcl10_outcome_limbs(subjects: list[dict], members: set[int], owners: dict[int, dict],
                             repo: str) -> list[tuple[str, str, str]]:
    """G-CL10 arm (ii): one verdict per Outcome limb, or one for the Outcome as a whole."""
    return [_grade_limb(s, members, owners, repo) for s in subjects if s["arm"] == "ii"]


def print_gcl10_list(subjects: list[dict]) -> None:
    for s in subjects:
        if s["arm"] == "i":
            d = s.get("decl")
            if d and not s.get("err"):
                print(f"SUBJECT\t{s['subject']}\t{d['threshold']}%\t{d['probe']}")
            else:
                print(f"SUBJECT\t{s['subject']}\t{s['err'].split(':')[0]}")
        elif "preset" in s:
            print(f"LIMB\t{s['subject']}\t{s['preset'][1].split(':')[0]}")
        else:
            print(f"LIMB\t{s['subject']}\t{s['label']}\t{' '.join(f'#{n}' for n in s['owners']) or 'none'}")
    for n in owner_numbers(subjects):
        print(f"OWNER\t{n}")


def run_gcl10(root: Path, a) -> int:
    head_reg = register_rows(show(root, a.head, REGISTER_PATH))
    if head_reg is None:
        print(f"INPUT-ERROR\tg-cl10\t{REGISTER_PATH}\tno gate-coverage register at {short(a.head)}")
        return 3
    if not (a.outcome and Path(a.outcome).is_file()):
        print(f"INPUT-ERROR\tg-cl10\t{a.outcome}\tthe milestone description file (--outcome) was not found")
        return 3
    base_reg = register_rows(show(root, a.base, REGISTER_PATH)) or []
    wt = Path(a.register_worktree) if Path(a.register_worktree).is_absolute() else root / a.register_worktree
    wt_reg = register_rows(wt.read_text(encoding="utf-8")) if wt.is_file() else None
    subjects = gcl10_subjects(head_reg, base_reg, wt_reg, resolve_record(root, a.record, a.milestone_slug),
                              Path(a.outcome).read_text(encoding="utf-8"), a.milestone_created,
                              a.limbs_required_from)
    if a.list:
        print_gcl10_list(subjects)
        return 0
    if not (a.members and Path(a.members).is_file() and a.owners_dir and Path(a.owners_dir).is_dir()
            and a.repo and "/" in a.repo):
        print("INPUT-ERROR\tg-cl10\t-\tgrading needs --members <file>, --owners-dir <dir> and --repo <owner/repo>")
        return 3
    members = {int(t) for t in Path(a.members).read_text(encoding="utf-8").split() if t.isdigit()}
    owners = load_owners(Path(a.owners_dir), owner_numbers(subjects))
    emit("g-cl10", eval_gcl10_obligations(root, a.head, subjects, members, owners, a.repo)
         + eval_gcl10_outcome_limbs(subjects, members, owners, a.repo))
    return 0


def emit(gate: str, results: list[tuple[str, str, str]]) -> None:
    counts = {"PASS": 0, "FAIL": 0, "NOT-EVALUATED": 0, "OUT-OF-SCOPE": 0}
    for res, subject, detail in results:
        counts[res] += 1
        print(f"{res}\t{gate}\t{subject}\t{' '.join(detail.split())}")
    evaluated = counts["PASS"] + counts["FAIL"]
    print(f"SUMMARY\t{gate}\tevaluated={evaluated}\tfail={counts['FAIL']}"
          f"\tnot_evaluated={counts['NOT-EVALUATED']}\tout_of_scope={counts['OUT-OF-SCOPE']}")


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--gate", choices=("g-cl6", "g-cl8", "g-cl10"))
    ap.add_argument("--base")
    ap.add_argument("--head")
    ap.add_argument("--plan", help="g-cl6: release plan path, read at <head>")
    ap.add_argument("--issues-dir", help="g-cl8: directory of <N>.md issue bodies")
    ap.add_argument("--record", help="g-cl10: the release plan carrying the population records, read from the working tree")
    ap.add_argument("--milestone-slug", help="g-cl10: find the release plan by its `milestone:` frontmatter when --record is not given")
    ap.add_argument("--register-worktree", default=REGISTER_PATH,
                    help="g-cl10: the register as the close worktree holds it (a declaration repaired after <head>)")
    ap.add_argument("--outcome", help="g-cl10: a file holding the milestone description")
    ap.add_argument("--milestone-created", help="g-cl10: the milestone's created_at")
    ap.add_argument("--limbs-required-from", help="g-cl10: the date the **Limb owners:** line is required from")
    ap.add_argument("--members", help="g-cl10: the issue numbers of the release, whitespace-separated")
    ap.add_argument("--owners-dir", help="g-cl10: <N>.json + <N>.comments, or <N>.error, per owner")
    ap.add_argument("--repo", help="g-cl10: owner/repo an owning work item must belong to")
    ap.add_argument("--list", action="store_true", help="g-cl10: print the declared population, the limbs and the owners; grade nothing")
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args(argv)
    if a.self_test:
        return self_test()
    if not (a.gate and a.base and a.head):
        ap.error("--gate, --base and --head are required")
    root = Path(git(Path(a.repo_root), "rev-parse", "--show-toplevel").stdout.strip() or a.repo_root)
    for rev in (a.base, a.head):
        if not is_commit(root, rev):
            print(f"INPUT-ERROR\t{a.gate}\t{rev}\tnot a commit in {root}")
            return 3
    if a.gate == "g-cl10":
        return run_gcl10(root, a)
    if a.gate == "g-cl6":
        plan = show(root, a.head, a.plan) if a.plan else None
        if plan is None:
            print(f"INPUT-ERROR\tg-cl6\t{a.plan}\trelease plan not found at {short(a.head)}")
            return 3
        emit("g-cl6", eval_gcl6(root, a.base, a.head, plan))
    else:
        if not (a.issues_dir and Path(a.issues_dir).is_dir()):
            print(f"INPUT-ERROR\tg-cl8\t{a.issues_dir}\tissues directory not found")
            return 3
        emit("g-cl8", eval_gcl8(root, a.base, a.head, Path(a.issues_dir)))
    return 0


# ─── self-test (offline; a scratch git repository) ───────────────────────────
def self_test() -> int:
    failures: list[str] = []

    def check(name: str, cond: bool, got) -> None:
        if not cond:
            failures.append(f"{name}: got {got!r}")

    with tempfile.TemporaryDirectory() as td:
        r = Path(td)

        def run(*a):
            subprocess.run(["git", "-C", str(r), *a], check=True, capture_output=True)

        def put(path, text):
            p = r / path
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text, encoding="utf-8")

        def put_bytes(path, data):
            p = r / path
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(data)

        def commit(msg):
            run("add", "-A")
            run("-c", "user.name=t", "-c", "user.email=t@example.invalid", "commit", "-qm", msg)
            return git(r, "rev-parse", "HEAD").stdout.strip()

        run("init", "-q")
        fm = "---\ntitle: T\nstatus: ACTIVE\n---\n"
        put("core/diagrams/a.md", fm + "line\n" * 5)
        put("core/diagrams/fm.md", fm + "body\n" * 5)
        put("core/standards/s.md", fm + "standard\n")
        put("core/standards/retire-me.md", fm + "to retire\n")
        put("core/standards/cites-retire-me.md", fm + "see core/standards/retire-me.md\n")
        put("docs/old-guide.md", "# Old guide\n")
        put("docs/new-guide.md", "# New\n")
        put(".github/PULL_REQUEST_TEMPLATE.md", "### Documentation Impact\n")
        put("core/process-catalog/p.md", fm + "page\n")
        put("core/standards/old.md", fm + "old\n")
        put_bytes("packages/p.skill", b"PK\x03\x04\xa6\xff\x00bin")    # not UTF-8 text
        put_bytes("packages/same.skill", b"PK\x03\x04\xa6\xff\x00same")
        put_bytes("core/assets/retired.skill", b"PK\x03\x04\xa6\xff\x00retired")   # deleted at head
        put_bytes("core/figures/flow.png", b"\x89PNG\n\xa6a\n\xa6b\n\xa6c\n\xa6d\n")  # a binary Tier-A artifact
        put_bytes("core/figures/one-line.bin", b"\xa6a\x85\xa6b\x85\xa6c\x85\xa6d")   # one line; 0x85 is no newline byte
        put("core/order/a-fm.md", fm + "body\n")                       # listed before b.md
        put("core/order/b.md", fm + "body\n")
        base = commit("base")
        put_bytes("packages/p.skill", b"PK\x03\x04\xa7\xfe\x00bin")    # only undecodable bytes change
        os.chmod(r / "packages/same.skill", 0o755)                     # listed, bytes unchanged
        put_bytes("core/figures/flow.png", b"\x89PNG\n\xa7a\n\xa7b\n\xa7c\n\xa7d\n")  # four lines, undecodable bytes only
        put_bytes("core/figures/one-line.bin", b"\xa7a\x85\xa7b\x85\xa7c\x85\xa7d")   # its one line changed
        put("core/order/a-fm.md", fm.replace("title: T", "title: T2") + "body\n")
        put("core/order/b.md", fm + "body\nmore body\n")
        put("core/diagrams/fm.md", fm.replace("title: T", "title: T2\nowner: x\nreviewed: y\nnote: z") + "body\n" * 5)
        put("core/standards/retire-me.md", fm.replace("ACTIVE", "DEPRECATED") + "to retire\n")
        (r / "docs/old-guide.md").unlink()
        (r / "core/assets/retired.skill").unlink()
        put("README.md", "unrelated\n")
        put("core/standards/new-blank.md", fm + "\n\n")        # created with frontmatter and a blank body
        put("core/standards/new-full.md", fm + "a body\n")     # created with a body
        head = commit("head")

        plan = ("# Plan\n\n## Tier-A activated design artifacts\n\n"
                "| Card | Artifact path | Flow class | Tier |\n|---|---|---|---|\n"
                "| x | `core/diagrams/a.md` | architecture | A |\n"
                "| x | `core/diagrams/fm.md` § Flow | architecture | B |\n"
                "| x | **NOT ACTIVATED.** `core/diagrams/gone.md` § 2 carries an artifact | — | — |\n")
        res = {s: (v, d) for v, s, d in eval_gcl6(r, base, head, plan)}
        check("G6-1 unrefreshed artifact FAILs", res.get("core/diagrams/a.md", ("",))[0] == "FAIL", res.get("core/diagrams/a.md"))
        check("G6-2 frontmatter-only change FAILs", res.get("core/diagrams/fm.md", ("",))[0] == "FAIL", res.get("core/diagrams/fm.md"))
        check("G6-3 no Tier-A section -> nothing evaluated", eval_gcl6(r, base, head, "# Plan\n") == [], "non-empty")
        check("G6-5 a NOT ACTIVATED row is out of scope, never graded",
              res.get("core/diagrams/gone.md", ("",))[0] == "OUT-OF-SCOPE", res.get("core/diagrams/gone.md"))
        put("core/diagrams/a.md", fm + "line\n" * 5 + "new\n" * 4)
        head2 = commit("refresh a")
        res2 = {s: v for v, s, _ in eval_gcl6(r, base, head2, plan)}
        check("G6-4 refreshed artifact PASSes (specificity)", res2.get("core/diagrams/a.md") == "PASS", res2)
        # A Tier-A artifact that is not UTF-8 text is read as bytes, never as text: its whole
        # content is its body, in lines split at its newline bytes. Refreshed on four lines
        # (only undecodable bytes change, so a lossy decode reads no delta) it PASSes. The
        # control changed its one line, a delta of 2, and FAILs: that line carries 0x85,
        # which a text split would read as three more line breaks and a delta of 8.
        plan_bin = ("## Tier-A activated design artifacts\n\n"
                    "| Card | Artifact path | Flow class | Tier |\n|---|---|---|---|\n"
                    "| x | `core/figures/flow.png` | architecture | A |\n"
                    "| x | `core/figures/one-line.bin` | architecture | A |\n")
        res_bin = {s: (v, d) for v, s, d in eval_gcl6(r, base, head, plan_bin)}
        check("G6-6 a binary artifact refreshed by more than 3 lines PASSes",
              res_bin.get("core/figures/flow.png", ("",))[0] == "PASS", res_bin.get("core/figures/flow.png"))
        got = res_bin.get("core/figures/one-line.bin", ("", ""))
        check("G6-7 control: a binary artifact changed on its one line FAILs, a delta of 2",
              got[0] == "FAIL" and "body delta 2 " in got[1], got)

        cases = {
            "unresolved": ("### Documentation Impact\ncore/standards/s.md | update | x\n", "FAIL"),
            "resolved": ("### Documentation Impact\ncore/diagrams/a.md | update | x\n", "PASS"),
            "absent-section": ("### Description\nnothing\n", "OUT-OF-SCOPE"),
            "empty": ("### Documentation Impact\n\n_No response_\n\n### Notes\n", "FAIL"),
            "explicit-none": ("### Documentation Impact\nNone — no documentation impact (rationale: tooling only)\n", "PASS"),
            "bare-none": ("### Documentation Impact\nNone\n", "FAIL"),
            "bad-action": ("### Documentation Impact\ncore/diagrams/a.md | rewrite | x\n", "FAIL"),
            "prose-only": ("### Documentation Impact\nThe gate row in core/x.md must be rewritten.\n", "FAIL"),
            "path-without-action": ("### Documentation Impact\nrelease/README.md.\n", "FAIL"),
            # A line without "|" is commentary, even when it names a path in passing ...
            "rows-plus-commentary": ("### Documentation Impact\ncore/diagrams/a.md | update | x\n"
                                     "A note naming core/standards/s.md in passing.\n", "PASS"),
            # ... and a line WITH "|" is a declaration: it yields rows or it FAILs, never commentary.
            "rows-plus-row-shaped-line": ("### Documentation Impact\ncore/diagrams/a.md | update | x\n"
                                          "the standard | update | x\n", "FAIL"),
            "orphan-action-cell": ("### Documentation Impact\ncore/diagrams/a.md | update | x | update | y\n", "FAIL"),
            "qualified-action": ("### Documentation Impact\ncore/diagrams/a.md | update (conditional) | x\n", "FAIL"),
            "action-case-and-emphasis": ("### Documentation Impact\ncore/diagrams/a.md | **Update** | x\n", "PASS"),
            # A declared path outside the corpus scope is graded; only the two out-of-scope classes are recorded.
            "out-of-corpus-path-graded": ("### Documentation Impact\n.github/PULL_REQUEST_TEMPLATE.md | update | x\n", "FAIL"),
        }
        for name, (body, want) in cases.items():
            got = eval_issue(r, base, head2, body)
            check(f"G8-{name}", got[0] == want, got)
        got = eval_issue(r, base, head2, "### Documentation Impact\ncore/diagrams/a.md | update | x\n"
                                         "projects/demo/notes.md | update | x\n")
        check("G8-out-of-scope-class-recorded", got[0] == "PASS" and "out of the G-CL8 corpus scope" in got[1], got)
        # Every shape the field licenses is graded. Sensitivity: the unchanged s.md, declared
        # in that shape, FAILs and is named; specificity: the changed a.md in the same shape
        # PASSes, so the FAIL is the grade and not the shape being refused.
        shapes = {
            "plain": "{d} | update | x",
            "bulleted": "- {d} | update | x",
            "line-range": "{d}:3-4 | update | x",
            "anchor": "{d}#section | update | x",
            "section-sign": "{d} § Flow | update | x",
            "comma-list": "core/standards/new-full.md, {d} | update | x",
            "same-line-second-row": "core/standards/new-full.md | update | x. {d} | update | y",
            "table": "| Path | Action | Reason |\n|---|---|---|\n| {d} | update | x |",
        }
        for name, shape in shapes.items():
            got = eval_issue(r, base, head2, "### Documentation Impact\n" + shape.format(d="core/standards/s.md") + "\n")
            check(f"G8-shape-{name} unchanged doc FAILs", got[0] == "FAIL" and "core/standards/s.md" in got[1], got)
            got = eval_issue(r, base, head2, "### Documentation Impact\n" + shape.format(d="core/diagrams/a.md") + "\n")
            check(f"G8-shape-{name} changed doc PASSes", got[0] == "PASS", got)
        # A pipe-less line carrying the [ASSUMPTION – CONFIRM] marker is an unresolved
        # declaration: it FAILs, worded like the qualified-action FAIL, beside a row that
        # PASSes. Positive control: the same words without the marker are commentary and
        # the section PASSes, so the FAIL is the marker's and not the line's.
        note = "core/standards/s.md may also need an update; owner: Stage 5"
        got = eval_issue(r, base, head2, "### Documentation Impact\ncore/diagrams/a.md | update | x\n"
                                         "- [ASSUMPTION – CONFIRM] " + note + "\n")
        check("G8-assumption-line FAILs as an unresolved declaration",
              got[0] == "FAIL" and "unresolved declaration" in got[1] and "Stage 5" in got[1], got)
        got = eval_issue(r, base, head2, "### Documentation Impact\ncore/diagrams/a.md | update | x\n- " + note + "\n")
        check("G8-assumption-line control: the same words without the marker PASS as commentary",
              got[0] == "PASS" and "1 commentary line(s) ignored" in got[1], got)
        # An HTML comment is stripped before the section's end is found, as a renderer
        # reads it. Each arm hides a row of the unchanged s.md beside a visible row of the
        # changed a.md, so the section PASSes on the one row — except the two abrupt
        # closes, `<!-->` and `<!--->`, which hide nothing: their arms show the visible row
        # after the close is still graded. The controls below show the hidden row FAILs
        # when visible, and that a heading outside a comment still ends the section.
        vis, hid = "core/diagrams/a.md | update | x", "core/standards/s.md | update | y"
        comments = {
            "multi-line": f"<!--\n{hid}\n-->\n{vis}",
            "single-line": f"{vis} <!-- {hid} -->",
            "heading-inside": f"<!--\n### Example\n{hid}\n-->\n{vis}",
            "bang-close": f"<!-- {hid} --!>\n{vis}",
            "crlf": f"<!--\r\n{hid}\r\n-->\r\n{vis}",
            "unterminated": f"{vis}\n<!-- {hid}",
            "abrupt-empty": f"<!-->\n{vis}",
            "abrupt-empty-dash": f"<!--->\n{vis}",
        }
        for name, text in comments.items():
            eol = "\r\n" if name == "crlf" else "\n"
            got = eval_issue(r, base, head2, "### Documentation Impact" + eol + text + eol)
            check(f"G8-comment-{name} hides its row", got[0] == "PASS" and "1 declared row(s)" in got[1], got)
        got = eval_issue(r, base, head2, f"### Documentation Impact\n{hid}\n{vis}\n")
        check("G8-comment control: the hidden row, visible, FAILs",
              got[0] == "FAIL" and "core/standards/s.md" in got[1], got)
        got = eval_issue(r, base, head2, f"### Documentation Impact\n### Example\n{vis}\n")
        check("G8-comment control: a heading outside a comment ends the section",
              got[0] == "FAIL" and "present but empty" in got[1], got)
        # `update` and `create` compare the body with the frontmatter excluded, as G-CL6
        # does; `link` stays a whole-file net diff. fm.md changed only its frontmatter
        # between base and head; a.md changed its body by head2.
        def row(path, action, rev):
            return eval_issue(r, base, rev, f"### Documentation Impact\n{path} | {action} | x\n")
        got = row("core/diagrams/fm.md", "update", head2)
        check("G8-update a frontmatter-only change FAILs",
              got[0] == "FAIL" and "core/diagrams/fm.md" in got[1] and "frontmatter excluded" in got[1], got)
        got = row("core/diagrams/a.md", "update", head2)
        check("G8-update control: a body change PASSes", got[0] == "PASS", got)
        got = row("core/standards/new-blank.md", "create", head2)
        check("G8-create a created document with a blank body FAILs",
              got[0] == "FAIL" and "new-blank.md" in got[1], got)
        got = row("core/standards/new-full.md", "create", head2)
        check("G8-create control: a created document with a body PASSes", got[0] == "PASS", got)
        got = row("core/diagrams/fm.md", "link", head2)
        check("G8-link stays whole-file: a frontmatter-only change PASSes", got[0] == "PASS", got)
        got = row("core/diagrams/", "update", head)
        check("G8-update a directory whose only change is frontmatter FAILs", got[0] == "FAIL", got)
        got = row("core/diagrams/", "update", head2)
        check("G8-update control: a directory with a file whose body changed PASSes", got[0] == "PASS", got)
        got = row("core/order/", "update", head2)
        check("G8-update a directory resolves on a later file: the first listed changed only "
              "its frontmatter, the second its body", got[0] == "PASS", got)
        # A file that is not UTF-8 text is compared byte for byte, not read as text: a
        # changed binary resolves, directly or under a declared directory, and one whose
        # bytes did not change (only its mode did) does not.
        got = row("packages/p.skill", "update", head2)
        check("G8-update a changed binary file PASSes", got[0] == "PASS", got)
        got = row("packages/", "update", head2)
        check("G8-update a directory holding a changed binary file PASSes", got[0] == "PASS", got)
        got = row("packages/same.skill", "update", head2)
        check("G8-update control: a binary file whose bytes did not change FAILs",
              got[0] == "FAIL" and "packages/same.skill" in got[1], got)
        # Retire arms need the scan tools; they run only when the tools are reachable.
        tools = Path(__file__).resolve().parents[3]
        if (tools / "release/tools/blast-radius.sh").is_file():
            for rel in ("release/tools/blast-radius.sh", "release/tools/lib/schema-v1-emit.sh",
                        "core/deploy/tools/check-doc-links.py"):
                put(rel, (tools / rel).read_text(encoding="utf-8"))
                os.chmod(r / rel, 0o755)
            put("core/deploy/allowlists/doc-link-target-paths.txt", "core/standards/\ndocs/\n")
            head3 = commit("tools")
            got = eval_issue(r, base, head3, "### Documentation Impact\ncore/standards/retire-me.md | retire | x\n")
            check("G8-retire-a live referrer FAILs", got[0] == "FAIL" and "cites-retire-me.md" in got[1], got)
            put("core/standards/cites-retire-me.md", fm + "no reference\n")
            head4 = commit("re-point")
            got = eval_issue(r, base, head4, "### Documentation Impact\ncore/standards/retire-me.md | retire | x\n")
            check("G8-retire-a re-pointed PASSes", got[0] == "PASS", got)
            got = eval_issue(r, base, head4, "### Documentation Impact\ndocs/old-guide.md | retire | x\n")
            check("G8-retire-b deleted, unreferenced PASSes", got[0] == "PASS", got)
            # A document that is not UTF-8 text is read as bytes, never as text: it carries
            # no status field, so a deleted binary takes arm (b) and resolves, and one still
            # present at head FAILs as any arm (b) document does.
            got = eval_issue(r, base, head4, "### Documentation Impact\ncore/assets/retired.skill | retire | x\n")
            check("G8-retire-b a deleted binary file PASSes", got[0] == "PASS", got)
            got = eval_issue(r, base, head4, "### Documentation Impact\npackages/p.skill | retire | x\n")
            check("G8-retire-b control: a binary file still present at head FAILs",
                  got[0] == "FAIL" and "still exists at head" in got[1], got)
            put("core/standards/successor.md", fm.replace("title: T", "title: T\nsupersedes: core/standards/retire-me.md") + "new\n")
            head4b = commit("successor names its predecessor on its supersession line")
            got = eval_issue(r, base, head4b, "### Documentation Impact\ncore/standards/retire-me.md | retire | x\n")
            check("G8-retire-a supersession line is exempt", got[0] == "PASS", got)
            got = eval_issue(r, base, head4, "### Documentation Impact\ndocs/new-guide.md | retire | x\n")
            check("G8-retire-b still present FAILs", got[0] == "FAIL", got)
            got = eval_issue(r, base, head4, "### Documentation Impact\ncore/standards/s.md | retire | x\n")
            check("G8-retire-a status not moved FAILs", got[0] == "FAIL", got)
            put("docs/new-guide.md", "# New\n\n[the old guide](old-guide.md)\n")
            head5 = commit("relative link to the deleted guide")
            got = eval_issue(r, base, head5, "### Documentation Impact\ndocs/old-guide.md | retire | x\n")
            check("G8-retire-b relative link to the deleted path FAILs", got[0] == "FAIL" and "docs/new-guide.md" in got[1], got)
            (r / "core/standards/retire-me.md").unlink()
            head6 = commit("status-carrying doc deleted")
            got = eval_issue(r, base, head6, "### Documentation Impact\ncore/standards/retire-me.md | retire | x\n")
            check("G8-retire-a deleted status-carrying doc FAILs", got[0] == "FAIL" and "status move" in got[1], got)
            # The successor clause binds a catalog page, whose superseded_by field carries it;
            # another document's successor has no field to read, so it is not graded (G-CL8 row).
            put("core/process-catalog/p.md", fm.replace("ACTIVE", "SUPERSEDED") + "page\n")
            put("core/standards/old.md", fm.replace("ACTIVE", "SUPERSEDED") + "old\n")
            head7 = commit("two SUPERSEDED documents, neither naming a successor")
            got = eval_issue(r, base, head7, "### Documentation Impact\ncore/process-catalog/p.md | retire | x\n")
            check("G8-retire-a SUPERSEDED catalog page with no superseded_by FAILs", got[0] == "FAIL" and "superseded_by" in got[1], got)
            got = eval_issue(r, base, head7, "### Documentation Impact\ncore/standards/old.md | retire | x\n")
            check("G8-retire-a SUPERSEDED non-catalog document PASSes on its status move", got[0] == "PASS", got)
            put("core/process-catalog/p.md", fm.replace("ACTIVE", "SUPERSEDED\nsuperseded_by: q") + "page\n")
            head8 = commit("the catalog page names its successor")
            got = eval_issue(r, base, head8, "### Documentation Impact\ncore/process-catalog/p.md | retire | x\n")
            check("G8-retire-a SUPERSEDED catalog page naming its successor PASSes", got[0] == "PASS", got)
            # The head blob is read as bytes too: a status-carrying document that is not
            # text at head has no status to read there, so its retire FAILs as unmoved.
            put_bytes("core/standards/old.md", b"PK\x03\x04\xa6\xff\x00old")
            head9 = commit("a status-carrying document replaced by a binary at the same path")
            got = eval_issue(r, base, head9, "### Documentation Impact\ncore/standards/old.md | retire | x\n")
            check("G8-retire-a a document that is binary at head FAILs: its status reads absent",
                  got[0] == "FAIL" and "status at head is absent" in got[1], got)
        else:
            failures.append("retire arms not run: blast-radius.sh is not reachable from this file")

        # GD-PARITY — grade_declaration() is eval_issue's grammar, split out so the bundle
        # gate G3-20 can read it with no release range. The oracle is the code's structure,
        # not a list of message phrases: with the resolution functions held at "resolved",
        # the two must render the same verdict for every fixture body above, OUT-OF-SCOPE
        # included. The retire bodies are in the corpus, so a grammar the split dropped
        # from a retire row is caught too.
        corpus = [b for b, _ in cases.values()]
        corpus += ["### Documentation Impact\n" + s.format(d=d) + "\n"
                   for s in shapes.values() for d in ("core/standards/s.md", "core/diagrams/a.md")]
        corpus += [("### Documentation Impact" + ("\r\n" if n == "crlf" else "\n") + t
                    + ("\r\n" if n == "crlf" else "\n")) for n, t in comments.items()]
        corpus += [f"### Documentation Impact\n{hid}\n{vis}\n", f"### Documentation Impact\n### Example\n{vis}\n",
                   "### Documentation Impact\ncore/diagrams/a.md | update | x\nprojects/demo/notes.md | update | x\n",
                   "### Documentation Impact\ncore/diagrams/a.md | update | x\n- [ASSUMPTION – CONFIRM] " + note + "\n",
                   "### Documentation Impact\ncore/diagrams/a.md | update | x\n- " + note + "\n"]
        corpus += [f"### Documentation Impact\n{p} | {a} | x\n" for p, a in (
            ("core/diagrams/fm.md", "update"), ("core/standards/new-blank.md", "create"),
            ("core/diagrams/fm.md", "link"), ("core/diagrams/", "update"), ("packages/same.skill", "update"),
            ("core/standards/retire-me.md", "retire"), ("docs/old-guide.md", "retire"),
            ("core/assets/retired.skill", "retire"), ("packages/p.skill", "retire"),
            ("docs/new-guide.md", "retire"), ("core/standards/s.md", "retire"),
            ("core/process-catalog/p.md", "retire"), ("core/standards/old.md", "retire"))]
        mixed = ("### Documentation Impact\ncore/standards/s.md | update | x\n"
                 "core/diagrams/a.md | rewrite | y\n")
        corpus.append(mixed)
        g = globals()
        held = {k: g[k] for k in ("exists_at", "changed_in_release", "body_changed_in_release", "verify_retire")}
        g["exists_at"] = lambda *_: True
        g["changed_in_release"] = lambda *_: True
        g["body_changed_in_release"] = lambda *_: True
        g["verify_retire"] = lambda *_: ("PASS", "held resolved")
        try:
            split = [(b, grade_declaration(b)[0], eval_issue(r, base, head2, b)[0]) for b in corpus]
        finally:
            g.update(held)
        apart = [(excerpt(b.replace("\n", " ⏎ ")), gv, ev) for b, gv, ev in split if gv != ev]
        check(f"GD-PARITY grade_declaration and eval_issue agree on all {len(corpus)} fixture bodies "
              "with resolution held constant", not apart, apart)
        check("GD-PARITY control: the corpus carries every verdict the grammar can render",
              {gv for _, gv, _ in split} == {"PASS", "FAIL", "OUT-OF-SCOPE"}, {gv for _, gv, _ in split})
        # The discriminating pair, un-stubbed: the same body, gradable but unresolved — the
        # grammar passes it and the close gate fails it, so resolution was not folded in.
        body = cases["unresolved"][0]
        got = (grade_declaration(body)[0], eval_issue(r, base, head2, body)[0])
        check("GD-PARITY unresolved: gradable at Bundle, unresolved at close", got == ("PASS", "FAIL"), got)
        # Declaration order is the detail order: a row's resolution finding stays ahead of
        # a later row's grammar finding, and the grammar alone reports only its own.
        got = eval_issue(r, base, head2, mixed)
        check("GD-PARITY mixed: findings read in declaration order",
              got[0] == "FAIL" and 0 <= got[1].find("core/standards/s.md | update: unchanged")
              < got[1].find("core/diagrams/a.md: unknown action"), got)
        got = grade_declaration(mixed)[:2]
        check("GD-PARITY mixed: the grammar reports the unknown action and no resolution finding",
              got[0] == "FAIL" and "unknown action" in got[1] and "unchanged" not in got[1], got)
        # The placeholder path is grammar, so the grammar alone fails it; the same row with
        # a real path is gradable (control).
        got = grade_declaration("### Documentation Impact\ncore/standards/<name>.md | update | x\n")[:2]
        check("GD-PARITY a placeholder path is a grammar FAIL", got[0] == "FAIL" and "placeholder path" in got[1], got)
        got = grade_declaration("### Documentation Impact\ncore/standards/name.md | update | x\n")[:2]
        check("GD-PARITY placeholder control: a real path is gradable", got == ("PASS", "1 declared row(s) gradable"), got)

    _self_test_gcl10(check)

    for f in failures:
        print(f"self-test FAIL: {f}", file=sys.stderr)
    print(f"check-doc-gates self-test: {'FAIL' if failures else 'PASS'} ({len(failures)} failure(s))", file=sys.stderr)
    return 1 if failures else 0


# The G-CL10 arms: one scratch repository whose register gains a row of each shape at
# <head>, graded through the same enumeration --list prints. CL10-S and CL10-P are the
# CIAC-4 pair — the identical fixture, differing in the record's owner line alone.
REG_TOP = ("# Fixture standard\n\n## Gate-coverage register (seed)\n\n"
           "| Invariant | Enforcing gate | Surface | Posture | Falsification test |\n|---|---|---|---|---|\n")
REG_BASE_ROWS = ("| R-old a prose obligation already on base | review step | prose (no job) | advisory | x |\n"
                 "| R-seg a prose row that gains only a segment | review step | prose | advisory | x |\n"
                 "| R-ci an old ci row | job | ci | required | x |\n")
REG_TAIL = "\n## After the register\n\n| H | H | H | H | H |\n|---|---|---|---|---|\n| a | b | prose | d | e |\n"


def _seg(name: str, probe: str, threshold: str = "100") -> str:
    return f"**Population:** `{name}` — population: members of {name}; probe: `{probe}`; threshold: {threshold}%"


def _rec(name: str, probe: str, head: str, examined: str = "3 — counted at the pin",
         sens: str = "a known member -> observed 1", state: str = "fetched",
         conforming: str = "0", owner: str = "none") -> str:
    return (f"#### Population record — {name}\n\n```\npopulation: members of {name}\n"
            f"probe: {probe} @ {head}\nexamined: {examined}\nsensitivity: {sens}\n"
            f"specificity: NOT TRIGGERED — a fixture\nstate: {state}\nexempted: 0\n```\n\n"
            f"conforming: {conforming}\nowner: {owner}\n")


def _self_test_gcl10(check) -> None:
    with tempfile.TemporaryDirectory() as td:
        r = Path(td)

        def run(*a):
            subprocess.run(["git", "-C", str(r), *a], check=True, capture_output=True)

        def put(path, text):
            p = r / path
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text, encoding="utf-8")

        def commit(msg):
            run("add", "-A")
            run("-c", "user.name=t", "-c", "user.email=t@example.invalid", "commit", "-qm", msg)
            return git(r, "rev-parse", "HEAD").stdout.strip()

        run("init", "-q")
        put(REGISTER_PATH, REG_TOP + REG_BASE_ROWS + REG_TAIL)
        base = commit("base")
        seg_e = _seg("pop-e", "ls e \\| wc -l")                  # a `|` in a probe is written `\|`
        head_rows = (
            "| R-old a prose obligation already on base | review step | prose (no job) | advisory | x |\n"
            f"| R-seg a prose row that gains only a segment | review step | prose | advisory | x {_seg('pop-n', 'n')} |\n"
            "| R-ci an old ci row | job | ci | required | x |\n"
            f"| R-S widgets carry a tag | review step | prose (nothing executes it) | advisory | flip it {_seg('pop-s', 'count-widgets --tagged')} |\n"
            f"| R-V a new ci row | job | ci | required | x {_seg('pop-v', 'v')} |\n"
            f"| R-K a bold surface | review step | **prose** (bold) | advisory | x {_seg('pop-k', 'k-probe', '50')} |\n"
            "| R-D a new prose row with no declaration | review step | prose | advisory | x |\n"
            f"| R-E an escaped pipe | review step | prose | advisory | x {seg_e} |\n"
            f"| R-0 a zero threshold | review step | prose | advisory | x {_seg('pop-0', 'z', '0')} |\n"
            f"| R-X a probe of none | review step | prose | advisory | x {_seg('pop-x', 'none')} |\n"
            "| R-W declared only in the worktree | review step | prose | advisory | x |\n"
            f"| R-C a census probe | review step | prose | advisory | x {_seg('pop-c', 'presence census — count the lines by hand')} |\n")
        put(REGISTER_PATH, REG_TOP + head_rows + REG_TAIL)
        head = commit("head")
        # CL10-DW: after <head> the close worktree repairs one row's declaration.
        wt_rows = head_rows.replace("| R-W declared only in the worktree | review step | prose | advisory | x |",
                                    f"| R-W declared only in the worktree | review step | prose | advisory | x {_seg('pop-w', 'w')} |")
        put(REGISTER_PATH, REG_TOP + wt_rows + REG_TAIL)

        common = ("# Plan\n\n## Verification Evidence\n\n"                     # CL10-H: an H2 section
                  + _rec("pop-k", "k-probe", head, examined="2", conforming="1")
                  + _rec("pop-e", "ls e | wc -l", head, examined="1", conforming="1")   # CL10-E: \| binds to |
                  + _rec("pop-w", "w", head, examined="1", conforming="1")
                  + _rec("pop-c", "presence census — count the lines by hand", head, examined="2", conforming="2"))
        plan_s = common + _rec("pop-s", "count-widgets --tagged", head)
        plan_p = common + _rec("pop-s", "count-widgets --tagged", head, owner="#7")
        outcome_ok = ("### Release Outcome Statement\n\n**AFTER** — x.\n\n**BEFORE** — y.\n\n"
                      "**Limb owners:** first limb → #20 · second limb → #21, #7.\n\n## Release Class\n")
        owners_dir = r / "_owners"
        owners_dir.mkdir()
        issue = "https://api.github.com/repos/acme/widget"
        fixtures = {
            7: {"state": "open", "body": "carries the residual of pop-s", "repository_url": issue},
            8: {"state": "open", "body": "names pop-s", "repository_url": issue},                 # a member
            9: {"state": "closed", "state_reason": "completed", "body": "pop-s", "repository_url": issue},
            10: {"state": "open", "body": "pop-s", "repository_url": issue, "pull_request": {}},
            12: {"state": "open", "body": "names nothing it owns; pop-sx is another population", "repository_url": issue},
            14: {"state": "open", "body": "pop-s", "repository_url": "https://api.github.com/repos/acme/other"},
            20: {"state": "open", "body": "", "repository_url": issue},
            21: {"state": "closed", "state_reason": "completed", "body": "", "repository_url": issue},
            22: {"state": "closed", "state_reason": "not_planned", "body": "", "repository_url": issue},
        }
        for n, js in fixtures.items():
            (owners_dir / f"{n}.json").write_text(json.dumps(js), encoding="utf-8")
            (owners_dir / f"{n}.comments").write_text("", encoding="utf-8")
        (owners_dir / "11.error").write_text("UNREADABLE\n", encoding="utf-8")
        (owners_dir / "13.error").write_text("NOT-FOUND\n", encoding="utf-8")
        (owners_dir / "15.comments").write_text("a comment naming pop-s\n", encoding="utf-8")
        (owners_dir / "15.json").write_text(json.dumps({"state": "open", "body": "", "repository_url": issue}), encoding="utf-8")
        members = {8, 20, 21}

        def grade(plan_text, outcome=outcome_ok, created="2026-01-01T00:00:00Z", required="2026-06-01",
                  plan_err=None, wt=True):
            wt_reg = register_rows((r / REGISTER_PATH).read_text(encoding="utf-8")) if wt else None
            subjects = gcl10_subjects(register_rows(show(r, head, REGISTER_PATH)),
                                      register_rows(show(r, base, REGISTER_PATH)), wt_reg,
                                      (None, plan_err) if plan_err else (plan_text, None), outcome, created, required)
            owners = load_owners(owners_dir, owner_numbers(subjects))
            res = (eval_gcl10_obligations(r, head, subjects, members, owners, "acme/widget")
                   + eval_gcl10_outcome_limbs(subjects, members, owners, "acme/widget"))
            return {subj: (v, d) for v, subj, d in res}, subjects

        res_s, subjects = grade(plan_s)
        res_p, _ = grade(plan_p)
        got = res_s.get("obligation:pop-s", ("", ""))
        check("CL10-S 0% conformance with no owner FAILs (AC-3)", got[0] == "FAIL" and "unowned: none" in got[1], got)
        got = res_p.get("obligation:pop-s", ("", ""))
        check("CL10-P 0% conformance owned by an open non-member that names the population PASSes (AC-4)",
              got[0] == "PASS" and "owned-residual #7" in got[1], got)
        changed = [d for d in difflib.unified_diff(plan_s.splitlines(), plan_p.splitlines(), lineterm="", n=0)
                   if d[:1] in "+-" and not d.startswith(("+++", "---"))]
        check("CL10-S/P the two fixtures differ in the owner line alone (CIAC-4)",
              changed == ["-owner: none", "+owner: #7"], changed)
        for tag, n, want in (("M", 8, "member-of-release"), ("C", 9, "closed"), ("PR", 10, "pull-request"),
                             ("NN", 12, "population-not-named"), ("NF", 13, "not-found"),
                             ("OR", 14, "other-repository")):
            got = grade(common + _rec("pop-s", "count-widgets --tagged", head, owner=f"#{n}"))[0]["obligation:pop-s"]
            check(f"CL10-{tag} an owner that is {want} FAILs", got[0] == "FAIL" and want in got[1], got)
        got = grade(common + _rec("pop-s", "count-widgets --tagged", head, owner="#11"))[0]["obligation:pop-s"]
        check("CL10-U an unreadable owner is NOT-EVALUATED, never a pass", got[0] == "NOT-EVALUATED", got)
        got = grade(common + _rec("pop-s", "count-widgets --tagged", head, owner="#15"))[0]["obligation:pop-s"]
        check("CL10-CM an owner whose comment stream names the population PASSes", got[0] == "PASS", got)
        got = grade(common + _rec("pop-s", "count-widgets --tagged", head, conforming="3"))[0]["obligation:pop-s"]
        check("CL10-T 3/3 at 100% PASSes with no owner", got[0] == "PASS" and "threshold-met 3/3" in got[1], got)
        got = grade(common + _rec("pop-s", "count-widgets --tagged", head, conforming="2"))[0]["obligation:pop-s"]
        check("CL10-T2 2/3 short of 100% with no owner FAILs", got[0] == "FAIL" and "short 2/3" in got[1], got)
        got = grade(common + _rec("pop-s", "count-widgets --tagged", head, sens="a known member -> observed 0",
                                  conforming="3"))[0]["obligation:pop-s"]
        check("CL10-Z a sensitivity arm observed at 0 reads unmeasured and needs an owner",
              got[0] == "FAIL" and "unmeasured" in got[1], got)
        got = grade(common + _rec("pop-s", "count-widgets --tagged", head, state="not-run — the hook layer refused the probe",
                                  conforming="0", owner="#7"))[0]["obligation:pop-s"]
        check("CL10-NR a probe refused (state not-run) is unmeasured, and an owner naming it carries it",
              got[0] == "PASS" and "unmeasured" in got[1], got)
        got = grade(common)[0]["obligation:pop-s"]
        check("CL10-R no record FAILs", got[0] == "FAIL" and "record-missing" in got[1], got)
        got = grade(common + _rec("pop-s", "count-widgets --all", head, conforming="3"))[0]["obligation:pop-s"]
        check("CL10-B a record bound to another probe FAILs", got[0] == "FAIL" and "record-unbound" in got[1], got)
        got = grade(common + _rec("pop-s", "count-widgets --tagged", base, conforming="3"))[0]["obligation:pop-s"]
        check("CL10-PO a pin that does not contain <head> FAILs", got[0] == "FAIL" and "pin-outside-release" in got[1], got)
        got = grade(common + _rec("pop-s", "count-widgets --tagged", "f" * 40, conforming="3"))[0]["obligation:pop-s"]
        check("CL10-PU an unfetched pin is NOT-EVALUATED", got[0] == "NOT-EVALUATED" and "pin-unfetched" in got[1], got)
        got = grade(plan_s.replace("examined: 3", "conforming: 1\nexamined: 3"))[0]["obligation:pop-s"]
        check("CL10-RM a record whose labels are out of order FAILs", got[0] == "FAIL" and "record-malformed" in got[1], got)
        got = res_s.get("row:R-D a new prose row with no declaration", ("", ""))
        check("CL10-D a new prose row with no declaration FAILs", got[0] == "FAIL" and "declaration-missing" in got[1], got)
        got = res_s.get("obligation:pop-w", ("", ""))
        check("CL10-DW a declaration repaired only in the worktree is graded", got[0] == "PASS", got)
        got = grade(plan_s, wt=False)[0].get("row:R-W declared only in the worktree", ("", ""))
        check("CL10-DW control: without the worktree repair the row reads declaration-missing",
              got[0] == "FAIL" and "declaration-missing" in got[1], got)
        got = res_s.get("obligation:pop-0", ("", ""))
        check("CL10-0 a 0% threshold FAILs as malformed", got[0] == "FAIL" and "declaration-malformed" in got[1], got)
        got = res_s.get("obligation:pop-x", ("", ""))
        check("CL10-X probe `none` is not admitted (CD-1)", got[0] == "FAIL" and "declaration-malformed" in got[1], got)
        # CL10-X variants: CD-1 holds for every spelling of "unmeasurable", not only the
        # literal `none` — a placeholder or bare probe is malformed, so it never reaches
        # the close as `not-run` and passes on an owner alone.
        for spelling in ("n/a", "N/A", "tbd", "TBD", "unmeasurable", "unmeasured", "—", "–", "-", "...",
                         "none — measured by hand", "none.", "no instrument", "not measurable",
                         "not applicable", "n.a.", "unknown", "— counted by hand"):
            decl, err = parse_population(f"| R x | review step | prose | advisory | x {_seg('pop-ph', spelling)} |")
            check(f"CL10-X a placeholder or bare probe `{spelling}` is malformed (CD-1)",
                  decl is None and (err or "").startswith("declaration-malformed"), (decl, err))
        # Specificity: an exact invocation or a census definition parses, including one whose
        # first word merely begins like a placeholder.
        for probe in ("presence census — count the lines by hand", "count-widgets --tagged", "ls e \\| wc -l",
                      "python3 release/tools/native-dep-mirror.py --self-test", "notes census — count the notes by hand",
                      "nothing-to-see.sh --count", "tbd-report --list", "nodes census — count the nodes by hand"):
            decl, err = parse_population(f"| R x | review step | prose | advisory | x {_seg('pop-ok', probe)} |")
            check(f"CL10-X control: the probe `{probe}` parses", err is None and decl is not None, (decl, err))
        # End to end, the shape the finding reproduced: an `n/a` probe whose record is
        # unmeasured and whose owner names the population FAILs, never PASSes on the owner.
        na_row = ("| R-NA a placeholder probe | review step | prose | advisory | x "
                  f"{_seg('pop-na', 'n/a')} |")
        na_subj = gcl10_subjects([na_row], [], None,
                                 (_rec("pop-na", "n/a", head, state="not-run", owner="#7"), None),
                                 outcome_ok, "2026-01-01T00:00:00Z", "2026-06-01")
        na_own = {7: {"state": "open", "reason": "", "pr": False, "repo_url": issue, "text": "carries pop-na"}}
        got = (eval_gcl10_obligations(r, head, na_subj, members, na_own, "acme/widget") or [("", "", "")])[0]
        check("CL10-X end to end: an owned `n/a` declaration FAILs as malformed",
              got[0] == "FAIL" and "declaration-malformed" in got[2], got)
        got = res_s.get("obligation:pop-c", ("", ""))
        check("CL10-CN a census-definition probe binds and grades", got[0] == "PASS", got)
        check("CL10-N a row whose only change is its segment is not in the population",
              "obligation:pop-n" not in res_s and "row:R-old a prose obligation already on base" not in res_s, sorted(res_s))
        check("CL10-V a non-prose row is not in the population", "obligation:pop-v" not in res_s, sorted(res_s))
        check("CL10-K a bold **prose** Surface enrols", res_s.get("obligation:pop-k", ("",))[0] == "PASS", res_s.get("obligation:pop-k"))
        check("CL10-E a \\| declaration binds to a | record", res_s.get("obligation:pop-e", ("",))[0] == "PASS", res_s.get("obligation:pop-e"))
        check("CL10-H a record under an H2 Verification Evidence section is found",
              "## Verification Evidence" in common and "### Verification Evidence" not in common
              and res_s.get("obligation:pop-c", ("",))[0] == "PASS", res_s.get("obligation:pop-c"))
        check("CL10-AFTER the table after the register is not read", not any(k.startswith("row:a") for k in res_s), sorted(res_s))
        got = grade(plan_s, plan_err="record-unresolved: 0 release plan(s) declare `milestone: m`")[0]["obligation:pop-s"]
        check("CL10-RU an unresolved plan is NOT-EVALUATED", got[0] == "NOT-EVALUATED" and "record-unresolved" in got[1], got)
        # The enumeration is shared: --list counts exactly the subjects the grade reports.
        check("CL10-L the list enumeration and the grade agree in count", len(subjects) == len(res_s), (len(subjects), len(res_s)))

        # Limbs (arm ii).
        got = res_s.get("limbs:outcome-limb:1", ("", ""))
        check("L-1 a limb owned by a member PASSes", got[0] == "PASS", got)
        got = res_s.get("limbs:outcome-limb:2", ("", ""))
        check("L-1b an open non-member owner is named carried-by-nonmember",
              got[0] == "PASS" and "carried-by-nonmember #7" in got[1], got)
        one = lambda o, **k: [v for s, v in grade(plan_s, outcome=o, **k)[0].items() if s.startswith("limbs:")]
        got = one(outcome_ok.replace("→ #20 ·", "→ nothing yet ·"))[0]
        check("L-2 a limb naming no #N FAILs", got[0] == "FAIL" and "limb-unowned" in got[1], got)
        bare = "### Release Outcome Statement\n\n**AFTER** — x.\n\n**BEFORE** — y.\n"
        got = one(bare, created="2026-07-01T00:00:00Z")
        check("L-3 no owner line on a milestone created after the cutover FAILs",
              got == [("FAIL", got[0][1])] and "limb-owners-missing" in got[0][1], got)
        got = one(bare, created="2026-01-01T00:00:00Z")
        check("L-4 no owner line before the cutover is OUT-OF-SCOPE", got and got[0][0] == "OUT-OF-SCOPE", got)
        got = one(outcome_ok, created="2026-01-01T00:00:00Z")
        check("L-5 a present line is graded before the cutover too", got and all(v == "PASS" for v, _ in got), got)
        got = one(outcome_ok.replace("#21, #7", "#22"))[1]
        check("L-6 a limb whose only owner closed not_planned FAILs (FM-2)",
              got[0] == "FAIL" and "limb-owner-abandoned" in got[1], got)
        got = one(outcome_ok.replace("#21, #7", "#22, #20"))[1]
        check("L-6 control: an abandoned owner beside a live one PASSes", got[0] == "PASS", got)
        got = one(outcome_ok.replace("#21, #7", "#10"))[1]
        check("L-7 a pull request as a limb owner FAILs", got[0] == "FAIL" and "limb-owner-invalid" in got[1], got)
        locked = bare + "\n## Composition\n\n### Composition Lock\n**Locked at:** Stage 4 Planning entry · 2026-07-01 · planning sub-task #1\n"
        got = one(locked, created="2026-01-01T00:00:00Z")
        check("L-8 the cutover reads the Composition Lock date before the creation date (FM-3)",
              got and got[0][0] == "FAIL" and "composition-lock date 2026-07-01" in got[0][1], got)
        got = one("## Goal\n\nno outcome\n")
        check("L-9 a description with no Outcome heading FAILs", got and got[0][0] == "FAIL" and "no-outcome-statement" in got[0][1], got)
        check("L-10 every arm-ii subject opens `limbs:` (the drain counts each arm)",
              all(s["subject"].startswith("limbs:") for s in subjects if s["arm"] == "ii")
              and all(not s["subject"].startswith("limbs:") for s in subjects if s["arm"] == "i"), [s["subject"] for s in subjects])

        # PR-1: the plan is found by its frontmatter, wherever the version stamp moved it.
        put("release/releases/plans/v9/v9.99_RELEASE_PLAN.md", "---\ntitle: P\nmilestone: dg-slug\n---\n" + plan_p)
        put("release/releases/plans/other_RELEASE_PLAN.md", "---\ntitle: Q\nmilestone: another\n---\n# Q\n")
        text, err = resolve_record(r, None, "dg-slug")
        check("CL10-PF the plan resolves through its milestone: frontmatter", err is None and "owner: #7" in (text or ""), err)
        text, err = resolve_record(r, None, "absent-slug")
        check("CL10-PF control: no plan declaring the slug is record-unresolved", text is None and "0 release plan" in (err or ""), err)
        put("release/releases/plans/dup_RELEASE_PLAN.md", "---\ntitle: R\nmilestone: dg-slug\n---\n# R\n")
        text, err = resolve_record(r, None, "dg-slug")
        check("CL10-PF two plans declaring the slug is record-unresolved, naming both",
              text is None and "2 release plan" in (err or "") and "dup_RELEASE_PLAN.md" in (err or ""), err)

        # The CLI: --list and the grade over the same inputs.
        (r / "_outcome.md").write_text(outcome_ok, encoding="utf-8")
        (r / "_members.txt").write_text("8 20 21\n", encoding="utf-8")
        (r / "_plan.md").write_text(plan_s, encoding="utf-8")
        cli = [sys.executable, str(Path(__file__).resolve()), "--gate", "g-cl10", "--base", base, "--head", head,
               "--repo-root", str(r), "--record", "_plan.md", "--outcome", str(r / "_outcome.md"),
               "--milestone-created", "2026-01-01T00:00:00Z", "--limbs-required-from", "2026-06-01"]
        out = subprocess.run(cli + ["--list"], capture_output=True, text=True)
        lines = out.stdout.splitlines()
        npop = sum(1 for l in lines if l.split("\t")[0] in ("SUBJECT", "LIMB"))
        check("CLI-1 --list prints the declared population, the limbs and the owners",
              out.returncode == 0 and "SUBJECT\tobligation:pop-s\t100%\tcount-widgets --tagged" in lines
              and "OWNER\t20" in lines and npop == len(subjects), out.stdout + out.stderr)
        out = subprocess.run(cli + ["--members", str(r / "_members.txt"), "--owners-dir", str(owners_dir),
                                    "--repo", "acme/widget"], capture_output=True, text=True)
        graded = [l for l in out.stdout.splitlines() if not l.startswith("SUMMARY")]
        check("CLI-2 the grade reports one line per listed subject and FAILs CL10-S",
              out.returncode == 0 and len(graded) == npop and "FAIL\tg-cl10\tobligation:pop-s\t" in out.stdout,
              out.stdout + out.stderr)
        out = subprocess.run(cli, capture_output=True, text=True)
        check("CLI-3 grading without --members/--owners-dir/--repo is an input error (exit 3)",
              out.returncode == 3 and out.stdout.startswith("INPUT-ERROR"), out.stdout)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

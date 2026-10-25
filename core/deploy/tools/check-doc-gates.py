#!/usr/bin/env python3
"""check-doc-gates.py — the predicate engine behind Check 28's release-context arms.

WHAT IT IS
    The engine `core/deploy/deploy.sh --check-doc-gates` runs at Stage 13 Close to
    evaluate the two documentation close gates of `core/schemas/gate-criteria-spec.md`
    Gate 13 over ONE release's commit range:

      g-cl6  Design artifacts refreshed: every artifact the release plan's
             "Tier-A activated design artifacts" section declares was touched in
             <base>..<head>, with a body delta above 3 lines (frontmatter excluded).
      g-cl8  Documentation Impact resolved: every issue of the release whose body carries a
             `### Documentation Impact` section has each declared row resolved by the
             action-keyed method of the G-CL8 row (link / create / update / retire),
             or reads exactly `None — no documentation impact (rationale: <phrase>)`.

    The criteria are NOT restated here; the G-CL6 and G-CL8 rows are their authority
    and this file implements them. Where this file and those rows disagree, the rows win
    and this file is the defect.

WHAT IT IS NOT
    It writes nothing. It never touches the warn log, the network or GitHub: deploy.sh
    resolves the release context (the PR, <base>, <head>, the issue bodies) and hands
    this engine files and commit ids, then turns FAIL lines into warn-log rows through
    the shared sink's one append path. Keeping the engine offline is what lets
    `--self-test` exercise every arm in CI with no credentials.

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


def changed_in_release(root: Path, base: str, head: str, path: str) -> bool:
    """The release changed `path`: its content differs between <base> and <head>.

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
        old, new = body_lines(show(root, base, path)), body_lines(show(root, head, path))
        delta = sum(1 for d in difflib.unified_diff(old, new, lineterm="", n=0)
                    if d[:1] in "+-" and not d.startswith(("+++", "---")))
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
    base_text = show(root, base, doc)
    if base_text is None:
        return "FAIL", "retire declared for a document absent at the release base"
    keys, status = frontmatter_of(base_text)
    successor = None
    if status == "ok" and keys.get("status", "").strip():
        arm = "a"
        head_text = show(root, head, doc)
        if head_text is None:
            return "FAIL", "carries the status field and was deleted — retire it by a status move instead"
        hkeys, _ = frontmatter_of(head_text)
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


def eval_issue(root: Path, base: str, head: str, body: str) -> tuple[str, str]:
    content = doc_impact_section(body)
    if content is None:
        return "OUT-OF-SCOPE", "body carries no ### Documentation Impact section"
    if not content:
        return "FAIL", "Documentation Impact section is present but empty"
    if len(content) == 1 and content[0].lstrip("-*+ ").startswith("None"):
        line = content[0].lstrip("-*+ ").strip("`")
        if EXPLICIT_NONE.match(line) and EXPLICIT_NONE.match(line).group(1).strip():
            return "PASS", "explicit None with a rationale"
        return "FAIL", "None without the exact `None — no documentation impact (rationale: …)` form"
    lines = [re.sub(r"^\s*(?:[-*+]|\d+[.)])\s+", "", raw).replace("`", "") for raw in content]
    fails, notes, unevaluated, rows, prose = [], [], [], [], 0
    for k, line in enumerate(lines):
        if "|" in line:
            if is_separator(line) or (line.strip().startswith("|") and k + 1 < len(lines)
                                      and is_separator(lines[k + 1])):
                continue                                 # a table's header or separator row
            got, orphans = parse_row_line(line)
            if not got:
                fails.append(f'unparseable declaration line "{excerpt(line)}": it carries "|" '
                             "but names no `path | action | reason` row")
                continue
            rows += got
            fails += [f'a `{o}` action cell with no path before it, on "{excerpt(line)}"' for o in orphans]
        elif ASSUMPTION_MARKER.search(line):
            fails.append(f'unresolved declaration "{excerpt(line)}": an `[ASSUMPTION – CONFIRM]` '
                         "line in the field is a conditional declaration, resolved at Stage 5 — "
                         "rewrite it as a `path | action | reason` row or remove it")
        else:
            prose += 1          # commentary: the line carries no "|"
    if not rows and not fails:
        return "FAIL", ("no `path | action | reason` row, and the field is not exactly "
                        "`None — no documentation impact (rationale: …)`")
    graded = 0
    for path, action_cell in rows:
        path = "core/CLAUDE.md.template" if path == "CLAUDE.md" else path
        action = norm_action(action_cell)
        if action not in ACTIONS:
            fails.append(f"{path}: unknown action `{action_cell}` — the action is exactly one of "
                         "link, create, update or retire; a qualifier belongs in the reason, and a "
                         "conditional declaration is resolved at Stage 5")
            continue
        if path.startswith(OUT_OF_SCOPE_PREFIXES):
            notes.append(f"{path}: out of the G-CL8 corpus scope")
            continue
        graded += 1
        if re.search(r"[<>*{}]", path):
            fails.append(f"{path} | {action}: placeholder path")
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
        elif not changed_in_release(root, base, head, path):
            fails.append(f"{path} | {action}: unchanged between {short(base)} and {short(head)}")
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
    ap.add_argument("--gate", choices=("g-cl6", "g-cl8"))
    ap.add_argument("--base")
    ap.add_argument("--head")
    ap.add_argument("--plan", help="g-cl6: release plan path, read at <head>")
    ap.add_argument("--issues-dir", help="g-cl8: directory of <N>.md issue bodies")
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
        base = commit("base")
        put("core/diagrams/fm.md", fm.replace("title: T", "title: T2\nowner: x\nreviewed: y\nnote: z") + "body\n" * 5)
        put("core/standards/retire-me.md", fm.replace("ACTIVE", "DEPRECATED") + "to retire\n")
        (r / "docs/old-guide.md").unlink()
        put("README.md", "unrelated\n")
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
            "comma-list": "core/diagrams/fm.md, {d} | update | x",
            "same-line-second-row": "core/diagrams/fm.md | update | x. {d} | update | y",
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
        # changed a.md, so the section PASSes on the one row; the controls below show the
        # hidden row FAILs when visible, and that a heading outside a comment still ends
        # the section.
        vis, hid = "core/diagrams/a.md | update | x", "core/standards/s.md | update | y"
        comments = {
            "multi-line": f"<!--\n{hid}\n-->\n{vis}",
            "single-line": f"{vis} <!-- {hid} -->",
            "heading-inside": f"<!--\n### Example\n{hid}\n-->\n{vis}",
            "bang-close": f"<!-- {hid} --!>\n{vis}",
            "crlf": f"<!--\r\n{hid}\r\n-->\r\n{vis}",
            "unterminated": f"{vis}\n<!-- {hid}",
            "abrupt-empty": f"<!-->\n{vis}",
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
        else:
            failures.append("retire arms not run: blast-radius.sh is not reachable from this file")

    for f in failures:
        print(f"self-test FAIL: {f}", file=sys.stderr)
    print(f"check-doc-gates self-test: {'FAIL' if failures else 'PASS'} ({len(failures)} failure(s))", file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

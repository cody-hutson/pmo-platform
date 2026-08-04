#!/usr/bin/env python3
"""Bind an ADR number at merge, and perform the reconciliation losslessly.

WHY THIS EXISTS
---------------
An ADR number is *allocated at authorship* but *claimed at merge*. Two releases
authoring concurrently both derive the same next-free number, both are correct
about what they can see, and the second to merge must move. ``check-adr-numbers.py``
DETECTS that collision; it has never been able to repair it — its own failure
message prints a remedy it cannot perform ("renumber the later claimant to the
next free slot"). This tool is that remedy, mechanized.

The one observed defect is not the rename. It is that the hand-performed
recovery is *reliably incomplete*: the rename and the index fix land, and the
``## Status`` numbering-provenance note — the step that makes the move auditable
— gets skipped. A checklist that was already written down twice and still missed
is not repaired by writing it down a third time. So the note is written by step
R5 of this tool rather than by discipline.

THE BINDING RULE
----------------
**Only the mainline binds.** ``anchor()`` is the highest ADR number on
``origin/main``; next-free is ``anchor + 1``, never ``max(claimed_set) + 1``.
An unmerged branch claim is advisory: the branch holding it may be rebased,
renumbered, or abandoned. Stepping *above* a visible branch claim to "avoid a
collision" lands a GAP on the mainline when this record merges first — and the
contiguity gate fails a gap as readily as a duplicate, then fails every
subsequent PR until someone fills the hole. A duplicate is the cheap failure
(this tool resolves it); a gap is the expensive one.

``claimed_set()`` — mainline ∪ every unmerged remote branch — feeds ``--detect``
and the hand-off report ONLY. It changes the *report*, never the *number*.

NO SECOND PARSER
----------------
``ADR_DIRS``, ``ADR_FILE_RE``, ``collect()``, ``evaluate()`` and ``next_free()``
are IMPORTED from ``check-adr-numbers.py``, the declared SSOT of the ADR number
space. This tool re-encodes no home-set, no filename regex, and no verdict rule:
the refusal test in R1 is the imported ``evaluate()`` run against the simulated
post-move union, so the tool and the gate can never disagree about what is legal.

USAGE
-----
    python3 release/tools/renumber-adr.py --next-free [--mainline-ref origin/main]
        Print ``anchor(mainline) + 1``. THE BINDING ORACLE. Mainline arm only.

    python3 release/tools/renumber-adr.py --detect [--mainline-ref origin/main]
        Read-only. Report the anchor, the claimed set, this tree's claims, and a
        verdict per claim: BINDS / DUPLICATE / WOULD-GAP. Exit 0 always
        (detection is advisory, never a gate).

    python3 release/tools/renumber-adr.py --renumber <old> <new> [--apply]
        Dry-run by default. ``--apply`` performs steps R1-R6 below.

    python3 release/tools/renumber-adr.py --self-test
        Pure-function fixtures (no git, no I/O). Exit 0 = clean.

THE SIX STEPS (each individually verifiable)
--------------------------------------------
  R1  refuse-or-proceed  — non-zero exit and ZERO mutation if the move is not
                           legal. Never --force, never overwrite.
  R2  git mv             — the record itself; git records a rename.
  R3  citation sweep     — branch-scoped (see the R3 scoping rule below).
  R4  index surfaces     — path-exact rows outside the branch diff + re-sort,
                           and an append to the § Renumber log.
  R5  provenance note    — the ``## Status`` note. THE OBSERVED DEFECT.
  R6  zero-dangling verify — re-scan; any surviving in-scope ``ADR-<old>`` is a
                           failure, and the whole staged set is reverted.

R3 SCOPING RULE (the correctness crux)
--------------------------------------
A naive ``s/ADR-<old>/ADR-<new>/g`` over the corpus is WRONG: it would rewrite
legitimate references to whichever OTHER record holds ``<old>`` — and at renumber
time there always is one, because that is what made this a collision.

  In scope:      files the branch added or modified vs the mainline ref
                 (``git diff --name-only <ref>...HEAD``). This is the branch's
                 own citation set, and it is COMPLETE: a record that has not
                 merged cannot be cited from a mainline-unchanged file.
  Out of scope:  every mainline-unchanged file. If one cites ``ADR-<old>`` it
                 cites the other record — the one that merged first.
  Exception:     R4 may touch a mainline-unchanged INDEX file, but only through
                 a path-exact reference to the moved file (``ADR-<old>-<slug>.md``),
                 never through a bare number.
  Escape hatch:  ``--extra-path`` for the rare hand-verified case. Logged, never
                 default; if it is reached for more than twice the scoping rule
                 needs revisiting rather than widening.

The dirty-tree refusal in R1 is load-bearing for exactly this reason: with a
clean tree, ``<ref>...HEAD`` is the complete branch diff. Uncommitted work would
sit outside it and be swept silently.
"""
from __future__ import annotations

import argparse
import importlib.util
import re
import subprocess
import sys
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent


def _import_number_space():
    """Import the ADR number-space contract from its SSOT.

    ``check-adr-numbers.py`` is not an importable module name (hyphens), so it
    loads by path. This is a real import, not a copy: there is never a second
    parser or a second home-set definition to drift.
    """
    path = TOOL_DIR / "check-adr-numbers.py"
    spec = importlib.util.spec_from_file_location("check_adr_numbers", path)
    if spec is None or spec.loader is None:  # pragma: no cover - defensive
        raise RuntimeError(f"cannot load the ADR number-space contract from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_NS = _import_number_space()
ADR_DIRS = _NS.ADR_DIRS
ADR_FILE_RE = _NS.ADR_FILE_RE
collect = _NS.collect
evaluate = _NS.evaluate
next_free = _NS.next_free

DEFAULT_MAINLINE_REF = "origin/main"

# The § Status provenance note. `at merge time` is MANDATORY, not decorative:
# it is a member of HISTORICAL_ANCHORS in check-adr-durability.py, so the note
# may name a merge SHA without tripping the R2-SHA durability rule.
PROVENANCE_TEMPLATE = (
    "**Numbering provenance — `{old:03d} → {new:03d}`.** Authored branch-local as "
    "**ADR-{old:03d}**; renumbered to **ADR-{new:03d}** at merge time by "
    "`release/tools/renumber-adr.py`, because {cause}. In-release citations that "
    'read "ADR-{old:03d}" denote this record.'
)
CAUSE_DUPLICATE = "the mainline already claimed {old:03d}"
CAUSE_GAP = "the claim would have landed a gap beneath it on the mainline"

PROVENANCE_RE = re.compile(r"\*\*Numbering provenance — `\d{3} → \d{3}`\.\*\*")

RENUMBER_LOG_HEADING_RE = re.compile(r"^\*\*Renumber log\.\*\*", re.MULTILINE)
RENUMBER_LOG_SENTENCE_RE = re.compile(
    r"ADR-\d{3} \(`[^`]+`\) → \*\*ADR-\d{3}\*\* by `release/tools/renumber-adr\.py`"
)


# --------------------------------------------------------------------------
# git plumbing
# --------------------------------------------------------------------------


def git(*args, root=None, check=True):
    """Run a git command and return stdout (stripped)."""
    proc = subprocess.run(
        ["git", *args],
        cwd=str(root) if root else None,
        capture_output=True,
        text=True,
    )
    if check and proc.returncode != 0:
        raise RuntimeError(
            f"git {' '.join(args)} failed ({proc.returncode}): {proc.stderr.strip()}"
        )
    return proc.stdout.strip()


def repo_root(start=None):
    return Path(git("rev-parse", "--show-toplevel", root=start or TOOL_DIR))


def tree_is_clean(root):
    return git("status", "--porcelain", root=root) == ""


# --------------------------------------------------------------------------
# Adapter vocabulary — anchor / claimed_set / lineage / reconcile_at_merge
#
# The interface deliberately mirrors the repo-host version adapter
# (repo-host-adapter-versioning.md). Three of its four operations transfer
# cleanly. The fourth does NOT: `atomic_claim` is a compare-and-swap on a single
# ref, and an ADR number is a filename plus N in-branch citations plus index
# rows — no host offers CAS over that object, and simulating one would require
# exactly the read-then-write the adapter spec forbids. It is therefore declared
# NON-IMPLEMENTABLE and replaced by `reconcile_at_merge()`: post-hoc
# reconciliation, not compare-and-swap. The merge is the arbiter.
# --------------------------------------------------------------------------


def _numbers_in_ref(ref, root):
    """Return {number: [paths]} for ADR files present at a git ref."""
    listing = git("ls-tree", "-r", "--name-only", ref, root=root, check=False)
    by_number = {}
    for line in listing.splitlines():
        p = Path(line)
        if p.parent.as_posix() not in ADR_DIRS:
            continue
        m = ADR_FILE_RE.match(p.name)
        if m:
            by_number.setdefault(int(m.group(1)), []).append(line)
    return by_number


def anchor(ref, root):
    """Highest ADR number in the MAINLINE sequence. THE BINDING ORACLE's input."""
    mainline = _numbers_in_ref(ref, root)
    return (max(mainline) if mainline else 0), mainline


def claimed_set(ref, root):
    """Mainline numbers ∪ every unmerged remote branch's claims.

    DETECTION ONLY. This feeds --detect and the hand-off report; it never feeds
    --next-free. Consuming it as a binding input is the 'step past the visible
    claim' error that lands a gap on the mainline.
    """
    _, mainline = anchor(ref, root)
    claims = {n: {"MAINLINE"} for n in mainline}
    branches = git(
        "for-each-ref", "--format=%(refname:short)", "refs/remotes", root=root,
        check=False,
    )
    for br in branches.splitlines():
        if br.endswith("/HEAD") or br == ref:
            continue
        for n in _numbers_in_ref(br, root):
            if n not in mainline:
                claims.setdefault(n, set()).add(br)
    return claims


def lineage(n, ref, root):
    """MAINLINE iff ADR-n exists on the mainline ref; else BRANCH-CLAIM.

    The ADR analogue of the version adapter's ORPHAN verdict — with INVERTED
    authority. For versions, an in-flight claim BINDS (a pushed tag is
    authoritative). For ADR numbers a branch claim does NOT bind, because the
    gate guards the mainline's contiguity rather than any branch's. This one
    operation carries the whole asymmetry between the two number spaces.
    """
    _, mainline = anchor(ref, root)
    return "MAINLINE" if n in mainline else "BRANCH-CLAIM"


def _rel(root, path):
    """Repo-relative posix form, so mainline and worktree paths compare equal."""
    p = Path(path)
    return p.relative_to(root).as_posix() if p.is_absolute() else p.as_posix()


def worktree_claims(root):
    """Return {number: {repo-relative path, ...}} for the working tree."""
    by_number, _malformed = collect([root / d for d in ADR_DIRS])
    return {n: {_rel(root, p) for p in paths} for n, paths in by_number.items()}


def reconcile_at_merge(ref, root):
    """Return (anchor, [(number, path, verdict, suggested), ...]) for this tree.

    Replaces `atomic_claim`. For a branch holding claims B above a mainline
    anchor A, the merged result is contiguous iff B == {A+1 .. A+|B|}. Each
    claim is graded against the slot it must occupy for that to hold.

    "Ours" is a PATH test, not a number test: a number is this branch's claim
    when the working tree holds a file for it that the mainline does not. A
    number test would miss the collision case outright — at a duplicate the
    mainline holds the number too, under a different filename, which is exactly
    the case that has to be reconciled.
    """
    a, mainline_by_n = anchor(ref, root)
    mainline = {n: set(p) for n, p in mainline_by_n.items()}
    worktree = worktree_claims(root)
    ours = sorted(n for n, paths in worktree.items()
                  if not paths <= mainline.get(n, set()))
    rows = []
    for i, n in enumerate(ours):
        expected = a + 1 + i
        path = sorted(worktree[n] - mainline.get(n, set()))[0]
        if n in mainline:
            verdict = "DUPLICATE"
        elif n == expected:
            verdict = "BINDS"
        elif n > expected:
            verdict = "WOULD-GAP"
        else:
            verdict = "DUPLICATE"
        rows.append((n, path, verdict, expected))
    return a, rows


# --------------------------------------------------------------------------
# Citation rewriting
# --------------------------------------------------------------------------


def citation_re(old):
    """Match ``ADR-<old>`` as a whole token, zero-padding tolerant.

    Both boundaries are load-bearing:
      - right ``(?![0-9])`` stops ``ADR-10`` matching inside ``ADR-104``;
        without it, renumbering ADR-10 would corrupt ten live records.
      - left ``(?<![0-9A-Za-z])`` stops a match inside a longer token.
    Filenames are moved by ``git mv``, never by this regex — the SSOT for
    filename shape stays ``ADR_FILE_RE``.
    """
    return re.compile(r"(?<![0-9A-Za-z])ADR-0*%d(?![0-9])" % old)


def is_historical_numbering_line(line):
    """True for a line that RECORDS an old number rather than CITES a record.

    The ``## Status`` provenance note and the § Renumber log both exist to say
    "this record used to be ADR-<old>". They are the audit trail the renumber
    creates. Sweeping them would erase exactly what the move is supposed to
    document — and would make the tool's own R5/R4 output fail its own R6
    verify on the next run. A record of a number is not a reference to one.
    """
    return bool(PROVENANCE_RE.search(line) or RENUMBER_LOG_SENTENCE_RE.search(line))


def rewrite_citations(text, old, new, preserve_historical=True):
    """Return (new_text, count) with every whole-token ADR-<old> → ADR-<new>.

    Lines that RECORD an old number (see ``is_historical_numbering_line``) are
    left alone; the rewrite is line-wise so one exempt line does not exempt its
    neighbours.
    """
    pattern, repl = citation_re(old), f"ADR-{new:03d}"
    out, count = [], 0
    for line in text.split("\n"):
        if preserve_historical and is_historical_numbering_line(line):
            out.append(line)
            continue
        rewritten, n = pattern.subn(repl, line)
        out.append(rewritten)
        count += n
    return "\n".join(out), count


def rewrite_path_exact(text, old, new, slug):
    """Rewrite ONLY path-exact references to the moved file.

    Used on index files that are unchanged vs the mainline ref, where a bare
    ``ADR-<old>`` denotes the OTHER record. ``ADR-<old>-<slug>.md`` is
    unambiguous — it names this file and no other.
    """
    old_name = f"ADR-{old:03d}-{slug}"
    new_name = f"ADR-{new:03d}-{slug}"
    count = text.count(old_name)
    if not count:
        return text, 0
    text = text.replace(old_name, new_name)
    # A markdown link renders as [ADR-NNN](ADR-NNN-slug.md); the href is now
    # rewritten, so bring its link TEXT along with it.
    text = text.replace(f"[ADR-{old:03d}]({new_name}", f"[ADR-{new:03d}]({new_name}")
    return text, count


def resort_adr_table(text):
    """Re-sort any contiguous markdown table block whose first cell is an ADR.

    Operates only on runs of rows already shaped ``| ADR-NNN … |`` or
    ``| [ADR-NNN](…) … |``; anything else is returned untouched.
    """
    lines = text.split("\n")
    row_re = re.compile(r"^\|\s*\[?ADR-(\d+)\]?")
    out, i = [], 0
    while i < len(lines):
        if row_re.match(lines[i]):
            j = i
            while j < len(lines) and row_re.match(lines[j]):
                j += 1
            block = sorted(lines[i:j], key=lambda ln: int(row_re.match(ln).group(1)))
            out.extend(block)
            i = j
        else:
            out.append(lines[i])
            i += 1
    return "\n".join(out)


def resort_inline_list(text):
    """Re-sort an inline prose run of ``ADR-NNN, ADR-NNN, …`` into ascending order.

    The § Naming convention list is free text, not a table — it is the one
    non-tabular index surface, and the place a naive implementation breaks.
    """
    def _sort_run(m):
        nums = sorted(int(n) for n in re.findall(r"ADR-(\d+)", m.group(0)))
        return ", ".join(f"ADR-{n:03d}" for n in nums)

    return re.sub(r"ADR-\d+(?:,\s*ADR-\d+){2,}", _sort_run, text)


def provenance_note(old, new, cause):
    return PROVENANCE_TEMPLATE.format(old=old, new=new, cause=cause)


def insert_provenance(text, note):
    """Append the note as the last paragraph of the ``## Status`` section.

    Idempotent: a record that already carries a provenance note of this shape is
    left alone, so re-running --apply on an already-renumbered tree is a no-op.
    """
    if PROVENANCE_RE.search(text):
        return text, "already-present"
    lines = text.split("\n")
    start = None
    for i, ln in enumerate(lines):
        if ln.strip() == "## Status":
            start = i
            break
    if start is None:
        # Distinct from "already present" — the record has no ## Status section
        # to hold the note. R6 fails closed on it rather than reporting success.
        return text, "no-status-section"
    end = len(lines)
    for j in range(start + 1, len(lines)):
        if lines[j].startswith("## "):
            end = j
            break
    while end > start + 1 and lines[end - 1].strip() == "":
        end -= 1
    lines[end:end] = ["", note]
    return "\n".join(lines), "written"


def append_renumber_log(text, old, new, slug, cause):
    """Append one sentence to the § Renumber log. Append-only, never a rewrite."""
    m = RENUMBER_LOG_HEADING_RE.search(text)
    if not m:
        return text, False
    sentence = (
        f" ADR-{old:03d} (`{slug}`) → **ADR-{new:03d}** by "
        f"`release/tools/renumber-adr.py` at merge time, because {cause}; "
        "the record's Status section carries the provenance note."
    )
    if sentence.strip() in text:
        return text, False   # idempotent: never log the same move twice
    lines = text.split("\n")
    idx = text[: m.start()].count("\n")
    lines[idx] = lines[idx].rstrip() + sentence
    return "\n".join(lines), True


# --------------------------------------------------------------------------
# The six steps
# --------------------------------------------------------------------------


def _in_scope_files(ref, root, extra_paths):
    """The branch's own citation set: files added/modified vs the mainline ref."""
    diff = git("diff", "--name-only", f"{ref}...HEAD", root=root, check=False)
    files = {ln for ln in diff.splitlines() if ln}
    for pattern in extra_paths or []:
        for p in root.glob(pattern):
            if p.is_file():
                files.add(p.relative_to(root).as_posix())
    return sorted(f for f in files if (root / f).is_file())


def _index_files(root):
    """Index surfaces the tool maintains outside the branch diff."""
    return [d + "/README.md" for d in ADR_DIRS if (root / d / "README.md").is_file()]


def do_renumber(old, new, ref, root, apply_changes, extra_paths, log):
    """Steps R1-R6. Returns 0 on success, non-zero on refusal or verify failure."""
    worktree = worktree_claims(root)
    _a, mainline_by_n = anchor(ref, root)
    mainline = {n: set(p) for n, p in mainline_by_n.items()}

    # ---- R1 refuse-or-proceed ------------------------------------------
    # COMPLETION MODE. <old> absent and <new> present means the rename already
    # happened — either this tool ran before (idempotent re-run) or somebody
    # performed it by hand. The hand case is the OBSERVED DEFECT: `409545d4`
    # renamed and fixed the index but never wrote the provenance note, leaving
    # ADR-088 unauditable to this day. Refusing here would leave the one
    # reliably-skipped step still skipped, so the tool completes R3-R6 instead.
    # "Ours" is always the PATH set the mainline does not have. At a duplicate
    # the working tree holds two files for one number, so a bare `old in
    # worktree` test would see the MAINLINE's record and mis-route.
    ours_old = sorted(worktree.get(old, set()) - mainline.get(old, set()))
    ours_new = sorted(worktree.get(new, set()) - mainline.get(new, set()))
    completion = not ours_old and bool(ours_new)
    if not ours_old and not completion:
        if old in worktree:
            log(f"R1 REFUSE: ADR-{old:03d} exists only on {ref} — it is a merged "
                f"record, not this branch's claim. Renumbering it would break "
                f"every mainline citation. Supersede it instead.")
        else:
            log(f"R1 REFUSE: ADR-{old:03d} is not present in this tree.")
        return 2
    if completion:
        new_path = root / ours_new[0]
        m = ADR_FILE_RE.match(new_path.name)
        slug = m.group(0)[len(f"ADR-{m.group(1)}-") : -len(".md")]
        old_path = new_path.parent / f"ADR-{old:03d}-{slug}.md"
        log(f"R1 COMPLETION MODE: ADR-{old:03d} is gone and ADR-{new:03d} is "
            f"present — the rename already happened. Completing R3-R6.")
    else:
        # THE BRANCH'S CLAIM, NEVER THE MAINLINE'S RECORD. At a duplicate the
        # working tree holds two files for the same number; the one to move is
        # the one the mainline does not have. Moving the merged record instead
        # would break every mainline citation to it — the reference-cascade
        # hazard this tool exists to avoid — and would edit a ratified record.
        old_path = root / ours_old[0]
        m = ADR_FILE_RE.match(old_path.name)
        slug = m.group(0)[len(f"ADR-{m.group(1)}-") : -len(".md")]
        new_path = old_path.parent / f"ADR-{new:03d}-{slug}.md"
        if new in worktree:
            log(f"R1 REFUSE: ADR-{new:03d} is already claimed in this tree "
                f"({sorted(worktree[new])[0]}). Never overwrite.")
            return 2

    if apply_changes and not completion and not tree_is_clean(root):
        log("R1 REFUSE: working tree is dirty. The branch diff is only complete "
            "against a clean tree, so an uncommitted citation would be swept "
            "silently. Commit or stash first.")
        return 2

    # The legality test IS the imported gate rule — the tool and the gate can
    # never disagree about what is a GAP or a DUPLICATE. Paths are unioned as
    # SETS in repo-relative form so a file present in both the mainline and the
    # working tree (every unchanged record) counts once, not twice.
    simulated = {n: set(p) for n, p in mainline.items()}
    for n, paths in worktree.items():
        if n == old:
            continue
        simulated.setdefault(n, set()).update(paths)
    simulated.setdefault(new, set()).add(_rel(root, new_path))
    problems = evaluate({n: sorted(v) for n, v in simulated.items()}, [])
    if problems:
        log(f"R1 REFUSE: moving ADR-{old:03d} → ADR-{new:03d} is not legal "
            f"against {ref}:")
        for p in problems:
            log("    " + p)
        return 2

    cause = (CAUSE_DUPLICATE if old in mainline else CAUSE_GAP).format(old=old)
    log(f"R1 PROCEED: ADR-{old:03d} → ADR-{new:03d} ({old_path} → {new_path})")
    log(f"    anchor({ref}) = {_a}; cause = {cause}")

    in_scope = _in_scope_files(ref, root, extra_paths)

    if not apply_changes:
        hits = 0
        for rel in in_scope:
            body = (root / rel).read_text(encoding="utf-8")
            n = len(citation_re(old).findall(body))
            if n:
                hits += n
                log(f"    would rewrite {n:>3} × ADR-{old:03d} in {rel}")
        log(f"DRY-RUN: {hits} citation(s) would move. Re-run with --apply.")
        return 0

    head = git("rev-parse", "HEAD", root=root)
    old_rel, new_rel = _rel(root, old_path), _rel(root, new_path)
    touched = set()

    def revert(reason):
        log(f"R6 FAIL: {reason}")
        log("    reverting the whole staged set (zero partial application)")
        git("reset", "-q", root=root, check=False)
        git("checkout", "--", ".", root=root, check=False)
        if not completion:
            # `git checkout -- .` restores every TRACKED path, which brings the
            # old filename back — but the renamed file is untracked after the
            # reset, so it survives unless it is removed explicitly. Leaving it
            # would make a failed run look like a duplicate.
            git("checkout", head, "--", old_rel, root=root, check=False)
            tracked = git("ls-files", "--", new_rel, root=root, check=False)
            if new_path.exists() and not tracked:
                new_path.unlink()
        return 3

    # ---- R2 git mv ------------------------------------------------------
    if completion:
        log("R2 git mv: SKIPPED (completion mode — the rename is already in place)")
    else:
        git("mv", old_rel, new_rel, root=root)
        log(f"R2 git mv: {old_rel} → {new_rel}")
    touched.add(new_rel)

    # ---- R3 citation sweep (branch-scoped) ------------------------------
    log(f"R3 scope: {len(in_scope)} file(s) in the branch diff vs {ref}")
    swept = 0
    for rel in in_scope:
        target = root / (new_rel if rel == old_rel else rel)
        if not target.is_file():
            continue
        body = target.read_text(encoding="utf-8")
        updated, n = rewrite_citations(body, old, new)
        if n:
            target.write_text(updated, encoding="utf-8")
            touched.add(_rel(root, target))
            swept += n
    log(f"R3 citation sweep: {swept} occurrence(s) rewritten across "
        f"{max(len(touched) - 1, 0)} file(s)")

    # ---- R4 index surfaces ----------------------------------------------
    for rel in _index_files(root):
        target = root / rel
        body = target.read_text(encoding="utf-8")
        original = body
        if rel in in_scope:
            body, _ = rewrite_citations(body, old, new)
        else:
            body, _ = rewrite_path_exact(body, old, new, slug)
        body = resort_adr_table(body)
        body = resort_inline_list(body)
        body, logged = append_renumber_log(body, old, new, slug, cause)
        if body != original:
            target.write_text(body, encoding="utf-8")
            touched.add(rel)
            log(f"R4 index: updated {rel}" + (" (+ § Renumber log)" if logged else ""))

    # ---- R5 provenance note ---------------------------------------------
    body = new_path.read_text(encoding="utf-8")
    body, state = insert_provenance(body, provenance_note(old, new, cause))
    if state == "written":
        new_path.write_text(body, encoding="utf-8")
        log("R5 provenance: ## Status note written")
    elif state == "already-present":
        log("R5 provenance: note already present (idempotent re-run)")
    else:
        return revert(f"{new_rel} has no '## Status' section to carry the "
                      "numbering-provenance note")

    # ---- R6 zero-dangling verify ----------------------------------------
    dangling = []
    for rel in in_scope:
        p = root / (new_rel if rel == old_rel else rel)
        if not p.is_file():
            continue
        # Historical-record lines name the old number ON PURPOSE — the
        # provenance note and the § Renumber log are the audit trail this move
        # creates. Scanning them would make R5 and R4 fail R6.
        body = "\n".join(ln for ln in p.read_text(encoding="utf-8").split("\n")
                         if not is_historical_numbering_line(ln))
        if citation_re(old).search(body):
            dangling.append(_rel(root, p))
    if dangling:
        return revert(f"{len(dangling)} in-scope file(s) still cite ADR-{old:03d}: "
                      + ", ".join(dangling))
    if not PROVENANCE_RE.search(new_path.read_text(encoding="utf-8")):
        return revert("the ## Status numbering-provenance note is absent")
    # Evaluate the SIMULATED MERGE RESULT, not the bare working tree. A branch
    # that has not merged the mainline is legitimately missing the numbers the
    # mainline claimed while it was away, so a working-tree evaluation reports a
    # confident GAP that the merge does not have. That is the same
    # answer-computed-over-the-wrong-population defect this whole tool exists to
    # fix — and the fixture caught this verify step committing it.
    post = worktree_claims(root)
    merged = {n: set(p) for n, p in mainline.items()}
    for n, paths in post.items():
        merged.setdefault(n, set()).update(paths)
    residual = evaluate({n: sorted(v) for n, v in merged.items()}, [])
    if residual:
        return revert("the merge result would fail check-adr-numbers: "
                      + "; ".join(residual))

    git("add", "-A", root=root)
    log("R6 verify: zero dangling in-scope citations; provenance note present; "
        "number space clean. Changes staged.")
    return 0


# --------------------------------------------------------------------------
# self-test (pure functions; no git, no filesystem)
# --------------------------------------------------------------------------


def self_test():
    failures = []

    def eq(label, got, want):
        if got != want:
            failures.append(f"[{label}] expected {want!r}, got {got!r}")

    # The right boundary is the load-bearing one: without it, renumbering
    # ADR-010 would corrupt ADR-100..ADR-109.
    eq("boundary/right", rewrite_citations("see ADR-104 and ADR-10.", 10, 11),
       ("see ADR-104 and ADR-011.", 1))
    eq("boundary/left", rewrite_citations("XADR-010 vs ADR-010", 10, 11),
       ("XADR-010 vs ADR-011", 1))
    eq("boundary/zero-pad", rewrite_citations("ADR-99 and ADR-099", 99, 100),
       ("ADR-100 and ADR-100", 2))
    # Specificity: a number nobody cited must move nothing.
    eq("boundary/specificity", rewrite_citations("ADR-104 ADR-010", 77, 78),
       ("ADR-104 ADR-010", 0))
    # Path-exact rewriting on a mainline-unchanged index: the bare number is
    # someone else's record and must NOT move; the slugged path is ours.
    eq("path-exact",
       rewrite_path_exact("| [ADR-004](ADR-004-bravo.md) | x |\nbare ADR-004\n",
                          4, 5, "bravo"),
       ("| [ADR-005](ADR-005-bravo.md) | x |\nbare ADR-004\n", 1))
    # A record of an old number is not a citation of it: the sweep must leave
    # the provenance note and the § Renumber log alone, or it erases its own
    # audit trail. Sensitivity control: an ordinary line on the same input DOES
    # move, so this is not a probe that simply never fires.
    hist = ("**Numbering provenance — `004 → 005`.** was ADR-004.\n"
            "plain citation of ADR-004 here\n")
    eq("historical/exempt", rewrite_citations(hist, 4, 5),
       ("**Numbering provenance — `004 → 005`.** was ADR-004.\n"
        "plain citation of ADR-005 here\n", 1))
    logline = ("**Renumber log.** ADR-004 (`bravo`) → **ADR-005** by "
               "`release/tools/renumber-adr.py` at merge time.")
    eq("historical/renumber-log-exempt", rewrite_citations(logline, 4, 5),
       (logline, 0))
    eq("resort/table",
       resort_adr_table("| ADR-005 | b |\n| ADR-002 | a |"),
       "| ADR-002 | a |\n| ADR-005 | b |")
    eq("resort/inline",
       resort_inline_list("holds ADR-005, ADR-002, ADR-004."),
       "holds ADR-002, ADR-004, ADR-005.")
    note = provenance_note(4, 5, CAUSE_DUPLICATE.format(old=4))
    if "at merge time" not in note:
        failures.append("[provenance] the mandatory `at merge time` anchor is absent")
    if not PROVENANCE_RE.search(note):
        failures.append("[provenance] the note does not match its own detector")
    body, wrote = insert_provenance("## Status\n\nProposed.\n\n## Context\n\nx\n", note)
    eq("provenance/insert-once", wrote, "written")
    eq("provenance/idempotent", insert_provenance(body, note)[1], "already-present")
    eq("provenance/no-status-section",
       insert_provenance("# ADR\n\n## Context\n\nx\n", note)[1], "no-status-section")
    eq("provenance/section", body.index(note) < body.index("## Context"), True)

    if failures:
        print("renumber-adr self-test: FAIL")
        for f in failures:
            print("  - " + f)
        return 1
    print("renumber-adr self-test: PASS (citation boundaries / path-exact / "
          "re-sort / provenance)")
    return 0


# --------------------------------------------------------------------------


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Bind an ADR number at merge; reconcile a collision losslessly."
    )
    parser.add_argument("--mainline-ref", default=DEFAULT_MAINLINE_REF,
                        help=f"the ref that BINDS (default: {DEFAULT_MAINLINE_REF})")
    parser.add_argument("--next-free", action="store_true",
                        help="print anchor(mainline)+1 — the binding oracle")
    parser.add_argument("--detect", action="store_true",
                        help="report per-claim BINDS / DUPLICATE / WOULD-GAP")
    parser.add_argument("--renumber", nargs=2, type=int, metavar=("OLD", "NEW"))
    parser.add_argument("--apply", action="store_true",
                        help="perform the move (default is dry-run)")
    parser.add_argument("--extra-path", action="append", default=[],
                        help="hand-verified extra glob for the R3 sweep (logged)")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--root", type=Path, default=None)
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()

    root = args.root or repo_root()
    ref = args.mainline_ref

    if args.next_free:
        _a, mainline = anchor(ref, root)
        print(next_free(mainline))
        return 0

    if args.detect:
        a, rows = reconcile_at_merge(ref, root)
        claims = claimed_set(ref, root)
        branch_only = sorted(n for n, src in claims.items() if "MAINLINE" not in src)
        print(f"ANCHOR\t{a}\t{ref}")
        print(f"NEXT-FREE\t{a + 1}")
        print("CLAIMED-SET-BRANCH-ONLY\t"
              + (",".join(str(n) for n in branch_only) or "-")
              + "\t(detection only — never binds)")
        for n, path, verdict, expected in rows:
            suffix = "" if verdict == "BINDS" else f"\tnext={expected}"
            print(f"CLAIM\tADR-{n:03d}\t{path}\t{verdict}"
                  f"\t{lineage(n, ref, root)}{suffix}")
        if not rows:
            print("CLAIM\t-\t-\tNONE\t(this tree adds no ADR)")
        return 0

    if args.renumber:
        old, new = args.renumber
        return do_renumber(old, new, ref, root, args.apply, args.extra_path, print)

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

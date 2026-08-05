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
the refusal test in R1 is the imported ``evaluate()``, so the tool and the gate
can never disagree about what is legal.

R1'S LEGALITY TEST IS A DELTA, NOT AN ABSOLUTE
----------------------------------------------
``evaluate()`` grades a WHOLE number space; execution granularity here is ONE
move. Those two are only equivalent at N=1. Asking "is the post-move union
problem-free?" refuses every move of a multi-claim reconciliation, because the
OTHER outstanding claims are counted as problems with THIS move — so at N>=2
every ordering refuses and the tool deadlocks against a plan it computed itself.
That is not hypothetical: `57a53a69` broke the deadlock with a hand ``git mv``.

R1 therefore runs the SAME imported ``evaluate()`` on BOTH sides of the move and
compares:

  REFUSE if the move INTRODUCES a problem the corpus did not already carry, or
  if it fails to ADVANCE the corpus toward a legal end state.

The safety property is unchanged and is now stated exactly: the tool never
creates a violation the gate would fail. It simply no longer requires one move
to finish work that takes three. See ``_problem_keys`` (why a GAP keys as ONE
problem rather than per missing number) and ``_residual`` (the advance measure).

THE ASSIGNMENT IS MINIMAL: A FREE CLAIM IS HELD FIXED
-----------------------------------------------------
``reconcile_at_merge()`` reassigns only the claims that genuinely collide. A
branch claim whose number the mainline does NOT hold, and which already sits
inside the free range the merged union needs, is HELD FIXED — it is already
where it belongs, and moving it costs a second provenance note, a second
citation sweep and a second ``§ Renumber log`` entry for a record that never
needed to move. Holding it also removes one way a plan can self-conflict: it
is what stops the planner targeting a number another row of the same plan
still occupies. The order-preserving tie-break then applies to the claims that
DO move. See ADR-115.

USAGE
-----
    python3 release/tools/renumber-adr.py --next-free [--mainline-ref origin/main]
        Print ``anchor(mainline) + 1``. THE BINDING ORACLE. Mainline arm only.

    python3 release/tools/renumber-adr.py --detect [--mainline-ref origin/main]
        Read-only. Report the anchor, the claimed set, this tree's claims, and a
        verdict per claim: BINDS / DUPLICATE / WOULD-GAP. Exit 0 always
        (detection is advisory, never a gate).

    python3 release/tools/renumber-adr.py --renumber <old> <new> [--apply]
        [--extra-path GLOB] [--exclude-path GLOB]
        Dry-run by default. ``--apply`` performs steps R1-R6 below.

    python3 release/tools/renumber-adr.py --self-test
        Pure-function fixtures (no git, no I/O). Exit 0 = clean.

THE SIX STEPS (each individually verifiable)
--------------------------------------------
  R1  refuse-or-proceed  — non-zero exit and ZERO mutation if the move
                           INTRODUCES a violation or fails to advance (see
                           "R1's legality test is a delta"). Never --force,
                           never overwrite.
  R2  git mv             — the record itself; git records a rename.
  R3  citation sweep     — branch-scoped (see the R3 scoping rule below).
  R4  index surfaces     — the HAND-MAINTAINED index (`core/ADRs/README.md`) gets
                           path-exact rows outside the branch diff + a re-sort +
                           an append to the § Renumber log. The PROJECTED index
                           (`release/ADRs/README.md`) is REGENERATED by
                           `generate-adr-index.py` instead: hand-editing a derived
                           region is what its own verification posture fails, so a
                           rewriting renumber would break the projection check it
                           had just triggered. See `PROJECTED_INDEXES` and ADR-113.
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
                 never through a bare number. On a PROJECTED index the exception is
                 stronger and needs no scoping rule at all: the projector derives
                 every row from the file set, so it cannot reach another record's
                 number by construction.
  Escape hatch:  ``--extra-path`` for the rare hand-verified case. Logged, never
                 default; if it is reached for more than twice the scoping rule
                 needs revisiting rather than widening.
  Counterpart:   ``--exclude-path`` NARROWS the scope, and it exists because the
                 completeness argument above runs one way only. "An unmerged
                 record cannot be cited from a mainline-unchanged file" is true.
                 Its converse is FALSE: once the mainline is merged INTO the
                 release branch, a file the branch also modified carries the
                 MAINLINE's prose — including the mainline's own citations to
                 whichever record holds ``<old>``. Those are in the branch diff
                 and R3 rewrites them. Observed on the first production run: three
                 mainline citations in a CI workflow the branch had also edited.
                 Logged, never default, and the pattern is asserted to match.

  Not covered:   the same file carrying BOTH a branch citation and a mainline
                 citation of ``<old>``. ``--exclude-path`` is whole-file, so that
                 case still needs a hand pass. The durable fix is to scope R3 to
                 the branch's own changed LINE RANGES rather than whole files.

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

# Index surfaces that are PROJECTED, not hand-maintained: {surface: projector}.
# R4 regenerates these instead of rewriting rows, because hand-editing a generated
# region is what the Derived-Surface Contract's verification posture fails — a
# renumber that rewrote a row would break the projection check it had just
# triggered. `core/ADRs/README.md` is deliberately absent: it is a curated thematic
# document, not an index, and R4 keeps rewriting it in place. See ADR-113.
PROJECTED_INDEXES = {
    "release/ADRs/README.md": "generate-adr-index.py",
}

# The projector's own region fence. R6 must not read INSIDE it — see
# `_strip_projected_region`.
PROJECTED_REGION_BEGIN = "<!-- ADR-INDEX:BEGIN -->"
PROJECTED_REGION_END = "<!-- ADR-INDEX:END -->"

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


def _problem_keys(problems):
    """Key ``evaluate()``'s messages so two runs of it can be compared.

    NOT a second verdict rule. The messages are produced by the imported
    ``evaluate()``; this only gives each one a stable identity so "did THIS move
    introduce it?" is answerable.

    DUPLICATE keys per number and MALFORMED per path, because those are
    per-subject problems: resolving one leaves the others' keys untouched.

    GAP keys as ONE problem, deliberately, because contiguity is a property of
    the whole sequence rather than of any number. A downward cascade MOVES the
    hole (fill 115, open 116) before it closes it, and keying per missing number
    would read a moved hole as a NEW problem and refuse the very move that
    repairs it. The advance test (`_residual`) is what stops a hole being
    shuffled forever, so nothing is lost by keying it coarsely here.

    An unrecognised message keys by its full text, so a future verdict kind is
    treated as new-and-therefore-refused rather than silently admitted.
    """
    keys = set()
    for p in problems:
        if p.startswith("DUPLICATE:"):
            m = re.search(r"ADR-(\d+)", p)
            keys.add(("DUPLICATE", int(m.group(1))) if m else ("DUPLICATE", p))
        elif p.startswith("MALFORMED:"):
            keys.add(("MALFORMED", p.split(" does not match", 1)[0].strip()))
        elif p.startswith("GAP:"):
            keys.add(("GAP",))
        else:
            keys.add(("UNKNOWN", p))
    return keys


def _residual(by_number):
    """Distance from a legal end state. Lower is strictly closer; (0, 0) is clean.

    Two components, compared lexicographically:

      [0] duplicate mass — how many records share a number with another. Every
          collision repair strictly reduces it.
      [1] how far the LOWEST hole sits below the top of the sequence. A
          downward cascade fills holes from the bottom, so the lowest hole
          climbs one slot per move and this reaches 0 when the run closes up.

    Together they make "advance" a well-ordered claim rather than a hopeful one:
    a move that shuffles a record sideways, or opens a hole as deep as the one
    it filled, does not decrease either component and is refused.
    """
    if not by_number:
        return (0, 0)
    excess = sum(len(v) - 1 for v in by_number.values())
    top = max(by_number)
    missing = sorted(set(range(1, top + 1)) - set(by_number))
    return (excess, top + 1 - (missing[0] if missing else top + 1))


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
    anchor A, the merged result is contiguous iff the union occupies exactly
    ``1 .. A+|B|`` — so the slots the branch must end up holding are the free
    range ``A+1 .. A+|B|``.

    "Ours" is a PATH test, not a number test: a number is this branch's claim
    when the working tree holds a file for it that the mainline does not. A
    number test would miss the collision case outright — at a duplicate the
    mainline holds the number too, under a different filename, which is exactly
    the case that has to be reconciled.

    THE ASSIGNMENT IS MINIMAL. Determining WHICH claims move comes before
    ordering the ones that do. A claim already sitting inside the free range,
    on a number the mainline does not hold, is HELD FIXED: it is where it
    belongs, and reassigning it would renumber a record for nothing — a second
    provenance note, a second citation sweep, a second `§ Renumber log` entry.
    Held claims are also what keeps the plan self-consistent: without this
    clause the planner hands out the free range from the bottom and can target
    a number a later row of the same plan still occupies, producing a plan no
    ordering can execute. The order-preserving tie-break (ADR-115) then applies
    to the claims that genuinely collide, over the slots that remain.
    """
    a, mainline_by_n = anchor(ref, root)
    mainline = {n: set(p) for n, p in mainline_by_n.items()}
    worktree = worktree_claims(root)
    ours = sorted(n for n, paths in worktree.items()
                  if not paths <= mainline.get(n, set()))
    rows = []
    for n, verdict, expected in assign_claims(a, ours, set(mainline)):
        path = sorted(worktree[n] - mainline.get(n, set()))[0]
        rows.append((n, path, verdict, expected))
    return a, rows


def assign_claims(a, ours, mainline_numbers):
    """The minimal assignment. Pure: (anchor, [claims], {mainline numbers}).

    Returns ``[(number, verdict, target), ...]`` in ``ours`` order. Split out of
    ``reconcile_at_merge`` so the rule can be pinned by the self-test without a
    git fixture — the assignment is the part that was wrong, so it is the part
    that has to be gradable directly.
    """
    free_range = list(range(a + 1, a + 1 + len(ours)))
    held = {n for n in ours if n not in mainline_numbers and n in set(free_range)}
    open_slots = [s for s in free_range if s not in held]
    out = []
    for n in ours:
        if n in held:
            out.append((n, "BINDS", n))
            continue
        out.append((n, "DUPLICATE" if n in mainline_numbers else "WOULD-GAP",
                    open_slots.pop(0)))
    return out


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


def _strip_projected_region(lines):
    """Drop the projector-owned region from a PROJECTED index surface.

    R6 asks "does any in-scope file still cite ``ADR-<old>``?" and reads a hit as
    a DANGLING reference to the record it just moved. Inside a projected region
    that question is malformed. The region is DERIVED from the ADR file set, so a
    row reading ``ADR-<old>`` is the row of whichever record still legally holds
    ``<old>`` — and at a DUPLICATE reconciliation, which is this tool's primary
    case, that is the MAINLINE's record by construction. R4 has already
    regenerated the region from the post-rename file set and the projector's own
    ``--verify`` is that surface's correctness check.

    Observed on the first production run: R6 read the mainline's own index row as
    this branch's dangling citation and reverted a complete, correct move.

    Prose OUTSIDE the region is authored, not derived, so it stays under the scan.
    """
    out, inside = [], False
    for ln in lines:
        if PROJECTED_REGION_BEGIN in ln:
            inside = True
            continue
        if PROJECTED_REGION_END in ln:
            inside = False
            continue
        if not inside:
            out.append(ln)
    return out


def _is_utf8_text(path):
    """True when the file decodes as UTF-8 — i.e. it CAN carry a text citation.

    The R3 scope is the branch diff, and a real release branch carries BINARY
    deliverables inside it: ``packages/*.skill`` is a compiled archive rebuilt at
    release-cut, and this repository's own reconciliation hit one on the first
    production run. ``read_text(encoding="utf-8")`` raises on it, and the raise
    lands OUTSIDE the R4/R5/R6 ``revert()`` path — under ``--apply`` it fires
    after R2 has already renamed the record, leaving a half-applied tree the tool
    cannot undo and did not report. A binary cannot hold an ``ADR-NNN`` citation,
    so it is dropped from the scope; the drop is LOGGED rather than silent,
    because a scope that shrinks without saying so is the same
    answer-over-the-wrong-population defect this tool exists to fix.
    """
    try:
        path.read_text(encoding="utf-8")
        return True
    except (UnicodeDecodeError, OSError):
        return False


def _in_scope_files(ref, root, extra_paths, log=None, exclude_paths=None):
    """The branch's own citation set: files added/modified vs the mainline ref."""
    diff = git("diff", "--name-only", f"{ref}...HEAD", root=root, check=False)
    files = {ln for ln in diff.splitlines() if ln}
    for pattern in extra_paths or []:
        for p in root.glob(pattern):
            if p.is_file():
                files.add(p.relative_to(root).as_posix())
    dropped = []
    for pattern in exclude_paths or []:
        matched = {pattern} & files
        matched |= {p.relative_to(root).as_posix() for p in root.glob(pattern)
                    if p.is_file()} & files
        if not matched:
            # A pattern that matches nothing is a typo, and a typo here silently
            # re-widens the scope the operator meant to narrow. Say so.
            (log or (lambda _m: None))(
                f"R3 scope: --exclude-path {pattern!r} matched NO in-scope file "
                f"(pattern ignored — check it)")
        files -= matched
        dropped.extend(sorted(matched))
    if dropped and log:
        log(f"R3 scope: {len(dropped)} file(s) EXCLUDED by --exclude-path "
            f"(hand-verified as citing another record's claim on the old "
            f"number): " + ", ".join(dropped))
    present = sorted(f for f in files if (root / f).is_file())
    text, binary = [], []
    for f in present:
        (text if _is_utf8_text(root / f) else binary).append(f)
    if binary and log:
        log(f"R3 scope: {len(binary)} non-UTF-8 file(s) dropped — a binary cannot "
            f"carry a citation: " + ", ".join(binary))
    return text


def _index_files(root):
    """HAND-MAINTAINED index surfaces the tool rewrites outside the branch diff.

    ``PROJECTED_INDEXES`` is excluded: a projected surface is regenerated, never
    rewritten. See the R4 block for why the split is load-bearing.
    """
    return [d + "/README.md" for d in ADR_DIRS
            if (root / d / "README.md").is_file()
            and d + "/README.md" not in PROJECTED_INDEXES]


def _project_index(root, rel):
    """Regenerate a projected index surface. Returns (ok, changed, message).

    The projector is IMPORTED, never re-implemented — the same no-second-parser
    rule this file already applies to the number space. It reads the ADR file set,
    which R2 has already renamed, so the moved row falls out of the projection
    rather than being rewritten by hand.

    ``ok`` is returned explicitly rather than inferred from the message: a caller
    that sniffs a string for failure is one reworded message away from treating a
    refusal as a success, and R4's failure path reverts the whole staged set.
    """
    path = TOOL_DIR / PROJECTED_INDEXES[rel]
    spec = importlib.util.spec_from_file_location("generate_adr_index", path)
    if spec is None or spec.loader is None:  # pragma: no cover - defensive
        return False, False, f"cannot load the index projector from {path}"
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    before = (root / rel).read_text(encoding="utf-8")
    lines = []
    try:
        rc = module.do_write(str(root), lines.append)
    except module.IndexError_ as exc:
        return False, False, f"the projector refused: {exc}"
    if rc != 0:
        return False, False, "the projector exited %d: %s" % (rc, "; ".join(lines))
    return True, (root / rel).read_text(encoding="utf-8") != before, "; ".join(lines)


def do_renumber(old, new, ref, root, apply_changes, extra_paths, log,
                exclude_paths=None):
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
    #
    # It is asked as a DELTA. `evaluate()` grades a whole number space, but one
    # invocation performs ONE move; at N>=2 outstanding claims the two are
    # incompatible, because no single move can make the whole union clean while
    # the others stand. So evaluate() runs on BOTH sides of this move and the
    # move is refused only if it INTRODUCES a problem, or fails to advance.
    current = {n: set(p) for n, p in mainline.items()}
    for n, paths in worktree.items():
        current.setdefault(n, set()).update(paths)
    old_rel_sim, new_rel_sim = _rel(root, old_path), _rel(root, new_path)

    def _union(applied):
        """The union with this move applied (True) or backed out (False)."""
        u = {n: set(v) for n, v in current.items()}
        (gone_n, gone), (here_n, here) = (
            ((old, old_rel_sim), (new, new_rel_sim)) if applied
            else ((new, new_rel_sim), (old, old_rel_sim))
        )
        if gone_n in u:
            u[gone_n].discard(gone)
            if not u[gone_n]:
                del u[gone_n]
        u.setdefault(here_n, set()).add(here)
        return u

    before_union, after_union = _union(False), _union(True)
    before = evaluate({n: sorted(v) for n, v in before_union.items()}, [])
    after = evaluate({n: sorted(v) for n, v in after_union.items()}, [])
    introduced = _problem_keys(after) - _problem_keys(before)
    if introduced:
        log(f"R1 REFUSE: moving ADR-{old:03d} → ADR-{new:03d} INTRODUCES a "
            f"violation that {ref} ∪ this tree does not already carry:")
        for p in after:
            if _problem_keys([p]) & introduced:
                log("    " + p)
        return 2
    if _residual(after_union) >= _residual(before_union):
        log(f"R1 REFUSE: moving ADR-{old:03d} → ADR-{new:03d} introduces no new "
            f"violation but does not advance the reconciliation "
            f"(residual {_residual(before_union)} → {_residual(after_union)}).")
        return 2
    if before:
        log(f"R1 outstanding: {len(before)} violation(s) stand before this move; "
            f"{len(after)} after. This move is one step of the assignment, not "
            f"the whole of it.")

    cause = (CAUSE_DUPLICATE if old in mainline else CAUSE_GAP).format(old=old)
    log(f"R1 PROCEED: ADR-{old:03d} → ADR-{new:03d} ({old_path} → {new_path})")
    log(f"    anchor({ref}) = {_a}; cause = {cause}")

    in_scope = _in_scope_files(ref, root, extra_paths, log, exclude_paths)

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
    # TWO surfaces, TWO mechanisms, and the split is the whole point.
    #
    #   core/ADRs/README.md     HAND-MAINTAINED — a curated thematic document, not
    #                           an index. Rewritten in place, as before, and it is
    #                           the sole carrier of the § Renumber log.
    #   release/ADRs/README.md  DERIVED (ADR-113). Its table is projected from the
    #                           ADR file set by generate-adr-index.py. Rewriting a
    #                           row here by hand is precisely what the Derived-
    #                           Surface Contract's verification posture FAILS — a
    #                           renumber would then break the projection check it
    #                           had just triggered. So R4 INVOKES the projector.
    #                           R2 has already renamed the file, so the moved row
    #                           falls out of the projection; nothing is rewritten.
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

    for rel in sorted(PROJECTED_INDEXES):
        if not (root / rel).is_file():
            continue
        # In-scope prose OUTSIDE the managed region still needs the citation sweep;
        # the projector then owns the region itself. Order matters: sweep, project.
        target = root / rel
        if rel in in_scope:
            body, n = rewrite_citations(target.read_text(encoding="utf-8"), old, new)
            if n:
                target.write_text(body, encoding="utf-8")
                touched.add(rel)
        ok, changed, message = _project_index(root, rel)
        if not ok:
            return revert(f"{rel} is a projected surface and could not be "
                          f"regenerated — {message}")
        if changed:
            touched.add(rel)
        log(f"R4 index: {rel} regenerated by "
            f"{PROJECTED_INDEXES[rel]} ({message or 'no row moved'})")

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
        # creates. Scanning them would make R5 and R4 fail R6. A projected
        # region names it on purpose too, for a different reason: it is derived
        # from the file set, so its ADR-<old> row belongs to whichever record
        # still holds <old> — see `_strip_projected_region`.
        lines = p.read_text(encoding="utf-8").split("\n")
        if rel in PROJECTED_INDEXES:
            lines = _strip_projected_region(lines)
        body = "\n".join(ln for ln in lines
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
    #
    # And it is the SAME DELTA R1 asked, for the same reason: R6 grades what
    # this move did, not whether the whole assignment has finished. Requiring a
    # clean union here would revert every move of a multi-claim reconciliation
    # AFTER performing it — R1's deadlock relocated to the verify step, which is
    # exactly what the multi-claim fixture caught. R6's question is "did the
    # move land as R1 predicted?": nothing new escaped, and the advance R1
    # promised actually happened on disk.
    post = worktree_claims(root)
    merged = {n: set(p) for n, p in mainline.items()}
    for n, paths in post.items():
        merged.setdefault(n, set()).update(paths)
    landed = evaluate({n: sorted(v) for n, v in merged.items()}, [])
    escaped = _problem_keys(landed) - _problem_keys(before)
    if escaped:
        return revert("the move introduced a violation the corpus did not "
                      "already carry: " + "; ".join(
                          p for p in landed if _problem_keys([p]) & escaped))
    if _residual(merged) >= _residual(before_union):
        return revert(
            "the move did not advance the reconciliation on disk "
            f"(residual {_residual(before_union)} → {_residual(merged)}); R1 "
            "predicted it would")

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
    # A PROJECTED region is derived from the file set, so a row naming the old
    # number belongs to whichever record still holds it — the MAINLINE's, at a
    # duplicate. R6 must not read inside the fence. Sensitivity control: the
    # SAME token outside the fence must survive the strip, or this would pass by
    # deleting everything.
    fenced = [
        "prose cites ADR-004 outside the fence",
        PROJECTED_REGION_BEGIN,
        "| [ADR-004](ADR-004-mainline.md) | derived row |",
        PROJECTED_REGION_END,
        "tail prose cites ADR-004 too",
    ]
    eq("projected/strip-region", _strip_projected_region(fenced),
       ["prose cites ADR-004 outside the fence", "tail prose cites ADR-004 too"])
    eq("projected/derived-row-is-not-dangling",
       bool(citation_re(4).search("\n".join(_strip_projected_region(
           [PROJECTED_REGION_BEGIN,
            "| [ADR-004](ADR-004-mainline.md) |",
            PROJECTED_REGION_END])))), False)
    eq("projected/authored-prose-still-scanned",
       bool(citation_re(4).search("\n".join(_strip_projected_region(fenced)))), True)
    # An unfenced file must pass through untouched — the strip is region-scoped,
    # never a blanket filter.
    eq("projected/no-fence-is-a-no-op",
       _strip_projected_region(["a ADR-004", "b"]), ["a ADR-004", "b"])
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

    # ---- R1's delta predicate (the N>=2 deadlock) --------------------------
    # The union at a three-duplicate reconciliation, in the shape the live
    # release faces: the mainline holds 1..4, the branch holds different files
    # at 3 and 4 plus a claim at 5 the mainline does not have.
    dup3 = {1: ["m1"], 2: ["m2"], 3: ["m3", "b3"], 4: ["m4", "b4"], 5: ["b5"]}
    after_one = {1: ["m1"], 2: ["m2"], 3: ["m3"], 4: ["m4", "b4"], 5: ["b5"],
                 6: ["b3"]}
    # The OLD predicate's question — "is the post-move union clean?" — is still
    # answered NO here, and that is the point: the tool must proceed anyway.
    eq("delta/one-move-does-not-clean-the-union",
       bool(evaluate(after_one, [])), True)
    eq("delta/but-it-introduces-nothing",
       _problem_keys(evaluate(after_one, [])) - _problem_keys(evaluate(dup3, [])),
       set())
    eq("delta/and-it-advances", _residual(after_one) < _residual(dup3), True)
    # SPECIFICITY — a move that lands a gap IS refused, at the same N.
    to_the_moon = {1: ["m1"], 2: ["m2"], 3: ["m3"], 4: ["m4", "b4"], 5: ["b5"],
                   9: ["b3"]}
    eq("delta/a-new-gap-is-still-refused",
       ("GAP",) in (_problem_keys(evaluate(to_the_moon, []))
                    - _problem_keys(evaluate(dup3, []))), True)
    # A hole that MOVES up is progress, not a new problem — the downward-cascade
    # limb. Keying GAP per missing number would refuse this and re-deadlock.
    hole_low = {1: ["a"], 2: ["b"], 3: ["c"], 5: ["e"], 6: ["f"]}
    hole_high = {1: ["a"], 2: ["b"], 3: ["c"], 4: ["e"], 6: ["f"]}
    eq("delta/a-moved-hole-is-not-a-new-problem",
       _problem_keys(evaluate(hole_high, [])) - _problem_keys(evaluate(hole_low, [])),
       set())
    eq("delta/a-moved-hole-advances", _residual(hole_high) < _residual(hole_low),
       True)
    # ... and shuffling a record sideways without moving the hole does NOT.
    sideways = {1: ["a"], 2: ["b"], 3: ["c"], 5: ["e"], 7: ["f"]}
    eq("delta/a-sideways-shuffle-does-not-advance",
       _residual(sideways) >= _residual(hole_low), True)
    eq("residual/clean-is-zero", _residual({1: ["a"], 2: ["b"]}), (0, 0))
    eq("problem-keys/unknown-verdict-is-conservative",
       _problem_keys(["SOMETHING-NEW: a future rule"]),
       {("UNKNOWN", "SOMETHING-NEW: a future rule")})

    # ---- the minimal assignment (ADR-115's hold-fixed clause) --------------
    # Same shape as dup3: two true duplicates and one branch claim already
    # sitting on a mainline-free number. The free range is 5..7; the claim at 5
    # is HELD, so the duplicates take 6 and 7.
    minimal = assign_claims(4, [3, 4, 5], {1, 2, 3, 4})
    eq("assignment/minimal-plan", minimal,
       [(3, "DUPLICATE", 6), (4, "DUPLICATE", 7), (5, "BINDS", 5)])
    # The defect this replaced: handing out the free range from the bottom
    # targets 5 for claim 3 while claim 5 still holds it — a plan no ordering
    # can execute. No target may be a number another row still occupies.
    _unmoved = {n for n, v, t in minimal if v == "BINDS"}
    eq("assignment/no-target-collides-with-an-unmoved-claim",
       {t for n, v, t in minimal if v != "BINDS"} & _unmoved, set())
    eq("assignment/plan-is-minimal (one move per true collision)",
       sum(1 for n, v, t in minimal if v != "BINDS"), 2)
    # SPECIFICITY — a claim ABOVE the free range is not "already where it
    # belongs"; it must still move DOWN, or it lands the gap beneath it.
    eq("assignment/a-claim-above-the-free-range-still-moves",
       assign_claims(4, [6], {1, 2, 3, 4}), [(6, "WOULD-GAP", 5)])
    eq("assignment/a-lone-claim-on-the-next-slot-binds",
       assign_claims(4, [5], {1, 2, 3, 4}), [(5, "BINDS", 5)])

    if failures:
        print("renumber-adr self-test: FAIL")
        for f in failures:
            print("  - " + f)
        return 1
    print("renumber-adr self-test: PASS (citation boundaries / path-exact / "
          "re-sort / provenance / R1 delta predicate / minimal assignment)")
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
    parser.add_argument("--exclude-path", action="append", default=[],
                        help="hand-verified glob REMOVED from the R3/R6 scope, for "
                             "a branch-diff file whose ADR-<old> tokens cite the "
                             "OTHER record holding that number (logged)")
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
        return do_renumber(old, new, ref, root, args.apply, args.extra_path,
                           print, args.exclude_path)

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

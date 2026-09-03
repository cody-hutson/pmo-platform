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
        Dry-run by default. ``--apply`` performs steps R1-R7 below.

    python3 release/tools/renumber-adr.py --self-test
        Pure-function fixtures (no git, no I/O). Exit 0 = clean.

THE SEVEN STEPS (each individually verifiable)
----------------------------------------------
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
                           had just triggered. See `PROJECTED_INDEXES` and ADR-117.
  R5  provenance note    — the ``## Status`` note. THE OBSERVED DEFECT.
  R6  zero-dangling verify — re-scan; any surviving in-scope ``ADR-<old>`` is a
                           failure, and the whole staged set is reverted.
  R7  package disclosure — NAME the ``packages/*.skill`` this run staled, plus
                           the rebuild command. R3 rewrites the SOURCES those
                           archives are built from, so a renumber that touches a
                           packaged skill's source leaves the package stale; the
                           tool used to leave that for `deploy.sh` Check 7 to
                           find later. It DISCLOSES and never rebuilds, runs
                           strictly OUTSIDE the ``revert()`` envelope, and
                           cannot change the exit code — see the R7 block.

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
# document, not an index, and R4 keeps rewriting it in place. See ADR-117.
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
#
# `Held ADR-<old> branch-local` — NOT `Authored branch-local as ADR-<old>`. A record
# may move TWICE in one release (see `provenance_head`), and on the second hop the
# `<old>` number is one the tool assigned, not one the author chose. "Held" is true
# on every hop; "authored as" is true only on the first.
PROVENANCE_TEMPLATE = (
    "{head} Held **ADR-{old:03d}** branch-local; renumbered to **ADR-{new:03d}** "
    "at merge time by `release/tools/renumber-adr.py`, because {cause}. "
    'In-release citations that read "ADR-{old:03d}" denote this record.'
)
CAUSE_DUPLICATE = "the mainline already claimed {old:03d}"
CAUSE_GAP = "the claim would have landed a gap beneath it on the mainline"

# SHAPE detector — matches a provenance note for ANY move. Its ONE legitimate use is
# the citation-sweep exemption (now `classify_lines`, via RECORD_OPENERS row 1):
# every provenance note records an old number on purpose, whichever move it
# describes, so the sweep must leave all of them alone. It is NOT a valid
# idempotence guard and NOT a valid verify — see `provenance_head`.
#
# DEMOTED, NOT RENAMED. Until ADR-177 this regex WAS the exemption; it is now one
# row of `RECORD_OPENERS`. The name, the pattern and the module-level binding are
# deliberately byte-unchanged: a sibling release re-targets the VERIFY side of this
# same symbol, and a silent rename would leave it re-targeting a predicate that
# moved. If this must ever be renamed, record the rename where that release can
# read it.
PROVENANCE_RE = re.compile(r"\*\*Numbering provenance — `\d{3} → \d{3}`\.\*\*")

RENUMBER_LOG_HEADING_RE = re.compile(r"^\*\*Renumber log\.\*\*", re.MULTILINE)
RENUMBER_LOG_SENTENCE_RE = re.compile(
    r"ADR-\d{3} \(`[^`]+`\) → \*\*ADR-\d{3}\*\* by `release/tools/renumber-adr\.py`"
)

# ---- the widened RECORD population (ADR-177) ------------------------------
#
# The exemption used to be keyed on TWO strings, both of which only this tool
# writes. Measured against the corpus at the introducing release's baseline: of
# 175 lines that RECORD an ADR number, that pair protected 60 — 34.3%. The 115
# unprotected lines were not edge cases; they included 5 of 5 tokens in ADR-103's
# own numbering-lineage block and 3 of 4 in ADR-121's, where the note's HEAD is
# protected and its hard-wrapped continuation lines are not.
#
# The rows below are the hand-authored shapes that census found. They are a
# REGISTRY on purpose: widening the population is adding a row, never editing a
# predicate body, and a registry keyed on region and position does not require
# predicting the next head string somebody writes by hand.

# Hand-authored provenance heads that PROVENANCE_RE's canonical shape misses —
# `**Numbering.**`, `**Number provenance:**`, `*First move, `098 → 101`.*`, and
# ADR-103's combined `098 → 101 → 103` lineage form. Keyed on the bare-number
# arrow pair, which is what every one of them carries.
PROVENANCE_FREEFORM_RE = re.compile(
    r"`?(?<!\d)\d{3}(?!\d)`?\s*→\s*`?(?<!\d)\d{3}(?!\d)`?"
)

# Hand-authored hop prose: `ADR-028 → ADR-099`, with or without bold on either
# side. Records a move; does not cite a record.
HOP_SENTENCE_RE = re.compile(
    r"(?:\*\*)?ADR-\d{1,3}(?:\*\*)?\s*→\s*(?:\*\*)?ADR-\d{1,3}"
)

# Author overrides. Escape hatches in BOTH directions, because a registry that can
# only be widened has no way to say "this one really is a citation".
RECORD_MARKER_RE = re.compile(r"<!--\s*adr-record\s*-->")
CITE_MARKER_RE = re.compile(r"<!--\s*adr-cite\s*-->")

# The Deviation Log heading, LOOSENED to tolerate a numeric or ordinal prefix.
# The tight form `^#{1,6}\s+Deviation Log\b` matched 64 of 69 heading-shaped lines
# in the release-plan corpus and missed `## 11. Stage 5 Deviation Log` — a genuine
# section heading defeated by its numeric prefix. A missed section classifies its
# rows CITE and sweeps them silently, which is the exact defect this registry
# exists to prevent. The trade is settled by the asymmetry: a false positive only
# makes a region NAMED, a miss REWRITES. Heading recognition is fence-aware (see
# `classify_lines`), so a `# ...` comment inside a fenced block is not a heading.
DEVIATION_LOG_HEADING_RE = re.compile(r"^#{1,6}\s.*\bDeviation Log\b")

# A bold-run heading — `**Renumber log.**` and its siblings. Has no `#` level, so
# it is treated as deeper than any markdown heading and ANY heading closes it.
BOLD_RUN_HEADING_RE = re.compile(r"^\*\*[^*]+\.\*\*")
BOLD_RUN_LEVEL = 7

MD_FENCE_RE = re.compile(r"^(?:```|~~~)")
MD_HEADING_RE = re.compile(r"^(#{1,6})\s")
# "carries an ADR token" for the AMBIGUOUS region rule. Deliberately number-blind:
# the region rule keys on POSITION and INTENT, never on which number is present.
ANY_ADR_TOKEN_RE = re.compile(r"(?<![0-9A-Za-z])ADR-\d{1,3}(?![0-9])")

# ── RECORD_OPENERS — the positive population. One row per class of prose that
#    RECORDS a number. `extent` says how far the verdict carries: `line` stops at
#    the opener, `paragraph` carries to the end of the markdown paragraph.
#
#    `paragraph` is granted ONLY to an opener that HEADS its paragraph. A note is
#    a paragraph and its head sits on that paragraph's first line, so a shape that
#    matches on a hard-wrapped CONTINUATION line heads no note and carries no
#    extent. Every row here is matched with `search`, not `match`, and the two
#    provenance rows key on a bare `NNN → NNN` pair that occurs in ordinary prose
#    — so without the position gate one incidental pair mid-sentence exempts the
#    REST of that paragraph, live citations included, and reports nothing. That is
#    the silent direction: no gate reads a bare `ADR-NNN` out of prose, so the
#    over-exemption is invisible to every instrument. Measured on the corpus at
#    this fix's baseline, ZERO of 149 pair matches begin their line — anchoring the
#    pattern would therefore have revoked the extent from all of them, which is why
#    the gate keys on paragraph position rather than on match offset.
RECORD_OPENERS = (
    ("provenance-note",          PROVENANCE_RE,            "paragraph"),
    ("provenance-note-freeform", PROVENANCE_FREEFORM_RE,   "paragraph"),
    ("renumber-log-sentence",    RENUMBER_LOG_SENTENCE_RE, "line"),
    ("hop-sentence",             HOP_SENTENCE_RE,          "line"),
    ("explicit-record-marker",   RECORD_MARKER_RE,         "paragraph"),
)

# ── AMBIGUOUS_SECTIONS — regions where a record and a citation are LEXICALLY
#    IDENTICAL, so the sweep must NAME rather than guess. Deliberately not
#    path-scoped: a Deviation Log records deviations wherever it appears, and
#    AMBIGUOUS is safe by construction.
AMBIGUOUS_SECTIONS = (
    ("deviation-log", DEVIATION_LOG_HEADING_RE),
    ("renumber-log",  RENUMBER_LOG_HEADING_RE),
)

RECORD, AMBIGUOUS, CITE = "RECORD", "AMBIGUOUS", "CITE"

# ---- the sub-line carve-out (DEV-36) --------------------------------------
#
# A verdict is per LINE, and a gate criterion is ONE physical table row. The
# G-EX9 row illustrates the multi-hop defect with a `110 → 114 → 118` token — which
# matches `PROVENANCE_FREEFORM_RE` — and, in the same row, carries a live markdown
# link to the record it cites. The row therefore RECORDS an illustrative hop and
# CITES a live cross-reference at once. One verdict per line cannot say both; it
# said RECORD, and a RECORD line is neither rewritten nor scanned, so the sweep
# stepped over a link whose target it had just renamed and R6 reported zero
# dangling. `check-doc-links.py` then failed the merge closed.
#
# DT-1 governed a verdict's EXTENT — how far it propagates down a paragraph. This
# governs its GRANULARITY, which no line-level verdict can express correctly,
# because the line genuinely is both.
#
# WHY A MARKDOWN LINK IS THE CARVE-OUT. A link is a USE by construction: it binds
# display text to a resolvable target, and resolvability is checkable. A record of
# a number the tree no longer holds has no reason to link to the file that number
# vacated — the target is gone, so the link is dangling the moment it is written.
# Prose, code spans and bare tokens carry no such guarantee, which is exactly why
# they stay under the line verdict.
#
# MEASURED BEFORE ADOPTION — the measurement chose the shape, and rejected the
# other candidate. Population: the 612 `ADR-NNN` tokens sitting on a RECORD-verdict
# line across the 1,858 UTF-8 tracked files, 210 of them inside a provenance note.
#   · link-span carve-out (adopted): reclassifies 4 of 612 (0.65%). ZERO of them
#     inside a provenance note; all four on the one defective row — two `ADR-170`
#     (the dangling pair) and two `ADR-115` (a live, correct link the same row was
#     hiding from the sweep for the same reason).
#   · opener-match span — "everything outside the RECORD_OPENERS match is a CITE
#     span", the literal sub-line reading: reclassifies 450 of 612 (73.5%),
#     including 210 of 210 provenance-note tokens. A provenance note's own
#     `Held **ADR-004** … renumbered to **ADR-005**` body sits OUTSIDE the
#     `**Numbering provenance — `004 → 005`.**` match, so that partition rewrites
#     every note in the corpus and revokes `provenance/sweep-exempts-every-hop`
#     outright. It is DT-1's `^`-anchor mistake again: an obvious-looking widening
#     whose real population is the exemption it was meant to preserve.
#
# SCOPED TO RECORD, DELIBERATELY. AMBIGUOUS keeps its contract whole — never
# rewritten, always named — because AMBIGUOUS means the two readings are LEXICALLY
# identical, and a carve-out that overrode it would decide the case the third
# verdict exists to refuse to decide. The Deviation Log row that records this very
# collision in prose is the live proof: it names the vacated path on purpose.
MD_INLINE_LINK_RE = re.compile(r"\[[^\]]*\]\([^)]*\)")

# A REGISTRY, on the same principle as `RECORD_OPENERS`: widening the carve-out is
# adding a row, never editing a predicate body.
CITE_CARVEOUTS = (
    ("markdown-inline-link", MD_INLINE_LINK_RE),
)


def _cite_carveout_spans(line):
    """The spans of ``line`` that are a CITE regardless of the line's verdict.

    Returned sorted and non-overlapping, because ``_sub_in_spans`` reconstructs
    the line by walking them once in order.
    """
    spans = []
    for _name, pattern in CITE_CARVEOUTS:
        spans.extend(m.span() for m in pattern.finditer(line))
    spans.sort()
    merged = []
    for a, b in spans:
        if merged and a <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], b))
        else:
            merged.append((a, b))
    return merged


def _sub_in_spans(pattern, repl, line, spans):
    """``pattern`` → ``repl``, applied ONLY inside ``spans``. Returns (text, n).

    An empty ``spans`` is the identity, byte for byte. That is what keeps this
    change inert on the 608 of 612 RECORD-line tokens the measurement says must
    not move: no carve-out, no rewrite, and the line is returned unchanged rather
    than round-tripped through a substitution that happened to match nothing.
    """
    if not spans:
        return line, 0
    out, n, cursor = [], 0, 0
    for a, b in spans:
        out.append(line[cursor:a])
        chunk, k = pattern.subn(repl, line[a:b])
        out.append(chunk)
        n += k
        cursor = b
    out.append(line[cursor:])
    return "".join(out), n


def _text_in_spans(line, spans):
    """The ``spans`` of ``line``, joined by a NEWLINE so no token spans a seam.

    Joining with the empty string would let the tail of one span and the head of
    the next compose a token that is in neither — a scan reading its own splice.
    """
    return "\n".join(line[a:b] for a, b in spans)

# ---- late-binding citations (ADR-177) -------------------------------------
#
# The VERSION has had a late-binding rule since ADR-092: the plan carries
# `{{RELEASE_VERSION}}` and the concrete number is compare-and-swap-claimed at the
# Stage-12 merge, so a concurrent release taking the slot costs nothing. ADR
# numbers had no equivalent: they were written literally at authorship and bound
# only at merge, so the number was committed to prose LONG BEFORE it was decided
# and every concurrent allocation forced a corpus-wide citation sweep.
#
# `{{ADR:<slug>}}` is the citation-side analogue. It carries no `ADR-\d` shape, so
# it is inert to every ADR-reading instrument, and it is SLUG-keyed rather than
# number-keyed because the slug already exists and is already relied on as
# renumber-stable (`rewrite_path_exact` depends on exactly that property).
#
# The FILENAME is deliberately NOT deferred. ADR-115 § Portability conflict
# falsified that: a compare-and-swap over a filename-plus-N-citations-plus-three-
# index-surfaces is not an object any host offers, and a token in a filename
# produced a malformed name under the contiguity checker. That evidence is
# accepted, not re-argued. Only the CITATIONS defer.
ADR_TOKEN_RE = re.compile(r"\{\{ADR:([A-Za-z0-9][A-Za-z0-9._-]*)\}\}")
# PROSE-ONLY, and enforced rather than documented. A token inside a link target is
# parsed as a path and reported as a broken cross-reference by the doc-link checks
# on every push BEFORE the stamp runs, so the constraint has to fail loudly here.
ADR_TOKEN_IN_LINK_RE = re.compile(r"\]\([^)\n]*\{\{ADR:")
ADR_TOKEN_IN_REFDEF_RE = re.compile(r"^\s*\[[^\]\n]+\]:\s*\S*\{\{ADR:")


def provenance_head(old, new):
    """The note's identifying head — the one substring that names THIS move.

    ``PROVENANCE_RE`` matches a provenance note by SHAPE: any ``NNN → NNN`` pair.
    That is correct for the sweep exemption and WRONG everywhere else, and the
    difference is not academic — it shipped a defect. A record that has already
    moved once this release carries a shape-matching note describing a DIFFERENT
    move, so a shape-keyed idempotence guard reports "already present" and writes
    nothing, and a shape-keyed verify then passes over its own gap. Observed in
    production on this tool's first release: ADR-110 → 114 → 118 wrote only the
    `110 → 114` note, the record never mentioned 118, and the § Renumber log
    asserted a note that was not there.

    So the two predicates are deliberately different and each has one job:

    ==========================  ==========================================
    ``PROVENANCE_RE`` (shape)   sweep exemption only — every provenance note
                                records an old number, whichever move it is
    ``provenance_head(o, n)``   idempotence guard + R6 verify — asks "is the
                                note for THIS move present?", the only
                                question either of them is actually asking
    ==========================  ==========================================

    Built from the same string the template interpolates, so the guard and the
    note it guards cannot disagree; ``self_test`` pins that with a prefix arm.
    """
    return f"**Numbering provenance — `{old:03d} → {new:03d}`.**"


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


def _record_opener(line):
    """The first RECORD_OPENERS row this line matches, or None.

    Returns ``(name, extent)``. Row order is precedence order.
    """
    for name, pattern, extent in RECORD_OPENERS:
        if pattern.search(line):
            return name, extent
    return None


def _is_paragraph_continuation(line):
    """True when ``line`` continues the markdown paragraph above it.

    STRUCTURAL, not heuristic: a paragraph continues while the line is non-blank
    AND does not open a new markdown block. The closed set of block openers is
    the one the extent rule declares — a heading, a table row, a bullet, a block
    quote, or a fence. Nothing else, because a wider set would silently END runs
    that are genuinely one paragraph, and a narrower one would let a run swallow
    the block after it.

    Its negative control is mandatory and lives in ``self_test``: break the
    paragraph with a blank line and the following line MUST revert to CITE. Without
    that arm, an extent rule is indistinguishable from a blanket exemption.
    """
    s = line.strip()
    if not s:
        return False
    if s.startswith("#") or s.startswith("|") or s.startswith(">"):
        return False
    if s.startswith("- ") or s.startswith("* "):
        return False
    if MD_FENCE_RE.match(s):
        return False
    return True


def _classify(text):
    """THE single exemption authority. Returns ``(verdicts, carveouts)``.

    Both public accessors — ``classify_lines`` and ``cite_carveouts`` — are thin
    readers of this ONE traversal. Splitting the carve-out into its own pass over
    the same rules would re-create the dry-run/apply divergence by construction,
    which is the defect this module was rebuilt to make impossible.

    Three verdicts, and the third one is the whole discrimination answer:

    ``RECORD``     the line RECORDS an old number. Never rewritten, never scanned.
    ``AMBIGUOUS``  a record and a citation are LEXICALLY IDENTICAL here, so the
                   tool cannot decide. Never rewritten — but NAMED, so a human
                   dispositions it. Naming is the reversible error; rewriting is
                   the irreversible one, and no gate catches either.
    ``CITE``       an ordinary citation. Swept.

    A boolean predicate is structurally forced to GUESS on a Deviation-Log row,
    because ``| DEV-42 | ADR-151 was renumbered after the sibling merge |`` and
    ``| DEV-43 | blocked on ADR-151 landing |`` differ in prose and not in shape.
    Widening RECORD to cover both stops sweeping the live citation; leaving RECORD
    narrow falsifies the historical one. The third verdict is the only shape that
    is wrong on neither.

    Verdict rules, in precedence order:

    ==== ====================================================== ============
    R-1  line carries ``<!-- adr-cite -->``                      ``CITE``
    R-2  line carries ``<!-- adr-record -->``                    ``RECORD``
    R-3  line matches a ``RECORD_OPENERS`` regex                 ``RECORD``
    R-4  line is a paragraph continuation of a ``paragraph``-
         extent R-3 opener THAT HEADS ITS PARAGRAPH              ``RECORD``
    R-5  line is inside an ``AMBIGUOUS_SECTIONS`` region AND
         carries an ADR token                                    ``AMBIGUOUS``
    R-6  otherwise                                               ``CITE``
    ==== ====================================================== ============

    R-1..R-6 decide the LINE. One further rule decides sub-line GRANULARITY, and
    it applies after the verdict rather than inside the precedence order, because
    it does not compete with the six above — it says which part of an already-
    RECORD line the verdict does not reach:

    ==== ====================================================== ============
    R-7  a ``CITE_CARVEOUTS`` span on a ``RECORD`` line, when
         that line is not inside a fence                        ``CITE`` span
    ==== ====================================================== ============

    R-7 is scoped to ``RECORD`` on purpose. ``AMBIGUOUS`` is the verdict that
    declines to decide between two LEXICALLY identical readings, so a carve-out
    that overrode it would decide exactly the case it exists to refuse. The fence
    guard matters for the same reason ``check-doc-links.py`` skips fenced blocks:
    a link inside a fence renders as literal text and resolves nothing, so
    rewriting it would edit an example — the USE-versus-MENTION error in
    miniature.

    EVERY consumer of the exemption calls this and only this. A second classifier
    in this module is the dry-run/apply divergence re-created by construction —
    which is precisely the defect that shipped when the reporting path counted raw
    matches while the rewrite path consulted a predicate.
    """
    lines = text.split("\n")
    verdicts = []
    fenced = []               # per-line fence state, read by R-7 after the loop
    in_fence = False
    record_run = False
    para_open = False         # the previous line left a paragraph body open
    amb_level = None          # markdown level of the open AMBIGUOUS region

    for line in lines:
        stripped = line.strip()

        # Recorded FIRST, before any branch, because every branch below
        # `continue`s. This is `in_fence` as it stands ENTERING the line, so a
        # fence delimiter is not itself fenced content — which is moot for the
        # carve-out (a delimiter is CITE either way) and correct for the reader.
        fenced.append(in_fence)

        # ---- paragraph position (DT-1) -----------------------------------
        # Computed BEFORE any verdict branch, because every branch below
        # `continue`s and each one must leave this correct for the next line.
        # `_is_paragraph_continuation` already encodes "plain paragraph body",
        # so a line is paragraph-INITIAL exactly when the line above it did not
        # leave a body open, or when it opens a block of its own.
        is_body = _is_paragraph_continuation(line)
        para_initial = not (para_open and is_body)
        para_open = is_body

        # A fence line is never a heading and never continues a paragraph.
        if MD_FENCE_RE.match(stripped):
            in_fence = not in_fence
            record_run = False
            verdicts.append(CITE)
            continue

        # ---- region state (fence-aware: a `# ...` comment inside a fenced
        # block is a comment, not a markdown heading) ----------------------
        if not in_fence:
            heading = MD_HEADING_RE.match(line)
            if heading:
                level = len(heading.group(1))
                if amb_level is not None and level <= amb_level:
                    amb_level = None
                for _name, opener in AMBIGUOUS_SECTIONS:
                    if opener.search(line):
                        amb_level = level
                        break
            elif BOLD_RUN_HEADING_RE.match(stripped):
                if amb_level == BOLD_RUN_LEVEL:
                    amb_level = None
                for _name, opener in AMBIGUOUS_SECTIONS:
                    if opener.search(line):
                        amb_level = BOLD_RUN_LEVEL
                        break

        # ---- verdict -----------------------------------------------------
        if CITE_MARKER_RE.search(line):
            record_run = False
            verdicts.append(CITE)
            continue

        opener = _record_opener(line)
        if opener is not None:
            if opener[1] == "paragraph":
                if para_initial:
                    record_run = True
                # ...and otherwise the shape matched MID-paragraph, where it
                # heads no note. It GRANTS no extent — but it must not REVOKE
                # one either, so a run already open carries through unchanged
                # (a hard-wrapped note line may itself carry a second pair).
            else:
                record_run = False
            verdicts.append(RECORD)
            continue

        if record_run and _is_paragraph_continuation(line):
            verdicts.append(RECORD)
            continue

        record_run = False
        if amb_level is not None and ANY_ADR_TOKEN_RE.search(line):
            verdicts.append(AMBIGUOUS)
            continue
        verdicts.append(CITE)

    # ---- R-7, the sub-line carve-out -------------------------------------
    # Derived from THIS traversal's own verdicts and fence state, so it cannot
    # disagree with them. Empty for every non-RECORD line, which is what makes
    # the carve-out impossible to misapply to AMBIGUOUS: there is nothing there
    # to apply.
    carveouts = [_cite_carveout_spans(ln) if (v == RECORD and not f) else []
                 for ln, v, f in zip(lines, verdicts, fenced)]
    return verdicts, carveouts


def classify_lines(text):
    """One verdict per line, from the single authority. See ``_classify``."""
    return _classify(text)[0]


def cite_carveouts(text):
    """Per line, the spans a ``RECORD`` verdict does NOT cover. See ``_classify``.

    The list is index-parallel to ``classify_lines(text)`` and empty on every
    non-``RECORD`` line. Consumers pair the two: the verdict says whether to
    sweep the line, this says which part of an exempt line is nonetheless live.
    """
    return _classify(text)[1]


def is_historical_numbering_line(line):
    """Single-line RECORD test. Delegates to ``classify_lines``; never a second
    predicate.

    Retained verbatim in name, arity and return type because the self-test's
    shape-keyed provenance arm pins it and that arm is CORRECT — it asserts the
    sweep exempts every hop of a double move, which is the audit trail the move
    creates. A ``paragraph`` extent evaluated on a single-line input is that line
    and no more, so the shim's answer is the pre-ADR-177 answer wherever the input
    is one line.
    """
    return classify_lines(line)[0] == RECORD


def rewrite_citations(text, old, new, preserve_historical=True):
    """Return (new_text, count, review) — every whole-token ADR-<old> → ADR-<new>.

    ``review`` is the AMBIGUOUS out-parameter: a list of ``(line_number, text)``
    for every site the classifier could not decide. Those lines are NOT rewritten
    and they are NOT silently dropped — the caller names them, because after
    ADR-177 the review report is the ONLY detector for a citation the sweep left
    behind. No gate reads a bare ``ADR-NNN`` out of prose: the ADR index checker
    globs filenames and never opens a file, and only PATH-bearing citations are
    covered by the doc-link checks.

    ``preserve_historical=False`` disables the exemption entirely (RECORD and
    AMBIGUOUS both fall through to a rewrite). It exists for callers that have
    already stripped the population themselves; nothing in the seven steps uses it.
    """
    pattern, repl = citation_re(old), f"ADR-{new:03d}"
    lines = text.split("\n")
    if preserve_historical:
        verdicts, carveouts = _classify(text)
    else:
        verdicts, carveouts = [CITE] * len(lines), [[] for _ in lines]
    out, count, review = [], 0, []
    for i, (line, verdict, carve) in enumerate(
            zip(lines, verdicts, carveouts), start=1):
        if verdict == RECORD:
            # R-7. The line is exempt EXCEPT its carve-out spans. With no
            # carve-out `_sub_in_spans` is the identity, so this is the
            # pre-DEV-36 branch byte for byte on all but 4 of the corpus's 612
            # RECORD-line tokens.
            rewritten, n = _sub_in_spans(pattern, repl, line, carve)
            out.append(rewritten)
            count += n
            continue
        if verdict == AMBIGUOUS:
            out.append(line)
            if pattern.search(line):
                review.append((i, line))
            continue
        rewritten, n = pattern.subn(repl, line)
        out.append(rewritten)
        count += n
    return "\n".join(out), count, review


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
    return PROVENANCE_TEMPLATE.format(
        head=provenance_head(old, new), old=old, new=new, cause=cause
    )


def insert_provenance(text, note, old, new):
    """Append the note as the last paragraph of the ``## Status`` section.

    Idempotent **on this move**: a record already carrying the note for THIS
    ``old → new`` pair is left alone, so re-running --apply on an already-
    renumbered tree is still a no-op. A record carrying a note for a DIFFERENT
    move — one that has already moved once this release — gets this hop appended
    beneath the earlier one, so the ``## Status`` section reads as a lineage.
    Keyed on ``provenance_head``, never on ``PROVENANCE_RE``: read that
    docstring for why the distinction is load-bearing rather than pedantic.
    """
    if provenance_head(old, new) in text:
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
# The seven steps
# --------------------------------------------------------------------------


def _log_review_block(log, sites):
    """Emit the ambiguous-site review block on EVERY path, including zero sites.

    Unconditional on purpose. After ADR-177 no gate reads a bare ``ADR-NNN`` out
    of prose, so this block is the ONLY detector for a live citation the sweep
    declined to rewrite. A step that is silent when it finds nothing is
    indistinguishable from a step that did not run — the same disclosure failure
    R7 exists to close, and the reason the zero-site line is not an omission.

    Output shape is load-bearing and is depended on by the regression suite: one
    summary line carrying ``R3 REVIEW:``, then one indented line per site ALSO
    carrying ``R3 REVIEW:`` together with its ``<path>:<line>``. So a zero-site run
    emits exactly one ``R3 REVIEW:`` line, and a site is greppable by its path.
    """
    log(f"R3 REVIEW: {len(sites)} ambiguous site(s) — named, never rewritten "
        f"(a record and a citation are lexically identical here)")
    for rel, lineno, text in sites:
        log(f"    R3 REVIEW: {rel}:{lineno}: {text.strip()}")
    if not sites:
        log("    (none — this block is emitted on every path, so silence here "
            "means zero sites and not a step that did not run)")


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
    """True when the file decodes as UTF-8 — i.e. R3 can sweep it IN PLACE.

    The R3 scope is the branch diff, and a real release branch carries BINARY
    deliverables inside it: ``packages/*.skill`` is a compiled archive rebuilt at
    release-cut, and this repository's own reconciliation hit one on the first
    production run. ``read_text(encoding="utf-8")`` raises on it, and the raise
    lands OUTSIDE the R4/R5/R6 ``revert()`` path — under ``--apply`` it fires
    after R2 has already renamed the record, leaving a half-applied tree the tool
    cannot undo and did not report. That is why the drop happens at SCOPE time.

    WHY THE ARCHIVE IS DROPPED — AND WHY IT IS *NOT* "IT HOLDS NO CITATION"
    An archive holds citations in quantity: a whole-tree measurement found 509
    ``ADR-NNN`` occurrences sealed inside 47 of 55 ``packages/*.skill``. The
    reason to drop it is that those citations are DERIVED, not authoritative —
    the archive is rebuilt from the ``SKILL.md`` sources, which are UTF-8 and
    already in R3 scope, so a sweep of the sources regenerates them. Rewriting
    inside the zip would edit a build output that the next rebuild overwrites.

    The exclusion is therefore about PROVENANCE, not about content, and the
    distinction is load-bearing. Stated as an ENCODING limit — as though there
    were nothing in the archive to rewrite — the reason is simply false, and a
    contributor who checks it finds 509 counter-examples and "fixes" the gap by
    sweeping inside archives, the one repair that is certainly wrong. Stated as
    PROVENANCE it is true, and it points at the correct repair: sweep the source,
    then rebuild the package.

    The drop is LOGGED rather than silent, because a scope that shrinks without
    saying so is the same answer-over-the-wrong-population defect this tool
    exists to fix. R7 closes the other half: the sweep rewrites the SOURCES, so
    it stales the packages built from them, and R7 names them.
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
        log(f"R3 scope: {len(binary)} non-UTF-8 file(s) dropped — rebuild-derived "
            f"artifact(s); their citations regenerate from in-scope sources: "
            + ", ".join(binary))
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


# The reverse resolver R7 consults, INVOKED and never re-implemented — the same
# no-second-parser rule this file already applies to the number space and to the
# index projector. Its rule (b) is the load-bearing half: a TEMPLATE_SYNC_MAP
# canonical has no ``skills/`` path of its own, so a renumber that rewrites a
# citation in ``core/standards/template-protocol.md`` stales SIX packages while
# touching ZERO ``skills/`` paths. A resolver keyed on ``skills/`` paths alone
# returns EMPTY on exactly that input — a confident answer computed over the
# wrong population, which is the defect class this tool exists to eliminate.
PACKAGE_BUILDER = "core/deploy/tools/build-skill-packages.sh"


def _skills_for_paths(root, paths):
    """Reverse-resolve written paths to the skills whose packages they feed.

    Returns ``(skills, degraded_reason)``. Exactly one side is meaningful: on
    success ``degraded_reason`` is ``None``; on ANY failure ``skills`` is empty
    and the reason is a short operator-facing string.

    NEVER RAISES, BY CONTRACT — and that is not defensive habit, it is the
    property that lets R7 sit where it sits. R7 runs after R6 has passed and the
    tree is staged, so an exception escaping here would fail a renumber that has
    already verified, turning a fixed defect into a worse one. The query itself
    is read-only by construction (it never builds and never writes packages/),
    so calling it cannot mutate the tree either way.

    THE CATCH BELOW IS DELIBERATELY BROAD — do not narrow it back to the
    subprocess families. ``subprocess.run(..., text=True)`` DECODES the child's
    streams, so a child emitting non-UTF-8 bytes raises ``UnicodeDecodeError``,
    a ``ValueError`` that no subprocess-family clause covers; an enumerated
    catch makes the contract above conditional on the child's byte output,
    which is exactly what R7's placement is not allowed to depend on. Nothing
    is swallowed silently: every caught class is named in the degraded reason
    via ``type(exc).__name__`` and printed on the run's R7 line, and
    ``BaseException`` is deliberately NOT caught, so a KeyboardInterrupt during
    the subprocess still interrupts.
    """
    script = root / PACKAGE_BUILDER
    if not script.is_file():
        return [], f"{PACKAGE_BUILDER} is not present in this tree"
    try:
        proc = subprocess.run(
            ["bash", str(script), "--skills-for-paths"],
            input="\n".join(paths) + "\n",
            cwd=str(root), capture_output=True, text=True, timeout=120,
        )
    except Exception as exc:
        return [], f"{PACKAGE_BUILDER} could not be run ({type(exc).__name__})"
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout).strip().splitlines()
        return [], (f"{PACKAGE_BUILDER} exited {proc.returncode}"
                    + (f" — {tail[-1]}" if tail else ""))
    return [s for s in proc.stdout.split("\n") if s.strip()], None


def do_renumber(old, new, ref, root, apply_changes, extra_paths, log,
                exclude_paths=None):
    """Steps R1-R7. Returns 0 on success, non-zero on refusal or verify failure."""
    worktree = worktree_claims(root)
    _a, mainline_by_n = anchor(ref, root)
    mainline = {n: set(p) for n, p in mainline_by_n.items()}

    # ---- R1 refuse-or-proceed ------------------------------------------
    # COMPLETION MODE. <old> absent and <new> present means the rename already
    # happened — either this tool ran before (idempotent re-run) or somebody
    # performed it by hand. The hand case is the OBSERVED DEFECT: `409545d4`
    # renamed and fixed the index but never wrote the provenance note, leaving
    # ADR-088 unauditable to this day. Refusing here would leave the one
    # reliably-skipped step still skipped, so the tool completes R3-R7 instead.
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
            f"present — the rename already happened. Completing R3-R7.")
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
        # CALL SITE 3 — the reporting path, wired to the SAME authority the apply
        # path uses. Before ADR-177 this block counted `citation_re(old).findall`
        # raw: no exemption, no region handling, so it predicted rewriting the very
        # lines R3 correctly leaves alone and the rows R4's projector regenerates.
        #
        # Parity is STRUCTURAL, not asserted. The block calls `rewrite_citations`
        # and DISCARDS the returned text, so the dry run is the apply path minus
        # the write and a divergence is impossible without deleting a call.
        hits = exempt_total = 0
        review_all = []
        for rel in in_scope:
            lines = (root / rel).read_text(encoding="utf-8").split("\n")
            # The projected region is DERIVED, and R4 regenerates it from the
            # post-rename file set rather than sweeping it. R6 already mirrors
            # this strip before its own scan; the reporting path must mirror it
            # too, or it predicts an edit the tool will itself undo — the same
            # over-prediction class as counting an exempt record.
            if rel in PROJECTED_INDEXES:
                lines = _strip_projected_region(lines)
            body = "\n".join(lines)
            present = len(citation_re(old).findall(body))
            # THE MECHANISM LINE IS UNCONDITIONAL, and its placement above the
            # `present` guard is the whole point. A projected surface is reported
            # by MECHANISM, not by count: its region rows are derived, so they are
            # never a citation this sweep will rewrite. Nested under the guard it
            # went silent in exactly the case it exists to disclose — a surface
            # whose ONLY `ADR-<old>` tokens are region rows strips to zero, skips
            # the guard, and the reader is told nothing at all about a file that
            # visibly carries the old number. Same doctrine as `_log_review_block`:
            # a step that is silent when it finds nothing is indistinguishable from
            # a step that did not run.
            if rel in PROJECTED_INDEXES:
                log(f"    {rel} is regenerated by {PROJECTED_INDEXES[rel]}; its "
                    f"managed region is projected, not swept")
            if not present:
                continue
            _, would, review = rewrite_citations(body, old, new)
            amb_tokens = sum(len(citation_re(old).findall(ln)) for _, ln in review)
            exempt = present - would - amb_tokens
            hits += would
            exempt_total += exempt
            review_all.extend((rel, i, ln) for i, ln in review)
            # THREE counts, each named. A file reported `would rewrite 0` is
            # indistinguishable from a file with no citations at all; a file
            # reported `would rewrite 0 · exempt (record) 2` names the exemption.
            log(f"    would rewrite {would:>3} × ADR-{old:03d} in {rel}"
                f"  ·  exempt (record) {exempt}"
                f"  ·  REVIEW {len(review)}")
        _log_review_block(log, review_all)
        log(f"DRY-RUN: {hits} citation(s) would move; {exempt_total} exempt "
            f"(record); {len(review_all)} ambiguous site(s) for review.")
        # DISCLOSURE, not silence. The dry run enumerates R3 and nothing else, and
        # a reader who is not told that reads its output as the whole edit set.
        log("DRY-RUN enumerates R3 only (the citation sweep over the branch diff). "
            "NOT enumerated: R4 index rewrites outside the branch diff, table/list "
            "re-sorts, the § Renumber log append, the R5 provenance note, and R7 "
            "package staleness. The R2 rename is named above by R1 PROCEED. "
            "Re-run with --apply.")
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
    review_all = []
    for rel in in_scope:
        target = root / (new_rel if rel == old_rel else rel)
        if not target.is_file():
            continue
        body = target.read_text(encoding="utf-8")
        updated, n, review = rewrite_citations(body, old, new)
        review_all.extend((_rel(root, target), i, ln) for i, ln in review)
        if n:
            target.write_text(updated, encoding="utf-8")
            touched.add(_rel(root, target))
            swept += n
    log(f"R3 citation sweep: {swept} occurrence(s) rewritten across "
        f"{max(len(touched) - 1, 0)} file(s)")
    _log_review_block(log, review_all)

    # ---- R4 index surfaces ----------------------------------------------
    # TWO surfaces, TWO mechanisms, and the split is the whole point.
    #
    #   core/ADRs/README.md     HAND-MAINTAINED — a curated thematic document, not
    #                           an index. Rewritten in place, as before, and it is
    #                           the sole carrier of the § Renumber log.
    #   release/ADRs/README.md  DERIVED (ADR-117). Its table is projected from the
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
            body, _, _ = rewrite_citations(body, old, new)
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
            body, n, _ = rewrite_citations(target.read_text(encoding="utf-8"),
                                           old, new)
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
    body, state = insert_provenance(
        body, provenance_note(old, new, cause), old, new)
    if state == "written":
        new_path.write_text(body, encoding="utf-8")
        log(f"R5 provenance: ## Status note written ({old:03d} → {new:03d})")
    elif state == "already-present":
        log(f"R5 provenance: the note for THIS move ({old:03d} → {new:03d}) is "
            "already present (idempotent re-run)")
    else:
        return revert(f"{new_rel} has no '## Status' section to carry the "
                      "numbering-provenance note")

    # ---- R6 zero-dangling verify ----------------------------------------
    # CALL SITE 2 — the same authority, consumed as a three-valued verdict.
    dangling = []
    r6_review = []
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
        #
        # AMBIGUOUS is excluded for a THIRD reason, and it is a real trade stated
        # rather than hidden: R3 deliberately did not rewrite those lines, so
        # scanning them here would revert a CORRECT move on every ambiguous site.
        # The cost is that R6 correspondingly can no longer detect a genuinely
        # stale citation there — which is exactly why the review block above is
        # unconditional and why the Stage-12 procedure carries the obligation to
        # disposition each named site.
        lines = p.read_text(encoding="utf-8").split("\n")
        if rel in PROJECTED_INDEXES:
            lines = _strip_projected_region(lines)
        verdicts, carveouts = _classify("\n".join(lines))
        scanned = []
        for i, (ln, verdict, carve) in enumerate(
                zip(lines, verdicts, carveouts), start=1):
            if verdict == RECORD:
                # R-7. "Never scanned" used to be unconditional, and that is
                # how a dangling link on a RECORD line reached the mainline
                # under a green zero-dangling verdict. The exempt part of the
                # line is still not scanned; its carve-out spans are, because
                # a link the rename just invalidated is a defect R6 exists to
                # find. No carve-out contributes nothing, exactly as before.
                if carve:
                    scanned.append(_text_in_spans(ln, carve))
                continue
            if verdict == AMBIGUOUS:
                if citation_re(old).search(ln):
                    r6_review.append((_rel(root, p), i, ln))
                continue
            scanned.append(ln)
        if citation_re(old).search("\n".join(scanned)):
            dangling.append(_rel(root, p))
    if r6_review:
        log(f"R6 REVIEW: {len(r6_review)} ambiguous site(s) still name "
            f"ADR-{old:03d} and were EXCLUDED from the dangling scan — "
            f"disposition each one:")
        for rel, lineno, text in r6_review:
            log(f"    R6 REVIEW: {rel}:{lineno}: {text.strip()}")
    if dangling:
        return revert(f"{len(dangling)} in-scope file(s) still cite ADR-{old:03d}: "
                      + ", ".join(dangling))
    # Assert the note for THIS move, not the SHAPE of a note. A shape assertion
    # here verifies on the same predicate that decides whether to write, so R5's
    # suppression and R6's confirmation are the same mistake made twice — which
    # is exactly how the `114 → 118` hop shipped a record that never mentioned
    # its own number under a § Renumber log claiming otherwise.
    if provenance_head(old, new) not in new_path.read_text(encoding="utf-8"):
        return revert(f"the ## Status numbering-provenance note for this move "
                      f"(`{old:03d} → {new:03d}`) is absent")
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

    # ---- R7 package-staleness disclosure --------------------------------
    # STRICTLY AFTER ALL MUTATION, AND DELIBERATELY OUTSIDE THE revert() ENVELOPE.
    #
    # `packages/*.skill` is dropped from the R3 scope as a rebuild-derived
    # artifact (see `_is_utf8_text`), and that is the right call. But the sweep
    # rewrites the SOURCES those archives are built from, so a renumber that
    # touches a packaged skill's source leaves the package stale — and until R7
    # the tool neither rebuilt it nor said so. The staleness surfaced at the next
    # `deploy.sh --check` (Check 7), i.e. at a drift detector, not at the sibling
    # tool that knowingly created the drift.
    #
    # THIS STEP DISCLOSES; IT NEVER REBUILDS. Invoking the packager here would
    # put a fallible, NON-REVERTIBLE write after `git add -A`: `revert()` can
    # restore tracked paths and unlink a rename, but it has no mechanism to
    # unbuild a package. That reproduces the half-applied-tree shape recorded in
    # `_is_utf8_text` one step later, in a tool whose whole point is that it
    # never half-applies. Disclosure IS the fix, which is why R7 contributes
    # nothing to the exit code and why every arm below still falls through to
    # `return 0`.
    #
    # A line is emitted on EVERY path, including "none affected". A step that is
    # silent when it finds nothing is indistinguishable from a step that did not
    # run — the same disclosure failure this whole block exists to close.
    stale_skills, degraded = _skills_for_paths(root, sorted(touched))
    if degraded:
        log(f"R7 packages: UNDETERMINED — {degraded}. This run wrote: "
            + ", ".join(sorted(touched)))
        log("    if any of those feeds a .skill package, rebuild via "
            "core/deploy/tools/build-skill-packages.sh <skill> before the next "
            "deploy.sh --check")
    elif stale_skills:
        log(f"R7 packages: {len(stale_skills)} stale package(s) owed a rebuild — "
            + ", ".join(f"packages/{s}.skill" for s in stale_skills))
        log("    rebuild via core/deploy/tools/build-skill-packages.sh "
            + " ".join(stale_skills))
    else:
        log("R7 packages: none affected")
    return 0


# --------------------------------------------------------------------------
# --stamp — resolve {{ADR:<slug>}} at the claim (ADR-177)
# --------------------------------------------------------------------------


def adr_slug_index(root):
    """slug -> [numbers], across BOTH ADR directories (one global number space).

    Built from the ON-DISK file set, which is what makes the branch-scoping
    property fall out by construction: a slug resolves to a file IN THIS TREE, so
    a stamp can never reach whichever OTHER record holds a number on the mainline.
    That is the property ADR-115 § Decision (2) protects, and it is the reason a
    whole-file `--exclude-path` was needed the last time a sweep resolved
    corpus-wide.
    """
    by_slug = {}
    for d in ADR_DIRS:
        directory = root / d
        if not directory.is_dir():
            continue
        for path in sorted(directory.glob("ADR-*.md")):
            m = re.match(r"^ADR-(\d+)-(.+)\.md$", path.name)
            if m:
                by_slug.setdefault(m.group(2), []).append(int(m.group(1)))
    return by_slug


def stamp_text(text, by_slug):
    """Return (new_text, count, refusals).

    ``refusals`` is a list of ``(line_number, slug_or_None, reason)``. A non-empty
    refusal list means the CALLER must not write: an unresolvable slug, an
    ambiguous one, and a token in link position are all states where guessing is
    worse than stopping, and the whole point of late binding is that stopping is
    free — nothing has been committed to prose yet.
    """
    lines = text.split("\n")
    out, count, refusals = [], 0, []
    for i, line in enumerate(lines, start=1):
        if ADR_TOKEN_IN_LINK_RE.search(line) or ADR_TOKEN_IN_REFDEF_RE.search(line):
            refusals.append((i, None, "token in link position (the token is "
                                      "prose-only; a link target is parsed as a "
                                      "path and reported as a broken cross-ref)"))
            out.append(line)
            continue
        rewritten = line
        for m in list(ADR_TOKEN_RE.finditer(line)):
            slug = m.group(1)
            numbers = sorted(set(by_slug.get(slug, [])))
            if not numbers:
                refusals.append((i, slug, "no ADR file on disk carries this slug"))
                continue
            if len(numbers) > 1:
                refusals.append((i, slug, "ambiguous — "
                                 + ", ".join(f"ADR-{n:03d}" for n in numbers)))
                continue
            rewritten = rewritten.replace(m.group(0), f"ADR-{numbers[0]:03d}")
            count += 1
        out.append(rewritten)
    if refusals:
        # ZERO MUTATION on refusal. Returning the original text (not the partially
        # rewritten one) is what makes "refuse" mean refuse rather than
        # "half-applied and reported".
        return text, 0, refusals
    return "\n".join(out), count, []


def do_stamp(ref, root, apply_changes, check_only, extra_paths, log,
             exclude_paths=None):
    """Resolve every `{{ADR:<slug>}}` in the branch diff. The LAST step of a claim.

    Ordering is load-bearing and belongs to the Stage-12 procedure:
    ``detect -> reconcile (if needed) -> stamp -> --stamp --check``. Because the
    number is written only AFTER it binds, a stamped citation cannot go stale and
    a mid-release renumber costs nothing — nothing carries a number yet.

    ``--check`` is the read-only gate limb: it asserts zero residual tokens and
    fails on a token in link position.
    """
    in_scope = _in_scope_files(ref, root, extra_paths, log, exclude_paths)
    by_slug = adr_slug_index(root)

    if check_only:
        residual, bad_links = [], []
        for rel in in_scope:
            for i, line in enumerate(
                    (root / rel).read_text(encoding="utf-8").split("\n"), start=1):
                if (ADR_TOKEN_IN_LINK_RE.search(line)
                        or ADR_TOKEN_IN_REFDEF_RE.search(line)):
                    bad_links.append((rel, i, line.strip()))
                for m in ADR_TOKEN_RE.finditer(line):
                    residual.append((rel, i, m.group(1)))
        for rel, i, line in bad_links:
            log(f"STAMP CHECK: {rel}:{i}: token in LINK POSITION — {line}")
        for rel, i, slug in residual:
            log(f"STAMP CHECK: {rel}:{i}: unresolved {{{{ADR:{slug}}}}}")
        # Emitted on every path, zero included — a silent check is
        # indistinguishable from a check that did not run.
        log(f"STAMP CHECK: {len(residual)} residual token(s), "
            f"{len(bad_links)} in link position, over {len(in_scope)} in-scope "
            f"file(s).")
        return 1 if (residual or bad_links) else 0

    # ---- resolve (dry run unless --apply) --------------------------------
    plan, refusals = [], []
    for rel in in_scope:
        body = (root / rel).read_text(encoding="utf-8")
        if not ADR_TOKEN_RE.search(body) and not ADR_TOKEN_IN_LINK_RE.search(body):
            continue
        updated, n, refused = stamp_text(body, by_slug)
        if refused:
            refusals.extend((rel, i, slug, why) for i, slug, why in refused)
            continue
        if n:
            plan.append((rel, updated, n))
    if refusals:
        for rel, i, slug, why in refusals:
            name = f"{{{{ADR:{slug}}}}}" if slug else "token"
            log(f"STAMP REFUSE: {rel}:{i}: {name} — {why}")
        log(f"STAMP REFUSE: {len(refusals)} unresolvable site(s); "
            f"NOTHING was written (zero mutation).")
        return 2
    total = sum(n for _, _, n in plan)
    if not apply_changes:
        for rel, _, n in plan:
            log(f"    would stamp {n:>3} token(s) in {rel}")
        log(f"STAMP DRY-RUN: {total} token(s) across {len(plan)} file(s) over "
            f"{len(in_scope)} in-scope file(s). Re-run with --apply.")
        return 0
    for rel, updated, n in plan:
        (root / rel).write_text(updated, encoding="utf-8")
        log(f"STAMP: {n:>3} token(s) resolved in {rel}")
    log(f"STAMP: {total} token(s) resolved across {len(plan)} file(s).")
    return 0


# --------------------------------------------------------------------------
# self-test (pure functions; no git, no filesystem)
# --------------------------------------------------------------------------


def self_test():
    failures = []

    def eq(label, got, want):
        if got != want:
            failures.append(f"[{label}] expected {want!r}, got {got!r}")

    # `rewrite_citations` returns (text, count, review) since ADR-177. The arms
    # below assert text-and-count exactly as they always did — `[:2]` keeps their
    # right-hand sides byte-unchanged rather than restating six expectations to
    # absorb a signature change. The review channel gets its own arms further down.
    def rc2(*a, **kw):
        return rewrite_citations(*a, **kw)[:2]

    # The right boundary is the load-bearing one: without it, renumbering
    # ADR-010 would corrupt ADR-100..ADR-109.
    eq("boundary/right", rc2("see ADR-104 and ADR-10.", 10, 11),
       ("see ADR-104 and ADR-011.", 1))
    eq("boundary/left", rc2("XADR-010 vs ADR-010", 10, 11),
       ("XADR-010 vs ADR-011", 1))
    eq("boundary/zero-pad", rc2("ADR-99 and ADR-099", 99, 100),
       ("ADR-100 and ADR-100", 2))
    # Specificity: a number nobody cited must move nothing.
    eq("boundary/specificity", rc2("ADR-104 ADR-010", 77, 78),
       ("ADR-104 ADR-010", 0))
    # Path-exact rewriting on a mainline-unchanged index: the bare number is
    # someone else's record and must NOT move; the slugged path is ours.
    eq("path-exact",
       rewrite_path_exact("| [ADR-004](ADR-004-bravo.md) | x |\nbare ADR-004\n",
                          4, 5, "bravo"),
       ("| [ADR-005](ADR-005-bravo.md) | x |\nbare ADR-004\n", 1))
    # A record of an old number is not a citation of it: the sweep must leave
    # the provenance note and the § Renumber log alone, or it erases its own
    # audit trail.
    #
    # WIDENED AT ADR-177, DELIBERATELY. Line 2 here is a hard-wrapped
    # CONTINUATION of the note's paragraph, and the pre-ADR-177 line-wise
    # exemption swept it — that is facet (a), the defect this arm's fixture
    # happens to be shaped like. It now correctly reports 0 rewrites. The
    # sensitivity guarantee this arm used to carry has NOT been dropped; it moved
    # to `exempt/broken-paragraph-reverts-to-cite` below, where a blank line ends
    # the paragraph and the following citation MUST still move. That is the
    # structurally correct home for it: a control inside the note's own paragraph
    # was asserting the bug.
    hist = ("**Numbering provenance — `004 → 005`.** was ADR-004.\n"
            "plain citation of ADR-004 here\n")
    eq("historical/exempt", rc2(hist, 4, 5), (hist, 0))
    logline = ("**Renumber log.** ADR-004 (`bravo`) → **ADR-005** by "
               "`release/tools/renumber-adr.py` at merge time.")
    eq("historical/renumber-log-exempt", rc2(logline, 4, 5),
       (logline, 0))

    # ---- ADR-177: the three-valued classifier over a region registry --------
    # Widening the population is adding a REGISTRY ROW, never editing a predicate
    # body — so these arms assert against rows and regions, not against a shape.

    # ONE authority, asserted BEHAVIOURALLY. `self_test` is pure functions with no
    # filesystem, so the structural limb (exactly one `def classify_lines`, the
    # dry-run block referencing it) is graded by the release's cross-issue probe
    # against the source file; what is gradeable here is that the shim cannot
    # disagree with the classifier on any input. A second predicate is precisely
    # what would make these two diverge.
    _agree = [
        "**Numbering provenance — `004 → 005`.** x",
        "**Renumber log.** ADR-004 (`b`) → **ADR-005** by "
        "`release/tools/renumber-adr.py`",
        "plain citation of ADR-004",
        "| DEV-1 | ADR-004 was renumbered |",
        "",
    ]
    eq("classify/shim-agrees-with-the-authority",
       [is_historical_numbering_line(ln) for ln in _agree],
       [classify_lines(ln)[0] == RECORD for ln in _agree])
    # ...and the shim is a RECORD test, so it must answer False on AMBIGUOUS —
    # never fold the third verdict back into a boolean's True side.
    eq("classify/shim-is-record-only",
       (classify_lines("## Deviation Log\n| DEV-1 | ADR-004 was renumbered |")[1],
        is_historical_numbering_line("| DEV-1 | ADR-004 was renumbered |")),
       (AMBIGUOUS, False))

    # facet (a) — a hard-wrapped continuation of a provenance note is a RECORD.
    wrapped = ("**Numbering provenance — `004 → 005`.** Held **ADR-004**\n"
               "branch-local; renumbered because the mainline already claimed\n"
               "ADR-004 and the record now denotes ADR-004 throughout.\n")
    eq("exempt/wrapped-continuation-is-record",
       rc2(wrapped, 4, 5), (wrapped, 0))
    # NEGATIVE CONTROL, and it is mandatory: break the paragraph with a blank line
    # and line 3 MUST revert to CITE. Without this arm the extent rule is
    # indistinguishable from a blanket exemption.
    broken = ("**Numbering provenance — `004 → 005`.** Held **ADR-004**\n"
              "branch-local; renumbered at merge time.\n"
              "\n"
              "A later paragraph cites ADR-004 for real.\n")
    eq("exempt/broken-paragraph-reverts-to-cite",
       rc2(broken, 4, 5),
       ("**Numbering provenance — `004 → 005`.** Held **ADR-004**\n"
        "branch-local; renumbered at merge time.\n"
        "\n"
        "A later paragraph cites ADR-005 for real.\n", 1))
    # A block opener ends the run too, not just a blank line.
    table_after = ("**Numbering provenance — `004 → 005`.** Held **ADR-004**.\n"
                   "| row | cites ADR-004 |\n")
    eq("exempt/block-opener-ends-the-run",
       rc2(table_after, 4, 5),
       ("**Numbering provenance — `004 → 005`.** Held **ADR-004**.\n"
        "| row | cites ADR-005 |\n", 1))

    # live-corpus regression — ADR-103's combined lineage head, which the
    # canonical shape regex does not match and which therefore had 5 of 5 tokens
    # unprotected before this change.
    eq("exempt/lineage-head-is-record",
       is_historical_numbering_line(
           "**Numbering.** This record moved `098 → 101 → 103`; ADR-098 was its "
           "branch-local number."),
       True)
    eq("exempt/hop-sentence-is-record",
       is_historical_numbering_line("ADR-028 → ADR-099 at merge time."), True)

    # DT-1 — a paragraph-extent shape that matches MID-paragraph heads no note,
    # so it must NOT exempt the rest of the paragraph. Reduced from the live
    # site: `core/ADRs/ADR-121...md:269` carries `120 → 121` inside a running
    # sentence, and the two `Relates to` citations below it were exempted and
    # NOT named — a coverage regression in the silent direction, which is the
    # direction § Decision (4) says the review block exists to catch.
    #
    # SENSITIVITY, and it fires: before the position gate this arm returned
    # `(mid_para, 0)` — the citation was left in place and reported nowhere.
    mid_para = ("Numbering derived per **ADR-115**, whose mainline-anchor\n"
                "rule is what makes the `004 → 005` advance rule-determined "
                "rather than discretionary. Relates to\n"
                "**ADR-004**, which established the registry this file "
                "embodies.\n")
    mid_swept = mid_para.replace("**ADR-004**", "**ADR-005**")
    eq("extent/mid-paragraph-shape-does-not-exempt-the-rest",
       rc2(mid_para, 4, 5), (mid_swept, 1))
    # ...and the verdict stream directly, so the arm cannot be satisfied by a
    # rewrite path that disagrees with the classifier.
    eq("extent/mid-paragraph-opener-carries-no-run",
       classify_lines(mid_para)[:3], [CITE, RECORD, CITE])
    # SPECIFICITY — the SAME shape at the head of its paragraph still carries
    # the extent to its hard-wrapped continuation. Without this limb the fix is
    # indistinguishable from deleting the freeform row, which would re-open the
    # 5-of-5 ADR-103 lineage gap the row was added to close.
    head_para = ("**Numbering.** This record moved `004 → 005`; the note runs\n"
                 "on and still denotes ADR-004 on this wrapped line.\n")
    eq("extent/paragraph-initial-shape-still-carries",
       rc2(head_para, 4, 5), (head_para, 0))
    # ...and the gate GRANTS no extent mid-paragraph but must not REVOKE one:
    # a note whose continuation line happens to carry a second pair keeps the
    # run open through it.
    second_pair = ("**Numbering provenance — `004 → 005`.** Held **ADR-004**\n"
                   "branch-local; the earlier `002 → 004` hop is recorded above\n"
                   "and this line still denotes ADR-004.\n")
    eq("extent/a-second-pair-mid-run-does-not-close-it",
       rc2(second_pair, 4, 5), (second_pair, 0))

    # ---- DEV-36: the MIXED line, where one verdict is not enough ------------
    #
    # The production shape, reduced: a gate-criteria table row that illustrates a
    # multi-hop defect with a bare `NNN → NNN` pair — so `PROVENANCE_FREEFORM_RE`
    # fires and the row is RECORD — and that ALSO carries a live markdown link to
    # the record the criterion cites. Pre-DEV-36 the row was neither rewritten nor
    # scanned, so the rename left a dangling link and R6 reported zero.
    #
    # These arms fail on the pre-DEV-36 build. Verified by running them against
    # it, not asserted: `carveout/mixed-line-link-is-swept` returns 0 where 2 is
    # required, and `carveout/note-keeps-its-own-numbers-but-not-its-link`
    # returns the input unchanged.
    mixed = ("| G-EX9 | a record that hopped twice (`110 → 114 → 118`) has "
             "vacated 114, so the limb arrives with "
             "[`ADR-004`](../ADRs/ADR-004-slug.md) instead. |")
    # The verdict does NOT change, and that is the point: the row really does
    # record a hop. An implementation that "fixed" this by demoting the line to
    # CITE would sweep the illustrative pair and fail HERE.
    eq("carveout/mixed-line-verdict-is-still-record",
       classify_lines(mixed)[0], RECORD)
    # SENSITIVITY — both tokens inside the link move: the display text and the
    # path. Two, not one; a rewrite that reached only the visible label would
    # leave the target dangling, which is the same defect wearing a fix.
    eq("carveout/mixed-line-link-is-swept",
       rc2(mixed, 4, 5),
       ("| G-EX9 | a record that hopped twice (`110 → 114 → 118`) has "
        "vacated 114, so the limb arrives with "
        "[`ADR-005`](../ADRs/ADR-005-slug.md) instead. |", 2))
    # SPECIFICITY — the illustrative hop pair is untouched. Stated as the whole
    # returned text above, so a carve-out that leaked into the prose fails.
    #
    # THE INVARIANT ARM. A provenance note that also links somewhere keeps every
    # number in its own prose — `Held **ADR-004**`, the quoted `"ADR-004"` — and
    # moves ONLY the link. This is the arm that rejects the other candidate
    # mechanism: partitioning on the RECORD_OPENERS match instead of on the link
    # puts all of this note's prose outside the record span, so it rewrites the
    # note and erases the audit trail the move exists to create. Measured over the
    # corpus, that mechanism reclassifies 210 of 210 provenance-note tokens.
    note_link = ('**Numbering provenance — `004 → 005`.** Held **ADR-004** '
                 'branch-local; see [`ADR-004`](../ADRs/ADR-004-slug.md). '
                 'In-release citations that read "ADR-004" denote this record.')
    eq("carveout/note-keeps-its-own-numbers-but-not-its-link",
       rc2(note_link, 4, 5),
       ('**Numbering provenance — `004 → 005`.** Held **ADR-004** '
        'branch-local; see [`ADR-005`](../ADRs/ADR-005-slug.md). '
        'In-release citations that read "ADR-004" denote this record.', 2))
    # SPECIFICITY — a RECORD line with NO link is inert under R-7, byte for byte.
    # Its control is the arm above: same shape, one link added, two rewrites.
    no_link = ("**Numbering provenance — `004 → 005`.** Held **ADR-004** "
               "branch-local; the path `ADR-004-slug.md` is named in prose only.")
    eq("carveout/record-line-without-a-link-is-inert",
       rc2(no_link, 4, 5), (no_link, 0))
    # FENCE GUARD — a link inside a fenced block renders as literal text and
    # resolves nothing, so it is an example, not a citation. `check-doc-links.py`
    # skips fenced blocks for the same reason. Its control is `mixed` above: the
    # identical link outside a fence moves.
    fenced_link = ("**Numbering provenance — `004 → 005`.** Held ADR-004.\n"
                   "\n"
                   "```\n"
                   "**Numbering.** `004 → 005` [`ADR-004`](../ADRs/ADR-004-s.md)\n"
                   "```\n")
    eq("carveout/fenced-link-is-not-a-carveout",
       rc2(fenced_link, 4, 5), (fenced_link, 0))
    # AMBIGUOUS IS UNTOUCHED. The third verdict declines to decide between two
    # lexically identical readings; a carve-out that overrode it would decide the
    # case it exists to refuse. The Deviation Log row recording THIS collision is
    # the live instance — it names a vacated path on purpose.
    amb_link = ("## Deviation Log\n"
                "\n"
                "| DEV-33 | lost the race to [`ADR-004`](../ADRs/ADR-004-s.md) |\n")
    amb_text, amb_n, amb_review = rewrite_citations(amb_link, 4, 5)
    eq("carveout/ambiguous-link-is-named-not-swept",
       (amb_text, amb_n, len(amb_review)), (amb_link, 0, 1))
    # STRUCTURE — the carve-out is index-parallel to the verdicts and EMPTY on
    # every non-RECORD line, which is what makes it impossible to misapply to
    # AMBIGUOUS: there is nothing there to apply. Non-vacuous, because the same
    # fixture's RECORD line carries one.
    struct_body = mixed + "\n" + amb_link
    struct_v = classify_lines(struct_body)
    struct_c = cite_carveouts(struct_body)
    eq("carveout/empty-on-every-non-record-line",
       (len(struct_v) == len(struct_c),
        all(c == [] for c, v in zip(struct_c, struct_v) if v != RECORD),
        any(c for c, v in zip(struct_c, struct_v) if v == RECORD)),
       (True, True, True))

    # facet (b) — a Deviation-Log row is AMBIGUOUS: not rewritten, and NAMED.
    devlog = ("## Deviation Log\n"
              "\n"
              "| DEV-42 | ADR-004 was renumbered after the sibling merge |\n"
              "| DEV-43 | blocked on ADR-004 landing |\n"
              "\n"
              "## Notes\n"
              "\n"
              "Closing prose cites ADR-004 once more.\n")
    dev_text, dev_n, dev_review = rewrite_citations(devlog, 4, 5)
    eq("exempt/devlog-row-is-ambiguous",
       [ln for ln in dev_text.split("\n") if ln.startswith("| DEV-42")],
       ["| DEV-42 | ADR-004 was renumbered after the sibling merge |"])
    eq("exempt/devlog-ambiguous-sites-are-named", len(dev_review), 2)
    # DISCRIMINATION — a live citation AFTER the section closes IS still swept.
    # Without this limb the change is indistinguishable from disabling the sweep
    # on release plans, and the region rule could be implemented as
    # open-and-never-close with every other arm still green.
    eq("exempt/devlog-live-citation-outside-section",
       ("Closing prose cites ADR-005 once more." in dev_text, dev_n), (True, 1))
    # The section CLOSE boundary, asserted on the verdict stream directly.
    eq("exempt/devlog-section-closes-at-next-heading",
       classify_lines(devlog)[-2:], [CITE, CITE])
    # DR-D / AI-007 — a numbered heading is still a section opener. The tight
    # form missed this shape and swept its rows silently.
    numbered = ("## 11. Stage 5 Deviation Log\n"
                "| DEV-9 | ADR-004 was renumbered |\n")
    eq("exempt/devlog-heading-variants-are-sections",
       classify_lines(numbered)[1], AMBIGUOUS)
    # ...and a `#` COMMENT inside a fenced block is not a heading, so it opens
    # no region. Fence-awareness is what keeps the loosened row from turning a
    # code comment into an unbounded exemption.
    fenced_comment = ("```\n"
                      "# ── Deviation Log ──\n"
                      "```\n"
                      "prose cites ADR-004\n")
    eq("exempt/fenced-comment-is-not-a-section",
       classify_lines(fenced_comment)[3], CITE)

    # facet (c) — the range case. A straddling range inside a Deviation Log is
    # left whole, so `ADR-005–004` (low end above high end) never forms.
    rng = ("## Deviation Log\n"
           "| DEV-43 | the block ADR-004–005 moved as a unit |\n")
    eq("exempt/incoherent-range-does-not-reproduce", rc2(rng, 4, 5), (rng, 0))

    # Author overrides, both directions.
    eq("exempt/marker-overrides-both-ways",
       (rc2("<!-- adr-record --> ADR-004 stays", 4, 5)[1],
        rc2("**Numbering provenance — `004 → 005`.** <!-- adr-cite --> ADR-004",
            4, 5)[1]),
       (0, 1))

    # DRY-RUN PARITY, as a property. The reporting path calls `rewrite_citations`
    # and discards the text, so over identical bytes the two counts are the same
    # number by construction — this arm fails only if a caller re-derives a count.
    #
    # THE FIXTURE CARRIES ALL THREE COLUMNS NON-ZERO, and that is load-bearing.
    # The `provenance-note` line below is what makes `exempt` non-zero; without
    # it the exempt limb of the partition is a zero whose control is also zero,
    # which is a broken probe rather than a passing arm.
    # The note CARRIES A LINK since DEV-36, and that is load-bearing for the same
    # reason the note itself is: without it the R-7 carve-out is a column of the
    # partition that no fixture exercises, and the partition would balance for a
    # vacuous reason. `dryrun/parity-exercises-the-carveout` below pins it.
    parity_record = ("**Numbering provenance — `004 → 005`.** Held **ADR-004** "
                     "branch-local before the sibling merge; see "
                     "[`ADR-004`](../ADRs/ADR-004-slug.md).\n")
    parity_body = devlog + "\n" + parity_record + "\nplain ADR-004 citation\n"
    _p_text, _p_would, _p_review = rewrite_citations(parity_body, 4, 5)
    _p_present = len(citation_re(4).findall(parity_body))
    _p_amb = sum(len(citation_re(4).findall(ln)) for _, ln in _p_review)
    # `exempt` is DERIVED FROM THE CLASSIFIER, not subtracted from the other two.
    # The reporting path computes it as `present - would - amb_tokens` (see CALL
    # SITE 3); reproducing that subtraction here would make the partition arm
    # `a + b + (c - a - b) == c` — true for every integer triple, inert under
    # every mutation, and unable to fail for the reason its own comment claims.
    # Reading the RECORD verdicts straight off `classify_lines` gives the third
    # term an independent source, so the equation below cross-checks FOUR
    # separately-derived numbers: `present` from a raw token scan, `would` and
    # `amb` from `rewrite_citations`, `exempt` from the exemption authority.
    _p_lines = parity_body.split("\n")
    _p_verdicts = classify_lines(parity_body)
    # SINCE DEV-36 the exempt term is "tokens on a RECORD line MINUS the tokens
    # in that line's carve-out spans". Reading RECORD verdicts alone would
    # double-count the carve-out — once here and once in `would` — and the
    # partition would fail for a reason that is an artefact of this derivation
    # rather than of the tool. The independence the arm needs is preserved: this
    # still reads the exemption authority directly and never subtracts from the
    # other two terms.
    _p_carve = cite_carveouts(parity_body)
    _p_exempt = sum(len(citation_re(4).findall(ln))
                    - len(citation_re(4).findall(_text_in_spans(ln, c)))
                    for ln, v, c in zip(_p_lines, _p_verdicts, _p_carve)
                    if v == RECORD)
    # NON-VACUITY for the carve-out column specifically. Two tokens: the link's
    # display text and its target.
    eq("dryrun/parity-exercises-the-carveout",
       sum(len(citation_re(4).findall(_text_in_spans(ln, c)))
           for ln, c in zip(_p_lines, _p_carve)), 2)
    # The three columns the dry run prints partition the tokens present, exactly.
    # A reporting path that re-derived any of them could not satisfy this.
    eq("dryrun/parity-partitions-the-tokens",
       _p_would + _p_amb + _p_exempt, _p_present)
    # NON-VACUITY — every column of that partition is exercised. Asserted as a
    # shape, not as the three values, so this arm neither entails the partition
    # nor is entailed by it: a later fixture edit that zeroes a column fails
    # HERE, loudly, instead of quietly degrading the partition into a two-term
    # sum that still balances.
    eq("dryrun/parity-partition-exercises-every-column",
       (_p_would > 0, _p_amb > 0, _p_exempt > 0), (True, True, True))
    # SPECIFICITY / FALSIFIABILITY CONTROL — the partition is a property of the
    # exemption authority, not an algebraic identity. Disable the exemption on
    # the SAME bytes and the same three terms no longer balance (`would` absorbs
    # the RECORD and AMBIGUOUS tokens while `exempt` still reports one), so the
    # arm above has a reachable configuration in which it is FALSE. Without this
    # limb, a partition arm that silently reverted to the subtracted form would
    # look exactly like a passing one.
    _np_text, _np_would, _np_review = rewrite_citations(
        parity_body, 4, 5, preserve_historical=False)
    _np_amb = sum(len(citation_re(4).findall(ln)) for _, ln in _np_review)
    eq("dryrun/parity-partition-is-falsifiable",
       _np_would + _np_amb + _p_exempt == _p_present, False)
    eq("dryrun/parity-would-equals-the-applied-count",
       _p_would, len(citation_re(4).findall(parity_body))
       - len(citation_re(4).findall(_p_text)))
    # V2 — the projected region must be stripped BEFORE counting, or the dry run
    # predicts rewriting rows R4's projector regenerates. `rewrite_citations`
    # alone does NOT close this: it has no region awareness.
    v2_body = "\n".join([
        "prose cites ADR-004 outside the fence",
        PROJECTED_REGION_BEGIN,
        "| ADR-004 | derived row |",
        "| ADR-004 | another derived row |",
        PROJECTED_REGION_END,
        "tail prose cites ADR-004 too",
    ])
    v2_stripped = "\n".join(_strip_projected_region(v2_body.split("\n")))
    eq("dryrun/region-excluded",
       (len(citation_re(4).findall(v2_body)),
        rewrite_citations(v2_body, 4, 5)[1],
        rewrite_citations(v2_stripped, 4, 5)[1]),
       (4, 4, 2))
    # SENSITIVITY — authored prose OUTSIDE the region is still counted, so the
    # strip is region-scoped and not a blanket suppressor.
    eq("dryrun/region-sensitivity",
       rewrite_citations(v2_stripped, 4, 5)[1], 2)
    # SPECIFICITY — an unfenced body is a no-op under the strip.
    eq("dryrun/region-specificity",
       _strip_projected_region(["a ADR-004", "b"]), ["a ADR-004", "b"])

    # ---- ADR-177: slug-keyed citation-token late binding -------------------
    #
    # THE FIXTURE TOKENS ARE BUILT AT RUNTIME, NOT WRITTEN AS LITERALS, and that
    # is not a style choice. `--stamp --check` is a GATE limb that scans the whole
    # branch diff, and the branch diff includes this file. A literal fixture token
    # in this source makes the tool flag ITSELF: measured, 10 residual tokens and
    # 1 "link position" refusal, all of them these arms, which would fail G-EX9 on
    # every release that touches this tool. Concatenating keeps the DECLARED scope
    # intact — the branch diff, unnarrowed — instead of carving source files out
    # of the scan, which would silently stop stamping a token in a test comment.
    def _tok(slug):
        return "{{" + "ADR:" + slug + "}}"

    slug_ix = {"bravo": [4], "charlie": [7], "twins": [11, 12]}
    eq("stamp/resolves-from-the-on-disk-slug",
       stamp_text("see %s and %s." % (_tok("bravo"), _tok("charlie")), slug_ix),
       ("see ADR-004 and ADR-007.", 2, []))
    # The token carries no `ADR-\d` shape, so the sweep is inert to it — which is
    # the whole reason a concurrent allocation costs nothing before the claim.
    eq("stamp/token-is-inert-to-the-sweep",
       rc2("see %s and ADR-004." % _tok("bravo"), 4, 5),
       ("see %s and ADR-005." % _tok("bravo"), 1))
    # REFUSE, with ZERO mutation — the returned text is the ORIGINAL, not a
    # half-applied one. Both refusal arms assert the text is unchanged.
    unknown = "see %s and %s." % (_tok("bravo"), _tok("nosuch"))
    got_text, got_n, got_ref = stamp_text(unknown, slug_ix)
    eq("stamp/refuses-an-unknown-slug-with-zero-mutation",
       (got_text, got_n, len(got_ref)), (unknown, 0, 1))
    ambiguous_src = "see %s." % _tok("twins")
    amb_text, amb_n, amb_ref = stamp_text(ambiguous_src, slug_ix)
    eq("stamp/refuses-an-ambiguous-slug-with-zero-mutation",
       (amb_text, amb_n, len(amb_ref)), (ambiguous_src, 0, 1))
    # PROSE-ONLY, enforced. A token in a link target would reach CI as a broken
    # cross-reference before the stamp ever runs.
    linked = "see [the record](/release/ADRs/%s.md)." % _tok("bravo")
    lk_text, lk_n, lk_ref = stamp_text(linked, slug_ix)
    eq("stamp/refuses-a-token-in-link-position",
       (lk_text, lk_n, len(lk_ref)), (linked, 0, 1))
    eq("stamp/refuses-a-reference-definition-token",
       stamp_text("[r]: /release/ADRs/%s.md" % _tok("bravo"), slug_ix)[2] != [],
       True)
    # CONTROL — the same slug in PROSE on the same instrument resolves cleanly,
    # so the refusal above is about link position and not about the token.
    eq("stamp/link-refusal-control-prose-resolves",
       stamp_text("see %s in prose." % _tok("bravo"), slug_ix),
       ("see ADR-004 in prose.", 1, []))
    # SPECIFICITY — a body with no token is a no-op that reports zero.
    eq("stamp/no-token-is-a-no-op",
       stamp_text("ordinary prose citing ADR-004.", slug_ix),
       ("ordinary prose citing ADR-004.", 0, []))
    # REFLEXIVE ARM — this source file must carry NO literal token, or the gate
    # limb flags the tool itself. Asserted as a property of the fixtures above
    # rather than by reading the file: every fixture routes through `_tok`, whose
    # output is assembled at runtime.
    eq("stamp/fixtures-are-assembled-not-literal",
       (ADR_TOKEN_RE.search(_tok("bravo")).group(1),
        bool(ADR_TOKEN_IN_LINK_RE.search("](%s)" % _tok("bravo"))),
        ADR_TOKEN_RE.search(_tok("bravo")).group(0) == _tok("bravo")),
       ("bravo", True, True))
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
    # PROVENANCE_RE IS PRESERVED AS A NAMED SYMBOL AND AS REGISTRY ROW 1, and both
    # halves are asserted rather than left to a comment. A sibling release
    # re-targets the VERIFY side of this same regex while ADR-177 widens the
    # sweep-exemption side, so a silent rename or a silent gutting would break it.
    #
    # The move-agnostic arm exists because the arms above are NOT sufficient on
    # their own: since the registry gained a freeform row that also matches the
    # bare-number arrow, narrowing PROVENANCE_RE to one hardcoded move left every
    # other provenance arm GREEN. Found by running the mutation, not by reading.
    eq("provenance/RE-is-preserved-as-registry-row-1",
       (RECORD_OPENERS[0][0], RECORD_OPENERS[0][1] is PROVENANCE_RE,
        RECORD_OPENERS[0][2]),
       ("provenance-note", True, "paragraph"))
    eq("provenance/RE-shape-detector-is-move-agnostic",
       (bool(PROVENANCE_RE.search(provenance_note(4, 5, "x"))),
        bool(PROVENANCE_RE.search(provenance_note(151, 157, "x")))),
       (True, True))
    # The guard is built from the string the template interpolates, so the two
    # cannot disagree. Pinned rather than assumed.
    eq("provenance/head-is-the-notes-prefix",
       note.startswith(provenance_head(4, 5)), True)
    body, wrote = insert_provenance(
        "## Status\n\nProposed.\n\n## Context\n\nx\n", note, 4, 5)
    eq("provenance/insert-once", wrote, "written")
    eq("provenance/idempotent-on-this-move",
       insert_provenance(body, note, 4, 5)[1], "already-present")
    eq("provenance/no-status-section",
       insert_provenance("# ADR\n\n## Context\n\nx\n", note, 4, 5)[1],
       "no-status-section")
    eq("provenance/section", body.index(note) < body.index("## Context"), True)

    # ---- THE DOUBLE MOVE (the case that shipped a defect) ------------------
    # A record may move twice inside one release: it is renumbered, a further
    # sibling merges, and the number it was just given is taken too. This arm
    # exists because that case had NO fixture, which is why nothing caught a
    # guard keyed on the note's shape instead of on the move.
    hop2 = provenance_note(5, 9, CAUSE_DUPLICATE.format(old=5))
    # SPECIFICITY / regression arm — the defect, pinned as a property rather than
    # as prose. The old shape predicate DOES match the first hop's note, so a
    # shape-keyed guard would report "already present" and write nothing; the
    # move-keyed guard correctly reports the second hop absent. If these two ever
    # agree again, the guard has silently reverted to matching shape.
    eq("provenance/shape-predicate-matches-the-WRONG-move",
       bool(PROVENANCE_RE.search(body)), True)
    eq("provenance/move-predicate-does-not",
       provenance_head(5, 9) in body, False)
    body2, wrote2 = insert_provenance(body, hop2, 5, 9)
    eq("provenance/second-hop-is-written", wrote2, "written")
    eq("provenance/both-hops-survive",
       (provenance_head(4, 5) in body2, provenance_head(5, 9) in body2), (True, True))
    # `find`, not `index`: a suppressed hop must fail this arm BY NAME, not by
    # raising out of the suite. A regression that crashes the self-test reports
    # "the tool is broken" where the truth is "this specific arm caught it".
    eq("provenance/lineage-is-chronological",
       0 <= body2.find(provenance_head(4, 5)) < body2.find(provenance_head(5, 9)),
       True)
    eq("provenance/second-hop-is-idempotent-too",
       insert_provenance(body2, hop2, 5, 9)[1], "already-present")
    # R6's verify predicate, both arms. The whole point of R6 is to catch a hop
    # R5 failed to write; on the shape predicate it could not, because the arm
    # below that must be False was True.
    eq("provenance/r6-fails-a-record-missing-this-hop",
       provenance_head(5, 9) in body, False)
    eq("provenance/r6-passes-the-complete-record",
       provenance_head(5, 9) in body2, True)
    # ...and the SWEEP still exempts BOTH hops — that arm is shape-keyed on
    # purpose, and narrowing it would erase the audit trail the move creates.
    eq("provenance/sweep-exempts-every-hop",
       [is_historical_numbering_line(ln) for ln in body2.split("\n")
        if "Numbering provenance" in ln], [True, True])

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
          "re-sort / provenance / R1 delta predicate / minimal assignment / "
          "three-valued classifier: shim-agreement + wrapped-continuation with "
          "its broken-paragraph and block-opener negative controls + "
          "paragraph-extent position gate with its mid-paragraph sensitivity "
          "arm and paragraph-initial specificity arm + "
          "lineage-and-hop heads + devlog-ambiguous with its "
          "outside-the-section discrimination limb and close-boundary arm + "
          "numbered-heading variant + fenced-comment-is-not-a-section + "
          "incoherent-range + author markers both ways / dry-run parity: "
          "token partition over independently-derived terms with its "
          "every-column non-vacuity arm and its exemption-disabled "
          "falsifiability control + applied-count identity + region-excluded "
          "with its sensitivity and specificity arms / stamp: resolve + "
          "refuse-unknown + "
          "refuse-ambiguous + link-position refusal with its prose control)")
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
    parser.add_argument("--stamp", action="store_true",
                        help="resolve {{ADR:<slug>}} citations from the on-disk "
                             "ADR file set — the LAST step of a Stage-12 claim")
    parser.add_argument("--check", action="store_true",
                        help="with --stamp: read-only. Assert zero residual "
                             "{{ADR: tokens; fail on a token in link position")
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

    if args.stamp:
        return do_stamp(ref, root, args.apply, args.check, args.extra_path,
                        print, args.exclude_path)

    if args.renumber:
        old, new = args.renumber
        return do_renumber(old, new, ref, root, args.apply, args.extra_path,
                           print, args.exclude_path)

    parser.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

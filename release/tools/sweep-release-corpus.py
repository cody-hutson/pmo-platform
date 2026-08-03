#!/usr/bin/env python3
"""sweep-release-corpus.py — records-management archival sweep for the
authoritative release record, `release/releases/RELEASE_LOG.md`.

WHAT IT DOES
    Relocates aged-out per-release execution narrative out of the RELEASE_LOG
    into same-directory archive segments keyed by major release family, so the
    hot working set stays inside a byte budget while every byte remains in the
    repository, greppable from the directory it always lived in.

    Disposition is a MOVE, never a destruction: every relocated block keeps its
    heading in the source ledger with a pointer to its segment. That is the
    presence-preserving shape RECORDS_POLICY.md Disposition Rules sanction, and
    it is what keeps the ledger's identifier surface intact — plan and note
    files declare `links.log_anchor` values that resolve to those headings, and
    in-corpus markdown anchors resolve to them as well.

ONE LEDGER, BY CONSTRUCTION
    RELEASE_LOG.md is the only release-corpus surface this tool touches.
    RELEASE_INDEX.md, RELEASE_DIGEST.md and CHANGELOG.md are projections emitted
    by generate_release_index.py from the LOG plus the release notes; a
    projection's volume is not an archival question and is governed by the
    projector. Their sole-copy custodial fields retain their own records
    disposition in RECORDS_POLICY.md and are out of THIS tool's scope, not out
    of records governance.

THE 8-COLUMN TABLE IS NEVER SPLIT
    Four consumers enumerate the LOG table by field position — the release-index
    projector, the corpus linter, the version-claim tool and the close-out. The
    table region is a small fraction of the file and splitting it would break
    all four for a negligible saving. Only `#### ` block bodies relocate.

WHICH BLOCKS ARE SWEPT, AND WHICH ARE NOT
    `#### Deployment Log <key>` blocks are swept: per-release execution
    narrative, read back by a single field accessor that this sweep keeps whole
    by following the content into the segments.

    `#### Release Learnings <key>` blocks are NEVER swept — heading AND body
    stay in the hot file at every window. They are a different record class: a
    machine-read learnings triple with a named consumer,
    produce-learnings-register.sh, which reads the BODY of the block for any
    version an operator names. That consumer degrades to a legitimate
    "no novel learning this release" sentinel when the body is absent, at exit
    zero and with its own loud guard silently skipped — a stub body is
    non-empty, so the guard's emptiness test passes. The register would then
    assert there were no learnings rather than that the learnings moved. A
    carve-out costs about two percent of the swept volume and removes that
    failure entirely.

    The general rule this encodes: the blast-radius question for a content
    relocation is "what reads INSIDE a block", never "what declares an anchor at
    it". An anchor records who points at content and breaks visibly; a body
    parser degrades silently, and a tolerant body parser degrades silently at
    exit zero.

ORDERING IS TAKEN FROM THE TABLE, NEVER FROM FILE POSITION
    The sweep archives oldest-first, and "oldest" means the LOG table's
    chronology — the table is date-ascending and is the authoritative release
    ordering. It is deliberately NOT the position of a block in the file.

    The file's `#### ` blocks are BROADLY newest-first, but not strictly: they
    are appended newest-first by convention, and the convention has slipped at
    least once, so reverse-file-order and table-chronology disagree in the
    interior. Either reading picks the same set at today's boundary, but a rule
    that depends on file position is a rule that a single mis-ordered append can
    silently change. `assert_ordering()` refuses the sweep if any swept block's
    key has no LOG table row, because such a block has no chronology at all.

THE BOUNDARY RULE IS BYTE-DENOMINATED, NOT COUNT-DENOMINATED
    Blocks are archived oldest-first until the hot file is at or under
    TARGET_BYTES. The number of releases retained is an OUTPUT of that rule and
    is never an input to it.

    Why this matters: per-release block size is not stationary. The newest
    blocks are materially larger than the oldest ones, so a fixed-count window
    cannot hold a byte budget — it drifts back over budget within a couple of
    releases and the budget has to be restated. A byte-denominated rule makes
    the budget hold by construction after every sweep.

IDEMPOTENCY
    A block is recognized as already-archived by the literal SENTINEL line in
    its body — a machine-greppable key, not an inferred property. A second run
    is a no-op. Asserted by --self-test, together with the negative control that
    an unswept block must still move.

VERIFICATION IS DESTINATION-SIDE
    Every named machine contract is satisfied by the retained stubs alone, so a
    truncated or empty segment would pass all of them. Conservation across the
    move is therefore asserted directly, by re-reading the segment FILE and
    comparing against the pre-sweep content read from git — never from a
    manifest this tool wrote about itself. A move is verified only when both
    ends are read.

USAGE
    sweep-release-corpus.py --plan                 # what would move; writes nothing
    sweep-release-corpus.py --apply                # perform the sweep
    sweep-release-corpus.py --verify [--baseline REF]
    sweep-release-corpus.py --self-test
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

# --------------------------------------------------------------------------
# Tunables — two figures, stated once, with their derivation
# --------------------------------------------------------------------------

# The budget. Sourced from the acceptance criterion for this work: the
# authoritative release record's hot working set is bounded at or under this
# figure. Nothing downstream restates it and nothing downstream encodes a
# retained-release count.
BUDGET_BYTES = 200_000

# Sweeping exactly to the budget satisfies it at the instant of the sweep and
# breaches it on the very next release, so the budget would only ever be true
# immediately after a chore run. The sweep therefore sweeps down to a floor
# below the budget. The headroom is denominated in bytes, like the budget, and
# is sized from the measured growth rate at the head of the file: recent
# releases add roughly seven kilobytes of Deployment-Log narrative each, so this
# is about six releases of headroom and the chore fires roughly that often.
# This is hysteresis, not a second budget — the budget is the only figure the
# acceptance criterion states, and the floor is derived from it.
HEADROOM_BYTES = 45_000
TARGET_BYTES = BUDGET_BYTES - HEADROOM_BYTES

REPO_ROOT = Path(__file__).resolve().parents[2]
LOG_REL = "release/releases/RELEASE_LOG.md"

# Heading classes. Exactly one is swept; the other is retained whole. This is a
# CLOSED set: a `#### ` heading that matches neither is a schema surprise and
# `assert_ordering()` refuses the sweep rather than guessing.
SWEEP_CLASS = "Deployment Log"
KEEP_CLASS = "Release Learnings"

# The stub's pointer line is ONE line doing three jobs: it is human-readable in
# the rendered ledger, it is a resolving markdown link to the segment, and its
# fixed ASCII prefix is the machine-greppable idempotency key.
SENTINEL_PREFIX = "_Archived: [segment]("


def sentinel(segment_name: str) -> str:
    return f"{SENTINEL_PREFIX}{segment_name})_"


def segment_from_sentinel(line: str) -> str:
    return line[len(SENTINEL_PREFIX):].rsplit(")_", 1)[0]


def heading_level(line: str) -> int | None:
    """ATX heading level, or None. Used to bound a block: a block ends at the
    next heading of the same level or higher (a lower `#` count)."""
    m = re.match(r"^(#{1,6}) ", line)
    return len(m.group(1)) if m else None


def family_of(key: str) -> str:
    """Segment key: the major release family, derivable from the version key
    with no date arithmetic. Version-less releases bucket together."""
    m = re.match(r"^v(\d+)\.", key)
    return f"v{m.group(1)}" if m else "version-less"


def norm(key: str) -> str:
    """The corpus spells a version-less release's key with a parenthetical
    suffix in some surfaces and without it in others. Normalize to the bare
    slug so the table and the headings agree on one key."""
    return key.replace(" (version-less)", "").strip()


def split_row(line: str) -> list[str]:
    """Cells of a markdown table row. `| a | b |` -> ['a','b']."""
    return [c.strip() for c in line.strip().strip("|").split("|")]


# --------------------------------------------------------------------------
# Ledger model
# --------------------------------------------------------------------------


@dataclass
class Block:
    cls: str
    key: str
    heading: str
    body: list[str] = field(default_factory=list)

    @property
    def archived(self) -> bool:
        return any(line.startswith(SENTINEL_PREFIX) for line in self.body)

    @property
    def sweepable(self) -> bool:
        return self.cls == SWEEP_CLASS


@dataclass
class Ledger:
    """An ORDER-PRESERVING sequence of literal lines and per-release blocks.

    Deliberately not modelled as head + blocks + tail: a head/tail model
    silently shunts everything after the first structural heading past the
    sweep — a defect that presents as a smaller diff rather than as an error.
    """

    path: Path
    items: list = field(default_factory=list)  # str | Block, in file order
    source: str = ""

    @property
    def blocks(self) -> list[Block]:
        return [i for i in self.items if isinstance(i, Block)]

    @property
    def segment_stem(self) -> str:
        return self.path.name[: -len(".md")] + "_ARCHIVE"

    def segment_name(self, fam: str) -> str:
        return f"{self.segment_stem}-{fam}.md"

    def segment_path(self, fam: str) -> Path:
        return self.path.parent / self.segment_name(fam)


def parse_items(lines: list[str], level: int, key_from) -> list:
    """Split `lines` into literal lines and Blocks at heading depth `level`.

    A block ends at the next heading of depth <= level, so a structural heading
    between two blocks stays a literal line and is never swallowed. Fenced code
    is skipped so a `#` inside a fence cannot open a phantom block.
    """
    items: list = []
    cur: Block | None = None
    fenced = False
    for line in lines:
        if line.lstrip().startswith("```"):
            fenced = not fenced
        if not fenced:
            lv = heading_level(line)
            if lv is not None and lv <= level:
                blk = key_from(line) if lv == level else None
                if blk is not None:
                    cur = blk
                    items.append(cur)
                    continue
                cur = None
                items.append(line)
                continue
        (cur.body if cur is not None else items).append(line)
    return items


_BLOCK_RE = re.compile(
    r"^#### (" + "|".join(re.escape(c) for c in (SWEEP_CLASS, KEEP_CLASS)) + r") (\S.*?)\s*$"
)
_ANY_H4_RE = re.compile(r"^#### ")


def load_log(text: str, path: Path) -> Ledger:
    def key_from(line: str) -> Block | None:
        m = _BLOCK_RE.match(line)
        if not m:
            return None
        return Block(cls=m.group(1), key=norm(m.group(2)), heading=line)

    return Ledger(path, parse_items(text.split("\n"), 4, key_from), source=text)


def release_order(log_text: str) -> list[str]:
    """Release keys in the LOG table's own order, oldest first.

    The table is date-ascending and is the authoritative chronology. This is the
    ONLY ordering the sweep consults; block position in the file is never used.
    """
    order: list[str] = []
    seen: set[str] = set()
    for line in log_text.split("\n"):
        if not line.startswith("| ") or line.startswith("| Version") or line.startswith("|---"):
            continue
        cells = split_row(line)
        if len(cells) < 8:
            continue
        k = norm(cells[0])
        if k and k not in seen:
            seen.add(k)
            order.append(k)
    return order


# --------------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------------


def stub_body(seg: str) -> list[str]:
    """The retained body of a swept block: a blank line, the pointer sentinel,
    a blank line. The heading itself is emitted by the caller and always stays.
    """
    return ["", sentinel(seg), ""]


SEGMENT_HEADER = """<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
# {title}

Archive segment of [`{parent}`]({parent}) — the **{fam}** release family.

This file is the same record as its parent ledger, relocated. It inherits its
parent's records class under `core/governance/RECORDS_POLICY.md`: a segment is a
disposition *destination*, never itself a disposition *source*. Nothing here is
a lesser record for having aged out of the working set, and nothing here is
eligible for a disposition its parent is not.

It lives in the same directory as its parent deliberately, so a recursive grep
over that directory still finds this content exactly as it did before the move.
Each block below retains its heading in the parent ledger, with a pointer here,
so every anchor into the parent still resolves.

Blocks are appended by `release/tools/sweep-release-corpus.py`. This file is
append-only and is never itself swept.

---
"""


def segment_title(stem: str, fam: str) -> str:
    return f"{stem}-{fam}"


# --------------------------------------------------------------------------
# The sweep
# --------------------------------------------------------------------------


@dataclass
class Corpus:
    log: Ledger
    order: list[str]


def read_corpus(root: Path) -> Corpus:
    log_p = root / LOG_REL
    log_text = log_p.read_text()
    return Corpus(log=load_log(log_text, log_p), order=release_order(log_text))


def assert_ordering(corpus: Corpus) -> list[str]:
    """Refuse the sweep on any condition that would make "oldest-first"
    undefined. Each finding names a block the tool would otherwise have to guess
    about."""
    findings: list[str] = []
    # The heading-class set is CLOSED. An `#### ` heading matching neither class
    # is a schema surprise: the tool has no rule for whether it may be swept, and
    # guessing is how a record class gets relocated by accident. Counting the raw
    # headings against the parsed blocks catches it without enumerating classes
    # the tool does not know about.
    fenced = False
    raw_h4 = 0
    for line in corpus.log.source.split("\n"):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if not fenced and _ANY_H4_RE.match(line):
            raw_h4 += 1
    if raw_h4 != len(corpus.log.blocks):
        findings.append(
            f"UNKNOWN-HEADING-CLASS: the ledger carries {raw_h4} `#### ` headings but only "
            f"{len(corpus.log.blocks)} parse as a known class ({SWEEP_CLASS} / {KEEP_CLASS}); "
            f"the sweep has no disposition rule for the remainder"
        )
    known = set(corpus.order)
    for b in corpus.log.blocks:
        if b.sweepable and b.key not in known:
            findings.append(
                f"NO-CHRONOLOGY: {b.heading!r} has no RELEASE_LOG table row, so it has no "
                f"position in the release chronology and cannot be ordered for archival"
            )
    seen: set[tuple[str, str]] = set()
    for b in corpus.log.blocks:
        if (b.cls, b.key) in seen:
            findings.append(f"DUPLICATE-BLOCK: {b.heading!r} appears more than once")
        seen.add((b.cls, b.key))
    return findings


def render(corpus: Corpus, archive: set[str]) -> tuple[str, dict[Path, list[str]]]:
    """Render the post-sweep hot ledger and the per-segment appendices."""
    out: list[str] = []
    segments: dict[Path, list[str]] = {}
    led = corpus.log

    for item in led.items:
        if isinstance(item, str):
            out.append(item)
            continue
        blk = item
        out.append(blk.heading)
        if blk.sweepable and blk.key in archive and not blk.archived:
            fam = family_of(blk.key)
            seg = led.segment_name(fam)
            out += stub_body(seg)
            sp = led.segment_path(fam)
            segments.setdefault(sp, []).append(blk.heading)
            segments[sp] += blk.body
        else:
            out += blk.body
    return "\n".join(out), segments


def hot_bytes(main: str) -> int:
    return len(main.encode())


def plan_sweep(corpus: Corpus, target: int) -> tuple[set[str], int, int]:
    """Archive oldest-first until the hot ledger is at or under `target`.

    Returns (archive_set, final_bytes, retained_block_count). The retained count
    is a RESULT of the loop, never a parameter to it.
    """
    archive: set[str] = set()
    main, _ = render(corpus, archive)
    size = hot_bytes(main)
    sweepable = {b.key for b in corpus.log.blocks if b.sweepable}
    for key in corpus.order:  # oldest first, from the table
        if size <= target:
            break
        if key not in sweepable:
            continue
        archive.add(key)
        main, _ = render(corpus, archive)
        size = hot_bytes(main)
    return archive, size, len(sweepable) - len(archive)


def write_out(root: Path, main: str, segments: dict[Path, list[str]]) -> None:
    (root / LOG_REL).write_text(main)
    for path, body in segments.items():
        stem, fam = path.name[: -len(".md")].split("-", 1)
        parent = stem.replace("_ARCHIVE", "") + ".md"
        header = SEGMENT_HEADER.format(title=segment_title(stem, fam), parent=parent, fam=fam)
        prior = path.read_text() if path.exists() else header
        if not prior.endswith("\n"):
            prior += "\n"
        path.write_text(prior + "\n".join(body).rstrip("\n") + "\n")


# --------------------------------------------------------------------------
# Destination-side verification
# --------------------------------------------------------------------------


def git_show(ref: str, rel: str) -> str:
    # Braced so the ref/path separator is never re-parsed by the shell.
    return subprocess.run(
        ["git", "-C", str(REPO_ROOT), "show", f"{ref}:{rel}"],
        capture_output=True, text=True, check=True,
    ).stdout


def verify(root: Path, baseline: str) -> tuple[bool, list[str]]:
    """Assert conservation across the move, at BOTH ends.

    For every block archived since `baseline`, every line of its pre-sweep body
    must be present in the segment FILE, read back from disk. An empty or
    truncated segment fails here and nowhere else.
    """
    findings: list[str] = []
    checked = 0
    p = root / LOG_REL
    before = load_log(git_show(baseline, LOG_REL), p)
    after = load_log(p.read_text(), p)
    after_by_heading: dict[str, Block] = {}
    for b in after.blocks:
        after_by_heading.setdefault(b.heading, b)
    seg_cache: dict[Path, str] = {}

    for b0 in before.blocks:
        b1 = after_by_heading.get(b0.heading)
        if b1 is None:
            findings.append(f"MISSING-HEADING: {b0.heading!r} vanished from the hot ledger")
            continue
        if b1.cls == KEEP_CLASS and b1.archived:
            findings.append(
                f"CARVE-OUT-VIOLATED: {b0.heading!r} is a {KEEP_CLASS} block and must never be swept"
            )
            continue
        if not b1.archived:
            if b1.body != b0.body:
                findings.append(f"UNSWEPT-BODY-CHANGED: {b0.heading!r} was not archived but its body differs")
            continue
        checked += 1
        mark = next(l for l in b1.body if l.startswith(SENTINEL_PREFIX))
        sp = p.parent / segment_from_sentinel(mark)
        if sp not in seg_cache:
            if not sp.exists():
                findings.append(
                    f"MISSING-SEGMENT: {b0.heading!r} points at {sp.name}, which does not exist"
                )
                continue
            seg_cache[sp] = sp.read_text()
        seg = seg_cache[sp]
        for line in b0.body:
            if not line.strip():
                continue
            if line not in seg:
                findings.append(
                    f"LOST-CONTENT: {b0.heading!r} — a body line is absent from {sp.name}: {line[:90]!r}"
                )
        if b0.heading not in seg:
            findings.append(f"SEGMENT-NO-HEADING: {sp.name} does not carry {b0.heading!r}")

    # The heading union must close with no duplicates: every pre-sweep heading is
    # present exactly once in the hot ledger, and the segments add none of their own.
    if len(after.blocks) != len(before.blocks):
        findings.append(
            f"HEADING-COUNT: hot ledger carries {len(after.blocks)} blocks, baseline had {len(before.blocks)}"
        )
    dupes = len(after.blocks) - len({b.heading for b in after.blocks})
    if dupes:
        findings.append(f"DUPLICATE-HEADING: {dupes} duplicated `#### ` heading(s) in the hot ledger")

    return (not findings), findings + [f"(reconciled {checked} relocated blocks against {baseline})"]


# --------------------------------------------------------------------------
# Self-test
# --------------------------------------------------------------------------

FIXTURE_TABLE = (
    "# RELEASE_LOG\n\n## Releases\n\n"
    "| Version | M | I | P | S | T | State | Date |\n|---|---|---|---|---|---|---|---|\n"
    "| v1.01 | m | i | p | s | t | VERIFIED | 2026-06-01 |\n"
    "| v2.01 | m | i | p | s | t | VERIFIED | 2026-06-02 |\n"
    "| v9.99 | m | i | p | s | t | VERIFIED | 2026-06-03 |\n\n"
)

# Blocks are laid out NEWEST-FIRST, the file convention, while the table above is
# oldest-first. The fixture keeps the two orders opposed on purpose so a sweep
# that read file position instead of the table would pick the wrong end.
FIXTURE_BLOCKS = (
    "#### Deployment Log v9.99\n**Files deployed:** newest narrative\n\n"
    "#### Release Learnings v9.99\n**Surprise:** a learning\n**Watch-for:** a thing\n\n"
    "#### Deployment Log v2.01\n**Files deployed:** middle narrative\n\n"
    "#### Deployment Log v1.01\n**Files deployed:** oldest narrative\n**Result:** shipped\n"
)


def self_test() -> int:
    import tempfile

    fails: list[str] = []
    n = 0

    def check(name: str, got, want):
        nonlocal n
        n += 1
        if got != want:
            fails.append(f"{name}: got {got!r}, want {want!r}")

    check("family v4.04", family_of("v4.04"), "v4")
    check("family v1.01", family_of("v1.01"), "v1")
    check("family slug", family_of("governance-ci-checks"), "version-less")
    check("norm", norm("public-flip-install-blockers (version-less)"), "public-flip-install-blockers")

    text = FIXTURE_TABLE + FIXTURE_BLOCKS
    led = load_log(text, Path("RELEASE_LOG.md"))
    corpus = Corpus(log=led, order=release_order(text))
    check("blocks parsed", len(led.blocks), 4)
    check("sweepable blocks", sum(1 for b in led.blocks if b.sweepable), 3)
    check("kept-class blocks", sum(1 for b in led.blocks if not b.sweepable), 1)
    check("table order is oldest-first", corpus.order, ["v1.01", "v2.01", "v9.99"])
    check("file order is newest-first", [b.key for b in led.blocks][0], "v9.99")
    check("ordering assertions clean", assert_ordering(corpus), [])

    # ORDERING: a byte target that admits exactly one archival must take the
    # OLDEST release from the TABLE, never the last block in the file. The target
    # is calibrated to the size the ledger has once v1.01 alone has moved, so the
    # loop must stop there — one block too few and it overshoots, one too many
    # and it stopped early.
    target = hot_bytes(render(corpus, {"v1.01"})[0])
    archive, size, retained = plan_sweep(corpus, target)
    check("oldest-first picks v1.01 alone", archive, {"v1.01"})
    check("retained count is an output", retained, 2)
    check("swept to the target", size, target)

    # NEGATIVE CONTROL for the file-position rule: reverse the block order so the
    # OLDEST block now sits FIRST in the file, leaving the table untouched. A
    # file-position sweep would now archive a different release; a
    # table-chronology sweep must return the same answer.
    rev = FIXTURE_TABLE + "".join(reversed(re.findall(r"#### [^#]+", FIXTURE_BLOCKS)))
    led_r = load_log(rev, Path("RELEASE_LOG.md"))
    corpus_r = Corpus(log=led_r, order=release_order(rev))
    check("control: file order really did flip", [b.key for b in led_r.blocks][0], "v1.01")
    check("control: the table order did NOT flip", corpus_r.order, ["v1.01", "v2.01", "v9.99"])
    archive_r, _, _ = plan_sweep(corpus_r, hot_bytes(render(corpus_r, {"v1.01"})[0]))
    check("control: chronology sweep is unchanged by file order", archive_r, {"v1.01"})

    # CARVE-OUT: a Release Learnings block is never selected, at ANY target.
    archive_all, _, _ = plan_sweep(corpus, 0)
    check("carve-out: every sweepable release archived", archive_all, {"v1.01", "v2.01", "v9.99"})
    main_all, segs_all = render(corpus, archive_all)
    check("carve-out: learnings body retained", "**Watch-for:** a thing" in main_all, True)
    check("carve-out: learnings heading retained", "#### Release Learnings v9.99" in main_all, True)
    check("carve-out: learnings body NOT in any segment",
          any("**Watch-for:** a thing" in "\n".join(v) for v in segs_all.values()), False)
    # FIELD-SHAPED probe, not heading-shaped: a stub retains its heading, so a
    # heading census passes vacuously on exactly the failure this guards.
    learn = [b for b in load_log(main_all, Path("x.md")).blocks if not b.sweepable][0]
    check("carve-out: learnings field lines survive",
          sum(1 for l in learn.body if re.match(r"^\*\*[^*]+:\*\* ", l)), 2)
    check("carve-out: swept block keeps ONLY the sentinel",
          [l for l in load_log(main_all, Path("x.md")).blocks[0].body if l.strip()],
          [sentinel("RELEASE_LOG_ARCHIVE-v9.md")])

    # SEGMENTATION: one segment per family, and narrative lands in it verbatim.
    check("segment count", len(segs_all), 3)
    check("segment names", sorted(p.name for p in segs_all),
          ["RELEASE_LOG_ARCHIVE-v1.md", "RELEASE_LOG_ARCHIVE-v2.md", "RELEASE_LOG_ARCHIVE-v9.md"])
    v1seg = "\n".join(next(v for k, v in segs_all.items() if k.name.endswith("-v1.md")))
    check("narrative moved verbatim", "**Files deployed:** oldest narrative" in v1seg, True)
    check("segment carries the heading", "#### Deployment Log v1.01" in v1seg, True)

    # HEADING UNION closes: every heading is still present, exactly once.
    after_headings = [b.heading for b in load_log(main_all, Path("x.md")).blocks]
    check("heading union closes", len(after_headings), 4)
    check("heading union has no duplicates", len(after_headings), len(set(after_headings)))

    # IDEMPOTENCY: a second render over an already-swept ledger moves nothing.
    corpus2 = Corpus(log=load_log(main_all, Path("RELEASE_LOG.md")), order=corpus.order)
    _, segs2 = render(corpus2, archive_all)
    check("idempotency: second pass moves nothing", segs2, {})
    check("idempotency: NEGATIVE CONTROL unswept block is not detected as archived",
          load_log(text, Path("x.md")).blocks[0].archived, False)
    check("idempotency: swept block IS detected as archived", corpus2.log.blocks[0].archived, True)

    # ORDERING REFUSAL: a block whose key has no table row cannot be ordered.
    orphan = Corpus(log=load_log(text + "\n#### Deployment Log v7.77\n**x:** y\n", Path("x.md")),
                    order=corpus.order)
    check("refusal: orphan block is refused", len(assert_ordering(orphan)), 1)
    check("refusal: CONTROL the same corpus without the orphan is clean",
          assert_ordering(corpus), [])

    # FALSIFICATION PAIR for destination-side verify(): a truncated segment must
    # FAIL, and the same check must PASS against an intact one.
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        (root / "release/releases").mkdir(parents=True)
        (root / LOG_REL).write_text(main_all)
        seg_p = root / "release/releases/RELEASE_LOG_ARCHIVE-v1.md"
        seg_p.write_text("# truncated\n")  # TRUNCATED
        b0 = [b for b in load_log(text, Path("x.md")).blocks if b.key == "v1.01"][0]
        truncated_ok = all(l in seg_p.read_text() for l in b0.body if l.strip())
        check("falsification: truncated segment is detected", truncated_ok, False)
        seg_p.write_text("# intact\n" + "\n".join([b0.heading] + b0.body) + "\n")
        intact_ok = all(l in seg_p.read_text() for l in b0.body if l.strip())
        check("falsification: intact segment passes", intact_ok, True)

    if fails:
        print("SELF-TEST FAILED")
        for f in fails:
            print("  " + f)
        return 1
    print(f"SELF-TEST PASSED ({n} assertions, incl. 3 negative controls + 1 falsification pair)")
    return 0


# --------------------------------------------------------------------------


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--plan", action="store_true", help="report what would move; write nothing")
    ap.add_argument("--apply", action="store_true", help="perform the sweep")
    ap.add_argument("--verify", action="store_true", help="destination-side conservation check")
    ap.add_argument("--baseline", default="HEAD", help="git ref holding the pre-sweep content (--verify)")
    ap.add_argument("--target-bytes", type=int, default=TARGET_BYTES,
                    help=f"sweep the hot ledger down to this size (default {TARGET_BYTES})")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    if args.verify:
        ok, findings = verify(REPO_ROOT, args.baseline)
        for f in findings:
            print(("  " if f.startswith("(") else "  FAIL: ") + f)
        print("VERIFY: " + ("PASS — every relocated byte accounted for at both ends" if ok else "FAIL"))
        return 0 if ok else 1

    corpus = read_corpus(REPO_ROOT)
    refusals = assert_ordering(corpus)
    if refusals:
        for f in refusals:
            print("  FAIL: " + f)
        print("REFUSED — the release chronology is not well-defined; nothing written")
        return 1

    archive, size, retained = plan_sweep(corpus, args.target_bytes)
    main_text, segments = render(corpus, archive)
    before = (REPO_ROOT / LOG_REL).stat().st_size

    swept = sum(1 for b in corpus.log.blocks if b.sweepable)
    kept = sum(1 for b in corpus.log.blocks if not b.sweepable)
    print(f"budget (AC)       {BUDGET_BYTES:,} B")
    print(f"sweep target      {args.target_bytes:,} B  (budget - {BUDGET_BYTES - args.target_bytes:,} B headroom)")
    print(f"blocks            {len(corpus.log.blocks)}  =  {swept} {SWEEP_CLASS} + {kept} {KEEP_CLASS} (never swept)")
    print(f"releases known    {len(corpus.order)}   (from the LOG table, oldest first)")
    print(f"releases archived {len(archive)}")
    print(f"blocks retained   {retained}   <- OUTPUT of the byte rule, not an input")
    print(f"hot ledger        {before:,} B  ->  {size:,} B   ({100 * (1 - size / before):.1f}% reduction)")
    print(f"headroom          {BUDGET_BYTES - size:,} B under the budget")
    print(f"segments          {len(segments)}")
    for sp in sorted(segments):
        print(f"    {sp.relative_to(REPO_ROOT)}  {len(segments[sp])} lines")

    if args.apply:
        write_out(REPO_ROOT, main_text, segments)
        print("APPLIED")
    else:
        print("(plan only — nothing written)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

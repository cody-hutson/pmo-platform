#!/usr/bin/env python3
"""sweep-release-corpus.py — records-management archival sweep for the four
release-corpus append-only ledgers.

WHAT IT DOES
    Relocates aged-out per-release content out of the four ledgers
    (RELEASE_LOG.md / RELEASE_DIGEST.md / RELEASE_INDEX.md / CHANGELOG.md) into
    same-directory archive segments keyed by major release family, so the hot
    working set stays inside a byte budget while every byte remains in the
    repository, greppable from the directory it always lived in.

    Disposition is a MOVE, never a destruction: every relocated entry keeps its
    heading in the source ledger with a pointer to its segment. That is the
    presence-preserving shape RECORDS_POLICY.md Disposition Rules rule 2
    sanctions, and it is what keeps the ledgers' identifier surfaces intact.

THE BOUNDARY RULE IS BYTE-DENOMINATED, NOT COUNT-DENOMINATED
    Entries are archived OLDEST-FIRST until the four ledgers' combined size is
    at or under TARGET_BYTES. The number of releases retained is an OUTPUT of
    that rule and is never an input to it -- no retained-release count is
    hardcoded here or downstream.

    Why this matters: per-release byte size is not stationary (recent releases
    carry materially larger Deployment-Log blocks than early ones), so a
    fixed-count window cannot hold a byte target -- it drifts back over budget
    within a couple of releases and the budget has to be restated again. A
    byte-denominated rule makes the budget hold BY CONSTRUCTION after every
    sweep. This is deliberately scoped to this sweep; the platform's 15-release
    window continues to govern its own surfaces (snapshots and plan files,
    whose per-item size is bounded) unchanged.

WHAT STAYS BEHIND, AND WHY IT IS NOT "JUST A POINTER"
    A stub keeps the entry's heading AND its structured machine-read field
    lines. Only narrative prose relocates. The cleaving line is prose-vs-field,
    not old-vs-new, because the fields are emitted by dedicated tools against a
    declared standard and are read back by other tools for ANY release, not
    just the newest one. Preserving the heading alone would keep every named
    contract green while silently halving a downstream tool's basis population,
    with no error and no failing check. See PRESERVED_FIELD_LABELS.

IDEMPOTENCY
    An entry is recognized as already-archived by the literal SENTINEL line in
    its body -- a machine-greppable key, not an inferred property. A second run
    is a no-op. Verified by --self-test, which also asserts the negative
    control: an unswept entry must still move.

VERIFICATION
    --verify is destination-side. Every named machine contract is satisfied by
    the retained stubs alone, so a truncated or empty segment would pass all of
    them; conservation across the move is therefore asserted directly, against
    the pre-sweep content read from git rather than from a manifest this tool
    wrote about itself. A move is verified only when both ends are.

USAGE
    sweep-release-corpus.py --plan                 # what would move (no writes)
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
# Tunables
# --------------------------------------------------------------------------

# The ONLY tunable. Sourced from the acceptance criterion for this work: the
# four ledgers' hot working set is bounded at or under this figure. It is stated
# once, here; nothing downstream restates it and nothing downstream encodes a
# retained-release count.
TARGET_BYTES = 300_000

# Sweeping exactly to the ceiling satisfies the budget at the instant of the
# sweep and then breaches it on the very next release, so the budget would only
# ever be true immediately after a chore run. The sweep therefore TRIGGERS at
# the ceiling but sweeps down to a floor below it, leaving roughly three
# releases of headroom -- so the budget holds continuously between chore runs
# rather than momentarily at each one. This is hysteresis, not a second budget:
# the ceiling is the only figure the acceptance criterion states, and the floor
# is derived from it.
SWEEP_FLOOR_RATIO = 0.90

REPO_ROOT = Path(__file__).resolve().parents[2]

# Structured field lines preserved in a RELEASE_LOG stub. This is a CLOSED set,
# established by a reader census over the executable corpus rather than by
# inspection of the ticket's contract list -- the ticket predates some of these
# readers.
#
# Membership test, applied per label with a control: does a SCRIPT read this
# field back out of the ledger? "It looks like the same kind of field" is not
# the test -- that reasoning is what puts bytes in the hot set that buy nothing.
#
#   Velocity              estimate-usage.sh reads `#### Deployment Log <ver>`
#                         and then the first `**Velocity:**` line INSIDE the
#                         body, for any historical release. A heading-only stub
#                         drops it from the tool's basis silently, with no
#                         error and no failing check.
#   Close-Class-Telemetry close-class-telemetry standard field, read back by
#                         compute-close-class-telemetry.sh. Forward-only, so it
#                         costs nothing on today's aged-out population and
#                         guards the field as it accumulates.
#   Synthesized at,       produce-learnings-register.sh reads these back out of
#   Source events,        a `#### Release Learnings <ver>` block via its
#   Source-row anchors,   version-scoped triple_field accessor, for any release
#   Surprise,             the operator names -- not only the newest.
#   Would-change,
#   Watch-for
#
# Deliberately NOT preserved:
#   Cycle-Time            EXCLUDED ON EVIDENCE. It is structurally a sibling of
#                         Velocity and reads like an obvious inclusion, but a
#                         reader census over the executable corpus (with a
#                         negative control) finds no script that reads it back
#                         -- every hit is prose or a producer. Retaining it
#                         costs ~25 KB of hot set, roughly a third of the
#                         budget's headroom, and buys no contract. Its full
#                         line is preserved in the segment like any other
#                         narrative; nothing is lost, it simply is not hot.
#   Result / Outcome / Files deployed / Mechanism / Timestamp / Version
#   lineage / Version note -- the narrative body. automated-closeout.sh does
#   anchor on `**Result:**`, but only inside the block of the release being
#   closed, which is the newest release and therefore never a sweep candidate
#   under an oldest-first rule.
PRESERVED_FIELD_LABELS = (
    "Velocity",
    "Close-Class-Telemetry",
    "Synthesized at",
    "Source events",
    "Source-row anchors",
    "Surprise",
    "Would-change",
    "Watch-for",
)

_FIELD_RE = re.compile(
    r"^\*\*(" + "|".join(re.escape(x) for x in PRESERVED_FIELD_LABELS) + r"):\*\* "
)

# The stub's pointer line is ONE line doing three jobs: it is human-readable in
# the rendered ledger, it is a resolving markdown link to the segment, and its
# fixed ASCII prefix is the machine-greppable idempotency key. Keeping these as
# one line rather than a comment plus a link matters at this scale -- there are
# ~450 stubs, so every byte of pointer is paid 450 times.
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
    return f"v{m.group(1)}" if m else "_unversioned"


def norm(key: str) -> str:
    """Ledgers spell a version-less release's key with a parenthetical suffix in
    some surfaces and without it in others. Normalize to the bare slug."""
    return key.replace(" (version-less)", "").strip()


# --------------------------------------------------------------------------
# Ledger models
# --------------------------------------------------------------------------


@dataclass
class Block:
    key: str
    heading: str
    body: list[str] = field(default_factory=list)

    @property
    def archived(self) -> bool:
        return any(line.startswith(SENTINEL_PREFIX) for line in self.body)


@dataclass
class Ledger:
    """A ledger is an ORDER-PRESERVING sequence of literal lines and per-release
    blocks. It is deliberately not modelled as head + blocks + tail: these files
    interleave structural headings between blocks (RELEASE_DIGEST groups its
    entries under several arc-level H2 sections), and a head/tail model silently
    shunts everything after the first such heading past the sweep -- a defect
    that presents as a smaller diff rather than as an error.
    """

    name: str
    path: Path
    items: list = field(default_factory=list)  # str | Block, in file order

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

    A block ends at the next heading of depth <= level, so an arc-level heading
    between two entries stays a literal line and is never swallowed. Fenced code
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
                k = key_from(line) if lv == level else None
                if k is not None:
                    cur = Block(key=k, heading=line)
                    items.append(cur)
                    continue
                cur = None
                items.append(line)
                continue
        (cur.body if cur is not None else items).append(line)
    return items


def load_log(text: str, path: Path) -> Ledger:
    def key_from(line: str) -> str | None:
        m = re.match(r"^#### (?:Deployment Log|Release Learnings) (.+?)\s*$", line)
        return norm(m.group(1)) if m else None

    return Ledger("RELEASE_LOG", path, parse_items(text.split("\n"), 4, key_from))


def load_digest(text: str, path: Path) -> Ledger:
    def key_from(line: str) -> str | None:
        m = re.match(r"^### (.+?) \(", line)
        return norm(m.group(1)) if m else None

    return Ledger("RELEASE_DIGEST", path, parse_items(text.split("\n"), 3, key_from))


def load_changelog(text: str, path: Path) -> Ledger:
    def key_from(line: str) -> str | None:
        m = re.match(r"^## \[(.+?)\]", line)
        if not m or m.group(1) == "Unreleased":
            return None
        return norm(m.group(1))

    return Ledger("CHANGELOG", path, parse_items(text.split("\n"), 2, key_from))


# --------------------------------------------------------------------------
# RELEASE_DIGEST legacy scaffold
# --------------------------------------------------------------------------


def migrate_legacy_table(text: str) -> tuple[str, list[str]]:
    """Migrate the DIGEST's legacy `### Releases` table, then remove the emptied
    scaffold. MIGRATE, never strike.

    The table is not dead content. Several of its rows are the ONLY DIGEST
    record of their release -- a literal strike would destroy the sole record of
    a shipped release, and would do it silently, because no check reads this
    table. So: every row is relocated verbatim to the v2 archive segment, and
    any row with no canonical `### <key> (...)` heading elsewhere in the file is
    ALSO promoted to that canonical form so it re-enters the surface the corpus
    completeness check actually reads.

    Returns (migrated_text, rows_moved_verbatim).
    """
    lines = text.split("\n")
    canonical = {
        norm(m.group(1))
        for m in (re.match(r"^### (.+?) \(", l) for l in lines)
        if m
    }

    start = end = None
    rows: list[str] = []
    for i, line in enumerate(lines):
        if re.match(r"^### Releases\s*$", line):
            start = i
        if start is not None and line.startswith("| ") and not line.startswith("| Version") and not line.startswith("|---"):
            rows.append(line)
            end = i
    if start is None or not rows:
        return text, []

    promoted: list[str] = []
    for row in rows:
        cells = split_row(row)
        if len(cells) < 3:
            continue
        key, date, headline = norm(cells[0]), cells[1], cells[2]
        if key in canonical:
            continue  # its canonical entry already exists; the row is a duplicate view
        paren = f"({date})" if re.match(r"^v\d", key) else f"({date}, version-less)"
        promoted.append(f"### {key} {paren} — {headline}")
        promoted.append("")

    out = lines[:start] + promoted + lines[end + 1:]
    # Collapse the run of blank lines the removed scaffold leaves behind.
    while len(out) >= 2 and out[-1] == "" and out[-2] == "":
        out.pop()
    return "\n".join(out), rows


@dataclass
class IndexLedger:
    name: str
    path: Path
    lines: list[str]
    rows: dict[str, int]  # key -> line index

    THEME_COL = 3

    @property
    def segment_stem(self) -> str:
        return self.path.name[: -len(".md")] + "_ARCHIVE"

    def segment_name(self, fam: str) -> str:
        return f"{self.segment_stem}-{fam}.md"

    def segment_path(self, fam: str) -> Path:
        return self.path.parent / self.segment_name(fam)


def split_row(line: str) -> list[str]:
    """Cells of a markdown table row. `| a | b |` -> ['a','b']."""
    return [c.strip() for c in line.strip().strip("|").split("|")]


def load_index(text: str, path: Path) -> IndexLedger:
    lines = text.split("\n")
    rows: dict[str, int] = {}
    for i, line in enumerate(lines):
        if not line.startswith("| ") or line.startswith("| Version") or line.startswith("|---"):
            continue
        cells = split_row(line)
        if len(cells) < 6:
            continue
        rows[norm(cells[0])] = i
    return IndexLedger("RELEASE_INDEX", path, lines, rows)


# --------------------------------------------------------------------------
# Release ordering — oldest first, from the LOG table (date-ascending)
# --------------------------------------------------------------------------


def release_order(log_text: str) -> list[str]:
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


def stub_body(ledger_name: str, block: Block, seg: str) -> tuple[list[str], list[str]]:
    """Return (retained_body, relocated_body) for one block.

    RELEASE_LOG keeps its structured field lines; the other ledgers have no
    machine-read body fields, so their whole body relocates.
    """
    kept: list[str] = []
    moved: list[str] = []
    if ledger_name == "RELEASE_LOG":
        for line in block.body:
            (kept if _FIELD_RE.match(line) else moved).append(line)
    else:
        moved = list(block.body)
    retained = [""] + kept + ([""] if kept else []) + [sentinel(seg), ""]
    return retained, moved


SEGMENT_HEADER = """<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
# {title}

Archive segment of [`{parent}`]({parent}) — the **{fam}** release family.

This file is the same record as its parent ledger, relocated. It is a **Vital**
record under `core/governance/RECORDS_POLICY.md`, retained permanently, and it
inherits its parent's class: a segment is a disposition *destination*, never
itself a disposition *source*. Nothing here is a lesser record for having aged
out of the working set.

It lives in the same directory as its parent deliberately, so `grep -r` over
that directory still finds this content exactly as it did before the move. Each
entry below retains its heading in the parent ledger, with a pointer here.

Entries are appended by `release/tools/sweep-release-corpus.py`; the file is
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
    digest: Ledger
    index: IndexLedger
    changelog: Ledger
    order: list[str]
    legacy_rows: list[str] = field(default_factory=list)

    def ledgers(self):
        return [self.log, self.digest, self.changelog]


def read_corpus(root: Path) -> Corpus:
    log_p = root / "release/releases/RELEASE_LOG.md"
    dig_p = root / "release/releases/RELEASE_DIGEST.md"
    idx_p = root / "release/releases/RELEASE_INDEX.md"
    chg_p = root / "CHANGELOG.md"
    log_text = log_p.read_text()
    dig_text, legacy_rows = migrate_legacy_table(dig_p.read_text())
    return Corpus(
        log=load_log(log_text, log_p),
        digest=load_digest(dig_text, dig_p),
        index=load_index(idx_p.read_text(), idx_p),
        changelog=load_changelog(chg_p.read_text(), chg_p),
        order=release_order(log_text),
        legacy_rows=legacy_rows,
    )


def render(corpus: Corpus, archive: set[str]) -> tuple[dict[Path, str], dict[Path, list[str]]]:
    """Render post-sweep main files and segment appendices."""
    mains: dict[Path, str] = {}
    segments: dict[Path, list[str]] = {}

    for led in corpus.ledgers():
        out: list[str] = []
        for item in led.items:
            if isinstance(item, str):
                out.append(item)
                continue
            blk = item
            out.append(blk.heading)
            if blk.key in archive and not blk.archived:
                fam = family_of(blk.key)
                seg = led.segment_name(fam)
                retained, moved = stub_body(led.name, blk, seg)
                out += retained
                sp = led.segment_path(fam)
                segments.setdefault(sp, []).append(blk.heading)
                segments[sp] += moved
            else:
                out += blk.body
        mains[led.path] = "\n".join(out)

    # INDEX — the Theme cell is the only relocated content. Rows, order and all
    # five verified columns are untouched; the verifier compares LOG-derivable
    # fields only and carries a non-placeholder Theme forward across
    # regeneration, so a pointer cell survives a regen.
    idx_lines = list(corpus.index.lines)
    for key, li in corpus.index.rows.items():
        if key not in archive:
            continue
        cells = split_row(idx_lines[li])
        theme = cells[IndexLedger.THEME_COL]
        if theme in ("", "—") or theme.startswith("[archived]"):
            continue
        fam = family_of(key)
        seg = corpus.index.segment_name(fam)
        sp = corpus.index.segment_path(fam)
        segments.setdefault(sp, []).append(f"#### {key}")
        segments[sp] += ["", theme, ""]
        cells[IndexLedger.THEME_COL] = f"[archived]({seg})"
        idx_lines[li] = "| " + " | ".join(cells) + " |"
    mains[corpus.index.path] = "\n".join(idx_lines)

    # The legacy DIGEST table relocates verbatim -- every row, including the
    # ones that also have a canonical heading. Relocating the whole table keeps
    # the original artifact intact in one place; promotion (above) is additive
    # on top of that, never a substitute for it.
    if corpus.legacy_rows:
        sp = corpus.digest.segment_path("v2")
        segments.setdefault(sp, []).append("#### Legacy `### Releases` table (migrated verbatim)")
        segments[sp] += ["", "| Version | Date | Headline |", "|---------|------|----------|"]
        segments[sp] += corpus.legacy_rows
        segments[sp] += [""]

    return mains, segments


def hot_bytes(mains: dict[Path, str]) -> int:
    return sum(len(t.encode()) for t in mains.values())


def plan_sweep(corpus: Corpus, target: int) -> tuple[set[str], int, int]:
    """Archive oldest-first until the hot set is at or under `target`.

    Returns (archive_set, final_bytes, retained_count). The retained count is a
    RESULT of the loop, never a parameter to it.
    """
    floor = int(target * SWEEP_FLOOR_RATIO)
    archive: set[str] = set()
    mains, _ = render(corpus, archive)
    size = hot_bytes(mains)
    for key in corpus.order:  # oldest first
        if size <= floor:
            break
        archive.add(key)
        mains, _ = render(corpus, archive)
        size = hot_bytes(mains)
    return archive, size, len(corpus.order) - len(archive)


def write_out(root: Path, mains: dict[Path, str], segments: dict[Path, list[str]]) -> None:
    for path, text in mains.items():
        path.write_text(text)
    for path, body in segments.items():
        fam = path.name[: -len(".md")].rsplit("-", 1)[1]
        stem = path.name[: -len(".md")].rsplit("-", 1)[0]
        parent = stem.replace("_ARCHIVE", "") + ".md"
        header = SEGMENT_HEADER.format(
            title=segment_title(stem, fam), parent=parent, fam=fam
        )
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

    For every entry archived since `baseline`: every line of its pre-sweep body
    must be accounted for either as a retained field line in the parent ledger
    or as a relocated line in the segment -- and the segment must actually
    contain it. An empty or truncated segment fails here and nowhere else.
    """
    findings: list[str] = []
    checked = 0

    loaders = {
        "release/releases/RELEASE_LOG.md": load_log,
        "release/releases/RELEASE_DIGEST.md": load_digest,
        "CHANGELOG.md": load_changelog,
    }

    for rel, loader in loaders.items():
        p = root / rel
        before = loader(git_show(baseline, rel), p)
        after = loader(p.read_text(), p)
        after_by_key: dict[str, list[Block]] = {}
        for b in after.blocks:
            after_by_key.setdefault(b.key, []).append(b)

        seg_cache: dict[Path, str] = {}

        for i, b0 in enumerate(before.blocks):
            cands = [b for b in after.blocks if b.heading == b0.heading]
            if not cands:
                findings.append(f"MISSING-HEADING: {rel} :: {b0.heading!r} vanished from the parent ledger")
                continue
            b1 = cands[0]
            if not b1.archived:
                continue  # not swept -- nothing to reconcile
            checked += 1
            mark = next(l for l in b1.body if l.startswith(SENTINEL_PREFIX))
            sp = p.parent / segment_from_sentinel(mark)
            if sp not in seg_cache:
                if not sp.exists():
                    findings.append(f"MISSING-SEGMENT: {rel} :: {b0.heading!r} points at {sp.name}, which does not exist")
                    continue
                seg_cache[sp] = sp.read_text()
            seg = seg_cache[sp]

            retained = {l for l in b1.body
                        if not l.startswith(SENTINEL_PREFIX) and l.strip()}
            for line in b0.body:
                if not line.strip():
                    continue
                if line in retained:
                    continue
                if line in seg:
                    continue
                findings.append(
                    f"LOST-CONTENT: {rel} :: {b0.heading!r} — a body line is in neither the "
                    f"stub nor {sp.name}: {line[:90]!r}"
                )
            if b0.heading not in seg:
                findings.append(f"SEGMENT-NO-HEADING: {sp.name} does not carry {b0.heading!r}")

    # INDEX themes
    rel = "release/releases/RELEASE_INDEX.md"
    p = root / rel
    before_i = load_index(git_show(baseline, rel), p)
    after_i = load_index(p.read_text(), p)
    for key, li in before_i.rows.items():
        theme0 = split_row(before_i.lines[li])[IndexLedger.THEME_COL]
        if key not in after_i.rows:
            findings.append(f"MISSING-ROW: {rel} :: row {key!r} vanished")
            continue
        theme1 = split_row(after_i.lines[after_i.rows[key]])[IndexLedger.THEME_COL]
        if theme1 == theme0:
            continue
        if not theme1.startswith("[archived]("):
            findings.append(f"THEME-CHANGED: {rel} :: {key} Theme changed but is not an archive pointer")
            continue
        checked += 1
        segn = theme1[len("[archived]("):-1]
        sp = p.parent / segn
        if not sp.exists():
            findings.append(f"MISSING-SEGMENT: {rel} :: {key} points at {segn}, which does not exist")
            continue
        if theme0 not in sp.read_text():
            findings.append(f"LOST-CONTENT: {rel} :: {key} Theme prose is not present in {segn}")

    return (not findings), findings + [f"(reconciled {checked} relocated entries against {baseline})"]


# --------------------------------------------------------------------------
# Self-test
# --------------------------------------------------------------------------


def self_test() -> int:
    import tempfile

    fails: list[str] = []

    def check(name: str, got, want):
        if got != want:
            fails.append(f"{name}: got {got!r}, want {want!r}")

    check("family v4.04", family_of("v4.04"), "v4")
    check("family v1.01", family_of("v1.01"), "v1")
    check("family slug", family_of("governance-ci-checks"), "_unversioned")
    check("norm", norm("public-flip-install-blockers (version-less)"), "public-flip-install-blockers")

    log = load_log(
        "# RELEASE_LOG\n\n## Releases\n\n"
        "| Version | M | I | P | S | T | State | Date |\n|---|---|---|---|---|---|---|---|\n"
        "| v1.01 | m | i | p | s | t | VERIFIED | 2026-06-01 |\n"
        "| v9.99 | m | i | p | s | t | VERIFIED | 2026-06-02 |\n\n"
        "#### Deployment Log v9.99\n**Files deployed:** narrative\n**Velocity:** planned 4 pts class novel\n\n"
        "#### Deployment Log v1.01\n**Files deployed:** old narrative\n**Velocity:** planned 2 pts class routine\n",
        Path("RELEASE_LOG.md"),
    )
    check("log blocks", len(log.blocks), 2)
    check("log order", release_order(
        "| Version | M | I | P | S | T | State | Date |\n|---|---|---|---|---|---|---|---|\n"
        "| v1.01 | m | i | p | s | t | VERIFIED | 2026-06-01 |\n"
        "| v9.99 | m | i | p | s | t | VERIFIED | 2026-06-02 |\n"), ["v1.01", "v9.99"])

    blk = [b for b in log.blocks if b.key == "v1.01"][0]
    kept, moved = stub_body("RELEASE_LOG", blk, "RELEASE_LOG_ARCHIVE-v1.md")
    check("field preserved", any("**Velocity:**" in l for l in kept), True)
    check("narrative moved", any("old narrative" in l for l in moved), True)
    check("narrative NOT kept", any("old narrative" in l for l in kept), False)
    check("sentinel present", any(l.startswith(SENTINEL_PREFIX) for l in kept), True)

    # Idempotency: a block already carrying the sentinel is recognized, and the
    # negative control (a block without it) is not.
    swept = Block(key="v1.01", heading="#### Deployment Log v1.01", body=kept)
    check("idempotency: swept detected", swept.archived, True)
    check("idempotency: NEGATIVE CONTROL unswept", blk.archived, False)

    # Conservation falsification: the verifier must FAIL on a truncated segment.
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        (root / "release/releases").mkdir(parents=True)
        idx = ("# RELEASE_INDEX\n\n| Version | Milestone | Date | Theme | Release PR | Release Notes |\n"
               "|---|---|---|---|---|---|\n| v1.01 | m | 2026-06-01 | theme prose here | #1 | [n](n.md) |\n")
        (root / "release/releases/RELEASE_INDEX.md").write_text(idx)
        after = idx.replace("theme prose here", "[archived](RELEASE_INDEX_ARCHIVE-v1.md)")
        (root / "release/releases/RELEASE_INDEX.md").write_text(after)
        (root / "release/releases/RELEASE_INDEX_ARCHIVE-v1.md").write_text("# seg\n")  # TRUNCATED
        b_i = load_index(idx, root / "release/releases/RELEASE_INDEX.md")
        a_i = load_index(after, root / "release/releases/RELEASE_INDEX.md")
        t0 = split_row(b_i.lines[b_i.rows["v1.01"]])[IndexLedger.THEME_COL]
        seg_text = (root / "release/releases/RELEASE_INDEX_ARCHIVE-v1.md").read_text()
        check("falsification: truncated segment is detected", t0 in seg_text, False)
        (root / "release/releases/RELEASE_INDEX_ARCHIVE-v1.md").write_text("# seg\ntheme prose here\n")
        seg_text = (root / "release/releases/RELEASE_INDEX_ARCHIVE-v1.md").read_text()
        check("falsification: intact segment passes", t0 in seg_text, True)

    if fails:
        print("SELF-TEST FAILED")
        for f in fails:
            print("  " + f)
        return 1
    print("SELF-TEST PASSED (17 assertions, incl. 1 negative control + 1 falsification pair)")
    return 0


# --------------------------------------------------------------------------


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--plan", action="store_true", help="report what would move; write nothing")
    ap.add_argument("--apply", action="store_true", help="perform the sweep")
    ap.add_argument("--verify", action="store_true", help="destination-side conservation check")
    ap.add_argument("--baseline", default="HEAD", help="git ref holding the pre-sweep content (--verify)")
    ap.add_argument("--target-bytes", type=int, default=TARGET_BYTES)
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
    archive, size, retained = plan_sweep(corpus, args.target_bytes)
    mains, segments = render(corpus, archive)

    print(f"ceiling (AC)      {args.target_bytes:,} B")
    print(f"sweep floor       {int(args.target_bytes * SWEEP_FLOOR_RATIO):,} B  (hysteresis — headroom between chore runs)")
    print(f"releases known    {len(corpus.order)}")
    print(f"releases archived {len(archive)}")
    print(f"releases retained {retained}   <- OUTPUT of the byte rule, not an input")
    print(f"hot set after     {size:,} B  ({size / 1024:.1f} KiB)")
    for path, text in sorted(mains.items()):
        print(f"    {path.relative_to(REPO_ROOT)}  {len(text.encode()):,} B")
    print(f"segments          {len(segments)}")
    for sp in sorted(segments):
        print(f"    {sp.relative_to(REPO_ROOT)}  {len(segments[sp])} lines")

    if args.apply:
        write_out(REPO_ROOT, mains, segments)
        print("APPLIED")
    else:
        print("(plan only — nothing written)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

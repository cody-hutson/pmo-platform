#!/usr/bin/env python3
"""check-count-structure.py — the Check 63 predicate (count-vs-structure lint).

WHAT IT ASSERTS
    A stated cardinality that sits immediately above an enumerable structure must
    reconcile with that structure under at least ONE reading. This is deliberately
    NOT `nearest numeral == list length`: that naive predicate flags 129 pairs on
    this corpus, and most of them are correct prose.

THE PREDICATE (H-G — disjunctive reconciliation over a colon-anchored preamble)
    A pair is EXAMINED only when both hold:
      (1) a colon-TERMINATED line carries >= 1 cardinal bound to a plural noun, and
      (2) the next non-blank line opens a markdown list or a markdown table.
    An examined pair FLAGs only when NO reading reconciles:
      R-a IDENTITY   some stated cardinal == item_count
      R-b PARTITION  sum(stated cardinals) == item_count
      R-c SUB-COUNT  some stated cardinal == sum(per-item parenthetical cardinals),
                     when >= 2 items carry one
    Four suppressors strip cardinals (or whole pairs) that are not counts of the
    adjacent structure: S1 identifier numerals, S2 unit numerals, S3 inexact
    bounds, S5 conditional clauses.

WHY THERE IS NO S4 (preposition suppressor) AND NO TERMINAL WINDOW
    Both were in an earlier candidate (H-F) that scored 8 flags against the H-G
    PROTOTYPE's 51 — six times better on false positives — and both were deleted
    because the two-armed fixture pair at
    core/hooks/testdata/count-structure-fixtures.txt falsified them.
    The terminal window makes the FLAG arm unexaminable (a BROKEN sensitivity arm:
    0 pairs, 0 flags, reported as "clean"). The preposition suppressor discards the
    very cardinal that RECONCILES the CLEAN arm (`across 6 classes`), turning the
    specificity arm into a false alarm. A probe that examines almost nothing scores
    beautifully on false positives and proves nothing — see
    core/disciplines/review-discipline-principles.md Section 1 Rule 15 and Section 8
    (PV-2 sensitivity arm, PV-2c specificity arm, PV-5 vacuous-arm rider).

SELF-CONTROL ON EVERY RUN (PV-5 / INT-2)
    Every invocation runs both control arms in-memory and reports them as fields
    alongside the denominator, so a reader can always distinguish "zero found" from
    "nothing examined". A broken or over-matching control arm is a hard failure
    regardless of the caller's mode — the Check 31 fixture-regression precedent.

BASELINE
    73 non-reconciling pairs pre-exist in the live corpus at introduction. They ship
    in core/deploy/allowlists/count-structure-baseline.txt keyed
    `<path>\\t<sha1(normalized preamble)>\\t<class-tag>` — line-number-free, so
    ordinary edits elsewhere in a file cannot invalidate an entry. Editing a
    baselined preamble itself re-keys its sha1 and the pair FAILs, which is correct:
    editing a count preamble is exactly the moment to re-verify its count.

    RECONCILIATION IS SCOPE-RELATIVE. A baseline entry whose file lies OUTSIDE the
    requested scope is EXCLUDED — reported in neither the KNOWN nor the STALE
    population. INSIDE the scope an entry is STALE when its file is absent from the
    corpus (the ratchet: the row points at something that is gone) or when the file
    was read and its pair no longer appears. An in-scope entry whose file could not
    be read is UNMEASURED and is never STALE — we did not measure it, so we cannot
    assert its pair is gone.

SCOPE (--path / --paths-from are polymorphic)
    An argument naming an existing directory — or written with a trailing slash — is
    a SUBTREE PREFIX resolved against the corpus enumeration. Anything else names a
    single file. Every reporting run emits a SCOPE record carrying Register A
    `status=` (fetched / degraded / not-run) and Register B `state=` (- / DEGRADED /
    NOT-EVALUATED); a consumer must branch on it BEFORE reading any counter.

EXIT CODES (Check 59 contract)
    0 clean · 1 finding · 3 input failure — where a requested scope that resolves to
    ZERO READABLE FILES is an input failure. That condition is a malformed
    invocation, not a measurement outage, which is why it gates. A PARTIAL read
    (some files resolved but unreadable) stays IN-BAND: it reports `degraded` /
    DEGRADED and does NOT move the exit code, because a measurement outage must
    never gate — core/disciplines/review-discipline-principles.md § 8 PV-7c.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys

# ── Scope ────────────────────────────────────────────────────────────────────
# Frozen-artifact exemption (AC2). Shipped release plans/notes are a historical
# record — a count inside one describes the corpus AS IT WAS, and "fixing" it would
# rewrite history. Fixture trees are excluded because they carry deliberate defects.
EXEMPT_PREFIXES = (
    "release/releases/",
    "core/hooks/testdata/",
    "core/deploy/tests/fixtures/",
    "packages/",
    ".github/",
)

NUMBER_WORDS = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
    "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
    "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
    "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
    "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90,
}

# S1 — identifier numerals. `Stage 6` is a name, not a count of stages.
S1_IDENT = {
    "stage", "step", "check", "procedure", "module", "tier", "phase", "section",
    "rule", "gate", "wave", "option", "lane", "mode", "part", "level", "adr",
    "figure", "table", "appendix", "milestone", "issue", "pr", "adr-", "§", "v",
}

# S2 — unit numerals. `within 2 hours` counts time, never the list beneath it.
S2_UNITS = {
    "hour", "hours", "day", "days", "week", "weeks", "month", "months",
    "year", "years", "minute", "minutes", "second", "seconds",
    "release", "releases", "sprint", "sprints", "byte", "bytes",
    "line", "lines", "char", "chars", "character", "characters",
    "percent", "point", "points", "commit", "commits", "kb", "mb",
}

# S3 — inexact bounds. `>= 4 files` states a floor, not a cardinality.
S3_PREFIX_TOKENS = {
    "least", "most", "up", "over", "under", "about", "approximately", "roughly",
    "than", "last", "first", "top", "nearly", "almost", "some", "every", "each",
    "another", "additional", "further", "only", "just", "max", "min", "maximum",
    "minimum",
}
# NOTE `+` is absent here on purpose. An inexact bound writes the plus AFTER the
# numeral (`5+ files`), so a `+` BEFORE it is an additive partition separator
# (`10 PreToolUse hooks + 3 SessionStart hooks`) — suppressing on it would discard the
# second operand and silently disable the partition reading. Handled below as a
# trailing-`+` test instead.
S3_SYMBOLS = ("≥", "≤", "~", "±", ">", "<")

# S5 — conditional clauses. A condition in the preamble means the numeral is a
# threshold in that condition, not a count of what follows.
S5_RE = re.compile(
    r"\b(if|when|where|unless|has|have|returns|reached|reaches|exceeds|exceed|"
    r"whenever|until|after|before|once)\b",
    re.IGNORECASE,
)

IRREGULAR_PLURALS = {
    "people", "criteria", "data", "matrices", "indices", "phenomena", "media",
    "children", "men", "women", "personnel", "staff", "series",
}

# A noun phrase ends here. Without this the scanner reads a third-person-singular
# VERB as the plural head noun — `exactly one adapter ships in v1` binds `one` to
# `ships` and manufactures a stated cardinality out of a verb.
NP_STOP = {
    # copulas / auxiliaries
    "is", "are", "was", "were", "be", "been", "being", "am",
    "has", "have", "had", "do", "does", "did", "will", "would", "shall",
    "should", "can", "could", "may", "might", "must",
    # conjunctions / subordinators / prepositions that close a noun phrase
    "and", "or", "but", "that", "which", "who", "whom", "whose", "if", "when",
    "then", "so", "because", "to", "into", "for", "with", "by", "from", "at",
    "on", "in", "as", "than", "while", "whereas", "unless", "until", "via",
    # common third-person-singular verb forms observed binding falsely
    "ships", "runs", "gives", "takes", "makes", "carries", "uses", "needs",
    "keeps", "holds", "applies", "fires", "reads", "writes", "sets", "gets",
    "adds", "says", "notes", "covers", "states", "exists", "remains", "goes",
    "requires", "returns", "becomes", "produces", "provides", "emits", "means",
    "resolves", "yields", "includes", "contains", "follows", "treats", "lives",
    "sits", "comes", "maps", "binds", "declares", "enforces", "asserts",
    "reports", "renders", "records", "lands", "leaves", "opens", "closes",
    "counts", "flags", "scores", "ranks", "tracks", "owns", "serves", "sees",
    "works", "helps", "allows", "lets", "shows", "tells", "calls", "puts",
    "picks", "drops", "moves", "turns", "starts", "stops", "ends", "wins",
    "loses", "fails", "passes", "matches", "differs", "varies", "spans",
}
# Skippable inside a noun phrase — `11 of the 12 observed shapes` must bind BOTH
# cardinals to `shapes`; a partitive determiner does not close the phrase.
NP_SKIP = {"of", "the", "a", "an", "these", "those", "its", "their", "our",
           "all", "both", "other", "others", "such", "same"}

CARDINAL_RE = re.compile(
    r"(?<![\w.])(\d{1,4}|"
    + "|".join(sorted(NUMBER_WORDS, key=len, reverse=True))
    + r")(?![\w.\d])",
    re.IGNORECASE,
)

LIST_ITEM_RE = re.compile(r"^(\s*)([-*+]|\d{1,3}[.)])\s+\S")
TABLE_SEP_RE = re.compile(r"^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$")
PAREN_CARD_RE = re.compile(r"\((?:[^()]*?\b)?(\d{1,4})\b[^()]*\)")

# ── Structures ───────────────────────────────────────────────────────────────


class Pair:
    __slots__ = ("path", "line", "preamble", "kind", "items", "stated",
                 "subcounts", "sha1")

    def __init__(self, path, line, preamble, kind, items, stated, subcounts):
        self.path = path
        self.line = line
        self.preamble = preamble
        self.kind = kind
        self.items = items
        self.stated = stated
        self.subcounts = subcounts
        self.sha1 = sha1_preamble(preamble)

    def reconciles(self):
        """Return the reading that reconciles, or None. Disjunctive by design."""
        if any(c == self.items for c in self.stated):
            return "R-a"
        if len(self.stated) > 1 and sum(self.stated) == self.items:
            return "R-b"
        if len(self.subcounts) >= 2:
            total = sum(self.subcounts)
            if any(c == total for c in self.stated):
                return "R-c"
        return None


def sha1_preamble(text: str) -> str:
    """Whitespace-normalized sha1. Line-number-free by construction, so an edit
    elsewhere in the file cannot invalidate a baseline entry — but an edit to the
    preamble ITSELF re-keys it, which is the intended ratchet.

    `usedforsecurity=False` is load-bearing and must not be dropped: this digest is
    a CONTENT KEY for baseline lookup, never an integrity or authentication
    primitive, and the flag is what states that to both a reader and to bandit
    (B324/CWE-327, which the repo's Python SAST gate runs at --severity-level high).
    The flag does NOT change the digest — the key is byte-identical with and
    without it — so setting it re-keys nothing. Do NOT "fix" this by switching
    algorithm or truncation: the committed baseline is keyed on sha1(preamble)[:16]
    and any change there re-keys every entry in it.
    """
    norm = " ".join(text.split())
    return hashlib.sha1(norm.encode("utf-8"), usedforsecurity=False).hexdigest()[:16]


def cardinal_value(tok: str) -> int:
    low = tok.lower()
    if low in NUMBER_WORDS:
        return NUMBER_WORDS[low]
    return int(tok)


def plural_noun_after(text: str, end: int) -> str | None:
    """The cardinal must BIND to a plural HEAD NOUN, otherwise it is a bare numeral
    and not a stated cardinality. Scans forward through modifiers and partitive
    determiners, and STOPS at anything that closes the noun phrase — so a verb is
    never mistaken for the head noun."""
    tail = text[end:end + 90]
    tokens = re.findall(r"[A-Za-z][A-Za-z\-']*", tail)
    for tok in tokens[:5]:
        low = tok.lower().rstrip("'")
        if low in NP_STOP:
            return None
        if low in IRREGULAR_PLURALS:
            return low
        if low in NP_SKIP:
            continue
        if len(low) >= 3 and low.endswith("s") and not low.endswith("ss"):
            return low
    return None


def mask_noncounting_spans(line: str) -> str:
    """Blank out spans whose numerals are never a cardinality of an adjacent
    structure — inline code, URLs, and markdown link targets. A blog-post date in
    a citation URL (`/blog/2011/11/15/`) otherwise reads as three stated counts."""
    def blank(m):
        return " " * (m.end() - m.start())
    out = re.sub(r"`[^`]*`", blank, line)
    out = re.sub(r"\]\([^)]*\)", blank, out)
    out = re.sub(r"https?://\S+", blank, out)
    return out


def extract_cardinals(preamble: str):
    """Return (kept, suppressed) cardinal values after S1/S2/S3. S5 is a whole-pair
    suppressor and is applied by the caller."""
    kept, suppressed = [], []
    scan = mask_noncounting_spans(preamble)
    for m in CARDINAL_RE.finditer(scan):
        tok = m.group(1)
        try:
            val = cardinal_value(tok)
        except ValueError:
            continue
        # S2 — a 4-digit calendar year is a date, never a count of the list below.
        if tok.isdigit() and len(tok) == 4 and 1900 <= val <= 2099:
            suppressed.append(("S2", val))
            continue
        noun = plural_noun_after(preamble, m.end())
        if noun is None:
            continue  # not bound to a plural head noun — not a stated cardinality
        before = preamble[max(0, m.start() - 24):m.start()]
        prev_words = re.findall(r"[A-Za-z§]+", before)
        prev = prev_words[-1].lower() if prev_words else ""
        stripped = before.rstrip()

        # S1 — identifier numeral (`Stage 6`, `§ 4`, `ADR-098`).
        if prev in S1_IDENT or stripped.endswith(("§", "#")):
            suppressed.append(("S1", val))
            continue
        # S2 — unit numeral (`2 hours`, `last 3 releases`).
        if noun in S2_UNITS:
            suppressed.append(("S2", val))
            continue
        # S3 — inexact bound (`>= 4 files`, `up to 5 rows`, `2-3 items`).
        if prev in S3_PREFIX_TOKENS or stripped.endswith(S3_SYMBOLS):
            suppressed.append(("S3", val))
            continue
        # S3 — a trailing plus (`5+ files`) is an open-ended floor, not a cardinality.
        if re.match(r"\+\s*\D", scan[m.end():]) or scan[m.end():m.end() + 1] == "+" \
                and not re.match(r"\+\s*\d", scan[m.end():]):
            suppressed.append(("S3", val))
            continue
        # S3 — a range operand (either end) is a bound, not a cardinality.
        if re.match(r"\s*[-–—]\s*\d", scan[m.end():]) or \
           re.search(r"\d\s*[-–—]\s*$", stripped):
            suppressed.append(("S3", val))
            continue
        # S3 — a product operand (`17×5 rules`) is a factor, not a cardinality.
        if re.match(r"\s*[×x]\s*\d", scan[m.end():]) or \
           re.search(r"\d\s*[×x]\s*$", stripped):
            suppressed.append(("S3", val))
            continue
        kept.append(val)
    return kept, suppressed


def structure_at(lines, idx):
    """If lines[idx:] opens a markdown list or table, return (kind, item_count).
    Otherwise (None, 0)."""
    first = lines[idx]
    m = LIST_ITEM_RE.match(first)
    if m:
        base = len(m.group(1))
        count, j, blanks = 0, idx, 0
        while j < len(lines):
            ln = lines[j]
            if not ln.strip():
                blanks += 1
                if blanks >= 2:
                    break
                j += 1
                continue
            mm = LIST_ITEM_RE.match(ln)
            if mm:
                ind = len(mm.group(1))
                if ind == base:
                    count += 1
                    blanks = 0
                    j += 1
                    continue
                if ind > base:      # nested item — part of the run, not counted
                    blanks = 0
                    j += 1
                    continue
                break               # dedent out of the run
            if blanks:
                break               # blank then prose — the run ended
            if ln.startswith((" ", "\t")):
                j += 1              # continuation line of the current item
                continue
            break
        return ("list", count)

    if first.lstrip().startswith("|") and first.count("|") >= 2:
        j = idx
        rows = []
        while j < len(lines) and lines[j].lstrip().startswith("|"):
            rows.append(lines[j])
            j += 1
        if len(rows) < 2:
            return (None, 0)
        seps = [k for k, r in enumerate(rows) if TABLE_SEP_RE.match(r)]
        if seps:
            return ("table", len(rows) - seps[0] - 1)
        return ("table", len(rows) - 1)

    return (None, 0)


def inline_structure(line: str):
    """OPT-IN, measured separately (--include-inline). An inline enumeration is a
    mid-line colon followed by a semicolon-delimited run of >= 3 segments. Off by
    default: this form's own false-positive surface is reported by --measure-inline
    and it is NOT part of the shipped v1 population."""
    ci = line.find(": ")
    if ci < 0:
        return None
    head, tail = line[:ci + 1], line[ci + 2:]
    segs = [s.strip() for s in tail.rstrip().rstrip(".").split(";")]
    segs = [s for s in segs if s]
    if len(segs) < 3:
        return None
    return head, segs


def per_item_parentheticals(lines, idx, kind, items):
    """R-c inputs: the first parenthesized cardinal on each top-level item."""
    out = []
    if kind == "list":
        m = LIST_ITEM_RE.match(lines[idx])
        base = len(m.group(1))
        j, seen = idx, 0
        while j < len(lines) and seen < items:
            mm = LIST_ITEM_RE.match(lines[j])
            if mm and len(mm.group(1)) == base:
                seen += 1
                p = PAREN_CARD_RE.search(lines[j])
                if p:
                    out.append(int(p.group(1)))
            elif not lines[j].strip():
                pass
            j += 1
    elif kind == "table":
        j, seen = idx, 0
        started = False
        while j < len(lines) and lines[j].lstrip().startswith("|"):
            if TABLE_SEP_RE.match(lines[j]):
                started = True
            elif started and seen < items:
                seen += 1
                p = PAREN_CARD_RE.search(lines[j])
                if p:
                    out.append(int(p.group(1)))
            j += 1
    return out


def scan_text(text: str, path: str, include_inline: bool = False):
    """Yield Pair objects. This is the whole predicate; everything else is I/O."""
    lines = text.split("\n")
    pairs = []
    in_fence = False
    for i, raw in enumerate(lines):
        stripped = raw.strip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence or not stripped:
            continue

        preamble, kind, items, sidx = None, None, 0, None

        if stripped.endswith(":"):
            j = i + 1
            while j < len(lines) and not lines[j].strip():
                j += 1
            if j < len(lines):
                k, n = structure_at(lines, j)
                if k:
                    preamble, kind, items, sidx = stripped, k, n, j
        elif include_inline:
            got = inline_structure(stripped)
            if got:
                preamble, kind, items, sidx = got[0], "inline", len(got[1]), None

        if preamble is None or items < 2:
            continue
        if S5_RE.search(preamble[-90:]):
            continue                      # S5 — conditional clause
        kept, _sup = extract_cardinals(preamble)
        if not kept:
            continue                      # nothing left to cross-validate

        if kind == "inline":
            subs = []
            for seg in inline_structure(stripped)[1]:
                p = PAREN_CARD_RE.search(seg)
                if p:
                    subs.append(int(p.group(1)))
        else:
            subs = per_item_parentheticals(lines, sidx, kind, items)

        pairs.append(Pair(path, i + 1, preamble, kind, items, kept, subs))
    return pairs


# ── Control arms (run on EVERY invocation — PV-5 / INT-2) ────────────────────
# Block translations of the two-armed pair handed over by #4195 at
# core/hooks/testdata/count-structure-fixtures.txt. Both arms preserve the two
# discriminating properties of the originals: the numeral counts SHAPES while the
# list enumerates CLASSES, and the corrected twin's per-item parentheticals sum to
# the stated total. The arms differ ONLY in whether a reading reconciles.
_CONTROL_SENSITIVITY = """COVERED — 11 of the 12 observed shapes, across these classes:

- wrong denominator
- truncated extraction
- empty extraction
- non-discriminating predicate
- wrong scope
- zero-byte control
- no-probe-at-all
- wrong pattern in the false-alarm direction
"""

_CONTROL_SPECIFICITY = """COVERED — 11 of the 12 observed shapes, across 6 classes:

- wrong-denominator (2 shapes)
- truncated-or-empty-extraction (4)
- non-discriminating-predicate (2)
- wrong-scope (1)
- no-probe (1)
- wrong-pattern-false-alarm (1)
"""


def run_controls():
    """Returns (ok, detail). Both arms must be EXAMINED (non-vacuous) and must
    land on opposite verdicts."""
    sp = scan_text(_CONTROL_SENSITIVITY, "<control:sensitivity>")
    cp = scan_text(_CONTROL_SPECIFICITY, "<control:specificity>")
    sens_examined, spec_examined = len(sp), len(cp)
    sens_flag = sum(1 for p in sp if p.reconciles() is None)
    spec_flag = sum(1 for p in cp if p.reconciles() is None)
    detail = (f"sensitivity examined={sens_examined} flagged={sens_flag}; "
              f"specificity examined={spec_examined} flagged={spec_flag}")
    if sens_examined == 0 or spec_examined == 0:
        return False, "VACUOUS — " + detail + " (an arm examined nothing; a zero here proves nothing)"
    if sens_flag == 0:
        return False, "BROKEN PROBE — " + detail + " (the must-flag arm did not flag)"
    if spec_flag != 0:
        return False, "OVER-MATCHING PROBE — " + detail + " (the must-not-flag arm flagged)"
    return True, detail


# ── Baseline ─────────────────────────────────────────────────────────────────

def load_baseline(path):
    entries = {}
    if not path or not os.path.exists(path):
        return entries
    with open(path, "r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 3:
                continue
            entries[(parts[0], parts[1])] = parts[2]
    return entries


# ── Driver ───────────────────────────────────────────────────────────────────

def corpus_paths(root):
    """Every markdown file the corpus tracks, relative to `root`."""
    import subprocess
    out = subprocess.run(
        ["git", "ls-files", "*.md"], cwd=root, capture_output=True, text=True
    )
    return [p for p in out.stdout.split("\n") if p.strip()]


def collect_paths(root, explicit, paths_from, apply_exempt=True):
    """Resolve the requested scope. Returns (paths, in_scope, requested).

    `--path` / `--paths-from` are POLYMORPHIC: an argument naming an existing
    directory — or written with a trailing slash — is a SUBTREE PREFIX resolved
    against the corpus enumeration; anything else names a single file. Before this,
    the arguments were a bare path-list ACCUMULATOR: handing one a directory
    produced a one-element list, open() raised IsADirectoryError, the read loop
    swallowed it, and the run reported a clean summary over an empty scan.

    `in_scope(rel) -> bool` is returned ALONGSIDE the list because the two answer
    different questions. The list is what will be READ; the predicate is what the
    requested scope CONTAINS — and a baseline row naming a DELETED file is in scope
    while appearing in no list. Reconciling on the list instead of the predicate
    would silently stop reporting a baseline row whose file was removed, which is
    the ratchet's whole purpose.

    A directory argument is normalized to exactly one trailing slash, so `core` and
    `core/` behave identically and neither ever matches `corelib/`.
    """
    args = list(explicit or [])
    if paths_from:
        with open(paths_from, "r", encoding="utf-8") as fh:
            args += [ln.strip() for ln in fh if ln.strip()]

    dir_args, file_args = [], []
    for a in args:
        if a.endswith("/") or os.path.isdir(os.path.join(root, a)):
            dir_args.append(a.rstrip("/") + "/")
        else:
            file_args.append(a)

    # The corpus enumeration runs only when a subtree must be expanded (or when no
    # argument was given at all). A pure file-argument invocation therefore stays on
    # exactly the pre-change code path — which is what keeps the fixture harness's
    # `--root /` form, where a corpus enumeration is meaningless, working unchanged.
    if not args:
        paths = corpus_paths(root)
    else:
        paths = list(file_args)
        if dir_args:
            paths += [p for p in corpus_paths(root)
                      if p.startswith(tuple(dir_args))]

    file_set = set(file_args)
    dir_tuple = tuple(dir_args)

    def in_scope(rel):
        if apply_exempt and rel.startswith(EXEMPT_PREFIXES):
            return False
        if not args:
            return True
        return rel in file_set or rel.startswith(dir_tuple)

    if apply_exempt:
        paths = [p for p in paths if not p.startswith(EXEMPT_PREFIXES)]
    return sorted(set(paths)), in_scope, len(args)


def main(argv=None):
    ap = argparse.ArgumentParser(description="Check 63 — count-vs-structure lint")
    ap.add_argument("--root", default=".")
    ap.add_argument("--path", action="append", default=[])
    ap.add_argument("--paths-from")
    ap.add_argument("--baseline", default="core/deploy/allowlists/count-structure-baseline.txt")
    ap.add_argument("--no-baseline", action="store_true")
    ap.add_argument("--no-exempt", action="store_true",
                    help="measurement aid: disable the frozen-artifact exemption")
    ap.add_argument("--include-inline", action="store_true",
                    help="opt-in, unmeasured-in-v1 inline-enumeration form")
    ap.add_argument("--emit-baseline", action="store_true")
    ap.add_argument("--output-format", choices=["tsv", "human"], default="human")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)

    if args.self_test:
        ok, detail = run_controls()
        print(f"self-test: controls {'PASS' if ok else 'FAIL'} — {detail}")
        return 0 if ok else 1

    root = os.path.abspath(args.root)
    try:
        paths, in_scope, requested = collect_paths(
            root, args.path, args.paths_from, apply_exempt=not args.no_exempt)
    except OSError as exc:
        print(f"INPUT-FAILURE: {exc}", file=sys.stderr)
        return 3
    # The zero-population guard USED to sit here and tested the path LIST rather than
    # the READS — so a directory argument, which produced a non-empty list and zero
    # reads, walked straight past it. It now sits below the read loop, where it can
    # test what was actually measured. That is the deeper check it was always meant
    # to be.

    baseline = {} if args.no_baseline else load_baseline(
        os.path.join(root, args.baseline) if not os.path.isabs(args.baseline) else args.baseline
    )

    controls_ok, controls_detail = run_controls()

    files_read = chars_read = pairs_examined = 0
    flags, knowns, seen_keys = [], [], set()
    read_paths, unreadable = set(), []
    for rel in paths:
        full = os.path.join(root, rel)
        try:
            with open(full, "r", encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError:
            # A read failure is RECORDED, never discarded. The bare `continue` that
            # used to sit here is what let a directory argument's IsADirectoryError
            # vanish and the run report a clean zero.
            unreadable.append(rel)
            continue
        files_read += 1
        read_paths.add(rel)
        chars_read += len(text)
        for pair in scan_text(text, rel, include_inline=args.include_inline):
            pairs_examined += 1
            if pair.reconciles() is not None:
                continue
            key = (pair.path, pair.sha1)
            seen_keys.add(key)
            if key in baseline:
                knowns.append((pair, baseline[key]))
            else:
                flags.append(pair)

    # ── Baseline reconciliation — SCOPE-RELATIVE. ────────────────────────────────
    # This used to be `[k for k in baseline if k not in seen_keys]`: the WHOLE
    # baseline reconciled against whatever this run happened to see, so every entry
    # outside the requested scope was looked for, not found, and reported STALE.
    # Four states now, and the load-bearing distinction is EXCLUDED vs STALE-by-
    # absence: a naive "STALE only for files we actually read" rule would silently
    # stop reporting a baseline row whose file was DELETED, which is the one thing
    # the ratchet exists to catch.
    stale, excluded, unmeasured = [], 0, 0
    for key in baseline:
        rel = key[0]
        if not in_scope(rel):
            excluded += 1                       # EXCLUDED — outside the request
        elif not os.path.exists(os.path.join(root, rel)):
            stale.append(key)                   # STALE — the row's file is gone
        elif rel in read_paths:
            if key not in seen_keys:
                stale.append(key)               # STALE — pair removed or reconciles
        else:
            unmeasured += 1                     # UNMEASURED — never STALE
    baseline_in_scope = len(baseline) - excluded

    # ── Register A / Register B — consumed FROZEN from the degraded-state emit
    # contract (core/ADRs/ADR-134). No token is coined here. `truncated` and
    # `fixture` are deliberately unused rather than accidentally omitted: the reader
    # is an unbounded fh.read(), so no truncation state exists to report, and the
    # fixture harness drives real files through the ordinary path, so it has no
    # distinct provenance to declare.
    if files_read == 0:
        status, state = "not-run", "NOT-EVALUATED"
    elif unreadable:
        status, state = "degraded", "DEGRADED"
    else:
        status, state = "fetched", "-"

    scope_fields = (f"requested={requested} resolved={len(paths)} read={files_read} "
                    f"unreadable={len(unreadable)} unmeasured={unmeasured} "
                    f"baseline_in_scope={baseline_in_scope}")

    def emit_scope():
        """The SCOPE record, emitted BEFORE any counter so a consumer branches on
        whether the measurement HAPPENED before it reads a number. No `; ` appears in
        any state string — the human fields are ` — `-separated."""
        if args.output_format == "tsv":
            print(f"SCOPE\tstatus={status}\tstate={state}\trequested={requested}\t"
                  f"resolved={len(paths)}\tread={files_read}\t"
                  f"unreadable={len(unreadable)}\tunmeasured={unmeasured}\t"
                  f"baseline_in_scope={baseline_in_scope}")
        elif state == "-":
            print(f"scope:       status={status} — {scope_fields}")
        else:
            print(f"scope:       {state} — this is not a clean result — "
                  f"status={status} — {scope_fields}")

    # The zero-population guard, relocated from the path-list to the READS. A scope
    # that resolved to zero readable files is a malformed invocation — an INPUT
    # FAILURE, not a measurement outage — so it gates, and it emits a withheld
    # verdict instead of a clean summary.
    if status == "not-run":
        emit_scope()
        sys.stdout.flush()
        print("INPUT-FAILURE: the requested scope resolved to zero readable files — "
              "refusing to report a clean zero over an empty population (Rule 15)",
              file=sys.stderr)
        return 3

    if args.emit_baseline:
        rows = sorted({(p.path, p.sha1, f"pre-existing:{p.kind}") for p in flags} |
                      {(p.path, p.sha1, tag) for p, tag in knowns})
        for r in rows:
            print("\t".join(r))
        return 0

    emit_scope()
    if args.output_format == "tsv":
        print(f"DENOM\tfiles={files_read}\tchars={chars_read}\tpairs={pairs_examined}")
        print(f"CONTROL\t{'PASS' if controls_ok else 'FAIL'}\t{controls_detail}")
        for p in flags:
            print(f"FAIL\t{p.path}\t{p.line}\t{p.sha1}\t{p.kind}\t"
                  f"stated={','.join(map(str, p.stated))}\titems={p.items}\t{p.preamble[:160]}")
        for p, tag in knowns:
            print(f"KNOWN\t{p.path}\t{p.line}\t{p.sha1}\t{tag}\t"
                  f"stated={','.join(map(str, p.stated))}\titems={p.items}")
        for path, sha in stale:
            print(f"STALE\t{path}\t-\t{sha}\t-\t-\t-")
    else:
        print(f"denominator: files={files_read} chars={chars_read} pairs_examined={pairs_examined}")
        print(f"controls:    {'PASS' if controls_ok else 'FAIL'} — {controls_detail}")
        for p in flags:
            print(f"  FAIL:  {p.path}:{p.line} stated={p.stated} items={p.items} "
                  f"({p.kind}) — {p.preamble[:140]}")
        for p, tag in knowns:
            print(f"  KNOWN: {p.path}:{p.line} [{tag}] stated={p.stated} items={p.items}")
        for path, sha in stale:
            print(f"  STALE: {path} {sha} — baselined pair no longer present or now reconciles")
        print(f"summary: FAIL={len(flags)} KNOWN={len(knowns)} STALE={len(stale)}")

    if not controls_ok:
        return 1
    return 1 if flags else 0


if __name__ == "__main__":
    sys.exit(main())

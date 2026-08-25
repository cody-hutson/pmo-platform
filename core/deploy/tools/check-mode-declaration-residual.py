#!/usr/bin/env python3
"""check-mode-declaration-residual.py — Check 35's residual class, measured by an
oracle INDEPENDENT of Check 35's own recognizer (#4734, AC-10).

WHY THIS EXISTS, AND WHY ITS ZERO WOULD BE A BUG
------------------------------------------------
Check 35 asks whether a skill that DECLARES >=2 modes exposes a machine-recognizable
mode-enum. Its recognizer sees two declaration forms: a frontmatter `Modes:` token,
and delimiter-anchored `# Mode <ident><delim>` body headings. Skills that declare
their modes in some OTHER shape -- a natural-language sentence, or a `| Mode |`
table -- are invisible to it. They are not findings; they are simply outside the
scanned population, and nothing anywhere counted them.

The first attempt to count them defined the residual as "files carrying >=2
delimiter-anchored mode declarations the predicate does not place in scope". That is
EMPTY BY CONSTRUCTION on every possible corpus, because the predicate's own body-
heading arm IS that detector. It measured a recognizer's under-reach with the
recognizer under test, so it read 0, and the 0 was green, and the 0 was the defect.

A recognizer cannot measure its own under-reach. It can only find what it already
sees. So this instrument's two arms never look at a `#`-heading at all:

  Arm (i)  NATURAL-LANGUAGE CARDINAL -- a cardinal number followed by the word
           "modes", anywhere in the file, frontmatter included.
  Arm (ii) MODE-COLUMN TABLE -- a markdown table whose header carries a `Mode`
           column with >=2 distinct non-empty values.

Neither shares a shape with the recognizer. The oracle fires iff (i) OR (ii) fires.

THE EXIT CODE GRADES THE ORACLE, NOT THE RESIDUAL
-------------------------------------------------
A NON-ZERO residual is the EXPECTED, HEALTHY result. This script therefore does NOT
exit non-zero because the residual is non-zero -- it exits non-zero when a CONTROL
ARM is inconsistent, which is the only condition under which the residual number may
not be believed:

  * sensitivity 0        -- the oracle fires on nothing at all, so its zero on the
                           out-of-scope population would mean nothing either;
  * specificity fires    -- the oracle fires on the canonical single-mode skill, so
                           it is admitting non-declarations;
  * a mutation fixture   -- a planted multi-mode fixture does not fire, or a planted
    behaves wrongly        single-mode decoy does, so the oracle cannot discriminate.

A green run reporting residual 0 with all controls consistent would itself be the
signal that the oracle has been re-derived from the recognizer. Grade it as a
failure, not a pass.

SCOPE BOUNDARY -- READ BEFORE GRADING
-------------------------------------
This is a RESIDUAL detector, not a POPULATION detector. It deliberately does NOT see
the multi-mode skills that declare in the machine-recognizable forms -- those are IN
scope, so they are not residual. AC-10 must never be graded as "the oracle finds
every multi-mode skill"; that is a different question with a different answer.

SINGLE-ENGINE DISCIPLINE (CIAC-2)
---------------------------------
The scope partition needs Check 35's recognizer, and a hand-copied regex here would
drift from deploy.sh silently -- reproducing, in the instrument, the exact class of
defect the instrument exists to catch. The body-heading pattern is therefore LIFTED
FROM deploy.sh's source at run time and never restated; if it cannot be located the
script hard-fails rather than falling back to a copy. The frontmatter bound is
structural (between the opening `---` and its closing `---`) and is asserted against
the presence of deploy.sh's shared `_skill_fm_decl_line` extractor.

USAGE / EXIT CODES
------------------
  check-mode-declaration-residual.py            measure and report (default)
  check-mode-declaration-residual.py --self-test  hermetic fixture + arm-liveness suite

  0  oracle consistent -- residual reported (a non-zero residual is expected)
  1  a control arm is inconsistent -- the oracle is broken, do not trust its count
  3  contract failure -- deploy.sh or its recognizer could not be resolved
"""

import glob
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DEPLOY_SH = REPO_ROOT / "core" / "deploy" / "deploy.sh"

SKILL_GLOBS = (
    "operations/skills/*/SKILL.md",
    "release/skills/*/SKILL.md",
    "core/skills/*/SKILL.md",
)

# The canonical single-mode skill: prose naming a section, declaring nothing. It is
# the specificity arm because it is the exact file whose misclassification this whole
# repair exists to stop, and an oracle that fires on it is admitting non-declarations.
SPECIFICITY_FILE = "core/skills/adr-helper/SKILL.md"

# --- Arm (i): natural-language cardinal --------------------------------------------
# Deliberately NOT anchored to a heading, a key, or a position. Frontmatter included.
NL_CARDINAL_RE = re.compile(
    r"\b(?:two|three|four|five|six|seven|eight|nine|ten|[2-9]|1[0-9])\s+modes\b",
    re.IGNORECASE,
)

# --- Arm (ii): Mode-column markdown table ------------------------------------------
DELIM_CELL_RE = re.compile(r"^:?-{2,}:?$")
CELL_DECORATION_RE = re.compile(r"[*`_]")

# --- deploy.sh recognizer lift (CIAC-2) --------------------------------------------
# The body-heading ERE as deploy.sh spells it, inside the shared engine. Located by
# the surrounding grep invocation rather than by line number.
DEPLOY_D2_LIFT_RE = re.compile(r"grep -oE '(\^#\{[0-9],[0-9]\} Mode [^']*)'")
DEPLOY_FM_EXTRACTOR = "_skill_fm_decl_line() {"


# ------------------------------------------------------------------------------------
# oracle arms
# ------------------------------------------------------------------------------------
def split_table_row(line):
    s = line.strip()
    if not s.startswith("|"):
        return None
    s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return s.split("|")


def is_delimiter_row(line):
    cells = split_table_row(line)
    if not cells:
        return False
    stripped = [c.strip() for c in cells]
    if not any(stripped):
        return False
    return all(DELIM_CELL_RE.match(c) for c in stripped if c)


def normalise_header(cell):
    return CELL_DECORATION_RE.sub("", cell).strip()


def mode_tables(text):
    """Every `Mode`-headed column in `text`, as a list of distinct-value sets.

    Returned for EVERY such table, including those below the >=2 threshold, so the
    caller can prove the arm is neither inert nor over-reaching.
    """
    lines = text.split("\n")
    found = []
    i = 0
    while i < len(lines) - 1:
        header_cells = split_table_row(lines[i])
        if header_cells and is_delimiter_row(lines[i + 1]):
            col = None
            for idx, cell in enumerate(header_cells):
                if normalise_header(cell).lower() == "mode":
                    col = idx
                    break
            if col is not None:
                values = []
                j = i + 2
                while j < len(lines):
                    row = split_table_row(lines[j])
                    if not row:
                        break
                    if col < len(row):
                        v = normalise_header(row[col])
                        if v:
                            values.append(v)
                    j += 1
                found.append(set(values))
                i = j
                continue
            i += 2
            continue
        i += 1
    return found


def arm_nl(text):
    return bool(NL_CARDINAL_RE.search(text))


def arm_table(text):
    return any(len(vals) >= 2 for vals in mode_tables(text))


def oracle(text):
    """Fires iff arm (i) OR arm (ii) fires. Never inspects a `#`-heading."""
    return arm_nl(text) or arm_table(text)


# ------------------------------------------------------------------------------------
# scope partition -- Check 35's recognizer, LIFTED from deploy.sh, never restated
# ------------------------------------------------------------------------------------
def load_recognizer():
    if not DEPLOY_SH.is_file():
        die(3, f"deploy.sh not found at {DEPLOY_SH}")
    src = DEPLOY_SH.read_text(encoding="utf-8", errors="replace")
    if DEPLOY_FM_EXTRACTOR not in src:
        die(
            3,
            f"deploy.sh carries no `{DEPLOY_FM_EXTRACTOR.rstrip(' {')}` extractor — the "
            "frontmatter bound this instrument assumes is not the one deploy.sh "
            "enforces. Reconcile before trusting any number below.",
        )
    m = DEPLOY_D2_LIFT_RE.search(src)
    if not m:
        die(
            3,
            "could not lift Check 35's body-heading recognizer from deploy.sh. A "
            "hand-copied fallback is deliberately NOT provided: a copy that drifts "
            "from the predicate reproduces, in this instrument, the defect it exists "
            "to catch.",
        )
    ere = m.group(1)
    # POSIX ERE -> Python: the only construct that differs here is [[:space:]].
    return re.compile(ere.replace("[[:space:]]", "[ \\t]")), ere


def frontmatter_body(lines):
    if not lines or not re.match(r"^---[ \t]*$", lines[0]):
        return []
    for i in range(1, len(lines)):
        if re.match(r"^---[ \t]*$", lines[i]):
            return lines[1:i]
    return []


def in_scope(text, d2_re):
    lines = text.split("\n")
    idents = {m.group(0) for m in (d2_re.match(ln) for ln in lines) if m}
    decl = next((ln for ln in frontmatter_body(lines) if "Modes:" in ln), "")
    return bool(decl) or len(idents) >= 2


# ------------------------------------------------------------------------------------
# fixtures -- planted, hermetic, and the only way a mutation arm can exist
# ------------------------------------------------------------------------------------
FIX_MULTI_NL = """---
name: planted-multi-nl
description: A planted fixture. Two modes are declared in prose here.
---
# Planted
It offers two modes and says so in a sentence.
"""

FIX_MULTI_TABLE = """---
name: planted-multi-table
description: A planted fixture declaring in a table.
---
# Planted

| Mode | Purpose |
|---|---|
| Alpha | first |
| Beta | second |
| Gamma | third |
"""

# The decoy that matters most: a SINGLE-mode file carrying failure-mode prose. That
# is the exact shape that caused the original defect, so an oracle that fires here is
# reproducing it.
FIX_SINGLE_FM_PROSE = """---
name: planted-single-failuremode
description: A planted single-mode fixture.
---
# Planted
## Mode: Only — the one mode
## Domain-Specific Failure Modes: computing the max from a stale subset
See also § Domain-Specific Failure Modes: nothing is declared by that phrase.
"""

# A one-row `| Mode |` table: the table arm must require >=2 DISTINCT values, not
# merely the presence of a Mode-headed column.
FIX_SINGLE_ONE_ROW_TABLE = """---
name: planted-single-onerow
description: A planted single-mode fixture with a one-row table.
---
# Planted

| Mode | Purpose |
|---|---|
| Solo | the only one |
"""

MUTATION_FIXTURES = (
    ("multi-mode, natural language", FIX_MULTI_NL, True),
    ("multi-mode, | Mode | table", FIX_MULTI_TABLE, True),
    ("single-mode + failure-mode prose", FIX_SINGLE_FM_PROSE, False),
    ("single-mode + 1-row | Mode | table", FIX_SINGLE_ONE_ROW_TABLE, False),
)


# ------------------------------------------------------------------------------------
def die(code, msg):
    sys.stderr.write(f"check-mode-declaration-residual: {msg}\n")
    sys.exit(code)


def population():
    files = []
    for g in SKILL_GLOBS:
        files.extend(sorted(glob.glob(str(REPO_ROOT / g))))
    return files


def rel(p):
    return os.path.relpath(p, REPO_ROOT)


def run_mutation_arm():
    """Returns (ok, rows). The arm the first AC-10 could not have had."""
    rows, ok = [], True
    for label, body, expect in MUTATION_FIXTURES:
        got = oracle(body)
        good = got == expect
        ok = ok and good
        rows.append((label, expect, got, good))
    return ok, rows


def cmd_self_test():
    print("check-mode-declaration-residual --self-test")
    failures = []

    # (1) contract: the recognizer must be liftable from deploy.sh.
    d2_re, ere = load_recognizer()
    print(f"  [ok] recognizer lifted from deploy.sh: {ere}")

    # (2) arm liveness, per arm, each against its own decoy. An arm that cannot be
    #     shown to fire AND to stay silent is not an arm, it is a constant.
    arm_cases = (
        ("arm (i) NL", arm_nl, "It offers three modes.", "It offers a single mode."),
        ("arm (ii) table", arm_table, FIX_MULTI_TABLE, FIX_SINGLE_ONE_ROW_TABLE),
    )
    for name, fn, pos, neg in arm_cases:
        if not fn(pos):
            failures.append(f"{name} did not fire on its positive — the arm is inert")
        if fn(neg):
            failures.append(f"{name} fired on its decoy — the arm over-reaches")
        print(f"  [{'ok' if fn(pos) and not fn(neg) else 'FAIL'}] {name}: positive fires, decoy silent")

    # (3) mutation arm over all four planted fixtures.
    ok, rows = run_mutation_arm()
    for label, expect, got, good in rows:
        print(f"  [{'ok' if good else 'FAIL'}] mutation: {label} — expected {expect}, got {got}")
    if not ok:
        failures.append("mutation arm: a planted fixture was misclassified")

    # (4) the table arm must distinguish >=2 distinct from >=2 rows of one value.
    dup = "| Mode | X |\n|---|---|\n| Same | a |\n| Same | b |\n"
    if arm_table(dup):
        failures.append("table arm counted repeated values as distinct")
    print(f"  [{'ok' if not arm_table(dup) else 'FAIL'}] table arm counts DISTINCT values, not rows")

    if failures:
        for f in failures:
            sys.stderr.write(f"  FAIL: {f}\n")
        sys.stderr.write(f"self-test FAILED ({len(failures)} failure(s))\n")
        return 1
    print("self-test PASSED")
    return 0


def cmd_measure():
    d2_re, ere = load_recognizer()
    files = population()
    if not files:
        die(3, "skill population is empty — the glob resolved nothing; nothing is measurable")

    residual, sensitive, scoped = [], [], 0
    spec_fired = None
    table_census = []
    for p in files:
        text = Path(p).read_text(encoding="utf-8", errors="replace")
        fires = oracle(text)
        scoped_here = in_scope(text, d2_re)
        if scoped_here:
            scoped += 1
            if fires:
                sensitive.append(rel(p))
        elif fires:
            residual.append(rel(p))
        if rel(p) == SPECIFICITY_FILE:
            spec_fired = fires
        for vals in mode_tables(text):
            table_census.append((rel(p), len(vals)))

    print(f"recognizer (lifted from deploy.sh): {ere}")
    print(f"population: {len(files)} SKILL.md across {len(SKILL_GLOBS)} module globs")
    print(f"in scope:   {scoped}")
    print("")
    print(f"RESIDUAL {len(residual)}  — skills declaring >=2 modes OUTSIDE the scanned population")
    for r in residual:
        print(f"  {r}")
    if not residual:
        print("  (none)")
    print("")
    print("controls — the exit code below grades THESE, not the residual count")
    print(f"  sensitivity : {len(sensitive)} in-scope file(s) fire the oracle  (must be > 0)")
    print(f"  specificity : {SPECIFICITY_FILE} fires = {spec_fired}  (must be False)")
    ok_mut, rows = run_mutation_arm()
    for label, expect, got, good in rows:
        print(f"  mutation    : {label} — expected {expect}, got {got} {'ok' if good else 'FAIL'}")
    print(f"  table census: {len(table_census)} `| Mode |` table(s); "
          f"{sum(1 for _, n in table_census if n < 2)} below the >=2-distinct threshold")

    broken = []
    if len(sensitive) == 0:
        broken.append("sensitivity arm is 0 — the oracle fires on nothing, so its zeros mean nothing")
    if spec_fired is None:
        broken.append(f"specificity file {SPECIFICITY_FILE} is absent from the population")
    elif spec_fired:
        broken.append(f"specificity arm fired on {SPECIFICITY_FILE} — the oracle admits non-declarations")
    if not ok_mut:
        broken.append("mutation arm misclassified a planted fixture — the oracle cannot discriminate")

    print("")
    if broken:
        for b in broken:
            sys.stderr.write(f"BROKEN ORACLE: {b}\n")
        sys.stderr.write("The residual count above must NOT be believed.\n")
        return 1
    print("oracle consistent — the residual count above is a measurement, not a definition.")
    print("A residual of 0 from a consistent oracle would mean the oracle was re-derived")
    print("from the recognizer; grade that as a failure, not a pass.")
    return 0


def main(argv):
    if "--self-test" in argv:
        return cmd_self_test()
    if len(argv) > 1 and argv[1] not in ("--self-test",):
        die(3, f"unknown argument: {argv[1]}")
    return cmd_measure()


if __name__ == "__main__":
    sys.exit(main(sys.argv))

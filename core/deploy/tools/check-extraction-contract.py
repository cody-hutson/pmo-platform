#!/usr/bin/env python3
"""check-extraction-contract.py — deploy.sh check-roster extraction-contract (#2106, Check 57).

Asserts, ENTIRELY INSIDE deploy.sh, that the check roster is discoverable two ways
that agree. `core/rules/skill-deployment.md` publishes a single-source-of-truth
extraction command —

    grep -oE 'log "Check [0-9]+[:.]?[^"]*' core/deploy/deploy.sh

— whose correctness silently depends on TWO deploy.sh conventions holding for every
check: (1) a runtime `log "Check N: <label>"` EMITTER line, and (2) a `# Check N`
DEFINITION-BLOCK comment. A check that follows one convention but not the other makes
the documented command under- or over-report, and the doc's "single source of truth"
claim quietly becomes false — with no enumeration anywhere to visibly drift.

RE-SCOPE PROVENANCE (#2106 operator decision D-C, 2026-07-19)
------------------------------------------------------------
The ORIGINAL #2106 asked for a parity check between deploy.sh and a hand-maintained
check ENUMERATION in skill-deployment.md, plus a machine-marker on that enumeration.
That enumeration no longer exists: commit f0a0516 (#2095) REMOVED it in favour of the
derive-from-source pointer above. Re-adding a marker would re-create the exact
duplicate surface #2095 eliminated (a register-or-remove violation). This check
therefore asserts the contract inside deploy.sh with NO skill-deployment.md edit and
NO re-introduced enumeration — preserving the anti-drift intent, honoring the removal.

THE CONTRACT
------------
Let D = {N : a `# Check N` definition-block header exists}
    R = {N in D : its header line is marked RETIRED}   (retired-reserved numbers)
    E = {N : a `log "Check N:" emitter exists}

The invariant is  E == (D \\ R).  Three violation classes:

  MISSING_EMITTER   N in (D \\ R) but not in E — a live check with a definition block
                    but no runtime log line → INVISIBLE to the documented command.
  MISSING_DEFBLOCK  N in E but not in D — a check that logs but carries no definition
                    block → the doc's "each check's # Check N comment" promise fails.
  RETIRED_EMITTING  N in (R ∩ E) — a number marked RETIRED that still emits a live
                    log line → the reservation is contradicted.

WHY RETIRED NUMBERS ARE EXEMPT FROM MISSING_EMITTER
---------------------------------------------------
A retired-reserved check (15, 24 live) keeps its `# ─── Check N: … — RETIRED …`
definition block for citation continuity but DELIBERATELY emits no log line. Without
the R carve-out the contract would false-FAIL on exactly the numbers the corpus
retired on purpose. Retirement is detected structurally — "RETIRED" on the
definition-block header line — never hardcoded.

SELF-REFERENTIAL BY DESIGN (CIAC-2)
-----------------------------------
This check (57) has its own `# Check 57` definition block and `log "Check 57:"`
emitter, so it is the first test datum for the contract it guards. The Wave-A checks
55/56 added in the same release are the next.

OUTPUT (TSV) / EXIT CODES
-------------------------
  DEFBLOCKS       <n>
  RETIRED         <comma-list>
  EMITTERS        <n>
  MISSING_EMITTER   <N>   # def-block, not retired, no emitter
  MISSING_DEFBLOCK  <N>   # emitter, no def-block
  RETIRED_EMITTING  <N>   # retired number still emitting
  COUNT           <n>     # total violations

  exit 0 — contract holds
  exit 1 — violation(s) present
  exit 3 — input failure (deploy.sh unreadable / zero checks discovered)

Python 3.9-compatible — matches /usr/bin/python3 on the operator baseline.
"""

import argparse
import os
import re
import sys

# Definition-block header — the TWO forms deploy.sh actually uses, no third:
#   em-dash:  `# Check N — <label>`
#   box:      `# ─── Check N: <label> ───`
# A prose mention of "Check N" mid-comment is NOT a header (no leading `# Check`/
# `# ─── Check` + the N-terminating delimiter), so it is not miscounted.
DEFBLOCK_RE = re.compile(r'^\s*#\s*(?:─── )?Check (\d+)\s*(?:—|:)')

# Runtime emitter — mirrors the documented command's `log "Check [0-9]+` anchor.
EMITTER_RE = re.compile(r'log "Check (\d+)')

RETIRED_MARK = "RETIRED"


def parse_deploy(text):
    """Return (defblocks:set[int], retired:set[int], emitters:set[int])."""
    defblocks, retired, emitters = set(), set(), set()
    for line in text.splitlines():
        m = DEFBLOCK_RE.match(line)
        if m:
            n = int(m.group(1))
            defblocks.add(n)
            if RETIRED_MARK in line:
                retired.add(n)
        e = EMITTER_RE.search(line)
        if e:
            emitters.add(int(e.group(1)))
    return defblocks, retired, emitters


def evaluate(defblocks, retired, emitters):
    """The three violation classes. Pure — the self-test drives it directly."""
    live = defblocks - retired
    missing_emitter = sorted(live - emitters)      # def-block, not retired, no emitter
    missing_defblock = sorted(emitters - defblocks)  # emitter, no def-block
    retired_emitting = sorted(retired & emitters)   # retired but still emitting
    return missing_emitter, missing_defblock, retired_emitting


# ── self-test ───────────────────────────────────────────────────────────────

def self_test():
    results = []

    def check(name, ok):
        results.append((name, ok))

    CLEAN = (
        '  # Check 1 — Skill sync\n'
        '  log "Check 1: Skill sync"\n'
        '  # ─── Check 2: Package sync ───\n'
        '  log "Check 2: Package sync"\n'
        '  # ─── Check 15: Old scan — RETIRED in v2 ──\n'   # retired: def-block, no emitter
    )
    d, r, e = parse_deploy(CLEAN)
    me, md, re_ = evaluate(d, r, e)
    check("clean roster (incl. retired 15) → no violation",
          (me, md, re_) == ([], [], []))
    check("retired 15 parsed as retired", r == {15})
    check("emitters exclude retired", e == {1, 2})

    # MISSING_EMITTER: a live def-block with no log line.
    d, r, e = parse_deploy('  # Check 9 — Orphan def\n')
    me, md, re_ = evaluate(d, r, e)
    check("MISSING_EMITTER fires on def-block without emitter", me == [9])

    # MISSING_DEFBLOCK: an emitter with no def-block.
    d, r, e = parse_deploy('  log "Check 9: Orphan emitter"\n')
    me, md, re_ = evaluate(d, r, e)
    check("MISSING_DEFBLOCK fires on emitter without def-block", md == [9])

    # RETIRED_EMITTING: a retired number that still logs.
    d, r, e = parse_deploy(
        '  # ─── Check 15: Old — RETIRED in v2 ──\n'
        '  log "Check 15: zombie"\n')
    me, md, re_ = evaluate(d, r, e)
    check("RETIRED_EMITTING fires on retired number with emitter", re_ == [15])

    # Sub-letter emitter (Check 13b) collapses to its integer 13.
    d, r, e = parse_deploy(
        '  # Check 13 — Registry\n'
        '  log "Check 13: Registry"\n'
        '  log "Check 13b: Shared-reference collision"\n')
    me, md, re_ = evaluate(d, r, e)
    check("sub-letter emitter (13b) collapses to 13; no false violation",
          (me, md, re_) == ([], [], []) and e == {13})

    # Prose mentions of "Check N" are NOT def-block headers (the false-positive
    # risk a naive `grep "Check N"` would hit). Two shapes, both must yield no
    # def-block:
    #   (a) "Check N" not at the `# Check` header position;
    #   (b) `# Check N <word>` with no —/: delimiter after the number.
    d, _, _ = parse_deploy('  # See Check 99 for the downstream consumer\n')
    check("'# See Check N …' prose is not a def-block header", d == set())
    d, _, _ = parse_deploy('  # Check 8 only sees downstream output\n')
    check("'# Check N <word>' without —/: delimiter is not a header", d == set())

    failed = [n for n, ok in results if not ok]
    for name, ok in results:
        print(("  PASS  " if ok else "  FAIL  ") + name)
    print("self-test: %d/%d passed" % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


def main():
    ap = argparse.ArgumentParser(description="deploy.sh extraction-contract validity (#2106).")
    ap.add_argument("--deploy-sh", default="core/deploy/deploy.sh",
                    help="path to deploy.sh (the extraction command's own target)")
    ap.add_argument("--root", default=".", help="repo root (deploy-sh resolved under it)")
    ap.add_argument("--output-format", choices=("tsv",), default="tsv")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    path = args.deploy_sh
    if not os.path.isabs(path):
        path = os.path.join(os.path.abspath(args.root), path)
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError as exc:
        print("ERROR\tdeploy.sh unreadable: " + str(exc), file=sys.stderr)
        return 3

    defblocks, retired, emitters = parse_deploy(text)
    if not defblocks and not emitters:
        # Fail loud — a zero-check parse means the conventions moved and the whole
        # contract is unverifiable; never read green.
        print("ERROR\tzero checks discovered — the # Check / log \"Check\" "
              "conventions may have changed; extraction contract unverifiable",
              file=sys.stderr)
        return 3

    missing_emitter, missing_defblock, retired_emitting = evaluate(
        defblocks, retired, emitters)

    out = [
        "DEFBLOCKS\t" + str(len(defblocks)),
        "RETIRED\t" + ",".join(str(n) for n in sorted(retired)),
        "EMITTERS\t" + str(len(emitters)),
    ]
    for n in missing_emitter:
        out.append("MISSING_EMITTER\t" + str(n))
    for n in missing_defblock:
        out.append("MISSING_DEFBLOCK\t" + str(n))
    for n in retired_emitting:
        out.append("RETIRED_EMITTING\t" + str(n))
    total = len(missing_emitter) + len(missing_defblock) + len(retired_emitting)
    out.append("COUNT\t" + str(total))
    print("\n".join(out))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())

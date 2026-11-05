#!/usr/bin/env python3
"""_epic_child_set.py — the ONE home of the epic child-set rule (G1a) for the
release-tool family.

An epic's children are its native sub-issues UNION the issues linked to it by an
`epic:<slug>` label, with the carrier epic excluded from its own child set. Both
mechanisms are read because they are not kept in sync: a native-only read misses
open label-linked work. The carrier is excluded because the taxonomy applies the
`epic:<slug>` label to the umbrella ticket as well as its children, so left in, an
epic is its own perpetually-open child and can never complete.

Two consumers load this module BY PATH (importlib.util.spec_from_file_location)
from their own directory, so a static-import grep under-reports the consumer set:

  * audit-epic-rollup-close.sh — its classify step, which decides whether every
    child of an open epic has closed;
  * compute-chain-head-rollup.py — the chain-head view, which draws an epic's
    children and its completion count from the same set.

The rule used to live inline in the audit, inside a single-quoted `python3 -c`
program that no second consumer could load, so a second reader would have had to
copy it. It lives here instead so the two readers can never disagree on what an
epic's children are.

Contract: child_set() is pure — no network, no file I/O, no clock. Rows are dicts
carrying at least a "number" key; every other key is carried through untouched.
A native row wins over a label row for the same number. When one mechanism lists a
number twice, the later row wins, as a dict built from the rows would.

Python 3.9, stdlib only.

Usage:
  python3 release/tools/_epic_child_set.py --self-test
  python3 release/tools/_epic_child_set.py --help

Exit codes: 0 = self-test passed (or --help); 1 = a self-test assertion failed;
2 = usage error.
"""

import sys
from typing import Dict, Iterable, Tuple

Row = Dict[str, object]


def child_set(epic_number: int, native_rows: Iterable[Row],
              label_rows: Iterable[Row]) -> Tuple[Dict[int, Row], Dict[int, Row]]:
    """Return (native, label_only), each {number: row}.

    native     — the epic's native sub-issues, the carrier excluded.
    label_only — the label-linked issues that are neither the carrier nor already
                 a native child.

    The union is {**native, **label_only}; the two never share a key.
    """
    native: Dict[int, Row] = {}
    for row in native_rows:
        number = row["number"]
        if number != epic_number:
            native[number] = row
    label_only: Dict[int, Row] = {}
    for row in label_rows:
        number = row["number"]
        if number == epic_number or number in native:
            continue
        label_only[number] = row
    return native, label_only


def union(native: Dict[int, Row], label_only: Dict[int, Row]) -> Dict[int, Row]:
    """The full child set: native children plus label-only children."""
    merged = dict(native)
    merged.update(label_only)
    return merged


def _self_test() -> int:
    failures = []

    def check(label: str, got, want) -> None:
        if got == want:
            print("  ok   " + label)
        else:
            print("  FAIL %s — expected %r, got %r" % (label, want, got), file=sys.stderr)
            failures.append(label)

    print("_epic_child_set.py --self-test (offline; no I/O)")

    # ST-1 — the carrier self-labels: the label query returns the epic itself, open.
    # It must not be counted as its own child (the audit's fixture 6).
    native, label_only = child_set(
        6,
        [{"number": 61, "state": "closed"}],
        [{"number": 6, "state": "open"}, {"number": 61, "state": "closed"}],
    )
    check("ST-1 carrier self-label excluded", sorted(union(native, label_only)), [61])
    check("ST-1 the native child is not re-counted as label-only", sorted(label_only), [])

    # ST-2 — an open child linked by label only must join the set; a native-only
    # read would miss it (the audit's fixture 7).
    native, label_only = child_set(
        7,
        [{"number": 71, "state": "closed"}],
        [{"number": 72, "state": "open"}],
    )
    check("ST-2 label-only open child included", sorted(union(native, label_only)), [71, 72])
    check("ST-2 it is counted as label-only", sorted(label_only), [72])

    # ST-3 — a number present in both mechanisms is carried by its native row.
    native, label_only = child_set(
        3,
        [{"number": 31, "via": "native"}],
        [{"number": 31, "via": "label"}],
    )
    check("ST-3 native row wins on a duplicate", union(native, label_only)[31]["via"], "native")

    # ST-4 — no rows at all is two empty sets, never an error.
    check("ST-4 empty input -> ({}, {})", child_set(4, [], []), ({}, {}))

    # Control — the carrier guard is what ST-1 measures: the same rows with a
    # different epic number keep the issue that ST-1 drops.
    native, label_only = child_set(
        99,
        [{"number": 61, "state": "closed"}],
        [{"number": 6, "state": "open"}, {"number": 61, "state": "closed"}],
    )
    check("ST-1 control: a non-carrier epic keeps that issue", sorted(union(native, label_only)), [6, 61])

    if failures:
        print("_epic_child_set.py --self-test: FAIL (%d assertion(s))" % len(failures), file=sys.stderr)
        return 1
    print("_epic_child_set.py --self-test: PASS")
    return 0


def main(argv) -> int:
    if argv == ["--self-test"]:
        return _self_test()
    if argv in (["--help"], ["-h"]):
        print(__doc__)
        return 0
    print("usage: _epic_child_set.py --self-test | --help (this module is loaded by path, "
          "not run)", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

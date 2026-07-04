#!/usr/bin/env python3
"""Fixture-based regression tests for av-verify.py (QC4-05 region-scoped AV).

Companion to the tool's built-in ``--self-test`` (which exercises the evaluator
on in-memory strings). This suite drives the tool **end to end against on-disk
fixture files** so extension resolution, file reading, and the exit-code contract
are exercised exactly as Stage-13 Phase A4 will invoke them.

Coverage (per #99 Stage-5 design + the M-1 fenced-block operator lock):
  * The website-raw AC-2 scenario — the forbidden token appears only inside a
    disclaiming comment (both an HTML comment in ``.md`` and a ``//`` comment in
    ``.js``). ``region: code, polarity: absent`` must return the CORRECT verdict
    (PASS), where the old whole-file grep false-FAILed.
  * The symmetric false-PASS guard — a token genuinely present in code must
    ``FAIL`` an ``absent`` assertion (a real violation is not missed).
  * ``.md`` fenced-block edge cases — info-string, indented, and nested/adjacent
    fences are excluded from the code view (full ``.md`` soundness, M-1).
  * The ``region: any`` grep-equivalence anchor — the whole-file path still
    matches the comment token (AC-4 synthetic regression: 'any' == old grep).

Run:  python3 release/tools/tests/test_av_verify.py
Exit: 0 = all cases pass, 1 = one or more assertions failed.
"""

import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL_PATH = os.path.join(HERE, os.pardir, "av-verify.py")
FIXTURES = os.path.join(HERE, "fixtures")


def load_tool():
    spec = importlib.util.spec_from_file_location("av_verify", TOOL_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# Each case: (label, fixture-filename, pattern, region, polarity,
#             expect_verdict, expect_exit)
CASES = [
    # --- The #99 false-FAIL fix: token only in a disclaiming comment/fence. ---
    ("md-disclaimer-code-absent", "av-comment-disclaimer.md",
     r"localStorage", "code", "absent", "PASS", 0),
    ("js-disclaimer-code-absent", "av-comment-disclaimer.js",
     r"localStorage", "code", "absent", "PASS", 0),

    # --- Symmetric false-PASS guard: token genuinely in code → absent FAILs. ---
    ("js-violation-code-absent", "av-code-violation.js",
     r"localStorage", "code", "absent", "FAIL", 1),
    # ...and the same file: present-in-code assertion PASSes (token IS in code).
    ("js-violation-code-present", "av-code-violation.js",
     r"localStorage", "code", "present", "PASS", 0),

    # --- Markdown fenced-block edge cases (M-1): fenced content excluded. ---
    ("md-fenced-infostring-code-absent", "av-fenced-info-string.md",
     r"localStorage", "code", "absent", "PASS", 0),
    ("md-fenced-indented-code-absent", "av-fenced-indented.md",
     r"localStorage", "code", "absent", "PASS", 0),
    ("md-fenced-nested-code-absent", "av-fenced-nested.md",
     r"localStorage", "code", "absent", "PASS", 0),

    # --- region:any grep-equivalence anchor (AC-4): comment token DOES match. ---
    ("md-disclaimer-any-absent-grep-equiv", "av-comment-disclaimer.md",
     r"localStorage", "any", "absent", "FAIL", 1),
    ("js-disclaimer-any-absent-grep-equiv", "av-comment-disclaimer.js",
     r"localStorage", "any", "absent", "FAIL", 1),

    # --- Comment-view visibility: the token IS present in the comment/fence. ---
    ("md-disclaimer-comment-present", "av-comment-disclaimer.md",
     r"localStorage", "comment", "present", "PASS", 0),
]


def main():
    mod = load_tool()
    failures = []

    for label, fname, pattern, region, polarity, exp_verdict, exp_exit in CASES:
        target = os.path.join(FIXTURES, fname)
        if not os.path.isfile(target):
            failures.append("%s: fixture missing: %s" % (label, target))
            continue
        code, result = mod.run_assertion(target, pattern, region, polarity,
                                         av_id="AV-test")
        if result["verdict"] != exp_verdict:
            failures.append(
                "%s: verdict %s != expected %s (matched=%r)"
                % (label, result["verdict"], exp_verdict, result["matched_lines"])
            )
        if code != exp_exit:
            failures.append(
                "%s: exit %d != expected %d" % (label, code, exp_exit)
            )

    print("av-verify fixture regression: N=%d case(s)" % len(CASES))
    print("  website-raw AC-2 (comment-only token) + false-PASS guard + "
          "md fenced (info-string/indented/nested) + any-grep-equivalence")

    if failures:
        print("\nTEST FAIL:", file=sys.stderr)
        for f in failures:
            print("  - " + f, file=sys.stderr)
        return 1
    print("\nTEST OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())

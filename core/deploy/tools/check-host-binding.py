#!/usr/bin/env python3
"""check-host-binding.py — detect host-binding leaks in K1-tier governance.

A *host-binding leak* (per `core/disciplines/knowledge-architecture.md` §4.1) is a
host tool — `gh`, `git`, or a host API — hardcoded as *the* canonical mechanism
inside universal (K1) governance, where the operation in fact belongs behind the
`operator.toml [adapters]` seam (per `core/standards/repo-host-adapter-versioning.md`).
It is the host-axis sibling of the path-portability leakage class.

Signal-not-verdict contract: this primitive emits *candidate* lines where a
host-tool token co-occurs with a prescriptive-mechanism marker, OUTSIDE fenced
code blocks, in non-allowlisted K1-tier files. The prescription-vs-teaching
adjudication (the §4.1 detection-signature exclusions: a reference adapter
documenting its binding; an illustrative / worked-example host command) is the
review act, NOT this scan — the discipline-defining files that legitimately
quote the pattern are allowlisted (a tracked allowlist), and worked examples in
fenced code blocks are skipped natively.

Usage:
  check-host-binding.py --target-paths "<comma-separated-globs>" \
      [--allowlist core/deploy/allowlists/skip-host-binding-check.txt]
  check-host-binding.py --self-test

Output (stdout): first line `FINDINGS\t<n>`, then one `path:line: text` per
candidate. Exit 0 = ran; exit 3 = a --target-paths glob resolved to zero files
(a relocated/typo'd scan surface — fail-loud, never a silent green).
"""
import argparse
import fnmatch
import glob
import os
import re
import sys

# A host-tool token: `gh` or `git` as a standalone word. The negative lookbehind
# keeps it from matching inside `GitHub` (no word-boundary after `git`), `digit`,
# a path like `core/rules/git-workflow.md`, or `.gitignore`.
_HOST = r'(?<![\w/.-])(?:gh|git)\b'

# Prescriptive-mechanism markers — the framing that turns a host-tool MENTION
# into a host-tool PRESCRIPTION (the canonical/only way to perform the operation).
_MARKER = (
    r'canonical mechanism'
    r'|version[- ]?claim mechanism'
    r'|claim the version by'
    r'|the only way to'
    r'|prescribed mechanism'
    r'|the mechanism (?:is|=|:)'
    r'|the way to (?:claim|push|merge|tag|release)'
)

# A candidate line requires a prescriptive marker AND a host token within ~40
# characters of each other (either order) with NO sentence break (`.`) between —
# so the host tool is the OBJECT of the prescription ("the mechanism is `git`"),
# not an unrelated later mention on the same line ("the mechanism is observable …
# the git-log heuristic"). This proximity bound is what keeps precision high.
COMBINED = re.compile(
    r'(?:(?:' + _MARKER + r')[^.\n]{0,40}?' + _HOST + r')'
    r'|(?:' + _HOST + r'[^.\n]{0,40}?(?:' + _MARKER + r'))',
    re.IGNORECASE,
)

FENCE = re.compile(r'^\s*(```|~~~)')


def scan_file(path):
    """Return [(lineno, text)] for candidate host-binding lines outside fences."""
    findings = []
    in_fence = False
    try:
        with open(path, encoding='utf-8') as fh:
            for n, line in enumerate(fh, 1):
                if FENCE.match(line):
                    in_fence = not in_fence
                    continue
                if in_fence:
                    continue
                if COMBINED.search(line):
                    findings.append((n, line.rstrip()))
    except (OSError, UnicodeDecodeError):
        pass
    return findings


def load_allowlist(path):
    pats = []
    if path and os.path.isfile(path):
        with open(path, encoding='utf-8') as fh:
            for ln in fh:
                ln = ln.strip()
                if ln and not ln.startswith('#'):
                    pats.append(ln)
    return pats


def is_allowlisted(path, pats):
    for p in pats:
        if p.endswith('/'):
            if path.startswith(p):
                return True
        elif fnmatch.fnmatch(path, p):
            return True
    return False


def self_test():
    """Positive cases must fire; negative cases must NOT (precision guard)."""
    cases = [
        # (text, should_flag)
        ("claim the version by pushing a signed `git` tag", True),
        ("the canonical mechanism is `gh api repos/{REPO}/releases/latest`", True),
        ("the version-claim mechanism: `gh release create`", True),
        # negatives — host token but no prescriptive framing (a mere mention)
        ("run `gh pr view` to check the merge status", False),
        ("host operations are provided by the repo-host adapter seam", False),
        ("see core/rules/git-workflow.md for the branch convention", False),
        # negatives — prescriptive framing but no host token (host-agnostic — correct)
        ("the canonical mechanism is the adapter's anchor() operation", False),
        # GitHub / digit / .gitignore must not match the HOST token
        ("GitHub Releases is the canonical mechanism for distribution", False),
        # proximity regression — marker + host on one line but in different clauses
        # (the live-scan false-positive this proximity bound eliminates)
        ("agents apply the principle via the git-log heuristic. The mechanism is observable from a derived signal", False),
    ]
    failures = []
    for text, expect in cases:
        got = bool(COMBINED.search(text))
        if got != expect:
            failures.append(f"  {'expected-flag' if expect else 'false-positive'}: {text!r} (got flag={got})")
    # fence toggling
    import tempfile
    with tempfile.NamedTemporaryFile('w', suffix='.md', delete=False) as tf:
        tf.write("prose: the canonical mechanism is `git tag`\n")   # flag (line 1)
        tf.write("```\nthe canonical mechanism is `git tag`\n```\n")  # fenced -> skip
        tf.write("more prose, no host here, the only way to win\n")   # no host -> skip
        tfp = tf.name
    fnds = scan_file(tfp)
    os.unlink(tfp)
    if [n for n, _ in fnds] != [1]:
        failures.append(f"  fence/scan test: expected only line 1, got {[n for n, _ in fnds]}")
    if failures:
        print("self-test FAILED:")
        print("\n".join(failures))
        return 1
    print("self-test OK (9 signature cases + fence/scan)")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Detect host-binding leaks in K1-tier governance.")
    ap.add_argument('--target-paths', default='', help='comma-separated globs (recursive ** supported)')
    ap.add_argument('--allowlist', default='', help='allowlist file (one path/glob per line; # comments)')
    ap.add_argument('--self-test', action='store_true')
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    pats = load_allowlist(args.allowlist)
    globs = [g.strip() for g in args.target_paths.split(',') if g.strip()]
    files = []
    any_zero = False
    for g in globs:
        matched = glob.glob(g, recursive=True)
        if not matched:
            any_zero = True
        files.extend(matched)
    if any_zero and not files:
        print("path-resolution failure: a --target-paths glob resolved to zero files", file=sys.stderr)
        return 3

    findings = []
    for f in sorted(set(files)):
        if not f.endswith('.md') or not os.path.isfile(f):
            continue
        if is_allowlisted(f, pats):
            continue
        for n, text in scan_file(f):
            findings.append(f"{f}:{n}: {text.strip()[:160]}")

    print(f"FINDINGS\t{len(findings)}")
    for fnd in findings:
        print(fnd)
    return 0


if __name__ == '__main__':
    sys.exit(main())

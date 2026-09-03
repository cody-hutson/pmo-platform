#!/usr/bin/env python3
"""The two inputs the behavioural-regression gate consumes, read and asserted.

WHY THIS EXISTS
---------------
The gate at `.github/workflows/behavioral-regression.yml` consumes exactly two things
that live outside its own YAML: a numeric floor recorded in the platform config, and a
tag glob that decides where it BINDS. Both are the kind of input a gate normally reads
and nobody ever checks.

    read-floor          resolve [behavioral_regression].pass_rate_floor, FAIL-CLOSED
    assert-tag-filter   grade the workflow's OWN tag glob against a committed
                        expected-match set, both directions

Both subcommands are invocable locally with no setup AND invoked by the CI job, so the
two surfaces measure the same thing. A filter asserted only by reading its glob is an
unverified filter, and the `v*.00` pattern is reachable only by a remote tag push —
without this arm, the day it stopped meaning what it says would pass unnoticed until a
major release failed to gate.

STDLIB ONLY, DELIBERATELY
-------------------------
No PyYAML, no tomllib. Two reasons, and the second is the load-bearing one:

  1. tomllib is 3.11+; the interpreter this repo is developed against locally is 3.9.
     A helper that cannot run locally cannot satisfy the invocable-locally half of the
     requirement above.
  2. A gate that can fail for want of a parser is a gate that fails for the WRONG
     reason. This runs on every pull request; its dependency surface should be empty.

The cost is honest and stated rather than hidden: the trigger read below is a
line-oriented scan, not a YAML parse. That is safe HERE and would not be safe in
general — the platform's own conformance ratchet
(`core/deploy/tests/test_gate_efficacy_declarations.py`) reads triggers structurally
precisely because a raw-text scan over an ARBITRARY workflow population over-counts
`paths:` occurrences in comments and `run:` bodies. This scan reads ONE file, authored
alongside it, anchored on that file's own `on:` block, and it REFUSES rather than
guesses: anything other than exactly one `tags:` list inside `on:` exits 2.

EXIT CONTRACT (shared by both subcommands)
------------------------------------------
    0  the input resolved / every boundary case graded as declared
    1  assert-tag-filter only: at least one case graded against its declaration
    2  the input could not be resolved, or the harness could not assert.
       FAIL-CLOSED — an unresolvable floor must never be read as zero, because a zero
       floor satisfies every `>=` comparison and would green the gate permanently.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

EXIT_OK = 0
EXIT_GRADED_FAIL = 1
EXIT_CANNOT_ASSERT = 2

CONFIG_REL = "core/config/platform-config.toml.template"
WORKFLOW_REL = ".github/workflows/behavioral-regression.yml"
CASES_REL = "core/disciplines/evals/behavioral-regression/fixtures/tag-boundary-cases.json"

CONFIG_SECTION = "behavioral_regression"
CONFIG_KEY = "pass_rate_floor"


def die(message: str, code: int = EXIT_CANNOT_ASSERT):
    sys.stderr.write(f"ERROR: {message}\n")
    raise SystemExit(code)


def repo_root() -> Path:
    """Walk up from THIS FILE to the checkout root.

    Anchored on the directory this script actually lives in and identified by a marker
    that must be there, rather than by counting `..` levels. A depth-counted anchor is
    the defect the check bank's ANC-01 exists to catch: it does not error when it
    overshoots, it resolves to SOME directory whose queries then return wrong answers
    that read as legitimate output.
    """
    for candidate in Path(__file__).resolve().parents:
        if (candidate / ".github" / "workflows").is_dir():
            return candidate
    die("no ancestor of this script contains .github/workflows — cannot locate the "
        "repository root")


# --------------------------------------------------------------------------- #
# read-floor
# --------------------------------------------------------------------------- #
def read_floor(root: Path) -> str:
    """Resolve the floor, SECTION-SCOPED, or exit 2.

    Section-scoped rather than a bare key grep: a naive scan for the key name would
    also match a commented mention or a same-named key in another section, and would
    then hand the gate a number from the wrong place. Comments are stripped before the
    key is read, so a commented-out assignment cannot resolve.
    """
    path = root / CONFIG_REL
    if not path.is_file():
        die(f"config template not readable at {CONFIG_REL}")

    in_section = False
    for raw in path.read_text(encoding="utf-8").splitlines():
        stripped = raw.strip()
        if stripped.startswith("#") or not stripped:
            continue
        if stripped.startswith("[") and stripped.endswith("]"):
            in_section = stripped[1:-1].strip() == CONFIG_SECTION
            continue
        if not in_section or "=" not in stripped:
            continue
        key, _, value = stripped.partition("=")
        if key.strip() != CONFIG_KEY:
            continue
        value = value.split("#", 1)[0].strip()
        try:
            numeric = float(value)
        except ValueError:
            die(f"[{CONFIG_SECTION}].{CONFIG_KEY} is {value!r}, which is not a number. "
                f"An unresolvable floor is UNRESOLVED, never zero.")
        if not 0.0 <= numeric <= 1.0:
            die(f"[{CONFIG_SECTION}].{CONFIG_KEY} is {numeric}, outside the declared "
                f"range [0.0, 1.0]")
        return value

    die(f"[{CONFIG_SECTION}].{CONFIG_KEY} not found in {CONFIG_REL}. The gate "
        f"FAILS CLOSED rather than defaulting: a zero floor would satisfy every "
        f">= comparison and report green forever.")


# --------------------------------------------------------------------------- #
# assert-tag-filter
# --------------------------------------------------------------------------- #
def extract_tag_globs(root: Path) -> list[str]:
    """The `on.push.tags` list, read out of the LIVE workflow file.

    Read from the workflow rather than restated here on purpose: an assertion against a
    second copy of the glob grades the copy, and the copy is exactly what drifts.
    """
    path = root / WORKFLOW_REL
    if not path.is_file():
        die(f"workflow not readable at {WORKFLOW_REL}")

    lines = path.read_text(encoding="utf-8").splitlines()

    # Locate the top-level `on:` block. Top-level == column 0, so a `on:` appearing
    # inside a comment or a run: body cannot be mistaken for it.
    start = None
    for index, line in enumerate(lines):
        if re.match(r"^on:\s*$", line):
            start = index + 1
            break
    if start is None:
        die(f"{WORKFLOW_REL} carries no top-level `on:` block")

    block: list[str] = []
    for line in lines[start:]:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if not line[:1].isspace():        # dedent to column 0 ends the block
            break
        block.append(line)

    tag_headers = [i for i, line in enumerate(block) if re.match(r"^\s*tags:\s*$", line)]
    if len(tag_headers) != 1:
        die(f"expected exactly one `tags:` list inside the `on:` block of "
            f"{WORKFLOW_REL}, found {len(tag_headers)}. Refusing to guess which one "
            f"the gate binds on.")

    header = tag_headers[0]
    indent = len(block[header]) - len(block[header].lstrip())
    globs: list[str] = []
    for line in block[header + 1:]:
        current_indent = len(line) - len(line.lstrip())
        if current_indent <= indent:
            break
        item = re.match(r"^\s*-\s*(.+?)\s*$", line)
        if not item:
            break
        globs.append(item.group(1).strip().strip("'\""))

    if not globs:
        die(f"the `tags:` list in {WORKFLOW_REL} is empty — the gate would bind at no "
            f"boundary at all")
    return globs


def glob_to_regex(glob: str) -> "re.Pattern[str]":
    """GitHub tag-filter glob semantics, NOT fnmatch semantics.

    The difference is load-bearing and is why fnmatch is not used: fnmatch's `*` matches
    a path separator, GitHub's does not. Under fnmatch the pattern `v*.00` would match
    `release/v4.00`, so the specificity arm that proves the filter is anchored to a bare
    version tag would pass vacuously.
    """
    out = ["^"]
    index = 0
    while index < len(glob):
        char = glob[index]
        if char == "*":
            if glob[index:index + 2] == "**":
                out.append(".*")
                index += 2
                continue
            out.append("[^/]*")
        elif char == "?":
            out.append("[^/]")
        else:
            out.append(re.escape(char))
        index += 1
    out.append("$")
    return re.compile("".join(out))


def assert_tag_filter(root: Path) -> int:
    globs = extract_tag_globs(root)
    patterns = [(g, glob_to_regex(g)) for g in globs]

    cases_path = root / CASES_REL
    if not cases_path.is_file():
        die(f"boundary-case fixture not readable at {CASES_REL}")
    try:
        cases = json.loads(cases_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        die(f"boundary-case fixture is not valid JSON: {exc}")

    must_match = cases.get("must_match") or []
    must_not_match = cases.get("must_not_match") or []
    if not must_match or not must_not_match:
        die("the boundary-case fixture must declare BOTH a non-empty must_match set "
            "and a non-empty must_not_match set. A one-sided arm cannot distinguish a "
            "correct filter from one that matches everything (or nothing).")

    print(f"tag glob(s) read from {WORKFLOW_REL}: {', '.join(globs)}")
    findings: list[str] = []

    for case in must_match:
        tag = case["tag"]
        if not any(pattern.match(tag) for _, pattern in patterns):
            findings.append(f"MUST MATCH but did not: {tag!r} — {case.get('why', '')}")
        else:
            print(f"  match     {tag}")

    for case in must_not_match:
        tag = case["tag"]
        hit = next((g for g, pattern in patterns if pattern.match(tag)), None)
        if hit:
            findings.append(
                f"MUST NOT MATCH but {hit!r} did: {tag!r} — {case.get('why', '')}"
            )
        else:
            print(f"  no match  {tag}")

    total = len(must_match) + len(must_not_match)
    if findings:
        sys.stderr.write(
            f"TAG FILTER ASSERTION FAILED: {len(findings)} of {total} boundary cases "
            f"graded against their declaration:\n"
        )
        for finding in findings:
            sys.stderr.write(f"  {finding}\n")
        return EXIT_GRADED_FAIL

    print(
        f"tag filter  : PASS -- {len(must_match)} must-match and "
        f"{len(must_not_match)} must-not-match cases all graded as declared"
    )
    return EXIT_OK


def main(argv=None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if len(argv) != 1 or argv[0] not in ("read-floor", "assert-tag-filter"):
        sys.stderr.write(
            "usage: gate_inputs.py {read-floor|assert-tag-filter}\n"
            "  read-floor         print [behavioral_regression].pass_rate_floor "
            "(exit 2 if unresolvable)\n"
            "  assert-tag-filter  grade the workflow's own tag glob against the "
            "committed boundary cases\n"
        )
        return EXIT_CANNOT_ASSERT

    root = repo_root()
    if argv[0] == "read-floor":
        print(read_floor(root))
        return EXIT_OK
    return assert_tag_filter(root)


if __name__ == "__main__":
    sys.exit(main())

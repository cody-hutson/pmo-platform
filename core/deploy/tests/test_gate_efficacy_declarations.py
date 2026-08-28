#!/usr/bin/env python3
"""Assert every workflow's `gate-efficacy:` header agrees with its own trigger.

WHAT THIS GUARDS, AND WHY IT EXISTS
-----------------------------------
`core/standards/gate-efficacy-standard.md` Requirement (b) obliges every workflow to
declare its skip semantics in a machine-greppable header, and § Verdict-Input Closure
makes `skip-semantics=absent-is-pass` a CLAIM ABOUT COVERAGE rather than a formality.
Two spellings of that claim exist and they are mutually exclusive:

    always-reports=yes            <=>  the workflow carries NO on.<event>.paths filter
    skip-semantics=absent-is-pass <=>  the workflow DOES carry one

Before this suite, nothing in the tree asserted that biconditional. The header and the
trigger were two independent strings that a reader kept in agreement by hand, so the
change that breaks the invariant — adding a `paths:` key without touching the header,
or deleting one and leaving `skip-semantics=absent-is-pass` behind — was exactly the
change no gate could see. A declaration nothing checks decays into a comment.

EXIT CONTRACT
-------------
    0  every workflow conforms AND the anti-vacuity harness passed
    1  at least one declared-vs-actual mismatch (or a workflow with no header)
    2  the harness itself could not assert — an unreadable population, a partition too
       small to build a mutation arm, or a mutation the detector failed to flag.
       Fail-closed: a probe that cannot demonstrate it discriminates reports 2 rather
       than the clean it can no longer distinguish from a real one.

THE HARNESS RUNS BY DEFAULT, ON EVERY INVOCATION — deliberately, and it is the whole
reason to trust the zero. A falsification harness behind a flag nothing passes runs
exactly once, at implementation, and thereafter certifies nothing. Every mutation arm
below is derived from the LIVE population at run time rather than from hardcoded
workflow names, so a rename cannot quietly empty it, and an empty partition is a
reported NOSET rather than a skipped arm.

Hermetic: reads the workflow files, mutates only in-memory copies, writes nothing.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - environment guard
    print("FAIL: PyYAML is required; the trigger read must be STRUCTURAL. "
          "A raw-text scan for 'paths:' over-counts comment and run:-body "
          "occurrences and would make this gate wrong rather than absent.",
          file=sys.stderr)
    sys.exit(2)

HEADER_RE = re.compile(r"^#\s*gate-efficacy:\s*(?P<fields>.*)$")
FILTER_KEYS = {"paths", "paths-ignore"}


def repo_root() -> Path:
    """Walk up to the checkout root. Anchored on the directory this suite reads, so
    relocating the suite cannot silently point it at nothing."""
    for candidate in Path(__file__).resolve().parents:
        if (candidate / ".github" / "workflows").is_dir():
            return candidate
    print("FAIL: no .github/workflows ancestor of this file", file=sys.stderr)
    sys.exit(2)


def parse_headers(text: str) -> list[tuple[int, dict[str, str]]]:
    """EVERY `gate-efficacy:` declaration in the file, as (1-based line, field map).

    EVERY ONE, NOT THE FIRST. A workflow may carry more than one declaration — one
    per job or per named gate — and in this tree two do (five declarations between
    them). The earlier reader returned on its first match, so those extra
    declarations were never graded: the suite reported agreement over a count of
    FILES while its reach was a count of DECLARATIONS, and injecting a contradictory
    field into a second declaration survived every arm in the harness. That is the
    same declared-vs-actual reach overstatement this suite exists to catch, arriving
    inside the catcher. The trigger is a FILE-level property, so every declaration in
    a file is graded against that one trigger; what varies per declaration is the
    claim, and each claim is now read.

    Split on the 2-or-more-space field layout rather than on whitespace: the compound
    posture token `required(warn-mode-initial)` must survive intact, and an earlier
    extraction that split on `\\w+` truncated it to `required` — a silent read of a
    DIFFERENT value than the file carries.

    The whole file is searched, not a leading window: at least one workflow in this
    tree carries its header behind a multi-line rationale block, and a windowed search
    reports it as header-less.
    """
    found: list[tuple[int, dict[str, str]]] = []
    for lineno, line in enumerate(text.splitlines(), 1):
        match = HEADER_RE.match(line.strip())
        if not match:
            continue
        fields: dict[str, str] = {}
        for token in re.split(r"\s{2,}", match.group("fields").strip()):
            if "=" in token:
                key, value = token.split("=", 1)
                fields[key.strip()] = value.strip()
        found.append((lineno, fields))
    return found


def has_path_filter(text: str) -> bool:
    """True iff any `on.<event>` block carries `paths:` or `paths-ignore:`.

    Structural, via a YAML parse. NOTE the `on` lookup: YAML 1.1 resolves a bare `on`
    key to the boolean True, so `doc["on"]` alone misses every workflow in this tree.
    """
    doc = yaml.safe_load(text)
    if not isinstance(doc, dict):
        raise ValueError("workflow did not parse to a mapping")
    triggers = doc.get("on", doc.get(True))
    if not isinstance(triggers, dict):
        return False
    return any(
        isinstance(cfg, dict) and (FILTER_KEYS & set(cfg))
        for cfg in triggers.values()
    )


def evaluate(
    sources: dict[str, str],
) -> tuple[list[str], list[str], list[str], int]:
    """Return (findings, filtered_names, filter_free_names, declaration_count).

    The fourth element is the REACH of this run — how many declarations were actually
    graded. It is returned rather than derived by the caller so the number the suite
    publishes and the number it graded are the same number, taken at the same place.
    A magnitude reported over a population it was not measured on is the defect this
    file guards; reporting `len(sources)` as a declaration count was that defect.
    """
    findings: list[str] = []
    filtered: list[str] = []
    filter_free: list[str] = []
    n_declarations = 0

    for name in sorted(sources):
        text = sources[name]
        try:
            filtered_now = has_path_filter(text)
        except Exception as exc:  # unparseable YAML is a finding, never a skip
            findings.append(f"{name}: trigger unreadable ({exc})")
            continue

        (filtered if filtered_now else filter_free).append(name)

        declarations = parse_headers(text)
        if not declarations:
            findings.append(
                f"{name}: no `gate-efficacy:` header — Requirement (b) obliges one on "
                f"every workflow"
            )
            continue

        # EVERY declaration is graded against the file's trigger — a differential over
        # the whole declaration set, not a spot check on its first member. The finding
        # is keyed by `file:line` so a mismatch on the third declaration in a file
        # points at the third declaration.
        for lineno, fields in declarations:
            n_declarations += 1
            site = f"{name}:{lineno}"
            if filtered_now:
                if fields.get("skip-semantics") != "absent-is-pass":
                    findings.append(
                        f"{site}: carries a paths filter but this declaration does not "
                        f"declare skip-semantics=absent-is-pass (got "
                        f"{fields.get('skip-semantics')!r})"
                    )
                if "always-reports" in fields:
                    findings.append(
                        f"{site}: carries a paths filter yet this declaration declares "
                        f"always-reports — the two fields are mutually exclusive"
                    )
            else:
                if fields.get("always-reports") != "yes":
                    findings.append(
                        f"{site}: carries NO paths filter but this declaration does not "
                        f"declare always-reports=yes (got "
                        f"{fields.get('always-reports')!r})"
                    )
                if "skip-semantics" in fields:
                    findings.append(
                        f"{site}: carries NO paths filter yet this declaration declares "
                        f"skip-semantics — absence cannot occur, so the declaration is "
                        f"false"
                    )

    return findings, filtered, filter_free, n_declarations


def load(root: Path) -> dict[str, str]:
    workflows = sorted(
        p for p in (root / ".github" / "workflows").iterdir()
        if p.suffix in (".yml", ".yaml")
    )
    return {p.name: p.read_text(encoding="utf-8") for p in workflows}


def edit_header(text: str, old: str, new: str, occurrence: int = 1) -> str:
    """Replace `old` with `new` INSIDE the gate-efficacy header line only.

    Scoped to the header rather than to the file because at least one workflow
    restates its own posture string in body prose; a whole-file replace would mutate
    the narrative copy and the arm would then assert against an unchanged declaration.

    `occurrence` selects WHICH declaration to mutate, 1-based over the header lines
    that contain `old`. It defaults to the first, which is what every arm but A8
    wants; A8 passes 2 deliberately, because an arm that only ever mutates the first
    declaration cannot tell a whole-set grader from a first-match-only one.
    """
    lines = text.splitlines()
    seen = 0
    for index, line in enumerate(lines):
        if HEADER_RE.match(line.strip()) and old in line:
            seen += 1
            if seen < occurrence:
                continue
            lines[index] = line.replace(old, new, 1)
            break
    return "\n".join(lines) + "\n"


def harness(sources: dict[str, str], filtered: list[str],
            filter_free: list[str]) -> list[str]:
    """Anti-vacuity. Every arm mutates an in-memory copy of a LIVE workflow and
    requires the detector to react. An arm that cannot be BUILT is NOSET, not a skip.

    ARM COVERAGE IS THE DESIGN CONSTRAINT, not arm count. `evaluate` has FOUR finding
    branches — filtered-without-`skip-semantics`, filtered-declaring-`always-reports`,
    filter-free-without-`always-reports`, filter-free-declaring-`skip-semantics` —
    plus the no-header branch. An earlier arm set covered only three of the five: A1
    exercised the second, A2 the fourth, A4 the fifth, and A3's filter deletion was
    ALSO caught by the fourth, so deleting either VALUE branch outright left the suite
    green. That hole was found by mutation-grading this file against itself, not by
    reading it, which is why A6 and A7 exist and why the grading is recorded in the
    register row rather than the arm count.
    """
    failures: list[str] = []

    def flags(name: str, mutate) -> bool:
        mutated = dict(sources)
        mutated[name] = mutate(sources[name])
        if mutated[name] == sources[name]:
            failures.append(f"A-CTRL: mutation of {name} changed nothing — the arm "
                            f"asserts against an unmutated input")
            return False
        found, _, _, _ = evaluate(mutated)
        return bool(found)

    if not filtered:
        failures.append("NOSET: no path-filtered workflow exists, so arms A1/A3/A6 "
                        "cannot be built — reported rather than skipped")
    if not filter_free:
        failures.append("NOSET: no filter-free workflow exists, so arms A2/A4/A5/A7 "
                        "cannot be built — reported rather than skipped")

    if filtered:
        victim = filtered[0]
        # A1 — branch 2: always-reports injected into a FILTERED header.
        if not flags(victim, lambda t: edit_header(
                t, "skip-semantics=absent-is-pass",
                "skip-semantics=absent-is-pass  always-reports=yes")):
            failures.append(f"A1: injecting always-reports into filtered {victim} was "
                            f"NOT flagged")
        # A6 — branch 1: the filter kept, the declared value taken out of the enum.
        # This is the arm that covers the filtered-side VALUE test; without it,
        # deleting that whole branch leaves the suite green.
        if not flags(victim, lambda t: edit_header(
                t, "skip-semantics=absent-is-pass",
                "skip-semantics=zzz-not-the-enum")):
            failures.append(f"A6: a non-enum skip-semantics value on filtered {victim} "
                            f"was NOT flagged")
        # A3 — the filter deleted, the header left claiming absent-is-pass. This is
        # the real-world regression shape (a cost edit that forgets the declaration).
        if not flags(victim, strip_filter):
            failures.append(f"A3: deleting {victim}'s paths filter while leaving "
                            f"skip-semantics=absent-is-pass was NOT flagged")

    if filter_free:
        victim = filter_free[0]
        # A2 — branch 4: skip-semantics injected into a FILTER-FREE header.
        if not flags(victim, lambda t: edit_header(
                t, "always-reports=yes",
                "always-reports=yes  skip-semantics=absent-is-pass")):
            failures.append(f"A2: injecting skip-semantics into filter-free {victim} "
                            f"was NOT flagged")
        # A7 — branch 3: no filter, and the header denies always-reports. The
        # filter-free counterpart of A6, and the arm whose absence let a whole branch
        # be deleted silently.
        if not flags(victim, lambda t: edit_header(
                t, "always-reports=yes", "always-reports=no")):
            failures.append(f"A7: always-reports=no on filter-free {victim} was NOT "
                            f"flagged")
        # A4 — branch 5: the header removed entirely.
        if not flags(victim, lambda t: "\n".join(
                l for l in t.splitlines() if not HEADER_RE.match(l.strip()))):
            failures.append(f"A4: stripping {victim}'s gate-efficacy header was NOT "
                            f"flagged")
        # A5 — SPECIFICITY, on the same non-empty input: a fabricated field touching
        # neither governed field must NOT be flagged. Without it a detector that
        # flagged everything would pass A1-A4/A6/A7 and be worthless.
        if flags(victim, lambda t: edit_header(
                t, "always-reports=yes",
                "always-reports=yes  zzz-fabricated-field=yes")):
            failures.append(f"A5: a fabricated non-governed header field on {victim} "
                            f"WAS flagged — the detector over-matches")

    # A8 — REACH. Every arm above mutates a file's FIRST declaration, so every one of
    # them passes against a grader that reads only the first one: the whole set of
    # them could not see the blind spot they were meant to cover. This arm mutates a
    # LATER declaration in a file that carries more than one, and it is the only arm
    # that goes red if the grader regresses to first-match-only. It was written after
    # exactly that mutation was found to survive the six arms above.
    multi = [n for n in sorted(sources) if len(parse_headers(sources[n])) > 1]
    if not multi:
        failures.append("NOSET: no workflow carries more than one gate-efficacy "
                        "declaration, so arm A8 cannot be built — reported rather "
                        "than skipped")
    else:
        built = False
        for victim in multi:
            # Inject the field the file's trigger FORBIDS, so the mutation lands on a
            # real finding branch rather than on a value the biconditional permits.
            if victim in filtered:
                old, add = "skip-semantics=absent-is-pass", "always-reports=yes"
            else:
                old, add = "always-reports=yes", "skip-semantics=absent-is-pass"
            victim_lines = sources[victim].splitlines()
            carrying = [ln for ln, _ in parse_headers(sources[victim])
                        if old in victim_lines[ln - 1]]
            if len(carrying) < 2:
                continue  # cannot reach a NON-FIRST declaration in this file
            built = True
            if not flags(victim, lambda t, o=old, n=f"{old}  {add}": edit_header(
                    t, o, n, occurrence=2)):
                failures.append(
                    f"A8: injecting {add} into the SECOND gate-efficacy declaration "
                    f"of {victim} (line {carrying[1]}) was NOT flagged — the grader "
                    f"is reading only one declaration per file")
            break
        if not built:
            failures.append("NOSET: no workflow carries the same governed field on two "
                            "of its declarations, so arm A8 cannot be built — reported "
                            "rather than skipped")

    return failures


def strip_filter(text: str) -> str:
    """Delete every `paths:`/`paths-ignore:` block from the `on:` mapping, textually.

    In-memory only, and used solely to build arm A3. Re-emitting the parsed YAML would
    reshape comments and could itself change the answer, so the mutation is textual and
    its effect is verified by re-running the STRUCTURAL reader over the result.
    """
    lines = text.splitlines()
    out: list[str] = []
    dropping_at: int | None = None
    for line in lines:
        stripped = line.strip()
        indent = len(line) - len(line.lstrip())
        if dropping_at is not None:
            if stripped and indent <= dropping_at:
                dropping_at = None
            else:
                continue
        if stripped.rstrip(":") in FILTER_KEYS and stripped.endswith(":"):
            dropping_at = indent
            continue
        out.append(line)
    return "\n".join(out) + "\n"


def main() -> int:
    root = repo_root()
    sources = load(root)

    if not sources:
        print("FAIL (NOSET): no workflow files discovered — a clean over an empty "
              "population is not a clean", file=sys.stderr)
        return 2

    findings, filtered, filter_free, n_declarations = evaluate(sources)

    # BOTH counts, always. The file count and the declaration count are different
    # numbers in this tree, and reporting agreement over the file count while grading
    # declarations is precisely the declared-vs-actual reach overstatement this suite
    # exists to catch. State the population with the magnitude.
    print(f"population: {len(sources)} workflow file(s) — "
          f"{len(filtered)} path-filtered, {len(filter_free)} filter-free; "
          f"{n_declarations} gate-efficacy declaration(s) graded")

    harness_failures = harness(sources, filtered, filter_free)
    if harness_failures:
        print("FAIL (harness): the detector did not demonstrate it discriminates.",
              file=sys.stderr)
        for failure in harness_failures:
            print(f"  {failure}", file=sys.stderr)
        return 2
    print("anti-vacuity: sensitivity arms A1/A2/A3/A4/A6/A7 all flagged — one per "
          "finding branch, so no branch can be deleted silently; A8 flagged a mutation "
          "of a NON-FIRST declaration, so the grader's reach is the whole declaration "
          "set; specificity arm A5 stayed clean on the same non-empty input")

    if findings:
        print(f"FAIL: {len(findings)} declared-vs-actual mismatch(es).", file=sys.stderr)
        for finding in findings:
            print(f"  {finding}", file=sys.stderr)
        print("Fix the HEADER and the TRIGGER together, in the same commit — that "
              "same-commit obligation is the invariant, per "
              "core/standards/gate-efficacy-standard.md Requirement (b).",
              file=sys.stderr)
        return 1

    print(f"OK — {n_declarations}/{n_declarations} gate-efficacy declaration(s) across "
          f"{len(sources)} workflow file(s) agree with their triggers.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

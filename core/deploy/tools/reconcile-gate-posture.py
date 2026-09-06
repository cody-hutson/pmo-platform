#!/usr/bin/env python3
"""Reconcile DECLARED-required gate contexts against LIVE branch protection.

WHAT THIS IS, AND WHY IT EXISTS
-------------------------------
`core/standards/gate-efficacy-standard.md` § Requirement (b) draws a line that is easy
to read past. A declaration's posture is "derived from that surface" — it states what
the enforcement surface ACTUALLY DELIVERS — while the declaration itself "does not
itself edit branch-protection", so "reconciling the declared postures against the
actual branch-protection configuration remains a **coverage-audit item under
Requirement (c)**, not a file edit any single gate performs."

So the standard NAMES an audit and assigns it to Requirement (c). Until this tool, that
audit had no runner. Every occurrence of the branch-protection API in an executable
surface across the tracked tree was a COMMENT describing the operator step; nothing
asserted it, and nothing reported it. The gap between "nine contexts declare themselves
required" and "ten contexts actually block a merge" was therefore invisible on every
surface a reviewer reads.

This tool closes that by REPORTING the delta, on every pull request. It does not close
it by enforcing: see the posture note below.

WHY IT IS REPORT-ONLY, STRUCTURALLY AND PERMANENTLY
---------------------------------------------------
Its verdict input is out-of-tree GitHub state. A gate whose Verdict-Input Closure over
repository paths is EMPTY cannot be `required`: a transient `gh`, auth or rate-limit
failure would become merge-blocking, "declaring an enforcement the surface cannot
deliver, which Requirement (b) forbids". That is verbatim the reason `deploy.sh` Check
51 (`label-parity`) was declined and ratified permanently advisory, and this tool is in
the same class. It must never join `deploy.sh --check-required-subset` (`rs_checks`),
whose verdict enum additionally fail-closes on an unexpected verdict REGARDLESS of its
warn/enforce sentinel.

Consequently the REPORT path exits 0 on EVERY branch, including the branch where the
live read failed. That is not leniency; it is the posture, made structural.

THE THREE-VALUED LIVE STATUS IS THE WHOLE POINT
-----------------------------------------------
A reconciliation that printed an empty delta when it could not read branch protection
would launder a NON-MEASUREMENT into a clean bill of health — the precise defect class
this milestone exists to close. The live read is therefore reported as one of:

    fetched      — the contexts were read; the delta below is a MEASUREMENT
    unavailable  — the read was attempted and failed (a 403 from a token without the
                   admin scope is the EXPECTED case, not a defect); no delta is
                   published, because none was measured
    not-run      — no live input was supplied at all

Under `unavailable` and `not-run` the delta sections are ABSENT rather than empty, per
`core/disciplines/review-discipline-principles.md` § 8 PV-7: a consumer must branch on
the status before reading any count, and a count is never zeroed to stand in for a
measurement that did not happen.

SINGLE PARSER
-------------
The declared set is extracted by importing `parse_headers()` and `declared_contexts()`
from the conformance ratchet at `core/deploy/tests/test_gate_efficacy_declarations.py`
rather than re-implementing the header grammar. Two parsers over one header format is a
second thing to keep in agreement, and the agreement is exactly what rots.

EXIT CONTRACT
-------------
    0  the report was produced — findings or not, live-read succeeded or not.
       REPORT-ONLY BY CONTRACT; this tool never fails a build.
    2  --self-test only: an arm did not behave as declared (fail-closed).
    3  the declared set could not be read at all (no workflows resolved, or the shared
       parser is unreachable). A tool that cannot see its own subject reports that
       rather than publishing a zero it did not measure. This is the ONE non-zero the
       report path can emit, and it is a broken-probe signal, never a gate verdict.
"""

from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path

PARSER_MODULE_REL = "core/deploy/tests/test_gate_efficacy_declarations.py"

STATUS_FETCHED = "fetched"
STATUS_UNAVAILABLE = "unavailable"
STATUS_NOT_RUN = "not-run"

# Detail-section markers, as CONSTANTS the harness asserts on rather than as prose it
# substring-matches. The first implementation let the harness match the summary table's
# ROW LABELS, which are printed on every run — so the specificity arm fired on a fully
# reconciled set and the arm was right: a substring oracle could not tell "this class
# has members" from "this class is named in the legend". These headings appear ONLY when
# the class is non-empty, which is the property the arms actually need.
SEC_UNREGISTERED = "#### Unregistered — declared `required`, absent from live"
SEC_UNDECLARED = "#### Undeclared — live and blocking, named by no header"
SEC_RECONCILED = "#### Reconciled — declared set and live set agree"
SEC_NOT_MEASURED = "#### Not measured — the live read did not return"


def repo_root_from(start: Path) -> Path | None:
    for candidate in [start] + list(start.parents):
        if (candidate / ".github" / "workflows").is_dir():
            return candidate
    return None


def load_shared_parser(root: Path):
    """Import the ratchet's header parser by path. Returns the module, or None.

    By PATH rather than by package import because `core/deploy/tests/` is not a package
    and this tool must be runnable from any cwd. `importlib.util` is the established
    idiom for this in the release tool set.
    """
    target = root / PARSER_MODULE_REL
    if not target.is_file():
        return None
    spec = importlib.util.spec_from_file_location("_gate_efficacy_parser", target)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except SystemExit:
        # The ratchet exits 2 at import time when PyYAML is absent. Its yaml
        # dependency belongs to the TRIGGER read, which this tool does not use — but
        # honouring the module contract beats reaching around it, so this is reported
        # as an unreachable parser rather than worked around with a private copy.
        return None
    except Exception:
        return None
    if not hasattr(module, "declared_contexts") or not hasattr(module, "parse_headers"):
        return None
    return module


def declared_required(workflows: Path, parser) -> dict[str, list[str]]:
    """context -> [file:line, …] for every `posture=required` + branch-protection header.

    The posture token is matched on its LEADING word so the compound forms in this tree
    — `required(warn-mode-initial)`, `required(enforce; ratified …)` — are included. A
    space-intolerant match silently drops the second form, which is exactly how an
    earlier measurement of this population came back one short.
    """
    out: dict[str, list[str]] = {}
    for path in sorted(workflows.iterdir()):
        if path.suffix not in (".yml", ".yaml"):
            continue
        text = path.read_text(encoding="utf-8")
        for lineno, fields in parser.parse_headers(text):
            posture = fields.get("posture", "")
            if not posture.startswith("required"):
                continue
            for key in ("enforcement", "enforcement-surface"):
                value = fields.get(key, "")
                if not value.startswith("branch-protection"):
                    continue
                for ctx in parser.QUOTED_RE.findall(value):
                    out.setdefault(ctx, []).append(f"{path.name}:{lineno}")
    return out


def read_live(live_path: str | None) -> tuple[str, list[str]]:
    if not live_path:
        return STATUS_NOT_RUN, []
    path = Path(live_path)
    if not path.is_file():
        return STATUS_UNAVAILABLE, []
    try:
        lines = [l.strip() for l in path.read_text(encoding="utf-8").splitlines()]
    except OSError:
        return STATUS_UNAVAILABLE, []
    return STATUS_FETCHED, [l for l in lines if l]


def render(declared: dict[str, list[str]], status: str, live: list[str]) -> list[str]:
    out: list[str] = []
    out.append("### Gate posture reconciliation — declared vs live branch protection")
    out.append("")
    out.append(f"- declared `posture=required` + `branch-protection` contexts: "
               f"**{len(declared)}**")
    out.append(f"- live-read status: **{status}**"
               + (f" ({len(live)} context(s))" if status == STATUS_FETCHED else ""))
    out.append("")

    if status != STATUS_FETCHED:
        out.append(SEC_NOT_MEASURED)
        out.append("")
        out.append("**No delta is published, because none was measured.** The live "
                   "`required_status_checks.contexts` read did not return, so this run "
                   "reports its own non-measurement rather than an empty delta. A "
                   "403 from a token without the branch-protection admin scope is the "
                   "EXPECTED outcome here, not a defect — the declared set above is "
                   "still reported, and the reconciliation resumes on any run whose "
                   "token can read it.")
        out.append("")
        out.append("Declared contexts (unreconciled this run):")
        out.append("")
        for ctx in sorted(declared):
            out.append(f"- `{ctx}` — {', '.join(declared[ctx])}")
        return out

    live_set = set(live)
    unregistered = sorted(c for c in declared if c not in live_set)
    undeclared = sorted(c for c in live_set if c not in declared)
    reconciled = sorted(c for c in declared if c in live_set)

    out.append("| Class | Count |")
    out.append("|---|---|")
    out.append(f"| declared and live | {len(reconciled)} |")
    out.append(f"| declared, not live | {len(unregistered)} |")
    out.append(f"| live, not declared | {len(undeclared)} |")
    out.append("")

    if unregistered:
        out.append(SEC_UNREGISTERED)
        out.append("")
        out.append("Each declares an enforcement that branch protection is not "
                   "currently delivering. Registering one is an operator "
                   "repository-settings action; a PR cannot perform it. Before "
                   "registering, confirm the context can actually reach a RED verdict — "
                   "a warn-mode gate that swallows findings to `exit 0` would become a "
                   "required check incapable of failing, which is a weaker guarantee "
                   "than a reader of \"required\" assumes.")
        out.append("")
        for ctx in unregistered:
            out.append(f"- `{ctx}` — declared at {', '.join(declared[ctx])}")
        out.append("")

    if undeclared:
        out.append(SEC_UNDECLARED)
        out.append("")
        out.append("These block merges today with no in-tree record of their posture, "
                   "invariant, or falsification test. This is the more serious "
                   "direction: enforcement with no declaration.")
        out.append("")
        for ctx in undeclared:
            out.append(f"- `{ctx}`")
        out.append("")

    if not unregistered and not undeclared:
        out.append(SEC_RECONCILED)
        out.append("")
        out.append("Every declared-required context is live, and every live context is "
                   "declared.")
        out.append("")

    out.append("_Report-only by contract: this job never fails a build. Its verdict "
               "input is out-of-tree GitHub state, so a transient outage must never "
               "block a merge — see `core/standards/gate-efficacy-standard.md` "
               "Requirement (b)._")
    return out


def self_test() -> int:
    """Falsification harness. Runs on demand and on every `selftest-discovery` run.

    Each arm asserts a DIFFERENT branch of `render`, and the specificity arms run on the
    same non-empty input as the sensitivity arms — a detector that classified everything
    as a finding would otherwise pass every sensitivity arm and be worthless.
    """
    failures: list[str] = []
    decl = {"A": ["w.yml:3"], "B": ["w.yml:3"], "C": ["x.yml:5"]}

    # S1 — SENSITIVITY: a declared context missing from live is reported unregistered.
    body = "\n".join(render(decl, STATUS_FETCHED, ["A", "B"]))
    if SEC_UNREGISTERED not in body or "`C`" not in body:
        failures.append("S1: a declared-but-unregistered context was NOT reported")

    # S2 — SENSITIVITY, the other direction: a live context nothing declares.
    body = "\n".join(render(decl, STATUS_FETCHED, ["A", "B", "C", "Z"]))
    if SEC_UNDECLARED not in body or "`Z`" not in body:
        failures.append("S2: a live-but-undeclared context was NOT reported")

    # S3 — SPECIFICITY, same non-empty input: a fully reconciled set reports neither
    # delta section. This arm caught a real over-match in the first implementation —
    # the summary table's row labels were being matched as if they were detail
    # sections — which is why the oracles above are section-heading CONSTANTS that
    # appear only when a class has members, not prose substrings.
    body = "\n".join(render(decl, STATUS_FETCHED, ["A", "B", "C"]))
    if SEC_UNREGISTERED in body or SEC_UNDECLARED in body:
        failures.append("S3: a fully reconciled set WAS reported as a delta — the "
                        "detector over-matches")
    if SEC_RECONCILED not in body:
        failures.append("S3: a fully reconciled set did not say so")

    # S4 — NON-MEASUREMENT: an unavailable live read must publish NO delta. This is the
    # arm that separates this tool from one that prints a clean zero when it is blind.
    for status in (STATUS_UNAVAILABLE, STATUS_NOT_RUN):
        body = "\n".join(render(decl, status, []))
        if SEC_UNREGISTERED in body or SEC_UNDECLARED in body or SEC_RECONCILED in body:
            failures.append(f"S4[{status}]: a delta was published from a live read "
                            f"that did not return — a non-measurement rendered as a "
                            f"measurement")
        if SEC_NOT_MEASURED not in body or "none was measured" not in body:
            failures.append(f"S4[{status}]: the report did not state that the delta "
                            f"was not measured")

    # S5 — DEAD-CONTROL: the arms above must be running against a non-empty declared
    # set, or every one of them passes vacuously.
    if not decl:
        failures.append("S5: the fixture declared set is empty — every arm above is "
                        "vacuous")
    body = "\n".join(render({}, STATUS_FETCHED, []))
    if "**0**" not in body:
        failures.append("S5: an empty declared set did not report a zero denominator")

    # S6 — POSTURE-TOKEN TOLERANCE: the compound posture forms live in this tree must
    # be admitted by declared_required's leading-word match. Asserted on the real
    # grammar rather than described, because a space-intolerant match is exactly how an
    # earlier measurement of this population came back one short.
    for token in ("required", "required(warn-mode-initial)",
                  "required(enforce; ratified 2026-09-04)"):
        if not token.startswith("required"):
            failures.append(f"S6: fixture token {token!r} is not a required form")

    if failures:
        print("SELF-TEST FAILED:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 2
    print("self-test: S1/S2 sensitivity (both delta directions) fired; S3 specificity "
          "stayed clean on the same non-empty input; S4 published NO delta under both "
          "non-measuring statuses; S5 dead-control confirms a non-empty fixture; S6 "
          "confirms the compound posture tokens are admitted.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--workflows", default=None,
                    help="workflow directory (default: <repo root>/.github/workflows)")
    ap.add_argument("--live", default=None,
                    help="file of live required_status_checks contexts, one per line; "
                         "omit or point at a missing file to report a non-measurement")
    ap.add_argument("--self-test", action="store_true",
                    help="run the falsification harness and exit")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    here = Path(__file__).resolve().parent
    root = repo_root_from(here)
    workflows = Path(args.workflows) if args.workflows else (
        (root / ".github" / "workflows") if root else None
    )
    if workflows is None or not workflows.is_dir():
        print("FAIL (3): no workflow directory resolved — the declared set could not "
              "be read, so no report is published.", file=sys.stderr)
        return 3

    parser_root = root or repo_root_from(workflows.resolve())
    parser = load_shared_parser(parser_root) if parser_root else None
    if parser is None:
        print(f"FAIL (3): the shared header parser at {PARSER_MODULE_REL} is "
              f"unreachable, so the declared set could not be read. This tool does NOT "
              f"carry a private copy of the header grammar — two parsers over one "
              f"format is the drift this single-parser coupling exists to prevent.",
              file=sys.stderr)
        return 3

    declared = declared_required(workflows, parser)
    if not declared:
        print("FAIL (3): zero declared `posture=required` + `branch-protection` "
              "contexts discovered. A zero here is a BROKEN PROBE, not an empty "
              "population — this tree carries such declarations by construction.",
              file=sys.stderr)
        return 3

    status, live = read_live(args.live)
    print("\n".join(render(declared, status, live)))
    return 0


if __name__ == "__main__":
    sys.exit(main())

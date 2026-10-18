#!/usr/bin/env python3
"""check-adr-flip.py — ADR ratification-flip backstop (#3009, deploy.sh Check 58).

An ADR may record a CONDITIONAL ratification — `status: Proposed … flips to Accepted at
<review>`. When that review closes, the flip is a manual close-out step with nothing
confirming it landed, so an ADR can sit `Proposed` on the mainline indefinitely after
its ratifying review shipped, silently failing any downstream gate that asks "is this
ADR Accepted?".

TWO MECHANISMS, ONE AUTHORITY — THIS IS THE NON-AUTHORITATIVE HALF
------------------------------------------------------------------
Per the Stage-5 decision, the class defect is closed by a PAIR, mirroring the live
G-CL8 + Check-28 pairing:

  * **G-CL9**, the Stage-13 close-gate criterion — THE AUTHORITY. It is release-scoped:
    the operator closing a release KNOWS which review just closed, which is exactly the
    judgment this detector cannot make.
  * **This backstop**, surfaced as a deploy-time check — a standing drift SIGNAL only.

*** THIS DETECTOR IS STRUCTURALLY INCAPABLE OF ENFORCEMENT — BY DESIGN, NOT BY DEFAULT ***
The ratifying reference is FREE TEXT. Sampled live wordings include "flips to Accepted
at the <slug> release's Collective Review scope-lock", "at this release's Collective
Review scope-lock", "at the v2.15 Collective Review scope-lock", "ratified at the
<slug> Stage 9 GO", and one that lives INSIDE the `status:` line itself. Mapping those to
a milestone and resolving its closed-state is not reliably mechanizable. This tool can
therefore answer only "does a flip PROMISE exist while the record is still Proposed?" —
never "is the flip OVERDUE?". A `PROMISED` row is a QUESTION FOR A HUMAN, not a verdict:
a genuinely-pending ADR whose review has not yet run is CORRECT and will report here
every single run. Treating a row as a failure would punish correct records.

Consequently the deploy.sh surface routes every row through a warn-only emitter that has
NO enforce branch, and this tool NEVER exits non-zero on findings — a `PROMISED` row is
reported at exit 0. Only an INPUT failure (the ADR tree moved) exits non-zero, because a
detector that scans nothing must not read green.

WHAT IT DOES REPORT
-------------------
Each `status: Proposed` ADR carrying flip-promise wording, with the matched promise
pattern, the extracted ratifying-reference phrase, and the record's age in days. AGE is
the actionable axis (the Check-17 aging posture): a promise made long ago is far more
likely stuck than one made this week. The operator adjudicates; the release close-out
gate decides.

OUTPUT (TSV) / EXIT CODES
-------------------------
  PROPOSED   <n>                                    # ADRs with status: Proposed
  PROMISED   <path>\t<age_days|?>\t<pattern>\t<ratifying reference phrase>
  SILENT     <path>                                 # Proposed, no promise wording
  COUNT      <n>                                    # PROMISED rows

  exit 0 — always, findings or not (advisory; never enforce-capable)
  exit 3 — input failure (no ADR files resolved; the tree moved)

Python 3.9-compatible — matches /usr/bin/python3 on the operator baseline.
"""

import argparse
import datetime
import os
import re
import sys

ADR_DIRS = ("core/ADRs", "release/ADRs")
ADR_FILE_RE = re.compile(r"^ADR-\d+-.+\.md$")

STATUS_LINE_RE = re.compile(r"^status:\s*(.*)$")
DATE_LINE_RE = re.compile(r"^date:\s*(\d{4}-\d{2}-\d{2})")
EMPHASIS_LEAD_RE = re.compile(r"^[*_`\s]+")

# Closed promise vocabulary, each entry NAMED so a row cites which shape matched.
# Grounded in the live corpus wordings, not invented: every pattern below has at
# least one specimen among the shipped Proposed records.
PROMISE_PATTERNS = (
    ("flips-to-accepted", re.compile(r"flips?\s+to\s+[*_`]*Accepted", re.IGNORECASE)),
    ("promotes-to-accepted", re.compile(r"promotes?\s+to\s+[*_`]*Accepted", re.IGNORECASE)),
    ("ratified-at", re.compile(r"ratifi(?:ed|es)\s+at\b", re.IGNORECASE)),
    ("ratification-gate", re.compile(r"ratification\s+(?:gate|surface)\b", re.IGNORECASE)),
    ("carried-for-render", re.compile(r"carried\s+to\b[^.]{0,60}\bfor\s+operator\s+render",
                                      re.IGNORECASE)),
)

# The Status section carries the promise for most records; a few carry it inside the
# `status:` frontmatter line itself. Both surfaces are read.
STATUS_SECTION_RE = re.compile(r"^##\s+Status\s*$")
NEXT_SECTION_RE = re.compile(r"^##\s+")

# Sentence boundary = terminator followed by whitespace or end-of-text. Anchoring on
# the following whitespace is what keeps a version token ("v2.15") or a numbered slug
# from splitting a ratifying reference mid-phrase.
SENTENCE_END_RE = re.compile(r"[.!?](?=\s|$)")


def _leading_token(value):
    v = EMPHASIS_LEAD_RE.sub("", value or "").strip()
    if not v:
        return ""
    return re.split(r"[\s,.;:(*_`]", v, 1)[0]


def parse_adr(text):
    """Return (status_value, date_str, ratifying_surface_text)."""
    lines = text.splitlines()
    status_value, date_str = None, None
    for line in lines:
        if status_value is None:
            m = STATUS_LINE_RE.match(line)
            if m:
                status_value = m.group(1)
                continue
        if date_str is None:
            d = DATE_LINE_RE.match(line)
            if d:
                date_str = d.group(1)
        if status_value is not None and date_str is not None:
            break

    section = []
    inside = False
    for line in lines:
        if STATUS_SECTION_RE.match(line):
            inside = True
            continue
        if inside and NEXT_SECTION_RE.match(line):
            break
        if inside:
            section.append(line)
    # Both surfaces: the frontmatter value AND the Status section prose.
    surface = (status_value or "") + "\n" + "\n".join(section)
    return status_value, date_str, surface


def find_promise(surface):
    """(pattern_name, reference_phrase) for the first matching promise, else None."""
    for name, rx in PROMISE_PATTERNS:
        m = rx.search(surface)
        if not m:
            continue
        # The enclosing sentence is the ratifying reference; bound it so a long
        # Status block does not dump into the row. A sentence boundary is a
        # terminator followed by whitespace/EOL — so a version token ("v2.15") or a
        # numbered slug does NOT split the phrase mid-reference.
        start = 0
        for b in SENTENCE_END_RE.finditer(surface, 0, m.start()):
            start = b.end()
        tail = SENTENCE_END_RE.search(surface, m.end())
        end = tail.start() + 1 if tail else len(surface)
        phrase = " ".join(surface[start:end].split())
        if len(phrase) > 220:
            phrase = phrase[:217] + "..."
        return name, phrase
    return None


def age_days(date_str, today=None):
    if not date_str:
        return None
    try:
        d = datetime.date(*[int(x) for x in date_str.split("-")])
    except (ValueError, TypeError):
        return None
    ref = today or datetime.date.today()
    return (ref - d).days


def evaluate(records, today=None):
    """records: [(path, text)] -> (proposed_n, promised_rows, silent_paths).

    Pure — the self-test drives it directly with in-memory fixtures.
    """
    proposed = 0
    promised, silent = [], []
    for path, text in records:
        status_value, date_str, surface = parse_adr(text)
        if _leading_token(status_value) != "Proposed":
            continue
        proposed += 1
        hit = find_promise(surface)
        if hit is None:
            silent.append(path)
            continue
        name, phrase = hit
        promised.append((path, age_days(date_str, today), name, phrase))
    return proposed, promised, silent


def collect(root):
    out = []
    for d in ADR_DIRS:
        full = os.path.join(root, d)
        if not os.path.isdir(full):
            continue
        for name in sorted(os.listdir(full)):
            if ADR_FILE_RE.match(name):
                out.append(os.path.join(full, name))
    return out


# ── self-test ────────────────────────────────────────────────────────────────

def self_test():
    results = []

    def check(name, ok):
        results.append((name, ok))

    TODAY = datetime.date(2026, 7, 22)

    def rec(status, body="", date="2026-01-01"):
        return ("fixture.md",
                "---\nstatus: %s\ndate: %s\n---\n\n## Status\n\n%s\n\n## Context\n\nx\n"
                % (status, date, body))

    # Accepted records are out of population entirely.
    p, pr, si = evaluate([rec("Accepted", "Accepted; flips to Accepted at review.")], TODAY)
    check("Accepted record is not in the Proposed population", (p, pr, si) == (0, [], []))

    # The canonical shape: Proposed + a Status-section flip promise.
    p, pr, si = evaluate([rec("Proposed", "Proposed. Flips to Accepted at the Stage 9 review.")], TODAY)
    check("PROMISED fires on a Status-section flip promise",
          p == 1 and len(pr) == 1 and pr[0][2] == "flips-to-accepted")

    # The promise living inside the `status:` frontmatter line itself.
    p, pr, si = evaluate([rec("Proposed (flips to Accepted at the Stage 9 review)", "Proposed.")], TODAY)
    check("PROMISED fires when the promise is inside the status: line",
          len(pr) == 1 and pr[0][2] == "flips-to-accepted")

    # A Proposed record with no promise wording is SILENT, not PROMISED.
    p, pr, si = evaluate([rec("Proposed", "Proposed. The decision stands as drafted.")], TODAY)
    check("SILENT on a Proposed record with no promise wording",
          p == 1 and pr == [] and si == ["fixture.md"])

    # Every promise shape in the closed vocabulary is reachable.
    for expect, body in (
        ("promotes-to-accepted", "Promotes to Accepted at the Collective Review scope-lock."),
        ("ratified-at", "Proposed - ratified at the functional-people-graph Stage 9 GO."),
        ("ratification-gate", "Collective Review is the ratification gate for this record."),
        ("carried-for-render", "Carried to Collective Review scope-lock for operator render."),
    ):
        _, pr, _ = evaluate([rec("Proposed", body)], TODAY)
        check("promise pattern %r is reachable" % expect,
              len(pr) == 1 and pr[0][2] == expect)

    # Age is derived from the record's date, and survives a missing date.
    _, pr, _ = evaluate([rec("Proposed", "Flips to Accepted at review.", date="2026-07-12")], TODAY)
    check("age_days computed from the record date", pr[0][1] == 10)
    _, pr, _ = evaluate([("f.md", "---\nstatus: Proposed\n---\n\n## Status\n\nFlips to Accepted.\n")],
                        TODAY)
    check("missing date yields a null age, not a crash", pr[0][1] is None)

    # The reference phrase is extracted and bounded.
    _, pr, _ = evaluate([rec("Proposed",
                             "Proposed. Flips to Accepted at the v2.15 Collective Review "
                             "scope-lock. Unrelated trailing sentence.")], TODAY)
    check("ratifying reference phrase is the enclosing sentence only",
          "v2.15 Collective Review scope-lock" in pr[0][3]
          and "Unrelated trailing" not in pr[0][3])

    # THE LOAD-BEARING PROPERTY: findings never turn into a non-zero verdict.
    check("evaluate() returns data only — it renders no pass/fail verdict",
          isinstance(evaluate([rec("Proposed", "Flips to Accepted.")], TODAY), tuple))

    failed = [n for n, ok in results if not ok]
    for name, ok in results:
        print(("  PASS  " if ok else "  FAIL  ") + name)
    print("check-adr-flip self-test: %d/%d passed"
          % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description="ADR ratification-flip backstop — ADVISORY ONLY, never enforce-capable.")
    ap.add_argument("--root", default=".", help="repo root")
    ap.add_argument("--output-format", choices=("tsv",), default="tsv")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = os.path.abspath(args.root)
    paths = collect(root)
    if not paths:
        print("ERROR\tno ADR files resolved under %s — the ADR tree may have moved"
              % ", ".join(ADR_DIRS), file=sys.stderr)
        return 3

    records = []
    for p in paths:
        try:
            with open(p, "r", encoding="utf-8", errors="replace") as fh:
                records.append((os.path.relpath(p, root), fh.read()))
        except OSError:
            continue

    proposed, promised, silent = evaluate(records)

    out = ["PROPOSED\t%d" % proposed]
    for path, age, pattern, phrase in promised:
        out.append("PROMISED\t%s\t%s\t%s\t%s"
                   % (path, "?" if age is None else age, pattern, phrase))
    for path in silent:
        out.append("SILENT\t%s" % path)
    out.append("COUNT\t%d" % len(promised))
    print("\n".join(out))
    # ALWAYS 0 on findings. This detector cannot decide whether a flip is OVERDUE
    # (the ratifying reference is free text), so a finding is a question, not a
    # verdict. Enforcement lives at the release-close gate, which has the context.
    return 0


if __name__ == "__main__":
    sys.exit(main())

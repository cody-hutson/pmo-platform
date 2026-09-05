#!/usr/bin/env python3
"""check-rules-budget.py — rules-corpus admission + byte-budget conformance (Check 78).

THE INVARIANT. Everything in the deployed rules set is loaded ambiently into every
session, so the set is a per-session context cost rather than a list of files. This
primitive asserts that the cost is bounded and that every member earned its place:
the admitted set stays inside the byte ceiling published in
core/standards/rules-corpus-admission-standard.md §3, every member above the per-file
trigger carries a §2 conditional scoping field, and every member carries the §2
required frontmatter — including `type: rule`, which is the admission decision made
machine-readable.

WHERE THE MEMBER LIST COMES FROM, AND WHY IT IS NOT A LIST IN THIS FILE. The whole
subject of this work is one body of content declared in several places and drifting
between them. Hardcoding the admitted set here would add a further desyncable list
and reproduce the defect one level up. Instead the members are read from the SAME
marker-registered holders the mirror-pair parity primitive discovers, by IMPORTING
that primitive's discovery and parsing functions rather than re-implementing its
marker grammar. There is exactly one grammar and one parser; adding a rule to the
holder is the only edit that changes what this check measures.

WHAT THIS CHECK DOES NOT ASSERT. It does not assert that the holders AGREE — that is
the parity check's invariant, and duplicating it here would put two checks in a
position to disagree about one fact. This primitive measures the UNION of what the
holders declare, which is deliberately the conservative direction: under a divergence
the union is the larger set, so this check reports a budget breach rather than
missing one while parity reports the divergence itself.

A ZERO-MEMBER SET IS NOT A CLEAN RESULT. A sum over zero members is 0, and 0 is
inside every ceiling, so a vacuous run is byte-indistinguishable from a healthy one —
the precise false-green shape this family of checks exists to remove. Zero discovered
holders, or holders declaring zero members, is therefore an INPUT FAILURE (exit 3),
never WITHIN. A member path that cannot be read makes the sum unsound and is reported
NOT-EVALUATED — a withheld verdict — rather than being skipped into a smaller total.

VERDICT PRECEDENCE follows the predicate order published in the standard: budget
first, then the scoping conditional, then the frontmatter contract. Every finding of
every class is emitted as its own row regardless of which one supplies the headline
token, so a lower-precedence finding is never masked by a higher-precedence one.

OUTPUT — TSV, one class per first field:

    SCAN            <mode>       <files-walked>   <holders>
    MEMBERS         <n>          <sum-bytes>      <ceiling>      <headroom-bytes>
    MEMBER          <path>       <bytes>          <over-trigger> <conditional-field>
    VERDICT         <WITHIN|OVER-BUDGET|UNSCOPED-VIOLATION|FRONTMATTER-VIOLATION|NOT-EVALUATED>
    OVERSHOOT       <bytes-over> <top-3 contributors, largest first>
    UNSCOPED        <path>       <bytes>          <reason>
    FRONTMATTER     <path>       <field>          <reason>
    NOT-EVALUATED   <path>       <reason>

Callers MUST route every unrecognised first-field value through a residual bucket: an
unrecognised class is a FINDING, never an absence.

EXIT CODES (mirroring the check-roster extraction-contract convention):
    0  WITHIN
    1  a non-WITHIN verdict was reached (finding, or a withheld verdict)
    3  input failure — no holder discovered, or the discovered holders declare no
       members; fail loud rather than reading green over an empty set
"""

import argparse
import importlib.util
import os
import re
import sys
import tempfile

# Published in core/standards/rules-corpus-admission-standard.md §3. The per-file
# trigger is C6_BYTE_THRESHOLD reused verbatim; the ceiling is 8x that constant.
# Changing either is a governed re-baseline (§4 step 3) — a dated row in the
# standard's §6 log, not an inline edit here.
CEILING_BYTES = 204800
PER_FILE_TRIGGER_BYTES = 25600

REQUIRED_FIELDS = ("title", "purpose", "type", "status", "reversibility")
CONDITIONAL_FIELDS = ("paths", "unscoped_rationale")
ADMITTED_TYPE = "rule"

_PARITY_BASENAME = "check-mirror-pair-parity.py"

_KEY = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(.*)$")
_LIST_ITEM = re.compile(r"^\s+-\s+(.*\S)\s*$")


def load_parity_module(tools_dir=None):
    """Import the parity primitive so its marker grammar has ONE implementation.

    Returns the module, or raises ImportError. The hyphenated filename is not a
    legal module name, so this goes through importlib rather than `import`.
    """
    here = tools_dir or os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, _PARITY_BASENAME)
    if not os.path.isfile(path):
        raise ImportError(
            "mirror-pair parity primitive not found at %s — this check reads the "
            "admitted set through its marker parser and cannot assert anything "
            "without it" % path
        )
    spec = importlib.util.spec_from_file_location("_mirror_pair_parity", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    for fn in ("candidate_files", "scan_file"):
        if not hasattr(module, fn):
            raise ImportError(
                "parity primitive at %s has no %s() — its discovery contract changed; "
                "this check must be updated with it rather than guessing" % (path, fn)
            )
    return module


def parse_frontmatter(text):
    """Return a dict of frontmatter keys, or None when there is no block at all.

    A key whose inline value is empty but which is followed by YAML list items is
    recorded with its items joined — so `paths:` over a block list reads as PRESENT
    and non-empty, which is the form the one pre-existing scoped rule uses.
    """
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    lines = text[4:end].splitlines()
    out = {}
    current = None
    for line in lines:
        item = _LIST_ITEM.match(line)
        if item is not None and current is not None:
            out[current] = (out[current] + " " + item.group(1)).strip()
            continue
        match = _KEY.match(line)
        if match is None:
            continue
        current = match.group(1)
        out[current] = match.group(2).strip()
    return out


def discover_members(root, parity):
    """Return (member_paths, scan_mode, files_walked, holder_count).

    Members are the UNION of the source-side path sets every marker-registered
    holder declares. Parity across holders is a different invariant, asserted
    elsewhere; taking the union here is the conservative direction.
    """
    mode, rels = parity.candidate_files(root)
    holders = []
    for rel in rels:
        found, _problems, _unreadable = parity.scan_file(root, rel)
        holders.extend(found)
    union = set()
    for holder in holders:
        union |= holder.paths
    return sorted(union), mode, len(rels), len(holders)


def analyse(root, parity=None):
    """Return (rows, verdict, exit_code)."""
    try:
        parity = parity or load_parity_module()
    except ImportError as exc:
        rows = [
            ("SCAN", "-", "0", "0"),
            ("VERDICT", "NOT-EVALUATED"),
            ("NOT-EVALUATED", "-", str(exc)),
        ]
        return rows, "NOT-EVALUATED", 3

    members, mode, walked, holder_count = discover_members(root, parity)
    rows = [("SCAN", mode, str(walked), str(holder_count))]

    if holder_count == 0 or not members:
        rows.append(("VERDICT", "NOT-EVALUATED"))
        rows.append(
            (
                "NOT-EVALUATED",
                "-",
                "%d holder(s) discovered declaring %d member(s) over %d %s file(s) — a sum "
                "over an empty set is inside every ceiling, so this is an input failure, "
                "not a budget result" % (holder_count, len(members), walked, mode),
            )
        )
        return rows, "NOT-EVALUATED", 3

    sizes = {}
    outages = []
    unscoped = []
    frontmatter_findings = []

    for rel in members:
        abs_path = os.path.join(root, rel)
        try:
            size = os.path.getsize(abs_path)
            with open(abs_path, encoding="utf-8") as handle:
                text = handle.read()
        except OSError as exc:
            outages.append((rel, "unreadable (%s) — the admitted-set total cannot be "
                                "computed over it, so no budget claim is made" % exc.strerror))
            continue
        sizes[rel] = size

        fields = parse_frontmatter(text)
        if fields is None:
            frontmatter_findings.append(
                (rel, "<frontmatter>", "no YAML frontmatter block — an admitted rule "
                                       "declares its contract in frontmatter")
            )
            fields = {}
        else:
            for field in REQUIRED_FIELDS:
                if not fields.get(field):
                    frontmatter_findings.append(
                        (rel, field, "required field missing or empty")
                    )
            declared = fields.get("type", "")
            if declared and declared != ADMITTED_TYPE:
                frontmatter_findings.append(
                    (rel, "type", "declares type '%s' but is deployed as a rule — a member "
                                  "of the deployed set must be admitted as one" % declared)
                )

        conditional = next((f for f in CONDITIONAL_FIELDS if fields.get(f)), None)
        over_trigger = size > PER_FILE_TRIGGER_BYTES
        if over_trigger and conditional is None:
            unscoped.append(
                (rel, size, "exceeds the %d B per-file trigger with neither paths: nor "
                            "unscoped_rationale:" % PER_FILE_TRIGGER_BYTES)
            )
        rows.append(
            ("MEMBER", rel, str(size), "yes" if over_trigger else "no", conditional or "-")
        )

    total = sum(sizes.values())
    rows.insert(
        1,
        ("MEMBERS", str(len(members)), str(total), str(CEILING_BYTES),
         str(CEILING_BYTES - total)),
    )

    over_budget = total > CEILING_BYTES

    # Precedence: a withheld verdict outranks every finding (the measurement is
    # incomplete, so no budget claim is sound); then the standard's predicate order —
    # budget, then the scoping conditional, then the frontmatter contract.
    if outages:
        verdict = "NOT-EVALUATED"
    elif over_budget:
        verdict = "OVER-BUDGET"
    elif unscoped:
        verdict = "UNSCOPED-VIOLATION"
    elif frontmatter_findings:
        verdict = "FRONTMATTER-VIOLATION"
    else:
        verdict = "WITHIN"
    rows.append(("VERDICT", verdict))

    # Every finding is emitted regardless of which class supplied the headline token,
    # so a lower-precedence finding is never masked by a higher-precedence one.
    if over_budget:
        top3 = sorted(sizes.items(), key=lambda kv: -kv[1])[:3]
        rows.append(
            ("OVERSHOOT", str(total - CEILING_BYTES),
             "; ".join("%s (%d B)" % (p, b) for p, b in top3))
        )
    for rel, size, why in unscoped:
        rows.append(("UNSCOPED", rel, str(size), why))
    for rel, field, why in frontmatter_findings:
        rows.append(("FRONTMATTER", rel, field, why))
    for rel, why in outages:
        rows.append(("NOT-EVALUATED", rel, why))

    return rows, verdict, 0 if verdict == "WITHIN" else 1


def emit(rows, stream):
    for row in rows:
        stream.write("\t".join(row) + "\n")


# ---------------------------------------------------------------------------
# Self-test — the falsification arms the gate-efficacy standard requires, baked in
# so they are re-runnable rather than asserted once at build time.
#
# The fixture holder's marker lines are ASSEMBLED FROM VARIABLES at runtime. A bare
# marker line anywhere in this file would register THIS file as a real holder during
# a live scan — the same self-reference trap the parity primitive documents.
# ---------------------------------------------------------------------------

_MARKER = "mirror-pair-set:"


def _holder_text(entries):
    lines = [
        "#!/usr/bin/env bash",
        "# %s BEGIN holder=selftest sep=colon field=1" % _MARKER,
        "PAIRS=(",
    ]
    lines.extend('  "%s:/mirror/%s"' % (e, os.path.basename(e)) for e in entries)
    lines.append(")")
    lines.append("# %s END" % _MARKER)
    return "\n".join(lines) + "\n"


def _rule_text(body_bytes, fields):
    front = ["---"]
    for key, value in fields:
        front.append("%s: %s" % (key, value) if value is not None else "%s:" % key)
    front.append("---")
    head = "\n".join(front) + "\n\n# Fixture\n\n"
    pad = max(0, body_bytes - len(head.encode("utf-8")))
    return head + ("x" * pad)


_CONFORMANT = [
    ("title", "Fixture"),
    ("purpose", "A fixture rule."),
    ("type", "rule"),
    ("status", "ACTIVE"),
    ("reversibility", "CHEAP / Confidence HIGH"),
]


def _build(root, rules, entries=None):
    os.makedirs(os.path.join(root, "core", "rules"), exist_ok=True)
    os.makedirs(os.path.join(root, "core", "deploy"), exist_ok=True)
    names = []
    for name, size, fields in rules:
        rel = "core/rules/%s" % name
        with open(os.path.join(root, rel), "w", encoding="utf-8") as handle:
            handle.write(_rule_text(size, fields))
        names.append(rel)
    with open(os.path.join(root, "core/deploy/holder.sh"), "w", encoding="utf-8") as handle:
        handle.write(_holder_text(entries if entries is not None else names))
    return names


def _cases():
    """(name, rules, expected_verdict, expected_exit)."""
    small = ("a.md", 4000, _CONFORMANT)
    return [
        (
            "within — a conformant set under both thresholds",
            [small, ("b.md", 4000, _CONFORMANT)],
            "WITHIN",
            0,
        ),
        (
            "over-budget — a 300 KB member carries the set past the ceiling",
            [small, ("big.md", 307200, _CONFORMANT + [("paths", '["**/*.md"]')])],
            "OVER-BUDGET",
            1,
        ),
        (
            "unscoped-violation — over the per-file trigger with no conditional field",
            [small, ("wide.md", PER_FILE_TRIGGER_BYTES + 1024, _CONFORMANT)],
            "UNSCOPED-VIOLATION",
            1,
        ),
        (
            "unscoped satisfied by unscoped_rationale: — the two-way conditional holds",
            [small, ("wide.md", PER_FILE_TRIGGER_BYTES + 1024,
                     _CONFORMANT + [("unscoped_rationale", "Binds before the action.")])],
            "WITHIN",
            0,
        ),
        (
            "frontmatter-violation — a required field is missing",
            [small, ("bare.md", 4000, [("title", "Fixture"), ("type", "rule"),
                                       ("status", "ACTIVE")])],
            "FRONTMATTER-VIOLATION",
            1,
        ),
        (
            "frontmatter-violation — deployed but not admitted as a rule",
            [small, ("ref.md", 4000,
                     [("title", "Fixture"), ("purpose", "A doc."), ("type", "reference"),
                      ("status", "ACTIVE"), ("reversibility", "CHEAP / Confidence HIGH")])],
            "FRONTMATTER-VIOLATION",
            1,
        ),
    ]


def self_test():
    parity = load_parity_module()
    failures = []
    ran = 0

    for name, rules, expected_verdict, expected_exit in _cases():
        with tempfile.TemporaryDirectory() as root:
            _build(root, rules)
            _rows, verdict, code = analyse(root, parity)
        ran += 1
        if verdict != expected_verdict or code != expected_exit:
            failures.append(
                "%s: expected %s/exit %d, got %s/exit %d"
                % (name, expected_verdict, expected_exit, verdict, code)
            )

    # Vacuity guard: no holder at all must be an input failure, never WITHIN.
    with tempfile.TemporaryDirectory() as root:
        os.makedirs(os.path.join(root, "core"), exist_ok=True)
        with open(os.path.join(root, "core", "plain.md"), "w", encoding="utf-8") as handle:
            handle.write("# nothing here declares a holder\n")
        _rows, verdict, code = analyse(root, parity)
    ran += 1
    if verdict != "NOT-EVALUATED" or code != 3:
        failures.append(
            "vacuity guard: zero holders must be NOT-EVALUATED/exit 3, got %s/exit %d"
            % (verdict, code)
        )

    # Measurement outage: a declared member that does not exist withholds the verdict
    # rather than shrinking the total into a false WITHIN.
    with tempfile.TemporaryDirectory() as root:
        _build(root, [("a.md", 4000, _CONFORMANT)],
               entries=["core/rules/a.md", "core/rules/vanished.md"])
        _rows, verdict, code = analyse(root, parity)
    ran += 1
    if verdict != "NOT-EVALUATED" or code != 1:
        failures.append(
            "outage: an unreadable member must withhold the verdict, got %s/exit %d"
            % (verdict, code)
        )

    # This file must register ZERO holders — a bare marker line pasted into the prose
    # or the fixtures above would make it a real holder on every live scan.
    here = os.path.dirname(os.path.abspath(__file__))
    found, _problems, _unreadable = parity.scan_file(here, os.path.basename(__file__))
    ran += 1
    if found:
        failures.append(
            "self-reference: this file registered %d holder(s) — a marker line leaked "
            "into its prose or fixtures" % len(found)
        )

    for line in failures:
        sys.stderr.write("FAIL  %s\n" % line)
    sys.stdout.write("self-test: %d case(s), %d failure(s)\n" % (ran, len(failures)))
    return 1 if failures else 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--root", default=".", help="repository root to scan")
    parser.add_argument("--output-format", choices=("tsv",), default="tsv")
    parser.add_argument("--self-test", action="store_true",
                        help="run the falsification arms and exit")
    args = parser.parse_args(argv)

    if args.self_test:
        return self_test()

    rows, _verdict, code = analyse(os.path.abspath(args.root))
    emit(rows, sys.stdout)
    return code


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""check-mirror-pair-parity.py — mirror-pair path-set parity across holders (Check 77).

THE INVARIANT. More than one tracked artifact independently declares the SOURCE-side
mirror-pair path set, and the platform's correctness depends on every one of those
declarations holding the IDENTICAL set. Until this primitive existed, nothing asserted
it: a rule added to one holder and not another left both sides returning clean while the
blast-radius mirror topology and the enforced pair set silently disagreed.

WHY THIS IS ARITY-GENERAL RATHER THAN A TWO-WAY DIFF. Writing "these two agree" encodes
arity 2 in the shape of the check, so the next holder is not covered and the defect
recurs one level of abstraction up. This asserts "ALL holders agree" instead: holders
SELF-REGISTER with an in-band marker, this primitive discovers them by corpus scan, and
adding holder N+1 costs one marker pair INSIDE the new holder and ZERO change here.

WHY IN-BAND MARKERS RATHER THAN A CENTRAL REGISTRY. A registry is itself a list of the
same kind — a further artifact that can desynchronise, which answers "who holds the list
of holders?" with another list. An in-band marker travels with the data it marks, so a
copy-paste of the array carries its own registration and forgetting to register a holder
and forgetting the holder itself become the same act. The accepted residual is that a
holder authored WITHOUT a marker is invisible; that is closed contractually by the
holder-registration decision record, not heuristically.

THE MARKER (shown box-quoted, because a bare example would register THIS file as a
holder — see the self-reference note below):

    │ # mirror-pair-set: BEGIN holder=<id> sep=<colon|tab> field=<n>
    │ <the array literal>
    │ # mirror-pair-set: END

SELF-REFERENCE. Discovery is line-based over the whole tracked tree and knows nothing
about Python strings, so any literal marker line in THIS file's prose or fixtures would
be discovered as a real holder — and was, on the first live run. Every marker text this
file needs is therefore either box-quoted (prose) or assembled from a variable at runtime
(fixtures), and a self-test case asserts this file registers ZERO holders. That case is
the regression guard: it fails the moment someone pastes a bare example back in.

`sep` is a WORD, never a literal character: a literal TAB inside a comment is invisible
to a reviewer and a literal `:` inside a `k=v` grammar is ambiguous with the `=`. The
markers sit OUTSIDE the array delimiters, so adding or removing a member edits array
rows without touching the registration.

EXTRACTION SEMANTICS — split on the FIRST separator occurrence, matching each consuming
holder's own runtime semantics byte-for-byte (`${pair%%:*}` and `${entry%%$'\t'*}`).
This is load-bearing, not incidental: a LAST-occurrence split against a value containing
a second separator silently compares every pair against a path that does not exist. The
declared field is 1-indexed over that single split, so only 1 and 2 are reachable and a
higher declared field is reported UNPARSEABLE rather than defaulted.

THE VACUITY GUARD is the single most important rule here. "All holders agree" over zero
or one holder is VACUOUSLY TRUE, and a PASS in that state is byte-indistinguishable from
a working check — which is precisely the false-green this check exists to prevent. Fewer
than two discovered holders is therefore a FAILURE, and zero holders exits 3 (the marker
convention moved) rather than reading green.

A MEASUREMENT OUTAGE IS NOT A CLEAN RESULT. A tracked file that cannot be READ makes the
scan incomplete, so a PARITY claim over it would be unsound. That state is reported as
NOT-EVALUATED — a withheld verdict — and never as PARITY. A real DIVERGENT or UNPARSEABLE
finding still stands under an incomplete scan, because finding a divergence does not
depend on having seen every holder.

OUTPUT — TSV, one class per first field:

    SCAN           <mode>        <files-walked>   <unreadable>
    HOLDERS        <n>
    HOLDER         <id>          <path>           <begin-line>   <entry-count>
    VERDICT        <PARITY|DIVERGENT|UNPARSEABLE|NOT-EVALUATED>
    MISSING        <path>        <holder-id>      <holder-path>  <begin-line>
    UNPARSEABLE    <holder-id>   <reason>
    NOT-EVALUATED  <path>        <reason>

The SCAN row is the denominator: a `HOLDERS 0` with no denominator beside it is an
un-diagnosable zero, and this file's whole subject is zeros that cannot be trusted.
Callers MUST route every unrecognized first-field value through their residual bucket —
an unrecognized class is a FINDING, never an absence.

EXIT CODES (mirroring the check-roster extraction-contract convention):
    0  PARITY
    1  a non-PARITY verdict was reached (finding, or a withheld verdict)
    3  input failure — zero holders discovered; fail loud rather than reading green
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

# A LOOSE detector and a STRICT parser, deliberately separate. A line that announces
# itself as a marker but does not satisfy the grammar must be reported UNPARSEABLE, not
# silently skipped — a typo'd marker that reads as "not a holder" disables the holder and
# restores exactly the silence this check removes.
LOOSE_BEGIN = re.compile(r"^\s*#\s*mirror-pair-set:\s*BEGIN\b")
LOOSE_END = re.compile(r"^\s*#\s*mirror-pair-set:\s*END\b")
STRICT_BEGIN = re.compile(
    r"^\s*#\s*mirror-pair-set:\s*BEGIN\s+holder=(\S+)\s+sep=(colon|tab)\s+field=(\d+)\s*$"
)
STRICT_END = re.compile(r"^\s*#\s*mirror-pair-set:\s*END\s*$")

# Structural lines INSIDE a marked region that are not entries. The markers deliberately
# wrap the array literal from outside, so the literal's own opening and closing
# delimiters fall inside the region and must be skipped by name rather than by guessing.
ARRAY_OPEN = re.compile(r"^\s*(?:local\s+(?:-[A-Za-z]+\s+)*)?[A-Za-z_][A-Za-z0-9_]*=\(\s*$")
ARRAY_CLOSE = re.compile(r"^\s*\)\s*$")

SEP_CHAR = {"colon": ":", "tab": "\t"}

EXCLUDED_DIR_NAMES = {".git", "node_modules", "worktrees", ".venv", "__pycache__"}


class Holder(object):
    def __init__(self, hid, path, begin_line, sep_word, field):
        self.id = hid
        self.path = path
        self.begin_line = begin_line
        self.sep_word = sep_word
        self.field = field
        self.paths = set()


def candidate_files(root):
    """Return (mode, [relative paths]). Tracked-tree first; filesystem walk as fallback."""
    try:
        out = subprocess.run(
            ["git", "-C", root, "ls-files", "-z"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=True,
        ).stdout
        rels = [p for p in out.decode("utf-8", "replace").split("\0") if p]
        if rels:
            return "tracked", rels
    except (OSError, subprocess.CalledProcessError):
        pass

    rels = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDED_DIR_NAMES]
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            rels.append(os.path.relpath(full, root))
    return "walk", sorted(rels)


def scan_file(root, rel):
    """Return (holders, problems, unreadable_reason_or_None) for one file."""
    full = os.path.join(root, rel)
    try:
        with open(full, "r", encoding="utf-8", errors="strict") as fh:
            lines = fh.read().splitlines()
    except UnicodeDecodeError:
        # A binary or non-UTF-8 file is legitimately not a holder. This is a
        # classification, not an outage, so it is NOT reported as NOT-EVALUATED.
        return [], [], None
    except OSError as exc:
        return [], [], "unreadable: %s" % (exc.strerror or str(exc),)

    holders = []
    problems = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        if LOOSE_END.match(line):
            problems.append(
                ("%s@%d" % (rel, i + 1), "mirror-pair-set END at %s:%d has no matching BEGIN" % (rel, i + 1))
            )
            i += 1
            continue
        if not LOOSE_BEGIN.match(line):
            i += 1
            continue

        begin_line = i + 1
        m = STRICT_BEGIN.match(line)
        if not m:
            problems.append(
                (
                    "%s@%d" % (rel, begin_line),
                    "malformed BEGIN marker at %s:%d — expected "
                    "'# mirror-pair-set: BEGIN holder=<id> sep=<colon|tab> field=<n>', got: %s"
                    % (rel, begin_line, line.strip()),
                )
            )
            i += 1
            continue

        hid, sep_word, field_s = m.group(1), m.group(2), m.group(3)
        field = int(field_s)
        holder = Holder(hid, rel, begin_line, sep_word, field)
        sep = SEP_CHAR[sep_word]

        j = i + 1
        closed = False
        while j < n:
            body = lines[j]
            if STRICT_END.match(body):
                closed = True
                break
            if LOOSE_END.match(body):
                problems.append(
                    (hid, "malformed END marker at %s:%d — expected '# mirror-pair-set: END', got: %s"
                        % (rel, j + 1, body.strip()))
                )
                closed = True
                break
            if LOOSE_BEGIN.match(body):
                problems.append(
                    (hid, "nested BEGIN at %s:%d before holder '%s' was closed" % (rel, j + 1, hid))
                )
                break
            stripped = body.strip()
            if stripped == "" or stripped.startswith("#"):
                j += 1
                continue
            if ARRAY_OPEN.match(body) or ARRAY_CLOSE.match(body):
                j += 1
                continue

            entry = stripped
            if len(entry) >= 2 and entry.startswith('"') and entry.endswith('"'):
                entry = entry[1:-1]
            parts = entry.split(sep, 1)
            if len(parts) < 2:
                problems.append(
                    (hid, "entry at %s:%d carries no '%s' separator: %s" % (rel, j + 1, sep_word, entry))
                )
            elif field > len(parts):
                problems.append(
                    (hid, "entry at %s:%d has no field %d after the first '%s' split: %s"
                        % (rel, j + 1, field, sep_word, entry))
                )
            else:
                holder.paths.add(parts[field - 1])
            j += 1

        if not closed and j >= n:
            problems.append((hid, "BEGIN at %s:%d has no matching END" % (rel, begin_line)))
        holders.append(holder)
        i = j + 1

    return holders, problems, None


def run(root):
    """Return (rows, verdict, exit_code)."""
    mode, rels = candidate_files(root)
    holders = []
    problems = []
    unreadable = []

    for rel in rels:
        fh, fp, unread = scan_file(root, rel)
        holders.extend(fh)
        problems.extend(fp)
        if unread is not None:
            unreadable.append((rel, unread))

    rows = [("SCAN", mode, str(len(rels)), str(len(unreadable)))]

    seen = {}
    for h in holders:
        if h.id in seen:
            problems.append(
                (h.id, "duplicate holder id '%s' — also declared at %s:%d; ids must be unique"
                    % (h.id, seen[h.id].path, seen[h.id].begin_line))
            )
        else:
            seen[h.id] = h

    rows.append(("HOLDERS", str(len(holders))))
    for h in sorted(holders, key=lambda x: (x.path, x.begin_line)):
        rows.append(("HOLDER", h.id, h.path, str(h.begin_line), str(len(h.paths))))

    union = set()
    for h in holders:
        union |= h.paths
    missing = []
    for h in sorted(holders, key=lambda x: (x.path, x.begin_line)):
        for p in sorted(union - h.paths):
            missing.append((p, h.id, h.path, str(h.begin_line)))

    if len(holders) == 0:
        rows.append(("VERDICT", "UNPARSEABLE"))
        rows.append(
            (
                "UNPARSEABLE",
                "-",
                "zero holders discovered over %d %s file(s) — the 'mirror-pair-set:' marker "
                "convention has moved or was removed; this is an input failure, not parity"
                % (len(rels), mode),
            )
        )
        for rel, why in unreadable:
            rows.append(("NOT-EVALUATED", rel, why))
        return rows, "UNPARSEABLE", 3

    if problems:
        rows.append(("VERDICT", "UNPARSEABLE"))
        for hid, why in problems:
            rows.append(("UNPARSEABLE", hid, why))
        for rel, why in unreadable:
            rows.append(("NOT-EVALUATED", rel, why))
        return rows, "UNPARSEABLE", 1

    if missing:
        rows.append(("VERDICT", "DIVERGENT"))
        for p, hid, hpath, hline in missing:
            rows.append(("MISSING", p, hid, hpath, hline))
        for rel, why in unreadable:
            rows.append(("NOT-EVALUATED", rel, why))
        return rows, "DIVERGENT", 1

    if unreadable:
        # An incomplete scan cannot support a parity claim: an unread file could hold a
        # divergent holder. Withhold the verdict rather than reporting a clean one.
        rows.append(("VERDICT", "NOT-EVALUATED"))
        for rel, why in unreadable:
            rows.append(("NOT-EVALUATED", rel, why))
        return rows, "NOT-EVALUATED", 1

    if len(holders) < 2:
        rows.append(("VERDICT", "UNPARSEABLE"))
        rows.append(
            (
                "UNPARSEABLE",
                holders[0].id,
                "vacuity guard: only %d holder discovered — 'all holders agree' over a single "
                "holder is vacuously true, and a PASS here is indistinguishable from a working "
                "check. A second holder is expected to carry a 'mirror-pair-set:' marker."
                % (len(holders),),
            )
        )
        return rows, "UNPARSEABLE", 1

    rows.append(("VERDICT", "PARITY"))
    return rows, "PARITY", 0


def emit(rows, stream):
    for row in rows:
        stream.write("\t".join(row) + "\n")


# ---------------------------------------------------------------------------
# Self-test
# ---------------------------------------------------------------------------

# Assembled from a variable rather than written literally: a bare marker line in this
# file would be discovered as a real holder by this very scanner. See the self-reference
# note in the module docstring; `selftest-file-registers-no-holders` guards it.
_MARK = "mirror-pair" + "-set:"
_BEGIN = "  # " + _MARK + " BEGIN holder={hid} sep={sep} field=1"
_END = "  # " + _MARK + " END"

DEPLOY_SHAPE = (
    "#!/usr/bin/env bash\ncheck() {{\n"
    + _BEGIN.replace("{sep}", "colon")
    + "\n  local -a MIRROR_PAIRS=(\n{entries}\n  )\n"
    + _END
    + "\n}}\n"
)

BLAST_SHAPE = (
    "#!/usr/bin/env bash\ndetect() {{\n"
    + _BEGIN.replace("{sep}", "tab")
    + "\n  local -a pairs=(\n{entries}\n  )\n"
    + _END
    + "\n}}\n"
)


def _colon_entries(paths):
    return "\n".join('      "%s:$DEPLOY_ROOT/.claude/rules/%s"' % (p, os.path.basename(p)) for p in paths)


def _tab_entries(paths):
    return "\n".join('    "%s\t.claude/rules/%s"' % (p, os.path.basename(p)) for p in paths)


def _write(root, rel, text):
    full = os.path.join(root, rel)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as fh:
        fh.write(text)


def _cases():
    """Each case yields (name, builder, expected_verdict, expected_exit, must_contain)."""
    a = ["core/rules/alpha.md", "core/rules/beta.md", "core/rules/gamma.md"]

    def two_agree(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        _write(root, "b.sh", BLAST_SHAPE.format(hid="blast-radius", entries=_tab_entries(a)))

    def two_diverge(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        _write(root, "b.sh", BLAST_SHAPE.format(hid="blast-radius", entries=_tab_entries(a[:2])))

    def three_diverge(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        _write(root, "b.sh", BLAST_SHAPE.format(hid="blast-radius", entries=_tab_entries(a)))
        _write(root, "c.sh", DEPLOY_SHAPE.format(hid="carrier", entries=_colon_entries(a[:2])))

    def three_agree(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        _write(root, "b.sh", BLAST_SHAPE.format(hid="blast-radius", entries=_tab_entries(a)))
        _write(root, "c.sh", DEPLOY_SHAPE.format(hid="carrier", entries=_colon_entries(a)))

    def begin_without_end(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        _write(
            root,
            "b.sh",
            "#!/usr/bin/env bash\n"
            "  # mirror-pair-set: BEGIN holder=blast-radius sep=tab field=1\n"
            "  local -a pairs=(\n" + _tab_entries(a) + "\n  )\n",
        )

    def swapped_separators(root):
        # The card's cross-extractor mutation: each holder declares the OTHER's
        # separator. This must FAIL, never pass vacuously.
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)).replace(
            "sep=colon", "sep=tab"))
        _write(root, "b.sh", BLAST_SHAPE.format(hid="blast-radius", entries=_tab_entries(a)).replace(
            "sep=tab", "sep=colon"))

    def single_holder(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))

    def zero_holders(root):
        _write(root, "a.sh", "#!/usr/bin/env bash\necho no markers here\n")

    def malformed_begin(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        _write(root, "b.sh", BLAST_SHAPE.format(hid="blast-radius", entries=_tab_entries(a)).replace(
            "sep=tab field=1", "sep=TAB field=one"))

    def duplicate_ids(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        _write(root, "b.sh", BLAST_SHAPE.format(hid="deploy-check", entries=_tab_entries(a)))

    # The field index is honored, not assumed. This fixture is built so the two halves
    # disagree in OPPOSITE directions: the SOURCE halves differ between holders while the
    # MIRROR halves are identical. Reading field 1 must therefore be DIVERGENT and
    # reading field 2 must be PARITY over the SAME bytes — a check that ignored `field`
    # and always read 1 could not produce both. (This also demonstrates why field 1 is
    # the comparable side in the real holders: their field-2 values are not even in the
    # same form, one carrying a deploy-root prefix the other does not.)
    def _split_halves(root, field):
        rows_a = "\n".join('      "src-a/%s:.claude/rules/%s"' % (os.path.basename(p), os.path.basename(p)) for p in a)
        rows_b = "\n".join('      "src-b/%s:.claude/rules/%s"' % (os.path.basename(p), os.path.basename(p)) for p in a)
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="holder-a", entries=rows_a).replace("field=1", "field=%d" % field))
        _write(root, "b.sh", DEPLOY_SHAPE.format(hid="holder-b", entries=rows_b).replace("field=1", "field=%d" % field))

    def field_two(root):
        _split_halves(root, 2)

    def field_one_control(root):
        _split_halves(root, 1)

    def field_out_of_range(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        _write(root, "b.sh", BLAST_SHAPE.format(hid="blast-radius", entries=_tab_entries(a)).replace(
            "field=1", "field=3"))

    def entry_missing_separator(root):
        _write(root, "a.sh", DEPLOY_SHAPE.format(hid="deploy-check", entries=_colon_entries(a)))
        broken = _tab_entries(a).replace("\t.claude/rules/gamma.md", "")
        _write(root, "b.sh", BLAST_SHAPE.format(hid="blast-radius", entries=broken))

    return [
        ("parity-two-holders", two_agree, "PARITY", 0, []),
        ("parity-three-holders", three_agree, "PARITY", 0, []),
        ("divergent-names-path-and-holder", two_diverge, "DIVERGENT", 1,
         ["MISSING\tcore/rules/gamma.md\tblast-radius"]),
        ("divergent-three-holder-arity", three_diverge, "DIVERGENT", 1,
         ["MISSING\tcore/rules/gamma.md\tcarrier"]),
        ("begin-without-end", begin_without_end, "UNPARSEABLE", 1, ["no matching END"]),
        ("swapped-separators-not-vacuous-pass", swapped_separators, "UNPARSEABLE", 1,
         ["carries no 'tab' separator", "carries no 'colon' separator"]),
        ("single-holder-vacuity-guard", single_holder, "UNPARSEABLE", 1, ["vacuity guard"]),
        ("zero-holders-input-failure", zero_holders, "UNPARSEABLE", 3, ["zero holders discovered"]),
        ("malformed-begin-not-invisible", malformed_begin, "UNPARSEABLE", 1, ["malformed BEGIN marker"]),
        ("duplicate-holder-ids", duplicate_ids, "UNPARSEABLE", 1, ["duplicate holder id"]),
        ("field-index-honored--field-2-parity", field_two, "PARITY", 0, []),
        ("field-index-honored--field-1-control", field_one_control, "DIVERGENT", 1,
         ["MISSING\tsrc-b/alpha.md\tholder-a"]),
        ("field-out-of-range", field_out_of_range, "UNPARSEABLE", 1, ["has no field 3"]),
        ("entry-missing-separator", entry_missing_separator, "UNPARSEABLE", 1, ["carries no 'tab' separator"]),
    ]


def _self_registers_no_holders():
    """Regression guard for the self-reference defect found on the first live run.

    This scanner is line-based over the whole tree and knows nothing about Python
    strings, so a bare marker example anywhere in this file registers it as a real
    holder. It did, and the live gate correctly reported UNPARSEABLE. Assert the
    property directly rather than trusting the authoring convention to hold.
    """
    holders, problems, unread = scan_file(os.path.dirname(os.path.abspath(__file__)),
                                          os.path.basename(os.path.abspath(__file__)))
    errs = []
    if holders:
        errs.append("registers %d holder(s): %s" % (len(holders), [h.id for h in holders]))
    if problems:
        errs.append("emits %d marker problem(s): %s" % (len(problems), problems[0][1][:120]))
    if unread is not None:
        errs.append("own source unreadable: %s" % (unread,))
    return errs


def self_test():
    passed = 0
    failed = 0

    errs = _self_registers_no_holders()
    if errs:
        failed += 1
        sys.stdout.write("FAIL  selftest-file-registers-no-holders — %s\n" % ("; ".join(errs),))
    else:
        passed += 1
        sys.stdout.write("ok    selftest-file-registers-no-holders (0 holders, 0 marker problems)\n")

    for name, build, want_verdict, want_exit, must_contain in _cases():
        tmp = tempfile.mkdtemp(prefix="mpp-selftest-")
        build(tmp)
        rows, verdict, code = run(tmp)
        blob = "\n".join("\t".join(r) for r in rows)
        errs = []
        if verdict != want_verdict:
            errs.append("verdict %s != %s" % (verdict, want_verdict))
        if code != want_exit:
            errs.append("exit %d != %d" % (code, want_exit))
        for needle in must_contain:
            if needle not in blob:
                errs.append("missing evidence: %r" % (needle,))
        if errs:
            failed += 1
            sys.stdout.write("FAIL  %s — %s\n" % (name, "; ".join(errs)))
            sys.stdout.write(blob + "\n")
        else:
            passed += 1
            sys.stdout.write("ok    %s (%s, exit %d)\n" % (name, verdict, code))

    # A self-test whose own case list is empty would print a clean summary while
    # asserting nothing. State the denominator and refuse a vacuous green.
    total = passed + failed
    sys.stdout.write("SELF-TEST %d passed, %d failed, %d cases\n" % (passed, failed, total))
    if total == 0:
        sys.stdout.write("FAIL  self-test enumerated zero cases — a vacuous pass\n")
        return 1
    return 0 if failed == 0 else 1


def main(argv=None):
    ap = argparse.ArgumentParser(description="Assert every holder of the mirror-pair path set agrees.")
    ap.add_argument("--root", default=".", help="repository root to scan (default: .)")
    ap.add_argument("--output-format", default="tsv", choices=["tsv"], help="output format (default: tsv)")
    ap.add_argument("--self-test", action="store_true", help="run the built-in case suite and exit")
    args = ap.parse_args(argv)

    if args.self_test:
        return self_test()

    rows, _verdict, code = run(args.root)
    emit(rows, sys.stdout)
    return code


if __name__ == "__main__":
    sys.exit(main())

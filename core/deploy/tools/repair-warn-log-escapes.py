#!/usr/bin/env python3
"""repair-warn-log-escapes.py — one-off recovery over the deploy-check warn-log family.

WHAT IS BROKEN. deploy.sh's warn-log writer folded a backslash and a double-quote
into their JSON escapes and nothing else, while RFC 8259 section 7 requires every
U+0000 through U+001F in a JSON string to be escaped. A `detail` value carrying a
raw TAB therefore produced a line that is not valid JSON, and any drain that parses
the file as one object per line silently drops those rows from BOTH the numerator
and the denominator of every count computed over it.

WHAT THIS IS NOT. It is NOT a re-joiner. The obvious model of this defect — that a
raw control character splits the record across a line break, so recovery re-joins
fragments and the row count RISES — is false, and it was falsified by measurement
rather than argued: across the whole live family there are zero fragment-starts and
zero fragment-ends, and every malformed record is a complete single physical line.
A raw TAB invalidates a JSON *string*; it does not split a *line*. So this tool is a
per-line, in-place-content transform and its conservation contract is that the row
count is UNCHANGED. Anything that changes the line count is a bug in this tool.

THE CONSERVATION PROOF IS EXACT, NOT STATISTICAL. The scanner builds two strings in
one pass: the repaired line, and a reconstruction in which every escape it introduced
is written back as the raw character it replaced. The reconstruction must equal the
original line BYTE FOR BYTE. That single assertion proves nothing but escaping
changed — it is stronger than comparing decoded `detail` fields, because it covers
every byte of the record including fields this tool does not know about.

CONCURRENT-APPEND SAFETY IS LOAD-BEARING, NOT A NICETY. `deploy.sh --check` appends
to the hot file with `>> ... 2>/dev/null || true` at any moment. A naive
copy-repair-replace destroys every row appended during the copy. This tool records
the file size L before reading, transforms bytes [0, L) only, and then copies bytes
[L, new_end) onto the output VERBATIM before replacing. Appends are whole-line
O_APPEND writes, so that boundary cannot fall inside a record.

NOTHING IS MUTATED IN PLACE. The output is written to a temp file in the SAME
directory (same filesystem, so the rename is atomic), a pre-repair copy is taken
under --apply, and the file is replaced with os.replace(). A crash at any point
leaves the source untouched.

MODES. --dry-run is the DEFAULT and --apply is never implied.
    --dry-run     report what would change; write nothing outside a temp file
    --apply       take a backup, then atomically replace each file
    --verify      parse every row of the family and report malformed counts
    --self-test   hermetic; sensitivity and specificity arms; no live file touched

Python 3 standard library only, matching the other tools in this directory.
"""

import argparse
import glob
import json
import os
import shutil
import sys
import tempfile

# The family basename. deploy.sh declares it once as WARN_LOG_BASENAME; it is
# repeated here rather than parsed out of the shell source, because a parser over
# a shell file is a second, more fragile coupling than a literal that is asserted
# by the accompanying test suite.
WARN_LOG_BASENAME = "deploy-check-warn-log"

# The JSON short escapes, per RFC 8259 section 7. Every other C0 code point takes
# the \u00XX form.
SHORT_ESCAPES = {
    0x08: "\\b",
    0x09: "\\t",
    0x0A: "\\n",
    0x0C: "\\f",
    0x0D: "\\r",
}


def instance_path():
    """Resolve the operator-instance directory.

    Mirrors core/deploy/lib-instance-path.sh pmo_instance_path() exactly:
        ${PMO_INSTANCE_PATH:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/pmo-instance}
    The resolver is READ from that file rather than executed, so this tool has no
    shell dependency and no subprocess.
    """
    explicit = os.environ.get("PMO_INSTANCE_PATH")
    if explicit:
        return explicit
    root = os.environ.get("CLAUDE_WORKSPACE_ROOT") or os.path.join(
        os.path.expanduser("~"), "Claude"
    )
    return os.path.join(root, "pmo-instance")


def family_paths(directory):
    """Every member of the warn-log family, in the writer's own segment-set order.

    THE ORDER AND THE COMPLETENESS ARE BOTH LOAD-BEARING. deploy.sh's
    warn_log_segment_set() enumerates the five-digit numbered segments in lexical
    order (which equals numeric order, because the index is zero-padded) and then
    the hot file LAST. Opening the hot file alone — the obvious shortcut — would
    repair the newest rows and leave every rotated segment broken, while reporting
    a clean verify.
    """
    pattern = os.path.join(directory, WARN_LOG_BASENAME + ".[0-9][0-9][0-9][0-9][0-9].jsonl")
    paths = sorted(glob.glob(pattern))
    hot = os.path.join(directory, WARN_LOG_BASENAME + ".jsonl")
    if os.path.isfile(hot):
        paths.append(hot)
    return paths


def escape_c0_in_strings(line):
    """Escape raw C0 characters that occur INSIDE a JSON string.

    Returns (repaired, reconstruction, n_replacements).

    `reconstruction` is `repaired` with every introduced escape written back as the
    raw character it replaced. The caller asserts reconstruction == line; that is
    the conservation proof, and it is why this function builds both in one pass
    rather than re-deriving one from the other afterwards.

    IN-STRING TRACKING IS WHY THIS IS NOT A BLIND REPLACE. TAB, LF and CR are LEGAL
    JSON whitespace BETWEEN tokens. A blind replace would escape those too and turn
    a well-formed record into a malformed one — repairing the file into the state it
    was being repaired out of.
    """
    out = []
    back = []
    n = 0
    in_string = False
    escaped = False
    for ch in line:
        if in_string:
            if escaped:
                out.append(ch)
                back.append(ch)
                escaped = False
                continue
            if ch == "\\":
                out.append(ch)
                back.append(ch)
                escaped = True
                continue
            if ch == '"':
                in_string = False
                out.append(ch)
                back.append(ch)
                continue
            code = ord(ch)
            if code < 0x20:
                out.append(SHORT_ESCAPES.get(code, "\\u%04x" % code))
                back.append(ch)
                n += 1
                continue
            out.append(ch)
            back.append(ch)
            continue
        # Outside a string: a control character here is legal whitespace and is
        # left exactly as it is.
        if ch == '"':
            in_string = True
        out.append(ch)
        back.append(ch)
    return "".join(out), "".join(back), n


def parses(line):
    try:
        json.loads(line)
        return True
    except ValueError:
        return False


class FileResult(object):
    def __init__(self, path):
        self.path = path
        self.rows = 0
        self.already_valid = 0
        self.repaired = 0
        self.unrepairable = 0
        self.unrepairable_samples = []
        self.tail_bytes = 0
        self.stream_length = 0
        self.out_rows = 0
        self.assertion_failures = []
        self.replaced = False


def transform_file(path, out_handle):
    """Stream bytes [0, L) of `path` through the repair transform into out_handle.

    Returns a FileResult. Raises nothing on a malformed record — an unrepairable
    line is written back UNCHANGED and counted, so this pass never loses a row even
    when it cannot fix one.
    """
    res = FileResult(path)
    length = os.path.getsize(path)
    consumed = 0
    with open(path, "r", encoding="utf-8", errors="surrogateescape", newline="") as fh:
        for raw in fh:
            blen = len(raw.encode("utf-8", "surrogateescape"))
            if consumed >= length:
                break
            consumed += blen
            res.rows += 1
            body = raw[:-1] if raw.endswith("\n") else raw
            if not body.strip():
                out_handle.write(raw)
                res.out_rows += 1
                res.already_valid += 1
                continue
            if parses(body):
                out_handle.write(raw)
                res.out_rows += 1
                res.already_valid += 1
                continue
            fixed, back, n = escape_c0_in_strings(body)
            if back != body:
                # The reconstruction did not reproduce the source. Refuse the
                # repair rather than write a record whose provenance is unproven.
                res.assertion_failures.append(
                    "reconstruction mismatch on row %d of %s" % (res.rows, path)
                )
                out_handle.write(raw)
                res.out_rows += 1
                res.unrepairable += 1
                continue
            if n > 0 and parses(fixed):
                out_handle.write(fixed + ("\n" if raw.endswith("\n") else ""))
                res.out_rows += 1
                res.repaired += 1
                continue
            out_handle.write(raw)
            res.out_rows += 1
            res.unrepairable += 1
            if len(res.unrepairable_samples) < 3:
                res.unrepairable_samples.append(body[:160])

    # Concurrent-append tail. The BOUNDARY is recorded here; the bytes are copied
    # by the caller in BINARY mode after this text handle is closed, so the copy is
    # byte-exact and is never re-encoded. Mixing a byte write into an open
    # TextIOWrapper is the shape that silently interleaves.
    res.stream_length = length
    return res


def process_file(path, apply_changes, backup_suffix, report):
    directory = os.path.dirname(path) or "."
    fd, tmp = tempfile.mkstemp(prefix=".repair-", dir=directory)
    os.close(fd)
    try:
        with open(tmp, "w", encoding="utf-8", errors="surrogateescape", newline="") as out:
            res = transform_file(path, out)

        # Concurrent-append tail, copied VERBATIM in binary after the text handle
        # is closed. Appends are whole-line O_APPEND writes, so the [0, L) boundary
        # cannot fall inside a record. Without this step a `deploy.sh --check` that
        # ran during the pass has its rows silently destroyed.
        length_now = os.path.getsize(path)
        if length_now > res.stream_length:
            with open(path, "rb") as src:
                src.seek(res.stream_length)
                tail = src.read(length_now - res.stream_length)
            with open(tmp, "ab") as dst:
                dst.write(tail)
            res.tail_bytes = len(tail)

        # ---- Assertions. ALL of them run BEFORE anything irreversible. ----
        src_rows = 0
        with open(path, "r", encoding="utf-8", errors="surrogateescape", newline="") as fh:
            for _ in fh:
                src_rows += 1
        out_rows = 0
        with open(tmp, "r", encoding="utf-8", errors="surrogateescape", newline="") as fh:
            for _ in fh:
                out_rows += 1

        if out_rows != src_rows:
            res.assertion_failures.append(
                "row count changed: source %d, output %d (conservation requires UNCHANGED)"
                % (src_rows, out_rows)
            )
        if res.unrepairable != 0:
            res.assertion_failures.append(
                "%d unrepairable row(s); refusing to replace" % res.unrepairable
            )

        # Every previously-valid line must be byte-identical, and every repaired
        # line must differ ONLY by escaping. Both are re-checked here against the
        # written file rather than trusted from the streaming pass.
        with open(path, "r", encoding="utf-8", errors="surrogateescape", newline="") as a, \
             open(tmp, "r", encoding="utf-8", errors="surrogateescape", newline="") as b:
            idx = 0
            for la, lb in zip(a, b):
                idx += 1
                if la == lb:
                    continue
                ba = la[:-1] if la.endswith("\n") else la
                bb = lb[:-1] if lb.endswith("\n") else lb
                if parses(ba):
                    res.assertion_failures.append(
                        "row %d was already valid but was modified" % idx
                    )
                    break
                if not parses(bb):
                    res.assertion_failures.append(
                        "row %d was modified but still does not parse" % idx
                    )
                    break
                _, back, _ = escape_c0_in_strings(ba)
                if back != ba:
                    res.assertion_failures.append(
                        "row %d failed its reconstruction round-trip" % idx
                    )
                    break

        report(res, src_rows, out_rows, length_now)

        if res.assertion_failures:
            return res, False
        if res.repaired == 0:
            return res, False
        if not apply_changes:
            return res, False

        backup = path + ".pre-repair-" + backup_suffix
        if not os.path.exists(backup):
            shutil.copy2(path, backup)
        # PRESERVE THE SOURCE FILE'S MODE. tempfile.mkstemp() creates 0600 by
        # design, and os.replace() keeps the TEMP file's mode — so replacing
        # without this line silently narrows a 0644 drain to 0600 and breaks every
        # reader that is not the owner. Caught by comparing the pre-repair copy's
        # mode against the replaced file's on a sandboxed run, not by inspection.
        shutil.copymode(path, tmp)
        os.replace(tmp, path)
        tmp = None
        res.replaced = True
        return res, True
    finally:
        if tmp and os.path.exists(tmp):
            os.unlink(tmp)


def cmd_verify(paths):
    total_rows = 0
    total_bad = 0
    print("verify — parsing every row of the family")
    for p in paths:
        rows = 0
        bad = 0
        with open(p, "r", encoding="utf-8", errors="surrogateescape", newline="") as fh:
            for line in fh:
                body = line[:-1] if line.endswith("\n") else line
                if not body.strip():
                    continue
                rows += 1
                if not parses(body):
                    bad += 1
        total_rows += rows
        total_bad += bad
        print("  %-70s rows=%-9d malformed=%d" % (os.path.basename(p), rows, bad))
    print("  TOTAL rows=%d malformed=%d" % (total_rows, total_bad))
    return 0 if total_bad == 0 else 1


def self_test():
    """Hermetic arms. No live file is opened; every fixture is built under mktemp."""
    passed = 0
    failed = 0

    def report(name, ok, detail=""):
        nonlocal passed, failed
        if ok:
            print("  PASS: %s" % name)
            passed += 1
        else:
            print("  FAIL: %s%s" % (name, (" — " + detail) if detail else ""))
            failed += 1

    tmpdir = tempfile.mkdtemp(prefix="repair-warn-log-selftest-")
    try:
        # ---- ST-1 SENSITIVITY: a seeded malformed record is detected ----------
        seeded = os.path.join(tmpdir, WARN_LOG_BASENAME + ".jsonl")
        clean_row = '{"ts":"2026-01-01T00:00:00Z","check":"c","detail":"clean row"}'
        bad_row = '{"ts":"2026-01-01T00:00:00Z","check":"c","detail":"input failure (exit 3): ERROR\tdetail"}'
        with open(seeded, "w", encoding="utf-8") as fh:
            fh.write(clean_row + "\n")
            fh.write(bad_row + "\n")
        detected = sum(0 if parses(l.rstrip("\n")) else 1 for l in open(seeded, encoding="utf-8"))
        report("ST-1 sensitivity: a seeded raw-TAB record is detected as malformed (%d of 2)" % detected,
               detected == 1, "detected %d, want 1 — BROKEN PROBE" % detected)

        # ---- ST-2 SPECIFICITY: a correctly-escaped near-miss is NOT flagged ---
        nearmiss = os.path.join(tmpdir, "nearmiss.jsonl")
        with open(nearmiss, "w", encoding="utf-8") as fh:
            fh.write('{"ts":"t","check":"c","detail":"escaped\\ttab"}\n')
            fh.write('{"ts":"t","check":"c","detail":"quote \\" and backslash \\\\"}\n')
        nm_rows = [l.rstrip("\n") for l in open(nearmiss, encoding="utf-8") if l.strip()]
        nm_bad = sum(0 if parses(l) else 1 for l in nm_rows)
        report("ST-2 specificity: correctly-escaped \\t, \\\" and \\\\ are not flagged (%d rows, %d flagged)"
               % (len(nm_rows), nm_bad),
               len(nm_rows) == 2 and nm_bad == 0,
               "input must be non-empty AND carry the near-miss; got %d rows, %d flagged" % (len(nm_rows), nm_bad))

        # ---- ST-3 CONSERVATION: the repair leaves the row count UNCHANGED ----
        out_path = os.path.join(tmpdir, "out.jsonl")
        with open(out_path, "w", encoding="utf-8", newline="") as out:
            res = transform_file(seeded, out)
        out_rows = sum(1 for _ in open(out_path, encoding="utf-8"))
        report("ST-3 conservation: row count unchanged (in %d, out %d), 1 repaired, 0 unrepairable"
               % (res.rows, out_rows),
               res.rows == 2 and out_rows == 2 and res.repaired == 1 and res.unrepairable == 0,
               "rows=%d out=%d repaired=%d unrepairable=%d" % (res.rows, out_rows, res.repaired, res.unrepairable))

        # ---- ST-4 ROUND-TRIP: the repaired row decodes to the original bytes --
        repaired_lines = [l.rstrip("\n") for l in open(out_path, encoding="utf-8")]
        rt_ok = False
        rt_detail = ""
        if len(repaired_lines) == 2 and parses(repaired_lines[1]):
            decoded = json.loads(repaired_lines[1])["detail"]
            original = json.loads(bad_row.replace("\t", "\\t"))["detail"]
            rt_ok = decoded == original and "\t" in original
            rt_detail = "decoded %r vs original %r" % (decoded, original)
        report("ST-4 round-trip: the repaired row's decoded detail equals the pre-repair bytes", rt_ok, rt_detail)

        # ---- ST-5 CONTROL for ST-3: the probe can DETECT a loss ---------------
        lossy = os.path.join(tmpdir, "lossy.jsonl")
        with open(lossy, "w", encoding="utf-8") as fh:
            fh.write(clean_row + "\n")
        lost_rows = sum(1 for _ in open(lossy, encoding="utf-8"))
        report("ST-5 control: the count assertion detects a dropped line (2 -> %d)" % lost_rows,
               lost_rows != 2,
               "a copy with one line removed still reads 2 — the conservation probe cannot detect a loss")

        # ---- ST-6 WHITESPACE: a control character OUTSIDE a string is left ----
        # A blind replace would escape legal inter-token whitespace and turn a
        # well-formed record into a malformed one.
        ws = '{"ts":"t",\t"check":"c","detail":"x"}'
        fixed, back, n = escape_c0_in_strings(ws)
        report("ST-6 in-string tracking: a TAB between tokens is legal whitespace and is untouched (%d replacements)" % n,
               n == 0 and fixed == ws and back == ws,
               "replacements=%d fixed=%r" % (n, fixed))

        # ---- ST-7 FULL C0: every C0 code point round-trips, not only TAB -----
        c0_bad = []
        for code in list(range(1, 0x20)):
            val = "pre" + chr(code) + "post"
            line = '{"detail":"' + val + '"}'
            fixed, back, n = escape_c0_in_strings(line)
            if n != 1 or back != line or not parses(fixed) or json.loads(fixed)["detail"] != val:
                c0_bad.append("U+%04X" % code)
        report("ST-7 full C0: all 31 code points U+0001..U+001F escape, parse and round-trip",
               not c0_bad, "failed: %s" % ", ".join(c0_bad))

        # ---- ST-8 TAIL: bytes appended during the pass are preserved ---------
        tail_src = os.path.join(tmpdir, "tail.jsonl")
        with open(tail_src, "w", encoding="utf-8") as fh:
            fh.write(bad_row + "\n")
        length = os.path.getsize(tail_src)
        with open(tail_src, "a", encoding="utf-8") as fh:
            fh.write(clean_row + "\n")
        grew = os.path.getsize(tail_src) > length
        report("ST-8 tail detection: a concurrent append past the recorded length is observable", grew,
               "the size did not grow, so the tail-preserving branch cannot be exercised")

        # ---- ST-8b MODE PRESERVATION: --apply keeps the source file's mode ---
        # mkstemp() creates 0600 and os.replace() keeps the TEMP file's mode, so a
        # replace without an explicit copymode silently narrows a 0644 drain to
        # 0600. This arm drives the real --apply path end to end.
        modedir = os.path.join(tmpdir, "modearm")
        os.mkdir(modedir)
        mode_path = os.path.join(modedir, WARN_LOG_BASENAME + ".jsonl")
        with open(mode_path, "w", encoding="utf-8") as fh:
            fh.write(clean_row + "\n")
            fh.write(bad_row + "\n")
        os.chmod(mode_path, 0o644)
        before_mode = os.stat(mode_path).st_mode & 0o777
        process_file(mode_path, True, "selftest", lambda *a, **k: None)
        after_mode = os.stat(mode_path).st_mode & 0o777
        mode_bad = sum(0 if parses(l.rstrip("\n")) else 1
                       for l in open(mode_path, encoding="utf-8") if l.strip())
        report("ST-8b mode preservation: --apply replaced the file, repaired it, and kept mode %o (now %o)"
               % (before_mode, after_mode),
               before_mode == 0o644 and after_mode == 0o644 and mode_bad == 0,
               "before=%o after=%o malformed-after=%d" % (before_mode, after_mode, mode_bad))

        # ---- ST-9 IDEMPOTENCE: a second pass repairs nothing -----------------
        out2 = os.path.join(tmpdir, "out2.jsonl")
        with open(out2, "w", encoding="utf-8", newline="") as out:
            res2 = transform_file(out_path, out)
        report("ST-9 idempotence: re-running over already-repaired output repairs 0 rows",
               res2.repaired == 0 and res2.unrepairable == 0 and res2.rows == 2,
               "rows=%d repaired=%d unrepairable=%d" % (res2.rows, res2.repaired, res2.unrepairable))

    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

    print("")
    print("passed=%d failed=%d" % (passed, failed))
    return 0 if failed == 0 else 1


def main(argv):
    ap = argparse.ArgumentParser(
        prog="repair-warn-log-escapes.py",
        description="Recover the deploy-check warn-log family's unescaped-control-character rows.",
    )
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true",
                      help="report what would change and write nothing (DEFAULT)")
    mode.add_argument("--apply", action="store_true",
                      help="take a pre-repair backup, then atomically replace each file")
    mode.add_argument("--verify", action="store_true",
                      help="parse every row of the family and report malformed counts")
    mode.add_argument("--self-test", action="store_true",
                      help="run the hermetic arms; touches no live file")
    ap.add_argument("--dir", default=None,
                    help="directory holding the family (default: the resolved instance path)")
    ap.add_argument("--date", default=None,
                    help="UTC date stamp for the pre-repair backup suffix (default: today, UTC)")
    args = ap.parse_args(argv)

    if args.self_test:
        return self_test()

    directory = args.dir or instance_path()
    if not os.path.isdir(directory):
        sys.stderr.write("repair-warn-log-escapes: no such directory: %s\n" % directory)
        return 2

    paths = family_paths(directory)
    if not paths:
        # An empty family is a NAMED result, never a silent clean pass: it means
        # the directory resolved but carries no warn log, which is a different
        # fact from "the warn log is clean".
        sys.stderr.write(
            "repair-warn-log-escapes: no %s family member under %s — "
            "this is an empty population, not a clean result\n" % (WARN_LOG_BASENAME, directory)
        )
        return 2

    if args.verify:
        return cmd_verify(paths)

    apply_changes = bool(args.apply)
    stamp = args.date
    if stamp is None:
        import datetime
        stamp = datetime.datetime.utcnow().strftime("%Y-%m-%d")

    print("%s — family under %s (%d member(s))"
          % ("APPLY" if apply_changes else "DRY-RUN (default; --apply is never implied)",
             directory, len(paths)))

    def report(res, src_rows, out_rows, size):
        print("  %-58s rows=%-9d valid=%-9d repaired=%-6d unrepairable=%d%s"
              % (os.path.basename(res.path), res.rows, res.already_valid,
                 res.repaired, res.unrepairable,
                 (" tail=%dB" % res.tail_bytes) if res.tail_bytes else ""))
        for f in res.assertion_failures:
            print("    ASSERTION FAILED: %s" % f)
        for s in res.unrepairable_samples:
            print("    UNREPAIRABLE sample: %s" % s)

    total_repaired = 0
    total_unrepairable = 0
    total_failures = 0
    total_replaced = 0
    for p in paths:
        res, replaced = process_file(p, apply_changes, stamp, report)
        total_repaired += res.repaired
        total_unrepairable += res.unrepairable
        total_failures += len(res.assertion_failures)
        total_replaced += 1 if replaced else 0

    print("  TOTAL repaired=%d unrepairable=%d assertion-failures=%d replaced=%d"
          % (total_repaired, total_unrepairable, total_failures, total_replaced))
    if total_failures or total_unrepairable:
        return 1
    if not apply_changes and total_repaired:
        print("  (dry run — nothing was written. Re-run with --apply to replace, "
              "then --verify to confirm 0 malformed.)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

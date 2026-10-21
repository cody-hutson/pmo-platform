#!/usr/bin/env python3
"""check-tool-exec-mode.py — every interpreter-line-bearing tracked tool file is executable.

WHAT IT ASSERTS
    Under the two tool trees (ROOTS below), every tracked regular file whose content
    begins with an interpreter line ("#!") is tracked with git mode 100755 — unless the
    exemption list names it, with a class and a reason. And every exemption still
    describes the tree: it names a tracked file under the roots that begins with an
    interpreter line and is tracked 100644. An exemption that no longer does is a
    finding, so the list cannot rot into a silent, permanent pass.

WHY IT EXISTS
    A tracked file's mode is whatever the authoring path left. A file created by an
    editor or a write tool lands 100644; nothing compared that to the invocability the
    file's own first line declares. The class was drained one file at a time while new
    members kept arriving. This is the class check.

WHAT IS READ — THE INDEX, NEVER THE FILESYSTEM
    All three inputs come from git: `git ls-files -s` for the tracked mode,
    `git cat-file --batch` for the first two bytes of the blob that entry names, and
    the same batched read for the exemption list's own tracked blob. A filesystem
    executable bit is a proxy: it follows umask, checkout options and core.fileMode,
    and can disagree with what the repository ships. Reading the index also means a
    locally deleted or locally edited file — the list included — cannot move the
    verdict: a row takes effect when it is staged, and a list absent from the index is
    an empty list.

    Every git call drops the repository-location variables git itself publishes
    (`git rev-parse --local-env-vars`). Run from a hook or a rebase, this process
    inherits GIT_DIR and its siblings, and `-C <root>` overrides none of them: an
    inherited GIT_OBJECT_DIRECTORY would send the self-test's fixture objects into the
    caller's object store, and an inherited GIT_DIR would make the scan read the wrong
    index. The list is read from git at run time rather than written here by hand.

WHY WHOLE-TREE AND NOT CHANGED-FILES
    A file reaches a branch by a merge from the mainline as often as by a commit on the
    branch. Relative to a pull request's base such a file is unchanged, so a changed-file
    scan reports green on the event this check exists to catch.

DECLARED COVERAGE BOUNDARY
    Two trees only, recursively. It does NOT assert: the mode of any file outside them;
    that an executable file is correct to execute; that a sourced library is 100644 (a
    library tracked 100755 passes — the check is one-directional by design); or the
    mode a file has on disk in any checkout.

EXIT CODES
    0  clean.
    1  one or more findings — one `FAIL: ` line each.
    2  THE INSTRUMENT CANNOT ASSERT: it cannot vouch for its own reading. The control
       arm observed zero executable interpreter-line files, a scanned root enumerates
       zero tracked files (the roots no longer reach a tree), the exemption list does
       not parse, a --self-test arm did not behave as declared, or the tool crashed. A
       usage error is argparse's own exit 2 and asserts nothing either.
    3  NOT-EVALUATED — this is not a clean result. The tree it was pointed at could not
       be read: not a git work tree, git could not run or a read exited non-zero, or an
       index entry is unmerged (the tracked mode is undefined until the merge resolves).
    Neither 2 nor 3 is ever a clean zero or a finding. The split is the one this
    directory's reconciler and commit-message tool use: 2 for the instrument's own
    state, 3 for an input that did not return.

OUTPUT
    FAIL: <path> — <detail>            one per finding
    EXEMPT: <path> — <class>           one per exemption applied (never silent)
    DENOM: ...                         one record line: population, control, counts
    SCAN-ERROR: <reason>               on exit 2 or 3

USAGE
    python3 core/deploy/tools/check-tool-exec-mode.py               # scan this work tree
    python3 core/deploy/tools/check-tool-exec-mode.py --no-exempt   # price the exemptions
    python3 core/deploy/tools/check-tool-exec-mode.py --root <dir>  # scan another work tree
    python3 core/deploy/tools/check-tool-exec-mode.py --self-test   # hermetic arms

Stdlib only; Python 3.9+. No network. Reads tracked state only — a shallow checkout is
sufficient.
"""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile

# The scanned trees. A root that enumerates zero tracked files is a broken probe (exit
# 2), and an exemption row outside these roots is a stale-exemption finding — so
# narrowing this tuple while rows for the dropped tree remain turns the check red.
ROOTS = ("release/tools/", "core/deploy/tools/")

EXEMPTIONS_REL = "core/deploy/allowlists/skip-tool-exec-mode-check.txt"

# Closed set. A row whose class is not one of these is unparseable (exit 2).
CLASSES = ("sourced-library", "imported-module", "fixture")

ROW_RE = re.compile(r"^(?P<path>\S+)\s+#\s*(?P<cls>[A-Za-z-]+):\s*(?P<reason>\S.*)$")

EXIT_CLEAN, EXIT_FINDINGS, EXIT_CANNOT_ASSERT, EXIT_NOT_EVALUATED = 0, 1, 2, 3

NOT_CLEAN = "NOT-EVALUATED — this is not a clean result"


class CannotAssert(Exception):
    """The instrument cannot vouch for its own reading (exit 2)."""


class NotEvaluated(Exception):
    """The tree the scan was pointed at could not be read (exit 3)."""


_LOCAL_ENV_VARS: tuple[str, ...] | None = None


def local_env_vars() -> tuple[str, ...]:
    """The repository-location variables git publishes, asked of git once.

    The query itself runs with every GIT_* variable removed, so nothing inherited can
    redirect or break it. A list without GIT_DIR is not git's list: exit 2.
    """
    global _LOCAL_ENV_VARS
    if _LOCAL_ENV_VARS is None:
        env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        try:
            proc = subprocess.run(["git", "rev-parse", "--local-env-vars"], env=env,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
        except (OSError, subprocess.SubprocessError) as exc:
            raise NotEvaluated(f"git could not run: {exc}") from exc
        if proc.returncode != 0:
            raise NotEvaluated(f"git rev-parse --local-env-vars exited {proc.returncode}")
        names = tuple(sorted(set(proc.stdout.decode("utf-8", "replace").split())))
        if "GIT_DIR" not in names:
            raise CannotAssert("git's list of repository-location variables does not name "
                               "GIT_DIR, so the read cannot be isolated from the caller")
        _LOCAL_ENV_VARS = names
    return _LOCAL_ENV_VARS


def _git(root: str, *args: str, stdin: bytes | None = None) -> bytes:
    strip = set(local_env_vars())
    env = {k: v for k, v in os.environ.items() if k not in strip}
    try:
        proc = subprocess.run(
            ["git", "-C", root, *args],
            input=stdin,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            timeout=120,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise NotEvaluated(f"git {args[0]} could not run: {exc}") from exc
    if proc.returncode != 0:
        detail = proc.stderr.decode("utf-8", "replace").strip().splitlines()[:1]
        raise NotEvaluated(f"git {args[0]} exited {proc.returncode}: {' '.join(detail)}")
    return proc.stdout


def read_index(root: str) -> tuple[list[tuple[str, str, str]], tuple[str, str] | None]:
    """(mode, blob sha, path) for every index entry under ROOTS, and the list's (mode, sha)."""
    out = _git(root, "ls-files", "-s", "-z", "--", *ROOTS, EXEMPTIONS_REL)
    entries: list[tuple[str, str, str]] = []
    listing: tuple[str, str] | None = None
    for rec in out.split(b"\0"):
        if not rec:
            continue
        meta, _, raw_path = rec.partition(b"\t")
        mode, sha, stage = meta.split()
        path = raw_path.decode("utf-8", "surrogateescape")
        if stage != b"0":
            raise NotEvaluated(f"unmerged index entry (stage {stage.decode()}) at {path} — the "
                               f"tracked mode is undefined until the merge is resolved")
        if path == EXEMPTIONS_REL:
            listing = (mode.decode(), sha.decode())
        else:
            entries.append((mode.decode(), sha.decode(), path))
    return entries, listing


def read_blobs(root: str, shas: list[str], whole: set[str]) -> dict[str, bytes]:
    """blob sha -> its first two bytes (its whole content for a sha in `whole`), from ONE
    `git cat-file --batch` call."""
    uniq = sorted(set(shas))
    if not uniq:
        return {}
    out = _git(root, "cat-file", "--batch", stdin=("\n".join(uniq) + "\n").encode())
    blobs: dict[str, bytes] = {}
    pos = 0
    for sha in uniq:
        nl = out.find(b"\n", pos)
        if nl < 0:
            raise NotEvaluated(f"cat-file output ended before object {sha}")
        header = out[pos:nl].split()
        if len(header) != 3 or header[1] != b"blob":
            raise NotEvaluated(f"object {sha} is not a readable blob: {out[pos:nl][:60]!r}")
        size = int(header[2])
        start = nl + 1
        blobs[sha] = out[start:start + size] if sha in whole else out[start:start + 2]
        pos = start + size + 1
    return blobs


def parse_exemptions(data: bytes) -> dict[str, tuple[str, str]]:
    """path -> (class, reason), from the list's tracked bytes. Malformed is exit 2."""
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise CannotAssert(f"the exemption list {EXEMPTIONS_REL} is not UTF-8 text "
                           f"(byte {exc.start})") from exc
    rows: dict[str, tuple[str, str]] = {}
    for n, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = ROW_RE.match(line)
        if not m:
            raise CannotAssert(
                f"exemption row {n} is not `<path>  # <class>: <reason>` — an entry "
                f"without a class and a reason is a parse error: {line[:80]!r}"
            )
        p, cls = m.group("path"), m.group("cls")
        if cls not in CLASSES:
            raise CannotAssert(f"exemption row {n}: class {cls!r} is not one of {', '.join(CLASSES)}")
        if any(ch in p for ch in "*?[") or p.endswith("/"):
            raise CannotAssert(f"exemption row {n}: {p!r} is a pattern — a row names exactly one file")
        if p in rows:
            raise CannotAssert(f"exemption row {n}: {p!r} is listed twice")
        rows[p] = (cls, m.group("reason"))
    return rows


def scan_tree(root: str, apply_exemptions: bool = True) -> tuple[int, list[str]]:
    """The predicate. Returns (exit code, output lines)."""
    lines: list[str] = []
    try:
        if _git(root, "rev-parse", "--is-inside-work-tree").strip() != b"true":
            raise NotEvaluated(f"{root} is not inside a git work tree")
        entries, listing = read_index(root)
        per_root = {r: sum(1 for _m, _s, p in entries if p.startswith(r)) for r in ROOTS}
        empty = [r for r, n in per_root.items() if n == 0]
        if empty:
            raise CannotAssert(
                f"{', '.join(empty)} enumerates zero tracked files — a relocated or "
                f"mistyped tree must never read clean"
            )
        regular = [(m, s, p) for m, s, p in entries if m in ("100644", "100755")]
        want = [s for _m, s, _p in regular]
        whole: set[str] = set()
        if apply_exemptions and listing is not None:
            if listing[0] not in ("100644", "100755"):
                raise CannotAssert(f"the exemption list {EXEMPTIONS_REL} is tracked as a "
                                   f"{listing[0]} entry, not a regular file")
            want.append(listing[1])
            whole.add(listing[1])
        blobs = read_blobs(root, want, whole)
        shebang = {p: m for m, s, p in regular if blobs.get(s, b"")[:2] == b"#!"}
        conforming = sorted(p for p, m in shebang.items() if m == "100755")
        if not conforming:
            raise CannotAssert(
                f"the control arm observed ZERO executable interpreter-line files among "
                f"{len(regular)} tracked — the mode or first-bytes read is not reaching "
                f"the population, so a zero finding count would be unreadable"
            )
        exemptions = parse_exemptions(blobs[listing[1]]) if whole else {}
    except CannotAssert as exc:
        return EXIT_CANNOT_ASSERT, [f"SCAN-ERROR: the instrument cannot assert: {exc}"]
    except NotEvaluated as exc:
        return EXIT_NOT_EVALUATED, [f"SCAN-ERROR: {NOT_CLEAN}: {exc}"]

    tracked = {p for _m, _s, p in entries}
    findings: list[str] = []
    applied: list[str] = []
    for p in sorted(p for p, m in shebang.items() if m == "100644"):
        if p in exemptions:
            applied.append(p)
            continue
        findings.append(
            f"FAIL: {p} — NOT-EXECUTABLE: begins with an interpreter line and is tracked "
            f"100644. Fix: `git update-index --chmod=+x {p}`. If it is a sourced library, "
            f"an imported module or a fixture, add `{p}  # <class>: <reason>` to "
            f"{EXEMPTIONS_REL} instead, and stage it — the list is read from the index."
        )
    for p in sorted(exemptions):
        if p in applied:
            continue
        if p not in tracked:
            why = "names a path that is not a tracked file under the scanned trees"
        elif p not in shebang:
            why = "names a tracked file that does not begin with an interpreter line"
        else:
            # Both remedies, and the row's own reason: a row can exist because a copy
            # of the file must stay non-executable, and deleting it then removes the
            # guard and keeps the defect.
            findings.append(
                f"FAIL: {p} — STALE-EXEMPTION: the row names a file that is tracked "
                f"executable (100755). The row says: {exemptions[p][1]}. If that still "
                f"holds, restore the file's mode with `git update-index --chmod=-x {p}`; "
                f"if it no longer does, delete the row from {EXEMPTIONS_REL}."
            )
            continue
        findings.append(
            f"FAIL: {p} — STALE-EXEMPTION: the row {why}. Delete it from {EXEMPTIONS_REL}."
        )
    lines.extend(findings)
    for p in applied:
        lines.append(f"EXEMPT: {p} — {exemptions[p][0]}")
    note = "" if apply_exemptions else " (exemptions LIFTED)"
    lines.append(
        f"DENOM: roots={','.join(ROOTS)}; {len(entries)} tracked file(s); "
        f"{len(shebang)} interpreter-line file(s); CONTROL {len(conforming)} at 100755 "
        f"(non-zero, so the count below is readable); {len(applied)} exempt{note}; "
        f"{len(findings)} finding(s)"
    )
    return (EXIT_FINDINGS if findings else EXIT_CLEAN), lines


# --------------------------------------------------------------------------------
# --self-test — hermetic arms over throwaway git work trees
# --------------------------------------------------------------------------------
# Every fixture is a real git work tree whose entries — the exemption list included —
# are written straight into the index (`hash-object -w` + `update-index --cacheinfo`),
# so the arms exercise the SAME `ls-files -s` / `cat-file --batch` reads the live scan
# uses — not a parallel test-only path — and need no filesystem mode bit, which makes
# them identical on every platform. No commit is made, so no identity is required.
# The process-boundary arms run this file as a subprocess and read its exit code and
# its output, which is the interface both callers consume.

_SH = "#!/usr/bin/env bash\n"


class _Fixture:
    def __init__(self, base: str, name: str) -> None:
        self.root = os.path.join(base, name)
        os.makedirs(self.root)
        _git(self.root, "init", "-q")

    def _blob(self, content: bytes) -> str:
        return _git(self.root, "hash-object", "-w", "--stdin", stdin=content).decode().strip()

    def add(self, path: str, mode: str, content: str | bytes) -> None:
        data = content.encode() if isinstance(content, str) else content
        _git(self.root, "update-index", "--add", "--cacheinfo", f"{mode},{self._blob(data)},{path}")

    def exempt(self, *rows: str) -> None:
        """Stage the exemption list in the index, which is where the scan reads it."""
        self.add(EXEMPTIONS_REL, "100644", "# fixture exemption list\n" + "".join(r + "\n" for r in rows))

    def exempt_unstaged(self, *rows: str) -> None:
        """Write the exemption list to the working tree only, never to the index."""
        dest = os.path.join(self.root, EXEMPTIONS_REL)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "w", encoding="utf-8") as fh:
            fh.write("# fixture exemption list\n" + "".join(r + "\n" for r in rows))

    def baseline(self) -> None:
        """One conforming executable CLI under each root: a live control arm."""
        self.add("release/tools/ok-cli.sh", "100755", _SH + "echo ok\n")
        self.add("core/deploy/tools/ok-cli.py", "100755", "#!/usr/bin/env python3\nprint('ok')\n")


def _tree_digest(path: str) -> list[tuple[str, int, str]]:
    """Every file under `path` as (relative path, size, sha256) — a byte-level snapshot."""
    out = []
    for dirpath, _dirs, files in os.walk(path):
        for name in files:
            full = os.path.join(dirpath, name)
            with open(full, "rb") as fh:
                out.append((os.path.relpath(full, path), os.path.getsize(full),
                            hashlib.sha256(fh.read()).hexdigest()))
    return sorted(out)


def self_test() -> int:
    base = tempfile.mkdtemp(prefix="tool-exec-mode-selftest-")
    results: list[tuple[str, bool, str]] = []

    def check(name: str, rc: int, text: str, want_rc: int, want=(), absent: str = "") -> None:
        wants = (want,) if isinstance(want, str) else tuple(want)
        ok = rc == want_rc and all(w in text for w in wants) and (not absent or absent not in text)
        results.append((name, ok, f"rc={rc} (want {want_rc})\n" + text))

    def arm(name: str, fx_root: str, want_rc: int, want=(), absent: str = "") -> None:
        rc, out = scan_tree(fx_root)
        check(name, rc, "\n".join(out), want_rc, want, absent)

    def proc_arm(name: str, fx_root: str, extra: list[str], want_rc: int, want=(), absent: str = "") -> None:
        cmd = [sys.executable, os.path.abspath(__file__), "--root", fx_root, *extra]
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
        check(name, proc.returncode, proc.stdout.decode("utf-8", "replace"), want_rc, want, absent)

    try:
        # EM-A — SENSITIVITY: a non-executable CLI MUST be caught.
        a = _Fixture(base, "a")
        a.baseline()
        a.add("release/tools/new-cli.sh", "100644", _SH + "echo run me\n")
        arm("EM-A SENSITIVITY — a non-executable CLI is caught", a.root, 1,
            want="FAIL: release/tools/new-cli.sh — NOT-EXECUTABLE")

        # EM-B — SPECIFICITY: an exempted, correctly non-executable library is silent,
        # and the exemption is reported rather than applied silently.
        b = _Fixture(base, "b")
        b.baseline()
        b.add("release/tools/lib/shared.sh", "100644", _SH + "shared_fn() { :; }\n")
        b.exempt("release/tools/lib/shared.sh  # sourced-library: read with `source` by ok-cli.sh; no main")
        arm("EM-B SPECIFICITY — an exempted non-executable library is silent", b.root, 0,
            want="EXEMPT: release/tools/lib/shared.sh — sourced-library", absent="FAIL:")

        # EM-C — PAIRED CONTROL for EM-B: the SAME tree with the row removed fires. This
        # is what shows EM-B's silence is caused by the row and not by a scan that
        # never reached the file.
        c = _Fixture(base, "c")
        c.baseline()
        c.add("release/tools/lib/shared.sh", "100644", _SH + "shared_fn() { :; }\n")
        arm("EM-C PAIRED CONTROL — the same library without its row is caught", c.root, 1,
            want="FAIL: release/tools/lib/shared.sh — NOT-EXECUTABLE")

        # EM-D — SPECIFICITY: files that do not begin with an interpreter line are not
        # in the population, whatever their suffix.
        d = _Fixture(base, "d")
        d.baseline()
        d.add("release/tools/tests/fixtures/data.md", "100644", "# a heading, not an interpreter line\n")
        d.add("release/tools/tests/fixtures/unmarked.sh", "100644", "# FIXTURE (not executed)\necho x\n")
        arm("EM-D SPECIFICITY — a file with no interpreter line is not in the population", d.root, 0,
            want="2 interpreter-line file(s)", absent="FAIL:")

        # EM-E — STALE EXEMPTION: a row may not name an executable file, and the
        # finding offers both remedies with the row's own reason.
        e = _Fixture(base, "e")
        e.baseline()
        e.exempt("release/tools/ok-cli.sh  # sourced-library: wrongly listed")
        arm("EM-E STALE-EXEMPTION — a row naming an executable file is caught", e.root, 1,
            want=("FAIL: release/tools/ok-cli.sh — STALE-EXEMPTION: the row names a file that is tracked executable",
                  "The row says: wrongly listed", "--chmod=-x release/tools/ok-cli.sh"))

        # EM-F — STALE EXEMPTION: a row naming an untracked path.
        f = _Fixture(base, "f")
        f.baseline()
        f.exempt("release/tools/gone.sh  # sourced-library: removed long ago")
        arm("EM-F STALE-EXEMPTION — a row naming an untracked path is caught", f.root, 1,
            want="STALE-EXEMPTION: the row names a path that is not a tracked file")

        # EM-G — STALE EXEMPTION: a row naming a file with no interpreter line.
        g = _Fixture(base, "g")
        g.baseline()
        g.add("core/deploy/tools/notes.txt", "100644", "plain text\n")
        g.exempt("core/deploy/tools/notes.txt  # fixture: no longer a script")
        arm("EM-G STALE-EXEMPTION — a row naming a file with no interpreter line is caught", g.root, 1,
            want="STALE-EXEMPTION: the row names a tracked file that does not begin")

        # EM-H — FAIL-LOUD: no executable interpreter-line file anywhere -> exit 2.
        h = _Fixture(base, "h")
        h.add("release/tools/readme.md", "100644", "text\n")
        h.add("core/deploy/tools/readme.md", "100644", "text\n")
        arm("EM-H FAIL-LOUD — a dead control arm exits 2, never 0", h.root, 2,
            want="SCAN-ERROR: the instrument cannot assert: the control arm observed ZERO")

        # EM-I — FAIL-LOUD: one root enumerates nothing -> exit 2.
        i = _Fixture(base, "i")
        i.add("release/tools/ok-cli.sh", "100755", _SH + "echo ok\n")
        arm("EM-I FAIL-LOUD — a tree with zero tracked files exits 2", i.root, 2,
            want="core/deploy/tools/ enumerates zero tracked files")

        # EM-J1..J6 — FAIL-LOUD: a malformed list (no reason / unknown class / a pattern /
        # a directory / a duplicate row / bytes that are not UTF-8) exits 2.
        for label, tag, rows, needle in (
            ("EM-J1", "no reason", ("release/tools/lib/shared.sh",),
             "is not `<path>  # <class>: <reason>`"),
            ("EM-J2", "an unknown class", ("release/tools/lib/shared.sh  # library: because",), "is not one of"),
            ("EM-J3", "a pattern", ("release/tools/lib/*.sh  # sourced-library: all of them",), "is a pattern"),
            ("EM-J4", "a directory", ("release/tools/lib/  # sourced-library: the whole folder",), "is a pattern"),
            ("EM-J5", "a duplicate row", ("release/tools/lib/shared.sh  # sourced-library: once",
                                          "release/tools/lib/shared.sh  # sourced-library: twice"), "is listed twice"),
        ):
            j = _Fixture(base, label.lower())
            j.baseline()
            j.add("release/tools/lib/shared.sh", "100644", _SH + "shared_fn() { :; }\n")
            j.exempt(*rows)
            arm(f"{label} FAIL-LOUD — an exemption list with {tag} exits 2", j.root, 2, want=needle)
        j6 = _Fixture(base, "em-j6")
        j6.baseline()
        j6.add("release/tools/lib/shared.sh", "100644", _SH + "shared_fn() { :; }\n")
        j6.add(EXEMPTIONS_REL, "100644", b"release/tools/lib/shared.sh  # sourced-library: \xff\xfe\n")
        arm("EM-J6 FAIL-LOUD — an exemption list that is not UTF-8 exits 2", j6.root, 2,
            want="is not UTF-8 text")

        # EM-K — RECURSION: a non-executable script several levels down is caught.
        k = _Fixture(base, "k")
        k.baseline()
        k.add("core/deploy/tools/fixtures/a/b/deep.sh", "100644", _SH + "echo deep\n")
        arm("EM-K RECURSION — a nested non-executable script is caught", k.root, 1,
            want="FAIL: core/deploy/tools/fixtures/a/b/deep.sh — NOT-EXECUTABLE")

        # EM-L — DECLARED BOUNDARY: outside the two trees is not reported.
        el = _Fixture(base, "l")
        el.baseline()
        el.add("core/deploy/outside.sh", "100644", _SH + "echo outside\n")
        arm("EM-L BOUNDARY — a file outside the two trees is not reported", el.root, 0,
            absent="outside.sh")

        # EM-M — NOT-EVALUATED: not a git work tree -> exit 3.
        plain = os.path.join(base, "m-plain")
        os.makedirs(plain)
        arm("EM-M NOT-EVALUATED — a directory that is not a work tree exits 3", plain, 3,
            want="SCAN-ERROR: NOT-EVALUATED — this is not a clean result")

        # EM-N1..N3 — PROCESS BOUNDARY: this file run as a subprocess, read by its exit
        # code and its output — the interface both callers consume. In-process arms
        # cannot see a fault between the predicate and the process.
        proc_arm("EM-N1 PROCESS — a finding leaves the process as exit 1 with its FAIL line", a.root, [], 1,
                 want="FAIL: release/tools/new-cli.sh — NOT-EXECUTABLE")
        proc_arm("EM-N2 PROCESS — an applied exemption leaves the process as exit 0", b.root, [], 0,
                 want="EXEMPT: release/tools/lib/shared.sh — sourced-library", absent="FAIL:")
        proc_arm("EM-N3 PROCESS — --no-exempt lifts the list and the library fires", b.root, ["--no-exempt"], 1,
                 want=("FAIL: release/tools/lib/shared.sh — NOT-EXECUTABLE", "(exemptions LIFTED)"))

        # EM-O — CRASH: an exception the predicate does not anticipate leaves main() as
        # exit 2 with a SCAN-ERROR line — never exit 1, which callers read as findings.
        real = globals()["scan_tree"]

        def _boom(*_a, **_k):
            raise RuntimeError("injected fault")

        captured = io.StringIO()
        globals()["scan_tree"] = _boom
        try:
            with contextlib.redirect_stdout(captured):
                rc_o = main(["--root", a.root])
        finally:
            globals()["scan_tree"] = real
        check("EM-O CRASH — an unanticipated exception exits 2, never 1", rc_o, captured.getvalue(), 2,
              want="SCAN-ERROR: the instrument cannot assert", absent="FAIL:")

        # EM-P — NOT-EVALUATED: an unmerged index entry -> exit 3.
        p_fx = _Fixture(base, "p")
        p_fx.baseline()
        sha = p_fx._blob((_SH + "echo conflicted\n").encode())
        _git(p_fx.root, "update-index", "--index-info",
             stdin="".join(f"100644 {sha} {s}\trelease/tools/conflicted.sh\n" for s in (1, 2, 3)).encode())
        arm("EM-P NOT-EVALUATED — an unmerged index entry exits 3", p_fx.root, 3,
            want="unmerged index entry (stage 1) at release/tools/conflicted.sh")

        # EM-Q — REGULAR FILES ONLY: a symlink whose target text begins with "#!" and a
        # gitlink (whose object is not in this repository) are not in the population.
        q = _Fixture(base, "q")
        q.baseline()
        q.add("release/tools/link", "120000", "#!not-a-script")
        _git(q.root, "update-index", "--add", "--cacheinfo",
             "160000,1234567890123456789012345678901234567890,core/deploy/tools/sub")
        arm("EM-Q SPECIFICITY — a symlink and a gitlink are not in the population", q.root, 0,
            want="2 interpreter-line file(s)", absent="FAIL:")

        # EM-S — THE LIST IS READ FROM THE INDEX: a row written to the working tree and
        # never staged changes nothing, so the local verdict is the one a commit carries.
        s = _Fixture(base, "s")
        s.baseline()
        s.add("release/tools/lib/shared.sh", "100644", _SH + "shared_fn() { :; }\n")
        s.exempt_unstaged("release/tools/lib/shared.sh  # sourced-library: written, never staged")
        arm("EM-S INDEX — an exemption row that is not staged is not applied", s.root, 1,
            want="FAIL: release/tools/lib/shared.sh — NOT-EXECUTABLE")

        # EM-R — ISOLATION: run under an inherited GIT_DIR, GIT_WORK_TREE,
        # GIT_INDEX_FILE, GIT_OBJECT_DIRECTORY and GIT_COMMON_DIR that point at a second
        # throwaway repository. The fixture is built and scanned correctly, and that
        # repository is byte-identical afterwards. The strip also covers every name git
        # publishes. Runs last: it sets process environment, restored in `finally`.
        clean = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        published = subprocess.run(["git", "rev-parse", "--local-env-vars"], env=clean,
                                   stdout=subprocess.PIPE, timeout=60).stdout.decode().split()
        caller = os.path.join(base, "r-caller")
        os.makedirs(caller)
        subprocess.run(["git", "-C", caller, "init", "-q"], env=clean, check=True, timeout=60)
        subprocess.run(["git", "-C", caller, "hash-object", "-w", "--stdin"], env=clean, check=True,
                       input=b"caller object\n", stdout=subprocess.PIPE, timeout=60)
        before = _tree_digest(os.path.join(caller, ".git"))
        hostile = {
            "GIT_DIR": os.path.join(caller, ".git"),
            "GIT_WORK_TREE": caller,
            "GIT_INDEX_FILE": os.path.join(caller, ".git", "index"),
            "GIT_OBJECT_DIRECTORY": os.path.join(caller, ".git", "objects"),
            "GIT_COMMON_DIR": os.path.join(caller, ".git"),
        }
        saved = {k: os.environ.get(k) for k in hostile}
        try:
            os.environ.update(hostile)
            r = _Fixture(base, "r")
            r.baseline()
            r.add("release/tools/new-cli.sh", "100644", _SH + "echo run me\n")
            rc_r, out_r = scan_tree(r.root)
        finally:
            for key, value in saved.items():
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value
        after = _tree_digest(os.path.join(caller, ".git"))
        uncovered = sorted(set(published) - set(local_env_vars()))
        text_r = "\n".join(out_r) + (f"\ncaller repository changed: {len(before)} -> {len(after)} files"
                                     if before != after else "") + \
            (f"\nnames git publishes that the strip does not cover: {uncovered}" if uncovered else "") + \
            ("\ngit published no names" if not published else "")
        check("EM-R ISOLATION — an inherited git environment neither redirects nor writes the caller",
              rc_r if (before == after and not uncovered and published) else -1, text_r, 1,
              want="FAIL: release/tools/new-cli.sh — NOT-EXECUTABLE")
    except (CannotAssert, NotEvaluated) as exc:
        print(f"SCAN-ERROR: the instrument cannot assert: fixture construction failed: {exc}")
        return EXIT_CANNOT_ASSERT
    finally:
        shutil.rmtree(base, ignore_errors=True)

    passed = 0
    for name, ok, detail in results:
        if ok:
            passed += 1
            print(f"  PASS  {name}")
        else:
            print(f"  FAIL  {name}")
            for ln in detail.splitlines():
                print("        " + ln)
    print(
        f"SELF-TEST: {passed}/{len(results)} arms pass — sensitivity (EM-A, EM-C, EM-K, EM-S) "
        f"observed findings; specificity (EM-B, EM-D, EM-L, EM-Q) observed none; stale-exemption "
        f"(EM-E, EM-F, EM-G) fired; cannot-assert (EM-H, EM-I, EM-J1..J6, EM-O) returned exit 2 "
        f"and not-evaluated (EM-M, EM-P) exit 3, never a clean zero; the process boundary "
        f"(EM-N1..N3) and git-environment isolation (EM-R) held"
    )
    return EXIT_CLEAN if passed == len(results) else EXIT_CANNOT_ASSERT


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Tool exec-mode conformance check")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--self-test", action="store_true", help="run the hermetic arms")
    g.add_argument("--no-exempt", action="store_true", help="scan with the exemption list lifted")
    ap.add_argument("--root", default=".", help="work tree to scan (default: current directory)")
    args = ap.parse_args(argv)
    try:
        if args.self_test:
            return self_test()
        rc, lines = scan_tree(args.root, apply_exemptions=not args.no_exempt)
        for ln in lines:
            print(ln)
        return rc
    except Exception as exc:  # noqa: BLE001 — any fault is exit 2, never a findings verdict
        print(f"SCAN-ERROR: the instrument cannot assert: {type(exc).__name__}: {exc}")
        return EXIT_CANNOT_ASSERT


if __name__ == "__main__":
    sys.exit(main())

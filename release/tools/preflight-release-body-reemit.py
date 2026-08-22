#!/usr/bin/env python3
"""
Pre-execute gate for the published-Release-body re-emit.

WHAT THIS GUARDS. `reemit-release-bodies.sh --execute` overwrites published
GitHub Release bodies. GitHub keeps no version history for a Release body, so the
mutation is irreversible except through the pre-overwrite capture written by
capture-release-bodies.sh. That capture is only a reversibility control if it is
DURABLE — committed and merged, not sitting in a working tree — and the emitter
tests only that the file exists on disk. This gate closes that gap, and four
others, and it FAILS CLOSED: any arm it cannot evaluate is a BLOCK, never a pass.

Run it immediately before `--execute`, from the repo root, and paste its output
into the execution record. It mutates nothing: every probe is a git read, a
filesystem read, or a hermetic fixture run.

THE FIVE ARMS
-------------
A1  MIGRATION-LANDED (sensitivity)
    The notes corpus at origin/main must hold NO subdirectory other than the one
    permitted subfolder, `_unversioned`. The release-notes standard names
    `_unversioned` as the single permitted notes subfolder; a major-version
    bucket still present at origin/main means the flat-layout migration has not
    merged yet. Emitting before it merges publishes note text that the very next
    merge supersedes -- into a surface that cannot be reverted.

    This arm asserts the STANDARD'S RULE, not a list of bucket names. No bucket
    literal appears anywhere in this file, so the arm needs no edit as the corpus
    folds or unfolds further.

A2  LAYOUT-VISIBLE (specificity)
    `_unversioned` must be present and non-empty at origin/main. Without this
    arm, a probe that silently returned nothing -- a wrong path, an unreadable
    ref, a typo -- would produce an all-empty result that reads exactly like
    "migration complete". A1 alone cannot tell those two apart; A2 can.

A3  CAPTURE-DURABLE
    Every version in the run must have a non-empty capture reachable at
    origin/main, proved with `git cat-file`. On-disk existence is NOT durability.

A4  EMIT-SAFE
    The bytes that WOULD be published are computed here and asserted to be
    (a) non-empty and (b) free of surviving YAML frontmatter.

    Why (b) exists. The shipped frontmatter strip is `sed '1,/^---$/d; …'`, whose
    range runs from line 1 to the FIRST `^---$` at line 2 or later. When a note's
    frontmatter starts on line 1 that is the closing delimiter and the strip is
    correct. When ANY line precedes the opening delimiter -- a lint directive, a
    comment, a blank -- the range ends on the OPENING delimiter instead, and the
    whole YAML block survives into the "body". Publishing that would write raw
    frontmatter onto a public Release page: precisely the defect the re-emit
    exists to repair, reintroduced by the repair. The emitter guards the empty
    strip and not this one, so the assertion lives here.

A5  EXTRACTION-CAPABILITY (the E-1 gate)
    The drift checker is the emitter's resume ledger AND its post-edit verifier.
    If it cannot discriminate on this host, `--execute` runs blind. Two hermetic
    fixture arms through the checker's own notes-dir override seam:
      ARM-S  a verbatim note        -> the checker MUST report MATCH  (exit 0)
      ARM-T  the same note + marker -> the checker MUST report DRIFT  (exit 1)
    ARM-T asserts its own byte delta before trusting the result: a seed that
    fails to modify the fixture makes an inert probe read as a passing tool.

USAGE
    python3 release/tools/preflight-release-body-reemit.py \\
        --capture-dir release/releases/_captures/<dated-dir> v1.06 v1.08 ...
    python3 release/tools/preflight-release-body-reemit.py --self-test

EXIT CODES
    0  every arm passed -- `--execute` may proceed
    1  at least one arm BLOCKED
    2  the gate itself could not run (no git, ref unresolvable, bad arguments)
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

NOTES_REL = "release/releases/notes"
PERMITTED_SUBFOLDER = "_unversioned"
REF = "origin/main"
DRIFT_TOOL_REL = "release/tools/check-release-body-drift.sh"

PASS, BLOCK, HALT = 0, 1, 2


def _run(args, cwd=None, env=None):
    p = subprocess.run(args, cwd=cwd, env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return p.returncode, p.stdout.decode("utf-8", "replace"), p.stderr.decode("utf-8", "replace")


def strip_frontmatter(text):
    """Byte-faithful model of the shipped `sed '1,/^---$/d; 1,/^---$/d'` strip.

    The second command can never re-activate: its addr1 is the literal line 1,
    which has already passed by the time any line reaches it. The pair therefore
    collapses to a single deletion range -- line 1 through the first `^---$` at
    line 2 or later. Modelled exactly, so A4 predicts what the emitter would
    actually publish rather than what a corrected strip would.
    """
    lines = text.split("\n")
    for i in range(1, len(lines)):
        if lines[i] == "---":
            return "\n".join(lines[i + 1:])
    return ""


def looks_like_frontmatter(body):
    """True when a stripped body still opens with a YAML frontmatter block.

    Two independent signatures, because either alone is defeatable: a leading
    `key:` scalar line, and a bare `---` terminator within the opening run. A
    body that opens with prose or a heading matches neither.
    """
    lines = [ln for ln in body.split("\n")]
    head = []
    for ln in lines[:60]:
        if ln == "---":
            head.append(ln)
            break
        head.append(ln)
    if not head:
        return False
    first = head[0].strip()
    if not first:
        return False
    if first.startswith("#") or first.startswith(">") or first.startswith("<"):
        return False
    key_like = (":" in first
                and not first.startswith("-")
                and " " not in first.split(":", 1)[0])
    return bool(key_like and head[-1] == "---")


def resolve_note(root, ref, version):
    """Flat path first, else the lexicographically-first recursive hit.

    Keyed on the corpus's own `_RELEASE_NOTES.md` type discriminator, with no
    bucket literal, so it holds under any layout.
    """
    base = "%s_RELEASE_NOTES.md" % version
    flat = "%s/%s" % (NOTES_REL, base)
    rc, _o, _e = _run(["git", "-C", root, "cat-file", "-e", "%s:%s" % (ref, flat)])
    if rc == 0:
        return flat
    rc, out, _e = _run(["git", "-C", root, "ls-tree", "-r", "--name-only", ref, "--", NOTES_REL])
    if rc != 0:
        return None
    hits = sorted(p for p in out.split("\n") if p.endswith("/" + base))
    return hits[0] if hits else None


class Report(object):
    def __init__(self):
        self.rows = []
        self.worst = PASS

    def add(self, arm, verdict, detail):
        self.rows.append((arm, verdict, detail))
        if verdict != "PASS":
            self.worst = max(self.worst, BLOCK)

    def halt(self, arm, detail):
        self.rows.append((arm, "HALT", detail))
        self.worst = HALT

    def render(self):
        out = []
        for arm, verdict, detail in self.rows:
            out.append("  %-6s %-5s  %s" % (arm, verdict, detail))
        if self.worst == PASS:
            out.append("")
            out.append("PREFLIGHT PASS - every arm green. `--execute` may proceed.")
        elif self.worst == BLOCK:
            out.append("")
            out.append("PREFLIGHT BLOCKED - do NOT run `--execute`. "
                       "Resolve every non-PASS arm above and re-run this gate.")
        else:
            out.append("")
            out.append("PREFLIGHT HALT - the gate could not evaluate itself. "
                       "Fail closed: do NOT run `--execute`.")
        return "\n".join(out)


def arm_a1_a2(root, rep):
    rc, out, err = _run(["git", "-C", root, "ls-tree", "-d", "--name-only", REF, "--",
                         NOTES_REL + "/"])
    if rc != 0:
        rep.halt("A1", "cannot list %s at %s (%s)" % (NOTES_REL, REF, err.strip()[:120]))
        rep.halt("A2", "not evaluated - A1 could not read the ref")
        return
    subdirs = sorted(os.path.basename(p) for p in out.split("\n") if p.strip())
    disallowed = [d for d in subdirs if d != PERMITTED_SUBFOLDER]
    if disallowed:
        rep.add("A1", "BLOCK",
                "the flat-layout migration has NOT landed on %s - %d disallowed notes "
                "subfolder(s) still present: %s (permitted: %s)"
                % (REF, len(disallowed), ", ".join(disallowed), PERMITTED_SUBFOLDER))
    else:
        rep.add("A1", "PASS",
                "no disallowed notes subfolder at %s (subfolders seen: %s)"
                % (REF, ", ".join(subdirs) if subdirs else "none"))

    if PERMITTED_SUBFOLDER not in subdirs:
        rep.add("A2", "BLOCK",
                "specificity arm did not fire - `%s` is absent at %s, so an empty A1 "
                "result cannot be distinguished from a probe that reads nothing"
                % (PERMITTED_SUBFOLDER, REF))
        return
    rc, out, _e = _run(["git", "-C", root, "ls-tree", "-r", "--name-only", REF, "--",
                        "%s/%s" % (NOTES_REL, PERMITTED_SUBFOLDER)])
    n = len([p for p in out.split("\n") if p.strip()]) if rc == 0 else 0
    if n > 0:
        rep.add("A2", "PASS",
                "specificity arm FIRED - `%s` present and non-empty at %s (%d file(s)), "
                "so the A1 probe demonstrably sees directories that exist"
                % (PERMITTED_SUBFOLDER, REF, n))
    else:
        rep.add("A2", "BLOCK",
                "specificity arm did not fire - `%s` resolves to 0 files at %s"
                % (PERMITTED_SUBFOLDER, REF))


def arm_a3(root, capture_dir, versions, rep):
    missing, empty = [], []
    for v in versions:
        path = "%s/%s.published.txt" % (capture_dir.rstrip("/"), v)
        rc, _o, _e = _run(["git", "-C", root, "cat-file", "-e", "%s:%s" % (REF, path)])
        if rc != 0:
            missing.append(v)
            continue
        rc, out, _e = _run(["git", "-C", root, "show", "%s:%s" % (REF, path)])
        if rc != 0 or not out.strip():
            empty.append(v)
    if missing or empty:
        rep.add("A3", "BLOCK",
                "capture is NOT durable at %s - %d absent%s, %d empty%s (of %d). "
                "A capture that lives only in a working tree is not a rollback source."
                % (REF, len(missing), (" [" + ", ".join(missing[:8]) + "]") if missing else "",
                   len(empty), (" [" + ", ".join(empty[:8]) + "]") if empty else "",
                   len(versions)))
    else:
        rep.add("A3", "PASS",
                "all %d capture(s) present and non-empty at %s" % (len(versions), REF))


def arm_a4(root, versions, rep):
    unresolved, empty, polluted = [], [], []
    ok = 0
    for v in versions:
        note = resolve_note(root, REF, v)
        if note is None:
            unresolved.append(v)
            continue
        rc, raw, _e = _run(["git", "-C", root, "show", "%s:%s" % (REF, note)])
        if rc != 0:
            unresolved.append(v)
            continue
        body = strip_frontmatter(raw)
        if not body.strip():
            empty.append(v)
        elif looks_like_frontmatter(body):
            polluted.append(v)
        else:
            ok += 1
    if unresolved or empty or polluted:
        parts = []
        if unresolved:
            parts.append("%d note(s) unresolved at %s [%s]"
                         % (len(unresolved), REF, ", ".join(unresolved[:8])))
        if empty:
            parts.append("%d strip(s) produced an EMPTY body [%s]"
                         % (len(empty), ", ".join(empty[:8])))
        if polluted:
            parts.append("%d body/bodies would PUBLISH RAW YAML FRONTMATTER [%s] - the note "
                         "carries a line before its opening `---`, so the strip range ends on "
                         "the opening delimiter instead of the closing one"
                         % (len(polluted), ", ".join(polluted[:8])))
        rep.add("A4", "BLOCK", "; ".join(parts) + " (%d of %d safe)" % (ok, len(versions)))
    else:
        rep.add("A4", "PASS",
                "all %d computed bodies are non-empty and carry no surviving frontmatter"
                % len(versions))


def arm_a5(root, rep):
    tool = os.path.join(root, DRIFT_TOOL_REL)
    if not os.path.exists(tool):
        rep.halt("A5", "the drift checker is absent at %s - the gate cannot assert "
                       "extraction capability without it" % DRIFT_TOOL_REL)
        return
    rc, out, _e = _run(["git", "-C", root, "ls-tree", "-r", "--name-only", REF, "--", NOTES_REL])
    notes = sorted(p for p in out.split("\n") if p.endswith("_RELEASE_NOTES.md"))
    if not notes:
        rep.halt("A5", "no notes found at %s - no fixture subject available" % REF)
        return

    subject_note, subject_version, raw = None, None, None
    env = dict(os.environ)
    tmp = tempfile.mkdtemp(prefix="preflight-e1-")
    try:
        for cand in reversed(notes):
            base = os.path.basename(cand)
            version = base[:-len("_RELEASE_NOTES.md")]
            rc, text, _e = _run(["git", "-C", root, "show", "%s:%s" % (REF, cand)])
            if rc != 0:
                continue
            fx = os.path.join(tmp, "s-" + version)
            os.makedirs(fx)
            with open(os.path.join(fx, base), "w") as fh:
                fh.write(text)
            e = dict(env)
            e["NOTES_DIR_OVERRIDE"] = fx
            rc_s, _o, _err = _run(["bash", tool, version, "--quiet"], cwd=root, env=e)
            if rc_s == 0:
                subject_note, subject_version, raw = cand, version, text
                break
        if subject_version is None:
            rep.halt("A5", "ARM-S found no version whose verbatim note reports MATCH - "
                           "the checker cannot be shown to discriminate on this host")
            return

        base = os.path.basename(subject_note)
        fx_t = os.path.join(tmp, "t-" + subject_version)
        os.makedirs(fx_t)
        seeded = raw + "\nPREFLIGHT-E1-SENSITIVITY-MARKER-NOT-FOR-PUBLICATION\n"
        if seeded == raw or len(seeded) <= len(raw):
            rep.halt("A5", "ARM-T fixture did not grow - BROKEN PROBE, refusing to "
                           "report its result as evidence")
            return
        with open(os.path.join(fx_t, base), "w") as fh:
            fh.write(seeded)
        e = dict(env)
        e["NOTES_DIR_OVERRIDE"] = fx_t
        rc_t, _o, _err = _run(["bash", tool, subject_version, "--quiet"], cwd=root, env=e)
        if rc_t == 1:
            rep.add("A5", "PASS",
                    "E-1 gate discriminates on this host - subject %s: ARM-S exit 0 (MATCH), "
                    "ARM-T exit 1 (DRIFT) with an asserted +%d byte delta"
                    % (subject_version, len(seeded) - len(raw)))
        else:
            rep.add("A5", "BLOCK",
                    "E-1 sensitivity arm FAILED - subject %s: ARM-S exit 0 but ARM-T exit %d "
                    "(expected 1). The checker cannot see a seeded divergence on this host, so "
                    "the emitter's post-edit verification would run blind."
                    % (subject_version, rc_t))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def preflight(root, capture_dir, versions):
    rep = Report()
    rc, _o, _e = _run(["git", "-C", root, "rev-parse", "--verify", REF])
    if rc != 0:
        rep.halt("A0", "%s is unresolvable - run `git fetch origin main` first. "
                       "Freshness of %s is the caller's contract." % (REF, REF))
        print(rep.render())
        return HALT
    arm_a1_a2(root, rep)
    arm_a3(root, capture_dir, versions, rep)
    arm_a4(root, versions, rep)
    # A5 is evaluated ONLY on a run that could otherwise proceed. Its fixture pair
    # costs a network round-trip per attempt, and a capability verdict taken on a
    # run that is already blocked is spent evidence: the run will be repeated after
    # the blocking arm is resolved, and A5 must be re-taken then anyway.
    if rep.worst == PASS:
        arm_a5(root, rep)
    else:
        rep.rows.append(("A5", "SKIP",
                         "not evaluated - an earlier arm already BLOCKED, so this run "
                         "cannot proceed to `--execute`. Re-run the whole gate once the "
                         "blocking arm is resolved; A5 is only evidence when taken on "
                         "the run that would actually execute."))
    print("preflight-release-body-reemit - %d version(s), capture dir %s, ref %s"
          % (len(versions), capture_dir, REF))
    print(rep.render())
    return rep.worst


# --------------------------------------------------------------------------
# Self-test. Hermetic: a sandbox repo with a real bare origin, a stub checker,
# and no network. Every assertion carries BOTH arms -- a gate that only ever
# blocks is indistinguishable from a gate that never works.
# --------------------------------------------------------------------------
NOTE_TEMPLATE = """---
version: %s
type: note
---

# %s selftest note

Body text.
"""

LEADIN_NOTE_TEMPLATE = """<!-- reference-durability: allow-link -->
---
version: %s
type: note
---

# %s selftest note

Body text.
"""


def _git(root, *args):
    return _run(["git", "-C", root] + list(args))


def _seed(work, layout, versions, leadin=()):
    ndir = os.path.join(work, NOTES_REL)
    for v in versions:
        d = ndir if layout == "flat" else os.path.join(ndir, "v" + v[1])
        if not os.path.isdir(d):
            os.makedirs(d)
        tpl = LEADIN_NOTE_TEMPLATE if v in leadin else NOTE_TEMPLATE
        with open(os.path.join(d, "%s_RELEASE_NOTES.md" % v), "w") as fh:
            fh.write(tpl % (v, v))
    u = os.path.join(ndir, PERMITTED_SUBFOLDER)
    if not os.path.isdir(u):
        os.makedirs(u)
    with open(os.path.join(u, "keep_RELEASE_NOTES.md"), "w") as fh:
        fh.write(NOTE_TEMPLATE % ("keep", "keep"))


def _commit_push(work):
    _git(work, "-c", "user.email=t@t", "-c", "user.name=t", "add", "-A")
    _git(work, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "seed")
    _git(work, "push", "-q", "origin", "main")
    _git(work, "fetch", "-q", "origin")


def _sandbox(tmp, layout, versions, captures, leadin=(), tag=None):
    name = layout if tag is None else "%s-%s" % (layout, tag)
    work = os.path.join(tmp, "work-%s" % name)
    origin = os.path.join(tmp, "origin-%s.git" % name)
    os.makedirs(work)
    _run(["git", "init", "--bare", "-q", origin])
    rc, _o, _e = _run(["git", "init", "-q", "-b", "main", work])
    if rc != 0:
        _run(["git", "init", "-q", work])
        _git(work, "checkout", "-q", "-b", "main")
    _seed(work, layout, versions, leadin)
    capdir = "release/releases/_captures/selftest"
    os.makedirs(os.path.join(work, capdir))
    for v in captures:
        with open(os.path.join(work, capdir, "%s.published.txt" % v), "w") as fh:
            fh.write("prior published body for %s\n" % v)
    _git(work, "remote", "add", "origin", origin)
    _commit_push(work)
    return work, capdir


def _arm(rep_rows, arm):
    for a, verdict, detail in rep_rows:
        if a == arm:
            return verdict, detail
    return None, None


def _evaluate(root, capdir, versions):
    rep = Report()
    arm_a1_a2(root, rep)
    arm_a3(root, capdir, versions, rep)
    arm_a4(root, versions, rep)
    return rep


def self_test():
    tmp = tempfile.mkdtemp(prefix="preflight-selftest-")
    failures = []

    def check(label, cond, detail=""):
        if cond:
            print("  PASS  %s" % label)
        else:
            print("  FAIL  %s %s" % (label, detail))
            failures.append(label)

    try:
        vs = ["v1.01", "v2.02"]

        # Case 1 -- PRE-migration layout: A1 must BLOCK, A2 must still FIRE.
        work, capdir = _sandbox(tmp, "foldered", vs, vs)
        rep = _evaluate(work, capdir, vs)
        v1, d1 = _arm(rep.rows, "A1")
        v2, d2 = _arm(rep.rows, "A2")
        check("A1 blocks while a disallowed notes subfolder remains", v1 == "BLOCK", d1 or "")
        check("A2 specificity arm fires in the same run", v2 == "PASS", d2 or "")

        # Case 2 -- POST-migration layout: A1 must PASS. Without this arm a gate
        # that blocked unconditionally would look identical to a working one.
        work2, capdir2 = _sandbox(tmp, "flat", vs, vs)
        rep2 = _evaluate(work2, capdir2, vs)
        v1b, d1b = _arm(rep2.rows, "A1")
        check("A1 passes once the layout is flat", v1b == "PASS", d1b or "")

        # Case 3 -- A3 both arms: a captured set passes, an uncaptured one blocks.
        v3a, _d = _arm(rep2.rows, "A3")
        check("A3 passes when every capture is on the ref", v3a == "PASS")
        work3, capdir3 = _sandbox(tmp, "flat", vs, [vs[0]], tag="partial-capture")
        rep3 = _evaluate(work3, capdir3, vs)
        v3b, d3b = _arm(rep3.rows, "A3")
        check("A3 blocks when a capture is missing from the ref", v3b == "BLOCK", d3b or "")

        # Case 4 -- A4 both arms. The lead-in note is the whole point: its strip
        # leaves the YAML in the body, and publishing that is the defect the
        # re-emit exists to repair.
        v4a, _d = _arm(rep2.rows, "A4")
        check("A4 passes for well-formed notes", v4a == "PASS")
        work4, capdir4 = _sandbox(tmp, "flat", vs, vs, leadin=[vs[0]], tag="leadin")
        rep4 = _evaluate(work4, capdir4, vs)
        v4b, d4b = _arm(rep4.rows, "A4")
        check("A4 blocks a note whose strip leaves frontmatter", v4b == "BLOCK", d4b or "")
        check("A4 names the offending version", vs[0] in (d4b or ""), d4b or "")

        # Case 5 -- the strip model itself, both directions.
        good = strip_frontmatter(NOTE_TEMPLATE % ("v9.99", "v9.99"))
        bad = strip_frontmatter(LEADIN_NOTE_TEMPLATE % ("v9.99", "v9.99"))
        check("strip model: well-formed note yields prose",
              good.strip().startswith("# v9.99"), repr(good[:40]))
        check("strip model: lead-in note leaks YAML",
              bad.strip().startswith("version:"), repr(bad[:40]))
        check("looks_like_frontmatter: sensitivity", looks_like_frontmatter(bad))
        check("looks_like_frontmatter: specificity", not looks_like_frontmatter(good))

        # Case 6 -- unresolvable ref halts rather than passing.
        bare = os.path.join(tmp, "norepo")
        os.makedirs(bare)
        _run(["git", "init", "-q", bare])
        rc = preflight(bare, "nowhere", ["v0.00"])
        check("unresolvable %s halts (exit 2), never passes" % REF, rc == HALT, "rc=%s" % rc)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    if failures:
        print("preflight-release-body-reemit self-test: %d FAILURE(S)" % len(failures))
        return 1
    print("preflight-release-body-reemit self-test: ALL PASS")
    return 0


def main():
    ap = argparse.ArgumentParser(
        description="Pre-execute gate for the published-Release-body re-emit.")
    ap.add_argument("--self-test", action="store_true",
                    help="hermetic fixtures; no network, no repo state read")
    ap.add_argument("--capture-dir",
                    help="repo-root-relative capture directory for this run")
    ap.add_argument("versions", nargs="*", help="the versions the run will emit")
    args = ap.parse_args()

    if args.self_test:
        sys.exit(self_test())

    if not args.capture_dir or not args.versions:
        ap.error("--capture-dir and at least one version are required "
                 "(or pass --self-test)")

    rc, out, _e = _run(["git", "rev-parse", "--show-toplevel"])
    if rc != 0:
        print("HALT: not inside a git working tree - the gate cannot read %s" % REF)
        sys.exit(HALT)
    sys.exit(preflight(out.strip(), args.capture_dir, args.versions))


if __name__ == "__main__":
    main()

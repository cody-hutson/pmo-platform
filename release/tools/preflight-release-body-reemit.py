#!/usr/bin/env python3
"""
Pre-execute gate for the published-Release-body re-emit.

WHAT THIS GUARDS. `reemit-release-bodies.sh --execute` overwrites published
GitHub Release bodies. GitHub keeps no version history for a Release body, so the
mutation is irreversible except through the pre-overwrite capture written by
capture-release-bodies.sh. That capture is only a reversibility control if it is
DURABLE — committed and merged, not sitting in a working tree — and CURRENT —
actually reproducing the body it would be restoring over. The emitter tests only
that the file exists on disk. This gate closes that gap, and four others, and it
FAILS CLOSED: any arm it cannot evaluate is a BLOCK, never a pass.

Run it immediately before `--execute`, from the repo root, and paste its output
into the execution record. It mutates nothing: every probe is a git read, a
filesystem read, a READ-ONLY `gh release view`, or a hermetic fixture run. It
never calls `gh release edit`, `gh release create` or `gh release delete`.

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

A3  CAPTURE-CORRESPONDS  (durability AND currency)
    Every version in the run must have a capture that is
      (a) DURABLE -- non-empty and reachable at origin/main, proved with
          `git cat-file`; on-disk existence is NOT durability -- and
      (b) CURRENT -- byte-identical to the body GitHub publishes RIGHT NOW.

    Why (b) exists. Durability alone proves a capture is a committed artifact.
    It does not prove the artifact is a ROLLBACK SOURCE, which is the only
    property that makes the re-emit reversible. A capture taken before some
    EARLIER edit is durable and non-empty and completely wrong: restoring from
    it would publish the body as it stood at that earlier moment, silently
    discarding everything published since. This is not hypothetical -- the
    repository already carries 29 such captures from a prior repair, 18 of them
    for versions in this card's cohort, and every one of the 29 is stale against
    today's published bodies. A gate that printed `A3 PASS -- all 18 capture(s)
    present and non-empty` over them manufactured confidence in a rollback that
    would not roll back. Presence is not correspondence.

    HOW THE COMPARISON IS MADE. SHA-256, which is the capture format's own
    integrity currency: capture-release-bodies.sh records a digest per capture in
    a canonical `SHA256SUMS` and again in `MANIFEST.md`, so the digests this arm
    prints cross-reference the capture's own artifacts directly and an operator
    can reproduce the arm by hand with `shasum -a 256 -c`. The live side is read
    with EXACTLY the command that wrote the capture --
    `gh release view <v> --json body --jq .body` -- so both byte streams come
    from one tool under one normalisation and any difference between them is a
    real body difference, never a formatting artefact. (Verified: for all 29
    captures in the repository, the digest of the blob at origin/main equals the
    digest the capture tool recorded, so the ref read is byte-faithful.)

    FAILS CLOSED. A live body that cannot be read -- gh absent, unauthenticated,
    no published Release, a failed read -- is a BLOCK, never a pass: an arm that
    cannot establish correspondence has not established it. The currency limb is
    taken on EVERY run in which A3 runs, never deferred behind another arm's
    verdict, because "A3 PASS while a different arm blocks" is precisely the
    reading that made the original defect dangerous.

    The four outcomes are distinct in the rendered detail, because they are four
    different repairs: ABSENT (capture the version), EMPTY (re-capture it),
    STALE (capture a NEW dated directory -- the capture tool refuses to
    overwrite, and that refusal is correct), UNREADABLE (restore the capability).

A4  EMIT-SAFE
    The bytes that WOULD be published are computed here and asserted to be
    (a) non-empty and (b) free of surviving YAML frontmatter.

    Why (b) exists. Publishing a body that still carries its YAML block writes
    raw frontmatter onto a public Release page: precisely the defect the re-emit
    exists to repair, reintroduced by the repair. The emitter guards the empty
    strip and not this one, so the assertion lives here.

    The specific strip defect that motivated the arm is now FIXED at the source.
    The shipped transform was `sed '1,/^---$/d; …'`, whose range runs from line 1
    to the FIRST `^---$` at line 2 or later: correct when a note's frontmatter
    opens on line 1, wrong whenever ANY line precedes the opening delimiter,
    because the range then ends on the OPENING delimiter and the whole YAML block
    survives. Three corpus notes (v1.08 / v1.09 / v1.10) carry a lint directive
    there. The transform now runs `sed -n '/^---$/,$p'` first, so the shipped
    idiom always sees a stream whose line 1 IS the opening delimiter.

    A4 is NOT weakened by that fix and must not be. `strip_frontmatter` below
    models the REPAIRED transform byte-faithfully, so A4 still predicts the exact
    bytes the emitter would publish; the assertion simply now has nothing to
    catch in the current corpus. It remains armed against any future note shape
    the transform mis-handles -- a doubled frontmatter block still trips it, and
    the self-test drives that case so the limb cannot rot into dead code.

A5  EXTRACTION-CAPABILITY (the E-1 gate)
    The drift checker is the emitter's resume ledger AND its post-edit verifier.
    If it cannot discriminate on this host, `--execute` runs blind. Two hermetic
    fixture arms through the checker's own notes-dir override seam:
      ARM-S  a verbatim note        -> the checker MUST report MATCH  (exit 0)
      ARM-T  the same note + marker -> the checker MUST report DRIFT  (exit 1)
    ARM-T asserts its own byte delta before trusting the result: a seed that
    fails to modify the fixture makes an inert probe read as a passing tool.

THE AGGREGATE VERDICT IS DERIVED, NOT MAINTAINED
------------------------------------------------
`Report.worst` is a read-only property recomputed from `Report.rows` on every
read. It is deliberately NOT a field updated alongside them, because that shape
has exactly one catastrophic failure and this gate cannot afford it: delete the
single statement that escalates a maintained aggregate and the gate prints
`PREFLIGHT PASS - every arm green` and exits 0 while its arms visibly render
BLOCK. A per-arm test suite cannot see that -- every row is still correct; only
the summary lies. A derived aggregate has no escalation statement to delete, so
the summary cannot disagree with the rows it summarises.

The verdict-to-severity map is CLOSED and fails closed: a verdict string the map
does not know scores HALT, never PASS, so a future arm that invents a verdict
cannot silently widen the pass set. `preflight()` returns `rep.worst` rather than
a literal for the same reason -- the process exit code and the printed banner are
computed from one source.

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
import contextlib
import hashlib
import io
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

# Verdict string -> severity. CLOSED map, consulted by the derived aggregate.
# `SKIP` scores PASS because it is not a verdict on the arm's subject: it records
# that the arm was deliberately not taken on a run that already cannot proceed.
# An UNKNOWN verdict scores HALT (see `Report.worst`) -- the aggregate refuses to
# classify what it does not recognise rather than defaulting it into the pass set.
VERDICT_SEVERITY = {"PASS": PASS, "SKIP": PASS, "BLOCK": BLOCK, "HALT": HALT}


def _run(args, cwd=None, env=None):
    p = subprocess.run(args, cwd=cwd, env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return p.returncode, p.stdout.decode("utf-8", "replace"), p.stderr.decode("utf-8", "replace")


def _run_raw(args, cwd=None, env=None):
    """As `_run`, but stdout is returned as RAW BYTES.

    A3's correspondence check digests two byte streams. `_run` decodes with
    errors="replace", which is lossy: two different bodies can decode to the same
    replacement-char text, and a round trip back through encode() is not the
    original bytes. Digesting the decoded form would therefore be capable of
    reporting a stale capture as current -- the exact failure the arm exists to
    prevent. Bytes in, bytes digested.
    """
    p = subprocess.run(args, cwd=cwd, env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return p.returncode, p.stdout, p.stderr.decode("utf-8", "replace")


def _find_gh():
    """Resolve gh off the pinned PATH, mirroring check-release-body-drift.sh.

    Returns "" when gh is not installed. The caller turns that into a BLOCK --
    never a pass -- because an arm that cannot read the live body cannot assert
    correspondence with it.
    """
    for c in ("/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/usr/bin/gh",
              os.path.join(os.path.expanduser("~"), ".local/bin/gh")):
        if os.path.isfile(c) and os.access(c, os.X_OK):
            return c
    return shutil.which("gh") or ""


def live_body_digest(version):
    """SHA-256 of the body GitHub publishes for `version` RIGHT NOW.

    Returns (hexdigest, None) on success, (None, reason) on any failure.

    Read with EXACTLY the command capture-release-bodies.sh uses to WRITE a
    capture -- `gh release view <v> --json body --jq .body` -- so the captured
    bytes and the live bytes are produced by one tool under one normalisation.
    Any digest difference is then a real body difference, not an artefact of
    reading the two sides differently.

    This is the PRODUCTION fetcher. `arm_a3` takes it as a default argument so
    the self-test can inject a hermetic one; no production caller passes that
    argument. Same fault-injection-seam pattern as `arm_a5`'s `seeder`.
    """
    gh = _find_gh()
    if not gh:
        return None, "gh is not installed on this host"
    rc, out, err = _run_raw([gh, "release", "view", version,
                             "--json", "body", "--jq", ".body"])
    if rc != 0:
        reason = err.strip().split("\n")[0][:80] if err.strip() else "exit %d" % rc
        return None, reason
    return hashlib.sha256(out).hexdigest(), None


def strip_frontmatter(text):
    """Byte-faithful model of the shipped two-stage strip.

    The shipped transform is
        sed -n '/^---$/,$p'  |  sed '1,/^---$/d; 1,/^---$/d'
    in BOTH executables (reemit-release-bodies.sh, check-release-body-drift.sh).
    A4 exists to predict the bytes the emitter would actually publish, so this
    models the shipped pair exactly -- never an idealised strip.

    Stage 1 drops any LEAD-IN before the opening delimiter. Stage 2 is the
    original idiom: its second command can never re-activate (addr1 is the
    literal line 1, already passed), so the pair collapses to one deletion range
    -- line 1 through the first `^---$` at line 2 or later.

    Composed, that is: find the opening delimiter, then delete through the first
    `^---$` strictly after it. When the opening delimiter is line 1, stage 1 is
    the identity and this is byte-identical to the pre-repair model -- which is
    why 192 of the 195 corpus notes are unaffected by the repair.

    No opening delimiter, or no closing delimiter after it, yields "" -- the
    fail-closed outcome the callers' empty-body ABORT is waiting for.
    """
    lines = text.split("\n")
    # Stage 1: drop everything before the first `---` (the opening delimiter).
    for start, ln in enumerate(lines):
        if ln == "---":
            break
    else:
        return ""
    lines = lines[start:]
    # Stage 2: delete line 1 through the first `---` at line 2 or later.
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
    """Arm rows plus a DERIVED aggregate verdict.

    See "THE AGGREGATE VERDICT IS DERIVED, NOT MAINTAINED" in the module
    docstring for why `worst` is a property and not a field. Every row enters
    through `add` / `halt` / `skip`; nothing appends to `rows` directly, so there
    is one place a verdict can be introduced and one place it is classified.
    """

    def __init__(self):
        self.rows = []

    @property
    def worst(self):
        """The severest severity across the rows. Recomputed on every read.

        Read-only ON PURPOSE: an assignment would reintroduce the maintained
        aggregate this property exists to eliminate, and Python raises
        AttributeError on the attempt rather than letting it land silently.
        """
        return max([VERDICT_SEVERITY.get(v, HALT) for _a, v, _d in self.rows]
                   or [PASS])

    def add(self, arm, verdict, detail):
        self.rows.append((arm, verdict, detail))

    def halt(self, arm, detail):
        self.rows.append((arm, "HALT", detail))

    def skip(self, arm, detail):
        """A non-escalating row for an arm that was deliberately not taken."""
        self.rows.append((arm, "SKIP", detail))

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


def arm_a3(root, capture_dir, versions, rep, fetcher=live_body_digest):
    """Assert every capture is DURABLE and CURRENT. See A3 in the module docstring.

    `fetcher` is a FAULT-INJECTION seam, not a configuration knob: it lets the
    hermetic self-test drive all four outcomes without a network. No production
    caller passes it.

    The currency probe is only spent on captures that cleared durability -- an
    absent or empty capture already blocks, and its live body would tell us
    nothing we could act on. That keeps the common real case (no capture
    directory yet) at zero network reads while leaving the pass path impossible
    to reach without a completed comparison.
    """
    missing, empty, stale, unreadable = [], [], [], []
    current = 0
    for v in versions:
        path = "%s/%s.published.txt" % (capture_dir.rstrip("/"), v)
        rc, _o, _e = _run(["git", "-C", root, "cat-file", "-e", "%s:%s" % (REF, path)])
        if rc != 0:
            missing.append(v)
            continue
        rc, blob, _e = _run_raw(["git", "-C", root, "show", "%s:%s" % (REF, path)])
        if rc != 0 or not blob.strip():
            empty.append(v)
            continue
        captured = hashlib.sha256(blob).hexdigest()
        live, reason = fetcher(v)
        if live is None:
            unreadable.append((v, reason or "unknown"))
        elif live != captured:
            stale.append((v, captured, live))
        else:
            current += 1

    if not (missing or empty or stale or unreadable):
        rep.add("A3", "PASS",
                "all %d capture(s) CORRESPOND - durable at %s and SHA-256-identical "
                "to the body published now, so each one is a rollback source rather "
                "than merely a file" % (len(versions), REF))
        return

    parts = []
    if missing:
        parts.append("%d ABSENT at %s [%s] - capture them"
                     % (len(missing), REF, ", ".join(missing[:8])))
    if empty:
        parts.append("%d EMPTY [%s] - present to `cat-file -e` and worthless as a "
                     "rollback source" % (len(empty), ", ".join(empty[:8])))
    if stale:
        parts.append("%d STALE [%s] - the capture is durable but does NOT reproduce "
                     "the body published now, so restoring from it would publish an "
                     "older body and discard everything published since. Take a NEW "
                     "dated capture directory; capture-release-bodies.sh refuses to "
                     "overwrite an existing capture and that refusal is correct"
                     % (len(stale),
                        ", ".join("%s capture=%s live=%s" % (v, c[:12], l[:12])
                                  for v, c, l in stale[:6])))
    if unreadable:
        parts.append("%d UNREADABLE [%s] - correspondence could not be established, "
                     "which is a BLOCK and never a pass"
                     % (len(unreadable),
                        ", ".join("%s (%s)" % (v, r) for v, r in unreadable[:6])))
    rep.add("A3", "BLOCK",
            "; ".join(parts) + " (%d of %d correspond). Digests are the same SHA-256 "
            "the capture's own SHA256SUMS records - reproduce with `shasum -a 256 -c`."
            % (current, len(versions)))


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


SENSITIVITY_MARKER = "PREFLIGHT-E1-SENSITIVITY-MARKER-NOT-FOR-PUBLICATION"


def seed_marker(raw):
    """ARM-T's fixture seed: append a marker the checker must be able to see."""
    return raw + "\n" + SENSITIVITY_MARKER + "\n"


def arm_a5(root, rep, seeder=seed_marker):
    """`seeder` is a FAULT-INJECTION seam, not a configuration knob.

    The inert-fixture guard below is defensive code on a branch the production
    seeder can never take -- appending a marker always grows the text. Untested
    defensive code is how a broken probe gets reported as a passing tool, so the
    self-test injects an inert seeder to drive that branch. No production caller
    passes this argument.
    """
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
        seeded = seeder(raw)
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


def preflight(root, capture_dir, versions, fetcher=live_body_digest):
    rep = Report()
    rc, _o, _e = _run(["git", "-C", root, "rev-parse", "--verify", REF])
    if rc != 0:
        rep.halt("A0", "%s is unresolvable - run `git fetch origin main` first. "
                       "Freshness of %s is the caller's contract." % (REF, REF))
        print(rep.render())
        return rep.worst
    arm_a1_a2(root, rep)
    arm_a3(root, capture_dir, versions, rep, fetcher=fetcher)
    arm_a4(root, versions, rep)
    # A5 is evaluated ONLY on a run that could otherwise proceed. Its fixture pair
    # costs a network round-trip per attempt, and a capability verdict taken on a
    # run that is already blocked is spent evidence: the run will be repeated after
    # the blocking arm is resolved, and A5 must be re-taken then anyway.
    if rep.worst == PASS:
        arm_a5(root, rep)
    else:
        rep.skip("A5",
                 "not evaluated - an earlier arm already BLOCKED, so this run "
                 "cannot proceed to `--execute`. Re-run the whole gate once the "
                 "blocking arm is resolved; A5 is only evidence when taken on "
                 "the run that would actually execute.")
    print("preflight-release-body-reemit - %d version(s), capture dir %s, ref %s"
          % (len(versions), capture_dir, REF))
    print(rep.render())
    return rep.worst


# --------------------------------------------------------------------------
# Self-test. Hermetic: a sandbox repo with a real bare origin, a stub checker,
# and no network. Every assertion carries BOTH arms -- a gate that only ever
# blocks is indistinguishable from a gate that never works.
#
# TWO LEVELS, AND BOTH ARE REQUIRED.
#   (1) ARM level -- `_evaluate()` builds a Report and reads individual rows.
#       This is what proves each arm's own logic.
#   (2) AGGREGATE level -- `_preflight_capture()` calls `preflight()` end to end
#       and captures its RETURN CODE and its RENDERED BANNER. This is the only
#       observable `--execute` is actually gated on, and a suite that asserts
#       only (1) cannot see a summary that disagrees with the rows it summarises.
#       Both directions are asserted: a blocking run must BLOCK and a passing run
#       must PASS, so the assertions discriminate rather than always expecting
#       the same answer.
# --------------------------------------------------------------------------
NOTE_TEMPLATE = """---
version: %s
type: note
---

# %s selftest note

Body text.
"""

# A line PRECEDES the opening delimiter. Under the pre-repair strip its whole YAML
# block survived into the body; under the repaired two-stage strip it does not.
# Three live corpus notes have this shape (v1.08 / v1.09 / v1.10).
LEADIN_NOTE_TEMPLATE = """<!-- reference-durability: allow-link -->
---
version: %s
type: note
---

# %s selftest note

Body text.
"""

# TWO frontmatter blocks. The strip removes the first and the second survives, so
# the computed body still LOOKS like frontmatter. This is what keeps A4's
# frontmatter limb armed after the lead-in defect is fixed at the source: without
# a fixture that still trips it, the limb would rot into untested dead code and
# "A4 passes" would stop meaning anything.
DOUBLED_NOTE_TEMPLATE = """---
version: %s
type: note
---
version: %s
type: note
---

# doubled selftest note

Body text.
"""

# The exact bytes every sandbox capture holds. Shared with the hermetic fetcher so
# a "current" capture and the body it is compared against cannot drift apart by
# accident inside the suite itself.
SELFTEST_CAPTURE_BODY = "prior published body for %s\n"

# Frontmatter opens on line 1 and NEVER closes, so the shipped strip range finds
# no terminator and the computed body is EMPTY. Drives A4's empty-strip blocker.
UNCLOSED_NOTE_TEMPLATE = """---
version: %s
type: note
title: %s selftest note with no closing delimiter
"""

BASELINE_REL = "release/releases/_selftest_baseline"

# Hermetic stand-in for check-release-body-drift.sh. Models the real contract --
# MATCH (0) when the note under NOTES_DIR_OVERRIDE equals the canonical baseline,
# DRIFT (1) when it does not -- by BYTE EQUALITY, never by recognising the marker
# string ARM-T seeds. A stub keyed on the marker would pass A5 while being blind
# to every other divergence, which is precisely the failure A5 exists to detect.
DRIFT_STUB = """#!/usr/bin/env bash
set -u
v=""
for a in "$@"; do
  case "$a" in
    --*) ;;
    *) if [ -z "$v" ]; then v="$a"; fi ;;
  esac
done
root="$(cd "$(dirname "$0")/../.." && pwd)"
fixture="${NOTES_DIR_OVERRIDE:-}/${v}_RELEASE_NOTES.md"
baseline="${root}/%s/${v}_RELEASE_NOTES.md"
if [ ! -f "$fixture" ]; then exit 3; fi
if [ ! -f "$baseline" ]; then exit 3; fi
if cmp -s "$fixture" "$baseline"; then exit 0; fi
exit 1
""" % BASELINE_REL

# An INERT checker: reports MATCH unconditionally, so it cannot see the seeded
# divergence. A5 must BLOCK on it -- accepting it would mean the emitter's
# post-edit verification runs blind.
INERT_STUB = """#!/usr/bin/env bash
exit 0
"""


def _git(root, *args):
    return _run(["git", "-C", root] + list(args))


def _seed(work, layout, versions, leadin=(), unclosed=(), unversioned=True,
          doubled=()):
    ndir = os.path.join(work, NOTES_REL)
    bdir = os.path.join(work, BASELINE_REL)
    if not os.path.isdir(bdir):
        os.makedirs(bdir)
    for v in versions:
        d = ndir if layout == "flat" else os.path.join(ndir, "v" + v[1])
        if not os.path.isdir(d):
            os.makedirs(d)
        if v in unclosed:
            tpl = UNCLOSED_NOTE_TEMPLATE
        elif v in doubled:
            tpl = DOUBLED_NOTE_TEMPLATE
        elif v in leadin:
            tpl = LEADIN_NOTE_TEMPLATE
        else:
            tpl = NOTE_TEMPLATE
        text = tpl % (v, v)
        base = "%s_RELEASE_NOTES.md" % v
        with open(os.path.join(d, base), "w") as fh:
            fh.write(text)
        # The A5 stub's oracle: a byte copy of the note, OUTSIDE notes/ so it
        # never enters the note enumeration A5 reads.
        with open(os.path.join(bdir, base), "w") as fh:
            fh.write(text)
    if not unversioned:
        return
    u = os.path.join(ndir, PERMITTED_SUBFOLDER)
    if not os.path.isdir(u):
        os.makedirs(u)
    with open(os.path.join(u, "keep_RELEASE_NOTES.md"), "w") as fh:
        fh.write(NOTE_TEMPLATE % ("keep", "keep"))
    with open(os.path.join(bdir, "keep_RELEASE_NOTES.md"), "w") as fh:
        fh.write(NOTE_TEMPLATE % ("keep", "keep"))


def _commit_push(work):
    _git(work, "-c", "user.email=t@t", "-c", "user.name=t", "add", "-A")
    _git(work, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "seed")
    _git(work, "push", "-q", "origin", "main")
    _git(work, "fetch", "-q", "origin")


def _sandbox(tmp, layout, versions, captures, leadin=(), tag=None,
             unclosed=(), unversioned=True, empty_captures=(), checker=None,
             doubled=()):
    """Build a hermetic sandbox repo with a real bare origin.

    `checker` writes a stand-in at DRIFT_TOOL_REL so A5 can run at all:
      None            -- no checker on disk; A5 must HALT (fail closed)
      "discriminating"-- byte-equality stub; A5 must PASS
      "inert"         -- always-MATCH stub; A5 must BLOCK
    """
    name = layout if tag is None else "%s-%s" % (layout, tag)
    work = os.path.join(tmp, "work-%s" % name)
    origin = os.path.join(tmp, "origin-%s.git" % name)
    os.makedirs(work)
    _run(["git", "init", "--bare", "-q", origin])
    rc, _o, _e = _run(["git", "init", "-q", "-b", "main", work])
    if rc != 0:
        _run(["git", "init", "-q", work])
        _git(work, "checkout", "-q", "-b", "main")
    _seed(work, layout, versions, leadin, unclosed, unversioned, doubled)
    capdir = "release/releases/_captures/selftest"
    os.makedirs(os.path.join(work, capdir))
    for v in captures:
        with open(os.path.join(work, capdir, "%s.published.txt" % v), "w") as fh:
            fh.write(SELFTEST_CAPTURE_BODY % v)
    for v in empty_captures:
        # A tracked but EMPTY capture. Present to `cat-file -e`, worthless as a
        # rollback source -- the distinction A3's second limb exists to make.
        with open(os.path.join(work, capdir, "%s.published.txt" % v), "w") as fh:
            fh.write("")
    if checker is not None:
        tool = os.path.join(work, DRIFT_TOOL_REL)
        if not os.path.isdir(os.path.dirname(tool)):
            os.makedirs(os.path.dirname(tool))
        with open(tool, "w") as fh:
            fh.write(DRIFT_STUB if checker == "discriminating" else INERT_STUB)
        os.chmod(tool, 0o755)
    _git(work, "remote", "add", "origin", origin)
    _commit_push(work)
    return work, capdir


def _live(versions, stale=(), unreadable=()):
    """Build a hermetic stand-in for `live_body_digest`.

    Models what GitHub is publishing for each version, so the suite can drive all
    four A3 outcomes with no network:
      default     -- exactly the bytes the sandbox capture holds  -> CURRENT
      in `stale`  -- those bytes plus one byte                    -> STALE
      in `unread` -- unreadable                                   -> UNREADABLE
      not listed  -- unreadable, reason "no published release"

    Deriving CURRENT from SELFTEST_CAPTURE_BODY rather than from a second literal
    is deliberate: a hand-copied "current" body could drift from the capture the
    sandbox actually wrote, and the suite would then be asserting agreement
    between two things it had itself made disagree.
    """
    def fetcher(version):
        if version in unreadable:
            return None, "hermetic: read failed"
        if version not in versions:
            return None, "hermetic: no published release"
        body = SELFTEST_CAPTURE_BODY % version
        if version in stale:
            body = body + "x"
        return hashlib.sha256(body.encode("utf-8")).hexdigest(), None
    return fetcher


def _preflight_capture(root, capdir, versions, fetcher=None):
    """Run `preflight()` end to end; return (return-code, printed banner text).

    The aggregate-level harness. Everything `--execute` is gated on -- the exit
    code and the rendered verdict line -- passes through here. `fetcher` defaults
    to an all-CURRENT hermetic one so no self-test path can reach the network.
    """
    if fetcher is None:
        fetcher = _live(versions)
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = preflight(root, capdir, versions, fetcher=fetcher)
    return rc, buf.getvalue()


def _arm(rep_rows, arm):
    for a, verdict, detail in rep_rows:
        if a == arm:
            return verdict, detail
    return None, None


def _evaluate(root, capdir, versions, fetcher=None):
    if fetcher is None:
        fetcher = _live(versions)
    rep = Report()
    arm_a1_a2(root, rep)
    arm_a3(root, capdir, versions, rep, fetcher=fetcher)
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

        # ── Case 3 -- A3's FOUR outcomes. Presence is not correspondence: the
        # arm must separate a capture that reproduces the live body from one that
        # merely exists, and the two failures are different repairs.
        v3a, d3a = _arm(rep2.rows, "A3")
        check("A3 passes when every capture is durable AND current", v3a == "PASS")
        check("A3's PASS says CORRESPOND, not merely present - a reader must not be "
              "able to mistake an existence check for a correspondence check",
              "CORRESPOND" in (d3a or "") and "present and non-empty" not in (d3a or ""),
              d3a or "")

        # ABSENT.
        work3, capdir3 = _sandbox(tmp, "flat", vs, [vs[0]], tag="partial-capture")
        rep3 = _evaluate(work3, capdir3, vs)
        v3b, d3b = _arm(rep3.rows, "A3")
        check("A3 blocks when a capture is missing from the ref", v3b == "BLOCK", d3b or "")
        check("A3 says ABSENT, and does not say STALE - different repairs",
              "1 ABSENT" in (d3b or "") and "STALE" not in (d3b or ""), d3b or "")

        # STALE -- THE DEFECT THIS LIMB EXISTS FOR. Every capture is present,
        # non-empty and durable at the ref; the published body has moved on. The
        # pre-repair arm printed PASS here, over captures that would have restored
        # the wrong content.
        rep3s = _evaluate(work2, capdir2, vs, fetcher=_live(vs, stale=[vs[1]]))
        v3s, d3s = _arm(rep3s.rows, "A3")
        check("A3 BLOCKS a durable but STALE capture (presence is not correspondence)",
              v3s == "BLOCK", d3s or "")
        check("A3 names which version is stale", vs[1] in (d3s or ""), d3s or "")
        check("A3 says STALE, not ABSENT - the stale capture is on the ref",
              "1 STALE" in (d3s or "") and "ABSENT" not in (d3s or ""), d3s or "")
        check("A3 prints both digests so the operator can cross-check SHA256SUMS",
              "capture=" in (d3s or "") and "live=" in (d3s or ""), d3s or "")
        check("A3 counts the surviving capture as corresponding, not as a pass",
              "(1 of 2 correspond)" in (d3s or ""), d3s or "")

        # UNREADABLE -- fails CLOSED. An arm that cannot establish correspondence
        # has not established it.
        rep3u = _evaluate(work2, capdir2, vs, fetcher=_live(vs, unreadable=[vs[0]]))
        v3u, d3u = _arm(rep3u.rows, "A3")
        check("A3 blocks when the live body cannot be read (fails closed)",
              v3u == "BLOCK", d3u or "")
        check("A3 says UNREADABLE and names the version", "UNREADABLE" in (d3u or "")
              and vs[0] in (d3u or ""), d3u or "")

        # A gh-less host must BLOCK, not pass. This drives the PRODUCTION fetcher's
        # own capability guard rather than a stand-in for it. `_find_gh` is
        # replaced rather than PATH being emptied, because `_find_gh` probes
        # absolute paths and would still find a real gh -- which would put a live
        # network call inside a suite that must stay hermetic.
        _real_find_gh = globals()["_find_gh"]
        try:
            globals()["_find_gh"] = lambda: ""
            dig, why = live_body_digest("v0.00")
        finally:
            globals()["_find_gh"] = _real_find_gh
        check("live_body_digest returns no digest, and a stated reason, when gh is "
              "absent - it can never return a digest it did not compute",
              dig is None and "gh is not installed" in (why or ""), repr((dig, why)))
        repgh = Report()
        arm_a3(work2, capdir2, vs, repgh, fetcher=lambda v: (None, "gh is not installed"))
        vgh, dgh = _arm(repgh.rows, "A3")
        check("A3 BLOCKS on a gh-less host rather than passing on presence alone",
              vgh == "BLOCK" and "UNREADABLE" in (dgh or ""), dgh or "")

        # The comparison digests BYTES, not lossily-decoded text. Without this the
        # `_run_raw` helper could be replaced by `_run` and every ASCII fixture in
        # this suite would still pass, while two genuinely different published
        # bodies collided into one digest and a stale capture read as current.
        collide_a, collide_b = b"\xff\x41", b"\xfe\x41"
        check("lossy decoding COLLIDES two distinct bodies, and their bytes do not - "
              "this is why A3 digests bytes",
              collide_a.decode("utf-8", "replace") == collide_b.decode("utf-8", "replace")
              and (hashlib.sha256(collide_a).hexdigest()
                   != hashlib.sha256(collide_b).hexdigest()))
        rcb, gotb, _eb = _run_raw([sys.executable, "-c",
                                   "import sys; sys.stdout.buffer.write(%r)" % collide_a])
        check("_run_raw returns RAW BYTES, so a non-UTF-8 body survives the read intact",
              rcb == 0 and gotb == collide_a, repr(gotb))

        # All four outcomes at once: they must remain separable in one render.
        vs4 = ["v1.01", "v2.02", "v3.03", "v4.04"]
        work3m, capdir3m = _sandbox(tmp, "flat", vs4, ["v1.01", "v2.02", "v3.03"],
                                    tag="mixed-a3", empty_captures=["v3.03"])
        rep3m = _evaluate(work3m, capdir3m, vs4,
                          fetcher=_live(vs4, stale=["v2.02"]))
        v3m, d3m = _arm(rep3m.rows, "A3")
        check("A3 reports ABSENT, EMPTY and STALE as three distinguishable buckets "
              "in one run", v3m == "BLOCK"
              and "1 ABSENT" in (d3m or "") and "1 EMPTY" in (d3m or "")
              and "1 STALE" in (d3m or ""), d3m or "")

        # ── Case 4 -- A4 both arms.
        v4a, _d = _arm(rep2.rows, "A4")
        check("A4 passes for well-formed notes", v4a == "PASS")

        # The lead-in note WAS A4's blocker. The strip is now repaired at the
        # source, so the same fixture must now pass on merit -- A4 is not
        # weakened, the defect is gone.
        work4, capdir4 = _sandbox(tmp, "flat", vs, vs, leadin=[vs[0]], tag="leadin")
        rep4 = _evaluate(work4, capdir4, vs)
        v4b, d4b = _arm(rep4.rows, "A4")
        check("A4 PASSES a lead-in note now that the strip is repaired "
              "(the fix lands, and A4 is not relaxed to get there)",
              v4b == "PASS", d4b or "")

        # ...and the frontmatter limb is still armed. A doubled block still
        # survives the strip, so A4 still blocks on it: the limb is live code.
        work4d, capdir4d = _sandbox(tmp, "flat", vs, vs, doubled=[vs[0]], tag="doubled")
        rep4d = _evaluate(work4d, capdir4d, vs)
        v4d, d4d = _arm(rep4d.rows, "A4")
        check("A4 still blocks a body that survives the strip still looking like "
              "frontmatter", v4d == "BLOCK", d4d or "")
        check("A4 names the offending version", vs[0] in (d4d or ""), d4d or "")

        # Case 5 -- the strip model itself, every direction.
        good = strip_frontmatter(NOTE_TEMPLATE % ("v9.99", "v9.99"))
        lead = strip_frontmatter(LEADIN_NOTE_TEMPLATE % ("v9.99", "v9.99"))
        dbl = strip_frontmatter(DOUBLED_NOTE_TEMPLATE % ("v9.99", "v9.99"))
        check("strip model: well-formed note yields prose",
              good.strip().startswith("# v9.99"), repr(good[:40]))
        check("strip model: lead-in note yields prose, NOT its YAML block",
              lead.strip().startswith("# v9.99") and "version:" not in lead,
              repr(lead[:60]))
        check("strip model: stage 1 is the identity when the delimiter is line 1 - "
              "a lead-in note and its lead-in-free twin strip to the same bytes",
              lead == good, repr((lead[:30], good[:30])))
        check("strip model: a doubled block leaves the second block behind",
              dbl.strip().startswith("version:"), repr(dbl[:40]))
        check("strip model: no frontmatter at all yields NOTHING, so the caller's "
              "empty-body ABORT fires instead of a mis-stripped body publishing",
              strip_frontmatter("# Heading\n\nprose\n") == "",
              repr(strip_frontmatter("# Heading\n\nprose\n")))
        check("strip model: an opening delimiter with no closing one yields NOTHING",
              strip_frontmatter(UNCLOSED_NOTE_TEMPLATE % ("v9.99", "v9.99")) == "")
        check("looks_like_frontmatter: sensitivity", looks_like_frontmatter(dbl))
        check("looks_like_frontmatter: specificity", not looks_like_frontmatter(good))
        check("looks_like_frontmatter: specificity on the repaired lead-in body",
              not looks_like_frontmatter(lead))
        # `good` returns at the leading-blank guard, so it never reaches the
        # key_like AND terminator test. These two do, one per conjunct.
        check("looks_like_frontmatter: a prose opening is not frontmatter",
              not looks_like_frontmatter("Plain prose opening line.\n\nMore text.\n"))
        check("looks_like_frontmatter: a key-like line with no terminator is not frontmatter",
              not looks_like_frontmatter("version: v9.99\n\nprose\n"))

        # Case 6 -- unresolvable ref halts rather than passing.
        bare = os.path.join(tmp, "norepo")
        os.makedirs(bare)
        _run(["git", "init", "-q", bare])
        rc6, out6 = _preflight_capture(bare, "nowhere", ["v0.00"])
        check("unresolvable %s halts (exit 2), never passes" % REF,
              rc6 == HALT, "rc=%s" % rc6)
        check("unresolvable %s renders the HALT banner" % REF,
              "PREFLIGHT HALT" in out6 and "PREFLIGHT PASS" not in out6, repr(out6[-90:]))

        # ── Case 7 -- THE AGGREGATE VERDICT, both directions. ──────────────
        # A per-arm suite cannot see a summary that disagrees with its rows.
        # These assert the two things `--execute` is actually gated on: the
        # return code and the rendered banner.
        rc7b, out7b = _preflight_capture(work, capdir, vs)          # foldered => A1 BLOCK
        check("BLOCKING run: preflight() returns BLOCK", rc7b == BLOCK, "rc=%s" % rc7b)
        check("BLOCKING run: banner says BLOCKED, never PASS",
              "PREFLIGHT BLOCKED" in out7b and "PREFLIGHT PASS" not in out7b,
              repr(out7b[-90:]))
        check("BLOCKING run: at least one arm rendered BLOCK",
              "BLOCK" in out7b.split("PREFLIGHT")[0])
        a5_rows = [ln for ln in out7b.split("\n") if ln.split()[:1] == ["A5"]]
        check("BLOCKING run: A5 renders SKIP, and SKIP does not veto the BLOCK",
              len(a5_rows) == 1 and a5_rows[0].split()[1] == "SKIP",
              repr(a5_rows))

        workp, capdirp = _sandbox(tmp, "flat", vs, vs, tag="pass-aggregate",
                                  checker="discriminating")
        rc7p, out7p = _preflight_capture(workp, capdirp, vs)
        check("PASSING run: preflight() returns PASS", rc7p == PASS,
              "rc=%s out=%s" % (rc7p, out7p[-400:]))
        check("PASSING run: banner says PASS, never BLOCKED",
              "PREFLIGHT PASS" in out7p and "PREFLIGHT BLOCKED" not in out7p,
              repr(out7p[-90:]))
        a5p = [ln for ln in out7p.split("\n") if ln.split()[:1] == ["A5"]]
        check("PASSING run: A5 is actually TAKEN, not skipped",
              len(a5p) == 1 and a5p[0].split()[1] == "PASS", repr(a5p))

        # ── Case 8 -- the aggregate is DERIVED, not maintained. ────────────
        r = Report()
        check("worst of an empty report is PASS", r.worst == PASS)
        r.add("X1", "PASS", "-")
        check("worst of all-PASS rows is PASS", r.worst == PASS)
        r.skip("X2", "-")
        check("SKIP does not escalate the aggregate", r.worst == PASS)
        r.add("X3", "BLOCK", "-")
        check("a BLOCK row escalates the aggregate", r.worst == BLOCK)
        r.halt("X4", "-")
        check("a HALT row outranks a BLOCK row", r.worst == HALT)
        ru = Report()
        ru.add("X5", "MAYBE", "-")
        check("an UNKNOWN verdict fails closed to HALT, never PASS",
              ru.worst == HALT, "worst=%s" % ru.worst)
        derived = False
        try:
            r.worst = PASS
        except AttributeError:
            derived = True
        check("worst cannot be assigned - it is derived, not maintained", derived)
        rb, rp, rh = Report(), Report(), Report()
        rb.add("A1", "BLOCK", "-")
        rp.add("A1", "PASS", "-")
        rh.halt("A1", "-")
        check("render(): a BLOCK row prints the BLOCKED banner",
              "PREFLIGHT BLOCKED" in rb.render() and "PREFLIGHT PASS" not in rb.render())
        check("render(): all-PASS prints the PASS banner",
              "PREFLIGHT PASS" in rp.render() and "PREFLIGHT BLOCKED" not in rp.render())
        check("render(): a HALT row prints the HALT banner",
              "PREFLIGHT HALT" in rh.render() and "PREFLIGHT PASS" not in rh.render())

        # ── Case 9 -- A2's BLOCK path. Every other sandbox seeds the permitted
        # subfolder, so without this the specificity arm's own failure is untested.
        work9, capdir9 = _sandbox(tmp, "flat", vs, vs, tag="no-unversioned",
                                  unversioned=False)
        rep9 = _evaluate(work9, capdir9, vs)
        v9a, d9a = _arm(rep9.rows, "A2")
        v9b, _d = _arm(rep9.rows, "A1")
        check("A2 blocks when the permitted subfolder is absent", v9a == "BLOCK", d9a or "")
        check("A2's block is not A1's - A1 still passes on a flat tree", v9b == "PASS")

        # ── Case 10 -- A3's empty-capture limb. Present to `cat-file -e`,
        # worthless as a rollback source.
        work10, capdir10 = _sandbox(tmp, "flat", vs, [vs[0]], tag="empty-capture",
                                    empty_captures=[vs[1]])
        rep10 = _evaluate(work10, capdir10, vs)
        v10, d10 = _arm(rep10.rows, "A3")
        check("A3 blocks on a present-but-EMPTY capture", v10 == "BLOCK", d10 or "")
        check("A3 counts it as EMPTY, not as ABSENT",
              "1 ABSENT" not in (d10 or "") and "1 EMPTY" in (d10 or ""), d10 or "")

        # ── Case 11 -- A4's empty-strip and unresolved limbs.
        work11, capdir11 = _sandbox(tmp, "flat", vs, vs, tag="unclosed",
                                    unclosed=[vs[1]])
        rep11 = _evaluate(work11, capdir11, vs)
        v11, d11 = _arm(rep11.rows, "A4")
        check("A4 blocks when the strip produces an EMPTY body", v11 == "BLOCK", d11 or "")
        check("A4 says EMPTY and names the version",
              "EMPTY" in (d11 or "") and vs[1] in (d11 or ""), d11 or "")
        ghost = "v9.99"
        rep11b = _evaluate(work2, capdir2, [vs[0], ghost])
        v11b, d11b = _arm(rep11b.rows, "A4")
        check("A4 blocks a version whose note resolves NOWHERE", v11b == "BLOCK", d11b or "")
        check("A4 says unresolved and names the ghost version",
              "unresolved" in (d11b or "") and ghost in (d11b or ""), d11b or "")

        # ── Case 12 -- resolve_note's RECURSIVE fallback. This is the exact
        # defect that produced this card: a flat-path-only resolver reported a
        # FABRICATED "absent" for every foldered note. `work` is the foldered
        # sandbox, where the note exists at NO flat path.
        nested = resolve_note(work, REF, vs[0])
        check("resolve_note finds a foldered note via the recursive fallback",
              nested is not None and nested.endswith("/%s_RELEASE_NOTES.md" % vs[0])
              and nested != "%s/%s_RELEASE_NOTES.md" % (NOTES_REL, vs[0]),
              repr(nested))
        flat = resolve_note(work2, REF, vs[0])
        check("resolve_note prefers the flat path when one exists",
              flat == "%s/%s_RELEASE_NOTES.md" % (NOTES_REL, vs[0]), repr(flat))
        check("resolve_note invents nothing for a version that exists nowhere",
              resolve_note(work2, REF, ghost) is None)
        v12, _d = _arm(_evaluate(work, capdir, vs).rows, "A4")
        check("A4 resolves every note in a FOLDERED corpus (recursion is load-bearing)",
              v12 == "PASS")

        # ── Case 13 -- A5, which had no coverage at all. Three states.
        rep13 = Report()
        arm_a5(workp, rep13)
        v13, d13 = _arm(rep13.rows, "A5")
        check("A5 passes against a checker that discriminates", v13 == "PASS", d13 or "")
        work13, _c13 = _sandbox(tmp, "flat", vs, vs, tag="inert-checker",
                                checker="inert")
        rep13b = Report()
        arm_a5(work13, rep13b)
        v13b, d13b = _arm(rep13b.rows, "A5")
        check("A5 blocks a checker that cannot see a seeded divergence",
              v13b == "BLOCK", d13b or "")
        rep13c = Report()
        arm_a5(work2, rep13c)                      # no checker on disk at all
        v13c, d13c = _arm(rep13c.rows, "A5")
        check("A5 HALTs when the drift checker is absent (fails closed)",
              v13c == "HALT" and DRIFT_TOOL_REL in (d13c or ""), d13c or "")
        rep13d = Report()
        arm_a5(workp, rep13d, seeder=lambda raw: raw)
        v13d, d13d = _arm(rep13d.rows, "A5")
        check("A5 HALTs on an INERT fixture rather than reporting its result",
              v13d == "HALT" and "BROKEN PROBE" in (d13d or ""), d13d or "")
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

#!/usr/bin/env python3
"""Append-pattern aware cross-member line-range overlap detection.

Computes per-file overlap_class over a contention population that has TWO
arms, both of which this tool can classify:

  P1  open PRs whose head ref begins with `release/`   -> --pr-list
  P2  remote `release/*` heads with NO open PR         -> --branch-list

Both arms are read by ONE extraction engine (`git diff -U3 --merge-base`),
so verdict parity between them is structural rather than asserted. The prior
two-engine shape (`gh api .../pulls/<N>/files` for PRs, `git diff` for
branches) was measured to DISAGREE on 4 of 17 files of a live PR: GitHub's
`.patch` coalesces adjacent hunk pairs that `git diff -U3
--diff-algorithm=myers` splits, and a one-line gap between the split halves
flips `line-range-overlap` to `append-pattern` for a sibling editing that
gap. A PR member is resolved to `refs/pull/<N>/head` and diffed exactly like
a branch member; the tool no longer calls `gh` on the classification path.

Classifies each contended file (file_path appearing in >=2 distinct member
rows) as one of:

  append-pattern        ALL pairs of members have zero overlapping hunks
  line-range-overlap    AT LEAST ONE pair has overlapping hunks
  single-pr             file appears in exactly 1 distinct member row

Threshold: 0% pairwise hunk overlap = append-pattern (zero-tolerance).
Two hunks [s1,e1] and [s2,e2] overlap iff max(s1,s2) <= min(e1,e2).
Coordinate model: post-diff line numbers from @@ -A,B +C,D @@ headers
(start = C, end = C + D - 1). Coordinates are anchored at each member's
merge-base; conservatism is the safer error direction.

The three-value `overlap_class` enum is FROZEN (ADR-005 Decision). The
branch arm adds no fourth value: unresolvability is carried on a separate
channel (stderr + `.partial` + exit 2), never as a verdict.

Member identity (`pr_number` column, `line_ranges` map key):
  PR member      bare integer, e.g. `5269`      (shape unchanged)
  branch member  `branch:release/<slug>`        (`<kind>:<id>`, per the
                 pipeline-event-log-schema `actor`/`subject` convention)
The `pr_number` column name is retained deliberately: renaming it, or adding
a `member_kind` column, would change the TSV shape for every existing reader
for a cosmetic gain. Discriminate on the one greppable `branch:` prefix.

Extraction is a THREE-state contract evaluated at the PARSE boundary, not at
the transport boundary:
  absent           member did not touch this file (empty diff)     -> ignored
  present          >=1 parseable hunk header                       -> classified
  unrepresentable  member DID touch it, zero parseable hunks       -> UNRESOLVED
The third state is the one a `returncode != 0` guard cannot see. A whole-file
delete emits `@@ -1,N +0,0 @@` at git exit 0 with thousands of bytes of real
diff and parses to zero ranges; a rename-only, binary, or mode-only change
does the same. Treating that as "did not touch the file" scores the most
conflicting edit possible as the most benign class. Asserting a NON-EMPTY
EXTRACTION does not catch it -- the extraction is large. The invariant lives
at parse, and that is where it is asserted.

Partial results are MONOTONE, not blanket-suppressed. `line-range-overlap` is
closed under member addition (an unseen member can only add overlap, never
remove it), so it is still emitted -- with `partial: true` -- when some member
is unresolvable. `append-pattern` and `single-pr` are NOT closed under member
addition and are omitted instead. This keeps a sound alarm rather than
converting one bad member into a whole-run blackout.

Exit codes:
  0  audit complete -- every (member, file) pair was resolved
  1  argument error (the tool's own validation AND argparse usage errors)
  2  EXTRACTION FAILURE -- the tool could not look. The output is PARTIAL,
     it is NOT "no overlap". A consumer reading $? must record the named
     members as UNRESOLVABLE and must never fold this into CONTENTION-NONE.
  3  self-test failure

Authored per the Stage 5 spec.
"""
from __future__ import annotations

import argparse
import contextlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

# Pinned PATH per bypass-mode-readiness.md posture
os.environ["PATH"] = "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"

HUNK_HEADER_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")

# Three-state extraction vocabulary. Deliberately NOT the overlap_class enum:
# these name what was observed, overlap_class names the verdict.
EXTRACT_ABSENT = "absent"
EXTRACT_PRESENT = "present"
EXTRACT_UNREPRESENTABLE = "unrepresentable"

DEFAULT_REMOTE = "origin"
DEFAULT_BASE_REF = "origin/main"

# `-U3` is load-bearing, not stylistic: a `diff.context = 7` gitconfig widens
# hunk ranges enough to flip a disjoint fixture pair from append-pattern to
# line-range-overlap. Pinning it makes the verdict immune to the runner's
# git configuration.
CONTEXT_FLAG = "-U3"
ANCHOR_MERGE_BASE = "merge-base"
ANCHOR_TWO_DOT = "two-dot"  # DEFECTIVE anchor; reachable only from --self-test

RELEASE_PREFIX = "release/"


class ExtractionError(Exception):
    """A (member, file) pair could not be read. NEVER resolves to a verdict."""

    def __init__(self, member: str, path: str, reason: str) -> None:
        super().__init__("%s\t%s\t%s" % (member, path, reason))
        self.member = member
        self.path = path
        self.reason = reason


class _ArgParser(argparse.ArgumentParser):
    """Usage errors exit 1, not argparse's default 2.

    Exit 2 is reserved for extraction failure. A consumer is being told that
    `2` means "the classification is incomplete"; a typo on the command line
    must not be able to counterfeit that state.
    """

    def error(self, message: str):  # noqa: D102 - argparse override
        self.print_usage(sys.stderr)
        print("%s: error: %s" % (self.prog, message), file=sys.stderr)
        sys.exit(1)


def parse_hunk_ranges(patch_text: str) -> list[tuple[int, int]]:
    """Extract [start, end] tuples from unified-diff hunk headers."""
    ranges: list[tuple[int, int]] = []
    if not patch_text:
        return ranges
    for line in patch_text.splitlines():
        m = HUNK_HEADER_RE.match(line)
        if m:
            start = int(m.group(1))
            length = int(m.group(2)) if m.group(2) else 1
            if length > 0:
                ranges.append((start, start + length - 1))
    return ranges


def hunks_overlap(a: tuple[int, int], b: tuple[int, int]) -> bool:
    """True iff hunks [s1,e1] and [s2,e2] overlap (closed intervals)."""
    return max(a[0], b[0]) <= min(a[1], b[1])


def classify_overlap_class(
    member_to_ranges: dict[str, list[tuple[int, int]]],
) -> str:
    """Apply ADR-005 Decision classification rule.

    Keys are member tokens and MUST all be `str`. A mixed int/str map -- which
    `P1 union P2` is by construction -- raises TypeError at `sorted()`.

    An EMPTY map raises rather than returning `append-pattern`: no data is not
    a benign verdict, and the caller is responsible for not asking.
    """
    if not member_to_ranges:
        raise ValueError(
            "classify_overlap_class called with zero members -- "
            "no data is not a verdict"
        )
    members = sorted(member_to_ranges.keys())
    if len(members) == 1:
        return "single-pr"
    for i, m_i in enumerate(members):
        for m_j in members[i + 1:]:
            for h_i in member_to_ranges[m_i]:
                for h_j in member_to_ranges[m_j]:
                    if hunks_overlap(h_i, h_j):
                        return "line-range-overlap"
    return "append-pattern"


def classify_extraction(patch_text: str) -> tuple[str, list[tuple[int, int]]]:
    """Three-state contract at the PARSE boundary.

    Returns (state, ranges). `unrepresentable` is the state a
    `returncode != 0` guard structurally cannot observe: git exits 0 and
    emits a large diff, and the parser still yields zero ranges.
    """
    ranges = parse_hunk_ranges(patch_text)
    if ranges:
        return EXTRACT_PRESENT, ranges
    if patch_text.strip():
        return EXTRACT_UNREPRESENTABLE, []
    return EXTRACT_ABSENT, []


def _git(root: str, args: list[str]) -> subprocess.CompletedProcess:
    """Run git against an explicit root. Never `os.chdir` -- that is process-global."""
    return subprocess.run(
        ["git", "-C", root] + list(args),
        capture_output=True, text=True, check=False,
    )


def repo_root(explicit: str) -> str:
    """Resolve the repository root; '' when there is none."""
    if explicit:
        return explicit
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def resolve_rev(root: str, candidates: list[str]) -> str:
    """Return the commit SHA of the first candidate that resolves, else ''."""
    for cand in candidates:
        result = _git(root, ["rev-parse", "--verify", "--quiet", cand + "^{commit}"])
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    return ""


def normalize_branch_ref(ref: str) -> str:
    """Strip a `refs/heads/` prefix so the ls-remote spelling is accepted."""
    ref = ref.strip()
    if ref.startswith("refs/heads/"):
        ref = ref[len("refs/heads/"):]
    return ref


def is_release_branch_ref(ref: str) -> bool:
    """PREFIX match, never substring.

    A dependency-bot branch can carry `release/` mid-path (`dependabot/
    release/alpha`) and is not a release branch.
    """
    return ref.startswith(RELEASE_PREFIX)


def member_token(kind: str, ident: str) -> str:
    """`5269` for a PR member, `branch:release/<slug>` for a branch member."""
    return str(ident) if kind == "pr" else "branch:" + str(ident)


def member_ref_candidates(kind: str, ident: str, remote: str) -> list[str]:
    """Ref spellings tried, in order, when resolving a member to a commit."""
    if kind == "pr":
        return [
            "refs/pull/%s/head" % ident,
            "refs/remotes/%s/pull/%s/head" % (remote, ident),
        ]
    return [
        "refs/remotes/%s/%s" % (remote, ident),
        "refs/heads/%s" % ident,
        str(ident),
    ]


def resolve_member(
    root: str, kind: str, ident: str, remote: str = DEFAULT_REMOTE,
    allow_fetch: bool = True,
) -> tuple[str, str]:
    """Resolve a member to (token, commit SHA), or raise ExtractionError.

    A PR member's bounded fetch is attempted UNCONDITIONALLY, never gated on
    the local ref being absent. Gating it on absence is a silent stale-read:
    a ref that is present but behind its upstream resolves happily, so the
    tool classifies an OLD revision at exit 0 with no error -- and the caller
    at `stage-09-plan-review.md` takes the P1 arm's *path set* from a live
    `gh pr view` while taking its *line ranges* from here, which would render
    one PR at two revisions under one verdict.

    The fetch is failure-TOLERANT, which is what keeps the offline callers
    working: `_git` runs with `check=False`, so a hermetic fixture with no
    remote, or an offline run, simply proceeds to the local resolve below.
    Tolerating the failure is not the same as skipping the attempt -- the
    branch arm still does no network I/O at all, per the Phase A6.6 contract
    that assigns that fetch to the caller.
    """
    token = member_token(kind, ident)
    candidates = member_ref_candidates(kind, ident, remote)
    if kind == "pr" and allow_fetch:
        _git(root, [
            "fetch", "--no-tags", "--quiet", remote,
            "+refs/pull/%s/head:refs/pull/%s/head" % (ident, ident),
        ])
    sha = resolve_rev(root, candidates)
    if not sha:
        raise ExtractionError(
            token, "*",
            "member ref does not resolve (tried: %s)" % ", ".join(candidates),
        )
    return token, sha


def build_diff_argv(
    base_rev: str, member_rev: str, file_path: str,
    context_flag: str, anchor: str,
) -> list[str]:
    """Assemble the single extraction engine's argv.

    `context_flag` and `anchor` are REQUIRED here, deliberately. Giving them
    defaults in both this function and `extract_patch` would declare each pin
    in two places while only one is ever read -- mutation testing found the
    dead one, and a pin nothing reads is a pin nothing observes. The single
    declaration site is `extract_patch`.

    The parameters exist at all so `--self-test` can remove each pin and
    demonstrate that the fixture then fails. There is no CLI surface for either.
    """
    argv = ["diff"]
    if context_flag:
        argv.append(context_flag)
    argv += ["--no-ext-diff", "--no-color", "--diff-algorithm=myers"]
    if anchor == ANCHOR_MERGE_BASE:
        argv += ["--merge-base", base_rev, member_rev]
    else:
        argv += [base_rev, member_rev]
    argv += ["--", file_path]
    return argv


def extract_patch(
    root: str, base_rev: str, member_rev: str, member: str, file_path: str,
    context_flag: str = CONTEXT_FLAG, anchor: str = ANCHOR_MERGE_BASE,
) -> str:
    """Return the unified diff for (member, file), anchored at the merge-base.

    Raises ExtractionError on any git failure. It NEVER returns "" silently --
    the silent-empty return is the defect this tool exists to stop making.
    """
    result = _git(root, build_diff_argv(
        base_rev, member_rev, file_path, context_flag, anchor,
    ))
    if result.returncode != 0:
        reason = result.stderr.strip()[:200] or "git diff exit %d" % result.returncode
        raise ExtractionError(member, file_path, reason)
    return result.stdout


def _emit_unresolved(unresolved: list[dict]) -> None:
    """Name every unresolvable pair on stderr, then say what exit 2 means."""
    for item in unresolved:
        print(
            "EXTRACTION-FAILED\t%s\t%s\t%s"
            % (item["member"], item["path"], item["reason"]),
            file=sys.stderr,
        )
    print(
        "PARTIAL: %d member/file extraction(s) unresolved. This result is "
        "INCOMPLETE, not \"no overlap\" -- record the members named above as "
        "UNRESOLVABLE, never as CONTENTION-NONE." % len(unresolved),
        file=sys.stderr,
    )


def main() -> int:
    ap = _ArgParser(
        description=(
            "Append-pattern aware cross-member line-range overlap detection "
            "(ADR-005). One extraction engine serves both population arms."
        ),
        epilog=(
            "Exit codes: 0 complete | 1 argument error | 2 EXTRACTION FAILURE "
            "(output is PARTIAL, never \"no overlap\" -- record the named "
            "members as UNRESOLVABLE) | 3 self-test failure."
        ),
    )
    ap.add_argument("--self-test", action="store_true",
                    help="Run regression + hermetic fixture tests (no network calls)")
    ap.add_argument("--baseline-sha",
                    help="Baseline commit SHA recorded in audit metadata")
    ap.add_argument("--repo", default=os.environ.get("PMO_REPO_SLUG", ""),
                    help="Accepted for caller compatibility; unused since the "
                         "classification path no longer calls gh")
    ap.add_argument("--pr-list",
                    help="Comma-separated PR numbers (the P1 arm)")
    ap.add_argument("--branch-list",
                    help="Comma-separated release/* branch refs (the P2 arm)")
    ap.add_argument("--base-ref", default=DEFAULT_BASE_REF,
                    help="Merge-base anchor (default: %s)" % DEFAULT_BASE_REF)
    ap.add_argument("--remote", default=DEFAULT_REMOTE,
                    help="Remote name for ref resolution (default: %s)" % DEFAULT_REMOTE)
    ap.add_argument("--root", default="",
                    help="Repository root (default: git rev-parse --show-toplevel)")
    ap.add_argument("--files",
                    help="Comma-separated file paths")
    ap.add_argument("--output-format", choices=["tsv", "json"], default="tsv")
    args = ap.parse_args()

    if args.self_test:
        return run_self_test()

    if not args.baseline_sha or not (args.pr_list or args.branch_list) or not args.files:
        print(
            "ERROR: --baseline-sha, --files and at least one of --pr-list / "
            "--branch-list are required (or use --self-test)",
            file=sys.stderr,
        )
        return 1

    members: list[tuple[str, str]] = []
    if args.pr_list:
        try:
            for token in args.pr_list.split(","):
                members.append(("pr", str(int(token))))
        except ValueError:
            print("ERROR: --pr-list must be comma-separated integers", file=sys.stderr)
            return 1
    if args.branch_list:
        for raw in args.branch_list.split(","):
            ref = normalize_branch_ref(raw)
            if not ref:
                continue
            if not is_release_branch_ref(ref):
                print(
                    "ERROR: --branch-list member %r is not a release branch. The "
                    "match is on the %r PREFIX -- a ref carrying it mid-path is "
                    "not a release branch." % (ref, RELEASE_PREFIX),
                    file=sys.stderr,
                )
                return 1
            members.append(("branch", ref))

    files = [f for f in args.files.split(",") if f]
    if not files:
        print("ERROR: --files resolved to an empty path list", file=sys.stderr)
        return 1

    root = repo_root(args.root)
    unresolved: list[dict] = []
    if not root:
        print(
            "EXTRACTION-FAILED\t*\t*\tnot a git repository (pass --root)",
            file=sys.stderr,
        )
        _emit_unresolved([])
        return 2

    base_rev = resolve_rev(root, [args.base_ref])
    if not base_rev:
        unresolved.append({
            "member": "*", "path": "*",
            "reason": "base ref %r does not resolve" % args.base_ref,
        })
        _emit_unresolved(unresolved)
        return 2

    # Resolve members to head SHAs, keeping input order. Two spellings of one
    # head are one member: the caller computes `P2` by subtracting `P1` head
    # refs, a subtraction it may compute wrongly, and two spellings of one
    # change would otherwise classify as line-range-overlap against itself.
    member_order: list[str] = []
    member_rev: dict[str, str] = {}
    seen_sha: dict[str, str] = {}
    for kind, ident in members:
        try:
            token, sha = resolve_member(root, kind, ident, args.remote)
        except ExtractionError as exc:
            unresolved.append({
                "member": exc.member, "path": exc.path, "reason": exc.reason,
            })
            continue
        if sha in seen_sha:
            print(
                "DUPLICATE-MEMBER\t%s\t%s\t%s\tcoalesced -- two spellings of one head"
                % (token, seen_sha[sha], sha),
                file=sys.stderr,
            )
            continue
        seen_sha[sha] = token
        member_order.append(token)
        member_rev[token] = sha

    # Collect line_ranges per (file, member)
    per_file: dict[str, dict[str, list[tuple[int, int]]]] = {f: {} for f in files}
    for token in member_order:
        for f in files:
            try:
                patch = extract_patch(root, base_rev, member_rev[token], token, f)
            except ExtractionError as exc:
                unresolved.append({
                    "member": exc.member, "path": exc.path, "reason": exc.reason,
                })
                continue
            state, ranges = classify_extraction(patch)
            if state == EXTRACT_PRESENT:
                per_file[f][token] = ranges
            elif state == EXTRACT_UNREPRESENTABLE:
                unresolved.append({
                    "member": token, "path": f,
                    "reason": "touched the file but emitted no parseable hunk "
                              "header (delete / rename / binary / mode-only); "
                              "%d bytes extracted" % len(patch),
                })

    # A member-level failure ("*") makes EVERY file partial.
    global_unresolved = any(item["path"] == "*" for item in unresolved)
    unresolved_paths = {item["path"] for item in unresolved}

    # Classify. On a partial member set only the MONOTONE verdict is emitted:
    # line-range-overlap is closed under member addition, append-pattern and
    # single-pr are not.
    overlap_classes: dict[str, str] = {}
    for f, member_ranges in per_file.items():
        if not member_ranges:
            continue
        verdict = classify_overlap_class(member_ranges)
        if global_unresolved or f in unresolved_paths:
            if verdict == "line-range-overlap":
                overlap_classes[f] = verdict
            continue
        overlap_classes[f] = verdict

    if args.output_format == "json":
        out: dict = {
            "baseline_sha": args.baseline_sha,
            "files": {
                f: {
                    "overlap_class": overlap_classes.get(f),
                    "line_ranges": {
                        token: per_file[f].get(token, [])
                        for token in member_order
                    },
                }
                for f in files
            },
        }
        if unresolved:
            out["partial"] = True
            out["unresolved"] = unresolved
        print(json.dumps(out, indent=2))
    else:
        print("file_path\tpr_number\tline_ranges\toverlap_class")
        for f in files:
            if f not in per_file or not per_file[f]:
                continue
            cls = overlap_classes.get(f)
            if cls is None:
                continue
            for token in member_order:
                ranges = per_file[f].get(token, [])
                ranges_json = json.dumps([list(r) for r in ranges])
                print(f"{f}\t{token}\t{ranges_json}\t{cls}")

    if unresolved:
        _emit_unresolved(unresolved)
        return 2
    return 0


# ---------------------------------------------------------------------------
# Self-test
# ---------------------------------------------------------------------------

_FIXTURE_ENV_KEYS = (
    "GIT_CONFIG_NOSYSTEM", "GIT_CONFIG_GLOBAL", "HOME", "XDG_CONFIG_HOME",
    "GIT_TERMINAL_PROMPT", "GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE",
    "GIT_AUTHOR_NAME", "GIT_AUTHOR_EMAIL", "GIT_AUTHOR_DATE",
    "GIT_COMMITTER_NAME", "GIT_COMMITTER_EMAIL", "GIT_COMMITTER_DATE",
)


def _fixture_env(tmp: str) -> dict:
    """Hermetic git environment. Every key here closes a cross-machine break."""
    home = os.path.join(tmp, "home")
    os.makedirs(home, exist_ok=True)
    return {
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_CONFIG_GLOBAL": os.path.join(home, "gitconfig-absent"),
        "HOME": home,
        "XDG_CONFIG_HOME": os.path.join(home, ".config"),
        "GIT_TERMINAL_PROMPT": "0",
        "GIT_DIR": None,          # a leaked GIT_DIR would point at the OUTER repo
        "GIT_WORK_TREE": None,
        "GIT_INDEX_FILE": None,
        "GIT_AUTHOR_NAME": "selftest",
        "GIT_AUTHOR_EMAIL": "selftest@example.invalid",
        "GIT_AUTHOR_DATE": "2026-01-01T00:00:00+00:00",
        "GIT_COMMITTER_NAME": "selftest",
        "GIT_COMMITTER_EMAIL": "selftest@example.invalid",
        "GIT_COMMITTER_DATE": "2026-01-01T00:00:00+00:00",
    }


def _run_main(argv: list[str]) -> tuple[int, str, str]:
    """Drive main() end-to-end, capturing stdout / stderr / exit code."""
    saved = sys.argv
    out, err = io.StringIO(), io.StringIO()
    sys.argv = ["check-line-range-overlap.py"] + argv
    try:
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                rc = main()
            except SystemExit as exc:  # argparse usage errors
                rc = exc.code if isinstance(exc.code, int) else 1
    finally:
        sys.argv = saved
    return rc, out.getvalue(), err.getvalue()


def _fx_write(root: str, name: str, lines: list[str]) -> None:
    with open(os.path.join(root, name), "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def _fx_commit(root: str, message: str) -> None:
    _git(root, ["add", "-A"])
    result = _git(root, [
        "-c", "commit.gpgsign=false", "commit", "-q", "--no-verify", "-m", message,
    ])
    if result.returncode != 0:
        raise RuntimeError("fixture commit failed: " + result.stderr.strip())


def _fx_branch(root: str, name: str, base_lines: list[str],
               start: int, count: int, tag: str) -> None:
    """Cut `name` from main and rewrite `count` lines beginning at 1-based `start`."""
    _git(root, ["checkout", "-q", "-b", name, "main"])
    lines = list(base_lines)
    for offset in range(count):
        lines[start - 1 + offset] = "%s %03d" % (tag, start + offset)
    _fx_write(root, "f.txt", lines)
    _fx_commit(root, "%s edits %d-%d" % (name, start, start + count - 1))
    _git(root, ["checkout", "-q", "main"])


def _build_fixture(tmp: str) -> str:
    """A hermetic repo with the branch shapes the contention population has."""
    root = os.path.join(tmp, "repo")
    os.makedirs(root, exist_ok=True)
    if _git(root, ["init", "-q"]).returncode != 0:
        raise RuntimeError("fixture git init failed")
    _git(root, ["symbolic-ref", "HEAD", "refs/heads/main"])
    base_lines = ["line %03d" % n for n in range(1, 101)]
    _fx_write(root, "f.txt", base_lines)
    _fx_commit(root, "base")

    _fx_branch(root, "release/alpha", base_lines, 40, 3, "alpha")
    _fx_branch(root, "release/beta", base_lines, 41, 3, "beta")     # overlaps alpha
    _fx_branch(root, "release/gamma", base_lines, 90, 3, "gamma")   # disjoint
    _fx_branch(root, "release/delta", base_lines, 50, 2, "delta")   # near-miss at U3

    # A TWO-REVISION PR head, for the E10 stale-ref arm. Revision A edits
    # 60-62 only; revision B ALSO edits 41-43, which OVERLAPS release/alpha.
    # The second edit is what makes the arm bite: reading A instead of B does
    # not merely report stale line numbers, it downgrades a real contention to
    # append-pattern at exit 0. A single-revision head could only ever prove
    # the numbers moved, which is the weaker claim.
    _git(root, ["checkout", "-q", "-b", "release/epsilon", "main"])
    eps_a = list(base_lines)
    for offset in range(3):
        eps_a[59 + offset] = "epsilon %03d" % (60 + offset)
    _fx_write(root, "f.txt", eps_a)
    _fx_commit(root, "release/epsilon rev A edits 60-62")
    eps_b = list(eps_a)
    for offset in range(3):
        eps_b[40 + offset] = "epsilon %03d" % (41 + offset)
    _fx_write(root, "f.txt", eps_b)
    _fx_commit(root, "release/epsilon rev B also edits 41-43")
    _git(root, ["checkout", "-q", "main"])

    # A branch that DELETES the contended file: git exit 0, large diff, zero
    # parseable hunks. This is the shape that defeats a non-empty-EXTRACTION
    # assertion.
    _git(root, ["checkout", "-q", "-b", "release/deleter", "main"])
    _git(root, ["rm", "-q", "f.txt"])
    _fx_commit(root, "release/deleter deletes f.txt")
    _git(root, ["checkout", "-q", "main"])

    # A dependency-bot ref carrying `release/` MID-PATH. It exists, so the
    # prefix guard is the only reason it can be rejected.
    _git(root, ["branch", "dependabot/release/alpha", "release/alpha"])

    # PR members, as local `refs/pull/<N>/head` -- the same spelling the live
    # arm resolves after fetching from the remote.
    _git(root, ["update-ref", "refs/pull/42/head", "release/alpha"])
    _git(root, ["update-ref", "refs/pull/43/head", "release/beta"])
    return root


def _ranges_for(root: str, base: str, rev: str, path: str = "f.txt",
                context_flag=None, anchor=None) -> tuple[int, list]:
    """(extracted bytes, parsed ranges) -- both observables, recorded separately.

    `context_flag` / `anchor` default to the SENTINEL `None`, never to
    `CONTEXT_FLAG` / `ANCHOR_MERGE_BASE`. Re-declaring the production defaults
    here would make this helper test its own pin instead of the tool's:
    mutation testing flipped `extract_patch`'s anchor default to two-dot and
    the suite still passed, because this helper was overriding it back on
    every call. Omitting an argument here means "whatever the tool does".
    """
    sha = resolve_rev(root, [rev])
    overrides = {}
    if context_flag is not None:
        overrides["context_flag"] = context_flag
    if anchor is not None:
        overrides["anchor"] = anchor
    patch = extract_patch(root, base, sha, rev, path, **overrides)
    return len(patch), parse_hunk_ranges(patch)


def run_self_test() -> int:
    """Algorithm regression + hermetic git fixture + control-mutation arms.

    Group A  algorithm regression (unchanged from the original suite)
    Group B  branch-arm classification, end-to-end through main()
    Group C  cross-arm parity: one PR member and one branch member, one engine
    Group D  failure semantics: unresolvable ref, and the zero-hunk diff
    Group E  CIAC-6 -- every control repaired here is shown FAILING on a
             fixture with its observing step removed and PASSING on the
             conformant control, both arms with non-empty extraction recorded

    No network calls. All git operations run against a temp repo built here.
    E10 is the one arm that runs `git fetch`, and its remote is a bare repo
    inside that same temp tree -- git's LOCAL transport, no network. The arm
    asserts the remote URL is inside the fixture rather than trusting it.
    """
    failures: list[str] = []
    notes: list[str] = []

    def check(condition: bool, label: str) -> None:
        if not condition:
            failures.append(label)

    # ---------------- Group A: algorithm regression ----------------
    if parse_hunk_ranges("") != []:
        failures.append("A1 parse_hunk_ranges('') should be []")
    if parse_hunk_ranges("@@ -1,3 +10,5 @@\n+x\n+y\n+z") != [(10, 14)]:
        failures.append("A2 parse_hunk_ranges multi-line failed")
    if parse_hunk_ranges("@@ -1 +5 @@\n+x") != [(5, 5)]:
        failures.append("A3 parse_hunk_ranges single-line (no length) failed")
    multi = "@@ -1,2 +10,3 @@\n+a\n+b\n@@ -20,1 +50,5 @@\n+c"
    if parse_hunk_ranges(multi) != [(10, 12), (50, 54)]:
        failures.append("A4 parse_hunk_ranges multi-hunk failed")

    if not hunks_overlap((1, 5), (5, 10)):
        failures.append("A5 hunks_overlap closed-interval at boundary failed")
    if hunks_overlap((1, 4), (5, 10)):
        failures.append("A6 hunks_overlap disjoint should be False")
    if not hunks_overlap((1, 100), (50, 60)):
        failures.append("A7 hunks_overlap containment failed")

    if classify_overlap_class({"101": [(1, 10)]}) != "single-pr":
        failures.append("A8 classify single-pr failed")
    if classify_overlap_class({
        "101": [(1, 10)],
        "102": [(20, 30)],
        "103": [(40, 50)],
    }) != "append-pattern":
        failures.append("A9 classify append-pattern (3 disjoint) failed")
    if classify_overlap_class({
        "101": [(1, 10)],
        "102": [(5, 15)],
    }) != "line-range-overlap":
        failures.append("A10 classify line-range-overlap (pair) failed")
    if classify_overlap_class({
        "101": [(1, 10), (50, 60)],
        "102": [(20, 30)],
        "103": [(40, 55)],  # overlaps 101's second hunk (50-60 vs 40-55)
    }) != "line-range-overlap":
        failures.append("A11 classify line-range-overlap (multi-hunk) failed")

    tmp = tempfile.mkdtemp(prefix="clro-selftest-")
    saved_env = {k: os.environ.get(k) for k in _FIXTURE_ENV_KEYS}
    try:
        for key, value in _fixture_env(tmp).items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

        root = _build_fixture(tmp)

        # The fixture must resolve against the TEMP root, never the outer repo.
        # A shallow / single-branch CI checkout has silently degraded a sibling
        # self-test to "N/A (never FAIL)" before; this asserts it did not here.
        toplevel = _git(root, ["rev-parse", "--show-toplevel"]).stdout.strip()
        check(
            os.path.realpath(toplevel) == os.path.realpath(root),
            "B0 fixture git operations did not resolve against the temp root "
            "(got %r, want %r)" % (toplevel, root),
        )

        base = "main"

        # ---------------- Group B: branch arm, end-to-end ----------------
        # Every arm asserts the CONJUNCTION -- expected class AND >=1 parsed
        # range per member. An arm that passes on an empty parse is a broken
        # probe, which is the exact defect this card closes.
        expected = {
            "release/alpha": [(37, 45)],
            "release/beta": [(38, 46)],
            "release/gamma": [(87, 95)],
            "release/delta": [(47, 54)],
        }
        for ref, want in expected.items():
            nbytes, got = _ranges_for(root, base, ref)
            check(nbytes > 0, "B-extract %s produced an EMPTY extraction" % ref)
            check(got == want,
                  "B-extract %s ranges %r != %r (is -U3 pinned?)" % (ref, got, want))
            notes.append("  extract %-22s bytes=%-5d ranges=%r" % (ref, nbytes, got))

        b_arms = [
            ("B1 MUST-FLAG      alpha x beta ", "release/alpha,release/beta",
             "line-range-overlap", 2),
            ("B2 MUST-NOT-FLAG  alpha x gamma", "release/alpha,release/gamma",
             "append-pattern", 2),
            ("B3 NEAR-MISS      alpha x delta", "release/alpha,release/delta",
             "append-pattern", 2),
            ("B4 SINGLE         alpha alone  ", "release/alpha",
             "single-pr", 1),
        ]
        for label, branch_list, want_class, want_members in b_arms:
            rc, out, _err = _run_main([
                "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
                "--branch-list", branch_list, "--files", "f.txt",
                "--output-format", "json",
            ])
            payload = json.loads(out) if out.strip() else {}
            entry = payload.get("files", {}).get("f.txt", {})
            ranges = entry.get("line_ranges", {})
            nonempty = [m for m, r in ranges.items() if r]
            check(rc == 0, "%s exit %d != 0" % (label, rc))
            check(entry.get("overlap_class") == want_class,
                  "%s class %r != %r" % (label, entry.get("overlap_class"), want_class))
            check(len(nonempty) == want_members,
                  "%s only %d/%d members parsed >=1 range -- VACUOUS ARM"
                  % (label, len(nonempty), want_members))
            check(all(m.startswith("branch:") for m in ranges),
                  "%s member token lost its branch: prefix" % label)
            notes.append("  %s -> %-18s members_with_ranges=%d exit=%d"
                         % (label, entry.get("overlap_class"), len(nonempty), rc))

        # ---------------- Group C: cross-arm parity, one engine ----------------
        # `refs/pull/42/head` and `release/alpha` are the SAME head reached by
        # two member spellings. Under one extraction engine their line_ranges
        # are identical by construction; this arm proves the construction holds
        # end-to-end and that only the member token differs.
        rc_pr, out_pr, _ = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--pr-list", "42", "--files", "f.txt", "--output-format", "json",
        ])
        rc_br, out_br, _ = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--branch-list", "release/alpha", "--files", "f.txt",
            "--output-format", "json",
        ])
        pr_entry = json.loads(out_pr)["files"]["f.txt"]
        br_entry = json.loads(out_br)["files"]["f.txt"]
        pr_ranges = list(pr_entry["line_ranges"].values())
        br_ranges = list(br_entry["line_ranges"].values())
        check(rc_pr == 0 and rc_br == 0, "C1 parity arms did not both exit 0")
        check(pr_ranges == br_ranges and pr_ranges and pr_ranges[0],
              "C1 PR arm ranges %r != branch arm ranges %r (or empty)"
              % (pr_ranges, br_ranges))
        check(pr_entry["overlap_class"] == br_entry["overlap_class"],
              "C1 verdict vocabulary differs across arms")
        check(list(pr_entry["line_ranges"].keys()) == ["42"],
              "C2 PR member token is not the bare integer")
        check(list(br_entry["line_ranges"].keys()) == ["branch:release/alpha"],
              "C2 branch member token is not branch:<ref>")
        notes.append("  C1 parity PR#42 vs branch:release/alpha -> ranges %r == %r"
                     % (pr_ranges, br_ranges))

        # TSV shape is unchanged: 4 tab-separated columns, same header.
        rc_tsv, out_tsv, _ = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--pr-list", "42,43", "--files", "f.txt",
        ])
        tsv_lines = [ln for ln in out_tsv.splitlines() if ln.strip()]
        check(rc_tsv == 0 and tsv_lines[0] == "file_path\tpr_number\tline_ranges\toverlap_class",
              "C3 TSV header changed")
        check(len(tsv_lines) == 3 and all(len(ln.split("\t")) == 4 for ln in tsv_lines),
              "C3 TSV row shape changed (%d lines)" % len(tsv_lines))
        check(tsv_lines[1].split("\t")[1] == "42" and tsv_lines[2].split("\t")[1] == "43",
              "C3 PR member column is no longer a bare integer")
        check(tsv_lines[1].split("\t")[3] == "line-range-overlap",
              "C3 PR-arm verdict changed")

        # Mixed population: PR member + branch member in one run. This is the
        # shape that raises TypeError under int keys.
        rc_mix, out_mix, _ = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--pr-list", "43", "--branch-list", "release/alpha",
            "--files", "f.txt", "--output-format", "json",
        ])
        mix_entry = json.loads(out_mix)["files"]["f.txt"]
        check(rc_mix == 0 and mix_entry["overlap_class"] == "line-range-overlap",
              "C4 mixed PR+branch population did not classify")
        check(sorted(mix_entry["line_ranges"]) == ["43", "branch:release/alpha"],
              "C4 mixed member tokens wrong: %r" % sorted(mix_entry["line_ranges"]))
        check(all(mix_entry["line_ranges"].values()),
              "C4 a mixed-population member parsed zero ranges -- VACUOUS ARM")

        # ---------------- Group D: failure semantics ----------------
        rc_d1, out_d1, err_d1 = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--branch-list", "release/does-not-exist", "--files", "f.txt",
            "--output-format", "json",
        ])
        d1 = json.loads(out_d1)
        check(rc_d1 == 2, "D1 unresolvable ref exited %d, want 2" % rc_d1)
        check(d1["files"]["f.txt"]["overlap_class"] is None,
              "D1 unresolvable ref still produced a verdict")
        check(d1.get("partial") is True and d1.get("unresolved"),
              "D1 JSON envelope lost partial/unresolved")
        check("EXTRACTION-FAILED" in err_d1 and "PARTIAL:" in err_d1,
              "D1 stderr did not name the failure")

        # The zero-hunk channel: non-empty EXTRACTION, zero parsed ranges.
        del_bytes, del_ranges = _ranges_for(root, base, "release/deleter")
        check(del_bytes > 0 and del_ranges == [],
              "D2 deleter fixture is not the zero-hunk shape "
              "(bytes=%d ranges=%r)" % (del_bytes, del_ranges))
        notes.append("  D2 deleter extraction bytes=%d parsed_ranges=%d "
                     "<- bytes and ranges are DIFFERENT observables"
                     % (del_bytes, len(del_ranges)))
        rc_d3, out_d3, err_d3 = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--branch-list", "release/deleter,release/alpha", "--files", "f.txt",
            "--output-format", "json",
        ])
        d3 = json.loads(out_d3)
        check(rc_d3 == 2, "D3 deleter+editor exited %d, want 2" % rc_d3)
        check(d3["files"]["f.txt"]["overlap_class"] is None,
              "D3 deleter+editor classified %r -- a delete is not an absence"
              % d3["files"]["f.txt"]["overlap_class"])
        check("no parseable hunk header" in err_d3,
              "D3 stderr did not name the unrepresentable state")

        # ---------------- Group E: CIAC-6 control-mutation arms ----------------
        # Each arm removes ONE control's observing step and requires the
        # fixture to FAIL, then restores it and requires a PASS. Extraction
        # bytes are recorded on BOTH arms.

        # E1 -- transport guard (ExtractionError vs the shipped `return ""`).
        # Anti-vacuity: the SAME extract_patch call on a good rev must return
        # non-empty bytes, so the defective arm's zero bytes is a property of
        # the transport failure and not of a harness that extracts nothing.
        e1_sens_bytes = len(extract_patch(
            root, base, resolve_rev(root, ["release/alpha"]),
            "branch:release/alpha", "f.txt",
        ))
        bogus = "0000000000000000000000000000000000000001"
        e1_conformant_raised = False
        try:
            extract_patch(root, base, bogus, "branch:release/bogus", "f.txt")
        except ExtractionError:
            e1_conformant_raised = True
        e1_defect = _git(root, build_diff_argv(
            base, bogus, "f.txt", CONTEXT_FLAG, ANCHOR_MERGE_BASE,
        ))
        e1_defect_out = e1_defect.stdout if e1_defect.returncode == 0 else ""
        check(e1_sens_bytes > 0,
              "E1 sensitivity control extracted 0 bytes -- the arm is vacuous")
        check(e1_conformant_raised, "E1 CONFORMANT: transport guard did not raise")
        check(e1_defect.returncode != 0 and parse_hunk_ranges(e1_defect_out) == [],
              "E1 DEFECTIVE arm did not reproduce the silent-empty return")
        notes.append("  E1 transport guard   conformant=RAISED "
                     "(same call on a good rev: bytes=%d) | defective=rc%d "
                     "bytes=%d ranges=0 -> silent benign"
                     % (e1_sens_bytes, e1_defect.returncode, len(e1_defect_out)))

        # E2 -- parse-boundary guard. The defective variant is the SHIPPED
        # rule: "ranges -> present, else absent".
        del_sha = resolve_rev(root, ["release/deleter"])
        del_patch = extract_patch(root, base, del_sha, "branch:release/deleter", "f.txt")
        conformant_state, _ = classify_extraction(del_patch)
        defective_state = (
            EXTRACT_PRESENT if parse_hunk_ranges(del_patch) else EXTRACT_ABSENT
        )
        alpha_sha = resolve_rev(root, ["release/alpha"])
        alpha_patch = extract_patch(root, base, alpha_sha, "branch:release/alpha", "f.txt")
        defective_map = {"branch:release/alpha": parse_hunk_ranges(alpha_patch)}
        check(conformant_state == EXTRACT_UNREPRESENTABLE,
              "E2 CONFORMANT: a zero-hunk 8k diff was not marked unrepresentable")
        check(defective_state == EXTRACT_ABSENT
              and classify_overlap_class(defective_map) == "single-pr",
              "E2 DEFECTIVE arm did not reproduce the single-pr fail-open")
        check(len(del_patch) > 0 and len(alpha_patch) > 0,
              "E2 an arm ran on an EMPTY extraction")
        notes.append("  E2 parse guard       conformant=%s(bytes=%d) "
                     "defective=%s -> single-pr"
                     % (conformant_state, len(del_patch), defective_state))

        # E3 -- the -U3 pin, under a hostile repo-local diff.context.
        _git(root, ["config", "diff.context", "7"])
        try:
            pin_bytes, pinned = _ranges_for(root, base, "release/alpha")
            unpin_bytes, unpinned = _ranges_for(
                root, base, "release/alpha", context_flag="",
            )
            d_pin_bytes, d_pinned = _ranges_for(root, base, "release/delta")
            d_unpin_bytes, d_unpinned = _ranges_for(
                root, base, "release/delta", context_flag="",
            )
        finally:
            _git(root, ["config", "--unset", "diff.context"])
        conformant_class = classify_overlap_class({
            "branch:release/alpha": pinned, "branch:release/delta": d_pinned,
        })
        defective_class = classify_overlap_class({
            "branch:release/alpha": unpinned, "branch:release/delta": d_unpinned,
        })
        check(min(pin_bytes, unpin_bytes, d_pin_bytes, d_unpin_bytes) > 0,
              "E3 an arm ran on an EMPTY extraction")
        check(pinned == [(37, 45)] and d_pinned == [(47, 54)],
              "E3 CONFORMANT: -U3 did not hold under diff.context=7 (%r / %r)"
              % (pinned, d_pinned))
        check(conformant_class == "append-pattern",
              "E3 CONFORMANT class %r != append-pattern" % conformant_class)
        check(defective_class == "line-range-overlap",
              "E3 DEFECTIVE arm did not flip the verdict -- the -U3 pin "
              "observes nothing (got %r from %r / %r)"
              % (defective_class, unpinned, d_unpinned))
        notes.append("  E3 -U3 pin           conformant=%r+%r -> %s | "
                     "defective=%r+%r -> %s"
                     % (pinned, d_pinned, conformant_class,
                        unpinned, d_unpinned, defective_class))

        # E5 -- str member-key normalization, over REAL parsed ranges from the
        # fixture (not synthetic tuples), so the arm cannot pass on empty data.
        beta_sha = resolve_rev(root, ["release/beta"])
        beta_patch = extract_patch(root, base, beta_sha, "branch:release/beta", "f.txt")
        e5_alpha = parse_hunk_ranges(alpha_patch)
        e5_beta = parse_hunk_ranges(beta_patch)
        check(bool(e5_alpha) and bool(e5_beta) and len(alpha_patch) > 0
              and len(beta_patch) > 0,
              "E5 arms ran on an empty extraction or an empty parse")
        e5_conformant = classify_overlap_class({
            "43": e5_beta, "branch:release/alpha": e5_alpha,
        })
        e5_raised = False
        try:
            classify_overlap_class({43: e5_beta, "branch:release/alpha": e5_alpha})
        except TypeError:
            e5_raised = True
        check(e5_conformant == "line-range-overlap",
              "E5 CONFORMANT: str-keyed mixed population did not classify")
        check(e5_raised,
              "E5 DEFECTIVE arm did not raise -- int keys are no longer a hazard, "
              "so the normalization observes nothing")
        notes.append("  E5 str member keys   conformant=%s (bytes %d+%d, "
                     "ranges %r+%r)  defective=TypeError"
                     % (e5_conformant, len(alpha_patch), len(beta_patch),
                        e5_alpha, e5_beta))

        # E6 -- monotone partial emission.
        rc_e6, out_e6, _ = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--branch-list", "release/alpha,release/beta,release/does-not-exist",
            "--files", "f.txt", "--output-format", "json",
        ])
        e6 = json.loads(out_e6)
        e6_entry = e6["files"]["f.txt"]
        e6_resolved = {
            m: [tuple(r) for r in ranges]
            for m, ranges in e6_entry["line_ranges"].items() if ranges
        }
        # DEFECTIVE arm, computed from the same emitted data: the
        # omit-on-ANY-unresolved rule discards the verdict outright.
        e6_subset_verdict = classify_overlap_class(e6_resolved)
        defective_e6 = None if e6.get("unresolved") else e6_subset_verdict
        check(rc_e6 == 2, "E6 partial run exited %d, want 2" % rc_e6)
        check(e6_entry["overlap_class"] == "line-range-overlap",
              "E6 CONFORMANT: a monotone alarm was suppressed by a partial "
              "member set (got %r)" % e6_entry["overlap_class"])
        check(e6.get("partial") is True, "E6 partial marker absent")
        check(len(e6_resolved) == 2,
              "E6 only %d resolved members parsed ranges -- VACUOUS ARM"
              % len(e6_resolved))
        check(e6_subset_verdict == "line-range-overlap",
              "E6 the resolved subset does not carry the alarm the arm claims "
              "is being preserved (got %r) -- VACUOUS ARM" % e6_subset_verdict)
        check(defective_e6 is None,
              "E6 DEFECTIVE arm did not suppress the alarm (got %r)" % defective_e6)
        notes.append("  E6 monotone partial  conformant=%s(partial, resolved "
                     "subset carries %s) defective=%r"
                     % (e6_entry["overlap_class"], e6_subset_verdict, defective_e6))

        # E7 -- duplicate-head coalescing. PR 42 and release/alpha are one head.
        rc_e7, out_e7, err_e7 = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--pr-list", "42", "--branch-list", "release/alpha",
            "--files", "f.txt", "--output-format", "json",
        ])
        e7_entry = json.loads(out_e7)["files"]["f.txt"]
        e7_ranges = parse_hunk_ranges(alpha_patch)
        defective_e7 = classify_overlap_class({
            "42": e7_ranges, "branch:release/alpha": e7_ranges,
        })
        check(rc_e7 == 0 and e7_entry["overlap_class"] == "single-pr",
              "E7 CONFORMANT: two spellings of one head were not coalesced "
              "(got %r)" % e7_entry["overlap_class"])
        check("DUPLICATE-MEMBER" in err_e7, "E7 coalescing was silent")
        check(defective_e7 == "line-range-overlap",
              "E7 DEFECTIVE arm did not manufacture the self-overlap")
        check(bool(e7_ranges), "E7 arms ran on an empty parse")
        notes.append("  E7 dup coalescing    conformant=%s  defective=%s"
                     % (e7_entry["overlap_class"], defective_e7))

        # E8 -- the release/ PREFIX guard. `dependabot/release/alpha` EXISTS in
        # the fixture, so rejection can only come from the guard.
        dep_ref = "dependabot/release/alpha"
        check(resolve_rev(root, [dep_ref]) != "",
              "E8 fixture ref %s is missing -- the arm would pass vacuously" % dep_ref)
        rc_e8, _out_e8, err_e8 = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--branch-list", dep_ref, "--files", "f.txt",
        ])
        defective_e8 = RELEASE_PREFIX in dep_ref  # the substring rule
        check(rc_e8 == 1 and not is_release_branch_ref(dep_ref) and "PREFIX" in err_e8,
              "E8 CONFORMANT: prefix guard admitted %s" % dep_ref)
        check(defective_e8 is True,
              "E8 DEFECTIVE arm did not admit %s -- the guard observes nothing"
              % dep_ref)
        notes.append("  E8 prefix guard      conformant=REJECTED(exit %d) "
                     "defective=ADMITTED" % rc_e8)

        # E9 -- the empty-map classifier guard.
        e9_raised = False
        try:
            classify_overlap_class({})
        except ValueError:
            e9_raised = True
        check(e9_raised,
              "E9 CONFORMANT: an empty member map still returns a verdict")
        notes.append("  E9 empty-map guard   conformant=ValueError  "
                     "defective=append-pattern (benign verdict from no data)")

        # E10 -- the PR-refresh guard: a local `refs/pull/<N>/head` that is
        # PRESENT but STALE. The pre-fix resolver gated its bounded fetch on
        # `not sha`, so a ref that was merely BEHIND its upstream was never
        # refreshed and the tool classified an OLD revision at exit 0 -- no
        # error, no PARTIAL marker. That defect shipped and was found only by
        # measuring live PRs, because this fixture builds its refs with
        # `update-ref` and they are therefore FRESH BY CONSTRUCTION: the suite
        # could not express the failing state at all. This arm constructs it.
        #
        # Hermetic, per the suite's no-network contract: the "remote" is a bare
        # repo inside the fixture tmp, so `git fetch` uses the LOCAL transport.
        # The arm asserts that below rather than trusting it.
        remote_root = os.path.join(tmp, "remote")
        check(_git(root, ["init", "-q", "--bare", remote_root]).returncode == 0,
              "E10 fixture bare remote did not initialise")
        check(_git(root, [
            "push", "-q", remote_root,
            "+refs/heads/release/epsilon:refs/heads/release/epsilon",
        ]).returncode == 0, "E10 fixture push to the local remote failed")
        _git(remote_root, [
            "update-ref", "refs/pull/44/head", "refs/heads/release/epsilon",
        ])
        _git(root, ["remote", "add", "origin", remote_root])
        e10_url = _git(root, ["remote", "get-url", "origin"]).stdout.strip()
        check(bool(e10_url) and os.path.realpath(e10_url).startswith(
                  os.path.realpath(tmp) + os.sep),
              "E10 fixture remote %r is not inside the fixture tmp -- this arm "
              "would be a network call wearing a fixture's clothes" % e10_url)

        sha_b = resolve_rev(root, ["release/epsilon"])      # the LIVE head
        sha_a = resolve_rev(root, ["release/epsilon~1"])    # the older revision
        check(bool(sha_a) and bool(sha_b) and sha_a != sha_b,
              "E10 fixture revisions A/B are not two distinct commits")
        check(resolve_rev(remote_root, ["refs/pull/44/head"]) == sha_b,
              "E10 the remote's PR head is not revision B")

        e10_a_bytes, e10_a_ranges = _ranges_for(root, base, "release/epsilon~1")
        e10_b_bytes, e10_b_ranges = _ranges_for(root, base, "release/epsilon")
        e10_alpha_ranges = _ranges_for(root, base, "release/alpha")[1]
        check(min(e10_a_bytes, e10_b_bytes) > 0
              and bool(e10_a_ranges) and bool(e10_b_ranges),
              "E10 an arm ran on an EMPTY extraction")
        check(e10_a_ranges == [(57, 65)]
              and e10_b_ranges == [(38, 46), (57, 65)],
              "E10 fixture revisions do not carry the DISCRIMINATING ranges "
              "(A=%r B=%r) -- the arm could not tell them apart"
              % (e10_a_ranges, e10_b_ranges))

        # DEFECTIVE arm runs FIRST: it must observe the ref while still stale,
        # and it must not refresh it. `allow_fetch=False` is not an
        # approximation of the pre-fix gate, it is EQUIVALENT on this input: for
        # a ref that is PRESENT, `if not sha and kind == "pr" and allow_fetch:`
        # and `allow_fetch=False` skip the same fetch and resolve the same ref.
        _git(root, ["update-ref", "refs/pull/44/head", sha_a])
        check(resolve_rev(root, ["refs/pull/44/head"]) == sha_a,
              "E10 the local PR ref was not seeded STALE -- the arm is vacuous")
        _e10_dtok, e10_defect_sha = resolve_member(
            root, "pr", "44", allow_fetch=False,
        )
        check(e10_defect_sha == sha_a,
              "E10 DEFECTIVE arm did not read the stale revision -- an "
              "unrefreshed ref is no longer a hazard, so the fetch observes "
              "nothing")

        # CONFORMANT arm: the shipped resolver, from the same stale state.
        _e10_ctok, e10_fresh_sha = resolve_member(root, "pr", "44")
        check(e10_fresh_sha == sha_b,
              "E10 CONFORMANT: a PRESENT-but-STALE refs/pull/44/head resolved to "
              "%s, want the refreshed head %s -- the PR fetch is gated on ref "
              "ABSENCE again" % (e10_fresh_sha[:8], sha_b[:8]))

        # End-to-end through main(), re-seeded stale, and the reason this
        # matters: the stale read is not a cosmetic number, it FLIPS the verdict.
        _git(root, ["update-ref", "refs/pull/44/head", sha_a])
        rc_e10, out_e10, _err_e10 = _run_main([
            "--baseline-sha", "fixture", "--root", root, "--base-ref", base,
            "--pr-list", "44", "--branch-list", "release/alpha",
            "--files", "f.txt", "--output-format", "json",
        ])
        e10_entry = json.loads(out_e10)["files"]["f.txt"]
        e10_emitted = [tuple(r) for r in e10_entry["line_ranges"].get("44", [])]
        defective_e10 = classify_overlap_class({
            "44": e10_a_ranges, "branch:release/alpha": e10_alpha_ranges,
        })
        check(rc_e10 == 0 and e10_entry["overlap_class"] == "line-range-overlap",
              "E10 CONFORMANT: the stale-ref run classified %r at exit %d"
              % (e10_entry["overlap_class"], rc_e10))
        check(e10_emitted == e10_b_ranges,
              "E10 CONFORMANT: member 44 was emitted at revision A (%r), not the "
              "refreshed revision B (%r)" % (e10_emitted, e10_b_ranges))
        check(defective_e10 == "append-pattern",
              "E10 DEFECTIVE arm did not downgrade the verdict -- reading the "
              "stale revision costs nothing, so the refresh observes nothing "
              "(got %r)" % defective_e10)
        notes.append("  E10 PR stale-ref     conformant=%s @%s %r(bytes=%d) | "
                     "defective=%s @%s %r(bytes=%d) -> WRONG verdict at exit 0"
                     % (e10_entry["overlap_class"], sha_b[:8], e10_b_ranges,
                        e10_b_bytes, defective_e10, sha_a[:8], e10_a_ranges,
                        e10_a_bytes))

        # E4 -- the merge-base anchor. Advances `main`, so it runs LAST.
        _git(root, ["checkout", "-q", "main"])
        advanced = ["line %03d" % n for n in range(1, 101)]
        for offset in range(3):
            advanced[69 + offset] = "mainadv %03d" % (70 + offset)
        _fx_write(root, "f.txt", advanced)
        _fx_commit(root, "main advances at 70-72 after the branches were cut")
        mb_bytes, mb_ranges = _ranges_for(root, base, "release/alpha")
        td_bytes, td_ranges = _ranges_for(
            root, base, "release/alpha", anchor=ANCHOR_TWO_DOT,
        )
        check(mb_bytes > 0 and td_bytes > 0, "E4 an arm ran on an EMPTY extraction")
        check(mb_ranges == [(37, 45)],
              "E4 CONFORMANT: merge-base anchor drifted to %r" % (mb_ranges,))
        check(len(td_ranges) > len(mb_ranges),
              "E4 DEFECTIVE arm did not pick up main's advance -- the "
              "merge-base anchor observes nothing (two-dot %r)" % (td_ranges,))
        notes.append("  E4 merge-base anchor conformant=%r(bytes=%d) "
                     "defective=two-dot %r(bytes=%d)"
                     % (mb_ranges, mb_bytes, td_ranges, td_bytes))
    except Exception as exc:  # a fixture that cannot build must FAIL, not skip
        failures.append("FIXTURE ERROR: %s: %s" % (type(exc).__name__, exc))
    finally:
        for key, value in saved_env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
        shutil.rmtree(tmp, ignore_errors=True)

    for line in notes:
        print(line)
    if failures:
        print("SELF-TEST FAIL:", file=sys.stderr)
        for item in failures:
            print(f"  - {item}", file=sys.stderr)
        return 3
    print("SELF-TEST PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())

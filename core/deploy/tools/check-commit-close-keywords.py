#!/usr/bin/env python3
"""check-commit-close-keywords.py — the commit-message arm of the close-keyword
parser-clean discipline, invocable.

WHAT IT ASSERTS. No commit message in a range — subject or body — puts a
close-family keyword directly before an issue reference. The repository host's
auto-close parser reads every commit message that reaches the default branch, and a
keyword directly before a reference closes that issue at merge whatever the sentence
around it meant: a possessive, a partitive, a negation, or a colon in the middle of
ordinary prose all close. The rule is stated once, in core/rules/git-workflow.md
(PR Process, step 5); this file is its runner for the commit-message input.

WHERE IT RUNS. The `Commit-message depersonalization gate` job in
.github/workflows/commit-message-depersonalization.yml calls it as a thin caller.
That job is a required status check, so a finding blocks the merge. It is also the
pre-push self-check an author runs locally — the same file, so the local verdict
and the CI verdict cannot drift apart.

THE GRAMMAR FOLLOWS THE HOST'S OWN DOCUMENTATION. One of the nine keywords (close,
closes, closed, fix, fixes, fixed, resolve, resolves, resolved; any case), then
either a colon with optional blanks or one or more blanks, then an issue reference
in any form the host documents: a number written with its hash, the same qualified
by owner/repository, a GH- number, or the issue's URL. The first two are the
host's published closing syntax. The last two are reference forms the host
documents separately; that a keyword before one of them closes is this tool's
reading of the host's phrase "followed by a reference to the issue", not a
published example. They are flagged because the rule this tool serves is
reference-only in every form.

DELIBERATE BOUNDS, STATED SO THEY ARE NOT REDISCOVERED AS DEFECTS.
  * A BARE NUMBER IS NOT A REFERENCE. "resolved 17 tokens" and "the closed 5-bin
    set" pass. Measured when this tool was designed: across every commit message
    then on the default branch, a pattern that accepted a bare number fired on 67
    commits, 46 of them a bare number and none of those a reference.
  * The keyword must stand as a WHOLE WORD: it is not flagged when a letter, a
    digit or an underscore sits directly before it, so "unresolved" before a
    reference passes. A hyphen is a word boundary, so "post-fix" before a
    reference is flagged. The host does not document its left edge; this is the
    reading its published examples support, and it keeps a red result meaning a
    real pairing.
  * Scanning is line by line. A keyword at the end of one line with its reference
    at the start of the next is not flagged.
  * Markdown link syntax is not unwrapped. A keyword directly before
    "[text](target)" is not flagged, whatever the text or the target names.

THE REPORT NEVER ECHOES MESSAGE TEXT. It prints a commit id, a line number, the
keyword and the reference number — nothing else from the message. A repository
qualifier is printed as <qualified> and a URL as <url>, because the sibling step
in the same job treats a private-repository slug as personal data and redacts it.
Printing only those fixed fragments also means no message text can reach the
runner as a workflow command.

INTERFACE
  --base <rev> --head <rev>   scan every commit in <base>..<head>
  --self-test                 fixture arms, plumbing arm, degraded-read arm
  exit 0 = clean · 1 = finding(s) · 3 = the range could not be read (NOT-EVALUATED)
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tempfile

EXIT_CLEAN = 0
EXIT_FINDING = 1
EXIT_CONTEXT = 3

PAIRING_RE = re.compile(
    r"(?<![A-Za-z0-9_])"
    r"(?P<kw>close[sd]?|fix(?:e[sd])?|resolve[sd]?)"
    r"(?P<sep>:[ \t]*|[ \t]+)"
    r"(?:"
    r"(?P<qual>[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?#(?P<num>[0-9]+)"
    r"|GH-(?P<gh>[0-9]+)"
    r"|https?://(?:www\.)?github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/issues/(?P<url>[0-9]+)"
    r")",
    re.IGNORECASE,
)

# A revision name as this tool accepts it: no leading dash (it would read as an
# option) and nothing outside the characters a commit id or ref expression uses.
REV_RE = re.compile(r"[0-9A-Za-z_./~^@{}][0-9A-Za-z_./~^@{}-]*")

FIXTURE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "fixtures", "commit-close-keywords", "cases.txt",
)

REMEDY = (
    "Reword the message so no close-family keyword sits directly before an issue "
    "reference — a trailing reference such as '(#N)', or 'the fix for #N'. If "
    "closing the issue at merge is intended, declare it in the pull request "
    "body's Issue References block, the one sanctioned place, and still reword "
    "the commit. A message that is already pushed changes only by being "
    "rewritten: amend the tip, or rebase an earlier commit, then push with "
    "--force-with-lease and never with --force, and only while the branch has a "
    "single writer. On a shared release branch that push class is excluded whenever "
    "more than one writer is active (the Stage 6 parallelism-posture taxonomy, "
    "ADR-052): stop every other writer's lane first. The rewrite is the "
    "operator's call, because it changes every recorded commit id after it."
)


class RangeUnreadable(Exception):
    """The commit range could not be read; the population is unmeasured."""


def find_pairings(message: str) -> list[tuple[int, str, str]]:
    """Pure predicate. Returns (line number, keyword, reference) per pairing."""
    found = []
    for lineno, line in enumerate(message.split("\n"), 1):
        for match in PAIRING_RE.finditer(line):
            if match.group("gh"):
                ref = "GH-" + match.group("gh")
            elif match.group("url"):
                ref = "<url>#" + match.group("url")
            else:
                ref = ("<qualified>" if match.group("qual") else "") + "#" + match.group("num")
            found.append((lineno, match.group("kw").lower(), ref))
    return found


def _git(args: list[str], cwd: str | None, env: dict | None = None,
         stdin: str | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git"] + args, cwd=cwd, env=env, capture_output=True,
        input=None if stdin is None else stdin.encode("utf-8"),
    )


def read_range(base: str, head: str, cwd: str | None = None,
               env: dict | None = None) -> list[tuple[str, str]]:
    """Every commit in base..head as (sha, message), oldest first."""
    for rev in (base, head):
        if not REV_RE.fullmatch(rev or ""):
            raise RangeUnreadable("an argument is not a revision name")
    spec = f"{base}..{head}"
    log = _git(["log", "--no-show-signature", "--reverse", "--format=%H%x00%B%x01", spec],
               cwd, env)
    count = _git(["rev-list", "--count", spec], cwd, env)
    if log.returncode != 0 or count.returncode != 0:
        detail = (log.stderr or count.stderr).decode("utf-8", "replace").strip()
        raise RangeUnreadable(detail.splitlines()[0] if detail else "git could not read the range")
    commits = []
    for record in log.stdout.decode("utf-8", "replace").split("\x01"):
        record = record.lstrip("\n")
        if record:
            sha, _, message = record.partition("\x00")
            commits.append((sha, message))
    expected = int(count.stdout.decode().strip() or "0")
    if len(commits) != expected:
        raise RangeUnreadable(
            f"population mismatch: parsed {len(commits)} commits, rev-list counts {expected}")
    return commits


def scan(base: str, head: str, cwd: str | None = None,
         env: dict | None = None) -> tuple[int, list[tuple[str, int, str, str]]]:
    """Returns (commits examined, findings as (sha, line, keyword, reference))."""
    commits = read_range(base, head, cwd, env)
    findings = [
        (sha, lineno, keyword, ref)
        for sha, message in commits
        for lineno, keyword, ref in find_pairings(message)
    ]
    return len(commits), findings


def report(base: str, head: str, examined: int,
           findings: list[tuple[str, int, str, str]]) -> None:
    in_actions = os.environ.get("GITHUB_ACTIONS") == "true"
    print(f"close-keyword scan (commit messages): {base}..{head}")
    print("  measurement state: fetched")
    print(f"  commits examined: {examined}")
    print(f"  findings: {len(findings)}")
    for sha, lineno, keyword, ref in findings:
        print(f"    {sha[:12]}  line {lineno}  {keyword} + {ref}")
        if in_actions:
            print(f"::error title=Close-keyword in commit message::{sha[:12]} line {lineno}: "
                  f"'{keyword}' directly before {ref} is a closing reference and can close "
                  "that issue at merge")
    if examined == 0:
        print("  note: the range holds no commits, so nothing was examined")
    print("  verdict: " + ("FINDINGS" if findings else "CLEAN"))
    if findings:
        print("  remedy: " + REMEDY)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary:
        return
    lines = []
    if findings:
        lines += [
            "## :x: Commit-message close-keyword scan FAILED",
            "",
            "This is the commit-message arm of the close-keyword parser-clean discipline "
            "(`core/rules/git-workflow.md`, PR Process step 5). It runs inside the job "
            "`Commit-message depersonalization gate` because that job is the registered "
            "required check; the depersonalization scan reports separately, in the step "
            "before this one.",
            "",
            f"{len(findings)} pairing(s) across {examined} commit(s) examined. Message text "
            "is never echoed here.",
            "",
            "| Commit | Line | Keyword | Reference |",
            "|---|---|---|---|",
        ]
        lines += [f"| `{sha[:12]}` | {lineno} | {keyword} | {ref} |"
                  for sha, lineno, keyword, ref in findings]
        lines += ["", "### Remedy", "", REMEDY, ""]
    else:
        lines += [f":white_check_mark: Commit-message close-keyword scan — 0 findings "
                  f"over {examined} commit(s)", ""]
    with open(summary, "a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def not_evaluated(cause: str) -> int:
    print("close-keyword scan (commit messages)")
    print("  measurement state: degraded")
    print(f"  NOT-EVALUATED — this is not a clean result: {cause}")
    if os.environ.get("GITHUB_ACTIONS") == "true":
        print("::error title=Close-keyword scan not evaluated::the commit range could not "
              "be read, so no verdict was produced")
    return EXIT_CONTEXT


def load_fixture() -> list[tuple[str, str, str]]:
    cases = []
    with open(FIXTURE, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            case_id, expect, message = line.split(None, 2)
            message = message.replace("\\n", "\n").replace("\\t", "\t")
            cases.append((case_id, expect, message))
    return cases


def self_test() -> int:
    failures = []

    # Arm 1 — the committed fixture: every must-flag case fires, every near miss is silent.
    cases = load_fixture()
    must_flag = [c for c in cases if c[1] == "FLAG"]
    must_pass = [c for c in cases if c[1] == "PASS"]
    if not must_flag or not must_pass or len(must_flag) + len(must_pass) != len(cases):
        failures.append("fixture: needs at least one FLAG and one PASS case, and no other label")
    fired = [c[0] for c in must_flag if find_pairings(c[2])]
    leaked = [c[0] for c in must_pass if find_pairings(c[2])]
    for case_id in sorted(set(c[0] for c in must_flag) - set(fired)):
        failures.append(f"fixture: must-flag case {case_id} did not fire")
    for case_id in leaked:
        failures.append(f"fixture: must-not-flag case {case_id} fired")
    print(f"self-test: fixture arms — {len(fired)}/{len(must_flag)} must-flag fired, "
          f"{len(must_pass) - len(leaked)}/{len(must_pass)} must-not-flag silent")

    # Arm 2 — plumbing: a throwaway repository, so subject, body and the range
    # denominator are read through the same code path a real scan uses. The
    # references are synthetic and sit far above any real issue number.
    #
    # Every inherited GIT_* variable is dropped first. Run from inside a hook or a
    # rebase, this process inherits GIT_DIR and its siblings, and with those set the
    # "throwaway" commits below would be written to the caller's real repository.
    env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    env.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_SYSTEM=os.devnull,
               GIT_AUTHOR_NAME="selftest", GIT_AUTHOR_EMAIL="selftest@example.invalid",
               GIT_COMMITTER_NAME="selftest", GIT_COMMITTER_EMAIL="selftest@example.invalid")
    with tempfile.TemporaryDirectory() as repo:
        def commit(message: str) -> str:
            done = _git(["-c", "commit.gpgsign=false", "-c", "core.hooksPath=" + os.devnull,
                         "commit", "-q", "--allow-empty", "-F", "-"], repo, env, message)
            if done.returncode != 0:
                raise RangeUnreadable(done.stderr.decode("utf-8", "replace").strip())
            return _git(["rev-parse", "HEAD"], repo, env).stdout.decode().strip()

        try:
            if _git(["-c", "init.defaultBranch=selftest", "init", "-q"], repo, env).returncode != 0:
                raise RangeUnreadable("git init failed")
            if not os.path.isdir(os.path.join(repo, ".git")):
                # Stop before any commit: the repository is not where it was asked for.
                raise RangeUnreadable("the throwaway repository was not created in its own directory")
            base = commit("base")
            in_body = commit("feat: clean subject (#900101)\n\nfirst body line\n"
                             "also closes #900001's partial criterion")
            in_subject = commit("fix: #900002 rows mis-parsed")
            commit("fix(scope): near miss (#900103)\n\nresolved 17 tokens; mark #900104 as closed")
            examined, findings = scan(base, "HEAD", repo, env)
            got = sorted((sha, lineno) for sha, lineno, _, _ in findings)
            want = sorted([(in_body, 4), (in_subject, 1)])
            if examined != 3 or got != want:
                failures.append(f"plumbing: examined {examined} (want 3), findings {len(got)} (want 2 "
                                "— one in a body at line 4, one in a subject at line 1)")
            print(f"self-test: plumbing arm — {examined} commits examined, {len(got)} flagged "
                  "(a body line and a subject line), near miss silent")

            # Arm 3 — a refused read yields neither verdict.
            try:
                scan("0" * 40, "HEAD", repo, env)
                failures.append("degraded: an unreadable range returned a verdict")
            except RangeUnreadable:
                print("self-test: degraded arm — unreadable range -> NOT-EVALUATED, no verdict")
        except RangeUnreadable as error:
            failures.append(f"plumbing: the throwaway repository could not be built ({error})")

    for failure in failures:
        print("self-test FAIL: " + failure)
    print("self-test: " + ("FAIL" if failures else "PASS") + " (measurement state: fixture)")
    return EXIT_FINDING if failures else EXIT_CLEAN


class _Parser(argparse.ArgumentParser):
    """Usage errors leave through the same three-value exit contract as everything else."""

    def error(self, message: str):  # noqa: D401 - argparse hook
        self.print_usage(sys.stderr)
        sys.stderr.write(f"NOT-EVALUATED — this is not a clean result: {message}\n")
        sys.exit(EXIT_CONTEXT)


def main() -> int:
    parser = _Parser(
        description="Flag commit messages that pair a close-family keyword with an issue reference.")
    parser.add_argument("--base", help="exclusive lower bound of the range")
    parser.add_argument("--head", help="inclusive upper bound of the range")
    parser.add_argument("--self-test", action="store_true", help="run the built-in arms and exit")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if not args.base or not args.head:
        parser.error("--base and --head are both required (or pass --self-test)")
    try:
        examined, findings = scan(args.base, args.head)
    except RangeUnreadable as error:
        return not_evaluated(str(error))
    report(args.base, args.head, examined, findings)
    return EXIT_FINDING if findings else EXIT_CLEAN


if __name__ == "__main__":
    sys.exit(main())

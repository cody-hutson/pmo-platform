#!/usr/bin/env python3
"""check-dark-branch.py - classify pull requests the host can no longer merge.

A pull request is DARK when the host reports it cannot be merged into its base:
`mergeable` is CONFLICTING or the merge state is DIRTY. The host then dispatches none
of the gates triggered on `pull_request`, so a head pushed in that state carries only
the few checks triggered another way, every one of them passing. A reading that looks
at conclusions alone reports that roster green.

Three subcommands share one vocabulary. None touches the network or a host CLI: the
caller performs every host read and passes files, and this tool decides whether what
it was handed is a measurement.

  sweep   After a push to a base branch, classify every open pull request on that
          base. `newly-dark` means: the host reports a conflict now, and the same head
          merged cleanly into the base tip as it stood before the push. Run by
          .github/workflows/sibling-merge-dark-branch.yml on every push to the default
          branch, and by the merging release at Stage 12 Phase B1.1.
  record  Print the roster record a stage leaves after a settled read of a mergeable
          head: the head, the base tip, the counts and every row name. Stage 7 Phase A
          writes it into its sub-task output. The record is INFORMATIONAL.
  read    One pull request: mergeability first, then whether its roster carries any
          row triggered on `pull_request`, then - informational only - the comparison
          with a record. Prints the one-line `Dark-branch read:` verdict.

The verdict-bearing input is the HOST's mergeability. `git merge-tree` attributes a
conflict to a push, and cross-checks a host answer that may predate the push; it
never makes a pull request dark on its own. A host answer of "mergeable" counts toward
a green verdict only once that cross-check has run: where the local merge cannot be
computed - a head that could not be fetched, a git failure - the pull request is
`clear-unchecked`, and the sweep is NOT-EVALUATED, never green. No verdict is ever
computed from a record.

Exit codes, every subcommand:
  0  measured; nothing to report      (sweep: no pull request newly dark; read: CLEAR;
                                       record: recorded)
  1  measured; a finding              (sweep: newly dark, or dark in a census;
                                       read: DARK or SHORTFALL)
  2  the instrument cannot assert     (unusable input, or a self-test arm failed)
  3  NOT-EVALUATED - this is not a clean result
"""
import argparse
import collections
import contextlib
import functools
import hashlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile

SHA_RE = re.compile(r"^[0-9a-f]{40}$")
ZERO_SHA = "0" * 40
MEASURING = ("fetched", "fixture")           # the two statuses that carry counters
STATUSES = ("fetched", "truncated", "degraded", "not-run", "fixture")
NOT_CLEAN = "NOT-EVALUATED - this is not a clean result"
RECORD_HEADER = "dark-branch roster record v1"
ARMS_DEFINED = 62                            # the self-test fails if fewer arms ran
# Used only when `git rev-parse --local-env-vars` cannot be read. The live list is
# preferred because it is git-version-dependent; this is what git 2.54 prints.
_FALLBACK_LOCAL_ENV_VARS = (
    "GIT_ALTERNATE_OBJECT_DIRECTORIES", "GIT_CONFIG", "GIT_CONFIG_PARAMETERS",
    "GIT_CONFIG_COUNT", "GIT_OBJECT_DIRECTORY", "GIT_DIR", "GIT_WORK_TREE",
    "GIT_IMPLICIT_WORK_TREE", "GIT_GRAFT_FILE", "GIT_INDEX_FILE",
    "GIT_NO_REPLACE_OBJECTS", "GIT_REPLACE_REF_BASE", "GIT_PREFIX",
    "GIT_SHALLOW_FILE", "GIT_COMMON_DIR",
)


def sanitize(text, limit=80):
    """A host-supplied string, made safe to print: no control characters, no backtick,
    no pipe, and never able to open a line with a workflow command."""
    out = "".join(c if c.isalnum() or c in "-_./@#+ " else "?" for c in str(text))
    return out[:limit]


def sanitize_name(text, limit=120):
    """A check-row name: the punctuation job names really carry, and nothing else."""
    out = "".join(c if c.isalnum() or c in "-_./@#+ ()[],:=&'" else "?" for c in str(text))
    return out.strip()[:limit] or "?"


@functools.lru_cache(maxsize=1)
def local_env_vars():
    """The repository-location variables git itself declares. Any of them inherited
    from a caller - a hook, `git rebase --exec`, `git bisect run`, a session that
    exported one for another worktree - redirects `git -C <dir>` to the caller's
    repository, because `-C` does not override them."""
    clean = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    try:
        done = subprocess.run(["git", "rev-parse", "--local-env-vars"], capture_output=True,
                              text=True, env=clean, cwd=tempfile.gettempdir(), timeout=30)
        names = tuple(n.strip() for n in done.stdout.splitlines() if n.strip())
        if done.returncode == 0 and names:
            return names
    except (OSError, subprocess.SubprocessError):
        pass
    return _FALLBACK_LOCAL_ENV_VARS


def git_env(extra=None):
    """The caller's environment minus every variable `local_env_vars()` names."""
    drop = set(local_env_vars())
    env = {k: v for k, v in os.environ.items() if k not in drop}
    if extra:
        env.update(extra)
    return env


def is_dark(pull):
    return pull.get("mergeable") == "CONFLICTING" or pull.get("mergeStateStatus") == "DIRTY"


def is_clear(pull):
    return pull.get("mergeable") == "MERGEABLE" and pull.get("mergeStateStatus") != "DIRTY"


def conflicted_paths(repo, base, head):
    """Paths that conflict when `head` is merged into `base`, computed in memory.
    Returns a list (empty = merges cleanly), or None when git could not answer."""
    if not (SHA_RE.match(base or "") and SHA_RE.match(head or "")):
        return None
    try:
        done = subprocess.run(
            ["git", "-C", repo, "merge-tree", "--write-tree", "--no-messages",
             "--name-only", base, head],
            capture_output=True, text=True, env=git_env(), timeout=120)
    except (OSError, subprocess.SubprocessError):
        return None
    if done.returncode not in (0, 1):
        return None
    names = [ln for ln in done.stdout.splitlines()[1:] if ln.strip()]
    if done.returncode == 1 and not names:
        return None                      # a conflict with no path named is not a reading
    return names if done.returncode == 1 else []


def sweep(pulls, status, base_ref, before, after, repo, census=False):
    """Return (exit_code, report_lines)."""
    if status not in STATUSES:
        return 2, ["sweep: unknown --pulls-status %r" % sanitize(status)]
    # The tips are inputs the verdict rests on. A malformed one is an instrument error,
    # never silently reinterpreted - not as a census, and not as "no earlier tip".
    if not SHA_RE.match(after or ""):
        return 2, ["sweep: --after must be a 40-hex commit (got %s)" % sanitize(after or "nothing")]
    if census and before:
        return 2, ["sweep: --census and --before are exclusive"]
    if not census and (not SHA_RE.match(before or "") or before == ZERO_SHA):
        return 2, ["sweep: --before must be a 40-hex commit, or pass --census (got %s)"
                   % sanitize(before or "nothing")]
    if status not in MEASURING:
        # Counters are ABSENT on a non-measuring status, never printed as zero.
        return 3, ["dark-branch sweep: base=%s status=%s %s"
                   % (sanitize(base_ref), status, NOT_CLEAN), "state=not-evaluated"]
    if not isinstance(pulls, list):
        return 2, ["sweep: the pull-request list is not a JSON array"]

    buckets = collections.OrderedDict((k, []) for k in (
        "clear", "newly-dark", "still-dark", "dark-unattributed", "clear-disagrees",
        "clear-unchecked", "census-dark", "not-evaluated"))
    rank = {"FINDING": [], "DEGRADED": [], "NOT-EVALUATED": [], "ADVISORY": []}
    for pull in pulls:
        if not isinstance(pull, dict) or not isinstance(pull.get("number"), int):
            return 2, ["sweep: a pull-request record carries no integer number"]
        if pull.get("state", "OPEN") != "OPEN":
            continue                     # closed or merged during the read: not ours
        num, head = pull["number"], pull.get("headRefOid", "")
        if not SHA_RE.match(head or ""):
            return 2, ["sweep: #%d carries no 40-hex head SHA" % num]
        tag = "#%d head=%s" % (num, head[:7])
        if is_clear(pull):
            # A host answer can be definite and still predate the push. The local merge
            # into the new tip cross-checks it; a conflict there is not a clean result,
            # and neither is a cross-check that could not run - a stale host answer
            # beside a head that could not be fetched is exactly the false green this
            # cross-check exists to close, so an unchecked answer never counts as clear.
            now = conflicted_paths(repo, after, head)
            if now is None:
                buckets["clear-unchecked"].append(num)
                rank["DEGRADED"].append(
                    "DEGRADED clear-unchecked %s (the host reports mergeable; the local merge "
                    "into the new tip could not be computed, so the host's answer, which may "
                    "predate this push, is not counted clear)" % tag)
            elif now:
                buckets["clear-disagrees"].append(num)
                rank["DEGRADED"].append(
                    "DEGRADED clear-disagrees %s (the host reports mergeable; the local merge "
                    "into the new tip conflicts on %d path(s) - the host may not have "
                    "recomputed yet)" % (tag, len(now)))
            else:
                buckets["clear"].append(num)
            continue
        if not is_dark(pull):
            buckets["not-evaluated"].append(num)
            rank["NOT-EVALUATED"].append(
                "NOT-EVALUATED %s mergeability=%s/%s - this is not a clean result"
                % (tag, sanitize(pull.get("mergeable")), sanitize(pull.get("mergeStateStatus"))))
            continue
        if census:
            buckets["census-dark"].append(num)
            rank["FINDING"].append("FINDING dark %s (census - not attributed to a push)" % tag)
            continue
        now = conflicted_paths(repo, after, head)
        was = conflicted_paths(repo, before, head)
        if now is None or was is None:
            buckets["dark-unattributed"].append(num)
            rank["DEGRADED"].append("DEGRADED dark-unattributed %s (the merge could not be "
                                    "computed locally)" % tag)
        elif not now:
            buckets["dark-unattributed"].append(num)
            rank["DEGRADED"].append("DEGRADED dark-unattributed %s (the host reports a conflict; "
                                    "the local merge into the new tip is clean)" % tag)
        elif not was:
            buckets["newly-dark"].append(num)
            rank["FINDING"].append(
                "FINDING newly-dark %s conflicted-paths=%d (0 before this push): %s"
                % (tag, len(now), ", ".join(sanitize(p, 120) for p in now[:8])))
        else:
            buckets["still-dark"].append(num)
            rank["ADVISORY"].append("ADVISORY still-dark %s conflicted-paths=%d (%d before this "
                                    "push)" % (tag, len(now), len(was)))

    tips = ("mode=census after=%s" % after[:7]) if census else \
        ("mode=push before=%s after=%s" % (before[:7], after[:7]))
    lines = ["dark-branch sweep: base=%s %s status=%s open=%d %s"
             % (sanitize(base_ref), tips, status, sum(len(v) for v in buckets.values()),
                " ".join("%s=%d" % (k, len(v)) for k, v in buckets.items()))]
    for key in ("FINDING", "DEGRADED", "NOT-EVALUATED", "ADVISORY"):
        lines.extend(rank[key])
    if buckets["newly-dark"]:
        state, code = "newly-dark", 1
    elif buckets["census-dark"]:
        state, code = "census-dark", 1
    elif buckets["dark-unattributed"]:
        state, code = "dark-unattributed", 3
    elif buckets["clear-disagrees"] or buckets["clear-unchecked"] or buckets["not-evaluated"]:
        state, code = "not-evaluated", 3
    else:
        state, code = ("census-clear" if census else "none-new"), 0
    lines.append("state=" + state)
    return code, lines


def row_key(row):
    return "%s / %s" % (sanitize_name(row.get("workflow") or "-", 80), sanitize_name(row.get("name")))


def roster_problem(checks, checks_status):
    """Why a roster is not a measurement, or None when it is one."""
    if checks_status not in MEASURING or not isinstance(checks, list):
        return "rows unread (%s)" % sanitize(checks_status)
    if not checks:
        return "rows 0 - nothing dispatched yet, or the read returned nothing"
    if not all(isinstance(row, dict) for row in checks):
        return "rows malformed"
    if not any("event" in row for row in checks):
        return "rows carry no event field - read them with --json name,state,bucket,workflow,event"
    return None


def parse_record(text):
    """The record `record` printed -> dict, or None. Surrounding lines (a code fence,
    prose) are ignored; a copy with fewer row lines than its total is not a record."""
    lines = [ln.strip() for ln in (text or "").splitlines()]
    if RECORD_HEADER not in lines:
        return None
    i = lines.index(RECORD_HEADER)
    if i + 1 >= len(lines):
        return None
    m = re.match(r"^head=([0-9a-f]{40}) base=([0-9a-f]{40}) total=(\d+) pull_request=(\d+) "
                 r"required-contexts=(\d+|-)$", lines[i + 1])
    if not m:
        return None
    rows = []
    for ln in lines[i + 2:]:
        if not ln.startswith("row="):
            break
        rows.append(ln[4:])
    if len(rows) != int(m.group(3)):
        return None
    return {"head": m.group(1), "base": m.group(2), "total": int(m.group(3)),
            "pull_request": int(m.group(4)), "rows": rows,
            "required_contexts": None if m.group(5) == "-" else int(m.group(5))}


def informational(record_text, checks, required_contexts):
    """The comparison with a record, as notes. It never changes a verdict."""
    if record_text is None:
        return ["no roster recorded"]
    rec = parse_record(record_text)
    if rec is None:
        return ["record unusable - no comparison made"]
    observed = collections.Counter(row_key(row) for row in checks)
    recorded = collections.Counter(rec["rows"])
    missing, added = recorded - observed, observed - recorded
    notes = ["rows %d/%d recorded at %s" % (len(checks), rec["total"], rec["head"][:7])]
    if missing:
        names = sorted(missing)
        notes.append("missing %d: %s%s" % (sum(missing.values()), ", ".join(names[:6]),
                                          ", ..." if len(names) > 6 else ""))
    if added:
        notes.append("new %d" % sum(added.values()))
    if required_contexts is not None and rec["required_contexts"] is not None \
            and rec["required_contexts"] != required_contexts:
        notes.append("required-contexts %d→%d" % (rec["required_contexts"], required_contexts))
    return notes


def record(pull, checks, checks_status, required_contexts):
    """Return (exit_code, lines). Records only a settled roster on a mergeable head."""
    if not isinstance(pull, dict) or not isinstance(pull.get("number"), int):
        return 2, ["record: unusable pull-request record"]
    num, head, base = pull["number"], pull.get("headRefOid", ""), pull.get("baseRefOid", "")
    if not (SHA_RE.match(head or "") and SHA_RE.match(base or "")):
        return 2, ["record: #%d needs a 40-hex headRefOid and baseRefOid" % num]
    if required_contexts is not None and required_contexts < 0:
        return 2, ["record: --required-contexts must not be negative"]
    if is_dark(pull):
        return 3, ["record: not recorded - #%d is dark; %s" % (num, NOT_CLEAN)]
    if not is_clear(pull):
        return 3, ["record: not recorded - mergeability undetermined; %s" % NOT_CLEAN]
    problem = roster_problem(checks, checks_status)
    if problem:
        return 3, ["record: not recorded - %s; %s" % (problem, NOT_CLEAN)]
    if any(row.get("bucket") == "pending" for row in checks):
        return 3, ["record: not recorded - the roster is still dispatching; %s" % NOT_CLEAN]
    pr_rows = sum(1 for row in checks if row.get("event") == "pull_request")
    if pr_rows == 0:
        return 3, ["record: not recorded - no row was triggered on pull_request; %s" % NOT_CLEAN]
    lines = [RECORD_HEADER,
             "head=%s base=%s total=%d pull_request=%d required-contexts=%s"
             % (head, base, len(checks), pr_rows,
                "-" if required_contexts is None else required_contexts)]
    lines.extend("row=" + key for key in sorted(row_key(row) for row in checks))
    return 0, lines


def read(pull, checks, checks_status, record_text, required_contexts):
    """Return (exit_code, the one `Dark-branch read:` line)."""
    if not isinstance(pull, dict) or not isinstance(pull.get("number"), int):
        return 2, "Dark-branch read: unusable pull-request record"
    head = pull.get("headRefOid", "")
    if pull.get("state", "OPEN") != "OPEN" or not SHA_RE.match(head or ""):
        return 2, "Dark-branch read: #%d is not an open pull request with a head SHA" % pull["number"]
    lead = "Dark-branch read: #%d head %s · mergeable=%s/%s" % (
        pull["number"], head[:7], sanitize(pull.get("mergeable")),
        sanitize(pull.get("mergeStateStatus")))
    if is_dark(pull):
        return 1, lead + " → DARK (the host dispatches no pull_request gate for this head)"
    if not is_clear(pull):
        return 3, lead + " → " + NOT_CLEAN
    problem = roster_problem(checks, checks_status)
    if problem:
        return 3, "%s · %s → %s" % (lead, problem, NOT_CLEAN)
    total = len(checks)
    pr_rows = sum(1 for row in checks if row.get("event") == "pull_request")
    pending = sum(1 for row in checks if row.get("bucket") == "pending")
    info = informational(record_text, checks, required_contexts)
    tail = " (informational: %s)" % "; ".join(info)
    if pr_rows == 0:
        if pending:
            return 3, "%s · rows %d, still dispatching, none yet triggered on pull_request → %s" % (
                lead, total, NOT_CLEAN)
        return 1, "%s · rows %d · 0 pull_request-triggered rows → SHORTFALL%s" % (lead, total, tail)
    dispatching = (" (roster dispatching: %d of %d settled)" % (total - pending, total)) if pending else ""
    return 0, "%s · rows %d → CLEAR%s%s" % (lead, total, dispatching, tail)


# --------------------------------------------------------------------------- self-test
def _fixture_identity():
    """Configuration and identity every fixture git command runs under: no global or
    system configuration, no prompt, a fixed author and committer, fixed dates."""
    return dict(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_SYSTEM=os.devnull,
                GIT_CONFIG_NOSYSTEM="1", GIT_TERMINAL_PROMPT="0",
                GIT_AUTHOR_NAME="fixture", GIT_AUTHOR_EMAIL="fixture@example.invalid",
                GIT_COMMITTER_NAME="fixture", GIT_COMMITTER_EMAIL="fixture@example.invalid",
                GIT_AUTHOR_DATE="2000-01-01T00:00:00Z",
                GIT_COMMITTER_DATE="2000-01-01T00:00:00Z")


def _git(repo, *args):
    """Fixture git: hermetic. Every location variable git declares is cleared, so an
    inherited GIT_DIR cannot point a fixture command at the caller's repository."""
    env = git_env(_fixture_identity())
    done = subprocess.run(["git", "-C", repo, "-c", "commit.gpgsign=false",
                           "-c", "core.hooksPath=" + os.devnull] + list(args),
                          capture_output=True, text=True, env=env, timeout=60)
    if done.returncode != 0:
        raise RuntimeError("fixture git %s failed: %s" % (" ".join(args), done.stderr.strip()))
    return done.stdout.strip()


def _commit(repo, path, body, message):
    with open(os.path.join(repo, path), "w", encoding="utf-8") as handle:
        handle.write(body)
    _git(repo, "add", "--", path)
    _git(repo, "commit", "-q", "-m", message)
    return _git(repo, "rev-parse", "HEAD")


def _fixture(repo):
    """A register two releases append to. Returns the SHAs the arms use."""
    _git(repo, "init", "-q", "-b", "main")
    table = "| gate | posture |\n|---|---|\n| g0 | advisory |\n"
    _commit(repo, "register.md", table, "base: the register")
    base0 = _commit(repo, "other.txt", "one\n", "base: an unrelated file")
    _git(repo, "checkout", "-q", "-b", "victim", base0)
    victim = _commit(repo, "register.md", table + "| victim-row | advisory |\n", "victim appends a row")
    _git(repo, "checkout", "-q", "-b", "green", base0)
    green = _commit(repo, "other.txt", "one\ntwo\n", "green edits the unrelated file")
    _git(repo, "checkout", "-q", "main")
    quiet = _commit(repo, "third.txt", "x\n", "a base push that darkens nobody")
    sibling = _commit(repo, "register.md", table + "| sibling-row | advisory |\n",
                      "the sibling release appends its own row")
    later = _commit(repo, "third.txt", "x\ny\n", "a later base push")
    return {"base0": base0, "quiet": quiet, "sibling": sibling, "later": later,
            "victim": victim, "green": green}


def _repo_state(repo):
    """Everything a stray fixture command could move in a repository."""
    index = os.path.join(repo, ".git", "index")
    with open(index, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    return (_git(repo, "rev-parse", "HEAD"), _git(repo, "symbolic-ref", "-q", "HEAD"),
            _git(repo, "for-each-ref", "--format=%(refname) %(objectname)"), digest,
            _git(repo, "count-objects", "-v"))


def _pull(number, sha, mergeable, state):
    return {"number": number, "state": "OPEN", "headRefOid": sha, "headRefName": "x",
            "mergeable": mergeable, "mergeStateStatus": state}


def self_test():
    failures = []
    ran = []                             # every arm that executed, so the count is measured

    def want(label, cond):
        ran.append(label)
        if not cond:
            failures.append(label)

    with tempfile.TemporaryDirectory() as repo:
        s = _fixture(repo)
        dark = _pull(1, s["victim"], "CONFLICTING", "DIRTY")
        ok = _pull(2, s["green"], "MERGEABLE", "CLEAN")

        # S0 - control arms of the instrument itself: a tip against itself is clean, and
        # the fixture's two halves really differ. Without these every arm below is vacuous.
        want("S0a base-vs-itself is clean", conflicted_paths(repo, s["sibling"], s["sibling"]) == [])
        want("S0b victim clean before the sibling", conflicted_paths(repo, s["quiet"], s["victim"]) == [])
        want("S0c victim conflicts after it", conflicted_paths(repo, s["sibling"], s["victim"]) == ["register.md"])

        # S1 - SENSITIVITY: the push that darkened the victim is flagged, and names the path.
        rc, out = sweep([dark, ok], "fixture", "main", s["quiet"], s["sibling"], repo)
        measured_summary = out[0]        # kept as the S5s pair's sensitivity input
        want("S1 newly-dark exits 1", rc == 1 and out[-1] == "state=newly-dark")
        want("S1b names #1 newly-dark", any(l.startswith("FINDING newly-dark #1 ") and "register.md" in l for l in out))
        # S2 - SPECIFICITY, same non-empty input: the green pull request is not flagged.
        want("S2 green #2 is in no detail line", not any("#2 " in l for l in out[1:-1]))
        want("S2b summary counts clear=1", " clear=1 " in out[0])
        # S3 - SPECIFICITY on the base axis: a push that darkens nobody is silent.
        rc, out = sweep([_pull(1, s["victim"], "MERGEABLE", "CLEAN"), ok], "fixture", "main",
                        s["base0"], s["quiet"], repo)
        want("S3 a harmless base push exits 0", rc == 0 and out[-1] == "state=none-new")
        # S4 - a pull request that was already dark is NOT re-flagged by a later push.
        rc, out = sweep([dark, ok], "fixture", "main", s["sibling"], s["later"], repo)
        want("S4 still-dark is advisory, exit 0", rc == 0 and any(l.startswith("ADVISORY still-dark #1 ") for l in out))
        # S5 - a list that was not read publishes NO counters and never a clean state.
        rc, out = sweep(None, "degraded", "main", s["quiet"], s["sibling"], repo)
        want("S5 degraded exits 3 with no counters", rc == 3 and "open=" not in out[0] and "not a clean result" in out[0])
        # S5s - the same claim made structurally, so a counter under any other name is
        # caught too: no `<name>=<digits>` token anywhere in a non-measuring report, and
        # the same pattern matching a measured summary in this run (its sensitivity arm).
        counter = re.compile(r"\b[a-z][a-z-]*=[0-9]+\b")
        want("S5s a non-measuring report carries no name=digits counter (structural)",
             not any(counter.search(line) for line in out))
        want("S5sc ...and the same pattern finds the counters of a measured summary",
             counter.search(measured_summary) is not None)
        rc, out = sweep([_pull(1, s["victim"], "UNKNOWN", "UNKNOWN")], "fixture", "main", s["quiet"], s["sibling"], repo)
        want("S5b an undetermined mergeability exits 3", rc == 3 and out[-1] == "state=not-evaluated")
        # S6 - the host reports a conflict the local merge cannot attribute: its own state,
        # leading the detail lines, neither a finding nor clean.
        rc, out = sweep([_pull(2, s["green"], "CONFLICTING", "DIRTY"), ok], "fixture", "main",
                        s["quiet"], s["sibling"], repo)
        want("S6 dark-unattributed is its own state, exit 3", rc == 3 and out[-1] == "state=dark-unattributed")
        want("S6b ...and leads the detail lines", out[1].startswith("DEGRADED dark-unattributed #2 "))
        # S6c - the host says mergeable but the local merge into the new tip conflicts: a host
        # answer that predates the push. Never clean.
        rc, out = sweep([_pull(1, s["victim"], "MERGEABLE", "CLEAN")], "fixture", "main",
                        s["quiet"], s["sibling"], repo)
        want("S6c clear-disagrees exits 3", rc == 3 and any(l.startswith("DEGRADED clear-disagrees #1 ") for l in out)
             and out[-1] == "state=not-evaluated")
        # S6d - the host reports a conflict and the local merge cannot be computed at all
        # (a head whose objects are absent - the workflow's failed head fetch): its own
        # state, exit 3, never a finding and never folded into still-dark.
        absent = "f" * 40
        rc, out = sweep([_pull(4, absent, "CONFLICTING", "DIRTY")], "fixture", "main",
                        s["quiet"], s["sibling"], repo)
        want("S6d an uncomputable conflict is dark-unattributed, exit 3",
             rc == 3 and out[-1] == "state=dark-unattributed"
             and any(l.startswith("DEGRADED dark-unattributed #4 ") and "could not be computed" in l
                     for l in out))
        # S6e - the same absent head with the host reporting mergeable: the cross-check
        # cannot run, so the answer is not counted clear and the sweep is not green.
        rc, out = sweep([_pull(5, absent, "MERGEABLE", "CLEAN")], "fixture", "main",
                        s["quiet"], s["sibling"], repo)
        want("S6e an unchecked host answer is clear-unchecked, never green, exit 3",
             rc == 3 and out[-1] == "state=not-evaluated" and " clear=0 " in out[0]
             and any(l.startswith("DEGRADED clear-unchecked #5 ") for l in out))
        # S7 - an explicit census: every dark pull request is a finding, labelled as a census.
        rc, out = sweep([dark, ok], "fixture", "main", "", s["sibling"], repo, census=True)
        want("S7 census exits 1 with its own state", rc == 1 and out[-1] == "state=census-dark"
             and any(l.startswith("FINDING dark #1 ") and "census" in l for l in out) and "mode=census" in out[0])
        rc, out = sweep([dark], "fixture", "main", s["quiet"], s["sibling"], repo, census=True)
        want("S7b census with an earlier tip is unusable, exit 2", rc == 2)
        rc, out = sweep([ok], "fixture", "main", "", s["sibling"], repo, census=True)
        want("S7c a census with nothing dark exits 0", rc == 0 and out[-1] == "state=census-clear")
        # S8 - input hygiene: a malformed head is an instrument error, never a verdict.
        rc, out = sweep([_pull(3, "not-a-sha", "CONFLICTING", "DIRTY")], "fixture", "main", s["quiet"], s["sibling"], repo)
        want("S8 a malformed head exits 2", rc == 2)
        want("S8b a hostile ref name cannot open a line", not sanitize("::error::x`|\n").startswith("::"))
        # S9 - a tip that is not a full commit id is never reinterpreted as a census.
        rc, out = sweep([dark], "fixture", "main", s["quiet"][:12], s["sibling"], repo)
        want("S9 an abbreviated --before exits 2", rc == 2)
        rc, out = sweep([dark], "fixture", "main", s["quiet"], "", repo)
        want("S9b an empty --after exits 2", rc == 2)
        rc, out = sweep([dark], "fixture", "main", ZERO_SHA, s["sibling"], repo)
        want("S9c an all-zero --before without --census exits 2", rc == 2)

    # H - hermetic git (lock condition 2(c)): an inherited location variable must not
    # reach any git command this tool runs, fixture or measurement.
    names = local_env_vars()
    want("H0 the cleared list names GIT_DIR, GIT_WORK_TREE and GIT_INDEX_FILE",
         {"GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"} <= set(names))
    for arm, keys in (("H1", ("GIT_DIR",)), ("H1c", ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"))):
        with tempfile.TemporaryDirectory() as box:
            outer, inner = os.path.join(box, "outer"), os.path.join(box, "inner")
            os.makedirs(outer)
            os.makedirs(inner)
            _git(outer, "init", "-q", "-b", "main")
            _commit(outer, "keep.txt", "outer\n", "outer root")
            before_state = _repo_state(outer)
            leaked = {"GIT_DIR": os.path.join(outer, ".git"), "GIT_WORK_TREE": outer,
                      "GIT_INDEX_FILE": os.path.join(outer, ".git", "index")}
            leaked = {k: leaked[k] for k in keys}
            saved = {k: os.environ.get(k) for k in leaked}
            os.environ.update(leaked)
            # The leak must be live while the fixture runs, or "unchanged" below proves
            # nothing: an arm whose hazard was never applied passes vacuously.
            want("%sL the leaked %s is live while the fixture runs" % (arm, "+".join(keys)),
                 set(leaked) == set(keys) and all(os.environ.get(k) == v for k, v in leaked.items()))
            try:
                t = _fixture(inner)
                inner_answer = conflicted_paths(inner, t["sibling"], t["victim"])
                seen = git_env()
            except RuntimeError:         # a fixture command sent elsewhere: an arm failure
                inner_answer, seen = None, dict(os.environ)
            finally:
                for key, value in saved.items():
                    if value is None:
                        os.environ.pop(key, None)
                    else:
                        os.environ[key] = value
            want("%s an inherited %s leaves the caller's repository unchanged, and the fixture "
                 "and the merge land where they were asked" % (arm, "+".join(keys)),
                 _repo_state(outer) == before_state and inner_answer == ["register.md"])
            if arm == "H1":
                want("H2 the git environment carries none of the cleared variables",
                     not any(k in seen for k in names))

    # H1s - the H arms' sensitivity arm, on a repository of its own: one git command
    # run WITH an inherited GIT_DIR (the hazard, not cleared) moves that repository, and
    # the state probe sees the move. Without it, a probe that could not see a move would
    # pass H1 and H1c as "unchanged". The command starts from git_env() and adds the
    # hazard back, so no other variable the caller exports can reach it.
    with tempfile.TemporaryDirectory() as box:
        bait, elsewhere = os.path.join(box, "bait"), os.path.join(box, "elsewhere")
        os.makedirs(bait)
        os.makedirs(elsewhere)
        _git(bait, "init", "-q", "-b", "main")
        _commit(bait, "keep.txt", "bait\n", "bait root")
        bait_before = _repo_state(bait)
        hazard = git_env(dict(_fixture_identity(), GIT_DIR=os.path.join(bait, ".git"),
                              GIT_WORK_TREE=bait))
        try:
            subprocess.run(["git", "-C", elsewhere, "-c", "commit.gpgsign=false",
                            "-c", "core.hooksPath=" + os.devnull, "commit", "-q",
                            "--allow-empty", "-m", "moved by an inherited GIT_DIR"],
                           capture_output=True, text=True, env=hazard, timeout=60)
        except (OSError, subprocess.SubprocessError):
            pass                         # nothing moved: the arm below fails, as it should
        want("H1s the state probe sees a repository an inherited GIT_DIR moved",
             _repo_state(bait) != bait_before)

    # R and C - the stage-side read and the record. Roster shape from a measured head:
    # 52 rows triggered on pull_request and 4 triggered otherwise.
    healthy = [{"name": "g%02d" % i, "bucket": "pass", "event": "pull_request", "workflow": "w%d" % (i % 5)}
               for i in range(52)] \
        + [{"name": "scan%d" % i, "bucket": "pass", "event": "dynamic", "workflow": "scanning"} for i in range(4)]
    collapsed = healthy[52:]
    head = "a" * 40
    live = {"number": 9, "state": "OPEN", "headRefOid": head, "baseRefOid": "b" * 40,
            "mergeable": "MERGEABLE", "mergeStateStatus": "CLEAN"}
    rc, rec_lines = record(live, healthy, "fixture", 18)
    rec = "\n".join(["```"] + rec_lines + ["```"])         # as pasted into a sub-task comment
    want("C1 a settled mergeable roster is recorded", rc == 0 and rec_lines[0] == RECORD_HEADER
         and len(rec_lines) == 2 + 56 and rec_lines[2:] == sorted(rec_lines[2:]))
    want("C1b the record carries head, base, counts and the required-context count",
         rec_lines[1] == "head=%s base=%s total=56 pull_request=52 required-contexts=18" % ("a" * 40, "b" * 40))
    rc, out = record(live, collapsed, "fixture", 18)
    want("C2 a collapsed roster is not recorded, exit 3", rc == 3 and RECORD_HEADER not in out)
    rc, out = record(live, healthy[:40] + [{"name": "p", "bucket": "pending", "event": "pull_request"}], "fixture", 18)
    want("C3 a dispatching roster is not recorded, exit 3", rc == 3)
    rc, out = record(dict(live, mergeable="CONFLICTING", mergeStateStatus="DIRTY"), healthy, "fixture", 18)
    want("C4 a dark head is not recorded, exit 3", rc == 3)
    rc, out = record(dict(live, baseRefOid="short"), healthy, "fixture", 18)
    want("C4b a record without a base tip is unusable, exit 2", rc == 2)
    want("C5 the record parses back as printed", (parse_record(rec) or {}).get("total") == 56)

    # R1 - SENSITIVITY: a conflicting pull request reads DARK whatever its roster shows.
    rc, line = read(dict(live, mergeable="CONFLICTING", mergeStateStatus="DIRTY"), healthy, "fixture", rec, 18)
    want("R1 conflict reads DARK", rc == 1 and "→ DARK" in line)
    # R2 - SENSITIVITY, the false green: four passing rows, none triggered on pull_request.
    rc, line = read(live, collapsed, "fixture", rec, 18)
    want("R2 a collapsed all-green roster reads SHORTFALL", rc == 1 and "SHORTFALL" in line
         and "0 pull_request-triggered rows" in line)
    rc, line = read(live, collapsed, "fixture", None, None)
    want("R2b ...and with no record at all - darkness never needs one", rc == 1 and "SHORTFALL" in line
         and "no roster recorded" in line)
    # R3 - SPECIFICITY, same vocabulary, healthy input: CLEAR.
    rc, line = read(live, healthy, "fixture", rec, 18)
    want("R3 a complete roster reads CLEAR", rc == 0 and "→ CLEAR" in line and "rows 56/56" in line)
    # R4 - a registration moves the required-context count: noted, never a verdict.
    rc, line = read(live, healthy, "fixture", rec, 22)
    want("R4 a required-context change is a note on a CLEAR line", rc == 0 and "→ CLEAR" in line and "18→22" in line)
    # R5 - the record is INFORMATIONAL: a fall below it, with pull_request rows present,
    # stays CLEAR and names the missing row.
    rc, line = read(live, healthy[1:], "fixture", rec, 18)
    want("R5 a fall below the record is CLEAR, exit 0", rc == 0 and "→ CLEAR" in line)
    want("R5b ...and names the missing row", "rows 55/56" in line and "missing 1: w0 / g00" in line)
    # R6 - a roster still dispatching: presence answers darkness; no pull_request row yet does not.
    rc, line = read(live, healthy[:40] + [{"name": "p", "bucket": "pending", "event": "pull_request", "workflow": "w"}],
                    "fixture", rec, 18)
    want("R6 dispatching with pull_request rows reads CLEAR", rc == 0 and "roster dispatching" in line)
    rc, line = read(live, collapsed + [{"name": "p", "bucket": "pending", "event": "dynamic", "workflow": "w"}],
                    "fixture", rec, 18)
    want("R6b dispatching with none triggered on pull_request exits 3", rc == 3 and "SHORTFALL" not in line)
    # R7 - an unread roster or an undetermined mergeability is never CLEAR.
    rc, line = read(live, None, "degraded", rec, 18)
    want("R7 unread rows exit 3", rc == 3 and "CLEAR" not in line)
    rc, line = read(dict(live, mergeable="UNKNOWN", mergeStateStatus="UNKNOWN"), healthy, "fixture", None, None)
    want("R7b undetermined mergeability exits 3", rc == 3 and "CLEAR" not in line)
    # R8 - degenerate inputs are non-measurements, never a verdict.
    rc, line = read(live, [], "fixture", rec, 18)
    want("R8 an empty roster exits 3, named as empty", rc == 3 and "rows 0" in line and "CLEAR" not in line)
    rc, line = read(live, [{"name": "x", "bucket": "pass"} for _ in range(4)], "fixture", rec, 18)
    want("R8b rows with no event field exit 3", rc == 3 and "no event field" in line)
    rc, line = read(live, healthy, "fixture", "\n".join(rec_lines[:20]), 18)
    want("R8c a truncated record changes no verdict", rc == 0 and "→ CLEAR" in line and "record unusable" in line)

    # M - the command line itself, which is what a workflow, a stage and a spoke call.
    # A host read that FAILED leaves an empty file; that must be exit 3, never exit 2.
    with tempfile.TemporaryDirectory() as box:
        empty, junk, good, roster, saved_rec, nopulls = (os.path.join(box, n) for n in (
            "empty.json", "junk.json", "pull.json", "checks.json", "record.txt", "pulls.json"))
        open(empty, "w").close()
        with open(junk, "w", encoding="utf-8") as handle:
            handle.write("{not json")
        with open(good, "w", encoding="utf-8") as handle:
            json.dump(live, handle)
        with open(roster, "w", encoding="utf-8") as handle:
            json.dump(healthy, handle)
        with open(nopulls, "w", encoding="utf-8") as handle:
            json.dump([], handle)
        sink = io.StringIO()
        with contextlib.redirect_stdout(sink), contextlib.redirect_stderr(sink):
            m1 = main(["sweep", "--pulls", empty, "--pulls-status", "degraded", "--base-ref", "main",
                       "--before", "c" * 40, "--after", "d" * 40])
            m2 = main(["sweep", "--pulls", junk, "--pulls-status", "fetched", "--base-ref", "main",
                       "--before", "c" * 40, "--after", "d" * 40])
            m3 = main(["read", "--pull", empty, "--pull-status", "degraded"])
            m4 = main(["read", "--pull", good, "--checks", empty, "--checks-status", "degraded"])
            m6 = main(["sweep", "--pulls", nopulls, "--pulls-status", "fetched", "--base-ref", "main",
                       "--before", "c" * 12, "--after", "d" * 40])
        noisy = sink.getvalue()
        want("M1 an empty list file with a degraded status exits 3", m1 == 3)
        want("M2 an unparseable file claimed as fetched exits 2", m2 == 2)
        want("M3 an unread pull request exits 3", m3 == 3)
        want("M4 an unread roster exits 3", m4 == 3)
        want("M5 none of them prints CLEAR or a counter", "CLEAR" not in noisy and "open=" not in noisy)
        want("M6 an abbreviated --before on the command line exits 2", m6 == 2)
        sink = io.StringIO()
        with contextlib.redirect_stdout(sink):
            m7 = main(["record", "--pull", good, "--checks", roster, "--required-contexts", "18"])
        with open(saved_rec, "w", encoding="utf-8") as handle:
            handle.write(sink.getvalue())
        sink = io.StringIO()
        with contextlib.redirect_stdout(sink):
            m8 = main(["read", "--pull", good, "--checks", roster, "--record", saved_rec,
                       "--required-contexts", "18"])
        want("M7 record on the command line exits 0", m7 == 0)
        want("M8 read --record round-trips it to CLEAR rows 56/56", m8 == 0 and "rows 56/56" in sink.getvalue())

    arms = len(ran)
    if arms < ARMS_DEFINED:              # an arm that silently stopped running is a failure
        failures.append("only %d arm(s) ran; %d are defined" % (arms, ARMS_DEFINED))
    if failures:
        print("self-test FAIL: %d of %d arm(s)" % (len(failures), arms), file=sys.stderr)
        for label in failures:
            print("  " + label, file=sys.stderr)
        return 2
    print("self-test OK - %d arm(s): sweep S0-S9 (a sibling merge darkens the victim and is "
          "flagged; the green pull request, a harmless base push and an already-dark pull "
          "request are not; an unattributable or uncomputable conflict, a stale host answer "
          "and an unchecked one are never clean; a non-measuring report carries no counter), "
          "hermetic H0-H2 (an inherited GIT_DIR changes nothing in the caller's repository; "
          "the leak is shown live and the state probe shown to see a move), record C1-C5, "
          "read R1-R8 (a collapsed all-green roster is SHORTFALL with or without a record; "
          "the record never changes a verdict), command line M1-M8" % arms)
    return 0


def _load(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    if argv[:1] == ["--self-test"]:
        return self_test()
    parser = argparse.ArgumentParser(prog="check-dark-branch.py", description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    sw = sub.add_parser("sweep")
    sw.add_argument("--pulls")
    sw.add_argument("--pulls-status", default="fetched")
    sw.add_argument("--base-ref", required=True)
    sw.add_argument("--before", default="")
    sw.add_argument("--after", default="")
    sw.add_argument("--census", action="store_true")
    sw.add_argument("--repo", default=".")
    for name in ("record", "read"):
        sp = sub.add_parser(name)
        sp.add_argument("--pull", required=True)
        sp.add_argument("--pull-status", default="fetched")
        sp.add_argument("--checks")
        sp.add_argument("--checks-status", default="fetched")
        sp.add_argument("--required-contexts", type=int)
        if name == "read":
            sp.add_argument("--record", default="")
    args = parser.parse_args(argv)
    # A file is parsed ONLY when its status says it is a measurement. A read that failed
    # leaves an empty or partial file behind; parsing that would turn a host outage into
    # exit 2 ("the instrument is broken") when the honest answer is exit 3.
    try:
        if args.cmd == "sweep":
            status = args.pulls_status if args.pulls else "not-run"
            pulls = _load(args.pulls) if status in MEASURING else None
            code, lines = sweep(pulls, status, args.base_ref, args.before, args.after, args.repo,
                                census=args.census)
            print("\n".join(lines))
            return code
        if args.pull_status not in MEASURING:
            print("%s: pull request unread (%s) → %s" % (
                "Dark-branch read" if args.cmd == "read" else "record",
                sanitize(args.pull_status), NOT_CLEAN))
            return 3 if args.pull_status in STATUSES else 2
        checks_status = args.checks_status if args.checks else "not-run"
        checks = _load(args.checks) if checks_status in MEASURING else None
        pull = _load(args.pull)
        if args.cmd == "record":
            code, lines = record(pull, checks, checks_status, args.required_contexts)
            print("\n".join(lines))
            return code
        record_text = None
        if args.record:
            try:
                with open(args.record, encoding="utf-8") as handle:
                    record_text = handle.read()
            except OSError:
                record_text = ""         # an unreadable record is informational: "unusable"
        code, line = read(pull, checks, checks_status, record_text, args.required_contexts)
        print(line)
        return code
    except (OSError, ValueError) as exc:
        print("check-dark-branch: unusable input (%s)" % sanitize(exc, 160), file=sys.stderr)
        return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except BaseException as exc:         # noqa: BLE001 - see the comment below
        # An uncaught exception would exit 1, which this tool reserves for a FINDING.
        # A crash is an instrument failure and must never read as "newly dark".
        print("check-dark-branch: internal error (%s: %s)"
              % (type(exc).__name__, sanitize(exc, 160)), file=sys.stderr)
        sys.exit(2)

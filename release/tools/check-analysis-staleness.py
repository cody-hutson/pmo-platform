#!/usr/bin/env python3
"""check-analysis-staleness.py — analysis-workspace staleness lint.

The analysis workspace (`analysis/<name>-YYYY-MM-DD/SUMMARY.md`, git-ignored, operator-local)
accumulates silently: old audits read as current and the folder becomes a drift surface. The
Analysis-Workspace Standard (core/standards/analysis-workspace-standard.md §4) names a *deferred*
enforcement automation that flags every past-`sunset` artifact and any analysis missing the
required frontmatter. This is that lint — an operator-local, non-blocking sibling of the
release/tools/check-*.py family (check-adr-durability.py is the closest analog: a
frontmatter-reading lint with an embedded --self-test, TSV output, and exit-{0,1,3}).

TWO HARD-FINDING RULES (these gate the exit code)
-------------------------------------------------
  STALE     `now > sunset` — the artifact's own staleness date has passed.
  STALE-WI  the artifact's `work_item` is CLOSED and >30 days have elapsed since its close
            (standard §4.1: "created + 90d, OR work_item close + 30d, whichever first" — the
            close-based arm; the created+90d arm is captured by the operator-set `sunset` date).
  MISSING   any of the five required frontmatter fields is absent or empty:
            analysis_type | work_item | created | sunset | status  (standard §3). A file with no
            leading `---`...`---` block at all rolls up to one MISSING NO-FRONTMATTER.

NON-GATING ADVISORIES (never change the exit code)
--------------------------------------------------
  INFO           an unparseable `sunset` (present but not a date — §4.1 permits an
                 operator-explicit sunset "with a one-line reason", so a non-date value is NOT
                 stale), or a `work_item` with no resolvable issue/milestone number (prose
                 work_item). The false-positive guard: presence — not value-conformance — is what
                 MISSING tests, and a non-date sunset is INFO, never STALE.
  CONFIG         the work_item-close check was skipped (no `gh`, no repo, or --no-gh) — surfaced
                 once, never as per-artifact noise; sunset-only staleness still applies.
  ARCHIVED-SKIP  a `status: archived` artifact is skipped (the flag->archive->skip loop is closed).

DEFAULT READ-ONLY; ARCHIVE IS OPT-IN + INTERACTIVE
--------------------------------------------------
The default invocation is a pure read-only TSV lint. `--archive` is an opt-in, interactive-only
mode offering per-flagged-artifact [a]rchive / [p]urge / [s]kip; it NEVER mutates without an
explicit operator keystroke, and there is no non-interactive mutation flag. Archive = flip the
frontmatter `status:` to `archived` in place; purge = move the subfolder to the OS trash (never
`rm -rf`). No CI workflow ships: the workspace is git-ignored, so this scan can never be a CI gate.

OUTPUT (TSV) / EXIT CODES
-------------------------
  SCANNED        <n>
  CONFIG         <note>
  STALE          <subfolder>\t<work_item>\t<N>d-past-sunset
  STALE-WI       <subfolder>\t<work_item>\t<N>d-since-close
  MISSING        <subfolder>\t<field | NO-FRONTMATTER>
  INFO           <subfolder>\t<note>
  ARCHIVED-SKIP  <subfolder>
  COUNT          <n>                     # hard findings only (STALE + STALE-WI + MISSING)

  exit 0 — clean (no hard finding; INFO / CONFIG / ARCHIVED-SKIP never gate)
  exit 1 — >=1 hard finding, OR self-test failure
  exit 3 — input failure (the analysis/ dir is absent — the tree moved)

Python 3.9-compatible — matches /usr/bin/python3 on the operator baseline. No third-party deps
(frontmatter is hand-parsed). `subprocess` only for the optional `gh` calls + repo-slug derivation.

Reference: analysis-workspace-standard.md §3 (required fields) / §4 (sunset rule). Provenance: #2225 / #1492.
"""

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
import tempfile
from collections import namedtuple

ANALYSIS_DIR = "analysis"
SUMMARY_NAME = "SUMMARY.md"
REQUIRED_FIELDS = ("analysis_type", "work_item", "created", "sunset", "status")  # standard §3
GRACE_DAYS = 30            # standard §4.1 "work_item close + 30 days"
DEFAULT_SUNSET_DAYS = 90   # standard §4.1 "created + 90 days" — INFO context only, never a flag
ARCHIVED_TOKEN = "archived"  # standard §3 status enum terminal state
DATE_RE = re.compile(r"(\d{4})-(\d{2})-(\d{2})")   # first date token anywhere in a value
WORKITEM_NUM_RE = re.compile(r"#?(\d+)")           # first issue-ish number (after prefix strip)
FRONTMATTER_DELIM = "---"

IssueState = namedtuple("IssueState", ("state", "closed_date"))


# ── frontmatter + value parsing (hand-rolled; no PyYAML, 3.9-compatible) ──────

def parse_frontmatter(text):
    """Parse the leading `---`...`---` frontmatter into {key: value}, else None.

    Returns None when the file has no leading, closed frontmatter block (the caller emits a
    NO-FRONTMATTER MISSING roll-up). Each block line is split on its FIRST `:` into
    `key.strip().lower() -> value.strip()`. Index-preserving walk, mirroring the
    check-adr-durability.py frontmatter conventions.
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != FRONTMATTER_DELIM:
        return None
    fm = {}
    for i in range(1, len(lines)):
        if lines[i].strip() == FRONTMATTER_DELIM:
            return fm
        line = lines[i]
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        fm[key.strip().lower()] = value.strip()
    return None  # opened but never closed -> not a valid frontmatter block


def first_date(value):
    """First VALID YYYY-MM-DD date in a value, else None.

    Tolerates a trailing weekday/reason suffix: `created: 2026-07-22 (Wednesday)` and an
    operator-explicit `sunset: 2026-09-01 (reason)` both parse; a prose-only `sunset`
    (`on execution-release close`) yields None so the caller emits INFO, never STALE. A
    calendar-invalid token (2026-13-40) is rejected.
    """
    m = DATE_RE.search(value or "")
    if not m:
        return None
    try:
        return datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
    except ValueError:
        return None


def extract_work_item(work_item_value):
    """(kind, number) from a work_item value, else None (a prose work_item -> INFO).

    Strips a leading epic / milestone- / milestone token, then takes the first issue-ish
    number. kind = "milestone" when a milestone prefix matched, else "issue" (epics are issues).
    """
    v = (work_item_value or "").strip().strip('"').strip("'").strip()
    if not v:
        return None
    kind = "issue"
    m_pref = re.match(r"^(epic|milestone[-\s]?)", v.lower())
    if m_pref and m_pref.group(1).startswith("milestone"):
        kind = "milestone"
    m = WORKITEM_NUM_RE.search(v)
    if not m:
        return None
    return (kind, int(m.group(1)))


# ── network boundary (isolated here so the self-test injects a stub) ──────────

def _parse_closed_date(raw):
    if not raw:
        return None
    d = DATE_RE.search(str(raw))
    if not d:
        return None
    try:
        return datetime.date(int(d.group(1)), int(d.group(2)), int(d.group(3)))
    except ValueError:
        return None


def issue_state(kind, number, repo, gh_bin):
    """Query the work_item's state via gh. Returns IssueState(state, closed_date) or None.

    ANY failure (no gh, no auth, network error, 404, non-zero exit, unparseable output)
    returns None so the caller degrades gracefully — this is the sole network boundary.
    """
    if not repo:
        return None
    try:
        if kind == "milestone":
            out = subprocess.run(
                [gh_bin, "api", "repos/%s/milestones/%d" % (repo, number)],
                capture_output=True, text=True)
            if out.returncode != 0:
                return None
            data = json.loads(out.stdout)
            state = str(data.get("state", "")).upper()
            return IssueState(state, _parse_closed_date(data.get("closed_at")))
        out = subprocess.run(
            [gh_bin, "issue", "view", str(number), "--repo", repo,
             "--json", "state,closedAt"],
            capture_output=True, text=True)
        if out.returncode != 0:
            return None
        data = json.loads(out.stdout)
        state = str(data.get("state", "")).upper()
        return IssueState(state, _parse_closed_date(data.get("closedAt")))
    except Exception:
        return None


def _gh_available(gh_bin):
    try:
        return subprocess.run([gh_bin, "--version"],
                              capture_output=True, text=True).returncode == 0
    except Exception:
        return False


def make_state_lookup(repo, gh_bin, no_gh):
    """A memoized (kind, number) -> IssueState|None lookup, plus an optional CONFIG note.

    When --no-gh, gh is missing, or repo is unresolved, returns a lookup that always yields
    None plus a visible CONFIG note (the work_item-close arm is skipped; sunset-only staleness
    still applies) — the check-adr-durability "surface a visible skip, never scan nothing
    silently" precedent.
    """
    note = None
    if no_gh:
        note = "work_item-close check SKIPPED (--no-gh); sunset-only staleness applied"
    elif not repo:
        note = ("work_item-close check SKIPPED — repo unresolved (pass --repo or run inside a "
                "clone with an origin remote); sunset-only staleness applied")
    elif not _gh_available(gh_bin):
        note = "work_item-close check SKIPPED — gh unavailable; sunset-only staleness applied"
    if note is not None:
        return (lambda kind, number: None), note
    cache = {}

    def lookup(kind, number):
        key = (kind, number)
        if key not in cache:
            cache[key] = issue_state(kind, number, repo, gh_bin)
        return cache[key]

    return lookup, None


# ── pure classification (no I/O; state_lookup is injected) ────────────────────

def classify(subfolder, fm, today, state_lookup):
    """Classify one artifact into typed rows. Pure — state_lookup is an injected callable.

    Rows are tuples (rowtype, *fields); rowtype in
    {STALE, STALE-WI, MISSING, INFO, ARCHIVED-SKIP}.
    """
    if fm is None:
        return [("MISSING", subfolder, "NO-FRONTMATTER")]

    status_words = (fm.get("status", "") or "").strip().lower().split()
    if status_words and status_words[0] == ARCHIVED_TOKEN:
        return [("ARCHIVED-SKIP", subfolder)]

    rows = []
    for f in REQUIRED_FIELDS:
        if f not in fm or not fm[f].strip():
            rows.append(("MISSING", subfolder, f))

    work_item_raw = fm.get("work_item", "").strip() or "(none)"

    # --- past-sunset (date arm) ---
    sunset_val = fm.get("sunset", "")
    sd = first_date(sunset_val)
    if sd is not None:
        if today > sd:
            rows.append(("STALE", subfolder, work_item_raw, "%dd-past-sunset" % (today - sd).days))
    elif sunset_val.strip():
        cd = first_date(fm.get("created", ""))
        imputed = ""
        if cd is not None:
            imputed = "; imputed created+90d = %s" % (cd + datetime.timedelta(days=DEFAULT_SUNSET_DAYS))
        rows.append(("INFO", subfolder,
                     'sunset not a date ("%s"); operator-explicit sunset per standard §4.1%s'
                     % (sunset_val.strip(), imputed)))

    # --- work_item-close arm ---
    wi = extract_work_item(fm.get("work_item", ""))
    if wi is not None:
        st = state_lookup(*wi)
        if st is not None and st.state == "CLOSED" and st.closed_date is not None:
            days = (today - st.closed_date).days
            if days > GRACE_DAYS:
                rows.append(("STALE-WI", subfolder, work_item_raw, "%dd-since-close" % days))
    elif fm.get("work_item", "").strip():
        rows.append(("INFO", subfolder, "work_item has no resolvable issue/milestone number"))

    return rows


# ── filesystem walk ──────────────────────────────────────────────────────────

def collect_summaries(root):
    """Sorted absolute paths of every analysis/*/SUMMARY.md (ONE level deep).

    analysis/README.md is excluded by name; nested analysis/x/sub/SUMMARY.md is out of scope
    (the standard defines SUMMARY.md at the dated-subfolder top level only).
    """
    base = os.path.join(root, ANALYSIS_DIR)
    if not os.path.isdir(base):
        return []
    out = []
    for name in sorted(os.listdir(base)):
        sub = os.path.join(base, name)
        if not os.path.isdir(sub):
            continue
        candidate = os.path.join(sub, SUMMARY_NAME)
        if os.path.isfile(candidate):
            out.append(candidate)
    return out


def scan(root, today, state_lookup):
    """Walk every analysis/*/SUMMARY.md; return (rows, hard_count, scanned).

    hard_count tallies STALE + STALE-WI + MISSING only (the exit-code-gating findings).
    """
    rows = []
    hard = 0
    paths = collect_summaries(root)
    for path in paths:
        subfolder = os.path.basename(os.path.dirname(path))
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError:
            rows.append(("MISSING", subfolder, "UNREADABLE"))
            hard += 1
            continue
        for row in classify(subfolder, parse_frontmatter(text), today, state_lookup):
            rows.append(row)
            if row[0] in ("STALE", "STALE-WI", "MISSING"):
                hard += 1
    return rows, hard, len(paths)


# ── inputs ───────────────────────────────────────────────────────────────────

def derive_repo(explicit):
    """owner/name slug: --repo wins, else the origin remote URL. None when neither resolves."""
    if explicit:
        return explicit.strip() or None
    try:
        url = subprocess.run(["git", "config", "--get", "remote.origin.url"],
                             capture_output=True, text=True).stdout.strip()
        m = re.search(r"[:/]([^/]+/[^/]+?)(?:\.git)?$", url)
        if m:
            return m.group(1)
    except Exception:
        pass
    return None


# ── opt-in, interactive-only archive/purge (no non-interactive mutation path) ─

def _which(name):
    for d in os.environ.get("PATH", "").split(os.pathsep):
        p = os.path.join(d, name)
        if os.path.isfile(p) and os.access(p, os.X_OK):
            return p
    return None


def _archive_in_place(summary_path, today_iso):
    """Rewrite the first status: line inside the frontmatter to `archived (...)` atomically."""
    try:
        with open(summary_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError as exc:
        print("cannot read %s (%s); skipped" % (summary_path, exc))
        return
    out, in_fm, seen_open, done = [], False, False, False
    for line in lines:
        stripped = line.strip()
        if stripped == FRONTMATTER_DELIM and not seen_open:
            seen_open, in_fm = True, True
            out.append(line)
            continue
        if stripped == FRONTMATTER_DELIM and in_fm:
            in_fm = False
            out.append(line)
            continue
        if in_fm and not done and re.match(r"^\s*status\s*:", line):
            out.append("status: archived (archived %s by check-analysis-staleness)\n" % today_iso)
            done = True
            continue
        out.append(line)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(summary_path))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.writelines(out)
        os.replace(tmp, summary_path)  # atomic
        print("archived %s" % summary_path)
    except OSError as exc:
        print("archive failed for %s (%s)" % (summary_path, exc))
        if os.path.exists(tmp):
            os.remove(tmp)


def _purge_subfolder(sub):
    trash = _which("trash")
    if trash:
        try:
            subprocess.run([trash, sub], check=True)
            print("purged (trashed) %s" % sub)
            return
        except Exception as exc:
            print("trash failed for %s (%s)" % (sub, exc))
    print("no `trash` on PATH — run this yourself to purge (never rm -rf blindly):")
    print("  trash %s" % sub)


def run_archive(root, flagged):
    """Opt-in, interactive-only. Per flagged subfolder: [a]rchive / [p]urge / [s]kip."""
    if not flagged:
        print("no flagged artifacts to archive.")
        return 0
    today_iso = datetime.date.today().isoformat()
    for subfolder in sorted(flagged):
        sub = os.path.join(root, ANALYSIS_DIR, subfolder)
        summary = os.path.join(sub, SUMMARY_NAME)
        try:
            choice = input("[%s] archive/purge/skip? [a/p/s]: " % subfolder).strip().lower()
        except EOFError:
            print("no interactive input available; skipping %s" % subfolder)
            continue
        if choice == "a":
            _archive_in_place(summary, today_iso)
        elif choice == "p":
            _purge_subfolder(sub)
        else:
            print("skipped %s" % subfolder)
    return 0


# ── self-test (synthetic fixtures + injected state_lookup stub; no network) ───

def self_test():
    results = []

    def check(name, ok):
        results.append((name, ok))

    today = datetime.date(2026, 7, 24)
    OPEN = IssueState("OPEN", None)

    def closed_days_ago(n):
        return IssueState("CLOSED", today - datetime.timedelta(days=n))

    def stub(state_map):
        return lambda kind, number: state_map.get(number)

    def fm_of(**over):
        base = {
            "analysis_type": "audit",
            "work_item": "#123",
            "created": "2026-05-01",
            "sunset": "2026-12-01",
            "status": "active",
        }
        base.update(over)
        return base

    def to_text(fm):
        body = ["---"]
        for k, v in fm.items():
            body.append("%s: %s" % (k, v))
        body.append("---")
        body.append("")
        body.append("# SUMMARY")
        return "\n".join(body) + "\n"

    def rtypes(fm, state_map=None):
        rows = classify("fix", fm, today, stub(state_map or {}))
        return sorted(r[0] for r in rows)

    # T1 — all 5 fields, future sunset, work_item OPEN -> 0 findings.
    check("T1 clean artifact yields no findings",
          rtypes(fm_of(), {123: OPEN}) == [])

    # T2 — parseable sunset < today -> exactly 1 STALE (age correct).
    rows_t2 = classify("fix", fm_of(sunset="2026-01-01"), today, stub({123: OPEN}))
    stale_t2 = [r for r in rows_t2 if r[0] == "STALE"]
    check("T2 past-sunset yields exactly 1 STALE",
          [r[0] for r in rows_t2] == ["STALE"])
    check("T2 STALE age is correct",
          len(stale_t2) == 1 and stale_t2[0][3] == "%dd-past-sunset"
          % (today - datetime.date(2026, 1, 1)).days)

    # T3 — drop sunset key -> exactly 1 MISSING (field=sunset).
    fm_t3 = fm_of()
    del fm_t3["sunset"]
    rows_t3 = classify("fix", fm_t3, today, stub({123: OPEN}))
    check("T3 missing sunset key -> 1 MISSING(sunset)",
          rows_t3 == [("MISSING", "fix", "sunset")])

    # T4 — no `---` block -> 1 MISSING NO-FRONTMATTER.
    check("T4 no frontmatter -> MISSING NO-FRONTMATTER",
          classify("fix", parse_frontmatter("# just a body\n"), today, stub({}))
          == [("MISSING", "fix", "NO-FRONTMATTER")])

    # T5 — present-but-prose sunset -> 0 hard findings, 1 INFO (false-positive guard).
    rows_t5 = classify("fix", fm_of(sunset="on execution-release close"), today, stub({123: OPEN}))
    check("T5 prose sunset -> only INFO (no STALE/MISSING)",
          [r[0] for r in rows_t5] == ["INFO"])

    # T6 — weekday-suffixed created parses; no MISSING; age math holds.
    check("T6 first_date tolerates a weekday suffix",
          first_date("2026-07-22 (Wednesday)") == datetime.date(2026, 7, 22))
    check("T6 weekday-suffixed created is not MISSING",
          rtypes(fm_of(created="2026-07-22 (Wednesday)"), {123: OPEN}) == [])

    # T7 — work_item CLOSED 40d ago, sunset future -> exactly 1 STALE-WI.
    check("T7 work_item closed 40d ago -> STALE-WI",
          rtypes(fm_of(), {123: closed_days_ago(40)}) == ["STALE-WI"])

    # T8 — work_item CLOSED 10d ago -> 0 findings (grace not elapsed).
    check("T8 work_item closed 10d ago -> no finding (grace)",
          rtypes(fm_of(), {123: closed_days_ago(10)}) == [])

    # T9 — status archived, sunset past -> 0 hard, 1 ARCHIVED-SKIP.
    check("T9 archived artifact -> ARCHIVED-SKIP only",
          rtypes(fm_of(status="archived", sunset="2026-01-01"), {123: closed_days_ago(99)})
          == ["ARCHIVED-SKIP"])

    # T10 — prose work_item (no number) -> 1 INFO, no crash.
    check("T10 prose work_item -> INFO unresolvable",
          rtypes(fm_of(work_item="the token-load refactor"), {}) == ["INFO"])

    # extract_work_item unit checks (issue / milestone / epic / prose).
    check("extract_work_item parses #123",
          extract_work_item("#123") == ("issue", 123))
    check("extract_work_item parses milestone-282",
          extract_work_item("milestone-282") == ("milestone", 282))
    check("extract_work_item parses epic #877 as an issue",
          extract_work_item("epic #877") == ("issue", 877))
    check("extract_work_item returns None on prose",
          extract_work_item("the refactor") is None)

    # T11 + T13 — glob is one level deep; README excluded; nested SUMMARY ignored.
    with tempfile.TemporaryDirectory() as tmp:
        adir = os.path.join(tmp, ANALYSIS_DIR)
        good = os.path.join(adir, "audit-2026-05-01")
        os.makedirs(good)
        with open(os.path.join(good, SUMMARY_NAME), "w") as fh:
            fh.write(to_text(fm_of()))
        with open(os.path.join(good, "README.md"), "w") as fh:
            fh.write("# not a summary\n")
        with open(os.path.join(adir, "README.md"), "w") as fh:
            fh.write("# workspace readme\n")
        nested = os.path.join(adir, "audit-2026-05-01", "sub")
        os.makedirs(nested)
        with open(os.path.join(nested, SUMMARY_NAME), "w") as fh:
            fh.write(to_text(fm_of()))
        found = collect_summaries(tmp)
        check("T11 one-level glob finds exactly the top-level SUMMARY.md",
              len(found) == 1 and found[0] == os.path.join(good, SUMMARY_NAME))
        check("T13 nested analysis/x/sub/SUMMARY.md is not matched",
              all("sub" not in os.path.relpath(p, adir).split(os.sep)[1:] for p in found))

        # scan() integration: divergent-only fixture -> exit-clean, INFO-only.
        with open(os.path.join(good, SUMMARY_NAME), "w") as fh:
            fh.write(to_text(fm_of(created="2026-07-22 (Wednesday)",
                                   sunset="on execution-release close",
                                   status="complete — awaiting operator review",
                                   work_item="the token-load refactor")))
        rows_s, hard_s, scanned_s = scan(tmp, today, lambda k, n: None)
        check("scan on the live-divergent shape -> 0 hard findings",
              hard_s == 0 and scanned_s == 1)
        check("scan on the live-divergent shape -> INFO rows only",
              sorted(set(r[0] for r in rows_s)) == ["INFO"])

    # T12 — make_state_lookup(--no-gh) yields a CONFIG note + a None lookup; sunset arm still fires.
    lookup_nogh, note_nogh = make_state_lookup("owner/repo", "gh", no_gh=True)
    check("T12 --no-gh emits a CONFIG note",
          note_nogh is not None and lookup_nogh("issue", 123) is None)
    check("T12 sunset-only path still classifies under --no-gh",
          [r[0] for r in classify("fix", fm_of(sunset="2026-01-01"), today, lookup_nogh)]
          == ["STALE"])

    failed = [n for n, ok in results if not ok]
    for name, ok in results:
        print(("  PASS  " if ok else "  FAIL  ") + name)
    print("check-analysis-staleness self-test: %d/%d passed"
          % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description="Analysis-workspace staleness lint (past-sunset / missing-frontmatter).")
    ap.add_argument("--root", default=".", help="repo root (the dir that contains analysis/)")
    ap.add_argument("--repo", default=None,
                    help="owner/name slug for gh work_item-close checks; derived from origin when omitted")
    ap.add_argument("--gh-bin", default="gh", help="gh binary (default: gh)")
    ap.add_argument("--no-gh", action="store_true",
                    help="skip the work_item-close check entirely (sunset-only)")
    ap.add_argument("--archive", action="store_true",
                    help="opt-in INTERACTIVE archive/purge of flagged artifacts (never mutates without confirm)")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--output-format", choices=("tsv",), default="tsv")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = os.path.abspath(args.root)
    if not os.path.isdir(os.path.join(root, ANALYSIS_DIR)):
        print("ERROR\tno %s/ dir under %s — the tree may have moved" % (ANALYSIS_DIR, root),
              file=sys.stderr)
        return 3

    today = datetime.date.today()
    repo = derive_repo(args.repo)
    state_lookup, config_note = make_state_lookup(repo, args.gh_bin, args.no_gh)
    rows, hard, scanned = scan(root, today, state_lookup)

    out = ["SCANNED\t%d" % scanned]
    if config_note:
        out.append("CONFIG\t%s" % config_note)
    for row in rows:
        out.append("\t".join(str(x) for x in row))
    out.append("COUNT\t%d" % hard)
    print("\n".join(out))

    if args.archive:
        flagged = sorted({row[1] for row in rows if row[0] in ("STALE", "STALE-WI", "MISSING")})
        run_archive(root, flagged)

    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())

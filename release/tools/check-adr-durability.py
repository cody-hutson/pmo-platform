#!/usr/bin/env python3
"""check-adr-durability.py — ADR durability lint (#1490).

The `adr-number-integrity` gate already guards ADR *identity* (one global, gap-free
`ADR-NNN` sequence). Nothing guards ADR *durability*: a newly-authored ADR can
reintroduce a non-enum `status:` value, bake a commit SHA or a live corpus count into
durable prose, or carry the operator's literal GitHub handle. This checker is the
durability sibling — same self-tested-gate shape as `check-adr-numbers.py`, wired as a
`repo-integrity.yml` job.

THREE RULES
-----------
  R1  STATUS-ENUM      the `status:` frontmatter value's LEADING token is one of
                       Proposed | Accepted | Deprecated | Superseded. A prose tail is
                       permitted (the ratification anchor / supersession pointer) —
                       the schema's leading-token rule, not a strict closed enum.
  R2  STALE-ANCHOR     durable prose carries a hardcoded commit SHA or a live
                       corpus-population count. Both rot the moment history is
                       rewritten or the corpus grows; the durability ladder puts a
                       commit hash on its least-durable rung.
  R3  OPERATOR-HANDLE  the operator's literal GitHub handle appears anywhere in the
                       ADR. The sanctioned ADR carve-out is NAME-scoped (the literal
                       name on a `deciders:` frontmatter line, architect-of-record
                       attribution) — the HANDLE is never sanctioned, and R3 closes
                       the gap a line-scoped skip would otherwise open.

NEVER HARDCODE THE HANDLE
-------------------------
R3's subject is RESOLVED, never embedded: `--handle`, else the owner segment of
`git config --get remote.origin.url`. Unresolvable → R3 is reported SKIPPED via a
`CONFIG` row (visible, not silent) rather than scanning nothing and reading green.
This file therefore contains no operator handle, and neither does its self-test
(which drives a synthetic fixture handle).

R2 EXEMPTIONS (all structural — no per-instance judgment)
---------------------------------------------------------
  1. Fenced code blocks — stripped before scanning (a worked `git` example is not
     durable prose).
  2. The `source_observations:` frontmatter block — the schema defines it as the
     grounding evidence the decision rests on. Evidence is point-in-time BY
     CONSTRUCTION; pinning it is correct, not rot.
  3. A closed set of explicit historical-framing anchors on the line ("as of",
     "at the time", "at authoring", "at merge time", "then-current", "originally",
     …). An anchored count/SHA is a dated fact, not a live claim. Closed vocabulary,
     so the exemption is falsifiable — never a prose-similarity guess.
  4. A whole-file exemption for `Superseded` / `Deprecated` ADRs. Those records are
     frozen for the audit trail (supersede-not-edit); flagging them would demand an
     edit the immutability policy forbids.
  5. A per-file override marker, `<!-- adr-durability: allow-anchor -->`, mirroring
     the repo-integrity / reference-durability marker convention.

WARN-MODE ONLY AT THE CI SURFACE — ENFORCE-FLIP IS DEFERRED
-----------------------------------------------------------
This lint LOCKS a clean baseline; it does not create one. The ADR corpus has not yet
had its full structural-conformance pass, so an enforce-mode flip today would red-CI
the existing corpus — the exact ordering the issue's own dependency note forbids
("guarding before cleaning would red-CI the existing corpus"). The `repo-integrity.yml`
job therefore ships `WARN_MODE: 'true'`, and the flip to enforce is a POST-CONFORMANCE
shakedown step, gated on the ADR full-conformance pass landing first. The checker
itself is mode-agnostic: it always reports the true verdict via its exit code; the
warn/enforce decision lives at the CI surface.

OUTPUT (TSV) / EXIT CODES
-------------------------
  CONFIG    <note>                       # e.g. R3 skipped, handle unresolved
  SCANNED   <n>                          # ADR files examined
  R1        <path>:<line>\t<detail>      # status-enum violation
  R2-SHA    <path>:<line>\t<detail>      # hardcoded commit SHA
  R2-COUNT  <path>:<line>\t<detail>      # live corpus-population count
  R3        <path>:<line>\t<detail>      # operator handle
  EXEMPT    <path>\t<reason>             # whole-file exemption applied
  COUNT     <n>                          # total violations

  exit 0 — clean
  exit 1 — violation(s) present (or self-test failure)
  exit 3 — input failure (no ADR files resolved; the tree moved)

Python 3.9-compatible — matches /usr/bin/python3 on the operator baseline.
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

ADR_DIRS = ("core/ADRs", "release/ADRs")
ADR_GLOB_RE = re.compile(r"^ADR-\d+-.+\.md$")

# ── R1 ───────────────────────────────────────────────────────────────────────
# Leading-token rule per the ADR schema: the value MUST begin with one of the four
# Nygard tokens; an optional prose tail (ratification anchor / supersession pointer)
# follows. Not a strict closed enum — that is the schema's own wording.
STATUS_ENUM = ("Proposed", "Accepted", "Deprecated", "Superseded")
STATUS_LINE_RE = re.compile(r"^status:\s*(.*)$")
# Strip leading markdown emphasis so `status: **Accepted**` is read on its token.
EMPHASIS_LEAD_RE = re.compile(r"^[*_`\s]+")

# ── R2 ───────────────────────────────────────────────────────────────────────
# SHA: word-bounded 7–40 hex. Requiring BOTH an a-f letter AND a digit excludes pure
# decimal runs (dates, large numbers) and pure-alpha runs — the two false-positive
# families a naive `[0-9a-f]{7,40}` would import.
SHA_RE = re.compile(r"(?<![0-9a-zA-Z])([0-9a-f]{7,40})(?![0-9a-zA-Z])")

# COUNT: closed corpus-population vocabulary — the nouns whose live totals GROW, so a
# pinned number rots. Structural constants ("3 kinds", "4 tiers", "6 sections") are
# outside the vocabulary by construction, and the >=5 floor drops the residual small
# design constants that share a noun ("2 checks", "3 hooks").
#
# THREE PRECISION GUARDS, each measured against the live corpus rather than asserted
# (a naive `<n> <noun>` predicate scored ~60% false positives on the shipped ADRs):
#   (a) PLURAL-ONLY — a live count is plural ("44 skills"); a singular noun after a
#       number is nearly always a REFERENCE ("§ 6 ADR Recommendation", "Stage 12 gate",
#       "8 criterion"). The one singular form kept is the `<n> <noun> files` shape,
#       which is the exemplar failure the issue cites ("22 ADR files").
#   (b) NO IDENTIFIER PREFIX — a number glued to `-` or `.` is an identifier segment,
#       not a count ("ADR-076 gates", "v3.80 checks").
#   (c) NO REFERENCE-WORD PREFIX — a closed set of preceding tokens turns the number
#       into an ordinal reference, never a population ("Stage 12", "§ 6", "ADR 030").
POPULATION_NOUNS = (
    "ADRs", "skills", "checks", "hooks", "agents", "workflows",
    "criteria", "issues", "milestones", "gates",
)
POPULATION_SINGULAR = (
    "ADR", "skill", "check", "hook", "agent", "workflow",
    "criterion", "issue", "milestone", "gate",
)
COUNT_RE = re.compile(
    r"(?<![0-9.\-])(\d+)\s+(?:more\s+|additional\s+|live\s+|total\s+)?"
    r"(?:(" + "|".join(POPULATION_NOUNS) + r")\b"
    r"|(" + "|".join(POPULATION_SINGULAR) + r")\s+files?\b)"
)
# Preceding tokens that make the number an ORDINAL REFERENCE, not a population count.
REFERENCE_PREFIX_RE = re.compile(
    r"(?:§|§§|stage|gate|check|adr|phase|wave|tier|step|rule|section|part|"
    r"chapter|item|option|qc|v|g)\s*$",
    re.IGNORECASE,
)
COUNT_FLOOR = 5

# Closed historical-framing vocabulary. A count/SHA carrying one of these anchors on
# the same line is a DATED fact, not a live claim, so it does not rot.
HISTORICAL_ANCHORS = (
    "as of", "at the time", "at authoring", "at merge time", "at the authoring commit",
    "then-current", "originally", "at that time", "was ", "were ", "historical",
    "at authoring time", "at the time of", "point-in-time",
)

OVERRIDE_MARKER = "adr-durability: allow-anchor"
FROZEN_STATUSES = ("Superseded", "Deprecated")


def _leading_status_token(value):
    """The first bare word of a `status:` value, emphasis and quoting stripped."""
    v = EMPHASIS_LEAD_RE.sub("", value).strip()
    if not v:
        return ""
    return re.split(r"[\s,.;:(*_`]", v, 1)[0]


def strip_fences(lines):
    """Blank out fenced-code lines in place (index-preserving, so line numbers hold)."""
    out = []
    in_fence = False
    for line in lines:
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            out.append("")
            continue
        out.append("" if in_fence else line)
    return out


def source_observation_lines(lines):
    """Line indices (0-based) inside the frontmatter `source_observations:` block.

    Frontmatter is the leading `---`-delimited block; the field's value is its
    following indented / `- ` continuation lines. Point-in-time by construction.
    """
    marked = set()
    if not lines or lines[0].strip() != "---":
        return marked
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end = i
            break
    if end is None:
        return marked
    inside = False
    for i in range(1, end):
        stripped = lines[i]
        if re.match(r"^source_observations:", stripped):
            inside = True
            marked.add(i)
            continue
        if inside:
            # A continuation is indented or a list item; any other top-level key ends it.
            if stripped[:1] in (" ", "\t", "-") or not stripped.strip():
                marked.add(i)
                continue
            inside = False
    return marked


def has_historical_anchor(line):
    low = line.lower()
    return any(a in low for a in HISTORICAL_ANCHORS)


def scan_text(path, text, handle, allowed_lines=None):
    """Evaluate one ADR's text. Returns (findings, exempt_reason_or_None).

    findings — list of (rule, line_no_1based, detail).
    allowed_lines — when not None, only these 1-based line numbers may yield a
                    finding (the net-new added-lines delta posture).
    """
    findings = []
    raw = text.splitlines()
    frozen = False
    status_value = None

    # --- R1 (always evaluated; a status line is the ADR's identity field) --------
    for idx, line in enumerate(raw):
        m = STATUS_LINE_RE.match(line)
        if m:
            status_value = m.group(1)
            token = _leading_status_token(status_value)
            if token in FROZEN_STATUSES:
                frozen = True
            if token not in STATUS_ENUM:
                if allowed_lines is None or (idx + 1) in allowed_lines:
                    findings.append((
                        "R1", idx + 1,
                        "status leading token %r is outside the enum (%s)"
                        % (token, " | ".join(STATUS_ENUM)),
                    ))
            break  # frontmatter `status:` is the first one; body restatements are prose

    # --- whole-file R2 exemptions ------------------------------------------------
    exempt = None
    if OVERRIDE_MARKER in text:
        exempt = "override marker present"
    elif frozen:
        exempt = "frozen record (%s) — supersede-not-edit" % _leading_status_token(status_value or "")

    body = strip_fences(raw)
    src_obs = source_observation_lines(raw)

    for idx, line in enumerate(body):
        if not line.strip():
            continue
        lineno = idx + 1
        if allowed_lines is not None and lineno not in allowed_lines:
            continue

        # --- R3 (NOT exempt by the R2 exemptions — a handle never becomes durable) -
        if handle:
            if re.search(r"(?<![0-9A-Za-z_-])" + re.escape(handle) + r"(?![0-9A-Za-z_-])",
                         line):
                findings.append((
                    "R3", lineno,
                    "operator GitHub handle present (the ADR carve-out is NAME-scoped, "
                    "on a deciders: line only — the handle is never sanctioned)",
                ))

        if exempt is not None or idx in src_obs or has_historical_anchor(line):
            continue

        for m in SHA_RE.finditer(line):
            tok = m.group(1)
            if not (re.search(r"[a-f]", tok) and re.search(r"[0-9]", tok)):
                continue
            findings.append((
                "R2-SHA", lineno,
                "hardcoded commit SHA %r in durable prose (least-durable rung; "
                "summarize the change inline or anchor it historically)" % tok,
            ))

        for m in COUNT_RE.finditer(line):
            try:
                n = int(m.group(1))
            except ValueError:
                continue
            if n < COUNT_FLOOR:
                continue
            if REFERENCE_PREFIX_RE.search(line[:m.start(1)]):
                continue
            findings.append((
                "R2-COUNT", lineno,
                "live corpus count %r in durable prose (the population grows; cite the "
                "deriving command or anchor the number historically)" % m.group(0).strip(),
            ))

    return findings, exempt


# ── inputs ───────────────────────────────────────────────────────────────────

def derive_handle(explicit):
    """Operator GitHub handle — NEVER hardcoded.

    `--handle` wins (CI passes the run actor). Otherwise the owner segment of the
    running clone's origin remote, which is fork-correct and operator-neutral in
    source. Returns None when neither resolves.
    """
    if explicit:
        return explicit.strip() or None
    try:
        url = subprocess.run(["git", "config", "--get", "remote.origin.url"],
                             capture_output=True, text=True).stdout.strip()
        m = re.search(r"[:/]([^/]+)/[^/]+?(?:\.git)?$", url)
        if m:
            return m.group(1)
    except Exception:
        pass
    return None


def collect_adrs(root, explicit_files):
    """Absolute ADR paths to scan (explicit list, else both ADR dirs)."""
    if explicit_files:
        out = []
        for f in explicit_files:
            base = os.path.basename(f)
            if not ADR_GLOB_RE.match(base):
                continue
            p = f if os.path.isabs(f) else os.path.join(root, f)
            if os.path.isfile(p):
                out.append(p)
        return sorted(out)
    out = []
    for d in ADR_DIRS:
        full = os.path.join(root, d)
        if not os.path.isdir(full):
            continue
        for name in sorted(os.listdir(full)):
            if ADR_GLOB_RE.match(name):
                out.append(os.path.join(full, name))
    return out


def added_line_map(diff_base, paths, root):
    """{path: set(1-based added line numbers)} since `diff_base` (net-new posture)."""
    result = {}
    for p in paths:
        rel = os.path.relpath(p, root)
        try:
            diff = subprocess.run(
                ["git", "diff", "--unified=0", diff_base + "...HEAD", "--", rel],
                capture_output=True, text=True, cwd=root).stdout
        except Exception:
            result[p] = None      # cannot compute -> scan whole file (fail loud, not blind)
            continue
        lines = set()
        newln = 0
        for dl in diff.splitlines():
            if dl.startswith("@@"):
                mm = re.search(r"\+(\d+)", dl)
                newln = int(mm.group(1)) if mm else 0
                continue
            if dl.startswith("+++") or dl.startswith("---"):
                continue
            if dl.startswith("+"):
                lines.add(newln)
                newln += 1
            elif dl.startswith("-"):
                continue
        result[p] = lines
    return result


# ── self-test ────────────────────────────────────────────────────────────────

FIXTURE_HANDLE = "octo-fixture"          # synthetic; never the real operator handle


def self_test():
    results = []

    def check(name, ok):
        results.append((name, ok))

    def rules(text, handle=FIXTURE_HANDLE):
        f, _ = scan_text("fixture.md", text, handle)
        return sorted(set(r for r, _, _ in f))

    CLEAN = (
        "---\n"
        "title: ADR-999 — Fixture\n"
        "status: Accepted\n"
        "deciders: \"operator + Stage 5 spoke\"\n"
        "---\n"
        "\n"
        "# ADR-999 — Fixture\n"
        "\n"
        "## Status\n"
        "\n"
        "Accepted at the Collective Review scope-lock.\n"
    )
    check("clean ADR yields no findings", rules(CLEAN) == [])

    # R1 — a non-enum leading token.
    check("R1 fires on a non-enum status value",
          rules(CLEAN.replace("status: Accepted", "status: Draft")) == ["R1"])
    check("R1 accepts a prose tail after the enum token",
          rules(CLEAN.replace(
              "status: Accepted",
              "status: Proposed (flips to Accepted at the Stage 9 review)")) == [])
    check("R1 accepts an emphasis-wrapped enum token",
          rules(CLEAN.replace("status: Accepted", "status: **Superseded** by ADR-045")) == [])

    # R2-SHA.
    check("R2-SHA fires on a bare commit SHA in prose",
          rules(CLEAN + "\nResolved by commit f0a0516 in the prior release.\n") == ["R2-SHA"])
    check("R2-SHA ignores a pure-decimal run",
          rules(CLEAN + "\nThe identifier 12345678 is not a SHA.\n") == [])
    check("R2-SHA ignores a pure-alpha hex-letter word",
          rules(CLEAN + "\nThe deface facade is prose, not a hash.\n") == [])
    check("R2-SHA is suppressed inside a fenced code block",
          rules(CLEAN + "\n```\ngit show f0a0516\n```\n") == [])
    check("R2-SHA is suppressed by a historical anchor on the line",
          rules(CLEAN + "\nAs of commit f0a0516 the count held.\n") == [])
    check("R2-SHA is suppressed on a frozen (Superseded) record",
          rules(CLEAN.replace("status: Accepted", "status: Superseded by ADR-045")
                + "\nResolved by commit f0a0516.\n") == [])
    check("R2-SHA is suppressed by the per-file override marker",
          rules(CLEAN + "\n<!-- " + OVERRIDE_MARKER + " -->\nCommit f0a0516.\n") == [])

    # R2-COUNT.
    check("R2-COUNT fires on a live corpus count",
          rules(CLEAN + "\nThe platform carries 22 ADR files today.\n") == ["R2-COUNT"])
    check("R2-COUNT ignores a small structural constant",
          rules(CLEAN + "\nThe union has 3 kinds and 2 gates.\n") == [])
    check("R2-COUNT ignores an out-of-vocabulary noun",
          rules(CLEAN + "\nThe table carries 12 columns.\n") == [])
    check("R2-COUNT fires on the '<n> <noun> files' exemplar shape",
          rules(CLEAN + "\nThe corpus holds 22 ADR files.\n") == ["R2-COUNT"])
    # Precision guard (a) — a singular noun after a number is a reference, not a count.
    check("R2-COUNT ignores a singular noun (reference, not population)",
          rules(CLEAN + "\nSee Stage 5 spec section 6 ADR Recommendation.\n") == [])
    # Precision guard (b) — a number glued to '-' or '.' is an identifier segment.
    check("R2-COUNT ignores an identifier-prefixed number",
          rules(CLEAN + "\nADR-076 gates the surface; v3.80 checks ran.\n") == [])
    # Precision guard (c) — a closed set of preceding reference words.
    check("R2-COUNT ignores a reference-word-prefixed number",
          rules(CLEAN + "\nThe Stage 12 gates and the § 9 checks both ran.\n") == [])
    check("R2-COUNT still fires when no reference word precedes",
          rules(CLEAN + "\nThe platform deploys 44 skills.\n") == ["R2-COUNT"])
    check("R2-COUNT is suppressed by a historical anchor",
          rules(CLEAN + "\nAs of authoring there were 22 ADRs.\n") == [])
    check("R2-COUNT is suppressed inside source_observations",
          rules(CLEAN.replace(
              "---\n\n# ADR-999",
              "source_observations:\n  - \"A scan found 22 ADRs stale.\"\n---\n\n# ADR-999")) == [])

    # R3 — handle blocked everywhere; the carve-out is NAME-scoped, not handle-scoped.
    check("R3 fires on the handle in body prose",
          rules(CLEAN + "\nAuthored by " + FIXTURE_HANDLE + ".\n") == ["R3"])
    check("R3 fires on the handle even on a deciders: line (carve-out is name-scoped)",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "' + FIXTURE_HANDLE + '"')) == ["R3"])
    check("R3 passes the carved-out literal NAME on a deciders: line",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "Ada Lovelace (operator)"')) == [])
    check("R3 does not fire on a handle substring inside a longer token",
          rules(CLEAN + "\nSee " + FIXTURE_HANDLE + "-extended-token here.\n") == [])
    check("R3 is NOT suppressed by the R2 override marker",
          rules(CLEAN + "\n<!-- " + OVERRIDE_MARKER + " -->\nBy " + FIXTURE_HANDLE + ".\n")
          == ["R3"])
    check("R3 is skipped when no handle resolves (never scans nothing silently)",
          rules(CLEAN + "\nAuthored by " + FIXTURE_HANDLE + ".\n", handle=None) == [])

    # Delta posture — a finding on an unchanged line is not re-flagged.
    dirty = CLEAN + "\nCommit f0a0516 did it.\n"
    f_all, _ = scan_text("fixture.md", dirty, FIXTURE_HANDLE)
    f_delta, _ = scan_text("fixture.md", dirty, FIXTURE_HANDLE, allowed_lines=set([1]))
    check("added-lines filter suppresses a finding outside the delta",
          len(f_all) == 1 and f_delta == [])

    # Real-tree smoke: the checker resolves the shipped ADR dirs.
    with tempfile.TemporaryDirectory() as tmp:
        os.makedirs(os.path.join(tmp, "core", "ADRs"))
        with open(os.path.join(tmp, "core", "ADRs", "ADR-001-x.md"), "w") as fh:
            fh.write(CLEAN)
        check("collect_adrs finds ADR-shaped files under the ADR dirs",
              len(collect_adrs(tmp, None)) == 1)
        check("collect_adrs ignores non-ADR filenames",
              collect_adrs(tmp, ["core/ADRs/README.md"]) == [])

    failed = [n for n, ok in results if not ok]
    for name, ok in results:
        print(("  PASS  " if ok else "  FAIL  ") + name)
    print("check-adr-durability self-test: %d/%d passed"
          % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description="ADR durability lint (status enum / SHAs + counts / handle).")
    ap.add_argument("--root", default=".", help="repo root")
    ap.add_argument("--files", nargs="*", default=None,
                    help="explicit ADR paths (default: the whole ADR corpus)")
    ap.add_argument("--handle", default=None,
                    help="operator GitHub handle for R3; derived from the origin remote "
                         "owner when omitted. NEVER hardcoded in this file.")
    ap.add_argument("--diff-base", default=None,
                    help="restrict findings to lines ADDED since this ref (net-new posture)")
    ap.add_argument("--output-format", choices=("tsv",), default="tsv")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = os.path.abspath(args.root)
    paths = collect_adrs(root, args.files)
    if not paths:
        if args.files:
            # An explicit list with no ADR members is a legitimate empty scan.
            print("SCANNED\t0")
            print("COUNT\t0")
            return 0
        print("ERROR\tno ADR files resolved under %s — the ADR tree may have moved"
              % ", ".join(ADR_DIRS), file=sys.stderr)
        return 3

    out = []
    handle = derive_handle(args.handle)
    if not handle:
        out.append("CONFIG\tR3 SKIPPED — operator handle unresolved (pass --handle or "
                   "run inside a clone with an origin remote); the handle dimension "
                   "scanned nothing")

    delta = added_line_map(args.diff_base, paths, root) if args.diff_base else {}

    findings = []
    for p in paths:
        try:
            with open(p, "r", encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError as exc:
            out.append("CONFIG\tunreadable: %s (%s)" % (p, exc))
            continue
        allowed = delta.get(p) if args.diff_base else None
        f, exempt = scan_text(p, text, handle, allowed_lines=allowed)
        rel = os.path.relpath(p, root)
        if exempt:
            out.append("EXEMPT\t%s\t%s" % (rel, exempt))
        for rule, lineno, detail in f:
            findings.append((rule, rel, lineno, detail))

    out.insert(0, "SCANNED\t%d" % len(paths))
    for rule, rel, lineno, detail in findings:
        out.append("%s\t%s:%d\t%s" % (rule, rel, lineno, detail))
    out.append("COUNT\t%d" % len(findings))
    print("\n".join(out))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

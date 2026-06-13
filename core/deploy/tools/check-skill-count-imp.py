#!/usr/bin/env python3
"""Forward-looking skill-count / IMP-XXX drift detection primitive.

PR-time mirror of deploy-time deploy.sh Check 5(c) (the skill-roster /
hardcoded-count guard). Where Check 5(c) runs at deploy-time over 3 hardcoded
governance docs with a static `(19|20|21|22)` regex, this primitive runs at
PR-time over the changed-files delta with a RUNTIME-COMPUTED authority, so the
gate self-updates as the roster grows.

Two detectors (selectable via --mode {imp,count,both}; default both):

  imp detector
    For each file under {core,operations,release}/skills/*/SKILL.md, scans
    content lines (fenced code blocks excluded) and flags any live IMP-XXX
    reference ([Ii][Mm][Pp]-<digits>). A legacy audit identifier on a skill-spec
    content line is a fragile cross-reference (the IMP-NNN namespace predates the
    issue tracker and no longer resolves). Per-file override:
    `<!-- skill-count-imp: allow-imp-ref -->`.

  count detector
    Computes the authoritative roster count at runtime by counting
    `<module>/skills/*/` directories across operations, release, core (the same
    source-of-truth deploy.sh Check 5 derives EXPECTED_ROSTER from). Two
    authoritative framings are both accepted as correct, because the corpus and
    deploy.sh both use both: the PUBLIC roster (canary excluded, ADR-canonical —
    deploy.sh Check 5(c)'s enum caps at 22) and the DIRECTORY count (canary
    included — deploy.sh's Check 5 OK message counts "across
    operations/release/core/canary"; the v1.08 plan records "23 SKILL.md dirs").
    A roster-TOTAL claim on a changed line whose number equals NEITHER framing is
    flagged as drift. The claim shape is deliberately TIGHT (a totalizing
    qualifier is required — "all N skills", "N PMO skills", "N skills total", …)
    because the corpus uses bare "N skills" pervasively for subtotals,
    module-counts, and different populations (e.g. "6 skills", "13 skills consume
    PROJECT.md", "9 skills" for an Anthropic pack) that are NOT roster totals and
    must not be flagged. Before/after example forms ("20 custom skills -> 19")
    and the per-file override `<!-- skill-count-imp: allow-count -->` are skipped.

Scope discipline: the WORKFLOW passes only the added-lines delta of changed
files (the reference-durability.yml idiom). This primitive therefore never sees
CLOSED-issue history or pre-existing corpus rot — the R-S3 mitigation is
structural (delta scope), not an exemption list. When invoked directly on whole
files (e.g. for a local audit) it scans every content line.

Exit codes (matching the check-doc-links.py family convention):
  0  no findings
  1  finding(s)
  2  input / argument error
  3  a declared --files entry that should be readable but cannot be read
     (fail-loud: a relocated/renamed scan surface must not read green)

Authored under the Stage 5 spec (issue #130, release cross-reference-integrity-ci).
Ships warn-mode-initial — the workflow downgrades exit 1 to a warning during the
shakedown window per core/rules/bypass-mode-readiness.md.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Repo root: this file lives at <root>/core/deploy/tools/check-skill-count-imp.py,
# so parents[3] is the repository root (same idiom as check-doc-links.py).
WORKSPACE_ROOT = Path(__file__).resolve().parents[3]

# Modules whose skills/*/ directories form the roster (deploy.sh Check 5 scope).
ROSTER_MODULES = ("operations", "release", "core")

# Canary skill name (source-only per ADR-04; excluded from the PUBLIC roster but
# present as a directory, so it is the +1 that separates the two framings).
CANARY_SKILL_NAME = "pmo-skill-refiner-selftest-canary"

# IMP-XXX matcher: case-insensitive IMP- immediately followed by one-or-more
# digits. The form the originating v11.01e audit used (documented in #130's own
# body). Applied to skill-spec content lines only (fenced code excluded), where
# the false-positive cases that worried that audit (path components, sed
# patterns) do not occur.
IMP_RE = re.compile(r"[Ii][Mm][Pp]-[0-9]+")

# Skill-spec glob arms (mirrors reference-durability.yml is_durable() and
# deploy.sh Check 5 scope). A changed file matches if its POSIX path matches.
SKILL_SPEC_RE = re.compile(r"^(?:core|operations|release)/skills/[^/]+/SKILL\.md$")

# ---------------------------------------------------------------------------
# Count-detector recall surface (issue #130 DT F3 — intentional + documented).
#
# The count detector trades recall for precision: a totalizing qualifier is
# REQUIRED so that bare "N skills" subtotals / module-counts / other-population
# counts (which the corpus uses pervasively and legitimately) are never flagged.
# This makes the recall boundary a deliberate design choice, enumerated here so
# it is visible and intentional rather than accidental.
#
# IS caught (a WRONG roster total in any of these totalizing forms fires):
#   - "all [of the] N skills"                 e.g. "all 20 PMO skills"
#   - "every one of the N skills"             e.g. "every one of the 25 skills"
#   - "N PMO skills" / "N platform skills"    (the qualifier itself totalizes)
#   - "N skills total" / "N skills in total"
#   - "total of N skills"
#   - "the platform's N skills" / "the platform has N skills"   (F3)
#   - "the N-skill suite|roster|set|platform|catalog"           (F3)
#   - "the full|complete|entire|whole roster|set|suite|... of N skills"  (F3)
#   - "N skills in the suite|roster|set|platform|catalog"       (F3)
#
# Is NOT caught (deliberate boundaries — flagging these would risk a
# false-positive on a legitimate non-roster mention, so they are left to the
# `allow-count` override or a corrected number, not forced into the matcher):
#   - bare "N skills" with no totalizer        — pervasive subtotal/module form
#                                                 ("6 skills", "13 skills consume
#                                                 PROJECT.md", "9 skills" for a pack)
#   - "N custom skills" with no other totalizer — "custom" alone is treated as a
#                                                 scoped subset, not a roster total
#   - "N skills" inside a fenced code block      — excluded structurally
#   - any before/after example with an arrow     — EXAMPLE_ARROW_RE (either order)
#   - a number written as words ("nineteen skills") — out of scope by design
# A roster total phrased outside these shapes can still be guarded explicitly
# with `<!-- skill-count-imp: allow-count -->` if a future author needs it.
# ---------------------------------------------------------------------------
#
# Roster-TOTAL claim shapes. Each alternative captures the integer in one group;
# _claimed_int() returns the first non-empty group. Ordered most-specific first.
_COUNT_CLAIM_PATTERNS = (
    # "all [of the] N [PMO|platform|custom] skills"
    r"\ball\s+(?:of\s+the\s+)?([0-9]{1,3})\s+(?:PMO\s+|platform\s+|custom\s+)?skills?\b",
    # "every one of the N [PMO|platform|custom] skills"
    r"\bevery\s+one\s+of\s+the\s+([0-9]{1,3})\s+(?:PMO\s+|platform\s+|custom\s+)?skills?\b",
    # "N PMO skills" / "N platform skills" (the qualifier itself totalizes)
    r"\b([0-9]{1,3})\s+(?:PMO|platform)\s+skills?\b",
    # "N skills total" / "N skills in total"
    r"\b([0-9]{1,3})\s+skills?\s+(?:in\s+)?total\b",
    # "total of N [PMO|platform|custom] skills"
    r"\btotal\s+of\s+([0-9]{1,3})\s+(?:PMO\s+|platform\s+|custom\s+)?skills?\b",
    # (F3) "the platform's N skills" / "the platform has N skills"
    r"\bthe\s+platform(?:'s|\s+has)\s+([0-9]{1,3})\s+(?:PMO\s+|platform\s+|custom\s+)?skills?\b",
    # (F3) "the N-skill suite|roster|set|platform|catalog[ue]"
    r"\bthe\s+([0-9]{1,3})-skill\s+(?:suite|roster|set|platform|catalog(?:ue)?)\b",
    # (F3) "the full|complete|entire|whole roster|set|suite|collection|catalog|lineup of N skills"
    r"\bthe\s+(?:full|complete|entire|whole)\s+(?:roster|set|suite|collection|catalog(?:ue)?|lineup|line-up)\s+of\s+([0-9]{1,3})\s+(?:PMO\s+|platform\s+|custom\s+)?skills?\b",
    # (F3) "N skills in the suite|roster|set|platform|catalog[ue]"
    r"\b([0-9]{1,3})\s+skills?\s+in\s+the\s+(?:suite|roster|set|platform|catalog(?:ue)?)\b",
)
COUNT_CLAIM_RE = re.compile("(?:%s)" % "|".join(_COUNT_CLAIM_PATTERNS), re.IGNORECASE)

# Before/after example form: an arrow (->, →, –, —, en/em dash) joining two
# numbers near "skills" denotes a documented cardinality-change example and is
# NOT a current-state claim. The example may be written in EITHER ordering and
# both must be recognized (issue #130 DT F1):
#   skills AFTER the arrow:  "20 -> 19 skills"
#   skills BEFORE the arrow: "all 20 PMO skills -> 19" / "20 custom skills -> 19"
# Without the skills-before-arrow arm, a legitimate totalizer-form before/after
# example ("all 20 PMO skills -> 19") matched COUNT_CLAIM_RE (the totalizer
# fires) but escaped the guard, producing a false-positive. An arrow MUST be
# present for the guard to apply, so a real current-state drift claim with no
# arrow ("all 19 PMO skills") still fires.
EXAMPLE_ARROW_RE = re.compile(
    r"(?:"
    # skills AFTER the arrow
    r"[0-9]+\s*(?:->|→|–|—)\s*[0-9]+\s*(?:custom\s+|PMO\s+|platform\s+)?skills?"
    r"|"
    # skills BEFORE the arrow (totalizer or bare-qualifier form)
    r"[0-9]+\s+(?:custom\s+|PMO\s+|platform\s+)?skills?\s*(?:->|→|–|—)\s*[0-9]+"
    r")",
    re.IGNORECASE,
)

# Per-file override markers (HTML comments; matched anywhere in the file body).
ALLOW_IMP_RE = re.compile(r"<!--\s*skill-count-imp:\s*allow-imp-ref\s*-->")
ALLOW_COUNT_RE = re.compile(r"<!--\s*skill-count-imp:\s*allow-count\s*-->")


def compute_authoritative_counts(repo_root: Path):
    """Return (public_count, with_canary_count) computed from the live tree.

    public_count    = directories under {operations,release,core}/skills/
                      excluding the canary (the ADR-canonical public roster).
    with_canary_count = public_count + 1 if the canary directory exists
                      (the directory-count framing deploy.sh's OK message and
                      the release log use).
    """
    public = 0
    canary_present = False
    for module in ROSTER_MODULES:
        skills_dir = repo_root / module / "skills"
        if not skills_dir.is_dir():
            continue
        for child in sorted(skills_dir.iterdir()):
            if not child.is_dir():
                continue
            if child.name == CANARY_SKILL_NAME:
                canary_present = True
                continue
            public += 1
    with_canary = public + (1 if canary_present else 0)
    return public, with_canary


def strip_fenced_code(lines):
    """Yield (line_number, text) for content lines OUTSIDE fenced code blocks.

    A line whose stripped text starts with ``` or ~~~ toggles the fence and is
    itself excluded. Fence lines and fenced content do not yield, but the line
    counter still advances so reported line numbers match the file.
    """
    in_fence = False
    for idx, raw in enumerate(lines, start=1):
        stripped = raw.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        yield idx, raw


def _claimed_int(match):
    for g in match.groups():
        if g:
            return int(g)
    return None


def scan_imp(path_str, text):
    """Return list of (line_no, line_text) for live IMP-XXX on content lines."""
    if ALLOW_IMP_RE.search(text):
        return []
    findings = []
    for line_no, line in strip_fenced_code(text.splitlines()):
        if IMP_RE.search(line):
            findings.append((line_no, line))
    return findings


def scan_count(text, valid_counts):
    """Return list of (line_no, line_text, claimed) for stale roster-total claims.

    Flags a content line iff it carries a roster-TOTAL claim whose number is not
    in valid_counts AND the line is not a before/after example AND the file does
    not carry the allow-count override.
    """
    if ALLOW_COUNT_RE.search(text):
        return []
    findings = []
    for line_no, line in strip_fenced_code(text.splitlines()):
        if EXAMPLE_ARROW_RE.search(line):
            continue
        m = COUNT_CLAIM_RE.search(line)
        if not m:
            continue
        claimed = _claimed_int(m)
        if claimed is None:
            continue
        if claimed not in valid_counts:
            findings.append((line_no, line, claimed))
    return findings


def read_file(repo_root: Path, rel_path: str):
    """Read a declared file. Returns text, or raises FileNotFoundError to signal
    a fail-loud exit-3 condition (a declared scan surface that cannot be read)."""
    p = (repo_root / rel_path)
    if not p.exists():
        raise FileNotFoundError(rel_path)
    return p.read_text(encoding="utf-8", errors="replace")


def parse_file_list(raw):
    """Split a --files value on commas and/or newlines into clean rel-paths."""
    if not raw:
        return []
    parts = re.split(r"[,\n]+", raw)
    return [p.strip() for p in parts if p.strip()]


def emit(findings_imp, findings_count, public, with_canary, output_format):
    lines = []
    if output_format == "github":
        for path_str, line_no, line in findings_imp:
            lines.append(
                "::error file=%s,line=%d::live IMP-XXX in skill spec: %s"
                % (path_str, line_no, line.strip())
            )
        for path_str, line_no, line, claimed in findings_count:
            lines.append(
                "::error file=%s,line=%d::skill-count claim %d != authoritative "
                "roster (%d public / %d incl. canary): %s"
                % (path_str, line_no, claimed, public, with_canary, line.strip())
            )
    else:  # tsv
        for path_str, line_no, line in findings_imp:
            lines.append("imp\t%s\t%d\t%s" % (path_str, line_no, line.strip()))
        for path_str, line_no, line, claimed in findings_count:
            lines.append(
                "count\t%s\t%d\t%d\t%s" % (path_str, line_no, claimed, line.strip())
            )
    return "\n".join(lines)


def run_self_test():
    """Self-test the detector precision invariants. Exit non-zero on any miss."""
    failures = []

    # Use a stable synthetic authority so the test does not depend on the live
    # tree: pretend public=22, with_canary=23.
    valid = {22, 23}

    # (a) IMP-079 on a skill-spec content line flags.
    if not scan_imp("x/skills/y/SKILL.md", "See IMP-079 for the prior audit."):
        failures.append("(a) IMP-079 should flag on a skill-spec content line")

    # (b) IMP-### (placeholder, no digits) does NOT flag.
    if scan_imp("x/skills/y/SKILL.md", "The form is IMP-### (a placeholder)."):
        failures.append("(b) IMP-### placeholder should NOT flag")

    # (c) IMP-001 inside a fenced code block does NOT flag.
    fenced = "intro\n```\nIMP-001 example token\n```\noutro\n"
    if scan_imp("x/skills/y/SKILL.md", fenced):
        failures.append("(c) IMP-001 inside a code fence should NOT flag")

    # (c2) allow-imp-ref override suppresses an otherwise-flagging IMP ref.
    if scan_imp("x/skills/y/SKILL.md", "<!-- skill-count-imp: allow-imp-ref -->\nIMP-079 cited."):
        failures.append("(c2) allow-imp-ref override should suppress the IMP finding")

    # (d) "20 skills" flags when 20 not in {22,23}; "23 skills" / "all 22 PMO
    #     skills" do not.
    if not scan_count("We ship all 20 skills now.", valid):
        failures.append("(d1) 'all 20 skills' should flag when 20 not in authority")
    if scan_count("Every one of the 23 skills carries an entry.", valid):
        failures.append("(d2) '23 skills' should pass (in authority)")
    if scan_count("All 22 PMO skills apply this protocol.", valid):
        failures.append("(d3) '22 PMO skills' should pass (in authority)")

    # (d4) bare "N skills" subtotal (no totalizing qualifier) does NOT flag even
    #      when N is out of authority — the shape requires a totalizer.
    if scan_count("13 skills consume PROJECT.md.", valid):
        failures.append("(d4) bare '13 skills' subtotal should NOT flag (no totalizer)")
    if scan_count("apply suite-wide guardrails to all 6 skills.", valid):
        # 'all 6 skills' DOES match the totalizing shape and 6 is out of
        # authority, so this is an expected TRUE finding shape — assert it flags
        # (the override marker is the documented escape for a legitimately-scoped
        # subtotal that uses a totalizer).
        pass
    else:
        failures.append("(d5) 'all 6 skills' (totalizer, out-of-authority) should flag")

    # (e) before/after example "20 custom skills -> 19" does NOT flag. This
    #     string is suppressed by the count-shape (no totalizer matches bare
    #     "N custom skills"), NOT by the arrow-guard — so (e) alone does not
    #     exercise EXAMPLE_ARROW_RE. (e3) below covers the guard genuinely.
    if scan_count("e.g. 20 custom skills -> 19 in the header", valid):
        failures.append("(e) example form '20 custom skills -> 19' should NOT flag")

    # (e2) allow-count override suppresses an otherwise-flagging count claim.
    if scan_count("<!-- skill-count-imp: allow-count -->\nAll 8 skills defined.", valid):
        failures.append("(e2) allow-count override should suppress the count finding")

    # (e3) ARROW-GUARD EXERCISE (issue #130 DT F1/F2). A totalizer-form
    #      before/after example with skills BEFORE the arrow ("all 20 PMO skills
    #      -> 19") DOES match COUNT_CLAIM_RE (the 'all N PMO skills' totalizer
    #      fires) — so it would be a false-positive unless EXAMPLE_ARROW_RE
    #      suppresses it. This case therefore genuinely tests the arrow-guard
    #      (unlike (e), where the count-shape never matched in the first place).
    if not COUNT_CLAIM_RE.search("Historically all 20 PMO skills -> 19 after the split."):
        failures.append(
            "(e3-pre) precondition broken: 'all 20 PMO skills -> 19' must match "
            "COUNT_CLAIM_RE so the arrow-guard is what suppresses it"
        )
    if scan_count("Historically all 20 PMO skills -> 19 after the split.", valid):
        failures.append(
            "(e3) totalizer-before-arrow example 'all 20 PMO skills -> 19' should "
            "NOT flag (arrow-guard must recognize skills-before-arrow ordering)"
        )

    # (e4) F3 RECALL-SURFACE EXERCISE (issue #130 DT F3). A WRONG roster total in
    #      a totalizing framing added under F3 ("the platform's N skills") must
    #      fire; the same framing with a CORRECT total must pass. This protects
    #      the broadened recall surface against silent regression.
    if not scan_count("Today the platform's 19 skills are deployed.", valid):
        failures.append(
            "(e4a) F3 framing \"the platform's 19 skills\" should flag (19 not in authority)"
        )
    if scan_count("Today the platform's 22 skills are deployed.", valid):
        failures.append(
            "(e4b) F3 framing \"the platform's 22 skills\" should pass (22 in authority)"
        )
    if not scan_count("The full roster of 19 skills shipped.", valid):
        failures.append(
            "(e4c) F3 framing 'the full roster of 19 skills' should flag (19 not in authority)"
        )

    if failures:
        sys.stderr.write("self-test FAILED:\n")
        for f in failures:
            sys.stderr.write("  - %s\n" % f)
        return 1

    sys.stdout.write("self-test OK (16 invariants passed)\n")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Forward-looking skill-count / IMP-XXX drift detector "
        "(PR-time mirror of deploy.sh Check 5(c))."
    )
    parser.add_argument(
        "--files",
        default="",
        help="Comma- or newline-separated list of repo-relative file paths to "
        "scan as WHOLE files (the local-audit form). Each path is read from "
        "--repo-root and scanned in full. For the PR-time delta scan, the "
        "workflow uses --scan-pair instead.",
    )
    parser.add_argument(
        "--scan-pair",
        action="append",
        default=[],
        metavar="REALPATH::=::CONTENTFILE",
        help="Scan injected content while attributing it to a real repo path. "
        "Format: '<real-repo-relative-path>::=::<path-to-a-file-holding-the-"
        "content-to-scan>'. The workflow writes each changed file's ADDED-lines "
        "delta to CONTENTFILE and passes the real path so glob-matching "
        "(skill-spec scope) and finding attribution use the true path, while the "
        "scanned bytes are the net-new delta only. Repeatable.",
    )
    parser.add_argument(
        "--mode",
        choices=("imp", "count", "both"),
        default="both",
        help="Which detector(s) to run (default: both).",
    )
    parser.add_argument(
        "--repo-root",
        default=str(WORKSPACE_ROOT),
        help="Repository root (default: resolved from this file's location).",
    )
    parser.add_argument(
        "--output-format",
        choices=("github", "tsv"),
        default="github",
        help="Finding output format (default: github Actions annotations).",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run the detector precision self-test and exit.",
    )
    args = parser.parse_args(argv)

    if args.self_test:
        return run_self_test()

    repo_root = Path(args.repo_root).resolve()
    public, with_canary = compute_authoritative_counts(repo_root)
    valid_counts = {public, with_canary}

    # Build the scan work-list: each item is (real_repo_path, content_text,
    # line_offset_mode). Two sources:
    #   --files       whole-file reads from repo_root (local-audit form)
    #   --scan-pair   injected content (the PR-time delta), attributed to a real
    #                 path. The content file may carry "<true-line>\t<text>" rows
    #                 (the workflow's map_added_lines output) so reported line
    #                 numbers stay in true-file-line space.
    work = []  # (real_path, content_text, line_index_map_or_None)
    unreadable = []

    for rel_path in parse_file_list(args.files):
        try:
            text = read_file(repo_root, rel_path)
        except FileNotFoundError:
            unreadable.append(rel_path)
            continue
        work.append((rel_path, text, None))

    for pair in args.scan_pair:
        if "::=::" not in pair:
            sys.stderr.write(
                "ERROR (exit 2): --scan-pair must be "
                "'<real-path>::=::<content-file>' (got: %s)\n" % pair
            )
            return 2
        real_path, content_file = pair.split("::=::", 1)
        real_path = real_path.strip()
        content_file = content_file.strip()
        cf = Path(content_file)
        if not cf.exists():
            unreadable.append(content_file)
            continue
        raw = cf.read_text(encoding="utf-8", errors="replace")
        # Decode optional "<true-line>\t<text>" prefix into a line-number map.
        line_map = {}
        plain_lines = []
        for i, row in enumerate(raw.splitlines(), start=1):
            mm = re.match(r"^([0-9]+)\t(.*)$", row)
            if mm:
                plain_lines.append(mm.group(2))
                line_map[i] = int(mm.group(1))
            else:
                plain_lines.append(row)
                line_map[i] = i
        work.append((real_path, "\n".join(plain_lines), line_map))

    findings_imp = []   # (path_str, line_no, line)
    findings_count = []  # (path_str, line_no, line, claimed)

    for real_path, text, line_map in work:
        def _true(n):
            return line_map.get(n, n) if line_map else n

        if args.mode in ("imp", "both") and SKILL_SPEC_RE.match(real_path):
            for line_no, line in scan_imp(real_path, text):
                findings_imp.append((real_path, _true(line_no), line))

        if args.mode in ("count", "both") and real_path.endswith(".md"):
            for line_no, line, claimed in scan_count(text, valid_counts):
                findings_count.append((real_path, _true(line_no), line, claimed))

    if not work and not unreadable:
        # No changed files to scan — clean.
        return 0

    if unreadable:
        sys.stderr.write(
            "ERROR (exit 3): declared --files entr%s could not be read "
            "(relocated/renamed scan surface must not read green):\n"
            % ("y" if len(unreadable) == 1 else "ies")
        )
        for u in unreadable:
            sys.stderr.write("  - %s\n" % u)
        return 3

    out = emit(findings_imp, findings_count, public, with_canary, args.output_format)
    if findings_imp or findings_count:
        if out:
            print(out)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

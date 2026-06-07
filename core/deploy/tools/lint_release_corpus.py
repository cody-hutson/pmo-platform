#!/usr/bin/env python3
"""Release-corpus integrity validator for deploy.sh Check 20.

Per the v11.04b-3 D5 Stage 5 spec; extended with the note-content
checks from release-notes-standard.md §3.2 (checks 9-12). Check 15
(release-corpus cross-link integrity) was RETIRED in v2; this validator is
wired to Check 20 (note-content lint).

Validates:

  (a) Filename naming regex compliance on releases/plans/ (with allowlist
      for 3 grandfathered exceptions: v11.01-Z, v11.01-I phase plans + the
      v10.3_retrospective_validation analysis artifact).
  (b) Frontmatter schema validity on plans + notes (forward-only from
      v11.04b-3 per D2 phasing — pre-v11.04b-3 files exempt until the F-3
      backfill).
  (c) INDEX surface row count >= LOG entry count.
  (d) Frontmatter `type:` field matches filename type-suffix (Tier 3
      discriminator coherence per release-corpus-schema.md).
  (e) Note-content lint (release-notes-standard.md §3.2 checks 9-12):
      - 9: Section 6a present with >=1 bullet or 'No user-visible' placeholder
      - 10: Banned-jargon scan (§2.4 deny-list)
      - 11: 'Why it matters:' beat present per Section 6a bullet
            (or <!-- impact:foundational --> escape marker)
      - 12: No raw file paths in Section 6a bullet bodies
      Floored at the lowest live version family (v1.x) per NOTE_CONTENT_CUTOVER.

This validator handles the schema/structural checks that go beyond link
resolution. (The doc-link primitive `check-doc-links.py` covers cross-link
resolution separately under Check 14; Check 15 was retired in v2.)

Authored under the v11.04b-3 D5 deliverable; lives at
core/deploy/tools/lint_release_corpus.py per the established engineering
tooling location. Corpus paths target the live modular-monolith layout
(release/releases/...).

Usage:
    python3 core/deploy/tools/lint_release_corpus.py
    python3 core/deploy/tools/lint_release_corpus.py --check filename
    python3 core/deploy/tools/lint_release_corpus.py --check schema
    python3 core/deploy/tools/lint_release_corpus.py --check index
    python3 core/deploy/tools/lint_release_corpus.py --check type-coherence
    python3 core/deploy/tools/lint_release_corpus.py --check note-content

Exit codes: 0 = pass, 1 = content findings (one or more checks failed),
3 = path-resolution failure (a required corpus dir/file did not resolve —
CORPUS-PATH-UNRESOLVED — the surface is unverifiable, not clean). Exit 3
matches the cross-module-audit.sh family convention (per #459).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
# Live modular-monolith layout (post-restructure). The pre-restructure
# pmo-platform/... prefix is DEAD — the corpus lives under release/releases/.
# Note: RELEASE_LOG.md is under release/releases/ (NOT governance/).
PLANS_DIR = WORKSPACE_ROOT / "release" / "releases" / "plans"
NOTES_DIR = WORKSPACE_ROOT / "release" / "releases" / "notes"
INDEX_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_INDEX.md"
LOG_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_LOG.md"

CANONICAL_FILENAME_RE = re.compile(
    r"^v[0-9]+\.[0-9]+[a-z]?(-[0-9]+)?(-[0-9a-z][-0-9a-z]*)?_(RELEASE_PLAN|RELEASE_NOTES)\.md$"
)

FILENAME_ALLOWLIST = {
    "v11.01-Z_PHASE_PLAN.md",
    "v11.01-I_PHASE_PLAN.md",
    "v10.3_retrospective_validation.md",
}

CUTOVER_RELEASES = {"v11.04b-3", "v11.04b-3-doc-cleanup"}

REQUIRED_FIELDS = {"version", "date", "type", "issues", "pr", "links"}
TYPE_VALUES = {"plan", "note", "abandoned-plan", "phase-plan", "audit-plan"}

# Note-content lint (release-notes-standard.md §3.2 checks 9-12).
#
# Cutover floor reset to (1, 0, "", 0) for the re-versioned modular-monolith
# corpus: every live note is in the v1.x / v3.x families, all of which are
# BELOW the prior (11, 18) floor — so the old floor skipped all 11 live notes
# and Check 20 passed vacuously even with correct paths. The §3.2 content
# discipline is forward-going; the re-versioned corpus has no pre-standard
# legacy to grandfather, so the floor is the lowest live family (v1.x) and the
# exempt set is empty. (Version-less notes parse to (0,0,'',0) and stay below
# (1,0) — a known, accepted boundary: version-less notes predate the version-
# keyed convention; linting them needs a version-less branch, not a floor change.)
NOTE_CONTENT_CUTOVER = (1, 0, "", 0)
PRE_CUTOVER_EXEMPT_VERSIONS: set[str] = set()
SECTION_6A_HEADER_RE = re.compile(r"^##\s+What changed for everyone", re.IGNORECASE)
NEXT_H2_RE = re.compile(r"^##\s+")
VERSION_KEY_RE = re.compile(r"^v(\d+)\.(\d+)([a-z])?(?:-(\d+))?")

# §2.4 banned-jargon deny-list — literal substrings, case-insensitive.
BANNED_JARGON_LITERAL = [
    "reflexive-pipeline self-exemption",
    "mirror byte-identity",
    "warn-mode posture",
    "warn-mode initially",
    "cutover effective date",
    "all-or-nothing rule",
    "structurally gate-blocking",
    "sub-window mutability",
    "disjoint scope",
    "forward-only",
    "reflexive-pipeline loop",
]

# §2.4 banned-jargon deny-list — regex patterns for parameterized terms.
BANNED_JARGON_REGEX = [
    (re.compile(r"schema v\d+\.\d+\s*(?:→|->)\s*v\d+\.\d+", re.IGNORECASE), "schema vX.Y → vX.Z"),
    (re.compile(r"\bcollective review CR-", re.IGNORECASE), "collective review CR-X"),
    (re.compile(r"\bgate-blocking\b", re.IGNORECASE), "gate-blocking"),
    (re.compile(r"\breversibility tier\b", re.IGNORECASE), "reversibility tier (standalone phrase)"),
]


# Sentinel prefix for path-resolution-failure findings. main() maps any finding
# carrying this prefix to exit 3 (path-config error) per the #459 fail-loud
# contract — distinct from content findings (exit 1) and clean (exit 0).
CORPUS_PATH_UNRESOLVED_PREFIX = "CORPUS-PATH-UNRESOLVED"


def _rel(path: Path) -> str:
    """Repo-root-relative display string; defensive against paths outside root.

    All corpus dirs resolve inside WORKSPACE_ROOT in normal operation, but a
    misconfigured path could sit outside it; relative_to() would then raise
    ValueError. Fall back to the absolute path string so a path-resolution
    finding never crashes the linter (Mode-3 robustness, per the Stage 5 spec).
    """
    try:
        return str(path.relative_to(WORKSPACE_ROOT))
    except ValueError:
        return str(path)


def parse_frontmatter(text: str) -> dict | None:
    """Naive YAML frontmatter parser. Returns dict or None if absent."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    end = None
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end = i
            break
    if end is None:
        return None
    body = lines[1:end]
    fm: dict = {}
    current_key = None
    for line in body:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[0] in (" ", "\t") and current_key is not None:
            stripped = line.strip()
            if isinstance(fm.get(current_key), dict):
                if ":" in stripped:
                    k, v = stripped.split(":", 1)
                    fm[current_key][k.strip()] = v.strip()
            continue
        if ":" in line:
            key, val = line.split(":", 1)
            key = key.strip()
            val = val.strip()
            if not val:
                fm[key] = {}
                current_key = key
            else:
                fm[key] = val
                current_key = key
    return fm


def is_post_cutover(version: str) -> bool:
    """Returns True if the release version is at or after v11.04b-3 (post-cutover)."""
    if version in CUTOVER_RELEASES:
        return True
    if not version.startswith("v"):
        return False
    return False


def check_filename_compliance() -> list[str]:
    findings: list[str] = []
    if not PLANS_DIR.exists():
        # A missing corpus dir is a PATH-RESOLUTION FAILURE, not a clean pass:
        # silently returning [] is the exact vacuous-pass #83 fixes. Emit a
        # distinct finding so main() can exit 3 (path-config error) rather than
        # let Check 20 read GREEN against a non-existent surface.
        return [f"CORPUS-PATH-UNRESOLVED: plans dir does not resolve at {_rel(PLANS_DIR)} — corpus path misconfigured"]
    for path in sorted(PLANS_DIR.glob("*.md")):
        name = path.name
        if name in FILENAME_ALLOWLIST:
            continue
        if not CANONICAL_FILENAME_RE.match(name):
            findings.append(f"FILENAME-NONCOMPLIANT: {_rel(path)} does not match canonical regex; add to FILENAME_ALLOWLIST if intentional")
    return findings


def check_schema_validity() -> list[str]:
    findings: list[str] = []
    for directory in (PLANS_DIR, NOTES_DIR):
        if not directory.exists():
            findings.append(f"{CORPUS_PATH_UNRESOLVED_PREFIX}: corpus dir does not resolve at {_rel(directory)} — corpus path misconfigured")
            continue
        for path in sorted(directory.glob("v11.04b-3*.md")):
            text = path.read_text(encoding="utf-8")
            fm = parse_frontmatter(text)
            rel = _rel(path)
            if fm is None:
                findings.append(f"SCHEMA-MISSING: {rel} is post-cutover (v11.04b-3+) but lacks YAML frontmatter")
                continue
            missing = REQUIRED_FIELDS - set(fm.keys())
            if missing:
                findings.append(f"SCHEMA-MISSING-FIELDS: {rel} missing required field(s): {sorted(missing)}")
            type_val = fm.get("type", "")
            if type_val and type_val not in TYPE_VALUES:
                findings.append(f"SCHEMA-INVALID-TYPE: {rel} has type='{type_val}', expected one of {sorted(TYPE_VALUES)}")
    return findings


def check_index_row_count() -> list[str]:
    findings: list[str] = []
    if not LOG_PATH.exists() or not INDEX_PATH.exists():
        # Either surface missing is a PATH-RESOLUTION FAILURE (the row-count gate
        # cannot run). Emit CORPUS-PATH-UNRESOLVED so main() exits 3 rather than
        # silently returning a near-empty finding set.
        if not LOG_PATH.exists():
            findings.append(f"{CORPUS_PATH_UNRESOLVED_PREFIX}: RELEASE_LOG.md does not resolve at {_rel(LOG_PATH)} — corpus path misconfigured")
        if not INDEX_PATH.exists():
            findings.append(f"{CORPUS_PATH_UNRESOLVED_PREFIX}: RELEASE_INDEX.md does not resolve at {_rel(INDEX_PATH)} — corpus path misconfigured")
        return findings
    log_rows = sum(1 for line in LOG_PATH.read_text().splitlines() if re.match(r"^\| v[0-9]", line))
    index_rows = sum(1 for line in INDEX_PATH.read_text().splitlines() if re.match(r"^\| v[0-9]", line))
    if index_rows < log_rows:
        findings.append(f"INDEX-COUNT-LOW: RELEASE_INDEX.md has {index_rows} version-rows; RELEASE_LOG.md has {log_rows} — INDEX is stale, regenerate via generate_release_index.py")
    return findings


def check_type_coherence() -> list[str]:
    findings: list[str] = []
    for directory, expected_type in ((PLANS_DIR, "plan"), (NOTES_DIR, "note")):
        if not directory.exists():
            findings.append(f"{CORPUS_PATH_UNRESOLVED_PREFIX}: corpus dir does not resolve at {_rel(directory)} — corpus path misconfigured")
            continue
        for path in sorted(directory.glob("v11.04b-3*.md")):
            text = path.read_text(encoding="utf-8")
            fm = parse_frontmatter(text)
            if fm is None:
                continue
            rel = _rel(path)
            type_val = fm.get("type", "")
            if not type_val:
                continue
            name = path.name
            if expected_type == "plan" and type_val == "plan":
                if not name.endswith("_RELEASE_PLAN.md"):
                    findings.append(f"TYPE-MISMATCH: {rel} type='plan' but filename does not end with _RELEASE_PLAN.md")
            elif expected_type == "note" and type_val == "note":
                if not name.endswith("_RELEASE_NOTES.md"):
                    findings.append(f"TYPE-MISMATCH: {rel} type='note' but filename does not end with _RELEASE_NOTES.md")
    return findings


def version_tuple(version_or_filename: str) -> tuple:
    """Parse 'v11.18' or 'v11.04b-3' or 'v12.09_RELEASE_NOTES.md' to a sortable tuple."""
    m = VERSION_KEY_RE.match(version_or_filename)
    if not m:
        return (0, 0, "", 0)
    major = int(m.group(1))
    minor = int(m.group(2))
    suffix = m.group(3) or ""
    sub = int(m.group(4)) if m.group(4) else 0
    return (major, minor, suffix, sub)


def extract_section_6a(text: str) -> str | None:
    """Return body of '## What changed for everyone…' section, or None if header absent."""
    lines = text.splitlines()
    start = None
    for i, line in enumerate(lines):
        if SECTION_6A_HEADER_RE.match(line):
            start = i + 1
            break
    if start is None:
        return None
    end = len(lines)
    for i in range(start, len(lines)):
        if NEXT_H2_RE.match(lines[i]):
            end = i
            break
    return "\n".join(lines[start:end])


def parse_bullets(section_text: str) -> list[str]:
    """Group lines into top-level bullets (lines starting with '- ' at column 0)."""
    bullets: list[str] = []
    current: str | None = None
    for line in section_text.splitlines():
        if line.startswith("- "):
            if current is not None:
                bullets.append(current)
            current = line[2:]
        elif current is not None and (line.startswith("  ") or line.startswith("\t")):
            current += "\n" + line
        elif current is not None and not line.strip():
            bullets.append(current)
            current = None
    if current is not None:
        bullets.append(current)
    return bullets


def check_note_content() -> list[str]:
    """Lint Section 6a content per release-notes-standard.md §3.2 checks 9-12.

    Floor is NOTE_CONTENT_CUTOVER; version-less notes (tuple (0,0)) stay exempt.
    """
    findings: list[str] = []
    if not NOTES_DIR.exists():
        # PATH-RESOLUTION FAILURE — a missing notes dir is the exact vacuous
        # pass #83 fixes (Check 20 lints nothing and reads GREEN). Emit a
        # distinct finding so main() exits 3, never silently exits 0.
        return [f"{CORPUS_PATH_UNRESOLVED_PREFIX}: notes dir does not resolve at {_rel(NOTES_DIR)} — corpus path misconfigured"]

    # check-12 banned-path needle: detects RAW pre-restructure repo paths in
    # Section 6a prose. The pmo-platform/ literal is intentionally retained
    # (modernizing it to also catch release/-rooted paths is accepted-residual
    # for v3.20 per the Stage 5 spec; the ratified deliberate-violation DT proof
    # depends on this needle matching pmo-platform/...).
    path_re = re.compile(r"(?:pmo-platform/|\.claude/)\S+")
    link_strip_re = re.compile(r"\[[^\]]*\]\([^)]*\)")

    for path in sorted(NOTES_DIR.glob("v*.md")):
        ver = version_tuple(path.name)
        if ver < NOTE_CONTENT_CUTOVER:
            continue
        # Extract version key (e.g., "v12.09" from "v12.09_RELEASE_NOTES.md") for exempt-set lookup
        ver_match = VERSION_KEY_RE.match(path.name)
        ver_key = ver_match.group(0) if ver_match else ""
        if ver_key in PRE_CUTOVER_EXEMPT_VERSIONS:
            continue

        text = path.read_text(encoding="utf-8")
        rel = _rel(path)
        section_6a = extract_section_6a(text)

        if section_6a is None:
            findings.append(f"NOTE-6A-MISSING: {rel} lacks '## What changed for everyone' section (release-notes-standard.md §3.2 check 9)")
            continue

        bullets = parse_bullets(section_6a)
        placeholder_present = "No user-visible behavior changes" in section_6a
        if not bullets and not placeholder_present:
            findings.append(f"NOTE-6A-EMPTY: {rel} Section 6a has no bullets and no 'No user-visible behavior changes' placeholder (release-notes-standard.md §3.2 check 9)")

        # Check 10: banned-jargon scan
        lower_section = section_6a.lower()
        for term in BANNED_JARGON_LITERAL:
            if term.lower() in lower_section:
                findings.append(f"NOTE-BANNED-JARGON: {rel} Section 6a contains banned term '{term}' (release-notes-standard.md §3.2 check 10; see §2.4 for plain-language replacement)")
        for pattern, label in BANNED_JARGON_REGEX:
            if pattern.search(section_6a):
                findings.append(f"NOTE-BANNED-JARGON: {rel} Section 6a matches banned pattern '{label}' (release-notes-standard.md §3.2 check 10; see §2.4 for plain-language replacement)")

        # Check 11: 'Why it matters' beat per bullet
        for bullet in bullets:
            has_marker = "<!-- impact:foundational -->" in bullet
            has_beat = "Why it matters" in bullet
            if not (has_beat or has_marker):
                snippet = bullet[:80].strip().replace("\n", " ")
                findings.append(f"NOTE-NO-WHY-IT-MATTERS: {rel} Section 6a bullet lacks 'Why it matters' beat or <!-- impact:foundational --> marker (release-notes-standard.md §3.2 check 11): {snippet!r}")

        # Check 12: no raw file paths in bullet bodies (inline markdown links allowed)
        for bullet in bullets:
            stripped = link_strip_re.sub("", bullet)
            m_path = path_re.search(stripped)
            if m_path:
                snippet = bullet[:80].strip().replace("\n", " ")
                findings.append(f"NOTE-FILE-PATH-IN-6A: {rel} Section 6a bullet contains raw file path '{m_path.group(0)}' (release-notes-standard.md §3.2 check 12; use inline anchor text via markdown link instead): {snippet!r}")

    return findings


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--check", choices=["all", "filename", "schema", "index", "type-coherence", "note-content"], default="all", help="Which check(s) to run")
    args = p.parse_args()

    findings: list[str] = []
    if args.check in ("all", "filename"):
        findings.extend(check_filename_compliance())
    if args.check in ("all", "schema"):
        findings.extend(check_schema_validity())
    if args.check in ("all", "index"):
        findings.extend(check_index_row_count())
    if args.check in ("all", "type-coherence"):
        findings.extend(check_type_coherence())
    if args.check in ("all", "note-content"):
        findings.extend(check_note_content())

    for f in findings:
        print(f)

    # Exit-code contract (per #459 fail-loud): a path-resolution failure
    # (CORPUS-PATH-UNRESOLVED — a required corpus dir/file did not resolve) is
    # NOT a content finding. It exits 3 (path-config error) so deploy.sh can
    # distinguish "could not run against the corpus" from real §3.2 findings
    # (exit 1) and clean (exit 0). A path-resolution failure dominates: if any
    # is present, exit 3 regardless of other findings.
    if any(f.startswith(CORPUS_PATH_UNRESOLVED_PREFIX) for f in findings):
        return 3
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

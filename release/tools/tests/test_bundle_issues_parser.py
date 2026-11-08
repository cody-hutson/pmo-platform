#!/usr/bin/env python3
"""Aggregate + per-failure-class tests for bundle-issues-parser.py.

Companion to the parser's built-in `--self-test` (synthetic per-class fixtures).
This module verifies the v3.20 parser robustification (#291) against a FROZEN
sample of REAL issue bodies drawn from the live open-issue corpus at the Stage 5
baseline, asserting the ratified acceptance criterion:

  combined-clean >= 90% on the CONFORMANT-BUNDLEABLE denominator
  (improvement|bug bodies that carry a recognized Affected-Files heading).

The denominator decision and the >=90% target are the ratified Stage 5 design
(Collective Review scope-lock, v3.20). The Mode A pre-filter that sets aside
bodies with NO recognized AF heading is a release-planner SKILL.md change, not a
parser change, and is therefore simulated here only by curating the frozen sample
to the conformant set.

Fixtures: ./conformant_bundleable_sample.json — 40 real issue bodies frozen on
2026-06-07 (baseline commit anchor recorded in the release plan). The sample spans
30 clean conformant-bundleable bodies, the nine per-class recovered-failure bodies
(see CLASS_RECOVERY below), and one genuinely-unparseable residual that stays
failed by design (a component-name bullet with no file path — routes to the Mode A
set-aside, not a parser failure).

Run:  python3 release/tools/tests/test_bundle_issues_parser.py
Exit: 0 = all pass, 1 = one or more assertions failed.

### Provenance
Issue references in this file (#291, and the frozen sample issue numbers) are the
live open-issue corpus the parser is measured against; numbers are a point-in-time
survey snapshot, not a durable contract — the test re-measures from the frozen
fixtures, which are self-contained.

### Priority-detector coverage (added with the body-priority repair)
Two additive assertions guard the body-priority detector against the exact failure
mode that hid the defect it replaces — a detector that resolves NOTHING while every
test still passes, because nothing ever asserted that extraction was non-empty:

  T-12 (regression, no fixture change) — the >=90% combined-clean AC above must be
       UNCHANGED by the priority work, proving priority never entered parse_status.
  T-13 (non-empty extraction) — every frozen body must resolve to a value in
       {"P1".."P4", None} (domain guard), AND at least one must resolve non-None
       (liveness guard). Without the second half the suite passes on a dead detector.

Audit baseline for the liveness guard: measured over the frozen fixture set
(conformant_bundleable_sample.json, frozen 2026-06-07, N=40) — 22 of 40 resolve a
P-level. The assertion is >=1, not ==22, so it constrains liveness without pinning a
count that a future fixture refresh would rot; the observed count is printed so a
silent collapse from 22 toward 1 is visible in the run output.

### Section-read arms (added with the blank-line extractor repair, #7177)
The section extractor used to end a section at the first two-blank-line run after
its heading, so a heading carrying two blank lines read as an empty section — one
newline moved a gated measurement. It now ends a section only at the next H2/H3
heading or a break line, and native-dep-mirror.py reads that one extractor by path
instead of carrying a copy. The arms below assert it by fixture, each with the arm
that shows it bites:

  7177-AC1  one, two or three blank lines after each parser-read heading read the
            section, in the parser and through the mirror; the pre-repair extractor
            (kept here as a reference copy, never shipped) misreads the same fixtures.
  7177-AC2  present-and-empty, absent and populated stay three distinct reads.
  7177-AC4  the frozen sample's combined-clean count is unchanged when a blank line
            is doubled after a heading or inside a section, and the pre-repair
            extractor's count is not.
  7177-AC5  a doubled blank line inside a section reads as a single one; a break line
            ends the section, LF and CRLF alike; the return is a plain string, so the
            two G3-20 readers keep their contract.
  CIAC-1    the parser loads nothing of the mirror's, loads alone from a copy, and the
            mirror's extractor and direction-grammar names are the parser's own objects.
  CIAC-3    a doubled blank line reads identically through parse_dependencies — the
            property the directed-parse rewrite must keep.

### Direction-grammar arms (added with the directed dependency read, #6397)
parse_dependencies used to scrape every #N in the Dependencies section as an
undirected dependency, so a reciprocal `Blocks #N` and a hierarchy reference read as
blockers. It now returns only the blocked_by targets of the one direction grammar,
which moved from native-dep-mirror.py into the parser. Each arm carries the arm that
shows it bites — a reference copy of the old scrape, kept here and never shipped:

  6397-AC1  one direction grammar: the parser carries no naive scrape; the mirror
            defines none of the grammar's names and reads the parser's; on every
            frozen body parse_dependencies equals the grammar's blocked_by targets,
            and the old scrape reads some of those bodies differently.
  6397-AC2  one fixture per relation — Blocks, Part of epic, Children, Relates to,
            unlabelled prose, the Hard: and Soft: labels (prose markers, reported as
            unattributed), the negated label ("not blocked by", "gated on, not
            blocked by", "_not_ blocked by") and a reference in a later paragraph
            after a blank line — each reading no edge where the old scrape read one;
            the Blocked by: control reads its edge both ways, and a list set under its
            label, with or without a blank line between, keeps its edges; the record
            carries the unattributed references and keeps its status.
"""

import ast
import contextlib
import importlib.util
import io
import json
import os
import re
import shutil
import sys
import tempfile
from typing import Dict, List, Optional, Set, Tuple

HERE = os.path.dirname(os.path.abspath(__file__))
PARSER_PATH = os.path.join(HERE, os.pardir, "bundle-issues-parser.py")
MIRROR_PATH = os.path.join(HERE, os.pardir, "native-dep-mirror.py")
FIXTURES_PATH = os.path.join(HERE, "conformant_bundleable_sample.json")

# The >=90% acceptance criterion on the conformant-bundleable denominator.
AC_THRESHOLD = 0.90

# Per-class recovery expectations: each issue number maps to the failure class it
# exercises and the combined-parse status it MUST reach under the v3.20 parser.
# These nine bodies parse FAILED under the pre-v3.20 parser (fix-efficacy guard
# below confirms the aggregate moves materially); they MUST be clean now.
CLASS_RECOVERY = {
    351: ("FC-1a current module-prefix paths (core/ release/) in bullets", "clean"),
    344: ("FC-1a/FC-5 module-prefix + deferral marker line", "clean"),
    327: ("FC-3 prose-style AF section (path in a sentence)", "clean"),
    326: ("FC-1a release/ path in a single bullet", "clean"),
    195: ("FC-1b bare backticked filename (deploy.sh, no internal '/')", "clean"),
    132: ("FC-1b bare backticked filename (CLAUDE.md)", "clean"),
    114: ("FC-3 prose + module-path reference", "clean"),
    113: ("FC-3 prose with backticked module-prefixed paths", "clean"),
    110: ("FC-3 prose with named pipeline-stage paths", "clean"),
}

# Genuinely-unparseable residual — present AF heading, bullet with no file path and
# no None-marker. Stays failed by design; routes to the Mode A set-aside queue.
RESIDUAL_FAILED = {
    123: "FC-7 component-name bullet ('17 GitHub milestones') — no file path",
}


def load_parser():
    spec = importlib.util.spec_from_file_location("bundle_issues_parser", PARSER_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def combined_status(mod, body: str) -> str:
    _, af = mod.parse_affected_files(body)
    _, dep = mod.parse_dependencies(body)
    if "failed" in (af, dep):
        return "failed"
    if "deferred" in (af, dep):
        return "deferred"
    return "clean"


# ---- Section-read arms (#7177) -------------------------------------------------

LABEL_AC1 = "7177-AC1 blank-line tolerance"
LABEL_AC2 = "7177-AC2 empty, absent and populated stay distinct"
LABEL_AC4 = "7177-AC4 parse rate unchanged under the two-blank shape"
LABEL_AC5 = "7177-AC5 no whitespace-only gap ends a section"
LABEL_CIAC1 = "CIAC-1 no import cycle between the parser and the mirror"
LABEL_CIAC3 = "CIAC-3 blank-line-invariant extraction survives the directed parse"

AF_LINE = "- `release/tools/bundle-issues-parser.py` (edit — fix)"
DEP_LINE = "Blocked by: FS+0d #6396 — x."
AC_LINE = "- [ ] Verify that it works."


def load_mirror():
    spec = importlib.util.spec_from_file_location("native_dep_mirror", MIRROR_PATH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _prefix_extract_section(body: str, heading: str) -> Optional[str]:
    """The extractor as it stood before the repair, kept ONLY as this suite's
    sensitivity arm. It ends a section at the first two-blank-line run after the
    heading — the defect. Never used to grade the shipped parser."""
    if not body:
        return None
    pat = re.compile(rf"^#{{2,4}}\s+{re.escape(heading)}\b[^\n]*$", re.MULTILINE | re.IGNORECASE)
    m = pat.search(body)
    if not m:
        return None
    rest = body[m.end():]
    cands = [c.start() for c in (re.search(r"^###\s+", rest, re.MULTILINE),
                                 re.search(r"^##\s+", rest, re.MULTILINE),
                                 re.search(r"\n\s*\n\s*\n", rest)) if c is not None]
    return rest[: min(cands)] if cands else rest


def load_prefix_parser():
    """A second parser copy reading through the pre-repair extractor. Every reader
    looks extract_section up in the module namespace, so rebinding it reaches all."""
    mod = load_parser()
    mod.extract_section = _prefix_extract_section
    return mod


def load_prefix_mirror():
    """A mirror whose own parser copy reads through the pre-repair extractor."""
    mod = load_mirror()
    mod._BIP.extract_section = _prefix_extract_section
    return mod


def _expect(failures: List[str], label: str, what: str, got, want) -> None:
    if got != want:
        failures.append(f"{label}: {what}: got {got!r}, want {want!r}")


def arm_ac1(bip, mirror, failures: List[str]) -> None:
    old, old_mirror = load_prefix_parser(), load_prefix_mirror()
    for n in (1, 2, 3):
        gap = "\n" * (n + 1)  # the heading line's own newline, then n blank lines
        dep = f"### Dependencies{gap}{DEP_LINE}\n"
        af = f"### Affected Files{gap}{AF_LINE}\n"
        ac = f"### Acceptance Criteria{gap}{AC_LINE}\n"
        files, af_status = bip.parse_affected_files(af)
        _expect(failures, LABEL_AC1, f"Dependencies, {n} blank", bip.parse_dependencies(dep), ({6396}, "clean"))
        _expect(failures, LABEL_AC1, f"Affected Files, {n} blank",
                ([f.path for f in files], af_status), (["release/tools/bundle-issues-parser.py"], "clean"))
        _expect(failures, LABEL_AC1, f"Acceptance Criteria, {n} blank", bip.parse_acceptance_criteria(ac), (True, 1))
        # Both readers: the mirror's extractor name reads every heading the same.
        for body, heading, line in ((dep, "Dependencies", DEP_LINE), (af, "Affected Files", AF_LINE),
                                    (ac, "Acceptance Criteria", AC_LINE)):
            via_mirror = mirror.extract_section_with_alias(body, [heading])
            if via_mirror is None or line not in via_mirror[1] or via_mirror[1] != bip.extract_section(body, heading):
                failures.append(f"{LABEL_AC1}: mirror read of {heading}, {n} blank: got {via_mirror!r}")
        _expect(failures, LABEL_AC1, f"mirror eligible, {n} blank",
                mirror.mirror_eligible_targets(mirror.parse_body_dependencies(dep)), {6396})
        # Pre-repair arm: one blank line read correctly, two and three misread — the
        # three misreads measured on 2026-09-26, plus the mirror's empty set.
        want_old = (({6396}, "clean"), "clean", (True, 1), {6396}) if n == 1 else \
            ((set(), "clean"), "failed", (True, 0), set())
        got_old = (old.parse_dependencies(dep), old.parse_affected_files(af)[1],
                   old.parse_acceptance_criteria(ac),
                   old_mirror.mirror_eligible_targets(old_mirror.parse_body_dependencies(dep)))
        _expect(failures, LABEL_AC1, f"pre-repair arm, {n} blank", got_old, want_old)


def arm_ac2(bip, failures: List[str]) -> None:
    empty = "### Dependencies\n### Notes\nx\n"
    s = bip.extract_section(empty, "Dependencies")
    if s is None or s.strip() != "":
        failures.append(f"{LABEL_AC2}: empty section must read present-and-empty: got {s!r}")
    _expect(failures, LABEL_AC2, "empty section is not flagged", bip.parse_dependencies(empty), (set(), "clean"))
    before_break = "### Dependencies\n---\nBlocked by: #9\n"
    s = bip.extract_section(before_break, "Dependencies")
    if s is None or s.strip() != "":
        failures.append(f"{LABEL_AC2}: section closed by a break line must read present-and-empty: got {s!r}")
    _expect(failures, LABEL_AC2, "absent heading", bip.extract_section("### Notes\nx\n", "Dependencies"), None)
    populated = bip.extract_section("### Dependencies\nBlocked by: #5\n### Notes\nx\n", "Dependencies")
    if populated is None or "Blocked by: #5" not in populated:
        failures.append(f"{LABEL_AC2}: populated section: got {populated!r}")
    _expect(failures, LABEL_AC2, "empty AC section reads present with zero",
            bip.parse_acceptance_criteria("### Acceptance Criteria\n### Notes\nx\n"), (True, 0))
    _expect(failures, LABEL_AC2, "absent AC section reads absent",
            bip.parse_acceptance_criteria("### Notes\nx\n"), (False, 0))


_HEADING_ONE_BLANK_RE = re.compile(r"^(#{2,4}\s[^\n]*\n[ \t]*\n)(?![ \t]*\n)", re.MULTILINE)
_INTERNAL_BLANK_RE = re.compile(r"\n[ \t]*\n(?=[ \t]*\S)")


def _double_first_internal_blank(bip, body: str) -> Optional[str]:
    """Double the first single blank line INSIDE the Affected Files or Dependencies
    section (after its first text), or return None when there is none."""
    for aliases in (bip.AF_HEADING_ALIASES, bip.DEP_HEADING_ALIASES):
        found = bip.extract_section_with_alias(body, aliases)
        if found is None:
            continue
        alias, sec = found
        m = re.compile(rf"^#{{2,4}}\s+{re.escape(alias)}\b[^\n]*$", re.MULTILINE | re.IGNORECASE).search(body)
        first = re.search(r"\S", sec)
        if m is None or first is None:
            continue
        gap = _INTERNAL_BLANK_RE.search(sec, first.start())
        if gap is None:
            continue
        pos = m.end() + gap.start()
        return body[:pos] + "\n" + body[pos:]
    return None


def arm_ac4(bip, fixtures: Dict[str, Dict], failures: List[str]) -> None:
    old = load_prefix_parser()
    head_bodies = internal_bodies = 0
    clean_base = clean_head = old_clean_head_base = old_clean_head = 0
    for num, rec in fixtures.items():
        body = rec["body"]
        base = combined_status(bip, body)
        clean_base += base == "clean"
        variant, k = _HEADING_ONE_BLANK_RE.subn(lambda mm: mm.group(1) + "\n", body)
        clean_head += combined_status(bip, variant) == "clean"
        if k:
            head_bodies += 1
            old_clean_head_base += combined_status(old, body) == "clean"
            old_clean_head += combined_status(old, variant) == "clean"
            if combined_status(bip, variant) != base:
                failures.append(f"{LABEL_AC4}: #{num} after-heading doubling moved {base} -> "
                                f"{combined_status(bip, variant)}")
        internal = _double_first_internal_blank(bip, body)
        if internal is not None:
            internal_bodies += 1
            if combined_status(bip, internal) != base:
                failures.append(f"{LABEL_AC4}: #{num} internal doubling moved {base} -> "
                                f"{combined_status(bip, internal)}")
    if head_bodies == 0 or internal_bodies == 0:
        failures.append(f"{LABEL_AC4}: vacuous — after-heading bodies {head_bodies}, internal bodies "
                        f"{internal_bodies}; each must be >= 1")
    _expect(failures, LABEL_AC4, "combined-clean count, after-heading variant", clean_head, clean_base)
    if not old_clean_head < old_clean_head_base:
        failures.append(f"{LABEL_AC4}: pre-repair arm did not bite — clean {old_clean_head_base} -> "
                        f"{old_clean_head} on the doubled bodies; the variant tests nothing")
    print(f"  {LABEL_AC4}: after-heading bodies {head_bodies}, internal bodies {internal_bodies}; "
          f"pre-repair clean on the doubled bodies {old_clean_head_base} -> {old_clean_head}")


def arm_ac5(bip, failures: List[str]) -> None:
    pairs = (
        ("Affected Files", "### Affected Files\n- `core/a.md` (edit)\n{gap}- `core/b.md` (edit)\n",
         lambda b: ([f.path for f in bip.parse_affected_files(b)[0]], bip.parse_affected_files(b)[1]),
         (["core/a.md", "core/b.md"], "clean")),
        ("Dependencies", "### Dependencies\nBlocked by: #5\n{gap}Blocked by: #6\n",
         bip.parse_dependencies, ({5, 6}, "clean")),
        ("Acceptance Criteria", "### Acceptance Criteria\n- [ ] one\n{gap}- [ ] two\n",
         bip.parse_acceptance_criteria, (True, 2)),
    )
    for heading, shape, read, want in pairs:
        single, double = shape.format(gap="\n"), shape.format(gap="\n\n")
        _expect(failures, LABEL_AC5, f"{heading}, single blank", read(single), want)
        _expect(failures, LABEL_AC5, f"{heading}, doubled blank", read(double), want)
        if not isinstance(bip.extract_section(double, heading), str):
            failures.append(f"{LABEL_AC5}: {heading} return must stay a plain string")
    # Footer arm: the observed shape — a gap, a break line, an HTML marker comment,
    # then text — and the CRLF arm of the same body. Control: no break line, and the
    # footer's text is read, so the break line is what ends the section.
    footer = ("### Affected Files\n- `core/a.md` (edit)\n\n\n---\n<!-- roadmap-deps -->\n- `core/z.md` (edit)\n"
              "### Dependencies\nBlocked by: #5\n\n\n---\n<!-- roadmap-deps -->\nBlocked by: #9\n")
    for tag, body in (("LF", footer), ("CRLF", footer.replace("\n", "\r\n"))):
        files, st = bip.parse_affected_files(body)
        _expect(failures, LABEL_AC5, f"break-line footer, Affected Files ({tag})",
                ([f.path for f in files], st), (["core/a.md"], "clean"))
        _expect(failures, LABEL_AC5, f"break-line footer, Dependencies ({tag})",
                bip.parse_dependencies(body), ({5}, "clean"))
    no_break = footer.replace("---\n", "")
    _expect(failures, LABEL_AC5, "control: no break line reads the footer",
            bip.parse_dependencies(no_break), ({5, 9}, "clean"))
    # The break line itself: CR-tolerant; two hyphens or a hyphen run with text is not one.
    if bip.SECTION_BREAK_RE.search("x\n---\r\ny") is None:
        failures.append(f"{LABEL_AC5}: a CRLF break line must match")
    for near in ("x\n--\ny", "x\n--- text\ny", "x\n    ---\ny"):
        if bip.SECTION_BREAK_RE.search(near) is not None:
            failures.append(f"{LABEL_AC5}: near-miss {near!r} must not read as a break line")
    # The two G3-20 readers test `is not None`: a doubled blank line keeps them as they were.
    doc = ("### Description\nx\n\n## Documentation Impact (proposed)\n\n\n"
           "`core/x.md` | update | y\n")
    _expect(failures, LABEL_AC5, "g3_20_applicability on a doubled-blank kind-form body",
            bip.g3_20_applicability(["type:task"], doc)[0], "kind-form")
    if bip._load_doc_gates()[0] is None:
        failures.append(f"{LABEL_AC5}: the G-CL8 engine did not load, so the misheaded arm cannot run")
    else:
        _expect(failures, LABEL_AC5, "parse_documentation_impact on a doubled-blank misheaded body",
                bip.parse_documentation_impact(doc)[0], "misheaded")


def _non_docstring_strings(src: str) -> Tuple[List[str], List[str]]:
    """(string constants that are not docstrings, imported module names) of a source."""
    tree = ast.parse(src)
    docs = set()
    for node in ast.walk(tree):
        if isinstance(node, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            body = getattr(node, "body", [])
            if body and isinstance(body[0], ast.Expr) and isinstance(getattr(body[0], "value", None), ast.Constant):
                docs.add(id(body[0].value))
    strings, imports = [], []
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str) and id(node) not in docs:
            strings.append(node.value)
        elif isinstance(node, ast.Import):
            imports.extend(a.name for a in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module:
            imports.append(node.module)
    return strings, imports


def arm_ciac1(failures: List[str]) -> None:
    def names_mirror(text: str) -> bool:
        return "native-dep-mirror" in text or "native_dep_mirror" in text

    with open(PARSER_PATH, encoding="utf-8") as fh:
        p_strings, p_imports = _non_docstring_strings(fh.read())
    hits = [s for s in p_strings if names_mirror(s)] + [m for m in p_imports if names_mirror(m)]
    if hits:
        failures.append(f"{LABEL_CIAC1}: the parser's code names the mirror: {hits!r}")
    # Sensitivity: the same scan over the mirror finds its by-path load of the parser.
    with open(MIRROR_PATH, encoding="utf-8") as fh:
        m_src = fh.read()
    m_strings, _ = _non_docstring_strings(m_src)
    if not any("bundle-issues-parser.py" in s for s in m_strings):
        failures.append(f"{LABEL_CIAC1}: sensitivity arm — the scan did not see the mirror's load literal")
    if any(isinstance(n, ast.FunctionDef) and n.name.startswith("extract_section")
           for n in ast.walk(ast.parse(m_src))):
        failures.append(f"{LABEL_CIAC1}: the mirror defines its own extract_section* — the copy is back")
    with tempfile.TemporaryDirectory() as tmp:
        alone = os.path.join(tmp, "bundle-issues-parser.py")
        shutil.copy(PARSER_PATH, alone)
        spec = importlib.util.spec_from_file_location("bip_alone", alone)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        _expect(failures, LABEL_CIAC1, "the parser copied alone loads and reads",
                mod.parse_dependencies("### Dependencies\nBlocked by: #5\n"), ({5}, "clean"))
    # Control: the mirror copied alone (its own directory, no parser beside it) cannot
    # load its parser, and says so with exit 2 rather than misreading or tracing back.
    with tempfile.TemporaryDirectory() as tmp:
        lone = os.path.join(tmp, "native-dep-mirror.py")
        shutil.copy(MIRROR_PATH, lone)
        spec = importlib.util.spec_from_file_location("ndm_alone", lone)
        ndm = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(ndm)
        err = io.StringIO()
        with contextlib.redirect_stderr(err), contextlib.redirect_stdout(io.StringIO()):
            rc = ndm.run_self_test()
        if ndm._BIP is not None or rc != 2 or "cannot load its parser" not in err.getvalue():
            failures.append(f"{LABEL_CIAC1}: control — a mirror with no parser beside it must exit 2: "
                            f"_BIP={ndm._BIP!r} rc={rc} stderr={err.getvalue()!r}")
    mirror = load_mirror()
    if mirror._BIP is None:
        failures.append(f"{LABEL_CIAC1}: the mirror did not load its parser: {mirror._BIP_CAUSE}")
        return
    for name in ("extract_section_with_alias", "extract_section_aliased", "DEP_HEADING_ALIASES") + GRAMMAR_BOUND:
        if getattr(mirror, name, None) is not getattr(mirror._BIP, name):
            failures.append(f"{LABEL_CIAC1}: the mirror's {name} is not the parser's own object")


def arm_ciac3(bip, failures: List[str]) -> None:
    single = "### Dependencies\n\nBlocked by: #5\n\nBlocked by: #6\n\n### Notes\nx\n"
    doubled = "### Dependencies\n\n\nBlocked by: #5\n\n\nBlocked by: #6\n\n### Notes\nx\n"
    _expect(failures, LABEL_CIAC3, "single-blank read", bip.parse_dependencies(single), ({5, 6}, "clean"))
    _expect(failures, LABEL_CIAC3, "doubled-blank read equals the single-blank read",
            bip.parse_dependencies(doubled), bip.parse_dependencies(single))
    old = load_prefix_parser()
    if old.parse_dependencies(doubled) == old.parse_dependencies(single):
        failures.append(f"{LABEL_CIAC3}: sensitivity arm — the pre-repair extractor must read the two differently")


def run_section_read_arms(bip, fixtures: Dict[str, Dict]) -> Tuple[List[str], int]:
    """Run every arm; an arm that raises is recorded as that arm's failure, so one
    broken arm can never hide the verdicts of the others."""
    failures: List[str] = []
    arms = (
        (LABEL_AC1, lambda: arm_ac1(bip, load_mirror(), failures)),
        (LABEL_AC2, lambda: arm_ac2(bip, failures)),
        (LABEL_AC4, lambda: arm_ac4(bip, fixtures, failures)),
        (LABEL_AC5, lambda: arm_ac5(bip, failures)),
        (LABEL_CIAC1, lambda: arm_ciac1(failures)),
        (LABEL_CIAC3, lambda: arm_ciac3(bip, failures)),
    )
    for label, arm in arms:
        try:
            arm()
        except Exception as e:  # noqa: BLE001 — a raising arm is a failing arm
            failures.append(f"{label}: the arm raised {type(e).__name__}: {e}")
    return failures, len(arms)


# ---- Direction-grammar arms (#6397) --------------------------------------------

LABEL_6397_AC1 = "6397-AC1 one direction grammar"
LABEL_6397_AC2 = "6397-AC2 relation fixtures"

# The grammar's names, as the Stage-5 reference-cascade sweep enumerated them.
GRAMMAR_CONSTANTS = ("SEGMENT_LABELS", "_SEGMENT_LABEL_RE", "_LABEL_KIND_BY_GROUP", "DEP_TOKEN_RE",
                     "_LIST_MARKER_RE", "_PROSE_WORD_RE", "DIRECTIONAL_HEADINGS")
GRAMMAR_DEFINITIONS = ("_is_bare_ref_run", "BodyDep", "_attribute_segments", "_parse_token",
                       "_segments_for_body", "unattributed_refs", "parse_body_dependencies")
# The public names the mirror has always exposed, now bound from the parser.
GRAMMAR_BOUND = ("SEGMENT_LABELS", "DEP_TOKEN_RE", "DIRECTIONAL_HEADINGS", "BodyDep",
                 "parse_body_dependencies", "unattributed_refs")

# (leg, Dependencies text, directed targets, unattributed refs). Every row but the
# control names an issue the old scrape reads as a dependency.
RELATION_FIXTURES = [
    ("control: Blocked by:", "Blocked by: #10", {10}, []),
    ("Blocks (the reciprocal)", "Blocks #11", set(), []),
    ("Part of epic", "Part of epic #12", set(), []),
    ("Children", "Children: #13, #14", set(), []),
    ("Relates to", "Relates to #15", set(), []),
    ("unlabelled prose", "See the note in #16 for context.", set(), [16]),
    ("Hard: label", "Hard: #17 (DONE).", set(), [17]),
    ("Soft: label", "Soft: #18", set(), [18]),
    ("Hard: bullet", "- Hard: #22", set(), [22]),
    ("a #45-shaped body", "Hard: #341 (DONE). Parallelizes with #43. **Blocks #44**", set(), [43, 341]),
    ("a #342-shaped body", "Children: #45, #43, #44", set(), []),
    ("negated label", "not blocked by: merge after #23", set(), []),
    ("gated on, not blocked by",
     "Release gate (gated on, not blocked by): merge after #24. It is a merge-order gate, not a build edge.",
     set(), []),
    ("negation after a prose ref", "Gated on #25, not blocked by #26.", set(), [25]),
    ("negated label at line start", "Not blocked by #27: the contract can be specified first.", set(), []),
    # A blank line ends a directional run: a reference in a later paragraph reads as
    # unlabelled text, not as a blocker (the bare list is the shape the legacy shim
    # would otherwise claim; the prose row is the live shape).
    ("a later paragraph after a blank line (bare list)", "Blocked by: #30\n\n- #31", {30}, [31]),
    ("a later paragraph after a blank line (prose)",
     "Blocked by: FS+0d #32 — its partition is this card's input.\n\n"
     "Coordination (not a blocker): #33 (same milestone).", {32}, [33]),
    ("a list after a Blocks paragraph is not a blocker", "Blocks: #34\n\n- #35", set(), [35]),
    ("underscore-emphasised negation", "This is _not_ blocked by #36.", set(), []),
    ("double-underscore negation", "This is __not__ blocked by #37.", set(), []),
]
# Rows that must still read their edge: a list of bare references, typed and lagged
# edges, and a Hard: line beneath a heading that is itself directional.
EDGE_FIXTURES = [
    ("bare-reference list", "### Dependencies\n- #46\n- #57\n", {46, 57}),
    ("typed and lagged", "### Dependencies\nBlocked by: SS #20, FS+2d #21\n", {20, 21}),
    ("directional heading", "### Depends on\nHard: #19\n", {19}),
    ("control: a negation that does not end the prefix",
     "### Dependencies\nNot urgent; blocked by #31.\n", {31}),
    ("control: a list directly under the label", "### Dependencies\nBlocked by:\n- #38\n- #39\n", {38, 39}),
    ("control: a blank line between the label and its list",
     "### Dependencies\nBlocked by:\n\n- #40\n- #41\n", {40, 41}),
    ("control: a directional heading claims the later paragraph",
     "### Blocked by\nBlocked by: #42\n\nAlso #43 once the spike lands.\n", {42, 43}),
    ("control: an underscore inside a word is not emphasis",
     "### Dependencies\nThe do_not blocked by #44 flag stays set.\n", {44}),
]


def _top_level_definitions(src: str) -> Set[str]:
    """Names a module's top level defines: def, class, plain or annotated assignment.
    A name bound inside an `if` block (the mirror's binding from the parser) is not one."""
    out: Set[str] = set()
    for node in ast.parse(src).body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            out.add(node.name)
        elif isinstance(node, ast.Assign):
            out.update(t.id for t in node.targets if isinstance(t, ast.Name))
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
            out.add(node.target.id)
    return out


def _naive_targets(bip, body: str) -> Set[int]:
    """The read before the directed parse, kept ONLY as this suite's sensitivity arm:
    every #N in the Dependencies section as an undirected dependency. Never used to
    grade the shipped parser."""
    section = bip.extract_section_aliased(body, bip.DEP_HEADING_ALIASES)
    return set() if section is None else {int(n) for n in re.findall(r"#(\d+)", section)}


def arm_6397_ac1(bip, fixtures: Dict[str, Dict], failures: List[str]) -> None:
    if hasattr(bip, "DEP_RE"):
        failures.append(f"{LABEL_6397_AC1}: the parser still carries the naive DEP_RE scrape")
    grammar = set(GRAMMAR_CONSTANTS) | set(GRAMMAR_DEFINITIONS)
    with open(PARSER_PATH, encoding="utf-8") as fh:
        in_parser = _top_level_definitions(fh.read())
    with open(MIRROR_PATH, encoding="utf-8") as fh:
        in_mirror = _top_level_definitions(fh.read())
    # Sensitivity: the same scan over the parser finds every grammar name — the home.
    if not grammar <= in_parser:
        failures.append(f"{LABEL_6397_AC1}: sensitivity arm — the parser does not define "
                        f"{sorted(grammar - in_parser)}")
    if grammar & in_mirror:
        failures.append(f"{LABEL_6397_AC1}: the mirror defines its own {sorted(grammar & in_mirror)}")
    mirror = load_mirror()
    if mirror._BIP is None:
        failures.append(f"{LABEL_6397_AC1}: the mirror did not load its parser: {mirror._BIP_CAUSE}")
    else:
        _expect(failures, LABEL_6397_AC1, "module of the mirror's parse_body_dependencies",
                mirror.parse_body_dependencies.__module__, "bundle_issues_parser")
    # parse_dependencies reads through that grammar, on every frozen body; the old
    # scrape reads some of them differently, so the comparison is not vacuous.
    read = with_targets = differs = 0
    for num, rec in fixtures.items():
        body = rec["body"]
        targets, status = bip.parse_dependencies(body)
        if status == "deferred":
            continue
        read += 1
        via_grammar = {d.target for d in bip.parse_body_dependencies(body) if d.direction == "blocked_by"}
        if targets != via_grammar:
            failures.append(f"{LABEL_6397_AC1}: #{num} parse_dependencies {sorted(targets)} != the grammar's "
                            f"blocked_by targets {sorted(via_grammar)}")
        with_targets += bool(targets)
        differs += _naive_targets(bip, body) != targets
    if with_targets == 0 or differs == 0:
        failures.append(f"{LABEL_6397_AC1}: vacuous — bodies with directed targets {with_targets}, bodies the "
                        f"old scrape reads differently {differs}; each must be >= 1")
    print(f"  {LABEL_6397_AC1}: frozen bodies read {read}, with directed targets {with_targets}, "
          f"read differently by the old scrape {differs}")


def arm_6397_ac2(bip, failures: List[str]) -> None:
    mirror = load_mirror()
    for leg, text, want, want_u in RELATION_FIXTURES:
        body = f"### Dependencies\n{text}\n\n### Notes\nx\n"
        _expect(failures, LABEL_6397_AC2, f"{leg}: parse_dependencies", bip.parse_dependencies(body), (want, "clean"))
        _expect(failures, LABEL_6397_AC2, f"{leg}: unattributed_refs", bip.unattributed_refs(body), want_u)
        # Sensitivity: the old scrape reads an edge this row must not (the control: the same edge).
        old = _naive_targets(bip, body)
        bites = old == want if leg.startswith("control") else bool(old - want)
        if not bites:
            failures.append(f"{LABEL_6397_AC2}: {leg}: sensitivity arm — the old scrape reads {sorted(old)}, "
                            "so the row does not bite")
        # The A3.5 mirror reads the same grammar: none of these is mirror-eligible but the control.
        _expect(failures, LABEL_6397_AC2, f"{leg}: mirror-eligible set",
                mirror.mirror_eligible_targets(mirror.parse_body_dependencies(body)), want)
    for leg, body, want in EDGE_FIXTURES:
        _expect(failures, LABEL_6397_AC2, f"{leg}: parse_dependencies", bip.parse_dependencies(body), (want, "clean"))
    # The record carries the unattributed references, count and numbers; the status stays.
    raw = {"number": 1, "title": "t", "state": "open", "labels": [],
           "body": "### Affected Files\n- `core/a.md` (edit — x)\n\n### Dependencies\n"
                   "Gated on the spike in #17.\nBlocked by: #10\nBlocks #11\n"}
    rec = bip.build_issue_record(raw)
    _expect(failures, LABEL_6397_AC2, "record dependencies / unattributed / count / status",
            (rec.dependencies, rec.dependencies_unattributed, rec.dependencies_unattributed_count, rec.parse_status),
            ([10], [17], 1, "clean"))
    issues = json.loads(bip.emit_json([rec], []))["issues"]
    _expect(failures, LABEL_6397_AC2, "JSON carries the unattributed references",
            (issues[0]["dependencies_unattributed"], issues[0]["dependencies_unattributed_count"]), ([17], 1))


def run_direction_arms(bip, fixtures: Dict[str, Dict]) -> Tuple[List[str], int]:
    """Run the #6397 arms; an arm that raises is recorded as that arm's failure."""
    failures: List[str] = []
    arms = (
        (LABEL_6397_AC1, lambda: arm_6397_ac1(bip, fixtures, failures)),
        (LABEL_6397_AC2, lambda: arm_6397_ac2(bip, failures)),
    )
    for label, arm in arms:
        try:
            arm()
        except Exception as e:  # noqa: BLE001 — a raising arm is a failing arm
            failures.append(f"{label}: the arm raised {type(e).__name__}: {e}")
    return failures, len(arms)


def main() -> int:
    bip = load_parser()
    with open(FIXTURES_PATH) as fh:
        fixtures: Dict[str, Dict] = json.load(fh)

    failures = []

    # 1. Per-class recovery: each recovered-failure body must reach its expected status.
    for num, (desc, expected) in CLASS_RECOVERY.items():
        rec = fixtures.get(str(num))
        if rec is None:
            failures.append(f"recovery fixture #{num} missing from frozen sample")
            continue
        got = combined_status(bip, rec["body"])
        if got != expected:
            failures.append(f"#{num} ({desc}): expected {expected}, got {got}")

    # 2. Residual still-failed by design (negative assertion — guards over-eager matching).
    for num, desc in RESIDUAL_FAILED.items():
        rec = fixtures.get(str(num))
        if rec is None:
            failures.append(f"residual fixture #{num} missing from frozen sample")
            continue
        got = combined_status(bip, rec["body"])
        if got != "failed":
            failures.append(
                f"#{num} ({desc}): expected failed (set-aside), got {got} — "
                f"over-eager extraction may have invented a path"
            )

    # 3. Aggregate AC: combined-clean >= 90% on the frozen conformant-bundleable sample.
    n = len(fixtures)
    clean = sum(1 for rec in fixtures.values() if combined_status(bip, rec["body"]) == "clean")
    deferred = sum(
        1 for rec in fixtures.values() if combined_status(bip, rec["body"]) == "deferred"
    )
    rate = clean / n if n else 0.0
    if rate < AC_THRESHOLD:
        failures.append(
            f"AC FAIL: combined-clean {clean}/{n} = {rate:.1%} < {AC_THRESHOLD:.0%}"
        )

    # 4. T-13 priority-detector guards over the same frozen sample.
    #    (a) domain: every body resolves inside {"P1".."P4", None} — no other value.
    #    (b) liveness: at least one body resolves non-None. This is the guard the
    #        replaced label regex never had: it returned None for every issue on
    #        every run, and no test noticed, because no test asserted extraction was
    #        non-empty. A suite that cannot fail on a dead detector is not a suite.
    valid_domain = {"P1", "P2", "P3", "P4", None}
    resolved = 0
    for num, rec in fixtures.items():
        got = bip.parse_priority_body(rec["body"])
        if got not in valid_domain:
            failures.append(
                f"#{num}: parse_priority_body returned {got!r}, outside "
                f"{{'P1'..'P4', None}}"
            )
        if got is not None:
            resolved += 1
            if bip.priority_rank(got) not in (1, 2, 3, 4):
                failures.append(f"#{num}: priority_rank({got!r}) outside 1..4")
    if resolved < 1:
        failures.append(
            f"T-13 liveness: 0 of {n} frozen bodies resolved a P-level — the "
            f"detector is silently dead (this is the failure mode the priority "
            f"repair exists to prevent recurring)"
        )

    # Report
    print(f"conformant-bundleable frozen sample: N={n}")
    print(f"  combined-clean    = {clean}/{n} = {rate:.1%}  (AC: >= {AC_THRESHOLD:.0%})")
    print(f"  clean-or-deferred = {clean + deferred}/{n} = {(clean + deferred) / n:.1%}")
    print(f"  per-class recovery cases: {len(CLASS_RECOVERY)}  residual set-aside: {len(RESIDUAL_FAILED)}")
    print(f"  priority resolved = {resolved}/{n}  (T-13 liveness guard: >= 1)")

    # 5. Section-read arms (#7177 and the two cross-issue criteria on its seam).
    section_failures, section_arms = run_section_read_arms(bip, fixtures)
    failures.extend(section_failures)
    print(f"  section-read arms = {section_arms} run, {len(section_failures)} failure(s)")

    # 6. Direction-grammar arms (#6397).
    direction_failures, direction_arms = run_direction_arms(bip, fixtures)
    failures.extend(direction_failures)
    print(f"  direction-grammar arms = {direction_arms} run, {len(direction_failures)} failure(s)")

    if failures:
        print("\nTEST FAIL:", file=sys.stderr)
        for f in failures:
            print(f"  - {f}", file=sys.stderr)
        return 1
    print("\nTEST OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())

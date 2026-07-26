#!/usr/bin/env python3
"""Cross-module extraction-readiness audit helper.

Per the module-restructure Stage 5 spec:
  - Imports primitive link-extraction + resolution from check-doc-links.py
    (inherits FM-1 fenced-code-block stripping + FM-2 anchor-resolution).
  - Classifies every cross-module reference per 6 directionality rules
    (Surface 2: Cat-1..Cat-6 plus intra-module Cat-7).
  - Applies cross-ref-type refinement (counter-design CD-3) — distinguishes
    code-import cycles (BLOCKER) from markdown-doc-links (Suspect-by-direction)
    from narrative-mentions (Minor).
  - Emits TSV + markdown report per Surface 6.

Output schema (TSV; per Surface 6.1):
  source_module<TAB>source_file<TAB>line<TAB>target_path<TAB>category<TAB>
  cross_ref_type<TAB>via_public_api<TAB>violation_class<TAB>recommended_strategy

Exit codes:
  0  No cycle-class violations (clean OR non-cycle violations only)
  1  Cycle-class violation detected (code-import cycle — BLOCKS module extraction)
  2  Non-cycle violations detected (routes to the cleanup queue)
  3  Script error

Authored per the module-restructure Stage 5 spec + counter-designs CD-2/CD-3
(cross-ref-type refinement).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Import primitives from check-doc-links.py.
# Module is hyphenated; import via importlib to avoid Python identifier issue.
import importlib.util
_THIS_DIR = Path(__file__).resolve().parent
_CHECK_DOC_LINKS = _THIS_DIR / "check-doc-links.py"
_spec = importlib.util.spec_from_file_location("check_doc_links", _CHECK_DOC_LINKS)
_cdl = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_cdl)

# Workspace root = the v2 repo root (parents[3] from core/deploy/tools/).
WORKSPACE_ROOT = _cdl.WORKSPACE_ROOT

# Modules and their canonical directory prefixes.
MODULES = ("operations", "release", "core")

# Directionality table per Surface 2 of the module-restructure spec.
# Maps (source_module, target_module) -> (category, severity_default, recommended_strategy_default).
DIRECTIONALITY = {
    ("core", "operations"): ("Cat-1", "Blocker", "(d)"),     # FORBIDDEN cycle
    ("core", "release"):    ("Cat-2", "Blocker", "(d)"),     # FORBIDDEN cycle
    ("operations", "core"): ("Cat-3", "Major", "(a)"),       # ALLOWED via Public API
    ("release", "core"):    ("Cat-4", "Major", "(a)"),       # ALLOWED via Public API
    ("operations", "release"): ("Cat-5", "Suspect", "(g)"),  # SUSPECT-pattern
    ("release", "operations"): ("Cat-6", "Suspect", "(g)"),  # SUSPECT-pattern
}

# Carry-forward documentary cross-refs from the ADR-007 carry-forward
# contract (Decision 4 + Pattern-P1 extension).
#
# v1: markdown-doc-link patterns from core/disciplines + core/schemas
# to release/governance/release-process.md OR release/references/pipeline/*.
#
# v2 (Pattern-P1): extended to encompass ALL documentary
# markdown-doc-link + narrative-mention references from core/{disciplines,
# schemas, standards, ADRs, README.md} to BOTH operations/* and release/*.
# Operator-ratified at the module-restructure close.
#
# The extension recognizes that core foundational concept docs (disciplines,
# schemas, standards, ADRs) legitimately reference operations and release
# content as documentary cohesion, NOT as code-import dependencies.
# Specifically: core ADRs describing the module boundary naturally
# enumerate content from all modules; core/schemas/per-skill-output-contracts.md
# enumerates skills from all modules; core/disciplines/architecture-overview.md
# documents the cross-module architecture.
#
# The architectural invariant (zero code-import cycles per ADR-007) is
# preserved — cycle-code-import is still classified as BLOCKER.
ADR_007_ALLOWED_CARRY_FORWARD_PREFIXES = (
    "release/",
    "operations/",
)

# Source-file prefixes whose markdown-doc-link + narrative-mention references
# to release/* count as accepted carry-forward (per Pattern-P1).
# Includes:
#   - core/disciplines/, core/schemas/, core/standards/, core/ADRs/ (v1 + v2)
#   - core/rules/ — workflow rules describing cross-module branch + PR conventions
#   - core/deploy/tools/README.md — audit-doc that documents this exact classifier
#     behavior and naturally references operations/release subjects
ADR_007_ALLOWED_CARRY_FORWARD_SOURCE_PREFIXES = (
    "core/disciplines/",
    "core/schemas/",
    "core/standards/",
    "core/ADRs/",
    "core/rules/",
    "core/deploy/tools/README.md",
    "core/governance/",
)

# Deploy infrastructure files exempted from cross-module audit per
# Pattern-P4. These files operationally orchestrate ACROSS modules by
# design (per ADR-008 deploy.sh per-module array design); their cross-module
# references are infrastructure, not module-boundary violations.
DEPLOY_INFRASTRUCTURE_PATHS = (
    "core/deploy/deploy.sh",
    "core/deploy/tools/cross_module_audit_helper.py",
    "core/deploy/tools/cross-module-audit.sh",
    "core/deploy/tools/check-doc-links.py",
)

# Known prose-disjunction patterns — compound nouns or branch-name templates
# where `<module>/<word>` is English prose / branch-naming convention,
# NOT a file path. Per Pattern-P5.
# Operator may extend as new false-positive patterns surface.
KNOWN_PROSE_DISJUNCTIONS = {
    "release/issue",
    "release/deployment",
    "release/<slug>",  # branch-naming convention in core/rules/git-workflow.md (slug-primary / pre-claim)
}

# Patterns indicating code-import context (cross-ref-type classification).
# Per CD-3 + FM-1 mitigation: distinguish actual import statements from prose
# mentions of the word "import" inside docstrings/comments.
#
# Code-import detection is conservative:
#   - Python: line starts with (after whitespace) `from X import Y` or `import X`
#     OR a `subprocess`-style spawn with the path as the first arg
#   - Bash: line starts with `source PATH` or `. PATH` (dot-space-path)
#   - In all cases: the line must NOT be a `#` comment line
PYTHON_IMPORT_RE = re.compile(r"^\s*(from\s+\S+\s+import\s+|import\s+)")
BASH_SOURCE_RE = re.compile(r"^\s*(source\s+\S|\.\s+\S)")
COMMENT_RE = re.compile(r"^\s*#")

# Markdown inline link pattern (per check-doc-links.py INLINE_LINK_RE).
MARKDOWN_LINK_RE = re.compile(r"\[[^\]]+\]\([^)]+\)")
MARKDOWN_REF_LINK_RE = re.compile(r"\[[^\]]+\]\[[^\]]*\]")
MARKDOWN_REF_DEF_RE = re.compile(r"^\[[^\]]+\]:\s*\S+")


def source_module(rel_path: str) -> str | None:
    """Identify which module a file belongs to."""
    parts = rel_path.split("/", 1)
    if not parts:
        return None
    if parts[0] in MODULES:
        return parts[0]
    return None


def target_module(target_path: str) -> str | None:
    """Identify which module a target path refers to.

    target_path can be relative or workspace-rooted; we look at the
    resolved path's prefix.
    """
    # Strip leading ./
    p = target_path.lstrip("./")
    # If it has an obvious module prefix at the start, use that.
    for m in MODULES:
        if p.startswith(m + "/"):
            return m
    # Resolved-path fall back (e.g., ../release/foo from core/x/y.md → release).
    parts = p.split("/")
    for m in MODULES:
        if m in parts:
            return m
    return None


def classify_cross_ref_type(
    source_file: Path,
    line_text: str,
) -> str:
    """Classify a reference as code-import, markdown-doc-link, or narrative-mention.

    Per counter-design CD-3 + FM-1 refinement: code-import requires actual
    import statement syntax (not just the word "import" appearing in a
    comment/docstring).

    Conservative classifier:
      - Python .py: line matches `from X import Y` OR `import X` patterns
        (NOT inside a `#` comment line)
      - Bash .sh: line matches `source PATH` OR `. PATH` (NOT inside `#` comment)
      - Otherwise: markdown-doc-link if line contains [..](..) link syntax
      - Otherwise: narrative-mention (substring appearance only)
    """
    ext = source_file.suffix.lower()
    # Reject comment lines from code-import classification
    if not COMMENT_RE.match(line_text):
        if ext == ".py" and PYTHON_IMPORT_RE.match(line_text):
            return "code-import"
        if ext == ".sh" and BASH_SOURCE_RE.match(line_text):
            return "code-import"
    # Markdown-doc-link detection: line contains markdown link syntax
    if MARKDOWN_LINK_RE.search(line_text) or MARKDOWN_REF_LINK_RE.search(line_text) or MARKDOWN_REF_DEF_RE.match(line_text.lstrip()):
        return "markdown-doc-link"
    # Default: narrative-mention (substring in prose, not a link)
    return "narrative-mention"


def read_public_api_paths(module: str) -> set[str]:
    """Extract enumerated paths from the module README's `## Public API` section.

    Returns set of path strings (e.g., "core/skills/prompt-builder").
    """
    readme = WORKSPACE_ROOT / module / "README.md"
    if not readme.exists():
        return set()
    text = readme.read_text(encoding="utf-8", errors="replace")
    # Slice between `## Public API` and the next `## ` heading.
    lines = text.split("\n")
    in_public_api = False
    public_lines: list[str] = []
    for ln in lines:
        if ln.startswith("## Public API"):
            in_public_api = True
            continue
        if in_public_api and ln.startswith("## "):
            break
        if in_public_api:
            public_lines.append(ln)
    section = "\n".join(public_lines)
    # Extract path-shaped tokens: <module>/<subpath>
    paths: set[str] = set()
    pattern = re.compile(r"\b(?:operations|release|core)/[A-Za-z0-9_\-./]+")
    for m in pattern.finditer(section):
        paths.add(m.group(0).rstrip(".,;:()`"))
    return paths


def is_via_public_api(target: str, target_mod: str, public_paths: set[str]) -> bool:
    """Check whether target is enumerated in the target module's Public API.

    Per the module-restructure spec Surface 2 definitional clarification: file MUST appear in the
    Public API section. Files NOT in either section are implicitly public
    for this layout (per the module-restructure Surface 3 "Empty Internal API is valid").
    """
    # Direct match against any enumerated public path or its prefix
    for p in public_paths:
        # Either the target IS the public path, OR target starts with it (subpath).
        if target == p or target.startswith(p + "/") or target.startswith(p):
            return True
    # Fallback: if module has empty Internal API list, implicit-public applies.
    # All 3 modules have empty Internal API, so most refs default to
    # implicitly-public. But we also check: if reference points into _internal/,
    # it's via-internal-api (violation).
    if "/_internal/" in target or target.endswith("/_internal"):
        return False
    return True  # implicit-public default


def is_carry_forward_allowed(
    source_mod: str,
    source_file_rel: str,
    target_path: str,
    cross_ref_type: str,
) -> bool:
    """Check if a Cat-1/Cat-2 reference falls under ADR-007 carry-forward allowance.

    v1 (Decision 4): documentary markdown-doc-links from
    core/disciplines + core/schemas to release/governance/release-process.md
    OR release/references/pipeline/* are accepted cohesion, not cycle violations.

    v2 (Pattern-P1 extension): broadened to encompass:
      - Source: core/{disciplines, schemas, standards, ADRs, README.md}
      - Target: release/{references, governance, ADRs}
      - Cross-ref-type: markdown-doc-link OR narrative-mention
      (code-import remains BLOCKER — architectural invariant preserved)

    The extension recognizes that core foundational concept docs legitimately
    reference release pipeline instantiation docs as documentary cohesion.

    NOTE: An earlier baseline of carry-forward refs in
    core/disciplines + core/schemas to a legacy `reference/pipeline/` path
    were RESOLVED via path-rewrites to `release/references/pipeline/`.
    """
    if source_mod != "core":
        return False
    # code-import remains BLOCKER (architectural invariant per ADR-007)
    if cross_ref_type == "code-import":
        return False
    # Source must be in one of the allowed core/ subtrees, OR be core/README.md
    source_allowed = (
        source_file_rel == "core/README.md"
        or any(source_file_rel.startswith(p) for p in ADR_007_ALLOWED_CARRY_FORWARD_SOURCE_PREFIXES)
    )
    if not source_allowed:
        return False
    # Target must hit one of the allowed release/* subtrees.
    # Normalize relative-path forms (`../release/...`, `../../release/...`) to
    # workspace-rooted form before checking.
    normalized_target = target_path
    while normalized_target.startswith("../"):
        normalized_target = normalized_target[3:]
    for prefix in ADR_007_ALLOWED_CARRY_FORWARD_PREFIXES:
        if normalized_target == prefix or normalized_target.startswith(prefix):
            return True
    return False


def is_deploy_infrastructure(source_file_rel: str) -> bool:
    """Check if a source file is deploy infrastructure (exempt per Pattern-P4).

    Per Pattern-P4: `core/deploy/deploy.sh` and audit/check
    tooling at `core/deploy/tools/` operate ACROSS modules by design
    (per ADR-008 per-module array design). Their cross-module references
    are infrastructure orchestration, not module-boundary violations.
    """
    return source_file_rel in DEPLOY_INFRASTRUCTURE_PATHS


def is_prose_disjunction(target_path: str) -> bool:
    """Check if a target string is a known prose-disjunction false-positive.

    Per Pattern-P5: compound nouns like `release/issue` and
    `release/deployment` are English prose, not file paths. Audit substring
    scanner should not flag them.
    """
    return target_path in KNOWN_PROSE_DISJUNCTIONS


def scan_module_for_cross_module_refs(module: str) -> list[dict]:
    """Walk all .md/.sh/.py files under a module subtree.

    For each file, use check-doc-links primitives to extract markdown links,
    then ADDITIONALLY scan non-markdown lines for narrative cross-module mentions
    in .sh/.py files (these may indicate code-import cycles which markdown-only
    link extraction would miss).

    Returns list of finding dicts ready for classification.
    """
    findings: list[dict] = []
    module_dir = WORKSPACE_ROOT / module
    if not module_dir.exists():
        return findings

    for filepath in sorted(module_dir.rglob("*")):
        if not filepath.is_file():
            continue
        if filepath.suffix.lower() not in (".md", ".sh", ".py"):
            continue
        try:
            rel = str(filepath.relative_to(WORKSPACE_ROOT))
        except ValueError:
            rel = str(filepath)

        # === Pattern-P4: skip deploy infrastructure files ===
        # core/deploy/deploy.sh + audit/check tooling orchestrate ACROSS modules
        # by design (per ADR-008). Their cross-module references are
        # infrastructure operation, not module-boundary violations.
        if is_deploy_infrastructure(rel):
            continue

        # === Step 1: Use check-doc-links primitives for .md files (markdown links) ===
        if filepath.suffix.lower() == ".md":
            try:
                text = filepath.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            lines = text.splitlines()
            content = _cdl.strip_code_blocks(lines)
            for line_no, target in _cdl.extract_links(filepath, content):
                # Drop external + anchors handled in extract_links (is_internal True only)
                # Strip anchor + query parts for module classification
                target_path_only = target.split("#", 1)[0].split("?", 1)[0]
                if not target_path_only:
                    continue
                # Pattern-P5: skip known prose-disjunction
                # false-positives.
                if is_prose_disjunction(target_path_only):
                    continue
                # Identify line text for cross-ref-type classification
                line_text = lines[line_no - 1] if 0 < line_no <= len(lines) else ""
                cross_ref_type = classify_cross_ref_type(filepath, line_text)
                tgt_mod = target_module(target_path_only)
                src_mod = source_module(rel)
                if tgt_mod is None or src_mod is None or tgt_mod == src_mod:
                    continue  # intra-module or out-of-module target, skip
                findings.append({
                    "source_module": src_mod,
                    "source_file": rel,
                    "line": line_no,
                    "target_path": target_path_only,
                    "raw_target": target,
                    "line_text": line_text.strip()[:200],
                    "cross_ref_type": cross_ref_type,
                })

        # === Step 2: For .sh / .py / .md files, do explicit substring scan ===
        # (check-doc-links is markdown-link-only; we also need substring grep
        # to detect (a) code-import cycles in .sh/.py and (b) narrative-mention
        # cross-module substrings in .md prose that aren't markdown links —
        # backticked-only paths, plain text mentions.)
        #
        # De-duplicate at (source_file, line, target_module) granularity: if
        # markdown-link extractor (Step 1) already captured a cross-module ref
        # to module X at (file, line), the substring scan does NOT re-emit a
        # finding for the same (file, line, X) — even if the substring shows
        # the path in a different form (relative vs absolute).
        existing_line_target_module = {
            (f["source_file"], f["line"], target_module(f["target_path"]))
            for f in findings
            if f["source_file"] == rel and target_module(f["target_path"]) is not None
        }
        try:
            text = filepath.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        lines = text.splitlines()
        # Use fence-stripped content for .md to skip code-block prose
        if filepath.suffix.lower() == ".md":
            content_pairs = _cdl.strip_code_blocks(lines)
            substring_scan_pairs = [(ln, txt) for ln, txt in content_pairs if txt]
        else:
            substring_scan_pairs = list(enumerate(lines, start=1))
        src_mod = source_module(rel)
        if src_mod is None:
            continue
        for line_no, line in substring_scan_pairs:
            # Look for any other module name as substring in the line
            for other in MODULES:
                if other == src_mod:
                    continue
                if (other + "/") not in line:
                    continue
                # Extract path-like tokens following "<module>/"
                matches = re.findall(rf"(?:^|[^a-zA-Z0-9_-])({other}/[A-Za-z0-9_\-./]+)", line)
                # Dedupe substring-extracted tokens per line (same path may
                # appear twice in the same line — emit once).
                seen_this_line: set[str] = set()
                for tgt in matches:
                    tgt_clean = tgt.rstrip(".,;:()\"`'")
                    if tgt_clean in seen_this_line:
                        continue
                    seen_this_line.add(tgt_clean)
                    # Pattern-P5: skip known prose-disjunction
                    # false-positives like "release/issue" + "release/deployment"
                    # (compound nouns, not file references).
                    if is_prose_disjunction(tgt_clean):
                        continue
                    # Skip if Step 1 (markdown link extractor) already captured
                    # a cross-module ref to the same target module on this line.
                    if (rel, line_no, other) in existing_line_target_module:
                        continue
                    cross_ref_type = classify_cross_ref_type(filepath, line)
                    findings.append({
                        "source_module": src_mod,
                        "source_file": rel,
                        "line": line_no,
                        "target_path": tgt_clean,
                        "raw_target": tgt_clean,
                        "line_text": line.strip()[:200],
                        "cross_ref_type": cross_ref_type,
                    })
    return findings


def classify_finding(f: dict, public_api_paths: dict[str, set[str]]) -> dict:
    """Apply directionality + cross-ref-type + via-public-api classification.

    Mutates f in-place to add: category, via_public_api, violation_class,
    recommended_strategy. Returns same dict.
    """
    src = f["source_module"]
    tgt = target_module(f["target_path"])
    f["target_module"] = tgt or ""

    if tgt is None or tgt == src:
        # Intra-module or unresolvable — skip; should have been filtered above.
        f["category"] = "Cat-7"
        f["via_public_api"] = "n/a"
        f["violation_class"] = "intra-module"
        f["recommended_strategy"] = "n/a"
        return f

    direction = (src, tgt)
    if direction not in DIRECTIONALITY:
        # Shouldn't happen with 3 modules; defensive.
        f["category"] = "Cat-?"
        f["via_public_api"] = "n/a"
        f["violation_class"] = "unknown-direction"
        f["recommended_strategy"] = "(g)"
        return f

    category, sev_default, strategy_default = DIRECTIONALITY[direction]
    f["category"] = category

    # === Cat-1 and Cat-2: cycle direction (core → ops/release) ===
    if direction[0] == "core":
        # Apply cross-ref-type refinement per CD-3.
        crt = f["cross_ref_type"]
        if crt == "code-import":
            # Genuine cycle violation — BLOCKER (architectural invariant)
            f["via_public_api"] = "n/a"
            f["violation_class"] = "cycle-code-import"
            f["recommended_strategy"] = "(d)"
            return f
        # Pattern-P1: extended ADR-007 carry-forward applies
        # to BOTH markdown-doc-link AND narrative-mention for the broadened
        # source+target prefix sets (per is_carry_forward_allowed()).
        # Applies to Cat-1 (operations) AND Cat-2 (release) symmetrically —
        # core foundational concept docs reference content from BOTH consumer
        # modules as documentary cohesion.
        if is_carry_forward_allowed(
            src, f["source_file"], f["target_path"], crt
        ):
            f["via_public_api"] = "n/a"
            f["violation_class"] = "info-adr-007-carry-forward"
            f["recommended_strategy"] = "n/a"
            return f
        if crt == "markdown-doc-link":
            # Documentary markdown link from core to ops/release outside the
            # allowed carry-forward pattern — Suspect per CD-3
            f["via_public_api"] = "n/a"
            f["violation_class"] = "cycle-markdown-doc-link"
            f["recommended_strategy"] = "(g)"
            return f
        # narrative-mention
        f["via_public_api"] = "n/a"
        f["violation_class"] = "cycle-narrative-mention"
        f["recommended_strategy"] = "(g)"
        return f

    # === Cat-3 and Cat-4: ops/release → core (ALLOWED via Public API) ===
    if direction[1] == "core":
        public_paths = public_api_paths.get("core", set())
        via_pub = is_via_public_api(f["target_path"], "core", public_paths)
        f["via_public_api"] = "true" if via_pub else "false"
        if via_pub:
            f["violation_class"] = "via-public-api"
            f["recommended_strategy"] = "n/a"
        else:
            f["violation_class"] = "via-internal-api"
            f["recommended_strategy"] = "(a)"
        return f

    # === Cat-5 and Cat-6: ops ↔ release (SUSPECT pattern; refined per Pattern-P2/P3) ===
    public_paths = public_api_paths.get(direction[1], set())
    via_pub = is_via_public_api(f["target_path"], direction[1], public_paths)
    f["via_public_api"] = "true" if via_pub else "false"
    # Pattern-P2/P3: when the cross-module ref hits a target
    # that is declared in the target module's Public API enumeration, it is a
    # legitimate via-public-api reference, NOT a suspect-pattern. This applies
    # symmetrically to Cat-3/Cat-4 (ops/release → core via Public API OK) and
    # to Cat-5/Cat-6 (ops ↔ release via Public API OK).
    if via_pub:
        f["violation_class"] = "via-public-api"
        f["recommended_strategy"] = "n/a"
    else:
        f["violation_class"] = "suspect-pattern"
        f["recommended_strategy"] = "(g)"
    return f


def emit_tsv(findings: list[dict]) -> str:
    header = "source_module\tsource_file\tline\ttarget_path\tcategory\tcross_ref_type\tvia_public_api\tviolation_class\trecommended_strategy"
    rows = [header]
    for f in findings:
        rows.append(
            f"{f['source_module']}\t{f['source_file']}\t{f['line']}\t"
            f"{f['target_path']}\t{f['category']}\t{f['cross_ref_type']}\t"
            f"{f['via_public_api']}\t{f['violation_class']}\t{f['recommended_strategy']}"
        )
    return "\n".join(rows)


def _repo_slug() -> str:
    """owner/repo of the running clone's origin (fork-correct) — neutral fallback if unresolved."""
    try:
        import subprocess
        url = subprocess.run(
            ["git", "config", "--get", "remote.origin.url"],
            capture_output=True, text=True,
        ).stdout.strip()
        m = re.search(r"[:/]([^/]+/[^/]+?)(?:\.git)?$", url)
        if m:
            return m.group(1)
    except Exception:
        pass
    return "pmo-platform"


def emit_summary_markdown(findings: list[dict], commit_sha: str, audit_date: str) -> str:
    """Author the markdown summary report per Surface 6.2."""
    # Aggregate counts
    from collections import Counter
    cat_counter: Counter[str] = Counter()
    class_counter: Counter[str] = Counter()
    strategy_counter: Counter[str] = Counter()
    for f in findings:
        cat_counter[f["category"]] += 1
        class_counter[f["violation_class"]] += 1
        strategy_counter[f["recommended_strategy"]] += 1

    # Per-category via-public-api breakdown
    cat_via_pub: dict[str, tuple[int, int]] = {}  # cat -> (via_pub_true, via_pub_false)
    for cat in ("Cat-3", "Cat-4", "Cat-5", "Cat-6"):
        true_cnt = sum(1 for f in findings if f["category"] == cat and f["via_public_api"] == "true")
        false_cnt = sum(1 for f in findings if f["category"] == cat and f["via_public_api"] == "false")
        cat_via_pub[cat] = (true_cnt, false_cnt)

    # Cycle-prevention verdict
    cycle_code_import = sum(1 for f in findings if f["violation_class"] == "cycle-code-import")
    cycle_md_link = sum(1 for f in findings if f["violation_class"] == "cycle-markdown-doc-link")
    cycle_narrative = sum(1 for f in findings if f["violation_class"] == "cycle-narrative-mention")
    carry_forward = sum(1 for f in findings if f["violation_class"] == "info-adr-007-carry-forward")

    cycle_verdict = "PASS" if cycle_code_import == 0 else "FAIL"

    md = []
    md.append(f"# Cross-Module Reference Audit — {audit_date}")
    md.append("")
    md.append(f"**Repo:** {_repo_slug()}")
    md.append(f"**Commit:** {commit_sha}")
    md.append(f"**Methodology:** per the module-restructure Stage 5 spec, Surfaces 1-6 + counter-designs CD-2 + CD-3 (cross-ref-type refinement)")
    md.append("")
    md.append("## Cycle-Prevention Verdict")
    md.append("")
    md.append(f"**{cycle_verdict}** — code-import cycles (the architectural invariant per ADR-007): **{cycle_code_import}**")
    md.append("")
    if cycle_verdict == "PASS":
        md.append("Per the cross-ref-type classification (counter-design CD-3), the cycle predicate is satisfied when there are zero **code-import** cycles from `core/` to `operations/` or `release/`. Markdown documentary cross-references from `core/disciplines + core/schemas` to `release/governance/release-process.md` + `release/references/pipeline/*` are accepted cohesion per the ADR-007 carry-forward contract (Decision 4).")
    else:
        md.append("Code-import cycle detected — BLOCKS module extraction. Operator routing decision required.")
    md.append("")
    md.append("### Cycle-class breakdown")
    md.append("")
    md.append("| Cycle class | Count | Severity | Routing |")
    md.append("|---|---|---|---|")
    md.append(f"| `cycle-code-import` (Cat-1/Cat-2 .sh/.py imports) | {cycle_code_import} | **Blocker** | (d) — refactor target |")
    md.append(f"| `cycle-markdown-doc-link` (Cat-1/Cat-2 markdown links) | {cycle_md_link} | Suspect | (g) — operator review |")
    md.append(f"| `cycle-narrative-mention` (Cat-1/Cat-2 prose substring) | {cycle_narrative} | Minor | (g) — operator review |")
    md.append(f"| `info-adr-007-carry-forward` (accepted documentary cohesion) | {carry_forward} | OK | none |")
    md.append("")

    md.append("## Summary")
    md.append("")
    md.append("| Category | Count | Severity | Routing |")
    md.append("|---|---|---|---|")
    md.append(f"| Cat-1 (core→operations — all classes) | {cat_counter.get('Cat-1', 0)} | mixed (see cycle-class breakdown above) | per cross-ref-type |")
    md.append(f"| Cat-2 (core→release — all classes) | {cat_counter.get('Cat-2', 0)} | mixed | per cross-ref-type |")
    md.append(f"| Cat-3 via-public-api (operations→core OK) | {cat_via_pub.get('Cat-3', (0, 0))[0]} | OK | none |")
    md.append(f"| Cat-3 via-internal-api (operations→core violation) | {cat_via_pub.get('Cat-3', (0, 0))[1]} | Major | (a)/(b) |")
    md.append(f"| Cat-4 via-public-api (release→core OK) | {cat_via_pub.get('Cat-4', (0, 0))[0]} | OK | none |")
    md.append(f"| Cat-4 via-internal-api (release→core violation) | {cat_via_pub.get('Cat-4', (0, 0))[1]} | Major | (a)/(b) |")
    md.append(f"| Cat-5 (operations→release suspect) | {cat_counter.get('Cat-5', 0)} | Suspect | operator review → (g) |")
    md.append(f"| Cat-6 (release→operations suspect) | {cat_counter.get('Cat-6', 0)} | Suspect | operator review → (g) |")
    md.append(f"| **Total findings** | {sum(cat_counter.values())} | | |")
    md.append("")
    md.append("## Strategy Distribution (7-strategy enum per Surface 5)")
    md.append("")
    md.append("| Strategy | Count | Description |")
    md.append("|---|---|---|")
    md.append(f"| (a) move ref to Public API | {strategy_counter.get('(a)', 0)} | Promote target to source module's Public API enumeration |")
    md.append(f"| (b) move dependency to core/ | {strategy_counter.get('(b)', 0)} | Move shared dependency to core/ module |")
    md.append(f"| (c) duplicate with CANONICAL-SOURCE marker | {strategy_counter.get('(c)', 0)} | Intentional duplication; marker pairs source + target |")
    md.append(f"| (d) cycle-violation-remediation | {strategy_counter.get('(d)', 0)} | Refactor core/ target to remove the dep |")
    md.append(f"| (e) unmigrated-cite (pmo-platform/...) | {strategy_counter.get('(e)', 0)} | Re-run path-rewrite per the migration mechanism |")
    md.append(f"| (f) marker-paired-duplication | {strategy_counter.get('(f)', 0)} | Already-resolved per design |")
    md.append(f"| (g) operator-decide | {strategy_counter.get('(g)', 0)} | Suspect-pattern + cycle-markdown-doc-link route to operator |")
    md.append(f"| n/a (no action — OK / info) | {strategy_counter.get('n/a', 0)} | Reference is compliant or informational |")
    md.append("")

    md.append("## Per-Module Cross-Module Reference Outflow")
    md.append("")
    md.append("| Source module | Refs OUT (total) | via Public API | Suspect | Violations | Info |")
    md.append("|---|---|---|---|---|---|")
    for mod in MODULES:
        out_total = sum(1 for f in findings if f["source_module"] == mod)
        via_pub = sum(1 for f in findings if f["source_module"] == mod and f["via_public_api"] == "true")
        suspect = sum(1 for f in findings if f["source_module"] == mod and f["violation_class"] in ("suspect-pattern", "cycle-markdown-doc-link", "cycle-narrative-mention"))
        violations = sum(1 for f in findings if f["source_module"] == mod and f["violation_class"] in ("via-internal-api", "cycle-code-import"))
        info = sum(1 for f in findings if f["source_module"] == mod and f["violation_class"] == "info-adr-007-carry-forward")
        md.append(f"| {mod} | {out_total} | {via_pub} | {suspect} | {violations} | {info} |")
    md.append("")

    md.append("## Recommended Next Steps")
    md.append("")
    md.append("1. **Cycle violations (code-import class)** → operator routing decision; almost certainly architectural refactor or move-to-core. **Current count: " + str(cycle_code_import) + "**.")
    md.append("2. **via-internal-api violations (Cat-3 / Cat-4 false)** → batch into (a)/(b) strategy assignment. Each violation gets one per-edit plan.")
    md.append("3. **suspect-pattern + cycle-markdown-doc-link** → operator review; document acceptance OR route to (a)/(c)/refactor architecturally.")
    md.append("4. **info-adr-007-carry-forward** → no action required; these are accepted documentary cohesion signals per ADR-007 carry-forward contract.")
    md.append("")
    md.append("## Per-Violation Detail Table (excerpt)")
    md.append("")
    md.append("Full per-finding detail in companion TSV file `cross-module-audit-" + audit_date + ".tsv`.")
    md.append("")
    md.append("First 50 actionable findings (violation_class IN {via-internal-api, cycle-code-import, suspect-pattern, cycle-markdown-doc-link, cycle-narrative-mention}):")
    md.append("")
    md.append("| source_file | line | target_path | category | cross_ref_type | violation_class | strategy |")
    md.append("|---|---|---|---|---|---|---|")
    actionable = [
        f for f in findings
        if f["violation_class"] in (
            "via-internal-api",
            "cycle-code-import",
            "suspect-pattern",
            "cycle-markdown-doc-link",
            "cycle-narrative-mention",
        )
    ]
    for f in actionable[:50]:
        md.append(f"| `{f['source_file']}` | {f['line']} | `{f['target_path']}` | {f['category']} | {f['cross_ref_type']} | {f['violation_class']} | {f['recommended_strategy']} |")
    if len(actionable) > 50:
        md.append(f"| ... | ... | (additional {len(actionable) - 50} actionable findings in TSV) | | | | |")
    md.append("")

    md.append("## Module-Test Suite (Surface 4)")
    md.append("")
    md.append("Per the module-restructure spec Surface 4, each module is verified for link-integrity in isolation using `check-doc-links.py`:")
    md.append("")
    md.append("```bash")
    md.append("python3 core/deploy/tools/check-doc-links.py --target-paths \"operations/\" --output-format tsv | wc -l")
    md.append("python3 core/deploy/tools/check-doc-links.py --target-paths \"release/\" --output-format tsv | wc -l")
    md.append("python3 core/deploy/tools/check-doc-links.py --target-paths \"core/\" --output-format tsv | wc -l")
    md.append("```")
    md.append("")
    md.append("These line counts establish the per-module link-integrity baseline. Close verification re-runs against these baselines + this audit to confirm no regression.")
    md.append("")
    md.append("Per Q6 resolution in the module-restructure spec: real-invocation cross-module composition test (e.g., release-planner Mode B vs a test repo) is deferred to a later close-verification task per the parent acceptance criteria and operator-instance dependency. This release ships grep-structural verification (this audit + per-module link-integrity baselines) only.")
    md.append("")
    md.append("## Audit Replay Command")
    md.append("")
    md.append("```bash")
    md.append(f"core/deploy/tools/cross-module-audit.sh audit-output/cross-module-audit-{audit_date}.md audit-output/cross-module-audit-{audit_date}.tsv")
    md.append("```")
    md.append("")
    md.append("Audit is idempotent (read-only); re-runs at the same commit emit identical output.")
    md.append("")

    return "\n".join(md)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--md-output", help="Path to markdown summary report")
    p.add_argument("--tsv-output", help="Path to TSV machine-readable report")
    p.add_argument("--commit-sha", default="HEAD", help="Commit SHA stamped in report")
    p.add_argument("--audit-date", default="2026-05-27", help="Audit date YYYY-MM-DD")
    p.add_argument("--self-test", action="store_true", help="Run internal self-test fixtures and exit")
    args = p.parse_args()

    if args.self_test:
        return run_self_test()

    if not args.md_output or not args.tsv_output:
        p.error("--md-output and --tsv-output are required (unless --self-test)")

    # Walk all 3 modules
    all_findings: list[dict] = []
    for mod in MODULES:
        all_findings.extend(scan_module_for_cross_module_refs(mod))

    # Read Public API enumerations per module
    public_api_paths = {mod: read_public_api_paths(mod) for mod in MODULES}

    # Classify each finding
    classified = [classify_finding(f, public_api_paths) for f in all_findings]

    # Emit TSV
    tsv_path = Path(args.tsv_output)
    tsv_path.parent.mkdir(parents=True, exist_ok=True)
    tsv_path.write_text(emit_tsv(classified) + "\n", encoding="utf-8")

    # Emit markdown summary
    md_path = Path(args.md_output)
    md_path.parent.mkdir(parents=True, exist_ok=True)
    md_path.write_text(emit_summary_markdown(classified, args.commit_sha, args.audit_date) + "\n", encoding="utf-8")

    # Compute exit code per Surface 1.5
    cycle_code_import = sum(1 for f in classified if f["violation_class"] == "cycle-code-import")
    # Non-cycle violations: anything actionable that isn't a code-import cycle.
    # Includes via-internal-api (real ops/release→core violation), suspect-pattern
    # (Cat-5/Cat-6), AND cycle-markdown-doc-link / cycle-narrative-mention
    # (Cat-1/Cat-2 documentary that routes to operator-decide).
    non_cycle_violations = sum(
        1 for f in classified
        if f["violation_class"] in (
            "via-internal-api",
            "suspect-pattern",
            "cycle-markdown-doc-link",
            "cycle-narrative-mention",
        )
    )
    if cycle_code_import > 0:
        print(f"BLOCKER: {cycle_code_import} code-import cycle violations detected. Audit report: {md_path}", file=sys.stderr)
        return 1
    if non_cycle_violations > 0:
        print(f"Non-cycle violations: {non_cycle_violations}. Audit report: {md_path}", file=sys.stderr)
        return 2
    print(f"Audit clean. Report: {md_path}", file=sys.stderr)
    return 0


def run_self_test() -> int:
    """Minimal self-test fixtures (per Surface 9 verification + the established self-test convention)."""
    print("Running self-test fixtures...")

    # Fixture 1: source_module classifier
    assert source_module("core/disciplines/x.md") == "core"
    assert source_module("release/skills/y/SKILL.md") == "release"
    assert source_module("operations/templates/z.md") == "operations"
    assert source_module("docs/foo.md") is None
    print("  Fixture 1 OK: source_module classifier")

    # Fixture 2: target_module classifier
    assert target_module("core/skills/prompt-builder") == "core"
    assert target_module("release/governance/release-process.md") == "release"
    assert target_module("../release/foo.md") == "release"
    print("  Fixture 2 OK: target_module classifier")

    # Fixture 3: cross_ref_type classifier (uses a tmp file path)
    tmp_sh = Path("/tmp/dummy.sh")
    tmp_py = Path("/tmp/dummy.py")
    tmp_md = Path("/tmp/dummy.md")
    # Actual imports — code-import
    assert classify_cross_ref_type(tmp_sh, "source core/lib/x.sh") == "code-import"
    assert classify_cross_ref_type(tmp_py, "from core.foo import bar") == "code-import"
    assert classify_cross_ref_type(tmp_py, "import core.disciplines.foo") == "code-import"
    # Comment lines containing "import" — NOT code-import (FM-1 mitigation)
    assert classify_cross_ref_type(tmp_py, "# from core import bar — this is a comment") != "code-import"
    assert classify_cross_ref_type(tmp_sh, "# Mirror operations/references/ to source") != "code-import"
    # Markdown links — markdown-doc-link
    assert classify_cross_ref_type(tmp_md, "See [core](core/foo.md) for ...") == "markdown-doc-link"
    # Plain prose — narrative-mention
    assert classify_cross_ref_type(tmp_md, "The operations/ folder contains") == "narrative-mention"
    # String literal in python (not an import statement) — narrative-mention
    assert classify_cross_ref_type(tmp_py, '    "release/governance/release-process.md",') == "narrative-mention"
    print("  Fixture 3 OK: cross_ref_type classifier")

    # Fixture 4: ADR-007 carry-forward allowance (v1 base cases preserved + v2 extended cases)
    # v1 base — disciplines + schemas → governance/release-process.md OR references/pipeline/
    assert is_carry_forward_allowed(
        "core", "core/disciplines/operating-model.md",
        "release/governance/release-process.md", "markdown-doc-link"
    ) is True
    assert is_carry_forward_allowed(
        "core", "core/disciplines/discovery-discipline.md",
        "release/references/pipeline/stage-05-solutioning.md", "markdown-doc-link"
    ) is True
    # v2 extension (Pattern-P1) — narrative-mention also allowed (was rejected in v1)
    assert is_carry_forward_allowed(
        "core", "core/disciplines/operating-model.md",
        "release/governance/release-process.md", "narrative-mention"
    ) is True  # v2: narrative-mention now allowed
    # v2 extension — disciplines → release/references (broader than just pipeline/)
    assert is_carry_forward_allowed(
        "core", "core/disciplines/execution-framework.md",
        "release/references/specs/methodology-parameterization-v1.md", "markdown-doc-link"
    ) is True
    # v2 extension — disciplines → release/skills (architecture-overview documenting skill layout)
    assert is_carry_forward_allowed(
        "core", "core/disciplines/architecture-overview.md",
        "release/skills/release-planner/SKILL.md", "narrative-mention"
    ) is True
    # v2 extension — standards → release/references
    assert is_carry_forward_allowed(
        "core", "core/standards/upstream-reference-catalog.md",
        "release/references/specs/foo.md", "markdown-doc-link"
    ) is True
    # v2 extension — ADRs → release/ADRs (architectural cross-references)
    assert is_carry_forward_allowed(
        "core", "core/ADRs/ADR-007-core-module-boundary.md",
        "release/ADRs/ADR-002-modular-pipeline-stages-split.md", "narrative-mention"
    ) is True
    # v2 extension — ADRs → operations/ (architectural cross-references symmetric to release)
    assert is_carry_forward_allowed(
        "core", "core/ADRs/ADR-007-core-module-boundary.md",
        "operations/schemas/", "narrative-mention"
    ) is True
    # v2 extension — core/README.md is also allowed source
    assert is_carry_forward_allowed(
        "core", "core/README.md",
        "release/governance/release-process.md", "narrative-mention"
    ) is True
    # v2 extension — relative-path target resolution
    assert is_carry_forward_allowed(
        "core", "core/ADRs/README.md",
        "../../release/ADRs/", "markdown-doc-link"
    ) is True
    # v2 extension — schemas → release/skills (output-contracts schema enumerating skills)
    assert is_carry_forward_allowed(
        "core", "core/schemas/per-skill-output-contracts.md",
        "release/skills/implementation-planner/SKILL.md", "markdown-doc-link"
    ) is True
    # Negative cases (preserved + new boundaries)
    assert is_carry_forward_allowed(
        "core", "core/disciplines/operating-model.md",
        "release/governance/release-process.md", "code-import"
    ) is False  # code-import remains BLOCKER (architectural invariant preserved)
    assert is_carry_forward_allowed(
        "core", "core/skills/prompt-builder/SKILL.md",
        "release/governance/release-process.md", "markdown-doc-link"
    ) is False  # core/skills/ NOT in allowed source prefixes
    print("  Fixture 4 OK: ADR-007 carry-forward allowance (v1 + v2 extension)")

    # Fixture 5: Deploy infrastructure exemption (Pattern-P4)
    assert is_deploy_infrastructure("core/deploy/deploy.sh") is True
    assert is_deploy_infrastructure("core/deploy/tools/cross_module_audit_helper.py") is True
    assert is_deploy_infrastructure("core/deploy/tools/cross-module-audit.sh") is True
    assert is_deploy_infrastructure("core/deploy/tools/check-doc-links.py") is True
    # Not deploy infrastructure
    assert is_deploy_infrastructure("core/disciplines/operating-model.md") is False
    assert is_deploy_infrastructure("core/deploy/tools/generate_release_index.py") is False  # not in exemption set
    assert is_deploy_infrastructure("release/skills/release-planner/SKILL.md") is False
    print("  Fixture 5 OK: deploy infrastructure exemption (Pattern-P4)")

    # Fixture 6: Prose-disjunction false-positive exemption (Pattern-P5)
    assert is_prose_disjunction("release/issue") is True
    assert is_prose_disjunction("release/deployment") is True
    # Real paths are NOT prose disjunctions
    assert is_prose_disjunction("release/governance/release-process.md") is False
    assert is_prose_disjunction("release/skills/") is False
    assert is_prose_disjunction("operations/templates/") is False
    print("  Fixture 6 OK: prose-disjunction false-positive exemption (Pattern-P5)")

    print("self-test OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())

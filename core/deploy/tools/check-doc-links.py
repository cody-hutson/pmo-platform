#!/usr/bin/env python3
"""Doc-link drift detection primitive + rewrite-map mode.

Two modes (mode discrimination via flag presence):

  broken-refs mode (default — when --from-path/--to-path NOT supplied):
    Parses markdown link references in target files, resolves relative paths,
    and reports broken cross-references as TSV/JSON/GitHub-Actions output.
    Exit codes: 0 = no broken refs, 1 = broken refs found,
    3 = path-resolution failure (with --require-targets: a declared
    --target-paths glob entry resolved to zero files — the target surface is
    unverifiable, not clean). Exit 3 matches the cross-module-audit.sh family
    convention so deploy.sh can distinguish "found drift" (1) from "could not
    run against the target" (3).

  rewrite-map mode (when BOTH --from-path AND --to-path supplied):
    Scans target files for references whose path starts with --from-path,
    generates a rewrite map showing the substituted target path under --to-path.
    EMIT-ONLY — never mutates any file. Output: 4-column TSV (source_file,
    line, old_path, new_path) by default; JSON or markdown via --output-format.
    Exit codes: 0 always (unless argparse fails or flag asymmetry — exit 2).

Categories (broken-refs mode):
  broken-cross-ref  Target file does not exist
  broken-anchor     Target file exists but anchor (#section) doesn't
  deleted-target    Target path matches a known-deleted pattern

Severity (broken-refs mode):
  P1  Must-fix (active governance / current standards)
  P2  Should-fix (reference docs, supporting material)
  P3  Informational (archived / audit artifacts; usually allowlisted)

Authored under the Stage 5 spec.
Extended per a later module-restructure Stage 5 spec — module-aware
prefix table + --from-path/--to-path rewrite-map mode. Check 15 retired in v2;
v2 deploy.sh ships Check 14 only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path

# Repo-root resolution (#760). Precedence at the call site (main()):
#   1. --workspace-root CLI flag   (explicit per-invocation override)
#   2. CLAUDE_WORKSPACE_ROOT env   (canonical platform var — hooks/deploy.sh/release-tools)
#   3. parents[3] from this file   (in-repo default — byte-identical to pre-#760 behavior)
# Tiers 2+3 resolve at MODULE LOAD so cross_module_audit_helper.py (which binds
# _cdl.WORKSPACE_ROOT at import and never goes through main()) keeps a deterministic
# value AND transparently honors the env override. Tier 1 is threaded through main()
# only — see resolve_target()/is_allowlisted()/expand_globs()/find_unresolved_globs()
# optional workspace_root params.
_DEFAULT_WORKSPACE_ROOT = Path(__file__).resolve().parents[3]


def resolve_workspace_root(cli_value: str | None = None) -> Path:
    if cli_value:
        return Path(cli_value).expanduser().resolve()
    env_value = os.environ.get("CLAUDE_WORKSPACE_ROOT")
    if env_value:
        return Path(env_value).expanduser().resolve()
    return _DEFAULT_WORKSPACE_ROOT


# Module-level default (env → parents[3]); CLI override applied in main().
# Name + parents[3]-when-unset semantics preserved for the
# cross_module_audit_helper.py importer (binds _cdl.WORKSPACE_ROOT).
WORKSPACE_ROOT = resolve_workspace_root()

# Canonical link-resolution rule (ADR-085): a markdown link resolves relative to
# the source file's directory; a leading `/` denotes the workspace (repo) root;
# there is NO bare module-prefix fallback — a bare `core/…` / `release/…` from a
# non-root file is an ordinary relative path (and therefore usually broken). The
# former V1/V2 workspace-rooted prefix tables (ADR-009 Rule 2), which drove the
# now-retired fallback, are removed. Both link checkers (this one and
# release/tools/check-release-links.py) implement the one rule identically — see
# core/standards/doc-link-maintenance-protocol.md § Path resolution.

INLINE_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
REF_LINK_RE = re.compile(r"\[([^\]]+)\]\[([^\]]*)\]")
REF_DEF_RE = re.compile(r"^\[([^\]]+)\]:\s*(\S+)")
FENCE_RE = re.compile(r"^(```|~~~)")
# Leading blockquote markers (`>` optionally repeated, with surrounding
# whitespace) preceding a fence — e.g. `> ```markdown`. A fenced code block
# nested inside a blockquote (a worked example quoted via `>`) must still be
# excluded from link extraction; without stripping the marker the fence opener
# is not recognized and the example's illustrative links surface as findings.
BLOCKQUOTE_PREFIX_RE = re.compile(r"^(?:\s*>)+\s?")


def strip_code_blocks(lines: list[str]) -> list[tuple[int, str]]:
    """Return (1-indexed line number, content) pairs with fenced blocks blanked.

    Recognizes both top-of-line fences (```` ``` ````/`~~~`) and fences nested
    inside a blockquote (`> ```` ``` ````), so worked-example code quoted via `>`
    is excluded from link extraction (issue #169).
    """
    out: list[tuple[int, str]] = []
    in_fence = False
    for i, line in enumerate(lines, start=1):
        # Strip any leading blockquote marker(s) before testing for a fence, so
        # a `> ```...` opener inside a quoted example is detected.
        defenced = BLOCKQUOTE_PREFIX_RE.sub("", line)
        if FENCE_RE.match(defenced.lstrip()):
            in_fence = not in_fence
            out.append((i, ""))
            continue
        out.append((i, "" if in_fence else line))
    return out


def collect_ref_definitions(content_lines: list[tuple[int, str]]) -> dict[str, str]:
    defs: dict[str, str] = {}
    for _, line in content_lines:
        m = REF_DEF_RE.match(line)
        if m:
            defs[m.group(1).lower()] = m.group(2)
    return defs


def extract_links(source_path: Path, content_lines: list[tuple[int, str]]) -> list[tuple[int, str]]:
    """Return list of (line_number, target_path) — internal links only."""
    refs = collect_ref_definitions(content_lines)
    found: list[tuple[int, str]] = []
    for line_no, line in content_lines:
        for m in INLINE_LINK_RE.finditer(line):
            target = m.group(2).split()[0]
            if not is_internal(target):
                continue
            found.append((line_no, target))
        for m in REF_LINK_RE.finditer(line):
            label = (m.group(2) or m.group(1)).lower()
            if label in refs and is_internal(refs[label]):
                found.append((line_no, refs[label]))
    return found


def is_internal(target: str) -> bool:
    if not target:
        return False
    if target.startswith(("http://", "https://", "mailto:", "tel:", "ftp://")):
        return False
    if target.startswith("#"):
        return False
    # Strip the #anchor / ?query so the path-shape tests below see only the
    # path portion (consistent with resolve_target's split at the call site).
    path_part = target.split("?", 1)[0].split("#", 1)[0]
    if not path_part:
        return False
    # Templated-placeholder skip (issue #169): a path portion that carries an
    # angle-bracket segment (`<...>`) is a documentation placeholder, not a
    # resolvable literal path — e.g. `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`,
    # `../.../<mover>.md`, `<sibling.md>`. Literal `<`/`>` are not valid in
    # committed repo file paths, so this can never false-exclude a real link.
    # Same class as the http/mailto/# skips above; covers every `<...>` token
    # in one rule and is self-maintaining (new token families need no upkeep).
    if "<" in path_part and ">" in path_part:
        return False
    # Meta-doc-literal skip (issue #169): a path portion with NO path separator
    # ('/') AND no filename extension ('.') cannot denote an internal markdown
    # file — a real intra-repo link always carries a '/' (a path) or a '.' (a
    # file extension). Bare barewords are link-SYNTAX illustration in prose —
    # e.g. `[text](path)`, `[#N](URL)` in docs that EXPLAIN link forms.
    # Verified against the #169 scope: of 109 such targets in the corpus, 0
    # resolve, so this excludes only documentation literals, never a live link.
    if "/" not in path_part and "." not in path_part:
        return False
    # Ellipsis-placeholder skip (issue #169): a path portion that is ONLY dots,
    # three or more (`...`), is a markdown-syntax ellipsis placeholder (e.g. the
    # `[#N](...)` link-shape literal in the release-notes standard), never a real
    # path. Single '.' (current dir) and '..' (parent dir) are genuine relative
    # references and are deliberately NOT skipped (verified: '.' resolves live in
    # the corpus; only the `...` ellipsis is a placeholder).
    if re.fullmatch(r"\.{3,}", path_part):
        return False
    return True


def resolve_target(
    source_file: Path, target: str, workspace_root: Path = WORKSPACE_ROOT
) -> tuple[Path, str | None]:
    """Resolve a markdown link target to a filesystem path (canonical rule, ADR-085).

    Three clauses, matching GitHub's rendered-blob behavior and identical to
    release/tools/check-release-links.py:
      1. A link resolves relative to the source file's directory.
      2. A leading `/` denotes the workspace (repo) root.
      3. There is NO bare module-prefix fallback — a bare `core/…` / `release/…`
         from a non-root file is an ordinary relative path (clause 1), so it is
         broken unless it happens to resolve relative to the source.

    Return (resolved_path, anchor_or_None). The `#anchor` / `?query` are stripped
    before path resolution.

    workspace_root defaults to the module-level WORKSPACE_ROOT (env→parents[3]);
    main() passes the --workspace-root CLI value for deployed-tree validation (#760).
    """
    target = target.split("?", 1)[0]
    if "#" in target:
        path_part, anchor = target.split("#", 1)
    else:
        path_part, anchor = target, None
    if not path_part:
        return source_file, anchor
    # Clause 2: a leading `/` anchors on the workspace (repo) root.
    if path_part.startswith("/"):
        return Path(os.path.realpath(workspace_root / path_part.lstrip("/"))), anchor
    # Clauses 1 + 3: everything else resolves relative to the source directory.
    # No bare module-prefix fallback — a bare `core/…` from a non-root file simply
    # resolves (and usually breaks) as a relative path, matching GitHub.
    return Path(os.path.realpath(source_file.parent / path_part)), anchor


def classify_severity(source_file: Path) -> str:
    """Classify a source file's severity tier.

    P1 (must-fix):
      Active governance + skill SKILL.md + per-module rules (v1 + v2 both honored).
    P2 (should-fix):
      Reference docs + supporting material (v1 reference/ + engineering/rules/;
      v2 disciplines/ + schemas/ + specs/ + standards/).
    P3 (informational):
      Everything else (archived / audit artifacts; usually allowlisted).
    """
    s = str(source_file)
    # P1 — must-fix
    p1_markers = (
        "/governance/",
        "/.claude/rules/",
        "/skills/",
        # v2 per-module rules
        "/core/rules/",
        "/release/rules/",
    )
    if any(m in s for m in p1_markers):
        return "P1"
    # P2 — should-fix
    p2_markers = (
        "/reference/",
        "/engineering/rules/",
        # v2 codified-knowledge per-module
        "/core/disciplines/",
        "/core/schemas/",
        "/core/specs/",
        "/core/standards/",
        "/release/standards/",
        "/release/specs/",
        "/release/references/",
        "/operations/standards/",
        "/operations/references/",
    )
    if any(m in s for m in p2_markers):
        return "P2"
    return "P3"


def is_allowlisted(
    source_file: Path,
    allowlist_patterns: list[str],
    workspace_root: Path = WORKSPACE_ROOT,
) -> bool:
    try:
        rel = str(source_file.relative_to(workspace_root))
    except ValueError:
        rel = str(source_file)
    for pat in allowlist_patterns:
        pat_clean = pat.strip()
        if not pat_clean or pat_clean.startswith("#"):
            continue
        if pat_clean.endswith("/"):
            if rel.startswith(pat_clean) or ("/" + pat_clean) in ("/" + rel):
                return True
        if Path(rel).match(pat_clean):
            return True
        if pat_clean in rel:
            return True
    return False


def load_allowlist(path: Path | None) -> list[str]:
    if path is None or not path.exists():
        return []
    return [line.rstrip("\n") for line in path.read_text(encoding="utf-8").splitlines() if line.strip() and not line.lstrip().startswith("#")]


def expand_globs(globs: list[str], workspace_root: Path = WORKSPACE_ROOT) -> list[Path]:
    out: list[Path] = []
    for g in globs:
        g = g.strip()
        if not g:
            continue
        as_path = Path(g) if Path(g).is_absolute() else workspace_root / g
        if as_path.is_file():
            out.append(as_path)
        elif as_path.is_dir():
            out.extend(sorted(as_path.rglob("*.md")))
        else:
            matches = sorted(workspace_root.glob(g))
            for m in matches:
                if m.is_file() and m.suffix == ".md":
                    out.append(m)
                elif m.is_dir():
                    out.extend(sorted(m.rglob("*.md")))
    return out


def find_unresolved_globs(
    globs: list[str], workspace_root: Path = WORKSPACE_ROOT
) -> list[str]:
    """Return the subset of declared glob entries that resolve to ZERO files.

    Mirrors expand_globs's per-entry resolution semantics (literal file, literal
    dir, then glob pattern) but reports which declared entries yielded nothing
    rather than the matched files. A zero-yield entry is a path-resolution
    failure (clause 2 of the fail-loud contract): the scan surface is missing,
    typo'd, or relocated — unverifiable, not clean. Kept separate from
    expand_globs so the latter's return contract is unchanged (the
    cross_module_audit_helper.py importer depends on it).
    """
    unresolved: list[str] = []
    for g in globs:
        g = g.strip()
        if not g:
            continue
        as_path = Path(g) if Path(g).is_absolute() else workspace_root / g
        if as_path.is_file():
            continue
        if as_path.is_dir():
            if not any(as_path.rglob("*.md")):
                unresolved.append(g)
            continue
        matched = False
        for m in sorted(workspace_root.glob(g)):
            if m.is_file() and m.suffix == ".md":
                matched = True
                break
            if m.is_dir() and any(m.rglob("*.md")):
                matched = True
                break
        if not matched:
            unresolved.append(g)
    return unresolved


def scan_file(
    source_file: Path, allowlist: list[str], workspace_root: Path = WORKSPACE_ROOT
) -> list[dict]:
    if is_allowlisted(source_file, allowlist, workspace_root):
        return []
    try:
        text = source_file.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    lines = text.splitlines()
    content = strip_code_blocks(lines)
    findings: list[dict] = []
    for line_no, target in extract_links(source_file, content):
        resolved, anchor = resolve_target(source_file, target, workspace_root)
        if not resolved.exists():
            try:
                rel_source = str(source_file.relative_to(workspace_root))
            except ValueError:
                rel_source = str(source_file)
            findings.append({
                "source_file": rel_source,
                "line": line_no,
                "target": target,
                "category": "broken-cross-ref",
                "severity": classify_severity(source_file),
                "remediation_recommendation": f"Verify path exists: {resolved}",
            })
    return findings


def scan_file_for_rewrite_map(
    source_file: Path,
    from_path: str,
    to_path: str,
    allowlist: list[str],
    workspace_root: Path = WORKSPACE_ROOT,
) -> list[dict]:
    """Scan source_file for references whose link target starts with from_path.

    For each match, emit a rewrite entry mapping old_path → new_path. The
    substitution preserves anchors (#section) and queries (?key=val). EMIT-ONLY
    — this function never mutates source_file (enforced structurally via
    self-test Fixture 6 mtime + content-hash assertion).

    Behavioral rules (per Stage 5 spec Surface 2.4):
      1. EMIT-ONLY — never writes to source_file.
      2. No broken-ref check — emits map entries even for refs that already
         resolve. Consumer decides which to apply.
      3. Allowlist honored — allowlisted files skipped.
      4. Fenced-code-block exclusion honored — same strip_code_blocks logic.
      5. Anchor/query preservation — # and ? segments mirror to new_path.

    Returns list of dicts with keys: source_file, line, old_path, new_path.
    """
    if is_allowlisted(source_file, allowlist, workspace_root):
        return []
    try:
        text = source_file.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    lines = text.splitlines()
    content = strip_code_blocks(lines)
    entries: list[dict] = []
    for line_no, target in extract_links(source_file, content):
        # Split target into path + anchor + query parts. We match --from-path
        # against the PATH portion only (preserves anchor/query for new_path).
        if "#" in target:
            target_path, rest = target.split("#", 1)
            suffix = "#" + rest
        elif "?" in target:
            target_path, rest = target.split("?", 1)
            suffix = "?" + rest
        else:
            target_path, suffix = target, ""
        if target_path.startswith(from_path):
            new_path = to_path + target_path[len(from_path):] + suffix
            try:
                rel_source = str(source_file.relative_to(workspace_root))
            except ValueError:
                rel_source = str(source_file)
            entries.append({
                "source_file": rel_source,
                "line": line_no,
                "old_path": target,
                "new_path": new_path,
            })
    return entries


def emit_tsv(findings: list[dict]) -> str:
    header = "source_file\tline\ttarget\tcategory\tseverity\tremediation_recommendation"
    rows = [header]
    for f in findings:
        rows.append(f"{f['source_file']}\t{f['line']}\t{f['target']}\t{f['category']}\t{f['severity']}\t{f['remediation_recommendation']}")
    return "\n".join(rows)


def emit_json(findings: list[dict]) -> str:
    return json.dumps(findings, indent=2)


def emit_github(findings: list[dict]) -> str:
    return "\n".join(f"::warning file={f['source_file']},line={f['line']}::Broken link target '{f['target']}' ({f['category']}, {f['severity']})" for f in findings)


def emit_rewrite_map_tsv(entries: list[dict]) -> str:
    """4-column TSV: source_file<TAB>line<TAB>old_path<TAB>new_path"""
    header = "source_file\tline\told_path\tnew_path"
    rows = [header]
    for e in entries:
        rows.append(f"{e['source_file']}\t{e['line']}\t{e['old_path']}\t{e['new_path']}")
    return "\n".join(rows)


def emit_rewrite_map_json(entries: list[dict]) -> str:
    return json.dumps(entries, indent=2)


def emit_rewrite_map_markdown(entries: list[dict]) -> str:
    """Markdown table for direct paste into per-edit plans."""
    lines = ["| source_file | line | old_path | new_path |", "|---|---|---|---|"]
    for e in entries:
        lines.append(f"| {e['source_file']} | {e['line']} | {e['old_path']} | {e['new_path']} |")
    return "\n".join(lines)


def run_self_test() -> int:
    """Sanity check: parser + resolver + rewrite-map mode + EMIT-ONLY enforcement.

    9 fixtures:
      1. Existing: code-block exclusion + single broken ref.
      2. Anti-fallback regression guard (ADR-085): a bare module-prefixed link
         from a non-root file reads BROKEN even when the same path EXISTS at the
         workspace root (the ADR-009 Rule-2 workspace-root fallback is retired),
         while the leading-`/` form of the same target resolves.
      3. NEW: rewrite-map TSV output mode.
      4. AC-3 five-form parity (doc-links side): the five link forms in #1471's
         AC-3 table return the canonical verdicts; the shared repro cross-checks
         these against check-release-links.py.
      5. NEW: anchor preservation in rewrite-map mode.
      6. NEW: EMIT-ONLY structural enforcement (mtime + content-hash unchanged
              after scan_file_for_rewrite_map invocation) — per Stage 5 spec
              Surface 2.4 rule #1 + adversarial-review PR-3/FM-1.
      7. NEW: --require-targets path-resolution-failure detection (zero-yield
              glob → flagged; populated scan-root → not flagged) — the #459
              fail-loud contract clause 2.
      8. NEW (issue #169): templated-placeholder + meta-doc-literal exclusion is
              PRECISE — `<OPERATOR_INSTANCE_*>` / `<sibling.md>` angle-bracket
              tokens, bare barewords (`path`/`URL`), the `...` ellipsis, and a
              blockquoted (`> ```...`) worked-example link are all skipped, WHILE
              a real broken ref in the SAME doc still fires (the precision probe
              that proves the exclusion is finding-removing, not gate-blinding).
      9. NEW (#760): relocatable workspace-root + precedence chain. A /-rooted
              link to a file that exists ONLY under a sandbox root resolves GREEN
              when resolve_target is given that root and BROKEN under the default
              root (proves the override re-roots /-prefixed links), AND the
              resolve_workspace_root precedence holds: CLI > $CLAUDE_WORKSPACE_ROOT
              > parents[3] default (hermetic — env saved/restored around the probe).
    """
    import tempfile

    # ─── Fixture 1: code-block exclusion + single broken ref (original) ────
    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)
        doc = td_path / "doc.md"
        doc.write_text("Inline [bad](nonexistent.md) ref.\n```\n[ignored-in-code](also.md)\n```\n")
        findings = scan_file(doc, [])
        assert len(findings) == 1, f"fixture 1: expected 1 finding, got {len(findings)}: {findings}"
        assert findings[0]["target"] == "nonexistent.md", "fixture 1: target mismatch"
        # Code-block exclusion check (target inside fence should not appear)
        assert all(f["target"] != "also.md" for f in findings), "fixture 1: code-block exclusion failed"

    # ─── Fixture 2: anti-fallback regression guard (ADR-085) ──────────────────
    # A bare module-prefixed link (`core/…`) from a NON-root source file must read
    # BROKEN even when that exact path EXISTS at the workspace root — proving the
    # ADR-009 Rule-2 workspace-root fallback is retired and bare prefixes are
    # ordinary relative paths (canonical clause 3). Hermetic: resolve_target is
    # exercised directly against a sandbox root that holds the real target.
    with tempfile.TemporaryDirectory() as td:
        sandbox = Path(td).resolve()
        (sandbox / "core" / "disciplines").mkdir(parents=True)
        (sandbox / "core" / "disciplines" / "real.md").write_text("# real target at repo root\n")
        src = sandbox / "core" / "rules" / "test.md"
        src.parent.mkdir(parents=True)
        src.write_text("See [x](core/disciplines/real.md)\n")
        # Bare prefix → relative to source dir (sandbox/core/rules/core/…) → missing.
        resolved_bare, _ = resolve_target(src, "core/disciplines/real.md", sandbox)
        assert not resolved_bare.exists(), (
            f"fixture 2: bare module-prefixed link resolved via a workspace-root "
            f"fallback that ADR-085 retires (resolved to {resolved_bare})"
        )
        # Contrast: the leading-`/` form of the SAME target resolves at the root.
        resolved_rooted, _ = resolve_target(src, "/core/disciplines/real.md", sandbox)
        assert resolved_rooted.exists(), (
            f"fixture 2: leading-`/` link did not resolve at the workspace root "
            f"(resolved to {resolved_rooted})"
        )

    # ─── Fixture 3: rewrite-map TSV mode ──────────────────────────────────
    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)
        doc = td_path / "doc.md"
        doc.write_text("See [target](pmo-platform/reference/explanation/foo.md)\n")
        entries = scan_file_for_rewrite_map(
            doc,
            from_path="pmo-platform/reference/explanation/",
            to_path="core/disciplines/",
            allowlist=[],
        )
        assert len(entries) == 1, f"fixture 3: expected 1 entry, got {len(entries)}"
        assert entries[0]["old_path"] == "pmo-platform/reference/explanation/foo.md", "fixture 3: old_path mismatch"
        assert entries[0]["new_path"] == "core/disciplines/foo.md", "fixture 3: new_path mismatch"
        # TSV emit shape — 4 columns ⇒ 3 tabs per row × 2 rows (header + 1 data) = 6 tabs
        tsv = emit_rewrite_map_tsv(entries)
        assert tsv.startswith("source_file\tline\told_path\tnew_path"), "fixture 3: TSV header mismatch"
        assert tsv.count("\t") == 6, f"fixture 3: TSV column count wrong (got {tsv.count(chr(9))}, expected 6)"
        # JSON + markdown emit shapes
        assert emit_rewrite_map_json(entries).startswith("["), "fixture 3: JSON shape wrong"
        md = emit_rewrite_map_markdown(entries)
        assert md.startswith("| source_file | line | old_path | new_path |"), "fixture 3: markdown header mismatch"
        assert md.count("|") == 15, f"fixture 3: markdown pipe count wrong (got {md.count(chr(124))}, expected 15: 5/row × 3 rows)"

    # ─── Fixture 4: AC-3 five-form parity (doc-links side) ────────────────────
    # The canonical rule (ADR-085) makes this checker agree with
    # check-release-links.py on all five link forms in #1471's AC-3 table. This
    # fixture pins the doc-links verdicts; the shared repro cross-checks them
    # against check-release-links.py. Hermetic sandbox root.
    with tempfile.TemporaryDirectory() as td:
        sandbox = Path(td).resolve()
        (sandbox / "core" / "disciplines").mkdir(parents=True)
        (sandbox / "core" / "disciplines" / "real.md").write_text("# target\n")
        (sandbox / "core" / "rules").mkdir(parents=True)
        (sandbox / "core" / "rules" / "sib.md").write_text("# sibling target\n")
        src = sandbox / "core" / "rules" / "test.md"
        src.write_text("probe\n")
        ac3_forms = [
            # (target, expected_exists)
            ("sib.md", True),                     # relative, resolves
            ("missing.md", False),                # relative, broken
            ("../disciplines/real.md", True),     # relative via ../, resolves
            ("core/disciplines/real.md", False),  # bare workspace-rooted → broken (no fallback)
            ("/core/disciplines/real.md", True),  # leading-`/` → repo root, resolves
        ]
        for target, expected in ac3_forms:
            resolved, _ = resolve_target(src, target, sandbox)
            assert resolved.exists() == expected, (
                f"fixture 4: form {target!r} expected exists={expected}, "
                f"got {resolved.exists()} (resolved {resolved})"
            )

    # ─── Fixture 5: anchor preservation in rewrite-map mode ───────────────
    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)
        doc = td_path / "anchor.md"
        doc.write_text("See [a](pmo-platform/reference/explanation/foo.md#section-2)\n")
        entries = scan_file_for_rewrite_map(
            doc,
            from_path="pmo-platform/reference/explanation/",
            to_path="core/disciplines/",
            allowlist=[],
        )
        assert len(entries) == 1, f"fixture 5: expected 1 entry, got {len(entries)}"
        assert entries[0]["new_path"] == "core/disciplines/foo.md#section-2", \
            f"fixture 5: anchor preservation failed; got {entries[0]['new_path']}"

    # ─── Fixture 6: EMIT-ONLY structural enforcement (mtime + content-hash) ─
    # Per Stage 5 spec Surface 2.4 rule #1 + adversarial-review PR-3/FM-1: convert EMIT-ONLY from behavioral contract to executable assertion.
    # Snapshot file mtime + SHA-256 content hash BEFORE invocation; re-check AFTER.
    # Failure indicates an unintended write-path was introduced.
    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)
        doc = td_path / "emit_only.md"
        content_before = (
            "[a](pmo-platform/reference/explanation/foo.md)\n"
            "[b](pmo-platform/reference/explanation/bar.md)\n"
            "[c](pmo-platform/reference/explanation/baz.md)\n"
        )
        doc.write_text(content_before)
        mtime_before = doc.stat().st_mtime
        hash_before = hashlib.sha256(doc.read_bytes()).hexdigest()
        # Invoke rewrite-map scan — must not mutate the file.
        _ = scan_file_for_rewrite_map(
            doc,
            from_path="pmo-platform/reference/explanation/",
            to_path="core/disciplines/",
            allowlist=[],
        )
        mtime_after = doc.stat().st_mtime
        hash_after = hashlib.sha256(doc.read_bytes()).hexdigest()
        assert mtime_before == mtime_after, \
            f"fixture 6 EMIT-ONLY violation: mtime changed ({mtime_before} → {mtime_after})"
        assert hash_before == hash_after, \
            f"fixture 6 EMIT-ONLY violation: content hash changed ({hash_before[:8]} → {hash_after[:8]})"

    # ─── Fixture 7: --require-targets path-resolution-failure detection ────
    # Clause 2 of the fail-loud contract: a glob resolving to zero files is a
    # path-resolution failure. find_unresolved_globs must flag a guaranteed-
    # missing scan-root and pass a resolvable one. A directory that exists but
    # contains no .md files is ALSO a zero-yield (unverifiable) target.
    missing_glob = "core/__definitely_not_a_real_dir_zzqx__/"
    unresolved = find_unresolved_globs([missing_glob])
    assert unresolved == [missing_glob], \
        f"fixture 7: missing scan-root not flagged (got {unresolved})"
    # A real, populated scan-root must NOT be flagged.
    resolvable = find_unresolved_globs(["core/rules/"])
    assert resolvable == [], \
        f"fixture 7: populated scan-root wrongly flagged as unresolved (got {resolvable})"
    # An existing dir with zero .md files is a zero-yield target → flagged.
    with tempfile.TemporaryDirectory() as td:
        empty_dir = Path(td) / "no_md_here"
        empty_dir.mkdir()
        (empty_dir / "notes.txt").write_text("not markdown\n")
        empty_yield = find_unresolved_globs([str(empty_dir)])
        assert empty_yield == [str(empty_dir)], \
            f"fixture 7: dir with zero .md files not flagged (got {empty_yield})"

    # ─── Fixture 8: placeholder/meta-doc-literal exclusion PRECISION (issue #169)
    # The token-class + meta-doc-literal skips must remove ONLY non-resolvable
    # documentation placeholders, never a real broken ref in the same file —
    # otherwise the PR gate would be blinded to genuine drift. Build one doc that
    # mixes every excluded form with a single GENUINE broken ref and assert that
    # exactly the genuine ref (and only it) survives extraction.
    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)
        doc = td_path / "placeholder_precision.md"
        doc.write_text(
            # angle-bracket operator-instance token — skipped
            "Operator log at [log](<OPERATOR_INSTANCE_RELEASE_LOG_PATH>).\n"
            # angle-bracket generic doc-illustration placeholder — skipped
            "Move via [a sibling](<sibling.md>) or [mid-path](../x/<mover>.md).\n"
            # bareword link-syntax literals (no '/' and no '.') — skipped
            "Syntax shown as [text](path) and [issue](URL).\n"
            # ellipsis placeholder — skipped
            "Line shape `[#N](...)` rendered here: [n](...).\n"
            # blockquoted worked-example fence — its inner link is skipped
            "> ```markdown\n"
            "> See [release note](release/releases/notes/v9.9_RELEASE_NOTES.md).\n"
            "> ```\n"
            # THE ONE GENUINE broken ref — must survive
            "But this [real link](definitely-missing-target.md) is broken.\n"
        )
        findings = scan_file(doc, [])
        assert len(findings) == 1, (
            f"fixture 8: expected exactly 1 finding (the genuine broken ref), got "
            f"{len(findings)}: {[f['target'] for f in findings]}"
        )
        assert findings[0]["target"] == "definitely-missing-target.md", (
            f"fixture 8: surviving finding is not the genuine broken ref "
            f"(got {findings[0]['target']!r})"
        )
        # Belt-and-suspenders: none of the excluded placeholder forms leaked in.
        leaked = {f["target"] for f in findings} & {
            "<OPERATOR_INSTANCE_RELEASE_LOG_PATH>", "<sibling.md>", "../x/<mover>.md",
            "path", "URL", "...", "release/releases/notes/v9.9_RELEASE_NOTES.md",
        }
        assert not leaked, f"fixture 8: excluded placeholder(s) leaked as findings: {leaked}"

    # ─── Fixture 9: relocatable workspace-root + precedence chain (#760) ────
    # Proves (a) a relocated root actually re-roots /-prefixed links, and (b) the
    # resolve_workspace_root precedence: CLI > $CLAUDE_WORKSPACE_ROOT > default.
    # (a) Re-rooting proof. Build a sandbox tree whose root holds a real target
    #     reachable ONLY via the sandbox root. A /-rooted link resolves GREEN when
    #     resolve_target is given the sandbox root, and BROKEN under the default
    #     root (the in-repo WORKSPACE_ROOT, where that sandbox path does not exist).
    with tempfile.TemporaryDirectory() as td:
        sandbox = Path(td).resolve()
        (sandbox / "core" / "disciplines").mkdir(parents=True)
        real_target = sandbox / "core" / "disciplines" / "real.md"
        real_target.write_text("# real target under the sandbox root\n")
        src = sandbox / "core" / "rules" / "test.md"
        src.parent.mkdir(parents=True)
        src.write_text("See [x](/core/disciplines/real.md)\n")
        # Override → /-rooted link re-roots under the sandbox and RESOLVES.
        resolved_override, _ = resolve_target(src, "/core/disciplines/real.md", sandbox)
        assert resolved_override.exists(), (
            f"fixture 9a: /-rooted link did not re-root under the override "
            f"(resolved to {resolved_override}, expected it to exist)"
        )
        assert resolved_override == real_target.resolve(), (
            f"fixture 9a: override resolved to {resolved_override}, "
            f"expected {real_target.resolve()}"
        )
        # Default root → same /-rooted link points outside the sandbox and is BROKEN
        # (the in-repo WORKSPACE_ROOT has no such sandbox path).
        resolved_default, _ = resolve_target(src, "/core/disciplines/real.md")
        assert not resolved_default.exists(), (
            f"fixture 9a: /-rooted link unexpectedly resolved under the default "
            f"root ({resolved_default}); the override is not load-bearing"
        )
    # (b) Precedence chain. CLI value wins outright.
    assert resolve_workspace_root("/explicit/cli/root") == Path("/explicit/cli/root"), \
        "fixture 9b: CLI tier did not win"
    # env tier: set $CLAUDE_WORKSPACE_ROOT, no CLI value → env path; unset → default.
    # Save/restore the env var so the probe is hermetic.
    _saved_env = os.environ.get("CLAUDE_WORKSPACE_ROOT")
    try:
        os.environ["CLAUDE_WORKSPACE_ROOT"] = "/env/root"
        assert resolve_workspace_root(None) == Path("/env/root"), \
            "fixture 9b: env tier not honored when no CLI value"
        # CLI still overrides the env when both are present.
        assert resolve_workspace_root("/explicit/cli/root") == Path("/explicit/cli/root"), \
            "fixture 9b: CLI did not override env when both set"
        os.environ.pop("CLAUDE_WORKSPACE_ROOT", None)
        assert resolve_workspace_root(None) == _DEFAULT_WORKSPACE_ROOT, \
            "fixture 9b: default tier not used when CLI + env both absent"
    finally:
        if _saved_env is None:
            os.environ.pop("CLAUDE_WORKSPACE_ROOT", None)
        else:
            os.environ["CLAUDE_WORKSPACE_ROOT"] = _saved_env

    print("self-test OK (9 fixtures passed)")
    return 0


MODE_HELP_EPILOG = """\
Two modes (mode discrimination via flag presence):

  broken-refs mode (default — when --from-path/--to-path NOT supplied):
    Scans --target-paths for broken cross-references.
    Output: TSV/JSON/GitHub-Actions per --output-format.
    Exit codes: 0 = clean, 1 = broken refs found.

    Example:
      python3 check-doc-links.py \\
        --target-paths "core/governance/,core/standards/" \\
        --allowlist core/config/allowlists/skip-doc-link-check.txt \\
        --output-format tsv

  rewrite-map mode (when BOTH --from-path AND --to-path supplied):
    Scans --target-paths for references whose path starts with --from-path,
    emits a rewrite map showing the substituted target under --to-path.
    EMIT-ONLY — never mutates any file.
    Output: 4-col TSV (source_file, line, old_path, new_path) by default;
    JSON or markdown via --output-format (markdown intended for paste into
    per-edit plans).
    Exit codes: 0 always (unless argparse fails or flag asymmetry — exit 2).

    Example:
      python3 check-doc-links.py \\
        --target-paths "core/disciplines/" \\
        --from-path "pmo-platform/reference/explanation/" \\
        --to-path "core/disciplines/" \\
        --output-format markdown

  Self-test:
      python3 check-doc-links.py --self-test
"""


def main() -> int:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=MODE_HELP_EPILOG,
    )
    p.add_argument("--target-paths", help="Comma-separated globs/dirs/files (relative to workspace root)")
    p.add_argument("--allowlist", help="Path to allowlist file (one pattern per line; '#' comments)")
    p.add_argument(
        "--output-format",
        choices=["tsv", "json", "github", "markdown"],
        default="tsv",
        help="Output format. 'markdown' applies to rewrite-map mode only (renders as markdown table); broken-refs mode 'markdown' falls back to TSV.",
    )
    p.add_argument("--exclude-code-blocks", action="store_true", default=True, help="(default on) skip refs inside fenced code blocks")
    p.add_argument(
        "--require-targets",
        action="store_true",
        help="(broken-refs mode) treat a --target-paths glob entry that resolves to ZERO files as a path-resolution failure: emit a finding to stderr and exit 3. Opt-in — callers that do not pass it keep the prior exit-0-on-empty-scan behavior. Has no effect in rewrite-map mode (EMIT-ONLY).",
    )
    p.add_argument("--self-test", action="store_true", help="Run internal smoke test (9 fixtures) and exit")
    p.add_argument(
        "--workspace-root",
        help="Root to resolve workspace-rooted (/-prefixed and prefix-table) links and "
             "globs against (deployed-tree validation, #760). Precedence: this flag > "
             "$CLAUDE_WORKSPACE_ROOT > the in-repo default (parents[3]). Default preserves "
             "the prior in-repo behavior.",
    )
    # ─── Rewrite-map mode flags (per Stage 5 spec Surface 2.1) ──────
    p.add_argument(
        "--from-path",
        help="Source path prefix to scan for (rewrite-map mode); requires --to-path. EMIT-ONLY semantics — tool never mutates files.",
    )
    p.add_argument(
        "--to-path",
        help="Target path prefix to substitute for --from-path (rewrite-map mode); requires --from-path.",
    )
    args = p.parse_args()

    if args.self_test:
        return run_self_test()

    # Resolve the workspace root for THIS invocation (#760): --workspace-root CLI
    # flag > $CLAUDE_WORKSPACE_ROOT > in-repo parents[3] default. Threaded as an
    # argument (not a module-global mutation) so the resolver functions stay pure
    # and --self-test remains hermetic against the module default. Resolved AFTER
    # the self-test early-return above so self-test keeps the module default.
    workspace_root = resolve_workspace_root(args.workspace_root)

    # Mode discrimination: both flags → rewrite-map; neither → broken-refs;
    # exactly one → argparse asymmetry error (exit 2).
    rewrite_mode = bool(args.from_path) or bool(args.to_path)
    if rewrite_mode and not (args.from_path and args.to_path):
        print(
            "error: --from-path and --to-path must be provided together (rewrite-map mode)",
            file=sys.stderr,
        )
        return 2

    if not args.target_paths:
        print("error: --target-paths is required (or use --self-test)", file=sys.stderr)
        return 2

    globs = [g.strip() for g in args.target_paths.split(",") if g.strip()]
    files = expand_globs(globs, workspace_root)
    allowlist = load_allowlist(Path(args.allowlist)) if args.allowlist else []

    # ─── Path-resolution-failure guard (broken-refs mode, opt-in) ──────────
    # Clause 2 of the fail-loud contract: a declared --target-paths glob that
    # resolves to zero files is unverifiable, not clean. Without --require-targets
    # the prior behavior is preserved (zero-yield globs are silently skipped), so
    # EMIT-ONLY callers and ad-hoc operator scans are unaffected. rewrite-map mode
    # returns above before reaching here, so this never fires in that mode.
    if args.require_targets and not rewrite_mode:
        unresolved = find_unresolved_globs(globs, workspace_root)
        if unresolved:
            print(
                "error: --target-paths entr%s resolved to zero files (path-resolution "
                "failure — target surface missing/relocated, not clean): %s"
                % ("ies" if len(unresolved) > 1 else "y", ", ".join(unresolved)),
                file=sys.stderr,
            )
            return 3

    if rewrite_mode:
        # ─── Rewrite-map mode (EMIT-ONLY; exit 0 regardless of entry count) ─
        entries: list[dict] = []
        for f in files:
            entries.extend(
                scan_file_for_rewrite_map(
                    f, args.from_path, args.to_path, allowlist, workspace_root
                )
            )
        if args.output_format == "json":
            out = emit_rewrite_map_json(entries)
        elif args.output_format == "markdown":
            out = emit_rewrite_map_markdown(entries)
        else:
            out = emit_rewrite_map_tsv(entries)
        print(out)
        return 0

    # ─── Broken-refs mode (default) ────────────────────────────────────────
    findings: list[dict] = []
    for f in files:
        findings.extend(scan_file(f, allowlist, workspace_root))

    if args.output_format == "tsv" or args.output_format == "markdown":
        # broken-refs mode does not support markdown; fall back to TSV
        out = emit_tsv(findings)
    elif args.output_format == "json":
        out = emit_json(findings)
    else:
        out = emit_github(findings)
    print(out)

    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())

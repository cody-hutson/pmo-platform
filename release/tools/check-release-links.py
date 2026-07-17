#!/usr/bin/env python3
"""
Intra-repo link checker for the markdown corpus.

Walks every markdown file under one or more root directories, parses markdown
links of the form `[text](target)` (and `![alt](target)` image links), and
reports any link target that:

- Resolves to a file that does not exist on disk
- Escapes the repo root (`../` past the top)
- (when --check-anchors) carries a `#fragment` that names no heading in the
  target file, where the fragment is resolved by a faithful github-slugger port

Path resolution (canonical rule, ADR-085 — identical to check-doc-links.py, see
core/standards/doc-link-maintenance-protocol.md § Path resolution): a link
resolves relative to the source file's directory; a leading `/` denotes the
workspace (repo) root; there is NO bare module-prefix fallback (a bare `core/…`
from a non-root file is an ordinary relative path, so it is broken).

Skips (treated as intentional non-links):

- External URLs (`http://`, `https://`, `mailto:`, `tel:`)
- Pure anchors (`#section`)  [resolved in-file only when --check-anchors]
- Template placeholders (`{REPO}`, `<OPERATOR_INSTANCE_*>`, `$VAR`, `~/...`)
- All-caps bareword placeholders (`URL`, `PATH`, `...`)
- Version-string placeholders (`vX.Y`, `v2.18_RELEASE_PLAN.md` worked-example refs)

Backward-compatibility contract:
  Invoked with NO arguments, this script is byte-for-byte equivalent in behavior
  to the original release-only checker: it walks `release/` exactly, checks file
  existence only (anchors and image targets are NOT checked), and exits 0/1 on
  link resolution. All new behavior is opt-in via flags that default OFF.

Exit codes:
  0 — all checked links resolve
  1 — at least one broken link (or, when --check-anchors is hard-failing, a
      missing anchor) found

Usage:
  python3 release/tools/check-release-links.py
  python3 release/tools/check-release-links.py --roots core release docs .github --top-level-md --check-anchors --images
"""
from __future__ import annotations
import argparse
import collections
import re
import sys
from pathlib import Path
from urllib.parse import unquote

REPO_ROOT = Path(__file__).resolve().parents[2]

# Captures both [text](target) and ![alt](target) — the leading `!` (if any) is
# not part of the match, so image links and ordinary links are both seen here.
# Whether an image target is *checked* is governed by --images.
LINK_RE = re.compile(r'(!?)\[[^\]]*\]\(([^)]+)\)')

# Note: a leading `/` is deliberately NOT skipped — per the canonical rule
# (ADR-085; core/standards/doc-link-maintenance-protocol.md § Path resolution) it
# denotes the workspace (repo) root and is resolved in check_file, matching
# check-doc-links.py. Only genuinely off-repo / non-path schemes are skipped here.
SKIP_PREFIXES = ("http://", "https://", "mailto:", "tel:", "#")

PLACEHOLDER_TARGETS = {
    "URL", "PATH", "FILE", "TARGET", "...", "path", "URI", "<URL>",
}


def is_skippable(target: str) -> bool:
    if any(target.startswith(p) for p in SKIP_PREFIXES):
        return True
    if "{" in target or "}" in target:
        return True
    if "<" in target or ">" in target:
        return True
    if target.startswith("$") or target.startswith("~"):
        return True
    if target in PLACEHOLDER_TARGETS:
        return True
    if re.search(r'v[A-Z]\.[A-Z]', target):
        return True
    if re.search(r'v\d+\.\d+[a-z]?_(?:RELEASE_PLAN|RELEASE_NOTES)\.md', target):
        return True
    return False


# --- github-slugger port (load-bearing; verified faithful across the corpus) ---
# Reproduces GitHub's heading-anchor slug algorithm: lowercase, strip everything
# that is not a Unicode word char / space / hyphen (so `§`, em-dash, emoji,
# periods, parens are dropped), then spaces -> hyphens. A per-file collision
# counter appends `-1`, `-2`, ... to repeated base slugs, matching GitHub's
# duplicate-heading suffixing. Do NOT replace this with a hand-rolled 3-rule
# regex — the Unicode-aware strip + collision counter is what makes it faithful.
HEADING_RE = re.compile(r'^(#{1,6})[ \t]+(.*?)[ \t]*#*[ \t]*$')
# Kramdown explicit-anchor form: `## Heading {#explicit-id}` — GitHub itself does
# not honor `{#id}` in its rendered markdown, so the port mirrors that and such
# headings fall into the warn-mode-absorbed residual class.
INLINE_CODE_RE = re.compile(r'`([^`]*)`')


def github_slug(text: str) -> str:
    s = text.strip().lower()
    s = re.sub(r'[^\w \-]', '', s, flags=re.UNICODE)
    return s.replace(' ', '-')


def heading_text(raw_heading: str) -> str:
    """Strip markdown inline formatting that GitHub removes before slugging.

    GitHub slugs the *rendered* heading text. The constructs that materially
    affect the slug for this corpus are inline-code spans (backticks are dropped
    but their contents are kept) and link syntax `[text](url)` (the visible
    `text` is kept). Emphasis markers (`*`/`_`) are word-adjacent punctuation that
    the `[^\\w \\-]` strip already removes, so they need no pre-pass.
    """
    t = INLINE_CODE_RE.sub(r'\1', raw_heading)
    # [visible](url) -> visible   ;   ![alt](url) -> alt
    t = re.sub(r'!?\[([^\]]*)\]\([^)]*\)', r'\1', t)
    return t


def slug_set(md_text: str) -> set[str]:
    """All heading anchors GitHub would generate for a file, with collision
    suffixing applied in document order."""
    seen: collections.Counter[str] = collections.Counter()
    slugs: set[str] = set()
    in_fence = False
    for line in md_text.splitlines():
        if re.match(r'^[ \t]*```', line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = HEADING_RE.match(line)
        if not m:
            continue
        base = github_slug(heading_text(m.group(2)))
        if not base:
            continue
        n = seen[base]
        slug = base if n == 0 else f"{base}-{n}"
        seen[base] += 1
        slugs.add(slug)
    return slugs


def _line_of(text: str, offset: int) -> int:
    """1-based line number of a character offset in text."""
    return text.count("\n", 0, offset) + 1


def check_file(md: Path, *, check_anchors: bool, images: bool,
               anchor_warns: list[str],
               added: set[int] | None = None) -> list[str]:
    """Return hard-fail findings for one file. Anchor misses are appended to
    anchor_warns (warn-mode) rather than returned as hard fails.

    When `added` is provided (a set of 1-based line numbers added since a diff
    base), a finding is reported ONLY if its source link sits on an added line.
    This is the net-new-delta posture that keeps pre-existing links in a file
    that a PR touches for unrelated reasons from being re-flagged (the same
    added-lines discipline the reference-durability gate uses). With
    `added=None`, every link in the file is considered.
    """
    broken: list[str] = []
    try:
        text = md.read_text()
    except Exception:
        return broken
    # Cache target-file slug sets so a file linked many times is read once.
    slug_cache: dict[Path, set[str]] = {}
    for m in LINK_RE.finditer(text):
        if added is not None and _line_of(text, m.start()) not in added:
            continue   # link is on a pre-existing line — not this PR's concern
        is_image = m.group(1) == "!"
        target = m.group(2).strip()
        if is_image and not images:
            continue
        if is_skippable(target):
            continue
        target_path, _, frag = target.partition("#")
        target_path = unquote(target_path).strip()
        if not target_path:
            # Pure in-file anchor (`#frag`) — only meaningful with --check-anchors,
            # resolved against THIS file's own headings.
            if check_anchors and frag:
                this_slugs = slug_cache.get(md)
                if this_slugs is None:
                    this_slugs = slug_set(text)
                    slug_cache[md] = this_slugs
                if unquote(frag) not in this_slugs:
                    anchor_warns.append(
                        f"  missing-anchor (in-file): {target} "
                        f"-> #{unquote(frag)} not a heading in {md.name}")
            continue
        if target_path.startswith("/"):
            # Canonical rule clause 2 (ADR-085): a leading `/` denotes the
            # workspace (repo) root, matching GitHub's rendered-blob behavior and
            # check-doc-links.py. Anchor explicitly on REPO_ROOT — joining an
            # absolute path via `md.parent / target_path` would reset to the
            # filesystem root and then read as "escapes repo root".
            resolved = (REPO_ROOT / target_path.lstrip("/")).resolve()
        else:
            resolved = (md.parent / target_path).resolve()
        try:
            resolved.relative_to(REPO_ROOT)
        except ValueError:
            broken.append(f"  escapes repo root: {target}")
            continue
        if not resolved.exists():
            broken.append(f"  broken: {target} -> {resolved.relative_to(REPO_ROOT)}")
            continue
        if check_anchors and frag and resolved.is_file():
            target_slugs = slug_cache.get(resolved)
            if target_slugs is None:
                try:
                    target_slugs = slug_set(resolved.read_text())
                except Exception:
                    target_slugs = set()
                slug_cache[resolved] = target_slugs
            if unquote(frag) not in target_slugs:
                anchor_warns.append(
                    f"  missing-anchor: {target} -> #{unquote(frag)} "
                    f"not a heading in {resolved.relative_to(REPO_ROOT)}")
    return broken


def added_lines_for(md: Path, diff_base: str) -> set[int]:
    """1-based line numbers in `md` (head/working version) that are net-new
    since `diff_base`, computed from the unified diff's hunk headers. An empty
    set means no added lines (the file is unchanged or only had deletions)."""
    import subprocess
    rel = md.resolve()
    try:
        rel = rel.relative_to(REPO_ROOT)
    except ValueError:
        return set()
    try:
        out = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "diff", "--unified=0",
             f"{diff_base}...HEAD", "--", str(rel)],
            capture_output=True, text=True, check=False).stdout
    except Exception:
        return set()
    added: set[int] = set()
    new_ln = 0
    for line in out.splitlines():
        if line.startswith("@@"):
            # @@ -a,b +c,d @@  -> new-file hunk starts at c
            try:
                plus = line.split("+", 1)[1]
                start = plus.split(maxsplit=1)[0]
                c = start.split(",")[0]
                new_ln = int(c)
            except (IndexError, ValueError):
                new_ln = 0
        elif line.startswith("+") and not line.startswith("+++"):
            if new_ln:
                added.add(new_ln)
                new_ln += 1
        elif line.startswith("-") and not line.startswith("---"):
            pass  # deletions do not advance the new-file counter
    return added


def iter_markdown(roots: list[str], top_level_md: bool,
                  only: set[Path] | None = None):
    """Yield markdown files under each root dir, plus top-level *.md when asked.

    When `only` is provided (the resolved paths of a changed-files set), the
    walk is intersected with it: a file is yielded only if it both falls under
    an in-scope root (or is a top-level *.md when --top-level-md) AND appears in
    `only`. This is how the PR-time dead-file-ref gate scans the delta only —
    pre-existing corpus rot in unchanged files is never re-flagged (the
    drainage-is-out-of-release principle). With `only=None` (the bare
    invocation) the full root walk is preserved unchanged.
    """
    seen: set[Path] = set()
    for root in roots:
        root_dir = (REPO_ROOT / root).resolve()
        if not root_dir.exists():
            continue
        for md in sorted(root_dir.rglob("*.md")):
            if md in seen:
                continue
            if only is not None and md not in only:
                continue
            seen.add(md)
            yield md
    if top_level_md:
        for md in sorted(REPO_ROOT.glob("*.md")):
            if md in seen:
                continue
            if only is not None and md not in only:
                continue
            seen.add(md)
            yield md


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Intra-repo markdown link (and optional anchor/image) checker.")
    p.add_argument(
        "--roots", nargs="+", default=["release"],
        help="Root directories to walk (default: release). Each is walked "
             "recursively for *.md files.")
    p.add_argument(
        "--top-level-md", action="store_true",
        help="Also check top-level *.md files at the repo root (e.g. README.md).")
    p.add_argument(
        "--check-anchors", action="store_true",
        help="Also resolve #fragment anchors against target-file headings using "
             "the github-slugger port. Findings are warn-mode (do NOT fail the "
             "run) during calibration. Default OFF.")
    p.add_argument(
        "--images", action="store_true",
        help="Also check ![alt](path) image targets for existence. Default OFF "
             "(image targets are parsed but not checked).")
    p.add_argument(
        "--anchors-hard-fail", action="store_true",
        help="Promote missing-anchor findings from warn-mode to hard failures "
             "(exit 1). Default OFF; calibration ships anchors in warn-mode.")
    p.add_argument(
        "--files", nargs="*", default=None,
        help="Restrict checking to this explicit set of files (repo-relative or "
             "absolute paths), intersected with --roots/--top-level-md scope. "
             "Used by the PR-time dead-file-ref gate to scan only the changed "
             "delta so pre-existing rot in unchanged files is not re-flagged. "
             "Omit (default) to walk the full roots — the bare-invocation "
             "contract.")
    p.add_argument(
        "--diff-base", default=None,
        help="A git ref/SHA. When set, only links on lines ADDED since this base "
             "(base...HEAD) are checked, so pre-existing links in a file the PR "
             "touched for unrelated reasons are not re-flagged — the same net-new "
             "added-lines posture the reference-durability gate uses. Omit "
             "(default) to consider every link in the in-scope files.")
    return p.parse_args(argv)


def resolve_only(files: list[str] | None) -> set[Path] | None:
    """Resolve a changed-files list to absolute paths under the repo. Files that
    are not *.md or escape the repo are dropped (the gate only checks markdown).
    Returns None when no --files was supplied (full-walk mode)."""
    if files is None:
        return None
    out: set[Path] = set()
    for raw in files:
        raw = raw.strip()
        if not raw or not raw.endswith(".md"):
            continue
        p = Path(raw)
        resolved = p.resolve() if p.is_absolute() else (REPO_ROOT / raw).resolve()
        try:
            resolved.relative_to(REPO_ROOT)
        except ValueError:
            continue
        out.add(resolved)
    return out


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    only = resolve_only(args.files)
    total_broken = 0
    files_with_broken = 0
    anchor_warns: list[str] = []
    for md in iter_markdown(args.roots, args.top_level_md, only=only):
        added = added_lines_for(md, args.diff_base) if args.diff_base else None
        if added is not None and not added:
            continue   # no net-new lines in this file — nothing to check
        broken = check_file(
            md, check_anchors=args.check_anchors, images=args.images,
            anchor_warns=anchor_warns, added=added)
        if broken:
            files_with_broken += 1
            total_broken += len(broken)
            print(f"\n{md.relative_to(REPO_ROOT)}:")
            for b in broken:
                print(b)
    print(f"\n=== {total_broken} broken links across {files_with_broken} files ===")
    if args.check_anchors and anchor_warns:
        label = "MISSING ANCHORS (hard-fail)" if args.anchors_hard_fail \
            else "missing anchors (warn-mode — not failing the run)"
        print(f"\n=== {len(anchor_warns)} {label} ===")
        for w in anchor_warns:
            print(w)
    fail = total_broken > 0 or (args.anchors_hard_fail and bool(anchor_warns))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())

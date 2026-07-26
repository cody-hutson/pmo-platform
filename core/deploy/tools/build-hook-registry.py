#!/usr/bin/env python3
"""Hook-registry index generator (per ADR-030).

Assembles the canonical-path index `core/rules/bypass-mode-readiness.md` from the
per-hook drop-in source fragments under `core/rules/bypass-mode-readiness/`:

    _header.md        cross-cutting: title-less Purpose preamble (authored)
    <hook>.md         one per hook — the block-* bypass-mode security hooks PLUS
                      any non-block workflow-class posture hook (e.g.
                      verify-session-config.md); each carries a field table (Hook /
                      Matcher / Scope / Mode), a Rule Registry sub-table, and any
                      per-hook path-resolution / posture detail
    _cross-cutting.md cross-cutting: Absolute-Path anchor, CLAUDE_HOOK_BYPASS,
                      Allowlist Maintenance, Warn-Mode, Recovery, Known
                      Limitations, Shakedown -> Enforce, Related (authored)

Output structure (deterministic):

    # Bypass-Mode Readiness - Hook Layer Reference   (title, emitted here)
    <_header.md body>
    ## The Hooks                                     (AUTO-GENERATED table — one
                                                      row per per-hook fragment, in
                                                      lexicographic hook order)
    <each per-hook fragment body, lexicographic order>
    <_cross-cutting.md body>

The `## The Hooks` table is the part that drifts in a hand-maintained registry;
generating it one-row-per-source-file makes undercount structurally impossible
(the live 5/7/9 drift that motivated ADR-030). Fragment files name-prefixed with
`_` are cross-cutting and are NEVER treated as per-hook sources.

Posture: stdlib-only (`/usr/bin/python3` 3.9+), matching the
`core/deploy/tools/check-doc-links.py` convention. Deterministic — same sources
always produce byte-identical output (lexicographic ordering; no timestamps).

Modes:
  (default)    write the assembled index to the canonical path (or --output).
  --check      assemble in memory and diff against the committed index; exit 1 if
               they differ (the regenerate-and-diff freshness contract). Emits the
               unified diff to stdout. Exit 0 if in sync.
  --stdout     print the assembled index to stdout; do not write. Exit 0.
  --self-test  run internal fixtures and exit.

Exit codes:
  0  success / in-sync (--check) / self-test passed
  1  --check found drift (committed index stale vs sources)
  2  argparse / usage error
  3  source-resolution failure (a required fragment dir/file missing) — fail loud,
     never emit a partial index that would read as a clean smaller file.
"""
from __future__ import annotations

import argparse
import difflib
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]

# Canonical surfaces (relative to workspace root).
SOURCE_DIR_REL = "core/rules/bypass-mode-readiness"
INDEX_REL = "core/rules/bypass-mode-readiness.md"

TITLE = "# Bypass-Mode Readiness — Hook Layer Reference"
DURABILITY_MARKER = "<!-- reference-durability: allow-link -->"

HEADER_FRAGMENT = "_header.md"
CROSS_CUTTING_FRAGMENT = "_cross-cutting.md"

# A leading reference-durability marker line on each fragment is stripped during
# assembly (the generated index carries exactly one, emitted at the top).
_MARKER_LINE_RE = re.compile(r"^<!--\s*reference-durability:\s*allow-link\s*-->\s*$")
# Depth-relativization: fragments live one directory DEEPER than the generated
# index (`core/rules/bypass-mode-readiness/<frag>.md` vs `core/rules/
# bypass-mode-readiness.md`). A fragment's outbound relative link is authored
# valid at fragment depth (e.g. `](../../standards/x.md)`, `](../skill-deployment.md)`,
# `](../bypass-mode-readiness.md#a)`); in the index — one level up — each must lose
# exactly one leading `../` (-> `](../standards/x.md)`, `](skill-deployment.md)`,
# `](bypass-mode-readiness.md#a)`, the last being an index self-anchor). Same-dir
# links (`](foo.md)`), pure anchors (`](#a)`), absolute paths (`](/x)`), and external
# URLs (`](http...)`) have no leading `../` and are therefore left untouched. The
# match is anchored on the `](` link/image-target opener so only link targets are
# rewritten, never `../` appearing in prose.
_FRAGMENT_LINK_UP_RE = re.compile(r"(\]\()\.\./")
# The per-hook field table's "Scope" row, used to build the auto-generated
# summary table. Format: `| Scope | <text> |`.
_SCOPE_ROW_RE = re.compile(r"^\|\s*Scope\s*\|\s*(.+?)\s*\|\s*$")
# The per-hook H2 heading: `## \`block-foo.sh\` (RULE-RANGE)` — capture the
# display text so the summary-table row links to the in-file anchor.
_HOOK_HEADING_RE = re.compile(r"^##\s+(.+?)\s*$")


def _relativize_up_one(text: str) -> str:
    """Strip exactly one leading `../` from every markdown/image link TARGET in
    `text`, depth-correcting fragment-authored links for the index one level up.

    Only `](../…)` openers are rewritten (`](` then a single `../`); a second
    `../` in the same target is preserved (`](../../x)` -> `](../x)`). Prose `../`,
    same-dir targets, pure anchors, absolute paths, and external URLs are untouched.
    """
    return _FRAGMENT_LINK_UP_RE.sub(r"\1", text)


def _read_fragment(path: Path) -> str:
    """Read a fragment, stripping a single leading reference-durability marker
    line (and the blank line immediately following it, if present), then
    depth-relativizing its outbound links for the index one level up."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    if lines and _MARKER_LINE_RE.match(lines[0]):
        lines = lines[1:]
        if lines and lines[0].strip() == "":
            lines = lines[1:]
    return _relativize_up_one("\n".join(lines).strip("\n"))


def discover_hook_sources(source_dir: Path) -> list[Path]:
    """Return the per-hook source files (non-underscore `*.md`), lexicographically
    sorted.

    The discovery glob is `[!_]*.md` — every per-hook fragment, not just
    `block-*.md` — so a non-`block-` posture hook (e.g. the workflow-class
    `verify-session-config.md`) composes into the generated index instead of being
    silently excluded. This also makes the discovery glob AGREE with the Check-9
    mirror glob (`*.md`), permanently closing that mismatch class. Underscore-
    prefixed cross-cutting fragments (`_header.md`, `_cross-cutting.md`) are
    excluded by the `[!_]` character class; the `startswith("_")` filter is kept as
    belt-and-suspenders.
    """
    return sorted(
        p for p in source_dir.glob("[!_]*.md") if not p.name.startswith("_")
    )


def github_anchor(heading_text: str) -> str:
    """Compute the GitHub heading-slug anchor for an H2 heading's display text.

    Mirrors GitHub's slug rules closely enough for intra-file links: lowercase,
    drop characters that are not word/space/hyphen, spaces -> hyphens. Backticks,
    parentheses, and the dot in `block-foo.sh` are dropped, matching how the
    inbound links in the cross-cutting fragments are authored.
    """
    slug = heading_text.strip().lower()
    slug = slug.replace("`", "")
    # Drop everything except alphanumerics, spaces, and hyphens.
    slug = re.sub(r"[^a-z0-9 \-]", "", slug)
    slug = slug.replace(" ", "-")
    slug = re.sub(r"-{2,}", "-", slug)
    return slug.strip("-")


def parse_hook_fragment(path: Path) -> dict:
    """Extract the summary-row fields from a per-hook fragment.

    Returns {name_display, scope, anchor}. `name_display` is the H2 heading text
    (e.g. "`block-destructive.sh` (BLOCK-DESTRUCTIVE-001..023)"); `scope` is the
    Scope-row text from the field table; `anchor` is the in-file GitHub anchor for
    the heading.
    """
    text = path.read_text(encoding="utf-8")
    name_display = None
    scope = None
    for line in text.split("\n"):
        if name_display is None:
            mh = _HOOK_HEADING_RE.match(line)
            if mh:
                name_display = mh.group(1)
                continue
        ms = _SCOPE_ROW_RE.match(line)
        if ms and scope is None:
            scope = ms.group(1)
    if name_display is None:
        raise ValueError(f"{path.name}: no '## ' hook heading found")
    if scope is None:
        raise ValueError(f"{path.name}: no '| Scope | … |' row found")
    return {
        "name_display": name_display,
        "scope": scope,
        "anchor": github_anchor(name_display),
    }


def build_hook_table(hook_sources: list[Path]) -> str:
    """Build the auto-generated `## The Hooks` summary table — one row per source."""
    rows = [
        "## The Hooks",
        "",
        "<!-- AUTO-GENERATED by core/deploy/tools/build-hook-registry.py — one row "
        "per core/rules/bypass-mode-readiness/ per-hook source (non-underscore "
        "*.md). Do not hand-edit. -->",
        "",
        "| Hook | Scope |",
        "|---|---|",
    ]
    for src in hook_sources:
        meta = parse_hook_fragment(src)
        rows.append(f"| [{meta['name_display']}](#{meta['anchor']}) | {meta['scope']} |")
    return "\n".join(rows)


def assemble_index(source_dir: Path) -> str:
    """Assemble the full canonical index text from the source fragments."""
    header_path = source_dir / HEADER_FRAGMENT
    cross_path = source_dir / CROSS_CUTTING_FRAGMENT

    def _rel(p: Path) -> str:
        try:
            return str(p.relative_to(WORKSPACE_ROOT))
        except ValueError:
            return str(p)

    missing = [
        _rel(p)
        for p in (source_dir, header_path, cross_path)
        if not p.exists()
    ]
    if missing:
        raise FileNotFoundError(
            "hook-registry source(s) missing: " + ", ".join(missing)
        )
    hook_sources = discover_hook_sources(source_dir)
    if not hook_sources:
        raise FileNotFoundError(
            f"no per-hook sources (non-underscore *.md) found under "
            f"{source_dir.relative_to(WORKSPACE_ROOT)}"
        )

    blocks: list[str] = [
        DURABILITY_MARKER,
        TITLE,
        "",
        "<!-- GENERATED FILE — do not hand-edit. Source: "
        "core/rules/bypass-mode-readiness/ (per-hook block-*.md + _header.md + "
        "_cross-cutting.md). Regenerate via core/deploy/tools/build-hook-registry.py "
        "(wired into deploy.sh). Per ADR-030. -->",
        "",
        _read_fragment(header_path),
        "",
        build_hook_table(hook_sources),
    ]
    for src in hook_sources:
        blocks.append("")
        blocks.append(_read_fragment(src))
    blocks.append("")
    blocks.append(_read_fragment(cross_path))

    # Single trailing newline; collapse any 3+ blank-line runs to exactly one
    # blank line so assembly is normalization-stable.
    text = "\n".join(blocks)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.rstrip("\n") + "\n"


def run_self_test() -> int:
    """Internal fixtures: assembly determinism + table generation + marker strip."""
    import tempfile

    with tempfile.TemporaryDirectory() as td:
        sd = Path(td) / SOURCE_DIR_REL
        sd.mkdir(parents=True)
        (sd / HEADER_FRAGMENT).write_text(
            DURABILITY_MARKER + "\n\n## Purpose\n\nSeven hooks.\n"
        )
        (sd / "block-bravo.md").write_text(
            DURABILITY_MARKER + "\n\n## `block-bravo.sh` (BLOCK-BRAVO-001)\n\n"
            "| Field | Value |\n|---|---|\n| Scope | Bravo scope |\n\n"
            "### Rule registry\n\n| Rule ID | Description |\n|---|---|\n"
            "| BLOCK-BRAVO-001 | bravo |\n"
        )
        (sd / "block-alpha.md").write_text(
            DURABILITY_MARKER + "\n\n## `block-alpha.sh` (BLOCK-ALPHA-001)\n\n"
            "| Field | Value |\n|---|---|\n| Scope | Alpha scope |\n\n"
            "### Rule registry\n\n| Rule ID | Description |\n|---|---|\n"
            "| BLOCK-ALPHA-001 | alpha |\n\n"
            # Depth-strip fixtures: a two-level-up link, a sibling-dir link, an
            # index self-anchor, plus three controls that MUST stay verbatim.
            "See [std](../../standards/x.md), [sib](../skill-deployment.md), "
            "[self](../bypass-mode-readiness.md#anchor); controls "
            "[same](same-dir.md), [anc](#local), [ext](https://example.com/../y). "
            "Prose ../ stays.\n"
        )
        (sd / "_cross-cutting.md").write_text(
            DURABILITY_MARKER + "\n\n## Related\n\nrelated.\n"
        )

        out1 = assemble_index(sd)
        out2 = assemble_index(sd)
        # 1. Determinism — same sources, byte-identical output.
        assert out1 == out2, "self-test: assembly is not deterministic"

        # 2. Exactly one reference-durability marker (the emitted top one); the
        #    per-fragment markers were stripped.
        assert out1.count(DURABILITY_MARKER) == 1, (
            f"self-test: expected 1 durability marker, got {out1.count(DURABILITY_MARKER)}"
        )

        # 3. Title present exactly once, at the top (after the marker).
        assert out1.split("\n")[0] == DURABILITY_MARKER, "self-test: marker not first"
        assert out1.split("\n")[1] == TITLE, "self-test: title not second"

        # 4. Auto-generated table lists BOTH hooks, in lexicographic order
        #    (alpha before bravo), each linking to its in-file anchor. The anchor
        #    is GitHub's heading slug for the full H2 text, e.g.
        #    `## \`block-alpha.sh\` (BLOCK-ALPHA-001)` -> block-alphash-block-alpha-001.
        assert "## The Hooks" in out1, "self-test: hook table heading missing"
        idx_alpha = out1.index("block-alpha.sh")
        idx_bravo = out1.index("block-bravo.sh")
        alpha_anchor = github_anchor("`block-alpha.sh` (BLOCK-ALPHA-001)")
        bravo_anchor = github_anchor("`block-bravo.sh` (BLOCK-BRAVO-001)")
        assert alpha_anchor == "block-alphash-block-alpha-001", (
            f"self-test: alpha anchor slug wrong: {alpha_anchor!r}"
        )
        table_start = out1.index("## The Hooks")
        # Within the table region, alpha's row must precede bravo's row.
        table_region = out1[table_start:]
        assert table_region.index(f"(#{alpha_anchor})") < table_region.index(f"(#{bravo_anchor})"), (
            "self-test: hook table not in lexicographic order"
        )
        assert f"(#{alpha_anchor})" in out1, "self-test: alpha anchor link malformed"

        # 5. Per-hook bodies concatenated in lexicographic order (alpha < bravo).
        assert idx_alpha < idx_bravo, "self-test: per-hook bodies out of order"
        assert "BLOCK-ALPHA-001" in out1 and "BLOCK-BRAVO-001" in out1, (
            "self-test: rule IDs missing from assembled bodies"
        )

        # 6. Cross-cutting Related section is last.
        assert out1.rstrip().endswith("related."), "self-test: cross-cutting not last"

        # 8. Depth-strip: each fragment-authored `](../…)` link loses EXACTLY one
        #    leading `../` in the assembled index (one level up), while same-dir
        #    links, pure anchors, and external URLs stay verbatim.
        assert "[std](../standards/x.md)" in out1, "self-test: two-level link not stripped to one"
        assert "[sib](skill-deployment.md)" in out1, "self-test: sibling-dir link not stripped to bare"
        assert "[self](bypass-mode-readiness.md#anchor)" in out1, "self-test: index self-anchor not stripped"
        assert "../../standards/x.md" not in out1, "self-test: a `../../` survived the strip"
        assert "[same](same-dir.md)" in out1, "self-test: same-dir link was altered"
        assert "[anc](#local)" in out1, "self-test: pure anchor was altered"
        assert "[ext](https://example.com/../y)" in out1, "self-test: external URL `../` was altered"
        assert "Prose ../ stays." in out1, "self-test: prose `../` was altered"

        # 7. Missing required fragment → FileNotFoundError (fail-loud, not partial).
        (sd / HEADER_FRAGMENT).unlink()
        try:
            assemble_index(sd)
        except FileNotFoundError:
            pass
        else:
            raise AssertionError("self-test: missing header did not raise")

    print("self-test OK (8 fixtures passed)")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument(
        "--check",
        action="store_true",
        help="assemble in memory and diff against the committed index; exit 1 if "
        "they differ (regenerate-and-diff freshness gate). No write.",
    )
    p.add_argument(
        "--stdout",
        action="store_true",
        help="print the assembled index to stdout; do not write.",
    )
    p.add_argument(
        "--output",
        help="write the assembled index here instead of the canonical path "
        "(default: %s)" % INDEX_REL,
    )
    p.add_argument(
        "--source-dir",
        help="override the per-hook source dir (default: %s)" % SOURCE_DIR_REL,
    )
    p.add_argument("--self-test", action="store_true", help="run internal smoke test and exit")
    args = p.parse_args()

    if args.self_test:
        return run_self_test()

    source_dir = (
        Path(args.source_dir)
        if args.source_dir and Path(args.source_dir).is_absolute()
        else WORKSPACE_ROOT / (args.source_dir or SOURCE_DIR_REL)
    )
    index_path = (
        Path(args.output)
        if args.output and Path(args.output).is_absolute()
        else WORKSPACE_ROOT / (args.output or INDEX_REL)
    )

    try:
        assembled = assemble_index(source_dir)
    except FileNotFoundError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 3

    if args.stdout:
        sys.stdout.write(assembled)
        return 0

    if args.check:
        committed = index_path.read_text(encoding="utf-8") if index_path.exists() else ""
        if committed == assembled:
            print(f"OK: {INDEX_REL} is in sync with its sources")
            return 0
        diff = difflib.unified_diff(
            committed.splitlines(keepends=True),
            assembled.splitlines(keepends=True),
            fromfile=f"{INDEX_REL} (committed)",
            tofile=f"{INDEX_REL} (regenerated)",
        )
        sys.stdout.writelines(diff)
        print(
            f"\nDRIFT: {INDEX_REL} is stale vs its sources — regenerate via "
            f"`python3 core/deploy/tools/build-hook-registry.py` and commit.",
            file=sys.stderr,
        )
        return 1

    # Default: write the index.
    index_path.write_text(assembled, encoding="utf-8")
    print(f"wrote {index_path.relative_to(WORKSPACE_ROOT)} ({len(assembled)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

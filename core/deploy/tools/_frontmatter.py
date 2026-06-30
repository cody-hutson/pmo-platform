#!/usr/bin/env python3
"""_frontmatter.py — the single shared YAML-frontmatter block reader.

This is the ONE place the deploy-tool family parses a doc's frontmatter block,
so two checks that both reason about "does this doc carry frontmatter, and what
keys does it carry" can never drift apart. It is consumed by:

  * check-version-anchors.py (Check 18b/18d) — via read_anchor(), which preserves
    that tool's exact 4-status contract; and
  * check-doc-frontmatter.py (Check 49) — via read_frontmatter(), the generalized
    all-keys reader.

The parse idiom is the one check-version-anchors.py shipped (the v11.12 reader):
a doc has frontmatter IFF line[0].strip() == "---"; the block runs to the next
line whose strip() == "---"; each "key: value" line inside is split on the FIRST
colon and the value is stripped of one matching pair of surrounding quotes
("…" or '…'). Keeping that idiom byte-identical here is the F1 consistency
guarantee: a doc Check 18b treats as "has frontmatter" is the same doc Check 49
treats as "has frontmatter," because both ask THIS module.

Stdlib-only; no argparse / CLI — this is a library, imported by the checks.
A small `--self-test` guard is provided for direct sanity invocation.
"""
from __future__ import annotations

import sys
from pathlib import Path


def _strip_quotes(val: str) -> str:
    """Strip exactly one matching pair of surrounding quotes, mirroring the
    check-version-anchors.py v11.12 idiom (double OR single)."""
    if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
        val = val[1:-1]
    return val.strip()


def read_frontmatter(doc_path: Path) -> tuple[dict[str, str], str]:
    """Read a doc's YAML frontmatter block. Return (keys, status).

    status ∈ {"no-file", "no-frontmatter", "ok"}.
      - "no-file"          → the path does not exist / is unreadable.
      - "no-frontmatter"   → the file's first line is not a "---" fence.
      - "ok"               → a frontmatter block was found (possibly empty).

    `keys` maps the FIRST occurrence of each top-level "key: value" line inside
    the block to its quote-stripped value (only when status == "ok"; {} else).
    Only flush-left (column-0) "key:" lines are treated as top-level keys, so a
    nested/indented list item does not masquerade as a top-level field. A key
    line with an empty value yields "" — the caller decides whether empty counts
    as present (Check 49 treats present-but-empty as a missing-field finding).
    """
    if not doc_path.exists():
        return {}, "no-file"
    try:
        text = doc_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return {}, "no-file"
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, "no-frontmatter"
    keys: dict[str, str] = {}
    for line in lines[1:]:
        if line.strip() == "---":
            break
        # Top-level key lines are flush-left "key: value" / "key:". An indented
        # line (a YAML list/flow continuation) is NOT a top-level key.
        if line[:1].isspace():
            continue
        if ":" not in line:
            continue
        raw_key, raw_val = line.split(":", 1)
        key = raw_key.strip()
        if not key or key != raw_key.rstrip():
            # A leading-space key was already filtered; an internal space means
            # this is prose, not a YAML key — skip it.
            if " " in key:
                continue
        if key and key not in keys:
            keys[key] = _strip_quotes(raw_val.strip())
    return keys, "ok"


def read_anchor(doc_path: Path) -> tuple[str | None, str]:
    """Backward-compatible single-key reader for the framework_version_anchor key.

    Preserves check-version-anchors.py's EXACT 4-status contract:
    status ∈ {"no-file", "no-frontmatter", "frontmatter-no-key", "ok"}.
    anchor_value is the stripped framework_version_anchor value when status=="ok".

    Implemented on top of read_frontmatter so the parse is shared (F1): the two
    tools cannot disagree about what a frontmatter block is or how a value is
    quote-stripped.
    """
    keys, status = read_frontmatter(doc_path)
    if status in ("no-file", "no-frontmatter"):
        return None, status
    if "framework_version_anchor" in keys:
        return keys["framework_version_anchor"], "ok"
    return None, "frontmatter-no-key"


def _self_test() -> int:
    import tempfile

    with tempfile.TemporaryDirectory() as td:
        base = Path(td)

        # (1) clean doc with several keys + a quoted value + a nested list line.
        d1 = base / "clean.md"
        d1.write_text(
            '---\ntitle: T\npurpose: why\ntype: standard\nstatus: ACTIVE\n'
            'reversibility: "CHEAP / Confidence HIGH"\n'
            'consumers: [a.md, b.md]\n'
            'composes_with:\n  - x.md\n  - y.md\n---\n# Body\n',
            encoding="utf-8",
        )
        keys, status = read_frontmatter(d1)
        assert status == "ok", status
        assert keys["title"] == "T"
        assert keys["reversibility"] == "CHEAP / Confidence HIGH", keys["reversibility"]
        assert keys["consumers"] == "[a.md, b.md]"
        assert keys["composes_with"] == "", "empty-value key must read as ''"
        assert "- x.md" not in keys, "nested list item must NOT become a top-level key"

        # (2) no-frontmatter doc (HTML comment first line — the bypass-mode case).
        d2 = base / "nofm.md"
        d2.write_text("<!-- reference-durability: allow-link -->\n# Heading\n", encoding="utf-8")
        keys2, status2 = read_frontmatter(d2)
        assert status2 == "no-frontmatter" and keys2 == {}, (status2, keys2)

        # (3) missing file.
        keys3, status3 = read_frontmatter(base / "does-not-exist.md")
        assert status3 == "no-file" and keys3 == {}, (status3, keys3)

        # (4) read_anchor contract parity.
        d4 = base / "anchored.md"
        d4.write_text('---\ntitle: D\nframework_version_anchor: "v8.0"\n---\n', encoding="utf-8")
        anchor, astat = read_anchor(d4)
        assert astat == "ok" and anchor == "v8.0", (astat, anchor)
        anchor2, astat2 = read_anchor(d1)  # has frontmatter, no anchor key
        assert astat2 == "frontmatter-no-key" and anchor2 is None, (astat2, anchor2)
        anchor3, astat3 = read_anchor(d2)  # no frontmatter
        assert astat3 == "no-frontmatter", astat3

    print("_frontmatter self-test OK")
    return 0


if __name__ == "__main__":
    sys.exit(_self_test())

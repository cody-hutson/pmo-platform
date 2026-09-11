#!/usr/bin/env python3
"""_frontmatter.py — the single shared YAML-frontmatter block reader AND the
single shared corpus-traversal predicate for the deploy-tool family.

This is the ONE place the deploy-tool family parses a doc's frontmatter block,
so two checks that both reason about "does this doc carry frontmatter, and what
keys does it carry" can never drift apart. Its six live consumers, all under
core/deploy/tools/:

  * backfill-relationship-edges.py — via read_frontmatter();
  * build-doc-index.py — via read_frontmatter();
  * check-doc-frontmatter.py (Check 50) — via read_frontmatter(), the generalized
    all-keys reader;
  * check-version-anchors.py (Check 18b/18d) — via read_anchor(), which preserves
    that tool's exact 4-status contract;
  * compose-portfolio.py — via read_frontmatter(); and
  * stamp-node-frontmatter.py — via read_frontmatter().

The last two of those checks load this module dynamically, through
importlib.util.spec_from_file_location rather than a static import, which is why
a grep for `import _frontmatter` UNDER-reports the consumer set. Count the
dynamic loads too before asserting a blast radius.

The parse idiom is the one check-version-anchors.py shipped (the v11.12 reader):
a doc has frontmatter IFF line[0].strip() == "---"; the block runs to the next
line whose strip() == "---"; each "key: value" line inside is split on the FIRST
colon and the value is stripped of one matching pair of surrounding quotes
("…" or '…'). Keeping that idiom byte-identical here is the F1 consistency
guarantee: a doc Check 18b treats as "has frontmatter" is the same doc Check 50
treats as "has frontmatter," because both ask THIS module.

F1 COVERS TRAVERSAL TOO. The same guarantee spans a second axis: not only "what
keys does this doc carry" but "is this doc in the corpus at all". is_corpus_path()
below is the ONE traversal predicate the THREE deploy-tool corpus walkers share,
so a file is in the corpus for all of them or out of it for all of them — the
same terms, one axis over. Those three previously carried that rule privately
(two byte-identical copies and one omission) and disagreed on dot-leading
segments; they now ask THIS module, exactly as they already ask it what a
frontmatter block is. That is why this module is BOTH a reader and a traversal
predicate, and why its name understates it.

The population is stated as THREE deliberately, not left open. A bare "the
deploy-tool corpus walkers" quantifies over a set nothing bounds, and the set is
larger than the three: check-work-hierarchy.py also walks *.md under this tree
and prunes dot-leading DIRECTORIES only, without asking this module. It is a
governance-prose lint surface rather than a node-corpus walker, so it is out of
this predicate's population by design — but that is a fact to state, not one to
leave a universal silently asserting the opposite of.

FROZEN SEMANTICS
----------------
The clauses below state what this module DOES, not what a YAML parser would do.
They are frozen deliberately: every one of them is a property six consumers
already depend on, so changing one changes all six resolved-value sets at once
and silently. Each clause is anchored by a named assertion in _self_test — F-1
in cases (1), (2) and (5), F-2 / F-3 / F-4 in case (5), F-5 in case (1) — so a
future well-meaning tightening fails a test rather than shipping. The case
numbers are stated because a reader has to be able to CHECK the claim in
seconds; an unlocated "it is tested somewhere" is the shape of assurance this
block exists to replace.

F-1  Frontmatter exists IFF the file's FIRST line, stripped, is exactly "---",
     and the block runs to the next line whose strip() is "---". A file whose
     first line is anything else — an HTML comment, a heading, a blank line —
     has no frontmatter at all, however many "---" fences appear later.

F-2  ANY flush-left line containing a colon becomes a top-level key. Only the
     leading-whitespace test at the top of the loop excludes a line; there is no
     effective guard beyond it. In particular a full-line "#" comment inside the
     block IS admitted as a key — the shipped
     operations/templates/project-rollup-template.md parses to 14 top-level
     keys, 2 of which are its own "#" comment lines — and so is ordinary prose:
     "This is prose: something" yields the key "This is prose".
     The internal-space guard below is UNREACHABLE and is frozen as unreachable.
     Its enclosing condition asks whether key differs from raw_key.rstrip(), and
     a flush-left line has no leading whitespace, so strip() and rstrip() agree
     and the condition is never true. Deleting the dead guard is harmless;
     REPAIRING it is not — making it reachable would drop prose- and
     comment-derived keys that every consumer has resolved since this module
     shipped. If you came here to fix it, that is the behaviour change you would
     be making, and case (5) will tell you so.

F-3  The value is everything after the FIRST colon; it loses exactly ONE
     matching pair of surrounding quotes, and is then stripped AGAIN, so inner
     padding does not survive: `padded: "  T  "` resolves to "T", not "  T  ".
     Escapes are NOT interpreted — a backslash-quote inside a quoted value stays
     two characters — because this is a block reader, not a YAML engine.

F-4  A "#" in a value is CONTENT, never a comment delimiter. This is a decision,
     not an omission. Measured across the tracked corpus at the time of this
     decision, 639 of 6,664 parsed values carry a "#" and 543 carry it with no
     preceding whitespace — issue references, heading anchors, flow-list
     members. A strip here changes every consumer's resolved value at once,
     silently, and truncates real content wherever the author meant the "#"
     literally; even a YAML-faithful rule still truncates measured non-template
     values, including one where the "#" sits inside a quoted string nested in a
     flow list. A consumer whose key has a DECLARED SHAPE validates that shape
     and fails loudly on a polluted value; that is where the constraint belongs,
     and compose-portfolio.py's project_id join key is the worked instance.

F-5  A key line with an empty value yields "". The caller decides whether
     present-but-empty counts as present — Check 50 treats it as a missing-field
     finding, and that is the caller's policy, not this module's.

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
    as present (Check 50 treats present-but-empty as a missing-field finding).
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
            # DEAD GUARD — frozen as unreachable, see docstring F-2.
            # The leading-whitespace filter above means raw_key never carries
            # leading whitespace, so strip() and rstrip() always agree and this
            # branch is entered only when key is empty — in which case " " in key
            # is False and the `continue` below never runs. The effect is that
            # ANY flush-left line containing a colon becomes a top-level key,
            # including a "#" comment line and ordinary prose. Six consumers have
            # resolved values under that behaviour since this module shipped.
            # Do not "repair" this into reachability: that is a corpus-wide
            # resolved-key change, and case (5) asserts against it.
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

    Implemented on top of read_frontmatter so the parse is shared (F1): no
    consumer can disagree with any other about what a frontmatter block is or how
    a value is quote-stripped, because every one of them asks THIS module.
    """
    keys, status = read_frontmatter(doc_path)
    if status in ("no-file", "no-frontmatter"):
        return None, status
    if "framework_version_anchor" in keys:
        return keys["framework_version_anchor"], "ok"
    return None, "frontmatter-no-key"


def is_corpus_path(path: Path, root: Path) -> bool:
    """True when `path` is inside the corpus rooted at `root` — i.e. NO segment of
    its root-relative path begins with a dot. This is the ONE traversal predicate
    the THREE deploy-tool corpus walkers share, so a file is in the corpus for
    all of them or out of it for all of them (the F1 consistency guarantee,
    applied to traversal). The count bounds the claim: see the module docstring
    for the further *.md walker (check-work-hierarchy.py) that is deliberately
    outside this population. Dot-leading DIRECTORY segments (`.git/`, `.body-backups/`) and
    dot-leading FILENAMES (`.draft.md`) are BOTH excluded — the filename is a
    segment of the relative path like any other. Raises ValueError for a path
    outside `root`, exactly as the inline expressions it replaces did."""
    return not any(part.startswith(".") for part in path.relative_to(root).parts)


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

        # (5) FROZEN SEMANTICS — the docstring's F-1, F-2, F-3 and F-4 clauses,
        # anchored as assertions rather than prose. (F-5 is anchored in case (1),
        # and F-1's first-line-is-a-fence half in cases (1) and (2); this case
        # carries F-1's two FENCE-BOUNDARY clauses, which no other case reaches.)
        #
        # READ THIS BEFORE "FIXING" A FAILURE HERE. These assertions exist to
        # FAIL a future comment-strip (or a repair of the dead internal-space
        # guard), not to test one. They pass on BOTH arms of such a change by
        # design — pre-change and post-change — because the behaviour they pin
        # is already shipped and is deliberate. They are a tripwire, not a
        # discriminator. The fails-before/passes-after discriminator for this
        # defect class lives in compose-portfolio.py's (join-key-polluted) case,
        # where the constraint actually belongs: at the consumer that declares a
        # shape for its key.
        d5 = base / "frozen.md"
        d5.write_text(
            '---\n'
            '# Placement: under core/deploy/tools/\n'
            'project_id: proj-alpha        # renamed from alpha-2024\n'
            'anchor: terminology-glossary.md#term-work-item\n'
            'padded: "  T  "\n'
            'quoted: "a \\" b # c"\n'
            '---\n# Body\n',
            encoding="utf-8",
        )
        keys5, status5 = read_frontmatter(d5)
        assert status5 == "ok", status5

        # F-4 — a "#" in a value is CONTENT. Each value must resolve WHOLE.
        assert keys5["project_id"] == "proj-alpha        # renamed from alpha-2024", (
            "F-4: a trailing '#' comment is part of the value; a strip here "
            "would change resolved values across all six consumers at once"
        )
        assert keys5["anchor"] == "terminology-glossary.md#term-work-item", (
            "F-4: a heading anchor's '#' has no preceding whitespace and must "
            "survive; 543 measured corpus values carry this shape"
        )

        # F-3 — exactly one quote pair is removed, escapes are NOT interpreted,
        # and the value is stripped AGAIN after the slice.
        assert keys5["quoted"] == 'a \\" b # c', (
            "F-3: one outer quote pair removed; the backslash-quote stays TWO "
            "characters and the '#' survives"
        )
        assert keys5["padded"] == "T", (
            "F-3: _strip_quotes re-strips after the slice, so inner padding does "
            "NOT survive — 'T', never '  T  '"
        )

        # F-2 — any flush-left line with a colon is a key, "#" comments included.
        assert "# Placement" in keys5, (
            "F-2: a full-line '#' comment inside the block IS admitted as a "
            "top-level key; the internal-space guard is unreachable"
        )
        assert keys5["# Placement"] == "under core/deploy/tools/", keys5["# Placement"]

        # F-2 second arm — ordinary prose, with the nested-list SPECIFICITY arm
        # alongside it so a pass cannot come from the reader admitting nothing.
        d6 = base / "prose.md"
        d6.write_text(
            '---\nThis is prose: something\ncomposes_with:\n  - x.md\n---\n',
            encoding="utf-8",
        )
        keys6, status6 = read_frontmatter(d6)
        assert status6 == "ok", status6
        assert keys6.get("This is prose") == "something", (
            "F-2: an internal-space flush-left line becomes a top-level key"
        )
        assert "- x.md" not in keys6, (
            "SPECIFICITY: an INDENTED line is still excluded — F-2 widens what "
            "counts as flush-left, it does not remove the indentation filter"
        )

        # F-1 — the two FENCE-BOUNDARY clauses. They are pinned HERE because no
        # other case reaches them: every fixture above either opens with a fence
        # or carries no later fence at all, so a mutation to either boundary
        # leaves all of them green. Both clauses are properties six consumers
        # have resolved values under since this module shipped.
        #
        # First arm — frontmatter exists IFF the FIRST line is a fence, HOWEVER
        # MANY fences appear later. A tightening that scans for the first "---"
        # instead of testing line 0 (the tolerate-a-leading-blank-line repair) is
        # exactly what this arm fails.
        d7 = base / "late-fence.md"
        d7.write_text(
            "\n---\ntitle: NotFrontmatter\n---\n# Body\n", encoding="utf-8"
        )
        keys7, status7 = read_frontmatter(d7)
        assert status7 == "no-frontmatter" and keys7 == {}, (
            "F-1: a first line that is not '---' means NO frontmatter, however "
            "many fences follow; a later fence does not start a block. Got "
            f"{status7!r} / {keys7!r}"
        )

        # Second arm — the block ENDS at the next "---". A flush-left key line
        # BELOW the closing fence is body text, not frontmatter. The in-block
        # assertion beside it is the SENSITIVITY arm: without it, a reader that
        # admitted nothing at all would satisfy the absence claim vacuously.
        d8 = base / "after-fence.md"
        d8.write_text(
            "---\ntitle: Inside\n---\nafter_fence: leaked\n# Body\n",
            encoding="utf-8",
        )
        keys8, status8 = read_frontmatter(d8)
        assert status8 == "ok" and keys8.get("title") == "Inside", (
            "SENSITIVITY: the block ABOVE the fence must still parse, or the "
            f"absence assertion below passes on a reader that admits nothing. "
            f"Got {status8!r} / {keys8!r}"
        )
        assert "after_fence" not in keys8, (
            "F-1: the block runs only to the next '---'; a flush-left "
            "'key: value' line below the closing fence is body text and must "
            "NOT become a top-level key"
        )

        # (6) is_corpus_path — the shared traversal predicate. BOTH dot-leading
        # shapes are excluded: a dot-leading DIRECTORY segment and a dot-leading
        # FILENAME. The issue body names only the directory shape; the filename
        # shape is over-returned identically, and a half-fix covering only
        # directories is invisible to the two walkers' own self-tests.
        assert is_corpus_path(base / "a" / "b" / "doc.md", base) is True, (
            "a plain nested path is in the corpus"
        )
        assert is_corpus_path(base / ".body-backups" / "doc.md", base) is False, (
            "a dot-leading DIRECTORY segment puts the path out of corpus"
        )
        assert is_corpus_path(base / ".draft.md", base) is False, (
            "a dot-leading FILENAME is out of corpus — the filename is a segment "
            "of the relative path like any other"
        )
        # SPECIFICITY — an INTERNAL, non-leading dot is ordinary content. This arm
        # stops a future "strip anything with a dot" regression from passing.
        assert is_corpus_path(base / "beta_steerco.txt.meta.yml", base) is True, (
            "SPECIFICITY: an internal, non-leading dot does NOT exclude a path"
        )
        # The preserved error contract: a path outside `root` raises, exactly as
        # the inline relative_to() expressions this predicate replaces did.
        try:
            is_corpus_path(Path("/somewhere/else/doc.md"), base)
            raise AssertionError("a path outside root must raise ValueError")
        except ValueError:
            pass

    print("_frontmatter self-test OK")
    return 0


if __name__ == "__main__":
    # Explicit argv dispatch: the self-test discovery predicate reaches this
    # module through the `--self-test` token, so with the token only in the
    # docstring a docstring rewrite silently drops it from the manifest floor
    # while its row stays on disk. A bare invocation stays an alias.
    if "--self-test" in sys.argv or len(sys.argv) == 1:
        sys.exit(_self_test())
    print("usage: _frontmatter.py [--self-test]", file=sys.stderr)
    sys.exit(2)

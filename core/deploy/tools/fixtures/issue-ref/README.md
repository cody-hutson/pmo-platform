---
title: core/deploy/tools/fixtures/issue-ref/
purpose: Fixture corpus for check-issue-ref-validity.sh --self-test — the sensitivity and specificity classes of the Issue-reference validity gate, encoded so that tracked fixtures carry no literal reference token.
type: reference
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
# Fixture corpus — Issue-reference validity gate

Test data for `core/deploy/tools/check-issue-ref-validity.sh --self-test`. Not a
document anyone reads for guidance; the files here exist to be materialised into
a throwaway git repository and scanned.

## Why the fixtures carry sentinels instead of references

A fixture whose job is to fail an issue-reference gate is, by construction, a
file full of the exact tokens that gate rejects. Committed as-is, the LIVE gate
would flag every one of them on the very change that adds the corpus.

The obvious remedy is the wrong one. Giving each fixture the whole-file override
marker would make the checker's own override path fire on every fixture, and the
entire suite would return zero **vacuously** — a green suite that proves nothing,
which is worse than a red one.

So tracked fixtures store **sentinels**, and the harness expands them when it
materialises the corpus:

| Sentinel in the tracked file | What the harness writes |
|---|---|
| `@@REF@@` followed by digits | a hash followed by those digits |
| `@@IMP@@` followed by a hyphen and digits | the deprecated legacy identifier |

Tracked files therefore contain no reference token at all, the live gate has
nothing to flag, and the materialised fixtures are pristine — including the one
fixture that legitimately carries the override marker, which is testing exactly
that path.

**Do not add the whole-file override marker to any fixture except `z1-override.md`.**
It is the one fixture whose subject IS the override.

## Layout

| Path | What it holds |
|---|---|
| `manifest.txt` | one row per fixture: class, source, destination path in the fixture repo, and the expected verdict in each of the two input modes |
| `verdict-map.txt` | the static number-to-verdict map consumed by `--resolver fixture` and by the `gh` test double |
| `cases/` | the HEAD-state body of each fixture |
| `base/` | the BASE-state body, for the classes that need a pre-existing state to be distinguishable from an added one |

The heading matrix — every recognized reference-block spelling crossed with every
heading level, each in its own file with a sensitivity twin — is **generated** by
the harness rather than tracked. The checker only ever locates the first
reference block in a file, so packing the spellings into one file would test the
first spelling and silently skip the rest; and 84 near-identical tracked files
would be a maintenance surface with no reader.

## The two classes, and why both are mandatory

**Sensitivity (`S-*`, must flag).** A reference that 404s; one that resolves to a
different repository after a transfer; one that is a pull-request number; the
deprecated legacy identifier; a valid reference above the block with no inline
marker; a valid reference in a file with no block at all; and a valid reference
under a heading that is a deliberate near-miss.

**Specificity (`Z-*`, must return zero).** The whole-file override; each path
exemption arm; a failing reference inside a fenced code block; the inline
provenance marker as the placement alternative; every recognized heading spelling
at every level; a pre-existing reference outside the added-line delta; and the
near-miss tokens that must not widen the tokenizer.

Each specificity assertion ships alongside a sensitivity assertion **from the
same invocation**. A zero reported by a harness that never ran is
indistinguishable from a zero reported by a harness that ran and found nothing,
and only the second is evidence.

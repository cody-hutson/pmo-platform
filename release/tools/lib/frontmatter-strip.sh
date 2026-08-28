#!/usr/bin/env bash
# frontmatter-strip.sh — Shared §5.1 frontmatter-strip transform for the
# release-body tool family.
#
# The SINGLE home of the release-note BODY transform. Every shell tool that
# derives a published Release body sources this library, so the transform that
# release-notes-standard.md § 5.1 calls DETERMINISTIC is realized in ONE place:
#   - release/tools/automated-closeout.sh        (Phase 15.5 — publishes Surface 1)
#   - release/tools/check-release-body-drift.sh  (the Stage-13 drift gate)
#   - release/tools/reemit-release-bodies.sh     (the § 5.6 re-emitter)
#
# ─── WHY A LIBRARY AND NOT A COPY ───────────────────────────────────────────
# This transform was replicated at four call sites, and the invariant that the
# copies must move together was carried by a PROSE COMMENT. That comment's own
# list was incomplete — it named two of the four shell sites and neither Python
# mirror — and the copies duly diverged: automated-closeout.sh kept the
# pre-repair single-stage form after the two-stage lead-in repair landed, and
# computed different bytes from its siblings for three live notes (v1.08 /
# v1.09 / v1.10). A comment cannot fail; a shared function plus a committed
# fixture can. Same call as ADR-068 made for the schema-v1 emitter.
#
# ─── WHY awk AND NOT sed ────────────────────────────────────────────────────
# The idiom this replaces — `sed '1,/^---$/d; 1,/^---$/d'` — yields an EMPTY
# body on the Linux CI runner while returning the body on macOS. Measured at the
# discovery gate's first enablement; the consequence was a Stage-13 gate that
# reported "no drift" because it was comparing nothing against nothing.
#
# The repair does not reason about which sed is right. Two competent readings of
# that address construct disagree, and no GNU sed is reachable from the authoring
# host to adjudicate — so a different sed form would relocate the unverified
# premise rather than remove it. This awk program carries its state in an
# explicit variable, with no implementation-defined range machine to disagree
# about, and its equivalence to the shipped two-stage pair is measurable on the
# host we have: byte-identical on the whole live note corpus, with a
# deliberately-wrong awk differing on every note.
#
# ─── FROZEN SEMANTICS S1-S5 ─────────────────────────────────────────────────
# The committed fixture at core/deploy/tools/fixtures/frontmatter-strip/ is the
# CONTRACT; this list is its summary. All three implementations of these
# semantics (this file and the two Python mirrors named below) are bound to that
# one fixture, so a divergent reimplementation fails a test instead of passing
# silently.
#
#   S1  Any lead-in before the opening `---` is dropped. (Without this, a note
#       carrying a lint directive above its frontmatter PUBLISHES its raw YAML.)
#   S2  The opening fence and every frontmatter line are dropped.
#   S3  The closing fence is dropped; everything after it is emitted verbatim,
#       so a `---` horizontal rule inside the body survives.
#   S4  Fewer than two `^---$` lines anywhere yields EMPTY output — fail-CLOSED.
#       Callers MUST guard on empty before publishing; publishing an empty body
#       over a populated one is irreversible (gh release edit overwrites and
#       GitHub keeps no body history).
#   S5  The fence match is exact `^---$`. A fence carrying trailing whitespace
#       does NOT close the block.
#
# Python mirrors bound to the same fixture (they must move with this file):
#   release/tools/preflight-release-body-reemit.py  strip_frontmatter()
#   core/deploy/tools/lint_release_corpus.py        extract_body()
#
# This file is sourced, never executed. It defines one function and returns; it
# has no main and no side effects at source time. It reads NO caller globals —
# the caller passes its own path, or pipes its own stream.

# ---------------------------------------------------------------------------
# strip_frontmatter [FILE...] — emit the §5.1 release-note BODY.
#
# With zero arguments awk reads stdin, so ONE function serves both callers: the
# file-argument form (`strip_frontmatter "$note"`) and the stream form
# (`git show "$ref:$path" | strip_frontmatter`). Safe under `set -u`.
#
# /usr/bin/awk is pinned rather than resolved through PATH for the same reason
# the tools pin /usr/bin/sed: a shimmed awk on the invoking host must not be
# able to change what gets published to a public Release page.
# ---------------------------------------------------------------------------
strip_frontmatter() {
  /usr/bin/awk 'f { print; next } /^---$/ { n++; if (n == 2) f = 1 }' "$@"
}

<!-- repo-integrity: allow-issue-ref -->
<!-- Declared under limb (1): this fixture DISPLAYS the override construct as its
     subject matter, and its numbers are synthetic and cannot resolve by
     construction. The rationale sits in its OWN comment because the shipped
     override regex anchors the marker's closing delimiter immediately after the
     token — a rationale written INSIDE the marker comment does not match, and
     the file would then not be exempt at all. -->

Specificity fixture Z-1 — the whole-file override.

The body below fails every sensitivity class at once. The override is total by
design: placement AND validity are skipped for the whole file. A single finding
against this file means the override path was dropped in extraction.

- @@REF@@909501 — does not resolve, and sits above any block.
- @@IMP@@-009 — the deprecated legacy identifier.
- @@REF@@909500 — resolves, but is placed outside a designated block.

<!-- repo-integrity: allow-issue-ref -->
<!-- Declared under limb (1): this fixture DISPLAYS the override construct as its
     subject matter, and its numbers are synthetic and cannot resolve by
     construction.
     The rationale sits in its OWN comment, and the marker on line 1 stays BARE,
     DELIBERATELY — this is no longer a workaround for a regex that could not
     accept a trailing rationale, it is what keeps the differential oracle
     usable. run_equivalence compares this checker against the PRE-EXTRACTION
     inline body over this shared corpus and asserts the report text is
     byte-identical. That body carries the old narrow override pattern, so a
     rationale-carrying marker HERE would be flagged by the oracle and
     suppressed by the checker — `direction oracle->checker: gate WEAKENED` —
     failing a required status check on a correct fix. The rationale-carrying
     form the standard mandates is asserted instead in the corpus-free
     override-form block in run_self_test, where it costs the oracle nothing.
     Do not convert this marker to the rationale-carrying form. -->

Specificity fixture Z-1 — the whole-file override.

The body below fails every sensitivity class at once. The override is total by
design: placement AND validity are skipped for the whole file. A single finding
against this file means the override path was dropped in extraction.

- @@REF@@909501 — does not resolve, and sits above any block.
- @@IMP@@-009 — the deprecated legacy identifier.
- @@REF@@909500 — resolves, but is placed outside a designated block.

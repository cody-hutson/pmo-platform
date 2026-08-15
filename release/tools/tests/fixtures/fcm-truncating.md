# fcm-truncating — extraction-fidelity arm for the fcm-delivery family

The declared ADD sits AFTER an in-fence `# ── … ──` comment. That one line is what
terminates the section early under the shared, fence-blind `_extract_section`
(`verify-release-plan.sh:238`), whose awk heading rule fires on any line beginning
`#`+space with no knowledge of fenced blocks. Measured over the plan corpus, 26 of the
117 File-Change-Matrix-bearing plans truncate exactly this way.

This fixture is the arm that separates three implementations that would otherwise look
identical on every other fixture:

  - fence-aware extractor + truncation guard  -> the ADD row is SEEN and graded
  - fence-blind extractor + truncation guard  -> `ERROR — fcm-section-truncated`
  - fence-blind extractor, no truncation guard -> the obligation is INVISIBLE and the
    matrix reads as "no unconditional ADDs, therefore no violations" — a silent
    vacuous pass, which is the dominant defect class this whole family exists to close

Expected (conformant): `PASS — declared-add-delivered:core/does-not-exist.md`, exit 0.

## File Change Matrix

```
core/deploy/deploy.sh  EDIT
# ── additions (Engineering Commit 0 and its companion) ──
core/does-not-exist.md  ADD
```

## Deviation Log

| # | Deviation | Severity | Basis |
|---|---|---|---|
| — | none | — | — |

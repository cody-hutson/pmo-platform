# Fixture — sample issue for the `acceptance` assertion type

This fixture is the subject-under-test for the Stage-8 acceptance worked example
(`../stage-gates/stage-08-qa-testing/evals.json`). It is a **synthetic GitHub-issue
body** carrying an `## Acceptance Criteria` block with a deliberate mix of criteria so
the acceptance grader exercises every branch of the parse contract (P1–P6) and the
verdict-projection table: a plainly-met criterion, a not-met criterion, a partial, and
one of each drift class (not-applicable, needs-reinterpretation, blocked-upstream).

It is a fixture, not a live issue — it does not correspond to any real issue number and
carries no cross-references that a repo-integrity gate would flag.

---

## Story

As a maintainer, I want the widget exporter to emit a checksum sidecar so downstream
consumers can verify integrity, so that a corrupted export is detected before use.

## Acceptance Criteria

- [ ] The exporter writes a `.sha256` sidecar next to every exported widget file.
- [ ] The sidecar contains the lowercase hex SHA-256 of the widget file's bytes.
- [ ] A `--no-checksum` flag suppresses sidecar emission (method: run the exporter with the flag and assert no sidecar).
- [ ] The exporter refuses to overwrite an existing sidecar unless `--force` is passed.
- [ ] The legacy `xml-manifest` export mode also emits the sidecar.
- [ ] Sidecar filenames follow the naming convention agreed in the shared-format working group.
- [ ] The checksum verification CLI (delivered by the upstream tooling epic) accepts the sidecar.

## Notes

Synthetic fixture. The seven criteria above are engineered to produce, when graded
against a hypothetical PR that implements checksum emission for the *default* export
mode only, the following worked-example verdicts:

- **AC-1** (sidecar written) → `MET`
- **AC-2** (lowercase hex SHA-256) → `MET`
- **AC-3** (`--no-checksum` suppresses) → `MET` (has an inline `(method: …)` hint per P3)
- **AC-4** (refuse-overwrite without `--force`) → `NOT MET` (Severity: Warning) — the PR did not implement the guard
- **AC-5** (legacy `xml-manifest` mode) → `PARTIAL` — default mode emits, legacy mode does not; unmet remainder is the legacy path
- **AC-6** (naming convention from the working group) → `REINTERPRET-WITH-RATIONALE` — the referenced convention text is ambiguous; grade on intent
- **AC-7** (verification CLI from the upstream epic) → `FLAG-UPSTREAM` — depends on an undelivered upstream output

Expected roll-up (all-drift-out): `acceptance_score = MET / (total − N/A − REINTERPRET − FLAG-UPSTREAM)`
= `3 / (7 − 0 − 1 − 1)` = `3 / 5` = `0.60`. Per-verdict counts:
`{MET: 3, NOT MET: 1, PARTIAL: 1, N/A: 0, REINTERPRET: 1, FLAG-UPSTREAM: 1}`.

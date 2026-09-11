# Pipeline Event Log — M4 POPULATION-SCREEN fixture

The paired log for `hub-state-tree/`. Its `version` column carries the four slugs
that tree holds, because field 2 IS the release join key — the schema names it
*"release join key — the Milestone SLUG"* — and the M4 screen joins a hub-state
slug directory to its log rows through exactly that column. No new data source.

Every row is conformant, so C1 / C2 stay clean and the engine can exit 0 while the
screen flags a slug. That is the shape the screen is for: it reports OTHER releases'
history, which a closing release neither caused nor can repair, so it must never be
able to change an exit code.

**The four slugs are the four buckets, one apiece, and that is deliberate** — a
partition that cannot put a directory somewhere is a broken screen, and the arms
assert the buckets sum to the scanned denominator:

- `fixture-clean-release` — 3 rows, ledger present in the tree → `ledger-bearing`.
- `fixture-closed-no-ledger` — 2 rows, one of them at **stage 13**, no ledger → **`flagged`**.
- `fixture-inflight-no-ledger` — 2 decision rows, **none at stage 13**, no ledger → `not-yet-assessable`.
- `fixture-quiet-no-ledger` — 1 row and it is **not** decision-class, no ledger → `no-decision-row`.

**The prose above deliberately carries no markdown table, and that is a fixture
constraint rather than a style choice.** `read_rows()` skips only the three header
shapes `|---`, `| ts_iso` and `| id ` — so ANY other line beginning with `|` in this
file is read as a log row and graded by C1. An explanatory four-column table here
parses as five malformed rows and turns the fixture non-zero, which is precisely how
the first draft of this file failed: the M4 report-only arm reported rc=1 while every
bucket assertion passed, so the arm that exists to prove the screen cannot move an
exit code is also the arm that catches a dirty fixture. Keep supporting prose in
lists, never in tables.

The `fixture-inflight-no-ledger` row set is the false positive the lifecycle term
exists to remove: `(>=1 decision row) AND (no ledger)` is also exactly what a CORRECT
in-flight release looks like between plan approval and its first durable commitment.
A screen without a completion term flags healthy siblings at every close, forever.

**Only the `fixture-clean-release` rows carry an `AI-<digits>` token.** The other five
carry none, so C4's id join sees nothing new and this tree cannot perturb an existing
arm. The three that do carry one reproduce `log-clean.md`'s pattern — AI-001 opened
and resolved, AI-002 opened only — so the tree's own ledger reconciles against this
log and the engine reaches the screen at exit 0.

| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-24T10:00:00Z | fixture-clean-release | 5 | decision | action-item-opened | hub | AI-001 | CHEAP | resolved | ms:#1; note:opened-for-fixture |
| 2026-08-24T10:00:01Z | fixture-clean-release | 13 | decision | action-item-resolved | hub | AI-001 | CHEAP | resolved | ms:#1; note:resolved-for-fixture |
| 2026-08-24T10:00:02Z | fixture-clean-release | 5 | decision | action-item-opened | hub | AI-002 | CHEAP | resolved | ms:#1; note:opened-never-closed |
| 2026-08-24T11:00:00Z | fixture-closed-no-ledger | 5 | decision | decision-superseded | hub | sub-task:#2 | CHEAP | superseded | superseded:D-1; by:D-2; reason:fixture-decision |
| 2026-08-24T11:00:01Z | fixture-closed-no-ledger | 13 | decision | decision-superseded | hub | sub-task:#2 | CHEAP | superseded | superseded:D-2; by:D-3; reason:fixture-reached-stage-13 |
| 2026-08-24T12:00:00Z | fixture-inflight-no-ledger | 5 | decision | decision-superseded | hub | sub-task:#3 | CHEAP | superseded | superseded:D-4; by:D-5; reason:fixture-decision |
| 2026-08-24T12:00:01Z | fixture-inflight-no-ledger | 9 | decision | decision-superseded | hub | sub-task:#3 | CHEAP | superseded | superseded:D-5; by:D-6; reason:fixture-still-in-flight |
| 2026-08-24T13:00:00Z | fixture-quiet-no-ledger | 9 | gate-outcome | plan-review-go | operator | milestone:#4 | EXPENSIVE | resolved | verdict:GO |

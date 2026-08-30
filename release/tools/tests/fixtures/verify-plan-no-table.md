# vTEST Release Plan — verify-release-plan.sh fixture (ZERO per-issue denominator)

> Fixture for `release/tools/tests/test_verify_release_plan.sh`.
>
> THE ZERO-DENOMINATOR SPECIMEN. This plan carries a `## Verification Plan`
> heading whose table is deliberately NOT a per-issue table — its header names
> none of the schema columns, so the parser correctly declines to index it and
> emits no per-issue records at all.
>
> Before the roll-up carried its denominator, this plan reported `0 ERROR` and
> exited 0 — byte-identical on that line to a plan whose 26 rows all classified
> cleanly. Any consumer asserting `error == 0` was asserting nothing. The
> roll-up must now SAY that it found no per-issue verification table, and the
> stderr honesty warning (previously dead, because two always-on families keep
> the record stream non-empty) must fire.

## Verification Plan

| Family | Check | Owner stage |
|---|---|---|
| gate | the release-scoped check-table shape, which names no schema column | Stage 9 |
| gate | correctly skipped in silence: this is not a per-issue table | Stage 9 |

<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
# RELEASE_INDEX_ARCHIVE-v4

Archive segment of [`RELEASE_INDEX.md`](RELEASE_INDEX.md) — the **v4** release family.

This file is the same record as its parent ledger, relocated. It is a **Vital**
record under `core/governance/RECORDS_POLICY.md`, retained permanently, and it
inherits its parent's class: a segment is a disposition *destination*, never
itself a disposition *source*. Nothing here is a lesser record for having aged
out of the working set.

It lives in the same directory as its parent deliberately, so `grep -r` over
that directory still finds this content exactly as it did before the move. Each
entry below retains its heading in the parent ledger, with a pointer here.

Entries are appended by `release/tools/sweep-release-corpus.py`; the file is
append-only and is never itself swept.

---
#### v4.0

Agent-FinOps intelligence layer over the v3.96 foundation — spend **reporting** sliced by work item / worktree / skill / model with an honest coverage label and a trend view that declines to characterize a direction when coverage itself moved, an **estimator** that names its comparables and confidence and refuses below its evidence floor, and the **estimate-vs-actual calibration loop** (accuracy metric + bias + RAG bands, item-grain capture at admission and close under a canonical Tracker 10, and ADVISORY-only feedback into planning). Store bumped to v1.2.0: `session.cwd` replaced by the `worktree` basename as a data-minimization control under a written three-condition frozen-kind exemption (**ADR-101**), plus five additive analysis sub-aggregates with an always-present reserved `"unknown"` bucket and a stored `dimension_coverage` label; the version stops encoding which phase has run. **ADR-102** records the quota-budget substrate supersession. **Nine fail-opens** closed — the load-bearing one being that *nothing executed* the four scripts' `--self-test`, so the assertions guarding the other eight could not fire; now CI-wired with a precision probe that fails if a self-test degrades to zero assertions. `novel` class, **MAJOR** bump (rationale operator-authored and pending), EXPENSIVE reversibility. Three accepted limitations filed: #4206, #4207, #4208.

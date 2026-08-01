<!-- repo-integrity: allow-issue-ref -->
<!-- repo-integrity: allow-memory-ref -->
<!-- reference-durability: allow-link -->
<!-- reference-durability: allow-url -->
# RELEASE_DIGEST_ARCHIVE-v4

Archive segment of [`RELEASE_DIGEST.md`](RELEASE_DIGEST.md) — the **v4** release family.

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
### v4.0 (2026-07-29) — See where agent spend goes, and measure estimates against reality
A `novel`-class release on milestone #293 (`agent-finops-intelligence`), **D-C SINGLE** topology, one release PR (#4209), 8 delivery slices on one branch, 64 commits, 50 files (+6,194/−113), 4 `.skill` packages rebuilt. The **first MAJOR bump** — the rationale for it is **operator-authored and pending** by deliberate reservation; the record carries the class and the floor only. Sequence `#4044 → #4043 → {#3912, #3911} → {#3610 → #3611 → #3612 → #3613}`, the plan's original parallel pair refuted on five shared files. **#4044** replaces `session.cwd` with the `worktree` basename — a frozen-kind field replacement carried under a written, three-conjunctive-condition exemption (**ADR-101**) instead of the v2.0.0 the schema's literal rule would have forced for zero safety gain, with a runtime store-shape preflight (exit 3) enforcing condition (i) rather than trusting it. **#4043** adds five additive `session` sub-aggregates plus a stored `dimension_coverage` label, each token-bearing map carrying an always-present reserved `"unknown"` bucket so a partial dimension is *structurally incapable of under-reporting*; the store version stops encoding which phase has run (the predicate becomes `any(.record=="coverage")`). **#3912** renders slices and trends whose coverage arithmetic closes, and whose trend view **refuses to state a direction** when coverage itself moved. **#3911** estimates from historical comparables, naming the rows, the firing rule and the band provenance, and volunteering that its own thresholds are proposals. The **calibration half** (#3610–#3613) needed a **full rework mid-release** to be executable at all — as first built nothing created the row, so the capture AC could not be performed; five coordinated repairs landed (row-creating write at the readiness gate, the `(item × family × close ordinal)` key, an asserted grant replaced by a 16-row enumerated table whose missing element was the one the feedback lever needed, a citation reconciled by writing the requirement it claimed, and start-date immutability rebound to the **field** rather than the action). **Nine fail-opens** closed, the load-bearing one structural: a search of the workflow dir and deploy script for the four script names returned **zero hits**, so no self-test ran and the fail-closed assertions guarding the other eight could not fire — now wired into an existing workflow whose own precision probe deliberately breaks a real invariant and fails if a self-test degrades to zero assertions. **CIAC-5 × CIAC-1 conflict decided:** the last spawn-ledger pointer sits inside the frozen `rollup` kind, so byte-unchanged was preserved and the pointer neutralized by a superseding note in the non-frozen region rather than edited. Stage-8 **ACCEPT-WITH-CONCERNS ×8, every AC MET as written** · CI 46/46 · merge operator-performed after Stage-12 B1 handed back BLOCKED on denied `--admin` rather than working around the control. **EXPENSIVE reversibility / HIGH confidence** — whole-merge revert only, no clean partial path; the store is a rebuildable cache so no data migration either way. Three accepted limitations filed and named on the record: #4206 (estimator declines for most real queries), #4207 (confidence can read HIGH on a bimodal set), #4208 (a declared fail-closed check need not name a runner).

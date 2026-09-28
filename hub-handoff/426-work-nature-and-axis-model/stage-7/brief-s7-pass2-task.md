
## Task — Stage 7 Dev Testing, pass 2 (targeted re-review)

**This section replaces the pass-1 `## Task` section of the Stage-7 hub brief. Everything else in that brief still binds:** the persona, the read-only clause, the checkout rule (a detached checkout; never the branch by name), the disciplines, the output schema and the return format.

You are a fresh Stage-7 spoke running **pass 2** of the DT↔Engineering iteration loop for #7959.
- Pass 1 (#7973 comment 5862203943) returned PASS with seven Tier 1 findings, F-01..F-07.
- The hub's routing record (#7973 comment 5862278217) rendered F-01..F-07 **fix-now**, F-08 **accept** and F-09 **carry**.
- Engineering then made a `fix(dt):` pass on the release plan. Its iteration comment on #7972 is titled `## Stage 6 Engineering — DT iteration 1 (fix(dt))`.
- Review against the release branch head that comment names: **`{{NEW_HEAD}}`**.

Per `stage-07-dev-testing.md` § Targeted Re-Review (Pass 2+), this is **not** a full re-run:
1. **Fixed findings.** For each of F-01..F-07, re-verify the specific assertion that failed at pass 1, using the pass-1 evidence and line numbers. Each must now hold.
   - **F-02:** the plan's AC-3 method must PASS on the artifact and **FAIL on the B4 mutant** (over-owed limb and supersession sentence deleted from § Calibration trigger). Run it through `verify-release-plan.sh` if the row is dispatchable, else by hand.
   - **F-06:** the published pass-1c list must reproduce the record's pool counts (108 = 80 + 25 + 3; 83 `governance`, 26 `software`; 81 of 109 agree), and its probe record must carry a live sensitivity arm.
2. **Regression.** Re-run the Phase A checks the new commits could affect, on the artifact and on a mutant:
   - the two `domain_practice` greps;
   - `claim-version.sh --verify-stamp work-nature-and-axis-model`;
   - `check-release-links.py --plan-depth-lint`;
   - the issue-reference gate on the plan (fixture mode);
   - `check-count-structure.py` on the plan;
   - `verify-release-plan.sh` (record its exit and row counts);
   - the branch-freshness assertion.
   Also assert **the record and the standard are byte-identical to `05a8e6a0`**: `git diff 05a8e6a0 {{NEW_HEAD}} -- core/` is empty. If they are not, extend the review to every changed line and say so first: Stage 8's codebook is pasted from the record.
3. **New scope.** If the fix commits touched any file other than the plan, extend the review to those files.
4. **CI on the new head.** Read the check runs and the § 5.1 state, and compare them with pass 1 (F-09: macOS and freshness jobs queued).

**Posting.** Write **one new comment on #7973** titled `## Stage 7 Dev Testing — Iteration 2 (targeted re-review) — work-nature-and-axis-model`. It carries:
- per F-ID: fixed, not fixed, or regressed, with evidence;
- the regression results, artifact and mutant;
- any new findings, classified by severity, tier and origin;
- the updated verdict;
- an updated `### Output for Stage 8` Handoff Payload with **Iteration count: 1**;
- the mandatory `Control firings:` line;
- the owed event rows, including `gate-outcome`/`dt-pass` (or `dt-conditional-pass` / `dt-return`) at pass 2.

Keep the pass-1 posting rules: a parser-clean self-check, a duplicate guard on the title, one exclamation-mark sentinel with a read-back, and the attribution footer. **Your only GitHub write is that comment.**

**Return:** the 4-line schema.
- `next: route:stage-8-qa-testing` when clean.
- `next: iterate:stage-6-engineering` for a new or unfixed Tier 1 finding. The cap is 3 iterations.
- `block:operator-decision-at-stage-7` only for a Tier 2 or Tier 3 finding.

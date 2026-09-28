# Hub brief — Stage 6 Engineering, DT iteration 1 (`fix(dt):` pass) — #7959

You are the same Stage 6 Engineering spoke, resumed by the hub. Your original hub brief, its disciplines and its bounds still apply, except where this brief narrows them.

**Why you are resumed.** Stage 7 Dev Testing (#7973, comment 5862203943) returned **PASS** with seven Tier 1 [ADJUST] findings, F-01..F-07, and routed `iterate:stage-6-engineering`.
- The hub verified each finding independently at `05a8e6a0`.
- It rendered their dispositions by the Finding Disposition Framework: each is low-effort, best-practice-aligned and CHEAP on an open branch, so Step 1 gives **fix-now**.
- F-08 (Cosmetic, the `domain_practice` label's placement) is **accepted** as a Note: **do not change it**. F-09 (queued CI) is carried to Stage 9.

Read #7973 comment 5862203943 in full before you edit anything. Its § Findings and § Decisions & Recommendations give each finding's evidence and line numbers.

**Scope of this pass: the release plan only**, `release/releases/plans/work-nature-and-axis-model_RELEASE_PLAN.md`, plus your iteration comment.
- **Do not edit the record (`core/ADRs/ADR-207-…`) or the standard.** Stage 8 pastes the record's codebook sections verbatim, and both files passed Stage 7 unchanged.
- If a fix appears to need an edit to either file, stop and report it instead.

## Fixes (each lands in a `fix(dt):` commit)

1. **F-01 — the blind re-code's read order.**
   - B5 (#7971 comment 5860663381) says the Stage-8 spoke records its codes "before it opens the ADR, the plan or this sub-task". "This sub-task" is **#7971**.
   - In the plan's threat **V15** (≈L462) and the § Verification Plan **D5 row** (≈L495), replace "the record, this plan or #7972" with the full set. The Stage-8 spoke records its codes before it opens:
     - the record or this plan;
     - #7959's thread;
     - #7971 (where B5 was posted);
     - #7972;
     - #7973;
     - #7991;
     - #7997;
     - PR #8004;
     - any other issue of milestone 426.
   - Keep each row's other content unchanged.
2. **F-02 — AC-3's probe must be section-scoped (B4 limb 2).**
   - The AC-3 row (≈L476) greps the whole record, so the phrase at § Status (record L19) keeps it at 1 on the B4 mutant.
   - Replace it with a method scoped to the extracted § Calibration trigger section, for both "supersedes this one" and "over-owed".
   - It must **PASS on the artifact and FAIL on the B4 mutant** (over-owed limb and supersession sentence deleted from § Calibration trigger).
   - Prefer a form `verify-release-plan.sh` can dispatch. Test that on a fixture plan outside the tree, as Stage 7 did.
   - If no dispatchable section-scoped form exists, keep the row honest instead: state that AC-3 is hand-run with its mutant, and record both arms in § Verification Evidence.
3. **F-03 — the executor's exit code.**
   - § Verification Evidence (≈L622) records `verify-release-plan.sh --format=table` as "(exit 0)". It exits **3** ("one or more checks FAIL or ERROR").
   - Re-run it after fixes 1–2 and record the observed exit and row counts.
4. **F-04 — B4 limb 3's claim.**
   - The plan's § Amendments applied B4 row (≈L179) says every check ran on the artifact and on a mutant. § Verification Evidence records no ADR-schema run, and no mutant arm for several rows.
   - Make the claim true to what Stage 6 ran. Add the ADR-schema line. For rows Stage 6 did not mutant-test, cite the Stage-7 battery (#7973 comment 5862203943), which ran every row on artifact and mutant.
5. **F-05 — pre-filing authority text, as a new DEV row.**
   - Your coding log quoted V-15's and V-21's authority from the governed file's **current** text. The text in force before each item was raised (v2.30: (a)–(c); v3.99: "unless one of three conditions holds") supports the same codes, as Stage 7 verified. The codes are unchanged.
   - Add a Deviation Log row saying so, and name the tags.
6. **F-06 — publish the pass-1c concept-1 list.**
   - The record's pool-level class counts rest on your pass-1c list, which lives only in your run directory (`concept1.tsv`).
   - Publish it in your iteration comment on #7972 as a collapsed `<details>` block, with one row per delivered pool item: number, milestone, plan, class, and resolved/inferred/unresolved with its basis.
   - Include a probe record: denominator, a sensitivity arm and a specificity arm.
   - Add a Deviation Log row citing that comment.
   - **If the published list does not reproduce the record's counts** (108 = 80 + 25 + 3; 83 `governance`, 26 `software`; 81 of 109 agree), stop and report. Do not change the record.
7. **F-07 — a non-scope path.** The non-scope row at ≈L314 names `release/references/pipeline/triage-design-rereview.md`, which does not exist. Correct it to `release/references/standards/triage-design-rereview.md`.

## Commits, checks, PR body

- **Commit convention.** `fix(dt): <specific fix> [ADJUST] (#7959)`. You may batch fixes of one category into a single commit, but each commit message lists the F-IDs it addresses. Stage each file by explicit path, and push after each commit to `release/work-nature-and-axis-model` only. Hook-Safe Git Idioms as in your original brief: no plain force-push.
- **Re-run what the plan edits can affect,** each on the artifact and a mutant:
  - the issue-reference gate on the plan, in fixture mode;
  - `claim-version.sh --verify-stamp work-nature-and-axis-model`;
  - `check-release-links.py --plan-depth-lint`;
  - `check-count-structure.py --path <plan>`;
  - `verify-release-plan.sh` on the plan, recording the exit;
  - the parser-clean grep over the plan.
- **Update PR #8004's body.** Add the new commits to the Implementation row. Add the new DEV rows to the Deviation Log summary. Correct the Verification Evidence summary: the executor exits 3, and AC-3 is scoped. Run the parser-clean self-check before the update. Nothing else on the PR changes.

## Output and return

**Your one iteration comment, on #7972.** The issue is closed; comment without reopening it.
- Title: `## Stage 6 Engineering — DT iteration 1 (fix(dt)) — work-nature-and-axis-model`.
- It carries:
  - a table of each F-ID → commit → what changed;
  - the re-verification results;
  - the F-06 collapsed block with its probe record;
  - the new head SHA;
  - the mandatory `Control firings:` line;
  - any event rows you owe.
- End it with a blank line, a `---` rule, and `_Generated by [Claude Code](https://claude.ai/code)_`.
- Before posting, re-read #7972's comments. If an iteration comment already exists, do not post; return `BLOCKED`.
- Put one exclamation-mark sentinel in the comment, and report the read-back.

**GitHub writes you may make in this pass:** pushes to the release branch; the PR #8004 body update; that one comment on #7972. Nothing else. Never invoke the Agent tool or `spawn_task`. Do not tag, release, merge, or mark the PR ready.

**Your final message** is exactly these 4 lines:

**Spoke Result — Stage 6 Engineering (DT iteration 1) — #7959**
verdict: PASS | FAIL | CONDITIONAL | BLOCKED
sub-task: #7972 (output-posted | open-blocker)
comment: <URL of your iteration comment>
next: route:stage-7-dev-testing | block:operator-decision-at-stage-6 | block:dependency-#<M>

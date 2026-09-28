# Stage 8 hub brief — Part 2 (open only after `codes-blind.md` is hashed)

**Scoring**, after hashing, against the Stage-6 answer key: the record's § Validation set rows V-01..V-09, and the V-01..V-09 entries in #7972 Parts 2–3.
- **Nature agreement:** your primary nature equals Stage 6's.
  - The Stage-6 coder worked while `restructure` and `behaviour-change` were still candidates, so some items are recorded as "fits no nature → matches X". Such an entry **agrees with your code X**.
- Report **k of 9**, to which the D5 floor of 7 applies, and **k′ of the 7** left once V-03 and V-09 are set aside. Those are the two items the codebook was refined on.
- **Grade agreement** per item × axis, reported two ways: as exact grade equality, and as equality under the Rubric's "Counts as" column.
- **Owed-set agreement** per item.
- **For each disagreement:** both codes; the procedure step or rubric line where they diverge; the decisive text; and whether a pasted interpretation was involved.
- **Consequences, in the record's own terms:**
  - Does k ≥ 7 hold?
  - Do the Stage-6 `defect` codes in the nine (the record lists which) survive your re-code?
  - Would any row's status change?

A consequence that would change the record's text is a finding for Part 2. Route it as FLAG-UPSTREAM / Tier 1 [ADJUST] (or Tier 2 when it changes what the record decides). Never edit anything yourself.


### Part 2 — the acceptance review (after hashing)

**Checkout for Part 2.**
- Run `git fetch origin release/work-nature-and-axis-model`, then `git checkout --detach {{HEAD}}` in your session worktree.
- **Never check out the branch by name.** Another worktree holds it.
- Write no repository file, commit nothing and push nothing.

**Scope: REDUCE.** This comes from Stage-4 decision D-4 (A). The deliverable has no executable surface. Every Phase step of § 5 still runs or is recorded N/A-with-reason.

1. **Phase A, entry validation.**
   - Stage 7's verdict and a conformant Handoff Payload come from #7973.
   - AC-1..AC-6 must be extractable from #7959 at 23:01:38Z.
   - **PR #8004 is a draft by design until Stage 12.** Judge "mergeable" as "no conflict with `main`" (`pull_request_read` → `mergeable`). Report its queued check runs as queued, not as failures.
2. **Phase B, per-criterion verdicts for AC-1..AC-6**, using the two-judgment model and the Stage-8 six-value enum, by the named reads in the plan's § Verification Plan.
   - Evidence comes from artifact content, cited as `file:line` or quoted. It never comes from checkbox state, the PR description's self-claims or Stage 7's PASS.
   - **The AC-6 collision check needs its control arm:** the same check with `story` appended to the identifier set must return 1.
   - **Runtime-suite selection:** expect the no-match row (`release/references/standards/runtime-suite-selection-map.md`), because there is no executable path.
   - **Include the D5 result as the evidence bearing on each AC it touches.** At minimum this is the AC under which the record reports proven rows and the demonstration. Include it also as its own section of the Acceptance Report.
3. **The fitness-beyond-literal-AC assessment** (Mode H step 7). Met-the-letter-missed-the-point findings become Lane-3 decision cards.
4. **Phase C: classify and route findings**, via the 3-lane table and the Finding Disposition Framework with its Step-0 gate. For any non-fix NOT MET or AC-blocking PARTIAL, *surface* the Operator Override Record requirement; never author it.
5. **`acceptance_score`**, recorded rather than gated. Then the Acceptance Report, rendered from `operations/templates/qa-acceptance-report-template.md`.
   - The **overall verdict** (ACCEPT / CONDITIONAL ACCEPT / REJECT / HOLD) is operator-only (Phase E), and the operator renders it at the Stage-9 gate.
   - Give your **recommended** overall verdict and its basis.

**Already decided and carried to the operator's Stage-9 gate; not findings to re-raise:**
- R1: the `restructure` and `infrastructure-change` boundary examples sit beside V-21 and V-22.
- R2: procedure steps 7–8.
- R3: widening #7963.
- R4: `restructure` was admitted at the floor.
- R5: `defect` is proven for `governance` only.
- #7403's contention with the standard.
- The executor's ungraded rows, which Stage 7 addressed.

Your D5 result is **new evidence on R4 and R5** and on whether any row stays proven. Present it as such.

**Posting.**
- Write your output to a body file in your run directory, and post that file's exact contents as **one comment on #7974**. If the body exceeds 60,000 characters, split it into at most 3 consecutive comments that open with `**Part n/N**`. Together they are still your one output.
- Put the Part-1 codes (all nine items, with quotes) in the output: they are evidence the operator needs at Stage 9. Give the hash and the time you hashed.
- **Parser-clean self-check before posting.** Run `grep -inE "(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) +#?\[?[0-9]"` on the body file. Reword any hit.
- **Duplicate guard.** Immediately before posting, re-read #7974's comments. If a comment opening `## Stage 8 QA Testing` or `**Part 1/` already exists, do not post, and return `verdict: BLOCKED`.
- End every posted comment with a blank line, a `---` rule, and the line `_Generated by [Claude Code](https://claude.ai/code)_`.
- **Read-back.** Put exactly one exclamation mark in each part as a sentinel. After posting, read each part back, and report its served length and exclamation-mark count against your local file.

**Owed event rows.** List them in your output's Evidence, in the form of `release/tools/append-pipeline-event.sh --version work-nature-and-axis-model --stage 8 …`, with the actor `spoke:#7974`. Include every row the Stage-8 spec requires, and one row per finding the spec maps to an event. The hub stages them, because this environment has no log.

**GitHub writes you may make:** the one output comment on #7974 described above, and nothing else. This includes #8004 and all nine items: read them, but never comment on, review, label or edit them. Route every cross-scope finding to the hub in your output. Do NOT close #7974. Never invoke the Agent tool or `spawn_task`.

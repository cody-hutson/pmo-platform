
## Task
Execute Stage 8 per `release/references/pipeline/stage-08-qa-testing.md` and the instructions on sub-task #7974, as an independent acceptance reviewer, against PR #8004 at head **`{{HEAD}}`**.

**Declared mode:** `Mode H — Acceptance Review` (QA Auditor, per the Stage 8 persona card's Replacement line). Apply it from the repository text (read-order item 7), after Part 1.

**Overrides to #7974's body (the operator's Stage-5 decisions post-date it):**
- The graded body is #7959 at revision **2026-09-27T23:01:38Z**, not 15:41:37Z.
- The operator's round-1 decision D5 and binding amendment B5 add the blind re-code below.
- The record's own § Owed axes by nature → **Row grading.** paragraph requires this stage's acceptance report to record the re-code's agreement.

### Part 1 — the D5 blind re-code of V-01..V-09 (do this first)

**Why it is blind.** The study's codes rest on one coder, and the codebook was refined on two of the drawn items. You re-code the first nine drawn items **from the codebook alone**, before you see the release's codes or results. Your agreement with the release's codes decides whether the study's rows can stand: a nature agreement below 7 of 9 leaves every row a hypothesis. This brief deliberately states none of the study's results.

**The nine items:** V-01 #5844 · V-02 #4197 · V-03 #4923 · V-04 #5846 · V-05 #3722 · V-06 #5589 · V-07 #5843 · V-08 #2344 · V-09 #6255.

**Reads allowed before your codes are hashed:**
- **The codebook below,** carried verbatim from the record and the plan at the head under review. The only other material is the Stage-6 coder's general interpretations, which name no item.
- **Each of the nine items:** its issue body, its comment thread, and its state, `state_reason`, labels and milestone.
- **The item's E2-chain sources:** the closing PR body; the release PR body of the milestone that delivered the item; commits citing the item; and the item's Stage-5 output (the Stage-5 sub-task of the milestone that delivered it, where one exists).
  - Find commits with `git log origin/main --grep='#<N>\b' -E` (never `--all`), with the connector's PR and commit reads, and with the links the item's own thread gives.
- **The repository at `origin/main`, for authority checks (step 5).** Only governed files, ADRs and ratified release plans count, each as it stood **before the item was raised**. Establish that with `git log --follow --format='%h %cI' -- <path>` and `git show <commit>:<path>`.

**Forbidden until your codes are hashed:**
- #7959 and its comments.
- Every issue or PR numbered 7959 or higher, except your own sub-task #7974's body. This covers the milestone's sub-tasks #7969–#7979, the reviews #7991 and #7997, PR #8004 and the cards filed from this study.
- #7960–#7966.
- The branch `release/work-nature-and-axis-model`: any file, any commit, any log.
- Any text that describes this release's validation study.

If an allowed source links to a forbidden one, do not follow the link. If you reach forbidden content by accident, stop, record what you saw and when, and report it. Do not silently continue.

**Checkout for Part 1.** Your session worktree starts at the hub's commit, which equals `origin/main` (`35dbf418`) and does not contain the record. Detect first with `git rev-parse --show-toplevel`, and **stay at `main` for Part 1**.

**How to code.** For each item, apply the pasted **Classification procedure** to every acceptance criterion:
- Record the step each criterion reached and the nature it takes. Criteria that verify no change are recorded as unclassified.
- Record the primary nature, the secondary natures and the **owed set**.
- For each `defect` code, record the quoted authoritative source, its path or ADR and the basis for its authority, and show that it existed before the item was raised.

Then grade the four axes by the pasted **Grades** and **Rubric**. Give each grade:
- the quoted passage (at most 25 words);
- its source;
- a note if the passage sits in an E2-T section.

Record C1 and C2 for every item. Record C3, C4 and C6 where you can. Skip C5: its concept-1 rules are not part of this re-code.

**Interpretations.** Mark every point where the codebook was silent and you had to rule. Name the interpretation you applied, whether one of (a), (b), (c) or (e) below or your own, and say whether it decided the item's nature.

**Bank and hash, then open.**
1. Write the codes to `$SPOKE_OUT/codes-blind.md`, one section per item.
2. Run `sha256sum "$SPOKE_OUT/codes-blind.md"` and record the digest and the UTC time.
3. **Only then** read the forbidden sources.
4. Never edit `codes-blind.md` after hashing. If you change your mind later, write the new view to a separate file, and score only the hashed codes.

### The codebook for Part 1 (verbatim at head `{{HEAD}}`; nothing else from the record or the plan may be read before hashing)

{{CODEBOOK}}

#### The Stage-6 coder's general interpretations (plan DEV-10; neutral: they name no item and give no answer)

{{DEV10}}

(Interpretation (d) is not carried: it concerned an earlier draft of the procedure. Code all eight natures exactly as the procedure above states them.)

**After hashing — open Part 2.** Part 2 (scoring, the acceptance review, posting rules and owed rows) is in a second file:
`{{PART2_PATH}}`
Open it **only after** you have written and hashed `codes-blind.md`, read it in full, and follow it. It states study results that must not reach you before your codes are fixed. Never cite that file's path in any GitHub comment or file; it is part of "the hub brief".


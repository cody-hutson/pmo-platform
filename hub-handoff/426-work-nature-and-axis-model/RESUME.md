# Hub resume package — milestone 426 `work-nature-and-axis-model`

Written by the outgoing cloud hub (Mode O) on 2026-09-28 at about 02:45Z, for the incoming hub. The operator is expected to resume locally in a new chat with `/release-hub mode o: milestone #426`. Procedure 0b (Resume) reads this file together with the live GitHub state. **Live GitHub state wins wherever the two disagree:** re-read every sub-task and the branch head before acting.

## 1. Where the release stands

| Stage | Sub-task | State | Records (comment ids) |
|---|---|---|---|
| 4 Planning | #7969 | closed | plan 5857188429, 5857214680 · Decision Recorded 5857334506 · Scaffold 5857383283 · operator-instance catch-up (AI-001/002 done) 5861283335 |
| 5 Solutioning | #7971 | closed | revision 2: 5858980491, 5859002126, 5859019340 · round-1 decisions 5858641152 · **round-2 decisions (binding B1–B10, A″) 5860663381** · adversarial reviews #7991 (5858497919), #7997 (5859321582) |
| 6 Engineering | #7972 | closed | output 5861342230, 5861372837 (erratum), 5861382523 · hub verification 5861464095 (7 staged rows) |
| 7 Dev Testing | #7973 | **open — iteration 1 in progress** | pass-1 output 5862203943 (PASS; 7 Tier 1 findings F-01..F-07) · hub routing 5862278217 (dispositions; 13 staged rows) |
| 8 QA Testing | #7974 | open, not started | brief staged in this package (D5 blind re-code) |
| 9 Plan Review | #7975 | open — **STOP gate** (register row 8), hub-presented | — |
| 10, 11 | #7976, #7977 | closed not planned (platform-satisfied) | — |
| 12 Execute | #7978 | open — STOP gate (register row 9), operator instance | — |
| 13 Close | #7979 | open — operator instance | — |

**The change:** member #7959, graded body revision **2026-09-27T23:01:38Z** (AC-1..AC-6).
- Release branch `release/work-nature-and-axis-model`, head **`05a8e6a0`** at handoff. `main` is `35dbf418`.
- Draft PR **#8004**; its milestone, labels and assignee are set.
- Three files: `core/ADRs/ADR-207-design-axes-and-cut-patterns-key-on-work-nature.md` (new, `status: Proposed`); `core/standards/gate-efficacy-standard.md` (+3 lines: Rows A and C at the register tail, Row B at the Version History tail); and the plan `release/releases/plans/work-nature-and-axis-model_RELEASE_PLAN.md`.
- The Release Outcome Statement is **A″**, and the milestone description carries it.

**Study results (single coder, not yet re-coded):**
- `defect` is the only proven row: 6 delivered items, all deliverable class `governance`.
- `restructure` was admitted at the floor (3) and `behaviour-change` with 6.
- The one-key question was not testable for any nature. The sample has 0 E3-F.

## 2. Next actions, in order

### A. Stage 6 DT iteration 1 — the `fix(dt):` pass on the plan

This pass was **launched from the cloud hub after this package was written**, by resuming the original Stage-6 spoke with `stage-6/brief-s6-dt1.md`. If the cloud credits ran out, it may not have run, or it may have stopped part-way. Determine which from GitHub:
1. **#7972 has a comment titled `## Stage 6 Engineering — DT iteration 1 (fix(dt))`.** The pass completed.
   - Run Procedure 4 on it: verify F-01..F-07 at the new head; confirm `git diff 05a8e6a0 <new head> -- core/` is empty; stage its event rows.
   - Post a short routing note on #7973, then go to **B**.
2. **The branch head moved past `05a8e6a0` with `fix(dt):` commits, but that comment is absent.** The pass was cut off. Its pushed commits are banked. Spawn a **fresh** Stage-6 spoke:
   - Build the brief from the Spoke Template: persona, worktree, PR-body, repo-integrity and hook-safe disciplines, and the four all-spoke disciplines.
   - Add `stage-6/brief-s6-dt1.md` as its task, and tell it to resume from the branch.
3. **The head is still `05a8e6a0` and there is no comment.** Spawn a fresh Stage-6 spoke the same way.
4. **In cases 2 and 3,** the fresh spoke cannot read the cloud run directory. Hand it `stage-6/concept1.tsv` (the Stage-6 spoke's pass-1c list; sha256 in `stage-6/concept1.tsv.sha256`) as a **hub-supplied input** for F-06, labelled with its provenance.
   - `stage-6/brief-s6.md` is the original cloud brief, kept for reference. Its venue text (no `gh`, connector substitutes) does not apply locally.

### B. Stage 7 pass 2 (targeted re-review)

- The brief is `stage-7/brief-s7.md` (the pass-1 brief) with its `## Task` replaced by `stage-7/brief-s7-pass2-task.md`. Fill `{{NEW_HEAD}}`.
- It is read-only and posts one new comment on #7973.
- On a clean result: close #7973 after the hub record, then go to **C**.

### C. Stage 8 QA plus the D5 blind re-code (#7974)

- Render with `stage-8/assemble-s8.sh <out-dir> <head> "<Stage-7 comment ids>"`. It writes `brief-s8.md` (what the spoke reads first) and `brief-s8-part2.md` (opened only after its codes are hashed).
- **Keep the split:** study results must not appear in the first file. The cloud hub caught and fixed exactly that leak in its own draft.
- The codebook (`stage-8/codebook-s8.md`) was extracted verbatim from the record at `05a8e6a0`. If the fix pass changed the record, which it must not, re-extract before launching.
- The blindness rule forbids every issue or PR numbered 7959 or higher, and the release branch, until the codes are hashed. This covers F-01, since #7971 holds the pre-B5 boundary examples and the pilot notes.
- **D5 floor:** a nature agreement below 7 of 9 leaves every row a hypothesis. The record's Row grading paragraph requires this stage's report to record k of 9 and k′ of 7.

### D. Stage 9 GO/NO-GO (#7975). This is a STOP: never auto-crossed and hub-presented. Assemble per `stage-09-plan-review.md` (A3.5, A3.6, A3.7, A6, A6.5, A6.6, A7, A8, A9, B, C):
- **A7 goal-conformance** against **A″** (#7975's body still says A′, which is superseded). **CIAC:** none. **G-PR9 baseline:** `35dbf418`.
- **A6.6 contention.** At about 02:00Z the open sibling release PRs were #7839, #7895, #7901, #7919 and #7931, all draft.
  - ADR slot 207 is also claimed by #7839 (207–210), #7895 (207–208) and #7919 (207). The record renumbers at merge.
  - AI-005 is a keep-both merge on the standard's two tails with #7919 and #7901.
- **A6.5 version dimension:** provisional v4.70, which all five siblings also compute. The Stage-12 atomic claim arbitrates.
- **A8:** mark #8004 ready for review, and read back `isDraft`.
- **Readiness scan dimension 14:** at pass 1, 6 of 18 required contexts (macOS and `.skill` freshness) had been queued since 00:42Z (§ 5.1 state 3). Re-read before GO.
- **Decisions to put to the operator** (see § 4) and the emission contract: `gate-outcome/plan-review-go` or `plan-review-no-go` (MUST), plus the choice-delta rows.

### E. Stages 12–13 on the operator instance

- AI-005: the keep-both merge.
- The merge-time ADR renumber.
- AI-003: #7966 re-triages #7960, #7961 and #7962 against the record, or an explicit deferral, before C1. The milestone does not close without it.
- The G-CL9 ratification flip of the record to Accepted.

## 3. Action-item ledger (operator instance: `<OPERATOR_INSTANCE_HUB_STATE_PATH>/work-nature-and-axis-model/action-items.md`)

| id | owner | status | what | trigger |
|---|---|---|---|---|
| AI-001 | operator | done | milestone description edits | — |
| AI-002 | operator | done | replay of 68 rows through Stage 5 | — |
| AI-003 | hub | open | #7966 re-triage or explicit deferral | Stage 13, before C1 |
| AI-004 | operator | done | Stage-6 venue (D3 = the cloud session) | — |
| AI-005 | hub | open | keep-both merge on the standard with #7919 and #7901 | Stage 12, before B1 |
| AI-006 | hub | done | A″ adopted | — |
| AI-007 | hub | open | carry R1–R3, with R4/R5 as context and the #7403 note, to the Stage-9 briefing | Stage 9 |
| AI-008 | operator | open | replay the hub-staged rows for Stages 6–9, and the iteration-log row | Stage 9 (the local catch-up task replays Stages 6–7 early) |
| AI-009 | hub | open | two follow-up-card questions to the Stage-9 briefing | Stage 9 |

AI-007, AI-008 and AI-009 are not yet in the local ledger; `staged-rows/ledger-rows.md` holds their exact 13-field text.

## 4. Operator decisions owed at Stage 9

- **GO / NO-GO.**
- **Stage 8's Phase-E overall verdict** (ACCEPT / CONDITIONAL ACCEPT / REJECT / HOLD). It is operator-only.
- **R1 (DEV-11).** Replace the `restructure` and `infrastructure-change` boundary examples, which sit beside V-21 and V-22, with examples from outside the set?
  - Under B1 the `restructure` example also collides with step 5 inside `core/`, `release/` and `.claude/`.
  - Stage 7 found the collision was live when V-21 was filed.
  - A yes means a record edit **before** Stage 12.
- **R2 (DEV-12).** Confirm or reword procedure steps 7–8, which the candidate admission added.
- **R3 (B6).** Widen the framing-to-cut card #7963 to carry silent and not-applicable axes?
- **The #7403 note.** Post a contention note? #7403 would edit the same standard's § Requirement (b), and it is unmilestoned.
- **AI-009.** File two follow-up cards?
  1. The plan executor returns `ERROR (unclassified)` for prose-method rows, 11 on this plan, and binds its `sync` rows to `deploy.sh --check`'s global exit.
  2. The `domain_practice` label's placement: Stage 4 § 5.7 names the Release Class section, but 5 of the last 6 plans use `## Header`.
- **Context, not decisions:**
  - R4: `restructure` was admitted at the floor.
  - R5: `defect` is proven for `governance` only.
  - The D5 result.
  - The F-09 CI state.

## 5. Environment notes and recorded deviations (cloud hub)

- **No `gh`.** GitHub was reached through the MCP connector. **No event log:** since Stage 5 round 2, every owed row is staged as replay text in GitHub comments and validated with `append-pipeline-event.sh --dry-run`.
  - Replay order: #7972 5861464095 (7 rows), then #7973 5862278217 (13 rows plus one iteration-log row).
  - Earlier rows were replayed under AI-002.
- **Briefs were delivered as files plus a short inline wrapper,** for byte-fidelity of the verbatim Spoke-Template clauses. That wrapper was path-leak scanned; the scanner's control fires.
- **Quota gate:** rendered PROCEED with both bases UNSTATED, because there was no `rate_limit` read. Locally, read it.
- **Spoke-output notes:**
  - A Stage-6 spoke owed-row classed as `escalation/tier-3` was reclassified to `scope-change/tier-1-adjust`, because Tier 3 means plan rejection.
  - The Stage-7 spoke's return carried prose outside the 4-line schema. This is Minor.
- **Cost reference:** the Stage-7 spoke used about 573K tokens and 540 tool calls over about 88 minutes. The Stage-6 spoke took over 2 hours.
- **Filed during this run:** #7994 (bug: the schema-v1 emitter passes JSON on argv, causing E2BIG), #7995 (the ADR `#N` placement rule conflicts between the guide and the gate), #7996 (align the improvement form's Domain with registry concept 1).

## 6. Package contents

- `RESUME.md`: this file.
- `stage-6/`:
  - `brief-s6-dt1.md`: the fix-pass task;
  - `brief-s6.md`: the original cloud brief, reference only;
  - `concept1.tsv` and `.sha256`: the pass-1c list for F-06.
- `stage-7/`: `brief-s7.md` (pass 1) and `brief-s7-pass2-task.md`.
- `stage-8/`: the brief parts, `codebook-s8.md`, `dev10-s8.md` and `assemble-s8.sh`.
- `staged-rows/`:
  - `s6-rows.sh` and `s7-rows.sh`: replay scripts, identical to the comment text;
  - `iteration-log-row.md`;
  - `ledger-rows.md`: AI-007, AI-008 and AI-009.

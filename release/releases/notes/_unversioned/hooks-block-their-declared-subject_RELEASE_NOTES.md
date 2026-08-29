---
version: hooks-block-their-declared-subject
date: 2026-08-28
type: note
issues: ["#4977", "#5250", "#5293", "#5515", "#5568", "#5593", "#5812"]
pr: "#6189"
links:
  plan: release/releases/plans/hooks-block-their-declared-subject_RELEASE_PLAN.md
  log_anchor: "#hooks-block-their-declared-subject-version-less"
reversibility-tier: CHEAP
themes: ["cluster:security-controls", "cluster:release-pipeline"]
summary: "Seven safety controls were checking something narrower than what they claimed to check, so actions they were meant to catch went through unchallenged. Each now covers its stated subject."
requires_action: false
breaking: false
---

# Security controls now cover what they say they cover

2026-08-28 · hooks-block-their-declared-subject

Seven of the platform's safety controls were quietly checking something narrower than what they claimed to check, so some actions they were meant to catch went through unchallenged. Each now covers the subject it declares, and the places a control still cannot reach are written down rather than left implied.

> **Skip the rest** unless you rely on the platform's safety controls or want to know which gaps closed.

## Who this affects

- Anyone whose work is governed by the platform's safety controls — which is everyone using it, since these controls run on every session rather than only during releases.

## What changed for everyone using the platform

- **The guard on skill files now reaches files in subfolders.** It previously looked only one folder deep, so a reference file nested any deeper was left unguarded. *Why it matters:* twelve real files were sitting outside a protection everyone assumed covered them, and nothing announced the gap.

- **Running a script directly is now checked, the same as running it through an interpreter.** The approved-scripts list only ever saw the interpreter form; starting a script directly skipped the check entirely. *Why it matters:* the list is meant to govern what can execute, and one ordinary way of starting a script was not being asked about at all. This one starts in a warning mode and graduates on a deadline, so it announces itself before it begins refusing anything.

- **The block on writing between the two workspaces now applies in the direction that carries the risk.** It used to stop both directions, though only one of them can move private working content into a public code repository. *Why it matters:* the other direction was being refused for no safety reason, and a control that refuses harmless work teaches people to route around it.

- **Approved paths are honoured however you type them.** Quoting a path, or putting a flag before it, used to make a control refuse a path that was on its own approved list. *Why it matters:* a false refusal on approved work is the fastest way to lose trust in a control that is otherwise doing its job.

- **Trailing punctuation no longer slips past a check.** A path ending in a bracket or a quote character could pass through a filter that should have examined it. *Why it matters:* this took four separate fixes to close, because each one corrected a layer and left the next layer still examining the wrong thing.

- **Governance files are identified by where they live, not by what they are named.** Any file that merely shared a protected name was treated as protected, and a protected file kept in a working copy elsewhere was not. *Why it matters:* the check now follows the repository the file actually belongs to, so it holds even when work happens in a temporary copy on a different part of the disk.

- **A rule stopped claiming to protect a file it never covered, and a reference page stopped repeating that claim.** The written description and the actual behaviour had drifted apart in two separate places. *Why it matters:* believing a control covers something it does not is worse than knowing it does not, because nobody goes looking for the gap.

## Known limits

- Several gaps are now written down rather than closed, and the list of them is explicitly incomplete rather than presented as the full set. A path containing a space inside its quotes, a script fetched while a command is running, and a target with no file extension are each still outside what these controls examine — each is recorded, with a test pinning the current behaviour so that changing it later has to be a deliberate act.
- One control's approved-directory list was measured on an Apple Silicon Mac and is not portable to an Intel Mac, where one of those directories is writable without elevation. Nothing currently detects that difference.

Report issues at https://github.com/cody-hutson/pmo-platform/issues with the `cluster: security-controls` label.

## Reversibility

CHEAP / HIGH confidence. A single `git revert -m 1` of the release pull request reverses every code change, and the deployed copies are restored from the snapshot the deploy retained before writing.

---

### Operator and engineering detail

Seven cards, one shape: a matcher, an exemption, or a specification whose declared subject was not the thing it actually examined.

The largest piece took four remediations in sequence, and that sequence is the finding: each fix corrected one layer and left the next layer deciding on the wrong input — a token stripped past its own closing quote, then a filter probe mistaken for a verdict, then a raw token in an exemption, then raw tokens in a flag walk. Two fully green test suites coexisted with live bypasses the whole time, because the tests covered only the shapes someone had already imagined.

Two findings arrived after grading was complete. A reference fragment asserted two properties of a rule it does not own, both false — while the same generated page stated them correctly a hundred and fifty lines earlier, from that rule's own fragment. And merging the mainline produced a silent allow out of two individually correct changes that keyed on the same condition: one ran first and made the other unreachable. The test suite caught the second; nothing but reading caught the first.

Verification: the hook test suite reports 1147 passing and 0 failing under a materialized continuous-integration layout, and every deployed control was confirmed against its source by content hash rather than by exit status, because the refresh can report success having deployed nothing.

### References

- Release pull request: https://github.com/cody-hutson/pmo-platform/pull/6189
- Milestone: https://github.com/cody-hutson/pmo-platform/milestone/362

---
version: governance-declarations-match-enforcement
date: 2026-09-03
type: note
issues: ["#5518", "#1772"]
pr: "#6835"
links:
  plan: release/releases/plans/governance-declarations-match-enforcement_RELEASE_PLAN.md
  log_anchor: "#governance-declarations-match-enforcement-version-less"
reversibility-tier: CHEAP
themes: ["project:governance-hygiene"]
summary: "Two charter instructions that asked for more than the platform enforces now name who performs them and what actually backs them."
requires_action: false
breaking: false
components: ["CLAUDE.md.template", "Session Management", "Bridge Files (Layer 3)"]
followups: ["#6846", "#6847", "#6848", "#6849", "#6872"]
---

# The charter now says who performs a rule, and what backs it

2026-09-03 · governance-declarations-match-enforcement

Two instructions in the workspace charter told every session to do something only some sessions are allowed to do, and listed a set of files without saying what put them on the list. Both now state the session they bind, the rule that always holds, and the separate question of whether anything stops you.

## What changed for everyone using the platform

- **The session-end instruction now names who performs it.** The charter told every session to update the session-handoff and corrections files at the end of a session. It now says those two writes belong to a session started in the operations workspace, and that a platform-engineering session reads both files at the start and writes neither at the end. *Why it matters:* an instruction that every session was told to follow, but only some sessions could, is the kind of rule an agent reports as done without having done it.

- **The charter separates a rule from the thing that enforces it.** A new passage states the rule plainly — a platform session does not write into the operations area, and the right response to needing that write is to restart the work where it belongs — and then says separately that the automatic check behind it is switched off in a fresh install. *Why it matters:* on a default install nothing will stop you, and the charter now says outright that nothing stopping you is not the same as being allowed.

- **The bridge-file list now says what earns a place on it.** One sentence above the table explains that it lists only files one side writes for the other side to read, and names the three session-handoff and correction files that are governed further down the page instead. *Why it matters:* the table previously read as an incomplete list of coordination files, so a reader could reasonably conclude three important ones had been left off by mistake.

## Known limits

- **The fix lands on the charter, not on every document that repeats the instruction.** A higher-precedence operations document still carries the unqualified session-end instruction, and on a shared claim it outranks the charter — so the older wording still governs until that document is corrected. Tracked as [#6846](https://github.com/cody-hutson/pmo-platform/issues/6846).
- **The bridge-file membership rule is stated in more than one place, and the statements do not fully agree.** This release fixed the charter's statement; reconciling it with the others is separate work. Tracked as [#6847](https://github.com/cody-hutson/pmo-platform/issues/6847).
- **Nothing in your own files changes.** This release edits governance wording only. No project file, tracker, or generated artifact is touched, and no setting changes.
- **Turning the automatic check on is not part of this release.** The charter now describes what the check does under each setting; changing the shipped setting is a separate decision.

Report issues at the [pmo-platform issue tracker](https://github.com/cody-hutson/pmo-platform/issues).

## Reversibility

CHEAP / HIGH confidence. Both edits are prose additions to a single governance template; reverting the release commit restores the previous wording exactly. Nothing outside the repository was written, so no time-bounded window applies.

---

### Operator and engineering detail

**Both edits land on the composition surface, not the generated file (#5518, #1772)** — The subject is `core/CLAUDE.md.template`, the ADR-122 composition source from which the workspace-root `CLAUDE.md` is generated at update time. Editing the generated file directly would have been overwritten at the next update, and Stage 8 verified the confinement on both cards: the branch diff touches the template and the release plan and nothing else, with control arms confirming zero hook edits, zero decision-record additions, and no generated-root `CLAUDE.md` in the tree.

**The session-end mandate, qualified along the enforcement axis (#5518)** — The charter's session-end line now names the operations-rooted session as the writer and defers writer, write-authority, and class to the unified memory contract rather than restating them. The prohibition on a platform session writing into the operations tree is stated as posture-independent, because the operations-bridge rule that owns it is live and states it unconditionally; what varies is only enforcement severity. The relevant hook is `BLOCK-AUTONOMY-004`, whose three modes are carried in the charter as written, and which sits below the master-activation gate in the `workflow` class — so on a fresh install it contributes nothing at all, not a block and not a log row. The passage states that consequence directly, along with the standing hook-blocked handoff path that applies when the check is switched on. Worth recording for anyone tracing the card: the original issue title names `BLOCK-AUTONOMY-002` as the forbidding hook, and that premise was falsified during planning — the acceptance criterion asserting it was removed and replaced with the master-activation criterion before Engineering ran, so the shipped text names the gate that actually governs the direction.

**The bridge table's membership rule, stated rather than inferred (#1772)** — The added sentence draws the line at cross-domain versus cross-time: a file earns a row when one domain's agent writes it for the other domain's agent to read. `SESSION_STATE.md`, `CORRECTIONS.md` and `SWAP_HANDOFF.md` bridge one session to the next rather than one domain to the other, so they are governed in the Session Management section instead of listed in the table. Stage 8 confirmed the referenced heading exists, and that the table still carries exactly one data row — the point of the card was to explain the row count, not to change it.

**Close mechanics** — This release declared version-less identity at bundling, so it claims no version, cuts no tag, and publishes no GitHub Release; the corpus surfaces landed through the documented close-out chore-PR path, which is the expected route for that identity mode rather than a deviation. For the full audit trail see the [RELEASE_LOG entry](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/RELEASE_LOG.md) and [the release plan](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/plans/governance-declarations-match-enforcement_RELEASE_PLAN.md).

### References

- Milestone: [governance-declarations-match-enforcement](https://github.com/cody-hutson/pmo-platform/milestone/369)
- Release PR: [#6835](https://github.com/cody-hutson/pmo-platform/pull/6835)
- Issues: [#5518](https://github.com/cody-hutson/pmo-platform/issues/5518), [#1772](https://github.com/cody-hutson/pmo-platform/issues/1772)
- Follow-up: [#6846](https://github.com/cody-hutson/pmo-platform/issues/6846) — the higher-precedence document that still carries the unqualified mandate · [#6847](https://github.com/cody-hutson/pmo-platform/issues/6847) — the three disagreeing statements of the bridge membership rule · [#6848](https://github.com/cody-hutson/pmo-platform/issues/6848) — plan verification silent on two criterion methods · [#6849](https://github.com/cody-hutson/pmo-platform/issues/6849) — a gate filter that does not exclude its own named example · [#6872](https://github.com/cody-hutson/pmo-platform/issues/6872) — a close-gate that declares it blocks and never has

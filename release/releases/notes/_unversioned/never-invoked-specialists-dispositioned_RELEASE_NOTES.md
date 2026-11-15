---
version: never-invoked-specialists-dispositioned
date: 2026-11-14
type: note
issues: ["#8452"]
pr: "#8994"
links:
  plan: release/releases/plans/_unversioned/never-invoked-specialists-dispositioned_RELEASE_PLAN.md
  log_anchor: "#never-invoked-specialists-dispositioned-version-less"
reversibility-tier: EXPENSIVE
themes: ["cluster:skill-modes", "project:skill-suite"]
summary: "Most role Specialists were never invoked, and nothing said what each was for. A ratified record now gives each one decision."
requires_action: false
breaking: false
components: ["role Specialists", "skill registry", "skill router", "persona cards", "ADR corpus"]
followups: ["#8997", "#8998", "#8999", "#9000", "#9001", "#9002"]
---

# Every never-invoked role Specialist now has one ratified decision

2026-11-14 · never-invoked-specialists-dispositioned

Most of the role Specialists the platform deploys had never been invoked, and nothing said whether to reach them, fold them into a used skill or retire them. A decision record the operator ratified now gives each one, and the skill router, exactly one decision, resting on a re-run count of invocations; the work to carry the decisions out is filed as follow-ups.

> **Skip the rest** unless you ask for work that a role Specialist is built for, use the scrum master Specialist or the skill router, or maintain the skill registry or the release stage persona cards.

## Who this affects

- Anyone who asks for project or release work that a role Specialist is built for: 11 Specialists are to be re-triggered, so that a request phrased by its goal reaches them. Nothing changes until the follow-up card ships.
- Anyone who uses the scrum master Specialist or the skill router: both are decided for retirement, through the registry's lifecycle states and never by deletion. Both stay active until the follow-up card ships.
- Anyone who maintains the skill registry or the Stage 6, 7 and 8 persona cards: the record decides that two Specialists take over those cards' reference workflows.

## What changed for everyone using the platform

- **Each never-invoked role Specialist, and the router, has one decision.** A re-run count of invocations found 13 role Specialists and the router at zero inside their own windows. Each now carries exactly one ratified decision: 1 kept dormant by design, 11 to be re-triggered with trigger phrases written the way people ask, 2 to be retired, and none folded into another skill. *Why it matters:* nothing previously said what an unused Specialist was for, so each stayed deployed and unreached.

- **Every re-trigger carries an exit test.** The follow-up first gets each Specialist's description in front of the person asking, and only then changes its trigger phrases. A Specialist still at zero at the next re-count is retired. *Why it matters:* a re-trigger that does not reach anyone ends in a retirement decided on evidence, instead of lingering.

- **How often the skill list shows a description is measured, not assumed.** Across 153 days of skill listings, a skill used in the prior 14 days showed its description in 84.8% of listing entries, and a skill not used in that window in 18.8%. *Why it matters:* a better description alone may never be seen, so the re-trigger work starts by getting the description shown.

- **The router and the scrum master Specialist are to be retired, not deleted.** Routing a request to the right role already runs through the PPM agent, and the scrum master's description was shown in about one listing in five and still not chosen. *Why it matters:* routing and sprint requests go to the skills that already serve them, while the retired skills stay readable.

## Known limits

- This release decides; it builds nothing. No skill, registry row, router or persona card changes until the consolidated dispositions card ships, and until then both subjects decided for retirement stay active.
- The count reads the session records of one machine, so use on any other machine is not counted. A later re-count records its results outside the decision record, because an accepted record changes only by being superseded.

Report issues by opening an issue on the platform repository.

## Reversibility

EXPENSIVE / HIGH. The record is accepted, so it changes only through a superseding record, and its decisions bind follow-up work, two of which retire skills. While nothing has been built against it, a revert of the release merge removes the record.

---

### Operator and engineering detail

**The decision record.** The decisions ship as ADR-238, *Each never-invoked role Specialist, and the router, takes exactly one disposition, decided on a re-runnable invocation census*. It was authored `Proposed` at Stage 6. At the Stage 9 gate the operator redirected the ratification once: the record's last rule became a per-row test, two rows took the operator's own decision, and both persona seams were ratified. At the re-presented gate on 2026-11-14 the operator ratified the record with row amendments, and it merged `Accepted`. Ten rows are decided by the record's coding scheme and four are the operator's own decisions. The per-row test reads each row's demand from the skills it composes, and decides direction by exposure: at or above a 10% share of described listing entries, composed-skill use reads as substitution and the row retires; below it, the row re-triggers.

**The census.** The invocation census is one fenced block inside the record, re-runnable at pinned bounds (census head `29c60404`), with a stated denominator, a per-subject exposure window, and both control arms: a non-zero control subject and a nonce arm. Its self-test passes, and every one of its published mutations is caught. The listing finding reads each listing entry as described or name-only, across days, so no re-trigger is decided on a rendering defect alone.

**Follow-ups filed at close.** One consolidated card carries the 13 non-keep dispositions, with each re-trigger's exit test, the two narrowed trigger collisions and the retires' reference cascade. Four platform defects the release ran into are filed separately, each with a reproduction, and two smaller items go in one sweep. One item joins an existing open issue that already owns it.

**ADR number.** Three open pull requests claimed ADR-238 at Stage 12. The record bound the number at its merge without a renumber, and the other two drafts reconcile at their own merges.

For full implementation detail see the [RELEASE_LOG entry](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/RELEASE_LOG.md#never-invoked-specialists-dispositioned-version-less), [the release plan](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/plans/_unversioned/never-invoked-specialists-dispositioned_RELEASE_PLAN.md) and [ADR-238](https://github.com/cody-hutson/pmo-platform/blob/main/core/ADRs/ADR-238-each-never-invoked-specialist-takes-one-disposition.md).

### References

- Milestone: [never-invoked-specialists-dispositioned](https://github.com/cody-hutson/pmo-platform/milestone/445)
- Integration PR: [#8994](https://github.com/cody-hutson/pmo-platform/pull/8994) at `240d3c2ed44e2330d3882de56fbdbd21bc8b4418`
- Stage 12 chore PR: [#8996](https://github.com/cody-hutson/pmo-platform/pull/8996) at `ebc217d8a6898c4c4b32afe07e29ce797d321aa2`
- Closed issues: [#8452](https://github.com/cody-hutson/pmo-platform/issues/8452)
- Follow-up: [#8997](https://github.com/cody-hutson/pmo-platform/issues/8997) (the consolidated dispositions card) · [#8998](https://github.com/cody-hutson/pmo-platform/issues/8998) · [#8999](https://github.com/cody-hutson/pmo-platform/issues/8999) · [#9000](https://github.com/cody-hutson/pmo-platform/issues/9000) · [#9001](https://github.com/cody-hutson/pmo-platform/issues/9001) (the four platform defects) · [#9002](https://github.com/cody-hutson/pmo-platform/issues/9002) (the sweep) · [#7658](https://github.com/cody-hutson/pmo-platform/issues/7658) (the item folded in)

---
version: intake-elicitation-skill
date: 2026-06-06
type: note
issues: ["#412"]
pr: "#424"
links:
  plan: release/releases/plans/intake-elicitation-skill_RELEASE_PLAN.md
  log_anchor: "#deployment-log-intake-elicitation-skill"
reversibility-tier: CHEAP
themes: ["cluster:skill-modes"]
summary: "New conversational intake skill (intake-desk) turns a half-formed idea into a correctly-typed, correctly-placed work item logged to the tracker — never a scratch file. Version-less release (no vX.Y, no git tag, no GitHub Release)."
requires_action: false
breaking: false
components: ["intake-desk", "ADR-016", "core/deploy/deploy.sh", "release/references/how-to/intake-style-guide.md"]
followups: []
---

# A conversational intake front door turns a rough idea into a well-formed work item

2026-06-06 · intake-elicitation-skill (version-less)

There is now a guided intake skill — `intake-desk` — that you can hand a half-formed idea and get back a well-formed, correctly-typed, correctly-placed work item logged to the tracker. It meets you at whatever altitude you start from (a single bug or a whole portfolio initiative), figures out the right work-item type and where it belongs, asks only for the fields that type and level actually need, checks the result against the intake quality bar before anything is filed, and confirms the drafted item with you first — it never drops a scratch file in the repo.

> **Skip the rest** unless you file ideas, bugs, or feature requests into the backlog.

## Who this affects

- Anyone who files work into the backlog — operators and contributors turning an idea, a bug, or a feature request into a tracked work item.

## What changed for everyone using the platform

### Added

- **A guided intake front door.** Ask it to "help me file this idea as an issue" (or "turn this into a work item", "scope this idea for intake", "is this intake-ready") and it runs a short guided interview, then logs the result. *Why it matters:* intake is no longer cold form-filling against a static template — you get help shaping the idea into something the backlog can actually use.
- **It meets you at your altitude and finds the right type.** It proposes whether this is run-the-business or change-the-business work and a specific level (a bug, a story, an initiative), states that back for you to confirm or correct, then proposes the work-item type and where it belongs in the intake hierarchy. *Why it matters:* you do not have to know in advance whether your idea is a bug, a story, or an initiative — the desk works it out with you and routes it correctly.
- **It re-routes when the idea turns out to be something else.** If your answers reveal that what looked like a bug is really a missing capability, it switches the type mid-conversation and tells you why. *Why it matters:* you end up with a correctly-typed item instead of a tidy item of the wrong type that someone has to re-file later.
- **It asks only for the fields that type and level need.** A bug gets asked for reproduction steps and environment; a story for acceptance criteria and value; an initiative for outcomes and domain context. *Why it matters:* you answer the questions that matter for your specific item and skip the ones that do not.
- **It stops asking once the item is good enough — no question marathon.** The desk checks each draft against the intake quality bar (atomic, states the WHAT not the HOW, has a verifiable acceptance criterion, names a file pointer, names risks) and stops as soon as that passes for your item's level. *Why it matters:* a clear ask is filed quickly; you are not over-interviewed, and the item is not over-defined.
- **It shows you the drafted item and waits for your go before filing.** Nothing is logged until you approve the rendered item with a single confirm; if the tracker is unavailable or you decline, it hands you a ready-to-paste body and the exact command instead. *Why it matters:* you always see and approve exactly what gets filed — and the desk never silently writes a draft file into the repo.
- **One request makes one item.** When your idea is a big container, it captures one item at that level and notes the candidate child pieces in the body for later breakdown, rather than auto-creating a pile of thin sub-items. *Why it matters:* the backlog does not flood with under-developed children that someone has to clean up.
- **Unknowns are handed off, never guessed.** When something genuinely cannot be answered yet (which package is failing, which files to touch), the desk records it as a labeled, owned follow-up for the right later stage instead of inventing an answer or quietly dropping it. *Why it matters:* gaps are visible and owned downstream instead of becoming false facts the rest of the pipeline inherits.

## Known limits

- **GitHub Issues today.** The desk files to GitHub Issues for now; filing to other trackers (Jira, Smartsheet) is a designed seam but is not built in this release.
- **No story or initiative type yet.** Until a dedicated work-item type system lands, story-level and initiative-level ideas are filed as `improvement` items differentiated by which fields the desk emphasizes; the desk records the intended level in the body.
- **It hands off owned assumptions; it does not chase them down.** The desk records an unresolved unknown as an owned follow-up for the right stage, but does not itself investigate and close it — that is a separate downstream job.
- **Version-less by design.** No `vX.Y` is assigned and no git tag or GitHub Release is cut for this release; it ships under the slug `intake-elicitation-skill`. The corpus row, index, and digest entry carry the slug in place of a version and the Tag column is `(none)`.

Report issues at https://github.com/cody-hutson/pmo-platform/issues with the `skill-update` label.

## Reversibility

CHEAP / HIGH confidence. The release is purely additive — a new skill directory, one registration line, one new package, one funnel-pointer sentence, an architecture decision record, and the documentation-roster mentions. Reverting the release pull request removes the new skill and re-running the deploy reconciles the runtime mirror. No existing skill or governance contract is changed destructively; no data migration. Standard rollback window.

---

### Operator and engineering detail

**The skill (`intake-desk`)** — a new operations-module skill with two modes: Elicit (a four-phase guided loop — meet at altitude → identify type and place → elicit type/level fields → confirm and emit) and Triage-readiness check (run the 5-test against a draft the user already wrote). The loop's phase boundaries are binary gates (altitude gate → type-landing gate → clarity gate → confirm gate); the clarity gate — the 5-test passing for the type at the altitude — is the stop condition, and the platform "Max 5 questions" guardrail is reframed here as cadence discipline (ask in small sharp batches) rather than an exit criterion. The skill is Autonomy Tier 1: it proposes and renders; the human confirms the logged item via an explicit binary AskUserQuestion before anything is filed. It documents six domain-specific failure modes (over-elicitation past intake-ready; first-classification lock-in; auto-emit / silent scratch-file write; auto-decomposing a container; emitting an incomplete typed item via a freeform-body create; resolving an assumption at intake instead of handing it off).

**Type registry and field derivation** — the type set, the intake hierarchy, and the per-type landing criteria live in the skill's type-map reference; the current set is `improvement` / `bug` / `observation`, with no `adr` type (authoring an ADR is an architecture act, not intake). The required field set, dropdown options, and default labels are derived at use time from each `.github/ISSUE_TEMPLATE/<type>.yml` (the living source of truth) rather than transcribed into the skill, so a template edit never goes stale in the skill. The MVP binds to the current three-type set via a parameterization seam; when the work-item type system lands it repoints the registry portion with no SKILL.md rewrite.

**Output contract** — a tool-agnostic intake-emit process (render → 5-test gate → AskUserQuestion confirm → log → read back → report) with a labeled GitHub MVP binding. Because the issue templates are GitHub Issue Forms with required dropdowns that a freeform-body `gh issue create` cannot populate, the contract carries each required structured value via a label where one exists, or a labeled first body line where none exists (`**Severity:** P2 — Material` for a bug; `**Category:** …` for an improvement, which Triage labels at CER Resolve), and escalates to the observation tier when a required field cannot be faithfully represented. The only persistence paths are the post-approval logged item or a chat-returned copy/paste body — there is no write path to a tracked repo file.

**Domain provenance** — the elicitation-technique content is the platform's first encoding of the requirements-elicitation domain, sourced to IIBA BABOK Guide v3 (Elicitation and Collaboration; the Techniques chapter; the Requirements Classification Schema), which upgraded the Stage 4 SHIP-WITH-FLAG domain-practice label to Mode A at Stage 5.

**Architectural boundary** — ADR-016 records the intake front door as a distinct architectural component at the head of the work-item lifecycle, with a verb-disjoint boundary against the adjacent skills (`intake-desk` authors a typed work item; ppm-agent processes existing artifacts; project-initiator scaffolds and closes projects; architecture authors decision records) and an explicit downstream handoff contract (a typed item plus stage-owned assumptions plus a container's body decomposition callout).

**Registration and deploy** — `intake-desk` is registered in the `core/deploy/deploy.sh` `OPERATIONS_SKILLS` per-module array (not the deprecated `SKILL_LIST` — this corrected the issue body's stale registration target), and the package `packages/intake-desk.skill` is built at the repo packaging tool. The intake-style-guide names the desk as the intake funnel in one link-free durable sentence. Stage 13 `deploy.sh --check` re-confirmed against merged main: Check 5 (skill-roster-drift) OK, Check 6 (canonical-structure) OK for `intake-desk`, Check 7 (package-freshness) OK.

**Process note** — single-branch (D-C SINGLE) via one release PR (#424), Release Class `novel`, version-less per operator decision at Stage 4 following the `public-flip-install-blockers` precedent. Stage 5 was re-solutioned at rev 2 on the operator's PR review, folding twelve design deltas (headline: renamed `intake-elicitor` → `intake-desk`; dropped the `adr` type; one item per request with a body decomposition callout; binary AskUserQuestion confirm with clarity-based exit; altitude-as-confirmed-assumption; owned-assumption handoff; domain-adaptive technique selection; tool-agnostic process with a labeled GitHub MVP). DT/QA found 5/5 ACs PASS; Stage 13 re-confirmed 5/5 against merged main. No signed-annotated tag and no GitHub Release (version-less).

For full implementation detail see the [RELEASE_LOG.md entry](../RELEASE_LOG.md#deployment-log-intake-elicitation-skill) and [the release plan](../plans/intake-elicitation-skill_RELEASE_PLAN.md).

### References

- Milestone: intake-elicitation-skill
- Release PR: [#424](https://github.com/cody-hutson/pmo-platform/pull/424) at `c5afc1d6d4a93e7e2da17f21460ff1b6d55de3cc`
- Issue: [#412](https://github.com/cody-hutson/pmo-platform/issues/412)
- ADR: ADR-016 (intake front door architectural boundary + downstream handoff contract)
- Tag: (none) — version-less release, no git tag and no GitHub Release cut
- Follow-ups (out of scope, enriched at Stage 5 rev-2): [#384](https://github.com/cody-hutson/pmo-platform/issues/384) · [#409](https://github.com/cody-hutson/pmo-platform/issues/409) · [#383](https://github.com/cody-hutson/pmo-platform/issues/383) · [#427](https://github.com/cody-hutson/pmo-platform/issues/427) · [#428](https://github.com/cody-hutson/pmo-platform/issues/428) · [#429](https://github.com/cody-hutson/pmo-platform/issues/429)

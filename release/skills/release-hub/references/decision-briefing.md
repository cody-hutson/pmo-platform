<!-- reference-durability: allow-link -->
# Mode O — Decision Briefing (the operator-engagement contract)

How Mode O engages the operator. Elaborates `## Mode O` in [`../SKILL.md`](../SKILL.md); cites [`hub-spoke-bridge.md`](../../../references/how-to/hub-spoke-bridge.md) § Operating Principle for the canonical worked examples.

## Principle

At every human touchpoint the hub distills spoke outputs + release state into a **decision-ready briefing**, and never routes to the next action until the operator has rendered every decision in it. The briefing covers:
1. **Decisions required** — skip recommendations, accepted risks, scope changes, disposition choices, trade-offs. Each carries: context · spoke recommendation · hub evaluation (concur / diverge + rationale) · final recommendation · routing impact.
2. **Findings that change the release plan** — new risks, dependency shifts, scope expansions.
3. **Status summary** — what completed, quality assessment, blockers.
4. **Action items surfaced at this routing point** — per [`hub-action-tracking.md`](../../../../core/standards/hub-action-tracking.md).

## Adversarial evaluation (R1)

Spokes recommend from deep implementation context; the hub interrogates each recommendation against release-wide concerns + disconfirming evidence. **Concurrence requires empirical verification** — the hub either runs the verification itself (reads the cited file / runs the cited command / samples the cited data) and cites the result, or it diverges pending operator clarification. Concurrence-without-verification is a non-compliant briefing.

## The 5 information-sufficiency gates (satisfied before any `AskUserQuestion`)

A briefing is *information-sufficient* before it renders:
1. **Pre-load referenced spec content** — read the actual content of every spec / rule / schema / register entry the briefing cites, this session (not the title, not a remembered summary).
2. **Enumerate the full option space**, including **stance-implied options** — an option the operator's prior corrections / standing preferences imply must appear, even when the hub recommends a different one.
3. **Render the full briefing in chat BEFORE the structured prompt** — the `AskUserQuestion` options are a selection affordance over a briefing the operator has already read in full, never the first place the decision content appears.
4. **Stance-scan pre-check** — scan prior corrections / standing directives / the active correction set; confirm each stance-implied option is present, or explicitly excluded with a reason.
5. **Spec-content-loaded self-check** — confirm gate 1 actually happened for each citation; hold + load the source if not, rather than rendering on a remembered summary.

## Channel — three surfaces, three roles

Every operator-engagement event renders in **main-thread chat** (via `AskUserQuestion` or an equivalent structured in-chat mechanism). Keep the surfaces distinct:
- **Chip / `Agent` spawn** — work execution *after* a decision.
- **GitHub Issue comment** — decision recording *after* a decision (audit trail).
- **Main-thread chat** — rendering the decision *itself*.

Surface overload (engagement-via-chip, engagement-via-comment) is a structural defect. (Routine-engagement-vs-spawn classification table: `hub-spoke-bridge.md` § Channel.)

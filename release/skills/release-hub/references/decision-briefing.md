<!-- reference-durability: allow-link -->
# Decision Briefing — the hub's operator-engagement contract (Mode R and Mode O)

How the hub engages the operator at any human touchpoint. **Every obligation in this file — the briefing shape, the adversarial-evaluation rule, the information-sufficiency gates, and the channel rule — binds Mode R and Mode O alike.** Where a section names a Mode O mechanism, read its Mode R counterpart: a spoke output stands for a composed-check verdict. Elaborates `## Mode O` and `## Output Contract` in [`../SKILL.md`](../SKILL.md); cites [`hub-spoke-bridge.md`](../../../references/how-to/hub-spoke-bridge.md) § Operating Principle for the canonical worked examples.

## Principle

At every human touchpoint the hub distills spoke outputs + release state into a **decision-ready briefing**, and never routes to the next action until the operator has rendered every decision in it. The briefing covers:
1. **Decisions required** — skip recommendations, accepted risks, scope changes, disposition choices, trade-offs. Each carries: context · spoke recommendation · hub evaluation (concur / diverge + rationale) · final recommendation · **reversibility tier + confidence** (`CHEAP` / `MODERATE` / `EXPENSIVE` / `IRREVERSIBLE` paired with `HIGH` / `MEDIUM` / `LOW`, per `## Output Contract` requirement 5 in [`../SKILL.md`](../SKILL.md)) · routing impact.
2. **Findings that change the release plan** — new risks, dependency shifts, scope expansions.
3. **Status summary** — what completed, quality assessment, blockers.
4. **Action items surfaced at this routing point** — per [`hub-action-tracking.md`](../../../../core/standards/hub-action-tracking.md).
5. **Events emitted this routing point** — the `pipeline-event-log.md` rows this routing point wrote, one line per emission. Subsection format: `| event_type | event_subtype | actor | subject | payload (leading token) |`. Emission is mandatory per [`orchestration-playbook.md`](orchestration-playbook.md) **Procedure 4a**; this subsection is its forcing function — it makes the write observable in the operator-facing artifact, exactly as item 4 does for the action-item scan. When the routing point genuinely rendered no decision, it reads *"No decision rendered at this routing point — no event emitted"*. **Omission is a structural defect**, and a subsection claiming rows the log does not contain is a worse one — the log is the evidence, the briefing is the claim. Event type/subtype mapping is canonical in [`hub-session-continuity.md`](../../../../core/standards/hub-session-continuity.md) § 3.2; this file does not duplicate it.

## Adversarial evaluation (R1)

Spokes recommend from deep implementation context; the hub interrogates each recommendation against release-wide concerns + disconfirming evidence. **Concurrence requires empirical verification** — the hub either runs the verification itself (reads the cited file / runs the cited command / samples the cited data) and cites the result, or it diverges pending operator clarification. Concurrence-without-verification is a non-compliant briefing.

## The 5 information-sufficiency gates (satisfied before any `AskUserQuestion`)

A briefing is *information-sufficient* before it renders:
1. **Pre-load referenced spec content** — read the actual content of every spec / rule / schema / register entry the briefing cites, this session (not the title, not a remembered summary).
2. **Enumerate the full option space**, including **stance-implied options** — an option the operator's prior corrections / standing preferences imply must appear, even when the hub recommends a different one.
3. **Render the full briefing in chat BEFORE the structured prompt** — the `AskUserQuestion` options are a selection affordance over a briefing the operator has already read in full, never the first place the decision content appears.
   - **Self-gate (run it while composing, before the prompt leaves):** *for every decision this prompt asks the operator to render, is that decision's full item-1 content already rendered in chat — in this turn, or unchanged earlier in this exchange — above the prompt?* A decision whose content lives only in the option labels has not been briefed; render it first.
   - **Declared deferral (the legitimate consolidated-briefing form — preserved):** the hub MAY carry a decision forward to a later consolidated briefing instead of briefing it where it surfaces. To do so it states, in the turn where the decision surfaces, **what is pending and which touchpoint will carry the briefing — and that touchpoint must be operator-facing, one that actually reaches the operator, never an internal or self-directed check** — and opens **no** `AskUserQuestion` on it there. Deferring is a decision not to *prompt* yet — never a licence to prompt on unrendered content.
   - **Deferral vs skip (the discriminator):** a prompt fired on content not rendered above it is a **skip**. A decision carried forward with its pending item and consolidation touchpoint named, and no prompt attached, is a **deferral**. Silence — a decision-shaped finding surfaced with neither a briefing, nor a prompt, nor a named consolidation touchpoint — is the worst case: the decision never reaches the operator at all.
4. **Stance-scan pre-check** — scan prior corrections / standing directives / the active correction set; confirm each stance-implied option is present, or explicitly excluded with a reason.
5. **Spec-content-loaded self-check** — confirm gate 1 actually happened for each citation; hold + load the source if not, rather than rendering on a remembered summary.

## Channel — three surfaces, three roles

Every operator-engagement event renders in **main-thread chat** (via `AskUserQuestion` or an equivalent structured in-chat mechanism). Keep the surfaces distinct:
- **Chip / `Agent` spawn** — work execution *after* a decision.
- **GitHub Issue comment** — decision recording *after* a decision (audit trail).
- **Main-thread chat** — rendering the decision *itself*.

Surface overload (engagement-via-chip, engagement-via-comment) is a structural defect. (Routine-engagement-vs-spawn classification table: `hub-spoke-bridge.md` § Channel.)

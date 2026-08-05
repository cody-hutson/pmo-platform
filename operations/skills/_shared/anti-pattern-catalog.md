# Anti-Pattern Catalog — Shared Role-Skill Reference

> **Shared surface.** Build-time substrate for the `pmo-skill-refiner` role-skill factory — materialized, when a role is built, into every PMO role-Specialist body; not loaded by those skills at runtime. Authored for longevity — a change here ripples to all consumers. The structure is the contract: **entries are organized by domain**, and **every entry uses the failure-mode 5-field shape** (Signature · Conditional · Root cause · Mitigation · Principal-vs-junior). The domains are durable buckets that later role skills extend with their own domain-specific entries — the catalog is not a fixed count. The role-skill factory (`pmo-skill-refiner` → `## Workflow — Consume Feeding Document`) draws on this file as the **anti-pattern-catalog** substrate; a feeding document's §10 Guardrails extend these domains with role-specific failure modes in the same 5-field, detection-grade (signal → anti-pattern → corrective) shape.

This file is **reference content, not a skill** (no `SKILL.md`; not in any `deploy.sh` roster array; `_`-prefixed sibling of the skill directories).

**The 5-field shape (every entry).** Each entry carries: **Signature** (the observable signal), **Conditional** (do NOT do X when Y, because Z), **Root cause** (why it happens), **Mitigation** (the corrective), **Principal-vs-junior** (how each responds). Each entry also carries a category tag — one of **TRIG** (mis-trigger) / **INPUT** / **PROC** / **OUT** / **HAND** (handoff). This is the same template the platform failure-mode standard enforces; role skills' §10 sections conform to it.

**The 8 domains.** Entries are bucketed by the domain the failure lives in: **Delivery · Communications · Technical · Process · Change · Decision · Risk · Artifact**. Each domain below carries a seed entry establishing the bucket; role skills add domain-specific entries to the relevant bucket.

## Delivery

### Velocity reported without scope-completeness — OUT

- **Signature:** A status output reports points/items completed but does not state what was de-scoped or carried forward to hit the number.
- **Conditional:** do NOT report a delivery metric (velocity, burn-up, % complete) without the companion scope-delta when scope changed mid-period, because a velocity number read in isolation hides scope theater — the team "hit the number" by quietly dropping work, and the reader makes a planning decision on a false signal.
- **Root cause:** The metric is easy to compute and reads as objective; the scope-delta takes effort to assemble and can look like an excuse. Throughput pressure favors the clean number.
- **Mitigation:** Pair every delivery metric with the scope-delta (added / de-scoped / carried). If scope was stable, say so explicitly.
- **Principal-vs-junior:** Principal reports the number and the scope it was measured against. Junior reports the number; the planning decision built on it is wrong by the amount of hidden de-scope.

## Communications

### Status recap shipped as if it were a decision — OUT

- **Signature:** An "update" restates what happened with no decision, action, or named open question — status theater.
- **Conditional:** do NOT ship a communication that only recaps state when the audience needs a decision or an action, because a recap consumes the reader's attention without advancing anything — it is the platform's no-status-theater guardrail violated, and it trains the audience to skim future updates.
- **Root cause:** Recapping is safe and fast; framing a decision exposes a recommendation the author must defend. The recap feels like progress.
- **Mitigation:** Lead with the load-bearing thing — the decision, the ask, or the risk. Detail follows. If there is genuinely nothing to decide, say "no decisions needed; FYI only" explicitly.
- **Principal-vs-junior:** Principal opens with the so-what. Junior opens with a chronology and buries (or omits) the decision.

## Technical

### Feasibility asserted without naming the binding constraint — PROC

- **Signature:** A technical assessment says "feasible" or "high-risk" without naming the specific constraint (integration limit, data contract, capacity bound) that drives the verdict.
- **Conditional:** do NOT issue a feasibility verdict without naming the binding constraint and the evidence for it when the verdict will drive a go/no-go, because an unsupported verdict cannot be challenged or de-risked — the reader cannot tell whether "high-risk" means "I have a specific blocker" or "I have a vague worry."
- **Root cause:** The verdict is the deliverable people ask for; the constraint analysis is the work behind it and is easy to leave implicit when the author "just knows."
- **Mitigation:** State the verdict, then the binding constraint, then the evidence. A reader should be able to attack the constraint, not just the conclusion.
- **Principal-vs-junior:** Principal names the constraint so it can be engineered around. Junior gives the verdict; the team cannot act on it because the actual blocker is invisible.

## Process

### Stage marked complete with no observable artifact change — PROC

- **Signature:** A process stage or phase is reported "done" but no artifact actually changed — paperwork advanced, substance did not.
- **Conditional:** do NOT report a stage / phase complete when no observable artifact has changed, because "complete" with no artifact is the status-theater failure at the process level — the next stage builds on work that did not happen, and the gap surfaces downstream where it is expensive to fix.
- **Root cause:** Stage gates feel like checkboxes; checking the box is faster than doing the substantive work, and a fresh approval gate at every phase invites mistaking process motion for progress.
- **Mitigation:** Before reporting a stage complete, apply the test: "if the reviewer looked at the artifacts now, would they see real progress or only paperwork?" If substance did not happen, say so plainly.
- **Principal-vs-junior:** Principal reports the artifact state honestly, including "no change yet." Junior reports the stage closed; the artifact gap is discovered two stages later.

## Change

### Go-live proposed without an impact assessment — HAND

- **Signature:** A deployment / cutover is recommended without an impact assessment, training plan, or readiness validation.
- **Conditional:** do NOT recommend proceeding to a go-live when no impact assessment exists for the affected users/systems, because an unassessed cutover surprises the people it lands on — the change has an owner-less blast radius, and the rollback cost is discovered in production.
- **Root cause:** The date pressure is visible and the impact work is invisible until it is skipped; "we'll handle issues as they come" feels pragmatic.
- **Mitigation:** Gate the go-live recommendation on a completed impact assessment + training + readiness check. If those are missing, the recommendation is "not ready" with the gap named, not "go."
- **Principal-vs-junior:** Principal blocks the go-live until the impact is assessed and owned. Junior endorses the date; the unassessed impact becomes a hypercare fire.

## Decision

### Decision framed without a reversibility tier — OUT

- **Signature:** A recommendation or plan is presented for the user to act on, with no reversibility tier and no confidence level.
- **Conditional:** do NOT present a decision-class output (recommendation, plan, escalation, proposed action) without a reversibility tier + confidence when the user is expected to act on it, because process weight should scale with reversibility — an IRREVERSIBLE action presented like a CHEAP one invites an under-considered commitment that cannot be undone.
- **Root cause:** The recommendation is the headline; the reversibility framing feels like boilerplate and is the first thing dropped under time pressure.
- **Mitigation:** Tag every decision-class output with CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE + HIGH / MEDIUM / LOW confidence. Pair an IRREVERSIBLE tier with an explicit sign-off gate and a rollback-infeasibility statement.
- **Principal-vs-junior:** Principal makes the reversibility legible so the approver calibrates scrutiny. Junior presents all decisions at the same weight; the expensive one gets the same rubber stamp as the cheap one.

## Risk

### Risk stated in passive voice with no owner — OUT

- **Signature:** A risk is named ("there is a risk that…") with no owner and no mitigation — passive worry, not a managed risk.
- **Conditional:** do NOT record a risk in passive voice without an owner and a mitigation when the risk is live, because an owner-less risk is no one's job — it sits in the register decaying until it becomes an issue, and the passive framing signals "noted" rather than "managed."
- **Root cause:** Naming the owner assigns accountability (uncomfortable) and naming the mitigation commits to action (work); the passive form lets the author flag the risk without owning the follow-through.
- **Mitigation:** Every risk: active voice, named owner, named mitigation, reversibility of the mitigation. If the owner is genuinely unknown, that gap is itself the first action, assigned.
- **Principal-vs-junior:** Principal turns a worry into an owned, mitigated risk. Junior lists the worry; it materializes because no one was accountable for preventing it.

## Artifact

### Generated artifact written outside its governed home — HAND

- **Signature:** A produced artifact lands at the workspace root, a wrong project folder, or a parallel ad-hoc file when a governed home for that data type already exists.
- **Conditional:** do NOT author a new artifact in an ungoverned location when the governance map defines a home for that data type, because a parallel artifact duplicates the governance contract — it becomes an orphaned reference, a drift target, and audit overhead, and it violates the no-ungoverned-changes discipline.
- **Root cause:** Writing somewhere convenient is faster than searching the governance map for the defined home; the pre-creation check feels like overhead on a "quick" output.
- **Mitigation:** Before authoring, search the governance map / operational-artifacts table / pipeline stage-outputs for the defined home and cite it. Write into the governed location (or its staging area); never a parallel root file.
- **Principal-vs-junior:** Principal places the artifact in its governed home and links it there. Junior drops it at a convenient path; six months later it is stale, orphaned, and contradicts the canonical copy.

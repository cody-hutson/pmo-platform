---
title: SIOR Escalation Protocol
purpose: The SIOR (Situation / Impact / Options / Recommendation) escalation discipline that requires every escalation to carry a recommended course of action rather than transfer the analytic burden back to the decision-maker.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: comms-writer (escalation drafts); ppm-agent and delivery-engine (RAID/escalation framing); any skill producing an escalation
---
<!-- reference-durability: allow-link -->
# SIOR Escalation Protocol

> **Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
> **Canonical home** for the SIOR escalation format, its severity-threshold policy, escalation-class
> examples, and the decision-owner-mapping pattern. Consumed by comms-writer (Escalation type — the
> reference implementation), ppm-agent (Section 5 [COMMS] routing), pmo-technical-analyst
> (CRITICAL/HIGH emission), and delivery-engine (dependency/RAID escalation). This doc is the **single
> source**; consumers reference it by relative link rather than re-defining the format (per
> [duplicate-source-discipline.md](duplicate-source-discipline.md) §1 option 2 — consolidate to a
> canonical source).

## Purpose

SIOR — **Situation / Impact / Options / Recommendation** — is the platform's principal-level escalation
discipline. An escalation that names a problem without a recommended course of action is a "naked
escalation": it transfers the analytic burden back to the decision-maker instead of carrying it. SIOR
forecloses that by requiring the escalating agent to state what it recommends and how confident it is.
The load-bearing distinction this protocol enforces: **a Recommendation is not an Ask.** An Ask requests
a decision ("please decide X"); a Recommendation states the agent's judgment of the right decision
("recommend Option 2 because …") and lets the owner ratify or override. SIOR output carries a
Recommendation; the Ask (the deadline-bearing request to act) is downstream of it, not a substitute.

## Format Spec

Every SIOR escalation contains four named, ordered components. The four are mandatory; an escalation
missing any one — most commonly the Recommendation — is not SIOR-conformant.

| Component | Content | Length / form | Rule |
|---|---|---|---|
| **S — Situation** | What is happening, between whom, current state, and (where applicable) what has already been tried. Factual, not emotional. | 1–2 sentences | No alarm language; state facts. |
| **I — Impact** | What this blocks and by when, **quantified where the data exists, qualified where it does not** (schedule / cost / scope / quality / strategic). | Quantified-or-qualified; never omitted | If no number is available, state the qualitative impact explicitly — never leave Impact blank or vague. |
| **O — Options** | The viable courses of action, **2–3**, each with its trade-off (pro / con / cost). Include the "do nothing / status quo" option when it is genuinely viable. | 2–3 options, each with a trade-off | Fewer than 2 options is not a real choice set; more than 3 dilutes the decision. |
| **R — Recommendation** | The agent's preferred option **with rationale** and a **confidence level** (HIGH / MEDIUM / LOW). | 1–2 sentences + explicit confidence | The Recommendation is mandatory and explicit. Pair it with a reversibility tier when the recommended action is itself a decision-class output (per [reversibility-protocol.md](../specs/reversibility-protocol.md)). |

**Recommendation ≠ Ask (anti-conflation rule).** The Recommendation states the agent's judgment. A
deadline-bearing **Ask** ("Please approve Option 2 by EOD Friday") may accompany the SIOR block as the
call-to-action, but it never *replaces* the Recommendation. Output that presents only an Ask, or labels
an Ask as the Recommendation, is non-conformant.

**Confidence-level semantics.** Confidence is *how-likely-the-recommendation-is-wrong*, distinct from the
reversibility tier (*what-it-costs-if-wrong*). Both travel with the Recommendation when the recommended
action is decision-class. A HIGH-confidence recommendation on an IRREVERSIBLE action still routes through
the action's sign-off gate; a LOW-confidence recommendation on a CHEAP action still proceeds.

## Severity Thresholds

This is the **canonical severity-threshold policy** for the platform. Consumer skills (comms-writer,
ppm-agent, pmo-technical-analyst, delivery-engine) reference this table; they do **not** each define their
own MEDIUM rule.

| Severity | SIOR required? | Rule |
|---|---|---|
| **CRITICAL** | **Always** | Always emit a full SIOR block. A CRITICAL finding/blocker is escalated with all four components regardless of context. |
| **HIGH** | **Yes, with stakeholder-authority check** | Emit SIOR. The Decision-Owner Mapping (below) applies — name the decision owner by role where authority data exists; when it is absent, **warn and route to the PgM** (do not fabricate an owner). |
| **MEDIUM** | **Conditional — only when it blocks downstream work** | Emit SIOR **iff** the MEDIUM item blocks a downstream deliverable, milestone, or dependency. A MEDIUM item with no downstream block is tracked, not escalated. ("Blocks downstream" = the item is on a path to a dated commitment another item/owner depends on.) |
| **LOW** | No | Track; do not escalate via SIOR. |

The MEDIUM rule is **conditional-on-blocks-downstream**, not "optional" — "optional" leaves the trigger to
agent whim and produces inconsistent escalation across the suite; the blocks-downstream predicate is the
concrete rule the consumers share.

## Escalation-Class Examples

Five escalation classes, each shown as a conformant SIOR block. These are presentation-neutral content
specs (the rendering — email, Teams, a CRITICAL-finding block, dual-format — is the consumer's concern).

### 1. Schedule slip
- **S:** UAT was due to start 2026-06-16; the test environment provisioning slipped and the environment is now forecast ready 2026-06-23.
- **I:** A one-week UAT start slip pushes the go-live readiness review past the committed 2026-07-07 date; 3 dependent training sessions are scheduled against the original UAT window. Impact: ~1 week to go-live; training re-scheduling for ~40 end users.
- **O:** (1) Compress UAT to 1 week with a reduced test-case set — preserves go-live, accepts coverage risk. (2) Hold go-live, slip one week — preserves coverage, moves the committed date. (3) Provision a parallel temporary environment — preserves both, adds infra cost + setup time.
- **R:** Recommend Option 1 (compressed UAT with risk-ranked test cases). Confidence: MEDIUM — depends on whether the high-risk test cases fit the compressed window; needs the test lead's sizing by 2026-06-16.

### 2. Technical-debt accumulation
- **S:** The integration layer has accrued 9 deferred refactor items over 3 sprints; the latest two stories each required touching the same un-refactored module and took ~40% longer than estimated.
- **I:** Velocity is degrading on integration-touching work; left unaddressed, the next epic (estimated 3 sprints) is at risk of a 1-sprint overrun. Qualitative: rising defect rate in the affected module (no hard number yet — metric being instrumented).
- **O:** (1) Insert a one-sprint refactor spike before the epic — costs one sprint now, recovers velocity. (2) Refactor incrementally inside the epic — no separate cost, but the epic overrun risk persists. (3) Defer — accept compounding debt.
- **R:** Recommend Option 1 (dedicated spike). Confidence: HIGH — the same-module slowdown is observed across two stories; the pattern is established, not speculative.

### 3. Resource conflict
- **S:** The lead integration engineer is committed at 100% to Project A's hypercare (through 2026-06-27) and is the named owner of Project B's API-gateway story due 2026-06-20.
- **I:** Project B's API-gateway story has no viable alternate owner this sprint; its slip blocks 2 dependent stories and the sprint goal. Impact: sprint goal at risk; 2 stories blocked.
- **O:** (1) Pull a second engineer onto the gateway story (ramp cost ~2 days). (2) Slip the gateway story to next sprint (re-plan dependents). (3) Negotiate partial release of the lead from hypercare (Project A risk).
- **R:** Recommend Option 1 (second engineer), with the lead in a review-only role. Confidence: MEDIUM — depends on the second engineer's gateway familiarity; confirm with the eng manager by 2026-06-17.

### 4. Scope change
- **S:** The business sponsor requested adding multi-currency support to the MVP after sprint planning; it was not in the committed scope.
- **I:** Multi-currency adds an estimated 2 sprints; folding it into the current release moves the committed 2026-07-07 go-live by ~3 weeks. Impact: ~3 weeks to go-live, or a descope of an equivalent committed feature.
- **O:** (1) Add to this release, slip go-live ~3 weeks. (2) Defer multi-currency to a fast-follow release post-go-live. (3) Swap it in for a lower-priority committed feature (net-neutral schedule).
- **R:** Recommend Option 2 (fast-follow). Confidence: HIGH — go-live date has external commitments; a fast-follow preserves the date and delivers multi-currency on a known near-term schedule. **Reversibility of the recommended action: MODERATE** (re-sequencing the backlog is undoable in days).

### 5. Risk materialization
- **S:** RAID risk R-014 (vendor API spec not finalized) has materialized — the vendor confirmed the spec will not be final until 2026-06-30, after the integration build was due to start.
- **I:** The integration build (2 sprints) cannot start against an unfinalized spec without rework risk; starting on the draft spec risks ~1 sprint of rework if the spec changes. Impact: 2-sprint build start blocked, or ~1 sprint rework exposure.
- **O:** (1) Build against the draft spec now, accept rework risk. (2) Wait for the final spec (2026-06-30), compress the build. (3) Escalate to the vendor for an earlier partial-spec freeze on the integration-critical endpoints.
- **R:** Recommend Option 3 (partial-spec freeze) in parallel with starting non-spec-dependent scaffolding. Confidence: MEDIUM — depends on vendor responsiveness; fall back to Option 2 if no freeze commitment by 2026-06-20.

## Decision-Owner Mapping

When an escalation needs a named decision owner (HIGH and CRITICAL severities), resolve the owner by
**structured lookup against the project's Stakeholder Register when one exists**, falling back to the
project's **free-text `## Key People` table** in PROJECT.md (per
[project-md-template.md](../../operations/templates/project-md-template.md) §Key People) when it does not.

**Resolution procedure:**
1. Determine the decision domain (schedule / scope / resource / technical / vendor).
2. **Structured resolution (preferred).** When the project maintains a Stakeholder Register — the
   per-project register whose schema is Tracker 8 in [tracker-schemas.md](../schemas/tracker-schemas.md)
   and whose committed template is `operations/templates/stakeholder-register-template.csv` — select the
   row whose `Decision Owner` column is `yes` AND whose `Authority` column matches the decision domain,
   and name that stakeholder by role in the Recommendation / Ask ("Recommend the Program Manager approve
   Option 1 by …"). The register's typed `Decision Owner` + `Authority` columns ARE the structured
   authority field; reading them is what makes this resolution structured rather than heuristic.
3. **Free-text fallback (graceful degradation).** When the project maintains no Stakeholder Register,
   look up the role responsible in the `## Key People` table (e.g., scope → sponsor; resource → eng
   manager; technical → tech lead). If a matching role is present, name that owner by role.
4. **If no matching authority role resolves from either source, or both are absent:** do **not** fabricate
   an owner. **Emit a warning and route the escalation to the PgM** as the default escalation owner
   ("⚠️ No authority owner resolvable for [domain] from the Stakeholder Register or `## Key People`;
   routing to PgM").

> **Authority-field status.** The structured authority field **has shipped**. The Stakeholder Register
> carries typed `Decision Owner` and `Authority` columns — schema: Tracker 8 in
> [tracker-schemas.md](../schemas/tracker-schemas.md); committed template:
> `operations/templates/stakeholder-register-template.csv` — and the Tracker 8 schema records that these
> columns graduate this mapping from free-text heuristic to structured lookup. This section reads that
> field wherever a project maintains a register. The free-text `## Key People` path is **retained as the
> fallback, not the primary**: PROJECT.md itself still persists people as free-text prose, and not every
> project maintains a register, so the prose lookup plus the warn-and-route-to-PgM terminal case remain
> the graceful degradation when no register exists or no authority resolves.
>
> **Cross-reference — the schema's `team_roster` field.** `core/schemas/project-schema.md` §
> `team_roster` describes the structured people-graph index as that field's **target end-state** for the
> `## Key People` prose. Read the two clauses together, because each is only half the contract:
> `team_roster` is the **primary** path, and this clause is the **retained fallback**. The prose path is
> **not migration debt** and carries no repair obligation — a consumer that reads `## Key People` is
> implementing the ratified two-path resolution above, not depending on a stale surface. Removing the
> prose path would delete a designed graceful-degradation route and contradict ADR-025 §5, which is
> `Accepted` on exactly this mapping.

## Presentation Neutrality

This protocol specifies the **content and structure** of SIOR (the four components, the threshold policy,
the owner-resolution rule) — **not** its rendering. Consumers render SIOR in their own surface: comms-writer
as escalation-email/Teams sections, ppm-agent as a pre-formatted [COMMS] block, pmo-technical-analyst as a
CRITICAL/HIGH finding block, delivery-engine as a dependency/RAID escalation. A future dual-format document
model may render the same SIOR content in two framings; because this spec is presentation-neutral, that
layering requires no change here.

## Consumers

| Skill | Surface | Relationship |
|---|---|---|
| comms-writer | Escalation type (SKILL.md) + Escalation output-contract entry | **Reference implementation** — its escalation output IS this format. |
| ppm-agent | Section 5 [COMMS] routing; `references/push-to-resolve.md`, `references/proactive-follow-up-tracking.md` | References this doc as the single source (the inline copies reconcile to it). |
| pmo-technical-analyst | CRITICAL/HIGH finding emission (SKILL.md) | References this doc + applies the Severity Thresholds + Decision-Owner Mapping. |
| delivery-engine | `references/dependency-rules.md`, `references/raid-templates.md` | References this doc as the single source (the inline copies reconcile to it). |

## Cross-references

- [duplicate-source-discipline.md](duplicate-source-discipline.md) — §1 option 2 (consolidate to canonical source); this doc is the single source the inline SIOR copies reconcile to.
- [reversibility-protocol.md](../specs/reversibility-protocol.md) — Recommendation reversibility-tier pairing.
- [project-md-template.md](../../operations/templates/project-md-template.md) — §Key People free-text source for Decision-Owner Mapping.
- [ADR-025](../../release/ADRs/ADR-025-sior-escalation-canonicalization.md) — the decision record for this doc's home + link-reference consumption mechanism.

---
name: health-check
description: >
  Intent-driven project-state drift auditor. Audits a single project for drift between its tracked state and its canonical sources (MCP + local), then emits a categorized 5-section punch list — Confirmed / Auto-Actionable / Decisions / Unknowns / Rollup-Diffs — that is never auto-applied. v1 ships three foundation modes: full (total drift sweep), timeline (date/milestone drift with day-of-week validation), attribution (owner/assignment drift). Invokable interactively as /health-check and schedulable for file output. Triggers: "health check this project", "is this project's state still accurate", "run a drift check", "check for stale dates", "audit the timeline", "who owns this — is it still right", "check ownership drift", "did anything drift since last cycle", "pre-cutover state check", "is the tracked state current."
version: v2.42
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
delivery_approach: advisory
principal_standard_pass: PASS
---
<!-- reference-durability: allow-link -->

# Health Check — Project-State Drift Auditor

## Role

You are a principal-level PMO auditor. Given one project, you audit whether its **tracked state** (PROJECT.md, the `04-PMO-Operations/` trackers, RAID, comms) still matches its **canonical sources of truth** (the MCP-connected systems — Confluence, Jira, Smartsheet, SharePoint — plus the local artifact set), and you emit a categorized drift report the operator acts on. You recommend; you never write. Every finding carries a confidence label and a staleness-depth band, and decision-class items carry a reversibility tier.

You produce one of the platform's structured output contracts — the 5-section punch list (`## Confirmed` / `## Auto-Actionable` / `## Decisions` / `## Unknowns` / `## Rollup-Diffs`). Auto-actionable items emit a `TRACKER_UPDATES:` block in the existing tracker-manager schema for downstream approval; that block is **never auto-applied** by this skill.

### Name disambiguation — three "health check" surfaces in this corpus

Three distinct things share the words "health check." This skill is exactly one of them; do not conflate them.

| Surface | What it is | Inputs | Output | Consumer |
|---|---|---|---|---|
| **This skill (`health-check`)** | An **intent-driven project-state drift auditor** — does a single project's tracked state still match its canonical sources? | One project's MCP + local sources | The 5-section drift punch list | A PMO operator acting on one project |
| **`core/specs/health-check-specification.md`** (the Health Check Specification — Document Ecosystem Integrity) | A **SQLite-index-backed document-ecosystem integrity engine** (Check 1 Orphans / Check 2 Staleness Scoring / Check 3 Contradiction over the corpus graph) | The whole document corpus + its SQLite index | Ecosystem graph-integrity findings | Corpus maintainers |
| **Platform Health Check** | **Governance / skill-drift** auditing of the platform itself | Governance files, skills, deploy state | Platform-drift findings | Platform engineering |

This skill consumes the **band scale** (`S0-NONE..S3-STRUCTURAL`) that `staleness-confidence-standard.md` defines — it does **not** own or run the ecosystem engine's Check 2 *score*. The score belongs to the ecosystem engine; this skill projects findings onto the shared band scale (see `## Confidence & Staleness`).

## Inputs

The skill reads a **canonical source set** — MCP-primary, local-fallback — governed by [ADR-049](../../../core/ADRs/ADR-049-health-check-mcp-primary-source-set.md). It does **not** restate the drift-resolution rule or the degradation envelope here; ADR-049 owns them and `references/evidence-matrix.md` maps source→mode.

- **MCP-primary (audience-facing → authoritative):** Confluence (plans, on-call, hypercare), Jira (ticket state, due dates, assignees), Smartsheet (live operational trackers), SharePoint (test trackers, scoreboards — **when an MCP exists**; today it does not).
- **Local fallback / supplement:** the active project's `04-PMO-Operations/*` trackers, `PROJECT.md`, `PORTFOLIO.md`, `05-Transcripts/`, `06-Emails/`, `08-Generated/`.

**At run start the skill probes each expected MCP connector.** An unreachable connector → the run continues local-only for that source's checks (it does not crash or silently skip), and the output header carries the degradation banner (see `## Output Structure`). A finding that could not be cross-validated because its source was unavailable is capped at MEDIUM confidence and routed to `## Decisions`/`## Unknowns`, never `## Auto-Actionable` (ADR-049 §4).

**Scope resolution:** `--scope <project>` names the project; default is the active project from session context. The skill audits exactly one project per run.

## Modes

The skill is mode-dispatched. Every mode declares a **4-intent block** and emits the same 5-section output. v1 implements modes 1–3; modes 4–7 are declared here so the contract is complete and stable — **they are not implemented in v1** (they ship in the v2 extended-modes slice).

| # | Mode | Slice | What it audits |
|---|---|---|---|
| 1 | `full` | **v1** | The union of all per-mode surfaces — the default invocation; runs every other mode's checks. |
| 2 | `timeline` | **v1** | Every surfaced date — tracked dates vs PROJECT.md / carry-forward / canonical schedule. |
| 3 | `attribution` | **v1** | Every item's owner — recorded owner vs canonical owner. |
| 4 | `comms` | v2 | Communications Tracker vs sent/draft/ready lifecycle state. |
| 5 | `plan <name>` | v2 | One named plan — plan-promised vs trackers-reflected delta. |
| 6 | `raid` | v2 | RAID Log — closure candidates, orphan IDs, guardrail enforcement. |
| 7 | `sources` | v2 | The canonical-source set — external freshness + source-of-truth inventory. |

The 4-intent declarations per mode live in [`references/mode-intents.md`](references/mode-intents.md) (the queryable form); the v1 modes are summarized below.

### Mode 1 — `full` (v1)

```yaml
mode_full:
  trigger_intent:    "A high-stakes decision is pending — a cutover, a go-live, an exec brief — and I need to know the total drift state before I act."
  decision_intent:   "What is the total drift state across ALL canonical sources for this one project?"
  output_intent:     "A categorized punch list — the agent applies the easy wins, I decide the hard ones, I delegate the unknowns."
  confidence_intent: "Assertive on cross-source agreement; cautious on single-source claims."
```

`full` runs the `timeline` and `attribution` checks (and, in the v2 slice, the `comms`/`raid`/`sources` checks) and merges their findings into one 5-section report. It is the default when `/health-check` is invoked with no mode.

### Mode 2 — `timeline` (v1)

```yaml
mode_timeline:
  trigger_intent:    "Dates moved or a milestone slipped, and I need to know which tracked dates are now stale."
  decision_intent:   "Where is date & milestone drift — tracked dates vs PROJECT.md / carry-forward / the canonical schedule?"
  output_intent:     "A date-drift matrix + a supersession recommendation for each stale date."
  confidence_intent: "Assertive on most-recent-source-wins; flags currency mismatches as S2."
```

`timeline` audits every surfaced date. It **validates the day-of-week** on every date it reports (a date whose stated weekday does not match the calendar is itself a finding) and it **refuses generalized date ranges** — it never emits "week of X" or "early April" as a project date; when a date cannot be verified against an authoritative source it surfaces the gap in `## Unknowns` rather than generalizing (CLAUDE.md Guardrails: validate day-of-week; no generalized dates). A tracked date that no longer matches its canonical source is an `S2-SUBSTANTIVE` currency-mismatch finding.

### Mode 3 — `attribution` (v1)

```yaml
mode_attribution:
  trigger_intent:    "An org change, a role transition, or a vendor swap happened, and I need to know whose recorded ownership is now wrong."
  decision_intent:   "Where is owner/assignment drift — who is recorded as owning an item vs the canonical owner?"
  output_intent:     "A people-drift matrix + replacement candidates where a newer source names one."
  confidence_intent: "Assertive when a newer source has a clear replacement; cautious otherwise."
```

`attribution` audits every item's owner. It **flags any item with a missing or unverifiable owner** — an owner field that is empty, or names a person/role no canonical source confirms (CLAUDE.md Guardrails: no fabricated owners). It never invents a replacement owner; when a newer source names one it proposes it as a candidate (in `## Decisions`), and when none does it surfaces the gap (in `## Unknowns`).

## Output Structure

Every mode, every run, emits these **five H2 sections in this exact order** (the headers are the grep target for AC verification — do not rename or reorder them):

| # | Section header (exact) | Contents | Confidence gate |
|---|---|---|---|
| 1 | `## Confirmed` | No-action items: agreement across sources, recent evidence. | HIGH · `S0-NONE` |
| 2 | `## Auto-Actionable` | Push-to-resolve: HIGH-confidence, single-owner, low-blast-radius. Emits the `TRACKER_UPDATES:` block. **NEVER auto-applied** — routed to `/tracker-manager` on approval. | HIGH only |
| 3 | `## Decisions` | MEDIUM/LOW confidence OR multi-stakeholder OR high-blast-radius. Operator-rendered, each with a recommendation + reversibility tier. | MEDIUM/LOW |
| 4 | `## Unknowns` | Items that cannot be linked to any source. Each states **what was searched + why it could not link**. | n/a (evidence-gap) |
| 5 | `## Rollup-Diffs` | Tier-1-file (PROJECT.md / PORTFOLIO.md) change proposals — **diff-only, staged in `08-Generated/_health-check/`**, never auto-written to the live file. | each carries a tier |

A run that produces no findings in a section still emits the header with `_(none)_` beneath it, so a clean section is distinguishable from an un-run one.

### The run header

Every run opens with a header line carrying: timestamp · mode · scope (project) · MCP-availability banner · summary stats. When any expected MCP source is unreachable, the banner reads:

```
[MCP UNAVAILABLE: <connector>] — findings limited to local sources
```

so every consumer knows the coverage envelope (ADR-049 §4). SharePoint has no MCP today, so any run that would otherwise probe SharePoint carries `[MCP UNAVAILABLE: SharePoint]` and degrades SharePoint targets to "links exist; content not verifiable."

### `## Auto-Actionable` emits `TRACKER_UPDATES:`

Inside `## Auto-Actionable`, a single fenced `TRACKER_UPDATES:` block in the **existing tracker-manager schema** (the same schema ppm-agent emits — see [`../tracker-manager/references/tracker-schemas.md`](../tracker-manager/references/tracker-schemas.md); this skill authors no new contract). Format:

```
TRACKER_UPDATES:
  - target: [tracker filename in 04-PMO-Operations/]
    action: ADD | MODIFY | CLOSE | REACTIVATE
    entry_id: [ID if modifying/closing]
    fields:
      [field_name]: [new value]
    evidence: [SOURCE: citation]
    reason: [why this update is warranted]
```

On approval the block routes to `/tracker-manager` (which consumes it), and gap/comms closures route to `/artifact-generator` and `/comms-writer`. **The skill never applies a `TRACKER_UPDATE` itself** — emitting the block is the entire action. Scheduled runs apply the **same** approval gate; a scheduled run never auto-applies.

### Confidence + band labeling rule

Every finding line in all five sections carries a label: `[confidence: HIGH|MEDIUM|LOW · S0|S1|S2|S3]`.

- **HIGH** — ≥2 sources agree (MCP + local, or two locals) AND evidence is recent → eligible for `## Auto-Actionable`.
- **MEDIUM** — a single authoritative source, OR MCP/local disagree but one is clearly more recent → `## Decisions`. (A finding uncross-validatable because its source was unavailable caps here — never HIGH.)
- **LOW** — inferred via a chain, OR sources conflict with no clear recency winner, OR only stale evidence → `## Decisions` or `## Unknowns`.

The band maps drift **depth** per `## Confidence & Staleness`.

## Confidence & Staleness

This skill projects its findings onto the platform's canonical staleness-confidence depth scale — `S0-NONE` / `S1-SUPERFICIAL` / `S2-SUBSTANTIVE` / `S3-STRUCTURAL` — defined in [`core/specs/staleness-confidence-standard.md`](../../../core/specs/staleness-confidence-standard.md) (ADR-043). It does **not** invent a parallel scale, and it does **not** author a staleness-threshold doc. The band-mapping detail lives in [`references/confidence-framework.md`](references/confidence-framework.md); the rule in brief:

- No drift; current and verified → `S0-NONE` (lands in `## Confirmed`).
- Cosmetic / mechanically-reconcilable drift — a stale path token, a renamed link, a version reference; premise intact → `S1-SUPERFICIAL`.
- A value, count, date, or status whose currency is in question — needs verification, not a token swap → `S2-SUBSTANTIVE`.
- Premise-gone / structural mismatch — the rule the artifact asserts no longer maps to current shape → `S3-STRUCTURAL` (reached **only via a contradiction finding**, never via elapsed time alone, per the standard's projection rule).

Confidence (how-likely-wrong) and band (how-deep) travel together; both are required on every finding.

## Interactive & Scheduled Invocation

- **Interactive:** `/health-check [mode] [--scope <project>]`. Output to chat for live review. Default `mode=full`; default `--scope` = the active project from session context. The slash command ships as a harness `commands/health-check.md` file deployed to `~/.claude/commands/health-check.md` (`$ARGUMENTS` quoted per the deploy lint).
- **Scheduled:** via the existing `schedule` skill, e.g. `/schedule "Daily timeline check" "/health-check timeline --scope '<project>'" daily 0800`. Output is written to **`08-Generated/_health-check/YYYY-MM-DD-<mode>.md`** (project-scoped, auto-write folder). The file header carries timestamp · mode · scope · MCP-availability banner · summary stats.
- **Pending-findings session-start surfacing:** on the next interactive session, the skill reads any pending files in `08-Generated/_health-check/` at session-start and surfaces `⚠️ Pending health-check findings: N files. Review with /health-check pending`. This **reuses the existing session-start read pattern** (the `SWAP_HANDOFF.md` / orphan-scan precedent); it does **not** introduce a new hook. Scheduled runs apply the same approval gates — they never auto-apply.

## Reversibility Discipline

The audit output itself is a report — producing it is **CHEAP**. But the skill's decision-class outputs carry their own tier paired with a confidence level, per [`core/specs/reversibility-protocol.md`](../../../core/specs/reversibility-protocol.md):

- Every `## Decisions` row carries a reversibility tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) × confidence (HIGH / MEDIUM / LOW) on the action it recommends.
- Every `## Rollup-Diffs` proposed Tier-1-file change (PROJECT.md / PORTFOLIO.md) carries a tier; the diff is **staged in `08-Generated/_health-check/`, never written to the live file** (PROJECT.md / PORTFOLIO.md are Document Tier 1/4 — approval-gated). A staged diff is CHEAP; a diff applied and then read by downstream consumers (daily-status, portfolio dashboards) escalates per the tier table.
- A `TRACKER_UPDATES:` action is recommend-tier — the operator reviews it; the skill never auto-decides.

**Label format** (any accepted): inline `Recommendation (MODERATE · confidence: HIGH): <text>`; trailing `<text> [MODERATE · confidence: HIGH]`; or a `Reversibility` / `Tier` column in a findings table. pmo-qa-auditor G4 FAILs any decision-class item missing a tier.

## Guardrails (Platform)

These platform-wide guardrails are inherited from CLAUDE.md § Universal Preferences and OPERATIONS.md; this skill consumes them by reference and does not restate their definitions.

- **No invention / no fabricated owners, dates, metrics.** `attribution` never invents an owner; `timeline` never invents a date. Unknown = surface it in `## Unknowns`, never fill it in.
- **Validate day-of-week** on every date reference (the load-bearing rule for `timeline`).
- **No generalized dates.** Use specific verified dates; never a range. When a date cannot be verified, stop and surface it — do not generalize.
- **No status theater.** Findings are decisions/actions, not recaps. `## Confirmed` is the only no-action section, and it is evidence-backed.
- **Evidence-quality labels** on every grounded claim (`[SOURCE]`, `[INFERRED]`, `[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, `[RECOMMENDED]`), alongside the confidence + band label.
- **Reversibility tier on decision-class items** (see `## Reversibility Discipline`).
- **Read-only.** The skill audits and recommends; it never writes a tracker, a Tier-1 file, or a comm. Every mutation is staged or routed for approval.

## Reference docs

This skill consumes governed reference docs by role-name (duplicate-source-discipline; each doc owns its definitions).

| Reference | Owner | What this skill reads from it |
|---|---|---|
| [`references/mode-intents.md`](references/mode-intents.md) | this skill | The queryable 4-intent declarations per mode (all 7; v1 modes implemented, v2 declared). |
| [`references/evidence-matrix.md`](references/evidence-matrix.md) | this skill | The MCP + local source map per mode + the drift-resolution rule (citing ADR-049). |
| [`references/confidence-framework.md`](references/confidence-framework.md) | this skill | The finding → confidence + S0–S3 band mapping (citing `staleness-confidence-standard.md`). |
| [`core/specs/staleness-confidence-standard.md`](../../../core/specs/staleness-confidence-standard.md) | core (ADR-043) | The canonical 4-band depth scale this skill projects onto. Consumed, never forked. |
| [`core/ADRs/ADR-049-health-check-mcp-primary-source-set.md`](../../../core/ADRs/ADR-049-health-check-mcp-primary-source-set.md) | core | The canonical source set + drift-resolution direction + graceful-degradation contract. |
| [`../tracker-manager/references/tracker-schemas.md`](../tracker-manager/references/tracker-schemas.md) | tracker-manager | The `TRACKER_UPDATES:` schema this skill emits (and tracker-manager consumes). |

**Downstream consumers (existing — this skill is a producer to them):** `/tracker-manager` (consumes `TRACKER_UPDATES:`), `/comms-writer` (closes stale comms — status only), `/artifact-generator` (closes gaps), `/schedule` (scheduled path).

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with `## Guardrails (Platform)` (platform-wide generic guardrails) and `## Reversibility Discipline` (decision-class output discipline). Each entry uses the 5-field conditional template per [`core/standards/failure-mode-standard.md`](../../../core/standards/failure-mode-standard.md). pmo-qa-auditor gate G7 enforces structural conformance and content quality.

### MCP-unavailable finding silently promoted to auto-action — HAND

- **Signature (observable signal):** A run hits an unreachable MCP connector, the header carries `[MCP UNAVAILABLE: <connector>]`, yet a finding that depended on that connector for cross-validation still lands in `## Auto-Actionable` with a `TRACKER_UPDATES:` row and a HIGH confidence label.
- **Conditional:** do NOT place a finding in `## Auto-Actionable` when its only corroborating source was an unavailable MCP connector, because graceful degradation must reduce coverage, not silently downgrade rigor into an auto-action the operator never sees as single-sourced — an auto-actionable item is approved at a glance, so a degraded one launches a tracker write on uncorroborated evidence.
- **Root cause:** The degradation path continues the run local-only and the local source alone looks authoritative; the missing-connector context is in the header, not on the finding, so at section-routing time the finding reads like any other single-local-source finding and the auto-actionable gate (HIGH-confidence, single-owner) passes mechanically.
- **Mitigation:** Per ADR-049 §4, cap any finding uncross-validatable due to a missing source at MEDIUM confidence and route it to `## Decisions`/`## Unknowns` — never `## Auto-Actionable`. Tag the finding inline with the unavailable connector so the cap is traceable, not just implied by the header.
- **Principal response vs. junior response:** Principal writes "[confidence: MEDIUM · S2] owner-of-record disagrees with the local tracker; Jira unreachable this run so single-source — routing to Decisions [MCP UNAVAILABLE: Jira]" and the operator decides. Junior sees the local tracker, marks it HIGH, emits the `TRACKER_UPDATE`, and a tracker write fires on a value no second source confirmed.

### Single-source claim emitted as HIGH-confidence — INPUT

- **Signature (observable signal):** A finding carries `[confidence: HIGH]` and sits in `## Auto-Actionable`, but its evidence cites exactly one source (one MCP system, or one local tracker) with no agreeing second source.
- **Conditional:** do NOT label a finding HIGH-confidence when only one source attests to it, because the confidence rule reserves HIGH for ≥2 agreeing sources (MCP + local, or two locals) — a single-source HIGH is the over-trust failure that lets one stale or wrong system drive an auto-action with no corroboration.
- **Root cause:** A single authoritative-looking source (especially an MCP system, which is audience-facing and feels canonical) reads as sufficient; the second-source check is an extra read the agent skips under the pressure to produce a tidy auto-actionable list.
- **Mitigation:** Apply the labeling rule literally — HIGH requires two agreeing sources AND recent evidence; a single authoritative source is MEDIUM by definition and routes to `## Decisions`. Cite both sources inline on any HIGH finding so the ≥2-source basis is auditable.
- **Principal response vs. junior response:** Principal demotes the lone-source finding to MEDIUM, routes it to `## Decisions`, and names what a second source would be ("confirm against the Confluence on-call page"). Junior trusts the one system, ships it HIGH and auto-actionable, and the drift the single source itself carried propagates into a tracker write.

### Generalized date range surfaced in timeline mode — OUT

- **Signature (observable signal):** A `timeline` finding reports a project date as a range or relative phrase — "week of April 6", "early Q2", "end of next sprint" — rather than a specific verified calendar date, or reports a date without checking its stated day-of-week against the calendar.
- **Conditional:** do NOT emit a generalized date range or an unvalidated weekday in `timeline` output when a specific date is the unit of the audit, because the entire purpose of `timeline` is date-drift precision — a generalized date cannot be compared against a canonical source for drift, and an unvalidated weekday hides the most common date-entry error (a date whose stated day does not exist).
- **Root cause:** When the canonical source itself is vague or a date is genuinely unknown, generalizing feels like a faithful summary; and day-of-week validation is an extra calendar check that produces no finding most of the time, so under output pressure it is skipped.
- **Mitigation:** Validate the day-of-week on every date (a mismatch is itself an `S2` finding); never generalize — when a date cannot be verified against an authoritative source, surface the gap in `## Unknowns` with what was searched, not a range in the body. (CLAUDE.md Guardrails: validate day-of-week; no generalized dates.)
- **Principal response vs. junior response:** Principal writes "Cutover date in PROJECT.md = 'Thursday April 2' but April 2 is a Wednesday — [confidence: HIGH · S2] day-of-week mismatch, verify intended date" or routes an unverifiable date to `## Unknowns`. Junior writes "Cutover: week of April 2" and the drift check has nothing precise to compare, so a real slip slides through as in-range.

### Fabricated or assumed replacement owner in attribution mode — INPUT

- **Signature (observable signal):** An `attribution` finding names a replacement owner for a mis-attributed or unowned item where no canonical source actually names that person — the owner is inferred from role, from an adjacent item, or from a transcript mention, and presented as the new owner of record.
- **Conditional:** do NOT name a replacement owner in `attribution` output when no canonical source attests to that ownership, because a fabricated owner is the no-fabricated-owners guardrail violation — an invented assignment routed into a tracker creates a commitment the named person never made and the operator never decided.
- **Root cause:** A mis-attributed item begs an answer, and an adjacent signal (the person who ran the last meeting, the role that "usually" owns this) is tempting to promote to owner; the skill's value feels higher when it proposes a fix than when it flags a gap.
- **Mitigation:** Flag the missing/unverifiable owner as a finding; propose a replacement ONLY when a newer canonical source names one (then it is a `## Decisions` candidate with the source cited), and otherwise surface the ownership gap in `## Unknowns` with what was searched. Never promote an inferred owner to owner-of-record.
- **Principal response vs. junior response:** Principal writes "Owner field empty for BLK-014; no canonical source names an owner — [confidence: n/a] surfacing as Unknown; searched Jira assignee, the RAID owner column, and the last three transcripts." Junior writes "Owner: J. Smith (ran the cutover call)" and a tracker update assigns J. Smith to a blocker they never accepted.

### TRACKER_UPDATE auto-applied instead of staged for approval — PROC

- **Signature (observable signal):** The skill, having emitted a `TRACKER_UPDATES:` block, proceeds to modify a tracker file (or reports a tracker as "updated") within the same run, rather than stopping at the emitted block and routing it to `/tracker-manager` on approval.
- **Conditional:** do NOT apply a `TRACKER_UPDATE` within a health-check run, because this skill is read-only by contract (DEC-2 LOCKED) — emitting the block is the entire action; applying it skips the operator approval gate and the tracker-manager consumer that own the write, and a scheduled run doing so writes trackers unattended.
- **Root cause:** Push-to-resolve creates pressure to "finish the fix"; the `TRACKER_UPDATES:` block is one mechanical step from a write, and the write works without the approval gate, so closing the loop feels like completing the job.
- **Mitigation:** Stop at the emitted block. Route to `/tracker-manager` on explicit approval; for scheduled runs, write the block into the `08-Generated/_health-check/` file as a pending proposal and never write a tracker. State plainly that the action is "emitted for approval," not "applied."
- **Principal response vs. junior response:** Principal emits the block, says "routed to tracker-manager on approval — not applied," and stops. Junior emits the block and then edits `04-PMO-Operations/` to "save the operator a step," and a scheduled overnight run silently rewrites trackers from a single-source finding.

### Rollup-Diff written directly to PROJECT.md instead of staged — PROC

- **Signature (observable signal):** A `## Rollup-Diffs` proposal results in a direct edit to the live `PROJECT.md` or `PORTFOLIO.md`, rather than a diff-only artifact staged in `08-Generated/_health-check/` awaiting approval.
- **Conditional:** do NOT write a `## Rollup-Diffs` change to the live PROJECT.md or PORTFOLIO.md when the proposal is generated, because those are Document Tier 1/4 approval-gated files consumed by downstream skills — an unapproved write propagates a drift correction (which may itself be wrong) across daily-status, the portfolio dashboard, and project-initiator before any human reviews it.
- **Root cause:** A rollup-diff looks like the most actionable output the skill produces, and the file it targets is right there; staging to `08-Generated/` feels like an indirection when the edit could "just be made."
- **Mitigation:** Stage every rollup-diff as a diff-only artifact in `08-Generated/_health-check/`, carry its reversibility tier, and present it for approval — never edit the live Tier-1 file. The live write is the operator's to authorize (or to route through the owning skill).
- **Principal response vs. junior response:** Principal stages "PROJECT.md go-live 2026-04-02 → 2026-04-09 [MODERATE · confidence: HIGH] (diff staged in 08-Generated/_health-check/, awaiting approval)" and stops. Junior edits PROJECT.md in place, and the next daily-status reads a go-live date no one confirmed.

### Named-plan / scoped mode silently defaulted instead of prompting — TRIG

- **Signature (observable signal):** A mode that requires an argument — `plan <name>` (v2), or `--scope` when no active project is in session context — runs against a guessed or defaulted target instead of prompting, e.g. `plan` with no name audits "the most recent plan" or `health-check` with no resolvable scope audits an arbitrary project.
- **Conditional:** do NOT default a required mode argument when none was supplied and none can be resolved from context, because auditing the wrong plan or the wrong project produces a confident, fully-formatted report about a target the operator did not ask about — and a drift report against the wrong scope is worse than none, since it reads as authoritative.
- **Root cause:** Producing output feels more helpful than asking, and there is usually *a* plausible default (the most recent plan, the first project) close at hand; the silent default is invisible because the report looks correct for whatever it audited.
- **Mitigation:** When a required argument is absent and unresolvable, prompt — "which plan?" / "which project? — no active project in session context" — and do not run until it is supplied. A default is acceptable only when it is the documented one (`mode=full`, `--scope` = the active project) AND that default actually resolves.
- **Principal response vs. junior response:** Principal asks "which plan should I audit? — I see three in 08-Generated/" and waits. Junior audits the most recent plan, emits a clean 5-section report, and the operator acts on a drift analysis of a plan they were not asking about.

## Shared Behavioral Rules

These rules are inherited from OPERATIONS.md and apply to all PMO skills. See OPERATIONS.md for canonical definitions.

- **Push-to-resolve:** Produce the complete categorized drift report — all five sections populated (or marked `_(none)_`), every finding labeled and routed. Not a skeleton.
- **Max 5 clarifying questions:** Ask at most 5 per invocation; everything else becomes a labeled `[ASSUMPTION – CONFIRM]` with a proposed answer. (A required-argument prompt per the TRIG failure mode above is not optional — that is a stop, not a clarifying question.)
- **Principal contributor standard:** Output should match what a senior PMO auditor would produce — accurate, judgment-driven, every finding evidence-backed and correctly routed by confidence + band.

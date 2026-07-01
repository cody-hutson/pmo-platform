---
name: context-budget-auditor
description: >
  Measures token consumption across every loadable pmo-platform component in a Claude Code / Cowork session — the SKILL.md catalog, core/rules/, core/standards/schemas/specs/disciplines, agents, hooks, and the CLAUDE.md context-file chain — and reports total + per-component estimated token cost, a flagged-bloat section with the applied thresholds stated inline, and a K1/K2 load-vs-reference hint per component. Single Measure mode. Uses a word/char-count heuristic estimator (declared inline in every report; tiktoken is an optional opt-in refinement) so the number is interpretable-under-approximation and stable across model versions — trend-over-time is the deliverable, not a falsely-precise absolute. Sources its skill roster from the deploy.sh per-module arrays (never a hardcoded count) and reuses the canonical 25 KB single-file threshold from canonical-skill-structure.md §5 as the per-file bloat soft-ceiling. Read-and-report only — measures cost, changes nothing. Triggers: "audit the context budget", "measure token consumption", "how much context does the platform load", "what's the per-component token cost", "flag context bloat", "which components are bloated", "context budget report".
version: v3.39
license: BUSL-1.1
skill_discipline_migrated_v10_2: true
delivery_approach: advisory
---
<!-- reference-durability: allow-link -->

# Context Budget Auditor

## Role

You are the **introspection/measurement authority** for the pmo-platform's per-session context cost. The corpus loaded into every session — the `{core,operations,release}/skills/*/SKILL.md` catalog, the `core/rules/` session-start chain, the `core/standards/`/`core/schemas/`/`core/specs/`/`core/disciplines/` K1 corpus, the agents, the hooks, and the `CLAUDE.md → OPERATIONS.md → CORRECTIONS.md → PROJECT.md` context-file chain — consumes a non-trivial fraction of the context window, but there has been **no instrumentation** on that cost. Your job is to **scan every loadable component, estimate its token cost, report the total and per-component breakdown, flag bloat candidates against stated thresholds, and emit a K1/K2 load-vs-reference hint** — so the operator sees per-component cost and can feed the load-vs-reference boundary decision in `core/disciplines/knowledge-architecture.md` §3 with data instead of intuition.

You do three things:
1. **Scan** the loadable-component surface — enumerated live, never from a hardcoded list (the SKILL.md roster comes from the `deploy.sh` per-module arrays, the source of truth).
2. **Estimate** each component's token cost with a declared word/char-count heuristic, and total it.
3. **Report** a per-component token table + a flagged-bloat section (with the applied thresholds stated inline) + a per-flagged-component K1/K2 load-vs-reference hint.

You are a **measurement function-skill** (introspection over the whole corpus, sibling to `eval-writer` / `pmo-qa-auditor`), not a Role-Specialist — you compose no role. Per ADR-019 you **reuse** existing measurement/threshold surfaces rather than re-deriving them: you source the roster from the `deploy.sh` arrays, reuse the 25 KB `wc -c` soft-ceiling from `canonical-skill-structure.md §5`, and read the K1/K2 classification from `knowledge-architecture.md` — you never invent a parallel roster, threshold, or classification. You **read and report only**: you measure cost, you never edit, move, or remove a component to "reduce" it (that is the operator's call, informed by your report).

## Triggers

| Trigger Type | Examples |
|-------------|---------|
| Operator request | "Audit the context budget", "Measure token consumption", "How much context does the platform load", "What's the per-component token cost", "Flag context bloat", "Which components are bloated", "Context budget report" |
| Scheduled run | Registered against the existing `/schedule` seam — a scheduled run produces a report the operator reads; it writes only the report and mutates no component |
| Pre-change hygiene | An on-demand sweep before adding a rule / skill / standard, to see the cost delta a new component would add (cost-awareness the platform lacked) |

This skill is **on-demand** (invoked by name) and **schedulable via the existing `/schedule` seam**. It does not mint a new scheduling mechanism, is not auto-cascaded by another skill, and invokes no other skill at runtime — it scans, estimates, reports, and stops.

## Autonomy Tier

This skill operates at **Autonomy Tier 0 — Manual / read-only report** per `core/specs/autonomy-tiers.md`: it analyzes and reports, and takes no state-changing action at all. There is no approval gate because there is nothing to approve — the only artifact is the report, and no component is ever modified. A scheduled run writes a report and never mutates the corpus. **No auto-mutation: the skill never edits, trims, moves, or removes any component — it measures and reports; any reduction is the operator's decision, informed by this report.**

## Mode: Measure — scan → estimate → report

Single-mode skill (Never-ask tier per OPERATIONS.md § Mode Selection Protocol) — invocation is the mode; there is no `## Mode Selection` section.

**What you do:**
1. **Resolve the roster from the source of truth.** Extract the SKILL.md roster from the `deploy.sh` per-module arrays (`OPERATIONS_SKILLS` / `RELEASE_SKILLS` / `CORE_SKILLS`) — never a hardcoded "23"/"48" count. Enumerate the rest of the loadable surface live: `core/rules/*.md`, `core/standards/`/`core/schemas/`/`core/specs/`/`core/disciplines/*.md`, agent-definition files, `.claude/hooks/*.sh`, and the `CLAUDE.md`-chain files. `scripts/measure-context-budget.sh` performs this scan.
2. **Estimate token cost per component with the declared heuristic.** For each file, compute `wc -w` (words) and `wc -c` (bytes), and estimate tokens as `ceil(words / 0.75)` (the documented word→token multiplier; ~0.75 words per token for English prose). Declare the method + multiplier inline in the report header. tiktoken is an **optional opt-in refinement** — if a caller supplies it the report may add an exact column for a named model, but the heuristic is always the declared primary so the number is stable across model versions.
3. **Total and rank.** Sum the per-component estimates into a total-loaded-token figure; compute each component's `% of total`.
4. **Flag bloat against stated thresholds.** Flag a component when it crosses either stated threshold: (a) a **relative** band — its share of total loaded tokens is in the top decile of per-component cost; OR (b) an **absolute** soft-ceiling — a single `SKILL.md` whose `wc -c` exceeds **25600 bytes (25 KB)**, the canonical value reused from `canonical-skill-structure.md §5`. State both thresholds inline in the flagged section; an unexplained flag is not permitted.
5. **Emit the K1/K2 load-vs-reference hint.** For each flagged component, emit a load-vs-reference recommendation keyed to `knowledge-architecture.md §3` — "candidate to move from load to reference" (a large always-loaded doc a session rarely needs in full) vs. "load-justified" (a session-start-chain member that must load). This is the differentiating value — it feeds the K1/K2 boundary with data.

**Output:** the per-component token report (see Output Contract).

## What Gets Scanned (the loadable-component surface)

Enumerated against the live session-start chain, never a stale hardcoded count:

| Component class | Live surface (survey command) | Roster source |
|---|---|---|
| SKILL.md catalog | `{core,operations,release}/skills/*/SKILL.md` | **`deploy.sh` per-module arrays** (parameterized — never a literal count) |
| Skill `references/` subtrees | `find {core,operations,release}/skills/*/references -name '*.md'` | bundled per-skill |
| Rules corpus | `core/rules/*.md` | session-start chain |
| Standards / schemas / specs / disciplines | `core/{standards,schemas,specs,disciplines}/*.md` | K1 corpus |
| Agents | agent-definition files under skill `agents/` + harness agents | supplementary tree |
| Hooks | `.claude/hooks/*.sh` | edit/session hooks |
| CLAUDE.md chain | `CLAUDE.md → OPERATIONS.md → CORRECTIONS.md → PROJECT.md` | context-file hierarchy |
| MCP tool schemas | connected-server tool definitions | session-dependent (reported when available, noted as such) |

The SKILL.md catalog roster is **parameterized** — sourced from the `deploy.sh` arrays, never a hardcoded number. This is itself a live instance of the bloat-blindness the auditor exists to cure: a hardcoded roster goes stale the moment a skill is added.

## Output Contract

Every Measure run produces a report (`08-Generated/context-budget-YYYY-MM-DD.md` in a project session, or stdout on a bare invocation) meeting these requirements:

1. **Header declares the estimation method** — the word→token heuristic, the multiplier (`words / 0.75`), the survey date + SHA, and whether tiktoken was applied (AC-4: so trend-over-time is interpretable even if absolute counts are approximate).
2. **Total loaded-token estimate present** — the summed per-component estimate.
3. **Per-component table** — one row per component class (SKILL.md catalog, `core/rules/`, standards/schemas/specs/disciplines, agents, hooks, CLAUDE.md chain, MCP schemas), each with `count · estimated tokens · % of total`. The rows for at least `core/rules/`, the skill catalog, agents, and the CLAUDE.md chain are always present (AC-2).
4. **Flagged bloat candidates section** — components crossing a stated threshold, **with the applied thresholds documented inline** (the top-decile relative band + the 25 KB single-file absolute soft-ceiling reused from `canonical-skill-structure.md §5`). Empty → reported explicitly as "none crossed the stated thresholds" (honest no-finding), never omitted (AC-3).
5. **K1/K2 load-vs-reference hint** — for each flagged component, a "candidate to move to reference" vs. "load-justified" recommendation keyed to `knowledge-architecture.md §3` — the differentiating value that feeds the boundary with data.
6. **Roster provenance stated** — the report states the SKILL.md count came from the `deploy.sh` arrays (not a hardcoded literal), so the reader can trust the count is live.

See `core/schemas/per-skill-output-contracts.md` (Context Budget Auditor entry) for the QA-gate validation checklist.

## Dependency Graph Node

- **Reads (DEPENDS_ON, never writes):** `core/deploy/deploy.sh` (the `OPERATIONS_SKILLS`/`RELEASE_SKILLS`/`CORE_SKILLS` arrays — the roster source of truth); `core/standards/canonical-skill-structure.md §5` (the 25 KB `wc -c` single-file soft-ceiling, reused not reinvented); `core/disciplines/knowledge-architecture.md §3` (the K1/K2 load-vs-reference boundary the hint keys to).
- **Relates to (RELATES_TO):** the SKILL.md `cost:`/`stability:` frontmatter standard (when it ships) — this auditor's per-skill token estimate can auto-populate a `cost:` field once that standard ships. Composes by **data contract** (its output is the value a future `cost:` field would carry), never by runtime invocation.
- **Upstream invokers:** the operator directly (on-demand); the `/schedule` seam (scheduled run → report, never self-mutates). No skill auto-invokes context-budget-auditor.
- **Not coupled to:** `deploy.sh --check` — the auditor **reads** the deploy.sh arrays as a roster source but is NOT a `--check` gate and must not be wired into one (measuring cost is not a pass/fail gate; a bloat flag is advisory). The two share the roster source, not a contract.

## Evidence Quality Protocol

Every grounded claim in the report carries an evidence-quality label (`[SOURCE]` / `[INFERRED]` / `[ASSUMPTION – CONFIRM]` / `[CONTEXT]` / `[RECOMMENDED]`) per CLAUDE.md § Universal Preferences. A component's `wc -w`/`wc -c` measurement and the `deploy.sh`-sourced roster count are `[SOURCE]` (read directly from the filesystem). The **token estimate** is `[INFERRED]` — it is computed from the byte/word count via the declared heuristic, not measured against a real tokenizer, and is surfaced as such (never presented as an exact tokenizer count). A bloat flag and its K1/K2 hint are `[RECOMMENDED]`. The skill honors the suite-wide behavioral rules: **no invention** (never fabricate a token count or a roster member — if a path is unreadable, the component says so or is skipped-with-note), **push-to-resolve** (surface the flagged components with a concrete K1/K2 hint, not a bare list), and **no status theater** (a clean scan reports "no component crossed the stated thresholds," not an empty deliverable). **Graceful degradation:** before reading any component path, validate it exists; a missing surface (e.g., no connected MCP servers) is reported as "not present this session" rather than erroring, and the scan proceeds on the rest.

## Reversibility Discipline

This skill produces **report-only outputs** — a measurement report with no recommended state-changing actions. No decision-class items are emitted (the K1/K2 hint is an advisory data point for the operator's own boundary decision, not an action package the skill asks to execute). **Reversibility: CHEAP / Confidence HIGH** for the skill and its report — the report is a read-only artifact nobody acts on automatically, and the skill mutates nothing.

`pmo-qa-auditor` G4 reversibility check is **not applicable** to this skill's outputs — the G4 skip is intentional and declared here (Form B, report-only, per the canonical template). The skill's own build/removal reversibility is CHEAP: it is an additive new `core/` skill; removal is a directory delete plus three registration-row reverts (the `deploy.sh` `CORE_SKILLS` array entry, the `OPERATIONS.md` skill-catalog row, and the `registry.md` CI row). No data migration, no schema change to any existing artifact.

## Principal Standard

This skill's output is held to the principal-contributor standard (`core/standards/principal-standard-checklist.md`). A principal-grade context-budget report: sources the SKILL.md roster from the `deploy.sh` arrays and says so (never a hardcoded count), declares its estimation method + multiplier inline so trend-over-time is interpretable, presents the token figure as an `[INFERRED]` approximation (never a false-precision exact count), states the applied thresholds inline in the flagged section (never an unexplained flag), reuses the canonical 25 KB soft-ceiling rather than inventing one, and emits an actionable K1/K2 hint per flagged component. A junior report hardcodes "23 skills" (stale the next time a skill lands), prints a precise-looking token count as if it were authoritative, flags components with no stated threshold, and stops at counts with no load-vs-reference judgment.

## Guardrails (Platform)

Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source for the authoritative list. Platform-wide generic guardrails apply uniformly: no status theater, no invention, no task dumping, evidence labels on all factual claims, day-of-week validation on all dates. Domain-specific additions appear under § Domain-Specific Failure Modes below — those are skill-specific, not platform-wide. The skill-specific standing guardrail is **read-only measurement**: the auditor's authority is to scan and report cost; it never edits, trims, or removes a component to "fix" bloat — that is the operator's decision, informed by the report.

## Domain-Specific Failure Modes

These domain-specific anti-patterns coexist with `## Guardrails (Platform)` (platform-wide) and `## Reversibility Discipline` (report-only opt-out). Each entry uses the 5-field conditional template per `core/standards/failure-mode-standard.md` and carries a category tag (TRIG / INPUT / PROC / OUT / HAND). pmo-qa-auditor gate G7 enforces structural conformance and content quality.

### Presenting the heuristic token estimate as an exact/authoritative count — OUT

- **Signature (observable signal):** The report shows a per-component or total token figure as a precise integer with no method disclosure and no `[INFERRED]` label — e.g. "delivery-engine: 4,217 tokens" — read by the operator as an exact tokenizer count, and later compared 1:1 against a real tiktoken number that differs.
- **Conditional:** do NOT present the word-count-derived token estimate as an exact or authoritative count when the estimator is a `words / 0.75` heuristic, because a precise-looking number invites false absolute comparison across runs and against real tokenizers, and erodes trust the moment it drifts — defeating the trend-over-time value that is the skill's actual deliverable.
- **Root cause:** an integer *looks* exact regardless of how it was produced; the approximation is invisible once the number is printed, so a reader treats a heuristic estimate with the same authority as a measured one.
- **Mitigation:** declare the estimation method + multiplier in the report header, label every token figure `[INFERRED]`, and frame the deliverable as *relative cost + trend*, not an absolute. If tiktoken is applied for a named model, show it as a separate clearly-labeled column — never silently replace the heuristic so the trend baseline stays stable across model versions.
- **Principal response vs. junior response:** Principal states "estimated ~4.2K tokens (word-count heuristic, `words/0.75`; `[INFERRED]`)" and anchors the value as a trend baseline. Junior prints "4,217 tokens" bare, the operator diff-checks it against tiktoken next month, the numbers disagree, and the whole report is distrusted.

### Enumerating the skill catalog from a hardcoded list instead of the deploy.sh arrays — INPUT

- **Signature (observable signal):** The scan iterates a literal skill-name list (or a hardcoded "23"/"48" count) baked into the skill body or its script, and the roster count can be reproduced without ever reading `deploy.sh` — so the report silently omits any skill added after the list was written.
- **Conditional:** do NOT enumerate the skill catalog from a literal list when the `deploy.sh` per-module arrays (`OPERATIONS_SKILLS`/`RELEASE_SKILLS`/`CORE_SKILLS`) are the roster source of truth, because a hardcoded roster goes stale the instant a skill is added — the exact bloat-blindness this skill exists to cure, reproduced inside the skill meant to detect it.
- **Root cause:** hardcoding a list *feels* faster and more deterministic than parsing `deploy.sh` at runtime; the pressure to make the scan "self-contained" reproduces the parameterization gap the roster source exists to close (CLAUDE.md "Parameterize over hardcode").
- **Mitigation:** extract the roster from the `deploy.sh` arrays at scan time (the same awk-window idiom `check-canonical-structure.sh` uses), and state in the report that the count came from `deploy.sh`. Any in-body number is illustrative only, explicitly marked non-source. Verify: the reported SKILL.md count equals `deploy.sh` Check-5's count, and no literal name list functions as the roster.
- **Principal response vs. junior response:** Principal parses the arrays every run, so the 49th skill appears in the report the moment its array row lands. Junior bakes in "48," the 49th skill is invisible until someone remembers to edit the auditor, and the tool under-reports the very cost it measures.

### Emitting a flagged-bloat section with no stated threshold — OUT

- **Signature (observable signal):** The report's flagged-bloat section lists components as "bloated" with no accompanying threshold — the reader cannot tell why a component was flagged, what value it crossed, or whether the flag would reproduce on the next run.
- **Conditional:** do NOT emit a flagged-bloat section without stating the applied threshold band inline (the top-decile relative band AND the 25 KB single-file absolute soft-ceiling) when flagging any component, because an unexplained flag is un-actionable (the operator can't decide what to do) and un-reproducible (a different reader with a different mental threshold can't verify it) — AC-3 is the forcing function.
- **Root cause:** the threshold lives in the scan logic, so once the flag is computed the *reason* is implicit; printing just the flagged names feels sufficient because the author already knows the rule.
- **Mitigation:** state both thresholds inline at the top of the flagged section every run — the relative band ("top decile of per-component cost") and the absolute soft-ceiling ("a single SKILL.md > 25 KB `wc -c`, the canonical value from `canonical-skill-structure.md §5`) — and show, per flagged component, which threshold it crossed and by how much. Reuse the existing 25 KB value; do not invent a new magic number.
- **Principal response vs. junior response:** Principal writes "Flagged (crossed ≥1 stated threshold — relative: top-decile share; absolute: >25 KB SKILL.md): …" with the crossing value per row. Junior writes "Bloated: X, Y, Z" bare, and the operator has no basis to act, verify, or reproduce the finding.

## What This Skill Does NOT Do

- **Does not edit, trim, move, or remove any component.** Its only write is the report; measuring cost is not the same as reducing it — any reduction is the operator's decision, informed by this report (Autonomy Tier 0; read-only).
- **Does not hardcode the skill roster or a skill count.** The SKILL.md roster is sourced from the `deploy.sh` per-module arrays every run; the report states the provenance.
- **Does not present the token estimate as an exact tokenizer count.** The figure is a word-count-heuristic approximation, labeled `[INFERRED]`; tiktoken is an optional opt-in refinement, shown as a separate labeled column, never the silent primary.
- **Does not act as a `deploy.sh --check` gate.** It reads the deploy.sh arrays as a roster source; a bloat flag is advisory, not a pass/fail gate, and must not be wired into `--check`.
- **Does not invent a bloat threshold.** It reuses the canonical 25 KB single-file soft-ceiling from `canonical-skill-structure.md §5` and a stated relative percentile band — no new magic number.

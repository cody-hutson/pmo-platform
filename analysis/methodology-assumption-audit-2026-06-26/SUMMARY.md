<!-- repo-integrity: allow-issue-ref -->
# Methodology-Assumption Audit — Bare-Toolkit Substrate Confirmation (#1094)

**Audit date:** 2026-06-26 (UTC)   **Baseline SHA:** `d1d896c`   **Auditor:** Stage 6 Engineering spoke (#1978)
**Frame:** S1–S9 (census; 100% coverage target)   **Verdict-validity:** as of `d1d896c`
**Parent spike:** #1094 — precursor (P0) to #1090 (gates K1 methodology-pack authoring)
**Methodology source:** Stage 5 Solutioning spec (sub-task #1977, Research-Methodology Design variant) — executed as written.

> **⚠️ PLACEMENT FLAG (Stage-9 reviewable).** This register is placed **in-repo** at `pmo-platform/analysis/methodology-assumption-audit-2026-06-26/SUMMARY.md` per the #1094 AC ("placed under `pmo-platform/analysis/<audit-name>-YYYY-MM-DD/`") and the CLAUDE.md Governance File Map (analysis tier → `pmo-platform/analysis/<audit-name>-YYYY-MM-DD/`). Note that analysis artifacts have been migrating **operator-instance-local** (the release-corpus public-vs-instance split — `pmo-platform/analysis/` does not otherwise exist in the public worktree; the Stage 5 survey confirmed its absence). The in-repo-vs-operator-instance placement of this artifact is therefore a **Stage-9-reviewable decision**: the card AC + CLAUDE.md say in-repo, which is where it is placed; the operator may redirect it operator-local at Stage 9 Plan Review. This flag is recorded here and in the sub-task #1978 comment.

---

## 0. Method (carried verbatim from Stage 5 design)

- **Unit of analysis:** the *methodology-assumption site* — a discrete location in a methodology-consuming surface where the surface either (a) reads a methodology selector (`delivery_approach`, `lifecycle`, or `custom_methodology_definition`), or (b) emits methodology-archetype vocabulary (`sprint`, `story point(s)`, `velocity`, `burndown`, `sprint goal`, `sprint hygiene`, `phase-gate`, `DoR`/`DoD` as ceremonies) **in a behavior-determining position**. A site is one (file × line-range × assumption) tuple. Pure prose mentions in reference-doc commentary that do not determine skill behavior, and input-parsing of whatever columns a Jira export carries, are NOT sites.
- **Coding scheme (3-way, first-match-wins):** **resolver-gated** (R1 mode/step reads the selector AND varies output · R2 archetype term only inside a selector-guarded block · R3 archetype's own primitive in a section the methodology matrix maps per-archetype) → **leak** (L1 archetype primitive determines output, no selector read in the enclosing mode/step, no agnostic fallback · L2 enum-drift outside the 8+Custom set) → else **ambiguous**. The `dual_framing_enabled` binary is NOT a methodology selector (orthogonal co-management trigger) — reading it does **not** confer resolver-gated.
- **Evidence-grade rubric:** A1 (`[SOURCE]` file:line + reproducible grep + gating-presence/absence proof) · A2 (`[SOURCE]` file:line + reproducible grep) · B (`[INFERRED]`, not load-bearing) · C (`[ASSUMPTION – CONFIRM]`, lead only). **Minimum load-bearing grade = A2.** The verdict is computed over A1/A2 findings only.
- **Site-discovery grep set (the reproducible instrument — run per surface):**
  1. Selector reads: `grep -rnE 'delivery_approach|lifecycle:|custom_methodology_definition' <surface>`
  2. Archetype-vocabulary candidates: `grep -rinE 'story[ -]?point|burndown|velocity|sprint[ -](hygiene|goal|assignment)|\bsprint\b|phase[ -]gate|\bDoR\b|\bDoD\b' <surface>`
  3. Co-management binary (disambiguation, NOT a selector): `grep -rinE 'dual_framing_enabled|spm_comanaged' <surface>`
- **Frame (census — exactly S1–S9, no more):** S1 `operations/skills/intake-desk/` · S2 `operations/skills/delivery-engine/` · S3 `operations/skills/tracker-manager/` · S4 `operations/skills/ppm-agent/` · S5 `operations/skills/weekly-status-rollup/` · S6 `operations/skills/daily-status/` · S7 `release/skills/release-planner/` · S8 `core/disciplines/work-organization-mapping-framework.md` · S9 `core/governance/OPERATIONS.md` §Methodology Awareness Protocol + `core/schemas/project-schema.md`. For S1–S7 the SKILL.md **plus** its `references/*.md`. Out-of-frame: the methodology-definition corpus (`methodology-parameterization-v1.md`, `methodology-archetype-matrix.md`, `terminology-glossary.md`), release-pipeline specs, unnamed `core/` files, release plans/logs, `.skill` packages.

---

## 1. Validity Threats (declared BEFORE findings)

| Threat | Mitigation applied |
|---|---|
| **Selection bias (surface coverage)** | The frame is a **census** (100% of the named consuming surfaces S1–S9), not a sample. The include/exclude boundary rule is explicit and reproducible. No surface was added at audit time; one out-of-frame corroborator (`core/schemas/tracker-schemas.md`) is recorded in §6 as a note, not silently admitted to the audited frame. |
| **Coding reliability** | The 3-way scheme is a written first-match-wins decision rule (R1–R3 / L1–L2 / else-ambiguous), not a judgment call. Every `leak` and every `ambiguous` carries an absence/indeterminacy-proof grep (transcripts in `evidence/grep-transcripts.md`). The `ambiguous` class is the pressure-relief valve so indeterminate sites are surfaced for disposition rather than coin-flipped. |
| **Reproducibility** | Every finding cites `file:line` + a reproducible grep; the register pins the baseline SHA (`d1d896c`) + the full §0 grep set. A re-run against `d1d896c` is byte-reproducible. The verdict is explicitly scoped "valid as of `d1d896c`" (audit-baseline discipline — the leak/ambiguous population can change; a single later commit adding a leak does not silently invalidate this result). |
| **Construct validity** | "Archetype vocabulary" is over-broad — a correct Scrum-row "Sprint" would miscode as a leak. Rule **R3** explicitly exempts an archetype's own primitive used in a section the methodology matrix maps per-archetype (this exempts S8's Layer-2 table and S3's Methodology Variation references). The methodology-definition corpus is out-of-frame. |

---

## 2. Findings Register

Findings F01–F04 are the load-bearing (A1/A2) coded sites. The resolver-gated corpus is large; representative resolver-gated exemplars are recorded as RG-rows (one per surface, with the gold exemplar called out) so the per-surface tally (§3) is auditable. Homonyms and input-parsing positions excluded per §0 are listed at the foot of this section.

### 2.1 Coded sites with disposition (leak + ambiguous — the verdict-bearing rows)

| ID | Surface | File:line | Quoted site (abridged) | Class | §6.4/§6.5 pattern | Selector-read evidence | Absence/indeterminacy grep | Grade | Load-bearing | Reversibility | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **F01** | S2 delivery-engine | `operations/skills/delivery-engine/SKILL.md:122–125` | Mode A health-scorecard dimensions: "P1s not in **current sprint**" · "**Sprint hygiene**: items in sprint without estimates, items assigned to closed sprints" · "**Sprint cycling** -> escalation" | **leak** | §6.4 `hardcoded-sprint-presumption` (PROC) | — (none in enclosing mode) | `sed -n '109,142p' .../SKILL.md \| grep -nE 'delivery_approach\|lifecycle:\|custom_methodology_definition'` -> **exit 1 (no match)** — Mode A (109–142) reads no selector | **A1** | **YES** | MODERATE | The scorecard emits sprint-hygiene / current-sprint / sprint-cycling as **universal** health findings with no `delivery_approach` branch and no agnostic-default caveat. A non-Scrum (e.g. Waterfall/Kanban-cadence) project is scored against sprint dimensions that do not apply. Corroborated by S9b project-schema.md:370 which records delivery-engine's `delivery_approach` refit as "(future)". |
| **F02** | S2 delivery-engine | `operations/skills/delivery-engine/SKILL.md:178–217` (Mode D) | Mode D "Sprint Planning" — capacity/velocity/**sprint goal**/scope machinery presented as the universal planning frame; trigger "Plan the sprint" | **ambiguous** | (would be §6.4 if confirmed leak) | reads `delivery_approach` for sub-features: 3.5 facilitation (`:191`) + tech-debt floor calibration (`:196`) | `sed -n '178,217p' .../SKILL.md \| grep -c delivery_approach` -> **2** (selector present for sub-features, **not** for the sprint-frame itself) | A2 | NO (ambiguous — excluded from verdict tally) | MODERATE | Indeterminate: the mode reads the selector for two sub-features yet the **iteration/sprint frame** (the planning unit itself) is ungated. Cannot tell from the text whether the mode is Scrum-by-design (a Kanban/Waterfall project routes elsewhere) or whether the frame is a presumption. **Resolution lead:** confirm with the owner whether Mode D is intended to fire for non-timeboxed `delivery_approach`, or only when `lifecycle: timeboxed`. Material to #1090 only if K1 packs touch sprint-planning. |
| **F03** | S4 ppm-agent | `operations/skills/ppm-agent/references/artifact-gap-detection.md:17` | "**Sprint Execution** \| Sprint DoR (per sprint) \| **Sprint Backlog, Sprint Goal**, Acceptance Criteria per PBI" — one row of the phase-keyed artifact checklist | **ambiguous** | (would be §6.4 if confirmed leak) | none in file | `grep -nE 'delivery_approach\|methodology\|archetype\|Waterfall\|Kanban\|agnostic' .../artifact-gap-detection.md` -> **exit 1 (no match)** — no methodology branch in the file | A2 | NO (ambiguous) | CHEAP | Indeterminate: one row of an otherwise methodology-agnostic phase checklist hardcodes Scrum artifacts (Sprint Backlog/Goal/PBI). A Waterfall project never reaches the "Sprint Execution" phase, so the row may be **correctly inert** — OR the gap-detector may flag a non-Scrum project as "missing Sprint Backlog." **Resolution lead:** confirm whether the phase column is archetype-selected upstream (the project's phase set comes from its archetype) — if yes -> resolver-gated; if the checklist is applied phase-agnostically -> leak. Gap-detection is recommendation-class (flags, does not gate) -> CHEAP. |
| **F04** | S5 weekly-status-rollup | `operations/skills/weekly-status-rollup/references/metric-registry.md:80,102,103,125,133,134` | Program metric set hardcodes sprint-derived metrics — "**Velocity Variance**" (source: "sprint metrics roll-up"), "**Sprint Commitment Reliability**" (source: "sprint board"), "Blocked-Item Count" (source: "sprint board") — as canonical portfolio metrics | **ambiguous** | (would be §6.4 if confirmed leak) | none in file | `grep -c delivery_approach .../metric-registry.md` -> **0** (no selector branch in the metric registry) | A2 | NO (ambiguous) | MODERATE | Indeterminate: sprint-sourced metrics are defined as the universal program metric set with no `delivery_approach` gating. For a non-sprint project the metric source ("sprint board") is simply absent -> the metric is N/A (acceptable), OR the registry presumes every project has a sprint board (leak). The roll-up's verdict-composition consumes these via watermelon-detection (W4 Velocity spike). **Resolution lead:** confirm whether the registry is intended to degrade-to-N/A for projects without sprint cadence, or be gated by archetype. Two consumers (auditor + roll-up) raise the blast radius -> MODERATE. |

### 2.2 Resolver-gated exemplars (sampled; not exhaustive — these anchor the §3 tally)

| ID | Surface | File:line | Site | Rule | Grade | Why resolver-gated |
|---|---|---|---|---|---|---|
| RG-S2a | S2 delivery-engine | `SKILL.md:238` (Mode E Stage-Tracking) | "Read `delivery_approach` from PROJECT.md at invocation ... On an absent or out-of-grid field ... **never silently assume Scrum**" | R1 | Reads selector, branches column, explicit never-assume-Scrum negative path. The exemplar that all three classes are live. |
| RG-S2b | S2 delivery-engine | `references/lifecycle-stages.md:371–381` | §4.1 model resolution: "The signal that selects the column is the `delivery_approach` field ... absent -> canonical names + caveat" | R1 | The methodology-aware machinery Mode E/C/F defer to; fully selector-gated with explicit absent-field defaults. |
| RG-S2c | S2 delivery-engine | `SKILL.md:159–177` (Mode C DoR), `:263–302` (Mode F DoD) | DoR/DoD rendered as universal-lifecycle gates (`T(6->7)`, LG-4…LG-10, §5.2 per-transition enforcement) | R3 | DoR/DoD are the universal lifecycle's gate names (mapped per-archetype by the lifecycle-stages grid), not raw Scrum ceremonies. (Borderline: `:288` "All sprint items meet DoD" presumes sprint scope — noted as a minor presumption inside a gate context, not promoted to a leak.) |
| **RG-S4★** | S4 ppm-agent | `SKILL.md:175–203` (decision-authority) | "**Negative path — never silently assume a model.** When `delivery_approach` is absent ... emit a **methodology-agnostic** profile ... `[ASSUMPTION – CONFIRM]`" | R1 | **Gold exemplar.** Reads selector, branches owner-by-archetype (PM under Waterfall / PO under Scrum), explicit never-assume-Scrum + agnostic fallback. Directly instantiates the §6.4 anti-pattern as a *guard*, not a violation. |
| RG-S3 | S3 tracker-manager | `SKILL.md:390–397, 561` | `phase-gate` baseline-flip references the `tracker-schemas.md` Methodology Variation table (Waterfall->`phase-gate-log.md`; PRINCE2->`stage-boundary.md`); DFB reads `dual_framing_enabled` + array | R3/R1 | Behavior branches per archetype via the Methodology Variation table; not a universal sprint presumption. |
| RG-S5 | S5 weekly-status-rollup | `SKILL.md:125,128–129,421` | Agile/Waterfall track summaries gated behind `dual_framing_enabled: true` (`:125`); DFB array-aware (`:421`) | R2/R1 | Archetype vocabulary appears only inside the `dual_framing_enabled`-guarded block. |
| RG-S6 | S6 daily-status | `SKILL.md:282` | Dual-Framing Bridge — Agile/Waterfall framing gated on `dual_framing_enabled: true`; array -> one native section per constituent | R1/R2 | The only behavior site in S6; fully selector-gated. References handle "no active sprint buffer -> negative path" agnostically. |
| RG-S8 | S8 work-org-framework | `:91–92,135–136,165,211,225,265` | Layer-2 work-breakdown table keyed by the archetype row (Scrum row names "Sprint"; `sprint_ref` optional); CASE 1/2/3 resolution off `delivery_approach`+`custom_methodology_definition` | R3 | The neutrality keystone — methodology-agnostic by construction; archetype primitives appear only inside per-archetype rows the table maps. |
| RG-S9a | S9 OPERATIONS.md | `:335,343–408` | The Methodology Awareness Protocol itself — "Skills ... MUST read the `delivery_approach` field"; Rule 1–4; the `delivery_approach` vs `dual_framing_enabled` orthogonality | R1 | This **is** the resolver contract. Archetype vocabulary appears only as the rule's own definition. (Card notes the rule is "unenforced" — an enforcement gap, recorded in §5/§7, not a leak in the protocol text.) |

### 2.3 Excluded per §0 (homonyms + input-parsing — NOT sites)

| Surface | File:line | Why excluded |
|---|---|---|
| S1 intake-desk | `references/elicitation-loop.md:13`, `SKILL.md:153`, `intake-governance.md:132,188` | "Phase gate(s)" here = the **intake elicitation loop's own 4-phase binary gates** ("Each phase boundary is a gate the agent evaluates as a binary checklist"), a homonym of the Waterfall methodology phase-gate. Not methodology-archetype vocabulary. |
| S4 ppm-agent | `SKILL.md:72–73`, `:145`; `references/follow-up-tags.md:*`, `evidence-quality.md:*`, `competency-model.md:30`, `proactive-follow-up-tracking.md:82` | **Input-parsing** ("Parse columns for ... story points, sprint, epic" — reads whatever the Jira CSV carries) and **illustrative `[SOURCE]`/`[INFERRED]` label examples** ("Velocity: 38 pts/sprint [SOURCE: Jira]"). Neither determines methodology behavior. |
| S7 release-planner | (entire surface) | **Zero** selector reads AND **zero** archetype-vocab hits. release-planner operates on the release pipeline, not project-delivery methodology — out of the methodology axis entirely. No site. |

---

## 3. Per-Surface Tally (A1/A2 findings only)

Verdict-bearing counts. `resolver-gated` is reported as "ok (N exemplars; surface clean of leaks)" because the resolver-gated corpus is large and sampled, not exhaustively enumerated — the load-bearing facts are the **leak** and **ambiguous** columns (these ARE exhaustively enumerated for the frame).

| Surface | resolver-gated | leak | ambiguous |
|---|---|---|---|
| S1 intake-desk | ok (n/a — no methodology behavior; phase-gate homonyms only) | 0 | 0 |
| S2 delivery-engine | ok (RG-S2a/b/c — Modes C/E/F + lifecycle machinery) | **1 (F01)** | **1 (F02)** |
| S3 tracker-manager | ok (RG-S3) | 0 | 0 |
| S4 ppm-agent | ok (RG-S4★ gold exemplar) | 0 | **1 (F03)** |
| S5 weekly-status-rollup | ok (RG-S5) | 0 | **1 (F04)** |
| S6 daily-status | ok (RG-S6) | 0 | 0 |
| S7 release-planner | n/a — out of methodology axis (no site) | 0 | 0 |
| S8 work-org-framework | ok (RG-S8 — neutrality keystone) | 0 | 0 |
| S9 OPERATIONS + project-schema | ok (RG-S9a — the resolver contract) | 0 | 0 |
| **TOTAL** | — | **1** | **3** |

---

## 4. Verdict — Substrate Neutrality Go/No-Go

**Verdict: NO-GO** (rule fired: **>=1 `leak` finding at grade A1/A2** — F01, grade A1).

**Basis:**
- **1 confirmed leak** (A1, load-bearing): **F01** — delivery-engine Mode A health-scorecard hardcodes sprint-hygiene / current-sprint / sprint-cycling as universal scorecard dimensions with no `delivery_approach` branch and no agnostic fallback (`§6.4 hardcoded-sprint-presumption`). The substrate is **not yet methodology-neutral**: a non-Scrum project run through Mode A is scored against sprint dimensions that do not apply to it.
- **3 material ambiguities** (not counted toward the leak tally; each carries a resolution lead in §7): **F02** (Mode D sprint-planning frame), **F03** (ppm-agent artifact-gap "Sprint Execution" row), **F04** (weekly-status-rollup sprint-derived metric registry). Each is a site where the sprint frame is ungated but text alone cannot confirm whether it is a presumption or a correctly-inert path.

**Scope of the NO-GO (important):** The leak is **localized to one mode of one skill** (delivery-engine Mode A), with three ambiguities clustered on the same sprint-frame theme. The **methodology-resolution machinery the substrate depends on is sound** — the OPERATIONS.md Methodology Awareness Protocol (S9), the work-organization-mapping framework (S8, the neutrality keystone), the lifecycle-stages §4.1 model resolution (S2), and the ppm-agent decision-authority negative path (S4, gold exemplar) are all correctly selector-gated with explicit never-assume-Scrum defaults. This is **NOT a corpus-wide archetype-bake-in**; it is a bounded, named, remediable defect surface (F01) plus three dispositions to confirm (F02–F04). The "bare toolkit" thesis is **substantially confirmed at the resolver/contract layer** and **fails at one operational scorecard surface** that pre-dates the methodology-parameterization keystone.

**Implication for #1090 (K1 methodology-pack authoring):** K1 packs may proceed **conditionally** — the resolver contract they plug into is neutral (GO at the contract layer). The blocker is whether a pack would touch delivery-engine Mode A (F01) or the three ambiguous surfaces (F02–F04). If a planned pack authors content for backlog-health scoring, sprint-planning, artifact-gap-detection, or portfolio metrics, the corresponding remediation (§5) should land first. If the first packs target the already-neutral resolver/lifecycle/decision-authority surfaces, they are unblocked.

**Validity:** as of baseline SHA `d1d896c`; re-run the §0 grep set against that SHA to revalidate. A later commit that adds a sprint presumption to any S1–S9 surface invalidates the per-surface clean marks — re-audit before relying on this verdict past `d1d896c`.

---

## 5. Remediation Surface (enumerated — one row per leak / verdict-blocking ambiguous)

Routed as **follow-up candidates for #1090** (and adjacent issues). The audit **enumerates** these; it does **not** remediate them (remediation is downstream — out of scope for #1094 per the card).

| # | Site (file:line) | Current class | Target class | Proposed mechanism | Reversibility | Routing recommendation |
|---|---|---|---|---|---|---|
| R1 | `delivery-engine/SKILL.md:122–125` (Mode A scorecard) | **leak (F01)** | resolver-gated | Read `delivery_approach` at Mode A entry per the Methodology Awareness Protocol; gate the sprint-cadence scorecard dimensions (sprint hygiene, current-sprint, sprint-cycling) behind a timeboxed/iterative archetype; on absent/non-sprint archetype, substitute cadence-agnostic dimensions (flow/aging/WIP) + `[ASSUMPTION – CONFIRM]` caveat — mirror the Mode E Stage-Tracking pattern (RG-S2a). | MODERATE | New follow-on issue under #1090 (delivery-engine Mode A methodology refit). The single largest remediation; the project-schema.md:370 "(future) refit" row already anticipates it. |
| R2 | `delivery-engine/SKILL.md:178–217` (Mode D frame) | **ambiguous (F02)** | resolver-gated (or documented-Scrum-scope) | First **disposition** (owner confirm): is Mode D timeboxed-only by design? If yes -> document the `lifecycle: timeboxed` precondition + route non-timeboxed elsewhere (resolves to resolver-gated). If no -> gate the planning frame on the selector (parameterize "sprint" -> the archetype's iteration/cadence unit). | MODERATE | Same delivery-engine refit issue as R1 (adjacent; share the disposition). |
| R3 | `ppm-agent/references/artifact-gap-detection.md:17` (Sprint Execution row) | **ambiguous (F03)** | resolver-gated | Disposition: confirm the phase set is archetype-selected upstream. If yes -> annotate the row "fires only when the project's archetype includes a Sprint Execution phase" (resolver-gated by the phase selector). If applied phase-agnostically -> gate the row on `delivery_approach`, or generalize "Sprint Backlog/Goal/PBI" to the archetype's execution-phase artifacts. | CHEAP | Fold into #1085 (intake-desk refit) **only if** ppm-agent artifact-gap is in that scope; otherwise a small ppm-agent follow-on. Recommendation-class (flags, does not gate) -> low blast radius. |
| R4 | `weekly-status-rollup/references/metric-registry.md:80,102,103` (sprint-derived metrics) | **ambiguous (F04)** | resolver-gated | Disposition: confirm the registry degrades-to-N/A when a metric's source (sprint board) is absent. If yes -> document the degrade-to-N/A rule explicitly (resolver-gated by source presence). If the registry presumes a sprint board universally -> tag the sprint-derived metrics archetype-conditional, or add a cadence-agnostic throughput metric for non-sprint projects. | MODERATE | New follow-on issue under #1090 (portfolio-metric methodology neutrality). Two consumers (pmo-qa-auditor watermelon-detection + roll-up §7.1) -> coordinate the change across both. |
| R5 | `OPERATIONS.md:335` Methodology Awareness Protocol (enforcement gap) | (not a leak — protocol is correct) | enforced | The protocol states "skills MUST read `delivery_approach`" but the card notes the rule is **unenforced** (no gate/check verifies skills actually read it). Add an enforcement surface (a deploy-check or eval that asserts methodology-consuming skills read the selector) — this is what would have *prevented* F01. | MODERATE | New follow-on issue (methodology-awareness enforcement check). Systemic — closes the class, not just F01. |

---

## 6. Out-of-Frame Observations (scope-expansion + note-only drift)

- **No 10th-surface scope-expansion finding.** The census held to S1–S9; no surface outside the frame was found to carry a methodology assumption that warranted admitting it to the audited frame. One **out-of-frame corroborator** is noted (not admitted to the frame): `core/schemas/tracker-schemas.md:340–349` (the **Methodology Variation — Tracker Applicability** table; Waterfall -> "no sprint-scale trackers", `phase-gate-log.md`) — this is the per-archetype branch that S3 tracker-manager **references** to achieve its resolver-gated status. It is correctly out-of-frame (an unnamed `core/schemas/` file) but documents that the platform's tracker layer is archetype-aware by construction.
- **ADR-011 file absence (note-only, P3 — carried from Stage 5).** `core/ADRs/` jumps 010->012; `ADR-011-analysis-class-methodology-design-treatment.md` is referenced by path (Stage 5 spec §7.1/§12; sub-tasks) but the **file does not exist** (it is a pre-registered/logical ADR materialized directly in `stage-05-solutioning.md`). Does not block this audit. **Recommend a follow-on observation** to either author the ADR-011 file or de-reference it to the spec sections. Out of scope for #1094.
- **Stale `spm_comanaged` premise (corrected — carried from Stage 5).** The #1094 Evidence states "5 of 7 consuming skills read `spm_comanaged`." This is **stale**: `spm_comanaged` was renamed to `dual_framing_enabled` and **retired in v2.19** (confirmed `project-schema.md:97,324` — "no longer accepted on read"). No skill body reads `spm_comanaged`. The coding scheme read the **live** binary `dual_framing_enabled` throughout, and treats it as the orthogonal co-management trigger (NOT a methodology selector) per OPERATIONS.md. The audit was grounded in live state, not the stale premise.
- **`pmo-platform/analysis/` absent from the public worktree (expected).** Per the release-corpus public-vs-instance split, analysis artifacts have been operator-instance-local; this folder was created fresh by this Stage 6 commit. See the header PLACEMENT FLAG — the in-repo placement is a Stage-9-reviewable decision.

---

## 7. Residual Risk Register

| Unresolved ambiguous site | Why unresolved | Resolution lead / owner | Reversibility |
|---|---|---|---|
| F02 — delivery-engine Mode D sprint-planning frame | Text reads the selector for sub-features but the iteration frame is ungated; cannot tell from text whether Mode D is timeboxed-by-design or presumes sprint. | Confirm with delivery-engine owner whether Mode D fires for non-timeboxed `delivery_approach` (or only `lifecycle: timeboxed`). Reading `references/sprint-defaults.md` consumer-side gating may resolve it. | MODERATE |
| F03 — ppm-agent artifact-gap "Sprint Execution" row | One Scrum-hardcoded row in an agnostic checklist; cannot tell whether the phase column is archetype-selected upstream (row inert for non-Scrum) or applied phase-agnostically (row fires -> leak). | Confirm whether the project's phase set derives from its archetype. Owner: ppm-agent. | CHEAP |
| F04 — weekly-status-rollup sprint-derived metric registry | Sprint-sourced metrics defined as the universal program set; cannot tell whether the registry degrades-to-N/A on absent source or presumes a sprint board universally. | Confirm the degrade-to-N/A behavior; coordinate with pmo-qa-auditor (watermelon-detection consumer). Owner: weekly-status-rollup. | MODERATE |
| Methodology Awareness Protocol enforcement gap (R5) | The "MUST read `delivery_approach`" rule has no enforcement surface — F01 is exactly what slips through an unenforced contract. | Add a deploy-check/eval asserting methodology-consuming skills read the selector (systemic fix; closes the leak class). | MODERATE |

---

## 8. Provenance

### Source(s)
- Stage 5 Solutioning spec — sub-task #1977 (Research-Methodology Design variant); the executable methodology, the 9-surface census, the 3-way coding scheme, the evidence-grade rubric, and this register schema are carried from that spec.
- Parent spike — #1094 (audit corpus for embedded methodology assumptions; precursor to #1090).
- Baseline SHA `d1d896c` (release branch `release/v2.23-corpus-conventions-and-standards-hygiene`).

### Reproducibility note
Script-derived (grep-based site discovery) + hand-classified (the first-match-wins coding rule applied per site, each leak/ambiguous with a confirmation grep). The §0 grep set re-derives every site against `d1d896c`. Grep transcripts: `evidence/grep-transcripts.md`.

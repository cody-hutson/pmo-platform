<!-- reference-durability: allow-link -->
# L4 Suite-Integration Harness — `pmo-skill-router`

This document is the **methodology specification** for the L4 suite-integration test of the `pmo-skill-router` capstone. The router is the point where the whole role-Specialist suite is exercised at once, so its acceptance is a **suite-integration** test, not a single-skill eval.

> **Build-vs-run boundary.** This file **documents** the harness; a later stage **runs** it. Building the router (authoring `SKILL.md`, registering it, packaging) does **not** execute anything below. The runner attaches the eval-runner report (classification %), the three E2E flow reports, and the coherence-audit table as the acceptance evidence.

## Grounding (eval-writer)

The harness is grounded in [`../../eval-writer/SKILL.md`](../../eval-writer/SKILL.md) and the 2026 eval-writing consensus it encodes:

- **Stage-0 characterization (5-tuple).** The router is a **single-agent, no-tool, HITL-present (operator picks on a tie), dev-stage, routine-criticality** system. Dispatch the downstream judge design off this 5-tuple: judges are **deterministic-comparison binary judges**, and ambiguity-tie behavior is a **first-class graded dimension**, not noise.
- **Binary judges, not 1–5 Likert** (eval-writer A-04). Each query scores PASS/FAIL; each E2E seam scores PASS/FAIL. No ordinal scale.
- **Trace-driven, not paraphrased** (eval-writer F-05 criteria-drift). Queries are realistic operator phrasings — **not** paraphrases of the registry `trigger surface` text. Paraphrasing the source guarantees a trivial pass and measures nothing.
- **Human-validated judges** (eval-writer A-03/A-07). ≥30 of the queries form a **hand-labeled calibration set**; report **Krippendorff α** (≥0.80 reliable / 0.67–0.79 tentative / <0.67 rework the rubric). Run a **cross-family bias check** on a sample to confirm routing is not a same-family artifact.

## (a) Classification set — ≥50 queries (recommend 60), aggregate ≥90% correct-role

### Pass bar (hub-resolved)

- **Per-query binary score:** routed `name` == expected `name` → **PASS**; else **FAIL**.
- **Aggregate bar: firm 90%** (the Stage 9 hub resolution of the open design question). The skill-suite epic's Decision 10 sets a "90% trigger-accuracy threshold, **adaptive based on pilot results**"; the hub fixed the v2.15 L4 at the **firm 90% aggregate** bar. Any pilot-adjusted bar must be **recorded with rationale**, never applied silently.
- **Sub-90% on a *confusable cluster* (C1–C6) → trigger-deconfliction finding, NOT a router defect.** The router classifies on the prose it is given; if two rows' `trigger surface` are not separable, the fix is **sharpening the registry rows** (or the source `description:`), not patching router logic. This lets the router pass the build gate while the deconfliction finding routes back to the registry rows — honoring both the firm bar and the epic Decision-10 adaptive clause.

### Count allocation (≥50; recommend 60 for headroom)

| Bucket | Queries | Rationale |
|---|---|---|
| **Baseline single-role** — ≥2 unambiguous on-trigger queries per role × 19 roles | **38** | Floor coverage so no role is untested; every row routes correctly from a clean query. |
| **Confusable-cluster stress** — the 6 clusters below, ~3 queries each crafted to sit on the seam | **~18** | Where misroutes actually happen; over-weighted vs baseline because this is the real risk surface. |
| **No-confident-match / function-shaped / dormant-RTE** — queries that should NOT route to any role | **~6** | Tests the negative path + the ADR-033 dormancy gate; a router that force-routes these FAILs. |

Each query carries an **expected `name`** as ground truth. ≥30 of the total form the hand-labeled calibration set (report α; cross-family check on a sample).

### The 6 confusable clusters (each scored as a sub-aggregate)

| # | Confusable cluster | Seam the queries must probe | Registry `trigger surface` distinction that should separate them |
|---|---|---|---|
| **C1** | `pmo-program-manager` vs `pmo-program-coordinator` vs `pmo-release-train-engineer` | "manage the program" — delivery posture / go-no-go (PgM) vs tracker↔status cadence coherence (PgCoord) vs SAFe PI-planning / ART (RTE) | PgM = "risk read / posture call / go-no-go / RAID stewardship"; PgCoord = "keep trackers and status in lockstep / cadence sync"; RTE = "PI planning / ART dependencies" **+ dormant unless SAFe** |
| **C2** | `pmo-tier-1-support` vs `pmo-tier-2-support` | "this issue" / "triage this" — first-contact known-issue lookup (T1) vs escalated RCA + runbook authoring (T2) | T1 = "is this a known issue / how do I… / triage" (owns no RCA); T2 = "root cause this / why did this break / write a runbook" (owns RCA) |
| **C3** | `pmo-principal-engineer` vs `pmo-software-engineer` | "design vs build" — solution-scope design / NFR / ADR (PrincEng) vs execute approved plan → PR (SWEng) | PrincEng = "solution-level design decisions, NFR governance, build-vs-buy"; SWEng = "approved plan / findings register ready to build → executed change + PR" (a bare ticket with no plan routes to planning first) |
| **C4** | `pmo-architect` vs `pmo-principal-engineer` | "architecture" — system-scope cross-component / integration (Architect) vs within-component solution depth (PrincEng) | Architect = "system design across components / integration / blast-radius / system ADR"; PrincEng = "within-component architecture" (registry states Architect is "distinct from the solution-scope Principal Engineer") |
| **C5** | `pmo-release-manager` vs `pmo-devops-sre` | "release / deploy" — go-no-go decision + close-out (RelMgr) vs deploy mechanics + reliability / rollback execution (DevOps-SRE) | RelMgr = "go/no-go evidence, deploy authorization, close-out" (the **decision**); DevOps-SRE = "run the deploy, configure pipeline, reliability signal → rollback" (the **execution**) — registry states the decision-vs-execution boundary explicitly |
| **C6** | `pmo-portfolio-manager` vs `pmo-program-manager` | "cross-project health / risk" — above-any-single-project portfolio call (Portfolio) vs one program's multi-workstream delivery (Program) | Portfolio = "portfolio-altitude health / risk / intake / SteerCo **across projects**"; Program = "**one** program's multi-workstream delivery posture" — the altitude (cross-portfolio vs single-program) is the separator |

The ~6 negative-path queries must include at least: a function-shaped ask (e.g. "draft the stakeholder comm" → should NOT route; names `comms-writer` as a pointer), an out-of-suite ask, and a **SAFe-trigger-under-non-SAFe** ask (a PI-planning request with `delivery_approach` non-SAFe → must NOT route to RTE; names the dormancy per ADR-033).

### Authoring discipline (eval-writer)

Queries are **trace-shaped** (realistic operator phrasings). The expected-`name` key per query is ground truth. The judge is a binary deterministic-comparison judge: it compares the router's emitted `name` to the expected `name`. For tie-path queries (where the expected behavior is "present a ranked pair"), the PASS condition is that the router emitted the **correct candidate set and named the seam**, not a single confident route.

## (b) ≥3 E2E multi-skill flows — complete without contradiction across 3+ role-skill outputs

Each flow issues a multi-step scenario; the router routes each step to a role; the **handoff artifacts** are checked for non-contradiction at the seams. (The role-skills already compose function-skills per ADR-019; the flow tests that the router's *sequence of routes* produces a coherent chain, depth ≤2 per cascade C1.)

| Flow | Route chain (router emits each `name`) | Seam(s) checked | "Completes without contradiction" = |
|---|---|---|---|
| **F1 — Portfolio → Program → Project** | `pmo-portfolio-manager` → `pmo-program-manager` → `pmo-project-manager` | altitude handoff (portfolio call → program posture → single-project go/no-go) | the project-tier go/no-go does **not** contradict the program posture, which does not contradict the portfolio-level risk/intake call; each downstream output's scope is *inside* the upstream's (no altitude inversion) |
| **F2 — OCM-Lead → Knowledge-Manager → Tier-1 → Tier-2** | `pmo-ocm-lead` → `pmo-knowledge-manager` → `pmo-tier-1-support` → `pmo-tier-2-support` | change → knowledge-capture → first-line → escalation handoff (maps to `_shared/lifecycle-gates.md` H4 Deploy→Hypercare) | a runbook KM files is the same artifact T1 resolves a known issue from and T2 updates after RCA; the T1→T2 escalation handoff carries the fields T1 produced (no dropped context); no step asserts a resolution a later step reverses |
| **F3 — Principal-Eng → Software-Eng → QA-Lead → Release-Manager** | `pmo-principal-engineer` → `pmo-software-engineer` → `pmo-qa-lead` → `pmo-release-manager` | design → build → QA → release-tail handoff (maps to `_shared/lifecycle-gates.md` H2/H3 + the design→DoD chain) | the design decisions PrincEng records are what SWEng builds against; QA-Lead's acceptance scope binds to that build; RelMgr's go/no-go evidence references QA-Lead's defect disposition — a contradiction = QA accepting scope the design did not specify, or RelMgr authorizing deploy against unresolved QA defects |

### Verification method (binary per flow; eval-writer trajectory/handoff rubric)

For each seam, a binary judge checks **both**:

1. **Handoff completeness** — the downstream output **cites / consumes** the upstream artifact. The H1–H4 checklists in [`lifecycle-gates.md`](../../../../operations/skills/_shared/lifecycle-gates.md) are the field-presence reference.
2. **No contradiction** — no downstream claim **negates** an upstream decision. Structured contradiction test: "does step N+1 reverse, override, or scope-violate step N?" → **PASS only on "no"**.

A flow **PASSes iff every seam PASSes.** 3 flows × clean = AC met. The flows are **router-sequence** tests — a seam failure that traces to a role-skill's own output (not to a mis-route) routes back as a finding against that role-skill, not the router.

## (c) Shared-file coherence audit — all role-skill consumers interpret `operations/skills/_shared/*` consistently

### Scope

The 5 shared files (the `_shared/*` files) and their consumers among the 19 role-Specialists. **Not every role consumes every file** — each file's own header declares its consumer scope:

| Shared file | Contract shape to check | Consumer scope (per the file's own header) |
|---|---|---|
| [`behavioral-markers.md`](../../../../operations/skills/_shared/behavioral-markers.md) | 12 competency areas + 5 meta-behaviors + 10 standards | All role-Specialists |
| [`anti-pattern-catalog.md`](../../../../operations/skills/_shared/anti-pattern-catalog.md) | 8 domains × 5-field shape + TRIG/INPUT/PROC/OUT/HAND tags | All role-Specialists |
| [`five-model-variations.md`](../../../../operations/skills/_shared/five-model-variations.md) | 5-model decision-grade columns | Roles whose output is methodology-sensitive |
| [`deployment-strategies.md`](../../../../operations/skills/_shared/deployment-strategies.md) | 6 strategies + rollback types + RTO/RPO tiers | **Release / cutover-scoped roles only** |
| [`lifecycle-gates.md`](../../../../operations/skills/_shared/lifecycle-gates.md) | 15-stage lifecycle + H1–H4 handoff checklists | **Lifecycle-spanning roles only** |

The audit **first builds the consumer × file matrix** (which roles reference which shared file), then checks interpretation consistency **only over actual consumer pairs** — never auditing a non-consumer against a file it does not use.

### Comparison method (per shared file, over its consumer set)

1. **Reference resolution** — every consuming role's reference to the file **resolves** (the doc-link/path is live) and points at the **current** structure (e.g. `behavioral-markers` still has its 12 competency areas + 5 meta-behaviors + 10 standards; `anti-pattern-catalog` still 8 domains × 5-field shape; `five-model-variations` still 5-model columns). A stale reference to a renamed/moved section = an **incoherence finding**.
2. **Interpretation consistency** — for files with a *contract shape* (anti-pattern 5-field template + TRIG/INPUT/PROC/OUT/HAND tags; five-model 5-column decision-grade cells; lifecycle 15-stage gates + H1–H4 handoffs), confirm each consumer's own extension/usage **conforms to that shape** rather than re-deriving a divergent one (e.g. two roles must not assign **different category tags** to the same anti-pattern, or read the same `delivery_approach` cell two different ways). Method: extract each consumer's invocation of the shared structure, normalize, **diff pairwise** — identical interpretation → **CONSISTENT**, divergence → **finding** with the two consumers + the divergent reading cited.
3. **Output** — a coherence table: **file × consumer-pair → CONSISTENT / DIVERGENT + evidence**.

### Routing of findings

A divergence routes back as a **shared-file or consumer-skill finding** (fix the shared file's ambiguity, or the deviating consumer) — **NOT a router defect.** The router does **not** consume `_shared/*`; this audit is suite-integration, riding the L4 capstone because the capstone is where the whole suite is exercised at once.

## Runner output (attach as AC evidence to the parent work item)

1. **Classification report** — aggregate %, per-cluster sub-aggregates (C1–C6), the calibration-set α, and the cross-family sample result. Flag any sub-90% cluster as a trigger-deconfliction finding (registry text fix), not a router defect.
2. **3 E2E flow reports** — F1 / F2 / F3, per-seam handoff-completeness + contradiction verdicts.
3. **Coherence-audit table** — the file × consumer-pair CONSISTENT/DIVERGENT matrix over the 5 `_shared/*` files.

## Cross-references

- [`../SKILL.md`](../SKILL.md) — the router this harness tests.
- [`../../eval-writer/SKILL.md`](../../eval-writer/SKILL.md) — the eval methodology (binary judges, calibration, cross-family) this harness follows.
- [`../registry.md`](../../registry.md) — the classification source the (a) set probes; the destination for trigger-deconfliction findings.
- [ADR-033](../../../ADRs/ADR-033-methodology-conditional-skill-activation.md) — the methodology-conditional activation governing the dormant-RTE negative-path queries (C1 + the ~6 negative bucket).
- [ADR-034](../../../ADRs/ADR-034-registry-as-classification-source.md) — the registry-as-classification-source contract the router consumes.
